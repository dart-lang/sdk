// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analyzer/src/utilities/cancellation.dart';
import 'package:meta/meta.dart';

ErrorOr<R> cancelled<R>([CancellationToken? token]) {
  var code = ErrorCodes.RequestCancelled;
  var reason = 'Request was cancelled';

  if (token is CancelableToken) {
    if (token.cancellationCode case var cancellationCode?) {
      code = ErrorCodes(cancellationCode);
    }
    if (token.cancellationReason case var cancellationReason?) {
      reason = cancellationReason;
    }
  }

  return error(code, reason);
}

ErrorOr<R> error<R>(ErrorCodes code, String message, [String? data]) =>
    ErrorOr<R>.error(ResponseError(code: code, message: message, data: data));

ErrorOr<R> failure<R>(ErrorOr<Object?> error) => ErrorOr<R>.error(error.error);

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
  @visibleForTesting
  ResponseError get error {
    return map(
      (error) => error,
      (_) => throw StateError('Value is not an error'),
    );
  }

  /// Returns the error or `null` if this object is not an error.
  ResponseError? get errorOrNull {
    return isError ? error : null;
  }

  /// Returns true if this object is an error, false if it is a result. Prefer
  /// [mapResult] instead of checking this flag if [errors] will simply be
  /// propagated as-is.
  bool get isError => map((_) => true, (_) => false);

  /// Returns true if this object is aa result, false if it is an error. Prefer
  /// [ifResult] or [mapResult] instead to read/operate on errors.
  bool get isResult => map((_) => false, (_) => true);

  /// Returns the result or throws if this object is an error. Check [isError]
  /// before accessing [result]. It is valid for this to return null is the
  /// object does not represent an error but the resulting value was null.
  @visibleForTesting
  T get result {
    return map(
      (_) => throw StateError('Value is not a result'),
      (result) => result,
    );
  }

  /// Returns the result or `null` if this object is an error.
  T? get resultOrNull {
    return isError ? null : result;
  }

  /// If this object is an error, calls [f] with the error.
  void ifError(void Function(ResponseError) f) {
    if (isError) {
      f(error);
    }
  }

  /// If this object is a result, calls [f] with the value.
  void ifResult(void Function(T) f) {
    if (!isError) {
      f(result);
    }
  }

  /// If this object is a result, maps [result] through [f], otherwise returns
  /// a new error object representing [error].
  Future<ErrorOr<N>> mapResult<N>(Future<ErrorOr<N>> Function(T) f) async {
    return isError
        // Re-wrap the error using our new type arg
        ? ErrorOr<N>.error(error)
        // Otherwise call the map function
        : await f(result);
  }

  /// Sync version of [mapResult].
  ErrorOr<N> mapResultSync<N>(ErrorOr<N> Function(T) f) {
    return isError
        // Re-wrap the error using our new type arg
        ? ErrorOr<N>.error(error)
        // Otherwise call the map function
        : f(result);
  }
}

extension ErrorOrRecord2Extension<T1, T2> on (ErrorOr<T1>, ErrorOr<T2>) {
  void ifResults(void Function(T1, T2) f) {
    if ($1.isError || $2.isError) {
      return;
    }
    f($1.result, $2.result);
  }

  /// If all parts of the record are results, maps them through [f], otherwise
  /// returns a new error object representing the first error.
  Future<ErrorOr<R>> mapResults<R>(
    Future<ErrorOr<R>> Function(T1, T2) f,
  ) async {
    if ($1.isError) {
      return failure($1);
    }
    if ($2.isError) {
      return failure($2);
    }
    return await f($1.result, $2.result);
  }

  /// Sync version of [mapResults].
  ErrorOr<R> mapResultsSync<R>(ErrorOr<R> Function(T1, T2) f) {
    if ($1.isError) {
      return failure($1);
    }
    if ($2.isError) {
      return failure($2);
    }
    return f($1.result, $2.result);
  }
}

extension ErrorOrRecord3Extension<T1, T2, T3>
    on (ErrorOr<T1>, ErrorOr<T2>, ErrorOr<T3>) {
  void ifResults(void Function(T1, T2, T3) f) {
    if ($1.isError || $2.isError || $3.isError) {
      return;
    }
    f($1.result, $2.result, $3.result);
  }

  /// If all parts of the record are results, maps them through [f], otherwise
  /// returns a new error object representing the first error.
  Future<ErrorOr<R>> mapResults<R>(
    Future<ErrorOr<R>> Function(T1, T2, T3) f,
  ) async {
    if ($1.isError) {
      return failure($1);
    }
    if ($2.isError) {
      return failure($2);
    }
    if ($3.isError) {
      return failure($3);
    }
    return await f($1.result, $2.result, $3.result);
  }

  /// Sync version of [mapResults].
  ErrorOr<R> mapResultsSync<R>(ErrorOr<R> Function(T1, T2, T3) f) {
    if ($1.isError) {
      return failure($1);
    }
    if ($2.isError) {
      return failure($2);
    }
    if ($3.isError) {
      return failure($3);
    }
    return f($1.result, $2.result, $3.result);
  }
}

extension ErrorOrRecord4Extension<T1, T2, T3, T4>
    on (ErrorOr<T1>, ErrorOr<T2>, ErrorOr<T3>, ErrorOr<T4>) {
  void ifResults(void Function(T1, T2, T3, T4) f) {
    if ($1.isError || $2.isError || $3.isError || $4.isError) {
      return;
    }
    f($1.result, $2.result, $3.result, $4.result);
  }

  /// If all parts of the record are results, maps them through [f], otherwise
  /// returns a new error object representing the first error.
  Future<ErrorOr<R>> mapResults<R>(
    Future<ErrorOr<R>> Function(T1, T2, T3, T4) f,
  ) async {
    if ($1.isError) {
      return failure($1);
    }
    if ($2.isError) {
      return failure($2);
    }
    if ($3.isError) {
      return failure($3);
    }
    if ($4.isError) {
      return failure($4);
    }
    return await f($1.result, $2.result, $3.result, $4.result);
  }

  /// Sync version of [mapResults].
  ErrorOr<R> mapResultsSync<R>(ErrorOr<R> Function(T1, T2, T3, T4) f) {
    if ($1.isError) {
      return failure($1);
    }
    if ($2.isError) {
      return failure($2);
    }
    if ($3.isError) {
      return failure($3);
    }
    if ($4.isError) {
      return failure($4);
    }
    return f($1.result, $2.result, $3.result, $4.result);
  }
}

extension IterableErrorOrExtension<T> on Iterable<ErrorOr<T>> {
  /// Converts a [List<ErrorOr<T>>] into an [ErrorOr<List<T>>]. If any of the
  /// items represents an error, that error will be returned. Otherwise, the
  /// list of results will be returned in a success response.
  ErrorOr<List<T>> get errorOrResults {
    var results = <T>[];
    for (var item in this) {
      if (item.isError) {
        return failure(item);
      }
      results.add(item.result);
    }
    return success(results);
  }
}
