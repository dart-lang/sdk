// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import '../fasta_codes.dart' show LocatedMessage, Message;

abstract class InferenceHelper {
  Uri get uri;

  InvalidExpression buildProblem(Message message, int charOffset, int length,
      {List<LocatedMessage>? context,
      bool suppressMessage = false,
      Expression? expression});

  LocatedMessage? checkArgumentsForType(
      FunctionType function, Arguments arguments, int offset,
      {bool isExtensionMemberInvocation = false});

  void addProblem(Message message, int charOffset, int length,
      {List<LocatedMessage>? context, bool wasHandled = false});

  Expression wrapInProblem(
      Expression expression, Message message, int fileOffset, int length,
      {List<LocatedMessage>? context});

  String superConstructorNameForDiagnostics(String name);

  String constructorNameForDiagnostics(String name, {String? className});
}
