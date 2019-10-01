// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/edit/nnbd_migration/offset_mapper.dart';
import 'package:analyzer/src/generated/utilities_general.dart';

/// The migration information associated with a single library.
class LibraryInfo {
  /// The information about the units in the library. The information about the
  /// defining compilation unit is always first.
  final List<UnitInfo> units;

  /// Initialize a newly created library.
  LibraryInfo(this.units);
}

/// A location to which a user might want to navigate.
class NavigationTarget {
  /// The file containing the anchor.
  final String filePath;

  /// The offset of the anchor.
  final int offset;

  /// The length of the anchor.
  final int length;

  /// Initialize a newly created anchor.
  NavigationTarget(this.filePath, this.offset, this.length);

  @override
  int get hashCode => JenkinsSmiHash.hash3(filePath.hashCode, offset, length);

  @override
  bool operator ==(other) {
    return other is NavigationTarget &&
        other.filePath == filePath &&
        other.offset == offset &&
        other.length == length;
  }
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
  /// The offset to the beginning of the region.
  final int offset;

  /// The length of the region.
  final int length;

  /// The explanation to be displayed for the region.
  final String explanation;

  /// Details that further explain why a change was made.
  final List<RegionDetail> details;

  /// Initialize a newly created region.
  RegionInfo(this.offset, this.length, this.explanation, this.details);
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

  /// The navigation targets that are located in this file. The offsets in these
  /// targets are offsets into the pre-edit content.
  final Set<NavigationTarget> targets = {};

  /// The object used to map the pre-edit offsets in the navigation targets to
  /// the post-edit offsets in the [content].
  OffsetMapper offsetMapper = OffsetMapper.identity;

  /// Initialize a newly created unit.
  UnitInfo(this.path);
}
