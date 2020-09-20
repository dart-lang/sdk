// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import './opt_out_lib.dart';

foo(dynamic d, void v, Object? onull, Object o, String? snull, String s) {
  f(d);
  f(v);
  f(onull);
  f(o);
  f(snull);
  f(s);
}

main() {}
