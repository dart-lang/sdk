// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A test library that should fail because there is a plural with text
/// before the plural expression.
library embedded_plural_text_before;

import "package:intl/intl.dart";

embeddedPlural(n) => Intl.message(
    "There are ${Intl.plural(n, zero: 'nothing', one: 'one', other: 'some')}.",
    name: 'embeddedPlural',
    desc: 'An embedded plural',
    args: [n]);
