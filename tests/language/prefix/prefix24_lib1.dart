// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library prefix24_lib1;

import "prefix24_lib2.dart" as X;

// lib1_foo() returns value of bar() in library prefix24_lib2.
lib1_foo() => X.bar();
