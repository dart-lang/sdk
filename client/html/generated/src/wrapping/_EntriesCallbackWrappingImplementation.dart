// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class EntriesCallbackWrappingImplementation extends DOMWrapperBase implements EntriesCallback {
  EntriesCallbackWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool handleEvent(EntryArray entries) {
    return _ptr.handleEvent(LevelDom.unwrap(entries));
  }
}
