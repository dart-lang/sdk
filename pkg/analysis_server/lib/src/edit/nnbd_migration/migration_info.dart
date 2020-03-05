// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/edit/nnbd_migration/offset_mapper.dart';
import 'package:analysis_server/src/edit/nnbd_migration/unit_link.dart';
import 'package:analysis_server/src/edit/preview/preview_site.dart';
import 'package:analyzer/src/generated/utilities_general.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

/// A description of an edit that can be applied before rerunning the migration
/// in order to improve the migration results.
class EditDetail {
  /// A description of the edit that will be performed.
  final String description;

  /// The offset of the range to be replaced.
  final int offset;

  /// The length of the range to be replaced.
  final int length;

  /// The string with which the range will be replaced.
  final String replacement;

  /// Initialize a newly created detail.
  EditDetail(this.description, this.offset, this.length, this.replacement);
}

/// A class storing rendering information for an entire migration report.
///
/// This generally provides one [InstrumentationRenderer] (for one library)
/// with information about the rest of the libraries represented in the
/// instrumentation output.
class MigrationInfo {
  /// The information about the compilation units that are are migrated.
  final Set<UnitInfo> units;

  /// A map from file paths to the unit infos created for those files. The units
  /// in this map is a strict superset of the [units] that were migrated.
  final Map<String, UnitInfo> unitMap;

  /// The resource provider's path context.
  final path.Context pathContext;

  /// The filesystem root used to create relative paths for each unit.
  final String includedRoot;

  MigrationInfo(this.units, this.unitMap, this.pathContext, this.includedRoot);

  /// The path to the highlight.pack.js script, relative to [unitInfo].
  String get highlightJsPath => PreviewSite.highlightJsPath;

  /// The path to the highlight.pack.js stylesheet, relative to [unitInfo].
  String get highlightStylePath => PreviewSite.highlightCssPath;

  /// Return the path to [unit] from [includedRoot], to be used as a display
  /// name for a library.
  String computeName(UnitInfo unit) =>
      pathContext.relative(unit.path, from: includedRoot);

  List<UnitLink> unitLinks() {
    List<UnitLink> links = [];
    for (UnitInfo unit in units) {
      int count = unit.fixRegions.length;
      links.add(UnitLink(
          _pathTo(target: unit), pathContext.split(computeName(unit)), count));
    }
    return links;
  }

  /// The path to [target], as an HTTP URI path, using forward slash separators.
  String _pathTo({@required UnitInfo target}) =>
      '/' + pathContext.split(target.path).skip(1).join('/');
}

/// A location from or to which a user might want to navigate.
abstract class NavigationRegion {
  /// The offset of the region.
  final int offset;

  /// The line number of the region.
  final int line;

  /// The length of the region.
  final int length;

  /// Initialize a newly created link.
  NavigationRegion(int offset, this.line, this.length)
      : assert(offset >= 0),
        offset = offset < 0 ? 0 : offset;
}

/// A location from which a user might want to navigate.
class NavigationSource extends NavigationRegion {
  /// The target to which the user should be navigated.
  final NavigationTarget target;

  /// Initialize a newly created link.
  NavigationSource(int offset, int line, int length, this.target)
      : super(offset, line, length);
}

/// A location to which a user might want to navigate.
class NavigationTarget extends NavigationRegion {
  /// The file containing the anchor.
  final String filePath;

  /// Initialize a newly created anchor.
  NavigationTarget(this.filePath, int offset, int line, int length)
      : super(offset, line, length);

  @override
  int get hashCode => JenkinsSmiHash.hash3(filePath.hashCode, offset, length);

  @override
  bool operator ==(other) {
    return other is NavigationTarget &&
        other.filePath == filePath &&
        other.offset == offset &&
        other.length == length;
  }

  @override
  String toString() => 'NavigationTarget["$filePath", $offset, $length]';
}

/// An additional detail related to a region.
class RegionDetail {
  /// A textual description of the detail.
  final String description;

  /// The location associated with the detail, such as the location of an
  /// argument that's assigned to a parameter.
  final NavigationTarget target;

  /// Initialize a newly created detail.
  RegionDetail(this.description, this.target);
}

/// A description of an explanation associated with a region of code that was
/// modified.
class RegionInfo {
  /// Type type of region.
  final RegionType regionType;

  /// The offset to the beginning of the region.
  final int offset;

  /// The length of the region.
  final int length;

  /// The line number of the beginning of the region.
  final int lineNumber;

  /// The explanation to be displayed for the region.
  final String explanation;

  /// Details that further explain why a change was made.
  final List<RegionDetail> details;

  /// A list of the edits that are related to this range.
  List<EditDetail> edits;

  /// A list of the nullability propagation traces that are related to this
  /// range.
  List<TraceInfo> traces;

  /// Initialize a newly created region.
  RegionInfo(this.regionType, this.offset, this.length, this.lineNumber,
      this.explanation, this.details,
      {this.edits = const [], this.traces = const []});
}

/// Different types of regions that are called out.
enum RegionType {
  /// This is a region of code that was added in migration.
  add,

  /// This is a region of code that was removed in migration.
  remove,

  /// This is a region of code that was unchanged in migration; likely a type
  /// that was declared non-nullable in migration.
  unchanged,
}

/// Information about a single entry in a nullability trace.
class TraceEntryInfo {
  /// Text description of the entry.
  final String description;

  /// Source code location associated with the entry, or `null` if no source
  /// code location is known.
  final NavigationTarget target;

  TraceEntryInfo(this.description, this.target);
}

/// Information about a nullability trace.
class TraceInfo {
  /// Text description of the trace.
  final String description;

  /// List of trace entries.
  final List<TraceEntryInfo> entries;

  TraceInfo(this.description, this.entries);
}

/// The migration information associated with a single compilation unit.
class UnitInfo {
  /// The absolute and normalized path of the unit.
  final String path;

  /// The content of unit.
  String content;

  /// The information about the regions that have an explanation associated with
  /// them. The offsets in these regions are offsets into the post-edit content.
  final List<RegionInfo> regions = [];

  /// The navigation sources that are located in this file. The offsets in these
  /// sources are offsets into the pre-edit content.
  List<NavigationSource> sources;

  /// The navigation targets that are located in this file. The offsets in these
  /// targets are offsets into the pre-edit content.
  final Set<NavigationTarget> targets = {};

  /// The object used to map the pre-edit offsets in the navigation targets to
  /// the post-edit offsets in the [content].
  OffsetMapper offsetMapper = OffsetMapper.identity;

  /// Initialize a newly created unit.
  UnitInfo(this.path);

  /// Returns the [regions] that represent a fixed (changed) region of code.
  List<RegionInfo> get fixRegions => List.of(
      regions.where((region) => region.regionType != RegionType.unchanged));

  /// Returns the [regions] that represent an unchanged type which was
  /// determined to be non-null.
  List<RegionInfo> get nonNullableTypeRegions => List.of(
      regions.where((region) => region.regionType == RegionType.unchanged));

  /// Returns the [RegionInfo] at offset [offset].
  // TODO(srawlins): This is O(n), used each time the user clicks on a region.
  //  Consider changing the type of [regions] to facilitate O(1) searching.
  RegionInfo regionAt(int offset) =>
      regions.firstWhere((region) => region.offset == offset);
}
