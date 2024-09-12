// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:record_use/record_use_internal.dart';
import 'package:test/test.dart';

import 'test_data.dart';

void main() {
  test('All API calls', () {
    expect(
      RecordedUsages.fromJson(
              jsonDecode(recordedUsesJson) as Map<String, dynamic>)
          .argumentsTo(callId),
      recordedUses.calls.expand((e) => e.references).map((e) => e.arguments),
    );
  });

  test('All API instances', () {
    final references =
        recordedUses.instances.expand((instance) => instance.references);
    final instances = RecordedUsages.fromJson(
            jsonDecode(recordedUsesJson) as Map<String, dynamic>)
        .instancesOf(instanceId);
    expect(instances, references);
  });

  test('Specific API calls', () {
    final callId = Identifier(
      uri: Uri.parse('file://lib/_internal/js_runtime/lib/js_helper.dart')
          .toString(),
      parent: 'MyClass',
      name: 'get:loadDeferredLibrary',
    );
    final arguments = RecordedUsages.fromJson(
            jsonDecode(recordedUsesJson) as Map<String, dynamic>)
        .argumentsTo(callId)!
        .toList();
    expect(
      arguments[0].constArguments.named,
      const {
        'leroy': StringConstant('jenkins'),
        'freddy': StringConstant('mercury'),
      },
    );
    expect(
      arguments[0].constArguments.positional,
      const {
        0: StringConstant('lib_SHA1'),
        1: BoolConstant(false),
        2: IntConstant(1)
      },
    );
    expect(arguments[1].constArguments.named, const {
      'leroy': StringConstant('jenkins'),
      'albert': ListConstant([
        StringConstant('camus'),
        ListConstant([
          StringConstant('einstein'),
          StringConstant('insert'),
          BoolConstant(false),
        ]),
        StringConstant('einstein'),
      ]),
    });
    expect(arguments[1].constArguments.positional, const {
      0: StringConstant('lib_SHA1'),
      2: IntConstant(0),
      4: MapConstant({'key': IntConstant(99)})
    });
  });

  test('Specific API instances', () {
    final instanceId = Identifier(
      uri: Uri.parse('file://lib/_internal/js_runtime/lib/js_helper.dart')
          .toString(),
      name: 'MyAnnotation',
    );
    expect(
      RecordedUsages.fromJson(
              jsonDecode(recordedUsesJson) as Map<String, dynamic>)
          .instancesOf(instanceId)
          ?.first,
      InstanceReference(
        instanceConstant: const InstanceConstant(
          fields: {'a': IntConstant(42), 'b': NullConstant()},
        ),
        location: Location(uri: instanceId.uri, line: 40, column: 30),
        loadingUnit: 3.toString(),
      ),
    );
  });

  test('HasNonConstInstance', () {
    final id = const Identifier(
      uri: 'package:drop_dylib_recording/src/drop_dylib_recording.dart',
      name: 'getMathMethod',
    );

    expect(
        RecordedUsages.fromJson(
                jsonDecode(recordedUsesJson2) as Map<String, dynamic>)
            .hasNonConstArguments(id),
        false);
  });
}
