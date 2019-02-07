// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'available_suggestions_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvailableSuggestionSetsTest);
  });
}

@reflectiveTest
class AvailableSuggestionSetsTest extends AvailableSuggestionsBase {
  test_notifications_whenFileChanges() async {
    var path = '/home/test/lib/a.dart';
    var uriStr = 'package:test/a.dart';

    // No file initially, so no set.
    expect(uriToSetMap.keys, isNot(contains(uriStr)));

    // Create the file, should get the set.
    {
      newFile(path, content: r'''
class A {}
''');
      var set = await waitForSetWithUri(uriStr);
      expect(set.items.map((d) => d.label), contains('A'));
    }

    // Update the file, should get the updated set.
    {
      newFile(path, content: r'''
class B {}
''');
      removeSet(uriStr);
      var set = await waitForSetWithUri(uriStr);
      expect(set.items.map((d) => d.label), contains('B'));
    }

    // Delete the file, the set should be removed.
    deleteFile(path);
    waitForSetWithUriRemoved(uriStr);
  }
}
