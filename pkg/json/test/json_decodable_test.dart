// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedOptions=--enable-experiment=macros

import 'package:json/json.dart';
import 'package:test/test.dart';

void main() {
  test('generates a fromJson constructor', () {
    expect(A.fromJson({'b': 5, r'$b': 5}),
        predicate<A>((a) => a.b == 5 && a.$b == 5));
  });

  test('does not generate a toJson method', () {
    expect(() => (A(5) as dynamic).toJson(), throwsA(isA<NoSuchMethodError>()));
  });
}

@JsonDecodable()
class A {
  final int b;
  int? $b;

  A(this.b);
}
