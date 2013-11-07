// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--use_mirrored_compilation_error=true

@notDefined
library mirrored_compilation_error_test;

import 'dart:mirrors';
import "package:expect/expect.dart";

@notDefined
class Class<@notDefined T> {
  @notDefined
  var field;

  @notDefined
  method(@notDefined param) {}
}

class Class2 {
  method() { +++; }
  get getter { +++; }
  set setter(x) { +++; }

  static staticFunction() { +++; }
  static get staticGetter { +++; }
  static set staticSetter(x) { +++; }

  Class2() {}
  Class2.constructor() { +++; }
}

toplevelFunction() { +++; }
get toplevelGetter { +++; }
set toplevelSetter(x) { +++; }


class G<A extends int, B extends String> {
  G();
  factory G.swap() = G<B,A>;  /// static type warning
}

raises(closure) {
  Expect.throws(closure,
                (e) => e is MirroredCompilationError,
                'Expected a deferred compilation error');
}

bool get inCheckedMode {
  try {
    var i = 1;
    String s = i;
    return false;
  } catch (e) {
    return true;
  }
}

main() {

  // Metadata.

  raises(() => reflectClass(Class).metadata);
  raises(() => reflectClass(Class).typeVariables.single.metadata);
  raises(() => reflectClass(Class).variables[#field].metadata);
  raises(() => reflectClass(Class).methods[#method].metadata);
  raises(() => reflectClass(Class).methods[#method].parameters.single.metadata);
  raises(() => reflectClass(Class).owner.metadata);


  // Invocation.

  InstanceMirror im = reflect(new Class2());
  raises(() => im.invoke(#method, []));
  raises(() => im.getField(#getter));
  raises(() => im.setField(#setter, 'some value'));
  // The implementation is within its right to defer the compilation even
  // further here, so we apply the tear-off to force compilation.
  raises(() => im.getField(#method).apply([]));

  ClassMirror cm = reflectClass(Class2);
  raises(() => cm.invoke(#staticFunction, []));
  raises(() => cm.getField(#staticGetter));
  raises(() => cm.setField(#staticSetter, 'some value'));
  raises(() => cm.getField(#staticFunction).apply([]));
  raises(() => cm.newInstance(#constructor, []));

  LibraryMirror lm = reflectClass(Class2).owner;
  raises(() => lm.invoke(#toplevelFunction, []));
  raises(() => lm.getField(#toplevelGetter));
  raises(() => lm.setField(#toplevelSetter, 'some value'));
  raises(() => lm.getField(#toplevelFunction).apply([]));


  // Bounds violation.

  if (inCheckedMode) {
    ClassMirror cm = reflect(new G<int, String>()).type;
    raises(() => cm.newInstance(#swap, []));
  }
}
