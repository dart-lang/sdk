// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis_server.utilities.change_builder_dart;

import 'package:analysis_server/src/utilities/change_builder_dart.dart';
import 'package:analysis_server/utilities/change_builder_core.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';

/**
 * A [ChangeBuilder] used to build changes in Dart files.
 *
 * Clients are not expected to subtype this class.
 */
abstract class DartChangeBuilder extends ChangeBuilder {
  /**
   * Initialize a newly created change builder.
   */
  factory DartChangeBuilder(AnalysisContext context) = DartChangeBuilderImpl;
}

/**
 * An [EditBuilder] used to build edits in Dart files.
 *
 * Clients are not expected to subtype this class.
 */
abstract class DartEditBuilder extends EditBuilder {
  /**
   * The group-id used for the name of a declaration.
   */
  static const String NAME_GROUP_ID = 'NAME';

  /**
   * The group-id used for the return type of a function, getter or method.
   */
  static const String RETURN_TYPE_GROUP_ID = 'RETURN_TYPE';

  /**
   * The group-id used for the name of the superclass in a class declaration.
   */
  static const String SUPERCLASS_GROUP_ID = 'SUPERCLASS';

  /**
   * Write the code for a declaration of a class with the given [name]. If
   * [isAbstract] is `true`, then the class will be abstract. If a [superclass]
   * is given then it will be the superclass of the class.
   */
  void writeClassDeclaration(String name,
      {bool isAbstract: false, DartType superclass});

  /**
   * Append a placeholder for an override of an inherited [member].
   */
  void writeOverrideOfInheritedMember(ExecutableElement member);

  /**
   * Write the code for a list of [parameters], including the surrounding
   * parentheses.
   */
  void writeParameters(Iterable<ParameterElement> parameters);

  /**
   * Write the code for a list of parameters that would match the given list of
   * [arguments], including the surrounding parentheses.
   */
  void writeParametersMatchingArguments(ArgumentList arguments);

  /**
   * Write the code for a single parameter with the given [type] and [name].
   * The [type] can be `null` if no type is to be specified for the parameter.
   */
  void writeParameterSource(DartType type, String name);

  /**
   * Write the code for a type annotation for the given [type]. If the [type] is
   * either `null` or represents the type 'dynamic', then the behavior depends
   * on whether a type is [required]. If [required] is `true`, then 'var' will
   * be written; otherwise, nothing is written.
   *
   * If the [groupName] is not `null`, then the name of the type (including type
   * parameters) will be included as a region in the linked edit group with that
   * name. If the [groupName] is not `null` and [addSupertypeProposals] is
   * `true`, then all of the supertypes of the [type] will be added as
   * suggestions for alternatives to the type name.
   */
  bool writeType(DartType type,
      {bool addSupertypeProposals: false, String groupName, bool required: false});
}

/**
 * A [FileEditBuilder] used to build edits for Dart files.
 *
 * Clients are not expected to subtype this class.
 */
abstract class DartFileEditBuilder extends FileEditBuilder {}
