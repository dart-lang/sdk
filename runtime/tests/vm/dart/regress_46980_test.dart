// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--deterministic

// The Dart Project Fuzz Tester (1.91).
// Program generated as:
//   dart dartfuzz.dart --seed 929450448 --no-fp --no-ffi --no-flat

import 'dart:collection';
import 'dart:typed_data';

MapEntry<List<int>, Map<String, String>>? var0 =
    MapEntry<List<int>, Map<String, String>>(
        Uint16List.fromList(<int>[-25]), <String, String>{
  '': 'p8',
  'VGiZ+x': 'n6\u{1f600}',
  'j': 'hrNI',
  '3@kX)\u{1f600}': 'TW+Z',
  'D': '\u2665Yqu',
  'wzBa\u{1f600}h': '-k'
});
num? var78 = 29;
MapEntry<String, int> var141 = MapEntry<String, int>('\u{1f600}', 16);

MapEntry<Map<bool, int>, MapEntry<bool, int>>? var2896 =
    MapEntry<Map<bool, int>, MapEntry<bool, int>>(<bool, int>{
  true: -79,
  false: 13,
  true: 35,
  true: -84,
  false: -9223372034707292159
}, MapEntry<bool, int>(true, 0));

main() {
  for (var i = 0; i < 1848; i++) {
    print(var2896);
  }

  print('$var0\n$var78\n$var141\n');
}
