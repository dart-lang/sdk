// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VM implementation of Uri.
typedef Uri _UriBaseClosure();

Uri _unsupportedUriBase() {
  throw new UnsupportedError("'Uri.base' is not supported");
}

// _uriBaseClosure can be overwritten by the embedder to supply a different
// value for Uri.base.
_UriBaseClosure _uriBaseClosure = _unsupportedUriBase;

patch class Uri {
  static final bool _isWindowsCached = _isWindowsPlatform;

  /* patch */ static bool get _isWindows => _isWindowsCached;

  /* patch */ static Uri get base => _uriBaseClosure();

  static bool get _isWindowsPlatform native "Uri_isWindowsPlatform";
}
