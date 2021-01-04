// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:io' show Directory, File;

import 'package:cli_util/cli_util.dart';
import 'package:dev_compiler/dev_compiler.dart';
import 'package:dev_compiler/src/compiler/module_builder.dart';
import 'package:front_end/src/api_unstable/ddc.dart';
import 'package:front_end/src/api_prototype/compiler_options.dart'
    show CompilerOptions;
import 'package:front_end/src/compute_platform_binaries_location.dart';
import 'package:front_end/src/fasta/incremental_serializer.dart';
import 'package:kernel/ast.dart' show Component, Library;
import 'package:kernel/target/targets.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

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

  SetupCompilerOptions(bool soundNullSafety)
      : options = getOptions(soundNullSafety),
        dartLangComment =
            soundNullSafety ? dartSoundComment : dartUnsoundComment {
    options.onDiagnostic = (DiagnosticMessage m) {
      errors.addAll(m.plainTextFormatted);
    };
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
      'Name: $name, File: $file, Package: $package, path: $path';
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
    var classHierarchy = compiler.getClassHierarchy();
    var compilerOptions = SharedCompilerOptions(replCompile: true);
    var coreTypes = compiler.getCoreTypes();

    final importToSummary = Map<Library, Component>.identity();
    final summaryToModule = Map<Component, String>.identity();
    for (var lib in component.libraries) {
      importToSummary[lib] = component;
    }
    summaryToModule[component] = 'foo.dart';

    var kernel2jsCompiler = ProgramCompiler(component, classHierarchy,
        compilerOptions, importToSummary, summaryToModule,
        coreTypes: coreTypes);
    kernel2jsCompiler.emitModule(component);

    // create expression compiler
    var evaluator = ExpressionCompiler(
      setup.options,
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
  group('Unsound null safety:', () {
    var options = SetupCompilerOptions(false);

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
              T.VoidTodynamic = () => (T.VoidTodynamic = dart.constFn(dart.fnType(dart.dynamic, [])))();
              dart.defineLazy(CT, {
                get C0() {
                  return C[0] = dart.fn(foo.main, T.VoidTodynamic());
                }
              }, false);
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
            expectedError: "The getter 'typo' isn't defined for the class 'C'");
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
              let _field = dart.privateName(foo, "_field");
              return dart.notNull(x) + dart.notNull(this[_field]);
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
              let _field = dart.privateName(foo, "_field");
              return this[_field] = 2;
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
            expectedError: "The getter 'typo' isn't defined for the class 'C'");
      });

      test('expression using static fields', () async {
        await driver.check(
            scope: <String, String>{'x': '1'},
            expression: 'x + staticField',
            expectedResult: '''
            (function(x) {
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
              let _field = dart.privateName(foo, "_field");
              return dart.notNull(x) + dart.notNull(this[_field]);
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
              let _field = dart.privateName(foo, "_field");
              return this[_field] = 2;
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
            expectedError: "The getter 'typo' isn't defined for the class 'C'");
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
              let _field = dart.privateName(foo, "_field");
              return new foo.C.new(1, 3)[_field];
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
              let _field = dart.privateName(foo, "_field");
              return c[_field];
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
              let _field = dart.privateName(foo, "_field");
              return c[_field] = 2;
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
        await driver.check(
            scope: <String, String>{'x': '1', 'c': 'null', 'y': '3', 'z': '0'},
            expression: 'typo',
            expectedError: "Getter not found: 'typo'.");
      });

      test('expression using uncaptured variables', () async {
        await driver.check(
            scope: <String, String>{'x': '1', 'c': 'null', 'y': '3', 'z': '0'},
            expression: r"'$x+$y+$z'",
            expectedResult: '''
            (function(x, c, y, z) {
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
            scope: <String, String>{'x': '1', 'c': 'null', 'y': '3', 'z': '0'},
            expression: r"'$y+$z'",
            expectedResult: '''
            (function(x, c, y, z) {
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

      test('call function using type', () async {
        await driver.check(
            scope: <String, String>{'p': '1'},
            expression: 'bar(p)',
            expectedResult: '''
            (function(p) {
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
              T.StringL = () => (T.StringL = dart.constFn(dart.legacy(core.String)))();
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
              dart.defineLazy(CT, {
                get C0() {
                  return C[0] = dart.const({
                    __proto__: foo.MyClass.prototype,
                    [_t]: 1
                  });
                }
              }, false);
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
              dart.defineLazy(CT, {
                get C0() {
                  return C[0] = dart.const({
                    __proto__: foo.ValueKey.prototype,
                    [value]: "t"
                    });
                  }
              }, false);
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
            expectedError: "The getter 'typo' isn't defined for the class 'C'");
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
              let _field = dart.privateName(foo, "_field");
              return dart.notNull(x) + dart.notNull(this[_field]);
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
            let _field = dart.privateName(foo, "_field");
            return this[_field] = 2;
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

      TestDriver driver;
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
              T.StringL = () => (T.StringL = dart.constFn(dart.legacy(core.String)))();
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
            dart.defineLazy(CT, {
              get C1() {
                return C[1] = dart.const({
                  __proto__: foo.B.prototype
                });
              }
            }, false);
            return C[1] || CT.C1;
            }(
              null,
              null
            ))
            ''');
      });

      test('evaluation that reuses the constant container', () async {
        await driver.check(
            scope: <String, String>{'a': 'null', 'check': 'null'},
            expression: 'const A()',
            expectedResult: '''
            (function(a, check) {
              return C[0] || CT.C0;
            }(
              null,
              null
            ))
            ''');
      });
    });
  });

  group('Sound null safety:', () {
    var options = SetupCompilerOptions(true);

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
              T.VoidTodynamic = () => (T.VoidTodynamic = dart.constFn(dart.fnType(dart.dynamic, [])))();
              dart.defineLazy(CT, {
                get C0() {
                  return C[0] = dart.fn(foo.main, T.VoidTodynamic());
                }
              }, false);
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
            expectedError: "The getter 'typo' isn't defined for the class 'C'");
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
              let _field = dart.privateName(foo, "_field");
              return dart.notNull(x) + dart.notNull(this[_field]);
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
              let _field = dart.privateName(foo, "_field");
              return this[_field] = 2;
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
            expectedError: "The getter 'typo' isn't defined for the class 'C'");
      });

      test('expression using static fields', () async {
        await driver.check(
            scope: <String, String>{'x': '1'},
            expression: 'x + staticField',
            expectedResult: '''
            (function(x) {
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
              let _field = dart.privateName(foo, "_field");
              return dart.notNull(x) + dart.notNull(this[_field]);
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
              let _field = dart.privateName(foo, "_field");
              return this[_field] = 2;
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
            expectedError: "The getter 'typo' isn't defined for the class 'C'");
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
              let _field = dart.privateName(foo, "_field");
              return new foo.C.new(1, 3)[_field];
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
              let _field = dart.privateName(foo, "_field");
              return c[_field];
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
              let _field = dart.privateName(foo, "_field");
              return c[_field] = 2;
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
        await driver.check(
            scope: <String, String>{'x': '1', 'c': 'null', 'y': '3', 'z': '0'},
            expression: 'typo',
            expectedError: "Getter not found: 'typo'.");
      });

      test('expression using uncaptured variables', () async {
        await driver.check(
            scope: <String, String>{'x': '1', 'c': 'null', 'y': '3', 'z': '0'},
            expression: r"'$x+$y+$z'",
            expectedResult: '''
            (function(x, c, y, z) {
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
            scope: <String, String>{'x': '1', 'c': 'null', 'y': '3', 'z': '0'},
            expression: r"'$y+$z'",
            expectedResult: '''
            (function(x, c, y, z) {
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
              dart.defineLazy(CT, {
                get C0() {
                  return C[0] = dart.const({
                    __proto__: foo.MyClass.prototype,
                    [_t]: 1
                  });
                }
              }, false);
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
              dart.defineLazy(CT, {
                get C0() {
                  return C[0] = dart.const({
                    __proto__: foo.ValueKey.prototype,
                    [value]: "t"
                    });
                  }
              }, false);
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
            expectedError: "The getter 'typo' isn't defined for the class 'C'");
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
              let _field = dart.privateName(foo, "_field");
              return dart.notNull(x) + dart.notNull(this[_field]);
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
            let _field = dart.privateName(foo, "_field");
            return this[_field] = 2;
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
  });
}
