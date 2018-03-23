// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N prefer_equal_for_default_values`

f1({a: 1}) => null; // LINT
f2({a = 1}) => null; // OK
f3([a = 1]) => null; // OK
f4([a]) => null; // OK
