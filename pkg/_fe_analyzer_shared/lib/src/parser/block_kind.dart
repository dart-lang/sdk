// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/messages/diagnostic.dart' as diag;

import '../messages/codes.dart' as codes;
import '../scanner/token.dart';

class BlockKind {
  final String name;

  final codes.Message? message;

  final codes.Template<codes.Message Function({required Token lexeme})>?
  template;

  const BlockKind._(this.name, {this.template, this.message});

  @override
  String toString() => 'BlockKind($name)';

  static const BlockKind catchClause = const BlockKind._(
    'catch clause',
    message: diag.expectedCatchClauseBody,
  );
  static const BlockKind classDeclaration = const BlockKind._(
    'class declaration',
    message: diag.expectedClassBody,
  );
  static const BlockKind enumDeclaration = const BlockKind._(
    'enum declaration',
    template: diag.expectedEnumBody,
  );
  static const BlockKind extensionDeclaration = const BlockKind._(
    'extension declaration',
    message: diag.expectedExtensionBody,
  );
  static const BlockKind extensionTypeDeclaration = const BlockKind._(
    'extension type declaration',
    message: diag.expectedExtensionTypeBody,
  );
  static const BlockKind finallyClause = const BlockKind._(
    'finally clause',
    message: diag.expectedFinallyClauseBody,
  );
  static const BlockKind functionBody = const BlockKind._(
    'function body',
    template: diag.expectedFunctionBody,
  );
  static const BlockKind invalid = const BlockKind._('invalid');
  static const BlockKind mixinDeclaration = const BlockKind._(
    'mixin declaration',
    message: diag.expectedMixinBody,
  );
  static const BlockKind statement = const BlockKind._('statement');
  static const BlockKind switchExpression = const BlockKind._(
    'switch expression',
    message: diag.expectedSwitchExpressionBody,
  );
  static const BlockKind switchStatement = const BlockKind._(
    'switch statement',
    message: diag.expectedSwitchStatementBody,
  );
  static const BlockKind tryStatement = const BlockKind._(
    'try statement',
    message: diag.expectedTryStatementBody,
  );
}
