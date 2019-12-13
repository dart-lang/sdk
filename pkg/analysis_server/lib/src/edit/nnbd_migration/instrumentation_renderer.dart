// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/edit/nnbd_migration/dart_page_script.dart';
import 'package:analysis_server/src/edit/nnbd_migration/dart_page_style.dart';
import 'package:analysis_server/src/edit/nnbd_migration/migration_info.dart';
import 'package:analysis_server/src/edit/nnbd_migration/path_mapper.dart';
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
    <p><b>
    Hover over modified regions to see why the migration tool chose to make the
    modification.
    </b></p>
    <h2 id="unit-name">&nbsp;</h2>
    <div class="panels">
    <div class="horizontal">
    <div class="nav" style="">
      <p>Select a source file below to preview the modifications.</p>
      <p class="root">{{ root }}</p>
      {{# links }}
        <a href="#" class="nav-link"
            data-path="{{ path }}"
            data-name="{{ name }}">{{ name }}</a>
        {{ modificationCount }}
        <br/>
      {{/ links }}
    </div><!-- /nav -->
    '''
    '<div class="content">'
    '<div class="code">{{! Compilation unit content is written here. }}</div>'
    '<div class="regions">'
    '{{! The regions are then written again, overlaying the first copy of }}'
    '{{! the content, to provide tooltips for modified regions. }}'
    '</div><!-- /regions -->'
    '</div><!-- /content -->'
    '''
    </div><!-- /horizontal -->
    <div><em>Generated on {{ generationDate }}</em></div>
    </div><!-- /panels -->
    <script lang="javascript">
document.addEventListener("DOMContentLoaded", highlightAllCode);
    </script>
  </body>
</html>''');

/// Instrumentation display output for a library that was migrated to use
/// non-nullable types.
class InstrumentationRenderer {
  /// A flag indicating whether the incremental workflow is currently supported.
  static const bool supportsIncrementalWorkflow = false;

  /// Information for a whole migration, so that libraries can reference each
  /// other.
  final MigrationInfo migrationInfo;

  /// An object used to map the file paths of analyzed files to the file paths
  /// of the HTML files used to view the content of those files.
  final PathMapper pathMapper;

  /// Creates an output object for the given library info.
  InstrumentationRenderer(this.migrationInfo, this.pathMapper);

  /// Return the path context used to manipulate paths.
  path.Context get pathContext => migrationInfo.pathContext;

  /// Builds an HTML view of the instrumentation information.
  String render() {
    Map<String, dynamic> mustacheContext = {
      'root': migrationInfo.includedRoot,
      'dartPageScript': dartPageScript,
      'dartPageStyle': dartPageStyle,
      'links': migrationInfo.unitLinks(),
      'highlightJsPath': migrationInfo.highlightJsPath,
      'highlightStylePath': migrationInfo.highlightStylePath,
      'generationDate': migrationInfo.migrationDate,
    };
    return _template.renderString(mustacheContext);
  }
}
