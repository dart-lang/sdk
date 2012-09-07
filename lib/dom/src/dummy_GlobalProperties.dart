// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

Window get window => _dummy();

// TODO(vsm): Remove when prefixes are supported.
Window get dom_window => _dummy();

Document get document => _dummy();
