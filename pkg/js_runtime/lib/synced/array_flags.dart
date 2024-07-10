// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Values for the 'array flags' property that is attached to native JSArray and
/// typed data objects to encode restrictions.
///
/// We encode the restrictions as two bits - one for potentially growable
/// objects that are restricted to be fixed length, and a second for objects
/// with potentially modifiable contents that are restricted to have
/// unmodifiable contents. We only use three combinations (00 = growable, 01 =
/// fixed-length, 11 = unmodifiable), since the core List class does not have a
/// variant that is an 'append-only' list (would be 10).
///
/// We use the same scheme for typed data so that the same check works for
/// modifiability checks for `a[i] = v` when `a` is a JSarray or Uint8Array.
///
/// `const` JSArray values are tagged with an additional bit for future use in
/// avoiding copying. We could also use the `const` bit for unmodifiable typed
/// data for which there in no modifable view of the underlying buffer.
///
/// Given the absense of append-only lists, we could have used a more
/// numerically compact scheme (0 = growable, 1 = fixed-length, 2 =
/// unmodifiable, 3 = const). This compact scheme requires comparison
///
///     if (x.flags > 0)
///
/// rather than mask-testing
///
///     if (x.flags & 1)
///
/// The unrestricted flags (0) are usually encoded as a missing property, i.e.,
/// `undefined`, which is converted to NaN for '>', but converted to the more
/// comfortable '0' for '&'. We hope that there is less to go potentially go
/// wrong with JavaScript engine slow paths with the bitmask.
class ArrayFlags {
  /// Value of array flags that marks a JSArray as being fixed-length. This is
  /// not used on typed data since that is always fixed-length.
  static const int fixedLength = fixedLengthCheck;

  /// Value of array flags that marks a JSArray or typed-data object as
  /// unmodifiable. Includes the 'fixed-length' bit, since all unmodifiable
  /// lists are also fixed length.
  static const int unmodifiable = fixedLengthCheck | unmodifiableCheck;

  /// Value of array flags that marks a JSArray as a constant (transitively
  /// unmodifiable).
  static const int constant =
      fixedLengthCheck | unmodifiableCheck | constantCheck;

  /// Default value of array flags when there is no flags property. This value
  /// is not stored on the flags property.
  static const int none = 0;

  /// Bit to check for fixed-length JSArray.
  static const int fixedLengthCheck = 1;

  /// Bit to check for unmodifiable JSArray and typed data.
  static const int unmodifiableCheck = 2;

  /// Bit to check for constant JSArray.
  static const int constantCheck = 4;
}
