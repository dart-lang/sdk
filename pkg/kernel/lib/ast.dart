// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// -----------------------------------------------------------------------
///                           ERROR HANDLING
/// -----------------------------------------------------------------------
///
/// Consumers of the AST currently need to handle two types of error cases:
/// - The "invalid" node types (e.g. [InvalidExpression])
/// - Mismatching arguments and parameters on statically resolved invocations.
///
/// Although the frontend does not yet catch all possible errors, AST consumers
/// should assume that a member reference always points to a meaningful target.
/// For instance, a [SuperInvocation] will never target an abstract method, and
/// [StaticSet] will never have a final field as a write target.  Should the
/// input contain such errors, the frontend must create an invalid node instead.
///
/// Since the frontend is not yet complete, erroneous code may slip through,
/// but this should be fixed in the frontend, not by the AST consumer.
///
/// -----------------------------------------------------------------------
///                                 NAMES
/// -----------------------------------------------------------------------
///
/// We distinguish two kinds of names, **binding names** and **cosmetic names**.
///
/// Binding names are:
/// - names used for dynamic dispatch
/// - external member names
/// - named parameter names
///
/// Cosmetic names are everything else, for example:
/// - local variable names
/// - positional parameter names
/// - static member names (non-external)
/// - constructor names (non-external)
/// - class names
/// - library names
///
/// Cosmetic names are only stored at the definition site of an object, e.g.
/// a static method invocation does not store the name of the target method,
/// only the method itself does.
///
/// Cosmetic names can sometimes be observed by introspection features like
/// mirrors, they can show up in stack traces, and transformers may want to rely
/// on them.  Cosmetic names may in general be `null` for synthetic objects.
///
/// -----------------------------------------------------------------------
///                           STATIC vs TOP-LEVEL
/// -----------------------------------------------------------------------
///
/// The term `static` includes both static class members and top-level members.
///
/// "Static class member" is the preferred term for non-top level statics.
///
/// Static class members are not lifted to the library level because mirrors
/// and stack traces can observe that they are class members.
///
/// -----------------------------------------------------------------------
///                                 PROCEDURES
/// -----------------------------------------------------------------------
///
/// "Procedure" is an umbrella term for method, getter, setter, index-getter,
/// index-setter, operator overloader, and factory constructor.
///
/// Generative constructors, field initializers, local functions are NOT
/// procedures.
///
/// -----------------------------------------------------------------------
///                               TRANSFORMATIONS
/// -----------------------------------------------------------------------
///
/// AST transformations can be performed using [TreeNode.replaceWith] or the
/// [Transformer] visitor class.
///
/// Use [Transformer] for bulk transformations that are likely to transform lots
/// of nodes, and [TreeNode.replaceWith] for sparse transformations that mutate
/// relatively few nodes.  Or use whichever is more convenient.
///
/// The AST can also be mutated by direct field manipulation, but the user then
/// has to update parent pointers manually.
///
library kernel.ast;

import 'visitor.dart';
export 'visitor.dart';

import 'text/ast_to_text.dart';
import 'type_algebra.dart';

/// Any type of node in the IR.
abstract class Node {
  const Node();

  accept(Visitor v);
  visitChildren(Visitor v);

  /// Returns the textual representation of this node for use in debugging.
  ///
  /// [toString] should only be used for debugging and short-running test tools
  /// as it can cause serious memory leaks.
  ///
  /// Synthetic names are cached globally to retain consistency across different
  /// [toString] calls (hence the memory leak).
  String toString() => debugNodeToString(this);
}

/// A mutable AST node with a parent pointer.
///
/// This is anything other than [Name] and [DartType] nodes.
abstract class TreeNode extends Node {
  static int _hashCounter = 0;
  final int hashCode = _hashCounter = (_hashCounter + 1) & 0x7fffffff;

  TreeNode parent;

  accept(TreeVisitor v);
  visitChildren(Visitor v);
  transformChildren(Transformer v);

  /// Replaces [child] with [replacement].
  ///
  /// The caller is responsible for ensuring that the AST remains a tree.  In
  /// particular, [replacement] should be an orphan or be part of an orphaned
  /// subtree.
  ///
  /// Has no effect if [child] is not actually a child of this node.
  ///
  /// If [replacement] is `null`, this will [remove] the [child] node.
  void replaceChild(TreeNode child, TreeNode replacement) {
    transformChildren(new _ChildReplacer(child, replacement));
  }

  /// Inserts another node in place of this one.
  ///
  /// The caller is responsible for ensuring that the AST remains a tree.  In
  /// particular, [replacement] should be an orphan or be part of an orphaned
  /// subtree.
  ///
  /// If [replacement] is `null`, this will [remove] the node.
  void replaceWith(TreeNode replacement) {
    parent.replaceChild(this, replacement);
    parent = null;
  }

  /// Removes this node from the [List] it is currently stored in, or assigns
  /// `null` to the field on the parent currently pointing to the node.
  ///
  /// Has no effect if the node is orphaned or if the parent pointer is stale.
  void remove() {
    parent?.replaceChild(this, null);
    parent = null;
  }
}

// ------------------------------------------------------------------------
//                      LIBRARIES and CLASSES
// ------------------------------------------------------------------------

class Library extends TreeNode {
  /// An absolute import path to this library.
  ///
  /// The [Uri] should have the `dart`, `package`, or `file` scheme.
  //
  // DESIGN TODO: Absolute `file` URIs are not ideal for serialization. We will
  //   revise this when we implement modular compilation.
  Uri importUri;

  /// If false, the library object is a placeholder for a library that has
  /// not been loaded yet.
  ///
  /// The [importUri] is always set on an unloaded library, and can be used
  /// as they key to load the library.
  ///
  /// Unloaded libraries may contain arbitrary classes and members for use by
  /// the frontend until the library is loaded.  Clients should not rely
  /// on unloaded library objects being in any particular state.
  bool isLoaded = true;

  String name; // Cosmetic name.
  final List<Class> classes;
  final List<Procedure> procedures;
  final List<Field> fields;

  Library(this.importUri,
      {this.name,
      List<Class> classes,
      List<Procedure> procedures,
      List<Field> fields})
      : this.classes = classes ?? <Class>[],
        this.procedures = procedures ?? <Procedure>[],
        this.fields = fields ?? <Field>[] {
    _setParents(this.classes, this);
    _setParents(this.procedures, this);
    _setParents(this.fields, this);
  }

  void addMember(Member member) {
    member.parent = this;
    if (member is Procedure) {
      procedures.add(member);
    } else if (member is Field) {
      fields.add(member);
    } else {
      throw new ArgumentError(member);
    }
  }

  void addClass(Class class_) {
    class_.parent = this;
    classes.add(class_);
  }

  accept(TreeVisitor v) => v.visitLibrary(this);

  visitChildren(Visitor v) {
    _visitList(classes, v);
    _visitList(procedures, v);
    _visitList(fields, v);
  }

  transformChildren(Transformer v) {
    _transformList(classes, v, this);
    _transformList(procedures, v, this);
    _transformList(fields, v, this);
  }

  /// Returns a possibly synthesized name for this library, consistent with
  /// the names used in [toString] calls.
  String get debugName => debugLibraryName(this);
}

/// A class declaration.
///
/// There are two kinds of classes: [MixinClass] is a mixin application and
/// a [NormalClass] is any other kind of class.
///
/// The two subclasses enforce the runtime invariant that mixin applications
/// can never declare fields or procedures.  Code that relies on this invariant
/// should treat the two kinds of classes separately, but otherwise it is
/// recommended to interface against [Class].
abstract class Class extends TreeNode {
  String name; // Cosmetic name.
  bool isAbstract;
  final List<TypeParameter> typeParameters;

  /// The immediate super type, or `null` if this is the root class.
  InterfaceType superType;

  /// The types from the `implements` clause.
  final List<InterfaceType> implementedTypes;

  /// Fields declared in the class.
  ///
  /// For mixin applications this is an immutable empty list.
  final List<Field> fields;

  /// Constructors declared in the class.
  final List<Constructor> constructors;

  /// Procedures declared in the class.
  ///
  /// For mixin applications this is an immutable empty list.
  final List<Procedure> procedures;

  Class(this.name, this.isAbstract, this.typeParameters, this.superType,
      this.implementedTypes, this.fields, this.constructors, this.procedures) {
    _setParents(typeParameters, this);
    _setParents(constructors, this);
    _setParents(procedures, this);
    _setParents(fields, this);
  }

  /// Returns the mixed-in type if this is a mixin application, otherwise null.
  InterfaceType get mixedInType => null;

  bool get isMixinApplication => false;

  /// Members declared in this class.
  ///
  /// This getter is for convenience, not efficiency.  Consider manually
  /// iterating the members to speed up code in production.
  Iterable<Member> get members =>
      <Iterable<Member>>[fields, constructors, procedures].expand((x) => x);

  /// The immediately extended, mixed-in, and implemented types.
  ///
  /// This getter is for convenience, not efficiency.  Consider manually
  /// iterating the super types to speed up code in production.
  Iterable<InterfaceType> get supers => <Iterable<InterfaceType>>[
        superType == null ? const [] : [superType],
        mixedInType == null ? const [] : [mixedInType],
        implementedTypes
      ].expand((x) => x);

  /// The library containing this class.
  Library get enclosingLibrary => parent;

  /// Adds a member to this class.
  ///
  /// Throws an error if attempting to add a field or procedure to a mixin
  /// application.
  void addMember(Member member) {
    member.parent = this;
    if (member is Constructor) {
      constructors.add(member);
    } else if (member is Procedure) {
      procedures.add(member);
    } else if (member is Field) {
      fields.add(member);
    } else {
      throw new ArgumentError(member);
    }
  }

  accept(ClassVisitor v);
  acceptReference(ClassReferenceVisitor v);

  bool get isLoaded => enclosingLibrary.isLoaded;

  InterfaceType _rawType;
  InterfaceType get rawType => _rawType ??= new InterfaceType(this);

  InterfaceType _thisType;
  InterfaceType get thisType {
    return _thisType ??=
        new InterfaceType(this, _getAsTypeArguments(typeParameters));
  }

  /// Returns a possibly synthesized name for this class, consistent with
  /// the names used in [toString] calls.
  String get debugName => debugClassName(this);
}

/// A class that is not a mixin application.
class NormalClass extends Class {
  NormalClass(InterfaceType superType,
      {String name,
      bool isAbstract: false,
      List<TypeParameter> typeParameters,
      List<InterfaceType> implementedClasses,
      List<Constructor> constructors,
      List<Procedure> procedures,
      List<Field> fields})
      : super(
            name,
            isAbstract,
            typeParameters ?? <TypeParameter>[],
            superType,
            implementedClasses ?? <InterfaceType>[],
            fields ?? <Field>[],
            constructors ?? <Constructor>[],
            procedures ?? <Procedure>[]);

  accept(ClassVisitor v) => v.visitNormalClass(this);

  acceptReference(ClassReferenceVisitor v) => v.visitNormalClassReference(this);

  visitChildren(Visitor v) {
    _visitList(typeParameters, v);
    superType?.accept(v);
    _visitList(implementedTypes, v);
    _visitList(constructors, v);
    _visitList(procedures, v);
    _visitList(fields, v);
  }

  transformChildren(Transformer v) {
    _transformList(typeParameters, v, this);
    _transformList(constructors, v, this);
    _transformList(procedures, v, this);
    _transformList(fields, v, this);
  }
}

/// The result of mixing two classes [superType] and [mixedInType].
///
/// A class declaration `class A extends B with C` is represented as a
/// normal class `A` with the mixin class `B with C` as its super class.
///
/// A mixin with multiple classes `A with B, C` is represented as a left-leaning
/// tree of mixin classes `(A with B) with C`.  Each mixin will have an entry
/// in [Library.classes].
///
/// Mixin applications cannot declare any fields or procedures, as it implicitly
/// uses those from the mixed-in class.
class MixinClass extends Class {
  InterfaceType mixedInType;

  MixinClass(InterfaceType superType, this.mixedInType,
      {String name,
      bool isAbstract: false,
      List<TypeParameter> typeParameters,
      List<InterfaceType> implementedClasses,
      List<Constructor> constructors})
      : super(
            name,
            isAbstract,
            typeParameters ?? <TypeParameter>[],
            superType,
            implementedClasses ?? <InterfaceType>[],
            const <Field>[],
            constructors ?? <Constructor>[],
            const <Procedure>[]);

  bool get isMixinApplication => true;

  accept(ClassVisitor v) => v.visitMixinClass(this);

  acceptReference(ClassReferenceVisitor v) => v.visitMixinClassReference(this);

  visitChildren(Visitor v) {
    _visitList(typeParameters, v);
    superType?.accept(v);
    mixedInType?.accept(v);
    _visitList(implementedTypes, v);
    _visitList(constructors, v);
  }

  transformChildren(Transformer v) {
    _transformList(typeParameters, v, this);
    _transformList(constructors, v, this);
  }
}

// ------------------------------------------------------------------------
//                            MEMBERS
// ------------------------------------------------------------------------

abstract class Member extends TreeNode {
  Name get name;
  set name(Name name);

  Class get enclosingClass => parent is Class ? parent : null;
  Library get enclosingLibrary => parent is Class ? parent.parent : parent;

  accept(MemberVisitor v);
  acceptReference(MemberReferenceVisitor v);

  bool get isLoaded => enclosingLibrary.isLoaded;

  /// Returns a possibly synthesized name for this member, consistent with
  /// the names used in [toString] calls.
  String get debugName => debugMemberName(this);
}

/// A field declaration.
///
/// The implied getter and setter for the field are not represented explicitly.
class Field extends Member {
  Name name;
  DartType type; // Not null. Defaults to DynamicType.
  int flags = 0;
  Expression initializer; // May be null.

  Field(this.name,
      {DartType type,
      this.initializer,
      bool isFinal: false,
      bool isConst: false,
      bool isStatic: false})
      : this.type = type ?? const DynamicType() {
    initializer?.parent = this;
    this.isFinal = isFinal;
    this.isConst = isConst;
    this.isStatic = isStatic;
  }

  static const int FlagFinal = 1 << 0; // Must match serialized bit positions.
  static const int FlagConst = 1 << 1;
  static const int FlagStatic = 1 << 2;

  bool get isFinal => flags & FlagFinal != 0;
  bool get isConst => flags & FlagConst != 0;
  bool get isStatic => flags & FlagStatic != 0;

  void set isFinal(bool value) {
    flags = value ? (flags | FlagFinal) : (flags & ~FlagFinal);
  }

  void set isConst(bool value) {
    flags = value ? (flags | FlagConst) : (flags & ~FlagConst);
  }

  void set isStatic(bool value) {
    flags = value ? (flags | FlagStatic) : (flags & ~FlagStatic);
  }

  /// True if the field is neither final nor const.
  bool get isMutable => flags & (FlagStatic | FlagConst) == 0;

  accept(MemberVisitor v) => v.visitField(this);

  acceptReference(MemberReferenceVisitor v) => v.visitFieldReference(this);

  visitChildren(Visitor v) {
    type?.accept(v);
    name?.accept(v);
    initializer?.accept(v);
  }

  transformChildren(Transformer v) {
    if (initializer != null) {
      initializer = initializer.accept(v);
      initializer?.parent = this;
    }
  }
}

/// A generative constructor, possibly redirecting.
///
/// Note that factory constructors are treated as [Procedure]s.
///
/// Constructors do not take type parameters.  Type arguments from a constructor
/// invocation should be matched with the type parameters declared in the class.
class Constructor extends Member {
  int flags = 0;

  /// Name of the constructor.
  ///
  /// For non-external constructors, the name is cosmetic.
  ///
  /// For unnamed constructors, this is the empty string (in a [Name]).
  Name name;
  FunctionNode function;
  List<Initializer> initializers;

  Constructor(this.function,
      {this.name,
      bool isConst: false,
      bool isExternal: false,
      List<Initializer> initializers})
      : this.initializers = initializers ?? <Initializer>[] {
    function?.parent = this;
    _setParents(this.initializers, this);
    this.isConst = isConst;
    this.isExternal = isExternal;
  }

  static const int FlagConst = 1 << 0; // Must match serialized bit positions.
  static const int FlagExternal = 1 << 1;

  bool get isConst => flags & FlagConst != 0;
  bool get isExternal => flags & FlagExternal != 0;

  void set isConst(bool value) {
    flags = value ? (flags | FlagConst) : (flags & ~FlagConst);
  }

  void set isExternal(bool value) {
    flags = value ? (flags | FlagExternal) : (flags & ~FlagExternal);
  }

  accept(MemberVisitor v) => v.visitConstructor(this);

  acceptReference(MemberReferenceVisitor v) =>
      v.visitConstructorReference(this);

  visitChildren(Visitor v) {
    name?.accept(v);
    function?.accept(v);
    _visitList(initializers, v);
  }

  transformChildren(Transformer v) {
    if (function != null) {
      function = function.accept(v);
      function?.parent = this;
    }
    _transformList(initializers, v, this);
  }
}

/// A method, getter, setter, index-getter, index-setter, operator overloader,
/// or factory.
///
/// Procedures can have the static, abstract, and/or external modifier, although
/// only the static and external modifiers may be used together.
class Procedure extends Member {
  ProcedureKind kind;
  int flags = 0;

  /// Name of the procedure.
  ///
  /// For static non-external procedures, the name is cosmetic and may be `null`
  /// but keep that the name may show up in stack traces.
  ///
  /// For non-static procedures the name is required for dynamic dispatch.
  /// For external procedures the name is required for identifying the external
  /// implementation.
  ///
  /// For methods, getters, and setters, this is just name as it was declared.
  /// For setters this does NOT include a trailing `=`.
  /// For index-getters/setters, this is `[]` and `[]=`.
  /// For operators, this is the token for the operator, e.g. `+` or `==`,
  /// except for the unary minus operator, whose name is `unary-`.
  Name name;
  FunctionNode function; // Body is null if and only if abstract or external.

  Procedure(this.name, this.kind, this.function,
      {bool isAbstract: false,
      bool isStatic: false,
      bool isExternal: false,
      bool isConst: false}) {
    function?.parent = this;
    this.isAbstract = isAbstract;
    this.isStatic = isStatic;
    this.isExternal = isExternal;
    this.isConst = isConst;
  }

  static const int FlagStatic = 1 << 0; // Must match serialized bit positions.
  static const int FlagAbstract = 1 << 1;
  static const int FlagExternal = 1 << 2;
  static const int FlagConst = 1 << 3; // Only for external const factories.

  bool get isStatic => flags & FlagStatic != 0;
  bool get isAbstract => flags & FlagAbstract != 0;
  bool get isExternal => flags & FlagExternal != 0;

  /// True if this has the `const` modifier.  This is only possible for external
  /// constant factories, such as `String.fromEnvironment`.
  bool get isConst => flags & FlagConst != 0;

  void set isStatic(bool value) {
    flags = value ? (flags | FlagStatic) : (flags & ~FlagStatic);
  }

  void set isAbstract(bool value) {
    flags = value ? (flags | FlagAbstract) : (flags & ~FlagAbstract);
  }

  void set isExternal(bool value) {
    flags = value ? (flags | FlagExternal) : (flags & ~FlagExternal);
  }

  void set isConst(bool value) {
    flags = value ? (flags | FlagConst) : (flags & ~FlagConst);
  }

  accept(MemberVisitor v) => v.visitProcedure(this);

  acceptReference(MemberReferenceVisitor v) => v.visitProcedureReference(this);

  visitChildren(Visitor v) {
    name?.accept(v);
    function?.accept(v);
  }

  transformChildren(Transformer v) {
    if (function != null) {
      function = function.accept(v);
      function?.parent = this;
    }
  }
}

enum ProcedureKind {
  Method,
  Getter,
  Setter,
  IndexGetter,
  IndexSetter,
  Operator,
  Factory,
}

// ------------------------------------------------------------------------
//                     CONSTRUCTOR INITIALIZERS
// ------------------------------------------------------------------------

/// Part of an initializer list in a constructor.
abstract class Initializer extends TreeNode {
  accept(InitializerVisitor v);
}

/// An initializer with a compile-time error.
///
/// Should throw an exception at runtime.
//
// DESIGN TODO: The frontend should use this in a lot more cases to catch
// invalid cases.
class InvalidInitializer extends Initializer {
  accept(InitializerVisitor v) => v.visitInvalidInitializer(this);

  visitChildren(Visitor v) {}
  transformChildren(Transformer v) {}
}

/// A field assignment `field = value` occuring in the initializer list of
/// a constructor.
///
/// This node has nothing to do with declaration-site field initializers; those
/// are [Expression]s stored in [Field.initializer].
//
// TODO: The frontend should check that all final fields are initialized
//  exactly once, and that no fields are assigned twice in the initializer list.
class FieldInitializer extends Initializer {
  /// Reference to the field being initialized.  Not null.
  Field field;
  Expression value;

  FieldInitializer(this.field, this.value) {
    value?.parent = this;
  }

  accept(InitializerVisitor v) => v.visitFieldInitializer(this);

  visitChildren(Visitor v) {
    field?.acceptReference(v);
    value?.accept(v);
  }

  transformChildren(Transformer v) {
    if (value != null) {
      value = value.accept(v);
      value?.parent = this;
    }
  }
}

/// A super call `super(x,y)` occuring in the initializer list of a constructor.
///
/// There are no type arguments on this call.
//
// TODO: The frontend should check that there is no more than one super call.
//
// DESIGN TODO: Consider if the frontend should insert type arguments derived
// from the extends clause.
class SuperInitializer extends Initializer {
  /// Reference to the constructor being invoked in the super class. Not null.
  Constructor target;
  Arguments arguments;

  SuperInitializer(this.target, this.arguments) {
    arguments?.parent = this;
  }

  accept(InitializerVisitor v) => v.visitSuperInitializer(this);

  visitChildren(Visitor v) {
    target?.acceptReference(v);
    arguments?.accept(v);
  }

  transformChildren(Transformer v) {
    if (arguments != null) {
      arguments = arguments.accept(v);
      arguments?.parent = this;
    }
  }
}

/// A redirecting call `this(x,y)` occuring in the initializer list of
/// a constructor.
//
// TODO: The frontend should check that this is the only initializer and if the
// constructor has a body or if there is a cycle in the initializer calls.
class RedirectingInitializer extends Initializer {
  /// Reference to the constructor being invoked in the same class. Not null.
  Constructor target;
  Arguments arguments;

  RedirectingInitializer(this.target, this.arguments) {
    arguments?.parent = this;
  }

  accept(InitializerVisitor v) => v.visitRedirectingInitializer(this);

  visitChildren(Visitor v) {
    target?.acceptReference(v);
    arguments?.accept(v);
  }

  transformChildren(Transformer v) {
    if (arguments != null) {
      arguments = arguments.accept(v);
      arguments?.parent = this;
    }
  }
}

// ------------------------------------------------------------------------
//                            FUNCTIONS
// ------------------------------------------------------------------------

/// A function declares parameters and has a body.
///
/// This may occur in a procedure, constructor, function expression, or local
/// function declaration.
class FunctionNode extends TreeNode {
  AsyncMarker asyncMarker;
  List<TypeParameter> typeParameters;
  int requiredParameterCount;
  List<VariableDeclaration> positionalParameters;
  List<VariableDeclaration> namedParameters;
  DartType returnType; // May be null. Always null for constructors.
  Statement body;

  FunctionNode(this.body,
      {List<TypeParameter> typeParameters,
      List<VariableDeclaration> positionalParameters,
      List<VariableDeclaration> namedParameters,
      int requiredParameterCount,
      this.returnType,
      this.asyncMarker: AsyncMarker.Sync})
      : this.positionalParameters =
            positionalParameters ?? <VariableDeclaration>[],
        this.requiredParameterCount =
            requiredParameterCount ?? positionalParameters?.length ?? 0,
        this.namedParameters = namedParameters ?? <VariableDeclaration>[],
        this.typeParameters = typeParameters ?? <TypeParameter>[] {
    _setParents(this.typeParameters, this);
    _setParents(this.positionalParameters, this);
    _setParents(this.namedParameters, this);
    body?.parent = this;
  }

  accept(TreeVisitor v) => v.visitFunctionNode(this);

  visitChildren(Visitor v) {
    _visitList(typeParameters, v);
    _visitList(positionalParameters, v);
    _visitList(namedParameters, v);
    returnType?.accept(v);
    body?.accept(v);
  }

  transformChildren(Transformer v) {
    _transformList(typeParameters, v, this);
    _transformList(positionalParameters, v, this);
    _transformList(namedParameters, v, this);
    if (body != null) {
      body = body.accept(v);
      body?.parent = this;
    }
  }
}

enum AsyncMarker {
  // Do not change the order of these, the frontends depend on it.
  Sync,
  SyncStar,
  Async,
  AsyncStar
}

// ------------------------------------------------------------------------
//                                EXPRESSIONS
// ------------------------------------------------------------------------

abstract class Expression extends TreeNode {
  accept(ExpressionVisitor v);
}

/// An expression containing compile-time errors.
///
/// Should throw a runtime error when evaluated.
class InvalidExpression extends Expression {
  accept(ExpressionVisitor v) => v.visitInvalidExpression(this);

  visitChildren(Visitor v) {}
  transformChildren(Transformer v) {}
}

/// Read a local variable, a local function, or a function parameter.
class VariableGet extends Expression {
  VariableDeclaration variable;

  VariableGet(this.variable);

  accept(ExpressionVisitor v) => v.visitVariableGet(this);

  visitChildren(Visitor v) {}
  transformChildren(Transformer v) {}
}

/// Assign a local variable or function parameter.
class VariableSet extends Expression {
  VariableDeclaration variable;
  Expression value;

  VariableSet(this.variable, this.value) {
    value?.parent = this;
  }

  accept(ExpressionVisitor v) => v.visitVariableSet(this);

  visitChildren(Visitor v) {
    value?.accept(v);
  }

  transformChildren(Transformer v) {
    if (value != null) {
      value = value.accept(v);
      value?.parent = this;
    }
  }
}

/// Expression of form `x.field`.
///
/// This may invoke a getter, read a field, or tear off a method.
class PropertyGet extends Expression {
  Expression receiver;
  Name name;

  PropertyGet(this.receiver, this.name) {
    receiver?.parent = this;
  }

  accept(ExpressionVisitor v) => v.visitPropertyGet(this);

  visitChildren(Visitor v) {
    receiver?.accept(v);
    name?.accept(v);
  }

  transformChildren(Transformer v) {
    if (receiver != null) {
      receiver = receiver.accept(v);
      receiver?.parent = this;
    }
  }
}

/// Expression of form `x.field = value`.
///
/// This may invoke a setter or assign a field.
class PropertySet extends Expression {
  Expression receiver;
  Name name;
  Expression value;

  PropertySet(this.receiver, this.name, this.value) {
    receiver?.parent = this;
    value?.parent = this;
  }

  accept(ExpressionVisitor v) => v.visitPropertySet(this);

  visitChildren(Visitor v) {
    receiver?.accept(v);
    name?.accept(v);
    value?.accept(v);
  }

  transformChildren(Transformer v) {
    if (receiver != null) {
      receiver = receiver.accept(v);
      receiver?.parent = this;
    }
    if (value != null) {
      value = value.accept(v);
      value?.parent = this;
    }
  }
}

/// Expression of form `super.field`.
///
/// This may invoke a getter, read a field, or tear off a method.
class SuperPropertyGet extends Expression {
  /// A field or a getter, or a method (for tear-off) in a super class.
  ///
  /// Cannot be static or abstract.
  Member target;

  SuperPropertyGet(this.target);

  accept(ExpressionVisitor v) => v.visitSuperPropertyGet(this);

  visitChildren(Visitor v) {
    target?.acceptReference(v);
  }

  transformChildren(Transformer v) {}
}

/// Expression of form `super.field = value`.
///
/// This may invoke a setter or assign a field.
class SuperPropertySet extends Expression {
  /// A mutable field or a non-abstract getter in a super class.
  Member target;
  Expression value;

  SuperPropertySet(this.target, this.value) {
    value?.parent = this;
  }

  accept(ExpressionVisitor v) => v.visitSuperPropertySet(this);

  visitChildren(Visitor v) {
    target?.acceptReference(v);
    value?.accept(v);
  }

  transformChildren(Transformer v) {
    if (value != null) {
      value = value.accept(v);
      value?.parent = this;
    }
  }
}

/// Read a static field, call a static getter, or tear off a static method.
class StaticGet extends Expression {
  /// A static field, getter, or method (for tear-off).
  Member target;

  StaticGet(this.target);

  accept(ExpressionVisitor v) => v.visitStaticGet(this);

  visitChildren(Visitor v) {
    target?.acceptReference(v);
  }

  transformChildren(Transformer v) {}
}

/// Assign a static field or call a static setter.
class StaticSet extends Expression {
  /// A mutable static field or a static setter.
  Member target;
  Expression value;

  StaticSet(this.target, this.value) {
    value?.parent = this;
  }

  accept(ExpressionVisitor v) => v.visitStaticSet(this);

  visitChildren(Visitor v) {
    target?.acceptReference(v);
    value?.accept(v);
  }

  transformChildren(Transformer v) {
    if (value != null) {
      value = value.accept(v);
      value?.parent = this;
    }
  }
}

/// The arguments to a function call, divided into type arguments,
/// positional arguments, and named arguments.
class Arguments extends TreeNode {
  final List<DartType> types;
  final List<Expression> positional;
  final List<NamedExpression> named;

  Arguments(this.positional,
      {List<DartType> types, List<NamedExpression> named})
      : this.types = types ?? <DartType>[],
        this.named = named ?? <NamedExpression>[] {
    _setParents(this.positional, this);
    _setParents(this.named, this);
  }

  Arguments.empty()
      : types = <DartType>[],
        positional = <Expression>[],
        named = <NamedExpression>[];

  accept(TreeVisitor v) => v.visitArguments(this);

  visitChildren(Visitor v) {
    _visitList(types, v);
    _visitList(positional, v);
    _visitList(named, v);
  }

  transformChildren(Transformer v) {
    _transformList(positional, v, this);
    _transformList(named, v, this);
  }
}

/// A named argument, `name: value`.
class NamedExpression extends TreeNode {
  String name;
  Expression value;

  NamedExpression(this.name, this.value) {
    value?.parent = this;
  }

  accept(TreeVisitor v) => v.visitNamedExpression(this);

  visitChildren(Visitor v) {
    value?.accept(v);
  }

  transformChildren(Transformer v) {
    if (value != null) {
      value = value.accept(v);
      value?.parent = this;
    }
  }
}

/// Common super class for [MethodInvocation], [SuperMethodInvocation],
/// [StaticInvocation], and [ConstructorInvocation].
abstract class InvocationExpression extends Expression {
  Arguments get arguments;
  set arguments(Arguments value);

  /// The static target of the invocation, or `null` if this is a dynamic
  /// dispatch invocation.
  Member get target;

  /// Name of the invoked method.
  ///
  /// May be `null` if the target is a synthetic static member without a name.
  Name get name;
}

/// Expression of form `x.foo(y)`.
class MethodInvocation extends InvocationExpression {
  Expression receiver;
  Name name;
  Arguments arguments;

  MethodInvocation(this.receiver, this.name, this.arguments) {
    receiver?.parent = this;
    arguments?.parent = this;
  }

  Member get target => null;

  accept(ExpressionVisitor v) => v.visitMethodInvocation(this);

  visitChildren(Visitor v) {
    receiver?.accept(v);
    name?.accept(v);
    arguments?.accept(v);
  }

  transformChildren(Transformer v) {
    if (receiver != null) {
      receiver = receiver.accept(v);
      receiver?.parent = this;
    }
    if (arguments != null) {
      arguments = arguments.accept(v);
      arguments?.parent = this;
    }
  }
}

/// Expression of form `super.foo(x)`.
///
/// The provided arguments might not match the parameters of the target.
class SuperMethodInvocation extends InvocationExpression {
  Procedure target; // Non-abstract, non-static method in a super class.
  Arguments arguments;

  Name get name => target?.name;

  SuperMethodInvocation(this.target, this.arguments) {
    arguments?.parent = this;
  }

  accept(ExpressionVisitor v) => v.visitSuperMethodInvocation(this);

  visitChildren(Visitor v) {
    target?.acceptReference(v);
    arguments?.accept(v);
  }

  transformChildren(Transformer v) {
    if (arguments != null) {
      arguments = arguments.accept(v);
      arguments?.parent = this;
    }
  }
}

/// Expression of form `foo(x)`, or `const foo(x)` if the target is an
/// external constant factory.
///
/// The provided arguments might not match the parameters of the target.
class StaticInvocation extends InvocationExpression {
  Procedure target;
  Arguments arguments;

  /// True if this is a constant call to an external constant factory.
  bool isConst;

  Name get name => target?.name;

  StaticInvocation(this.target, this.arguments, {this.isConst: false}) {
    arguments?.parent = this;
  }

  accept(ExpressionVisitor v) => v.visitStaticInvocation(this);

  visitChildren(Visitor v) {
    target?.acceptReference(v);
    arguments?.accept(v);
  }

  transformChildren(Transformer v) {
    if (arguments != null) {
      arguments = arguments.accept(v);
      arguments?.parent = this;
    }
  }
}

/// Expression of form `new Foo(x)` or `const Foo(x)`.
///
/// The provided arguments might not match the parameters of the target.
//
// DESIGN TODO: Should we pass type arguments in a separate field
// `classTypeArguments`? They are quite different from type arguments to
// generic functions.
class ConstructorInvocation extends Expression {
  Constructor target;
  Arguments arguments;
  bool isConst;

  ConstructorInvocation(this.target, this.arguments, {this.isConst: false}) {
    arguments?.parent = this;
  }

  accept(ExpressionVisitor v) => v.visitConstructorInvocation(this);

  visitChildren(Visitor v) {
    target?.acceptReference(v);
    arguments?.accept(v);
  }

  transformChildren(Transformer v) {
    if (arguments != null) {
      arguments = arguments.accept(v);
      arguments?.parent = this;
    }
  }
}

/// Expression of form `!x`.
///
/// The `is!` and `!=` operators are desugared into [Not] nodes with `is` and
/// `==` expressions inside, respectively.
class Not extends Expression {
  Expression operand;

  Not(this.operand) {
    operand?.parent = this;
  }

  accept(ExpressionVisitor v) => v.visitNot(this);

  visitChildren(Visitor v) {
    operand?.accept(v);
  }

  transformChildren(Transformer v) {
    if (operand != null) {
      operand = operand.accept(v);
      operand?.parent = this;
    }
  }
}

/// Expression of form `x && y`, `x || y`, or `x ?? y`.
class LogicalExpression extends Expression {
  Expression left;
  String operator; // && or || or ??
  Expression right;

  LogicalExpression(this.left, this.operator, this.right) {
    left?.parent = this;
    right?.parent = this;
  }

  accept(ExpressionVisitor v) => v.visitLogicalExpression(this);

  visitChildren(Visitor v) {
    left?.accept(v);
    right?.accept(v);
  }

  transformChildren(Transformer v) {
    if (left != null) {
      left = left.accept(v);
      left?.parent = this;
    }
    if (right != null) {
      right = right.accept(v);
      right?.parent = this;
    }
  }
}

/// Expression of form `x ? y : z`.
class ConditionalExpression extends Expression {
  Expression condition;
  Expression then;
  Expression otherwise;

  ConditionalExpression(this.condition, this.then, this.otherwise) {
    condition?.parent = this;
    then?.parent = this;
    otherwise?.parent = this;
  }

  accept(ExpressionVisitor v) => v.visitConditionalExpression(this);

  visitChildren(Visitor v) {
    condition?.accept(v);
    then?.accept(v);
    otherwise?.accept(v);
  }

  transformChildren(Transformer v) {
    if (condition != null) {
      condition = condition.accept(v);
      condition?.parent = this;
    }
    if (then != null) {
      then = then.accept(v);
      then?.parent = this;
    }
    if (otherwise != null) {
      otherwise = otherwise.accept(v);
      otherwise?.parent = this;
    }
  }
}

/// Convert expressions to strings and concatenate them.  Semantically, calls
/// `toString` on every argument, checks that a string is returned, and returns
/// the concatenation of all the strings.
///
/// If [expressions] is empty then an empty string is returned.
///
/// These arise from string interpolations and adjacent string literals.
class StringConcatenation extends Expression {
  final List<Expression> expressions;

  StringConcatenation(this.expressions) {
    _setParents(expressions, this);
  }

  accept(ExpressionVisitor v) => v.visitStringConcatenation(this);

  visitChildren(Visitor v) {
    _visitList(expressions, v);
  }

  transformChildren(Transformer v) {
    _transformList(expressions, v, this);
  }
}

/// Expression of form `x is T`.
class IsExpression extends Expression {
  Expression operand;
  DartType type;

  IsExpression(this.operand, this.type) {
    operand?.parent = this;
  }

  accept(ExpressionVisitor v) => v.visitIsExpression(this);

  visitChildren(Visitor v) {
    operand?.accept(v);
    type?.accept(v);
  }

  transformChildren(Transformer v) {
    if (operand != null) {
      operand = operand.accept(v);
      operand?.parent = this;
    }
  }
}

/// Expression of form `x as T`.
class AsExpression extends Expression {
  Expression operand;
  DartType type;

  AsExpression(this.operand, this.type) {
    operand?.parent = this;
  }

  accept(ExpressionVisitor v) => v.visitAsExpression(this);

  visitChildren(Visitor v) {
    operand?.accept(v);
    type?.accept(v);
  }

  transformChildren(Transformer v) {
    if (operand != null) {
      operand = operand.accept(v);
      operand?.parent = this;
    }
  }
}

/// An integer, double, boolean, string, or null constant.
abstract class BasicLiteral extends Expression {
  Object get value;

  visitChildren(Visitor v) {}
  transformChildren(Transformer v) {}
}

class StringLiteral extends BasicLiteral {
  String value;

  StringLiteral(this.value);

  accept(ExpressionVisitor v) => v.visitStringLiteral(this);
}

class IntLiteral extends BasicLiteral {
  int value;

  IntLiteral(this.value);

  accept(ExpressionVisitor v) => v.visitIntLiteral(this);
}

class DoubleLiteral extends BasicLiteral {
  double value;

  DoubleLiteral(this.value);

  accept(ExpressionVisitor v) => v.visitDoubleLiteral(this);
}

class BoolLiteral extends BasicLiteral {
  bool value;

  BoolLiteral(this.value);

  accept(ExpressionVisitor v) => v.visitBoolLiteral(this);
}

class NullLiteral extends BasicLiteral {
  Object get value => null;

  accept(ExpressionVisitor v) => v.visitNullLiteral(this);
}

class SymbolLiteral extends Expression {
  String value; // Everything strictly after the '#'.

  SymbolLiteral(this.value);

  accept(ExpressionVisitor v) => v.visitSymbolLiteral(this);

  visitChildren(Visitor v) {}
  transformChildren(Transformer v) {}
}

class TypeLiteral extends Expression {
  DartType type;

  TypeLiteral(this.type);

  accept(ExpressionVisitor v) => v.visitTypeLiteral(this);

  visitChildren(Visitor v) {
    type?.accept(v);
  }

  transformChildren(Transformer v) {}
}

class ThisExpression extends Expression {
  accept(ExpressionVisitor v) => v.visitThisExpression(this);

  visitChildren(Visitor v) {}
  transformChildren(Transformer v) {}
}

class Rethrow extends Expression {
  accept(ExpressionVisitor v) => v.visitRethrow(this);

  visitChildren(Visitor v) {}
  transformChildren(Transformer v) {}
}

class Throw extends Expression {
  Expression expression;

  Throw(this.expression) {
    expression?.parent = this;
  }

  accept(ExpressionVisitor v) => v.visitThrow(this);

  visitChildren(Visitor v) {
    expression?.accept(v);
  }

  transformChildren(Transformer v) {
    if (expression != null) {
      expression = expression.accept(v);
      expression?.parent = this;
    }
  }
}

class ListLiteral extends Expression {
  bool isConst;
  DartType typeArgument; // Not null, defaults to DynamicType.
  final List<Expression> expressions;

  ListLiteral(this.expressions,
      {this.typeArgument: const DynamicType(), this.isConst: false}) {
    _setParents(expressions, this);
  }

  accept(ExpressionVisitor v) => v.visitListLiteral(this);

  visitChildren(Visitor v) {
    typeArgument?.accept(v);
    _visitList(expressions, v);
  }

  transformChildren(Transformer v) {
    _transformList(expressions, v, this);
  }
}

class MapLiteral extends Expression {
  bool isConst;
  DartType keyType; // Not null, defaults to DynamicType.
  DartType valueType; // Not null, defaults to DynamicType.
  final List<MapEntry> entries;

  MapLiteral(this.entries,
      {this.keyType: const DynamicType(),
      this.valueType: const DynamicType(),
      this.isConst: false}) {
    _setParents(entries, this);
  }

  accept(ExpressionVisitor v) => v.visitMapLiteral(this);

  visitChildren(Visitor v) {
    keyType?.accept(v);
    valueType?.accept(v);
    _visitList(entries, v);
  }

  transformChildren(Transformer v) {
    _transformList(entries, v, this);
  }
}

class MapEntry extends TreeNode {
  Expression key;
  Expression value;

  MapEntry(this.key, this.value) {
    key?.parent = this;
    value?.parent = this;
  }

  accept(TreeVisitor v) => v.visitMapEntry(this);

  visitChildren(Visitor v) {
    key?.accept(v);
    value?.accept(v);
  }

  transformChildren(Transformer v) {
    if (key != null) {
      key = key.accept(v);
      key?.parent = this;
    }
    if (value != null) {
      value = value.accept(v);
      value?.parent = this;
    }
  }
}

/// Expression of form `await x`.
class AwaitExpression extends Expression {
  Expression operand;

  AwaitExpression(this.operand) {
    operand?.parent = this;
  }

  accept(ExpressionVisitor v) => v.visitAwaitExpression(this);

  visitChildren(Visitor v) {
    operand?.accept(v);
  }

  transformChildren(Transformer v) {
    if (operand != null) {
      operand = operand.accept(v);
      operand?.parent = this;
    }
  }
}

/// Expression of form `(x,y) => ...` or `(x,y) { ... }`
///
/// The arrow-body form `=> e` is desugared into `return e;`.
class FunctionExpression extends Expression {
  FunctionNode function;

  FunctionExpression(this.function) {
    function?.parent = this;
  }

  accept(ExpressionVisitor v) => v.visitFunctionExpression(this);

  visitChildren(Visitor v) {
    function?.accept(v);
  }

  transformChildren(Transformer v) {
    if (function != null) {
      function = function.accept(v);
      function?.parent = this;
    }
  }
}

/// Synthetic expression of form `let v = x in y`
class Let extends Expression {
  VariableDeclaration variable; // Must have an initializer.
  Expression body;

  Let(this.variable, this.body) {
    variable?.parent = this;
    body?.parent = this;
  }

  accept(ExpressionVisitor v) => v.visitLet(this);

  visitChildren(Visitor v) {
    variable?.accept(v);
    body?.accept(v);
  }

  transformChildren(Transformer v) {
    if (variable != null) {
      variable = variable.accept(v);
      variable?.parent = this;
    }
    if (body != null) {
      body = body.accept(v);
      body?.parent = this;
    }
  }
}

// ------------------------------------------------------------------------
//                              STATEMENTS
// ------------------------------------------------------------------------

abstract class Statement extends TreeNode {
  accept(StatementVisitor v);
}

/// A statement with a compile-time error.
///
/// Should throw an exception at runtime.
class InvalidStatement extends Statement {
  accept(StatementVisitor v) => v.visitInvalidStatement(this);

  visitChildren(Visitor v) {}
  transformChildren(Transformer v) {}
}

class ExpressionStatement extends Statement {
  Expression expression;

  ExpressionStatement(this.expression) {
    expression?.parent = this;
  }

  accept(StatementVisitor v) => v.visitExpressionStatement(this);

  visitChildren(Visitor v) {
    expression?.accept(v);
  }

  transformChildren(Transformer v) {
    if (expression != null) {
      expression = expression.accept(v);
      expression?.parent = this;
    }
  }
}

class Block extends Statement {
  final List<Statement> statements;

  Block(this.statements) {
    _setParents(statements, this);
  }

  accept(StatementVisitor v) => v.visitBlock(this);

  visitChildren(Visitor v) {
    _visitList(statements, v);
  }

  transformChildren(Transformer v) {
    _transformList(statements, v, this);
  }
}

class EmptyStatement extends Statement {
  accept(StatementVisitor v) => v.visitEmptyStatement(this);

  visitChildren(Visitor v) {}
  transformChildren(Transformer v) {}
}

class AssertStatement extends Statement {
  Expression condition;
  Expression message; // May be null.

  AssertStatement(this.condition, [this.message]) {
    condition?.parent = this;
    message?.parent = this;
  }

  accept(StatementVisitor v) => v.visitAssertStatement(this);

  visitChildren(Visitor v) {
    condition?.accept(v);
    message?.accept(v);
  }

  transformChildren(Transformer v) {
    if (condition != null) {
      condition = condition.accept(v);
      condition?.parent = this;
    }
    if (message != null) {
      message = message.accept(v);
      message?.parent = this;
    }
  }
}

/// A target of a [Break] statement.
///
/// The label itself has no name; breaks reference the statement directly.
///
/// The frontend does not generate labeled statements without uses.
class LabeledStatement extends Statement {
  Statement body;

  LabeledStatement(this.body) {
    body?.parent = this;
  }

  accept(StatementVisitor v) => v.visitLabeledStatement(this);

  visitChildren(Visitor v) {
    body?.accept(v);
  }

  transformChildren(Transformer v) {
    if (body != null) {
      body = body.accept(v);
      body?.parent = this;
    }
  }
}

/// Breaks out of an enclosing [LabeledStatement].
///
/// Both `break` and loop `continue` statements are translated into this node.
///
/// For example, the following loop with a `continue` will be desugared:
///
///     while(x) {
///       if (y) continue;
///       BODY'
///     }
///
///     ==>
///
///     while(x) {
///       L: {
///         if (y) break L;
///         BODY'
///       }
///     }
//
class BreakStatement extends Statement {
  LabeledStatement target;

  BreakStatement(this.target);

  accept(StatementVisitor v) => v.visitBreakStatement(this);

  visitChildren(Visitor v) {}
  transformChildren(Transformer v) {}
}

class WhileStatement extends Statement {
  Expression condition;
  Statement body;

  WhileStatement(this.condition, this.body) {
    condition?.parent = this;
    body?.parent = this;
  }

  accept(StatementVisitor v) => v.visitWhileStatement(this);

  visitChildren(Visitor v) {
    condition?.accept(v);
    body?.accept(v);
  }

  transformChildren(Transformer v) {
    if (condition != null) {
      condition = condition.accept(v);
      condition?.parent = this;
    }
    if (body != null) {
      body = body.accept(v);
      body?.parent = this;
    }
  }
}

class DoStatement extends Statement {
  Statement body;
  Expression condition;

  DoStatement(this.body, this.condition) {
    body?.parent = this;
    condition?.parent = this;
  }

  accept(StatementVisitor v) => v.visitDoStatement(this);

  visitChildren(Visitor v) {
    body?.accept(v);
    condition?.accept(v);
  }

  transformChildren(Transformer v) {
    if (body != null) {
      body = body.accept(v);
      body?.parent = this;
    }
    if (condition != null) {
      condition = condition.accept(v);
      condition?.parent = this;
    }
  }
}

class ForStatement extends Statement {
  final List<VariableDeclaration> variables; // May be empty, but not null.
  Expression condition; // May be null.
  final List<Expression> updates; // May be empty, but not null.
  Statement body;

  ForStatement(this.variables, this.condition, this.updates, this.body) {
    _setParents(variables, this);
    condition?.parent = this;
    _setParents(updates, this);
    body?.parent = this;
  }

  accept(StatementVisitor v) => v.visitForStatement(this);

  visitChildren(Visitor v) {
    _visitList(variables, v);
    condition?.accept(v);
    _visitList(updates, v);
    body?.accept(v);
  }

  transformChildren(Transformer v) {
    _transformList(variables, v, this);
    if (condition != null) {
      condition = condition.accept(v);
      condition?.parent = this;
    }
    _transformList(updates, v, this);
    if (body != null) {
      body = body.accept(v);
      body?.parent = this;
    }
  }
}

class ForInStatement extends Statement {
  VariableDeclaration variable; // Has no initializer.
  Expression iterable;
  Statement body;
  bool isAsync; // True if this is an 'await for' loop.

  ForInStatement(this.variable, this.iterable, this.body,
      {this.isAsync: false}) {
    variable?.parent = this;
    iterable?.parent = this;
    body?.parent = this;
  }

  accept(StatementVisitor v) => v.visitForInStatement(this);

  visitChildren(Visitor v) {
    variable?.accept(v);
    iterable?.accept(v);
    body?.accept(v);
  }

  transformChildren(Transformer v) {
    if (variable != null) {
      variable = variable.accept(v);
      variable?.parent = this;
    }
    if (iterable != null) {
      iterable = iterable.accept(v);
      iterable?.parent = this;
    }
    if (body != null) {
      body = body.accept(v);
      body?.parent = this;
    }
  }
}

/// Statement of form `switch (e) { case x: ... }`.
///
/// Adjacent case clauses have been merged into a single [SwitchCase]. A runtime
/// exception must be thrown if one [SwitchCase] falls through to another case.
class SwitchStatement extends Statement {
  Expression expression;
  final List<SwitchCase> cases;

  SwitchStatement(this.expression, this.cases) {
    expression?.parent = this;
    _setParents(cases, this);
  }

  accept(StatementVisitor v) => v.visitSwitchStatement(this);

  visitChildren(Visitor v) {
    expression?.accept(v);
    _visitList(cases, v);
  }

  transformChildren(Transformer v) {
    if (expression != null) {
      expression = expression.accept(v);
      expression?.parent = this;
    }
    _transformList(cases, v, this);
  }
}

/// A group of `case` clauses and/or a `default` clause.
///
/// This is a potential target of [ContinueSwitchStatement].
class SwitchCase extends TreeNode {
  final List<Expression> expressions;
  Statement body;
  bool isDefault;

  SwitchCase(this.expressions, this.body, {this.isDefault: false}) {
    _setParents(expressions, this);
    body?.parent = this;
  }

  SwitchCase.defaultCase(this.body)
      : isDefault = true,
        expressions = <Expression>[] {
    body?.parent = this;
  }

  SwitchCase.empty()
      : expressions = <Expression>[],
        body = null,
        isDefault = false;

  accept(TreeVisitor v) => v.visitSwitchCase(this);

  visitChildren(Visitor v) {
    _visitList(expressions, v);
    body?.accept(v);
  }

  transformChildren(Transformer v) {
    _transformList(expressions, v, this);
    if (body != null) {
      body = body.accept(v);
      body?.parent = this;
    }
  }
}

/// Jump to a case in an enclosing switch.
class ContinueSwitchStatement extends Statement {
  SwitchCase target;

  ContinueSwitchStatement(this.target);

  accept(StatementVisitor v) => v.visitContinueSwitchStatement(this);

  visitChildren(Visitor v) {}
  transformChildren(Transformer v) {}
}

class IfStatement extends Statement {
  Expression condition;
  Statement then;
  Statement otherwise;

  IfStatement(this.condition, this.then, this.otherwise) {
    condition?.parent = this;
    then?.parent = this;
    otherwise?.parent = this;
  }

  accept(StatementVisitor v) => v.visitIfStatement(this);

  visitChildren(Visitor v) {
    condition?.accept(v);
    then?.accept(v);
    otherwise?.accept(v);
  }

  transformChildren(Transformer v) {
    if (condition != null) {
      condition = condition.accept(v);
      condition?.parent = this;
    }
    if (then != null) {
      then = then.accept(v);
      then?.parent = this;
    }
    if (otherwise != null) {
      otherwise = otherwise.accept(v);
      otherwise?.parent = this;
    }
  }
}

class ReturnStatement extends Statement {
  Expression expression; // May be null.

  ReturnStatement([this.expression]) {
    expression?.parent = this;
  }

  accept(StatementVisitor v) => v.visitReturnStatement(this);

  visitChildren(Visitor v) {
    expression?.accept(v);
  }

  transformChildren(Transformer v) {
    if (expression != null) {
      expression = expression.accept(v);
      expression?.parent = this;
    }
  }
}

class TryCatch extends Statement {
  Statement body;
  List<Catch> catches;

  TryCatch(this.body, this.catches) {
    body?.parent = this;
    _setParents(catches, this);
  }

  accept(StatementVisitor v) => v.visitTryCatch(this);

  visitChildren(Visitor v) {
    body?.accept(v);
    _visitList(catches, v);
  }

  transformChildren(Transformer v) {
    if (body != null) {
      body = body.accept(v);
      body?.parent = this;
    }
    _transformList(catches, v, this);
  }
}

class Catch extends TreeNode {
  DartType guard; // May be null.
  VariableDeclaration exception; // May be null. The declared type is null.
  VariableDeclaration stackTrace; // May be null.
  Statement body;

  Catch(this.exception, this.body, {this.guard, this.stackTrace}) {
    exception?.parent = this;
    stackTrace?.parent = this;
    body?.parent = this;
  }

  accept(TreeVisitor v) => v.visitCatch(this);

  visitChildren(Visitor v) {
    exception?.accept(v);
    stackTrace?.accept(v);
    body?.accept(v);
  }

  transformChildren(Transformer v) {
    if (exception != null) {
      exception = exception.accept(v);
      exception?.parent = this;
    }
    if (stackTrace != null) {
      stackTrace = stackTrace.accept(v);
      stackTrace?.parent = this;
    }
    if (body != null) {
      body = body.accept(v);
      body?.parent = this;
    }
  }
}

class TryFinally extends Statement {
  Statement body;
  Statement finalizer;

  TryFinally(this.body, this.finalizer) {
    body?.parent = this;
    finalizer?.parent = this;
  }

  accept(StatementVisitor v) => v.visitTryFinally(this);

  visitChildren(Visitor v) {
    body?.accept(v);
    finalizer?.accept(v);
  }

  transformChildren(Transformer v) {
    if (body != null) {
      body = body.accept(v);
      body?.parent = this;
    }
    if (finalizer != null) {
      finalizer = finalizer.accept(v);
      finalizer?.parent = this;
    }
  }
}

/// Statement of form `yield x` or `yield* x`.
class YieldStatement extends Statement {
  Expression expression;
  bool isYieldStar;

  YieldStatement(this.expression, {this.isYieldStar: false}) {
    expression?.parent = this;
  }

  accept(StatementVisitor v) => v.visitYieldStatement(this);

  visitChildren(Visitor v) {
    expression?.accept(v);
  }

  transformChildren(Transformer v) {
    if (expression != null) {
      expression = expression.accept(v);
      expression?.parent = this;
    }
  }
}

/// Declaration of a local variable.
///
/// This may occur as a statement, but is also used in several non-statement
/// contexts, such as in [ForStatement], [Catch], and [FunctionNode].
//
// DESIGN TODO: Should we remove the 'final' modifier from variables?
class VariableDeclaration extends Statement {
  /// For named parameters, this is the name of the parameter. No two named
  /// parameters (in the same parameter list) can have the same name.
  ///
  /// In all other cases, the name is cosmetic, may be empty or null,
  /// and is not necessarily unique.
  String name;
  int flags = 0;
  DartType type; // May be null.

  /// For locals, this is the initial value.
  /// For parameters, this is the default value.
  ///
  /// Should be null in other cases.
  Expression initializer; // May be null.

  VariableDeclaration(this.name,
      {this.initializer, this.type, bool isFinal: false, bool isConst: false}) {
    initializer?.parent = this;
    this.isFinal = isFinal;
    this.isConst = isConst;
  }

  /// Creates a synthetic variable with the given expression as initializer.
  VariableDeclaration.forValue(this.initializer,
      {bool isFinal: true, bool isConst: false, this.type}) {
    initializer?.parent = this;
    this.isFinal = isFinal;
    this.isConst = isConst;
  }

  static const int FlagFinal = 1 << 0; // Must match serialized bit positions.
  static const int FlagConst = 1 << 1;

  bool get isFinal => flags & FlagFinal != 0;
  bool get isConst => flags & FlagConst != 0;

  void set isFinal(bool value) {
    flags = value ? (flags | FlagFinal) : (flags & ~FlagFinal);
  }

  void set isConst(bool value) {
    flags = value ? (flags | FlagConst) : (flags & ~FlagConst);
  }

  accept(StatementVisitor v) => v.visitVariableDeclaration(this);

  visitChildren(Visitor v) {
    type?.accept(v);
    initializer?.accept(v);
  }

  transformChildren(Transformer v) {
    if (initializer != null) {
      initializer = initializer.accept(v);
      initializer?.parent = this;
    }
  }

  /// Returns a possibly synthesized name for this variable, consistent with
  /// the names used in [toString] calls.
  String get debugName => debugVariableDeclarationName(this);
}

/// Declaration a local function.
///
/// The body of the function may use [variable] as its self-reference.
class FunctionDeclaration extends Statement {
  VariableDeclaration variable; // Is final and has no initializer.
  FunctionNode function;

  FunctionDeclaration(this.variable, this.function) {
    variable?.parent = this;
    function?.parent = this;
  }

  accept(StatementVisitor v) => v.visitFunctionDeclaration(this);

  visitChildren(Visitor v) {
    variable?.accept(v);
    function?.accept(v);
  }

  transformChildren(Transformer v) {
    if (variable != null) {
      variable = variable.accept(v);
      variable?.parent = this;
    }
    if (function != null) {
      function = function.accept(v);
      function?.parent = this;
    }
  }
}

// ------------------------------------------------------------------------
//                                NAMES
// ------------------------------------------------------------------------

/// A public name, or a private name qualified by a library.
///
/// Names are only used for expressions with dynamic dispatch, as all
/// statically resolved references are represented in nameless form.
///
/// [Name]s are immutable and compare based on structural equality, and they
/// are not AST nodes.
///
/// The [toString] method returns a human-readable string that includes the
/// library name for private names; uniqueness is not guaranteed.
abstract class Name implements Node {
  final String name;
  Library get library;
  bool get isPrivate;

  Name._internal(this.name);

  factory Name(String name, [Library library]) {
    /// Use separate subclasses for the public and private case to save memory
    /// for public names.
    if (name.startsWith('_')) {
      return new _PrivateName(name, library);
    } else {
      return new _PublicName(name);
    }
  }

  bool operator ==(other) {
    return other is Name && name == other.name && library == other.library;
  }

  int get hashCode => 131 * name.hashCode + 17 * library.hashCode;

  accept(Visitor v) => v.visitName(this);

  visitChildren(Visitor v) {
    // DESIGN TODO: Should we visit the library as a library reference?
  }
}

class _PrivateName extends Name {
  final Library library;
  bool get isPrivate => true;

  _PrivateName(String name, this.library) : super._internal(name);

  String toString() => library != null ? '${library.name}::$name' : name;
}

class _PublicName extends Name {
  Library get library => null;
  bool get isPrivate => false;

  _PublicName(String name) : super._internal(name);

  String toString() => name;
}

// ------------------------------------------------------------------------
//                             TYPES
// ------------------------------------------------------------------------

/// A syntax-independent notion of a type.
///
/// [DartType]s are not AST nodes and may be shared between different parents.
///
/// [DartType] objects should be treated as unmodifiable objects, although
/// immutability is not enforced for List fields, and [TypeParameter]s are
/// cyclic structures that are constructed by mutation.
///
/// The `==` operator on [DartType]s compare based on type equality, not
/// object identity.  The [hashCode] function throws an exception because
/// canonicalization of generic function types is too expensive for hash codes
/// to have any practical use.
//
// TODO: Maybe we should just have a really crappy hash code for generic
//   function types so users can rely on hashCode if they know there will be
//   very few or no generic function types.
abstract class DartType extends Node {
  const DartType();

  accept(DartTypeVisitor v);

  bool operator ==(Object other);
  int get hashCode => throw 'DartType.hashCode is not allowed.';
}

/// The type arising from invalid type annotations.
///
/// Can usually be treated as 'dynamic', but should occasionally be handled
/// differently, e.g. `x is ERROR` should evaluate to false.
class InvalidType extends DartType {
  const InvalidType();

  accept(DartTypeVisitor v) => v.visitInvalidType(this);
  visitChildren(Visitor v) {}

  bool operator ==(Object other) => other is InvalidType;
}

class DynamicType extends DartType {
  const DynamicType();

  accept(DartTypeVisitor v) => v.visitDynamicType(this);
  visitChildren(Visitor v) {}

  bool operator ==(Object other) => other is DynamicType;
}

class VoidType extends DartType {
  const VoidType();

  accept(DartTypeVisitor v) => v.visitVoidType(this);
  visitChildren(Visitor v) {}

  bool operator ==(Object other) => other is VoidType;
}

class InterfaceType extends DartType {
  final Class classNode;
  final List<DartType> typeArguments;

  /// The [typeArguments] list must not be modified after this call. If the
  /// list is omitted, 'dynamic' type arguments are filled in.
  InterfaceType(Class classNode, [List<DartType> typeArguments])
      : this.classNode = classNode,
        this.typeArguments = typeArguments ?? _defaultTypeArguments(classNode);

  static List<DartType> _defaultTypeArguments(Class classNode) {
    if (classNode.typeParameters.length == 0) {
      // Avoid allocating a list in this very common case.
      return const <DartType>[];
    } else {
      return new List<DartType>.filled(
          classNode.typeParameters.length, const DynamicType());
    }
  }

  accept(DartTypeVisitor v) => v.visitInterfaceType(this);

  visitChildren(Visitor v) {
    classNode.acceptReference(v);
    _visitList(typeArguments, v);
  }

  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is InterfaceType) {
      if (classNode != other.classNode) return false;
      if (typeArguments.length != other.typeArguments.length) return false;
      for (int i = 0; i < typeArguments.length; ++i) {
        if (typeArguments[i] != other.typeArguments[i]) return false;
      }
      return true;
    } else {
      return false;
    }
  }
}

/// A possibly generic function type.
class FunctionType extends DartType {
  final List<TypeParameter> typeParameters;
  final int requiredParameterCount;
  final List<DartType> positionalParameters;
  final Map<String, DartType> namedParameters;
  final DartType returnType;

  FunctionType(List<DartType> positionalParameters, this.returnType,
      {this.namedParameters: const <String, DartType>{},
      this.typeParameters: const <TypeParameter>[],
      int requiredParameterCount})
      : this.positionalParameters = positionalParameters,
        this.requiredParameterCount =
            requiredParameterCount ?? positionalParameters.length;

  accept(DartTypeVisitor v) => v.visitFunctionType(this);

  visitChildren(Visitor v) {
    _visitList(typeParameters, v);
    _visitList(positionalParameters, v);
    _visitIterable(namedParameters.values, v);
    returnType.accept(v);
  }

  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is FunctionType) {
      if (typeParameters.length != other.typeParameters.length ||
          requiredParameterCount != other.requiredParameterCount ||
          positionalParameters.length != other.positionalParameters.length ||
          namedParameters.length != other.namedParameters.length) {
        return false;
      }
      if (typeParameters.isEmpty) {
        for (int i = 0; i < positionalParameters.length; ++i) {
          if (positionalParameters[i] != other.positionalParameters[i]) {
            return false;
          }
        }
        for (var name in namedParameters.keys) {
          // If the other function type declared differently named parameters,
          // one side of this equality will be null and we're good.
          if (namedParameters[name] != other.namedParameters[name]) {
            return false;
          }
        }
        return returnType == other.returnType;
      } else {
        // Structural equality does not tell us if two generic function types
        // are the same type.  If they are unifiable without substituting any
        // type variables, they are equal.
        return unifyTypes(this, other, new Set<TypeParameter>()) != null;
      }
    } else {
      return false;
    }
  }

  /// Returns a variant of this function type that does not declare any type
  /// parameters.
  ///
  /// Any uses of its type parameters become free variables in the returned
  /// type.
  FunctionType get withoutTypeParameters {
    if (typeParameters.isEmpty) return this;
    return new FunctionType(positionalParameters, returnType,
        requiredParameterCount: requiredParameterCount,
        namedParameters: namedParameters);
  }
}

/// Reference to a type variable.
class TypeParameterType extends DartType {
  TypeParameter parameter;

  TypeParameterType(this.parameter);

  accept(DartTypeVisitor v) => v.visitTypeParameterType(this);

  visitChildren(Visitor v) {}

  bool operator ==(Object other) {
    return other is TypeParameterType && parameter == other.parameter;
  }
}

/// Declaration of a type variable.
///
/// Type parameters declared in a [Class] or [FunctionNode] are part of the AST,
/// have a parent pointer to its declaring class or function, and will be seen
/// by tree visitors.
///
/// Type parameters declared by a [FunctionType] are orphans and have a `null`
/// parent pointer.  [TypeParameter] objects should not be shared between
/// different [FunctionType] objects.
class TypeParameter extends TreeNode {
  String name; // Cosmetic name.

  /// The bound on the type variable, or [DynamicType] if none was given.
  DartType bound;

  TypeParameter([this.name, this.bound = const DynamicType()]);

  accept(TreeVisitor v) => v.visitTypeParameter(this);

  visitChildren(Visitor v) {
    bound.accept(v);
  }

  transformChildren(Transformer v) {}

  /// Returns a possibly synthesized name for this type parameter, consistent
  /// with the names used in [toString] calls.
  String get debugName => debugTypeParameterName(this);
}

// ------------------------------------------------------------------------
//                                PROGRAM
// ------------------------------------------------------------------------

/// A way to bundle up all the libraries in a program.
class Program extends TreeNode {
  final List<Library> libraries;

  /// Reference to the main method in one of the libraries.
  Procedure mainMethod;

  Program([List<Library> libraries]) : libraries = libraries ?? <Library>[] {
    _setParents(libraries, this);
  }

  accept(TreeVisitor v) => v.visitProgram(this);

  visitChildren(Visitor v) {
    _visitList(libraries, v);
    mainMethod?.acceptReference(v);
  }

  transformChildren(Transformer v) {
    _transformList(libraries, v, this);
  }
}

// ------------------------------------------------------------------------
//                             INTERNAL FUNCTIONS
// ------------------------------------------------------------------------

void _setParents(List<TreeNode> nodes, TreeNode parent) {
  for (int i = 0; i < nodes.length; ++i) {
    nodes[i].parent = parent;
  }
}

void _visitList(List<Node> nodes, Visitor visitor) {
  for (int i = 0; i < nodes.length; ++i) {
    nodes[i].accept(visitor);
  }
}

void _visitIterable(Iterable<Node> nodes, Visitor visitor) {
  for (var node in nodes) {
    node.accept(visitor);
  }
}

void _transformList(
    List<TreeNode> nodes, Transformer visitor, TreeNode parent) {
  int storeIndex = 0;
  for (int i = 0; i < nodes.length; ++i) {
    var result = nodes[i].accept(visitor);
    if (result != null) {
      nodes[storeIndex] = result;
      result.parent = parent;
      ++storeIndex;
    }
  }
  if (storeIndex < nodes.length) {
    nodes.length = storeIndex;
  }
}

List<DartType> _getAsTypeArguments(List<TypeParameter> typeParameters) {
  if (typeParameters.isEmpty) return const <DartType>[];
  return new List<DartType>.generate(
      typeParameters.length, (i) => new TypeParameterType(typeParameters[i]),
      growable: false);
}

class _ChildReplacer extends Transformer {
  final TreeNode child;
  final TreeNode replacement;

  _ChildReplacer(this.child, this.replacement);

  defaultNode(TreeNode node) {
    if (node == child) {
      child.parent = null;
      return replacement;
    } else {
      return node;
    }
  }
}
