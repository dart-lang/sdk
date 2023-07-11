// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// Checks for static errors using external without the @JS() annotation,
// in a library without a @JS() annotation

library external_nonjs_static_test;

import 'dart:html';
import 'package:js/js.dart';

external get topLevelGetter;
//           ^
// [web] Only JS interop members may be 'external'.

external set topLevelSetter(_);
//           ^
// [web] Only JS interop members may be 'external'.

external topLevelFunction();
//       ^
// [web] Only JS interop members may be 'external'.

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

extension ExtensionNative on HtmlElement {
  external get getter;
  external set setter(_);

  external method();
  external optionalParameterMethod([int a, int b = 0]);

  nonExternalMethod() => 1;
  static nonExternalStaticMethod() => 2;
}

main() {}
