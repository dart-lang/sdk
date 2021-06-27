
// @dart = 2.9
library CyclicImportTest;

import 'sub/sub.dart';

var value = 42;

main() {
  subMain();
}
