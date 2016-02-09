// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dev_compiler.src.transformer.transformer;

import 'dart:async';
import 'dart:io';

import 'package:barback/barback.dart';
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisEngine, AnalysisOptionsImpl;
import 'package:path/path.dart' as path;

import 'asset_universe.dart';
import 'error_listener.dart';
import 'uri_resolver.dart' show assetIdToUri, createSourceFactory;
import '../compiler.dart';
import '../options.dart';
import '../utils.dart';
import 'package:analyzer/src/generated/engine.dart';

const String _fakeRuntimeDir = "<runtime>";

/// Disclaimer: this transformer is experimental and not optimized. It may run
/// out of memory for large applications: please use DDC's command-line runner
/// instead whenever possible.
class DdcTransformer extends AggregateTransformer {
  final List<String> _ddcArgs;

  DdcTransformer.asPlugin(BarbackSettings settings)
      : _ddcArgs = settings.configuration['args'] ?? [];

  @override
  apply(AggregateTransform transform) async {
    var inputs = await transform.primaryInputs.toList();

    // The analyzer's source factory mechanism is synchronous, so we can't
    // have it wait upon transform.getInput. Instead, we build the whole
    // universe (scanning transitive dependencies and reading their sources),
    // so as to get a non-async source getter.
    // Note: This means we use a lot of memory: one way to fix it would be to
    // propagate asynchonous calls throughout the analyzer.
    var universe = new AssetUniverse();
    await Future.wait(
        inputs.map((a) => universe.scanSources(a.id, transform.getInput)));

    // TODO(ochafik): invesigate the us of createAnalysisContextWithSources
    // instead.
    var context = AnalysisEngine.instance.createAnalysisContext();
    context.analysisOptions = _makeAnalysisOptions();
    context.sourceFactory = createSourceFactory(universe.getAssetSource);

    // Virtual file system that writes into the transformer's outputs.
    var fileSystem = new _TransformerFileSystem(
        transform.logger, transform.package, transform.addOutput,
        // Seed the runtime files into our file system:
        inputs: await _readRuntimeFiles(transform.getInput));

    var compiler = new BatchCompiler(
        context,
        // Note that the output directory needs not exist, and the runtime
        // directory is a special value that corresponds to the seeding of
        // runtimeFiles above.
        parseOptions([]
          ..addAll(_ddcArgs)
          ..addAll([
            '-o',
            fileSystem.outputDir.path,
            '--runtime-dir',
            _fakeRuntimeDir
          ])),
        reporter: new TransformAnalysisErrorListener(transform.logger, context),
        fileSystem: fileSystem);

    for (var asset in inputs) {
      compiler.compileFromUriString(assetIdToUri(asset.id));
    }
  }

  // TODO(ochafik): Provide more control over these options.
  AnalysisOptions _makeAnalysisOptions() => new AnalysisOptionsImpl()
    ..cacheSize = 256 // # of sources to cache ASTs for.
    ..preserveComments = true
    ..analyzeFunctionBodies = true
    ..strongMode = true;

  /// Read the runtime files from the transformer (they're available as
  /// resources of package:dev_compiler),
  Future<Map<String, String>> _readRuntimeFiles(
      Future<Asset> getInput(AssetId id)) async {
    var runtimeFiles = <String, String>{};
    for (var file in defaultRuntimeFiles) {
      var asset =
          await getInput(new AssetId('dev_compiler', 'lib/runtime/$file'));
      runtimeFiles[path.join(_fakeRuntimeDir, file)] =
          await asset.readAsString();
    }
    return runtimeFiles;
  }

  /// We just transform all .dart and .html files in one go.
  @override
  classifyPrimary(AssetId id) =>
      id.extension == '.dart' || id.extension == '.html' ? '<dart>' : null;
}

/// Type of [Transform.addOutput] and [AggregateTransform.addOutput].
typedef void AssetOutputAdder(Asset asset);

/// Virtual file system that outputs files into a transformer.
class _TransformerFileSystem implements FileSystem {
  final String _package;
  final Directory outputDir = Directory.current;
  final String outputPrefix;
  final AssetOutputAdder _addOutput;
  final Map<String, String> inputs;
  final TransformLogger _logger;
  _TransformerFileSystem(this._logger, this._package, this._addOutput,
      {this.inputs, this.outputPrefix: 'web/'});

  @override
  void writeAsStringSync(String file, String contents) {
    var id = new AssetId(
        _package, outputPrefix + path.relative(file, from: outputDir.path));
    _logger.fine('Adding output $id');
    _addOutput(new Asset.fromString(id, contents));
  }

  @override
  void copySync(String src, String dest) {
    writeAsStringSync(dest, inputs[src] ?? new File(src).readAsStringSync());
  }
}
