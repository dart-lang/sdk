// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Helper functions for parsing output of `--print-instructions-sizes-to` flag.
library vm.snapshot.instruction_sizes;

import 'dart:convert';
import 'dart:io';

import 'package:vm/snapshot/name.dart';

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
