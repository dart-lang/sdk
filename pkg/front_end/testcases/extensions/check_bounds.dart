// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part 'check_bounds_lib.dart';

class A {}

class B extends A {}

class Class<T extends A> {}

extension Extension<T extends B> on Class<T> {
  method() {}
  genericMethod<S extends B>(S s) {}
}

main() {}

test() {
  A a;

  Class<A> classA = new Class<A>();
  classA.method(); // Expect method not found.
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

final A a = new A();
final Class<A> classA = new Class<A>();
final field1 = classA.method(); // Expect method not found.
final field2 = Extension(classA).method(); // Expect bounds mismatch.
final field3 = Extension<A>(classA).method(); // Expect bounds mismatch.
final field4 = Extension<B>(classA).method();
final field5 = Extension(classA).genericMethod(a); // Expect bounds mismatch.
final field6 = Extension(classA).genericMethod<A>(a); // Expect bounds mismatch.
final field7 = Extension(classA).genericMethod<B>(a); // Expect bounds mismatch.
final field8 = Extension<A>(classA).genericMethod(a); // Expect bounds mismatch.
final field9 =
    Extension<A>(classA).genericMethod<A>(a); // Expect bounds mismatch.
final field10 =
    Extension<A>(classA).genericMethod<B>(a); // Expect bounds mismatch.
final field11 =
    Extension<B>(classA).genericMethod(a); // Expect bounds mismatch.
final field12 =
    Extension<B>(classA).genericMethod<A>(a); // Expect bounds mismatch.
final field13 = Extension<B>(classA).genericMethod<B>(a);

final Class<B> classB = new Class<B>();
final field14 = classB.method();
final field15 = Extension(classB).method();
final field16 = Extension<A>(classB).method(); // Expect bounds mismatch.
final field17 = Extension<B>(classB).method();

final field18 = classB.genericMethod(a); // Expect bounds mismatch.
final field19 = classB.genericMethod<A>(a); // Expect bounds mismatch.
final field20 = classB.genericMethod<B>(a);
final field21 = Extension(classB).genericMethod(a); // Expect bounds mismatch.
final field22 =
    Extension(classB).genericMethod<A>(a); // Expect bounds mismatch.
final field23 = Extension(classB).genericMethod<B>(a);
final field24 =
    Extension<A>(classB).genericMethod(a); // Expect bounds mismatch.
final field25 =
    Extension<A>(classB).genericMethod<A>(a); // Expect bounds mismatch.
final field26 =
    Extension<A>(classB).genericMethod<B>(a); // Expect bounds mismatch.
final field27 =
    Extension<B>(classB).genericMethod(a); // Expect bounds mismatch.
final field28 =
    Extension<B>(classB).genericMethod<A>(a); // Expect bounds mismatch.
final field29 = Extension<B>(classB).genericMethod<B>(a);
