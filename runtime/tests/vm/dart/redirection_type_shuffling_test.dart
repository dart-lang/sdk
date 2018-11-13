// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:mirrors";
import "package:expect/expect.dart";

class G<A extends int, B extends String> {
  G();
  factory G.swap() = G<B,A>;  /// 00: compile-time error
  factory G.retain() = G<A,B>;
}

main() {
  ClassMirror cm = reflect(new G<int, String>()).type;

  Expect.isTrue(cm.newInstance(#retain, []).reflectee is G<int,String>);

  Expect.isTrue(cm.newInstance(#swap, []).reflectee is G<String,int>);  /// 00: dynamic type error
}
