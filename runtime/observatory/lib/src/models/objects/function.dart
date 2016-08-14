// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of models;

enum FunctionKind {
  regular,
  closure,
  getter,
  setter,
  constructor,
  implicitGetter,
  implicitSetter,
  implicitStaticFinalGetter,
  irregexpFunction,
  staticInitializer,
  methodExtractor,
  noSuchMethodDispatcher,
  invokeFieldDispatcher,
  collected,
  native,
  stub,
  tag,
  signatureFunction
}

bool isSyntheticFunction(FunctionKind kind) {
  switch (kind) {
    case FunctionKind.collected:
    case FunctionKind.native:
    case FunctionKind.stub:
    case FunctionKind.tag:
      return true;
    default:
      return false;
  }
}

bool isDartFunction(FunctionKind kind) => !isSyntheticFunction(kind);
bool isStubFunction(FunctionKind kind) => kind == FunctionKind.stub;
bool hasDartCode(FunctionKind kind) =>
    isDartFunction(kind) || isStubFunction(kind);

abstract class FunctionRef extends ObjectRef {
  /// The name of this class.
  String get name;

  /// The owner of this function, which can be a LibraryRef, ClassRef,
  /// or a FunctionRef.
  ObjectRef get dartOwner; // owner

  /// Is this function static?
  bool get isStatic;

  /// Is this function const?
  bool get isConst;

  /// The kind of the function.
  FunctionKind get kind;
}

abstract class Function extends Object implements FunctionRef {
  /// The location of this function in the source code. [optional]
  SourceLocation get location;

  /// The compiled code associated with this function. [optional]
  CodeRef get code;
}
