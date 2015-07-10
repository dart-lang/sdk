// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test file for testing source mappings of invocations.

var counter = 0;
var bucket;

main(args) {
  counter++;
  invokes(args);
  return counter;
}

invokes(parameter) {
  counter++;
  toplevelFunction();
  toplevelField();
  toplevelFinalField();
  toplevelConstField();
  toplevelGetter();
  C.staticFunction();
  C.staticField();
  C.staticFinalField();
  C.staticConstField();
  C.staticGetter();

  var localVariable = () {
    counter++;
  };
  localFunction() {
    counter++;
  }

  parameter();
  localVariable();
  localFunction();
  (parameter)();

  parameter.dynamicInvoke();
  new C(parameter).instanceInvokes();
}

toplevelFunction() {
  counter++;
}

var toplevelField = () {
  counter++;
};

final toplevelFinalField = toplevelFunction;

const toplevelConstField = toplevelFunction;

get toplevelGetter => () {
  counter++;
};

typedef F();

class B {
  B(parameter);

  superMethod() {
    counter++;
  }

  var superField = () {
    counter++;
  };

  get superGetter => () {
    counter++;
  };

}

class C<T> extends B {
  C(parameter) : super(parameter);

  static staticFunction() {
    counter++;
  }

  static var staticField = () {
    counter++;
  };

  static final staticFinalField = staticFunction;

  static const staticConstField = staticFunction;

  static get staticGetter => () {
    counter++;
  };

  instanceMethod() {
    counter++;
  }

  var instanceField = () {
    counter++;
  };

  get instanceGetter => () {
    counter++;
  };

  instanceInvokes() {
    instanceMethod();
    this.instanceMethod();
    instanceField();
    this.instanceField();
    instanceGetter();
    this.instanceGetter();

    super.superMethod();
    super.superField();
    super.superGetter();

    C();
    dynamic();
    F();
    T();
  }
}