library mixin_step_class1;

import 'mixin_break_mixin_class.dart';

class Hello1 extends Object with HelloMixin {
  void speak() {
    sayHello();
    print(" - Hello1");
  }
}
