// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--support_find_in_context=true

library test.find_in_context_private;

import "dart:mirrors";
import "package:expect/expect.dart";

var _globalVariable = "globalVariable";
_globalFoo() => 17;

class S {
  static _staticFooInS() => "staticFooInS";
  static var _staticInS = "staticInS";
  var _instanceInS = "instanceInS";
}

class C extends S {
  static _staticFooInC() => "staticFooInC";
  static var _staticInC = "staticInC";
  var _instanceInC = "instanceInC";

  _method() {
    var _local = "local";
    nested() {
      var _innerLocal = "innerLocal";
      print(this._instanceInC);
      print(_local);
      print(_innerLocal);
    }
    return nested;
  }

}

doFindInContext(cm, name, value) {
  Expect.equals(value,
                cm.findInContext(name).reflectee);
}
dontFindInContext(cm, name) {
  Expect.isNull(cm.findInContext(name));
}

main() {
  LibraryMirror wrongLibrary = reflectClass(List).owner;
  p(name) => MirrorSystem.getSymbol(name, wrongLibrary);

  C c = new C();

  // In the context of C._method.nested.
  ClosureMirror cm = reflect(c._method());

  // N.B.: innerLocal is only defined with respective to an activation of the
  // closure 'nested', not the closure itself.
  dontFindInContext(cm, #_innerLocal);

  doFindInContext(cm, #_local, "local");
  doFindInContext(cm, #_method, c._method);
  doFindInContext(cm, #_instanceInC, "instanceInC");
  doFindInContext(cm, #_staticInC, "staticInC");
  doFindInContext(cm, #_staticFooInC, C._staticFooInC);
  dontFindInContext(cm, #_staticInS);
  dontFindInContext(cm, #_staticFooInS);
  doFindInContext(cm, #_globalFoo, _globalFoo);
  doFindInContext(cm, #_globalVariable, "globalVariable");

  dontFindInContext(cm, p('_local'));
  dontFindInContext(cm, p('_innerLocal'));
  dontFindInContext(cm, p('_method'));
  dontFindInContext(cm, p('_instanceInC'));
  dontFindInContext(cm, p('_staticInC'));
  dontFindInContext(cm, p('_staticFooInC'));
  dontFindInContext(cm, p('_staticInS'));
  dontFindInContext(cm, p('_staticFooInS'));
  dontFindInContext(cm, p('_globalFoo'));
  dontFindInContext(cm, p('_globalVariable'));

  // In the context of C._method.
  cm = reflect(c._method);
  dontFindInContext(cm, #_innerLocal);
  dontFindInContext(cm, #_local);  // N.B.: See above.
  doFindInContext(cm, #_method, c._method);
  doFindInContext(cm, #_instanceInC, "instanceInC");
  doFindInContext(cm, #_staticInC, "staticInC");
  doFindInContext(cm, #_staticFooInC, C._staticFooInC);
  dontFindInContext(cm, #_staticInS);
  dontFindInContext(cm, #_staticFooInS);
  doFindInContext(cm, #_globalFoo, _globalFoo);
  doFindInContext(cm, #_globalVariable, "globalVariable");

  dontFindInContext(cm, p('_local'));
  dontFindInContext(cm, p('_innerLocal'));
  dontFindInContext(cm, p('_method'));
  dontFindInContext(cm, p('_instanceInC'));
  dontFindInContext(cm, p('_staticInC'));
  dontFindInContext(cm, p('_staticFooInC'));
  dontFindInContext(cm, p('_staticInS'));
  dontFindInContext(cm, p('_staticFooInS'));
  dontFindInContext(cm, p('_globalFoo'));
  dontFindInContext(cm, p('_globalVariable'));
}
