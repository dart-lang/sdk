// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.resolution_strategy;

import '../common_elements.dart';
import '../compiler.dart';
import '../elements/elements.dart';
import '../elements/entities.dart';
import '../js_backend/mirrors_data.dart';

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
