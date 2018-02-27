// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async' show Future;

import 'dart:io' show BytesBuilder, File, IOSink;

import 'package:kernel/ast.dart' show Library, Program;

import 'package:kernel/binary/ast_to_binary.dart' show BinaryPrinter;

import 'package:kernel/binary/limited_ast_to_binary.dart'
    show LimitedBinaryPrinter;

import 'package:kernel/text/ast_to_text.dart' show Printer;

/// Print the given [program].  Do nothing if it is `null`.  If the
/// [libraryFilter] is provided, then only libraries that satisfy it are
/// printed.
void printProgramText(Program program, {bool libraryFilter(Library library)}) {
  if (program == null) return;
  StringBuffer sb = new StringBuffer();
  for (Library library in program.libraries) {
    if (libraryFilter != null && !libraryFilter(library)) continue;
    Printer printer = new Printer(sb);
    printer.writeLibraryFile(library);
  }
  print(sb);
}

/// Write [program] to file only including libraries that match [filter].
Future<Null> writeProgramToFile(Program program, Uri uri,
    {bool filter(Library library)}) async {
  File output = new File.fromUri(uri);
  IOSink sink = output.openWrite();
  try {
    BinaryPrinter printer = filter == null
        ? new BinaryPrinter(sink)
        : new LimitedBinaryPrinter(sink, filter ?? (_) => true, false);
    printer.writeProgramFile(program);
    program.unbindCanonicalNames();
  } finally {
    await sink.close();
  }
}

/// Serialize the libraries in [program] that match [filter].
List<int> serializeProgram(Program program,
    {bool filter(Library library), bool excludeUriToSource: false}) {
  ByteSink byteSink = new ByteSink();
  BinaryPrinter printer = filter == null && !excludeUriToSource
      ? new BinaryPrinter(byteSink)
      : new LimitedBinaryPrinter(
          byteSink, filter ?? (_) => true, excludeUriToSource);
  printer.writeProgramFile(program);
  return byteSink.builder.takeBytes();
}

/// A [Sink] that directly writes data into a byte builder.
class ByteSink implements Sink<List<int>> {
  final BytesBuilder builder = new BytesBuilder();

  void add(List<int> data) {
    builder.add(data);
  }

  void close() {}
}
