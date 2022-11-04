// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../js_model/js_world.dart';
import '../universe/world_builder.dart' show SelectorConstraintsStrategy;
import 'abstract_value_domain.dart';

/// Strategy for the abstraction of runtime values used by the global type
/// inference.
abstract class AbstractValueStrategy {
  /// Creates the abstract value domain for [closedWorld].
  AbstractValueDomain createDomain(covariant JClosedWorld closedWorld);

  /// Creates the [SelectorConstraintsStrategy] used by the backend enqueuer.
  SelectorConstraintsStrategy createSelectorStrategy();
}
