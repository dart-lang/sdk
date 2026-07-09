// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import '../base/compiler_context.dart';
import '../base/lookup_result.dart';
import '../base/messages.dart';
import '../builder/formal_parameter_builder.dart';
import '../kernel/internal_ast.dart';
import '../type_inference/inference_results.dart';
import '../type_inference/object_access_target.dart';

abstract class ExpressionEvaluationHelper {
  ExpressionInferenceResult? visitInternalVariableGet(
    InternalVariableGet node,
    DartType typeContext,
    ProblemReporting problemReporting,
    CompilerContext compilerContext,
    Uri fileUri,
  );

  ExpressionInferenceResult? visitInternalVariableSet(
    InternalVariableSet node,
    DartType typeContext,
    ProblemReporting problemReporting,
    CompilerContext compilerContext,
    Uri fileUri,
  );

  OverwrittenInterfaceMember? overwriteFindInterfaceMember({
    required ObjectAccessTarget target,
    required DartType receiverType,
    required Name name,
    required bool setter,
    bool? isImplicitThis,
  });

  /// Register a lookup result for a name that can be returned via a lookup on
  /// [additionalScopeLookup].
  void registerAdditionalScopeLookupResult(
    String name,
    FormalParameterBuilder result,
  );

  /// If the alternative is an error, return if there is another result for a
  /// scope lookup on [name].
  LookupResult? additionalScopeLookup(String name);
}

// Coverage-ignore(suite): Not run.
class OverwrittenInterfaceMember {
  final ObjectAccessTarget target;
  final Name name;

  new({required this.target, required this.name});
}
