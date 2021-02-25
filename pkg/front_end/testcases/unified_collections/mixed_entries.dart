// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

bool b = false;

var list = [];

var map0 = {};
var map1 = {if (b) 0: 1 else ...map0};
var map2 = {if (b) ...map0 else 0: 1};
var map3 = {if (b) ...map0 else ...map0};
var map4 = {if (b) 0: 1 else for (var a in list) a: 1};
var map5 = {if (b) for (var a in list) a: 1 else 0: 1};
var map6 = {
  if (b) 0: 1 else for (var a in list) ...{a: 1}
};
var map7 = {
  if (b) for (var a in list) ...{a: 1} else 0: 1
};
var map8 = {if (b) 0: 1 else for (var i = 0; i < list.length; i++) list[i]: 1};
var map9 = {if (b) for (var i = 0; i < list.length; i++) list[i]: 1 else 0: 1};
var map10 = {
  if (b) 0: 1 else for (var i = 0; i < list.length; i++) ...{list[i]: 1}
};
var map11 = {
  if (b) for (var i = 0; i < list.length; i++) ...{list[i]: 1} else 0: 1
};
var map12 = {
  if (b) 0: 1 else if (b) ...{0: 1}
};

var error4 = {if (b) 0: 1 else for (var a in list) a};
var error5 = {if (b) for (var a in list) a else 0: 1};
var error6 = {
  if (b) 0: 1 else for (var a in list) ...{a}
};
var error7 = {
  if (b) for (var a in list) ...{a} else 0: 1
};
var error8 = {if (b) 0: 1 else for (var i = 0; i < list.length; i++) list[i]};
var error9 = {if (b) for (var i = 0; i < list.length; i++) list[i] else 0: 1};
var error10 = {
  if (b) 0: 1 else for (var i = 0; i < list.length; i++) ...{list[i]}
};
var error11 = {
  if (b) for (var i = 0; i < list.length; i++) ...{list[i]} else 0: 1
};
var error12 = {
  if (b) 0: 1 else if (b) ...{0}
};

main() {}
