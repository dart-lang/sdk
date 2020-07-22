// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.import 'dart:io' show Platform, File;

import 'dart:io' show Directory, File;

import 'package:cli_util/cli_util.dart';
import 'package:dev_compiler/dev_compiler.dart';
import 'package:front_end/src/api_unstable/ddc.dart';
import 'package:front_end/src/api_prototype/compiler_options.dart'
    show CompilerOptions;
import 'package:front_end/src/compute_platform_binaries_location.dart';
import 'package:front_end/src/fasta/incremental_serializer.dart';
import 'package:frontend_server/src/expression_compiler.dart';
import 'package:kernel/ast.dart' show Component;
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
            new CompilerContext(
                new ProcessedOptions(options: options, inputs: [entryPoint])),
            initializeFrom,
            outlineOnly,
            incrementalSerializer);

  DevelopmentIncrementalCompiler.fromComponent(CompilerOptions options,
      this.entryPoint, Component componentToInitializeFrom,
      [bool outlineOnly, IncrementalSerializer incrementalSerializer])
      : super.fromComponent(
            new CompilerContext(
                new ProcessedOptions(options: options, inputs: [entryPoint])),
            componentToInitializeFrom,
            outlineOnly,
            incrementalSerializer);
}

class SetupCompilerOptions {
  static final sdkRoot = computePlatformBinariesLocation();
  static final sdkSummaryPath = p.join(sdkRoot.path, 'ddc_sdk.dill');
  static final librariesSpecificationUri =
      p.join(p.dirname(p.dirname(getSdkPath())), 'libraries.json');

  static CompilerOptions getOptions() {
    var options = CompilerOptions()
      ..verbose = false // set to true for debugging
      ..sdkRoot = sdkRoot
      ..target = DevCompilerTarget(TargetFlags())
      ..librariesSpecificationUri = Uri.base.resolve('sdk/lib/libraries.json')
      ..omitPlatform = true
      ..sdkSummary = sdkRoot.resolve(sdkSummaryPath)
      ..environmentDefines = const {};
    return options;
  }

  List<String> errors;
  final CompilerOptions options;

  SetupCompilerOptions() : options = getOptions() {
    errors = <String>[];
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
      : name = importUri.pathSegments.last.replaceAll('.dart', ''),
        path = importUri.scheme == 'package'
            ? 'packages/${importUri.path}'
            : importUri.path;

  String get package => importUri.toString();
  String get file => fileUri.path;

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
      int line,
      int column,
      Map<String, String> scope,
      String expression}) async {
    // initialize incremental compiler and create component
    var compiler = DevelopmentIncrementalCompiler(setup.options, input);
    var component = await compiler.computeDelta();

    // initialize ddc
    var classHierarchy = compiler.getClassHierarchy();
    var compilerOptions = SharedCompilerOptions(replCompile: true);
    var coreTypes = compiler.getCoreTypes();
    var kernel2jsCompiler = ProgramCompiler(
        component, classHierarchy, compilerOptions, const {}, const {},
        coreTypes: coreTypes);
    kernel2jsCompiler.emitModule(component);

    // create expression compiler
    var evaluator = new ExpressionCompiler(
        compiler, kernel2jsCompiler, component,
        verbose: setup.options.verbose,
        onDiagnostic: setup.options.onDiagnostic);

    // collect all module names and paths
    Map<Uri, Module> moduleInfo = _collectModules(component);

    var modules =
        moduleInfo.map((k, v) => MapEntry<String, String>(v.name, v.path));
    modules['dart'] = 'dart_sdk';
    modules['core'] = 'dart_sdk';

    var module = moduleInfo[input];

    setup.errors.clear();

    // compile
    var jsExpression = await evaluator.compileExpressionToJs(
        module.package, line, column, modules, scope, module.name, expression);

    if (setup.errors.length > 0) {
      jsExpression = setup.errors.toString().replaceAll(
          RegExp(
              r'org-dartlang-debug:synthetic_debug_expression:[0-9]*:[0-9]*:'),
          '');

      return TestCompilationResult(jsExpression, false);
    }

    return TestCompilationResult(jsExpression, true);
  }

  Map<Uri, Module> _collectModules(Component component) {
    Map<Uri, Module> modules = <Uri, Module>{};
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
  File file;
  int line;

  TestDriver(this.options, this.source) {
    var systemTempDir = Directory.systemTemp;
    tempDir = systemTempDir.createTempSync('foo bar');

    line = _getEvaluationLine(source);
    input = tempDir.uri.resolve('foo.dart');
    file = File.fromUri(input)..createSync();
    file.writeAsStringSync(source);
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
        line: line,
        column: 1,
        scope: scope,
        expression: expression);

    if (expectedError != null) {
      expect(result.isSuccess, isFalse);
      expect(_normalize(result.result), matches(expectedError));
    } else if (expectedResult != null) {
      expect(result.isSuccess, isTrue);
      expect(_normalize(result.result), _matches(expectedResult));
    }
  }

  String _normalize(String text) {
    return text.replaceAll(RegExp('\'.*foo.dart\''), '\'foo.dart\'');
  }

  Matcher _matches(String text) {
    var indent = text.indexOf(RegExp('[^ ]'));
    var unindented =
        text.split('\n').map((line) => line.substring(indent)).join('\n');

    return matches(RegExp(RegExp.escape(unindented), multiLine: true));
  }

  int _getEvaluationLine(String source) {
    RegExp placeholderRegExp = RegExp(r'/\* evaluation placeholder \*/');

    var lines = source.split('\n');
    for (int line = 0; line < lines.length; line++) {
      var content = lines[line];
      if (placeholderRegExp.firstMatch(content) != null) {
        return line + 1;
      }
    }
    return -1;
  }
}

int main() {
  SetupCompilerOptions options = SetupCompilerOptions();

  group('Expression compiler tests in extension method:', () {
    const String source = '''
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

    test('local', () async {
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

    test('this', () async {
      await driver.check(
          scope: <String, String>{'ret': '1234'},
          expression: 'this',
          expectedError: "Expected identifier, but got 'this'.");
    });
  });

  group('Expression compiler tests in method:', () {
    const String source = '''
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
            return dart.dsend(x, '+', [1]);
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
            return dart.dsend(x, '+', [foo.C.staticField]);
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
            let foo = require('foo.dart').foo;
            let _staticField = dart.privateName(foo, "_staticField");
            return dart.dsend(x, '+', [foo.C._staticField]);
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
            return dart.dsend(x, '+', [this.field]);
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
            let foo = require('foo.dart').foo;
            let _field = dart.privateName(foo, "_field");
            return dart.dsend(x, '+', [this[_field]]);
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
            return dart.dsend(x, '+', [foo.global]);
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
          let foo = require('foo.dart').foo;
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
            let foo = require('foo.dart').foo;
            let _staticField = dart.privateName(foo, "_staticField");
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
    const String source = '''
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
            return dart.dsend(x, '+', [foo.C.staticField]);
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
            let foo = require('foo.dart').foo;
            let _staticField = dart.privateName(foo, "_staticField");
            return dart.dsend(x, '+', [foo.C._staticField]);
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
            return dart.dsend(x, '+', [this.field]);
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
            let foo = require('foo.dart').foo;
            let _field = dart.privateName(foo, "_field");
            return dart.dsend(x, '+', [this[_field]]);
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
            let foo = require('foo.dart').foo;
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
            let foo = require('foo.dart').foo;
            let _staticField = dart.privateName(foo, "_staticField");
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
    const String source = '''
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
    const String source = '''
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
          1, null
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
          1, null
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
            1, null
            ))
            ''');
    });

    test('access field of new object', () async {
      await driver.check(
          scope: <String, String>{'x': '1', 'c': 'null'},
          expression: 'C(1,3)._field',
          expectedResult: '''
          (function(x, c) {
            let foo = require('foo.dart').foo;
            let _field = dart.privateName(foo, "_field");
            return new foo.C.new(1, 3)[_field];
          }(
          1, null
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
          1, null
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
            return dart.dloadRepl(c, 'field');
          }(
          1, null
          ))
          ''');
    });

    test('access private field', () async {
      await driver.check(
          scope: <String, String>{'x': '1', 'c': 'null'},
          expression: 'c._field',
          expectedResult: '''
          (function(x, c) {
            let foo = require('foo.dart').foo;
            let _field = dart.privateName(foo, "_field");
            return dart.dloadRepl(c, _field);
          }(
          1, null
          ))
          ''');
    });

    test('method call', () async {
      await driver.check(
          scope: <String, String>{'x': '1', 'c': 'null'},
          expression: 'c.methodFieldAccess(2)',
          expectedResult: '''
          (function(x, c) {
            return dart.dsendRepl(c, 'methodFieldAccess', [2]);
          }(
          1, null
          ))
          ''');
    });

    test('async method call', () async {
      await driver.check(
          scope: <String, String>{'x': '1', 'c': 'null'},
          expression: 'c.asyncMethod(2)',
          expectedResult: '''
          (function(x, c) {
            return dart.dsendRepl(c, 'asyncMethod', [2]);
          }(
          1, null
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
        1, null
        ))
        ''');
    });

    test('private field modification', () async {
      await driver.check(
          scope: <String, String>{'x': '1', 'c': 'null'},
          expression: 'c._field = 2',
          expectedResult: '''
          (function(x, c) {
            let foo = require('foo.dart').foo;
            let _field = dart.privateName(foo, "_field");
            return dart.dputRepl(c, _field, 2);
          }(
          1, null
          ))
          ''');
    });

    test('field modification', () async {
      await driver.check(
          scope: <String, String>{'x': '1', 'c': 'null'},
          expression: 'c.field = 2',
          expectedResult: '''
          (function(x, c) {
            return dart.dputRepl(c, 'field', 2);
          }(
          1, null
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
          1, null
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
          1, null
          ))
          ''');
    });
  });

  group('Expression compiler tests in closures:', () {
    const String source = r'''
      int globalFunction() {
      int x = 15;
      var c = C(1, 2);

      var outerClosure = (int y) {
        var closureCaptureInner = (int z) {
          /* evaluation placeholder */
          print('$y+$z');
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
          1, null, 3, 0
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
          1, null, 3, 0
          ))
          ''');
    });
  });

  group('Expression compiler tests in method with no type use', () {
    const String source = '''
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
            var intL = () => (intL = dart.constFn(dart.legacy(core.int)))();
            return foo.bar(intL().as(p));
          }(
          1
          ))
          ''');
    });

    test('evaluate new const expression', () async {
      await driver.check(
          scope: <String, String>{'p': '1'},
          expression: 'const MyClass(1)',
          expectedResult: '''
          (function(p) {
            return C0 || CT.C0;
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
        skip:
            'Cannot compile constants optimized away by the frontend'); // https://github.com/dart-lang/sdk/issues/41999

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
            return C0 || CT.C0;
          }(
          1
          ))
          ''');
    });
  });

  return 0;
}
