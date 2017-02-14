// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

class A {
  operator + (String s) => null;

  operator [] (i) => null;

  operator []= (i, val) {}
}

class B extends A {
  operator + (String s) => super + ("${s}${s}");

  operator [] (i) => super[i];

  operator []= (i, val) => super[i++] += val;
}

class Autobianchi {
  g() => super[0];
}
