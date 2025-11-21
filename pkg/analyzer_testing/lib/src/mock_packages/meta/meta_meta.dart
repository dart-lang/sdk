// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

final metaMetaUnit = MockLibraryUnit('lib/meta_meta.dart', r'''
library meta_meta;

@Target({TargetKind.classType})
class Target {
  final Set<TargetKind> kinds;

  const Target(this.kinds);
}

class TargetKind {
  static const classType = TargetKind._('classes', 'classType');

  static const constructor = TargetKind._('constructors', 'constructor');

  static const directive = TargetKind._('directives', 'directive');

  static const enumType = TargetKind._('enums', 'enumType');

  static const enumValue = TargetKind._('enum values', 'enumValue');

  static const extension = TargetKind._('extensions', 'extension');

  static const extensionType = TargetKind._('extension types', 'extensionType');

  static const field = TargetKind._('fields', 'field');

  static const function = TargetKind._('top-level functions', 'function');

  static const library = TargetKind._('libraries', 'library');

  static const getter = TargetKind._('getters', 'getter');

  static const method = TargetKind._('methods', 'method');

  static const mixinType = TargetKind._('mixins', 'mixinType');

  static const optionalParameter = TargetKind._(
    'optional parameters',
    'optionalParameter',
  );

  static const overridableMember = TargetKind._(
    'overridable members',
    'overridableMember',
  );

  static const parameter = TargetKind._('parameters', 'parameter');

  static const setter = TargetKind._('setters', 'setter');

  static const topLevelVariable = TargetKind._(
    'top-level variables',
    'topLevelVariable',
  );

  static const type = TargetKind._(
    'types (classes, enums, mixins, or typedefs)',
    'type',
  );

  static const typedefType = TargetKind._('typedefs', 'typedefType');

  static const typeParameter = TargetKind._('type parameters', 'typeParameter');

  static const values = [
    classType,
    constructor,
    directive,
    enumType,
    enumValue,
    extension,
    extensionType,
    field,
    function,
    library,
    getter,
    method,
    mixinType,
    optionalParameter,
    overridableMember,
    parameter,
    setter,
    topLevelVariable,
    type,
    typedefType,
    typeParameter,
  ];

  final String displayString;

  final String name;

  const TargetKind._(this.displayString, this.name);
  int get index => throw 0;
  @override
  String toString() => throw 0;
}
''');
