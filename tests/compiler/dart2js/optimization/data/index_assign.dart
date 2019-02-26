// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: dynamicIndexAssign:Specializer=[!IndexAssign]*/
@pragma('dart2js:noInline')
dynamicIndexAssign(var list) {
  list[0] = 1;
}

/*strong.element: unknownListIndexAssign:Specializer=[!IndexAssign]*/
/*omit.element: unknownListIndexAssign:Specializer=[IndexAssign]*/
@pragma('dart2js:noInline')
unknownListIndexAssign(List list) {
  list[0] = 1;
}

/*strong.element: possiblyNullMutableListIndexAssign:Specializer=[!IndexAssign]*/
/*omit.element: possiblyNullMutableListIndexAssign:Specializer=[IndexAssign]*/
@pragma('dart2js:noInline')
possiblyNullMutableListIndexAssign(bool b) {
  var list = b ? [0] : null;
  list[0] = 1;
}

/*strong.element: mutableListIndexAssign:Specializer=[!IndexAssign]*/
/*omit.element: mutableListIndexAssign:Specializer=[IndexAssign]*/
@pragma('dart2js:noInline')
mutableListIndexAssign() {
  var list = [0];
  list[0] = 1;
}

/*strong.element: mutableListDynamicIndexAssign:Specializer=[!IndexAssign]*/
/*omit.element: mutableListDynamicIndexAssign:Specializer=[IndexAssign]*/
@pragma('dart2js:noInline')
mutableListDynamicIndexAssign(dynamic index) {
  var list = [0];
  list[index] = 1;
}

/*strong.element: mutableListDynamicValueIndexAssign:Specializer=[!IndexAssign]*/
/*omit.element: mutableListDynamicValueIndexAssign:Specializer=[IndexAssign]*/
@pragma('dart2js:noInline')
mutableListDynamicValueIndexAssign(dynamic value) {
  var list = [0];
  list[0] = value;
}

/*element: immutableListIndexAssign:Specializer=[!IndexAssign]*/
@pragma('dart2js:noInline')
immutableListIndexAssign() {
  var list = const [0];
  list[0] = 1;
}

main() {
  dynamicIndexAssign([]);
  dynamicIndexAssign({});
  unknownListIndexAssign([]);
  unknownListIndexAssign(null);
  possiblyNullMutableListIndexAssign(true);
  possiblyNullMutableListIndexAssign(false);
  mutableListIndexAssign();
  mutableListDynamicIndexAssign(0);
  mutableListDynamicIndexAssign('');
  mutableListDynamicValueIndexAssign(0);
  mutableListDynamicValueIndexAssign('');
  immutableListIndexAssign();
}
