// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@MirrorsUsed(targets: "Foo")
import "dart:mirrors";

import 'package:expect/expect.dart';

class ParameterAnnotation {
  final String value;
  const ParameterAnnotation(this.value);
}

class Foo {
  Foo(@ParameterAnnotation("vogel") p) {}
  Foo.named(@ParameterAnnotation("hamster") p) {}
  Foo.named2(
      @ParameterAnnotation("hamster") p, @ParameterAnnotation("wurm") p2) {}

  f1(@ParameterAnnotation("hest") p) {}
  f2(@ParameterAnnotation("hest") @ParameterAnnotation("fisk") p) {}
  f3(a, @ParameterAnnotation("fugl") p) {}
  f4(@ParameterAnnotation("fisk") a, {@ParameterAnnotation("hval") p}) {}
  f5(@ParameterAnnotation("fisk") a, [@ParameterAnnotation("hval") p]) {}
  f6({@ParameterAnnotation("fisk") z, @ParameterAnnotation("hval") p}) {}

  set s1(@ParameterAnnotation("cheval") p) {}
}

expectAnnotations(
    Type type, Symbol method, int parameterIndex, List<String> expectedValues) {
  MethodMirror mirror = reflectClass(type).declarations[method];
  ParameterMirror parameter = mirror.parameters[parameterIndex];
  List<InstanceMirror> annotations = parameter.metadata;
  Expect.equals(annotations.length, expectedValues.length,
      "wrong number of parameter annotations");
  for (int i = 0; i < annotations.length; i++) {
    Expect.equals(
        expectedValues[i],
        annotations[i].reflectee.value,
        "annotation #$i of parameter #$parameterIndex "
        "of $type.$method.");
  }
}

main() {
  expectAnnotations(Foo, #Foo, 0, ["vogel"]);
  expectAnnotations(Foo, #Foo.named, 0, ["hamster"]);
  expectAnnotations(Foo, #Foo.named2, 0, ["hamster"]);
  expectAnnotations(Foo, #Foo.named2, 1, ["wurm"]);

  expectAnnotations(Foo, #f1, 0, ["hest"]);
  expectAnnotations(Foo, #f2, 0, ["hest", "fisk"]);
  expectAnnotations(Foo, #f3, 0, []);
  expectAnnotations(Foo, #f3, 1, ["fugl"]);
  expectAnnotations(Foo, #f4, 0, ["fisk"]);
  expectAnnotations(Foo, #f4, 1, ["hval"]);
  expectAnnotations(Foo, #f5, 0, ["fisk"]);
  expectAnnotations(Foo, #f5, 1, ["hval"]);
  expectAnnotations(Foo, #f6, 0, ["fisk"]);
  expectAnnotations(Foo, #f6, 1, ["hval"]);

  expectAnnotations(Foo, const Symbol('s1='), 0, ["cheval"]);
}
