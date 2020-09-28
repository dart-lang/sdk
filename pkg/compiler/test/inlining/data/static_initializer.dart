// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[]*/
main() {
  _var1;
  _var2;
  _var3;
}

var _var1 = <String>[_shortString(), _longStringMany()];
var _var2 = <String>[_shortString(), _longStringMany(), _longStringOnce()];

/*member: _shortString:[_var1,_var2]*/
String _shortString() => r"""
hello""";

/*member: _longStringMany:[]*/
String _longStringMany() => r"""
I wandered lonely as a cloud
That floats on high o'er vales and hills,
When all at once I saw a crowd,
A host, of golden daffodils;
Beside the lake, beneath the trees,
Fluttering and dancing in the breeze.
""";

/*member: _longStringOnce:[_var2]*/
String _longStringOnce() => r"""
Continuous as the stars that shine
And twinkle on the milky way,
They stretched in never-ending line
Along the margin of a bay:
Ten thousand saw I at a glance,
Tossing their heads in sprightly dance.
""";

var _var3 = <int>[Foo().a, (Foo()..a).a];

/*member: Foo.:[_var3:Foo]*/
class Foo {
  int z = 99;
  /*member: Foo.a:[_var3]*/
  get a => b;
  /*member: Foo.b:[_var3]*/
  get b => c;
  /*member: Foo.c:[]*/
  get c => z++;
}
