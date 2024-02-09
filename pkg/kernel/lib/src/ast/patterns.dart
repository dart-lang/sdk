// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../../ast.dart';

sealed class Pattern extends TreeNode {
  /// Variable declarations induced by nested variable patterns.
  ///
  /// These variables are initialized to the values captured by the variable
  /// patterns nested in the pattern.
  List<VariableDeclaration> get declaredVariables;

  @override
  R accept<R>(PatternVisitor<R> visitor);

  @override
  R accept1<R, A>(PatternVisitor1<R, A> visitor, A arg);

  /// Returns the variable name that this pattern defines, if any.
  ///
  /// This is used to derive an implicit variable name from a pattern to use
  /// on object patterns. For instance
  ///
  ///    if (o case Foo(:var bar, :var baz!)) { ... }
  ///
  /// the getter names 'bar' and 'baz' are implicitly defined by the patterns.
  String? get variableName => null;
}

/// A [Pattern] based on a constant [Expression].
class ConstantPattern extends Pattern {
  Expression expression;

  /// Static type of the expression as computed during inference.
  DartType? expressionType;

  /// Reference to the `operator ==` procedure on [expression].
  ///
  /// This is set during inference.
  Reference? equalsTargetReference;

  /// The type of the `operator ==` procedure on [expression].
  ///
  /// This is set during inference.
  FunctionType? equalsType;

  /// The [Constant] value for this constant pattern.
  ///
  /// This is set during constant evaluation.
  Constant? value;

  ConstantPattern(this.expression) {
    expression.parent = this;
  }

  /// The `operator ==` procedure on [expression].
  ///
  /// This is set during inference.
  Procedure get equalsTarget => equalsTargetReference!.asProcedure;

  void set equalsTarget(Procedure value) {
    equalsTargetReference = value.reference;
  }

  @override
  List<VariableDeclaration> get declaredVariables => const [];

  @override
  R accept<R>(PatternVisitor<R> visitor) => visitor.visitConstantPattern(this);

  @override
  R accept1<R, A>(PatternVisitor1<R, A> visitor, A arg) =>
      visitor.visitConstantPattern(this, arg);

  @override
  void transformChildren(Transformer v) {
    expression = v.transform(expression)..parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    expression = v.transform(expression)..parent = this;
  }

  @override
  void visitChildren(Visitor v) {
    expression.accept(v);
  }

  @override
  void toTextInternal(AstPrinter printer) {
    expression.toTextInternal(printer);
  }

  @override
  String toString() {
    return "ConstantPattern(${toStringInternal()})";
  }
}

/// A [Pattern] for `pattern && pattern`.
class AndPattern extends Pattern {
  Pattern left;
  Pattern right;

  @override
  List<VariableDeclaration> get declaredVariables =>
      [...left.declaredVariables, ...right.declaredVariables];

  AndPattern(this.left, this.right) {
    left.parent = this;
    right.parent = this;
  }

  @override
  R accept<R>(PatternVisitor<R> visitor) => visitor.visitAndPattern(this);

  @override
  R accept1<R, A>(PatternVisitor1<R, A> visitor, A arg) =>
      visitor.visitAndPattern(this, arg);

  @override
  void transformChildren(Transformer v) {
    left = v.transform(left)..parent = this;
    right = v.transform(right)..parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    left = v.transform(left)..parent = this;
    right = v.transform(right)..parent = this;
  }

  @override
  void visitChildren(Visitor v) {
    left.accept(v);
    right.accept(v);
  }

  @override
  void toTextInternal(AstPrinter printer) {
    left.toTextInternal(printer);
    printer.write(' && ');
    right.toTextInternal(printer);
  }

  @override
  String toString() {
    return "AndPattern(${toStringInternal()})";
  }
}

/// A [Pattern] for `pattern || pattern`.
class OrPattern extends Pattern {
  Pattern left;
  Pattern right;

  final List<VariableDeclaration> orPatternJointVariables;

  @override
  List<VariableDeclaration> get declaredVariables => orPatternJointVariables;

  OrPattern(this.left, this.right,
      {required List<VariableDeclaration> orPatternJointVariables})
      : orPatternJointVariables = orPatternJointVariables {
    left.parent = this;
    right.parent = this;
  }

  @override
  R accept<R>(PatternVisitor<R> visitor) => visitor.visitOrPattern(this);

  @override
  R accept1<R, A>(PatternVisitor1<R, A> visitor, A arg) =>
      visitor.visitOrPattern(this, arg);

  @override
  void transformChildren(Transformer v) {
    left = v.transform(left)..parent = this;
    right = v.transform(right)..parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    left = v.transform(left)..parent = this;
    right = v.transform(right)..parent = this;
  }

  @override
  void visitChildren(Visitor v) {
    left.accept(v);
    right.accept(v);
  }

  @override
  void toTextInternal(AstPrinter printer) {
    left.toTextInternal(printer);
    printer.write(' || ');
    right.toTextInternal(printer);
  }

  @override
  String toString() {
    return "OrPattern(${toStringInternal()})";
  }
}

/// A [Pattern] for `pattern as type`.
class CastPattern extends Pattern {
  Pattern pattern;
  DartType type;

  CastPattern(this.pattern, this.type) {
    pattern.parent = this;
  }

  @override
  String? get variableName => pattern.variableName;

  @override
  List<VariableDeclaration> get declaredVariables => pattern.declaredVariables;

  @override
  R accept<R>(PatternVisitor<R> visitor) => visitor.visitCastPattern(this);

  @override
  R accept1<R, A>(PatternVisitor1<R, A> visitor, A arg) =>
      visitor.visitCastPattern(this, arg);

  @override
  void transformChildren(Transformer v) {
    pattern = v.transform(pattern)..parent = this;
    type = v.visitDartType(type);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    pattern = v.transform(pattern)..parent = this;
    type = v.visitDartType(type, cannotRemoveSentinel);
  }

  @override
  void visitChildren(Visitor v) {
    pattern.accept(v);
    type.accept(v);
  }

  @override
  void toTextInternal(AstPrinter printer) {
    pattern.toTextInternal(printer);
    printer.write(' as ');
    printer.writeType(type);
  }

  @override
  String toString() {
    return "CastPattern(${toStringInternal()})";
  }
}

/// A [Pattern] for `pattern!`.
class NullAssertPattern extends Pattern {
  Pattern pattern;

  NullAssertPattern(this.pattern) {
    pattern.parent = this;
  }

  @override
  String? get variableName => pattern.variableName;

  @override
  List<VariableDeclaration> get declaredVariables => pattern.declaredVariables;

  @override
  R accept<R>(PatternVisitor<R> visitor) =>
      visitor.visitNullAssertPattern(this);

  @override
  R accept1<R, A>(PatternVisitor1<R, A> visitor, A arg) =>
      visitor.visitNullAssertPattern(this, arg);

  @override
  void transformChildren(Transformer v) {
    pattern = v.transform(pattern)..parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    pattern = v.transform(pattern)..parent = this;
  }

  @override
  void visitChildren(Visitor v) {
    pattern.accept(v);
  }

  @override
  void toTextInternal(AstPrinter printer) {
    pattern.toTextInternal(printer);
    printer.write('!');
  }

  @override
  String toString() {
    return "NullAssertPattern(${toStringInternal()})";
  }
}

/// A [Pattern] for `pattern?`.
class NullCheckPattern extends Pattern {
  Pattern pattern;

  NullCheckPattern(this.pattern) {
    pattern.parent = this;
  }

  @override
  String? get variableName => pattern.variableName;

  @override
  List<VariableDeclaration> get declaredVariables => pattern.declaredVariables;

  @override
  R accept<R>(PatternVisitor<R> visitor) => visitor.visitNullCheckPattern(this);

  @override
  R accept1<R, A>(PatternVisitor1<R, A> visitor, A arg) =>
      visitor.visitNullCheckPattern(this, arg);

  @override
  void transformChildren(Transformer v) {
    pattern = v.transform(pattern)..parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    pattern = v.transform(pattern)..parent = this;
  }

  @override
  void visitChildren(Visitor v) {
    pattern.accept(v);
  }

  @override
  void toTextInternal(AstPrinter printer) {
    pattern.toTextInternal(printer);
    printer.write('?');
  }

  @override
  String toString() {
    return "NullCheckPattern(${toStringInternal()})";
  }
}

/// A [Pattern] for `<typeArgument>[pattern0, ... patternN]`.
class ListPattern extends Pattern {
  /// The element type argument as specified by the list pattern syntax.
  DartType? typeArgument;

  List<Pattern> patterns;

  /// The required type of the pattern.
  ///
  /// This is the type the matched expression is checked against, if the
  /// [matchedValueType] is not already a subtype of [requiredType].
  ///
  /// This is set during inference.
  DartType? requiredType;

  /// The type of the expression against which this pattern is matched.
  ///
  /// This is set during inference.
  DartType? matchedValueType;

  /// If `true`, the matched expression must be checked to be a `List`.
  ///
  /// This is set during inference.
  bool needsCheck = false;

  /// The most specific type of the matched expression. Either the
  /// [requiredType] or the [matchedValueType] if it is a subtype of
  /// [requiredType].
  ///
  /// This is the type on which pattern accesses from [patterns] are looked up.
  ///
  /// This is set during inference.
  DartType? lookupType;

  /// If `true`, this list pattern contains a rest pattern.
  ///
  /// This is set during inference.
  bool hasRestPattern = false;

  /// Reference to the target of the `length` property of the list.
  ///
  /// This is set during inference.
  Reference? lengthTargetReference;

  /// The type of the `length` property of the list.
  ///
  /// This is set during inference.
  DartType? lengthType;

  /// Reference to the method used to check the `length` of the list.
  ///
  /// If this pattern has a rest pattern, this is an `operator >=` method.
  /// Otherwise this is an `operator ==` method.
  ///
  /// This is set during inference.
  Reference? lengthCheckTargetReference;

  /// The type of the method used to check the `length` of the list.
  ///
  /// If this pattern has a rest pattern, this is an `operator >=` method.
  /// Otherwise this is an `operator ==` method.
  ///
  /// This is set during inference.
  FunctionType? lengthCheckType;

  /// Reference to the target of the `sublist` method of the list.
  ///
  /// This is used if this pattern has a rest pattern with a subpattern.
  ///
  /// This is set during inference.
  Reference? sublistTargetReference;

  /// The type of the `sublist` method of the list.
  ///
  /// This is used if this pattern has a rest pattern with a subpattern.
  ///
  /// This is set during inference.
  FunctionType? sublistType;

  /// Reference to the target of the `minus` method of the `length` of this
  /// list.
  ///
  /// This is used to compute tail indices if this pattern has a rest pattern.
  ///
  /// This is set during inference.
  Reference? minusTargetReference;

  /// The type of the `minus` method of the `length` of this list.
  ///
  /// This is used to compute tail indices if this pattern has a rest pattern.
  ///
  /// This is set during inference.
  FunctionType? minusType;

  /// Reference to the target of the `operator []` method of the list.
  ///
  /// This is set during inference.
  Reference? indexGetTargetReference;

  /// The type of the `operator []` method of the list.
  ///
  /// This is set during inference.
  FunctionType? indexGetType;

  @override
  List<VariableDeclaration> get declaredVariables =>
      [for (Pattern pattern in patterns) ...pattern.declaredVariables];

  ListPattern(this.typeArgument, this.patterns) {
    setParents(patterns, this);
  }

  /// The target of the `length` property of the list.
  ///
  /// This is set during inference.
  Member get lengthTarget => lengthTargetReference!.asMember;

  void set lengthTarget(Member value) {
    lengthTargetReference = value.reference;
  }

  /// The method used to check the `length` of the list.
  ///
  /// If this pattern has a rest pattern, this is an `operator >=` method. If
  /// this is the empty list pattern, this an `operator <=` method. Otherwise
  /// this is an `operator ==` method.
  ///
  /// This is set during inference.
  Procedure get lengthCheckTarget => lengthCheckTargetReference!.asProcedure;

  void set lengthCheckTarget(Procedure value) {
    lengthCheckTargetReference = value.reference;
  }

  /// The target of the `sublist` method of the list.
  ///
  /// This is used if this pattern has a rest pattern with a subpattern.
  ///
  /// This is set during inference.
  Procedure get sublistTarget => sublistTargetReference!.asProcedure;

  void set sublistTarget(Procedure value) {
    sublistTargetReference = value.reference;
  }

  /// The target of the `minus` method of the `length` of this list.
  ///
  /// This is used to compute tail indices if this pattern has a rest pattern.
  ///
  /// This is set during inference.
  Procedure get minusTarget => minusTargetReference!.asProcedure;

  void set minusTarget(Procedure value) {
    minusTargetReference = value.reference;
  }

  /// The target of the `operator []` method of the list.
  ///
  /// This is set during inference.
  Procedure get indexGetTarget => indexGetTargetReference!.asProcedure;

  void set indexGetTarget(Procedure value) {
    indexGetTargetReference = value.reference;
  }

  @override
  R accept<R>(PatternVisitor<R> visitor) => visitor.visitListPattern(this);

  @override
  R accept1<R, A>(PatternVisitor1<R, A> visitor, A arg) =>
      visitor.visitListPattern(this, arg);

  @override
  void transformChildren(Transformer v) {
    if (typeArgument != null) {
      typeArgument = v.visitDartType(typeArgument!);
    }
    v.transformList(patterns, this);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    if (typeArgument != null) {
      DartType newTypeArgument = v.visitDartType(typeArgument!, dummyDartType);
      if (identical(newTypeArgument, dummyDartType)) {
        typeArgument = null;
      } else {
        typeArgument = newTypeArgument;
      }
    }
    v.transformList(patterns, this, dummyPattern);
  }

  @override
  void visitChildren(Visitor v) {
    typeArgument?.accept(v);
    visitList(patterns, v);
  }

  @override
  void toTextInternal(AstPrinter printer) {
    if (typeArgument != null) {
      printer.write('<');
      printer.writeType(typeArgument!);
      printer.write('>');
    }
    printer.write('[');
    String comma = '';
    for (Pattern pattern in patterns) {
      printer.write(comma);
      pattern.toTextInternal(printer);
      comma = ', ';
    }
    printer.write(']');
  }

  @override
  String toString() {
    return "ListPattern(${toStringInternal()})";
  }
}

class ObjectPattern extends Pattern {
  /// The type specified as part of the object pattern syntax.
  ///
  /// This is the type the matched expression is checked against, if the
  /// [matchedValueType] is not already a subtype of [requiredType].
  ///
  /// This is the type on which pattern accesses from [fields] are looked up.
  ///
  /// This is set during inference.
  DartType requiredType;

  final List<NamedPattern> fields;

  /// The type of the expression against which this pattern is matched.
  ///
  /// This is set during inference.
  DartType? matchedValueType;

  /// If `true`, the matched expression must be checked to be of type
  /// [requiredType].
  ///
  /// This is set during inference.
  bool needsCheck = false;

  /// The most specific type of the matched expression. Either the
  /// [requiredType] or the [matchedValueType] if it is a subtype of
  /// [requiredType].
  ///
  /// This is set during inference.
  // TODO(johnniwinther): Remove this field. It is no longer used.
  DartType? lookupType;

  ObjectPattern(this.requiredType, this.fields) {
    setParents(fields, this);
  }

  @override
  R accept<R>(PatternVisitor<R> visitor) => visitor.visitObjectPattern(this);

  @override
  R accept1<R, A>(PatternVisitor1<R, A> visitor, A arg) =>
      visitor.visitObjectPattern(this, arg);

  @override
  void transformChildren(Transformer v) {
    requiredType = v.visitDartType(requiredType);
    v.transformList(fields, this);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    requiredType = v.visitDartType(requiredType, cannotRemoveSentinel);
    v.transformList(fields, this, dummyNamedPattern);
  }

  @override
  void visitChildren(Visitor v) {
    requiredType.accept(v);
    visitList(fields, v);
  }

  @override
  List<VariableDeclaration> get declaredVariables {
    return [for (NamedPattern field in fields) ...field.declaredVariables];
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeType(requiredType);
    printer.write('(');
    String comma = '';
    for (Pattern field in fields) {
      printer.write(comma);
      field.toTextInternal(printer);
      comma = ', ';
    }
    printer.write(')');
  }

  @override
  String toString() {
    return "ObjectPattern(${toStringInternal()})";
  }
}

enum RelationalPatternKind {
  equals,
  notEquals,
  lessThan,
  lessThanEqual,
  greaterThan,
  greaterThanEqual,
}

/// A [Pattern] for `operator expression` where `operator  is either ==, !=,
/// <, <=, >, or >=.
class RelationalPattern extends Pattern {
  final RelationalPatternKind kind;
  Expression expression;

  /// The type of the [expression].
  ///
  /// This is set during inference.
  DartType? expressionType;

  /// The type of the expression against which this pattern is matched.
  ///
  /// This is set during inference.
  DartType? matchedValueType;

  /// The access kind for performing the relational operation of this pattern.
  ///
  /// This is set during inference.
  RelationalAccessKind accessKind = RelationalAccessKind.Invalid;

  /// The name of the relational operation called by this pattern.
  ///
  /// This is set during inference.
  Name? name;

  /// Reference to the target [Procedure] called by this pattern.
  ///
  /// This is used for [RelationalAccessKind.Instance] and
  /// [RelationalAccessKind.Static].
  ///
  /// This is set during inference.
  Reference? targetReference;

  /// The type arguments passed to [target].
  ///
  /// This is used for [RelationalAccessKind.Static].
  ///
  /// This is set during inference.
  List<DartType>? typeArguments;

  /// The type of [target].
  ///
  /// This is used for [RelationalAccessKind.Instance] and
  /// [RelationalAccessKind.Static].
  ///
  /// This is set during inference.
  FunctionType? functionType;

  /// The [Constant] value for the [expression].
  ///
  /// This is set during constant evaluation.
  Constant? expressionValue;

  RelationalPattern(this.kind, this.expression) {
    expression.parent = this;
  }

  /// The target [Procedure] called by this pattern.
  ///
  /// This is used for [RelationalAccessKind.Instance] and
  /// [RelationalAccessKind.Static].
  ///
  /// This is set during inference.
  Procedure? get target => targetReference?.asProcedure;

  void set target(Procedure? value) {
    targetReference = value?.reference;
  }

  @override
  List<VariableDeclaration> get declaredVariables => const [];

  @override
  R accept<R>(PatternVisitor<R> visitor) =>
      visitor.visitRelationalPattern(this);

  @override
  R accept1<R, A>(PatternVisitor1<R, A> visitor, A arg) =>
      visitor.visitRelationalPattern(this, arg);

  @override
  void transformChildren(Transformer v) {
    expression = v.transform(expression)..parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    expression = v.transform(expression)..parent = this;
  }

  @override
  void visitChildren(Visitor v) {
    expression.accept(v);
  }

  @override
  void toTextInternal(AstPrinter printer) {
    switch (kind) {
      case RelationalPatternKind.equals:
        printer.write('== ');
        break;
      case RelationalPatternKind.notEquals:
        printer.write('!= ');
        break;
      case RelationalPatternKind.lessThan:
        printer.write('< ');
        break;
      case RelationalPatternKind.lessThanEqual:
        printer.write('<= ');
        break;
      case RelationalPatternKind.greaterThan:
        printer.write('> ');
        break;
      case RelationalPatternKind.greaterThanEqual:
        printer.write('>= ');
        break;
    }
    printer.writeExpression(expression);
  }

  @override
  String toString() {
    return "RelationalPattern(${toStringInternal()})";
  }
}

class WildcardPattern extends Pattern {
  DartType? type;

  WildcardPattern(this.type);

  @override
  List<VariableDeclaration> get declaredVariables => const [];

  @override
  R accept<R>(PatternVisitor<R> visitor) => visitor.visitWildcardPattern(this);

  @override
  R accept1<R, A>(PatternVisitor1<R, A> visitor, A arg) =>
      visitor.visitWildcardPattern(this, arg);

  @override
  void transformChildren(Transformer v) {
    if (type != null) {
      type = v.visitDartType(type!);
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
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
  void visitChildren(Visitor v) {
    type?.accept(v);
  }

  @override
  void toTextInternal(AstPrinter printer) {
    if (type != null) {
      type!.toTextInternal(printer);
      printer.write(" ");
    }
    printer.write("_");
  }

  @override
  String toString() {
    return "WildcardPattern(${toStringInternal()})";
  }
}

class AssignedVariablePattern extends Pattern {
  final VariableDeclaration variable;

  /// The type of the expression against which this pattern is matched.
  ///
  /// This is set during inference.
  DartType? matchedValueType;

  /// If `true`, the matched expression must be checked to be of the type
  /// of [variable].
  ///
  /// This is set during inference.
  bool needsCast = false;

  /// If `true`, the assignment occurs in a context where effects can be
  /// observed and must therefore be postponed until the whole pattern has been
  /// evaluated.
  ///
  /// This is used an optimized encoding of pattern assignment. It is sound to
  /// assume that all [AssignedVariablePattern]s have an observable effect.
  ///
  /// For instance
  ///
  ///     class A {
  ///       get b => throw 'foo';
  ///     }
  ///     class B extends A {
  ///       get b => 42;
  ///     }
  ///     method(A a) {
  ///       var b1;
  ///       var b2;
  ///       A(b: b1) = a;
  ///       try {
  ///         A(b: b2) = a;
  ///       } catch (_) {
  ///       }
  ///       print(b1);
  ///       print(b2);
  ///     }
  ///
  /// Here the assignment to `b2` has an observable effect where as `b1` has
  /// not.
  bool hasObservableEffect = true;

  AssignedVariablePattern(this.variable);

  @override
  R accept<R>(PatternVisitor<R> visitor) =>
      visitor.visitAssignedVariablePattern(this);

  @override
  R accept1<R, A>(PatternVisitor1<R, A> visitor, A arg) =>
      visitor.visitAssignedVariablePattern(this, arg);

  @override
  void transformChildren(Transformer v) {}

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {}

  @override
  void visitChildren(Visitor v) {}

  @override
  List<VariableDeclaration> get declaredVariables => const [];

  @override
  String? get variableName => variable.name!;

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write(variable.name!);
  }

  @override
  String toString() {
    return "AssignedVariablePattern(${toStringInternal()})";
  }
}

class MapPattern extends Pattern {
  /// The key type arguments as specific in the map pattern syntax.
  DartType? keyType;

  /// The value type arguments as specific in the map pattern syntax.
  DartType? valueType;

  final List<MapPatternEntry> entries;

  /// The required type of the pattern.
  ///
  /// This is the type the matched expression is checked against, if the
  /// [matchedValueType] is not already a subtype of [requiredType].
  ///
  /// This is set during inference.
  DartType? requiredType;

  /// The type of the expression against which this pattern is matched.
  ///
  /// This is set during inference.
  DartType? matchedValueType;

  /// If `true`, the matched expression must be checked to be a `Map`.
  ///
  /// This is set during inference.
  bool needsCheck = false;

  /// The most specific type of the matched expression. Either the
  /// [requiredType] or the [matchedValueType] if it is a subtype of
  /// [requiredType].
  ///
  /// This is the type on which pattern accesses from [entries] are looked up.
  ///
  /// This is set during inference.
  DartType? lookupType;

  /// Reference to the target of the `containsKey` method of the map.
  ///
  /// This is set during inference.
  Reference? containsKeyTargetReference;

  /// The type of the `containsKey` method of the map.
  ///
  /// This is set during inference.
  FunctionType? containsKeyType;

  /// Reference to the target of the `operator []` method of the map.
  ///
  /// This is set during inference.
  Reference? indexGetTargetReference;

  /// The type of the `operator []` method of the map.
  ///
  /// This is set during inference.
  FunctionType? indexGetType;

  @override
  List<VariableDeclaration> get declaredVariables => [
        for (MapPatternEntry entry in entries)
          if (entry is! MapPatternRestEntry) ...entry.value.declaredVariables
      ];

  MapPattern(this.keyType, this.valueType, this.entries)
      : assert((keyType == null) == (valueType == null)) {
    setParents(entries, this);
  }

  /// The target of the `containsKey` method of the map.
  ///
  /// This is set during inference.
  Procedure get containsKeyTarget => containsKeyTargetReference!.asProcedure;

  void set containsKeyTarget(Procedure value) {
    containsKeyTargetReference = value.reference;
  }

  /// The target of the `operator []` method of the map.
  ///
  /// This is set during inference.
  Procedure get indexGetTarget => indexGetTargetReference!.asProcedure;
  void set indexGetTarget(Procedure value) {
    indexGetTargetReference = value.reference;
  }

  @override
  R accept<R>(PatternVisitor<R> visitor) => visitor.visitMapPattern(this);

  @override
  R accept1<R, A>(PatternVisitor1<R, A> visitor, A arg) =>
      visitor.visitMapPattern(this, arg);

  @override
  void transformChildren(Transformer v) {
    if (keyType != null) {
      keyType = v.visitDartType(keyType!);
    }
    if (valueType != null) {
      valueType = v.visitDartType(valueType!);
    }
    v.transformList(entries, this);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    if (keyType != null) {
      DartType newType = v.visitDartType(keyType!, dummyDartType);
      if (identical(newType, dummyDartType)) {
        keyType = null;
      } else {
        keyType = newType;
      }
    }
    if (valueType != null) {
      DartType newType = v.visitDartType(valueType!, dummyDartType);
      if (identical(newType, dummyDartType)) {
        valueType = null;
      } else {
        valueType = newType;
      }
    }
    v.transformList(entries, this, dummyMapPatternEntry);
  }

  @override
  void visitChildren(Visitor v) {
    keyType?.accept(v);
    valueType?.accept(v);
    visitList(entries, v);
  }

  @override
  void toTextInternal(AstPrinter printer) {
    if (keyType != null && valueType != null) {
      printer.writeTypeArguments([keyType!, valueType!]);
    }
    printer.write('{');
    String comma = '';
    for (MapPatternEntry entry in entries) {
      printer.write(comma);
      entry.toTextInternal(printer);
      comma = ', ';
    }
    printer.write('}');
  }

  @override
  String toString() {
    return 'MapPattern(${toStringInternal()})';
  }
}

class NamedPattern extends Pattern {
  final String name;
  Pattern pattern;

  /// When used in an object pattern, this holds the named of the property
  /// accessed by this pattern.
  ///
  /// This is set during inference.
  Name fieldName = new Name('#');

  /// When used in an object pattern, this holds the access kind of used for
  /// reading the property value for this pattern.
  ///
  /// This is set during inference.
  ObjectAccessKind accessKind = ObjectAccessKind.Invalid;

  /// When used in an object pattern, this holds the reference to the target
  /// [Member] used to read the property for this pattern.
  ///
  /// This is used for [ObjectAccessKind.Object], [ObjectAccessKind.Instance],
  /// and [ObjectAccessKind.Static].
  ///
  /// This is set during inference.
  Reference? targetReference;

  /// When used in an object pattern, this holds the static property type for
  /// this pattern.
  ///
  /// This is used for [ObjectAccessKind.Object], [ObjectAccessKind.Instance],
  /// and [ObjectAccessKind.Static].
  ///
  /// This is set during inference.
  DartType? resultType;

  /// When used in an object pattern, this is set to `true` if the field value
  /// needs to be checked against the [resultType]. This is needed for fields
  /// whose type contain covariant types that occur in non-covariant positions.
  bool checkReturn = false;

  /// When used in an object pattern, this holds the record on which the
  /// property for this pattern is read.
  ///
  /// This is used for [ObjectAccessKind.RecordNamed] and
  /// [ObjectAccessKind.RecordIndexed].
  ///
  /// This is set during inference.
  RecordType? recordType;

  /// When used in an object pattern, this holds the record field index from
  /// which the property for this pattern is read.
  ///
  /// This is used for [ObjectAccessKind.RecordIndexed].
  ///
  /// This is set during inference.
  int recordFieldIndex = -1;

  /// When used in an object pattern, this holds the function type of [target]
  /// called to read the property for this pattern.
  ///
  /// This is set during inference.
  // TODO(johnniwinther): Remove this. This is no longer used.
  FunctionType? functionType;

  /// When used in an object pattern, this holds the type arguments used when
  /// called the [target] to read the property for this pattern.
  ///
  /// This is used for [ObjectAccessKind.Static].
  ///
  /// This is set during inference.
  List<DartType>? typeArguments;

  @override
  List<VariableDeclaration> get declaredVariables => pattern.declaredVariables;

  NamedPattern(this.name, this.pattern) {
    pattern.parent = this;
  }

  /// When used in an object pattern, this holds the target [Member] used to
  /// read the property for this pattern.
  ///
  /// This is used for [ObjectAccessKind.Object], [ObjectAccessKind.Instance],
  /// and [ObjectAccessKind.Static].
  ///
  /// This is set during inference.
  Member? get target => targetReference?.asMember;

  void set target(Member? value) {
    targetReference = value?.reference;
  }

  @override
  R accept<R>(PatternVisitor<R> visitor) => visitor.visitNamedPattern(this);

  @override
  R accept1<R, A>(PatternVisitor1<R, A> visitor, A arg) =>
      visitor.visitNamedPattern(this, arg);

  @override
  void transformChildren(Transformer v) {
    pattern = v.transform(pattern)..parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    pattern = v.transform(pattern)..parent = this;
  }

  @override
  void visitChildren(Visitor v) {
    pattern.accept(v);
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write(name);
    printer.write(': ');
    pattern.toTextInternal(printer);
  }

  @override
  String toString() {
    return 'NamedPattern(${toStringInternal()})';
  }
}

class RecordPattern extends Pattern {
  final List<Pattern> patterns;

  /// The required type of the pattern.
  ///
  /// This is the type the matched expression is checked against, if the
  /// [matchedValueType] is not already a subtype of [requiredType].
  ///
  /// This is set during inference.
  RecordType? requiredType;

  /// The type of the expression against which this pattern is matched.
  ///
  /// This is set during inference.
  DartType? matchedValueType;

  /// If `true`, the matched expression must be checked to be of type
  /// [requiredType].
  ///
  /// This is set during inference.
  bool needsCheck = false;

  /// The most specific type of the matched expression. Either the
  /// [requiredType] or the [matchedValueType] if it is a subtype of
  /// [requiredType].
  ///
  /// This is the type on which pattern accesses from [patterns] are looked up.
  ///
  /// This is set during inference.
  RecordType? lookupType;

  @override
  List<VariableDeclaration> get declaredVariables =>
      [for (Pattern pattern in patterns) ...pattern.declaredVariables];

  RecordPattern(this.patterns) {
    setParents(patterns, this);
  }

  @override
  R accept<R>(PatternVisitor<R> visitor) => visitor.visitRecordPattern(this);

  @override
  R accept1<R, A>(PatternVisitor1<R, A> visitor, A arg) =>
      visitor.visitRecordPattern(this, arg);

  @override
  void transformChildren(Transformer v) {
    v.transformList(patterns, this);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformList(patterns, this, dummyPattern);
  }

  @override
  void visitChildren(Visitor v) {
    visitList(patterns, v);
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('(');
    String comma = '';
    for (Pattern pattern in patterns) {
      printer.write(comma);
      pattern.toTextInternal(printer);
      comma = ', ';
    }
    printer.write(')');
  }

  @override
  String toString() {
    return 'RecordPattern(${toStringInternal()})';
  }
}

class VariablePattern extends Pattern {
  // TODO(johnniwinther): Should this be accessed through [variable] instead?
  DartType? type;
  VariableDeclaration variable;

  /// The type of the expression against which this pattern is matched.
  ///
  /// This is set during inference.
  DartType? matchedValueType;

  @override
  List<VariableDeclaration> get declaredVariables => [variable];

  VariablePattern(this.type, this.variable) {
    variable.parent = this;
  }

  @override
  String? get variableName => variable.name;

  @override
  R accept<R>(PatternVisitor<R> visitor) => visitor.visitVariablePattern(this);

  @override
  R accept1<R, A>(PatternVisitor1<R, A> visitor, A arg) =>
      visitor.visitVariablePattern(this, arg);

  @override
  void transformChildren(Transformer v) {
    if (type != null) {
      type = v.visitDartType(type!);
    }
    variable = v.transform(variable)..parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    if (type != null) {
      DartType newType = v.visitDartType(type!, dummyDartType);
      if (identical(newType, dummyDartType)) {
        type = null;
      } else {
        type = newType;
      }
    }
    variable = v.transform(variable)..parent = this;
  }

  @override
  void visitChildren(Visitor v) {
    type?.accept(v);
    variable.accept(v);
  }

  @override
  void toTextInternal(AstPrinter printer) {
    if (type != null) {
      type!.toTextInternal(printer);
      printer.write(" ");
    } else {
      printer.write("var ");
    }
    printer.write(variable.name!);
  }

  @override
  String toString() {
    return "VariablePattern(${toStringInternal()})";
  }
}

class RestPattern extends Pattern {
  Pattern? subPattern;

  RestPattern(this.subPattern) {
    subPattern?.parent = this;
  }

  @override
  R accept<R>(PatternVisitor<R> visitor) => visitor.visitRestPattern(this);

  @override
  R accept1<R, A>(PatternVisitor1<R, A> visitor, A arg) =>
      visitor.visitRestPattern(this, arg);

  @override
  void transformChildren(Transformer v) {
    if (subPattern != null) {
      subPattern = v.transform(subPattern!)..parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    if (subPattern != null) {
      subPattern = v.transform(subPattern!)..parent = this;
    }
  }

  @override
  void visitChildren(Visitor v) {
    subPattern?.accept(v);
  }

  @override
  List<VariableDeclaration> get declaredVariables =>
      subPattern?.declaredVariables ?? const [];

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('...');
    if (subPattern != null) {
      subPattern!.toTextInternal(printer);
    }
  }

  @override
  String toString() {
    return "RestPattern(${toStringInternal()})";
  }
}

class InvalidPattern extends Pattern {
  Expression invalidExpression;

  @override
  final List<VariableDeclaration> declaredVariables;

  InvalidPattern(this.invalidExpression, {required this.declaredVariables}) {
    invalidExpression.parent = this;
    setParents(declaredVariables, this);
  }

  @override
  R accept<R>(PatternVisitor<R> visitor) => visitor.visitInvalidPattern(this);

  @override
  R accept1<R, A>(PatternVisitor1<R, A> visitor, A arg) =>
      visitor.visitInvalidPattern(this, arg);

  @override
  void transformChildren(Transformer v) {
    invalidExpression = v.transform(invalidExpression)..parent = this;
    v.transformList(declaredVariables, this);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    invalidExpression = v.transform(invalidExpression)..parent = this;
    v.transformVariableDeclarationList(declaredVariables, this);
  }

  @override
  void visitChildren(Visitor v) {
    invalidExpression.accept(v);
    visitList(declaredVariables, v);
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(invalidExpression);
  }

  @override
  String toString() {
    return "InvalidPattern(${toStringInternal()})";
  }
}

class MapPatternEntry extends TreeNode {
  Expression key;
  Pattern value;

  DartType? keyType;

  /// The [Constant] value for the [key] expression.
  ///
  /// This is set during constant evaluation.
  Constant? keyValue;

  MapPatternEntry(this.key, this.value) {
    key.parent = this;
    value.parent = this;
  }

  @override
  R accept<R>(TreeVisitor<R> v) {
    return v.visitMapPatternEntry(this);
  }

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) {
    return v.visitMapPatternEntry(this, arg);
  }

  @override
  void transformChildren(Transformer v) {
    key = v.transform(key)..parent = this;
    if (keyType != null) {
      keyType = v.visitDartType(keyType!);
    }
    value = v.transform(value)..parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    key = v.transform(key)..parent = this;
    if (keyType != null) {
      keyType = v.visitDartType(keyType!, cannotRemoveSentinel);
    }
    value = v.transform(value)..parent = this;
  }

  @override
  void visitChildren(Visitor v) {
    key.accept(v);
    keyType?.accept(v);
    value.accept(v);
  }

  @override
  void toTextInternal(AstPrinter printer) {
    key.toTextInternal(printer);
    printer.write(': ');
    value.toTextInternal(printer);
  }

  @override
  String toString() {
    return 'MapPatternEntry(${toStringInternal()})';
  }
}

class MapPatternRestEntry extends TreeNode implements MapPatternEntry {
  MapPatternRestEntry();

  @override
  Expression get key => throw new UnsupportedError('MapPatternRestEntry.key');

  @override
  void set key(Expression value) =>
      throw new UnsupportedError('MapPatternRestEntry.key=');

  @override
  DartType? get keyType =>
      throw new UnsupportedError('MapPatternRestEntry.keyType');

  @override
  void set keyType(DartType? value) =>
      throw new UnsupportedError('MapPatternRestEntry.keyType=');

  @override
  Pattern get value => throw new UnsupportedError('MapPatternRestEntry.value');

  @override
  void set value(Pattern value) =>
      throw new UnsupportedError('MapPatternRestEntry.value=');

  @override
  Constant? get keyValue =>
      throw new UnsupportedError('MapPatternRestEntry.keyValue');

  @override
  void set keyValue(Constant? value) =>
      throw new UnsupportedError('MapPatternRestEntry.keyValue=');

  @override
  R accept<R>(TreeVisitor<R> v) {
    return v.visitMapPatternRestEntry(this);
  }

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) {
    return v.visitMapPatternRestEntry(this, arg);
  }

  @override
  void transformChildren(Transformer v) {}

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {}

  @override
  void visitChildren(Visitor v) {}

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('...');
  }

  @override
  String toString() {
    return 'MapPatternRestEntry(${toStringInternal()})';
  }
}

/// Kinds of lowerings of relational pattern operations.
enum RelationalAccessKind {
  /// Operator defined by an interface member.
  Instance,

  /// Operator defined by an extension or extension type member.
  Static,

  /// Operator accessed on a receiver of type `dynamic`.
  Dynamic,

  /// Operator accessed on a receiver of type `Never`.
  Never,

  /// Operator accessed on a receiver of an invalid type.
  Invalid,
}

/// Kinds of lowerings of objects pattern property access.
enum ObjectAccessKind {
  /// Property defined by an `Object` member.
  Object,

  /// Property defined by an interface member.
  Instance,

  /// Property defined by an extension member.
  Extension,

  /// Property defined by an extension type member.
  ExtensionType,

  /// Named record field property.
  RecordNamed,

  /// Positional record field property.
  RecordIndexed,

  /// Property accessed on a receiver of type `dynamic`.
  Dynamic,

  /// Property accessed on a receiver of type `Never`.
  Never,

  /// Property accessed on a receiver of an invalid type.
  Invalid,

  /// Access of `call` on a function.
  FunctionTearOff,

  /// Erroneous property access.
  Error,

  /// Access of an extension type representation field.
  Direct,
}

/// A [Pattern] with an optional guard [Expression].
class PatternGuard extends TreeNode {
  Pattern pattern;
  Expression? guard;

  PatternGuard(this.pattern, [this.guard]) {
    pattern.parent = this;
    guard?.parent = this;
  }

  @override
  R accept<R>(TreeVisitor<R> v) {
    return v.visitPatternGuard(this);
  }

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) {
    return v.visitPatternGuard(this, arg);
  }

  @override
  void transformChildren(Transformer v) {
    pattern = v.transform(pattern)..parent = this;
    if (guard != null) {
      guard = v.transform(guard!)..parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    pattern = v.transform(pattern)..parent = this;
    if (guard != null) {
      guard = v.transformOrRemoveExpression(guard!)?..parent = this;
    }
  }

  @override
  void visitChildren(Visitor v) {
    pattern.accept(v);
    guard?.accept(v);
  }

  @override
  void toTextInternal(AstPrinter printer) {
    pattern.toTextInternal(printer);
    if (guard != null) {
      printer.write(' when ');
      printer.writeExpression(guard!);
    }
  }

  @override
  String toString() => 'PatternGuard(${toStringInternal()})';
}

class PatternSwitchCase extends TreeNode implements SwitchCase {
  final List<int> caseOffsets;
  final List<PatternGuard> patternGuards;
  // TODO(johnniwinther): Handle this through serialization. Currently this
  // cannot be serialized because we have to way of referring to arbitrary
  // statements.
  // TODO(johnniwinther): Make this a list of [ContinueSwitchStatement]s.
  final List<Statement> labelUsers = [];

  @override
  Statement body;

  @override
  bool isDefault;

  bool hasLabel;

  final List<VariableDeclaration> jointVariables;

  // TODO(johnniwinther): Serialize this field.
  final List<int>? jointVariableFirstUseOffsets;

  PatternSwitchCase(this.caseOffsets, this.patternGuards, this.body,
      {required this.isDefault,
      required this.hasLabel,
      required this.jointVariables,
      required this.jointVariableFirstUseOffsets}) {
    setParents(patternGuards, this);
    setParents(jointVariables, this);
    body.parent = this;
  }

  @override
  List<Expression> get expressions =>
      throw new UnimplementedError('PatternSwitchCase.expressions');

  @override
  List<int> get expressionOffsets =>
      throw new UnimplementedError('PatternSwitchCase.expressionOffsets');

  @override
  R accept<R>(TreeVisitor<R> v) {
    return v.visitPatternSwitchCase(this);
  }

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) {
    return v.visitPatternSwitchCase(this, arg);
  }

  @override
  void transformChildren(Transformer v) {
    v.transformList(patternGuards, this);
    body = v.transform(body)..parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformList(patternGuards, this, dummyPatternGuard);
    body = v.transform(body)..parent = this;
  }

  @override
  void visitChildren(Visitor v) {
    visitList(patternGuards, v);
    body.accept(v);
  }

  @override
  void toTextInternal(AstPrinter printer) {
    for (int index = 0; index < patternGuards.length; index++) {
      if (index > 0) {
        printer.newLine();
      }
      printer.write('case ');
      patternGuards[index].toTextInternal(printer);
      printer.write(':');
    }
    if (isDefault) {
      if (patternGuards.isNotEmpty) {
        printer.newLine();
      }
      printer.write('default:');
    }
    printer.incIndentation();
    Statement? block = body;
    if (block is Block) {
      for (Statement statement in block.statements) {
        printer.newLine();
        printer.writeStatement(statement);
      }
    } else {
      printer.write(' ');
      printer.writeStatement(body);
    }
    printer.decIndentation();
  }

  @override
  String toString() {
    return "PatternSwitchCase(${toStringInternal()})";
  }
}

class PatternSwitchStatement extends Statement implements SwitchStatement {
  @override
  Expression expression;

  @override
  final List<PatternSwitchCase> cases;

  /// The type of the [expression].
  ///
  /// This is set during inference.
  @override
  DartType? expressionTypeInternal;

  /// `true` if the last case terminates.
  ///
  /// This is set during inference.
  // TODO(johnniwinther): Serialize this.
  bool lastCaseTerminates = false;

  PatternSwitchStatement(this.expression, this.cases) {
    expression.parent = this;
    setParents(cases, this);
  }

  @override
  DartType get expressionType {
    assert(expressionTypeInternal != null,
        "Expression type hasn't been computed for $this.");
    return expressionTypeInternal!;
  }

  @override
  void set expressionType(DartType value) {
    expressionTypeInternal = value;
  }

  @override
  bool isExplicitlyExhaustive = false;

  /// Whether the switch has a `default` case.
  @override
  bool get hasDefault {
    // TODO(johnniwinther): Establish this, even for erroneous cases.
    //assert(cases.every((c) => c == cases.last || !c.isDefault));
    return cases.isNotEmpty && cases.last.isDefault;
  }

  @override
  bool get isExhaustive => throw new UnimplementedError();

  @override
  R accept<R>(StatementVisitor<R> v) {
    return v.visitPatternSwitchStatement(this);
  }

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) {
    return v.visitPatternSwitchStatement(this, arg);
  }

  @override
  void transformChildren(Transformer v) {
    expression = v.transform(expression)..parent = this;
    v.transformList(cases, this);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    expression = v.transform(expression)..parent = this;
    v.transformList(cases, this, dummyPatternSwitchCase);
  }

  @override
  void visitChildren(Visitor v) {
    expression.accept(v);
    visitList(cases, v);
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('switch (');
    printer.writeExpression(expression);
    printer.write(') {');
    printer.incIndentation();
    for (SwitchCase switchCase in cases) {
      printer.newLine();
      printer.writeSwitchCase(switchCase);
    }
    printer.decIndentation();
    printer.newLine();
    printer.write('}');
  }

  @override
  String toString() {
    return "PatternSwitchStatement(${toStringInternal()})";
  }
}

class SwitchExpressionCase extends TreeNode {
  PatternGuard patternGuard;
  Expression expression;

  SwitchExpressionCase(this.patternGuard, this.expression) {
    patternGuard.parent = this;
    expression.parent = this;
  }

  @override
  R accept<R>(TreeVisitor<R> v) {
    return v.visitSwitchExpressionCase(this);
  }

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) {
    return v.visitSwitchExpressionCase(this, arg);
  }

  @override
  void transformChildren(Transformer v) {
    patternGuard = v.transform(patternGuard)..parent = this;
    expression = v.transform(expression)..parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    patternGuard = v.transform(patternGuard)..parent = this;
    expression = v.transform(expression)..parent = this;
  }

  @override
  void visitChildren(Visitor v) {
    patternGuard.accept(v);
    expression.accept(v);
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('case ');
    patternGuard.toTextInternal(printer);
    printer.write(' => ');
    printer.writeExpression(expression);
  }

  @override
  String toString() {
    return 'SwitchExpressionCase(${toStringInternal()})';
  }
}

class SwitchExpression extends Expression {
  Expression expression;
  final List<SwitchExpressionCase> cases;

  /// The type of the [expression].
  ///
  /// This is set during inference.
  DartType? expressionType;

  /// The resulting type of the switch expression.
  ///
  /// This is set during inference.
  DartType? staticType;

  SwitchExpression(this.expression, this.cases) {
    expression.parent = this;
    setParents(cases, this);
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) {
    return v.visitSwitchExpression(this);
  }

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) {
    return v.visitSwitchExpression(this, arg);
  }

  @override
  void transformChildren(Transformer v) {
    expression = v.transform(expression)..parent = this;
    v.transformList(cases, this);
    if (staticType != null) {
      staticType = v.visitDartType(staticType!);
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    expression = v.transform(expression)..parent = this;
    v.transformList(cases, this, dummySwitchExpressionCase);
    if (staticType != null) {
      staticType = v.visitDartType(staticType!, cannotRemoveSentinel);
    }
  }

  @override
  void visitChildren(Visitor v) {
    expression.accept(v);
    visitList(cases, v);
    staticType?.accept(v);
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) => staticType!;

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('switch (');
    printer.writeExpression(expression);
    printer.write(') {');
    String comma = ' ';
    for (SwitchExpressionCase switchCase in cases) {
      printer.write(comma);
      switchCase.toTextInternal(printer);
      comma = ', ';
    }
    printer.write(' }');
  }

  @override
  String toString() => 'SwitchExpression(${toStringInternal()})';
}

class PatternVariableDeclaration extends Statement {
  Pattern pattern;
  Expression initializer;
  final bool isFinal;

  /// The type of the expression against which this pattern is matched.
  ///
  /// This is set during inference.
  DartType? matchedValueType;

  PatternVariableDeclaration(this.pattern, this.initializer,
      {required this.isFinal}) {
    pattern.parent = this;
    initializer.parent = this;
  }

  @override
  R accept<R>(StatementVisitor<R> v) {
    return v.visitPatternVariableDeclaration(this);
  }

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) {
    return v.visitPatternVariableDeclaration(this, arg);
  }

  @override
  void transformChildren(Transformer v) {
    pattern = v.transform(pattern)..parent = this;
    initializer = v.transform(initializer)..parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    pattern = v.transform(pattern)..parent = this;
    initializer = v.transform(initializer)..parent = this;
  }

  @override
  void visitChildren(Visitor v) {
    pattern.accept(v);
    initializer.accept(v);
  }

  @override
  void toTextInternal(AstPrinter printer) {
    if (isFinal) {
      printer.write('final ');
    } else {
      printer.write('var ');
    }
    pattern.toTextInternal(printer);
    printer.write(" = ");
    printer.writeExpression(initializer);
    printer.write(';');
  }

  @override
  String toString() {
    return "PatternVariableDeclaration(${toStringInternal()})";
  }
}

class PatternAssignment extends Expression {
  Pattern pattern;
  Expression expression;

  /// The type of the expression against which this pattern is matched.
  ///
  /// This is set during inference.
  DartType? matchedValueType;

  PatternAssignment(this.pattern, this.expression) {
    pattern.parent = this;
    expression.parent = this;
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) {
    return v.visitPatternAssignment(this);
  }

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) {
    return v.visitPatternAssignment(this, arg);
  }

  @override
  void transformChildren(Transformer v) {
    pattern = v.transform(pattern)..parent = this;
    expression = v.transform(expression)..parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    pattern = v.transform(pattern)..parent = this;
    expression = v.transform(expression)..parent = this;
  }

  @override
  void visitChildren(Visitor v) {
    pattern.accept(v);
    expression.accept(v);
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    return expression.getStaticType(context);
  }

  @override
  void toTextInternal(AstPrinter printer) {
    pattern.toTextInternal(printer);
    printer.write(' = ');
    printer.writeExpression(expression);
  }

  @override
  String toString() {
    return "PatternAssignment(${toStringInternal()})";
  }
}

/// Statement for a if-case statements:
///
///     if (expression case pattern) then
///     if (expression case pattern) then else otherwise
///     if (expression case pattern when guard) then
///     if (expression case pattern when guard) then else otherwise
///
class IfCaseStatement extends Statement {
  Expression expression;
  PatternGuard patternGuard;
  Statement then;
  Statement? otherwise;

  /// The type of the expression against which this pattern is matched.
  ///
  /// This is set during inference.
  DartType? matchedValueType;

  IfCaseStatement(this.expression, this.patternGuard, this.then,
      [this.otherwise]) {
    expression.parent = this;
    patternGuard.parent = this;
    then.parent = this;
    otherwise?.parent = this;
  }

  @override
  R accept<R>(StatementVisitor<R> v) {
    return v.visitIfCaseStatement(this);
  }

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) {
    return v.visitIfCaseStatement(this, arg);
  }

  @override
  void transformChildren(Transformer v) {
    expression = v.transform(expression)..parent = this;
    patternGuard = v.transform(patternGuard)..parent = this;
    then = v.transform(then)..parent = this;
    if (otherwise != null) {
      otherwise = v.transform(otherwise!)..parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    expression = v.transform(expression)..parent = this;
    patternGuard = v.transform(patternGuard)..parent = this;
    then = v.transform(then)..parent = this;
    if (otherwise != null) {
      otherwise = v.transformOrRemoveStatement(otherwise!)?..parent = this;
    }
  }

  @override
  void visitChildren(Visitor v) {
    expression.accept(v);
    patternGuard.accept(v);
    then.accept(v);
    otherwise?.accept(v);
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('if (');
    printer.writeExpression(expression);
    printer.write(' case ');
    patternGuard.toTextInternal(printer);
    printer.write(') ');
    printer.writeStatement(then);
    if (otherwise != null) {
      printer.write(' else ');
      printer.writeStatement(otherwise!);
    }
  }

  @override
  String toString() {
    return "IfCaseStatement(${toStringInternal()})";
  }
}

final Pattern dummyPattern = new ConstantPattern(dummyExpression);

final NamedPattern dummyNamedPattern = new NamedPattern('', dummyPattern);

final MapPatternEntry dummyMapPatternEntry =
    new MapPatternEntry(dummyExpression, dummyPattern);

final PatternGuard dummyPatternGuard = new PatternGuard(dummyPattern);

final PatternSwitchCase dummyPatternSwitchCase = new PatternSwitchCase(
    [], [], dummyStatement,
    isDefault: true,
    hasLabel: false,
    jointVariables: [],
    jointVariableFirstUseOffsets: null);

final SwitchExpressionCase dummySwitchExpressionCase =
    new SwitchExpressionCase(dummyPatternGuard, dummyExpression);
