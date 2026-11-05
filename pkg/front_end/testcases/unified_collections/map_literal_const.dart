// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const Map<int, String>? nullableIntMap1 = <int, String>{0: '0', 1: '1', 2: '2'};
const Map<int, String>? nullableIntMap2 = null;
const List<int> intList = <int>[3, 4, 5];
const Map<int, String> intMap = <int, String>{6: '6', 7: '7', 8: '8'};
const Map<num, String> numMap = <num, String>{9: '9', 10: '10', 11: '11'};
const List<(int, int)> intIntList = <(int, int)>[(12, 13), (14, 15)];

const num? nullableNum1 = 16;
const num? nullableNum2 = null;
const num? nullableNum3 = 17;
const String? nullableString1 = '18';
const String? nullableString2 = null;

main() {
  const bool b1 = true;
  const bool b2 = false;
  const <num, String>{
    19: '19',
    ?nullableNum1: '20',
    ?nullableNum2: '21',
    22: ?nullableString1,
    23: ?nullableString2,
    ?nullableNum3: ?nullableString2,
    ?nullableNum2: ?nullableString1,
    if (b1) 24: '24',
    if (b2) 25: '25' else 26: '26',
    // TODO(johnniwinther): Support these:
    // if (intList case [var a, ...]) a: '$a',
    // if (intList case [_, var b, ...]) b: '$b' else 27: '27',
    ...intMap,
    ...numMap,
    ...?nullableIntMap1,
    ...?nullableIntMap2,
  };
}
