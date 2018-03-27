// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N prefer_generic_function_type_aliases`

typedef void F1(); // LINT
typedef F2 = void Function(); // OK
