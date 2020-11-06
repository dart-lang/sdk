// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import '../fasta/builder/class_builder.dart';
import '../fasta/builder/library_builder.dart';
import '../fasta/builder/member_builder.dart';
import '../fasta/builder/named_type_builder.dart';
import '../fasta/builder/type_builder.dart';
import '../fasta/builder/type_variable_builder.dart';
import '../fasta/builder/extension_builder.dart';
import '../fasta/messages.dart';
import '../fasta/source/source_library_builder.dart';
import '../fasta/source/source_loader.dart';
import '../kernel_generator_impl.dart';

/// Helper methods to use in annotated tests.

/// Returns a canonical simple name for [member].
String getMemberName(Member member) {
  if (member is Procedure && member.isSetter) return '${member.name.text}=';
  return member.name.text;
}

/// Returns the enclosing [Member] for [node].
Member getEnclosingMember(TreeNode node) {
  while (node is! Member) {
    node = node.parent;
  }
  return node;
}

/// Finds the first [Library] in [component] with the given import [uri].
///
/// If [required] is `true` an error is thrown if no library was found.
Library lookupLibrary(Component component, Uri uri, {bool required: true}) {
  return component.libraries
      .firstWhere((Library library) => library.importUri == uri, orElse: () {
    if (required) {
      throw new ArgumentError("Library '$uri' not found.");
    }
    return null;
  });
}

/// Finds the first [Class] in [library] with the given [className].
///
/// If [required] is `true` an error is thrown if no class was found.
Class lookupClass(Library library, String className, {bool required: true}) {
  return library.classes.firstWhere((Class cls) => cls.name == className,
      orElse: () {
    if (required) {
      throw new ArgumentError("Class '$className' not found in '$library'.");
    }
    return null;
  });
}

/// Finds the first [Extension] in [library] with the given [className].
///
/// If [required] is `true` an error is thrown if no class was found.
Extension lookupExtension(Library library, String extensionName,
    {bool required: true}) {
  return library.extensions.firstWhere(
      (Extension extension) => extension.name == extensionName, orElse: () {
    if (required) {
      throw new ArgumentError(
          "Extension '$extensionName' not found in '${library.importUri}'.");
    }
    return null;
  });
}

/// Finds the first [Member] in [library] with the given canonical simple
/// [memberName] as computed by [getMemberName].
///
/// If [required] is `true` an error is thrown if no member was found.
Member lookupLibraryMember(Library library, String memberName,
    {bool required: true}) {
  return library.members.firstWhere(
      (Member member) => getMemberName(member) == memberName, orElse: () {
    if (required) {
      throw new ArgumentError("Member '$memberName' not found in '$library'.");
    }
    return null;
  });
}

/// Finds the first [Member] in [cls] with the given canonical simple
/// [memberName] as computed by [getMemberName].
///
/// If [required] is `true` an error is thrown if no member was found.
Member lookupClassMember(Class cls, String memberName, {bool required: true}) {
  return cls.members.firstWhere(
      (Member member) => getMemberName(member) == memberName, orElse: () {
    if (required) {
      throw new ArgumentError("Member '$memberName' not found in '$cls'.");
    }
    return null;
  });
}

LibraryBuilder lookupLibraryBuilder(
    InternalCompilerResult compilerResult, Library library,
    {bool required: true}) {
  SourceLoader loader = compilerResult.kernelTargetForTesting.loader;
  SourceLibraryBuilder builder = loader.builders[library.importUri];
  if (builder == null && required) {
    throw new ArgumentError("DeclarationBuilder for $library not found.");
  }
  return builder;
}

TypeParameterScopeBuilder lookupLibraryDeclarationBuilder(
    InternalCompilerResult compilerResult, Library library,
    {bool required: true}) {
  SourceLibraryBuilder builder =
      lookupLibraryBuilder(compilerResult, library, required: required);
  return builder.libraryDeclaration;
}

ClassBuilder lookupClassBuilder(
    InternalCompilerResult compilerResult, Class cls,
    {bool required: true}) {
  TypeParameterScopeBuilder libraryBuilder = lookupLibraryDeclarationBuilder(
      compilerResult, cls.enclosingLibrary,
      required: required);
  ClassBuilder clsBuilder = libraryBuilder.members[cls.name];
  if (clsBuilder == null && required) {
    throw new ArgumentError("ClassBuilder for $cls not found.");
  }
  return clsBuilder;
}

ExtensionBuilder lookupExtensionBuilder(
    InternalCompilerResult compilerResult, Extension extension,
    {bool required: true}) {
  TypeParameterScopeBuilder libraryBuilder = lookupLibraryDeclarationBuilder(
      compilerResult, extension.enclosingLibrary,
      required: required);
  ExtensionBuilder extensionBuilder = libraryBuilder.members[extension.name];
  if (extensionBuilder == null && required) {
    throw new ArgumentError("ExtensionBuilder for $extension not found.");
  }
  return extensionBuilder;
}

/// Look up the [MemberBuilder] for [member] through the [ClassBuilder] for
/// [cls] using [memberName] as its name.
MemberBuilder lookupClassMemberBuilder(InternalCompilerResult compilerResult,
    Class cls, Member member, String memberName,
    {bool required: true}) {
  ClassBuilder classBuilder =
      lookupClassBuilder(compilerResult, cls, required: required);
  MemberBuilder memberBuilder;
  if (classBuilder != null) {
    if (member is Constructor || member is Procedure && member.isFactory) {
      memberBuilder = classBuilder.constructors.local[memberName];
    } else {
      memberBuilder = classBuilder.scope.lookupLocalMember(memberName,
          setter: member is Procedure && member.isSetter);
    }
  }
  if (memberBuilder == null && required) {
    throw new ArgumentError("MemberBuilder for $member not found.");
  }
  return memberBuilder;
}

MemberBuilder lookupMemberBuilder(
    InternalCompilerResult compilerResult, Member member,
    {bool required: true}) {
  MemberBuilder memberBuilder;
  if (member.isExtensionMember) {
    String memberName = member.name.text;
    String extensionName = memberName.substring(0, memberName.indexOf('|'));
    memberName = memberName.substring(extensionName.length + 1);
    bool isSetter = member is Procedure && member.isSetter;
    if (memberName.startsWith('set#')) {
      memberName = memberName.substring(4);
      isSetter = true;
    } else if (memberName.startsWith('get#')) {
      memberName = memberName.substring(4);
    }
    Extension extension =
        lookupExtension(member.enclosingLibrary, extensionName);
    memberBuilder = lookupExtensionMemberBuilder(
        compilerResult, extension, member, memberName,
        isSetter: isSetter, required: required);
  } else if (member.enclosingClass != null) {
    memberBuilder = lookupClassMemberBuilder(
        compilerResult, member.enclosingClass, member, member.name.text,
        required: required);
  } else {
    TypeParameterScopeBuilder libraryBuilder = lookupLibraryDeclarationBuilder(
        compilerResult, member.enclosingLibrary,
        required: required);
    if (member is Procedure && member.isSetter) {
      memberBuilder = libraryBuilder.setters[member.name.text];
    } else {
      memberBuilder = libraryBuilder.members[member.name.text];
    }
  }
  if (memberBuilder == null && required) {
    throw new ArgumentError("MemberBuilder for $member not found.");
  }
  return memberBuilder;
}

/// Look up the [MemberBuilder] for [member] through the [ExtensionBuilder] for
/// [extension] using [memberName] as its name.
MemberBuilder lookupExtensionMemberBuilder(
    InternalCompilerResult compilerResult,
    Extension extension,
    Member member,
    String memberName,
    {bool isSetter: false,
    bool required: true}) {
  ExtensionBuilder extensionBuilder =
      lookupExtensionBuilder(compilerResult, extension, required: required);
  MemberBuilder memberBuilder;
  if (extensionBuilder != null) {
    memberBuilder =
        extensionBuilder.scope.lookupLocalMember(memberName, setter: isSetter);
  }
  if (memberBuilder == null && required) {
    throw new ArgumentError("MemberBuilder for $member not found.");
  }
  return memberBuilder;
}

/// Returns a textual representation of the constant [node] to be used in
/// testing.
String constantToText(Constant node,
    {TypeRepresentation typeRepresentation: TypeRepresentation.legacy}) {
  StringBuffer sb = new StringBuffer();
  new ConstantToTextVisitor(sb, typeRepresentation).visit(node);
  return sb.toString();
}

enum TypeRepresentation {
  legacy,
  explicit,
  // The type representation is made match the non-nullable-by-default type
  // display string from the analyzer.
  analyzerNonNullableByDefault,
}

/// Returns a textual representation of the type [node] to be used in
/// testing.
String typeToText(DartType node,
    [TypeRepresentation typeRepresentation = TypeRepresentation.legacy]) {
  StringBuffer sb = new StringBuffer();
  new DartTypeToTextVisitor(sb, typeRepresentation).visit(node);
  return sb.toString();
}

Set<Class> computeAllSuperclasses(Class node) {
  Set<Class> set = <Class>{};
  _getAllSuperclasses(node, set);
  return set;
}

void _getAllSuperclasses(Class node, Set<Class> set) {
  if (set.add(node)) {
    if (node.supertype != null) {
      _getAllSuperclasses(node.supertype.classNode, set);
    }
    if (node.mixedInType != null) {
      _getAllSuperclasses(node.mixedInType.classNode, set);
    }
    for (Supertype interface in node.implementedTypes) {
      _getAllSuperclasses(interface.classNode, set);
    }
  }
}

String supertypeToText(Supertype node,
    [TypeRepresentation typeRepresentation = TypeRepresentation.legacy]) {
  StringBuffer sb = new StringBuffer();
  sb.write(node.classNode.name);
  if (node.typeArguments.isNotEmpty) {
    sb.write('<');
    new DartTypeToTextVisitor(sb, typeRepresentation)
        .visitList(node.typeArguments);
    sb.write('>');
  }
  return sb.toString();
}

class ConstantToTextVisitor implements ConstantVisitor<void> {
  final StringBuffer sb;
  final DartTypeToTextVisitor typeToText;

  ConstantToTextVisitor(this.sb, TypeRepresentation typeRepresentation)
      : typeToText = new DartTypeToTextVisitor(sb, typeRepresentation);

  void visit(Constant node) => node.accept(this);

  void visitList(Iterable<Constant> nodes) {
    String comma = '';
    for (Constant node in nodes) {
      sb.write(comma);
      visit(node);
      comma = ',';
    }
  }

  void defaultConstant(Constant node) => throw new UnimplementedError(
      'Unexpected constant $node (${node.runtimeType})');

  void visitNullConstant(NullConstant node) {
    sb.write('Null()');
  }

  void visitBoolConstant(BoolConstant node) {
    sb.write('Bool(${node.value})');
  }

  void visitIntConstant(IntConstant node) {
    sb.write('Int(${node.value})');
  }

  void visitDoubleConstant(DoubleConstant node) {
    sb.write('Double(${node.value})');
  }

  void visitStringConstant(StringConstant node) {
    sb.write('String(${node.value})');
  }

  void visitSymbolConstant(SymbolConstant node) {
    sb.write('Symbol(${node.name})');
  }

  void visitMapConstant(MapConstant node) {
    sb.write('Map<');
    typeToText.visit(node.keyType);
    sb.write(',');
    typeToText.visit(node.valueType);
    sb.write('>(');
    String comma = '';
    for (ConstantMapEntry entry in node.entries) {
      sb.write(comma);
      entry.key.accept(this);
      sb.write(':');
      entry.value.accept(this);
      comma = ',';
    }
    sb.write(')');
  }

  void visitListConstant(ListConstant node) {
    sb.write('List<');
    typeToText.visit(node.typeArgument);
    sb.write('>(');
    visitList(node.entries);
    sb.write(')');
  }

  void visitSetConstant(SetConstant node) {
    sb.write('Set<');
    typeToText.visit(node.typeArgument);
    sb.write('>(');
    visitList(node.entries);
    sb.write(')');
  }

  void visitInstanceConstant(InstanceConstant node) {
    sb.write('Instance(');
    sb.write(node.classNode.name);
    if (node.typeArguments.isNotEmpty) {
      sb.write('<');
      typeToText.visitList(node.typeArguments);
      sb.write('>');
    }
    if (node.fieldValues.isNotEmpty) {
      sb.write(',{');
      String comma = '';
      for (Reference ref in node.fieldValues.keys) {
        sb.write(comma);
        sb.write(getMemberName(ref.asField));
        sb.write(':');
        visit(node.fieldValues[ref]);
        comma = ',';
      }
      sb.write('}');
    }
    sb.write(')');
  }

  void visitPartialInstantiationConstant(PartialInstantiationConstant node) {
    sb.write('Instantiation(');
    sb.write(getMemberName(node.tearOffConstant.procedure));
    sb.write('<');
    typeToText.visitList(node.types);
    sb.write('>)');
  }

  void visitTearOffConstant(TearOffConstant node) {
    sb.write('Function(');
    sb.write(getMemberName(node.procedure));
    sb.write(')');
  }

  void visitTypeLiteralConstant(TypeLiteralConstant node) {
    sb.write('TypeLiteral(');
    typeToText.visit(node.type);
    sb.write(')');
  }

  void visitUnevaluatedConstant(UnevaluatedConstant node) {
    sb.write('Unevaluated()');
  }
}

class DartTypeToTextVisitor implements DartTypeVisitor<void> {
  final StringBuffer sb;
  final TypeRepresentation typeRepresentation;

  DartTypeToTextVisitor(this.sb, this.typeRepresentation);

  String get commaText {
    if (typeRepresentation == TypeRepresentation.analyzerNonNullableByDefault) {
      return ', ';
    } else {
      return ',';
    }
  }

  void visit(DartType node) => node.accept(this);

  void visitList(Iterable<DartType> nodes) {
    String comma = '';
    for (DartType node in nodes) {
      sb.write(comma);
      visit(node);
      comma = commaText;
    }
  }

  void defaultDartType(DartType node) => throw new UnimplementedError(
      'Unexpected type $node (${node.runtimeType})');

  void visitInvalidType(InvalidType node) {
    sb.write('<invalid>');
  }

  void visitDynamicType(DynamicType node) {
    sb.write('dynamic');
  }

  void visitVoidType(VoidType node) {
    sb.write('void');
  }

  void visitBottomType(BottomType node) {
    sb.write('<bottom>');
  }

  void visitNeverType(NeverType node) {
    sb.write('Never');
    if (node.nullability != Nullability.nonNullable) {
      sb.write(nullabilityToText(node.nullability, typeRepresentation));
    }
  }

  void visitNullType(NullType node) {
    sb.write('Null');
  }

  void visitInterfaceType(InterfaceType node) {
    sb.write(node.classNode.name);
    if (node.typeArguments.isNotEmpty) {
      sb.write('<');
      visitList(node.typeArguments);
      sb.write('>');
    }
    if (!isNull(node)) {
      sb.write(nullabilityToText(node.nullability, typeRepresentation));
    }
  }

  void visitFutureOrType(FutureOrType node) {
    sb.write('FutureOr<');
    visit(node.typeArgument);
    sb.write('>');
    sb.write(nullabilityToText(node.declaredNullability, typeRepresentation));
  }

  void visitFunctionType(FunctionType node) {
    visit(node.returnType);
    sb.write(' Function');
    if (node.typeParameters.isNotEmpty) {
      sb.write('<');
      for (int i = 0; i < node.typeParameters.length; i++) {
        if (i > 0) {
          sb.write(',');
          if (typeRepresentation ==
              TypeRepresentation.analyzerNonNullableByDefault) {
            sb.write(' ');
          }
        }
        TypeParameter typeParameter = node.typeParameters[i];
        sb.write(typeParameter.name);
        DartType bound = typeParameter.bound;
        if (!(bound is InterfaceType && bound.classNode.name == 'Object')) {
          sb.write(' extends ');
          visit(bound);
        }
      }
      sb.write('>');
    }
    sb.write('(');
    String comma = '';
    visitList(node.positionalParameters.take(node.requiredParameterCount));
    if (node.requiredParameterCount > 0) {
      comma = commaText;
    }
    if (node.requiredParameterCount < node.positionalParameters.length) {
      sb.write(comma);
      sb.write('[');
      visitList(node.positionalParameters.skip(node.requiredParameterCount));
      sb.write(']');
      comma = commaText;
    }
    if (node.namedParameters.isNotEmpty) {
      sb.write(comma);
      sb.write('{');
      comma = '';
      for (NamedType namedParameter in node.namedParameters) {
        sb.write(comma);
        if (namedParameter.isRequired) {
          sb.write('required ');
        }
        visit(namedParameter.type);
        sb.write(' ');
        sb.write(namedParameter.name);
        comma = commaText;
      }
      sb.write('}');
    }
    sb.write(')');
    sb.write(nullabilityToText(node.nullability, typeRepresentation));
  }

  void visitTypeParameterType(TypeParameterType node) {
    sb.write(node.parameter.name);
    sb.write(nullabilityToText(node.nullability, typeRepresentation));
    if (node.promotedBound != null) {
      sb.write(' & ');
      visit(node.promotedBound);
    }
  }

  void visitTypedefType(TypedefType node) {
    sb.write(node.typedefNode.name);
    if (node.typeArguments.isNotEmpty) {
      sb.write('<');
      visitList(node.typeArguments);
      sb.write('>');
    }
    sb.write(nullabilityToText(node.nullability, typeRepresentation));
  }
}

/// Returns `true` if [type] is `Object` from `dart:core`.
bool isObject(DartType type) {
  return type is InterfaceType &&
      type.classNode.name == 'Object' &&
      '${type.classNode.enclosingLibrary.importUri}' == 'dart:core';
}

/// Returns `true` if [type] is `Null` from `dart:core`.
bool isNull(DartType type) => type is NullType;

/// Returns a textual representation of the [typeParameter] to be used in
/// testing.
String typeParameterToText(TypeParameter typeParameter) {
  String name = typeParameter.name;
  if (!isObject(typeParameter.bound)) {
    return '$name extends ${typeToText(typeParameter.bound)}';
  }
  return name;
}

/// Returns a textual representation of the [type] to be used in testing.
String typeBuilderToText(TypeBuilder type) {
  StringBuffer sb = new StringBuffer();
  _typeBuilderToText(type, sb);
  return sb.toString();
}

void _typeBuilderToText(TypeBuilder type, StringBuffer sb) {
  if (type is NamedTypeBuilder) {
    sb.write(type.name);
    if (type.arguments != null && type.arguments.isNotEmpty) {
      sb.write('<');
      _typeBuildersToText(type.arguments, sb);
      sb.write('>');
    }
  } else {
    throw 'Unhandled type builder $type (${type.runtimeType})';
  }
}

void _typeBuildersToText(Iterable<TypeBuilder> types, StringBuffer sb) {
  String comma = '';
  for (TypeBuilder type in types) {
    sb.write(comma);
    _typeBuilderToText(type, sb);
    comma = ',';
  }
}

/// Returns a textual representation of the [typeVariable] to be used in
/// testing.
String typeVariableBuilderToText(TypeVariableBuilder typeVariable) {
  String name = typeVariable.name;
  if (typeVariable.bound != null) {
    return '$name extends ${typeBuilderToText(typeVariable.bound)}';
  }
  return name;
}

/// Returns a textual representation of [errors] to be used in testing.
String errorsToText(List<FormattedMessage> errors, {bool useCodes: false}) {
  if (useCodes) {
    return errors.map((m) => m.code).join(',');
  } else {
    return errors.map((m) => m.message).join(',');
  }
}

/// Returns a textual representation of [descriptor] to be used in testing.
String extensionMethodDescriptorToText(ExtensionMemberDescriptor descriptor) {
  StringBuffer sb = new StringBuffer();
  if (descriptor.isStatic) {
    sb.write('static ');
  }
  switch (descriptor.kind) {
    case ExtensionMemberKind.Method:
      break;
    case ExtensionMemberKind.Getter:
      sb.write('getter ');
      break;
    case ExtensionMemberKind.Setter:
      sb.write('setter ');
      break;
    case ExtensionMemberKind.Operator:
      sb.write('operator ');
      break;
    case ExtensionMemberKind.Field:
      sb.write('field ');
      break;
    case ExtensionMemberKind.TearOff:
      sb.write('tearoff ');
      break;
  }
  sb.write(descriptor.name.text);
  sb.write('=');
  Member member = descriptor.member.asMember;
  String name = member.name.text;
  if (member is Procedure && member.isSetter) {
    sb.write('$name=');
  } else {
    sb.write(name);
  }
  return sb.toString();
}

/// Returns a textual representation of [nullability] to be used in testing.
String nullabilityToText(
    Nullability nullability, TypeRepresentation typeRepresentation) {
  switch (nullability) {
    case Nullability.nonNullable:
      switch (typeRepresentation) {
        case TypeRepresentation.explicit:
        case TypeRepresentation.legacy:
          return '!';
        case TypeRepresentation.analyzerNonNullableByDefault:
          return '';
      }
      break;
    case Nullability.nullable:
      return '?';
    case Nullability.undetermined:
      switch (typeRepresentation) {
        case TypeRepresentation.analyzerNonNullableByDefault:
          return '';
        default:
          return '%';
      }
      break;
    case Nullability.legacy:
      switch (typeRepresentation) {
        case TypeRepresentation.legacy:
          return '';
        case TypeRepresentation.explicit:
        case TypeRepresentation.analyzerNonNullableByDefault:
          return '*';
      }
      break;
  }
  throw new UnsupportedError('Unexpected nullability: $nullability.');
}
