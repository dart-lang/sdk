// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/// TODO(johnniwinther): Move this test to the codegen folder.

import "package:async_helper/async_helper.dart";
import "package:compiler/src/commandline_options.dart";
import "package:compiler/src/common_elements.dart";
import "package:compiler/src/compiler.dart";
import "package:compiler/src/constants/values.dart";
import "package:compiler/src/elements/entities.dart";
import "package:compiler/src/inferrer/abstract_value_domain.dart";
import "package:compiler/src/inferrer/types.dart";
import 'package:compiler/src/inferrer/typemasks/masks.dart';
import 'package:compiler/src/js_model/js_strategy.dart';
import "package:compiler/src/world.dart";
import "package:expect/expect.dart";
import '../helpers/memory_compiler.dart';

import 'dart:async';

const String TEST1 = r"""
foo(x) {
  return x;
}

bar(x) {
  if (x) {
    print("aaa");
  } else {
    print("bbb");
  }
}

main() {
  bar(foo(false));
  bar(foo(foo(false)));
}
""";

Future runTest1() async {
  CompilationResult result = await runCompiler(
      memorySourceFiles: {'main.dart': TEST1},
      options: [Flags.disableInlining]);
  Compiler compiler = result.compiler;
  JsBackendStrategy backendStrategy = compiler.backendStrategy;
  GlobalTypeInferenceResults results =
      compiler.globalInference.resultsForTesting;
  JClosedWorld closedWorld = results.closedWorld;
  JElementEnvironment elementEnvironment = closedWorld.elementEnvironment;
  AbstractValueDomain commonMasks = closedWorld.abstractValueDomain;
  MemberEntity element = elementEnvironment.lookupLibraryMember(
      elementEnvironment.mainLibrary, 'foo');
  AbstractValue mask = results.resultOfMember(element).returnType;
  AbstractValue falseType =
      new ValueTypeMask(commonMasks.boolType, new FalseConstantValue());
  // 'foo' should always return false
  Expect.equals(falseType, mask);
  // the argument to 'bar' is always false
  MemberEntity bar = elementEnvironment.lookupLibraryMember(
      elementEnvironment.mainLibrary, 'bar');
  elementEnvironment.forEachParameterAsLocal(closedWorld.globalLocalsMap, bar,
      (barArg) {
    AbstractValue barArgMask = results.resultOfParameter(barArg);
    Expect.equals(falseType, barArgMask);
  });
  String barCode = backendStrategy.getGeneratedCodeForTesting(bar);
  Expect.isTrue(barCode.contains('"bbb"'));
  Expect.isFalse(barCode.contains('"aaa"'));
}

const String TEST2 = r"""
foo(x) {
  if (x > 3) return true;
  return false;
}

bar(x) {
  if (x) {
    print("aaa");
  } else {
    print("bbb");
  }
}

main() {
  bar(foo(5));
  bar(foo(6));
}
""";

Future runTest2() async {
  CompilationResult result = await runCompiler(
      memorySourceFiles: {'main.dart': TEST2},
      options: [Flags.disableInlining]);
  Compiler compiler = result.compiler;
  JsBackendStrategy backendStrategy = compiler.backendStrategy;
  GlobalTypeInferenceResults results =
      compiler.globalInference.resultsForTesting;
  JClosedWorld closedWorld = results.closedWorld;
  AbstractValueDomain commonMasks = closedWorld.abstractValueDomain;
  JElementEnvironment elementEnvironment = closedWorld.elementEnvironment;
  MemberEntity element = elementEnvironment.lookupLibraryMember(
      elementEnvironment.mainLibrary, 'foo');
  AbstractValue mask = results.resultOfMember(element).returnType;
  // Can't infer value for foo's return type, it could be either true or false
  Expect.identical(commonMasks.boolType, mask);
  MemberEntity bar = elementEnvironment.lookupLibraryMember(
      elementEnvironment.mainLibrary, 'bar');
  elementEnvironment.forEachParameterAsLocal(closedWorld.globalLocalsMap, bar,
      (barArg) {
    AbstractValue barArgMask = results.resultOfParameter(barArg);
    // The argument to bar should have the same type as the return type of foo
    Expect.identical(commonMasks.boolType, barArgMask);
  });
  String barCode = backendStrategy.getGeneratedCodeForTesting(bar);
  Expect.isTrue(barCode.contains('"bbb"'));
  // Still must output the print for "aaa"
  Expect.isTrue(barCode.contains('"aaa"'));
}

main() {
  asyncTest(() async {
    ;
    await runTest1();
    await runTest2();
  });
}
