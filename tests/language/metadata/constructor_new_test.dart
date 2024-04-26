// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'constructor_new_test.dart' as self;

class Class {
  const Class();
}

class GenericClass<X, Y> {
  const GenericClass();
}

@Class.new()
@GenericClass.new()
@GenericClass<int, String>.new()
@self.Class.new()
@self.GenericClass.new()
@self.GenericClass<int, String>.new()
main() {}
