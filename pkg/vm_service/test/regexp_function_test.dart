// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=
// VMOptions=--interpret_irregexp

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'regexp_function_lib.dart' as testee_lib;

void main([args = const <String>[]]) => IsolateTestHarness(
      'regexp_function_lib.dart',
      args,
    ).addCustomTest((VmService service, IsolateRef isolateRef) async {
      final isolateId = isolateRef.id!;
      final isolate = await service.getIsolate(isolateId);
      final rootLib = await service.getObject(
        isolateId,
        isolate.libraries!
            .firstWhere((l) => l.uri!.contains('regexp_function_lib'))
            .id!,
      ) as Library;

      final variables = rootLib.variables!;

      final fieldRef = variables.singleWhere((v) => v.name == 'regex');
      final field = await service.getObject(
        isolateId,
        fieldRef.id!,
      ) as Field;

      final regexRef = field.staticValue as InstanceRef;
      expect(regexRef.kind, InstanceKind.kRegExp);

      final regex = await service.getObject(
        isolateId,
        regexRef.id!,
      ) as Instance;

      final regexJson = regex.json!;
      if (regexJson
          case {
            '_oneByteBytecode': {'kind': InstanceKind.kUint8List},
            // No two-byte string subject was used.
            '_twoByteBytecode': {'kind': InstanceKind.kNull},
          } when !regexJson.containsKey('_oneByteFunction')) {
        // Running with interpreted regexp.
      } else if (regexJson
          case {
            '_oneByteFunction': {'type': '@Function'},
            '_twoByteFunction': {'type': '@Function'},
          }) {
        // Running with compiled regexp.
      } else {
        fail('Unexpected JSON structure: ${regex.json!}');
      }
    }).run(testeeMain: testee_lib.main);
