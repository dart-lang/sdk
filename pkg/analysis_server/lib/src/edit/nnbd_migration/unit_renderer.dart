// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show HtmlEscape, HtmlEscapeMode, LineSplitter;

import 'package:analysis_server/src/edit/nnbd_migration/migration_info.dart';
import 'package:analysis_server/src/edit/nnbd_migration/offset_mapper.dart';
import 'package:analysis_server/src/edit/nnbd_migration/path_mapper.dart';
import 'package:analysis_server/src/edit/nnbd_migration/web/file_details.dart';
import 'package:path/path.dart' as path;

/// Instrumentation display output for a library that was migrated to use
/// non-nullable types.
class UnitRenderer {
  /// A converter which only escapes "&", "<", and ">". Safe for use in HTML
  /// text, between HTML elements.
  static const HtmlEscape _htmlEscape =
      HtmlEscape(HtmlEscapeMode(escapeLtGt: true));

  /// Displays information for a compilation unit.
  final UnitInfo unitInfo;

  /// Information for a whole migration, so that libraries can reference each
  /// other.
  final MigrationInfo migrationInfo;

  /// An object used to map the file paths of analyzed files to the file paths
  /// of the HTML files used to view the content of those files.
  final PathMapper pathMapper;

  /// Creates an output object for the given library info.
  UnitRenderer(this.unitInfo, this.migrationInfo, this.pathMapper);

  /// Return the path context used to manipulate paths.
  path.Context get pathContext => migrationInfo.pathContext;

  /// Builds a JSON view of the instrumentation information in [unitInfo].
  FileDetails render() {
    return FileDetails(
        regions: _computeRegionContent(unitInfo),
        navigationContent: _computeNavigationContent(),
        sourceCode: unitInfo.content,
        edits: _computeEditList());
  }

  /// Returns the list of edits, as JSON.
  List<EditListItem> _computeEditList() {
    return unitInfo.fixRegions.map((RegionInfo region) {
      return EditListItem(
          line: region.lineNumber,
          explanation: region.explanation,
          offset: region.offset);
    }).toList();
  }

  /// Returns the content of the file with navigation links and anchors added.
  ///
  /// The content of the file (not including added links and anchors) will be
  /// HTML-escaped.
  String _computeNavigationContent() {
    String unitDir = pathContext.dirname(pathMapper.map(unitInfo.path));
    String content = unitInfo.content;
    OffsetMapper mapper = unitInfo.offsetMapper;
    Map<int, String> openInsertions = {};
    Map<int, String> closeInsertions = {};
    //
    // Compute insertions for navigation targets.
    //
    for (NavigationTarget region in unitInfo.targets) {
      if (region.length > 0) {
        int openOffset = mapper.map(region.offset);
        String openInsertion = openInsertions[openOffset] ?? '';
        openInsertion = '<span id="o${region.offset}">$openInsertion';
        openInsertions[openOffset] = openInsertion;

        int closeOffset = openOffset + region.length;
        String closeInsertion = closeInsertions[closeOffset] ?? '';
        closeInsertion = '$closeInsertion</span>';
        closeInsertions[closeOffset] = closeInsertion;
      }
    }
    //
    // Compute insertions for navigation sources, but skip the sources that
    // point at themselves.
    //
    for (NavigationSource region in unitInfo.sources ?? <NavigationSource>[]) {
      if (region.length > 0) {
        int openOffset = mapper.map(region.offset);
        NavigationTarget target = region.target;
        if (target.filePath != unitInfo.path ||
            region.offset != target.offset) {
          String openInsertion = openInsertions[openOffset] ?? '';
          String unitPath = pathContext
              .relative(pathMapper.map(target.filePath), from: unitDir);
          String targetUri = _uriForRelativePath(unitPath, target);
          openInsertion =
              '<a href="$targetUri" class="nav-link">$openInsertion';
          openInsertions[openOffset] = openInsertion;

          int closeOffset = openOffset + region.length;
          String closeInsertion = closeInsertions[closeOffset] ?? '';
          closeInsertion = '$closeInsertion</a>';
          closeInsertions[closeOffset] = closeInsertion;
        }
      }
    }
    //
    // Apply the insertions that have been computed.
    //
    List<int> offsets = [...openInsertions.keys, ...closeInsertions.keys];
    offsets.sort();
    StringBuffer navContent2 = StringBuffer();
    int previousOffset = 0;
    for (int offset in offsets) {
      navContent2.write(
          _htmlEscape.convert(content.substring(previousOffset, offset)));
      navContent2.write(closeInsertions[offset] ?? '');
      navContent2.write(openInsertions[offset] ?? '');
      previousOffset = offset;
    }
    if (previousOffset < content.length) {
      navContent2.write(_htmlEscape.convert(content.substring(previousOffset)));
    }
    return navContent2.toString();
  }

  /// Returns the content of regions, based on the [unitInfo] for both
  /// unmodified and modified regions.
  ///
  /// The content of the file (not including added links and anchors) will be
  /// HTML-escaped.
  String _computeRegionContent(UnitInfo unit) {
    String content = unitInfo.content;
    StringBuffer regions = StringBuffer();
    int lineNumber = 1;

    void writeSplitLines(
      String lines, {
      String perLineOpeningTag = '',
      String perLineClosingTag = '',
    }) {
      Iterator<String> lineIterator = LineSplitter.split(lines).iterator;
      lineIterator.moveNext();

      while (true) {
        regions.write(perLineOpeningTag);
        regions.write(_htmlEscape.convert(lineIterator.current));
        regions.write(perLineClosingTag);
        if (lineIterator.moveNext()) {
          // If we're not on the last element, end this table row, and start a
          // new table row.
          lineNumber++;
          regions.write('</td></tr>'
              '<tr><td class="line-no">$lineNumber</td>'
              '<td class="line-$lineNumber">');
        } else {
          break;
        }
      }

      if (lines.endsWith('\n')) {
        lineNumber++;
        regions.write('</td></tr>'
            '<tr><td class="line-no">$lineNumber</td>'
            '<td class="line-$lineNumber">');
      }
    }

    /// Returns the CSS class for a region with a given [RegionType].
    String classForRegion(RegionType type) {
      switch (type) {
        case RegionType.add:
          return 'added-region';
        case RegionType.remove:
          return 'removed-region';
        case RegionType.informative:
          return 'informative-region';
      }
      throw StateError('Unexpected RegionType $type');
    }

    int previousOffset = 0;
    regions.write('<table data-path="${unit.path}"><tbody>');
    regions.write('<tr><td class="line-no">$lineNumber</td><td>');
    for (var region in unitInfo.regions) {
      int offset = region.offset;
      int length = region.length;
      if (offset > previousOffset) {
        // Display a region of unmodified content.
        writeSplitLines(content.substring(previousOffset, offset));
        previousOffset = offset + length;
      }
      String regionClass = classForRegion(region.regionType);
      String regionSpanTag = '<span class="region $regionClass" '
          'data-offset="$offset" data-line="$lineNumber">';
      writeSplitLines(content.substring(offset, offset + length),
          perLineOpeningTag: regionSpanTag, perLineClosingTag: '</span>');
    }
    if (previousOffset < content.length) {
      // Last region of unmodified content.
      writeSplitLines(content.substring(previousOffset));
    }
    regions.write('</td></tr></tbody></table>');
    return regions.toString();
  }

  /// Returns the URL that will navigate to the given [target] in the file at
  /// the given [relativePath].
  String _uriForRelativePath(String relativePath, NavigationTarget target) {
    var queryParams = {
      'offset': target.offset,
      if (target.line != null) 'line': target.line,
    }.entries.map((entry) => '${entry.key}=${entry.value}').join('&');
    return '$relativePath?$queryParams';
  }
}
