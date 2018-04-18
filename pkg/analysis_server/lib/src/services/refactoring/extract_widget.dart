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
import 'package:analysis_server/src/services/search/element_visitors.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analysis_server/src/utilities/flutter.dart';
import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/source.dart' show SourceRange;
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// [ExtractWidgetRefactoring] implementation.
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

  /// If [offset] is in a class, the node of this class, `null` otherwise.
  ClassDeclaration _enclosingClassNode;

  /// If [offset] is in a class, the element of this class, `null` otherwise.
  ClassElement _enclosingClassElement;

  /// The [CompilationUnitMember] that encloses the [offset].
  CompilationUnitMember _enclosingUnitMember;

  /// The widget creation expression to extract.
  InstanceCreationExpression _expression;

  /// The method returning widget to extract.
  MethodDeclaration _method;

  /// The parameters for the new widget class - referenced fields of the
  /// [_enclosingClassElement], local variables referenced by [_expression],
  /// and [_method] parameters.
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

    _enclosingUnitMember = (_expression ?? _method).getAncestor(
        (n) => n is CompilationUnitMember && n.parent is CompilationUnit);

    result.addStatus(await _initializeParameters());
    result.addStatus(await _initializeClasses());

    return result;
  }

  @override
  RefactoringStatus checkName() {
    RefactoringStatus result = new RefactoringStatus();

    // Validate the name.
    result.addStatus(validateClassName(name));

    // Check for duplicate declarations.
    if (!result.hasFatalError) {
      visitLibraryTopLevelElements(libraryElement, (element) {
        if (hasDisplayName(element, name)) {
          String message = format(
              "Library already declares {0} with name '{1}'.",
              getElementKindName(element),
              name);
          result.addError(message, newLocation_fromElement(element));
        }
      });
    }

    return result;
  }

  @override
  Future<SourceChange> createChange() async {
    String file = unitElement.source.fullName;
    var changeBuilder = new DartChangeBuilder(sessionHelper.session);
    await changeBuilder.addFileEdit(file, (builder) {
      if (_expression != null) {
        builder.addReplacement(range.node(_expression), (builder) {
          _writeWidgetInstantiation(builder);
        });
      } else {
        _removeMethodDeclaration(builder);
        _replaceInvocationsWithInstantiations(builder);
      }

      _writeWidgetDeclaration(builder);
    });
    return changeBuilder.sourceChange;
  }

  @override
  bool isAvailable() {
    return !_checkSelection().hasFatalError;
  }

  @override
  bool requiresPreview() => false;

  /// Checks if [offset] is a widget creation expression that can be extracted.
  RefactoringStatus _checkSelection() {
    AstNode node = new NodeLocator2(offset, offset).searchWithin(unit);

    // Find the enclosing class.
    _enclosingClassNode = node?.getAncestor((n) => n is ClassDeclaration);
    _enclosingClassElement = _enclosingClassNode?.element;

    // new MyWidget(...)
    InstanceCreationExpression newExpression = identifyNewExpression(node);
    if (isWidgetCreation(newExpression)) {
      _expression = newExpression;
      return new RefactoringStatus();
    }

    // Widget myMethod(...) { ... }
    for (; node != null; node = node.parent) {
      if (node is FunctionBody) {
        break;
      }
      if (node is MethodDeclaration) {
        DartType returnType = node.returnType?.type;
        if (isWidgetType(returnType) && node.body != null) {
          _method = node;
          return new RefactoringStatus();
        }
        break;
      }
    }

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

  /// Prepare referenced local variables and fields, that should be turned
  /// into the widget class fields and constructor parameters.
  Future<RefactoringStatus> _initializeParameters() async {
    _ParametersCollector collector;
    if (_expression != null) {
      SourceRange localRange = range.node(_expression);
      collector = new _ParametersCollector(_enclosingClassElement, localRange);
      _expression.accept(collector);
    }
    if (_method != null) {
      SourceRange localRange = range.node(_method);
      collector = new _ParametersCollector(_enclosingClassElement, localRange);
      _method.body.accept(collector);
    }

    _parameters
      ..clear()
      ..addAll(collector.parameters);

    // We added fields, now add the method parameters.
    if (_method != null) {
      for (var parameter in _method.parameters.parameters) {
        if (parameter is NormalFormalParameter) {
          _parameters.add(new _Parameter(
              parameter.identifier.name, parameter.element.type,
              isMethodParameter: true));
        }
      }
    }

    return collector.status;
  }

  /// Remove the [_method] declaration.
  void _removeMethodDeclaration(DartFileEditBuilder builder) {
    SourceRange methodRange = range.node(_method);
    SourceRange linesRange =
        utils.getLinesRange(methodRange, skipLeadingEmptyLines: true);
    builder.addDeletion(linesRange);
  }

  /// Replace invocations of the [_method] with instantiations of the new
  /// widget class.
  void _replaceInvocationsWithInstantiations(DartFileEditBuilder builder) {
    var collector = new _MethodInvocationsCollector(_method.element);
    _enclosingClassNode.accept(collector);
    for (var invocation in collector.invocations) {
      builder.addReplacement(
        range.startEnd(invocation, invocation.argumentList.leftParenthesis),
        (builder) {
          builder.write('new $name(');

          // Insert field references.
          for (var parameter in _parameters) {
            if (parameter.isMethodParameter) {
              break;
            }
            if (parameter != _parameters.first) {
              builder.write(', ');
            }
            builder.write(parameter.name);
          }

          // Separate references to fields and method arguments.
          if (_parameters.isNotEmpty &&
              invocation.argumentList.arguments.isNotEmpty) {
            builder.write(', ');
          }
        },
      );
    }
  }

  /// Write declaration of the new widget class.
  void _writeWidgetDeclaration(DartFileEditBuilder builder) {
    builder.addInsertion(_enclosingUnitMember.end, (builder) {
      builder.writeln();
      builder.writeln();
      builder.writeClassDeclaration(
        name,
        superclass: classStatelessWidget.type,
        membersWriter: () {
          if (_parameters.isNotEmpty) {
            // Add the fields for the parameters.
            for (var parameter in _parameters) {
              builder.write('  ');
              builder.writeFieldDeclaration(parameter.name,
                  isFinal: true, type: parameter.type);
              builder.writeln();
            }
            builder.writeln();

            // Add the constructor.
            builder.write('  ');
            builder.writeConstructorDeclaration(name,
                fieldNames: _parameters.map((e) => e.name).toList());
            builder.writeln();
            builder.writeln();
          }

          // Widget build(BuildContext context) { ... }
          builder.writeln('  @override');
          builder.write('  ');
          builder.writeFunctionDeclaration(
            'build',
            returnType: classWidget.type,
            parameterWriter: () {
              builder.writeParameter('context', type: classBuildContext.type);
            },
            bodyWriter: () {
              if (_expression != null) {
                String indentOld = utils.getLinePrefix(_expression.offset);
                String indentNew = '    ';

                String code = utils.getNodeText(_expression);
                code = code.replaceAll(
                    new RegExp('^$indentOld', multiLine: true), indentNew);

                builder.writeln('{');

                builder.write('    return ');
                builder.write(code);
                builder.writeln(';');

                builder.writeln('  }');
              } else {
                String code = utils.getNodeText(_method.body);
                builder.writeln(code);
              }
            },
          );
        },
      );
    });
  }

  /// Write instantiation of the new widget class.
  void _writeWidgetInstantiation(DartEditBuilder builder) {
    builder.write('new $name(');

    for (var parameter in _parameters) {
      if (parameter != _parameters.first) {
        builder.write(', ');
      }
      builder.write(parameter.name);
    }

    builder.write(')');
  }
}

class _MethodInvocationsCollector extends RecursiveAstVisitor<void> {
  final MethodElement methodElement;
  final List<MethodInvocation> invocations = [];

  _MethodInvocationsCollector(this.methodElement);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName?.staticElement == methodElement) {
      invocations.add(node);
    } else {
      super.visitMethodInvocation(node);
    }
  }
}

class _Parameter {
  final String name;
  final DartType type;

  /// Whether the parameter is a parameter of the method being extracted.
  final bool isMethodParameter;

  _Parameter(this.name, this.type, {this.isMethodParameter = false});
}

class _ParametersCollector extends RecursiveAstVisitor<void> {
  final ClassElement enclosingClass;
  final SourceRange expressionRange;

  final RefactoringStatus status = new RefactoringStatus();
  final Set<Element> uniqueElements = new Set<Element>();
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
      if (!expressionRange.contains(element.nameOffset)) {
        if (node.inSetterContext()) {
          status.addError("Write to '$elementName' cannot be extracted.");
        } else {
          type = element.type;
        }
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

    if (type != null && uniqueElements.add(element)) {
      parameters.add(new _Parameter(elementName, type));
    }
  }

  /// Return `true` if the given [element] is a member of the [enclosingClass]
  /// or one of its supertypes, interfaces, or mixins.
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
