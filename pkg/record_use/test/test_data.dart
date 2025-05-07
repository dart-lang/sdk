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
          BoolConstant(false),
          StringConstant('mercury'),
          IntConstant(1),
          StringConstant('jenkins'),
          StringConstant('lib_SHA1'),
        ],
        namedArguments: {},
        loadingUnit: 'o.js',
        location: Location(uri: 'lib/test.dart'),
      ),
      const CallWithArguments(
        positionalArguments: [
          StringConstant('lib_SHA1'),
          IntConstant(0),
          MapConstant<IntConstant>({'key': IntConstant(99)}),
          StringConstant('jenkins'),
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
        namedArguments: {},
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
      "type": "bool",
      "value": false
    },
    {
      "type": "String",
      "value": "mercury"
    },
    {
      "type": "int",
      "value": 1
    },
    {
      "type": "String",
      "value": "jenkins"
    },
    {
      "type": "String",
      "value": "lib_SHA1"
    },
    {
      "type": "int",
      "value": 0
    },
    {
      "type": "int",
      "value": 99
    },
    {
      "type": "map",
      "value": {
        "key": 6
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
        9,
        10,
        0
      ]
    },
    {
      "type": "list",
      "value": [
        8,
        11,
        9
      ]
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
            2,
            3,
            4
          ],
          "loading_unit": "o.js",
          "@": 0
        },
        {
          "type": "with_arguments",
          "positional": [
            4,
            5,
            7,
            3,
            12
          ],
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
