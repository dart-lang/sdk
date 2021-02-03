// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Checks for static errors using external without the @JS() annotation,
// in a library with a @JS() annotation

@JS()
library external_static_test;

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

main() {}
