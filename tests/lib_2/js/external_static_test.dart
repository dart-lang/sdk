// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// Checks for static errors using external without the @JS() annotation,
// in a library with a @JS() annotation

@JS()
library external_static_test;

import 'dart:html';
import 'package:js/js.dart';

// external top level members ok in @JS() library.
external get topLevelGetter;
external set topLevelSetter(_);
external topLevelFunction();

class Constructors {
  external Constructors();
  //       ^
  // [web] Only JS interop members may be 'external'.

  external Constructors.namedConstructor();
  //       ^
  // [web] Only JS interop members may be 'external'.

  external factory Constructors.namedFactory();
  //               ^
  // [web] Only JS interop members may be 'external'.
}

class Members {
  external get instanceGetter;
  //           ^
  // [web] Only JS interop members may be 'external'.

  external set instanceSetter(_);
  //           ^
  // [web] Only JS interop members may be 'external'.

  external instanceMethod();
  //       ^
  // [web] Only JS interop members may be 'external'.
}

class StaticMembers {
  external static get staticGetter;
  //                  ^
  // [web] Only JS interop members may be 'external'.

  external static set staticSetter(_);
  //                  ^
  // [web] Only JS interop members may be 'external'.

  external static staticMethod();
  //              ^
  // [web] Only JS interop members may be 'external'.
}

@anonymous
class AnonymousClass {
  external factory AnonymousClass();
  //               ^
  // [web] Only JS interop members may be 'external'.
}

extension ExtensionNonJS on NonJSClass {
  external get getter;
  //           ^
  // [web] JS interop or Native class required for 'external' extension members.
  external set setter(_);
  //           ^
  // [web] JS interop or Native class required for 'external' extension members.

  external static get staticGetter;
  //                  ^
  // [web] JS interop or Native class required for 'external' extension members.
  external static set staticSetter(_);
  //                  ^
  // [web] JS interop or Native class required for 'external' extension members.

  external method();
  //       ^
  // [web] JS interop or Native class required for 'external' extension members.
  external static staticMethod();
  //              ^
  // [web] JS interop or Native class required for 'external' extension members.
  external optionalParameterMethod([int a, int b = 0]);
  //       ^
  // [web] JS interop or Native class required for 'external' extension members.
  external overriddenMethod();
  //       ^
  // [web] JS interop or Native class required for 'external' extension members.

  @JS('memberAnnotation')
  external annotatedMethod();
  //       ^
  // [web] JS interop or Native class required for 'external' extension members.

  nonExternalMethod() => 1;
  static nonExternalStaticMethod() => 2;
}

class NonJSClass {
  void overriddenMethod() => 5;
}

extension ExtensionGenericNonJS<T> on GenericNonJSClass<T> {
  external T method();
  //         ^
  // [web] JS interop or Native class required for 'external' extension members.
}

class GenericNonJSClass<T> {}

extension ExtensionJS on JSClass {
  external get getter;
  external set setter(_);

  external static get staticGetter;
  external static set staticSetter(_);

  external method();
  external static staticMethod();
  external optionalParameterMethod([int a, int b = 0]);

  @JS('memberAnnotation')
  external annotatedMethod();

  nonExternalMethod() => 1;
  static nonExternalStaticMethod() => 2;
}

@JS()
class JSClass {}

extension ExtensionGenericJS<T> on GenericJSClass<T> {
  external T method();
}

@JS()
class GenericJSClass<T> {}

extension ExtensionAnonymousJS on AnonymousJSClass {
  external get getter;
  external set setter(_);
  external method();
}

@JS()
@anonymous
class AnonymousJSClass {}

extension ExtensionAbstractJS on AbstractJSClass {
  external get getter;
  external set setter(_);
  external method();
}

@JS()
abstract class AbstractJSClass {}

extension ExtensionAnnotatedJS on AnnotatedJSClass {
  external get getter;
  external set setter(_);
  external method();
}

@JS('Annotation')
class AnnotatedJSClass {}

extension ExtensionPrivateJS on _privateJSClass {
  external get getter;
  external set setter(_);
  external method();
}

@JS()
class _privateJSClass {}

extension ExtensionNative on HtmlElement {
  external get getter;
  external set setter(_);

  external static get staticGetter;
  external static set staticSetter(_);

  external method();
  external static staticMethod();
  external optionalParameterMethod([int a, int b = 0]);

  nonExternalMethod() => 1;
  static nonExternalStaticMethod() => 2;
}

main() {}
