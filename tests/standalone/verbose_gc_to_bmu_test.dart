// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test forks a second vm process that runs the BMU tool and verifies that
// it produces some output. This test is mainly here to ensure that the BMU
// tool compiles and runs.

import "dart:async";
import "dart:convert";
import "dart:io";

import "package:path/path.dart";

// Tool script relative to the path of this test.
var toolScript = "../../runtime/tools/verbose_gc_to_bmu.dart";

// Target script relative to this test.
var targetScript = "../language/gc_test.dart";
const minOutputLines = 20;

void checkExitCode(exitCode) {
  if (exitCode != 0) {
    print("Process terminated with exit code ${exitCode}.");
    exit(-1);
  }
}

void main() {
  // Compute paths for tool and target relative to the path of this script.
  var scriptDir = dirname(Platform.script.toFilePath());
  var targPath = normalize(join(scriptDir, targetScript));
  var targetResult =
      Process.runSync(Platform.executable, ["--verbose_gc", targPath]);
  checkExitCode(targetResult.exitCode);
  var gcLog = targetResult.stderr;
  var toolPath = normalize(join(scriptDir, toolScript));
  Process.start(Platform.executable, [toolPath]).then((Process process) {
    // Feed the GC log of the target to the BMU tool.
    process.stdin.write(gcLog);
    process.stdin.close();
    var stdoutStringStream = process.stdout
        .transform(UTF8.decoder)
        .transform(new LineSplitter());
    var stderrStringStream = process.stderr
        .transform(UTF8.decoder)
        .transform(new LineSplitter());
    // Wait for 3 future events: stdout and stderr streams closed, and
    // process terminated.
    var futures = [];
    var stdoutLines = [];
    var stderrLines = [];
    var subscription = stdoutStringStream.listen(stdoutLines.add);
    futures.add(subscription.asFuture(true));
    subscription = stderrStringStream.listen(stderrLines.add);
    futures.add(subscription.asFuture(true));
    futures.add(process.exitCode.then(checkExitCode));
    Future.wait(futures).then((results) {
      if (stderrLines.isNotEmpty) {
        print("Unexpected output on stderr:");
        print(stderrLines.join('\n'));
        exit(-1);
      }
      if (stdoutLines.length < minOutputLines) {
        print("Less than expected output on stdout:");
        print(stdoutLines.join('\n'));
        exit(-1);
      }
    });
  });
}
