// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'annotation_new.dart' as self;

const field = 1;

void method() {}

class Class {
  const Class();

  static const field = 1;

  static void method() {}
}

class GenericClass<X, Y> {
  const GenericClass();
}

@Class.new() // OK
@GenericClass.new() // OK
@GenericClass<int, String>.new() // OK
@self.Class.new() // OK
@self.GenericClass.new() // OK
@self.GenericClass<int, String>.new() // OK
@field // OK
@self.field // OK
@method // Error
@self.method // Error
@Class.field // OK
@Class.method // Error
@Class.new // Error
@self.Class.field // OK
@self.Class.method // Error
@self.Class.new // Error
main() {}
