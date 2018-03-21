// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/protocol_server.dart' hide Element;
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/services/refactoring/naming_conventions.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/refactoring_internal.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analysis_server/src/utilities/flutter.dart';
import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';
import 'package:analyzer/src/generated/source.dart' show SourceRange;
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/**
 * [ExtractMethodRefactoring] implementation.
 */
class ExtractWidgetRefactoringImpl extends RefactoringImpl
    implements ExtractWidgetRefactoring {
  final SearchEngine searchEngine;
  final AnalysisSessionHelper sessionHelper;
  final CompilationUnit unit;
  final int offset;

  CompilationUnitElement unitElement;
  LibraryElement libraryElement;
  CorrectionUtils utils;

  ClassElement classBuildContext;
  ClassElement classStatefulWidget;
  ClassElement classStatelessWidget;
  ClassElement classWidget;

  @override
  String name;

  @override
  bool stateful = false;

  /**
   * If [offset] is in a class, the element of this class, `null` otherwise.
   */
  ClassElement _enclosingClass;

//  /**
//   * If [_expression] is being extracted, the
//   */
//  SourceRange _expressionRange;

  /**
   * The widget creation expression to extract.
   */
  InstanceCreationExpression _expression;

//  /**
//   * The method returning widget to extract.
//   */
//  MethodDeclaration _method;

  List<_Parameter> _parameters = [];

  ExtractWidgetRefactoringImpl(
      this.searchEngine, AnalysisSession session, this.unit, this.offset)
      : sessionHelper = new AnalysisSessionHelper(session) {
    unitElement = unit.element;
    libraryElement = unitElement.library;
    utils = new CorrectionUtils(unit);
  }

  @override
  String get refactoringName {
    return 'Extract Widget';
  }

  @override
  Future<RefactoringStatus> checkFinalConditions() async {
    RefactoringStatus result = new RefactoringStatus();
    result.addStatus(validateClassName(name));
    return result;
  }

  @override
  Future<RefactoringStatus> checkInitialConditions() async {
    RefactoringStatus result = new RefactoringStatus();

    result.addStatus(_checkSelection());
    if (result.hasFatalError) {
      return result;
    }

    result.addStatus(await _initializeParameters());
    result.addStatus(await _initializeClasses());

    return result;
  }

  @override
  RefactoringStatus checkName() {
    return validateClassName(name);
  }

  @override
  Future<SourceChange> createChange() async {
    String file = unitElement.source.fullName;
    var changeBuilder = new DartChangeBuilder(sessionHelper.session);
    await changeBuilder.addFileEdit(file, (builder) {
      CompilationUnitMember enclosingUnitMember = _expression.getAncestor(
          (n) => n is CompilationUnitMember && n.parent is CompilationUnit);

      // Replace the expression with the new widget creation.
      builder.addReplacement(range.node(_expression), (builder) {
        builder.write('new $name(');

        for (var parameter in _parameters) {
          if (parameter != _parameters.first) {
            builder.write(', ');
          }
          builder.write(parameter.name);
        }

        builder.write(')');
      });

      // Add the new widget class declaration.
      builder.addInsertion(enclosingUnitMember.end, (builder) {
        builder.writeln();
        builder.writeln();
        builder.writeClassDeclaration(name,
            superclass: classStatelessWidget.type, membersWriter: () {
          if (_parameters.isNotEmpty) {
            // Add the fields for the parameters.
            for (var parameter in _parameters) {
              builder.write('  final ');
              builder.writeType(parameter.type);
              builder.write(' ');
              builder.write(parameter.name);
              builder.writeln(';');
            }
            builder.writeln();

            // Add the constructor.
            builder.write('  ');
            builder.writeConstructorDeclaration(name,
                fieldNames: _parameters.map((e) => e.name).toList());
            builder.writeln();
            builder.writeln();
          }

          builder.writeln('  @override');

          builder.write('  ');
          builder.writeType(classWidget.type);
          builder.write(' build(');
          builder.writeType(classBuildContext.type);
          builder.writeln(' context) {');

          String indentOld = utils.getLinePrefix(_expression.offset);
          String indentNew = '    ';

          String widgetSrc = utils.getNodeText(_expression);
          widgetSrc = widgetSrc.replaceAll(
              new RegExp("^$indentOld", multiLine: true), indentNew);

          builder.write('    return ');
          builder.write(widgetSrc);
          builder.writeln(';');

          builder.writeln('  }');
        });
      });
    });
    return changeBuilder.sourceChange;
  }

  @override
  bool requiresPreview() => false;

  /**
   * Checks if [offset] is a widget creation expression that can be extracted.
   */
  RefactoringStatus _checkSelection() {
    AstNode node = new NodeLocator2(offset, offset).searchWithin(unit);

    // Find the enclosing class.
    ClassDeclaration enclosingClassNode =
        node?.getAncestor((n) => n is ClassDeclaration);
    if (enclosingClassNode != null) {
      _enclosingClass = enclosingClassNode.element;
    }

    // new MyWidget(...)
    if (node is InstanceCreationExpression && isWidgetCreation(node)) {
      _expression = node;
      return new RefactoringStatus();
    }

//    // Widget myMethod(...) { ... }
//    for (; node != null; node = node.parent) {
//      if (node is FunctionBody) {
//        break;
//      }
//      if (node is MethodDeclaration) {
//        DartType returnType = node.returnType?.type;
//        if (isWidgetType(returnType)) {
//          _method = node;
//          return new RefactoringStatus();
//        }
//      }
//    }

    // Invalid selection.
    return new RefactoringStatus.fatal(
        'Can only extract a widget expression or a method returning widget.');
  }

  Future<RefactoringStatus> _initializeClasses() async {
    var result = new RefactoringStatus();

    Future<ClassElement> getClass(String name) async {
      const uri = 'package:flutter/widgets.dart';
      var element = await sessionHelper.getClass(uri, name);
      if (element == null) {
        result.addFatalError("Unable to find '$name' in $uri");
      }
      return element;
    }

    classBuildContext = await getClass('BuildContext');
    classStatelessWidget = await getClass('StatelessWidget');
    classStatefulWidget = await getClass('StatefulWidget');
    classWidget = await getClass('Widget');

    return result;
  }

  /**
   * Prepare referenced local variables and fields, that should be turned
   * into the widget class fields and constructor parameters.
   */
  Future<RefactoringStatus> _initializeParameters() async {
    var collector = new _ParametersCollector(
        _enclosingClass, _expression != null ? range.node(_expression) : null);
    _expression.accept(collector);

    _parameters
      ..clear()
      ..addAll(collector.parameters);

    return collector.status;
  }
}

class _Parameter {
  final String name;
  final DartType type;

  _Parameter(this.name, this.type);
}

class _ParametersCollector extends RecursiveAstVisitor<void> {
  final ClassElement enclosingClass;
  final SourceRange expressionRange;

  final RefactoringStatus status = new RefactoringStatus();
  final List<_Parameter> parameters = [];

  List<ClassElement> enclosingClasses;

  _ParametersCollector(this.enclosingClass, this.expressionRange);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    Element element = node.staticElement;
    if (element == null) {
      return;
    }
    String elementName = element.displayName;

    DartType type;
    if (element is MethodElement) {
      if (_isMemberOfEnclosingClass(element)) {
        status.addError(
            "Reference to an enclosing class method cannot be extracted.");
      }
    } else if (element is LocalVariableElement) {
      if (node.inSetterContext() &&
          expressionRange != null &&
          !expressionRange.contains(element.nameOffset)) {
        status.addError("Write to '$elementName' cannot be extracted.");
      } else {
        type = element.type;
      }
    } else if (element is PropertyAccessorElement) {
      PropertyInducingElement field = element.variable;
      if (_isMemberOfEnclosingClass(field)) {
        if (node.inSetterContext()) {
          status.addError("Write to '$elementName' cannot be extracted.");
        } else {
          type = field.type;
        }
      }
    }

    if (type != null) {
      parameters.add(new _Parameter(elementName, type));
    }
  }

  /**
   * Return `true` if the given [element] is a member of the [enclosingClass]
   * or one of its supertypes, interfaces, or mixins.
   */
  bool _isMemberOfEnclosingClass(Element element) {
    if (enclosingClass != null) {
      if (enclosingClasses == null) {
        enclosingClasses = <ClassElement>[]
          ..add(enclosingClass)
          ..addAll(enclosingClass.allSupertypes.map((t) => t.element));
      }
      return enclosingClasses.contains(element.enclosingElement);
    }
    return false;
  }
}
