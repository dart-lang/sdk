// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:core';

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analyzer/context/context_root.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/plugin/resolver_provider.dart';
import 'package:analyzer/source/analysis_options_provider.dart';
import 'package:analyzer/source/package_map_provider.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/source/path_filter.dart';
import 'package:analyzer/source/pub_package_map_provider.dart';
import 'package:analyzer/source/sdk_ext.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer/src/context/context.dart' as context;
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:analyzer/src/util/absolute_path.dart';
import 'package:analyzer/src/util/glob.dart';
import 'package:analyzer/src/util/yaml.dart';
import 'package:package_config/packages.dart';
import 'package:package_config/packages_file.dart' as pkgfile show parse;
import 'package:package_config/src/packages_impl.dart' show MapPackages;
import 'package:path/path.dart' as pathos;
import 'package:watcher/watcher.dart';
import 'package:yaml/yaml.dart';

/**
 * Information tracked by the [ContextManager] for each context.
 */
class ContextInfo {
  /**
   * The [Folder] for which this information object is created.
   */
  final Folder folder;

  /// The [PathFilter] used to filter sources from being analyzed.
  final PathFilter pathFilter;

  /**
   * The enclosed pubspec-based contexts.
   */
  final List<ContextInfo> children = <ContextInfo>[];

  /**
   * The package root for this context, or null if there is no package root.
   */
  String packageRoot;

  /**
   * The [ContextInfo] that encloses this one, or `null` if this is the virtual
   * [ContextInfo] object that acts as the ancestor of all other [ContextInfo]
   * objects.
   */
  ContextInfo parent;

  /**
   * The package description file path for this context.
   */
  String packageDescriptionPath;

  /**
   * The folder disposition for this context.
   */
  final FolderDisposition disposition;

  /**
   * Paths to files which determine the folder disposition and package map.
   *
   * TODO(paulberry): if any of these files are outside of [folder], they won't
   * be watched for changes.  I believe the use case for watching these files
   * is no longer relevant.
   */
  Set<String> _dependencies = new Set<String>();

  /**
   * The analysis driver that was created for the [folder].
   */
  AnalysisDriver analysisDriver;

  /**
   * The analysis context that was created for the [folder].
   */
  AnalysisContext context;

  /**
   * Map from full path to the [Source] object, for each source that has been
   * added to the context.
   */
  Map<String, Source> sources = new HashMap<String, Source>();

  ContextInfo(ContextManagerImpl contextManager, this.parent, Folder folder,
      File packagespecFile, this.packageRoot, this.disposition)
      : folder = folder,
        pathFilter = new PathFilter(
            folder.path, null, contextManager.resourceProvider.pathContext) {
    packageDescriptionPath = packagespecFile.path;
    parent.children.add(this);
  }

  /**
   * Create the virtual [ContextInfo] which acts as an ancestor to all other
   * [ContextInfo]s.
   */
  ContextInfo._root()
      : folder = null,
        pathFilter = null,
        packageRoot = null,
        disposition = null;

  /**
   * Iterate through all [children] and their children, recursively.
   */
  Iterable<ContextInfo> get descendants sync* {
    for (ContextInfo child in children) {
      yield child;
      yield* child.descendants;
    }
  }

  /**
   * Returns `true` if this is a "top level" context, meaning that the folder
   * associated with it is not contained within any other folders that have an
   * associated context.
   */
  bool get isTopLevel => parent.parent == null;

  /**
   * Returns `true` if [path] is excluded, as it is in one of the children.
   */
  bool excludes(String path) {
    return children.any((child) {
      return child.folder.contains(path);
    });
  }

  /**
   * Returns `true` if [resource] is excluded, as it is in one of the children.
   */
  bool excludesResource(Resource resource) => excludes(resource.path);

  /**
   * Return the first [ContextInfo] in [children] whose associated folder is or
   * contains [path].  If there is no such [ContextInfo], return `null`.
   */
  ContextInfo findChildInfoFor(String path) {
    for (ContextInfo info in children) {
      if (info.folder.isOrContains(path)) {
        return info;
      }
    }
    return null;
  }

  /**
   * Determine if the given [path] is one of the dependencies most recently
   * passed to [setDependencies].
   */
  bool hasDependency(String path) => _dependencies.contains(path);

  /// Returns `true` if  [path] should be ignored.
  bool ignored(String path) => pathFilter.ignored(path);

  /**
   * Returns `true` if [path] is the package description file for this context
   * (pubspec.yaml or .packages).
   */
  bool isPathToPackageDescription(String path) =>
      path == packageDescriptionPath;

  /**
   * Update the set of dependencies for this context.
   */
  void setDependencies(Iterable<String> newDependencies) {
    _dependencies = newDependencies.toSet();
  }

  /**
   * Return `true` if the given [path] is managed by this context or by
   * any of its children.
   */
  bool _managesOrHasChildThatManages(String path) {
    if (parent == null) {
      for (ContextInfo child in children) {
        if (child._managesOrHasChildThatManages(path)) {
          return true;
        }
      }
      return false;
    } else {
      if (!folder.isOrContains(path)) {
        return false;
      }
      for (ContextInfo child in children) {
        if (child._managesOrHasChildThatManages(path)) {
          return true;
        }
      }
      return !pathFilter.ignored(path);
    }
  }
}

/**
 * Class that maintains a mapping from included/excluded paths to a set of
 * folders that should correspond to analysis contexts.
 */
abstract class ContextManager {
  // TODO(brianwilkerson) Support:
  //   setting the default analysis options
  //   setting the default content cache
  //   setting the default SDK
  //   maintaining AnalysisContext.folderMap (or remove it)
  //   telling server when a context has been added or removed (see onContextsChanged)
  //   telling server when a context needs to be re-analyzed
  //   notifying the client when results should be flushed
  //   using analyzeFileFunctions to determine which files to analyze
  //
  // TODO(brianwilkerson) Move this class to a public library.

  /**
   * Return the [AnalysisContext]s that are being used to analyze the analysis
   * roots.
   */
  Iterable<AnalysisContext> get analysisContexts;

  /**
   * Get the callback interface used to create, destroy, and update contexts.
   */
  ContextManagerCallbacks get callbacks;

  /**
   * Set the callback interface used to create, destroy, and update contexts.
   */
  void set callbacks(ContextManagerCallbacks value);

  /**
   * A table mapping [Folder]s to the [AnalysisDriver]s associated with them.
   */
  Map<Folder, AnalysisDriver> get driverMap;

  /**
   * Return the list of excluded paths (folders and files) most recently passed
   * to [setRoots].
   */
  List<String> get excludedPaths;

  /**
   * Return a table mapping [Folder]s to the [AnalysisContext]s associated with
   * them.
   */
  Map<Folder, AnalysisContext> get folderMap;

  /**
   * Return the list of included paths (folders and files) most recently passed
   * to [setRoots].
   */
  List<String> get includedPaths;

  /**
   * Return a list of all of the contexts reachable from the given
   * [analysisRoot] (the context associated with [analysisRoot] and all of its
   * descendants).
   */
  List<AnalysisContext> contextsInAnalysisRoot(Folder analysisRoot);

  /**
   * Like [getDriverFor] and [getContextFor], but returns the [Folder] which
   * allows plugins to create & manage their own tree of drivers just like using
   * [getDriverFor].
   *
   * This folder should be the root of analysis context, not just the containing
   * folder of the path (like basename), as this is NOT just a file API.
   *
   * This exists at least temporarily, for plugin support until the new API is
   * ready.
   */
  Folder getContextFolderFor(String path);

  /**
   * Return the [AnalysisContext] for the "innermost" context whose associated
   * folder is or contains the given path.  ("innermost" refers to the nesting
   * of contexts, so if there is a context for path /foo and a context for
   * path /foo/bar, then the innermost context containing /foo/bar/baz.dart is
   * the context for /foo/bar.)
   *
   * If no context contains the given path, `null` is returned.
   */
  AnalysisContext getContextFor(String path);

  /**
   * Return the [AnalysisDriver] for the "innermost" context whose associated
   * folder is or contains the given path.  ("innermost" refers to the nesting
   * of contexts, so if there is a context for path /foo and a context for
   * path /foo/bar, then the innermost context containing /foo/bar/baz.dart is
   * the context for /foo/bar.)
   *
   * If no driver contains the given path, `null` is returned.
   */
  AnalysisDriver getDriverFor(String path);

  /**
   * Return a list of all of the analysis drivers reachable from the given
   * [analysisRoot] (the driver associated with [analysisRoot] and all of its
   * descendants).
   */
  List<AnalysisDriver> getDriversInAnalysisRoot(Folder analysisRoot);

  /**
   * Return `true` if the given [path] is ignored by a [ContextInfo] whose
   * folder contains it.
   */
  bool isIgnored(String path);

  /**
   * Return `true` if the given absolute [path] is in one of the current
   * root folders and is not excluded.
   */
  bool isInAnalysisRoot(String path);

  /**
   * Rebuild the set of contexts from scratch based on the data last sent to
   * [setRoots]. Only contexts contained in the given list of analysis [roots]
   * will be rebuilt, unless the list is `null`, in which case every context
   * will be rebuilt.
   */
  void refresh(List<Resource> roots);

  /**
   * Change the set of paths which should be used as starting points to
   * determine the context directories.
   */
  void setRoots(List<String> includedPaths, List<String> excludedPaths,
      Map<String, String> packageRoots);
}

/**
 * Callback interface used by [ContextManager] to (a) request that contexts be
 * created, destroyed or updated, (b) inform the client when "pub list"
 * operations are in progress, and (c) determine which files should be
 * analyzed.
 *
 * TODO(paulberry): eliminate this interface, and instead have [ContextManager]
 * operations return data structures describing how context state should be
 * modified.
 */
abstract class ContextManagerCallbacks {
  /**
   * Create and return a new analysis driver rooted at the given [folder], with
   * the given analysis [options].
   */
  AnalysisDriver addAnalysisDriver(
      Folder folder, ContextRoot contextRoot, AnalysisOptions options);

  /**
   * Create and return a new analysis context rooted at the given [folder], with
   * the given analysis [options].
   */
  AnalysisContext addContext(Folder folder, AnalysisOptions options);

  /**
   * Called when the set of files associated with a context have changed (or
   * some of those files have been modified).  [changeSet] is the set of
   * changes that need to be applied to the context.
   */
  void applyChangesToContext(Folder contextFolder, ChangeSet changeSet);

  /**
   * The given [file] was removed from the folder analyzed in the [driver].
   */
  void applyFileRemoved(AnalysisDriver driver, String file);

  /**
   * Sent the given watch [event] to any interested plugins.
   */
  void broadcastWatchEvent(WatchEvent event);

  /**
   * Signals that the context manager has started to compute a package map (if
   * [computing] is `true`) or has finished (if [computing] is `false`).
   */
  void computingPackageMap(bool computing);

  /**
   * Create and return a context builder that can be used to create a context
   * for the files in the given [folder] when analyzed using the given [options].
   */
  ContextBuilder createContextBuilder(Folder folder, AnalysisOptions options);

  /**
   * Called when the context manager changes the folder with which a context is
   * associated. Currently this is mostly FYI, and used only in tests.
   */
  void moveContext(Folder from, Folder to);

  /**
   * Remove the context associated with the given [folder].  [flushedFiles] is
   * a list of the files which will be "orphaned" by removing this context
   * (they will no longer be analyzed by any context).
   */
  void removeContext(Folder folder, List<String> flushedFiles);

  /**
   * Called when the package resolution for the given [context] has changed.
   */
  void updateContextPackageUriResolver(AnalysisContext context);
}

/**
 * Class that maintains a mapping from included/excluded paths to a set of
 * folders that should correspond to analysis contexts.
 */
class ContextManagerImpl implements ContextManager {
  /**
   * The name of the `doc` directory.
   */
  static const String DOC_DIR_NAME = 'doc';

  /**
   * The name of the `lib` directory.
   */
  static const String LIB_DIR_NAME = 'lib';

  /**
   * The name of `packages` folders.
   */
  static const String PACKAGES_NAME = 'packages';

  /**
   * File name of pubspec files.
   */
  static const String PUBSPEC_NAME = 'pubspec.yaml';

  /**
   * File name of package spec files.
   */
  static const String PACKAGE_SPEC_NAME = '.packages';

  /**
   * The name of the key in an embedder file whose value is the list of
   * libraries in the SDK.
   * TODO(brianwilkerson) This is also defined in sdk.dart.
   */
  static const String _EMBEDDED_LIB_MAP_KEY = 'embedded_libs';

  /**
   * The [ResourceProvider] using which paths are converted into [Resource]s.
   */
  final ResourceProvider resourceProvider;

  /**
   * The manager used to access the SDK that should be associated with a
   * particular context.
   */
  final DartSdkManager sdkManager;

  /**
   * The context used to work with absolute file system paths.
   *
   * TODO(scheglov) remove [pathContext].
   */
  AbsolutePathContext absolutePathContext;

  /**
   * The context used to work with file system paths.
   */
  pathos.Context pathContext;

  /**
   * The list of excluded paths (folders and files) most recently passed to
   * [setRoots].
   */
  List<String> excludedPaths = <String>[];

  /**
   * The list of included paths (folders and files) most recently passed to
   * [setRoots].
   */
  List<String> includedPaths = <String>[];

  /**
   * The map of package roots most recently passed to [setRoots].
   */
  Map<String, String> packageRoots = <String, String>{};

  /**
   * Same as [packageRoots], except that source folders have been normalized
   * and non-folders have been removed.
   */
  Map<String, String> normalizedPackageRoots = <String, String>{};

  /**
   * A function that will return a [UriResolver] that can be used to resolve
   * `package:` URI's within a given folder, or `null` if we should fall back
   * to the standard URI resolver.
   */
  final ResolverProvider packageResolverProvider;

  /**
   * Provider which is used to determine the mapping from package name to
   * package folder.
   */
  final PubPackageMapProvider _packageMapProvider;

  /**
   * A list of the globs used to determine which files should be analyzed.
   */
  final List<Glob> analyzedFilesGlobs;

  /**
   * The default options used to create new analysis contexts.
   */
  final AnalysisOptionsImpl defaultContextOptions;

  /**
   * The instrumentation service used to report instrumentation data.
   */
  final InstrumentationService _instrumentationService;

  final bool enableNewAnalysisDriver;

  @override
  ContextManagerCallbacks callbacks;

  /**
   * Virtual [ContextInfo] which acts as the ancestor of all other
   * [ContextInfo]s.
   */
  final ContextInfo rootInfo = new ContextInfo._root();

  @override
  final Map<Folder, AnalysisDriver> driverMap =
      new HashMap<Folder, AnalysisDriver>();

  /**
   * A table mapping [Folder]s to the [AnalysisContext]s associated with them.
   */
  final Map<Folder, AnalysisContext> _folderMap =
      new HashMap<Folder, AnalysisContext>();

  /**
   * Stream subscription we are using to watch each analysis root directory for
   * changes.
   */
  final Map<Folder, StreamSubscription<WatchEvent>> changeSubscriptions =
      <Folder, StreamSubscription<WatchEvent>>{};

  ContextManagerImpl(
      this.resourceProvider,
      this.sdkManager,
      this.packageResolverProvider,
      this._packageMapProvider,
      this.analyzedFilesGlobs,
      this._instrumentationService,
      this.defaultContextOptions,
      this.enableNewAnalysisDriver) {
    absolutePathContext = resourceProvider.absolutePathContext;
    pathContext = resourceProvider.pathContext;
  }

  @override
  Iterable<AnalysisContext> get analysisContexts => folderMap.values;

  Map<Folder, AnalysisContext> get folderMap {
    if (enableNewAnalysisDriver) {
      throw new StateError('Should not be used with the new analysis driver');
    } else {
      return _folderMap;
    }
  }

  @override
  List<AnalysisContext> contextsInAnalysisRoot(Folder analysisRoot) {
    List<AnalysisContext> contexts = <AnalysisContext>[];
    ContextInfo innermostContainingInfo =
        _getInnermostContextInfoFor(analysisRoot.path);
    void addContextAndDescendants(ContextInfo info) {
      contexts.add(info.context);
      info.children.forEach(addContextAndDescendants);
    }

    if (innermostContainingInfo != null) {
      if (analysisRoot == innermostContainingInfo.folder) {
        addContextAndDescendants(innermostContainingInfo);
      } else {
        for (ContextInfo info in innermostContainingInfo.children) {
          if (analysisRoot.isOrContains(info.folder.path)) {
            addContextAndDescendants(info);
          }
        }
      }
    }
    return contexts;
  }

  /**
   * Check if this map defines embedded libraries.
   */
  bool definesEmbeddedLibs(Map map) => map[_EMBEDDED_LIB_MAP_KEY] != null;

  Folder getContextFolderFor(String path) {
    return _getInnermostContextInfoFor(path)?.folder;
  }

  @override
  AnalysisContext getContextFor(String path) {
    return _getInnermostContextInfoFor(path)?.context;
  }

  /**
   * For testing: get the [ContextInfo] object for the given [folder], if any.
   */
  ContextInfo getContextInfoFor(Folder folder) {
    ContextInfo info = _getInnermostContextInfoFor(folder.path);
    if (info != null && folder == info.folder) {
      return info;
    }
    return null;
  }

  @override
  AnalysisDriver getDriverFor(String path) {
    return _getInnermostContextInfoFor(path)?.analysisDriver;
  }

  @override
  List<AnalysisDriver> getDriversInAnalysisRoot(Folder analysisRoot) {
    List<AnalysisDriver> drivers = <AnalysisDriver>[];
    void addContextAndDescendants(ContextInfo info) {
      drivers.add(info.analysisDriver);
      info.children.forEach(addContextAndDescendants);
    }

    ContextInfo innermostContainingInfo =
        _getInnermostContextInfoFor(analysisRoot.path);
    if (innermostContainingInfo != null) {
      if (analysisRoot == innermostContainingInfo.folder) {
        addContextAndDescendants(innermostContainingInfo);
      } else {
        for (ContextInfo info in innermostContainingInfo.children) {
          if (analysisRoot.isOrContains(info.folder.path)) {
            addContextAndDescendants(info);
          }
        }
      }
    }
    return drivers;
  }

  @override
  bool isIgnored(String path) {
    ContextInfo info = rootInfo;
    do {
      info = info.findChildInfoFor(path);
      if (info == null) {
        return false;
      }
      if (info.ignored(path)) {
        return true;
      }
    } while (true);
  }

  @override
  bool isInAnalysisRoot(String path) {
    // check if excluded
    if (_isExcluded(path)) {
      return false;
    }
    // check if in one of the roots
    for (ContextInfo info in rootInfo.children) {
      if (info.folder.contains(path)) {
        return true;
      }
    }
    // no
    return false;
  }

  /**
   * Process [options] for the given context [info].
   */
  void processOptionsForContext(ContextInfo info, Map<String, Object> options,
      {bool optionsRemoved: false}) {
    if (options == null && !optionsRemoved) {
      return;
    }

    AnalysisOptionsImpl analysisOptions;
    if (optionsRemoved) {
      // In case options files are removed, revert to defaults.
      analysisOptions = new AnalysisOptionsImpl.from(defaultContextOptions);
      // Apply inherited options.
      options = _toStringMap(_getEmbeddedOptions(info));
    } else {
      analysisOptions =
          new AnalysisOptionsImpl.from(info.context.analysisOptions);
      // Check for embedded options.
      Map embeddedOptions = _getEmbeddedOptions(info);
      if (embeddedOptions != null) {
        options = _toStringMap(new Merger().merge(embeddedOptions, options));
      }
    }
    if (options != null) {
      applyToAnalysisOptions(analysisOptions, options);
    }
    info.context.analysisOptions = analysisOptions;

    // Nothing more to do.
    if (options == null) {
      return;
    }

    var analyzer = options[AnalyzerOptions.analyzer];
    if (analyzer is Map) {
      // Set ignore patterns.
      var exclude = analyzer[AnalyzerOptions.exclude];
      if (exclude is YamlList) {
        List<String> excludeList = toStringList(exclude);
        if (excludeList != null) {
          setIgnorePatternsForContext(info, excludeList);
        }
      }
    }
  }

  /**
   * Process [options] for the given context [info].
   */
  void processOptionsForDriver(ContextInfo info,
      AnalysisOptionsImpl analysisOptions, Map<String, Object> options) {
    if (options == null) {
      return;
    }

    // Check for embedded options.
    Map embeddedOptions = _getEmbeddedOptions(info);
    if (embeddedOptions != null) {
      options = _toStringMap(new Merger().merge(embeddedOptions, options));
    }

    applyToAnalysisOptions(analysisOptions, options);

    var analyzer = options[AnalyzerOptions.analyzer];
    if (analyzer is Map) {
      // Set ignore patterns.
      YamlList exclude = analyzer[AnalyzerOptions.exclude];
      List<String> excludeList = toStringList(exclude);
      if (excludeList != null) {
        setIgnorePatternsForContext(info, excludeList);
      }
    }
  }

  /**
   * Return the options from the analysis options file in the given [folder]
   * if exists, or in one of the parent folders, or `null` if no analysis
   * options file is found or if the contents of the file are not valid YAML.
   */
  Map<String, Object> readOptions(Folder folder, Packages packages) {
    try {
      Map<String, List<Folder>> packageMap =
          new ContextBuilder(resourceProvider, null, null)
              .convertPackagesToMap(packages);
      List<UriResolver> resolvers = <UriResolver>[
        new ResourceUriResolver(resourceProvider),
        new PackageMapUriResolver(resourceProvider, packageMap),
      ];
      SourceFactory sourceFactory =
          new SourceFactory(resolvers, packages, resourceProvider);
      return new AnalysisOptionsProvider(sourceFactory)
          .getOptions(folder, crawlUp: true);
    } catch (_) {
      // Parse errors are reported by GenerateOptionsErrorsTask.
    }
    return null;
  }

  @override
  void refresh(List<Resource> roots) {
    // Destroy old contexts
    List<ContextInfo> contextInfos = rootInfo.descendants.toList();
    if (roots == null) {
      contextInfos.forEach(_destroyContext);
    } else {
      roots.forEach((Resource resource) {
        contextInfos.forEach((ContextInfo contextInfo) {
          if (resource is Folder &&
              resource.isOrContains(contextInfo.folder.path)) {
            _destroyContext(contextInfo);
          }
        });
      });
    }

    // Rebuild contexts based on the data last sent to setRoots().
    setRoots(includedPaths, excludedPaths, packageRoots);
  }

  /**
   * Sets the [ignorePatterns] for the context having info [info].
   */
  void setIgnorePatternsForContext(
      ContextInfo info, List<String> ignorePatterns) {
    info.pathFilter.setIgnorePatterns(ignorePatterns);
  }

  @override
  void setRoots(List<String> includedPaths, List<String> excludedPaths,
      Map<String, String> packageRoots) {
    this.packageRoots = packageRoots;

    // Normalize all package root sources by mapping them to folders on the
    // filesystem.  Ignore any package root sources that aren't folders.
    normalizedPackageRoots = <String, String>{};
    packageRoots.forEach((String sourcePath, String targetPath) {
      Resource resource = resourceProvider.getResource(sourcePath);
      if (resource is Folder) {
        normalizedPackageRoots[resource.path] = targetPath;
      }
    });

    List<ContextInfo> contextInfos = rootInfo.descendants.toList();
    // included
    List<Folder> includedFolders = <Folder>[];
    {
      // Sort paths to ensure that outer roots are handled before inner roots,
      // so we can correctly ignore inner roots, which are already managed
      // by outer roots.
      LinkedHashSet<String> uniqueIncludedPaths =
          new LinkedHashSet<String>.from(includedPaths);
      List<String> sortedIncludedPaths = uniqueIncludedPaths.toList();
      sortedIncludedPaths.sort((a, b) => a.length - b.length);
      // Convert paths to folders.
      for (String path in sortedIncludedPaths) {
        Resource resource = resourceProvider.getResource(path);
        if (resource is Folder) {
          includedFolders.add(resource);
        } else if (!resource.exists) {
          // Non-existent resources are ignored.  TODO(paulberry): we should set
          // up a watcher to ensure that if the resource appears later, we will
          // begin analyzing it.
        } else {
          // TODO(scheglov) implemented separate files analysis
          throw new UnimplementedError('$path is not a folder. '
              'Only support for folder analysis is implemented currently.');
        }
      }
    }
    this.includedPaths = includedPaths;
    // excluded
    List<String> oldExcludedPaths = this.excludedPaths;
    this.excludedPaths = excludedPaths;
    // destroy old contexts
    for (ContextInfo contextInfo in contextInfos) {
      bool isIncluded = includedFolders.any((folder) {
        return folder.isOrContains(contextInfo.folder.path);
      });
      if (!isIncluded) {
        _destroyContext(contextInfo);
      }
    }
    // Update package roots for existing contexts
    for (ContextInfo info in rootInfo.descendants) {
      String newPackageRoot = normalizedPackageRoots[info.folder.path];
      if (info.packageRoot != newPackageRoot) {
        info.packageRoot = newPackageRoot;
        _recomputeFolderDisposition(info);
      }
    }
    // create new contexts
    for (Folder includedFolder in includedFolders) {
      String includedPath = includedFolder.path;
      bool isManaged = rootInfo._managesOrHasChildThatManages(includedPath);
      if (!isManaged) {
        ContextInfo parent = _getParentForNewContext(includedPath);
        changeSubscriptions[includedFolder] =
            includedFolder.changes.listen(_handleWatchEvent);
        _createContexts(parent, includedFolder, excludedPaths, false);
      }
    }
    // remove newly excluded sources
    for (ContextInfo info in rootInfo.descendants) {
      // prepare excluded sources
      Map<String, Source> excludedSources = new HashMap<String, Source>();
      info.sources.forEach((String path, Source source) {
        if (_isExcludedBy(excludedPaths, path) &&
            !_isExcludedBy(oldExcludedPaths, path)) {
          excludedSources[path] = source;
        }
      });
      // apply exclusion
      ChangeSet changeSet = new ChangeSet();
      excludedSources.forEach((String path, Source source) {
        info.sources.remove(path);
        changeSet.removedSource(source);
      });
      callbacks.applyChangesToContext(info.folder, changeSet);
    }
    // add previously excluded sources
    for (ContextInfo info in rootInfo.descendants) {
      ChangeSet changeSet = new ChangeSet();
      _addPreviouslyExcludedSources(
          info, changeSet, info.folder, oldExcludedPaths);
      callbacks.applyChangesToContext(info.folder, changeSet);
    }
  }

  /**
   * Recursively adds all Dart and HTML files to the [changeSet].
   */
  void _addPreviouslyExcludedSources(ContextInfo info, ChangeSet changeSet,
      Folder folder, List<String> oldExcludedPaths) {
    if (info.excludesResource(folder)) {
      return;
    }
    List<Resource> children;
    try {
      children = folder.getChildren();
    } on FileSystemException {
      // The folder no longer exists, or cannot be read, to there's nothing to
      // do.
      return;
    }
    for (Resource child in children) {
      String path = child.path;
      // Path is being ignored.
      if (info.ignored(path)) {
        continue;
      }
      // add files, recurse into folders
      if (child is File) {
        // ignore if should not be analyzed at all
        if (!_shouldFileBeAnalyzed(child)) {
          continue;
        }
        // ignore if was not excluded
        bool wasExcluded = _isExcludedBy(oldExcludedPaths, path) &&
            !_isExcludedBy(excludedPaths, path);
        if (!wasExcluded) {
          continue;
        }
        // do add the file
        Source source = createSourceInContext(info.context, child);
        changeSet.addedSource(source);
        info.sources[path] = source;
      } else if (child is Folder) {
        if (child.shortName == PACKAGES_NAME) {
          continue;
        }
        _addPreviouslyExcludedSources(info, changeSet, child, oldExcludedPaths);
      }
    }
  }

  /**
   * Recursively adds all Dart and HTML files to the [changeSet].
   */
  void _addSourceFiles(ChangeSet changeSet, Folder folder, ContextInfo info) {
    if (info.excludesResource(folder) ||
        folder.shortName.startsWith('.') ||
        _isInTopLevelDocDir(info.folder.path, folder.path)) {
      return;
    }
    List<Resource> children = null;
    try {
      children = folder.getChildren();
    } on FileSystemException {
      // The directory either doesn't exist or cannot be read. Either way, there
      // are no children that need to be added.
      return;
    }
    for (Resource child in children) {
      String path = child.path;
      // ignore excluded files or folders
      if (_isExcluded(path) || info.excludes(path) || info.ignored(path)) {
        continue;
      }
      // add files, recurse into folders
      if (child is File) {
        if (_shouldFileBeAnalyzed(child)) {
          Source source = createSourceInContext(info.context, child);
          changeSet.addedSource(source);
          info.sources[path] = source;
        }
      } else if (child is Folder) {
        String shortName = child.shortName;
        if (shortName == PACKAGES_NAME) {
          continue;
        }
        _addSourceFiles(changeSet, child, info);
      }
    }
  }

  void _checkForAnalysisOptionsUpdate(
      String path, ContextInfo info, ChangeType changeType) {
    if (AnalysisEngine.isAnalysisOptionsFileName(path, pathContext)) {
      if (enableNewAnalysisDriver) {
        AnalysisDriver driver = info.analysisDriver;
        String contextRoot = info.folder.path;
        ContextBuilder builder =
            callbacks.createContextBuilder(info.folder, defaultContextOptions);
        AnalysisOptions options = builder.getAnalysisOptions(contextRoot);
        SourceFactory factory =
            builder.createSourceFactory(contextRoot, options);
        driver.configure(analysisOptions: options, sourceFactory: factory);
        // TODO(brianwilkerson) Set exclusion patterns.
      } else {
        var analysisContext = info.context;
        if (analysisContext is context.AnalysisContextImpl) {
          Map<String, Object> options =
              readOptions(info.folder, info.disposition.packages);
          processOptionsForContext(info, options,
              optionsRemoved: changeType == ChangeType.REMOVE);
          analysisContext.sourceFactory = _createSourceFactory(
              analysisContext, analysisContext.analysisOptions, info.folder);
          callbacks.applyChangesToContext(info.folder, new ChangeSet());
        }
      }
    }
  }

  void _checkForPackagespecUpdate(
      String path, ContextInfo info, Folder folder) {
    // Check to see if this is the .packages file for this context and if so,
    // update the context's source factory.
    if (absolutePathContext.basename(path) == PACKAGE_SPEC_NAME) {
      String contextRoot = info.folder.path;
      ContextBuilder builder =
          callbacks.createContextBuilder(info.folder, defaultContextOptions);
      AnalysisOptions options = builder.getAnalysisOptions(contextRoot);
      SourceFactory factory = builder.createSourceFactory(contextRoot, options);
      if (enableNewAnalysisDriver) {
        AnalysisDriver driver = info.analysisDriver;
        driver.configure(analysisOptions: options, sourceFactory: factory);
      } else {
        info.context.analysisOptions = options;
        info.context.sourceFactory = factory;
      }
    }
  }

  /**
   * Compute the set of files that are being flushed, this is defined as
   * the set of sources in the removed context (context.sources), that are
   * orphaned by this context being removed (no other context includes this
   * file.)
   */
  List<String> _computeFlushedFiles(ContextInfo info) {
    if (enableNewAnalysisDriver) {
      Set<String> flushedFiles = info.analysisDriver.addedFiles.toSet();
      for (ContextInfo contextInfo in rootInfo.descendants) {
        AnalysisDriver other = contextInfo.analysisDriver;
        if (other != info.analysisDriver) {
          flushedFiles.removeAll(other.addedFiles);
        }
      }
      return flushedFiles.toList(growable: false);
    } else {
      AnalysisContext context = info.context;
      HashSet<String> flushedFiles = new HashSet<String>();
      for (Source source in context.sources) {
        flushedFiles.add(source.fullName);
      }
      for (ContextInfo contextInfo in rootInfo.descendants) {
        AnalysisContext contextN = contextInfo.context;
        if (context != contextN) {
          for (Source source in contextN.sources) {
            flushedFiles.remove(source.fullName);
          }
        }
      }
      return flushedFiles.toList(growable: false);
    }
  }

  /**
   * Compute the appropriate [FolderDisposition] for [folder].  Use
   * [addDependency] to indicate which files needed to be consulted in order to
   * figure out the [FolderDisposition]; these dependencies will be watched in
   * order to determine when it is necessary to call this function again.
   *
   * TODO(paulberry): use [addDependency] for tracking all folder disposition
   * dependencies (currently we only use it to track "pub list" dependencies).
   */
  FolderDisposition _computeFolderDisposition(
      Folder folder, void addDependency(String path), File packagespecFile) {
    String packageRoot = normalizedPackageRoots[folder.path];
    if (packageRoot != null) {
      // TODO(paulberry): We shouldn't be using JavaFile here because it
      // makes the code untestable (see dartbug.com/23909).
      JavaFile packagesDirOrFile = new JavaFile(packageRoot);
      Map<String, List<Folder>> packageMap = new Map<String, List<Folder>>();
      if (packagesDirOrFile.isDirectory()) {
        for (JavaFile file in packagesDirOrFile.listFiles()) {
          // Ensure symlinks in packages directory are canonicalized
          // to prevent 'type X cannot be assigned to type X' warnings
          String path;
          try {
            path = file.getCanonicalPath();
          } catch (e, s) {
            // Ignore packages that do not exist
            _instrumentationService.logException(e, s);
            continue;
          }
          Resource res = resourceProvider.getResource(path);
          if (res is Folder) {
            packageMap[file.getName()] = <Folder>[res];
          }
        }
        return new PackageMapDisposition(packageMap, packageRoot: packageRoot);
      } else if (packagesDirOrFile.isFile()) {
        File packageSpecFile = resourceProvider.getFile(packageRoot);
        Packages packages = _readPackagespec(packageSpecFile);
        if (packages != null) {
          return new PackagesFileDisposition(packages);
        }
      }
      // The package root does not exist (or is not a folder).  Since
      // [setRoots] ignores any package roots that don't exist (or aren't
      // folders), the only way we should be able to get here is due to a race
      // condition.  In any case, the package root folder is gone, so we can't
      // resolve packages.
      return new NoPackageFolderDisposition(packageRoot: packageRoot);
    } else {
      PackageMapInfo packageMapInfo;
      callbacks.computingPackageMap(true);
      try {
        // Try .packages first.
        if (absolutePathContext.basename(packagespecFile.path) ==
            PACKAGE_SPEC_NAME) {
          Packages packages = _readPackagespec(packagespecFile);
          return new PackagesFileDisposition(packages);
        }
        if (packageResolverProvider != null) {
          UriResolver resolver = packageResolverProvider(folder);
          if (resolver != null) {
            return new CustomPackageResolverDisposition(resolver);
          }
        }

        ServerPerformanceStatistics.pub.makeCurrentWhile(() {
          packageMapInfo = _packageMapProvider.computePackageMap(folder);
        });
      } finally {
        callbacks.computingPackageMap(false);
      }
      for (String dependencyPath in packageMapInfo.dependencies) {
        addDependency(dependencyPath);
      }
      if (packageMapInfo.packageMap == null) {
        return new NoPackageFolderDisposition();
      }
      return new PackageMapDisposition(packageMapInfo.packageMap);
    }
  }

  /**
   * Create a new empty context associated with [folder], having parent
   * [parent] and using [packagesFile] to resolve package URI's.
   */
  ContextInfo _createContext(ContextInfo parent, Folder folder,
      List<String> excludedPaths, File packagesFile) {
    List<String> dependencies = <String>[];
    FolderDisposition disposition =
        _computeFolderDisposition(folder, dependencies.add, packagesFile);
    ContextInfo info = new ContextInfo(this, parent, folder, packagesFile,
        normalizedPackageRoots[folder.path], disposition);

    Map<String, Object> optionMap =
        readOptions(info.folder, disposition.packages);
    AnalysisOptions options =
        new AnalysisOptionsImpl.from(defaultContextOptions);
    applyToAnalysisOptions(options, optionMap);

    info.setDependencies(dependencies);
    if (enableNewAnalysisDriver) {
      String includedPath = folder.path;
      List<String> containedExcludedPaths = excludedPaths
          .where((String excludedPath) =>
              pathContext.isWithin(includedPath, excludedPath))
          .toList();
      processOptionsForDriver(info, options, optionMap);
      info.analysisDriver = callbacks.addAnalysisDriver(folder,
          new ContextRoot(folder.path, containedExcludedPaths), options);
    } else {
      info.context = callbacks.addContext(folder, options);
      _folderMap[folder] = info.context;
      info.context.name = folder.path;
      processOptionsForContext(info, optionMap);
    }

    return info;
  }

  /**
   * Potentially create a new context associated with the given [folder].
   *
   * If there are subfolders with 'pubspec.yaml' files, separate contexts are
   * created for them and excluded from the context associated with the
   * [folder].
   *
   * If [withPackageSpecOnly] is `true`, a context will be created only if there
   * is a 'pubspec.yaml' or '.packages' file in the [folder].
   *
   * [parent] should be the parent of any contexts that are created.
   */
  void _createContexts(ContextInfo parent, Folder folder,
      List<String> excludedPaths, bool withPackageSpecOnly) {
    if (_isExcluded(folder.path) ||
        folder.shortName.startsWith('.') ||
        folder.shortName == 'packages') {
      return;
    }
    // Decide whether a context needs to be created for [folder] here, and if
    // so, create it.
    File packageSpec = _findPackageSpecFile(folder);
    bool createContext = packageSpec.exists || !withPackageSpecOnly;
    if (withPackageSpecOnly &&
        packageSpec.exists &&
        parent != null &&
        parent.ignored(packageSpec.path)) {
      // Don't create a context if the package spec is required and ignored.
      createContext = false;
    }
    if (createContext) {
      parent = _createContext(parent, folder, excludedPaths, packageSpec);
    }

    // Try to find subfolders with pubspecs or .packages files.
    try {
      for (Resource child in folder.getChildren()) {
        if (child is Folder) {
          if (!parent.ignored(child.path)) {
            _createContexts(parent, child, excludedPaths, true);
          }
        }
      }
    } on FileSystemException {
      // The directory either doesn't exist or cannot be read. Either way, there
      // are no subfolders that need to be added.
    }

    if (createContext) {
      // Now that the child contexts have been created, add the sources that
      // don't belong to the children.
      ChangeSet changeSet = new ChangeSet();
      _addSourceFiles(changeSet, folder, parent);
      callbacks.applyChangesToContext(folder, changeSet);
    }
  }

  /**
   * Set up a [SourceFactory] that resolves packages as appropriate for the
   * given [disposition].
   */
  SourceFactory _createSourceFactory(
      InternalAnalysisContext context, AnalysisOptions options, Folder folder) {
    ContextBuilder builder = callbacks.createContextBuilder(folder, options);
    return builder.createSourceFactory(folder.path, options);
  }

  /**
   * Clean up and destroy the context associated with the given folder.
   */
  void _destroyContext(ContextInfo info) {
    changeSubscriptions.remove(info.folder)?.cancel();
    callbacks.removeContext(info.folder, _computeFlushedFiles(info));
    bool wasRemoved = info.parent.children.remove(info);
    assert(wasRemoved);
  }

  /**
   * Extract a new [packagespecFile]-based context from [oldInfo].
   */
  void _extractContext(ContextInfo oldInfo, File packagespecFile) {
    Folder newFolder = packagespecFile.parent;
    ContextInfo newInfo =
        _createContext(oldInfo, newFolder, excludedPaths, packagespecFile);
    // prepare sources to extract
    Map<String, Source> extractedSources = new HashMap<String, Source>();
    oldInfo.sources.forEach((path, source) {
      if (newFolder.contains(path)) {
        extractedSources[path] = source;
      }
    });
    // update new context
    {
      ChangeSet changeSet = new ChangeSet();
      extractedSources.forEach((path, source) {
        newInfo.sources[path] = source;
        changeSet.addedSource(source);
      });
      callbacks.applyChangesToContext(newFolder, changeSet);
    }
    // update old context
    {
      ChangeSet changeSet = new ChangeSet();
      extractedSources.forEach((path, source) {
        oldInfo.sources.remove(path);
        changeSet.removedSource(source);
      });
      callbacks.applyChangesToContext(oldInfo.folder, changeSet);
    }
    // TODO(paulberry): every context that was previously a child of oldInfo is
    // is still a child of oldInfo.  This is wrong--some of them ought to be
    // adopted by newInfo now.
  }

  /**
   * Find the file that should be used to determine whether a context needs to
   * be created here--this is either the ".packages" file or the "pubspec.yaml"
   * file.
   */
  File _findPackageSpecFile(Folder folder) {
    // Decide whether a context needs to be created for [folder] here, and if
    // so, create it.
    File packageSpec;

    // Start by looking for .packages.
    packageSpec = folder.getChild(PACKAGE_SPEC_NAME);

    // Fall back to looking for a pubspec.
    if (packageSpec == null || !packageSpec.exists) {
      packageSpec = folder.getChild(PUBSPEC_NAME);
    }
    return packageSpec;
  }

  /// Get analysis options inherited from an `_embedder.yaml` (deprecated)
  /// and/or a package specified configuration.  If more than one
  /// `_embedder.yaml` is associated with the given context, the embedder is
  /// skipped.
  ///
  /// Returns null if there are no embedded/configured options.
  Map _getEmbeddedOptions(ContextInfo info) {
    Map embeddedOptions = null;
    EmbedderYamlLocator locator =
        info.disposition.getEmbedderLocator(resourceProvider);
    Iterable<YamlMap> maps = locator.embedderYamls.values;
    if (maps.length == 1) {
      embeddedOptions = maps.first;
    }
    return embeddedOptions;
  }

  /**
   * Return the [ContextInfo] for the "innermost" context whose associated
   * folder is or contains the given path.  ("innermost" refers to the nesting
   * of contexts, so if there is a context for path /foo and a context for
   * path /foo/bar, then the innermost context containing /foo/bar/baz.dart is
   * the context for /foo/bar.)
   *
   * If no context contains the given path, `null` is returned.
   */
  ContextInfo _getInnermostContextInfoFor(String path) {
    ContextInfo info = rootInfo.findChildInfoFor(path);
    if (info == null) {
      return null;
    }
    while (true) {
      ContextInfo childInfo = info.findChildInfoFor(path);
      if (childInfo == null) {
        return info;
      }
      info = childInfo;
    }
  }

  /**
   * Return the parent for a new [ContextInfo] with the given [path] folder.
   */
  ContextInfo _getParentForNewContext(String path) {
    ContextInfo parent = _getInnermostContextInfoFor(path);
    if (parent != null) {
      return parent;
    }
    return rootInfo;
  }

  void _handleWatchEvent(WatchEvent event) {
    // Figure out which context this event applies to.
    // TODO(brianwilkerson) If a file is explicitly included in one context
    // but implicitly referenced in another context, we will only send a
    // changeSet to the context that explicitly includes the file (because
    // that's the only context that's watching the file).
    callbacks.broadcastWatchEvent(event);
    String path = event.path;
    ChangeType type = event.type;
    ContextInfo info = _getInnermostContextInfoFor(path);
    if (info == null) {
      // This event doesn't apply to any context.  This could happen due to a
      // race condition (e.g. a context was removed while one of its events was
      // in the event loop).  The event is inapplicable now, so just ignore it.
      return;
    }
    _instrumentationService.logWatchEvent(
        info.folder.path, path, type.toString());
    // First handle changes that affect folderDisposition (since these need to
    // be processed regardless of whether they are part of an excluded/ignored
    // path).
    if (info.hasDependency(path)) {
      _recomputeFolderDisposition(info);
    }
    // maybe excluded globally
    if (_isExcluded(path) ||
        _isContainedInDotFolder(info.folder.path, path) ||
        _isInPackagesDir(info.folder.path, path) ||
        _isInTopLevelDocDir(info.folder.path, path)) {
      return;
    }
    // maybe excluded from the context, so other context will handle it
    if (info.excludes(path)) {
      return;
    }
    if (info.ignored(path)) {
      return;
    }
    // handle the change
    switch (type) {
      case ChangeType.ADD:
        Resource resource = resourceProvider.getResource(path);

        String directoryPath = absolutePathContext.dirname(path);

        // Check to see if we need to create a new context.
        if (info.isTopLevel) {
          // Only create a new context if this is not the same directory
          // described by our info object.
          if (info.folder.path != directoryPath) {
            if (_isPubspec(path)) {
              // Check for a sibling .packages file.
              if (!resourceProvider
                  .getFile(absolutePathContext.append(
                      directoryPath, PACKAGE_SPEC_NAME))
                  .exists) {
                _extractContext(info, resource);
                return;
              }
            }
            if (_isPackagespec(path)) {
              // Check for a sibling pubspec.yaml file.
              if (!resourceProvider
                  .getFile(
                      absolutePathContext.append(directoryPath, PUBSPEC_NAME))
                  .exists) {
                _extractContext(info, resource);
                return;
              }
            }
          }
        }

        // If the file went away and was replaced by a folder before we
        // had a chance to process the event, resource might be a Folder.  In
        // that case don't add it.
        if (resource is File) {
          File file = resource;
          if (_shouldFileBeAnalyzed(file)) {
            if (enableNewAnalysisDriver) {
              info.analysisDriver.addFile(path);
            } else {
              ChangeSet changeSet = new ChangeSet();
              Source source = createSourceInContext(info.context, file);
              changeSet.addedSource(source);
              callbacks.applyChangesToContext(info.folder, changeSet);
              info.sources[path] = source;
            }
          }
        }
        break;
      case ChangeType.REMOVE:

        // If package spec info is removed, check to see if we can merge contexts.
        // Note that it's important to verify that there is NEITHER a .packages nor a
        // lingering pubspec.yaml before merging.
        if (!info.isTopLevel) {
          String directoryPath = absolutePathContext.dirname(path);

          // Only merge if this is the same directory described by our info object.
          if (info.folder.path == directoryPath) {
            if (_isPubspec(path)) {
              // Check for a sibling .packages file.
              if (!resourceProvider
                  .getFile(absolutePathContext.append(
                      directoryPath, PACKAGE_SPEC_NAME))
                  .exists) {
                _mergeContext(info);
                return;
              }
            }
            if (_isPackagespec(path)) {
              // Check for a sibling pubspec.yaml file.
              if (!resourceProvider
                  .getFile(
                      absolutePathContext.append(directoryPath, PUBSPEC_NAME))
                  .exists) {
                _mergeContext(info);
                return;
              }
            }
          }
        }

        if (enableNewAnalysisDriver) {
          callbacks.applyFileRemoved(info.analysisDriver, path);
        } else {
          List<Source> sources = info.context.getSourcesWithFullName(path);
          if (!sources.isEmpty) {
            ChangeSet changeSet = new ChangeSet();
            sources.forEach((Source source) {
              changeSet.removedSource(source);
            });
            callbacks.applyChangesToContext(info.folder, changeSet);
            info.sources.remove(path);
          }
        }
        break;
      case ChangeType.MODIFY:
        if (enableNewAnalysisDriver) {
          for (AnalysisDriver driver in driverMap.values) {
            driver.changeFile(path);
          }
        } else {
          List<Source> sources = info.context.getSourcesWithFullName(path);
          if (!sources.isEmpty) {
            ChangeSet changeSet = new ChangeSet();
            sources.forEach((Source source) {
              changeSet.changedSource(source);
            });
            callbacks.applyChangesToContext(info.folder, changeSet);
          }
        }
        break;
    }
    _checkForPackagespecUpdate(path, info, info.folder);
    _checkForAnalysisOptionsUpdate(path, info, type);
  }

  /**
   * Determine whether the given [path], when interpreted relative to the
   * context root [root], contains a folder whose name starts with '.'.
   */
  bool _isContainedInDotFolder(String root, String path) {
    String pathDir = absolutePathContext.dirname(path);
    String suffixPath = absolutePathContext.suffix(root, pathDir);
    if (suffixPath == null) {
      return false;
    }
    for (String pathComponent in absolutePathContext.split(suffixPath)) {
      if (pathComponent.startsWith('.') &&
          pathComponent != '.' &&
          pathComponent != '..') {
        return true;
      }
    }
    return false;
  }

  /**
   * Returns `true` if the given [path] is excluded by [excludedPaths].
   */
  bool _isExcluded(String path) => _isExcludedBy(excludedPaths, path);

  /**
   * Returns `true` if the given [path] is excluded by [excludedPaths].
   */
  bool _isExcludedBy(List<String> excludedPaths, String path) {
    return excludedPaths.any((excludedPath) {
      if (absolutePathContext.isWithin(excludedPath, path)) {
        return true;
      }
      return path == excludedPath;
    });
  }

  /**
   * Determine whether the given [path], when interpreted relative to the
   * context root [root], contains a 'packages' folder.
   */
  bool _isInPackagesDir(String root, String path) {
    String suffixPath = absolutePathContext.suffix(root, path);
    if (suffixPath == null) {
      return false;
    }
    List<String> pathParts = absolutePathContext.split(suffixPath);
    return pathParts.contains(PACKAGES_NAME);
  }

  /**
   * Determine whether the given [path] is in the direct 'doc' folder of the
   * context root [root].
   */
  bool _isInTopLevelDocDir(String root, String path) {
    String suffixPath = absolutePathContext.suffix(root, path);
    if (suffixPath == null) {
      return false;
    }
    return suffixPath == DOC_DIR_NAME ||
        suffixPath.startsWith(DOC_DIR_NAME + absolutePathContext.separator);
  }

  bool _isPackagespec(String path) =>
      absolutePathContext.basename(path) == PACKAGE_SPEC_NAME;

  bool _isPubspec(String path) =>
      absolutePathContext.basename(path) == PUBSPEC_NAME;

  /**
   * Merges [info] context into its parent.
   */
  void _mergeContext(ContextInfo info) {
    // destroy the context
    _destroyContext(info);
    // add files to the parent context
    ContextInfo parentInfo = info.parent;
    if (parentInfo != null) {
      parentInfo.children.remove(info);
      ChangeSet changeSet = new ChangeSet();
      info.sources.forEach((path, source) {
        parentInfo.sources[path] = source;
        changeSet.addedSource(source);
      });
      callbacks.applyChangesToContext(parentInfo.folder, changeSet);
    }
  }

  Packages _readPackagespec(File specFile) {
    try {
      String contents = specFile.readAsStringSync();
      Map<String, Uri> map =
          pkgfile.parse(UTF8.encode(contents), new Uri.file(specFile.path));
      return new MapPackages(map);
    } catch (_) {
      //TODO(pquitslund): consider creating an error for the spec file.
      return null;
    }
  }

  /**
   * Recompute the [FolderDisposition] for the context described by [info],
   * and update the client appropriately.
   */
  void _recomputeFolderDisposition(ContextInfo info) {
    // TODO(paulberry): when computePackageMap is changed into an
    // asynchronous API call, we'll want to suspend analysis for this context
    // while we're rerunning "pub list", since any analysis we complete while
    // "pub list" is in progress is just going to get thrown away anyhow.
    List<String> dependencies = <String>[];
    info.setDependencies(dependencies);
    _updateContextPackageUriResolver(info.folder);
  }

  /**
   * Return `true` if the given [file] should be analyzed.
   */
  bool _shouldFileBeAnalyzed(File file) {
    for (Glob glob in analyzedFilesGlobs) {
      if (glob.matches(file.path)) {
        // Emacs creates dummy links to track the fact that a file is open for
        // editing and has unsaved changes (e.g. having unsaved changes to
        // 'foo.dart' causes a link '.#foo.dart' to be created, which points to
        // the non-existent file 'username@hostname.pid'. To avoid these dummy
        // links causing the analyzer to thrash, just ignore links to
        // non-existent files.
        return file.exists;
      }
    }
    return false;
  }

  /**
   * If the given [object] is a map, and all of the keys in the map are strings,
   * return a map containing the same mappings. Otherwise, return `null`.
   */
  Map<String, Object> _toStringMap(Object object) {
    if (object is Map) {
      Map<String, Object> stringMap = new HashMap<String, Object>();
      for (var key in object.keys) {
        if (key is String) {
          stringMap[key] = object[key];
        } else {
          return null;
        }
      }
      return stringMap;
    }
    return null;
  }

  void _updateContextPackageUriResolver(Folder contextFolder) {
    if (enableNewAnalysisDriver) {
      ContextInfo info = getContextInfoFor(contextFolder);
      AnalysisDriver driver = info.analysisDriver;
      SourceFactory sourceFactory =
          _createSourceFactory(null, driver.analysisOptions, contextFolder);
      driver.configure(sourceFactory: sourceFactory);
    } else {
      AnalysisContext context = folderMap[contextFolder];
      context.sourceFactory =
          _createSourceFactory(context, context.analysisOptions, contextFolder);
      callbacks.updateContextPackageUriResolver(context);
    }
  }

  /**
   * Create and return a source representing the given [file] within the given
   * [context].
   */
  static Source createSourceInContext(AnalysisContext context, File file) {
    // TODO(brianwilkerson) Optimize this, by allowing support for source
    // factories to restore URI's from a file path rather than a source.
    Source source = file.createSource();
    if (context == null) {
      return source;
    }
    Uri uri = context.sourceFactory.restoreUri(source);
    return file.createSource(uri);
  }
}

/**
 * An indication that one or more contexts were added, changed, or removed.
 *
 * The lists of [added], [changed] and [removed] contexts will not contain
 * duplications (that is, a single context will not be in any list multiple
 * times), nor will there be any overlap between the lists (that is, a single
 * context will not be in more than one list).
 */
class ContextsChangedEvent {
  /**
   * The contexts that were added to the server.
   */
  final List<AnalysisContext> added;

  /**
   * The contexts that were changed.
   */
  final List<AnalysisContext> changed;

  /**
   * The contexts that were removed from the server.
   */
  final List<AnalysisContext> removed;

  /**
   * Initialize a newly created event to indicate which contexts have changed.
   */
  ContextsChangedEvent(
      {this.added: AnalysisContext.EMPTY_LIST,
      this.changed: AnalysisContext.EMPTY_LIST,
      this.removed: AnalysisContext.EMPTY_LIST});
}

/**
 * Concrete [FolderDisposition] object indicating that the context for a given
 * folder should resolve package URIs using a custom URI resolver.
 */
class CustomPackageResolverDisposition extends FolderDisposition {
  /**
   * The [UriResolver] that should be used to resolve package URIs.
   */
  UriResolver resolver;

  CustomPackageResolverDisposition(this.resolver);

  @override
  String get packageRoot => null;

  @override
  Packages get packages => null;

  @override
  Iterable<UriResolver> createPackageUriResolvers(
          ResourceProvider resourceProvider) =>
      <UriResolver>[resolver];

  @override
  EmbedderYamlLocator getEmbedderLocator(ResourceProvider resourceProvider) =>
      new EmbedderYamlLocator(null);

  @override
  SdkExtensionFinder getSdkExtensionFinder(ResourceProvider resourceProvider) =>
      new SdkExtensionFinder(null);
}

/**
 * An instance of the class [FolderDisposition] represents the information
 * gathered by the [ContextManagerImpl] to determine how to create an
 * [AnalysisContext] for a given folder.
 *
 * Note: [ContextManagerImpl] may use equality testing and hash codes to
 * determine when two folders should share the same context, so derived classes
 * may need to override operator== and hashCode() if object identity is
 * insufficient.
 *
 * TODO(paulberry): consider adding a flag to indicate that it is not necessary
 * to recurse into the given folder looking for additional contexts to create
 * or files to analyze (this could help avoid unnecessarily weighing down the
 * system with file watchers).
 */
abstract class FolderDisposition {
  /**
   * If this [FolderDisposition] was created based on a package root
   * folder, the absolute path to that folder.  Otherwise `null`.
   */
  String get packageRoot;

  /**
   * If contexts governed by this [FolderDisposition] should resolve packages
   * using the ".packages" file mechanism (DEP 5), retrieve the [Packages]
   * object that resulted from parsing the ".packages" file.
   */
  Packages get packages;

  /**
   * Create all the [UriResolver]s which should be used to resolve packages in
   * contexts governed by this [FolderDisposition].
   *
   * [resourceProvider] is provided since it is needed to construct most
   * [UriResolver]s.
   */
  Iterable<UriResolver> createPackageUriResolvers(
      ResourceProvider resourceProvider);

  /**
   * Return the locator used to locate the _embedder.yaml file used to configure
   * the SDK. The [resourceProvider] is used to access the file system in cases
   * where that is necessary.
   */
  EmbedderYamlLocator getEmbedderLocator(ResourceProvider resourceProvider);

  /**
   * Return the extension finder used to locate the `_sdkext` file used to add
   * extensions to the SDK. The [resourceProvider] is used to access the file
   * system in cases where that is necessary.
   */
  SdkExtensionFinder getSdkExtensionFinder(ResourceProvider resourceProvider);
}

/**
 * Concrete [FolderDisposition] object indicating that the context for a given
 * folder should not resolve "package:" URIs at all.
 */
class NoPackageFolderDisposition extends FolderDisposition {
  @override
  final String packageRoot;

  NoPackageFolderDisposition({this.packageRoot});

  @override
  Packages get packages => null;

  @override
  Iterable<UriResolver> createPackageUriResolvers(
          ResourceProvider resourceProvider) =>
      const <UriResolver>[];

  @override
  EmbedderYamlLocator getEmbedderLocator(ResourceProvider resourceProvider) =>
      new EmbedderYamlLocator(null);

  @override
  SdkExtensionFinder getSdkExtensionFinder(ResourceProvider resourceProvider) =>
      new SdkExtensionFinder(null);
}

/**
 * Concrete [FolderDisposition] object indicating that the context for a given
 * folder should resolve packages using a package map.
 */
class PackageMapDisposition extends FolderDisposition {
  final Map<String, List<Folder>> packageMap;

  EmbedderYamlLocator _embedderLocator;
  SdkExtensionFinder _sdkExtensionFinder;

  @override
  final String packageRoot;

  PackageMapDisposition(this.packageMap, {this.packageRoot});

  @override
  Packages get packages => null;

  @override
  Iterable<UriResolver> createPackageUriResolvers(
          ResourceProvider resourceProvider) =>
      <UriResolver>[
        new SdkExtUriResolver(packageMap),
        new PackageMapUriResolver(resourceProvider, packageMap)
      ];

  @override
  EmbedderYamlLocator getEmbedderLocator(ResourceProvider resourceProvider) {
    if (_embedderLocator == null) {
      _embedderLocator = new EmbedderYamlLocator(packageMap);
    }
    return _embedderLocator;
  }

  @override
  SdkExtensionFinder getSdkExtensionFinder(ResourceProvider resourceProvider) {
    return _sdkExtensionFinder ??= new SdkExtensionFinder(packageMap);
  }
}

/**
 * Concrete [FolderDisposition] object indicating that the context for a given
 * folder should resolve packages using a ".packages" file.
 */
class PackagesFileDisposition extends FolderDisposition {
  @override
  final Packages packages;

  Map<String, List<Folder>> packageMap;

  EmbedderYamlLocator _embedderLocator;
  SdkExtensionFinder _sdkExtensionFinder;

  PackagesFileDisposition(this.packages);

  @override
  String get packageRoot => null;

  Map<String, List<Folder>> buildPackageMap(ResourceProvider resourceProvider) {
    if (packageMap == null) {
      packageMap = <String, List<Folder>>{};
      if (packages != null) {
        packages.asMap().forEach((String name, Uri uri) {
          if (uri.scheme == 'file' || uri.scheme == '' /* unspecified */) {
            var path = resourceProvider.pathContext.fromUri(uri);
            packageMap[name] = <Folder>[resourceProvider.getFolder(path)];
          }
        });
      }
    }
    return packageMap;
  }

  @override
  Iterable<UriResolver> createPackageUriResolvers(
      ResourceProvider resourceProvider) {
    if (packages != null) {
      // Construct package map for the SdkExtUriResolver.
      Map<String, List<Folder>> packageMap = buildPackageMap(resourceProvider);
      return <UriResolver>[new SdkExtUriResolver(packageMap)];
    } else {
      return const <UriResolver>[];
    }
  }

  @override
  EmbedderYamlLocator getEmbedderLocator(ResourceProvider resourceProvider) {
    if (_embedderLocator == null) {
      _embedderLocator =
          new EmbedderYamlLocator(buildPackageMap(resourceProvider));
    }
    return _embedderLocator;
  }

  @override
  SdkExtensionFinder getSdkExtensionFinder(ResourceProvider resourceProvider) {
    return _sdkExtensionFinder ??=
        new SdkExtensionFinder(buildPackageMap(resourceProvider));
  }
}
