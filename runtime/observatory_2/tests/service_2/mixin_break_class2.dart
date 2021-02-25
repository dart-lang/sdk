library mixin_step_class2;

import 'mixin_break_mixin_class.dart';

class Hello2 extends Object with HelloMixin {
  void speak() {
    sayHello();
    print(" - Hello2");
  }
}
