import 'dart:async';
import 'dart:io';

import 'package:analyzer_cli/src/driver.dart' show Driver, outSink, errorSink;
import 'package:analyzer_cli/src/options.dart' show ExitHandler, exitHandler;
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'utils.dart' show recursiveCopy, testDirectory, withTempDirAsync;

main() {
  defineReflectiveTests(OptionsTest);
}

@reflectiveTest
class OptionsTest {
  _Runner runner;

  void setUp() {
    runner = new _Runner.setUp();
  }

  void tearDown() {
    runner.tearDown();
    runner = null;
  }

  test_options() async {
    // Copy to temp dir so that existing analysis options
    // in the test directory hierarchy do not interfere
    var projDir = path.join(testDirectory, 'data', 'flutter_analysis_options');
    await withTempDirAsync((String tempDirPath) async {
      await recursiveCopy(new Directory(projDir), tempDirPath);
      var expectedPath = path.join(tempDirPath, 'somepkgs', 'flutter', 'lib',
          'analysis_options_user.yaml');
      expect(FileSystemEntity.isFileSync(expectedPath), isTrue);
      await runner.run2([
        "--packages",
        path.join(tempDirPath, 'packagelist'),
        path.join(tempDirPath, 'lib', 'main.dart')
      ]);
      expect(runner.stdout, contains('The parameter \'child\' is required'));
      // Should be a warning as specified in analysis_options_user.yaml
      // not a hint
      expect(runner.stdout, contains('1 warning found'));
    });
  }
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

  String get stderr => _stderr.toString();

  String get stdout => _stdout.toString();

  Future<Null> run2(List<String> args) async {
    await new Driver(isTesting: true).start(args);
    if (stderr.isNotEmpty) {
      fail("Unexpected output to stderr:\n$stderr");
    }
  }

  void tearDown() {
    outSink = _savedOutSink;
    errorSink = _savedErrorSink;
    exitCode = _savedExitCode;
    exitHandler = _savedExitHandler;
  }
}
