// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:io' show Directory, File;

import 'package:cli_util/cli_util.dart';
import 'package:dev_compiler/dev_compiler.dart';
import 'package:dev_compiler/src/compiler/js_names.dart';
import 'package:dev_compiler/src/compiler/module_builder.dart';
import 'package:dev_compiler/src/js_ast/js_ast.dart';
import 'package:front_end/src/api_unstable/ddc.dart';
import 'package:front_end/src/compute_platform_binaries_location.dart';
import 'package:front_end/src/fasta/incremental_serializer.dart';
import 'package:kernel/ast.dart' show Component, Library;
import 'package:kernel/target/targets.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:vm/transformations/type_flow/utils.dart';

// TODO(annagrin): Replace javascript matching in tests below with evaluating
// the javascript and checking the result.
// See https://github.com/dart-lang/sdk/issues/41959

class DevelopmentIncrementalCompiler extends IncrementalCompiler {
  Uri entryPoint;

  DevelopmentIncrementalCompiler(CompilerOptions options, this.entryPoint,
      [Uri initializeFrom,
      bool outlineOnly,
      IncrementalSerializer incrementalSerializer])
      : super(
            CompilerContext(
                ProcessedOptions(options: options, inputs: [entryPoint])),
            initializeFrom,
            outlineOnly,
            incrementalSerializer);

  DevelopmentIncrementalCompiler.fromComponent(CompilerOptions options,
      this.entryPoint, Component componentToInitializeFrom,
      [bool outlineOnly, IncrementalSerializer incrementalSerializer])
      : super.fromComponent(
            CompilerContext(
                ProcessedOptions(options: options, inputs: [entryPoint])),
            componentToInitializeFrom,
            outlineOnly,
            incrementalSerializer);
}

class SetupCompilerOptions {
  static final sdkRoot = computePlatformBinariesLocation();
  static final sdkUnsoundSummaryPath = p.join(sdkRoot.path, 'ddc_sdk.dill');
  static final sdkSoundSummaryPath =
      p.join(sdkRoot.path, 'ddc_outline_sound.dill');
  static final librariesSpecificationUri =
      p.join(p.dirname(p.dirname(getSdkPath())), 'libraries.json');

  static CompilerOptions getOptions(bool soundNullSafety) {
    var options = CompilerOptions()
      ..verbose = false // set to true for debugging
      ..sdkRoot = sdkRoot
      ..target = DevCompilerTarget(TargetFlags())
      ..librariesSpecificationUri = Uri.base.resolve('sdk/lib/libraries.json')
      ..omitPlatform = true
      ..sdkSummary = sdkRoot.resolve(
          soundNullSafety ? sdkSoundSummaryPath : sdkUnsoundSummaryPath)
      ..environmentDefines = const {}
      ..nnbdMode = soundNullSafety ? NnbdMode.Strong : NnbdMode.Weak;
    return options;
  }

  static final String dartUnsoundComment = '// @dart = 2.9';
  static final String dartSoundComment = '//';

  final List<String> errors = [];
  final CompilerOptions options;
  final String dartLangComment;
  final ModuleFormat moduleFormat;
  final bool soundNullSafety;

  SetupCompilerOptions(
      {this.soundNullSafety = true, this.moduleFormat = ModuleFormat.amd})
      : options = getOptions(soundNullSafety),
        dartLangComment =
            soundNullSafety ? dartSoundComment : dartUnsoundComment {
    options.onDiagnostic = (DiagnosticMessage m) {
      errors.addAll(m.plainTextFormatted);
    };
  }

  String get loadModule {
    switch (moduleFormat) {
      case ModuleFormat.amd:
        return 'require';
      case ModuleFormat.ddc:
        return 'dart_library.import';
      default:
        throw UnsupportedError('Module format: $moduleFormat');
    }
  }
}

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
        path = importUri.scheme == 'package'
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

  TestCompiler(this.setup);

  Future<TestCompilationResult> compile(
      {Uri input,
      Uri packages,
      int line,
      int column,
      Map<String, String> scope,
      String expression}) async {
    // initialize incremental compiler and create component
    setup.options.packagesFileUri = packages;
    var compiler = DevelopmentIncrementalCompiler(setup.options, input);
    var component = await compiler.computeDelta();
    component.computeCanonicalNames();

    // initialize ddc
    var moduleName = 'foo.dart';
    var classHierarchy = compiler.getClassHierarchy();
    var compilerOptions = SharedCompilerOptions(
        replCompile: true,
        moduleName: moduleName,
        soundNullSafety: setup.soundNullSafety,
        moduleFormats: [setup.moduleFormat]);
    var coreTypes = compiler.getCoreTypes();

    final importToSummary = Map<Library, Component>.identity();
    final summaryToModule = Map<Component, String>.identity();
    for (var lib in component.libraries) {
      importToSummary[lib] = component;
    }
    summaryToModule[component] = moduleName;

    var kernel2jsCompiler = ProgramCompiler(component, classHierarchy,
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

    // create expression compiler
    var evaluator = ExpressionCompiler(
      setup.options,
      setup.moduleFormat,
      setup.errors,
      compiler,
      kernel2jsCompiler,
      component,
    );

    // collect all module names and paths
    var moduleInfo = _collectModules(component);
    var module = moduleInfo[input];

    setup.errors.clear();

    // compile
    var jsExpression = await evaluator.compileExpressionToJs(
        module.package, line, column, scope, expression);

    if (setup.errors.isNotEmpty) {
      jsExpression = setup.errors.toString().replaceAll(
          RegExp(
              r'org-dartlang-debug:synthetic_debug_expression:[0-9]*:[0-9]*:'),
          '');

      return TestCompilationResult(jsExpression, false);
    }

    return TestCompilationResult(jsExpression, true);
  }

  Map<Uri, Module> _collectModules(Component component) {
    var modules = <Uri, Module>{};
    for (var library in component.libraries) {
      modules[library.fileUri] = Module(library.importUri, library.fileUri);
    }

    return modules;
  }
}

class TestDriver {
  final SetupCompilerOptions options;
  Directory tempDir;
  final String source;
  Uri input;
  Uri packages;
  File file;
  int line;

  TestDriver(this.options, this.source) {
    var systemTempDir = Directory.systemTemp;
    tempDir = systemTempDir.createTempSync('foo bar');

    line = _getEvaluationLine(source);
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

  Future<void> check(
      {Map<String, String> scope,
      String expression,
      String expectedError,
      String expectedResult}) async {
    var result = await TestCompiler(options).compile(
        input: input,
        packages: packages,
        line: line,
        column: 1,
        scope: scope,
        expression: expression);

    var success = expectedError == null;
    var message = success ? expectedResult : expectedError;

    expect(
        result,
        const TypeMatcher<TestCompilationResult>()
            .having((r) => _normalize(r.result), 'result', _matches(message))
            .having((r) => r.isSuccess, 'isSuccess', success));
  }

  String _normalize(String text) {
    return text
        .replaceAll(RegExp('\'.*foo.dart\''), '\'foo.dart\'')
        .replaceAll(RegExp('\".*foo.dart\"'), '\'foo.dart\'');
  }

  Matcher _matches(String text) {
    var unindented = RegExp.escape(text).replaceAll(RegExp('[ ]+'), '[ ]*');
    return matches(RegExp(unindented, multiLine: true));
  }

  int _getEvaluationLine(String source) {
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
    group('Module format: $moduleFormat', () {
      group('Unsound null safety:', () {
        var options = SetupCompilerOptions(
            soundNullSafety: false, moduleFormat: moduleFormat);

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

          TestDriver driver;

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
              const dart_sdk = ${options.loadModule}(\'dart_sdk\');
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
              const dart_sdk = ${options.loadModule}(\'dart_sdk\');
              const io = dart_sdk.io;
              return io.Directory.systemTemp;
            }(
              
            ))
            ''');
          });

          test(
              'expression referencing another library with the same named import',
              () async {
            await driver.check(
                scope: <String, String>{},
                expression: 'p.utf8.decoder',
                expectedResult: '''
            (function() {
              const dart_sdk = ${options.loadModule}(\'dart_sdk\');
              const convert = dart_sdk.convert;
              return convert.utf8.decoder;
            }(
              
            ))
            ''');
          });
        });

        group('Expression compiler extension symbols tests', () {
          var source = '''
          ${options.dartLangComment}

          main() {
            List<int> list = {};
            list.add(0);
            /* evaluation placeholder */
          }
          ''';

          TestDriver driver;

          setUp(() {
            driver = TestDriver(options, source);
          });

          tearDown(() {
            driver.delete();
          });

          test('extension symbol used in original compilation', () async {
            await driver.check(
                scope: <String, String>{'list': 'list'},
                expression: 'list.add(1)',
                expectedResult: '''
            (function(list) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const dartx = dart_sdk.dartx;
              var \$add = dartx.add;
              var S = {\$add: dartx.add};
              return list[\$add](1);
            }(
              list
            ))
            ''');
          });

          test('extension symbol used only in expression compilation',
              () async {
            await driver.check(
                scope: <String, String>{'list': 'list'},
                expression: 'list.first',
                expectedResult: '''
            (function(list) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const dartx = dart_sdk.dartx;
              var S = {\$first: dartx.first};
              return list[S.\$first];
            }(
              list
            ))
            ''');
          });
        });

        group('Expression compiler tests in closures:', () {
          var source = '''
          ${options.dartLangComment}
          int globalFunction() {
            int x = 15;
            var c = C(1, 2);

            var outerClosure = (int y) {
              var closureCaptureInner = (int z) {
                /* evaluation placeholder */
                print('\$y+\$z');
              };
              closureCaptureInner(0);
            };

            outerClosure(3);
            return 0;
          }

          main() => 0;
          ''';

          TestDriver driver;
          setUp(() {
            driver = TestDriver(options, source);
          });

          tearDown(() {
            driver.delete();
          });

          test('compilation error', () async {
            await driver.check(scope: <String, String>{
              'x': '1',
              'c': 'null',
              'y': '3',
              'z': '0'
            }, expression: 'typo', expectedError: "Getter not found: 'typo'.");
          });

          test('expression using uncaptured variables', () async {
            await driver.check(
                scope: <String, String>{
                  'x': '1',
                  'c': 'null',
                  'y': '3',
                  'z': '0'
                },
                expression: "'\$x+\$y+\$z'",
                expectedResult: '''
            (function(x, c, y, z) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const dart = dart_sdk.dart;
              return dart.str(x) + "+" + dart.str(y) + "+" + dart.str(z);
            }(
              1,
              null,
              3,
              0
            ))
            ''');
          });

          test('expression using captured variables', () async {
            await driver.check(
                scope: <String, String>{
                  'x': '1',
                  'c': 'null',
                  'y': '3',
                  'z': '0'
                },
                expression: "'\$y+\$z'",
                expectedResult: '''
            (function(x, c, y, z) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const dart = dart_sdk.dart;
              return dart.str(y) + "+" + dart.str(z);
            }(
              1,
              null,
              3,
              0
            ))
            ''');
          });
        });

        group(
            'Expression compiler tests for interactions with module containers:',
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

          TestDriver driver;
          setUp(() {
            driver = TestDriver(options, source);
          });

          tearDown(() {
            driver.delete();
          });

          test(
              'evaluation that non-destructively appends to the type container',
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

          test(
              'evaluation that non-destructively appends to the constant container',
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
                  return C[0] = dart.const({
                    __proto__: foo.B.prototype
                  });
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
                  return C[0] = dart.const({
                    __proto__: foo.A.prototype
                  });
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

        group('Expression compiler tests in generic method:', () {
          var source = '''
          ${options.dartLangComment}
          class A {
            void generic<TType, KType>(TType a, KType b) {
              /* evaluation placeholder */
              print(a);
              print(b);
            }
          }

          void main() => generic<int, String>(0, 'hi');
          ''';

          TestDriver driver;
          setUp(() {
            driver = TestDriver(options, source);
          });

          tearDown(() {
            driver.delete();
          });

          test('evaluate formals', () async {
            await driver.check(
                scope: <String, String>{
                  'TType': 'TType',
                  'KType': 'KType',
                  'a': 'a',
                  'b': 'b'
                },
                expression: 'a',
                expectedResult: '''
            (function(TType, KType, a, b) {
                return a;
            }.bind(this)(
              TType,
              KType,
              a,
              b
            ))
            ''');
          });

          test('evaluate type parameters', () async {
            await driver.check(
                scope: <String, String>{
                  'TType': 'TType',
                  'KType': 'KType',
                  'a': 'a',
                  'b': 'b'
                },
                expression: 'TType',
                expectedResult: '''
            (function(TType, KType, a, b) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const dart = dart_sdk.dart;
              return dart.wrapType(dart.legacy(TType));
            }.bind(this)(
              TType,
              KType,
              a,
              b
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

          TestDriver driver;
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
      });
    });
  }

  for (var moduleFormat in [ModuleFormat.amd, ModuleFormat.ddc]) {
    group('Module format: $moduleFormat', () {
      group('Sound null safety:', () {
        var options = SetupCompilerOptions(soundNullSafety: true);

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

          TestDriver driver;

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
              const dart_sdk = ${options.loadModule}(\'dart_sdk\');
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
              const dart_sdk = ${options.loadModule}(\'dart_sdk\');
              const io = dart_sdk.io;
              return io.Directory.systemTemp;
            }(
              
            ))
            ''');
          });

          test(
              'expression referencing another library with the same named import',
              () async {
            await driver.check(
                scope: <String, String>{},
                expression: 'p.utf8.decoder',
                expectedResult: '''
            (function() {
              const dart_sdk = ${options.loadModule}(\'dart_sdk\');
              const convert = dart_sdk.convert;
              return convert.utf8.decoder;
            }(
              
            ))
            ''');
          });
        });

        group('Expression compiler extension symbols tests', () {
          var source = '''
          ${options.dartLangComment}
    
          main() {
            List<int> list = {};
            list.add(0);
            /* evaluation placeholder */
          }
          ''';

          TestDriver driver;

          setUp(() {
            driver = TestDriver(options, source);
          });

          tearDown(() {
            driver.delete();
          });

          test('extension symbol used in original compilation', () async {
            await driver.check(
                scope: <String, String>{'list': 'list'},
                expression: 'list.add(1)',
                expectedResult: '''
            (function(list) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const dartx = dart_sdk.dartx;
              var \$add = dartx.add;
              var S = {\$add: dartx.add};
              return list[\$add](1);
            }(
              list
            ))
            ''');
          });

          test('extension symbol used only in expression compilation',
              () async {
            await driver.check(
                scope: <String, String>{'list': 'list'},
                expression: 'list.first',
                expectedResult: '''
            (function(list) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const dartx = dart_sdk.dartx;
              var S = {\$first: dartx.first};
              return list[S.\$first];
            }(
              list
            ))
            ''');
          });
        });

        group('Expression compiler tests in closures:', () {
          var source = '''
          ${options.dartLangComment}
          int globalFunction() {
            int x = 15;
            var c = C(1, 2);

            var outerClosure = (int y) {
              var closureCaptureInner = (int z) {
                /* evaluation placeholder */
                print('\$y+\$z');
              };
              closureCaptureInner(0);
            };

            outerClosure(3);
            return 0;
          }

          main() => 0;
          ''';

          TestDriver driver;
          setUp(() {
            driver = TestDriver(options, source);
          });

          tearDown(() {
            driver.delete();
          });

          test('compilation error', () async {
            await driver.check(scope: <String, String>{
              'x': '1',
              'c': 'null',
              'y': '3',
              'z': '0'
            }, expression: 'typo', expectedError: "Getter not found: 'typo'.");
          });

          test('expression using uncaptured variables', () async {
            await driver.check(
                scope: <String, String>{
                  'x': '1',
                  'c': 'null',
                  'y': '3',
                  'z': '0'
                },
                expression: "'\$x+\$y+\$z'",
                expectedResult: '''
            (function(x, c, y, z) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const dart = dart_sdk.dart;
              return dart.str(x) + "+" + dart.str(y) + "+" + dart.str(z);
            }(
              1,
              null,
              3,
              0
            ))
            ''');
          });

          test('expression using captured variables', () async {
            await driver.check(
                scope: <String, String>{
                  'x': '1',
                  'c': 'null',
                  'y': '3',
                  'z': '0'
                },
                expression: "'\$y+\$z'",
                expectedResult: '''
            (function(x, c, y, z) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const dart = dart_sdk.dart;
              return dart.str(y) + "+" + dart.str(z);
            }(
              1,
              null,
              3,
              0
            ))
            ''');
          });
        });

        group('Expression compiler tests in generic method:', () {
          var source = '''
          ${options.dartLangComment}
          class A {
            void generic<TType, KType>(TType a, KType b) {
              /* evaluation placeholder */
              print(a);
              print(b);
            }
          }

          void main() => generic<int, String>(0, 'hi');
          ''';

          TestDriver driver;
          setUp(() {
            driver = TestDriver(options, source);
          });

          tearDown(() {
            driver.delete();
          });

          test('evaluate formals', () async {
            await driver.check(
                scope: <String, String>{
                  'TType': 'TType',
                  'KType': 'KType',
                  'a': 'a',
                  'b': 'b'
                },
                expression: 'a',
                expectedResult: '''
            (function(TType, KType, a, b) {
                return a;
            }.bind(this)(
              TType,
              KType,
              a,
              b
            ))
            ''');
          });

          test('evaluate type parameters', () async {
            await driver.check(
                scope: <String, String>{
                  'TType': 'TType',
                  'KType': 'KType',
                  'a': 'a',
                  'b': 'b'
                },
                expression: 'TType',
                expectedResult: '''
            (function(TType, KType, a, b) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const dart = dart_sdk.dart;
              return dart.wrapType(TType);
            }.bind(this)(
              TType,
              KType,
              a,
              b
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

          TestDriver driver;
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
      });
    });
  }
}
