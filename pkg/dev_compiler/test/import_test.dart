import 'imported_file.dart';

class B extends A {
  int b = 0;
}

test1() {
  B x = new A();
  print(x.a);
  print(x.b);
}

test2() {
  A x = new B();
  print(x.a);
  print(x.b);
}
