// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final String gitignore = '''
# Files and directories created by pub.
.dart_tool/
.packages

# Conventional directory for build output.
build/
''';

final String analysisOptions = '''
# This file configures the static analysis results for your project (errors,
# warnings, and lints).

# The following line activates a set of core lints for Dart apps; this is the
# set that is used by pub.dev for scoring packages. For many projects, consider
# changing this to specify 'package:lints/recommended.yaml'; that's an
# additional set of lints designed to encourage good coding practices.

include: package:lints/core.yaml

# Uncomment the following section to specify additional rules.

# linter:
#   rules:
#     - camel_case_types

# analyzer:
#   exclude:
#     - path/to/excluded/files/**

# For more information about the core and recommended set of lints, see
# https://dart.dev/go/core-lints

# For additional information about configuring this file, see
# https://dart.dev/guides/language/analysis-options
''';

final String changelog = '''
## 1.0.0

- Initial version.
''';
