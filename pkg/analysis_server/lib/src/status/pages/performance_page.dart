// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:analysis_server/src/status/diagnostics.dart';
import 'package:analysis_server/src/status/pages.dart';
import 'package:analysis_server/src/status/utilities/library_cycle_extensions.dart';
import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/library_graph.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:path/path.dart' as path;

/// A diagnostic page reporting performance-related health checks and
/// diagnostics.
class PerformancePage extends DiagnosticPageWithNav {
  new(DiagnosticsSite site)
    : super(
        site,
        'performance',
        'Performance',
        description:
            'Performance diagnostics and health checks for the '
            'analysis server.',
      );

  // Computing the detail checks all of the components, which can involve
  // walking the file system; see [DiagnosticPageWithNav.navDetailParameter].
  @override
  bool get loadsNavDetailAsynchronously => true;

  @override
  String? get navDetail {
    var problemCount = _collectComponents()
        .where((c) => c.hasPotentialProblem)
        .length;
    return problemCount > 0 ? '$problemCount' : null;
  }

  @override
  String? get navDetailClass => 'counter-red';

  path.Context get pathContext => server.resourceProvider.pathContext;

  @override
  Future<void> generateContent(Map<String, String> params) async {
    var components = _collectComponents();
    var problems = components.where((c) => c.hasPotentialProblem).toList();
    var healthy = components.where((c) => !c.hasPotentialProblem).toList();

    if (problems.isNotEmpty) {
      h2('Potential Problems');
      for (var component in problems) {
        div(() {
          h3(component.title);
          component.render(this);
        }, classes: 'flash flash-warn mb-3');
      }
    } else {
      div(() {
        buf.writeln(
          '<strong>All Clear:</strong> No obvious performance problems detected.',
        );
      }, classes: 'flash flash-success mb-3');
    }

    if (healthy.isNotEmpty) {
      h2('Other Information');
      for (var component in healthy) {
        div(() {
          h3(component.title);
          component.render(this);
        }, classes: 'Box p-3 mb-3 text-gray');
      }
    }
  }

  List<_PerformanceComponent> _collectComponents() {
    // The components walk the file system whenever this page is rendered, and
    // whenever the browser loads the navigation detail of any page; keep this
    // out of the File I/O timing page.
    return server.timingResourceProvider.withoutMeasuring(
      () => [
        _ContextsPerformanceComponent(this),
        _LibraryCyclesPerformanceComponent(this),
        _NodeModulesPerformanceComponent(this),
        _SymlinksPerformanceComponent(this),
        // TODO(srawlins): Check for slow file reads.
      ],
    );
  }
}

/// Component reporting on the number of active analysis contexts.
class _ContextsPerformanceComponent implements _PerformanceComponent {
  static const _problematicContextCount = 10;
  final PerformancePage page;

  final int contextCount;

  new(this.page) : contextCount = page.driverMap.length;

  @override
  bool get hasPotentialProblem => contextCount > _problematicContextCount;

  @override
  String get title => 'Analysis Contexts';

  @override
  void render(PerformancePage page) {
    if (hasPotentialProblem) {
      page.p(
        'There are <strong>$contextCount</strong> analysis contexts currently '
        'being analyzed.',
        raw: true,
      );
      page.p(
        'Having more than $_problematicContextCount analysis contexts can '
        'significantly increase memory usage and analysis latency. Consider '
        'collapsing multiple analysis contexts into a single workspace using '
        '<a href="https://dart.dev/tools/pub/workspaces" target="_blank">pub workspaces</a>.',
        raw: true,
      );
    } else {
      page.p(
        'There ${contextCount == 1 ? 'is' : 'are'} '
        '<strong>$contextCount</strong> analysis '
        'context${contextCount == 1 ? '' : 's'} being analyzed. '
        '(<a href="contexts">View contexts</a>)',
        raw: true,
      );
    }

    page.p(
      'The analysis server consumes more memory and resources when analyzing '
      'multiple analysis contexts. Using '
      '<a href="https://dart.dev/tools/pub/workspaces" target="_blank">pub workspaces</a> '
      'can reduce the number of contexts by managing multiple packages in a '
      'single shared workspace.',
      raw: true,
    );
  }
}

/// Information about a large library cycle detected in an analysis context.
class _LargeCycleInfo {
  final Folder folder;
  final LibraryCycle cycle;

  new({required this.folder, required this.cycle});
}

/// Component reporting on large library cycles (>20 libraries).
class _LibraryCyclesPerformanceComponent implements _PerformanceComponent {
  static const _problematicCycleSize = 20;
  final PerformancePage page;
  final List<_LargeCycleInfo> largeCycles = [];

  int totalCycleCount = 0;

  new(this.page) {
    for (var entry in page.driverMap.entries) {
      var folder = entry.key;
      var driver = entry.value;
      var contextRoot = driver.analysisContext?.contextRoot;
      if (contextRoot == null) continue;
      var pathContext = contextRoot.resourceProvider.pathContext;

      var cyclesInDriver = <LibraryCycle>{};
      for (var filePath in contextRoot.analyzedFiles()) {
        if (!file_paths.isDart(pathContext, filePath)) continue;
        var fileState = driver.fsState.getFileForPath(filePath);
        var kind = fileState.kind;
        if (kind is LibraryFileKind) {
          cyclesInDriver.add(kind.libraryCycle);
        }
      }

      totalCycleCount += cyclesInDriver.length;
      for (var cycle in cyclesInDriver) {
        if (cycle.size > _problematicCycleSize) {
          largeCycles.add(_LargeCycleInfo(folder: folder, cycle: cycle));
        }
      }
    }

    largeCycles.sort((a, b) => b.cycle.size.compareTo(a.cycle.size));
  }

  @override
  bool get hasPotentialProblem => largeCycles.isNotEmpty;

  @override
  String get title => 'Library Cycles';

  @override
  void render(PerformancePage page) {
    page.p(
      'A library cycle is a cycle in the import/export graph. Large library '
      'cycles can lead to slower incremental analysis time (the time to '
      're-analyze as you edit code). Breaking up cycles into smaller, modular '
      'libraries can significantly improve incremental analysis speed.',
    );

    if (hasPotentialProblem) {
      var count = largeCycles.length;
      page.p(
        'Detected <strong>$count</strong> large library '
        'cycle${count == 1 ? '' : 's'} containing more than '
        '$_problematicCycleSize libraries:',
        raw: true,
      );

      const maxToDisplay = 20;
      var cyclesToDisplay = math.min(count, maxToDisplay);

      page.buf.writeln('<ul>');
      for (var i = 0; i < cyclesToDisplay; i++) {
        var info = largeCycles[i];
        var cycle = info.cycle;
        var folder = info.folder;
        var contextPath = folder.path;
        var pathContext = folder.provider.pathContext;
        var contextHref =
            'contexts?context=${Uri.encodeQueryComponent(contextPath)}';
        var libraries = cycle.libraries;
        var cycleSize = cycle.size;
        var libraryCount = math.min(cycleSize, 8);

        page.buf.write('<li>');
        page.buf.write(
          '<strong>$cycleSize libraries</strong> in context '
          '<a href="$contextHref"><code>${escape(folder.shortName)}</code></a>, '
          'including:',
        );
        page.buf.write('<ul>');
        for (var j = 0; j < libraryCount; j++) {
          var library = libraries[j];
          var libPath = library.file.path;
          var relativePath = pathContext.isWithin(contextPath, libPath)
              ? pathContext.relative(libPath, from: contextPath)
              : libPath;
          page.buf.write('<li><code>${escape(relativePath)}</code></li>');
        }
        if (cycleSize > libraryCount) {
          page.buf.write(
            '<li><em>${cycleSize - libraryCount} more...</em></li>',
          );
        }
        page.buf.write('</ul>');
        page.buf.write('</li>');
      }
      page.buf.writeln('</ul>');

      if (count > maxToDisplay) {
        var remaining = count - maxToDisplay;
        page.p(
          'plus $remaining more potentially problematic library '
          'cycle${remaining == 1 ? '' : 's'}.',
        );
      }
    } else {
      page.p(
        'No large library cycles (>$_problematicCycleSize libraries) were '
        'detected across $totalCycleCount library '
        'cycle${totalCycleCount == 1 ? '' : 's'}. '
        '(<a href="contexts">View context cycles</a>)',
        raw: true,
      );
    }
  }
}

/// Information about an unexcluded `node_modules` directory in an analysis context.
class _NodeModulesDirectoryInfo {
  final String contextPath;
  final String nodeModulesPath;

  new({required this.contextPath, required this.nodeModulesPath});
}

/// Component reporting on unexcluded `node_modules` directories.
class _NodeModulesPerformanceComponent implements _PerformanceComponent {
  final PerformancePage page;
  final List<_NodeModulesDirectoryInfo> nodeModulesDirectories = [];

  new(this.page) {
    for (var entry in page.driverMap.entries) {
      var contextFolder = entry.key;
      var driver = entry.value;
      var contextRoot = driver.analysisContext?.contextRoot;
      if (contextRoot == null) continue;

      var foundPaths = _findNodeModules(contextRoot);
      for (var path in foundPaths) {
        nodeModulesDirectories.add(
          _NodeModulesDirectoryInfo(
            contextPath: contextFolder.path,
            nodeModulesPath: path,
          ),
        );
      }
    }
  }

  @override
  bool get hasPotentialProblem => nodeModulesDirectories.isNotEmpty;

  @override
  String get title => 'node_modules Directories';

  @override
  void render(PerformancePage page) {
    if (hasPotentialProblem) {
      var count = nodeModulesDirectories.length;
      page.p(
        'Detected <strong>$count</strong> unexcluded <code>node_modules</code> '
        'director${count == 1 ? 'y' : 'ies'} within analyzed contexts:',
        raw: true,
      );

      var pathContext = page.pathContext;

      page.buf.writeln('<ul>');
      for (var info in nodeModulesDirectories) {
        var _NodeModulesDirectoryInfo(:contextPath, :nodeModulesPath) = info;
        var relativePath = pathContext.isWithin(contextPath, nodeModulesPath)
            ? pathContext.relative(nodeModulesPath, from: contextPath)
            : nodeModulesPath;
        var contextHref =
            'contexts?context=${Uri.encodeQueryComponent(contextPath)}';
        var contextName = pathContext.basename(contextPath);

        page.buf.write('<li>');
        page.buf.write(
          '<code>${escape(relativePath)}</code> in context '
          '<a href="$contextHref"><code>${escape(contextName)}</code></a>',
        );
        page.buf.write('</li>');
      }
      page.buf.writeln('</ul>');

      page.p(
        'The analysis server can spend significant time and memory watching and '
        'scanning large directory trees like <code>node_modules</code>. Consider '
        'excluding them in your <code>analysis_options.yaml</code> file:',
        raw: true,
      );
      page.pre(() {
        page.buf.writeln('analyzer:');
        page.buf.writeln('  exclude:');
        page.buf.writeln('    - "**/node_modules/**"');
      });
    } else {
      page.p(
        'No unexcluded <code>node_modules</code> directories were detected in '
        'analyzed contexts.',
        raw: true,
      );
      page.p(
        'Directories named <code>node_modules</code> can contain tens of '
        'thousands of files. If present, they should be excluded in '
        '<code>analysis_options.yaml</code> to avoid slowing down analysis.',
        raw: true,
      );
    }
  }

  static List<String> _findNodeModules(ContextRoot contextRoot) {
    var results = <String>[];
    var visited = <String>{};

    void searchFolder(Folder folder) {
      String canonicalPath;
      try {
        canonicalPath = folder.resolveSymbolicLinksSync().path;
      } on FileSystemException {
        return;
      }
      if (!visited.add(canonicalPath)) return;

      List<Folder> children;
      try {
        children = folder.getChildren().whereType<Folder>().toList();
      } on FileSystemException {
        return;
      }

      for (var child in children) {
        var basename = child.shortName;
        if (basename.startsWith('.')) continue;

        if (basename == 'node_modules') {
          if (contextRoot.isAnalyzed(child.path)) {
            results.add(child.path);
          }
          // Do not recurse into 'node_modules'.
          continue;
        }

        if (contextRoot.isAnalyzed(child.path)) {
          searchFolder(child);
        }
      }
    }

    for (var included in contextRoot.included) {
      if (included is Folder) {
        searchFolder(included);
      }
    }

    return results;
  }
}

/// A component that analyzes and renders a specific performance aspect.
abstract class _PerformanceComponent {
  /// Whether this component currently indicates a potential performance issue.
  bool get hasPotentialProblem;

  /// The human-readable title of this component.
  String get title;

  /// Renders this component's content into [page].
  void render(PerformancePage page);
}

/// The Dart files that are analyzed through a symlink to a directory.
class _SymlinkedFiles {
  /// The context whose analysis reaches the symlink.
  final ContextRoot contextRoot;

  /// The contexts that were created for directories behind the symlink.
  final Set<ContextRoot> createdContexts = {};

  /// The number of Dart files that are analyzed through the symlink.
  int dartFileCount = 0;

  new(this.contextRoot);
}

/// Information about a symlink to a directory, through which Dart files are
/// analyzed.
class _SymlinkInfo {
  /// The path of the context whose analysis reaches the symlink.
  final String contextPath;

  /// The path of the symlink.
  final String linkPath;

  /// The canonical path of the directory that the symlink points to, or `null`
  /// if the symlink cannot be resolved.
  final String? targetPath;

  /// The number of Dart files that are analyzed through the symlink.
  final int dartFileCount;

  /// The number of additional analysis contexts that were created for
  /// directories behind the symlink.
  final int createdContextCount;

  /// Whether the symlink points to the directory that contains it, or to one of
  /// the ancestors of that directory.
  final bool pointsToParent;

  /// Whether the symlink points to a directory that is inside the context.
  final bool pointsIntoContext;

  /// A pattern that excludes the symlink, as it would be written in the
  /// `exclude` section of the context's analysis options file.
  final String excludePattern;

  new({
    required this.contextPath,
    required this.linkPath,
    required this.targetPath,
    required this.dartFileCount,
    required this.createdContextCount,
    required this.pointsToParent,
    required this.pointsIntoContext,
    required this.excludePattern,
  });
}

/// Component that reports on symlinks to directories that make DAS analyze a
/// large number of Dart files, or create additional analysis contexts.
///
/// DAS follows symlinks to directories and analyzes every Dart file that it
/// finds along the way. A file that is reachable through multiple paths may be
/// analyzed once for each of them, so a symlink to a directory that is already
/// part of the context (or to a parent directory, or to a large directory tree)
/// can make the server analyze the same code over and over. What is more, a
/// symlink to a directory with its own package configuration, such as the
/// directory that contains the symlink, creates an additional analysis context
/// for that directory.
///
/// To avoid walking the file system again, this component starts from the
/// folders that each context includes, and from the files that have been added
/// to each context's analysis driver, and looks for symlinks in their paths.
class _SymlinksPerformanceComponent implements _PerformanceComponent {
  /// The number of Dart files, across all contexts, that can be analyzed
  /// through symlinks before the symlinks are considered a potential problem.
  static const _problematicDartFileCount = 100;

  final PerformancePage page;

  /// The symlinks through which Dart files are analyzed, or behind which
  /// additional analysis contexts were created, from the symlink with the most
  /// files to the one with the fewest.
  final List<_SymlinkInfo> symlinks = [];

  /// The number of Dart files that are analyzed through [symlinks].
  int linkedDartFileCount = 0;

  /// The number of Dart files that are analyzed, whether or not they are
  /// reached through a symlink.
  int totalDartFileCount = 0;

  new(this.page) {
    var contexts = [
      for (var driver in page.driverMap.values)
        if (driver.analysisContext?.contextRoot case var contextRoot?)
          (contextRoot: contextRoot, addedFiles: driver.addedFiles),
    ];

    var includedFolders = {
      for (var (:contextRoot, addedFiles: _) in contexts)
        for (var included in contextRoot.included)
          if (included is Folder) included.path: contextRoot,
    };

    // The symlinks, by path, through which Dart files are analyzed.
    var symlinkedFiles = <String, _SymlinkedFiles>{};

    // A context that was created for a directory behind a symlink is not seen
    // by the files of the context that contains the symlink, because that
    // context excludes the directory. Find these contexts by their included
    // folders instead.
    var symlinksByIncludedFolder = <String, String>{};
    for (var (:contextRoot, addedFiles: _) in contexts) {
      for (var included in contextRoot.included) {
        if (included is! Folder) continue;

        var enclosing = _findEnclosingSymlink(
          contextRoot,
          included.path,
          includedFolders,
        );
        if (enclosing == null) continue;

        var (:symlinkPath, :enclosingRoot) = enclosing;
        symlinksByIncludedFolder[included.path] = symlinkPath;
        symlinkedFiles
            .putIfAbsent(symlinkPath, () => _SymlinkedFiles(enclosingRoot))
            .createdContexts
            .add(contextRoot);
      }
    }

    for (var (:contextRoot, :addedFiles) in contexts) {
      _collectSymlinkedFiles(
        contextRoot,
        addedFiles,
        symlinksByIncludedFolder,
        symlinkedFiles,
      );
    }

    for (var MapEntry(key: symlinkPath, value: files)
        in symlinkedFiles.entries) {
      symlinks.add(_createSymlinkInfo(symlinkPath, files));
    }
    symlinks.sort((a, b) {
      var result = b.dartFileCount.compareTo(a.dartFileCount);
      return result != 0 ? result : a.linkPath.compareTo(b.linkPath);
    });
  }

  @override
  bool get hasPotentialProblem =>
      linkedDartFileCount > _problematicDartFileCount ||
      symlinks.any((info) => info.createdContextCount > 0);

  @override
  String get title => 'Symlinks';

  @override
  void render(PerformancePage page) {
    var count = symlinks.length;
    var directories = 'director${count == 1 ? 'y' : 'ies'}';
    var explanation =
        'The analysis server follows symlinks to directories and analyzes '
        'every Dart file it finds, once for each path that leads to the file. '
        'Symlinks to directories that are already part of a context, to '
        'parent directories, or to large directory trees can cause the same '
        'files to be analyzed repeatedly, which increases memory usage and '
        'analysis time, and can produce duplicate diagnostics. A symlink to a '
        'directory with its own package configuration even creates an '
        'additional analysis context.';

    if (hasPotentialProblem) {
      var percentage = totalDartFileCount == 0
          ? ''
          : ' (${printPercentage(linkedDartFileCount / totalDartFileCount)} '
                'of the Dart files being analyzed)';
      page.p(
        'Detected <strong>$count</strong> symlinked $directories through '
        'which <strong>$linkedDartFileCount</strong> Dart '
        'file${linkedDartFileCount == 1 ? '' : 's'}$percentage '
        '${linkedDartFileCount == 1 ? 'is' : 'are'} analyzed:',
        raw: true,
      );

      const maxToDisplay = 20;
      var symlinksToDisplay = symlinks.take(maxToDisplay).toList();
      var pathContext = page.pathContext;

      page.buf.writeln('<ul>');
      for (var info in symlinksToDisplay) {
        var _SymlinkInfo(
          :contextPath,
          :linkPath,
          :targetPath,
          :dartFileCount,
          :createdContextCount,
        ) = info;
        var relativePath = pathContext.isWithin(contextPath, linkPath)
            ? pathContext.relative(linkPath, from: contextPath)
            : linkPath;
        var contextHref =
            'contexts?context=${Uri.encodeQueryComponent(contextPath)}';
        var contextName = pathContext.basename(contextPath);
        var notes = [
          if (createdContextCount == 1)
            'creates an additional analysis context'
          else if (createdContextCount > 1)
            'creates $createdContextCount additional analysis contexts',
          if (info.pointsToParent) 'points to a parent directory',
          if (info.pointsIntoContext) 'points into this context',
        ];

        page.buf.write('<li>');
        page.buf.write('<code>${escape(relativePath)}</code>');
        if (targetPath != null) {
          page.buf.write(' &rarr; <code>${escape(targetPath)}</code>');
        }
        page.buf.write(
          ': <strong>$dartFileCount Dart '
          'file${dartFileCount == 1 ? '' : 's'}</strong> in context '
          '<a href="$contextHref"><code>${escape(contextName)}</code></a>',
        );
        if (notes.isNotEmpty) {
          page.buf.write(' <em>(${notes.join(', ')})</em>');
        }
        page.buf.write('</li>');
      }
      page.buf.writeln('</ul>');

      if (count > maxToDisplay) {
        var remaining = count - maxToDisplay;
        page.p('plus $remaining more symlink${remaining == 1 ? '' : 's'}.');
      }

      page.p(
        '$explanation Consider excluding the symlinks that do not need to be '
        'analyzed in your <code>analysis_options.yaml</code> file:',
        raw: true,
      );
      page.pre(() {
        page.buf.writeln('analyzer:');
        page.buf.writeln('  exclude:');
        for (var info in symlinksToDisplay) {
          var pattern = info.excludePattern.replaceAll("'", "''");
          page.buf.writeln("    - '${escape(pattern)}'");
        }
      });
    } else {
      if (symlinks.isEmpty) {
        page.p(
          'No symlinks to directories were detected among the Dart files '
          'being analyzed.',
        );
      } else {
        page.p(
          'Detected <strong>$count</strong> symlinked $directories through '
          'which <strong>$linkedDartFileCount</strong> Dart '
          'file${linkedDartFileCount == 1 ? ' is' : 's are'} analyzed, which '
          'is unlikely to affect performance.',
          raw: true,
        );
      }
      page.p(explanation);
    }

    page.p(
      'Symlinks inside hidden directories (those with names starting with '
      '<code>.</code>), such as the <code>.symlinks</code> directories that '
      'Flutter creates, are not followed when finding the files to analyze, '
      'and are not reported here.',
      raw: true,
    );
  }

  /// Collects the Dart files that the context with the given [contextRoot]
  /// analyzes through symlinks into [symlinkedFiles], from the [addedFiles] of
  /// its driver.
  ///
  /// The [symlinksByIncludedFolder] maps the folders that were included because
  /// they are behind a symlink to that symlink.
  void _collectSymlinkedFiles(
    ContextRoot contextRoot,
    Iterable<String> addedFiles,
    Map<String, String> symlinksByIncludedFolder,
    Map<String, _SymlinkedFiles> symlinkedFiles,
  ) {
    var provider = contextRoot.resourceProvider;
    var pathContext = provider.pathContext;
    var includedFolderPaths = {
      for (var included in contextRoot.included)
        if (included is Folder) included.path,
    };

    // Count the files in each directory, so that each directory is examined
    // only once, no matter how many files it contains.
    var dartFileCounts = <String, int>{};
    for (var path in addedFiles) {
      if (!file_paths.isDart(pathContext, path)) continue;

      dartFileCounts.update(
        pathContext.dirname(path),
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }

    // Maps each directory that has been examined to the outermost symlink in
    // its path, or to `null` if there is none.
    var outermostSymlinks = <String, String?>{};

    // Returns the outermost symlink between an included folder and [directory].
    //
    // Everything below the outermost symlink is reached through that symlink,
    // so it is the symlink to exclude in order to stop analyzing those files.
    String? outermostSymlink(String directory) {
      // Find the closest ancestor with a known answer. [unchecked] holds the
      // directories below that ancestor, from the innermost to the outermost.
      var unchecked = <String>[];
      var current = directory;
      String? symlink;
      while (true) {
        if (includedFolderPaths.contains(current)) {
          // Everything in a folder that is behind a symlink is reached through
          // that symlink.
          symlink = symlinksByIncludedFolder[current];
          break;
        }
        if (outermostSymlinks.containsKey(current)) {
          symlink = outermostSymlinks[current];
          break;
        }
        var parent = pathContext.dirname(current);
        // [directory] is not inside an included folder, so there is nothing to
        // report (and the ancestors of an included folder must not be
        // mistaken for symlinks that lead into it).
        if (parent == current) return null;
        unchecked.add(current);
        current = parent;
      }

      for (var path in unchecked.reversed) {
        symlink ??= provider.getLink(path).exists ? path : null;
        outermostSymlinks[path] = symlink;
      }
      return symlink;
    }

    for (var MapEntry(key: directory, value: count) in dartFileCounts.entries) {
      totalDartFileCount += count;

      var symlink = outermostSymlink(directory);
      if (symlink == null) continue;

      linkedDartFileCount += count;
      var files = symlinkedFiles.putIfAbsent(
        symlink,
        () => _SymlinkedFiles(contextRoot),
      );
      files.dartFileCount += count;
    }
  }

  /// Creates the information about the symlink at [linkPath], through which the
  /// [files] are analyzed.
  _SymlinkInfo _createSymlinkInfo(String linkPath, _SymlinkedFiles files) {
    var contextRoot = files.contextRoot;
    var provider = contextRoot.resourceProvider;
    var pathContext = provider.pathContext;

    String? canonicalPath(String path) {
      try {
        return provider.getFolder(path).resolveSymbolicLinksSync().path;
      } on FileSystemException {
        return null;
      }
    }

    var targetPath = canonicalPath(linkPath);
    var parentPath = canonicalPath(pathContext.dirname(linkPath));
    var pointsToParent =
        targetPath != null &&
        parentPath != null &&
        (targetPath == parentPath ||
            pathContext.isWithin(targetPath, parentPath));
    var pointsIntoContext =
        targetPath != null &&
        contextRoot.included.any((included) {
          if (included is! Folder) return false;
          var includedPath = canonicalPath(included.path);
          return includedPath != null &&
              (targetPath == includedPath ||
                  pathContext.isWithin(includedPath, targetPath));
        });

    // Patterns in an analysis options file are relative to the directory that
    // contains the file, which may be an ancestor of the context root, and
    // always use forward slashes.
    var baseDirectory = contextRoot.optionsFile?.parent.path;
    if (baseDirectory == null ||
        !pathContext.isWithin(baseDirectory, linkPath)) {
      baseDirectory = contextRoot.root.path;
    }
    var excludePattern = pathContext.isWithin(baseDirectory, linkPath)
        ? '${pathContext.split(pathContext.relative(linkPath, from: baseDirectory)).join('/')}/**'
        : '$linkPath/**';

    return _SymlinkInfo(
      contextPath: contextRoot.root.path,
      linkPath: linkPath,
      targetPath: targetPath,
      dartFileCount: files.dartFileCount,
      createdContextCount: files.createdContexts.length,
      pointsToParent: pointsToParent,
      pointsIntoContext: pointsIntoContext,
      excludePattern: excludePattern,
    );
  }

  /// Finds the outermost symlink in the path of the folder at [folderPath],
  /// which is included by the context with the given [contextRoot], that is
  /// below a folder that is included by another context.
  ///
  /// The context locator creates a context for a directory that has its own
  /// package configuration, and it excludes the directory from the context that
  /// contains it. So when a context is created for a directory behind a
  /// symlink, then the other context is the one whose analysis reaches the
  /// symlink, and it is the one in which the symlink can be excluded.
  ///
  /// Returns the path of the symlink and the enclosing context, or `null` if
  /// there is no such symlink. Symlinks in the path of the enclosing context's
  /// included folder itself, such as `/tmp` on macOS, do not count: they are
  /// only the way in which the folder was opened.
  static ({String symlinkPath, ContextRoot enclosingRoot})?
  _findEnclosingSymlink(
    ContextRoot contextRoot,
    String folderPath,
    Map<String, ContextRoot> includedFolders,
  ) {
    var provider = contextRoot.resourceProvider;
    var pathContext = provider.pathContext;

    // The folders between the folder and the enclosing context, from the
    // innermost to the outermost.
    var folders = <String>[];
    var current = folderPath;
    while (true) {
      folders.add(current);
      var parent = pathContext.dirname(current);
      if (parent == current) return null;
      current = parent;

      var enclosingRoot = includedFolders[current];
      if (enclosingRoot != null && enclosingRoot != contextRoot) {
        for (var path in folders.reversed) {
          if (provider.getLink(path).exists) {
            return (symlinkPath: path, enclosingRoot: enclosingRoot);
          }
        }
        return null;
      }
    }
  }
}
