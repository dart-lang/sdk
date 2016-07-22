// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Conventions for paths:
///
/// - Use the [Uri] class for paths that may have the `file`, `dart` or
///   `package` scheme.  Never use [Uri] for relative paths.
/// - Use [String]s for all filenames and paths that have no scheme prefix.
/// - Never translate a `dart:` or `package:` URI into a `file:` URI, instead
///   translate it to a [String] if the file system path is needed.
/// - Only use [File] from dart:io at the last moment when it is needed.
///
library kernel;

import 'analyzer/loader.dart';
import 'ast.dart';
import 'binary/ast_to_binary.dart';
import 'binary/loader.dart';
import 'dart:async';
import 'dart:io';
import 'repository.dart';
import 'text/ast_to_text.dart';

export 'ast.dart';
export 'repository.dart';
export 'analyzer/analyzer_repository.dart';

Program loadProgramFromBinary(String path) {
  Repository repository = new Repository();
  return new BinaryLoader(repository).loadProgram(path);
}

/// Load a binary library from [path], unless [repository] already has
/// a loaded version of the library.
///
/// If provided, [repository] is used to link URIs to other [Library] objects.
///
/// [path] is relative to the working directory of the repository, or
/// the current working directory if no repository is given.
Library loadLibraryFromBinary(String path, [Repository repository]) {
  repository ??= new Repository();
  var library = repository.getLibrary(path);
  new BinaryLoader(repository).ensureLibraryIsLoaded(library);
  return library;
}

TreeNode loadProgramOrLibraryFromBinary(String path, [Repository repository]) {
  repository ??= new Repository();
  return new BinaryLoader(repository).loadProgramOrLibrary(path);
}

/// Loads a .dart library from [path], unless [repository] already has
/// a loaded version of that library.
Library loadLibraryFromDart(String path, [Repository repository]) {
  repository ??= new Repository();
  return new AnalyzerLoader(repository).loadLibrary(path);
}

/// Loads a .dart file from [path] and all of its transitive dependencies.
///
/// The resulting [Program] will have a main method if the library at [path]
/// contains a top-level method named "main", otherwise its main reference will
/// be `null`.
Program loadProgramFromDart(String path, [Repository repository]) {
  repository ??= new Repository();
  return new AnalyzerLoader(repository).loadProgram(path);
}

Future writeLibraryToBinary(Library library, String path) {
  var sink = new File(path).openWrite();
  var future;
  try {
    new BinaryPrinter(sink).writeLibraryFile(library);
  } finally {
    future = sink.close();
  }
  return future;
}

Future writeProgramToBinary(Program program, String path) {
  var sink = new File(path).openWrite();
  var future;
  try {
    new BinaryPrinter(sink).writeProgramFile(program);
  } finally {
    future = sink.close();
  }
  return future;
}

void writeLibraryToText(Library library, [String path]) {
  StringBuffer buffer = new StringBuffer();
  new Printer(buffer).writeLibraryFile(library);
  if (path == null) {
    print(buffer);
  } else {
    new File(path).writeAsStringSync('$buffer');
  }
}

void writeProgramToText(Program program, [String path]) {
  StringBuffer buffer = new StringBuffer();
  new Printer(buffer).writeProgramFile(program);
  if (path == null) {
    print(buffer);
  } else {
    new File(path).writeAsStringSync('$buffer');
  }
}
