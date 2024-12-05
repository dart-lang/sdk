// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, File;

import 'package:dev_compiler/src/command/command.dart';
import 'package:dev_compiler/src/command/options.dart' show Options;
import 'package:dev_compiler/src/compiler/module_builder.dart'
    show ModuleFormat;
import 'package:dev_compiler/src/kernel/compiler.dart' show ProgramCompiler;
import 'package:dev_compiler/src/kernel/module_symbols.dart';
import 'package:kernel/ast.dart' show Component, Library;

import '../shared_test_options.dart';

class TestCompiler {
  final SetupCompilerOptions setup;

  TestCompiler(this.setup);

  Future<JSCode> compile({required Uri input, required Uri packages}) async {
    // Initialize incremental compiler and create component.
    setup.options.packagesFileUri = packages;
    var compiler = DevelopmentIncrementalCompiler(setup.options, input);
    var compilerResult = await compiler.computeDelta();
    var component = compilerResult.component;
    component.computeCanonicalNames();
    var errors = setup.errors.where((e) => e.contains('Error'));
    if (errors.isNotEmpty) {
      throw Exception('Compilation failed: \n${errors.join('\n')}');
    }

    // Initialize DDC.
    var moduleName = 'foo.dart';
    var classHierarchy = compilerResult.classHierarchy!;
    var compilerOptions = Options(
        replCompile: true,
        moduleName: moduleName,
        soundNullSafety: setup.soundNullSafety,
        moduleFormats: [setup.moduleFormat],
        emitDebugSymbols: true);
    var coreTypes = compilerResult.coreTypes;

    final importToSummary = Map<Library, Component>.identity();
    final summaryToModule = Map<Component, String>.identity();
    for (var lib in component.libraries) {
      importToSummary[lib] = component;
    }
    summaryToModule[component] = moduleName;

    // Compile Kernel AST to JS AST.
    var kernel2jsCompiler = ProgramCompiler(component, classHierarchy,
        compilerOptions, importToSummary, summaryToModule,
        coreTypes: coreTypes);
    var moduleTree = kernel2jsCompiler.emitModule(component);

    // Compile JS AST to code.
    return jsProgramToCode(moduleTree, ModuleFormat.amd,
        emitDebugSymbols: true,
        compiler: kernel2jsCompiler,
        component: component);
  }
}

class TestDriver {
  final SetupCompilerOptions options;
  late final Directory tempDir;
  late final Uri input;
  late final Uri packages;

  TestDriver(this.options, String source) {
    var systemTempDir = Directory.systemTemp;
    tempDir = systemTempDir.createTempSync('foo bar');

    input = tempDir.uri.resolve('foo.dart');
    var file = File.fromUri(input)..createSync();
    file.writeAsStringSync(source);

    packages = tempDir.uri.resolve('package_config.json');
    file = File.fromUri(packages)..createSync();
    file.writeAsStringSync('''
      {
        "configVersion": 2,
        "packages": [
          {
            "name": "foo",
            "rootUri": "./",
            "packageUri": "./"
          }
        ]
      }
      ''');
  }

  Future<ModuleSymbols> compileAndGetSymbols() async {
    var result =
        await TestCompiler(options).compile(input: input, packages: packages);
    var symbols = result.symbols;
    if (symbols == null) {
      throw Exception('No symbols found in compilation result.');
    }
    return symbols;
  }

  void cleanUp() {
    tempDir.delete(recursive: true);
    options.errors.clear();
  }
}
