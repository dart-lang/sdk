// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

/// Provides context information for [FixContributor]s.
///
/// Clients may not extend, implement or mix-in this class.
abstract interface class FixContext {
  /// The error to fix.
  AnalysisError get error;
}
