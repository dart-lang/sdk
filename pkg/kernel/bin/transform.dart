#!/usr/bin/env dart
// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/src/tool/batch_util.dart';
import 'package:kernel/target/targets.dart';
import 'package:kernel/transformations/closure_conversion.dart' as closures;
import 'package:kernel/transformations/constants.dart' as constants;
import 'package:kernel/transformations/continuation.dart' as cont;
import 'package:kernel/transformations/empty.dart' as empty;
import 'package:kernel/transformations/method_call.dart' as method_call;
import 'package:kernel/transformations/mixin_full_resolution.dart' as mix;
import 'package:kernel/transformations/treeshaker.dart' as treeshaker;
// import 'package:kernel/verifier.dart';
import 'package:kernel/transformations/coq.dart' as coq;
import 'package:kernel/vm/constants_native_effects.dart';

import 'util.dart';

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
  ..addMultiOption('embedder-entry-points-manifest',
      help: 'A path to a file describing entrypoints '
          '(lines of the form `<library>,<class>,<member>`).')
  ..addOption('transformation',
      abbr: 't',
      help: 'The transformation to apply.',
      defaultsTo: 'continuation')
  ..addFlag('sync-async',
      help: 'Whether `async` functions start synchronously.',
      defaultsTo: false);

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
  var syncAsync = options['sync-async'];

  if (output == null) {
    output = '${input.substring(0, input.lastIndexOf('.'))}.transformed.dill';
  }

  List<String> embedderEntryPointManifests =
      options['embedder-entry-points-manifest'] as List<String>;
  List<treeshaker.ProgramRoot> programRoots =
      parseProgramRoots(embedderEntryPointManifests);

  var component = loadComponentFromBinary(input);

  final coreTypes = new CoreTypes(component);
  final hierarchy = new ClassHierarchy(component);
  switch (options['transformation']) {
    case 'continuation':
      component = cont.transformComponent(coreTypes, component, syncAsync);
      break;
    case 'resolve-mixins':
      mix.transformLibraries(
          new NoneTarget(null), coreTypes, hierarchy, component.libraries);
      break;
    case 'closures':
      component = closures.transformComponent(coreTypes, component);
      break;
    case 'coq':
      component = coq.transformComponent(coreTypes, component);
      break;
    case 'constants':
      // We use the -D defines supplied to this VM instead of explicitly using a
      // constructed map of constants.
      final Map<String, String> defines = null;
      final VmConstantsBackend backend =
          new VmConstantsBackend(defines, coreTypes);
      component = constants.transformComponent(component, backend);
      break;
    case 'treeshake':
      component = treeshaker.transformComponent(coreTypes, hierarchy, component,
          programRoots: programRoots);
      break;
    case 'methodcall':
      component =
          method_call.transformComponent(coreTypes, hierarchy, component);
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
