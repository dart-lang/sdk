// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

const bool debug = false;

/// Tool to find and display any process using perf_events which as a
/// consequence might use one of the hardware counters, leaving fewer for
/// `perf stat` stuff.
/// Likely has to be run as root.
void main() {
  try {
    mainImpl();
  } catch (e) {
    print("Got the error '$e'.");
    print("");
    print("┌───────────────────────────────────────────────────┐");
    print("│ Note that this tool likely has to be run as root. │");
    print("└───────────────────────────────────────────────────┘");
    print("");
    rethrow;
  }
}

void mainImpl() {
  if (!Platform.isLinux) {
    throw "This tool only works in Linux.";
  }
  bool foundSomething = false;
  Directory dir = new Directory("/proc/");
  for (FileSystemEntity pidDir in dir.listSync(recursive: false)) {
    if (pidDir is! Directory) continue;
    Uri pidUri = pidDir.uri;
    String possiblePid = pidUri.pathSegments[pidUri.pathSegments.length - 2];
    int? candidatePid = int.tryParse(possiblePid);
    if (candidatePid == null) continue;
    Directory fdDir = new Directory.fromUri(pidDir.uri.resolve("fd/"));
    int count = 0;
    for (FileSystemEntity entry in fdDir.listSync()) {
      if (debug) {
        print("$entry");
      }
      if (entry is Link) {
        String target = entry.targetSync();
        if (debug) {
          print(" => target: $target");
        }
        if (target.contains("perf_event")) {
          count++;
        }
      }
    }
    if (count > 0) {
      print("Found $count perf event file descriptors for "
          "process with pid $candidatePid:");
      runPsForPid(candidatePid);
      print("");
      foundSomething = true;
    }
  }

  if (!foundSomething) {
    print("Found no open perf file descriptors.");
    return;
  }
}

void runPsForPid(int pid) {
  ProcessResult psRun = Process.runSync("ps", ["-p", "$pid", "u"]);
  stdout.write(psRun.stdout);
  stderr.write(psRun.stderr);
}
