#!/usr/bin/env bash
# Métricas do Atlas em .atlas/metrics.jsonl. Uso:
#   metrics.sh log <evento> key=value ...     (ex.: log feature issue=42 duration_s=1830 waves=3 review_cycles=1 agents=6)
#   metrics.sh hook                           (chamado pelos hooks SubagentStart/Stop; lê JSON do stdin)
#   metrics.sh report [n]                     (resumo das últimas n features/releases, padrão 10)
set -u
ROOT="${CLAUDE_PROJECT_DIR:-.}"; F="$ROOT/.atlas/metrics.jsonl"; mkdir -p "$ROOT/.atlas"
now(){ date -u +%Y-%m-%dT%H:%M:%SZ; }
case "${1:-}" in
  log) shift; EV="$1"; shift
    python3 - "$EV" "$@" <<'PY' >> "$F"
import json,sys,datetime
ev=sys.argv[1]; d={"ts":datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),"event":ev}
for kv in sys.argv[2:]:
    k,_,v=kv.partition("="); 
    try: v=int(v)
    except: pass
    d[k]=v
print(json.dumps(d,ensure_ascii=False))
PY
    ;;
  hook) python3 -c "
import json,sys,datetime
try: d=json.load(sys.stdin)
except Exception: sys.exit(0)
print(json.dumps({'ts':datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),'event':d.get('hook_event_name','subagent'),'agent':d.get('agent_type') or d.get('agent_name'),'session':d.get('session_id','')[:8]}))" >> "$F" 2>/dev/null; exit 0;;
  report) N="${2:-10}"; [ -f "$F" ] || { echo "METRICS: sem dados ainda"; exit 0; }
    python3 - "$F" "$N" <<'PY'
import json,sys,collections
rows=[json.loads(l) for l in open(sys.argv[1]) if l.strip()]
n=int(sys.argv[2])
feats=[r for r in rows if r["event"] in("feature","hotfix")][-n:]
rels=[r for r in rows if r["event"]=="release"][-5:]
sub=[r for r in rows if r["event"]=="SubagentStop"]
print(f"METRICS: {len(feats)} entregas recentes · {len(rels)} releases · {len(sub)} execuções de subagentes no total")
if feats:
    avg=sum(r.get("duration_s",0) for r in feats)/len(feats)
    cyc=sum(r.get("review_cycles",0) for r in feats)/len(feats)
    blk=sum(1 for r in feats if r.get("blocked"))
    print(f"  tempo médio por entrega: {avg/60:.0f} min · ciclos de review médios: {cyc:.1f} · bloqueadas: {blk}")
    for r in feats: print(f"  #{r.get('issue','?')} {r['event']}: {r.get('duration_s',0)//60} min · ondas {r.get('waves','?')} · review x{r.get('review_cycles','?')} · security {r.get('security','?')}" + (" · BLOQUEADA" if r.get("blocked") else ""))
c=collections.Counter(r.get("agent") for r in sub)
if c: print("  agentes mais usados: "+", ".join(f"{a} x{k}" for a,k in c.most_common(6)))
for r in rels: print(f"  release {r.get('version')}: gate {r.get('gate','?')} · skipped {r.get('skipped',0)} · {r.get('duration_s',0)//60} min")
PY
    ;;
  *) echo "uso: metrics.sh log|hook|report"; exit 1;;
esac
