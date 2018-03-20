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
import 'package:analyzer/src/dart/analysis/session_helper.dart';
import 'package:analyzer/src/generated/source.dart';
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
   * The widget creation expression to extract.
   */
  InstanceCreationExpression _expression;

//  /**
//   * The method returning widget to extract.
//   */
//  MethodDeclaration _method;

  List<RefactoringMethodParameter> _parameters = [];
  Map<String, RefactoringMethodParameter> _parametersMap = {};
  Map<String, List<SourceRange>> _parameterReferencesMap = {};

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

      builder.addReplacement(range.node(_expression), (builder) {
        builder.write('new $name()');
      });

      builder.addInsertion(enclosingUnitMember.end, (builder) {
        builder.writeln();
        builder.writeln();
        builder.writeClassDeclaration(name,
            superclass: classStatelessWidget.type, membersWriter: () {
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
   * Prepares information about used variables, which should be turned into
   * parameters.
   */
  Future<RefactoringStatus> _initializeParameters() async {
    _parameters.clear();
    _parametersMap.clear();
    _parameterReferencesMap.clear();
    // TODO(scheglov) Find parameters.
    return new RefactoringStatus();
  }
}
