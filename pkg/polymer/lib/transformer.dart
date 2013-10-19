// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Transfomers used for pub-serve and pub-deploy. */
// TODO(sigmund): move into a plugin directory when pub supports it.
library polymer.src.transform;

import 'package:barback/barback.dart';
import 'package:observe/transform.dart';
import 'src/build/code_extractor.dart';
import 'src/build/import_inliner.dart';
import 'src/build/script_compactor.dart';
import 'src/build/polyfill_injector.dart';
import 'src/build/common.dart';

export 'src/build/code_extractor.dart';
export 'src/build/import_inliner.dart';
export 'src/build/script_compactor.dart';
export 'src/build/polyfill_injector.dart';
export 'src/build/common.dart' show TransformOptions;

/** Creates phases to deploy a polymer application. */
List<List<Transformer>> createDeployPhases(TransformOptions options) {
  return [
    [new InlineCodeExtractor(options)],
    [new ObservableTransformer()],
    [new ImportInliner(options)],
    [new ScriptCompactor(options)],
    [new PolyfillInjector(options)]
  ];
}
