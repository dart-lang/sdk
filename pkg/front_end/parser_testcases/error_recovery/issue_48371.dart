enum E w /*cursor, about to type 'with'*/ {
  v
}

enum E w /*cursor, about to type 'with'*/ implements Foo {
  v
}

enum E implements Foo with Bar {
  v
}

enum E implements Foo implements Bar implements Bar2 {
  v
}

enum E w /*cursor, about to type 'with' instead of implements*/ Foo {
  v
}

enum E implemen /*cursor, about to type 'implements'*/ {
  v
}

enum E implements Foo w/*about to write 'with'*/ {
  v
}

enum E with /* cursor */ {
  v
}

enum E impl implements Foo {
  v
}

// Right order
enum E with Foo implements Bar {
  v
}

// Wrong order
enum E implements Bar with Foo {
  v
}

// Right order but with "gunk" before and between.
enum E gunk1 with Foo gunk2 implements Bar {
  v
}

// Wrong order but with "gunk" before and between.
enum E gunk1 implements Bar gunk2 with Foo {
  v
}

// (Partially) right order but additional clauses.
enum E with Foo with Foo2 implements Bar implements Bar2 with Foo3 implements Bar3 {
  v
}

// Wrong order and additional clauses.
enum E implements Bar implements Bar2 with Foo with Foo2 implements Bar3 with Foo3 {
  v
}
