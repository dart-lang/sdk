library lib;

@MirrorsUsed(targets: "lib.C")
import "dart:mirrors";

class C {}

foo() {
  var a = new C();
  print(reflectClass(C).owner);
}