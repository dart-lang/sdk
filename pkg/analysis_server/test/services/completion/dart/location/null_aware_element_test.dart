// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NullAwareElementTest);
  });
}

@reflectiveTest
class NullAwareElementTest extends AbstractCompletionDriverTest
    with NullAwareElementTestCases {}

mixin NullAwareElementTestCases on AbstractCompletionDriverTest {
  Future<void> test_inList_after_elementsAfter() async {
    await computeSuggestions('''
f() => [?^, 0];
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_inList_after_elementsBefore() async {
    await computeSuggestions('''
f() => [0, ?^];
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_inList_after_elementsBeforeAndAfter() async {
    await computeSuggestions('''
f() => [0, ?^, 0];
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_inList_after_singleElement() async {
    await computeSuggestions('''
f() => [?^];
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_inList_before_elementsAfter() async {
    await computeSuggestions('''
f() => [^?, 0];
''');
    assertResponse(r'''
suggestions
  false
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  const
    kind: keyword
  switch
    kind: keyword
''');
  }

  Future<void> test_inList_before_elementsBefore() async {
    await computeSuggestions('''
f() => [0, ^?];
''');
    assertResponse(r'''
suggestions
  false
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  const
    kind: keyword
  switch
    kind: keyword
''');
  }

  Future<void> test_inList_before_elementsBeforeAndAfter() async {
    await computeSuggestions('''
f() => [0, ^?, 1];
''');
    assertResponse(r'''
suggestions
  false
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  const
    kind: keyword
  switch
    kind: keyword
''');
  }

  Future<void> test_inList_before_SingleElement() async {
    await computeSuggestions('''
f() => [^?];
''');
    assertResponse(r'''
suggestions
  false
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  const
    kind: keyword
  switch
    kind: keyword
''');
  }

  Future<void> test_inMap_inKey_after_withoutValue_entriesAfter() async {
    await computeSuggestions('''
f() => <String, int>{?^, "one": 1};
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_inMap_inKey_after_withoutValue_entriesBefore() async {
    await computeSuggestions('''
f() => <String, int>{"one": 1, ?^};
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void>
      test_inMap_inKey_after_withoutValue_entriesBeforeAndAfter() async {
    await computeSuggestions('''
f() => <String, int>{"one": 1, ?^, "two": 2};
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_inMap_inKey_after_withoutValue_singleEntry() async {
    await computeSuggestions('''
f() => <String, int>{?^};
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_inMap_inKey_after_withValue_entriesAfter() async {
    await computeSuggestions('''
f() => <String, int>{?^: 0, "one": 1};
''');
    assertResponse(r'''
suggestions
  false
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  const
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  switch
    kind: keyword
''');
  }

  Future<void> test_inMap_inKey_after_withValue_entriesBefore() async {
    await computeSuggestions('''
f() => <String, int>{"one": 1, ?^: 0};
''');
    assertResponse(r'''
suggestions
  false
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  const
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  switch
    kind: keyword
''');
  }

  Future<void> test_inMap_inKey_after_withValue_entriesBeforeAndAfter() async {
    await computeSuggestions('''
f() => <String, int>{"one": 1, ?^: 0, "two": 2};
''');
    assertResponse(r'''
suggestions
  false
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  const
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  switch
    kind: keyword
''');
  }

  Future<void> test_inMap_inKey_after_withValue_singleEntry() async {
    await computeSuggestions('''
f() => <String, int>{?^: 0};
''');
    assertResponse(r'''
suggestions
  false
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  const
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  switch
    kind: keyword
''');
  }

  Future<void> test_inMap_inKey_before_withoutValue_entriesAfter() async {
    await computeSuggestions('''
f() => <String, int>{^?, "one": 1};
''');
    assertResponse(r'''
suggestions
  false
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  const
    kind: keyword
  switch
    kind: keyword
''');
  }

  Future<void> test_inMap_inKey_before_withoutValue_entriesBefore() async {
    await computeSuggestions('''
f() => <String, int>{"one": 1, ^?};
''');
    assertResponse(r'''
suggestions
  false
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  const
    kind: keyword
  switch
    kind: keyword
''');
  }

  Future<void>
      test_inMap_inKey_before_withoutValue_entriesBeforeAndAfter() async {
    await computeSuggestions('''
f() => <String, int>{"one": 1, ^?, "two": 2};
''');
    assertResponse(r'''
suggestions
  false
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  const
    kind: keyword
  switch
    kind: keyword
''');
  }

  Future<void> test_inMap_inKey_before_withoutValue_singleEntry() async {
    await computeSuggestions('''
f() => <String, int>{^?};
''');
    assertResponse(r'''
suggestions
  false
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  const
    kind: keyword
  switch
    kind: keyword
''');
  }

  Future<void> test_inMap_inKey_before_withValue_entriesAfter() async {
    await computeSuggestions('''
f() => <String, int>{^?: 0, "one": 1};
''');
    assertResponse(r'''
suggestions
  false
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  if
    kind: keyword
  for
    kind: keyword
  const
    kind: keyword
  switch
    kind: keyword
''');
  }

  Future<void> test_inMap_inKey_before_withValue_entriesBefore() async {
    await computeSuggestions('''
f() => <String, int>{"one": 1, ^?: 0};
''');
    assertResponse(r'''
suggestions
  false
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  if
    kind: keyword
  for
    kind: keyword
  const
    kind: keyword
  switch
    kind: keyword
''');
  }

  Future<void> test_inMap_inKey_before_withValue_entriesBeforeAndAfter() async {
    await computeSuggestions('''
f() => <String, int>{"one": 1, ^?: 0, "two": 2};
''');
    assertResponse(r'''
suggestions
  false
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  if
    kind: keyword
  for
    kind: keyword
  const
    kind: keyword
  switch
    kind: keyword
''');
  }

  Future<void> test_inMap_inKey_before_withValue_singleEntry() async {
    await computeSuggestions('''
f() => <String, int>{^?: 0};
''');
    assertResponse(r'''
suggestions
  false
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  if
    kind: keyword
  for
    kind: keyword
  const
    kind: keyword
  switch
    kind: keyword
''');
  }

  Future<void> test_inMap_inValue_after_entriesAfter() async {
    await computeSuggestions('''
f() => <String, int>{"": ?^, "one": 1};
''');
    assertResponse(r'''
suggestions
  false
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  const
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  switch
    kind: keyword
''');
  }

  Future<void> test_inMap_inValue_after_entriesBefore() async {
    await computeSuggestions('''
f() => <String, int>{"one": 1, "": ?^};
''');
    assertResponse(r'''
suggestions
  false
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  const
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  switch
    kind: keyword
''');
  }

  Future<void> test_inMap_inValue_after_entriesBeforeAndAfter() async {
    await computeSuggestions('''
f() => <String, int>{"one": 1, "": ?^, "two": 2};
''');
    assertResponse(r'''
suggestions
  false
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  const
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  switch
    kind: keyword
''');
  }

  Future<void> test_inMap_inValue_after_singleEntry() async {
    await computeSuggestions('''
f() => <String, int>{"": ?^};
''');
    assertResponse(r'''
suggestions
  false
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  const
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  switch
    kind: keyword
''');
  }

  Future<void> test_inMap_inValue_before_entriesAfter() async {
    await computeSuggestions('''
f() => <String, int>{"": ^?, "one": 1};
''');
    assertResponse(r'''
suggestions
  false
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  const
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  switch
    kind: keyword
''');
  }

  Future<void> test_inMap_inValue_before_entriesBefore() async {
    await computeSuggestions('''
f() => <String, int>{"one": 1, "": ^?};
''');
    assertResponse(r'''
suggestions
  false
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  const
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  switch
    kind: keyword
''');
  }

  Future<void> test_inMap_inValue_before_singleEntry() async {
    await computeSuggestions('''
f() => <String, int>{"": ^?};
''');
    assertResponse(r'''
suggestions
  false
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  const
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  switch
    kind: keyword
''');
  }

  Future<void> test_inMap_inValue_before_withEntriesBeforeAndAfter() async {
    await computeSuggestions('''
f() => <String, int>{"one": 1, "": ^?, "two": 2};
''');
    assertResponse(r'''
suggestions
  false
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  const
    kind: keyword
  for
    kind: keyword
  if
    kind: keyword
  switch
    kind: keyword
''');
  }

  Future<void> test_inSet_after_elementsAfter() async {
    await computeSuggestions('''
f() => <Object?>{?^, 0};
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_inSet_after_elementsBefore() async {
    await computeSuggestions('''
f() => <Object?>{0, ?^};
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_inSet_after_elementsBeforeAndAfter() async {
    await computeSuggestions('''
f() => <Object?>{0, ?^, 1};
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_inSet_after_singleElement() async {
    await computeSuggestions('''
f() => <Object?>{?^};
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_inSet_before_elementsAfter() async {
    await computeSuggestions('''
f() => <Object?>{^?, 0};
''');
    assertResponse(r'''
suggestions
  false
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  const
    kind: keyword
  switch
    kind: keyword
''');
  }

  Future<void> test_inSet_before_elementsBefore() async {
    await computeSuggestions('''
f() => <Object?>{0, ^?};
''');
    assertResponse(r'''
suggestions
  false
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  const
    kind: keyword
  switch
    kind: keyword
''');
  }

  Future<void> test_inSet_before_elementsBeforeAndAfter() async {
    await computeSuggestions('''
f() => <Object?>{0, ^?, 1};
''');
    assertResponse(r'''
suggestions
  false
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  const
    kind: keyword
  switch
    kind: keyword
''');
  }

  Future<void> test_inSet_before_singleEntry() async {
    await computeSuggestions('''
f() => <Object?>{^?};
''');
    assertResponse(r'''
suggestions
  false
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  const
    kind: keyword
  switch
    kind: keyword
''');
  }
}
