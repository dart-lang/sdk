// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Platform;

const Set<String> _known = {
  // Currently there's no live experiments.
};

Set<String> getExperimentEnvironment() {
  Set<String> enabled = {};
  Map<String, String> environment = Platform.environment;
  for (String experiment in _known) {
    if (environment[experiment] == "true") {
      enabled.add(experiment);
    }
  }
  return enabled;
}
