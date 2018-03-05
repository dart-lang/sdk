// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class M {}

typedef dynamic FF({M b});

/*element: table:OutputUnit(1, {lib})*/
const table =
/*ast.null*/
/*kernel.OutputUnit(1, {lib})*/
    const <int, FF>{1: f1, 2: f2};

/*element: f1:OutputUnit(1, {lib})*/
dynamic f1({M b}) => null;

/*element: f2:OutputUnit(1, {lib})*/
dynamic f2({M b}) => null;
