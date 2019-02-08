// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'available_suggestions_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GetSuggestionAvailableTest);
  });
}

@reflectiveTest
class GetSuggestionAvailableTest extends AvailableSuggestionsBase {
  test_dart() async {
    addTestFile('');
    var mathSet = await waitForSetWithUri('dart:math');
    var asyncSet = await waitForSetWithUri('dart:async');

    var results = await _getSuggestions(testFile, 0);
    expect(results.includedSuggestionKinds, isNotEmpty);

    var includedIdSet = results.includedSuggestionSets.map((set) => set.id);
    expect(includedIdSet, contains(mathSet.id));
    expect(includedIdSet, contains(asyncSet.id));
  }

  test_inHtml() async {
    newFile('/home/test/lib/a.dart', content: 'class A {}');

    var path = convertPath('/home/test/doc/a.html');
    newFile(path, content: '<html></html>');

    await waitResponse(
      CompletionGetSuggestionsParams(path, 0).toRequest('0'),
    );
    expect(serverErrors, isEmpty);
  }

  Future<CompletionResultsParams> _getSuggestions(
    String path,
    int offset,
  ) async {
    var response = CompletionGetSuggestionsResult.fromResponse(
      await waitResponse(
        CompletionGetSuggestionsParams(path, offset).toRequest('0'),
      ),
    );
    return await waitForGetSuggestions(response.id);
  }
}
