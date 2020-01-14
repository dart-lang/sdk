import 'dart:collection';
import 'package:expect/expect.dart';

class MyList extends ListBase {
  int get length => 4;
  set length(int x) {}
  int operator [](int x) => 42;
  void operator []=(int x, val) {}
}

main() {
  var x = new MyList();
  int z = 0;
  x.forEach((y) {
    z += y;
  });
  Expect.equals(z, 4 * 42);
}
