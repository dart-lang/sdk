// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';

/// A list of the experiments that are to be enabled for tests.
///
/// The list will be empty if there are no experiments that should be enabled.
///
/// Experiments should be added to this list when work on a new experiment
/// begins. Experiments should be removed from this list when they are marked
/// as being enable by default.
///
/// The flags in the list are kept in alphabetic order for ease of determining
/// whether a given flag is already included.
List<String> experimentsForTests = [
  Feature.augmentations.enableString,
  Feature.digit_separators.enableString,
  Feature.enhanced_parts.enableString,
  Feature.macros.enableString,
  Feature.null_aware_elements.enableString,
  Feature.wildcard_variables.enableString,
];
