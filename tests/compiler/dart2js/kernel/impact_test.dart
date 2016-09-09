// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.kernel.impact_test;

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/common/resolution.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/ssa/kernel_impact.dart';
import 'package:compiler/src/serialization/equivalence.dart';
import '../memory_compiler.dart';
import '../serialization/test_helper.dart';

const Map<String, String> SOURCE = const <String, String>{
  'main.dart': '''
main() {
  testEmpty();
  testNull();
  testTrue();
  testFalse();
  testInt();
  testDouble();
  testString();
  testSymbol();
  testEmptyListLiteral();
  testEmptyListLiteralDynamic();
  testEmptyListLiteralTyped();
  testEmptyListLiteralConstant();
  testNonEmptyListLiteral();
  testEmptyMapLiteral();
  testEmptyMapLiteralDynamic();
  testEmptyMapLiteralTyped();
  testEmptyMapLiteralConstant();
  testNonEmptyMapLiteral();
  testNot();
  testUnaryMinus();
  testIfThen();
  testIfThenElse();
}

testEmpty() {}
testNull() => null;
testTrue() => true;
testFalse() => false;
testInt() => 42;
testDouble() => 37.5;
testString() => 'foo';
testSymbol() => #main;
testEmptyListLiteral() => [];
testEmptyListLiteralDynamic() => <dynamic>[];
testEmptyListLiteralTyped() => <String>[];
testEmptyListLiteralConstant() => const [];
testNonEmptyListLiteral() => [0];
testEmptyMapLiteral() => {};
testEmptyMapLiteralDynamic() => <dynamic, dynamic>{};
testEmptyMapLiteralTyped() => <String, int>{};
testEmptyMapLiteralConstant() => const {};
testNonEmptyMapLiteral() => {0: true};
testNot() => !false;
testUnaryMinus() => -1;
testIfThen() {
  if (false) return 42;
  return 1;
}
testIfThenElse() {
  if (true) {
    return 42;
  } else {
    return 1;
  }
}
'''
};

main(List<String> args) {
  asyncTest(() async {
    enableDebugMode();
    Uri entryPoint = Uri.parse('memory:main.dart');
    Compiler compiler = compilerFor(
        entryPoint: entryPoint,
        memorySourceFiles: SOURCE,
        options: [Flags.analyzeOnly]);
    compiler.resolution.retainCachesForTesting = true;
    await compiler.run(entryPoint);
    compiler.mainApp.forEachLocalMember(
        (element) => checkElement(compiler, element));
  });
}

void checkElement(Compiler compiler, AstElement element) {
  ResolutionImpact astImpact =
      compiler.resolution.getResolutionImpact(element);
  ResolutionImpact kernelImpact = build(compiler, element.resolvedAst);
  testResolutionImpactEquivalence(astImpact, kernelImpact,
      const CheckStrategy());
}
