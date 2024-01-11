// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';

/// An event that happened inside the [AnalysisDriver].
sealed class AnalysisDriverEvent {}

final class ComputeAnalysis extends AnalysisDriverEvent {
  final FileState file;
  final LibraryFileKind library;

  ComputeAnalysis({
    required this.file,
    required this.library,
  });
}

final class ComputeResolvedLibrary extends AnalysisDriverEvent {
  final LibraryFileKind library;

  ComputeResolvedLibrary({
    required this.library,
  });
}
