// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/edit/nnbd_migration/migration_info.dart';
import 'package:analysis_server/src/edit/nnbd_migration/offset_mapper.dart';
import 'package:meta/meta.dart';
import 'package:mustache/mustache.dart' as mustache;
import 'package:path/path.dart' as path;

/// Instrumentation display output for a library that was migrated to use
/// non-nullable types.
class InstrumentationRenderer {
  /// Display information for a library.
  final LibraryInfo libraryInfo;

  /// Information for a whole migration, so that libraries can reference each
  /// other.
  final MigrationInfo migrationInfo;

  /// Creates an output object for the given library info.
  InstrumentationRenderer(this.libraryInfo, this.migrationInfo);

  /// Builds an HTML view of the instrumentation information in [libraryInfo].
  String render() {
    Map<String, dynamic> mustacheContext = {
      'units': <Map<String, dynamic>>[],
      'links': migrationInfo.libraryLinks(libraryInfo),
      'highlightJsPath': migrationInfo.highlightJsPath(libraryInfo),
      'highlightStylePath': migrationInfo.highlightStylePath(libraryInfo),
    };
    for (var compilationUnit in libraryInfo.units) {
      mustacheContext['units'].add({
        'path': compilationUnit.path,
        'regions': _computeRegions(compilationUnit),
        'targetRegions': _computeTargetRegions(compilationUnit),
      });
    }
    return _template.renderString(mustacheContext);
  }

  /// Return a list of Mustache context, based on the [unitInfo] for both
  /// unmodified and modified regions:
  ///
  /// * 'modified': Whether this region represents modified source, or
  ///   unmodified.
  /// * 'content': The textual content of this region.
  /// * 'explanation': The Mustache context for the tooltip explaining why the
  ///   content in this region was modified.
  List<Map> _computeRegions(UnitInfo unitInfo) {
    String content = unitInfo.content;
    List<Map> regions = [];
    int previousOffset = 0;
    for (var region in unitInfo.regions) {
      int offset = region.offset;
      int length = region.length;
      if (offset > previousOffset) {
        // Display a region of unmodified content.
        regions.add({
          'modified': false,
          'content': content.substring(previousOffset, offset),
        });
        previousOffset = offset + length;
      }
      List<Map> details = [];
      for (var detail in region.details) {
        details.add({
          'description': detail.description,
          'target': _uriForTarget(detail.target),
        });
      }
      regions.add({
        'modified': true,
        'content': content.substring(offset, offset + length),
        'explanation': region.explanation,
        'details': details,
      });
    }
    if (previousOffset < content.length) {
      // Last region of unmodified content.
      regions.add({
        'modified': false,
        'content': content.substring(previousOffset),
      });
    }
    return regions;
  }

  /// Return a list of Mustache context, based on the [unitInfo] for both
  /// target and non-target regions:
  ///
  /// * 'content': The content of the region.
  /// * 'isTarget': A flag indicating whether the region has a name associated
  ///   with it.
  /// * 'target': The name of the region, if the region has a name.
  List<Map> _computeTargetRegions(UnitInfo unitInfo) {
    String content = unitInfo.content;
    OffsetMapper mapper = unitInfo.offsetMapper;
    List<NavigationTarget> targets = unitInfo.targets.toList();
    targets.sort((first, second) => first.offset.compareTo(second.offset));
    List<Map> targetRegions = [];
    int previousOffset = 0;
    for (NavigationTarget target in targets) {
      int offset = mapper.map(target.offset);
      int length = target.length;
      if (offset > previousOffset) {
        // Display a non-target region.
        targetRegions.add({
          'content': content.substring(previousOffset, offset),
          'isTarget': false,
        });
        // Add a target region.
        targetRegions.add({
          'content': content.substring(offset, offset + length),
          'isTarget': true,
          'target': 'o${target.offset}',
        });
        previousOffset = offset + length;
      }
    }
    if (previousOffset < content.length) {
      // Last non-target region.
      targetRegions.add({
        'content': content.substring(previousOffset),
        'isTarget': false,
      });
    }
    return targetRegions;
  }

  /// Return the URL that will navigate to the given [target].
  String _uriForTarget(NavigationTarget target) {
    path.Context pathContext = migrationInfo.pathContext;
    String targetPath = pathContext.setExtension(target.filePath, '.html');
    String sourceDir = pathContext.dirname(libraryInfo.units.first.path);
    String relativePath = pathContext.relative(targetPath, from: sourceDir);
    return '$relativePath#o${target.offset.toString()}';
  }
}

/// A class storing rendering information for an entire migration report.
///
/// This generally provides one [InstrumentationRenderer] (for one library)
/// with information about the rest of the libraries represented in the
/// instrumentation output.
class MigrationInfo {
  /// The information about the libraries that are are migrated.
  final List<LibraryInfo> libraries;

  /// The resource provider's path context.
  final path.Context pathContext;

  /// The filesystem root used to create relative paths for each unit.
  final String includedRoot;

  MigrationInfo(this.libraries, this.pathContext, this.includedRoot);

  /// Generate mustache context for library links, for navigation in the
  /// instrumentation document for [thisLibrary].
  List<Map<String, Object>> libraryLinks(LibraryInfo thisLibrary) {
    return [
      for (var library in libraries)
        {
          'name': _computeName(library),
          'isLink': library != thisLibrary,
          if (library != thisLibrary)
            'href': _pathTo(library, source: thisLibrary)
        }
    ];
  }

  /// Return the path to [library] from [includedRoot], to be used as a display
  /// name for a library.
  String _computeName(LibraryInfo library) =>
      pathContext.relative(library.units.first.path, from: includedRoot);

  /// The path to [target], relative to [from].
  String _pathTo(LibraryInfo target, {@required LibraryInfo source}) {
    assert(target.units.isNotEmpty);
    assert(source.units.isNotEmpty);
    String targetPath =
        pathContext.setExtension(target.units.first.path, '.html');
    String sourceDir = pathContext.dirname(source.units.first.path);
    return pathContext.relative(targetPath, from: sourceDir);
  }

  /// The path to the highlight.js script, relative to [libraryInfo].
  String highlightJsPath(LibraryInfo libraryInfo) =>
      pathContext.relative(pathContext.join(includedRoot, 'highlight.pack.js'),
          from: pathContext.dirname(libraryInfo.units.first.path));

  /// The path to the highlight.js stylesheet, relative to [libraryInfo].
  String highlightStylePath(LibraryInfo libraryInfo) =>
      pathContext.relative(pathContext.join(includedRoot, 'androidstudio.css'),
          from: pathContext.dirname(libraryInfo.units.first.path));
}

/// A mustache template for one library's instrumentation output.
mustache.Template _template = mustache.Template(r'''
<html>
  <head>
    <title>Non-nullable fix instrumentation report</title>
    <script src="{{ highlightJsPath }}"></script>
    <script>
    function highlightTarget() {
      var url = document.URL;
      var index = url.lastIndexOf("#");
      if (index >= 0) {
        var name = url.substring(index + 1);
        var anchor = document.getElementById(name);
        if (anchor != null) {
          anchor.className = "target";
        }
      }
    }
    </script>
    <link rel="stylesheet" href="{{ highlightStylePath }}">
    <style>
body {
  font-family: sans-serif;
  padding: 1em;
}

h2 {
  font-size: 1em;
  font-weight: bold;
}

.content {
  font-family: monospace;
  position: relative;
  white-space: pre;
}

.regions {
  position: absolute;
  left: 0.5em;
  top: 0.5em;
  /* The content of the regions is not visible; the user instead will see the
   * highlighted copy of the content. */
  visibility: hidden;
}

.region {
  /* Green means this region was added. */
  background-color: #ccffcc;
  color: #003300;
  cursor: default;
  display: inline-block;
  position: relative;
  visibility: visible;
}

.region .tooltip {
  background-color: #EEE;
  border: solid 2px #999;
  color: #333;
  cursor: auto;
  font-family: sans-serif;
  font-size: 0.8em;
  left: 0;
  margin-left: 0;
  padding: 1px;
  position: absolute;
  top: 100%;
  visibility: hidden;
  white-space: normal;
  width: 200px;
  z-index: 1;
}

.region:hover .tooltip {
  visibility: visible;
}

.target {
  background-color: #FFFFFF;
  position: relative;
  visibility: visible;
}
    </style>
  </head>
  <body onload="highlightTarget()">
    <h1>Non-nullable fix instrumentation report</h1>
    <p><em>Well-written introduction to this report.</em></p>
    <div class="navigation">
      {{# links }}
        {{# isLink }}<a href="{{ href }}">{{ name }}</a>{{/ isLink }}
        {{^ isLink }}{{ name }}{{/ isLink }}
        <br />
      {{/ links }}
    </div>
    {{# units }}'''
    '<h2>{{{ path }}}</h2>'
    '<div class="content">'
    '<div class="highlighting">'
    '{{! These regions are written out, unmodified, as they need to be found }}'
    '{{! in one simple text string for highlight.js to hightlight them. }}'
    '{{# regions }}'
    '{{ content }}'
    '{{/ regions }}'
    '</div>'
    '<div class="regions">'
    '{{! The regions are written a second time, but hidden, to include }}'
    '{{! anchors. }}'
    '{{# targetRegions }}'
    '{{^ isTarget }}{{ content }}{{/ isTarget }}'
    '{{# isTarget }}<a id="{{ target }}">{{ content }}</a>{{/ isTarget }}'
    '{{/ targetRegions }}'
    '</div>'
    '<div class="regions">'
    '{{! The regions are then written again, overlaying the first two copies }}'
    '{{! of the content, to provide tooltips for modified regions. }}'
    '{{# regions }}'
    '{{^ modified }}{{ content }}{{/ modified }}'
    '{{# modified }}<span class="region">{{ content }}'
    '<span class="tooltip">{{ explanation }}<ul>'
    '{{# details }}'
    '<li>'
    '<a href="{{ target }}">{{ description }}</a>'
    '</li>'
    '{{/ details }}</ul></span></span>{{/ modified }}'
    '{{/ regions }}'
    '</div></div>'
    r'''
    {{/ units }}
    <script lang="javascript">
document.addEventListener("DOMContentLoaded", (event) => {
  document.querySelectorAll(".highlighting").forEach((block) => {
    hljs.highlightBlock(block);
  });
});
    </script>
  </body>
</html>''');
