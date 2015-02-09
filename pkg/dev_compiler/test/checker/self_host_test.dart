/// Tests that run the checker end-to-end using the file system.
library ddc.test.end_to_end;

import 'dart:io';
import 'package:cli_util/cli_util.dart' show getSdkDir;
import 'package:ddc/devc.dart' show compile;
import 'package:ddc/src/report.dart';
import 'package:ddc/src/checker/resolver.dart' show TypeResolver;
import 'package:path/path.dart' as path;
import 'package:unittest/compact_vm_config.dart';
import 'package:unittest/unittest.dart';

main(args) {
  useCompactVMConfiguration();

  var realSdk = new TypeResolver.fromDir(getSdkDir(args).path);
  var testDir = path.absolute(path.dirname(Platform.script.path));

  test('checker can run on itself ', () {
    compile('$testDir/../all_tests.dart', realSdk, reporter: new LogReporter());
  });
}
