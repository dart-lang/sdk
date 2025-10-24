// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import 'package:args/args.dart';
import 'package:kernel/binary/ast_from_binary.dart'
    show BinaryBuilderWithMetadata;
import 'package:kernel/kernel.dart' show Component, writeComponentToText;
import 'package:vm/metadata/closure_id.dart' show ClosureIdMetadataRepository;
import 'package:vm/metadata/direct_call.dart' show DirectCallMetadataRepository;
import 'package:vm/metadata/inferred_type.dart'
    show InferredTypeMetadataRepository, InferredArgTypeMetadataRepository;
import 'package:vm/metadata/loading_units.dart'
    show LoadingUnitsMetadataRepository;
import 'package:vm/metadata/procedure_attributes.dart'
    show ProcedureAttributesMetadataRepository;
import 'package:vm/metadata/table_selector.dart'
    show TableSelectorMetadataRepository;
import 'package:vm/metadata/unboxing_info.dart'
    show UnboxingInfoMetadataRepository;
import 'package:vm/metadata/unreachable.dart'
    show UnreachableNodeMetadataRepository;
import 'package:vm/modular/metadata/call_site_attributes.dart'
    show CallSiteAttributesMetadataRepository;

final ArgParser _argParser =
    ArgParser()..addFlag('show-offsets', help: 'Print file offsets');

final String _usage = '''
Usage: dump_kernel [options] input.dill output.txt
Dumps kernel binary file with VM-specific metadata.

Options:
${_argParser.usage}
''';

void main(List<String> arguments) async {
  final argResults = _argParser.parse(arguments);
  if (argResults.rest.length != 2) {
    print(_usage);
    exit(1);
  }

  final input = argResults.rest[0];
  final output = argResults.rest[1];

  final component = new Component();

  // Register VM-specific metadata.
  component.addMetadataRepository(new DirectCallMetadataRepository());
  component.addMetadataRepository(new InferredTypeMetadataRepository());
  component.addMetadataRepository(new InferredArgTypeMetadataRepository());
  component.addMetadataRepository(new ProcedureAttributesMetadataRepository());
  component.addMetadataRepository(new TableSelectorMetadataRepository());
  component.addMetadataRepository(new UnboxingInfoMetadataRepository());
  component.addMetadataRepository(new UnreachableNodeMetadataRepository());
  component.addMetadataRepository(new CallSiteAttributesMetadataRepository());
  component.addMetadataRepository(new LoadingUnitsMetadataRepository());
  component.addMetadataRepository(new ClosureIdMetadataRepository());

  final Uint8List bytes = new File(input).readAsBytesSync();
  new BinaryBuilderWithMetadata(bytes).readComponent(component);

  writeComponentToText(
    component,
    path: output,
    showMetadata: true,
    showOffsets: argResults['show-offsets'],
  );
}
