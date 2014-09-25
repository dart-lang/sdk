// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'compiler_helper.dart';

const String TEST = """
class A {
  int aField;

  A(this.aField);

  // Test return type annotation.
  int foo(a) => a;
  // Test parameter type annotation.
  faa (int a) => a;
  // Test annotations on locals.
  baz(x) {
    int y = x;
    return y;
  }
  // Test tear-off closure type annotations.
  int bar(x) => x;
  int tear(x) {
    var torn = bar;
    // Have torn escape through closure to disable tracing.
    var fail = (() => torn)();
    return fail(x);
  }
}

main () {
  var a = new A("42");
  print(a.aField);
  print(a.foo("42"));
  print(a.foo(42));
  print(a.faa("42"));
  print(a.faa(42));
  print(a.baz("42"));
  print(a.baz(42));
  // Test trusting types of tear off closures.
  print(a.tear("42"));
  print(a.tear(42));
}
""";

void main() {
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(TEST, uri, trustTypeAnnotations: true);
  asyncTest(() => compiler.runCompiler(uri).then((_) {
    var typesInferrer = compiler.typesTask.typesInferrer;

    ClassElement classA = findElement(compiler, "A");

    checkReturn(String name, TypeMask type) {
      var element = classA.lookupMember(name);
      var mask = typesInferrer.getReturnTypeOfElement(element);
      Expect.isTrue(type.containsMask(
          typesInferrer.getReturnTypeOfElement(element), compiler.world));
    }
    checkType(String name, type) {
      var element = classA.lookupMember(name);
      Expect.isTrue(type.containsMask(
                typesInferrer.getTypeOfElement(element), compiler.world));
    }

    var intMask = new TypeMask.subtype(compiler.intClass, compiler.world);

    checkReturn('foo', intMask);
    checkReturn('faa', intMask);
    checkType('aField', intMask);
    checkReturn('bar', intMask);
    checkReturn('baz', intMask);
    checkReturn('tear', intMask);
  }));
}
