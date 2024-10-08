Various tools for low level profing of code running on the Dart VM.

# Uprobe based profiling

[uprobes](https://www.kernel.org/doc/html/latest/trace/uprobetracer.html) is
a user-space dynamic tracing mechanism. Using this mechanism the kernel can
be instructed to place a tracepoint at a particular file offset within a
specific binary. Whenever this tracepoint is hit the kernel will fetch values
from the execution context based on the uprobe's description and emit an event.
A developer can subscribe to uprobe events in a few different ways including
[perf_event_open](https://man7.org/linux/man-pages/man2/perf_event_open.2.html)
syscall. uprobes have been enabled by default on all newish Linux kernels
(4.14+), however they are only truly usable on Android/ARM64 starting from
5.10+. `bin/set_uprobe.dart` is a helper script for placing uprobes inside
binaries and using this for profiling.

The core workflow looks like this:

```console
$ sudo $(which dart) runtime/tools/profiling/bin/set_uprobe.dart probeName symbol binary
```

This will create an uprobe with name `probeName` which triggers whenever
the given `symbol` inside the given `binary` is called. You can then record
an event (and collect the call stack) using:

```console
$ sudo perf record -g -e uprobes:probeName ...
```

## Allocation profiling with uprobes

AOT compiler can emit a special probe point (`stub AllocationProbePoint`) which
triggers for each new space allocation from generated code. `set_uprobe` script
has special support for this probe point: it will configure probe point to
record additional information (address of allocated object, allocation top and
cid of the allocated object) allowing to post process collected data into
an actual allocation profile.

Start by compiling your application with `--generate-probe-points`:

```console
$ pkg/vm/tool/precompiler2 --generate-probe-points test.dart test.aot
```

Then install uprobe on `AllocationProbePoint`:

```console
$ sudo $(which dart) runtime/tools/profiling/bin/set_uprobe.dart alloc AllocationProbePoint test.aot
```

Record the profile:

```
$ sudo perf record -g -e uprobes:alloc out/ReleaseX64/dart_precompiled_runtime test.aot
$ sudo chmod 0755 perf.data
```

Produce a coalesced allocation profile from the recording:

```
$ dart runtime/tools/profiling/bin/convert_allocation_profile.dart perf.data
$ pprof -flame pprof.profile
```