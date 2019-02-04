// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library fasta.testing.kernel_chain;

import 'dart:async' show Future;

import 'dart:io' show Directory, File, IOSink;

import 'dart:typed_data' show Uint8List;

import 'package:kernel/ast.dart' show Component, Library;

import 'package:kernel/binary/ast_to_binary.dart' show BinaryPrinter;

import 'package:kernel/binary/ast_from_binary.dart' show BinaryBuilder;

import 'package:kernel/error_formatter.dart' show ErrorFormatter;

import 'package:kernel/kernel.dart' show loadComponentFromBinary;

import 'package:kernel/naive_type_checker.dart' show NaiveTypeChecker;

import 'package:kernel/text/ast_to_text.dart' show Printer;

import 'package:kernel/text/text_serialization_verifier.dart'
    show
        TextDeserializationFailure,
        TextRoundTripFailure,
        TextSerializationFailure,
        TextSerializationVerificationFailure,
        TextSerializationVerifier;

import 'package:testing/testing.dart'
    show ChainContext, Expectation, ExpectationSet, Result, StdioProcess, Step;

import '../../api_prototype/compiler_options.dart'
    show CompilerOptions, DiagnosticMessage;

import '../../base/processed_options.dart' show ProcessedOptions;

import '../../compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;

import '../compiler_context.dart' show CompilerContext;

import '../kernel/verifier.dart' show verifyComponent;

import '../messages.dart' show LocatedMessage;

import '../fasta_codes.dart'
    show templateInternalProblemUnhandled, templateUnspecified;

import '../util/relativize.dart' show relativizeUri;

final Uri platformBinariesLocation = computePlatformBinariesLocation();

abstract class MatchContext implements ChainContext {
  bool get updateExpectations;

  ExpectationSet get expectationSet;

  Expectation get expectationFileMismatch =>
      expectationSet["ExpectationFileMismatch"];

  Expectation get expectationFileMissing =>
      expectationSet["ExpectationFileMissing"];

  Future<Result<O>> match<O>(
    String suffix,
    String actual,
    Uri uri,
    O output,
  ) async {
    actual = actual.trim();
    if (actual.isNotEmpty) {
      actual += "\n";
    }
    File expectedFile = new File("${uri.toFilePath()}$suffix");
    if (await expectedFile.exists()) {
      String expected = await expectedFile.readAsString();
      if (expected != actual) {
        if (updateExpectations) {
          return updateExpectationFile<O>(expectedFile.uri, actual, output);
        }
        String diff = await runDiff(expectedFile.uri, actual);
        return new Result<O>(output, expectationFileMismatch,
            "$uri doesn't match ${expectedFile.uri}\n$diff", null);
      } else {
        return new Result<O>.pass(output);
      }
    } else {
      if (actual.isEmpty) return new Result<O>.pass(output);
      if (updateExpectations) {
        return updateExpectationFile(expectedFile.uri, actual, output);
      }
      return new Result<O>(
          output,
          expectationFileMissing,
          """
Please create file ${expectedFile.path} with this content:
$actual""",
          null);
    }
  }

  Future<Result<O>> updateExpectationFile<O>(
    Uri uri,
    String actual,
    O output,
  ) async {
    if (actual.isEmpty) {
      await new File.fromUri(uri).delete();
    } else {
      await openWrite(uri, (IOSink sink) {
        sink.write(actual);
      });
    }
    return new Result<O>.pass(output);
  }
}

class Print extends Step<Component, Component, ChainContext> {
  const Print();

  String get name => "print";

  Future<Result<Component>> run(Component component, _) async {
    StringBuffer sb = new StringBuffer();
    await CompilerContext.runWithDefaultOptions((compilerContext) async {
      compilerContext.uriToSource.addAll(component.uriToSource);

      Printer printer = new Printer(sb);
      for (Library library in component.libraries) {
        if (library.importUri.scheme != "dart" &&
            library.importUri.scheme != "package") {
          printer.writeLibraryFile(library);
        }
      }
      printer.writeConstantTable(component);
    });
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
        new NaiveTypeChecker(errorFormatter, component, ignoreSdk: true);
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

class MatchExpectation extends Step<Component, Component, MatchContext> {
  final String suffix;

  const MatchExpectation(this.suffix);

  String get name => "match expectations";

  Future<Result<Component>> run(Component component, MatchContext context) {
    StringBuffer messages =
        (context as dynamic).componentToDiagnostics[component];
    Uri uri =
        component.uriToSource.keys.firstWhere((uri) => uri?.scheme == "file");
    Iterable<Library> libraries = component.libraries.where(
        ((Library library) =>
            library.importUri.scheme != "dart" &&
            library.importUri.scheme != "package"));
    Uri base = uri.resolve(".");
    Uri dartBase = Uri.base;
    StringBuffer buffer = new StringBuffer();
    messages.clear();
    Printer printer = new Printer(buffer)
      ..writeProblemsAsJson("Problems in component", component.problemsAsJson);
    libraries.forEach((Library library) {
      printer.writeLibraryFile(library);
      printer.endLine();
    });
    String actual = "$buffer";
    String binariesPath = relativizeUri(platformBinariesLocation);
    if (binariesPath.endsWith("/dart-sdk/lib/_internal/")) {
      // We are running from the built SDK.
      actual = actual.replaceAll(
          binariesPath.substring(
              0, binariesPath.length - "lib/_internal/".length),
          "sdk/");
    }
    actual = actual.replaceAll("$base", "org-dartlang-testcase:///");
    actual = actual.replaceAll("$dartBase", "org-dartlang-testcase-sdk:///");
    actual = actual.replaceAll("\\n", "\n");
    return context.match<Component>(suffix, actual, uri, component);
  }
}

class KernelTextSerialization extends Step<Component, Component, ChainContext> {
  const KernelTextSerialization();

  String get name => "kernel text serialization";

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
      TextSerializationVerifier verifier = new TextSerializationVerifier();
      for (Library library in component.libraries) {
        if (library.importUri.scheme != "dart" &&
            library.importUri.scheme != "package") {
          library.accept(verifier);
        }
      }
      for (TextSerializationVerificationFailure failure in verifier.failures) {
        LocatedMessage message;
        if (failure is TextSerializationFailure) {
          message = templateUnspecified
              .withArguments(
                  "Failed to serialize a node: ${failure.message.isNotEmpty}")
              .withLocation(failure.uri, failure.offset, 1);
        } else if (failure is TextDeserializationFailure) {
          message = templateUnspecified
              .withArguments(
                  "Failed to deserialize a node: ${failure.message.isNotEmpty}")
              .withLocation(failure.uri, failure.offset, 1);
        } else if (failure is TextRoundTripFailure) {
          String formattedInitial =
              failure.initial.isNotEmpty ? failure.initial : "<empty>";
          String formattedSerialized =
              failure.serialized.isNotEmpty ? failure.serialized : "<empty>";
          message = templateUnspecified
              .withArguments(
                  "Round trip failure: initial doesn't match serialized.\n"
                  "  Initial    : $formattedInitial\n"
                  "  Serialized : $formattedSerialized")
              .withLocation(failure.uri, failure.offset, 1);
        } else {
          message = templateInternalProblemUnhandled
              .withArguments(
                  "${failure.runtimeType}", "KernelTextSerialization.run")
              .withLocation(failure.uri, failure.offset, 1);
        }
        options.report(message, message.code.severity);
      }

      if (verifier.failures.isNotEmpty) {
        return new Result<Component>(
            null,
            context.expectationSet["TextSerializationFailure"],
            "$messages",
            null);
      }
      return pass(component);
    });
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
