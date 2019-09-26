// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  const NavigationTarget(this.filePath, this.offset, this.length);
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
  final String content;

  /// The information about the regions that have an explanation associated with
  /// them.
  final List<RegionInfo> regions;

  /// Initialize a newly created unit.
  UnitInfo(this.path, this.content, this.regions);
}
