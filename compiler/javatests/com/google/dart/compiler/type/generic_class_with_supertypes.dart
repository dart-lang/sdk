// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Interface<I1, I2> {
  I1 interfaceField;
  I1 interfaceMethod(I2 arg);
}

class Superclass<S1, S2> {
  S1 superField;
  S1 superMethod(S2 arg) { return null; }
}

class GenericClassWithSupertypes<T1, T2> extends Superclass<T2, T1> implements Interface<T1, T1> {
  T1 localField;
  T1 localMethod(T2 arg) { return null; }
  T2 t2;
  T1 t1;
}
