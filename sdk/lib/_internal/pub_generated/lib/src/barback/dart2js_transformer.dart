library pub.dart2js_transformer;
import 'dart:async';
import 'dart:convert';
import 'package:analyzer/analyzer.dart';
import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;
import 'package:pool/pool.dart';
import 'package:stack_trace/stack_trace.dart';
import '../../../../compiler/compiler.dart' as compiler;
import '../../../../compiler/implementation/dart2js.dart' show AbortLeg;
import '../../../../compiler/implementation/source_file.dart';
import '../barback.dart';
import '../dart.dart' as dart;
import '../utils.dart';
import 'asset_environment.dart';
final _validOptions = new Set<String>.from(
    [
        'commandLineOptions',
        'checked',
        'csp',
        'minify',
        'verbose',
        'environment',
        'analyzeAll',
        'suppressWarnings',
        'suppressHints',
        'suppressPackageWarnings',
        'terse']);
class Dart2JSTransformer extends Transformer implements LazyTransformer {
  static final _pool = new Pool(1);
  final AssetEnvironment _environment;
  final BarbackSettings _settings;
  bool get _generateSourceMaps => _settings.mode != BarbackMode.RELEASE;
  Dart2JSTransformer.withSettings(this._environment, this._settings) {
    var invalidOptions =
        _settings.configuration.keys.toSet().difference(_validOptions);
    if (invalidOptions.isEmpty) return;
    throw new FormatException(
        "Unrecognized dart2js " "${pluralize('option', invalidOptions.length)} "
            "${toSentence(invalidOptions.map((option) => '"$option"'))}.");
  }
  Dart2JSTransformer(AssetEnvironment environment, BarbackMode mode)
      : this.withSettings(environment, new BarbackSettings({}, mode));
  bool isPrimary(AssetId id) {
    if (id.extension != ".dart") return false;
    return !id.path.startsWith("lib/");
  }
  Future apply(Transform transform) {
    return _isEntrypoint(transform.primaryInput).then((isEntrypoint) {
      if (!isEntrypoint) return null;
      return _pool.withResource(() {
        transform.logger.info("Compiling ${transform.primaryInput.id}...");
        var stopwatch = new Stopwatch()..start();
        return _doCompilation(transform).then((_) {
          stopwatch.stop();
          transform.logger.info(
              "Took ${stopwatch.elapsed} to compile " "${transform.primaryInput.id}.");
        });
      });
    });
  }
  void declareOutputs(DeclaringTransform transform) {
    var primaryId = transform.primaryId;
    transform.declareOutput(primaryId.addExtension(".js"));
    transform.declareOutput(primaryId.addExtension(".precompiled.js"));
    if (_generateSourceMaps) {
      transform.declareOutput(primaryId.addExtension(".js.map"));
    }
  }
  Future<bool> _isEntrypoint(Asset asset) {
    return asset.readAsString().then((code) {
      try {
        var name = asset.id.path;
        if (asset.id.package != _environment.rootPackage.name) {
          name += " in ${asset.id.package}";
        }
        var parsed = parseCompilationUnit(code, name: name);
        return dart.isEntrypoint(parsed);
      } on AnalyzerErrorGroup catch (e) {
        return true;
      }
    });
  }
  Future _doCompilation(Transform transform) {
    var provider = new _BarbackCompilerProvider(
        _environment,
        transform,
        generateSourceMaps: _generateSourceMaps);
    var id = transform.primaryInput.id;
    var entrypoint =
        path.join(_environment.graph.packages[id.package].dir, id.path);
    return Chain.track(
        dart.compile(
            entrypoint,
            provider,
            commandLineOptions: _configCommandLineOptions,
            csp: _configBool('csp'),
            checked: _configBool('checked'),
            minify: _configBool(
                'minify',
                defaultsTo: _settings.mode == BarbackMode.RELEASE),
            verbose: _configBool('verbose'),
            environment: _configEnvironment,
            packageRoot: path.join(_environment.rootPackage.dir, "packages"),
            analyzeAll: _configBool('analyzeAll'),
            suppressWarnings: _configBool('suppressWarnings'),
            suppressHints: _configBool('suppressHints'),
            suppressPackageWarnings: _configBool(
                'suppressPackageWarnings',
                defaultsTo: true),
            terse: _configBool('terse'),
            includeSourceMapUrls: _settings.mode != BarbackMode.RELEASE));
  }
  List<String> get _configCommandLineOptions {
    if (!_settings.configuration.containsKey('commandLineOptions')) return null;
    var options = _settings.configuration['commandLineOptions'];
    if (options is List && options.every((option) => option is String)) {
      return options;
    }
    throw new FormatException(
        'Invalid value for '
            '\$dart2js.commandLineOptions: ${JSON.encode(options)} (expected list '
            'of strings).');
  }
  Map<String, String> get _configEnvironment {
    if (!_settings.configuration.containsKey('environment')) return null;
    var environment = _settings.configuration['environment'];
    if (environment is Map &&
        environment.keys.every((key) => key is String) &&
        environment.values.every((key) => key is String)) {
      return environment;
    }
    throw new FormatException(
        'Invalid value for \$dart2js.environment: '
            '${JSON.encode(environment)} (expected map from strings to strings).');
  }
  bool _configBool(String name, {bool defaultsTo: false}) {
    if (!_settings.configuration.containsKey(name)) return defaultsTo;
    var value = _settings.configuration[name];
    if (value is bool) return value;
    throw new FormatException(
        'Invalid value for \$dart2js.$name: '
            '${JSON.encode(value)} (expected true or false).');
  }
}
class _BarbackCompilerProvider implements dart.CompilerProvider {
  Uri get libraryRoot => Uri.parse("${path.toUri(_libraryRootPath)}/");
  final AssetEnvironment _environment;
  final Transform _transform;
  String _libraryRootPath;
  final _sourceFiles = new Map<String, SourceFile>();
  var _showWarnings = true;
  var _showHints = true;
  var _verbose = false;
  var _throwOnError = false;
  var _isAborting = false;
  final bool generateSourceMaps;
  compiler.Diagnostic _lastKind = null;
  static final int _FATAL =
      compiler.Diagnostic.CRASH.ordinal |
      compiler.Diagnostic.ERROR.ordinal;
  static final int _INFO =
      compiler.Diagnostic.INFO.ordinal |
      compiler.Diagnostic.VERBOSE_INFO.ordinal;
  _BarbackCompilerProvider(this._environment, this._transform,
      {this.generateSourceMaps: true}) {
    var buildDir =
        _environment.getSourceDirectoryContaining(_transform.primaryInput.id.path);
    _libraryRootPath =
        path.join(_environment.rootPackage.dir, buildDir, "packages", r"$sdk");
  }
  Future<String> provideInput(Uri resourceUri) {
    assert(resourceUri.isAbsolute);
    assert(resourceUri.scheme == "file");
    var sourcePath = path.fromUri(resourceUri);
    return _readResource(resourceUri).then((source) {
      _sourceFiles[resourceUri.toString()] =
          new StringSourceFile(path.relative(sourcePath), source);
      return source;
    });
  }
  EventSink<String> provideOutput(String name, String extension) {
    if (!generateSourceMaps && extension.endsWith(".map")) {
      return new NullSink<String>();
    }
    var primaryId = _transform.primaryInput.id;
    var outPath;
    if (name == "") {
      outPath = _transform.primaryInput.id.path;
    } else {
      var dirname = path.url.dirname(_transform.primaryInput.id.path);
      outPath = path.url.join(dirname, name);
    }
    var id = new AssetId(primaryId.package, "$outPath.$extension");
    var sink = new StreamController<String>();
    var stream = UTF8.encoder.bind(sink.stream);
    _transform.addOutput(new Asset.fromStream(id, stream));
    return sink;
  }
  void handleDiagnostic(Uri uri, int begin, int end, String message,
      compiler.Diagnostic kind) {
    if (kind.name == "source map") return;
    if (_isAborting) return;
    _isAborting = (kind == compiler.Diagnostic.CRASH);
    var isInfo = (kind.ordinal & _INFO) != 0;
    if (isInfo && uri == null && kind != compiler.Diagnostic.INFO) {
      if (!_verbose && kind == compiler.Diagnostic.VERBOSE_INFO) return;
      _transform.logger.info(message);
      return;
    }
    if (kind != compiler.Diagnostic.INFO) _lastKind = kind;
    var logFn;
    if (kind == compiler.Diagnostic.ERROR) {
      logFn = _transform.logger.error;
    } else if (kind == compiler.Diagnostic.WARNING) {
      if (!_showWarnings) return;
      logFn = _transform.logger.warning;
    } else if (kind == compiler.Diagnostic.HINT) {
      if (!_showHints) return;
      logFn = _transform.logger.warning;
    } else if (kind == compiler.Diagnostic.CRASH) {
      logFn = _transform.logger.error;
    } else if (kind == compiler.Diagnostic.INFO) {
      if (_lastKind == compiler.Diagnostic.WARNING && !_showWarnings) return;
      if (_lastKind == compiler.Diagnostic.HINT && !_showHints) return;
      logFn = _transform.logger.info;
    } else {
      throw new Exception('Unknown kind: $kind (${kind.ordinal})');
    }
    var fatal = (kind.ordinal & _FATAL) != 0;
    if (uri == null) {
      logFn(message);
    } else {
      SourceFile file = _sourceFiles[uri.toString()];
      if (file == null) {
        logFn('$uri: $message');
      } else {
        logFn(file.getLocationMessage(message, begin, end, true, (i) => i));
      }
    }
    if (fatal && _throwOnError) {
      _isAborting = true;
      throw new AbortLeg(message);
    }
  }
  Future<String> _readResource(Uri url) {
    return syncFuture(() {
      var id = _sourceUrlToId(url);
      if (id != null) return _transform.readInputAsString(id);
      throw new Exception(
          "Cannot read $url because it is outside of the build environment.");
    });
  }
  AssetId _sourceUrlToId(Uri url) {
    var id = packagesUrlToId(url);
    if (id != null) return id;
    var sourcePath = path.fromUri(url);
    if (_environment.containsPath(sourcePath)) {
      var relative = path.toUri(
          path.relative(sourcePath, from: _environment.rootPackage.dir)).toString();
      return new AssetId(_environment.rootPackage.name, relative);
    }
    return null;
  }
}
class NullSink<T> implements EventSink<T> {
  void add(T event) {}
  void addError(errorEvent, [StackTrace stackTrace]) {}
  void close() {}
}
