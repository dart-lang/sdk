import 'package:analysis_server/src/edit/nnbd_migration/migration_info.dart';
import 'package:mustache/mustache.dart' as mustache;

/// Instrumentation display output for a library that was migrated to use non-nullable types.
class InstrumentationRenderer {
  /// Display information for a library.
  final LibraryInfo info;

  /// Creates an output object for the given library info.
  InstrumentationRenderer(this.info);

  /// Builds an HTML view of the instrumentation information in [info].
  String render() {
    int previousIndex = 0;
    Map<String, dynamic> mustacheContext = {'units': <Map<String, dynamic>>[]};
    for (var compilationUnit in info.units) {
      // List of Mustache context for both unmodified and modified regions:
      //
      // * 'modified': Whether this region represents modified source, or
      //   unmodified.
      // * 'content': The textual content of this region.
      // * 'explanation': The textual explanation of why the content in this
      //   region was modified. It will appear in a "tooltip" on hover.
      //   TODO(srawlins): Support some sort of HTML explanation, with
      //   hyperlinks to anchors in other source code.
      List<Map> regions = [];
      for (var region in compilationUnit.regions) {
        if (region.offset > previousIndex) {
          // Display a region of unmodified content.
          regions.add({
            'modified': false,
            'content':
                compilationUnit.content.substring(previousIndex, region.offset)
          });
          previousIndex = region.offset + region.length;
        }
        regions.add({
          'modified': true,
          'content': compilationUnit.content
              .substring(region.offset, region.offset + region.length),
          'explanation': region.explanation,
        });
      }
      if (previousIndex < compilationUnit.content.length) {
        // Last region of unmodified content.
        regions.add({
          'modified': false,
          'content': compilationUnit.content.substring(previousIndex)
        });
      }
      mustacheContext['units']
          .add({'path': compilationUnit.path, 'regions': regions});
    }
    return _template.renderString(mustacheContext);
  }
}

/// A mustache template for one library's instrumentation output.
mustache.Template _template = mustache.Template(r'''
<html>
  <head>
    <title>Non-nullable fix instrumentation report</title>
    <script src="highlight.pack.js"></script>
    <link rel="stylesheet" href="styles/androidstudio.css">
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
  white-space: pre;
}

.content.highlighting {
  position: relative;
}

.regions {
  position: absolute;
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
  left: 50%;
  margin-left: -100px;
  padding: 1px;
  position: absolute;
  top: 100%;
  visibility: hidden;
  width: 200px;
  z-index: 1;
}

.region:hover .tooltip {
  visibility: visible;
}
    </style>
  </head>
  <body>
    <h1>Non-nullable fix instrumentation report</h1>
    <p><em>Well-written introduction to this report.</em></p>'''
    '    {{# units }}'
    '      <h2>{{{ path }}}</h2>'
    '      <div class="content highlighting">'
    '{{! These regions are written out, unmodified, as they need to be found }}'
    '{{! in one simple text string for highlight.js to hightlight them. }}'
    '{{# regions }}'
    '{{ content }}'
    '{{/ regions }}'
    '      <div class="regions">'
    '{{! The regions are then printed again, overlaying the first copy of the }}'
    '{{! content, to provide tooltips for modified regions. }}'
    '{{# regions }}'
    '{{^ modified }}{{ content }}{{/ modified }}'
    '{{# modified }}<span class="region">{{ content }}'
    '<span class="tooltip">{{explanation}}</span></span>{{/ modified }}'
    '{{/ regions }}'
    '</div></div>'
    '    {{/ units }}'
    '    <script lang="javascript">'
    'document.addEventListener("DOMContentLoaded", (event) => {'
    '  document.querySelectorAll(".highlighting").forEach((block) => {'
    '    hljs.highlightBlock(block);'
    '  });'
    '});'
    '    </script>'
    '  </body>'
    '</html>');
