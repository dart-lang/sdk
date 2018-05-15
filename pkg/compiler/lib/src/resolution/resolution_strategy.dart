// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.resolution_strategy;

import '../common.dart';
import '../common/resolution.dart';
import '../common/work.dart';
import '../common_elements.dart';
import '../compiler.dart';
import '../elements/elements.dart';
import '../elements/entities.dart';
import '../enqueue.dart';
import '../js_backend/mirrors_data.dart';

/// Builder that creates work item necessary for the resolution of a
/// [MemberElement].
class ResolutionWorkItemBuilder extends WorkItemBuilder {
  final Resolution _resolution;

  ResolutionWorkItemBuilder(this._resolution);

  @override
  WorkItem createWorkItem(MemberElement element) {
    assert(element.isDeclaration, failedAt(element));
    if (element.isMalformed) return null;

    assert(element is AnalyzableElement,
        failedAt(element, 'Element $element is not analyzable.'));
    return _resolution.createWorkItem(element);
  }
}

class ResolutionMirrorsData extends MirrorsDataImpl {
  ResolutionMirrorsData(Compiler compiler,
      ElementEnvironment elementEnvironment, CommonElements commonElements)
      : super(compiler, elementEnvironment, commonElements);

  @override
  bool isClassInjected(covariant ClassElement cls) => cls.isInjected;

  @override
  bool isClassResolved(covariant ClassElement cls) => cls.isResolved;

  @override
  void forEachConstructor(
      covariant ClassElement cls, void f(ConstructorEntity constructor)) {
    cls.constructors.forEach((Element _constructor) {
      ConstructorElement constructor = _constructor;
      f(constructor);
    });
  }
}
