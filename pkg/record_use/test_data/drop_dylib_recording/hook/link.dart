// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:native_assets_cli/native_assets_cli.dart';
import 'package:record_use/record_use.dart';

final callIdAdd = const Identifier(
  importUri: 'package:drop_dylib_recording/src/drop_dylib_recording.dart',
  parent: 'MyMath',
  name: 'add',
);

final callIdMultiply = const Identifier(
  importUri: 'package:drop_dylib_recording/src/drop_dylib_recording.dart',
  parent: 'MyMath',
  name: 'multiply',
);

final instanceId = const Identifier(
  importUri: 'package:drop_dylib_recording/src/drop_dylib_recording.dart',
  name: 'RecordCallToC',
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

    final symbols = <String>{};
    final argumentsFile =
        await File.fromUri(config.outputDirectory.resolve('arguments.txt'))
          ..create();

    final dataLines = <String>[];
    //Tree-shake unused assets using calls
    for (var callId in [callIdAdd, callIdMultiply]) {
      var arguments = usages.argumentsTo(callId);
      if (arguments?.isNotEmpty ?? false) {
        final argument =
            (arguments!.first.constArguments.positional[0] as IntConstant)
                .value;
        dataLines.add('Argument to "${callId.name}": $argument');
        symbols.add(callId.name);
      }
    }

    argumentsFile.writeAsStringSync(dataLines.join('\n'));

    //Tree-shake unused assets
    final instances = usages.instancesOf(instanceId) ?? [];
    for (final instance in instances) {
      final symbol =
          (instance.instanceConstant.fields.values.first as StringConstant)
              .value;

      symbols.add(symbol);
    }

    for (var symbol in symbols) {
      output.addAssets(
        config.assets.where((asset) => asset.id.endsWith(symbol)),
      );
    }

    print('''
Keeping only ${output.assets.map((e) => e.id)}.
''');
    output.addDependency(config.packageRoot.resolve('hook/link.dart'));
  });
}
