// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:kernel/ast.dart';
import 'package:kernel/kernel.dart';

import 'fasta/kernel/utils.dart';
import 'macro_serializer.dart';

/// [MacroSerializer] that uses .dill files stored in a temporary directory to
/// provided [Uri]s for precompiled macro [Component]s.
///
/// This can be used other with the isolate and process based macro executors.
class TempDirMacroSerializer implements MacroSerializer {
  final String? name;
  Directory? tempDirectory;
  int precompiledCount = 0;

  TempDirMacroSerializer([this.name]);

  Future<Directory> _ensureDirectory() async {
    return tempDirectory ??= await Directory.systemTemp.createTemp(name);
  }

  @override
  Future<Uri> createUriForComponent(Component component) async {
    Directory directory = await _ensureDirectory();
    Uri uri =
        directory.absolute.uri.resolve('macros${precompiledCount++}.dill');
    await writeComponentToFile(component, uri);
    return uri;
  }

  @override
  Future<void> close() async {
    try {
      await tempDirectory?.delete(recursive: true);
    } catch (_) {}
  }
}
