/// Tests that run the checker end-to-end using the file system.
library ddc.test.end_to_end;

import 'package:unittest/unittest.dart';

import 'package:path/path.dart' as path;
import 'package:ddc/typechecker.dart';
import 'package:ddc/src/dart_sdk.dart' show mockSdkSources, dartSdkDirectory;

main() {
  test('checker runs correctly (end-to-end)', () {
    checkProgram(_uri('inferred_type'), mockSdkSources: mockSdkSources);
  });

  test('checker accepts files with imports', () {
    checkProgram(_uri('import_test'), mockSdkSources: mockSdkSources);
  });

  test('checker tests function types', () {
    // TODO(vsm): Check for correct down casts.
    checkProgram(_uri('function_type_test'), mockSdkSources: mockSdkSources);
  });

  test('checker tests runtime checks', () {
    // TODO(sigmund,vsm): Check output for invalid checks.
    checkProgram(_uri('runtimetypechecktest'), mockSdkSources: mockSdkSources);
  });

  test('checker tests return values', () {
    // TODO(vsm): Check for conversions.
    checkProgram(_uri('return_test'), mockSdkSources: mockSdkSources);
  });

  test('checker can run on itself ', () {
    checkProgram(_uri('all_tests'), sdkDir: dartSdkDirectory);
  });
}

_uri(testfile) => new Uri.file(path.absolute('test/$testfile.dart'));
