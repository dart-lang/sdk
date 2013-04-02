// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library scheduled_process_test;

import 'dart:async';
import 'dart:io';

import 'package:pathos/path.dart' as path;
import 'package:scheduled_test/scheduled_process.dart';
import 'package:scheduled_test/scheduled_test.dart';
import 'package:scheduled_test/src/mock_clock.dart' as mock_clock;

import 'metatest.dart';
import 'utils.dart';

void main() {
  setUpTimeout();

  expectTestsPass("a process must have kill() or shouldExit() called", () {
    var errors;
    test('test 1', () {
      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });

      startDartProcess('print("hello!");');
    });

    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.length, equals(1));
      expect(errors.first.error, isStateError);
      expect(errors.first.error.message, matches(r"^Scheduled process "
          r"'[^']+[\\/]dart(\.exe)?' must have shouldExit\(\) or kill\(\) "
          r"called before the test is run\.$"));
    });
  }, passing: ['test 2']);

  expectTestsPass("a process exits with the expected exit code", () {
    test('exit code 0', () {
      var process = startDartProcess('exitCode = 0;');
      process.shouldExit(0);
    });

    test('exit code 42', () {
      var process = startDartProcess('exitCode = 42;');
      process.shouldExit(42);
    });
  });

  expectTestsPass("a process exiting with an unexpected exit code should cause "
      "an error", () {
    var errors;
    test('test 1', () {
      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });

      var process = startDartProcess('exitCode = 1;');
      process.shouldExit(0);
    });

    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.length, equals(1));
      expect(errors.first.error, new isInstanceOf<TestFailure>());
    });
  }, passing: ['test 2']);

  expectTestsPass("a killed process doesn't care about its exit code", () {
    test('exit code 0', () {
      var process = startDartProcess('exitCode = 0;');
      process.kill();
    });

    test('exit code 1', () {
      var process = startDartProcess('exitCode = 1;');
      process.kill();
    });
  });

  expectTestsPass("a killed process stops running", () {
    test('test', () {
      var process = startDartProcess('while (true);');
      process.kill();
    });
  });

  expectTestsPass("kill can't be called twice", () {
    test('test', () {
      var process = startDartProcess('');
      process.kill();
      expect(process.kill, throwsA(isStateError));
    });
  });

  expectTestsPass("kill can't be called after shouldExit", () {
    test('test', () {
      var process = startDartProcess('');
      process.shouldExit(0);
      expect(process.kill, throwsA(isStateError));
    });
  });

  expectTestsPass("shouldExit can't be called twice", () {
    test('test', () {
      var process = startDartProcess('');
      process.shouldExit(0);
      expect(() => process.shouldExit(0), throwsA(isStateError));
    });
  });

  expectTestsPass("shouldExit can't be called after kill", () {
    test('test', () {
      var process = startDartProcess('');
      process.kill();
      expect(() => process.shouldExit(0), throwsA(isStateError));
    });
  });

  expectTestsPass("a process that ends while waiting for stdout shouldn't "
      "block the test", () {
    var errors;
    test('test 1', () {
      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });
  
      var process = startDartProcess('');
      expect(process.nextLine(), completion(equals('hello')));
      expect(process.nextLine(), completion(equals('world')));
      process.shouldExit(0);
    });
  
    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.length, anyOf(1, 2));
      expect(errors[0].error, isStateError);
      expect(errors[0].error.message, equals("No elements"));

      // Whether or not this error appears depends on how quickly the "no
      // elements" error is handled.
      if (errors.length == 2) {
        expect(errors[1].error, matches(r"^Process "
            r"'[^']+[\\/]dart(\.exe)? [^']+' ended earlier than scheduled with "
            r"exit code 0\."));
      }
    });
  }, passing: ['test 2']);

  expectTestsPass("a process that ends during the task immediately before it's "
      "scheduled to end shouldn't cause an error", () {
    test('test', () {
      var process = startDartProcess('stdin.toList();');
      process.closeStdin();
      // Unfortunately, sleeping for a second seems like the best way of
      // guaranteeing that the process ends during this task.
      schedule(() => new Future.delayed(new Duration(seconds: 1)));
      process.shouldExit(0);
    });
  });

  expectTestsPass("nextLine returns the next line of stdout from the process",
      () {
    test('test', () {
      var process = startDartProcess(r'print("hello\n\nworld"); print("hi");');
      expect(process.nextLine(), completion(equals('hello')));
      expect(process.nextLine(), completion(equals('')));
      expect(process.nextLine(), completion(equals('world')));
      expect(process.nextLine(), completion(equals('hi')));
      process.shouldExit(0);
    });
  });

  expectTestsPass("nextLine throws an error if there's no more stdout", () {
    var errors;
    test('test 1', () {
      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });
  
      var process = startDartProcess('print("hello");');
      expect(process.nextLine(), completion(equals('hello')));
      expect(process.nextLine(), completion(equals('world')));
      process.shouldExit(0);
    });
  
    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.length, anyOf(1, 2));
      expect(errors[0].error, isStateError);
      expect(errors[0].error.message, equals("No elements"));

      // Whether or not this error appears depends on how quickly the "no
      // elements" error is handled.
      if (errors.length == 2) {
        expect(errors[1].error, matches(r"^Process "
            r"'[^']+[\\/]dart(\.exe)? [^']+' ended earlier than scheduled with "
            r"exit code 0\."));
      }
    });
  }, passing: ['test 2']);

  expectTestsPass("nextErrLine returns the next line of stderr from the "
      "process", () {
    test('test', () {
      var process = startDartProcess(r'''
          stderr.write("hello\n\nworld\n");
          stderr.write("hi");
          ''');
      expect(process.nextErrLine(), completion(equals('hello')));
      expect(process.nextErrLine(), completion(equals('')));
      expect(process.nextErrLine(), completion(equals('world')));
      expect(process.nextErrLine(), completion(equals('hi')));
      process.shouldExit(0);
    });
  });

  expectTestsPass("nextErrLine throws an error if there's no more stderr", () {
    var errors;
    test('test 1', () {
      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });
  
      var process = startDartProcess(r'stderr.write("hello\n");');
      expect(process.nextErrLine(), completion(equals('hello')));
      expect(process.nextErrLine(), completion(equals('world')));
      process.shouldExit(0);
    });
  
    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.length, anyOf(1, 2));
      expect(errors[0].error, isStateError);
      expect(errors[0].error.message, equals("No elements"));

      // Whether or not this error appears depends on how quickly the "no
      // elements" error is handled.
      if (errors.length == 2) {
        expect(errors[1].error, matches(r"^Process "
            r"'[^']+[\\/]dart(\.exe)? [^']+' ended earlier than scheduled with "
            r"exit code 0\."));
      }
    });
  }, passing: ['test 2']);

  expectTestsPass("remainingStdout returns all the stdout if it's not consumed "
      "any other way", () {
    test('test', () {
      var process = startDartProcess(r'print("hello\n\nworld"); print("hi");');
      process.shouldExit(0);
      expect(process.remainingStdout(),
          completion(equals("hello\n\nworld\nhi")));
    });
  });

  expectTestsPass("remainingStdout returns the empty string if there's no "
      "stdout", () {
    test('test', () {
      var process = startDartProcess(r'');
      process.shouldExit(0);
      expect(process.remainingStdout(), completion(isEmpty));
    });
  });

  expectTestsPass("remainingStdout returns the remaining stdout after the "
      "lines consumed by nextLine", () {
    test('test', () {
      var process = startDartProcess(r'print("hello\n\nworld"); print("hi");');
      expect(process.nextLine(), completion(equals("hello")));
      expect(process.nextLine(), completion(equals("")));
      process.shouldExit(0);
      expect(process.remainingStdout(), completion(equals("world\nhi")));
    });
  });

  expectTestsPass("remainingStdout can't be called before the process is "
      "scheduled to end", () {
    test('test', () {
      var process = startDartProcess(r'');
      expect(process.remainingStdout, throwsA(isStateError));
      process.shouldExit(0);
    });
  });

  expectTestsPass("remainingStderr returns all the stderr if it's not consumed "
      "any other way", () {
    test('test', () {
      var process = startDartProcess(r'''
          stderr.write("hello\n\nworld\n");
          stderr.write("hi\n");
          ''');
      process.shouldExit(0);
      expect(process.remainingStderr(),
          completion(equals("hello\n\nworld\nhi")));
    });
  });

  expectTestsPass("remainingStderr returns the empty string if there's no "
      "stderr", () {
    test('test', () {
      var process = startDartProcess(r'');
      process.shouldExit(0);
      expect(process.remainingStderr(), completion(isEmpty));
    });
  });

  expectTestsPass("remainingStderr returns the remaining stderr after the "
      "lines consumed by nextLine", () {
    test('test', () {
      var process = startDartProcess(r'''
          stderr.write("hello\n\nworld\n");
          stderr.write("hi\n");
          ''');
      expect(process.nextErrLine(), completion(equals("hello")));
      expect(process.nextErrLine(), completion(equals("")));
      process.shouldExit(0);
      expect(process.remainingStderr(), completion(equals("world\nhi")));
    });
  });

  expectTestsPass("remainingStderr can't be called before the process is "
      "scheduled to end", () {
    test('test', () {
      var process = startDartProcess(r'');
      expect(process.remainingStderr, throwsA(isStateError));
      process.shouldExit(0);
    });
  });

  expectTestsPass("writeLine schedules a line to be written to the process",
      () {
    test('test', () {
      var process = startDartProcess(r'''
          stdinLines.listen((line) => print("> $line"));
          ''');
      process.writeLine("hello");
      expect(process.nextLine(), completion(equals("> hello")));
      process.writeLine("world");
      expect(process.nextLine(), completion(equals("> world")));
      process.kill();
    });
  });

  expectTestsPass("closeStdin closes the process's stdin stream", () {
    test('test', () {
      var process = startDartProcess(r'''
          stdin.listen((line) => print("> $line"),
              onDone: () => print("stdin closed"));
          ''');
      process.closeStdin();
      process.shouldExit(0);
      expect(process.nextLine(), completion(equals('stdin closed')));
    });
  });
}

ScheduledProcess startDartProcess(String script) {
  var tempDir = schedule(() {
    return new Directory('').createTemp().then((dir) => dir.path);
  }, 'create temp dir');

  var dartPath = schedule(() {
    return tempDir.then((dir) {
      var utilsPath = path.absolute(path.join(
          new Options().script, 'utils.dart'));
      return new File(path.join(dir, 'test.dart')).writeAsString('''
          import 'dart:async';
          import 'dart:io';

          var stdinLines = stdin
              .transform(new StringDecoder())
              .transform(new LineTransformer());

          void main() {
            $script
          }
          ''').then((file) => file.path);
    });
  }, 'write script file');

  currentSchedule.onComplete.schedule(() {
    return tempDir.catchError((_) => null).then((dir) {
      if (dir == null) return;
      return new Directory(dir).delete(recursive: true);
    });
  }, 'clean up temp dir');

  return new ScheduledProcess.start(dartExecutable, ['--checked', dartPath]);
}
