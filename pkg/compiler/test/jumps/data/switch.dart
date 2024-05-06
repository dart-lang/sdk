// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void simpleSwitch(e) {
  /*0@break*/ switch (e) {
    case 0:
      /*target=0*/ break;
  }
}

void labelledSwitch(e) {
  target:
  /*0@break*/
  switch (e) {
    case 0:
      /*target=0*/ break target;
  }
}

void switchNestedInLoop(l) {
  for (var e in l) {
    target:
    /*0@break*/
    switch (e) {
      case 0:
        /*target=0*/ break target;
    }
  }
}

void labelledSwitchNestedInLoop(l) {
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

void switchWithContinue(e) {
  /*0@break*/ switch (e) {
    target:
    case /*1@continue*/ 0:
      /*target=0*/ break;
    case 1:
      /*target=1*/ continue target;
  }
}

void main() {
  simpleSwitch(0);
  labelledSwitch(0);
  switchNestedInLoop([]);
  labelledSwitchNestedInLoop([]);
  switchWithContinue(0);
}
