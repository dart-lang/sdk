#!/usr/bin/env dart
// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/checks.dart' as checks;
import 'package:kernel/transformations/continuation.dart' as cont;
import 'package:kernel/transformations/infer_values.dart' as infer_values;
import 'package:kernel/transformations/mixin_full_resolution.dart' as mix;
import 'package:kernel/transformations/treeshaker.dart' as treeshaker;

import 'batch_util.dart';

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

  var program = loadProgramFromBinary(input);
  switch (options['transformation']) {
    case 'continuation':
      program = cont.transformProgram(program);
      break;
    case 'infervalues':
      program = infer_values.transformProgram(program);
      break;
    case 'resolve-mixins':
      program = mix.transformProgram(program);
      break;
    case 'treeshake':
      program = treeshaker.transformProgram(program);
      break;
    default:
      throw 'Unknown transformation';
  }

  program.accept(new checks.CheckParentPointers());

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
