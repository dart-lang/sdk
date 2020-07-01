// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/elements/types.dart';
import 'package:compiler/src/world.dart';
import 'package:compiler/src/universe/use.dart';
import 'package:compiler/src/universe/world_impact.dart';
import '../helpers/memory_compiler.dart';

main() {
  asyncTest(() async {
    await runTest();
  });
}

runTest() async {
  String source = '''
class A {}
class B {}

int method1() => 0;
int method2(dynamic o) => o;
method3(int i) {}
int method4(dynamic o) => o as int;
void method5() {}
method6() => [];
method7() => [0];
method8() => <int>[0];
method9(dynamic o) => <int>[o];
method10() => {};
method11() => {0: ''};
method12() => <int, String>{0: ''};
method13(dynamic k, String v) => <int, String>{k: v};

main() {
  method1();
  method2(null);
  method3(0);
  method4(0);
  method5();
  method6();
  method7();
  method8();
  method9(0);
  method10();
  method11();
  method12();
  method13(0, '');
}
''';

  Map<String, Impact> expectedImpactMap = <String, Impact>{
    'method1': const Impact(),
    'method2': new Impact(implicitCasts: ['int*']),
    'method3': new Impact(parameterChecks: ['int*']),
    'method4': new Impact(asCasts: ['int*']),
    'method5': const Impact(),
    'method6': const Impact(),
    'method7': const Impact(),
    'method8': const Impact(),
    'method9': new Impact(implicitCasts: ['int*']),
    'method10': const Impact(),
    'method11': const Impact(),
    'method12': const Impact(),
    'method13':
        new Impact(implicitCasts: ['int*'], parameterChecks: ['String*']),
  };

  retainDataForTesting = true;
  CompilationResult result = await runCompiler(
      memorySourceFiles: {'main.dart': source},
      options: [Flags.printLegacyStars]);
  Expect.isTrue(result.isSuccess);
  Compiler compiler = result.compiler;
  var options = compiler.options;

  KClosedWorld closedWorld = compiler.frontendClosedWorldForTesting;
  DartTypes types = closedWorld.dartTypes;
  ElementEnvironment elementEnvironment = closedWorld.elementEnvironment;

  String printType(DartType type) {
    return type.toStructuredText(types, options);
  }

  elementEnvironment.forEachLibraryMember(elementEnvironment.mainLibrary,
      (MemberEntity member) {
    if (member == elementEnvironment.mainFunction) return;

    Impact expectedImpact = expectedImpactMap[member.name];
    Expect.isNotNull(expectedImpact, "Not expected impact for $member");
    WorldImpact actualImpact = compiler.impactCache[member];

    Set<TypeUse> typeUses = actualImpact.typeUses.toSet();

    Set<String> asCasts = expectedImpact.asCasts.toSet();
    Set<String> checkedModeChecks = expectedImpact.checkedModeChecks.toSet();
    Set<String> implicitCasts = expectedImpact.implicitCasts.toSet();
    Set<String> parameterChecks = expectedImpact.parameterChecks.toSet();

    String context = 'in $member:\n'
        'Expected: $expectedImpact\nActual: $typeUses';
    for (TypeUse typeUse in typeUses) {
      String type = printType(typeUse.type);
      switch (typeUse.kind) {
        case TypeUseKind.AS_CAST:
          Expect.isTrue(asCasts.contains(type), "Extra $typeUse $context");
          asCasts.remove(type);
          break;
        case TypeUseKind.IMPLICIT_CAST:
          Expect.isTrue(
              implicitCasts.contains(type), "Extra $typeUse $context");
          implicitCasts.remove(type);
          break;
        case TypeUseKind.PARAMETER_CHECK:
          Expect.isTrue(
              parameterChecks.contains(type), "Extra $typeUse $context");
          parameterChecks.remove(type);
          break;
        default:
      }
    }
    Expect.isTrue(asCasts.isEmpty, "Missing as casts $asCasts $context");
    Expect.isTrue(checkedModeChecks.isEmpty,
        "Missing checked mode checks $checkedModeChecks $context");
  });
}

class Impact {
  final List<String> checkedModeChecks;
  final List<String> asCasts;
  final List<String> implicitCasts;
  final List<String> parameterChecks;

  const Impact(
      {this.checkedModeChecks: const <String>[],
      this.asCasts: const <String>[],
      this.implicitCasts: const <String>[],
      this.parameterChecks: const <String>[]});

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('Impact(');
    String comma = '';
    if (checkedModeChecks.isNotEmpty) {
      sb.write('checkedModeChecks=');
      sb.write(checkedModeChecks.join(','));
      comma = ',';
    }
    if (asCasts.isNotEmpty) {
      sb.write(comma);
      sb.write('asCasts=');
      sb.write(asCasts.join(','));
      comma = ',';
    }
    if (implicitCasts.isNotEmpty) {
      sb.write(comma);
      sb.write('syntheticCasts=');
      sb.write(implicitCasts.join(','));
      comma = ',';
    }
    if (parameterChecks.isNotEmpty) {
      sb.write(comma);
      sb.write('parameterChecks=');
      sb.write(parameterChecks.join(','));
      comma = ',';
    }
    sb.write(')');
    return sb.toString();
  }
}
