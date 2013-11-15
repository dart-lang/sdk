// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library path.test.utils;

import "package:unittest/unittest.dart";
import "package:path/path.dart" as path;

/// A matcher for a closure that throws a [path.PathException].
final throwsPathException = throwsA(new isInstanceOf<path.PathException>());
