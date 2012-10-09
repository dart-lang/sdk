// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import('dart:io');

void runTests(String executable, String script, Iterator iterator) {
  if (iterator.hasNext()) {
    var progressIndicator = iterator.next();
    Process.run(executable, [script, progressIndicator]).then((result) {
      Expect.equals(1, result.exitCode);
      if (progressIndicator == 'buildbot') {
        Expect.isTrue(result.stdout.contains("@@@STEP_FAILURE@@@"));
      }
      runTests(executable, script, iterator);
    });
  }
}

main() {
  var scriptPath = new Path.fromNative(new Options().script);
  var scriptDirPath = scriptPath.directoryPath;
  var exitCodeScriptPath =
    scriptDirPath.append('test_runner_exit_code_script.dart');
  var script = exitCodeScriptPath.toNativePath();
  var executable = new Options().executable;
  var progressTypes = ['compact', 'color', 'line', 'verbose',
                       'status', 'buildbot'];
  var iterator = progressTypes.iterator();
  runTests(executable, script, iterator);
}
