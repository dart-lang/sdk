// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("precedence");

final EXPRESSION = 0;
final ASSIGNMENT = EXPRESSION + 1;
final LOGICAL_OR = ASSIGNMENT + 1;
final LOGICAL_AND = LOGICAL_OR + 1;
final BIT_OR = LOGICAL_AND + 1;
final BIT_XOR = BIT_OR + 1;
final BIT_AND = BIT_XOR + 1;
final EQUALITY = BIT_AND + 1;
final RELATIONAL = EQUALITY + 1;
final SHIFT = RELATIONAL + 1;
final ADDITIVE = SHIFT + 1;
final MULTIPLICATIVE = ADDITIVE + 1;
final UNARY = MULTIPLICATIVE + 1;
final LEFT_HAND_SIDE = UNARY + 1;
// We merge new, call and member expressions.
// This means that we have to emit parenthesis for 'new's. For example `new X;`
// should be printed as `new X();`. This simplifies the requirements.
final CALL = LEFT_HAND_SIDE;
final PRIMARY = CALL + 1;
