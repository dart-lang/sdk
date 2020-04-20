// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
class Superclass {
  foo({alpha, beta}) {}
  bar({beta, alpha}) {}

  namedCallback(callback({String alpha, int beta})) {
    callback(alpha: 'one', beta: 2);
    callback(beta: 1, alpha: 'two');
  }
}

class Subclass extends Superclass {
  foo({beta, alpha}) {}
  bar({alpha, beta}) {}

  namedCallback(callback({int beta, String alpha})) {}
}

topLevelNamed(beta, alpha, {gamma, delta}) {}
topLevelOptional(beta, alpha, [gamma, delta]) {}

main() {
  new Subclass().foo(beta: 1, alpha: 2);
  new Subclass().foo(alpha: 1, beta: 2);
  topLevelNamed(1, 2, gamma: 3, delta: 4);
  topLevelNamed(1, 2, delta: 3, gamma: 4);
}
