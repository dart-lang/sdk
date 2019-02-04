// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:kernel/kernel.dart' show Component, writeComponentToText;
import 'package:kernel/binary/ast_from_binary.dart'
    show BinaryBuilderWithMetadata;

import 'package:vm/metadata/bytecode.dart' show BytecodeMetadataRepository;
import 'package:vm/metadata/direct_call.dart' show DirectCallMetadataRepository;
import 'package:vm/metadata/inferred_type.dart'
    show InferredTypeMetadataRepository;
import 'package:vm/metadata/procedure_attributes.dart'
    show ProcedureAttributesMetadataRepository;
import 'package:vm/metadata/unreachable.dart'
    show UnreachableNodeMetadataRepository;
import 'package:vm/metadata/call_site_attributes.dart'
    show CallSiteAttributesMetadataRepository;

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

  final component = new Component();

  // Register VM-specific metadata.
  component.addMetadataRepository(new DirectCallMetadataRepository());
  component.addMetadataRepository(new InferredTypeMetadataRepository());
  component.addMetadataRepository(new ProcedureAttributesMetadataRepository());
  component.addMetadataRepository(new UnreachableNodeMetadataRepository());
  component.addMetadataRepository(new BytecodeMetadataRepository());
  component.addMetadataRepository(new CallSiteAttributesMetadataRepository());

  final List<int> bytes = new File(input).readAsBytesSync();
  new BinaryBuilderWithMetadata(bytes).readComponent(component);

  writeComponentToText(component,
      path: output, showExternal: true, showMetadata: true);
}
