// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/base/processed_options.dart';

import '../api_prototype/compiler_options.dart';
import '../base/processed_options.dart';

class InitializedCompilerState {
  final CompilerOptions options;
  final ProcessedOptions processedOpts;

  InitializedCompilerState(this.options, this.processedOpts);
}
