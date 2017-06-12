// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/domains/analysis/navigation.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NavigationCollectorImplTest);
  });
}

@reflectiveTest
class NavigationCollectorImplTest {
  NavigationCollectorImpl collector = new NavigationCollectorImpl();

  void test_multipleTargets() {
    collector.addRegion(
        10, 5, ElementKind.CLASS, new Location('file', 11, 12, 13, 14));
    collector.addRegion(
        10, 5, ElementKind.CLASS, new Location('file', 21, 22, 23, 24));
    collector.createRegions();
    List<NavigationRegion> regions = collector.regions;
    expect(regions, hasLength(1));
    {
      NavigationRegion region = regions[0];
      expect(region.offset, 10);
      expect(region.length, 5);
      expect(region.targets, hasLength(2));
      {
        NavigationTarget target = collector.targets[region.targets[0]];
        expect(target.offset, 11);
        expect(target.length, 12);
      }
      {
        NavigationTarget target = collector.targets[region.targets[1]];
        expect(target.offset, 21);
        expect(target.length, 22);
      }
    }
  }

  void test_unique() {
    collector.addRegion(
        100, 10, ElementKind.CLASS, new Location('file', 11, 12, 13, 14));
    collector.addRegion(
        200, 20, ElementKind.CLASS, new Location('file', 21, 22, 23, 24));
    collector.createRegions();
    List<NavigationRegion> regions = collector.regions;
    expect(regions, hasLength(2));
    {
      NavigationRegion region = regions[0];
      expect(region.offset, 100);
      expect(region.length, 10);
      expect(region.targets, hasLength(1));
      {
        NavigationTarget target = collector.targets[region.targets[0]];
        expect(target.offset, 11);
        expect(target.length, 12);
      }
    }
    {
      NavigationRegion region = regions[1];
      expect(region.offset, 200);
      expect(region.length, 20);
      expect(region.targets, hasLength(1));
      {
        NavigationTarget target = collector.targets[region.targets[0]];
        expect(target.offset, 21);
        expect(target.length, 22);
      }
    }
  }
}
