// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core' hide MapEntry;

import 'package:kernel/ast.dart';

import 'package:kernel/core_types.dart' show CoreTypes;

import '../fasta_codes.dart' show LocatedMessage, Message;

import '../kernel/forest.dart';

abstract class InferenceHelper {
  CoreTypes get coreTypes;

  Uri get uri;

  Forest get forest;

  set transformSetLiterals(bool value);

  Expression buildProblem(Message message, int charOffset, int length,
      {List<LocatedMessage> context, bool suppressMessage});

  LocatedMessage checkArgumentsForType(
      FunctionType function, Arguments arguments, int offset);

  void addProblem(Message message, int charOffset, int length,
      {List<LocatedMessage> context, bool wasHandled});

  Expression wrapInProblem(Expression expression, Message message, int length,
      {List<LocatedMessage> context});

  String constructorNameForDiagnostics(String name,
      {String className, bool isSuper});

  Expression desugarSyntheticExpression(Expression node);

  /// Creates a tear off of the extension instance method [procedure].
  ///
  /// The tear off is created as a function expression that captures the
  /// current `this` value from [extensionThis] and [extensionTypeParameters]
  /// synthetically copied to the extension instance method.
  ///
  /// For instance the declaration of `B.m`:
  ///
  ///     class A<X, Y> {}
  ///     class B<S, T> on A<S, T> {
  ///       void m<U>(U u) {}
  ///     }
  ///
  /// is converted into this top level method:
  ///
  ///     void B<S,T>|m<U>(A<S, T> #this, U u) {}
  ///
  /// and a tear off
  ///
  ///     A<X, Y> a = ...;
  ///     var f = a.m;
  ///
  /// is converted into:
  ///
  ///     A<int, String> a = ...;
  ///     var f = <#U>(#U u) => B<S,T>|m<int,String,#U>(a, u);
  ///
  Expression createExtensionTearOff(
      int fileOffset,
      Procedure procedure,
      VariableDeclaration extensionThis,
      List<TypeParameter> extensionTypeParameters);
}
