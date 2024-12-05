// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Based on tests/language/getter/syntax_get_set_syntax_test.dart

var get; // OK
var get a; // Error
var get b, c; // Error
