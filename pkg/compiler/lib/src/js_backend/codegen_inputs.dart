// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../tracer.dart' show Tracer;
import 'checked_mode_helpers.dart';
import 'namer.dart';
import 'runtime_types_codegen.dart';
import 'runtime_types_new.dart';

/// Holds resources only used during code generation.
class CodegenInputs {
  final CheckedModeHelpers checkedModeHelpers = CheckedModeHelpers();
  final RuntimeTypesSubstitutions rtiSubstitutions;
  final RecipeEncoder rtiRecipeEncoder;
  final Tracer tracer;
  final FixedNames fixedNames;

  CodegenInputs(this.rtiSubstitutions, this.rtiRecipeEncoder, this.tracer,
      this.fixedNames);
}
