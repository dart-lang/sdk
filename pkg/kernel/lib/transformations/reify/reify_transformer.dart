// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.transformations.reify.standalone_runner;

import 'analysis/program_analysis.dart';
import 'dart:io' show File, IOSink;

import 'package:kernel/binary/ast_to_binary.dart' show BinaryPrinter;

import 'package:kernel/ast.dart';

import 'package:kernel/kernel.dart';
import 'package:kernel/verifier.dart';
import 'package:kernel/text/ast_to_text.dart' show Printer;

import 'transformation/remove_generics.dart';
import 'transformation/transformer.dart'
    show ReifyVisitor, RuntimeLibrary, RuntimeTypeSupportBuilder;

import 'package:kernel/core_types.dart' show CoreTypes;

RuntimeLibrary findRuntimeTypeLibrary(Program p) {
  Library findLibraryEndingWith(String postfix) {
    Iterable<Library> candidates = p.libraries.where((Library l) {
      return l.importUri.toString().endsWith(postfix);
    });
    if (candidates.length != 1) {
      String howMany = candidates.isEmpty ? "No" : "Multiple";
      throw new Exception(
          "$howMany candidates for runtime support library found.");
    }
    return candidates.single;
  }

  Library types = findLibraryEndingWith("reify/types.dart");
  Library declarations = findLibraryEndingWith("reify/declarations.dart");
  Library interceptors = findLibraryEndingWith("reify/interceptors.dart");
  return new RuntimeLibrary(types, declarations, interceptors);
}

Program transformProgramUsingLibraries(
    Program program, RuntimeLibrary runtimeLibrary,
    [Library libraryToTransform]) {
  LibraryFilter filter = libraryToTransform != null
      ? (Library library) => library == libraryToTransform
      : (_) => true;
  ProgramKnowledge knowledge = analyze(program, analyzeLibrary: filter);
  Library mainLibrary = program.mainMethod.parent;
  RuntimeTypeSupportBuilder builder = new RuntimeTypeSupportBuilder(
      runtimeLibrary, new CoreTypes(program), mainLibrary);
  ReifyVisitor transformer =
      new ReifyVisitor(runtimeLibrary, builder, knowledge, libraryToTransform);
  // Transform the main program.
  program = program.accept(transformer);
  if (!filter(runtimeLibrary.interceptorsLibrary)) {
    // We need to transform the interceptor function in any case to make sure
    // that the type literals in the interceptor function are rewritten.
    runtimeLibrary.interceptorFunction.accept(transformer);
  }
  builder.createDeclarations();
  program = program.accept(new Erasure(transformer));
  // TODO(karlklose): skip checks in debug mode
  verifyProgram(program);
  return program;
}

Program transformProgram(Program program) {
  RuntimeLibrary runtimeLibrary = findRuntimeTypeLibrary(program);
  Library mainLibrary = program.mainMethod.enclosingLibrary;
  return transformProgramUsingLibraries(program, runtimeLibrary, mainLibrary);
}

main(List<String> arguments) async {
  String path = arguments.first;
  Uri output;
  if (arguments.length > 1) {
    output = Uri.base.resolve(arguments[1]);
  }
  Uri uri = Uri.base.resolve(path);
  Program program = loadProgramFromBinary(uri.toFilePath());

  RuntimeLibrary runtimeLibrary = findRuntimeTypeLibrary(program);
  Library mainLibrary = program.mainMethod.enclosingLibrary;
  program =
      transformProgramUsingLibraries(program, runtimeLibrary, mainLibrary);

  if (output == null) {
    // Print result
    StringBuffer sb = new StringBuffer();
    Printer printer = new Printer(sb);
    printer.writeLibraryFile(mainLibrary);
    print("$sb");
  } else {
    IOSink sink = new File.fromUri(output).openWrite();
    try {
      new BinaryPrinter(sink).writeProgramFile(program);
    } finally {
      await sink.close();
    }
    try {
      // Check that we can read the binary file.
      loadProgramFromBinary(output.toFilePath());
    } catch (e) {
      print("Error when attempting to read $output.");
      rethrow;
    }
  }
}
