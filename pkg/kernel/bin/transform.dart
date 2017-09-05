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
import 'package:kernel/target/targets.dart';
import 'package:kernel/transformations/closure_conversion.dart' as closures;
import 'package:kernel/transformations/continuation.dart' as cont;
import 'package:kernel/transformations/empty.dart' as empty;
import 'package:kernel/transformations/method_call.dart' as method_call;
import 'package:kernel/transformations/mixin_full_resolution.dart' as mix;
import 'package:kernel/transformations/treeshaker.dart' as treeshaker;
import 'package:kernel/verifier.dart';
import 'package:kernel/transformations/coq.dart' as coq;

import 'batch_util.dart';
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
  ..addOption('embedder-entry-points-manifest',
      allowMultiple: true,
      help: 'A path to a file describing entrypoints '
          '(lines of the form `<library>,<class>,<member>`).')
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

  if (output == null) {
    output = '${input.substring(0, input.lastIndexOf('.'))}.transformed.dill';
  }

  List<String> embedderEntryPointManifests =
      options['embedder-entry-points-manifest'] as List<String>;
  List<treeshaker.ProgramRoot> programRoots =
      parseProgramRoots(embedderEntryPointManifests);

  var program = loadProgramFromBinary(input);
  var coreTypes = new CoreTypes(program);
  var hierarchy = new ClosedWorldClassHierarchy(program);
  switch (options['transformation']) {
    case 'continuation':
      program = cont.transformProgram(coreTypes, program);
      break;
    case 'resolve-mixins':
      mix.transformLibraries(
          new NoneTarget(null), coreTypes, hierarchy, program.libraries);
      break;
    case 'closures':
      program = closures.transformProgram(coreTypes, program);
      break;
    case 'coq':
      program = coq.transformProgram(coreTypes, program);
      break;
    case 'treeshake':
      program = treeshaker.transformProgram(coreTypes, hierarchy, program,
          programRoots: programRoots);
      break;
    case 'methodcall':
      program = method_call.transformProgram(coreTypes, hierarchy, program);
      break;
    case 'empty':
      program = empty.transformProgram(program);
      break;
    default:
      throw 'Unknown transformation';
  }

  verifyProgram(program);

  if (format == 'text') {
    writeProgramToText(program, path: output);
  } else {
    assert(format == 'bin');
    await writeProgramToBinary(program, output);
  }

  if (verbose) {
    writeLibraryToText(program.mainMethod.parent as Library);
  }

  return CompilerOutcome.Ok;
}
