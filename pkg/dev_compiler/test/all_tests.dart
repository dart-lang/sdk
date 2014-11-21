/// Meta-test that runs all tests we have written.
library ddc.test.all_tests;

import 'package:unittest/compact_vm_config.dart';

import 'end_to_end_test.dart' as e2e;

main() {
  useCompactVMConfiguration();
  e2e.main();
}
