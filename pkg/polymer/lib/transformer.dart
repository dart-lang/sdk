// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Transfomer used for pub-serve and pub-deploy. */
library polymer.transformer;

import 'package:barback/barback.dart';
import 'package:observe/transform.dart';
import 'src/build/code_extractor.dart';
import 'src/build/import_inliner.dart';
import 'src/build/script_compactor.dart';
import 'src/build/polyfill_injector.dart';
import 'src/build/common.dart';

/**
 * The Polymer transformer, which internally runs several phases that will:
 *   * Extract inlined script tags into their separate files
 *   * Apply the observable transformer on every Dart script.
 *   * Inline imported html files
 *   * Combine scripts from multiple files into a single script tag
 *   * Inject extra polyfills needed to run on all browsers.
 *
 * At the end of these phases, this tranformer produces a single entrypoint HTML
 * file with a single Dart script that can later be compiled with dart2js.
 */
class PolymerTransformerGroup implements TransformerGroup {
  final Iterable<Iterable> phases;

  PolymerTransformerGroup(TransformOptions options)
      : phases = _createDeployPhases(options);

  PolymerTransformerGroup.asPlugin(Map args) : this(_parseArgs(args));
}


TransformOptions _parseArgs(Map args) {
  var entryPoints;
  if (args.containsKey('entry_points')) {
    entryPoints = [];
    var value = args['entry_points'];
    bool error;
    if (value is List) {
      entryPoints = value;
      error = value.any((e) => e is! String);
    } else if (value is String) {
      entryPoints = [value];
      error = false;
    } else {
      error = true;
    }

    if (error) {
      print('Invalid value for "entry_points" in the polymer transformer.');
    }
  }
  return new TransformOptions(entryPoints: entryPoints);
}

List<List<Transformer>> _createDeployPhases(TransformOptions options) {
  return [
    [new InlineCodeExtractor(options)],
    [new ObservableTransformer()],
    [new ImportInliner(options)],
    [new ScriptCompactor(options)],
    [new PolyfillInjector(options)]
  ];
}
