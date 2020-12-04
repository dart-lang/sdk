// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library fasta.test.expression_test;

import "dart:convert" show JsonEncoder;

import "dart:io" show File, IOSink;

import 'package:_fe_analyzer_shared/src/util/colors.dart' as colors;

import "package:front_end/src/api_prototype/compiler_options.dart"
    show CompilerOptions, DiagnosticMessage;
import 'package:front_end/src/api_prototype/experimental_flags.dart';

import "package:front_end/src/api_prototype/memory_file_system.dart"
    show MemoryFileSystem;

import "package:front_end/src/api_prototype/terminal_color_support.dart"
    show printDiagnosticMessage;

import 'package:front_end/src/base/processed_options.dart'
    show ProcessedOptions;

import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;

import 'package:front_end/src/fasta/compiler_context.dart' show CompilerContext;

import 'package:front_end/src/fasta/incremental_compiler.dart'
    show IncrementalCompiler;

import "package:kernel/ast.dart"
    show Procedure, Component, DynamicType, DartType, TypeParameter;

import 'package:kernel/target/targets.dart' show TargetFlags;

import 'package:kernel/text/ast_to_text.dart' show Printer;

import "package:testing/src/log.dart" show splitLines;

import "package:testing/testing.dart"
    show Chain, ChainContext, Result, Step, TestDescription, runMe;

import 'package:vm/target/vm.dart' show VmTarget;

import "package:yaml/yaml.dart" show YamlMap, YamlList, loadYamlNode;

import '../../lib/src/fasta/kernel/utils.dart'
    show writeComponentToFile, serializeProcedure;

import '../utils/kernel_chain.dart' show runDiff, openWrite;

const JsonEncoder json = const JsonEncoder.withIndent("  ");

class Context extends ChainContext {
  final CompilerContext compilerContext;
  final List<DiagnosticMessage> errors;

  final List<Step> steps;

  Context(this.compilerContext, this.errors, bool updateExpectations)
      : steps = <Step>[
          const ReadTest(),
          const CompileExpression(),
          new MatchProcedureExpectations(".expect",
              updateExpectations: updateExpectations)
        ];

  ProcessedOptions get options => compilerContext.options;

  MemoryFileSystem get fileSystem => options.fileSystem;

  Future<T> runInContext<T>(Future<T> action(CompilerContext c)) {
    return compilerContext.runInContext<T>(action);
  }

  void reset() {
    errors.clear();
  }

  List<DiagnosticMessage> takeErrors() {
    List<DiagnosticMessage> result = new List<DiagnosticMessage>.from(errors);
    errors.clear();
    return result;
  }
}

class CompilationResult {
  Procedure compiledProcedure;
  List<DiagnosticMessage> errors;
  CompilationResult(this.compiledProcedure, this.errors);

  String printResult(Uri entryPoint, Context context) {
    StringBuffer buffer = new StringBuffer();
    buffer.write("Errors: {\n");
    for (var error in errors) {
      for (String message in error.plainTextFormatted) {
        for (String line in splitLines(message)) {
          buffer.write("  ");
          buffer.write(line);
        }
        buffer.write("\n");
        // TODO(jensj): Ignore context for now.
        // Remove once we have positions on type parameters.
        break;
      }
    }
    buffer.write("}\n");
    if (compiledProcedure == null) {
      buffer.write("<no procedure>");
    } else {
      Printer printer = new Printer(buffer);
      printer.visitProcedure(compiledProcedure);
      printer.writeConstantTable(new Component());
    }
    Uri base = entryPoint.resolve(".");
    return "$buffer".replaceAll("$base", "org-dartlang-testcase:///");
  }
}

class TestCase {
  final TestDescription description;

  final Uri entryPoint;

  final Uri import;

  final List<String> definitions;

  final List<String> typeDefinitions;

  final bool isStaticMethod;

  final Uri library;

  final String className;

  String expression;

  List<CompilationResult> results = [];

  TestCase(
      this.description,
      this.entryPoint,
      this.import,
      this.definitions,
      this.typeDefinitions,
      this.isStaticMethod,
      this.library,
      this.className,
      this.expression);

  String toString() {
    return "TestCase("
        "$entryPoint, "
        "$import, "
        "$definitions, "
        "$typeDefinitions,"
        "$library, "
        "$className, "
        "static = $isStaticMethod)";
  }

  String validate() {
    print(this);
    if (entryPoint == null) {
      return "No entryPoint.";
    }
    if (!(new File.fromUri(entryPoint)).existsSync()) {
      return "Entry point $entryPoint doesn't exist.";
    }
    if (library == null) {
      return "No enclosing node.";
    }
    if (expression == null) {
      return "No expression to compile.";
    }
    return null;
  }
}

class MatchProcedureExpectations extends Step<List<TestCase>, Null, Context> {
  final String suffix;
  final bool updateExpectations;

  const MatchProcedureExpectations(this.suffix,
      {this.updateExpectations: false});

  String get name => "match expectations";

  Future<Result<Null>> run(List<TestCase> tests, Context context) async {
    String actual = "";
    for (var test in tests) {
      var primary = test.results.first.printResult(test.entryPoint, context);
      actual += primary;
      for (int i = 1; i < test.results.length; ++i) {
        var secondary = test.results[i].printResult(test.entryPoint, context);
        if (primary != secondary) {
          return fail(
              null,
              "Multiple expectations don't match on $test:"
              "\nFirst expectation:\n$actual\n"
              "\nSecond expectation:\n$secondary\n");
        }
      }
    }
    var test = tests.first;
    Uri testUri = test.description.uri;
    File expectedFile = new File("${testUri.toFilePath()}$suffix");
    if (await expectedFile.exists()) {
      String expected = await expectedFile.readAsString();
      if (expected.trim() != actual.trim()) {
        if (!updateExpectations) {
          String diff = await runDiff(expectedFile.uri, actual);
          return fail(
              null, "$testUri doesn't match ${expectedFile.uri}\n$diff");
        }
      } else {
        return pass(null);
      }
    }
    if (updateExpectations) {
      await openWrite(expectedFile.uri, (IOSink sink) {
        sink.writeln(actual.trim());
      });
      return pass(null);
    } else {
      return fail(null, """
Please create file ${expectedFile.path} with this content:
$actual""");
    }
  }
}

class ReadTest extends Step<TestDescription, List<TestCase>, Context> {
  const ReadTest();

  String get name => "read test";

  Future<Result<List<TestCase>>> run(
      TestDescription description, Context context) async {
    context.reset();
    Uri uri = description.uri;
    String contents = await new File.fromUri(uri).readAsString();

    Uri entryPoint;
    Uri import;
    List<String> definitions = <String>[];
    List<String> typeDefinitions = <String>[];
    bool isStaticMethod = false;
    Uri library;
    String className;
    String expression;

    dynamic maps = loadYamlNode(contents, sourceUrl: uri);
    if (maps is YamlMap) maps = [maps];

    final List<TestCase> tests = [];
    for (YamlMap map in maps) {
      for (var _key in map.keys) {
        String key = _key;
        var value = map[key];

        if (key == "entry_point") {
          entryPoint = description.uri.resolveUri(Uri.parse(value as String));
        } else if (key == "import") {
          import = description.uri.resolveUri(Uri.parse(value as String));
        } else if (key == "position") {
          Uri uri = description.uri.resolveUri(Uri.parse(value as String));
          library = uri.removeFragment();
          if (uri.fragment != null && uri.fragment != '') {
            className = uri.fragment;
          }
        } else if (key == "definitions") {
          definitions = (value as YamlList).map((x) => x as String).toList();
        } else if (key == "type_definitions") {
          typeDefinitions =
              (value as YamlList).map((x) => x as String).toList();
        } else if (key == "static") {
          isStaticMethod = value;
        } else if (key == "expression") {
          expression = value;
        }
      }
      var test = new TestCase(description, entryPoint, import, definitions,
          typeDefinitions, isStaticMethod, library, className, expression);
      var result = test.validate();
      if (result != null) {
        return new Result.fail(tests, result);
      }
      tests.add(test);
    }
    return new Result.pass(tests);
  }
}

class CompileExpression extends Step<List<TestCase>, List<TestCase>, Context> {
  const CompileExpression();

  String get name => "compile expression";

  // Compile [test.expression], update [test.errors] with results.
  // As a side effect - verify that generated procedure can be serialized.
  void compileExpression(TestCase test, IncrementalCompiler compiler,
      Component component, Context context) async {
    Map<String, DartType> definitions = {};
    for (String name in test.definitions) {
      definitions[name] = new DynamicType();
    }
    List<TypeParameter> typeParams = [];
    for (String name in test.typeDefinitions) {
      typeParams.add(new TypeParameter(name, new DynamicType()));
    }

    Procedure compiledProcedure = await compiler.compileExpression(
        test.expression,
        definitions,
        typeParams,
        "debugExpr",
        test.library,
        test.className,
        test.isStaticMethod);
    List<DiagnosticMessage> errors = context.takeErrors();
    test.results.add(new CompilationResult(compiledProcedure, errors));
    if (compiledProcedure != null) {
      // Confirm we can serialize generated procedure.
      component.computeCanonicalNames();
      List<int> list = serializeProcedure(compiledProcedure);
      assert(list.length > 0);
    }
  }

  Future<Result<List<TestCase>>> run(
      List<TestCase> tests, Context context) async {
    for (var test in tests) {
      context.fileSystem.entityForUri(test.entryPoint).writeAsBytesSync(
          await new File.fromUri(test.entryPoint).readAsBytes());

      if (test.import != null) {
        context.fileSystem.entityForUri(test.import).writeAsBytesSync(
            await new File.fromUri(test.import).readAsBytes());
      }

      var sourceCompiler = new IncrementalCompiler(context.compilerContext);
      Component component =
          await sourceCompiler.computeDelta(entryPoints: [test.entryPoint]);
      var errors = context.takeErrors();
      if (!errors.isEmpty) {
        return fail(tests, "Couldn't compile entry-point: $errors");
      }
      Uri dillFileUri = new Uri(
          scheme: test.entryPoint.scheme, path: test.entryPoint.path + ".dill");
      File dillFile = new File.fromUri(dillFileUri);
      if (!await dillFile.exists()) {
        await writeComponentToFile(component, dillFileUri);
        context.fileSystem.entityForUri(dillFileUri).writeAsBytesSync(
            await new File.fromUri(dillFileUri).readAsBytes());
      }
      compileExpression(test, sourceCompiler, component, context);

      var dillCompiler =
          new IncrementalCompiler(context.compilerContext, dillFileUri);
      component =
          await dillCompiler.computeDelta(entryPoints: [test.entryPoint]);
      component.computeCanonicalNames();
      await dillFile.delete();

      errors = context.takeErrors();
      // Since it compiled successfully from source, the bootstrap-from-Dill
      // should also succeed without errors.
      assert(errors.isEmpty);
      compileExpression(test, dillCompiler, component, context);
    }
    return new Result.pass(tests);
  }
}

Future<Context> createContext(
    Chain suite, Map<String, String> environment) async {
  final Uri base = Uri.parse("org-dartlang-test:///");

  /// Unused because we supply entry points to [computeDelta] directly above.
  final Uri entryPoint = base.resolve("nothing.dart");

  /// The custom URI used to locate the dill file in the MemoryFileSystem.
  final Uri sdkSummary = base.resolve("vm_platform_strong.dill");

  /// The actual location of the dill file.
  final Uri sdkSummaryFile =
      computePlatformBinariesLocation(forceBuildDir: true)
          .resolve("vm_platform_strong.dill");

  final MemoryFileSystem fs = new MemoryFileSystem(base);

  fs
      .entityForUri(sdkSummary)
      .writeAsBytesSync(await new File.fromUri(sdkSummaryFile).readAsBytes());

  final List<DiagnosticMessage> errors = <DiagnosticMessage>[];

  final CompilerOptions optionBuilder = new CompilerOptions()
    ..target = new VmTarget(new TargetFlags())
    ..verbose = true
    ..omitPlatform = true
    ..fileSystem = fs
    ..sdkSummary = sdkSummary
    ..onDiagnostic = (DiagnosticMessage message) {
      printDiagnosticMessage(message, print);
      errors.add(message);
    }
    ..environmentDefines = const {}
    ..explicitExperimentalFlags = {ExperimentalFlag.nonNullable: false}
    ..allowedExperimentalFlagsForTesting = const AllowedExperimentalFlags();

  final ProcessedOptions options =
      new ProcessedOptions(options: optionBuilder, inputs: [entryPoint]);

  final bool updateExpectations = environment["updateExpectations"] == "true";

  final CompilerContext compilerContext = new CompilerContext(options);

  // Disable colors to ensure that expectation files are the same across
  // platforms and independent of stdin/stderr.
  colors.enableColors = false;

  return new Context(compilerContext, errors, updateExpectations);
}

main([List<String> arguments = const []]) =>
    runMe(arguments, createContext, configurationPath: "../../testing.json");
