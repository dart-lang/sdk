// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

Future<String?> getNull() async => null;

Future<bool> testAnd() async =>
    (await getNull()) != null && await Future<bool>.value(true);

Future<bool> testOr() async =>
    (await getNull()) == null || await Future<bool>.value(false);

void main() async {
  print(await testAnd());
  print(await testOr());
}
