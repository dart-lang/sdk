// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/util/testing.dart';

/*member: Foo.:[exact=Foo]*/
class Foo {
  /*member: Foo._#Foo#x#AI:[sentinel|exact=JSUInt31]*/
  /*member: Foo.x:[exact=JSUInt31]*/
  late int /*[exact=Foo]*/ /*update: [exact=Foo]*/ x = 42;
}

/*member: main:[null]*/
void main() {
  makeLive(test(Foo()));
}

@pragma('dart2js:noInline')
/*member: test:[exact=JSUInt31]*/
int test(Foo /*[exact=Foo]*/ foo) => foo. /*[exact=Foo]*/ x;
