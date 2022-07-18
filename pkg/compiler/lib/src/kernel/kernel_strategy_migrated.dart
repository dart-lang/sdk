// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Facades for kernel_strategy.dart.
// TODO(48820): Remove when frontend_strategy.dart is migrated.
library dart2js.kernel.frontend_strategy.facades;

import '../common.dart' show SourceSpan, Spannable;
import '../common/elements.dart' show KCommonElements;
import '../elements/entities.dart' show Entity;

/// Facade interface for KernelFrontendStrategy.
abstract class KernelFrontendStrategyForBackendUsage {
  KCommonElements get commonElements;
  SourceSpan spanFromSpannable(Spannable spannable, Entity currentElement);
}
