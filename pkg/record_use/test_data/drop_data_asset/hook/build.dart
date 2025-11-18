// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:data_assets/data_assets.dart';
import 'package:hooks/hooks.dart';

void main(List<String> arguments) async {
  await build(arguments, (input, output) async {
    for (var element in ['add', 'multiply', 'double', 'square']) {
      output.assets.data.add(
        DataAsset(
          file: input.packageRoot.resolve('assets/$element.txt'),
          name: element,
          package: input.packageName,
        ),
        routing:
            input.config.linkingEnabled
                ? ToLinkHook(input.packageName)
                : const ToAppBundle(),
      );
    }
  });
}
