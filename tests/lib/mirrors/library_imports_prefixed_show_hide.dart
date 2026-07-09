// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library library_imports_prefixed_show_hide;

import 'library_imports_a.dart' as prefixa show somethingFromA;
import 'library_imports_b.dart' as prefixb hide somethingFromB;

var somethingFromPrefixed;
