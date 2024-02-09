// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type Ext(Function it) {
  String call() => 'call from Ext: ${it()}';
}

class C {
  String call() => 'call from C';
}

extension type Ext2(C c) implements C {}

class D {
  Function get getter1 => Ext(C());
  Function get getter2 {
    var result = Ext(C());
    return result;
  }
  Function get getter3 => Ext2(C());
  Function get getter4 {
    var result = Ext2(C());
    return result;
  }
  Function method1<T extends C>(T c) {
    return c;
  }
  Function method2<T extends C>(T c) {
    var result = Ext(c);
    return result;
  }
  Function method3<T extends Ext>(Ext e) {
    return e;
  }
  Function method4<T extends Ext2>(Ext2 e) {
    return e;
  }
  Function method5<T>(T c) {
    if (c is C) {
      return c;
    }
    return () => null;
  }
  Function method6<T, S extends C>(T c) {
    if (c is S) {
      return c;
    }
    return () => null;
  }
}

class E {
  String get getter1 => Ext(C())();

  String get getter2 {
    var result = Ext(C())();
    return result;
  }

  String get getter3 => Ext2(C())();

  String get getter4 {
    var result = Ext2(C())();
    return result;
  }

  String method1<T extends C>(T c) {
    return c();
  }

  String method2<T extends C>(T c) {
    var result = Ext(c)();
    return result;
  }

  String method3<T extends Ext>(Ext e) {
    return e();
  }

  String method4<T extends Ext2>(Ext2 e) {
    return e();
  }

  String method5<T>(T c) {
    if (c is C) {
      return c();
    }
    return "";
  }

  String method6<T, S extends C>(T c) {
    if (c is S) {
      return c();
    }
    return "";
  }
}

void main() {
  var d = D();
  print(d.getter1());
  print(d.getter2());
  print(d.getter3());
  print(d.getter4());
  print(d.method1(C())());
  print(d.method2(C())());
  print(d.method3(Ext(C()))());
  print(d.method4(Ext2(C()))());
  print(d.method5(C())());
  print(d.method6(C())());

  var e = E();
  print(e.getter1);
  print(e.getter2);
  print(e.getter3);
  print(e.getter4);
  print(e.method1(C()));
  print(e.method2(C()));
  print(e.method3(Ext(C())));
  print(e.method4(Ext2(C())));
  print(e.method5(C()));
  print(e.method6(C()));
}