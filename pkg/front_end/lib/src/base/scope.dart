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
//import '../kernel/body_builder.dart' show JumpTarget;
import '../kernel/body_builder_context.dart';
import '../kernel/hierarchy/class_member.dart' show ClassMember;
import '../kernel/kernel_helper.dart';
import '../kernel/load_library_builder.dart';
import '../kernel/type_algorithms.dart';
import '../source/source_class_builder.dart';
import '../source/source_extension_builder.dart';
import '../source/source_extension_type_declaration_builder.dart';
import '../source/source_function_builder.dart';
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

  import,

  prefix,
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
    return normalizeLookup(
        getable: getables[name],
        setable: null,
        name: name,
        charOffset: charOffset,
        fileUri: fileUri,
        classNameOrDebugName: classNameOrDebugName,
        isSetter: false);
  }

  Builder? lookupSetableIn(String name, int charOffset, Uri fileUri,
      Map<String, Builder>? getables) {
    return normalizeLookup(
        getable: getables?[name],
        setable: null,
        name: name,
        charOffset: charOffset,
        fileUri: fileUri,
        classNameOrDebugName: classNameOrDebugName,
        isSetter: true);
  }
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
    Builder? builder = normalizeLookup(
        getable: _nameSpace.lookupLocalMember(name, setter: false),
        setable: _nameSpace.lookupLocalMember(name, setter: true),
        name: name,
        charOffset: charOffset,
        fileUri: fileUri,
        classNameOrDebugName: classNameOrDebugName,
        isSetter: false);
    return builder ?? _parent?.lookupGetable(name, charOffset, fileUri);
  }

  @override
  Builder? lookupSetable(String name, int charOffset, Uri fileUri) {
    Builder? builder = normalizeLookup(
        getable: _nameSpace.lookupLocalMember(name, setter: false),
        setable: _nameSpace.lookupLocalMember(name, setter: true),
        name: name,
        charOffset: charOffset,
        fileUri: fileUri,
        classNameOrDebugName: classNameOrDebugName,
        isSetter: true);
    return builder ?? _parent?.lookupSetable(name, charOffset, fileUri);
  }

  @override
  void forEachExtension(void Function(ExtensionBuilder) f) {
    _nameSpace.forEachLocalExtension(f);
    _parent?.forEachExtension(f);
  }
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
    Builder? builder = normalizeLookup(
        getable: getTypeParameter(name),
        setable: null,
        name: name,
        charOffset: charOffset,
        fileUri: fileUri,
        classNameOrDebugName: classNameOrDebugName,
        isSetter: false);
    return builder ?? _parent.lookupGetable(name, charOffset, fileUri);
  }

  @override
  Builder? lookupSetable(String name, int charOffset, Uri fileUri) {
    Builder? builder = normalizeLookup(
        getable: getTypeParameter(name),
        setable: null,
        name: name,
        charOffset: charOffset,
        fileUri: fileUri,
        classNameOrDebugName: classNameOrDebugName,
        isSetter: true);
    return builder ?? _parent.lookupSetable(name, charOffset, fileUri);
  }

  String get classNameOrDebugName => "type parameter";

  @override
  // Coverage-ignore(suite): Not run.
  void forEachExtension(void Function(ExtensionBuilder) f) {
    _parent.forEachExtension(f);
  }
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
    Builder? builder = normalizeLookup(
        getable: _getables
            // Coverage-ignore(suite): Not run.
            ?[name],
        setable: _setables
            // Coverage-ignore(suite): Not run.
            ?[name],
        name: name,
        charOffset: charOffset,
        fileUri: fileUri,
        classNameOrDebugName: classNameOrDebugName,
        isSetter: false);
    return builder ?? _parent?.lookupGetable(name, charOffset, fileUri);
  }

  @override
  Builder? lookupSetable(String name, int charOffset, Uri fileUri) {
    Builder? builder = normalizeLookup(
        getable: _getables
            // Coverage-ignore(suite): Not run.
            ?[name],
        setable: _setables
            // Coverage-ignore(suite): Not run.
            ?[name],
        name: name,
        charOffset: charOffset,
        fileUri: fileUri,
        classNameOrDebugName: classNameOrDebugName,
        isSetter: true);
    return builder ?? _parent?.lookupSetable(name, charOffset, fileUri);
  }

  @override
  void forEachExtension(void Function(ExtensionBuilder) f) {
    _parent?.forEachExtension(f);
  }
}

// Coverage-ignore(suite): Not run.
// TODO(johnniwinther): Use this instead of [SourceLibraryBuilderScope].
class CompilationUnitScope extends BaseNameSpaceLookupScope {
  final CompilationUnit _compilationUnit;

  @override
  final LookupScope? _parent;

  CompilationUnitScope(
      this._compilationUnit, super.kind, super.classNameOrDebugName,
      {LookupScope? parent})
      : _parent = parent;

  @override
  NameSpace get _nameSpace => _compilationUnit.libraryBuilder.libraryNameSpace;
}

class SourceLibraryBuilderScope extends BaseNameSpaceLookupScope {
  final SourceCompilationUnit _compilationUnit;

  SourceLibraryBuilderScope(
      this._compilationUnit, super.kind, super.classNameOrDebugName);

  @override
  NameSpace get _nameSpace => _compilationUnit.libraryBuilder.libraryNameSpace;

  @override
  LookupScope? get _parent => _compilationUnit.libraryBuilder.prefixScope;
}

abstract class ConstructorScope {
  MemberBuilder? lookup(String name, int charOffset, Uri fileUri);
}

class DeclarationNameSpaceConstructorScope implements ConstructorScope {
  final String _className;

  final DeclarationNameSpace _nameSpace;

  DeclarationNameSpaceConstructorScope(this._className, this._nameSpace);

  @override
  MemberBuilder? lookup(String name, int charOffset, Uri fileUri) {
    MemberBuilder? builder = _nameSpace.lookupConstructor(name);
    if (builder == null) return null;
    if (builder.next != null) {
      return new AmbiguousMemberBuilder(
          name.isEmpty ? _className : name, builder, charOffset, fileUri);
    } else {
      return builder;
    }
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
  Member? get writeTarget => null;

  @override
  // Coverage-ignore(suite): Not run.
  Member? get invokeTarget => null;

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
  BodyBuilderContext createBodyBuilderContext() {
    throw new UnsupportedError(
        '$runtimeType.bodyBuilderContextForAnnotations}');
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

  // Coverage-ignore(suite): Not run.
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

abstract class MergedScope<T extends Builder> {
  final T _origin;
  final NameSpace _originNameSpace;
  Map<T, NameSpace> _augmentationNameSpaces = {};

  MergedScope(this._origin, this._originNameSpace);

  SourceLibraryBuilder get originLibrary;

  void _addBuilderToMergedScope(
      String name, Builder newBuilder, Builder? existingBuilder,
      {required bool setter, required bool inPatchLibrary}) {
    bool isAugmentationBuilder = inPatchLibrary
        ? newBuilder.hasPatchAnnotation
        : newBuilder.isAugmentation;
    if (existingBuilder != null) {
      if (isAugmentationBuilder) {
        existingBuilder.applyAugmentation(newBuilder);
      } else {
        newBuilder.isConflictingAugmentationMember = true;
        Message message;
        Message context;
        if (newBuilder is SourceMemberBuilder &&
            existingBuilder is SourceMemberBuilder) {
          if (_origin is SourceLibraryBuilder) {
            message = inPatchLibrary
                ? templateNonPatchLibraryMemberConflict.withArguments(name)
                : templateNonAugmentationLibraryMemberConflict
                    .withArguments(name);
          } else {
            message = inPatchLibrary
                ? templateNonPatchClassMemberConflict.withArguments(name)
                : templateNonAugmentationClassMemberConflict
                    .withArguments(name);
          }
          context = messageNonAugmentationMemberConflictCause;
        } else if (newBuilder is SourceClassBuilder &&
            existingBuilder is SourceClassBuilder) {
          message = inPatchLibrary
              ? templateNonPatchClassConflict.withArguments(name)
              : templateNonAugmentationClassConflict.withArguments(name);
          context = messageNonAugmentationClassConflictCause;
        } else {
          if (_origin is SourceLibraryBuilder) {
            message = inPatchLibrary
                ? templateNonPatchLibraryConflict.withArguments(name)
                : templateNonAugmentationLibraryConflict.withArguments(name);
          } else {
            // Coverage-ignore-block(suite): Not run.
            message = inPatchLibrary
                ? templateNonPatchClassMemberConflict.withArguments(name)
                : templateNonAugmentationClassMemberConflict
                    .withArguments(name);
          }
          context = messageNonAugmentationMemberConflictCause;
        }
        originLibrary.addProblem(
            message, newBuilder.fileOffset, name.length, newBuilder.fileUri,
            context: [
              context.withLocation(existingBuilder.fileUri!,
                  existingBuilder.fileOffset, name.length)
            ]);
      }
    } else {
      if (isAugmentationBuilder) {
        Message message;
        if (newBuilder is SourceMemberBuilder) {
          if (_origin is SourceLibraryBuilder) {
            message = inPatchLibrary
                ? templateUnmatchedPatchLibraryMember.withArguments(name)
                : templateUnmatchedAugmentationLibraryMember
                    .withArguments(name);
          } else {
            message = inPatchLibrary
                ? templateUnmatchedPatchClassMember.withArguments(name)
                : templateUnmatchedAugmentationClassMember.withArguments(name);
          }
        } else if (newBuilder is SourceClassBuilder) {
          message = inPatchLibrary
              ? templateUnmatchedPatchClass.withArguments(name)
              : templateUnmatchedAugmentationClass.withArguments(name);
        } else {
          message = inPatchLibrary
              ? templateUnmatchedPatchDeclaration.withArguments(name)
              :
              // Coverage-ignore(suite): Not run.
              templateUnmatchedAugmentationDeclaration.withArguments(name);
        }
        originLibrary.addProblem(
            message, newBuilder.fileOffset, name.length, newBuilder.fileUri);
      } else {
        if (inPatchLibrary &&
            !name.startsWith('_') &&
            !_allowInjectedPublicMember(newBuilder)) {
          originLibrary.addProblem(
              templatePatchInjectionFailed.withArguments(
                  name, originLibrary.importUri),
              newBuilder.fileOffset,
              noLength,
              newBuilder.fileUri);
        }
        _originNameSpace.addLocalMember(name, newBuilder, setter: setter);
        if (newBuilder is ExtensionBuilder) {
          _originNameSpace.addExtension(newBuilder);
        }
        for (NameSpace augmentationNameSpace
            in _augmentationNameSpaces.values) {
          _addBuilderToAugmentationNameSpace(
              augmentationNameSpace, name, newBuilder,
              setter: setter);
        }
      }
    }
  }

  void _addBuilderToAugmentationNameSpace(
      NameSpace augmentationNameSpace, String name, Builder member,
      {required bool setter}) {
    Builder? augmentationMember =
        augmentationNameSpace.lookupLocalMember(name, setter: setter);
    if (augmentationMember == null) {
      augmentationNameSpace.addLocalMember(name, member, setter: setter);
      if (member is ExtensionBuilder) {
        augmentationNameSpace.addExtension(member);
      }
    }
  }

  void _addAugmentationScope(T parentBuilder, NameSpace nameSpace,
      {required Map<String, List<Builder>>? augmentations,
      required Map<String, List<Builder>>? setterAugmentations,
      required bool inPatchLibrary}) {
    // TODO(johnniwinther): Use `scope.filteredNameIterator` instead of
    // `scope.forEachLocalMember`/`scope.forEachLocalSetter`.

    // Include all augmentation scope members to the origin scope.
    nameSpace.forEachLocalMember((String name, Builder member) {
      // In case of duplicates we use the first declaration.
      while (member.isDuplicate) {
        member = member.next!;
      }
      _addBuilderToMergedScope(
          name, member, _originNameSpace.lookupLocalMember(name, setter: false),
          setter: false, inPatchLibrary: inPatchLibrary);
    });
    if (augmentations != null) {
      for (String augmentedName in augmentations.keys) {
        for (Builder augmentation in augmentations[augmentedName]!) {
          _addBuilderToMergedScope(augmentedName, augmentation,
              _originNameSpace.lookupLocalMember(augmentedName, setter: false),
              setter: false, inPatchLibrary: inPatchLibrary);
        }
      }
    }
    nameSpace.forEachLocalSetter((String name, Builder member) {
      // In case of duplicates we use the first declaration.
      while (member.isDuplicate) {
        member = member.next!;
      }
      _addBuilderToMergedScope(
          name, member, _originNameSpace.lookupLocalMember(name, setter: true),
          setter: true, inPatchLibrary: inPatchLibrary);
    });
    if (setterAugmentations != null) {
      for (String augmentedName in setterAugmentations.keys) {
        for (Builder augmentation in setterAugmentations[augmentedName]!) {
          _addBuilderToMergedScope(augmentedName, augmentation,
              _originNameSpace.lookupLocalMember(augmentedName, setter: true),
              setter: true, inPatchLibrary: inPatchLibrary);
        }
      }
    }
    nameSpace.forEachLocalExtension((ExtensionBuilder extensionBuilder) {
      if (extensionBuilder is SourceExtensionBuilder &&
          extensionBuilder.isUnnamedExtension) {
        _originNameSpace.addExtension(extensionBuilder);
        for (NameSpace augmentationNameSpace
            in _augmentationNameSpaces.values) {
          augmentationNameSpace.addExtension(extensionBuilder);
        }
      }
    });

    // Include all origin scope members in the augmentation scope.
    _originNameSpace.forEachLocalMember((String name, Builder originMember) {
      _addBuilderToAugmentationNameSpace(nameSpace, name, originMember,
          setter: false);
    });
    _originNameSpace.forEachLocalSetter((String name, Builder originMember) {
      _addBuilderToAugmentationNameSpace(nameSpace, name, originMember,
          setter: true);
    });
    _originNameSpace.forEachLocalExtension((ExtensionBuilder extensionBuilder) {
      if (extensionBuilder is SourceExtensionBuilder &&
          extensionBuilder.isUnnamedExtension) {
        nameSpace.addExtension(extensionBuilder);
      }
    });

    _augmentationNameSpaces[parentBuilder] = nameSpace;
  }

  bool _allowInjectedPublicMember(Builder newBuilder);
}

class MergedLibraryScope extends MergedScope<SourceLibraryBuilder> {
  MergedLibraryScope(SourceLibraryBuilder origin)
      : super(origin, origin.libraryNameSpace);

  @override
  SourceLibraryBuilder get originLibrary => _origin;

  void addAugmentationScope(SourceLibraryBuilder builder) {
    _addAugmentationScope(builder, builder.libraryNameSpace,
        augmentations: builder.augmentations,
        setterAugmentations: builder.setterAugmentations,
        inPatchLibrary: builder.isPatchLibrary);
  }

  @override
  bool _allowInjectedPublicMember(Builder newBuilder) {
    return originLibrary.importUri.isScheme("dart") &&
        originLibrary.importUri.path.startsWith("_");
  }
}

class MergedClassMemberScope extends MergedScope<SourceClassBuilder> {
  final DeclarationNameSpace _originConstructorNameSpace;
  Map<SourceClassBuilder, DeclarationNameSpace>
      _augmentationConstructorNameSpaces = {};

  MergedClassMemberScope(SourceClassBuilder origin)
      : _originConstructorNameSpace = origin.nameSpace,
        super(origin, origin.nameSpace);

  @override
  SourceLibraryBuilder get originLibrary => _origin.libraryBuilder;

  void _addAugmentationConstructorScope(DeclarationNameSpace nameSpace,
      {required bool inPatchLibrary}) {
    nameSpace.forEachConstructor((String name, MemberBuilder newConstructor) {
      MemberBuilder? existingConstructor =
          _originConstructorNameSpace.lookupConstructor(name);
      bool isAugmentationBuilder = inPatchLibrary
          ? newConstructor.hasPatchAnnotation
          : newConstructor.isAugmentation;
      if (existingConstructor != null) {
        if (isAugmentationBuilder) {
          existingConstructor.applyAugmentation(newConstructor);
        } else {
          newConstructor.isConflictingAugmentationMember = true;
          originLibrary.addProblem(
              inPatchLibrary
                  ? templateNonPatchConstructorConflict
                      .withArguments(newConstructor.fullNameForErrors)
                  :
                  // Coverage-ignore(suite): Not run.
                  templateNonAugmentationConstructorConflict
                      .withArguments(newConstructor.fullNameForErrors),
              newConstructor.fileOffset,
              noLength,
              newConstructor.fileUri,
              context: [
                messageNonAugmentationConstructorConflictCause.withLocation(
                    existingConstructor.fileUri!,
                    existingConstructor.fileOffset,
                    noLength)
              ]);
        }
      } else {
        if (isAugmentationBuilder) {
          originLibrary.addProblem(
              inPatchLibrary
                  ? templateUnmatchedPatchConstructor
                      .withArguments(newConstructor.fullNameForErrors)
                  :
                  // Coverage-ignore(suite): Not run.
                  templateUnmatchedAugmentationConstructor
                      .withArguments(newConstructor.fullNameForErrors),
              newConstructor.fileOffset,
              noLength,
              newConstructor.fileUri);
        } else {
          _originConstructorNameSpace.addConstructor(name, newConstructor);
          for (DeclarationNameSpace augmentationConstructorNameSpace
              in _augmentationConstructorNameSpaces.values) {
            // Coverage-ignore-block(suite): Not run.
            _addConstructorToAugmentationScope(
                augmentationConstructorNameSpace, name, newConstructor);
          }
        }
        if (inPatchLibrary &&
            !name.startsWith('_') &&
            !_allowInjectedPublicMember(newConstructor)) {
          // Coverage-ignore-block(suite): Not run.
          originLibrary.addProblem(
              templatePatchInjectionFailed.withArguments(
                  name, originLibrary.importUri),
              newConstructor.fileOffset,
              noLength,
              newConstructor.fileUri);
        }
      }
    });
    _originConstructorNameSpace
        .forEachConstructor((String name, MemberBuilder originConstructor) {
      _addConstructorToAugmentationScope(nameSpace, name, originConstructor);
    });
  }

  void _addConstructorToAugmentationScope(
      DeclarationNameSpace augmentationConstructorNameSpace,
      String name,
      MemberBuilder constructor) {
    Builder? augmentationConstructor =
        augmentationConstructorNameSpace.lookupConstructor(name);
    if (augmentationConstructor == null) {
      augmentationConstructorNameSpace.addConstructor(name, constructor);
    }
  }

  // TODO(johnniwinther): Check for conflicts between constructors and class
  //  members.
  void addAugmentationScope(SourceClassBuilder builder) {
    _addAugmentationScope(builder, builder.nameSpace,
        augmentations: null,
        setterAugmentations: null,
        inPatchLibrary: builder.libraryBuilder.isPatchLibrary);
    _addAugmentationConstructorScope(builder.nameSpace,
        inPatchLibrary: builder.libraryBuilder.isPatchLibrary);
  }

  @override
  bool _allowInjectedPublicMember(Builder newBuilder) {
    if (originLibrary.importUri.isScheme("dart") &&
        originLibrary.importUri.path.startsWith("_")) {
      return true;
    }
    if (newBuilder.isStatic) {
      // Coverage-ignore-block(suite): Not run.
      return _origin.name.startsWith('_');
    }
    // TODO(johnniwinther): Restrict the use of injected public class members.
    return true;
  }
}

extension on Builder {
  bool get isAugmentation {
    Builder self = this;
    if (self is SourceLibraryBuilder) {
      // Coverage-ignore-block(suite): Not run.
      return self.isAugmentationLibrary;
    } else if (self is SourceClassBuilder) {
      return self.isAugmentation;
    } else if (self is SourceMemberBuilder) {
      return self.isAugmentation;
    } else {
      // TODO(johnniwinther): Handle all cases here.
      return false;
    }
  }

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

  void set isConflictingAugmentationMember(bool value) {
    Builder self = this;
    if (self is SourceMemberBuilder) {
      self.isConflictingAugmentationMember = value;
    } else if (self is SourceClassBuilder) {
      self.isConflictingAugmentationMember = value;
    }
    // TODO(johnniwinther): Handle all cases here.
  }

  bool _hasPatchAnnotation(Iterable<MetadataBuilder>? metadata) {
    if (metadata == null) {
      return false;
    }
    for (MetadataBuilder metadataBuilder in metadata) {
      if (metadataBuilder.hasPatch) {
        return true;
      }
    }
    return false;
  }

  bool get hasPatchAnnotation {
    Builder self = this;
    if (self is SourceFunctionBuilder) {
      return _hasPatchAnnotation(self.metadata);
    } else if (self is SourceClassBuilder) {
      return _hasPatchAnnotation(self.metadata);
    } else if (self is SourceExtensionBuilder) {
      return _hasPatchAnnotation(self.metadata);
    } else if (self is SourceExtensionTypeDeclarationBuilder) {
      // Coverage-ignore-block(suite): Not run.
      return _hasPatchAnnotation(self.metadata);
    }
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
