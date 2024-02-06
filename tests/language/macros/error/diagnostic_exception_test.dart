// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// SharedOptions=--enable-experiment=macros

import 'impl/throw_diagnostic_exception_macro.dart';

@ThrowDiagnosticException(atTypeDeclaration: 'B', withMessage: 'failed here')
class A {}

class B {}
//    ^
// [analyzer] COMPILE_TIME_ERROR.MACRO_ERROR
// [cfe] failed here
