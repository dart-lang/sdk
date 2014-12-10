/// Tests that run the checker end-to-end using the file system.
library ddc.test.end_to_end;

import 'dart:io';
import 'package:ddc/typechecker.dart';
import 'package:ddc/src/dart_sdk.dart' show mockSdkSources;
import 'package:ddc/src/resolver.dart' show TypeResolver;
import 'package:path/path.dart' as path;
import 'package:unittest/unittest.dart';

main() {
  var mockSdk =
      new TypeResolver(TypeResolver.sdkResolverFromMock(mockSdkSources));

  var testDir = path.absolute(path.dirname(Platform.script.path));

  _uri(testfile) => new Uri.file('$testDir/$testfile.dart');

  test('checker runs correctly (end-to-end)', () {
    checkProgram(_uri('funwithtypes'), mockSdk);
  });

  test('checker accepts files with imports', () {
    checkProgram(_uri('import_test'), mockSdk);
  });

  test('checker tests function types', () {
    // TODO(vsm): Check for correct down casts.
    checkProgram(_uri('function_type_test'), mockSdk);
  });

  test('checker tests runtime checks', () {
    // TODO(sigmund,vsm): Check output for invalid checks.
    checkProgram(_uri('runtimetypechecktest'), mockSdk);
  });

  test('checker tests return values', () {
    // TODO(vsm): Check for conversions.
    checkProgram(_uri('return_test'), mockSdk);
  });
}
