// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// -----------------------------------------------------------------------
///                          WHEN CHANGING THIS FILE:
/// -----------------------------------------------------------------------
///
/// If you are adding/removing/modifying fields/classes of the AST, you must
/// also update the following files:
///
///   - binary/ast_to_binary.dart
///   - binary/ast_from_binary.dart
///   - text/ast_to_text.dart
///   - clone.dart
///   - binary.md
///   - type_checker.dart (if relevant)
///
/// -----------------------------------------------------------------------
///                           ERROR HANDLING
/// -----------------------------------------------------------------------
///
/// As a rule of thumb, errors that can be detected statically are handled by
/// the frontend, typically by translating the erroneous code into a 'throw' or
/// a call to 'noSuchMethod'.
///
/// For example, there are no arity mismatches in static invocations, and
/// there are no direct invocations of a constructor on a abstract class.
///
/// -----------------------------------------------------------------------
///                           STATIC vs TOP-LEVEL
/// -----------------------------------------------------------------------
///
/// The term `static` includes both static class members and top-level members.
///
/// "Static class member" is the preferred term for non-top level statics.
///
/// Static class members are not lifted to the library level because mirrors
/// and stack traces can observe that they are class members.
///
/// -----------------------------------------------------------------------
///                                 PROCEDURES
/// -----------------------------------------------------------------------
///
/// "Procedure" is an umbrella term for method, getter, setter, index-getter,
/// index-setter, operator overloader, and factory constructor.
///
/// Generative constructors, field initializers, local functions are NOT
/// procedures.
///
/// -----------------------------------------------------------------------
///                               TRANSFORMATIONS
/// -----------------------------------------------------------------------
///
/// AST transformations can be performed using [TreeNode.replaceWith] or the
/// [Transformer] visitor class.
///
/// Use [Transformer] for bulk transformations that are likely to transform lots
/// of nodes, and [TreeNode.replaceWith] for sparse transformations that mutate
/// relatively few nodes.  Or use whichever is more convenient.
///
/// The AST can also be mutated by direct field manipulation, but the user then
/// has to update parent pointers manually.
///
library kernel.ast;

import 'dart:collection' show ListBase;
import 'dart:convert' show utf8;
import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/type_inference/nullability_suffix.dart';
import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer_operations.dart'
    show Variance;
import 'package:_fe_analyzer_shared/src/types/shared_type.dart'
    show
        SharedDynamicTypeStructure,
        SharedNamedFunctionParameterStructure,
        SharedFunctionTypeStructure,
        SharedInvalidTypeStructure,
        SharedNamedTypeStructure,
        SharedRecordTypeStructure,
        SharedTypeParameterStructure,
        SharedTypeStructure,
        SharedVoidTypeStructure;

import 'src/extension_type_erasure.dart';
import 'visitor.dart';
export 'visitor.dart';

import 'canonical_name.dart' show CanonicalName, Reference;
export 'canonical_name.dart' show CanonicalName, Reference;

import 'default_language_version.dart' show defaultLanguageVersion;
export 'default_language_version.dart' show defaultLanguageVersion;

import 'transformations/flags.dart';
import 'text/ast_to_text.dart' as astToText;
import 'core_types.dart';
import 'type_algebra.dart';
import 'type_environment.dart';
import 'src/assumptions.dart';
import 'src/non_null.dart';
import 'src/printer.dart';
import 'src/text_util.dart';

export 'package:_fe_analyzer_shared/src/type_inference/type_analyzer_operations.dart'
    show Variance;

part 'src/ast/constants.dart';
part 'src/ast/components.dart';
part 'src/ast/declarations.dart';
part 'src/ast/dummies.dart';
part 'src/ast/expressions.dart';
part 'src/ast/functions.dart';
part 'src/ast/helpers.dart';
part 'src/ast/initializers.dart';
part 'src/ast/libraries.dart';
part 'src/ast/members.dart';
part 'src/ast/misc.dart';
part 'src/ast/names.dart';
part 'src/ast/patterns.dart';
part 'src/ast/statements.dart';
part 'src/ast/typedefs.dart';
part 'src/ast/types.dart';
