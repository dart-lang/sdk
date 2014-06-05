// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library matcher.error_matchers;

import 'core_matchers.dart';
import 'interfaces.dart';

/// **DEPRECATED**
///
/// Will be removed in the next major release.
// TODO(kevmoo): re-deprecate once 19173 is resolved
//@deprecated
const Matcher isAbstractClassInstantiationError =
  const _AbstractClassInstantiationError();

/// **DEPRECATED**
///
/// Will be removed in the next major release.
// TODO(kevmoo): re-deprecate once 19173 is resolved
//@deprecated
const Matcher throwsAbstractClassInstantiationError =
  const Throws(isAbstractClassInstantiationError);

class _AbstractClassInstantiationError extends TypeMatcher {
  const _AbstractClassInstantiationError() :
  super("AbstractClassInstantiationError");
  bool matches(item, Map matchState) => item is AbstractClassInstantiationError;
}

/// A matcher for ArgumentErrors.
const Matcher isArgumentError = const _ArgumentError();

/// A matcher for functions that throw ArgumentError.
const Matcher throwsArgumentError = const Throws(isArgumentError);

class _ArgumentError extends TypeMatcher {
  const _ArgumentError(): super("ArgumentError");
  bool matches(item, Map matchState) => item is ArgumentError;
}

/// A matcher for ConcurrentModificationError.
const Matcher isConcurrentModificationError =
    const _ConcurrentModificationError();

/// A matcher for functions that throw ConcurrentModificationError.
const Matcher throwsConcurrentModificationError =
  const Throws(isConcurrentModificationError);

class _ConcurrentModificationError extends TypeMatcher {
  const _ConcurrentModificationError(): super("ConcurrentModificationError");
  bool matches(item, Map matchState) => item is ConcurrentModificationError;
}

/// A matcher for CyclicInitializationError.
const Matcher isCyclicInitializationError = const _CyclicInitializationError();

/// A matcher for functions that throw CyclicInitializationError.
const Matcher throwsCyclicInitializationError =
  const Throws(isCyclicInitializationError);

class _CyclicInitializationError extends TypeMatcher {
  const _CyclicInitializationError(): super("CyclicInitializationError");
  bool matches(item, Map matchState) => item is CyclicInitializationError;
}

/// A matcher for Exceptions.
const Matcher isException = const _Exception();

/// A matcher for functions that throw Exception.
const Matcher throwsException = const Throws(isException);

class _Exception extends TypeMatcher {
  const _Exception(): super("Exception");
  bool matches(item, Map matchState) => item is Exception;
}

/// **DEPRECATED**
///
/// Will be removed in the next major release.
// TODO(kevmoo): re-deprecate once 19173 is resolved
//@deprecated
const Matcher isFallThroughError = const _FallThroughError();

/// **DEPRECATED**
///
/// Will be removed in the next major release.
// TODO(kevmoo): re-deprecate once 19173 is resolved
//@deprecated
const Matcher throwsFallThroughError = const Throws(isFallThroughError);

class _FallThroughError extends TypeMatcher {
  const _FallThroughError(): super("FallThroughError");
  bool matches(item, Map matchState) => item is FallThroughError;
}

/// A matcher for FormatExceptions.
const Matcher isFormatException = const _FormatException();

/// A matcher for functions that throw FormatException.
const Matcher throwsFormatException = const Throws(isFormatException);

class _FormatException extends TypeMatcher {
  const _FormatException(): super("FormatException");
  bool matches(item, Map matchState) => item is FormatException;
}

/// A matcher for NoSuchMethodErrors.
const Matcher isNoSuchMethodError = const _NoSuchMethodError();

/// A matcher for functions that throw NoSuchMethodError.
const Matcher throwsNoSuchMethodError = const Throws(isNoSuchMethodError);

class _NoSuchMethodError extends TypeMatcher {
  const _NoSuchMethodError(): super("NoSuchMethodError");
  bool matches(item, Map matchState) => item is NoSuchMethodError;
}

/// A matcher for NullThrownError.
const Matcher isNullThrownError = const _NullThrownError();

/// A matcher for functions that throw NullThrownError.
const Matcher throwsNullThrownError = const Throws(isNullThrownError);

class _NullThrownError extends TypeMatcher {
  const _NullThrownError(): super("NullThrownError");
  bool matches(item, Map matchState) => item is NullThrownError;
}

/// A matcher for RangeErrors.
const Matcher isRangeError = const _RangeError();

/// A matcher for functions that throw RangeError.
const Matcher throwsRangeError = const Throws(isRangeError);

class _RangeError extends TypeMatcher {
  const _RangeError(): super("RangeError");
  bool matches(item, Map matchState) => item is RangeError;
}

/// A matcher for StateErrors.
const Matcher isStateError = const _StateError();

/// A matcher for functions that throw StateError.
const Matcher throwsStateError = const Throws(isStateError);

class _StateError extends TypeMatcher {
  const _StateError(): super("StateError");
  bool matches(item, Map matchState) => item is StateError;
}

/// A matcher for UnimplementedErrors.
const Matcher isUnimplementedError = const _UnimplementedError();

/// A matcher for functions that throw Exception.
const Matcher throwsUnimplementedError = const Throws(isUnimplementedError);

class _UnimplementedError extends TypeMatcher {
  const _UnimplementedError(): super("UnimplementedError");
  bool matches(item, Map matchState) => item is UnimplementedError;
}

/// A matcher for UnsupportedError.
const Matcher isUnsupportedError = const _UnsupportedError();

/// A matcher for functions that throw UnsupportedError.
const Matcher throwsUnsupportedError = const Throws(isUnsupportedError);

class _UnsupportedError extends TypeMatcher {
  const _UnsupportedError(): super("UnsupportedError");
  bool matches(item, Map matchState) => item is UnsupportedError;
}
