// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show BytesBuilder, File, IOSink;

import 'dart:typed_data' show Uint8List;

import 'package:kernel/clone.dart' show CloneVisitorWithMembers;

import 'package:kernel/ast.dart'
    show
        Class,
        Component,
        DartType,
        Library,
        Procedure,
        Supertype,
        TreeNode,
        TypeParameter,
        TypeParameterType;

import 'package:kernel/binary/ast_to_binary.dart' show BinaryPrinter;

import 'package:kernel/text/ast_to_text.dart' show Printer;

/// Print the given [component].  Do nothing if it is `null`.  If the
/// [libraryFilter] is provided, then only libraries that satisfy it are
/// printed.
void printComponentText(Component component,
    {bool libraryFilter(Library library)}) {
  if (component == null) return;
  StringBuffer sb = new StringBuffer();
  Printer printer = new Printer(sb);
  printer.writeComponentProblems(component);
  for (Library library in component.libraries) {
    if (libraryFilter != null && !libraryFilter(library)) continue;
    printer.writeLibraryFile(library);
  }
  printer.writeConstantTable(component);
  print(sb);
}

/// Write [component] to file only including libraries that match [filter].
Future<Null> writeComponentToFile(Component component, Uri uri,
    {bool filter(Library library)}) async {
  File output = new File.fromUri(uri);
  IOSink sink = output.openWrite();
  try {
    BinaryPrinter printer = new BinaryPrinter(sink, libraryFilter: filter);
    printer.writeComponentFile(component);
  } finally {
    await sink.close();
  }
}

/// Serialize the libraries in [component] that match [filter].
Uint8List serializeComponent(Component component,
    {bool filter(Library library),
    bool includeSources: true,
    bool includeOffsets: true}) {
  ByteSink byteSink = new ByteSink();
  BinaryPrinter printer = new BinaryPrinter(byteSink,
      libraryFilter: filter,
      includeSources: includeSources,
      includeOffsets: includeOffsets);
  printer.writeComponentFile(component);
  return byteSink.builder.takeBytes();
}

const String kDebugClassName = "#DebugClass";

Component createExpressionEvaluationComponent(Procedure procedure) {
  Library realLibrary = procedure.enclosingLibrary;

  Library fakeLibrary = new Library(new Uri(scheme: 'evaluate', path: 'source'))
    ..setLanguageVersion(realLibrary.languageVersion)
    ..isNonNullableByDefault = realLibrary.isNonNullableByDefault
    ..nonNullableByDefaultCompiledMode =
        realLibrary.nonNullableByDefaultCompiledMode;

  if (procedure.parent is Class) {
    Class realClass = procedure.parent;

    Class fakeClass = new Class(name: kDebugClassName)..parent = fakeLibrary;
    Map<TypeParameter, TypeParameter> typeParams =
        <TypeParameter, TypeParameter>{};
    Map<TypeParameter, DartType> typeSubstitution = <TypeParameter, DartType>{};
    for (TypeParameter typeParam in realClass.typeParameters) {
      TypeParameter newNode = new TypeParameter(typeParam.name)
        ..parent = fakeClass;
      typeParams[typeParam] = newNode;
      typeSubstitution[typeParam] =
          new TypeParameterType.forAlphaRenaming(typeParam, newNode);
    }
    CloneVisitorWithMembers cloner = new CloneVisitorWithMembers(
        typeSubstitution: typeSubstitution, typeParams: typeParams);

    for (TypeParameter typeParam in realClass.typeParameters) {
      fakeClass.typeParameters.add(typeParam.accept<TreeNode>(cloner));
    }

    if (realClass.supertype != null) {
      // supertype is null for Object.
      fakeClass.supertype = new Supertype.byReference(
          realClass.supertype.className,
          realClass.supertype.typeArguments.map(cloner.visitType).toList());
    }

    // Rebind the type parameters in the procedure.
    procedure = cloner.cloneProcedure(procedure, null);
    procedure.parent = fakeClass;
    fakeClass.procedures.add(procedure);
    fakeLibrary.classes.add(fakeClass);
  } else {
    fakeLibrary.procedures.add(procedure);
    procedure.parent = fakeLibrary;
  }

  // TODO(vegorov) find a way to preserve metadata.
  Component component = new Component(libraries: [fakeLibrary]);
  component.setMainMethodAndMode(
      null, false, fakeLibrary.nonNullableByDefaultCompiledMode);
  return component;
}

List<int> serializeProcedure(Procedure procedure) {
  return serializeComponent(createExpressionEvaluationComponent(procedure));
}

/// A [Sink] that directly writes data into a byte builder.
class ByteSink implements Sink<List<int>> {
  final BytesBuilder builder = new BytesBuilder();

  void add(List<int> data) {
    builder.add(data);
  }

  void close() {}
}
