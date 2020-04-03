// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library testing.log;

import 'dart:io' show stdout;

import 'chain.dart' show Result, Step;

import 'suite.dart' show Suite;

import 'test_description.dart' show TestDescription;

import 'expectation.dart' show Expectation;

/// ANSI escape code for moving cursor one line up.
/// See [CSI codes](https://en.wikipedia.org/wiki/ANSI_escape_code#CSI_codes).
const String cursorUpCodes = "\u001b[1A";

/// ANSI escape code for erasing the entire line.
/// See [CSI codes](https://en.wikipedia.org/wiki/ANSI_escape_code#CSI_codes).
const String eraseLineCodes = "\u001b[2K";

final bool enableAnsiEscapes = stdout.supportsAnsiEscapes;

final String cursorUp = enableAnsiEscapes ? cursorUpCodes : "";

final String eraseLine = enableAnsiEscapes ? eraseLineCodes : "";

final Stopwatch wallclock = new Stopwatch()..start();

bool _isVerbose = const bool.fromEnvironment("verbose");

bool get isVerbose => _isVerbose;

void enableVerboseOutput() {
  _isVerbose = true;
}

abstract class Logger {
  void logTestStart(int completed, int failed, int total, Suite suite,
      TestDescription description);

  void logTestComplete(int completed, int failed, int total, Suite suite,
      TestDescription description);

  void logStepStart(int completed, int failed, int total, Suite suite,
      TestDescription description, Step step);

  void logStepComplete(int completed, int failed, int total, Suite suite,
      TestDescription description, Step step);

  void logProgress(String message);

  void logMessage(Object message);

  void logNumberedLines(String text);

  void logExpectedResult(Suite suite, TestDescription description,
      Result result, Set<Expectation> expectedOutcomes);

  void logUnexpectedResult(Suite suite, TestDescription description,
      Result result, Set<Expectation> expectedOutcomes);

  void logSuiteStarted(Suite suite);

  void logSuiteComplete(Suite suite);

  void logUncaughtError(error, StackTrace stackTrace);
}

class StdoutLogger implements Logger {
  const StdoutLogger();

  void logTestStart(int completed, int failed, int total, Suite suite,
      TestDescription description) {}

  void logTestComplete(int completed, int failed, int total, Suite suite,
      TestDescription description) {
    String message = formatProgress(completed, failed, total);
    if (suite != null) {
      message += ": ${formatTestDescription(suite, description)}";
    }
    logProgress(message);
  }

  void logStepStart(int completed, int failed, int total, Suite suite,
      TestDescription description, Step step) {
    String message = formatProgress(completed, failed, total);
    if (suite != null) {
      message += ": ${formatTestDescription(suite, description)} ${step.name}";
      if (step.isAsync) {
        message += "...";
      }
    }
    logProgress(message);
  }

  void logStepComplete(int completed, int failed, int total, Suite suite,
      TestDescription description, Step step) {
    if (!step.isAsync) return;
    String message = formatProgress(completed, failed, total);
    if (suite != null) {
      message += ": ${formatTestDescription(suite, description)} ${step.name}!";
    }
    logProgress(message);
  }

  void logProgress(String message) {
    if (isVerbose) {
      print(message);
    } else {
      print("$eraseLine$message$cursorUp");
    }
  }

  String formatProgress(int completed, int failed, int total) {
    Duration elapsed = wallclock.elapsed;
    String percent = pad((completed / total * 100.0).toStringAsFixed(1), 5);
    String good = pad(completed - failed, 5);
    String bad = pad(failed, 5);
    String minutes = pad(elapsed.inMinutes, 2, filler: "0");
    String seconds = pad(elapsed.inSeconds % 60, 2, filler: "0");
    return "[ $minutes:$seconds | $percent% | +$good | -$bad ]";
  }

  String formatTestDescription(Suite suite, TestDescription description) {
    return "${suite.name}/${description.shortName}";
  }

  void logMessage(Object message) {
    if (isVerbose) {
      print("$message");
    }
  }

  void logNumberedLines(String text) {
    if (isVerbose) {
      print(numberedLines(text));
    }
  }

  void logExpectedResult(Suite suite, TestDescription description,
      Result result, Set<Expectation> expectedOutcomes) {}

  void logUnexpectedResult(Suite suite, TestDescription description,
      Result result, Set<Expectation> expectedOutcomes) {
    print("${eraseLine}UNEXPECTED: ${suite.name}/${description.shortName}");
    Uri statusFile = suite.statusFile;
    if (statusFile != null) {
      String path = statusFile.toFilePath();
      if (result.outcome == Expectation.Pass) {
        print("The test unexpectedly passed, please update $path.");
      } else {
        print("The test had the outcome ${result.outcome}, but the status file "
            "($path) allows these outcomes: ${expectedOutcomes.join(' ')}");
      }
    }
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
  }

  void logSuiteStarted(Suite suite) {
    print("Running suite ${suite.name}...");
  }

  void logSuiteComplete(Suite suite) {
    if (!isVerbose) {
      print("");
    }
  }

  void logUncaughtError(error, StackTrace stackTrace) {
    logMessage(error);
    if (stackTrace != null) {
      logMessage(stackTrace);
    }
  }
}

String pad(Object o, int pad, {String filler: " "}) {
  String result = (filler * pad) + "$o";
  return result.substring(result.length - pad);
}

String numberedLines(String text) {
  StringBuffer result = new StringBuffer();
  int lineNumber = 1;
  List<String> lines = splitLines(text);
  int pad = "${lines.length}".length;
  String fill = " " * pad;
  for (String line in lines) {
    String paddedLineNumber = "$fill$lineNumber";
    paddedLineNumber =
        paddedLineNumber.substring(paddedLineNumber.length - pad);
    result.write("$paddedLineNumber: $line");
    lineNumber++;
  }
  return '$result';
}

List<String> splitLines(String text) {
  return text.split(new RegExp('^', multiLine: true));
}
