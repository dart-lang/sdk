// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis_server.plugin.edit.utilities.change_builder_dart;

import 'package:analysis_server/src/provisional/edit/utilities/change_builder_core.dart';
import 'package:analysis_server/src/utilities/change_builder_dart.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/generated/engine.dart';

/**
 * A [ChangeBuilder] used to build changes in Dart files.
 *
 * Clients may not extend, implement or mix-in this class.
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
 * Clients may not extend, implement or mix-in this class.
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
   * Write the code for a declaration of a class with the given [name]. If a
   * list of [interfaces] is provided, then the class will implement those
   * interfaces. If [isAbstract] is `true`, then the class will be abstract. If
   * a [memberWriter] is provided, then it will be invoked to allow members to
   * be generated. (The members will automatically be preceeded and followed by
   * end-of-line markers.) If a list of [mixins] is provided, then the class
   * will mix in those classes. If a [nameGroupName] is provided, then the name
   * of the class will be included in the linked edit group with that name. If a
   * [superclass] is given then it will be the superclass of the class. (If a
   * list of [mixins] is provided but no [superclass] is given then the class
   * will extend `Object`.)
   */
  void writeClassDeclaration(String name,
      {Iterable<DartType> interfaces,
      bool isAbstract: false,
      void memberWriter(),
      Iterable<DartType> mixins,
      String nameGroupName,
      DartType superclass});

  /**
   * Write the code for a declaration of a field with the given [name]. If an
   * [initializerWriter] is provided, it will be invoked to write the content of
   * the initializer. (The equal sign separating the field name from the
   * initializer expression will automatically be written.) If [isConst] is
   * `true`, then the declaration will be preceeded by the `const` keyword. If
   * [isFinal] is `true`, then the declaration will be preceeded by the `final`
   * keyword. (If both [isConst] and [isFinal] are `true`, then only the `const`
   * keyword will be written.) If [isStatic] is `true`, then the declaration
   * will be preceeded by the `static` keyword. If a [nameGroupName] is
   * provided, the name of the field will be included in the linked edit group
   * with that name. If a [type] is provided, then it will be used as the type
   * of the field. (The keyword `var` will be provided automatically when
   * required.) If a [typeGroupName] is provided, then if a type was written
   * it will be in the linked edit group with that name.
   */
  void writeFieldDeclaration(String name,
      {void initializerWriter(),
      bool isConst: false,
      bool isFinal: false,
      bool isStatic: false,
      String nameGroupName,
      DartType type,
      String typeGroupName});

  /**
   * Write the code for a declaration of a getter with the given [name]. If a
   * [bodyWriter] is provided, it will be invoked to write the body of the
   * getter. (The space between the name and the body will automatically be
   * written.) If [isStatic] is `true`, then the declaration will be preceeded
   * by the `static` keyword. If a [nameGroupName] is provided, the name of the
   * getter will be included in the linked edit group with that name. If a
   * [returnType] is provided, then it will be used as the return type of the
   * getter. If a [returnTypeGroupName] is provided, then if a return type was
   * written it will be in the linked edit group with that name.
   */
  void writeGetterDeclaration(String name,
      {void bodyWriter(),
      bool isStatic: false,
      String nameGroupName,
      DartType returnType,
      String returnTypeGroupName});

  /**
   * Append a placeholder for an override of the specified inherited [member].
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
      {bool addSupertypeProposals: false,
      String groupName,
      bool required: false});
}

/**
 * A [FileEditBuilder] used to build edits for Dart files.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class DartFileEditBuilder extends FileEditBuilder {}
