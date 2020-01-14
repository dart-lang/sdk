import 'regress20394_lib.dart';

class M {}

class C extends Super with M {
  C() : super._private(42);
  //    ^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER
  // [cfe] Superclass has no constructor named 'Super._private'.
}

main() {
  new C();
}
