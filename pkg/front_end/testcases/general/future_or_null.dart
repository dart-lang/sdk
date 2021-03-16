// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

import 'dart:async';

// The test checks that the nullability of FutureOr<null> is `nullable` even in
// an opted-out library.

FutureOr<Null> get foo => null;

main() {}
