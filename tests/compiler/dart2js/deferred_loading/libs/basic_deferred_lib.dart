// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: defaultArg:OutputUnit(1, {lib})*/
defaultArg() => "";

/*element: funky:OutputUnit(1, {lib})*/
funky([x = defaultArg]) => x();

final int notUsed = 3;
