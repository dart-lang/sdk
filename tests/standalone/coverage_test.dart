// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test forks a second vm process that runs the script tools/coverage.dart
// and verifies that the coverage tool produces its expected output.
// This test is mainly here to ensure that the coverage tool compiles and
// runs.

import "dart:io";
import "dart:utf";

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
    if (line.endsWith(sourceLines[nextLineToMatch])) {
      nextLineToMatch++;
    }
  }
}

void onCoverageExit(exitCode) {
  var pid = coverageToolProcess.pid;
  print("process $pid terminated with exit code $exitCode.");
  if (nextLineToMatch < sourceLines.length) {
    print("Error: could not match all source code lines of '$targPath'");
    exit(-1);
  } else {
    print("Successfully matched all lines of '$targPath'");
  }
}

void main() {
  var options = new Options();

  // Compute paths for coverage tool and coverage target relative
  // the the path of this script.
  var scriptPath = new Path(options.script).directoryPath;
  var toolPath = scriptPath.join(new Path(coverageToolScript)).canonicalize();
  targPath = scriptPath.join(new Path(coverageTargetScript)).canonicalize();

  sourceLines = new File(targPath.toNativePath()).readAsLinesSync();
  assert(sourceLines != null);

  var processOpts = [ "--compile_all",
                      toolPath.toNativePath(),
                      targPath.toNativePath() ];

  Process.start(options.executable, processOpts).then((Process process) {
    coverageToolProcess = process;
    coverageToolProcess.stdin.close();
    var stdoutStringStream = coverageToolProcess.stdout
        .transform(new StringDecoder())
        .transform(new LineTransformer());
    stdoutStringStream.listen(onCoverageOutput);

    var stderrStringStream = coverageToolProcess.stderr
        .transform(new StringDecoder())
        .transform(new LineTransformer());
    stderrStringStream.listen(onCoverageOutput);

    coverageToolProcess.exitCode.then(onCoverageExit);
  });
}
