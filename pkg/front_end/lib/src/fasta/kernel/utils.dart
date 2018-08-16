// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async' show Future;

import 'dart:io' show BytesBuilder, File, IOSink;

import 'package:kernel/clone.dart' show CloneVisitor;

import 'package:kernel/ast.dart'
    show Library, Component, Procedure, Class, TypeParameter, Supertype;

import 'package:kernel/binary/ast_to_binary.dart' show BinaryPrinter;

import 'package:kernel/binary/limited_ast_to_binary.dart'
    show LimitedBinaryPrinter;

import 'package:kernel/text/ast_to_text.dart' show Printer;

/// Print the given [component].  Do nothing if it is `null`.  If the
/// [libraryFilter] is provided, then only libraries that satisfy it are
/// printed.
void printComponentText(Component component,
    {bool libraryFilter(Library library)}) {
  if (component == null) return;
  StringBuffer sb = new StringBuffer();
  for (Library library in component.libraries) {
    if (libraryFilter != null && !libraryFilter(library)) continue;
    Printer printer = new Printer(sb);
    printer.writeLibraryFile(library);
  }
  print(sb);
}

/// Write [component] to file only including libraries that match [filter].
Future<Null> writeComponentToFile(Component component, Uri uri,
    {bool filter(Library library)}) async {
  File output = new File.fromUri(uri);
  IOSink sink = output.openWrite();
  try {
    BinaryPrinter printer = filter == null
        ? new BinaryPrinter(sink)
        : new LimitedBinaryPrinter(sink, filter ?? (_) => true, false);
    printer.writeComponentFile(component);
    component.unbindCanonicalNames();
  } finally {
    await sink.close();
  }
}

/// Serialize the libraries in [component] that match [filter].
List<int> serializeComponent(Component component,
    {bool filter(Library library), bool excludeUriToSource: false}) {
  ByteSink byteSink = new ByteSink();
  BinaryPrinter printer = filter == null && !excludeUriToSource
      ? new BinaryPrinter(byteSink)
      : new LimitedBinaryPrinter(
          byteSink, filter ?? (_) => true, excludeUriToSource);
  printer.writeComponentFile(component);
  return byteSink.builder.takeBytes();
}

const String kDebugClassName = "#DebugClass";

List<int> serializeProcedure(Procedure procedure) {
  Library fakeLibrary =
      new Library(new Uri(scheme: 'evaluate', path: 'source'));

  if (procedure.parent is Class) {
    Class realClass = procedure.parent;

    CloneVisitor cloner = new CloneVisitor();

    Class fakeClass = new Class(name: kDebugClassName);
    for (TypeParameter typeParam in realClass.typeParameters) {
      fakeClass.typeParameters.add(typeParam.accept(cloner));
    }

    fakeClass.parent = fakeLibrary;
    fakeClass.supertype = new Supertype.byReference(
        realClass.supertype.className,
        realClass.supertype.typeArguments.map(cloner.visitType).toList());

    // Rebind the type parameters in the procedure.
    procedure = procedure.accept(cloner);
    procedure.parent = fakeClass;
    fakeClass.procedures.add(procedure);
    fakeLibrary.classes.add(fakeClass);
  } else {
    fakeLibrary.procedures.add(procedure);
    procedure.parent = fakeLibrary;
  }

  // TODO(vegorov) find a way to preserve metadata.
  Component program = new Component(libraries: [fakeLibrary]);
  return serializeComponent(program);
}

/// A [Sink] that directly writes data into a byte builder.
class ByteSink implements Sink<List<int>> {
  final BytesBuilder builder = new BytesBuilder();

  void add(List<int> data) {
    builder.add(data);
  }

  void close() {}
}
