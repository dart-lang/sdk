// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../experiments/flags.dart';

/// Interface for determining which features are enabled during parsing.
abstract class ExperimentalFeatures {
  bool isExperimentEnabled(ExperimentalFlag flag);
}

/// Implementation of [ExperimentalFeatures] that uses the enables the
/// experiments currently enabled by default.
///
/// This should only be used for testing. For actual parsing, the enabled
/// features should be determined by language version and enabled experiments.
class DefaultExperimentalFeatures implements ExperimentalFeatures {
  const DefaultExperimentalFeatures();

  @override
  bool isExperimentEnabled(ExperimentalFlag flag) => flag.isEnabledByDefault;
}
