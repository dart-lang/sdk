// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:analysis_server/src/status/diagnostics.dart';
import 'package:analysis_server/src/status/pages.dart';
import 'package:analysis_server/src/status/utilities/library_cycle_extensions.dart';
import 'package:analysis_server/src/status/utilities/string_extensions.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/source.dart';
import 'package:analyzer/src/dart/analysis/driver.dart' as analysis;
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/library_graph.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/workspace/pub.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:path/path.dart' as path;

class ContextsPage extends DiagnosticPageWithNav {
  ContextsPage(DiagnosticsSite site)
    : super(
        site,
        'contexts',
        'Contexts',
        description:
            'An analysis context defines a set of sources for which URIs are '
            'all resolved in the same way.',
      );

  @override
  String get navDetail => '${server.driverMap.length}';

  @override
  Future<void> generateContent(Map<String, String> params) async {
    var driverMap = SplayTreeMap.of(
      server.driverMap,
      (a, b) => a.path.compareTo(b.path),
    );
    if (driverMap.isEmpty) {
      blankslate('No contexts.');
      return;
    }

    var (folder: folder, driver: driver) = _currentContext(params, driverMap);
    var contextPath = folder.path;

    buf.writeln('<div class="tabnav">');
    buf.writeln('<nav class="tabnav-tabs">');
    for (var f in driverMap.keys) {
      var selectedClass = f == folder ? 'selected' : '';
      var href = '${this.path}?context=${Uri.encodeQueryComponent(f.path)}';
      buf.writeln(
        '<a href="${escape(href)}" class="tabnav-tab $selectedClass" title="${escape(f.path)}">${escape(f.shortName)}</a>',
      );
    }
    buf.writeln('</nav>');
    buf.writeln('</div>');

    buf.writeln(writeOption('Context location', escape(contextPath)));
    buf.writeln(
      writeOption('SDK root', escape(driver.analysisContext?.sdkRoot?.path)),
    );

    h3('Analysis options');

    // Display analysis options entries inside this context root.
    var separator = folder.provider.pathContext.separator;
    var foldersInContextRoot = driver.analysisOptionsMap.folders.where(
      (e) =>
          contextPath == e.path ||
          contextPath.startsWith('${e.path}$separator'),
    );
    ul(foldersInContextRoot, (folder) {
      buf.write(escape(folder.path));
      var optionsPath = path.join(folder.path, 'analysis_options.yaml');
      var contentsPath =
          '/contents?file=${Uri.encodeQueryComponent(optionsPath)}';
      buf.writeln(' <a href="$contentsPath">analysis_options.yaml</a>');
    }, classes: 'scroll-table');

    h3('Workspace');
    var workspace = driver.analysisContext!.contextRoot.workspace;
    buf.writeln('<p>');
    buf.writeln(writeOption('Workspace root', escape(workspace.root)));
    var workspaceFolder = folder.provider.getFolder(workspace.root);

    void writePackage(WorkspacePackageImpl package) {
      buf.writeln(writeOption('Package root', escape(package.root.path)));
      if (package is PubPackage) {
        buf.writeln(
          writeOption(
            'pubspec file',
            escape(
              workspaceFolder.getChildAssumingFile(file_paths.pubspecYaml).path,
            ),
          ),
        );
      }
    }

    var packageConfig = workspaceFolder
        .getChildAssumingFolder(file_paths.dotDartTool)
        .getChildAssumingFile(file_paths.packageConfigJson);
    buf.writeln(
      writeOption('Has package_config.json file', packageConfig.exists),
    );

    String lenCounter(int length) {
      return '<span class="counter" style="float: right;">$length</span>';
    }

    if (workspace is PackageConfigWorkspace) {
      var packages = workspace.allPackages;
      h4('Packages ${lenCounter(packages.length)}', raw: true);
      ul(packages, writePackage, classes: 'scroll-table');
    }
    buf.writeln('</p>');

    buf.writeln('</div>');

    h3('Plugins');
    var optionsData = collectOptionsData(driver);
    p(optionsData.plugins.toList().join(', '));

    var priorityFiles = driver.priorityFiles;
    var addedFiles = driver.addedFiles.toList();
    var knownFiles = driver.knownFiles.map((f) => f.path).toSet();
    var implicitFiles = knownFiles.difference(driver.addedFiles).toList();
    addedFiles.sort();
    implicitFiles.sort();

    h3('Context files');

    void writeFile(String file) {
      var astPath = '/ast?file=${Uri.encodeQueryComponent(file)}';
      var elementPath = '/element-model?file=${Uri.encodeQueryComponent(file)}';
      var contentsPath = '/contents?file=${Uri.encodeQueryComponent(file)}';
      var hasOverlay = server.resourceProvider.hasOverlay(file);

      buf.write(file.wordBreakOnSlashes);
      buf.writeln(' <a href="$astPath">ast</a>');
      buf.writeln(' <a href="$elementPath">element</a>');
      buf.writeln(
        ' <a href="$contentsPath">contents${hasOverlay ? '*' : ''}</a>',
      );
    }

    h4('Priority files ${lenCounter(priorityFiles.length)}', raw: true);
    ul(priorityFiles, writeFile, classes: 'scroll-table');

    h4('Added files ${lenCounter(addedFiles.length)}', raw: true);
    ul(addedFiles, writeFile, classes: 'scroll-table');

    h4('Implicit files ${lenCounter(implicitFiles.length)}', raw: true);
    ul(implicitFiles, writeFile, classes: 'scroll-table');

    var sourceFactory = driver.sourceFactory;
    if (sourceFactory is SourceFactoryImpl) {
      h3('Resolvers');
      for (var resolver in sourceFactory.resolvers) {
        h4(resolver.runtimeType.toString());
        buf.write('<p class="scroll-table">');
        if (resolver is DartUriResolver) {
          var sdk = resolver.dartSdk;
          buf.write(' (sdk = ');
          buf.write(sdk.runtimeType);
          if (sdk is FolderBasedDartSdk) {
            buf.write(' (path = ');
            buf.write(sdk.directory.path);
            buf.write(')');
          } else if (sdk is EmbedderSdk) {
            buf.write(' (map = ');
            writeMap(sdk.urlMappings);
            buf.write(')');
          }
          buf.write(')');
        } else if (resolver is PackageMapUriResolver) {
          writeMap(resolver.packageMap);
        } else if (resolver is PackageConfigPackageUriResolver) {
          writeMap(resolver.packageMap);
        }
        buf.write('</p>');
      }
    }

    h3('Dartdoc template info');
    var info = driver.dartdocDirectiveInfo;
    buf.write('<p class="scroll-table">');
    writeMap(info.templateMap);
    buf.write('</p>');

    h3('Largest library cycles');
    Set<LibraryCycle> cycles = {};
    var contextRoot = driver.analysisContext!.contextRoot;
    var pathContext = contextRoot.resourceProvider.pathContext;
    for (var filePath in contextRoot.analyzedFiles()) {
      if (!file_paths.isDart(pathContext, filePath)) continue;
      var fileState = driver.fsState.getFileForPath(filePath);
      var kind = fileState.kind;
      if (kind is LibraryFileKind) {
        cycles.add(kind.libraryCycle);
      }
    }
    var sortedMultiLibraryCycles =
        cycles.where((cycle) => cycle.size > 1).toList()
          ..sort((first, second) => second.size - first.size);
    var cyclesToDisplay = math.min(sortedMultiLibraryCycles.length, 10);
    var initialPathLength = contextRoot.root.path.length + 1;
    buf.write('<p>There are ${cycles.length} library cycles. ');
    if (cyclesToDisplay < 10) {
      buf.write(
        '$cyclesToDisplay of these have more than one library. '
        'They contain</p>',
      );
    } else {
      buf.write('The $cyclesToDisplay largest contain</p>');
    }
    buf.write('<ul>');
    for (var i = 0; i < cyclesToDisplay; i++) {
      var cycle = sortedMultiLibraryCycles[i];
      var libraries = cycle.libraries;
      var cycleSize = cycle.size;
      var libraryCount = math.min(cycleSize, 8);
      buf.write('<li>$cycleSize libraries, including');
      buf.write('<ul>');
      for (var j = 0; j < libraryCount; j++) {
        var library = libraries[j];
        buf.write('<li>');
        buf.write(library.file.path.substring(initialPathLength));
        buf.write('</li>');
      }
      if (cycleSize > libraryCount) {
        buf.write('<li>${cycleSize - libraryCount} more...</li>');
      }
      buf.write('</ul>');
      buf.write('</li>');
    }
    buf.write('</ul>');
  }

  void writeList<E>(List<E> list) {
    buf.writeln('[${list.join(', ')}]');
  }

  void writeMap<V>(Map<String, V> map) {
    var keys = map.keys.toList();
    keys.sort();
    var length = keys.length;
    buf.write('{');
    for (var i = 0; i < length; i++) {
      buf.write('<br>');
      var key = keys[i];
      var value = map[key];
      buf.write(key);
      buf.write(' = ');
      if (value is List) {
        writeList(value);
      } else {
        buf.write(value);
      }
      buf.write(',');
    }
    buf.write('<br>}');
  }

  /// Information regarding the context currently being displayed.
  ({Folder folder, analysis.AnalysisDriver driver}) _currentContext(
    Map<String, String> params,
    Map<Folder, analysis.AnalysisDriver> driverMap,
  ) {
    var contextPath = params['context'];
    if (contextPath == null) {
      return (
        folder: driverMap.entries.first.key,
        driver: driverMap.entries.first.value,
      );
    } else {
      var entry = driverMap.entries.firstWhere(
        (e) => e.key.path == contextPath,
        orElse: () => driverMap.entries.first,
      );
      return (folder: entry.key, driver: entry.value);
    }
  }
}
