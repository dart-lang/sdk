// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Checks for static errors using external without the @JS() annotation,
// in a library with a @JS() annotation

@JS()
library external_static_test;

import 'dart:html';
import 'package:js/js.dart';

// external top level members ok in @JS() library.
external var topLevelField;
external final topLevelFinalField;
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
  external var field;
  //           ^
  // [web] Only JS interop members may be 'external'.

  external final finalField;
  //             ^
  // [web] Only JS interop members may be 'external'.

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
  external static var staticField;
  //                  ^
  // [web] Only JS interop members may be 'external'.

  external static final staticFinalField;
  //                    ^
  // [web] Only JS interop members may be 'external'.

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
  external var field;
  //           ^
  // [web] Only JS interop members may be 'external'.

  external factory AnonymousClass({var field});
  //               ^
  // [web] Only JS interop members may be 'external'.
}

extension ExtensionNonJS on NonJSClass {
  external var field;
  //           ^
  // [web] JS interop or Native class required for 'external' extension members.
  external final finalField;
  //             ^
  // [web] JS interop or Native class required for 'external' extension members.
  external static var staticField;
  //                  ^
  // [web] JS interop or Native class required for 'external' extension members.
  external static final staticFinalField;
  //                    ^
  // [web] JS interop or Native class required for 'external' extension members.

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
  external optionalParameterMethod([int? a, int b = 0]);
  //       ^
  // [web] JS interop or Native class required for 'external' extension members.
  external overriddenMethod();
  //       ^
  // [web] JS interop or Native class required for 'external' extension members.

  @JS('fieldAnnotation')
  external var annotatedField;
  //           ^
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
  external var field;
  external final finalField;

  external get getter;
  external set setter(_);

  external method();
  external optionalParameterMethod([int? a, int b = 0]);

  @JS('fieldAnnotation')
  external var annotatedField;

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
  external var field;
  external get getter;
  external set setter(_);
  external method();
}

@JS()
@anonymous
class AnonymousJSClass {}

extension ExtensionAbstractJS on AbstractJSClass {
  external var field;
  external get getter;
  external set setter(_);
  external method();
}

@JS()
abstract class AbstractJSClass {}

extension ExtensionAnnotatedJS on AnnotatedJSClass {
  external var field;
  external get getter;
  external set setter(_);
  external method();
}

@JS('Annotation')
class AnnotatedJSClass {}

extension ExtensionPrivateJS on _privateJSClass {
  external var field;
  external get getter;
  external set setter(_);
  external method();
}

@JS()
class _privateJSClass {}

extension ExtensionNative on HtmlElement {
  external var field;
  external final finalField;
  external static var staticField;
  external static final staticFinalField;

  external get getter;
  external set setter(_);

  external static get staticGetter;
  external static set staticSetter(_);

  external method();
  external static staticMethod();
  external optionalParameterMethod([int? a, int b = 0]);

  nonExternalMethod() => 1;
  static nonExternalStaticMethod() => 2;
}

main() {}
