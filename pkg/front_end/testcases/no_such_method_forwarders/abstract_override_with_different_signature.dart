// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is a regression test for http://dartbug.com/40248.

class Cat {
  bool eatFood(String food) => true;
}

class MockCat implements Cat {
  dynamic noSuchMethod(Invocation invocation) {
    var arg = invocation.positionalArguments[0];
    return arg is String && arg.isNotEmpty;
  }
}

class MockCat2 extends MockCat {
  noSuchMethod(_);
}

class MockCat3 extends MockCat2 implements Cat {
  bool eatFood(String food, {double amount});
}

class MockCat4 extends MockCat2 implements HungryCat {}

abstract class HungryCat {
  bool eatFood(String food, {double amount, double yetAnother});
}

main() {}
