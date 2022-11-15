// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'test_client.dart';
import 'test_scripts.dart';
import 'test_support.dart';

main() {
  late DapTestSession dap;
  setUp(() async {
    dap = await DapTestSession.setUp();
  });
  tearDown(() => dap.tearDown());

  group('debug mode variables', () {
    test('provides variable list for frames', () async {
      final client = dap.client;
      final testFile = dap.createTestFile('''
void main(List<String> args) {
  final myVariable = 1;
  foo();
}

void foo() {
  final b = 2;
  print('Hello!'); $breakpointMarker
}
    ''');
      final breakpointLine = lineWith(testFile, breakpointMarker);

      final stop = await client.hitBreakpoint(testFile, breakpointLine);
      final stack = await client.getValidStack(
        stop.threadId!,
        startFrame: 0,
        numFrames: 2,
      );

      // Check top two frames (in `foo` and in `main`).
      await client.expectScopeVariables(
        stack.stackFrames[0].id, // Top frame: foo
        'Locals',
        '''
            b: 2, eval: b
        ''',
      );
      await client.expectScopeVariables(
        stack.stackFrames[1].id, // Second frame: main
        'Locals',
        '''
            args: List (0 items), eval: args, 0 items
            myVariable: 1, eval: myVariable
        ''',
      );
    });

    test('provides simple exception types for frames', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(r'''
void main(List<String> args) {
  throw 'my error';
}
    ''');

      final stop = await client.hitException(testFile);
      final topFrameId = await client.getTopFrameId(stop.threadId!);

      // Check for an additional Scope named "Exceptions" that includes the
      // exception.
      await client.expectScopeVariables(
        topFrameId,
        'Exceptions',
        r'''
            String: "my error", eval: $_threadException
        ''',
      );
    });

    test('provides complex exception types for frames', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(r'''
void main(List<String> args) {
  throw ArgumentError.notNull('args');
}
    ''');

      final stop = await client.hitException(testFile);
      final topFrameId = await client.getTopFrameId(stop.threadId!);

      // Check for an additional Scope named "Exceptions" that includes the
      // exception.
      await client.expectScopeVariables(
        topFrameId,
        'Exceptions',
        r'''
            invalidValue: null, eval: $_threadException.invalidValue
            message: "Must not be null", eval: $_threadException.message
            name: "args", eval: $_threadException.name
        ''',
      );
    });

    test('includes simple variable fields', () async {
      final client = dap.client;
      final testFile = dap.createTestFile('''
void main(List<String> args) {
  final myVariable = DateTime(2000, 1, 1);
  print('Hello!'); $breakpointMarker
}
    ''');
      final breakpointLine = lineWith(testFile, breakpointMarker);

      final stop = await client.hitBreakpoint(testFile, breakpointLine);
      await client.expectLocalVariable(
        stop.threadId!,
        expectedName: 'myVariable',
        expectedDisplayString: 'DateTime',
        expectedVariables: '''
            isUtc: false, eval: myVariable.isUtc
        ''',
      );
    });

    test('includes variable getters when evaluateGettersInDebugViews=true',
        () async {
      final client = dap.client;
      final testFile = dap.createTestFile('''
void main(List<String> args) {
  final myVariable = DateTime(2000, 1, 1);
  print('Hello!'); $breakpointMarker
}
    ''');
      final breakpointLine = lineWith(testFile, breakpointMarker);

      final stop = await client.hitBreakpoint(
        testFile,
        breakpointLine,
        launch: () => client.launch(
          testFile.path,
          evaluateGettersInDebugViews: true,
        ),
      );
      await client.expectLocalVariable(
        stop.threadId!,
        expectedName: 'myVariable',
        expectedDisplayString: 'DateTime',
        expectedVariables: '''
            day: 1, eval: myVariable.day
            hour: 0, eval: myVariable.hour
            isUtc: false, eval: myVariable.isUtc
            microsecond: 0, eval: myVariable.microsecond
            millisecond: 0, eval: myVariable.millisecond
            minute: 0, eval: myVariable.minute
            month: 1, eval: myVariable.month
            runtimeType: Type (DateTime), eval: myVariable.runtimeType
            second: 0, eval: myVariable.second
            timeZoneOffset: Duration, eval: myVariable.timeZoneOffset
            weekday: 6, eval: myVariable.weekday
            year: 2000, eval: myVariable.year
        ''',
        ignore: {
          // Don't check fields that may very based on timezone as it'll make
          // these tests fragile, and this isn't really what's being tested.
          'timeZoneName',
          'microsecondsSinceEpoch',
          'millisecondsSinceEpoch',
        },
      );
    });

    test('renders a simple list', () async {
      final client = dap.client;
      final testFile = dap.createTestFile('''
void main(List<String> args) {
  final myVariable = ["first", "second", "third"];
  print('Hello!'); $breakpointMarker
}
    ''');
      final breakpointLine = lineWith(testFile, breakpointMarker);

      final stop = await client.hitBreakpoint(testFile, breakpointLine);
      await client.expectLocalVariable(
        stop.threadId!,
        expectedName: 'myVariable',
        expectedDisplayString: 'List (3 items)',
        expectedIndexedItems: 3,
        expectedVariables: '''
            [0]: "first", eval: myVariable[0]
            [1]: "second", eval: myVariable[1]
            [2]: "third", eval: myVariable[2]
        ''',
      );
    });

    test('renders a simple list subset', () async {
      final client = dap.client;
      final testFile = dap.createTestFile('''
void main(List<String> args) {
  final myVariable = ["first", "second", "third"];
  print('Hello!'); $breakpointMarker
}
    ''');
      final breakpointLine = lineWith(testFile, breakpointMarker);

      final stop = await client.hitBreakpoint(testFile, breakpointLine);
      await client.expectLocalVariable(
        stop.threadId!,
        expectedName: 'myVariable',
        expectedDisplayString: 'List (3 items)',
        expectedIndexedItems: 3,
        expectedVariables: '''
            [1]: "second", eval: myVariable[1]
        ''',
        start: 1,
        count: 1,
      );
    });

    /// Helper to verify variables types of list.
    _checkList(
      String typeName, {
      required String constructor,
      required List<String> expectedDisplayStrings,
    }) {
      test('renders a $typeName', () async {
        final client = dap.client;
        final testFile = dap.createTestFile('''
import 'dart:typed_data';

void main(List<String> args) {
  final myVariable = $constructor;
  print('Hello!'); $breakpointMarker
}
    ''');
        final breakpointLine = lineWith(testFile, breakpointMarker);

        final stop = await client.hitBreakpoint(testFile, breakpointLine);
        await client.expectLocalVariable(
          stop.threadId!,
          expectedName: 'myVariable',
          expectedDisplayString: '$typeName (3 items)',
          expectedIndexedItems: 3,
          expectedVariables: '''
            [0]: ${expectedDisplayStrings[0]}
            [1]: ${expectedDisplayStrings[1]}
            [2]: ${expectedDisplayStrings[2]}
        ''',
        );
      });

      test('renders a $typeName subset', () async {
        final client = dap.client;
        final testFile = dap.createTestFile('''
import 'dart:typed_data';

void main(List<String> args) {
  final myVariable = $constructor;
  print('Hello!'); $breakpointMarker
}
    ''');
        final breakpointLine = lineWith(testFile, breakpointMarker);

        final stop = await client.hitBreakpoint(testFile, breakpointLine);
        await client.expectLocalVariable(
          stop.threadId!,
          expectedName: 'myVariable',
          expectedDisplayString: '$typeName (3 items)',
          expectedIndexedItems: 3,
          expectedVariables: '''
            [1]: ${expectedDisplayStrings[1]}
        ''',
          start: 1,
          count: 1,
        );
      });
    }

    _checkList(
      'Uint8ClampedList',
      constructor: 'Uint8ClampedList.fromList([1, 2, 3])',
      expectedDisplayStrings: ['1', '2', '3'],
    );
    _checkList(
      'Uint8List',
      constructor: 'Uint8List.fromList([1, 2, 3])',
      expectedDisplayStrings: ['1', '2', '3'],
    );
    _checkList(
      'Uint16List',
      constructor: 'Uint16List.fromList([1, 2, 3])',
      expectedDisplayStrings: ['1', '2', '3'],
    );
    _checkList(
      'Uint32List',
      constructor: 'Uint32List.fromList([1, 2, 3])',
      expectedDisplayStrings: ['1', '2', '3'],
    );
    _checkList(
      'Uint64List',
      constructor: 'Uint64List.fromList([1, 2, 3])',
      expectedDisplayStrings: ['1', '2', '3'],
    );
    _checkList(
      'Int8List',
      constructor: 'Int8List.fromList([1, 2, 3])',
      expectedDisplayStrings: ['1', '2', '3'],
    );
    _checkList(
      'Int16List',
      constructor: 'Int16List.fromList([1, 2, 3])',
      expectedDisplayStrings: ['1', '2', '3'],
    );
    _checkList(
      'Int32List',
      constructor: 'Int32List.fromList([1, 2, 3])',
      expectedDisplayStrings: ['1', '2', '3'],
    );
    _checkList(
      'Int64List',
      constructor: 'Int64List.fromList([1, 2, 3])',
      expectedDisplayStrings: ['1', '2', '3'],
    );
    _checkList(
      'Float32List',
      constructor: 'Float32List.fromList([1.1, 2.2, 3.3])',
      expectedDisplayStrings: [
        // Converting the numbers above to 32bit floats loses precisions and
        // we're just calling toString() on them.
        '1.100000023841858',
        '2.200000047683716',
        '3.299999952316284',
      ],
    );
    _checkList(
      'Float64List',
      constructor: 'Float64List.fromList([1.1, 2.2, 3.3])',
      expectedDisplayStrings: ['1.1', '2.2', '3.3'],
    );
    _checkList(
      'Int32x4List',
      constructor: 'Int32x4List.fromList(['
          'Int32x4(1, 1, 1, 1),'
          'Int32x4(2, 2, 2, 2),'
          'Int32x4(3, 3, 3, 3)'
          '])',
      expectedDisplayStrings: [
        // toString()s of Int32x4
        '[00000001, 00000001, 00000001, 00000001]',
        '[00000002, 00000002, 00000002, 00000002]',
        '[00000003, 00000003, 00000003, 00000003]',
      ],
    );
    _checkList(
      'Float32x4List',
      constructor: 'Float32x4List.fromList(['
          'Float32x4(1.1, 1.1, 1.1, 1.1),'
          'Float32x4(2.2, 2.2, 2.2, 2.2),'
          'Float32x4(3.3, 3.3, 3.3, 3.3)'
          '])',
      expectedDisplayStrings: [
        // toString()s of Float32x4
        '[1.100000, 1.100000, 1.100000, 1.100000]',
        '[2.200000, 2.200000, 2.200000, 2.200000]',
        '[3.300000, 3.300000, 3.300000, 3.300000]',
      ],
    );
    _checkList(
      'Float64x2List',
      constructor: 'Float64x2List.fromList(['
          'Float64x2(1.1,1.1),'
          'Float64x2(2.2,2.2),'
          'Float64x2(3.3,3.3)'
          '])',
      expectedDisplayStrings: [
        // toString()s of Float64x2
        '[1.100000, 1.100000]',
        '[2.200000, 2.200000]',
        '[3.300000, 3.300000]',
      ],
    );

    test('renders a simple map with keys/values', () async {
      final client = dap.client;
      final testFile = dap.createTestFile('''
void main(List<String> args) {
  final myVariable = {
    'zero': 0,
    'one': 1,
    'two': 2
  };
  print('Hello!'); $breakpointMarker
}
    ''');
      final breakpointLine = lineWith(testFile, breakpointMarker);

      final stop = await client.hitBreakpoint(testFile, breakpointLine);
      final variables = await client.expectLocalVariable(
        stop.threadId!,
        expectedName: 'myVariable',
        expectedDisplayString: 'Map (3 items)',
        // For maps, we render a level of MapAssociates first, which show
        // their index numbers. Expanding them has a Key and a Value "field"
        // which correspond to the items.
        expectedVariables: '''
            0: "zero" -> 0
            1: "one" -> 1
            2: "two" -> 2
        ''',
      );

      // Check one of the MapAssociation variables has the correct Key/Value
      // inside.
      expect(variables.variables, hasLength(3));
      final variableOne = variables.variables[1];
      expect(variableOne.variablesReference, isPositive);
      await client.expectVariables(
        variableOne.variablesReference,
        '''
            key: "one"
            value: 1, eval: myVariable["one"]
        ''',
      );
    });

    test('renders a simple map subset', () async {
      final client = dap.client;
      final testFile = dap.createTestFile('''
void main(List<String> args) {
  final myVariable = {
    'zero': 0,
    'one': 1,
    'two': 2
  };
  print('Hello!'); $breakpointMarker
}
    ''');
      final breakpointLine = lineWith(testFile, breakpointMarker);

      final stop = await client.hitBreakpoint(testFile, breakpointLine);
      await client.expectLocalVariable(
        stop.threadId!,
        expectedName: 'myVariable',
        expectedDisplayString: 'Map (3 items)',
        // For maps, we render a level of MapAssociates first, which show
        // their index numbers. Expanding them has a Key and a Value "field"
        // which correspond to the items.
        expectedVariables: '''
            1: "one" -> 1
        ''',
        start: 1,
        count: 1,
      );
    });

    test('renders a complex map with keys/values', () async {
      final client = dap.client;
      final testFile = dap.createTestFile('''
void main(List<String> args) {
  final myVariable = {
    DateTime(2000, 1, 1): Exception("my error")
  };
  print('Hello!'); $breakpointMarker
}
    ''');
      final breakpointLine = lineWith(testFile, breakpointMarker);

      final stop = await client.hitBreakpoint(testFile, breakpointLine);
      final mapVariables = await client.expectLocalVariable(
        stop.threadId!,
        expectedName: 'myVariable',
        expectedDisplayString: 'Map (1 item)',
        expectedVariables: '''
            0: DateTime -> _Exception
        ''',
      );

      // Check one of the MapAssociation variables has the correct Key/Value
      // inside.
      expect(mapVariables.variables, hasLength(1));
      final mapVariable = mapVariables.variables[0];
      expect(mapVariable.variablesReference, isPositive);
      final variables = await client.expectVariables(
        mapVariable.variablesReference,
        // We don't expect an evaluateName because the key is not a simple type.
        '''
            key: DateTime
            value: _Exception
        ''',
      );

      // Check the Key can be drilled into.
      expect(variables.variables, hasLength(2));
      final keyVariable = variables.variables[0];
      expect(keyVariable.variablesReference, isPositive);
      await client.expectVariables(
        keyVariable.variablesReference,
        '''
            isUtc: false
        ''',
      );

      // Check the Value can be drilled into.
      final valueVariable = variables.variables[1];
      expect(valueVariable.variablesReference, isPositive);
      await client.expectVariables(
        valueVariable.variablesReference,
        '''
            message: "my error"
        ''',
      );
    });

    test('calls toString() on custom classes', () async {
      final client = dap.client;
      final testFile = dap.createTestFile('''
class Foo {
  toString() => 'Bar!';
}

void main() {
  final myVariable = Foo();
  print('Hello!'); $breakpointMarker
}
    ''');
      final breakpointLine = lineWith(testFile, breakpointMarker);

      final stop = await client.hitBreakpoint(
        testFile,
        breakpointLine,
        launch: () => client.launch(
          testFile.path,
          evaluateToStringInDebugViews: true,
        ),
      );

      await client.expectScopeVariables(
        await client.getTopFrameId(stop.threadId!),
        'Locals',
        r'''
            myVariable: Foo (Bar!), eval: myVariable
        ''',
      );
    });

    test('does not use toString() result if "Instance of Foo"', () async {
      // When evaluateToStringInDebugViews=true, we should discard the result of
      // calling toString() when it's just 'Instance of Foo' because we're already
      // showing the type, and otherwise we show:
      //
      //     myVariable: Foo (Instance of Foo)
      final client = dap.client;
      final testFile = dap.createTestFile('''
class Foo {}

void main() {
  final myVariable = Foo();
  print('Hello!'); $breakpointMarker
}
    ''');
      final breakpointLine = lineWith(testFile, breakpointMarker);

      final stop = await client.hitBreakpoint(
        testFile,
        breakpointLine,
        launch: () => client.launch(
          testFile.path,
          evaluateToStringInDebugViews: true,
        ),
      );

      await client.expectScopeVariables(
        await client.getTopFrameId(stop.threadId!),
        'Locals',
        r'''
            myVariable: Foo, eval: myVariable
        ''',
      );
    });

    test('handles errors in getters', () async {
      final client = dap.client;
      final testFile = dap.createTestFile('''
class Foo {
  String get doesNotThrow => "success";
  String get throws => throw Exception('err');
}

void main() {
  final myVariable = Foo();
  print('Hello!'); $breakpointMarker
}
    ''');
      final breakpointLine = lineWith(testFile, breakpointMarker);

      final stop = await client.hitBreakpoint(
        testFile,
        breakpointLine,
        launch: () => client.launch(
          testFile.path,
          evaluateGettersInDebugViews: true,
        ),
      );

      await client.expectLocalVariable(
        stop.threadId!,
        expectedName: 'myVariable',
        expectedDisplayString: 'Foo',
        expectedVariables: '''
            doesNotThrow: "success", eval: myVariable.doesNotThrow
            throws: <Exception: err>
        ''',
        ignore: {'runtimeType'},
      );
    });
    // These tests can be slow due to starting up the external server process.
  }, timeout: Timeout.none);
}
