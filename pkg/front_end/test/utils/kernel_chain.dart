// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.testing.kernel_chain;

import 'dart:async';

import 'dart:io' show Directory, File, IOSink, Platform;

import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/scanner/abstract_scanner.dart'
    show ScannerConfiguration;
import 'package:_fe_analyzer_shared/src/scanner/token.dart';

import 'package:_fe_analyzer_shared/src/scanner/utf8_bytes_scanner.dart'
    show Utf8BytesScanner;

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
        LibraryPart,
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

import '../fasta/testing/suite.dart' show CompilationSetup, CompileMode;

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

class ErrorCommentChecker
    extends Step<ComponentResult, ComponentResult, ChainContext> {
  final CompileMode compileMode;
  const ErrorCommentChecker(this.compileMode);
  static const bool throwOnNoMatch = false;

  @override
  String get name => "ErrorCommentChecker";

  static const Set<String> ignoreBecauseOfFailures = {
    "extension_types/conflicting_static_and_instance",
    "extension_types/implements_conflicts",
    "general/bounds_enums",
    "general/bounds_type_parameters",
    "general/covariant_equals",
    "general/getter_vs_setter_type",
    "general/nested_variance",
    "general/new_as_selector",
    "general/top_level_variance",
    "general/type_variable_uses",
    "generic_metadata/alias_from_opt_in",
    "inference/block_bodied_lambdas_infer_bottom_sync",
    "inference/future_then_conditional",
    "inference/future_then_ifNull",
    "inference/generic_methods_infer_js_builtin",
    "inference/instantiate_to_bounds_generic2_has_bound_defined_after",
    "inference/instantiate_to_bounds_generic2_has_bound_defined_before",
    "inference/void_return_type_subtypes_dynamic",
    "nnbd_mixed/hierarchy/in_dill_out_in/in_out_in",
    "nnbd_mixed/hierarchy/in_out_dill_in/in_out_in",
    "nnbd/getter_vs_setter_type_nnbd",
    "nnbd/getter_vs_setter_type",
    "nnbd/null_access",
    "patterns/exhaustiveness/bool_switch",
    "patterns/exhaustiveness/enum_switch",
    "patterns/for_final_variable",
    "patterns/pattern_types",
    "records/type_record_as_supertype"
  };

  @override
  Future<Result<ComponentResult>> run(
      ComponentResult result, ChainContext context) {
    if (compileMode != CompileMode.full) return Future.value(pass(result));
    // TODO(jensj): Delete this once failures are fixed.
    if (ignoreBecauseOfFailures.contains(result.description.shortName)) {
      return Future.value(pass(result));
    }

    Component component = result.component;
    for (Library lib in component.libraries) {
      if (!result.userLibraries.contains(lib.importUri)) continue;
      if (!lib.fileUri.isScheme("file")) continue;
      List<Uri> uris = [];
      List<String> filenames = [];
      for (LibraryPart part in lib.parts) {
        // This is a bit simplistic but will probably work for our use here.
        uris.add(lib.fileUri.resolve(part.partUri));
        filenames.add(uris.last.pathSegments.last);
      }
      uris.add(lib.fileUri);
      filenames.add(uris.last.pathSegments.last);

      Set<String> expectProblemOn = {};
      Set<String> expectNoProblemOn = {};
      for (Uri uri in uris) {
        Set<int> expectErrorOnLines = {};
        Set<int> expectNoErrorOnLines = {};
        Map<int, List<CommentToken>> linesToComments =
            extractCommentsFromLines(uri);
        categorizeCommentLines(
            linesToComments, expectErrorOnLines, expectNoErrorOnLines);
        for (int line in expectErrorOnLines) {
          expectProblemOn.add("${uri.pathSegments.last}:$line");
        }
        for (int line in expectNoErrorOnLines) {
          expectNoProblemOn.add("${uri.pathSegments.last}:$line");
        }
      }

      // Now check.
      if (expectProblemOn.isNotEmpty || expectNoProblemOn.isNotEmpty) {
        List<String> failures = [];
        Set<String> notYetSeen = new Set<String>.of(expectProblemOn);
        // Sanity check: No overlap between error and no-error expectations.
        Set<String> overlap = expectProblemOn.intersection(expectNoProblemOn);
        if (overlap.isNotEmpty) {
          for (String fileAndLine in overlap) {
            failures.add("Test error: "
                "$fileAndLine is marked as both error and no error.");
          }
        }

        List<String>? libraryProblems = lib.problemsAsJson;
        RegExp extractLineRegExp = RegExp(
            "(${filenames.map((e) => RegExp.escape(e)).join("|")}):(\\d+)");

        if (libraryProblems != null) {
          for (String jsonString in libraryProblems) {
            DiagnosticMessageFromJson message =
                new DiagnosticMessageFromJson.fromJson(jsonString);
            // By taking all of these we accept it if it's just mentioned in a
            // context message too. Is that the precision we want?
            for (String plainTextProblem in message.plainTextFormatted) {
              List<RegExpMatch> matches =
                  extractLineRegExp.allMatches(plainTextProblem).toList();
              if (matches.isEmpty && throwOnNoMatch) {
                throw "Couldn't extract any offsets from "
                    "'$plainTextProblem' with '$extractLineRegExp'";
              }
              for (RegExpMatch match in matches) {
                String lineString = match.group(0)!;
                notYetSeen.remove(lineString);
                if (expectNoProblemOn.contains(lineString)) {
                  failures.add("Found error at $lineString "
                      "but didn't expect any:\n"
                      "$plainTextProblem");
                }
              }
            }
          }
        }

        for (String line in notYetSeen) {
          failures.add("Expected error on $line but didn't find any.");
        }

        if (failures.isNotEmpty) {
          return new Future.value(new Result<ComponentResult>(
              result,
              context.expectationSet["ErrorCommentCheckFailure"],
              "Found ${failures.length} failures:\n\n * "
              "${failures.join("\n\n * ")}\n"));
        }
      }
    }

    return Future.value(pass(result));
  }

  void categorizeCommentLines(Map<int, List<CommentToken>> linesToComments,
      Set<int> expectErrorOnLines, Set<int> expectNoErrorOnLines) {
    for (MapEntry<int, List<CommentToken>> entry in linesToComments.entries) {
      for (CommentToken comment in entry.value) {
        String message = comment.lexeme.trim().toLowerCase();
        while (message.startsWith("//") || message.startsWith("/*")) {
          message = message.substring(2).trim();
        }
        // TODO(jensj): Possibly reduce these cases by updating tests.
        // See discussion in
        // https://dart-review.googlesource.com/c/sdk/+/346301.
        if (message == "error" ||
            message == "error." ||
            message == "error */" ||
            message == "error*/" ||
            message.startsWith("error in strong mode") ||
            message.startsWith("error:") ||
            message.startsWith("error,") ||
            message.startsWith("error.") ||
            message.startsWith("error - ") ||
            message.startsWith("error (") ||
            message.startsWith("error on ") ||
            message.startsWith("error in ") ||
            message.startsWith("error since ") ||
            message.startsWith("error because ") ||
            message.startsWith("not ok.") ||
            message.startsWith("note: illegal ") ||
            message.startsWith("parse error:") ||
            message.startsWith("parse error,") ||
            message.startsWith("compile-time error") ||
            message.endsWith(" compile-time error")) {
          expectErrorOnLines.add(entry.key);
        } else if (message == "ok" ||
            message == "ok." ||
            message == "ok," ||
            message == "ok */" ||
            message.startsWith("ok: ") ||
            message.startsWith("ok, ") ||
            message.startsWith("ok (") ||
            message.startsWith("ok because ") ||
            message.startsWith("ok to ") ||
            message.startsWith("now ok") ||
            message.startsWith("no error.") ||
            message.startsWith("no error:") ||
            message.startsWith("no error ") ||
            message.startsWith("not a compile time error") ||
            message.startsWith("not an error") ||
            message == "shouldn't result in a compile-time error.") {
          expectNoErrorOnLines.add(entry.key);
        }
      }
    }
  }

  Map<int, List<CommentToken>> extractCommentsFromLines(Uri uri) {
    if (!uri.isScheme("file")) return const {};
    File f = new File.fromUri(uri);
    if (!f.existsSync()) return const {};
    Uint8List rawBytes = f.readAsBytesSync();

    Uint8List bytes = new Uint8List(rawBytes.length + 1);
    bytes.setRange(0, rawBytes.length, rawBytes);

    Utf8BytesScanner scanner = new Utf8BytesScanner(
      bytes,
      configuration: const ScannerConfiguration(
          enableExtensionMethods: true,
          enableNonNullable: true,
          enableTripleShift: true),
      includeComments: true,
      languageVersionChanged: (scanner, languageVersion) {
        // Nothing - but don't overwrite the previous settings.
      },
    );
    Token firstToken = scanner.tokenize();
    List<int> lineStarts = scanner.lineStarts;

    Token? token = firstToken;
    Token? previousToken;
    Source lineStartsHelper = new Source(lineStarts, const [], null, null);
    Map<int, List<CommentToken>> linesToComments = {};
    while (token != null && !token.isEof) {
      CommentToken? precedingComments = token.precedingComments;
      while (precedingComments != null) {
        int commentLine = lineStartsHelper
            .getLocation(Uri.base /* dummy */, precedingComments.offset)
            .line;
        int tokenLine = lineStartsHelper
            .getLocation(Uri.base /* dummy */, token.offset)
            .line;
        int likelyAboutLine = tokenLine;
        if (previousToken != null) {
          int previousTokenLine = lineStartsHelper
              .getLocation(Uri.base /* dummy */, previousToken.offset)
              .line;
          if (previousTokenLine == commentLine) likelyAboutLine = commentLine;
        }
        if (!precedingComments.lexeme.startsWith("// Copyright (c)") &&
            !precedingComments.lexeme
                .startsWith("// for details. All rights reserved.") &&
            !precedingComments.lexeme.startsWith("// BSD-style license")) {
          (linesToComments[likelyAboutLine] ??= []).add(precedingComments);
        }

        Token? next = precedingComments.next;
        if (next is CommentToken) {
          precedingComments = next;
        } else {
          precedingComments = null;
        }
      }
      previousToken = token;
      token = token.next;
    }
    return linesToComments;
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
      // We are running from something like out/ReleaseX64/dart-sdk/bin/dart
      String search = binariesPath.substring(
          0, binariesPath.length - "lib/_internal/".length);
      actual = _replaceSdkLocation(actual, search, "sdk/");
    } else {
      // We are running from something like out/ReleaseX64/dart
      actual = _replaceSdkLocation(actual, "sdk/", "sdk/");
    }
    actual = actual.replaceAll("$base", "org-dartlang-testcase:///");
    actual = actual.replaceAll("\\n", "\n");
    return context.match<ComponentResult>(suffix, actual, uri, result,
        onMismatch: serializeFirst
            ? context.expectationFileMismatchSerialized
            : context.expectationFileMismatch,
        overwriteUpdateExpectationsWith: serializeFirst ? false : null);
  }

  /// Replace SDK locations starting with [path] with [replacement] and '*'
  /// instead of the line/column.
  ///
  /// For instance replacing
  ///
  ///     out/ReleaseX64/dart-sdk/lib/core/enum.dart:101:13
  ///
  /// with
  ///
  ///     sdk/lib/core/enum.dart:*
  ///
  /// This is done to avoid expectations to depend on the actual location
  /// of the SDK or the position within the SDK file.
  String _replaceSdkLocation(String text, String path, String replacement) {
    // Replace path with line/column.
    RegExp regExp = new RegExp(
        '^// ${RegExp.escape(path)}([^:\r\n]*):\\d+:\\d+:',
        multiLine: true);
    text = text.replaceAllMapped(
        regExp, (Match match) => '// $replacement${match[1]}:*:');
    // Replace path with no line/column.
    return text.replaceAll(path, replacement);
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
    // TODO(johnniwinther): Support patch libraries user libraries.
    return userLibraries.contains(importUri);
  }

  ProcessedOptions get options => compilationSetup.options;
}
