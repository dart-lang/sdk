import 'package:expect/expect.dart';

class MyClass {}

@NoInline()
method3() {
  /*4:method3*/ throw new MyClass();
}

method2() => /*3:method2*/ method3();
method4() {
  /*2:method4(inlined)*/ method2();
}

method1() {
  print('hi');
  /*1:method1(inlined)*/ method4();
}

main() => /*0:main*/ method1();
