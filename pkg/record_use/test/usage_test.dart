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
        jsonDecode(recordedUsesJson) as Map<String, Object?>,
      ).constArgumentsFor(
        Identifier(
          importUri:
              Uri.parse(
                'file://lib/_internal/js_runtime/lib/js_helper.dart',
              ).toString(),
          scope: 'MyClass',
          name: 'get:loadDeferredLibrary',
        ),
        '''
void loadDeferredLibrary(String s, bool b, int i, {required String singer, String? character})''',
      ).length,
      2,
    );
  });

  test('All API instances', () {
    final instance =
        RecordedUsages.fromJson(
              jsonDecode(recordedUsesJson) as Map<String, Object?>,
            )
            .constantsOf(
              Identifier(
                importUri:
                    Uri.parse(
                      'file://lib/_internal/js_runtime/lib/js_helper.dart',
                    ).toString(),
                name: 'MyAnnotation',
              ),
            )
            .first;
    final instanceMap =
        recordedUses.instancesForDefinition.values
            .expand((usage) => usage)
            .map(
              (instance) => instance.instanceConstant.fields.map(
                (key, constant) => MapEntry(key, constant.toValue()),
              ),
            )
            .first;
    for (final entry in instanceMap.entries) {
      expect(instance[entry.key], entry.value);
    }
  });

  test('Specific API calls', () {
    var arguments =
        RecordedUsages.fromJson(
          jsonDecode(recordedUsesJson) as Map<String, Object?>,
        ).constArgumentsFor(
          Identifier(
            importUri:
                Uri.parse(
                  'file://lib/_internal/js_runtime/lib/js_helper.dart',
                ).toString(),
            scope: 'MyClass',
            name: 'get:loadDeferredLibrary',
          ),
          '''
void loadDeferredLibrary(String s, bool b, int i, {required String freddy, String? leroy})''',
        ).toList();
    var (named: named0, positional: positional0) = arguments[0];
    expect(named0, const {'freddy': 'mercury', 'leroy': 'jenkins'});
    expect(positional0, const ['lib_SHA1', false, 1]);
    var (named: named1, positional: positional1) = arguments[1];
    expect(named1, const {'freddy': 0, 'leroy': 'jenkins'});
    expect(positional1, const [
      [
        'camus',
        ['einstein', 'insert', false],
        'einstein',
      ],
      'lib_SHA1',
      {'key': 99},
    ]);
  });

  test('Specific API instances', () {
    final instance =
        RecordedUsages.fromJson(
              jsonDecode(recordedUsesJson) as Map<String, Object?>,
            )
            .constantsOf(
              Identifier(
                importUri:
                    Uri.parse(
                      'file://lib/_internal/js_runtime/lib/js_helper.dart',
                    ).toString(),
                name: 'MyAnnotation',
              ),
            )
            .first;
    expect(instance['a'], 42);
    expect(instance['b'], null);
  });

  test('HasNonConstInstance', () {
    expect(
      RecordedUsages.fromJson(
        jsonDecode(recordedUsesJson2) as Map<String, Object?>,
      ).hasNonConstArguments(
        const Identifier(
          importUri:
              'package:drop_dylib_recording/src/drop_dylib_recording.dart',
          name: 'getMathMethod',
        ),
      ),
      false,
    );
  });
}
