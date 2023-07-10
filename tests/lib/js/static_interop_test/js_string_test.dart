// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file for
// details. All jsStringImplArguments reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

// Check that JSStringImpl behaves correctly as a subtype of String.

import 'dart:js_interop';

import 'package:expect/expect.dart';

// We run many tests in three configurations:
// 1) Test should ensure receivers for all [String] operations will be
//    `JSStringImpl`.
// 2) Test should ensure arguments to all [String] operations
//    will be `JSStringImpl`.
// 3) Test should ensure both receivers and arguments
//    for all [String] operations will be `JSStringImpl`.
enum TestMode {
  jsStringImplReceiver,
  jsStringImplArgument,
  jsStringImplReceiverAndArguments,
}

enum Position {
  jsStringImplReceiver,
  jsStringImplArgument,
}

bool useJSStringImpl(Position pos, TestMode mode) =>
    (pos == Position.jsStringImplReceiver &&
        (mode == TestMode.jsStringImplReceiver ||
            mode == TestMode.jsStringImplReceiverAndArguments)) ||
    (pos == Position.jsStringImplArgument &&
        (mode == TestMode.jsStringImplArgument ||
            mode == TestMode.jsStringImplReceiverAndArguments));

// Round trip through `dart:js_interop` to get a `JSString` backed `String`.
String jsStringImpl(String s) => s.toJS.toDart;

String getStr(String s, Position pos, TestMode mode) =>
    useJSStringImpl(pos, mode) ? jsStringImpl(s) : s;

void testStringLength(int length, String str) {
  Expect.equals(length, str.length);
  (length == 0 ? Expect.isTrue : Expect.isFalse)(str.isEmpty);
  (length != 0 ? Expect.isTrue : Expect.isFalse)(str.isNotEmpty);
}

void testLength(TestMode mode) {
  String str = getStr('', Position.jsStringImplReceiver, mode);
  for (var i = 0; i < 5; i++) {
    testStringLength(i, str);
    str += getStr(' ', Position.jsStringImplArgument, mode);
  }
}

void testOutOfRange() {
  String a = jsStringImpl('Hello');
  bool exception_caught = false;
  try {
    var c = a[20]; // Throw exception.
  } on RangeError catch (e) {
    exception_caught = true;
  }
  Expect.isTrue(exception_caught);
}

void testIndex() {
  String str = jsStringImpl('string');
  List<String> chars = ['s', 't', 'r', 'i', 'n', 'g'];
  assert(str.length == chars.length);
  for (int i = 0; i < str.length; i++) {
    Expect.isTrue(str[i] is String);
    testStringLength(1, str[i]);
    Expect.equals(str[i], chars[i]);
  }
}

void testCodeUnitAt() {
  String str = jsStringImpl('string');
  List<int> codes = [115, 116, 114, 105, 110, 103];
  for (int i = 0; i < str.length; i++) {
    Expect.isTrue(str.codeUnitAt(i) is int);
    Expect.equals(str.codeUnitAt(i), codes[i]);
  }
}

void testConcat(TestMode mode) {
  var a = getStr('One', Position.jsStringImplReceiver, mode);
  var b = getStr('Four', Position.jsStringImplArgument, mode);
  var c = a + b;
  testStringLength(7, c);
  Expect.equals('OneFour', c);
}

void testEquals(TestMode mode) {
  String r(String s) => getStr(s, Position.jsStringImplReceiver, mode);
  String a(String s) => getStr(s, Position.jsStringImplArgument, mode);

  final rstr = r('str');
  final astr = a('str');
  Expect.equals(rstr, astr);

  Expect.equals(rstr, a('s') + 't' + 'r');
  Expect.equals(r('s') + 't' + 'r', a('str'));

  Expect.isFalse(rstr == a('s'));
  Expect.isFalse(r('s') == astr);

  Expect.isFalse(r('') == a('s'));
  Expect.equals(r(''), a(''));
}

void testEndsWith(TestMode mode) {
  String r(String s) => getStr(s, Position.jsStringImplReceiver, mode);
  String a(String s) => getStr(s, Position.jsStringImplArgument, mode);

  final rstr = r('str');
  Expect.isTrue(rstr.endsWith(a('str')));
  Expect.isFalse(rstr.endsWith(a('t')));

  final rEmptyStr = r('');
  Expect.isTrue(rEmptyStr.endsWith(r('')));
  Expect.isFalse(rEmptyStr.endsWith(r('s')));
}

void testStartsWith(TestMode mode) {
  String r(String s) => getStr(s, Position.jsStringImplReceiver, mode);
  String a(String s) => getStr(s, Position.jsStringImplArgument, mode);

  final rstr = r('str');
  Expect.isTrue(rstr.startsWith(a('str')));
  Expect.isFalse(rstr.startsWith(a('stri')));

  final rEmptyStr = r('');
  Expect.isTrue(rEmptyStr.startsWith(a('')));
  Expect.isFalse(rEmptyStr.startsWith(a('s')));

  final rstrstr = r('strstr');
  final as = a('s');
  Expect.isFalse(rstrstr.startsWith(as, 1));
  Expect.isTrue(rstrstr.startsWith(as, 3));

  final ast = a('st');
  Expect.isFalse(rstrstr.startsWith(ast, 1));
  Expect.isTrue(rstrstr.startsWith(ast, 3));

  final astr = a('str');
  Expect.isFalse(rstrstr.startsWith(astr, 1));
  Expect.isTrue(rstrstr.startsWith(astr, 3));

  final aEmptyStr = a('');
  Expect.isTrue(rstr.startsWith(aEmptyStr, 0));

  Expect.throws(() => rstr.startsWith(aEmptyStr, -1));
  Expect.throws(() => rstr.startsWith(aEmptyStr, 4));

  final regexp = new RegExp('s(?:tr?)?');
  Expect.isTrue(rstr.startsWith(regexp));
  Expect.isFalse(rstrstr.startsWith(regexp, 1));
  Expect.isFalse(rstrstr.startsWith(regexp, 2));
  Expect.isTrue(rstrstr.startsWith(regexp, 3));
  Expect.isFalse(rstrstr.startsWith(regexp, 4));
}

void testIndexOf(TestMode mode) {
  String r(String s) => getStr(s, Position.jsStringImplReceiver, mode);
  String a(String s) => getStr(s, Position.jsStringImplArgument, mode);

  final rstr = r('str');
  final rEmptyStr = r('');
  final aEmptyStr = a('');
  Expect.equals(0, rstr.indexOf(aEmptyStr, 0));
  Expect.equals(0, rEmptyStr.indexOf(aEmptyStr, 0));
  Expect.equals(-1, rEmptyStr.indexOf(a('a'), 0));

  Expect.equals(1, rstr.indexOf(a('t'), 0));
  Expect.equals(-1, rstr.indexOf(a('string'), 0));

  final rstrstr = r('strstr');
  final astr = a('str');
  Expect.equals(0, rstrstr.indexOf(astr, 0));
  Expect.equals(3, rstrstr.indexOf(astr, 1));
  Expect.equals(3, rstrstr.indexOf(astr, 2));
  Expect.equals(3, rstrstr.indexOf(astr, 3));

  for (int i = 0; i < 5; i++) {
    if (i > rstr.length) {
      Expect.throws(() => rstr.indexOf(aEmptyStr, i));
    } else {
      int result = rstr.indexOf(aEmptyStr, i);
      Expect.equals(i, result);
    }
  }

  final banana = a('banana');
  var re = RegExp('an?');
  Expect.equals(1, banana.indexOf(re));
  Expect.equals(1, banana.indexOf(re, 0));
  Expect.equals(1, banana.indexOf(re, 1));
  Expect.equals(3, banana.indexOf(re, 2));
  Expect.equals(3, banana.indexOf(re, 3));
  Expect.equals(5, banana.indexOf(re, 4));
  Expect.equals(5, banana.indexOf(re, 5));
  Expect.equals(-1, banana.indexOf(re, 6));
  Expect.throws(() => banana.indexOf(re, -1));
  Expect.throws(() => banana.indexOf(re, 7));
  re = RegExp('x?');
  for (int i = 0; i <= rstr.length; i++) {
    Expect.equals(i, rstr.indexOf(re, i));
  }
}

void testLastIndexOf(TestMode mode) {
  String r(String s) => getStr(s, Position.jsStringImplReceiver, mode);
  String a(String s) => getStr(s, Position.jsStringImplArgument, mode);

  final rstr = r('str');
  final rEmptyStr = r('');
  final aEmptyStr = a('');
  Expect.equals(2, rstr.lastIndexOf(aEmptyStr, 2));
  Expect.equals(0, rEmptyStr.lastIndexOf(aEmptyStr, 0));
  Expect.equals(-1, rEmptyStr.lastIndexOf(a('a'), 0));

  final astr = a('str');
  final astring = a('string');
  final at = a('t');
  Expect.equals(1, rstr.lastIndexOf(at));
  Expect.equals(0, rstr.lastIndexOf(astr, 2));
  Expect.equals(2, rstr.lastIndexOf(a('r'), 2));
  Expect.equals(-1, rstr.lastIndexOf(astring, 2));

  final rstrstr = r('strstr');
  Expect.equals(4, rstrstr.lastIndexOf(at, 5));
  Expect.equals(3, rstrstr.lastIndexOf(astr, 5));
  Expect.throws(() {
    rstr.lastIndexOf(astring, 5);
  });
  Expect.equals(4, rstrstr.lastIndexOf(at, 5));
  Expect.equals(3, rstrstr.lastIndexOf(astr, 5));
  Expect.equals(5, rstrstr.lastIndexOf(a('r')));
  Expect.equals(5, rstrstr.lastIndexOf(a('r'), null));

  for (int i = 0; i < 5; i++) {
    if (i > rstr.length) {
      Expect.throws(() => rstr.indexOf(aEmptyStr, i));
    } else {
      int result = rstr.lastIndexOf(aEmptyStr, i);
      Expect.equals(i, result);
    }
  }

  final banana = r('banana');
  var re = RegExp('an?');
  Expect.equals(5, banana.lastIndexOf(re));
  Expect.equals(5, banana.lastIndexOf(re, 6));
  Expect.equals(5, banana.lastIndexOf(re, 5));
  Expect.equals(3, banana.lastIndexOf(re, 4));
  Expect.equals(3, banana.lastIndexOf(re, 3));
  Expect.equals(1, banana.lastIndexOf(re, 2));
  Expect.equals(1, banana.lastIndexOf(re, 1));
  Expect.equals(-1, banana.lastIndexOf(re, 0));
  Expect.throws(() => banana.lastIndexOf(re, -1));
  Expect.throws(() => banana.lastIndexOf(re, 7));
  re = RegExp('x?');
  for (int i = 0; i <= rstr.length; i++) {
    Expect.equals(i, rstr.indexOf(re, i));
  }
}

void testHashCode() {
  for (final str in ['', 'foobar', 'hello world !']) {
    String a = str;
    String b = jsStringImpl(str);
    Expect.equals(a, b);
    Expect.equals(a.hashCode, b.hashCode);
  }
}

void testContains(TestMode mode) {
  String r(String s) => getStr(s, Position.jsStringImplReceiver, mode);
  String a(String s) => getStr(s, Position.jsStringImplArgument, mode);

  final rstr = r('str');
  Expect.isTrue(rstr.contains(a('s'), 0));
  Expect.isTrue(rstr.contains(a('st'), 0));
  Expect.isTrue(rstr.contains(a('str'), 0));
  Expect.isTrue(rstr.contains(a('t'), 0));
  Expect.isTrue(rstr.contains(a('r'), 0));
  Expect.isTrue(rstr.contains(a('tr'), 0));

  Expect.isFalse(rstr.contains(a('sr'), 0));
  Expect.isFalse(rstr.contains(a('string'), 0));

  Expect.isTrue(rstr.contains(a(''), 0));
  Expect.isTrue(r('').contains(a(''), 0));
  Expect.isFalse(r('').contains(a('s'), 0));
}

void testReplaceAll(TestMode mode) {
  String r(String s) => getStr(s, Position.jsStringImplReceiver, mode);
  String a(String s) => getStr(s, Position.jsStringImplArgument, mode);

  final aFrom = a('from');
  final aTo = a('to');
  final aEmptyStr = a('');
  Expect.equals('AtoBtoCDtoE', r('AfromBfromCDfromE').replaceAll(aFrom, aTo));
  Expect.equals('toABtoCDtoE', r('fromABfromCDfromE').replaceAll(aFrom, aTo));
  Expect.equals(
      'toABtoCDtoEto', r('fromABfromCDfromEfrom').replaceAll(aFrom, aTo));
  Expect.equals('ABC', r('ABC').replaceAll(aFrom, aTo));
  Expect.equals('', r('').replaceAll(aFrom, aTo));
  Expect.equals('fro', r('fro').replaceAll(aFrom, aTo));
  Expect.equals('to', r('from').replaceAll(aFrom, aTo));
  Expect.equals('to', r('to').replaceAll(aFrom, aTo));
  Expect.equals('', r('from').replaceAll(aFrom, aEmptyStr));
  Expect.equals('AB', r('AfromB').replaceAll(aFrom, aEmptyStr));
  Expect.equals('to', r('').replaceAll(aEmptyStr, aTo));
  Expect.equals('toAtoBtoCto', r('ABC').replaceAll(aEmptyStr, aTo));
  Expect.equals('aXXcaXXdae', r('abcabdae').replaceAll(RegExp('b'), a('XX')));
  Expect.equals(
      'aXXcaXXdae', r('abcabdae').replaceAll(RegExpWrap('b'), a('XX')));
}

void testReplaceAllMapped(TestMode mode) {
  String r(String s) => getStr(s, Position.jsStringImplReceiver, mode);
  String a(String s) => getStr(s, Position.jsStringImplArgument, mode);
  String mark(Match m) => a('[${m[0]}]');
  Expect.equals('a[b]ca[b]dae', r('abcabdae').replaceAllMapped(a('b'), mark));
  Expect.equals('abcabdae', r('abcabdae').replaceAllMapped(a('f'), mark));
  Expect.equals('', r('').replaceAllMapped(a('from'), mark));
  Expect.equals('bcbde', r('abcabdae').replaceAllMapped(a('a'), (m) => a('')));
  Expect.equals('[]', r('').replaceAllMapped(a(''), mark));
  Expect.equals('[]A[]B[]C[]', r('ABC').replaceAllMapped(a(''), mark));
  Expect.equals('aXXcaXXdae',
      r('abcabdae').replaceAllMapped(RegExp('b'), (_) => a('XX')));
  Expect.equals('aXXcaXXdae',
      r('abcabdae').replaceAllMapped(RegExpWrap('b'), (_) => a('XX')));
}

void testCompareTo(TestMode mode) {
  String r(String s) => getStr(s, Position.jsStringImplReceiver, mode);
  String a(String s) => getStr(s, Position.jsStringImplArgument, mode);

  Expect.equals(0, r('').compareTo(a('')));
  Expect.equals(0, r('str').compareTo(a('str')));
  Expect.equals(-1, r('str').compareTo(a('string')));
  Expect.equals(1, r('string').compareTo(a('str')));
  Expect.equals(1, r('string').compareTo(a('')));
  Expect.equals(-1, r('').compareTo(a('string')));
}

void testCharCodes() {
  void test(String str) {
    final list = str.codeUnits;
    Expect.equals(str.length, list.length);
    for (int i = 0; i < str.length; i++) {
      Expect.equals(str.codeUnitAt(i), list[i]);
    }
  }

  test(jsStringImpl('abc'));
  test(jsStringImpl(''));
  test(jsStringImpl(' '));
}

void testRepeat() {
  List<String> testStrings = [
    '',
    '\x00',
    'a',
    'ab',
    '\x80',
    '\xff',
    '\u2028',
    'abcdef\u2028',
    '\u{10002}',
    'abcdef\u{10002}'
  ].map(jsStringImpl).toList();
  List<int> counts = [
    0,
    1,
    2,
    10,
  ];
  void testRepeat(String str, int repeat) {
    String expect;
    if (repeat <= 0) {
      expect = '';
    } else if (repeat == 1) {
      expect = str;
    } else {
      StringBuffer buf = new StringBuffer();
      for (int i = 0; i < repeat; i++) {
        buf.write(str);
      }
      expect = buf.toString();
    }
    String actual = str * repeat;
    Expect.equals(expect, actual, '$str#${str.length} * $repeat');
  }

  for (String str in testStrings) {
    for (int repeat in counts) {
      testRepeat(str, repeat);
    }
  }
}

void testPadLeft(TestMode mode) {
  String r(String s) => getStr(s, Position.jsStringImplReceiver, mode);
  String a(String s) => getStr(s, Position.jsStringImplArgument, mode);

  Expect.equals('    1', r('1').padLeft(5, a(' ')));
  Expect.equals('   \u{10002}', r('\u{10002}').padLeft(5, a(' ')));
  Expect.equals('', r('').padLeft(0, a('a')));
  Expect.equals('a', r('').padLeft(1, a('a')));
  Expect.equals('', r('').padLeft(-2, a('a')));

  Expect.equals('xyzxyzxyzxyzxyz', r('').padLeft(5, a('xyz')));
  Expect.equals('xyzxyzxyzxyza', r('a').padLeft(5, a('xyz')));
  Expect.equals(
      '\u{10002}\u{10002}\u{10002}aa', r('aa').padLeft(5, a('\u{10002}')));
}

void testPadRight(TestMode mode) {
  String r(String s) => getStr(s, Position.jsStringImplReceiver, mode);
  String a(String s) => getStr(s, Position.jsStringImplArgument, mode);

  Expect.equals('1    ', r('1').padRight(5, a(' ')));
  Expect.equals('\u{10002}   ', r('\u{10002}').padRight(5, a(' ')));
  Expect.equals('', r('').padRight(0, a('a')));
  Expect.equals('a', r('').padRight(1, a('a')));
  Expect.equals('', r('').padRight(-2, a('a')));

  Expect.equals('xyzxyzxyzxyzxyz', r('').padRight(5, a('xyz')));
  Expect.equals('axyzxyzxyzxyz', r('a').padRight(5, a('xyz')));
  Expect.equals(
      'aa\u{10002}\u{10002}\u{10002}', r('aa').padRight(5, a('\u{10002}')));
  Expect.equals('a', r('a').padRight(10, a('')));
}

// Characters with Whitespace property (Unicode 6.3).
// 0009..000D    ; White_Space # Cc       <control-0009>..<control-000D>
// 0020          ; White_Space # Zs       SPACE
// 0085          ; White_Space # Cc       <control-0085>
// 00A0          ; White_Space # Zs       NO-BREAK SPACE
// 1680          ; White_Space # Zs       OGHAM SPACE MARK
// 2000..200A    ; White_Space # Zs       EN QUAD..HAIR SPACE
// 2028          ; White_Space # Zl       LINE SEPARATOR
// 2029          ; White_Space # Zp       PARAGRAPH SEPARATOR
// 202F          ; White_Space # Zs       NARROW NO-BREAK SPACE
// 205F          ; White_Space # Zs       MEDIUM MATHEMATICAL SPACE
// 3000          ; White_Space # Zs       IDEOGRAPHIC SPACE
// And BOM:
// FEFF          ; Byte order mark.
const whitespace = const [
  0x09,
  0x0A,
  0x0B,
  0x0C,
  0x0D,
  0x20,
  0x85,
  0xA0,
  0x1680,
  0x2000,
  0x2001,
  0x2002,
  0x2003,
  0x2004,
  0x2005,
  0x2006,
  0x2007,
  0x2008,
  0x2009,
  0x200A,
  0x2028,
  0x2029,
  0x202F,
  0x205F,
  0x3000,
  0xFEFF,
];

void testTrimTest() {
  String s(String a) => jsStringImpl(a);

  Expect.equals('', s(' ').trim());
  Expect.equals('', s('     ').trim());
  Expect.equals('left', s('      left').trim());
  Expect.equals('right', s('right    ').trim());
  Expect.equals('', ' \t \n \r '.trim());

  for (final ws in whitespace) {
    Expect.equals('', s(String.fromCharCode(ws)).trim());
  }
}

void testTrimLeftTest() {
  String s(String a) => jsStringImpl(a);

  Expect.equals('', s(' ').trimLeft());
  Expect.equals('', s('     ').trimLeft());
  Expect.equals('left', s('      left').trimLeft());
  Expect.equals('right    ', s('right    ').trimLeft());
  Expect.equals('', ' \t \n \r '.trimLeft());

  for (final ws in whitespace) {
    Expect.equals('', s(String.fromCharCode(ws)).trimLeft());
  }
}

void testTrimRightTest() {
  String s(String a) => jsStringImpl(a);

  Expect.equals('', s(' ').trimRight());
  Expect.equals('', s('     ').trimRight());
  Expect.equals('      left', s('      left').trimRight());
  Expect.equals('right', s('right    ').trimRight());
  Expect.equals('', ' \t \n \r '.trimRight());

  for (final ws in whitespace) {
    Expect.equals('', s(String.fromCharCode(ws)).trimRight());
  }
}

void testMatch(TestMode mode) {
  String r(String s) => getStr(s, Position.jsStringImplReceiver, mode);
  String a(String s) => getStr(s, Position.jsStringImplArgument, mode);

  String astr = a('this is a string with hello here and hello there');

  // No match:
  {
    final helloPattern = r('with (hello)');
    final matches = helloPattern.allMatches(astr);
    Expect.isFalse(matches.iterator.moveNext());
  }

  int check(String helloPattern, Iterable<Match> matches, String expected) {
    int count = 0;
    int start = 0;
    for (final match in matches) {
      Expect.equals(astr.indexOf(expected, start), match.start);
      Expect.equals(
          astr.indexOf(expected, start) + helloPattern.length, match.end);
      Expect.equals(helloPattern, match.pattern);
      Expect.equals(astr, match.input);
      Expect.equals(helloPattern, match[0]);
      Expect.equals(0, match.groupCount);
      count++;
      start = match.end;
    }
    return count;
  }

  // One match:
  {
    String helloPattern = r('with hello');
    Iterable<Match> matches = helloPattern.allMatches(astr);
    final count = check(helloPattern, matches, a('with'));
    Expect.equals(1, count);
  }

  // Two matches:
  {
    String helloPattern = r('hello');
    Iterable<Match> matches = helloPattern.allMatches(astr);
    final count = check(helloPattern, matches, a('hello'));
    Expect.equals(2, count);
  }

  // Empty pattern:
  {
    String pattern = r('');
    Iterable<Match> matches = pattern.allMatches(astr);
    Expect.isTrue(matches.iterator.moveNext());
  }

  // Empty string:
  {
    String pattern = r('foo');
    String str = a('');
    Iterable<Match> matches = pattern.allMatches(str);
    Expect.isFalse(matches.iterator.moveNext());
  }

  // Empty pattern and string:
  {
    String pattern = r('');
    String str = a('');
    Iterable<Match> matches = pattern.allMatches(str);
    Expect.isTrue(matches.iterator.moveNext());
  }

  // Match as prefix:
  {
    String pattern = r('an');
    String str = a('banana');
    Expect.isNull(pattern.matchAsPrefix(str));
    Expect.isNull(pattern.matchAsPrefix(str, 0));
    var m = pattern.matchAsPrefix(str, 1)!;
    Expect.equals('an', m[0]);
    Expect.equals(1, m.start);
    Expect.isNull(pattern.matchAsPrefix(str, 2));
    m = pattern.matchAsPrefix(str, 3)!;
    Expect.equals('an', m[0]);
    Expect.equals(3, m.start);
    Expect.isNull(pattern.matchAsPrefix(str, 4));
    Expect.isNull(pattern.matchAsPrefix(str, 5));
    Expect.isNull(pattern.matchAsPrefix(str, 6));
    Expect.throws(() => pattern.matchAsPrefix(str, -1));
    Expect.throws(() => pattern.matchAsPrefix(str, 7));
  }

  // Start:
  {
    String p = r('ass');
    String s = a('assassin');
    Expect.equals(2, p.allMatches(s).length);
    Expect.equals(2, p.allMatches(s, 0).length);
    Expect.equals(1, p.allMatches(s, 1).length);
    Expect.equals(0, p.allMatches(s, 4).length);
    Expect.equals(0, p.allMatches(s, s.length).length);
    Expect.throws(() => p.allMatches(s, -1));
    Expect.throws(() => p.allMatches(s, s.length + 1));
  }
}

void testSubstring() {
  String s(String a) => jsStringImpl(a);

  final emptyStr = s('');
  Expect.equals(emptyStr.substring(0), '');
  Expect.throwsRangeError(() => emptyStr.substring(1));
  Expect.throwsRangeError(() => emptyStr.substring(-1));

  final abcStr = s('abc');
  Expect.equals(abcStr.substring(0), 'abc');
  Expect.equals(abcStr.substring(1), 'bc');
  Expect.equals(abcStr.substring(2), 'c');
  Expect.equals(abcStr.substring(3), '');
  Expect.throwsRangeError(() => abcStr.substring(4));
  Expect.throwsRangeError(() => abcStr.substring(-1));

  // Test that providing null goes to the end.
  Expect.equals(emptyStr.substring(0, null), '');
  Expect.throwsRangeError(() => emptyStr.substring(1, null));
  Expect.throwsRangeError(() => emptyStr.substring(-1, null));

  Expect.equals(abcStr.substring(0, null), 'abc');
  Expect.equals(abcStr.substring(1, null), 'bc');
  Expect.equals(abcStr.substring(2, null), 'c');
  Expect.equals(abcStr.substring(3, null), '');
  Expect.throwsRangeError(() => abcStr.substring(4, null));
  Expect.throwsRangeError(() => abcStr.substring(-1, null));
}

void testSplitString(TestMode mode) {
  String r(String s) => getStr(s, Position.jsStringImplReceiver, mode);
  String a(String s) => getStr(s, Position.jsStringImplArgument, mode);

  Expect.listEquals(['a', 'b', 'c'], r('a b c').split(a(' ')));
  Expect.listEquals(['a', 'b', 'c'], r('adbdc').split(a('d')));
  Expect.listEquals(['abc'], r('abc').split(a(' ')));
  Expect.listEquals(['a', 'b', 'c'], a('abc').split(a('')));
}

void testSplit(TestMode mode, Pattern p(String s)) {
  String r(String s) => getStr(s, Position.jsStringImplReceiver, mode);

  Expect.listEquals(['a', 'b', 'c'], r('a b c').split(p(' ')));
  Expect.listEquals(['a', 'b', 'c'], r('adbdc').split(p(r'[dz]')));
}

void testSplitRegExp(TestMode mode) => testSplit(mode, (s) => RegExp(s));

void testSplitUserPattern(TestMode mode) =>
    testSplit(mode, (s) => RegExpWrap(s));

void testCase() {
  String s(String a) => jsStringImpl(a);

  Expect.equals('ABC', s('aBc').toUpperCase());
  Expect.equals('abc', s('AbC').toLowerCase());
}

void testReplace(TestMode mode) {
  String r(String s) => getStr(s, Position.jsStringImplReceiver, mode);
  String a(String s) => getStr(s, Position.jsStringImplArgument, mode);

  // Test replaceFirst
  Expect.equals(
      'AtoBtoCDtoE', r('AfromBtoCDtoE').replaceFirst(a('from'), a('to')));
  Expect.equals(
      'toABtoCDtoE', r('fromABtoCDtoE').replaceFirst(a('from'), a('to')));
  Expect.equals(
      'toABtoCDtoEto', r('fromABtoCDtoEto').replaceFirst(a('from'), a('to')));
  Expect.equals('ABC', r('ABC').replaceFirst(a('from'), a('to')));
  Expect.equals('', r('').replaceFirst(a('from'), a('to')));
  Expect.equals('foo-AAA-foo-bar',
      r('foo-bar-foo-bar').replaceFirst(a('bar'), a('AAA'), 4));
  Expect.equals('foo-bar-foo-bar',
      r('foo-bar-foo-bar').replaceFirst(RegExp(r'^foo'), a(''), 8));
  Expect.throwsRangeError(() => r('hello').replaceFirst(a('h'), a('X'), -1));
  Expect.throwsRangeError(() => r('hello').replaceFirst(a('h'), a('X'), 6));

  // Test replaceFirstMapped.
  Expect.equals('AtoBtoCDtoE',
      r('AfromBtoCDtoE').replaceFirstMapped(a('from'), (_) => a('to')));
  Expect.equals('ABC', r('ABC').replaceFirstMapped(a('from'), (_) => a('to')));
  Expect.equals('', r('').replaceFirstMapped(a('from'), (_) => a('to')));
  Expect.equals('foo-AAA-foo-bar',
      r('foo-bar-foo-bar').replaceFirstMapped(a('bar'), (_) => a('AAA'), 4));
  Expect.equals(
      'foo-bar-foo-bar',
      r('foo-bar-foo-bar')
          .replaceFirstMapped(RegExp(r'^foo'), (_) => a(''), 8));
  Expect.throwsRangeError(
      () => r('hello').replaceFirstMapped(a('h'), (_) => a('X'), -1));
  Expect.throwsRangeError(
      () => r('hello').replaceFirstMapped(a('h'), (_) => a('X'), 6));
  Expect.equals(
      'foo-BAR-foo-bar',
      r('foo-bar-foo-bar')
          .replaceFirstMapped(a('bar'), (v) => a(v[0]!.toUpperCase())));

  for (final string in [r(''), r('x'), r('foo'), r('x\u2000z')]) {
    for (final replacement in [a(''), a('foo'), a(string)]) {
      for (int start = 0; start <= string.length; start++) {
        var expect;
        for (int end = start; end <= string.length; end++) {
          expect =
              string.substring(0, start) + replacement + string.substring(end);
          Expect.equals(expect, string.replaceRange(start, end, replacement),
              "'$string'[$start:$end]='$replacement'");
        }
        // Reuse expect from 'end == string.length' case when omitting end.
        Expect.equals(expect, string.replaceRange(start, null, replacement),
            "'$string'[$start:]='$replacement'");
      }
    }
    Expect.throws(() => string.replaceRange(-1, 0, 'x'));
    Expect.throws(() => string.replaceRange(0, string.length + 1, 'x'));
  }
}

void testSplitMapJoin(TestMode mode) {
  String r(String s) => getStr(s, Position.jsStringImplReceiver, mode);
  String a(String s) => getStr(s, Position.jsStringImplArgument, mode);
  String mark(Match m) => a('[${m[0]}]');
  String rest(String s) => a('<${s}>');

  Expect.equals('<a>[b]<ca>[b]<dae>',
      r('abcabdae').splitMapJoin(a('b'), onMatch: mark, onNonMatch: rest));
  Expect.equals('<abcabdae>',
      r('abcabdae').splitMapJoin(a('f'), onMatch: mark, onNonMatch: rest));
  Expect.equals(
      '<>', r('').splitMapJoin(a('from'), onMatch: mark, onNonMatch: rest));
  Expect.equals(
      '<>[]<>', r('').splitMapJoin(a(''), onMatch: mark, onNonMatch: rest));
  Expect.equals('<>[]<A>[]<B>[]<C>[]<>',
      r('ABC').splitMapJoin(a(''), onMatch: mark, onNonMatch: rest));
  Expect.equals(
      '[a]bc[a]bd[a]e', r('abcabdae').splitMapJoin(a('a'), onMatch: mark));
  Expect.equals(
      '<>a<bc>a<bd>a<e>', r('abcabdae').splitMapJoin(a('a'), onNonMatch: rest));
}

void main() {
  for (final mode in [
    TestMode.jsStringImplReceiver,
    TestMode.jsStringImplArgument,
    TestMode.jsStringImplReceiverAndArguments
  ]) {
    testLength(mode);
    testConcat(mode);
    testEquals(mode);
    testEndsWith(mode);
    testStartsWith(mode);
    testIndexOf(mode);
    testLastIndexOf(mode);
    testContains(mode);
    testReplaceAll(mode);
    testReplaceAllMapped(mode);
    testCompareTo(mode);
    testPadLeft(mode);
    testPadRight(mode);
    testMatch(mode);
    testSplitString(mode);
    testSplitRegExp(mode);
    testSplitUserPattern(mode);
    testReplace(mode);
    testSplitMapJoin(mode);
  }

  testOutOfRange();
  testIndex();
  testCodeUnitAt();
  testHashCode();
  testCharCodes();
  testRepeat();
  testTrimTest();
  testTrimLeftTest();
  testTrimRightTest();
  testSubstring();
  testCase();
}

// A Pattern implementation with the same capabilities as a RegExp, but not
// directly recognizable as a RegExp.
class RegExpWrap implements Pattern {
  final RegExp regexp;
  RegExpWrap(String source) : regexp = RegExp(source);
  Iterable<Match> allMatches(String string, [int start = 0]) =>
      regexp.allMatches(string, start);

  Match? matchAsPrefix(String string, [int start = 0]) =>
      regexp.matchAsPrefix(string, start);

  String toString() => 'Wrap(/${regexp.pattern}/)';
}
