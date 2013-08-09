// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VM implementation of Uri.
patch class Uri {
  static final bool _isWindowsCached = _isWindowsPlatform;

  static bool get _isWindowsPlatform native "Uri_isWindowsPlatform";

  /* patch */ static bool get _isWindows => _isWindowsCached;
}
