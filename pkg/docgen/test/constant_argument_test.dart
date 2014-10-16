// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library docgen.test.typedef;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:scheduled_test/descriptor.dart' as d;
import 'package:scheduled_test/scheduled_test.dart';

import 'util.dart';
import '../lib/docgen.dart' as dg;

void main() {

  setUp(() {
    scheduleTempDir();
  });

  test('argument default values', () {
    schedule(() {
      var codeDir = getMultiLibraryCodePath();
      expect(FileSystemEntity.isDirectorySync(codeDir), isTrue);
      return dg.docgen([codeDir], out: p.join(d.defaultRoot, 'docs'));
    });

    schedule(() {
      var path = p.join(d.defaultRoot, 'docs', 'test_lib.json');
      var dartCoreJson = new File(path).readAsStringSync();

      var testLibBar = JSON.decode(dartCoreJson) as Map<String, dynamic>;

      //
      // Validate function doc references
      //
      var functionDef =
          testLibBar['functions']['methods']['positionalDefaultValues']
          as Map<String, dynamic>;

      var params = functionDef['parameters'] as Map<String, dynamic>;

      expect(params.keys, orderedEquals(_PARAM_NAME_ORDER),
          reason: 'parameter order  must be maintained');

      var vals = {};
      params.forEach((paramName, paramHash) {
        expect(_PARAM_VALUES, contains(paramName));
        expect(paramHash['value'], _PARAM_VALUES[paramName],
            reason: 'Value for $paramName should match expected');
      });
    });
  });
}

final _PARAM_VALUES = {
  "intConst": "42",
  "boolConst": "true",
  "listConst": 'const [true, 42, "Shanna", null, 3.14, const []]',
  "stringConst": "\"Shanna\"",
  "mapConst": 'const {"a": 1, 2: true, "c": const [1, null, true]}',
  "emptyMap": 'const {}',
  "referencedConst": "INT_CONST",
  "constructedConstant1": "const ConstClass<int>(0, true)",
  "constructedConstant2": 'const ConstClass(1, false, str: "str")'
};

const _PARAM_NAME_ORDER = const [
  "intConst",
  "boolConst",
  "listConst",
  "stringConst",
  "mapConst",
  "emptyMap",
  "referencedConst",
  "constructedConstant1",
  "constructedConstant2"
];
