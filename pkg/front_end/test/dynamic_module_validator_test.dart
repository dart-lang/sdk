// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_prototype/compiler_options.dart';
import 'package:front_end/src/compute_platform_binaries_location.dart';
import 'package:front_end/src/testing/compiler_common.dart';
import 'package:test/test.dart';

void main() {
  group('DynamicModuleValidator', () {
    test(
      'handles top-level members and extensions in dynamically-callable',
      () async {
        var errors = [];
        var options = CompilerOptions()
          ..onDiagnostic = errors.add
          ..sdkSummary = computePlatformBinariesLocation().resolve(
            'vm_platform.dill',
          );

        const source = '''
void topLevelFunction() {}

extension IntExtension on int {
  int doubleIt() => this * 2;
}

extension type IntExtensionType(int value) {
  int tripleIt() => value * 3;
}
''';

        final aUriStr = toTestUri('a.dart').toString();
        final diContent =
            '''
callable:
  - library: 'dart:core'
  - library: '$aUriStr'
can-be-used-as-type:
  - library: 'dart:core'
  - library: '$aUriStr'
can-be-overridden:
  - library: 'dart:core'
  - library: '$aUriStr'
dynamically-callable:
  - library: '$aUriStr'
''';

        final sources = {'a.dart': source, 'dynamic_interface.yaml': diContent};

        options.dynamicInterfaceSpecificationUri = toTestUri(
          'dynamic_interface.yaml',
        );
        options.allowDynamicCallsInDynamicModules = true;

        var result = await compileUnit(['a.dart'], sources, options: options);
        expect(result, isNotNull);
        expect(errors, isEmpty);
      },
    );
  });
}
