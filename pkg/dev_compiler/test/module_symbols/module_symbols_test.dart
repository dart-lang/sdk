// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:io' show Directory, File;

import 'package:dev_compiler/dev_compiler.dart';
import 'package:dev_compiler/src/kernel/command.dart';
import 'package:dev_compiler/src/kernel/module_symbols.dart';
import 'package:kernel/ast.dart' show Component, Library;
import 'package:test/test.dart';

import '../shared_test_options.dart';

class TestCompiler {
  final SetupCompilerOptions setup;

  TestCompiler(this.setup);

  Future<JSCode> compile({Uri input, Uri packages}) async {
    // Initialize incremental compiler and create component.
    setup.options.packagesFileUri = packages;
    var compiler = DevelopmentIncrementalCompiler(setup.options, input);
    var component = await compiler.computeDelta();
    component.computeCanonicalNames();

    // Initialize DDC.
    var moduleName = 'foo.dart';
    var classHierarchy = compiler.getClassHierarchy();
    var compilerOptions = SharedCompilerOptions(
        replCompile: true,
        moduleName: moduleName,
        soundNullSafety: setup.soundNullSafety,
        moduleFormats: [setup.moduleFormat],
        emitDebugSymbols: true);
    var coreTypes = compiler.getCoreTypes();

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
  Directory tempDir;
  final String source;
  Uri input;
  Uri packages;
  File file;

  TestDriver(this.options, this.source) {
    var systemTempDir = Directory.systemTemp;
    tempDir = systemTempDir.createTempSync('foo bar');

    input = tempDir.uri.resolve('foo.dart');
    file = File.fromUri(input)..createSync();
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

  Future<JSCode> compile() async =>
      await TestCompiler(options).compile(input: input, packages: packages);

  void cleanUp() {
    tempDir.delete(recursive: true);
  }
}

class NullSafetyTestOption {
  final String description;
  final bool soundNullSafety;

  NullSafetyTestOption(this.description, this.soundNullSafety);
}

void main() async {
  for (var mode in [
    NullSafetyTestOption('Sound Mode:', true),
    NullSafetyTestOption('Weak Mode:', false)
  ]) {
    group(mode.description, () {
      var options = SetupCompilerOptions(soundNullSafety: mode.soundNullSafety);
      group('simple class debug symbols', () {
        TestDriver driver;
        ClassSymbol classSymbol;
        final source = '''
          ${options.dartLangComment}

          class A {}
          ''';
        setUpAll(() async {
          driver = TestDriver(options, source);
          var result = await driver.compile();
          classSymbol = result.symbols.classes.single;
        });
        tearDownAll(() {
          driver.cleanUp();
        });
        test('has name', () async {
          expect(classSymbol.name, equals('A'));
        });
        test('is not abstract', () async {
          expect(classSymbol.isAbstract, isFalse);
        });
        // TODO test isConst
        test('has no superclassId', () async {
          expect(classSymbol.superClassId, isNull);
        });
        test('empty interfacesIds', () async {
          expect(classSymbol.interfaceIds, isEmpty);
        });
        test('empty typeParameters', () async {
          expect(classSymbol.typeParameters, isEmpty);
        });
        test('has localId', () async {
          expect(classSymbol.localId, equals('A'));
        });
        test('has library scopeId', () async {
          expect(classSymbol.scopeId, endsWith('package:foo/foo.dart'));
        });
        group('location', () {
          test('has scriptId', () async {
            expect(classSymbol.location.scriptId, endsWith('/foo.dart'));
          });
          test('has start token', () async {
            expect(classSymbol.location.tokenPos,
                22 + options.dartLangComment.length);
          });
          test('has end token', () async {
            expect(classSymbol.location.endTokenPos,
                31 + options.dartLangComment.length);
          });
        });
        test('no fields', () async {
          expect(classSymbol.variableIds, isEmpty);
        });
        // TODO only has the implicit constructor in scopeIds.
      });
      group('abstract class debug symbols', () {
        TestDriver driver;
        ClassSymbol classSymbol;
        final source = '''
          ${options.dartLangComment}

          abstract class A {}
          ''';
        setUpAll(() async {
          driver = TestDriver(options, source);
          var result = await driver.compile();
          classSymbol = result.symbols.classes.single;
        });
        tearDownAll(() {
          driver.cleanUp();
        });
        test('is abstract', () async {
          expect(classSymbol.isAbstract, isTrue);
        });
      });
      group('class extends debug symbols', () {
        TestDriver driver;
        ClassSymbol classSymbol;
        final source = '''
          ${options.dartLangComment}

          class A extends B {}

          class B {}
          ''';
        setUpAll(() async {
          driver = TestDriver(options, source);
          var result = await driver.compile();
          classSymbol =
              result.symbols.classes.where((c) => c.localId == 'A').single;
        });
        tearDownAll(() {
          driver.cleanUp();
        });
        test('has superclass', () async {
          expect(classSymbol.superClassId, 'B');
        });
      });
      group('class implements debug symbols', () {
        TestDriver driver;
        List<ClassSymbol> classSymbols;
        final source = '''
          ${options.dartLangComment}

          class A implements B, C {}

          class B implements C {}

          class C {}
          ''';
        setUpAll(() async {
          driver = TestDriver(options, source);
          var result = await driver.compile();
          classSymbols = result.symbols.classes;
        });
        tearDownAll(() {
          driver.cleanUp();
        });
        test('single implements', () async {
          var classSymbol = classSymbols.singleWhere((c) => c.localId == 'B');
          expect(classSymbol.interfaceIds, orderedEquals(['C']));
        });
        test('multiple implements', () async {
          var classSymbol = classSymbols.singleWhere((c) => c.localId == 'A');
          expect(classSymbol.interfaceIds, orderedEquals(['B', 'C']));
        });
      });
    });
  }
}
