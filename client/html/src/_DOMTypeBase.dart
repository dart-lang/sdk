// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _DOMTypeBase {
  final _ptr;

  _DOMTypeBase._wrap(this._ptr) {
  	// We should never be creating duplicate wrappers.
  	// TODO(jacobr): this boolean value is evaluated outside of the assert
  	// to work around a mysterious and flaky bug in tip of trunk versions of
  	// chrome.
  	bool hasExistingWrapper = _ptr.dartObjectLocalStorage === null;
  	assert(hasExistingWrapper);
	  _ptr.dartObjectLocalStorage = this;
  }
}

/** This function is provided for unittest purposes only. */
unwrapDomObject(_DOMTypeBase wrapper) {
  return wrapper._ptr;
}