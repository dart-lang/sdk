// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Issue 24043.

import "package:expect/expect.dart";

class EvilMatch implements Match {
  int get start => 100000000;
  int get end => 3;
  bool noSuchMethod(Invocation im) => false; // To appease dartanalyzer.
}

class EvilIterator implements Iterator {
  bool moveNext() => true;
  EvilMatch get current => new EvilMatch();
}

class EvilIterable extends Iterable {
  Iterator get iterator => new EvilIterator();
}

class EvilPattern implements Pattern {
  Iterable allMatches(String s, [int start = 0]) => new EvilIterable();
  bool noSuchMethod(Invocation im) => false; // To appease dartanalyzer.
}

void main() {
  Expect.throwsRangeError(() => "foo".split(new EvilPattern())[0].length);
}
