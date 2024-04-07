import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

import 'dart:math';

void validate() {
  // Initial program is valid. Symbols in 'dart:math' are visible.
  Expect.equals(0, hotReloadGeneration);
  Expect.equals(e, 2.718281828459045);
  Expect.type<double>(e);
}

Future<void> main() async {
  validate();
  await hotReload();
  validate();
}
