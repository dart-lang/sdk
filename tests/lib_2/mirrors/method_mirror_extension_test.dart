// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=extension-methods

library lib;

import "dart:mirrors";

import "package:expect/expect.dart";

class C<T> {
  static int tracefunc() {
    try {
      throw "producing a stack trace";
    } catch (e, s) {
      print(s);
    }
    return 10;
  }
}

extension ext<T> on C<T> {
  func() {
    try {
      throw "producing a stack trace";
    } catch (e, s) {
      print(s);
    }
  }

  get prop {
    try {
      throw "producing a stack trace";
    } catch (e, s) {
      print(s);
    }
  }

  set prop(value) {
    try {
      throw "producing a stack trace";
    } catch (e, s) {
      print(s);
    }
  }

  operator +(val) {
    try {
      throw "producing a stack trace";
    } catch (e, s) {
      print(s);
    }
  }

  operator -(val) {
    try {
      throw "producing a stack trace";
    } catch (e, s) {
      print(s);
    }
  }

  static int sfld = C.tracefunc();
  static sfunc() {
    try {
      throw "producing a stack trace";
    } catch (e, s) {
      print(s);
    }
  }

  static get sprop {
    try {
      throw "producing a stack trace";
    } catch (e, s) {
      print(s);
    }
  }

  static set sprop(value) {
    try {
      throw "producing a stack trace";
    } catch (e, s) {
      print(s);
    }
  }
}

checkExtensionKind(closure, kind, name) {
  var closureMirror = reflect(closure) as ClosureMirror;
  var methodMirror = closureMirror.function;
  Expect.isTrue(methodMirror.simpleName.toString().contains(name));
  Expect.equals(kind, methodMirror.isExtensionMember, "isExtension");
}

void testExtension(sym, mirror) {
  if (mirror is MethodMirror) {
    var methodMirror = mirror as MethodMirror;
    if (MirrorSystem.getName(sym).startsWith('ext', 0)) {
      Expect.equals(true, methodMirror.isExtensionMember, "isExtension");
      Expect.isTrue(methodMirror.simpleName.toString().contains('ext.'));
    } else {
      Expect.equals(false, methodMirror.isExtensionMember, "isExtension");
    }
  } else if (mirror is VariableMirror) {
    var variableMirror = mirror as VariableMirror;
    if (MirrorSystem.getName(sym).startsWith('ext', 0)) {
      Expect.equals(true, variableMirror.isExtensionMember, "isExtension");
    } else {
      Expect.equals(false, variableMirror.isExtensionMember, "isExtension");
    }
  }
}

main() {
  checkExtensionKind(C.tracefunc, false, 'tracefunc');

  C c = new C();
  checkExtensionKind(c.func, true, 'ext.func');
  checkExtensionKind(ext.sfunc, true, 'ext.sfunc');

  var libraryMirror = reflectClass(C).owner as LibraryMirror;
  libraryMirror.declarations.forEach(testExtension);
}
