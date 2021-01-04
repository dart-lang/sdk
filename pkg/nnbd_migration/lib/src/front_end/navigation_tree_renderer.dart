// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:nnbd_migration/src/front_end/migration_info.dart';
import 'package:nnbd_migration/src/front_end/path_mapper.dart';
import 'package:nnbd_migration/src/front_end/unit_link.dart';
import 'package:nnbd_migration/src/front_end/web/navigation_tree.dart';
import 'package:path/path.dart' as path;

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
  List<NavigationTreeNode> render() {
    var linkData = migrationInfo.unitLinks();
    var tree = _renderNavigationSubtree(linkData, 0);
    for (var node in tree) {
      node.parent = null;
    }
    return tree;
  }

  /// Renders the navigation link subtree at [depth].
  List<NavigationTreeNode> _renderNavigationSubtree(
      List<UnitLink> links, int depth) {
    var linksGroupedByDirectory = _groupBy(
        links.where((link) => link.depth > depth),
        (UnitLink link) => link.pathParts[depth]);

    return [
      for (var entry in linksGroupedByDirectory.entries)
        NavigationTreeDirectoryNode(
          name: entry.key,
          path: pathContext
              .dirname(pathContext.joinAll(entry.value.first.pathParts)),
          subtree: _renderNavigationSubtree(entry.value, depth + 1),
        )..setSubtreeParents(),
      for (var link in links.where((link) => link.depth == depth))
        NavigationTreeFileNode(
          name: link.fileName,
          path: pathContext.joinAll(link.pathParts),
          href: pathMapper.map(link.fullPath),
          editCount: link.editCount,
          wasExplicitlyOptedOut: link.wasExplicitlyOptedOut,
          migrationStatus: link.migrationStatus,
        ),
    ];
  }
}
