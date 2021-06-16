// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

/// Whether insecure connections to [host] are allowed.
///
/// This API is deprecated and always returns true. See
/// https://github.com/flutter/flutter/issues/72723 for more details.
///
/// [host] must be a [String] or [InternetAddress].
///
/// If any of the domain policies match [host], the matching policy will make
/// the decision. If multiple policies apply, the top matching policy makes the
/// decision. If none of the domain policies match, the embedder default is
/// used.
///
/// Loopback addresses are always allowed.
@Deprecated("See https://github.com/flutter/flutter/issues/54448 for followup")
bool isInsecureConnectionAllowed(dynamic host) {
  return true;
}
