// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/experiments/flags.dart' as shared;
import 'package:_fe_analyzer_shared/src/parser/experimental_features.dart'
    as parser;
import 'package:front_end/src/api_prototype/experimental_flags.dart' as cfe;

class ExperimentalFeaturesFromFlags implements parser.ExperimentalFeatures {
  Map<cfe.ExperimentalFlag, bool> _experimentalFlags;

  ExperimentalFeaturesFromFlags(this._experimentalFlags);

  @override
  bool isExperimentEnabled(shared.ExperimentalFlag flag) {
    return cfe.isExperimentEnabled(
      cfe.fromSharedExperimentalFlag(flag),
      explicitExperimentalFlags: _experimentalFlags,
    );
  }
}
