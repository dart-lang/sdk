// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  final int a;

  A(this.a);
}

Future<int> invoke() async {
  A myA;

  try {
    myA = await A(3);
  } on ArgumentError catch (e) {
    final myA = e.message as String;
    throw Exception('Catch throw: $myA');
  }

  return myA.a;
}

void main() async {
  print(await invoke());
}
