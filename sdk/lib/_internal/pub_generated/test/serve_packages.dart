library serve_packages;
import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:scheduled_test/scheduled_test.dart';
import 'package:yaml/yaml.dart';
import '../lib/src/io.dart';
import '../lib/src/utils.dart';
import '../lib/src/version.dart';
import 'descriptor.dart' as d;
import 'test_pub.dart';
d.DirectoryDescriptor _servedApiPackageDir;
d.DirectoryDescriptor _servedPackageDir;
PackageServerBuilder _builder;
void servePackages(void callback(PackageServerBuilder builder), {bool replace:
    false}) {
  if (_servedPackageDir == null) {
    _builder = new PackageServerBuilder();
    _servedApiPackageDir = d.dir('packages', []);
    _servedPackageDir = d.dir('packages', []);
    serve([d.dir('api', [_servedApiPackageDir]), _servedPackageDir]);
    currentSchedule.onComplete.schedule(() {
      _builder = null;
      _servedApiPackageDir = null;
      _servedPackageDir = null;
    }, 'cleaning up served packages');
  }
  schedule(() {
    if (replace) _builder = new PackageServerBuilder();
    callback(_builder);
    return _builder._await().then((resolvedPubspecs) {
      _servedApiPackageDir.contents.clear();
      _servedPackageDir.contents.clear();
      _builder._packages.forEach((name, versions) {
        _servedApiPackageDir.contents.addAll([d.file('$name', JSON.encode({
            'name': name,
            'uploaders': ['nweiz@google.com'],
            'versions': versions.map(
                (version) => packageVersionApiMap(version.pubspec)).toList()
          })), d.dir(name, [d.dir('versions', versions.map((version) {
              return d.file(
                  version.version.toString(),
                  JSON.encode(packageVersionApiMap(version.pubspec, full: true)));
            }))])]);
        _servedPackageDir.contents.add(
            d.dir(
                name,
                [
                    d.dir(
                        'versions',
                        versions.map(
                            (version) => d.tar('${version.version}.tar.gz', version.contents)))]));
      });
    });
  }, 'initializing the package server');
}
void serveNoPackages() => servePackages((_) {}, replace: true);
class PackageServerBuilder {
  final _packages = new Map<String, List<_ServedPackage>>();
  var _futures = new FutureGroup();
  void serve(String name, String version, {Map deps, Map pubspec,
      Iterable<d.Descriptor> contents}) {
    _futures.add(
        Future.wait([awaitObject(deps), awaitObject(pubspec)]).then((pair) {
      var resolvedDeps = pair.first;
      var resolvedPubspec = pair.last;
      var pubspecFields = {
        "name": name,
        "version": version
      };
      if (resolvedPubspec != null) pubspecFields.addAll(resolvedPubspec);
      if (resolvedDeps != null) pubspecFields["dependencies"] = resolvedDeps;
      if (contents == null) contents = [d.libDir(name, "$name $version")];
      contents =
          [d.file("pubspec.yaml", yaml(pubspecFields))]..addAll(contents);
      var packages = _packages.putIfAbsent(name, () => []);
      packages.add(new _ServedPackage(pubspecFields, contents));
    }));
  }
  void serveRepoPackage(String package) {
    _addPackage(name) {
      if (_packages.containsKey(name)) return;
      _packages[name] = [];
      var pubspec = new Map.from(
          loadYaml(readTextFile(p.join(repoRoot, 'pkg', name, 'pubspec.yaml'))));
      pubspec.remove('environment');
      _packages[name].add(
          new _ServedPackage(
              pubspec,
              [
                  d.file('pubspec.yaml', yaml(pubspec)),
                  new d.DirectoryDescriptor.fromFilesystem(
                      'lib',
                      p.join(repoRoot, 'pkg', name, 'lib'))]));
      if (pubspec.containsKey('dependencies')) {
        pubspec['dependencies'].keys.forEach(_addPackage);
      }
    }
    _addPackage(package);
  }
  Future _await() {
    if (_futures.futures.isEmpty) return new Future.value();
    return _futures.future.then((_) {
      _futures = new FutureGroup();
    });
  }
}
class _ServedPackage {
  final Map pubspec;
  final List<d.Descriptor> contents;
  Version get version => new Version.parse(pubspec['version']);
  _ServedPackage(this.pubspec, this.contents);
}
