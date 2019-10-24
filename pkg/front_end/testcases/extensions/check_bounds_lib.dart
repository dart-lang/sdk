// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'check_bounds.dart';

testInPart() {
  A a;

  Class<A> classA = new Class<A>();
  classA.method();
  Extension(classA).method(); // Expect bounds mismatch.
  Extension<A>(classA).method(); // Expect bounds mismatch.
  Extension<B>(classA).method();
  Extension(classA).genericMethod(a); // Expect bounds mismatch.
  Extension(classA).genericMethod<A>(a); // Expect bounds mismatch.
  Extension(classA).genericMethod<B>(a); // Expect bounds mismatch.
  Extension<A>(classA).genericMethod(a); // Expect bounds mismatch.
  Extension<A>(classA).genericMethod<A>(a); // Expect bounds mismatch.
  Extension<A>(classA).genericMethod<B>(a); // Expect bounds mismatch.
  Extension<B>(classA).genericMethod(a); // Expect bounds mismatch.
  Extension<B>(classA).genericMethod<A>(a); // Expect bounds mismatch.
  Extension<B>(classA).genericMethod<B>(a);

  Class<B> classB = new Class<B>();
  classB.method();
  Extension(classB).method();
  Extension<A>(classB).method(); // Expect bounds mismatch.
  Extension<B>(classB).method();

  classB.genericMethod(a); // Expect bounds mismatch.
  classB.genericMethod<A>(a); // Expect bounds mismatch.
  classB.genericMethod<B>(a);
  Extension(classB).genericMethod(a); // Expect bounds mismatch.
  Extension(classB).genericMethod<A>(a); // Expect bounds mismatch.
  Extension(classB).genericMethod<B>(a);
  Extension<A>(classB).genericMethod(a); // Expect bounds mismatch.
  Extension<A>(classB).genericMethod<A>(a); // Expect bounds mismatch.
  Extension<A>(classB).genericMethod<B>(a); // Expect bounds mismatch.
  Extension<B>(classB).genericMethod(a); // Expect bounds mismatch.
  Extension<B>(classB).genericMethod<A>(a); // Expect bounds mismatch.
  Extension<B>(classB).genericMethod<B>(a);
}
