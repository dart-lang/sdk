// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/edit/nnbd_migration/instrumentation_renderer.dart';
import 'package:analysis_server/src/edit/nnbd_migration/migration_info.dart';
import 'package:path/src/context.dart';

/// The renderer used to displayed when the root of the included path is requested.
class IndexRenderer {
  /// Information for a whole migration, so that libraries can reference each
  /// other.
  final MigrationInfo migrationInfo;

  /// A flag indicating whether the paths for the links should be computed for
  /// the case where the rendered index will be written to disk.
  final bool writeToDisk;

  /// Initialize a newly index renderer.
  IndexRenderer(this.migrationInfo, {this.writeToDisk = false});

  /// Builds an HTML view of the included root directory.
  String render() {
    Context pathContext = migrationInfo.pathContext;
    String includedRoot = migrationInfo.includedRoot;

    StringBuffer buf = StringBuffer();
    buf.write('''
<html>
  <head>
    <title>Non-nullable fix instrumentation report</title>
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

.navigationHeader {
  padding-left: 1em;
}

.navigationLinks {
  padding-left: 2em;
}

.selectedFile {
  font-weight: bold;
}
    </style>
  </head>
  <body>
    <h1>Preview of NNBD migration</h1>
    <p><b>
    Select a migrated file to see the suggested modifications below.
    </b></p>
    <div class="navigationHeader">
''');
    buf.writeln(includedRoot);
    buf.write('''
    </div>
    <div class="navigationLinks">
''');
    for (UnitInfo unit in migrationInfo.units) {
      buf.write('<a href="');
      buf.write(_pathTo(unit, pathContext, includedRoot));
      buf.write('">');
      buf.write(_name(unit, pathContext, includedRoot));
      buf.write('</a> ');
      buf.write(_modificationCount(unit));
      buf.write('<br/>');
    }
    buf.write('''
    </div>
  </body>
</html>
''');
    return buf.toString();
  }

  /// Return the number of modifications made to the [unit].
  String _modificationCount(UnitInfo unit) {
    int count = unit.fixRegions.length;
    return count == 1 ? '(1 modification)' : '($count modifications)';
  }

  /// Return the path to [unit] from [includedRoot], to be used as a display
  /// name for a library.
  String _name(UnitInfo unit, Context pathContext, String includedRoot) =>
      pathContext.relative(unit.path, from: includedRoot);

  /// The path to [target], relative to [includedRoot].
  String _pathTo(UnitInfo target, Context pathContext, String includedRoot) {
    String targetPath;
    if (writeToDisk) {
      targetPath = pathContext.setExtension(target.path, '.html');
    } else {
      targetPath = target.path;
    }
    String sourceDir = pathContext.dirname(includedRoot);
    return pathContext.relative(targetPath, from: sourceDir);
  }
}
