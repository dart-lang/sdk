// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Unresolved symbols should be reported as an error.
import "library12.dart" as lib12;

class Subclass
    extends lib12.Library13 //# 01: compile-time error
{}

class Implementer
    implements lib12.Library13 //# 02: compile-time error
{}

main() {
  new Subclass();
  new Implementer();
}
