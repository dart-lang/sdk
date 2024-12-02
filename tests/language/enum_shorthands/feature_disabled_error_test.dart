// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Enum shorthands are not enabled in versions before release.

// @dart=3.6

import 'enum_shorthand_helper.dart';

void main() {
  Color color = .blue;
  //            ^
  // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
  // [cfe] Expected an identifier, but got '.'.
}
