// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, File;

import 'package:dev_compiler/src/compiler/js_names.dart';
import 'package:dev_compiler/src/compiler/module_builder.dart';
import 'package:dev_compiler/src/compiler/shared_command.dart'
    show SharedCompilerOptions;
import 'package:dev_compiler/src/js_ast/js_ast.dart';
import 'package:dev_compiler/src/kernel/compiler.dart' show ProgramCompiler;
import 'package:dev_compiler/src/kernel/expression_compiler.dart'
    show ExpressionCompiler;
import 'package:kernel/ast.dart' show Component, Library;
import 'package:test/test.dart';
import 'package:vm/transformations/type_flow/utils.dart';

import '../shared_test_options.dart';

// TODO(annagrin): Replace javascript matching in tests below with evaluating
// the javascript and checking the result.
// See https://github.com/dart-lang/sdk/issues/41959

/// Convenience class describing JavaScript module
/// to ensure we have normalized module names
class Module {
  /// variable name used in JavaScript output to load the module
  /// example: file
  final String name;

  /// JavaScript module name used in trackLibraries
  /// example: packages/package/file.dart
  final String path;

  /// URI where the contents of the library that produces this module
  /// can be found
  /// example: /Users/../package/file.dart
  final Uri fileUri;

  /// Import URI for the library that generates this module.
  /// example: packages:package/file.dart
  final Uri importUri;

  Module(this.importUri, this.fileUri)
      : name = libraryUriToJsIdentifier(importUri),
        path = importUri.isScheme('package')
            ? 'packages/${importUri.path}'
            : importUri.path;

  String get package => importUri.toString();
  String get file => fileUri.path;

  @override
  String toString() =>
      'Name: \$name, File: \$file, Package: \$package, path: \$path';
}

class TestCompilationResult {
  final String result;
  final bool isSuccess;

  TestCompilationResult(this.result, this.isSuccess);
}

class TestCompiler {
  final SetupCompilerOptions setup;
  final Map<Uri, Module> _modules = {};
  late final ExpressionCompiler compiler;

  TestCompiler._(this.setup);

  static Future<TestCompiler> create(
      SetupCompilerOptions setup, Uri input, Uri packages) async {
    final testCompiler = TestCompiler._(setup);
    await testCompiler._createCompiler(input, packages);
    return testCompiler;
  }

  Future<TestCompilationResult> compile(
      {required Uri input,
      required int line,
      required int column,
      required Map<String, String> scope,
      required String expression}) async {
    // clear previous errors
    setup.errors.clear();

    // compile
    var jsExpression = await compiler.compileExpressionToJs(
        _libraryUriFor(input), line, column, scope, expression);

    if (setup.errors.isNotEmpty) {
      jsExpression = setup.errors.toString().replaceAll(
          RegExp(
              r'org-dartlang-debug:synthetic_debug_expression:[0-9]*:[0-9]*:'),
          '');

      return TestCompilationResult(jsExpression, false);
    }

    return TestCompilationResult(jsExpression!, true);
  }

  Future<void> _createCompiler(Uri input, Uri packages) async {
    // initialize incremental compiler and create component
    setup.options.packagesFileUri = packages;
    var frontend = DevelopmentIncrementalCompiler(setup.options, input);
    var compilerResult = await frontend.computeDelta();
    var component = compilerResult.component;
    component.computeCanonicalNames();

    // initialize ddc
    var moduleName = 'foo.dart';
    var classHierarchy = compilerResult.classHierarchy;
    var compilerOptions = SharedCompilerOptions(
      replCompile: true,
      moduleName: moduleName,
      soundNullSafety: setup.soundNullSafety,
      moduleFormats: [setup.moduleFormat],
      canaryFeatures: false,
    );
    var coreTypes = compilerResult.coreTypes;

    final importToSummary = Map<Library, Component>.identity();
    final summaryToModule = Map<Component, String>.identity();
    for (var lib in component.libraries) {
      importToSummary[lib] = component;
    }
    summaryToModule[component] = moduleName;

    var kernel2jsCompiler = ProgramCompiler(component, classHierarchy!,
        compilerOptions, importToSummary, summaryToModule,
        coreTypes: coreTypes);
    var moduleTree = kernel2jsCompiler.emitModule(component);

    {
      var opts = JavaScriptPrintingOptions(
          allowKeywordsInProperties: true, allowSingleLineIfStatements: true);
      var printer = SimpleJavaScriptPrintingContext();

      var tree = transformModuleFormat(setup.moduleFormat, moduleTree);
      tree.accept(Printer(opts, printer, localNamer: TemporaryNamer(tree)));
      var printed = printer.getText();
      debugPrint(printed);
    }

    _collectModules(component);

    // create expression compiler
    compiler = ExpressionCompiler(
      setup.options,
      setup.moduleFormat,
      setup.errors,
      frontend,
      kernel2jsCompiler,
      component,
    );
  }

  void _collectModules(Component component) {
    for (var library in component.libraries) {
      _modules[library.fileUri] = Module(library.importUri, library.fileUri);
    }
  }

  String _libraryUriFor(Uri input) => _modules[input]!.package;
}

class TestDriver {
  final SetupCompilerOptions options;
  late Directory tempDir;
  final String source;
  late Uri input;
  late Uri packages;
  late File file;
  int line;

  TestDriver(this.options, this.source) : line = _getEvaluationLine(source) {
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

  void delete() {
    tempDir.delete(recursive: true);
  }

  Future<TestCompiler> createCompiler() =>
      TestCompiler.create(options, input, packages);

  Future<TestCompilationResult> compile({
    required TestCompiler compiler,
    required Map<String, String> scope,
    required String expression,
  }) async {
    return compiler.compile(
        input: input,
        line: line,
        column: 1,
        scope: scope,
        expression: expression);
  }

  void checkResult(
    TestCompilationResult result, {
    String? expectedError,
    String? expectedResult,
  }) {
    var success = expectedError == null;
    var message = success ? expectedResult! : expectedError;

    expect(
        result,
        const TypeMatcher<TestCompilationResult>()
            .having((r) => _normalize(r.result), 'result', _matches(message))
            .having((r) => r.isSuccess, 'isSuccess', success));
  }

  Future<void> check({
    TestCompiler? compiler,
    required Map<String, String> scope,
    required String expression,
    String? expectedError,
    String? expectedResult,
  }) async {
    compiler ??= await createCompiler();
    var result =
        await compile(compiler: compiler, scope: scope, expression: expression);

    checkResult(result,
        expectedError: expectedError, expectedResult: expectedResult);
  }

  String _normalize(String text) {
    return text
        .replaceAll(RegExp('\'.*foo.dart\''), '\'foo.dart\'')
        .replaceAll(RegExp('".*foo.dart"'), '\'foo.dart\'');
  }

  Matcher _matches(String text) {
    var unIndented = RegExp.escape(text).replaceAll(RegExp('[ ]+'), '[ ]*');
    return matches(RegExp(unIndented, multiLine: true));
  }

  static int _getEvaluationLine(String source) {
    var placeholderRegExp = RegExp(r'/\* evaluation placeholder \*/');

    var lines = source.split('\n');
    for (var line = 0; line < lines.length; line++) {
      var content = lines[line];
      if (placeholderRegExp.firstMatch(content) != null) {
        return line + 1;
      }
    }
    return -1;
  }
}

void main() {
  for (var moduleFormat in [ModuleFormat.amd, ModuleFormat.ddc]) {
    group('Module format: $moduleFormat |', () {
      group('Unsound null safety |', () {
        runUnsoundTests(moduleFormat);
      });
    });
  }

  for (var moduleFormat in [ModuleFormat.amd, ModuleFormat.ddc]) {
    group('Module format: $moduleFormat |', () {
      group('Sound null safety |', () {
        runSoundTests(moduleFormat);
      });
    });
  }
}

void runUnsoundTests(ModuleFormat moduleFormat) {
  var options = SetupCompilerOptions(
    soundNullSafety: false,
    moduleFormat: moduleFormat,
  );

  group('Expression compilations on the same expression compiler |', () {
    var source = '''
          ${options.dartLangComment}
          main() {
          }

          void foo() {
            /* evaluation placeholder */
          }
          ''';

    late TestDriver driver;

    setUp(() {
      driver = TestDriver(options, source);
    });

    tearDown(() {
      driver.delete();
    });

    test('successful expression compilations', () async {
      var compiler = await driver.createCompiler();
      await driver.check(
          compiler: compiler,
          scope: <String, String>{},
          expression: 'true',
          expectedResult: '''
                (function() {
                  return true;
                }(
                  
                ))
                ''');
      await driver.check(
          compiler: compiler,
          scope: <String, String>{},
          expression: 'false',
          expectedResult: '''
                (function() {
                  return false;
                }(
                  
                ))
                ''');
    });

    test('some successful expression compilations', () async {
      var compiler = await driver.createCompiler();
      await driver.check(
          compiler: compiler,
          scope: <String, String>{},
          expression: 'true',
          expectedResult: '''
                (function() {
                  return true;
                }(
                  
                ))
                ''');
      await driver.check(
        compiler: compiler,
        scope: <String, String>{},
        expression: 'blah',
        expectedError: "Undefined name 'blah'",
      );
      await driver.check(
          compiler: compiler,
          scope: <String, String>{},
          expression: 'false',
          expectedResult: '''
                (function() {
                  return false;
                }(
                  
                ))
                ''');
    });

    test('failing expression compilations', () async {
      var compiler = await driver.createCompiler();
      await driver.check(
        compiler: compiler,
        scope: <String, String>{},
        expression: 'blah1',
        expectedError: "Undefined name 'blah1'",
      );
      await driver.check(
        compiler: compiler,
        scope: <String, String>{},
        expression: 'blah2',
        expectedError: "Undefined name 'blah2'",
      );
    });
  });

  group('Expression compiler import tests', () {
    var source = '''
          ${options.dartLangComment}
          import 'dart:io' show Directory;
          import 'dart:io' as p;
          import 'dart:convert' as p;
          
          main() {
            print(Directory.systemTemp);
            print(p.Directory.systemTemp);
            print(p.utf.decoder);
          }

          void foo() {
            /* evaluation placeholder */
          }
          ''';

    late TestDriver driver;

    setUp(() {
      driver = TestDriver(options, source);
    });

    tearDown(() {
      driver.delete();
    });

    test('expression referencing unnamed import', () async {
      await driver.check(
          scope: <String, String>{},
          expression: 'Directory.systemTemp',
          expectedResult: '''
            (function() {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const io = dart_sdk.io;
              return io.Directory.systemTemp;
            }(
              
            ))
            ''');
    });

    test('expression referencing named import', () async {
      await driver.check(
          scope: <String, String>{},
          expression: 'p.Directory.systemTemp',
          expectedResult: '''
            (function() {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const io = dart_sdk.io;
              return io.Directory.systemTemp;
            }(
              
            ))
            ''');
    });

    test('expression referencing another library with the same named import',
        () async {
      await driver.check(
          scope: <String, String>{},
          expression: 'p.utf8.decoder',
          expectedResult: '''
            (function() {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const convert = dart_sdk.convert;
              return convert.utf8.decoder;
            }(
              
            ))
            ''');
    });
  });

  group('Expression compiler tests for interactions with module containers:',
      () {
    var source = '''
          ${options.dartLangComment}
          class A {
            const A();
          }
          class B {
            const B();
          }
          void foo() {
            const a = A();
            var check = a is int;
            /* evaluation placeholder */
            return;
          }

          void main() => foo();
          ''';

    late TestDriver driver;
    setUp(() {
      driver = TestDriver(options, source);
    });

    tearDown(() {
      driver.delete();
    });

    test('evaluation that non-destructively appends to the type container',
        () async {
      await driver.check(
          scope: <String, String>{'a': 'null', 'check': 'null'},
          expression: 'a is String',
          expectedResult: '''
            (function(a, check) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const core = dart_sdk.core;
              const dart = dart_sdk.dart;
              var T = {
                StringL: () => (T.StringL = dart.constFn(dart.legacy(core.String)))()
              };
              return T.StringL().is(a);
            }(
              null,
              null
            ))
            ''');
    });

    test('evaluation that reuses the type container', () async {
      await driver.check(
          scope: <String, String>{'a': 'null', 'check': 'null'},
          expression: 'a is int',
          expectedResult: '''
            (function(a, check) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const core = dart_sdk.core;
              const dart = dart_sdk.dart;
              var T = {
                intL: () => (T.intL = dart.constFn(dart.legacy(core.int)))()
              };
              return T.intL().is(a);
            }(
              null,
              null
            ))
            ''');
    });

    test('evaluation that non-destructively appends to the constant container',
        () async {
      await driver.check(
          scope: <String, String>{'a': 'null', 'check': 'null'},
          expression: 'const B()',
          expectedResult: '''
            (function(a, check) {
             const dart_sdk = ${options.loadModule}('dart_sdk');
              const dart = dart_sdk.dart;
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              const CT = Object.create(null);
              dart.defineLazy(CT, {
                get C0() {
                  return C[0] = dart.const(Object.setPrototypeOf({
                  }, foo.B.prototype));
                }
              }, false);
              var C = [void 0];
              return C[0] || CT.C0;
            }(
              null,
              null
            ))
            ''');
    });

    test(
        'evaluation that reuses the constant container and canonicalizes properly',
        () async {
      await driver.check(
          scope: <String, String>{'a': 'null', 'check': 'null'},
          expression: 'a == const A()',
          expectedResult: '''
            (function(a, check) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const dart = dart_sdk.dart;
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              const CT = Object.create(null);
              dart.defineLazy(CT, {
                get C0() {
                  return C[0] = dart.const(Object.setPrototypeOf({
                  }, foo.A.prototype));
                }
              }, false);
              var C = [void 0];
              return dart.equals(a, C[0] || CT.C0);
            }(
              null,
              null
            ))
            ''');
    });
  });

  group('Expression compiler tests using extension symbols', () {
    var source = '''
          ${options.dartLangComment}
          void bar() {
            /* evaluation placeholder */
          }

          void main() => bar();
          ''';

    late TestDriver driver;
    setUp(() {
      driver = TestDriver(options, source);
    });

    tearDown(() {
      driver.delete();
    });

    test('map access', () async {
      await driver.check(
          scope: <String, String>{'inScope': '1', 'innerInScope': '0'},
          expression:
              '(Map<String, String> params) { return params["index"]; }({})',
          expectedResult: '''
            (function() {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const core = dart_sdk.core;
              const _js_helper = dart_sdk._js_helper;
              const dart = dart_sdk.dart;
              const dartx = dart_sdk.dartx;
              var T = {
                StringL: () => (T.StringL = dart.constFn(dart.legacy(core.String)))(),
                MapOfStringL\$StringL: () => (T.MapOfStringL\$StringL = dart.constFn(core.Map\$(T.StringL(), T.StringL())))(),
                MapLOfStringL\$StringL: () => (T.MapLOfStringL\$StringL = dart.constFn(dart.legacy(T.MapOfStringL\$StringL())))(),
                MapLOfStringL\$StringLToStringL: () => (T.MapLOfStringL\$StringLToStringL = dart.constFn(dart.fnType(T.StringL(), [T.MapLOfStringL\$StringL()])))(),
                IdentityMapOfStringL\$StringL: () => (T.IdentityMapOfStringL\$StringL = dart.constFn(_js_helper.IdentityMap\$(T.StringL(), T.StringL())))()
              };
              var S = {\$_get: dartx._get};
              return dart.fn(params => params[S.\$_get]("index"), T.MapLOfStringL\$StringLToStringL())(new (T.IdentityMapOfStringL\$StringL()).new());
            }(
              
            ))
            ''');
    });
  });
}

void runSoundTests(ModuleFormat moduleFormat) {
  var options = SetupCompilerOptions(
    soundNullSafety: true,
    moduleFormat: moduleFormat,
  );

  group('Expression compilations on the same expression compiler |', () {
    var source = '''
          ${options.dartLangComment}
          main() {
          }

          void foo() {
            /* evaluation placeholder */
          }
          ''';

    late TestDriver driver;

    setUp(() {
      driver = TestDriver(options, source);
    });

    tearDown(() {
      driver.delete();
    });

    test('successful expression compilations', () async {
      var compiler = await driver.createCompiler();
      await driver.check(
          compiler: compiler,
          scope: <String, String>{},
          expression: 'true',
          expectedResult: '''
                (function() {
                  return true;
                }(
                  
                ))
                ''');
      await driver.check(
          compiler: compiler,
          scope: <String, String>{},
          expression: 'false',
          expectedResult: '''
                (function() {
                  return false;
                }(
                  
                ))
                ''');
    });

    test('some successful expression compilations', () async {
      var compiler = await driver.createCompiler();
      await driver.check(
          compiler: compiler,
          scope: <String, String>{},
          expression: 'true',
          expectedResult: '''
                (function() {
                  return true;
                }(
                  
                ))
                ''');
      await driver.check(
        compiler: compiler,
        scope: <String, String>{},
        expression: 'blah',
        expectedError: "Undefined name 'blah'",
      );
      await driver.check(
          compiler: compiler,
          scope: <String, String>{},
          expression: 'false',
          expectedResult: '''
                (function() {
                  return false;
                }(
                  
                ))
                ''');
    });

    test('failing expression compilations', () async {
      var compiler = await driver.createCompiler();
      await driver.check(
        compiler: compiler,
        scope: <String, String>{},
        expression: 'blah1',
        expectedError: "Undefined name 'blah1'",
      );
      await driver.check(
        compiler: compiler,
        scope: <String, String>{},
        expression: 'blah2',
        expectedError: "Undefined name 'blah2'",
      );
    });
  });

  group('Expression compiler import tests', () {
    var source = '''
          ${options.dartLangComment}
          import 'dart:io' show Directory;
          import 'dart:io' as p;
          import 'dart:convert' as p;
          
          main() {
            print(Directory.systemTemp);
            print(p.Directory.systemTemp);
            print(p.utf.decoder);
          }

          void foo() {
            /* evaluation placeholder */
          }
          ''';

    late TestDriver driver;

    setUp(() {
      driver = TestDriver(options, source);
    });

    tearDown(() {
      driver.delete();
    });

    test('expression referencing unnamed import', () async {
      await driver.check(
          scope: <String, String>{},
          expression: 'Directory.systemTemp',
          expectedResult: '''
            (function() {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const io = dart_sdk.io;
              return io.Directory.systemTemp;
            }(
              
            ))
            ''');
    });

    test('expression referencing named import', () async {
      await driver.check(
          scope: <String, String>{},
          expression: 'p.Directory.systemTemp',
          expectedResult: '''
            (function() {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const io = dart_sdk.io;
              return io.Directory.systemTemp;
            }(
              
            ))
            ''');
    });

    test('expression referencing another library with the same named import',
        () async {
      await driver.check(
          scope: <String, String>{},
          expression: 'p.utf8.decoder',
          expectedResult: '''
            (function() {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const convert = dart_sdk.convert;
              return convert.utf8.decoder;
            }(
              
            ))
            ''');
    });
  });

  group('Expression compiler expressions that import extension symbols', () {
    var source = '''
          ${options.dartLangComment}
          void bar() {
            /* evaluation placeholder */ 
          }

          void main() => bar();
          ''';

    late TestDriver driver;
    setUp(() {
      driver = TestDriver(options, source);
    });

    tearDown(() {
      driver.delete();
    });

    test('map access', () async {
      await driver.check(
          scope: <String, String>{'inScope': '1', 'innerInScope': '0'},
          expression:
              '(Map<String, String> params) { return params["index"]; }({})',
          expectedResult: '''
            (function() {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const core = dart_sdk.core;
              const _js_helper = dart_sdk._js_helper;
              const dart = dart_sdk.dart;
              const dartx = dart_sdk.dartx;
              var T = {
                StringN: () => (T.StringN = dart.constFn(dart.nullable(core.String)))(),
                MapOfString\$String: () => (T.MapOfString\$String = dart.constFn(core.Map\$(core.String, core.String)))(),
                MapOfString\$StringToStringN: () => (T.MapOfString\$StringToStringN = dart.constFn(dart.fnType(T.StringN(), [T.MapOfString\$String()])))(),
                IdentityMapOfString\$String: () => (T.IdentityMapOfString\$String = dart.constFn(_js_helper.IdentityMap\$(core.String, core.String)))()
              };
              var S = {\$_get: dartx._get};
              return dart.fn(params => params[S.\$_get]("index"), T.MapOfString\$StringToStringN())(new (T.IdentityMapOfString\$String()).new());
            }(
              
            ))
            ''');
    });
  });
}
