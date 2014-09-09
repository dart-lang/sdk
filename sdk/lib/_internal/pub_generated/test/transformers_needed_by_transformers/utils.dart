library pub_tests;
import 'package:path/path.dart' as p;
import 'package:scheduled_test/scheduled_test.dart';
import '../../lib/src/barback/cycle_exception.dart';
import '../../lib/src/barback/transformers_needed_by_transformers.dart';
import '../../lib/src/entrypoint.dart';
import '../../lib/src/io.dart';
import '../../lib/src/package.dart';
import '../../lib/src/package_graph.dart';
import '../../lib/src/source/path.dart';
import '../../lib/src/system_cache.dart';
import '../../lib/src/utils.dart';
import '../test_pub.dart';
void expectDependencies(Map<String, Iterable<String>> expected) {
  expected = mapMap(expected, value: (_, ids) => ids.toSet());
  schedule(() {
    var result = mapMap(
        computeTransformersNeededByTransformers(_loadPackageGraph()),
        key: (id, _) => id.toString(),
        value: (_, ids) => ids.map((id) => id.toString()).toSet());
    expect(result, equals(expected));
  }, "expect dependencies to match $expected");
}
void expectException(matcher) {
  schedule(() {
    expect(
        () => computeTransformersNeededByTransformers(_loadPackageGraph()),
        throwsA(matcher));
  }, "expect an exception: $matcher");
}
void expectCycleException(Iterable<String> steps) {
  expectException(predicate((error) {
    expect(error, new isInstanceOf<CycleException>());
    expect(error.steps, equals(steps));
    return true;
  }, "cycle exception:\n${steps.map((step) => "  $step").join("\n")}"));
}
PackageGraph _loadPackageGraph() {
  var packages = {};
  var systemCache = new SystemCache(p.join(sandboxDir, cachePath));
  systemCache.sources
      ..register(new PathSource())
      ..setDefault('path');
  var entrypoint = new Entrypoint(p.join(sandboxDir, appPath), systemCache);
  for (var package in listDir(sandboxDir)) {
    if (!fileExists(p.join(package, 'pubspec.yaml'))) continue;
    var packageName = p.basename(package);
    packages[packageName] =
        new Package.load(packageName, package, systemCache.sources);
  }
  loadPackage(packageName) {
    if (packages.containsKey(packageName)) return;
    packages[packageName] = new Package.load(
        packageName,
        p.join(pkgPath, packageName),
        systemCache.sources);
    for (var dep in packages[packageName].dependencies) {
      loadPackage(dep.name);
    }
  }
  loadPackage('barback');
  return new PackageGraph(entrypoint, null, packages);
}
String transformer([Iterable<String> imports]) {
  if (imports == null) imports = [];
  var buffer =
      new StringBuffer()..writeln('import "package:barback/barback.dart";');
  for (var import in imports) {
    buffer.writeln('import "$import";');
  }
  buffer.writeln("""
NoOpTransformer extends Transformer {
  bool isPrimary(AssetId id) => true;
  void apply(Transform transform) {}
}
""");
  return buffer.toString();
}
