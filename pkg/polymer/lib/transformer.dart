// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Transfomer used for pub-serve and pub-deploy. */
library polymer.transformer;

import 'package:barback/barback.dart';
import 'package:observe/transformer.dart';

import 'src/build/build_filter.dart';
import 'src/build/code_extractor.dart';
import 'src/build/common.dart';
import 'src/build/import_inliner.dart';
import 'src/build/linter.dart';
import 'src/build/polyfill_injector.dart';
import 'src/build/script_compactor.dart';

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

  PolymerTransformerGroup.asPlugin(BarbackSettings settings)
      : this(_parseSettings(settings));
}

TransformOptions _parseSettings(BarbackSettings settings) {
  var args = settings.configuration;
  bool releaseMode = settings.mode == BarbackMode.RELEASE;
  bool jsOption = args['js'];
  bool csp = args['csp'] == true; // defaults to false
  return new TransformOptions(
      entryPoints: _readEntrypoints(args['entry_points']),
      directlyIncludeJS: jsOption == null ? releaseMode : jsOption,
      contentSecurityPolicy: csp,
      releaseMode: releaseMode);
}

_readEntrypoints(value) {
  if (value == null) return null;
  var entryPoints = [];
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
  return entryPoints;
}

List<List<Transformer>> _createDeployPhases(TransformOptions options) {
  return [
    [new Linter(options)],
    [new InlineCodeExtractor(options)],
    [new ObservableTransformer()],
    [new ImportInliner(options)],
    [new ScriptCompactor(options)],
    [new PolyfillInjector(options)],
    [new BuildFilter(options)]
  ];
}
