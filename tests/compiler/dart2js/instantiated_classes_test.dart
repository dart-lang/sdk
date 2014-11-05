// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library instantiated_classes_test;

import 'dart:async';
import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/elements/elements.dart'
    show ClassElement;
import 'type_test_helper.dart';

void main() {
  asyncTest(() => Future.forEach([
    () => test("class Class {}", ["Class"]),
    () => test("""abstract class A {}
                  class Class extends A {}""",
               ["Class"]),
    () => test("""class A {}
                  class Class extends A {}""",
               ["Class"]),
    () => test("""class A {}
                  class B {}
                  class Class extends A {}""",
               ["Class"]),
    () => test("""class A {}
                  class Class implements A {}""",
               ["Class"]),
    () => test("""class A {}
                  class Class extends Object with A {}""",
               ["Class"]),
    () => test("""class A {}
                  class B {}
                  class Class extends Object with B implements A {}""",
               ["Class"]),

    () => test("""class A {}
                  class Class {}""",
               ["Class", "A"], ["Class", "A"]),
    () => test("""class A {}
                  class Class extends A {}""",
               ["Class", "A"], ["Class", "A"]),
    () => test("""class A {}
                  class Class implements A {}""",
               ["Class", "A"], ["Class", "A"]),
    () => test("""class A {}
                  class B extends A {}
                  class Class extends B {}""",
               ["Class", "A"], ["Class", "A"]),
    () => test("""class A {}
                  class B {}
                  class Class extends B with A {}""",
               ["Class", "A"], ["Class", "A"]),

    // TODO(johnniwinther): Avoid registration of `Class` as instantiated.
    () => test("""class A {}
                  class Class implements A {
                    factory Class() = A;
                  }""",
               ["Class", "A"], ["Class"]),
  ], (f) => f()));
}

Future test(String source, List<String> directlyInstantiatedClasses,
            [List<String> newClasses = const <String>["Class"]]) {
  StringBuffer mainSource = new StringBuffer();
  mainSource.write('main() {\n');
  for (String newClass in newClasses) {
    mainSource.write('  new $newClass();\n');
  }
  mainSource.write('}');
  return TypeEnvironment.create(source,
        mainSource: mainSource.toString(),
        useMockCompiler: true).then((env) {
    Iterable<ClassElement> expectedClasses =
        directlyInstantiatedClasses.map(env.getElement);
    Iterable<ClassElement> actualClasses =
        env.compiler.resolverWorld.directlyInstantiatedClasses.where(
            (c) => c.library == env.compiler.mainApp);
    Expect.setEquals(expectedClasses, actualClasses);
  });
}


