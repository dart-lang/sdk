// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library precedence;

const EXPRESSION = 0;
const ASSIGNMENT = EXPRESSION + 1;
const LOGICAL_OR = ASSIGNMENT + 1;
const LOGICAL_AND = LOGICAL_OR + 1;
const BIT_OR = LOGICAL_AND + 1;
const BIT_XOR = BIT_OR + 1;
const BIT_AND = BIT_XOR + 1;
const EQUALITY = BIT_AND + 1;
const RELATIONAL = EQUALITY + 1;
const SHIFT = RELATIONAL + 1;
const ADDITIVE = SHIFT + 1;
const MULTIPLICATIVE = ADDITIVE + 1;
const UNARY = MULTIPLICATIVE + 1;
const LEFT_HAND_SIDE = UNARY + 1;
// We merge new, call and member expressions.
// This means that we have to emit parenthesis for 'new's. For example `new X;`
// should be printed as `new X();`. This simplifies the requirements.
const CALL = LEFT_HAND_SIDE;
const PRIMARY = CALL + 1;
