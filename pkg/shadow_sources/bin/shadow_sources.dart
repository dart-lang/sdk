// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// CLI entrypoint for the `shadow_sources` tool.
library;

import 'dart:io' as io;

import 'package:shadow_sources/shadow_sources.dart';

Future<void> main(List<String> args) => shadowSources(
  ShadowOptions.fromArgs(args),
  fileWriter: (uri, content) async {
    final file = io.File.fromUri(uri);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  },
);
