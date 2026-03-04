// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/messages/diagnostic.dart' as diag;

import '../messages/codes.dart';
import 'flags.dart';

/// Returns the message used to report that [experimentalFlag] feature is not
/// enabled.
Message getExperimentNotEnabledMessage(ExperimentalFlag experimentalFlag) {
  if (experimentalFlag.isEnabledByDefault) {
    return diag.experimentNotEnabled.withArguments(
      featureName: experimentalFlag.name,
      enabledVersion: experimentalFlag.experimentEnabledVersion.toText(),
    );
  } else {
    return diag.experimentNotEnabledOffByDefault.withArguments(
      featureName: experimentalFlag.name,
    );
  }
}
