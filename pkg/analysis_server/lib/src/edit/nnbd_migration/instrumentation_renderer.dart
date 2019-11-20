// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show htmlEscape, LineSplitter;

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
  left: 0.5em;
  /* Increase line height to make room for borders in non-nullable type
   * regions.
   */
  line-height: 1.3;
  padding-left: 60px;
  position: absolute;
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

.regions table {
  border-spacing: 0;
}

.regions td {
  border: none;
  line-height: 1.3;
  padding: 0;
  white-space: pre;
}

.regions td:empty:after {
  content: "\00a0";
}

.regions td.line-no {
  color: #999999;
  display: inline-block;
  padding-right: 4px;
  text-align: right;
  visibility: visible;
  width: 50px;
}

.region {
  cursor: default;
  display: inline-block;
  position: relative;
  visibility: visible;
}

.region.fix-region {
  /* Green means this region was added. */
  background-color: #ccffcc;
  color: #003300;
}

.region.non-nullable-type-region {
  background-color: rgba(0, 0, 0, 0.3);
  border-bottom: solid 2px #cccccc;
  /* Invisible text; use underlying highlighting. */
  color: rgba(0, 0, 0, 0);
  /* Reduce line height to make room for border. */
  line-height: 1;
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
    <p>Migrated files:</p>
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
    '{{! The regions are then written again, overlaying the first copy of }}'
    '{{! the content, to provide tooltips for modified regions. }}'
    '{{{ regionContent }}}'
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
    Map<String, dynamic> mustacheContext = {
      'units': <Map<String, dynamic>>[],
      'links': migrationInfo.unitLinks(unitInfo),
      'highlightJsPath': migrationInfo.highlightJsPath(unitInfo),
      'highlightStylePath': migrationInfo.highlightStylePath(unitInfo),
      'navContent': _computeNavigationContent(unitInfo),
    };
    mustacheContext['units'].add({
      'path': unitInfo.path,
      'regionContent': _computeRegionContent(unitInfo),
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
      int regionLength = region.length;
      if (regionLength > 0) {
        int openOffset = mapper.map(region.offset);
        String openInsertion = openInsertions[openOffset] ?? '';
        openInsertion = '<a id="o${region.offset}">$openInsertion';
        openInsertions[openOffset] = openInsertion;

        int closeOffset = openOffset + regionLength;
        String closeInsertion = closeInsertions[closeOffset] ?? '';
        closeInsertion = '$closeInsertion</a>';
        closeInsertions[closeOffset] = closeInsertion;
      }
    }
    //
    // Compute insertions for navigation sources, but skip the sources that
    // point at themselves.
    //
    for (NavigationSource region in unitInfo.sources ?? <NavigationSource>[]) {
      int regionLength = region.length;
      if (regionLength > 0) {
        int openOffset = mapper.map(region.offset);
        NavigationTarget target = region.target;
        if (target.filePath != unitInfo.path ||
            region.offset != target.offset) {
          String openInsertion = openInsertions[openOffset] ?? '';
          String htmlPath = pathContext
              .relative(pathMapper.map(target.filePath), from: unitDir);
          openInsertion =
              '<a href="$htmlPath#o${target.offset}">$openInsertion';
          openInsertions[openOffset] = openInsertion;

          int closeOffset = openOffset + regionLength;
          String closeInsertion = closeInsertions[closeOffset] ?? '';
          closeInsertion = '$closeInsertion</a>';
          closeInsertions[closeOffset] = closeInsertion;
        }
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

  /// Return the content of regions, based on the [unitInfo] for both
  /// unmodified and modified regions.
  String _computeRegionContent(UnitInfo unitInfo) {
    String unitDir = _directoryContaining(unitInfo);
    String content = unitInfo.content;
    StringBuffer regions = StringBuffer();
    int lineNumber = 1;

    void writeSplitLines(String lines) {
      Iterator<String> lineIterator = LineSplitter.split(lines).iterator;
      lineIterator.moveNext();

      while (true) {
        regions.write(htmlEscape.convert(lineIterator.current));
        if (lineIterator.moveNext()) {
          // If we're not on the last element, end this table row, and start a
          // new table row.
          lineNumber++;
          regions.write(
              '</td></tr>' '<tr><td class="line-no">$lineNumber</td><td>');
        } else {
          break;
        }
      }
    }

    int previousOffset = 0;
    regions.write('<table><tbody><tr><td class="line-no">$lineNumber</td><td>');
    for (var region in unitInfo.regions) {
      int offset = region.offset;
      int length = region.length;
      if (offset > previousOffset) {
        // Display a region of unmodified content.
        writeSplitLines(content.substring(previousOffset, offset));
        previousOffset = offset + length;
      }
      String regionClass = region.regionType == RegionType.fix
          ? 'fix-region'
          : 'non-nullable-type-region';
      regions.write('<span class="region $regionClass">'
          '${content.substring(offset, offset + length)}'
          '<span class="tooltip">'
          '<p>${region.explanation}</p>');
      if (region.details.isNotEmpty) {
        regions.write('<ul>');
      }
      for (var detail in region.details) {
        regions.write('<li>');

        if (detail.target != null) {
          regions.write('<a href="${_uriForTarget(detail.target, unitDir)}">');
        }
        writeSplitLines(detail.description);
        if (detail.target != null) {
          regions.write('</a>');
        }
        regions.write('</li>');
      }
      if (region.details.isNotEmpty) {
        regions.write('</ul>');
      }
      regions.write('</span></span>');
    }
    if (previousOffset < content.length) {
      // Last region of unmodified content.
      writeSplitLines(content.substring(previousOffset));
    }
    regions.write('</td></tr></tbody></table>');
    return regions.toString();
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

  /// A map from file paths to the unit infos created for those files. The units
  /// in this map is a strict superset of the [units] that were migrated.
  final Map<String, UnitInfo> unitMap;

  /// The resource provider's path context.
  final path.Context pathContext;

  /// The filesystem root used to create relative paths for each unit.
  final String includedRoot;

  MigrationInfo(this.units, this.unitMap, this.pathContext, this.includedRoot);

  /// The path to the highlight.js script, relative to [unitInfo].
  String highlightJsPath(UnitInfo unitInfo) {
    if (pathContext.isWithin(includedRoot, unitInfo.path)) {
      return pathContext.relative(
          pathContext.join(includedRoot, '..', 'highlight.pack.js'),
          from: pathContext.dirname(unitInfo.path));
    }
    // Files that aren't within the [includedRoot] are written to the top-level
    // of the output directory, next to the Javascript file.
    return 'highlight.pack.js';
  }

  /// The path to the highlight.js stylesheet, relative to [unitInfo].
  String highlightStylePath(UnitInfo unitInfo) {
    if (pathContext.isWithin(includedRoot, unitInfo.path)) {
      return pathContext.relative(
          pathContext.join(includedRoot, '..', 'androidstudio.css'),
          from: pathContext.dirname(unitInfo.path));
    }
    // Files that aren't within the [includedRoot] are written to the top-level
    // of the output directory, next to the CSS file.
    return 'androidstudio.css';
  }

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
