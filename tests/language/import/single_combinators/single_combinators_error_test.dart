// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=single-combinators

import "import_helper.dart" as p show a hide b;
//                                      ^^^^
// [analyzer] SYNTACTIC_ERROR.MULTIPLE_COMBINATORS
// [cfe] At most one 'show' or 'hide' combinator can be used on an import or export directive.

import "import_helper.dart" show a show b;
//                                 ^^^^
// [analyzer] SYNTACTIC_ERROR.MULTIPLE_COMBINATORS
// [cfe] At most one 'show' or 'hide' combinator can be used on an import or export directive.

import "import_helper.dart" show a hide b;
//                                 ^^^^
// [analyzer] SYNTACTIC_ERROR.MULTIPLE_COMBINATORS
// [cfe] At most one 'show' or 'hide' combinator can be used on an import or export directive.

import "import_helper.dart" hide a hide b;
//                                 ^^^^
// [analyzer] SYNTACTIC_ERROR.MULTIPLE_COMBINATORS
// [cfe] At most one 'show' or 'hide' combinator can be used on an import or export directive.

import "import_helper.dart" hide a show b;
//                                 ^^^^
// [analyzer] SYNTACTIC_ERROR.MULTIPLE_COMBINATORS
// [cfe] At most one 'show' or 'hide' combinator can be used on an import or export directive.

// Trailing import to ensure dart format keeps comments attached to the import above.
import "import_helper.dart";

main() {}
