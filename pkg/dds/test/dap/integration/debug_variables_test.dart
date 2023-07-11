// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dap/dap.dart';
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
    test('provides local variable list for frames', () async {
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

    test('provides global variable list for frames', () async {
      final client = dap.client;
      final testFile = dap.createTestFile('''
final globalInt = 1;
final globalString = 'TEST';
final globalMyClass = MyClass();

void main(List<String> args) {
  globalMyClass;
  print(''); $breakpointMarker
}

class MyClass {}
    ''');
      final breakpointLine = lineWith(testFile, breakpointMarker);

      final stop = await client.hitBreakpoint(testFile, breakpointLine);
      final topFrameId = await client.getTopFrameId(stop.threadId!);

      await client.expectScopeVariables(
        topFrameId,
        'Globals',
        '''
            globalInt: 1, eval: globalInt
            globalMyClass: MyClass, eval: globalMyClass
            globalString: "TEST", eval: globalString
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

    test('includes eager public getters when evaluateGettersInDebugViews=true',
        () async {
      final client = dap.client;
      final testFile = dap.createTestFile('''
void main(List<String> args) {
  final myVariable = A();
  print('Hello!'); $breakpointMarker
}
class A {
  String get publicString => '111';
  String get _privateString => '222';
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
        expectedDisplayString: 'A',
        expectedVariables: '''
            publicString: "111", eval: myVariable.publicString
            runtimeType: Type (A), eval: myVariable.runtimeType
        ''',
        ignorePrivate: false,
      );
    });

    test('includes lazy public getters when showGettersInDebugViews=true',
        () async {
      final client = dap.client;
      final testFile = dap.createTestFile('''
void main(List<String> args) {
  final myVariable = A();
  print('Hello!'); $breakpointMarker
}
class A {
  String get publicString => '111';
  String get _privateString => '222';
}
    ''');
      final breakpointLine = lineWith(testFile, breakpointMarker);

      final stop = await client.hitBreakpoint(
        testFile,
        breakpointLine,
        launch: () => client.launch(
          testFile.path,
          showGettersInDebugViews: true,
        ),
      );

      // Check the first level of variables are flagged as lazy with no values.
      final variables = await client.expectLocalVariable(
        stop.threadId!,
        expectedName: 'myVariable',
        expectedDisplayString: 'A',
        expectedVariables: '''
            publicString: , lazy: true
            runtimeType: , lazy: true
        ''',
        ignorePrivate: false,
      );

      // "Expand" publicString to ensure it resolve correctly to a single-field
      // variable with no name and the correct value/eval information.
      final namedRecordVariable = variables.variables
          .singleWhere((variable) => variable.name == 'publicString');
      expect(namedRecordVariable.variablesReference, isPositive);
      await client.expectVariables(
        namedRecordVariable.variablesReference,
        r'''
            : "111", eval: myVariable.publicString
        ''',
      );
    });

    test('includes record fields', () async {
      final client = dap.client;
      final testFile = dap.createTestFile('''
void main(List<String> args) {
  final (String?, int, {String? namedString, (int, int) namedRecord}) myRecord
      = (namedString: '', namedRecord: (10, 11), '', 2);
  print('Hello!'); $breakpointMarker
}
    ''');
      final breakpointLine = lineWith(testFile, breakpointMarker);

      final stop = await client.hitBreakpoint(
        testFile,
        breakpointLine,
        // TODO(dantup): Remove toolArgs when this is no longer required.
        toolArgs: ['--enable-experiment=records'],
      );

      // Check the fields directly on the record.
      final variables = await client.expectLocalVariable(
        stop.threadId!,
        expectedName: 'myRecord',
        expectedDisplayString: 'Record',
        expectedVariables: r'''
            $1: "", eval: myRecord.$1
            $2: 2, eval: myRecord.$2
            namedRecord: Record, eval: myRecord.namedRecord
            namedString: "", eval: myRecord.namedString
        ''',
      );

      // Check the fields nested inside `namedRecord`.
      final namedRecordVariable = variables.variables
          .singleWhere((variable) => variable.name == 'namedRecord');
      expect(namedRecordVariable.variablesReference, isPositive);
      await client.expectVariables(
        namedRecordVariable.variablesReference,
        r'''
            $1: 10, eval: myRecord.namedRecord.$1
            $2: 11, eval: myRecord.namedRecord.$2
        ''',
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
    checkList(
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
            [0]: ${expectedDisplayStrings[0]}, eval: myVariable[0]
            [1]: ${expectedDisplayStrings[1]}, eval: myVariable[1]
            [2]: ${expectedDisplayStrings[2]}, eval: myVariable[2]
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
            [1]: ${expectedDisplayStrings[1]}, eval: myVariable[1]
        ''',
          start: 1,
          count: 1,
        );
      });
    }

    checkList(
      'Uint8ClampedList',
      constructor: 'Uint8ClampedList.fromList([1, 2, 3])',
      expectedDisplayStrings: ['1', '2', '3'],
    );
    checkList(
      'Uint8List',
      constructor: 'Uint8List.fromList([1, 2, 3])',
      expectedDisplayStrings: ['1', '2', '3'],
    );
    checkList(
      'Uint16List',
      constructor: 'Uint16List.fromList([1, 2, 3])',
      expectedDisplayStrings: ['1', '2', '3'],
    );
    checkList(
      'Uint32List',
      constructor: 'Uint32List.fromList([1, 2, 3])',
      expectedDisplayStrings: ['1', '2', '3'],
    );
    checkList(
      'Uint64List',
      constructor: 'Uint64List.fromList([1, 2, 3])',
      expectedDisplayStrings: ['1', '2', '3'],
    );
    checkList(
      'Int8List',
      constructor: 'Int8List.fromList([1, 2, 3])',
      expectedDisplayStrings: ['1', '2', '3'],
    );
    checkList(
      'Int16List',
      constructor: 'Int16List.fromList([1, 2, 3])',
      expectedDisplayStrings: ['1', '2', '3'],
    );
    checkList(
      'Int32List',
      constructor: 'Int32List.fromList([1, 2, 3])',
      expectedDisplayStrings: ['1', '2', '3'],
    );
    checkList(
      'Int64List',
      constructor: 'Int64List.fromList([1, 2, 3])',
      expectedDisplayStrings: ['1', '2', '3'],
    );
    checkList(
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
    checkList(
      'Float64List',
      constructor: 'Float64List.fromList([1.1, 2.2, 3.3])',
      expectedDisplayStrings: ['1.1', '2.2', '3.3'],
    );
    checkList(
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
    checkList(
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
    checkList(
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

    test('handles errors in toString() on custom classes', () async {
      final client = dap.client;
      final testFile = dap.createTestFile('''
class Foo {
  toString() => throw UnimplementedError('NYI!');
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
            myVariable: Foo (UnimplementedError: NYI!), eval: myVariable
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

    test('handles sentinel fields', () async {
      final client = dap.client;
      final testFile = dap.createTestFile('''
class Foo {
  late String foo;
}

void main() {
  final myVariable = Foo();
  print('Hello!'); $breakpointMarker
}
    ''');

      final breakpointLine = lineWith(testFile, breakpointMarker);
      final stop = await client.hitBreakpoint(testFile, breakpointLine);

      await client.expectLocalVariable(
        stop.threadId!,
        expectedName: 'myVariable',
        expectedDisplayString: 'Foo',
        expectedVariables: 'foo: <not initialized>',
      );
    });

    test('handles sentinel locals', () async {
      final client = dap.client;
      final testFile = dap.createTestFile('''
void main() {
  late String foo;
  print('Hello!'); $breakpointMarker
}
    ''');
      final breakpointLine = lineWith(testFile, breakpointMarker);
      final stop = await client.hitBreakpoint(testFile, breakpointLine);

      await client.expectScopeVariables(
        await client.getTopFrameId(stop.threadId!),
        'Locals',
        'foo: <not initialized>',
      );
    });

    group('inspect()', () {
      /// Helper to test `inspect()` with varying expressions.
      void checkInspect(
        String inspectCode, {
        required String expectedVariables,
      }) {
        test('sends variable in OutputEvent for inspect($inspectCode)',
            () async {
          final client = dap.client;
          final testFile = dap.createTestFile('''
import 'dart:developer';

void main() {
  inspect($inspectCode);
  print('Done!'); $breakpointMarker
}
    ''');

          // Capture an `OutputEvent` that has a variable reference which should
          // be sent by the `inspect()` call.
          final outputEventFuture = client.outputEvents.firstWhere(
              (e) => e.variablesReference != null && e.variablesReference! > 0);
          final breakpointLine = lineWith(testFile, breakpointMarker);
          await client.hitBreakpoint(testFile, breakpointLine);
          final outputEvent = await outputEventFuture;

          final inspectWrapper =
              await client.getValidVariables(outputEvent.variablesReference!);
          // The wrapper should only have one field for expanding.
          final variable = inspectWrapper.variables.single;
          expect(variable.value, '<inspected variable>');

          // Check the child variables are as expected.
          await client.expectVariables(
            variable.variablesReference,
            expectedVariables,
          );
        });
      }

      checkInspect(
        '"My String"',
        expectedVariables: 'String: "My String"',
      );

      checkInspect(
        'null',
        expectedVariables: 'Null: null',
      );

      checkInspect(
        '[0, 1, 2]',
        expectedVariables: '''
          [0]: 0
          [1]: 1
          [2]: 2
        ''',
      );
    });

    group('value formats', () {
      test('can trigger invalidation from the DAP client', () async {
        final client = dap.client;
        final testFile = dap.createTestFile(simpleBreakpointProgram);
        final breakpointLine = lineWith(testFile, breakpointMarker);
        await client.hitBreakpoint(testFile, breakpointLine);

        // Expect the server to emit an "invalidated" event after we call
        // our custom '_invalidateAreas' request.
        final invalidatedEventFuture = client.event('invalidated');
        await client.sendRequest({
          'areas': ['a', 'b'],
        }, overrideCommand: '_invalidateAreas');

        final invalidatedEvent = await invalidatedEventFuture;
        final body = InvalidatedEventBody.fromJson(
          invalidatedEvent.body as Map<String, Object?>,
        );
        expect(body.areas, ['a', 'b']);
      });

      test('supports format.hex in variables arguments', () async {
        final client = dap.client;
        final testFile = dap.createTestFile('''
  void main(List<String> args) {
    var i = 12345;
    print('Hello!'); $breakpointMarker
  }''');
        final breakpointLine = lineWith(testFile, breakpointMarker);

        final stop = await client.hitBreakpoint(testFile, breakpointLine);
        final topFrameId = await client.getTopFrameId(stop.threadId!);
        await client.expectScopeVariables(
          topFrameId,
          'Locals',
          '''
            i: 0x3039, eval: i
        ''',
          ignore: {'args'},
          format: ValueFormat(hex: true),
        );
      });
    });

    group('evaluateNames are correctly stored for nested variables', () {
      /// A helper that checks evaluate names are available on nested objects
      /// to ensure they are being stored correctly across variableRequests.
      ///
      /// [code] is the Dart code that should be included in the program.
      /// [variablesPath] is a path to walk down from the Local Variables to get
      /// to the 'myField' field on an instance of 'A'.
      ///
      /// This test ensures the evaluateName on that variable matches
      /// [expectedEvaluateName].
      void checkEvaluateNames(
        String testType, {
        required String code,
        String? definitions,
        required List<String> variablesPath,
        required String expectedEvaluateName,
      }) {
        test('in $testType', () async {
          final client = dap.client;
          final testFile = dap.createTestFile('''
class A {
  final String myField = '';
}
${definitions ?? ''}
void main() {
  $code
  print('Done!'); $breakpointMarker
}
    ''');

          // Hit the breakpoint ready to evaluate.
          final breakpointLine = lineWith(testFile, breakpointMarker);
          final stop = await client.hitBreakpoint(
            testFile,
            breakpointLine,
            launch: () => client.launch(
              testFile.path,
              evaluateGettersInDebugViews: true,
            ),
          );

          // Walk down the variables path to locate our `A().myField`.
          var variable = await client.getLocalVariable(
            stop.threadId!,
            variablesPath.removeAt(0),
          );
          while (variablesPath.isNotEmpty) {
            variable = await client.getChildVariable(
              variable.variablesReference,
              variablesPath.removeAt(0),
            );
          }

          expect(variable.evaluateName, expectedEvaluateName);
        });
      }

      checkEvaluateNames(
        'lists',
        variablesPath: ['list', '[0]', 'myField'],
        expectedEvaluateName: 'list[0].myField',
        code: '''
          final list = [A()];
        ''',
      );

      checkEvaluateNames(
        'maps',
        // To support expanding complex keys, maps are rendered numerically with
        // key/value pairs grouped by index, so rather than map->key here, we
        // have to look in the first group, then the value.
        variablesPath: ['map', '0', 'value', 'myField'],
        // But the evaluate name should be the normal Dart code for this.
        expectedEvaluateName: 'map["key"].myField',
        code: '''
          final map = {'key': A()};
        ''',
      );

      checkEvaluateNames(
        'fields',
        variablesPath: ['a', 'b', 'myField'],
        expectedEvaluateName: 'a.b.myField',
        code: '''
          final a = MyClass();
        ''',
        definitions: '''
          class MyClass {
            final b = A();
          }
        ''',
      );

      checkEvaluateNames(
        'getters',
        variablesPath: ['a', 'b', 'myField'],
        expectedEvaluateName: 'a.b.myField',
        code: '''
          final a = MyClass();
        ''',
        definitions: '''
          class MyClass {
            A get b => A();
          }
        ''',
      );
    });
    // These tests can be slow due to starting up the external server process.
  }, timeout: Timeout.none);
}
