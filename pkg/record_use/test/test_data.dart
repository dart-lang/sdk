// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:pub_semver/pub_semver.dart';
import 'package:record_use/record_use_internal.dart';

final callId = Identifier(
  importUri: Uri.parse('file://lib/_internal/js_runtime/lib/js_helper.dart')
      .toString(),
  parent: 'MyClass',
  name: 'get:loadDeferredLibrary',
);
final instanceId = Identifier(
  importUri: Uri.parse('file://lib/_internal/js_runtime/lib/js_helper.dart')
      .toString(),
  name: 'MyAnnotation',
);

final recordedUses = UsageRecord(
  metadata: Metadata(
    version: Version(1, 6, 2, pre: 'wip', build: '5.-.2.z'),
    comment:
        'Recorded references at compile time and their argument values, as far'
        ' as known, to definitions annotated with @RecordUse',
  ),
  instances: [
    Usage(
      definition: Definition(
        identifier: instanceId,
        location: Location(
          uri: Uri.parse('file://lib/_internal/js_runtime/lib/js_helper.dart')
              .toString(),
          line: 15,
          column: 30,
        ),
      ),
      references: [
        InstanceReference(
          instanceConstant: const InstanceConstant(
            fields: {
              'a': IntConstant(42),
              'b': NullConstant(),
            },
          ),
          location: Location(
            uri: Uri.parse('file://lib/_internal/js_runtime/lib/js_helper.dart')
                .toString(),
            line: 40,
            column: 30,
          ),
          loadingUnit: '3',
        ),
      ],
    ),
  ],
  calls: [
    Usage(
      definition: Definition(
        identifier: callId,
        location: Location(
          uri: Uri.parse('file://lib/_internal/js_runtime/lib/js_helper.dart')
              .toString(),
          line: 12,
          column: 67,
        ),
        loadingUnit: 'part_15.js',
      ),
      references: [
        CallReference(
          arguments: const Arguments(
            constArguments: ConstArguments(
              positional: {
                0: StringConstant('lib_SHA1'),
                1: BoolConstant(false),
                2: IntConstant(1)
              },
              named: {
                'leroy': StringConstant('jenkins'),
                'freddy': StringConstant('mercury')
              },
            ),
          ),
          location: Location(
            uri: Uri.parse(
                    'file://benchmarks/OmnibusDeferred/dart/OmnibusDeferred.dart')
                .toString(),
            line: 14,
            column: 49,
          ),
          loadingUnit: 'o.js',
        ),
        CallReference(
          arguments: const Arguments(
            constArguments: ConstArguments(
              positional: {
                0: StringConstant('lib_SHA1'),
                2: IntConstant(0),
                4: MapConstant<IntConstant>({'key': IntConstant(99)}),
              },
              named: {
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
              },
            ),
            nonConstArguments: NonConstArguments(
              positional: [1],
              named: ['freddy'],
            ),
          ),
          location: Location(
            uri: Uri.parse(
                    'file://benchmarks/OmnibusDeferred/dart/OmnibusDeferred.dart')
                .toString(),
            line: 14,
            column: 48,
          ),
          loadingUnit: 'o.js',
        ),
      ],
    ),
  ],
);

final recordedUsesJson = '''{
  "metadata": {
    "comment":
        "Recorded references at compile time and their argument values, as far as known, to definitions annotated with @RecordUse",
    "version": "1.6.2-wip+5.-.2.z"
  },
  "uris": [
    "file://lib/_internal/js_runtime/lib/js_helper.dart",
    "file://benchmarks/OmnibusDeferred/dart/OmnibusDeferred.dart"
  ],
  "ids": [
    {"uri": 0, "parent": "MyClass", "name": "get:loadDeferredLibrary"},
    {"uri": 0, "name": "MyAnnotation"}
  ],
  "constants": [
    {"type": "String", "value": "jenkins"},
    {"type": "String", "value": "mercury"},
    {"type": "String", "value": "lib_SHA1"},
    {"type": "bool", "value": false},
    {"type": "int", "value": 1},
    {"type": "String", "value": "camus"},
    {"type": "String", "value": "einstein"},
    {"type": "String", "value": "insert"},
    {
      "type": "list",
      "value": [6, 7, 3]
    },
    {
      "type": "list",
      "value": [5, 8, 6]
    },
    {"type": "int", "value": 0},
    {"type": "int", "value": 99},
    {
      "type": "map",
      "value": {"key": 11}
    },
    {"type": "int", "value": 42},
    {"type": "Null"},
    {"type": "Instance", "value": {"a": 13, "b": 14}}
  ],
  "calls": [
    {
      "definition": {
        "id": 0,
        "@": {"uri": 0, "line": 12, "column": 67},
        "loadingUnit": "part_15.js"
      },
      "references": [
        {
          "arguments": {
            "const": {
              "positional": {"0": 2, "1": 3, "2": 4},
              "named": {"leroy": 0, "freddy": 1}
            }
          },
          "loadingUnit": "o.js",
          "@": {"uri": 1, "line": 14, "column": 49}
        },
        {
          "arguments": {
            "const": {
              "positional": {"0": 2, "2": 10, "4": 12},
              "named": {"leroy": 0, "albert": 9}
            },
            "nonConst": {
              "positional": [1],
              "named": ["freddy"]
            }
          },
          "loadingUnit": "o.js",
          "@": {"uri": 1, "line": 14, "column": 48}
        }
      ]
    }
  ],
  "instances": [
    {
      "definition": {
        "id": 1,
        "@": {"uri": 0, "line": 15, "column": 30},
        "loadingUnit": null
      },
      "references": [
        {
          "instanceConstant": 15,
          "loadingUnit": "3",
          "@": {"uri": 0, "line": 40, "column": 30}
        }
      ]
    }
  ]
}''';

final recordedUsesJson2 = '''{
  "metadata": {
    "comment": "Recorded usages of objects tagged with a `RecordUse` annotation",
    "version": "0.1.0"
  },
  "uris": [
    "package:drop_dylib_recording/src/drop_dylib_recording.dart",
    "drop_dylib_recording_calls.dart"
  ],
  "ids": [
    {
      "uri": 0,
      "name": "getMathMethod"
    }
  ],
  "constants": [
    {
      "type": "String",
      "value": "add"
    }
  ],
  "calls": [
    {
      "definition": {
        "id": 0,
        "@": {
          "uri": 0, 
          "line": 10,
          "column": 6
        },
        "loadingUnit": "1"
      },
      "references": [
        {
          "arguments": {
            "const": {
              "positional": {
                "0": 0
              }
            }
          },
          "loadingUnit": "1",
          "@": {
            "uri": 1,
            "line": 8,
            "column": 3
          }
        }
      ]
    }
  ]
}''';
