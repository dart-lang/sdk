// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show jsonEncode;

import 'package:analysis_server/src/edit/nnbd_migration/migration_info.dart';
import 'package:analysis_server/src/edit/nnbd_migration/path_mapper.dart';
import 'package:path/path.dart' as path;

/// The HTML that is displayed for a region of code.
class RegionRenderer {
  /// A flag indicating whether the incremental workflow is currently supported.
  static const bool supportsIncrementalWorkflow = false;

  /// The region to render.
  final RegionInfo region;

  /// The compilation unit information containing the region.
  final UnitInfo unitInfo;

  final MigrationInfo migrationInfo;

  /// An object used to map the file paths of analyzed files to the file paths
  /// of the HTML files used to view the content of those files.
  final PathMapper pathMapper;

  /// Initializes a newly created region page within the given [site]. The
  /// [unitInfo] provides the information needed to render the page.
  RegionRenderer(
      this.region, this.unitInfo, this.migrationInfo, this.pathMapper);

  /// Returns the path context used to manipulate paths.
  path.Context get pathContext => migrationInfo.pathContext;

  String render() {
    var unitDir = pathContext.dirname(pathMapper.map(unitInfo.path));

    Map<String, dynamic> linkForTarget(NavigationTarget target) {
      String relativePath = _relativePathToTarget(target, unitDir);
      String targetUri = _uriForRelativePath(relativePath, target);
      return {
        'text': relativePath,
        'href': targetUri,
        'line': target.line,
      };
    }

    Map<String, String> linkForEdit(EditDetail edit) => {
          'text': edit.description,
          'href': Uri(
              scheme: 'http',
              path: pathContext.basename(unitInfo.path),
              queryParameters: {
                'offset': edit.offset.toString(),
                'end': (edit.offset + edit.length).toString(),
                'replacement': edit.replacement
              }).toString()
        };

    var response = {
      'path': unitInfo.path,
      'line': region.lineNumber,
      'explanation': region.explanation,
      'details': [
        for (var detail in region.details)
          {
            'description': detail.description,
            if (detail.target != null) 'link': linkForTarget(detail.target)
          },
      ],
      if (supportsIncrementalWorkflow)
        'edits': [
          for (var edit in region.edits) linkForEdit(edit),
        ],
    };
    return jsonEncode(response);
  }

  /// Returns the URL that will navigate to the given [target].
  String _relativePathToTarget(NavigationTarget target, String unitDir) {
    if (target == null) {
      // TODO(brianwilkerson) This is temporary support until we can get targets
      //  for all nodes.
      return '';
    }
    return pathContext.relative(pathMapper.map(target.filePath), from: unitDir);
  }

  /// Return the URL that will navigate to the given [target] in the file at the
  /// given [relativePath].
  String _uriForRelativePath(String relativePath, NavigationTarget target) {
    var queryParams = {
      'offset': target.offset,
      if (target.line != null) 'line': target.line,
    }.entries.map((entry) => '${entry.key}=${entry.value}').join('&');
    return '$relativePath?$queryParams';
  }
}
