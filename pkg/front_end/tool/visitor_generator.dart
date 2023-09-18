// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_style/dart_style.dart' show DartFormatter;

import 'ast_model.dart';

/// Generates a visitor library into [sb] based on [astModel] and [strategy].
///
/// If [format] is `false`, the generated output will _not_ be formatted using
/// the Dart formatter. Use this during development to support incomplete
/// generation.
String generateVisitor(AstModel astModel, VisitorStrategy strategy,
    {bool format = true}) {
  StringBuffer sb = new StringBuffer();
  strategy.generateHeader(astModel, sb);

  void addVisitNode(AstClass astClass) {
    switch (astClass.kind) {
      case AstClassKind.root:
      case AstClassKind.inner:
        for (AstClass subclass in astClass.subclasses) {
          addVisitNode(subclass);
        }
        break;
      case AstClassKind.public:
      case AstClassKind.auxiliary:
      case AstClassKind.named:
      case AstClassKind.declarative:
        if (astClass.hasVisitMethod) {
          strategy.generateVisit(astModel, astClass, sb);
        }
        break;
      case AstClassKind.implementation:
      case AstClassKind.interface:
      case AstClassKind.utilityAsStructure:
      case AstClassKind.utilityAsValue:
        break;
    }
  }

  void addVisitReference(AstClass astClass) {
    switch (astClass.kind) {
      case AstClassKind.root:
      case AstClassKind.inner:
        for (AstClass subclass in astClass.subclasses) {
          addVisitReference(subclass);
        }
        break;
      case AstClassKind.public:
      case AstClassKind.auxiliary:
      case AstClassKind.named:
      case AstClassKind.declarative:
        if (astClass.hasVisitReferenceMethod) {
          strategy.generateVisitReference(astModel, astClass, sb);
        }
        break;
      case AstClassKind.implementation:
      case AstClassKind.interface:
      case AstClassKind.utilityAsStructure:
      case AstClassKind.utilityAsValue:
        break;
    }
  }

  addVisitNode(astModel.nodeClass);
  addVisitReference(astModel.namedNodeClass);
  addVisitReference(astModel.constantClass);
  strategy.generateFooter(astModel, sb);

  String result = sb.toString();
  if (format) {
    result = new DartFormatter().format(result);
  }
  return result;
}

/// Strategy for generating a visitor in its own library based on an [AstModel].
abstract class VisitorStrategy {
  const VisitorStrategy();

  /// Preamble comment used in the generated file.
  String get preamble => '''
// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// NOTE: THIS FILE IS GENERATED. DO NOT EDIT.
//
// Run '$generatorCommand' to update.
''';

  /// The command used to generate the visitor.
  ///
  /// This is inserted in the [preamble] along with a comment that the file
  /// is generated.
  String get generatorCommand;

  /// Comment used as doc comment for the generated visitor class.
  String get visitorComment => '';

  /// Generates the header of the visitor library, including preamble, imports
  /// and visitor class declaration start.
  void generateHeader(AstModel astModel, StringBuffer sb);

  /// Generates a `visitX` visitor method for [astClass].
  void generateVisit(AstModel astModel, AstClass astClass, StringBuffer sb);

  /// Generates a `visitXReference` visitor method for [astClass].
  void generateVisitReference(
      AstModel astModel, AstClass astClass, StringBuffer sb);

  /// Generates the footer of the visitor library, including the visitor class
  /// declaration end.
  void generateFooter(AstModel astModel, StringBuffer sb);
}

/// Base strategy for creating a [Visitor] implementation.
abstract class Visitor0Strategy extends VisitorStrategy {
  const Visitor0Strategy();

  /// The name of the generated visitor class.
  String get visitorName;

  /// The type parameters of the generated visitor class.
  String get visitorTypeParameters => '';

  /// The return type for the visitor methods.
  ///
  /// The generated visitor will implement `Visitor<$returnType>`.
  String get returnType;

  @override
  void generateHeader(AstModel astModel, StringBuffer sb) {
    sb.writeln('''
$preamble

import 'package:kernel/ast.dart';

$visitorComment
class $visitorName$visitorTypeParameters implements Visitor<$returnType> {''');
  }

  @override
  void generateFooter(AstModel astModel, StringBuffer sb) {
    sb.writeln('''
}''');
  }

  @override
  void generateVisit(AstModel astModel, AstClass astClass, StringBuffer sb) {
    sb.writeln('''
  @override
  ${returnType} visit${astClass.name}(
      ${astClass.name} node) {''');
    handleVisit(astModel, astClass, sb);
    sb.writeln('}');
  }

  /// Generates the body of a `visitX` visitor method of [astClass].
  void handleVisit(AstModel astModel, AstClass astClass, StringBuffer sb) {}

  @override
  void generateVisitReference(
      AstModel astModel, AstClass astClass, StringBuffer sb) {
    sb.writeln('''
  @override
  ${returnType} visit${astClass.name}Reference(
      ${astClass.name} node) {''');
    handleVisitReference(astModel, astClass, sb);
    sb.writeln('}');
  }

  /// Generates the body of a `visitXReference` visitor method of [astClass].
  void handleVisitReference(
      AstModel astModel, AstClass astClass, StringBuffer sb) {}
}

/// Strategy for creating an empty `Visitor<void>` implementation.
abstract class VoidVisitor0Strategy extends Visitor0Strategy {
  const VoidVisitor0Strategy();

  @override
  String get visitorName => 'VoidVisitor';

  @override
  String get returnType => 'void';
}

/// Base strategy for creating a [Visitor1] implementation.
abstract class Visitor1Strategy extends VisitorStrategy {
  const Visitor1Strategy();

  /// The name of the generated visitor class.
  String get visitorName;

  /// The type parameters of the generated visitor class.
  String get visitorTypeParameters => '';

  /// The type of the argument of the visitor methods.
  ///
  /// The generated visitor will implement
  /// `Visitor1<$returnType, $argumentType>`.
  String get argumentType;

  /// The name of the argument parameter name.
  String get argumentName => 'arg';

  /// The return type for the visitor methods.
  ///
  /// The generated visitor will implement
  /// `Visitor1<$returnType, $argumentType>`.
  String get returnType;

  @override
  void generateHeader(AstModel astModel, StringBuffer sb) {
    sb.writeln('''
import 'package:kernel/ast.dart';

$visitorComment
class $visitorName$visitorTypeParameters
    implements Visitor1<$returnType, $argumentType> {''');
  }

  @override
  void generateFooter(AstModel astModel, StringBuffer sb) {
    sb.writeln('''
}''');
  }

  @override
  void generateVisit(AstModel astModel, AstClass astClass, StringBuffer sb) {
    sb.writeln('''
  @override
  ${returnType} visit${astClass.name}(
      ${astClass.name} node, $argumentType $argumentName) {''');
    handleVisit(astModel, astClass, sb);
    sb.writeln('''
  }''');
  }

  /// Generates the body of a `visitX` visitor method of [astClass].
  void handleVisit(AstModel astModel, AstClass astClass, StringBuffer sb) {}

  @override
  void generateVisitReference(
      AstModel astModel, AstClass astClass, StringBuffer sb) {
    sb.writeln('''
  @override
  ${returnType} visit${astClass.name}Reference(
      ${astClass.name} node, $argumentType $argumentName) {''');
    handleVisitReference(astModel, astClass, sb);
    sb.writeln('''
  }''');
  }

  /// Generates the body of a `visitXReference` visitor method of [astClass].
  void handleVisitReference(
      AstModel astModel, AstClass astClass, StringBuffer sb) {}
}

/// Strategy for creating an empty `Visitor1<void,Null>` implementation.
abstract class VoidVisitor1Strategy extends Visitor1Strategy {
  const VoidVisitor1Strategy();

  @override
  String get visitorName => 'VoidVisitor';

  @override
  String get returnType => 'void';

  @override
  String get argumentType => 'Null';

  @override
  String get argumentName => '_';
}
