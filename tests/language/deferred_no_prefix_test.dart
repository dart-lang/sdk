// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Loading a deferred library without prefix is not allowed.
import "deferred_constraints_lib2.dart"
  deferred //# 01: compile-time error
    ;

void main() {}
