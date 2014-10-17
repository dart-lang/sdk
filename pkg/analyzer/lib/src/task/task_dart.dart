// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library engine.task.dart;

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * A `BuildUnitElementTask` builds a compilation unit element for a single
 * compilation unit.
 */
class BuildUnitElementTask extends AnalysisTask {
  /**
   * The source for which an element model will be built.
   */
  final Source source;

  /**
   * The source of the library in which an element model will be built.
   */
  final Source library;

  /**
   * The compilation unit from which an element model will be built.
   */
  final CompilationUnit unit;

  /**
   * The element model that was built.
   */
  CompilationUnitElement unitElement;

  /**
   * Initialize a newly created task to build a compilation unit element for
   * the given [source] in the given [library] based on the compilation [unit]
   * that was parsed.
   */
  BuildUnitElementTask(InternalAnalysisContext context, this.source, this.library, this.unit)
      : super(context);

  @override
  accept(AnalysisTaskVisitor visitor) {
    return visitor.visitBuildUnitElementTask(this);
  }

  /**
   * Return the compilation unit from which the element model was built.
   */
  CompilationUnit getCompilationUnit() {
    return unit;
  }

  /**
   * Return the source that is to be parsed.
   */
  Source getSource() {
    return source;
  }

  /**
   * Return the compilation unit element that was produced, or `null` if the
   * task has not yet been performed or if an exception occurred.
   */
  CompilationUnitElement getUnitElement() {
    return unitElement;
  }

  @override
  void internalPerform() {
    CompilationUnitBuilder builder = new CompilationUnitBuilder();
    unitElement = builder.buildCompilationUnit(source, unit);
  }

  @override
  String get taskDescription {
    if (source == null) {
      return "build the unit element model for null source";
    }
    return "build the unit element model for " + source.fullName;
  }
}
