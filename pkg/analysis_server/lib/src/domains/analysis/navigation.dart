// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analysis_server/plugin/analysis/navigation/navigation_core.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/collections.dart';
import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisContext, AnalysisEngine;
import 'package:analyzer/src/generated/source.dart' show Source, SourceRange;

/**
 * Compute all known navigation information for the given part of [source].
 */
NavigationCollectorImpl computeNavigation(AnalysisServer server,
    AnalysisContext context, Source source, int offset, int length) {
  NavigationCollectorImpl collector = new NavigationCollectorImpl();
  List<NavigationContributor> contributors =
      server.serverPlugin.navigationContributors;
  for (NavigationContributor contributor in contributors) {
    try {
      contributor.computeNavigation(collector, context, source, offset, length);
    } catch (exception, stackTrace) {
      AnalysisEngine.instance.logger.logError(
          'Exception from navigation contributor: ${contributor.runtimeType}',
          new CaughtException(exception, stackTrace));
    }
  }
  collector.createRegions();
  return collector;
}

/**
 * A concrete implementation of  [NavigationCollector].
 */
class NavigationCollectorImpl implements NavigationCollector {
  /**
   * A list of navigation regions.
   */
  final List<protocol.NavigationRegion> regions = <protocol.NavigationRegion>[];
  final Map<SourceRange, List<int>> regionMap =
      new HashMap<SourceRange, List<int>>();

  /**
   * All the unique targets referenced by [regions].
   */
  final List<protocol.NavigationTarget> targets = <protocol.NavigationTarget>[];
  final Map<Pair<protocol.ElementKind, protocol.Location>, int> targetMap =
      new HashMap<Pair<protocol.ElementKind, protocol.Location>, int>();

  /**
   * All the unique files referenced by [targets].
   */
  final List<String> files = <String>[];
  final Map<String, int> fileMap = new HashMap<String, int>();

  @override
  void addRegion(int offset, int length, protocol.ElementKind targetKind,
      protocol.Location targetLocation) {
    SourceRange range = new SourceRange(offset, length);
    // prepare targets
    List<int> targets = regionMap[range];
    if (targets == null) {
      targets = <int>[];
      regionMap[range] = targets;
    }
    // add new target
    int targetIndex = _addTarget(targetKind, targetLocation);
    targets.add(targetIndex);
  }

  void createRegions() {
    regionMap.forEach((range, targets) {
      protocol.NavigationRegion region =
          new protocol.NavigationRegion(range.offset, range.length, targets);
      regions.add(region);
    });
    regions.sort((a, b) {
      return a.offset - b.offset;
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

  int _addTarget(protocol.ElementKind kind, protocol.Location location) {
    var pair =
        new Pair<protocol.ElementKind, protocol.Location>(kind, location);
    int index = targetMap[pair];
    if (index == null) {
      String file = location.file;
      int fileIndex = _addFile(file);
      index = targets.length;
      protocol.NavigationTarget target = new protocol.NavigationTarget(
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
