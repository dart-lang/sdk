// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:async_helper/async_helper.dart" show asyncTest;

import "package:front_end/src/testing/compiler_common.dart" show compileUnit;

import "package:front_end/front_end.dart" show CompilerOptions;

main() {
  asyncTest(() async {
    var sources = <String, dynamic>{
      "a.dart": """
import 'charcode.dart';
""",
      "charcode.dart": """
export 'ascii.dart';
export 'html_entity.dart' hide tilde;
""",
      "html_entity.dart": """
export 'ascii.dart' show quot;
const int tilde=1;
""",
      "ascii.dart": """
const int tilde=2;
const int quot=3;
""",
    };
    await compileUnit(sources.keys.toList(), sources,
        options: new CompilerOptions()
          ..onError = (e) => throw "${e.severity}: ${e.message}");
  });
}
