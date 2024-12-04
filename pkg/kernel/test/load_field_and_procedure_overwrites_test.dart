// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:kernel/binary/ast_from_binary.dart';
import 'package:kernel/binary/ast_to_binary.dart';
import 'binary/utils.dart';

void main() {
  final Uri libUri = Uri.parse('org-dartlang:///lib.dart');

  Uint8List writtenBytesField;
  {
    Library lib = new Library(libUri, fileUri: libUri);
    final Field field =
        new Field.immutable(new Name("myGetter"), fileUri: libUri);
    lib.addField(field);

    writtenBytesField = serialize(lib);
  }
  Uint8List writtenBytesProcedure;
  {
    Library lib = new Library(libUri, fileUri: libUri);
    final Block libProcedureBody = new Block([]);
    final Procedure procedure = new Procedure(
        new Name("myGetter"),
        ProcedureKind.Getter,
        new FunctionNode(libProcedureBody, returnType: new DynamicType()),
        fileUri: libUri);
    lib.addProcedure(procedure);
    writtenBytesProcedure = serialize(lib);
  }

  CanonicalName nameRoot = new CanonicalName.root();

  for (int i = 0; i < 4; i++) {
    // Load field version "on top of" (meant to replace old one if any).
    Component componentWithField = new Component(nameRoot: nameRoot);
    new BinaryBuilder(writtenBytesField,
            disableLazyReading: false, alwaysCreateNewNamedNodes: true)
        .readComponent(componentWithField);
    expect(componentWithField.libraries.single.members.single is Field, true);

    // Load procedure version "on top of" (meant to replace old one if any).
    Component componentWithProcedure = new Component(nameRoot: nameRoot);
    new BinaryBuilder(writtenBytesProcedure,
            disableLazyReading: false, alwaysCreateNewNamedNodes: true)
        .readComponent(componentWithProcedure);
    expect(componentWithProcedure.libraries.single.members.single is Procedure,
        true);
  }
}

void expect(dynamic actual, dynamic expected) {
  if (actual != expected) {
    throw "Expected '$expected' but got '$actual'";
  }
}

Uint8List serialize(Library lib1) {
  Component component = new Component(libraries: [lib1])
    ..setMainMethodAndMode(
        null, false, NonNullableByDefaultCompiledMode.Strong);
  ByteSink sink = new ByteSink();
  new BinaryPrinter(sink).writeComponentFile(component);
  return sink.builder.takeBytes();
}
