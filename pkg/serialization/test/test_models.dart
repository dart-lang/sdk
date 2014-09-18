// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Provides some basic model classes to test serialization. */

part of serialization_test;

class Person {
  String name, rank, serialNumber;
  var address;
}

class Address {
  String street, city, state, zip;
  Address();
  Address.withData(this.street, this.city, this.state, this.zip);
}

class Various {
  Various.Foo(this._d, this.e);

  // Field
  var a;

  // Get/Set pair
  var _b;
  get b => _b;
  set b(value) { _b = value; }

  // Private field (shouldn't be visible)
  var _c = 'default value';

  // Getter, value is set in the constructor
  var _d;
  get d => _d;

  // Final, value set is the constructor.
  final e;

  // Get without corresponding set
  get aLength => a.length;

  static String thisShouldBeIgnored = "because it's static";
  static get thisShouldAlsoBeIgnored => "for the same reason";
  static set thisShouldAlsoBeIgnored(x) {}
}

class Node {
  Node parent;
  String name;
  Node(this.name);
  Node.parentEssential(this.parent);
  List<Node> children;
  bool someBoolean = true;

  toString() => "Node($name)";
}

class NodeEqualByName extends Node {
  NodeEqualByName(name) : super(name);
  operator ==(x) => x is NodeEqualByName && name == x.name;
  get hashCode => name.hashCode;
}

class Stream {
  // In a real stream the position wouldn't likely be settable, making
  // this trickier to reconstruct.
  List _collection;
  int position = 0;
  Stream(this._collection);

  next() => atEnd() ? null : _collection[position++];
  atEnd() => position >= _collection.length;
}