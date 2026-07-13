// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dds/src/dap/isolate_manager.dart';
import 'package:dds/src/dap/protocol_converter.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart' as vm;

import 'mocks.dart';

void main() {
  late MockDartCliDebugAdapter adapter;
  late ProtocolConverter converter;
  late ThreadInfo thread;

  setUp(() async {
    adapter = MockDartCliDebugAdapter();
    converter = ProtocolConverter(adapter);
    thread = ThreadInfo(
      adapter.isolateManager,
      1,
      adapter.mockService.isolate1,
    );
  });

  group('Pointer display string', () {
    test('shows address from valueAsString', () async {
      final ref = vm.InstanceRef(
        id: 'ptr1',
        kind: 'Pointer',
        valueAsString: '0xdeadbeef',
      );

      final result = await converter.convertVmInstanceRefToDisplayString(
        thread,
        ref,
        allowCallingToString: false,
      );

      expect(result, 'Pointer (0xdeadbeef)');
    });

    test('shows unknown when valueAsString is null', () async {
      final ref = vm.InstanceRef(id: 'ptr1', kind: 'Pointer');

      final result = await converter.convertVmInstanceRefToDisplayString(
        thread,
        ref,
        allowCallingToString: false,
      );

      expect(result, 'Pointer (unknown)');
    });
  });

  group('Pointer variables list', () {
    test('returns single [raw bytes] child with address in value', () async {
      final instance = vm.Instance(
        id: 'ptr1',
        kind: 'Pointer',
        valueAsString: '0x1234',
      );

      final variables = await converter.convertVmInstanceToVariablesList(
        thread,
        instance,
        evaluateName: null,
        allowCallingToString: false,
      );

      expect(variables, hasLength(1));
      expect(variables[0].name, '[raw bytes]');
      expect(variables[0].value, '');
      expect(variables[0].presentationHint?.lazy, isTrue);
      expect(variables[0].variablesReference, isPositive);
    });
  });
}
