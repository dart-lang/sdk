library lib;

import "dart:mirrors";

class C {}

foo() {
  var a = new C();
  print(reflectClass(C).owner);
}
