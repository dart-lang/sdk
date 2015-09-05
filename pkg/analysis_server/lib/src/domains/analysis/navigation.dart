// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library domains.analysis.navigation;

import 'dart:collection';

import 'package:analysis_server/analysis/navigation/navigation_core.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/collections.dart';
import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisContext, AnalysisEngine;
import 'package:analyzer/src/generated/java_engine.dart' show CaughtException;
import 'package:analyzer/src/generated/source.dart' show Source;

/**
 * Compute all known navigation information for the given part of [source].
 */
NavigationHolderImpl computeNavigation(AnalysisServer server,
    AnalysisContext context, Source source, int offset, int length) {
  NavigationHolderImpl holder = new NavigationHolderImpl();
  List<NavigationContributor> contributors =
      server.serverPlugin.navigationContributors;
  for (NavigationContributor contributor in contributors) {
    try {
      contributor.computeNavigation(holder, context, source, offset, length);
    } catch (exception, stackTrace) {
      AnalysisEngine.instance.logger.logError(
          'Exception from navigation contributor: ${contributor.runtimeType}',
          new CaughtException(exception, stackTrace));
    }
  }
  holder.sortRegions();
  return holder;
}

/**
 * A concrete implementation of  [NavigationHolder].
 */
class NavigationHolderImpl implements NavigationHolder {
  /**
   * A list of navigation regions.
   */
  final List<protocol.NavigationRegion> regions = <protocol.NavigationRegion>[];

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
    int targetIndex = _addTarget(targetKind, targetLocation);
    protocol.NavigationRegion region =
        new protocol.NavigationRegion(offset, length, <int>[targetIndex]);
    regions.add(region);
  }

  void sortRegions() {
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
