// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'main_lib.dart';

typedef F<X> = E<X, X>;

extension type E<X, Y>(String s) {}

void main() {
  var f1 = F('');
  F<int> f2 = F('');
  F<int> f3 = E('');
  F<int>('');
  F('');

  var h1 = H('');
  H<int> h2 = H('');
  H<int> h3 = G('');
  H<int>('');
  H('');
}