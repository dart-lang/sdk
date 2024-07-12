// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:isolate' show Isolate, ReceivePort, SendPort;

import 'package:testing/src/log.dart' show Logger;
import 'package:testing/src/suite.dart';
import 'package:testing/testing.dart' as testing;

import 'presubmit_helper.dart';
import 'test/deps_git_test.dart' as deps_test;
import 'test/explicit_creation_impl.dart' show runExplicitCreationTest;
import 'test/fasta/messages_suite.dart' as messages_suite;
import 'test/lint_suite.dart' as lint_suite;
import 'test/spelling_test_not_src_suite.dart' as spelling_test_not_src;
import 'test/spelling_test_src_suite.dart' as spelling_test_src;

Future<void> main(List<String> args, [SendPort? sendPort]) async {
  if (sendPort == null) throw "Need a send-port.";
  var isolateReceivePort = ReceivePort();
  isolateReceivePort.listen((rawData) async {
    if (rawData is! String) {
      print("Got unexpected data of type ${rawData.runtimeType}");
      sendPort.send(false);
      return;
    }
    Work work = Work.workFromJson(json.decode(rawData));
    Stopwatch stopwatch = new Stopwatch()..start();
    switch (work) {
      case ExplicitCreationWork():
        int explicitCreationErrorsFound = -1;
        try {
          explicitCreationErrorsFound = await Isolate.run(() =>
              runExplicitCreationTest(
                  includedFiles: work.includedFiles,
                  includedDirectoryUris: work.includedDirectoryUris,
                  repoDir: work.repoDir));
        } catch (e) {
          // This will make it send false.
          explicitCreationErrorsFound = -1;
        }
        print("Sending ok = ${explicitCreationErrorsFound == 0} "
            "for ${work.name} after ${stopwatch.elapsed}");
        sendPort.send(explicitCreationErrorsFound == 0);

      case MessagesWork():
        bool ok;
        try {
          ok = await Isolate.run(() async {
            ErrorNotingLogger logger = new ErrorNotingLogger();
            await testing.runMe(
              const ["-DfastOnly=true"],
              messages_suite.createContext,
              me: work.repoDir
                  .resolve("pkg/front_end/test/fasta/messages_suite.dart"),
              configurationPath: "../../testing.json",
              logger: logger,
            );
            return !logger.gotFailure;
          });
        } catch (e) {
          ok = false;
        }
        print("Sending ok = $ok "
            "for ${work.name} after ${stopwatch.elapsed}");
        sendPort.send(ok);
      case SpellNotSourceWork():
        bool ok;
        try {
          ok = await Isolate.run(() async {
            ErrorNotingLogger logger = new ErrorNotingLogger();
            await testing.runMe(
              ["--", ...work.filters],
              spelling_test_not_src.createContext,
              me: work.repoDir.resolve(
                  "pkg/front_end/test/spelling_test_not_src_suite.dart"),
              configurationPath: "../testing.json",
              logger: logger,
            );
            return !logger.gotFailure;
          });
        } catch (e) {
          ok = false;
        }
        print("Sending ok = $ok "
            "for ${work.name} after ${stopwatch.elapsed}");
        sendPort.send(ok);
      case SpellSourceWork():
        bool ok;
        try {
          ok = await Isolate.run(() async {
            ErrorNotingLogger logger = new ErrorNotingLogger();
            await testing.runMe(
              ["--", ...work.filters],
              spelling_test_src.createContext,
              me: work.repoDir
                  .resolve("pkg/front_end/test/spelling_test_src_suite.dart"),
              configurationPath: "../testing.json",
              logger: logger,
            );
            return !logger.gotFailure;
          });
        } catch (e) {
          ok = false;
        }
        print("Sending ok = $ok "
            "for ${work.name} after ${stopwatch.elapsed}");
        sendPort.send(ok);
      case LintWork():
        bool ok;
        try {
          ok = await Isolate.run(() async {
            ErrorNotingLogger logger = new ErrorNotingLogger();
            await testing.runMe(
              ["--", ...work.filters],
              lint_suite.createContext,
              me: work.repoDir.resolve("pkg/front_end/test/lint_suite.dart"),
              configurationPath: "../testing.json",
              logger: logger,
            );
            return !logger.gotFailure;
          });
        } catch (e) {
          ok = false;
        }
        print("Sending ok = $ok "
            "for ${work.name} after ${stopwatch.elapsed}");
        sendPort.send(ok);
      case DepsTestWork():
        bool ok;
        try {
          ok = await Isolate.run(() {
            return deps_test.main();
          });
        } catch (e) {
          ok = false;
        }
        print("Sending ok = $ok "
            "for ${work.name} after ${stopwatch.elapsed}");
        sendPort.send(ok);
    }
  });
  sendPort.send(isolateReceivePort.sendPort);
}

class ErrorNotingLogger implements Logger {
  bool gotFailure = false;

  @override
  void logExpectedResult(Suite suite, testing.TestDescription description,
      testing.Result result, Set<testing.Expectation> expectedOutcomes) {}

  @override
  void logMessage(Object message) {}

  @override
  void logNumberedLines(String text) {}

  @override
  void logProgress(String message) {}

  @override
  void logStepComplete(
      int completed,
      int failed,
      int total,
      Suite suite,
      testing.TestDescription description,
      testing.Step<dynamic, dynamic, testing.ChainContext> step) {}

  @override
  void logStepStart(
      int completed,
      int failed,
      int total,
      Suite suite,
      testing.TestDescription description,
      testing.Step<dynamic, dynamic, testing.ChainContext> step) {}

  @override
  void logSuiteComplete(Suite suite) {}

  @override
  void logSuiteStarted(Suite suite) {}

  @override
  void logTestComplete(int completed, int failed, int total, Suite suite,
      testing.TestDescription description) {}

  @override
  void logTestStart(int completed, int failed, int total, Suite suite,
      testing.TestDescription description) {}

  @override
  void logUncaughtError(error, StackTrace stackTrace) {
    print("Uncaught Error: $error\n$stackTrace");
    gotFailure = true;
  }

  // package:testing logs the result twice: As it happens and at the end.
  // I don't want that so for now I'll maintain a set of already reported
  // test results.
  Set<testing.Result> alreadyReportedResults = {};

  @override
  void logUnexpectedResult(Suite suite, testing.TestDescription description,
      testing.Result result, Set<testing.Expectation> expectedOutcomes) {
    if (!alreadyReportedResults.add(result)) return;

    String log = result.log;
    if (log.isNotEmpty) {
      print(log);
    }
    if (result.error != null) {
      print(result.error);
      if (result.trace != null) {
        print(result.trace);
      }
    }

    gotFailure = true;
  }

  @override
  void noticeFrameworkCatchError(error, StackTrace stackTrace) {
    print("Framework Catch Error: $error\n$stackTrace");
    gotFailure = true;
  }
}
