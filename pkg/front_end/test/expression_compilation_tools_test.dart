// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/legacy/minitest.dart'; // ignore: deprecated_member_use

import 'package:front_end/src/api_prototype/expression_compilation_tools.dart';

void main() {
  // null value.
  expectHelper(
    [
      ["null"],
    ],
    [new ParsedType.nullType()],
  );

  // String
  expectHelper(
    [
      [
        // String, kNonNullable, 0 arguments.
        "dart:core", "_OneByteString", "1", "0",
      ],
    ],
    [new ParsedType.interface("dart:core", "_OneByteString", 1)],
  );

  // List<something it can't represent which thus becomes an explicit
  // dynamic/null>, kNonNullable.
  expectHelper(
    [
      [
        // List, kNonNullable, 1 argument
        "dart:core", "List", "1", "1",
        // we don't know what.
        "null",
      ],
    ],
    [
      new ParsedType.interface("dart:core", "List", 1)
        ..arguments!.add(new ParsedType.nullType()),
    ],
  );

  // List<int>
  expectHelper(
    [
      [
        // List, kNonNullable, 1 argument
        "dart:core", "_GrowableList", "1", "1",
        // int, kNonNullable, 0 arguments
        "dart:core", "int", "1", "0",
      ],
    ],
    [
      new ParsedType.interface("dart:core", "_GrowableList", 1)
        ..arguments!.add(new ParsedType.interface("dart:core", "int", 1)),
    ],
  );

  // Map<int, int>
  expectHelper(
    [
      [
        // Map, kNonNullable, 2 arguments
        "dart:core", "Map", "1", "2",
        // int, kNonNullable, 0 arguments
        "dart:core", "int", "1", "0",
        // int, kNonNullable, 0 arguments
        "dart:core", "int", "1", "0",
      ],
    ],
    [
      new ParsedType.interface("dart:core", "Map", 1)
        ..arguments!.add(new ParsedType.interface("dart:core", "int", 1))
        ..arguments!.add(new ParsedType.interface("dart:core", "int", 1)),
    ],
  );

  // [0] = String
  // [1] = List<String>
  // [2] = int
  expectHelper(
    [
      [
        // String, kNonNullable, no arguments
        "dart:core", "_OneByteString", "1", "0",
      ],
      [
        // List, kNonNullable, 1 argument
        "dart:core", "_GrowableList", "1", "1",
        //  -> String, kNonNullable (i.e. the above is List<String>)
        /**/ "dart:core", "String", "1", "0",
      ],
      [
        // Int, kNonNullable, no arguments
        "dart:core", "_Smi", "1", "0",
      ],
    ],
    <ParsedType>[
      // String
      new ParsedType.interface("dart:core", "_OneByteString", 1),
      // List<String>
      new ParsedType.interface("dart:core", "_GrowableList", 1)
        ..arguments!.addAll([
          new ParsedType.interface("dart:core", "String", 1),
        ]),
      // int
      new ParsedType.interface("dart:core", "_Smi", 1),
    ],
  );

  // [0] = String
  // [1] = int
  // [2] = List<String>
  // [3] = Bar
  // [4] = null
  // [5] = HashMap<Map<int, List<int>>, List<String>>
  expectHelper(
    [
      [
        // String, kNonNullable, no arguments
        "dart:core", "_OneByteString", "1", "0",
      ],
      [
        // Int, kNonNullable, no arguments
        "dart:core", "_Smi", "1", "0",
      ],
      [
        // List, kNonNullable, 1 argument
        "dart:core", "_GrowableList", "1", "1",
        //  -> String, kNonNullable (i.e. the above is List<String>)
        /**/ "dart:core", "String", "1", "0",
      ],
      [
        // "Bar", kNonNullable, no arguments
        "file://wherever/t.dart", "Bar", "1", "0",
      ],
      [
        // null value
        "null",
      ],
      [
        // HashMap, kNonNullable, 2 arguments
        "dart:collection", "_InternalLinkedHashMap", "1", "2",
        //   -> Map, kNonNullable, 2 arguments
        /**/ "dart:core", "Map", "1", "2",
        //   -> -> int, kNonNullable, no arguments
        /*/**/*/ "dart:core", "int", "1", "0",
        //   -> -> List, kNonNullable, 1 argument
        /*/**/*/ "dart:core", "List", "1", "1",
        //   -> -> -> int, kNonNullable, no arguments
        /*/*/**/*/*/ "dart:core", "int", "1", "0",
        //   -> List, kNonNullable, 1 argument
        "dart:core", "List", "1", "1",
        //   -> -> String, kNonNullable, no arguments
        "dart:core", "String", "1", "0",
      ],
    ],
    <ParsedType>[
      // String
      new ParsedType.interface("dart:core", "_OneByteString", 1),
      // int
      new ParsedType.interface("dart:core", "_Smi", 1),
      // List<String>
      new ParsedType.interface("dart:core", "_GrowableList", 1)
        ..arguments!.addAll([
          new ParsedType.interface("dart:core", "String", 1),
        ]),
      // Bar
      new ParsedType.interface("file://wherever/t.dart", "Bar", 1),
      // null value
      new ParsedType.nullType(),
      // HashMap<Map<int, List<int>>, List<String>>
      new ParsedType.interface("dart:collection", "_InternalLinkedHashMap", 1)
        ..arguments!.addAll([
          new ParsedType.interface("dart:core", "Map", 1)
            ..arguments!.addAll([
              new ParsedType.interface("dart:core", "int", 1),
              new ParsedType.interface("dart:core", "List", 1)
                ..arguments!.addAll([
                  new ParsedType.interface("dart:core", "int", 1),
                ]),
            ]),
          new ParsedType.interface("dart:core", "List", 1)
            ..arguments!.addAll([
              new ParsedType.interface("dart:core", "String", 1),
            ]),
        ]),
    ],
  );

  // Set<(int, {int foo})>, kNonNullable
  expectHelper(
    [
      [
        //
        /**/ "dart:_compact_hash", "_Set", "1", "1",
        /*  */ "record", "1", "2", "1", "foo",
        /*    */ "dart:core", "int", "1", "0",
        /*    */ "dart:core", "int", "1", "0",
      ],
    ],
    [
      new ParsedType.interface("dart:_compact_hash", "_Set", 1)
        ..arguments!.add(
          new ParsedType.record(1, [null, "foo"])
            ..arguments!.add(new ParsedType.interface("dart:core", "int", 1))
            ..arguments!.add(new ParsedType.interface("dart:core", "int", 1)),
        ),
    ],
  );
}

/// Test that the input parses correctly. Also try to add "viaScope" on each
/// type and verify that it parses correctly too.
void expectHelper(
  List<List<String>> definitionTypesGrouped,
  List<ParsedType> expectedTypes,
) {
  if (definitionTypesGrouped.length != expectedTypes.length) {
    throw "Bad test";
  }
  List<String> definitionTypes = [];
  for (List<String> definitionType in definitionTypesGrouped) {
    definitionTypes.addAll(definitionType);
  }
  expect(parseDefinitionTypes(definitionTypes), expectedTypes);

  for (int i = 0; i < definitionTypesGrouped.length; i++) {
    definitionTypes = [];
    for (int j = 0; j < definitionTypesGrouped.length; j++) {
      List<String> definitionType = definitionTypesGrouped[j];
      if (i == j) definitionTypes.add("viaScope");
      definitionTypes.addAll(definitionType);
    }
    expectedTypes[i].wasAddedViaCustomScope = true;
    expect(parseDefinitionTypes(definitionTypes), expectedTypes);
    expectedTypes[i].wasAddedViaCustomScope = false;
  }
}
