// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library testrunner_test;

import 'dart:async';
import 'dart:io';
import 'package:unittest/unittest.dart';

var dart;
var debug = false;

Future runTestrunner(
    command, List<String> args, List<String> stdout, List<String> stderr) {
  if (debug) {
    print("Running $command ${args.join(' ')}");
  }
  return Process.run(command, args).then((ProcessResult result) {
    var lineEndings = new RegExp("\r\n|\n");
    stdout.addAll(result.stdout.trim().split(lineEndings));
    stderr.addAll(result.stderr.trim().split(lineEndings));
  }).catchError((e) {
    stderr.add("Error starting process:");
    stderr.add("  Command: $command");
    stderr.add("  Error: ${e}");
    completer.complete(-1);
  });
}

// Useful utility for debugging test failures.
void dump(label, list) {
  if (!debug) return;
  print('\n@=[ $label ]=============================\n');
  for (var i = 0; i < list.length; i++) {
    print('@ ${list[i]}\n');
  }
  print('------------------------------------------\n');
}

int stringCompare(String s1, String s2) => s1.compareTo(s2);

Future runTest(List<String> args, List<String> expected_stdout,
    {List<String> expected_stderr, sort: false}) {
  var stdout = new List<String>();
  var stderr = new List<String>();
  for (var i = 0; i < expected_stdout.length; i++) {
    expected_stdout[i] =
        expected_stdout[i].replaceAll('/', Platform.pathSeparator);
  }
  if (debug) {
    args.insert(1, "--log=stderr");
  }
  var rtn = runTestrunner(dart, args, stdout, stderr);
  rtn.then((_) {
    dump('stderr', stderr);
    dump('stdout', stdout);

    if (expected_stderr != null) {
      expect(stderr.length, orderedEquals(expected_stderr));
    }
    var i, l = 0, matched = 0;
    if (sort) {
      stdout.sort(stringCompare);
      expected_stdout.sort(stringCompare);
    }
    for (i = 0; i < stdout.length; i++) {
      if (!stdout[i].startsWith('@')) {
        if (expected_stdout.length <= l) {
          fail("Extra text in output: ${stdout[i]}");
          return;
        }
        var actual = stdout[i].trim();
        if (debug) {
          print("Compare <$actual> and <${expected_stdout[l]}>");
        }
        if (expected_stdout[l].startsWith('*')) {
          expect(actual, endsWith(expected_stdout[l].substring(1)));
        } else if (expected_stdout[l].startsWith('?')) {
          var pat = expected_stdout[l].substring(1);
          if (Platform.operatingSystem == 'windows') {
            // The joys of Windows...
            pat = pat.replaceAll('\\', '\\\\');
          }
          expect(actual, matches(pat));
        } else {
          expect(actual, expected_stdout[l]);
        }
        ++l;
      }
    }
    if (l < expected_stdout.length) {
      fail("Only matched $l of ${expected_stdout.length} lines");
    }
  });
  return rtn;
}

// A useful function to quickly disable a group of tests; just
// replace group() with skip_group().
skip_group(_1, _2) {}

main() {
  dart = Platform.executable;
  var idx = dart.indexOf('dart-sdk');
  if (idx < 0) {
    print("Please run using the dart executable from the Dart SDK");
    exit(-1);
  }
  var _ = Platform.pathSeparator;
  var testrunner = '../../testrunner/testrunner.dart'
      .replaceAll('/', Platform.pathSeparator);

  group("list tests", () {
    test('list file', () {
      return runTest([testrunner, '--list-files', 'non_browser_tests'],
          ['?.*/non_browser_tests/non_browser_test.dart']);
    });
    test('list files', () {
      return runTest([
        testrunner,
        '--recurse',
        '--sort',
        '--list-files',
        '--test-file-pattern=.dart\$'
      ], [
        '*browser_tests/web/browser_test.dart',
        '*http_client_tests/http_client_test.dart',
        '*layout_tests/web/layout_test.dart',
        '*non_browser_tests/non_browser_test.dart',
        '*non_browser_tests/non_browser_toast.dart',
        '*/testrunner_test.dart'
      ]);
    });
    test('list files', () {
      return runTest([
        testrunner,
        '--list-files',
        '--test-file-pattern=.dart\$',
        'non_browser_tests'
      ], [
        '*non_browser_tests/non_browser_test.dart',
        '*non_browser_tests/non_browser_toast.dart'
      ], sort: true);
    });
    test('list groups', () {
      return runTest([
        testrunner,
        '--list-groups',
        'non_browser_tests'
      ], [
        '*non_browser_tests/non_browser_test.dart group1',
        '*non_browser_tests/non_browser_test.dart group2'
      ]);
    });
    test('list tests', () {
      return runTest([
        testrunner,
        '--list-tests',
        'non_browser_tests'
      ], [
        '*non_browser_tests/non_browser_test.dart group1 test1',
        '*non_browser_tests/non_browser_test.dart group2 test2'
      ]);
    });
  });

  group("vm", () {
    test("vm without timing info", () {
      return runTest([
        testrunner,
        '--recurse',
        'non_browser_tests'
      ], [
        '?FAIL .*/non_browser_tests/non_browser_test.dart group1 test1'
            ' Expected: false',
        '?PASS .*/non_browser_tests/non_browser_test.dart group2 test2'
      ]);
    });

    test("vm with timing info", () {
      return runTest([
        testrunner,
        '--recurse',
        '--time',
        'non_browser_tests'
      ], [
        '?FAIL [0-9.]+s .*/non_browser_tests/non_browser_test.dart group1'
            ' test1 Expected: false',
        '?PASS [0-9.]+s .*/non_browser_tests/non_browser_test.dart group2'
            ' test2'
      ]);
    });
  });

  group("selection", () {
    test("--include", () {
      return runTest([
        testrunner,
        '--recurse',
        '--include=group1',
        'non_browser_tests'
      ], [
        '?FAIL .*/non_browser_tests/non_browser_test.dart group1 test1 '
            'Expected: false'
      ]);
    });

    test("--exclude", () {
      return runTest(
          [testrunner, '--recurse', '--exclude=group1', 'non_browser_tests'],
          ['?PASS .*/non_browser_tests/non_browser_test.dart group2 test2']);
    });

    test("test file pattern", () {
      return runTest([
        testrunner,
        '--recurse',
        '--test-file-pattern=toast',
        'non_browser_tests'
      ], [
        '?PASS .*/non_browser_tests/non_browser_toast.dart foo bar'
      ]);
    });
  });

  group("stop on failure tests", () {
    test("without stop", () {
      return runTest([
        testrunner,
        '--recurse',
        '--sort',
        '--tasks=1',
        '--test-file-pattern=.dart\$',
        'non_browser_tests'
      ], [
        '?FAIL .*/non_browser_tests/non_browser_test.dart group1 test1 '
            'Expected: false',
        '?PASS .*/non_browser_tests/non_browser_test.dart group2 test2',
        '?PASS .*/non_browser_tests/non_browser_toast.dart foo bar'
      ]);
    });
    test("with stop", () {
      return runTest([
        testrunner,
        '--recurse',
        '--sort',
        '--tasks=1',
        '--test-file-pattern=.dart\$',
        '--stop-on-failure',
        'non_browser_tests'
      ], [
        '?FAIL .*/non_browser_tests/non_browser_test.dart group1 test1 '
            'Expected: false',
        '?PASS .*/non_browser_tests/non_browser_test.dart group2 test2'
      ]);
    });
  });

  group("output control", () {
    test("summary test", () {
      return runTest([
        testrunner,
        '--recurse',
        '--summary',
        'non_browser_tests'
      ], [
        '?FAIL .*/non_browser_tests/non_browser_test.dart group1 test1 '
            'Expected: false',
        '?PASS .*/non_browser_tests/non_browser_test.dart group2 test2',
        '',
        '?.*/non_browser_tests/non_browser_test.dart: '
            '1 PASSED, 1 FAILED, 0 ERRORS'
      ]);
    });

    test('list tests with custom format', () {
      return runTest([
        testrunner,
        '--list-tests',
        '--list-format="<FILENAME><TESTNAME>"',
        'non_browser_tests'
      ], [
        '?.*/non_browser_tests/non_browser_test.dart test1',
        '?.*/non_browser_tests/non_browser_test.dart test2'
      ]);
    });

    test("custom message formatting", () {
      return runTest([
        testrunner,
        '--recurse',
        '--pass-format=YIPPEE! <GROUPNAME><TESTNAME>',
        '--fail-format=EPIC FAIL! <GROUPNAME><TESTNAME>',
        'non_browser_tests'
      ], [
        'EPIC FAIL! group1 test1',
        'YIPPEE! group2 test2'
      ]);
    });
  });

  test("checked mode test", () {
    return runTest([
      testrunner,
      '--recurse',
      '--checked',
      'non_browser_tests'
    ], [
      '?FAIL .*/non_browser_tests/non_browser_test.dart group1 test1 '
          'Expected: false',
      "?FAIL .*/non_browser_tests/non_browser_test.dart group2 test2 "
          "Caught type 'int' is not a subtype of type 'bool' of 'x'."
    ]);
  });

  group("browser", () {
    test("native test", () {
      return runTest([
        testrunner,
        '--recurse',
        '--runtime=drt-dart',
        'browser_tests'
      ], [
        '?FAIL .*/browser_tests/web/browser_test.dart group1 test1 '
            'Expected: false',
        '?PASS .*/browser_tests/web/browser_test.dart group2 test2'
      ]);
    });

    test("compiled test", () {
      return runTest([
        testrunner,
        '--recurse',
        '--runtime=drt-js',
        'browser_tests'
      ], [
        '?FAIL .*/browser_tests/web/browser_test.dart group1 test1 '
            'Expected: false',
        '?PASS .*/browser_tests/web/browser_test.dart group2 test2'
      ]);
    });
  });

  group("textual layout tests", () {
    group("drt-dart", () {
      test("no baseline", () {
        var f = new File("layout_tests/web/layout_test/layout.txt");
        if (f.existsSync()) {
          f.deleteSync();
        }
        return runTest([
          testrunner,
          '--runtime=drt-dart',
          '--recurse',
          '--layout-text',
          'layout_tests'
        ], [
          '?FAIL .*/layout_tests/web/layout_test.dart layout '
              'No expectation file'
        ]);
      });
      test("create baseline", () {
        return runTest([
          testrunner,
          '--runtime=drt-dart',
          '--recurse',
          '--layout-text',
          '--regenerate',
          'layout_tests'
        ], [
          '?PASS .*/layout_tests/web/layout_test.dart layout'
        ]);
      });
      test("test baseline", () {
        return runTest([
          testrunner,
          '--runtime=drt-dart',
          '--recurse',
          '--layout-text',
          'layout_tests'
        ], [
          '?PASS .*/layout_tests/web/layout_test.dart layout'
        ]);
      });
    });
    group("drt-js", () {
      test("no baseline", () {
        var f = new File("layout_tests/web/layout_test/layout.txt");
        if (f.existsSync()) {
          f.deleteSync();
        }
        return runTest([
          testrunner,
          '--runtime=drt-js',
          '--recurse',
          '--layout-text',
          'layout_tests'
        ], [
          '?FAIL .*/layout_tests/web/layout_test.dart layout '
              'No expectation file'
        ]);
      });
      test("create baseline", () {
        return runTest([
          testrunner,
          '--runtime=drt-js',
          '--recurse',
          '--layout-text',
          '--regenerate',
          'layout_tests'
        ], [
          '?PASS .*/layout_tests/web/layout_test.dart layout'
        ]);
      });
      test("test baseline", () {
        return runTest([
          testrunner,
          '--runtime=drt-js',
          '--recurse',
          '--layout-text',
          'layout_tests'
        ], [
          '?PASS .*/layout_tests/web/layout_test.dart layout'
        ]);
      });
    });
  });

  group("pixel layout tests", () {
    group("drt-dart", () {
      test("no baseline", () {
        var f = new File("layout_tests/web/layout_test/layout.png");
        if (f.existsSync()) {
          f.deleteSync();
        }
        return runTest([
          testrunner,
          '--runtime=drt-dart',
          '--recurse',
          '--layout-pixel',
          'layout_tests'
        ], [
          '?FAIL .*/layout_tests/web/layout_test.dart layout '
              'No expectation file'
        ]);
      });
      test("create baseline", () {
        return runTest([
          testrunner,
          '--runtime=drt-dart',
          '--recurse',
          '--layout-pixel',
          '--regenerate',
          'layout_tests'
        ], [
          '?PASS .*/layout_tests/web/layout_test.dart layout'
        ]);
      });
      test("test baseline", () {
        return runTest([
          testrunner,
          '--runtime=drt-dart',
          '--recurse',
          '--layout-pixel',
          'layout_tests'
        ], [
          '?PASS .*/layout_tests/web/layout_test.dart layout'
        ]);
      });
      // TODO(gram): Should add a test that changes a byte of the
      // expectation .png.
    });
    group("drt-js", () {
      test("no baseline", () {
        var f = new File("layout_tests/web/layout_test/layout.png");
        if (f.existsSync()) {
          f.deleteSync();
        }
        return runTest([
          testrunner,
          '--runtime=drt-js',
          '--recurse',
          '--layout-pixel',
          'layout_tests'
        ], [
          '?FAIL .*/layout_tests/web/layout_test.dart layout '
              'No expectation file'
        ]);
      });
      test("create baseline", () {
        return runTest([
          testrunner,
          '--runtime=drt-js',
          '--recurse',
          '--layout-pixel',
          '--regenerate',
          'layout_tests'
        ], [
          '?PASS .*/layout_tests/web/layout_test.dart layout'
        ]);
      });
      test("test baseline", () {
        return runTest([
          testrunner,
          '--runtime=drt-js',
          '--recurse',
          '--layout-pixel',
          'layout_tests'
        ], [
          '?PASS .*/layout_tests/web/layout_test.dart layout'
        ]);
      });
    });
  });

  group("run in isolate", () {
    test("vm", () {
      return runTest([
        testrunner,
        '--runtime=vm',
        '--recurse',
        '--isolate',
        'non_browser_tests'
      ], [
        '?FAIL .*/non_browser_tests/non_browser_test.dart group1 test1'
            ' Expected: false',
        '?PASS .*/non_browser_tests/non_browser_test.dart group2 test2'
      ]);
    });
    test("drt-dart", () {
      return runTest([
        testrunner,
        '--runtime=drt-dart',
        '--recurse',
        '--isolate',
        'non_browser_tests'
      ], [
        '?FAIL .*/non_browser_tests/non_browser_test.dart group1 test1'
            ' Expected: false',
        '?PASS .*/non_browser_tests/non_browser_test.dart group2 test2'
      ]);
    });
    test("drt-js", () {
      return runTest([
        testrunner,
        '--runtime=drt-js',
        '--recurse',
        '--isolate',
        'non_browser_tests'
      ], [
        '?FAIL .*/non_browser_tests/non_browser_test.dart group1 test1 '
            'Expected: false',
        '?PASS .*/non_browser_tests/non_browser_test.dart group2 test2'
      ]);
    });
  });

  group("embedded server", () {
    test("get test", () {
      return runTest([
        testrunner,
        '--recurse',
        '--server',
        '--port=3456',
        '--root=${Directory.current.path}',
        'http_client_tests'
      ], [
        '?PASS .*/http_client_tests/http_client_test.dart  test1',
        '?PASS .*/http_client_tests/http_client_test.dart  test2'
      ]);
    });
  });
}
