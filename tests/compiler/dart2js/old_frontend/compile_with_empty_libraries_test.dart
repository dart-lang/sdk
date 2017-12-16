// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test that the dart2js compiler can compile an empty script without
/// references to core library definitions.

import 'package:async_helper/async_helper.dart';
import '../mock_compiler.dart';

const String TEST = r"main() {}";

main() {
  Uri uri = new Uri(scheme: 'source');
  MockCompiler compiler =
      new MockCompiler.internal(librariesOverride: (_) => '');
  asyncTest(() => compiler.run(uri));
}
