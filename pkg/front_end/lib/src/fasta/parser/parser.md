<!--
Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
for details. All rights reserved. Use of this source code is governed by a
BSD-style license that can be found in the LICENSE file.
-->

# Uses of peek in the parser

  * In parseType, the parser uses peekAfterIfType to tell the difference
    between `id` and `id id`.

  * In parseExpressionStatementOrDeclaration, the parser uses
    peekIdentifierAfterType to select between an expression statement or a
    local (function or variable) declaration.

  * In parseExpressionStatementOrConstDeclaration, the parser uses
    peekIdentifierAfterOptionalType to select between an expression statement
    and a const local variable.

  * In parseSendOrFunctionLiteral, the parser uses peekAfterIfType to select
    between function expression and send.

  * In parseVariablesDeclarationOrExpressionOpt, the parser uses
    peekIdentifierAfterType to select between local variable declarations or an
    expression.

  * In parseSwitchCase, the parser uses peekPastLabels to select between case
    labels and statement labels.

  * The parser uses isGeneralizedFunctionType in parseType, and findMemberName.

  * The parser uses findMemberName in parseTopLevelMember, and parseMember.
