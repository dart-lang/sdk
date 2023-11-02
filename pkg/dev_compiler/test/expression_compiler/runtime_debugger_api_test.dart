// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dev_compiler/src/compiler/module_builder.dart'
    show ModuleFormat;
import 'package:test/test.dart';

import '../shared_test_options.dart';
import 'expression_compiler_e2e_suite.dart';

void main(List<String> args) async {
  var driver = await ExpressionEvaluationTestDriver.init();

  tearDownAll(() async {
    await driver.finish();
  });
  group('(Sound null safety)', () {
    group('(AMD module system)', () {
      var setup = SetupCompilerOptions(
        soundNullSafety: true,
        legacyCode: false,
        moduleFormat: ModuleFormat.amd,
        args: args,
      );
      runSharedTests(setup, driver);
    });
  });

  group('(Weak null safety)', () {
    group('(AMD module system)', () {
      var setup = SetupCompilerOptions(
        soundNullSafety: false,
        legacyCode: false,
        moduleFormat: ModuleFormat.amd,
        args: args,
      );
      runSharedTests(setup, driver);
    });
  });
}

const simpleClassSource = '''
int get globalField { print('globalField access!'); return 0; }
late final int globalLateFinalField;

class BaseClass {
  static const int staticConstField = 0;
  static int staticField = 1;
  static int _staticField = 2;
  static int _unusedStaticField = 3;
  int field;

  int _field;
  int _unusedField = 4;

  late final int lateFinalField;

  int get getter => 6;
  int get _privateGetter => 7;

  void Function() functionField = staticMethod;
  BaseClass? nullableField;
  AnotherClass nonNullableField = AnotherClass();

  BaseClass(this.field, this._field) {
    int y = 1;
    lateFinalField = 35;
  }

  BaseClass.named(this.field): _field = 42;

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

  DerivedClass(): super(1, 3);
  void additionalMethod() { print('foo'); }
}

void globalFunction() {}

class AnotherClass {
  int a = 0;
}

main() {
  int x = 15;
  var derived = DerivedClass();
  var base = BaseClass(5, 6);
  var set = <String>{ 'a', 'b', 'c' };
  var list = <int>[1, 2, 3];
  var map = <String, int>{'a': 1, 'b': 2};
  var record = (0, 2, name: 'cat');
  var object = Object();

  var xType = x.runtimeType;
  var baseType = base.runtimeType;
  var baseTypeType = baseType.runtimeType;
  var setType = set.runtimeType;
  var listType = list.runtimeType;
  var mapType = map.runtimeType;
  var recordType = record.runtimeType;

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

    test('getLibraryMetadata', () async {
      await driver.checkRuntimeInFrame(
        breakpointId: 'BP',
        expression: 'dart.getLibraryMetadata("package:eval_test/test.dart")',
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
              'is': {'isStatic': true},
              'as': {'isStatic': true},
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
              'dart.getClassMetadata("package:eval_test/test.dart", "BaseClass")',
          expectedResult: {
            'className': 'BaseClass',
            'superClassName': 'Object',
            'superClassLibraryId': 'dart:core',
            'fields': {
              'field': {'className': 'int', 'classLibraryId': 'dart:core'},
              'functionField': {'className': '() => void'},
              'nullableField': {
                'className': 'BaseClass?',
                'classLibraryId': 'package:eval_test/test.dart',
              },
              'nonNullableField': {
                'className': 'AnotherClass',
                'classLibraryId': 'package:eval_test/test.dart',
              },
              '_field': {'className': 'int', 'classLibraryId': 'dart:core'},
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
            },
            'methods': {
              'method': {},
              '_privateMethod': {},
              'lateFinalField': {'isGetter': true},
              'getter': {'isGetter': true},
              '_privateGetter': {'isGetter': true},
              'factory': {'isStatic': true},
              'staticMethod': {'isStatic': true},
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
              'additionalMethod': {},
              'lateFinalField': {'isGetter': true},
              'getter': {'isGetter': true},
              '_privateGetter': {'isGetter': true},
              'factory': {'isStatic': true},
              'staticMethod': {'isStatic': true},
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
              'is': {'isStatic': true},
              'as': {'isStatic': true},
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
          });
    });

    test('getObjectMetadata (object of derived class)', () async {
      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression: 'dart.getObjectMetadata(base)',
          expectedResult: {
            'className': 'BaseClass',
            'libraryId': 'package:eval_test/test.dart',
            'runtimeKind': 'object',
          });
    });

    test('getObjectMetadata (Set)', () async {
      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression: 'dart.getObjectMetadata(set)',
          expectedResult: {
            'className': '_HashSet<String>',
            'libraryId': 'dart:collection',
            'runtimeKind': 'set',
            'length': 3,
          });
    });

    test('getObjectMetadata (List) (new types)', () async {
      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression: 'dart.getObjectMetadata(list)',
          expectedResult: {
            'className': 'JSArray<int>',
            'libraryId': 'dart:_interceptors',
            'runtimeKind': 'list',
            'length': 3,
          });
      // Old type system incorrectly returns 'dart:_interceptors|List<int>'
    }, skip: !setup.canaryFeatures);

    test('getObjectMetadata (List) (old types)', () async {
      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression: 'dart.getObjectMetadata(list)',
          expectedResult: {
            'className': 'List<int>',
            'libraryId': 'dart:_interceptors',
            'runtimeKind': 'list',
            'length': 3,
          });
      // Old type system incorrectly returns 'dart:_interceptors|List<int>'
    }, skip: setup.canaryFeatures);

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
          expression:
              'dart.getObjectMetadata(new interceptors.LegacyJavaScriptObject.new())',
          expectedResult: {
            'className': 'LegacyJavaScriptObject',
            'libraryId': 'dart:_interceptors',
            'runtimeKind': 'nativeObject',
          });
    });

    test('getObjectMetadata (NativeError)', () async {
      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression:
              'dart.getObjectMetadata(new interceptors.NativeError.new())',
          expectedResult: {
            'className': 'NativeError',
            'libraryId': 'dart:_interceptors',
            'runtimeKind': 'nativeError',
          });
    });

    test('getObjectMetadata (DartError)', () async {
      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression: 'dart.getObjectMetadata(new dart.DartError())',
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
      expect(typeName, 'BaseClass');
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
      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression: 'dart.getObjectMetadata(recordType)',
          expectedResult: {
            'className': 'RecordType',
            'libraryId': 'dart:_runtime',
            'runtimeKind': 'recordType',
            'length': 3,
          });
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
            '_unusedField',
            'field',
            'functionField',
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
            '_unusedField',
            'field',
            'functionField',
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

    // TODO(annagrin): Add recursive check for nested objects.
    test('getTypeFields', () async {
      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression: 'dart.getTypeFields(baseType)',
          expectedResult: {'hashCode': isA<int>(), 'runtimeType': {}});
    });

    // TODO(annagrin): Add recursive check for nested objects.
    test('getTypeFields (nested)', () async {
      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression: 'dart.getTypeFields(baseTypeType)',
          expectedResult: {'hashCode': isA<int>(), 'runtimeType': {}});
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

    test('getFunctionMetadata (method)', () async {
      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression: 'dart.getFunctionMetadata(base.method)',
          expectedResult: 'method');
    });

    test('getFunctionMetadata (static method)', () async {
      const module = 'test';
      const library = 'package:eval_test/test.dart';
      const className = 'BaseClass';
      const function = 'staticMethod';

      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression:
              'dart.getFunctionMetadata(dart.getModuleLibraries("$module")["$library"]["$className"]["$function"])',
          expectedResult: 'staticMethod');
    });

    test('getFunctionName (global method)', () async {
      const module = 'test';
      const library = 'package:eval_test/test.dart';
      const function = 'globalFunction';

      await driver.checkRuntimeInFrame(
          breakpointId: 'BP',
          expression:
              'dart.getFunctionMetadata(dart.getModuleLibraries("$module")["$library"]["$function"])',
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
  });
}
