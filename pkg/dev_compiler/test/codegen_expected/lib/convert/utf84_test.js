dart_library.library('lib/convert/utf84_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__utf84_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const convert = dart_sdk.convert;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const utf84_test = Object.create(null);
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let StringToListOfint = () => (StringToListOfint = dart.constFn(dart.definiteFunctionType(ListOfint(), [core.String])))();
  let ListOfintToListOfint = () => (ListOfintToListOfint = dart.constFn(dart.definiteFunctionType(ListOfint(), [ListOfint()])))();
  let ListOfintToString = () => (ListOfintToString = dart.constFn(dart.definiteFunctionType(core.String, [ListOfint()])))();
  utf84_test.testEnglishPhrase = "The quick brown fox jumps over the lazy dog.";
  utf84_test.testEnglishUtf8 = dart.constList([84, 104, 101, 32, 113, 117, 105, 99, 107, 32, 98, 114, 111, 119, 110, 32, 102, 111, 120, 32, 106, 117, 109, 112, 115, 32, 111, 118, 101, 114, 32, 116, 104, 101, 32, 108, 97, 122, 121, 32, 100, 111, 103, 46], core.int);
  utf84_test.testDanishPhrase = "Quizdeltagerne spiste jordbær med " + "fløde mens cirkusklovnen Wolther spillede på xylofon.";
  utf84_test.testDanishUtf8 = dart.constList([81, 117, 105, 122, 100, 101, 108, 116, 97, 103, 101, 114, 110, 101, 32, 115, 112, 105, 115, 116, 101, 32, 106, 111, 114, 100, 98, 195, 166, 114, 32, 109, 101, 100, 32, 102, 108, 195, 184, 100, 101, 32, 109, 101, 110, 115, 32, 99, 105, 114, 107, 117, 115, 107, 108, 111, 118, 110, 101, 110, 32, 87, 111, 108, 116, 104, 101, 114, 32, 115, 112, 105, 108, 108, 101, 100, 101, 32, 112, 195, 165, 32, 120, 121, 108, 111, 102, 111, 110, 46], core.int);
  utf84_test.testHebrewPhrase = "דג סקרן שט בים מאוכזב ולפתע מצא לו חברה איך הקליטה";
  utf84_test.testHebrewUtf8 = dart.constList([215, 147, 215, 146, 32, 215, 161, 215, 167, 215, 168, 215, 159, 32, 215, 169, 215, 152, 32, 215, 145, 215, 153, 215, 157, 32, 215, 158, 215, 144, 215, 149, 215, 155, 215, 150, 215, 145, 32, 215, 149, 215, 156, 215, 164, 215, 170, 215, 162, 32, 215, 158, 215, 166, 215, 144, 32, 215, 156, 215, 149, 32, 215, 151, 215, 145, 215, 168, 215, 148, 32, 215, 144, 215, 153, 215, 154, 32, 215, 148, 215, 167, 215, 156, 215, 153, 215, 152, 215, 148], core.int);
  utf84_test.testRussianPhrase = "Съешь же ещё этих мягких " + "французских булок да выпей чаю";
  utf84_test.testRussianUtf8 = dart.constList([208, 161, 209, 138, 208, 181, 209, 136, 209, 140, 32, 208, 182, 208, 181, 32, 208, 181, 209, 137, 209, 145, 32, 209, 141, 209, 130, 208, 184, 209, 133, 32, 208, 188, 209, 143, 208, 179, 208, 186, 208, 184, 209, 133, 32, 209, 132, 209, 128, 208, 176, 208, 189, 209, 134, 209, 131, 208, 183, 209, 129, 208, 186, 208, 184, 209, 133, 32, 208, 177, 209, 131, 208, 187, 208, 190, 208, 186, 32, 208, 180, 208, 176, 32, 208, 178, 209, 139, 208, 191, 208, 181, 208, 185, 32, 209, 135, 208, 176, 209, 142], core.int);
  utf84_test.testGreekPhrase = "Γαζέες καὶ μυρτιὲς δὲν θὰ βρῶ πιὰ " + "στὸ χρυσαφὶ ξέφωτο";
  utf84_test.testGreekUtf8 = dart.constList([206, 147, 206, 177, 206, 182, 206, 173, 206, 181, 207, 130, 32, 206, 186, 206, 177, 225, 189, 182, 32, 206, 188, 207, 133, 207, 129, 207, 132, 206, 185, 225, 189, 178, 207, 130, 32, 206, 180, 225, 189, 178, 206, 189, 32, 206, 184, 225, 189, 176, 32, 206, 178, 207, 129, 225, 191, 182, 32, 207, 128, 206, 185, 225, 189, 176, 32, 207, 131, 207, 132, 225, 189, 184, 32, 207, 135, 207, 129, 207, 133, 207, 131, 206, 177, 207, 134, 225, 189, 182, 32, 206, 190, 206, 173, 207, 134, 207, 137, 207, 132, 206, 191], core.int);
  utf84_test.testKatakanaPhrase = "イロハニホヘト チリヌルヲ ワカヨタレソ " + "ツネナラム ウヰノオクヤマ ケフコエテ アサキユメミシ ヱヒモセスン";
  utf84_test.testKatakanaUtf8 = dart.constList([227, 130, 164, 227, 131, 173, 227, 131, 143, 227, 131, 139, 227, 131, 155, 227, 131, 152, 227, 131, 136, 32, 227, 131, 129, 227, 131, 170, 227, 131, 140, 227, 131, 171, 227, 131, 178, 32, 227, 131, 175, 227, 130, 171, 227, 131, 168, 227, 130, 191, 227, 131, 172, 227, 130, 189, 32, 227, 131, 132, 227, 131, 141, 227, 131, 138, 227, 131, 169, 227, 131, 160, 32, 227, 130, 166, 227, 131, 176, 227, 131, 142, 227, 130, 170, 227, 130, 175, 227, 131, 164, 227, 131, 158, 32, 227, 130, 177, 227, 131, 149, 227, 130, 179, 227, 130, 168, 227, 131, 134, 32, 227, 130, 162, 227, 130, 181, 227, 130, 173, 227, 131, 166, 227, 131, 161, 227, 131, 159, 227, 130, 183, 32, 227, 131, 177, 227, 131, 146, 227, 131, 162, 227, 130, 187, 227, 130, 185, 227, 131, 179], core.int);
  utf84_test.main = function() {
    utf84_test.testUtf8bytesToCodepoints();
    utf84_test.testUtf8BytesToString();
    utf84_test.testEncodeToUtf8();
  };
  dart.fn(utf84_test.main, VoidTovoid());
  utf84_test.encodeUtf8 = function(str) {
    return convert.UTF8.encode(str);
  };
  dart.fn(utf84_test.encodeUtf8, StringToListOfint());
  utf84_test.utf8ToRunes = function(codeUnits) {
    return convert.UTF8.decode(codeUnits, {allowMalformed: true})[dartx.runes].toList();
  };
  dart.fn(utf84_test.utf8ToRunes, ListOfintToListOfint());
  utf84_test.decodeUtf8 = function(codeUnits) {
    return convert.UTF8.decode(codeUnits);
  };
  dart.fn(utf84_test.decodeUtf8, ListOfintToString());
  utf84_test.testEncodeToUtf8 = function() {
    expect$.Expect.listEquals(utf84_test.testEnglishUtf8, utf84_test.encodeUtf8(utf84_test.testEnglishPhrase), "english to utf8");
    expect$.Expect.listEquals(utf84_test.testDanishUtf8, utf84_test.encodeUtf8(utf84_test.testDanishPhrase), "encode danish to utf8");
    expect$.Expect.listEquals(utf84_test.testHebrewUtf8, utf84_test.encodeUtf8(utf84_test.testHebrewPhrase), "Hebrew to utf8");
    expect$.Expect.listEquals(utf84_test.testRussianUtf8, utf84_test.encodeUtf8(utf84_test.testRussianPhrase), "Russian to utf8");
    expect$.Expect.listEquals(utf84_test.testGreekUtf8, utf84_test.encodeUtf8(utf84_test.testGreekPhrase), "Greek to utf8");
    expect$.Expect.listEquals(utf84_test.testKatakanaUtf8, utf84_test.encodeUtf8(utf84_test.testKatakanaPhrase), "Katakana to utf8");
  };
  dart.fn(utf84_test.testEncodeToUtf8, VoidTovoid());
  utf84_test.testUtf8bytesToCodepoints = function() {
    expect$.Expect.listEquals(JSArrayOfint().of([954, 972, 963, 956, 949]), utf84_test.utf8ToRunes(JSArrayOfint().of([206, 186, 207, 140, 207, 131, 206, 188, 206, 181])), "κόσμε");
    expect$.Expect.listEquals([], utf84_test.utf8ToRunes(JSArrayOfint().of([])), "no input");
    expect$.Expect.listEquals(JSArrayOfint().of([0]), utf84_test.utf8ToRunes(JSArrayOfint().of([0])), "0");
    expect$.Expect.listEquals(JSArrayOfint().of([128]), utf84_test.utf8ToRunes(JSArrayOfint().of([194, 128])), "80");
    expect$.Expect.listEquals(JSArrayOfint().of([2048]), utf84_test.utf8ToRunes(JSArrayOfint().of([224, 160, 128])), "800");
    expect$.Expect.listEquals(JSArrayOfint().of([65536]), utf84_test.utf8ToRunes(JSArrayOfint().of([240, 144, 128, 128])), "10000");
    expect$.Expect.listEquals(JSArrayOfint().of([convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE]), utf84_test.utf8ToRunes(JSArrayOfint().of([248, 136, 128, 128, 128])), "200000");
    expect$.Expect.listEquals(JSArrayOfint().of([convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE]), utf84_test.utf8ToRunes(JSArrayOfint().of([252, 132, 128, 128, 128, 128])), "4000000");
    expect$.Expect.listEquals(JSArrayOfint().of([127]), utf84_test.utf8ToRunes(JSArrayOfint().of([127])), "7f");
    expect$.Expect.listEquals(JSArrayOfint().of([2047]), utf84_test.utf8ToRunes(JSArrayOfint().of([223, 191])), "7ff");
    expect$.Expect.listEquals(JSArrayOfint().of([65535]), utf84_test.utf8ToRunes(JSArrayOfint().of([239, 191, 191])), "ffff");
    expect$.Expect.listEquals(JSArrayOfint().of([convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE]), utf84_test.utf8ToRunes(JSArrayOfint().of([247, 191, 191, 191])), "1fffff");
    expect$.Expect.listEquals(JSArrayOfint().of([convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE]), utf84_test.utf8ToRunes(JSArrayOfint().of([251, 191, 191, 191, 191])), "3ffffff");
    expect$.Expect.listEquals(JSArrayOfint().of([convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE]), utf84_test.utf8ToRunes(JSArrayOfint().of([253, 191, 191, 191, 191, 191])), "4000000");
    expect$.Expect.listEquals(JSArrayOfint().of([55295]), utf84_test.utf8ToRunes(JSArrayOfint().of([237, 159, 191])), "d7ff");
    expect$.Expect.listEquals(JSArrayOfint().of([57344]), utf84_test.utf8ToRunes(JSArrayOfint().of([238, 128, 128])), "e000");
    expect$.Expect.listEquals(JSArrayOfint().of([convert.UNICODE_REPLACEMENT_CHARACTER_RUNE]), utf84_test.utf8ToRunes(JSArrayOfint().of([239, 191, 189])), "fffd");
    expect$.Expect.listEquals(JSArrayOfint().of([1114111]), utf84_test.utf8ToRunes(JSArrayOfint().of([244, 143, 191, 191])), "10ffff");
    expect$.Expect.listEquals(JSArrayOfint().of([convert.UNICODE_REPLACEMENT_CHARACTER_RUNE]), utf84_test.utf8ToRunes(JSArrayOfint().of([244, 144, 128, 128])), "110000");
    expect$.Expect.listEquals(JSArrayOfint().of([convert.UNICODE_REPLACEMENT_CHARACTER_RUNE]), utf84_test.utf8ToRunes(JSArrayOfint().of([128])), "80 => replacement character");
    expect$.Expect.listEquals(JSArrayOfint().of([convert.UNICODE_REPLACEMENT_CHARACTER_RUNE]), utf84_test.utf8ToRunes(JSArrayOfint().of([191])), "bf => replacement character");
    let allContinuationBytes = JSArrayOfint().of([]);
    let matchingReplacementChars = JSArrayOfint().of([]);
    for (let i = 128; i < 192; i++) {
      allContinuationBytes[dartx.add](i);
      matchingReplacementChars[dartx.add](convert.UNICODE_REPLACEMENT_CHARACTER_RUNE);
    }
    expect$.Expect.listEquals(matchingReplacementChars, utf84_test.utf8ToRunes(allContinuationBytes), "80 - bf => replacement character x 64");
    let allFirstTwoByteSeq = JSArrayOfint().of([]);
    matchingReplacementChars = JSArrayOfint().of([]);
    for (let i = 192; i < 224; i++) {
      allFirstTwoByteSeq[dartx.addAll](JSArrayOfint().of([i, 32]));
      matchingReplacementChars[dartx.addAll](JSArrayOfint().of([convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, 32]));
    }
    expect$.Expect.listEquals(matchingReplacementChars, utf84_test.utf8ToRunes(allFirstTwoByteSeq), "c0 - df + space => replacement character + space x 32");
    let allFirstThreeByteSeq = JSArrayOfint().of([]);
    matchingReplacementChars = JSArrayOfint().of([]);
    for (let i = 224; i < 240; i++) {
      allFirstThreeByteSeq[dartx.addAll](JSArrayOfint().of([i, 32]));
      matchingReplacementChars[dartx.addAll](JSArrayOfint().of([convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, 32]));
    }
    expect$.Expect.listEquals(matchingReplacementChars, utf84_test.utf8ToRunes(allFirstThreeByteSeq), "e0 - ef + space => replacement character x 16");
    let allFirstFourByteSeq = JSArrayOfint().of([]);
    matchingReplacementChars = JSArrayOfint().of([]);
    for (let i = 240; i < 248; i++) {
      allFirstFourByteSeq[dartx.addAll](JSArrayOfint().of([i, 32]));
      matchingReplacementChars[dartx.addAll](JSArrayOfint().of([convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, 32]));
    }
    expect$.Expect.listEquals(matchingReplacementChars, utf84_test.utf8ToRunes(allFirstFourByteSeq), "f0 - f7 + space => replacement character x 8");
    let allFirstFiveByteSeq = JSArrayOfint().of([]);
    matchingReplacementChars = JSArrayOfint().of([]);
    for (let i = 248; i < 252; i++) {
      allFirstFiveByteSeq[dartx.addAll](JSArrayOfint().of([i, 32]));
      matchingReplacementChars[dartx.addAll](JSArrayOfint().of([convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, 32]));
    }
    expect$.Expect.listEquals(matchingReplacementChars, utf84_test.utf8ToRunes(allFirstFiveByteSeq), "f8 - fb + space => replacement character x 4");
    let allFirstSixByteSeq = JSArrayOfint().of([]);
    matchingReplacementChars = JSArrayOfint().of([]);
    for (let i = 252; i < 254; i++) {
      allFirstSixByteSeq[dartx.addAll](JSArrayOfint().of([i, 32]));
      matchingReplacementChars[dartx.addAll](JSArrayOfint().of([convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, 32]));
    }
    expect$.Expect.listEquals(matchingReplacementChars, utf84_test.utf8ToRunes(allFirstSixByteSeq), "fc - fd + space => replacement character x 2");
    expect$.Expect.listEquals(JSArrayOfint().of([convert.UNICODE_REPLACEMENT_CHARACTER_RUNE]), utf84_test.utf8ToRunes(JSArrayOfint().of([194])), "2-byte sequence with last byte missing");
    expect$.Expect.listEquals(JSArrayOfint().of([convert.UNICODE_REPLACEMENT_CHARACTER_RUNE]), utf84_test.utf8ToRunes(JSArrayOfint().of([224, 128])), "3-byte sequence with last byte missing");
    expect$.Expect.listEquals(JSArrayOfint().of([convert.UNICODE_REPLACEMENT_CHARACTER_RUNE]), utf84_test.utf8ToRunes(JSArrayOfint().of([240, 128, 128])), "4-byte sequence with last byte missing");
    expect$.Expect.listEquals(JSArrayOfint().of([convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE]), utf84_test.utf8ToRunes(JSArrayOfint().of([248, 136, 128, 128])), "5-byte sequence with last byte missing");
    expect$.Expect.listEquals(JSArrayOfint().of([convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE]), utf84_test.utf8ToRunes(JSArrayOfint().of([252, 128, 128, 128, 128])), "6-byte sequence with last byte missing");
    expect$.Expect.listEquals(JSArrayOfint().of([convert.UNICODE_REPLACEMENT_CHARACTER_RUNE]), utf84_test.utf8ToRunes(JSArrayOfint().of([223])), "2-byte sequence with last byte missing (hi)");
    expect$.Expect.listEquals(JSArrayOfint().of([convert.UNICODE_REPLACEMENT_CHARACTER_RUNE]), utf84_test.utf8ToRunes(JSArrayOfint().of([239, 191])), "3-byte sequence with last byte missing (hi)");
    expect$.Expect.listEquals(JSArrayOfint().of([convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE]), utf84_test.utf8ToRunes(JSArrayOfint().of([247, 191, 191])), "4-byte sequence with last byte missing (hi)");
    expect$.Expect.listEquals(JSArrayOfint().of([convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE]), utf84_test.utf8ToRunes(JSArrayOfint().of([251, 191, 191, 191])), "5-byte sequence with last byte missing (hi)");
    expect$.Expect.listEquals(JSArrayOfint().of([convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE]), utf84_test.utf8ToRunes(JSArrayOfint().of([253, 191, 191, 191, 191])), "6-byte sequence with last byte missing (hi)");
    expect$.Expect.listEquals(JSArrayOfint().of([convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE]), utf84_test.utf8ToRunes(JSArrayOfint().of([194, 224, 128, 240, 128, 128, 248, 136, 128, 128, 252, 128, 128, 128, 128, 223, 239, 191, 247, 191, 191, 251, 191, 191, 191, 253, 191, 191, 191, 191])), "Concatenation of incomplete sequences");
    expect$.Expect.listEquals(JSArrayOfint().of([convert.UNICODE_REPLACEMENT_CHARACTER_RUNE]), utf84_test.utf8ToRunes(JSArrayOfint().of([254])), "fe");
    expect$.Expect.listEquals(JSArrayOfint().of([convert.UNICODE_REPLACEMENT_CHARACTER_RUNE]), utf84_test.utf8ToRunes(JSArrayOfint().of([255])), "ff");
    expect$.Expect.listEquals(JSArrayOfint().of([convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE]), utf84_test.utf8ToRunes(JSArrayOfint().of([254, 254, 255, 255])), "fe fe ff ff");
    expect$.Expect.listEquals(JSArrayOfint().of([convert.UNICODE_REPLACEMENT_CHARACTER_RUNE]), utf84_test.utf8ToRunes(JSArrayOfint().of([192, 175])), "c0 af");
    expect$.Expect.listEquals(JSArrayOfint().of([convert.UNICODE_REPLACEMENT_CHARACTER_RUNE]), utf84_test.utf8ToRunes(JSArrayOfint().of([224, 128, 175])), "e0 80 af");
    expect$.Expect.listEquals(JSArrayOfint().of([convert.UNICODE_REPLACEMENT_CHARACTER_RUNE]), utf84_test.utf8ToRunes(JSArrayOfint().of([240, 128, 128, 175])), "f0 80 80 af");
    expect$.Expect.listEquals(JSArrayOfint().of([convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE]), utf84_test.utf8ToRunes(JSArrayOfint().of([248, 128, 128, 128, 175])), "f8 80 80 80 af");
    expect$.Expect.listEquals(JSArrayOfint().of([convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE]), utf84_test.utf8ToRunes(JSArrayOfint().of([252, 128, 128, 128, 128, 175])), "fc 80 80 80 80 af");
    expect$.Expect.listEquals(JSArrayOfint().of([convert.UNICODE_REPLACEMENT_CHARACTER_RUNE]), utf84_test.utf8ToRunes(JSArrayOfint().of([193, 191])), "c1 bf");
    expect$.Expect.listEquals(JSArrayOfint().of([convert.UNICODE_REPLACEMENT_CHARACTER_RUNE]), utf84_test.utf8ToRunes(JSArrayOfint().of([224, 159, 191])), "e0 9f bf");
    expect$.Expect.listEquals(JSArrayOfint().of([convert.UNICODE_REPLACEMENT_CHARACTER_RUNE]), utf84_test.utf8ToRunes(JSArrayOfint().of([240, 143, 191, 191])), "f0 8f bf bf");
    expect$.Expect.listEquals(JSArrayOfint().of([convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE]), utf84_test.utf8ToRunes(JSArrayOfint().of([248, 135, 191, 191, 191])), "f8 87 bf bf bf");
    expect$.Expect.listEquals(JSArrayOfint().of([convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE]), utf84_test.utf8ToRunes(JSArrayOfint().of([252, 131, 191, 191, 191, 191])), "fc 83 bf bf bf bf");
    expect$.Expect.listEquals(JSArrayOfint().of([convert.UNICODE_REPLACEMENT_CHARACTER_RUNE]), utf84_test.utf8ToRunes(JSArrayOfint().of([192, 128])), "c0 80");
    expect$.Expect.listEquals(JSArrayOfint().of([convert.UNICODE_REPLACEMENT_CHARACTER_RUNE]), utf84_test.utf8ToRunes(JSArrayOfint().of([224, 128, 128])), "e0 80 80");
    expect$.Expect.listEquals(JSArrayOfint().of([convert.UNICODE_REPLACEMENT_CHARACTER_RUNE]), utf84_test.utf8ToRunes(JSArrayOfint().of([240, 128, 128, 128])), "f0 80 80 80");
    expect$.Expect.listEquals(JSArrayOfint().of([convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE]), utf84_test.utf8ToRunes(JSArrayOfint().of([248, 128, 128, 128, 128])), "f8 80 80 80 80");
    expect$.Expect.listEquals(JSArrayOfint().of([convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE, convert.UNICODE_REPLACEMENT_CHARACTER_RUNE]), utf84_test.utf8ToRunes(JSArrayOfint().of([252, 128, 128, 128, 128, 128])), "fc 80 80 80 80 80");
    expect$.Expect.listEquals(JSArrayOfint().of([65534]), utf84_test.utf8ToRunes(JSArrayOfint().of([239, 191, 190])), "U+FFFE");
    expect$.Expect.listEquals(JSArrayOfint().of([65535]), utf84_test.utf8ToRunes(JSArrayOfint().of([239, 191, 191])), "U+FFFF");
  };
  dart.fn(utf84_test.testUtf8bytesToCodepoints, VoidTovoid());
  utf84_test.testUtf8BytesToString = function() {
    expect$.Expect.stringEquals(utf84_test.testEnglishPhrase, utf84_test.decodeUtf8(utf84_test.testEnglishUtf8), "English");
    expect$.Expect.stringEquals(utf84_test.testDanishPhrase, utf84_test.decodeUtf8(utf84_test.testDanishUtf8), "Danish");
    expect$.Expect.stringEquals(utf84_test.testHebrewPhrase, utf84_test.decodeUtf8(utf84_test.testHebrewUtf8), "Hebrew");
    expect$.Expect.stringEquals(utf84_test.testRussianPhrase, utf84_test.decodeUtf8(utf84_test.testRussianUtf8), "Russian");
    expect$.Expect.stringEquals(utf84_test.testGreekPhrase, utf84_test.decodeUtf8(utf84_test.testGreekUtf8), "Greek");
    expect$.Expect.stringEquals(utf84_test.testKatakanaPhrase, utf84_test.decodeUtf8(utf84_test.testKatakanaUtf8), "Katakana");
  };
  dart.fn(utf84_test.testUtf8BytesToString, VoidTovoid());
  // Exports:
  exports.utf84_test = utf84_test;
});
