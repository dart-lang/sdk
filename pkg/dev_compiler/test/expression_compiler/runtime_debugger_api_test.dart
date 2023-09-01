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
      await driver.checkRuntime(
          breakpointId: 'BP',
          expression: 'dart.getLibraryMetadata("package:eval_test/test.dart")',
          expectedResult: {
            'type': 'object',
            'value': ['BaseClass', 'DerivedClass', 'AnotherClass']
          });
    });

    test('getClassMetadata (object)', () async {
      await driver.checkRuntime(
          breakpointId: 'BP',
          expression: 'dart.getClassMetadata("dart:core", "Object")',
          expectedResult: {
            'type': 'object',
            'value': {
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
                'hashAllUnordered': {'isStatic': true}
              }
            }
          });
    });

    test('getClassMetadata (base class)', () async {
      await driver.checkRuntime(
          breakpointId: 'BP',
          expression:
              'dart.getClassMetadata("package:eval_test/test.dart", "BaseClass")',
          expectedResult: {
            'type': 'object',
            'value': {
              'className': 'BaseClass',
              'superClassName': 'Object',
              'superClassLibraryId': 'dart:core',
              'fields': {
                'field': {'className': 'int', 'classLibraryId': 'dart:core'},
                'functionField': {'className': '() => void'},
                'nullableField': {
                  'className': 'BaseClass?',
                  'classLibraryId': 'package:eval_test/test.dart'
                },
                'nonNullableField': {
                  'className': 'AnotherClass',
                  'classLibraryId': 'package:eval_test/test.dart'
                },
                '_field': {'className': 'int', 'classLibraryId': 'dart:core'},
                '_unusedField': {
                  'className': 'int',
                  'classLibraryId': 'dart:core'
                },
                'lateFinalField': {
                  'className': 'int?',
                  'classLibraryId': 'dart:core'
                },
                'staticConstField': {'isStatic': true},
                'staticField': {'isStatic': true},
                '_staticField': {'isStatic': true},
                '_unusedStaticField': {'isStatic': true}
              },
              'methods': {
                'method': {},
                '_privateMethod': {},
                'lateFinalField': {'isGetter': true},
                'getter': {'isGetter': true},
                '_privateGetter': {'isGetter': true},
                'factory': {'isStatic': true},
                'staticMethod': {'isStatic': true}
              }
            }
          });
    });

    test('getClassMetadata (derived class)', () async {
      await driver.checkRuntime(
          breakpointId: 'BP',
          expression:
              'dart.getClassMetadata("package:eval_test/test.dart", "DerivedClass")',
          expectedResult: {
            'type': 'object',
            'value': {
              'className': 'DerivedClass',
              'superClassName': 'BaseClass',
              'superClassLibraryId': 'package:eval_test/test.dart',
              'fields': {
                'newPublicField': {
                  'isFinal': true,
                  'className': 'int',
                  'classLibraryId': 'dart:core'
                },
                '_newPrivateField': {
                  'isFinal': true,
                  'className': 'int',
                  'classLibraryId': 'dart:core'
                },
                '_newStaticConstPrivateField': {'isStatic': true}
              },
              'methods': {
                'additionalMethod': {},
                'lateFinalField': {'isGetter': true},
                'getter': {'isGetter': true},
                '_privateGetter': {'isGetter': true},
                'factory': {'isStatic': true},
                'staticMethod': {'isStatic': true}
              }
            }
          });
    });

    test('getClassMetadata (Record)', () async {
      await driver.checkRuntime(
          breakpointId: 'BP',
          expression: 'dart.getClassMetadata("dart:core", "Record")',
          expectedResult: {
            'type': 'object',
            'value': {
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
                'hashAllUnordered': {'isStatic': true}
              }
            }
          });
    });

    test('getObjectMetadata (int)', () async {
      await driver.checkRuntime(
          breakpointId: 'BP',
          expression: 'dart.getObjectMetadata(x)',
          expectedResult: {'type': 'object', 'value': {}});
    });

    test('getObjectMetadata (object)', () async {
      await driver.checkRuntime(
          breakpointId: 'BP',
          expression: 'dart.getObjectMetadata(object)',
          expectedResult: {
            'type': 'object',
            'value': {
              'className': 'Object',
              'libraryId': 'dart:core',
              'runtimeKind': 'object',
            }
          });
    });

    test('getObjectMetadata (object of derived class)', () async {
      await driver.checkRuntime(
          breakpointId: 'BP',
          expression: 'dart.getObjectMetadata(base)',
          expectedResult: {
            'type': 'object',
            'value': {
              'className': 'BaseClass',
              'libraryId': 'package:eval_test/test.dart',
              'runtimeKind': 'object',
            }
          });
    });

    test('getObjectMetadata (Set)', () async {
      await driver.checkRuntime(
          breakpointId: 'BP',
          expression: 'dart.getObjectMetadata(set)',
          expectedResult: {
            'type': 'object',
            'value': {
              'className': '_HashSet<String>',
              'libraryId': 'dart:collection',
              'runtimeKind': 'set',
              'length': 3
            }
          });
    });

    test('getObjectMetadata (List)', () async {
      await driver.checkRuntime(
          breakpointId: 'BP',
          expression: 'dart.getObjectMetadata(list)',
          expectedResult: {
            'type': 'object',
            'value': {
              'className': 'JSArray<int>',
              'libraryId': 'dart:_interceptors',
              'runtimeKind': 'list',
              'length': 3
            }
          });
      // Old type system incorrectly returns 'dart:_interceptors|_List<int>'
    }, skip: !setup.canaryFeatures);

    test('getObjectMetadata (Map)', () async {
      await driver.checkRuntime(
          breakpointId: 'BP',
          expression: 'dart.getObjectMetadata(map)',
          expectedResult: {
            'type': 'object',
            'value': {
              'className': 'IdentityMap<String, int>',
              'libraryId': 'dart:_js_helper',
              'runtimeKind': 'map',
              'length': 2
            }
          });
    });

    test('getObjectMetadata (Record)', () async {
      await driver.checkRuntime(
          breakpointId: 'BP',
          expression: 'dart.getObjectMetadata(record)',
          expectedResult: {
            'type': 'object',
            'value': {
              'className': 'Record',
              'libraryId': 'dart:core',
              'runtimeKind': 'record',
              'length': 3
            }
          });
    });

    test('getObjectMetadata (LegacyJavaScriptObject)', () async {
      await driver.checkRuntime(
          breakpointId: 'BP',
          expression:
              'dart.getObjectMetadata(new interceptors.LegacyJavaScriptObject.new())',
          expectedResult: {
            'type': 'object',
            'value': {
              'className': 'LegacyJavaScriptObject',
              'libraryId': 'dart:_interceptors',
              'runtimeKind': 'nativeObject',
            }
          });
    });

    test('getObjectMetadata (NativeError)', () async {
      await driver.checkRuntime(
          breakpointId: 'BP',
          expression:
              'dart.getObjectMetadata(new interceptors.NativeError.new())',
          expectedResult: {
            'type': 'object',
            'value': {
              'className': 'NativeError',
              'libraryId': 'dart:_interceptors',
              'runtimeKind': 'nativeError',
            }
          });
    });

    test('getObjectMetadata (DartError)', () async {
      await driver.checkRuntime(
          breakpointId: 'BP',
          expression: 'dart.getObjectMetadata(new dart.DartError())',
          expectedResult: {
            'type': 'object',
            'value': {
              'className': 'NativeError',
              'libraryId': 'dart:_interceptors',
              'runtimeKind': 'nativeError',
            }
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
      await driver.checkRuntime(
          breakpointId: 'BP',
          expression: 'dart.getObjectMetadata(xType)',
          expectedResult: {
            'type': 'object',
            'value': {
              'className': 'Type',
              'libraryId': 'dart:core',
              'runtimeKind': 'type',
              'typeName': typeName,
            }
          });
    });

    test('getObjectMetadata (base type)', () async {
      var typeName = await driver.evaluateDartExpressionInFrame(
        breakpointId: 'BP',
        expression: 'baseType.toString()',
      );
      await driver.checkRuntime(
          breakpointId: 'BP',
          expression: 'dart.getObjectMetadata(baseType)',
          expectedResult: {
            'type': 'object',
            'value': {
              'className': 'Type',
              'libraryId': 'dart:core',
              'runtimeKind': 'type',
              'typeName': typeName,
            }
          });
    });

    test('getObjectMetadata (type)', () async {
      var typeName = await driver.evaluateDartExpressionInFrame(
        breakpointId: 'BP',
        expression: 'baseTypeType.toString()',
      );
      await driver.checkRuntime(
          breakpointId: 'BP',
          expression: 'dart.getObjectMetadata(baseTypeType)',
          expectedResult: {
            'type': 'object',
            'value': {
              'className': 'Type',
              'libraryId': 'dart:core',
              'runtimeKind': 'type',
              'typeName': typeName,
            }
          });
    });

    test('getObjectMetadata (Set type)', () async {
      var typeName = await driver.evaluateDartExpressionInFrame(
        breakpointId: 'BP',
        expression: 'setType.toString()',
      );
      await driver.checkRuntime(
          breakpointId: 'BP',
          expression: 'dart.getObjectMetadata(setType)',
          expectedResult: {
            'type': 'object',
            'value': {
              'className': 'Type',
              'libraryId': 'dart:core',
              'runtimeKind': 'type',
              'typeName': typeName,
            }
          });
    });

    test('getObjectMetadata (List type)', () async {
      var typeName = await driver.evaluateDartExpressionInFrame(
        breakpointId: 'BP',
        expression: 'listType.toString()',
      );
      await driver.checkRuntime(
          breakpointId: 'BP',
          expression: 'dart.getObjectMetadata(listType)',
          expectedResult: {
            'type': 'object',
            'value': {
              'className': 'Type',
              'libraryId': 'dart:core',
              'runtimeKind': 'type',
              'typeName': typeName,
            }
          });
    });

    test('getObjectMetadata (Map type)', () async {
      var typeName = await driver.evaluateDartExpressionInFrame(
        breakpointId: 'BP',
        expression: 'mapType.toString()',
      );
      await driver.checkRuntime(
          breakpointId: 'BP',
          expression: 'dart.getObjectMetadata(mapType)',
          expectedResult: {
            'type': 'object',
            'value': {
              'className': 'Type',
              'libraryId': 'dart:core',
              'runtimeKind': 'type',
              'typeName': typeName,
            }
          });
    });

    test('getObjectMetadata (Record type)', () async {
      await driver.checkRuntime(
          breakpointId: 'BP',
          expression: 'dart.getObjectMetadata(recordType)',
          expectedResult: {
            'type': 'object',
            'value': {
              'className': 'RecordType',
              'libraryId': 'dart:_runtime',
              'runtimeKind': 'recordType',
              'length': 3
            }
          });
    });

    test('getObjectFieldNames (object)', () async {
      await driver.checkRuntime(
          breakpointId: 'BP',
          expression: 'dart.getObjectFieldNames(object)',
          expectedResult: {'type': 'object', 'value': []});
    });

    test('getObjectFieldNames (derived class)', () async {
      await driver.checkRuntime(
          breakpointId: 'BP',
          expression: 'dart.getObjectFieldNames(derived)',
          expectedResult: {
            'type': 'object',
            'value': [
              '_field',
              '_newPrivateField',
              '_unusedField',
              'field',
              'functionField',
              'lateFinalField',
              'newPublicField',
              'nonNullableField',
              'nullableField',
            ]
          });
    });

    test('getObjectFieldNames (base class)', () async {
      await driver.checkRuntime(
          breakpointId: 'BP',
          expression: 'dart.getObjectFieldNames(base)',
          expectedResult: {
            'type': 'object',
            'value': [
              '_field',
              '_unusedField',
              'field',
              'functionField',
              'lateFinalField',
              'nonNullableField',
              'nullableField',
            ]
          });
    });

    test('getSetElements', () async {
      await driver.checkRuntime(
          breakpointId: 'BP',
          expression: 'dart.getSetElements(set)',
          expectedResult: {
            'type': 'object',
            'value': {
              'entries': ['a', 'b', 'c']
            }
          });
    });

    test('getMapElements', () async {
      await driver.checkRuntime(
          breakpointId: 'BP',
          expression: 'dart.getMapElements(map)',
          expectedResult: {
            'type': 'object',
            'value': {
              'keys': ['a', 'b'],
              'values': [1, 2]
            }
          });
    });

    // TODO(annagrin): Add recursive check for nested objects.
    test('getTypeFields', () async {
      await driver.checkRuntime(
          breakpointId: 'BP',
          expression: 'dart.getTypeFields(baseType)',
          expectedResult: {
            'type': 'object',
            'value': {'hashCode': isA<int>(), 'runtimeType': {}}
          });
    });

    // TODO(annagrin): Add recursive check for nested objects.
    test('getTypeFields (nested)', () async {
      await driver.checkRuntime(
          breakpointId: 'BP',
          expression: 'dart.getTypeFields(baseTypeType)',
          expectedResult: {
            'type': 'object',
            'value': {'hashCode': isA<int>(), 'runtimeType': {}}
          });
    });

    test('getRecordFields', () async {
      await driver.checkRuntime(
          breakpointId: 'BP',
          expression: 'dart.getRecordFields(record)',
          expectedResult: {
            'type': 'object',
            'value': {
              'positionalCount': 2,
              'named': ['name'],
              'values': [0, 2, 'cat']
            }
          });
    });

    // TODO(annagrin): Add recursive check for nested objects.
    test('getRecordTypeFields', () async {
      await driver.checkRuntime(
          breakpointId: 'BP',
          expression: 'dart.getRecordTypeFields(recordType)',
          expectedResult: {
            'type': 'object',
            'value': {
              'positionalCount': 2,
              'named': ['name'],
              'types': [{}, {}, {}]
            }
          });
    });

    test('getFunctionMetadata (method)', () async {
      await driver.checkRuntime(
          breakpointId: 'BP',
          expression: 'dart.getFunctionMetadata(base.method)',
          expectedResult: {'type': 'string', 'value': 'method'});
    });

    test('getFunctionMetadata (static method)', () async {
      const module = 'test';
      const library = 'package:eval_test/test.dart';
      const className = 'BaseClass';
      const function = 'staticMethod';

      await driver.checkRuntime(
          breakpointId: 'BP',
          expression:
              'dart.getFunctionMetadata(dart.getModuleLibraries("$module")["$library"]["$className"]["$function"])',
          expectedResult: {'type': 'string', 'value': 'staticMethod'});
    });

    test('getFunctionName (global method)', () async {
      const module = 'test';
      const library = 'package:eval_test/test.dart';
      const function = 'globalFunction';

      await driver.checkRuntime(
          breakpointId: 'BP',
          expression:
              'dart.getFunctionMetadata(dart.getModuleLibraries("$module")["$library"]["$function"])',
          expectedResult: {'type': 'string', 'value': 'globalFunction'});
    });

    test('getSubRange (set)', () async {
      await driver.checkRuntime(
          breakpointId: 'BP',
          expression: 'dart.getSubRange(set, 0, 3)',
          expectedResult: {
            'type': 'object',
            'value': ['a', 'b', 'c']
          });

      await driver.checkRuntime(
          breakpointId: 'BP',
          expression: 'dart.getSubRange(set, 1, 2)',
          expectedResult: {
            'type': 'object',
            'value': ['b', 'c']
          });

      await driver.checkRuntime(
          breakpointId: 'BP',
          expression: 'dart.getSubRange(set, 1, 5)',
          expectedResult: {
            'type': 'object',
            'value': ['b', 'c']
          });
    });

    test('getSubRange (list)', () async {
      await driver.checkRuntime(
          breakpointId: 'BP',
          expression: 'dart.getSubRange(list, 0, 3)',
          expectedResult: {
            'type': 'object',
            'value': [1, 2, 3]
          });

      await driver.checkRuntime(
          breakpointId: 'BP',
          expression: 'dart.getSubRange(list, 1, 2)',
          expectedResult: {
            'type': 'object',
            'value': [2, 3]
          });

      await driver.checkRuntime(
          breakpointId: 'BP',
          expression: 'dart.getSubRange(list, 1, 5)',
          expectedResult: {
            'type': 'object',
            'value': [2, 3]
          });
    });

    test('getSubRange (map)', () async {
      await driver.checkRuntime(
          breakpointId: 'BP',
          expression: 'dart.getSubRange(map, 0, 3)',
          expectedResult: {
            'type': 'object',
            'value': isA<List>().having((p) => p.length, 'length', equals(2)),
          });

      await driver.checkRuntime(
          breakpointId: 'BP',
          expression: 'dart.getSubRange(map, 1, 2)',
          expectedResult: {
            'type': 'object',
            'value': isA<List>().having((p) => p.length, 'length', equals(1)),
          });

      await driver.checkRuntime(
          breakpointId: 'BP',
          expression: 'dart.getSubRange(map, 1, 5)',
          expectedResult: {
            'type': 'object',
            'value': isA<List>().having((p) => p.length, 'length', equals(1)),
          });
    });
  });
}
