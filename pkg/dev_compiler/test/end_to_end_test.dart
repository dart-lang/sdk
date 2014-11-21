/// Tests that run the checker end-to-end using the file system.
library ddc.test.end_to_end;

import 'package:unittest/unittest.dart';

import 'package:path/path.dart' as path;
import 'package:ddc/typechecker.dart';
import 'package:ddc/src/dart_sdk.dart' show mockSdkSources;

main() {
  test('checker runs correctly (end-to-end)', () {
    checkProgram(new Uri.file(path.absolute('test/inferred_type.dart')),
          mockSdkSources: mockSdkSources);
  });
}
