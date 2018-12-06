// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N avoid_types_on_closure_parameters`

class Person {
  String name;
}

List<Person> people;

var goodName1 = people.map((person) => person.name); // OK
var badName1 = people.map((Person person) => person.name); // LINT

var goodName2 = ({person}) => person.name; // OK
var badName2 = ({Person person}) => person.name; // LINT

var goodName3 = ({person : ""}) => person; // OK
var badName3 = ([String person = ""]) => person; // LINT

var goodName4 = ([person]) => person.name; // OK
var badName4 = ([Person person]) => person.name; // LINT

var goodName5 = (dynamic person) => person.name; // OK

var functionWithFunction = (int f(int x)) => f(0); // LINT
