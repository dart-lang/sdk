// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  var pm;
  try {
    (pm as Person).firstName = 'Seth'; //LINT
  } on CastError { }

  Person person = pm;
  person.firstName = 'Seth';
}

class Person {
  var firstName;
}
