// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:async';
import 'dart:collection';

final String cit = Platform.isWindows ? 'cit.bat' : 'cit';

class LogdogException implements Exception {
  final int errorCode;
  final String stdout;
  final String stderr;

  LogdogException(this.errorCode, this.stdout, this.stderr);
  LogdogException.fromProcessResult(ProcessResult result)
      : this(result.exitCode, result.stdout, result.stderr);

  toString() => "Error during logdog execution:\n$stderr";
}

bool logdogCheckDone = false;

void checkLogdog({bool tryToInstall: true}) {
  if (logdogCheckDone) return;
  var result = Process.runSync(cit, []);
  if (result.exitCode != 0) {
    print("cit (from depot_tools) must be in the path.");
    throw new StateError("cit not accessible");
  }
  String stdout = result.stdout;
  if (stdout.contains("logdog")) {
    logdogCheckDone = true;
    return;
  }
  if (tryToInstall) {
    print("logdog isn't yet installed. Installation might take some time");
    result = Process.runSync(cit, ["logdog"]);
    checkLogdog(tryToInstall: false);
  } else {
    print("Couldn't install logdog");
    throw new StateError("logdog not accessible");
  }
}

String logdog(List<String> args) {
  checkLogdog();
  args = args.toList()..insert(0, "logdog");
  var result = Process.runSync(cit, args);
  if (result.exitCode == 0) return result.stdout;
  throw new LogdogException.fromProcessResult(result);
}

String cat(String log) {
  return logdog(["cat", "-raw", log]);
}

/// Returns the content for [path], for instance the available build numbers
/// for 'dart2js-linux-chromeff-1-4-be' using the path
/// `chromium/bb/client.dart/dart2js-linux-chromeff-1-4-be`.
String ls(String path) {
  return logdog(["ls", path]);
}

class LogResult<T> {
  final String log;
  final T result;

  LogResult(this.log, this.result);
}

const int maxConcurrentLogdogs = 20;

/// Fetches the given [logs] concurrently using [logdog].
///
/// At most [maxConcurrentLogdogs] connections are opened at the same time.
///
/// The resulting [LogResult] has a [LogResult.result] equal to `null` if
/// the log didn't exist.
Stream<LogResult<String>> catN(Iterable<String> logs) async* {
  var queue = new Queue<Future<LogResult<ProcessResult>>>();
  var it = logs.iterator;

  // Launches a new logdog to fetch the next log.
  // Returns false when nothing was left to enqueue.
  bool enqueueNext() {
    if (!it.moveNext()) return false;
    var log = it.current;
    queue.add(new Future.sync(() async {
      var logPath = log.substring(0, log.lastIndexOf("/"));
      var lsResult = await Process.run(cit, ["logdog", "ls", logPath]);
      if (lsResult.exitCode != 0) return new LogResult(log, lsResult);
      if (lsResult.stdout == "") return new LogResult(log, null);
      return new LogResult(
          log, await Process.run(cit, ["logdog", "cat", "-raw", log]));
    }));
    return true;
  }

  for (int i = 0; i < maxConcurrentLogdogs; i++) {
    enqueueNext();
  }

  while (queue.isNotEmpty) {
    var logResult =
        await queue.removeFirst().timeout(const Duration(seconds: 15));
    enqueueNext();
    if (logResult.result == null) {
      yield new LogResult(logResult.log, null);
    } else if (logResult.result.exitCode != 0) {
      throw new LogdogException.fromProcessResult(logResult.result);
    } else {
      yield new LogResult(logResult.log, logResult.result.stdout);
    }
  }
}

/*
main() async {
//  print(cat(
//      "chromium/bb/client.dart/dart2js-win7-ie11ff-4-4-be/4215/+/recipes/steps/dart2js_ie11_tests/0/stdout"));
  catN(new Iterable.generate(10, (i) {
    return "chromium/bb/client.dart/dart2js-win7-ie11ff-4-4-be/"
        "${4200 + i}"
        "/+/recipes/steps/dart2js_ie11_tests/0/stdout";
  })).listen((logResult) {
    print("--------------------------");
    if (logResult.result == null) {
      print("${logResult.log} - empty");
    } else {
      print(logResult.result.substring(0, 200));
    }
  });
}
*/
