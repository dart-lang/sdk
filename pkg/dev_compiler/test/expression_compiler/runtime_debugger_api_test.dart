// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dev_compiler/src/compiler/module_builder.dart'
    show ModuleFormat;
import 'package:test/test.dart';

import '../shared_test_options.dart';
import 'expression_compiler_e2e_suite.dart';

void main(List<String> args) async {
  await runAllTests(true, args);
}

Future<void> runAllTests(bool soundNullSafety, List<String> args) async {
  final driver = await ExpressionEvaluationTestDriver.init();
  tearDownAll(() async {
    await driver.finish();
  });
  final mode = soundNullSafety ? 'Sound' : 'Weak';
  group('($mode null safety)', () {
    group('(AMD module system)', () {
      final setup = SetupCompilerOptions(
        soundNullSafety: soundNullSafety,
        moduleFormat: ModuleFormat.amd,
        args: args,
        enableExperiments: [],
      );
      runSharedTests(setup, driver);
    });
    group('(DDC module system)', () {
      final setup = SetupCompilerOptions(
        soundNullSafety: soundNullSafety,
        moduleFormat: ModuleFormat.ddc,
        args: args,
        enableExperiments: [],
      );
      runSharedTests(setup, driver);
    });
  });
}

const simpleClassSource = '''
import 'dart:js_interop';

@JS()
external void eval(String code);

@JS()
external JSObject? catchError(JSFunction f);

int get globalField { print('globalField access!'); return 0; }
late final int globalLateFinalField;

class BaseClass<T extends num> {
  static const int staticConstField = 0;
  static int staticField = 1;
  static int _staticField = 2;
  static int _unusedStaticField = 3;
  int field;
  T genericField;

  int _field;
  int _unusedField = 4;

  late final int lateFinalField;

  int get getter => 6;
  int get _privateGetter => 7;

  void Function() functionField = staticMethod;
  BaseClass? nullableField;
  AnotherClass nonNullableField = AnotherClass();

  Ext get extensionTypeGetter => Ext(AnotherClass());
  Ext get _privateExtensionTypeGetter => Ext(AnotherClass());
  ExtString extensionTypeField = ExtString('hello');
  ExtString _privateExtensionTypeField = ExtString('hello');
  static const ExtDuration staticConstExtensionTypeField =
      const ExtDuration(Duration.zero);
  static ExtDuration staticExtensionTypeField = ExtDuration(Duration.zero);
  static final ExtDuration staticFinalExtensionTypeField =
      ExtDuration(Duration.zero);

  BaseClass(this.field, this._field) : genericField = 0 as T {
    int y = 1;
    lateFinalField = 35;
  }

  BaseClass.named(this.field): _field = 42, genericField = 0 as T;

  BaseClass.redirecting(int x) : this(x, 99);

  factory BaseClass.factory() => BaseClass(42, 0);

  void _privateMethod() {}

  void method() {}

  static void staticMethod() {}
}

class DerivedClass extends BaseClass {
  static const int _newStaticConstPrivateField = -3;
  final int _newPrivateField = 0;
  final int newPublicField = 1;

  DerivedClass(int field, int field2): super(field, field2);
  int stringLength(String input) => input.length;
}

DerivedClass globalFunction(int a, int b) {
  return DerivedClass(a, b);
}

class AnotherClass {
  int a = 0;
}

extension type Ext(AnotherClass _) {}

extension type ExtString(String _) {}

extension type const ExtDuration(Duration _) {}

main() {
  eval(\'\'\'
    globalThis.catchError = function (f) {
      try {
        f();
      } catch (e) {
        return e;
      }
      return null;
    };
  \'\'\');

  int x = 15;
  var derived = DerivedClass(1, 3);
  var base = BaseClass<int>(5, 6);
  var set = <String>{ 'a', 'b', 'c' };
  var list = <int>[1, 2, 3];
  var map = <String, int>{'a': 1, 'b': 2};
  var stream = Stream.fromIterable([1, 2, 3]);
  var record = (0, 2, name: 'cat');
  var object = Object();
  var globalMethod = globalFunction;
  var staticMethod = BaseClass.staticMethod;

  var xType = x.runtimeType;
  var baseType = base.runtimeType;
  var baseTypeType = baseType.runtimeType;
  var setType = set.runtimeType;
  var listType = list.runtimeType;
  var mapType = map.runtimeType;
  var recordType = record.runtimeType;

  // We want to test the type representation of the thrown error. However, we
  // can't do this in Dart as the `catch` block unwraps the error. Instead, use
  // interop to catch the JS wrapped error and return that directly.
  var error = catchError((() {
    throw 'Throwing Dart error that should be wrapped with DartError.';
  } as void Function()).toJS);

  // Breakpoint: BP
  print('foo');
}
''';

void runSharedTests(
    SetupCompilerOptions setup, ExpressionEvaluationTestDriver driver) {
  group('Runtime debugging API |', () {
    var source = simpleClassSource;

    setUpAll(() async {
      await driver.initSource(setup, source);
    });

    tearDownAll(() async {
      await driver.cleanupTest();
    });

    test('getClassesInLibrary', () async {
      var getClasses = setup.emitLibraryBundle
          ? 'getClassesInLibrary'
          : 'getLibraryMetadata';
      await driver.checkRuntimeInFrame(
        breakpointId: 'BP',
        expression: 'dart.$getClasses("package:eval_test/test.dart")',
        expectedResult: ['BaseClass', 'DerivedClass', 'AnotherClass'],
      );
    });

    test('getClassMetadata (object)', () async {
      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression: 'dart.getClassMetadata("dart:core", "Object")',
          expectedResult: {
            'className': 'Object',
            'fields': {},
            'methods': {
              '_equals': {},
              'toString': {},
              'noSuchMethod': {},
              'hashCode': {'isGetter': true},
              'runtimeType': {'isGetter': true},
              'hash': {'isStatic': true},
              'hashAll': {'isStatic': true},
              'hashAllUnordered': {'isStatic': true},
            }
          });
    });

    test('getClassMetadata (base class)', () async {
      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression:
              'dart.getClassMetadata("package:eval_test/test.dart", "BaseClass", base)',
          expectedResult: {
            'className': 'BaseClass',
            'superClassName': 'Object',
            'superClassLibraryId': 'dart:core',
            'fields': {
              'field': {'className': 'int', 'classLibraryId': 'dart:core'},
              'functionField': {'className': '() => void'},
              'nullableField': {
                'className': 'BaseClass<num>?',
                'classLibraryId': 'package:eval_test/test.dart',
              },
              'nonNullableField': {
                'className': 'AnotherClass',
                'classLibraryId': 'package:eval_test/test.dart',
              },
              '_field': {'className': 'int', 'classLibraryId': 'dart:core'},
              'genericField': {'className': 'int'},
              '_unusedField': {
                'className': 'int',
                'classLibraryId': 'dart:core',
              },
              'lateFinalField': {
                'className': 'int?',
                'classLibraryId': 'dart:core',
              },
              'staticConstField': {'isStatic': true},
              'staticField': {'isStatic': true},
              '_staticField': {'isStatic': true},
              '_unusedStaticField': {'isStatic': true},
              // NOTE: Fields typed as an extension type appear as their static
              // erased type for now. This isn't necessarily the runtime type
              // of the value either.
              'extensionTypeField': {
                'className': 'String',
                'classLibraryId': 'dart:core',
              },
              '_privateExtensionTypeField': {
                'className': 'String',
                'classLibraryId': 'dart:core',
              },
              'staticConstExtensionTypeField': {'isStatic': true},
              'staticExtensionTypeField': {'isStatic': true},
              'staticFinalExtensionTypeField': {'isStatic': true},
            },
            'methods': {
              'method': {},
              '_privateMethod': {},
              'lateFinalField': {'isGetter': true},
              'getter': {'isGetter': true},
              '_privateGetter': {'isGetter': true},
              'factory': {'isStatic': true},
              'staticMethod': {'isStatic': true},
              'extensionTypeGetter': {'isGetter': true},
              '_privateExtensionTypeGetter': {'isGetter': true},
            },
          });
    });

    test('getClassMetadata (derived class)', () async {
      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression:
              'dart.getClassMetadata("package:eval_test/test.dart", "DerivedClass")',
          expectedResult: {
            'className': 'DerivedClass',
            'superClassName': 'BaseClass',
            'superClassLibraryId': 'package:eval_test/test.dart',
            'fields': {
              'newPublicField': {
                'isFinal': true,
                'className': 'int',
                'classLibraryId': 'dart:core',
              },
              '_newPrivateField': {
                'isFinal': true,
                'className': 'int',
                'classLibraryId': 'dart:core',
              },
              '_newStaticConstPrivateField': {'isStatic': true},
            },
            'methods': {
              'stringLength': {},
              'lateFinalField': {'isGetter': true},
              'getter': {'isGetter': true},
              '_privateGetter': {'isGetter': true},
              'factory': {'isStatic': true},
              'staticMethod': {'isStatic': true},
              'extensionTypeGetter': {'isGetter': true},
              '_privateExtensionTypeGetter': {'isGetter': true},
            },
          });
    });

    test('getClassMetadata (Record)', () async {
      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression: 'dart.getClassMetadata("dart:core", "Record")',
          expectedResult: {
            'className': 'Record',
            'superClassName': 'Object',
            'superClassLibraryId': 'dart:core',
            'fields': {},
            'methods': {
              '_equals': {},
              'toString': {},
              'noSuchMethod': {},
              'hashCode': {'isGetter': true},
              'runtimeType': {'isGetter': true},
              'hash': {'isStatic': true},
              'hashAll': {'isStatic': true},
              'hashAllUnordered': {'isStatic': true},
            }
          });
    });

    test('getObjectMetadata (int)', () async {
      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression: 'dart.getObjectMetadata(x)',
          expectedResult: {});
    });

    test('getObjectMetadata (object)', () async {
      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression: 'dart.getObjectMetadata(object)',
          expectedResult: {
            'className': 'Object',
            'libraryId': 'dart:core',
            'runtimeKind': 'object',
            'length': 0,
          });
    });

    test('getObjectMetadata (object of derived class)', () async {
      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression: 'dart.getObjectMetadata(base)',
          expectedResult: {
            'className': 'BaseClass<int>',
            'libraryId': 'package:eval_test/test.dart',
            'runtimeKind': 'object',
            'length': 10,
          });
    });

    test('getObjectMetadata (Set)', () async {
      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression: 'dart.getObjectMetadata(set)',
          expectedResult: {
            'className': 'LinkedSet<String>',
            'libraryId': 'dart:_js_helper',
            'runtimeKind': 'set',
            'length': 3,
          });
    });

    test('getObjectMetadata (List)', () async {
      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression: 'dart.getObjectMetadata(list)',
          expectedResult: {
            'className': 'JSArray<int>',
            'libraryId': 'dart:_interceptors',
            'runtimeKind': 'list',
            'length': 3,
          });
    });

    test('getObjectMetadata (Map)', () async {
      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression: 'dart.getObjectMetadata(map)',
          expectedResult: {
            'className': 'IdentityMap<String, int>',
            'libraryId': 'dart:_js_helper',
            'runtimeKind': 'map',
            'length': 2,
          });
    });

    test('getObjectMetadata (Stream)', () async {
      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression: 'dart.getObjectMetadata(stream)',
          expectedResult: {
            'className': '_MultiStream<int>',
            'libraryId': 'dart:async',
            'runtimeKind': 'object',
            'length': 2,
          });
    });

    test('getObjectMetadata (Record)', () async {
      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression: 'dart.getObjectMetadata(record)',
          expectedResult: {
            'className': 'Record',
            'libraryId': 'dart:core',
            'runtimeKind': 'record',
            'length': 3,
          });
    });

    test('getObjectMetadata (LegacyJavaScriptObject)', () async {
      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression: 'dart.getObjectMetadata({})',
          expectedResult: {
            'className': 'LegacyJavaScriptObject',
            'libraryId': 'dart:_interceptors',
            'runtimeKind': 'nativeObject',
          });
    });

    test('getObjectMetadata (NativeError)', () async {
      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression: 'dart.getObjectMetadata(new Error())',
          expectedResult: {
            'className': 'NativeError',
            'libraryId': 'dart:_interceptors',
            'runtimeKind': 'nativeError',
          });
    });

    test('getObjectMetadata (DartError)', () async {
      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression: 'dart.getObjectMetadata(error)',
          expectedResult: {
            'className': 'NativeError',
            'libraryId': 'dart:_interceptors',
            'runtimeKind': 'nativeError',
          });
    });

    test('typeName (int type)', () async {
      var typeName = await driver.evaluateDartExpressionInFrame(
        breakpointId: 'BP',
        expression: 'xType.toString()',
      );
      expect(typeName, 'int');
    });

    test('typeName (base type)', () async {
      var typeName = await driver.evaluateDartExpressionInFrame(
        breakpointId: 'BP',
        expression: 'baseType.toString()',
      );
      expect(typeName, 'BaseClass<int>');
    });

    test('getObjectMetadata (int type)', () async {
      var typeName = await driver.evaluateDartExpressionInFrame(
        breakpointId: 'BP',
        expression: 'xType.toString()',
      );
      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression: 'dart.getObjectMetadata(xType)',
          expectedResult: {
            'className': 'Type',
            'libraryId': 'dart:core',
            'runtimeKind': 'type',
            'typeName': typeName,
          });
    });

    test('getObjectMetadata (base type)', () async {
      var typeName = await driver.evaluateDartExpressionInFrame(
        breakpointId: 'BP',
        expression: 'baseType.toString()',
      );
      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression: 'dart.getObjectMetadata(baseType)',
          expectedResult: {
            'className': 'Type',
            'libraryId': 'dart:core',
            'runtimeKind': 'type',
            'typeName': typeName,
          });
    });

    test('getObjectMetadata (type)', () async {
      var typeName = await driver.evaluateDartExpressionInFrame(
        breakpointId: 'BP',
        expression: 'baseTypeType.toString()',
      );
      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression: 'dart.getObjectMetadata(baseTypeType)',
          expectedResult: {
            'className': 'Type',
            'libraryId': 'dart:core',
            'runtimeKind': 'type',
            'typeName': typeName,
          });
    });

    test('getObjectMetadata (Set type)', () async {
      var typeName = await driver.evaluateDartExpressionInFrame(
        breakpointId: 'BP',
        expression: 'setType.toString()',
      );
      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression: 'dart.getObjectMetadata(setType)',
          expectedResult: {
            'className': 'Type',
            'libraryId': 'dart:core',
            'runtimeKind': 'type',
            'typeName': typeName,
          });
    });

    test('getObjectMetadata (List type)', () async {
      var typeName = await driver.evaluateDartExpressionInFrame(
        breakpointId: 'BP',
        expression: 'listType.toString()',
      );
      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression: 'dart.getObjectMetadata(listType)',
          expectedResult: {
            'className': 'Type',
            'libraryId': 'dart:core',
            'runtimeKind': 'type',
            'typeName': typeName,
          });
    });

    test('getObjectMetadata (Map type)', () async {
      var typeName = await driver.evaluateDartExpressionInFrame(
        breakpointId: 'BP',
        expression: 'mapType.toString()',
      );
      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression: 'dart.getObjectMetadata(mapType)',
          expectedResult: {
            'className': 'Type',
            'libraryId': 'dart:core',
            'runtimeKind': 'type',
            'typeName': typeName,
          });
    });

    test('getObjectMetadata (Record type)', () async {
      var typeName = await driver.evaluateDartExpressionInFrame(
        breakpointId: 'BP',
        expression: 'recordType.toString()',
      );
      expect(typeName, '(int, int, {String name})');

      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression: 'dart.getObjectMetadata(recordType)',
          expectedResult: {
            'className': 'Type',
            'libraryId': 'dart:core',
            'runtimeKind': 'recordType',
            'length': 3,
          });

      await driver.checkInFrame(
        breakpointId: 'BP',
        expression: 'record is Record',
        expectedResult: 'true',
      );

      await driver.checkInFrame(
        breakpointId: 'BP',
        expression: 'recordType is Type',
        expectedResult: 'true',
      );
    });

    test('getObjectFieldNames (object)', () async {
      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression: 'dart.getObjectFieldNames(object)',
          expectedResult: []);
    });

    test('getObjectFieldNames (derived class)', () async {
      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression: 'dart.getObjectFieldNames(derived)',
          expectedResult: [
            '_field',
            '_newPrivateField',
            '_privateExtensionTypeField',
            '_unusedField',
            'extensionTypeField',
            'field',
            'functionField',
            'genericField',
            'lateFinalField',
            'newPublicField',
            'nonNullableField',
            'nullableField',
          ]);
    });

    test('getObjectFieldNames (base class)', () async {
      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression: 'dart.getObjectFieldNames(base)',
          expectedResult: [
            '_field',
            '_privateExtensionTypeField',
            '_unusedField',
            'extensionTypeField',
            'field',
            'functionField',
            'genericField',
            'lateFinalField',
            'nonNullableField',
            'nullableField',
          ]);
    });

    test('getSetElements', () async {
      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression: 'dart.getSetElements(set)',
          expectedResult: {
            'entries': ['a', 'b', 'c'],
          });
    });

    test('getMapElements', () async {
      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression: 'dart.getMapElements(map)',
          expectedResult: {
            'keys': ['a', 'b'],
            'values': [1, 2],
          });
    });

    test('getRecordFields', () async {
      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression: 'dart.getRecordFields(record)',
          expectedResult: {
            'positionalCount': 2,
            'named': ['name'],
            'values': [0, 2, 'cat'],
          });
    });

    // TODO(annagrin): Add recursive check for nested objects.
    test('getRecordTypeFields', () async {
      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression: 'dart.getRecordTypeFields(recordType)',
          expectedResult: {
            'positionalCount': 2,
            'named': ['name'],
            'types': [{}, {}, {}],
          });
    });

    test('getFunctionName (method)', () async {
      var getFunctionName =
          setup.emitLibraryBundle ? 'getFunctionName' : 'getFunctionMetadata';
      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression: 'dart.$getFunctionName(base.method)',
          expectedResult: 'method');
    });

    test('getFunctionName (static method)', () async {
      var getFunctionName =
          setup.emitLibraryBundle ? 'getFunctionName' : 'getFunctionMetadata';

      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression: 'dart.$getFunctionName(staticMethod)',
          expectedResult: 'staticMethod');
    });

    test('getFunctionName (global method)', () async {
      var getFunctionName =
          setup.emitLibraryBundle ? 'getFunctionName' : 'getFunctionMetadata';

      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression: 'dart.$getFunctionName(globalMethod)',
          expectedResult: 'globalFunction');
    });

    test('getSubRange (set)', () async {
      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression: 'dart.getSubRange(set, 0, 3)',
          expectedResult: ['a', 'b', 'c']);

      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression: 'dart.getSubRange(set, 1, 2)',
          expectedResult: ['b', 'c']);

      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression: 'dart.getSubRange(set, 1, 5)',
          expectedResult: ['b', 'c']);
    });

    test('getSubRange (list)', () async {
      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression: 'dart.getSubRange(list, 0, 3)',
          expectedResult: [1, 2, 3]);

      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression: 'dart.getSubRange(list, 1, 2)',
          expectedResult: [2, 3]);

      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression: 'dart.getSubRange(list, 1, 5)',
          expectedResult: [2, 3]);
    });

    test('getSubRange (map)', () async {
      await driver.checkRuntimeInFrame(
        breakpointId: 'BP',
        expression: 'dart.getSubRange(map, 0, 3)',
        expectedResult:
            isA<List>().having((p) => p.length, 'length', equals(2)),
      );

      await driver.checkRuntimeInFrame(
        breakpointId: 'BP',
        expression: 'dart.getSubRange(map, 1, 2)',
        expectedResult:
            isA<List>().having((p) => p.length, 'length', equals(1)),
      );

      await driver.checkRuntimeInFrame(
        breakpointId: 'BP',
        expression: 'dart.getSubRange(map, 1, 5)',
        expectedResult:
            isA<List>().having((p) => p.length, 'length', equals(1)),
      );
    });

    test('callLibraryMethod', () async {
      await driver.checkRuntimeInFrame(
        breakpointId: 'BP',
        expression:
            "dart.getObjectMetadata(dart.callLibraryMethod('package:eval_test/test.dart', 'globalFunction', [1, 3]))",
        expectedResult: {
          'className': 'DerivedClass',
          'libraryId': 'package:eval_test/test.dart',
          'runtimeKind': 'object',
          'length': 12
        },
      );
    }, skip: !setup.emitLibraryBundle);

    test('callInstanceMethod', () async {
      await driver.checkRuntimeInFrame(
        breakpointId: 'BP',
        expression:
            "dart.callInstanceMethod(dart.callLibraryMethod('package:eval_test/test.dart', 'globalFunction', [1, 3]), 'stringLength', ['hello'])",
        expectedResult: 5,
      );
    }, skip: !setup.emitLibraryBundle);
  });

  group('extension type expression compilations |', () {
    var source = r'''
//@dart=3.3
void main() {
  Foo f = new Foo(42);
  Baz b = new Baz(new Bar(42));
  print(f);
  print(b);
  // Breakpoint: BP1
  print(f.value);
  print(b.value);
  f.printValue();
  f.printThis();
  b.printThis();
}
class Bar {
  final int i;
  Bar(this.i);
  String toString() => "Bar[$i]";
}
extension type Foo(int value) {
  void printValue() {
    // Breakpoint: BP2
    print("This foos value is '$value'");
  }
  String printThis() {
    var foo = value;
    // Breakpoint: BP3
    print("This foos this value is '$this'");
    return "I printed '$value'!";
  }
}
extension type Baz(Bar value) {
  String printThis() {
    var foo = value;
    // Breakpoint: BP4
    print("This Baz' this value is '$this'");
    return "I printed '$value'!";
  }
}
''';

    setUpAll(() async {
      await driver.initSource(setup, source);
    });

    tearDownAll(() async {
      await driver.cleanupTest();
    });

    test('value on extension type (int)', () async {
      var result = await driver.evaluateDartExpressionInFrame(
        breakpointId: 'BP1',
        expression: 'f.value',
      );
      expect(result, '42');
    });

    test('value on extension type (custom class)', () async {
      var result = await driver.evaluateDartExpressionInFrame(
        breakpointId: 'BP1',
        expression: 'b.value.toString()',
      );
      expect(result, 'Bar[42]');
    });

    test('method on extension type (int)', () async {
      var result = await driver.evaluateDartExpressionInFrame(
        breakpointId: 'BP1',
        expression: 'f.printThis()',
      );
      expect(result, "I printed '42'!");
    });

    test('method on extension type (custom class)', () async {
      var result = await driver.evaluateDartExpressionInFrame(
        breakpointId: 'BP1',
        expression: 'b.printThis()',
      );
      expect(result, "I printed 'Bar[42]'!");
    });

    test('inside extension type method (int) (1)', () async {
      var result = await driver.evaluateDartExpressionInFrame(
        breakpointId: 'BP2',
        expression: 'printThis()',
      );
      expect(result, "I printed '42'!");
    });

    test('inside extension type method (int) (2)', () async {
      var result = await driver.evaluateDartExpressionInFrame(
        breakpointId: 'BP3',
        expression: 'foo + value',
      );
      expect(result, '84');
    });

    test('inside extension type method (custom class) (1)', () async {
      var result = await driver.evaluateDartExpressionInFrame(
        breakpointId: 'BP4',
        expression: 'printThis()',
      );
      expect(result, "I printed 'Bar[42]'!");
    });

    test('inside extension type method (custom class) (2)', () async {
      var result = await driver.evaluateDartExpressionInFrame(
        breakpointId: 'BP4',
        expression: 'foo.i + value.i',
      );
      expect(result, '84');
    });
  });

  group('extensions expression compilations |', () {
    var source = r'''
void main() {
  int i = 42;
  Bar b = new Bar(42);
  print(i);
  print(b);
  // Breakpoint: BP1
  i.printThis();
  b.printThis();
}
class Bar {
  final int i;
  Bar(this.i);
  String toString() => "Bar[$i]";
}
extension Foo on int {
  String printThis() {
    var value = this;
    // Breakpoint: BP2
    print("This foos this value is '$this'");
    return "I printed '$value'!";
  }
}
extension Baz on Bar {
  String printThis() {
    var value = this;
    // Breakpoint: BP3
    print("This Bars this value is '$this'");
    return "I printed '$value'!";
  }
}''';

    setUpAll(() async {
      await driver.initSource(setup, source);
    });

    tearDownAll(() async {
      await driver.cleanupTest();
    });

    test('call function on extension (int)', () async {
      var result = await driver.evaluateDartExpressionInFrame(
        breakpointId: 'BP1',
        expression: 'i.printThis()',
      );
      expect(result, "I printed '42'!");
    });

    test('call function on extension (custom class)', () async {
      var result = await driver.evaluateDartExpressionInFrame(
        breakpointId: 'BP1',
        expression: 'b.printThis()',
      );
      expect(result, "I printed 'Bar[42]'!");
    });

    test('inside extension method (int) (1)', () async {
      var result = await driver.evaluateDartExpressionInFrame(
        breakpointId: 'BP2',
        expression: 'printThis()',
      );
      expect(result, "I printed '42'!");
    });

    test('inside extension type method (int) (2)', () async {
      var result = await driver.evaluateDartExpressionInFrame(
        breakpointId: 'BP2',
        expression: 'this + value',
      );
      expect(result, '84');
    });

    test('inside extension method (custom class) (1)', () async {
      var result = await driver.evaluateDartExpressionInFrame(
        breakpointId: 'BP3',
        expression: 'printThis()',
      );
      expect(result, "I printed 'Bar[42]'!");
    });

    test('inside extension type method (custom class) (2)', () async {
      var result = await driver.evaluateDartExpressionInFrame(
        breakpointId: 'BP3',
        expression: 'this.i + value.i',
      );
      expect(result, '84');
    });
  });

  group('part files expression compilations |', () {
    // WARNING: The (main) source and the part source have been constructred
    // so that the same offset (71) is valid on both, and both have an 'x'
    // variable, where one is a String and the other is an int. The 4 dots after
    // 'padding' for instance is not a mistake.
    var source = r'''
part 'part.dart';
void main() {
  String x = "foo";
  // padding....
  foo();
  print(x);
}''';
    var partSource = r'''
part of 'test.dart';
void foo() {
  int x = 42;
  // Breakpoint: BP1
  print(x);
}''';

    setUpAll(() async {
      await driver.initSource(setup, source, partSource: partSource);
    });

    tearDownAll(() async {
      await driver.cleanupTest();
    });

    test('can evaluate in part file', () async {
      var result = await driver.evaluateDartExpressionInFrame(
        breakpointId: 'BP1',
        expression: 'x + 1',
      );
      expect(result, '43');
    });
  });
}
