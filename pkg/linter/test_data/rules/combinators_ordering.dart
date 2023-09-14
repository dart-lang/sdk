// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `dart test -N combinators_ordering`

import 'dart:math' as m1 show max, min; // OK
import 'dart:math' as m2 show min, max; // LINT

export 'dart:math' show max, min; // OK
export 'dart:math' show min, max; // LINT

import 'dart:math' as m3 hide max, min; // OK
import 'dart:math' as m4 hide min, max; // LINT

export 'dart:math' hide max, min; // OK
export 'dart:math' hide min, max; // LINT
