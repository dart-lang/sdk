// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class DOMWrapperBase {
  final _ptr;

  DOMWrapperBase._wrap(this._ptr) {
  	// We should never be creating duplicate wrappers.
  	assert(_ptr.dartObjectLocalStorage === null);
	_ptr.dartObjectLocalStorage = this;
  }
}

