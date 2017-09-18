// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library export1_lib;

export "dart:math" show LN10, LN2, E;

var E = "E"; // Hides constant E from math lib.
