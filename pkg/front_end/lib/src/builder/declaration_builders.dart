// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/src/bounds_checks.dart';
import 'package:kernel/src/unaliasing.dart';

import '../base/lookup_result.dart';
import '../base/messages.dart';
import '../base/name_space.dart';
import '../base/problems.dart' show unexpected, unhandled;
import '../base/scope.dart';
import '../base/uris.dart';
import '../codes/cfe_codes.dart';
import '../source/source_library_builder.dart';
import '../source/type_parameter_factory.dart';
import '../type_inference/type_schema.dart' show UnknownType;
import '../util/helpers.dart';
import 'builder.dart';
import 'builder_mixins.dart';
import 'formal_parameter_builder.dart';
import 'library_builder.dart';
import 'member_builder.dart';
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
part 'type_alias_builder.dart';
part 'type_declaration_builder.dart';
part 'type_parameter_builder.dart';

sealed class TypeDeclarationBuilder implements ITypeDeclarationBuilder {}

sealed class DeclarationBuilder
    implements TypeDeclarationBuilder, IDeclarationBuilder {}
