// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

int _perfPid = -1;

/// Helper for creating a perf snapshot when running via perf or magic-trace.
///
/// The linux `perf` tool (and the magic-trace tool which wraps the perf tool
/// and post-processes the result) can record "Intel Processor Trace" which
/// can then be used to produce nano-second level profiling.
///
/// Notice that this (probably) only works on Linux, and certainly only on
/// "newer" Intel processors (the perf man page says "first supported in
/// Intel Core M and 5th generation Intel Core processors" - so no older than
/// that, and not on AMD processors for instance).
///
/// The `perf` tool continuously records into a fixed-size ring-buffer, and only
/// "really saves" the data when asked to do a snapshot.
///
/// This method asks it to take the snapshot, i.e. you calls it *after* the
/// thing one wants to profile has run.
///
/// Notice that the actual snapshot is taken a short amount of time after the
/// call, likely because if the message propagating.
///
/// Also notice that it only records a very short duration. One will then get
/// ~nanosecond resolution though.
///
/// # Usage example:
///
/// Compile an aot snapshot like this:
///
/// ```
/// out/ReleaseX64/dart-sdk/bin/dart compile aot-snapshot \
///   <dart script>
/// ```
///
/// You might also want the dartaotruntime to include debug symbols:
///
/// ```
/// cp out/ReleaseX64/dartaotruntime_product \
///   out/ReleaseX64/dart-sdk/bin/dartaotruntime
/// ```
///
/// Now one can e.g. run via perf with something like this:
///
/// ```
/// perf record --event=intel_pt/cyc=1,cyc_thresh=1,mtc_period=0/u \
///   --timestamp --snapshot \
///   out/ReleaseX64/dart-sdk/bin/dartaotruntime \
///   <aot compiled script> <args>
/// ```
///
/// One could also use
/// `--event=intel_pt/cyc=1,cyc_thresh=1,mtc_period=0,noretcomp=1/u` and
/// possibly add something like `-m,256`. Or one could use `--snapshot="e"` to
/// automatically take a snapshot when the process dies.
///
/// In the code, do an initial call to this method with [onlyInitialize] set to
/// true to find the perf pid, then, once the code you want profiled has
/// executed call it again (with [onlyInitialize] set to false).
///
/// And one can then use something like
///
/// ```
/// perf script -F +cpu,-dso --tid=<tid> \
///   --dsos=/path/to/aot/compiled/script.aot --call-ret-trace
/// ```
///
/// to inspect the result (though maybe first just via
/// `perf script --call-ret-trace` to extract the other parts).
///
///
/// Or run with magic-trace via something like:
///
/// ```
/// ./magic-trace run -trigger tcsetattr -multi-thread -snapshot-size 1M \
///   -timer-resolution high \
///   out/ReleaseX64/dart-sdk/bin/dartaotruntime -- \
///   <aot compiled script> <args>
/// ```
/// (here it's asked to trigger on `tcsetattr` but that part doesn't seem to
/// work for whatever reason which is why we now have this).
///
/// and visualize the output file via
/// https://ui.perfetto.dev/
/// or
/// https://magic-trace.org/
///
/// It seems that multiple signals is fine, but the output result will grow
/// accordingly and the tools can have a hard time processing files that are
/// too big.
void linuxAndIntelSpecificPerf({bool onlyInitialize = false}) {
  if (!Platform.isLinux) {
    print("Error: Only supports Linux!");
    return;
  }

  if (_perfPid == -1) {
    // Currently not looked for yet. First mark that we have looked for it.
    _perfPid = -2;

    int? parentPidInt = _getParentPid(pid);
    if (parentPidInt == null) {
      print("Error: Couldn't find parent pid");
      return;
    }
    List<String>? cmdlines = _getPidCommandLine(parentPidInt);
    if (cmdlines == null) {
      print("Error: Parent cmdline file didn't exist.");
    } else if (cmdlines[0] == "perf" || cmdlines[0] == "/usr/bin/perf") {
      _perfPid = parentPidInt;
    } else if (cmdlines[0] == "magic-trace" ||
        cmdlines[0].endsWith("/magic-trace")) {
      // Search for perf process... For now blindly search from the parent pid
      // and 50 pids forward.
      pidSearch:
      for (int i = parentPidInt + 1; i < parentPidInt + 50; i++) {
        List<String>? cmdlines = _getPidCommandLine(i);
        if (cmdlines == null) continue;
        if (cmdlines[0] == "perf" || cmdlines[0] == "/usr/bin/perf") {
          // Extra check --- the perf tool is started with "-p <$pid>",
          // so verify that it contains this processes pid for good measure.
          for (int j = 1; j < cmdlines.length; j++) {
            if (cmdlines[j] == "$pid") {
              _perfPid = i;
              break pidSearch;
            }
          }
        }
      }
      if (_perfPid <= 0) {
        print("Error: Couldn't find perf.");
      }
    } else {
      print("Error: Unknown parent command: ${cmdlines[0]}");
    }
  }
  if (onlyInitialize || _perfPid <= 0) return;

  // From the perf man page: "In Snapshot Mode trace data is captured only when
  // signal SIGUSR2 is received and on exit if the above e option is given".
  // So we now signal that we want a snapshot by sending the sigusr2 signal.
  Process.killPid(_perfPid, ProcessSignal.sigusr2);
  print("Notice: Send snapshot signal to perf.");
}

int? _getParentPid(int pid) {
  File f = new File("/proc/${pid}/status");
  if (!f.existsSync()) return null;
  for (String line in f.readAsLinesSync()) {
    if (line.startsWith("PPid:")) {
      String parentPid = line.substring("PPid:".length).trim();
      return int.parse(parentPid);
    }
  }
  return null;
}

List<String>? _getPidCommandLine(int pid) {
  File f = new File("/proc/$pid/cmdline");
  if (!f.existsSync()) return null;
  String cmdline = f.readAsStringSync();
  return cmdline.split("\u{0}");
}
