// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'package:dart_style/dart_style.dart' show DartFormatter;

import 'ast_model.dart';

/// Generates a visitor library into [sb] based on [astModel] and [strategy].
String generateVisitor(AstModel astModel, VisitorStrategy strategy) {
  StringBuffer sb = new StringBuffer();
  strategy.generateHeader(astModel, sb);

  void addVisitNode(AstClass astClass) {
    switch (astClass.kind) {
      case AstClassKind.root:
      case AstClassKind.inner:
        if (astClass.hasVisitMethod) {
          strategy.generateDefaultVisit(astClass, sb);
        }
        for (AstClass subclass in astClass.subclasses) {
          addVisitNode(subclass);
        }
        break;
      case AstClassKind.public:
      case AstClassKind.named:
      case AstClassKind.declarative:
        if (astClass.hasVisitMethod) {
          strategy.generateVisit(astClass, sb);
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
        if (astClass.hasVisitReferenceMethod) {
          strategy.generateDefaultVisitReference(astClass, sb);
        }
        for (AstClass subclass in astClass.subclasses) {
          addVisitReference(subclass);
        }
        break;
      case AstClassKind.public:
      case AstClassKind.named:
      case AstClassKind.declarative:
        if (astClass.hasVisitReferenceMethod) {
          strategy.generateVisitReference(astClass, sb);
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
  result = new DartFormatter().format(result);
  return result;
}

/// Strategy for generating a visitor in its own library based on an [AstModel].
abstract class VisitorStrategy {
  const VisitorStrategy();

  /// Generates the header of the visitor library, including preamble, imports
  /// and visitor class declaration start.
  void generateHeader(AstModel astModel, StringBuffer sb);

  /// Generates a `defaultX` visitor method for [astClass].
  void generateDefaultVisit(AstClass astClass, StringBuffer sb);

  /// Generates a `visitX` visitor method for [astClass].
  void generateVisit(AstClass astClass, StringBuffer sb);

  /// Generates a `defaultXReference` visitor method for [astClass].
  void generateDefaultVisitReference(AstClass astClass, StringBuffer sb);

  /// Generates a `visitXReference` visitor method for [astClass].
  void generateVisitReference(AstClass astClass, StringBuffer sb);

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

  void generateHeader(AstModel astModel, StringBuffer sb) {
    sb.writeln('''
import 'package:kernel/ast.dart';

class $visitorName$visitorTypeParameters implements Visitor<$returnType> {''');
  }

  void generateFooter(AstModel astModel, StringBuffer sb) {
    sb.writeln('''
}''');
  }

  @override
  void generateDefaultVisit(AstClass astClass, StringBuffer sb) {
    sb.writeln('''
  @override
  ${returnType} default${astClass.name}(
      ${astClass.name} node) {''');
    handleDefaultVisit(astClass, sb);
    sb.writeln('}');
  }

  /// Generates the body of a `defaultX` visitor method of [astClass].
  void handleDefaultVisit(AstClass astClass, StringBuffer sb) {}

  @override
  void generateVisit(AstClass astClass, StringBuffer sb) {
    sb.writeln('''
  @override
  ${returnType} visit${astClass.name}(
      ${astClass.name} node) {''');
    handleVisit(astClass, sb);
    sb.writeln('}');
  }

  /// Generates the body of a `visitX` visitor method of [astClass].
  void handleVisit(AstClass astClass, StringBuffer sb) {}

  @override
  void generateDefaultVisitReference(AstClass astClass, StringBuffer sb) {
    sb.writeln(''''
  @override
  ${returnType} default${astClass.name}Reference(
      '${astClass.name} node) {''');
    handleDefaultVisitReference(astClass, sb);
    sb.writeln('}');
  }

  /// Generates the body of a `defaultXReference` visitor method of [astClass].
  void handleDefaultVisitReference(AstClass astClass, StringBuffer sb) {}

  @override
  void generateVisitReference(AstClass astClass, StringBuffer sb) {
    sb.writeln('''
  @override
  ${returnType} visit${astClass.name}Reference(
      ${astClass.name} node) {''');
    handleVisitReference(astClass, sb);
    sb.writeln('}');
  }

  /// Generates the body of a `visitXReference` visitor method of [astClass].
  void handleVisitReference(AstClass astClass, StringBuffer sb) {}
}

/// Strategy for creating an empty `Visitor<void>` implementation.
class VoidVisitor0Strategy extends Visitor0Strategy {
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

  void generateHeader(AstModel astModel, StringBuffer sb) {
    sb.writeln('''
import 'package:kernel/ast.dart';

class $visitorName$visitorTypeParameters
    implements Visitor1<$returnType, $argumentType> {''');
  }

  void generateFooter(AstModel astModel, StringBuffer sb) {
    sb.writeln('''
}''');
  }

  @override
  void generateDefaultVisit(AstClass astClass, StringBuffer sb) {
    sb.writeln('''
  @override
  ${returnType} default${astClass.name}(
      ${astClass.name} node, $argumentType $argumentName) {''');
    handleDefaultVisit(astClass, sb);
    sb.writeln('''
  }''');
  }

  /// Generates the body of a `defaultX` visitor method of [astClass].
  void handleDefaultVisit(AstClass astClass, StringBuffer sb) {}

  @override
  void generateVisit(AstClass astClass, StringBuffer sb) {
    sb.writeln('''
  @override
  ${returnType} visit${astClass.name}(
      ${astClass.name} node, $argumentType $argumentName) {''');
    handleVisit(astClass, sb);
    sb.writeln('''
  }''');
  }

  /// Generates the body of a `visitX` visitor method of [astClass].
  void handleVisit(AstClass astClass, StringBuffer sb) {}

  @override
  void generateDefaultVisitReference(AstClass astClass, StringBuffer sb) {
    sb.writeln('''
  @override
  ${returnType} default${astClass.name}Reference(
      ${astClass.name} node, $argumentType $argumentName) {''');
    handleDefaultVisitReference(astClass, sb);
    sb.writeln('''
  }''');
  }

  /// Generates the body of a `defaultXReference` visitor method of [astClass].
  void handleDefaultVisitReference(AstClass astClass, StringBuffer sb) {}

  @override
  void generateVisitReference(AstClass astClass, StringBuffer sb) {
    sb.writeln('''
  @override
  ${returnType} visit${astClass.name}Reference(
      ${astClass.name} node, $argumentType $argumentName) {''');
    handleVisitReference(astClass, sb);
    sb.writeln('''
  }''');
  }

  /// Generates the body of a `visitXReference` visitor method of [astClass].
  void handleVisitReference(AstClass astClass, StringBuffer sb) {}
}

/// Strategy for creating an empty `Visitor1<void,Null>` implementation.
class VoidVisitor1Strategy extends Visitor1Strategy {
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
