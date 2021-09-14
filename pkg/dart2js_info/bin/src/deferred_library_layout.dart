// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This tool reports how code is divided among deferred chunks.
library dart2js_info.bin.deferred_library_layout;

import 'dart:io';

import 'package:args/command_runner.dart';

import 'package:dart2js_info/info.dart';
import 'package:dart2js_info/src/io.dart';

import 'usage_exception.dart';

/// This tool reports how code is divided among deferred chunks.
class DeferredLibraryLayout extends Command<void> with PrintUsageException {
  final String name = "deferred_layout";
  final String description = "Show how code is divided among deferred parts.";

  void run() async {
    var args = argResults.rest;
    if (args.length < 1) {
      usageException('Missing argument: info.data');
    }
    await _showLayout(args.first);
  }
}

_showLayout(String file) async {
  AllInfo info = await infoFromFile(file);

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
