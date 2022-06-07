// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.17

/*member: main:ignore*/
void main() {
  final x1 = XX();
  x1.foo = 100;
  x1.bar = 200;
  x1.useFoo();
  x1.useBar();
}

class XX {
  late int foo;
  late final int bar;

  @pragma('dart2js:noInline')
  /*member: XX.useFoo:function() {
  var t2, t3, t4, t5, _this = this,
    t1 = _this.__XX_foo_A;
  if (t1 === $)
    A.throwLateFieldNI("foo");
  t2 = _this.effect$0();
  t3 = _this.__XX_foo_A;
  t4 = _this.effect$0();
  t5 = _this.__XX_foo_A;
  _this.use$8(t1, t1, t2, t3, t3, t4, t5, t5);
}*/
  void useFoo() {
    // There is only one check on `foo` since the first check dominates all the
    // others.  `foo` is not final, so the field needs to be reloaded after
    // `effects()`.
    use(foo, foo, effect(), foo, foo, effect(), foo, foo);
  }

  @pragma('dart2js:noInline')
  /*member: XX.useBar:function() {
  var _this = this,
    t1 = _this.__XX_bar_F;
  if (t1 === $)
    A.throwLateFieldNI("bar");
  _this.use$8(t1, t1, _this.effect$0(), t1, t1, _this.effect$0(), t1, t1);
}*/
  void useBar() {
    // There is only one check on `bar` since the first check dominates all the
    // others.  Since `bar` is final, the checked value is reused.
    use(bar, bar, effect(), bar, bar, effect(), bar, bar);
  }

  @pragma('dart2js:noInline')
  /*member: XX.use:ignore*/
  void use(int a1, int a2, int a3, int a4, int a5, int a6, int a7, int a8) {
    print([a1, a2, a3, a4, a5, a6, a7, a8]);
  }

  @pragma('dart2js:noInline')
  /*member: XX.effect:ignore*/
  int effect() {
    foo++;
    return 0;
  }
}
