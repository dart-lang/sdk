// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.backend_api;

import '../common/resolution.dart' show ResolutionImpact;
import '../universe/world_impact.dart' show WorldImpact;

/// Target-specific transformation for resolution world impacts.
///
/// This processes target-agnostic [ResolutionImpact]s and creates [WorldImpact]
/// in which backend/target specific impact data is added, for example: if
/// certain feature is used that requires some helper code from the backend
/// libraries, this will be included by the impact transformer.
class ImpactTransformer {
  /// Transform the [ResolutionImpact] into a [WorldImpact] adding the
  /// backend dependencies for features used in [worldImpact].
  WorldImpact transformResolutionImpact(ResolutionImpact worldImpact) {
    return worldImpact;
  }
}
