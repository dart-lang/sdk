// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedOptions=--enable-experiment=macros

import 'package:json/json.dart';
import 'package:test/test.dart';

void main() {
  test('generates a toJson method', () {
    expect(
        A(5).toJson(),
        equals({
          'b': 5,
        }));
  });

  test('does not generate a fromJson constructor', () {
    expect(() => A.fromJson({'b': 5}), throwsA(isA<NoSuchMethodError>()));
  });
}

@JsonEncodable()
class A {
  final int b;

  A(this.b);

  /// This is just here to validate that it isn't actually created (the macro
  /// would throw). It also allows us to try and call it, expecting a runtime
  /// exception.
  external A.fromJson(Map<String, Object?> json);
}
