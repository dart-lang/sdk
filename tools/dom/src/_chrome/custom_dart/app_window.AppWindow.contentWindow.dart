// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(sashab, sra): Detect whether this is the current window, or an
// external one, and return an appropriately-typed object
WindowBase get contentWindow => JS("Window", "#.contentWindow", this._jsObject);
