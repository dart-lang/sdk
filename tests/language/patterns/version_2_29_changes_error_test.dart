// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test captures the changes introduced in 2.29 of the patterns proposal.

import "package:expect/expect.dart";

main() {
  var map = {'a': 1, 'b': 2};

  // It's an error to have "..." in a map pattern.
  switch (map) {
    case {...}:
    //    ^^^
    // [analyzer] COMPILE_TIME_ERROR.REST_ELEMENT_IN_MAP_PATTERN
    // [cfe] The '...' pattern can't appear in map patterns.
    case {'a': _, ...}:
    // [error column 5, length 4]
    // [analyzer] STATIC_WARNING.UNREACHABLE_SWITCH_CASE
    //            ^^^
    // [analyzer] COMPILE_TIME_ERROR.REST_ELEMENT_IN_MAP_PATTERN
    // [cfe] The '...' pattern can't appear in map patterns.
  }

  // It's an error to have an empty map pattern.
  switch (map) {
    case {}:
    //   ^^
    // [analyzer] COMPILE_TIME_ERROR.EMPTY_MAP_PATTERN
    // [cfe] A map pattern must have at least one entry.
  }

  // Later cases may be unreachable because map patterns ignore extra keys.
  switch (map) {
    case {'a': _}:
      print('a');
    case {'b': _}:
      print('b');
    case {'a': _, 'b': _}:
      // [error column 5, length 4]
      // [analyzer] STATIC_WARNING.UNREACHABLE_SWITCH_CASE
      print('a b');
  }
}
