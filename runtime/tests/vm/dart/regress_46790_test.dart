// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// VMOptions=--stacktrace_every=137 --deterministic

// Reduced from
// The Dart Project Fuzz Tester (1.91).
// Program generated as:
//   dart dartfuzz.dart --seed 2528999334 --no-fp --no-ffi --no-flat

int var73 = -9223372034707292159;
String var81 = 'E4yq0';
Map<Expando<int>, int> var531 = <Expando<int>,int>{
  Expando<int>('NX') : 2147483648,
  Expando<int>('Gy') : 0,
  Expando<int>('DDp670v') : 40,
  Expando<int>('zS(') : -9223372036854775807
};
Map<Map<bool, int>, Expando<int>> var1077 = <Map<bool, int>,Expando<int>>{
  <bool,int>{
    true : -74,
    false : -65,
    true : 7
  } : Expando<int>('cteN2')
};
Map<MapEntry<int, int>, int> var1791 = <MapEntry<int, int>,int>{
  MapEntry<int, int>(31, 45) : 13,
  MapEntry<int, int>(10, 37) : 43
};
Map<MapEntry<String, bool>, int> var1911 = <MapEntry<String, bool>,int>{
  MapEntry<String, bool>('uD', false) : 47,
  MapEntry<String, bool>('LdL', false) : -11,
  MapEntry<String, bool>('RO(9', false) : -92,
  MapEntry<String, bool>('', true) : -9223372032559808513,
  MapEntry<String, bool>('F6eH', false) : -9223372032559808512,
  MapEntry<String, bool>('d', false) : -39
};
Map<MapEntry<String, int>, int>? var1972 = null;
Map<MapEntry<String, String>, MapEntry<int, bool>> var2077 = <MapEntry<String, String>,MapEntry<int, bool>>{
  MapEntry<String, String>('M', '') : MapEntry<int, bool>(1, true),
  new MapEntry<String, String>('n8)mj', '') : MapEntry<int, bool>(24, true),
  MapEntry<String, String>('', 'q9KjW') : MapEntry<int, bool>(21, false),
  MapEntry<String, String>('C', 'k5x') : new MapEntry<int, bool>(21, false)
};
MapEntry<Expando<bool>, Map<String, bool>> var2287 = MapEntry<Expando<bool>, Map<String, bool>>(Expando<bool>('5E\u{1f600}\u2665'), <String,bool>{
  'w\u266537L' : true,
  'Rfu' : false,
  ')JI+q&' : true,
  'Z)@a\u2665V' : true,
  '3+3WP' : true
});
MapEntry<Map<bool, String>, Expando<bool>>? var2918 = MapEntry<Map<bool, String>, Expando<bool>>(<bool,String>{
  true : '3rVO( ',
  true : '+9psp57'
}, Expando<bool>('d'));
MapEntry<Map<int, bool>, Map<int, String>>? var3006 = MapEntry<Map<int, bool>, Map<int, String>>(<int,bool>{
  18 : false,
  -32 : true,
  -32 : false,
  31 : false,
  -50 : false
}, <int,String>{
  -37 : '',
  12 : 'viG4s',
  4294967297 : '\u2665YGL12',
  11 : 'G',
  31 : 'hdQ',
  -2147483649 : 'JMsv'
});

MapEntry<MapEntry<bool, int>, Map<String, int>>? var3430 = MapEntry<MapEntry<bool, int>, Map<String, int>>(MapEntry<bool, int>(true, 29), <String,int>{
  'k' : -31,
  '' : 0,
  '\u{1f600}u3IJ ' : 12,
  '' : -89,
  'G&5' : 39
});

class X0 {
  Map<MapEntry<String, int>, int>? foo0_1(int par1){
    if (par1 >= 49) {
      return var1972;
    }

    {
      int loc0 = 0;
      do {
        var2077.forEach((loc1, loc2){});
      } while (++loc0 < 41);
    }

    for (int loc0 = 0; loc0 < 49; loc0++) {
      try {
        var3430 = MapEntry<MapEntry<bool, int>, Map<String, int>>(MapEntry<bool, int>(true, 11), <String,int>{
          'tocS' : (true ? var73 : var1911[MapEntry<String, bool>('CZ\u2665G4Ra', true)]!),
          '\u{1f600}UnA#' : var531[var1077[const <bool,int>{
            false : -73
          }]!]!,
        });
      } catch (exception, stackTrace) {
        var3006 = var3006;
        var2918 = var2918;
      }

      var1791.forEach((loc2, loc3){});
    }

    return foo0_1(par1 + 1);
  }
}


main() {
  try {
    X0().foo0_1(0);
  } catch (e, st) {
    print('X0().foo0_1 throws');
  }
}
