// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Body and header constructor syntax for mixin classes.

// SharedOptions=--enable-experiment=declaring-constructors

import "package:expect/expect.dart";

class C1 {}

mixin class M1() implements C1;

mixin class M2();

mixin class M3.named();

class C2<T> {}

mixin class M4<T>() implements C2<T>;

mixin class M5<T>();

mixin class M6<T>.named();

// Used for testing the mixins.

class CImpl1 with M1;
class CImpl2 with M2;
class CImpl3 with M3;
class CImpl4<T> with M4<T>;
class CImpl5<T> with M5<T>;
class CImpl6<T> with M6<T>;

void main() {
  CImpl1();
  CImpl2();
  CImpl3();
  CImpl4<String>();
  CImpl5<String>();
  CImpl6<String>();
}
