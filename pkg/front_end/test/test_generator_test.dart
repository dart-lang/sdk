// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show exitCode, File, stdout;

import 'package:front_end/src/api_prototype/compiler_options.dart';
import 'package:front_end/src/api_prototype/memory_file_system.dart';
import 'package:front_end/src/compute_platform_binaries_location.dart';
import 'package:front_end/src/fasta/kernel/utils.dart';
import 'package:front_end/src/fasta/messages.dart';
import 'package:kernel/binary/ast_to_binary.dart';

import 'package:kernel/kernel.dart' show Component;

import 'incremental_load_from_dill_suite.dart' as helper;

main() async {
  TestCompiler compiler = await TestCompiler.initialize();
  bool hasNewline = true;
  int numErrors = 0;
  List<String> errorSource = [];
  for (Generator outerContext in generateOuterContext()) {
    for (Generator innerContext
        in generateInnerContext(outerContext.typeParameters)) {
      for (Generator expression in generateExpression([]
        ..addAll(outerContext.typeParameters)
        ..addAll(innerContext.typeParameters))) {
        String source = outerContext
            .generate(innerContext.generate(expression.generate("")));
        String compileResult = await compiler.compile(source);
        if (compileResult != "") {
          if (!hasNewline) print("");
          hasNewline = true;
          print(source);
          print(compileResult);
          print("\n\n----------\n\n");
          numErrors++;
          errorSource.add(source);
        } else {
          hasNewline = false;
          stdout.write(".");
        }
      }
    }
  }

  if (numErrors > 0) {
    if (!hasNewline) print("");
    hasNewline = true;
    print("Found $numErrors errors on these programs:");
    print("");
    for (String source in errorSource) {
      print(source);
      print("----");
    }
    exitCode = 1;
  }
  if (!hasNewline) print("");
}

const Set<Code> ignoredCodes = {
  codeInvalidAssignmentError,
  codeTypeVariableInStaticContext,
  codeNonInstanceTypeVariableUse,
  codeExtensionDeclaresInstanceField,
  codeExtraneousModifier,
};

class TestCompiler {
  final Uri testUri;
  final MemoryFileSystem fs;
  final Set<String> formattedErrors;
  final Set<String> formattedWarnings;
  final helper.TestIncrementalCompiler compiler;
  final List<Code> formattedErrorsCodes;
  final List<Code> formattedWarningsCodes;

  TestCompiler._(
      this.testUri,
      this.fs,
      this.formattedErrors,
      this.formattedWarnings,
      this.formattedErrorsCodes,
      this.formattedWarningsCodes,
      this.compiler);

  Future<String> compile(String src) async {
    StringBuffer sb = new StringBuffer();
    fs.entityForUri(testUri).writeAsStringSync(src);
    compiler.invalidate(testUri);
    Component result = await compiler.computeDelta(entryPoints: [testUri]);
    Iterator<Code> codeIterator = formattedWarningsCodes.iterator;
    for (String warning in formattedWarnings) {
      codeIterator.moveNext();
      Code code = codeIterator.current;
      if (ignoredCodes.contains(code)) continue;
      sb.writeln("Warning: $warning ($code)");
    }
    codeIterator = formattedErrorsCodes.iterator;
    for (String error in formattedErrors) {
      codeIterator.moveNext();
      Code code = codeIterator.current;
      if (ignoredCodes.contains(code)) continue;
      sb.writeln("Error: $error ($code)");
    }
    formattedWarnings.clear();
    formattedWarningsCodes.clear();
    formattedErrors.clear();
    formattedErrorsCodes.clear();

    try {
      ByteSink byteSink = new ByteSink();
      final BinaryPrinter printer = new BinaryPrinter(byteSink);
      printer.writeComponentFile(result);
    } catch (e, st) {
      sb.writeln("Error: Crash when serializing: $e ($st)");
    }

    return sb.toString();
  }

  static Future<TestCompiler> initialize() async {
    final Uri base = Uri.parse("org-dartlang-test:///");
    final Uri sdkSummary = base.resolve("vm_platform_strong.dill");
    final Uri sdkRoot = computePlatformBinariesLocation(forceBuildDir: true);
    Uri platformUri = sdkRoot.resolve("vm_platform_strong.dill");
    final List<int> sdkSummaryData =
        await new File.fromUri(platformUri).readAsBytes();
    MemoryFileSystem fs = new MemoryFileSystem(base);
    fs.entityForUri(sdkSummary).writeAsBytesSync(sdkSummaryData);

    CompilerOptions options = helper.getOptions();
    options.fileSystem = fs;
    options.sdkRoot = null;
    options.sdkSummary = sdkSummary;
    options.omitPlatform = true;
    options.verify = true;

    final Set<String> formattedErrors = new Set<String>();
    final Set<String> formattedWarnings = new Set<String>();
    final List<Code> formattedErrorsCodes = <Code>[];
    final List<Code> formattedWarningsCodes = <Code>[];

    options.onDiagnostic = (DiagnosticMessage message) {
      String stringId = message.ansiFormatted.join("\n");
      if (message is FormattedMessage) {
        stringId = message.toJsonString();
      } else {
        throw "Unsupported currently";
      }
      FormattedMessage formattedMessage = message;
      if (message.severity == Severity.error) {
        if (!formattedErrors.add(stringId)) {
          throw "Got the same message twice: ${stringId}";
        }
        formattedErrorsCodes.add(formattedMessage.code);
      } else if (message.severity == Severity.warning) {
        if (!formattedWarnings.add(stringId)) {
          throw "Got the same message twice: ${stringId}";
        }
        formattedWarningsCodes.add(formattedMessage.code);
      }
    };

    Uri testUri = base.resolve("test.dart");
    helper.TestIncrementalCompiler compiler =
        new helper.TestIncrementalCompiler(options, testUri);

    return new TestCompiler._(testUri, fs, formattedErrors, formattedWarnings,
        formattedErrorsCodes, formattedWarningsCodes, compiler);
  }
}

Iterable<Generator> generateOuterContext() sync* {
  yield new Generator([], "", ""); // top-level.
  yield new Generator([], "class C {\n", "\n}");
  yield new Generator(["T1"], "class C<T1> {\n", "\n}");
  yield new Generator(["T1"],
      "class NotList<NT1>{}\nclass C<T1> extends NotList<T1> {\n", "\n}");
  yield new Generator([], "extension E on String {\n", "\n}");
  yield new Generator(["E1"], "extension E<E1> on String {\n", "\n}");
  yield new Generator(["E1"], "extension E<E1> on List<E1> {\n", "\n}");
}

Iterable<Generator> generateInnerContext(
    List<String> knownTypeParameters) sync* {
  for (String static in ["", "static "]) {
    yield new Generator([], "${static}int method() {\nreturn ", ";\n}");
    yield new Generator(
        ["T2"], "${static}int method<T2>() {\n  return ", ";\n}");
    for (String typeParameter in knownTypeParameters) {
      yield new Generator(
          [], "${static}$typeParameter method() {\nreturn ", ";\n}");
    }
    yield new Generator([], "${static}int field = ", ";");
    yield new Generator([], "${static}int field = () { return ", "; }();");
    yield new Generator([], "${static}var field = ", ";");
    yield new Generator([], "${static}var field = () { return ", "; }();");

    for (String typeParameter in knownTypeParameters) {
      yield new Generator(["T2"], "${static}int field = <T2>() { return ",
          "; }<$typeParameter>();");
      yield new Generator([], "${static}${typeParameter} field = ", ";");
      yield new Generator(
          [], "${static}${typeParameter} field = () { return ", "; }();");
    }
  }
}

Iterable<Generator> generateExpression(List<String> knownTypeParameters) sync* {
  yield new Generator([], "42", "");
  for (String typeParameter in knownTypeParameters) {
    yield new Generator([], "() { $typeParameter x = null; return x; }()", "");
  }
}

class Generator {
  final List<String> typeParameters;
  final String beforePlug;
  final String afterPlug;

  Generator(this.typeParameters, this.beforePlug, this.afterPlug);

  String generate(String plug) {
    return "// @dart = 2.9\n${beforePlug}${plug}${afterPlug}";
  }
}
