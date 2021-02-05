// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// From co19/Language/Types/Parameterized_Types/Actual_Type_of_Declaration/actual_type_t05.dart
import "package:expect/expect.dart";

class C<T> {
  List<T> f() => [];
}

main() {
  C c = new C();
  Expect.isTrue(c.f() is List<dynamic>);
}
