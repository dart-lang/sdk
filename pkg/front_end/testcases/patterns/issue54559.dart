// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  String? fooValue = 'hello world';
  if (fooValue case final String fooValue) {
    print(fooValue);
  }
  if (fooValue case final String barValue && String fooValue) {
    print(barValue);
    print(fooValue);
  }
  print(switch (fooValue) {
    String fooValue => fooValue,
    _ => '',
  });
  switch (fooValue) {
    case String fooValue:
      print(fooValue);
  }
}
