// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library code_generator_dependencies;

import '../js_backend.dart';
import '../../dart2jslib.dart';
import '../../js_emitter/js_emitter.dart';
import '../../js/js.dart' as js;
import '../../constants/values.dart';

/// Encapsulates the dependencies of the function-compiler to the compiler,
/// backend and emitter.
// TODO(sigurdm): Should be refactored when we have a better feeling for the
// interface.
class Glue {
  final Compiler _compiler;

  JavaScriptBackend get _backend => _compiler.backend;

  CodeEmitterTask get _emitter => _backend.emitter;

  Glue(this._compiler);

  js.Expression constantReference(ConstantValue value) {
    return _emitter.constantReference(value);
  }

}
