// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


#library('bidi_utils_test');

#import('../../../lib/i18n/bidi_utils.dart');
#import('../../../lib/unittest/unittest.dart');

/**
 * Tests the bidi utilities library.
 */
main() {
  var LRE = '\u202A';
  var RLE = '\u202B';
  var PDF = '\u202C';
  var LRM = '\u200E';
  var RLM = '\u200F';

  test('isRtlLang', () {
    expect(BidiUtils.isRtlLanguage('en'), isFalse);
    expect(BidiUtils.isRtlLanguage('fr'), isFalse);
    expect(BidiUtils.isRtlLanguage('zh-CN'), isFalse);
    expect(BidiUtils.isRtlLanguage('fil'), isFalse);
    expect(BidiUtils.isRtlLanguage('az'), isFalse);
    expect(BidiUtils.isRtlLanguage('iw-Latn'), isFalse);
    expect(BidiUtils.isRtlLanguage('iw-LATN'), isFalse);
    expect(BidiUtils.isRtlLanguage('iw_latn'), isFalse);
    expect(BidiUtils.isRtlLanguage('ar'), isTrue);
    expect(BidiUtils.isRtlLanguage('AR'), isTrue);
    expect(BidiUtils.isRtlLanguage('iw'), isTrue);
    expect(BidiUtils.isRtlLanguage('he'), isTrue);
    expect(BidiUtils.isRtlLanguage('fa'), isTrue);
    expect(BidiUtils.isRtlLanguage('ar-EG'), isTrue);
    expect(BidiUtils.isRtlLanguage('az-Arab'), isTrue);
    expect(BidiUtils.isRtlLanguage('az-ARAB-IR'), isTrue);
    expect(BidiUtils.isRtlLanguage('az_arab_IR'), isTrue);
  });

  test('hasAnyLtr', () {
    expect(BidiUtils.hasAnyLtr(''), isFalse);
    expect(BidiUtils.hasAnyLtr('\u05e0\u05e1\u05e2'), isFalse);
    expect(BidiUtils.hasAnyLtr('\u05e0\u05e1z\u05e2'), isTrue);
    expect(BidiUtils.hasAnyLtr('123\t...  \n'), isFalse);
    expect(BidiUtils.hasAnyLtr('<br>123&lt;', false), isTrue);
    expect(BidiUtils.hasAnyLtr('<br>123&lt;', true), isFalse);
  });

  test('hasAnyRtl', () {
    expect(BidiUtils.hasAnyRtl(''), isFalse);
    expect(BidiUtils.hasAnyRtl('abc'), isFalse);
    expect(BidiUtils.hasAnyRtl('ab\u05e0c'), isTrue);
    expect(BidiUtils.hasAnyRtl('123\t...  \n'), isFalse);
    expect(BidiUtils.hasAnyRtl('<input value=\u05e0>123', false), isTrue);
    expect(BidiUtils.hasAnyRtl('<input value=\u05e0>123', true), isFalse);
  });

  
  test('endsWithLtr', () {
    expect(BidiUtils.endsWithLtr('a'), isTrue);
    expect(BidiUtils.endsWithLtr('abc'), isTrue);
    expect(BidiUtils.endsWithLtr('a (!)'), isTrue);
    expect(BidiUtils.endsWithLtr('a.1'), isTrue);
    expect(BidiUtils.endsWithLtr('http://www.google.com '), isTrue);
    expect(BidiUtils.endsWithLtr('\u05e0a'), isTrue);
    expect(BidiUtils.endsWithLtr(' \u05e0\u05e1a\u05e2\u05e3 a (!)'), isTrue);
    expect(BidiUtils.endsWithLtr(''), isFalse);
    expect(BidiUtils.endsWithLtr(' '), isFalse);
    expect(BidiUtils.endsWithLtr('1'), isFalse);
    expect(BidiUtils.endsWithLtr('\u05e0'), isFalse);
    expect(BidiUtils.endsWithLtr('\u05e0 1(!)'), isFalse);
    expect(BidiUtils.endsWithLtr('a\u05e0'), isFalse);
    expect(BidiUtils.endsWithLtr('a abc\u05e0\u05e1def\u05e2. 1'), isFalse);
    expect(BidiUtils.endsWithLtr(' \u05e0\u05e1a\u05e2 &lt;', true), isFalse);
    expect(BidiUtils.endsWithLtr(' \u05e0\u05e1a\u05e2 &lt;', false), isTrue);
  });

  test('endsWithRtl', () {
    expect(BidiUtils.endsWithRtl('\u05e0'), isTrue);
    expect(BidiUtils.endsWithRtl('\u05e0\u05e1\u05e2'), isTrue);
    expect(BidiUtils.endsWithRtl('\u05e0 (!)'), isTrue);
    expect(BidiUtils.endsWithRtl('\u05e0.1'), isTrue);
    expect(BidiUtils.endsWithRtl('http://www.google.com/\u05e0 '), isTrue);
    expect(BidiUtils.endsWithRtl('a\u05e0'), isTrue);
    expect(BidiUtils.endsWithRtl(' a abc\u05e0def\u05e3. 1'), isTrue);
    expect(BidiUtils.endsWithRtl(''), isFalse);
    expect(BidiUtils.endsWithRtl(' '), isFalse);
    expect(BidiUtils.endsWithRtl('1'), isFalse);
    expect(BidiUtils.endsWithRtl('a'), isFalse);
    expect(BidiUtils.endsWithRtl('a 1(!)'), isFalse);
    expect(BidiUtils.endsWithRtl('\u05e0a'), isFalse);
    expect(BidiUtils.endsWithRtl('\u05e0 \u05e0\u05e1ab\u05e2 a (!)'), isFalse);
    expect(BidiUtils.endsWithRtl(' \u05e0\u05e1a\u05e2 &lt;', true), isTrue);
    expect(BidiUtils.endsWithRtl(' \u05e0\u05e1a\u05e2 &lt;', false), isFalse);
  });

  test('guardBracketInHtml', () {
    var strWithRtl = "asc \u05d0 (\u05d0\u05d0\u05d0)";
    expect(BidiUtils.guardBracketInHtml(strWithRtl),
        equals("asc \u05d0 <span dir=rtl>(\u05d0\u05d0\u05d0)</span>"));
    expect(BidiUtils.guardBracketInHtml(strWithRtl, true),
        equals("asc \u05d0 <span dir=rtl>(\u05d0\u05d0\u05d0)</span>"));
    expect(BidiUtils.guardBracketInHtml(strWithRtl, false),
        equals("asc \u05d0 <span dir=ltr>(\u05d0\u05d0\u05d0)</span>"));

    var strWithRtl2 = "\u05d0 a (asc:))";
    expect(BidiUtils.guardBracketInHtml(strWithRtl2),
        equals("\u05d0 a <span dir=rtl>(asc:))</span>"));
    expect(BidiUtils.guardBracketInHtml(strWithRtl2, true),
        equals("\u05d0 a <span dir=rtl>(asc:))</span>"));
    expect(BidiUtils.guardBracketInHtml(strWithRtl2, false),
        equals("\u05d0 a <span dir=ltr>(asc:))</span>"));

    var strWithoutRtl = "a (asc) {{123}}";
    expect(BidiUtils.guardBracketInHtml(strWithoutRtl),
        equals("a <span dir=ltr>(asc)</span> <span dir=ltr>{{123}}</span>"));
    expect(BidiUtils.guardBracketInHtml(strWithoutRtl, true),
        equals("a <span dir=rtl>(asc)</span> <span dir=rtl>{{123}}</span>"));
    expect(BidiUtils.guardBracketInHtml(strWithoutRtl, false),
        equals("a <span dir=ltr>(asc)</span> <span dir=ltr>{{123}}</span>"));

  });

  test('guardBracketInText', () {
    var strWithRtl = "asc \u05d0 (\u05d0\u05d0\u05d0)";
    expect(BidiUtils.guardBracketInText(strWithRtl),
        equals("asc \u05d0 \u200f(\u05d0\u05d0\u05d0)\u200f"));
    expect(BidiUtils.guardBracketInText(strWithRtl, true),
        equals("asc \u05d0 \u200f(\u05d0\u05d0\u05d0)\u200f"));
    expect(BidiUtils.guardBracketInText(strWithRtl, false),
        equals("asc \u05d0 \u200e(\u05d0\u05d0\u05d0)\u200e"));

    var strWithRtl2 = "\u05d0 a (asc:))";
    expect(BidiUtils.guardBracketInText(strWithRtl2),
        equals("\u05d0 a \u200f(asc:))\u200f"));
    expect(BidiUtils.guardBracketInText(strWithRtl2, true),
        equals("\u05d0 a \u200f(asc:))\u200f"));
    expect(BidiUtils.guardBracketInText(strWithRtl2, false),
        equals("\u05d0 a \u200e(asc:))\u200e"));

    var strWithoutRtl = "a (asc) {{123}}";
    expect(BidiUtils.guardBracketInText(strWithoutRtl),
        equals("a \u200e(asc)\u200e \u200e{{123}}\u200e"));
    expect(BidiUtils.guardBracketInText(strWithoutRtl, true),
        equals("a \u200f(asc)\u200f \u200f{{123}}\u200f"));
    expect(BidiUtils.guardBracketInText(strWithoutRtl, false),
        equals("a \u200e(asc)\u200e \u200e{{123}}\u200e"));

  });

  test('enforceRtlInHtml', () {
    var str = '<div> first <br> second </div>';
    expect(BidiUtils.enforceRtlInHtml(str),
        equals('<div dir=rtl> first <br> second </div>'));
    str = 'first second';
    expect(BidiUtils.enforceRtlInHtml(str),
        equals('\n<span dir=rtl>first second</span>'));
  });

  test('enforceRtlInText', () {
    var str = 'first second';
    expect(BidiUtils.enforceRtlInText(str), equals('${RLE}first second$PDF'));
  });

  test('enforceLtrInHtml', () {
    var str = '<div> first <br> second </div>';
    expect(BidiUtils.enforceLtrInHtml(str),
        equals('<div dir=ltr> first <br> second </div>'));
    str = 'first second';
    expect(BidiUtils.enforceLtrInHtml(str),
        equals('\n<span dir=ltr>first second</span>'));
  });

  test('enforceLtrInText', () {
    var str = 'first second';
    expect(BidiUtils.enforceLtrInText(str), equals('${LRE}first second$PDF'));
  });

  test('normalizeHebrewQuote', () {
    expect(BidiUtils.normalizeHebrewQuote('\u05d0"'), equals('\u05d0\u05f4'));
    expect(BidiUtils.normalizeHebrewQuote('\u05d0\''), equals('\u05d0\u05f3'));
    expect(BidiUtils.normalizeHebrewQuote('\u05d0"\u05d0\''),
        equals('\u05d0\u05f4\u05d0\u05f3'));
  });

  test('estimateDirection', () {
    expect(BidiUtils.estimateDirection('', false).value, 
        equals(TextDirection.UNKNOWN.value));
    expect(BidiUtils.estimateDirection(' ', false).value,
        equals(TextDirection.UNKNOWN.value));
    expect(BidiUtils.estimateDirection('! (...)', false).value,
        equals(TextDirection.UNKNOWN.value));
    expect(BidiUtils.estimateDirection('All-Ascii content', false).value,
        equals(TextDirection.LTR.value));
    expect(BidiUtils.estimateDirection('-17.0%', false).value,
        equals(TextDirection.LTR.value));
    expect(BidiUtils.estimateDirection('http://foo/bar/', false).value,
        equals(TextDirection.LTR.value));
    expect(BidiUtils.estimateDirection(
        'http://foo/bar/?s=\u05d0\u05d0\u05d0\u05d0\u05d0\u05d0\u05d0\u05d0'
        '\u05d0\u05d0\u05d0\u05d0\u05d0\u05d0\u05d0\u05d0\u05d0\u05d0\u05d0'
        '\u05d0\u05d0\u05d0\u05d0\u05d0').value,
        equals(TextDirection.LTR.value));
    expect(BidiUtils.estimateDirection('\u05d0', false).value,
        equals(TextDirection.RTL.value));
    expect(BidiUtils.estimateDirection(
        '9 \u05d0 -> 17.5, 23, 45, 19', false).value,
        equals(TextDirection.RTL.value));
    expect(BidiUtils.estimateDirection(
        'http://foo/bar/ \u05d0 http://foo2/bar2/ http://foo3/bar3/').value,
        equals(TextDirection.RTL.value));
    expect(BidiUtils.estimateDirection(
        '\u05d0\u05d9\u05df \u05de\u05de\u05e9 \u05de\u05d4 \u05dc\u05e8\u05d0'
        '\u05d5\u05ea: \u05dc\u05d0 \u05e6\u05d9\u05dc\u05de\u05ea\u05d9 \u05d4'
        '\u05e8\u05d1\u05d4 \u05d5\u05d2\u05dd \u05d0\u05dd \u05d4\u05d9\u05d9'
        '\u05ea\u05d9 \u05de\u05e6\u05dc\u05dd, \u05d4\u05d9\u05d4 \u05e9'
        '\u05dd').value,
        equals(TextDirection.RTL.value));
    expect(BidiUtils.estimateDirection(
        '\u05db\u05d0 - http://geek.co.il/gallery/v/2007-06 - \u05d0\u05d9'
        '\u05df \u05de\u05de\u05e9 \u05de\u05d4 \u05dc\u05e8\u05d0\u05d5\u05ea:'
        ' \u05dc\u05d0 \u05e6\u05d9\u05dc\u05de\u05ea\u05d9 \u05d4\u05e8\u05d1 '
        '\u05d5\u05d2\u05dd \u05d0\u05dd \u05d4\u05d9\u05d9\u05d9 \u05de\u05e6'
        '\u05dc\u05dd, \u05d4\u05d9\u05d4 \u05e9\u05dd \u05d1\u05e2\u05d9\u05e7'
        ' \u05d4\u05e8\u05d1\u05d4 \u05d0\u05e0\u05e9\u05d9\u05dd. \u05de\u05d4'
        ' \u05e9\u05db\u05df - \u05d0\u05e4\u05e9\u05e8 \u05dc\u05e0\u05e6'
        '\u05dc \u05d0\u05ea \u05d4\u05d4 \u05d3\u05d6\u05de\u05e0\u05d5 '
        '\u05dc\u05d4\u05e1\u05ea\u05db\u05dc \u05e2\u05dc \u05db\u05de\u05d4 '
        '\u05ea\u05de\u05d5\u05e0\u05d5\u05ea \u05de\u05e9\u05e9\u05e2\u05d5'
        '\u05ea \u05d9\u05e9\u05e0\u05d5 \u05d9\u05d5\u05ea\u05e8 \u05e9\u05d9'
        '\u05e9 \u05dc\u05d9 \u05d1\u05d0\u05ea\u05e8', false).value,
        equals(TextDirection.RTL.value));
    expect(BidiUtils.estimateDirection(
        'CAPTCHA \u05de\u05e9\u05d5\u05db\u05dc\u05dc '
        '\u05de\u05d3\u05d9?').value,
        equals(TextDirection.RTL.value));
    expect(BidiUtils.estimateDirection(
        'Yes Prime Minister \u05e2\u05d3\u05db\u05d5\u05df. \u05e9\u05d0\u05dc'
        '\u05d5 \u05d0\u05d5\u05ea\u05d9 \u05de\u05d4 \u05d0\u05e0\u05d9 '
        '\u05e8\u05d5\u05e6\u05d4 \u05de\u05ea\u05e0\u05d4 \u05dc\u05d7'
        '\u05d2').value,
        equals(TextDirection.RTL.value));
    expect(BidiUtils.estimateDirection(
        '17.4.02 \u05e9\u05e2\u05d4:13-20 .15-00 .\u05dc\u05d0 \u05d4\u05d9'
        '\u05d9\u05ea\u05d9 \u05db\u05d0\u05df.').value,
        equals(TextDirection.RTL.value));
    expect(BidiUtils.estimateDirection(
        '5710 5720 5730. \u05d4\u05d3\u05dc\u05ea. \u05d4\u05e0\u05e9\u05d9'
        '\u05e7\u05d4', false).value,
        equals(TextDirection.RTL.value));
    expect(BidiUtils.estimateDirection(
        '\u05d4\u05d3\u05dc\u05ea http://www.google.com '
        'http://www.gmail.com').value,
        equals(TextDirection.RTL.value));
    expect(BidiUtils.estimateDirection(
        '\u05d4\u05d3\u05dc <some quite nasty html mark up>').value,
        equals(TextDirection.LTR.value));
    expect(BidiUtils.estimateDirection(
        '\u05d4\u05d3\u05dc <some quite nasty html mark up>').value,
        equals(TextDirection.LTR.value));
    expect(BidiUtils.estimateDirection(
        '\u05d4\u05d3\u05dc\u05ea &amp; &lt; &gt;').value,
        equals(TextDirection.LTR.value));
    expect(BidiUtils.estimateDirection(
        '\u05d4\u05d3\u05dc\u05ea &amp; &lt; &gt;', true).value,
        equals(TextDirection.RTL.value));
  });

  test('detectRtlDirectionality', () {
    var bidiText = [];
    var item = new SampleItem('Pure Ascii content');
    bidiText.add(item);

    item = new SampleItem('\u05d0\u05d9\u05df \u05de\u05de\u05e9 \u05de\u05d4'
        ' \u05dc\u05e8\u05d0\u05d5\u05ea: \u05dc\u05d0 \u05e6\u05d9\u05dc'
        '\u05de\u05ea\u05d9 \u05d4\u05e8\u05d1\u05d4 \u05d5\u05d2\u05dd '
        '\u05d0\u05dd \u05d4\u05d9\u05d9\u05ea\u05d9 \u05de\u05e6\u05dc\u05dd, '
        '\u05d4\u05d9\u05d4 \u05e9\u05dd', true);
    bidiText.add(item);

    item = new SampleItem('\u05db\u05d0\u05df - http://geek.co.il/gallery/v/'
        '2007-06 - \u05d0\u05d9\u05df \u05de\u05de\u05e9 \u05de\u05d4 \u05dc'
        '\u05e8\u05d0\u05d5\u05ea: \u05dc\u05d0 \u05e6\u05d9\u05dc\u05de\u05ea'
        '\u05d9 \u05d4\u05e8\u05d1\u05d4 \u05d5\u05d2\u05dd \u05d0\u05dd \u05d4'
        '\u05d9\u05d9\u05ea\u05d9 \u05de\u05e6\u05dc\u05dd, \u05d4\u05d9\u05d4 '
        '\u05e9\u05dd \u05d1\u05e2\u05d9\u05e7\u05e8 \u05d4\u05e8\u05d1\u05d4 '
        '\u05d0\u05e0\u05e9\u05d9\u05dd. \u05de\u05d4 \u05e9\u05db\u05df - '
        '\u05d0\u05e4\u05e9\u05e8 \u05dc\u05e0\u05e6\u05dc \u05d0\u05ea \u05d4'
        '\u05d4\u05d3\u05d6\u05de\u05e0\u05d5\u05ea \u05dc\u05d4\u05e1\u05ea'
        '\u05db\u05dc \u05e2\u05dc \u05db\u05de\u05d4 \u05ea\u05de\u05d5\u05e0'
        '\u05d5\u05ea \u05de\u05e9\u05e2\u05e9\u05e2\u05d5\u05ea \u05d9\u05e9'
        '\u05e0\u05d5\u05ea \u05d9\u05d5\u05ea\u05e8 \u05e9\u05d9\u05e9 \u05dc'
        '\u05d9 \u05d1\u05d0\u05ea\u05e8', true);
    bidiText.add(item);

    item = new SampleItem('CAPTCHA \u05de\u05e9\u05d5\u05db\u05dc\u05dc '
        '\u05de\u05d3\u05d9?', true);
    bidiText.add(item);


    item = new SampleItem('Yes Prime Minister \u05e2\u05d3\u05db\u05d5\u05df. '
        '\u05e9\u05d0\u05dc\u05d5 \u05d0\u05d5\u05ea\u05d9 \u05de\u05d4 \u05d0'
        '\u05e0\u05d9 \u05e8\u05d5\u05e6\u05d4 \u05de\u05ea\u05e0\u05d4 '
        '\u05dc\u05d7\u05d2', true);
    bidiText.add(item);

    item = new SampleItem('17.4.02 \u05e9\u05e2\u05d4:13-20 .15-00 .\u05dc'
        '\u05d0 \u05d4\u05d9\u05d9\u05ea\u05d9 \u05db\u05d0\u05df.', true);
    bidiText.add(item);

    item = new SampleItem('5710 5720 5730. \u05d4\u05d3\u05dc\u05ea. \u05d4'
        '\u05e0\u05e9\u05d9\u05e7\u05d4', true);
    bidiText.add(item);

    item = new SampleItem('\u05d4\u05d3\u05dc\u05ea http://www.google.com '
        'http://www.gmail.com', true);
    bidiText.add(item);

    item = new SampleItem('&gt;\u05d4&lt;', true, true);
    bidiText.add(item);

    item = new SampleItem('&gt;\u05d4&lt;', false);
    bidiText.add(item);

    for (var i = 0; i < bidiText.length; i++) {
        var isRtlDir = BidiUtils.detectRtlDirectionality(bidiText[i].text,
                                                            bidiText[i].isHtml);
      if (isRtlDir != bidiText[i].isRtl) {
        var str = '"${bidiText[i].text} " should be '
                  '${bidiText[i].isRtl ? "rtl" : "ltr"} but detected as '
                  '${isRtlDir ? "rtl" : "ltr"}';
        //alert(str);
      }
      expect(bidiText[i].isRtl, isRtlDir);
    }
  });
}

class SampleItem {
  String text;
  bool isRtl;
  bool isHtml;
  SampleItem([someText='', someIsRtl=false, isHtml=false]) :
      this.text=someText, this.isRtl=someIsRtl, this.isHtml=isHtml;
}
