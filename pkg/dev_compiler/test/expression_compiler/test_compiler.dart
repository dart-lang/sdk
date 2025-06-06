// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' show File;

import 'package:dev_compiler/src/command/command.dart';
import 'package:dev_compiler/src/command/options.dart' show Options;
import 'package:dev_compiler/src/compiler/module_builder.dart';
import 'package:dev_compiler/src/kernel/compiler.dart' show ProgramCompiler;
import 'package:dev_compiler/src/kernel/compiler_new.dart'
    show LibraryBundleCompiler;
import 'package:dev_compiler/src/kernel/expression_compiler.dart'
    show ExpressionCompiler;
import 'package:dev_compiler/src/kernel/module_metadata.dart';
import 'package:front_end/src/api_unstable/ddc.dart' as fe;
import 'package:kernel/ast.dart' show Component, Library;
import 'package:path/path.dart' as p;
import 'package:source_maps/source_maps.dart' as source_maps;

import '../shared_test_options.dart';

class TestCompilationResult {
  final String? result;
  final bool isSuccess;

  TestCompilationResult(this.result, this.isSuccess);
}

class TestExpressionCompiler {
  final SetupCompilerOptions setup;
  final Component component;
  final ExpressionCompiler compiler;
  final ModuleMetadata? metadata;
  final source_maps.SingleMapping sourceMap;

  TestExpressionCompiler._(
    this.setup,
    this.component,
    this.compiler,
    this.metadata,
    this.sourceMap,
  );

  static Future<TestExpressionCompiler> init(
    SetupCompilerOptions setup, {
    required Uri input,
    required Uri output,
    Uri? packages,
    Map<String, bool> experiments = const {},
  }) async {
    setup.diagnosticMessages.clear();
    setup.errors.clear();
    // Initialize the incremental compiler and module component.
    // TODO: extend this for multi-module compilations by storing separate
    // compilers/components/names per module.
    setup.options.packagesFileUri = packages;
    setup.options.explicitExperimentalFlags.addAll(
      fe.parseExperimentalFlags(
        experiments,
        onError: (message) => throw Exception(message),
      ),
    );
    var frontend = DevelopmentIncrementalCompiler(setup.options, input);
    var compilerResult = await frontend.computeDelta();
    var component = compilerResult.component;
    component.computeCanonicalNames();
    // Initialize DDC.
    var moduleName = p.basenameWithoutExtension(output.toFilePath());

    var classHierarchy = compilerResult.classHierarchy;
    var compilerOptions = Options(
      replCompile: true,
      moduleName: moduleName,
      experiments: experiments,
      emitDebugMetadata: true,
      canaryFeatures: setup.canaryFeatures,
      enableAsserts: setup.enableAsserts,
      moduleFormats: [setup.moduleFormat],
    );
    var coreTypes = compilerResult.coreTypes;

    final importToSummary = Map<Library, Component>.identity();
    final summaryToModule = Map<Component, String>.identity();
    for (var lib in component.libraries) {
      importToSummary[lib] = component;
    }
    summaryToModule[component] = moduleName;

    var kernel2jsCompiler = compilerOptions.emitLibraryBundle
        ? LibraryBundleCompiler(
            component,
            classHierarchy,
            compilerOptions,
            importToSummary,
            summaryToModule,
            coreTypes: coreTypes,
          )
        : ProgramCompiler(
            component,
            classHierarchy,
            compilerOptions,
            importToSummary,
            summaryToModule,
            coreTypes: coreTypes,
          );
    var module = kernel2jsCompiler.emitModule(component);

    var moduleFormat = compilerOptions.emitLibraryBundle
        ? ModuleFormat.ddcLibraryBundle
        : setup.moduleFormat;

    // Perform a full compile, writing the compiled JS + sourcemap.
    var code = jsProgramToCode(
      module,
      moduleFormat,
      inlineSourceMap: compilerOptions.inlineSourceMap,
      buildSourceMap: compilerOptions.sourceMap,
      emitDebugMetadata: compilerOptions.emitDebugMetadata,
      emitDebugSymbols: compilerOptions.emitDebugSymbols,
      jsUrl: '$output',
      mapUrl: '$output.map',
      compiler: kernel2jsCompiler,
      component: component,
    );
    var codeBytes = utf8.encode(code.code);
    var sourceMapBytes = utf8.encode(json.encode(code.sourceMap));

    File(output.toFilePath()).writeAsBytesSync(codeBytes);
    File('${output.toFilePath()}.map').writeAsBytesSync(sourceMapBytes);

    // Save the expression compiler for future compilation.
    var compiler = ExpressionCompiler(
      setup.options,
      moduleFormat,
      setup.errors,
      frontend,
      kernel2jsCompiler,
      component,
    );

    if (setup.errors.isNotEmpty) {
      throw Exception('Compilation failed with: ${setup.errors}');
    }
    setup.diagnosticMessages.clear();
    setup.errors.clear();

    var sourceMap = source_maps.SingleMapping.fromJson(code.sourceMap!);
    return TestExpressionCompiler._(
      setup,
      component,
      compiler,
      code.metadata,
      sourceMap,
    );
  }

  // Line and column are 1-based.
  Future<TestCompilationResult> compileExpression({
    required Uri libraryUri,
    Uri? scriptUri,
    required int line,
    required int column,
    required Map<String, String> scope,
    required String expression,
  }) async {
    // clear previous errors
    setup.errors.clear();

    // At this time, no metadata is stored for the Dart SDK. This is one of the
    // reasons debugging and expression evaluation support is so limited within
    // the SDK.  When requesting evaluation of library level expressions, we can
    // ignore the lack of metadata and simply use the URI directly.
    String importUri;
    if (libraryUri.isScheme('dart')) {
      importUri = libraryUri.toString();
    } else {
      var libraryMetadata = metadataForLibraryUri(libraryUri);
      importUri = libraryMetadata.importUri;
    }
    var jsExpression = await compiler.compileExpressionToJs(
      importUri,
      scriptUri?.toString(),
      line,
      column,
      scope,
      expression,
    );
    if (setup.errors.isNotEmpty) {
      jsExpression = setup.errors.toString().replaceAll(
        RegExp(r'org-dartlang-debug:synthetic_debug_expression:[0-9]*:[0-9]*:'),
        '',
      );

      return TestCompilationResult(jsExpression, false);
    }

    return TestCompilationResult(jsExpression, true);
  }

  LibraryMetadata metadataForLibraryUri(Uri libraryUri) => metadata!
      .libraries
      .entries
      .firstWhere((entry) => entry.value.fileUri == '$libraryUri')
      .value;
}
