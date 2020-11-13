// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

const EXPRESSION = 0;
// TODO(nshahan) No longer used for the spread operator.
// All precedence levels need to be updated to be more accurate.
const SPREAD = EXPRESSION + 1;
const YIELD = SPREAD + 1;

// Note that some primary expressions (in the parser) must be emitted with lower
// precedence, because it's not normally legal for them to be followed by
// other postfix expressions, like ACCESS and CALL. For example:
// `function foo(){}` needs parens to call or access properties or
// compare with equality. Same thing with `class Foo {}` and `(x) => x`.
// However, prefix unary expressions will work in these cases. Unfortunately our
// current precedence tracking doesn't capture this distinction.
const PRIMARY_LOW_PRECEDENCE = ASSIGNMENT;

const ASSIGNMENT = YIELD + 1;
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
const CALL = LEFT_HAND_SIDE;
// We always emit `new` with parenthesis, so it uses ACCESS as its precedence.
const ACCESS = CALL + 1;
const PRIMARY = ACCESS + 1;
