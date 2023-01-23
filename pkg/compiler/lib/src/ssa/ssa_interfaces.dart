// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common/codegen.dart' show CodegenResult;
import '../elements/entities.dart';
import '../js_backend/backend.dart' show FunctionCompiler;

abstract class SsaFunctionCompiler implements FunctionCompiler {
  @override
  CodegenResult compile(MemberEntity member);
}
