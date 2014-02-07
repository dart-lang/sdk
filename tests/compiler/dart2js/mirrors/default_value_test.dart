// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:mirrors";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";
import "../memory_compiler.dart";

const SOURCE = const {
  'main.dart': """
library main;

class Class {
  var a, b, c, d, e, f, g, h;
  Class.optional(this.a, int b, void this.c(), 
                 [this.d, int this.e, void this.f(), 
                  this.g = 0, int this.h = 0]);
  Class.named(this.a, int b, void this.c(), 
                 {this.d, int this.e, void this.f(), 
                  this.g: 0, int this.h: 0});
  methodOptional(a, int b, void c(), 
                 [d, int e, void f(), 
                  g = 0, int h = 0]) {}
  methodNamed(a, int b, void c(), 
              {d, int e, void f(), 
               g: 0, int h: 0}) {}
} 
""",
};

main() {
  asyncTest(() => mirrorSystemFor(SOURCE).then((MirrorSystem mirrors) {
    LibraryMirror dartCore = mirrors.libraries[Uri.parse('memory:main.dart')];
    ClassMirror classMirror = dartCore.declarations[#Class];
    testMethod(classMirror.declarations[#optional]);
    testMethod(classMirror.declarations[#named]);
    testMethod(classMirror.declarations[#methodOptional]);
    testMethod(classMirror.declarations[#methodNamed]);
  }));
}

testMethod(MethodMirror mirror) {
  Expect.equals(8, mirror.parameters.length);
  for (int i = 0 ; i < 6 ; i++) {
    testParameter(mirror.parameters[i], false);
  }
  for (int i = 6 ; i < 8 ; i++) {
    testParameter(mirror.parameters[i], true);
  }
}

testParameter(ParameterMirror mirror, bool expectDefaultValue) {
  if (expectDefaultValue) {
    Expect.isTrue(mirror.hasDefaultValue);
    Expect.isNotNull(mirror.defaultValue);
  } else {
    Expect.isFalse(mirror.hasDefaultValue);
    Expect.isNull(mirror.defaultValue);
  }
}
