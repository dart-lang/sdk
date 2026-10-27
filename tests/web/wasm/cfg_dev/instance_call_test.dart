// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Greeter {
  static String greeting() => 'Hello, world!';
  String message();
  void greet() => print(message());
}

class WorldGreeter extends Greeter {
  @override
  String message() => Greeter.greeting();
}

void main() => WorldGreeter().greet();
