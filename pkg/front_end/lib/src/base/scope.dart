// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/type_environment.dart';

import '../builder/builder.dart';
import '../builder/compilation_unit.dart';
import '../builder/declaration_builders.dart';
import '../builder/member_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/prefix_builder.dart';
import '../kernel/hierarchy/class_member.dart' show ClassMember;
import '../kernel/kernel_helper.dart';
import '../kernel/load_library_builder.dart';
import '../kernel/type_algorithms.dart';
import '../source/source_class_builder.dart';
import '../source/source_library_builder.dart';
import '../source/source_member_builder.dart';
import 'lookup_result.dart';
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
  LookupResult? lookup(String name);
  // TODO(johnniwinther): Should this be moved to an outer scope interface?
  void forEachExtension(void Function(ExtensionBuilder) f);
}

/// A [LookupScope] based directly on a [NameSpace].
abstract class BaseNameSpaceLookupScope implements LookupScope {
  @override
  final ScopeKind kind;

  BaseNameSpaceLookupScope(this.kind);

  NameSpace get _nameSpace;

  LookupScope? get _parent;

  @override
  LookupResult? lookup(String name) {
    return _nameSpace.lookup(name) ?? _parent?.lookup(name);
  }

  @override
  void forEachExtension(void Function(ExtensionBuilder) f) {
    _nameSpace.forEachLocalExtension(f);
    _parent?.forEachExtension(f);
  }

  @override
  String toString() => "$runtimeType(${kind})";
}

class NameSpaceLookupScope extends BaseNameSpaceLookupScope {
  @override
  final NameSpace _nameSpace;

  @override
  final LookupScope? _parent;

  NameSpaceLookupScope(this._nameSpace, super.kind, {LookupScope? parent})
    : _parent = parent;
}

abstract class AbstractTypeParameterScope implements LookupScope {
  final LookupScope _parent;

  AbstractTypeParameterScope(this._parent);

  TypeParameterBuilder? getTypeParameter(String name);

  @override
  ScopeKind get kind => ScopeKind.typeParameters;

  @override
  LookupResult? lookup(String name) {
    LookupResult? result = getTypeParameter(name);
    return result ?? _parent.lookup(name);
  }

  @override
  void forEachExtension(void Function(ExtensionBuilder) f) {
    _parent.forEachExtension(f);
  }

  @override
  String toString() => "$runtimeType(${kind},type parameter)";
}

class TypeParameterScope extends AbstractTypeParameterScope {
  final Map<String, TypeParameterBuilder> _typeParameters;

  TypeParameterScope(super._parent, this._typeParameters);

  @override
  TypeParameterBuilder? getTypeParameter(String name) => _typeParameters[name];

  static LookupScope fromList(
    LookupScope parent,
    List<TypeParameterBuilder>? typeParameterBuilders,
  ) {
    if (typeParameterBuilders == null) return parent;
    Map<String, TypeParameterBuilder> map = {};
    for (TypeParameterBuilder typeParameterBuilder in typeParameterBuilders) {
      if (typeParameterBuilder.isWildcard) continue;
      map[typeParameterBuilder.name] = typeParameterBuilder;
    }
    return new TypeParameterScope(parent, map);
  }
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
    : super(ScopeKind.import);

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

  CompilationUnitScope(this._compilationUnit, super.kind, {LookupScope? parent})
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
  final ComputedNameSpace _nameSpace;

  @override
  final LookupScope? _parent;

  CompilationUnitPrefixScope(
    this._nameSpace,
    super.kind, {
    required LookupScope? parent,
  }) : _parent = parent;

  /// Set of extension declarations in scope. This is computed lazily in
  /// [forEachExtension].
  Set<ExtensionBuilder>? _extensions;

  @override
  void forEachExtension(void Function(ExtensionBuilder) f) {
    if (_extensions == null) {
      Set<ExtensionBuilder> extensions = _extensions = {};
      Iterator<PrefixBuilder> iterator = _nameSpace.filteredIterator();
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

  DeclarationBuilderScope(this._parent) : super(ScopeKind.declaration);

  @override
  NameSpace get _nameSpace {
    assert(_declarationBuilder != null, "declarationBuilder has not been set.");
    return _declarationBuilder!.nameSpace;
  }

  void set declarationBuilder(DeclarationBuilder value) {
    assert(
      _declarationBuilder == null,
      "declarationBuilder has already been set.",
    );
    _declarationBuilder = value;
  }
}

/// Computes a builder for the import collision between [declaration] and
/// [other].
NamedBuilder computeAmbiguousDeclarationForImport(
  ProblemReporting problemReporting,
  String name,
  NamedBuilder declaration,
  NamedBuilder other, {
  required UriOffset uriOffset,
}) {
  // Prefix fragments are merged to singular prefix builders when computing the
  // import scope.
  assert(
    !(declaration is PrefixBuilder && other is PrefixBuilder),
    "Unexpected prefix builders $declaration and $other.",
  );

  // TODO(ahe): Can I move this to Scope or Prefix?
  if (declaration == other) return declaration;
  if (declaration is InvalidBuilder) return declaration;
  if (other is InvalidBuilder) return other;
  NamedBuilder? preferred;
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
  Message message = codeDuplicatedImport.withArguments(
    name,
    // TODO(ahe): We should probably use a context object here
    // instead of including URIs in this message.
    firstUri,
    secondUri,
  );
  // We report the error lazily (setting errorHasBeenReported to false) because
  // the spec 18.1 states that 'It is not an error if N is introduced by two or
  // more imports but never referred to.'
  return new InvalidBuilder(
    name,
    message.withLocation(uriOffset.fileUri, uriOffset.fileOffset, name.length),
    errorHasBeenReported: false,
  );
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
  bool get isFinal => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isSynthesized => false;

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
  void buildOutlineExpressions(
    ClassHierarchy classHierarchy,
    List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
  ) {
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
  int computeDefaultTypes(
    ComputeDefaultTypeContext context, {
    required bool inErrorRecovery,
  }) {
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
    SourceClassBuilder sourceClassBuilder,
    TypeEnvironment typeEnvironment,
  ) {
    assert(false, "Unexpected call to $runtimeType.checkVariance.");
  }

  @override
  // Coverage-ignore(suite): Not run.
  void checkTypes(
    SourceLibraryBuilder library,
    NameSpace nameSpace,
    TypeEnvironment typeEnvironment,
  ) {
    assert(false, "Unexpected call to $runtimeType.checkVariance.");
  }

  @override
  MemberBuilder get getable;
}

class LookupResultIterator implements Iterator<NamedBuilder> {
  Iterator<LookupResult>? _lookupResultIterator;
  Iterator<ExtensionBuilder>? _extensionsIterator;
  LookupResult? _currentLookupResult;
  NamedBuilder? _currentBuilder;

  LookupResultIterator(this._lookupResultIterator, this._extensionsIterator);

  @override
  bool moveNext() {
    NamedBuilder? next = _currentBuilder?.next;
    if (next != null) {
      // Coverage-ignore-block(suite): Not run.
      _currentBuilder = next;
      return true;
    }
    next = _currentLookupResult?.setable;
    if (next != null) {
      _currentLookupResult = null;
      _currentBuilder = next;
      return true;
    }
    if (_lookupResultIterator != null) {
      if (_lookupResultIterator!.moveNext()) {
        LookupResult result = _lookupResultIterator!.current;
        if (result is NamedBuilder) {
          _currentBuilder = result as NamedBuilder;
          return true;
        } else {
          next = result.getable;
          if (next != null) {
            _currentBuilder = next;
            _currentLookupResult = result;
            return true;
          }
          // Coverage-ignore-block(suite): Not run.
          next = result.setable;
          if (next != null) {
            _currentBuilder = next;
            return true;
          }
        }
      } else {
        _lookupResultIterator = null;
      }
    }
    if (_extensionsIterator != null) {
      // Coverage-ignore-block(suite): Not run.
      if (_extensionsIterator!.moveNext()) {
        _currentBuilder = _extensionsIterator!.current;
      } else {
        _extensionsIterator = null;
      }
    }
    return false;
  }

  @override
  NamedBuilder get current {
    return _currentBuilder ?? // Coverage-ignore(suite): Not run.
        (throw new StateError('No element'));
  }
}

/// Filtered builder [Iterator].
class FilteredIterator<T extends NamedBuilder> implements Iterator<T> {
  final Iterator<NamedBuilder> _iterator;
  final bool includeDuplicates;

  FilteredIterator(this._iterator, {required this.includeDuplicates});

  bool _include(NamedBuilder element) {
    if (!includeDuplicates && (element.isDuplicate)) {
      return false;
    }
    return element is T;
  }

  @override
  T get current => _iterator.current as T;

  @override
  bool moveNext() {
    while (_iterator.moveNext()) {
      NamedBuilder candidate = _iterator.current;
      if (_include(candidate)) {
        return true;
      }
    }
    return false;
  }
}

extension IteratorExtension<T extends NamedBuilder> on Iterator<T> {
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
