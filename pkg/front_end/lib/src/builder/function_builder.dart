// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'function_signature.dart';
import 'member_builder.dart';

/// Common base class for constructor and procedure builders.
abstract class FunctionBuilder implements MemberBuilder {
  FunctionSignature get signature;
}
