// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/parser/member_kind.dart';
import 'package:_fe_analyzer_shared/src/scanner/scanner.dart' show Token;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/transformations/flags.dart';
import 'package:kernel/type_environment.dart';

import '../base/local_scope.dart';
import '../base/modifiers.dart';
import '../base/scope.dart';
import '../builder/builder.dart';
import '../builder/constructor_reference_builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/mixin_application_builder.dart';
import '../builder/omitted_type_builder.dart';
import '../builder/type_builder.dart';
import '../kernel/body_builder_context.dart';
import '../kernel/hierarchy/class_member.dart';
import '../kernel/hierarchy/members_builder.dart';
import '../kernel/type_algorithms.dart';
import '../source/name_scheme.dart';
import '../source/source_property_builder.dart';
import '../source/source_class_builder.dart';
import '../source/source_constructor_builder.dart';
import '../source/source_enum_builder.dart';
import '../source/source_extension_builder.dart';
import '../source/source_extension_type_declaration_builder.dart';
import '../source/source_factory_builder.dart';
import '../source/source_field_builder.dart';
import '../source/source_function_builder.dart';
import '../source/source_library_builder.dart';
import '../source/source_loader.dart';
import '../source/source_member_builder.dart';
import '../source/source_procedure_builder.dart';
import '../source/source_type_alias_builder.dart';
import '../source/type_parameter_scope_builder.dart';
import '../type_inference/type_inference_engine.dart';
import '../type_inference/type_schema.dart';

part 'class.dart';
part 'constructor.dart';
part 'enum.dart';
part 'extension.dart';
part 'extension_type.dart';
part 'factory.dart';
part 'field.dart';
part 'function.dart';
part 'getter.dart';
part 'method.dart';
part 'mixin.dart';
part 'named_mixin_application.dart';
part 'primary_constructor.dart';
part 'setter.dart';
part 'typedef.dart';
part 'util.dart';

sealed class Fragment {
  /// The declared name of this fragment.
  ///
  /// For unnamed extensions this is
  /// [UnnamedExtensionName.unnamedExtensionSentinel].
  ///
  /// For setters this is the name without `=`.
  ///
  /// The name is used to group introductory fragments with augmenting fragments
  /// and to group getters, setters, and fields as properties.
  String get name;

  /// The [Builder] created for this fragment.
  ///
  // TODO(johnniwinther): Implement this:
  /// The builder is shared between introductory fragments and augmenting
  /// fragments, as well as between getters, setters, and fields.
  Builder get builder;
}
