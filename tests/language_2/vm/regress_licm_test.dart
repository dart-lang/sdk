// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--enable-inlining-annotations --optimization-counter-threshold=1000 --no-background-compilation

// Regression test for correct LICM and type propagation.

const AlwaysInline = "AlwaysInline";
const NeverInline = "NeverInline";

class Attribute {
  final id = 123;
}

abstract class Name {
  Name(this.name);
  final String name;
  get attr;

  @AlwaysInline
  int compareTo(other) {
    int nameCompare = name.compareTo(other.name);
    if (nameCompare != 0) return nameCompare;
    if (attr == null) return 0;
    return attr.id - other.attr.id;
  }
}

class AName extends Name {
  AName() : super("abc");
  final attr = new Attribute();
}

class BName extends Name {
  BName(name) : super(name);
  get attr => null;
}

class Member {
  Member(this.name);
  var name;
}

Member find(List<Member> members, Name name) {
  int low = 0, high = members.length - 1;
  while (low <= high) {
    int mid = low + ((high - low) >> 1);
    Member pivot = members[mid];
    int comparison = name.compareTo(pivot.name);
    if (comparison < 0) {
      high = mid - 1;
    } else if (comparison > 0) {
      low = mid + 1;
    } else {
      return pivot;
    }
  }
  return null;
}

main() {
  var list = [
    new Member(new AName()),
    new Member(new BName("a")),
    new Member(new BName("b")),
    new Member(new BName("c")),
    new Member(new BName("d"))
  ];

  find(list, new AName());
  find(list, new BName("e"));
  find(list, new BName("b"));
  for (var i = 0; i < 1000; ++i) {
    find(list, new BName("b"));
    find(list, new BName("e"));
  }
}
