// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('PrivateMemberLibB');

#import('PrivateMemberTest.dart');

class B extends A {
  bool _private1;
  String _private3;

  static bool _static1;
  static String _static3;

  bool _fun1() { return true; }
  String _fun3() { return ""; }

  void _fun4(bool b) { }
}
