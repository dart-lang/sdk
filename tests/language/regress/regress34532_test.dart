// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Foo<T> {}

class Bar<T extends Foo<T>> {}

// Should be error here, because Bar completes to Bar<Foo>
class Baz extends Bar {}
//                ^^^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
// [cfe] Inferred type argument 'Foo<dynamic>' doesn't conform to the bound 'Foo<T>' of the type variable 'T' on 'Bar'.

void main() {}
