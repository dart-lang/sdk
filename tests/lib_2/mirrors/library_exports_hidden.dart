// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library library_exports_hidden;

export 'library_imports_a.dart' hide somethingFromA, somethingFromBoth;
export 'library_imports_b.dart' hide somethingFromB;

var somethingFromHidden;
