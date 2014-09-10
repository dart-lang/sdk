library pub.command.list;
import 'dart:async';
import 'dart:collection';
import '../ascii_tree.dart' as tree;
import '../command.dart';
import '../log.dart' as log;
import '../package.dart';
import '../package_graph.dart';
import '../utils.dart';
class DepsCommand extends PubCommand {
  String get description => "Print package dependencies.";
  List<String> get aliases => const ["dependencies", "tab"];
  String get usage => "pub deps";
  String get docUrl => "http://dartlang.org/tools/pub/cmd/pub-deps.html";
  PackageGraph _graph;
  StringBuffer _buffer;
  DepsCommand() {
    commandParser.addOption(
        "style",
        abbr: "s",
        help: "How output should be displayed.",
        allowed: ["compact", "tree", "list"],
        defaultsTo: "tree");
  }
  Future onRun() {
    return entrypoint.loadPackageGraph().then((graph) {
      _graph = graph;
      _buffer = new StringBuffer();
      _buffer.writeln(_labelPackage(entrypoint.root));
      switch (commandOptions["style"]) {
        case "compact":
          _outputCompact();
          break;
        case "list":
          _outputList();
          break;
        case "tree":
          _outputTree();
          break;
      }
      log.message(_buffer);
    });
  }
  void _outputCompact() {
    var root = entrypoint.root;
    _outputCompactPackages(
        "dependencies",
        root.dependencies.map((dep) => dep.name));
    _outputCompactPackages(
        "dev dependencies",
        root.devDependencies.map((dep) => dep.name));
    _outputCompactPackages(
        "dependency overrides",
        root.dependencyOverrides.map((dep) => dep.name));
    var transitive = _getTransitiveDependencies();
    _outputCompactPackages("transitive dependencies", transitive);
  }
  _outputCompactPackages(String section, Iterable<String> names) {
    if (names.isEmpty) return;
    _buffer.writeln();
    _buffer.writeln("$section:");
    for (var name in ordered(names)) {
      var package = _graph.packages[name];
      _buffer.write("- ${_labelPackage(package)}");
      if (package.dependencies.isEmpty) {
        _buffer.writeln();
      } else {
        var depNames = package.dependencies.map((dep) => dep.name);
        var depsList = "[${depNames.join(' ')}]";
        _buffer.writeln(" ${log.gray(depsList)}");
      }
    }
  }
  void _outputList() {
    var root = entrypoint.root;
    _outputListSection(
        "dependencies",
        root.dependencies.map((dep) => dep.name));
    _outputListSection(
        "dev dependencies",
        root.devDependencies.map((dep) => dep.name));
    _outputListSection(
        "dependency overrides",
        root.dependencyOverrides.map((dep) => dep.name));
    var transitive = _getTransitiveDependencies();
    if (transitive.isEmpty) return;
    _outputListSection("transitive dependencies", ordered(transitive));
  }
  _outputListSection(String name, Iterable<String> deps) {
    if (deps.isEmpty) return;
    _buffer.writeln();
    _buffer.writeln("$name:");
    for (var name in deps) {
      var package = _graph.packages[name];
      _buffer.writeln("- ${_labelPackage(package)}");
      for (var dep in package.dependencies) {
        _buffer.writeln(
            "  - ${log.bold(dep.name)} ${log.gray(dep.constraint)}");
      }
    }
  }
  void _outputTree() {
    var toWalk = new Queue<Pair<Package, Map>>();
    var visited = new Set<String>();
    var packageTree = {};
    for (var dep in entrypoint.root.immediateDependencies) {
      toWalk.add(new Pair(_graph.packages[dep.name], packageTree));
    }
    while (toWalk.isNotEmpty) {
      var pair = toWalk.removeFirst();
      var package = pair.first;
      var map = pair.last;
      if (visited.contains(package.name)) {
        map[log.gray('${package.name}...')] = {};
        continue;
      }
      visited.add(package.name);
      var childMap = {};
      map[_labelPackage(package)] = childMap;
      for (var dep in package.dependencies) {
        toWalk.add(new Pair(_graph.packages[dep.name], childMap));
      }
    }
    _buffer.write(tree.fromMap(packageTree, showAllChildren: true));
  }
  String _labelPackage(Package package) =>
      "${log.bold(package.name)} ${package.version}";
  Set<String> _getTransitiveDependencies() {
    var transitive = _graph.packages.keys.toSet();
    var root = entrypoint.root;
    transitive.remove(root.name);
    transitive.removeAll(root.dependencies.map((dep) => dep.name));
    transitive.removeAll(root.devDependencies.map((dep) => dep.name));
    transitive.removeAll(root.dependencyOverrides.map((dep) => dep.name));
    return transitive;
  }
}
