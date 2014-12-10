/// Meta-test that runs all tests we have written.
library ddc.test.all_tests;

import 'package:unittest/compact_vm_config.dart';
import 'package:unittest/unittest.dart';

import 'codegen_test.dart' as codegen_test;
import 'dart_runtime_test.dart' as runtime_test;
import 'end_to_end_test.dart' as e2e;
import 'inferred_type_test.dart' as inferred_type_test;

main(args) {
  useCompactVMConfiguration();
  group('end-to-end', e2e.main);
  group('inferred types', inferred_type_test.main);
  group('runtime', runtime_test.main);
  group('codegen', () {
    codegen_test.main(args);
  });
}
