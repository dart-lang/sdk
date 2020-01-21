// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show HtmlEscape, HtmlEscapeMode;

import 'package:analysis_server/src/edit/nnbd_migration/migration_info.dart';
import 'package:analysis_server/src/edit/nnbd_migration/path_mapper.dart';
import 'package:path/path.dart' as path;

/// The HTML that is displayed for a region of code.
class RegionRenderer {
  /// A converter which only escapes "&", "<", and ">". Safe for use in HTML
  /// text, between HTML elements.
  static const HtmlEscape _htmlEscape =
      HtmlEscape(HtmlEscapeMode(escapeLtGt: true));

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
    var buffer = StringBuffer();
    buffer.write('<p class="region-location">');
    // The line number is hard to compute here, but is known in the browser.
    // The browser will write the line number at the end of this paragraph.
    buffer.write(unitDir);
    buffer.write('</p>');
    buffer.write('<p>${_htmlEscape.convert(region.explanation)}</p>');
    //
    // Write out any details.
    //
    if (region.details.isNotEmpty) {
      buffer.write('<ul>');
      for (var detail in region.details) {
        buffer.write('<li>');
        buffer.write(detail.description);
        NavigationTarget target = detail.target;
        if (target != null) {
          String relativePath = _relativePathToTarget(target, unitDir);
          String targetUri = _uriForRelativePath(relativePath, target);
          buffer.write(' (<a href="$targetUri" class="nav-link">');
          buffer.write(relativePath);
          // TODO(brianwilkerson) Add the line number to the link text. This
          //  will require that either the contents of all navigation targets
          //  have been set or that line information has been saved.
          buffer.write('</a>)');
        }
        buffer.write('</li>');
      }
      buffer.write('</ul>');
    }
    //
    // Write out any edits.
    //
    if (supportsIncrementalWorkflow && region.edits.isNotEmpty) {
      for (EditDetail edit in region.edits) {
        int offset = edit.offset;
        String targetUri = Uri(
            scheme: 'http',
            path: pathContext.basename(unitInfo.path),
            queryParameters: {
              'offset': offset.toString(),
              'end': (offset + edit.length).toString(),
              'replacement': edit.replacement
            }).toString();
        buffer.write('<p>');
        buffer.write('<a href="$targetUri" class="nav-link">');
        buffer.write(edit.description);
        buffer.write('</a>');
        buffer.write('</p>');
      }
    }
    return buffer.toString();
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
