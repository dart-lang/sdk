// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core' hide MapEntry;

import 'package:kernel/ast.dart';

import 'package:kernel/core_types.dart' show CoreTypes;

import '../fasta_codes.dart' show LocatedMessage, Message;

abstract class InferenceHelper {
  CoreTypes get coreTypes;

  Uri get uri;

  set transformSetLiterals(bool value);

  Expression buildProblem(Message message, int charOffset, int length,
      {List<LocatedMessage> context, bool suppressMessage});

  LocatedMessage checkArgumentsForType(
      FunctionType function, Arguments arguments, int offset);

  void addProblem(Message message, int charOffset, int length,
      {List<LocatedMessage> context, bool wasHandled});

  Expression wrapInProblem(
      Expression expression, Message message, int fileOffset, int length,
      {List<LocatedMessage> context});

  String constructorNameForDiagnostics(String name,
      {String className, bool isSuper});
}
