// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that interop classes that inherit/implement other classes have the
// appropriate static interop static errors.

@JS()
library supertype_test;

import 'package:js/js.dart';

// Static base interop class.
@JS()
@staticInterop
class Static {}

// Non-static base interop class.
@JS()
class NonStatic {
  external int instanceMethod();
}

@JS()
@staticInterop
class NonStaticMarkedAsStatic {
  external int instanceMethod();
  //           ^
  // [web] JS interop class 'NonStaticMarkedAsStatic' with `@staticInterop` annotation cannot declare instance members.
}

// Static interop classes can inherit other static interop classes in order to
// inherit its extension methods.
@JS()
@staticInterop
class StaticExtendsStatic extends Static {}

// Static interop classes are disallowed from extending non-static interop
// classes.
@JS()
@staticInterop
class StaticExtendsNonStatic extends NonStatic {}
//    ^
// [web] JS interop class 'StaticExtendsNonStatic' has an `@staticInterop` annotation, but has supertype 'NonStatic', which is non-static.

// Static interop classes can implement each other in order to inherit extension
// methods. Note that a non-abstract static interop class can not implement a
// non-static class by definition, as it would need to contain an
// implementation.
@JS()
@staticInterop
class StaticImplementsStatic implements Static {}

// Abstract classes should behave the same way as concrete classes.
@JS()
@staticInterop
abstract class StaticAbstract {}

// Abstract classes with instance members should be non-static. The following
// have abstract or concrete members, so they're considered non-static.
@JS()
abstract class NonStaticAbstract {
  int abstractMethod();
}

@JS()
@staticInterop
abstract class NonStaticAbstractWithAbstractMembers {
  int abstractMethod();
  //  ^
  // [web] JS interop class 'NonStaticAbstractWithAbstractMembers' with `@staticInterop` annotation cannot declare instance members.
}

@JS()
@staticInterop
abstract class NonStaticAbstractWithConcreteMembers {
  external int instanceMethod();
  //           ^
  // [web] JS interop class 'NonStaticAbstractWithConcreteMembers' with `@staticInterop` annotation cannot declare instance members.
}

@JS()
@staticInterop
abstract class StaticAbstractImplementsStaticAbstract
    implements StaticAbstract {}

@JS()
@staticInterop
abstract class StaticAbstractExtendsStaticAbstract extends StaticAbstract {}

@JS()
@staticInterop
abstract class StaticAbstractImplementsNonStaticAbstract
//             ^
// [web] JS interop class 'StaticAbstractImplementsNonStaticAbstract' has an `@staticInterop` annotation, but has supertype 'NonStaticAbstract', which is non-static.
    implements
        NonStaticAbstract {}

@JS()
@staticInterop
abstract class StaticAbstractImplementsMultipleNonStatic
//             ^
// [web] JS interop class 'StaticAbstractImplementsMultipleNonStatic' has an `@staticInterop` annotation, but has supertype 'NonStatic', which is non-static.
// [web] JS interop class 'StaticAbstractImplementsMultipleNonStatic' has an `@staticInterop` annotation, but has supertype 'NonStaticAbstract', which is non-static.
    implements
        NonStaticAbstract,
        NonStatic {}

@JS()
@staticInterop
abstract class StaticAbstractExtendsNonStaticAbstract
//             ^
// [web] JS interop class 'StaticAbstractExtendsNonStaticAbstract' has an `@staticInterop` annotation, but has supertype 'NonStaticAbstract', which is non-static.
    extends NonStaticAbstract {}
