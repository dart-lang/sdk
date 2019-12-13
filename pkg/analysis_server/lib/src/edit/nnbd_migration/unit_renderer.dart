// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show htmlEscape, jsonEncode, LineSplitter;

import 'package:analysis_server/src/edit/nnbd_migration/migration_info.dart';
import 'package:analysis_server/src/edit/nnbd_migration/offset_mapper.dart';
import 'package:analysis_server/src/edit/nnbd_migration/path_mapper.dart';
import 'package:path/path.dart' as path;

/// Instrumentation display output for a library that was migrated to use
/// non-nullable types.
class UnitRenderer {
  /// A flag indicating whether the incremental workflow is currently supported.
  static const bool supportsIncrementalWorkflow = false;

  /// Display information for a compilation unit.
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

  /// Builds an HTML view of the instrumentation information in [unitInfo].
  String render() {
    Map<String, dynamic> response = {
      'thisUnit': migrationInfo.computeName(unitInfo),
      'navContent': _computeNavigationContent(unitInfo),
      'regions': _computeRegionContent(unitInfo),
    };
    return jsonEncode(response);
  }

  /// Return the content of the file with navigation links and anchors added.
  String _computeNavigationContent(UnitInfo unitInfo) {
    String content = unitInfo.content;
    OffsetMapper mapper = unitInfo.offsetMapper;
    Map<int, String> openInsertions = {};
    Map<int, String> closeInsertions = {};
    //
    // Compute insertions for navigation targets.
    //
    for (NavigationTarget region in unitInfo.targets) {
      int regionLength = region.length;
      if (regionLength > 0) {
        int openOffset = mapper.map(region.offset);
        String openInsertion = openInsertions[openOffset] ?? '';
        openInsertion = '<span id="o${region.offset}">$openInsertion';
        openInsertions[openOffset] = openInsertion;

        int closeOffset = openOffset + regionLength;
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
      int regionLength = region.length;
      if (regionLength > 0) {
        int openOffset = mapper.map(region.offset);
        NavigationTarget target = region.target;
        if (target.filePath != unitInfo.path ||
            region.offset != target.offset) {
          String openInsertion = openInsertions[openOffset] ?? '';
          String unitPath = pathContext.relative(
              pathMapper.map(target.filePath),
              from: migrationInfo.includedRoot);
          openInsertion = '<a href="#" class="nav-link" data-path="$unitPath" '
              'data-offset="${target.offset}">$openInsertion';
          openInsertions[openOffset] = openInsertion;

          int closeOffset = openOffset + regionLength;
          String closeInsertion = closeInsertions[closeOffset] ?? '';
          closeInsertion = '$closeInsertion</a>';
          closeInsertions[closeOffset] = closeInsertion;
        }
      }
    }
    //
    // Apply the insertions that have been computed.
    //
    List<int> offsets = []
      ..addAll(openInsertions.keys)
      ..addAll(closeInsertions.keys);
    offsets.sort();
    StringBuffer navContent2 = StringBuffer();
    int previousOffset2 = 0;
    for (int offset in offsets) {
      navContent2.write(content.substring(previousOffset2, offset));
      navContent2.write(closeInsertions[offset] ?? '');
      navContent2.write(openInsertions[offset] ?? '');
      previousOffset2 = offset;
    }
    if (previousOffset2 < content.length) {
      navContent2.write(content.substring(previousOffset2));
    }
    return navContent2.toString();
  }

  /// Return the content of regions, based on the [unitInfo] for both
  /// unmodified and modified regions.
  String _computeRegionContent(UnitInfo unitInfo) {
    String unitDir = _directoryContaining(unitInfo);
    String content = unitInfo.content;
    StringBuffer regions = StringBuffer();
    int lineNumber = 1;

    void writeSplitLines(String lines) {
      Iterator<String> lineIterator = LineSplitter.split(lines).iterator;
      lineIterator.moveNext();

      while (true) {
        regions.write(htmlEscape.convert(lineIterator.current));
        if (lineIterator.moveNext()) {
          // If we're not on the last element, end this table row, and start a
          // new table row.
          lineNumber++;
          regions.write(
              '</td></tr>' '<tr><td class="line-no">$lineNumber</td><td>');
        } else {
          break;
        }
      }
    }

    int previousOffset = 0;
    regions.write('<table><tbody><tr><td class="line-no">$lineNumber</td><td>');
    for (var region in unitInfo.regions) {
      int offset = region.offset;
      int length = region.length;
      if (offset > previousOffset) {
        // Display a region of unmodified content.
        writeSplitLines(content.substring(previousOffset, offset));
        previousOffset = offset + length;
      }
      String regionClass = region.regionType == RegionType.fix
          ? 'fix-region'
          : 'non-nullable-type-region';
      regions.write('<span class="region $regionClass">'
          '${content.substring(offset, offset + length)}'
          '<span class="tooltip">'
          '<p>${region.explanation}</p>');
      //
      // Write out any details.
      //
      if (region.details.isNotEmpty) {
        regions.write('<ul>');
        for (var detail in region.details) {
          regions.write('<li>');
          writeSplitLines(detail.description);
          NavigationTarget target = detail.target;
          if (target != null) {
            String relativePath = _relativePathToTarget(target, unitDir);
            String targetUri = _uriForRelativePath(relativePath, target);
            regions.write(' (<a href="$targetUri">');
            regions.write(relativePath);
            // TODO(brianwilkerson) Add the line number to the link text. This
            //  will require that either the contents of all navigation targets
            //  have been set or that line information has been saved.
            regions.write('</a>)');
          }
          regions.write('</li>');
        }
        regions.write('</ul>');
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
          regions.write('<p>');
          regions.write('<a href="$targetUri">');
          regions.write(edit.description);
          regions.write('</a>');
          regions.write('</p>');
        }
      }
      regions.write('</span></span>');
    }
    if (previousOffset < content.length) {
      // Last region of unmodified content.
      writeSplitLines(content.substring(previousOffset));
    }
    regions.write('</td></tr></tbody></table>');
    return regions.toString();
  }

  /// Return the path to the directory containing the output generated from the
  /// [unitInfo].
  String _directoryContaining(UnitInfo unitInfo) {
    return pathContext.dirname(pathMapper.map(unitInfo.path));
  }

  /// Return the URL that will navigate to the given [target].
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
    return '$relativePath?offset=${target.offset.toString()}';
  }
}
