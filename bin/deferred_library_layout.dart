// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This tool reports how code is divided among deferred chunks.
library dart2js_info.bin.deferred_library_size;

import 'dart:io';

import 'package:dart2js_info/info.dart';
import 'package:dart2js_info/src/util.dart';

main(args) async {
  AllInfo info = await infoFromFile(args.first);

  Map<OutputUnitInfo, Map<LibraryInfo, List<BasicInfo>>> hunkMembers = {};
  Map<LibraryInfo, Set<OutputUnitInfo>> libToHunks = {};
  void register(BasicInfo info) {
    var unit = info.outputUnit;
    var lib = _libOf(info);
    if (lib == null) return;
    libToHunks.putIfAbsent(lib, () => new Set()).add(unit);
    hunkMembers
        .putIfAbsent(unit, () => {})
        .putIfAbsent(lib, () => [])
        .add(info);
  }

  info.functions.forEach(register);
  info.classes.forEach(register);
  info.fields.forEach(register);
  info.closures.forEach(register);

  var dir = Directory.current.path;
  hunkMembers.forEach((unit, map) {
    print('Output unit ${unit.name ?? "main"}:');
    if (unit.name == null || unit.name == 'main') {
      print('  loaded by default');
    } else {
      print('  loaded by importing: ${unit.imports}');
    }

    print('  contains:');
    map.forEach((lib, elements) {
      var uri = lib.uri;
      var shortUri = (uri.scheme == 'file' && uri.path.startsWith(dir))
          ? uri.path.substring(dir.length + 1)
          : '$uri';

      // If the entire library is in one chunk, just report the library name
      // otherwise report which functions are on this chunk.
      if (libToHunks[lib].length == 1) {
        print('     - $shortUri');
      } else {
        print('     - $shortUri:');
        for (var e in elements) {
          print('       - ${kindToString(e.kind)} ${e.name}');
        }
      }
    });
    print('');
  });
}

_libOf(e) => e is LibraryInfo || e == null ? e : _libOf(e.parent);
