#!/usr/bin/env dart
// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/args.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/checks.dart' as checks;
import 'package:kernel/transformations/continuation.dart' as cont;

ArgParser parser = new ArgParser()
  ..addOption('format',
      abbr: 'f',
      allowed: ['text', 'bin'],
      defaultsTo: 'bin',
      help: 'Output format.')
  ..addOption('out',
      abbr: 'o',
      help: 'Output file.',
      defaultsTo: null)
  ..addOption('transformation',
      abbr: 't',
      help: 'The transformation to apply.',
      defaultsTo: 'continuation');

main(List<String> args) {
  ArgResults result = parser.parse(args);

  if (result.rest.length != 1) {
    throw "Usage:\n${parser.usage}";
  }

  var input = result.rest.first;
  var output = result['out'];
  var format = result['format'];

  if (output == null) {
    output = '${input.substring(0, input.lastIndexOf('.'))}.transformed.dill';
  }

  var program = loadProgramFromBinary(input);
  switch (result['transformation']) {
    case 'continuation':
      program = cont.tranformProgram(program);
      break;
    default: throw 'Unknown transformation';
  }

  program.accept(new checks.CheckParentPointers());

  if (format == 'text') {
    writeProgramToText(program, output);
  } else {
    assert(format == 'bin');
    writeProgramToBinary(program, output);
  }

  // We always dump the main library to stdout.
  writeLibraryToText(program.mainMethod.parent as Library, null);
}
