// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  neverForInExpressionType();        //# 01: runtime error
}

neverForInExpressionType() async {   //# 01: continued
  return <int, String>{              //# 01: continued
    for (var y in throw '') ...y,    //# 01: continued
  };                                 //# 01: continued
}                                    //# 01: continued

invalidForInExpressionType(X x) async {  //# 02: compile-time error
  return <X, X>{                         //# 02: continued
    for (var y in x) ...y,               //# 02: continued
  };                                     //# 02: continued
}                                        //# 02: continued

