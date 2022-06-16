// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/binary/ast_from_binary.dart';
import 'package:kernel/binary/ast_to_binary.dart';
import 'binary/utils.dart';

void main() {
  final Uri lib1Uri = Uri.parse('org-dartlang:///lib.dart');
  final Library lib1 = new Library(lib1Uri, fileUri: lib1Uri);
  final Field field = new Field.mutable(new Name("f"), fileUri: lib1Uri);
  lib1.addField(field);
  final Block libProcedureBody = new Block([
    new ExpressionStatement(new StaticSet(field, new IntLiteral(42))),
    new ReturnStatement(new StaticGet(field)),
  ]);
  final Procedure libProcedure = new Procedure(
      new Name("method"),
      ProcedureKind.Method,
      new FunctionNode(libProcedureBody, returnType: new DynamicType()),
      fileUri: lib1Uri);
  lib1.addProcedure(libProcedure);

  final Uri lib2Uri = Uri.parse('org-dartlang:///lib2.dart');
  final Library lib2 = new Library(lib2Uri, fileUri: lib2Uri);
  final Block lib2ProcedureBody = new Block([
    new ExpressionStatement(new StaticSet(field, new IntLiteral(43))),
    new ReturnStatement(new StaticGet(field)),
  ]);
  final Procedure lib2Procedure = new Procedure(
      new Name("method"),
      ProcedureKind.Method,
      new FunctionNode(lib2ProcedureBody, returnType: new DynamicType()),
      fileUri: lib2Uri);
  lib2.addProcedure(lib2Procedure);

  verifyTargets(libProcedure, lib2Procedure, field, field);
  List<int> writtenBytesFieldOriginal = serialize(lib1, lib2);
  // Canonical names are now set: Verify that the field is marked as such,
  // canonical-name-wise.
  String getterCanonicalName = '${field.getterReference.canonicalName}';
  if (field.getterReference.canonicalName!.parent!.name !=
      CanonicalName.gettersName) {
    throw "Expected ${CanonicalName.gettersName} parent, but had "
        "${field.getterReference.canonicalName!.parent!.name}";
  }
  String setterCanonicalName = '${field.setterReference!.canonicalName}';
  if (field.setterReference!.canonicalName!.parent!.name !=
      CanonicalName.settersName) {
    throw "Expected ${CanonicalName.settersName} parent, but had "
        "${field.setterReference!.canonicalName!.parent!.name}";
  }

  // Replace the field with a setter/getter pair.
  lib1.fields.remove(field);

  // Important: Unbind any old canonical name
  field.fieldReference.canonicalName?.unbind();

  FunctionNode getterFunction = new FunctionNode(new Block([]));
  Procedure getter = new Procedure(
      new Name("f"), ProcedureKind.Getter, getterFunction,
      reference: field.getterReference, fileUri: lib1Uri);
  // Important: Unbind any old canonical name
  // (nulling out the canonical name is not enough because it leaves the old
  // canonical name (which always stays alive) with a pointer to the reference,
  // meaning that if one tried to rebind it (e.g. if going back to a field from
  // a setter/getter), the reference wouldn't (because of the way `bindTo` is
  // implemented) actually have it's canonical name set, and serialization
  // wouldn't work.)
  field.getterReference.canonicalName?.unbind();
  lib1.addProcedure(getter);

  FunctionNode setterFunction = new FunctionNode(new Block([]),
      positionalParameters: [new VariableDeclaration("foo")]);
  Procedure setter = new Procedure(
      new Name("f"), ProcedureKind.Setter, setterFunction,
      reference: field.setterReference, fileUri: lib1Uri);
  // Important: Unbind any old canonical name
  // (nulling out the canonical name is not enough, see above).
  field.setterReference?.canonicalName?.unbind();
  lib1.addProcedure(setter);

  verifyTargets(libProcedure, lib2Procedure, getter, setter);
  List<int> writtenBytesGetterSetter = serialize(lib1, lib2);
  // Canonical names are now set: Verify that the getter/setter is marked as
  // such, canonical-name-wise.
  if (getter.reference.canonicalName!.parent!.name != "@getters") {
    throw "Expected @getters parent, but had "
        "${getter.reference.canonicalName!.parent!.name}";
  }
  if ('${getter.reference.canonicalName}' != getterCanonicalName) {
    throw "Unexpected getter canonical name. "
        "Expected $getterCanonicalName, "
        "actual ${getter.reference.canonicalName}.";
  }
  if (setter.reference.canonicalName!.parent!.name != "@setters") {
    throw "Expected @setters parent, but had "
        "${setter.reference.canonicalName!.parent!.name}";
  }
  if ('${setter.reference.canonicalName}' != setterCanonicalName) {
    throw "Unexpected setter canonical name. "
        "Expected $setterCanonicalName, "
        "actual ${setter.reference.canonicalName}.";
  }

  // Replace getter/setter with field.
  lib1.procedures.remove(getter);
  lib1.procedures.remove(setter);
  final Field fieldReplacement = new Field.mutable(new Name("f"),
      getterReference: getter.reference,
      setterReference: setter.reference,
      fileUri: lib1Uri);
  // Important: Unbind any old canonical name
  // (nulling out the canonical name is not enough, see above).
  fieldReplacement.getterReference.canonicalName?.unbind();
  fieldReplacement.setterReference?.canonicalName?.unbind();
  fieldReplacement.fieldReference.canonicalName?.unbind();
  lib1.addField(fieldReplacement);

  verifyTargets(
      libProcedure, lib2Procedure, fieldReplacement, fieldReplacement);
  List<int> writtenBytesFieldNew = serialize(lib1, lib2);
  // Canonical names are now set: Verify that the field is marked as such,
  // canonical-name-wise.
  if (fieldReplacement.getterReference.canonicalName!.parent!.name !=
      "@getters") {
    throw "Expected @getters parent, but had "
        "${fieldReplacement.getterReference.canonicalName!.parent!.name}";
  }
  if (fieldReplacement.setterReference!.canonicalName!.parent!.name !=
      "@setters") {
    throw "Expected @setters parent, but had "
        "${fieldReplacement.setterReference!.canonicalName!.parent!.name}";
  }

  // Load the written stuff and ensure it is as expected.
  // First one has a field.
  Component componentLoaded = new Component();
  new BinaryBuilder(writtenBytesFieldOriginal)
      .readSingleFileComponent(componentLoaded);
  verifyTargets(
      componentLoaded.libraries[0].procedures.single,
      componentLoaded.libraries[1].procedures.single,
      componentLoaded.libraries[0].fields.single,
      componentLoaded.libraries[0].fields.single);

  // Second one has a getter/setter pair.
  componentLoaded = new Component();
  new BinaryBuilder(writtenBytesGetterSetter)
      .readSingleFileComponent(componentLoaded);
  assert(componentLoaded.libraries[0].procedures[2].isSetter);
  verifyTargets(
      componentLoaded.libraries[0].procedures[0],
      componentLoaded.libraries[1].procedures[0],
      componentLoaded.libraries[0].procedures[1],
      componentLoaded.libraries[0].procedures[2]);

  // Third one has a field again.
  componentLoaded = new Component();
  new BinaryBuilder(writtenBytesFieldNew)
      .readSingleFileComponent(componentLoaded);
  verifyTargets(
      componentLoaded.libraries[0].procedures.single,
      componentLoaded.libraries[1].procedures.single,
      componentLoaded.libraries[0].fields.single,
      componentLoaded.libraries[0].fields.single);
}

void verifyTargets(Procedure libProcedure, Procedure lib2Procedure,
    Member getterTarget, Member setterTarget) {
  if (getGetTarget(libProcedure) != getterTarget) {
    throw "Unexpected get target for lib #1";
  }
  if (getSetTarget(libProcedure) != setterTarget) {
    throw "Unexpected set target for lib #1";
  }
  if (getGetTarget(lib2Procedure) != getterTarget) {
    throw "Unexpected get target for lib #2";
  }
  if (getSetTarget(lib2Procedure) != setterTarget) {
    throw "Unexpected set target for lib #2";
  }
}

List<int> serialize(Library lib1, Library lib2) {
  Component component = new Component(libraries: [lib1, lib2])
    ..setMainMethodAndMode(null, false, NonNullableByDefaultCompiledMode.Weak);
  ByteSink sink = new ByteSink();
  new BinaryPrinter(sink).writeComponentFile(component);
  return sink.builder.takeBytes();
}

Member getSetTarget(Procedure p) {
  Block block = p.function.body as Block;
  ExpressionStatement getterStatement =
      block.statements[0] as ExpressionStatement;
  StaticSet staticSet = getterStatement.expression as StaticSet;
  return staticSet.target;
}

Member getGetTarget(Procedure p) {
  Block block = p.function.body as Block;
  ReturnStatement setterStatement = block.statements[1] as ReturnStatement;
  StaticGet staticGet = setterStatement.expression as StaticGet;
  return staticGet.target;
}
