// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "core_patch.dart";

typedef Uri _UriBaseClosure();

Uri _unsupportedUriBase() {
  throw UnsupportedError("'Uri.base' is not supported");
}

// _uriBaseClosure can be overwritten by the embedder to supply a different
// value for Uri.base.
@pragma("vm:entry-point")
_UriBaseClosure _uriBaseClosure = _unsupportedUriBase;

@patch
class Uri {
  @patch
  static Uri get base => _uriBaseClosure();
}

/// VM implementation of Uri.
@patch
class _Uri {
  static final bool _isWindowsCached = _isWindowsPlatform;

  @pragma("vm:external-name", "Uri_isWindowsPlatform")
  external static bool get _isWindowsPlatform;

  @patch
  static bool get _isWindows => _isWindowsCached;
}
