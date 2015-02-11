// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Common AST helpers.
library dart_lint.src.ast;

import 'package:analyzer/src/generated/ast.dart';

/// Returns `true` if the given [ClassMember] is a public method.
bool isPublicMethod(ClassMember m) =>
    m is MethodDeclaration && m.element.isPublic;
