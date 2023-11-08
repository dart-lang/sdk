// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=
// VMOptions=--interpret_irregexp

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

import 'common/expect.dart';
import 'common/test_helper.dart';

// Make sure these variables are not removed by the tree shaker.
@pragma('vm:entry-point')
late RegExp regex0;
@pragma('vm:entry-point')
late RegExp regex;

void script() {
  // Check the internal NUL doesn't trip up the name scrubbing in the vm.
  regex0 = RegExp('with internal \u{0} NUL');
  regex = RegExp(r'(\w+)');
  final str = 'Parse my string';
  final matches = regex.allMatches(str); // Run to generate bytecode.
  Expect.equals(matches.length, 3);
}

final tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final rootLib = await service.getObject(
      isolateId,
      isolate.rootLib!.id!,
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
          '_externalOneByteFunction': {'type': '@Function'},
          '_externalTwoByteFunction': {'type': '@Function'},
        }) {
      // Running with compiled regexp.
    } else {
      fail('Unexpected JSON structure: ${regex.json!}');
    }
  }
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'regexp_function_test.dart',
      testeeBefore: script,
    );
