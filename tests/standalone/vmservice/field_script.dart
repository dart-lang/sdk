// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unknown_command_script;

import 'dart:io';
import 'dart:typed_data';

class Banana {
  final Float32List final_fixed_length_list = new Float32List(4);
  Float32List fixed_length_list = new Float32List(4);
  String name = '';
  var a = 44;
}


class BadBanana {
  final Float32List final_fixed_length_list;
  final List fixed_length_array = new List(3);
  num v;
  const c = 4;
  BadBanana() : final_fixed_length_list = new Float32List(1);
  BadBanana.variable() : final_fixed_length_list = new Float32List(2);
}

main() {
  for (int i = 0; i < 2000; i++) {
    Banana b = new Banana();
    b.name = 'Banana';
    BadBanana bb = new BadBanana();
    bb.v = 1.0;
  }
  var bb = new BadBanana.variable();
  bb.v = 2.0;
  var b = new Banana();
  b.a = 'foo';
  print(''); // Print blank line to signal that we are ready.
  // Wait until signaled from spawning test.
  stdin.first.then((_) => exit(0));
}
