// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library has_part;

part 'the_part.dart';
part 'the_part_2.dart';

main() {
  Foo10 foo = new Foo10("Foo!");
  print(foo);
}
