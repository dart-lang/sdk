// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show jsonEncode;

import 'package:analysis_server/src/edit/nnbd_migration/migration_info.dart';
import 'package:analysis_server/src/edit/nnbd_migration/path_mapper.dart';
import 'package:analysis_server/src/edit/nnbd_migration/unit_link.dart';
import 'package:path/path.dart' as path;

/// The HTML that is displayed for a region of code.
class NavigationTreeRenderer {
  final MigrationInfo migrationInfo;

  /// An object used to map the file paths of analyzed files to the file paths
  /// of the HTML files used to view the content of those files.
  final PathMapper pathMapper;

  /// Initializes a newly created region page within the given [site]. The
  /// [unitInfo] provides the information needed to render the page.
  NavigationTreeRenderer(this.migrationInfo, this.pathMapper);

  /// Returns the path context used to manipulate paths.
  path.Context get pathContext => migrationInfo.pathContext;

  /// Renders the navigation link tree.
  String render() {
    var linkData = migrationInfo.unitLinks();
    var tree = _renderNavigationSubtree(linkData, 0);
    return jsonEncode(tree);
  }

  /// Renders the navigation link subtree at [depth].
  List<Object> _renderNavigationSubtree(List<UnitLink> links, int depth) {
    var linksGroupedByDirectory = _groupBy(
        links.where((link) => link.depth > depth),
        (UnitLink link) => link.pathParts[depth]);
    return [
      for (var entry in linksGroupedByDirectory.entries)
        {
          'type': 'directory',
          'name': entry.key,
          'subtree': _renderNavigationSubtree(entry.value, depth + 1),
        },
      for (var link in links.where((link) => link.depth == depth))
        {
          'type': 'file',
          'name': link.fileName,
          'path': pathContext.joinAll(link.pathParts),
          'href': link.url,
          'editCount': link.editCount,
        },
    ];
  }
}

/// Groups the items in [iterable] by the result of applying [groupFn] to each
/// item.
Map<K, List<T>> _groupBy<K, T>(
    Iterable<T> iterable, K Function(T item) groupFn) {
  var result = <K, List<T>>{};
  for (var item in iterable) {
    var key = groupFn(item);
    result.putIfAbsent(key, () => <T>[]).add(item);
  }
  return result;
}
