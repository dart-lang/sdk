// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the basic StreamController and StreamController.singleSubscription.
library stream_join_test;

import 'dart:async';

import 'package:expect/expect.dart';
import 'package:unittest/unittest.dart';

import 'event_helper.dart';

main() {
  test("join-empty", () {
    StreamController c = new StreamController();
    c.stream.join("X").then(expectAsync((String s) => expect(s, equals(""))));
    c.close();
  });

  test("join-single", () {
    StreamController c = new StreamController();
    c.stream
        .join("X")
        .then(expectAsync((String s) => expect(s, equals("foo"))));
    c.add("foo");
    c.close();
  });

  test("join-three", () {
    StreamController c = new StreamController();
    c.stream
        .join("X")
        .then(expectAsync((String s) => expect(s, equals("fooXbarXbaz"))));
    c.add("foo");
    c.add("bar");
    c.add("baz");
    c.close();
  });

  test("join-three-non-string", () {
    StreamController c = new StreamController();
    c.stream
        .join("X")
        .then(expectAsync((String s) => expect(s, equals("fooXbarXbaz"))));
    c.add(new Foo("foo"));
    c.add(new Foo("bar"));
    c.add(new Foo("baz"));
    c.close();
  });

  test("join-error", () {
    StreamController c = new StreamController();
    c.stream
        .join("X")
        .catchError(expectAsync((String s) => expect(s, equals("BAD!"))));
    c.add(new Foo("foo"));
    c.add(new Foo("bar"));
    c.add(new Bad());
    c.add(new Foo("baz"));
    c.close();
  });
}

class Foo {
  String value;
  Foo(this.value);
  String toString() => value;
}

class Bad {
  Bad();
  String toString() => throw "BAD!";
}
