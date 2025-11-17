// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Top-level Zone-related declarations.
// Anything public that is not implementing `Zone`, `ZoneDelegate`
// or `ZoneSpecification`.
part of 'dart:async';

/// A no-argument function, like the argument to `Zone.run`.
typedef ZoneCallback<R> = R Function();

/// A one-argument function, like the argument to `Zone.runUnary`.
typedef ZoneUnaryCallback<R, T> = R Function(T);

/// A two-argument function, like the argument to `Zone.runBinary`.
typedef ZoneBinaryCallback<R, T1, T2> = R Function(T1, T2);

/// Runs [body] in its own zone.
///
/// Creates a new zone using [Zone.fork] based on [zoneSpecification] and
/// [zoneValues], then runs [body] in that zone and returns the result.
///
/// Example use:
/// ```dart
/// var secret = "arglebargle"; // Or a random generated string.
/// var result = runZoned(
///     () async {
///       await Future.delayed(Duration(seconds: 5), () {
///         print("${Zone.current[#_secret]} glop glyf");
///       });
///     },
///     zoneValues: {#_secret: secret},
///     zoneSpecification:
///         ZoneSpecification(print: (Zone self, parent, zone, String value) {
///       if (value.contains(Zone.current[#_secret] as String)) {
///         value = "--censored--";
///       }
///       parent.print(zone, value);
///     }));
/// secret = ""; // Erase the evidence.
/// await result; // Wait for asynchronous computation to complete.
/// ```
/// The new zone intercepts `print` and stores a value under the private
/// symbol `#_secret`. The secret is available from the new [Zone] object,
/// which is the [Zone.current] for the body,
/// and is also the first, `self`, parameter to the `print` handler function.
///
/// If the [ZoneSpecification.handleUncaughtError] is set, or the deprecated
/// [onError] callback is passed, the created zone will be an _error zone_.
/// Asynchronous errors in futures never cross zone boundaries between zones
/// with a different [Zone.errorZone].
/// A consequence of that behavior can be that a [Future] which completes as an
/// error in the created zone will seem to never complete when used from a zone
/// that belongs to a different error zone.
/// Multiple attempts to use the future in a zone where the error is
/// inaccessible will cause the error to be reported *again* in it's original
/// error zone.
///
/// See [runZonedGuarded] in place of using the deprected [onError] argument.
/// If [onError] is provided this function also tries to catch and handle
/// synchronous errors from [body], but may throw an error anyway returning
/// `null` if the generic argument [R] is not nullable.
R runZoned<R>(
  R body(), {
  Map<Object?, Object?>? zoneValues,
  ZoneSpecification? zoneSpecification,
  @Deprecated("Use runZonedGuarded instead") Function? onError,
}) {
  if (onError != null) {
    // TODO: Remove this when code have been migrated off using [onError].
    if (onError is! void Function(Object, StackTrace)) {
      if (onError is void Function(Object)) {
        var originalOnError = onError;
        onError = (Object error, StackTrace stack) => originalOnError(error);
      } else {
        throw ArgumentError.value(
          onError,
          "onError",
          "Must be Function(Object) or Function(Object, StackTrace)",
        );
      }
    }
    return runZonedGuarded(
          body,
          onError,
          zoneSpecification: zoneSpecification,
          zoneValues: zoneValues,
        )
        as R;
  }
  return _runZoned<R>(body, zoneValues, zoneSpecification);
}

/// Runs [body] in its own error zone.
///
/// Creates a new zone using [Zone.fork] based on [zoneSpecification] and
/// [zoneValues], then runs [body] in that zone and returns the result.
///
/// The [onError] function is used *both* to handle asynchronous errors
/// by overriding [ZoneSpecification.handleUncaughtError] in [zoneSpecification],
/// if any, *and* to handle errors thrown synchronously by the call to [body].
///
/// If an error occurs synchronously in [body],
/// then throwing in the [onError] handler
/// makes the call to `runZonedGuarded` throw that error,
/// and otherwise the call to `runZonedGuarded` returns `null`.
///
/// The created zone will always be an _error zone_.
/// Asynchronous errors in futures never cross zone boundaries between zones
/// with a different [Zone.errorZone].
/// A consequence of that behavior can be that a [Future] which completes as an
/// error in the created zone will seem to never complete when used from a zone
/// that belongs to a different error zone.
/// Multiple attempts to use the future in a zone where the error is
/// inaccessible will cause the error to be reported *again* in it's original
/// error zone.
R? runZonedGuarded<R>(
  R body(),
  void onError(Object error, StackTrace stack), {
  Map<Object?, Object?>? zoneValues,
  ZoneSpecification? zoneSpecification,
}) {
  _Zone parentZone = Zone._current;
  HandleUncaughtErrorHandler errorHandler =
      (
        Zone self,
        ZoneDelegate parent,
        Zone zone,
        Object error,
        StackTrace stackTrace,
      ) {
        try {
          parentZone.runBinary(onError, error, stackTrace);
        } catch (e, s) {
          if (identical(e, error)) {
            parent.handleUncaughtError(zone, error, stackTrace);
          } else {
            parent.handleUncaughtError(zone, e, s);
          }
        }
      };
  if (zoneSpecification == null) {
    zoneSpecification = ZoneSpecification(handleUncaughtError: errorHandler);
  } else {
    zoneSpecification = ZoneSpecification.from(
      zoneSpecification,
      handleUncaughtError: errorHandler,
    );
  }
  try {
    return _runZoned<R>(body, zoneValues, zoneSpecification);
  } catch (error, stackTrace) {
    onError(error, stackTrace);
  }
  return null;
}

/// Runs [body] in a new zone based on [zoneValues] and [specification].
R _runZoned<R>(
  R body(),
  Map<Object?, Object?>? zoneValues,
  ZoneSpecification? specification,
) => Zone.current
    .fork(specification: specification, zoneValues: zoneValues)
    .run<R>(body);
