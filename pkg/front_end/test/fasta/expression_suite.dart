// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.test.expression_test;

import "dart:io" show File, IOSink;
import 'dart:typed_data' show Uint8List;

import 'package:_fe_analyzer_shared/src/util/colors.dart' as colors;
import "package:front_end/src/api_prototype/compiler_options.dart"
    show CompilerOptions, DiagnosticMessage;
import 'package:front_end/src/api_prototype/experimental_flags.dart';
import 'package:front_end/src/api_prototype/expression_compilation_tools.dart'
    show createDefinitionsWithTypes, createTypeParametersWithBounds;
import 'package:front_end/src/api_prototype/incremental_kernel_generator.dart'
    show IncrementalCompilerResult;
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
import 'package:front_end/src/fasta/kernel/utils.dart'
    show serializeComponent, serializeProcedure;
import 'package:front_end/src/testing/compiler_common.dart';
import "package:kernel/ast.dart"
    show
        Class,
        Component,
        Constructor,
        DartType,
        DynamicType,
        Field,
        Library,
        Member,
        Procedure,
        TypeParameter;
import 'package:kernel/target/targets.dart' show TargetFlags;
import 'package:kernel/text/ast_to_text.dart' show Printer;
import "package:testing/src/log.dart" show splitLines;
import "package:testing/testing.dart"
    show Chain, ChainContext, Result, Step, TestDescription, runMe;
import 'package:vm/target/vm.dart' show VmTarget;
import "package:yaml/yaml.dart" show YamlMap, YamlList, loadYamlNode;

import '../testing_utils.dart' show checkEnvironment;
import '../utils/kernel_chain.dart' show runDiff, openWrite;
import 'testing/suite.dart';

class Context extends ChainContext {
  final CompilerContext compilerContext;
  final CompilerContext compilerContextNoNNBD;
  final List<DiagnosticMessage> errors;

  @override
  final List<Step> steps;

  final bool fuzz;
  final Set<Uri> fuzzedLibraries = {};
  int fuzzCompiles = 0;

  Context(this.compilerContext, this.compilerContextNoNNBD, this.errors,
      bool updateExpectations, this.fuzz)
      : steps = <Step>[
          const ReadTest(),
          const CompileExpression(),
          new MatchProcedureExpectations(".expect",
              updateExpectations: updateExpectations)
        ];

  ProcessedOptions get options => compilerContext.options;

  MemoryFileSystem get fileSystem => options.fileSystem as MemoryFileSystem;

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
  Procedure? compiledProcedure;
  List<DiagnosticMessage> errors;

  CompilationResult(this.compiledProcedure, this.errors);

  String printResult(Uri entryPoint, Context context) {
    StringBuffer buffer = new StringBuffer();
    buffer.write("Errors: {\n");
    for (DiagnosticMessage error in errors) {
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
      printer.visitProcedure(compiledProcedure!);
      printer.writeConstantTable(new Component());
    }
    Uri base = entryPoint.resolve(".");
    return "$buffer".replaceAll("$base", "org-dartlang-testcase:///");
  }
}

class TestCase {
  final TestDescription description;

  final Map<String, String> sources;

  final Uri entryPoint;

  final List<String> definitions;

  final List<String> definitionTypes;

  final List<String> typeDefinitions;

  final List<String> typeBounds;

  final List<String> typeDefaults;

  final bool isStaticMethod;

  final Uri library;

  final String? className;

  final String? methodName;

  String expression;

  List<CompilationResult> results = [];

  TestCase(
      this.description,
      this.sources,
      this.entryPoint,
      this.definitions,
      this.definitionTypes,
      this.typeDefinitions,
      this.typeBounds,
      this.typeDefaults,
      this.isStaticMethod,
      this.library,
      this.className,
      this.methodName,
      this.expression);

  @override
  String toString() {
    return "TestCase("
        "$sources, "
        "$entryPoint, "
        "$definitions, "
        "$definitionTypes, "
        "$typeDefinitions,"
        "$typeBounds,"
        "$typeDefaults,"
        "$library, "
        "$className, "
        "static = $isStaticMethod)";
  }
}

class MatchProcedureExpectations extends Step<List<TestCase>, Null, Context> {
  final String suffix;
  final bool updateExpectations;

  const MatchProcedureExpectations(this.suffix,
      {this.updateExpectations = false});

  @override
  String get name => "match expectations";

  @override
  Future<Result<Null>> run(List<TestCase> tests, Context context) async {
    String actual = "";
    for (TestCase test in tests) {
      String primary = test.results.first.printResult(test.entryPoint, context);
      actual += primary;
      for (int i = 1; i < test.results.length; ++i) {
        String secondary =
            test.results[i].printResult(test.entryPoint, context);
        if (primary != secondary) {
          return fail(
              null,
              "Multiple expectations don't match on $test:"
              "\nFirst expectation:\n$actual\n"
              "\nSecond expectation:\n$secondary\n");
        }
      }
    }
    TestCase test = tests.first;
    Uri testUri = test.description.uri;
    File expectedFile = new File("${testUri.toFilePath()}$suffix");
    if (await expectedFile.exists()) {
      String expected = await expectedFile.readAsString();
      if (expected.replaceAll("\r\n", "\n").trim() != actual.trim()) {
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

  @override
  String get name => "read test";

  @override
  Future<Result<List<TestCase>>> run(
      TestDescription description, Context context) async {
    context.reset();
    Uri uri = description.uri;
    String contents = await new File.fromUri(uri).readAsString();

    Uri entryPoint = toTestUri('main.dart');
    List<String> definitions = <String>[];
    List<String> definitionTypes = <String>[];
    List<String> typeDefinitions = <String>[];
    List<String> typeBounds = <String>[];
    List<String> typeDefaults = <String>[];
    bool isStaticMethod = false;
    Uri? library;
    String? className;
    String? methodName;
    String? expression;

    dynamic maps = loadYamlNode(contents, sourceUrl: uri);
    if (maps is YamlMap) maps = [maps];

    final List<TestCase> tests = [];
    Map<String, String> sources = {};
    for (YamlMap map in maps) {
      for (String key in map.keys) {
        dynamic value = map[key];
        if (key == "sources") {
          if (value is String) {
            sources['main.dart'] = value;
          } else if (value is YamlMap) {
            value.forEach((key, value) {
              sources[key as String] = value as String;
            });
          }
        } else if (key == "entry_point") {
          entryPoint = toTestUri(value as String);
        } else if (key == "position") {
          Uri uri = entryPoint.resolveUri(Uri.parse(value as String));
          library = uri.removeFragment();
          if (uri.fragment != '') {
            className = uri.fragment;
          }
        } else if (key == "method") {
          methodName = value as String;
        } else if (key == "definitions") {
          definitions = (value as YamlList).map((x) => x as String).toList();
        } else if (key == "definition_types") {
          definitionTypes =
              (value as YamlList).map((x) => x as String).toList();
        } else if (key == "type_definitions") {
          typeDefinitions =
              (value as YamlList).map((x) => x as String).toList();
        } else if (key == "type_bounds") {
          typeBounds = (value as YamlList).map((x) => x as String).toList();
        } else if (key == "type_defaults") {
          typeDefaults = (value as YamlList).map((x) => x as String).toList();
        } else if (key == "static") {
          isStaticMethod = value;
        } else if (key == "expression") {
          expression = value;
        } else {
          throw new UnsupportedError("Unknown key: ${key}");
        }
      }
      library ??= entryPoint;
      if (expression == null) {
        return new Result.fail(tests, "No expression to compile.");
      }

      TestCase test = new TestCase(
          description,
          sources,
          entryPoint,
          definitions,
          definitionTypes,
          typeDefinitions,
          typeBounds,
          typeDefaults,
          isStaticMethod,
          library,
          className,
          methodName,
          expression);
      tests.add(test);
    }
    return new Result.pass(tests);
  }
}

class CompileExpression extends Step<List<TestCase>, List<TestCase>, Context> {
  const CompileExpression();

  @override
  String get name => "compile expression";

  // Compile [test.expression], update [test.errors] with results.
  // As a side effect - verify that generated procedure can be serialized.
  Future<void> compileExpression(
      TestCase test,
      IncrementalCompiler compiler,
      IncrementalCompiler? compilerNoNNBD,
      IncrementalCompilerResult compilerResult,
      Context context) async {
    Map<String, DartType>? definitions = createDefinitionsWithTypes(
        compilerResult.classHierarchy?.knownLibraries,
        test.definitionTypes,
        test.definitions);

    if (definitions == null) {
      definitions = {};
      for (String name in test.definitions) {
        definitions[name] = new DynamicType();
      }
    }
    List<TypeParameter>? typeParams = createTypeParametersWithBounds(
        compilerResult.classHierarchy?.knownLibraries,
        test.typeBounds,
        test.typeDefaults,
        test.typeDefinitions);
    if (typeParams == null) {
      typeParams = [];
      for (String name in test.typeDefinitions) {
        typeParams
            .add(new TypeParameter(name, new DynamicType(), new DynamicType()));
      }
    }

    Procedure? compiledProcedure = await compiler.compileExpression(
      test.expression,
      definitions,
      typeParams,
      "debugExpr",
      test.library,
      className: test.className,
      methodName: test.methodName,
      isStatic: test.isStaticMethod,
    );
    List<DiagnosticMessage> errors = context.takeErrors();
    test.results.add(new CompilationResult(compiledProcedure, errors));
    if (compiledProcedure != null) {
      // Confirm we can serialize generated procedure.
      compilerResult.component.computeCanonicalNames();
      List<int> list = serializeProcedure(compiledProcedure);
      assert(list.length > 0);
    }

    if (context.fuzz) {
      await fuzz(compiler, compilerNoNNBD!, compilerResult, context);
    }
  }

  Future<void> fuzz(
      IncrementalCompiler compiler,
      IncrementalCompiler compilerNoNNBD,
      IncrementalCompilerResult compilerResult,
      Context context) async {
    for (Library lib in compilerResult.classHierarchy!.knownLibraries) {
      if (!context.fuzzedLibraries.add(lib.importUri)) continue;

      for (Member m in lib.members) {
        await fuzzMember(m, compiler, compilerNoNNBD, lib.importUri, context);
      }

      for (Class c in lib.classes) {
        for (Member m in c.members) {
          await fuzzMember(m, compiler, compilerNoNNBD, lib.importUri, context);
        }
      }
    }
  }

  Future<void> fuzzMember(
      Member m,
      IncrementalCompiler compiler,
      IncrementalCompiler compilerNoNNBD,
      Uri libraryUri,
      Context context) async {
    String expression = m.name.text;
    if (m is Field || (m is Procedure && m.isGetter)) {
      // fields and getters are fine as-is
    } else if (m is Procedure && !m.isGetter) {
      expression = "$expression()";
    } else if (m is Constructor) {
      if (m.parent is! Class) {
        return;
      }
      Class parent = m.parent as Class;
      if (m.name.text != "") {
        expression = "${parent.name}.${m.name.text}()";
      } else {
        expression = "${parent.name}()";
      }
    } else {
      throw "Didn't know ${m.runtimeType}";
    }

    String? className;
    if (m.parent is Class && m is! Constructor) {
      Class parent = m.parent as Class;
      className = parent.name;
    }

    await fuzzTryCompile(compiler, compilerNoNNBD, "$expression", libraryUri,
        className, !m.isInstanceMember, context);
    if (className != null && !m.isInstanceMember) {
      await fuzzTryCompile(compiler, compilerNoNNBD, "$className.$expression",
          libraryUri, null, !m.isInstanceMember, context);
    }
    await fuzzTryCompile(compiler, compilerNoNNBD, "$expression.toString()",
        libraryUri, className, !m.isInstanceMember, context);
    if (className != null && !m.isInstanceMember) {
      await fuzzTryCompile(
          compiler,
          compilerNoNNBD,
          "$className.$expression.toString()",
          libraryUri,
          null,
          !m.isInstanceMember,
          context);
    }
    await fuzzTryCompile(
        compiler,
        compilerNoNNBD,
        "$expression.toString() == '42'",
        libraryUri,
        className,
        !m.isInstanceMember,
        context);
    if (className != null && !m.isInstanceMember) {
      await fuzzTryCompile(
          compiler,
          compilerNoNNBD,
          "$className.$expression.toString() == '42'",
          libraryUri,
          null,
          !m.isInstanceMember,
          context);
    }
    await fuzzTryCompile(
        compiler,
        compilerNoNNBD,
        "() { var x = $expression.toString(); x == '42'; }()",
        libraryUri,
        className,
        !m.isInstanceMember,
        context);
    if (className != null && !m.isInstanceMember) {
      await fuzzTryCompile(
          compiler,
          compilerNoNNBD,
          "() { var x = $className.$expression.toString(); x == '42'; }()",
          libraryUri,
          null,
          !m.isInstanceMember,
          context);
    }
  }

  Future<void> fuzzTryCompile(
      IncrementalCompiler compiler,
      IncrementalCompiler compilerNoNNBD,
      String expression,
      Uri libraryUri,
      String? className,
      bool isStatic,
      Context context) async {
    context.fuzzCompiles++;
    print("Fuzz compile #${context.fuzzCompiles} "
        "('$expression' in $libraryUri $className)");
    {
      Procedure? compiledProcedure = await compiler.compileExpression(
        expression,
        {},
        [],
        "debugExpr",
        libraryUri,
        className: className,
        isStatic: isStatic,
      );
      context.takeErrors();
      if (compiledProcedure != null) {
        // Confirm we can serialize generated procedure.
        List<int> list = serializeProcedure(compiledProcedure);
        assert(list.length > 0);
      }
    }
    {
      Procedure? compiledProcedure = await compilerNoNNBD.compileExpression(
        expression,
        {},
        [],
        "debugExpr",
        libraryUri,
        className: className,
        isStatic: isStatic,
      );
      context.takeErrors();
      if (compiledProcedure != null) {
        // Confirm we can serialize generated procedure.
        List<int> list = serializeProcedure(compiledProcedure);
        assert(list.length > 0);
      }
    }
  }

  @override
  Future<Result<List<TestCase>>> run(
      List<TestCase> tests, Context context) async {
    for (TestCase test in tests) {
      test.sources.forEach((String fileName, String source) {
        context.fileSystem
            .entityForUri(toTestUri(fileName))
            .writeAsStringSync(source);
      });

      IncrementalCompiler sourceCompiler =
          new IncrementalCompiler(context.compilerContext);
      IncrementalCompilerResult sourceCompilerResult =
          await sourceCompiler.computeDelta(entryPoints: [test.entryPoint]);
      Component component = sourceCompilerResult.component;
      List<DiagnosticMessage> errors = context.takeErrors();
      if (!errors.isEmpty) {
        return fail(
            tests,
            "Couldn't compile entry-point: "
            "${errors.map((e) => e.plainTextFormatted.first).toList()}");
      }
      Uri dillFileUri = toTestUri("${test.description.shortName}.dill");
      Uri dillFileNoNNBDUri =
          toTestUri("${test.description.shortName}.no.nnbd.dill");
      Uint8List dillData = await serializeComponent(component);
      context.fileSystem.entityForUri(dillFileUri).writeAsBytesSync(dillData);
      Set<Uri> beforeFuzzedLibraries = context.fuzzedLibraries.toSet();
      IncrementalCompiler? sourceCompilerNoNNBD;
      if (context.fuzz) {
        sourceCompilerNoNNBD =
            new IncrementalCompiler(context.compilerContextNoNNBD);
        IncrementalCompilerResult sourceCompilerNoNNBDResult =
            await sourceCompilerNoNNBD
                .computeDelta(entryPoints: [test.entryPoint]);
        Component componentNoNNBD = sourceCompilerNoNNBDResult.component;
        Uint8List dillDataNoNNBD = await serializeComponent(componentNoNNBD);
        context.fileSystem
            .entityForUri(dillFileNoNNBDUri)
            .writeAsBytesSync(dillDataNoNNBD);
        context.takeErrors();
      }
      await compileExpression(test, sourceCompiler, sourceCompilerNoNNBD,
          sourceCompilerResult, context);

      IncrementalCompiler dillCompiler =
          new IncrementalCompiler(context.compilerContext, dillFileUri);
      IncrementalCompilerResult dillCompilerResult =
          await dillCompiler.computeDelta(entryPoints: [test.entryPoint]);
      component = dillCompilerResult.component;
      component.computeCanonicalNames();

      errors = context.takeErrors();
      // Since it compiled successfully from source, the bootstrap-from-Dill
      // should also succeed without errors.
      assert(errors.isEmpty);

      IncrementalCompiler? dillCompilerNoNNBD;
      if (context.fuzz) {
        dillCompilerNoNNBD = new IncrementalCompiler(
            context.compilerContextNoNNBD, dillFileNoNNBDUri);
        IncrementalCompilerResult dillCompilerNoNNBDResult =
            await dillCompilerNoNNBD
                .computeDelta(entryPoints: [test.entryPoint]);
        Component componentNoNNBD = dillCompilerNoNNBDResult.component;
        componentNoNNBD.computeCanonicalNames();
        context.takeErrors();
      }

      context.fuzzedLibraries.clear();
      context.fuzzedLibraries.addAll(beforeFuzzedLibraries);
      await compileExpression(
          test, dillCompiler, dillCompilerNoNNBD, dillCompilerResult, context);
    }
    return new Result.pass(tests);
  }
}

Future<Context> createContext(
    Chain suite, Map<String, String> environment) async {
  const Set<String> knownEnvironmentKeys = {
    UPDATE_EXPECTATIONS,
    "fuzz",
  };
  checkEnvironment(environment, knownEnvironmentKeys);

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
    ..explicitExperimentalFlags = {}
    ..allowedExperimentalFlagsForTesting = const AllowedExperimentalFlags();

  final ProcessedOptions options =
      new ProcessedOptions(options: optionBuilder, inputs: [entryPoint]);

  final CompilerOptions optionBuilderNoNNBD = new CompilerOptions()
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

  final ProcessedOptions optionsNoNNBD =
      new ProcessedOptions(options: optionBuilderNoNNBD, inputs: [entryPoint]);

  final bool updateExpectations = environment[UPDATE_EXPECTATIONS] == "true";

  final bool fuzz = environment["fuzz"] == "true";

  final CompilerContext compilerContext = new CompilerContext(options);
  final CompilerContext compilerContextNoNNBD =
      new CompilerContext(optionsNoNNBD);

  // Disable colors to ensure that expectation files are the same across
  // platforms and independent of stdin/stderr.
  colors.enableColors = false;

  return new Context(
      compilerContext, compilerContextNoNNBD, errors, updateExpectations, fuzz);
}

void main([List<String> arguments = const []]) =>
    runMe(arguments, createContext, configurationPath: "../../testing.json");
