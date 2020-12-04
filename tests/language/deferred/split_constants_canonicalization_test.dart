// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--use_bare_instructions=false
// VMOptions=--use_bare_instructions=true

import "package:expect/expect.dart";
import "split_constants_canonicalization_a.dart" deferred as a;
import "split_constants_canonicalization_b.dart" deferred as b;

class Box {
  final contents;
  const Box(this.contents);
}

enum Enum {
  RED,
  GREEN,
  BLUE,
}

commonClosure() {}

main() async {
  await a.loadLibrary();
  await a.loadChildren();
  await b.loadLibrary();
  await b.loadChildren();

  var a_1_mint = await a.a_1_mint();
  var a_2_mint = await a.a_2_mint();
  var b_1_mint = await b.b_1_mint();
  var b_2_mint = await b.b_2_mint();
  Expect.isTrue(identical(a_1_mint, a_2_mint));
  Expect.isTrue(identical(a_1_mint, b_1_mint));
  Expect.isTrue(identical(a_1_mint, b_2_mint));

  var a_1_string = await a.a_1_string();
  var a_2_string = await a.a_2_string();
  var b_1_string = await b.b_1_string();
  var b_2_string = await b.b_2_string();
  Expect.isTrue(identical(a_1_string, a_2_string));
  Expect.isTrue(identical(a_1_string, b_1_string));
  Expect.isTrue(identical(a_1_string, b_2_string));

  var a_1_list = await a.a_1_list();
  var a_2_list = await a.a_2_list();
  var b_1_list = await b.b_1_list();
  var b_2_list = await b.b_2_list();
  Expect.isTrue(identical(a_1_list, a_2_list));
  Expect.isTrue(identical(a_1_list, b_1_list));
  Expect.isTrue(identical(a_1_list, b_2_list));

  var a_1_map = await a.a_1_map();
  var a_2_map = await a.a_2_map();
  var b_1_map = await b.b_1_map();
  var b_2_map = await b.b_2_map();
  Expect.isTrue(identical(a_1_map, a_2_map));
  Expect.isTrue(identical(a_1_map, b_1_map));
  Expect.isTrue(identical(a_1_map, b_2_map));

  var a_1_box = await a.a_1_box();
  var a_2_box = await a.a_2_box();
  var b_1_box = await b.b_1_box();
  var b_2_box = await b.b_2_box();
  Expect.isTrue(identical(a_1_box, a_2_box));
  Expect.isTrue(identical(a_1_box, b_1_box));
  Expect.isTrue(identical(a_1_box, b_2_box));

  var a_1_enum = await a.a_1_enum();
  var a_2_enum = await a.a_2_enum();
  var b_1_enum = await b.b_1_enum();
  var b_2_enum = await b.b_2_enum();
  Expect.isTrue(identical(a_1_enum, a_2_enum));
  Expect.isTrue(identical(a_1_enum, b_1_enum));
  Expect.isTrue(identical(a_1_enum, b_2_enum));

  var a_1_type = await a.a_1_type();
  var a_2_type = await a.a_2_type();
  var b_1_type = await b.b_1_type();
  var b_2_type = await b.b_2_type();
  Expect.isTrue(identical(a_1_type, a_2_type));
  Expect.isTrue(identical(a_1_type, b_1_type));
  Expect.isTrue(identical(a_1_type, b_2_type));

  var a_1_closure = await a.a_1_closure();
  var a_2_closure = await a.a_2_closure();
  var b_1_closure = await b.b_1_closure();
  var b_2_closure = await b.b_2_closure();
  Expect.isTrue(identical(a_1_closure, a_2_closure));
  Expect.isTrue(identical(a_1_closure, b_1_closure));
  Expect.isTrue(identical(a_1_closure, b_2_closure));
}
