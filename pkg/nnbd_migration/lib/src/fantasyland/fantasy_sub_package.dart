// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/hint/sdk_constraint_extractor.dart';
import 'package:analyzer/src/lint/pub.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:nnbd_migration/src/fantasyland/fantasy_repo.dart';
import 'package:nnbd_migration/src/fantasyland/fantasy_workspace_impl.dart';
import 'package:path/path.dart' as path;
import 'package:pub/src/package_config.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:source_span/source_span.dart';
import 'package:yaml/yaml.dart';

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
  'webkit_inspection_protocol': FantasySubPackageSettings(
      'webkit_inspection_protocol',
      FantasyRepoSettings.fromName('webkit_inspection_protocol.dart')),
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

  String get languageVersion => extractLanguageVersion(versionConstraint);

  VersionConstraint _versionConstraint;
  VersionConstraint get versionConstraint =>
      _versionConstraint ??= SdkConstraintExtractor(pubspecYaml).constraint();

  File _pubspecYaml;
  File get pubspecYaml => _pubspecYaml ??= resourceProvider.getFile(
      resourceProvider.pathContext.join(packageRoot.path, 'pubspec.yaml'));

  Future<void> _acceptPubspecVisitor<T>(
      PubspecVisitor<T> pubspecVisitor) async {
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

  /// Delete any `pub get` output that interferes with a workspace.
  Future<void> cleanUp() async {
    File pubspecLock = packageRoot.getChildAssumingFile('pubspec.lock');
    File dotPackages = packageRoot.getChildAssumingFile('.packages');
    Folder dartTool = packageRoot.getChildAssumingFolder('.dart_tool');
    File packageConfigJson =
        dartTool.getChildAssumingFile('package_config.json');
    for (File f in [pubspecLock, dotPackages, packageConfigJson]) {
      if (f.exists) f.delete();
    }
  }

  void processYamlException(String operation, path, exception) {
    // TODO(jcollins-g): implement
  }

  static final RegExp _sdkConstraint = RegExp(r'^\s+sdk:\s+.*');

  Future<void> removeSdkConstraintHack() async {
    if (pubspecYaml.exists) {
      List<String> lines = pubspecYaml.readAsStringSync().split('\n');
      lines = lines.where((l) => !_sdkConstraint.hasMatch(l)).toList();
      pubspecYaml.writeAsStringSync(lines.join('\n'));
    }
    _pubspecYaml = null;
    _versionConstraint = null;
  }

  /// Modify all analysis_options.yaml file to include the nullability
  /// experiment.
  Future<void> enableExperimentHack() async {
    // This is completely bonkers, cut and paste from non_nullable_fix.dart.
    // But it is temporary, right?
    // TODO(jcollins-g): Remove this hack once no longer needed.
    File optionsFile =
        packageRoot.getChildAssumingFile('analysis_options.yaml');
    SourceChange sourceChange =
        SourceChange('fantasy_sub_package-experimenthack-$name');
    String optionsContent;
    YamlNode optionsMap;
    if (optionsFile.exists) {
      try {
        optionsContent = optionsFile.readAsStringSync();
      } on FileSystemException catch (e) {
        processYamlException('read', optionsFile.path, e);
        return;
      }
      try {
        optionsMap = loadYaml(optionsContent) as YamlNode;
      } on YamlException catch (e) {
        processYamlException('parse', optionsFile.path, e);
        return;
      }
    }

    SourceSpan parentSpan;
    String content;
    YamlNode analyzerOptions;
    if (optionsMap is YamlMap) {
      analyzerOptions = optionsMap.nodes[AnalyzerOptions.analyzer];
    }
    if (analyzerOptions == null) {
      var start = SourceLocation(0, line: 0, column: 0);
      parentSpan = SourceSpan(start, start, '');
      content = '''
analyzer:
  enable-experiment:
    - non-nullable

''';
    } else if (analyzerOptions is YamlMap) {
      YamlNode experiments =
          analyzerOptions.nodes[AnalyzerOptions.enableExperiment];
      if (experiments == null) {
        parentSpan = analyzerOptions.span;
        content = '''

  enable-experiment:
    - non-nullable''';
      } else if (experiments is YamlList) {
        experiments.nodes.firstWhere(
          (node) => node.span.text == EnableString.non_nullable,
          orElse: () {
            parentSpan = experiments.span;
            content = '''

    - non-nullable''';
            return null;
          },
        );
      }
    }

    if (parentSpan != null) {
      final space = ' '.codeUnitAt(0);
      final cr = '\r'.codeUnitAt(0);
      final lf = '\n'.codeUnitAt(0);

      int offset = parentSpan.end.offset;
      while (offset > 0) {
        int ch = optionsContent.codeUnitAt(offset - 1);
        if (ch == space || ch == cr) {
          --offset;
        } else if (ch == lf) {
          --offset;
        } else {
          break;
        }
      }
      SourceFileEdit fileEdit = SourceFileEdit(optionsFile.path, 0,
          edits: [SourceEdit(offset, 0, content)]);
      for (SourceEdit sourceEdit in fileEdit.edits) {
        sourceChange.addEdit(fileEdit.file, fileEdit.fileStamp, sourceEdit);
      }
    }
    _applyEdits(sourceChange);
  }

  void _applyEdits(SourceChange sourceChange) {
    for (var fileEdit in sourceChange.edits) {
      File toEdit = packageRoot.getChildAssumingFile(fileEdit.file);
      String contents = toEdit.exists ? toEdit.readAsStringSync() : '';
      for (SourceEdit edit in fileEdit.edits) {
        contents = edit.apply(contents);
      }
      toEdit.writeAsStringSync(contents);
    }
  }
}
