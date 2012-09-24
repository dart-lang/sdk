// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test explicit import of dart:core in the source code..

#library("ImportCorePrefixTest.dart");
#import("dart:core", prefix:"mycore");

void main() {
  var test = new mycore.Map<mycore.int,mycore.String>();
  mycore.bool boolval = false;
  mycore.int variable = 10;
  mycore.num value = 10;
  mycore.Dynamic d = null;
}
