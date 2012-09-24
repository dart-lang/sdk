// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A RunClientServerTask is like a regular RunProcessTask except it starts
 * an HTTP server before the task and stops it afterwards, so the task
 * would typically be making HTTP client requests.
 */
class RunClientServerTask extends RunProcessTask {
  RunProcessTask serverTask;
  Process serverProcess;

  RunClientServerTask(String commandTemplate, List argumentTemplates,
      int timeout) : super(commandTemplate, argumentTemplates, timeout) {
    serverTask = new RunProcessTask(
        config.dartPath,
        ['$runnerDirectory${Platform.pathSeparator}'
            'http_server_test_runner.dart',
            '--port=${config.port}',
            '--root=${config.staticRoot}'],
        1000 * timeout);
  }

  execute(Path testfile, List stdout, List stderr,
                        bool logging, Function exitHandler) {
    serverProcess = serverTask.execute(testfile, stdout, stderr, logging,
        (e) { serverProcess = null; });
    super.execute(testfile, stdout, stderr, logging, exitHandler);
  }

  void cleanup(Path testfile, List stdout, List stderr,
               bool verboseLogging, bool keepTestFiles) {
    if (serverProcess != null) {
      serverProcess.kill();
    }
  }
}