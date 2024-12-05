// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../../ast.dart';

/// Declaration of a type alias.
class Typedef extends NamedNode
    implements FileUriNode, Annotatable, GenericDeclaration {
  /// The URI of the source file that contains the declaration of this typedef.
  @override
  Uri fileUri;

  @override
  List<Expression> annotations = const <Expression>[];

  String name;

  @override
  final List<TypeParameter> typeParameters;

  // TODO(johnniwinther): Make this non-nullable.
  DartType? type;

  Typedef(this.name, this.type,
      {Reference? reference,
      required this.fileUri,
      List<TypeParameter>? typeParameters,
      List<TypeParameter>? typeParametersOfFunctionType,
      List<VariableDeclaration>? positionalParameters,
      List<VariableDeclaration>? namedParameters})
      : this.typeParameters = typeParameters ?? <TypeParameter>[],
        super(reference) {
    setParents(this.typeParameters, this);
  }

  @override
  void bindCanonicalNames(CanonicalName parent) {
    parent.getChildFromTypedef(this).bindTo(reference);
  }

  Library get enclosingLibrary => parent as Library;

  @override
  R accept<R>(TreeVisitor<R> v) => v.visitTypedef(this);

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) => v.visitTypedef(this, arg);

  @override
  void visitChildren(Visitor v) {
    visitList(annotations, v);
    visitList(typeParameters, v);
    type?.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    v.transformList(annotations, this);
    v.transformList(typeParameters, this);
    if (type != null) {
      type = v.visitDartType(type!);
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformExpressionList(annotations, this);
    v.transformTypeParameterList(typeParameters, this);
    if (type != null) {
      DartType newType = v.visitDartType(type!, dummyDartType);
      if (identical(newType, dummyDartType)) {
        type = null;
      } else {
        type = newType;
      }
    }
  }

  @override
  void addAnnotation(Expression node) {
    if (annotations.isEmpty) {
      annotations = <Expression>[];
    }
    annotations.add(node);
    node.parent = this;
  }

  @override
  Location? _getLocationInEnclosingFile(int offset) {
    return _getLocationInComponent(enclosingComponent, fileUri, offset,
        viaForErrorMessage: "Typedef '$name'");
  }

  @override
  String toString() {
    return "Typedef(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeTypedefName(reference);
  }
}
