// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Helper functions for parsing output of `--print-instructions-sizes-to` flag.
library vm.snapshot.instruction_sizes;

import 'dart:convert';
import 'dart:io';

import 'package:vm/snapshot/name.dart';
import 'package:vm/snapshot/program_info.dart';

/// Parse the output of `--print-instructions-sizes-to` saved in the given
/// file [input].
Future<List<SymbolInfo>> load(File input) async {
  final List<dynamic> symbolsArray = await input
      .openRead()
      .transform(utf8.decoder)
      .transform(json.decoder)
      .first;
  return symbolsArray
      .cast<Map<String, dynamic>>()
      .map(SymbolInfo._fromJson)
      .toList(growable: false);
}

/// Parse the output of `--print-instructions-sizes-to` saved in the given
/// file [input] into [ProgramInfo<int>] structure representing the sizes
/// of individual functions.
///
/// If [collapseAnonymousClosures] is set to [true] then all anonymous closures
/// within the same scopes are collapsed together. Collapsing closures is
/// helpful when comparing symbol sizes between two versions of the same
/// program because in general there is no reliable way to recognize the same
/// anonymous closures into two independent compilations.
Future<ProgramInfo<int>> loadProgramInfo(File input,
    {bool collapseAnonymousClosures = false}) async {
  final symbols = await load(input);
  return toProgramInfo(symbols,
      collapseAnonymousClosures: collapseAnonymousClosures);
}

/// Information about the size of the instruction object.
class SymbolInfo {
  /// Name of the code object (`Code::QualifiedName`) owning these instructions.
  final Name name;

  /// If this instructions object originated from a function then [libraryUri]
  /// will contain uri of the library of that function.
  final String libraryUri;

  /// If this instructions object originated from a function then [className]
  /// would contain name of the class owning that function.
  final String className;

  /// Size of the instructions object in bytes.
  final int size;

  SymbolInfo({String name, this.libraryUri, this.className, this.size})
      : name = Name(name);

  static SymbolInfo _fromJson(Map<String, dynamic> map) {
    return SymbolInfo(
        libraryUri: map['l'],
        className: map['c'],
        name: map['n'],
        size: map['s']);
  }
}

/// Restore hierarchical [ProgramInfo<int>] representation from the list of
/// symbols by parsing function names.
///
/// If [collapseAnonymousClosures] is set to [true] then all anonymous closures
/// within the same scopes are collapsed together. Collapsing closures is
/// helpful when comparing symbol sizes between two versions of the same
/// program because in general there is no reliable way to recognize the same
/// anonymous closures into two independent compilations.
ProgramInfo<int> toProgramInfo(List<SymbolInfo> symbols,
    {bool collapseAnonymousClosures = false}) {
  final program = ProgramInfo<int>();
  for (var sym in symbols) {
    final scrubbed = sym.name.scrubbed;
    if (sym.libraryUri == null) {
      assert(sym.name.isStub);
      assert(
          !program.stubs.containsKey(scrubbed) || sym.name.isTypeTestingStub);
      program.stubs[scrubbed] = (program.stubs[scrubbed] ?? 0) + sym.size;
    } else {
      // Split the name into components (names of individual functions).
      final path = sym.name.components;

      final lib =
          program.libraries.putIfAbsent(sym.libraryUri, () => LibraryInfo());
      final cls = lib.classes.putIfAbsent(sym.className, () => ClassInfo());
      var fun = cls.functions.putIfAbsent(path.first, () => FunctionInfo());
      for (var name in path.skip(1)) {
        if (collapseAnonymousClosures &&
            name.startsWith('<anonymous closure @')) {
          name = '<anonymous closure>';
        }
        fun = fun.closures.putIfAbsent(name, () => FunctionInfo());
      }
      fun.info = (fun.info ?? 0) + sym.size;
    }
  }

  return program;
}
