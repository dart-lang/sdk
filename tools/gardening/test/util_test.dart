import 'package:gardening/src/util.dart';

main() {
  testZip();
}

void testZip() {
  print(zip([1, 2, 3], [4, 5, 6], (x, y) => x + y));
}
