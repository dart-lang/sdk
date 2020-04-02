// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/src/utilities/navigation/navigation.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveTests(NavigationCollectorImplTest);
}

@reflectiveTest
class NavigationCollectorImplTest {
  NavigationCollectorImpl collector = NavigationCollectorImpl();

  void test_createRegions_multiple() {
    // Two files, each with two targets.
    var fileA = 'a.dart';
    var targetOffsetA1 = 1;
    var targetLengthA1 = 2;
    var targetStartLineA1 = 3;
    var targetStartColumnA1 = 4;
    var targetKindA1 = ElementKind.CLASS;
    var targetLocationA1 = Location(fileA, targetOffsetA1, targetLengthA1,
        targetStartLineA1, targetStartColumnA1);
    var targetOffsetA2 = 5;
    var targetLengthA2 = 6;
    var targetStartLineA2 = 7;
    var targetStartColumnA2 = 8;
    var targetKindA2 = ElementKind.FUNCTION;
    var targetLocationA2 = Location(fileA, targetOffsetA2, targetLengthA2,
        targetStartLineA2, targetStartColumnA2);

    var fileB = 'b.dart';
    var targetOffsetB1 = 9;
    var targetLengthB1 = 10;
    var targetStartLineB1 = 11;
    var targetStartColumnB1 = 12;
    var targetKindB1 = ElementKind.ENUM;
    var targetLocationB1 = Location(fileB, targetOffsetB1, targetLengthB1,
        targetStartLineB1, targetStartColumnB1);
    var targetOffsetB2 = 13;
    var targetLengthB2 = 14;
    var targetStartLineB2 = 15;
    var targetStartColumnB2 = 16;
    var targetKindB2 = ElementKind.METHOD;
    var targetLocationB2 = Location(fileB, targetOffsetB2, targetLengthB2,
        targetStartLineB2, targetStartColumnB2);

    // Six regions targeting a1, b1, a2, b1, a1, b2
    var regionOffsets = <int>[17, 18, 19, 20, 21, 22];
    var regionLengths = <int>[23, 24, 25, 26, 27, 28];
    var targetKinds = <ElementKind>[
      targetKindA1,
      targetKindB1,
      targetKindA2,
      targetKindB1,
      targetKindA1,
      targetKindB2
    ];
    var targetLocations = <Location>[
      targetLocationA1,
      targetLocationB1,
      targetLocationA2,
      targetLocationB1,
      targetLocationA1,
      targetLocationB2
    ];
    for (var i = 0; i < 6; i++) {
      collector.addRegion(regionOffsets[i], regionLengths[i], targetKinds[i],
          targetLocations[i]);
    }

    collector.createRegions();
    expect(collector.files, [fileA, fileB]);
    expect(collector.regions, [
      NavigationRegion(regionOffsets[0], regionLengths[0], [0]),
      NavigationRegion(regionOffsets[1], regionLengths[1], [1]),
      NavigationRegion(regionOffsets[2], regionLengths[2], [2]),
      NavigationRegion(regionOffsets[3], regionLengths[3], [1]),
      NavigationRegion(regionOffsets[4], regionLengths[4], [0]),
      NavigationRegion(regionOffsets[5], regionLengths[5], [3]),
    ]);
    expect(collector.targets, [
      NavigationTarget(targetKindA1, 0, targetOffsetA1, targetLengthA1,
          targetStartLineA1, targetStartColumnA1),
      NavigationTarget(targetKindB1, 1, targetOffsetB1, targetLengthB1,
          targetStartLineB1, targetStartColumnB1),
      NavigationTarget(targetKindA2, 0, targetOffsetA2, targetLengthA2,
          targetStartLineA2, targetStartColumnA2),
      NavigationTarget(targetKindB2, 1, targetOffsetB2, targetLengthB2,
          targetStartLineB2, targetStartColumnB2),
    ]);
  }

  void test_createRegions_none() {
    collector.createRegions();
    expect(collector.files, isEmpty);
    expect(collector.regions, isEmpty);
    expect(collector.targets, isEmpty);
  }

  void test_createRegions_single() {
    var regionOffset = 13;
    var regionLength = 7;
    var targetKind = ElementKind.CLASS;
    var targetFile = 'c.dart';
    var targetOffset = 17;
    var targetLength = 1;
    var targetStartLine = 5;
    var targetStartColumn = 1;
    var targetLocation = Location(targetFile, targetOffset, targetLength,
        targetStartLine, targetStartColumn);
    collector.addRegion(regionOffset, regionLength, targetKind, targetLocation);
    collector.createRegions();
    expect(collector.files, [targetFile]);
    expect(collector.regions, [
      NavigationRegion(regionOffset, regionLength, [0])
    ]);
    expect(collector.targets, [
      NavigationTarget(targetKind, 0, targetOffset, targetLength,
          targetStartLine, targetStartColumn)
    ]);
  }
}
