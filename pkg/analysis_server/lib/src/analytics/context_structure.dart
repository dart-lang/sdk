// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/analytics/percentile_calculator.dart';

/// Data about the structure of the contexts being analyzed.
///
/// The descriptions of the fields below depend on the following terms.
///
/// An _immediate file_ is a file contained in an analysis root. This does not
/// include files that are explicitly excluded from analysis unless the excluded
/// files are referenced, directly or indirectly, from a non-excluded file.
///
/// A _transitive file_ is a file that is not an immediate file but is analyzed
/// because it is referenced, directly or indirectly, from an immediate file.
///
/// A single file can be both an immediate file in one analysis context and a
/// transitive file in one or more other analysis contexts.
///
/// The _number of lines_ in a file is just a basic line count, which includes
/// blank lines and lines containing only comments. It is not the number of
/// lines of code.
class ContextStructure {
  /// The number of analysis contexts being analyzed.
  final int numberOfContexts;

  /// The number of immediate files that were analyzed.
  final int immediateFileCount;

  /// The number of lines in the immediate files.
  final int immediateFileLineCount;

  /// The number of transitive files. If a single file is referenced from
  /// multiple analysis roots, it will be counted multiple times.
  final int transitiveFileCount;

  /// The number of lines in the same files that are included in the
  /// [transitiveFileCount].
  final int transitiveFileLineCount;

  /// The number of unique transitive files. If a single file is referenced from
  /// multiple analysis roots, it will be counted once.
  final int transitiveFileUniqueCount;

  /// The number of lines in the same files that are included in the
  /// [transitiveFileUniqueCount].
  final int transitiveFileUniqueLineCount;

  final PercentileCalculator libraryCycleLibraryCounts;
  final PercentileCalculator libraryCycleLineCounts;

  /// Initialize a newly created data holder.
  ContextStructure({
    required this.numberOfContexts,
    required this.immediateFileCount,
    required this.immediateFileLineCount,
    required this.transitiveFileCount,
    required this.transitiveFileLineCount,
    required this.transitiveFileUniqueCount,
    required this.transitiveFileUniqueLineCount,
    required List<int> libraryCycleLibraryCounts,
    required List<int> libraryCycleLineCounts,
  }) : libraryCycleLibraryCounts = PercentileCalculator.from(
         libraryCycleLibraryCounts,
       ),
       libraryCycleLineCounts = PercentileCalculator.from(
         libraryCycleLineCounts,
       );
}
