// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show HtmlEscape, HtmlEscapeMode, LineSplitter;

import 'package:meta/meta.dart';
import 'package:nnbd_migration/nnbd_migration.dart';
import 'package:nnbd_migration/src/front_end/migration_info.dart';
import 'package:nnbd_migration/src/front_end/path_mapper.dart';
import 'package:nnbd_migration/src/front_end/web/file_details.dart';
import 'package:path/path.dart' as path;

/// Instrumentation display output for a library that was migrated to use
/// non-nullable types.
class UnitRenderer {
  /// A converter which only escapes "&", "<", and ">". Safe for use in HTML
  /// text, between HTML elements.
  static const HtmlEscape _htmlEscape =
      HtmlEscape(HtmlEscapeMode(escapeLtGt: true));

  /// List of kinds of nullability fixes that should be displayed in the
  /// "proposed edits" area, in the order in which they should be displayed.
  @visibleForTesting
  static const List<NullabilityFixKind> kindPriorityOrder = [
    NullabilityFixKind.noValidMigrationForNull,
    NullabilityFixKind.compoundAssignmentHasBadCombinedType,
    NullabilityFixKind.compoundAssignmentHasNullableSource,
    NullabilityFixKind.removeDeadCode,
    NullabilityFixKind.conditionTrueInStrongMode,
    NullabilityFixKind.conditionFalseInStrongMode,
    NullabilityFixKind.nullAwareAssignmentUnnecessaryInStrongMode,
    NullabilityFixKind.nullAwarenessUnnecessaryInStrongMode,
    NullabilityFixKind.otherCastExpression,
    NullabilityFixKind.changeMethodName,
    NullabilityFixKind.checkExpression,
    NullabilityFixKind.addRequired,
    NullabilityFixKind.makeTypeNullable,
    NullabilityFixKind.downcastExpression,
    NullabilityFixKind.addType,
    NullabilityFixKind.replaceVar,
    NullabilityFixKind.removeAs,
    NullabilityFixKind.addLate,
    NullabilityFixKind.addLateDueToTestSetup,
    NullabilityFixKind.addLateDueToHint,
    NullabilityFixKind.addLateFinalDueToHint,
    NullabilityFixKind.checkExpressionDueToHint,
    NullabilityFixKind.makeTypeNullableDueToHint,
    NullabilityFixKind.addImport,
    NullabilityFixKind.removeLanguageVersionComment
  ];

  /// Displays information for a compilation unit.
  final UnitInfo unitInfo;

  /// Information for a whole migration, so that libraries can reference each
  /// other.
  final MigrationInfo migrationInfo;

  /// An object used to map the file paths of analyzed files to the file paths
  /// of the HTML files used to view the content of those files.
  final PathMapper pathMapper;

  /// The auth token for the current site, for use in generating URIs.
  final String authToken;

  /// Creates an output object for the given library info.
  UnitRenderer(
      this.unitInfo, this.migrationInfo, this.pathMapper, this.authToken);

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
  Map<String, List<EditListItem>> _computeEditList() {
    var editListsByKind = <NullabilityFixKind, List<EditListItem>>{};
    for (var region in unitInfo.regions) {
      var kind = region.kind;
      if (kind != null && region.isCounted) {
        (editListsByKind[kind] ??= []).add(EditListItem(
            line: region.lineNumber,
            explanation: region.explanation,
            offset: region.offset));
      }
    }
    // Order the lists and filter out empty categories.
    var result = <String, List<EditListItem>>{};
    for (var kind in kindPriorityOrder) {
      var edits = editListsByKind[kind];
      if (edits != null) {
        result[_headerForKind(kind, edits.length)] = edits;
      }
    }
    return result;
  }

  /// Returns the content of the file with navigation links and anchors added.
  ///
  /// The content of the file (not including added links and anchors) will be
  /// HTML-escaped.
  String _computeNavigationContent() {
    var content = unitInfo.content;
    var mapper = unitInfo.offsetMapper;
    var openInsertions = <int, String>{};
    var closeInsertions = <int, String>{};
    //
    // Compute insertions for navigation targets.
    //
    for (var region in unitInfo.targets) {
      if (region.length > 0) {
        var openOffset = mapper.map(region.offset);
        if (openOffset == null) {
          // Region has been deleted via a hint action.
          continue;
        }
        var openInsertion = openInsertions[openOffset] ?? '';
        openInsertion = '<span id="o${region.offset}">$openInsertion';
        openInsertions[openOffset] = openInsertion;

        var closeOffset = openOffset + region.length;
        var closeInsertion = closeInsertions[closeOffset] ?? '';
        closeInsertion = '$closeInsertion</span>';
        closeInsertions[closeOffset] = closeInsertion;
      }
    }
    //
    // Compute insertions for navigation sources, but skip the sources that
    // point at themselves.
    //
    for (var region in unitInfo.sources ?? <NavigationSource>[]) {
      if (region.length > 0) {
        var openOffset = mapper.map(region.offset);
        if (openOffset == null) {
          // Region has been deleted via a hint action.
          continue;
        }
        var target = region.target;
        if (target.filePath != unitInfo.path ||
            region.offset != target.offset) {
          var openInsertion = openInsertions[openOffset] ?? '';
          var targetUri = _uriForPath(pathMapper.map(target.filePath), target);
          openInsertion =
              '<a href="$targetUri" class="nav-link">$openInsertion';
          openInsertions[openOffset] = openInsertion;

          var closeOffset = openOffset + region.length;
          var closeInsertion = closeInsertions[closeOffset] ?? '';
          closeInsertion = '$closeInsertion</a>';
          closeInsertions[closeOffset] = closeInsertion;
        }
      }
    }
    //
    // Apply the insertions that have been computed.
    //
    var offsets = <int>[...openInsertions.keys, ...closeInsertions.keys];
    offsets.sort();
    var navContent2 = StringBuffer();
    var previousOffset = 0;
    for (var offset in offsets) {
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
    var content = unitInfo.content;
    var rows = <String>[];
    var currentTextCell = StringBuffer();
    bool isAddedLine = false;
    var lineNumber = 1;

    void finishRow(bool isAddedText) {
      var line = currentTextCell?.toString();
      if (isAddedLine) {
        rows.add('<tr><td class="line-no">(new)</td><td>$line</td></tr>');
      } else {
        rows.add('<tr><td class="line-no">$lineNumber</td>'
            '<td class="line-$lineNumber">$line</td></tr>');
        lineNumber++;
      }
      currentTextCell = StringBuffer();
      isAddedLine = isAddedText;
    }

    void writeSplitLines(
      String lines, {
      String perLineOpeningTag = '',
      String perLineClosingTag = '',
      bool isAddedText = false,
    }) {
      var lineIterator = LineSplitter.split(lines).iterator;
      lineIterator.moveNext();

      while (true) {
        currentTextCell.write(perLineOpeningTag);
        currentTextCell.write(_htmlEscape.convert(lineIterator.current));
        currentTextCell.write(perLineClosingTag);
        if (lineIterator.moveNext()) {
          // If we're not on the last element, end this row, and get ready to
          // start a new row.
          finishRow(isAddedText);
        } else {
          break;
        }
      }

      if (lines.endsWith('\n')) {
        finishRow(isAddedText);
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

    var previousOffset = 0;
    for (var region in unitInfo.regions) {
      var offset = region.offset;
      var length = region.length;
      if (offset > previousOffset) {
        // Display a region of unmodified content.
        writeSplitLines(content.substring(previousOffset, offset));
      }
      previousOffset = offset + length;
      var shouldBeShown = region.kind != null;
      var regionClass = classForRegion(region.regionType);
      var regionSpanTag = shouldBeShown
          ? '<span class="region $regionClass" '
              'data-offset="$offset" data-line="$lineNumber">'
          : '';
      writeSplitLines(content.substring(offset, offset + length),
          perLineOpeningTag: regionSpanTag,
          perLineClosingTag: shouldBeShown ? '</span>' : '',
          isAddedText: region.regionType == RegionType.add);
    }
    if (previousOffset < content.length) {
      // Last region of unmodified content.
      writeSplitLines(content.substring(previousOffset));
    }
    finishRow(false);
    return '<table data-path="${pathMapper.map(unit.path)}"><tbody>'
        '${rows.join()}</tbody></table>';
  }

  String _headerForKind(NullabilityFixKind kind, int count) {
    var s = count == 1 ? '' : 's';
    var es = count == 1 ? '' : 'es';
    switch (kind) {
      case NullabilityFixKind.addImport:
        return '$count import$s added';
      case NullabilityFixKind.addLate:
        return '$count late keyword$s added';
      case NullabilityFixKind.addLateDueToHint:
        return '$count late hint$s converted to late keyword$s';
      case NullabilityFixKind.addLateDueToTestSetup:
        return '$count late keyword$s added, due to assignment in `setUp`';
      case NullabilityFixKind.addLateFinalDueToHint:
        return '$count late final hint$s converted to late and final keywords';
      case NullabilityFixKind.addRequired:
        return '$count required keyword$s added';
      case NullabilityFixKind.addType:
        return '$count type$s added';
      case NullabilityFixKind.changeMethodName:
        return '$count method name$s changed';
      case NullabilityFixKind.downcastExpression:
        return '$count downcast$s added';
      case NullabilityFixKind.otherCastExpression:
        return '$count cast$s (non-downcast) added';
      case NullabilityFixKind.checkExpression:
        return '$count null check$s added';
      case NullabilityFixKind.checkExpressionDueToHint:
        return '$count null check hint$s converted to null check$s';
      case NullabilityFixKind.compoundAssignmentHasBadCombinedType:
        return '$count compound assignment$s could not be migrated (bad '
            'combined type)';
      case NullabilityFixKind.compoundAssignmentHasNullableSource:
        return '$count compound assignment$s could not be migrated (nullable '
            'source)';
      case NullabilityFixKind.conditionTrueInStrongMode:
        return '$count condition$s will be true in strong checking mode';
        break;
      case NullabilityFixKind.conditionFalseInStrongMode:
        return '$count condition$s will be false in strong checking mode';
        break;
      case NullabilityFixKind.makeTypeNullable:
        return '$count type$s made nullable';
      case NullabilityFixKind.makeTypeNullableDueToHint:
        return '$count nullability hint$s converted to ?$s';
      case NullabilityFixKind.noValidMigrationForNull:
        return '$count literal `null`$s could not be migrated';
      case NullabilityFixKind.nullAwarenessUnnecessaryInStrongMode:
        return '$count null-aware access$es will be unnecessary in strong '
            'checking mode';
      case NullabilityFixKind.nullAwareAssignmentUnnecessaryInStrongMode:
        return '$count null-aware assignment$s will be unnecessary in strong '
            'checking mode';
      case NullabilityFixKind.removeAs:
        return '$count cast$s now unnecessary';
      case NullabilityFixKind.removeDeadCode:
        return '$count dead code removal$s';
      case NullabilityFixKind.removeLanguageVersionComment:
        return '$count language version comment$s removed';
      case NullabilityFixKind.replaceVar:
        return "$count 'var' declaration$s replaced";
      case NullabilityFixKind.typeNotMadeNullable:
        return '$count type$s not made nullable';
      case NullabilityFixKind.typeNotMadeNullableDueToHint:
        return '$count type$s not made nullable due to hint$s';
    }
    throw StateError('Null kind');
  }

  /// Returns the URL that will navigate to the given [target] in the file at
  /// the given [relativePath].
  String _uriForPath(String path, NavigationTarget target) {
    var queryParams = {
      'offset': target.offset,
      if (target.line != null) 'line': target.line,
      'authToken': authToken,
    }.entries.map((entry) => '${entry.key}=${entry.value}').join('&');
    return '$path?$queryParams';
  }
}
