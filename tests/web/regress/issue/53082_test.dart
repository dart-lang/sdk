// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

Future<void> main() async {
  try {
    await Future(() => throw Exception("async exception"));
  } catch (error) {
    print("Caught async exception: $error");
    try {
      throw 'foo';
    } on String catch (error) {
      print('Caught foo: $error');
    }
  }
}
