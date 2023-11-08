// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/src/unaliasing.dart';

import '../fasta_codes.dart';
import '../kernel/body_builder_context.dart';
import '../messages.dart';
import '../modifier.dart';
import '../problems.dart' show internalProblem, unhandled;
import '../scope.dart';
import '../source/source_library_builder.dart';
import '../type_inference/type_schema.dart' show UnknownType;
import '../uris.dart';
import '../util/helpers.dart';
import 'builder.dart';
import 'builder_mixins.dart';
import 'formal_parameter_builder.dart';
import 'library_builder.dart';
import 'member_builder.dart';
import 'metadata_builder.dart';
import 'modifier_builder.dart';
import 'name_iterator.dart';
import 'named_type_builder.dart';
import 'nullability_builder.dart';
import 'record_type_builder.dart';
import 'type_builder.dart';

part 'builtin_type_declaration_builder.dart';
part 'class_builder.dart';
part 'declaration_builder.dart';
part 'extension_builder.dart';
part 'extension_type_declaration_builder.dart';
part 'invalid_type_declaration_builder.dart';
part 'omitted_type_declaration_builder.dart';
part 'type_alias_builder.dart';
part 'type_declaration_builder.dart';
part 'type_variable_builder.dart';

sealed class TypeDeclarationBuilder implements ITypeDeclarationBuilder {}

sealed class DeclarationBuilder
    implements TypeDeclarationBuilder, IDeclarationBuilder {}
