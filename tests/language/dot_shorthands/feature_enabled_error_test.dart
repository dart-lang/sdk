// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dot shorthands are enabled by default. This should be an error as it's not
// currently enabled by default.

import 'dot_shorthand_helper.dart';

void main() {
  Color color = .blue;
  //            ^
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  // [cfe] This requires the experimental 'dot-shorthands' language feature to be enabled.
}
