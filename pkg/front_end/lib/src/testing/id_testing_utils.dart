// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import '../base/lookup_result.dart';
import '../base/messages.dart';
import '../builder/builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../builder/type_builder.dart';
import '../kernel_generator_impl.dart';
import '../source/source_loader.dart';

/// Helper methods to use in annotated tests.

/// Returns a canonical simple name for [member].
String getMemberName(Member member) {
  if (member is Procedure && member.isSetter) return '${member.name.text}=';
  return member.name.text;
}

/// Returns a canonical qualified name for [member].
String getQualifiedMemberName(Member member) {
  if (member.enclosingClass != null) {
    return '${member.enclosingClass!.name}.${getMemberName(member)}';
  }
  return getMemberName(member);
}

/// Returns the enclosing [Member] for [node].
Member getEnclosingMember(TreeNode? node) {
  while (node is! Member) {
    node = node!.parent;
  }
  return node;
}

/// Finds the first [Library] in [component] with the given import [uri].
///
/// If [required] is `true` an error is thrown if no library was found.
Library? lookupLibrary(Component component, Uri uri, {bool required = true}) {
  for (Library library in component.libraries) {
    if (library.importUri == uri) {
      return library;
    }
    for (LibraryPart part in library.parts) {
      if (library.fileUri.resolve(part.partUri) == uri) {
        return library;
      }
    }
  }
  if (required) {
    throw new ArgumentError("Library '$uri' not found.");
  }
  return null;
}

/// Finds the first [Class] in [library] with the given [className].
///
/// If [required] is `true` an error is thrown if no class was found.
Class? lookupClass(Library library, String className, {bool required = true}) {
  for (Class cls in library.classes) {
    if (cls.name == className) {
      return cls;
    }
  }
  if (required) {
    throw new ArgumentError("Class '$className' not found in '$library'.");
  }
  return null;
}

/// Finds the first [Extension] in [library] with the given [extensionName].
///
/// If [required] is `true` an error is thrown if no extension was found.
Extension? lookupExtension(Library library, String extensionName,
    {bool required = true}) {
  for (Extension extension in library.extensions) {
    if (extension.name == extensionName) {
      return extension;
    }
  }
  if (required) {
    throw new ArgumentError(
        "Extension '$extensionName' not found in '${library.importUri}'.");
  }
  return null;
}

/// Finds the first [ExtensionTypeDeclaration] in [library] with the given
/// [extensionTypeName].
///
/// If [required] is `true` an error is thrown if no extension type was found.
ExtensionTypeDeclaration? lookupExtensionTypeDeclaration(
    Library library, String extensionTypeName,
    {bool required = true}) {
  for (ExtensionTypeDeclaration extensionTypeDeclaration
      in library.extensionTypeDeclarations) {
    if (extensionTypeDeclaration.name == extensionTypeName) {
      return extensionTypeDeclaration;
    }
  }
  if (required) {
    throw new ArgumentError("Extension type '$extensionTypeName' not found in "
        "'${library.importUri}'.");
  }
  return null;
}

/// Finds the first [Member] in [library] with the given canonical simple
/// [memberName] as computed by [getMemberName].
///
/// If [required] is `true` an error is thrown if no member was found.
Member? lookupLibraryMember(Library library, String memberName,
    {bool required = true}) {
  for (Member member in library.members) {
    if (getMemberName(member) == memberName) {
      return member;
    }
  }
  if (required) {
    throw new ArgumentError("Member '$memberName' not found in '$library'.");
  }
  return null;
}

/// Finds the first [Member] in [cls] with the given canonical simple
/// [memberName] as computed by [getMemberName].
///
/// If [required] is `true` an error is thrown if no member was found.
Member? lookupClassMember(Class cls, String memberName,
    {bool required = true}) {
  for (Member member in cls.members) {
    if (getMemberName(member) == memberName) {
      return member;
    }
  }
  if (required) {
    throw new ArgumentError("Member '$memberName' not found in '$cls'.");
  }
  return null;
}

LibraryBuilder? lookupLibraryBuilder(
    InternalCompilerResult compilerResult, Library library,
    {bool required = true}) {
  SourceLoader loader = compilerResult.kernelTargetForTesting!.loader;
  LibraryBuilder? builder =
      loader.lookupLoadedLibraryBuilder(library.importUri);
  if (builder == null && required) {
    throw new ArgumentError("DeclarationBuilder for $library not found.");
  }
  return builder;
}

ClassBuilder? lookupClassBuilder(
    InternalCompilerResult compilerResult, Class cls,
    {bool required = true}) {
  LibraryBuilder libraryBuilder = lookupLibraryBuilder(
      compilerResult, cls.enclosingLibrary,
      required: required)!;
  ClassBuilder? clsBuilder = libraryBuilder.libraryNameSpace
      .lookup(cls.name)
      ?.getable as ClassBuilder?;
  if (clsBuilder == null && required) {
    throw new ArgumentError("ClassBuilder for $cls not found.");
  }
  return clsBuilder;
}

ExtensionBuilder? lookupExtensionBuilder(
    InternalCompilerResult compilerResult, Extension extension,
    {bool required = true}) {
  LibraryBuilder libraryBuilder = lookupLibraryBuilder(
      compilerResult, extension.enclosingLibrary,
      required: required)!;
  ExtensionBuilder? extensionBuilder;
  libraryBuilder.libraryNameSpace
      .forEachLocalExtension((ExtensionBuilder builder) {
    if (builder.extension == extension) {
      extensionBuilder = builder;
    }
  });
  if (extensionBuilder == null && required) {
    throw new ArgumentError("ExtensionBuilder for $extension not found.");
  }
  return extensionBuilder;
}

ExtensionTypeDeclarationBuilder? lookupExtensionTypeDeclarationBuilder(
    InternalCompilerResult compilerResult,
    ExtensionTypeDeclaration extensionTypeDeclaration,
    {bool required = true}) {
  LibraryBuilder libraryBuilder = lookupLibraryBuilder(
      compilerResult, extensionTypeDeclaration.enclosingLibrary,
      required: required)!;
  ExtensionTypeDeclarationBuilder? extensionTypeDeclarationBuilder;
  Builder? builder = libraryBuilder.libraryNameSpace
      .lookup(extensionTypeDeclaration.name)
      ?.getable;
  if (builder is ExtensionTypeDeclarationBuilder &&
      builder.extensionTypeDeclaration == extensionTypeDeclaration) {
    extensionTypeDeclarationBuilder = builder;
  }
  if (extensionTypeDeclarationBuilder == null && required) {
    throw new ArgumentError(
        "ExtensionTypeDeclarationBuilder for $extensionTypeDeclaration "
        "not found.");
  }
  return extensionTypeDeclarationBuilder;
}

/// Look up the [MemberBuilder] for [member] through the [ClassBuilder] for
/// [cls] using [memberName] as its name.
MemberBuilder? lookupClassMemberBuilder(InternalCompilerResult compilerResult,
    Class cls, Member member, String memberName,
    {bool required = true}) {
  ClassBuilder? classBuilder =
      lookupClassBuilder(compilerResult, cls, required: required);
  MemberBuilder? memberBuilder;
  if (classBuilder != null) {
    if (member is Constructor || member is Procedure && member.isFactory) {
      memberBuilder =
          classBuilder.nameSpace.lookupConstructor(memberName)?.getable;
    } else {
      bool isSetter = member is Procedure && member.isSetter;
      LookupResult? result = classBuilder.nameSpace.lookup(memberName);
      memberBuilder =
          (isSetter ? result?.setable : result?.getable) as MemberBuilder?;
    }
  }
  if (memberBuilder == null && required) {
    throw new ArgumentError("MemberBuilder for $member not found.");
  }
  return memberBuilder;
}

MemberBuilder? lookupMemberBuilder(
    InternalCompilerResult compilerResult, Member member,
    {bool required = true}) {
  MemberBuilder? memberBuilder;
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
    Extension extension = lookupExtension(
        member.enclosingLibrary, extensionName,
        required: true)!;
    memberBuilder = lookupExtensionMemberBuilder(
        compilerResult, extension, member, memberName,
        isSetter: isSetter, required: required);
  } else if (member.isExtensionTypeMember) {
    String memberName = member.name.text;
    String extensionTypeName = memberName.substring(0, memberName.indexOf('|'));
    memberName = memberName.substring(extensionTypeName.length + 1);
    bool isConstructor = false;
    bool isSetter = member is Procedure && member.isSetter;
    if (memberName.startsWith('set#')) {
      memberName = memberName.substring(4);
      isSetter = true;
    } else if (memberName.startsWith('get#')) {
      memberName = memberName.substring(4);
    } else if (memberName.startsWith('constructor#')) {
      memberName = memberName.substring(12);
      isConstructor = true;
    }
    ExtensionTypeDeclaration extensionType = lookupExtensionTypeDeclaration(
        member.enclosingLibrary, extensionTypeName,
        required: true)!;
    memberBuilder = lookupExtensionTypeMemberBuilder(
        compilerResult, extensionType, member, memberName,
        isConstructor: isConstructor, isSetter: isSetter, required: required);
  } else if (member.enclosingClass != null) {
    memberBuilder = lookupClassMemberBuilder(
        compilerResult, member.enclosingClass!, member, member.name.text,
        required: required);
  } else {
    LibraryBuilder libraryBuilder = lookupLibraryBuilder(
        compilerResult, member.enclosingLibrary,
        required: required)!;
    bool isSetter = member is Procedure && member.isSetter;
    LookupResult? result =
        libraryBuilder.libraryNameSpace.lookup(member.name.text);
    memberBuilder =
        (isSetter ? result?.setable : result?.getable) as MemberBuilder?;
  }
  if (memberBuilder == null && required) {
    throw new ArgumentError("MemberBuilder for $member not found.");
  }
  return memberBuilder;
}

/// Look up the [MemberBuilder] for [member] through the [ExtensionBuilder] for
/// [extension] using [memberName] as its name.
MemberBuilder? lookupExtensionMemberBuilder(
    InternalCompilerResult compilerResult,
    Extension extension,
    Member member,
    String memberName,
    {bool isSetter = false,
    bool required = true}) {
  ExtensionBuilder? extensionBuilder =
      lookupExtensionBuilder(compilerResult, extension, required: required);
  MemberBuilder? memberBuilder;
  if (extensionBuilder != null) {
    bool isSetter = member is Procedure && member.isSetter;
    LookupResult? result = extensionBuilder.nameSpace.lookup(memberName);
    memberBuilder =
        (isSetter ? result?.setable : result?.getable) as MemberBuilder?;
  }
  if (memberBuilder == null && required) {
    throw new ArgumentError("MemberBuilder for $member not found.");
  }
  return memberBuilder;
}

/// Look up the [MemberBuilder] for [member] through the [ExtensionBuilder] for
/// [extensionType] using [memberName] as its name.
MemberBuilder? lookupExtensionTypeMemberBuilder(
    InternalCompilerResult compilerResult,
    ExtensionTypeDeclaration extensionType,
    Member member,
    String memberName,
    {bool isConstructor = false,
    bool isSetter = false,
    bool required = true}) {
  ExtensionTypeDeclarationBuilder? extensionTypeBuilder =
      lookupExtensionTypeDeclarationBuilder(compilerResult, extensionType,
          required: required);
  MemberBuilder? memberBuilder;
  if (extensionTypeBuilder != null) {
    if (isConstructor) {
      memberBuilder =
          extensionTypeBuilder.nameSpace.lookupConstructor(memberName)?.getable;
    } else {
      bool isSetter = member is Procedure && member.isSetter;
      LookupResult? result = extensionTypeBuilder.nameSpace.lookup(memberName);
      memberBuilder =
          (isSetter ? result?.setable : result?.getable) as MemberBuilder?;
    }
  }
  if (memberBuilder == null && required) {
    throw new ArgumentError("MemberBuilder for $member not found.");
  }
  return memberBuilder;
}

/// Returns a textual representation of the constant [node] to be used in
/// testing.
String constantToText(Constant node,
    {TypeRepresentation typeRepresentation = TypeRepresentation.legacy}) {
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
      _getAllSuperclasses(node.supertype!.classNode, set);
    }
    if (node.mixedInType != null) {
      _getAllSuperclasses(node.mixedInType!.classNode, set);
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

  @override
  void visitNullConstant(NullConstant node) {
    sb.write('Null()');
  }

  @override
  void visitBoolConstant(BoolConstant node) {
    sb.write('Bool(${node.value})');
  }

  @override
  void visitIntConstant(IntConstant node) {
    sb.write('Int(${node.value})');
  }

  @override
  void visitDoubleConstant(DoubleConstant node) {
    sb.write('Double(${node.value})');
  }

  @override
  void visitStringConstant(StringConstant node) {
    sb.write('String(${node.value})');
  }

  @override
  void visitSymbolConstant(SymbolConstant node) {
    sb.write('Symbol(${node.name})');
  }

  @override
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

  @override
  void visitListConstant(ListConstant node) {
    sb.write('List<');
    typeToText.visit(node.typeArgument);
    sb.write('>(');
    visitList(node.entries);
    sb.write(')');
  }

  @override
  void visitSetConstant(SetConstant node) {
    sb.write('Set<');
    typeToText.visit(node.typeArgument);
    sb.write('>(');
    visitList(node.entries);
    sb.write(')');
  }

  @override
  void visitRecordConstant(RecordConstant node) {
    sb.write('Record(');
    String comma = '';
    for (Constant field in node.positional) {
      sb.write(comma);
      field.accept(this);
      comma = ',';
    }
    if (node.named.isNotEmpty) {
      sb.write(comma);
      sb.write('{');
      comma = '';
      for (MapEntry<String, Constant> entry in node.named.entries) {
        sb.write(comma);
        sb.write('${entry.key}:');
        entry.value.accept(this);
        comma = ',';
      }
      sb.write('}');
    }
    sb.write(')');
  }

  @override
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
      for (MapEntry<Reference, Constant> entry in node.fieldValues.entries) {
        sb.write(comma);
        sb.write(getMemberName(entry.key.asField));
        sb.write(':');
        visit(entry.value);
        comma = ',';
      }
      sb.write('}');
    }
    sb.write(')');
  }

  @override
  void visitInstantiationConstant(InstantiationConstant node) {
    sb.write('Instantiation(');
    Constant tearOffConstant = node.tearOffConstant;
    if (tearOffConstant is TearOffConstant) {
      sb.write(getMemberName(tearOffConstant.target));
    } else {
      visit(tearOffConstant);
    }
    sb.write('<');
    typeToText.visitList(node.types);
    sb.write('>)');
  }

  @override
  void visitTypedefTearOffConstant(TypedefTearOffConstant node) {
    sb.write('TypedefTearOff(');
    sb.write(getMemberName(node.tearOffConstant.target));
    if (node.parameters.isNotEmpty) {
      sb.write('<');
      for (int i = 0; i < node.parameters.length; i++) {
        if (i > 0) {
          sb.write(',');
          if (typeToText.typeRepresentation ==
              TypeRepresentation.analyzerNonNullableByDefault) {
            sb.write(' ');
          }
        }
        StructuralParameter structuralParameter = node.parameters[i];
        sb.write(structuralParameter.name);
        DartType bound = structuralParameter.bound;
        if (!(bound is InterfaceType && bound.classNode.name == 'Object')) {
          sb.write(' extends ');
          typeToText.visit(bound);
        }
      }
      sb.write('>');
    }
    sb.write('<');
    typeToText.visitList(node.types);
    sb.write('>)');
  }

  @override
  void visitStaticTearOffConstant(StaticTearOffConstant node) {
    sb.write('Function(');
    sb.write(getMemberName(node.target));
    sb.write(')');
  }

  @override
  void visitConstructorTearOffConstant(ConstructorTearOffConstant node) {
    sb.write('Constructor(');
    sb.write(getMemberName(node.target));
    sb.write(')');
  }

  @override
  void visitRedirectingFactoryTearOffConstant(
      RedirectingFactoryTearOffConstant node) {
    sb.write('RedirectingFactory(');
    sb.write(getMemberName(node.target));
    sb.write(')');
  }

  @override
  void visitTypeLiteralConstant(TypeLiteralConstant node) {
    sb.write('TypeLiteral(');
    typeToText.visit(node.type);
    sb.write(')');
  }

  @override
  void visitUnevaluatedConstant(UnevaluatedConstant node) {
    sb.write('Unevaluated()');
  }

  @override
  bool visitAuxiliaryConstant(AuxiliaryConstant node) {
    throw new UnsupportedError(
        "Unsupported auxiliary constant ${node} (${node.runtimeType}).");
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

  @override
  void visitAuxiliaryType(AuxiliaryType node) {
    throw new UnsupportedError(
        "Unsupported auxiliary type ${node} (${node.runtimeType}).");
  }

  @override
  void visitInvalidType(InvalidType node) {
    sb.write('<invalid>');
  }

  @override
  void visitDynamicType(DynamicType node) {
    sb.write('dynamic');
  }

  @override
  void visitVoidType(VoidType node) {
    sb.write('void');
  }

  @override
  void visitNeverType(NeverType node) {
    sb.write('Never');
    if (node.nullability != Nullability.nonNullable) {
      sb.write(nullabilityToText(node.nullability, typeRepresentation));
    }
  }

  @override
  void visitNullType(NullType node) {
    sb.write('Null');
  }

  @override
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

  @override
  void visitFutureOrType(FutureOrType node) {
    sb.write('FutureOr<');
    visit(node.typeArgument);
    sb.write('>');
    sb.write(nullabilityToText(node.declaredNullability, typeRepresentation));
  }

  @override
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
        StructuralParameter typeParameter = node.typeParameters[i];
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

  @override
  void visitRecordType(RecordType node) {
    sb.write('(');
    String comma = '';
    visitList(node.positional);
    if (node.positional.isNotEmpty) {
      comma = commaText;
    }
    if (node.named.isNotEmpty) {
      sb.write(comma);
      sb.write('{');
      comma = '';
      for (NamedType namedType in node.named) {
        sb.write(comma);
        if (namedType.isRequired) {
          sb.write('required ');
        }
        visit(namedType.type);
        sb.write(' ');
        sb.write(namedType.name);
        comma = commaText;
      }
      sb.write('}');
    }
    sb.write(')');
    sb.write(nullabilityToText(node.nullability, typeRepresentation));
  }

  @override
  void visitTypeParameterType(TypeParameterType node) {
    sb.write(node.parameter.name);
    sb.write(nullabilityToText(node.nullability, typeRepresentation));
  }

  @override
  void visitStructuralParameterType(StructuralParameterType node) {
    sb.write(node.parameter.name);
    sb.write(nullabilityToText(node.nullability, typeRepresentation));
  }

  @override
  void visitIntersectionType(IntersectionType node) {
    visit(node.left);
    sb.write(' & ');
    visit(node.right);
  }

  @override
  void visitTypedefType(TypedefType node) {
    sb.write(node.typedefNode.name);
    if (node.typeArguments.isNotEmpty) {
      sb.write('<');
      visitList(node.typeArguments);
      sb.write('>');
    }
    sb.write(nullabilityToText(node.nullability, typeRepresentation));
  }

  @override
  void visitExtensionType(ExtensionType node) {
    sb.write(node.extensionTypeDeclaration.name);
    if (node.typeArguments.isNotEmpty) {
      sb.write('<');
      visitList(node.typeArguments);
      sb.write('>');
    }
    sb.write(nullabilityToText(node.declaredNullability, typeRepresentation));
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
  String name = typeParameter.name!;
  if (!isObject(typeParameter.bound)) {
    return '$name extends ${typeToText(typeParameter.bound)}';
  }
  return name;
}

/// Returns a textual representation of the [type] to be used in testing.
String typeBuilderToText(TypeBuilder type) {
  StringBuffer sb = new StringBuffer();
  type.printOn(sb);
  return sb.toString();
}

/// Returns a textual representation of the [typeParameter] to be used in
/// testing.
String typeVariableBuilderToText(NominalParameterBuilder typeParameter) {
  String name = typeParameter.name;
  if (typeParameter.bound != null) {
    return '$name extends ${typeBuilderToText(typeParameter.bound!)}';
  }
  return name;
}

/// Returns a textual representation of [errors] to be used in testing.
String errorsToText(List<FormattedMessage> errors, {bool useCodes = false}) {
  if (useCodes) {
    return errors.map((m) => m.code).join(',');
  } else {
    return errors.map((m) => m.problemMessage).join(',');
  }
}

/// Returns a textual representation of [descriptor] to be used in testing.
List<String> extensionMethodDescriptorToText(
    ExtensionMemberDescriptor descriptor) {
  String descriptorToText(Reference reference, {required bool forTearOff}) {
    StringBuffer sb = new StringBuffer();
    if (descriptor.isStatic) {
      sb.write('static ');
    }
    switch (descriptor.kind) {
      case ExtensionMemberKind.Method:
        if (forTearOff) {
          sb.write('tearoff ');
        }
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
    }
    sb.write(descriptor.name.text);
    sb.write('=');
    Member member = reference.asMember;
    String name = member.name.text;
    if (member is Procedure && member.isSetter) {
      sb.write('$name=');
    } else {
      sb.write(name);
    }
    return sb.toString();
  }

  return [
    if (descriptor.memberReference != null)
      descriptorToText(descriptor.memberReference!, forTearOff: false),
    if (descriptor.tearOffReference != null)
      descriptorToText(descriptor.tearOffReference!, forTearOff: true),
  ];
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
    case Nullability.nullable:
      return '?';
    case Nullability.undetermined:
      switch (typeRepresentation) {
        case TypeRepresentation.analyzerNonNullableByDefault:
          return '';
        default:
          return '%';
      }
  }
}
