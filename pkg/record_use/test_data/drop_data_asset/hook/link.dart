// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:data_assets/data_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:record_use/record_use.dart';

void main(List<String> arguments) async {
  await link(arguments, (input, output) async {
    final recordedUsagesFile = input.recordedUsagesFile;
    if (recordedUsagesFile == null) {
      throw ArgumentError(
        'Enable the --enable-experiments=record-use experiment to use this app.',
      );
    }
    final usages = await recordedUsages(recordedUsagesFile);
    final dataAssets = input.assets.data;
    print('Received assets: ${dataAssets.map((a) => a.id).join(', ')}.');

    final symbols = <String>{};

    // Tree-shake unused assets using calls
    for (final methodName in ['add', 'multiply']) {
      final calls = usages.constArgumentsFor(
        Identifier(
          importUri:
              'package:${input.packageName}/src/${input.packageName}.dart',
          scope: 'MyMath',
          name: methodName,
        ),
        'int add(int a, int b)',
      );
      print('Checking calls to $methodName...');
      for (final call in calls) {
        print(
          'A call was made to "$methodName" with the arguments ('
          '${call.positional[0] as int},${call.positional[1] as int})',
        );
        symbols.add(methodName);
      }
    }

    // Tree-shake unused assets
    final instances = usages.constantsOf(
      Identifier(
        importUri: 'package:${input.packageName}/src/${input.packageName}.dart',
        name: 'RecordCallToC',
      ),
    );
    for (final instance in instances) {
      final symbol = instance['symbol'] as String;
      print('An instance of "$instance" was found with the field "$symbol"');
      symbols.add(symbol);
    }

    final neededCodeAssets = [
      for (final asset in dataAssets)
        if (symbols.any(asset.id.endsWith)) asset,
    ];

    print('Keeping only ${neededCodeAssets.map((e) => e.id).join(', ')}.');
    output.assets.data.addAll(neededCodeAssets);

    output.addDependency(recordedUsagesFile);
  });
}

Future<RecordedUsages> recordedUsages(Uri recordedUsagesFile) async {
  final file = File.fromUri(recordedUsagesFile);
  final string = await file.readAsString();
  final usages = RecordedUsages.fromJson(
    jsonDecode(string) as Map<String, Object?>,
  );
  return usages;
}
