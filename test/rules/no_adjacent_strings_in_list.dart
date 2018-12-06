// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N no_adjacent_strings_in_list`

void bad() {
  List<String> list = <String>[
    'a' // LINT
    'b',
    'c',
  ];

  List<String> list2 = <String>[
    'a' // LINT
    'b'
    'c'
  ];
}

void good() {
  List<String> list = <String>[
    'a' + // OK
    'b',
    'c',
  ];
}
