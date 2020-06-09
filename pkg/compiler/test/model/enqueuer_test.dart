// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Test that the enqueuers are not dependent upon in which order impacts are
// applied.

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/elements/names.dart';
import 'package:compiler/src/elements/types.dart';
import 'package:compiler/src/enqueue.dart';
import 'package:compiler/src/inferrer/typemasks/masks.dart';
import 'package:compiler/src/universe/call_structure.dart';
import 'package:compiler/src/universe/selector.dart';
import 'package:compiler/src/universe/world_impact.dart';
import 'package:compiler/src/universe/use.dart';
import 'package:compiler/src/universe/world_builder.dart';
import 'package:compiler/src/world.dart';
import 'package:expect/expect.dart';
import '../helpers/memory_compiler.dart';

class Test {
  final String name;
  final String code;
  final List<Impact> impacts;
  final Map<String, List<String>> expectedLiveMap;

  const Test({this.name, this.code, this.impacts, this.expectedLiveMap});

  Map<String, List<String>> get expectedLiveResolutionMap {
    Map<String, List<String>> map = {};
    expectedLiveMap.forEach((String clsName, List<String> memberNames) {
      for (String memberName in memberNames) {
        if (memberName.startsWith('?')) {
          memberName = memberName.substring(1);
        }
        map.putIfAbsent(clsName, () => []).add(memberName);
      }
    });
    return map;
  }

  Map<String, List<String>> get expectedLiveCodegenMap {
    Map<String, List<String>> map = {};
    expectedLiveMap.forEach((String clsName, List<String> memberNames) {
      for (String memberName in memberNames) {
        if (memberName.startsWith('?')) {
          // Skip for codegen
          continue;
        }
        map.putIfAbsent(clsName, () => []).add(memberName);
      }
    });
    return map;
  }
}

enum ImpactKind { instantiate, invoke }

class Impact {
  final ImpactKind kind;
  final String clsName;
  final String memberName;

  const Impact.instantiate(this.clsName, [this.memberName = ''])
      : this.kind = ImpactKind.instantiate;
  const Impact.invoke(this.clsName, this.memberName)
      : this.kind = ImpactKind.invoke;

  @override
  String toString() =>
      'Impact(kind=$kind,clsName=$clsName,memberName=$memberName)';
}

const List<Test> tests = const <Test>[
  const Test(name: 'Instantiate class', code: '''
class A {
  void method() {}
}
''', impacts: const [
    const Impact.instantiate('A'),
    const Impact.invoke('A', 'method'),
  ], expectedLiveMap: const {
    'A': const ['', 'method'],
  }),
  const Test(name: 'Instantiate subclass', code: '''
class A {
  void method() {}
}
class B extends A {
}
''', impacts: const [
    const Impact.instantiate('B'),
    const Impact.invoke('B', 'method'),
  ], expectedLiveMap: const {
    'A': const ['?', 'method'],
    'B': const [''],
  }),
  const Test(name: 'Instantiate superclass/subclass', code: '''
class A {
  void method() {}
}
class B extends A {
}
''', impacts: const [
    const Impact.instantiate('A'),
    const Impact.instantiate('B'),
    const Impact.invoke('B', 'method'),
  ], expectedLiveMap: const {
    'A': const ['', 'method'],
    'B': const [''],
  }),
];

main() {
  asyncTest(() async {
    for (Test test in tests) {
      await runTest(test);
    }
  });
}

runTest(Test test) async {
  print('====================================================================');
  print('Running test ${test.name}');
  for (List<Impact> permutation in permutations(test.impacts)) {
    print('------------------------------------------------------------------');
    print('Permutation: $permutation');
    await runTestPermutation(test, permutation);
  }
}

Iterable<List<Impact>> permutations(List<Impact> impacts) sync* {
  int length = impacts.length;
  if (length <= 1) {
    yield impacts;
  } else {
    for (int index = 0; index < length; index++) {
      Impact head = impacts[index];
      List<Impact> tail = new List<Impact>.from(impacts)..removeAt(index);
      for (List<Impact> permutation in permutations(tail)) {
        yield [head]..addAll(permutation);
      }
    }
  }
}

runTestPermutation(Test test, List<Impact> impacts) async {
  Compiler compiler = compilerFor(memorySourceFiles: {
    'main.dart': '''
${test.code}
main() {}
'''
  }, options: [
    Flags.disableInlining,
  ]);

  void checkInvariant(
      Enqueuer enqueuer, ElementEnvironment elementEnvironment) {
    for (MemberEntity member
        in compiler.enqueuer.resolutionEnqueuerForTesting.processedEntities) {
      Expect.isTrue(
          member == elementEnvironment.mainFunction ||
              member.library != elementEnvironment.mainLibrary,
          "Unexpected member $member in ${enqueuer}.");
    }
  }

  void instantiate(
      Enqueuer enqueuer, ElementEnvironment elementEnvironment, String name) {
    ClassEntity cls =
        elementEnvironment.lookupClass(elementEnvironment.mainLibrary, name);
    ConstructorEntity constructor =
        elementEnvironment.lookupConstructor(cls, '');
    InterfaceType type = elementEnvironment.getRawType(cls);
    WorldImpact impact = new WorldImpactBuilderImpl()
      ..registerStaticUse(new StaticUse.typedConstructorInvoke(constructor,
          constructor.parameterStructure.callStructure, type, null));
    enqueuer.applyImpact(impact);
  }

  void invoke(
      Enqueuer enqueuer,
      ElementEnvironment elementEnvironment,
      String className,
      String methodName,
      Object Function(ClassEntity cls) createConstraint) {
    ClassEntity cls = elementEnvironment.lookupClass(
        elementEnvironment.mainLibrary, className);
    Selector selector = new Selector.call(
        new Name(methodName, elementEnvironment.mainLibrary),
        CallStructure.NO_ARGS);
    WorldImpact impact = new WorldImpactBuilderImpl()
      ..registerDynamicUse(
          new DynamicUse(selector, createConstraint(cls), const <DartType>[]));
    enqueuer.applyImpact(impact);
  }

  void applyImpact(Enqueuer enqueuer, ElementEnvironment elementEnvironment,
      Impact impact, Object Function(ClassEntity cls) createConstraint) {
    switch (impact.kind) {
      case ImpactKind.instantiate:
        instantiate(enqueuer, elementEnvironment, impact.clsName);
        break;
      case ImpactKind.invoke:
        invoke(enqueuer, elementEnvironment, impact.clsName, impact.memberName,
            createConstraint);
        break;
    }
  }

  void checkLiveMembers(
      Enqueuer enqueuer,
      ElementEnvironment elementEnvironment,
      Map<String, List<String>> expectedLiveMap) {
    Map<String, List<String>> actualLiveMap = {};
    for (MemberEntity member in enqueuer.processedEntities) {
      if (member != elementEnvironment.mainFunction &&
          member.library == elementEnvironment.mainLibrary) {
        actualLiveMap
            .putIfAbsent(member.enclosingClass.name, () => [])
            .add(member.name);
      }
    }

    Expect.setEquals(
        expectedLiveMap.keys,
        actualLiveMap.keys,
        "Unexpected live classes in $enqueuer\n "
        "Expected: ${expectedLiveMap.keys}\n "
        "Actual  : ${actualLiveMap.keys}");
    expectedLiveMap.forEach((String clsName, List<String> expectedMembers) {
      List<String> actualMembers = actualLiveMap[clsName];
      Expect.setEquals(
          expectedMembers,
          actualMembers,
          "Unexpected live members for $clsName in $enqueuer\n "
          "Expected: $expectedMembers\n "
          "Actual  : $actualMembers");
    });
  }

  compiler.onResolutionQueueEmptyForTesting = () {
    Enqueuer enqueuer = compiler.enqueuer.resolutionEnqueuerForTesting;
    ElementEnvironment elementEnvironment =
        compiler.frontendStrategy.elementEnvironment;
    checkInvariant(enqueuer, elementEnvironment);

    Object createConstraint(ClassEntity cls) {
      return new StrongModeConstraint(compiler.frontendStrategy.commonElements,
          compiler.frontendStrategy.nativeBasicData, cls);
    }

    for (Impact impact in impacts) {
      applyImpact(enqueuer, elementEnvironment, impact, createConstraint);
    }
  };
  compiler.onCodegenQueueEmptyForTesting = () {
    Enqueuer enqueuer = compiler.enqueuer.codegenEnqueuerForTesting;
    JClosedWorld closedWorld = compiler.backendClosedWorldForTesting;
    ElementEnvironment elementEnvironment =
        compiler.backendClosedWorldForTesting.elementEnvironment;
    checkInvariant(enqueuer, elementEnvironment);

    Object createConstraint(ClassEntity cls) {
      return new TypeMask.subtype(cls, closedWorld);
    }

    for (Impact impact in impacts) {
      applyImpact(enqueuer, elementEnvironment, impact, createConstraint);
    }
  };

  await compiler.run(Uri.parse('memory:main.dart'));

  checkLiveMembers(
      compiler.enqueuer.resolutionEnqueuerForTesting,
      compiler.frontendStrategy.elementEnvironment,
      test.expectedLiveResolutionMap);

  checkLiveMembers(
      compiler.enqueuer.codegenEnqueuerForTesting,
      compiler.backendClosedWorldForTesting.elementEnvironment,
      test.expectedLiveCodegenMap);
}
