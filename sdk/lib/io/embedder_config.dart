// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

/// Embedder-specific, fine-grained dart:io configuration.
///
/// This class contains per-Isolate flags that an embedder can set to put
/// fine-grained limitations on what process-visible operations Isolates are
/// permitted to use (e.g. exit()). By default, the whole dart:io API is
/// enabled. When a disallowed operation is attempted, an `UnsupportedError` is
/// thrown.
abstract class _EmbedderConfig {
  /// The Isolate may set Directory.current.
  static bool _mayChdir = true;

  /// The Isolate may call exit().
  static bool _mayExit = true;

  // The Isolate may set Stdin.echoMode.
  static bool _maySetEchoMode = true;

  // The Isolate may set Stdin.lineMode.
  static bool _maySetLineMode = true;

  /// The Isolate may call sleep().
  static bool _maySleep = true;

  // TODO(zra): Consider adding:
  // - an option to disallow modifying SecurityContext.defaultContext
  // - an option to disallow closing stdout and stderr.
}
