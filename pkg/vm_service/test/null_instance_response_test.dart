// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

const _nullInstanceRef = <String, Object?>{
  'type': '@Instance',
  'id': 'objects/null',
  'kind': InstanceKind.kNull,
  'valueAsString': 'null',
};

const _malformedInstanceRef = <String, Object?>{
  'type': '@Instance',
  'id': 'objects/null',
  'kind': InstanceKind.kNull,
  'valueAsString': 0,
};

void main() {
  late StreamController<String> fromVm;
  late VmService service;
  late Map<String, Object?> responseResult;

  setUp(() {
    fromVm = StreamController<String>();
    responseResult = _nullInstanceRef;
    // Respond to every request with `responseResult` (defaults to a `null`
    // instance).
    service = VmService(fromVm.stream, (String message) {
      final request = jsonDecode(message) as Map<String, Object?>;
      fromVm.add(
        jsonEncode(<String, Object?>{
          'jsonrpc': '2.0',
          'id': request['id'],
          'result': responseResult,
        }),
      );
    });
  });

  tearDown(() async {
    await service.dispose();
    await fromVm.close();
  });

  final isNullInstanceRef = isA<InstanceRef>()
      .having((r) => r.kind, 'kind', InstanceKind.kNull)
      .having((r) => r.json, 'json', _nullInstanceRef);

  test('callMethod completes with a null InstanceRef for unknown RPCs',
      () async {
    expect(
      await service.callMethod(
        '_evaluateCompiledExpression',
        args: <String, Object?>{'isolateId': 'isolates/1'},
      ),
      isNullInstanceRef,
    );
  });

  test('callServiceExtension completes with a null InstanceRef', () async {
    expect(
      await service.callServiceExtension('ext.test.returnsNull'),
      isNullInstanceRef,
    );
  });

  test('evaluate (known return types) completes with a null InstanceRef',
      () async {
    expect(
      await service.evaluate('isolates/1', 'libraries/1', 'null'),
      isNullInstanceRef,
    );
  });

  test(
      'typed RPC not expecting InstanceRef completes with an error on null '
      'InstanceRef instead of hanging', () async {
    await expectLater(service.getVM(), throwsA(isA<TypeError>()));
  });

  test(
      'request completes with an error when createServiceObject throws instead '
      'of hanging', () async {
    responseResult = _malformedInstanceRef;
    await expectLater(
      service.evaluate('isolates/1', 'libraries/1', 'null'),
      throwsA(isA<TypeError>()),
    );
  });
}
