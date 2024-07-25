// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const int? expr1 = 5;
const List<int> literal1 = <int>[?expr1];

const String? expr2 = null;
const Set<String> literal2 = <String>{?expr2};

class Verifier {
  const Verifier.test1() : assert(identical(literal1, const <int>[5]));

  const Verifier.test2() : assert(identical(literal2, const <String>{}));
}

Verifier test1 = const Verifier.test1();
Verifier test2 = const Verifier.test2();
