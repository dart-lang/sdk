// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test forks a second vm process that runs the script tools/coverage.dart
// and verifies that the coverage tool produces its expected output.
// This test is mainly here to ensure that the coverage tool compiles and
// runs.

import "dart:io";
import "dart:async";

// Coverage tool script relative to the path of this test.
var coverageToolScript = "../../tools/coverage.dart";

// Coverage target script relative to this test.
var coverageTargetScript = "../language/hello_dart_test.dart";
var targPath;

Process coverageToolProcess;
List sourceLines;
int nextLineToMatch = 0;

void onCoverageOutput(String line) {
  print("COV: $line");
  if (nextLineToMatch < sourceLines.length) {
    if (line.endsWith("|" + sourceLines[nextLineToMatch])) {
      nextLineToMatch++;
    }
  }
}

bool checkExitCode(exitCode) {
  var pid = coverageToolProcess.pid;
  print("Coverage tool process (pid $pid) terminated with "
        "exit code $exitCode.");
  return exitCode == 0;
}

void checkSuccess() {
  if (nextLineToMatch == sourceLines.length) {
    print("Successfully matched all lines of '$targPath'");
  } else {
    print("Error: could not match all source code lines of '$targPath'");
    exit(-1);
  }
}

void main() {
  // Compute paths for coverage tool and coverage target relative
  // the the path of this script.
  var scriptPath = new Path(Platform.script).directoryPath;
  var toolPath = scriptPath.join(new Path(coverageToolScript)).canonicalize();
  targPath = scriptPath.join(new Path(coverageTargetScript)).canonicalize();

  sourceLines = new File(targPath.toNativePath()).readAsLinesSync();
  assert(sourceLines != null);

  var processOpts = [ "--compile_all",
                      toolPath.toNativePath(),
                      targPath.toNativePath() ];

  Process.start(Platform.executable, processOpts).then((Process process) {
    coverageToolProcess = process;
    coverageToolProcess.stdin.close();
    var stdoutStringStream = coverageToolProcess.stdout
        .transform(new StringDecoder())
        .transform(new LineTransformer());

    var stderrStringStream = coverageToolProcess.stderr
        .transform(new StringDecoder())
        .transform(new LineTransformer());

    // Wait for 3 future events: stdout and stderr streams of the coverage
    // tool process closed, and coverage tool process terminated.
    var futures = [];
    var subscription = stdoutStringStream.listen(onCoverageOutput);
    futures.add(subscription.asFuture(true));
    subscription = stderrStringStream.listen(onCoverageOutput);
    futures.add(subscription.asFuture(true));
    futures.add(coverageToolProcess.exitCode.then(checkExitCode));
    Future.wait(futures).then((results) {
      checkSuccess();
      if (results.contains(false)) exit(-1);
    });
  });
}
