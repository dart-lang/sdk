// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:kernel/ast.dart';
import 'package:kernel/binary/ast_from_binary.dart';
import 'package:kernel/binary/ast_to_binary.dart';

main() {
  Component component1 = createComponent(42);
  Component component2 = createComponent(43);

  ByteSink sink = new ByteSink();
  new BinaryPrinter(sink).writeComponentFile(component1);
  List<int> writtenBytes1 = sink.builder.takeBytes();
  sink = new ByteSink();
  new BinaryPrinter(sink).writeComponentFile(component2);
  List<int> writtenBytes2 = sink.builder.takeBytes();

  // Loading a single one works as one would expect: It's linked to itself.
  Component component1Prime = new Component();
  new BinaryBuilder(writtenBytes1).readSingleFileComponent(component1Prime);
  Procedure target1 = getMainTarget(component1Prime);
  Procedure procedureLib1 = getLibProcedure(component1Prime);
  if (target1 != procedureLib1) throw "Unexpected target.";

  // Loading another one saying it should overwrite works as one would expect
  // for this component: It gives a component that is linked to itself that is
  // different from the one loaded "on top of".
  Component component2Prime = new Component(nameRoot: component1Prime.root);
  new BinaryBuilder(writtenBytes2, alwaysCreateNewNamedNodes: true)
      .readSingleFileComponent(component2Prime);
  Procedure target2 = getMainTarget(component2Prime);
  Procedure procedureLib2 = getLibProcedure(component2Prime);
  if (procedureLib2 == procedureLib1) throw "Unexpected procedure.";
  if (target2 != procedureLib2) throw "Unexpected target.";

  // The old one that was loaded on top of was re-linked so it also points to
  // procedureLib2.
  target1 = getMainTarget(component1Prime);
  if (target1 != procedureLib2) throw "Unexpected target.";

  // Relink back and forth a number of times: It keeps working as expected.
  for (int i = 0; i < 6; i++) {
    // Relinking component1Prime works as one would expected: Both components
    // main now points to procedureLib1.
    component1Prime.relink();
    target1 = getMainTarget(component1Prime);
    if (target1 != procedureLib1) throw "Unexpected target.";
    target2 = getMainTarget(component2Prime);
    if (target2 != procedureLib1) throw "Unexpected target.";

    // Relinking component2Prime works as one would expected: Both components
    // main now points to procedureLib2.
    component2Prime.relink();
    target1 = getMainTarget(component1Prime);
    if (target1 != procedureLib2) throw "Unexpected target.";
    target2 = getMainTarget(component2Prime);
    if (target2 != procedureLib2) throw "Unexpected target.";
  }
}

Procedure getLibProcedure(Component component1Prime) {
  if (component1Prime.libraries[1].importUri !=
      Uri.parse('org-dartlang:///lib.dart')) {
    throw "Expected lib second, got ${component1Prime.libraries[1].importUri}";
  }
  Procedure procedureLib = component1Prime.libraries[1].procedures[0];
  return procedureLib;
}

Procedure getMainTarget(Component component1Prime) {
  if (component1Prime.libraries[0].importUri !=
      Uri.parse('org-dartlang:///main.dart')) {
    throw "Expected main first, got ${component1Prime.libraries[0].importUri}";
  }
  Block block = component1Prime.libraries[0].procedures[0].function.body;
  ReturnStatement returnStatement = block.statements[0];
  StaticInvocation staticInvocation = returnStatement.expression;
  Procedure target = staticInvocation.target;
  return target;
}

Component createComponent(int literal) {
  final Library lib = new Library(Uri.parse('org-dartlang:///lib.dart'));
  final Block libProcedureBody =
      new Block([new ReturnStatement(new IntLiteral(literal))]);
  final Procedure libProcedure = new Procedure(
      new Name("method"),
      ProcedureKind.Method,
      new FunctionNode(libProcedureBody, returnType: new DynamicType()));
  lib.addProcedure(libProcedure);

  final Library main = new Library(Uri.parse('org-dartlang:///main.dart'));
  final Block mainProcedureBody = new Block([
    new ReturnStatement(
        new StaticInvocation(libProcedure, new Arguments.empty()))
  ]);
  final Procedure mainProcedure = new Procedure(
      new Name("method"),
      ProcedureKind.Method,
      new FunctionNode(mainProcedureBody, returnType: new DynamicType()));
  main.addProcedure(mainProcedure);
  return new Component(libraries: [main, lib])
    ..setMainMethodAndMode(null, false, NonNullableByDefaultCompiledMode.Weak);
}

/// A [Sink] that directly writes data into a byte builder.
class ByteSink implements Sink<List<int>> {
  final BytesBuilder builder = new BytesBuilder();

  void add(List<int> data) {
    builder.add(data);
  }

  void close() {}
}
