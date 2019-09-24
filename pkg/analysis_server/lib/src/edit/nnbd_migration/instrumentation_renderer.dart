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
      StringBuffer buffer = StringBuffer();
      for (var region in compilationUnit.regions) {
        if (region.offset > previousIndex) {
          // Display a region of unmodified content.
          buffer.write(
              compilationUnit.content.substring(previousIndex, region.offset));
          previousIndex = region.offset + region.length;
        }
        buffer.write(_regionWithTooltip(region, compilationUnit.content));
      }
      if (previousIndex < compilationUnit.content.length) {
        // Last region of unmodified content.
        buffer.write(compilationUnit.content.substring(previousIndex));
      }
      mustacheContext['units']
          .add({'path': compilationUnit.path, 'content': buffer.toString()});
    }
    return _template.renderString(mustacheContext);
  }

  String _regionWithTooltip(RegionInfo region, String content) {
    String regionContent =
        content.substring(region.offset, region.offset + region.length);
    return '<span class="region">$regionContent'
        '<span class="tooltip">${region.explanation}</span></span>';
  }
}

/// A mustache template for one library's instrumentation output.
mustache.Template _template = mustache.Template(r'''
<html>
  <head>
    <title>Non-nullable fix instrumentation report</title>
    <style>
h2 {
  font-size: 1em;
  font-weight: bold;
}

div.content {
  font-family: monospace;
  whitespace: pre;
}

.region {
  /* Green means this region was added. */
  color: green;
  display: inline-block;
  position: relative;
}

.region .tooltip {
  background-color: #EEE;
  border: solid 2px #999;
  color: #333;
  left: 50%;
  margin-left: -50px;
  padding: 1px;
  position: absolute;
  top: 120%;
  visibility: hidden;
  width: 100px;
  z-index: 1;
}

.region:hover .tooltip {
  visibility: visible;
}
    </style>
  </head>
  <body>
    <h1>Non-nullable fix instrumentation report</h1>
    <p><em>Well-written introduction to this report.</em></p>
    {{# units }}
      <h2>{{ path }}</h2>
      <div class="content">
        {{{ content }}}
      </div> {{! content }}
    {{/ units }}
  </body>
</html>
''');
