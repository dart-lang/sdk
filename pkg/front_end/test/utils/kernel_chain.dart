// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library fasta.testing.kernel_chain;

import 'dart:async';
import 'dart:io' show Directory, File, IOSink, Platform;

import 'package:_fe_analyzer_shared/src/util/relativize.dart'
    show isWindows, relativizeUri;

import 'package:front_end/src/api_prototype/compiler_options.dart'
    show DiagnosticMessage;

import 'package:front_end/src/base/processed_options.dart'
    show ProcessedOptions;

import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;

import 'package:front_end/src/fasta/compiler_context.dart' show CompilerContext;

import 'package:front_end/src/fasta/kernel/kernel_target.dart'
    show KernelTarget;

import 'package:front_end/src/fasta/kernel/utils.dart' show ByteSink;

import 'package:front_end/src/fasta/messages.dart'
    show DiagnosticMessageFromJson;

import 'package:kernel/ast.dart'
    show
        Block,
        Component,
        Library,
        Procedure,
        ReturnStatement,
        Source,
        Statement;

import 'package:kernel/binary/ast_from_binary.dart' show BinaryBuilder;

import 'package:kernel/binary/ast_to_binary.dart' show BinaryPrinter;

import 'package:kernel/error_formatter.dart' show ErrorFormatter;

import 'package:kernel/kernel.dart' show loadComponentFromBinary;

import 'package:kernel/naive_type_checker.dart' show NaiveTypeChecker;

import 'package:kernel/text/ast_to_text.dart' show Printer;

import 'package:testing/testing.dart'
    show
        ChainContext,
        Expectation,
        ExpectationSet,
        Result,
        StdioProcess,
        Step,
        TestDescription;

import '../fasta/testing/suite.dart' show CompilationSetup;
import '../test_utils.dart';

final Uri platformBinariesLocation = computePlatformBinariesLocation();

mixin MatchContext implements ChainContext {
  bool get updateExpectations;

  String get updateExpectationsOption;

  bool get canBeFixWithUpdateExpectations;

  @override
  ExpectationSet get expectationSet;

  Expectation get expectationFileMismatch =>
      expectationSet["ExpectationFileMismatch"];

  Expectation get expectationFileMismatchSerialized =>
      expectationSet["ExpectationFileMismatchSerialized"];

  Expectation get expectationFileMissing =>
      expectationSet["ExpectationFileMissing"];

  Future<Result<O>> match<O>(String suffix, String actual, Uri uri, O output,
      {Expectation? onMismatch, bool? overwriteUpdateExpectationsWith}) async {
    bool updateExpectations =
        overwriteUpdateExpectationsWith ?? this.updateExpectations;
    actual = actual.trim();
    if (actual.isNotEmpty) {
      actual += "\n";
    }
    File expectedFile = new File("${uri.toFilePath()}$suffix");
    if (await expectedFile.exists()) {
      String expected = await expectedFile.readAsString();
      if (expected.replaceAll("\r\n", "\n") != actual) {
        if (updateExpectations) {
          return updateExpectationFile<O>(expectedFile.uri, actual, output);
        }
        String diff = await runDiff(expectedFile.uri, actual);
        onMismatch ??= expectationFileMismatch;
        return new Result<O>(
            output, onMismatch, "$uri doesn't match ${expectedFile.uri}\n$diff",
            autoFixCommand: onMismatch == expectationFileMismatch
                ? updateExpectationsOption
                : null,
            canBeFixWithUpdateExpectations:
                onMismatch == expectationFileMismatch &&
                    canBeFixWithUpdateExpectations);
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

  @override
  String get name => "print";

  @override
  Future<Result<ComponentResult>> run(ComponentResult result, _) async {
    Component component = result.component;

    StringBuffer sb = new StringBuffer();
    await CompilerContext.runWithDefaultOptions((compilerContext) async {
      compilerContext.uriToSource.addAll(component.uriToSource);

      Printer printer = new Printer(sb,
          showOffsets: result.compilationSetup.folderOptions.showOffsets);
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

  @override
  String get name => "typeCheck";

  @override
  Future<Result<ComponentResult>> run(
      ComponentResult result, ChainContext context) {
    Component component = result.component;
    ErrorFormatter errorFormatter = new ErrorFormatter();
    NaiveTypeChecker checker =
        new NaiveTypeChecker(errorFormatter, component, ignoreSdk: true);
    checker.checkComponent(component);
    if (errorFormatter.numberOfFailures == 0) {
      return new Future.value(pass(result));
    } else {
      errorFormatter.failures.forEach(print);
      print('------- Found ${errorFormatter.numberOfFailures} errors -------');
      return new Future.value(new Result<ComponentResult>(
          null,
          context.expectationSet["TypeCheckError"],
          '${errorFormatter.numberOfFailures} type errors'));
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
      {this.serializeFirst = false, required this.isLastMatchStep});

  @override
  String get name => "match expectations";

  @override
  Future<Result<ComponentResult>> run(
      ComponentResult result, MatchContext context) {
    Component component = result.component;

    Component componentToText = component;
    if (serializeFirst) {
      if (result.compilationSetup.folderOptions.showOffsets) {
        // Not all offsets are serialized so the output won't match and there is
        // currently no reason to check this.
        // TODO(johnniwinther): Find a way to avoid or verify the discrepancies.
        return new Future.value(new Result<ComponentResult>.pass(result));
      }
      // TODO(johnniwinther): Use library filter instead.
      List<Library> sdkLibraries =
          component.libraries.where((l) => !result.isUserLibrary(l)).toList();

      ByteSink sink = new ByteSink();
      Component writeMe = new Component(
          libraries: component.libraries.where(result.isUserLibrary).toList())
        ..setMainMethodAndMode(null, false, component.mode);
      writeMe.uriToSource.addAll(component.uriToSource);
      if (component.problemsAsJson != null) {
        writeMe.problemsAsJson =
            new List<String>.from(component.problemsAsJson!);
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

    List<Iterable<String>> errors = result.compilationSetup.errors;
    Set<String> reportedErrors = <String>{};
    for (Iterable<String> message in errors) {
      reportedErrors.add(message.join('\n'));
    }
    Set<String> problemsAsJson = <String>{};
    void addProblemsAsJson(List<String>? problems) {
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
    Printer printer = new Printer(buffer,
        showOffsets: result.compilationSetup.folderOptions.showOffsets)
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
    addConstantCoverageToExpectation(result.component, buffer,
        skipImportUri: (Uri? importUri) =>
            !result.isUserLibraryImportUri(importUri));

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
            : context.expectationFileMismatch,
        overwriteUpdateExpectationsWith: serializeFirst ? false : null);
  }
}

class WriteDill extends Step<ComponentResult, ComponentResult, ChainContext> {
  final bool skipVm;

  const WriteDill({required this.skipVm});

  @override
  String get name => "write .dill";

  @override
  Future<Result<ComponentResult>> run(ComponentResult result, _) async {
    Component component = result.component;
    Procedure? mainMethod = component.mainMethod;
    bool writeToFile = !skipVm;
    if (mainMethod == null) {
      writeToFile = false;
    } else {
      Statement? mainBody = mainMethod.function.body;
      if (mainBody is Block && mainBody.statements.isEmpty ||
          mainBody is ReturnStatement && mainBody.expression == null) {
        writeToFile = false;
      }
    }
    ByteSink sink = new ByteSink();
    bool good = false;
    try {
      // TODO(johnniwinther): Use library filter instead.
      // Avoid serializing the sdk.
      Component userCode = new Component(
          nameRoot: component.root,
          uriToSource: new Map<Uri, Source>.from(component.uriToSource));
      userCode.setMainMethodAndMode(
          component.mainMethodName, true, component.mode);
      List<Library> auxiliaryLibraries = [];
      for (Library library in component.libraries) {
        bool includeLibrary;
        if (library.importUri.isScheme("dart")) {
          if (result.isUserLibrary(library)) {
            // dart:test, test:extra etc as used will say yes to being a user
            // library.
            includeLibrary = true;
          } else if (library.isSynthetic) {
            // OK --- serialize that.
            includeLibrary = true;
          } else {
            // Skip serialization of "real" platform libraries.
            includeLibrary = false;
          }
        } else if (result.isUserLibrary(library)) {
          includeLibrary = true;
        } else {
          // This library is neither part of the user libraries nor part of the
          // platform libraries. To run this, we need to include it in the
          // dill.
          auxiliaryLibraries.add(library);
          includeLibrary = false;
        }
        if (includeLibrary) {
          userCode.libraries.add(library);
        }
      }

      // We first ensure that we can serialize with possible references to
      // libraries that aren't included in the serialization.
      new BinaryPrinter(sink).writeComponentFile(userCode);

      // We then serialize with any such libraries to
      //   a) ensure that we can do that too, and that
      //   b) the output is complete (modulo the platform) so that the VM can
      //      actually run it.
      if (auxiliaryLibraries.isNotEmpty) {
        userCode.libraries.addAll(auxiliaryLibraries);
        sink = new ByteSink();
        new BinaryPrinter(sink).writeComponentFile(userCode);
      }
      good = true;
    } catch (e, s) {
      return fail(result, e, s);
    } finally {
      if (good && writeToFile) {
        Directory tmp = await Directory.systemTemp.createTemp();
        Uri uri = tmp.uri.resolve("generated.dill");
        File generated = new File.fromUri(uri);
        IOSink ioSink = generated.openWrite();
        ioSink.add(sink.builder.takeBytes());
        await ioSink.close();
        result = new ComponentResult(
            result.description,
            result.component,
            result.userLibraries,
            result.compilationSetup,
            result.sourceTarget,
            uri);
        print("Wrote component to `${generated.path}`.");
      } else {
        print("Wrote component to memory.");
      }
    }
    return pass(result);
  }
}

class ReadDill extends Step<Uri, Uri, ChainContext> {
  const ReadDill();

  @override
  String get name => "read .dill";

  @override
  Future<Result<Uri>> run(Uri uri, _) {
    try {
      loadComponentFromBinary(uri.toFilePath());
    } catch (e, s) {
      return new Future.value(fail(uri, e, s));
    }
    return new Future.value(pass(uri));
  }
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
  final Uri? outputUri;
  final CompilationSetup compilationSetup;
  final KernelTarget sourceTarget;
  final List<String> extraConstantStrings = [];

  ComponentResult(this.description, this.component, this.userLibraries,
      this.compilationSetup, this.sourceTarget,
      [this.outputUri]);

  bool isUserLibrary(Library library) {
    return isUserLibraryImportUri(library.importUri);
  }

  bool isUserLibraryImportUri(Uri? importUri) {
    return userLibraries.contains(importUri);
  }

  ProcessedOptions get options => compilationSetup.options;
}
