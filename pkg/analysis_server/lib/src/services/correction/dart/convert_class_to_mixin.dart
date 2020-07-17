// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertClassToMixin extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.CONVERT_CLASS_TO_MIXIN;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var classDeclaration = node.thisOrAncestorOfType<ClassDeclaration>();
    if (classDeclaration == null) {
      return;
    }
    if (selectionOffset > classDeclaration.name.end ||
        selectionEnd < classDeclaration.classKeyword.offset) {
      return;
    }
    if (classDeclaration.members
        .any((member) => member is ConstructorDeclaration)) {
      return;
    }
    var finder = _SuperclassReferenceFinder();
    classDeclaration.accept(finder);
    var referencedClasses = finder.referencedClasses;
    var superclassConstraints = <InterfaceType>[];
    var interfaces = <InterfaceType>[];

    var classElement = classDeclaration.declaredElement;
    for (var type in classElement.mixins) {
      if (referencedClasses.contains(type.element)) {
        superclassConstraints.add(type);
      } else {
        interfaces.add(type);
      }
    }
    var extendsClause = classDeclaration.extendsClause;
    if (extendsClause != null) {
      if (referencedClasses.length > superclassConstraints.length) {
        superclassConstraints.insert(0, classElement.supertype);
      } else {
        interfaces.insert(0, classElement.supertype);
      }
    }
    interfaces.addAll(classElement.interfaces);

    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(
          range.startStart(
              classDeclaration.abstractKeyword ?? classDeclaration.classKeyword,
              classDeclaration.leftBracket), (builder) {
        builder.write('mixin ');
        builder.write(classDeclaration.name.name);
        builder.writeTypeParameters(
            classDeclaration.declaredElement.typeParameters);
        builder.writeTypes(superclassConstraints, prefix: ' on ');
        builder.writeTypes(interfaces, prefix: ' implements ');
        builder.write(' ');
      });
    });
  }

  /// Return an instance of this class. Used as a tear-off in `AssistProcessor`.
  static ConvertClassToMixin newInstance() => ConvertClassToMixin();
}

/// A visitor used to find all of the classes that define members referenced via
/// `super`.
class _SuperclassReferenceFinder extends RecursiveAstVisitor<void> {
  final List<ClassElement> referencedClasses = <ClassElement>[];

  _SuperclassReferenceFinder();

  @override
  void visitSuperExpression(SuperExpression node) {
    var parent = node.parent;
    if (parent is BinaryExpression) {
      _addElement(parent.staticElement);
    } else if (parent is IndexExpression) {
      _addElement(parent.staticElement);
    } else if (parent is MethodInvocation) {
      _addIdentifier(parent.methodName);
    } else if (parent is PrefixedIdentifier) {
      _addIdentifier(parent.identifier);
    } else if (parent is PropertyAccess) {
      _addIdentifier(parent.propertyName);
    }
    return super.visitSuperExpression(node);
  }

  void _addElement(Element element) {
    if (element is ExecutableElement) {
      var enclosingElement = element.enclosingElement;
      if (enclosingElement is ClassElement) {
        referencedClasses.add(enclosingElement);
      }
    }
  }

  void _addIdentifier(SimpleIdentifier identifier) {
    _addElement(identifier.staticElement);
  }
}
