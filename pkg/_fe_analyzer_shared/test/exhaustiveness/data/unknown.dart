// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final unknownShouldNotIncludeNull = /*fields={isEven:-},
 type=Null
*/ switch (null) {
  int(:var isEven) when isEven /*space=int(isEven: bool)*/ => 1,
  _ /*space=Null*/ => 0,
};
