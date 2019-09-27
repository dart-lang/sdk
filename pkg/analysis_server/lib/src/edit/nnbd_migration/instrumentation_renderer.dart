import 'package:analysis_server/src/edit/nnbd_migration/migration_info.dart';
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
    int previousIndex = 0;
    Map<String, dynamic> mustacheContext = {
      'units': <Map<String, dynamic>>[],
      'links': migrationInfo.libraryLinks(libraryInfo),
      'highlightJsPath': migrationInfo.highlightJsPath(libraryInfo),
      'highlightStylePath': migrationInfo.highlightStylePath(libraryInfo),
    };
    for (var compilationUnit in libraryInfo.units) {
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
  String highlightStylePath(LibraryInfo libraryInfo) => pathContext.relative(
      pathContext.join(includedRoot, 'styles', 'androidstudio.css'),
      from: pathContext.dirname(libraryInfo.units.first.path));
}

/// A mustache template for one library's instrumentation output.
mustache.Template _template = mustache.Template(r'''
<html>
  <head>
    <title>Non-nullable fix instrumentation report</title>
    <script src="{{ highlightJsPath }}"></script>
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
    <p><em>Well-written introduction to this report.</em></p>
    <div class="navigation">
      {{# links }}
        {{# isLink }}<a href="{{ href }}">{{ name }}</a>{{/ isLink }}
        {{^ isLink }}{{ name }}{{/ isLink }}
        <br />
      {{/ links }}
    </div>
    {{# units }}'''
    '  <h2>{{{ path }}}</h2>'
    '  <div class="content highlighting">'
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
