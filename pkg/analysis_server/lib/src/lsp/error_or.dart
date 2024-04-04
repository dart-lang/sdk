// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';

ErrorOr<R> cancelled<R>() =>
    error(ErrorCodes.RequestCancelled, 'Request was cancelled');

ErrorOr<R> error<R>(ErrorCodes code, String message, [String? data]) =>
    ErrorOr<R>.error(ResponseError(code: code, message: message, data: data));

ErrorOr<R> failure<R>(ErrorOr<dynamic> error) => ErrorOr<R>.error(error.error);

ErrorOr<R> success<R>(R t) => ErrorOr<R>.success(t);

/// A specialised version of [Either2] for working with results or errors in
/// LSP handlers.
///
/// Contains a helpers to assist in chaining operations while propagating errors.
class ErrorOr<T> extends Either2<ResponseError, T> {
  ErrorOr.error(super.error) : super.t1();

  ErrorOr.success(super.result) : super.t2();

  /// Returns the error or throws if object is not an error. Check [isError]
  /// before accessing [error].
  ResponseError get error {
    return map((error) => error, (_) => throw 'Value is not an error');
  }

  /// Returns true if this object is an error, false if it is a result. Prefer
  /// [mapResult] instead of checking this flag if [errors] will simply be
  /// propagated as-is.
  bool get isError => map((error) => true, (_) => false);

  /// Returns the result or throws if this object is an error. Check [isError]
  /// before accessing [result]. It is valid for this to return null is the
  /// object does not represent an error but the resulting value was null.
  T get result {
    return map((_) => throw 'Value is not a result', (result) => result);
  }

  /// Returns the result or `null` if this object is an error.
  T? get resultOrNull {
    return map((_) => null, (result) => result);
  }

  /// If this object is a result, maps [result] through [f], otherwise returns
  /// a new error object representing [error].
  FutureOr<ErrorOr<N>> mapResult<N>(FutureOr<ErrorOr<N>> Function(T) f) {
    return isError
        // Re-wrap the error using our new type arg
        ? ErrorOr<N>.error(error)
        // Otherwise call the map function
        : f(result);
  }

  /// Converts a [List<ErrorOr<T>>] into an [ErrorOr<List<T>>]. If any of the
  /// items represents an error, that error will be returned. Otherwise, the
  /// list of results will be returned in a success response.
  static ErrorOr<List<T>> all<T>(Iterable<ErrorOr<T>> items) {
    final results = <T>[];
    for (final item in items) {
      if (item.isError) {
        return failure(item);
      }
      results.add(item.result);
    }
    return success(results);
  }
}
