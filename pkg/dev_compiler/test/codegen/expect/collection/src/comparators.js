dart_library.library('collection/src/comparators', null, /* Imports */[
  'dart/_runtime',
  'dart/core'
], /* Lazy imports */[
], function(exports, dart, core) {
  'use strict';
  let dartx = dart.dartx;
  const _zero = 48;
  const _upperCaseA = 65;
  const _upperCaseZ = 90;
  const _lowerCaseA = 97;
  const _lowerCaseZ = 122;
  const _asciiCaseBit = 32;
  function equalsIgnoreAsciiCase(a, b) {
    if (a[dartx.length] != b[dartx.length]) return false;
    for (let i = 0; i < dart.notNull(a[dartx.length]); i++) {
      let aChar = a[dartx.codeUnitAt](i);
      let bChar = b[dartx.codeUnitAt](i);
      if (aChar == bChar) continue;
      if ((dart.notNull(aChar) ^ dart.notNull(bChar)) != _asciiCaseBit) return false;
      let aCharUpperCase = dart.notNull(aChar) | dart.notNull(_asciiCaseBit);
      if (dart.notNull(_upperCaseA) <= aCharUpperCase && aCharUpperCase <= dart.notNull(_upperCaseZ)) {
        continue;
      }
      return false;
    }
    return true;
  }
  dart.fn(equalsIgnoreAsciiCase, core.bool, [core.String, core.String]);
  function hashIgnoreAsciiCase(string) {
    let hash = 0;
    for (let i = 0; i < dart.notNull(string[dartx.length]); i++) {
      let char = string[dartx.codeUnitAt](i);
      if (dart.notNull(_lowerCaseA) <= dart.notNull(char) && dart.notNull(char) <= dart.notNull(_lowerCaseZ)) {
        char = dart.notNull(char) - dart.notNull(_asciiCaseBit);
      }
      hash = 536870911 & hash + dart.notNull(char);
      hash = 536870911 & hash + ((524287 & hash) << 10);
      hash = hash >> 6;
    }
    hash = 536870911 & hash + ((67108863 & hash) << 3);
    hash = hash >> 11;
    return 536870911 & hash + ((16383 & hash) << 15);
  }
  dart.fn(hashIgnoreAsciiCase, core.int, [core.String]);
  function compareAsciiUpperCase(a, b) {
    let defaultResult = 0;
    for (let i = 0; i < dart.notNull(a[dartx.length]); i++) {
      if (i >= dart.notNull(b[dartx.length])) return 1;
      let aChar = a[dartx.codeUnitAt](i);
      let bChar = b[dartx.codeUnitAt](i);
      if (aChar == bChar) continue;
      let aUpperCase = aChar;
      let bUpperCase = bChar;
      if (dart.notNull(_lowerCaseA) <= dart.notNull(aChar) && dart.notNull(aChar) <= dart.notNull(_lowerCaseZ)) {
        aUpperCase = dart.notNull(aUpperCase) - dart.notNull(_asciiCaseBit);
      }
      if (dart.notNull(_lowerCaseA) <= dart.notNull(bChar) && dart.notNull(bChar) <= dart.notNull(_lowerCaseZ)) {
        bUpperCase = dart.notNull(bUpperCase) - dart.notNull(_asciiCaseBit);
      }
      if (aUpperCase != bUpperCase) return (dart.notNull(aUpperCase) - dart.notNull(bUpperCase))[dartx.sign];
      if (defaultResult == 0) defaultResult = dart.notNull(aChar) - dart.notNull(bChar);
    }
    if (dart.notNull(b[dartx.length]) > dart.notNull(a[dartx.length])) return -1;
    return defaultResult[dartx.sign];
  }
  dart.fn(compareAsciiUpperCase, core.int, [core.String, core.String]);
  function compareAsciiLowerCase(a, b) {
    let defaultResult = 0;
    for (let i = 0; i < dart.notNull(a[dartx.length]); i++) {
      if (i >= dart.notNull(b[dartx.length])) return 1;
      let aChar = a[dartx.codeUnitAt](i);
      let bChar = b[dartx.codeUnitAt](i);
      if (aChar == bChar) continue;
      let aLowerCase = aChar;
      let bLowerCase = bChar;
      if (dart.notNull(_upperCaseA) <= dart.notNull(bChar) && dart.notNull(bChar) <= dart.notNull(_upperCaseZ)) {
        bLowerCase = dart.notNull(bLowerCase) + dart.notNull(_asciiCaseBit);
      }
      if (dart.notNull(_upperCaseA) <= dart.notNull(aChar) && dart.notNull(aChar) <= dart.notNull(_upperCaseZ)) {
        aLowerCase = dart.notNull(aLowerCase) + dart.notNull(_asciiCaseBit);
      }
      if (aLowerCase != bLowerCase) return (dart.notNull(aLowerCase) - dart.notNull(bLowerCase))[dartx.sign];
      if (defaultResult == 0) defaultResult = dart.notNull(aChar) - dart.notNull(bChar);
    }
    if (dart.notNull(b[dartx.length]) > dart.notNull(a[dartx.length])) return -1;
    return defaultResult[dartx.sign];
  }
  dart.fn(compareAsciiLowerCase, core.int, [core.String, core.String]);
  function compareNatural(a, b) {
    for (let i = 0; i < dart.notNull(a[dartx.length]); i++) {
      if (i >= dart.notNull(b[dartx.length])) return 1;
      let aChar = a[dartx.codeUnitAt](i);
      let bChar = b[dartx.codeUnitAt](i);
      if (aChar != bChar) {
        return _compareNaturally(a, b, i, aChar, bChar);
      }
    }
    if (dart.notNull(b[dartx.length]) > dart.notNull(a[dartx.length])) return -1;
    return 0;
  }
  dart.fn(compareNatural, core.int, [core.String, core.String]);
  function compareAsciiLowerCaseNatural(a, b) {
    let defaultResult = 0;
    for (let i = 0; i < dart.notNull(a[dartx.length]); i++) {
      if (i >= dart.notNull(b[dartx.length])) return 1;
      let aChar = a[dartx.codeUnitAt](i);
      let bChar = b[dartx.codeUnitAt](i);
      if (aChar == bChar) continue;
      let aLowerCase = aChar;
      let bLowerCase = bChar;
      if (dart.notNull(_upperCaseA) <= dart.notNull(aChar) && dart.notNull(aChar) <= dart.notNull(_upperCaseZ)) {
        aLowerCase = dart.notNull(aLowerCase) + dart.notNull(_asciiCaseBit);
      }
      if (dart.notNull(_upperCaseA) <= dart.notNull(bChar) && dart.notNull(bChar) <= dart.notNull(_upperCaseZ)) {
        bLowerCase = dart.notNull(bLowerCase) + dart.notNull(_asciiCaseBit);
      }
      if (aLowerCase != bLowerCase) {
        return _compareNaturally(a, b, i, aLowerCase, bLowerCase);
      }
      if (defaultResult == 0) defaultResult = dart.notNull(aChar) - dart.notNull(bChar);
    }
    if (dart.notNull(b[dartx.length]) > dart.notNull(a[dartx.length])) return -1;
    return defaultResult[dartx.sign];
  }
  dart.fn(compareAsciiLowerCaseNatural, core.int, [core.String, core.String]);
  function compareAsciiUpperCaseNatural(a, b) {
    let defaultResult = 0;
    for (let i = 0; i < dart.notNull(a[dartx.length]); i++) {
      if (i >= dart.notNull(b[dartx.length])) return 1;
      let aChar = a[dartx.codeUnitAt](i);
      let bChar = b[dartx.codeUnitAt](i);
      if (aChar == bChar) continue;
      let aUpperCase = aChar;
      let bUpperCase = bChar;
      if (dart.notNull(_lowerCaseA) <= dart.notNull(aChar) && dart.notNull(aChar) <= dart.notNull(_lowerCaseZ)) {
        aUpperCase = dart.notNull(aUpperCase) - dart.notNull(_asciiCaseBit);
      }
      if (dart.notNull(_lowerCaseA) <= dart.notNull(bChar) && dart.notNull(bChar) <= dart.notNull(_lowerCaseZ)) {
        bUpperCase = dart.notNull(bUpperCase) - dart.notNull(_asciiCaseBit);
      }
      if (aUpperCase != bUpperCase) {
        return _compareNaturally(a, b, i, aUpperCase, bUpperCase);
      }
      if (defaultResult == 0) defaultResult = dart.notNull(aChar) - dart.notNull(bChar);
    }
    if (dart.notNull(b[dartx.length]) > dart.notNull(a[dartx.length])) return -1;
    return defaultResult[dartx.sign];
  }
  dart.fn(compareAsciiUpperCaseNatural, core.int, [core.String, core.String]);
  function _compareNaturally(a, b, index, aChar, bChar) {
    dart.assert(aChar != bChar);
    let aIsDigit = _isDigit(aChar);
    let bIsDigit = _isDigit(bChar);
    if (dart.notNull(aIsDigit)) {
      if (dart.notNull(bIsDigit)) {
        return _compareNumerically(a, b, aChar, bChar, index);
      } else if (dart.notNull(index) > 0 && dart.notNull(_isDigit(a[dartx.codeUnitAt](dart.notNull(index) - 1)))) {
        return 1;
      }
    } else if (dart.notNull(bIsDigit) && dart.notNull(index) > 0 && dart.notNull(_isDigit(b[dartx.codeUnitAt](dart.notNull(index) - 1)))) {
      return -1;
    }
    return (dart.notNull(aChar) - dart.notNull(bChar))[dartx.sign];
  }
  dart.fn(_compareNaturally, core.int, [core.String, core.String, core.int, core.int, core.int]);
  function _compareNumerically(a, b, aChar, bChar, index) {
    if (dart.notNull(_isNonZeroNumberSuffix(a, index))) {
      let result = _compareDigitCount(a, b, index, index);
      if (result != 0) return result;
      return (dart.notNull(aChar) - dart.notNull(bChar))[dartx.sign];
    }
    let aIndex = index;
    let bIndex = index;
    if (aChar == _zero) {
      do {
        aIndex = dart.notNull(aIndex) + 1;
        if (aIndex == a[dartx.length]) return -1;
        aChar = a[dartx.codeUnitAt](aIndex);
      } while (aChar == _zero);
      if (!dart.notNull(_isDigit(aChar))) return -1;
    } else if (bChar == _zero) {
      do {
        bIndex = dart.notNull(bIndex) + 1;
        if (bIndex == b[dartx.length]) return 1;
        bChar = b[dartx.codeUnitAt](bIndex);
      } while (bChar == _zero);
      if (!dart.notNull(_isDigit(bChar))) return 1;
    }
    if (aChar != bChar) {
      let result = _compareDigitCount(a, b, aIndex, bIndex);
      if (result != 0) return result;
      return (dart.notNull(aChar) - dart.notNull(bChar))[dartx.sign];
    }
    while (true) {
      let aIsDigit = false;
      let bIsDigit = false;
      aChar = 0;
      bChar = 0;
      if ((aIndex = dart.notNull(aIndex) + 1) < dart.notNull(a[dartx.length])) {
        aChar = a[dartx.codeUnitAt](aIndex);
        aIsDigit = _isDigit(aChar);
      }
      if ((bIndex = dart.notNull(bIndex) + 1) < dart.notNull(b[dartx.length])) {
        bChar = b[dartx.codeUnitAt](bIndex);
        bIsDigit = _isDigit(bChar);
      }
      if (dart.notNull(aIsDigit)) {
        if (dart.notNull(bIsDigit)) {
          if (aChar == bChar) continue;
          break;
        }
        return 1;
      } else if (dart.notNull(bIsDigit)) {
        return -1;
      } else {
        return (dart.notNull(aIndex) - dart.notNull(bIndex))[dartx.sign];
      }
    }
    let result = _compareDigitCount(a, b, aIndex, bIndex);
    if (result != 0) return result;
    return (dart.notNull(aChar) - dart.notNull(bChar))[dartx.sign];
  }
  dart.fn(_compareNumerically, core.int, [core.String, core.String, core.int, core.int, core.int]);
  function _compareDigitCount(a, b, i, j) {
    while ((i = dart.notNull(i) + 1) < dart.notNull(a[dartx.length])) {
      let aIsDigit = _isDigit(a[dartx.codeUnitAt](i));
      if ((j = dart.notNull(j) + 1) == b[dartx.length]) return dart.notNull(aIsDigit) ? 1 : 0;
      let bIsDigit = _isDigit(b[dartx.codeUnitAt](j));
      if (dart.notNull(aIsDigit)) {
        if (dart.notNull(bIsDigit)) continue;
        return 1;
      } else if (dart.notNull(bIsDigit)) {
        return -1;
      } else {
        return 0;
      }
    }
    if ((j = dart.notNull(j) + 1) < dart.notNull(b[dartx.length]) && dart.notNull(_isDigit(b[dartx.codeUnitAt](j)))) {
      return -1;
    }
    return 0;
  }
  dart.fn(_compareDigitCount, core.int, [core.String, core.String, core.int, core.int]);
  function _isDigit(charCode) {
    return (dart.notNull(charCode) ^ dart.notNull(_zero)) <= 9;
  }
  dart.fn(_isDigit, core.bool, [core.int]);
  function _isNonZeroNumberSuffix(string, index) {
    while ((index = dart.notNull(index) - 1) >= 0) {
      let char = string[dartx.codeUnitAt](index);
      if (char != _zero) return _isDigit(char);
    }
    return false;
  }
  dart.fn(_isNonZeroNumberSuffix, core.bool, [core.String, core.int]);
  // Exports:
  exports.equalsIgnoreAsciiCase = equalsIgnoreAsciiCase;
  exports.hashIgnoreAsciiCase = hashIgnoreAsciiCase;
  exports.compareAsciiUpperCase = compareAsciiUpperCase;
  exports.compareAsciiLowerCase = compareAsciiLowerCase;
  exports.compareNatural = compareNatural;
  exports.compareAsciiLowerCaseNatural = compareAsciiLowerCaseNatural;
  exports.compareAsciiUpperCaseNatural = compareAsciiUpperCaseNatural;
});
