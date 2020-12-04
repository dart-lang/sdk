// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "split_constants_canonicalization_b_1.dart" deferred as b_1;
import "split_constants_canonicalization_b_2.dart" deferred as b_2;

loadChildren() async {
  await b_1.loadLibrary();
  await b_2.loadLibrary();
}

b_1_mint() => b_1.mint();
b_1_string() => b_1.string();
b_1_list() => b_1.list();
b_1_map() => b_1.map();
b_1_box() => b_1.box();
b_1_enum() => b_1.enumm();
b_1_type() => b_1.type();
b_1_closure() => b_1.closure();

b_2_mint() => b_2.mint();
b_2_string() => b_2.string();
b_2_list() => b_2.list();
b_2_map() => b_2.map();
b_2_box() => b_2.box();
b_2_enum() => b_2.enumm();
b_2_type() => b_2.type();
b_2_closure() => b_2.closure();
