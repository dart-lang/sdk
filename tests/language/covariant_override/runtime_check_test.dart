// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class View {
  addChild(View v) {}
  transform(View fn(View v)) {}
}

class MyView extends View {
  addChild(covariant MyView v) {}
  transform(covariant MyView fn(Object v)) {}
}

main() {
  dynamic mv = new MyView();
  dynamic v = new View();

  mv.addChild(mv);
  Expect.throws(() => mv.addChild(v));

  mv.transform((_) => new MyView());

  // TODO(jmesserly): these *should* be cast failures, but DDC is currently
  // ignoring function type failures w/ a warning at the console...

  // * -> * not a subtype of Object -> MyView
  Expect.throws(() => mv.transform((_) => mv));

  // View -> View not a subtype of Object -> MyView
  Expect.throws(() => mv.transform((View x) => x));
}
