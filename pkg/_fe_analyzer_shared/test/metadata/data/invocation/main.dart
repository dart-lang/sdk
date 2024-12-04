// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core';
import 'dart:core' as core;

class Helper {
  const Helper(a);
}

@Helper(identical(0, 1))
/*member: invocation1:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedIdentifier(identical)
    (
      IntegerLiteral(0), 
      IntegerLiteral(1)))))))
resolved=StaticInvocation(
  identical(
    IntegerLiteral(0), 
    IntegerLiteral(1)))*/
void invocation1() {}

@Helper(core.identical(0, 1))
/*member: invocation2:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (UnresolvedExpression(UnresolvedInvoke(
    UnresolvedAccess(
      UnresolvedIdentifier(core).identical)
    (
      IntegerLiteral(0), 
      IntegerLiteral(1)))))))
resolved=StaticInvocation(
  identical(
    IntegerLiteral(0), 
    IntegerLiteral(1)))*/
void invocation2() {}
