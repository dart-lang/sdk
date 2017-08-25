// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void simpleSwitch(e) {
  /*0@break*/ switch (e) {
    case 0:
      /*target=0*/ break;
  }
}

void simpleLabelledSwitch(e) {
  target:
  /*0@break*/
  switch (e) {
    case 0:
      /*target=0*/ break target;
  }
}

void simpleNestedSwitch(l) {
  for (var e in l) {
    target:
    /*0@break*/
    switch (e) {
      case 0:
        /*target=0*/ break target;
    }
  }
}

void simpleNestedLabelledSwitch(l) {
  target:
  /*0@break*/
  for (var e in l) {
    /*1@break*/ switch (e) {
      case 0:
        /*target=0*/ break target;
      case 1:
        /*target=1*/ break;
    }
  }
}

void main() {
  simpleSwitch(0);
  simpleLabelledSwitch(0);
  simpleNestedSwitch([]);
  simpleNestedLabelledSwitch([]);
}
