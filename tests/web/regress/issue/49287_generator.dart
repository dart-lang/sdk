// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  List<String> strings = [];
  String line = '';
  for (int i = 0x10000; i < 0x3F000; i++) {
    line += '\\u{${i.toRadixString(16)}}';
    // This prime-number based occasional insertion of simple character is to
    // prevent all the surrogate pairs having the same alignment.
    if (i % 19 == 0) line += 'X';
    if (i % 301 == 0) {
      strings.add("'$line'");
      line = '';
    }
  }

  // The generated code has two lists of the same strings so that the strings
  // are pushed into the string pool where they are printed one per line. This
  // is easier to understand than a diff in a single megabyte-sized line.

  print("""
// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// GENERATED CODE.
//
// To regenerate this file, run
//
//    dart 49287_generator.dart > 49287_data.dart
//

String get bigString => a1.join() + a2.join();

var a1 = [
  ${strings.join(',\n  ')}
];

var a2 = [
  ${strings.reversed.join(',\n  ')}
];
""");
}
