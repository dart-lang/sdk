// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

foo({fisk}) {
  print(fisk);
}

caller(f) {
  f();
}

main() {
  int i = 0;
  print(i == 1 ? "bad" : "good");
  print("$i");
  print("'$i'");
  print(" '${i}' ");
  print(" '${i}' '${i}'");
  print(" '$i' '${i}'");
  print("foo" "bar");
  print(" '${i}' '${i}'" " '$i' '${i}'");
  try {
    throw "fisk";
  } on String catch (e, s) {
    print(e);
    if (s != null) print(s);
  }
  for(;false;) {}
  var list = ["Hello, World!"];
  print(list[i]);
  list[i] = "Hello, Brave New World!";
  print(list[i]);
  i = 87;
  print(-i);
  print(~i);
  print(!(i == 42));
  print(--i);
  print(++i);
  print(i--);
  print(i++);
  print(new Object());
  print(const Object());
  print((new List<String>(2)).runtimeType);
  foo(fisk: "Blorp gulp");
  f() {
    print("f was called");
  }
  caller(f);
  caller(() {
    print("<anon> was called");
  });
  g([message]) {
    print(message);
  }
  g("Hello, World");
  caller(([x]) {
    print("<anon> was called with $x");
  });
  h({message}) {
    print(message);
  }
  h(message: "Hello, World");
  caller(({x}) {
    print("<anon> was called with $x");
  });
  print((int).toString());
  print(int);
  print(int..toString());
  try {
    print(int?.toString());
    throw "Shouldn't work";
  } on NoSuchMethodError catch (e) {
    print("As expected: $e");
  }
  print(int.parse("42"));
}
