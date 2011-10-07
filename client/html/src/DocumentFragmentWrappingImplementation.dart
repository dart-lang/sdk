// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class DocumentFragmentWrappingImplementation extends NodeWrappingImplementation implements DocumentFragment {
  DocumentFragmentWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  factory DocumentFragmentWrappingImplementation() {
    return new DocumentFragmentWrappingImplementation._wrap(
	    dom.document.createDocumentFragment());
  }

  Element query(String selectors) {
    return LevelDom.wrapElement(_ptr.querySelector(selectors));
  }

  ElementList queryAll(String selectors) {
    return LevelDom.wrapElementList(_ptr.querySelectorAll(selectors));
  }
}
