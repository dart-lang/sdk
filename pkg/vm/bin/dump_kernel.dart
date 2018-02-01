// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:kernel/kernel.dart' show Program, writeProgramToText;
import 'package:kernel/binary/ast_from_binary.dart'
    show BinaryBuilderWithMetadata;

import 'package:vm/metadata/direct_call.dart' show DirectCallMetadataRepository;
import 'package:vm/metadata/inferred_type.dart'
    show InferredTypeMetadataRepository;

final String _usage = '''
Usage: dump_kernel input.dill output.txt
Dumps kernel binary file with VM-specific metadata.
''';

main(List<String> arguments) async {
  if (arguments.length != 2) {
    print(_usage);
    exit(1);
  }

  final input = arguments[0];
  final output = arguments[1];

  final program = new Program();

  // Register VM-specific metadata.
  program.addMetadataRepository(new DirectCallMetadataRepository());
  program.addMetadataRepository(new InferredTypeMetadataRepository());

  final List<int> bytes = new File(input).readAsBytesSync();
  new BinaryBuilderWithMetadata(bytes).readProgram(program);

  writeProgramToText(program, path: output, showMetadata: true);
}
