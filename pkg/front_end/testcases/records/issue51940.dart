// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef Parser<T> = (Result<T> result, String next) Function(String input);

sealed class Result<T> {
  const Result();
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Error<T> extends Result<T> {
  const Error(this.error);
  final String error;
}

Parser<void> not(Parser<dynamic> parser) {
  return (input) => switch (parser(input)) {
        (Ok _, var _) => (const Error('unexpected input'), input),
        _ => (const Ok(null), input),
      };
}
