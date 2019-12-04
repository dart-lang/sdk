// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test type promotion of locals.

class A {
  var a = "a";
}

class B extends A {
  var b = "b";
}

class C extends B {
  var c = "c";
}

class D extends A {
  var d = "d";
}

class E implements C, D {
  var a = "";
  var b = "";
  var c = "";
  var d = "";
}

void main() {
  test(new E());
}

void test(A a1) {
  A a2 = new E();
  print(a1.a);




  print(a2.a);




  if (a1 is B && a2 is C) {
    print(a1.a);
    print(a1.b);



    print(a2.a);
    print(a2.b);
    print(a2.c);


    if (a1 is C && a2 is D) {
      print(a1.a);
      print(a1.b);
      print(a1.c);


      print(a2.a);
      print(a2.b);
      print(a2.c);

    }
  }

  var o1 = a1 is B && a2 is C
          ? '${a1.a}'
              '${a1.b}'


              '${a2.a}'
              '${a2.b}'
              '${a2.c}'

          : '${a1.a}'



          '${a2.a}'



      ;

  if (a2 is C && a1 is B && a1 is C && a2 is B && a2 is D) {
    print(a1.a);
    print(a1.b);
    print(a1.c);


    print(a2.a);
    print(a2.b);
    print(a2.c);

  }
}
