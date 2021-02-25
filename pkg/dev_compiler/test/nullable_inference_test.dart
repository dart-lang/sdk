// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:async';
import 'dart:io';
import 'package:front_end/src/api_unstable/ddc.dart' as fe;
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/type_environment.dart';
import 'package:kernel/src/printer.dart';
import 'package:kernel/target/targets.dart';
import 'package:test/test.dart';

import 'package:dev_compiler/src/kernel/command.dart';
import 'package:dev_compiler/src/kernel/nullable_inference.dart';
import 'package:dev_compiler/src/kernel/js_typerep.dart';
import 'package:dev_compiler/src/kernel/target.dart';

const AstTextStrategy astTextStrategy = AstTextStrategy(
    includeLibraryNamesInTypes: true,
    includeLibraryNamesInMembers: true,
    useMultiline: false);

void main() {
  test('empty main', () async {
    await expectNotNull('main() {}', '');
  });

  group('literal', () {
    test('null', () async {
      await expectNotNull('main() { print(null); }', '');
    });
    test('bool', () async {
      await expectNotNull('main() { print(false); }', 'false');
    });
    test('int', () async {
      await expectNotNull('main() { print(42); }', '42');
    });
    test('double', () async {
      await expectNotNull('main() { print(123.0); }', '123.0');
    });
    test('String', () async {
      await expectNotNull('main() { print("hi"); }', '"hi"');
    });
    test('List', () async {
      await expectNotNull(
          'main() { print([42, null]); }', '<dart.core::int*>[42, null], 42');
    });
    test('Map', () async {
      await expectNotNull('main() { print({"x": null}); }',
          '<dart.core::String*, Null>{"x": null}, "x"');
    });

    test('Symbol', () async {
      await expectNotNull('main() { print(#hi); }', '#hi');
    });

    test('Type', () async {
      await expectNotNull('main() { print(Object); }', 'dart.core::Object*');
    });
  });

  test('this', () async {
    await expectNotNull('class C { m() { return this; } }', 'this');
  });

  test('is', () async {
    await expectNotNull('main() { 42 is int; null is int; }',
        '42 is dart.core::int*, 42, null is dart.core::int*');
  });

  test('as', () async {
    await expectNotNull(
        'main() { 42 as int; null as int; }', '42 as dart.core::int*, 42');
  });

  test('constructor', () async {
    await expectNotNull(
        'library a; class C {} main() { new C(); }', 'new a::C()');
  });

  group('operator', () {
    test('==', () async {
      // This is not a correct non-null assumption when user-defined operators,
      // are present, see: https://github.com/dart-lang/sdk/issues/31854
      await expectAllNotNull('main() { 1 == 1; }');
    });
    test('!', () async {
      await expectAllNotNull('main() { !false; }');
    });
    test('!=', () async {
      await expectAllNotNull('main() { 1 != 2; }');
    });
    test('&&', () async {
      await expectAllNotNull('main() { true && true; }');
    });
    test('||', () async {
      await expectAllNotNull('main() { true || true; }');
    });
    test('? :', () async {
      await expectAllNotNull('main() { true ? true : false; }');
    });
  });

  test('bool', () async {
    await expectAllNotNull('main() { true.toString(); false.hashCode; }');
  });

  group('int', () {
    test('arithmetic', () async {
      await expectAllNotNull(
          'main() { -0; 1 + 2; 3 - 4; 5 * 6; 7 / 8; 9 % 10; 11 ~/ 12; }');
    });
    test('bitwise', () async {
      await expectAllNotNull(
          'main() { 1 & 2; 3 | 4; 5 ^ 6; ~7; 8 << 9; 10 >> 11; }');
    });
    test('comparison', () async {
      await expectAllNotNull('main() { 1 < 2; 3 > 4; 5 <= 6; 7 >= 8; }');
    });
    test('getters', () async {
      await expectAllNotNull(
          'main() { 1.isOdd; 1.isEven; 1.isNegative; 1.isNaN; 1.isInfinite; '
          '1.isFinite; 1.sign; 1.bitLength; 1.hashCode; }');
    });
    test('methods', () async {
      await expectAllNotNull(
          'main() { 1.compareTo(2); 1.remainder(2); 1.abs(); 1.toInt(); '
          '1.ceil(); 1.floor(); 1.truncate(); 1.round(); 1.ceilToDouble(); '
          '1.floorToDouble(); 1.truncateToDouble(); 1.roundToDouble(); '
          '1.toDouble(); 1.clamp(2, 2); 1.toStringAsFixed(2); '
          '1.toStringAsExponential(); 1.toStringAsPrecision(2); 1.toString(); '
          '1.toRadixString(2); 1.toUnsigned(2); 1.toSigned(2); 1.modPow(2, 2); '
          '1.modInverse(2); 1.gcd(2); }');
    });
  });

  group('double', () {
    test('arithmetic', () async {
      await expectAllNotNull(
          'main() { -0.0; 1.0 + 2.0; 3.0 - 4.0; 5.0 * 6.0; 7.0 / 8.0; '
          '9.0 % 10.0; 11.0 ~/ 12.0; }');
    });
    test('comparison', () async {
      await expectAllNotNull(
          'main() { 1.0 < 2.0; 3.0 > 4.0; 5.0 <= 6.0; 7.0 >= 8.0; }');
    });
    test('getters', () async {
      await expectAllNotNull(
          'main() { (1.0).isNegative; (1.0).isNaN; (1.0).isInfinite; '
          '(1.0).isFinite; (1.0).sign; (1.0).hashCode; }');
    });
    test('methods', () async {
      await expectAllNotNull(
          'main() { (1.0).compareTo(2.0); (1.0).remainder(2.0); (1.0).abs(); '
          '(1.0).toInt(); (1.0).ceil(); (1.0).floor(); (1.0).truncate(); '
          '(1.0).round(); (1.0).ceilToDouble(); (1.0).floorToDouble(); '
          '(1.0).truncateToDouble(); (1.0).roundToDouble(); (1.0).toDouble(); '
          '(1.0).clamp(2.0, 2.0); (1.0).toStringAsFixed(2); (1.0).toString(); '
          '(1.0).toStringAsExponential(); (1.0).toStringAsPrecision(2); }');
    });
  });

  group('num', () {
    test('arithmetic', () async {
      await expectAllNotNull(
          'main() { num n = 1; -n; n + n; n - n; n * n; n / n; n % n; n % n; '
          'n ~/ n; }');
    });
    test('comparison', () async {
      await expectAllNotNull(
          'main() { num n = 1; n < n; n > n; n <= n; n >= n; }');
    });
    test('getters', () async {
      await expectAllNotNull(
          'main() { num n = 1; n.isNegative; n.isNaN; n.isInfinite; '
          'n.isFinite; n.sign; n.hashCode; }');
    });
    test('methods', () async {
      await expectAllNotNull(
          'main() { num n = 1; n.compareTo(n); n.remainder(n); n.abs(); '
          'n.toInt(); n.ceil(); n.floor(); n.truncate(); '
          'n.round(); n.ceilToDouble(); n.floorToDouble(); '
          'n.truncateToDouble(); n.roundToDouble(); n.toDouble(); '
          'n.clamp(n, n); n.toStringAsFixed(n); n.toString(); '
          'n.toStringAsExponential(); n.toStringAsPrecision(n); }');
    });
  });

  group('String', () {
    test('concatenation', () async {
      await expectAllNotNull('main() { "1" "2"; }');
    });
    test('interpolation', () async {
      await expectAllNotNull('main() { "1${2}"; }');
    });
    test('getters', () async {
      await expectAllNotNull(
          'main() { "".codeUnits; "".hashCode; "".isEmpty; "".isNotEmpty; '
          '"".length; "".runes; }');
    });
    test('operators', () async {
      await expectAllNotNull('main() { "" + ""; "" * 2; "" == ""; "x"[0]; }');
    });
    test('methods', () async {
      await expectAllNotNull('''main() {
        String s = '';
        s.codeUnitAt(0);
        s.contains(s);
        s.endsWith(s);
        s.indexOf(s);
        s.lastIndexOf(s);
        s.padLeft(1);
        s.padRight(1);
        s.replaceAll(s, s);
        s.replaceAllMapped(s, (_) => s);
        s.replaceFirst(s, s);
        s.replaceFirstMapped(s, (_) => s);
        s.replaceRange(1, 2, s);
        s.split(s);
        s.splitMapJoin(s, onMatch: (_) => s, onNonMatch: (_) => s);
        s.startsWith(s);
        s.substring(1);
        s.toLowerCase();
        s.toUpperCase();
        s.trim();
        s.trimLeft();
        s.trimRight();

        // compareTo relies on the interface target being String.compareTo
        // except that method does not exist unless we insert too many
        // forwarding stubs.
        //
        // s.compareTo(s);

        s.toString();
        // Pattern methods (allMatches, matchAsPrefix) are not recognized.
      }''');
    });
  });

  test('identical', () async {
    await expectNotNull('main() { identical(null, null); }',
        'dart.core::identical(null, null)');
  });

  test('throw', () async {
    await expectNotNull('main() { print(throw null); }', 'throw null');
  });

  test('rethrow', () async {
    await expectNotNull('main() { try {} catch (e) { rethrow; } }', 'rethrow');
  });

  test('function expression', () async {
    await expectNotNull(
        'main() { () => null; f() {}; f; }', 'Null () => null, f');
  });

  test('cascades (kernel BlockExpression)', () async {
    // `null..toString()` evaluates to `null` so it is nullable.
    await expectNotNull('main() { null..toString(); }', '');
    await expectAllNotNull('main() { 1..toString(); }');
  });

  group('variable', () {
    test('declaration not-null', () async {
      await expectNotNull('main() { var x = 42; print(x); }', '42, x');
    });
    test('declaration null', () async {
      await expectNotNull('main() { var x = null; print(x); }', '');
    });
    test('declaration without initializer', () async {
      await expectNotNull('main() { var x; x = 1; print(x); }', 'x = 1, 1');
    });
    test('assignment non-null', () async {
      await expectNotNull(
          'main() { var x = 42; x = 1; print(x); }', '42, x = 1, 1, x');
    });
    test('assignment null', () async {
      await expectNotNull('main() { var x = 42; x = null; print(x); }', '42');
    });
    test('flow insensitive', () async {
      await expectNotNull('''main() {
        var x = 1;
        if (true) {
          print(x);
        } else {
          x = null;
          print(x);
        }
      }''', '1, true');
    });

    test('declaration from variable', () async {
      await expectNotNull('''main() {
        var x = 1;
        var y = x;
        print(y);
        x = null;
      }''', '1');
    });
    test('declaration from variable nested', () async {
      await expectNotNull('''main() {
        var x = 1;
        var y = (x = null) == null;
        print(x);
        print(y);
      }''', '1, (x = null) == null, y');
    });
    test('declaration from variable transitive', () async {
      await expectNotNull('''main() {
        var x = 1;
        var y = x;
        var z = y;
        print(z);
        x = null;
      }''', '1');
    });
    test('declaration between variable transitive nested', () async {
      await expectNotNull('''main() {
        var x = 1;
        var y = 1;
        var z = y = x;
        print(z);
        x = null;
      }''', '1, 1');
    });

    test('for not-null', () async {
      await expectAllNotNull('''main() {
        for (var i = 0; i < 10; i++) {
          i;
        }
      }''');
    });
    test('for nullable', () async {
      await expectNotNull(
          '''main() {
        for (var i = 0; i < 10; i++) {
          if (i >= 10) i = null;
        }
      }''',
          // arithmetic operation results on `i` are themselves not null, even
          // though `i` is nullable.
          '0, i.{dart.core::num.<}(10), 10, i = i.{dart.core::num.+}(1), '
              'i.{dart.core::num.+}(1), 1, i.{dart.core::num.>=}(10), 10');
    });
    test('for-in', () async {
      await expectNotNull('''main() {
        for (var i in []) {
          print(i);
        }
      }''', '<dynamic>[]');
    });

    test('inner functions', () async {
      await expectNotNull('''main() {
        var y = 0;
        f(x) {
          var g = () => print('g');
          g();
          print(x);
          print(y);
          var z = 1;
          print(z);
        }
        f;
        f(42);
      }''', '0, void () => dart.core::print("g"), "g", g, y, 1, z, f, 42');
    });
    test('assignment to closure variable', () async {
      await expectNotNull('''main() {
        var y = 0;
        f(x) {
          y = x;
        }
        f;
        f(42);
        print(y);
      }''', '0, f, 42');
    });

    test('declaration visits initializer', () async {
      await expectAllNotNull('''main() {
        var x = () { var y = 1; return y; };
        x;
      }''');
    });
    test('assignment visits value', () async {
      await expectAllNotNull('''main() {
        var x = () => 42;
        x = () { var y = 1; return y; };
      }''');
    });
    test('assignment visits value with closure variable set', () async {
      await expectNotNull('''main() {
        var x = () => 42;
        var y = (() => x = null);
      }''', 'dart.core::int* () => 42, 42, Null () => x = null');
    });
    test('do not depend on unrelated variables', () async {
      await expectNotNull('''main() {
        var x;
        var y = identical(x, null);
        y; // this is still non-null even though `x` is nullable
      }''', 'dart.core::identical(x, null), y');
    });
    test('do not depend on unrelated variables updated later', () async {
      await expectNotNull('''main() {
        var x = 1;
        var y = identical(x, 1);
        x = null;
        y; // this is still non-null even though `x` is nullable
      }''', '1, dart.core::identical(x, 1), 1, y');
    });
  });
  group('functions parameters in SDK', () {
    setUp(() {
      // Using annotations here to test how the parameter is detected when
      // compiling functions from the SDK.
      // A regression test for: https://github.com/dart-lang/sdk/issues/37700
      useAnnotations = true;
    });
    tearDown(() {
      useAnnotations = false;
    });
    test('optional with default value', () async {
      await expectNotNull('''
        f(x, [y = 1]) { x; y; }
      ''', '1');
    });
    test('named with default value', () async {
      await expectNotNull('''
        f(x, {y = 1}) { x; y; }
      ''', '1');
    });
  });

  group('notNull', () {
    setUp(() {
      useAnnotations = true;
    });
    tearDown(() {
      useAnnotations = false;
    });
    var imports = "import 'package:meta/meta.dart';";
    group('(previously known kernel annotation bug)', () {
      test('variable without initializer', () async {
        await expectNotNull(
            '$imports main() { @notNull var x; print(x); }', 'x');
      });
      test('variable with initializer', () async {
        // TODO(jmesserly): this does not work in the Analyzer backend.
        await expectNotNull(
            '$imports main() { @notNull var x = null; print(x); }', 'x');
      });
      test('parameters', () async {
        await expectNotNull(
            '$imports f(@notNull x, [@notNull y, @notNull z = 42]) '
                '{ x; y; z; }',
            '42, x, y, z');
      });
      test('named parameters', () async {
        await expectNotNull(
            '$imports f({@notNull x, @notNull y: 42}) { x; y; }', '42, x, y');
      });
    });

    test('top-level field', () async {
      await expectNotNull(
          'library a; $imports @notNull int x; main() { x; }', 'a::x');
    });

    test('getter', () async {
      await expectNotNull(
          'library b; $imports @notNull get x => null; main() { x; }', 'b::x');
    });

    test('function', () async {
      await expectNotNull(
          'library a; $imports @notNull f() {} main() { f(); }', 'a::f()');
    });

    test('method', () async {
      await expectNotNull(
          'library b; $imports class C { @notNull m() {} } '
              'main() { var c = new C(); c.m(); }',
          'new b::C(), c.{b::C.m}(), c');
    });
  });
}

/// Given the Dart [code], expects the [expectedNotNull] kernel expression list
/// to be produced in the set of expressions that cannot be null by DDC's null
/// inference.
Future expectNotNull(String code, String expectedNotNull) async {
  code = '// @dart = 2.9\n$code';
  var result = await kernelCompile(code);
  var collector = NotNullCollector(result.librariesFromDill);
  result.component.accept(collector);
  var actualNotNull = collector.notNullExpressions
      // ConstantExpressions print the table offset - we want to compare
      // against the underlying constant value instead.
      .map((e) {
        if (e is ConstantExpression) {
          var c = e.constant;
          if (c is DoubleConstant &&
              c.value.isFinite &&
              c.value.truncateToDouble() == c.value) {
            // Print integer values as integers
            return BigInt.from(c.value).toString();
          }
          return c.toText(astTextStrategy);
        }
        return e.toText(astTextStrategy);
      })
      // Filter out our own NotNull annotations.  The library prefix changes
      // per test, so just filter on the suffix.
      .where((s) => !s.endsWith('_NotNull{}'))
      .join(', ');
  expect(actualNotNull, equals(expectedNotNull));
}

/// Given the Dart [code], expects all the expressions inferred to be not-null.
Future expectAllNotNull(String code) async {
  code = '// @dart = 2.9\n$code';
  var result = (await kernelCompile(code));
  result.component.accept(ExpectAllNotNull(result.librariesFromDill));
}

bool useAnnotations = false;
NullableInference inference;

class _TestRecursiveVisitor extends RecursiveVisitor<void> {
  final Set<Library> librariesFromDill;
  int _functionNesting = 0;
  TypeEnvironment _typeEnvironment;
  StatefulStaticTypeContext _staticTypeContext;

  _TestRecursiveVisitor(this.librariesFromDill);

  @override
  void visitComponent(Component node) {
    var coreTypes = CoreTypes(node);
    var hierarchy = ClassHierarchy(node, coreTypes);
    var jsTypeRep = JSTypeRep(
      fe.TypeSchemaEnvironment(coreTypes, hierarchy),
      hierarchy,
    );
    _typeEnvironment = jsTypeRep.types;
    _staticTypeContext = StatefulStaticTypeContext.stacked(_typeEnvironment);
    inference ??= NullableInference(jsTypeRep, _staticTypeContext);

    if (useAnnotations) {
      inference.allowNotNullDeclarations = useAnnotations;
      inference.allowPackageMetaAnnotations = useAnnotations;
    }
    super.visitComponent(node);
  }

  @override
  void visitLibrary(Library node) {
    _staticTypeContext.enterLibrary(node);
    if (librariesFromDill.contains(node) ||
        node.importUri.scheme == 'package' &&
            node.importUri.pathSegments[0] == 'meta') {
      return;
    }
    super.visitLibrary(node);
    _staticTypeContext.leaveLibrary(node);
  }

  @override
  void visitField(Field node) {
    _staticTypeContext.enterMember(node);
    super.visitField(node);
    _staticTypeContext.leaveMember(node);
  }

  @override
  void visitConstructor(Constructor node) {
    _staticTypeContext.enterMember(node);
    super.visitConstructor(node);
    _staticTypeContext.leaveMember(node);
  }

  @override
  void visitProcedure(Procedure node) {
    _staticTypeContext.enterMember(node);
    super.visitProcedure(node);
    _staticTypeContext.leaveMember(node);
  }

  @override
  void visitFunctionNode(FunctionNode node) {
    _functionNesting++;
    if (_functionNesting == 1) {
      inference.enterFunction(node);
    }
    super.visitFunctionNode(node);
    if (_functionNesting == 1) inference.exitFunction(node);
    _functionNesting--;
  }
}

class NotNullCollector extends _TestRecursiveVisitor {
  final notNullExpressions = <Expression>[];

  NotNullCollector(Set<Library> librariesFromDill) : super(librariesFromDill);

  @override
  void defaultExpression(Expression node) {
    if (!inference.isNullable(node)) {
      notNullExpressions.add(node);
    }
    super.defaultExpression(node);
  }
}

class ExpectAllNotNull extends _TestRecursiveVisitor {
  ExpectAllNotNull(Set<Library> librariesFromDill) : super(librariesFromDill);

  @override
  void defaultExpression(Expression node) {
    expect(inference.isNullable(node), false,
        reason: 'expression `$node` should be inferred as not-null');
    super.defaultExpression(node);
  }
}

fe.InitializedCompilerState _compilerState;
final _fileSystem = fe.MemoryFileSystem(Uri.file('/memory/'));

class CompileResult {
  final Component component;
  final Set<Library> librariesFromDill;

  CompileResult(this.component, this.librariesFromDill);
}

Future<CompileResult> kernelCompile(String code) async {
  var succeeded = true;
  void diagnosticMessageHandler(fe.DiagnosticMessage message) {
    if (message.severity == fe.Severity.error) {
      succeeded = false;
    }
    fe.printDiagnosticMessage(message, print);
  }

  var sdkUri = Uri.file('/memory/dart_sdk.dill');
  var sdkFile = _fileSystem.entityForUri(sdkUri);
  if (!await sdkFile.exists()) {
    sdkFile.writeAsBytesSync(
        File(defaultSdkSummaryPath(soundNullSafety: false)).readAsBytesSync());
  }
  var packagesUri = Uri.file('/memory/.packages');
  var packagesFile = _fileSystem.entityForUri(packagesUri);
  if (!await packagesFile.exists()) {
    packagesFile.writeAsStringSync('meta:/memory/meta/lib');
    _fileSystem
        .entityForUri(Uri.file('/memory/meta/lib/meta.dart'))
        .writeAsStringSync('''
class _NotNull { const _NotNull(); }
const notNull = const _NotNull();
class _NullCheck { const _NullCheck(); }
const nullCheck = const _NullCheck();
    ''');
  }

  var mainUri = Uri.file('/memory/test.dart');
  _fileSystem.entityForUri(mainUri).writeAsStringSync(code);
  var oldCompilerState = _compilerState;
  _compilerState = await fe.initializeCompiler(oldCompilerState, false, null,
      sdkUri, packagesUri, null, [], DevCompilerTarget(TargetFlags()),
      fileSystem: _fileSystem,
      explicitExperimentalFlags: const {},
      environmentDefines: const {},
      nnbdMode: fe.NnbdMode.Weak);
  if (!identical(oldCompilerState, _compilerState)) inference = null;
  var result =
      await fe.compile(_compilerState, [mainUri], diagnosticMessageHandler);
  expect(succeeded, true);

  var librariesFromDill = result.computeLibrariesFromDill();
  return CompileResult(result.component, librariesFromDill);
}
