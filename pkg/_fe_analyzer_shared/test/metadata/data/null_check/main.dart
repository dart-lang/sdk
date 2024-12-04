// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Helper {
  const Helper(a);
}

const List<int>? constNullableList = [];

@Helper(constNullableList!)
/*member: nullCheck1:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (NullCheck(UnresolvedExpression(UnresolvedIdentifier(constNullableList))))))
resolved=NullCheck(StaticGet(constNullableList))*/
void nullCheck1() {}
