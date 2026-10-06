// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dap/dap.dart';
import 'package:test/test.dart';

import 'test_client.dart';
import 'test_scripts.dart';
import 'test_support.dart';

const _compoundDeclarations = '''
import 'dart:ffi';
import 'package:ffi/ffi.dart';

final class MyUnion extends Union {
  @Uint32() external int intVal;
  @Float()  external double floatVal;
}
final class InnerStruct extends Struct {
  @Uint32() external int a;
  @Float()  external double b;
}
final class MyStruct extends Struct {
  @Uint64() external int x;
  @Bool()   external bool y;
  external InnerStruct inner;
  external MyUnion payload;
  @Array(3) external Array<InnerStruct> items;
  @Array(3) external Array<Uint8> tail;
  @Array(2, 2) external Array<Array<Uint8>> grid;
}

class Holder {
  final Pointer<MyStruct> ptr;
  Holder(this.ptr);
}
''';

const _fillBody = '''
  ptr.ref.x = 42;
  ptr.ref.y = true;
  ptr.ref.inner.a = 100;
  ptr.ref.inner.b = 3.5;
  ptr.ref.payload.intVal = 1024;
  ptr.ref.items[0].a = 10; ptr.ref.items[0].b = 1.5;
  ptr.ref.items[1].a = 20; ptr.ref.items[1].b = 2.5;
  ptr.ref.items[2].a = 30; ptr.ref.items[2].b = 3.5;
  ptr.ref.tail[0] = 0xA1; ptr.ref.tail[1] = 0xA2; ptr.ref.tail[2] = 0xA3;
  ptr.ref.grid[0][0] = 1; ptr.ref.grid[0][1] = 2;
  ptr.ref.grid[1][0] = 3; ptr.ref.grid[1][1] = 4;
''';

void main() {
  late DapTestSession dap;
  setUp(() async {
    dap = await DapTestSession.setUp();
  });
  tearDown(() => dap.tearDown());

  Future<({DapTestClient client, Variable ref})> stopAndGetRef(
    String mainBody, {
    String local = 'ptr',
  }) async {
    final client = dap.client;
    await dap.addPackageDependency(dap.testAppDir, 'ffi');
    final testFile = dap.createTestFile('''
$_compoundDeclarations
void main() {
$mainBody
  print(''); // $breakpointMarker
}
''');
    final line = lineWith(testFile, breakpointMarker);
    final stop = await client.hitBreakpoint(testFile, line);
    final ptrVar = await client.getLocalVariable(stop.threadId!, local);
    expect(ptrVar.variablesReference, isPositive);
    final ref = await client.getChildVariable(
      ptrVar.variablesReference,
      '.ref',
    );
    return (client: client, ref: ref);
  }

  group('dart:ffi compound Pointer variables', () {
    test(
      'local Pointer<Compound> resolves via staticType and shows .ref',
      () async {
        final client = dap.client;
        await dap.addPackageDependency(dap.testAppDir, 'ffi');
        final testFile = dap.createTestFile('''
$_compoundDeclarations
void main() {
  final ptr = calloc<MyStruct>();
$_fillBody
  print(''); // $breakpointMarker
  calloc.free(ptr);
}
''');
        final line = lineWith(testFile, breakpointMarker);
        final stop = await client.hitBreakpoint(testFile, line);

        final ptrVar = await client.getLocalVariable(stop.threadId!, 'ptr');
        expect(ptrVar.type, equals('Pointer<MyStruct>'));
        expect(ptrVar.variablesReference, isPositive);

        // Expanding the pointer yields exactly one child: `.ref`.
        final children = await client.getValidVariables(
          ptrVar.variablesReference,
        );
        expect(children.variables, hasLength(1));
        final ref = children.variables.single;
        expect(ref.name, equals('.ref'));
        expect(ref.type, equals('MyStruct'));
        expect(ref.variablesReference, isPositive);
      },
    );

    test(
      'field Pointer<Compound> resolves via declaredType and shows .ref',
      () async {
        final client = dap.client;
        await dap.addPackageDependency(dap.testAppDir, 'ffi');
        final testFile = dap.createTestFile('''
$_compoundDeclarations
void main() {
  final ptr = calloc<MyStruct>();
$_fillBody
  final holder = Holder(ptr);
  print(''); // $breakpointMarker
  calloc.free(ptr);
}
''');
        final line = lineWith(testFile, breakpointMarker);
        final stop = await client.hitBreakpoint(testFile, line);

        final holderVar = await client.getLocalVariable(
          stop.threadId!,
          'holder',
        );
        final ptrVar = await client.getChildVariable(
          holderVar.variablesReference,
          'ptr',
        );
        expect(ptrVar.type, equals('Pointer<MyStruct>'));
        final ref = await client.getChildVariable(
          ptrVar.variablesReference,
          '.ref',
        );
        expect(ref.name, equals('.ref'));
        expect(ref.type, equals('MyStruct'));
        expect(ref.variablesReference, isPositive);
      },
    );

    test('.ref decodes all top-level fields and appends [raw bytes]', () async {
      final (:client, :ref) = await stopAndGetRef('''
  final ptr = calloc<MyStruct>();
$_fillBody''');

      final fields = await client.getValidVariables(ref.variablesReference);
      final byName = {for (final v in fields.variables) v.name: v};

      expect(
        fields.variables.map((v) => v.name),
        equals([
          'x',
          'y',
          'inner',
          'payload',
          'items',
          'tail',
          'grid',
          '[raw bytes]',
        ]),
      );

      // Primitive: @Uint64 is reported by the VM layout as int64.
      expect(byName['x']!.value, equals('42'));
      expect(byName['x']!.type, equals('Int64'));

      // @Bool() is represented as uint8 in the native layout, so it decodes to
      // its byte value (1), not `true`.
      expect(byName['y']!.value, equals('1'));
      expect(byName['y']!.type, equals('Uint8'));

      // Labels are preserved (nested struct / union / arrays).
      expect(byName['inner']!.value, equals('InnerStruct'));
      expect(byName['inner']!.type, equals('InnerStruct'));

      expect(byName['payload']!.value, startsWith('MyUnion'));
      expect(byName['payload']!.value, contains('union'));
      expect(byName['payload']!.type, equals('MyUnion'));

      expect(byName['items']!.value, equals('Array<InnerStruct>[3]'));
      expect(byName['items']!.type, equals('Array<InnerStruct>'));
      expect(byName['items']!.indexedVariables, equals(3));

      expect(byName['tail']!.value, equals('Array<uint8>[3]'));
      expect(byName['tail']!.indexedVariables, equals(3));

      // Multi-dimensional @Array(2, 2) is flattened by the CFE to length 4.
      expect(byName['grid']!.value, equals('Array<uint8>[4]'));
      expect(byName['grid']!.indexedVariables, equals(4));

      // The whole-compound byte view is lazy (eye icon).
      expect(byName['[raw bytes]']!.value, equals(''));
      expect(byName['[raw bytes]']!.presentationHint?.lazy, isTrue);
      expect(byName['[raw bytes]']!.variablesReference, isPositive);
    });

    test('primitive field expands into its little-endian bytes', () async {
      final (:client, :ref) = await stopAndGetRef('''
  final ptr = calloc<MyStruct>();
$_fillBody''');

      // x = 42 (0x2a) as a Uint64 -> [0]=0x2a, rest 0x00 (little-endian).
      final xVar = await client.getChildVariable(ref.variablesReference, 'x');
      expect(xVar.indexedVariables, equals(8));
      await client.expectVariables(xVar.variablesReference, '''
        [0]: 0x2a
        [1]: 0x00
        [2]: 0x00
        [3]: 0x00
        [4]: 0x00
        [5]: 0x00
        [6]: 0x00
        [7]: 0x00
      ''');
    });

    test('nested struct field decodes from absolute offsets', () async {
      final (:client, :ref) = await stopAndGetRef('''
  final ptr = calloc<MyStruct>();
$_fillBody''');

      final inner = await client.getChildVariable(
        ref.variablesReference,
        'inner',
      );
      final a = await client.getChildVariable(inner.variablesReference, 'a');
      final b = await client.getChildVariable(inner.variablesReference, 'b');
      expect(a.value, equals('100'));
      expect(a.type, equals('Uint32'));
      expect(b.value, equals('3.5'));
      expect(b.type, equals('Float'));
    });

    test('nested union members overlap at the same offset', () async {
      final (:client, :ref) = await stopAndGetRef('''
  final ptr = calloc<MyStruct>();
$_fillBody''');

      final payload = await client.getChildVariable(
        ref.variablesReference,
        'payload',
      );
      final intVal = await client.getChildVariable(
        payload.variablesReference,
        'intVal',
      );
      final floatVal = await client.getChildVariable(
        payload.variablesReference,
        'floatVal',
      );
      expect(intVal.value, equals('1024'));
      expect(floatVal.value, equals('1.4349296274686127e-42'));

      final intBytes = await client.getValidVariables(
        intVal.variablesReference,
      );
      final floatBytes = await client.getValidVariables(
        floatVal.variablesReference,
      );
      expect(
        floatBytes.variables.map((v) => v.value),
        equals(intBytes.variables.map((v) => v.value)),
      );
    });

    test('array of primitives decodes each element (and its bytes)', () async {
      final (:client, :ref) = await stopAndGetRef('''
  final ptr = calloc<MyStruct>();
$_fillBody''');

      final tail = await client.getChildVariable(
        ref.variablesReference,
        'tail',
      );
      await client.expectVariables(tail.variablesReference, '''
        [0]: 161, 1 items, Uint8
        [1]: 162, 1 items, Uint8
        [2]: 163, 1 items, Uint8
      ''');

      final first = await client.getChildVariable(
        tail.variablesReference,
        '[0]',
      );
      await client.expectVariables(first.variablesReference, '''
        [0]: 0xa1
      ''');
    });

    test('array of structs applies the element stride', () async {
      final (:client, :ref) = await stopAndGetRef('''
  final ptr = calloc<MyStruct>();
$_fillBody''');

      final items = await client.getChildVariable(
        ref.variablesReference,
        'items',
      );
      final elements = await client.getValidVariables(items.variablesReference);
      expect(
        elements.variables.map((v) => v.name),
        equals(['[0]', '[1]', '[2]']),
      );
      for (final e in elements.variables) {
        expect(e.type, equals('InnerStruct'));
        expect(e.value, equals('InnerStruct'));
      }

      Future<void> expectElement(String name, int a, double b) async {
        final element = await client.getChildVariable(
          items.variablesReference,
          name,
        );
        final aVar = await client.getChildVariable(
          element.variablesReference,
          'a',
        );
        final bVar = await client.getChildVariable(
          element.variablesReference,
          'b',
        );
        expect(aVar.value, equals('$a'));
        expect(bVar.value, equals('$b'));
      }

      await expectElement('[0]', 10, 1.5);
      await expectElement('[1]', 20, 2.5);
      await expectElement('[2]', 30, 3.5);
    });

    test('multi-dimensional array is flattened and decoded', () async {
      final (:client, :ref) = await stopAndGetRef('''
  final ptr = calloc<MyStruct>();
$_fillBody''');

      final grid = await client.getChildVariable(
        ref.variablesReference,
        'grid',
      );
      await client.expectVariables(grid.variablesReference, '''
        [0]: 1, 1 items, Uint8
        [1]: 2, 1 items, Uint8
        [2]: 3, 1 items, Uint8
        [3]: 4, 1 items, Uint8
      ''');
    });

    test(
      '[raw bytes] is a lazy 3-state view (eye -> summary -> bytes)',
      () async {
        final (:client, :ref) = await stopAndGetRef('''
  final ptr = calloc<MyStruct>();
$_fillBody''');

        // State A: the lazy placeholder.
        final placeholder = await client.getChildVariable(
          ref.variablesReference,
          '[raw bytes]',
        );
        expect(placeholder.value, equals(''));
        expect(placeholder.presentationHint?.lazy, isTrue);

        // State B: resolving the placeholder returns exactly one summary var.
        final resolved = await client.getValidVariables(
          placeholder.variablesReference,
        );
        expect(resolved.variables, hasLength(1));
        final summary = resolved.variables.single;
        expect(summary.name, equals('[raw bytes]'));
        expect(summary.value, startsWith('56 bytes @ 0x'));
        expect(summary.indexedVariables, equals(56));
        expect(summary.variablesReference, isPositive);

        // State C: the summary expands into the compound's bytes.
        final bytes = await client.getValidVariables(
          summary.variablesReference,
        );
        expect(bytes.variables, hasLength(56));
        expect(bytes.variables[0].value, equals('0x2a'));
        expect(bytes.variables[8].value, equals('0x01'));
        expect(bytes.variables[12].value, equals('0x64'));
      },
    );

    test('[raw bytes] honors pagination (start/count)', () async {
      final client = dap.client;
      await dap.addPackageDependency(dap.testAppDir, 'ffi');
      final testFile = dap.createTestFile('''
import 'dart:ffi';
import 'package:ffi/ffi.dart';

final class Big extends Struct {
  @Array(300) external Array<Uint8> data;
}

void main() {
  final ptr = calloc<Big>();
  for (var i = 0; i < 300; i++) {
    ptr.ref.data[i] = i & 0xFF;
  }
  print(''); // $breakpointMarker
  calloc.free(ptr);
}
''');
      final line = lineWith(testFile, breakpointMarker);
      final stop = await client.hitBreakpoint(testFile, line);

      final ptrVar = await client.getLocalVariable(stop.threadId!, 'ptr');
      final ref = await client.getChildVariable(
        ptrVar.variablesReference,
        '.ref',
      );
      final placeholder = await client.getChildVariable(
        ref.variablesReference,
        '[raw bytes]',
      );
      final summary = (await client.getValidVariables(
        placeholder.variablesReference,
      )).variables.single;
      expect(summary.indexedVariables, equals(300));

      // Request a middle page [100, 110).
      final page = await client.getValidVariables(
        summary.variablesReference,
        start: 100,
        count: 10,
      );
      expect(page.variables, hasLength(10));
      expect(page.variables.first.name, equals('[100]'));
      expect(page.variables.first.value, equals('0x64')); // 100 == 0x64
      expect(page.variables.last.name, equals('[109]'));
      expect(page.variables.last.value, equals('0x6d')); // 109 == 0x6d
    });

    test('array honors pagination (start/count)', () async {
      final client = dap.client;
      await dap.addPackageDependency(dap.testAppDir, 'ffi');
      final testFile = dap.createTestFile('''
import 'dart:ffi';
import 'package:ffi/ffi.dart';

final class Big extends Struct {
  @Array(300) external Array<Uint8> data;
}

void main() {
  final ptr = calloc<Big>();
  for (var i = 0; i < 300; i++) {
    ptr.ref.data[i] = i & 0xFF;
  }
  print(''); // $breakpointMarker
  calloc.free(ptr);
}
''');
      final line = lineWith(testFile, breakpointMarker);
      final stop = await client.hitBreakpoint(testFile, line);

      final ptrVar = await client.getLocalVariable(stop.threadId!, 'ptr');
      final ref = await client.getChildVariable(
        ptrVar.variablesReference,
        '.ref',
      );
      final data = await client.getChildVariable(
        ref.variablesReference,
        'data',
      );
      expect(data.indexedVariables, equals(300));

      final page = await client.getValidVariables(
        data.variablesReference,
        start: 100,
        count: 10,
      );
      expect(page.variables, hasLength(10));
      expect(page.variables.first.name, equals('[100]'));
      expect(page.variables.first.value, equals('100'));
      expect(page.variables.last.name, equals('[109]'));
      expect(page.variables.last.value, equals('109'));
    });

    test(
      'user compound named like a primitive is decoded, not mistaken',
      () async {
        final client = dap.client;
        await dap.addPackageDependency(dap.testAppDir, 'ffi');
        final testFile = dap.createTestFile('''
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';

final class Int8 extends ffi.Struct {
  @ffi.Uint32() external int marker;
}

void main() {
  final ptr = calloc<Int8>();
  ptr.ref.marker = 777;
  print(''); // $breakpointMarker
  calloc.free(ptr);
}
''');
        final line = lineWith(testFile, breakpointMarker);
        final stop = await client.hitBreakpoint(testFile, line);

        final ptrVar = await client.getLocalVariable(stop.threadId!, 'ptr');
        expect(ptrVar.type, equals('Pointer<Int8>'));
        final ref = await client.getChildVariable(
          ptrVar.variablesReference,
          '.ref',
        );
        expect(ref.type, equals('Int8'));
        final marker = await client.getChildVariable(
          ref.variablesReference,
          'marker',
        );
        expect(marker.value, equals('777'));
        expect(marker.type, equals('Uint32'));
      },
    );

    test('null Pointer<Compound> expands to nothing', () async {
      final client = dap.client;
      await dap.addPackageDependency(dap.testAppDir, 'ffi');
      final testFile = dap.createTestFile('''
$_compoundDeclarations
void main() {
  final Pointer<MyStruct> ptr = nullptr;
  print(''); // $breakpointMarker
}
''');
      final line = lineWith(testFile, breakpointMarker);
      final stop = await client.hitBreakpoint(testFile, line);

      final ptrVar = await client.getLocalVariable(stop.threadId!, 'ptr');
      final children = await client.getValidVariables(
        ptrVar.variablesReference,
      );
      expect(children.variables, isEmpty);
    });

    test(
      'unreadable memory renders an error node instead of crashing',
      () async {
        final client = dap.client;
        await dap.addPackageDependency(dap.testAppDir, 'ffi');
        final testFile = dap.createTestFile('''
$_compoundDeclarations
void main() {
  final ptr = Pointer<MyStruct>.fromAddress(0xdeadbeef);
  print(''); // $breakpointMarker
}
''');
        final line = lineWith(testFile, breakpointMarker);
        final stop = await client.hitBreakpoint(testFile, line);

        final ptrVar = await client.getLocalVariable(stop.threadId!, 'ptr');
        final ref = await client.getChildVariable(
          ptrVar.variablesReference,
          '.ref',
        );
        final children = await client.getValidVariables(ref.variablesReference);
        expect(children.variables, hasLength(1));
        expect(children.variables.single.name, equals('<unreadable memory>'));
      },
    );

    test(
      'primitive Pointer field rendering is unchanged (no regression)',
      () async {
        final client = dap.client;
        await dap.addPackageDependency(dap.testAppDir, 'ffi');
        final testFile = dap.createTestFile('''
import 'dart:ffi';
import 'package:ffi/ffi.dart';
class C {
  final Pointer<Int32> myPointer;
  C(this.myPointer);
}
void main() {
  final ptr = calloc<Int32>();
  ptr.value = -100;
  final c = C(ptr);
  print(''); // $breakpointMarker
  calloc.free(ptr);
}
''');
        final line = lineWith(testFile, breakpointMarker);
        final stop = await client.hitBreakpoint(testFile, line);

        final cVar = await client.getLocalVariable(stop.threadId!, 'c');
        final ptrVar = await client.getChildVariable(
          cVar.variablesReference,
          'myPointer',
        );
        expect(ptrVar.type, equals('Pointer<Int32>'));

        final children = await client.getValidVariables(
          ptrVar.variablesReference,
        );
        expect(children.variables, hasLength(2));
        expect(children.variables.first.name, equals('value'));
        expect(children.variables.first.value, equals('-100'));
        expect(children.variables.last.name, equals('[raw bytes]'));
        expect(children.variables.last.presentationHint?.lazy, isTrue);
      },
    );
  }, timeout: Timeout.none);
}
