// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'main_lib.dart';

test() {
  const a = C.new;
  const b = D.new;
  var m = const {C.new: true, D.new: false};
  var n = const {c: true, d: false};
}
