// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:pub_semver/pub_semver.dart';

import '../dart/resolution/driver_resolution.dart';

/// A base class designed to be used by tests of the hints produced by the
/// SdkConstraintVerifier.
class SdkConstraintVerifierTest extends DriverResolutionTest {
  /// Verify that the [errorCodes] are produced if the [source] is analyzed in
  /// a context that specifies the minimum SDK version to be [version].
  verifyVersion(String version, String source,
      {List<ErrorCode> errorCodes}) async {
    driver.configure(
        analysisOptions: analysisOptions
          ..sdkVersionConstraint = VersionConstraint.parse(version));
    await assertErrorsInCode(source, errorCodes ?? []);
  }
}
