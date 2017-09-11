// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/source.dart' show SourceRange;
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/utilities/navigation/navigation.dart';
import 'package:analyzer_plugin/utilities/pair.dart';

/**
 * A concrete implementation of [DartNavigationRequest].
 */
class DartNavigationRequestImpl implements DartNavigationRequest {
  @override
  final ResourceProvider resourceProvider;

  @override
  final int length;

  @override
  final int offset;

  @override
  final ResolveResult result;

  /**
   * Initialize a newly create request with the given data.
   */
  DartNavigationRequestImpl(
      this.resourceProvider, this.offset, this.length, this.result);

  @override
  String get path => result.path;
}

/**
 * A concrete implementation of [NavigationCollector].
 */
class NavigationCollectorImpl implements NavigationCollector {
  /**
   * A list of navigation regions.
   */
  final List<NavigationRegion> regions = <NavigationRegion>[];
  final Map<SourceRange, List<int>> regionMap = <SourceRange, List<int>>{};

  /**
   * All the unique targets referenced by [regions].
   */
  final List<NavigationTarget> targets = <NavigationTarget>[];
  final Map<Pair<ElementKind, Location>, int> targetMap =
      <Pair<ElementKind, Location>, int>{};

  /**
   * All the unique files referenced by [targets].
   */
  final List<String> files = <String>[];
  final Map<String, int> fileMap = <String, int>{};

  @override
  void addRange(
      SourceRange range, ElementKind targetKind, Location targetLocation) {
    addRegion(range.offset, range.length, targetKind, targetLocation);
  }

  @override
  void addRegion(
      int offset, int length, ElementKind targetKind, Location targetLocation) {
    SourceRange range = new SourceRange(offset, length);
    // add new target
    List<int> targets = regionMap.putIfAbsent(range, () => <int>[]);
    int targetIndex = _addTarget(targetKind, targetLocation);
    targets.add(targetIndex);
  }

  void createRegions() {
    regionMap.forEach((range, targets) {
      NavigationRegion region =
          new NavigationRegion(range.offset, range.length, targets);
      regions.add(region);
    });
    regions.sort((NavigationRegion first, NavigationRegion second) {
      return first.offset - second.offset;
    });
  }

  int _addFile(String file) {
    int index = fileMap[file];
    if (index == null) {
      index = files.length;
      files.add(file);
      fileMap[file] = index;
    }
    return index;
  }

  int _addTarget(ElementKind kind, Location location) {
    var pair = new Pair<ElementKind, Location>(kind, location);
    int index = targetMap[pair];
    if (index == null) {
      String file = location.file;
      int fileIndex = _addFile(file);
      index = targets.length;
      NavigationTarget target = new NavigationTarget(
          kind,
          fileIndex,
          location.offset,
          location.length,
          location.startLine,
          location.startColumn);
      targets.add(target);
      targetMap[pair] = index;
    }
    return index;
  }
}
