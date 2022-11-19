// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/50392

void main(List<String> arguments) {
  final model = Model();

  print(model.value); // null
  print(model.value == null); // true
}

class Model<T extends num> {
  final T? value;

  Model._(this.value);

  factory Model() {
    Object? value = (int.parse('1') == 1) ? null : 42;
    return Model._(value as T?);
  }
}
