// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that the use of a raw generic type with non-simple bounds in
// a bound of a type variable is detected when that generic type comes from a
// compiled .dill file.
//
// Note that the type variable of LinkedListEntry has non-simple bound because
// it references itself.
// https://api.dartlang.org/stable/1.24.3/dart-collection/LinkedListEntry-class.html

import 'dart:collection';

class Hest<X extends LinkedListEntry> {}

main() {}
