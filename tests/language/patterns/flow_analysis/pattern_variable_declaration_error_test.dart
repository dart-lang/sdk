// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/static_type_helper.dart";

test() {
  {
    // A pattern variable declaration does not promote its initializer
    // expression.
    var x = expr<num>();
    var (_ as int) = x;
    x.expectStaticType<Exactly<num>>();
  }
}

T expr<T>() => throw UnimplementedError();

main() {}
