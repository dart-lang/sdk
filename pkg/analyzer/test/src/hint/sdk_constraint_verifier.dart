// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';

import '../../generated/resolver_test_case.dart';
import '../../generated/test_support.dart';

/// A base class designed to be used by tests of the hints produced by an
/// SdkConstraintVerifier.
class SdkConstraintVerifierTest extends ResolverTestCase {
  bool get enableNewAnalysisDriver => true;

  verifyVersion(String version, String source,
      {List<ErrorCode> errorCodes}) async {
    newFile('/pubspec.yaml', content: '''
environment:
  sdk: ^$version
''');
    TestAnalysisResult result = await computeTestAnalysisResult(source);
    GatheringErrorListener listener = new GatheringErrorListener();
    listener.addAll(result.errors);
    if (errorCodes == null) {
      listener.assertNoErrors();
    } else {
      listener.assertErrorsWithCodes(errorCodes);
    }
  }

  File newFile(String path, {String content = ''}) {
    // Copied from ResourceProviderMixin because ResolverTestCase does not apply
    // that mixin on this branch.
    String convertedPath = resourceProvider.convertPath(path);
    return resourceProvider.newFile(convertedPath, content);
  }
}
