// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:analysis_server/src/status/diagnostics.dart';
import 'package:analysis_server/src/status/pages.dart';
import 'package:analysis_server/src/status/utilities/library_cycle_extensions.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/library_graph.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;

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

  @override
  String? get navDetail {
    var problemCount = _collectComponents()
        .where((c) => c.hasPotentialProblem)
        .length;
    return problemCount > 0 ? '$problemCount' : null;
  }

  @override
  String? get navDetailClass => 'counter-red';

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
    return [
      _ContextsPerformanceComponent(this),
      _LibraryCyclesPerformanceComponent(this),
      // TODO(srawlins): Check for slow file reads.
      // TODO(srawlins): Check for presence of node_modules directories.
      // TODO(srawlins): Check for symlink explosions.
    ];
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

/// A component that analyzes and renders a specific performance aspect.
abstract class _PerformanceComponent {
  /// Whether this component currently indicates a potential performance issue.
  bool get hasPotentialProblem;

  /// The human-readable title of this component.
  String get title;

  /// Renders this component's content into [page].
  void render(PerformancePage page);
}
