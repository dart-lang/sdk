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
  static const interestingChars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#&()+- ';

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
/// The invididual lists are organized by return type.
/// Proto list:
///   [ receiver-type (null denotes none),
///     param1 type (null denotes getter),
///     param2 type,
///     ...
///   ]
///
/// TODO(ajcbik): generate these lists automatically
///
class DartLib {
  final String name;
  final List<DartType> proto;
  const DartLib(this.name, this.proto);

  static const boolLibs = [
    DartLib('isEven', [DartType.INT, null]),
    DartLib('isOdd', [DartType.INT, null]),
    DartLib('isEmpty', [DartType.STRING, null]),
    DartLib('isEmpty', [DartType.INT_STRING_MAP, null]),
    DartLib('isNotEmpty', [DartType.STRING, null]),
    DartLib('isNotEmpty', [DartType.INT_STRING_MAP, null]),
    DartLib('endsWith', [DartType.STRING, DartType.STRING]),
    DartLib('remove', [DartType.INT_LIST, DartType.INT]),
    DartLib('containsValue', [DartType.INT_STRING_MAP, DartType.STRING]),
    DartLib('containsKey', [DartType.INT_STRING_MAP, DartType.INT]),
  ];

  static const intLibs = [
    DartLib('bitLength', [DartType.INT, null]),
    DartLib('sign', [DartType.INT, null]),
    DartLib('abs', [DartType.INT]),
    DartLib('round', [DartType.INT]),
    DartLib('round', [DartType.DOUBLE]),
    DartLib('floor', [DartType.INT]),
    DartLib('floor', [DartType.DOUBLE]),
    DartLib('ceil', [DartType.INT]),
    DartLib('ceil', [DartType.DOUBLE]),
    DartLib('truncate', [DartType.INT]),
    DartLib('truncate', [DartType.DOUBLE]),
    DartLib('toInt', [DartType.DOUBLE]),
    DartLib('toUnsigned', [DartType.INT, DartType.INT]),
    DartLib('toSigned', [DartType.INT, DartType.INT]),
    DartLib('modInverse', [DartType.INT, DartType.INT]),
    DartLib('modPow', [DartType.INT, DartType.INT, DartType.INT]),
    DartLib('length', [DartType.STRING, null]),
    DartLib('length', [DartType.INT_LIST, null]),
    DartLib('length', [DartType.INT_STRING_MAP, null]),
    DartLib('codeUnitAt', [DartType.STRING, DartType.INT]),
    DartLib('compareTo', [DartType.STRING, DartType.STRING]),
    DartLib('removeLast', [DartType.INT_LIST]),
    DartLib('removeAt', [DartType.INT_LIST, DartType.INT]),
    DartLib('indexOf', [DartType.INT_LIST, DartType.INT]),
    DartLib('lastIndexOf', [DartType.INT_LIST, DartType.INT]),
  ];

  static const doubleLibs = [
    DartLib('sign', [DartType.DOUBLE, null]),
    DartLib('abs', [DartType.DOUBLE]),
    DartLib('toDouble', [DartType.INT]),
    DartLib('roundToDouble', [DartType.INT]),
    DartLib('roundToDouble', [DartType.DOUBLE]),
    DartLib('floorToDouble', [DartType.INT]),
    DartLib('floorToDouble', [DartType.DOUBLE]),
    DartLib('ceilToDouble', [DartType.INT]),
    DartLib('ceilToDouble', [DartType.DOUBLE]),
    DartLib('truncateToDouble', [DartType.INT]),
    DartLib('truncateToDouble', [DartType.DOUBLE]),
    DartLib('remainder', [DartType.DOUBLE, DartType.DOUBLE]),
  ];

  static const stringLibs = [
    DartLib('toString', [DartType.BOOL]),
    DartLib('toString', [DartType.INT]),
    DartLib('toString', [DartType.DOUBLE]),
    DartLib('toRadixString', [DartType.INT, DartType.INT]),
    DartLib('trim', [DartType.STRING]),
    DartLib('trimLeft', [DartType.STRING]),
    DartLib('trimRight', [DartType.STRING]),
    DartLib('toLowerCase', [DartType.STRING]),
    DartLib('toUpperCase', [DartType.STRING]),
    DartLib('substring', [DartType.STRING, DartType.INT]),
    DartLib('replaceRange',
        [DartType.STRING, DartType.INT, DartType.INT, DartType.STRING]),
    DartLib('remove', [DartType.INT_STRING_MAP, DartType.INT]),
    // Avoid (OOM divergences, TODO(ajcbik): restrict parameters)
    // DartLib('padLeft', [DartType.STRING, DartType.INT]),
    // DartLib('padRight', [DartType.STRING, DartType.INT]),
  ];

  static const intListLibs = [
    DartLib('sublist', [DartType.INT_LIST, DartType.INT])
  ];
}
