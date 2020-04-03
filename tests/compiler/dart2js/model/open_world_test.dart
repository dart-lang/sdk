// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/ir/static_type.dart';
import 'package:compiler/src/js_backend/native_data.dart';
import 'package:compiler/src/universe/resolution_world_builder.dart';
import 'package:compiler/src/universe/world_builder.dart';
import '../helpers/memory_compiler.dart';

main() {
  asyncTest(() async {
    await runTest();
  });
}

runTest() async {
  String classes = '''
@JS()
library lib;

import 'package:js/js.dart';

class A {}
class A1 extends A {}
class A2 extends A1 {}

class B implements A {}
class B1 extends B {}

class C {}
class C0 {}
class C1 = C with A;
class C2 extends C1 {}
class C3 = C with C0, A;
class C4 = C with A, C0;

@JS()
class D {}

@JS()
class D1 extends D {}

''';

  CommonElements commonElements;
  NativeBasicData nativeBasicData;
  ResolutionWorldBuilderImpl world;

  List<ClassEntity> allClasses;

  ClassEntity A;
  ClassEntity A1;
  ClassEntity A2;
  ClassEntity B;
  ClassEntity B1;
  ClassEntity C;
  ClassEntity C0;
  ClassEntity C1;
  ClassEntity C2;
  ClassEntity C3;
  ClassEntity C4;
  ClassEntity D;
  ClassEntity D1;

  List<ClassRelation> allRelations = ClassRelation.values;
  List<ClassRelation> notExact = [
    ClassRelation.thisExpression,
    ClassRelation.subtype
  ];
  List<ClassRelation> subtype = [ClassRelation.subtype];

  run(List<String> liveClasses) async {
    String source = '''
$classes
main() {
${liveClasses.map((c) => '  new $c();').join('\n')}
}
''';
    print('------------------------------------------------------------------');
    print(source);
    CompilationResult result =
        await runCompiler(memorySourceFiles: {'main.dart': source});
    Expect.isTrue(result.isSuccess);
    Compiler compiler = result.compiler;
    commonElements = compiler.frontendStrategy.commonElements;
    ElementEnvironment elementEnvironment =
        compiler.frontendStrategy.elementEnvironment;
    nativeBasicData = compiler.frontendStrategy.nativeBasicData;
    world = compiler.resolutionWorldBuilderForTesting;

    ClassEntity findClass(String name) {
      ClassEntity cls =
          elementEnvironment.lookupClass(elementEnvironment.mainLibrary, name);
      Expect.isNotNull(cls, 'Class $name not found.');
      return cls;
    }

    allClasses = [
      A = findClass('A'),
      A1 = findClass('A1'),
      A2 = findClass('A2'),
      B = findClass('B'),
      B1 = findClass('B1'),
      C = findClass('C'),
      C0 = findClass('C0'),
      C1 = findClass('C1'),
      C2 = findClass('C2'),
      C3 = findClass('C3'),
      C4 = findClass('C4'),
      D = findClass('D'),
      D1 = findClass('D1'),
    ];
  }

  void check(
      Map<ClassEntity, Map<ClassEntity, List<ClassRelation>>> expectedResults) {
    for (ClassEntity cls in allClasses) {
      for (ClassEntity memberHoldingClass in allClasses) {
        Map<ClassEntity, List<ClassRelation>> memberResults =
            expectedResults[memberHoldingClass] ?? {};
        for (ClassRelation relation in allRelations) {
          List<ClassRelation> expectRelations = memberResults[cls];
          bool expectedResult =
              expectRelations != null && expectRelations.contains(relation);
          StrongModeConstraint constraint = new StrongModeConstraint(
              commonElements, nativeBasicData, cls, relation);
          Expect.equals(
              expectedResult,
              world.isInheritedInClass(
                  memberHoldingClass, constraint.cls, constraint.relation),
              "Unexpected results for member of $memberHoldingClass on a "
              "receiver $constraint (cls=$cls, relation=$relation)");
        }
      }
    }
  }

  await run([]);
  check({});

  await run(['A']);
  check({
    A: {A: allRelations},
  });

  await run(['A1']);
  check({
    A: {
      A: notExact,
      A1: allRelations,
    },
    A1: {
      A: notExact,
      A1: allRelations,
    },
  });

  await run(['A', 'A1']);
  check({
    A: {
      A: allRelations,
      A1: allRelations,
    },
    A1: {
      A: notExact,
      A1: allRelations,
    },
  });

  await run(['A2']);
  check({
    A: {
      A: notExact,
      A1: notExact,
      A2: allRelations,
    },
    A1: {
      A: notExact,
      A1: notExact,
      A2: allRelations,
    },
    A2: {
      A: notExact,
      A1: notExact,
      A2: allRelations,
    },
  });

  await run(['A', 'A2']);
  check({
    A: {
      A: allRelations,
      A1: notExact,
      A2: allRelations,
    },
    A1: {
      A: notExact,
      A1: notExact,
      A2: allRelations,
    },
    A2: {
      A: notExact,
      A1: notExact,
      A2: allRelations,
    },
  });

  await run(['A1', 'A2']);
  check({
    A: {
      A: notExact,
      A1: allRelations,
      A2: allRelations,
    },
    A1: {
      A: notExact,
      A1: allRelations,
      A2: allRelations,
    },
    A2: {
      A: notExact,
      A1: notExact,
      A2: allRelations,
    },
  });

  await run(['B']);
  check({
    B: {
      A: subtype,
      B: allRelations,
    },
  });

  await run(['B1']);
  check({
    B: {
      A: subtype,
      B: notExact,
      B1: allRelations,
    },
    B1: {
      A: subtype,
      B: notExact,
      B1: allRelations,
    },
  });

  await run(['A', 'A2', 'B']);
  check({
    A: {
      A: allRelations,
      A1: notExact,
      A2: allRelations,
    },
    A1: {
      A: notExact,
      A1: notExact,
      A2: allRelations,
    },
    A2: {
      A: notExact,
      A1: notExact,
      A2: allRelations,
    },
    B: {A: subtype, B: allRelations},
  });

  await run(['C']);
  check({
    C: {
      C: allRelations,
    },
  });

  await run(['C1']);
  check({
    A: {
      A: notExact,
      C: notExact,
      C1: allRelations,
    },
    C: {
      A: notExact,
      C: notExact,
      C1: allRelations,
    },
    C1: {
      A: notExact,
      C: notExact,
      C1: allRelations,
    },
  });

  await run(['C2']);
  check({
    A: {
      A: notExact,
      C: notExact,
      C1: notExact,
      C2: allRelations,
    },
    C: {
      A: notExact,
      C: notExact,
      C1: notExact,
      C2: allRelations,
    },
    C1: {
      A: notExact,
      C: notExact,
      C1: notExact,
      C2: allRelations,
    },
    C2: {
      A: notExact,
      C: notExact,
      C1: notExact,
      C2: allRelations,
    },
  });

  await run(['C3']);
  check({
    A: {
      A: notExact,
      C: notExact,
      C0: notExact,
      C3: allRelations,
    },
    C: {
      A: notExact,
      C: notExact,
      C0: notExact,
      C3: allRelations,
    },
    C0: {
      A: notExact,
      C: notExact,
      C0: notExact,
      C3: allRelations,
    },
    C3: {
      A: notExact,
      C: notExact,
      C0: notExact,
      C3: allRelations,
    },
  });

  await run(['C4']);
  check({
    A: {
      A: notExact,
      C: notExact,
      C0: notExact,
      C4: allRelations,
    },
    C: {
      A: notExact,
      C: notExact,
      C0: notExact,
      C4: allRelations,
    },
    C0: {
      A: notExact,
      C: notExact,
      C0: notExact,
      C4: allRelations,
    },
    C4: {
      A: notExact,
      C: notExact,
      C0: notExact,
      C4: allRelations,
    },
  });

  await run(['A2', 'C1']);
  check({
    A: {
      A: notExact,
      A1: notExact,
      A2: allRelations,
      C: notExact,
      C1: allRelations,
    },
    A1: {
      A: notExact,
      A1: notExact,
      A2: allRelations,
    },
    A2: {
      A: notExact,
      A1: notExact,
      A2: allRelations,
    },
    C: {
      A: notExact,
      C: notExact,
      C1: allRelations,
    },
    C1: {
      A: notExact,
      C: notExact,
      C1: allRelations,
    },
  });

  await run(['D']);
  check({
    D: {
      D: allRelations,
      D1: allRelations,
    },
  });
  await run(['D1']);
  check({
    D: {
      D: allRelations,
      D1: allRelations,
    },
    D1: {
      D: allRelations,
      D1: allRelations,
    },
  });
}
