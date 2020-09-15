// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/source.dart' show SourceRange;
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/utilities/navigation/navigation.dart';
import 'package:analyzer_plugin/utilities/pair.dart';

/// A concrete implementation of [DartNavigationRequest].
class DartNavigationRequestImpl implements DartNavigationRequest {
  @override
  final ResourceProvider resourceProvider;

  @override
  final int length;

  @override
  final int offset;

  @override
  final ResolvedUnitResult result;

  /// Initialize a newly create request with the given data.
  DartNavigationRequestImpl(
      this.resourceProvider, this.offset, this.length, this.result);

  @override
  String get path => result.path;
}

/// A concrete implementation of [NavigationCollector].
class NavigationCollectorImpl implements NavigationCollector {
  /// Whether the collector is collecting target code locations. Computers can
  /// skip computing these if this is false.
  @override
  final bool collectCodeLocations;

  /// A list of navigation regions.
  final List<NavigationRegion> regions = <NavigationRegion>[];

  final Map<SourceRange, List<int>> regionMap = <SourceRange, List<int>>{};

  /// All the unique targets referenced by [regions].
  final List<NavigationTarget> targets = <NavigationTarget>[];

  final Map<Pair<ElementKind, Location>, int> targetMap =
      <Pair<ElementKind, Location>, int>{};

  /// All the unique files referenced by [targets].
  final List<String> files = <String>[];

  final Map<String, int> fileMap = <String, int>{};

  NavigationCollectorImpl({this.collectCodeLocations = false});

  @override
  void addRange(
      SourceRange range, ElementKind targetKind, Location targetLocation,
      {Location targetCodeLocation}) {
    addRegion(range.offset, range.length, targetKind, targetLocation,
        targetCodeLocation: targetCodeLocation);
  }

  @override
  void addRegion(
      int offset, int length, ElementKind targetKind, Location targetLocation,
      {Location targetCodeLocation}) {
    var range = SourceRange(offset, length);
    // add new target
    var targets = regionMap.putIfAbsent(range, () => <int>[]);
    var targetIndex =
        _addTarget(targetKind, targetLocation, targetCodeLocation);
    targets.add(targetIndex);
  }

  void createRegions() {
    regionMap.forEach((range, targets) {
      var region = NavigationRegion(range.offset, range.length, targets);
      regions.add(region);
    });
    regions.sort((NavigationRegion first, NavigationRegion second) {
      return first.offset - second.offset;
    });
  }

  int _addFile(String file) {
    var index = fileMap[file];
    if (index == null) {
      index = files.length;
      files.add(file);
      fileMap[file] = index;
    }
    return index;
  }

  int _addTarget(ElementKind kind, Location location, Location codeLocation) {
    var pair = Pair<ElementKind, Location>(kind, location);
    var index = targetMap[pair];
    if (index == null) {
      var file = location.file;
      var fileIndex = _addFile(file);
      index = targets.length;
      var target = NavigationTarget(kind, fileIndex, location.offset,
          location.length, location.startLine, location.startColumn,
          codeOffset: collectCodeLocations ? codeLocation?.offset : null,
          codeLength: collectCodeLocations ? codeLocation?.length : null);
      targets.add(target);
      targetMap[pair] = index;
    }
    return index;
  }
}
