// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/src/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

/**
 * A [ChangeBuilder] used to build changes in Dart files.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class DartChangeBuilder implements ChangeBuilder {
  /**
   * Initialize a newly created change builder.
   */
  factory DartChangeBuilder(AnalysisDriver driver) = DartChangeBuilderImpl;

  @override
  Future<Null> addFileEdit(String path, int fileStamp,
      void buildFileEdit(DartFileEditBuilder builder));
}

/**
 * An [EditBuilder] used to build edits in Dart files.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class DartEditBuilder implements EditBuilder {
  @override
  void addLinkedEdit(
      String groupName, void buildLinkedEdit(DartLinkedEditBuilder builder));

  /**
   * Write the code for a declaration of a class with the given [name]. If a
   * list of [interfaces] is provided, then the class will implement those
   * interfaces. If [isAbstract] is `true`, then the class will be abstract. If
   * a [memberWriter] is provided, then it will be invoked to allow members to
   * be generated. (The members will automatically be preceded and followed by
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
      DartType superclass,
      String superclassGroupName});

  /**
   * Write the code for a constructor declaration in the class with the given
   * [className]. If [isConst] is `true`, then the constructor will be marked
   * as being a `const` constructor. If a [constructorName] is provided, then
   * the constructor will have the given name. If both a constructor name and a
   * [constructorNameGroupName] is provided, then the name of the constructor
   * will be included in the linked edit group with that name. If an
   * [argumentList] is provided then the constructor will have parameters that
   * match the given arguments. If no argument list is given, but a list of
   * [fieldNames] is provided, then field formal parameters will be created for
   * each of the field names.
   */
  void writeConstructorDeclaration(String className,
      {ArgumentList argumentList,
      SimpleIdentifier constructorName,
      String constructorNameGroupName,
      List<String> fieldNames,
      bool isConst: false});

  /**
   * Write the code for a declaration of a field with the given [name]. If an
   * [initializerWriter] is provided, it will be invoked to write the content of
   * the initializer. (The equal sign separating the field name from the
   * initializer expression will automatically be written.) If [isConst] is
   * `true`, then the declaration will be preceded by the `const` keyword. If
   * [isFinal] is `true`, then the declaration will be preceded by the `final`
   * keyword. (If both [isConst] and [isFinal] are `true`, then only the `const`
   * keyword will be written.) If [isStatic] is `true`, then the declaration
   * will be preceded by the `static` keyword. If a [nameGroupName] is
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
   * Write the code for a declaration of a function with the given [name]. If a
   * [bodyWriter] is provided, it will be invoked to write the body of the
   * function. (The space between the name and the body will automatically be
   * written.) If [isStatic] is `true`, then the declaration will be preceded
   * by the `static` keyword. If a [nameGroupName] is provided, the name of the
   * function will be included in the linked edit group with that name. If a
   * [returnType] is provided, then it will be used as the return type of the
   * function. If a [returnTypeGroupName] is provided, then if a return type was
   * written it will be in the linked edit group with that name. If a
   * [parameterWriter] is provided, then it will be invoked to write the
   * declarations of the parameters to the function. (The parentheses around the
   * parameters will automatically be written.)
   */
  void writeFunctionDeclaration(String name,
      {void bodyWriter(),
      bool isStatic: false,
      String nameGroupName,
      void parameterWriter(),
      DartType returnType,
      String returnTypeGroupName});

  /**
   * Write the code for a declaration of a getter with the given [name]. If a
   * [bodyWriter] is provided, it will be invoked to write the body of the
   * getter. (The space between the name and the body will automatically be
   * written.) If [isStatic] is `true`, then the declaration will be preceded
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
   * Write the code for a declaration of a local variable with the given [name].
   * If an [initializerWriter] is provided, it will be invoked to write the
   * content of the initializer. (The equal sign separating the variable name
   * from the initializer expression will automatically be written.) If
   * [isConst] is `true`, then the declaration will be preceded by the `const`
   * keyword. If [isFinal] is `true`, then the declaration will be preceded by
   * the `final` keyword. (If both [isConst] and [isFinal] are `true`, then only
   * the `const` keyword will be written.) If a [nameGroupName] is provided, the
   * name of the variable will be included in the linked edit group with that
   * name. If a [type] is provided, then it will be used as the type of the
   * variable. (The keyword `var` will be provided automatically when required.)
   * If a [typeGroupName] is provided, then if a type was written it will be in
   * the linked edit group with that name.
   */
  void writeLocalVariableDeclaration(String name,
      {void initializerWriter(),
      bool isConst: false,
      bool isFinal: false,
      String nameGroupName,
      DartType type,
      String typeGroupName});

  /**
   * Append a placeholder for an override of the specified inherited [member].
   */
  void writeOverrideOfInheritedMember(ExecutableElement member);

  /**
   * Write the code for a parameter that would match the given [argument]. The
   * name of the parameter will be generated based on the type of the argument,
   * but if the argument type is not known the [index] will be used to compose
   * a name. In any case, the set of [usedNames] will be used to ensure that the
   * name is unique (and the chosen name will be added to the set).
   */
  void writeParameterMatchingArgument(
      Expression argument, int index, Set<String> usedNames);

  /**
   * Write the code for a list of [parameters], including the surrounding
   * parentheses.
   *
   * If a [methodBeingCopied] is provided, then type parameters defined by that
   * method are assumed to be part of what is being written and hence valid
   * types.
   */
  void writeParameters(Iterable<ParameterElement> parameters,
      {ExecutableElement methodBeingCopied});

  /**
   * Write the code for a list of parameters that would match the given list of
   * [arguments]. The surrounding parentheses are *not* written.
   */
  void writeParametersMatchingArguments(ArgumentList arguments);

  /**
   * Write the code for a single parameter with the given [type] and [name].
   * The [type] can be `null` if no type is to be specified for the parameter.
   *
   * If a [methodBeingCopied] is provided, then type parameters defined by that
   * method are assumed to be part of what is being written and hence valid
   * types.
   */
  void writeParameterSource(DartType type, String name,
      {ExecutableElement methodBeingCopied});

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
   *
   * If a [methodBeingCopied] is provided, then type parameters defined by that
   * method are assumed to be part of what is being written and hence valid
   * types.
   */
  bool writeType(DartType type,
      {bool addSupertypeProposals: false,
      String groupName,
      ExecutableElement methodBeingCopied,
      bool required: false});

  /**
   * Write the code to declare the given [typeParameter]. The enclosing angle
   * brackets are not automatically written.
   */
  void writeTypeParameter(TypeParameterElement typeParameter);

  /**
   * Write the code to declare the given list of [typeParameters]. The enclosing
   * angle brackets are automatically written.
   */
  void writeTypeParameters(List<TypeParameterElement> typeParameters);
}

/**
 * A [FileEditBuilder] used to build edits for Dart files.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class DartFileEditBuilder implements FileEditBuilder {
  @override
  void addInsertion(int offset, void buildEdit(DartEditBuilder builder));

  @override
  void addReplacement(
      SourceRange range, void buildEdit(DartEditBuilder builder));

  /**
   * Create one or more edits that will convert the given function [body] from
   * being synchronous to be asynchronous. This includes adding the `async`
   * modifier to the body as well as potentially replacing the return type of
   * the function to `Future`.
   *
   * There is currently a limitation in that the function body must not be a
   * generator.
   *
   * Throws an [ArgumentError] if the function body is not both synchronous and
   * a non-generator.
   */
  void convertFunctionFromSyncToAsync(
      FunctionBody body, TypeProvider typeProvider);

  /**
   * Arrange to have imports added for each of the given [libraries].
   */
  void importLibraries(Iterable<Source> libraries);

  /**
   * Optionally create an edit to replace the given [typeAnnotation] with the
   * type `Future` (with the given type annotation as the type argument). The
   * [typeProvider] is used to check the current type, because if it is already
   * `Future` no edit will be added.
   */
  void replaceTypeWithFuture(
      TypeAnnotation typeAnnotation, TypeProvider typeProvider);
}

/**
 * A [LinkedEditBuilder] used to build linked edits for Dart files.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class DartLinkedEditBuilder implements LinkedEditBuilder {
  /**
   * Add the given [type] and all of its supertypes (other than mixins) as
   * suggestions for the current linked edit group.
   */
  void addSuperTypesAsSuggestions(DartType type);
}
