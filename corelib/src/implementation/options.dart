// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class RuntimeOptions implements Options {
  List<String> get arguments() {
    if (_arguments === null) {
      // On first access make a copy of the native arguments.
      _arguments = _nativeArguments.getRange(0, _nativeArguments.length);
    }
    return _arguments;
  }

  List<String> _arguments = null;

  // This arguments singleton is overriden by the embedder if applicable.
  static List<String> _nativeArguments = const [];
}
