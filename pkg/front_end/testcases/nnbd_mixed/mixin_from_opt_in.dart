// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

import 'mixin_from_opt_in_lib.dart';

class Class extends Object with Mixin {}

main() {
  print(new Class().method(null));
}
