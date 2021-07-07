// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `dart test -N avoid_returning_null`

/// See: https://github.com/dart-lang/linter/issues/2636

int? getFoo() => null; // OK
