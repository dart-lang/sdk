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
<!--    <script src="{{ highlightJsPath }}"></script>-->
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
a:link {
  color: #000000;
  text-decoration-line: none;
}

a:visited {
  color: #000000;
  text-decoration-line: none;
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
//    '<div class="highlighting">'
//    '{{! These regions are written out, unmodified, as they need to be found }}'
//    '{{! in one simple text string for highlight.js to hightlight them. }}'
//    '{{# regions }}'
//    '{{ content }}'
//    '{{/ regions }}'
//    '</div>'
    '<div class ="code">'
    '{{! Write the file content, modified to include navigation information, }}'
    '{{! both anchors and links. }}'
    '{{{ navContent }}}'
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
      'regions': _computeRegions(unitInfo),
    });
    return _template.renderString(mustacheContext);
  }

  /// Return the content of the file with navigation links and anchors added.
  String _computeNavigationContent(UnitInfo unitInfo) {
    String content = unitInfo.content;
    OffsetMapper mapper = unitInfo.offsetMapper;
    List<NavigationRegion> regions = []
      ..addAll(unitInfo.sources ?? <NavigationSource>[])
      ..addAll(unitInfo.targets);
    regions.sort((first, second) {
      int offsetComparison = first.offset.compareTo(second.offset);
      if (offsetComparison == 0) {
        return first is NavigationSource ? -1 : 1;
      }
      return offsetComparison;
    });

    StringBuffer navContent = StringBuffer();
    int previousOffset = 0;
    for (int i = 0; i < regions.length; i++) {
      NavigationRegion region = regions[i];
      int offset = mapper.map(region.offset);
      int length = region.length;
      if (offset > previousOffset) {
        // Write a non-target region.
        navContent.write(content.substring(previousOffset, offset));
        if (region is NavigationSource) {
          if (i + 1 < regions.length &&
              regions[i + 1].offset == region.offset) {
            NavigationTarget target = region.target;
            if (target == regions[i + 1]) {
              // Add a target region. We skip the source because it links to
              // itself, which is pointless.
              navContent.write('<a id="o${region.offset}">');
              navContent.write(content.substring(offset, offset + length));
              navContent.write('</a>');
            } else {
              // Add a source and target region.
              // TODO(brianwilkerson) Map the target's file path to the path of
              //  the corresponding html file. I'd like to do this by adding a
              //  `FilePathMapper` object so that it can't become inconsistent
              //  with the code used to decide where to write the html.
              String htmlPath = pathMapper.map(target.filePath);
              navContent.write('<a id="o${region.offset}" ');
              navContent.write('href="$htmlPath#o${target.offset}">');
              navContent.write(content.substring(offset, offset + length));
              navContent.write('</a>');
            }
            i++;
          } else {
            // Add a source region.
            NavigationTarget target = region.target;
            String htmlPath = pathMapper.map(target.filePath);
            navContent.write('<a href="$htmlPath#o${target.offset}">');
            navContent.write(content.substring(offset, offset + length));
            navContent.write('</a>');
          }
        } else {
          // Add a target region.
          navContent.write('<a id="o${region.offset}">');
          navContent.write(content.substring(offset, offset + length));
          navContent.write('</a>');
        }
        previousOffset = offset + length;
      }
    }
    if (previousOffset < content.length) {
      // Last non-target region.
      navContent.write(content.substring(previousOffset));
    }
    return navContent.toString();
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

  /// Return the URL that will navigate to the given [target].
  String _uriForTarget(NavigationTarget target) {
    path.Context pathContext = migrationInfo.pathContext;
    String targetPath = pathContext.setExtension(target.filePath, '.html');
    String sourceDir = pathContext.dirname(unitInfo.path);
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
  /// The information about the compilation units that are are migrated.
  final List<UnitInfo> units;

  /// The resource provider's path context.
  final path.Context pathContext;

  /// The filesystem root used to create relative paths for each unit.
  final String includedRoot;

  MigrationInfo(this.units, this.pathContext, this.includedRoot);

  /// The path to the highlight.js script, relative to [unitInfo].
  String highlightJsPath(UnitInfo unitInfo) =>
      pathContext.relative(pathContext.join(includedRoot, 'highlight.pack.js'),
          from: pathContext.dirname(unitInfo.path));

  /// The path to the highlight.js stylesheet, relative to [unitInfo].
  String highlightStylePath(UnitInfo unitInfo) =>
      pathContext.relative(pathContext.join(includedRoot, 'androidstudio.css'),
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
