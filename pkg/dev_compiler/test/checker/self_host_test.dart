/// Tests that run the checker end-to-end using the file system.
library ddc.test.end_to_end;

import 'dart:io';
import 'package:ddc/src/checker/checker.dart';
import 'package:ddc/src/report.dart';
import 'package:ddc/src/checker/dart_sdk.dart' show dartSdkDirectory;
import 'package:ddc/src/checker/resolver.dart' show TypeResolver;
import 'package:path/path.dart' as path;
import 'package:unittest/compact_vm_config.dart';
import 'package:unittest/unittest.dart';

main() {
  useCompactVMConfiguration();
  var realSdk =
      new TypeResolver(TypeResolver.sdkResolverFromDir(dartSdkDirectory));

  var testDir = path.absolute(path.dirname(Platform.script.path));

  _uri(testfile) => new Uri.file('$testDir/$testfile.dart');

  test('checker can run on itself ', () {
    checkProgram(_uri('../all_tests'), realSdk, new LogReporter());
  });
}
