// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/completion/filtering/fuzzy_matcher.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FuzzyMapTest);
    defineReflectiveTests(FuzzyMatcherTest);
    defineReflectiveTests(FuzzyScorerTest);
    defineReflectiveTests(ScoringFunctionTest);
  });
}

/// Surrounds all matching ranges with brackets.
String highlightMatches(String str, FuzzyMatcher matcher) {
  var matches = matcher.getMatchedRanges();
  expect(matches.length % 2, 0);
  for (var i = 1; i < matches.length; i++) {
    expect(matches[i], isNot(lessThan(matches[i - 1])));
  }

  var index = 0;
  var result = '';
  for (var i = 0; i < matches.length - 1; i += 2) {
    result += str.substring(index, matches[i]) +
        '[' +
        str.substring(matches[i], matches[i + 1]) +
        ']';
    index = matches[i + 1];
  }
  return result + str.substring(index);
}

@reflectiveTest
class FuzzyMapTest {
  static MatchStyle FILE = MatchStyle.FILENAME;
  static MatchStyle SYM = MatchStyle.SYMBOL;

  void map(
      {@required String str,
      @required String want,
      MatchStyle matchStyle = MatchStyle.TEXT}) {
//    test('maps characters of $str', () {
    var out = List<CharRole>.filled(str.length, CharRole.NONE);
    var matcher = FuzzyMatcher('', matchStyle: matchStyle);
    matcher.fuzzyMap(str, out);
    var result = '';
    var map = ' /cuC';
    for (var i = 0; i < str.length; i++) {
      result += map[out[i].index];
    }
    expect(result, want);
//    });
  }

  void test_map() {
    // Text
    map(str: 'abc', want: 'Ccc');
    map(str: '.abc', want: ' Ccc');
    map(str: 'abc def', want: 'Ccc Ccc');
    map(str: 'SWT MyID', want: 'Cuu CcCu');
    map(str: 'ID', want: 'Cu');
    map(str: ' ID ', want: ' Cu ');
    map(str: 'IDSome', want: 'CuCccc');
    map(str: '0123456789', want: 'Cccccccccc');
    map(str: 'abcdefghigklmnopqrstuvwxyz', want: 'Cccccccccccccccccccccccccc');
    map(str: 'ABCDEFGHIGKLMNOPQRSTUVWXYZ', want: 'Cuuuuuuuuuuuuuuuuuuuuuuuuu');
    map(str: 'こんにちは', want: 'Ccccc');
    map(str: ':/.', want: '   ');

    // File names
    map(str: 'abc/def', want: 'Ccc/Ccc', matchStyle: FILE);
    map(str: ' abc_def', want: ' Ccc Ccc', matchStyle: FILE);
    map(str: ' abc_DDf', want: ' Ccc CCc', matchStyle: FILE);
    map(str: ':.', want: '  ', matchStyle: FILE);

    // Symbols
    map(str: 'abc::def::goo', want: 'Ccc//Ccc//Ccc', matchStyle: SYM);
    map(str: 'proto::Message', want: 'Ccccc//Ccccccc', matchStyle: SYM);
    map(str: 'AbstractSWTFactory', want: 'CcccccccCuuCcccccc', matchStyle: SYM);
    map(str: 'Abs012', want: 'Cccccc', matchStyle: SYM);
    map(str: 'public setFoo', want: 'Cccccc/CccCcc', matchStyle: SYM);
    map(str: '/', want: ' ', matchStyle: SYM);
  }
}

@reflectiveTest
class FuzzyMatcherTest {
  void expectMatch(FuzzyMatcher matcher, String str, String expected) {
    expect(matcher.score(str), greaterThan(0));
    expect(highlightMatches(str, matcher), expected);
  }

  void test_considersTheEmptyStringToMatchAll() {
    var matcher = FuzzyMatcher('');
    expect(matcher.score('def'), greaterThan(0));
    expect(matcher.getMatchedRanges(), []);
    expect(matcher.score('Ab stuff c'), greaterThan(0));
    expect(matcher.getMatchedRanges(), []);
  }

  void test_ranksActions() {
    var matcher = FuzzyMatcher('jade', matchStyle: MatchStyle.TEXT);
    // Full word matches score higher than subsequence matches.
    expect(
        matcher.score('jump to a directory in tree'),
        lessThan(matcher
            .score('fix imports and dependencies using jade (java only)')));

    matcher = FuzzyMatcher('unedit', matchStyle: MatchStyle.TEXT);
    expect(matcher.score('Undo an edit'),
        lessThan(matcher.score('Close unedited tabs')));

    matcher = FuzzyMatcher('fix', matchStyle: MatchStyle.TEXT);
    expect(
        matcher.score('find next match'),
        lessThan(
            matcher.score('format edited lines in workspace files (g4 fix)')));
  }

  void test_ranksFileNames() {
    var matcher = FuzzyMatcher('aa', matchStyle: MatchStyle.FILENAME);
    // Full word matches scores higher than subsequence matches.
    expect(matcher.score('a/a/a'), lessThan(matcher.score('b/aa')));
    // Matches starting at the word boundary score higher.
    expect(matcher.score('baab'), lessThan(matcher.score('aabb')));
    // First word scores higher than later ones.
    expect(matcher.score('bb_aa'), lessThan(matcher.score('aa_bb')));
    // Tails don't matter.
    expect(matcher.score('aa_b'), matcher.score('aab'));
  }

  void test_ranksSymbols() {
    var matcher = FuzzyMatcher('Foo', matchStyle: MatchStyle.SYMBOL);
    // Prefix and complete matches are the same.
    expect(matcher.score('FooA'), matcher.score('Foo'));
    // First word scores higher than later ones.
    expect(matcher.score('BarFoo'), lessThan(matcher.score('FooBar')));
    // Aligned matches score higher.
    expect(matcher.score('Barfoo'), lessThan(matcher.score('BarFoo')));
    expect(matcher.score('F__oo'), matcher.score('F_oo'));
    expect(matcher.score('F_o_o'), lessThan(matcher.score('F_oo')));
    // Missed word vs a match in the middle.
    expect(matcher.score('BarFaoo'), lessThan(matcher.score('BarFaoFooa')));

    matcher = FuzzyMatcher('FooBar', matchStyle: MatchStyle.SYMBOL);
    // Ignores incomplete matches
    expect(matcher.score('FooaBar'), lessThan(matcher.score('FooBar')));
    expect(matcher.score('FooBara'), matcher.score('FooBar'));
    // Less words in the middle is better.
    expect(matcher.score('FooAtBaBar'), lessThan(matcher.score('FooAtBar')));
    expectMatch(matcher, 'FooAtBaBar', '[Foo]AtBa[Bar]');
  }

  void test_respectsTheBasename() {
    var matcher = FuzzyMatcher('subs', matchStyle: MatchStyle.FILENAME);
    expect(matcher.score('sub/seq'), greaterThanOrEqualTo(0));
    expect(matcher.score('sub/seq/end'), -1);
    expect(matcher.score('sub/seq'), greaterThanOrEqualTo(0));
    expect(matcher.score('sub/seq/base'), greaterThanOrEqualTo(0));
  }

  void test_worksWithDepotPaths() {
    var matcher = FuzzyMatcher('subs', matchStyle: MatchStyle.FILENAME);
    expect(matcher.score('//sub/seq'), greaterThanOrEqualTo(0));
    expect(matcher.score('//sub/seq/end'), -1);
    expect(matcher.score('//sub/seq'), greaterThanOrEqualTo(0));
    expect(matcher.score('//sub/seq/base'), greaterThanOrEqualTo(0));
  }

  void test_worksWithSimpleCases() {
    var matcher = FuzzyMatcher('abc');
    expect(matcher.score('def'), -1);
    expect(matcher.score('abd'), -1);
    expect(matcher.score('abc'), greaterThan(0));
    expect(matcher.score('Abc'), greaterThan(0));
    expect(matcher.score('Ab stuff c'), greaterThan(0));
  }

  void test_worksWithUpperCasePatterns() {
    var matcher = FuzzyMatcher('Abc');
    expect(matcher.score('def'), -1);
    expect(matcher.score('abd'), -1);
    expect(matcher.score('abc'), greaterThan(0));
    expect(matcher.score('Abc'), greaterThan(0));
    expect(matcher.score('Ab stuff c'), greaterThan(0));
  }
}

@reflectiveTest
class FuzzyScorerTest {
  static MatchStyle FILE = MatchStyle.FILENAME;

  static MatchStyle SYM = MatchStyle.SYMBOL;

  void score(
      {@required String p,
      @required String str,
      String want,
      MatchStyle input = MatchStyle.TEXT}) {
//    test('scores $str against $p', () {
    var matcher = FuzzyMatcher(p, matchStyle: input);
    if (want != null) {
      expect(matcher.score(str), greaterThanOrEqualTo(0));
      expect(highlightMatches(str, matcher), want);
    } else {
      expect(matcher.score(str), -1);
    }
//    });
  }

  void test_scorer() {
    // Text
    score(p: 'a', str: 'abc', want: '[a]bc');
    score(p: 'aaa', str: 'aaa', want: '[aaa]');
    score(p: 'aaa', str: 'abab');
    score(p: 'aaba', str: 'abababa', want: '[a]b[aba]ba');
    score(p: 'cabaa', str: 'c_babababa', want: '[c]_b[aba]b[a]ba');
    score(p: 'caaa', str: 'c_babababaaa', want: '[c]_bababab[aaa]');
    score(p: 'aaa', str: 'aaababababaaa', want: '[aaa]babababaaa');
    score(
        p: 'unedit', str: 'Close unedited tabs', want: 'Close [unedit]ed tabs');
    // Forward slashes are ignored in the non-filename mode.
    score(p: 'aaa', str: 'aaabab/ababaaa', want: '[aaa]bab/ababaaa');
    score(p: 'aaa', str: 'baaabab/abab_aaa', want: 'baaabab/abab_[aaa]');

    // Filenames.
    score(p: 'aa', str: 'a_a/a_a', want: '[a]_a/[a]_a', input: FILE);
    score(p: 'aaaa', str: 'a_a/a_a', want: '[a]_[a]/[a]_[a]', input: FILE);
    score(p: 'aaaa', str: 'aaaa', want: '[aaaa]', input: FILE);
    score(p: 'aaaa', str: 'a_a/a_aaaa', want: 'a_a/[a]_[aaa]a', input: FILE);
    score(p: 'aaaa', str: 'a_a/aaaaa', want: 'a_a/[aaaa]a', input: FILE);
    score(p: 'aaaa', str: 'aabaaa', want: '[aa]b[aa]a', input: FILE);
    score(p: 'aaaa', str: 'a/baaa', want: '[a]/b[aaa]', input: FILE);
    score(p: 'aaaa', str: 'a/baaa/', want: '[a]/b[aaa]/', input: FILE);
    score(
        p: 'abcxz',
        str: 'd/abc/abcd/oxz',
        want: 'd/[abc]/abcd/o[xz]',
        input: FILE);
    score(
        p: 'abcxz',
        str: 'd/abcd/abc/oxz',
        want: 'd/[abc]d/abc/o[xz]',
        input: FILE);

    // Symbols
    score(p: 'foo', str: 'abc::foo', want: 'abc::[foo]', input: SYM);
    score(p: 'foo', str: 'abc::foo::', want: 'abc::[foo]::', input: SYM);
    score(p: 'foo', str: 'foo.foo', want: 'foo.[foo]', input: SYM);
    score(p: 'foo', str: 'fo_oo.oo_oo', want: '[f]o_oo.[oo]_oo', input: SYM);
    score(p: 'foo', str: 'fo_oo.fo_oo', want: 'fo_oo.[fo]_[o]o', input: SYM);
    score(p: 'fo_o', str: 'fo_oo.o_oo', want: '[f]o_oo.[o_o]o', input: SYM);
    score(p: 'fOO', str: 'fo_oo.o_oo', want: '[f]o_oo.[o]_[o]o', input: SYM);
    score(
        p: 'tedit', str: 'foo.TextEdit', want: 'foo.[T]ext[Edit]', input: SYM);
    score(
        p: 'tedit',
        str: '*foo.TextEdit',
        want: '*foo.[T]ext[Edit]',
        input: SYM);
    score(
        p: 'TEdit', str: 'foo.TextEdit', want: 'foo.[T]ext[Edit]', input: SYM);
    score(
        p: 'Tedit', str: 'foo.TextEdit', want: 'foo.[T]ext[Edit]', input: SYM);
    score(
        p: 'Tedit', str: 'foo.Textedit', want: 'foo.[Te]xte[dit]', input: SYM);
    score(p: 'TEdit', str: 'foo.Textedit', input: SYM);
    score(p: 'te', str: 'foo.Textedit', want: 'foo.[Te]xtedit', input: SYM);
    score(p: 'ee', str: 'foo.Textedit', input: SYM);
    score(p: 'ex', str: 'foo.Textedit', want: 'foo.T[ex]tedit', input: SYM);
    score(p: 'exdi', str: 'foo.Textedit', input: SYM);
    score(p: 'exdit', str: 'foo.Textedit', input: SYM);
    score(
        p: 'extdit', str: 'foo.Textedit', want: 'foo.T[ext]e[dit]', input: SYM);
    score(p: 'e', str: 'foo.Textedit', want: 'foo.T[e]xtedit', input: SYM);
    score(p: 'ed', str: 'foo.Textedit', want: 'foo.Text[ed]it', input: SYM);
    score(p: 'edt', str: 'foo.Textedit', input: SYM);
    score(p: 'edit', str: 'foo.Textedit', want: 'foo.Text[edit]', input: SYM);
    score(
        p: 'pub', str: 'public setPubl', want: 'public set[Pub]l', input: SYM);
    score(
        p: 'mod',
        str: 'public List<AbstractModule> getMods',
        want: 'public List<AbstractModule> get[Mod]s',
        input: SYM);
    score(
        p: 'm',
        str: 'public List<AbstractModule> getMods',
        want: 'public List<AbstractModule> get[M]ods',
        input: SYM);
    score(p: 'f', str: '[]foo.Foo', want: '[]foo.[F]oo', input: SYM);
    score(
        p: 'edin',
        str: 'foo.TexteditNum',
        want: 'foo.Text[edi]t[N]um',
        input: SYM);
  }
}

@reflectiveTest
class ScoringFunctionTest {
  ///
  void score({@required String p, @required String str, double want}) {
//    test('scores $str against $p', () {
    var matcher = FuzzyMatcher(p, matchStyle: MatchStyle.SYMBOL);
    expect(
        matcher
            .score(str)
            .toStringAsFixed(4)
            .startsWith(want.toStringAsFixed(4)),
        true);
//    });
  }

  void test_score() {
    // This is a regression test. Feel free to update numbers below if the new
    // ones are reasonable. Use 5 digits after the period.
    score(p: 'abc', str: 'abc', want: 1); // perfect
    score(p: 'abc', str: 'Abc', want: 1); // almost perfect
    score(p: 'abc', str: 'Abcdef', want: 1);
    score(p: 'strc', str: 'StrCat', want: 1);
    score(p: 'abc_def', str: 'abc_def_xyz', want: 1);
    score(p: 'abcdef', str: 'abc_def_xyz', want: 0.91667);
    score(p: 'abcxyz', str: 'abc_def_xyz', want: 0.875);
    score(p: 'sc', str: 'StrCat', want: 0.75);
    score(p: 'abc', str: 'AbstrBasicCtor', want: 0.75);
    // Qualified symbols.
    score(p: 'foo', str: 'abc::foo', want: 1);
    score(p: 'afoo', str: 'abc::foo', want: 0.9375);
    score(p: 'abr', str: 'abc::bar', want: 0.5);
    score(p: 'br', str: 'abc::bar', want: 0.375);
    score(p: 'aar', str: 'abc::bar', want: 0.16667);
    score(p: 'edin', str: 'foo.TexteditNum', want: 0.0625); // poor match
    score(p: 'ediu', str: 'foo.TexteditNum', want: 0); // poor match
    // We want the next two items to have roughly similar scores.
    score(p: 'up', str: 'unique_ptr', want: 0.75);
    score(p: 'up', str: 'upper_bound', want: 1);
  }
}
