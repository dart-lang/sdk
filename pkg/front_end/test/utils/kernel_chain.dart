// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library fasta.testing.kernel_chain;

import 'dart:io' show Directory, File, IOSink, Platform;

import 'dart:typed_data' show Uint8List;

import 'package:_fe_analyzer_shared/src/util/relativize.dart'
    show isWindows, relativizeUri;

import 'package:front_end/src/api_prototype/compiler_options.dart'
    show CompilerOptions, DiagnosticMessage;

import 'package:front_end/src/base/processed_options.dart'
    show ProcessedOptions;

import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;

import 'package:front_end/src/fasta/compiler_context.dart' show CompilerContext;

import 'package:front_end/src/fasta/fasta_codes.dart' show templateUnspecified;

import 'package:front_end/src/fasta/kernel/kernel_target.dart'
    show KernelTarget;

import 'package:front_end/src/fasta/kernel/utils.dart' show ByteSink;

import 'package:front_end/src/fasta/messages.dart'
    show DiagnosticMessageFromJson, LocatedMessage;

import 'package:kernel/ast.dart' show Component, Library, Reference, Source;

import 'package:kernel/binary/ast_from_binary.dart' show BinaryBuilder;

import 'package:kernel/binary/ast_to_binary.dart' show BinaryPrinter;

import 'package:kernel/error_formatter.dart' show ErrorFormatter;

import 'package:kernel/kernel.dart' show loadComponentFromBinary;

import 'package:kernel/naive_type_checker.dart' show NaiveTypeChecker;

import 'package:kernel/text/ast_to_text.dart' show Printer;

import 'package:kernel/text/text_serialization_verifier.dart'
    show RoundTripStatus, TextSerializationVerifier;

import 'package:testing/testing.dart'
    show
        ChainContext,
        Expectation,
        ExpectationSet,
        Result,
        StdioProcess,
        Step,
        TestDescription;

final Uri platformBinariesLocation = computePlatformBinariesLocation();

abstract class MatchContext implements ChainContext {
  bool get updateExpectations;

  String get updateExpectationsOption;

  ExpectationSet get expectationSet;

  Expectation get expectationFileMismatch =>
      expectationSet["ExpectationFileMismatch"];

  Expectation get expectationFileMismatchSerialized =>
      expectationSet["ExpectationFileMismatchSerialized"];

  Expectation get expectationFileMissing =>
      expectationSet["ExpectationFileMissing"];

  Future<Result<O>> match<O>(String suffix, String actual, Uri uri, O output,
      {Expectation onMismatch}) async {
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
        onMismatch ??= expectationFileMismatch;
        return new Result<O>(
            output, onMismatch, "$uri doesn't match ${expectedFile.uri}\n$diff",
            autoFixCommand: onMismatch == expectationFileMismatch
                ? updateExpectationsOption
                : null);
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
          autoFixCommand: updateExpectationsOption);
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

class Print extends Step<ComponentResult, ComponentResult, ChainContext> {
  const Print();

  String get name => "print";

  Future<Result<ComponentResult>> run(ComponentResult result, _) async {
    Component component = result.component;

    StringBuffer sb = new StringBuffer();
    await CompilerContext.runWithDefaultOptions((compilerContext) async {
      compilerContext.uriToSource.addAll(component.uriToSource);

      Printer printer = new Printer(sb);
      for (Library library in component.libraries) {
        if (result.userLibraries.contains(library.importUri)) {
          printer.writeLibraryFile(library);
        }
      }
      printer.writeConstantTable(component);
    });
    print("$sb");
    return pass(result);
  }
}

class TypeCheck extends Step<ComponentResult, ComponentResult, ChainContext> {
  const TypeCheck();

  String get name => "typeCheck";

  Future<Result<ComponentResult>> run(
      ComponentResult result, ChainContext context) async {
    Component component = result.component;
    ErrorFormatter errorFormatter = new ErrorFormatter();
    NaiveTypeChecker checker =
        new NaiveTypeChecker(errorFormatter, component, ignoreSdk: true);
    checker.checkComponent(component);
    if (errorFormatter.numberOfFailures == 0) {
      return pass(result);
    } else {
      errorFormatter.failures.forEach(print);
      print('------- Found ${errorFormatter.numberOfFailures} errors -------');
      return new Result<ComponentResult>(
          null,
          context.expectationSet["TypeCheckError"],
          '${errorFormatter.numberOfFailures} type errors');
    }
  }
}

class MatchExpectation
    extends Step<ComponentResult, ComponentResult, MatchContext> {
  final String suffix;
  final bool serializeFirst;
  final bool isLastMatchStep;

  /// Check if a textual representation of the component matches the expectation
  /// located at [suffix]. If [serializeFirst] is true, the input component will
  /// be serialized, deserialized, and the textual representation of that is
  /// compared. It is still the original component that is returned though.
  const MatchExpectation(this.suffix,
      {this.serializeFirst: false, this.isLastMatchStep})
      : assert(isLastMatchStep != null);

  String get name => "match expectations";

  Future<Result<ComponentResult>> run(
      ComponentResult result, MatchContext context) {
    Component component = result.component;

    Component componentToText = component;
    if (serializeFirst) {
      component.computeCanonicalNames();
      List<Library> sdkLibraries =
          component.libraries.where((l) => !result.isUserLibrary(l)).toList();

      ByteSink sink = new ByteSink();
      Component writeMe = new Component(
          libraries: component.libraries.where(result.isUserLibrary).toList())
        ..setMainMethodAndMode(null, false, component.mode);
      writeMe.uriToSource.addAll(component.uriToSource);
      if (component.problemsAsJson != null) {
        writeMe.problemsAsJson =
            new List<String>.from(component.problemsAsJson);
      }
      BinaryPrinter binaryPrinter = new BinaryPrinter(sink);
      binaryPrinter.writeComponentFile(writeMe);
      List<int> bytes = sink.builder.takeBytes();

      BinaryBuilder binaryBuilder = new BinaryBuilder(bytes);
      componentToText = new Component(libraries: sdkLibraries);
      binaryBuilder.readComponent(componentToText);
      component.adoptChildren();
    }

    Uri uri = result.description.uri;
    Iterable<Library> libraries =
        componentToText.libraries.where(result.isUserLibrary);
    Uri base = uri.resolve(".");
    Uri dartBase = Uri.base;

    StringBuffer buffer = new StringBuffer();

    List<Iterable<String>> errors =
        (context as dynamic).componentToDiagnostics[component];
    Set<String> reportedErrors = <String>{};
    for (Iterable<String> message in errors) {
      reportedErrors.add(message.join('\n'));
    }
    Set<String> problemsAsJson = <String>{};
    void addProblemsAsJson(List<String> problems) {
      if (problems != null) {
        for (String jsonString in problems) {
          DiagnosticMessage message =
              new DiagnosticMessageFromJson.fromJson(jsonString);
          problemsAsJson.add(message.plainTextFormatted.join('\n'));
        }
      }
    }

    addProblemsAsJson(componentToText.problemsAsJson);
    libraries.forEach((Library library) {
      addProblemsAsJson(library.problemsAsJson);
    });

    bool hasProblemsOutsideComponent = false;
    for (String reportedError in reportedErrors) {
      if (!problemsAsJson.contains(reportedError)) {
        if (!hasProblemsOutsideComponent) {
          buffer.writeln('//');
          buffer.writeln('// Problems outside component:');
        }
        buffer.writeln('//');
        buffer.writeln('// ${reportedError.split('\n').join('\n// ')}');
        hasProblemsOutsideComponent = true;
      }
    }
    if (hasProblemsOutsideComponent) {
      buffer.writeln('//');
    }
    if (isLastMatchStep) {
      // Clear errors only in the last match step. This is needed to verify
      // problems reported outside the component in both the serialized and
      // non-serialized step.
      errors.clear();
    }
    Printer printer = new Printer(buffer)
      ..writeProblemsAsJson(
          "Problems in component", componentToText.problemsAsJson);
    libraries.forEach((Library library) {
      printer.writeLibraryFile(library);
      printer.endLine();
    });
    printer.writeConstantTable(componentToText);

    if (result.extraConstantStrings.isNotEmpty) {
      buffer.writeln("");
      buffer.writeln("Extra constant evaluation status:");
      for (String extraConstantString in result.extraConstantStrings) {
        buffer.writeln(extraConstantString);
      }
    }
    bool printedConstantCoverageHeader = false;
    for (Source source in result.component.uriToSource.values) {
      if (!result.isUserLibraryImportUri(source.importUri)) continue;

      if (source.constantCoverageConstructors != null &&
          source.constantCoverageConstructors.isNotEmpty) {
        if (!printedConstantCoverageHeader) {
          buffer.writeln("");
          buffer.writeln("");
          buffer.writeln("Constructor coverage from constants:");
          printedConstantCoverageHeader = true;
        }
        buffer.writeln("${source.fileUri}:");
        for (Reference reference in source.constantCoverageConstructors) {
          buffer
              .writeln("- ${reference.node} (from ${reference.node.location})");
        }
        buffer.writeln("");
      }
    }

    String actual = "$buffer";
    String binariesPath =
        relativizeUri(Uri.base, platformBinariesLocation, isWindows);
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
    return context.match<ComponentResult>(suffix, actual, uri, result,
        onMismatch: serializeFirst
            ? context.expectationFileMismatchSerialized
            : context.expectationFileMismatch);
  }
}

class KernelTextSerialization
    extends Step<ComponentResult, ComponentResult, ChainContext> {
  static const bool writeRoundTripStatus = bool.fromEnvironment(
      "text_serialization.writeRoundTripStatus",
      defaultValue: false);

  static const String suffix = ".roundtrip";

  const KernelTextSerialization();

  String get name => "kernel text serialization";

  Future<Result<ComponentResult>> run(
      ComponentResult result, ChainContext context) async {
    Component component = result.component;
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
      component.computeCanonicalNames();
      compilerContext.uriToSource.addAll(component.uriToSource);
      TextSerializationVerifier verifier =
          new TextSerializationVerifier(root: component.root);
      for (Library library in component.libraries) {
        if (library.importUri.scheme != "dart" &&
            library.importUri.scheme != "package") {
          verifier.verify(library);
        }
      }

      List<RoundTripStatus> failures = verifier.failures;
      for (RoundTripStatus failure in failures) {
        LocatedMessage message = templateUnspecified
            .withArguments("\n${failure}")
            .withLocation(failure.uri, failure.offset, 1);
        options.report(message, message.code.severity);
      }

      if (writeRoundTripStatus) {
        Uri uri = component.uriToSource.keys
            .firstWhere((uri) => uri?.scheme == "file");
        String filename = "${uri.toFilePath()}${suffix}";
        uri = new File(filename).uri;
        StringBuffer buffer = new StringBuffer();
        for (RoundTripStatus status in verifier.takeStatus()) {
          status.printOn(buffer);
        }
        await openWrite(uri, (IOSink sink) {
          sink.write(buffer.toString());
        });
      }

      if (failures.isNotEmpty) {
        return new Result<ComponentResult>(null,
            context.expectationSet["TextSerializationFailure"], "$messages");
      }
      return pass(result);
    });
  }
}

class WriteDill extends Step<ComponentResult, ComponentResult, ChainContext> {
  const WriteDill();

  String get name => "write .dill";

  Future<Result<ComponentResult>> run(ComponentResult result, _) async {
    Component component = result.component;
    Directory tmp = await Directory.systemTemp.createTemp();
    Uri uri = tmp.uri.resolve("generated.dill");
    File generated = new File.fromUri(uri);
    IOSink sink = generated.openWrite();
    result = new ComponentResult(result.description, result.component,
        result.userLibraries, result.options, result.sourceTarget, uri);
    try {
      new BinaryPrinter(sink).writeComponentFile(component);
    } catch (e, s) {
      return fail(result, e, s);
    } finally {
      print("Wrote `${generated.path}`");
      await sink.close();
    }
    return pass(result);
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
  if (Platform.isWindows) {
    // TODO(johnniwinther): Work-around for Windows. For some reason piping
    // the actual result through stdin doesn't work; it shows a diff as if the
    // actual result is the empty string.
    Directory tempDirectory = Directory.systemTemp.createTempSync();
    Uri uri = tempDirectory.uri.resolve('actual');
    File file = new File.fromUri(uri)..writeAsStringSync(actual);
    StdioProcess process = await StdioProcess.run(
        "git",
        <String>[
          "diff",
          "--no-index",
          "-u",
          expected.toFilePath(),
          uri.toFilePath()
        ],
        runInShell: true);
    file.deleteSync();
    tempDirectory.deleteSync();
    return process.output;
  } else {
    StdioProcess process = await StdioProcess.run(
        "git", <String>["diff", "--no-index", "-u", expected.toFilePath(), "-"],
        input: actual, runInShell: true);
    return process.output;
  }
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

class ComponentResult {
  final TestDescription description;
  final Component component;
  final Set<Uri> userLibraries;
  final Uri outputUri;
  final ProcessedOptions options;
  final KernelTarget sourceTarget;
  final List<String> extraConstantStrings = [];

  ComponentResult(this.description, this.component, this.userLibraries,
      this.options, this.sourceTarget,
      [this.outputUri]);

  bool isUserLibrary(Library library) {
    return isUserLibraryImportUri(library.importUri);
  }

  bool isUserLibraryImportUri(Uri importUri) {
    return userLibraries.contains(importUri);
  }
}
