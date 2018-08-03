// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=warning*/
class C {
  var superField;
  superMethod() {}

  get setterOnly => null;
  void set setterOnly(_) {}

  get getterOnly => null;
  void set getterOnly(_) {}
}

class D extends C {
  var field;

  void set setterOnly(_) {}

  get getterOnly => null;

  method() {}

  void test() {
    this.field;
    this.superField;
    this.field = 0;
    this.superField = 0;
    this.method();
    this.superMethod();
    this.setterOnly;
    this.setterOnly = 0;
    this.getterOnly;
    this.getterOnly = 0;

    field;
    superField;
    field = 0;
    superField = 0;
    method();
    superMethod();
    setterOnly;
    setterOnly = 0;
    getterOnly;
    getterOnly = 0;

    this. /*@warning=GetterNotFound*/ missingField;
    this. /*@warning=SetterNotFound*/ missingField = 0;
    this. /*@warning=MethodNotFound*/ missingMethod();

    /*@warning=GetterNotFound*/ missingField;
    /*@warning=SetterNotFound*/ missingField = 0;
    /*@warning=MethodNotFound*/ missingMethod();
  }
}

class E extends D {
  var missingField;
  void missingMethod() {}
}

main() {
  new E().test();
}
