// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/edit/nnbd_migration/migration_info.dart';
import 'package:analysis_server/src/edit/nnbd_migration/offset_mapper.dart';
import 'package:analysis_server/src/edit/nnbd_migration/path_mapper.dart';
import 'package:meta/meta.dart';
import 'package:mustache/mustache.dart' as mustache;
import 'package:path/path.dart' as path;

/// A mustache template for one library's instrumentation output.
mustache.Template _template = mustache.Template(r'''
<html>
  <head>
    <title>Non-nullable fix instrumentation report</title>
    <script src="{{ highlightJsPath }}"></script>
    <script>
    function getHash(location) {
      var index = location.lastIndexOf("#");
      if (index >= 0) {
        return location.substring(index + 1);
      } else {
        return null;
      }
    }

    function highlightTarget(event) {
      if (event !== undefined && event.oldURL !== undefined) {
        // Remove the "target" CSS class from the previous anchor.
        var oldHash = getHash(event.oldURL);
        if (oldHash != null) {
          var anchor = document.getElementById(oldHash);
          if (anchor != null) {
            anchor.classList.remove("target");
          }
        }
      }
      var url = document.URL;
      var hash = getHash(url);
      if (hash != null) {
        var anchor = document.getElementById(hash);
        if (anchor != null) {
          anchor.classList.add("target");
        }
      }
    }

    document.addEventListener("DOMContentLoaded", highlightTarget);
    window.addEventListener("hashchange", highlightTarget);
    </script>
    <link rel="stylesheet" href="{{ highlightStylePath }}">
    <style>
a:link {
  color: inherit;
  text-decoration-line: none;
}

a:visited {
  color: inherit;
  text-decoration-line: none;
}

a:hover {
  text-decoration-line: underline;
}

body {
  font-family: sans-serif;
  padding: 1em;
}

h2 {
  font-size: 1em;
  font-weight: bold;
}

.code {
  position: absolute;
  left: 0.5em;
  top: 0.5em;
}

.content {
  font-family: monospace;
  position: relative;
  white-space: pre;
}

.regions {
  padding: 0.5em;
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
  width: 400px;
  z-index: 1;
}

.region .tooltip > * {
  margin: 1em;
}

.region:hover .tooltip {
  visibility: visible;
}

.target {
  background-color: #FFFF99;
  position: relative;
  visibility: visible;
}
    </style>
  </head>
  <body>
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
    '<div class="code">'
    '{{! Write the file content, modified to include navigation information, }}'
    '{{! both anchors and links. }}'
    '{{{ navContent }}}'
    '</div>'
    '<div class="regions">'
    '{{! The regions are then written again, overlaying the first two copies }}'
    '{{! of the content, to provide tooltips for modified regions. }}'
    '{{# regions }}'
    '{{^ modified }}{{ content }}{{/ modified }}'
    '{{# modified }}'
    '<span class="region">{{ content }}'
    '<span class="tooltip"><p>{{ explanation }}</p>'
    '  <ul>'
    '    {{# details }}'
    '    <li>'
    '      {{# isLink }}<a href="{{ target }}">{{ description }}</a>{{/ isLink }}'
    '      {{^ isLink }}{{ description }}{{/ isLink }}'
    '    </li>'
    '    {{/ details }}'
    '  </ul>'
    '</span>'
    '</span>'
    '{{/ modified }}'
    '{{/ regions }}'
    '</div></div>'
    r'''
    {{/ units }}
    <script lang="javascript">
document.addEventListener("DOMContentLoaded", (event) => {
  document.querySelectorAll(".code").forEach((block) => {
    hljs.highlightBlock(block);
  });
});
    </script>
  </body>
</html>''');

/// Instrumentation display output for a library that was migrated to use
/// non-nullable types.
class InstrumentationRenderer {
  /// Display information for a compilation unit.
  final UnitInfo unitInfo;

  /// Information for a whole migration, so that libraries can reference each
  /// other.
  final MigrationInfo migrationInfo;

  /// An object used to map the file paths of analyzed files to the file paths
  /// of the HTML files used to view the content of those files.
  final PathMapper pathMapper;

  /// Creates an output object for the given library info.
  InstrumentationRenderer(this.unitInfo, this.migrationInfo, this.pathMapper);

  /// Return the path context used to manipulate paths.
  path.Context get pathContext => migrationInfo.pathContext;

  /// Builds an HTML view of the instrumentation information in [unitInfo].
  String render() {
    // TODO(brianwilkerson) Restore syntactic highlighting.
    // TODO(brianwilkerson) Add line numbers beside the content.
    Map<String, dynamic> mustacheContext = {
      'units': <Map<String, dynamic>>[],
      'links': migrationInfo.unitLinks(unitInfo),
      'highlightJsPath': migrationInfo.highlightJsPath(unitInfo),
      'highlightStylePath': migrationInfo.highlightStylePath(unitInfo),
      'navContent': _computeNavigationContent(unitInfo),
    };
    mustacheContext['units'].add({
      'path': unitInfo.path,
      'regions': _computeRegions(unitInfo),
    });
    return _template.renderString(mustacheContext);
  }

  /// Return the content of the file with navigation links and anchors added.
  String _computeNavigationContent(UnitInfo unitInfo) {
    String unitDir = _directoryContaining(unitInfo);
    String content = unitInfo.content;
    OffsetMapper mapper = unitInfo.offsetMapper;
    Map<int, String> openInsertions = {};
    Map<int, String> closeInsertions = {};
    //
    // Compute insertions for navigation targets.
    //
    for (NavigationTarget region in unitInfo.targets) {
      int openOffset = mapper.map(region.offset);
      String openInsertion = openInsertions[openOffset] ?? '';
      openInsertion = '<a id="o${region.offset}">$openInsertion';
      openInsertions[openOffset] = openInsertion;

      int closeOffset = openOffset + region.length;
      String closeInsertion = closeInsertions[closeOffset] ?? '';
      closeInsertion = '$closeInsertion</a>';
      closeInsertions[closeOffset] = closeInsertion;
    }
    //
    // Compute insertions for navigation sources, but skip the sources that
    // point at themselves.
    //
    for (NavigationSource region in unitInfo.sources ?? <NavigationSource>[]) {
      int openOffset = mapper.map(region.offset);
      NavigationTarget target = region.target;
      if (target.filePath != unitInfo.path || region.offset != target.offset) {
        String openInsertion = openInsertions[openOffset] ?? '';
        String htmlPath = pathContext.relative(pathMapper.map(target.filePath),
            from: unitDir);
        openInsertion = '<a href="$htmlPath#o${target.offset}">$openInsertion';
        openInsertions[openOffset] = openInsertion;

        int closeOffset = openOffset + region.length;
        String closeInsertion = closeInsertions[closeOffset] ?? '';
        closeInsertion = '$closeInsertion</a>';
        closeInsertions[closeOffset] = closeInsertion;
      }
    }
    //
    // Apply the insertions that have been computed.
    //
    List<int> offsets = []
      ..addAll(openInsertions.keys)
      ..addAll(closeInsertions.keys);
    offsets.sort();
    StringBuffer navContent2 = StringBuffer();
    int previousOffset2 = 0;
    for (int offset in offsets) {
      navContent2.write(content.substring(previousOffset2, offset));
      navContent2.write(closeInsertions[offset] ?? '');
      navContent2.write(openInsertions[offset] ?? '');
      previousOffset2 = offset;
    }
    if (previousOffset2 < content.length) {
      navContent2.write(content.substring(previousOffset2));
    }
    return navContent2.toString();
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
    String unitDir = _directoryContaining(unitInfo);
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
          'target': _uriForTarget(detail.target, unitDir),
          'isLink': detail.target != null,
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

  /// Return the path to the directory containing the output generated from the
  /// [unitInfo].
  String _directoryContaining(UnitInfo unitInfo) {
    return pathContext.dirname(pathMapper.map(unitInfo.path));
  }

  /// Return the URL that will navigate to the given [target].
  String _uriForTarget(NavigationTarget target, String unitDir) {
    if (target == null) {
      // TODO(brianwilkerson) This is temporary support until we can get targets
      //  for all nodes.
      return '';
    }
    String relativePath =
        pathContext.relative(pathMapper.map(target.filePath), from: unitDir);
    return '$relativePath#o${target.offset.toString()}';
  }
}

/// A class storing rendering information for an entire migration report.
///
/// This generally provides one [InstrumentationRenderer] (for one library)
/// with information about the rest of the libraries represented in the
/// instrumentation output.
class MigrationInfo {
  /// The information about the compilation units that are are migrated.
  final Set<UnitInfo> units;

  /// The resource provider's path context.
  final path.Context pathContext;

  /// The filesystem root used to create relative paths for each unit.
  final String includedRoot;

  MigrationInfo(this.units, this.pathContext, this.includedRoot);

  /// The path to the highlight.js script, relative to [unitInfo].
  String highlightJsPath(UnitInfo unitInfo) => pathContext.relative(
      pathContext.join(includedRoot, '..', 'highlight.pack.js'),
      from: pathContext.dirname(unitInfo.path));

  /// The path to the highlight.js stylesheet, relative to [unitInfo].
  String highlightStylePath(UnitInfo unitInfo) => pathContext.relative(
      pathContext.join(includedRoot, '..', 'androidstudio.css'),
      from: pathContext.dirname(unitInfo.path));

  /// Generate mustache context for unit links, for navigation in the
  /// instrumentation document for [thisUnit].
  List<Map<String, Object>> unitLinks(UnitInfo thisUnit) {
    return [
      for (var unit in units)
        {
          'name': _computeName(unit),
          'isLink': unit != thisUnit,
          if (unit != thisUnit) 'href': _pathTo(target: unit, source: thisUnit)
        }
    ];
  }

  /// Return the path to [unit] from [includedRoot], to be used as a display
  /// name for a library.
  String _computeName(UnitInfo unit) =>
      pathContext.relative(unit.path, from: includedRoot);

  /// The path to [target], relative to [from].
  String _pathTo({@required UnitInfo target, @required UnitInfo source}) {
    String targetPath = pathContext.setExtension(target.path, '.html');
    String sourceDir = pathContext.dirname(source.path);
    return pathContext.relative(targetPath, from: sourceDir);
  }
}
