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

class C2<T> {}

mixin class M5<T>() implements C2<T>;

mixin class M6<T>() on C2<T>;

mixin class M7<T>();

mixin class M8<T>.named();

// Used for testing the mixins.

class CImpl1 with M1;
class CImpl2 extends C1 with M2;
class CImpl3 with M3;
class CImpl4 with M4;
class CImpl5<T> with M5<T>;
class CImpl6<T> extends C2<T> with M6<T>;
class CImpl7<T> with M7<T>;
class CImpl8<T> with M8<T>;

void main() {
  CImpl1();
  CImpl2();
  CImpl3();
  CImpl4();
  CImpl5<String>();
  CImpl6<String>();
  CImpl7<String>();
  CImpl8<String>();
}
