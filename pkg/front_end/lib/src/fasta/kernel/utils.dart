// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:front_end/src/scanner/token.dart' show Token;
import 'package:kernel/ast.dart';
import 'package:kernel/binary/ast_to_binary.dart';
import 'package:kernel/text/ast_to_text.dart';

/// A null-aware alternative to `token.offset`.  If [token] is `null`, returns
/// `TreeNode.noOffset`.
int offsetForToken(Token token) =>
    token == null ? TreeNode.noOffset : token.offset;

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

Future<Null> writeProgramToFile(Program program, Uri uri) async {
  File output = new File.fromUri(uri);
  IOSink sink = output.openWrite();
  try {
    new BinaryPrinter(sink).writeProgramFile(program);
    program.unbindCanonicalNames();
  } finally {
    await sink.close();
  }
}
