// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../../ast.dart';

// ------------------------------------------------------------------------
//                            FUNCTIONS
// ------------------------------------------------------------------------

/// A function declares parameters and has a body.
///
/// This may occur in a procedure, constructor, function expression, or local
/// function declaration.
class FunctionNode extends TreeNode {
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

  List<TypeParameter> typeParameters;
  int requiredParameterCount;
  List<VariableDeclaration> positionalParameters;
  List<VariableDeclaration> namedParameters;
  DartType returnType; // Not null.
  Statement? _body;

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

  FunctionNode(this._body,
      {List<TypeParameter>? typeParameters,
      List<VariableDeclaration>? positionalParameters,
      List<VariableDeclaration>? namedParameters,
      int? requiredParameterCount,
      this.returnType = const DynamicType(),
      this.asyncMarker = AsyncMarker.Sync,
      AsyncMarker? dartAsyncMarker,
      this.emittedValueType})
      : this.positionalParameters =
            positionalParameters ?? <VariableDeclaration>[],
        this.requiredParameterCount =
            requiredParameterCount ?? positionalParameters?.length ?? 0,
        this.namedParameters = namedParameters ?? <VariableDeclaration>[],
        this.typeParameters = typeParameters ?? <TypeParameter>[],
        this.dartAsyncMarker = dartAsyncMarker ?? asyncMarker {
    setParents(this.typeParameters, this);
    setParents(this.positionalParameters, this);
    setParents(this.namedParameters, this);
    _body?.parent = this;
  }

  static DartType _getTypeOfVariable(VariableDeclaration node) => node.type;

  static NamedType _getNamedTypeOfVariable(VariableDeclaration node,
      [Substitution? substitution]) {
    return new NamedType(
        node.name!,
        substitution != null
            ? substitution.substituteType(node.type)
            : node.type,
        isRequired: node.isRequired);
  }

  /// Returns the function type of the node reusing its type parameters.
  ///
  /// This getter works similarly to [functionType], but reuses type parameters
  /// of the function node (or the class enclosing it -- see the comment on
  /// [functionType] about constructors of generic classes) in the result.  It
  /// is useful in some contexts, especially when reasoning about the function
  /// type of the enclosing generic function and in combination with
  /// [FunctionType.withoutTypeParameters].
  FunctionType computeThisFunctionType(Nullability nullability,
      {bool reuseTypeParameters = false}) {
    TreeNode? parent = this.parent;

    List<StructuralParameter> structuralParameters;
    List<TypeParameter> typeParametersToCopy = parent is Constructor
        ? parent.enclosingClass.typeParameters
        : typeParameters;
    DartType returnType;
    List<DartType> positionalParameters;
    List<NamedType> namedParameters;
    if (typeParametersToCopy.isEmpty || reuseTypeParameters) {
      structuralParameters = const <StructuralParameter>[];
      returnType = this.returnType;
      List<VariableDeclaration> thisPositionals = this.positionalParameters;
      positionalParameters = List.generate(thisPositionals.length,
          (index) => _getTypeOfVariable(thisPositionals[index]),
          growable: false);

      List<VariableDeclaration> thisNamed = this.namedParameters;
      if (thisNamed.isEmpty) {
        namedParameters = const <NamedType>[];
      } else {
        namedParameters = List.generate(thisNamed.length,
            (index) => _getNamedTypeOfVariable(thisNamed[index]),
            growable: false);
        namedParameters.sort();
      }
    } else {
      // We need create a copy of the list of type parameters, otherwise
      // transformations like erasure don't work.
      FreshStructuralParametersFromTypeParameters freshStructuralParameters =
          getFreshStructuralParametersFromTypeParameters(typeParametersToCopy);
      structuralParameters = freshStructuralParameters.freshTypeParameters;
      Substitution substitution = freshStructuralParameters.substitution;
      returnType = substitution.substituteType(this.returnType);

      List<VariableDeclaration> thisPositionals = this.positionalParameters;
      positionalParameters = List.generate(
          thisPositionals.length,
          (index) => substitution
              .substituteType(_getTypeOfVariable(thisPositionals[index])),
          growable: false);
      List<VariableDeclaration> thisNamed = this.namedParameters;
      if (thisNamed.isEmpty) {
        namedParameters = const <NamedType>[];
      } else {
        namedParameters = List.generate(thisNamed.length,
            (index) => _getNamedTypeOfVariable(thisNamed[index], substitution),
            growable: false);
        namedParameters.sort();
      }
    }
    // TODO(johnniwinther,cstefantsova): Cache the function type here and use
    // [DartType.withDeclaredNullability] to handle the variants.
    return new FunctionType(positionalParameters, returnType, nullability,
        namedParameters: namedParameters,
        typeParameters: structuralParameters,
        requiredParameterCount: requiredParameterCount);
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
    if (emittedValueType != null) {
      emittedValueType = v.visitDartType(emittedValueType!);
    }
    if (redirectingFactoryTarget?.typeArguments != null) {
      v.transformDartTypeList(redirectingFactoryTarget!.typeArguments!);
    }
    if (body != null) {
      body = v.transform(body!);
      body?.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformTypeParameterList(typeParameters, this);
    v.transformVariableDeclarationList(positionalParameters, this);
    v.transformVariableDeclarationList(namedParameters, this);
    returnType = v.visitDartType(returnType, cannotRemoveSentinel);
    if (emittedValueType != null) {
      emittedValueType =
          v.visitDartType(emittedValueType!, cannotRemoveSentinel);
    }
    if (redirectingFactoryTarget?.typeArguments != null) {
      v.transformDartTypeList(redirectingFactoryTarget!.typeArguments!);
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
