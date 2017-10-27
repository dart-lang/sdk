// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/filenames.dart';
import '../equivalence/id_equivalence_helper.dart';
import 'inference_test_helper.dart';

main(List<String> args) {
  asyncTest(() async {
    Uri uri = Uri.base.resolve(nativeToUriPath(args.first));
    List<Uri> uris = <Uri>[];
    if (FileSystemEntity.isDirectorySync(args.first)) {
      for (FileSystemEntity file in new Directory.fromUri(uri).listSync()) {
        if (file is File && file.path.endsWith('.dart')) {
          uris.add(file.uri);
        }
      }
    } else {
      uris.add(uri);
    }
    for (Uri uri in uris) {
      try {
        print('--$uri--------------------------------------------------------');
        await compareData(
            uri, const {}, computeMemberAstTypeMasks, computeMemberIrTypeMasks,
            options: [stopAfterTypeInference], skipUnprocessedMembers: true);
      } catch (e, s) {
        print('Failed: $e\n$s');
      }
    }
  });
}
