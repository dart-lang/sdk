// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/utilities/utilities.dart';

import '../dart/resolution/context_collection_resolution.dart';

/// A base class designed to be used by tests of the hints produced by the
/// SdkConstraintVerifier.
class SdkConstraintVerifierTest extends PubPackageResolutionTest {
  /// Verify that the [expectedDiagnostics] are produced if the [source] is
  /// analyzed in a context that uses given SDK [constraints].
  Future<void> verifyVersion(
    String constraints,
    String source, {
    List<ExpectedDiagnostic> expectedDiagnostics = const [],
  }) async {
    writeTestPackagePubspecYamlFile(
      pubspecYamlContent(sdkVersion: constraints),
    );

    await assertErrorsInCode(source, expectedDiagnostics);
  }
}
