// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../messages/codes.dart' as codes;
import '../scanner/token.dart';

class BlockKind {
  final String name;

  final codes.Message? message;

  final codes.Template<codes.Message Function(Token token)>? template;

  const BlockKind._(this.name, {this.template, this.message});

  @override
  String toString() => 'BlockKind($name)';

  static const BlockKind catchClause = const BlockKind._('catch clause',
      message: codes.messageExpectedCatchClauseBody);
  static const BlockKind classDeclaration = const BlockKind._(
      'class declaration',
      message: codes.messageExpectedClassBody);
  static const BlockKind enumDeclaration = const BlockKind._('enum declaration',
      template: codes.templateExpectedEnumBody);
  static const BlockKind extensionDeclaration = const BlockKind._(
      'extension declaration',
      message: codes.messageExpectedExtensionBody);
  static const BlockKind extensionTypeDeclaration = const BlockKind._(
      'extension type declaration',
      message: codes.messageExpectedExtensionTypeBody);
  static const BlockKind finallyClause = const BlockKind._('finally clause',
      message: codes.messageExpectedFinallyClauseBody);
  static const BlockKind functionBody = const BlockKind._('function body',
      template: codes.templateExpectedFunctionBody);
  static const BlockKind invalid = const BlockKind._('invalid');
  static const BlockKind mixinDeclaration = const BlockKind._(
      'mixin declaration',
      message: codes.messageExpectedMixinBody);
  static const BlockKind statement = const BlockKind._('statement');
  static const BlockKind switchExpression = const BlockKind._(
      'switch expression',
      message: codes.messageExpectedSwitchExpressionBody);
  static const BlockKind switchStatement = const BlockKind._('switch statement',
      message: codes.messageExpectedSwitchStatementBody);
  static const BlockKind tryStatement = const BlockKind._('try statement',
      message: codes.messageExpectedTryStatementBody);
}
