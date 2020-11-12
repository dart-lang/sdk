// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:collection';
import 'dart:typed_data';

/*member: dynamicIndex:Specializer=[!RemoveLast]*/
@pragma('dart2js:noInline')
dynamicIndex(var list) {
  return list.removeLast(); // This is not known to be an indexable primitive.
}

/*member: unknownList:Specializer=[!RemoveLast]*/
@pragma('dart2js:noInline')
unknownList(List list) {
  return list.removeLast(); // This is not known to be an indexable primitive.
}

/*member: possiblyNullMutableList:Specializer=[RemoveLast]*/
@pragma('dart2js:noInline')
possiblyNullMutableList(bool b) {
  var list = b ? [0] : null;
  return list.removeLast();
}

/*member: mutableList:Specializer=[RemoveLast]*/
@pragma('dart2js:noInline')
mutableList() {
  var list = [0];
  return list.removeLast();
}

/*member: typedList:Specializer=[!RemoveLast]*/
@pragma('dart2js:noInline')
typedList() {
  var list = Uint8List(10);
  return list.removeLast();
}

main() {
  dynamicIndex([]);
  dynamicIndex({});
  unknownList([]);
  unknownList(new MyList());
  possiblyNullMutableList(true);
  possiblyNullMutableList(false);
  mutableList();
  typedList();
}

class MyList<E> extends ListBase<E> {
  E operator [](int index) => null;
  void operator []=(int index, E value) {}
  int get length => 0;
  void set length(int value) {}
}
