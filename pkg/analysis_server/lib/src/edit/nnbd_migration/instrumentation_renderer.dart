// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/edit/nnbd_migration/dart_page_script.dart';
import 'package:analysis_server/src/edit/nnbd_migration/dart_page_style.dart';
import 'package:analysis_server/src/edit/nnbd_migration/migration_info.dart';
import 'package:analysis_server/src/edit/nnbd_migration/path_mapper.dart';
import 'package:analysis_server/src/edit/nnbd_migration/unit_link.dart';
import 'package:mustache/mustache.dart' as mustache;
import 'package:path/path.dart' as path;

/// A mustache template for one library's instrumentation output.
mustache.Template _template = mustache.Template(r'''
<html>
  <head>
    <title>Non-nullable fix instrumentation report</title>
    <script src="{{ highlightJsPath }}"></script>
    <script>{{{ dartPageScript }}}</script>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Open+Sans:400,600&display=swap">
    <link rel="stylesheet" href="{{ highlightStylePath }}">
    <style>{{{ dartPageStyle }}}</style>
  </head>
  <body>
    <h1>Preview of NNBD migration</h1>
    <h2 id="unit-name">&nbsp;</h2>
    <div class="panels">
    <div class="horizontal">
    <div class="nav-panel">
      <div class="nav-inner">
        <p class="panel-heading">Navigation</p>
        <p class="root">{{{ root }}}</p>
{{{ links }}}
      </div><!-- /nav-inner -->
    </div><!-- /nav -->
    '''
    '<div class="content">'
    '<div class="code">'
    '{{! Compilation unit content is written here. }}'
    '<p class="welcome">'
    '{{! TODO(srawlins): More welcome text! }}'
    'Select a source file on the left to preview the edits.'
    '</p>'
    '</div>'
    '<div class="regions">'
    '{{! The regions are then written again, overlaying the first copy of }}'
    '{{! the content, to provide tooltips for modified regions. }}'
    '</div><!-- /regions -->'
    '<div class="footer"><em>Generated on {{ generationDate }}</em></div>'
    '</div><!-- /content -->'
    '''
    <div class="info-panel">
      <div class="panel-container">
        <div class="edit-panel">
          <p class="panel-heading">Edit info</p>
          <div class="panel-content">
            <p>
            Click a modified region of code to see why the migration tool chose
            to make the edit.
            </p>
          </div><!-- /panel-content -->
        </div><!-- /edit-panel -->
        <div class="edit-list">
          <p class="panel-heading">Edits</p>
          <div class="panel-content"></div>
        </div><!-- /edit-list -->
      </div><!-- /panel-container -->
    </div><!-- /info-panel -->
    </div><!-- /horizontal -->
    </div><!-- /panels -->
  </body>
</html>''');

/// Instrumentation display output for a library that was migrated to use
/// non-nullable types.
class InstrumentationRenderer {
  /// Information for a whole migration, so that libraries can reference each
  /// other.
  final MigrationInfo migrationInfo;

  /// An object used to map the file paths of analyzed files to the file paths
  /// of the HTML files used to view the content of those files.
  final PathMapper pathMapper;

  /// Creates an output object for the given library info.
  InstrumentationRenderer(this.migrationInfo, this.pathMapper);

  /// Returns the path context used to manipulate paths.
  path.Context get pathContext => migrationInfo.pathContext;

  /// Builds an HTML view of the instrumentation information.
  String render() {
    Map<String, dynamic> mustacheContext = {
      'root': migrationInfo.includedRoot,
      'dartPageScript': dartPageScript,
      'dartPageStyle': dartPageStyle,
      'links': _renderNavigation(),
      'highlightJsPath': migrationInfo.highlightJsPath,
      'highlightStylePath': migrationInfo.highlightStylePath,
      'generationDate': migrationInfo.migrationDate,
    };
    return _template.renderString(mustacheContext);
  }

  /// Renders the navigation link tree.
  String _renderNavigation() {
    var linkData = migrationInfo.unitLinks();
    var buffer = StringBuffer();
    _renderNavigationSubtree(linkData, 0, buffer);
    return buffer.toString();
  }

  /// Renders the navigation link subtree at [depth].
  void _renderNavigationSubtree(
      List<UnitLink> links, int depth, StringBuffer buffer) {
    var linksGroupedByDirectory = _groupBy(
        links.where((link) => link.depth > depth),
        (UnitLink link) => link.pathParts[depth]);
    // Each subtree is indented four spaces more than its parent: two for the
    // parent <ul> and two for the parent <li>.
    var indent = '    ' * depth;
    buffer.writeln('$indent<ul>');
    linksGroupedByDirectory
        .forEach((String directoryName, Iterable<UnitLink> groupedLinks) {
      buffer.write('$indent  <li class="dir">');
      buffer.writeln(
          '<span class="arrow">&#x25BC;</span>&#x1F4C1;$directoryName');
      _renderNavigationSubtree(groupedLinks, depth + 1, buffer);
      buffer.writeln('$indent  </li>');
    });
    for (var link in links.where((link) => link.depth == depth)) {
      var modifications =
          link.modificationCount == 1 ? 'modification' : 'modifications';
      buffer.writeln('$indent  <li>'
          '&#x1F4C4;<a href="${link.url}" class="nav-link" data-name="${link.relativePath}">'
          '${link.fileName}</a> (${link.modificationCount} $modifications)'
          '</li>');
    }
    buffer.writeln('$indent</ul>');
  }
}

/// Groups the items in [iterable] by the result of applying [groupFn] to each
/// item.
Map<K, List<T>> _groupBy<K, T>(
    Iterable<T> iterable, K Function(T item) groupFn) {
  var result = <K, List<T>>{};
  for (var item in iterable) {
    var key = groupFn(item);
    result.putIfAbsent(key, () => <T>[]).add(item);
  }
  return result;
}
