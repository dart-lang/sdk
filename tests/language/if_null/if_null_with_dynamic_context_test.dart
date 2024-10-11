// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that if an if-null expression is analyzed in a `dynamic` context, the
// context for the RHS is taken from the static type of the LHS (see
// https://github.com/dart-lang/language/issues/3650).

import 'package:expect/static_type_helper.dart';

main() async {
  dynamic x =
      (null as List<int>?) ?? ([]..expectStaticType<Exactly<List<int>>>());
}
