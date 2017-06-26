// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Partial test that the closed world computed from [WorldImpact]s derived from
// kernel is equivalent to the original computed from resolution.
library dart2js.kernel.compile_from_dill_test;

import 'dart:async';
import 'dart:io';

import 'package:async_helper/async_helper.dart';
import 'package:compiler/compiler_new.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/elements/types.dart';
import 'package:compiler/src/kernel/element_map.dart';
import 'package:compiler/src/kernel/kernel_strategy.dart';
import 'package:compiler/src/serialization/equivalence.dart';
import 'package:compiler/src/resolution/enum_creator.dart';
import 'package:compiler/src/universe/world_builder.dart';
import 'package:compiler/src/world.dart';
import 'package:expect/expect.dart';
import '../memory_compiler.dart';
import '../equivalence/check_functions.dart';
import '../equivalence/check_helpers.dart';
import '../serialization/helper.dart';
import 'test_helpers.dart';

import 'compiler_helper.dart';

const SOURCE = const {
  'main.dart': '''
foo({named}) => 1;
bar(a) => !a;
class Class {
  var field;
  static var staticField;
  Class(this.field);
}
main() {
  foo();
  bar(true);
  [];
  {};
  new Object();
  new Class('');
  Class.staticField;
  var x = null;
  var y1 = x == null;
  var y2 = null == x;
  var z1 = x?.toString();
  var z2 = x ?? y1;
  var z3 = x ??= y2;
  var w = x == null ? null : x.toString();
  for (int i = 0; i < 10; i++) {
    x = i;
    if (i == 5) break;
  }
  print(x);
  return x;
}
'''
};

main(List<String> args) {
  asyncTest(() async {
    await mainInternal(args);
  });
}

enum ResultKind { crashes, errors, warnings, success, failure }

Future<ResultKind> mainInternal(List<String> args,
    {bool skipWarnings: false, bool skipErrors: false}) async {
  Arguments arguments = new Arguments.from(args);
  Uri entryPoint;
  Map<String, String> memorySourceFiles;
  if (arguments.uri != null) {
    entryPoint = arguments.uri;
    memorySourceFiles = const <String, String>{};
  } else {
    entryPoint = Uri.parse('memory:main.dart');
    memorySourceFiles = SOURCE;
  }

  enableDebugMode();
  EnumCreator.matchKernelRepresentationForTesting = true;
  Elements.usePatchedDart2jsSdkSorting = true;

  Directory dir = await Directory.systemTemp.createTemp('dart2js-with-dill');
  print('--- create temp directory $dir -------------------------------');
  memorySourceFiles.forEach((String name, String source) {
    new File.fromUri(dir.uri.resolve(name)).writeAsStringSync(source);
  });
  entryPoint = dir.uri.resolve(entryPoint.path);

  print('---- compile from ast ----------------------------------------------');
  DiagnosticCollector collector = new DiagnosticCollector();
  OutputCollector collector1 = new OutputCollector();
  Compiler compiler1 = compilerFor(
      entryPoint: entryPoint,
      diagnosticHandler: collector,
      outputProvider: collector1,
      options: [
        Flags.disableTypeInference,
        Flags.disableInlining,
        Flags.enableAssertMessage
      ]);
  ElementResolutionWorldBuilder.useInstantiationMap = true;
  compiler1.resolution.retainCachesForTesting = true;
  await compiler1.run(entryPoint);
  if (collector.crashes.isNotEmpty) {
    print('Skipping due to crashes.');
    return ResultKind.crashes;
  }
  if (collector.errors.isNotEmpty && skipErrors) {
    print('Skipping due to errors.');
    return ResultKind.errors;
  }
  if (collector.warnings.isNotEmpty && skipWarnings) {
    print('Skipping due to warnings.');
    return ResultKind.warnings;
  }
  Expect.isFalse(compiler1.compilationFailed);
  ClosedWorld closedWorld1 =
      compiler1.resolutionWorldBuilder.closedWorldForTesting;

  OutputCollector collector2 = new OutputCollector();
  Compiler compiler2 = await compileWithDill(
      entryPoint,
      const {},
      [
        Flags.disableTypeInference,
        Flags.disableInlining,
        Flags.enableAssertMessage
      ],
      printSteps: true,
      compilerOutput: collector2);

  KernelFrontEndStrategy frontendStrategy = compiler2.frontendStrategy;
  KernelToElementMap elementMap = frontendStrategy.elementMap;

  Expect.isFalse(compiler2.compilationFailed);

  KernelEquivalence equivalence = new KernelEquivalence(elementMap);

  ClosedWorld closedWorld2 =
      compiler2.resolutionWorldBuilder.closedWorldForTesting;

  checkBackendUsage(closedWorld1.backendUsage, closedWorld2.backendUsage,
      equivalence.defaultStrategy);

  print('--- checking resolution enqueuers ----------------------------------');
  checkResolutionEnqueuers(closedWorld1.backendUsage, closedWorld2.backendUsage,
      compiler1.enqueuer.resolution, compiler2.enqueuer.resolution,
      elementEquivalence: (a, b) => equivalence.entityEquivalence(a, b),
      typeEquivalence: (DartType a, DartType b) {
        return equivalence.typeEquivalence(unalias(a), b);
      },
      elementFilter: elementFilter,
      verbose: arguments.verbose);

  print('--- checking closed worlds -----------------------------------------');
  checkClosedWorlds(closedWorld1, closedWorld2,
      strategy: equivalence.defaultStrategy,
      verbose: arguments.verbose,
      // TODO(johnniwinther,efortuna): Require closure class equivalence when
      // these are supported.
      allowMissingClosureClasses: true);

  // TODO(johnniwinther): Perform equivalence tests on the model: codegen world
  // impacts, program model, etc.

  print('--- checking codegen enqueuers--------------------------------------');
  checkCodegenEnqueuers(compiler1.enqueuer.codegenEnqueuerForTesting,
      compiler2.enqueuer.codegenEnqueuerForTesting,
      elementEquivalence: (a, b) => equivalence.entityEquivalence(a, b),
      typeEquivalence: (DartType a, DartType b) {
        return equivalence.typeEquivalence(unalias(a), b);
      },
      elementFilter: elementFilter,
      verbose: arguments.verbose);

  checkEmitters(compiler1.backend.emitter, compiler2.backend.emitter,
      elementEquivalence: (a, b) => equivalence.entityEquivalence(a, b),
      typeEquivalence: (DartType a, DartType b) {
        return equivalence.typeEquivalence(unalias(a), b);
      },
      verbose: arguments.verbose);

  print('--- checking output------- -----------------------------------------');
  collector1.outputMap
      .forEach((OutputType outputType, Map<String, BufferedOutputSink> map1) {
    if (outputType == OutputType.sourceMap) {
      // TODO(johnniwinther): Support source map from .dill.
      return;
    }
    Map<String, BufferedOutputSink> map2 = collector2.outputMap[outputType];
    checkSets(map1.keys, map2.keys, 'output', equality);
    map1.forEach((String name, BufferedOutputSink output1) {
      BufferedOutputSink output2 = map2[name];
      Expect.stringEquals(output1.text, output2.text);
    });
  });
  return ResultKind.success;
}
