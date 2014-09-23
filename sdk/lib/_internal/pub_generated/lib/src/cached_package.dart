library pub.cached_package;
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import 'barback/transformer_config.dart';
import 'io.dart';
import 'package.dart';
import 'pubspec.dart';
import 'version.dart';
class CachedPackage extends Package {
  final String _cacheDir;
  CachedPackage(Package inner, this._cacheDir)
      : super(new _CachedPubspec(inner.pubspec), inner.dir);
  String path(String part1, [String part2, String part3, String part4,
      String part5, String part6, String part7]) {
    if (_pathInCache(part1)) {
      return p.join(_cacheDir, part1, part2, part3, part4, part5, part6, part7);
    } else {
      return super.path(part1, part2, part3, part4, part5, part6, part7);
    }
  }
  String relative(String path) {
    if (p.isWithin(path, _cacheDir)) return p.relative(path, from: _cacheDir);
    return super.relative(path);
  }
  List<String> listFiles({String beneath, recursive: true}) {
    if (beneath == null) return super.listFiles(recursive: recursive);
    if (_pathInCache(beneath)) return listDir(p.join(_cacheDir, beneath));
    return super.listFiles(beneath: beneath, recursive: recursive);
  }
  bool _pathInCache(String relativePath) => p.isWithin('lib', relativePath);
}
class _CachedPubspec implements Pubspec {
  final Pubspec _inner;
  YamlMap get fields => _inner.fields;
  String get name => _inner.name;
  Version get version => _inner.version;
  List<PackageDep> get dependencies => _inner.dependencies;
  List<PackageDep> get devDependencies => _inner.devDependencies;
  List<PackageDep> get dependencyOverrides => _inner.dependencyOverrides;
  PubspecEnvironment get environment => _inner.environment;
  String get publishTo => _inner.publishTo;
  Map<String, String> get executables => _inner.executables;
  bool get isPrivate => _inner.isPrivate;
  bool get isEmpty => _inner.isEmpty;
  List<PubspecException> get allErrors => _inner.allErrors;
  List<Set<TransformerConfig>> get transformers => const [];
  _CachedPubspec(this._inner);
}
