// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/inferrer/typemasks/masks.dart';
import '../helpers/memory_compiler.dart';

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
  var a = new A("42" as dynamic);
  print(a.aField);
  print(a.foo("42"));
  print(a.foo(42));
  print(a.faa("42" as dynamic));
  print(a.faa(42));
  print(a.baz("42"));
  print(a.baz(42));
  // Test trusting types of tear off closures.
  print(a.tear("42"));
  print(a.tear(42));
}
""";

void main() {
  runTest() async {
    var options = [Flags.omitImplicitChecks];
    var result = await runCompiler(
        memorySourceFiles: {'main.dart': TEST}, options: options);
    var compiler = result.compiler;
    var results = compiler.globalInference.resultsForTesting;
    var closedWorld = results.closedWorld;
    var elementEnvironment = closedWorld.elementEnvironment;

    ClassEntity classA =
        elementEnvironment.lookupClass(elementEnvironment.mainLibrary, "A");

    checkReturn(String name, TypeMask type) {
      MemberEntity element = elementEnvironment.lookupClassMember(classA, name);
      var mask = results.resultOfMember(element).returnType;
      Expect.isTrue(type.containsMask(mask, closedWorld));
    }

    checkType(String name, type) {
      MemberEntity element = elementEnvironment.lookupClassMember(classA, name);
      Expect.isTrue(
          type.containsMask(results.resultOfMember(element).type, closedWorld));
    }

    var intMask =
        new TypeMask.subtype(closedWorld.commonElements.intClass, closedWorld);

    checkReturn('foo', intMask);
    checkReturn('faa', intMask);
    checkType('aField', intMask);
    checkReturn('bar', intMask);
    checkReturn('baz', intMask);
    checkReturn('tear', intMask);
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTest();
  });
}
