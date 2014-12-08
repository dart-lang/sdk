/// Meta-test that runs all tests we have written.
library ddc.test.all_tests;

import 'package:unittest/compact_vm_config.dart';

import 'end_to_end_test.dart' as e2e;
import 'inferred_type_test.dart' as inferred_type_test;
import 'dart_runtime_test.dart' as runtime_test;

main() {
  useCompactVMConfiguration();
  e2e.main();
  inferred_type_test.main();
  runtime_test.main();
}
