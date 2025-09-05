// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import '../base/constant_context.dart';
import '../codes/cfe_codes.dart' show LocatedMessage, Message;

abstract class InferenceHelper {
  Uri get uri;

  ConstantContext get constantContext;

  InvalidExpression buildProblem(
    Message message,
    int charOffset,
    int length, {
    List<LocatedMessage>? context,
    bool errorHasBeenReported = false,
    Expression? expression,
  });

  LocatedMessage? checkArgumentsForType(
    FunctionType function,
    Arguments arguments,
    int offset,
  );

  Expression? checkStaticArguments({
    required Member target,
    required Arguments arguments,
    required int fileOffset,
  });

  void addProblem(
    Message message,
    int charOffset,
    int length, {
    List<LocatedMessage>? context,
    bool wasHandled = false,
  });

  Expression wrapInProblem(
    Expression expression,
    Message message,
    int fileOffset,
    int length, {
    List<LocatedMessage>? context,
    bool? errorHasBeenReported,
    bool includeExpression = true,
  });

  String superConstructorNameForDiagnostics(String name);

  String constructorNameForDiagnostics(String name, {String? className});

  /// Ensure that the containing library of the [member] has been loaded.
  ///
  /// This is for instance important for lazy dill library builders where this
  /// method has to be called to ensure that
  /// a) The library has been fully loaded (and for instance any internal
  ///    transformation needed has been performed); and
  /// b) The library is correctly marked as being used to allow for proper
  ///    'dependency pruning'.
  void ensureLoaded(Member? member);
}
