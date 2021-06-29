// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.type_test_registry;

import '../common.dart';
import '../elements/entities.dart';
import '../js_backend/runtime_types.dart'
    show RuntimeTypesChecks, RuntimeTypesChecksBuilder;
import '../options.dart';
import '../universe/codegen_world_builder.dart';

/// TODO(joshualitt): Delete this class and store [RuntimeTypeChecks] on
/// [CodeEmitterTask] directly.
class TypeTestRegistry {
  final CompilerOptions _options;

  RuntimeTypesChecks _rtiChecks;

  TypeTestRegistry(this._options);

  RuntimeTypesChecks get rtiChecks {
    assert(
        _rtiChecks != null,
        failedAt(NO_LOCATION_SPANNABLE,
            "RuntimeTypesChecks has not been computed yet."));
    return _rtiChecks;
  }

  Iterable<ClassEntity> get rtiNeededClasses {
    return rtiChecks.requiredClasses;
  }

  void computeRequiredTypeChecks(
      RuntimeTypesChecksBuilder rtiChecksBuilder, CodegenWorld codegenWorld) {
    _rtiChecks = rtiChecksBuilder.computeRequiredChecks(codegenWorld, _options);
  }
}
