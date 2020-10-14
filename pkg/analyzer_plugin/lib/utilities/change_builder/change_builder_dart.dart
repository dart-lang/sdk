// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/src/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

/// The optional generator for prefix that should be used for new imports.
typedef ImportPrefixGenerator = String Function(Uri);

/// A [ChangeBuilder] used to build changes in Dart files.
///
/// Clients may not extend, implement or mix-in this class.
@Deprecated('Use ChangeBuilder')
abstract class DartChangeBuilder implements ChangeBuilder {
  /// Initialize a newly created change builder.
  @Deprecated('Use ChangeBuilder(session: session)')
  factory DartChangeBuilder(AnalysisSession session) = DartChangeBuilderImpl;

  /// Use the [buildFileEdit] function to create a collection of edits to the
  /// file with the given [path]. The edits will be added to the source change
  /// that is being built.
  ///
  /// If [importPrefixGenerator] is provided, it will be asked to generate an
  /// import prefix for every newly imported library.
  @Deprecated('Use ChangeBuilder.addDartFileEdit')
  @override
  Future<void> addFileEdit(
      String path, void Function(DartFileEditBuilder builder) buildFileEdit,
      {ImportPrefixGenerator importPrefixGenerator});
}

/// An [EditBuilder] used to build edits in Dart files.
///
/// Clients may not extend, implement or mix-in this class.
abstract class DartEditBuilder implements EditBuilder {
  @override
  void addLinkedEdit(String groupName,
      void Function(DartLinkedEditBuilder builder) buildLinkedEdit);

  /// Write the code for a declaration of a class with the given [name]. If a
  /// list of [interfaces] is provided, then the class will implement those
  /// interfaces. If [isAbstract] is `true`, then the class will be abstract. If
  /// a [membersWriter] is provided, then it will be invoked to allow members to
  /// be generated. If a list of [mixins] is provided, then the class
  /// will mix in those classes. If a [nameGroupName] is provided, then the name
  /// of the class will be included in the linked edit group with that name. If
  /// a [superclass] is given then it will be the superclass of the class. (If a
  /// list of [mixins] is provided but no [superclass] is given then the class
  /// will extend `Object`.)
  void writeClassDeclaration(String name,
      {Iterable<DartType> interfaces,
      bool isAbstract = false,
      void Function() membersWriter,
      Iterable<DartType> mixins,
      String nameGroupName,
      DartType superclass,
      String superclassGroupName});

  /// Write the code for a constructor declaration in the class with the given
  /// [className]. If [isConst] is `true`, then the constructor will be marked
  /// as being a `const` constructor. If a [constructorName] is provided, then
  /// the constructor will have the given name. If both a constructor name and
  /// a [constructorNameGroupName] is provided, then the name of the constructor
  /// will be included in the linked edit group with that name. If a
  /// [parameterWriter] is provided then it is used to write the constructor
  /// parameters (enclosing parenthesis are written for you). Otherwise, if an
  /// [argumentList] is provided then the constructor will have parameters that
  /// match the given arguments. If no argument list is given, but a list of
  /// [fieldNames] is provided, then field formal parameters will be created for
  /// each of the field names. If an [initializerWriter] is provided then it is
  /// used to write the constructor initializers (the ` : ` prefix is written
  /// for you). If a [bodyWriter] is provided then it is used to write the
  /// constructor body, otherwise an empty body is written.
  void writeConstructorDeclaration(String className,
      {ArgumentList argumentList,
      void Function() bodyWriter,
      String classNameGroupName,
      SimpleIdentifier constructorName,
      String constructorNameGroupName,
      List<String> fieldNames,
      void Function() initializerWriter,
      bool isConst = false,
      void Function() parameterWriter});

  /// Write the code for a declaration of a field with the given [name]. If an
  /// [initializerWriter] is provided, it will be invoked to write the content
  /// of the initializer. (The equal sign separating the field name from the
  /// initializer expression will automatically be written.) If [isConst] is
  /// `true`, then the declaration will be preceded by the `const` keyword. If
  /// [isFinal] is `true`, then the declaration will be preceded by the `final`
  /// keyword. (If both [isConst] and [isFinal] are `true`, then only the
  /// `const` keyword will be written.) If [isStatic] is `true`, then the
  /// declaration will be preceded by the `static` keyword. If a [nameGroupName]
  /// is provided, the name of the field will be included in the linked edit
  /// group with that name. If a [type] is provided, then it will be used as the
  /// type of the field. (The keyword `var` will be provided automatically when
  /// required.) If a [typeGroupName] is provided, then if a type was written
  /// it will be in the linked edit group with that name.
  void writeFieldDeclaration(String name,
      {void Function() initializerWriter,
      bool isConst = false,
      bool isFinal = false,
      bool isStatic = false,
      String nameGroupName,
      DartType type,
      String typeGroupName});

  /// Write the code for a declaration of a function with the given [name]. If a
  /// [bodyWriter] is provided, it will be invoked to write the body of the
  /// function. (The space between the name and the body will automatically be
  /// written.) If [isStatic] is `true`, then the declaration will be preceded
  /// by the `static` keyword. If a [nameGroupName] is provided, the name of the
  /// function will be included in the linked edit group with that name. If a
  /// [returnType] is provided, then it will be used as the return type of the
  /// function. If a [returnTypeGroupName] is provided, then if a return type
  /// was written it will be in the linked edit group with that name. If a
  /// [parameterWriter] is provided, then it will be invoked to write the
  /// declarations of the parameters to the function. (The parentheses around
  /// the parameters will automatically be written.)
  void writeFunctionDeclaration(String name,
      {void Function() bodyWriter,
      bool isStatic = false,
      String nameGroupName,
      void Function() parameterWriter,
      DartType returnType,
      String returnTypeGroupName});

  /// Write the code for a declaration of a getter with the given [name]. If a
  /// [bodyWriter] is provided, it will be invoked to write the body of the
  /// getter. (The space between the name and the body will automatically be
  /// written.) If [isStatic] is `true`, then the declaration will be preceded
  /// by the `static` keyword. If a [nameGroupName] is provided, the name of the
  /// getter will be included in the linked edit group with that name. If a
  /// [returnType] is provided, then it will be used as the return type of the
  /// getter. If a [returnTypeGroupName] is provided, then if a return type was
  /// written it will be in the linked edit group with that name.
  void writeGetterDeclaration(String name,
      {void Function() bodyWriter,
      bool isStatic = false,
      String nameGroupName,
      DartType returnType,
      String returnTypeGroupName});

  /// Write the given [name], possibly with a prefix, assuming that the name can
  /// be imported from any of the given [uris].
  void writeImportedName(List<Uri> uris, String name);

  /// Write the code for a declaration of a local variable with the given
  /// [name]. If an [initializerWriter] is provided, it will be invoked to write
  /// the content of the initializer. (The equal sign separating the variable
  /// name from the initializer expression will automatically be written.) If
  /// [isConst] is `true`, then the declaration will be preceded by the `const`
  /// keyword. If [isFinal] is `true`, then the declaration will be preceded by
  /// the `final` keyword. (If both [isConst] and [isFinal] are `true`, then
  /// only the `const` keyword will be written.) If a [nameGroupName] is
  /// provided, the name of the variable will be included in the linked edit
  /// group with that name. If a [type] is provided, then it will be used as the
  /// type of the variable. (The keyword `var` will be provided automatically
  /// when required.) If a [typeGroupName] is provided, then if a type was
  /// written it will be in the linked edit group with that name.
  void writeLocalVariableDeclaration(String name,
      {void Function() initializerWriter,
      bool isConst = false,
      bool isFinal = false,
      String nameGroupName,
      DartType type,
      String typeGroupName});

  /// Write the code for a declaration of a mixin with the given [name]. If a
  /// list of [interfaces] is provided, then the mixin will implement those
  /// interfaces. If a [membersWriter] is provided, then it will be invoked to
  /// allow members to be generated. If a [nameGroupName] is provided, then the
  /// name of the class will be included in the linked edit group with that
  /// name.
  void writeMixinDeclaration(String name,
      {Iterable<DartType> interfaces,
      void Function() membersWriter,
      String nameGroupName,
      Iterable<DartType> superclassConstraints});

  /// Append a placeholder for an override of the specified inherited [element].
  /// If provided, write a string value suitable for display (e.g., in a
  /// completion popup) in the given [displayTextBuffer]. If [invokeSuper] is
  /// `true`, then the corresponding `super.name()` will be added in the body.
  void writeOverride(
    ExecutableElement element, {
    StringBuffer displayTextBuffer,
    bool invokeSuper = false,
  });

  /// Write the code for a single parameter with the given [name].
  ///
  /// If a [methodBeingCopied] is provided, then type parameters defined by that
  /// method are assumed to be part of what is being written and hence valid
  /// types.
  ///
  /// If a [type] is provided, then it will be used as the type of the
  /// parameter.
  ///
  /// If a [nameGroupName] is provided, then the name of the parameter will be
  /// included in a linked edit.
  ///
  /// If a [type] and [typeGroupName] are both provided, then the type of the
  /// parameter will be included in a linked edit.
  ///
  /// If [isCovariant] is `true` then the keyword `covariant` will be included
  /// in the parameter declaration.
  ///
  /// If [isRequiredNamed] is `true` then either the keyword `required` or the
  /// annotation `@required` will be included in the parameter declaration.
  void writeParameter(String name,
      {bool isCovariant,
      bool isRequiredNamed,
      ExecutableElement methodBeingCopied,
      String nameGroupName,
      DartType type,
      String typeGroupName});

  /// Write the code for a parameter that would match the given [argument]. The
  /// name of the parameter will be generated based on the type of the argument,
  /// but if the argument type is not known the [index] will be used to compose
  /// a name. In any case, the set of [usedNames] will be used to ensure that
  /// the name is unique (and the chosen name will be added to the set).
  void writeParameterMatchingArgument(
      Expression argument, int index, Set<String> usedNames);

  /// Write the code for a list of [parameters], including the surrounding
  /// parentheses.
  ///
  /// If a [methodBeingCopied] is provided, then type parameters defined by that
  /// method are assumed to be part of what is being written and hence valid
  /// types.
  void writeParameters(Iterable<ParameterElement> parameters,
      {ExecutableElement methodBeingCopied});

  /// Write the code for a list of parameters that would match the given list of
  /// [arguments]. The surrounding parentheses are *not* written.
  void writeParametersMatchingArguments(ArgumentList arguments);

  /// Write the code that references the [element]. If the [element] is a
  /// top-level element that has not been imported into the current library,
  /// imports will be updated.
  void writeReference(Element element);

  /// Write the code for a declaration of a setter with the given [name]. If a
  /// [bodyWriter] is provided, it will be invoked to write the body of the
  /// setter. (The space between the name and the body will automatically be
  /// written.) If [isStatic] is `true`, then the declaration will be preceded
  /// by the `static` keyword. If a [nameGroupName] is provided, the name of the
  /// getter will be included in the linked edit group with that name. If a
  /// [parameterType] is provided, then it will be used as the type of the
  /// parameter. If a [parameterTypeGroupName] is provided, then if a parameter
  /// type was written it will be in the linked edit group with that name.
  void writeSetterDeclaration(String name,
      {void Function() bodyWriter,
      bool isStatic = false,
      String nameGroupName,
      DartType parameterType,
      String parameterTypeGroupName});

  /// Write the code for a type annotation for the given [type]. If the [type]
  /// is either `null` or represents the type 'dynamic', then the behavior
  /// depends on whether a type is [required]. If [required] is `true`, then
  /// 'var' will be written; otherwise, nothing is written.
  ///
  /// If the [groupName] is not `null`, then the name of the type (including
  /// type parameters) will be included as a region in the linked edit group
  /// with that name. If the [groupName] is not `null` and
  /// [addSupertypeProposals] is `true`, then all of the supertypes of the
  /// [type] will be added as suggestions for alternatives to the type name.
  ///
  /// If a [methodBeingCopied] is provided, then type parameters defined by that
  /// method are assumed to be part of what is being written and hence valid
  /// types.
  ///
  /// Return `true` if some text was written.
  bool writeType(DartType type,
      {bool addSupertypeProposals = false,
      String groupName,
      ExecutableElement methodBeingCopied,
      bool required = false});

  /// Write the code to declare the given [typeParameter]. The enclosing angle
  /// brackets are not automatically written.
  ///
  /// If a [methodBeingCopied] is provided, then type parameters defined by that
  /// method are assumed to be part of what is being written and hence valid
  /// types.
  void writeTypeParameter(TypeParameterElement typeParameter,
      {ExecutableElement methodBeingCopied});

  /// Write the code to declare the given list of [typeParameters]. The
  /// enclosing angle brackets are automatically written.
  ///
  /// If a [methodBeingCopied] is provided, then type parameters defined by that
  /// method are assumed to be part of what is being written and hence valid
  /// types.
  void writeTypeParameters(List<TypeParameterElement> typeParameters,
      {ExecutableElement methodBeingCopied});

  /// Write the code for a comma-separated list of [types], optionally prefixed
  /// by a [prefix]. If the list of [types] is `null` or does not contain any
  /// types, then nothing will be written.
  void writeTypes(Iterable<DartType> types, {String prefix});
}

/// A [FileEditBuilder] used to build edits for Dart files.
///
/// Clients may not extend, implement or mix-in this class.
abstract class DartFileEditBuilder implements FileEditBuilder {
  @override
  void addInsertion(
      int offset, void Function(DartEditBuilder builder) buildEdit);

  @override
  void addReplacement(
      SourceRange range, void Function(DartEditBuilder builder) buildEdit);

  /// Create one or more edits that will convert the given function [body] from
  /// being synchronous to be asynchronous. This includes adding the `async`
  /// modifier to the body as well as potentially replacing the return type of
  /// the function to `Future`.
  ///
  /// There is currently a limitation in that the function body must not be a
  /// generator.
  ///
  /// Throws an [ArgumentError] if the function body is not both synchronous and
  /// a non-generator.
  void convertFunctionFromSyncToAsync(
      FunctionBody body, TypeProvider typeProvider);

  /// Format the code covered by the [range].
  ///
  /// If there are any edits that are in the [range], these edits are applied
  /// first, and replaced with a single new edit that produces the resulting
  /// formatted code. The [range] is relative to the original code.
  void format(SourceRange range);

  /// Arrange to have an import added for the library with the given [uri].
  ///
  /// Returns the text of the URI that will be used in the import directive.
  /// It can be different than the given [Uri].
  String importLibrary(Uri uri);

  /// Ensure that the library with the given [uri] is imported.
  ///
  /// If there is already an import for the requested library, return the import
  /// prefix of the existing import directive.
  ///
  /// If there is no existing import, a new import is added.
  ImportLibraryElementResult importLibraryElement(Uri uri);

  /// Optionally create an edit to replace the given [typeAnnotation] with the
  /// type `Future` (with the given type annotation as the type argument). The
  /// [typeProvider] is used to check the current type, because if it is already
  /// `Future` no edit will be added.
  void replaceTypeWithFuture(
      TypeAnnotation typeAnnotation, TypeProvider typeProvider);
}

/// A [LinkedEditBuilder] used to build linked edits for Dart files.
///
/// Clients may not extend, implement or mix-in this class.
abstract class DartLinkedEditBuilder implements LinkedEditBuilder {
  /// Add the given [type] and all of its supertypes (other than mixins) as
  /// suggestions for the current linked edit group.
  void addSuperTypesAsSuggestions(DartType type);
}

/// Information about a library to import.
abstract class ImportLibraryElementResult {
  /// If the library is already imported with a prefix, or should be imported
  /// with a prefix, the prefix name (without `.`). Otherwise `null`.
  String get prefix;
}
