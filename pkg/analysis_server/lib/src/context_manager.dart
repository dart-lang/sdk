// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library context.directory.manager;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:core' hide Resource;

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/source/optimizing_pub_package_map_provider.dart';
import 'package:analysis_server/uri/resolver_provider.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/source/analysis_options_provider.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/source/path_filter.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:package_config/packages.dart';
import 'package:package_config/packages_file.dart' as pkgfile show parse;
import 'package:package_config/src/packages_impl.dart' show MapPackages;
import 'package:path/path.dart' as pathos;
import 'package:watcher/watcher.dart';
import 'package:yaml/yaml.dart';

/**
 * Class that maintains a mapping from included/excluded paths to a set of
 * folders that should correspond to analysis contexts.
 */
abstract class AbstractContextManager implements ContextManager {

  /**
   * Temporary flag to hide WIP .packages support (DEP 5).
   */
  static bool ENABLE_PACKAGESPEC_SUPPORT = false;

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
   * [_ContextInfo] object for each included directory in the most
   * recent successful call to [setRoots].
   */
  Map<Folder, _ContextInfo> _contexts = new HashMap<Folder, _ContextInfo>();

  /**
   * The [ResourceProvider] using which paths are converted into [Resource]s.
   */
  final ResourceProvider resourceProvider;

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
  final OptimizingPubPackageMapProvider _packageMapProvider;

  /// Provider of analysis options.
  AnalysisOptionsProvider analysisOptionsProvider =
      new AnalysisOptionsProvider();

  /**
   * The instrumentation service used to report instrumentation data.
   */
  final InstrumentationService _instrumentationService;

  AbstractContextManager(this.resourceProvider, this.packageResolverProvider,
      this._packageMapProvider, this._instrumentationService) {
    pathContext = resourceProvider.pathContext;
  }

  /**
   * Create and return a new analysis context.
   */
  AnalysisContext addContext(
      Folder folder, UriResolver packageUriResolver, Packages packages);

  /**
   * Called when the set of files associated with a context have changed (or
   * some of those files have been modified).  [changeSet] is the set of
   * changes that need to be applied to the context.
   */
  void applyChangesToContext(Folder contextFolder, ChangeSet changeSet);

  /**
   * We are about to start computing the package map.
   */
  void beginComputePackageMap() {
    // Do nothing.
  }

  /**
   * Compute the set of files that are being flushed, this is defined as
   * the set of sources in the removed context (context.sources), that are
   * orphaned by this context being removed (no other context includes this
   * file.)
   */
  List<String> computeFlushedFiles(Folder folder) {
    AnalysisContext context = _contexts[folder].context;
    HashSet<String> flushedFiles = new HashSet<String>();
    for (Source source in context.sources) {
      flushedFiles.add(source.fullName);
    }
    for (_ContextInfo contextInfo in _contexts.values) {
      AnalysisContext contextN = contextInfo.context;
      if (context != contextN) {
        for (Source source in contextN.sources) {
          flushedFiles.remove(source.fullName);
        }
      }
    }
    return flushedFiles.toList(growable: false);
  }

  @override
  List<AnalysisContext> contextsInAnalysisRoot(Folder analysisRoot) {
    List<AnalysisContext> contexts = <AnalysisContext>[];
    _contexts.forEach((Folder contextFolder, _ContextInfo info) {
      if (analysisRoot.isOrContains(contextFolder.path)) {
        contexts.add(info.context);
      }
    });
    return contexts;
  }

  /**
   * We have finished computing the package map.
   */
  void endComputePackageMap() {
    // Do nothing.
  }

  @override
  bool isInAnalysisRoot(String path) {
    // check if excluded
    if (_isExcluded(path)) {
      return false;
    }
    // check if in of the roots
    for (Folder root in _contexts.keys) {
      if (root.contains(path)) {
        return true;
      }
    }
    // no
    return false;
  }

  /// Process [options] for the context [folder].
  void processOptionsForContext(Folder folder, Map<String, YamlNode> options) {
    _ContextInfo info = _contexts[folder];
    if (info == null) {
      return;
    }
    YamlMap analyzer = options['analyzer'];
    if (analyzer == null) {
      // No options for analyzer.
      return;
    }

    // Set ignore patterns.
    YamlList exclude = analyzer['exclude'];
    if (exclude != null) {
      setIgnorePatternsForContext(folder, exclude);
    }
  }

  @override
  void refresh(List<Resource> roots) {
    // Destroy old contexts
    List<Folder> contextFolders = _contexts.keys.toList();
    if (roots == null) {
      contextFolders.forEach(_destroyContext);
    } else {
      roots.forEach((Resource resource) {
        contextFolders.forEach((Folder contextFolder) {
          if (resource is Folder && resource.isOrContains(contextFolder.path)) {
            _destroyContext(contextFolder);
          }
        });
      });
    }

    // Rebuild contexts based on the data last sent to setRoots().
    setRoots(includedPaths, excludedPaths, packageRoots);
  }

  /**
   * Remove the context associated with the given [folder].
   */
  void removeContext(Folder folder);

  /// Sets the [ignorePatterns] for the context [folder].
  void setIgnorePatternsForContext(Folder folder, List<String> ignorePatterns) {
    _ContextInfo info = _contexts[folder];
    if (info == null) {
      return;
    }
    var pathFilter = info.pathFilter;
    pathFilter.setIgnorePatterns(ignorePatterns);
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

    List<Folder> contextFolders = _contexts.keys.toList();
    // included
    Set<Folder> includedFolders = new HashSet<Folder>();
    for (int i = 0; i < includedPaths.length; i++) {
      String path = includedPaths[i];
      Resource resource = resourceProvider.getResource(path);
      if (resource is Folder) {
        includedFolders.add(resource);
      } else {
        // TODO(scheglov) implemented separate files analysis
        throw new UnimplementedError('$path is not a folder. '
            'Only support for folder analysis is implemented currently.');
      }
    }
    this.includedPaths = includedPaths;
    // excluded
    List<String> oldExcludedPaths = this.excludedPaths;
    this.excludedPaths = excludedPaths;
    // destroy old contexts
    for (Folder contextFolder in contextFolders) {
      bool isIncluded = includedFolders.any((folder) {
        return folder.isOrContains(contextFolder.path);
      });
      if (!isIncluded) {
        _destroyContext(contextFolder);
      }
    }
    // Update package roots for existing contexts
    _contexts.forEach((Folder folder, _ContextInfo info) {
      String newPackageRoot = normalizedPackageRoots[folder.path];
      if (info.packageRoot != newPackageRoot) {
        info.packageRoot = newPackageRoot;
        _recomputePackageUriResolver(info);
      }
    });
    // create new contexts
    for (Folder includedFolder in includedFolders) {
      bool wasIncluded = contextFolders.any((folder) {
        return folder.isOrContains(includedFolder.path);
      });
      if (!wasIncluded) {
        _createContexts(includedFolder, false);
      }
    }
    // remove newly excluded sources
    _contexts.forEach((folder, info) {
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
      applyChangesToContext(folder, changeSet);
    });
    // add previously excluded sources
    _contexts.forEach((folder, info) {
      ChangeSet changeSet = new ChangeSet();
      _addPreviouslyExcludedSources(info, changeSet, folder, oldExcludedPaths);
      applyChangesToContext(folder, changeSet);
    });
  }

  /**
   * Return `true` if the given [file] should be analyzed.
   */
  bool shouldFileBeAnalyzed(File file);

  /**
   * Called when the package map for a context has changed.
   */
  void updateContextPackageUriResolver(
      Folder contextFolder, UriResolver packageUriResolver, Packages packages);

  /**
   * Resursively adds all Dart and HTML files to the [changeSet].
   */
  void _addPreviouslyExcludedSources(_ContextInfo info, ChangeSet changeSet,
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
        if (!shouldFileBeAnalyzed(child)) {
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
   * Resursively adds all Dart and HTML files to the [changeSet].
   */
  void _addSourceFiles(ChangeSet changeSet, Folder folder, _ContextInfo info) {
    if (info.excludesResource(folder) || folder.shortName.startsWith('.')) {
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
        if (shouldFileBeAnalyzed(child)) {
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

  /**
   * Cancel all dependency subscriptions for the given context.
   */
  void _cancelDependencySubscriptions(_ContextInfo info) {
    for (StreamSubscription<WatchEvent> s in info.dependencySubscriptions) {
      s.cancel();
    }
    info.dependencySubscriptions.clear();
  }

  void _checkForPackagespecUpdate(
      String path, _ContextInfo info, Folder folder) {
    // Check to see if this is the .packages file for this context and if so,
    // update the context's source factory.
    if (pathContext.basename(path) == PACKAGE_SPEC_NAME &&
        info.isPathToPackageDescription(path)) {
      File packagespec = resourceProvider.getFile(path);
      if (packagespec.exists) {
        Packages packages = _readPackagespec(packagespec);
        if (packages != null) {
          updateContextPackageUriResolver(folder, null, packages);
        }
      }
    }
  }

  /**
   * Compute the appropriate package URI resolver for [folder], and store
   * dependency information in [info]. Return `null` if no package map can
   * be computed.
   */
  UriResolver _computePackageUriResolver(Folder folder, _ContextInfo info) {
    _cancelDependencySubscriptions(info);
    if (info.packageRoot != null) {
      info.packageMapInfo = null;
      JavaFile packagesDir = new JavaFile(info.packageRoot);
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
        return new PackageMapUriResolver(resourceProvider, packageMap);
      }
      //TODO(danrubel) remove this if it will never be called
      return new PackageUriResolver([packagesDir]);
    } else {
      beginComputePackageMap();
      if (packageResolverProvider != null) {
        UriResolver resolver = packageResolverProvider(folder);
        if (resolver != null) {
          return resolver;
        }
      }
      OptimizingPubPackageMapInfo packageMapInfo;
      ServerPerformanceStatistics.pub.makeCurrentWhile(() {
        packageMapInfo =
            _packageMapProvider.computePackageMap(folder, info.packageMapInfo);
      });
      endComputePackageMap();
      for (String dependencyPath in packageMapInfo.dependencies) {
        Resource resource = resourceProvider.getResource(dependencyPath);
        if (resource is File) {
          StreamSubscription<WatchEvent> subscription;
          subscription = resource.changes.listen((WatchEvent event) {
            if (info.packageMapInfo != null &&
                info.packageMapInfo.isChangedDependency(
                    dependencyPath, resourceProvider)) {
              _recomputePackageUriResolver(info);
            }
          }, onError: (error, StackTrace stackTrace) {
            // Gracefully degrade if file is or becomes unwatchable
            _instrumentationService.logException(error, stackTrace);
            subscription.cancel();
            info.dependencySubscriptions.remove(subscription);
          });
          info.dependencySubscriptions.add(subscription);
        }
      }
      info.packageMapInfo = packageMapInfo;
      if (packageMapInfo.packageMap == null) {
        return null;
      }
      return new PackageMapUriResolver(
          resourceProvider, packageMapInfo.packageMap);
      // TODO(paulberry): if any of the dependencies is outside of [folder],
      // we'll need to watch their parent folders as well.
    }
  }

  /**
   * Create a new empty context associated with [folder].
   */
  _ContextInfo _createContext(
      Folder folder, File packagespecFile, List<_ContextInfo> children) {
    _ContextInfo info = new _ContextInfo(
        folder, packagespecFile, children, normalizedPackageRoots[folder.path]);
    _contexts[folder] = info;
    var options = analysisOptionsProvider.getOptions(folder);
    processOptionsForContext(folder, options);
    info.changeSubscription = folder.changes.listen((WatchEvent event) {
      _handleWatchEvent(folder, info, event);
    });
    try {
      Packages packages;
      UriResolver packageUriResolver;

      if (ENABLE_PACKAGESPEC_SUPPORT) {
        // Try .packages first.
        if (pathos.basename(packagespecFile.path) == PACKAGE_SPEC_NAME) {
          packages = _readPackagespec(packagespecFile);
        }
      }

      // Next resort to a package uri resolver.
      if (packages == null) {
        packageUriResolver = _computePackageUriResolver(folder, info);
      }

      info.context = addContext(folder, packageUriResolver, packages);
      info.context.name = folder.path;
    } catch (_) {
      info.changeSubscription.cancel();
      rethrow;
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
   * Returns created contexts.
   */
  List<_ContextInfo> _createContexts(Folder folder, bool withPackageSpecOnly) {
    // Try to find subfolders with pubspecs or .packages files.
    List<_ContextInfo> children = <_ContextInfo>[];
    try {
      for (Resource child in folder.getChildren()) {
        if (child is Folder) {
          children.addAll(_createContexts(child, true));
        }
      }
    } on FileSystemException {
      // The directory either doesn't exist or cannot be read. Either way, there
      // are no subfolders that need to be added.
    }

    File packageSpec;

    if (ENABLE_PACKAGESPEC_SUPPORT) {
      // Start by looking for .packages.
      packageSpec = folder.getChild(PACKAGE_SPEC_NAME);
    }

    // Fall back to looking for a pubspec.
    if (packageSpec == null || !packageSpec.exists) {
      packageSpec = folder.getChild(PUBSPEC_NAME);
    }

    if (packageSpec.exists) {
      return <_ContextInfo>[
        _createContextWithSources(folder, packageSpec, children)
      ];
    }
    // No packagespec? Done.
    if (withPackageSpecOnly) {
      return children;
    }
    // OK, create a context without a packagespec.
    return <_ContextInfo>[
      _createContextWithSources(folder, packageSpec, children)
    ];
  }

  /**
   * Create a new context associated with the given [folder]. The [pubspecFile]
   * is the `pubspec.yaml` file contained in the folder. Add any sources that
   * are not included in one of the [children] to the context.
   */
  _ContextInfo _createContextWithSources(
      Folder folder, File pubspecFile, List<_ContextInfo> children) {
    _ContextInfo info = _createContext(folder, pubspecFile, children);
    ChangeSet changeSet = new ChangeSet();
    _addSourceFiles(changeSet, folder, info);
    applyChangesToContext(folder, changeSet);
    return info;
  }

  /**
   * Clean up and destroy the context associated with the given folder.
   */
  void _destroyContext(Folder folder) {
    _ContextInfo info = _contexts[folder];
    info.changeSubscription.cancel();
    _cancelDependencySubscriptions(info);
    removeContext(folder);
    _contexts.remove(folder);
  }

  /**
   * Extract a new [packagespecFile]-based context from [oldInfo].
   */
  void _extractContext(_ContextInfo oldInfo, File packagespecFile) {
    Folder newFolder = packagespecFile.parent;
    _ContextInfo newInfo = _createContext(newFolder, packagespecFile, []);
    newInfo.parent = oldInfo;
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
      applyChangesToContext(newFolder, changeSet);
    }
    // update old context
    {
      ChangeSet changeSet = new ChangeSet();
      extractedSources.forEach((path, source) {
        oldInfo.sources.remove(path);
        changeSet.removedSource(source);
      });
      applyChangesToContext(oldInfo.folder, changeSet);
    }
  }

  void _handleWatchEvent(Folder folder, _ContextInfo info, WatchEvent event) {
    // TODO(brianwilkerson) If a file is explicitly included in one context
    // but implicitly referenced in another context, we will only send a
    // changeSet to the context that explicitly includes the file (because
    // that's the only context that's watching the file).
    _instrumentationService.logWatchEvent(
        folder.path, event.path, event.type.toString());
    String path = event.path;
    // maybe excluded globally
    if (_isExcluded(path)) {
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
        if (_isInPackagesDir(path, folder)) {
          return;
        }

        Resource resource = resourceProvider.getResource(path);

        if (ENABLE_PACKAGESPEC_SUPPORT) {
          String directoryPath = pathContext.dirname(path);

          // Check to see if we need to create a new context.
          if (info.isRoot) {

            // Only create a new context if this is not the same directory
            // described by our info object.
            if (info.folder.path != directoryPath) {
              if (_isPubspec(path)) {
                // Check for a sibling .packages file.
                if (!resourceProvider.getFile(
                    pathos.join(directoryPath, PACKAGE_SPEC_NAME)).exists) {
                  _extractContext(info, resource);
                  return;
                }
              }
              if (_isPackagespec(path)) {
                // Check for a sibling pubspec.yaml file.
                if (!resourceProvider
                    .getFile(pathos.join(directoryPath, PUBSPEC_NAME)).exists) {
                  _extractContext(info, resource);
                  return;
                }
              }
            }
          }
        } else {
          // pubspec was added in a sub-folder, extract a new context
          if (_isPubspec(path) &&
              info.isRoot &&
              !info.isPathToPackageDescription(path)) {
            _extractContext(info, resource);
            return;
          }
        }

        // If the file went away and was replaced by a folder before we
        // had a chance to process the event, resource might be a Folder.  In
        // that case don't add it.
        if (resource is File) {
          File file = resource;
          if (shouldFileBeAnalyzed(file)) {
            ChangeSet changeSet = new ChangeSet();
            Source source = createSourceInContext(info.context, file);
            changeSet.addedSource(source);
            applyChangesToContext(folder, changeSet);
            info.sources[path] = source;
          }
        }
        break;
      case ChangeType.REMOVE:

        // If package spec info is removed, check to see if we can merge contexts.
        // Note that it's important to verify that there is NEITHER a .packages nor a
        // lingering pubspec.yaml before merging.
        if (!info.isRoot) {
          if (ENABLE_PACKAGESPEC_SUPPORT) {
            String directoryPath = pathContext.dirname(path);

            // Only merge if this is the same directory described by our info object.
            if (info.folder.path == directoryPath) {
              if (_isPubspec(path)) {
                // Check for a sibling .packages file.
                if (!resourceProvider.getFile(
                    pathos.join(directoryPath, PACKAGE_SPEC_NAME)).exists) {
                  _mergeContext(info);
                  return;
                }
              }
              if (_isPackagespec(path)) {
                // Check for a sibling pubspec.yaml file.
                if (!resourceProvider
                    .getFile(pathos.join(directoryPath, PUBSPEC_NAME)).exists) {
                  _mergeContext(info);
                  return;
                }
              }
            }
          } else {
            if (info.isPathToPackageDescription(path)) {
              _mergeContext(info);
              return;
            }
          }
        }

        List<Source> sources = info.context.getSourcesWithFullName(path);
        if (!sources.isEmpty) {
          ChangeSet changeSet = new ChangeSet();
          sources.forEach((Source source) {
            changeSet.removedSource(source);
          });
          applyChangesToContext(folder, changeSet);
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
          applyChangesToContext(folder, changeSet);
        }
        break;
    }

    //TODO(pquitslund): find the right place for this
    _checkForPackagespecUpdate(path, info, folder);

    if (info.packageMapInfo != null &&
        info.packageMapInfo.isChangedDependency(path, resourceProvider)) {
      _recomputePackageUriResolver(info);
    }
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
      if (pathContext.isWithin(excludedPath, path)) {
        return true;
      }
      return path == excludedPath;
    });
  }

  /**
   * Determine if the path from [folder] to [path] contains a 'packages'
   * directory.
   */
  bool _isInPackagesDir(String path, Folder folder) {
    String relativePath = pathContext.relative(path, from: folder.path);
    List<String> pathParts = pathContext.split(relativePath);
    return pathParts.contains(PACKAGES_NAME);
  }

  bool _isPackagespec(String path) =>
      pathContext.basename(path) == PACKAGE_SPEC_NAME;

  bool _isPubspec(String path) => pathContext.basename(path) == PUBSPEC_NAME;

  /**
   * Merges [info] context into its parent.
   */
  void _mergeContext(_ContextInfo info) {
    // destroy the context
    _destroyContext(info.folder);
    // add files to the parent context
    _ContextInfo parentInfo = info.parent;
    if (parentInfo != null) {
      parentInfo.children.remove(info);
      ChangeSet changeSet = new ChangeSet();
      info.sources.forEach((path, source) {
        parentInfo.sources[path] = source;
        changeSet.addedSource(source);
      });
      applyChangesToContext(parentInfo.folder, changeSet);
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
   * Recompute the package URI resolver for the context described by [info],
   * and update the client appropriately.
   */
  void _recomputePackageUriResolver(_ContextInfo info) {
    // TODO(paulberry): when computePackageMap is changed into an
    // asynchronous API call, we'll want to suspend analysis for this context
    // while we're rerunning "pub list", since any analysis we complete while
    // "pub list" is in progress is just going to get thrown away anyhow.
    UriResolver packageUriResolver =
        _computePackageUriResolver(info.folder, info);
    updateContextPackageUriResolver(info.folder, packageUriResolver, null);
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

//  /**
//   * The default options used to create new analysis contexts.
//   */
//  AnalysisOptionsImpl get defaultOptions;

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

//  /**
//   * A stream that is notified when contexts are added or removed.
//   */
//  Stream<ContextsChangedEvent> get onContextsChanged;

  /**
   * Return a list containing all of the contexts contained in the given
   * [analysisRoot].
   */
  List<AnalysisContext> contextsInAnalysisRoot(Folder analysisRoot);

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
  ContextsChangedEvent({this.added: AnalysisContext.EMPTY_LIST,
      this.changed: AnalysisContext.EMPTY_LIST,
      this.removed: AnalysisContext.EMPTY_LIST});
}

/**
 * Information tracked by the [ContextManager] for each context.
 */
class _ContextInfo {
  /**
   * The [Folder] for which this information object is created.
   */
  final Folder folder;

  /// The [PathFilter] used to filter sources from being analyzed.
  final PathFilter pathFilter;

  /**
   * The enclosed pubspec-based contexts.
   */
  final List<_ContextInfo> children;

  /**
   * The package root for this context, or null if there is no package root.
   */
  String packageRoot;

  /**
   * The [_ContextInfo] that encloses this one.
   */
  _ContextInfo parent;

  /**
   * The package description file path for this context.
   */
  String packageDescriptionPath;

  /**
   * Stream subscription we are using to watch the context's directory for
   * changes.
   */
  StreamSubscription<WatchEvent> changeSubscription;

  /**
   * Stream subscriptions we are using to watch the files
   * used to determine the package map.
   */
  final List<StreamSubscription<WatchEvent>> dependencySubscriptions =
      <StreamSubscription<WatchEvent>>[];

  /**
   * The analysis context that was created for the [folder].
   */
  AnalysisContext context;

  /**
   * Map from full path to the [Source] object, for each source that has been
   * added to the context.
   */
  Map<String, Source> sources = new HashMap<String, Source>();

  /**
   * Info returned by the last call to
   * [OptimizingPubPackageMapProvider.computePackageMap], or `null` if the
   * package map hasn't been computed for this context yet.
   */
  OptimizingPubPackageMapInfo packageMapInfo;

  _ContextInfo(
      Folder folder, File packagespecFile, this.children, this.packageRoot)
      : folder = folder,
        pathFilter = new PathFilter(folder.path, null) {
    packageDescriptionPath = packagespecFile.path;
    for (_ContextInfo child in children) {
      child.parent = this;
    }
  }

  /**
   * Returns `true` if this context is root folder based.
   */
  bool get isRoot => parent == null;

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

  /// Returns `true` if  [path] should be ignored.
  bool ignored(String path) => pathFilter.ignored(path);

  /**
   * Returns `true` if [path] is the package description file for this context 
   * (pubspec.yaml or .packages).
   */
  bool isPathToPackageDescription(String path) =>
      path == packageDescriptionPath;
}
