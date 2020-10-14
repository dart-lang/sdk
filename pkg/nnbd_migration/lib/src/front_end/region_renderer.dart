// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:nnbd_migration/src/front_end/migration_info.dart';
import 'package:nnbd_migration/src/front_end/path_mapper.dart';
import 'package:nnbd_migration/src/front_end/web/edit_details.dart';
import 'package:path/path.dart' as path;

/// The HTML that is displayed for a region of code.
class RegionRenderer {
  /// A flag indicating whether the incremental workflow is currently supported.
  static const bool supportsIncrementalWorkflow = true;

  /// The region to render.
  final RegionInfo region;

  /// The compilation unit information containing the region.
  final UnitInfo unitInfo;

  final MigrationInfo migrationInfo;

  /// An object used to map the file paths of analyzed files to the file paths
  /// of the HTML files used to view the content of those files.
  final PathMapper pathMapper;

  /// The auth token for the current site, for use in generating URIs.
  final String authToken;

  /// Initializes a newly created region page within the given [site]. The
  /// [unitInfo] provides the information needed to render the page.
  RegionRenderer(this.region, this.unitInfo, this.migrationInfo,
      this.pathMapper, this.authToken);

  /// Returns the path context used to manipulate paths.
  path.Context get pathContext => migrationInfo.pathContext;

  EditDetails render() {
    TargetLink linkForTarget(NavigationTarget target) {
      var relativePath =
          _relativePathToTarget(target, pathContext.dirname(unitInfo.path));
      var targetUri = _uriForPath(target.filePath, target);
      return TargetLink(
        path: relativePath,
        href: targetUri,
        line: target.line,
      );
    }

    EditLink linkForEdit(EditDetail edit) => EditLink(
        description: edit.description,
        href: Uri(path: pathContext.basename(unitInfo.path), queryParameters: {
          'offset': edit.offset.toString(),
          'end': (edit.offset + edit.length).toString(),
          'replacement': edit.replacement
        }).toString());

    var response = EditDetails(
      displayPath: unitInfo.path,
      uriPath: pathMapper.map(unitInfo.path),
      line: region.lineNumber,
      explanation: region.explanation,
      edits: supportsIncrementalWorkflow
          ? [
              for (var edit in region.edits) linkForEdit(edit),
            ]
          : null,
      traces: [
        for (var trace in region.traces)
          Trace(description: trace.description, entries: [
            for (var entry in trace.entries)
              TraceEntry(
                  description: entry.description,
                  function: entry.function,
                  link:
                      entry.target == null ? null : linkForTarget(entry.target),
                  hintActions: entry.hintActions)
          ])
      ],
    );
    return response;
  }

  /// Returns the URL that will navigate to the given [target].
  String _relativePathToTarget(NavigationTarget target, String unitDir) {
    if (target == null) {
      // TODO(brianwilkerson) This is temporary support until we can get targets
      //  for all nodes.
      return '';
    }
    return pathMapper.map(pathContext.relative(target.filePath, from: unitDir));
  }

  /// Return the URL that will navigate to the given [target] in the file at the
  /// given [path].
  String _uriForPath(String path, NavigationTarget target) {
    var queryParams = {
      'offset': target.offset,
      if (target.line != null) 'line': target.line,
      'authToken': authToken,
    }.entries.map((entry) => '${entry.key}=${entry.value}').join('&');
    return '${pathMapper.map(path)}?$queryParams';
  }
}
