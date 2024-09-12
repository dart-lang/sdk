// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:native_assets_cli/native_assets_cli.dart';
import 'package:record_use/record_use.dart';

final id = const Identifier(
  uri: 'package:drop_dylib_recording/src/drop_dylib_recording.dart',
  name: 'getMathMethod',
);

void main(List<String> arguments) async {
  await link(arguments, (config, output) async {
    final file = File.fromUri(config.recordedUsagesFile!);
    final string = await file.readAsString();
    final usages =
        RecordedUsages.fromJson(jsonDecode(string) as Map<String, dynamic>);

    print('''
Received ${config.assets.length} assets: ${config.assets.map((e) => e.id)}.
''');
    final f = File.fromUri(config.outputDirectory.resolve('debug.txt'))
      ..createSync();
    f.writeAsStringSync(config.assets
        .map(
          (e) => e.id,
        )
        .join('\n'));
    f.writeAsStringSync('\nnow', mode: FileMode.append);

    if (usages.hasNonConstArguments(id)) {
      //Keep all assets
      output.addAssets(config.assets);
      f.writeAsStringSync('\nhasNonConstargs', mode: FileMode.append);

      f.writeAsStringSync(
          '\n${usages.argumentsTo(id)!.first.nonConstArguments.toJson()}',
          mode: FileMode.append);
    } else {
      f.writeAsStringSync('\nno-hasNonConstargs', mode: FileMode.append);
      //Tree-shake unused assets
      final arguments = usages.argumentsTo(id) ?? [];
      for (final argument in arguments) {
        f.writeAsStringSync('\nArg: $argument', mode: FileMode.append);
        final symbol =
            (argument.constArguments.positional[0] as StringConstant).value;
        f.writeAsStringSync('\nsymbol: $symbol', mode: FileMode.append);

        output.addAssets(
          config.assets.where((asset) => asset.id.endsWith(symbol)),
        );
      }
    }

    print('''
Keeping only ${output.assets.map((e) => e.id)}.
''');
    output.addDependency(config.packageRoot.resolve('hook/link.dart'));
  });
}
