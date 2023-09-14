// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `dart test -N prefer_final_parameters`

void badRequiredPositional(String label) { // LINT
  print(label);
}

void goodRequiredPositional(final String label) { // OK
  print(label);
}

void badOptionalPosition([String? label]) { // LINT
  print(label);
}

void goodOptionalPosition([final String? label]) { // OK
  print(label);
}

void badRequiredNamed({required String label}) { // LINT
  print(label);
}

void goodRequiredNamed({required final String label}) { // OK
  print(label);
}

void badOptionalNamed({String? label}) { // LINT
  print(label);
}

void goodOptionalNamed({final String? label}) { // OK
  print(label);
}

void badExpression(int value) => print(value); // LINT

void goodExpression(final int value) => print(value); // OK

bool? _testingVariable;

void set badSet(bool setting) => _testingVariable = setting; // LINT

void set goodSet(final bool setting) => _testingVariable = setting; // OK

var badClosure = (Object random) { // LINT
  print(random);
};

var goodClosure = (final Object random) { // OK
  print(random);
};

var _testingList = [1, 7, 15, 20];

void useBadClosureArgument() {
  _testingList.forEach((element) => print(element + 4)); // LINT
}

void useGoodClosureArgument() {
  _testingList.forEach((final element) => print(element + 4)); // OK
}

void useGoodTypedClosureArgument() {
  _testingList.forEach((final int element) => print(element + 4)); // OK
}

void badMixedLast(String bad, final String good) { // LINT
  print(bad);
  print(good);
}

void badMixedFirst(final String goodFirst, String badSecond) { // LINT
  print(goodFirst);
  print(badSecond);
}

// LINT [+1]
void badMixedMiddle(String badFirst, final String goodSecond, String badThird) { // LINT
  print(badFirst);
  print(goodSecond);
  print(badThird);
}

void goodMultiple(final String bad, final String good) { // OK
  print(bad);
  print(good);
}

void mutableCase(String label) { // OK
  print(label);
  label = 'Lint away!';
  print(label);
}

void mutableExpression(int value) => value = 3; // OK

class C {
  String value = '';
  int _contents = 0;

  C(String content) { // LINT
    _contents = content.length;
  }

  C.bad(int contents): _contents = contents; // LINT

  C.good(final int contents): _contents = contents; // OK

  C.badValue(String value): this.value = value; // LINT

  C.goodValue(this.value); // OK

  factory C.goodFactory(final String value) { // OK
    return C(value);
  }

  factory C.badFactory(String value) { // LINT
    return C(value);
  }

  void set badContents(int contents) => _contents = contents; // LINT
  void set goodContents(final int contents) => _contents = contents; // OK

  int get contentValue => _contents + 4; // OK

  void badMethod(String bad) { // LINT
    print(bad);
  }

  void goodMethod(final String good) { // OK
    print(good);
  }

  @override
  C operator +(C other) { // LINT
    return C.good(contentValue + other.contentValue);
  }

  @override
  C operator -(final C other) { // OK
    return C.good(contentValue + other.contentValue);
  }
}

class InitializingFormals {
  final String initialize;

  InitializingFormals.okInitializingFormal(this.initialize); // OK

  InitializingFormals.okInitializingFormalNamed({required this.initialize}); // OK
}
