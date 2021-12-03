// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--use_slow_path --deterministic

// Reduced from:
// The Dart Project Fuzz Tester (1.91).
// Program generated as:
//   dart dartfuzz.dart --seed 1339276199 --no-fp --no-ffi --no-flat
// @dart=2.14

import 'dart:collection';
import 'dart:typed_data';

MapEntry<Map<bool, int>, List<String>>? var0 =
    MapEntry<Map<bool, int>, List<String>>(
        <bool, int>{true: -32, true: 47, false: -11, false: 9, false: -69},
        <String>['n', 'Rz!4\u2665']);
Uint8List? var9 = Uint8List.fromList(Uint64List.fromList(
    Int64List.fromList(Int16List.fromList(Int16List.fromList(Uint8List(38))))));
Uint8ClampedList var10 = Uint8ClampedList.fromList(
    Int32List.fromList(Uint64List.fromList(<int>[-27, -74])));
Uint8ClampedList? var11 = Uint8ClampedList(31);
Int16List var12 = Int16List(5);
Int16List? var13 = Int16List(44);
Uint16List var14 = Uint16List.fromList(<int>[-96, 24, -43, -9]);
Uint16List? var15 = Uint16List.fromList(Int8List.fromList(Int32List(34)));
Int32List var16 = Int32List(7);
Int32List? var17 =
    Int32List.fromList(<int>[-67, if (false) -98 else -36, -4294967295]);
Uint32List var18 = Uint32List(28);
Uint32List? var19 = Uint32List(18);
Int64List var20 = Int64List.fromList(Uint64List.fromList(Uint16List(47)));
Int64List? var21 = Int64List(1);
Uint64List var22 = Uint64List(49);
Uint64List? var23 = Uint64List(43);
Int32x4List var24 = Int32x4List(45);
Int32x4List? var25 = Int32x4List(46);
Int32x4 var26 = Int32x4(46, 24, 23, 15);
Int32x4? var27 = Int32x4(20, 28, 20, 2);
Deprecated var28 = Deprecated('G-Ki');
Deprecated? var29 = Deprecated('#Ww');
Provisional var30 = Provisional();
Provisional? var31 = Provisional();
bool var32 = bool.fromEnvironment('');
bool? var33 = bool.hasEnvironment('P9LY');
Duration var34 = Duration();
Duration? var35 = Duration();
Error var36 = Error();
Error? var37 = Error();
AssertionError var38 = AssertionError(17);
AssertionError? var39 = AssertionError(8);
TypeError var40 = TypeError();
TypeError? var41 = TypeError();
CastError var42 = CastError();
CastError? var43 = new CastError();
NullThrownError var44 = NullThrownError();
NullThrownError? var45 = new NullThrownError();
ArgumentError var46 = ArgumentError.value(22, 'K90\u{1f600}QtS', 33);
ArgumentError? var47 = ArgumentError.notNull(')');
RangeError var48 = RangeError.range(2, 23, 36, 'H', 'w&');
RangeError? var49 = new RangeError(22);
IndexError var50 = IndexError(15, 14, 'ZuC', '#1z9xJ', 1);
IndexError? var51 = IndexError(14, 36, 'V(', '9Jf!0\u2665', 2);
FallThroughError var52 = FallThroughError();
FallThroughError? var53 = FallThroughError();
AbstractClassInstantiationError var54 = AbstractClassInstantiationError('J!');
AbstractClassInstantiationError? var55 =
    AbstractClassInstantiationError('L48ynpV');
UnsupportedError var56 = UnsupportedError('5txzg');
UnsupportedError? var57 = UnsupportedError('W4vVdfv');
UnimplementedError var58 = UnimplementedError('pK00TI\u2665');
UnimplementedError? var59 = UnimplementedError('J(teto2');
StateError var60 = StateError('L\u2665');
StateError? var61 = StateError('e\u2665mykMK');
ConcurrentModificationError var62 = new ConcurrentModificationError(22);
ConcurrentModificationError? var63 = ConcurrentModificationError(7);
StackOverflowError var64 = StackOverflowError();
StackOverflowError? var65 = new StackOverflowError();
CyclicInitializationError var66 = CyclicInitializationError('\u{1f600}');
CyclicInitializationError? var67 = CyclicInitializationError('C');
Exception var68 = Exception(14);
Exception? var69 = Exception(40);
FormatException var70 = FormatException('\u{1f600}lv32', 21, 28);
FormatException? var71 = FormatException('e', 19, 12);
IntegerDivisionByZeroException var72 = IntegerDivisionByZeroException();
IntegerDivisionByZeroException? var73 = IntegerDivisionByZeroException();
int var74 = 40;
int? var75 = -44;
Null var76 = null;
Null? var77 = null;
num var78 = 42;
num? var79 = -85;
RegExp var80 = new RegExp('M5O');
RegExp? var81 = RegExp('Fs2');
String var82 = 'W6';
String? var83 = 'h';
Runes var84 = Runes('+');
Runes? var85 = Runes('');
RuneIterator var86 = RuneIterator('\u2665w');
RuneIterator? var87 = new RuneIterator('iNEK\u{1f600}');
StringBuffer var88 = StringBuffer(47);
StringBuffer? var89 = StringBuffer(5);
Symbol var90 = new Symbol('q\u{1f600}');
Symbol? var91 = new Symbol('&j5');
Expando<bool> var92 = Expando<bool>(' ');
Expando<bool>? var93 = Expando<bool>('f5B');
Expando<int> var94 = Expando<int>('');
Expando<int>? var95 = Expando<int>('\u{1f600}1AwU\u2665C');
Expando<String> var96 = Expando<String>('Xzj(d');
Expando<String>? var97 = Expando<String>('Ulsd');
List<bool> var98 = <bool>[false, false, false];
List<bool>? var99 = <bool>[false, false, false, true];
List<int> var100 = Uint8ClampedList(17);
List<int>? var101 = Uint8ClampedList(40);
List<String> var102 = <String>['Y h', 'f', '\u{1f600}ip dQ', ')p', '2Qo'];
List<String>? var103 = <String>[
  'BQ(6-',
  '\u{1f600}6\u2665yJaC',
  '3wa',
  'VJ',
  'k',
  ''
];
Set<bool> var104 = <bool>{false, true, false};
Set<bool>? var105 = <bool>{false, true, false, true, false, false};
Set<int> var106 = <int>{44, 11};
Set<int>? var107 = <int>{if (false) -94, 35};
Set<String> var108 = <String>{''};
Set<String>? var109 = <String>{'4'};
Map<bool, bool> var110 = <bool, bool>{
  false: true,
  false: true,
  false: true,
  true: false
};
Map<bool, bool>? var111 = <bool, bool>{
  false: false,
  true: false,
  false: false,
  true: false
};
Map<bool, int> var112 = <bool, int>{
  true: 35,
  true: -4,
  true: -14,
  false: 30,
  false: -25
};
Map<bool, int>? var113 = null;
Map<bool, String> var114 = <bool, String>{
  false: '7d',
  false: '\u{1f600}sv+',
  false: 'aY',
  false: 'dt'
};
Map<bool, String>? var115 = <bool, String>{
  false: '',
  false: '(G7\u{1f600}TBN',
  true: '',
  true: 'zZ-\u{1f600}\u2665)X',
  false: ')-9',
  false: ''
};
Map<int, bool> var116 = <int, bool>{
  3: true,
  10: true,
  -59: true,
  15: false,
  -36: true
};
Map<int, bool>? var117 = <int, bool>{16: false, 0: false};
Map<int, int> var118 = <int, int>{
  -92: 29,
  -12: 40,
  -29: -26,
  -21: 1,
  13: 28,
  28: -44
};
Map<int, int>? var119 = <int, int>{-54: -37};
Map<int, String> var120 = <int, String>{-80: '', -62: 'h', 40: 'C\u2665FVU'};
Map<int, String>? var121 = <int, String>{
  ...<int, String>{
    -8: 'S\u{1f600}kjRb',
    23: '4',
    -9223372034707292160: '',
    28: 'uz',
    -69: '@'
  },
  -53: 'nU6f',
  -5: '',
  -9223372034707292159: '',
  20: 'h7EB+'
};
Map<String, bool> var122 = <String, bool>{'8+G': false};
Map<String, bool>? var123 = <String, bool>{'rM9m6k': true, '2': true};
Map<String, int> var124 = <String, int>{'Z+p@\u2665Ww': -55};
Map<String, int>? var125 = <String, int>{'9': -2147483647, 'uQ': 40};
Map<String, String> var126 = <String, String>{
  'Q!': ' V\u{1f600}A2\u{1f600}',
  'z': '\u2665)',
  'cM@7\u{1f600}': 'XUT',
  'oLoh': 'bLPrZ',
  'YmR67nj': 'BdeuR'
};
Map<String, String>? var127 = <String, String>{'nOsSM1': '3 @yIj'};
MapEntry<bool, bool> var128 = MapEntry<bool, bool>(true, false);
MapEntry<bool, bool>? var129 = MapEntry<bool, bool>(true, false);
MapEntry<bool, int> var130 = MapEntry<bool, int>(false, 13);
MapEntry<bool, int>? var131 = MapEntry<bool, int>(true, 31);
MapEntry<bool, String> var132 =
    MapEntry<bool, String>(true, '\u26653KE\u{1f600}');
MapEntry<bool, String>? var133 = MapEntry<bool, String>(false, 'd');
MapEntry<int, bool> var134 = MapEntry<int, bool>(46, true);
MapEntry<int, bool>? var135 = MapEntry<int, bool>(34, false);
MapEntry<int, int> var136 = MapEntry<int, int>(22, 30);
MapEntry<int, int>? var137 = MapEntry<int, int>(30, 48);
MapEntry<int, String> var138 = MapEntry<int, String>(46, 'by#@-nv');
MapEntry<int, String>? var139 = MapEntry<int, String>(49, 'N@KF');
MapEntry<String, bool> var140 =
    MapEntry<String, bool>('\u{1f600}km\u2665', true);
MapEntry<String, bool>? var141 = new MapEntry<String, bool>('7PZX', false);
MapEntry<String, int> var142 = new MapEntry<String, int>('OE', 27);

Map<String, Map<String, bool>> var446 = <String, Map<String, bool>>{
  'YJ\u{1f600}': <String, bool>{'BcKzE': true, 'Cz1A+n': false, '': true},
  'u!KEz9I': <String, bool>{
    '\u26653Hjr': true,
    '-\u{1f600}': true,
    '': true,
    ')-': false,
    'ygN': true
  },
  '+R6': <String, bool>{'ta\u2665dKu)': true, 'rao9j': true},
  'YGXS!': <String, bool>{
    '': false,
    '6R': false,
    '': true,
    'MV\u{1f600} PP': true
  }
};
Map<MapEntry<String, int>, Map<int, bool>> var2000 =
    <MapEntry<String, int>, Map<int, bool>>{
  new MapEntry<String, int>('', 7): <int, bool>{
    -55: true,
    4294967295: false,
    48: true,
    -1: true,
    -96: false
  },
  MapEntry<String, int>('ORLVr', 1): <int, bool>{
    -21: false,
    4294967297: false,
    -12: false,
    -84: false
  }
};

void foo1_Extension0() {
  var446.forEach((loc0, loc1) {
    for (int loc2 = 0; loc2 < 34; loc2++) {
      print(<MapEntry<bool, bool>, String>{
        MapEntry<bool, bool>(true, false): 'pqKqb',
        MapEntry<bool, bool>(true, true): 'Fkx',
        MapEntry<bool, bool>(true, false): '',
        MapEntry<bool, bool>(false, true): 'fJvVWOW',
        MapEntry<bool, bool>(false, true): 'q\u2665NR',
        MapEntry<bool, bool>(false, true): '\u2665'
      });
      var2000.forEach((loc3, loc4) {
        print(MapEntry<Map<bool, String>, MapEntry<int, bool>>(
            <bool, String>{false: 'L'}, MapEntry<int, bool>(42, false)));
      });
    }
  });
}

main() {
  foo1_Extension0();

  print(
      '$var0\n$var9\n$var11\n$var12\n$var13\n$var14\n$var15\n$var16\n$var17\n$var18\n$var19\n$var20\n$var21\n$var22\n$var23\n$var24\n$var25\n$var26\n$var27\n$var28\n$var29\n$var30\n$var31\n$var32\n$var33\n$var34\n$var35\n$var36\n$var37\n$var38\n$var39\n$var40\n$var41\n$var42\n$var43\n$var44\n$var45\n$var46\n$var47\n$var48\n$var49\n$var50\n$var51\n$var52\n$var53\n$var54\n$var55\n$var56\n$var57\n$var58\n$var59\n$var60\n$var61\n$var62\n$var63\n$var64\n$var65\n$var66\n$var67\n$var68\n$var69\n$var70\n$var71\n$var72\n$var73\n$var74\n$var75\n$var76\n$var77\n$var78\n$var79\n$var80\n$var81\n$var82\n$var83\n$var84\n$var85\n$var86\n$var87\n$var88\n$var89\n$var90\n$var91\n$var92\n$var93\n$var94\n$var95\n$var96\n$var97\n$var98\n$var99\n$var100\n$var101\n$var102\n$var103\n$var104\n$var105\n$var106\n$var107\n$var108\n$var109\n$var110\n$var111\n$var112\n$var113\n$var114\n$var115\n$var116\n$var117\n$var118\n$var119\n$var120\n$var121\n$var122\n$var123\n$var124\n$var125\n$var126\n$var127\n$var128\n$var129\n$var130\n$var131\n$var132\n');
}
