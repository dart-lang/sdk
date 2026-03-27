// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart'
    show PhysicalResourceProvider;
import 'package:analyzer/src/analysis_options/analysis_options_file.dart';
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/dart/analysis/context_root.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/lint/pub.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/util/yaml.dart';
import 'package:analyzer/src/utilities/extensions/file_system.dart';
import 'package:analyzer/src/workspace/basic.dart';
import 'package:analyzer/src/workspace/blaze.dart';
import 'package:analyzer/src/workspace/gn.dart';
import 'package:analyzer/src/workspace/pub.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:collection/collection.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

/// Returns a list of the context roots that should be used to analyze the
/// files that are included by the list of [includedPaths] and not excluded by
/// the list of [excludedPaths].
///
/// If an [optionsFile] is specified, then it is assumed to be the path to the
/// `analysis_options.yaml` file that should be used in place of the ones that
/// would be found by looking in the directories containing the context roots.
///
/// If a [packageConfigFile] is specified, then it is assumed to be the path
/// to the package config file that should be used in place of the one that
/// would be found by looking in the directories containing the context roots.
List<ContextRootImpl> locateContextRoots({
  required List<String> includedPaths,
  List<String> excludedPaths = const [],
  String? optionsFile,
  String? packageConfigFile,
  required ResourceProvider resourceProvider,
}) {
  File? defaultOptionsFile;
  if (optionsFile != null) {
    defaultOptionsFile = resourceProvider.getFile(optionsFile);
    if (!defaultOptionsFile.exists) {
      defaultOptionsFile = null;
    }
  }

  File? defaultPackageConfigFile;
  if (packageConfigFile != null) {
    defaultPackageConfigFile = resourceProvider.getFile(packageConfigFile);
    if (!defaultPackageConfigFile.exists) {
      defaultPackageConfigFile = null;
    }
  }

  var (includedFolders, includedFiles) = _resourcesFromPaths(
    includedPaths,
    resourceProvider,
  );
  var (excludedFolders, excludedFiles) = _resourcesFromPaths(
    excludedPaths,
    resourceProvider,
  );
  // Use the excluded folders and files to filter the included folders and
  // files.
  includedFolders = includedFolders
      .where(
        (Folder includedFolder) =>
            !includedFolder.isContainedInAny(excludedFolders),
      )
      .toList();
  includedFiles = includedFiles
      .where(
        (File includedFile) =>
            !includedFile.isContainedInAny(excludedFolders) &&
            !excludedFiles.contains(includedFile),
      )
      .toList();

  return _ContextLocator(
    resourceProvider: resourceProvider,
    defaultOptionsFile: defaultOptionsFile,
    defaultPackageConfigFile: defaultPackageConfigFile,
    excludedFolders: excludedFolders,
  )._locateRoots(
    includedFolders: includedFolders,
    includedFiles: includedFiles,
  );
}

/// Returns a list of [Folder]s and a list of [File]s containing all of the
/// resources in the given list of [paths] that exist and are not contained
/// within one of the folders.
(List<Folder>, List<File>) _resourcesFromPaths(
  List<String> paths,
  ResourceProvider resourceProvider,
) {
  List<Folder> folders = <Folder>[];
  List<File> files = <File>[];
  for (String path in _uniqueSortedPaths(paths)) {
    Resource resource = resourceProvider.getResource(path);
    if (resource is Folder) {
      folders.add(resource);
    } else if (resource is File) {
      files.add(resource);
    } else {
      // Internal error: unhandled kind of resource.
    }
  }
  return (folders, files);
}

/// Returns a list of paths that contains all of the unique elements from the
/// given list of [paths], sorted such that shorter paths are first.
List<String> _uniqueSortedPaths(List<String> paths) {
  Set<String> uniquePaths = Set<String>.from(paths);
  List<String> sortedPaths = uniquePaths.toList();
  sortedPaths.sort((a, b) => a.length - b.length);
  return sortedPaths;
}

/// Determines the list of analysis contexts that can be used to analyze the
/// files and folders that should be analyzed given a list of included files and
/// folders and a list of excluded files and folders.
class _ContextLocator {
  /// The resource provider used to access the file system.
  final ResourceProvider _resourceProvider;

  final File? _defaultOptionsFile;

  final File? _defaultPackageConfigFile;

  final List<Folder> _excludedFolders;

  /// The list of context roots ultimately returned by [_locateRoots].
  final _roots = <ContextRootImpl>[];

  /// Initialize a newly created context locator. If a [resourceProvider] is
  /// supplied, it will be used to access the file system. Otherwise the default
  /// resource provider will be used.
  _ContextLocator({
    required ResourceProvider? resourceProvider,
    required File? defaultOptionsFile,
    required File? defaultPackageConfigFile,
    required List<Folder> excludedFolders,
  }) : _resourceProvider =
           resourceProvider ?? PhysicalResourceProvider.INSTANCE,
       _defaultOptionsFile = defaultOptionsFile,
       _defaultPackageConfigFile = defaultPackageConfigFile,
       _excludedFolders = excludedFolders;

  /// Returns the location of a context root for a file in the [parent].
  ///
  /// If [_defaultOptionsFile] is non-`null`, it will be used, not a file found
  /// relative to the [parent].
  ///
  /// If [_defaultPackageConfigFile] is non-`null`, it will be used, not a file
  /// found relative to the [parent].
  ///
  /// The root folder of the context is the parent of either the options, or the
  /// grand-parent of the `.dart_tool/package_config.json` file, whichever is
  /// lower.
  _RootLocation _contextRootLocation(
    Folder parent, {
    required Folder Function() defaultRootFolder,
  }) {
    File? optionsFile;
    Folder? optionsFolderToChooseRoot;
    if (_defaultOptionsFile != null) {
      optionsFile = _defaultOptionsFile;
    } else {
      optionsFile = parent.findAnalysisOptionsYamlFile();
      optionsFolderToChooseRoot = optionsFile?.parent;
    }

    File? packageConfigFile;
    Folder? packagesFolderToChooseRoot;
    if (_defaultPackageConfigFile != null) {
      packageConfigFile = _defaultPackageConfigFile;
      // If the packages file is in .dart_tool directory, use the grandparent
      // folder, else use the parent folder.
      packagesFolderToChooseRoot =
          _findFolderWithPackageConfigFile(packageConfigFile.parent) ??
          packageConfigFile.parent;
    }

    var buildGnFile = _findBuildGnFile(parent);

    var rootFolder = _lowest([optionsFolderToChooseRoot, buildGnFile?.parent]);

    // If default packages file is given, create workspace for it.
    var workspace = _createWorkspace(
      folder: parent,
      packageConfigFile: packageConfigFile,
      buildGnFile: buildGnFile,
    );

    if (workspace is! BasicWorkspace) {
      rootFolder = _lowest([
        rootFolder,
        _resourceProvider.getFolder(workspace.root),
      ]);
    }

    if (workspace is PackageConfigWorkspace) {
      packageConfigFile ??= workspace.packageConfigFile;
      // If the default packages folder is a parent of the workspace root,
      // choose that as the root.
      if (rootFolder != null && packagesFolderToChooseRoot != null) {
        if (packagesFolderToChooseRoot.contains(rootFolder.path)) {
          rootFolder = packagesFolderToChooseRoot;
        }
      }
    }

    if (rootFolder == null) {
      rootFolder = defaultRootFolder();
      if (workspace is BasicWorkspace) {
        workspace = _createWorkspace(
          folder: rootFolder,
          packageConfigFile: packageConfigFile,
          buildGnFile: buildGnFile,
        );
      }
    }

    return _RootLocation(
      rootFolder: rootFolder,
      workspace: workspace,
      optionsFile: optionsFile,
      packageConfigFile: packageConfigFile,
    );
  }

  ContextRootImpl _createContextRoot({
    required Folder rootFolder,
    required File? optionsFile,
    required _RootLocation location,
  }) {
    if (location.workspace is WorkspaceWithDefaultAnalysisOptions) {
      optionsFile ??= _findDefaultOptionsFile(
        location.workspace.partialSourceFactory,
      );
    }

    var root = ContextRootImpl(
      _resourceProvider,
      rootFolder,
      location.workspace,
      optionsFile: optionsFile,
      packagesFile: location.packageConfigFile,
    );
    if (optionsFile != null) {
      root.optionsFileMap.putIfAbsent(optionsFile, () => {}).add(rootFolder);
    }

    root.excludedGlobs.addAll(
      _getExcludedGlobs(optionsFile, location.workspace.partialSourceFactory),
    );
    _roots.add(root);
    return root;
  }

  /// If the given [folder] should be the root of a new analysis context, then
  /// creates a new context root for it and add it to the list of context
  /// [_roots]. The [containingRoot] is the context root from an enclosing
  /// directory and is used to inherit configuration information that isn't
  /// overridden.
  ///
  /// If either the [_defaultOptionsFile] or [_defaultPackageConfigFile] is
  /// non-`null`, then the given file is used even if there is a local version
  /// of the file.
  ///
  /// For each directory within the given [folder] that is neither in the list
  /// of [_excludedFolders] nor excluded by the `containingRoot.excludedGlobs`,
  /// recursively searches for nested context roots.
  ///
  /// Returns true if the folder was contained in the root and did not create a
  /// new root, false if it did create a new root.
  bool _createContextRoots(
    Set<String> visited,
    Folder folder,
    ContextRootImpl containingRoot,
    Set<String> containingRootEnabledLegacyPlugins, {
    File? optionsFileFromParentInSameRoot,
  }) {
    var packageConfigFileToUse =
        _defaultPackageConfigFile ??
        _getPackageConfigFile(folder) ??
        containingRoot.packagesFile;
    var buildGnFile = folder.getExistingFile(file_paths.buildGn);

    var optionsFileToUse = _defaultOptionsFile;
    if (optionsFileToUse == null) {
      optionsFileToUse = folder.existingAnalysisOptionsYamlFile;
      // If this folder doesn't have one use the one from a parent folder if any,
      // that will be the one we find anyway.
      optionsFileToUse ??= optionsFileFromParentInSameRoot;
      if (optionsFileToUse == null) {
        var parentFolder = folder.parent;
        while (parentFolder != containingRoot.root) {
          optionsFileToUse = parentFolder.existingAnalysisOptionsYamlFile;
          if (optionsFileToUse != null) {
            break;
          }
          parentFolder = parentFolder.parent;
        }
      }
    }

    var localEnabledPlugins = _getEnabledLegacyPlugins(
      containingRoot.workspace,
      optionsFileToUse,
    );
    // Legacy plugins differ only if there is an analysis_options and it
    // contains a different set of plugins from the containing context.
    var pluginsDiffer =
        optionsFileToUse != null &&
        !const SetEquality<String>().equals(
          containingRootEnabledLegacyPlugins,
          localEnabledPlugins,
        );

    bool usedThisRoot = true;

    // Create a context root for the given [folder] if a packages or build file
    // is locally specified, or the set of enabled legacy plugins changed.
    if (pluginsDiffer ||
        packageConfigFileToUse != containingRoot.packagesFile ||
        buildGnFile != null) {
      var workspace = _createWorkspace(
        folder: folder,
        packageConfigFile: packageConfigFileToUse,
        buildGnFile: buildGnFile,
      );
      var root = ContextRootImpl(
        _resourceProvider,
        folder,
        workspace,
        optionsFile: optionsFileToUse ?? containingRoot.optionsFile,
        packagesFile: packageConfigFileToUse,
      );
      root.included.add(folder);
      containingRoot.excluded.add(folder);
      _roots.add(root);
      containingRoot = root;
      containingRootEnabledLegacyPlugins = localEnabledPlugins;
      var excludedGlobs = _getExcludedGlobs(
        root.optionsFile,
        workspace.partialSourceFactory,
      );
      root.excludedGlobs.addAll(excludedGlobs);
      usedThisRoot = false;
    }

    if (optionsFileToUse != null &&
        optionsFileToUse != optionsFileFromParentInSameRoot) {
      containingRoot.optionsFileMap
          .putIfAbsent(optionsFileToUse, () => {})
          .add(folder);
      // Add excluded globs only if we found a new options file.
      var excludes = _getExcludedGlobs(
        optionsFileToUse,
        containingRoot.workspace.partialSourceFactory,
      );
      containingRoot.excludedGlobs.addAll(excludes);
    }
    _createContextRootsIn(
      visited,
      folder,
      containingRoot,
      containingRootEnabledLegacyPlugins,
      optionsFileToUseForFolder: usedThisRoot ? optionsFileToUse : null,
    );

    return usedThisRoot;
  }

  /// For each directory within the given [folder] that is neither in the list
  /// of [_excludedFolders] nor excluded by the `containingRoot.excludedGlobs`,
  /// recursively searches for nested context roots and add them to the list of
  /// [_roots].
  ///
  /// If either the [_defaultOptionsFile] or [_defaultPackageConfigFile] is
  /// non-`null`, then the given file will be used even if there is a local
  /// version of the file.
  void _createContextRootsIn(
    Set<String> visited,
    Folder folder,
    ContextRootImpl containingRoot,
    Set<String> containingRootEnabledLegacyPlugins, {
    File? optionsFileToUseForFolder,
  }) {
    bool isExcluded(Folder folder) {
      if (_excludedFolders.contains(folder) ||
          folder.shortName.startsWith('.')) {
        return true;
      }
      for (var pattern in containingRoot.excludedGlobs) {
        if (pattern.matches(folder.path)) {
          return true;
        }
      }
      return false;
    }

    List<Resource> children;
    try {
      // Stop infinite recursion via links.
      var canonicalFolderPath = folder.resolveSymbolicLinksSync().path;
      if (!visited.add(canonicalFolderPath)) {
        return;
      }
      // Check each of the subdirectories to see whether a context root needs to
      // be added for it.
      children = folder.getChildren();
    } on FileSystemException {
      // The directory either doesn't exist or cannot be read. Either way, there
      // are no subdirectories that need to be added.
      return;
    }

    for (Resource child in children) {
      if (child is Folder) {
        if (_excludedFolders.contains(child)) {
          containingRoot.excluded.add(child);
        } else if (!isExcluded(child)) {
          _createContextRoots(
            visited,
            child,
            containingRoot,
            containingRootEnabledLegacyPlugins,
            optionsFileFromParentInSameRoot: optionsFileToUseForFolder,
          );
        }
      }
    }
  }

  Workspace _createWorkspace({
    required Folder folder,
    required File? packageConfigFile,
    required File? buildGnFile,
  }) {
    if (buildGnFile != null) {
      var workspace = GnWorkspace.find(buildGnFile);
      if (workspace != null) {
        return workspace;
      }
    }

    Packages packages;
    if (packageConfigFile != null) {
      packages = parsePackageConfigJsonFile(
        _resourceProvider,
        packageConfigFile,
      );
    } else {
      packages = Packages.empty;
    }

    var rootPath = folder.path;

    Workspace? workspace;
    workspace = BlazeWorkspace.find(
      _resourceProvider,
      rootPath,
      lookForBuildFileSubstitutes: false,
    );
    workspace = _mostSpecificWorkspace(
      workspace,
      PackageConfigWorkspace.find(_resourceProvider, packages, rootPath),
    );
    workspace ??= BasicWorkspace.find(_resourceProvider, packages, rootPath);
    return workspace;
  }

  File? _findBuildGnFile(Folder folder) {
    for (var current in folder.withAncestors) {
      var file = current.getExistingFile(file_paths.buildGn);
      if (file != null) {
        return file;
      }
    }
    return null;
  }

  File? _findDefaultOptionsFile(SourceFactory sourceFactory) {
    var uriStr = WorkspaceWithDefaultAnalysisOptions.uri;
    var path = sourceFactory.forUri(uriStr)?.fullName;
    if (path != null) {
      var file = _resourceProvider.getFile(path);
      if (file.exists) {
        return file;
      }
    }
    return null;
  }

  /// Returns the folder containing the `.dart_tool/` folder which contains the
  /// package config file to be used to analyze files in the given [folder], or
  /// `null` if there is no package config file in the given folder or any
  /// parent folder.
  Folder? _findFolderWithPackageConfigFile(Folder folder) {
    for (var current in folder.withAncestors) {
      var file = _getPackageConfigFile(current);
      if (file != null) {
        return current;
      }
    }
    return null;
  }

  /// Gets the set of enabled legacy plugins for [optionsFile], taking into
  /// account any includes.
  Set<String> _getEnabledLegacyPlugins(Workspace workspace, File? optionsFile) {
    if (optionsFile == null) {
      return const {};
    }
    try {
      var provider = AnalysisOptionsProvider(workspace.partialSourceFactory);

      var options = AnalysisOptionsImpl.fromYaml(
        optionsMap: provider.getOptionsFromFile(optionsFile),
        file: optionsFile,
        resourceProvider: _resourceProvider,
      );

      return options.enabledLegacyPluginNames.toSet();
    } catch (_) {
      // No legacy plugins will be enabled if the file doesn't parse or cannot
      // be read for any reason.
      return {};
    }
  }

  /// Return a list containing the glob patterns used to exclude files from
  /// analysis by the given [optionsFile]. The list will be empty if there is no
  /// options file or if there are no exclusion patterns in the options file.
  List<LocatedGlob> _getExcludedGlobs(
    File? optionsFile,
    SourceFactory sourceFactory,
  ) {
    if (optionsFile == null) return const [];

    YamlMap options;
    try {
      options = AnalysisOptionsProvider(
        sourceFactory,
      ).getOptionsFromFile(optionsFile);
    } catch (exception) {
      // If we can't read and parse the analysis options file, then there
      // aren't any excluded files that need to be read.
      return const [];
    }

    var analyzerOptions = options.valueAt(AnalysisOptionsFile.analyzer);
    if (analyzerOptions is! YamlMap) return const [];
    var excludeOptions = analyzerOptions.valueAt(AnalysisOptionsFile.exclude);
    if (excludeOptions is! YamlList) return const [];
    var pathContext = _resourceProvider.pathContext;
    List<LocatedGlob> patterns = [];

    void addGlob(List<String> components) {
      var pattern = posix.joinAll(components);
      patterns.add(
        LocatedGlob(optionsFile.parent, Glob(pattern, context: pathContext)),
      );
    }

    for (String excludedPath in excludeOptions.whereType<String>()) {
      var excludedComponents = posix.split(excludedPath);
      addGlob(excludedComponents);
      if (excludedComponents.length > 1 && excludedComponents.last == '**') {
        addGlob(excludedComponents..removeLast());
      }
    }

    return patterns;
  }

  /// Returns the package config file in the given [folder], or `null` if the
  /// folder does not contain a package config file.
  File? _getPackageConfigFile(Folder folder) {
    var file = folder
        .getChildAssumingFolder(file_paths.dotDartTool)
        .getChildAssumingFile(file_paths.packageConfigJson);
    if (file.exists) {
      return file;
    }

    return null;
  }

  /// Load the `workspace` paths from the pubspec file in the given [root].
  ///
  /// From https://dart.dev/tools/pub/workspaces a root folder pubspec file will
  /// look like this:
  ///
  /// ```
  /// name: _
  /// publish_to: none
  /// environment:
  ///   sdk: ^3.6.0
  /// workspace:
  ///   - packages/helper
  ///   - packages/client_package
  ///   - packages/server_package
  /// ```
  ///
  /// This loads the paths from the `workspace` entry and return them as
  /// Folders if they exist as folders in the filesystem.
  Set<Folder> _loadWorkspaceDetailsFromPubspec(String root) {
    var result = <Folder>{};
    var rootFolder = _resourceProvider.getFolder(root);
    var rootPubspecFile = rootFolder.getChildAssumingFile(
      file_paths.pubspecYaml,
    );
    if (rootPubspecFile.exists) {
      var rootPubspec = Pubspec.parse(
        rootPubspecFile.readAsStringSync(),
        resourceProvider: _resourceProvider,
      );
      var workspace = rootPubspec.workspace;
      if (workspace != null) {
        for (var entry in workspace) {
          if (entry.text case var relativePath?) {
            var child = rootFolder.getChild(relativePath);
            if (child.exists && child is Folder) {
              result.add(child);
            }
          }
        }
      }
    }
    return result;
  }

  /// For each resource in [includedFolders] and [includedFiles], walks the
  /// directory structure, creates context roots, and returns them.
  List<ContextRootImpl> _locateRoots({
    required List<Folder> includedFolders,
    required List<File> includedFiles,
  }) {
    var (workspaceResolutionRootMap, nonWorkspaceResolutionFolders) =
        _sortIncludedFoldersIntoWorkspaceResolutions(includedFolders);

    for (var MapEntry(key: workspaceRoot, value: workspaceFolders)
        in workspaceResolutionRootMap.entries) {
      var workspaceRootFolder = _resourceProvider.getFolder(workspaceRoot);
      var location = _contextRootLocation(
        workspaceRootFolder,
        defaultRootFolder: () => workspaceRootFolder,
      );

      ContextRootImpl root = _createContextRoot(
        rootFolder: workspaceRootFolder,
        optionsFile: location.optionsFile,
        location: location,
      );

      var rootEnabledLegacyPlugins = _getEnabledLegacyPlugins(
        location.workspace,
        location.optionsFile,
      );

      Set<String> visited = {};
      bool usedRoot = false;

      for (var folder in workspaceFolders) {
        if (!root.isAnalyzed(folder.path)) {
          root.included.add(folder);
        }

        usedRoot |= _createContextRoots(
          visited,
          folder,
          root,
          rootEnabledLegacyPlugins,
        );
      }
      if (!usedRoot) {
        // If all included folders under this workspace resolution ended up
        // creating new contexts remove the (not used) root.
        _roots.remove(root);
      }
    }

    for (Folder folder in nonWorkspaceResolutionFolders) {
      var location = _contextRootLocation(
        folder,
        defaultRootFolder: () => folder,
      );

      ContextRootImpl? root;
      // Check whether there are existing roots that overlap with this one.
      for (var existingRoot in _roots) {
        if (existingRoot.root.isOrContains(folder.path)) {
          if (_matchRootWithLocation(existingRoot, location)) {
            // This root is covered exactly by the existing root (with the same
            // options/packages file) so we can simple use it.
            root = existingRoot;
            break;
          } else {
            // This root is within another (but doesn't share options/packages)
            // so we still need a new root. However, we should exclude this
            // from the existing root so these files aren't analyzed by both.
            //
            // It's possible this folder is already excluded (for example
            // because it's also a project and had a context root created as
            // part of the parent analysis root).
            if (!existingRoot.excluded.contains(folder)) {
              existingRoot.excluded.add(folder);
            }
          }
        }
      }

      root ??= _createContextRoot(
        rootFolder: folder,
        optionsFile: location.optionsFile,
        location: location,
      );

      if (!root.isAnalyzed(folder.path)) {
        root.included.add(folder);
      }

      var rootEnabledLegacyPlugins = _getEnabledLegacyPlugins(
        location.workspace,
        location.optionsFile,
      );

      _createContextRootsIn({}, folder, root, rootEnabledLegacyPlugins);
    }

    for (File file in includedFiles) {
      Folder parent = file.parent;

      var location = _contextRootLocation(
        parent,
        defaultRootFolder: () => _fileSystemRoot(parent),
      );

      ContextRootImpl? root;
      for (var existingRoot in _roots) {
        if (existingRoot.root.isOrContains(file.path) &&
            _matchRootWithLocation(existingRoot, location)) {
          root = existingRoot;
          break;
        }
      }

      root ??= _createContextRoot(
        rootFolder: location.rootFolder,
        optionsFile: location.optionsFile,
        location: location,
      );

      if (!root.isAnalyzed(file.path)) {
        root.included.add(file);
      }
    }
    return _roots;
  }

  /// Sorts [includedFolders] into either pub workspace resolution or not.
  ///
  /// For each [Folder] in [includedFolders], sorts into either
  /// `nonWorkspaceResolutionFolders` or `workspaceResolutionRootMap` depending
  /// on `pubspec.yaml` specifications.
  ///
  /// Folders with `pubspec.yaml` files with a `resolution: workspace` setting
  /// that matches a root-folders `pubspec.yaml` file's `workspace` list is
  /// sorted into the `workspaceResolutionRootMap` map. Other folders end up in
  /// `nonWorkspaceResolutionFolders`.
  (Map<String, List<Folder>>, List<Folder>)
  _sortIncludedFoldersIntoWorkspaceResolutions(List<Folder> includedFolders) {
    var workspaceResolutionRootMap = <String, List<Folder>>{};
    var nonWorkspaceResolutionFolders = <Folder>[];
    var rootWorkspaceSpecification = <String, Set<Folder>>{};
    for (Folder folder in includedFolders) {
      var location = _contextRootLocation(
        folder,
        defaultRootFolder: () => folder,
      );

      var addedToWorkspace = false;

      if (folder.path == location.workspace.root) {
        // If opening the root don't try to do anything special.
        var known = rootWorkspaceSpecification[location.workspace.root] ??= {};
        known.clear();
        nonWorkspaceResolutionFolders.addAll(
          workspaceResolutionRootMap[location.workspace.root] ?? [],
        );
      } else {
        var pubspecFile = folder.getChildAssumingFile(file_paths.pubspecYaml);
        if (pubspecFile.exists) {
          var pubspec = Pubspec.parse(
            pubspecFile.readAsStringSync(),
            resourceProvider: _resourceProvider,
          );
          var resolution = pubspec.resolution;
          if (resolution != null && resolution.value.text == 'workspace') {
            var known = rootWorkspaceSpecification[location.workspace.root] ??=
                _loadWorkspaceDetailsFromPubspec(location.workspace.root);
            if (known.contains(folder)) {
              (workspaceResolutionRootMap[location.workspace.root] ??= []).add(
                folder,
              );
              addedToWorkspace = true;
            }
          }
        }
      }
      if (!addedToWorkspace) {
        nonWorkspaceResolutionFolders.add(folder);
      }
    }

    return (workspaceResolutionRootMap, nonWorkspaceResolutionFolders);
  }

  static Folder _fileSystemRoot(Resource resource) {
    for (var current = resource.parent; ; current = current.parent) {
      if (current.isRoot) {
        return current;
      }
    }
  }

  /// Every element in [folders] must be a folder on the path from a file to
  /// the root of the file system. As such, they are either the same folder,
  /// or one is strictly above the other.
  static Folder? _lowest(List<Folder?> folders) {
    return folders.fold<Folder?>(null, (result, folder) {
      if (result == null) {
        return folder;
      } else if (folder != null && result.contains(folder.path)) {
        return folder;
      } else {
        return result;
      }
    });
  }

  /// Return `true` if the configuration of [existingRoot] is the same as
  /// the requested configuration for the [location].
  static bool _matchRootWithLocation(
    ContextRootImpl existingRoot,
    _RootLocation location,
  ) {
    if (existingRoot.optionsFile != location.optionsFile) {
      return false;
    }

    if (existingRoot.packagesFile != location.packageConfigFile) {
      return false;
    }

    // BasicWorkspace has no special meaning, so can be ignored.
    // Other workspaces have semantic meaning, so must match.
    var workspace = location.workspace;
    if (workspace is! BasicWorkspace) {
      if (existingRoot.workspace.root != workspace.root) {
        return false;
      }
    }

    return true;
  }

  /// Picks a workspace with the most specific root.
  ///
  /// If any of [first] and [second] is null, returns the other one. If the root
  /// of [first] is non-null and is within the root of [second], returns
  /// [second]. If the roots aren't within each other, return [first].
  static Workspace? _mostSpecificWorkspace(
    Workspace? first,
    Workspace? second,
  ) {
    if (first == null) return second;
    if (second == null) return first;
    return isWithin(first.root, second.root) ? second : first;
  }
}

class _RootLocation {
  final Folder rootFolder;
  final Workspace workspace;
  final File? optionsFile;
  final File? packageConfigFile;

  _RootLocation({
    required this.rootFolder,
    required this.workspace,
    required this.optionsFile,
    required this.packageConfigFile,
  });
}

extension on Resource {
  /// Returns whether this Resource is contained in any of the [folders].
  bool isContainedInAny(Iterable<Folder> folders) =>
      folders.any((Folder folder) => folder.contains(path));
}
