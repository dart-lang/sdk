// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:nnbd_migration/migration_cli.dart';

const String migratedAlready =
    'All sources appear to be already migrated.  Nothing to do.';
const String nnbdExperimentOff =
    'Analyzer seems to need the nnbd experiment on in the SDK.';
const String sdkNnbdOff = 'Analysis seems to have an SDK without NNBD enabled.';
const String sdkPathEnvironmentVariableSet =
    r'Note: $SDK_PATH environment variable is set and may point to outdated '
    'dart:core sources';
const String unmigratedDependenciesWarning = '''
Warning: package has unmigrated dependencies.

Continuing due to the presence of `$_skipImportCheckFlag`.  To see a complete
list of the unmigrated dependencies, re-run without the `$_skipImportCheckFlag`
flag.
''';
const String _skipImportCheckFlag =
    '--${CommandLineOptions.skipImportCheckFlag}';

String unmigratedDependenciesError(List<String> uris) => '''
Error: package has unmigrated dependencies.

Before migrating your package, we recommend ensuring that every library it
imports (either directly or indirectly) has been migrated to null safety, so
that you will be able to run your unit tests in sound null checking mode.  You
are currently importing the following non-null-safe libraries:

  ${uris.join('\n  ')}

Please upgrade the packages containing these libraries to null safe versions
before continuing.  To see what null safe package versions are available, run
the following command: `dart pub outdated --mode=null-safety`.

To skip this check and try to migrate anyway, re-run with the flag
`$_skipImportCheckFlag`.
''';
