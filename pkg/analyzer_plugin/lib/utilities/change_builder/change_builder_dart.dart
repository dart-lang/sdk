// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

/// The optional generator for prefix that should be used for new imports.
typedef ImportPrefixGenerator = String Function(Uri);

/// An [EditBuilder] used to build edits in Dart files.
///
/// Clients may not extend, implement or mix-in this class.
abstract class DartEditBuilder implements EditBuilder {
  @override
  void addLinkedEdit(String groupName,
      void Function(DartLinkedEditBuilder builder) buildLinkedEdit);

  /// Checks whether the code for a type annotation for the given [type] can be
  /// written.
  ///
  /// If a [methodBeingCopied] is provided, then type parameters defined by that
  /// method are assumed to be part of what is being written and hence valid
  /// types.
  ///
  /// The logic is the same as the one used in [writeType].
  bool canWriteType(DartType? type, {ExecutableElement? methodBeingCopied});

  /// Returns the indentation with the given [level].
  String getIndent(int level);

  /// Writes the code for a declaration of a class with the given [name].
  ///
  /// If a list of [interfaces] is provided, then the class will implement those
  /// interfaces. If [isAbstract] is `true`, then the class will be abstract. If
  /// a [membersWriter] is provided, then it will be invoked to allow members to
  /// be generated. If a list of [mixins] is provided, then the class will mix
  /// in those classes. If a [nameGroupName] is provided, then the name of the
  /// class will be included in the linked edit group with that name. If a
  /// [superclass] is given then it will be the superclass of the class. (If a
  /// list of [mixins] is provided but no [superclass] is given then the class
  /// will extend `Object`.)
  void writeClassDeclaration(String name,
      {Iterable<DartType>? interfaces,
      bool isAbstract = false,
      void Function()? membersWriter,
      Iterable<DartType>? mixins,
      String? nameGroupName,
      DartType? superclass,
      String? superclassGroupName});

  /// Writes the code for a constructor declaration in the class with the given
  /// [className].
  ///
  /// If [isConst] is `true`, then the constructor will be marked as being a
  /// `const` constructor. If a [constructorName] is provided, then the
  /// constructor will have the given name. If both a constructor name and a
  /// [constructorNameGroupName] is provided, then the name of the constructor
  /// will be included in the linked edit group with that name. If a
  /// [parameterWriter] is provided, then it is used to write the constructor
  /// parameters (enclosing parenthesis are written for you). Otherwise, if an
  /// [argumentList] is provided then the constructor will have parameters that
  /// match the given arguments. If no argument list is given, but a list of
  /// [fieldNames] is provided, then field formal parameters will be created for
  /// each of the field names. If an [initializerWriter] is provided then it is
  /// used to write the constructor initializers (the ` : ` prefix is written
  /// for you). If a [bodyWriter] is provided then it is used to write the
  /// constructor body, otherwise an empty body is written.
  void writeConstructorDeclaration(String className,
      {ArgumentList? argumentList,
      void Function()? bodyWriter,
      String? classNameGroupName,
      String? constructorName,
      String? constructorNameGroupName,
      List<String>? fieldNames,
      void Function()? initializerWriter,
      bool isConst = false,
      void Function()? parameterWriter});

  /// Writes the code for a declaration of a field with the given [name].
  ///
  /// If an [initializerWriter] is provided, it will be invoked to write the
  /// content of the initializer. (The equal sign separating the field name from
  /// the initializer expression will automatically be written.) If [isConst] is
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
      {void Function()? initializerWriter,
      bool isConst = false,
      bool isFinal = false,
      bool isStatic = false,
      String? nameGroupName,
      DartType? type,
      String? typeGroupName});

  /// Writes the code for a declaration of a function with the given [name].
  ///
  /// If a [bodyWriter] is provided, it will be invoked to write the body of the
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
      {void Function()? bodyWriter,
      bool isStatic = false,
      String? nameGroupName,
      void Function()? parameterWriter,
      DartType? returnType,
      String? returnTypeGroupName});

  /// Writes the code for a declaration of a getter with the given [name].
  ///
  /// If a [bodyWriter] is provided, it will be invoked to write the body of the
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

  /// Writes the given [name], possibly with a prefix, assuming that the name
  /// can be imported from any of the given [uris].
  void writeImportedName(List<Uri> uris, String name);

  /// Writes an indent, two spaces for every [level].
  void writeIndent([int level = 1]);

  /// Writes the code for a declaration of a local variable with the given
  /// [name].
  ///
  /// If an [initializerWriter] is provided, it will be invoked to write the
  /// content of the initializer. (The equal sign separating the variable name
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
      {void Function()? initializerWriter,
      bool isConst = false,
      bool isFinal = false,
      String? nameGroupName,
      DartType? type,
      String? typeGroupName});

  /// Writes the code for a declaration of a mixin with the given [name].
  ///
  /// If a list of [interfaces] is provided, then the mixin will implement those
  /// interfaces. If a [membersWriter] is provided, then it will be invoked to
  /// allow members to be generated. If a [nameGroupName] is provided, then the
  /// name of the class will be included in the linked edit group with that
  /// name.
  void writeMixinDeclaration(String name,
      {Iterable<DartType>? interfaces,
      void Function()? membersWriter,
      String? nameGroupName,
      Iterable<DartType>? superclassConstraints});

  /// Appends a placeholder for an override of the specified inherited
  /// [element].
  ///
  /// If provided, writes a string value suitable for display (e.g., in a
  /// completion popup) in the given [displayTextBuffer]. If [invokeSuper] is
  /// `true`, then the corresponding `super.name()` will be added in the body.
  /// If [setSelection] is `true`, then the cursor will be placed in the body of
  /// the override.
  void writeOverride(
    ExecutableElement element, {
    StringBuffer? displayTextBuffer,
    bool invokeSuper = false,
    bool setSelection = true,
  });

  /// Writes the code for a single parameter with the given [name].
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
  /// If [isRequiredNamed] is `true` then the keyword `required` will be
  /// included in the parameter declaration.
  ///
  /// If [isRequiredType] is `true` then the type is always written.
  void writeParameter(String name,
      {bool isCovariant,
      bool isRequiredNamed,
      ExecutableElement? methodBeingCopied,
      String? nameGroupName,
      DartType? type,
      String? typeGroupName,
      bool isRequiredType});

  /// Writes the code for a parameter that would match the given [argument].
  ///
  /// The name of the parameter will be generated based on the type of the
  /// argument, but if the argument type is not known the [index] will be used
  /// to compose a name. In any case, the set of [usedNames] will be used to
  /// ensure that the name is unique (and the chosen name will be added to the
  /// set).
  void writeParameterMatchingArgument(
      Expression argument, int index, Set<String> usedNames);

  /// Writes the code for a list of [parameters], including the surrounding
  /// parentheses and default values (unless [includeDefaultValues] is `false`).
  ///
  /// If a [methodBeingCopied] is provided, then type parameters defined by that
  /// method are assumed to be part of what is being written and hence valid
  /// types.
  ///
  /// If [requiredTypes] is `true`, then the types are always written.
  void writeParameters(Iterable<ParameterElement> parameters,
      {ExecutableElement? methodBeingCopied,
      bool includeDefaultValues = true,
      bool requiredTypes});

  /// Writes the code for a list of parameters that would match the given list
  /// of [arguments].
  ///
  /// The surrounding parentheses are *not* written.
  void writeParametersMatchingArguments(ArgumentList arguments);

  /// Writes the code that references the [element].
  ///
  /// If the [element] is a top-level element that has not been imported into
  /// the current library, imports will be updated.
  void writeReference(Element element);

  /// Writes the code for a declaration of a setter with the given [name].
  ///
  /// If a [bodyWriter] is provided, it will be invoked to write the body of the
  /// setter. (The space between the name and the body will automatically be
  /// written.) If [isStatic] is `true`, then the declaration will be preceded
  /// by the `static` keyword. If a [nameGroupName] is provided, the name of the
  /// getter will be included in the linked edit group with that name. If a
  /// [parameterType] is provided, then it will be used as the type of the
  /// parameter. If a [parameterTypeGroupName] is provided, then if a parameter
  /// type was written it will be in the linked edit group with that name.
  void writeSetterDeclaration(String name,
      {void Function()? bodyWriter,
      bool isStatic = false,
      String? nameGroupName,
      DartType? parameterType,
      String? parameterTypeGroupName});

  /// Writes the code for a type annotation for the given [type].
  ///
  /// If the [type] is either `null` or represents the type `dynamic`, then the
  /// behavior depends on whether a type is [required]. If [required] is `true`,
  /// then the keyword `var` will be written; otherwise, nothing is written.
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
  /// Returns `true` if any text was written.
  bool writeType(DartType? type,
      {bool addSupertypeProposals = false,
      String? groupName,
      ExecutableElement? methodBeingCopied,
      bool required = false});

  /// Writes the code to declare the given [typeParameter].
  ///
  /// The enclosing angle brackets are not automatically written.
  ///
  /// If a [methodBeingCopied] is provided, then type parameters defined by that
  /// method are assumed to be part of what is being written and hence valid
  /// types.
  void writeTypeParameter(TypeParameterElement typeParameter,
      {ExecutableElement? methodBeingCopied});

  /// Writes the code to declare the given list of [typeParameters]. The
  /// enclosing angle brackets are automatically written.
  ///
  /// If a [methodBeingCopied] is provided, then type parameters defined by that
  /// method are assumed to be part of what is being written and hence valid
  /// types.
  void writeTypeParameters(List<TypeParameterElement> typeParameters,
      {ExecutableElement? methodBeingCopied});

  /// Writes the code for a comma-separated list of [types], optionally prefixed
  /// by a [prefix].
  ///
  /// If the list of [types] is `null` or does not contain any types, then
  /// nothing will be written.
  void writeTypes(Iterable<DartType>? types, {String? prefix});
}

/// A [FileEditBuilder] used to build edits for Dart files.
///
/// Clients may not extend, implement or mix-in this class.
abstract class DartFileEditBuilder implements FileEditBuilder {
  /// Sets the file header to be added before any generated imports.
  ///
  /// A blank line will automatically be added after the file header.
  set fileHeader(String fileHeader);

  /// A list of new URIs that must be imported for the types being referenced in
  /// edits.
  List<Uri> get requiredImports;

  @override
  // TODO(srawlins): Rename to `insert`.
  void addInsertion(
      int offset, void Function(DartEditBuilder builder) buildEdit);

  @override
  // TODO(srawlins): Rename to `replace`.
  void addReplacement(
      SourceRange range, void Function(DartEditBuilder builder) buildEdit);

  /// Checks whether the code for a type annotation for the given [type] can be
  /// written.
  ///
  /// If a [methodBeingCopied] is provided, then type parameters defined by that
  /// method are assumed to be part of what is being written and hence valid
  /// types.
  bool canWriteType(DartType? type, {ExecutableElement? methodBeingCopied});

  /// Creates one or more edits that will convert the given function [body] from
  /// being synchronous to be asynchronous. This includes adding the `async`
  /// modifier to the body as well as potentially replacing the return type of
  /// the function to `Future`.
  ///
  /// There is currently a limitation in that the function body must not be a
  /// generator.
  ///
  /// Throws an [ArgumentError] if the function body is not both synchronous and
  /// a non-generator.
  void convertFunctionFromSyncToAsync({
    required FunctionBody body,
    required TypeSystem typeSystem,
    required TypeProvider typeProvider,
  });

  /// Formats the code covered by the [range].
  ///
  /// If there are any edits that are in the [range], these edits are applied
  /// first, and replaced with a single new edit that produces the resulting
  /// formatted code. The [range] is relative to the original code.
  void format(SourceRange range);

  /// Arranges to have an import added for the library with the given [uri].
  ///
  /// If a [prefix] is provided it will be used in the import directive.
  ///
  /// If [showName] is provided, imports will be modified to make sure this
  /// symbol is shown.
  ///
  /// If [useShow] is `true`, new imports will show only the given [showName],
  /// instead of importing the library without a show clause.
  ///
  /// Returns the text of the URI that will be used in the import directive. It
  /// can be different than the given [uri].
  ///
  /// The [uri] may be converted from an absolute URI to a relative URI
  /// depending on the set of enabled lints.
  String importLibrary(
    Uri uri, {
    String? prefix,
    String? showName,
    bool useShow = false,
  });

  /// Ensures that the library with the given [uri] is imported.
  ///
  /// If there is already an import for the requested library, returns the
  /// import prefix of the existing import directive.
  ///
  /// If there is no existing import, a new import is added.
  ImportLibraryElementResult importLibraryElement(Uri uri);

  /// Returns whether the given library [uri] is already imported or will be
  /// imported by a scheduled edit.
  bool importsLibrary(Uri uri);

  /// Inserts the code for a case clause at the end of a switch statement or
  /// switch expression.
  void insertCaseClauseAtEnd(
    void Function(DartEditBuilder builder) buildEdit, {
    required Token switchKeyword,
    required Token rightParenthesis,
    required Token leftBracket,
    required Token rightBracket,
  });

  /// Inserts the code for a constructor.
  ///
  /// The constructor is inserted after the last existing field or constructor,
  /// or if the `sort_constructors_first` lint rule is enabled, after the last
  /// existing constructor.
  ///
  /// Throws an exception if [container] is not a [CompilationUnitMember] which
  /// can have constructor declarations.
  void insertConstructor(
    CompilationUnitMember container,
    void Function(DartEditBuilder builder) buildEdit,
  );

  /// Inserts the code for a field.
  ///
  /// The field is inserted after the last existing field, or at the beginning
  /// of [compilationUnitMember], if it has no existing fields.
  void insertField(
    CompilationUnitMember compilationUnitMember,
    void Function(DartEditBuilder builder) buildEdit,
  );

  /// Inserts the code for a getter.
  ///
  /// The getter is inserted after the last existing field, constructor, or
  /// getter, or at the beginning of [compilationUnitMember], if it has none of
  /// these.
  void insertGetter(
    CompilationUnitMember compilationUnitMember,
    void Function(DartEditBuilder builder) buildEdit,
  );

  /// Inserts into a [CompilationUnitMember].
  ///
  /// The new member is inserted at an offset determined by [lastMemberFilter].
  ///
  /// If [lastMemberFilter] is omitted, the new member is inserted after all
  /// existing members.
  ///
  /// Otherwise, the offset is just after the last member of
  /// [compilationUnitMember] that matches [lastMemberFilter]. If no existing
  /// member matches, then the offset is at the beginning of
  /// [compilationUnitMember], just after it's opening brace.
  void insertIntoUnitMember(
    CompilationUnitMember compilationUnitMember,
    void Function(DartEditBuilder builder) buildEdit, {
    bool Function(ClassMember existingMember)? lastMemberFilter,
  });

  /// Inserts the code for a method.
  ///
  /// The method is inserted after the last existing field, constructor, or
  /// method, or at the beginning of [compilationUnitMember], if it has none of
  /// these.
  void insertMethod(
    CompilationUnitMember compilationUnitMember,
    void Function(DartEditBuilder builder) buildEdit,
  );

  /// Optionally creates an edit to replace the given [typeAnnotation] with the
  /// type `Future` (with the given type annotation as the type argument).
  ///
  /// The [typeSystem] is used to check the current type, because if it is
  /// already `Future`, no edit will be added.
  void replaceTypeWithFuture({
    required TypeAnnotation typeAnnotation,
    required TypeSystem typeSystem,
    required TypeProvider typeProvider,
  });
}

/// A [LinkedEditBuilder] used to build linked edits for Dart files.
///
/// Clients may not extend, implement or mix-in this class.
abstract class DartLinkedEditBuilder implements LinkedEditBuilder {
  /// Adds the given [type] and all of its supertypes (other than mixins) as
  /// suggestions for the current linked edit group.
  void addSuperTypesAsSuggestions(DartType? type);
}

/// Information about a library to import.
abstract class ImportLibraryElementResult {
  /// If the library is already imported with a prefix, or should be imported
  /// with a prefix, the prefix name (without `.`). Otherwise `null`.
  String? get prefix;
}
