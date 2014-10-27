// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart._internal;

import 'dart:collection';

import 'dart:core' hide Symbol;
import 'dart:core' as core;
import 'dart:math' show Random;

part 'iterable.dart';
part 'list.dart';
part 'lists.dart';
part 'print.dart';
part 'sort.dart';
part 'symbol.dart';

// Powers of 10 up to 10^22 are representable as doubles.
// Powers of 10 above that are only approximate due to lack of precission.
// Used by double-parsing.
const POWERS_OF_TEN = const [
                        1.0,  /*  0 */
                       10.0,
                      100.0,
                     1000.0,
                    10000.0,
                   100000.0,  /*  5 */
                  1000000.0,
                 10000000.0,
                100000000.0,
               1000000000.0,
              10000000000.0,  /* 10 */
             100000000000.0,
            1000000000000.0,
           10000000000000.0,
          100000000000000.0,
         1000000000000000.0,  /*  15 */
        10000000000000000.0,
       100000000000000000.0,
      1000000000000000000.0,
     10000000000000000000.0,
    100000000000000000000.0,  /*  20 */
   1000000000000000000000.0,
  10000000000000000000000.0,
];
