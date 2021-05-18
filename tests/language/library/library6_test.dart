// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This tests that it is a compile-time error to both import a library
// that defines a function type alias and to have a local definition for
// another function type alias with the same name.
// This name conflict is considered an error even if Fun is never referred to.

library Library6NegativeTest.dart;

import "library5a.dart"; // Defines function type alias Fun

typedef int Fun(); // Does not conflict with definition of Fun from library5a

main() {}
