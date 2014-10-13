// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Transfomer used for pub-serve and pub-deploy.
library polymer.transformer;

import 'package:barback/barback.dart';
import 'package:observe/transformer.dart';
import 'package:path/path.dart' as path;

import 'src/build/build_filter.dart';
import 'src/build/common.dart';
import 'src/build/index_page_builder.dart';
import 'src/build/import_inliner.dart';
import 'src/build/linter.dart';
import 'src/build/build_log_combiner.dart';
import 'src/build/polyfill_injector.dart';
import 'src/build/script_compactor.dart';

/// The Polymer transformer, which internally runs several phases that will:
///   * Extract inlined script tags into their separate files
///   * Apply the observable transformer on every Dart script.
///   * Inline imported html files
///   * Combine scripts from multiple files into a single script tag
///   * Inject extra polyfills needed to run on all browsers.
///
/// At the end of these phases, this tranformer produces a single entrypoint
/// HTML file with a single Dart script that can later be compiled with dart2js.
class PolymerTransformerGroup implements TransformerGroup {
  final Iterable<Iterable> phases;

  PolymerTransformerGroup(TransformOptions options)
      : phases = createDeployPhases(options);

  PolymerTransformerGroup.asPlugin(BarbackSettings settings)
      : this(_parseSettings(settings));
}

TransformOptions _parseSettings(BarbackSettings settings) {
  var args = settings.configuration;
  bool releaseMode = settings.mode == BarbackMode.RELEASE;
  bool jsOption = args['js'];
  bool csp = args['csp'] == true; // defaults to false
  bool injectBuildLogs =
      !releaseMode && args['inject_build_logs_in_output'] != false;
  bool injectPlatformJs = args['inject_platform_js'] != false;
  return new TransformOptions(
      entryPoints: readFileList(args['entry_points']),
      inlineStylesheets: _readInlineStylesheets(args['inline_stylesheets']),
      directlyIncludeJS: jsOption == null ? releaseMode : jsOption,
      contentSecurityPolicy: csp,
      releaseMode: releaseMode,
      lint: _parseLintOption(args['lint']),
      injectBuildLogsInOutput: injectBuildLogs,
      injectPlatformJs: injectPlatformJs);
}

// Lint option can be empty (all files), false, true, or a map indicating
// include/exclude files.
_parseLintOption(value) {
  var lint = null;
  if (value == null || value == true) return new LintOptions();
  if (value == false) return new LintOptions.disabled();
  if (value is Map && value.length == 1) {
    var key = value.keys.single;
    var files = readFileList(value[key]);
    if (key == 'include') {
      return new LintOptions.include(files);
    } else if (key == 'exclude') {
      return new LintOptions.exclude(files);
    }
  }

  // Any other case it is an error:
  print('Invalid value for "lint" in the polymer transformer. '
        'Expected one of the following: \n'
        '    lint: true  # or\n'
        '    lint: false # or\n'
        '    lint: \n'
        '      include: \n'
        '        - file1 \n'
        '        - file2 # or \n'
        '    lint: \n'
        '      exclude: \n'
        '        - file1 \n'
        '        - file2 \n');
  return new LintOptions();
}

readFileList(value) {
  if (value == null) return null;
  var files = [];
  bool error;
  if (value is List) {
    files = value;
    error = value.any((e) => e is! String);
  } else if (value is String) {
    files = [value];
    error = false;
  } else {
    error = true;
  }
  if (error) {
    print('Invalid value for "entry_points" in the polymer transformer.');
  }
  return files;
}

Map<String, bool> _readInlineStylesheets(settingValue) {
  if (settingValue == null) return null;
  var inlineStylesheets = {};
  bool error = false;
  if (settingValue is Map) {
    settingValue.forEach((key, value) {
      if (value is! bool || key is! String) {
        error = true;
        return;
      }
      if (key == 'default') {
        inlineStylesheets[key] = value;
        return;
      };
      key = systemToAssetPath(key);
      // Special case package urls, convert to AssetId and use serialized form.
      var packageMatch = _PACKAGE_PATH_REGEX.matchAsPrefix(key);
      if (packageMatch != null) {
        var package = packageMatch[1];
        var path = 'lib/${packageMatch[2]}';
        key = new AssetId(package, path).toString();
      }
      inlineStylesheets[key] = value;
    });
  } else if (settingValue is bool) {
    inlineStylesheets['default'] = settingValue;
  } else {
    error = true;
  }
  if (error) {
    print('Invalid value for "inline_stylesheets" in the polymer transformer.');
  }
  return inlineStylesheets;
}

/// Create deploy phases for Polymer. Note that inlining HTML Imports
/// comes first (other than linter, if [options.linter] is enabled), which
/// allows the rest of the HTML-processing phases to operate only on HTML that
/// is actually imported.
List<List<Transformer>> createDeployPhases(
    TransformOptions options, {String sdkDir}) {
  // TODO(sigmund): this should be done differently. We should lint everything
  // that is reachable and have the option to lint the rest (similar to how
  // dart2js can analyze reachable code or entire libraries).
  var phases = options.lint.enabled ? [[new Linter(options)]] : [];
  phases.addAll([
    [new ImportInliner(options)],
    [new ObservableTransformer()],
    [new ScriptCompactor(options, sdkDir: sdkDir)],
    [new PolyfillInjector(options)],
    [new BuildFilter(options)],
    [new BuildLogCombiner(options)],
  ]);
  if (!options.releaseMode) {
    phases.add([new IndexPageBuilder(options)]);
  }
  return phases;
}

final RegExp _PACKAGE_PATH_REGEX = new RegExp(r'packages\/([^\/]+)\/(.*)');
