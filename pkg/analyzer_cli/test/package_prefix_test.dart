import 'dart:io' show exitCode;

import 'package:analyzer_cli/src/driver.dart' show Driver, outSink, errorSink;
import 'package:analyzer_cli/src/options.dart' show ExitHandler, exitHandler;
import 'package:unittest/unittest.dart';

import 'utils.dart' show testDirectory;

main() {
  group('--x-package-warnings-prefix', () {
    _Runner runner;

    setUp(() {
      runner = new _Runner.setUp();
    });

    tearDown(() {
      runner.tearDown();
      runner = null;
    });

    test('shows only the hint whose package matches the prefix', () {
      runner.run([
        "--packages",
        "$testDirectory/data/package_prefix/packagelist",
        "--x-package-warnings-prefix=f",
        "$testDirectory/data/package_prefix/main.dart"
      ]);
      print("ran it");
      expect(runner.stdout, contains('1 hint found'));
      expect(runner.stdout, contains('Unused import'));
      expect(runner.stdout, contains('package_prefix/pkg/foo/foo.dart'));
      expect(runner.stdout, isNot(contains('bar.dart')));
    });
  });
}

class _Runner {
  final _stdout = new StringBuffer();
  final _stderr = new StringBuffer();

  final StringSink _savedOutSink;
  final StringSink _savedErrorSink;
  final int _savedExitCode;
  final ExitHandler _savedExitHandler;

  _Runner.setUp()
      : _savedOutSink = outSink,
        _savedErrorSink = errorSink,
        _savedExitHandler = exitHandler,
        _savedExitCode = exitCode {
    outSink = _stdout;
    errorSink = _stderr;
    exitHandler = (_) {};
  }

  void run(List<String> args) {
    new Driver().start(args);
    if (stderr.isNotEmpty) {
      fail("Unexpected output to stderr:\n$stderr");
    }
  }

  String get stdout => _stdout.toString();
  String get stderr => _stderr.toString();

  void tearDown() {
    outSink = _savedOutSink;
    errorSink = _savedErrorSink;
    exitCode = _savedExitCode;
    exitHandler = _savedExitHandler;
  }
}
