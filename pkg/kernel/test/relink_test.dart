// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:kernel/binary/ast_from_binary.dart';
import 'package:kernel/binary/ast_to_binary.dart';
import 'package:kernel/src/tool/find_referenced_libraries.dart';
import 'binary/utils.dart';

void main() {
  Component component1 = createComponent(42);
  Component component2 = createComponent(43);

  expectReachable(
      findAllReferencedLibraries(component1.libraries), component1.libraries);
  if (duplicateLibrariesReachable(component1.libraries)) {
    throw "Didn't expect duplicates libraries!";
  }
  expectReachable(
      findAllReferencedLibraries(component2.libraries), component2.libraries);
  if (duplicateLibrariesReachable(component2.libraries)) {
    throw "Didn't expect duplicates libraries!";
  }

  ByteSink sink = new ByteSink();
  new BinaryPrinter(sink).writeComponentFile(component1);
  Uint8List writtenBytes1 = sink.builder.takeBytes();
  sink = new ByteSink();
  new BinaryPrinter(sink).writeComponentFile(component2);
  Uint8List writtenBytes2 = sink.builder.takeBytes();

  // Loading a single one works as one would expect: It's linked to itself.
  Component component1Prime = new Component();
  new BinaryBuilder(writtenBytes1).readSingleFileComponent(component1Prime);
  Procedure target1 = getMainTarget(component1Prime);
  Procedure procedureLib1 = getLibProcedure(component1Prime);
  if (target1 != procedureLib1) throw "Unexpected target.";
  expectReachable(findAllReferencedLibraries(component1Prime.libraries),
      component1Prime.libraries);
  if (duplicateLibrariesReachable(component1Prime.libraries)) {
    throw "Didn't expect duplicates libraries!";
  }

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
  expectReachable(findAllReferencedLibraries(component2Prime.libraries),
      component2Prime.libraries);
  if (duplicateLibrariesReachable(component2Prime.libraries)) {
    throw "Didn't expect duplicates libraries!";
  }

  // The old one that was loaded on top of was re-linked so it also points to
  // procedureLib2.
  target1 = getMainTarget(component1Prime);
  if (target1 != procedureLib2) throw "Unexpected target.";

  // Relink back and forth a number of times: It keeps working as expected.
  for (int i = 0; i < 6; i++) {
    // Before the relink the lib from component2Prime is also reachable!
    expectReachable(
        findAllReferencedLibraries(component1Prime.libraries),
        []
          ..addAll(component1Prime.libraries)
          ..add(procedureLib2.enclosingLibrary));
    if (!duplicateLibrariesReachable(component1Prime.libraries)) {
      throw "Expected duplicates libraries!";
    }

    // Relinking component1Prime works as one would expected: Both components
    // main now points to procedureLib1.
    component1Prime.relink();
    // After the relink only the libs from component1Prime are reachable!
    expectReachable(findAllReferencedLibraries(component1Prime.libraries),
        component1Prime.libraries);
    expectReachable(
        findAllReferencedLibraries(component1Prime.libraries,
            collectViaReferencesToo: true),
        component1Prime.libraries);
    if (duplicateLibrariesReachable(component1Prime.libraries)) {
      throw "Didn't expect duplicates libraries!";
    }
    target1 = getMainTarget(component1Prime);
    if (target1 != procedureLib1) throw "Unexpected target.";
    target2 = getMainTarget(component2Prime);
    if (target2 != procedureLib1) throw "Unexpected target.";

    // Before the relink the lib from component1Prime is also reachable!
    expectReachable(
        findAllReferencedLibraries(component2Prime.libraries),
        []
          ..addAll(component2Prime.libraries)
          ..add(procedureLib1.enclosingLibrary));
    if (!duplicateLibrariesReachable(component2Prime.libraries)) {
      throw "Expected duplicates libraries!";
    }
    // Relinking component2Prime works as one would expected: Both components
    // main now points to procedureLib2.
    component2Prime.relink();
    // After the relink only the libs from component1Prime are reachable!
    expectReachable(findAllReferencedLibraries(component2Prime.libraries),
        component2Prime.libraries);
    expectReachable(
        findAllReferencedLibraries(component2Prime.libraries,
            collectViaReferencesToo: true),
        component2Prime.libraries);
    if (duplicateLibrariesReachable(component2Prime.libraries)) {
      throw "Didn't expect duplicates libraries!";
    }
    target1 = getMainTarget(component1Prime);
    if (target1 != procedureLib2) throw "Unexpected target.";
    target2 = getMainTarget(component2Prime);
    if (target2 != procedureLib2) throw "Unexpected target.";
  }
}

void expectReachable(
    Set<Library> findAllReferencedLibraries, List<Library> libraries) {
  Set<Library> onlyInReferenced = findAllReferencedLibraries.toSet()
    ..removeAll(libraries);
  Set<Library> onlyInLibraries = libraries.toSet()
    ..removeAll(findAllReferencedLibraries);
  if (onlyInReferenced.isNotEmpty || onlyInLibraries.isNotEmpty) {
    throw "Expected to be the same, but ${onlyInReferenced} was only in "
        "reachable and ${onlyInLibraries} was only in libraries";
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
  Block block =
      component1Prime.libraries[0].procedures[0].function.body as Block;
  ReturnStatement returnStatement = block.statements[0] as ReturnStatement;
  StaticInvocation staticInvocation =
      returnStatement.expression as StaticInvocation;
  Procedure target = staticInvocation.target;
  return target;
}

Component createComponent(int literal) {
  final Uri libUri = Uri.parse('org-dartlang:///lib.dart');
  final Library lib = new Library(libUri, fileUri: libUri);
  final Block libProcedureBody =
      new Block([new ReturnStatement(new IntLiteral(literal))]);
  final Procedure libProcedure = new Procedure(
      new Name("method"),
      ProcedureKind.Method,
      new FunctionNode(libProcedureBody, returnType: new DynamicType()),
      fileUri: libUri);
  lib.addProcedure(libProcedure);

  ExtensionTypeDeclaration extensionTypeDeclaration =
      new ExtensionTypeDeclaration(name: "Foo", fileUri: libUri);
  extensionTypeDeclaration.declaredRepresentationType = DynamicType();
  extensionTypeDeclaration.representationName = "extensionTypeMethod";
  final Block extensionTypeProcedureBody =
      new Block([new ReturnStatement(new IntLiteral(literal))]);
  final Procedure extensionTypeProcedure = new Procedure(
      new Name("extensionTypeMethod"),
      ProcedureKind.Method,
      new FunctionNode(extensionTypeProcedureBody,
          returnType: new DynamicType()),
      fileUri: libUri);
  extensionTypeDeclaration.addProcedure(extensionTypeProcedure);
  lib.addExtensionTypeDeclaration(extensionTypeDeclaration);

  final Uri mainUri = Uri.parse('org-dartlang:///main.dart');
  final Library main = new Library(mainUri, fileUri: mainUri);
  final Block mainProcedureBody = new Block([
    new ReturnStatement(
        new StaticInvocation(libProcedure, new Arguments.empty()))
  ]);
  final Procedure mainProcedure = new Procedure(
      new Name("method"),
      ProcedureKind.Method,
      new FunctionNode(mainProcedureBody, returnType: new DynamicType()),
      fileUri: mainUri);
  main.addProcedure(mainProcedure);
  return new Component(libraries: [main, lib])
    ..setMainMethodAndMode(
        null, false, NonNullableByDefaultCompiledMode.Strong);
}
