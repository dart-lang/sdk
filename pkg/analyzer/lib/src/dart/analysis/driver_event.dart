// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/library_graph.dart';
import 'package:analyzer/src/fine/requirement_failure.dart';
import 'package:analyzer/src/fine/requirements.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';

/// An event that happened inside the [AnalysisDriver].
sealed class AnalysisDriverEvent {}

/// The event after [library] analysis.
final class AnalyzedLibrary extends AnalysisDriverEvent {
  final LibraryFileKind library;
  final RequirementsManifest? requirements;

  AnalyzedLibrary({required this.library, required this.requirements});
}

/// The event that we wanted to analyze [file], so analyze [library].
final class AnalyzeFile extends AnalysisDriverEvent {
  final FileState file;
  final LibraryFileKind library;

  AnalyzeFile({required this.file, required this.library});
}

/// The event that we checked requirements of the library diagnostics.
/// This is much cheaper than computing the result again, but not free.
final class CheckLibraryDiagnosticsRequirements extends AnalysisDriverEvent {
  final LibraryFileKind library;
  final RequirementFailure? failure;

  CheckLibraryDiagnosticsRequirements({
    required this.library,
    required this.failure,
  });
}

/// The event that we checked requirements of the linked bundle.
/// This is much cheaper than relinking it, but not free.
final class CheckLinkedBundleRequirements extends AnalysisDriverEvent {
  final LibraryCycle cycle;
  final RequirementFailure? failure;

  CheckLinkedBundleRequirements({required this.cycle, required this.failure});
}

final class GetErrorsFromBytes extends AnalysisDriverEvent {
  final FileState file;
  final LibraryFileKind library;

  GetErrorsFromBytes({required this.file, required this.library});
}

/// The event that libraries for [cycle] were linked, and accumulated the
/// [requirements] to be checked if we try to reuse the summary bundle later.
final class LinkLibraryCycle extends AnalysisDriverEvent {
  final LinkedElementFactory elementFactory;
  final LibraryCycle cycle;
  final RequirementsManifest? requirements;

  LinkLibraryCycle({
    required this.elementFactory,
    required this.cycle,
    required this.requirements,
  });
}

/// The event that the existing summary bundle for [cycle] was reused.
final class ReuseLinkedBundle extends AnalysisDriverEvent {
  final LibraryCycle cycle;

  ReuseLinkedBundle({required this.cycle});
}
