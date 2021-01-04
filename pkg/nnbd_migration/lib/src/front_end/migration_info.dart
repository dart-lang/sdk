// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/utilities_general.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:nnbd_migration/instrumentation.dart';
import 'package:nnbd_migration/nnbd_migration.dart';
import 'package:nnbd_migration/src/front_end/offset_mapper.dart';
import 'package:nnbd_migration/src/front_end/unit_link.dart';
import 'package:nnbd_migration/src/front_end/web/navigation_tree.dart';
import 'package:nnbd_migration/src/preview/preview_site.dart';
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

/// Everything the front end needs to know to tell the server to perform a hint
/// action.
class HintAction {
  final HintActionKind kind;
  final int nodeId;
  HintAction(this.kind, this.nodeId);

  HintAction.fromJson(Map<String, Object> json)
      : nodeId = json['nodeId'] as int,
        kind = HintActionKind.values
            .singleWhere((action) => action.index == json['kind']);

  Map<String, Object> toJson() => {
        'nodeId': nodeId,
        'kind': kind.index,
      };
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

  /// The path of the Dart logo displayed in the toolbar.
  String get dartLogoPath => PreviewSite.dartLogoPath;

  /// The path to the highlight.pack.js script, relative to [unitInfo].
  String get highlightJsPath => PreviewSite.highlightJsPath;

  /// The path to the highlight.pack.js stylesheet, relative to [unitInfo].
  String get highlightStylePath => PreviewSite.highlightCssPath;

  /// The path of the Material icons font.
  String get materialIconsPath => PreviewSite.materialIconsPath;

  /// The path of the Roboto font.
  String get robotoFont => PreviewSite.robotoFontPath;

  /// The path of the Roboto Mono font.
  String get robotoMonoFont => PreviewSite.robotoMonoFontPath;

  /// Returns the absolute path of [path], as relative to [includedRoot].
  String absolutePathFromRoot(String path) =>
      pathContext.join(includedRoot, path);

  /// Returns the relative path of [path] from [includedRoot].
  String relativePathFromRoot(String path) =>
      pathContext.relative(path, from: includedRoot);

  /// Return the path to [unit] from [includedRoot], to be used as a display
  /// name for a library.
  String computeName(UnitInfo unit) => relativePathFromRoot(unit.path);

  List<UnitLink> unitLinks() {
    var links = <UnitLink>[];
    for (var unit in units) {
      var count = unit.fixRegions.length;
      links.add(UnitLink(unit.path, pathContext.split(computeName(unit)), count,
          unit.wasExplicitlyOptedOut, unit.migrationStatus));
    }
    return links;
  }
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
  bool operator ==(Object other) {
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
  ///
  /// `null` if this region doesn't represent a fix (e.g. it's just whitespace
  /// change to preserve formatting).
  final String explanation;

  /// The kind of fix that was applied.
  ///
  /// `null` if this region doesn't represent a fix (e.g. it's just whitespace
  /// change to preserve formatting).
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

  /// The hint actions available on this trace entry, or `[]` if none.
  final List<HintAction> hintActions;

  TraceEntryInfo(this.description, this.function, this.target,
      {this.hintActions = const []})
      : assert(hintActions != null);
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

  /// Whether this compilation unit was explicitly opted out of null safety at
  /// the start of this migration.
  bool wasExplicitlyOptedOut;

  /// Indicates the migration status of this unit.
  ///
  /// After all migration phases have completed, this indicates that a file was
  /// already migrated, or is being migrated during this migration.
  ///
  /// A user can change this migration status from the preview interface:
  /// * An already migrated unit cannot be changed.
  /// * During an initial migration, in which a package is migrated to null
  ///   safety, the user can toggle a file's migration status between
  ///   "migrating" and "opting out."
  /// * During a follow-up migration, in which a package has been migrated to
  ///   null safety, but some files have been opted out, the user can toggle a
  ///   file's migration status between "migrating" and "keeping opted out."
  UnitMigrationStatus migrationStatus;

  /// Initialize a newly created unit.
  UnitInfo(this.path);

  /// Set the original/disk content of this file to later use [hadDiskContent].
  /// This does not have a getter because it is backed by a private hash.
  set diskContent(String originalContent) {
    _diskContentHash = md5.convert((originalContent ?? '').codeUnits).bytes;
  }

  /// Returns the [regions] that represent a fixed (changed) region of code.
  List<RegionInfo> get fixRegions => regions
      .where((region) =>
          region.regionType != RegionType.informative && region.kind != null)
      .toList();

  /// Returns the [regions] that are informative.
  List<RegionInfo> get informativeRegions => regions
      .where((region) =>
          region.regionType == RegionType.informative && region.kind != null)
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

  void handleSourceEdit(SourceEdit sourceEdit) {
    final contentCopy = content;
    final regionsCopy = List<RegionInfo>.from(regions);
    final insertLength = sourceEdit.replacement.length;
    final deleteLength = sourceEdit.length;
    final migratedOffset = offsetMapper.map(sourceEdit.offset);
    final diskOffset = diskChangesOffsetMapper.map(sourceEdit.offset);
    if (migratedOffset == null || diskOffset == null) {
      throw StateError('cannot apply replacement, offset has been deleted.');
    }
    try {
      content = content.replaceRange(migratedOffset,
          migratedOffset + deleteLength, sourceEdit.replacement);
      regions.clear();
      regions.addAll(regionsCopy
          .where((region) => region.offset + region.length <= migratedOffset));
      regions.addAll(regionsCopy
          .where((region) => region.offset >= migratedOffset + deleteLength)
          .map((region) => RegionInfo(
              region.regionType,
              // TODO: perhaps this should be handled by offset mapper instead,
              // since offset mapper handles navigation, edits, and traces, and
              // this is the odd ball out.
              region.offset + insertLength - deleteLength,
              region.length,
              region.lineNumber,
              region.explanation,
              region.kind,
              region.isCounted,
              edits: region.edits,
              traces: region.traces)));

      diskChangesOffsetMapper = OffsetMapper.sequence(
          diskChangesOffsetMapper,
          OffsetMapper.forReplacement(
              diskOffset, deleteLength, sourceEdit.replacement));
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
  RegionInfo regionAt(int offset) => regions
      .firstWhere((region) => region.kind != null && region.offset == offset);
}
