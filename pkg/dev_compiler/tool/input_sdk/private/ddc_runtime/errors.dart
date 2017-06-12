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

/// Throw an exception on `is` checks that would return an unsound answer in
/// non-strong mode Dart.
///
/// For example `x is List<int>` where `x = <Object>['hello']`.
///
/// These checks behave correctly in strong mode (they return false), however,
/// they will produce a different answer if run on a platform without strong
/// mode. As a debugging feature, these checks can be configured to throw, to
/// avoid seeing different behavior between modes.
///
/// (There are many other ways that different `is` behavior can be observed,
/// however, even with this flag. The most obvious is due to lack of reified
/// generic type parameters. This affects generic functions and methods, as
/// well as generic types when the type parameter was inferred. Setting this
/// flag to `true` will not catch these differences in behavior..)
void failForWeakModeIsChecks(bool flag) {
  JS('', 'dart.__failForWeakModeIsChecks = #', flag);
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

throwAssertionError([String message()]) {
  if (JS('bool', 'dart.__trapRuntimeErrors')) JS('', 'debugger');
  throw message != null
      ? new AssertionErrorWithMessage(message())
      : new AssertionError();
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
