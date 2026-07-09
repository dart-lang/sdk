// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests classes implementing other interfaces with JS interop. Only tests
// getters and assumes other instance members work similarly to avoid bloated
// tests.

@JS()
library implements_static_test;

import 'package:js/js.dart';

// Normal and abstract classes for Dart, JS, and anonymous classes.
class DartClass {
  int get dartGetter => 0;
}

abstract class AbstractDartClass {
  int get abstractDartGetter;
}

@JS()
class JSClass {
  external int get jsGetter;
}

@JS()
abstract class AbstractJSClass {
  external int get abstractJsGetter;
}

@JS()
@anonymous
class AnonymousClass {
  external int get anonymousGetter;
}

@JS()
@anonymous
abstract class AbstractAnonymousClass {
  external int get abstractAnonymousGetter;
}

// Dart classes that implement all the other JS type interfaces.
class DartClassImplementsJSClass implements JSClass {
  int get jsGetter => 0;
}

class DartClassImplementsAbstractJSClass implements AbstractJSClass {
  int get abstractJsGetter => 0;
}

class DartClassImplementsAnonymousClass implements AnonymousClass {
  int get anonymousGetter => 0;
}

class DartClassImplementsAbstractAnonymousClass
    implements AbstractAnonymousClass {
  int get abstractAnonymousGetter => 0;
}

// JS classes that implement all the other interfaces.
@JS()
class JSClassImplementsDartClass implements DartClass {
  external int get dartGetter;
}

@JS()
class JSClassImplementsAbstractDartClass implements AbstractDartClass {
  external int get abstractDartGetter;
}

@JS()
class JSClassImplementsJSClass implements JSClass {
  external int get jsGetter;
}

@JS()
class JSClassImplementsAbstractJSClass implements AbstractJSClass {
  external int get abstractJsGetter;
}

@JS()
class JSClassImplementsAnonymousClass implements AnonymousClass {
  external int get anonymousGetter;
}

@JS()
class JSClassImplementsAbstractAnonymousClass
    implements AbstractAnonymousClass {
  external int get abstractAnonymousGetter;
}

// Anonymous classes that implement all the other interfaces.
@JS()
@anonymous
class AnonymousClassImplementsDartClass implements DartClass {
  external int get dartGetter;
}

@JS()
@anonymous
class AnonymousClassImplementsAbstractDartClass implements AbstractDartClass {
  external int get abstractDartGetter;
}

@JS()
@anonymous
class AnonymousClassImplementsJSClass implements JSClass {
  external int get jsGetter;
}

@JS()
@anonymous
class AnonymousClassImplementsAbstractJSClass implements AbstractJSClass {
  external int get abstractJsGetter;
}

@JS()
@anonymous
class AnonymousClassImplementsAnonymousClass implements AnonymousClass {
  external int get anonymousGetter;
}

@JS()
@anonymous
class AnonymousClassImplementsAbstractAnonymousClass
    implements AbstractAnonymousClass {
  external int get abstractAnonymousGetter;
}

// Dart, JS, and anonymous classes implementing multiple interfaces.
class DartClassImplementsMultipleInterfaces
    implements DartClass, AbstractJSClass, AnonymousClass {
  int get dartGetter => 0;
  int get abstractJsGetter => 0;
  int get anonymousGetter => 0;
}

@JS()
class JSClassImplementsMultipleInterfaces
    implements AbstractDartClass, JSClass, AbstractAnonymousClass {
  external int get abstractDartGetter;
  external int get jsGetter;
  external int get abstractAnonymousGetter;
}

@JS()
@anonymous
class AnonymousClassImplementsMultipleInterfaces
    implements DartClass, JSClass, AbstractAnonymousClass {
  external int get dartGetter;
  external int get jsGetter;
  external int get abstractAnonymousGetter;
}

void main() {}
