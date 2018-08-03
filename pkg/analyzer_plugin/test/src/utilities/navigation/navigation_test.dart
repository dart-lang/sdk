// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
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
  NavigationCollectorImpl collector = new NavigationCollectorImpl();

  test_createRegions_multiple() {
    // Two files, each with two targets.
    String fileA = 'a.dart';
    int targetOffsetA1 = 1;
    int targetLengthA1 = 2;
    int targetStartLineA1 = 3;
    int targetStartColumnA1 = 4;
    ElementKind targetKindA1 = ElementKind.CLASS;
    Location targetLocationA1 = new Location(fileA, targetOffsetA1,
        targetLengthA1, targetStartLineA1, targetStartColumnA1);
    int targetOffsetA2 = 5;
    int targetLengthA2 = 6;
    int targetStartLineA2 = 7;
    int targetStartColumnA2 = 8;
    ElementKind targetKindA2 = ElementKind.FUNCTION;
    Location targetLocationA2 = new Location(fileA, targetOffsetA2,
        targetLengthA2, targetStartLineA2, targetStartColumnA2);

    String fileB = 'b.dart';
    int targetOffsetB1 = 9;
    int targetLengthB1 = 10;
    int targetStartLineB1 = 11;
    int targetStartColumnB1 = 12;
    ElementKind targetKindB1 = ElementKind.ENUM;
    Location targetLocationB1 = new Location(fileB, targetOffsetB1,
        targetLengthB1, targetStartLineB1, targetStartColumnB1);
    int targetOffsetB2 = 13;
    int targetLengthB2 = 14;
    int targetStartLineB2 = 15;
    int targetStartColumnB2 = 16;
    ElementKind targetKindB2 = ElementKind.METHOD;
    Location targetLocationB2 = new Location(fileB, targetOffsetB2,
        targetLengthB2, targetStartLineB2, targetStartColumnB2);

    // Six regions targeting a1, b1, a2, b1, a1, b2
    List<int> regionOffsets = [17, 18, 19, 20, 21, 22];
    List<int> regionLengths = [23, 24, 25, 26, 27, 28];
    List<ElementKind> targetKinds = [
      targetKindA1,
      targetKindB1,
      targetKindA2,
      targetKindB1,
      targetKindA1,
      targetKindB2
    ];
    List<Location> targetLocations = [
      targetLocationA1,
      targetLocationB1,
      targetLocationA2,
      targetLocationB1,
      targetLocationA1,
      targetLocationB2
    ];
    for (int i = 0; i < 6; i++) {
      collector.addRegion(regionOffsets[i], regionLengths[i], targetKinds[i],
          targetLocations[i]);
    }

    collector.createRegions();
    expect(collector.files, [fileA, fileB]);
    expect(collector.regions, [
      new NavigationRegion(regionOffsets[0], regionLengths[0], [0]),
      new NavigationRegion(regionOffsets[1], regionLengths[1], [1]),
      new NavigationRegion(regionOffsets[2], regionLengths[2], [2]),
      new NavigationRegion(regionOffsets[3], regionLengths[3], [1]),
      new NavigationRegion(regionOffsets[4], regionLengths[4], [0]),
      new NavigationRegion(regionOffsets[5], regionLengths[5], [3]),
    ]);
    expect(collector.targets, [
      new NavigationTarget(targetKindA1, 0, targetOffsetA1, targetLengthA1,
          targetStartLineA1, targetStartColumnA1),
      new NavigationTarget(targetKindB1, 1, targetOffsetB1, targetLengthB1,
          targetStartLineB1, targetStartColumnB1),
      new NavigationTarget(targetKindA2, 0, targetOffsetA2, targetLengthA2,
          targetStartLineA2, targetStartColumnA2),
      new NavigationTarget(targetKindB2, 1, targetOffsetB2, targetLengthB2,
          targetStartLineB2, targetStartColumnB2),
    ]);
  }

  test_createRegions_none() {
    collector.createRegions();
    expect(collector.files, isEmpty);
    expect(collector.regions, isEmpty);
    expect(collector.targets, isEmpty);
  }

  test_createRegions_single() {
    int regionOffset = 13;
    int regionLength = 7;
    ElementKind targetKind = ElementKind.CLASS;
    String targetFile = 'c.dart';
    int targetOffset = 17;
    int targetLength = 1;
    int targetStartLine = 5;
    int targetStartColumn = 1;
    Location targetLocation = new Location(targetFile, targetOffset,
        targetLength, targetStartLine, targetStartColumn);
    collector.addRegion(regionOffset, regionLength, targetKind, targetLocation);
    collector.createRegions();
    expect(collector.files, [targetFile]);
    expect(collector.regions, [
      new NavigationRegion(regionOffset, regionLength, [0])
    ]);
    expect(collector.targets, [
      new NavigationTarget(targetKind, 0, targetOffset, targetLength,
          targetStartLine, targetStartColumn)
    ]);
  }
}
