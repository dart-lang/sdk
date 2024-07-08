// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:_fe_analyzer_shared/src/messages/diagnostic_message.dart';
import 'package:front_end/src/api_prototype/testing.dart';
import 'package:kernel/ast.dart';

import "io_utils.dart";

final Uri repoDir = computeRepoDirUri();

Future<void> main(List<String> args) async {
  List<Uri> entryPoints = [];
  for (FileSystemEntity entry
      in new Directory.fromUri(repoDir.resolve("pkg/frontend_server/lib/"))
          .listSync(recursive: true)) {
    if (entry is! File) continue;
    entryPoints.add(entry.uri);
  }

  await run(entryPoints,
      'pkg/frontend_server/test/frontend_server_dynamic_allowed.json',
      analyzedUrisFilter: (Uri uri) =>
          '$uri'.startsWith('package:frontend_server/'),
      verbose: args.contains('-v'),
      generate: args.contains('-g'));
}

Future<void> run(List<Uri> entryPoints, String allowedListPath,
    {bool verbose = false,
    bool generate = false,
    bool Function(Uri uri)? analyzedUrisFilter}) async {
  await runAnalysis(entryPoints,
      (DiagnosticMessageHandler onDiagnostic, Component component) {
    new DynamicVisitor(
            onDiagnostic, component, allowedListPath, analyzedUrisFilter)
        .run(verbose: verbose, generate: generate);
  });
}
