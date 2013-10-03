// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:mirrors";
import "package:expect/expect.dart";

class G<A extends int, B extends String> {
  G();
  factory G.swap() = G<B,A>;  /// static type warning
  factory G.retain() = G<A,B>;
}

bool get inCheckedMode {
  try {
    var i = 1;
    String s = i;
    return false;
  } catch(e) {
    return true;
  }
}

main() {
  ClassMirror cm = reflect(new G<int, String>()).type;

  if (inCheckedMode) {
    Expect.throws(() => cm.newInstance(#swap, []),
                  (e) => e is MirroredCompilationError,
                  'Checked mode should not allow violation of type bounds');
  } else {
    Expect.isTrue(cm.newInstance(#swap, []).reflectee is G<String,int>);
  }

  Expect.isTrue(cm.newInstance(#retain, []).reflectee is G<int,String>);
}
