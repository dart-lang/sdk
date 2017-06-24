// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library elements;

import '../common.dart';
import '../common/resolution.dart' show Resolution;
import '../constants/constructors.dart';
import '../constants/expressions.dart';
import '../common_elements.dart' show CommonElements;
import '../ordered_typeset.dart' show OrderedTypeSet;
import '../resolution/scope.dart' show Scope;
import '../resolution/tree_elements.dart' show TreeElements;
import '../script.dart';
import 'package:front_end/src/fasta/scanner.dart'
    show Token, isUserDefinableOperator, isMinusOperator;
import '../tree/tree.dart' hide AsyncModifier;
import '../universe/call_structure.dart';
import '../util/util.dart';
import '../world.dart' show ClosedWorld;
import 'entities.dart';
import 'entity_utils.dart' as utils;
import 'jumps.dart';
import 'names.dart';
import 'resolution_types.dart';
import 'types.dart';
import 'visitor.dart' show ElementVisitor;

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
  static const ElementKind FACTORY_CONSTRUCTOR =
      const ElementKind('factory_constructor', ElementCategory.FACTORY);
  static const ElementKind FIELD =
      const ElementKind('field', ElementCategory.VARIABLE);
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
  static const ElementKind IMPORT =
      const ElementKind('import', ElementCategory.NONE);
  static const ElementKind EXPORT =
      const ElementKind('export', ElementCategory.NONE);
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
 * Elements are distinct from types ([ResolutionDartType]). For example, there
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
  Iterable<MetadataAnnotation> get metadata;

  /// `true` if this element is a library.
  bool get isLibrary;

  /// `true` if this element is an import declaration.
  bool get isImport => kind == ElementKind.IMPORT;

  /// `true` if this element is an export declaration.
  bool get isExport => kind == ElementKind.EXPORT;

  /// `true` if this element is a compilation unit.
  bool get isCompilationUnit;

  /// `true` if this element is defines the scope of prefix used by one or
  /// more import declarations.
  bool get isPrefix;

  /// `true` if this element is a class declaration or a mixin application.
  bool get isClass;

  /// `true` if this element is a type variable declaration.
  bool get isTypeVariable;

  /// `true` if this element is a typedef declaration.
  bool get isTypedef;

  /// `true` if this element is a top level function, static or instance
  /// method, local function or closure defined by a function expression.
  ///
  /// This property is `true` for operator methods but `false` for getter and
  /// setter methods, and generative and factory constructors.
  ///
  /// See also [isConstructor], [isGenerativeConstructor], and
  /// [isFactoryConstructor] for constructor properties, and [isAccessor],
  /// [isGetter] and [isSetter] for getter/setter properties.
  bool get isFunction;

  /// `true` if this element is an operator method.
  bool get isOperator;

  /// `true` if this element is an accessor, that is either an explicit
  /// getter or an explicit setter.
  bool get isAccessor;

  /// `true` if this element is an explicit getter method.
  bool get isGetter;

  /// `true` if this element is an explicit setter method.
  bool get isSetter;

  /// `true` if this element is a generative or factory constructor.
  bool get isConstructor;

  /// `true` if this element is a generative constructor, potentially
  /// redirecting.
  bool get isGenerativeConstructor;

  /// `true` if this element is the body of a generative constructor.
  ///
  /// This is a synthetic element kind used only by the JavaScript backend.
  bool get isGenerativeConstructorBody;

  /// `true` if this element is a factory constructor,
  /// potentially redirecting.
  bool get isFactoryConstructor;

  /// `true` if this element is a local variable.
  bool get isVariable;

  /// `true` if this element is a top level variable, static or instance field.
  bool get isField;

  /// `true` if this element is the abstract field implicitly defined by an
  /// explicit getter and/or setter.
  bool get isAbstractField;

  /// `true` if this element is a formal parameter from a constructor,
  /// a method, a typedef declaration, or from an inlined function typed
  /// parameter.
  ///
  /// This property is `false` if this element is an initializing formal.
  /// See [isInitializingFormal].
  bool get isRegularParameter;

  /// `true` if this element is an initializing formal of constructor, that
  /// is a formal of the form `this.foo`.
  bool get isInitializingFormal;

  /// `true` if this element is a formal parameter, either regular or
  /// initializing.
  bool get isParameter => isRegularParameter || isInitializingFormal;

  /// `true` if this element represents a resolution error.
  bool get isError;

  /// `true` if this element represents an ambiguous name.
  ///
  /// Ambiguous names occur when two imports/exports contain different entities
  /// by the same name. If an ambiguous name is resolved an warning or error
  /// is produced.
  bool get isAmbiguous;

  /// True if there has been errors during resolution or parsing of this
  /// element.
  bool get isMalformed;

  /// `true` if this element represents an entity whose access causes one or
  /// more warnings.
  bool get isWarnOnUse;

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

  /// `true` if this element is local element, that is, a local variable,
  /// local function or parameter.
  bool get isLocal;

  bool get impliesType;

  /// The character offset of the declaration of this element within its
  /// compilation unit, if available.
  ///
  /// This is used to sort the elements.
  int get sourceOffset;

  // TODO(johnniwinther): Remove this.
  Token get position;

  /// The position of the declaration of this element, if available.
  SourceSpan get sourcePosition;

  CompilationUnitElement get compilationUnit;
  LibraryElement get library;
  LibraryElement get implementationLibrary;
  ClassElement get enclosingClass;
  Element get enclosingClassOrCompilationUnit;
  Element get outermostEnclosingMemberOrTopLevel;

  // TODO(johnniwinther): Replace uses of this with [enclosingClass] when
  // [ClosureClassElement] has been removed.
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
  bool get isMixinApplication;

  bool get isAbstract;

  Scope buildScope();

  // TODO(johnniwinther): Move this to [AstElement].
  /// Returns the [Element] that holds the [TreeElements] for this element.
  AnalyzableElement get analyzableElement;

  accept(ElementVisitor visitor, arg);
}

class Elements {
  static bool isUnresolved(Element e) {
    return e == null || e.isMalformed;
  }

  static bool isError(Element e) {
    return e != null && e.isError;
  }

  static bool isMalformed(Element e) {
    return e != null && e.isMalformed;
  }

  /// Unwraps [element] reporting any warnings attached to it, if any.
  static Element unwrap(
      Element element, DiagnosticReporter listener, Spannable spannable) {
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
    return !Elements.isUnresolved(element) && element.isLocal;
  }

  static bool isInstanceField(Element element) {
    return !Elements.isUnresolved(element) &&
        element.isInstanceMember &&
        (identical(element.kind, ElementKind.FIELD) ||
            identical(element.kind, ElementKind.GETTER) ||
            identical(element.kind, ElementKind.SETTER));
  }

  static bool isStaticOrTopLevel(Element element) {
    // TODO(johnniwinther): Clean this up. This currently returns true for a
    // PartialConstructorElement, SynthesizedConstructorElementX, and
    // TypeVariableElementX though neither `element.isStatic` nor
    // `element.isTopLevel` is true.
    if (Elements.isUnresolved(element)) return false;
    if (element.isStatic || element.isTopLevel) return true;
    return !element.isAmbiguous &&
        !element.isInstanceMember &&
        !element.isPrefix &&
        element.enclosingElement != null &&
        (element.enclosingElement.kind == ElementKind.CLASS ||
            element.enclosingElement.kind == ElementKind.COMPILATION_UNIT ||
            element.enclosingElement.kind == ElementKind.LIBRARY ||
            element.enclosingElement.kind == ElementKind.PREFIX);
  }

  static bool isInStaticContext(Element element) {
    if (isUnresolved(element)) return true;
    if (element.enclosingElement.isClosure) {
      dynamic closureClass = element.enclosingElement;
      // ignore: UNDEFINED_GETTER
      element = closureClass.methodElement;
    }
    Element outer = element.outermostEnclosingMemberOrTopLevel;
    if (isUnresolved(outer)) return true;
    if (outer.isTopLevel) return true;
    if (outer.isGenerativeConstructor) return false;
    if (outer.isInstanceMember) return false;
    return true;
  }

  static bool hasAccessToTypeVariable(
      Element element, TypeVariableElement typeVariable) {
    GenericElement declaration = typeVariable.typeDeclaration;
    if (declaration is FunctionElement || declaration is ParameterElement) {
      return true;
    }
    Element outer = element.outermostEnclosingMemberOrTopLevel;
    return (outer != null && outer.isFactoryConstructor) ||
        !isInStaticContext(element);
  }

  static bool isStaticOrTopLevelField(Element element) {
    return isStaticOrTopLevel(element) &&
        (identical(element.kind, ElementKind.FIELD) ||
            identical(element.kind, ElementKind.GETTER) ||
            identical(element.kind, ElementKind.SETTER));
  }

  static bool isStaticOrTopLevelFunction(Element element) {
    return isStaticOrTopLevel(element) && element.isFunction;
  }

  static bool isInstanceMethod(Element element) {
    return !Elements.isUnresolved(element) &&
        element.isInstanceMember &&
        (identical(element.kind, ElementKind.FUNCTION));
  }

  static bool isInstanceSend(Send send, TreeElements elements) {
    Element element = elements[send];
    if (element == null) return !isClosureSend(send, element);
    return isInstanceMethod(element) ||
        isInstanceField(element) ||
        (send.isConditional && !element.isStatic);
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

  static String reconstructConstructorNameSourceString(FunctionEntity element) {
    if (element.name == '') {
      return element.enclosingClass.name;
    } else {
      return utils.reconstructConstructorName(element);
    }
  }

  static String constructorNameForDiagnostics(
      String className, String constructorName) {
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
   * JavaScript identifiers, except it may include reserved words for
   * non-operator names.
   */
  static String operatorNameToIdentifier(String name) {
    if (name == null) {
      return name;
    } else if (name == '==') {
      return r'operator$eq';
    } else if (name == '~') {
      return r'operator$not';
    } else if (name == '[]') {
      return r'operator$index';
    } else if (name == '[]=') {
      return r'operator$indexSet';
    } else if (name == '*') {
      return r'operator$mul';
    } else if (name == '/') {
      return r'operator$div';
    } else if (name == '%') {
      return r'operator$mod';
    } else if (name == '~/') {
      return r'operator$tdiv';
    } else if (name == '+') {
      return r'operator$add';
    } else if (name == '<<') {
      return r'operator$shl';
    } else if (name == '>>') {
      return r'operator$shr';
    } else if (name == '>=') {
      return r'operator$ge';
    } else if (name == '>') {
      return r'operator$gt';
    } else if (name == '<=') {
      return r'operator$le';
    } else if (name == '<') {
      return r'operator$lt';
    } else if (name == '&') {
      return r'operator$and';
    } else if (name == '^') {
      return r'operator$xor';
    } else if (name == '|') {
      return r'operator$or';
    } else if (name == '-') {
      return r'operator$sub';
    } else if (name == 'unary-') {
      return r'operator$negate';
    } else {
      return name;
    }
  }

  static String constructOperatorNameOrNull(String op, bool isUnary) {
    if (isMinusOperator(op)) {
      return isUnary ? 'unary-' : op;
    } else if (isUserDefinableOperator(op) || op == '??') {
      return op;
    } else {
      return null;
    }
  }

  static String constructOperatorName(String op, bool isUnary) {
    String operatorName = constructOperatorNameOrNull(op, isUnary);
    if (operatorName == null)
      throw 'Unhandled operator: $op';
    else
      return operatorName;
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
    if (identical(op, '??=')) return '??';

    return null;
  }

  /// A `compareTo` function that places [Element]s in a consistent order based
  /// on the source code order.
  static int compareByPosition(Element a, Element b) {
    if (identical(a, b)) return 0;
    int r = utils.compareLibrariesUris(
        a.library.canonicalUri, b.library.canonicalUri);
    if (r != 0) return r;
    r = utils.compareSourceUris(a.compilationUnit.script.readableUri,
        b.compilationUnit.script.readableUri);
    if (r != 0) return r;
    return utils.compareEntities(a, a.sourceOffset, -1, b, b.sourceOffset, -1);
  }

  static List<E> sortedByPosition<E extends Element>(Iterable<E> elements) {
    return elements.toList()..sort(compareByPosition);
  }

  static bool isFixedListConstructorCall(
      ConstructorEntity element, Send node, CommonElements commonElements) {
    return commonElements.isUnnamedListConstructor(element) &&
        node.isCall &&
        !node.arguments.isEmpty &&
        node.arguments.tail.isEmpty;
  }

  static bool isGrowableListConstructorCall(
      ConstructorEntity element, Send node, CommonElements commonElements) {
    return commonElements.isUnnamedListConstructor(element) &&
        node.isCall &&
        node.arguments.isEmpty;
  }

  static bool isFilledListConstructorCall(
      ConstructorEntity element, Send node, CommonElements commonElements) {
    return commonElements.isFilledListConstructor(element) &&
        node.isCall &&
        !node.arguments.isEmpty &&
        !node.arguments.tail.isEmpty &&
        node.arguments.tail.tail.isEmpty;
  }

  static bool isConstructorOfTypedArraySubclass(
      Element element, ClosedWorld closedWorld) {
    if (closedWorld.commonElements.typedDataLibrary == null) return false;
    if (!element.isConstructor) return false;
    ConstructorElement constructor = element.implementation;
    constructor = constructor.effectiveTarget;
    ClassElement cls = constructor.enclosingClass;
    return cls.library == closedWorld.commonElements.typedDataLibrary &&
        closedWorld.nativeData.isNativeClass(cls) &&
        closedWorld.isSubtypeOf(
            cls, closedWorld.commonElements.typedDataClass) &&
        closedWorld.isSubtypeOf(cls, closedWorld.commonElements.listClass) &&
        constructor.name == '';
  }

  static bool switchStatementHasContinue(
      SwitchStatement node, TreeElements elements) {
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

  /**
   * Returns a `List` with the evaluated arguments in the normalized order.
   *
   * [compileDefaultValue] is a function that returns a compiled constant
   * of an optional argument that is not in [compiledArguments].
   *
   * Precondition: `callStructure.signatureApplies(element.type)`.
   *
   * Invariant: [element] must be the implementation element.
   */
  static List<T> makeArgumentsList<T>(
      CallStructure callStructure,
      Link<Node> arguments,
      FunctionElement element,
      T compileArgument(Node argument),
      T compileDefaultValue(ParameterElement element)) {
    assert(element.isImplementation, failedAt(element));
    List<T> result = <T>[];

    FunctionSignature parameters = element.functionSignature;
    parameters.forEachRequiredParameter((_) {
      result.add(compileArgument(arguments.head));
      arguments = arguments.tail;
    });

    if (!parameters.optionalParametersAreNamed) {
      parameters.forEachOptionalParameter((_element) {
        ParameterElement element = _element;
        if (!arguments.isEmpty) {
          result.add(compileArgument(arguments.head));
          arguments = arguments.tail;
        } else {
          result.add(compileDefaultValue(element));
        }
      });
    } else {
      // Visit named arguments and add them into a temporary list.
      List compiledNamedArguments = [];
      for (; !arguments.isEmpty; arguments = arguments.tail) {
        NamedArgument namedArgument = arguments.head;
        compiledNamedArguments.add(compileArgument(namedArgument.expression));
      }
      // Iterate over the optional parameters of the signature, and try to
      // find them in [compiledNamedArguments]. If found, we use the
      // value in the temporary list, otherwise the default value.
      parameters.orderedOptionalParameters.forEach((_element) {
        ParameterElement element = _element;
        int foundIndex = callStructure.namedArguments.indexOf(element.name);
        if (foundIndex != -1) {
          result.add(compiledNamedArguments[foundIndex]);
        } else {
          result.add(compileDefaultValue(element));
        }
      });
    }
    return result;
  }

  /**
   * Fills [list] with the arguments in the order expected by
   * [callee], and where [caller] is a synthesized element
   *
   * [compileArgument] is a function that returns a compiled version
   * of a parameter of [callee].
   *
   * [compileConstant] is a function that returns a compiled constant
   * of an optional argument that is not in the parameters of [callee].
   *
   * Returns [:true:] if the signature of the [caller] matches the
   * signature of the [callee], [:false:] otherwise.
   */
  static bool addForwardingElementArgumentsToList<T>(
      ConstructorElement caller,
      List<T> list,
      ConstructorElement callee,
      T compileArgument(ParameterElement element),
      T compileConstant(ParameterElement element)) {
    assert(
        !callee.isMalformed,
        failedAt(
            caller,
            "Cannot compute arguments to malformed constructor: "
            "$caller calling $callee."));

    FunctionSignature signature = caller.functionSignature;
    Map<Node, ParameterElement> mapping = <Node, ParameterElement>{};

    // TODO(ngeoffray): This is a hack that fakes up AST nodes, so
    // that we can call [addArgumentsToList].
    Link<Node> computeCallNodesFromParameters() {
      LinkBuilder<Node> builder = new LinkBuilder<Node>();
      signature.forEachRequiredParameter((_element) {
        ParameterElement element = _element;
        Node node = element.node;
        mapping[node] = element;
        builder.addLast(node);
      });
      if (signature.optionalParametersAreNamed) {
        signature.forEachOptionalParameter((_element) {
          ParameterElement element = _element;
          mapping[element.initializer] = element;
          builder.addLast(new NamedArgument(null, null, element.initializer));
        });
      } else {
        signature.forEachOptionalParameter((_element) {
          ParameterElement element = _element;
          Node node = element.node;
          mapping[node] = element;
          builder.addLast(node);
        });
      }
      return builder.toLink();
    }

    T internalCompileArgument(Node node) {
      return compileArgument(mapping[node]);
    }

    Link<Node> nodes = computeCallNodesFromParameters();

    // Synthesize a structure for the call.
    // TODO(ngeoffray): Should the resolver do it instead?
    CallStructure callStructure = new CallStructure(
        signature.parameterCount, signature.type.namedParameters);
    if (!callStructure.signatureApplies(signature.parameterStructure)) {
      return false;
    }
    list.addAll(makeArgumentsList<T>(callStructure, nodes, callee,
        internalCompileArgument, compileConstant));

    return true;
  }
}

/// An element representing an erroneous resolution.
///
/// An [ErroneousElement] is used instead of `null` to provide additional
/// information about the error that caused the element to be unresolvable
/// or otherwise invalid.
///
/// Accessing any field or calling any method defined on [ErroneousElement]
/// except [isError] will currently throw an exception. (This might
/// change when we actually want more information on the erroneous element,
/// e.g., the name of the element we were trying to resolve.)
///
/// Code that cannot not handle an [ErroneousElement] should use
/// `Element.isUnresolved(element)` to check for unresolvable elements instead
/// of `element == null`.
// ignore: STRONG_MODE_INVALID_METHOD_OVERRIDE_FROM_BASE
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
  Element unwrap(DiagnosticReporter listener, Spannable usageSpannable);
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

  /// Compute the info messages associated with an error/warning on [context].
  List<DiagnosticMessage> computeInfos(
      Element context, DiagnosticReporter listener);
}

// TODO(kasperl): This probably shouldn't be called an element. It's
// just an interface shared by classes and libraries.
abstract class ScopeContainerElement implements Element {
  Element localLookup(String elementName);

  void forEachLocalMember(f(Element element));
}

abstract class CompilationUnitElement extends Element {
  /// Use [library] instead.
  @deprecated
  get enclosingElement;

  Script get script;

  void forEachLocalMember(f(Element element));
}

abstract class ImportElement extends Element {
  Uri get uri;
  LibraryElement get importedLibrary;
  bool get isDeferred;
  PrefixElement get prefix;
  // TODO(johnniwinther): Remove this when no longer needed in source mirrors.
  Import get node;
}

abstract class ExportElement extends Element {
  Uri get uri;
  LibraryElement get exportedLibrary;
  // TODO(johnniwinther): Remove this when no longer needed in source mirrors.
  Export get node;
}

abstract class LibraryElement extends Element
    implements ScopeContainerElement, AnalyzableElement, LibraryEntity {
  /**
   * The canonical uri for this library.
   *
   * For user libraries the canonical uri is the script uri. For platform
   * libraries the canonical uri is of the form [:dart:x:].
   */
  Uri get canonicalUri;

  /// Returns `true` if this library is 'dart:core'.
  bool get isDartCore;

  CompilationUnitElement get entryCompilationUnit;
  Link<CompilationUnitElement> get compilationUnits;

  /// The import declarations in this library, including the implicit import of
  /// 'dart:core', if present.
  Iterable<ImportElement> get imports;

  /// The export declarations in this library.
  Iterable<ExportElement> get exports;

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

  bool get exportsHandled;

  LibraryElement get implementation;

  Element find(String elementName);
  Element findLocal(String elementName);
  Element findExported(String elementName);
  void forEachExport(f(Element element));

  /// Calls [f] for each [Element] imported into this library.
  void forEachImport(f(Element element));

  /// Returns the imports that import element into this library.
  Iterable<ImportElement> getImportsFor(Element element);

  /// `true` if this library has name as given through a library tag.
  bool get hasLibraryName;

  /// The library name, which is either the name given in the library tag
  /// or the empty string if there is no library tag.
  String get libraryName;

  /// Returns the library name (as defined by the library tag) or for scripts
  /// (which have no library tag) the script file name.
  ///
  /// Note: the returned filename is still escaped ("a%20b.dart" instead of
  /// "a b.dart").
  String get name;
}

/// The implicit scope defined by a import declaration with a prefix clause.
abstract class PrefixElement extends Element {
  Element lookupLocalMember(String memberName);

  void forEachLocalMember(void f(Element member));

  /// Is true if this prefix belongs to a deferred import.
  bool get isDeferred;

  /// Import that declared this deferred prefix.
  ImportElement get deferredImport;

  /// The `loadLibrary` getter implicitly defined on deferred prefixes.
  GetterElement get loadLibrary;
}

/// A type alias definition.
abstract class TypedefElement extends Element
    implements AstElement, TypeDeclarationElement, FunctionTypedElement {
  /// The type defined by this typedef with the type variables as its type
  /// arguments.
  ///
  /// For instance `F<T>` for `typedef void F<T>(T t)`.
  ResolutionTypedefType get thisType;

  /// The type defined by this typedef with `dynamic` as its type arguments.
  ///
  /// For instance `F<dynamic>` for `typedef void F<T>(T t)`.
  ResolutionTypedefType get rawType;

  /// The type, function type if well-defined, for which this typedef is an
  /// alias.
  ///
  /// For instance `(int)->void` for `typedef void F(int)`.
  ResolutionDartType get alias;

  void checkCyclicReference(Resolution resolution);
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

/// A top-level, static or instance field or method, or a constructor.
///
/// A [MemberElement] is the outermost executable element for any executable
/// context.
abstract class MemberElement extends Element
    implements ExecutableElement, MemberEntity {
  /// The local functions defined within this member.
  List<FunctionElement> get nestedClosures;

  /// The name of this member, taking privacy into account.
  Name get memberName;
}

/// A function, variable or parameter defined in an executable context.
abstract class LocalElement extends Element
    implements AstElement, TypedElement, Local {
  ExecutableElement get executableContext;
}

/// A top level, static or instance field, a formal parameter or local variable.
abstract class VariableElement extends ExecutableElement {
  @override
  VariableDefinitions get node;

  Expression get initializer;

  bool get hasConstant;

  /// The constant expression defining the (initial) value of the variable.
  ///
  /// If the variable is `const` the value is always non-null, possibly an
  /// [ErroneousConstantExpression], otherwise, the value is null when the
  /// initializer isn't a constant expression.
  ConstantExpression get constant;
}

/// A variable or parameter that is local to an executable context.
///
/// The executable context is the [ExecutableElement] in which this variable
/// is defined.
abstract class LocalVariableElement extends VariableElement
    implements LocalElement {}

/// A top-level, static or instance field.
abstract class FieldElement extends VariableElement
    implements MemberElement, FieldEntity {}

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

  /// Whether the parameter is unnamed in a function type.
  bool get isUnnamed;
}

/// A formal parameter of a function or constructor.
///
/// Normal parameter that introduce a local variable are modeled by
/// [LocalParameterElement] whereas initializing formals, that is parameter of
/// the form `this.x`, are modeled by [InitializingFormalElement].
abstract class ParameterElement extends Element
    implements VariableElement, FormalElement, LocalElement {
  /// Use [functionDeclaration] instead.
  @deprecated
  get enclosingElement;

  /// The function on which this parameter is declared.
  FunctionElement get functionDeclaration;

  /// `true` if this parameter is named.
  bool get isNamed;

  /// `true` if this parameter is optional.
  bool get isOptional;
}

/// A formal parameter on a function or constructor that introduces a local
/// variable in the scope of the function or constructor.
abstract class LocalParameterElement extends ParameterElement
    implements LocalVariableElement {}

/// A formal parameter in a constructor that directly initializes a field.
///
/// For example: `A(this.field)`.
abstract class InitializingFormalElement extends LocalParameterElement {
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
  GetterElement get getter;
  SetterElement get setter;
}

abstract class FunctionSignature {
  ResolutionFunctionType get type;
  ResolutionDartType get returnType;
  List<ResolutionDartType> get typeVariables;
  List<FormalElement> get requiredParameters;
  List<FormalElement> get optionalParameters;

  int get requiredParameterCount;
  int get optionalParameterCount;
  bool get optionalParametersAreNamed;
  bool get hasOptionalParameters;

  int get parameterCount;
  List<FormalElement> get orderedOptionalParameters;

  void forEachParameter(void function(FormalElement parameter));
  void forEachRequiredParameter(void function(FormalElement parameter));
  void forEachOptionalParameter(void function(FormalElement parameter));

  void orderedForEachParameter(void function(FormalElement parameter));

  bool isCompatibleWith(FunctionSignature constructorSignature);

  ParameterStructure get parameterStructure;
}

/// A top level, static or instance method, constructor, local function, or
/// closure (anonymous local function).
abstract class FunctionElement extends Element
    implements
        AstElement,
        TypedElement,
        FunctionTypedElement,
        ExecutableElement,
        GenericElement {
  FunctionExpression get node;

  FunctionElement get patch;
  FunctionElement get origin;

  bool get hasFunctionSignature;

  /// The parameters of this function.
  List<ParameterElement> get parameters;

  /// The type of this function.
  ResolutionFunctionType get type;

  /// The synchronous/asynchronous marker on this function.
  AsyncMarker get asyncMarker;

  /// `true` if this function is external.
  bool get isExternal;

  /// The structure of the function parameters.
  ParameterStructure get parameterStructure;
}

/// A getter or setter.
abstract class AccessorElement extends MethodElement {
  /// Used to retrieve a link to the abstract field element representing this
  /// element.
  AbstractFieldElement get abstractField;
}

/// A getter.
abstract class GetterElement extends AccessorElement {
  /// The setter corresponding to this getter, if any.
  SetterElement get setter;
}

/// A setter.
abstract class SetterElement extends AccessorElement {
  /// The getter corresponding to this setter, if any.
  GetterElement get getter;
}

/// A top level, static or instance function.
abstract class MethodElement extends FunctionElement
    implements MemberElement, FunctionEntity {}

/// A local function or closure (anonymous local function).
abstract class LocalFunctionElement extends FunctionElement
    implements LocalElement {}

/// A constructor.
abstract class ConstructorElement extends MethodElement
    implements ConstructorEntity {
  /// Returns `true` if [effectiveTarget] has been computed for this
  /// constructor.
  bool get hasEffectiveTarget;

  /// The effective target of this constructor, that is the non-redirecting
  /// constructor that is called on invocation of this constructor.
  ///
  /// Consider for instance this hierarchy:
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
  /// Consider for instance this hierarchy:
  ///
  ///     class C { factory C() = D; }
  ///     class D { factory D() = E; }
  ///     class E { E(); }
  ///
  /// The immediate redirection target of `C` is `D` and the immediate
  /// redirection target of `D` is `E`. `E` is not a redirecting factory
  /// constructor so its immediate redirection target is `null`.
  ConstructorElement get immediateRedirectionTarget;

  /// The prefix of the immediateRedirectionTarget, if it is deferred.
  /// [null] if it is not deferred.
  PrefixElement get redirectionDeferredPrefix;

  /// Is `true` if this constructor is a redirecting generative constructor.
  bool get isRedirectingGenerative;

  /// Is `true` if this constructor is a redirecting factory constructor.
  bool get isRedirectingFactory;

  /// Is `true` if this constructor is a redirecting factory constructor that is
  /// part of a redirection cycle.
  bool get isCyclicRedirection;

  /// Is `true` if the effective target of this constructor is malformed.
  ///
  /// A constructor is considered malformed if any of the following applies:
  ///
  ///     * the constructor is undefined,
  ///     * the type of the constructor is undefined,
  ///     * the constructor is a redirecting factory and either
  ///       - it is part of a redirection cycle,
  ///       - the effective target is a generative constructor on an abstract
  ///         class, or
  ///       - this constructor is constant but the effective target is not,
  ///       - the arguments to this constructor are incompatible with the
  ///         parameters of the effective target.
  bool get isEffectiveTargetMalformed;

  /// Compute the type of the effective target of this constructor for an
  /// instantiation site with type [:newType:].
  /// May return a malformed type.
  ResolutionDartType computeEffectiveTargetType(
      ResolutionInterfaceType newType);

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

  /// Returns `true` if this constructor is an implicit default constructor.
  bool get isDefaultConstructor;

  /// The constant constructor defining the binding of fields if `const`,
  /// `null` otherwise.
  ConstantConstructor get constantConstructor;

  /// `true` if this constructor is one of `bool.fromEnvironment`,
  /// `int.fromEnvironment`, or `String.fromEnvironment`.
  bool get isFromEnvironmentConstructor;

  /// `true` if this constructor is `int.fromEnvironment`.
  bool get isIntFromEnvironmentConstructor;

  /// `true` if this constructor is `bool.fromEnvironment`.
  bool get isBoolFromEnvironmentConstructor;

  /// `true` if this constructor is `String.fromEnvironment`.
  bool get isStringFromEnvironmentConstructor;

  /// Use [enclosingClass] instead.
  @deprecated
  get enclosingElement;
}

/// JavaScript backend specific element for the body of constructor.
// TODO(johnniwinther): Remove this class from the element model.
abstract class ConstructorBodyElement extends MethodElement {
  ConstructorElement get constructor;
}

/// [GenericElement] defines the common interface for generic functions and
/// [TypeDeclarationElement].
abstract class GenericElement extends Element implements AstElement {
  /// Do not use [computeType] outside of the resolver.
  ///
  /// Trying to access a type that has not been computed in resolution is an
  /// error and calling [computeType] covers that error.
  /// This method will go away!
  @deprecated
  ResolutionDartType computeType(Resolution resolution);

  /**
   * The type variables declared on this declaration. The type variables are not
   * available until the type of the element has been computed through
   * [computeType].
   */
  List<ResolutionDartType> get typeVariables;
}

/// [TypeDeclarationElement] defines the common interface for class/interface
/// declarations and typedefs.
abstract class TypeDeclarationElement extends GenericElement {
  /// The name of this type declaration, taking privacy into account.
  Name get memberName;

  /// Do not use [computeType] outside of the resolver; instead retrieve the
  /// type from the [thisType] or [rawType], depending on the use case.
  ///
  /// Trying to access a type that has not been computed in resolution is an
  /// error and calling [computeType] covers that error.
  /// This method will go away!
  @deprecated
  GenericType computeType(Resolution resolution);

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
   * instantiation of [ResolutionInterfaceType] with [:dynamic:] as type
   * argument. Using this distinction, we can print the raw type with type
   * arguments only when the input source has used explicit type arguments.
   */
  GenericType get rawType;

  bool get isResolved;

  void ensureResolved(Resolution resolution);
}

abstract class ClassElement extends TypeDeclarationElement
    implements ScopeContainerElement, ClassEntity {
  /// The length of the longest inheritance path from [:Object:].
  int get hierarchyDepth;

  ResolutionInterfaceType get rawType;
  ResolutionInterfaceType get thisType;
  ClassElement get superclass;

  /// The direct supertype of this class.
  ResolutionDartType get supertype;

  /// Ordered set of all supertypes of this class including the class itself.
  OrderedTypeSet get allSupertypesAndSelf;

  /// A list of all supertypes of this class excluding the class itself.
  Link<InterfaceType> get allSupertypes;

  /// Returns the this type of this class as an instance of [cls].
  ResolutionInterfaceType asInstanceOf(ClassElement cls);

  /// A list of all direct superinterfaces of this class.
  Link<ResolutionDartType> get interfaces;

  bool get hasConstructor;
  Link<Element> get constructors;

  ClassElement get patch;
  ClassElement get origin;
  ClassElement get declaration;
  ClassElement get implementation;

  /// `true` if this class is an enum declaration.
  bool get isEnumClass;

  /// `true` if this class is a mixin application, either named or unnamed.
  bool get isMixinApplication;

  /// `true` if this class is a named mixin application, e.g.
  ///
  ///     class NamedMixinApplication = SuperClass with MixinClass;
  ///
  bool get isNamedMixinApplication;

  /// `true` if this class is an unnamed mixin application, e.g. the synthesized
  /// `SuperClass+MixinClass` mixin application class in:
  ///
  ///     class Class extends SuperClass with MixinClass {}
  ///
  bool get isUnnamedMixinApplication;

  bool get hasConstructorBodies;
  bool get hasLocalScopeMembers;

  /// Returns `true` if this class is `Object` from dart:core.
  bool get isObject;

  /// Returns `true` if this class implements [Function] either by directly
  /// implementing the interface or by providing a [call] method.
  bool implementsFunction(CommonElements commonElements);

  /// Returns `true` if this class extends [cls] directly or indirectly.
  ///
  /// This method is not to be used for checking type hierarchy and assignments,
  /// because it does not take parameterized types into account.
  bool isSubclassOf(ClassElement cls);

  /// Returns `true` if this class explicitly implements [intrface].
  ///
  /// Note that, if [intrface] is the `Function` class, this method returns
  /// false for a class that has a `call` method but does not explicitly
  /// implement `Function`.
  bool implementsInterface(ClassElement intrface);

  bool hasFieldShadowedBy(FieldElement fieldMember);

  /// Returns `true` if this class has a @proxy annotation.
  bool get isProxy;

  /// Returns `true` if the class hierarchy for this class contains errors.
  bool get hasIncompleteHierarchy;

  void addConstructorBody(ConstructorBodyElement element);

  Element lookupMember(String memberName);

  /// Looks up a class instance member declared or inherited in this class
  /// using [memberName] to match the (private) name and getter/setter property.
  ///
  /// This method recursively visits superclasses until the member is found or
  /// [stopAt] is reached.
  MemberElement lookupByName(Name memberName, {ClassElement stopAt});
  MemberElement lookupSuperByName(Name memberName);

  Element lookupLocalMember(String memberName);
  ConstructorBodyElement lookupConstructorBody(String memberName);
  Element lookupSuperMember(String memberName);

  Element lookupSuperMemberInLibrary(String memberName, LibraryElement library);

  // TODO(johnniwinther): Clean up semantics. Can the default constructor take
  // optional arguments? Must it be resolved?
  ConstructorElement lookupDefaultConstructor();
  ConstructorElement lookupConstructor(String name);

  void forEachMember(void f(ClassElement enclosingClass, Element member),
      {bool includeBackendMembers: false,
      bool includeSuperAndInjectedMembers: false});

  void forEachInstanceField(
      void f(ClassElement enclosingClass, FieldElement field),
      {bool includeSuperAndInjectedMembers: false});

  /// Similar to [forEachInstanceField] but visits static fields.
  void forEachStaticField(void f(ClassElement enclosingClass, Element field));

  void forEachConstructorBody(void f(ConstructorBodyElement member));

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
  ResolutionFunctionType get callType;
}

abstract class MixinApplicationElement extends ClassElement {
  ClassElement get mixin;
  ResolutionInterfaceType get mixinType;

  /// If this is an unnamed mixin application [subclass] is the subclass for
  /// which this mixin application is created.
  ClassElement get subclass;
}

/// Enum declaration.
abstract class EnumClassElement extends ClassElement {
  /// The static fields implied by the enum values.
  List<EnumConstantElement> get enumValues;
}

/// An enum constant value.
abstract class EnumConstantElement extends FieldElement {
  /// The enum that declared this constant.
  EnumClassElement get enclosingClass;

  /// The index of this constant within the values of the enum.
  int get index;
}

/// The [Element] for a type variable declaration on a generic class or typedef.
abstract class TypeVariableElement extends Element
    implements AstElement, TypedElement, TypeVariableEntity {
  /// The name of this type variable, taking privacy into account.
  Name get memberName;

  /// Use [typeDeclaration] instead.
  @deprecated
  get enclosingElement;

  /// The class, typedef, function, method, or function typed parameter on
  /// which this type variable is defined.
  GenericElement get typeDeclaration;

  /// The index of this type variable within its type declaration.
  int get index;

  /// The [type] defined by the type variable.
  ResolutionTypeVariableType get type;

  /// The upper bound on the type variable. If not explicitly declared, this is
  /// `Object`.
  ResolutionDartType get bound;
}

abstract class MetadataAnnotation implements Spannable {
  /// The front-end constant of this metadata annotation.
  ConstantExpression get constant;
  Element get annotatedElement;
  SourceSpan get sourcePosition;

  bool get hasNode;
  Node get node;

  MetadataAnnotation ensureResolved(Resolution resolution);
}

/// An [Element] that has a type.
abstract class TypedElement extends Element {
  /// Do not use [computeType] outside of the resolver; instead retrieve the
  /// type from  [type] property.
  ///
  /// Trying to access a type that has not been computed in resolution is an
  /// error and calling [computeType] covers that error.
  /// This method will go away!
  @deprecated
  ResolutionDartType computeType(Resolution resolution);

  ResolutionDartType get type;
}

/// An [Element] that can define a function type.
abstract class FunctionTypedElement extends Element implements GenericElement {
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

/// Enum values for different ways of defining semantics for an element.
enum ResolvedAstKind {
  /// The semantics of the element is defined in terms of an AST with resolved
  /// data mapped in [TreeElements].
  PARSED,

  /// The element is an implicit default constructor. No AST or [TreeElements]
  /// are provided.
  DEFAULT_CONSTRUCTOR,

  /// The element is an implicit forwarding constructor on a mixin application.
  /// No AST or [TreeElements] are provided.
  FORWARDING_CONSTRUCTOR,

  /// The element is the `loadLibrary` getter implicitly defined on a deferred
  /// prefix.
  DEFERRED_LOAD_LIBRARY,
}

/// [ResolvedAst] contains info that define the semantics of an element.
abstract class ResolvedAst {
  /// The element whose semantics is defined.
  Element get element;

  /// The kind of semantics definition used for this object.
  ResolvedAstKind get kind;

  /// The root AST node for the declaration of [element]. This only available if
  /// [kind] is `ResolvedAstKind.PARSED`.
  Node get node;

  /// The AST node for the 'body' of [element].
  ///
  /// For functions and constructors this is the root AST node of the method
  /// body, and for variables this is the root AST node of the initializer, if
  /// available.
  ///
  /// This only available if [kind] is `ResolvedAstKind.PARSED`.
  Node get body;

  /// The [TreeElements] containing the resolution data for [node]. This only
  /// available of [kind] is `ResolvedAstKind.PARSED`.
  TreeElements get elements;

  /// Returns the uri for the source file defining [node] and [body]. This
  /// only available if [kind] is `ResolvedAstKind.PARSED`.
  Uri get sourceUri;
}

/// [ResolvedAst] implementation used for elements whose semantics is defined in
/// terms an AST and a [TreeElements].
class ParsedResolvedAst implements ResolvedAst {
  final Element element;
  final Node node;
  final Node body;
  final TreeElements elements;
  final Uri sourceUri;

  ParsedResolvedAst(
      this.element, this.node, this.body, this.elements, this.sourceUri);

  ResolvedAstKind get kind => ResolvedAstKind.PARSED;

  String toString() => '$kind:$element:$node';
}

/// [ResolvedAst] implementation used for synthesized elements whose semantics
/// is not defined in terms an AST and a [TreeElements].
class SynthesizedResolvedAst implements ResolvedAst {
  final Element element;
  final ResolvedAstKind kind;

  SynthesizedResolvedAst(this.element, this.kind);

  @override
  TreeElements get elements {
    throw new UnsupportedError('$this does not provide a TreeElements');
  }

  @override
  Node get node {
    throw new UnsupportedError('$this does not have a root AST node');
  }

  @override
  Node get body {
    throw new UnsupportedError('$this does not have a body AST node');
  }

  @override
  Uri get sourceUri {
    throw new UnsupportedError('$this does not have a source URI');
  }

  String toString() => '$kind:$element';
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
  ResolutionDartType get type;

  /// The function type of the member. For a getter `Foo get foo` this is
  /// `() -> Foo`, for a setter `void set foo(Foo _)` this is `(Foo) -> void`.
  /// For methods the function type is defined by the return type and
  /// parameters.
  ResolutionFunctionType get functionType;

  /// Returns `true` if this member is a getter, possibly implicitly defined by a
  /// field declaration.
  bool get isGetter;

  /// Returns `true` if this member is a setter, possibly implicitly defined by a
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
  MemberElement get element;

  /// The instance of the class that declared this member.
  ///
  /// For instance:
  ///   class A<T> { T m() {} }
  ///   class B<S> extends A<S> {}
  /// The declarer of `m` in `A` is `A<T>` whereas the declarer of `m` in `B` is
  /// `A<S>`.
  ResolutionInterfaceType get declarer;

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
