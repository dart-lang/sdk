// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library fasta.testing.kernel_chain;

import 'dart:async' show Future;

import 'dart:io' show Directory, File, IOSink;

import 'dart:typed_data' show Uint8List;

import 'package:kernel/ast.dart'
    show Component, Field, Library, ListLiteral, StringLiteral;

import 'package:kernel/binary/ast_to_binary.dart' show BinaryPrinter;

import 'package:kernel/binary/ast_from_binary.dart' show BinaryBuilder;

import 'package:kernel/error_formatter.dart' show ErrorFormatter;

import 'package:kernel/kernel.dart' show loadComponentFromBinary;

import 'package:kernel/naive_type_checker.dart' show StrongModeTypeChecker;

import 'package:kernel/text/ast_to_text.dart' show Printer;

import 'package:testing/testing.dart'
    show ChainContext, Result, StdioProcess, Step;

import '../../api_prototype/compiler_options.dart'
    show CompilerOptions, DiagnosticMessage;

import '../../base/processed_options.dart' show ProcessedOptions;

import '../compiler_context.dart' show CompilerContext;

import '../kernel/verifier.dart' show verifyComponent;

import '../messages.dart' show LocatedMessage;

class Print extends Step<Component, Component, ChainContext> {
  const Print();

  String get name => "print";

  Future<Result<Component>> run(Component component, _) async {
    StringBuffer sb = new StringBuffer();
    for (Library library in component.libraries) {
      Printer printer = new Printer(sb);
      if (library.importUri.scheme != "dart" &&
          library.importUri.scheme != "package") {
        printer.writeLibraryFile(library);
      }
    }
    print("$sb");
    return pass(component);
  }
}

class Verify extends Step<Component, Component, ChainContext> {
  final bool fullCompile;

  const Verify(this.fullCompile);

  String get name => "verify";

  Future<Result<Component>> run(
      Component component, ChainContext context) async {
    StringBuffer messages = new StringBuffer();
    ProcessedOptions options = new ProcessedOptions(
        options: new CompilerOptions()
          ..onDiagnostic = (DiagnosticMessage message) {
            if (messages.isNotEmpty) {
              messages.write("\n");
            }
            messages.writeAll(message.plainTextFormatted, "\n");
          });
    return await CompilerContext.runWithOptions(options,
        (compilerContext) async {
      compilerContext.uriToSource.addAll(component.uriToSource);
      List<LocatedMessage> verificationErrors = verifyComponent(component,
          isOutline: !fullCompile, skipPlatform: true);
      assert(verificationErrors.isEmpty || messages.isNotEmpty);
      if (messages.isEmpty) {
        return pass(component);
      } else {
        return new Result<Component>(null,
            context.expectationSet["VerificationError"], "$messages", null);
      }
    }, errorOnMissingInput: false);
  }
}

class TypeCheck extends Step<Component, Component, ChainContext> {
  const TypeCheck();

  String get name => "typeCheck";

  Future<Result<Component>> run(
      Component component, ChainContext context) async {
    var errorFormatter = new ErrorFormatter();
    var checker =
        new StrongModeTypeChecker(errorFormatter, component, ignoreSdk: true);
    checker.checkComponent(component);
    if (errorFormatter.numberOfFailures == 0) {
      return pass(component);
    } else {
      errorFormatter.failures.forEach(print);
      print('------- Found ${errorFormatter.numberOfFailures} errors -------');
      return new Result<Component>(
          null,
          context.expectationSet["TypeCheckError"],
          '${errorFormatter.numberOfFailures} type errors',
          null);
    }
  }
}

class MatchExpectation extends Step<Component, Component, ChainContext> {
  final String suffix;

  // TODO(ahe): This is true by default which doesn't match well with the class
  // name.
  final bool updateExpectations;

  const MatchExpectation(this.suffix, {this.updateExpectations: false});

  String get name => "match expectations";

  Future<Result<Component>> run(Component component, dynamic context) async {
    StringBuffer messages = context.componentToDiagnostics[component];
    Uri uri = component.uriToSource.keys
        .firstWhere((uri) => uri != null && uri.scheme == "file");
    Library library = component.libraries
        .firstWhere((Library library) => library.importUri.scheme != "dart");
    Uri base = uri.resolve(".");
    Uri dartBase = Uri.base;
    StringBuffer buffer = new StringBuffer();
    if (messages.isNotEmpty) {
      buffer.write("// Formatted problems:\n//");
      for (String line in "${messages}".split("\n")) {
        buffer.write("\n// $line".trimRight());
      }
      buffer.write("\n\n");
      messages.clear();
    }
    for (Field field in library.fields) {
      if (field.name.name != "#errors") continue;
      ListLiteral list = field.initializer;
      buffer.write("// Unhandled errors:");
      for (StringLiteral string in list.expressions) {
        buffer.write("\n//");
        for (String line in string.value.split("\n")) {
          buffer.write("\n// $line");
        }
      }
      buffer.write("\n\n");
    }
    new ErrorPrinter(buffer).writeLibraryFile(library);
    String actual = "$buffer".replaceAll("$base", "org-dartlang-testcase:///");
    actual = actual.replaceAll("$dartBase", "org-dartlang-testcase-sdk:///");
    actual = actual.replaceAll("\\n", "\n");
    File expectedFile = new File("${uri.toFilePath()}$suffix");
    if (await expectedFile.exists()) {
      String expected = await expectedFile.readAsString();
      if (expected.trim() != actual.trim()) {
        if (!updateExpectations) {
          String diff = await runDiff(expectedFile.uri, actual);
          return new Result<Component>(
              component,
              context.expectationSet["ExpectationFileMismatch"],
              "$uri doesn't match ${expectedFile.uri}\n$diff",
              null);
        }
      } else {
        return pass(component);
      }
    }
    if (updateExpectations) {
      await openWrite(expectedFile.uri, (IOSink sink) {
        sink.writeln(actual.trim());
      });
      return pass(component);
    } else {
      return new Result<Component>(
          component,
          context.expectationSet["ExpectationFileMissing"],
          """
Please create file ${expectedFile.path} with this content:
$actual""",
          null);
    }
  }
}

class WriteDill extends Step<Component, Uri, ChainContext> {
  const WriteDill();

  String get name => "write .dill";

  Future<Result<Uri>> run(Component component, _) async {
    Directory tmp = await Directory.systemTemp.createTemp();
    Uri uri = tmp.uri.resolve("generated.dill");
    File generated = new File.fromUri(uri);
    IOSink sink = generated.openWrite();
    try {
      try {
        new BinaryPrinter(sink).writeComponentFile(component);
      } finally {
        component.unbindCanonicalNames();
      }
    } catch (e, s) {
      return fail(uri, e, s);
    } finally {
      print("Wrote `${generated.path}`");
      await sink.close();
    }
    return pass(uri);
  }
}

class ReadDill extends Step<Uri, Uri, ChainContext> {
  const ReadDill();

  String get name => "read .dill";

  Future<Result<Uri>> run(Uri uri, _) async {
    try {
      loadComponentFromBinary(uri.toFilePath());
    } catch (e, s) {
      return fail(uri, e, s);
    }
    return pass(uri);
  }
}

class Copy extends Step<Component, Component, ChainContext> {
  const Copy();

  String get name => "copy component";

  Future<Result<Component>> run(Component component, _) async {
    BytesCollector sink = new BytesCollector();
    new BinaryPrinter(sink).writeComponentFile(component);
    component.unbindCanonicalNames();
    Uint8List bytes = sink.collect();
    new BinaryBuilder(bytes).readComponent(component);
    return pass(component);
  }
}

class BytesCollector implements Sink<List<int>> {
  final List<List<int>> lists = <List<int>>[];

  int length = 0;

  void add(List<int> data) {
    lists.add(data);
    length += data.length;
  }

  Uint8List collect() {
    Uint8List result = new Uint8List(length);
    int offset = 0;
    for (List<int> list in lists) {
      result.setRange(offset, offset += list.length, list);
    }
    lists.clear();
    length = 0;
    return result;
  }

  void close() {}
}

Future<String> runDiff(Uri expected, String actual) async {
  StdioProcess process = await StdioProcess.run(
      "git", <String>["diff", "--no-index", "-u", expected.toFilePath(), "-"],
      input: actual, runInShell: true);
  return process.output;
}

Future<void> openWrite(Uri uri, f(IOSink sink)) async {
  IOSink sink = new File.fromUri(uri).openWrite();
  try {
    await f(sink);
  } finally {
    await sink.close();
  }
  print("Wrote $uri");
}

class ErrorPrinter extends Printer {
  ErrorPrinter(StringSink sink, {Object importTable, Object metadata})
      : super(sink, importTable: importTable, metadata: metadata);

  ErrorPrinter._inner(ErrorPrinter parent, Object importTable, Object metadata)
      : super(parent.sink,
            importTable: importTable,
            metadata: metadata,
            syntheticNames: parent.syntheticNames,
            annotator: parent.annotator,
            showExternal: parent.showExternal,
            showOffsets: parent.showOffsets,
            showMetadata: parent.showMetadata);

  @override
  ErrorPrinter createInner(importTable, metadata) {
    return new ErrorPrinter._inner(this, importTable, metadata);
  }

  @override
  visitField(Field node) {
    if (node.name.name != "#errors") {
      super.visitField(node);
    }
  }
}
