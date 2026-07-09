// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dot shorthands are not enabled in versions before release.

// @dart=3.6

import 'dot_shorthand_helper.dart';

void main() {
  Color color = .blue;
  //            ^
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  // [cfe] This requires the experimental 'dot-shorthands' language feature to be enabled.
}
