// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/target/targets.dart' show Target;

import 'compiler_context.dart' show CompilerContext;

/// Provides the implementation details used by a loader for a target.
abstract class TargetImplementation {
  CompilerContext get context;

  Target get backendTarget;
}
