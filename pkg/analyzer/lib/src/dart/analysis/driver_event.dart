// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';

/// An event that happened inside the [AnalysisDriver].
sealed class AnalysisDriverEvent {}

final class AnalyzeFile extends AnalysisDriverEvent {
  final FileState file;
  final LibraryFileKind library;

  AnalyzeFile({
    required this.file,
    required this.library,
  });
}

final class GetErrorsFromBytes extends AnalysisDriverEvent {
  final FileState file;
  final LibraryFileKind library;

  GetErrorsFromBytes({
    required this.file,
    required this.library,
  });
}
