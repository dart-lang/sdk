// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

import 'codegen_dart.dart';
import 'markdown.dart';
import 'typescript.dart';

main() async {
  final String script = Platform.script.toFilePath();
  // 3x parent = file -> lsp_spec -> tool -> analysis_server.
  final String packageFolder = new File(script).parent.parent.parent.path;
  final String outFolder = path.join(packageFolder, 'lib', 'lsp_protocol');
  new Directory(outFolder).createSync();

  final String spec = await fetchSpec();
  final List<ApiItem> types =
      extractTypeScriptBlocks(spec).map(extractTypes).expand((l) => l).toList();
  final String output = generateDartForTypes(types);
  // TODO(dantup): Add file header to output file before we start committing it.
  new File(path.join(outFolder, 'protocol_generated.dart'))
      .writeAsStringSync(output);
}

final Uri specUri = Uri.parse(
    'https://raw.githubusercontent.com/Microsoft/language-server-protocol/gh-pages/specification.md');

Future<String> fetchSpec() async {
  final resp = await http.get(specUri);
  return resp.body;
}
