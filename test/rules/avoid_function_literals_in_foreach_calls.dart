// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N avoid_function_literals_in_foreach_calls`

void main() {
  Iterable<String> people;

  for (var person in people) { // OK
    print(person);
  }
  people.forEach((person) { // LINT
    print(person);
  });

  people.forEach((person) => print(person)); // LINT

  people.forEach(print); // OK
}
