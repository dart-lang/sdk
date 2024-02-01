// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  void _privateInstanceMember(Class c) {
    _privateInstanceMember(c);
    _privateInjectedInstanceMember1(c);
    _privateInjectedInstanceMember2(c);
    c._privateInstanceMember(c);
    c._privateInjectedInstanceMember1(c);
    c._privateInjectedInstanceMember2(c);
  }

  static void _privateStaticMember() {
    _privateStaticMember();
    _privateInjectedStaticMember1();
    _privateInjectedStaticMember2();
    Class._privateStaticMember();
    Class._privateInjectedStaticMember1();
    Class._privateInjectedStaticMember2();
  }
}

void _privateTopLevelMember() {
  _privateTopLevelMember();
  _privateInjectedTopLevelMember1();
  _privateInjectedTopLevelMember2();
}

class ClassExtends extends Class /* Ok */ {
  void _privateInstanceMember() {}
}

// Error, missing (injected) members.
class ClassImplements implements Class {
  void _privateInstanceMember() {}
}
