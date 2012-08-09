#library("lib_b");

#import("4434_lib.dart");

class B extends A { }

main() {
  B b = new B();
  b.x(b);
}
