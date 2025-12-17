# Dart support for perf

## Pause `perf stat` recording while GC is running (or vice versa)

`perf stat` supports starting and stopping the recording via `--control` and the
Dart VM can be instructed to either stop the recording while GC is running, or
specifically start while GC is running (and stop when GC is finished) with
`--perf_ctl_fd`, `--perf_ctl_fd_ack` (for file handles) and `--perf_ctl_usage`
(1 or 2) to specify if it should be paused while GCing (1) or started (and
stoped) while GCing (2).

These options can for instance be useful for testing performance changes in AOT
compiled dart together with `--deterministic`.

As an example one could run a script like this:

```
DART=$1
shift
AOTSNAPSHOT=$1
shift

[...]

perf_ctl_fd=$ctl_fd perf_ctl_fd_ack=$ctl_fd_ack perf stat --delay=-1 --control fd:${ctl_fd},${ctl_fd_ack} -B -e "task-clock:u,context-switches:u,cpu-migrations:u,page-faults:u,cycles:u,instructions:u,branch-misses:u" $DART --perf_ctl_fd=${ctl_fd} --perf_ctl_fd_ack=${ctl_fd_ack} --perf_ctl_usage=1 --deterministic $AOTSNAPSHOT $@

[...]
```

(the missing pieces can be found in the perf stat man page).

This will start `perf stat` paused (which would require the run dart
aot-compiled script to start it when it wants to) and where the VM pauses `perf`
while doing GC. Note that the recording will be started when GC is done, even if
it wasn't started before.
