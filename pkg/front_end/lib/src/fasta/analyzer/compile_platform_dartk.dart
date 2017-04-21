// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.compile_platform;

import 'dart:async' show Future;

import 'dart:io' show File, IOSink;

import 'package:analyzer/src/generated/source.dart' show Source;

import 'package:analyzer/dart/element/element.dart'
    show ExportElement, LibraryElement;

import 'package:kernel/ast.dart'
    show Field, Library, Name, Program, StringLiteral;

import 'package:kernel/binary/ast_to_binary.dart' show BinaryPrinter;

import 'package:analyzer/src/kernel/loader.dart'
    show DartLoader, DartOptions, createDartSdk;

import 'package:kernel/target/targets.dart' show Target, TargetFlags, getTarget;

import 'package:kernel/ast.dart' show Program;

import '../environment_variable.dart'
    show EnvironmentVariableDirectory, fileExists;

import '../errors.dart' show inputError;

const EnvironmentVariableSdk dartAotSdk = const EnvironmentVariableSdk(
    "DART_AOT_SDK",
    "The environment variable 'DART_AOT_SDK' should point to a patched SDK.");

class EnvironmentVariableSdk extends EnvironmentVariableDirectory {
  const EnvironmentVariableSdk(String name, String what) : super(name, what);

  Future<Null> validate(String value) async {
    Uri sdk = Uri.base.resolveUri(new Uri.directory(value));
    const String asyncDart = "lib/async/async.dart";
    if (!await fileExists(sdk, asyncDart)) {
      inputError(
          null,
          null,
          "The environment variable '$name' has the value '$value', "
          "that's a directory that doesn't contain '$asyncDart'. $what");
    }
    const String asyncSources = "lib/async/async_sources.gypi";
    if (await fileExists(sdk, asyncSources)) {
      inputError(
          null,
          null,
          "The environment variable '$name' has the value '$value', "
          "that's a directory that contains '$asyncSources', so it isn't a "
          "patched SDK. $what");
    }
    return null;
  }
}

mainEntryPoint(List<String> arguments) async {
  Uri output = Uri.base.resolveUri(new Uri.file(arguments.single));
  DartOptions options = new DartOptions(
      strongMode: false, sdk: await dartAotSdk.value, packagePath: null);
  Program program = new Program();
  DartLoader loader = new DartLoader(program, options, null,
      ignoreRedirectingFactories: false,
      dartSdk: createDartSdk(options.sdk, strongMode: options.strongMode));
  Target target =
      getTarget("vm", new TargetFlags(strongMode: options.strongMode));
  loader.loadProgram(Uri.base.resolve("pkg/fasta/test/platform.dart"),
      target: target);
  if (loader.errors.isNotEmpty) {
    inputError(null, null, loader.errors.join("\n"));
  }
  Library mainLibrary = program.mainMethod.enclosingLibrary;
  program.uriToSource.remove(mainLibrary.fileUri);
  program = new Program(
      program.libraries
          .where((Library l) => l.importUri.scheme == "dart")
          .toList(),
      program.uriToSource);
  target.performModularTransformations(program);
  target.performGlobalTransformations(program);
  for (LibraryElement analyzerLibrary in loader.libraryElements) {
    Library library = loader.getLibraryReference(analyzerLibrary);
    StringBuffer sb = new StringBuffer();
    if (analyzerLibrary.exports.isNotEmpty) {
      Source source;
      int offset;
      for (ExportElement export in analyzerLibrary.exports) {
        source ??= export.source;
        offset ??= export.nameOffset;
        Uri uri = export.exportedLibrary.source.uri;
        sb.write("export '");
        sb.write(uri);
        sb.write("'");
        if (export.combinators.isNotEmpty) {
          sb.write(" ");
          sb.writeAll(export.combinators, " ");
        }
        sb.write(";");
      }
      Name exports = new Name("_exports#", library);
      StringLiteral literal = new StringLiteral("$sb")..fileOffset = offset;
      library.addMember(new Field(exports,
          isStatic: true,
          isConst: true,
          initializer: literal,
          fileUri: "${new Uri.file(source.fullName)}")..fileOffset = offset);
    }
  }

  IOSink sink = new File.fromUri(output).openWrite();
  new BinaryPrinter(sink).writeProgramFile(program);
  await sink.close();
}
