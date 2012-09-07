// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

Window get window {
  return _NativeDomGlobalProperties.getWindow();
}

// TODO(vsm): Remove when prefixes are supported.
Window get dom_window {
  return _NativeDomGlobalProperties.getWindow();
}

Document get document {
  return _NativeDomGlobalProperties.getDocument();
}

class _NativeDomGlobalProperties {
  static Window getWindow() native;
  static Document getDocument() native;
}
