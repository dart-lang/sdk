// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/edit/nnbd_migration/offset_mapper.dart';
import 'package:analyzer/src/generated/utilities_general.dart';

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

/// The migration information associated with a single library.
class LibraryInfo {
  /// The information about the units in the library. The information about the
  /// defining compilation unit is always first.
  final Set<UnitInfo> units;

  /// Initialize a newly created library.
  LibraryInfo(this.units);
}

/// A location from or to which a user might want to navigate.
abstract class NavigationRegion {
  /// The offset of the region.
  final int offset;

  /// The length of the region.
  final int length;

  /// Initialize a newly created link.
  NavigationRegion(this.offset, this.length);
}

/// A location from which a user might want to navigate.
class NavigationSource extends NavigationRegion {
  /// The target to which the user should be navigated.
  final NavigationTarget target;

  /// Initialize a newly created link.
  NavigationSource(int offset, int length, this.target) : super(offset, length);
}

/// A location to which a user might want to navigate.
class NavigationTarget extends NavigationRegion {
  /// The file containing the anchor.
  final String filePath;

  /// Initialize a newly created anchor.
  NavigationTarget(this.filePath, int offset, int length)
      : super(offset, length);

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

  /// The explanation to be displayed for the region.
  final String explanation;

  /// Details that further explain why a change was made.
  final List<RegionDetail> details;

  /// A list of the edits that are related to this range.
  List<EditDetail> edits;

  /// Initialize a newly created region.
  RegionInfo(
      this.regionType, this.offset, this.length, this.explanation, this.details,
      {this.edits});
}

/// Different types of regions that are called out.
enum RegionType {
  // TODO(brianwilkerson) 'fix' indicates whether the code was modified, while
  //  'nonNullableType' indicates why the code wasn't modified. It would be good
  //  to be consistent between the "whether" and "why" descriptions.
  /// This is a region of code that was fixed (changed) in migration.
  fix,

  /// This is a type that was declared non-nullable in migration.
  nonNullableType,
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
  List<RegionInfo> get fixRegions =>
      List.of(regions.where((region) => region.regionType == RegionType.fix));

  /// Returns the [regions] that represent an unchanged type which was
  /// determined to be non-null.
  List<RegionInfo> get nonNullableTypeRegions => List.of(regions
      .where((region) => region.regionType == RegionType.nonNullableType));
}
