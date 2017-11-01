// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'package:args/args.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/filenames.dart';
import 'package:compiler/src/inferrer/inferrer_engine.dart';
import '../equivalence/id_equivalence_helper.dart';
import 'inference_test_helper.dart';

main(List<String> args) {
  ArgParser argParser = new ArgParser(allowTrailingOptions: true);
  argParser.addFlag('colors', negatable: true);
  ArgResults argResults = argParser.parse(args);
  if (argResults['colors'] != null) {
    useColors = argResults['colors'];
  }

  InferrerEngineImpl.useSorterForTesting = true;
  asyncTest(() async {
    for (String arg in argResults.rest) {
      Uri uri = Uri.base.resolve(nativeToUriPath(arg));
      List<Uri> uris = <Uri>[];
      if (FileSystemEntity.isDirectorySync(arg)) {
        for (FileSystemEntity file in new Directory.fromUri(uri).listSync()) {
          if (file is File && file.path.endsWith('.dart')) {
            uris.add(file.uri);
          }
        }
      } else {
        uris.add(uri);
      }
      for (Uri uri in uris) {
        StringBuffer sb = new StringBuffer();
        ZoneSpecification specification = new ZoneSpecification(
            print: (self, parent, zone, line) => sb.writeln(line));

        try {
          print('--$uri------------------------------------------------------');
          bool isSuccess = await runZoned(() {
            return compareData(uri, const {}, computeMemberAstTypeMasks,
                computeMemberIrTypeMasks,
                options: [stopAfterTypeInference],
                forMainLibraryOnly: false,
                skipUnprocessedMembers: true,
                skipFailedCompilations: true);
          }, zoneSpecification: specification);
          if (!isSuccess) {
            print('  skipped due to compile-time errors');
          }
        } catch (e, s) {
          print(sb);
          print('Failed: $e\n$s');
        }
      }
    }
  });
}
