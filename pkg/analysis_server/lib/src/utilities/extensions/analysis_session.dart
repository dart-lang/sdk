// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/dartdoc/dartdoc_directive_info.dart';

extension AnalysisSessionExtension on AnalysisSession {
  /// The [DartdocDirectiveInfo] for the analysis context of this session.
  DartdocDirectiveInfo get dartdocDirectiveInfo =>
      (analysisContext as DriverBasedAnalysisContext)
          .driver
          .dartdocDirectiveInfo;
}
