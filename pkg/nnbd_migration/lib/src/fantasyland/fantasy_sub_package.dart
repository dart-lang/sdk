// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/lint/pub.dart';
import 'package:nnbd_migration/src/fantasyland/fantasy_repo.dart';
import 'package:nnbd_migration/src/fantasyland/fantasy_workspace_impl.dart';
import 'package:path/path.dart' as path;

final Map<String, FantasySubPackageSettings> _subPackageTable = {
  '_fe_analyzer_shared': FantasySubPackageSettings(
      '_fe_analyzer_shared', FantasyRepoSettings.fromName('sdk'),
      subDir: path.join('pkg', '_fe_analyzer_shared')),
  'analysis_tool': FantasySubPackageSettings(
      'analysis_tool', FantasyRepoSettings.fromName('sdk'),
      subDir: path.join('pkg', 'analysis_tool')),
  'analyzer': FantasySubPackageSettings(
      'analyzer', FantasyRepoSettings.fromName('sdk'),
      subDir: path.join('pkg', 'analyzer')),
  'build': FantasySubPackageSettings(
      'build', FantasyRepoSettings.fromName('build'),
      subDir: 'build'),
  'build_config': FantasySubPackageSettings(
      'build_config', FantasyRepoSettings.fromName('build'),
      subDir: 'build_config'),
  'build_daemon': FantasySubPackageSettings(
      'build_daemon', FantasyRepoSettings.fromName('build'),
      subDir: 'build_daemon'),
  'build_integration': FantasySubPackageSettings(
      'build_integration', FantasyRepoSettings.fromName('sdk'),
      subDir: path.join('pkg', 'build_integration')),
  'build_modules': FantasySubPackageSettings(
      'build_modules', FantasyRepoSettings.fromName('build'),
      subDir: 'build_modules'),
  'build_node_compilers': FantasySubPackageSettings(
      'build_node_compilers', FantasyRepoSettings.fromName('node-interop'),
      subDir: 'build_node_compilers'),
  'build_resolvers': FantasySubPackageSettings(
      'build_resolvers', FantasyRepoSettings.fromName('build'),
      subDir: 'build_resolvers'),
  'build_runner': FantasySubPackageSettings(
      'build_runner', FantasyRepoSettings.fromName('build'),
      subDir: 'build_runner'),
  'build_runner_core': FantasySubPackageSettings(
      'build_runner_core', FantasyRepoSettings.fromName('build'),
      subDir: 'build_runner_core'),
  'build_test': FantasySubPackageSettings(
      'build_test', FantasyRepoSettings.fromName('build'),
      subDir: 'build_test'),
  'build_vm_compilers': FantasySubPackageSettings(
      'build_vm_compilers', FantasyRepoSettings.fromName('build'),
      subDir: 'build_vm_compilers'),
  'build_web_compilers': FantasySubPackageSettings(
      'build_web_compilers', FantasyRepoSettings.fromName('build'),
      subDir: 'build_web_compilers'),
  'built_collection': FantasySubPackageSettings('built_collection',
      FantasyRepoSettings.fromName('built_collection.dart')),
  'built_value': FantasySubPackageSettings(
      'built_value', FantasyRepoSettings.fromName('built_value.dart'),
      subDir: 'built_value'),
  'built_value_generator': FantasySubPackageSettings(
      'built_value_generator', FantasyRepoSettings.fromName('built_value.dart'),
      subDir: 'built_value_generator'),
  'checked_yaml': FantasySubPackageSettings(
      'checked_yaml', FantasyRepoSettings.fromName('json_serializable'),
      subDir: 'checked_yaml'),
  'expect': FantasySubPackageSettings(
      'expect', FantasyRepoSettings.fromName('sdk'),
      subDir: path.join('pkg', 'expect')),
  'front_end': FantasySubPackageSettings(
      'front_end', FantasyRepoSettings.fromName('sdk'),
      subDir: path.join('pkg', 'front_end')),
  'grinder': FantasySubPackageSettings(
      'grinder', FantasyRepoSettings.fromName('grinder.dart')),
  'kernel': FantasySubPackageSettings(
      'kernel', FantasyRepoSettings.fromName('sdk'),
      subDir: path.join('pkg', 'kernel')),
  'meta': FantasySubPackageSettings('meta', FantasyRepoSettings.fromName('sdk'),
      subDir: path.join('pkg', 'meta')),
  'node_interop': FantasySubPackageSettings(
      'node_interop', FantasyRepoSettings.fromName('node-interop'),
      subDir: 'node_interop'),
  'node_io': FantasySubPackageSettings(
      'node_io', FantasyRepoSettings.fromName('node-interop'),
      subDir: 'node_io'),
  'js': FantasySubPackageSettings('js', FantasyRepoSettings.fromName('sdk'),
      subDir: path.join('pkg', 'js')),
  'json_annotation': FantasySubPackageSettings(
      'json_annotation', FantasyRepoSettings.fromName('json_serializable'),
      subDir: 'json_annotation'),
  'json_serializable': FantasySubPackageSettings(
      'json_serializable', FantasyRepoSettings.fromName('json_serializable'),
      subDir: 'json_serializable'),
  'package_config': FantasySubPackageSettings(
      'package_config', FantasyRepoSettings.fromName('package_config')),
  'protobuf': FantasySubPackageSettings(
      'protobuf', FantasyRepoSettings.fromName('protobuf'),
      subDir: 'protobuf'),
  'scratch_space': FantasySubPackageSettings(
      'scratch_space', FantasyRepoSettings.fromName('build'),
      subDir: 'scratch_space'),
  'source_gen': FantasySubPackageSettings(
      'source_gen', FantasyRepoSettings.fromName('source_gen'),
      subDir: 'source_gen'),
  'source_gen_test': FantasySubPackageSettings(
      'source_gen_test', FantasyRepoSettings.fromName('source_gen_test')),
  'test': FantasySubPackageSettings(
      'test', FantasyRepoSettings.fromName('test'),
      subDir: path.join('pkgs', 'test')),
  'test_api': FantasySubPackageSettings(
      'test_api', FantasyRepoSettings.fromName('test'),
      subDir: path.join('pkgs', 'test_api')),
  'test_core': FantasySubPackageSettings(
      'test_core', FantasyRepoSettings.fromName('test'),
      subDir: path.join('pkgs', 'test_core')),
  'testing': FantasySubPackageSettings(
      'testing', FantasyRepoSettings.fromName('sdk'),
      subDir: path.join('pkg', 'testing')),
  'vm_service': FantasySubPackageSettings(
      'vm_service', FantasyRepoSettings.fromName('sdk'),
      subDir: path.join('pkg', 'vm_service')),
  'quiver': FantasySubPackageSettings(
      'quiver', FantasyRepoSettings.fromName('quiver-dart')),
};

/// Data class containing settings for a package within a [FantasyWorkspaceImpl].
class FantasySubPackageSettings {
  final String name;
  final FantasyRepoSettings repoSettings;
  final String subDir;

  FantasySubPackageSettings(this.name, this.repoSettings, {this.subDir: '.'});

  /// Build settings just from a name in a mostly-hardcoded table.
  factory FantasySubPackageSettings.fromName(String name) {
    if (_subPackageTable.containsKey(name)) {
      return _subPackageTable[name];
    }
    return FantasySubPackageSettings(name, FantasyRepoSettings.fromName(name));
  }

  /// Build [FantasySubPackageSettings] from the dependency of a given subPackage.
  factory FantasySubPackageSettings.fromDependency(
      FantasySubPackage subPackage, PSDependency dependency) {
    if (dependency.host != null)
      throw UnimplementedError(
          'fromDependency: contains a host field:  $dependency');
    if (dependency.git != null)
      throw UnimplementedError(
          'fromDependency: contains a git field:  $dependency');
    if (dependency.path != null) {
      return FantasySubPackageSettings.fromNested(
          dependency.name.text, subPackage, dependency.path.value.text);
    }
    // Hopefully, a version is declared at least... but if not proceed onward
    // and hope building from name works if we aren't running with asserts.
    assert(dependency.version != null);
    return FantasySubPackageSettings.fromName(dependency.name.text);
  }

  /// Build settings for a nested package based on the repository settings
  /// of an existing package.
  ///
  /// [subDir] is resolved relative to [parent.packageRoot].
  factory FantasySubPackageSettings.fromNested(
      String name, FantasySubPackage parent, String subDir) {
    var pathContext = parent.resourceProvider.pathContext;
    String nestedSubdir;
    if (pathContext.isRelative(subDir)) {
      nestedSubdir = pathContext
          .normalize(pathContext.join(parent.packageRoot.path, subDir));
    } else {
      nestedSubdir = pathContext.normalize(subDir);
    }
    assert(pathContext.isWithin(parent.packageRoot.path, nestedSubdir));
    return FantasySubPackageSettings(name, parent.containingRepo.repoSettings,
        subDir: pathContext.relative(nestedSubdir,
            from: parent.containingRepo.repoRoot.path));
  }

  @override
  int get hashCode => toString().hashCode;

  @override
  bool operator ==(other) {
    return other is FantasySubPackageSettings &&
        (other.name == name &&
            other.repoSettings == repoSettings &&
            other.subDir == subDir);
  }

  @override
  String toString() =>
      'FantasySubPackageSettings("$name", ${repoSettings.toString()}, "$subDir")';
}

class _AccumulateDependenciesVisitor<T> extends PubspecVisitor {
  final T Function(PSDependency) transformDependency;
  final List<T> results = [];

  _AccumulateDependenciesVisitor(this.transformDependency);

  void visitPackageDependency(PSDependency dependency) =>
      results.add(transformDependency(dependency));
}

class _AccumulateAllDependenciesVisitor<T>
    extends _AccumulateDependenciesVisitor<T> {
  _AccumulateAllDependenciesVisitor(
      T Function(PSDependency) transformDependency)
      : super(transformDependency);

  void visitPackageDevDependency(PSDependency dependency) =>
      results.add(transformDependency(dependency));
}

class FantasySubPackageDependencies {
  final ResourceProvider resourceProvider;
  File Function(String) get fileBuilder => resourceProvider.getFile;

  FantasySubPackageDependencies({ResourceProvider resourceProvider})
      : resourceProvider =
            resourceProvider ?? PhysicalResourceProvider.INSTANCE;

  factory FantasySubPackageDependencies.fromWorkspaceDependencies(
      FantasyWorkspaceDependencies workspaceDependencies) {
    return FantasySubPackageDependencies(
        resourceProvider: workspaceDependencies.resourceProvider);
  }
}

/// Represents one package within a [FantasyWorkspaceImpl].
///
/// A `FantasySubPackage` differs from a normal package in that Dart code within
/// it depends on a global .packages file to resolve symbols.
class FantasySubPackage {
  final FantasyRepo containingRepo;
  final String name;
  final FantasySubPackageSettings packageSettings;
  final ResourceProvider resourceProvider;

  FantasySubPackage(this.packageSettings, this.containingRepo,
      {ResourceProvider resourceProvider})
      : name = packageSettings.name,
        resourceProvider =
            resourceProvider ?? PhysicalResourceProvider.INSTANCE;

  Folder _packageRoot;
  Folder get packageRoot => _packageRoot ??= resourceProvider.getFolder(
      resourceProvider.pathContext.normalize(resourceProvider.pathContext
          .join(containingRepo.repoRoot.path, packageSettings.subDir)));

  Future<void> _acceptPubspecVisitor<T>(
      PubspecVisitor<T> pubspecVisitor) async {
    File pubspecYaml = resourceProvider.getFile(
        resourceProvider.pathContext.join(packageRoot.path, 'pubspec.yaml'));
    if (!pubspecYaml.exists) return;
    Pubspec pubspec = Pubspec.parse(pubspecYaml.readAsStringSync(),
        sourceUrl: resourceProvider.pathContext.toUri(pubspecYaml.path));
    pubspec.accept(pubspecVisitor);
  }

  Future<List<FantasySubPackageSettings>> getPackageDependencies() async {
    var visitor = _AccumulateDependenciesVisitor(
        (d) => FantasySubPackageSettings.fromDependency(this, d));
    await _acceptPubspecVisitor(visitor);
    return visitor.results;
  }

  Future<List<FantasySubPackageSettings>> getPackageAllDependencies() async {
    var visitor = _AccumulateAllDependenciesVisitor(
        (d) => FantasySubPackageSettings.fromDependency(this, d));
    await _acceptPubspecVisitor(visitor);
    return visitor.results;
  }
}
