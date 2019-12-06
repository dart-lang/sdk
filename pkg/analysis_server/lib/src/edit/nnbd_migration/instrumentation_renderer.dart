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
    <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Open+Sans:400,600&display=swap">
    <link rel="stylesheet" href="{{ highlightStylePath }}">
    <style>
body {
  background-color: black;
  color: white;
  font-family: 'Open Sans', sans-serif;
  /* This allows very small files to be displayed lower than the very top of the
   * screen.
   */
  margin-bottom; 100px;
  padding: 0.5em;
}

h1 {
  font-size: 2.4em;
  font-weight: 600;
  margin: 0;
}

h2 {
  font-size: 1.2em;
  font-weight: 600;
  margin: 0;
}

.horizontal {
  display: flex;
  flex-wrap: wrap-reverse;
}

.content {
  flex: 1;
  font-family: monospace;
  /* Vertical margin around content. */
  margin: 10px 0;
  /* Offset the margin introduced by the absolutely positioned child div. */
  margin-left: -0.5em;
  min-width: 900px;
  position: relative;
  white-space: pre;
}

.code {
  left: 0.5em;
  /* Increase line height to make room for borders in non-nullable type
   * regions.
   */
  line-height: 1.3;
  padding-left: 60px;
  position: inherit;
}

.code a:link {
  color: inherit;
  text-decoration-line: none;
}

.code a:visited {
  color: inherit;
  text-decoration-line: none;
}

.code a:hover {
  text-decoration-line: underline;
  font-weight: 600;
}

.regions {
  padding: 0.5em;
  position: absolute;
  left: 0.5em;
  top: 0;
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

.region .tooltip::after {
  /* Make a larger hover target once the tooltip appears. */
  content: '';
  position: absolute;
  top: -1em;
  height: 2em;
  left: -1ch;
  width: 3ch;
}

.nav {
  background-color: #282b2e;
  flex-basis: 0;
  flex-grow: 1;
  font-size: 14px;
  /* 10px to match exact top margin of .content.
   * 0.8em to pair with the -0.5em margin of .content, producing a net margin
   * between the two of 0.3em.
   */
  margin: 10px 0.8em;
  padding: 0.5em;
}

.nav :first-child {
  margin-top: 0;
}

.nav .root {
  margin: 0;
}

.nav .file-name {
  margin-left: 1em;
}

.nav a:link {
  color: #33ccff;
}

.nav a:visited {
  color: #33ccff;
}

.nav .selected-file {
  font-weight: 600;
}

.target {
  background-color: #FFFF99;
  position: relative;
  visibility: visible;
}
    </style>
  </head>
  <body>
    <h1>Preview of NNBD migration</h1>
    {{# units }}
    <p><b>
    Hover over modified regions to see why the migration tool chose to make the
    modification.
    </b></p>
    <h2>{{ thisUnit }}</h2>
    <div class="panels">
    <div class="horizontal">'''
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
    '''
    <div class="nav" style="">
      <p>Select a source file below to preview the modifications.</p>
      <p class="root">{{ root }}</p>
      {{# links }}
        {{# isLink }}<a class="file-name" href="{{ href }}">{{ name }}</a>{{/ isLink }}
        {{^ isLink }}<span class="file-name selected-file">{{ name }}</span>{{/ isLink }}
        {{ modificationCount }}
        <br/>
      {{/ links }}
    </div><!-- /nav -->
    </div><!-- /horizontal -->
    <div><em>Generated on {{ generationDate }}</em></div>
    </div><!-- /panels -->
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
  /// A flag indicating whether the incremental workflow is currently supported.
  static const bool supportsIncrementalWorkflow = false;

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
      'root': migrationInfo.includedRoot,
      'units': <Map<String, dynamic>>[],
      'thisUnit': migrationInfo._computeName(unitInfo),
      'links': migrationInfo.unitLinks(unitInfo),
      'highlightJsPath': migrationInfo.highlightJsPath(unitInfo),
      'highlightStylePath': migrationInfo.highlightStylePath(unitInfo),
      'navContent': _computeNavigationContent(unitInfo),
      'generationDate': migrationInfo.migrationDate,
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
        openInsertion = '<span id="o${region.offset}">$openInsertion';
        openInsertions[openOffset] = openInsertion;

        int closeOffset = openOffset + regionLength;
        String closeInsertion = closeInsertions[closeOffset] ?? '';
        closeInsertion = '$closeInsertion</span>';
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
      //
      // Write out any details.
      //
      if (region.details.isNotEmpty) {
        regions.write('<ul>');
        for (var detail in region.details) {
          regions.write('<li>');
          if (detail.target != null) {
            String targetUri = _uriForTarget(detail.target, unitDir);
            regions.write('<a href="$targetUri">');
          }
          writeSplitLines(detail.description);
          if (detail.target != null) {
            regions.write('</a>');
          }
          regions.write('</li>');
        }
        regions.write('</ul>');
      }
      //
      // Write out any edits.
      //
      if (supportsIncrementalWorkflow && region.edits.isNotEmpty) {
        for (EditDetail edit in region.edits) {
          int offset = edit.offset;
          String targetUri = Uri(
              scheme: 'http',
              path: pathContext.basename(unitInfo.path),
              queryParameters: {
                'offset': offset.toString(),
                'end': (offset + edit.length).toString(),
                'replacement': edit.replacement
              }).toString();
          regions.write('<p>');
          regions.write('<a href="$targetUri">');
          regions.write(edit.description);
          regions.write('</a>');
          regions.write('</p>');
        }
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

  final String migrationDate;

  MigrationInfo(this.units, this.unitMap, this.pathContext, this.includedRoot)
      : migrationDate = DateTime.now().toString();

  /// The path to the highlight.js script, relative to [unitInfo].
  String highlightJsPath(UnitInfo unitInfo) {
    if (pathContext.isWithin(includedRoot, unitInfo.path)) {
      return pathContext.relative(
          pathContext.join(includedRoot, '..', 'highlight.pack.js'),
          from: pathContext.dirname(unitInfo.path));
    }
    // Files that aren't within the [includedRoot] are written to the top-level
    // of the output directory, next to the Javascript file.
    return pathContext.join('..', 'highlight.pack.js');
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
    return pathContext.join('..', 'androidstudio.css');
  }

  /// Generate mustache context for unit links, for navigation in the
  /// instrumentation document for [currentUnit].
  List<Map<String, Object>> unitLinks(UnitInfo currentUnit) {
    List<Map<String, Object>> links = [];
    for (UnitInfo unit in units) {
      int count = unit.fixRegions.length;
      String modificationCount =
          count == 1 ? '(1 modification)' : '($count modifications)';
      bool isNotCurrent = unit != currentUnit;
      links.add({
        'name': _computeName(unit),
        'modificationCount': modificationCount,
        'isLink': isNotCurrent,
        if (isNotCurrent) 'href': _pathTo(target: unit, source: currentUnit)
      });
    }
    return links;
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
