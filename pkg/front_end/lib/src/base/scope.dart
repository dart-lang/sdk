// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/type_environment.dart';

import '../builder/builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/name_iterator.dart';
import '../builder/prefix_builder.dart';
import '../kernel/hierarchy/class_member.dart' show ClassMember;
import '../kernel/kernel_helper.dart';
import '../kernel/load_library_builder.dart';
import '../kernel/type_algorithms.dart';
import '../source/source_class_builder.dart';
import '../source/source_extension_builder.dart';
import '../source/source_library_builder.dart';
import '../source/source_member_builder.dart';
import 'messages.dart';
import 'name_space.dart';
import 'uri_offset.dart';

enum ScopeKind {
  /// Scope of pattern switch-case statements
  ///
  /// These scopes receive special treatment in that they are end-points of the
  /// scope stack in presence of multiple heads for the same case, but can have
  /// nested scopes if it's just a single head. In that latter possibility the
  /// body of the case is nested into the scope of the case head. And for switch
  /// expressions that scope includes both the head and the case expression.
  caseHead,

  /// The declaration-level scope for classes, enums, and similar declarations
  declaration,

  /// Scope where the formal parameters of a function are declared
  formals,

  /// Scope of a `for` statement
  forStatement,

  /// Scope of a function body
  functionBody,

  /// Scope of the head of the if-case statement
  ifCaseHead,

  /// Scope of an if-element in a collection
  ifElement,

  /// Scope for the initializers of generative constructors
  initializers,

  /// Scope where the joint variables of a switch case are declared
  jointVariables,

  /// Scope where labels of labelled statements are declared
  labels,

  /// Top-level scope of a library
  library,

  /// The special scope of the named function expression
  ///
  /// This scope is treated separately because the named function expressions
  /// are allowed to be recursive, and the name of that function expression
  /// should be visible in the scope of the function itself.
  namedFunctionExpression,

  /// The scope of the RHS of a binary-or pattern
  ///
  /// It is utilized for separating the branch-local variables from the joint
  /// variables of the overall binary-or pattern.
  orPatternRight,

  /// The scope of a pattern
  ///
  /// It contains the variables associated with pattern variable declarations.
  pattern,

  /// Local scope of a statement, such as the body of a while loop
  statementLocalScope,

  /// Local scope of a switch block
  switchBlock,

  /// Scope for switch cases
  ///
  /// This scope kind is used in assertion checks.
  switchCase,

  /// Scope for switch case bodies
  ///
  /// This is used to handle local variables of switch cases.
  switchCaseBody,

  /// Scope for type parameters of declarations
  typeParameters,

  /// Scope for a compilation unit.
  ///
  /// This contains the entities declared in the library to which the
  /// compilation unit belongs. Its parent scopes are the [prefix] and [import]
  /// scopes of the compilation unit.
  compilationUnit,

  /// Scope for the prefixed imports in a compilation unit.
  ///
  /// The parent scope is the [import] scope of the same compilation unit.
  prefix,

  /// Scope for the non-prefixed imports in a compilation unit.
  ///
  /// The parent scope is the [prefix] scope of the parent compilation unit,
  /// if any.
  import,
}

abstract class LookupScope {
  ScopeKind get kind;
  Builder? lookupGetable(String name, int charOffset, Uri fileUri);
  Builder? lookupSetable(String name, int charOffset, Uri fileUri);
  // TODO(johnniwinther): Should this be moved to an outer scope interface?
  void forEachExtension(void Function(ExtensionBuilder) f);
}

/// Returns the correct value of the [getable] and [setable] found as a lookup
/// of [name].
///
/// If [isSetter] is `true`, the lookup intends to find a setable. Otherwise it
/// intends to find a getable.
///
/// This ensures that an [AmbiguousBuilder] is returned if the found builder is
/// a duplicate.
///
/// If [forStaticAccess] is `true`, `null` is returned if the found builder is
/// an instance member.
Builder? normalizeLookup(
    {required Builder? getable,
    required Builder? setable,
    required String name,
    required int charOffset,
    required Uri fileUri,
    required String classNameOrDebugName,
    required bool isSetter,
    bool forStaticAccess = false}) {
  if (getable == null && setable == null) {
    return null;
  }
  Builder? thisBuilder;
  Builder? otherBuilder;
  if (isSetter) {
    thisBuilder = setable;
    otherBuilder = getable;
  } else {
    thisBuilder = getable;
    otherBuilder = setable;
  }
  Builder? builder = _normalizeBuilderLookup(thisBuilder,
      name: name,
      charOffset: charOffset,
      fileUri: fileUri,
      classNameOrDebugName: classNameOrDebugName,
      forStaticAccess: forStaticAccess);
  if (builder != null) {
    return builder;
  }
  builder = _normalizeCrossLookup(
      _normalizeBuilderLookup(otherBuilder,
          name: name,
          charOffset: charOffset,
          fileUri: fileUri,
          classNameOrDebugName: classNameOrDebugName,
          forStaticAccess: forStaticAccess),
      name: name,
      charOffset: charOffset,
      fileUri: fileUri);
  return builder;
}

/// Returns the correct value of [builder] found as a lookup of [name].
///
/// This ensures that an [AmbiguousBuilder] is returned if the found builder is
/// a duplicate.
///
/// If [forStaticAccess] is `true`, `null` is returned if the found builder is
/// an instance member.
Builder? _normalizeBuilderLookup(Builder? builder,
    {required String name,
    required int charOffset,
    required Uri fileUri,
    required String classNameOrDebugName,
    required bool forStaticAccess}) {
  if (builder == null) return null;
  if (builder.next != null) {
    return new AmbiguousBuilder(name.isEmpty ? classNameOrDebugName : name,
        builder, charOffset, fileUri);
  } else if (forStaticAccess && builder.isDeclarationInstanceMember) {
    return null;
  } else if (builder is MemberBuilder && builder.isConflictingSetter) {
    // TODO(johnniwinther): Use a variant of [AmbiguousBuilder] for this case.
    return null;
  } else {
    return builder;
  }
}

/// Returns the correct value of [builder] found as a lookup of [name] where
/// [builder] is found as a setable in search of a getable or as a getable in
/// search of a setable.
///
/// This ensures that an [AccessErrorBuilder] is returned if a non-problem
/// builder was found.
Builder? _normalizeCrossLookup(Builder? builder,
    {required String name, required int charOffset, required Uri fileUri}) {
  if (builder != null && !builder.hasProblem) {
    return new AccessErrorBuilder(name, builder, charOffset, fileUri);
  }
  return builder;
}

mixin LookupScopeMixin implements LookupScope {
  String get classNameOrDebugName;

  Builder? lookupGetableIn(
      String name, int charOffset, Uri fileUri, Map<String, Builder> getables) {
    Builder? getable = getables[name];
    if (getable == null) {
      return null;
    }
    return normalizeLookup(
        getable: getable,
        setable: null,
        name: name,
        charOffset: charOffset,
        fileUri: fileUri,
        classNameOrDebugName: classNameOrDebugName,
        isSetter: false);
  }

  Builder? lookupSetableIn(String name, int charOffset, Uri fileUri,
      Map<String, Builder>? getables) {
    Builder? getable = getables?[name];
    if (getable == null) {
      return null;
    }
    // Coverage-ignore(suite): Not run.
    return normalizeLookup(
        getable: getable,
        setable: null,
        name: name,
        charOffset: charOffset,
        fileUri: fileUri,
        classNameOrDebugName: classNameOrDebugName,
        isSetter: true);
  }

  @override
  String toString() => "$runtimeType(${kind},$classNameOrDebugName)";
}

/// A [LookupScope] based directly on a [NameSpace].
abstract class BaseNameSpaceLookupScope implements LookupScope {
  @override
  final ScopeKind kind;

  final String classNameOrDebugName;

  BaseNameSpaceLookupScope(this.kind, this.classNameOrDebugName);

  NameSpace get _nameSpace;

  LookupScope? get _parent;

  @override
  Builder? lookupGetable(String name, int charOffset, Uri fileUri) {
    Builder? getable = _nameSpace.lookupLocalMember(name, setter: false);
    Builder? setable = _nameSpace.lookupLocalMember(name, setter: true);
    Builder? builder;
    if (getable != null || setable != null) {
      builder = normalizeLookup(
          getable: getable,
          setable: setable,
          name: name,
          charOffset: charOffset,
          fileUri: fileUri,
          classNameOrDebugName: classNameOrDebugName,
          isSetter: false);
    }
    return builder ?? _parent?.lookupGetable(name, charOffset, fileUri);
  }

  @override
  Builder? lookupSetable(String name, int charOffset, Uri fileUri) {
    Builder? getable = _nameSpace.lookupLocalMember(name, setter: false);
    Builder? setable = _nameSpace.lookupLocalMember(name, setter: true);
    Builder? builder;
    if (getable != null || setable != null) {
      builder = normalizeLookup(
          getable: getable,
          setable: setable,
          name: name,
          charOffset: charOffset,
          fileUri: fileUri,
          classNameOrDebugName: classNameOrDebugName,
          isSetter: true);
    }
    return builder ?? _parent?.lookupSetable(name, charOffset, fileUri);
  }

  @override
  void forEachExtension(void Function(ExtensionBuilder) f) {
    _nameSpace.forEachLocalExtension(f);
    _parent?.forEachExtension(f);
  }

  @override
  String toString() => "$runtimeType(${kind},$classNameOrDebugName)";
}

class NameSpaceLookupScope extends BaseNameSpaceLookupScope {
  @override
  final NameSpace _nameSpace;

  @override
  final LookupScope? _parent;

  NameSpaceLookupScope(this._nameSpace, super.kind, super.classNameOrDebugName,
      {LookupScope? parent})
      : _parent = parent;
}

abstract class AbstractTypeParameterScope implements LookupScope {
  final LookupScope _parent;

  AbstractTypeParameterScope(this._parent);

  Builder? getTypeParameter(String name);

  @override
  // Coverage-ignore(suite): Not run.
  ScopeKind get kind => ScopeKind.typeParameters;

  @override
  Builder? lookupGetable(String name, int charOffset, Uri fileUri) {
    Builder? typeParameter = getTypeParameter(name);
    Builder? builder;
    if (typeParameter != null) {
      builder = normalizeLookup(
          getable: typeParameter,
          setable: null,
          name: name,
          charOffset: charOffset,
          fileUri: fileUri,
          classNameOrDebugName: classNameOrDebugName,
          isSetter: false);
    }
    return builder ?? _parent.lookupGetable(name, charOffset, fileUri);
  }

  @override
  Builder? lookupSetable(String name, int charOffset, Uri fileUri) {
    Builder? typeParameter = getTypeParameter(name);
    Builder? builder;
    if (typeParameter != null) {
      // Coverage-ignore-block(suite): Not run.
      builder = normalizeLookup(
          getable: typeParameter,
          setable: null,
          name: name,
          charOffset: charOffset,
          fileUri: fileUri,
          classNameOrDebugName: classNameOrDebugName,
          isSetter: true);
    }
    return builder ?? _parent.lookupSetable(name, charOffset, fileUri);
  }

  String get classNameOrDebugName => "type parameter";

  @override
  void forEachExtension(void Function(ExtensionBuilder) f) {
    _parent.forEachExtension(f);
  }

  @override
  String toString() => "$runtimeType(${kind},$classNameOrDebugName)";
}

class TypeParameterScope extends AbstractTypeParameterScope {
  final Map<String, Builder> _typeParameters;

  TypeParameterScope(super._parent, this._typeParameters);

  @override
  Builder? getTypeParameter(String name) => _typeParameters[name];

  static LookupScope fromList(
      LookupScope parent, List<TypeParameterBuilder>? typeParameterBuilders) {
    if (typeParameterBuilders == null) return parent;
    Map<String, Builder> map = {};
    for (TypeParameterBuilder typeParameterBuilder in typeParameterBuilders) {
      if (typeParameterBuilder.isWildcard) continue;
      map[typeParameterBuilder.name] = typeParameterBuilder;
    }
    return new TypeParameterScope(parent, map);
  }
}

// Coverage-ignore(suite): Not run.
class FixedLookupScope implements LookupScope {
  final LookupScope? _parent;
  @override
  final ScopeKind kind;
  final String classNameOrDebugName;
  final Map<String, Builder>? _getables;
  final Map<String, Builder>? _setables;

  FixedLookupScope(this.kind, this.classNameOrDebugName,
      {Map<String, Builder>? getables,
      Map<String, Builder>? setables,
      LookupScope? parent})
      : this._getables = getables,
        this._setables = setables,
        this._parent = parent;

  @override
  Builder? lookupGetable(String name, int charOffset, Uri fileUri) {
    Builder? getable = _getables?[name];
    Builder? setable = _setables?[name];
    Builder? builder;
    if (getable != null || setable != null) {
      builder = normalizeLookup(
          getable: getable,
          setable: setable,
          name: name,
          charOffset: charOffset,
          fileUri: fileUri,
          classNameOrDebugName: classNameOrDebugName,
          isSetter: false);
    }
    return builder ?? _parent?.lookupGetable(name, charOffset, fileUri);
  }

  @override
  Builder? lookupSetable(String name, int charOffset, Uri fileUri) {
    Builder? getable = _getables?[name];
    Builder? setable = _setables?[name];
    Builder? builder;
    if (getable != null || setable != null) {
      builder = normalizeLookup(
          getable: getable,
          setable: setable,
          name: name,
          charOffset: charOffset,
          fileUri: fileUri,
          classNameOrDebugName: classNameOrDebugName,
          isSetter: true);
    }
    return builder ?? _parent?.lookupSetable(name, charOffset, fileUri);
  }

  @override
  void forEachExtension(void Function(ExtensionBuilder) f) {
    _parent?.forEachExtension(f);
  }

  @override
  String toString() => "$runtimeType(${kind},$classNameOrDebugName)";
}

/// The import scope of a compilation unit.
///
/// This includes all declaration available through imports in this compilation
/// unit. Its parent scope is the prefix scope of the parent compilation unit.
/// If the compilation unit has no parent, the
/// [SourceLibraryBuilder.parentScope] is used as the parent. This is not a
/// normal Dart scope, but instead a synthesized scope used for expression
/// compilation.
class CompilationUnitImportScope extends BaseNameSpaceLookupScope {
  final SourceCompilationUnit _compilationUnit;
  final NameSpace _importNameSpace;

  CompilationUnitImportScope(this._compilationUnit, this._importNameSpace)
      : super(ScopeKind.import, 'import');

  @override
  NameSpace get _nameSpace => _importNameSpace;

  @override
  LookupScope? get _parent =>
      _compilationUnit.parentCompilationUnit?.prefixScope ??
      _compilationUnit.libraryBuilder.parentScope;
}

/// The scope of a compilation unit.
///
/// This is the enclosing scope for all declarations within the compilation
/// unit. It gives access to all declarations in the library the compilation
/// unit is part of. Its parent scope is the prefix scope, which contains all
/// imports with prefixes declared in this compilation unit. The grand parent
/// scope is the import scope of the compilation  unit implemented through
/// [CompilationUnitImportScope].
class CompilationUnitScope extends BaseNameSpaceLookupScope {
  final SourceCompilationUnit _compilationUnit;

  @override
  final LookupScope? _parent;

  CompilationUnitScope(
      this._compilationUnit, super.kind, super.classNameOrDebugName,
      {LookupScope? parent})
      : _parent = parent;

  @override
  NameSpace get _nameSpace => _compilationUnit.libraryBuilder.libraryNameSpace;

  /// Set of extension declarations in scope. This is computed lazily in
  /// [forEachExtension].
  Set<ExtensionBuilder>? _extensions;

  @override
  void forEachExtension(void Function(ExtensionBuilder) f) {
    if (_extensions == null) {
      Set<ExtensionBuilder> extensions = _extensions = <ExtensionBuilder>{};
      _parent?.forEachExtension(extensions.add);
      _nameSpace.forEachLocalExtension(extensions.add);
    }
    _extensions!.forEach(f);
  }
}

/// The scope containing the prefixes imported into a compilation unit.
class CompilationUnitPrefixScope extends BaseNameSpaceLookupScope {
  @override
  final NameSpace _nameSpace;

  @override
  final LookupScope? _parent;

  CompilationUnitPrefixScope(
      this._nameSpace, super.kind, super.classNameOrDebugName,
      {required LookupScope? parent})
      : _parent = parent;

  /// Set of extension declarations in scope. This is computed lazily in
  /// [forEachExtension].
  Set<ExtensionBuilder>? _extensions;

  @override
  void forEachExtension(void Function(ExtensionBuilder) f) {
    if (_extensions == null) {
      Set<ExtensionBuilder> extensions = _extensions = {};
      Iterator<PrefixBuilder> iterator = _nameSpace.filteredIterator(
          includeDuplicates: false, includeAugmentations: false);
      while (iterator.moveNext()) {
        iterator.current.forEachExtension((e) {
          extensions.add(e);
        });
      }
      _parent?.forEachExtension(extensions.add);
    }
    _extensions!.forEach(f);
  }
}

class DeclarationBuilderScope extends BaseNameSpaceLookupScope {
  DeclarationBuilder? _declarationBuilder;

  @override
  final LookupScope? _parent;

  DeclarationBuilderScope(this._parent)
      : super(ScopeKind.declaration, 'declaration');

  @override
  NameSpace get _nameSpace {
    assert(_declarationBuilder != null, "declarationBuilder has not been set.");
    return _declarationBuilder!.nameSpace;
  }

  void set declarationBuilder(DeclarationBuilder value) {
    assert(_declarationBuilder == null,
        "declarationBuilder has already been set.");
    _declarationBuilder = value;
  }
}

/// Computes a builder for the import collision between [declaration] and
/// [other].
Builder computeAmbiguousDeclarationForImport(ProblemReporting problemReporting,
    String name, Builder declaration, Builder other,
    {required UriOffset uriOffset}) {
  // Prefix fragments are merged to singular prefix builders when computing the
  // import scope.
  assert(!(declaration is PrefixBuilder && other is PrefixBuilder),
      "Unexpected prefix builders $declaration and $other.");

  // TODO(ahe): Can I move this to Scope or Prefix?
  if (declaration == other) return declaration;
  if (declaration is InvalidTypeDeclarationBuilder) return declaration;
  if (other is InvalidTypeDeclarationBuilder) return other;
  if (declaration is AccessErrorBuilder) {
    // Coverage-ignore-block(suite): Not run.
    AccessErrorBuilder error = declaration;
    declaration = error.builder;
  }
  if (other is AccessErrorBuilder) {
    // Coverage-ignore-block(suite): Not run.
    AccessErrorBuilder error = other;
    other = error.builder;
  }
  Builder? preferred;
  Uri uri = computeLibraryUri(declaration);
  Uri otherUri = computeLibraryUri(other);
  if (declaration is LoadLibraryBuilder) {
    preferred = declaration;
  } else if (other is LoadLibraryBuilder) {
    preferred = other;
  } else if (otherUri.isScheme("dart") && !uri.isScheme("dart")) {
    preferred = declaration;
  } else if (uri.isScheme("dart") && !otherUri.isScheme("dart")) {
    preferred = other;
  }
  if (preferred != null) {
    return preferred;
  }

  Uri firstUri = uri;
  Uri secondUri = otherUri;
  if (firstUri.toString().compareTo(secondUri.toString()) > 0) {
    firstUri = secondUri;
    secondUri = uri;
  }
  Message message = templateDuplicatedImport.withArguments(
      name,
      // TODO(ahe): We should probably use a context object here
      // instead of including URIs in this message.
      firstUri,
      secondUri);
  // We report the error lazily (setting suppressMessage to false) because the
  // spec 18.1 states that 'It is not an error if N is introduced by two or
  // more imports but never referred to.'
  return new InvalidTypeDeclarationBuilder(name,
      message.withLocation(uriOffset.uri, uriOffset.fileOffset, name.length),
      suppressMessage: false);
}

abstract class ProblemBuilder extends BuilderImpl {
  final String name;

  final Builder builder;

  @override
  final int fileOffset;

  @override
  final Uri fileUri;

  ProblemBuilder(this.name, this.builder, this.fileOffset, this.fileUri);

  @override
  bool get hasProblem => true;

  Message get message;

  @override
  String get fullNameForErrors => name;
}

/// Represents a [builder] that's being accessed incorrectly. For example, an
/// attempt to write to a final field, or to read from a setter.
class AccessErrorBuilder extends ProblemBuilder {
  AccessErrorBuilder(String name, Builder builder, int charOffset, Uri fileUri)
      : super(name, builder, charOffset, fileUri);

  @override
  Builder? get parent => builder.parent;

  @override
  bool get isField => builder.isField;

  @override
  bool get isRegularMethod => builder.isRegularMethod;

  @override
  bool get isGetter => !builder.isGetter;

  @override
  bool get isSetter => !builder.isSetter;

  @override
  bool get isDeclarationInstanceMember => builder.isDeclarationInstanceMember;

  @override
  bool get isClassInstanceMember => builder.isClassInstanceMember;

  @override
  bool get isExtensionInstanceMember => builder.isExtensionInstanceMember;

  @override
  bool get isExtensionTypeInstanceMember =>
      builder.isExtensionTypeInstanceMember;

  @override
  bool get isStatic => builder.isStatic;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isTopLevel => builder.isTopLevel;

  @override
  bool get isTypeDeclaration => builder.isTypeDeclaration;

  @override
  bool get isLocal => builder.isLocal;

  @override
  // Coverage-ignore(suite): Not run.
  Message get message => templateAccessError.withArguments(name);
}

class AmbiguousBuilder extends ProblemBuilder {
  AmbiguousBuilder(String name, Builder builder, int charOffset, Uri fileUri)
      : super(name, builder, charOffset, fileUri);

  @override
  // Coverage-ignore(suite): Not run.
  Builder? get parent => null;

  @override
  Message get message => templateDuplicatedDeclarationUse.withArguments(name);

  // Coverage-ignore(suite): Not run.
  // TODO(ahe): Also provide context.

  Builder getFirstDeclaration() {
    Builder declaration = builder;
    while (declaration.next != null) {
      declaration = declaration.next!;
    }
    return declaration;
  }
}

mixin ErroneousMemberBuilderMixin implements SourceMemberBuilder {
  @override
  // Coverage-ignore(suite): Not run.
  MemberDataForTesting? get dataForTesting => null;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<MetadataBuilder>? get metadataForTesting => null;

  @override
  // Coverage-ignore(suite): Not run.
  Name get memberName => throw new UnsupportedError('$runtimeType.memberName');

  @override
  // Coverage-ignore(suite): Not run.
  Member? get readTarget => null;

  @override
  // Coverage-ignore(suite): Not run.
  Reference? get readTargetReference => null;

  @override
  // Coverage-ignore(suite): Not run.
  Member? get writeTarget => null;

  @override
  // Coverage-ignore(suite): Not run.
  Reference? get writeTargetReference => null;

  @override
  // Coverage-ignore(suite): Not run.
  Member? get invokeTarget => null;

  @override
  // Coverage-ignore(suite): Not run.
  Reference? get invokeTargetReference => null;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Reference> get exportedMemberReferences => const [];

  @override
  // Coverage-ignore(suite): Not run.
  bool get isProperty => throw new UnsupportedError("$runtimeType.isProperty");

  @override
  // Coverage-ignore(suite): Not run.
  bool get isAssignable => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isExternal => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isAbstract => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isFinal => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isSynthesized => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isEnumElement => false;

  @override
  bool get isConflictingSetter => false;

  @override
  bool get isConflictingAugmentationMember => false;

  @override
  void set isConflictingAugmentationMember(bool value) {
    throw new UnsupportedError('$runtimeType.isConflictingAugmentationMember=');
  }

  @override
  DeclarationBuilder get declarationBuilder {
    throw new UnsupportedError('$runtimeType.declarationBuilder');
  }

  @override
  ClassBuilder get classBuilder {
    throw new UnsupportedError('$runtimeType.classBuilder');
  }

  @override
  SourceLibraryBuilder get libraryBuilder {
    throw new UnsupportedError('$runtimeType.library');
  }

  @override
  void buildOutlineExpressions(ClassHierarchy classHierarchy,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    throw new UnsupportedError('$runtimeType.buildOutlineExpressions');
  }

  @override
  // Coverage-ignore(suite): Not run.
  void buildOutlineNodes(BuildNodesCallback f) {
    assert(false, "Unexpected call to $runtimeType.buildOutlineNodes.");
  }

  @override
  // Coverage-ignore(suite): Not run.
  int buildBodyNodes(BuildNodesCallback f) {
    assert(false, "Unexpected call to $runtimeType.buildBodyNodes.");
    return 0;
  }

  @override
  // Coverage-ignore(suite): Not run.
  int computeDefaultTypes(ComputeDefaultTypeContext context,
      {required bool inErrorRecovery}) {
    assert(false, "Unexpected call to $runtimeType.computeDefaultTypes.");
    return 0;
  }

  @override
  // Coverage-ignore(suite): Not run.
  List<ClassMember> get localMembers => const <ClassMember>[];

  @override
  // Coverage-ignore(suite): Not run.
  List<ClassMember> get localSetters => const <ClassMember>[];

  @override
  // Coverage-ignore(suite): Not run.
  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment) {
    assert(false, "Unexpected call to $runtimeType.checkVariance.");
  }

  @override
  // Coverage-ignore(suite): Not run.
  void checkTypes(SourceLibraryBuilder library, NameSpace nameSpace,
      TypeEnvironment typeEnvironment) {
    assert(false, "Unexpected call to $runtimeType.checkVariance.");
  }

  @override
  bool get isAugmentation {
    throw new UnsupportedError('$runtimeType.isAugmentation');
  }

  @override
  AugmentSuperTarget? get augmentSuperTarget {
    throw new UnsupportedError('$runtimeType.augmentSuperTarget}');
  }

  @override
  Iterable<Annotatable> get annotatables {
    throw new UnsupportedError('$runtimeType.annotatables}');
  }
}

class AmbiguousMemberBuilder extends AmbiguousBuilder
    with ErroneousMemberBuilderMixin {
  AmbiguousMemberBuilder(
      String name, Builder builder, int charOffset, Uri fileUri)
      : super(name, builder, charOffset, fileUri);
}

/// Iterator over builders mapped in a [Scope], including duplicates for each
/// directly mapped builder.
class ScopeIterator implements Iterator<Builder> {
  Iterator<Builder>? local;
  Iterator<Builder>? setters;
  Iterator<Builder>? extensions;

  Builder? _current;

  ScopeIterator(this.local, this.setters, this.extensions);

  @override
  bool moveNext() {
    Builder? next = _current?.next;
    if (next != null) {
      _current = next;
      return true;
    }
    if (local != null) {
      if (local!.moveNext()) {
        _current = local!.current;
        return true;
      }
      local = null;
    }
    if (setters != null) {
      if (setters!.moveNext()) {
        _current = setters!.current;
        return true;
      }
      setters = null;
    }
    if (extensions != null) {
      while (extensions!.moveNext()) {
        Builder extension = extensions!.current;
        // Named extensions have already been included throw [local] so we skip
        // them here.
        if (extension is SourceExtensionBuilder &&
            extension.isUnnamedExtension) {
          _current = extension;
          return true;
        }
      }
      extensions = null;
    }
    _current = null;
    return false;
  }

  @override
  Builder get current {
    return _current ?? // Coverage-ignore(suite): Not run.
        (throw new StateError('No element'));
  }
}

/// Iterator over builders mapped in a [Scope], including duplicates for each
/// directly mapped builder.
///
/// Compared to [ScopeIterator] this iterator also gives
/// access to the name that the builders are mapped to.
class ScopeNameIterator extends ScopeIterator implements NameIterator<Builder> {
  Iterator<String>? localNames;
  Iterator<String>? setterNames;

  String? _name;

  ScopeNameIterator(Map<String, Builder>? getables,
      Map<String, Builder>? setables, Iterator<Builder>? extensions)
      : localNames = getables?.keys.iterator,
        setterNames = setables?.keys.iterator,
        super(getables?.values.iterator, setables?.values.iterator, extensions);

  @override
  bool moveNext() {
    Builder? next = _current?.next;
    if (next != null) {
      _current = next;
      return true;
    }
    if (local != null) {
      if (local!.moveNext()) {
        localNames!.moveNext();
        _current = local!.current;
        _name = localNames!.current;
        return true;
      }
      local = null;
      localNames = null;
    }
    if (setters != null) {
      if (setters!.moveNext()) {
        setterNames!.moveNext();
        _current = setters!.current;
        _name = setterNames!.current;
        return true;
      }
      setters = null;
      setterNames = null;
    }
    if (extensions != null) {
      while (extensions!.moveNext()) {
        Builder extension = extensions!.current;
        // Named extensions have already been included throw [local] so we skip
        // them here.
        if (extension is SourceExtensionBuilder &&
            extension.isUnnamedExtension) {
          _current = extension;
          _name = extension.name;
          return true;
        }
      }
      extensions = null;
    }
    _current = null;
    _name = null;
    return false;
  }

  @override
  String get name {
    return _name ?? // Coverage-ignore(suite): Not run.
        (throw new StateError('No element'));
  }
}

/// Iterator over builders mapped in a [ConstructorNameSpace], including
/// duplicates for each directly mapped builder.
class ConstructorNameSpaceIterator implements Iterator<MemberBuilder> {
  Iterator<MemberBuilder>? _local;

  MemberBuilder? _current;

  ConstructorNameSpaceIterator(this._local);

  @override
  bool moveNext() {
    MemberBuilder? next = _current?.next as MemberBuilder?;
    if (next != null) {
      _current = next;
      return true;
    }
    if (_local != null) {
      if (_local!.moveNext()) {
        _current = _local!.current;
        return true;
      }
      _local = null;
    }
    return false;
  }

  @override
  MemberBuilder get current {
    return _current ?? // Coverage-ignore(suite): Not run.
        (throw new StateError('No element'));
  }
}

/// Iterator over builders mapped in a [ConstructorNameSpace], including
/// duplicates for each directly mapped builder.
///
/// Compared to [ConstructorNameSpaceIterator] this iterator also gives
/// access to the name that the builders are mapped to.
class ConstructorNameSpaceNameIterator extends ConstructorNameSpaceIterator
    implements NameIterator<MemberBuilder> {
  Iterator<String>? _localNames;

  String? _name;

  ConstructorNameSpaceNameIterator(this._localNames, super.local);

  @override
  bool moveNext() {
    MemberBuilder? next = _current?.next as MemberBuilder?;
    if (next != null) {
      _current = next;
      return true;
    }
    if (_local != null) {
      if (_local!.moveNext()) {
        _localNames!.moveNext();
        _current = _local!.current;
        _name = _localNames!.current;
        return true;
      }
      _local = null;
      _localNames = null;
    }
    _current = null;
    _name = null;
    return false;
  }

  @override
  String get name {
    return _name ?? // Coverage-ignore(suite): Not run.
        (throw new StateError('No element'));
  }
}

/// Filtered builder [Iterator].
class FilteredIterator<T extends Builder> implements Iterator<T> {
  final Iterator<Builder> _iterator;
  final Builder? parent;
  final bool includeDuplicates;
  final bool includeAugmentations;

  FilteredIterator(this._iterator,
      {required this.parent,
      required this.includeDuplicates,
      required this.includeAugmentations});

  bool _include(Builder element) {
    if (parent != null && element.parent != parent) return false;
    if (!includeDuplicates &&
        (element.isDuplicate || element.isConflictingAugmentationMember)) {
      return false;
    }
    if (!includeAugmentations && element.isAugmenting) return false;
    return element is T;
  }

  @override
  T get current => _iterator.current as T;

  @override
  bool moveNext() {
    while (_iterator.moveNext()) {
      Builder candidate = _iterator.current;
      if (_include(candidate)) {
        return true;
      }
    }
    return false;
  }
}

/// Filtered [NameIterator].
///
/// Compared to [FilteredIterator] this iterator also gives
/// access to the name that the builders are mapped to.
class FilteredNameIterator<T extends Builder> implements NameIterator<T> {
  final NameIterator<Builder> _iterator;
  final Builder? parent;
  final bool includeDuplicates;
  final bool includeAugmentations;

  FilteredNameIterator(this._iterator,
      {required this.parent,
      required this.includeDuplicates,
      required this.includeAugmentations});

  bool _include(Builder element) {
    if (parent != null && element.parent != parent) return false;
    if (!includeDuplicates &&
        (element.isDuplicate || element.isConflictingAugmentationMember)) {
      return false;
    }
    if (!includeAugmentations && element.isAugmenting) return false;
    return element is T;
  }

  @override
  T get current => _iterator.current as T;

  @override
  String get name => _iterator.name;

  @override
  bool moveNext() {
    while (_iterator.moveNext()) {
      Builder candidate = _iterator.current;
      if (_include(candidate)) {
        return true;
      }
    }
    return false;
  }
}

extension IteratorExtension<T extends Builder> on Iterator<T> {
  void forEach(void Function(T) f) {
    while (moveNext()) {
      f(current);
    }
  }

  List<T> toList() {
    List<T> list = [];
    while (moveNext()) {
      list.add(current);
    }
    return list;
  }

  Iterator<T> join(Iterator<T> other) {
    return new IteratorSequence<T>([this, other]);
  }
}

extension NameIteratorExtension<T extends Builder> on NameIterator<T> {
  void forEach(void Function(String, T) f) {
    while (moveNext()) {
      f(name, current);
    }
  }
}

extension on Builder {
  bool get isConflictingAugmentationMember {
    Builder self = this;
    if (self is SourceMemberBuilder) {
      return self.isConflictingAugmentationMember;
    } else if (self is SourceClassBuilder) {
      return self.isConflictingAugmentationMember;
    }
    // TODO(johnniwinther): Handle all cases here.
    return false;
  }
}

class IteratorSequence<T> implements Iterator<T> {
  Iterator<Iterator<T>> _iterators;

  Iterator<T>? _current;

  IteratorSequence(Iterable<Iterator<T>> iterators)
      : _iterators = iterators.iterator;

  @override
  T get current {
    if (_current != null) {
      return _current!.current;
    }
    // Coverage-ignore-block(suite): Not run.
    throw new StateError("No current element");
  }

  @override
  bool moveNext() {
    if (_current != null) {
      if (_current!.moveNext()) {
        return true;
      }
      _current = null;
    }
    while (_iterators.moveNext()) {
      _current = _iterators.current;
      if (_current!.moveNext()) {
        return true;
      }
      _current = null;
    }
    return false;
  }
}
