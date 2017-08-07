// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
part of dart._runtime;

// We need to set these properties while the sdk is only partially initialized
// so we cannot use regular Dart fields.
// The default values for these properties are set when the global_ final field
// in runtime.dart is initialized.

// Override, e.g., for testing
void trapRuntimeErrors(bool flag) {
  JS('', 'dart.__trapRuntimeErrors = #', flag);
}

void ignoreWhitelistedErrors(bool flag) {
  JS('', 'dart.__ignoreWhitelistedErrors = #', flag);
}

void ignoreAllErrors(bool flag) {
  JS('', 'dart.__ignoreAllErrors = #', flag);
}

throwCastError(object, actual, type) {
  var found = typeName(actual);
  var expected = typeName(type);
  if (JS('bool', 'dart.__trapRuntimeErrors')) JS('', 'debugger');
  throw new CastErrorImplementation(object, found, expected);
}

throwTypeError(object, actual, type) {
  var found = typeName(actual);
  var expected = typeName(type);
  if (JS('bool', 'dart.__trapRuntimeErrors')) JS('', 'debugger');
  throw new TypeErrorImplementation(object, found, expected);
}

throwStrongModeCastError(object, actual, type) {
  var found = typeName(actual);
  var expected = typeName(type);
  if (JS('bool', 'dart.__trapRuntimeErrors')) JS('', 'debugger');
  throw new StrongModeCastError(object, found, expected);
}

throwStrongModeTypeError(object, actual, type) {
  var found = typeName(actual);
  var expected = typeName(type);
  if (JS('bool', 'dart.__trapRuntimeErrors')) JS('', 'debugger');
  throw new StrongModeTypeError(object, found, expected);
}

throwUnimplementedError(String message) {
  if (JS('bool', 'dart.__trapRuntimeErrors')) JS('', 'debugger');
  throw new UnimplementedError(message);
}

assertFailed(message) {
  if (JS('bool', 'dart.__trapRuntimeErrors')) JS('', 'debugger');
  throw new AssertionErrorImpl(message);
}

throwCyclicInitializationError([String message]) {
  if (JS('bool', 'dart.__trapRuntimeErrors')) JS('', 'debugger');
  throw new CyclicInitializationError(message);
}

throwNullValueError() {
  // TODO(vsm): Per spec, we should throw an NSM here.  Technically, we ought
  // to thread through method info, but that uglifies the code and can't
  // actually be queried ... it only affects how the error is printed.
  if (JS('bool', 'dart.__trapRuntimeErrors')) JS('', 'debugger');
  throw new NoSuchMethodError(
      null, new Symbol('<Unexpected Null Value>'), null, null, null);
}

throwNoSuchMethodError(Object receiver, Symbol memberName,
    List positionalArguments, Map<Symbol, dynamic> namedArguments) {
  if (JS('bool', 'dart.__trapRuntimeErrors')) JS('', 'debugger');
  throw new NoSuchMethodError(
      receiver, memberName, positionalArguments, namedArguments);
}
