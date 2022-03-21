// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:path/path.dart' as package_path;

class MacroClass {
  final String name;
  final List<String> constructors;

  MacroClass({
    required this.name,
    required this.constructors,
  });
}

abstract class MacroFileEntry {
  String get content;

  /// When CFE searches for `package_config.json` we need to check this.
  bool get exists;
}

abstract class MacroFileSystem {
  /// Used to convert `file:` URIs into paths.
  package_path.Context get pathContext;

  MacroFileEntry getFile(String path);
}

abstract class MacroKernelBuilder {
  Uint8List build({
    required MacroFileSystem fileSystem,
    required List<MacroLibrary> libraries,
  });
}

class MacroLibrary {
  final Uri uri;
  final String path;
  final List<MacroClass> classes;

  MacroLibrary({
    required this.uri,
    required this.path,
    required this.classes,
  });
}
