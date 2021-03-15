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

  void check(
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

        group('Expression compiler scope collection tests', () {
          var source = '''
          ${options.dartLangComment}

          class C {
            C(int this.field);

            int methodFieldAccess(int x) {
              var inScope = 1;
              {
                var innerInScope = global + staticField + field;
                /* evaluation placeholder */
                print(innerInScope);
                var innerNotInScope = 2;
              }
              var notInScope = 3;
            }

            static int staticField = 0;
            int field;
          }

          int global = 42;
          main() => 0;
          ''';

          TestDriver driver;

          setUp(() {
            driver = TestDriver(options, source);
          });

          tearDown(() {
            driver.delete();
          });

          test('local in scope', () async {
            await driver.check(
                scope: <String, String>{'inScope': '1', 'innerInScope': '0'},
                expression: 'inScope',
                expectedResult: '''
            (function(inScope, innerInScope) {
              return inScope;
            }.bind(this)(
              1,
              0
            ))
            ''');
          });

          test('local in inner scope', () async {
            await driver.check(
                scope: <String, String>{'inScope': '1', 'innerInScope': '0'},
                expression: 'innerInScope',
                expectedResult: '''
            (function(inScope, innerInScope) {
              return innerInScope;
            }.bind(this)(
              1,
              0
            ))
            ''');
          });

          test('global in scope', () async {
            await driver.check(
                scope: <String, String>{'inScope': '1', 'innerInScope': '0'},
                expression: 'global',
                expectedResult: '''
            (function(inScope, innerInScope) {
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              return foo.global;
            }.bind(this)(
              1,
              0
            ))
            ''');
          });

          test('static field in scope', () async {
            await driver.check(
                scope: <String, String>{'inScope': '1', 'innerInScope': '0'},
                expression: 'staticField',
                expectedResult: '''
            (function(inScope, innerInScope) {
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              return foo.C.staticField;
            }.bind(this)(
              1,
              0
            ))
            ''');
          });

          test('field in scope', () async {
            await driver.check(
                scope: <String, String>{'inScope': '1', 'innerInScope': '0'},
                expression: 'field',
                expectedResult: '''
            (function(inScope, innerInScope) {
              return this.field;
            }.bind(this)(
              1,
              0
            ))
            ''');
          });

          test('local not in scope', () async {
            await driver.check(
                scope: <String, String>{'inScope': '1', 'innerInScope': '0'},
                expression: 'notInScope',
                expectedError:
                    "Error: The getter 'notInScope' isn't defined for the class 'C'.");
          });

          test('local not in inner scope', () async {
            await driver.check(
                scope: <String, String>{'inScope': '1', 'innerInScope': '0'},
                expression: 'innerNotInScope',
                expectedError:
                    "Error: The getter 'innerNotInScope' isn't defined for the class 'C'.");
          });
        });

        group('Expression compiler tests in extension method:', () {
          var source = '''
          ${options.dartLangComment}
          extension NumberParsing on String {
            int parseInt() {
              var ret = int.parse(this);
              /* evaluation placeholder */
              return ret;
            }
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
            await driver.check(
                scope: <String, String>{'ret': '1234'},
                expression: 'typo',
                expectedError: "Error: Getter not found: 'typo'");
          });

          test('local (trimmed scope)', () async {
            // Test that current expression evaluation works in extension methods.
            //
            // Note: the actual scope is {#this, ret}, but #this is effectively
            // removed in the expression compilator because it does not exist
            // in JavaScript code.
            // See (full scope) tests for what will the evaluation will look like
            // when the mapping from dart symbols to JavaScipt symbols is added.
            await driver.check(
                scope: <String, String>{'ret': '1234'},
                expression: 'ret',
                expectedResult: '''
            (function(ret) {
              return ret;
            }(
              1234
            ))
            ''');
          });

          test('local (full scope)', () async {
            // Test evalution in extension methods in the future when the mapping
            // from kernel symbols to dartdevc symbols is added.
            //
            // Note: this currently fails due to
            // - incremental compiler not allowing #this as a parameter name
            await driver.check(
                scope: <String, String>{'ret': '1234', '#this': 'this'},
                expression: 'ret',
                expectedError:
                    "Illegal parameter name '#this' found during expression compilation.");
          });

          test('this (full scope)', () async {
            // Test evalution in extension methods in the future when the mapping
            // from kernel symbols to dartdevc symbols is added.
            //
            // Note: this currently fails due to
            // - incremental compiler not allowing #this as a parameter name
            // - incremental compiler not mapping 'this' from user input to '#this'
            await driver.check(
                scope: <String, String>{'ret': '1234', '#this': 'this'},
                expression: 'this',
                expectedError:
                    "Illegal parameter name '#this' found during expression compilation.");
          });
        });

        group('Expression compiler tests in static function:', () {
          var source = '''
          ${options.dartLangComment}
          int foo(int x, {int y}) {
            int z = 0;
            /* evaluation placeholder */
            return x + y + z;
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
            await driver.check(
                scope: <String, String>{'x': '1', 'y': '2', 'z': '3'},
                expression: 'typo',
                expectedError: "Getter not found: \'typo\'");
          });

          test('local', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'y': '2', 'z': '3'},
                expression: 'x',
                expectedResult: '''
            (function(x, y, z) {
              return x;
            }(
              1,
              2,
              3
            ))
            ''');
          });

          test('formal', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'y': '2', 'z': '3'},
                expression: 'y',
                expectedResult: '''
            (function(x, y, z) {
              return y;
            }(
              1,
              2,
              3
            ))
            ''');
          });

          test('named formal', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'y': '2', 'z': '3'},
                expression: 'z',
                expectedResult: '''
            (function(x, y, z) {
              return z;
            }(
              1,
              2,
              3
            ))
            ''');
          });

          test('function', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'y': '2', 'z': '3'},
                expression: 'main',
                expectedResult: '''
            (function(x, y, z) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const dart = dart_sdk.dart;
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              var T = {
                VoidTodynamic: () => (T.VoidTodynamic = dart.constFn(dart.fnType(dart.dynamic, [])))()
              };
              const CT = Object.create(null);
              dart.defineLazy(CT, {
                get C0() {
                  return C[0] = dart.fn(foo.main, T.VoidTodynamic());
                }
              }, false);
              var C = [void 0];
              return C[0] || CT.C0;
            }(
              1,
              2,
              3
            ))
            ''');
          });
        });

        group('Expression compiler tests in method:', () {
          var source = '''
          ${options.dartLangComment}
          extension NumberParsing on String {
            int parseInt() {
              return int.parse(this);
            }
          }

          int global = 42;

          class C {
            C(int this.field, int this._field);

            static int staticField = 0;
            static int _staticField = 1;

            int _field;
            int field;

            int methodFieldAccess(int x) {
              /* evaluation placeholder */
              return x + _field + _staticField;
            }

            Future<int> asyncMethod(int x) async {
              return x;
            }
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
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'typo',
                expectedError:
                    "The getter 'typo' isn't defined for the class 'C'");
          });

          test('local', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'x',
                expectedResult: '''
            (function(x) {
              return x;
            }.bind(this)(
              1
            ))
            ''');
          });

          test('this', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'this',
                expectedResult: '''
            (function(x) {
              return this;
            }.bind(this)(
              1
            ))
            ''');
          });

          test('expression using locals', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'x + 1',
                expectedResult: '''
            (function(x) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const dart = dart_sdk.dart;
              return dart.notNull(x) + 1;
            }.bind(this)(
              1
            ))
            ''');
          });

          test('expression using static fields', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'x + staticField',
                expectedResult: '''
            (function(x) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const dart = dart_sdk.dart;
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              return dart.notNull(x) + dart.notNull(foo.C.staticField);
            }.bind(this)(
              1
            ))
            ''');
          });

          test('expression using private static fields', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'x + _staticField',
                expectedResult: '''
            (function(x) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const dart = dart_sdk.dart;
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              return dart.notNull(x) + dart.notNull(foo.C._staticField);
            }.bind(this)(
              1
            ))
            ''');
          });

          test('expression using fields', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'x + field',
                expectedResult: '''
            (function(x) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const dart = dart_sdk.dart;
              return dart.notNull(x) + dart.notNull(this.field);
            }.bind(this)(
              1
            ))
            ''');
          });

          test('expression using private fields', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'x + _field',
                expectedResult: '''
            (function(x) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const dart = dart_sdk.dart;
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              var S = {_field\$1: dart.privateName(foo, "_field")};
              return dart.notNull(x) + dart.notNull(this[S._field\$1]);
            }.bind(this)(
              1
            ))
            ''');
          });

          test('expression using globals', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'x + global',
                expectedResult: '''
            (function(x) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const dart = dart_sdk.dart;
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              return dart.notNull(x) + dart.notNull(foo.global);
            }.bind(this)(
              1
            ))
            ''');
          });

          test('method call', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'methodFieldAccess(2)',
                expectedResult: '''
            (function(x) {
              return this.methodFieldAccess(2);
            }.bind(this)(
              1
            ))
            ''');
          });

          test('async method call', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'asyncMethod(2)',
                expectedResult: '''
            (function(x) {
              return this.asyncMethod(2);
            }.bind(this)(
              1
            ))
            ''');
          });

          test('extension method call', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: '"1234".parseInt()',
                expectedResult: '''
            (function(x) {
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              return foo['NumberParsing|parseInt']("1234");
            }.bind(this)(
              1
            ))
            ''');
          });

          test('private field modification', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: '_field = 2',
                expectedResult: '''
            (function(x) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const dart = dart_sdk.dart;
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              var S = {_field\$1: dart.privateName(foo, "_field")};
              return this[S._field\$1] = 2;
            }.bind(this)(
              1
            ))
            ''');
          });

          test('field modification', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'field = 2',
                expectedResult: '''
            (function(x) {
              return this.field = 2;
            }.bind(this)(
              1
            ))
            ''');
          });

          test('private static field modification', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: '_staticField = 2',
                expectedResult: '''
            (function(x) {
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              return foo.C._staticField = 2;
            }.bind(this)(
              1
            ))
            ''');
          });

          test('static field modification', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'staticField = 2',
                expectedResult: '''
            (function(x) {
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              return foo.C.staticField = 2;
            }.bind(this)(
              1
            ))
            ''');
          });
        });

        group('Expression compiler tests in method with no field access:', () {
          var source = '''
          ${options.dartLangComment}
          extension NumberParsing on String {
            int parseInt() {
              return int.parse(this);
            }
          }

          int global = 42;

          class C {
            C(int this.field, int this._field);

            static int staticField = 0;
            static int _staticField = 1;

            int _field;
            int field;

            int methodNoFieldAccess(int x) {
              /* evaluation placeholder */
              return x;
            }

            Future<int> asyncMethod(int x) async {
              return x;
            }
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
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'typo',
                expectedError:
                    "The getter 'typo' isn't defined for the class 'C'");
          });

          test('expression using static fields', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'x + staticField',
                expectedResult: '''
            (function(x) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const dart = dart_sdk.dart;
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              return dart.notNull(x) + dart.notNull(foo.C.staticField);
            }.bind(this)(
              1
            ))
            ''');
          });

          test('expression using private static fields', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'x + _staticField',
                expectedResult: '''
            (function(x) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const dart = dart_sdk.dart;
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              return dart.notNull(x) + dart.notNull(foo.C._staticField);
            }.bind(this)(
              1
            ))
            ''');
          });

          test('expression using fields', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'x + field',
                expectedResult: '''
            (function(x) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const dart = dart_sdk.dart;
              return dart.notNull(x) + dart.notNull(this.field);
            }.bind(this)(
              1
            ))
            ''');
          });

          test('expression using private fields', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'x + _field',
                expectedResult: '''
            (function(x) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const dart = dart_sdk.dart;
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              var S = {_field\$1: dart.privateName(foo, "_field")};
              return dart.notNull(x) + dart.notNull(this[S._field\$1]);
            }.bind(this)(
            1
            ))
            ''');
          });

          test('private field modification', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: '_field = 2',
                expectedResult: '''
            (function(x) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const dart = dart_sdk.dart;
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              var S = {_field\$1: dart.privateName(foo, "_field")};
              return this[S._field\$1] = 2;
            }.bind(this)(
            1
            ))
            ''');
          });

          test('field modification', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'field = 2',
                expectedResult: '''
            (function(x) {
              return this.field = 2;
            }.bind(this)(
            1
            ))
            ''');
          });

          test('private static field modification', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: '_staticField = 2',
                expectedResult: '''
            (function(x) {
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              return foo.C._staticField = 2;
            }.bind(this)(
            1
            ))
            ''');
          });

          test('static field modification', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'staticField = 2',
                expectedResult: '''
            (function(x) {
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              return foo.C.staticField = 2;
            }.bind(this)(
            1
            ))
            ''');
          });
        });

        group('Expression compiler tests in async method:', () {
          var source = '''
          ${options.dartLangComment}
          class C {
            C(int this.field, int this._field);

            int _field;
            int field;

            Future<int> asyncMethod(int x) async {
              /* evaluation placeholder */
              return x;
            }
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
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'typo',
                expectedError:
                    "The getter 'typo' isn't defined for the class 'C'");
          });

          test('local', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'x',
                expectedResult: '''
            (function(x) {
              return x;
            }.bind(this)(
            1
            ))
            ''');
          });

          test('this', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'this',
                expectedResult: '''
            (function(x) {
              return this;
            }.bind(this)(
            1
            ))
            ''');
          });
        });

        group('Expression compiler tests in global function:', () {
          var source = '''
          ${options.dartLangComment}
          extension NumberParsing on String {
            int parseInt() {
              return int.parse(this);
            }
          }

          int global = 42;

          class C {
            C(int this.field, int this._field);

            static int staticField = 0;
            static int _staticField = 1;

            int _field;
            int field;

            int methodFieldAccess(int x) {
              return (x + _field + _staticField);
            }
            int methodFieldAccess(int x) {
              return (x)
            }

            Future<int> asyncMethod(int x) async {
              return x;
            }
          }

          int main() {
            int x = 15;
            var c = C(1, 2);
            /* evaluation placeholder */
            return 0;
          }
          ''';

          TestDriver driver;
          setUp(() {
            driver = TestDriver(options, source);
          });

          tearDown(() {
            driver.delete();
          });

          test('compilation error', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null'},
                expression: 'typo',
                expectedError: "Getter not found: 'typo'.");
          });

          test('local with primitive type', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null'},
                expression: 'x',
                expectedResult: '''
            (function(x, c) {
              return x;
            }(
              1,
              null
            ))
            ''');
          });

          test('local object', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null'},
                expression: 'c',
                expectedResult: '''
            (function(x, c) {
              return c;
            }(
              1,
              null
            ))
            ''');
          });

          test('create new object', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null'},
                expression: 'C(1,3)',
                expectedResult: '''
              (function(x, c) {
                const foo\$46dart = ${options.loadModule}('foo.dart');
                const foo = foo\$46dart.foo;
                return new foo.C.new(1, 3);
              }(
                1,
                null
              ))
              ''');
          });

          test('access field of new object', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null'},
                expression: 'C(1,3)._field',
                expectedResult: '''
            (function(x, c) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const dart = dart_sdk.dart;
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              var S = {_field\$1: dart.privateName(foo, "_field")};
              return new foo.C.new(1, 3)[S._field\$1];
            }(
              1,
              null
            ))
            ''');
          });

          test('access static field', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null'},
                expression: 'C.staticField',
                expectedResult: '''
            (function(x, c) {
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              return foo.C.staticField;
            }(
              1,
              null
            ))
            ''');
          });

          test('expression using private static fields', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null'},
                expression: 'C._staticField',
                expectedError: "Error: Getter not found: '_staticField'.");
          });

          test('access field', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null'},
                expression: 'c.field',
                expectedResult: '''
            (function(x, c) {
              return c.field;
            }(
              1,
              null
            ))
            ''');
          });

          test('access private field', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null'},
                expression: 'c._field',
                expectedResult: '''
            (function(x, c) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const dart = dart_sdk.dart;
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              var S = {_field\$1: dart.privateName(foo, "_field")};
              return c[S._field\$1];
            }(
              1,
              null
            ))
            ''');
          });

          test('method call', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null'},
                expression: 'c.methodFieldAccess(2)',
                expectedResult: '''
            (function(x, c) {
              return c.methodFieldAccess(2);
            }(
              1,
              null
            ))
            ''');
          });

          test('async method call', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null'},
                expression: 'c.asyncMethod(2)',
                expectedResult: '''
            (function(x, c) {
              return c.asyncMethod(2);
            }(
              1,
              null
            ))
            ''');
          });

          test('extension method call', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null'},
                expression: '"1234".parseInt()',
                expectedResult: '''
            (function(x, c) {
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              return foo['NumberParsing|parseInt']("1234");
            }(
              1,
              null
            ))
            ''');
          });

          test('private field modification', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null'},
                expression: 'c._field = 2',
                expectedResult: '''
            (function(x, c) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const dart = dart_sdk.dart;
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              var S = {_field\$1: dart.privateName(foo, "_field")};
              return c[S._field\$1] = 2;
            }(
              1,
              null
            ))
            ''');
          });

          test('field modification', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null'},
                expression: 'c.field = 2',
                expectedResult: '''
            (function(x, c) {
              return c.field = 2;
            }(
              1,
              null
            ))
            ''');
          });

          test('private static field modification', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null'},
                expression: 'C._staticField = 2',
                expectedError: "Setter not found: '_staticField'.");
          });

          test('static field modification', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null'},
                expression: 'C.staticField = 2',
                expectedResult: '''
            (function(x, c) {
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              return foo.C.staticField = 2;
            }(
              1,
              null
            ))
            ''');
          });

          test('call global function from core library', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null'},
                expression: 'print(x)',
                expectedResult: '''
            (function(x, c) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const core = dart_sdk.core;
              return core.print(x);
            }(
              1,
              null
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

        group('Expression compiler tests in method with no type use:', () {
          var source = '''
        ${options.dartLangComment}
          abstract class Key {
            const factory Key(String value) = ValueKey;
            const Key.empty();
          }

          abstract class LocalKey extends Key {
            const LocalKey() : super.empty();
          }

          class ValueKey implements LocalKey {
            const ValueKey(this.value);
            final String value;
          }

          class MyClass {
            const MyClass(this._t);
            final int _t;
          }

          int bar(int p){
            return p;
          }
          int baz(String t){
            return t;
          }
          void main() {
            var k = Key('t');
            MyClass c = MyClass(0);
            int p = 1;
            const t = 1;

            /* evaluation placeholder */
            print('\$c, \$k, \$t');
          }
          ''';

          TestDriver driver;
          setUp(() {
            driver = TestDriver(options, source);
          });

          tearDown(() {
            driver.delete();
          });

          test('call function not using type', () async {
            await driver.check(
                scope: <String, String>{'p': '1'},
                expression: 'bar(p)',
                expectedResult: '''
            (function(p) {
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              return foo.bar(p);
            }(
              1
            ))
            ''');
          });

          test('call function using type', () async {
            await driver.check(
                scope: <String, String>{'p': '0'},
                expression: 'baz(p as String)',
                expectedResult: '''
            (function(p) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const core = dart_sdk.core;
              const dart = dart_sdk.dart;
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              var T = {
                StringL: () => (T.StringL = dart.constFn(dart.legacy(core.String)))()
              };
              return foo.baz(T.StringL().as(p));
            }(
              0
            ))
            ''');
          });

          test('evaluate new const expression', () async {
            await driver.check(
                scope: <String, String>{'p': '1'},
                expression: 'const MyClass(1)',
                expectedResult: '''
            (function(p) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const dart = dart_sdk.dart;
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              var S = {MyClass__t: dart.privateName(foo, "MyClass._t")};
              const CT = Object.create(null);
              dart.defineLazy(CT, {
                get C0() {
                  return C[0] = dart.const({
                    __proto__: foo.MyClass.prototype,
                    [S.MyClass__t]: 1
                  });
                }
              }, false);
              var C = [void 0];
              return C[0] || CT.C0;
            }(
              1
            ))
            ''');
          });

          test('evaluate optimized const expression', () async {
            await driver.check(
                scope: <String, String>{},
                expression: 't',
                expectedResult: '''
            (function() {
              return 1;
            }(
            ))
            ''');
          },
              skip: 'Cannot compile constants optimized away by the frontend. '
                  'Issue: https://github.com/dart-lang/sdk/issues/41999');

          test('evaluate factory constructor call', () async {
            await driver.check(
                scope: <String, String>{'p': '1'},
                expression: "Key('t')",
                expectedResult: '''
            (function(p) {
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              return new foo.ValueKey.new("t");
            }(
              1
            ))
            ''');
          });

          test('evaluate const factory constructor call', () async {
            await driver.check(
                scope: <String, String>{'p': '1'},
                expression: "const Key('t')",
                expectedResult: '''
            (function(p) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const dart = dart_sdk.dart;
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              var S = {ValueKey_value: dart.privateName(foo, "ValueKey.value")};
              const CT = Object.create(null);
              dart.defineLazy(CT, {
                get C0() {
                  return C[0] = dart.const({
                    __proto__: foo.ValueKey.prototype,
                    [S.ValueKey_value]: "t"
                  });
                }
              }, false);
              var C = [void 0];
              return C[0] || CT.C0;
            }(
              1
            ))
            ''');
          });
        });

        group('Expression compiler tests in constructor:', () {
          var source = '''
          ${options.dartLangComment}
          extension NumberParsing on String {
            int parseInt() {
              return int.parse(this);
            }
          }

          int global = 42;

          class C {
            C(int this.field, int this._field) {
              int x = 1;
              /* evaluation placeholder */
              print(this.field);
            }

            static int staticField = 0;
            static int _staticField = 1;

            int _field;
            int field;

            int methodFieldAccess(int t) {
              return t + _field + _staticField;
            }

            Future<int> asyncMethod(int t) async {
              return t;
            }
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
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'typo',
                expectedError:
                    "The getter 'typo' isn't defined for the class 'C'");
          });

          test('local', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'x',
                expectedResult: '''
            (function(x) {
              return x;
            }.bind(this)(
              1
            ))
            ''');
          });

          test('this', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'this',
                expectedResult: '''
            (function(x) {
              return this;
            }.bind(this)(
              1
            ))
            ''');
          });

          test('expression using locals', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'x + 1',
                expectedResult: '''
            (function(x) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const dart = dart_sdk.dart;
              return dart.notNull(x) + 1;
            }.bind(this)(
              1
            ))
            ''');
          });

          test('expression using static fields', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'x + staticField',
                expectedResult: '''
            (function(x) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const dart = dart_sdk.dart;
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              return dart.notNull(x) + dart.notNull(foo.C.staticField);
            }.bind(this)(
              1
            ))
            ''');
          });

          test('expression using private static fields', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'x + _staticField',
                expectedResult: '''
            (function(x) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const dart = dart_sdk.dart;
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              return dart.notNull(x) + dart.notNull(foo.C._staticField);
            }.bind(this)(
              1
            ))
            ''');
          });

          test('expression using fields', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'x + field',
                expectedResult: '''
            (function(x) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const dart = dart_sdk.dart;
              return dart.notNull(x) + dart.notNull(this.field);
            }.bind(this)(
              1
            ))
            ''');
          });

          test('expression using private fields', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'x + _field',
                expectedResult: '''
            (function(x) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const dart = dart_sdk.dart;
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              var S = {_field\$1: dart.privateName(foo, "_field")};
              return dart.notNull(x) + dart.notNull(this[S._field\$1]);
            }.bind(this)(
                1
            ))
            ''');
          });

          test('expression using globals', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'x + global',
                expectedResult: '''
            (function(x) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const dart = dart_sdk.dart;
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              return dart.notNull(x) + dart.notNull(foo.global);
            }.bind(this)(
              1
            ))
            ''');
          });

          test('method call', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'methodFieldAccess(2)',
                expectedResult: '''
            (function(x) {
              return this.methodFieldAccess(2);
            }.bind(this)(
              1
            ))
            ''');
          });

          test('async method call', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'asyncMethod(2)',
                expectedResult: '''
            (function(x) {
              return this.asyncMethod(2);
            }.bind(this)(
              1
            ))
            ''');
          });

          test('extension method call', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: '"1234".parseInt()',
                expectedResult: '''
            (function(x) {
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              return foo['NumberParsing|parseInt']("1234");
            }.bind(this)(
              1
            ))
            ''');
          });

          test('private field modification', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: '_field = 2',
                expectedResult: '''
            (function(x) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const dart = dart_sdk.dart;
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              var S = {_field\$1: dart.privateName(foo, "_field")};
              return this[S._field\$1] = 2;
            }.bind(this)(
              1
            ))
            ''');
          });

          test('field modification', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'field = 2',
                expectedResult: '''
            (function(x) {
              return this.field = 2;
            }.bind(this)(
              1
            ))
            ''');
          });

          test('private static field modification', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: '_staticField = 2',
                expectedResult: '''
            (function(x) {
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              return foo.C._staticField = 2;
            }.bind(this)(
              1
            ))
            ''');
          });

          test('static field modification', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'staticField = 2',
                expectedResult: '''
            (function(x) {
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              return foo.C.staticField = 2;
            }.bind(this)(
              1
            ))
            ''');
          });
        });

        group('Expression compiler tests in simple loops:', () {
          var source = '''
          ${options.dartLangComment}
          int globalFunction() {
            int x = 15;
            var c = C(1, 2);

            for(int i = 0; i < 10; i++) {
              /* evaluation placeholder */
              print('\$i+\$x');
            };
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

          test('expression using local', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null', 'i': '0'},
                expression: 'x',
                expectedResult: '''
            (function(x, c, i) {
              return x;
            }(
              1,
              null,
              0
            ))
            ''');
          });

          test('expression using loop variable', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null', 'i': '0'},
                expression: 'i',
                expectedResult: '''
            (function(x, c, i) {
              return i;
            }(
              1,
              null,
              0
            ))
            ''');
          });
        });

        group('Expression compiler tests in iterator loops:', () {
          var source = '''
          ${options.dartLangComment}
          int globalFunction() {
            var l = <String>['1', '2', '3'];

            for(var e in l) {
              /* evaluation placeholder */
              print(e);
            };
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

          test('expression loop variable', () async {
            await driver.check(
                scope: <String, String>{'l': 'null', 'e': '1'},
                expression: 'e',
                expectedResult: '''
            (function(l, e) {
              return e;
            }(
              null,
              1
            ))
            ''');
          });
        });

        group('Expression compiler tests in conditional (then):', () {
          var source = '''
          ${options.dartLangComment}
          int globalFunction() {
            int x = 1;
            var c = C(1, 2);

            if (x == 14) {
              int y = 3;
              /* evaluation placeholder */
              print('\$y+\$x');
            } else {
              int z = 3;
              print('\$z+\$x');
            }
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

          test('expression using local', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null', 'y': '3'},
                expression: 'y',
                expectedResult: '''
            (function(x, c, y) {
              return y;
            }(
              1,
              null,
              3
            ))
            ''');
          });

          test('expression using local out of scope', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null', 'y': '3'},
                expression: 'z',
                expectedError: "Error: Getter not found: 'z'");
          });
        });

        group('Expression compiler tests in conditional (else):', () {
          var source = '''
          ${options.dartLangComment}
          int globalFunction() {
            int x = 1;
            var c = C(1, 2);

            if (x == 14) {
              int y = 3;
              print('\$y+\$x');
            } else {
              int z = 3;
              /* evaluation placeholder */
              print('\$z+\$x');
            }
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

          test('expression using local', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null', 'z': '3'},
                expression: 'z',
                expectedResult: '''
            (function(x, c, z) {
              return z;
            }(
              1,
              null,
              3
            ))
            ''');
          });

          test('expression using local out of scope', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null', 'z': '3'},
                expression: 'y',
                expectedError: "Error: Getter not found: 'y'");
          });
        });

        group('Expression compiler tests after conditionals:', () {
          var source = '''
          ${options.dartLangComment}
          int globalFunction() {
            int x = 1;
            var c = C(1, 2);

            if (x == 14) {
              int y = 3;
              print('\$y+\$x');
            } else {
              int z = 3;
              print('\$z+\$x');
            }
            /* evaluation placeholder */
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

          test('expression using local', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null'},
                expression: 'x',
                expectedResult: '''
          (function(x, c) {
            return x;
          }(
            1,
            null
          ))
          ''');
          });

          test('expression using local out of scope', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null'},
                expression: 'z',
                expectedError: "Error: Getter not found: 'z'");
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

        group('Expression compiler scope collection tests', () {
          var source = '''
          ${options.dartLangComment}

          class C {
            C(int this.field);

            int methodFieldAccess(int x) {
              var inScope = 1;
              {
                var innerInScope = global + staticField + field;
                /* evaluation placeholder */
                print(innerInScope);
                var innerNotInScope = 2;
              }
              var notInScope = 3;
            }

            static int staticField = 0;
            int field;
          }

          int global = 42;
          main() => 0;
          ''';

          TestDriver driver;

          setUp(() {
            driver = TestDriver(options, source);
          });

          tearDown(() {
            driver.delete();
          });

          test('local in scope', () async {
            await driver.check(
                scope: <String, String>{'inScope': '1', 'innerInScope': '0'},
                expression: 'inScope',
                expectedResult: '''
            (function(inScope, innerInScope) {
              return inScope;
            }.bind(this)(
              1,
              0
            ))
            ''');
          });

          test('local in inner scope', () async {
            await driver.check(
                scope: <String, String>{'inScope': '1', 'innerInScope': '0'},
                expression: 'innerInScope',
                expectedResult: '''
            (function(inScope, innerInScope) {
              return innerInScope;
            }.bind(this)(
              1,
              0
            ))
            ''');
          });

          test('global in scope', () async {
            await driver.check(
                scope: <String, String>{'inScope': '1', 'innerInScope': '0'},
                expression: 'global',
                expectedResult: '''
            (function(inScope, innerInScope) {
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              return foo.global;
            }.bind(this)(
              1,
              0
            ))
            ''');
          });

          test('static field in scope', () async {
            await driver.check(
                scope: <String, String>{'inScope': '1', 'innerInScope': '0'},
                expression: 'staticField',
                expectedResult: '''
            (function(inScope, innerInScope) {
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              return foo.C.staticField;
            }.bind(this)(
              1,
              0
            ))
            ''');
          });

          test('field in scope', () async {
            await driver.check(
                scope: <String, String>{'inScope': '1', 'innerInScope': '0'},
                expression: 'field',
                expectedResult: '''
            (function(inScope, innerInScope) {
              return this.field;
            }.bind(this)(
              1,
              0
            ))
            ''');
          });

          test('local not in scope', () async {
            await driver.check(
                scope: <String, String>{'inScope': '1', 'innerInScope': '0'},
                expression: 'notInScope',
                expectedError:
                    "Error: The getter 'notInScope' isn't defined for the class 'C'.");
          });

          test('local not in inner scope', () async {
            await driver.check(
                scope: <String, String>{'inScope': '1', 'innerInScope': '0'},
                expression: 'innerNotInScope',
                expectedError:
                    "Error: The getter 'innerNotInScope' isn't defined for the class 'C'.");
          });
        });

        group('Expression compiler tests in extension method:', () {
          var source = '''
          ${options.dartLangComment}
          extension NumberParsing on String {
            int parseInt() {
              var ret = int.parse(this);
              /* evaluation placeholder */
              return ret;
            }
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
            await driver.check(
                scope: <String, String>{'ret': '1234'},
                expression: 'typo',
                expectedError: "Error: Getter not found: 'typo'");
          });

          test('local (trimmed scope)', () async {
            // Test that current expression evaluation works in extension methods.
            //
            // Note: the actual scope is {#this, ret}, but #this is effectively
            // removed in the expression compilator because it does not exist
            // in JavaScript code.
            // See (full scope) tests for what will the evaluation will look like
            // when the mapping from dart symbols to JavaScipt symbols is added.
            await driver.check(
                scope: <String, String>{'ret': '1234'},
                expression: 'ret',
                expectedResult: '''
            (function(ret) {
              return ret;
            }(
              1234
            ))
            ''');
          });

          test('local (full scope)', () async {
            // Test evalution in extension methods in the future when the mapping
            // from kernel symbols to dartdevc symbols is added.
            //
            // Note: this currently fails due to
            // - incremental compiler not allowing #this as a parameter name
            await driver.check(
                scope: <String, String>{'ret': '1234', '#this': 'this'},
                expression: 'ret',
                expectedError:
                    "Illegal parameter name '#this' found during expression compilation.");
          });

          test('this (full scope)', () async {
            // Test evalution in extension methods in the future when the mapping
            // from kernel symbols to dartdevc symbols is added.
            //
            // Note: this currently fails due to
            // - incremental compiler not allowing #this as a parameter name
            // - incremental compiler not mapping 'this' from user input to '#this'
            await driver.check(
                scope: <String, String>{'ret': '1234', '#this': 'this'},
                expression: 'this',
                expectedError:
                    "Illegal parameter name '#this' found during expression compilation.");
          });
        });

        group('Expression compiler tests in static function:', () {
          var source = '''
          ${options.dartLangComment}
          int foo(int x, {int y}) {
            int z = 0;
            /* evaluation placeholder */
            return x + y + z;
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
            await driver.check(
                scope: <String, String>{'x': '1', 'y': '2', 'z': '3'},
                expression: 'typo',
                expectedError: "Getter not found: \'typo\'");
          });

          test('local', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'y': '2', 'z': '3'},
                expression: 'x',
                expectedResult: '''
            (function(x, y, z) {
              return x;
            }(
              1,
              2,
              3
            ))
            ''');
          });

          test('formal', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'y': '2', 'z': '3'},
                expression: 'y',
                expectedResult: '''
            (function(x, y, z) {
              return y;
            }(
              1,
              2,
              3
            ))
            ''');
          });

          test('named formal', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'y': '2', 'z': '3'},
                expression: 'z',
                expectedResult: '''
            (function(x, y, z) {
              return z;
            }(
              1,
              2,
              3
            ))
            ''');
          });

          test('function', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'y': '2', 'z': '3'},
                expression: 'main',
                expectedResult: '''
            (function(x, y, z) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const dart = dart_sdk.dart;
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              var T = {
                VoidTodynamic: () => (T.VoidTodynamic = dart.constFn(dart.fnType(dart.dynamic, [])))()
              };
              const CT = Object.create(null);
              dart.defineLazy(CT, {
                get C0() {
                  return C[0] = dart.fn(foo.main, T.VoidTodynamic());
                }
              }, false);
              var C = [void 0];
              return C[0] || CT.C0;
            }(
              1,
              2,
              3
            ))
            ''');
          });
        });

        group('Expression compiler tests in method:', () {
          var source = '''
          ${options.dartLangComment}
          extension NumberParsing on String {
            int parseInt() {
              return int.parse(this);
            }
          }

          int global = 42;

          class C {
            C(int this.field, int this._field);

            static int staticField = 0;
            static int _staticField = 1;

            int _field;
            int field;

            int methodFieldAccess(int x) {
              /* evaluation placeholder */
              return x + _field + _staticField;
            }

            Future<int> asyncMethod(int x) async {
              return x;
            }
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
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'typo',
                expectedError:
                    "The getter 'typo' isn't defined for the class 'C'");
          });

          test('local', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'x',
                expectedResult: '''
            (function(x) {
              return x;
            }.bind(this)(
              1
            ))
            ''');
          });

          test('this', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'this',
                expectedResult: '''
            (function(x) {
              return this;
            }.bind(this)(
              1
            ))
            ''');
          });

          test('expression using locals', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'x + 1',
                expectedResult: '''
            (function(x) {
              return x + 1;
            }.bind(this)(
              1
            ))
            ''');
          });

          test('expression using static fields', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'x + staticField',
                expectedResult: '''
            (function(x) {
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              return x + foo.C.staticField;
            }.bind(this)(
              1
            ))
            ''');
          });

          test('expression using private static fields', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'x + _staticField',
                expectedResult: '''
            (function(x) {
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              return x + foo.C._staticField;
            }.bind(this)(
              1
            ))
            ''');
          });

          test('expression using fields', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'x + field',
                expectedResult: '''
            (function(x) {
              return x + this.field;
            }.bind(this)(
              1
            ))
            ''');
          });

          test('expression using private fields', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'x + _field',
                expectedResult: '''
            (function(x) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const dart = dart_sdk.dart;
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              var S = {_field\$1: dart.privateName(foo, "_field")};
              return x + this[S._field\$1];
            }.bind(this)(
              1
            ))
            ''');
          });

          test('expression using globals', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'x + global',
                expectedResult: '''
            (function(x) {
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              return x + foo.global;
            }.bind(this)(
              1
            ))
            ''');
          });

          test('method call', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'methodFieldAccess(2)',
                expectedResult: '''
            (function(x) {
              return this.methodFieldAccess(2);
            }.bind(this)(
              1
            ))
            ''');
          });

          test('async method call', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'asyncMethod(2)',
                expectedResult: '''
            (function(x) {
              return this.asyncMethod(2);
            }.bind(this)(
              1
            ))
            ''');
          });

          test('extension method call', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: '"1234".parseInt()',
                expectedResult: '''
            (function(x) {
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              return foo['NumberParsing|parseInt']("1234");
            }.bind(this)(
              1
            ))
            ''');
          });

          test('private field modification', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: '_field = 2',
                expectedResult: '''
            (function(x) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const dart = dart_sdk.dart;
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              var S = {_field\$1: dart.privateName(foo, "_field")};
              return this[S._field\$1] = 2;
            }.bind(this)(
              1
            ))
            ''');
          });

          test('field modification', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'field = 2',
                expectedResult: '''
            (function(x) {
              return this.field = 2;
            }.bind(this)(
              1
            ))
            ''');
          });

          test('private static field modification', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: '_staticField = 2',
                expectedResult: '''
            (function(x) {
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              return foo.C._staticField = 2;
            }.bind(this)(
              1
            ))
            ''');
          });

          test('static field modification', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'staticField = 2',
                expectedResult: '''
            (function(x) {
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              return foo.C.staticField = 2;
            }.bind(this)(
              1
            ))
            ''');
          });
        });

        group('Expression compiler tests in method with no field access:', () {
          var source = '''
          ${options.dartLangComment}
          extension NumberParsing on String {
            int parseInt() {
              return int.parse(this);
            }
          }

          int global = 42;

          class C {
            C(int this.field, int this._field);

            static int staticField = 0;
            static int _staticField = 1;

            int _field;
            int field;

            int methodNoFieldAccess(int x) {
              /* evaluation placeholder */
              return x;
            }

            Future<int> asyncMethod(int x) async {
              return x;
            }
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
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'typo',
                expectedError:
                    "The getter 'typo' isn't defined for the class 'C'");
          });

          test('expression using static fields', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'x + staticField',
                expectedResult: '''
            (function(x) {
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              return x + foo.C.staticField;
            }.bind(this)(
              1
            ))
            ''');
          });

          test('expression using private static fields', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'x + _staticField',
                expectedResult: '''
            (function(x) {
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              return x + foo.C._staticField;
            }.bind(this)(
              1
            ))
            ''');
          });

          test('expression using fields', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'x + field',
                expectedResult: '''
            (function(x) {
              return x + this.field;
            }.bind(this)(
              1
            ))
            ''');
          });

          test('expression using private fields', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'x + _field',
                expectedResult: '''
            (function(x) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const dart = dart_sdk.dart;
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              var S = {_field\$1: dart.privateName(foo, "_field")};
              return x + this[S._field\$1];
            }.bind(this)(
            1
            ))
            ''');
          });

          test('private field modification', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: '_field = 2',
                expectedResult: '''
            (function(x) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const dart = dart_sdk.dart;
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              var S = {_field\$1: dart.privateName(foo, "_field")};
              return this[S._field\$1] = 2;
            }.bind(this)(
            1
            ))
            ''');
          });

          test('field modification', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'field = 2',
                expectedResult: '''
            (function(x) {
              return this.field = 2;
            }.bind(this)(
            1
            ))
            ''');
          });

          test('private static field modification', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: '_staticField = 2',
                expectedResult: '''
            (function(x) {
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              return foo.C._staticField = 2;
            }.bind(this)(
            1
            ))
            ''');
          });

          test('static field modification', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'staticField = 2',
                expectedResult: '''
            (function(x) {
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              return foo.C.staticField = 2;
            }.bind(this)(
            1
            ))
            ''');
          });
        });

        group('Expression compiler tests in async method:', () {
          var source = '''
          ${options.dartLangComment}
          class C {
            C(int this.field, int this._field);

            int _field;
            int field;

            Future<int> asyncMethod(int x) async {
              /* evaluation placeholder */
              return x;
            }
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
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'typo',
                expectedError:
                    "The getter 'typo' isn't defined for the class 'C'");
          });

          test('local', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'x',
                expectedResult: '''
            (function(x) {
              return x;
            }.bind(this)(
            1
            ))
            ''');
          });

          test('this', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'this',
                expectedResult: '''
            (function(x) {
              return this;
            }.bind(this)(
            1
            ))
            ''');
          });
        });

        group('Expression compiler tests in global function:', () {
          var source = '''
          ${options.dartLangComment}
          extension NumberParsing on String {
            int parseInt() {
              return int.parse(this);
            }
          }

          int global = 42;

          class C {
            C(int this.field, int this._field);

            static int staticField = 0;
            static int _staticField = 1;

            int _field;
            int field;

            int methodFieldAccess(int x) {
              return (x + _field + _staticField);
            }
            int methodFieldAccess(int x) {
              return (x)
            }

            Future<int> asyncMethod(int x) async {
              return x;
            }
          }

          int main() {
            int x = 15;
            var c = C(1, 2);
            /* evaluation placeholder */
            return 0;
          }
          ''';

          TestDriver driver;
          setUp(() {
            driver = TestDriver(options, source);
          });

          tearDown(() {
            driver.delete();
          });

          test('compilation error', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null'},
                expression: 'typo',
                expectedError: "Getter not found: 'typo'.");
          });

          test('local with primitive type', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null'},
                expression: 'x',
                expectedResult: '''
            (function(x, c) {
              return x;
            }(
              1,
              null
            ))
            ''');
          });

          test('local object', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null'},
                expression: 'c',
                expectedResult: '''
            (function(x, c) {
              return c;
            }(
              1,
              null
            ))
            ''');
          });

          test('create new object', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null'},
                expression: 'C(1,3)',
                expectedResult: '''
            (function(x, c) {
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              return new foo.C.new(1, 3);
            }(
              1,
              null
            ))
            ''');
          });

          test('access field of new object', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null'},
                expression: 'C(1,3)._field',
                expectedResult: '''
            (function(x, c) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const dart = dart_sdk.dart;
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              var S = {_field\$1: dart.privateName(foo, "_field")};
              return new foo.C.new(1, 3)[S._field\$1];
            }(
              1,
              null
            ))
            ''');
          });

          test('access static field', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null'},
                expression: 'C.staticField',
                expectedResult: '''
            (function(x, c) {
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              return foo.C.staticField;
            }(
              1,
              null
            ))
            ''');
          });

          test('expression using private static fields', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null'},
                expression: 'C._staticField',
                expectedError: "Error: Getter not found: '_staticField'.");
          });

          test('access field', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null'},
                expression: 'c.field',
                expectedResult: '''
            (function(x, c) {
              return c.field;
            }(
              1,
              null
            ))
            ''');
          });

          test('access private field', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null'},
                expression: 'c._field',
                expectedResult: '''
            (function(x, c) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const dart = dart_sdk.dart;
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              var S = {_field\$1: dart.privateName(foo, "_field")};
              return c[S._field\$1];
            }(
                1,
                null
            ))
            ''');
          });

          test('method call', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null'},
                expression: 'c.methodFieldAccess(2)',
                expectedResult: '''
            (function(x, c) {
              return c.methodFieldAccess(2);
            }(
              1,
              null
            ))
            ''');
          });

          test('async method call', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null'},
                expression: 'c.asyncMethod(2)',
                expectedResult: '''
            (function(x, c) {
              return c.asyncMethod(2);
            }(
              1,
              null
            ))
            ''');
          });

          test('extension method call', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null'},
                expression: '"1234".parseInt()',
                expectedResult: '''
            (function(x, c) {
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              return foo['NumberParsing|parseInt']("1234");
            }(
              1,
              null
            ))
            ''');
          });

          test('private field modification', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null'},
                expression: 'c._field = 2',
                expectedResult: '''
            (function(x, c) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const dart = dart_sdk.dart;
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              var S = {_field\$1: dart.privateName(foo, "_field")};
              return c[S._field\$1] = 2;
            }(
              1,
              null
            ))
            ''');
          });

          test('field modification', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null'},
                expression: 'c.field = 2',
                expectedResult: '''
            (function(x, c) {
              return c.field = 2;
            }(
              1,
              null
            ))
            ''');
          });

          test('private static field modification', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null'},
                expression: 'C._staticField = 2',
                expectedError: "Setter not found: '_staticField'.");
          });

          test('static field modification', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null'},
                expression: 'C.staticField = 2',
                expectedResult: '''
            (function(x, c) {
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              return foo.C.staticField = 2;
            }(
              1,
              null
            ))
            ''');
          });

          test('call global function from core library', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null'},
                expression: 'print(x)',
                expectedResult: '''
            (function(x, c) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const core = dart_sdk.core;
              return core.print(x);
            }(
              1,
              null
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

        group('Expression compiler tests in method with no type use:', () {
          var source = '''
          ${options.dartLangComment}
          abstract class Key {
            const factory Key(String value) = ValueKey;
            const Key.empty();
          }

          abstract class LocalKey extends Key {
            const LocalKey() : super.empty();
          }

          class ValueKey implements LocalKey {
            const ValueKey(this.value);
            final String value;
          }

          class MyClass {
            const MyClass(this._t);
            final int _t;
          }

          int bar(int p){
            return p;
          }
          int baz(String t){
            return t;
          }
          void main() {
            var k = Key('t');
            MyClass c = MyClass(0);
            int p = 1;
            const t = 1;

            /* evaluation placeholder */
            print('\$c, \$k, \$t');
          }
          ''';

          TestDriver driver;
          setUp(() {
            driver = TestDriver(options, source);
          });

          tearDown(() {
            driver.delete();
          });

          test('call function not using type', () async {
            await driver.check(
                scope: <String, String>{'p': '1'},
                expression: 'bar(p)',
                expectedResult: '''
            (function(p) {
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              return foo.bar(p);
            }(
              1
            ))
            ''');
          });

          test('call function using type', () async {
            await driver.check(
                scope: <String, String>{'p': '0'},
                expression: 'baz(p as String)',
                expectedResult: '''
            (function(p) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const core = dart_sdk.core;
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              return foo.baz(core.String.as(p));
            }(
              0
            ))
            ''');
          });

          test('evaluate new const expression', () async {
            await driver.check(
                scope: <String, String>{'p': '1'},
                expression: 'const MyClass(1)',
                expectedResult: '''
            (function(p) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const dart = dart_sdk.dart;
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              var S = {MyClass__t: dart.privateName(foo, "MyClass._t")};
              const CT = Object.create(null);
              dart.defineLazy(CT, {
                get C0() {
                  return C[0] = dart.const({
                    __proto__: foo.MyClass.prototype,
                    [S.MyClass__t]: 1
                  });
                }
              }, false);
              var C = [void 0];
              return C[0] || CT.C0;
            }(
              1
            ))
            ''');
          });

          test('evaluate optimized const expression', () async {
            await driver.check(
                scope: <String, String>{},
                expression: 't',
                expectedResult: '''
            (function() {
              return 1;
            }(
            ))
            ''');
          },
              skip: 'Cannot compile constants optimized away by the frontend. '
                  'Issue: https://github.com/dart-lang/sdk/issues/41999');

          test('evaluate factory constructor call', () async {
            await driver.check(
                scope: <String, String>{'p': '1'},
                expression: "Key('t')",
                expectedResult: '''
            (function(p) {
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              return new foo.ValueKey.new("t");
            }(
              1
            ))
            ''');
          });

          test('evaluate const factory constructor call', () async {
            await driver.check(
                scope: <String, String>{'p': '1'},
                expression: "const Key('t')",
                expectedResult: '''
            (function(p) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const dart = dart_sdk.dart;
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              var S = {ValueKey_value: dart.privateName(foo, "ValueKey.value")};
              const CT = Object.create(null);
              dart.defineLazy(CT, {
                get C0() {
                  return C[0] = dart.const({
                    __proto__: foo.ValueKey.prototype,
                    [S.ValueKey_value]: "t"
                  });
                }
              }, false);
              var C = [void 0];
              return C[0] || CT.C0;
            }(
              1
            ))
            ''');
          });
        });

        group('Expression compiler tests in constructor:', () {
          var source = '''
          ${options.dartLangComment}
          extension NumberParsing on String {
            int parseInt() {
              return int.parse(this);
            }
          }

          int global = 42;

          class C {
            C(int this.field, int this._field) {
              int x = 1;
              /* evaluation placeholder */
              print(this.field);
            }

            static int staticField = 0;
            static int _staticField = 1;

            int _field;
            int field;

            int methodFieldAccess(int t) {
              return t + _field + _staticField;
            }

            Future<int> asyncMethod(int t) async {
              return t;
            }
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
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'typo',
                expectedError:
                    "The getter 'typo' isn't defined for the class 'C'");
          });

          test('local', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'x',
                expectedResult: '''
            (function(x) {
              return x;
            }.bind(this)(
              1
            ))
            ''');
          });

          test('this', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'this',
                expectedResult: '''
            (function(x) {
              return this;
            }.bind(this)(
              1
            ))
            ''');
          });

          test('expression using locals', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'x + 1',
                expectedResult: '''
            (function(x) {
              return x + 1;
            }.bind(this)(
              1
            ))
            ''');
          });

          test('expression using static fields', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'x + staticField',
                expectedResult: '''
            (function(x) {
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              return x + foo.C.staticField;
            }.bind(this)(
              1
            ))
            ''');
          });

          test('expression using private static fields', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'x + _staticField',
                expectedResult: '''
            (function(x) {
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              return x + foo.C._staticField;
            }.bind(this)(
              1
            ))
            ''');
          });

          test('expression using fields', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'x + field',
                expectedResult: '''
            (function(x) {
              return x + this.field;
            }.bind(this)(
              1
            ))
            ''');
          });

          test('expression using private fields', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'x + _field',
                expectedResult: '''
            (function(x) {
              const dart_sdk = ${options.loadModule}('dart_sdk');
              const dart = dart_sdk.dart;
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              var S = {_field\$1: dart.privateName(foo, "_field")};
              return x + this[S._field\$1];
            }.bind(this)(
                1
            ))
            ''');
          });

          test('expression using globals', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'x + global',
                expectedResult: '''
            (function(x) {
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              return x + foo.global;
            }.bind(this)(
              1
            ))
            ''');
          });

          test('method call', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'methodFieldAccess(2)',
                expectedResult: '''
            (function(x) {
              return this.methodFieldAccess(2);
            }.bind(this)(
              1
            ))
            ''');
          });

          test('async method call', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'asyncMethod(2)',
                expectedResult: '''
            (function(x) {
              return this.asyncMethod(2);
            }.bind(this)(
              1
            ))
            ''');
          });

          test('extension method call', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: '"1234".parseInt()',
                expectedResult: '''
            (function(x) {
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              return foo['NumberParsing|parseInt']("1234");
            }.bind(this)(
              1
            ))
            ''');
          });

          test('private field modification', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: '_field = 2',
                expectedResult: '''
          (function(x) {
            const dart_sdk = ${options.loadModule}('dart_sdk');
            const dart = dart_sdk.dart;
            const foo\$46dart = ${options.loadModule}('foo.dart');
            const foo = foo\$46dart.foo;
            var S = {_field\$1: dart.privateName(foo, "_field")};
            return this[S._field\$1] = 2;
          }.bind(this)(
            1
          ))
          ''');
          });

          test('field modification', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'field = 2',
                expectedResult: '''
            (function(x) {
              return this.field = 2;
            }.bind(this)(
              1
            ))
            ''');
          });

          test('private static field modification', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: '_staticField = 2',
                expectedResult: '''
            (function(x) {
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              return foo.C._staticField = 2;
            }.bind(this)(
              1
            ))
            ''');
          });

          test('static field modification', () async {
            await driver.check(
                scope: <String, String>{'x': '1'},
                expression: 'staticField = 2',
                expectedResult: '''
            (function(x) {
              const foo\$46dart = ${options.loadModule}('foo.dart');
              const foo = foo\$46dart.foo;
              return foo.C.staticField = 2;
            }.bind(this)(
              1
            ))
            ''');
          });
        });

        group('Expression compiler tests in loops:', () {
          var source = '''
          ${options.dartLangComment}
          int globalFunction() {
            int x = 15;
            var c = C(1, 2);

            for(int i = 0; i < 10; i++) {
              /* evaluation placeholder */
              print('\$i+\$x');
            };
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

          test('expression using local', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null', 'i': '0'},
                expression: 'x',
                expectedResult: '''
            (function(x, c, i) {
              return x;
            }(
              1,
              null,
              0
            ))
            ''');
          });

          test('expression using loop variable', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null', 'i': '0'},
                expression: 'i',
                expectedResult: '''
            (function(x, c, i) {
              return i;
            }(
              1,
              null,
              0
            ))
            ''');
          });
        });

        group('Expression compiler tests in iterator loops:', () {
          var source = '''
          ${options.dartLangComment}
          int globalFunction() {
            var l = <String>['1', '2', '3'];

            for(var e in l) {
              /* evaluation placeholder */
              print(e);
            };
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

          test('expression loop variable', () async {
            await driver.check(
                scope: <String, String>{'l': 'null', 'e': '1'},
                expression: 'e',
                expectedResult: '''
            (function(l, e) {
              return e;
            }(
              null,
              1
            ))
            ''');
          });
        });

        group('Expression compiler tests in conditional (then):', () {
          var source = '''
          ${options.dartLangComment}
          int globalFunction() {
            int x = 1;
            var c = C(1, 2);

            if (x == 14) {
              int y = 3;
              /* evaluation placeholder */
              print('\$y+\$x');
            } else {
              int z = 3;
              print('\$z+\$x');
            }
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

          test('expression using local', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null', 'y': '3'},
                expression: 'y',
                expectedResult: '''
            (function(x, c, y) {
              return y;
            }(
              1,
              null,
              3
            ))
            ''');
          });

          test('expression using local out of scope', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null', 'y': '3'},
                expression: 'z',
                expectedError: "Error: Getter not found: 'z'");
          });
        });

        group('Expression compiler tests in conditional (else):', () {
          var source = '''
          ${options.dartLangComment}
          int globalFunction() {
            int x = 1;
            var c = C(1, 2);

            if (x == 14) {
              int y = 3;
              print('\$y+\$x');
            } else {
              int z = 3;
              /* evaluation placeholder */
              print('\$z+\$x');
            }
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

          test('expression using local', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null', 'z': '3'},
                expression: 'z',
                expectedResult: '''
            (function(x, c, z) {
              return z;
            }(
              1,
              null,
              3
            ))
            ''');
          });

          test('expression using local out of scope', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null', 'z': '3'},
                expression: 'y',
                expectedError: "Error: Getter not found: 'y'");
          });
        });

        group('Expression compiler tests after conditionals:', () {
          var source = '''
          ${options.dartLangComment}
          int globalFunction() {
            int x = 1;
            var c = C(1, 2);

            if (x == 14) {
              int y = 3;
              print('\$y+\$x');
            } else {
              int z = 3;
              print('\$z+\$x');
            }
            /* evaluation placeholder */
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

          test('expression using local', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null'},
                expression: 'x',
                expectedResult: '''
            (function(x, c) {
              return x;
            }(
              1,
              null
            ))
            ''');
          });

          test('expression using local out of scope', () async {
            await driver.check(
                scope: <String, String>{'x': '1', 'c': 'null'},
                expression: 'z',
                expectedError: "Error: Getter not found: 'z'");
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
