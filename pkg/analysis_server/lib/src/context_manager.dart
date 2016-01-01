// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library context.directory.manager;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:core' hide Resource;

import 'package:analysis_server/plugin/analysis/resolver_provider.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/plugin/options.dart';
import 'package:analyzer/source/analysis_options_provider.dart';
import 'package:analyzer/source/embedder.dart';
import 'package:analyzer/source/package_map_provider.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/source/path_filter.dart';
import 'package:analyzer/source/pub_package_map_provider.dart';
import 'package:analyzer/source/sdk_ext.dart';
import 'package:analyzer/src/context/context.dart' as context;
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:analyzer/src/util/absolute_path.dart';
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
   * The [ContextManager] which is tracking this information.
   */
  final ContextManagerImpl contextManager;

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
   * Paths to files which determine the folder disposition and package map.
   *
   * TODO(paulberry): if any of these files are outside of [folder], they won't
   * be watched for changes.  I believe the use case for watching these files
   * is no longer relevant.
   */
  Set<String> _dependencies = new Set<String>();

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
      File packagespecFile, this.packageRoot)
      : contextManager = contextManager,
        folder = folder,
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
      : contextManager = null,
        folder = null,
        pathFilter = null;

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
   * Get the callback interface used to create, destroy, and update contexts.
   */
  ContextManagerCallbacks get callbacks;

  /**
   * Set the callback interface used to create, destroy, and update contexts.
   */
  void set callbacks(ContextManagerCallbacks value);

  /**
   * Return the list of excluded paths (folders and files) most recently passed
   * to [setRoots].
   */
  List<String> get excludedPaths;

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
   * Create and return a new analysis context, allowing [disposition] to govern
   * details of how the context is to be created.
   */
  AnalysisContext addContext(Folder folder, FolderDisposition disposition);

  /**
   * Called when the set of files associated with a context have changed (or
   * some of those files have been modified).  [changeSet] is the set of
   * changes that need to be applied to the context.
   */
  void applyChangesToContext(Folder contextFolder, ChangeSet changeSet);

  /**
   * Called when the ContextManager is about to start computing the package
   * map.
   */
  void beginComputePackageMap() {
    // By default, do nothing.
  }

  /**
   * Called when the ContextManager has finished computing the package map.
   */
  void endComputePackageMap() {
    // By default, do nothing.
  }

  /**
   * Remove the context associated with the given [folder].  [flushedFiles] is
   * a list of the files which will be "orphaned" by removing this context
   * (they will no longer be analyzed by any context).
   */
  void removeContext(Folder folder, List<String> flushedFiles);

  /**
   * Return `true` if the given [file] should be analyzed.
   */
  bool shouldFileBeAnalyzed(File file);

  /**
   * Called when the disposition for a context has changed.
   */
  void updateContextPackageUriResolver(
      Folder contextFolder, FolderDisposition disposition);
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
   * The [ResourceProvider] using which paths are converted into [Resource]s.
   */
  final ResourceProvider resourceProvider;

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

  /// Provider of analysis options.
  AnalysisOptionsProvider analysisOptionsProvider =
      new AnalysisOptionsProvider();

  /**
   * The instrumentation service used to report instrumentation data.
   */
  final InstrumentationService _instrumentationService;

  @override
  ContextManagerCallbacks callbacks;

  /**
   * Virtual [ContextInfo] which acts as the ancestor of all other
   * [ContextInfo]s.
   */
  final ContextInfo rootInfo = new ContextInfo._root();

  /**
   * Stream subscription we are using to watch each analysis root directory for
   * changes.
   */
  final Map<Folder, StreamSubscription<WatchEvent>> changeSubscriptions =
      <Folder, StreamSubscription<WatchEvent>>{};

  ContextManagerImpl(this.resourceProvider, this.packageResolverProvider,
      this._packageMapProvider, this._instrumentationService) {
    absolutePathContext = resourceProvider.absolutePathContext;
    pathContext = resourceProvider.pathContext;
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
  void processOptionsForContext(ContextInfo info, Folder folder,
      {bool optionsRemoved: false}) {
    Map<String, Object> options;
    try {
      options = analysisOptionsProvider.getOptions(folder);
    } catch (_) {
      // Parse errors are reported by GenerateOptionsErrorsTask.
    }

    if (options == null && !optionsRemoved) {
      return;
    }

    // In case options files are removed, revert to defaults.
    if (optionsRemoved) {
      // Start with defaults.
      info.context.analysisOptions = new AnalysisOptionsImpl();

      // Apply inherited options.
      options = _getEmbeddedOptions(info.context);
      if (options != null) {
        configureContextOptions(info.context, options);
      }
    } else {
      // Check for embedded options.
      YamlMap embeddedOptions = _getEmbeddedOptions(info.context);
      if (embeddedOptions != null) {
        options = new Merger().merge(embeddedOptions, options);
      }
    }

    // Notify options processors.
    AnalysisEngine.instance.optionsPlugin.optionsProcessors
        .forEach((OptionsProcessor p) {
      try {
        p.optionsProcessed(info.context, options);
      } catch (e, stacktrace) {
        AnalysisEngine.instance.logger.logError(
            'Error processing .analysis_options',
            new CaughtException(e, stacktrace));
      }
    });

    configureContextOptions(info.context, options);

    // Nothing more to do.
    if (options == null) {
      return;
    }

    var analyzer = options[AnalyzerOptions.analyzer];
    if (analyzer is! Map) {
      // Done.
      return;
    }

    // Set ignore patterns.
    YamlList exclude = analyzer[AnalyzerOptions.exclude];
    if (exclude != null) {
      setIgnorePatternsForContext(info, exclude);
    }
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
        _createContexts(parent, includedFolder, false);
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
        if (!callbacks.shouldFileBeAnalyzed(child)) {
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
        if (callbacks.shouldFileBeAnalyzed(child)) {
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
      var analysisContext = info.context;
      if (analysisContext is context.AnalysisContextImpl) {
        processOptionsForContext(info, info.folder,
            optionsRemoved: changeType == ChangeType.REMOVE);
        analysisContext.invalidateCachedResults();
        callbacks.applyChangesToContext(info.folder, new ChangeSet());
      }
    }
  }

  void _checkForPackagespecUpdate(
      String path, ContextInfo info, Folder folder) {
    // Check to see if this is the .packages file for this context and if so,
    // update the context's source factory.
    if (absolutePathContext.basename(path) == PACKAGE_SPEC_NAME &&
        info.isPathToPackageDescription(path)) {
      File packagespec = resourceProvider.getFile(path);
      if (packagespec.exists) {
        Packages packages = _readPackagespec(packagespec);
        if (packages != null) {
          callbacks.updateContextPackageUriResolver(
              folder, new PackagesFileDisposition(packages));
        }
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
      JavaFile packagesDir = new JavaFile(packageRoot);
      Map<String, List<Folder>> packageMap = new Map<String, List<Folder>>();
      if (packagesDir.isDirectory()) {
        for (JavaFile file in packagesDir.listFiles()) {
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
      }
      // The package root does not exist (or is not a folder).  Since
      // [setRoots] ignores any package roots that don't exist (or aren't
      // folders), the only way we should be able to get here is due to a race
      // condition.  In any case, the package root folder is gone, so we can't
      // resolve packages.
      return new NoPackageFolderDisposition(packageRoot: packageRoot);
    } else {
      PackageMapInfo packageMapInfo;
      callbacks.beginComputePackageMap();
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
        callbacks.endComputePackageMap();
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
   * [parent] and using [packagespecFile] to resolve package URI's.
   */
  ContextInfo _createContext(
      ContextInfo parent, Folder folder, File packagespecFile) {
    ContextInfo info = new ContextInfo(this, parent, folder, packagespecFile,
        normalizedPackageRoots[folder.path]);

    FolderDisposition disposition;
    List<String> dependencies = <String>[];

    // Next resort to a package uri resolver.
    if (disposition == null) {
      disposition =
          _computeFolderDisposition(folder, dependencies.add, packagespecFile);
    }

    info.setDependencies(dependencies);
    info.context = callbacks.addContext(folder, disposition);
    info.context.name = folder.path;

    processOptionsForContext(info, folder);

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
  void _createContexts(
      ContextInfo parent, Folder folder, bool withPackageSpecOnly) {
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
      parent = _createContext(parent, folder, packageSpec);
    }

    // Try to find subfolders with pubspecs or .packages files.
    try {
      for (Resource child in folder.getChildren()) {
        if (child is Folder) {
          if (!parent.ignored(child.path)) {
            _createContexts(parent, child, true);
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
    ContextInfo newInfo = _createContext(oldInfo, newFolder, packagespecFile);
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

  /// Get analysis options associated with an `_embedder.yaml`. If there is
  /// more than one `_embedder.yaml` associated with the given context, `null`
  /// is returned.
  YamlMap _getEmbeddedOptions(AnalysisContext context) {
    if (context is InternalAnalysisContext) {
      EmbedderYamlLocator locator = context.embedderYamlLocator;
      Iterable<YamlMap> maps = locator.embedderYamls.values;
      if (maps.length == 1) {
        return maps.first;
      }
    }
    return null;
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
    ContextInfo info = _getInnermostContextInfoFor(event.path);
    if (info == null) {
      // This event doesn't apply to any context.  This could happen due to a
      // race condition (e.g. a context was removed while one of its events was
      // in the event loop).  The event is inapplicable now, so just ignore it.
      return;
    }
    _instrumentationService.logWatchEvent(
        info.folder.path, event.path, event.type.toString());
    String path = event.path;
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
    switch (event.type) {
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
          if (callbacks.shouldFileBeAnalyzed(file)) {
            ChangeSet changeSet = new ChangeSet();
            Source source = createSourceInContext(info.context, file);
            changeSet.addedSource(source);
            callbacks.applyChangesToContext(info.folder, changeSet);
            info.sources[path] = source;
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

        List<Source> sources = info.context.getSourcesWithFullName(path);
        if (!sources.isEmpty) {
          ChangeSet changeSet = new ChangeSet();
          sources.forEach((Source source) {
            changeSet.removedSource(source);
          });
          callbacks.applyChangesToContext(info.folder, changeSet);
          info.sources.remove(path);
        }
        break;
      case ChangeType.MODIFY:
        List<Source> sources = info.context.getSourcesWithFullName(path);
        if (!sources.isEmpty) {
          ChangeSet changeSet = new ChangeSet();
          sources.forEach((Source source) {
            changeSet.changedSource(source);
          });
          callbacks.applyChangesToContext(info.folder, changeSet);
        }
        break;
    }
    _checkForPackagespecUpdate(path, info, info.folder);
    _checkForAnalysisOptionsUpdate(path, info, event.type);
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
    FolderDisposition disposition = _computeFolderDisposition(
        info.folder, dependencies.add, _findPackageSpecFile(info.folder));
    info.setDependencies(dependencies);
    callbacks.updateContextPackageUriResolver(info.folder, disposition);
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
}

/**
 * Concrete [FolderDisposition] object indicating that the context for a given
 * folder should resolve packages using a package map.
 */
class PackageMapDisposition extends FolderDisposition {
  final Map<String, List<Folder>> packageMap;

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
}

/**
 * Concrete [FolderDisposition] object indicating that the context for a given
 * folder should resolve packages using a ".packages" file.
 */
class PackagesFileDisposition extends FolderDisposition {
  @override
  final Packages packages;

  PackagesFileDisposition(this.packages);

  @override
  String get packageRoot => null;

  Map<String, List<Folder>> buildPackageMap(ResourceProvider resourceProvider) {
    Map<String, List<Folder>> packageMap = <String, List<Folder>>{};
    if (packages == null) {
      return packageMap;
    }
    packages.asMap().forEach((String name, Uri uri) {
      if (uri.scheme == 'file' || uri.scheme == '' /* unspecified */) {
        var path = resourceProvider.pathContext.fromUri(uri);
        packageMap[name] = <Folder>[resourceProvider.getFolder(path)];
      }
    });
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
}
