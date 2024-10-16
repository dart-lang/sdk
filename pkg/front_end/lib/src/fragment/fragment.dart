// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/scanner.dart' show Token;
import 'package:kernel/ast.dart';

import '../base/modifiers.dart';
import '../base/scope.dart';
import '../builder/builder.dart';
import '../builder/constructor_reference_builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/mixin_application_builder.dart';
import '../builder/type_builder.dart';
import '../source/name_scheme.dart';
import '../source/source_class_builder.dart';
import '../source/source_constructor_builder.dart';
import '../source/source_enum_builder.dart';
import '../source/source_extension_builder.dart';
import '../source/source_extension_type_declaration_builder.dart';
import '../source/source_factory_builder.dart';
import '../source/source_field_builder.dart';
import '../source/source_procedure_builder.dart';
import '../source/source_type_alias_builder.dart';
import '../source/type_parameter_scope_builder.dart';

part 'class.dart';
part 'constructor.dart';
part 'enum.dart';
part 'extension.dart';
part 'extension_type.dart';
part 'factory.dart';
part 'field.dart';
part 'getter.dart';
part 'method.dart';
part 'mixin.dart';
part 'named_mixin_application.dart';
part 'setter.dart';
part 'typedef.dart';

sealed class Fragment {
  Builder get builder;
}
