// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:pub_semver/pub_semver.dart';
import 'package:record_use/record_use_internal.dart';

final callId = Identifier(
  importUri:
      Uri.parse(
        'file://lib/_internal/js_runtime/lib/js_helper.dart',
      ).toString(),
  scope: 'MyClass',
  name: 'get:loadDeferredLibrary',
);
final instanceId = Identifier(
  importUri:
      Uri.parse(
        'file://lib/_internal/js_runtime/lib/js_helper.dart',
      ).toString(),
  name: 'MyAnnotation',
);

final recordedUses = Recordings(
  metadata: Metadata.fromJson({
    'version': Version(1, 6, 2, pre: 'wip', build: '5.-.2.z').toString(),
    'comment':
        'Recorded references at compile time and their argument values, as'
        ' far as known, to definitions annotated with @RecordUse',
  }),
  callsForDefinition: {
    Definition(identifier: callId, loadingUnit: 'part_15.js'): [
      const CallWithArguments(
        positionalArguments: [
          StringConstant('lib_SHA1'),
          BoolConstant(false),
          IntConstant(1),
        ],
        namedArguments: {
          'freddy': StringConstant('mercury'),
          'leroy': StringConstant('jenkins'),
        },
        loadingUnit: 'o.js',
        location: Location(uri: 'lib/test.dart'),
      ),
      const CallWithArguments(
        positionalArguments: [
          StringConstant('lib_SHA1'),
          MapConstant<IntConstant>({'key': IntConstant(99)}),
          ListConstant([
            StringConstant('camus'),
            ListConstant([
              StringConstant('einstein'),
              StringConstant('insert'),
              BoolConstant(false),
            ]),
            StringConstant('einstein'),
          ]),
        ],
        namedArguments: {
          'freddy': IntConstant(0),
          'leroy': StringConstant('jenkins'),
        },
        loadingUnit: 'o.js',
        location: Location(uri: 'lib/test2.dart'),
      ),
    ],
  },
  instancesForDefinition: {
    Definition(identifier: instanceId): [
      const InstanceReference(
        instanceConstant: InstanceConstant(
          fields: {'a': IntConstant(42), 'b': NullConstant()},
        ),
        loadingUnit: '3',
        location: Location(uri: 'lib/test3.dart'),
      ),
      const InstanceReference(
        instanceConstant: InstanceConstant(fields: {}),
        loadingUnit: '3',
        location: Location(uri: 'lib/test3.dart'),
      ),
    ],
  },
);

final recordedUses2 = Recordings(
  metadata: Metadata.fromJson({
    'version': Version(1, 6, 2, pre: 'wip', build: '5.-.2.z').toString(),
    'comment':
        'Recorded references at compile time and their argument values, as'
        ' far as known, to definitions annotated with @RecordUse',
  }),
  callsForDefinition: {
    Definition(identifier: callId, loadingUnit: 'part_15.js'): [
      const CallWithArguments(
        positionalArguments: [BoolConstant(false), IntConstant(1)],
        namedArguments: {
          'freddy': StringConstant('mercury'),
          'answer': IntConstant(42),
        },
        loadingUnit: 'o.js',
        location: Location(uri: 'lib/test3.dart'),
      ),
    ],
  },
  instancesForDefinition: {},
);

final recordedUsesJson = '''{
  "metadata": {
    "version": "1.6.2-wip+5.-.2.z",
    "comment": "Recorded references at compile time and their argument values, as far as known, to definitions annotated with @RecordUse"
  },
  "constants": [
    {
      "type": "String",
      "value": "lib_SHA1"
    },
    {
      "type": "bool",
      "value": false
    },
    {
      "type": "int",
      "value": 1
    },
    {
      "type": "String",
      "value": "mercury"
    },
    {
      "type": "String",
      "value": "jenkins"
    },
    {
      "type": "int",
      "value": 99
    },
    {
      "type": "map",
      "value": {
        "key": 5
      }
    },
    {
      "type": "String",
      "value": "camus"
    },
    {
      "type": "String",
      "value": "einstein"
    },
    {
      "type": "String",
      "value": "insert"
    },
    {
      "type": "list",
      "value": [
        8,
        9,
        1
      ]
    },
    {
      "type": "list",
      "value": [
        7,
        10,
        8
      ]
    },
    {
      "type": "int",
      "value": 0
    },
    {
      "type": "int",
      "value": 42
    },
    {
      "type": "Null"
    },
    {
      "type": "Instance",
      "value": {
        "a": 13,
        "b": 14
      }
    },
    {
      "type": "Instance"
    }
  ],
  "locations": [
    {
      "uri": "lib/test.dart"
    },
    {
      "uri": "lib/test2.dart"
    },
    {
      "uri": "lib/test3.dart"
    }
  ],
  "recordings": [
    {
      "definition": {
        "identifier": {
          "uri": "file://lib/_internal/js_runtime/lib/js_helper.dart",
          "scope": "MyClass",
          "name": "get:loadDeferredLibrary"
        },
        "loading_unit": "part_15.js"
      },
      "calls": [
        {
          "type": "with_arguments",
          "positional": [
            0,
            1,
            2
          ],
          "named": {
            "freddy": 3,
            "leroy": 4
          },
          "loading_unit": "o.js",
          "@": 0
        },
        {
          "type": "with_arguments",
          "positional": [
            0,
            6,
            11
          ],
          "named": {
            "freddy": 12,
            "leroy": 4
          },
          "loading_unit": "o.js",
          "@": 1
        }
      ]
    },
    {
      "definition": {
        "identifier": {
          "uri": "file://lib/_internal/js_runtime/lib/js_helper.dart",
          "name": "MyAnnotation"
        }
      },
      "instances": [
        {
          "constant_index": 15,
          "loading_unit": "3",
          "@": 2
        },
        {
          "constant_index": 16,
          "loading_unit": "3",
          "@": 2
        }
      ]
    }
  ]
}''';

final recordedUsesJson2 = '''{
  "metadata": {
    "version": "1.6.2-wip+5.-.2.z",
    "comment": "Recorded references at compile time and their argument values, as far as known, to definitions annotated with @RecordUse"
  },
  "constants": [
    {
      "type": "bool",
      "value": false
    },
    {
      "type": "int",
      "value": 1
    },
    {
      "type": "String",
      "value": "mercury"
    },
    {
      "type": "int",
      "value": 42
    }
  ],
  "locations": [
    {
      "uri": "lib/test3.dart"
    }
  ],
  "recordings": [
    {
      "definition": {
        "identifier": {
          "uri": "file://lib/_internal/js_runtime/lib/js_helper.dart",
          "scope": "MyClass",
          "name": "get:loadDeferredLibrary"
        },
        "loading_unit": "part_15.js"
      },
      "calls": [
        {
          "type": "with_arguments",
          "positional": [
            0,
            1
          ],
          "named": {
            "freddy": 2,
            "answer": 3
          },
          "loading_unit": "o.js",
          "@": 0
        }
      ]
    }
  ]
}''';
