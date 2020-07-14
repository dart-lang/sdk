#!/usr/bin/env dart
// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:front_end/src/api_prototype/constant_evaluator.dart'
    as constants show EvaluationMode, SimpleErrorReporter, transformComponent;

import 'package:args/args.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/src/tool/batch_util.dart';
import 'package:kernel/target/targets.dart';

import 'package:kernel/transformations/continuation.dart' as cont;
import 'package:kernel/transformations/empty.dart' as empty;
import 'package:kernel/transformations/mixin_full_resolution.dart' as mix;
import 'package:kernel/type_environment.dart';
import 'package:kernel/vm/constants_native_effects.dart';

ArgParser parser = new ArgParser()
  ..addOption('format',
      abbr: 'f',
      allowed: ['text', 'bin'],
      defaultsTo: 'bin',
      help: 'Output format.')
  ..addOption('out', abbr: 'o', help: 'Output file.', defaultsTo: null)
  ..addFlag('verbose',
      abbr: 'v',
      negatable: false,
      help: 'Be verbose (e.g. prints transformed main library).',
      defaultsTo: false)
  ..addMultiOption('define', abbr: 'D', splitCommas: false)
  ..addOption('transformation',
      abbr: 't',
      help: 'The transformation to apply.',
      defaultsTo: 'continuation');

main(List<String> arguments) async {
  if (arguments.isNotEmpty && arguments[0] == '--batch') {
    if (arguments.length != 1) {
      throw '--batch cannot be used with other arguments';
    }
    await runBatch((arguments) => runTransformation(arguments));
  } else {
    CompilerOutcome outcome = await runTransformation(arguments);
    exit(outcome == CompilerOutcome.Ok ? 0 : 1);
  }
}

Future<CompilerOutcome> runTransformation(List<String> arguments) async {
  ArgResults options = parser.parse(arguments);

  if (options.rest.length != 1) {
    throw 'Usage:\n${parser.usage}';
  }

  var input = options.rest.first;
  var output = options['out'];
  var format = options['format'];
  var verbose = options['verbose'];

  Map<String, String> defines = <String, String>{};
  for (String define in options['define']) {
    int index = define.indexOf('=');
    String name;
    String expression;
    if (index != -1) {
      name = define.substring(0, index);
      expression = define.substring(index + 1);
    } else {
      name = define;
      expression = define;
    }
    defines[name] = expression;
  }

  if (output == null) {
    output = '${input.substring(0, input.lastIndexOf('.'))}.transformed.dill';
  }

  var component = loadComponentFromBinary(input);

  final coreTypes = new CoreTypes(component);
  final hierarchy = new ClassHierarchy(component, coreTypes);
  final typeEnvironment = new TypeEnvironment(coreTypes, hierarchy);
  switch (options['transformation']) {
    case 'continuation':
      bool productMode = defines["dart.vm.product"] == "true";
      component = cont.transformComponent(typeEnvironment, component,
          productMode: productMode);
      break;
    case 'resolve-mixins':
      mix.transformLibraries(new NoneTarget(null), coreTypes, hierarchy,
          component.libraries, null);
      break;
    case 'constants':
      final VmConstantsBackend backend = new VmConstantsBackend(coreTypes);
      component = constants.transformComponent(component, backend, defines,
          const constants.SimpleErrorReporter(), constants.EvaluationMode.weak,
          desugarSets: false,
          evaluateAnnotations: true,
          enableTripleShift: false,
          errorOnUnevaluatedConstant: false);
      break;
    case 'empty':
      component = empty.transformComponent(component);
      break;
    default:
      throw 'Unknown transformation';
  }

  // TODO(30631): Fix the verifier so we can check that the transform produced
  // valid output.
  //
  // verifyComponent(component);

  if (format == 'text') {
    writeComponentToText(component, path: output);
  } else {
    assert(format == 'bin');
    await writeComponentToBinary(component, output);
  }

  if (verbose) {
    writeLibraryToText(component.mainMethod.parent as Library);
  }

  return CompilerOutcome.Ok;
}
