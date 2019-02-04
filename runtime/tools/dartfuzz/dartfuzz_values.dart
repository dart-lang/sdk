// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Class that represents some common Dart types.
///
/// TODO(ajcbik): generalize
///
class DartType {
  final String name;

  const DartType._withName(this.name);

  static const VOID = const DartType._withName('void');
  static const BOOL = const DartType._withName('bool');
  static const INT = const DartType._withName('int');
  static const DOUBLE = const DartType._withName('double');
  static const STRING = const DartType._withName('String');
  static const INT_LIST = const DartType._withName('List<int>');
  static const INT_STRING_MAP = const DartType._withName('Map<int, String>');

  // All value types.
  static const allTypes = [BOOL, INT, DOUBLE, STRING, INT_LIST, INT_STRING_MAP];
}

/// Class with interesting values for fuzzing.
class DartFuzzValues {
  // Interesting characters.
  static const List<String> interestingChars = [
    '\\u2665',
    '\\u{1f600}', // rune
  ];

  // Regular characters.
  static const regularChars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#&()+- ';

  // Interesting doubles.
  static const interestingDoubles = [
    'double.infinity',
    'double.maxFinite',
    'double.minPositive',
    'double.nan',
    'double.negativeInfinity',
  ];

  // Interesting integer values.
  static const List<int> interestingIntegers = [
    0x0000000000000000,
    0x0000000000000001,
    0x000000007fffffff,
    0x0000000080000000,
    0x0000000080000001,
    0x00000000ffffffff,
    0x0000000100000000,
    0x0000000100000001,
    0x000000017fffffff,
    0x0000000180000000,
    0x0000000180000001,
    0x00000001ffffffff,
    0x7fffffff00000000,
    0x7fffffff00000001,
    0x7fffffff7fffffff,
    0x7fffffff80000000,
    0x7fffffff80000001,
    0x7fffffffffffffff,
    0x8000000000000000,
    0x8000000000000001,
    0x800000007fffffff,
    0x8000000080000000,
    0x8000000080000001,
    0x80000000ffffffff,
    0x8000000100000000,
    0x8000000100000001,
    0x800000017fffffff,
    0x8000000180000000,
    0x8000000180000001,
    0x80000001ffffffff,
    0xffffffff00000000,
    0xffffffff00000001,
    0xffffffff7fffffff,
    0xffffffff80000000,
    0xffffffff80000001,
    0xffffffffffffffff
  ];
}

/// Class that represents Dart library methods.
//
/// The invididual lists are organized by return type.
/// The proto string has the following format:
///    +-------> receiver type (V denotes none)
///    |+------> param1 type  (V denotes none, v denotes getter)
///    ||+-----> param2 type
///    |||+----> ....
///    ||||
///   "TTTT...."
/// where:
///   V void
///   v void (special)
///   B bool
///   I int
///   i int (small)
///   D double
///   S String
///   L List<int>
///   M Map<int, String>
///
/// TODO(ajcbik): generate these lists automatically
///
class DartLib {
  final String name;
  final String proto;
  const DartLib(this.name, this.proto);

  static const boolLibs = [
    DartLib('isEven', "Iv"),
    DartLib('isOdd', "Iv"),
    DartLib('isEmpty', "Sv"),
    DartLib('isEmpty', "Mv"),
    DartLib('isNotEmpty', "Sv"),
    DartLib('isNotEmpty', "Mv"),
    DartLib('endsWith', "SS"),
    DartLib('remove', "LI"),
    DartLib('containsValue', "MS"),
    DartLib('containsKey', "MI"),
  ];

  static const intLibs = [
    DartLib('bitLength', "Iv"),
    DartLib('sign', "Iv"),
    DartLib('abs', "IV"),
    DartLib('round', "IV"),
    DartLib('round', "DV"),
    DartLib('floor', "IV"),
    DartLib('floor', "DV"),
    DartLib('ceil', "IV"),
    DartLib('ceil', "DV"),
    DartLib('truncate', "IV"),
    DartLib('truncate', "DV"),
    DartLib('toInt', "DV"),
    DartLib('toUnsigned', "II"),
    DartLib('toSigned', "II"),
    DartLib('modInverse', "II"),
    DartLib('modPow', "III"),
    DartLib('length', "Sv"),
    DartLib('length', "Lv"),
    DartLib('length', "Mv"),
    DartLib('codeUnitAt', "SI"),
    DartLib('compareTo', "SS"),
    DartLib('removeLast', "LV"),
    DartLib('removeAt', "LI"),
    DartLib('indexOf', "LI"),
    DartLib('lastIndexOf', "LI"),
  ];

  static const doubleLibs = [
    DartLib('sign', "Dv"),
    DartLib('abs', "DV"),
    DartLib('toDouble', "IV"),
    DartLib('roundToDouble', "IV"),
    DartLib('roundToDouble', "DV"),
    DartLib('floorToDouble', "IV"),
    DartLib('floorToDouble', "DV"),
    DartLib('ceilToDouble', "IV"),
    DartLib('ceilToDouble', "DV"),
    DartLib('truncateToDouble', "IV"),
    DartLib('truncateToDouble', "DV"),
    DartLib('remainder', "DD"),
  ];

  static const stringLibs = [
    DartLib('toString', "BV"),
    DartLib('toString', "IV"),
    DartLib('toString', "DV"),
    DartLib('toRadixString', "II"),
    DartLib('trim', "SV"),
    DartLib('trimLeft', "SV"),
    DartLib('trimRight', "SV"),
    DartLib('toLowerCase', "SV"),
    DartLib('toUpperCase', "SV"),
    DartLib('substring', "SI"),
    DartLib('replaceRange', "SIIS"),
    DartLib('remove', "MI"),
    DartLib('padLeft', "Si"), // restrict!
    DartLib('padRight', "Si"), // restrict!
  ];

  static const intListLibs = [
    DartLib('sublist', "LI"),
  ];

  static const intStringMapLibs = [
    DartLib('Map.from', "VM"),
  ];
}
