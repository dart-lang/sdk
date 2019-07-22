<!-- TODO(bkonyi): Eventually remove this file once all methods and classes are
either officially supported or have their uses removed throughout tooling.-->
** This file is locked as of 2019/07/19 and no further additions will be
accepted. If you require access to a private API in the service protocol,
please reach out to bkonyi@.**

Undocumented (and currently unsupported) service methods and classes.

### _collectAllGarbage

```
Success _collectAllGarbage(string isolateId)
```

Trigger a full GC, collecting all unreachable or weakly reachable objects.

### _requestHeapSnapshot

```
Success _requestHeapSnapshot(string isolateId, string roots, bool collectGarbage)
```

_roots_ is one of User or VM. The results are returned as a stream of
[_Graph] events.

### _clearCpuProfile

```
Success _clearCpuProfile(string isolateId)
```

### _getCpuProfile

```
_CpuProfile _getCpuProfile(string isolateId, string tags)
```

_tags_ is one of UserVM, UserOnly, VMUser, VMOnly, or None.

### _CpuProfile

```
class _CpuProfile extends Response {
  int sampleCount;
  int samplePeriod;
  int stackDepth;
  double timeSpan;
  int timeOriginMicros;
  int timeExtentMicros;
  CodeRegion[] codes;
  ProfileFunction[] functions;
  int[] exclusiveCodeTrie;
  int[] inclusiveCodeTrie;
  int[] exclusiveFunctionTrie;
  int[] inclusiveFunctionTrie;
}
```

### CodeRegion

```
class CodeRegion {
  string kind;
  int inclusiveTicks;
  int exclusiveTicks;
  @Code code;
}
```

<!-- <string|int>[] ticks -->

### ProfileFunction

```
class ProfileFunction {
  string kind;
  int inclusiveTicks;
  int exclusiveTicks;
  @Function function;
  int[] codes;
}
```

<!-- <string|int>[] ticks -->

### AllocationProfile

```
class AllocationProfile extends Response {
  string dateLastServiceGC;
  ClassHeapStats[] members;
}
```

<!-- TODO: int dateLastServiceGC -->

### ClassHeapStats

```
class ClassHeapStats extends Response {
  @Class class;
  int[] new;
  int[] old;
  int promotedBytes;
  int promotedInstances;
}
```

### HeapSpace

```
class HeapSpace extends Response {
  double avgCollectionPeriodMillis;
  int capacity;
  int collections;
  int external;
  String name;
  double time;
  int used;
}
```

<!-- _CpuProfile -->
<!--
    counters: _JsonMap
    codes: JSArray
    functions: JSArray
    exclusiveCodeTrie: JSArray
    inclusiveCodeTrie: JSArray
    exclusiveFunctionTrie: JSArray
    inclusiveFunctionTrie: JSArray
  -->

<!-- _getCpuProfileTimeline -->

<!-- _getAllocationSamples -->
