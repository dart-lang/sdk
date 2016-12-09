import 'regress_20394_lib.dart';

class M {}

class C extends Super with M {
  C() : super._private(42);   /// 01: compile-time error
}

main() {
  new C();
}
