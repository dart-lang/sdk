// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/metadata/expressions.dart' as shared;
import 'package:_fe_analyzer_shared/src/parser/member_kind.dart';
import 'package:_fe_analyzer_shared/src/scanner/scanner.dart' show Token;
import 'package:front_end/src/codes/diagnostic.dart' as diag;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/transformations/flags.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';

import '../api_prototype/experimental_flags.dart';
import '../api_prototype/lowering_predicates.dart';
import '../base/constant_context.dart';
import '../base/extension_scope.dart';
import '../base/local_scope.dart';
import '../base/lookup_result.dart';
import '../base/messages.dart';
import '../base/modifiers.dart';
import '../base/scope.dart';
import '../base/uri_offset.dart';
import '../builder/builder.dart';
import '../builder/constructor_reference_builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/member_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/named_type_builder.dart';
import '../builder/omitted_type_builder.dart';
import '../builder/property_builder.dart';
import '../builder/type_builder.dart';
import '../builder/variable_builder.dart';
import '../kernel/body_builder_context.dart';
import '../kernel/hierarchy/class_member.dart';
import '../kernel/hierarchy/members_builder.dart';
import '../kernel/implicit_field_type.dart';
import '../kernel/internal_ast.dart';
import '../kernel/kernel_helper.dart';
import '../kernel/late_lowering.dart' as late_lowering;
import '../kernel/member_covariance.dart';
import '../kernel/type_algorithms.dart';
import '../source/check_helper.dart';
import '../source/fragment_factory.dart';
import '../source/name_scheme.dart';
import '../source/name_space_builder.dart';
import '../source/nominal_parameter_name_space.dart';
import '../source/source_class_builder.dart';
import '../source/source_constructor_builder.dart';
import '../source/source_enum_builder.dart';
import '../source/source_extension_builder.dart';
import '../source/source_extension_type_declaration_builder.dart';
import '../source/source_factory_builder.dart';
import '../source/source_library_builder.dart';
import '../source/source_member_builder.dart';
import '../source/source_method_builder.dart';
import '../source/source_property_builder.dart';
import '../source/source_type_alias_builder.dart';
import '../source/source_type_parameter_builder.dart';
import '../source/type_parameter_factory.dart';
import '../type_inference/inference_results.dart';
import '../type_inference/type_inference_engine.dart';
import '../util/helpers.dart';
import 'constructor/declaration.dart';
import 'factory/declaration.dart';
import 'field/declaration.dart';
import 'getter/declaration.dart';
import 'getter/encoding.dart';
import 'method/declaration.dart';
import 'setter/declaration.dart';
import 'setter/encoding.dart';

part 'class.dart';
part 'class/declaration.dart';
part 'constructor.dart';
part 'declaration.dart';
part 'enum.dart';
part 'enum_element.dart';
part 'extension.dart';
part 'extension_type.dart';
part 'factory.dart';
part 'field.dart';
part 'field/body_builder_context.dart';
part 'field/class_member.dart';
part 'field/encoding.dart';
part 'function.dart';
part 'getter.dart';
part 'method.dart';
part 'mixin.dart';
part 'named_mixin_application.dart';
part 'primary_constructor.dart';
part 'primary_constructor_body.dart';
part 'primary_constructor_field.dart';
part 'setter.dart';
part 'type_parameter.dart';
part 'typedef.dart';
part 'util.dart';

sealed class Fragment {
  /// The declared name of this fragment.
  ///
  /// For unnamed extensions this is
  /// [UnnamedExtensionName.unnamedExtensionSentinel].
  ///
  /// For primary constructor bodies this is
  /// [PrimaryConstructorBodyFragment.nameSentinel].
  ///
  /// For setters this is the name without `=`.
  ///
  /// The name is used to group introductory fragments with augmenting fragments
  /// and to group getters, setters, and fields as properties.
  String get name;

  /// Returns a [UriOffsetLength] object that can be used to point to the
  /// declaration of this fragment.
  UriOffsetLength get uriOffset;

  /// The [Builder] created for this fragment.
  ///
  // TODO(johnniwinther): Implement this:
  /// The builder is shared between introductory fragments and augmenting
  /// fragments, as well as between getters, setters, and fields.
  Builder get builder;
}

/// Interface for a compilation unit as a fragment.
///
/// This is only implemented by [SourceCompilationUnit] but added to avoid
/// dependency on the whole [SourceCompilationUnit] interface.
abstract interface class LibraryFragment {
  /// Returns `true` if this is a patch library or patch part.
  bool get isPatch;

  /// The [ExtensionScope] for this compilation unit.
  ExtensionScope get extensionScope;
}

/// Common interface for declaration fragments such as
/// [ClassFragment], [ExtensionFragment], [ExtensionTypeFragment], etc.
abstract interface class DeclarationFragment {
  /// Returns `true` if this is a patch declaration.
  bool get isPatch;

  /// Type parameters declared on this declaration.
  List<TypeParameterFragment>? get typeParameters;

  /// Returns the body scope for this declaration.
  LookupScope get bodyScope;
}
