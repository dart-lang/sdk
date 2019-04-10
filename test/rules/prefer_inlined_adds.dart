// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N prefer_inlined_adds`


var l = ['a']..add('b'); // LINT
var l2 = ['a']..add('b')..add('c'); // LINT

var l3 = ['a']..addAll(['b', 'c']); // LINT

var things;
var l4 = ['a']..addAll(things ?? const []); // OK
