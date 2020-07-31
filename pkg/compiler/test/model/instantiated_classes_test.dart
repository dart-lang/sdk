// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

library instantiated_classes_test;

import 'dart:async';
import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/elements/entities.dart'
    show ClassEntity, LibraryEntity;
import '../helpers/type_test_helper.dart';

void main() {
  Future runTests() async {
    Future test(String source, List<String> directlyInstantiatedClasses,
        [List<String> newClasses = const <String>["Class"]]) async {
      StringBuffer mainSource = new StringBuffer();
      mainSource.writeln(source);
      mainSource.write('main() {\n');
      for (String newClass in newClasses) {
        mainSource.write('  new $newClass();\n');
      }
      mainSource.write('}');
      dynamic env = await TypeEnvironment.create(mainSource.toString());
      LibraryEntity mainLibrary =
          env.compiler.frontendStrategy.elementEnvironment.mainLibrary;
      Iterable<ClassEntity> expectedClasses =
          directlyInstantiatedClasses.map((String name) {
        return env.getElement(name);
      });
      Iterable<ClassEntity> actualClasses = env
          .compiler.resolutionWorldBuilderForTesting.directlyInstantiatedClasses
          .where((c) => c.library == mainLibrary);
      Expect.setEquals(
          expectedClasses,
          actualClasses,
          "Instantiated classes mismatch: "
          "Expected $expectedClasses, actual: $actualClasses");
    }

    await test("class Class {}", ["Class"]);
    await test("""abstract class A {}
                  class Class extends A {}""", ["Class"]);
    await test("""class A {}
                  class Class extends A {}""", ["Class"]);
    await test("""class A {}
                  class B {}
                  class Class extends A {}""", ["Class"]);
    await test("""class A {}
                  class Class implements A {}""", ["Class"]);
    await test("""class A {}
                  class Class extends Object with A {}""", ["Class"]);
    await test("""class A {}
                  class B {}
                  class Class extends Object with B implements A {}""",
        ["Class"]);

    await test("""class A {}
                  class Class {}""", ["Class", "A"], ["Class", "A"]);
    await test("""class A {}
                  class Class extends A {}""", ["Class", "A"], ["Class", "A"]);
    await test("""class A {}
                  class Class implements A {}""", ["Class", "A"],
        ["Class", "A"]);
    await test("""class A {}
                  class B extends A {}
                  class Class extends B {}""", ["Class", "A"], ["Class", "A"]);
    await test("""class A {}
                  class B {}
                  class Class extends B with A {}""", ["Class", "A"],
        ["Class", "A"]);

    await test("""class A implements Class {}
                  class Class {
                    factory Class() = A;
                  }""", ["A"], ["Class"]);
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTests();
  });
}
