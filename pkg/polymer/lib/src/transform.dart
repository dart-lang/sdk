// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Transfomers used for pub-serve and pub-deploy. */
// TODO(sigmund): move into a plugin directory when pub supports it.
library polymer.src.transform;

import 'package:observe/transform.dart';
import 'transform/code_extractor.dart';
import 'transform/import_inliner.dart';
import 'transform/script_compactor.dart';
import 'transform/polyfill_injector.dart';

export 'transform/code_extractor.dart';
export 'transform/import_inliner.dart';
export 'transform/script_compactor.dart';
export 'transform/polyfill_injector.dart';

/** Phases to deploy a polymer application. */
var phases = [
  [new InlineCodeExtractor()],
  [new ObservableTransformer()],
  [new ImportedElementInliner()],
  [new ScriptCompactor()],
  [new PolyfillInjector()]
];
