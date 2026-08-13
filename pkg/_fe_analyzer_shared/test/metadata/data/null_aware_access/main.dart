// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Helper {
  const Helper(a);
}

const String? constNullableString = '';

@Helper(constNullableString?.length)
/*member: nullAwareAccess1:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (NullAwarePropertyGet(UnresolvedExpression(UnresolvedIdentifier(constNullableString))?.length))))
resolved=NullAwarePropertyGet(StaticGet(constNullableString)?.length)*/
void nullAwareAccess1() {}
