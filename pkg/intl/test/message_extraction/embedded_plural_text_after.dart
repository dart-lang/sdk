// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A test library that should fail because there is a plural with text
/// following the plural expression.
library embedded_plural_text_after;

import "package:intl/intl.dart";

embeddedPlural2(n) => Intl.message(
    "${Intl.plural(n, zero: 'none', one: 'one', other: 'some')} plus text.",
    name: 'embeddedPlural2',
    desc: 'An embedded plural',
    args: [n]);