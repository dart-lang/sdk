// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import 'type_schema.dart';

abstract class CfeInferenceStrategy {
  DartType createTypeContextForMethodInvocationReceiver({
    required String methodName,
    required DartType methodInvocationTypeContext,
  });

  DartType createTypeContextForPropertyGetReceiver({
    required String propertyName,
    required DartType propertyGetTypeContext,
  });
}

class CfeTrivialTypeInferenceStrategy implements CfeInferenceStrategy {
  @override
  DartType createTypeContextForMethodInvocationReceiver({
    required String methodName,
    required DartType methodInvocationTypeContext,
  }) {
    return const UnknownType();
  }

  @override
  DartType createTypeContextForPropertyGetReceiver({
    required String propertyName,
    required DartType propertyGetTypeContext,
  }) {
    return const UnknownType();
  }
}

// Coverage-ignore(suite): Not run.
class CfeReceiverTypeInferenceStrategy implements CfeInferenceStrategy {
  @override
  DartType createTypeContextForMethodInvocationReceiver({
    required String methodName,
    required DartType methodInvocationTypeContext,
  }) {
    return new LookupStructuralContextType(
      lookupName: methodName,
      lookupType: new InvocationStructuralContextType(
        returnType: methodInvocationTypeContext,
      ),
    );
  }

  @override
  DartType createTypeContextForPropertyGetReceiver({
    required String propertyName,
    required DartType propertyGetTypeContext,
  }) {
    return new LookupStructuralContextType(
      lookupName: propertyName,
      lookupType: propertyGetTypeContext,
    );
  }
}
