// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/domain_completion.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CompletionListTokenDetailsTest);
  });
}

@reflectiveTest
class CompletionListTokenDetailsTest extends AbstractAnalysisTest {
  CompletionDomainHandler completionHandler;

  Future<CompletionListTokenDetailsResult> getTokenDetails() async {
    var params = CompletionListTokenDetailsParams(testFile);
    await completionHandler.listTokenDetails(params.toRequest('0'));
    var response = await serverChannel.responseController.stream.first;
    return CompletionListTokenDetailsResult.fromResponse(response);
  }

  @override
  void setUp() {
    super.setUp();
    completionHandler = CompletionDomainHandler(server);
  }

  Future<void> test_packageUri() async {
    newFile('/project/.packages', content: '''
project:lib/
''');
    newFile('/project/lib/c.dart', content: '''
class C {}
''');
    addTestFile('''
import 'package:project/c.dart';

C c;
''');
    createProject();
    var result = await getTokenDetails();
    var tokens = result.tokens;
    expect(tokens, hasLength(6));
  }
}
