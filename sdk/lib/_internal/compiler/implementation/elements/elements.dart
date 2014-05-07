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
  static const ElementKind FIELD_PARAMETER =
      const ElementKind('field_parameter', ElementCategory.VARIABLE);
  static const ElementKind FUNCTION =
      const ElementKind('function', ElementCategory.FUNCTION);
  static const ElementKind CLASS =
      const ElementKind('class', ElementCategory.CLASS);
  static const ElementKind GENERATIVE_CONSTRUCTOR =
      const ElementKind('generative_constructor', ElementCategory.FACTORY);
  static const ElementKind FIELD =
      const ElementKind('field', ElementCategory.VARIABLE);
  static const ElementKind VARIABLE_LIST =
      const ElementKind('variable_list', ElementCategory.NONE);
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

  static const ElementKind STATEMENT =
      const ElementKind('statement', ElementCategory.NONE);
  static const ElementKind LABEL =
      const ElementKind('label', ElementCategory.NONE);
  static const ElementKind VOID =
      const ElementKind('void', ElementCategory.NONE);

  static const ElementKind AMBIGUOUS =
      const ElementKind('ambiguous', ElementCategory.NONE);
  static const ElementKind WARN_ON_USE =
      const ElementKind('warn_on_use', ElementCategory.NONE);
  static const ElementKind ERROR =
      const ElementKind('error', ElementCategory.NONE);

  toString() => id;
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
abstract class Element implements Spannable {
  String get name;
  ElementKind get kind;
  Modifiers get modifiers;
  Element get enclosingElement;
  Link<MetadataAnnotation> get metadata;

  Node parseNode(DiagnosticListener listener);

  /// Do not use [computeType] outside of the resolver; instead retrieve the
  /// type from the corresponding field:
  /// - `type` for fields, variables, type variable, and function elements.
  /// - `thisType` or `rawType` for [TypeDeclarationElement]s (classes and
  ///    typedefs), depending on the use case.
  /// Trying to access a type that has not been computed in resolution is an
  /// error and calling [computeType] covers that error.
  /// This method will go away!
  @deprecated DartType computeType(Compiler compiler);

  bool isFunction();
  bool isConstructor();
  bool isClosure();
  bool isMember();
  bool isInstanceMember();

  bool isFactoryConstructor();
  bool isGenerativeConstructor();
  bool isGenerativeConstructorBody();
  bool isCompilationUnit();
  bool isClass();
  bool isPrefix();
  bool isVariable();
  bool isParameter();
  bool isStatement();
  bool isTypedef();
  bool isTypeVariable();
  bool isField();
  bool isFieldParameter();
  bool isAbstractField();
  bool isGetter();
  bool isSetter();
  bool isAccessor();
  bool isLibrary();
  bool isErroneous();
  bool isAmbiguous();
  bool isWarnOnUse();

  /// Returns true if this [Element] is a top level element.
  /// That is, if it is not defined within the scope of a class.
  ///
  /// This means whether the enclosing element is a compilation unit.
  /// With the exception of [ClosureClassElement] that is considered top level
  /// as all other classes.
  bool isTopLevel();
  bool isAssignable();
  bool isNative();
  bool isDeferredLoaderGetter();

  bool impliesType();

  Token position();

  CompilationUnitElement getCompilationUnit();
  LibraryElement getLibrary();
  LibraryElement getImplementationLibrary();
  ClassElement getEnclosingClass();
  Element getEnclosingClassOrCompilationUnit();
  Element getEnclosingMember();
  Element getOutermostEnclosingMemberOrTopLevel();

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

  bool hasFixedBackendName();
  String fixedBackendName();

  bool get isAbstract;
  bool isForeign(Compiler compiler);

  void addMetadata(MetadataAnnotation annotation);
  void setNative(String name);
  void setFixedBackendName(String name);

  Scope buildScope();

  /// If the element is a forwarding constructor, [targetConstructor] holds
  /// the generative constructor that the forwarding constructor points to
  /// (possibly via other forwarding constructors).
  FunctionElement get targetConstructor;

  void diagnose(Element context, DiagnosticListener listener);

  TreeElements get treeElements;

  accept(ElementVisitor visitor);
}

class Elements {
  static bool isUnresolved(Element e) {
    return e == null || e.isErroneous();
  }
  static bool isErroneousElement(Element e) => e != null && e.isErroneous();

  /// Unwraps [element] reporting any warnings attached to it, if any.
  static Element unwrap(Element element,
                        DiagnosticListener listener,
                        Spannable spannable) {
    if (element != null && element.isWarnOnUse()) {
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
            && !element.isInstanceMember()
            && !isStaticOrTopLevelField(element)
            && !isStaticOrTopLevelFunction(element)
            && (identical(element.kind, ElementKind.VARIABLE) ||
                identical(element.kind, ElementKind.PARAMETER) ||
                identical(element.kind, ElementKind.FUNCTION));
  }

  static bool isInstanceField(Element element) {
    return !Elements.isUnresolved(element)
           && element.isInstanceMember()
           && (identical(element.kind, ElementKind.FIELD)
               || identical(element.kind, ElementKind.GETTER)
               || identical(element.kind, ElementKind.SETTER));
  }

  static bool isStaticOrTopLevel(Element element) {
    // TODO(ager): This should not be necessary when patch support has
    // been reworked.
    if (!Elements.isUnresolved(element)
        && element.modifiers.isStatic()) {
      return true;
    }
    return !Elements.isUnresolved(element)
           && !element.isAmbiguous()
           && !element.isInstanceMember()
           && !element.isPrefix()
           && element.enclosingElement != null
           && (element.enclosingElement.kind == ElementKind.CLASS ||
               element.enclosingElement.kind == ElementKind.COMPILATION_UNIT ||
               element.enclosingElement.kind == ElementKind.LIBRARY ||
               element.enclosingElement.kind == ElementKind.PREFIX);
  }

  static bool isInStaticContext(Element element) {
    if (isUnresolved(element)) return true;
    if (element.enclosingElement.isClosure()) {
      var closureClass = element.enclosingElement;
      element = closureClass.methodElement;
    }
    Element outer = element.getOutermostEnclosingMemberOrTopLevel();
    if (isUnresolved(outer)) return true;
    if (outer.isTopLevel()) return true;
    if (outer.isGenerativeConstructor()) return false;
    if (outer.isInstanceMember()) return false;
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
           && element.isInstanceMember()
           && (identical(element.kind, ElementKind.FUNCTION));
  }

  static bool isNativeOrExtendsNative(ClassElement element) {
    if (element == null) return false;
    if (element.isNative()) return true;
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
      return element.getEnclosingClass().name;
    } else {
      return reconstructConstructorName(element);
    }
  }

  // TODO(johnniwinther): Remove this method.
  static String reconstructConstructorName(Element element) {
    String className = element.getEnclosingClass().name;
    if (element.name == '') {
      return className;
    } else {
      return '$className\$${element.name}';
    }
  }

  /**
   * Map an operator-name to a valid Dart identifier.
   *
   * For non-operator names, this metod just returns its input.
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
    int r = a.getLibrary().compareTo(b.getLibrary());
    if (r != 0) return r;
    r = a.getCompilationUnit().compareTo(b.getCompilationUnit());
    if (r != 0) return r;
    Token positionA = a.position();
    Token positionB = b.position();
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
    if (!element.isConstructor()) return false;
    FunctionElement constructor = element;
    constructor = constructor.redirectionTarget;
    ClassElement cls = constructor.getEnclosingClass();
    return cls.getLibrary() == compiler.typedDataLibrary
        && cls.isNative()
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
          LabelElement labelElement = elements[label];
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
    TargetElement element = elements[body];
    // Labeled statements with no element on the body have no breaks.
    // A different target statement only happens if the body is itself
    // a break or continue for a different target. In that case, this
    // label is also always unused.
    return element == null || element.statement != body;
  }
}

abstract class ErroneousElement extends Element implements FunctionElement {
  MessageKind get messageKind;
  Map get messageArguments;
  String get message;
}

/// An [Element] whose usage should cause a warning.
abstract class WarnOnUseElement extends Element {
  /// The element whose usage cause a warning.
  Element get wrappedElement;

  /// Reports the attached warning and returns the wrapped element.
  /// [usageSpannable] is used to report messages on the reference of
  /// [wrappedElement].
  Element unwrap(DiagnosticListener listener, Spannable usageSpannable);
}

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

abstract class ClosureContainer implements Element {
  List<FunctionElement> get nestedClosures;
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

abstract class LibraryElement extends Element implements ScopeContainerElement {
  /**
   * The canonical uri for this library.
   *
   * For user libraries the canonical uri is the script uri. For platform
   * libraries the canonical uri is of the form [:dart:x:].
   */
  Uri get canonicalUri;
  CompilationUnitElement get entryCompilationUnit;
  Link<CompilationUnitElement> get compilationUnits;
  Link<LibraryTag> get tags;
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

abstract class PrefixElement extends Element {
  void addImport(Element element, Import import, DiagnosticListener listener);
  Element lookupLocalMember(String memberName);
  /// Is true if this prefix belongs to a deferred import.
  bool get isDeferred;
  void markAsDeferred(Import import);
  Import get deferredImport;
}

abstract class TypedefElement extends Element
    implements TypeDeclarationElement {
  TypedefType get thisType;
  TypedefType get rawType;
  DartType get alias;
  FunctionSignature get functionSignature;
  Link<DartType> get typeVariables;

  // TODO(kasperl): Try to get rid of these setters.
  void set alias(DartType value);
  void set functionSignature(FunctionSignature value);

  void checkCyclicReference(Compiler compiler);
}

abstract class VariableElement extends Element implements TypedElement {
  Expression get initializer;
}

abstract class FieldElement extends VariableElement
    implements ClosureContainer {}

abstract class ParameterElement extends VariableElement {
  VariableDefinitions get node;
  FunctionSignature get functionSignature;
}

abstract class FieldParameterElement extends ParameterElement {
  VariableElement get fieldElement;
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
  Link<Element> get requiredParameters;
  Link<Element> get optionalParameters;

  int get requiredParameterCount;
  int get optionalParameterCount;
  bool get optionalParametersAreNamed;
  Element get firstOptionalParameter;

  int get parameterCount;
  List<Element> get orderedOptionalParameters;

  void forEachParameter(void function(Element parameter));
  void forEachRequiredParameter(void function(Element parameter));
  void forEachOptionalParameter(void function(Element parameter));

  void orderedForEachParameter(void function(Element parameter));

  bool isCompatibleWith(FunctionSignature constructorSignature);
}

abstract class FunctionElement extends Element
    implements TypedElement, ClosureContainer {
  FunctionExpression get node;
  DartType get type;
  FunctionSignature get functionSignature;
  FunctionElement get redirectionTarget;
  FunctionElement get defaultImplementation;

  FunctionElement get patch;
  FunctionElement get origin;

  bool get isRedirectingFactory;

  /// Used to retrieve a link to the abstract field element representing this
  /// element.
  AbstractFieldElement get abstractField;

  /**
   * Compute the type of the target of a constructor for an instantiation site
   * with type [:newType:].
   */
  InterfaceType computeTargetType(InterfaceType newType);

  // TODO(kasperl): These are bit fishy. Do we really need them?
  void set defaultImplementation(FunctionElement value);

  /// Do not use [computeSignature] outside of the resolver; instead retrieve
  /// the signature through the [functionSignature] field.
  /// Trying to access a function signature that has not been computed in
  /// resolution is an error and calling [computeSignature] covers that error.
  /// This method will go away!
  @deprecated FunctionSignature computeSignature(Compiler compiler);

  FunctionExpression parseNode(DiagnosticListener listener);
}

abstract class ConstructorBodyElement extends FunctionElement {
  FunctionElement get constructor;
}

/**
 * [TypeDeclarationElement] defines the common interface for class/interface
 * declarations and typedefs.
 */
abstract class TypeDeclarationElement extends Element {
  GenericType get thisType;
  GenericType get rawType;

  /**
   * The type variables declared on this declaration. The type variables are not
   * available until the type of the element has been computed through
   * [computeType].
   */
  Link<DartType> get typeVariables;

  bool get isResolved;
}

abstract class ClassElement extends TypeDeclarationElement
    implements ScopeContainerElement {
  int get id;

  /// The length of the longest inheritance path from [:Object:].
  int get hierarchyDepth;

  InterfaceType get rawType;
  InterfaceType get thisType;

  ClassElement get superclass;

  DartType get supertype;
  OrderedTypeSet get allSupertypesAndSelf;
  Link<DartType> get allSupertypes;
  Link<DartType> get interfaces;

  bool get hasConstructor;
  Link<Element> get constructors;

  ClassElement get patch;
  ClassElement get origin;
  ClassElement get declaration;
  ClassElement get implementation;

  int get supertypeLoadState;
  int get resolutionState;
  String get nativeTagInfo;

  bool get isMixinApplication;
  bool get isUnnamedMixinApplication;
  bool get hasBackendMembers;
  bool get hasLocalScopeMembers;

  // TODO(kasperl): These are bit fishy. Do we really need them?
  void set supertype(DartType value);
  void set interfaces(Link<DartType> value);
  void set supertypeLoadState(int value);
  void set resolutionState(int value);
  void set nativeTagInfo(String value);

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

  void ensureResolved(Compiler compiler);

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

  Link<DartType> computeTypeParameters(Compiler compiler);

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

abstract class LabelElement extends Element {
  Label get label;
  String get labelName;
  TargetElement get target;

  bool get isTarget;
  bool get isBreakTarget;
  bool get isContinueTarget;

  void setBreakTarget();
  void setContinueTarget();
}

abstract class TargetElement extends Element {
  Node get statement;
  int get nestingLevel;
  Link<LabelElement> get labels;

  bool get isTarget;
  bool get isBreakTarget;
  bool get isContinueTarget;
  bool get isSwitch;

  // TODO(kasperl): Try to get rid of these.
  void set isBreakTarget(bool value);
  void set isContinueTarget(bool value);

  LabelElement addLabel(Label label, String labelName);
}

/// The [Element] for a type variable declaration on a generic class or typedef.
abstract class TypeVariableElement extends Element implements TypedElement {
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

  // TODO(kasperl): Try to get rid of these.
  void set annotatedElement(Element value);

  MetadataAnnotation ensureResolved(Compiler compiler);
}

// TODO(johnniwinther): Remove this element.
abstract class VoidElement extends Element {}

/// An [Element] that has a type.
abstract class TypedElement extends Element {
  DartType get type;
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

