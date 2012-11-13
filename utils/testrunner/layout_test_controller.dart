// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The following set of variables should be set by the caller that
// #sources this file.
/** Whether to include elapsed time. */

part of test_controller;

bool includeTime;

/** Path to DRT executable. */
String drt;

/** Whether to regenerate layout test files. */
bool regenerate;

/** Whether to output test summary. */
bool summarize;

/** Whether  to print results immediately as they come in. */
bool immediate;

/** Format strings to use for test result messages. */
String passFormat, failFormat, errorFormat, listFormat;

/** Location of the running test file. */
String sourceDir;

/** Path of the running test file. */
String testfile;

/** URL of the child test file. */
String baseUrl;

/** The print function to use. */
Function tprint;

/** A callback function to notify the caller we are done. */
Function notifyDone;

// Variable below here are local to this file.
var passCount = 0, failCount = 0, errorCount = 0;
Date start;

class Macros {
  static const String testTime = '<TIME>';
  static const String testfile = '<FILENAME>';
  static const String testGroup = '<GROUPNAME>';
  static const String testDescription = '<TESTNAME>';
  static const String testMessage = '<MESSAGE>';
  static const String testStacktrace = '<STACK>';
}

String formatMessage(filename, groupname,
    [testname = '', testTime = '', result = '',
      message = '', stack = '']) {
  var format = errorFormat;
  if (result == 'pass') format = passFormat;
  else if (result == 'fail') format = failFormat;
  return format.
      replaceAll(Macros.testTime, testTime).
      replaceAll(Macros.testfile, filename).
      replaceAll(Macros.testGroup, groupname).
      replaceAll(Macros.testDescription, testname).
      replaceAll(Macros.testMessage, message).
      replaceAll(Macros.testStacktrace, stack);
}

void outputResult(start, label, result, [message = '']) {
  var idx = label.lastIndexOf('###');
  var group = '', test = '';
  if (idx >= 0) {
    group = '${label.substring(0, idx).replaceAll("###", " ")} ';
    test = '${label.substring(idx+3)} ';
  } else {
    test = '$label ';
  }
  var elapsed = '';
  if (includeTime) {
    var end = new Date.now();
    double duration = (end.difference(start)).inMilliseconds.toDouble();
    duration /= 1000;
    elapsed = '${duration.toStringAsFixed(3)}s ';
  }
  tprint(formatMessage('$testfile ', group, test, elapsed, result, message));
}

pass(start, label) {
  ++passCount;
  outputResult(start, label, 'pass');
}

fail(start, label, message) {
  ++failCount;
  outputResult(start, label, 'fail', message);
}

error(start, label, message) {
  ++errorCount;
  outputResult(start, label, 'error', message);
}

void printSummary(String testFile, int passed, int failed, int errors,
    [String uncaughtError = '']) {
  tprint('');
  if (passed == 0 && failed == 0 && errors == 0) {
    tprint('$testFile: No tests found.');
  } else if (failed == 0 && errors == 0 && uncaughtError == null) {
    tprint('$testFile: All $passed tests passed.');
  } else {
    if (uncaughtError != null) {
      tprint('$testFile: Top-level uncaught error: $uncaughtError');
    }
    tprint('$testFile: $passed PASSED, $failed FAILED, $errors ERRORS');
  }
}

complete() {
  if (summarize) {
    printSummary(testfile, passCount, failCount, errorCount);
  }
  notifyDone(failCount > 0 ? -1 : 0);
}

runTextLayoutTest(testNum) {
  var url = '$baseUrl?test=$testNum';
  var stdout = new List();
  start = new Date.now();
  Process.start(drt, [url]).then((process) {
    // Drain stderr to not leak resources.
    process.stderr.onData = process.stderr.read;
    StringInputStream stdoutStringStream =
        new StringInputStream(process.stdout);
    stdoutStringStream.onLine = () {
      if (stdoutStringStream.closed) return;
      var line = stdoutStringStream.readLine();
      while (null != line) {
        stdout.add(line);
        line = stdoutStringStream.readLine();
      }
    };
    process.onExit = (exitCode) {
      process.close();
      if (stdout.length > 0 && stdout[stdout.length-1].startsWith('#EOF')) {
        stdout.removeLast();
      }
      var done = false;
      var i = 0;
      var label = null;
      var labelMarker = 'CONSOLE MESSAGE: #TEST ';
      var contentMarker = 'layer at ';
      while (i < stdout.length) {
        if (label == null && stdout[i].startsWith(labelMarker)) {
          label = stdout[i].substring(labelMarker.length);
          if (label == 'NONEXISTENT') {
            complete();
          }
        } else if (stdout[i].startsWith(contentMarker)) {
          if (label == null) {
            complete();
          }
          var expectedFileName =
              '$sourceDir${Platform.pathSeparator}'
              '${label.replaceAll("###", "_")
                      .replaceAll(const RegExp("[^A-Za-z0-9]"),"_")}.txt';
          var expected = new File(expectedFileName);
          if (regenerate) {
            var ostream = expected.openOutputStream(FileMode.WRITE);
            while (i < stdout.length) {
              ostream.writeString(stdout[i]);
              ostream.writeString('\n');
              i++;
            }
            ostream.close();
            pass(start, label);
          } else if (!expected.existsSync()) {
            fail(start, label, 'No expectation file');
          } else {
            var lines = expected.readAsLinesSync();
            var actualLength = stdout.length - i;
            var compareCount = min(lines.length, actualLength);
            var match = true;
            for (var j = 0; j < compareCount; j++) {
              if (lines[j] != stdout[i + j]) {
                fail(start, label, 'Expectation differs at line ${j + 1}');
                match = false;
                break;
              }
            }
            if (match) {
              if (lines.length != actualLength) {
                fail(start, label, 'Expectation file has wrong length');
              } else {
                pass(start, label);
              }
            }
          }
          done = true;
          break;
        }
        i++;
      }
      if (label != null) {
        if (!done) error(start, label, 'Failed to parse output');
        runTextLayoutTest(testNum + 1);
      }
    };
  });
}

runPixelLayoutTest(int testNum) {
  var url = '$baseUrl?test=$testNum';
  var stdout = new List();
  start = new Date.now();
  Process.start(drt, ["$url'-p"]).then((process) {
    // Drain stderr to not leak resources.
    process.stderr.onData = process.stderr.read;
    ListInputStream stdoutStream = process.stdout;
    stdoutStream.onData = () {
      if (!stdoutStream.closed) {
        var data = stdoutStream.read();
        stdout.addAll(data);
      }
    };
    stdoutStream.onError = (e) {
      print(e);
    };
    process.onExit = (exitCode) {
      stdout.addAll(process.stdout.read());
      process.close();
      var labelMarker = 'CONSOLE MESSAGE: #TEST ';
      var contentMarker = 'Content-Length: ';
      var eol = '\n'.charCodeAt(0);
      var pos = -1;
      var label = null;
      var done = false;

      while(pos < stdout.length) {
        var idx = stdout.indexOf(eol, ++pos);
        if (idx < 0) break;
        StringBuffer sb = new StringBuffer();
        for (var i = pos; i < idx; i++) {
          sb.addCharCode(stdout[i]);
        }
        var line = sb.toString();

        if (label == null && line.startsWith(labelMarker)) {
          label = line.substring(labelMarker.length);
          if (label == 'NONEXISTENT') {
            complete();
          }
        } else if (line.startsWith(contentMarker)) {
          if (label == null) {
            complete();
          }
          var len = int.parse(line.substring(contentMarker.length));
          pos = idx + 1;
          var expectedFileName =
              '$sourceDir${Platform.pathSeparator}'
              '${label.replaceAll("###","_").
                       replaceAll(const RegExp("[^A-Za-z0-9]"),"_")}.png';
          var expected = new File(expectedFileName);
          if (regenerate) {
            var ostream = expected.openOutputStream(FileMode.WRITE);
            ostream.writeFrom(stdout, pos, len);
            ostream.close();
            pass(start, label);
          } else if (!expected.existsSync()) {
            fail(start, label, 'No expectation file');
          } else {
            var bytes = expected.readAsBytesSync();
            if (bytes.length != len) {
              fail(start, label, 'Expectation file has wrong length');
            } else {
              var match = true;
              for (var j = 0; j < len; j++) {
                if (bytes[j] != stdout[pos + j]) {
                  fail(start, label, 'Expectation differs at byte ${j + 1}');
                  match = false;
                  break;
                }
              }
              if (match) pass(start, label);
            }
          }
          done = true;
          break;
        }
        pos = idx;
      }
      if (label != null) {
        if (!done) error(start, label, 'Failed to parse output');
        runPixelLayoutTest(testNum + 1);
      }
    };
  });
}

void init() {
  // Get the name of the directory that has the expectation files
  // (by stripping .dart suffix from test file path).
  // Create it if it does not exist.
  sourceDir = testfile.substring(0, testfile.length - 5);
  if (regenerate) {
    var d = new Directory(sourceDir);
    if (!d.existsSync()) {
      d.createSync();
    }
  }
}

void runPixelLayoutTests() {
  init();
  runPixelLayoutTest(0);
}

void runTextLayoutTests() {
  init();
  runTextLayoutTest(0);
}
