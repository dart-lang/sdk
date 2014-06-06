// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for http://dartbug.com/19191

class A {
  var method;
  
  noSuchMethod(Invocation invocation) {
    if (invocation.isGetter) {
      return method;
    } else if (invocation.isSetter) {
      method = invocation.positionalArguments[0];
      return null;
    } else if (invocation.isMethod) {
      return Function.apply(method, invocation.positionalArguments,
          invocation.namedArguments);
    } else {
      throw new NoSuchMethodError(this, invocation.memberName,
          invocation.positionalArguments, invocation.namedArguments);
    }
  }
  
  init() {
    closure_fails = (String str) {
      return str.toUpperCase();
    };
  }
  
  run() {
    print(closure_fails("Hello World"));
  }
}

void main() {
  var a = new A();
  a.init();
  a.run();
}

