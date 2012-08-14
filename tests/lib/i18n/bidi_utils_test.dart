// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


#library('bidi_utils_test');

#import('../../../pkg/i18n/intl.dart');
#import('../../../pkg/unittest/unittest.dart');

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
    expect(isRtlLanguage('en'), isFalse);
    expect(isRtlLanguage('fr'), isFalse);
    expect(isRtlLanguage('zh-CN'), isFalse);
    expect(isRtlLanguage('fil'), isFalse);
    expect(isRtlLanguage('az'), isFalse);
    expect(isRtlLanguage('iw-Latn'), isFalse);
    expect(isRtlLanguage('iw-LATN'), isFalse);
    expect(isRtlLanguage('iw_latn'), isFalse);
    expect(isRtlLanguage('ar'), isTrue);
    expect(isRtlLanguage('AR'), isTrue);
    expect(isRtlLanguage('iw'), isTrue);
    expect(isRtlLanguage('he'), isTrue);
    expect(isRtlLanguage('fa'), isTrue);
    expect(isRtlLanguage('ar-EG'), isTrue);
    expect(isRtlLanguage('az-Arab'), isTrue);
    expect(isRtlLanguage('az-ARAB-IR'), isTrue);
    expect(isRtlLanguage('az_arab_IR'), isTrue);
  });

  test('hasAnyLtr', () {
    expect(hasAnyLtr(''), isFalse);
    expect(hasAnyLtr('\u05e0\u05e1\u05e2'), isFalse);
    expect(hasAnyLtr('\u05e0\u05e1z\u05e2'), isTrue);
    expect(hasAnyLtr('123\t...  \n'), isFalse);
    expect(hasAnyLtr('<br>123&lt;', false), isTrue);
    expect(hasAnyLtr('<br>123&lt;', true), isFalse);
  });

  test('hasAnyRtl', () {
    expect(hasAnyRtl(''), isFalse);
    expect(hasAnyRtl('abc'), isFalse);
    expect(hasAnyRtl('ab\u05e0c'), isTrue);
    expect(hasAnyRtl('123\t...  \n'), isFalse);
    expect(hasAnyRtl('<input value=\u05e0>123', false), isTrue);
    expect(hasAnyRtl('<input value=\u05e0>123', true), isFalse);
  });

  
  test('endsWithLtr', () {
    expect(endsWithLtr('a'), isTrue);
    expect(endsWithLtr('abc'), isTrue);
    expect(endsWithLtr('a (!)'), isTrue);
    expect(endsWithLtr('a.1'), isTrue);
    expect(endsWithLtr('http://www.google.com '), isTrue);
    expect(endsWithLtr('\u05e0a'), isTrue);
    expect(endsWithLtr(' \u05e0\u05e1a\u05e2\u05e3 a (!)'), isTrue);
    expect(endsWithLtr(''), isFalse);
    expect(endsWithLtr(' '), isFalse);
    expect(endsWithLtr('1'), isFalse);
    expect(endsWithLtr('\u05e0'), isFalse);
    expect(endsWithLtr('\u05e0 1(!)'), isFalse);
    expect(endsWithLtr('a\u05e0'), isFalse);
    expect(endsWithLtr('a abc\u05e0\u05e1def\u05e2. 1'), isFalse);
    expect(endsWithLtr(' \u05e0\u05e1a\u05e2 &lt;', true), isFalse);
    expect(endsWithLtr(' \u05e0\u05e1a\u05e2 &lt;', false), isTrue);
  });

  test('endsWithRtl', () {
    expect(endsWithRtl('\u05e0'), isTrue);
    expect(endsWithRtl('\u05e0\u05e1\u05e2'), isTrue);
    expect(endsWithRtl('\u05e0 (!)'), isTrue);
    expect(endsWithRtl('\u05e0.1'), isTrue);
    expect(endsWithRtl('http://www.google.com/\u05e0 '), isTrue);
    expect(endsWithRtl('a\u05e0'), isTrue);
    expect(endsWithRtl(' a abc\u05e0def\u05e3. 1'), isTrue);
    expect(endsWithRtl(''), isFalse);
    expect(endsWithRtl(' '), isFalse);
    expect(endsWithRtl('1'), isFalse);
    expect(endsWithRtl('a'), isFalse);
    expect(endsWithRtl('a 1(!)'), isFalse);
    expect(endsWithRtl('\u05e0a'), isFalse);
    expect(endsWithRtl('\u05e0 \u05e0\u05e1ab\u05e2 a (!)'), isFalse);
    expect(endsWithRtl(' \u05e0\u05e1a\u05e2 &lt;', true), isTrue);
    expect(endsWithRtl(' \u05e0\u05e1a\u05e2 &lt;', false), isFalse);
  });

  test('guardBracketInHtml', () {
    var strWithRtl = "asc \u05d0 (\u05d0\u05d0\u05d0)";
    expect(guardBracketInHtml(strWithRtl),
        equals("asc \u05d0 <span dir=rtl>(\u05d0\u05d0\u05d0)</span>"));
    expect(guardBracketInHtml(strWithRtl, true),
        equals("asc \u05d0 <span dir=rtl>(\u05d0\u05d0\u05d0)</span>"));
    expect(guardBracketInHtml(strWithRtl, false),
        equals("asc \u05d0 <span dir=ltr>(\u05d0\u05d0\u05d0)</span>"));

    var strWithRtl2 = "\u05d0 a (asc:))";
    expect(guardBracketInHtml(strWithRtl2),
        equals("\u05d0 a <span dir=rtl>(asc:))</span>"));
    expect(guardBracketInHtml(strWithRtl2, true),
        equals("\u05d0 a <span dir=rtl>(asc:))</span>"));
    expect(guardBracketInHtml(strWithRtl2, false),
        equals("\u05d0 a <span dir=ltr>(asc:))</span>"));

    var strWithoutRtl = "a (asc) {{123}}";
    expect(guardBracketInHtml(strWithoutRtl),
        equals("a <span dir=ltr>(asc)</span> <span dir=ltr>{{123}}</span>"));
    expect(guardBracketInHtml(strWithoutRtl, true),
        equals("a <span dir=rtl>(asc)</span> <span dir=rtl>{{123}}</span>"));
    expect(guardBracketInHtml(strWithoutRtl, false),
        equals("a <span dir=ltr>(asc)</span> <span dir=ltr>{{123}}</span>"));

  });

  test('guardBracketInText', () {
    var strWithRtl = "asc \u05d0 (\u05d0\u05d0\u05d0)";
    expect(guardBracketInText(strWithRtl),
        equals("asc \u05d0 \u200f(\u05d0\u05d0\u05d0)\u200f"));
    expect(guardBracketInText(strWithRtl, true),
        equals("asc \u05d0 \u200f(\u05d0\u05d0\u05d0)\u200f"));
    expect(guardBracketInText(strWithRtl, false),
        equals("asc \u05d0 \u200e(\u05d0\u05d0\u05d0)\u200e"));

    var strWithRtl2 = "\u05d0 a (asc:))";
    expect(guardBracketInText(strWithRtl2),
        equals("\u05d0 a \u200f(asc:))\u200f"));
    expect(guardBracketInText(strWithRtl2, true),
        equals("\u05d0 a \u200f(asc:))\u200f"));
    expect(guardBracketInText(strWithRtl2, false),
        equals("\u05d0 a \u200e(asc:))\u200e"));

    var strWithoutRtl = "a (asc) {{123}}";
    expect(guardBracketInText(strWithoutRtl),
        equals("a \u200e(asc)\u200e \u200e{{123}}\u200e"));
    expect(guardBracketInText(strWithoutRtl, true),
        equals("a \u200f(asc)\u200f \u200f{{123}}\u200f"));
    expect(guardBracketInText(strWithoutRtl, false),
        equals("a \u200e(asc)\u200e \u200e{{123}}\u200e"));

  });

  test('enforceRtlInHtml', () {
    var str = '<div> first <br> second </div>';
    expect(enforceRtlInHtml(str),
        equals('<div dir=rtl> first <br> second </div>'));
    str = 'first second';
    expect(enforceRtlInHtml(str),
        equals('\n<span dir=rtl>first second</span>'));
  });

  test('enforceRtlInText', () {
    var str = 'first second';
    expect(enforceRtlInText(str), equals('${RLE}first second$PDF'));
  });

  test('enforceLtrInHtml', () {
    var str = '<div> first <br> second </div>';
    expect(enforceLtrInHtml(str),
        equals('<div dir=ltr> first <br> second </div>'));
    str = 'first second';
    expect(enforceLtrInHtml(str),
        equals('\n<span dir=ltr>first second</span>'));
  });

  test('enforceLtrInText', () {
    var str = 'first second';
    expect(enforceLtrInText(str), equals('${LRE}first second$PDF'));
  });

  test('normalizeHebrewQuote', () {
    expect(normalizeHebrewQuote('\u05d0"'), equals('\u05d0\u05f4'));
    expect(normalizeHebrewQuote('\u05d0\''), equals('\u05d0\u05f3'));
    expect(normalizeHebrewQuote('\u05d0"\u05d0\''),
        equals('\u05d0\u05f4\u05d0\u05f3'));
  });

  test('estimateDirectionOfText', () {
    expect(estimateDirectionOfText('', false).value, 
        equals(TextDirection.UNKNOWN.value));
    expect(estimateDirectionOfText(' ', false).value,
        equals(TextDirection.UNKNOWN.value));
    expect(estimateDirectionOfText('! (...)', false).value,
        equals(TextDirection.UNKNOWN.value));
    expect(estimateDirectionOfText('All-Ascii content', false).value,
        equals(TextDirection.LTR.value));
    expect(estimateDirectionOfText('-17.0%', false).value,
        equals(TextDirection.LTR.value));
    expect(estimateDirectionOfText('http://foo/bar/', false).value,
        equals(TextDirection.LTR.value));
    expect(estimateDirectionOfText(
        'http://foo/bar/?s=\u05d0\u05d0\u05d0\u05d0\u05d0\u05d0\u05d0\u05d0'
        '\u05d0\u05d0\u05d0\u05d0\u05d0\u05d0\u05d0\u05d0\u05d0\u05d0\u05d0'
        '\u05d0\u05d0\u05d0\u05d0\u05d0').value,
        equals(TextDirection.LTR.value));
    expect(estimateDirectionOfText('\u05d0', false).value,
        equals(TextDirection.RTL.value));
    expect(estimateDirectionOfText(
        '9 \u05d0 -> 17.5, 23, 45, 19', false).value,
        equals(TextDirection.RTL.value));
    expect(estimateDirectionOfText(
        'http://foo/bar/ \u05d0 http://foo2/bar2/ http://foo3/bar3/').value,
        equals(TextDirection.RTL.value));
    expect(estimateDirectionOfText(
        '\u05d0\u05d9\u05df \u05de\u05de\u05e9 \u05de\u05d4 \u05dc\u05e8\u05d0'
        '\u05d5\u05ea: \u05dc\u05d0 \u05e6\u05d9\u05dc\u05de\u05ea\u05d9 \u05d4'
        '\u05e8\u05d1\u05d4 \u05d5\u05d2\u05dd \u05d0\u05dd \u05d4\u05d9\u05d9'
        '\u05ea\u05d9 \u05de\u05e6\u05dc\u05dd, \u05d4\u05d9\u05d4 \u05e9'
        '\u05dd').value,
        equals(TextDirection.RTL.value));
    expect(estimateDirectionOfText(
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
    expect(estimateDirectionOfText(
        'CAPTCHA \u05de\u05e9\u05d5\u05db\u05dc\u05dc '
        '\u05de\u05d3\u05d9?').value,
        equals(TextDirection.RTL.value));
    expect(estimateDirectionOfText(
        'Yes Prime Minister \u05e2\u05d3\u05db\u05d5\u05df. \u05e9\u05d0\u05dc'
        '\u05d5 \u05d0\u05d5\u05ea\u05d9 \u05de\u05d4 \u05d0\u05e0\u05d9 '
        '\u05e8\u05d5\u05e6\u05d4 \u05de\u05ea\u05e0\u05d4 \u05dc\u05d7'
        '\u05d2').value,
        equals(TextDirection.RTL.value));
    expect(estimateDirectionOfText(
        '17.4.02 \u05e9\u05e2\u05d4:13-20 .15-00 .\u05dc\u05d0 \u05d4\u05d9'
        '\u05d9\u05ea\u05d9 \u05db\u05d0\u05df.').value,
        equals(TextDirection.RTL.value));
    expect(estimateDirectionOfText(
        '5710 5720 5730. \u05d4\u05d3\u05dc\u05ea. \u05d4\u05e0\u05e9\u05d9'
        '\u05e7\u05d4', false).value,
        equals(TextDirection.RTL.value));
    expect(estimateDirectionOfText(
        '\u05d4\u05d3\u05dc\u05ea http://www.google.com '
        'http://www.gmail.com').value,
        equals(TextDirection.RTL.value));
    expect(estimateDirectionOfText(
        '\u05d4\u05d3\u05dc <some quite nasty html mark up>').value,
        equals(TextDirection.LTR.value));
    expect(estimateDirectionOfText(
        '\u05d4\u05d3\u05dc <some quite nasty html mark up>').value,
        equals(TextDirection.LTR.value));
    expect(estimateDirectionOfText(
        '\u05d4\u05d3\u05dc\u05ea &amp; &lt; &gt;').value,
        equals(TextDirection.LTR.value));
    expect(estimateDirectionOfText(
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
        var isRtlDir = detectRtlDirectionality(bidiText[i].text,
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
