// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test type promotion of parameters.

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

void test(A a) {
  print(a.a);




  if (a is B) {
    print(a.a);
    print(a.b);



    if (a is C) {
      print(a.a);
      print(a.b);
      print(a.c);

    }

    print(a.a);
    print(a.b);


  }
  if (a is C) {
    print(a.a);
    print(a.b);
    print(a.c);


    if (a is B) {
      print(a.a);
      print(a.b);
      print(a.c);

    }
    if (a is D) {
      print(a.a);
      print(a.b);
      print(a.c);

    }

    print(a.a);
    print(a.b);
    print(a.c);

  }

  print(a.a);




  if (a is D) {
    print(a.a);


    print(a.d);
  }

  print(a.a);




  var o1 = a is B
          ? '${a.a}'
              '${a.b}'


          : '${a.a}'



      ;

  var o2 = a is C
          ? '${a.a}'
              '${a.b}'
              '${a.c}'

          : '${a.a}'



      ;

  var o3 = a is D
          ? '${a.a}'


              '${a.d}'
          : '${a.a}'



      ;

  if (a is B && a is B) {
    print(a.a);
    print(a.b);


  }
  if (a is B && a is C) {
    print(a.a);
    print(a.b);
    print(a.c);

  }
  if (a is C && a is B) {
    print(a.a);
    print(a.b);
    print(a.c);

  }
  if (a is C && a is D) {
    print(a.a);
    print(a.b);
    print(a.c);

  }
  if (a is D && a is C) {
    print(a.a);


    print(a.d);
  }
  if (a is D &&
      a.a == ""


      &&
      a.d == "") {
    print(a.a);


    print(a.d);
  }
  if (a.a == ""



          &&
          a is B &&
          a.a == "" &&
          a.b == ""


          &&
          a is C &&
          a.a == "" &&
          a.b == "" &&
          a.c == ""

      ) {
    print(a.a);
    print(a.b);
    print(a.c);

  }
  if ((a is B)) {
    print(a.a);
    print(a.b);


  }
  if ((a is B && (a) is C) && a is B) {
    print(a.a);
    print(a.b);
    print(a.c);

  }
}
