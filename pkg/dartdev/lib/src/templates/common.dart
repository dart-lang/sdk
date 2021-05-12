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
# Defines a default set of lint rules enforced for projects at Google. For
# details and rationale, see
# https://github.com/dart-lang/pedantic#enabled-lints.

include: package:pedantic/analysis_options.yaml

# For lint rules and documentation, see http://dart-lang.github.io/linter/lints.

# Uncomment to specify additional rules.
# linter:
#   rules:
#     - camel_case_types

# analyzer:
#   exclude:
#     - path/to/excluded/files/**
''';

final String changelog = '''
## 1.0.0

- Initial version.
''';
