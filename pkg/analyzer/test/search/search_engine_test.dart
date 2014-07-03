// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.search_engine_test;


main() {
}


//class AndSearchPatternTest extends EngineTestCase {
//  Element _element = mock(Element);
//
//  SearchPattern _patternA = mock(SearchPattern);
//
//  SearchPattern _patternB = mock(SearchPattern);
//
//  AndSearchPattern _pattern = new AndSearchPattern([_patternA, _patternB]);
//
//  void test_allExact() {
//    when(_patternA.matches(_element)).thenReturn(MatchQuality.EXACT);
//    when(_patternB.matches(_element)).thenReturn(MatchQuality.EXACT);
//    // validate
//    JUnitTestCase.assertSame(MatchQuality.EXACT, _pattern.matches(_element));
//  }
//
//  void test_ExactName() {
//    when(_patternA.matches(_element)).thenReturn(MatchQuality.EXACT);
//    when(_patternB.matches(_element)).thenReturn(MatchQuality.NAME);
//    // validate
//    JUnitTestCase.assertSame(MatchQuality.EXACT, _pattern.matches(_element));
//  }
//
//  void test_NameExact() {
//    when(_patternA.matches(_element)).thenReturn(MatchQuality.NAME);
//    when(_patternB.matches(_element)).thenReturn(MatchQuality.EXACT);
//    // validate
//    JUnitTestCase.assertSame(MatchQuality.EXACT, _pattern.matches(_element));
//  }
//
//  void test_oneNull() {
//    when(_patternA.matches(_element)).thenReturn(MatchQuality.EXACT);
//    when(_patternB.matches(_element)).thenReturn(null);
//    // validate
//    JUnitTestCase.assertSame(null, _pattern.matches(_element));
//  }
//
//  static dartSuite() {
//    _ut.group('AndSearchPatternTest', () {
//      _ut.test('test_ExactName', () {
//        final __test = new AndSearchPatternTest();
//        runJUnitTest(__test, __test.test_ExactName);
//      });
//      _ut.test('test_NameExact', () {
//        final __test = new AndSearchPatternTest();
//        runJUnitTest(__test, __test.test_NameExact);
//      });
//      _ut.test('test_allExact', () {
//        final __test = new AndSearchPatternTest();
//        runJUnitTest(__test, __test.test_allExact);
//      });
//      _ut.test('test_oneNull', () {
//        final __test = new AndSearchPatternTest();
//        runJUnitTest(__test, __test.test_oneNull);
//      });
//    });
//  }
//}
//
//class CamelCaseSearchPatternTest extends EngineTestCase {
//  void test_matchExact_samePartCount() {
//    Element element = mock(Element);
//    when(element.displayName).thenReturn("HashMap");
//    //
//    CamelCaseSearchPattern pattern = new CamelCaseSearchPattern("HM", true);
//    JUnitTestCase.assertSame(MatchQuality.EXACT, pattern.matches(element));
//  }
//
//  void test_matchExact_withLowerCase() {
//    Element element = mock(Element);
//    when(element.displayName).thenReturn("HashMap");
//    //
//    CamelCaseSearchPattern pattern = new CamelCaseSearchPattern("HaMa", true);
//    JUnitTestCase.assertSame(MatchQuality.EXACT, pattern.matches(element));
//  }
//
//  void test_matchNot_nullName() {
//    Element element = mock(Element);
//    when(element.displayName).thenReturn(null);
//    //
//    CamelCaseSearchPattern pattern = new CamelCaseSearchPattern("HM", true);
//    JUnitTestCase.assertSame(null, pattern.matches(element));
//  }
//
//  void test_matchNot_samePartCount() {
//    Element element = mock(Element);
//    when(element.displayName).thenReturn("LinkedHashMap");
//    //
//    CamelCaseSearchPattern pattern = new CamelCaseSearchPattern("LH", true);
//    JUnitTestCase.assertSame(null, pattern.matches(element));
//  }
//
//  void test_matchNot_withLowerCase() {
//    Element element = mock(Element);
//    when(element.displayName).thenReturn("HashMap");
//    //
//    CamelCaseSearchPattern pattern = new CamelCaseSearchPattern("HaMu", true);
//    JUnitTestCase.assertSame(null, pattern.matches(element));
//  }
//
//  static dartSuite() {
//    _ut.group('CamelCaseSearchPatternTest', () {
//      _ut.test('test_matchExact_samePartCount', () {
//        final __test = new CamelCaseSearchPatternTest();
//        runJUnitTest(__test, __test.test_matchExact_samePartCount);
//      });
//      _ut.test('test_matchExact_withLowerCase', () {
//        final __test = new CamelCaseSearchPatternTest();
//        runJUnitTest(__test, __test.test_matchExact_withLowerCase);
//      });
//      _ut.test('test_matchNot_nullName', () {
//        final __test = new CamelCaseSearchPatternTest();
//        runJUnitTest(__test, __test.test_matchNot_nullName);
//      });
//      _ut.test('test_matchNot_samePartCount', () {
//        final __test = new CamelCaseSearchPatternTest();
//        runJUnitTest(__test, __test.test_matchNot_samePartCount);
//      });
//      _ut.test('test_matchNot_withLowerCase', () {
//        final __test = new CamelCaseSearchPatternTest();
//        runJUnitTest(__test, __test.test_matchNot_withLowerCase);
//      });
//    });
//  }
//}
//
//class CountingSearchListenerTest extends EngineTestCase {
//  void test_matchFound() {
//    SearchListener listener = mock(SearchListener);
//    SearchMatch match = mock(SearchMatch);
//    SearchListener countingListener = new CountingSearchListener(2, listener);
//    // "match" should be passed to "listener"
//    countingListener.matchFound(match);
//    verify(listener).matchFound(match);
//    verifyNoMoreInteractions(listener);
//  }
//
//  void test_searchComplete() {
//    SearchListener listener = mock(SearchListener);
//    SearchListener countingListener = new CountingSearchListener(2, listener);
//    // complete 2 -> 1
//    countingListener.searchComplete();
//    verifyZeroInteractions(listener);
//    // complete 2 -> 0
//    countingListener.searchComplete();
//    verify(listener).searchComplete();
//  }
//
//  void test_searchComplete_zero() {
//    SearchListener listener = mock(SearchListener);
//    new CountingSearchListener(0, listener);
//    // complete at 0
//    verify(listener).searchComplete();
//  }
//
//  static dartSuite() {
//    _ut.group('CountingSearchListenerTest', () {
//      _ut.test('test_matchFound', () {
//        final __test = new CountingSearchListenerTest();
//        runJUnitTest(__test, __test.test_matchFound);
//      });
//      _ut.test('test_searchComplete', () {
//        final __test = new CountingSearchListenerTest();
//        runJUnitTest(__test, __test.test_searchComplete);
//      });
//      _ut.test('test_searchComplete_zero', () {
//        final __test = new CountingSearchListenerTest();
//        runJUnitTest(__test, __test.test_searchComplete_zero);
//      });
//    });
//  }
//}
//
//class ExactSearchPatternTest extends EngineTestCase {
//  Element _element = mock(Element);
//
//  void test_caseInsensitive_false() {
//    SearchPattern pattern = new ExactSearchPattern("HashMa", false);
//    when(_element.displayName).thenReturn("HashMap");
//    // validate
//    JUnitTestCase.assertSame(null, pattern.matches(_element));
//  }
//
//  void test_caseInsensitive_true() {
//    SearchPattern pattern = new ExactSearchPattern("HashMap", false);
//    when(_element.displayName).thenReturn("HashMaP");
//    // validate
//    JUnitTestCase.assertSame(MatchQuality.EXACT, pattern.matches(_element));
//  }
//
//  void test_caseSensitive_false() {
//    SearchPattern pattern = new ExactSearchPattern("HashMa", true);
//    when(_element.displayName).thenReturn("HashMap");
//    // validate
//    JUnitTestCase.assertSame(null, pattern.matches(_element));
//  }
//
//  void test_caseSensitive_true() {
//    SearchPattern pattern = new ExactSearchPattern("HashMap", true);
//    when(_element.displayName).thenReturn("HashMap");
//    // validate
//    JUnitTestCase.assertSame(MatchQuality.EXACT, pattern.matches(_element));
//  }
//
//  void test_nullName() {
//    SearchPattern pattern = new ExactSearchPattern("HashMap", true);
//    when(_element.displayName).thenReturn(null);
//    // validate
//    JUnitTestCase.assertSame(null, pattern.matches(_element));
//  }
//
//  static dartSuite() {
//    _ut.group('ExactSearchPatternTest', () {
//      _ut.test('test_caseInsensitive_false', () {
//        final __test = new ExactSearchPatternTest();
//        runJUnitTest(__test, __test.test_caseInsensitive_false);
//      });
//      _ut.test('test_caseInsensitive_true', () {
//        final __test = new ExactSearchPatternTest();
//        runJUnitTest(__test, __test.test_caseInsensitive_true);
//      });
//      _ut.test('test_caseSensitive_false', () {
//        final __test = new ExactSearchPatternTest();
//        runJUnitTest(__test, __test.test_caseSensitive_false);
//      });
//      _ut.test('test_caseSensitive_true', () {
//        final __test = new ExactSearchPatternTest();
//        runJUnitTest(__test, __test.test_caseSensitive_true);
//      });
//      _ut.test('test_nullName', () {
//        final __test = new ExactSearchPatternTest();
//        runJUnitTest(__test, __test.test_nullName);
//      });
//    });
//  }
//}
//
//class FilterSearchListenerTest extends EngineTestCase {
//  SearchListener _listener = mock(SearchListener);
//
//  SearchMatch _match = mock(SearchMatch);
//
//  SearchFilter _filter = mock(SearchFilter);
//
//  SearchListener _filteredListener = new FilteredSearchListener(_filter, _listener);
//
//  void test_matchFound_filterFalse() {
//    when(_filter.passes(_match)).thenReturn(false);
//    // "match" should be passed to "listener"
//    _filteredListener.matchFound(_match);
//    verifyNoMoreInteractions(_listener);
//  }
//
//  void test_matchFound_filterTrue() {
//    when(_filter.passes(_match)).thenReturn(true);
//    // "match" should be passed to "listener"
//    _filteredListener.matchFound(_match);
//    verify(_listener).matchFound(_match);
//    verifyNoMoreInteractions(_listener);
//  }
//
//  void test_searchComplete() {
//    _filteredListener.searchComplete();
//    verify(_listener).searchComplete();
//    verifyNoMoreInteractions(_listener);
//  }
//
//  static dartSuite() {
//    _ut.group('FilterSearchListenerTest', () {
//      _ut.test('test_matchFound_filterFalse', () {
//        final __test = new FilterSearchListenerTest();
//        runJUnitTest(__test, __test.test_matchFound_filterFalse);
//      });
//      _ut.test('test_matchFound_filterTrue', () {
//        final __test = new FilterSearchListenerTest();
//        runJUnitTest(__test, __test.test_matchFound_filterTrue);
//      });
//      _ut.test('test_searchComplete', () {
//        final __test = new FilterSearchListenerTest();
//        runJUnitTest(__test, __test.test_searchComplete);
//      });
//    });
//  }
//}
//
//class GatheringSearchListenerTest extends EngineTestCase {
//  SearchMatch _matchA = mock(SearchMatch);
//
//  SearchMatch _matchB = mock(SearchMatch);
//
//  GatheringSearchListener _gatheringListener = new GatheringSearchListener();
//
//  void test_matchFound() {
//    Element elementA = mock(Element);
//    Element elementB = mock(Element);
//    when(elementA.displayName).thenReturn("A");
//    when(elementB.displayName).thenReturn("B");
//    when(_matchA.element).thenReturn(elementA);
//    when(_matchB.element).thenReturn(elementB);
//    // matchB
//    _gatheringListener.matchFound(_matchB);
//    JUnitTestCase.assertFalse(_gatheringListener.isComplete);
//    assertThat(_gatheringListener.matches).containsExactly(_matchB);
//    // matchA
//    _gatheringListener.matchFound(_matchA);
//    JUnitTestCase.assertFalse(_gatheringListener.isComplete);
//    assertThat(_gatheringListener.matches).containsExactly(_matchA, _matchB);
//  }
//
//  void test_searchComplete() {
//    JUnitTestCase.assertFalse(_gatheringListener.isComplete);
//    // complete
//    _gatheringListener.searchComplete();
//    JUnitTestCase.assertTrue(_gatheringListener.isComplete);
//  }
//
//  static dartSuite() {
//    _ut.group('GatheringSearchListenerTest', () {
//      _ut.test('test_matchFound', () {
//        final __test = new GatheringSearchListenerTest();
//        runJUnitTest(__test, __test.test_matchFound);
//      });
//      _ut.test('test_searchComplete', () {
//        final __test = new GatheringSearchListenerTest();
//        runJUnitTest(__test, __test.test_searchComplete);
//      });
//    });
//  }
//}
//
//class LibrarySearchScopeTest extends EngineTestCase {
//  LibraryElement _libraryA = mock(LibraryElement);
//
//  LibraryElement _libraryB = mock(LibraryElement);
//
//  Element _element = mock(Element);
//
//  void test_arrayConstructor_inA_false() {
//    when(_element.getAncestor((element) => element is LibraryElement)).thenReturn(_libraryB);
//    LibrarySearchScope scope = new LibrarySearchScope.con2([_libraryA]);
//    assertThat(scope.libraries).containsOnly(_libraryA);
//    JUnitTestCase.assertFalse(scope.encloses(_element));
//  }
//
//  void test_arrayConstructor_inA_true() {
//    when(_element.getAncestor((element) => element is LibraryElement)).thenReturn(_libraryA);
//    LibrarySearchScope scope = new LibrarySearchScope.con2([_libraryA, _libraryB]);
//    assertThat(scope.libraries).containsOnly(_libraryA, _libraryB);
//    JUnitTestCase.assertTrue(scope.encloses(_element));
//  }
//
//  void test_collectionConstructor_inB() {
//    when(_element.getAncestor((element) => element is LibraryElement)).thenReturn(_libraryB);
//    LibrarySearchScope scope = new LibrarySearchScope.con1(ImmutableSet.of(_libraryA, _libraryB));
//    assertThat(scope.libraries).containsOnly(_libraryA, _libraryB);
//    JUnitTestCase.assertTrue(scope.encloses(_element));
//  }
//
//  static dartSuite() {
//    _ut.group('LibrarySearchScopeTest', () {
//      _ut.test('test_arrayConstructor_inA_false', () {
//        final __test = new LibrarySearchScopeTest();
//        runJUnitTest(__test, __test.test_arrayConstructor_inA_false);
//      });
//      _ut.test('test_arrayConstructor_inA_true', () {
//        final __test = new LibrarySearchScopeTest();
//        runJUnitTest(__test, __test.test_arrayConstructor_inA_true);
//      });
//      _ut.test('test_collectionConstructor_inB', () {
//        final __test = new LibrarySearchScopeTest();
//        runJUnitTest(__test, __test.test_collectionConstructor_inB);
//      });
//    });
//  }
//}
//
//class NameMatchingSearchListenerTest extends EngineTestCase {
//  SearchListener _listener = mock(SearchListener);
//
//  Element _element = mock(Element);
//
//  SearchMatch _match = mock(SearchMatch);
//
//  SearchPattern _pattern = mock(SearchPattern);
//
//  SearchListener _nameMatchingListener = new NameMatchingSearchListener(_pattern, _listener);
//
//  void test_matchFound_patternFalse() {
//    when(_pattern.matches(_element)).thenReturn(null);
//    // verify
//    _nameMatchingListener.matchFound(_match);
//    verifyNoMoreInteractions(_listener);
//  }
//
//  void test_matchFound_patternTrue() {
//    when(_pattern.matches(_element)).thenReturn(MatchQuality.EXACT);
//    // verify
//    _nameMatchingListener.matchFound(_match);
//    verify(_listener).matchFound(_match);
//    verifyNoMoreInteractions(_listener);
//  }
//
//  @override
//  void setUp() {
//    super.setUp();
//    when(_match.element).thenReturn(_element);
//  }
//
//  static dartSuite() {
//    _ut.group('NameMatchingSearchListenerTest', () {
//      _ut.test('test_matchFound_patternFalse', () {
//        final __test = new NameMatchingSearchListenerTest();
//        runJUnitTest(__test, __test.test_matchFound_patternFalse);
//      });
//      _ut.test('test_matchFound_patternTrue', () {
//        final __test = new NameMatchingSearchListenerTest();
//        runJUnitTest(__test, __test.test_matchFound_patternTrue);
//      });
//    });
//  }
//}
//
//class OrSearchPatternTest extends EngineTestCase {
//  Element _element = mock(Element);
//
//  SearchPattern _patternA = mock(SearchPattern);
//
//  SearchPattern _patternB = mock(SearchPattern);
//
//  SearchPattern _pattern = new OrSearchPattern([_patternA, _patternB]);
//
//  void test_allExact() {
//    when(_patternA.matches(_element)).thenReturn(MatchQuality.EXACT);
//    when(_patternB.matches(_element)).thenReturn(MatchQuality.EXACT);
//    // validate
//    JUnitTestCase.assertSame(MatchQuality.EXACT, _pattern.matches(_element));
//  }
//
//  void test_ExactName() {
//    when(_patternA.matches(_element)).thenReturn(MatchQuality.EXACT);
//    when(_patternB.matches(_element)).thenReturn(MatchQuality.NAME);
//    // validate
//    JUnitTestCase.assertSame(MatchQuality.EXACT, _pattern.matches(_element));
//  }
//
//  void test_NameExact() {
//    when(_patternA.matches(_element)).thenReturn(MatchQuality.NAME);
//    when(_patternB.matches(_element)).thenReturn(MatchQuality.EXACT);
//    // validate
//    JUnitTestCase.assertSame(MatchQuality.NAME, _pattern.matches(_element));
//  }
//
//  void test_NullNull() {
//    when(_patternA.matches(_element)).thenReturn(null);
//    when(_patternB.matches(_element)).thenReturn(null);
//    // validate
//    JUnitTestCase.assertSame(null, _pattern.matches(_element));
//  }
//
//  static dartSuite() {
//    _ut.group('OrSearchPatternTest', () {
//      _ut.test('test_ExactName', () {
//        final __test = new OrSearchPatternTest();
//        runJUnitTest(__test, __test.test_ExactName);
//      });
//      _ut.test('test_NameExact', () {
//        final __test = new OrSearchPatternTest();
//        runJUnitTest(__test, __test.test_NameExact);
//      });
//      _ut.test('test_NullNull', () {
//        final __test = new OrSearchPatternTest();
//        runJUnitTest(__test, __test.test_NullNull);
//      });
//      _ut.test('test_allExact', () {
//        final __test = new OrSearchPatternTest();
//        runJUnitTest(__test, __test.test_allExact);
//      });
//    });
//  }
//}
//
//class PrefixSearchPatternTest extends EngineTestCase {
//  Element _element = mock(Element);
//
//  void test_caseInsensitive_contentMatch_caseMatch() {
//    SearchPattern pattern = new PrefixSearchPattern("HashMa", false);
//    when(_element.displayName).thenReturn("HashMap");
//    // validate
//    JUnitTestCase.assertSame(MatchQuality.EXACT, pattern.matches(_element));
//  }
//
//  void test_caseInsensitive_contentMatch_caseMismatch() {
//    SearchPattern pattern = new PrefixSearchPattern("HaSHMa", false);
//    when(_element.displayName).thenReturn("hashMaP");
//    // validate
//    JUnitTestCase.assertSame(MatchQuality.EXACT, pattern.matches(_element));
//  }
//
//  void test_caseInsensitive_contentMismatch() {
//    SearchPattern pattern = new PrefixSearchPattern("HashMa", false);
//    when(_element.displayName).thenReturn("HashTable");
//    // validate
//    JUnitTestCase.assertSame(null, pattern.matches(_element));
//  }
//
//  void test_caseSensitive_contentMatch() {
//    SearchPattern pattern = new PrefixSearchPattern("HashMa", true);
//    when(_element.displayName).thenReturn("HashMap");
//    // validate
//    JUnitTestCase.assertSame(MatchQuality.EXACT, pattern.matches(_element));
//  }
//
//  void test_caseSensitive_contentMismatch() {
//    SearchPattern pattern = new PrefixSearchPattern("HashMa", true);
//    when(_element.displayName).thenReturn("HashTable");
//    // validate
//    JUnitTestCase.assertSame(null, pattern.matches(_element));
//  }
//
//  void test_nullElement() {
//    SearchPattern pattern = new PrefixSearchPattern("HashMa", false);
//    // validate
//    JUnitTestCase.assertSame(null, pattern.matches(null));
//  }
//
//  void test_nullName() {
//    SearchPattern pattern = new PrefixSearchPattern("HashMa", false);
//    when(_element.displayName).thenReturn(null);
//    // validate
//    JUnitTestCase.assertSame(null, pattern.matches(_element));
//  }
//
//  static dartSuite() {
//    _ut.group('PrefixSearchPatternTest', () {
//      _ut.test('test_caseInsensitive_contentMatch_caseMatch', () {
//        final __test = new PrefixSearchPatternTest();
//        runJUnitTest(__test, __test.test_caseInsensitive_contentMatch_caseMatch);
//      });
//      _ut.test('test_caseInsensitive_contentMatch_caseMismatch', () {
//        final __test = new PrefixSearchPatternTest();
//        runJUnitTest(__test, __test.test_caseInsensitive_contentMatch_caseMismatch);
//      });
//      _ut.test('test_caseInsensitive_contentMismatch', () {
//        final __test = new PrefixSearchPatternTest();
//        runJUnitTest(__test, __test.test_caseInsensitive_contentMismatch);
//      });
//      _ut.test('test_caseSensitive_contentMatch', () {
//        final __test = new PrefixSearchPatternTest();
//        runJUnitTest(__test, __test.test_caseSensitive_contentMatch);
//      });
//      _ut.test('test_caseSensitive_contentMismatch', () {
//        final __test = new PrefixSearchPatternTest();
//        runJUnitTest(__test, __test.test_caseSensitive_contentMismatch);
//      });
//      _ut.test('test_nullElement', () {
//        final __test = new PrefixSearchPatternTest();
//        runJUnitTest(__test, __test.test_nullElement);
//      });
//      _ut.test('test_nullName', () {
//        final __test = new PrefixSearchPatternTest();
//        runJUnitTest(__test, __test.test_nullName);
//      });
//    });
//  }
//}
//
//class RegularExpressionSearchPatternTest extends EngineTestCase {
//  Element _element = mock(Element);
//
//  void test_caseInsensitive_false_contentMismatch() {
//    SearchPattern pattern = new RegularExpressionSearchPattern("H[a-z]*Map", false);
//    when(_element.displayName).thenReturn("Maps");
//    // validate
//    JUnitTestCase.assertSame(null, pattern.matches(_element));
//  }
//
//  void test_caseInsensitive_true_caseMismatch() {
//    SearchPattern pattern = new RegularExpressionSearchPattern("H[a-z]*MaP", false);
//    when(_element.displayName).thenReturn("HashMap");
//    // validate
//    JUnitTestCase.assertSame(MatchQuality.EXACT, pattern.matches(_element));
//  }
//
//  void test_caseSensitive_false_caseMismatch() {
//    SearchPattern pattern = new RegularExpressionSearchPattern("H[a-z]*MaP", true);
//    when(_element.displayName).thenReturn("HashMap");
//    // validate
//    JUnitTestCase.assertSame(null, pattern.matches(_element));
//  }
//
//  void test_caseSensitive_false_contentMismatch() {
//    SearchPattern pattern = new RegularExpressionSearchPattern("H[a-z]*Map", true);
//    when(_element.displayName).thenReturn("Maps");
//    // validate
//    JUnitTestCase.assertSame(null, pattern.matches(_element));
//  }
//
//  void test_caseSensitive_true() {
//    SearchPattern pattern = new RegularExpressionSearchPattern("H.*Map", true);
//    when(_element.displayName).thenReturn("HashMap");
//    // validate
//    JUnitTestCase.assertSame(MatchQuality.EXACT, pattern.matches(_element));
//  }
//
//  void test_nullElement() {
//    SearchPattern pattern = new RegularExpressionSearchPattern("H.*Map", true);
//    // validate
//    JUnitTestCase.assertSame(null, pattern.matches(null));
//  }
//
//  void test_nullName() {
//    SearchPattern pattern = new RegularExpressionSearchPattern("H.*Map", true);
//    when(_element.displayName).thenReturn(null);
//    // validate
//    JUnitTestCase.assertSame(null, pattern.matches(_element));
//  }
//
//  static dartSuite() {
//    _ut.group('RegularExpressionSearchPatternTest', () {
//      _ut.test('test_caseInsensitive_false_contentMismatch', () {
//        final __test = new RegularExpressionSearchPatternTest();
//        runJUnitTest(__test, __test.test_caseInsensitive_false_contentMismatch);
//      });
//      _ut.test('test_caseInsensitive_true_caseMismatch', () {
//        final __test = new RegularExpressionSearchPatternTest();
//        runJUnitTest(__test, __test.test_caseInsensitive_true_caseMismatch);
//      });
//      _ut.test('test_caseSensitive_false_caseMismatch', () {
//        final __test = new RegularExpressionSearchPatternTest();
//        runJUnitTest(__test, __test.test_caseSensitive_false_caseMismatch);
//      });
//      _ut.test('test_caseSensitive_false_contentMismatch', () {
//        final __test = new RegularExpressionSearchPatternTest();
//        runJUnitTest(__test, __test.test_caseSensitive_false_contentMismatch);
//      });
//      _ut.test('test_caseSensitive_true', () {
//        final __test = new RegularExpressionSearchPatternTest();
//        runJUnitTest(__test, __test.test_caseSensitive_true);
//      });
//      _ut.test('test_nullElement', () {
//        final __test = new RegularExpressionSearchPatternTest();
//        runJUnitTest(__test, __test.test_nullElement);
//      });
//      _ut.test('test_nullName', () {
//        final __test = new RegularExpressionSearchPatternTest();
//        runJUnitTest(__test, __test.test_nullName);
//      });
//    });
//  }
//}
//
//class SearchEngineImplTest extends EngineTestCase {
//  static void _assertMatches(List<SearchMatch> matches, List<SearchEngineImplTest_ExpectedMatch> expectedMatches) {
//    assertThat(matches).hasSize(expectedMatches.length);
//    for (SearchMatch match in matches) {
//      bool found = false;
//      String msg = match.toString();
//      for (SearchEngineImplTest_ExpectedMatch expectedMatch in expectedMatches) {
//        if (match.element == expectedMatch._element && match.kind == expectedMatch._kind && match.quality == expectedMatch._quality && match.sourceRange == expectedMatch._range && match.isQualified == expectedMatch._qualified) {
//          found = true;
//          break;
//        }
//      }
//      if (!found) {
//        JUnitTestCase.fail("Not found: ${msg}");
//      }
//    }
//  }
//
//  IndexStore _indexStore = IndexFactory.newSplitIndexStore(new MemoryNodeManager());
//
//  static AnalysisContext _CONTEXT = mock(AnalysisContext);
//
//  int _nextLocationId = 0;
//
//  SearchScope _scope;
//
//  SearchPattern _pattern = null;
//
//  SearchFilter _filter = null;
//
//  Source _source = mock(Source);
//
//  CompilationUnitElement _unitElement = mock(CompilationUnitElement);
//
//  LibraryElement _libraryElement = mock(LibraryElement);
//
//  Element _elementA = _mockElement(Element, ElementKind.CLASS);
//
//  Element _elementB = _mockElement(Element, ElementKind.CLASS);
//
//  Element _elementC = _mockElement(Element, ElementKind.CLASS);
//
//  Element _elementD = _mockElement(Element, ElementKind.CLASS);
//
//  Element _elementE = _mockElement(Element, ElementKind.CLASS);
//
//  void fail_searchAssignedTypes_assignments() {
//    // TODO(scheglov) does not work - new split index store cannot store types (yet?)
//    PropertyAccessorElement setterElement = _mockElement(PropertyAccessorElement, ElementKind.SETTER);
//    FieldElement fieldElement = _mockElement(FieldElement, ElementKind.FIELD);
//    when(fieldElement.setter).thenReturn(setterElement);
//    DartType typeA = mock(DartType);
//    DartType typeB = mock(DartType);
//    DartType typeC = mock(DartType);
//    _indexStore.aboutToIndexDart(_CONTEXT, _unitElement);
//    {
//      Location location = new Location(_elementA, 1, 10);
//      location = new LocationWithData<DartType>.con1(location, typeA);
//      _indexStore.recordRelationship(setterElement, IndexConstants.IS_REFERENCED_BY_QUALIFIED, location);
//    }
//    {
//      Location location = new Location(_elementB, 2, 20);
//      location = new LocationWithData<DartType>.con1(location, typeB);
//      _indexStore.recordRelationship(setterElement, IndexConstants.IS_REFERENCED_BY_UNQUALIFIED, location);
//    }
//    // will be filtered by scope
//    {
//      Location location = new Location(_elementC, 3, 30);
//      location = new LocationWithData<DartType>.con1(location, typeC);
//      _indexStore.recordRelationship(setterElement, IndexConstants.IS_REFERENCED_BY_QUALIFIED, location);
//    }
//    // not LocationWithData
//    {
//      Location location = new Location(_elementD, 4, 40);
//      _indexStore.recordRelationship(setterElement, IndexConstants.IS_REFERENCED_BY_QUALIFIED, location);
//    }
//    _indexStore.doneIndex();
//    // ask types
//    Set<DartType> types = _runSearch(new SearchRunner_SearchEngineImplTest_fail_searchAssignedTypes_assignments(fieldElement));
//    assertThat(types).containsOnly(typeA, typeB);
//  }
//
//  void fail_searchAssignedTypes_initializers() {
//    // TODO(scheglov) does not work - new split index store cannot store types (yet?)
//    FieldElement fieldElement = _mockElement(FieldElement, ElementKind.FIELD);
//    DartType typeA = mock(DartType);
//    DartType typeB = mock(DartType);
//    {
//      Location location = new Location(_elementA, 10, 1);
//      location = new LocationWithData<DartType>.con1(location, typeA);
//      _indexStore.recordRelationship(fieldElement, IndexConstants.IS_DEFINED_BY, location);
//    }
//    {
//      Location location = new Location(_elementB, 20, 1);
//      location = new LocationWithData<DartType>.con1(location, typeB);
//      _indexStore.recordRelationship(fieldElement, IndexConstants.IS_REFERENCED_BY, location);
//    }
//    _indexStore.doneIndex();
//    // ask types
//    Set<DartType> types = _runSearch(new SearchRunner_SearchEngineImplTest_fail_searchAssignedTypes_initializers(fieldElement));
//    assertThat(types).containsOnly(typeA, typeB);
//  }
//
//  void test_searchDeclarations_String() {
//    Element referencedElement = new NameElementImpl("test");
//    {
//      Location locationA = new Location(_elementA, 1, 2);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.IS_DEFINED_BY, locationA);
//    }
//    {
//      Location locationB = new Location(_elementB, 10, 20);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.IS_DEFINED_BY, locationB);
//    }
//    _indexStore.doneIndex();
//    // search matches
//    List<SearchMatch> matches = _runSearch(new SearchRunner_SearchEngineImplTest_test_searchDeclarations_String(this));
//    // verify
//    _assertMatches(matches, [
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementA, MatchKind.NAME_DECLARATION, 1, 2),
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementB, MatchKind.NAME_DECLARATION, 10, 20)]);
//  }
//
//  void test_searchFunctionDeclarations() {
//    LibraryElement library = _mockElement(LibraryElement, ElementKind.LIBRARY);
//    _defineFunctionsAB(library);
//    _scope = new LibrarySearchScope.con2([library]);
//    // search matches
//    List<SearchMatch> matches = _searchFunctionDeclarationsSync();
//    // verify
//    _assertMatches(matches, [
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementA, MatchKind.FUNCTION_DECLARATION, 1, 2),
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementB, MatchKind.FUNCTION_DECLARATION, 10, 20)]);
//  }
//
//  void test_searchFunctionDeclarations_async() {
//    LibraryElement library = _mockElement(LibraryElement, ElementKind.LIBRARY);
//    _defineFunctionsAB(library);
//    _scope = new LibrarySearchScope.con2([library]);
//    // search matches
//    List<SearchMatch> matches = _searchFunctionDeclarationsAsync();
//    // verify
//    _assertMatches(matches, [
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementA, MatchKind.FUNCTION_DECLARATION, 1, 2),
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementB, MatchKind.FUNCTION_DECLARATION, 10, 20)]);
//  }
//
//  void test_searchFunctionDeclarations_inUniverse() {
//    {
//      Location locationA = new Location(_elementA, 1, 2);
//      _indexStore.recordRelationship(IndexConstants.UNIVERSE, IndexConstants.DEFINES_FUNCTION, locationA);
//    }
//    {
//      Location locationB = new Location(_elementB, 10, 20);
//      _indexStore.recordRelationship(IndexConstants.UNIVERSE, IndexConstants.DEFINES_FUNCTION, locationB);
//    }
//    _indexStore.doneIndex();
//    _scope = SearchScopeFactory.createUniverseScope();
//    // search matches
//    List<SearchMatch> matches = _searchFunctionDeclarationsSync();
//    // verify
//    _assertMatches(matches, [
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementA, MatchKind.FUNCTION_DECLARATION, 1, 2),
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementB, MatchKind.FUNCTION_DECLARATION, 10, 20)]);
//  }
//
//  void test_searchFunctionDeclarations_useFilter() {
//    LibraryElement library = _mockElement(LibraryElement, ElementKind.LIBRARY);
//    _defineFunctionsAB(library);
//    _scope = new LibrarySearchScope.con2([library]);
//    // search "elementA"
//    {
//      _filter = new SearchFilter_SearchEngineImplTest_test_searchFunctionDeclarations_useFilter_2(this);
//      List<SearchMatch> matches = _searchFunctionDeclarationsSync();
//      _assertMatches(matches, [new SearchEngineImplTest_ExpectedMatch.con1(_elementA, MatchKind.FUNCTION_DECLARATION, 1, 2)]);
//    }
//    // search "elementB"
//    {
//      _filter = new SearchFilter_SearchEngineImplTest_test_searchFunctionDeclarations_useFilter(this);
//      List<SearchMatch> matches = _searchFunctionDeclarationsSync();
//      _assertMatches(matches, [new SearchEngineImplTest_ExpectedMatch.con1(_elementB, MatchKind.FUNCTION_DECLARATION, 10, 20)]);
//    }
//  }
//
//  void test_searchFunctionDeclarations_usePattern() {
//    LibraryElement library = _mockElement(LibraryElement, ElementKind.LIBRARY);
//    _defineFunctionsAB(library);
//    _scope = new LibrarySearchScope.con2([library]);
//    // search "A"
//    {
//      _pattern = SearchPatternFactory.createExactPattern("A", true);
//      List<SearchMatch> matches = _searchFunctionDeclarationsSync();
//      _assertMatches(matches, [new SearchEngineImplTest_ExpectedMatch.con1(_elementA, MatchKind.FUNCTION_DECLARATION, 1, 2)]);
//    }
//    // search "B"
//    {
//      _pattern = SearchPatternFactory.createExactPattern("B", true);
//      List<SearchMatch> matches = _searchFunctionDeclarationsSync();
//      _assertMatches(matches, [new SearchEngineImplTest_ExpectedMatch.con1(_elementB, MatchKind.FUNCTION_DECLARATION, 10, 20)]);
//    }
//  }
//
//  void test_searchReferences_AngularComponentElement() {
//    AngularComponentElement referencedElement = _mockElement(AngularComponentElement, ElementKind.ANGULAR_COMPONENT);
//    {
//      Location locationA = new Location(_elementA, 1, 2);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.ANGULAR_REFERENCE, locationA);
//    }
//    {
//      Location locationB = new Location(_elementB, 10, 20);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.ANGULAR_CLOSING_TAG_REFERENCE, locationB);
//    }
//    _indexStore.doneIndex();
//    // search matches
//    List<SearchMatch> matches = _searchReferencesSync(Element, referencedElement);
//    _assertMatches(matches, [
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementA, MatchKind.ANGULAR_REFERENCE, 1, 2),
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementB, MatchKind.ANGULAR_CLOSING_TAG_REFERENCE, 10, 20)]);
//  }
//
//  void test_searchReferences_AngularControllerElement() {
//    AngularControllerElement referencedElement = _mockElement(AngularControllerElement, ElementKind.ANGULAR_CONTROLLER);
//    {
//      Location locationA = new Location(_elementA, 1, 2);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.ANGULAR_REFERENCE, locationA);
//    }
//    {
//      Location locationB = new Location(_elementB, 10, 20);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.ANGULAR_REFERENCE, locationB);
//    }
//    _indexStore.doneIndex();
//    // search matches
//    List<SearchMatch> matches = _searchReferencesSync(Element, referencedElement);
//    _assertMatches(matches, [
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementA, MatchKind.ANGULAR_REFERENCE, 1, 2),
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementB, MatchKind.ANGULAR_REFERENCE, 10, 20)]);
//  }
//
//  void test_searchReferences_AngularFilterElement() {
//    AngularFormatterElement referencedElement = _mockElement(AngularFormatterElement, ElementKind.ANGULAR_FORMATTER);
//    {
//      Location locationA = new Location(_elementA, 1, 2);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.ANGULAR_REFERENCE, locationA);
//    }
//    {
//      Location locationB = new Location(_elementB, 10, 20);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.ANGULAR_REFERENCE, locationB);
//    }
//    _indexStore.doneIndex();
//    // search matches
//    List<SearchMatch> matches = _searchReferencesSync(Element, referencedElement);
//    _assertMatches(matches, [
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementA, MatchKind.ANGULAR_REFERENCE, 1, 2),
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementB, MatchKind.ANGULAR_REFERENCE, 10, 20)]);
//  }
//
//  void test_searchReferences_AngularPropertyElement() {
//    AngularPropertyElement referencedElement = _mockElement(AngularPropertyElement, ElementKind.ANGULAR_PROPERTY);
//    {
//      Location locationA = new Location(_elementA, 1, 2);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.ANGULAR_REFERENCE, locationA);
//    }
//    {
//      Location locationB = new Location(_elementB, 10, 20);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.ANGULAR_REFERENCE, locationB);
//    }
//    _indexStore.doneIndex();
//    // search matches
//    List<SearchMatch> matches = _searchReferencesSync(Element, referencedElement);
//    _assertMatches(matches, [
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementA, MatchKind.ANGULAR_REFERENCE, 1, 2),
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementB, MatchKind.ANGULAR_REFERENCE, 10, 20)]);
//  }
//
//  void test_searchReferences_AngularScopePropertyElement() {
//    AngularScopePropertyElement referencedElement = _mockElement(AngularScopePropertyElement, ElementKind.ANGULAR_SCOPE_PROPERTY);
//    {
//      Location locationA = new Location(_elementA, 1, 2);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.ANGULAR_REFERENCE, locationA);
//    }
//    {
//      Location locationB = new Location(_elementB, 10, 20);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.ANGULAR_REFERENCE, locationB);
//    }
//    _indexStore.doneIndex();
//    // search matches
//    List<SearchMatch> matches = _searchReferencesSync(Element, referencedElement);
//    _assertMatches(matches, [
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementA, MatchKind.ANGULAR_REFERENCE, 1, 2),
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementB, MatchKind.ANGULAR_REFERENCE, 10, 20)]);
//  }
//
//  void test_searchReferences_AngularSelectorElement() {
//    AngularSelectorElement referencedElement = _mockElement(AngularSelectorElement, ElementKind.ANGULAR_SELECTOR);
//    {
//      Location locationA = new Location(_elementA, 1, 2);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.ANGULAR_REFERENCE, locationA);
//    }
//    {
//      Location locationB = new Location(_elementB, 10, 20);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.ANGULAR_REFERENCE, locationB);
//    }
//    _indexStore.doneIndex();
//    // search matches
//    List<SearchMatch> matches = _searchReferencesSync(Element, referencedElement);
//    _assertMatches(matches, [
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementA, MatchKind.ANGULAR_REFERENCE, 1, 2),
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementB, MatchKind.ANGULAR_REFERENCE, 10, 20)]);
//  }
//
//  void test_searchReferences_ClassElement() {
//    ClassElement referencedElement = _mockElement(ClassElement, ElementKind.CLASS);
//    {
//      Location locationA = new Location(_elementA, 1, 2);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.IS_REFERENCED_BY, locationA);
//    }
//    {
//      Location locationB = new Location(_elementB, 10, 20);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.IS_REFERENCED_BY, locationB);
//    }
//    _indexStore.doneIndex();
//    // search matches
//    List<SearchMatch> matches = _searchReferencesSync(Element, referencedElement);
//    // verify
//    _assertMatches(matches, [
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementA, MatchKind.TYPE_REFERENCE, 1, 2),
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementB, MatchKind.TYPE_REFERENCE, 10, 20)]);
//  }
//
//  void test_searchReferences_ClassElement_useScope() {
//    LibraryElement libraryA = _mockElement(LibraryElement, ElementKind.LIBRARY);
//    LibraryElement libraryB = _mockElement(LibraryElement, ElementKind.LIBRARY);
//    ClassElement referencedElement = _mockElement(ClassElement, ElementKind.CLASS);
//    {
//      when(_elementA.getAncestor((element) => element is LibraryElement)).thenReturn(libraryA);
//      Location locationA = new Location(_elementA, 1, 2);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.IS_REFERENCED_BY, locationA);
//    }
//    {
//      when(_elementB.getAncestor((element) => element is LibraryElement)).thenReturn(libraryB);
//      Location locationB = new Location(_elementB, 10, 20);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.IS_REFERENCED_BY, locationB);
//    }
//    _indexStore.doneIndex();
//    // search matches, in "libraryA"
//    _scope = SearchScopeFactory.createLibraryScope3(libraryA);
//    List<SearchMatch> matches = _searchReferencesSync(Element, referencedElement);
//    // verify
//    _assertMatches(matches, [new SearchEngineImplTest_ExpectedMatch.con1(_elementA, MatchKind.TYPE_REFERENCE, 1, 2)]);
//  }
//
//  void test_searchReferences_CompilationUnitElement() {
//    CompilationUnitElement referencedElement = _mockElement(CompilationUnitElement, ElementKind.COMPILATION_UNIT);
//    {
//      Location location = new Location(_elementA, 1, 2);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.IS_REFERENCED_BY, location);
//    }
//    _indexStore.doneIndex();
//    // search matches
//    List<SearchMatch> matches = _searchReferencesSync(Element, referencedElement);
//    // verify
//    _assertMatches(matches, [new SearchEngineImplTest_ExpectedMatch.con1(_elementA, MatchKind.UNIT_REFERENCE, 1, 2)]);
//  }
//
//  void test_searchReferences_ConstructorElement() {
//    ConstructorElement referencedElement = _mockElement(ConstructorElement, ElementKind.CONSTRUCTOR);
//    {
//      Location location = new Location(_elementA, 10, 1);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.IS_DEFINED_BY, location);
//    }
//    {
//      Location location = new Location(_elementB, 20, 2);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.IS_REFERENCED_BY, location);
//    }
//    {
//      Location location = new Location(_elementC, 30, 3);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.IS_REFERENCED_BY, location);
//    }
//    _indexStore.doneIndex();
//    // search matches
//    List<SearchMatch> matches = _searchReferencesSync(Element, referencedElement);
//    // verify
//    _assertMatches(matches, [
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementA, MatchKind.CONSTRUCTOR_DECLARATION, 10, 1),
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementB, MatchKind.CONSTRUCTOR_REFERENCE, 20, 2),
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementC, MatchKind.CONSTRUCTOR_REFERENCE, 30, 3)]);
//  }
//
//  void test_searchReferences_Element_unknown() {
//    List<SearchMatch> matches = _searchReferencesSync(Element, null);
//    assertThat(matches).isEmpty();
//  }
//
//  void test_searchReferences_FieldElement() {
//    PropertyAccessorElement getterElement = _mockElement(PropertyAccessorElement, ElementKind.GETTER);
//    PropertyAccessorElement setterElement = _mockElement(PropertyAccessorElement, ElementKind.SETTER);
//    FieldElement fieldElement = _mockElement(FieldElement, ElementKind.FIELD);
//    when(fieldElement.getter).thenReturn(getterElement);
//    when(fieldElement.setter).thenReturn(setterElement);
//    {
//      Location location = new Location(_elementA, 1, 10);
//      _indexStore.recordRelationship(getterElement, IndexConstants.IS_REFERENCED_BY_UNQUALIFIED, location);
//    }
//    {
//      Location location = new Location(_elementB, 2, 20);
//      _indexStore.recordRelationship(getterElement, IndexConstants.IS_REFERENCED_BY_QUALIFIED, location);
//    }
//    {
//      Location location = new Location(_elementC, 3, 30);
//      _indexStore.recordRelationship(setterElement, IndexConstants.IS_REFERENCED_BY_UNQUALIFIED, location);
//    }
//    {
//      Location location = new Location(_elementD, 4, 40);
//      _indexStore.recordRelationship(setterElement, IndexConstants.IS_REFERENCED_BY_QUALIFIED, location);
//    }
//    _indexStore.doneIndex();
//    // search matches
//    List<SearchMatch> matches = _searchReferencesSync(Element, fieldElement);
//    // verify
//    _assertMatches(matches, [
//        new SearchEngineImplTest_ExpectedMatch.con2(_elementA, MatchKind.FIELD_READ, 1, 10, false),
//        new SearchEngineImplTest_ExpectedMatch.con2(_elementB, MatchKind.FIELD_READ, 2, 20, true),
//        new SearchEngineImplTest_ExpectedMatch.con2(_elementC, MatchKind.FIELD_WRITE, 3, 30, false),
//        new SearchEngineImplTest_ExpectedMatch.con2(_elementD, MatchKind.FIELD_WRITE, 4, 40, true)]);
//  }
//
//  void test_searchReferences_FieldElement_invocation() {
//    PropertyAccessorElement getterElement = _mockElement(PropertyAccessorElement, ElementKind.GETTER);
//    FieldElement fieldElement = _mockElement(FieldElement, ElementKind.FIELD);
//    when(fieldElement.getter).thenReturn(getterElement);
//    {
//      Location location = new Location(_elementA, 1, 10);
//      _indexStore.recordRelationship(getterElement, IndexConstants.IS_INVOKED_BY_QUALIFIED, location);
//    }
//    {
//      Location location = new Location(_elementB, 2, 20);
//      _indexStore.recordRelationship(getterElement, IndexConstants.IS_INVOKED_BY_UNQUALIFIED, location);
//    }
//    _indexStore.doneIndex();
//    // search matches
//    List<SearchMatch> matches = _searchReferencesSync(Element, fieldElement);
//    // verify
//    _assertMatches(matches, [
//        new SearchEngineImplTest_ExpectedMatch.con2(_elementA, MatchKind.FIELD_INVOCATION, 1, 10, true),
//        new SearchEngineImplTest_ExpectedMatch.con2(_elementB, MatchKind.FIELD_INVOCATION, 2, 20, false)]);
//  }
//
//  void test_searchReferences_FieldElement2() {
//    FieldElement fieldElement = _mockElement(FieldElement, ElementKind.FIELD);
//    {
//      Location location = new Location(_elementA, 1, 10);
//      _indexStore.recordRelationship(fieldElement, IndexConstants.IS_REFERENCED_BY, location);
//    }
//    {
//      Location location = new Location(_elementB, 2, 20);
//      _indexStore.recordRelationship(fieldElement, IndexConstants.IS_REFERENCED_BY_QUALIFIED, location);
//    }
//    _indexStore.doneIndex();
//    // search matches
//    List<SearchMatch> matches = _searchReferencesSync(Element, fieldElement);
//    // verify
//    _assertMatches(matches, [
//        new SearchEngineImplTest_ExpectedMatch.con2(_elementA, MatchKind.FIELD_REFERENCE, 1, 10, false),
//        new SearchEngineImplTest_ExpectedMatch.con2(_elementB, MatchKind.FIELD_REFERENCE, 2, 20, true)]);
//  }
//
//  void test_searchReferences_FunctionElement() {
//    FunctionElement referencedElement = _mockElement(FunctionElement, ElementKind.FUNCTION);
//    {
//      Location location = new Location(_elementA, 1, 10);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.IS_INVOKED_BY, location);
//    }
//    {
//      Location location = new Location(_elementB, 2, 20);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.IS_REFERENCED_BY, location);
//    }
//    _indexStore.doneIndex();
//    // search matches
//    List<SearchMatch> matches = _searchReferencesSync(Element, referencedElement);
//    // verify
//    _assertMatches(matches, [
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementA, MatchKind.FUNCTION_EXECUTION, 1, 10),
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementB, MatchKind.FUNCTION_REFERENCE, 2, 20)]);
//  }
//
//  void test_searchReferences_ImportElement() {
//    ImportElement referencedElement = _mockElement(ImportElement, ElementKind.IMPORT);
//    {
//      Location locationA = new Location(_elementA, 1, 2);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.IS_REFERENCED_BY, locationA);
//    }
//    {
//      Location locationB = new Location(_elementB, 10, 0);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.IS_REFERENCED_BY, locationB);
//    }
//    _indexStore.doneIndex();
//    // search matches
//    List<SearchMatch> matches = _searchReferencesSync(Element, referencedElement);
//    // verify
//    _assertMatches(matches, [
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementA, MatchKind.IMPORT_REFERENCE, 1, 2),
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementB, MatchKind.IMPORT_REFERENCE, 10, 0)]);
//  }
//
//  void test_searchReferences_LibraryElement() {
//    LibraryElement referencedElement = _mockElement(LibraryElement, ElementKind.LIBRARY);
//    {
//      Location location = new Location(_elementA, 1, 2);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.IS_REFERENCED_BY, location);
//    }
//    _indexStore.doneIndex();
//    // search matches
//    List<SearchMatch> matches = _searchReferencesSync(Element, referencedElement);
//    // verify
//    _assertMatches(matches, [new SearchEngineImplTest_ExpectedMatch.con1(_elementA, MatchKind.LIBRARY_REFERENCE, 1, 2)]);
//  }
//
//  void test_searchReferences_MethodElement() {
//    MethodElement referencedElement = _mockElement(MethodElement, ElementKind.METHOD);
//    {
//      Location location = new Location(_elementA, 1, 10);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.IS_INVOKED_BY_UNQUALIFIED, location);
//    }
//    {
//      Location location = new Location(_elementB, 2, 20);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.IS_INVOKED_BY_QUALIFIED, location);
//    }
//    {
//      Location location = new Location(_elementC, 3, 30);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.IS_REFERENCED_BY_UNQUALIFIED, location);
//    }
//    {
//      Location location = new Location(_elementD, 4, 40);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.IS_REFERENCED_BY_QUALIFIED, location);
//    }
//    _indexStore.doneIndex();
//    // search matches
//    List<SearchMatch> matches = _searchReferencesSync(Element, referencedElement);
//    // verify
//    _assertMatches(matches, [
//        new SearchEngineImplTest_ExpectedMatch.con2(_elementA, MatchKind.METHOD_INVOCATION, 1, 10, false),
//        new SearchEngineImplTest_ExpectedMatch.con2(_elementB, MatchKind.METHOD_INVOCATION, 2, 20, true),
//        new SearchEngineImplTest_ExpectedMatch.con2(_elementC, MatchKind.METHOD_REFERENCE, 3, 30, false),
//        new SearchEngineImplTest_ExpectedMatch.con2(_elementD, MatchKind.METHOD_REFERENCE, 4, 40, true)]);
//  }
//
//  void test_searchReferences_MethodMember() {
//    MethodElement referencedElement = _mockElement(MethodElement, ElementKind.METHOD);
//    {
//      Location location = new Location(_elementA, 1, 10);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.IS_INVOKED_BY_UNQUALIFIED, location);
//    }
//    {
//      Location location = new Location(_elementB, 2, 20);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.IS_INVOKED_BY_QUALIFIED, location);
//    }
//    {
//      Location location = new Location(_elementC, 3, 30);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.IS_REFERENCED_BY_UNQUALIFIED, location);
//    }
//    {
//      Location location = new Location(_elementD, 4, 40);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.IS_REFERENCED_BY_QUALIFIED, location);
//    }
//    _indexStore.doneIndex();
//    // search matches
//    MethodMember referencedMember = new MethodMember(referencedElement, null);
//    List<SearchMatch> matches = _searchReferencesSync(Element, referencedMember);
//    // verify
//    _assertMatches(matches, [
//        new SearchEngineImplTest_ExpectedMatch.con2(_elementA, MatchKind.METHOD_INVOCATION, 1, 10, false),
//        new SearchEngineImplTest_ExpectedMatch.con2(_elementB, MatchKind.METHOD_INVOCATION, 2, 20, true),
//        new SearchEngineImplTest_ExpectedMatch.con2(_elementC, MatchKind.METHOD_REFERENCE, 3, 30, false),
//        new SearchEngineImplTest_ExpectedMatch.con2(_elementD, MatchKind.METHOD_REFERENCE, 4, 40, true)]);
//  }
//
//  void test_searchReferences_notSupported() {
//    Element referencedElement = _mockElement(Element, ElementKind.UNIVERSE);
//    List<SearchMatch> matches = _searchReferencesSync(Element, referencedElement);
//    assertThat(matches).isEmpty();
//  }
//
//  void test_searchReferences_ParameterElement() {
//    ParameterElement referencedElement = _mockElement(ParameterElement, ElementKind.PARAMETER);
//    {
//      Location location = new Location(_elementA, 1, 10);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.IS_READ_BY, location);
//    }
//    {
//      Location location = new Location(_elementB, 2, 20);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.IS_WRITTEN_BY, location);
//    }
//    {
//      Location location = new Location(_elementC, 3, 30);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.IS_READ_WRITTEN_BY, location);
//    }
//    {
//      Location location = new Location(_elementD, 4, 40);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.IS_REFERENCED_BY, location);
//    }
//    {
//      Location location = new Location(_elementD, 5, 50);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.IS_INVOKED_BY, location);
//    }
//    _indexStore.doneIndex();
//    // search matches
//    List<SearchMatch> matches = _searchReferencesSync(Element, referencedElement);
//    // verify
//    // TODO(scheglov) why no MatchKind.FIELD_READ_WRITE ?
//    _assertMatches(matches, [
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementA, MatchKind.VARIABLE_READ, 1, 10),
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementB, MatchKind.VARIABLE_WRITE, 2, 20),
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementC, MatchKind.VARIABLE_READ_WRITE, 3, 30),
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementD, MatchKind.NAMED_PARAMETER_REFERENCE, 4, 40),
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementD, MatchKind.FUNCTION_EXECUTION, 5, 50)]);
//  }
//
//  void test_searchReferences_PropertyAccessorElement_getter() {
//    PropertyAccessorElement accessor = _mockElement(PropertyAccessorElement, ElementKind.GETTER);
//    {
//      Location location = new Location(_elementA, 1, 10);
//      _indexStore.recordRelationship(accessor, IndexConstants.IS_REFERENCED_BY_UNQUALIFIED, location);
//    }
//    {
//      Location location = new Location(_elementB, 2, 20);
//      _indexStore.recordRelationship(accessor, IndexConstants.IS_REFERENCED_BY_QUALIFIED, location);
//    }
//    _indexStore.doneIndex();
//    // search matches
//    List<SearchMatch> matches = _searchReferencesSync(Element, accessor);
//    // verify
//    _assertMatches(matches, [
//        new SearchEngineImplTest_ExpectedMatch.con2(_elementA, MatchKind.PROPERTY_ACCESSOR_REFERENCE, 1, 10, false),
//        new SearchEngineImplTest_ExpectedMatch.con2(_elementB, MatchKind.PROPERTY_ACCESSOR_REFERENCE, 2, 20, true)]);
//  }
//
//  void test_searchReferences_PropertyAccessorElement_setter() {
//    PropertyAccessorElement accessor = _mockElement(PropertyAccessorElement, ElementKind.SETTER);
//    {
//      Location location = new Location(_elementA, 1, 10);
//      _indexStore.recordRelationship(accessor, IndexConstants.IS_REFERENCED_BY_UNQUALIFIED, location);
//    }
//    {
//      Location location = new Location(_elementB, 2, 20);
//      _indexStore.recordRelationship(accessor, IndexConstants.IS_REFERENCED_BY_QUALIFIED, location);
//    }
//    _indexStore.doneIndex();
//    // search matches
//    List<SearchMatch> matches = _searchReferencesSync(Element, accessor);
//    // verify
//    _assertMatches(matches, [
//        new SearchEngineImplTest_ExpectedMatch.con2(_elementA, MatchKind.PROPERTY_ACCESSOR_REFERENCE, 1, 10, false),
//        new SearchEngineImplTest_ExpectedMatch.con2(_elementB, MatchKind.PROPERTY_ACCESSOR_REFERENCE, 2, 20, true)]);
//  }
//
//  void test_searchReferences_TopLevelVariableElement() {
//    PropertyAccessorElement getterElement = _mockElement(PropertyAccessorElement, ElementKind.GETTER);
//    PropertyAccessorElement setterElement = _mockElement(PropertyAccessorElement, ElementKind.SETTER);
//    TopLevelVariableElement topVariableElement = _mockElement(TopLevelVariableElement, ElementKind.TOP_LEVEL_VARIABLE);
//    when(topVariableElement.getter).thenReturn(getterElement);
//    when(topVariableElement.setter).thenReturn(setterElement);
//    {
//      Location location = new Location(_elementA, 1, 10);
//      _indexStore.recordRelationship(getterElement, IndexConstants.IS_REFERENCED_BY_UNQUALIFIED, location);
//    }
//    {
//      Location location = new Location(_elementC, 2, 20);
//      _indexStore.recordRelationship(setterElement, IndexConstants.IS_REFERENCED_BY_UNQUALIFIED, location);
//    }
//    _indexStore.doneIndex();
//    // search matches
//    List<SearchMatch> matches = _searchReferencesSync(Element, topVariableElement);
//    // verify
//    _assertMatches(matches, [
//        new SearchEngineImplTest_ExpectedMatch.con2(_elementA, MatchKind.FIELD_READ, 1, 10, false),
//        new SearchEngineImplTest_ExpectedMatch.con2(_elementC, MatchKind.FIELD_WRITE, 2, 20, false)]);
//  }
//
//  void test_searchReferences_TypeAliasElement() {
//    FunctionTypeAliasElement referencedElement = _mockElement(FunctionTypeAliasElement, ElementKind.FUNCTION_TYPE_ALIAS);
//    {
//      Location locationA = new Location(_elementA, 1, 2);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.IS_REFERENCED_BY, locationA);
//    }
//    {
//      Location locationB = new Location(_elementB, 10, 20);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.IS_REFERENCED_BY, locationB);
//    }
//    _indexStore.doneIndex();
//    // search matches
//    List<SearchMatch> matches = _searchReferencesSync(Element, referencedElement);
//    // verify
//    _assertMatches(matches, [
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementA, MatchKind.FUNCTION_TYPE_REFERENCE, 1, 2),
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementB, MatchKind.FUNCTION_TYPE_REFERENCE, 10, 20)]);
//  }
//
//  void test_searchReferences_TypeParameterElement() {
//    TypeParameterElement referencedElement = _mockElement(TypeParameterElement, ElementKind.TYPE_PARAMETER);
//    {
//      Location locationA = new Location(_elementA, 1, 2);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.IS_REFERENCED_BY, locationA);
//    }
//    {
//      Location locationB = new Location(_elementB, 10, 20);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.IS_REFERENCED_BY, locationB);
//    }
//    _indexStore.doneIndex();
//    // search matches
//    List<SearchMatch> matches = _searchReferencesSync(Element, referencedElement);
//    // verify
//    _assertMatches(matches, [
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementA, MatchKind.TYPE_PARAMETER_REFERENCE, 1, 2),
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementB, MatchKind.TYPE_PARAMETER_REFERENCE, 10, 20)]);
//  }
//
//  void test_searchReferences_VariableElement() {
//    LocalVariableElement referencedElement = _mockElement(LocalVariableElement, ElementKind.LOCAL_VARIABLE);
//    {
//      Location location = new Location(_elementA, 1, 10);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.IS_READ_BY, location);
//    }
//    {
//      Location location = new Location(_elementB, 2, 20);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.IS_WRITTEN_BY, location);
//    }
//    {
//      Location location = new Location(_elementC, 3, 30);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.IS_READ_WRITTEN_BY, location);
//    }
//    {
//      Location location = new Location(_elementD, 4, 40);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.IS_INVOKED_BY, location);
//    }
//    _indexStore.doneIndex();
//    // search matches
//    List<SearchMatch> matches = _searchReferencesSync(Element, referencedElement);
//    // verify
//    _assertMatches(matches, [
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementA, MatchKind.VARIABLE_READ, 1, 10),
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementB, MatchKind.VARIABLE_WRITE, 2, 20),
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementC, MatchKind.VARIABLE_READ_WRITE, 3, 30),
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementD, MatchKind.FUNCTION_EXECUTION, 4, 40)]);
//  }
//
//  void test_searchSubtypes() {
//    ClassElement referencedElement = _mockElement(ClassElement, ElementKind.CLASS);
//    {
//      Location locationA = new Location(_elementA, 10, 1);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.IS_EXTENDED_BY, locationA);
//    }
//    {
//      Location locationB = new Location(_elementB, 20, 2);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.IS_MIXED_IN_BY, locationB);
//    }
//    {
//      Location locationC = new Location(_elementC, 30, 3);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.IS_IMPLEMENTED_BY, locationC);
//    }
//    _indexStore.doneIndex();
//    // search matches
//    List<SearchMatch> matches = _runSearch(new SearchRunner_SearchEngineImplTest_test_searchSubtypes(this, referencedElement));
//    // verify
//    _assertMatches(matches, [
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementA, MatchKind.EXTENDS_REFERENCE, 10, 1),
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementB, MatchKind.WITH_REFERENCE, 20, 2),
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementC, MatchKind.IMPLEMENTS_REFERENCE, 30, 3)]);
//  }
//
//  void test_searchTypeDeclarations_async() {
//    LibraryElement library = _mockElement(LibraryElement, ElementKind.LIBRARY);
//    {
//      when(_elementA.getAncestor((element) => element is LibraryElement)).thenReturn(library);
//      Location locationA = new Location(_elementA, 1, 2);
//      _indexStore.recordRelationship(library, IndexConstants.DEFINES_CLASS, locationA);
//    }
//    _indexStore.doneIndex();
//    _scope = new LibrarySearchScope.con2([library]);
//    // search matches
//    List<SearchMatch> matches = _searchTypeDeclarationsAsync();
//    // verify
//    _assertMatches(matches, [new SearchEngineImplTest_ExpectedMatch.con1(_elementA, MatchKind.CLASS_DECLARATION, 1, 2)]);
//  }
//
//  void test_searchTypeDeclarations_class() {
//    LibraryElement library = _mockElement(LibraryElement, ElementKind.LIBRARY);
//    {
//      when(_elementA.getAncestor((element) => element is LibraryElement)).thenReturn(library);
//      Location locationA = new Location(_elementA, 1, 2);
//      _indexStore.recordRelationship(library, IndexConstants.DEFINES_CLASS, locationA);
//    }
//    _indexStore.doneIndex();
//    _scope = new LibrarySearchScope.con2([library]);
//    // search matches
//    List<SearchMatch> matches = _searchTypeDeclarationsSync();
//    // verify
//    _assertMatches(matches, [new SearchEngineImplTest_ExpectedMatch.con1(_elementA, MatchKind.CLASS_DECLARATION, 1, 2)]);
//  }
//
//  void test_searchTypeDeclarations_classAlias() {
//    LibraryElement library = _mockElement(LibraryElement, ElementKind.LIBRARY);
//    {
//      when(_elementA.getAncestor((element) => element is LibraryElement)).thenReturn(library);
//      Location locationA = new Location(_elementA, 1, 2);
//      _indexStore.recordRelationship(library, IndexConstants.DEFINES_CLASS_ALIAS, locationA);
//    }
//    _indexStore.doneIndex();
//    _scope = new LibrarySearchScope.con2([library]);
//    // search matches
//    List<SearchMatch> matches = _searchTypeDeclarationsSync();
//    // verify
//    _assertMatches(matches, [new SearchEngineImplTest_ExpectedMatch.con1(_elementA, MatchKind.CLASS_ALIAS_DECLARATION, 1, 2)]);
//  }
//
//  void test_searchTypeDeclarations_functionType() {
//    LibraryElement library = _mockElement(LibraryElement, ElementKind.LIBRARY);
//    {
//      when(_elementA.getAncestor((element) => element is LibraryElement)).thenReturn(library);
//      Location locationA = new Location(_elementA, 1, 2);
//      _indexStore.recordRelationship(library, IndexConstants.DEFINES_FUNCTION_TYPE, locationA);
//    }
//    _indexStore.doneIndex();
//    _scope = new LibrarySearchScope.con2([library]);
//    // search matches
//    List<SearchMatch> matches = _searchTypeDeclarationsSync();
//    // verify
//    _assertMatches(matches, [new SearchEngineImplTest_ExpectedMatch.con1(_elementA, MatchKind.FUNCTION_TYPE_DECLARATION, 1, 2)]);
//  }
//
//  void test_searchUnresolvedQualifiedReferences() {
//    Element referencedElement = new NameElementImpl("test");
//    {
//      Location locationA = new Location(_elementA, 1, 2);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.IS_REFERENCED_BY_QUALIFIED_RESOLVED, locationA);
//    }
//    {
//      Location locationB = new Location(_elementB, 10, 20);
//      _indexStore.recordRelationship(referencedElement, IndexConstants.IS_REFERENCED_BY_QUALIFIED_UNRESOLVED, locationB);
//    }
//    _indexStore.doneIndex();
//    // search matches
//    List<SearchMatch> matches = _searchReferencesSync2("searchQualifiedMemberReferences", String, "test");
//    // verify
//    _assertMatches(matches, [
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementA, MatchKind.NAME_REFERENCE_RESOLVED, 1, 2),
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementB, MatchKind.NAME_REFERENCE_UNRESOLVED, 10, 20)]);
//  }
//
//  void test_searchVariableDeclarations() {
//    LibraryElement library = _mockElement(LibraryElement, ElementKind.LIBRARY);
//    _defineVariablesAB(library);
//    _scope = new LibrarySearchScope.con2([library]);
//    // search matches
//    List<SearchMatch> matches = _searchVariableDeclarationsSync();
//    // verify
//    _assertMatches(matches, [
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementA, MatchKind.VARIABLE_DECLARATION, 1, 2),
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementB, MatchKind.VARIABLE_DECLARATION, 10, 20)]);
//  }
//
//  void test_searchVariableDeclarations_async() {
//    LibraryElement library = _mockElement(LibraryElement, ElementKind.LIBRARY);
//    _defineVariablesAB(library);
//    _scope = new LibrarySearchScope.con2([library]);
//    // search matches
//    List<SearchMatch> matches = _searchVariableDeclarationsAsync();
//    // verify
//    _assertMatches(matches, [
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementA, MatchKind.VARIABLE_DECLARATION, 1, 2),
//        new SearchEngineImplTest_ExpectedMatch.con1(_elementB, MatchKind.VARIABLE_DECLARATION, 10, 20)]);
//  }
//
//  void test_searchVariableDeclarations_usePattern() {
//    LibraryElement library = _mockElement(LibraryElement, ElementKind.LIBRARY);
//    _defineVariablesAB(library);
//    _scope = new LibrarySearchScope.con2([library]);
//    // search "A"
//    {
//      _pattern = SearchPatternFactory.createExactPattern("A", true);
//      List<SearchMatch> matches = _searchVariableDeclarationsSync();
//      _assertMatches(matches, [new SearchEngineImplTest_ExpectedMatch.con1(_elementA, MatchKind.VARIABLE_DECLARATION, 1, 2)]);
//    }
//    // search "B"
//    {
//      _pattern = SearchPatternFactory.createExactPattern("B", true);
//      List<SearchMatch> matches = _searchVariableDeclarationsSync();
//      _assertMatches(matches, [new SearchEngineImplTest_ExpectedMatch.con1(_elementB, MatchKind.VARIABLE_DECLARATION, 10, 20)]);
//    }
//  }
//
//  @override
//  void setUp() {
//    super.setUp();
//    // library
//    when(_unitElement.library).thenReturn(_libraryElement);
//    when(_libraryElement.definingCompilationUnit).thenReturn(_unitElement);
//    when(_unitElement.source).thenReturn(_source);
//    when(_libraryElement.source).thenReturn(_source);
//    when(_libraryElement.parts).thenReturn(new List<CompilationUnitElement>(0));
//    // elements
//    when(_elementA.toString()).thenReturn("A");
//    when(_elementB.toString()).thenReturn("B");
//    when(_elementC.toString()).thenReturn("C");
//    when(_elementD.toString()).thenReturn("D");
//    when(_elementE.toString()).thenReturn("E");
//    when(_elementA.displayName).thenReturn("A");
//    when(_elementB.displayName).thenReturn("B");
//    when(_elementC.displayName).thenReturn("C");
//    when(_elementD.displayName).thenReturn("D");
//    when(_elementE.displayName).thenReturn("E");
//    when(_elementA.source).thenReturn(_source);
//    when(_elementB.source).thenReturn(_source);
//    when(_elementC.source).thenReturn(_source);
//    when(_elementD.source).thenReturn(_source);
//    when(_elementE.source).thenReturn(_source);
//    when(_elementA.context).thenReturn(_CONTEXT);
//    when(_elementB.context).thenReturn(_CONTEXT);
//    when(_elementC.context).thenReturn(_CONTEXT);
//    when(_elementD.context).thenReturn(_CONTEXT);
//    when(_elementE.context).thenReturn(_CONTEXT);
//    when(_CONTEXT.getElement(_elementA.location)).thenReturn(_elementA);
//    when(_CONTEXT.getElement(_elementB.location)).thenReturn(_elementB);
//    when(_CONTEXT.getElement(_elementC.location)).thenReturn(_elementC);
//    when(_CONTEXT.getElement(_elementD.location)).thenReturn(_elementD);
//    when(_CONTEXT.getElement(_elementE.location)).thenReturn(_elementE);
//    // start indexing
//    JUnitTestCase.assertTrue(_indexStore.aboutToIndexDart(_CONTEXT, _unitElement));
//  }
//
//  void _defineFunctionsAB(LibraryElement library) {
//    {
//      when(_elementA.getAncestor((element) => element is LibraryElement)).thenReturn(library);
//      Location locationA = new Location(_elementA, 1, 2);
//      _indexStore.recordRelationship(library, IndexConstants.DEFINES_FUNCTION, locationA);
//    }
//    {
//      when(_elementB.getAncestor((element) => element is LibraryElement)).thenReturn(library);
//      Location locationB = new Location(_elementB, 10, 20);
//      _indexStore.recordRelationship(library, IndexConstants.DEFINES_FUNCTION, locationB);
//    }
//    _indexStore.doneIndex();
//  }
//
//  void _defineVariablesAB(LibraryElement library) {
//    {
//      when(_elementA.getAncestor((element) => element is LibraryElement)).thenReturn(library);
//      Location locationA = new Location(_elementA, 1, 2);
//      _indexStore.recordRelationship(library, IndexConstants.DEFINES_VARIABLE, locationA);
//    }
//    {
//      when(_elementB.getAncestor((element) => element is LibraryElement)).thenReturn(library);
//      Location locationB = new Location(_elementB, 10, 20);
//      _indexStore.recordRelationship(library, IndexConstants.DEFINES_VARIABLE, locationB);
//    }
//    _indexStore.doneIndex();
//  }
//
//  Element _mockElement(Type clazz, ElementKind kind) {
//    Element element = mock(clazz);
//    when(element.context).thenReturn(_CONTEXT);
//    when(element.source).thenReturn(_source);
//    when(element.kind).thenReturn(kind);
//    ElementLocation elementLocation = new ElementLocationImpl.con2("mockLocation${_nextLocationId++}");
//    when(element.location).thenReturn(elementLocation);
//    when(_CONTEXT.getElement(element.location)).thenReturn(element);
//    return element;
//  }
//
//  Object _runSearch(SearchEngineImplTest_SearchRunner runner) {
//    OperationQueue queue = new OperationQueue();
//    OperationProcessor processor = new OperationProcessor(queue);
//    Index index = new IndexImpl(_indexStore, queue, processor);
//    SearchEngine engine = SearchEngineFactory.createSearchEngine(index);
//    try {
//      new Thread_SearchEngineImplTest_runSearch(processor).start();
//      processor.waitForRunning();
//      return runner.run(queue, processor, index, engine);
//    } finally {
//      processor.stop(false);
//    }
//  }
//
//  List<SearchMatch> _searchDeclarationsAsync(String methodName) => _runSearch(new SearchRunner_SearchEngineImplTest_searchDeclarationsAsync(this, methodName, this, matches, latch));
//
//  List<SearchMatch> _searchDeclarationsSync(String methodName) => _runSearch(new SearchRunner_SearchEngineImplTest_searchDeclarationsSync(this, methodName));
//
//  List<SearchMatch> _searchFunctionDeclarationsAsync() => _searchDeclarationsAsync("searchFunctionDeclarations");
//
//  List<SearchMatch> _searchFunctionDeclarationsSync() => _searchDeclarationsSync("searchFunctionDeclarations");
//
//  List<SearchMatch> _searchReferencesSync(Type clazz, Object element) => _searchReferencesSync2("searchReferences", clazz, element);
//
//  List<SearchMatch> _searchReferencesSync2(String methodName, Type clazz, Object element) => _runSearch(new SearchRunner_SearchEngineImplTest_searchReferencesSync(this, methodName, clazz, element));
//
//  List<SearchMatch> _searchTypeDeclarationsAsync() => _searchDeclarationsAsync("searchTypeDeclarations");
//
//  List<SearchMatch> _searchTypeDeclarationsSync() => _searchDeclarationsSync("searchTypeDeclarations");
//
//  List<SearchMatch> _searchVariableDeclarationsAsync() => _searchDeclarationsAsync("searchVariableDeclarations");
//
//  List<SearchMatch> _searchVariableDeclarationsSync() => _searchDeclarationsSync("searchVariableDeclarations");
//
//  static dartSuite() {
//    _ut.group('SearchEngineImplTest', () {
//      _ut.test('test_searchDeclarations_String', () {
//        final __test = new SearchEngineImplTest();
//        runJUnitTest(__test, __test.test_searchDeclarations_String);
//      });
//      _ut.test('test_searchFunctionDeclarations', () {
//        final __test = new SearchEngineImplTest();
//        runJUnitTest(__test, __test.test_searchFunctionDeclarations);
//      });
//      _ut.test('test_searchFunctionDeclarations_async', () {
//        final __test = new SearchEngineImplTest();
//        runJUnitTest(__test, __test.test_searchFunctionDeclarations_async);
//      });
//      _ut.test('test_searchFunctionDeclarations_inUniverse', () {
//        final __test = new SearchEngineImplTest();
//        runJUnitTest(__test, __test.test_searchFunctionDeclarations_inUniverse);
//      });
//      _ut.test('test_searchFunctionDeclarations_useFilter', () {
//        final __test = new SearchEngineImplTest();
//        runJUnitTest(__test, __test.test_searchFunctionDeclarations_useFilter);
//      });
//      _ut.test('test_searchFunctionDeclarations_usePattern', () {
//        final __test = new SearchEngineImplTest();
//        runJUnitTest(__test, __test.test_searchFunctionDeclarations_usePattern);
//      });
//      _ut.test('test_searchReferences_AngularComponentElement', () {
//        final __test = new SearchEngineImplTest();
//        runJUnitTest(__test, __test.test_searchReferences_AngularComponentElement);
//      });
//      _ut.test('test_searchReferences_AngularControllerElement', () {
//        final __test = new SearchEngineImplTest();
//        runJUnitTest(__test, __test.test_searchReferences_AngularControllerElement);
//      });
//      _ut.test('test_searchReferences_AngularFilterElement', () {
//        final __test = new SearchEngineImplTest();
//        runJUnitTest(__test, __test.test_searchReferences_AngularFilterElement);
//      });
//      _ut.test('test_searchReferences_AngularPropertyElement', () {
//        final __test = new SearchEngineImplTest();
//        runJUnitTest(__test, __test.test_searchReferences_AngularPropertyElement);
//      });
//      _ut.test('test_searchReferences_AngularScopePropertyElement', () {
//        final __test = new SearchEngineImplTest();
//        runJUnitTest(__test, __test.test_searchReferences_AngularScopePropertyElement);
//      });
//      _ut.test('test_searchReferences_AngularSelectorElement', () {
//        final __test = new SearchEngineImplTest();
//        runJUnitTest(__test, __test.test_searchReferences_AngularSelectorElement);
//      });
//      _ut.test('test_searchReferences_ClassElement', () {
//        final __test = new SearchEngineImplTest();
//        runJUnitTest(__test, __test.test_searchReferences_ClassElement);
//      });
//      _ut.test('test_searchReferences_ClassElement_useScope', () {
//        final __test = new SearchEngineImplTest();
//        runJUnitTest(__test, __test.test_searchReferences_ClassElement_useScope);
//      });
//      _ut.test('test_searchReferences_CompilationUnitElement', () {
//        final __test = new SearchEngineImplTest();
//        runJUnitTest(__test, __test.test_searchReferences_CompilationUnitElement);
//      });
//      _ut.test('test_searchReferences_ConstructorElement', () {
//        final __test = new SearchEngineImplTest();
//        runJUnitTest(__test, __test.test_searchReferences_ConstructorElement);
//      });
//      _ut.test('test_searchReferences_Element_unknown', () {
//        final __test = new SearchEngineImplTest();
//        runJUnitTest(__test, __test.test_searchReferences_Element_unknown);
//      });
//      _ut.test('test_searchReferences_FieldElement', () {
//        final __test = new SearchEngineImplTest();
//        runJUnitTest(__test, __test.test_searchReferences_FieldElement);
//      });
//      _ut.test('test_searchReferences_FieldElement2', () {
//        final __test = new SearchEngineImplTest();
//        runJUnitTest(__test, __test.test_searchReferences_FieldElement2);
//      });
//      _ut.test('test_searchReferences_FieldElement_invocation', () {
//        final __test = new SearchEngineImplTest();
//        runJUnitTest(__test, __test.test_searchReferences_FieldElement_invocation);
//      });
//      _ut.test('test_searchReferences_FunctionElement', () {
//        final __test = new SearchEngineImplTest();
//        runJUnitTest(__test, __test.test_searchReferences_FunctionElement);
//      });
//      _ut.test('test_searchReferences_ImportElement', () {
//        final __test = new SearchEngineImplTest();
//        runJUnitTest(__test, __test.test_searchReferences_ImportElement);
//      });
//      _ut.test('test_searchReferences_LibraryElement', () {
//        final __test = new SearchEngineImplTest();
//        runJUnitTest(__test, __test.test_searchReferences_LibraryElement);
//      });
//      _ut.test('test_searchReferences_MethodElement', () {
//        final __test = new SearchEngineImplTest();
//        runJUnitTest(__test, __test.test_searchReferences_MethodElement);
//      });
//      _ut.test('test_searchReferences_MethodMember', () {
//        final __test = new SearchEngineImplTest();
//        runJUnitTest(__test, __test.test_searchReferences_MethodMember);
//      });
//      _ut.test('test_searchReferences_ParameterElement', () {
//        final __test = new SearchEngineImplTest();
//        runJUnitTest(__test, __test.test_searchReferences_ParameterElement);
//      });
//      _ut.test('test_searchReferences_PropertyAccessorElement_getter', () {
//        final __test = new SearchEngineImplTest();
//        runJUnitTest(__test, __test.test_searchReferences_PropertyAccessorElement_getter);
//      });
//      _ut.test('test_searchReferences_PropertyAccessorElement_setter', () {
//        final __test = new SearchEngineImplTest();
//        runJUnitTest(__test, __test.test_searchReferences_PropertyAccessorElement_setter);
//      });
//      _ut.test('test_searchReferences_TopLevelVariableElement', () {
//        final __test = new SearchEngineImplTest();
//        runJUnitTest(__test, __test.test_searchReferences_TopLevelVariableElement);
//      });
//      _ut.test('test_searchReferences_TypeAliasElement', () {
//        final __test = new SearchEngineImplTest();
//        runJUnitTest(__test, __test.test_searchReferences_TypeAliasElement);
//      });
//      _ut.test('test_searchReferences_TypeParameterElement', () {
//        final __test = new SearchEngineImplTest();
//        runJUnitTest(__test, __test.test_searchReferences_TypeParameterElement);
//      });
//      _ut.test('test_searchReferences_VariableElement', () {
//        final __test = new SearchEngineImplTest();
//        runJUnitTest(__test, __test.test_searchReferences_VariableElement);
//      });
//      _ut.test('test_searchReferences_notSupported', () {
//        final __test = new SearchEngineImplTest();
//        runJUnitTest(__test, __test.test_searchReferences_notSupported);
//      });
//      _ut.test('test_searchSubtypes', () {
//        final __test = new SearchEngineImplTest();
//        runJUnitTest(__test, __test.test_searchSubtypes);
//      });
//      _ut.test('test_searchTypeDeclarations_async', () {
//        final __test = new SearchEngineImplTest();
//        runJUnitTest(__test, __test.test_searchTypeDeclarations_async);
//      });
//      _ut.test('test_searchTypeDeclarations_class', () {
//        final __test = new SearchEngineImplTest();
//        runJUnitTest(__test, __test.test_searchTypeDeclarations_class);
//      });
//      _ut.test('test_searchTypeDeclarations_classAlias', () {
//        final __test = new SearchEngineImplTest();
//        runJUnitTest(__test, __test.test_searchTypeDeclarations_classAlias);
//      });
//      _ut.test('test_searchTypeDeclarations_functionType', () {
//        final __test = new SearchEngineImplTest();
//        runJUnitTest(__test, __test.test_searchTypeDeclarations_functionType);
//      });
//      _ut.test('test_searchUnresolvedQualifiedReferences', () {
//        final __test = new SearchEngineImplTest();
//        runJUnitTest(__test, __test.test_searchUnresolvedQualifiedReferences);
//      });
//      _ut.test('test_searchVariableDeclarations', () {
//        final __test = new SearchEngineImplTest();
//        runJUnitTest(__test, __test.test_searchVariableDeclarations);
//      });
//      _ut.test('test_searchVariableDeclarations_async', () {
//        final __test = new SearchEngineImplTest();
//        runJUnitTest(__test, __test.test_searchVariableDeclarations_async);
//      });
//      _ut.test('test_searchVariableDeclarations_usePattern', () {
//        final __test = new SearchEngineImplTest();
//        runJUnitTest(__test, __test.test_searchVariableDeclarations_usePattern);
//      });
//    });
//  }
//}
//
//class SearchEngineImplTest_ExpectedMatch {
//  final Element _element;
//
//  final MatchKind _kind;
//
//  final MatchQuality _quality;
//
//  SourceRange _range;
//
//  final bool _qualified;
//
//  SearchEngineImplTest_ExpectedMatch.con1(Element element, MatchKind kind, int offset, int length) : this.con3(element, kind, MatchQuality.EXACT, offset, length);
//
//  SearchEngineImplTest_ExpectedMatch.con2(Element element, MatchKind kind, int offset, int length, bool qualified) : this.con4(element, kind, MatchQuality.EXACT, offset, length, qualified);
//
//  SearchEngineImplTest_ExpectedMatch.con3(Element element, MatchKind kind, MatchQuality quality, int offset, int length) : this.con4(element, kind, quality, offset, length, false);
//
//  SearchEngineImplTest_ExpectedMatch.con4(this._element, this._kind, this._quality, int offset, int length, this._qualified) {
//    this._range = new SourceRange(offset, length);
//  }
//}
//
//abstract class SearchEngineImplTest_SearchRunner<T> {
//  T run(OperationQueue queue, OperationProcessor processor, Index index, SearchEngine engine);
//}
//
//class SearchFilter_SearchEngineImplTest_test_searchFunctionDeclarations_useFilter implements SearchFilter {
//  final SearchEngineImplTest SearchEngineImplTest_this;
//
//  SearchFilter_SearchEngineImplTest_test_searchFunctionDeclarations_useFilter(this.SearchEngineImplTest_this);
//
//  @override
//  bool passes(SearchMatch match) => identical(match.element, SearchEngineImplTest_this._elementB);
//}
//
//class SearchFilter_SearchEngineImplTest_test_searchFunctionDeclarations_useFilter_2 implements SearchFilter {
//  final SearchEngineImplTest SearchEngineImplTest_this;
//
//  SearchFilter_SearchEngineImplTest_test_searchFunctionDeclarations_useFilter_2(this.SearchEngineImplTest_this);
//
//  @override
//  bool passes(SearchMatch match) => identical(match.element, SearchEngineImplTest_this._elementA);
//}
//
//class SearchListener_SearchRunner_117_run implements SearchListener {
//  List<SearchMatch> matches;
//
//  CountDownLatch latch;
//
//  SearchListener_SearchRunner_117_run(this.matches, this.latch);
//
//  @override
//  void matchFound(SearchMatch match) {
//    matches.add(match);
//  }
//
//  @override
//  void searchComplete() {
//    latch.countDown();
//  }
//}
//
//class SearchRunner_SearchEngineImplTest_fail_searchAssignedTypes_assignments implements SearchEngineImplTest_SearchRunner {
//  FieldElement fieldElement;
//
//  SearchRunner_SearchEngineImplTest_fail_searchAssignedTypes_assignments(this.fieldElement, this.fieldElement);
//
//  @override
//  Set<DartType> run(OperationQueue queue, OperationProcessor processor, Index index, SearchEngine engine) => engine.searchAssignedTypes(fieldElement, new SearchScope_SearchRunner_109_run());
//}
//
//class SearchRunner_SearchEngineImplTest_fail_searchAssignedTypes_initializers implements SearchEngineImplTest_SearchRunner {
//  FieldElement fieldElement;
//
//  SearchRunner_SearchEngineImplTest_fail_searchAssignedTypes_initializers(this.fieldElement);
//
//  @override
//  Set<DartType> run(OperationQueue queue, OperationProcessor processor, Index index, SearchEngine engine) => engine.searchAssignedTypes(fieldElement, null);
//}
//
//class SearchRunner_SearchEngineImplTest_searchDeclarationsAsync implements SearchEngineImplTest_SearchRunner {
//  final SearchEngineImplTest SearchEngineImplTest_this;
//
//  String methodName;
//
//  final SearchEngineImplTest SearchEngineImplTest_this;
//
//  List<SearchMatch> matches;
//
//  CountDownLatch latch;
//
//  SearchRunner_SearchEngineImplTest_searchDeclarationsAsync(this.SearchEngineImplTest_this, this.methodName, this.SearchEngineImplTest_this, this.matches, this.latch, this.SearchEngineImplTest_this, this.methodName, this.SearchEngineImplTest_this, this.matches, this.latch);
//
//  @override
//  List<SearchMatch> run(OperationQueue queue, OperationProcessor processor, Index index, SearchEngine engine) {
//    CountDownLatch latch = new CountDownLatch(1);
//    List<SearchMatch> matches = [];
//    engine.runtimeType.getMethod(methodName, [SearchScope, SearchPattern, SearchFilter, SearchListener]).invoke(engine, [
//        SearchEngineImplTest_this._scope,
//        SearchEngineImplTest_this._pattern,
//        SearchEngineImplTest_this._filter,
//        new SearchListener_SearchRunner_117_run(matches, latch)]);
//    latch.await(30, TimeUnit.SECONDS);
//    return matches;
//  }
//}
//
//class SearchRunner_SearchEngineImplTest_searchDeclarationsSync implements SearchEngineImplTest_SearchRunner {
//  final SearchEngineImplTest SearchEngineImplTest_this;
//
//  String methodName;
//
//  SearchRunner_SearchEngineImplTest_searchDeclarationsSync(this.SearchEngineImplTest_this, this.methodName);
//
//  @override
//  List<SearchMatch> run(OperationQueue queue, OperationProcessor processor, Index index, SearchEngine engine) => engine.runtimeType.getMethod(methodName, [SearchScope, SearchPattern, SearchFilter]).invoke(engine, [
//      SearchEngineImplTest_this._scope,
//      SearchEngineImplTest_this._pattern,
//      SearchEngineImplTest_this._filter]) as List<SearchMatch>;
//}
//
//class SearchRunner_SearchEngineImplTest_searchReferencesSync implements SearchEngineImplTest_SearchRunner {
//  final SearchEngineImplTest SearchEngineImplTest_this;
//
//  String methodName;
//
//  Type clazz;
//
//  Object element;
//
//  SearchRunner_SearchEngineImplTest_searchReferencesSync(this.SearchEngineImplTest_this, this.methodName, this.clazz, this.element);
//
//  @override
//  List<SearchMatch> run(OperationQueue queue, OperationProcessor processor, Index index, SearchEngine engine) {
//    // pass some operation to wait if search will not call processor
//    queue.enqueue(mock(IndexOperation));
//    // run actual search
//    return engine.runtimeType.getMethod(methodName, [clazz, SearchScope, SearchFilter]).invoke(engine, [
//        element,
//        SearchEngineImplTest_this._scope,
//        SearchEngineImplTest_this._filter]) as List<SearchMatch>;
//  }
//}
//
//class SearchRunner_SearchEngineImplTest_test_searchDeclarations_String implements SearchEngineImplTest_SearchRunner {
//  final SearchEngineImplTest SearchEngineImplTest_this;
//
//  SearchRunner_SearchEngineImplTest_test_searchDeclarations_String(this.SearchEngineImplTest_this);
//
//  @override
//  List<SearchMatch> run(OperationQueue queue, OperationProcessor processor, Index index, SearchEngine engine) => engine.searchDeclarations("test", SearchEngineImplTest_this._scope, SearchEngineImplTest_this._filter);
//}
//
//class SearchRunner_SearchEngineImplTest_test_searchSubtypes implements SearchEngineImplTest_SearchRunner {
//  final SearchEngineImplTest SearchEngineImplTest_this;
//
//  ClassElement referencedElement;
//
//  SearchRunner_SearchEngineImplTest_test_searchSubtypes(this.SearchEngineImplTest_this, this.referencedElement);
//
//  @override
//  List<SearchMatch> run(OperationQueue queue, OperationProcessor processor, Index index, SearchEngine engine) => engine.searchSubtypes(referencedElement, SearchEngineImplTest_this._scope, SearchEngineImplTest_this._filter);
//}
//
//class SearchScope_SearchRunner_109_run implements SearchScope {
//  @override
//  bool encloses(Element element) => !identical(element, _elementC);
//}
//
//class Thread_SearchEngineImplTest_runSearch extends Thread {
//  OperationProcessor processor;
//
//  Thread_SearchEngineImplTest_runSearch(this.processor) : super();
//
//  @override
//  void run() {
//    processor.run();
//  }
//}
//
//class UniverseSearchScopeTest extends EngineTestCase {
//  SearchScope _scope = new UniverseSearchScope();
//
//  Element _element = mock(Element);
//
//  void test_anyElement() {
//    JUnitTestCase.assertTrue(_scope.encloses(_element));
//  }
//
//  void test_nullElement() {
//    JUnitTestCase.assertTrue(_scope.encloses(null));
//  }
//
//  static dartSuite() {
//    _ut.group('UniverseSearchScopeTest', () {
//      _ut.test('test_anyElement', () {
//        final __test = new UniverseSearchScopeTest();
//        runJUnitTest(__test, __test.test_anyElement);
//      });
//      _ut.test('test_nullElement', () {
//        final __test = new UniverseSearchScopeTest();
//        runJUnitTest(__test, __test.test_nullElement);
//      });
//    });
//  }
//}
//
//class WildcardSearchPatternTest extends EngineTestCase {
//  Element _element = mock(Element);
//
//  void test_caseInsensitive_false_contentMismatch() {
//    SearchPattern pattern = new WildcardSearchPattern("H*Map", false);
//    when(_element.displayName).thenReturn("Maps");
//    // validate
//    JUnitTestCase.assertSame(null, pattern.matches(_element));
//  }
//
//  void test_caseInsensitive_true_caseMismatch() {
//    SearchPattern pattern = new WildcardSearchPattern("H*MaP", false);
//    when(_element.displayName).thenReturn("HashMap");
//    // validate
//    JUnitTestCase.assertSame(MatchQuality.EXACT, pattern.matches(_element));
//  }
//
//  void test_caseSensitive_false_caseMismatch() {
//    SearchPattern pattern = new WildcardSearchPattern("H*MaP", true);
//    when(_element.displayName).thenReturn("HashMap");
//    // validate
//    JUnitTestCase.assertSame(null, pattern.matches(_element));
//  }
//
//  void test_caseSensitive_false_contentMismatch() {
//    SearchPattern pattern = new WildcardSearchPattern("H*Map", false);
//    when(_element.displayName).thenReturn("Maps");
//    // validate
//    JUnitTestCase.assertSame(null, pattern.matches(_element));
//  }
//
//  void test_caseSensitive_true() {
//    SearchPattern pattern = new WildcardSearchPattern("H*Ma?", false);
//    when(_element.displayName).thenReturn("HashMap");
//    // validate
//    JUnitTestCase.assertSame(MatchQuality.EXACT, pattern.matches(_element));
//  }
//
//  void test_nullElement() {
//    SearchPattern pattern = new WildcardSearchPattern("H*Map", false);
//    // validate
//    JUnitTestCase.assertSame(null, pattern.matches(null));
//  }
//
//  void test_nullName() {
//    SearchPattern pattern = new WildcardSearchPattern("H*Map", false);
//    when(_element.displayName).thenReturn(null);
//    // validate
//    JUnitTestCase.assertSame(null, pattern.matches(_element));
//  }
//
//  static dartSuite() {
//    _ut.group('WildcardSearchPatternTest', () {
//      _ut.test('test_caseInsensitive_false_contentMismatch', () {
//        final __test = new WildcardSearchPatternTest();
//        runJUnitTest(__test, __test.test_caseInsensitive_false_contentMismatch);
//      });
//      _ut.test('test_caseInsensitive_true_caseMismatch', () {
//        final __test = new WildcardSearchPatternTest();
//        runJUnitTest(__test, __test.test_caseInsensitive_true_caseMismatch);
//      });
//      _ut.test('test_caseSensitive_false_caseMismatch', () {
//        final __test = new WildcardSearchPatternTest();
//        runJUnitTest(__test, __test.test_caseSensitive_false_caseMismatch);
//      });
//      _ut.test('test_caseSensitive_false_contentMismatch', () {
//        final __test = new WildcardSearchPatternTest();
//        runJUnitTest(__test, __test.test_caseSensitive_false_contentMismatch);
//      });
//      _ut.test('test_caseSensitive_true', () {
//        final __test = new WildcardSearchPatternTest();
//        runJUnitTest(__test, __test.test_caseSensitive_true);
//      });
//      _ut.test('test_nullElement', () {
//        final __test = new WildcardSearchPatternTest();
//        runJUnitTest(__test, __test.test_nullElement);
//      });
//      _ut.test('test_nullName', () {
//        final __test = new WildcardSearchPatternTest();
//        runJUnitTest(__test, __test.test_nullName);
//      });
//    });
//  }
//}
//
//main() {
//  CountingSearchListenerTest.dartSuite();
//  FilterSearchListenerTest.dartSuite();
//  GatheringSearchListenerTest.dartSuite();
//  NameMatchingSearchListenerTest.dartSuite();
//  LibrarySearchScopeTest.dartSuite();
//  UniverseSearchScopeTest.dartSuite();
//  SearchEngineImplTest.dartSuite();
//  AndSearchPatternTest.dartSuite();
//  CamelCaseSearchPatternTest.dartSuite();
//  ExactSearchPatternTest.dartSuite();
//  OrSearchPatternTest.dartSuite();
//  PrefixSearchPatternTest.dartSuite();
//  RegularExpressionSearchPatternTest.dartSuite();
//  WildcardSearchPatternTest.dartSuite();
//}
