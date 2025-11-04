// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Body and header constructor syntax for mixin classes.

// SharedOptions=--enable-experiment=declaring-constructors

import "package:expect/expect.dart";

class C1 {}

mixin class M1() implements C1;

mixin class M2() on C1;

mixin class M3();

mixin class M4.named();

mixin class M5 {
  this();
}

mixin class M6 {
  this.named();
}

class C2<T> {}

mixin class M7<T>() implements C2<T>;

mixin class M8<T>() on C2<T>;

mixin class M9<T>();

mixin class M10<T>.named();

mixin class M11<T> {
  this();
}

mixin class M12<T> {
  this.named();
}

// Used for testing the mixins.

class CImpl1 with M1;
class CImpl2 extends C1 with M2;
class CImpl3 with M3;
class CImpl4 with M4;
class CImpl5 with M5;
class CImpl6 with M6;
class CImpl7<T> with M7<T>;
class CImpl8<T> extends C2<T> with M8<T>;
class CImpl9<T> with M9<T>;
class CImpl10<T> with M10<T>;
class CImpl11<T> with M11<T>;
class CImpl12<T> with M12<T>;

void main() {
  CImpl1();
  CImpl2();
  CImpl3();
  CImpl4();
  CImpl5();
  CImpl6();
  CImpl7<String>();
  CImpl8<String>();
  CImpl9<String>();
  CImpl10<String>();
  CImpl11<String>();
  CImpl12<String>();
}
