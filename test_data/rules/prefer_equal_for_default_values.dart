// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `dart test -N prefer_equal_for_default_values`

// As of 2.19, this is a warning and the lint is a no-op.

f1({a: 1}) => null; // OK
f2({a = 1}) => null; // OK
f3([a = 1]) => null; // OK
f4([a]) => null; // OK
