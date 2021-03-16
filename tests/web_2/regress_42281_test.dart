// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class ComponentFactory<T> {
  @pragma('dart2js:noInline')
  Type get componentType => T;
}

var mm = {'String': String, 'int': int};
var gf1 = ComponentFactory<int>();
var gf2 = ComponentFactory<dynamic>();
Map<String, ComponentFactory> mf = {'RegExp': ComponentFactory<RegExp>()};

ComponentFactory test(String s, [Map<String, ComponentFactory> mf2]) {
  var f = mf[s];
  if (f == null) {
    var t = mm[s];
    if (mf2 != null) f = mf2[s];
    if (t != null && t != f?.componentType) {
      print('not match $t');
      f = gf2;
    }
  }
  return f;
}

main() {
  Map<String, ComponentFactory> mf2 = {'int': ComponentFactory<num>()};

  test('String');
  test('String', mf2);
  test('int');
  test('int', mf2);
  test('RegExp');
  test('RegExp', mf2);
}
