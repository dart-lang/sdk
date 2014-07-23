// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library elements;


import '../tree/tree.dart';
import '../util/util.dart';
import '../resolution/resolution.dart';

import '../dart2jslib.dart' show InterfaceType,
                                 DartType,
                                 TypeVariableType,
                                 TypedefType,
                                 DualKind,
                                 MessageKind,
                                 DiagnosticListener,
                                 Script,
                                 FunctionType,
                                 Selector,
                                 Constant,
                                 Compiler,
                                 isPrivateName;

import '../dart_types.dart';

import '../scanner/scannerlib.dart' show Token,
                                         isUserDefinableOperator,
                                         isMinusOperator;

import '../ordered_typeset.dart' show OrderedTypeSet;

import 'visitor.dart' show ElementVisitor;

part 'names.dart';

const int STATE_NOT_STARTED = 0;
const int STATE_STARTED = 1;
const int STATE_DONE = 2;

class ElementCategory {
  /**
   * Represents things that we don't expect to find when looking in a
   * scope.
   */
  static const int NONE = 0;

  /** Field, parameter, or variable. */
  static const int VARIABLE = 1;

  /** Function, method, or foreign function. */
  static const int FUNCTION = 2;

  static const int CLASS = 4;

  static const int PREFIX = 8;

  /** Constructor or factory. */
  static const int FACTORY = 16;

  static const int ALIAS = 32;

  static const int SUPER = 64;

  /** Type variable */
  static const int TYPE_VARIABLE = 128;

  static const int IMPLIES_TYPE = CLASS | ALIAS | TYPE_VARIABLE;
}

class ElementKind {
  final String id;
  final int category;

  const ElementKind(String this.id, this.category);

  static const ElementKind VARIABLE =
      const ElementKind('variable', ElementCategory.VARIABLE);
  static const ElementKind PARAMETER =
      const ElementKind('parameter', ElementCategory.VARIABLE);
  // Parameters in constructors that directly initialize fields. For example:
  // [:A(this.field):].
  static const ElementKind INITIALIZING_FORMAL =
      const ElementKind('initializing_formal', ElementCategory.VARIABLE);
  static const ElementKind FUNCTION =
      const ElementKind('function', ElementCategory.FUNCTION);
  static const ElementKind CLASS =
      const ElementKind('class', ElementCategory.CLASS);
  static const ElementKind GENERATIVE_CONSTRUCTOR =
      const ElementKind('generative_constructor', ElementCategory.FACTORY);
  static const ElementKind FIELD =
      const ElementKind('field', ElementCategory.VARIABLE);
  static const ElementKind FIELD_LIST =
      const ElementKind('field_list', ElementCategory.NONE);
  static const ElementKind GENERATIVE_CONSTRUCTOR_BODY =
      const ElementKind('generative_constructor_body', ElementCategory.NONE);
  static const ElementKind COMPILATION_UNIT =
      const ElementKind('compilation_unit', ElementCategory.NONE);
  static const ElementKind GETTER =
      const ElementKind('getter', ElementCategory.NONE);
  static const ElementKind SETTER =
      const ElementKind('setter', ElementCategory.NONE);
  static const ElementKind TYPE_VARIABLE =
      const ElementKind('type_variable', ElementCategory.TYPE_VARIABLE);
  static const ElementKind ABSTRACT_FIELD =
      const ElementKind('abstract_field', ElementCategory.VARIABLE);
  static const ElementKind LIBRARY =
      const ElementKind('library', ElementCategory.NONE);
  static const ElementKind PREFIX =
      const ElementKind('prefix', ElementCategory.PREFIX);
  static const ElementKind TYPEDEF =
      const ElementKind('typedef', ElementCategory.ALIAS);

  static const ElementKind AMBIGUOUS =
      const ElementKind('ambiguous', ElementCategory.NONE);
  static const ElementKind WARN_ON_USE =
      const ElementKind('warn_on_use', ElementCategory.NONE);
  static const ElementKind ERROR =
      const ElementKind('error', ElementCategory.NONE);

  toString() => id;
}

/// Abstract interface for entities.
///
/// Implement this directly if the entity is not a Dart language entity.
/// Entities defined within the Dart language should implement [Element].
///
/// For instance, the JavaScript backend need to create synthetic variables for
/// calling intercepted classes and such variables do not correspond to an
/// entity in the Dart source code nor in the terminology of the Dart language
/// and should therefore implement [Entity] directly.
abstract class Entity implements Spannable {
  String get name;
}

/**
 * A declared element of a program.
 *
 * The declared elements of a program include classes, methods,
 * fields, variables, parameters, etc.
 *
 * Sometimes it makes sense to construct "synthetic" elements that
 * have not been declared anywhere in a program, for example, there
 * are elements corresponding to "dynamic", "null", and unresolved
 * references.
 *
 * Elements are distinct from types ([DartType]). For example, there
 * is one declaration of the class List, but several related types,
 * for example, List, List<int>, List<String>, etc.
 *
 * Elements are distinct from AST nodes ([Node]), and there normally is a
 * one-to-one correspondence between an AST node and an element
 * (except that not all kinds of AST nodes have an associated
 * element).
 *
 * AST nodes represent precisely what is written in source code, for
 * example, when a user writes "class MyClass {}", the corresponding
 * AST node does not have a superclass. On the other hand, the
 * corresponding element (once fully resolved) will record the
 * information about the implicit superclass as defined by the
 * language semantics.
 *
 * Generally, the contents of a method are represented as AST nodes
 * without additional elements, but things like local functions, local
 * variables, and labels have a corresponding element.
 *
 * We generally say that scanning, parsing, resolution, and type
 * checking comprise the "front-end" of the compiler. The "back-end"
 * includes things like SSA graph construction, optimizations, and
 * code generation.
 *
 * The front-end data structures are designed to be reusable by
 * several back-ends.  For example, we may want to support emitting
 * minified Dart and JavaScript code in one go.  Also, we're planning
 * on adding an incremental compilation server that should be able to
 * reuse elements between compilations.  So to keep things simple, it
 * is best if the backends avoid setting state directly in elements.
 * It is better to keep such state in a table on the side.
 */
abstract class Element implements Entity {
  String get name;
  ElementKind get kind;
  Element get enclosingElement;
  Link<MetadataAnnotation> get metadata;

  /// Do not use [computeType] outside of the resolver; instead retrieve the
  /// type from the corresponding field:
  /// - `type` for fields, variables, type variable, and function elements.
  /// - `thisType` or `rawType` for [TypeDeclarationElement]s (classes and
  ///    typedefs), depending on the use case.
  /// Trying to access a type that has not been computed in resolution is an
  /// error and calling [computeType] covers that error.
  /// This method will go away!
  @deprecated DartType computeType(Compiler compiler);

  /// `true` if this element is a library.
  bool get isLibrary => kind == ElementKind.LIBRARY;

  /// `true` if this element is a compilation unit.
  bool get isCompilationUnit => kind == ElementKind.COMPILATION_UNIT;

  /// `true` if this element is defines the scope of prefix used by one or
  /// more import declarations.
  bool get isPrefix => kind == ElementKind.PREFIX;

  /// `true` if this element is a class declaration or a mixin application.
  bool get isClass => kind == ElementKind.CLASS;

  /// `true` if this element is a type variable declaration.
  bool get isTypeVariable => kind == ElementKind.TYPE_VARIABLE;

  /// `true` if this element is a typedef declaration.
  bool get isTypedef => kind == ElementKind.TYPEDEF;

  /// `true` if this element is a top level function, static or instance
  /// method, local function or closure defined by a function expression.
  ///
  /// This property is `true` for operator methods and factory constructors but
  /// `false` for getter and setter methods, and generative constructors.
  ///
  /// See also [isConstructor], [isGenerativeConstructor], and
  /// [isFactoryConstructor] for constructor properties, and [isAccessor],
  /// [isGetter] and [isSetter] for getter/setter properties.
  bool get isFunction => kind == ElementKind.FUNCTION;

  /// `true` if this element is an operator method.
  bool get isOperator;

  /// `true` if this element is an accessor, that is either an explicit
  /// getter or an explicit setter.
  bool get isAccessor => isGetter || isSetter;

  /// `true` if this element is an explicit getter method.
  bool get isGetter => kind == ElementKind.GETTER;

  /// `true` if this element is an explicit setter method.
  bool get isSetter => kind == ElementKind.SETTER;

  /// `true` if this element is a generative or factory constructor.
  bool get isConstructor => isGenerativeConstructor ||  isFactoryConstructor;

  /// `true` if this element is a generative constructor, potentially
  /// redirecting.
  bool get isGenerativeConstructor =>
      kind == ElementKind.GENERATIVE_CONSTRUCTOR;

  /// `true` if this element is the body of a generative constructor.
  ///
  /// This is a synthetic element kind used only be the JavaScript backend.
  bool get isGenerativeConstructorBody =>
      kind == ElementKind.GENERATIVE_CONSTRUCTOR_BODY;

  /// `true` if this element is a factory constructor,
  /// potentially redirecting.
  bool get isFactoryConstructor;

  /// `true` if this element is a local variable.
  bool get isVariable => kind == ElementKind.VARIABLE;

  /// `true` if this element is a top level variable, static or instance field.
  bool get isField => kind == ElementKind.FIELD;

  /// `true` if this element is the abstract field implicitly defined by an
  /// explicit getter and/or setter.
  bool get isAbstractField => kind == ElementKind.ABSTRACT_FIELD;

  /// `true` if this element is formal parameter either from a constructor,
  /// method, or typedef declaration or from an inlined function typed
  /// parameter.
  ///
  /// This property is `false` if this element is an initializing formal.
  /// See [isInitializingFormal].
  bool get isParameter => kind == ElementKind.PARAMETER;

  /// `true` if this element is an initializing formal of constructor, that
  /// is a formal of the form `this.foo`.
  bool get isInitializingFormal => kind == ElementKind.INITIALIZING_FORMAL;

  /// `true` if this element represents a resolution error.
  bool get isErroneous => kind == ElementKind.ERROR;

  /// `true` if this element represents an ambiguous name.
  ///
  /// Ambiguous names occur when two imports/exports contain different entities
  /// by the same name. If an ambiguous name is resolved an warning or error
  /// is produced.
  bool get isAmbiguous => kind == ElementKind.AMBIGUOUS;

  /// `true` if this element represents an entity whose access causes one or
  /// more warnings.
  bool get isWarnOnUse => kind == ElementKind.WARN_ON_USE;

  bool get isClosure;

  /// `true` if the element is a (static or instance) member of a class.
  ///
  /// Members are constructors, methods and fields.
  bool get isClassMember;

  /// `true` if the element is a nonstatic member of a class.
  ///
  /// Instance members are methods and fields but not constructors.
  bool get isInstanceMember;

  /// Returns true if this [Element] is a top level element.
  /// That is, if it is not defined within the scope of a class.
  ///
  /// This means whether the enclosing element is a compilation unit.
  /// With the exception of [ClosureClassElement] that is considered top level
  /// as all other classes.
  bool get isTopLevel;
  bool get isAssignable;
  bool get isNative;
  bool get isDeferredLoaderGetter;

  /// True if the element is declared in a patch library but has no
  /// corresponding declaration in the origin library.
  bool get isInjected;

  /// `true` if this element is a constructor, top level or local variable,
  /// or static field that is declared `const`.
  bool get isConst;

  /// `true` if this element is a top level or local variable, static or
  /// instance field, or parameter that is declared `final`.
  bool get isFinal;

  /// `true` if this element is a method, getter, setter or field that
  /// is declared `static`.
  bool get isStatic;

  bool get impliesType;

  Token get position;

  CompilationUnitElement get compilationUnit;
  LibraryElement get library;
  LibraryElement get implementationLibrary;
  ClassElement get enclosingClass;
  Element get enclosingClassOrCompilationUnit;
  Element get outermostEnclosingMemberOrTopLevel;

  /// The enclosing class that defines the type environment for this element.
  ClassElement get contextClass;

  FunctionElement asFunctionElement();

  /// Is [:true:] if this element has a corresponding patch.
  ///
  /// If [:true:] this element has a non-null [patch] field.
  ///
  /// See [:patch_parser.dart:] for a description of the terminology.
  bool get isPatched;

  /// Is [:true:] if this element is a patch.
  ///
  /// If [:true:] this element has a non-null [origin] field.
  ///
  /// See [:patch_parser.dart:] for a description of the terminology.
  bool get isPatch;

  /// Is [:true:] if this element defines the implementation for the entity of
  /// this element.
  ///
  /// See [:patch_parser.dart:] for a description of the terminology.
  bool get isImplementation;

  /// Is [:true:] if this element introduces the entity of this element.
  ///
  /// See [:patch_parser.dart:] for a description of the terminology.
  bool get isDeclaration;

  /// Returns the element which defines the implementation for the entity of
  /// this element.
  ///
  /// See [:patch_parser.dart:] for a description of the terminology.
  Element get implementation;

  /// Returns the element which introduces the entity of this element.
  ///
  /// See [:patch_parser.dart:] for a description of the terminology.
  Element get declaration;

  /// Returns the patch for this element if this element is patched.
  ///
  /// See [:patch_parser.dart:] for a description of the terminology.
  Element get patch;

  /// Returns the origin for this element if this element is a patch.
  ///
  /// See [:patch_parser.dart:] for a description of the terminology.
  Element get origin;

  bool get isSynthesized;
  bool get isForwardingConstructor;
  bool get isMixinApplication;

  bool get hasFixedBackendName;
  String get fixedBackendName;

  bool get isAbstract;
  bool isForeign(Compiler compiler);

  void addMetadata(MetadataAnnotation annotation);
  void setNative(String name);
  void setFixedBackendName(String name);

  Scope buildScope();

  void diagnose(Element context, DiagnosticListener listener);

  // TODO(johnniwinther): Move this to [AstElement].
  /// Returns the [Element] that holds the [TreeElements] for this element.
  AnalyzableElement get analyzableElement;

  accept(ElementVisitor visitor);
}

class Elements {
  static bool isUnresolved(Element e) {
    return e == null || e.isErroneous;
  }
  static bool isErroneousElement(Element e) => e != null && e.isErroneous;

  /// Unwraps [element] reporting any warnings attached to it, if any.
  static Element unwrap(Element element,
                        DiagnosticListener listener,
                        Spannable spannable) {
    if (element != null && element.isWarnOnUse) {
      WarnOnUseElement wrappedElement = element;
      element = wrappedElement.unwrap(listener, spannable);
    }
    return element;
  }

  static bool isClass(Element e) => e != null && e.kind == ElementKind.CLASS;
  static bool isTypedef(Element e) {
    return e != null && e.kind == ElementKind.TYPEDEF;
  }

  static bool isLocal(Element element) {
    return !Elements.isUnresolved(element)
            && !element.isInstanceMember
            && !isStaticOrTopLevelField(element)
            && !isStaticOrTopLevelFunction(element)
            && (identical(element.kind, ElementKind.VARIABLE) ||
                identical(element.kind, ElementKind.PARAMETER) ||
                identical(element.kind, ElementKind.FUNCTION));
  }

  static bool isInstanceField(Element element) {
    return !Elements.isUnresolved(element)
           && element.isInstanceMember
           && (identical(element.kind, ElementKind.FIELD)
               || identical(element.kind, ElementKind.GETTER)
               || identical(element.kind, ElementKind.SETTER));
  }

  static bool isStaticOrTopLevel(Element element) {
    // TODO(ager): This should not be necessary when patch support has
    // been reworked.
    if (!Elements.isUnresolved(element)
        && element.isStatic) {
      return true;
    }
    return !Elements.isUnresolved(element)
           && !element.isAmbiguous
           && !element.isInstanceMember
           && !element.isPrefix
           && element.enclosingElement != null
           && (element.enclosingElement.kind == ElementKind.CLASS ||
               element.enclosingElement.kind == ElementKind.COMPILATION_UNIT ||
               element.enclosingElement.kind == ElementKind.LIBRARY ||
               element.enclosingElement.kind == ElementKind.PREFIX);
  }

  static bool isInStaticContext(Element element) {
    if (isUnresolved(element)) return true;
    if (element.enclosingElement.isClosure) {
      var closureClass = element.enclosingElement;
      element = closureClass.methodElement;
    }
    Element outer = element.outermostEnclosingMemberOrTopLevel;
    if (isUnresolved(outer)) return true;
    if (outer.isTopLevel) return true;
    if (outer.isGenerativeConstructor) return false;
    if (outer.isInstanceMember) return false;
    return true;
  }

  static bool isStaticOrTopLevelField(Element element) {
    return isStaticOrTopLevel(element)
           && (identical(element.kind, ElementKind.FIELD)
               || identical(element.kind, ElementKind.GETTER)
               || identical(element.kind, ElementKind.SETTER));
  }

  static bool isStaticOrTopLevelFunction(Element element) {
    return isStaticOrTopLevel(element)
           && (identical(element.kind, ElementKind.FUNCTION));
  }

  static bool isInstanceMethod(Element element) {
    return !Elements.isUnresolved(element)
           && element.isInstanceMember
           && (identical(element.kind, ElementKind.FUNCTION));
  }

  static bool isNativeOrExtendsNative(ClassElement element) {
    if (element == null) return false;
    if (element.isNative) return true;
    assert(element.resolutionState == STATE_DONE);
    return isNativeOrExtendsNative(element.superclass);
  }

  static bool isInstanceSend(Send send, TreeElements elements) {
    Element element = elements[send];
    if (element == null) return !isClosureSend(send, element);
    return isInstanceMethod(element) || isInstanceField(element);
  }

  static bool isClosureSend(Send send, Element element) {
    if (send.isPropertyAccess) return false;
    if (send.receiver != null) return false;
    Node selector = send.selector;
    // this().
    if (selector.isThis()) return true;
    // (o)() or foo()().
    if (element == null && selector.asIdentifier() == null) return true;
    if (element == null) return false;
    // foo() with foo a local or a parameter.
    return isLocal(element);
  }

  static String reconstructConstructorNameSourceString(Element element) {
    if (element.name == '') {
      return element.enclosingClass.name;
    } else {
      return reconstructConstructorName(element);
    }
  }

  // TODO(johnniwinther): Remove this method.
  static String reconstructConstructorName(Element element) {
    String className = element.enclosingClass.name;
    if (element.name == '') {
      return className;
    } else {
      return '$className\$${element.name}';
    }
  }

  static String constructorNameForDiagnostics(String className,
                                              String constructorName) {
    String classNameString = className;
    String constructorNameString = constructorName;
    return (constructorName == '')
        ? classNameString
        : "$classNameString.$constructorNameString";
  }

  /// Returns `true` if [name] is the name of an operator method.
  static bool isOperatorName(String name) {
    return name == 'unary-' || isUserDefinableOperator(name);
  }

  /**
   * Map an operator-name to a valid JavaScript identifier.
   *
   * For non-operator names, this method just returns its input.
   *
   * The results returned from this method are guaranteed to be valid
   * JavaScript identifers, except it may include reserved words for
   * non-operator names.
   */
  static String operatorNameToIdentifier(String name) {
    if (name == null) {
      return name;
    } else if (identical(name, '==')) {
      return r'operator$eq';
    } else if (identical(name, '~')) {
      return r'operator$not';
    } else if (identical(name, '[]')) {
      return r'operator$index';
    } else if (identical(name, '[]=')) {
      return r'operator$indexSet';
    } else if (identical(name, '*')) {
      return r'operator$mul';
    } else if (identical(name, '/')) {
      return r'operator$div';
    } else if (identical(name, '%')) {
      return r'operator$mod';
    } else if (identical(name, '~/')) {
      return r'operator$tdiv';
    } else if (identical(name, '+')) {
      return r'operator$add';
    } else if (identical(name, '<<')) {
      return r'operator$shl';
    } else if (identical(name, '>>')) {
      return r'operator$shr';
    } else if (identical(name, '>=')) {
      return r'operator$ge';
    } else if (identical(name, '>')) {
      return r'operator$gt';
    } else if (identical(name, '<=')) {
      return r'operator$le';
    } else if (identical(name, '<')) {
      return r'operator$lt';
    } else if (identical(name, '&')) {
      return r'operator$and';
    } else if (identical(name, '^')) {
      return r'operator$xor';
    } else if (identical(name, '|')) {
      return r'operator$or';
    } else if (identical(name, '-')) {
      return r'operator$sub';
    } else if (identical(name, 'unary-')) {
      return r'operator$negate';
    } else {
      return name;
    }
  }

  static String constructOperatorNameOrNull(String op, bool isUnary) {
    if (isMinusOperator(op)) {
      return isUnary ? 'unary-' : op;
    } else if (isUserDefinableOperator(op)) {
      return op;
    } else {
      return null;
    }
  }

  static String constructOperatorName(String op, bool isUnary) {
    String operatorName = constructOperatorNameOrNull(op, isUnary);
    if (operatorName == null) throw 'Unhandled operator: $op';
    else return operatorName;
  }

  static String mapToUserOperatorOrNull(String op) {
    if (identical(op, '!=')) return '==';
    if (identical(op, '*=')) return '*';
    if (identical(op, '/=')) return '/';
    if (identical(op, '%=')) return '%';
    if (identical(op, '~/=')) return '~/';
    if (identical(op, '+=')) return '+';
    if (identical(op, '-=')) return '-';
    if (identical(op, '<<=')) return '<<';
    if (identical(op, '>>=')) return '>>';
    if (identical(op, '&=')) return '&';
    if (identical(op, '^=')) return '^';
    if (identical(op, '|=')) return '|';

    return null;
  }

  static String mapToUserOperator(String op) {
    String userOperator = mapToUserOperatorOrNull(op);
    if (userOperator == null) throw 'Unhandled operator: $op';
    else return userOperator;
  }

  static bool isNumberOrStringSupertype(Element element, Compiler compiler) {
    LibraryElement coreLibrary = compiler.coreLibrary;
    return (element == coreLibrary.find('Comparable'));
  }

  static bool isStringOnlySupertype(Element element, Compiler compiler) {
    LibraryElement coreLibrary = compiler.coreLibrary;
    return element == coreLibrary.find('Pattern');
  }

  static bool isListSupertype(Element element, Compiler compiler) {
    LibraryElement coreLibrary = compiler.coreLibrary;
    return element == coreLibrary.find('Iterable');
  }

  /// A `compareTo` function that places [Element]s in a consistent order based
  /// on the source code order.
  static int compareByPosition(Element a, Element b) {
    if (identical(a, b)) return 0;
    int r = a.library.compareTo(b.library);
    if (r != 0) return r;
    r = a.compilationUnit.compareTo(b.compilationUnit);
    if (r != 0) return r;
    Token positionA = a.position;
    Token positionB = b.position;
    int offsetA = positionA == null ? -1 : positionA.charOffset;
    int offsetB = positionB == null ? -1 : positionB.charOffset;
    r = offsetA.compareTo(offsetB);
    if (r != 0) return r;
    r = a.name.compareTo(b.name);
    if (r != 0) return r;
    // Same file, position and name.  If this happens, we should find out why
    // and make the order total and independent of hashCode.
    return a.hashCode.compareTo(b.hashCode);
  }

  static List<Element> sortedByPosition(Iterable<Element> elements) {
    return elements.toList()..sort(compareByPosition);
  }

  static bool isFixedListConstructorCall(Element element,
                                         Send node,
                                         Compiler compiler) {
    return element == compiler.unnamedListConstructor
        && node.isCall
        && !node.arguments.isEmpty
        && node.arguments.tail.isEmpty;
  }

  static bool isGrowableListConstructorCall(Element element,
                                            Send node,
                                            Compiler compiler) {
    return element == compiler.unnamedListConstructor
        && node.isCall
        && node.arguments.isEmpty;
  }

  static bool isFilledListConstructorCall(Element element,
                                          Send node,
                                          Compiler compiler) {
    return element == compiler.filledListConstructor
        && node.isCall
        && !node.arguments.isEmpty
        && !node.arguments.tail.isEmpty
        && node.arguments.tail.tail.isEmpty;
  }

  static bool isConstructorOfTypedArraySubclass(Element element,
                                                Compiler compiler) {
    if (compiler.typedDataLibrary == null) return false;
    if (!element.isConstructor) return false;
    ConstructorElement constructor = element;
    constructor = constructor.effectiveTarget;
    ClassElement cls = constructor.enclosingClass;
    return cls.library == compiler.typedDataLibrary
        && cls.isNative
        && compiler.world.isSubtype(compiler.typedDataClass, cls)
        && compiler.world.isSubtype(compiler.listClass, cls)
        && constructor.name == '';
  }

  static bool switchStatementHasContinue(SwitchStatement node,
                                         TreeElements elements) {
    for (SwitchCase switchCase in node.cases) {
      for (Node labelOrCase in switchCase.labelsAndCases) {
        Node label = labelOrCase.asLabel();
        if (label != null) {
          LabelDefinition labelElement = elements.getLabelDefinition(label);
          if (labelElement != null && labelElement.isContinueTarget) {
            return true;
          }
        }
      }
    }
    return false;
  }

  static bool isUnusedLabel(LabeledStatement node, TreeElements elements) {
    Node body = node.statement;
    JumpTarget element = elements.getTargetDefinition(body);
    // Labeled statements with no element on the body have no breaks.
    // A different target statement only happens if the body is itself
    // a break or continue for a different target. In that case, this
    // label is also always unused.
    return element == null || element.statement != body;
  }
}

/// An element representing an erroneous resolution.
///
/// An [ErroneousElement] is used instead of `null` to provide additional
/// information about the error that caused the element to be unresolvable
/// or otherwise invalid.
///
/// Accessing any field or calling any method defined on [ErroneousElement]
/// except [isErroneous] will currently throw an exception. (This might
/// change when we actually want more information on the erroneous element,
/// e.g., the name of the element we were trying to resolve.)
///
/// Code that cannot not handle an [ErroneousElement] should use
/// `Element.isUnresolved(element)` to check for unresolvable elements instead
/// of `element == null`.
abstract class ErroneousElement extends Element implements ConstructorElement {
  MessageKind get messageKind;
  Map get messageArguments;
  String get message;
}

/// An [Element] whose usage should cause one or more warnings.
abstract class WarnOnUseElement extends Element {
  /// The element whose usage cause a warning.
  Element get wrappedElement;

  /// Reports the attached warning and returns the wrapped element.
  /// [usageSpannable] is used to report messages on the reference of
  /// [wrappedElement].
  Element unwrap(DiagnosticListener listener, Spannable usageSpannable);
}

/// An ambiguous element represents multiple elements accessible by the same
/// name.
///
/// Ambiguous elements are created during handling of import/export scopes. If
/// an ambiguous element is encountered during resolution a warning/error is
/// reported.
abstract class AmbiguousElement extends Element {
  MessageKind get messageKind;
  Map get messageArguments;
  Element get existingElement;
  Element get newElement;
}

// TODO(kasperl): This probably shouldn't be called an element. It's
// just an interface shared by classes and libraries.
abstract class ScopeContainerElement implements Element {
  Element localLookup(String elementName);

  void forEachLocalMember(f(Element element));
}

abstract class CompilationUnitElement extends Element {
  Script get script;
  PartOf get partTag;

  void forEachLocalMember(f(Element element));
  void addMember(Element element, DiagnosticListener listener);
  void setPartOf(PartOf tag, DiagnosticListener listener);
  bool get hasMembers;

  int compareTo(CompilationUnitElement other);
}

abstract class LibraryElement extends Element
    implements ScopeContainerElement, AnalyzableElement {
  /**
   * The canonical uri for this library.
   *
   * For user libraries the canonical uri is the script uri. For platform
   * libraries the canonical uri is of the form [:dart:x:].
   */
  Uri get canonicalUri;
  CompilationUnitElement get entryCompilationUnit;
  Link<CompilationUnitElement> get compilationUnits;
  Iterable<LibraryTag> get tags;
  LibraryName get libraryTag;
  Link<Element> get exports;

  /**
   * [:true:] if this library is part of the platform, that is, its canonical
   * uri has the scheme 'dart'.
   */
  bool get isPlatformLibrary;

  /**
   * [:true:] if this library is from a package, that is, its canonical uri has
   * the scheme 'package'.
   */
  bool get isPackageLibrary;

  /**
   * [:true:] if this library is a platform library whose path starts with
   * an underscore.
   */
  bool get isInternalLibrary;
  bool get canUseNative;
  bool get exportsHandled;

  // TODO(kasperl): We should try to get rid of these.
  void set canUseNative(bool value);
  void set libraryTag(LibraryName value);

  LibraryElement get implementation;

  void addCompilationUnit(CompilationUnitElement element);
  void addTag(LibraryTag tag, DiagnosticListener listener);
  void addImport(Element element, Import import, DiagnosticListener listener);

  /// Record which element an import or export tag resolved to.
  /// (Belongs on builder object).
  void recordResolvedTag(LibraryDependency tag, LibraryElement library);

  /// Return the library element corresponding to an import or export.
  LibraryElement getLibraryFromTag(LibraryDependency tag);

  void addMember(Element element, DiagnosticListener listener);
  void addToScope(Element element, DiagnosticListener listener);

  // TODO(kasperl): Get rid of this method.
  Iterable<Element> getNonPrivateElementsInScope();

  void setExports(Iterable<Element> exportedElements);

  Element find(String elementName);
  Element findLocal(String elementName);
  Element findExported(String elementName);
  void forEachExport(f(Element element));

  /// Returns the imports that import element into this library.
  Link<Import> getImportsFor(Element element);

  bool hasLibraryName();
  String getLibraryName();
  String getLibraryOrScriptName();

  int compareTo(LibraryElement other);
}

/// The implicit scope defined by a import declaration with a prefix clause.
abstract class PrefixElement extends Element {
  void addImport(Element element, Import import, DiagnosticListener listener);
  Element lookupLocalMember(String memberName);
  /// Is true if this prefix belongs to a deferred import.
  bool get isDeferred;
  void markAsDeferred(Import import);
  Import get deferredImport;
}

/// A type alias definition.
abstract class TypedefElement extends Element
    implements AstElement, TypeDeclarationElement, FunctionTypedElement {

  /// The type defined by this typedef with the type variables as its type
  /// arguments.
  ///
  /// For instance `F<T>` for `typedef void F<T>(T t)`.
  TypedefType get thisType;

  /// The type defined by this typedef with `dynamic` as its type arguments.
  ///
  /// For instance `F<dynamic>` for `typedef void F<T>(T t)`.
  TypedefType get rawType;

  /// The type, function type if well-defined, for which this typedef is an
  /// alias.
  ///
  /// For instance `(int)->void` for `typedef void F(int)`.
  DartType get alias;

  void checkCyclicReference(Compiler compiler);
}

/// An executable element is an element that can hold code.
///
/// These elements variables (fields, parameters and locals), which can hold
/// code in their initializer, and functions (including methods and
/// constructors), which can hold code in their body.
abstract class ExecutableElement extends Element
    implements TypedElement, AstElement {
  /// The outermost member that contains this element.
  ///
  /// For top level, static or instance members, the member context is the
  /// element itself. For parameters, local variables and nested closures, the
  /// member context is the top level, static or instance member in which it is
  /// defined.
  MemberElement get memberContext;
}

/// A top-level or static field or method, or a constructor.
///
/// A [MemberElement] is the outermost executable element for any executable
/// context.
abstract class MemberElement extends Element implements ExecutableElement {
  /// The local functions defined within this member.
  List<FunctionElement> get nestedClosures;
}

/// A function, variable or parameter defined in an executable context.
abstract class LocalElement extends Element implements TypedElement, Local {
}

/// A top level, static or instance field, a formal parameter or local variable.
abstract class VariableElement extends ExecutableElement {
  Expression get initializer;
}

/// An entity that defines a local entity (memory slot) in generated code.
///
/// Parameters, local variables and local functions (can) define local entity
/// and thus implement [Local] through [LocalElement]. For non-element locals,
/// like `this` and boxes, specialized [Local] classes are created.
///
/// Type variables can introduce locals in factories and constructors
/// but since one type variable can introduce different locals in different
/// factories and constructors it is not itself a [Local] but instead
/// a non-element [Local] is created through a specialized class.
// TODO(johnniwinther): Should [Local] have `isAssignable` or `type`?
abstract class Local extends Entity {
  /// The context in which this local is defined.
  ExecutableElement get executableContext;
}

/// A variable or parameter that is local to an executable context.
///
/// The executable context is the [ExecutableElement] in which this variable
/// is defined.
abstract class LocalVariableElement extends VariableElement
    implements LocalElement {
}

/// A top-level, static or instance field.
abstract class FieldElement extends VariableElement implements MemberElement {
}

/// A parameter-like element of a function signature.
///
/// If the function signature comes from a typedef or an inline function-typed
/// parameter (e.g. the parameter 'f' in `method(void f())`), then its
/// parameters are not real parameters in that they can take no argument and
/// hold no value. Such parameter-like elements are modeled by [FormalElement].
///
/// If the function signature comes from a function or constructor, its
/// parameters are real parameters and are modeled by [ParameterElement].
abstract class FormalElement extends Element
    implements FunctionTypedElement, TypedElement, AstElement {
  /// Use [functionDeclaration] instead.
  @deprecated
  get enclosingElement;

  /// The function, typedef or inline function-typed parameter on which
  /// this parameter is declared.
  FunctionTypedElement get functionDeclaration;

  VariableDefinitions get node;
}

/// A formal parameter of a function or constructor.
///
/// Normal parameter that introduce a local variable are modeled by
/// [LocalParameterElement] whereas initializing formals, that is parameter of
/// the form `this.x`, are modeled by [InitializingFormalParameter].
abstract class ParameterElement extends Element
    implements VariableElement, FormalElement, LocalElement {
  /// The function on which this parameter is declared.
  FunctionElement get functionDeclaration;
}

/// A formal parameter on a function or constructor that introduces a local
/// variable in the scope of the function or constructor.
abstract class LocalParameterElement extends ParameterElement
    implements LocalVariableElement {
}

/// A formal parameter in a constructor that directly initializes a field.
///
/// For example: `A(this.field)`.
abstract class InitializingFormalElement extends ParameterElement {
  /// The field initialized by this initializing formal.
  FieldElement get fieldElement;

  /// The function on which this parameter is declared.
  ConstructorElement get functionDeclaration;
}

/**
 * A synthetic element which holds a getter and/or a setter.
 *
 * This element unifies handling of fields and getters/setters.  When
 * looking at code like "foo.x", we don't have to look for both a
 * field named "x", a getter named "x", and a setter named "x=".
 */
abstract class AbstractFieldElement extends Element {
  FunctionElement get getter;
  FunctionElement get setter;
}

abstract class FunctionSignature {
  FunctionType get type;
  Link<FormalElement> get requiredParameters;
  Link<FormalElement> get optionalParameters;

  int get requiredParameterCount;
  int get optionalParameterCount;
  bool get optionalParametersAreNamed;
  FormalElement get firstOptionalParameter;

  int get parameterCount;
  List<FormalElement> get orderedOptionalParameters;

  void forEachParameter(void function(FormalElement parameter));
  void forEachRequiredParameter(void function(FormalElement parameter));
  void forEachOptionalParameter(void function(FormalElement parameter));

  void orderedForEachParameter(void function(FormalElement parameter));

  bool isCompatibleWith(FunctionSignature constructorSignature);
}

/// A top level, static or instance method, constructor, local function, or
/// closure (anonymous local function).
abstract class FunctionElement extends Element
    implements AstElement,
               TypedElement,
               FunctionTypedElement,
               ExecutableElement {
  FunctionExpression get node;

  FunctionElement get patch;
  FunctionElement get origin;

  /// Used to retrieve a link to the abstract field element representing this
  /// element.
  AbstractFieldElement get abstractField;

  /// Do not use [computeSignature] outside of the resolver; instead retrieve
  /// the signature through the [functionSignature] field.
  /// Trying to access a function signature that has not been computed in
  /// resolution is an error and calling [computeSignature] covers that error.
  /// This method will go away!
  @deprecated FunctionSignature computeSignature(Compiler compiler);
}

/// A top level, static or instance function.
abstract class MethodElement extends FunctionElement
    implements MemberElement {
}

/// A local function or closure (anonymous local function).
abstract class LocalFunctionElement extends FunctionElement
    implements LocalElement {
}

/// A constructor.
abstract class ConstructorElement extends FunctionElement
    implements MemberElement {
  /// The effective target of this constructor, that is the non-redirecting
  /// constructor that is called on invocation of this constructor.
  ///
  /// Consider for instance this hierachy:
  ///
  ///     class C { factory C.c() = D.d; }
  ///     class D { factory D.d() = E.e2; }
  ///     class E { E.e1();
  ///               E.e2() : this.e1(); }
  ///
  /// The effective target of both `C.c`, `D.d`, and `E.e2` is `E.e2`, and the
  /// effective target of `E.e1` is `E.e1` itself.
  ConstructorElement get effectiveTarget;

  /// The immediate redirection target of a redirecting factory constructor.
  ///
  /// Consider for instance this hierachy:
  ///
  ///     class C { factory C() = D; }
  ///     class D { factory D() = E; }
  ///     class E { E(); }
  ///
  /// The immediate redirection target of `C` is `D` and the immediate
  /// redirection target of `D` is `E`. `E` is not a redirecting factory
  /// constructor so its immediate redirection target is `null`.
  ConstructorElement get immediateRedirectionTarget;

  /// Is `true` if this constructor is a redirecting factory constructor.
  bool get isRedirectingFactory;

  /// Compute the type of the effective target of this constructor for an
  /// instantiation site with type [:newType:].
  InterfaceType computeEffectiveTargetType(InterfaceType newType);

  /// If this is a synthesized constructor [definingConstructor] points to
  /// the generative constructor from which this constructor was created.
  /// Otherwise [definingConstructor] is `null`.
  ///
  /// Consider for instance this hierarchy:
  ///
  ///     class C { C.c(a, {b});
  ///     class D {}
  ///     class E = C with D;
  ///
  /// Class `E` has a synthesized constructor, `E.c`, whose defining constructor
  /// is `C.c`.
  ConstructorElement get definingConstructor;

  /// Use [enclosingClass] instead.
  @deprecated
  get enclosingElement;
}

/// JavaScript backend specific element for the body of constructor.
// TODO(johnniwinther): Remove this class for the element model.
abstract class ConstructorBodyElement extends FunctionElement {
  FunctionElement get constructor;
}

/// [TypeDeclarationElement] defines the common interface for class/interface
/// declarations and typedefs.
abstract class TypeDeclarationElement extends Element implements AstElement {
  /**
   * The `this type` for this type declaration.
   *
   * The type of [:this:] is the generic type based on this element in which
   * the type arguments are the declared type variables. For instance,
   * [:List<E>:] for [:List:] and [:Map<K,V>:] for [:Map:].
   *
   * For a class declaration this is the type of [:this:].
   */
  GenericType get thisType;

  /**
   * The raw type for this type declaration.
   *
   * The raw type is the generic type base on this element in which the type
   * arguments are all [dynamic]. For instance [:List<dynamic>:] for [:List:]
   * and [:Map<dynamic,dynamic>:] for [:Map:]. For non-generic classes [rawType]
   * is the same as [thisType].
   *
   * The [rawType] field is a canonicalization of the raw type and should be
   * used to distinguish explicit and implicit uses of the [dynamic]
   * type arguments. For instance should [:List:] be the [rawType] of the
   * [:List:] class element whereas [:List<dynamic>:] should be its own
   * instantiation of [InterfaceType] with [:dynamic:] as type argument. Using
   * this distinction, we can print the raw type with type arguments only when
   * the input source has used explicit type arguments.
   */
  GenericType get rawType;

  /**
   * The type variables declared on this declaration. The type variables are not
   * available until the type of the element has been computed through
   * [computeType].
   */
  List<DartType> get typeVariables;

  bool get isResolved;

  int get resolutionState;

  void ensureResolved(Compiler compiler);
}

abstract class ClassElement extends TypeDeclarationElement
    implements ScopeContainerElement {
  int get id;

  /// The length of the longest inheritance path from [:Object:].
  int get hierarchyDepth;

  InterfaceType get rawType;
  InterfaceType get thisType;
  ClassElement get superclass;

  /// The direct supertype of this class.
  DartType get supertype;

  /// Ordered set of all supertypes of this class including the class itself.
  OrderedTypeSet get allSupertypesAndSelf;

  /// A list of all supertypes of this class excluding the class itself.
  Link<DartType> get allSupertypes;

  /// Returns the this type of this class as an instance of [cls].
  InterfaceType asInstanceOf(ClassElement cls);

  /// A list of all direct superinterfaces of this class.
  Link<DartType> get interfaces;

  bool get hasConstructor;
  Link<Element> get constructors;

  ClassElement get patch;
  ClassElement get origin;
  ClassElement get declaration;
  ClassElement get implementation;

  int get supertypeLoadState;
  String get nativeTagInfo;

  bool get isMixinApplication;
  bool get isUnnamedMixinApplication;
  bool get hasBackendMembers;
  bool get hasLocalScopeMembers;

  bool isObject(Compiler compiler);
  bool isSubclassOf(ClassElement cls);
  /// Returns true if `this` explicitly/nominally implements [intrface].
  ///
  /// Note that, if [intrface] is the `Function` class, this method returns
  /// falso for a class that has a `call` method but does not explicitly
  /// implement `Function`.
  bool implementsInterface(ClassElement intrface);
  bool hasFieldShadowedBy(Element fieldMember);

  /// Returns `true` if this class has a @proxy annotation.
  bool get isProxy;

  /// Returns `true` if the class hierarchy for this class contains errors.
  bool get hasIncompleteHierarchy;

  void addMember(Element element, DiagnosticListener listener);
  void addToScope(Element element, DiagnosticListener listener);

  void setDefaultConstructor(FunctionElement constructor, Compiler compiler);

  void addBackendMember(Element element);
  void reverseBackendMembers();

  Element lookupMember(String memberName);
  Element lookupSelector(Selector selector, Compiler compiler);
  Element lookupSuperSelector(Selector selector, Compiler compiler);

  Element lookupLocalMember(String memberName);
  Element lookupBackendMember(String memberName);
  Element lookupSuperMember(String memberName);

  Element lookupSuperMemberInLibrary(String memberName,
                                     LibraryElement library);

  Element validateConstructorLookupResults(Selector selector,
                                           Element result,
                                           Element noMatch(Element));

  Element lookupConstructor(Selector selector, [Element noMatch(Element)]);

  void forEachMember(void f(ClassElement enclosingClass, Element member),
                     {bool includeBackendMembers: false,
                      bool includeSuperAndInjectedMembers: false});

  void forEachInstanceField(void f(ClassElement enclosingClass,
                                   FieldElement field),
                            {bool includeSuperAndInjectedMembers: false});

  /// Similar to [forEachInstanceField] but visits static fields.
  void forEachStaticField(void f(ClassElement enclosingClass, Element field));

  void forEachBackendMember(void f(Element member));

  List<DartType> computeTypeParameters(Compiler compiler);

  /// Looks up the member [name] in this class.
  Member lookupClassMember(Name name);

  /// Calls [f] with each member of this class.
  void forEachClassMember(f(Member member));

  /// Looks up the member [name] in the interface of this class.
  MemberSignature lookupInterfaceMember(Name name);

  /// Calls [f] with each member of the interface of this class.
  void forEachInterfaceMember(f(MemberSignature member));

  /// Returns the type of the 'call' method in the interface of this class, or
  /// `null` if the interface has no 'call' method.
  FunctionType get callType;
}

abstract class MixinApplicationElement extends ClassElement {
  ClassElement get mixin;
  InterfaceType get mixinType;
  void set mixinType(InterfaceType value);
  void addConstructor(FunctionElement constructor);
}

/// The label entity defined by a labeled statement.
abstract class LabelDefinition extends Entity {
  Label get label;
  String get labelName;
  JumpTarget get target;

  bool get isTarget;
  bool get isBreakTarget;
  bool get isContinueTarget;

  void setBreakTarget();
  void setContinueTarget();
}

/// A jump target is the reference point of a statement or switch-case,
/// either by label or as the default target of a break or continue.
abstract class JumpTarget extends Local {
  Node get statement;
  int get nestingLevel;
  Link<LabelDefinition> get labels;

  bool get isTarget;
  bool get isBreakTarget;
  bool get isContinueTarget;
  bool get isSwitch;

  // TODO(kasperl): Try to get rid of these.
  void set isBreakTarget(bool value);
  void set isContinueTarget(bool value);

  LabelDefinition addLabel(Label label, String labelName);
}

/// The [Element] for a type variable declaration on a generic class or typedef.
abstract class TypeVariableElement extends Element
    implements AstElement, TypedElement {

  /// Use [typeDeclaration] instead.
  @deprecated
  get enclosingElement;

  /// The class or typedef on which this type variable is defined.
  TypeDeclarationElement get typeDeclaration;

  /// The [type] defined by the type variable.
  TypeVariableType get type;

  /// The upper bound on the type variable. If not explicitly declared, this is
  /// `Object`.
  DartType get bound;
}

abstract class MetadataAnnotation implements Spannable {
  /// The front-end constant of this metadata annotation.
  Constant get value;
  Element get annotatedElement;
  int get resolutionState;
  Token get beginToken;
  Token get endToken;

  MetadataAnnotation ensureResolved(Compiler compiler);
}

/// An [Element] that has a type.
abstract class TypedElement extends Element {
  DartType get type;
}

/// An [Element] that can define a function type.
abstract class FunctionTypedElement extends Element {
  /// The function signature for the function type defined by this element,
  /// if any.
  FunctionSignature get functionSignature;
}

/// An [Element] that holds a [TreeElements] mapping.
abstract class AnalyzableElement extends Element {
  /// Return `true` if [treeElements] have been (partially) computed for this
  /// element.
  bool get hasTreeElements;

  /// Returns the [TreeElements] that hold the resolution information for the
  /// AST nodes of this element.
  TreeElements get treeElements;
}

/// An [Element] that (potentially) has a node.
///
/// Synthesized elements may return `null` from [node].
abstract class AstElement extends AnalyzableElement {
  /// `true` if [node] is available and non-null.
  bool get hasNode;

  /// The AST node of this element.
  Node get node;

  /// `true` if [resolvedAst] is available.
  bool get hasResolvedAst;

  /// The defining AST node of this element with is corresponding
  /// [TreeElements]. This is not available if [hasResolvedAst] is `false`.
  ResolvedAst get resolvedAst;
}

class ResolvedAst {
  final Element element;
  final Node node;
  final TreeElements elements;

  ResolvedAst(this.element, this.node, this.elements);
}

/// A [MemberSignature] is a member of an interface.
///
/// A signature is either a method or a getter or setter, possibly implicitly
/// defined by a field declarations. Fields themselves are not members of an
/// interface.
///
/// A [MemberSignature] may be defined by a member declaration or may be
/// synthetized from a set of declarations.
abstract class MemberSignature {
  /// The name of this member.
  Name get name;

  /// The type of the member when accessed. For getters and setters this is the
  /// return type and argument type, respectively. For methods the type is the
  /// [functionType] defined by the return type and parameters.
  DartType get type;

  /// The function type of the member. For a getter `Foo get foo` this is
  /// `() -> Foo`, for a setter `void set foo(Foo _)` this is `(Foo) -> void`.
  /// For methods the function type is defined by the return type and
  /// parameters.
  FunctionType get functionType;

  /// Returns `true` if this member is a getter, possibly implictly defined by a
  /// field declaration.
  bool get isGetter;

  /// Returns `true` if this member is a setter, possibly implictly defined by a
  /// field declaration.
  bool get isSetter;

  /// Returns `true` if this member is a method, that is neither a getter nor
  /// setter.
  bool get isMethod;

  /// Returns an iterable of the declarations that define this member.
  Iterable<Member> get declarations;
}

/// A [Member] is a member of a class, that is either a method or a getter or
/// setter, possibly implicitly defined by a field declarations. Fields
/// themselves are not members of a class.
///
/// A [Member] of a class also defines a signature which is a member of the
/// corresponding interface type.
///
/// A [Member] is implicitly concrete. An abstract declaration only declares
/// a signature in the interface of its class.
///
/// A [Member] is always declared by an [Element] which is accessibly through
/// the [element] getter.
abstract class Member extends MemberSignature {
  /// The [Element] that declared this member, possibly implicitly in case of
  /// a getter or setter defined by a field.
  Element get element;

  /// The instance of the class that declared this member.
  ///
  /// For instance:
  ///   class A<T> { T m() {} }
  ///   class B<S> extends A<S> {}
  /// The declarer of `m` in `A` is `A<T>` whereas the declarer of `m` in `B` is
  /// `A<S>`.
  InterfaceType get declarer;

  /// Returns `true` if this member is static.
  bool get isStatic;

  /// Returns `true` if this member is a getter or setter implicitly declared
  /// by a field.
  bool get isDeclaredByField;

  /// Returns `true` if this member is abstract.
  bool get isAbstract;

  /// If abstract, [implementation] points to the overridden concrete member,
  /// if any. Otherwise [implementation] points to the member itself.
  Member get implementation;
}

