// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/target/targets.dart' show Target;

import 'macro_target_unsupported.dart'
    if (dart.library.io) 'macro_target_io.dart' as impl;

// Coverage-ignore(suite): Not run.
MacroConfiguration computeMacroConfiguration({Uri? targetSdkSummary}) =>
    impl.computeMacroConfiguration(targetSdkSummary: targetSdkSummary);

// Coverage-ignore(suite): Not run.
class MacroConfiguration {
  final Target target;
  final Uri? sdkSummary;

  MacroConfiguration({required this.target, required this.sdkSummary});
}
