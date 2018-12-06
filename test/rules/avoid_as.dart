// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N avoid_as`

main() {
  var pm;
  try {
    (pm as Person).firstName = 'Seth'; //LINT
  } on CastError {}

  Person person = pm;
  person.firstName = 'Seth';

  Person p = person as dynamic; //OK #195
}

class Person {
  var firstName;
}
