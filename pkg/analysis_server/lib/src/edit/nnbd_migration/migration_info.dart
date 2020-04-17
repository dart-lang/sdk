// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/edit/nnbd_migration/offset_mapper.dart';
import 'package:analysis_server/src/edit/nnbd_migration/unit_link.dart';
import 'package:analysis_server/src/edit/preview/preview_site.dart';
import 'package:analyzer/src/generated/utilities_general.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';
import 'package:nnbd_migration/nnbd_migration.dart';
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

  /// Initializes a detail based on a [SourceEdit] object.
  factory EditDetail.fromSourceEdit(
          String description, SourceEdit sourceEdit) =>
      EditDetail(description, sourceEdit.offset, sourceEdit.length,
          sourceEdit.replacement);
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
    var links = <UnitLink>[];
    for (var unit in units) {
      var count = unit.fixRegions.length;
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
  String toString() => 'NavigationTarget["$filePath", $line, $offset, $length]';
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

  /// The kind of fix that was applied.
  final NullabilityFixKind kind;

  /// Indicates whether this region should be counted in the edit summary.
  final bool isCounted;

  /// A list of the edits that are related to this range.
  List<EditDetail> edits;

  /// A list of the nullability propagation traces that are related to this
  /// range.
  List<TraceInfo> traces;

  /// Initialize a newly created region.
  RegionInfo(this.regionType, this.offset, this.length, this.lineNumber,
      this.explanation, this.kind, this.isCounted,
      {this.edits = const [], this.traces = const []});
}

/// Different types of regions that are called out.
enum RegionType {
  /// This is a region of code that was added in migration.
  add,

  /// This is a region of code that was removed in migration.
  remove,

  /// This is a region of code that wasn't changed by migration, but is being
  /// shown to give the user more information about the migration.
  informative,
}

/// Information about a single entry in a nullability trace.
class TraceEntryInfo {
  /// Text description of the entry.
  final String description;

  /// Name of the enclosing function, or `null` if not known.
  String function;

  /// Source code location associated with the entry, or `null` if no source
  /// code location is known.
  final NavigationTarget target;

  TraceEntryInfo(this.description, this.function, this.target);
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

  /// Hash of the original contents of the unit.
  List<int> _diskContentHash;

  /// The preview content of unit.
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

  /// An offset mapper reflecting changes made by the migration edits.
  OffsetMapper migrationOffsetMapper = OffsetMapper.identity;

  /// An offset mapper reflecting changes made to disk since the migration was
  /// run, which can be rebased on [migrationOffsetMapper] to create and
  /// maintain an offset mapper from current disk state to migration result.
  OffsetMapper diskChangesOffsetMapper = OffsetMapper.identity;

  /// Initialize a newly created unit.
  UnitInfo(this.path);

  /// Set the original/disk content of this file to later use [hadDiskContent].
  /// This does not have a getter because it is backed by a private hash.
  set diskContent(String originalContent) {
    _diskContentHash = md5.convert((originalContent ?? '').codeUnits).bytes;
  }

  /// Returns the [regions] that represent a fixed (changed) region of code.
  List<RegionInfo> get fixRegions => regions
      .where((region) => region.regionType != RegionType.informative)
      .toList();

  /// Returns the [regions] that are informative.
  List<RegionInfo> get informativeRegions => regions
      .where((region) => region.regionType == RegionType.informative)
      .toList();

  /// The object used to map the pre-edit offsets in the navigation targets to
  /// the post-edit offsets in the [content].
  OffsetMapper get offsetMapper =>
      OffsetMapper.rebase(diskChangesOffsetMapper, migrationOffsetMapper);

  /// Check if this unit's file had expected disk contents [checkContent].
  bool hadDiskContent(String checkContent) {
    assert(_diskContentHash != null);
    return const ListEquality().equals(
        _diskContentHash, md5.convert((checkContent ?? '').codeUnits).bytes);
  }

  void handleInsertion(int offset, String replacement) {
    final contentCopy = content;
    final regionsCopy = List<RegionInfo>.from(regions);
    final length = replacement.length;
    offset = offsetMapper.map(offset);
    try {
      content = content.replaceRange(offset, offset, replacement);
      regions.clear();
      regions.addAll(regionsCopy.map((region) {
        if (region.offset < offset) {
          return region;
        }
        // TODO: adjust traces
        return RegionInfo(
            region.regionType,
            region.offset + length,
            region.length,
            region.lineNumber,
            region.explanation,
            region.kind,
            region.isCounted,
            edits: region.edits,
            traces: region.traces);
      }));

      diskChangesOffsetMapper = OffsetMapper.sequence(
          diskChangesOffsetMapper, OffsetMapper.forInsertion(offset, length));
    } catch (e) {
      regions.clear();
      regions.addAll(regionsCopy);
      content = contentCopy;
      rethrow;
    }
  }

  /// Returns the [RegionInfo] at offset [offset].
  // TODO(srawlins): This is O(n), used each time the user clicks on a region.
  //  Consider changing the type of [regions] to facilitate O(1) searching.
  RegionInfo regionAt(int offset) =>
      regions.firstWhere((region) => region.offset == offset);
}
