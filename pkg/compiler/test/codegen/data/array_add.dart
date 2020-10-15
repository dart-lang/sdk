// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// In prod mode, List.add is lowered to Array.push.
//
// TODO(sra): Lower when type of input does not need a generic covariant check.
@pragma('dart2js:noInline')
/*spec.member: test1:function() {
  var t1 = H.setRuntimeTypeInfo([], type$.JSArray_int);
  C.JSArray_methods.add$1(t1, 1);
  return t1;
}*/
/*prod.member: test1:function() {
  var t1 = [];
  t1.push(1);
  return t1;
}*/
test1() {
  return <int>[]..add(1);
}

/*member: main:function() {
  F.test1();
}*/
main() {
  test1();
}
