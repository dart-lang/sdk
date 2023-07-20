// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

void main() {
  final validator = createValidator([
    (validate: isNotEmpty, message: 'Value is required'),
  ]);
  Expect.isEmpty(validator('foo'));
  Expect.isNotEmpty(validator(null));
}

typedef FieldValidator<T> = List<String> Function(T? value);
typedef Validator<T> = bool Function(T? value);
FieldValidator<T> createValidator<T>(
        List<({Validator<T> validate, String message})> validators) =>
    (T? value) {
      return validators
          .where((validator) => !validator.validate(value))
          .map((validator) => validator.message)
          .toList();
    };

bool isNotEmpty(String? value) => value != null && value.isNotEmpty;
