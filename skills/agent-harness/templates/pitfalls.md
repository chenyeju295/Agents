---
status: active
kind: pitfalls
---

# Known Pitfalls

Documented traps: symptom → root cause → fix, so a future agent lands the
correct solution immediately instead of re-deriving it. Add an entry the first
time a non-obvious trap costs real time. Do not pre-populate hypotheticals.

Group by area (e.g. build, concurrency, platform, a specific library).

---

## <AREA>

### <Short symptom as the reader would search for it>

**Symptom:** <what the developer/agent observes — error text, wrong behavior.>

**Root cause:** <the actual underlying reason, not the surface symptom.>

**Fix:**

```<lang>
<the minimal correct code / config / command>
```

<Optional: why the obvious-but-wrong fix is wrong, so it isn't reintroduced.>

---
