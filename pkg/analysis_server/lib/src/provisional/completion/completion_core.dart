// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// [AbortCompletion] is thrown when the current completion request
/// should be aborted because either
/// the source changed since the request was made, or
/// a new completion request was received.
class AbortCompletion {}

/// Indicates a preference for completion text.
///
/// When preference is [insert], completion text may be tailored on the basis
/// of being more likely to be inserted than replaced.
///
/// For example, completing at ^ in the code below will produce named arg labels
/// with a trailing `: ,` if the preference is for [insert], but without for
/// [replace].
///
///     @A(^two: '2')
///
/// This value should generally be provided based on the default behaviour of
/// a given client/protocol (or could take user preferences into account).
enum CompletionPreference {
  insert,
  replace,
}
