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
/*1*/import 'dart:async';

// We can have comments
import 'package:a/b.dart';
import 'package:b/c.dart';

import '../a.dart';/*1:DIRECTIVES*/

main() {}
""";

    final regions = await _computeRegions(content);
    _compareRegions(regions, content);
  }

  /// Compares provided folding regions with expected
  /// regions extracted from the comments in the provided content.
  void _compareRegions(List<FoldingRegion> regions, String content) {
    // Find all numeric markers for region starts.
    final regex = new RegExp(r'/\*(\d+)\*/');
    final expectedRegions = regex.allMatches(content);

    // Check we didn't get more than expected, since the loop below only
    // checks for the presence of matches, not absence.
    expect(regions, hasLength(expectedRegions.length));

    // Go through each marker, find the expected region start/end and
    // ensure it's in the results.
    expectedRegions.forEach((m) {
      final i = m.group(1);
      // Find the end marker.
      final endMatch = new RegExp('/\\*$i:(.+?)\\*/').firstMatch(content);

      final expectedStart = m.end;
      final expectedLength = endMatch.start - expectedStart;
      final expectedKindString = endMatch.group(1);
      final expectedKind = FoldingKind.VALUES
          .firstWhere((f) => f.toString() == 'FoldingKind.$expectedKindString');

      expect(
          regions,
          contains(
              new FoldingRegion(expectedKind, expectedStart, expectedLength)));
    });
  }

  Future<List<FoldingRegion>> _computeRegions(String sourceContent) async {
    newFile(sourcePath, content: sourceContent);
    ResolveResult result = await driver.getResult(sourcePath);
    DartUnitFoldingComputer computer = new DartUnitFoldingComputer(result.unit);
    return computer.compute();
  }
}
