// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `dart test -N avoid_final_parameters`

void badRequiredPositional(final String label) { // LINT
  print(label);
}

void goodRequiredPositional(String label) { // OK
  print(label);
}

void badOptionalPosition([final String? label]) { // LINT
  print(label);
}

void goodOptionalPosition([String? label]) { // OK
  print(label);
}

void badRequiredNamed({required final String label}) { // LINT
  print(label);
}

void goodRequiredNamed({required String label}) { // OK
  print(label);
}

void badOptionalNamed({final String? label}) { // LINT
  print(label);
}

void goodOptionalNamed({String? label}) { // OK
  print(label);
}

void badExpression(final int value) => print(value); // LINT

void goodExpression(int value) => print(value); // OK

bool? _testingVariable;

void set badSet(final bool setting) => _testingVariable = setting; // LINT

void set goodSet(bool setting) => _testingVariable = setting; // OK

var badClosure = (final Object random) { // LINT
  print(random);
};

var goodClosure = (Object random) { // OK
  print(random);
};

var _testingList = [1, 7, 15, 20];

void useBadClosureArgument() {
  _testingList.forEach((final element) => print(element + 4)); // LINT
}

void useGoodClosureArgument() {
  _testingList.forEach((element) => print(element + 4)); // OK
}

void useGoodTypedClosureArgument() {
  _testingList.forEach((int element) => print(element + 4)); // OK
}

void badMixedLast(final String bad, String good) { // LINT
  print(bad);
  print(good);
}

void badMixedFirst(String goodFirst, final String badSecond) { // LINT
  print(goodFirst);
  print(badSecond);
}

// LINT [+1]
void badMixedMiddle(final String badFirst, String goodSecond, final String badThird) { // LINT
  print(badFirst);
  print(goodSecond);
  print(badThird);
}

void goodMultiple(String bad, String good) { // OK
  print(bad);
  print(good);
}

class C {
  String value = '';
  int _contents = 0;

  C(final String content) { // LINT
    _contents = content.length;
  }

  C.bad(final int contents) : _contents = contents; // LINT

  C.good(int contents) : _contents = contents; // OK

  C.badValue(final String value) : this.value = value; // LINT

  C.goodValue(this.value); // OK

  factory C.goodFactory(String value) { // OK
    return C(value);
  }

  factory C.badFactory(final String value) { // LINT
    return C(value);
  }

  void set badContents(final int contents) => _contents = contents; // LINT
  void set goodContents(int contents) => _contents = contents; // OK

  int get contentValue => _contents + 4; // OK

  void badMethod(final String bad) { // LINT
    print(bad);
  }

  void goodMethod(String good) { // OK
    print(good);
  }

  @override
  C operator +(final C other) { // LINT
    return C.good(contentValue + other.contentValue);
  }

  @override
  C operator -(C other) { // OK
    return C.good(contentValue + other.contentValue);
  }
}
