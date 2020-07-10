// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:collection';

/*member: dynamicIndex:Specializer=[!Index]*/
@pragma('dart2js:noInline')
dynamicIndex(var list) {
  return list[0]; // This not known to be an indexable primitive.
}

/*member: unknownListIndex:Specializer=[!Index]*/
@pragma('dart2js:noInline')
unknownListIndex(List list) {
  return list[0]; // This not known to be an indexable primitive.
}

/*member: possiblyNullMutableListIndex:Specializer=[Index]*/
@pragma('dart2js:noInline')
possiblyNullMutableListIndex(bool b) {
  var list = b ? [0] : null;
  return list[0];
}

/*member: mutableListIndex:Specializer=[Index]*/
@pragma('dart2js:noInline')
mutableListIndex() {
  var list = [0];
  return list[0];
}

/*member: mutableListDynamicIndex:Specializer=[Index]*/
@pragma('dart2js:noInline')
mutableListDynamicIndex(dynamic index) {
  var list = [0];
  return list[index]; // CFE inserts an implicit cast of the index.
}

/*spec.member: mutableDynamicListDynamicIndex:Specializer=[!Index]*/
/*prod.member: mutableDynamicListDynamicIndex:Specializer=[Index]*/
@pragma('dart2js:noInline')
@pragma('dart2js:disableFinal')
mutableDynamicListDynamicIndex(dynamic index) {
  dynamic list = [0];
  return list[index];
}

main() {
  dynamicIndex([]);
  dynamicIndex({});
  unknownListIndex([]);
  unknownListIndex(new MyList());
  possiblyNullMutableListIndex(true);
  possiblyNullMutableListIndex(false);
  mutableListIndex();
  mutableListDynamicIndex(0);
  mutableListDynamicIndex('');
  mutableDynamicListDynamicIndex(0);
  mutableDynamicListDynamicIndex('');
}

class MyList<E> extends ListBase<E> {
  E operator [](int index) => null;
  void operator []=(int index, E value) {}
  int get length => 0;
  void set length(int value) {}
}
