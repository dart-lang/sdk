// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../../ast.dart';

// ------------------------------------------------------------------------
//                            FUNCTIONS
// ------------------------------------------------------------------------

/// A fixed-length list of [TypeParameter]s.
extension type const TypeParameterList._(List<TypeParameter> _list)
    implements List<TypeParameter> {
  static const TypeParameterList empty = TypeParameterList._(
    const <TypeParameter>[],
  );

  /// Creates a fixed-length list of 1–4 elements without allocating a
  /// temporary growable list from a literal.
  @pragma('vm:prefer-inline')
  factory(
    TypeParameter t1, [
    TypeParameter? t2,
    TypeParameter? t3,
    TypeParameter? t4,
  ]) {
    if (t2 == null) {
      assert(t3 == null && t4 == null);
      return TypeParameterList._1(t1);
    }
    if (t3 == null) {
      assert(t4 == null);
      return TypeParameterList._2(t1, t2);
    }
    if (t4 == null) {
      return TypeParameterList._3(t1, t2, t3);
    }
    return TypeParameterList._4(t1, t2, t3, t4);
  }

  factory _1(TypeParameter t1) =>
      TypeParameterList._(List<TypeParameter>.filled(1, t1));

  factory _2(TypeParameter t1, TypeParameter t2) =>
      TypeParameterList._(List<TypeParameter>.filled(2, t1)..[1] = t2);

  factory _3(TypeParameter t1, TypeParameter t2, TypeParameter t3) =>
      TypeParameterList._(
        List<TypeParameter>.filled(3, t1)
          ..[1] = t2
          ..[2] = t3,
      );

  factory _4(
    TypeParameter t1,
    TypeParameter t2,
    TypeParameter t3,
    TypeParameter t4,
  ) => TypeParameterList._(
    List<TypeParameter>.filled(4, t1)
      ..[1] = t2
      ..[2] = t3
      ..[3] = t4,
  );

  @pragma('vm:prefer-inline')
  factory generate(int length, TypeParameter Function(int index) generator) {
    if (length == 0) return empty;
    return TypeParameterList._(
      List<TypeParameter>.generate(length, generator, growable: false),
    );
  }

  @pragma('vm:prefer-inline')
  static TypeParameterList mapped<T>(
    List<T> list,
    TypeParameter Function(T) func,
  ) {
    final int length = list.length;
    if (length == 0) return empty;
    return TypeParameterList._(
      List<TypeParameter>.generate(
        length,
        (i) => func(list[i]),
        growable: false,
      ),
    );
  }

  /// Copies [typeParameters] into a new fixed-length list.
  factory from(List<TypeParameter> typeParameters) {
    if (typeParameters.isEmpty) return empty;
    return TypeParameterList._(
      List<TypeParameter>.generate(
        typeParameters.length,
        (i) => typeParameters[i],
        growable: false,
      ),
    );
  }
}

/// A fixed-length list of [PositionalParameter]s.
extension type const PositionalParameterList._(List<PositionalParameter> _list)
    implements List<PositionalParameter> {
  static const PositionalParameterList empty = PositionalParameterList._(
    const <PositionalParameter>[],
  );

  /// Creates a fixed-length list of 1–4 elements without allocating a
  /// temporary growable list from a literal.
  @pragma('vm:prefer-inline')
  factory(
    PositionalParameter p1, [
    PositionalParameter? p2,
    PositionalParameter? p3,
    PositionalParameter? p4,
  ]) {
    if (p2 == null) {
      assert(p3 == null && p4 == null);
      return PositionalParameterList._1(p1);
    }
    if (p3 == null) {
      assert(p4 == null);
      return PositionalParameterList._2(p1, p2);
    }
    if (p4 == null) {
      return PositionalParameterList._3(p1, p2, p3);
    }
    return PositionalParameterList._4(p1, p2, p3, p4);
  }

  factory _1(PositionalParameter p1) =>
      PositionalParameterList._(List<PositionalParameter>.filled(1, p1));

  factory _2(PositionalParameter p1, PositionalParameter p2) =>
      PositionalParameterList._(
        List<PositionalParameter>.filled(2, p1)..[1] = p2,
      );

  factory _3(
    PositionalParameter p1,
    PositionalParameter p2,
    PositionalParameter p3,
  ) => PositionalParameterList._(
    List<PositionalParameter>.filled(3, p1)
      ..[1] = p2
      ..[2] = p3,
  );

  factory _4(
    PositionalParameter p1,
    PositionalParameter p2,
    PositionalParameter p3,
    PositionalParameter p4,
  ) => PositionalParameterList._(
    List<PositionalParameter>.filled(4, p1)
      ..[1] = p2
      ..[2] = p3
      ..[3] = p4,
  );

  @pragma('vm:prefer-inline')
  factory generate(
    int length,
    PositionalParameter Function(int index) generator,
  ) {
    if (length == 0) return empty;
    return PositionalParameterList._(
      List<PositionalParameter>.generate(length, generator, growable: false),
    );
  }

  @pragma('vm:prefer-inline')
  static PositionalParameterList mapped<T>(
    List<T> list,
    PositionalParameter Function(T) func,
  ) {
    final int length = list.length;
    if (length == 0) return empty;
    return PositionalParameterList._(
      List<PositionalParameter>.generate(
        length,
        (i) => func(list[i]),
        growable: false,
      ),
    );
  }

  /// Copies [positionalParameters] into a new fixed-length list.
  factory from(List<PositionalParameter> positionalParameters) {
    if (positionalParameters.isEmpty) return empty;
    return PositionalParameterList._(
      List<PositionalParameter>.generate(
        positionalParameters.length,
        (i) => positionalParameters[i],
        growable: false,
      ),
    );
  }
}

/// A fixed-length list of [NamedParameter]s.
extension type const NamedParameterList._(List<NamedParameter> _list)
    implements List<NamedParameter> {
  static const NamedParameterList empty = NamedParameterList._(
    const <NamedParameter>[],
  );

  /// Creates a fixed-length list of 1–4 elements without allocating a
  /// temporary growable list from a literal.
  @pragma('vm:prefer-inline')
  factory(
    NamedParameter p1, [
    NamedParameter? p2,
    NamedParameter? p3,
    NamedParameter? p4,
  ]) {
    if (p2 == null) {
      assert(p3 == null && p4 == null);
      return NamedParameterList._1(p1);
    }
    if (p3 == null) {
      assert(p4 == null);
      return NamedParameterList._2(p1, p2);
    }
    if (p4 == null) {
      return NamedParameterList._3(p1, p2, p3);
    }
    return NamedParameterList._4(p1, p2, p3, p4);
  }

  factory _1(NamedParameter p1) =>
      NamedParameterList._(List<NamedParameter>.filled(1, p1));

  factory _2(NamedParameter p1, NamedParameter p2) =>
      NamedParameterList._(List<NamedParameter>.filled(2, p1)..[1] = p2);

  factory _3(NamedParameter p1, NamedParameter p2, NamedParameter p3) =>
      NamedParameterList._(
        List<NamedParameter>.filled(3, p1)
          ..[1] = p2
          ..[2] = p3,
      );

  factory _4(
    NamedParameter p1,
    NamedParameter p2,
    NamedParameter p3,
    NamedParameter p4,
  ) => NamedParameterList._(
    List<NamedParameter>.filled(4, p1)
      ..[1] = p2
      ..[2] = p3
      ..[3] = p4,
  );

  @pragma('vm:prefer-inline')
  factory generate(int length, NamedParameter Function(int index) generator) {
    if (length == 0) return empty;
    return NamedParameterList._(
      List<NamedParameter>.generate(length, generator, growable: false),
    );
  }

  @pragma('vm:prefer-inline')
  static NamedParameterList mapped<T>(
    List<T> list,
    NamedParameter Function(T) func,
  ) {
    final int length = list.length;
    if (length == 0) return empty;
    return NamedParameterList._(
      List<NamedParameter>.generate(
        length,
        (i) => func(list[i]),
        growable: false,
      ),
    );
  }

  /// Copies [namedParameters] into a new fixed-length list.
  factory from(List<NamedParameter> namedParameters) {
    if (namedParameters.isEmpty) return empty;
    return NamedParameterList._(
      List<NamedParameter>.generate(
        namedParameters.length,
        (i) => namedParameters[i],
        growable: false,
      ),
    );
  }
}

/// A function declares parameters and has a body.
///
/// This may occur in a procedure, constructor, function expression, or local
/// function declaration.
class FunctionNode extends TreeNode implements ScopeProvider, ContextConsumer {
  /// End offset in the source file it comes from. Valid values are from 0 and
  /// up, or -1 ([TreeNode.noOffset]) if the file end offset is not available
  /// (this is the default if none is specifically set).
  int fileEndOffset = TreeNode.noOffset;

  @override
  List<int>? get fileOffsetsIfMultiple => [fileOffset, fileEndOffset];

  /// Kernel async marker for the function.
  ///
  /// See also [dartAsyncMarker].
  AsyncMarker asyncMarker;

  /// Dart async marker for the function.
  ///
  /// See also [asyncMarker].
  ///
  /// A Kernel function can represent a Dart function with a different async
  /// marker.
  ///
  /// For example, when async/await is translated away,
  /// a Dart async function might be represented by a Kernel sync function.
  AsyncMarker dartAsyncMarker;

  TypeParameterList typeParameters;
  int requiredParameterCount;
  PositionalParameterList positionalParameters;
  NamedParameterList namedParameters;
  ThisVariable? thisVariable;
  DartType returnType; // Not null.
  Statement? _body;

  @override
  Scope? scope;

  @override
  List<VariableContext>? capturedContexts;

  /// The emitted value of non-sync functions
  ///
  /// For `async` functions [emittedValueType] is the future value type, that
  /// is, the returned element type. For instance
  ///
  ///     Future<Foo> method1() async => new Foo();
  ///     FutureOr<Foo> method2() async => new Foo();
  ///
  /// here the return types are `Future<Foo>` and `FutureOr<Foo>` for `method1`
  /// and `method2`, respectively, but the future value type is in both cases
  /// `Foo`.
  ///
  /// For pre-nnbd libraries, this is set to `flatten(T)` of the return type
  /// `T`, which can be seen as the pre-nnbd equivalent of the future value
  /// type.
  ///
  /// For `sync*` functions [emittedValueType] is the type of the element of the
  /// iterable returned by the function.
  ///
  /// For `async*` functions [emittedValueType] is the type of the element of
  /// the stream returned by the function.
  ///
  /// For sync functions (those not marked with one of `async`, `sync*`, or
  /// `async*`) the value of [emittedValueType] is null.
  DartType? emittedValueType;

  /// If the function is a redirecting factory constructor, this holds
  /// the target and type arguments of the redirection.
  RedirectingFactoryTarget? redirectingFactoryTarget;

  void Function()? lazyBuilder;

  void _buildLazy() {
    void Function()? lazyBuilderLocal = lazyBuilder;
    if (lazyBuilderLocal != null) {
      lazyBuilder = null;
      lazyBuilderLocal();
    }
  }

  Statement? get body {
    _buildLazy();
    return _body;
  }

  void set body(Statement? body) {
    _buildLazy();
    _body = body;
  }

  new(
    this._body, {
    TypeParameterList? typeParameters,
    PositionalParameterList? positionalParameters,
    NamedParameterList? namedParameters,
    int? requiredParameterCount,
    this.returnType = const DynamicType(),
    this.asyncMarker = AsyncMarker.Sync,
    AsyncMarker? dartAsyncMarker,
    this.emittedValueType,
    this.thisVariable,
  }) : this.positionalParameters =
           positionalParameters ?? PositionalParameterList.empty,
       this.requiredParameterCount =
           requiredParameterCount ?? positionalParameters?.length ?? 0,
       this.namedParameters = namedParameters ?? NamedParameterList.empty,
       this.typeParameters = typeParameters ?? TypeParameterList.empty,
       this.dartAsyncMarker = dartAsyncMarker ?? asyncMarker {
    setParents(this.typeParameters, this);
    setParents(this.positionalParameters, this);
    setParents(this.namedParameters, this);
    thisVariable?.parent = this;
    _body?.parent = this;
  }

  static DartType _getTypeOfVariable(Variable node) => node.type;

  static NamedType _getNamedTypeOfVariable(
    NamedParameter node, [
    Substitution? substitution,
  ]) {
    return new NamedType(
      node.parameterName,
      substitution != null ? substitution.substituteType(node.type) : node.type,
      isRequired: node.isRequired,
    );
  }

  /// Returns the function type of the node reusing its type parameters.
  ///
  /// This getter works similarly to [functionType], but reuses type parameters
  /// of the function node (or the class enclosing it -- see the comment on
  /// [functionType] about constructors of generic classes) in the result.  It
  /// is useful in some contexts, especially when reasoning about the function
  /// type of the enclosing generic function and in combination with
  /// [FunctionType.withoutTypeParameters].
  FunctionType computeThisFunctionType(Nullability nullability) {
    TreeNode? parent = this.parent;

    TypeParameterList typeParametersToCopy = parent is Constructor
        ? parent.enclosingClass.typeParameters
        : typeParameters;

    // TODO(johnniwinther,cstefantsova): Cache the function type here and use
    // [DartType.withDeclaredNullability] to handle the variants.
    return computeFunctionTypeFromData(
      returnType: returnType,
      typeParameters: typeParametersToCopy,
      positionalParameters: positionalParameters,
      namedParameters: namedParameters,
      nullability: nullability,
      requiredParameterCount: requiredParameterCount,
    );
  }

  /// Returns the function type of the function node.
  ///
  /// If the function node describes a generic function, the resulting function
  /// type will be generic.  If the function node describes a constructor of a
  /// generic class, the resulting function type will be generic with its type
  /// parameters constructed after those of the class.  In both cases, if the
  /// resulting function type is generic, a fresh set of type parameters is used
  /// in it.
  // TODO(johnniwinther,cstefantsova): Merge it with [computeThisFunctionType].
  FunctionType computeFunctionType(Nullability nullability) {
    return computeThisFunctionType(nullability);
  }

  static FunctionType computeFunctionTypeFromData({
    required DartType returnType,
    required List<TypeParameter> typeParameters,
    required List<PositionalParameter> positionalParameters,
    required List<NamedParameter> namedParameters,
    required Nullability nullability,
    required int requiredParameterCount,
  }) {
    StructuralParameterList structuralParameters;
    DartType functionReturnType;
    DartTypeList positionalParameterTypes;
    NamedDartTypeList namedParameterTypes;
    if (typeParameters.isEmpty) {
      structuralParameters = StructuralParameterList.empty;
      functionReturnType = returnType;
      positionalParameterTypes = DartTypeList.generate(
        positionalParameters.length,
        (index) => _getTypeOfVariable(positionalParameters[index]),
      );

      if (namedParameters.isEmpty) {
        namedParameterTypes = NamedDartTypeList.empty;
      } else {
        namedParameterTypes = NamedDartTypeList.generate(
          namedParameters.length,
          (index) => _getNamedTypeOfVariable(namedParameters[index]),
        );
        namedParameterTypes.sort();
      }
    } else {
      // We need create a copy of the list of type parameters, otherwise
      // transformations like erasure don't work.
      FreshStructuralParametersFromTypeParameters freshStructuralParameters =
          getFreshStructuralParametersFromTypeParameters(typeParameters);
      structuralParameters = freshStructuralParameters.freshTypeParameters;
      Substitution substitution = freshStructuralParameters.substitution;
      functionReturnType = substitution.substituteType(returnType);

      positionalParameterTypes = DartTypeList.mapped(
        positionalParameters,
        (p) => substitution.substituteType(_getTypeOfVariable(p)),
      );
      if (namedParameters.isEmpty) {
        namedParameterTypes = NamedDartTypeList.empty;
      } else {
        namedParameterTypes = NamedDartTypeList.mapped(
          namedParameters,
          (p) => _getNamedTypeOfVariable(p, substitution),
        )..sort();
      }
    }
    return new FunctionType(
      positionalParameterTypes,
      functionReturnType,
      nullability,
      namedParameters: namedParameterTypes,
      typeParameters: structuralParameters,
      requiredParameterCount: requiredParameterCount,
    );
  }

  @override
  R accept<R>(TreeVisitor<R> v) => v.visitFunctionNode(this);

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) =>
      v.visitFunctionNode(this, arg);

  @override
  void visitChildren(Visitor v) {
    visitList(typeParameters, v);
    visitList(positionalParameters, v);
    visitList(namedParameters, v);
    returnType.accept(v);
    // TODO(cstefantsova): Uncomment the following.
    // thisVariable?.accept(v);
    emittedValueType?.accept(v);
    redirectingFactoryTarget?.target?.acceptReference(v);
    if (redirectingFactoryTarget?.typeArguments != null) {
      visitList(redirectingFactoryTarget!.typeArguments!, v);
    }
    body?.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    v.transformList(typeParameters, this);
    v.transformList(positionalParameters, this);
    v.transformList(namedParameters, this);
    returnType = v.visitDartType(returnType);
    // TODO(cstefantsova): Uncomment the following.
    // if (thisVariable != null) {
    //   thisVariable = v.transform(thisVariable!)..parent = this;
    // }
    if (emittedValueType != null) {
      emittedValueType = v.visitDartType(emittedValueType!);
    }
    if (redirectingFactoryTarget?.typeArguments != null) {
      redirectingFactoryTarget!.typeArguments = v.transformDartTypeList(
        redirectingFactoryTarget!.typeArguments!,
      );
    }
    if (body != null) {
      body = v.transform(body!);
      body?.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformTypeParameterList(typeParameters, this);
    v.transformVariableList(positionalParameters, this);
    v.transformVariableList(namedParameters, this);
    returnType = v.visitDartType(returnType, cannotRemoveSentinel);
    if (thisVariable != null) {
      thisVariable = v.transformOrRemove(thisVariable!, dummyThisVariable)
        ?..parent = this;
    }
    if (emittedValueType != null) {
      emittedValueType = v.visitDartType(
        emittedValueType!,
        cannotRemoveSentinel,
      );
    }
    if (redirectingFactoryTarget?.typeArguments != null) {
      redirectingFactoryTarget!.typeArguments = v.transformDartTypeList(
        redirectingFactoryTarget!.typeArguments!,
      );
    }
    if (body != null) {
      body = v.transformOrRemoveStatement(body!);
      body?.parent = this;
    }
  }

  @override
  String toString() {
    return "FunctionNode(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    // TODO(johnniwinther): Implement this.
  }
}

enum AsyncMarker {
  // Do not change the order of these, the frontends depend on it.
  Sync,
  SyncStar,
  Async,
  AsyncStar,
}
