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

  test('checker can run on itself ', () {
    // TODO(sigmund,vsm): this test breaks an assertion in the checker, need to
    // investigate.
    expect(() => checkProgram(_uri('all_tests'), sdkDir: dartSdkDirectory),
        throwsA(predicate((e) => '$e'.contains('_newType != baseType'))));
  });
}

_uri(testfile) => new Uri.file(path.absolute('test/$testfile.dart'));
