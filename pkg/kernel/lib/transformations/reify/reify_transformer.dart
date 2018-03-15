// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.transformations.reify.standalone_runner;

import 'analysis/program_analysis.dart';
import 'dart:io' show File, IOSink;

import '../../binary/ast_to_binary.dart' show BinaryPrinter;

import '../../ast.dart';

import '../../kernel.dart';
import '../../verifier.dart';
import '../../text/ast_to_text.dart' show Printer;

import 'transformation/remove_generics.dart';
import 'transformation/transformer.dart'
    show ReifyVisitor, RuntimeLibrary, RuntimeTypeSupportBuilder;

import '../../core_types.dart' show CoreTypes;

RuntimeLibrary findRuntimeTypeLibrary(Component p) {
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

Component transformComponentUsingLibraries(
    CoreTypes coreTypes, Component component, RuntimeLibrary runtimeLibrary,
    [Library libraryToTransform]) {
  LibraryFilter filter = libraryToTransform != null
      ? (Library library) => library == libraryToTransform
      : (_) => true;
  ProgramKnowledge knowledge = analyze(component, analyzeLibrary: filter);
  Library mainLibrary = component.mainMethod.parent;
  RuntimeTypeSupportBuilder builder =
      new RuntimeTypeSupportBuilder(runtimeLibrary, coreTypes, mainLibrary);
  ReifyVisitor transformer =
      new ReifyVisitor(runtimeLibrary, builder, knowledge, libraryToTransform);
  // Transform the main component.
  component = component.accept(transformer);
  if (!filter(runtimeLibrary.interceptorsLibrary)) {
    // We need to transform the interceptor function in any case to make sure
    // that the type literals in the interceptor function are rewritten.
    runtimeLibrary.interceptorFunction.accept(transformer);
  }
  builder.createDeclarations();
  component = component.accept(new Erasure(transformer));
  // TODO(karlklose): skip checks in debug mode
  verifyComponent(component);
  return component;
}

Component transformComponent(CoreTypes coreTypes, Component component) {
  RuntimeLibrary runtimeLibrary = findRuntimeTypeLibrary(component);
  Library mainLibrary = component.mainMethod.enclosingLibrary;
  return transformComponentUsingLibraries(
      coreTypes, component, runtimeLibrary, mainLibrary);
}

main(List<String> arguments) async {
  String path = arguments.first;
  Uri output;
  if (arguments.length > 1) {
    output = Uri.base.resolve(arguments[1]);
  }
  Uri uri = Uri.base.resolve(path);
  Component component = loadComponentFromBinary(uri.toFilePath());
  CoreTypes coreTypes = new CoreTypes(component);

  RuntimeLibrary runtimeLibrary = findRuntimeTypeLibrary(component);
  Library mainLibrary = component.mainMethod.enclosingLibrary;
  component = transformComponentUsingLibraries(
      coreTypes, component, runtimeLibrary, mainLibrary);

  if (output == null) {
    // Print result
    StringBuffer sb = new StringBuffer();
    Printer printer = new Printer(sb);
    printer.writeLibraryFile(mainLibrary);
    print("$sb");
  } else {
    IOSink sink = new File.fromUri(output).openWrite();
    try {
      new BinaryPrinter(sink).writeComponentFile(component);
    } finally {
      await sink.close();
    }
    try {
      // Check that we can read the binary file.
      loadComponentFromBinary(output.toFilePath());
    } catch (e) {
      print("Error when attempting to read $output.");
      rethrow;
    }
  }
}
