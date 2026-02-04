// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'shadowed_prefix_part1.dart';

import 'shadowed_prefix_lib3.dart' as prefix;

method3() {
  prefix.x1; // Error
  prefix.x3; // Ok
}