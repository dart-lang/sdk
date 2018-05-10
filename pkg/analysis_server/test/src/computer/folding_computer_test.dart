// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/computer/computer_folding.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_context.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FoldingComputerTest);
  });
}

@reflectiveTest
class FoldingComputerTest extends AbstractContextTest {
  String sourcePath;

  setUp() {
    super.setUp();
    sourcePath = resourceProvider.convertPath('/p/lib/source.dart');
  }

  test_single_import_directives() async {
    String content = """
import 'dart:async';

main() {}
""";

    // Since there are no region comment markers above
    final regions = await _computeRegions(content);
    expect(regions, hasLength(0));
  }

  test_multiple_import_directives() async {
    String content = """
import/*1:INC*/ 'dart:async';

// We can have comments
import 'package:a/b.dart';
import 'package:b/c.dart';

import '../a.dart';/*1:EXC:DIRECTIVES*/

main() {}
""";

    final regions = await _computeRegions(content);
    _compareRegions(regions, content);
  }

  test_multiple_directive_types() async {
    String content = """
import/*1:INC*/ 'dart:async';

// We can have comments
import 'package:a/b.dart';
import 'package:b/c.dart';

export '../a.dart';/*1:EXC:DIRECTIVES*/

main() {}
""";

    final regions = await _computeRegions(content);
    _compareRegions(regions, content);
  }

  test_function() async {
    String content = """
// Content before

main() {/*1:INC*/
  print("Hello, world!");
/*1:INC:TOP_LEVEL_DECLARATION*/}

// Content after
""";

    final regions = await _computeRegions(content);
    _compareRegions(regions, content);
  }

  test_function_with_dart_doc() async {
    String content = """
// Content before

/*1:EXC*//// This is a doc comment
/// that spans lines/*1:INC:DOCUMENTATION_COMMENT*/
main() {/*2:INC*/
  print("Hello, world!");
/*2:INC:TOP_LEVEL_DECLARATION*/}

// Content after
""";

    final regions = await _computeRegions(content);
    _compareRegions(regions, content);
  }

  test_nested_function() async {
    String content = """
// Content before

main() {/*1:INC*/
  doPrint() {/*2:INC*/
    print("Hello, world!");
  /*2:INC:TOP_LEVEL_DECLARATION*/}
  doPrint();
/*1:INC:TOP_LEVEL_DECLARATION*/}

// Content after
""";

    final regions = await _computeRegions(content);
    _compareRegions(regions, content);
  }

  test_class() async {
    String content = """
// Content before

class Person {/*1:INC*/
  Person() {/*2:INC*/
    print("Hello, world!");
  /*2:INC:CLASS_MEMBER*/}

  void sayHello() {/*3:INC*/
    print("Hello, world!");
  /*3:INC:CLASS_MEMBER*/}
/*1:INC:TOP_LEVEL_DECLARATION*/}

// Content after
""";

    final regions = await _computeRegions(content);
    _compareRegions(regions, content);
  }

  /// Compares provided folding regions with expected
  /// regions extracted from the comments in the provided content.
  void _compareRegions(List<FoldingRegion> regions, String content) {
    // Find all numeric markers for region starts.
    final regex = new RegExp(r'/\*(\d+):(INC|EXC)\*/');
    final expectedRegions = regex.allMatches(content);

    // Check we didn't get more than expected, since the loop below only
    // checks for the presence of matches, not absence.
    expect(regions, hasLength(expectedRegions.length));

    // Go through each marker, find the expected region start/end and
    // ensure it's in the results.
    expectedRegions.forEach((m) {
      final i = m.group(1);
      final inclusiveStart = m.group(2) == "INC";
      // Find the end marker.
      final endMatch =
          new RegExp('/\\*$i:(INC|EXC):(.+?)\\*/').firstMatch(content);

      final inclusiveEnd = endMatch.group(1) == "INC";
      final expectedKindString = endMatch.group(2);
      final expectedKind = FoldingKind.VALUES.firstWhere(
          (f) => f.toString() == 'FoldingKind.$expectedKindString',
          orElse: () => throw new Exception(
              "Annotated test code references $expectedKindString but "
              "this does not exist in FoldingKind"));

      final expectedStart = inclusiveStart ? m.start : m.end;
      final expectedLength =
          (inclusiveEnd ? endMatch.end : endMatch.start) - expectedStart;

      expect(
          regions,
          contains(
              new FoldingRegion(expectedKind, expectedStart, expectedLength)));
    });
  }

  Future<List<FoldingRegion>> _computeRegions(String sourceContent) async {
    newFile(sourcePath, content: sourceContent);
    ResolveResult result = await driver.getResult(sourcePath);
    DartUnitFoldingComputer computer =
        new DartUnitFoldingComputer(result.lineInfo, result.unit);
    return computer.compute();
  }
}
