// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.element;

import 'dart:collection';
import 'java_core.dart';
import 'java_engine.dart';
import 'utilities_collection.dart';
import 'source.dart';
import 'scanner.dart' show Keyword;
import 'ast.dart' show Identifier, LibraryIdentifier;
import 'sdk.dart' show DartSdk;
import 'html.dart' show XmlTagNode;
import 'engine.dart' show AnalysisContext;
import 'constant.dart' show EvaluationResultImpl;
import 'utilities_dart.dart';

/**
 * The interface `ClassElement` defines the behavior of elements that represent a class.
 *
 * @coverage dart.engine.element
 */
abstract class ClassElement implements Element {
  /**
   * Return an array containing all of the accessors (getters and setters) declared in this class.
   *
   * @return the accessors declared in this class
   */
  List<PropertyAccessorElement> get accessors;

  /**
   * Return an array containing all the supertypes defined for this class and its supertypes. This
   * includes superclasses, mixins and interfaces.
   *
   * @return all the supertypes of this class, including mixins
   */
  List<InterfaceType> get allSupertypes;

  /**
   * Return an array containing all of the constructors declared in this class.
   *
   * @return the constructors declared in this class
   */
  List<ConstructorElement> get constructors;

  /**
   * Return an array containing all of the fields declared in this class.
   *
   * @return the fields declared in this class
   */
  List<FieldElement> get fields;

  /**
   * Return the element representing the getter with the given name that is declared in this class,
   * or `null` if this class does not declare a getter with the given name.
   *
   * @param getterName the name of the getter to be returned
   * @return the getter declared in this class with the given name
   */
  PropertyAccessorElement getGetter(String getterName);

  /**
   * Return an array containing all of the interfaces that are implemented by this class.
   *
   * <b>Note:</b> Because the element model represents the state of the code, it is possible for it
   * to be semantically invalid. In particular, it is not safe to assume that the inheritance
   * structure of a class does not contain a cycle. Clients that traverse the inheritance structure
   * must explicitly guard against infinite loops.
   *
   * @return the interfaces that are implemented by this class
   */
  List<InterfaceType> get interfaces;

  /**
   * Return the element representing the method with the given name that is declared in this class,
   * or `null` if this class does not declare a method with the given name.
   *
   * @param methodName the name of the method to be returned
   * @return the method declared in this class with the given name
   */
  MethodElement getMethod(String methodName);

  /**
   * Return an array containing all of the methods declared in this class.
   *
   * @return the methods declared in this class
   */
  List<MethodElement> get methods;

  /**
   * Return an array containing all of the mixins that are applied to the class being extended in
   * order to derive the superclass of this class.
   *
   * <b>Note:</b> Because the element model represents the state of the code, it is possible for it
   * to be semantically invalid. In particular, it is not safe to assume that the inheritance
   * structure of a class does not contain a cycle. Clients that traverse the inheritance structure
   * must explicitly guard against infinite loops.
   *
   * @return the mixins that are applied to derive the superclass of this class
   */
  List<InterfaceType> get mixins;

  /**
   * Return the named constructor declared in this class with the given name, or `null` if
   * this class does not declare a named constructor with the given name.
   *
   * @param name the name of the constructor to be returned
   * @return the element representing the specified constructor
   */
  ConstructorElement getNamedConstructor(String name);

  /**
   * Return the element representing the setter with the given name that is declared in this class,
   * or `null` if this class does not declare a setter with the given name.
   *
   * @param setterName the name of the getter to be returned
   * @return the setter declared in this class with the given name
   */
  PropertyAccessorElement getSetter(String setterName);

  /**
   * Return the superclass of this class, or `null` if the class represents the class
   * 'Object'. All other classes will have a non-`null` superclass. If the superclass was not
   * explicitly declared then the implicit superclass 'Object' will be returned.
   *
   * <b>Note:</b> Because the element model represents the state of the code, it is possible for it
   * to be semantically invalid. In particular, it is not safe to assume that the inheritance
   * structure of a class does not contain a cycle. Clients that traverse the inheritance structure
   * must explicitly guard against infinite loops.
   *
   * @return the superclass of this class
   */
  InterfaceType get supertype;

  /**
   * Return the type defined by the class.
   *
   * @return the type defined by the class
   */
  InterfaceType get type;

  /**
   * Return an array containing all of the type parameters declared for this class.
   *
   * @return the type parameters declared for this class
   */
  List<TypeParameterElement> get typeParameters;

  /**
   * Return the unnamed constructor declared in this class, or `null` if this class does not
   * declare an unnamed constructor but does declare named constructors. The returned constructor
   * will be synthetic if this class does not declare any constructors, in which case it will
   * represent the default constructor for the class.
   *
   * @return the unnamed constructor defined in this class
   */
  ConstructorElement get unnamedConstructor;

  /**
   * Return `true` if this class or its superclass declares a non-final instance field.
   *
   * @return `true` if this class or its superclass declares a non-final instance field
   */
  bool hasNonFinalField();

  /**
   * Return `true` if this class has reference to super (so, for example, cannot be used as a
   * mixin).
   *
   * @return `true` if this class has reference to super
   */
  bool hasReferenceToSuper();

  /**
   * Return `true` if this class is abstract. A class is abstract if it has an explicit
   * `abstract` modifier. Note, that this definition of <i>abstract</i> is different from
   * <i>has unimplemented members</i>.
   *
   * @return `true` if this class is abstract
   */
  bool get isAbstract;

  /**
   * Return `true` if this element has an annotation of the form '@proxy'.
   *
   * @return `true` if this element defines a proxy
   */
  bool get isProxy;

  /**
   * Return `true` if this class is defined by a typedef construct.
   *
   * @return `true` if this class is defined by a typedef construct
   */
  bool get isTypedef;

  /**
   * Return `true` if this class can validly be used as a mixin when defining another class.
   * The behavior of this method is defined by the Dart Language Specification in section 9:
   * <blockquote>It is a compile-time error if a declared or derived mixin refers to super. It is a
   * compile-time error if a declared or derived mixin explicitly declares a constructor. It is a
   * compile-time error if a mixin is derived from a class whose superclass is not
   * Object.</blockquote>
   *
   * @return `true` if this class can validly be used as a mixin
   */
  bool get isValidMixin;

  /**
   * Return the element representing the getter that results from looking up the given getter in
   * this class with respect to the given library, or `null` if the look up fails. The
   * behavior of this method is defined by the Dart Language Specification in section 12.15.1:
   * <blockquote>The result of looking up getter (respectively setter) <i>m</i> in class <i>C</i>
   * with respect to library <i>L</i> is:
   *
   * * If <i>C</i> declares an instance getter (respectively setter) named <i>m</i> that is
   * accessible to <i>L</i>, then that getter (respectively setter) is the result of the lookup.
   * Otherwise, if <i>C</i> has a superclass <i>S</i>, then the result of the lookup is the result
   * of looking up getter (respectively setter) <i>m</i> in <i>S</i> with respect to <i>L</i>.
   * Otherwise, we say that the lookup has failed.
   *
   * </blockquote>
   *
   * @param getterName the name of the getter being looked up
   * @param library the library with respect to which the lookup is being performed
   * @return the result of looking up the given getter in this class with respect to the given
   *         library
   */
  PropertyAccessorElement lookUpGetter(String getterName, LibraryElement library);

  /**
   * Return the element representing the method that results from looking up the given method in
   * this class with respect to the given library, or `null` if the look up fails. The
   * behavior of this method is defined by the Dart Language Specification in section 12.15.1:
   * <blockquote> The result of looking up method <i>m</i> in class <i>C</i> with respect to library
   * <i>L</i> is:
   *
   * * If <i>C</i> declares an instance method named <i>m</i> that is accessible to <i>L</i>, then
   * that method is the result of the lookup. Otherwise, if <i>C</i> has a superclass <i>S</i>, then
   * the result of the lookup is the result of looking up method <i>m</i> in <i>S</i> with respect
   * to <i>L</i>. Otherwise, we say that the lookup has failed.
   *
   * </blockquote>
   *
   * @param methodName the name of the method being looked up
   * @param library the library with respect to which the lookup is being performed
   * @return the result of looking up the given method in this class with respect to the given
   *         library
   */
  MethodElement lookUpMethod(String methodName, LibraryElement library);

  /**
   * Return the element representing the setter that results from looking up the given setter in
   * this class with respect to the given library, or `null` if the look up fails. The
   * behavior of this method is defined by the Dart Language Specification in section 12.16:
   * <blockquote> The result of looking up getter (respectively setter) <i>m</i> in class <i>C</i>
   * with respect to library <i>L</i> is:
   *
   * * If <i>C</i> declares an instance getter (respectively setter) named <i>m</i> that is
   * accessible to <i>L</i>, then that getter (respectively setter) is the result of the lookup.
   * Otherwise, if <i>C</i> has a superclass <i>S</i>, then the result of the lookup is the result
   * of looking up getter (respectively setter) <i>m</i> in <i>S</i> with respect to <i>L</i>.
   * Otherwise, we say that the lookup has failed.
   *
   * </blockquote>
   *
   * @param setterName the name of the setter being looked up
   * @param library the library with respect to which the lookup is being performed
   * @return the result of looking up the given setter in this class with respect to the given
   *         library
   */
  PropertyAccessorElement lookUpSetter(String setterName, LibraryElement library);
}

/**
 * The interface `ClassMemberElement` defines the behavior of elements that are contained
 * within a [ClassElement].
 */
abstract class ClassMemberElement implements Element {
  /**
   * Return the type in which this member is defined.
   *
   * @return the type in which this member is defined
   */
  ClassElement get enclosingElement;

  /**
   * Return `true` if this element is a static element. A static element is an element that is
   * not associated with a particular instance, but rather with an entire library or class.
   *
   * @return `true` if this executable element is a static element
   */
  bool get isStatic;
}

/**
 * The interface `CompilationUnitElement` defines the behavior of elements representing a
 * compilation unit.
 *
 * @coverage dart.engine.element
 */
abstract class CompilationUnitElement implements Element, UriReferencedElement {
  /**
   * Return an array containing all of the top-level accessors (getters and setters) contained in
   * this compilation unit.
   *
   * @return the top-level accessors contained in this compilation unit
   */
  List<PropertyAccessorElement> get accessors;

  /**
   * Return the library in which this compilation unit is defined.
   *
   * @return the library in which this compilation unit is defined
   */
  LibraryElement get enclosingElement;

  /**
   * Return an array containing all of the top-level functions contained in this compilation unit.
   *
   * @return the top-level functions contained in this compilation unit
   */
  List<FunctionElement> get functions;

  /**
   * Return an array containing all of the function type aliases contained in this compilation unit.
   *
   * @return the function type aliases contained in this compilation unit
   */
  List<FunctionTypeAliasElement> get functionTypeAliases;

  /**
   * Return an array containing all of the top-level variables contained in this compilation unit.
   *
   * @return the top-level variables contained in this compilation unit
   */
  List<TopLevelVariableElement> get topLevelVariables;

  /**
   * Return the class defined in this compilation unit that has the given name, or `null` if
   * this compilation unit does not define a class with the given name.
   *
   * @param className the name of the class to be returned
   * @return the class with the given name that is defined in this compilation unit
   */
  ClassElement getType(String className);

  /**
   * Return an array containing all of the classes contained in this compilation unit.
   *
   * @return the classes contained in this compilation unit
   */
  List<ClassElement> get types;
}

/**
 * The interface `ConstructorElement` defines the behavior of elements representing a
 * constructor or a factory method defined within a type.
 *
 * @coverage dart.engine.element
 */
abstract class ConstructorElement implements ClassMemberElement, ExecutableElement {
  /**
   * Return the constructor to which this constructor is redirecting.
   *
   * @return the constructor to which this constructor is redirecting
   */
  ConstructorElement get redirectedConstructor;

  /**
   * Return `true` if this constructor is a const constructor.
   *
   * @return `true` if this constructor is a const constructor
   */
  bool get isConst;

  /**
   * Return `true` if this constructor can be used as a default constructor - unnamed and has
   * no required parameters.
   *
   * @return `true` if this constructor can be used as a default constructor.
   */
  bool get isDefaultConstructor;

  /**
   * Return `true` if this constructor represents a factory constructor.
   *
   * @return `true` if this constructor represents a factory constructor
   */
  bool get isFactory;
}

/**
 * The interface `Element` defines the behavior common to all of the elements in the element
 * model. Generally speaking, the element model is a semantic model of the program that represents
 * things that are declared with a name and hence can be referenced elsewhere in the code.
 *
 * There are two exceptions to the general case. First, there are elements in the element model that
 * are created for the convenience of various kinds of analysis but that do not have any
 * corresponding declaration within the source code. Such elements are marked as being
 * <i>synthetic</i>. Examples of synthetic elements include
 *
 * * default constructors in classes that do not define any explicit constructors,
 * * getters and setters that are induced by explicit field declarations,
 * * fields that are induced by explicit declarations of getters and setters, and
 * * functions representing the initialization expression for a variable.
 *
 *
 * Second, there are elements in the element model that do not have a name. These correspond to
 * unnamed functions and exist in order to more accurately represent the semantic structure of the
 * program.
 *
 * @coverage dart.engine.element
 */
abstract class Element {
  /**
   * An Unicode right arrow.
   */
  static final String RIGHT_ARROW = " \u2192 ";

  /**
   * A comparator that can be used to sort elements by their name offset. Elements with a smaller
   * offset will be sorted to be before elements with a larger name offset.
   */
  static final Comparator<Element> SORT_BY_OFFSET = (Element firstElement, Element secondElement) => firstElement.nameOffset - secondElement.nameOffset;

  /**
   * Use the given visitor to visit this element.
   *
   * @param visitor the visitor that will visit this element
   * @return the value returned by the visitor as a result of visiting this element
   */
  accept(ElementVisitor visitor);

  /**
   * Return the documentation comment for this element as it appears in the original source
   * (complete with the beginning and ending delimiters), or `null` if this element does not
   * have a documentation comment associated with it. This can be a long-running operation if the
   * information needed to access the comment is not cached.
   *
   * @return this element's documentation comment
   * @throws AnalysisException if the documentation comment could not be determined because the
   *           analysis could not be performed
   */
  String computeDocumentationComment();

  /**
   * Return the element of the given class that most immediately encloses this element, or
   * `null` if there is no enclosing element of the given class.
   *
   * @param elementClass the class of the element to be returned
   * @return the element that encloses this element
   */
  Element getAncestor(Type elementClass);

  /**
   * Return the analysis context in which this element is defined.
   *
   * @return the analysis context in which this element is defined
   */
  AnalysisContext get context;

  /**
   * Return the display name of this element, or `null` if this element does not have a name.
   *
   * In most cases the name and the display name are the same. Differences though are cases such as
   * setters where the name of some setter `set f(x)` is `f=`, instead of `f`.
   *
   * @return the display name of this element
   */
  String get displayName;

  /**
   * Return the element that either physically or logically encloses this element. This will be
   * `null` if this element is a library because libraries are the top-level elements in the
   * model.
   *
   * @return the element that encloses this element
   */
  Element get enclosingElement;

  /**
   * Return the kind of element that this is.
   *
   * @return the kind of this element
   */
  ElementKind get kind;

  /**
   * Return the library that contains this element. This will be the element itself if it is a
   * library element. This will be `null` if this element is an HTML file because HTML files
   * are not contained in libraries.
   *
   * @return the library that contains this element
   */
  LibraryElement get library;

  /**
   * Return an object representing the location of this element in the element model. The object can
   * be used to locate this element at a later time.
   *
   * @return the location of this element in the element model
   */
  ElementLocation get location;

  /**
   * Return an array containing all of the metadata associated with this element.
   *
   * @return the metadata associated with this element
   */
  List<ElementAnnotation> get metadata;

  /**
   * Return the name of this element, or `null` if this element does not have a name.
   *
   * @return the name of this element
   */
  String get name;

  /**
   * Return the offset of the name of this element in the file that contains the declaration of this
   * element, or `-1` if this element is synthetic, does not have a name, or otherwise does
   * not have an offset.
   *
   * @return the offset of the name of this element
   */
  int get nameOffset;

  /**
   * Return the source that contains this element, or `null` if this element is not contained
   * in a source.
   *
   * @return the source that contains this element
   */
  Source get source;

  /**
   * Return `true` if this element, assuming that it is within scope, is accessible to code in
   * the given library. This is defined by the Dart Language Specification in section 3.2:
   * <blockquote> A declaration <i>m</i> is accessible to library <i>L</i> if <i>m</i> is declared
   * in <i>L</i> or if <i>m</i> is public. </blockquote>
   *
   * @param library the library in which a possible reference to this element would occur
   * @return `true` if this element is accessible to code in the given library
   */
  bool isAccessibleIn(LibraryElement library);

  /**
   * Return `true` if this element has an annotation of the form '@deprecated' or
   * '@Deprecated('..')'.
   *
   * @return `true` if this element is deprecated
   */
  bool get isDeprecated;

  /**
   * Return `true` if this element is synthetic. A synthetic element is an element that is not
   * represented in the source code explicitly, but is implied by the source code, such as the
   * default constructor for a class that does not explicitly define any constructors.
   *
   * @return `true` if this element is synthetic
   */
  bool get isSynthetic;

  /**
   * Use the given visitor to visit all of the children of this element. There is no guarantee of
   * the order in which the children will be visited.
   *
   * @param visitor the visitor that will be used to visit the children of this element
   */
  void visitChildren(ElementVisitor visitor);
}

/**
 * The interface `ElementAnnotation` defines the behavior of objects representing a single
 * annotation associated with an element.
 *
 * @coverage dart.engine.element
 */
abstract class ElementAnnotation {
  /**
   * Return the element representing the field, variable, or const constructor being used as an
   * annotation.
   *
   * @return the field, variable, or constructor being used as an annotation
   */
  Element get element;

  /**
   * Return `true` if this annotation marks the associated element as being deprecated.
   *
   * @return `true` if this annotation marks the associated element as being deprecated
   */
  bool get isDeprecated;

  /**
   * Return `true` if this annotation marks the associated method as being expected to
   * override an inherited method.
   *
   * @return `true` if this annotation marks the associated method as overriding another
   *         method
   */
  bool get isOverride;

  /**
   * Return `true` if this annotation marks the associated class as implementing a proxy
   * object.
   *
   * @return `true` if this annotation marks the associated class as implementing a proxy
   *         object
   */
  bool get isProxy;
}

/**
 * The enumeration `ElementKind` defines the various kinds of elements in the element model.
 *
 * @coverage dart.engine.element
 */
class ElementKind extends Enum<ElementKind> {
  static final ElementKind CLASS = new ElementKind('CLASS', 0, "class");

  static final ElementKind COMPILATION_UNIT = new ElementKind('COMPILATION_UNIT', 1, "compilation unit");

  static final ElementKind CONSTRUCTOR = new ElementKind('CONSTRUCTOR', 2, "constructor");

  static final ElementKind DYNAMIC = new ElementKind('DYNAMIC', 3, "<dynamic>");

  static final ElementKind EMBEDDED_HTML_SCRIPT = new ElementKind('EMBEDDED_HTML_SCRIPT', 4, "embedded html script");

  static final ElementKind ERROR = new ElementKind('ERROR', 5, "<error>");

  static final ElementKind EXPORT = new ElementKind('EXPORT', 6, "export directive");

  static final ElementKind EXTERNAL_HTML_SCRIPT = new ElementKind('EXTERNAL_HTML_SCRIPT', 7, "external html script");

  static final ElementKind FIELD = new ElementKind('FIELD', 8, "field");

  static final ElementKind FUNCTION = new ElementKind('FUNCTION', 9, "function");

  static final ElementKind GETTER = new ElementKind('GETTER', 10, "getter");

  static final ElementKind HTML = new ElementKind('HTML', 11, "html");

  static final ElementKind IMPORT = new ElementKind('IMPORT', 12, "import directive");

  static final ElementKind LABEL = new ElementKind('LABEL', 13, "label");

  static final ElementKind LIBRARY = new ElementKind('LIBRARY', 14, "library");

  static final ElementKind LOCAL_VARIABLE = new ElementKind('LOCAL_VARIABLE', 15, "local variable");

  static final ElementKind METHOD = new ElementKind('METHOD', 16, "method");

  static final ElementKind NAME = new ElementKind('NAME', 17, "<name>");

  static final ElementKind PARAMETER = new ElementKind('PARAMETER', 18, "parameter");

  static final ElementKind PREFIX = new ElementKind('PREFIX', 19, "import prefix");

  static final ElementKind SETTER = new ElementKind('SETTER', 20, "setter");

  static final ElementKind TOP_LEVEL_VARIABLE = new ElementKind('TOP_LEVEL_VARIABLE', 21, "top level variable");

  static final ElementKind FUNCTION_TYPE_ALIAS = new ElementKind('FUNCTION_TYPE_ALIAS', 22, "function type alias");

  static final ElementKind TYPE_PARAMETER = new ElementKind('TYPE_PARAMETER', 23, "type parameter");

  static final ElementKind UNIVERSE = new ElementKind('UNIVERSE', 24, "<universe>");

  static final List<ElementKind> values = [
      CLASS,
      COMPILATION_UNIT,
      CONSTRUCTOR,
      DYNAMIC,
      EMBEDDED_HTML_SCRIPT,
      ERROR,
      EXPORT,
      EXTERNAL_HTML_SCRIPT,
      FIELD,
      FUNCTION,
      GETTER,
      HTML,
      IMPORT,
      LABEL,
      LIBRARY,
      LOCAL_VARIABLE,
      METHOD,
      NAME,
      PARAMETER,
      PREFIX,
      SETTER,
      TOP_LEVEL_VARIABLE,
      FUNCTION_TYPE_ALIAS,
      TYPE_PARAMETER,
      UNIVERSE];

  /**
   * Return the kind of the given element, or [ERROR] if the element is `null`. This is
   * a utility method that can reduce the need for null checks in other places.
   *
   * @param element the element whose kind is to be returned
   * @return the kind of the given element
   */
  static ElementKind of(Element element) {
    if (element == null) {
      return ERROR;
    }
    return element.kind;
  }

  /**
   * The name displayed in the UI for this kind of element.
   */
  String displayName;

  /**
   * Initialize a newly created element kind to have the given display name.
   *
   * @param displayName the name displayed in the UI for this kind of element
   */
  ElementKind(String name, int ordinal, String displayName) : super(name, ordinal) {
    this.displayName = displayName;
  }
}

/**
 * The interface `ElementLocation` defines the behavior of objects that represent the location
 * of an element within the element model.
 *
 * @coverage dart.engine.element
 */
abstract class ElementLocation {
  /**
   * Return an encoded representation of this location that can be used to create a location that is
   * equal to this location.
   *
   * @return an encoded representation of this location
   */
  String get encoding;
}

/**
 * The interface `ElementVisitor` defines the behavior of objects that can be used to visit an
 * element structure.
 *
 * @coverage dart.engine.element
 */
abstract class ElementVisitor<R> {
  R visitClassElement(ClassElement element);

  R visitCompilationUnitElement(CompilationUnitElement element);

  R visitConstructorElement(ConstructorElement element);

  R visitEmbeddedHtmlScriptElement(EmbeddedHtmlScriptElement element);

  R visitExportElement(ExportElement element);

  R visitExternalHtmlScriptElement(ExternalHtmlScriptElement element);

  R visitFieldElement(FieldElement element);

  R visitFieldFormalParameterElement(FieldFormalParameterElement element);

  R visitFunctionElement(FunctionElement element);

  R visitFunctionTypeAliasElement(FunctionTypeAliasElement element);

  R visitHtmlElement(HtmlElement element);

  R visitImportElement(ImportElement element);

  R visitLabelElement(LabelElement element);

  R visitLibraryElement(LibraryElement element);

  R visitLocalVariableElement(LocalVariableElement element);

  R visitMethodElement(MethodElement element);

  R visitMultiplyDefinedElement(MultiplyDefinedElement element);

  R visitParameterElement(ParameterElement element);

  R visitPrefixElement(PrefixElement element);

  R visitPropertyAccessorElement(PropertyAccessorElement element);

  R visitTopLevelVariableElement(TopLevelVariableElement element);

  R visitTypeParameterElement(TypeParameterElement element);
}

/**
 * The interface `EmbeddedHtmlScriptElement` defines the behavior of elements representing a
 * script tag in an HTML file having content that defines a Dart library.
 *
 * @coverage dart.engine.element
 */
abstract class EmbeddedHtmlScriptElement implements HtmlScriptElement {
  /**
   * Return the library element defined by the content of the script tag.
   *
   * @return the library element (not `null`)
   */
  LibraryElement get scriptLibrary;
}

/**
 * The interface `ExecutableElement` defines the behavior of elements representing an
 * executable object, including functions, methods, constructors, getters, and setters.
 *
 * @coverage dart.engine.element
 */
abstract class ExecutableElement implements Element {
  /**
   * Return an array containing all of the functions defined within this executable element.
   *
   * @return the functions defined within this executable element
   */
  List<FunctionElement> get functions;

  /**
   * Return an array containing all of the labels defined within this executable element.
   *
   * @return the labels defined within this executable element
   */
  List<LabelElement> get labels;

  /**
   * Return an array containing all of the local variables defined within this executable element.
   *
   * @return the local variables defined within this executable element
   */
  List<LocalVariableElement> get localVariables;

  /**
   * Return an array containing all of the parameters defined by this executable element.
   *
   * @return the parameters defined by this executable element
   */
  List<ParameterElement> get parameters;

  /**
   * Return the return type defined by this executable element.
   *
   * @return the return type defined by this executable element
   */
  Type2 get returnType;

  /**
   * Return the type of function defined by this executable element.
   *
   * @return the type of function defined by this executable element
   */
  FunctionType get type;

  /**
   * Return `true` if this executable element is an operator. The test may be based on the
   * name of the executable element, in which case the result will be correct when the name is
   * legal.
   *
   * @return `true` if this executable element is an operator
   */
  bool get isOperator;

  /**
   * Return `true` if this element is a static element. A static element is an element that is
   * not associated with a particular instance, but rather with an entire library or class.
   *
   * @return `true` if this executable element is a static element
   */
  bool get isStatic;
}

/**
 * The interface `ExportElement` defines the behavior of objects representing information
 * about a single export directive within a library.
 *
 * @coverage dart.engine.element
 */
abstract class ExportElement implements Element, UriReferencedElement {
  /**
   * An empty array of export elements.
   */
  static final List<ExportElement> EMPTY_ARRAY = new List<ExportElement>(0);

  /**
   * Return an array containing the combinators that were specified as part of the export directive
   * in the order in which they were specified.
   *
   * @return the combinators specified in the export directive
   */
  List<NamespaceCombinator> get combinators;

  /**
   * Return the library that is exported from this library by this export directive.
   *
   * @return the library that is exported from this library
   */
  LibraryElement get exportedLibrary;
}

/**
 * The interface `ExternalHtmlScriptElement` defines the behavior of elements representing a
 * script tag in an HTML file having a `source` attribute that references a Dart library
 * source file.
 *
 * @coverage dart.engine.element
 */
abstract class ExternalHtmlScriptElement implements HtmlScriptElement {
  /**
   * Return the source referenced by this element, or `null` if this element does not
   * reference a Dart library source file.
   *
   * @return the source for the external Dart library
   */
  Source get scriptSource;
}

/**
 * The interface `FieldElement` defines the behavior of elements representing a field defined
 * within a type.
 *
 * @coverage dart.engine.element
 */
abstract class FieldElement implements ClassMemberElement, PropertyInducingElement {
}

/**
 * The interface `FieldFormalParameterElement` defines the behavior of elements representing a
 * field formal parameter defined within a constructor element.
 */
abstract class FieldFormalParameterElement implements ParameterElement {
  /**
   * Return the field element associated with this field formal parameter, or `null` if the
   * parameter references a field that doesn't exist.
   *
   * @return the field element associated with this field formal parameter
   */
  FieldElement get field;
}

/**
 * The interface `FunctionElement` defines the behavior of elements representing a function.
 *
 * @coverage dart.engine.element
 */
abstract class FunctionElement implements ExecutableElement, LocalElement {
}

/**
 * The interface `FunctionTypeAliasElement` defines the behavior of elements representing a
 * function type alias (`typedef`).
 *
 * @coverage dart.engine.element
 */
abstract class FunctionTypeAliasElement implements Element {
  /**
   * Return the compilation unit in which this type alias is defined.
   *
   * @return the compilation unit in which this type alias is defined
   */
  CompilationUnitElement get enclosingElement;

  /**
   * Return an array containing all of the parameters defined by this type alias.
   *
   * @return the parameters defined by this type alias
   */
  List<ParameterElement> get parameters;

  /**
   * Return the return type defined by this type alias.
   *
   * @return the return type defined by this type alias
   */
  Type2 get returnType;

  /**
   * Return the type of function defined by this type alias.
   *
   * @return the type of function defined by this type alias
   */
  FunctionType get type;

  /**
   * Return an array containing all of the type parameters defined for this type.
   *
   * @return the type parameters defined for this type
   */
  List<TypeParameterElement> get typeParameters;
}

/**
 * The interface `HideElementCombinator` defines the behavior of combinators that cause some
 * of the names in a namespace to be hidden when being imported.
 *
 * @coverage dart.engine.element
 */
abstract class HideElementCombinator implements NamespaceCombinator {
  /**
   * Return an array containing the names that are not to be made visible in the importing library
   * even if they are defined in the imported library.
   *
   * @return the names from the imported library that are hidden from the importing library
   */
  List<String> get hiddenNames;
}

/**
 * The interface `HtmlElement` defines the behavior of elements representing an HTML file.
 *
 * @coverage dart.engine.element
 */
abstract class HtmlElement implements Element {
  /**
   * Return an array containing all of the script elements contained in the HTML file. This includes
   * scripts with libraries that are defined by the content of a script tag as well as libraries
   * that are referenced in the {@core source} attribute of a script tag.
   *
   * @return the script elements in the HTML file (not `null`, contains no `null`s)
   */
  List<HtmlScriptElement> get scripts;
}

/**
 * The interface `HtmlScriptElement` defines the behavior of elements representing a script
 * tag in an HTML file.
 *
 * @see EmbeddedHtmlScriptElement
 * @see ExternalHtmlScriptElement
 * @coverage dart.engine.element
 */
abstract class HtmlScriptElement implements Element {
}

/**
 * The interface `ImportElement` defines the behavior of objects representing information
 * about a single import directive within a library.
 *
 * @coverage dart.engine.element
 */
abstract class ImportElement implements Element, UriReferencedElement {
  /**
   * An empty array of import elements.
   */
  static final List<ImportElement> EMPTY_ARRAY = new List<ImportElement>(0);

  /**
   * Return an array containing the combinators that were specified as part of the import directive
   * in the order in which they were specified.
   *
   * @return the combinators specified in the import directive
   */
  List<NamespaceCombinator> get combinators;

  /**
   * Return the library that is imported into this library by this import directive.
   *
   * @return the library that is imported into this library
   */
  LibraryElement get importedLibrary;

  /**
   * Return the prefix that was specified as part of the import directive, or `null` if there
   * was no prefix specified.
   *
   * @return the prefix that was specified as part of the import directive
   */
  PrefixElement get prefix;

  /**
   * Return the offset of the prefix of this import in the file that contains this import directive,
   * or `-1` if this import is synthetic, does not have a prefix, or otherwise does not have
   * an offset.
   *
   * @return the offset of the prefix of this import
   */
  int get prefixOffset;

  /**
   * Return the offset of the character immediately following the last character of this node's URI,
   * or `-1` for synthetic import.
   *
   * @return the offset of the character just past the node's URI
   */
  int get uriEnd;
}

/**
 * The interface `LabelElement` defines the behavior of elements representing a label
 * associated with a statement.
 *
 * @coverage dart.engine.element
 */
abstract class LabelElement implements Element {
  /**
   * Return the executable element in which this label is defined.
   *
   * @return the executable element in which this label is defined
   */
  ExecutableElement get enclosingElement;
}

/**
 * The interface `LibraryElement` defines the behavior of elements representing a library.
 *
 * @coverage dart.engine.element
 */
abstract class LibraryElement implements Element {
  /**
   * Return the compilation unit that defines this library.
   *
   * @return the compilation unit that defines this library
   */
  CompilationUnitElement get definingCompilationUnit;

  /**
   * Return the entry point for this library, or `null` if this library does not have an entry
   * point. The entry point is defined to be a zero argument top-level function whose name is
   * `main`.
   *
   * @return the entry point for this library
   */
  FunctionElement get entryPoint;

  /**
   * Return an array containing all of the libraries that are exported from this library.
   *
   * @return an array containing all of the libraries that are exported from this library
   */
  List<LibraryElement> get exportedLibraries;

  /**
   * Return an array containing all of the exports defined in this library.
   *
   * @return the exports defined in this library
   */
  List<ExportElement> get exports;

  /**
   * Return an array containing all of the libraries that are imported into this library. This
   * includes all of the libraries that are imported using a prefix (also available through the
   * prefixes returned by [getPrefixes]) and those that are imported without a prefix.
   *
   * @return an array containing all of the libraries that are imported into this library
   */
  List<LibraryElement> get importedLibraries;

  /**
   * Return an array containing all of the imports defined in this library.
   *
   * @return the imports defined in this library
   */
  List<ImportElement> get imports;

  /**
   * Return an array containing all of the compilation units that are included in this library using
   * a `part` directive. This does not include the defining compilation unit that contains the
   * `part` directives.
   *
   * @return the compilation units that are included in this library
   */
  List<CompilationUnitElement> get parts;

  /**
   * Return an array containing elements for each of the prefixes used to `import` libraries
   * into this library. Each prefix can be used in more than one `import` directive.
   *
   * @return the prefixes used to `import` libraries into this library
   */
  List<PrefixElement> get prefixes;

  /**
   * Return the class defined in this library that has the given name, or `null` if this
   * library does not define a class with the given name.
   *
   * @param className the name of the class to be returned
   * @return the class with the given name that is defined in this library
   */
  ClassElement getType(String className);

  /**
   * Answer `true` if this library is an application that can be run in the browser.
   *
   * @return `true` if this library is an application that can be run in the browser
   */
  bool get isBrowserApplication;

  /**
   * Return `true` if this library is the dart:core library.
   *
   * @return `true` if this library is the dart:core library
   */
  bool get isDartCore;

  /**
   * Return `true` if this library is the dart:core library.
   *
   * @return `true` if this library is the dart:core library
   */
  bool get isInSdk;

  /**
   * Return `true` if this library is up to date with respect to the given time stamp. If any
   * transitively referenced Source is newer than the time stamp, this method returns false.
   *
   * @param timeStamp the time stamp to compare against
   * @return `true` if this library is up to date with respect to the given time stamp
   */
  bool isUpToDate2(int timeStamp);
}

/**
 * The interface `LocalElement` defines the behavior of elements that can be (but are not
 * required to be) defined within a method or function (an [ExecutableElement]).
 *
 * @coverage dart.engine.element
 */
abstract class LocalElement implements Element {
  /**
   * Return a source range that covers the approximate portion of the source in which the name of
   * this element is visible, or `null` if there is no single range of characters within which
   * the element name is visible.
   *
   * * For a local variable, this includes everything from the end of the variable's initializer
   * to the end of the block that encloses the variable declaration.
   * * For a parameter, this includes the body of the method or function that declares the
   * parameter.
   * * For a local function, this includes everything from the beginning of the function's body to
   * the end of the block that encloses the function declaration.
   * * For top-level functions, `null` will be returned because they are potentially visible
   * in multiple sources.
   *
   *
   * @return the range of characters in which the name of this element is visible
   */
  SourceRange get visibleRange;
}

/**
 * The interface `LocalVariableElement` defines the behavior common to elements that represent
 * a local variable.
 *
 * @coverage dart.engine.element
 */
abstract class LocalVariableElement implements LocalElement, VariableElement {
}

/**
 * The interface `MethodElement` defines the behavior of elements that represent a method
 * defined within a type.
 *
 * @coverage dart.engine.element
 */
abstract class MethodElement implements ClassMemberElement, ExecutableElement {
  /**
   * Return `true` if this method is abstract. Methods are abstract if they are not external
   * and have no body.
   *
   * @return `true` if this method is abstract
   */
  bool get isAbstract;
}

/**
 * The interface `MultiplyDefinedElement` defines the behavior of pseudo-elements that
 * represent multiple elements defined within a single scope that have the same name. This situation
 * is not allowed by the language, so objects implementing this interface always represent an error.
 * As a result, most of the normal operations on elements do not make sense and will return useless
 * results.
 *
 * @coverage dart.engine.element
 */
abstract class MultiplyDefinedElement implements Element {
  /**
   * Return an array containing all of the elements that were defined within the scope to have the
   * same name.
   *
   * @return the elements that were defined with the same name
   */
  List<Element> get conflictingElements;

  /**
   * Return the type of this element as the dynamic type.
   *
   * @return the type of this element as the dynamic type
   */
  Type2 get type;
}

/**
 * The interface `NamespaceCombinator` defines the behavior common to objects that control how
 * namespaces are combined.
 *
 * @coverage dart.engine.element
 */
abstract class NamespaceCombinator {
  /**
   * An empty array of namespace combinators.
   */
  static final List<NamespaceCombinator> EMPTY_ARRAY = new List<NamespaceCombinator>(0);
}

/**
 * The interface `ParameterElement` defines the behavior of elements representing a parameter
 * defined within an executable element.
 *
 * @coverage dart.engine.element
 */
abstract class ParameterElement implements LocalElement, VariableElement {
  /**
   * Return a source range that covers the portion of the source in which the default value for this
   * parameter is specified, or `null` if there is no default value.
   *
   * @return the range of characters in which the default value of this parameter is specified
   */
  SourceRange get defaultValueRange;

  /**
   * Return the kind of this parameter.
   *
   * @return the kind of this parameter
   */
  ParameterKind get parameterKind;

  /**
   * Return an array containing all of the parameters defined by this parameter. A parameter will
   * only define other parameters if it is a function typed parameter.
   *
   * @return the parameters defined by this parameter element
   */
  List<ParameterElement> get parameters;

  /**
   * Return `true` if this parameter is an initializing formal parameter.
   *
   * @return `true` if this parameter is an initializing formal parameter
   */
  bool get isInitializingFormal;
}

/**
 * The interface `PrefixElement` defines the behavior common to elements that represent a
 * prefix used to import one or more libraries into another library.
 *
 * @coverage dart.engine.element
 */
abstract class PrefixElement implements Element {
  /**
   * Return the library into which other libraries are imported using this prefix.
   *
   * @return the library into which other libraries are imported using this prefix
   */
  LibraryElement get enclosingElement;

  /**
   * Return an array containing all of the libraries that are imported using this prefix.
   *
   * @return the libraries that are imported using this prefix
   */
  List<LibraryElement> get importedLibraries;
}

/**
 * The interface `PropertyAccessorElement` defines the behavior of elements representing a
 * getter or a setter. Note that explicitly defined property accessors implicitly define a synthetic
 * field. Symmetrically, synthetic accessors are implicitly created for explicitly defined fields.
 * The following rules apply:
 *
 * * Every explicit field is represented by a non-synthetic [FieldElement].
 * * Every explicit field induces a getter and possibly a setter, both of which are represented by
 * synthetic [PropertyAccessorElement]s.
 * * Every explicit getter or setter is represented by a non-synthetic
 * [PropertyAccessorElement].
 * * Every explicit getter or setter (or pair thereof if they have the same name) induces a field
 * that is represented by a synthetic [FieldElement].
 *
 *
 * @coverage dart.engine.element
 */
abstract class PropertyAccessorElement implements ExecutableElement {
  /**
   * Return the accessor representing the getter that corresponds to (has the same name as) this
   * setter, or `null` if this accessor is not a setter or if there is no corresponding
   * getter.
   *
   * @return the getter that corresponds to this setter
   */
  PropertyAccessorElement get correspondingGetter;

  /**
   * Return the accessor representing the setter that corresponds to (has the same name as) this
   * getter, or `null` if this accessor is not a getter or if there is no corresponding
   * setter.
   *
   * @return the setter that corresponds to this getter
   */
  PropertyAccessorElement get correspondingSetter;

  /**
   * Return the field or top-level variable associated with this accessor. If this accessor was
   * explicitly defined (is not synthetic) then the variable associated with it will be synthetic.
   *
   * @return the variable associated with this accessor
   */
  PropertyInducingElement get variable;

  /**
   * Return `true` if this accessor is abstract. Accessors are abstract if they are not
   * external and have no body.
   *
   * @return `true` if this accessor is abstract
   */
  bool get isAbstract;

  /**
   * Return `true` if this accessor represents a getter.
   *
   * @return `true` if this accessor represents a getter
   */
  bool get isGetter;

  /**
   * Return `true` if this accessor represents a setter.
   *
   * @return `true` if this accessor represents a setter
   */
  bool get isSetter;
}

/**
 * The interface `PropertyInducingElement` defines the behavior of elements representing a
 * variable that has an associated getter and possibly a setter. Note that explicitly defined
 * variables implicitly define a synthetic getter and that non-`final` explicitly defined
 * variables implicitly define a synthetic setter. Symmetrically, synthetic fields are implicitly
 * created for explicitly defined getters and setters. The following rules apply:
 *
 * * Every explicit variable is represented by a non-synthetic [PropertyInducingElement].
 * * Every explicit variable induces a getter and possibly a setter, both of which are represented
 * by synthetic [PropertyAccessorElement]s.
 * * Every explicit getter or setter is represented by a non-synthetic
 * [PropertyAccessorElement].
 * * Every explicit getter or setter (or pair thereof if they have the same name) induces a
 * variable that is represented by a synthetic [PropertyInducingElement].
 *
 *
 * @coverage dart.engine.element
 */
abstract class PropertyInducingElement implements VariableElement {
  /**
   * Return the getter associated with this variable. If this variable was explicitly defined (is
   * not synthetic) then the getter associated with it will be synthetic.
   *
   * @return the getter associated with this variable
   */
  PropertyAccessorElement get getter;

  /**
   * Return the setter associated with this variable, or `null` if the variable is effectively
   * `final` and therefore does not have a setter associated with it. (This can happen either
   * because the variable is explicitly defined as being `final` or because the variable is
   * induced by an explicit getter that does not have a corresponding setter.) If this variable was
   * explicitly defined (is not synthetic) then the setter associated with it will be synthetic.
   *
   * @return the setter associated with this variable
   */
  PropertyAccessorElement get setter;

  /**
   * Return `true` if this element is a static element. A static element is an element that is
   * not associated with a particular instance, but rather with an entire library or class.
   *
   * @return `true` if this executable element is a static element
   */
  bool get isStatic;
}

/**
 * The interface `ShowElementCombinator` defines the behavior of combinators that cause some
 * of the names in a namespace to be visible (and the rest hidden) when being imported.
 *
 * @coverage dart.engine.element
 */
abstract class ShowElementCombinator implements NamespaceCombinator {
  /**
   * Return the offset of the character immediately following the last character of this node.
   *
   * @return the offset of the character just past this node
   */
  int get end;

  /**
   * Return the offset of the 'show' keyword of this element.
   *
   * @return the offset of the 'show' keyword of this element
   */
  int get offset;

  /**
   * Return an array containing the names that are to be made visible in the importing library if
   * they are defined in the imported library.
   *
   * @return the names from the imported library that are visible in the importing library
   */
  List<String> get shownNames;
}

/**
 * The interface `TopLevelVariableElement` defines the behavior of elements representing a
 * top-level variable.
 *
 * @coverage dart.engine.element
 */
abstract class TopLevelVariableElement implements PropertyInducingElement {
}

/**
 * The interface `TypeParameterElement` defines the behavior of elements representing a type
 * parameter.
 *
 * @coverage dart.engine.element
 */
abstract class TypeParameterElement implements Element {
  /**
   * Return the type representing the bound associated with this parameter, or `null` if this
   * parameter does not have an explicit bound.
   *
   * @return the type representing the bound associated with this parameter
   */
  Type2 get bound;

  /**
   * Return the type defined by this type parameter.
   *
   * @return the type defined by this type parameter
   */
  TypeParameterType get type;
}

/**
 * The interface `UndefinedElement` defines the behavior of pseudo-elements that represent
 * names that are undefined. This situation is not allowed by the language, so objects implementing
 * this interface always represent an error. As a result, most of the normal operations on elements
 * do not make sense and will return useless results.
 *
 * @coverage dart.engine.element
 */
abstract class UndefinedElement implements Element {
}

/**
 * The interface `UriReferencedElement` defines the behavior of objects included into a
 * library using some URI.
 *
 * @coverage dart.engine.element
 */
abstract class UriReferencedElement implements Element {
  /**
   * Return the URI that is used to include this element into the enclosing library, or `null`
   * if this is the defining compilation unit of a library.
   *
   * @return the URI that is used to include this element into the enclosing library
   */
  String get uri;
}

/**
 * The interface `VariableElement` defines the behavior common to elements that represent a
 * variable.
 *
 * @coverage dart.engine.element
 */
abstract class VariableElement implements Element {
  /**
   * Return a synthetic function representing this variable's initializer, or `null` if this
   * variable does not have an initializer. The function will have no parameters. The return type of
   * the function will be the compile-time type of the initialization expression.
   *
   * @return a synthetic function representing this variable's initializer
   */
  FunctionElement get initializer;

  /**
   * Return the declared type of this variable, or `null` if the variable did not have a
   * declared type (such as if it was declared using the keyword 'var').
   *
   * @return the declared type of this variable
   */
  Type2 get type;

  /**
   * Return `true` if this variable was declared with the 'const' modifier.
   *
   * @return `true` if this variable was declared with the 'const' modifier
   */
  bool get isConst;

  /**
   * Return `true` if this variable was declared with the 'final' modifier. Variables that are
   * declared with the 'const' modifier will return `false` even though they are implicitly
   * final.
   *
   * @return `true` if this variable was declared with the 'final' modifier
   */
  bool get isFinal;
}

/**
 * Instances of the class `GeneralizingElementVisitor` implement an element visitor that will
 * recursively visit all of the elements in an element model (like instances of the class
 * [RecursiveElementVisitor]). In addition, when an element of a specific type is visited not
 * only will the visit method for that specific type of element be invoked, but additional methods
 * for the supertypes of that element will also be invoked. For example, using an instance of this
 * class to visit a [MethodElement] will cause the method
 * [visitMethodElement] to be invoked but will also cause the methods
 * [visitExecutableElement] and [visitElement] to be
 * subsequently invoked. This allows visitors to be written that visit all executable elements
 * without needing to override the visit method for each of the specific subclasses of
 * [ExecutableElement].
 *
 * Note, however, that unlike many visitors, element visitors visit objects based on the interfaces
 * implemented by those elements. Because interfaces form a graph structure rather than a tree
 * structure the way classes do, and because it is generally undesirable for an object to be visited
 * more than once, this class flattens the interface graph into a pseudo-tree. In particular, this
 * class treats elements as if the element types were structured in the following way:
 *
 *
 * <pre>
 * Element
 *   ClassElement
 *   CompilationUnitElement
 *   ExecutableElement
 *      ConstructorElement
 *      LocalElement
 *         FunctionElement
 *      MethodElement
 *      PropertyAccessorElement
 *   ExportElement
 *   HtmlElement
 *   ImportElement
 *   LabelElement
 *   LibraryElement
 *   MultiplyDefinedElement
 *   PrefixElement
 *   TypeAliasElement
 *   TypeParameterElement
 *   UndefinedElement
 *   VariableElement
 *      PropertyInducingElement
 *         FieldElement
 *         TopLevelVariableElement
 *      LocalElement
 *         LocalVariableElement
 *         ParameterElement
 *            FieldFormalParameterElement
 * </pre>
 *
 * Subclasses that override a visit method must either invoke the overridden visit method or
 * explicitly invoke the more general visit method. Failure to do so will cause the visit methods
 * for superclasses of the element to not be invoked and will cause the children of the visited node
 * to not be visited.
 *
 * @coverage dart.engine.element
 */
class GeneralizingElementVisitor<R> implements ElementVisitor<R> {
  R visitClassElement(ClassElement element) => visitElement(element);

  R visitCompilationUnitElement(CompilationUnitElement element) => visitElement(element);

  R visitConstructorElement(ConstructorElement element) => visitExecutableElement(element);

  R visitElement(Element element) {
    element.visitChildren(this);
    return null;
  }

  R visitEmbeddedHtmlScriptElement(EmbeddedHtmlScriptElement element) => visitHtmlScriptElement(element);

  R visitExecutableElement(ExecutableElement element) => visitElement(element);

  R visitExportElement(ExportElement element) => visitElement(element);

  R visitExternalHtmlScriptElement(ExternalHtmlScriptElement element) => visitHtmlScriptElement(element);

  R visitFieldElement(FieldElement element) => visitPropertyInducingElement(element);

  R visitFieldFormalParameterElement(FieldFormalParameterElement element) => visitParameterElement(element);

  R visitFunctionElement(FunctionElement element) => visitLocalElement(element);

  R visitFunctionTypeAliasElement(FunctionTypeAliasElement element) => visitElement(element);

  R visitHtmlElement(HtmlElement element) => visitElement(element);

  R visitHtmlScriptElement(HtmlScriptElement element) => visitElement(element);

  R visitImportElement(ImportElement element) => visitElement(element);

  R visitLabelElement(LabelElement element) => visitElement(element);

  R visitLibraryElement(LibraryElement element) => visitElement(element);

  R visitLocalElement(LocalElement element) {
    if (element is LocalVariableElement) {
      return visitVariableElement(element as LocalVariableElement);
    } else if (element is ParameterElement) {
      return visitVariableElement(element as ParameterElement);
    } else if (element is FunctionElement) {
      return visitExecutableElement(element as FunctionElement);
    }
    return null;
  }

  R visitLocalVariableElement(LocalVariableElement element) => visitLocalElement(element);

  R visitMethodElement(MethodElement element) => visitExecutableElement(element);

  R visitMultiplyDefinedElement(MultiplyDefinedElement element) => visitElement(element);

  R visitParameterElement(ParameterElement element) => visitLocalElement(element);

  R visitPrefixElement(PrefixElement element) => visitElement(element);

  R visitPropertyAccessorElement(PropertyAccessorElement element) => visitExecutableElement(element);

  R visitPropertyInducingElement(PropertyInducingElement element) => visitVariableElement(element);

  R visitTopLevelVariableElement(TopLevelVariableElement element) => visitPropertyInducingElement(element);

  R visitTypeParameterElement(TypeParameterElement element) => visitElement(element);

  R visitVariableElement(VariableElement element) => visitElement(element);
}

/**
 * Instances of the class `RecursiveElementVisitor` implement an element visitor that will
 * recursively visit all of the element in an element model. For example, using an instance of this
 * class to visit a [CompilationUnitElement] will also cause all of the types in the
 * compilation unit to be visited.
 *
 * Subclasses that override a visit method must either invoke the overridden visit method or must
 * explicitly ask the visited element to visit its children. Failure to do so will cause the
 * children of the visited element to not be visited.
 *
 * @coverage dart.engine.element
 */
class RecursiveElementVisitor<R> implements ElementVisitor<R> {
  R visitClassElement(ClassElement element) {
    element.visitChildren(this);
    return null;
  }

  R visitCompilationUnitElement(CompilationUnitElement element) {
    element.visitChildren(this);
    return null;
  }

  R visitConstructorElement(ConstructorElement element) {
    element.visitChildren(this);
    return null;
  }

  R visitEmbeddedHtmlScriptElement(EmbeddedHtmlScriptElement element) {
    element.visitChildren(this);
    return null;
  }

  R visitExportElement(ExportElement element) {
    element.visitChildren(this);
    return null;
  }

  R visitExternalHtmlScriptElement(ExternalHtmlScriptElement element) {
    element.visitChildren(this);
    return null;
  }

  R visitFieldElement(FieldElement element) {
    element.visitChildren(this);
    return null;
  }

  R visitFieldFormalParameterElement(FieldFormalParameterElement element) {
    element.visitChildren(this);
    return null;
  }

  R visitFunctionElement(FunctionElement element) {
    element.visitChildren(this);
    return null;
  }

  R visitFunctionTypeAliasElement(FunctionTypeAliasElement element) {
    element.visitChildren(this);
    return null;
  }

  R visitHtmlElement(HtmlElement element) {
    element.visitChildren(this);
    return null;
  }

  R visitImportElement(ImportElement element) {
    element.visitChildren(this);
    return null;
  }

  R visitLabelElement(LabelElement element) {
    element.visitChildren(this);
    return null;
  }

  R visitLibraryElement(LibraryElement element) {
    element.visitChildren(this);
    return null;
  }

  R visitLocalVariableElement(LocalVariableElement element) {
    element.visitChildren(this);
    return null;
  }

  R visitMethodElement(MethodElement element) {
    element.visitChildren(this);
    return null;
  }

  R visitMultiplyDefinedElement(MultiplyDefinedElement element) {
    element.visitChildren(this);
    return null;
  }

  R visitParameterElement(ParameterElement element) {
    element.visitChildren(this);
    return null;
  }

  R visitPrefixElement(PrefixElement element) {
    element.visitChildren(this);
    return null;
  }

  R visitPropertyAccessorElement(PropertyAccessorElement element) {
    element.visitChildren(this);
    return null;
  }

  R visitTopLevelVariableElement(TopLevelVariableElement element) {
    element.visitChildren(this);
    return null;
  }

  R visitTypeParameterElement(TypeParameterElement element) {
    element.visitChildren(this);
    return null;
  }
}

/**
 * Instances of the class `SimpleElementVisitor` implement an element visitor that will do
 * nothing when visiting an element. It is intended to be a superclass for classes that use the
 * visitor pattern primarily as a dispatch mechanism (and hence don't need to recursively visit a
 * whole structure) and that only need to visit a small number of element types.
 *
 * @coverage dart.engine.element
 */
class SimpleElementVisitor<R> implements ElementVisitor<R> {
  R visitClassElement(ClassElement element) => null;

  R visitCompilationUnitElement(CompilationUnitElement element) => null;

  R visitConstructorElement(ConstructorElement element) => null;

  R visitEmbeddedHtmlScriptElement(EmbeddedHtmlScriptElement element) => null;

  R visitExportElement(ExportElement element) => null;

  R visitExternalHtmlScriptElement(ExternalHtmlScriptElement element) => null;

  R visitFieldElement(FieldElement element) => null;

  R visitFieldFormalParameterElement(FieldFormalParameterElement element) => null;

  R visitFunctionElement(FunctionElement element) => null;

  R visitFunctionTypeAliasElement(FunctionTypeAliasElement element) => null;

  R visitHtmlElement(HtmlElement element) => null;

  R visitImportElement(ImportElement element) => null;

  R visitLabelElement(LabelElement element) => null;

  R visitLibraryElement(LibraryElement element) => null;

  R visitLocalVariableElement(LocalVariableElement element) => null;

  R visitMethodElement(MethodElement element) => null;

  R visitMultiplyDefinedElement(MultiplyDefinedElement element) => null;

  R visitParameterElement(ParameterElement element) => null;

  R visitPrefixElement(PrefixElement element) => null;

  R visitPropertyAccessorElement(PropertyAccessorElement element) => null;

  R visitTopLevelVariableElement(TopLevelVariableElement element) => null;

  R visitTypeParameterElement(TypeParameterElement element) => null;
}

/**
 * For AST nodes that could be in both the getter and setter contexts ([IndexExpression]s and
 * [SimpleIdentifier]s), the additional resolved elements are stored in the AST node, in an
 * [AuxiliaryElements]. Since resolved elements are either statically resolved or resolved
 * using propagated type information, this class is a wrapper for a pair of
 * [ExecutableElement]s, not just a single [ExecutableElement].
 */
class AuxiliaryElements {
  /**
   * The element based on propagated type information, or `null` if the AST structure has not
   * been resolved or if this identifier could not be resolved.
   */
  ExecutableElement propagatedElement;

  /**
   * The element associated with this identifier based on static type information, or `null`
   * if the AST structure has not been resolved or if this identifier could not be resolved.
   */
  ExecutableElement staticElement;

  /**
   * Create the [AuxiliaryElements] with a static and propagated [ExecutableElement].
   *
   * @param staticElement the static element
   * @param propagatedElement the propagated element
   */
  AuxiliaryElements(ExecutableElement staticElement, ExecutableElement propagatedElement) {
    this.staticElement = staticElement;
    this.propagatedElement = propagatedElement;
  }
}

/**
 * Instances of the class `ClassElementImpl` implement a `ClassElement`.
 *
 * @coverage dart.engine.element
 */
class ClassElementImpl extends ElementImpl implements ClassElement {
  /**
   * An array containing all of the accessors (getters and setters) contained in this class.
   */
  List<PropertyAccessorElement> _accessors = PropertyAccessorElementImpl.EMPTY_ARRAY;

  /**
   * An array containing all of the constructors contained in this class.
   */
  List<ConstructorElement> _constructors = ConstructorElementImpl.EMPTY_ARRAY;

  /**
   * An array containing all of the fields contained in this class.
   */
  List<FieldElement> _fields = FieldElementImpl.EMPTY_ARRAY;

  /**
   * An array containing all of the mixins that are applied to the class being extended in order to
   * derive the superclass of this class.
   */
  List<InterfaceType> _mixins = InterfaceTypeImpl.EMPTY_ARRAY;

  /**
   * An array containing all of the interfaces that are implemented by this class.
   */
  List<InterfaceType> _interfaces = InterfaceTypeImpl.EMPTY_ARRAY;

  /**
   * An array containing all of the methods contained in this class.
   */
  List<MethodElement> _methods = MethodElementImpl.EMPTY_ARRAY;

  /**
   * The superclass of the class, or `null` if the class does not have an explicit superclass.
   */
  InterfaceType _supertype;

  /**
   * The type defined by the class.
   */
  InterfaceType _type;

  /**
   * An array containing all of the type parameters defined for this class.
   */
  List<TypeParameterElement> _typeParameters = TypeParameterElementImpl.EMPTY_ARRAY;

  /**
   * An empty array of type elements.
   */
  static List<ClassElement> EMPTY_ARRAY = new List<ClassElement>(0);

  /**
   * Initialize a newly created class element to have the given name.
   *
   * @param name the name of this element
   */
  ClassElementImpl(Identifier name) : super.con1(name);

  accept(ElementVisitor visitor) => visitor.visitClassElement(this);

  List<PropertyAccessorElement> get accessors => _accessors;

  List<InterfaceType> get allSupertypes {
    List<InterfaceType> list = new List<InterfaceType>();
    collectAllSupertypes(list);
    return new List.from(list);
  }

  ElementImpl getChild(String identifier) {
    for (PropertyAccessorElement accessor in _accessors) {
      if ((accessor as PropertyAccessorElementImpl).identifier == identifier) {
        return accessor as PropertyAccessorElementImpl;
      }
    }
    for (ConstructorElement constructor in _constructors) {
      if ((constructor as ConstructorElementImpl).identifier == identifier) {
        return constructor as ConstructorElementImpl;
      }
    }
    for (FieldElement field in _fields) {
      if ((field as FieldElementImpl).identifier == identifier) {
        return field as FieldElementImpl;
      }
    }
    for (MethodElement method in _methods) {
      if ((method as MethodElementImpl).identifier == identifier) {
        return method as MethodElementImpl;
      }
    }
    for (TypeParameterElement typeParameter in _typeParameters) {
      if ((typeParameter as TypeParameterElementImpl).identifier == identifier) {
        return typeParameter as TypeParameterElementImpl;
      }
    }
    return null;
  }

  List<ConstructorElement> get constructors => _constructors;

  /**
   * Given some name, this returns the [FieldElement] with the matching name, if there is no
   * such field, then `null` is returned.
   *
   * @param name some name to lookup a field element with
   * @return the matching field element, or `null` if no such element was found
   */
  FieldElement getField(String name) {
    for (FieldElement fieldElement in _fields) {
      if (name == fieldElement.name) {
        return fieldElement;
      }
    }
    return null;
  }

  List<FieldElement> get fields => _fields;

  PropertyAccessorElement getGetter(String getterName) {
    for (PropertyAccessorElement accessor in _accessors) {
      if (accessor.isGetter && accessor.name == getterName) {
        return accessor;
      }
    }
    return null;
  }

  List<InterfaceType> get interfaces => _interfaces;

  ElementKind get kind => ElementKind.CLASS;

  MethodElement getMethod(String methodName) {
    for (MethodElement method in _methods) {
      if (method.name == methodName) {
        return method;
      }
    }
    return null;
  }

  List<MethodElement> get methods => _methods;

  List<InterfaceType> get mixins => _mixins;

  ConstructorElement getNamedConstructor(String name) {
    for (ConstructorElement element in constructors) {
      String elementName = element.name;
      if (elementName != null && elementName == name) {
        return element;
      }
    }
    return null;
  }

  PropertyAccessorElement getSetter(String setterName) {
    if (!setterName.endsWith("=")) {
      setterName += '=';
    }
    for (PropertyAccessorElement accessor in _accessors) {
      if (accessor.isSetter && accessor.name == setterName) {
        return accessor;
      }
    }
    return null;
  }

  InterfaceType get supertype => _supertype;

  InterfaceType get type => _type;

  List<TypeParameterElement> get typeParameters => _typeParameters;

  ConstructorElement get unnamedConstructor {
    for (ConstructorElement element in constructors) {
      String name = element.displayName;
      if (name == null || name.isEmpty) {
        return element;
      }
    }
    return null;
  }

  bool hasNonFinalField() {
    List<ClassElement> classesToVisit = new List<ClassElement>();
    Set<ClassElement> visitedClasses = new Set<ClassElement>();
    classesToVisit.add(this);
    while (!classesToVisit.isEmpty) {
      ClassElement currentElement = classesToVisit.removeAt(0);
      if (visitedClasses.add(currentElement)) {
        for (FieldElement field in currentElement.fields) {
          if (!field.isFinal && !field.isConst && !field.isStatic && !field.isSynthetic) {
            return true;
          }
        }
        for (InterfaceType mixinType in currentElement.mixins) {
          ClassElement mixinElement = mixinType.element;
          classesToVisit.add(mixinElement);
        }
        InterfaceType supertype = currentElement.supertype;
        if (supertype != null) {
          ClassElement superElement = supertype.element;
          if (superElement != null) {
            classesToVisit.add(superElement);
          }
        }
      }
    }
    return false;
  }

  bool hasReferenceToSuper() => hasModifier(Modifier.REFERENCES_SUPER);

  bool get isAbstract => hasModifier(Modifier.ABSTRACT);

  bool get isProxy {
    for (ElementAnnotation annotation in metadata) {
      if (annotation.isProxy) {
        return true;
      }
    }
    return false;
  }

  bool get isTypedef => hasModifier(Modifier.TYPEDEF);

  bool get isValidMixin => hasModifier(Modifier.MIXIN);

  PropertyAccessorElement lookUpGetter(String getterName, LibraryElement library) {
    Set<ClassElement> visitedClasses = new Set<ClassElement>();
    ClassElement currentElement = this;
    while (currentElement != null && !visitedClasses.contains(currentElement)) {
      visitedClasses.add(currentElement);
      PropertyAccessorElement element = currentElement.getGetter(getterName);
      if (element != null && element.isAccessibleIn(library)) {
        return element;
      }
      for (InterfaceType mixin in currentElement.mixins) {
        ClassElement mixinElement = mixin.element;
        if (mixinElement != null) {
          element = mixinElement.getGetter(getterName);
          if (element != null && element.isAccessibleIn(library)) {
            return element;
          }
        }
      }
      InterfaceType supertype = currentElement.supertype;
      if (supertype == null) {
        return null;
      }
      currentElement = supertype.element;
    }
    return null;
  }

  MethodElement lookUpMethod(String methodName, LibraryElement library) {
    Set<ClassElement> visitedClasses = new Set<ClassElement>();
    ClassElement currentElement = this;
    while (currentElement != null && !visitedClasses.contains(currentElement)) {
      visitedClasses.add(currentElement);
      MethodElement element = currentElement.getMethod(methodName);
      if (element != null && element.isAccessibleIn(library)) {
        return element;
      }
      for (InterfaceType mixin in currentElement.mixins) {
        ClassElement mixinElement = mixin.element;
        if (mixinElement != null) {
          element = mixinElement.getMethod(methodName);
          if (element != null && element.isAccessibleIn(library)) {
            return element;
          }
        }
      }
      InterfaceType supertype = currentElement.supertype;
      if (supertype == null) {
        return null;
      }
      currentElement = supertype.element;
    }
    return null;
  }

  PropertyAccessorElement lookUpSetter(String setterName, LibraryElement library) {
    Set<ClassElement> visitedClasses = new Set<ClassElement>();
    ClassElement currentElement = this;
    while (currentElement != null && !visitedClasses.contains(currentElement)) {
      visitedClasses.add(currentElement);
      PropertyAccessorElement element = currentElement.getSetter(setterName);
      if (element != null && element.isAccessibleIn(library)) {
        return element;
      }
      for (InterfaceType mixin in currentElement.mixins) {
        ClassElement mixinElement = mixin.element;
        if (mixinElement != null) {
          element = mixinElement.getSetter(setterName);
          if (element != null && element.isAccessibleIn(library)) {
            return element;
          }
        }
      }
      InterfaceType supertype = currentElement.supertype;
      if (supertype == null) {
        return null;
      }
      currentElement = supertype.element;
    }
    return null;
  }

  /**
   * Set whether this class is abstract to correspond to the given value.
   *
   * @param isAbstract `true` if the class is abstract
   */
  void set abstract(bool isAbstract) {
    setModifier(Modifier.ABSTRACT, isAbstract);
  }

  /**
   * Set the accessors contained in this class to the given accessors.
   *
   * @param accessors the accessors contained in this class
   */
  void set accessors(List<PropertyAccessorElement> accessors) {
    for (PropertyAccessorElement accessor in accessors) {
      (accessor as PropertyAccessorElementImpl).enclosingElement = this;
    }
    this._accessors = accessors;
  }

  /**
   * Set the constructors contained in this class to the given constructors.
   *
   * @param constructors the constructors contained in this class
   */
  void set constructors(List<ConstructorElement> constructors) {
    for (ConstructorElement constructor in constructors) {
      (constructor as ConstructorElementImpl).enclosingElement = this;
    }
    this._constructors = constructors;
  }

  /**
   * Set the fields contained in this class to the given fields.
   *
   * @param fields the fields contained in this class
   */
  void set fields(List<FieldElement> fields) {
    for (FieldElement field in fields) {
      (field as FieldElementImpl).enclosingElement = this;
    }
    this._fields = fields;
  }

  /**
   * Set whether this class references 'super' to the given value.
   *
   * @param isReferencedSuper `true` references 'super'
   */
  void set hasReferenceToSuper2(bool isReferencedSuper) {
    setModifier(Modifier.REFERENCES_SUPER, isReferencedSuper);
  }

  /**
   * Set the interfaces that are implemented by this class to the given types.
   *
   * @param the interfaces that are implemented by this class
   */
  void set interfaces(List<InterfaceType> interfaces) {
    this._interfaces = interfaces;
  }

  /**
   * Set the methods contained in this class to the given methods.
   *
   * @param methods the methods contained in this class
   */
  void set methods(List<MethodElement> methods) {
    for (MethodElement method in methods) {
      (method as MethodElementImpl).enclosingElement = this;
    }
    this._methods = methods;
  }

  /**
   * Set the mixins that are applied to the class being extended in order to derive the superclass
   * of this class to the given types.
   *
   * @param mixins the mixins that are applied to derive the superclass of this class
   */
  void set mixins(List<InterfaceType> mixins) {
    this._mixins = mixins;
  }

  /**
   * Set the superclass of the class to the given type.
   *
   * @param supertype the superclass of the class
   */
  void set supertype(InterfaceType supertype) {
    this._supertype = supertype;
  }

  /**
   * Set the type defined by the class to the given type.
   *
   * @param type the type defined by the class
   */
  void set type(InterfaceType type) {
    this._type = type;
  }

  /**
   * Set whether this class is defined by a typedef construct to correspond to the given value.
   *
   * @param isTypedef `true` if the class is defined by a typedef construct
   */
  void set typedef(bool isTypedef) {
    setModifier(Modifier.TYPEDEF, isTypedef);
  }

  /**
   * Set the type parameters defined for this class to the given type parameters.
   *
   * @param typeParameters the type parameters defined for this class
   */
  void set typeParameters(List<TypeParameterElement> typeParameters) {
    for (TypeParameterElement typeParameter in typeParameters) {
      (typeParameter as TypeParameterElementImpl).enclosingElement = this;
    }
    this._typeParameters = typeParameters;
  }

  /**
   * Set whether this class is a valid mixin to correspond to the given value.
   *
   * @param isValidMixin `true` if this class can be used as a mixin
   */
  void set validMixin(bool isValidMixin) {
    setModifier(Modifier.MIXIN, isValidMixin);
  }

  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChildren(_accessors, visitor);
    safelyVisitChildren(_constructors, visitor);
    safelyVisitChildren(_fields, visitor);
    safelyVisitChildren(_methods, visitor);
    safelyVisitChildren(_typeParameters, visitor);
  }

  void appendTo(JavaStringBuilder builder) {
    String name = displayName;
    if (name == null) {
      builder.append("{unnamed class}");
    } else {
      builder.append(name);
    }
    int variableCount = _typeParameters.length;
    if (variableCount > 0) {
      builder.append("<");
      for (int i = 0; i < variableCount; i++) {
        if (i > 0) {
          builder.append(", ");
        }
        (_typeParameters[i] as TypeParameterElementImpl).appendTo(builder);
      }
      builder.append(">");
    }
  }

  void collectAllSupertypes(List<InterfaceType> supertypes) {
    List<InterfaceType> typesToVisit = new List<InterfaceType>();
    List<ClassElement> visitedClasses = new List<ClassElement>();
    typesToVisit.add(this.type);
    while (!typesToVisit.isEmpty) {
      InterfaceType currentType = typesToVisit.removeAt(0);
      ClassElement currentElement = currentType.element;
      if (!visitedClasses.contains(currentElement)) {
        visitedClasses.add(currentElement);
        if (currentType != this.type) {
          supertypes.add(currentType);
        }
        InterfaceType supertype = currentType.superclass;
        if (supertype != null) {
          typesToVisit.add(supertype);
        }
        for (InterfaceType type in currentElement.interfaces) {
          typesToVisit.add(type);
        }
        for (InterfaceType type in currentElement.mixins) {
          ClassElement element = type.element;
          if (!visitedClasses.contains(element)) {
            supertypes.add(type);
          }
        }
      }
    }
  }
}

/**
 * Instances of the class `CompilationUnitElementImpl` implement a
 * [CompilationUnitElement].
 *
 * @coverage dart.engine.element
 */
class CompilationUnitElementImpl extends ElementImpl implements CompilationUnitElement {
  /**
   * An empty array of compilation unit elements.
   */
  static List<CompilationUnitElement> EMPTY_ARRAY = new List<CompilationUnitElement>(0);

  /**
   * An array containing all of the top-level accessors (getters and setters) contained in this
   * compilation unit.
   */
  List<PropertyAccessorElement> _accessors = PropertyAccessorElementImpl.EMPTY_ARRAY;

  /**
   * An array containing all of the top-level functions contained in this compilation unit.
   */
  List<FunctionElement> _functions = FunctionElementImpl.EMPTY_ARRAY;

  /**
   * An array containing all of the variables contained in this compilation unit.
   */
  List<TopLevelVariableElement> _variables = TopLevelVariableElementImpl.EMPTY_ARRAY;

  /**
   * The source that corresponds to this compilation unit.
   */
  Source _source;

  /**
   * An array containing all of the function type aliases contained in this compilation unit.
   */
  List<FunctionTypeAliasElement> _typeAliases = FunctionTypeAliasElementImpl.EMPTY_ARRAY;

  /**
   * An array containing all of the types contained in this compilation unit.
   */
  List<ClassElement> _types = ClassElementImpl.EMPTY_ARRAY;

  /**
   * The URI that is specified by the "part" directive in the enclosing library, or `null` if
   * this is the defining compilation unit of a library.
   */
  String _uri;

  /**
   * Initialize a newly created compilation unit element to have the given name.
   *
   * @param name the name of this element
   */
  CompilationUnitElementImpl(String name) : super.con2(name, -1);

  accept(ElementVisitor visitor) => visitor.visitCompilationUnitElement(this);

  bool operator ==(Object object) => object != null && runtimeType == object.runtimeType && _source == (object as CompilationUnitElementImpl).source;

  List<PropertyAccessorElement> get accessors => _accessors;

  ElementImpl getChild(String identifier) {
    for (PropertyAccessorElement accessor in _accessors) {
      if ((accessor as PropertyAccessorElementImpl).identifier == identifier) {
        return accessor as PropertyAccessorElementImpl;
      }
    }
    for (VariableElement variable in _variables) {
      if ((variable as VariableElementImpl).identifier == identifier) {
        return variable as VariableElementImpl;
      }
    }
    for (ExecutableElement function in _functions) {
      if ((function as ExecutableElementImpl).identifier == identifier) {
        return function as ExecutableElementImpl;
      }
    }
    for (FunctionTypeAliasElement typeAlias in _typeAliases) {
      if ((typeAlias as FunctionTypeAliasElementImpl).identifier == identifier) {
        return typeAlias as FunctionTypeAliasElementImpl;
      }
    }
    for (ClassElement type in _types) {
      if ((type as ClassElementImpl).identifier == identifier) {
        return type as ClassElementImpl;
      }
    }
    return null;
  }

  LibraryElement get enclosingElement => super.enclosingElement as LibraryElement;

  List<FunctionElement> get functions => _functions;

  List<FunctionTypeAliasElement> get functionTypeAliases => _typeAliases;

  ElementKind get kind => ElementKind.COMPILATION_UNIT;

  Source get source => _source;

  List<TopLevelVariableElement> get topLevelVariables => _variables;

  ClassElement getType(String className) {
    for (ClassElement type in _types) {
      if (type.name == className) {
        return type;
      }
    }
    return null;
  }

  List<ClassElement> get types => _types;

  String get uri => _uri;

  int get hashCode => _source.hashCode;

  /**
   * Set the top-level accessors (getters and setters) contained in this compilation unit to the
   * given accessors.
   *
   * @param the top-level accessors (getters and setters) contained in this compilation unit
   */
  void set accessors(List<PropertyAccessorElement> accessors) {
    for (PropertyAccessorElement accessor in accessors) {
      (accessor as PropertyAccessorElementImpl).enclosingElement = this;
    }
    this._accessors = accessors;
  }

  /**
   * Set the top-level functions contained in this compilation unit to the given functions.
   *
   * @param functions the top-level functions contained in this compilation unit
   */
  void set functions(List<FunctionElement> functions) {
    for (FunctionElement function in functions) {
      (function as FunctionElementImpl).enclosingElement = this;
    }
    this._functions = functions;
  }

  /**
   * Set the source that corresponds to this compilation unit to the given source.
   *
   * @param source the source that corresponds to this compilation unit
   */
  void set source(Source source) {
    this._source = source;
  }

  /**
   * Set the top-level variables contained in this compilation unit to the given variables.
   *
   * @param variables the top-level variables contained in this compilation unit
   */
  void set topLevelVariables(List<TopLevelVariableElement> variables) {
    for (TopLevelVariableElement field in variables) {
      (field as TopLevelVariableElementImpl).enclosingElement = this;
    }
    this._variables = variables;
  }

  /**
   * Set the function type aliases contained in this compilation unit to the given type aliases.
   *
   * @param typeAliases the function type aliases contained in this compilation unit
   */
  void set typeAliases(List<FunctionTypeAliasElement> typeAliases) {
    for (FunctionTypeAliasElement typeAlias in typeAliases) {
      (typeAlias as FunctionTypeAliasElementImpl).enclosingElement = this;
    }
    this._typeAliases = typeAliases;
  }

  /**
   * Set the types contained in this compilation unit to the given types.
   *
   * @param types types contained in this compilation unit
   */
  void set types(List<ClassElement> types) {
    for (ClassElement type in types) {
      (type as ClassElementImpl).enclosingElement = this;
    }
    this._types = types;
  }

  /**
   * Set the URI that is specified by the "part" directive in the enclosing library.
   *
   * @param uri the URI that is specified by the "part" directive in the enclosing library.
   */
  void set uri(String uri) {
    this._uri = uri;
  }

  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChildren(_accessors, visitor);
    safelyVisitChildren(_functions, visitor);
    safelyVisitChildren(_typeAliases, visitor);
    safelyVisitChildren(_types, visitor);
    safelyVisitChildren(_variables, visitor);
  }

  void appendTo(JavaStringBuilder builder) {
    if (_source == null) {
      builder.append("{compilation unit}");
    } else {
      builder.append(_source.fullName);
    }
  }

  String get identifier => source.encoding;
}

/**
 * Instances of the class `ConstFieldElementImpl` implement a `FieldElement` for a
 * 'const' field that has an initializer.
 */
class ConstFieldElementImpl extends FieldElementImpl {
  /**
   * The result of evaluating this variable's initializer.
   */
  EvaluationResultImpl _result;

  /**
   * Initialize a newly created field element to have the given name.
   *
   * @param name the name of this element
   */
  ConstFieldElementImpl(Identifier name) : super.con1(name);

  EvaluationResultImpl get evaluationResult => _result;

  void set evaluationResult(EvaluationResultImpl result) {
    this._result = result;
  }
}

/**
 * Instances of the class `ConstLocalVariableElementImpl` implement a
 * `LocalVariableElement` for a local 'const' variable that has an initializer.
 *
 * @coverage dart.engine.element
 */
class ConstLocalVariableElementImpl extends LocalVariableElementImpl {
  /**
   * The result of evaluating this variable's initializer.
   */
  EvaluationResultImpl _result;

  /**
   * Initialize a newly created local variable element to have the given name.
   *
   * @param name the name of this element
   */
  ConstLocalVariableElementImpl(Identifier name) : super(name);

  EvaluationResultImpl get evaluationResult => _result;

  void set evaluationResult(EvaluationResultImpl result) {
    this._result = result;
  }
}

/**
 * Instances of the class `ConstTopLevelVariableElementImpl` implement a
 * `TopLevelVariableElement` for a top-level 'const' variable that has an initializer.
 */
class ConstTopLevelVariableElementImpl extends TopLevelVariableElementImpl {
  /**
   * The result of evaluating this variable's initializer.
   */
  EvaluationResultImpl _result;

  /**
   * Initialize a newly created top-level variable element to have the given name.
   *
   * @param name the name of this element
   */
  ConstTopLevelVariableElementImpl(Identifier name) : super.con1(name);

  EvaluationResultImpl get evaluationResult => _result;

  void set evaluationResult(EvaluationResultImpl result) {
    this._result = result;
  }
}

/**
 * Instances of the class `ConstructorElementImpl` implement a `ConstructorElement`.
 *
 * @coverage dart.engine.element
 */
class ConstructorElementImpl extends ExecutableElementImpl implements ConstructorElement {
  /**
   * An empty array of constructor elements.
   */
  static List<ConstructorElement> EMPTY_ARRAY = new List<ConstructorElement>(0);

  /**
   * The constructor to which this constructor is redirecting.
   */
  ConstructorElement _redirectedConstructor;

  /**
   * Initialize a newly created constructor element to have the given name.
   *
   * @param name the name of this element
   */
  ConstructorElementImpl(Identifier name) : super.con1(name);

  accept(ElementVisitor visitor) => visitor.visitConstructorElement(this);

  ClassElement get enclosingElement => super.enclosingElement as ClassElement;

  ElementKind get kind => ElementKind.CONSTRUCTOR;

  ConstructorElement get redirectedConstructor => _redirectedConstructor;

  bool get isConst => hasModifier(Modifier.CONST);

  bool get isDefaultConstructor {
    String name = this.name;
    if (name != null && name.length != 0) {
      return false;
    }
    for (ParameterElement parameter in parameters) {
      if (identical(parameter.parameterKind, ParameterKind.REQUIRED)) {
        return false;
      }
    }
    return true;
  }

  bool get isFactory => hasModifier(Modifier.FACTORY);

  bool get isStatic => false;

  /**
   * Set whether this constructor represents a 'const' constructor to the given value.
   *
   * @param isConst `true` if this constructor represents a 'const' constructor
   */
  void set const2(bool isConst) {
    setModifier(Modifier.CONST, isConst);
  }

  /**
   * Set whether this constructor represents a factory method to the given value.
   *
   * @param isFactory `true` if this constructor represents a factory method
   */
  void set factory(bool isFactory) {
    setModifier(Modifier.FACTORY, isFactory);
  }

  /**
   * Sets the constructor to which this constructor is redirecting.
   *
   * @param redirectedConstructor the constructor to which this constructor is redirecting
   */
  void set redirectedConstructor(ConstructorElement redirectedConstructor) {
    this._redirectedConstructor = redirectedConstructor;
  }

  void appendTo(JavaStringBuilder builder) {
    builder.append(enclosingElement.displayName);
    String name = displayName;
    if (name != null && !name.isEmpty) {
      builder.append(".");
      builder.append(name);
    }
    super.appendTo(builder);
  }
}

/**
 * Instances of the class `DefaultFieldFormalParameterElementImpl` implement a
 * `FieldFormalParameterElementImpl` for parameters that have an initializer.
 *
 * @coverage dart.engine.element
 */
class DefaultFieldFormalParameterElementImpl extends FieldFormalParameterElementImpl {
  /**
   * The result of evaluating this variable's initializer.
   */
  EvaluationResultImpl _result;

  /**
   * Initialize a newly created parameter element to have the given name.
   *
   * @param name the name of this element
   */
  DefaultFieldFormalParameterElementImpl(Identifier name) : super(name);

  EvaluationResultImpl get evaluationResult => _result;

  void set evaluationResult(EvaluationResultImpl result) {
    this._result = result;
  }
}

/**
 * Instances of the class `DefaultParameterElementImpl` implement a `ParameterElement`
 * for parameters that have an initializer.
 *
 * @coverage dart.engine.element
 */
class DefaultParameterElementImpl extends ParameterElementImpl {
  /**
   * The result of evaluating this variable's initializer.
   */
  EvaluationResultImpl _result;

  /**
   * Initialize a newly created parameter element to have the given name.
   *
   * @param name the name of this element
   */
  DefaultParameterElementImpl(Identifier name) : super.con1(name);

  EvaluationResultImpl get evaluationResult => _result;

  void set evaluationResult(EvaluationResultImpl result) {
    this._result = result;
  }
}

/**
 * Instances of the class `DynamicElementImpl` represent the synthetic element representing
 * the declaration of the type `dynamic`.
 *
 * @coverage dart.engine.element
 */
class DynamicElementImpl extends ElementImpl {
  /**
   * Return the unique instance of this class.
   *
   * @return the unique instance of this class
   */
  static DynamicElementImpl get instance => DynamicTypeImpl.instance.element as DynamicElementImpl;

  /**
   * The type defined by this element.
   */
  DynamicTypeImpl type;

  /**
   * Initialize a newly created instance of this class. Instances of this class should <b>not</b> be
   * created except as part of creating the type associated with this element. The single instance
   * of this class should be accessed through the method [getInstance].
   */
  DynamicElementImpl() : super.con2(Keyword.DYNAMIC.syntax, -1) {
    setModifier(Modifier.SYNTHETIC, true);
  }

  accept(ElementVisitor visitor) => null;

  ElementKind get kind => ElementKind.DYNAMIC;
}

/**
 * Instances of the class `ElementAnnotationImpl` implement an [ElementAnnotation].
 *
 * @coverage dart.engine.element
 */
class ElementAnnotationImpl implements ElementAnnotation {
  /**
   * The element representing the field, variable, or constructor being used as an annotation.
   */
  Element _element;

  /**
   * An empty array of annotations.
   */
  static List<ElementAnnotationImpl> EMPTY_ARRAY = new List<ElementAnnotationImpl>(0);

  /**
   * The name of the class used to mark an element as being deprecated.
   */
  static String _DEPRECATED_CLASS_NAME = "Deprecated";

  /**
   * The name of the top-level variable used to mark an element as being deprecated.
   */
  static String _DEPRECATED_VARIABLE_NAME = "deprecated";

  /**
   * The name of the top-level variable used to mark a method as being expected to override an
   * inherited method.
   */
  static String _OVERRIDE_VARIABLE_NAME = "override";

  /**
   * The name of the top-level variable used to mark a class as implementing a proxy object.
   */
  static String _PROXY_VARIABLE_NAME = "proxy";

  /**
   * Initialize a newly created annotation.
   *
   * @param element the element representing the field, variable, or constructor being used as an
   *          annotation
   */
  ElementAnnotationImpl(Element element) {
    this._element = element;
  }

  Element get element => _element;

  bool get isDeprecated {
    if (_element != null) {
      LibraryElement library = _element.library;
      if (library != null && library.isDartCore) {
        if (_element is ConstructorElement) {
          ConstructorElement constructorElement = _element as ConstructorElement;
          if (constructorElement.enclosingElement.name == _DEPRECATED_CLASS_NAME) {
            return true;
          }
        } else if (_element is PropertyAccessorElement && _element.name == _DEPRECATED_VARIABLE_NAME) {
          return true;
        }
      }
    }
    return false;
  }

  bool get isOverride {
    if (_element != null) {
      LibraryElement library = _element.library;
      if (library != null && library.isDartCore) {
        if (_element is PropertyAccessorElement && _element.name == _OVERRIDE_VARIABLE_NAME) {
          return true;
        }
      }
    }
    return false;
  }

  bool get isProxy {
    if (_element != null) {
      LibraryElement library = _element.library;
      if (library != null && library.isDartCore) {
        if (_element is PropertyAccessorElement && _element.name == _PROXY_VARIABLE_NAME) {
          return true;
        }
      }
    }
    return false;
  }

  String toString() => "@${_element.toString()}";
}

/**
 * The abstract class `ElementImpl` implements the behavior common to objects that implement
 * an [Element].
 *
 * @coverage dart.engine.element
 */
abstract class ElementImpl implements Element {
  /**
   * The enclosing element of this element, or `null` if this element is at the root of the
   * element structure.
   */
  ElementImpl _enclosingElement;

  /**
   * The name of this element.
   */
  String _name;

  /**
   * The offset of the name of this element in the file that contains the declaration of this
   * element.
   */
  int _nameOffset = 0;

  /**
   * A bit-encoded form of the modifiers associated with this element.
   */
  int _modifiers = 0;

  /**
   * An array containing all of the metadata associated with this element.
   */
  List<ElementAnnotation> _metadata = ElementAnnotationImpl.EMPTY_ARRAY;

  /**
   * A cached copy of the calculated hashCode for this element.
   */
  int _cachedHashCode = 0;

  /**
   * Initialize a newly created element to have the given name.
   *
   * @param name the name of this element
   */
  ElementImpl.con1(Identifier name) : this.con2(name == null ? "" : name.name, name == null ? -1 : name.offset);

  /**
   * Initialize a newly created element to have the given name.
   *
   * @param name the name of this element
   * @param nameOffset the offset of the name of this element in the file that contains the
   *          declaration of this element
   */
  ElementImpl.con2(String name, int nameOffset) {
    this._name = StringUtilities.intern(name);
    this._nameOffset = nameOffset;
  }

  String computeDocumentationComment() {
    AnalysisContext context = this.context;
    if (context == null) {
      return null;
    }
    return context.computeDocumentationComment(this);
  }

  bool operator ==(Object object) {
    if (identical(this, object)) {
      return true;
    }
    if (object == null || hashCode != object.hashCode) {
      return false;
    }
    return object.runtimeType == runtimeType && (object as Element).location == location;
  }

  Element getAncestor(Type elementClass) {
    Element ancestor = _enclosingElement;
    while (ancestor != null && !isInstanceOf(ancestor, elementClass)) {
      ancestor = ancestor.enclosingElement;
    }
    return ancestor as Element;
  }

  /**
   * Return the child of this element that is uniquely identified by the given identifier, or
   * `null` if there is no such child.
   *
   * @param identifier the identifier used to select a child
   * @return the child of this element with the given identifier
   */
  ElementImpl getChild(String identifier) => null;

  AnalysisContext get context {
    if (_enclosingElement == null) {
      return null;
    }
    return _enclosingElement.context;
  }

  String get displayName => _name;

  Element get enclosingElement => _enclosingElement;

  LibraryElement get library => getAncestor(LibraryElement);

  ElementLocation get location => new ElementLocationImpl.con1(this);

  List<ElementAnnotation> get metadata => _metadata;

  String get name => _name;

  int get nameOffset => _nameOffset;

  Source get source {
    if (_enclosingElement == null) {
      return null;
    }
    return _enclosingElement.source;
  }

  int get hashCode {
    if (_cachedHashCode == 0) {
      _cachedHashCode = location.hashCode;
    }
    return _cachedHashCode;
  }

  bool isAccessibleIn(LibraryElement library) {
    if (Identifier.isPrivateName(_name)) {
      return library == this.library;
    }
    return true;
  }

  bool get isDeprecated {
    for (ElementAnnotation annotation in _metadata) {
      if (annotation.isDeprecated) {
        return true;
      }
    }
    return false;
  }

  bool get isSynthetic => hasModifier(Modifier.SYNTHETIC);

  /**
   * Set the metadata associate with this element to the given array of annotations.
   *
   * @param metadata the metadata to be associated with this element
   */
  void set metadata(List<ElementAnnotation> metadata) {
    this._metadata = metadata;
  }

  /**
   * Set the offset of the name of this element in the file that contains the declaration of this
   * element to the given value. This is normally done via the constructor, but this method is
   * provided to support unnamed constructors.
   *
   * @param nameOffset the offset to the beginning of the name
   */
  void set nameOffset(int nameOffset) {
    this._nameOffset = nameOffset;
  }

  /**
   * Set whether this element is synthetic to correspond to the given value.
   *
   * @param isSynthetic `true` if the element is synthetic
   */
  void set synthetic(bool isSynthetic) {
    setModifier(Modifier.SYNTHETIC, isSynthetic);
  }

  String toString() {
    JavaStringBuilder builder = new JavaStringBuilder();
    appendTo(builder);
    return builder.toString();
  }

  void visitChildren(ElementVisitor visitor) {
  }

  /**
   * Append a textual representation of this type to the given builder.
   *
   * @param builder the builder to which the text is to be appended
   */
  void appendTo(JavaStringBuilder builder) {
    if (_name == null) {
      builder.append("<unnamed ");
      builder.append(runtimeType.toString());
      builder.append(">");
    } else {
      builder.append(_name);
    }
  }

  /**
   * Return an identifier that uniquely identifies this element among the children of this element's
   * parent.
   *
   * @return an identifier that uniquely identifies this element relative to its parent
   */
  String get identifier => name;

  /**
   * Return `true` if this element has the given modifier associated with it.
   *
   * @param modifier the modifier being tested for
   * @return `true` if this element has the given modifier associated with it
   */
  bool hasModifier(Modifier modifier) => BooleanArray.get(_modifiers, modifier);

  /**
   * If the given child is not `null`, use the given visitor to visit it.
   *
   * @param child the child to be visited
   * @param visitor the visitor to be used to visit the child
   */
  void safelyVisitChild(Element child, ElementVisitor visitor) {
    if (child != null) {
      child.accept(visitor);
    }
  }

  /**
   * Use the given visitor to visit all of the children in the given array.
   *
   * @param children the children to be visited
   * @param visitor the visitor being used to visit the children
   */
  void safelyVisitChildren(List<Element> children, ElementVisitor visitor) {
    if (children != null) {
      for (Element child in children) {
        child.accept(visitor);
      }
    }
  }

  /**
   * Set the enclosing element of this element to the given element.
   *
   * @param element the enclosing element of this element
   */
  void set enclosingElement(Element element) {
    _enclosingElement = element as ElementImpl;
  }

  /**
   * Set whether the given modifier is associated with this element to correspond to the given
   * value.
   *
   * @param modifier the modifier to be set
   * @param value `true` if the modifier is to be associated with this element
   */
  void setModifier(Modifier modifier, bool value) {
    _modifiers = BooleanArray.set(_modifiers, modifier, value);
  }
}

/**
 * Instances of the class `ElementLocationImpl` implement an [ElementLocation].
 *
 * @coverage dart.engine.element
 */
class ElementLocationImpl implements ElementLocation {
  /**
   * The path to the element whose location is represented by this object.
   */
  List<String> components;

  /**
   * The character used to separate components in the encoded form.
   */
  static int _SEPARATOR_CHAR = 0x3B;

  /**
   * Initialize a newly created location to represent the given element.
   *
   * @param element the element whose location is being represented
   */
  ElementLocationImpl.con1(Element element) {
    List<String> components = new List<String>();
    Element ancestor = element;
    while (ancestor != null) {
      components.insert(0, (ancestor as ElementImpl).identifier);
      ancestor = ancestor.enclosingElement;
    }
    this.components = new List.from(components);
  }

  /**
   * Initialize a newly created location from the given encoded form.
   *
   * @param encoding the encoded form of a location
   */
  ElementLocationImpl.con2(String encoding) {
    this.components = decode(encoding);
  }

  bool operator ==(Object object) {
    if (identical(this, object)) {
      return true;
    }
    if (object is! ElementLocationImpl) {
      return false;
    }
    ElementLocationImpl location = object as ElementLocationImpl;
    List<String> otherComponents = location.components;
    int length = components.length;
    if (otherComponents.length != length) {
      return false;
    }
    for (int i = length - 1; i >= 2; i--) {
      if (components[i] != otherComponents[i]) {
        return false;
      }
    }
    if (length > 1 && !equalSourceComponents(components[1], otherComponents[1])) {
      return false;
    }
    if (length > 0 && !equalSourceComponents(components[0], otherComponents[0])) {
      return false;
    }
    return true;
  }

  String get encoding {
    JavaStringBuilder builder = new JavaStringBuilder();
    int length = components.length;
    for (int i = 0; i < length; i++) {
      if (i > 0) {
        builder.appendChar(_SEPARATOR_CHAR);
      }
      encode(builder, components[i]);
    }
    return builder.toString();
  }

  int get hashCode {
    int result = 1;
    for (int i = 0; i < components.length; i++) {
      String component = components[i];
      int componentHash;
      if (i <= 1) {
        componentHash = hashSourceComponent(component);
      } else {
        componentHash = component.hashCode;
      }
      result = 31 * result + componentHash;
    }
    return result;
  }

  String toString() => encoding;

  /**
   * Decode the encoded form of a location into an array of components.
   *
   * @param encoding the encoded form of a location
   * @return the components that were encoded
   */
  List<String> decode(String encoding) {
    List<String> components = new List<String>();
    JavaStringBuilder builder = new JavaStringBuilder();
    int index = 0;
    int length = encoding.length;
    while (index < length) {
      int currentChar = encoding.codeUnitAt(index);
      if (currentChar == _SEPARATOR_CHAR) {
        if (index + 1 < length && encoding.codeUnitAt(index + 1) == _SEPARATOR_CHAR) {
          builder.appendChar(_SEPARATOR_CHAR);
          index += 2;
        } else {
          components.add(builder.toString());
          builder.length = 0;
          index++;
        }
      } else {
        builder.appendChar(currentChar);
        index++;
      }
    }
    if (builder.length > 0) {
      components.add(builder.toString());
    }
    return new List.from(components);
  }

  /**
   * Append an encoded form of the given component to the given builder.
   *
   * @param builder the builder to which the encoded component is to be appended
   * @param component the component to be appended to the builder
   */
  void encode(JavaStringBuilder builder, String component) {
    int length = component.length;
    for (int i = 0; i < length; i++) {
      int currentChar = component.codeUnitAt(i);
      if (currentChar == _SEPARATOR_CHAR) {
        builder.appendChar(_SEPARATOR_CHAR);
      }
      builder.appendChar(currentChar);
    }
  }

  /**
   * Return `true` if the given components, when interpreted to be encoded sources with a
   * leading source type indicator, are equal when the source type's are ignored.
   *
   * @param left the left component being compared
   * @param right the right component being compared
   * @return `true` if the given components are equal when the source type's are ignored
   */
  bool equalSourceComponents(String left, String right) {
    if (left == null) {
      return right == null;
    } else if (right == null) {
      return false;
    }
    int leftLength = left.length;
    int rightLength = right.length;
    if (leftLength != rightLength) {
      return false;
    } else if (leftLength <= 1 || rightLength <= 1) {
      return left == right;
    }
    return javaStringRegionMatches(left, 1, right, 1, leftLength - 1);
  }

  /**
   * Return the hash code of the given encoded source component, ignoring the source type indicator.
   *
   * @param sourceComponent the component to compute a hash code
   * @return the hash code of the given encoded source component
   */
  int hashSourceComponent(String sourceComponent) {
    if (sourceComponent.length <= 1) {
      return sourceComponent.hashCode;
    }
    return sourceComponent.substring(1).hashCode;
  }
}

/**
 * Instances of the class `EmbeddedHtmlScriptElementImpl` implement an
 * [EmbeddedHtmlScriptElement].
 *
 * @coverage dart.engine.element
 */
class EmbeddedHtmlScriptElementImpl extends HtmlScriptElementImpl implements EmbeddedHtmlScriptElement {
  /**
   * The library defined by the script tag's content.
   */
  LibraryElement _scriptLibrary;

  /**
   * Initialize a newly created script element to have the specified tag name and offset.
   *
   * @param node the XML node from which this element is derived (not `null`)
   */
  EmbeddedHtmlScriptElementImpl(XmlTagNode node) : super(node);

  accept(ElementVisitor visitor) => visitor.visitEmbeddedHtmlScriptElement(this);

  ElementKind get kind => ElementKind.EMBEDDED_HTML_SCRIPT;

  LibraryElement get scriptLibrary => _scriptLibrary;

  /**
   * Set the script library defined by the script tag's content.
   *
   * @param scriptLibrary the library or `null` if none
   */
  void set scriptLibrary(LibraryElementImpl scriptLibrary) {
    scriptLibrary.enclosingElement = this;
    this._scriptLibrary = scriptLibrary;
  }

  void visitChildren(ElementVisitor visitor) {
    safelyVisitChild(_scriptLibrary, visitor);
  }
}

/**
 * The abstract class `ExecutableElementImpl` implements the behavior common to
 * `ExecutableElement`s.
 *
 * @coverage dart.engine.element
 */
abstract class ExecutableElementImpl extends ElementImpl implements ExecutableElement {
  /**
   * An array containing all of the functions defined within this executable element.
   */
  List<FunctionElement> _functions = FunctionElementImpl.EMPTY_ARRAY;

  /**
   * An array containing all of the labels defined within this executable element.
   */
  List<LabelElement> _labels = LabelElementImpl.EMPTY_ARRAY;

  /**
   * An array containing all of the local variables defined within this executable element.
   */
  List<LocalVariableElement> _localVariables = LocalVariableElementImpl.EMPTY_ARRAY;

  /**
   * An array containing all of the parameters defined by this executable element.
   */
  List<ParameterElement> _parameters = ParameterElementImpl.EMPTY_ARRAY;

  /**
   * The return type defined by this executable element.
   */
  Type2 _returnType;

  /**
   * The type of function defined by this executable element.
   */
  FunctionType _type;

  /**
   * An empty array of executable elements.
   */
  static List<ExecutableElement> EMPTY_ARRAY = new List<ExecutableElement>(0);

  /**
   * Initialize a newly created executable element to have the given name.
   *
   * @param name the name of this element
   */
  ExecutableElementImpl.con1(Identifier name) : super.con1(name);

  /**
   * Initialize a newly created executable element to have the given name.
   *
   * @param name the name of this element
   * @param nameOffset the offset of the name of this element in the file that contains the
   *          declaration of this element
   */
  ExecutableElementImpl.con2(String name, int nameOffset) : super.con2(name, nameOffset);

  ElementImpl getChild(String identifier) {
    for (ExecutableElement function in _functions) {
      if ((function as ExecutableElementImpl).identifier == identifier) {
        return function as ExecutableElementImpl;
      }
    }
    for (LabelElement label in _labels) {
      if ((label as LabelElementImpl).identifier == identifier) {
        return label as LabelElementImpl;
      }
    }
    for (VariableElement variable in _localVariables) {
      if ((variable as VariableElementImpl).identifier == identifier) {
        return variable as VariableElementImpl;
      }
    }
    for (ParameterElement parameter in _parameters) {
      if ((parameter as ParameterElementImpl).identifier == identifier) {
        return parameter as ParameterElementImpl;
      }
    }
    return null;
  }

  List<FunctionElement> get functions => _functions;

  List<LabelElement> get labels => _labels;

  List<LocalVariableElement> get localVariables => _localVariables;

  List<ParameterElement> get parameters => _parameters;

  Type2 get returnType => _returnType;

  FunctionType get type => _type;

  bool get isOperator => false;

  /**
   * Set the functions defined within this executable element to the given functions.
   *
   * @param functions the functions defined within this executable element
   */
  void set functions(List<FunctionElement> functions) {
    for (FunctionElement function in functions) {
      (function as FunctionElementImpl).enclosingElement = this;
    }
    this._functions = functions;
  }

  /**
   * Set the labels defined within this executable element to the given labels.
   *
   * @param labels the labels defined within this executable element
   */
  void set labels(List<LabelElement> labels) {
    for (LabelElement label in labels) {
      (label as LabelElementImpl).enclosingElement = this;
    }
    this._labels = labels;
  }

  /**
   * Set the local variables defined within this executable element to the given variables.
   *
   * @param localVariables the local variables defined within this executable element
   */
  void set localVariables(List<LocalVariableElement> localVariables) {
    for (LocalVariableElement variable in localVariables) {
      (variable as LocalVariableElementImpl).enclosingElement = this;
    }
    this._localVariables = localVariables;
  }

  /**
   * Set the parameters defined by this executable element to the given parameters.
   *
   * @param parameters the parameters defined by this executable element
   */
  void set parameters(List<ParameterElement> parameters) {
    for (ParameterElement parameter in parameters) {
      (parameter as ParameterElementImpl).enclosingElement = this;
    }
    this._parameters = parameters;
  }

  /**
   * Set the return type defined by this executable element.
   *
   * @param returnType the return type defined by this executable element
   */
  void set returnType(Type2 returnType) {
    this._returnType = returnType;
  }

  /**
   * Set the type of function defined by this executable element to the given type.
   *
   * @param type the type of function defined by this executable element
   */
  void set type(FunctionType type) {
    this._type = type;
  }

  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChildren(_functions, visitor);
    safelyVisitChildren(_labels, visitor);
    safelyVisitChildren(_localVariables, visitor);
    safelyVisitChildren(_parameters, visitor);
  }

  void appendTo(JavaStringBuilder builder) {
    builder.append("(");
    int parameterCount = _parameters.length;
    for (int i = 0; i < parameterCount; i++) {
      if (i > 0) {
        builder.append(", ");
      }
      (_parameters[i] as ParameterElementImpl).appendTo(builder);
    }
    builder.append(")");
    if (_type != null) {
      builder.append(Element.RIGHT_ARROW);
      builder.append(_type.returnType);
    }
  }
}

/**
 * Instances of the class `ExportElementImpl` implement an [ExportElement].
 *
 * @coverage dart.engine.element
 */
class ExportElementImpl extends ElementImpl implements ExportElement {
  /**
   * The URI that is specified by this directive.
   */
  String _uri;

  /**
   * The library that is exported from this library by this export directive.
   */
  LibraryElement _exportedLibrary;

  /**
   * The combinators that were specified as part of the export directive in the order in which they
   * were specified.
   */
  List<NamespaceCombinator> _combinators = NamespaceCombinator.EMPTY_ARRAY;

  /**
   * Initialize a newly created export element.
   */
  ExportElementImpl() : super.con1(null);

  accept(ElementVisitor visitor) => visitor.visitExportElement(this);

  List<NamespaceCombinator> get combinators => _combinators;

  LibraryElement get exportedLibrary => _exportedLibrary;

  ElementKind get kind => ElementKind.EXPORT;

  String get uri => _uri;

  /**
   * Set the combinators that were specified as part of the export directive to the given array of
   * combinators.
   *
   * @param combinators the combinators that were specified as part of the export directive
   */
  void set combinators(List<NamespaceCombinator> combinators) {
    this._combinators = combinators;
  }

  /**
   * Set the library that is exported from this library by this import directive to the given
   * library.
   *
   * @param exportedLibrary the library that is exported from this library
   */
  void set exportedLibrary(LibraryElement exportedLibrary) {
    this._exportedLibrary = exportedLibrary;
  }

  /**
   * Set the URI that is specified by this directive.
   *
   * @param uri the URI that is specified by this directive.
   */
  void set uri(String uri) {
    this._uri = uri;
  }

  void appendTo(JavaStringBuilder builder) {
    builder.append("export ");
    (_exportedLibrary as LibraryElementImpl).appendTo(builder);
  }

  String get identifier => _exportedLibrary.name;
}

/**
 * Instances of the class `ExternalHtmlScriptElementImpl` implement an
 * [ExternalHtmlScriptElement].
 *
 * @coverage dart.engine.element
 */
class ExternalHtmlScriptElementImpl extends HtmlScriptElementImpl implements ExternalHtmlScriptElement {
  /**
   * The source specified in the `source` attribute or `null` if unspecified.
   */
  Source _scriptSource;

  /**
   * Initialize a newly created script element to have the specified tag name and offset.
   *
   * @param node the XML node from which this element is derived (not `null`)
   */
  ExternalHtmlScriptElementImpl(XmlTagNode node) : super(node);

  accept(ElementVisitor visitor) => visitor.visitExternalHtmlScriptElement(this);

  ElementKind get kind => ElementKind.EXTERNAL_HTML_SCRIPT;

  Source get scriptSource => _scriptSource;

  /**
   * Set the source specified in the `source` attribute.
   *
   * @param scriptSource the script source or `null` if unspecified
   */
  void set scriptSource(Source scriptSource) {
    this._scriptSource = scriptSource;
  }
}

/**
 * Instances of the class `FieldElementImpl` implement a `FieldElement`.
 *
 * @coverage dart.engine.element
 */
class FieldElementImpl extends PropertyInducingElementImpl implements FieldElement {
  /**
   * An empty array of field elements.
   */
  static List<FieldElement> EMPTY_ARRAY = new List<FieldElement>(0);

  /**
   * Initialize a newly created field element to have the given name.
   *
   * @param name the name of this element
   */
  FieldElementImpl.con1(Identifier name) : super.con1(name);

  /**
   * Initialize a newly created synthetic field element to have the given name.
   *
   * @param name the name of this element
   */
  FieldElementImpl.con2(String name) : super.con2(name);

  accept(ElementVisitor visitor) => visitor.visitFieldElement(this);

  ClassElement get enclosingElement => super.enclosingElement as ClassElement;

  ElementKind get kind => ElementKind.FIELD;

  bool get isStatic => hasModifier(Modifier.STATIC);

  /**
   * Set whether this field is static to correspond to the given value.
   *
   * @param isStatic `true` if the field is static
   */
  void set static(bool isStatic) {
    setModifier(Modifier.STATIC, isStatic);
  }
}

/**
 * Instances of the class `FieldFormalParameterElementImpl` extend
 * [ParameterElementImpl] to provide the additional information of the [FieldElement]
 * associated with the parameter.
 *
 * @coverage dart.engine.element
 */
class FieldFormalParameterElementImpl extends ParameterElementImpl implements FieldFormalParameterElement {
  /**
   * The field associated with this field formal parameter.
   */
  FieldElement _field;

  /**
   * Initialize a newly created parameter element to have the given name.
   *
   * @param name the name of this element
   */
  FieldFormalParameterElementImpl(Identifier name) : super.con1(name);

  accept(ElementVisitor visitor) => visitor.visitFieldFormalParameterElement(this);

  FieldElement get field => _field;

  bool get isInitializingFormal => true;

  /**
   * Set the field element associated with this field formal parameter to the given element.
   *
   * @param field the new field element
   */
  void set field(FieldElement field) {
    this._field = field;
  }
}

/**
 * Instances of the class `FunctionElementImpl` implement a `FunctionElement`.
 *
 * @coverage dart.engine.element
 */
class FunctionElementImpl extends ExecutableElementImpl implements FunctionElement {
  /**
   * The offset to the beginning of the visible range for this element.
   */
  int _visibleRangeOffset = 0;

  /**
   * The length of the visible range for this element, or `-1` if this element does not have a
   * visible range.
   */
  int _visibleRangeLength = -1;

  /**
   * An empty array of function elements.
   */
  static List<FunctionElement> EMPTY_ARRAY = new List<FunctionElement>(0);

  /**
   * Initialize a newly created function element to have the given name.
   *
   * @param name the name of this element
   */
  FunctionElementImpl.con1(Identifier name) : super.con1(name);

  /**
   * Initialize a newly created function element to have no name and the given offset. This is used
   * for function expressions, which have no name.
   *
   * @param nameOffset the offset of the name of this element in the file that contains the
   *          declaration of this element
   */
  FunctionElementImpl.con2(int nameOffset) : super.con2("", nameOffset);

  accept(ElementVisitor visitor) => visitor.visitFunctionElement(this);

  ElementKind get kind => ElementKind.FUNCTION;

  SourceRange get visibleRange {
    if (_visibleRangeLength < 0) {
      return null;
    }
    return new SourceRange(_visibleRangeOffset, _visibleRangeLength);
  }

  bool get isStatic => enclosingElement is CompilationUnitElement;

  /**
   * Set the visible range for this element to the range starting at the given offset with the given
   * length.
   *
   * @param offset the offset to the beginning of the visible range for this element
   * @param length the length of the visible range for this element, or `-1` if this element
   *          does not have a visible range
   */
  void setVisibleRange(int offset, int length) {
    _visibleRangeOffset = offset;
    _visibleRangeLength = length;
  }

  void appendTo(JavaStringBuilder builder) {
    String name = displayName;
    if (name != null) {
      builder.append(name);
    }
    super.appendTo(builder);
  }

  String get identifier => "${name}@${nameOffset}";
}

/**
 * Instances of the class `FunctionTypeAliasElementImpl` implement a
 * `FunctionTypeAliasElement`.
 *
 * @coverage dart.engine.element
 */
class FunctionTypeAliasElementImpl extends ElementImpl implements FunctionTypeAliasElement {
  /**
   * An array containing all of the parameters defined by this type alias.
   */
  List<ParameterElement> _parameters = ParameterElementImpl.EMPTY_ARRAY;

  /**
   * The return type defined by this type alias.
   */
  Type2 _returnType;

  /**
   * The type of function defined by this type alias.
   */
  FunctionType _type;

  /**
   * An array containing all of the type parameters defined for this type.
   */
  List<TypeParameterElement> _typeParameters = TypeParameterElementImpl.EMPTY_ARRAY;

  /**
   * An empty array of type alias elements.
   */
  static List<FunctionTypeAliasElement> EMPTY_ARRAY = new List<FunctionTypeAliasElement>(0);

  /**
   * Initialize a newly created type alias element to have the given name.
   *
   * @param name the name of this element
   */
  FunctionTypeAliasElementImpl(Identifier name) : super.con1(name);

  accept(ElementVisitor visitor) => visitor.visitFunctionTypeAliasElement(this);

  ElementImpl getChild(String identifier) {
    for (VariableElement parameter in _parameters) {
      if ((parameter as VariableElementImpl).identifier == identifier) {
        return parameter as VariableElementImpl;
      }
    }
    for (TypeParameterElement typeParameter in _typeParameters) {
      if ((typeParameter as TypeParameterElementImpl).identifier == identifier) {
        return typeParameter as TypeParameterElementImpl;
      }
    }
    return null;
  }

  CompilationUnitElement get enclosingElement => super.enclosingElement as CompilationUnitElement;

  ElementKind get kind => ElementKind.FUNCTION_TYPE_ALIAS;

  List<ParameterElement> get parameters => _parameters;

  Type2 get returnType => _returnType;

  FunctionType get type => _type;

  List<TypeParameterElement> get typeParameters => _typeParameters;

  /**
   * Set the parameters defined by this type alias to the given parameters.
   *
   * @param parameters the parameters defined by this type alias
   */
  void set parameters(List<ParameterElement> parameters) {
    if (parameters != null) {
      for (ParameterElement parameter in parameters) {
        (parameter as ParameterElementImpl).enclosingElement = this;
      }
    }
    this._parameters = parameters;
  }

  /**
   * Set the return type defined by this type alias.
   *
   * @param returnType the return type defined by this type alias
   */
  void set returnType(Type2 returnType) {
    this._returnType = returnType;
  }

  /**
   * Set the type of function defined by this type alias to the given type.
   *
   * @param type the type of function defined by this type alias
   */
  void set type(FunctionType type) {
    this._type = type;
  }

  /**
   * Set the type parameters defined for this type to the given parameters.
   *
   * @param typeParameters the type parameters defined for this type
   */
  void set typeParameters(List<TypeParameterElement> typeParameters) {
    for (TypeParameterElement typeParameter in typeParameters) {
      (typeParameter as TypeParameterElementImpl).enclosingElement = this;
    }
    this._typeParameters = typeParameters;
  }

  /**
   * Set the parameters defined by this type alias to the given parameters without becoming the
   * parent of the parameters. This should only be used by the [TypeResolverVisitor] when
   * creating a synthetic type alias.
   *
   * @param parameters the parameters defined by this type alias
   */
  void shareParameters(List<ParameterElement> parameters) {
    this._parameters = parameters;
  }

  /**
   * Set the type parameters defined for this type to the given parameters without becoming the
   * parent of the parameters. This should only be used by the [TypeResolverVisitor] when
   * creating a synthetic type alias.
   *
   * @param typeParameters the type parameters defined for this type
   */
  void shareTypeParameters(List<TypeParameterElement> typeParameters) {
    this._typeParameters = typeParameters;
  }

  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChildren(_parameters, visitor);
    safelyVisitChildren(_typeParameters, visitor);
  }

  void appendTo(JavaStringBuilder builder) {
    builder.append("typedef ");
    builder.append(displayName);
    int typeParameterCount = _typeParameters.length;
    if (typeParameterCount > 0) {
      builder.append("<");
      for (int i = 0; i < typeParameterCount; i++) {
        if (i > 0) {
          builder.append(", ");
        }
        (_typeParameters[i] as TypeParameterElementImpl).appendTo(builder);
      }
      builder.append(">");
    }
    builder.append("(");
    int parameterCount = _parameters.length;
    for (int i = 0; i < parameterCount; i++) {
      if (i > 0) {
        builder.append(", ");
      }
      (_parameters[i] as ParameterElementImpl).appendTo(builder);
    }
    builder.append(")");
    if (_type != null) {
      builder.append(Element.RIGHT_ARROW);
      builder.append(_type.returnType);
    }
  }
}

/**
 * Instances of the class `HideElementCombinatorImpl` implement a
 * [HideElementCombinator].
 *
 * @coverage dart.engine.element
 */
class HideElementCombinatorImpl implements HideElementCombinator {
  /**
   * The names that are not to be made visible in the importing library even if they are defined in
   * the imported library.
   */
  List<String> _hiddenNames = StringUtilities.EMPTY_ARRAY;

  List<String> get hiddenNames => _hiddenNames;

  /**
   * Set the names that are not to be made visible in the importing library even if they are defined
   * in the imported library to the given names.
   *
   * @param hiddenNames the names that are not to be made visible in the importing library
   */
  void set hiddenNames(List<String> hiddenNames) {
    this._hiddenNames = hiddenNames;
  }

  String toString() {
    JavaStringBuilder builder = new JavaStringBuilder();
    builder.append("show ");
    int count = _hiddenNames.length;
    for (int i = 0; i < count; i++) {
      if (i > 0) {
        builder.append(", ");
      }
      builder.append(_hiddenNames[i]);
    }
    return builder.toString();
  }
}

/**
 * Instances of the class `HtmlElementImpl` implement an [HtmlElement].
 *
 * @coverage dart.engine.element
 */
class HtmlElementImpl extends ElementImpl implements HtmlElement {
  /**
   * An empty array of HTML file elements.
   */
  static List<HtmlElement> EMPTY_ARRAY = new List<HtmlElement>(0);

  /**
   * The analysis context in which this library is defined.
   */
  AnalysisContext _context;

  /**
   * The scripts contained in or referenced from script tags in the HTML file.
   */
  List<HtmlScriptElement> _scripts = HtmlScriptElementImpl.EMPTY_ARRAY;

  /**
   * The source that corresponds to this HTML file.
   */
  Source _source;

  /**
   * Initialize a newly created HTML element to have the given name.
   *
   * @param context the analysis context in which the HTML file is defined
   * @param name the name of this element
   */
  HtmlElementImpl(AnalysisContext context, String name) : super.con2(name, -1) {
    this._context = context;
  }

  accept(ElementVisitor visitor) => visitor.visitHtmlElement(this);

  bool operator ==(Object object) => runtimeType == object.runtimeType && _source == (object as CompilationUnitElementImpl).source;

  AnalysisContext get context => _context;

  ElementKind get kind => ElementKind.HTML;

  List<HtmlScriptElement> get scripts => _scripts;

  Source get source => _source;

  int get hashCode => _source.hashCode;

  /**
   * Set the scripts contained in the HTML file to the given scripts.
   *
   * @param scripts the scripts
   */
  void set scripts(List<HtmlScriptElement> scripts) {
    if (scripts.length == 0) {
      scripts = HtmlScriptElementImpl.EMPTY_ARRAY;
    }
    for (HtmlScriptElement script in scripts) {
      (script as HtmlScriptElementImpl).enclosingElement = this;
    }
    this._scripts = scripts;
  }

  /**
   * Set the source that corresponds to this HTML file to the given source.
   *
   * @param source the source that corresponds to this HTML file
   */
  void set source(Source source) {
    this._source = source;
  }

  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChildren(_scripts, visitor);
  }

  void appendTo(JavaStringBuilder builder) {
    if (_source == null) {
      builder.append("{HTML file}");
    } else {
      builder.append(_source.fullName);
    }
  }
}

/**
 * Instances of the class `HtmlScriptElementImpl` implement an [HtmlScriptElement].
 *
 * @coverage dart.engine.element
 */
abstract class HtmlScriptElementImpl extends ElementImpl implements HtmlScriptElement {
  /**
   * An empty array of HTML script elements.
   */
  static List<HtmlScriptElement> EMPTY_ARRAY = new List<HtmlScriptElement>(0);

  /**
   * Initialize a newly created script element to have the specified tag name and offset.
   *
   * @param node the XML node from which this element is derived (not `null`)
   */
  HtmlScriptElementImpl(XmlTagNode node) : super.con2(node.tag.lexeme, node.tag.offset);
}

/**
 * Instances of the class `ImportElementImpl` implement an [ImportElement].
 *
 * @coverage dart.engine.element
 */
class ImportElementImpl extends ElementImpl implements ImportElement {
  /**
   * The offset of this directive, may be `-1` if synthetic.
   */
  int _offset = -1;

  /**
   * The offset of the character immediately following the last character of this node's URI, may be
   * `-1` if synthetic.
   */
  int _uriEnd = -1;

  /**
   * The offset of the prefix of this import in the file that contains the this import directive, or
   * `-1` if this import is synthetic.
   */
  int _prefixOffset = 0;

  /**
   * The URI that is specified by this directive.
   */
  String _uri;

  /**
   * The library that is imported into this library by this import directive.
   */
  LibraryElement _importedLibrary;

  /**
   * The combinators that were specified as part of the import directive in the order in which they
   * were specified.
   */
  List<NamespaceCombinator> _combinators = NamespaceCombinator.EMPTY_ARRAY;

  /**
   * The prefix that was specified as part of the import directive, or `null` if there was no
   * prefix specified.
   */
  PrefixElement _prefix;

  /**
   * Initialize a newly created import element.
   */
  ImportElementImpl() : super.con1(null);

  accept(ElementVisitor visitor) => visitor.visitImportElement(this);

  List<NamespaceCombinator> get combinators => _combinators;

  LibraryElement get importedLibrary => _importedLibrary;

  ElementKind get kind => ElementKind.IMPORT;

  PrefixElement get prefix => _prefix;

  int get prefixOffset => _prefixOffset;

  String get uri => _uri;

  int get uriEnd => _uriEnd;

  /**
   * Set the combinators that were specified as part of the import directive to the given array of
   * combinators.
   *
   * @param combinators the combinators that were specified as part of the import directive
   */
  void set combinators(List<NamespaceCombinator> combinators) {
    this._combinators = combinators;
  }

  /**
   * Set the library that is imported into this library by this import directive to the given
   * library.
   *
   * @param importedLibrary the library that is imported into this library
   */
  void set importedLibrary(LibraryElement importedLibrary) {
    this._importedLibrary = importedLibrary;
  }

  /**
   * Set the offset of this directive.
   */
  void set offset(int offset) {
    this._offset = offset;
  }

  /**
   * Set the prefix that was specified as part of the import directive to the given prefix.
   *
   * @param prefix the prefix that was specified as part of the import directive
   */
  void set prefix(PrefixElement prefix) {
    this._prefix = prefix;
  }

  /**
   * Set the offset of the prefix of this import in the file that contains the this import
   * directive.
   */
  void set prefixOffset(int prefixOffset) {
    this._prefixOffset = prefixOffset;
  }

  /**
   * Set the URI that is specified by this directive.
   *
   * @param uri the URI that is specified by this directive.
   */
  void set uri(String uri) {
    this._uri = uri;
  }

  /**
   * Set the the offset of the character immediately following the last character of this node's
   * URI. `-1` for synthetic import.
   */
  void set uriEnd(int uriEnd) {
    this._uriEnd = uriEnd;
  }

  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChild(_prefix, visitor);
  }

  void appendTo(JavaStringBuilder builder) {
    builder.append("import ");
    (_importedLibrary as LibraryElementImpl).appendTo(builder);
  }

  String get identifier => "${(_importedLibrary as LibraryElementImpl).identifier}@${_offset}";
}

/**
 * Instances of the class `LabelElementImpl` implement a `LabelElement`.
 *
 * @coverage dart.engine.element
 */
class LabelElementImpl extends ElementImpl implements LabelElement {
  /**
   * A flag indicating whether this label is associated with a `switch` statement.
   */
  bool isOnSwitchStatement = false;

  /**
   * A flag indicating whether this label is associated with a `switch` member (`case`
   * or `default`).
   */
  bool isOnSwitchMember = false;

  /**
   * An empty array of label elements.
   */
  static List<LabelElement> EMPTY_ARRAY = new List<LabelElement>(0);

  /**
   * Initialize a newly created label element to have the given name.
   *
   * @param name the name of this element
   * @param onSwitchStatement `true` if this label is associated with a `switch`
   *          statement
   * @param onSwitchMember `true` if this label is associated with a `switch` member
   */
  LabelElementImpl(Identifier name, bool onSwitchStatement, bool onSwitchMember) : super.con1(name) {
    this.isOnSwitchStatement = onSwitchStatement;
    this.isOnSwitchMember = onSwitchMember;
  }

  accept(ElementVisitor visitor) => visitor.visitLabelElement(this);

  ExecutableElement get enclosingElement => super.enclosingElement as ExecutableElement;

  ElementKind get kind => ElementKind.LABEL;
}

/**
 * Instances of the class `LibraryElementImpl` implement a `LibraryElement`.
 *
 * @coverage dart.engine.element
 */
class LibraryElementImpl extends ElementImpl implements LibraryElement {
  /**
   * An empty array of library elements.
   */
  static List<LibraryElement> EMPTY_ARRAY = new List<LibraryElement>(0);

  /**
   * Determine if the given library is up to date with respect to the given time stamp.
   *
   * @param library the library to process
   * @param timeStamp the time stamp to check against
   * @param visitedLibraries the set of visited libraries
   */
  static bool isUpToDate(LibraryElement library, int timeStamp, Set<LibraryElement> visitedLibraries) {
    if (!visitedLibraries.contains(library)) {
      visitedLibraries.add(library);
      if (timeStamp < library.definingCompilationUnit.source.modificationStamp) {
        return false;
      }
      for (CompilationUnitElement element in library.parts) {
        if (timeStamp < element.source.modificationStamp) {
          return false;
        }
      }
      for (LibraryElement importedLibrary in library.importedLibraries) {
        if (!isUpToDate(importedLibrary, timeStamp, visitedLibraries)) {
          return false;
        }
      }
      for (LibraryElement exportedLibrary in library.exportedLibraries) {
        if (!isUpToDate(exportedLibrary, timeStamp, visitedLibraries)) {
          return false;
        }
      }
    }
    return true;
  }

  /**
   * The analysis context in which this library is defined.
   */
  AnalysisContext _context;

  /**
   * The compilation unit that defines this library.
   */
  CompilationUnitElement _definingCompilationUnit;

  /**
   * The entry point for this library, or `null` if this library does not have an entry point.
   */
  FunctionElement _entryPoint;

  /**
   * An array containing specifications of all of the imports defined in this library.
   */
  List<ImportElement> _imports = ImportElement.EMPTY_ARRAY;

  /**
   * An array containing specifications of all of the exports defined in this library.
   */
  List<ExportElement> _exports = ExportElement.EMPTY_ARRAY;

  /**
   * An array containing all of the compilation units that are included in this library using a
   * `part` directive.
   */
  List<CompilationUnitElement> _parts = CompilationUnitElementImpl.EMPTY_ARRAY;

  /**
   * Initialize a newly created library element to have the given name.
   *
   * @param context the analysis context in which the library is defined
   * @param name the name of this element
   */
  LibraryElementImpl(AnalysisContext context, LibraryIdentifier name) : super.con1(name) {
    this._context = context;
  }

  accept(ElementVisitor visitor) => visitor.visitLibraryElement(this);

  bool operator ==(Object object) => object != null && runtimeType == object.runtimeType && _definingCompilationUnit == (object as LibraryElementImpl).definingCompilationUnit;

  ElementImpl getChild(String identifier) {
    if ((_definingCompilationUnit as CompilationUnitElementImpl).identifier == identifier) {
      return _definingCompilationUnit as CompilationUnitElementImpl;
    }
    for (CompilationUnitElement part in _parts) {
      if ((part as CompilationUnitElementImpl).identifier == identifier) {
        return part as CompilationUnitElementImpl;
      }
    }
    for (ImportElement importElement in _imports) {
      if ((importElement as ImportElementImpl).identifier == identifier) {
        return importElement as ImportElementImpl;
      }
    }
    for (ExportElement exportElement in _exports) {
      if ((exportElement as ExportElementImpl).identifier == identifier) {
        return exportElement as ExportElementImpl;
      }
    }
    return null;
  }

  AnalysisContext get context => _context;

  CompilationUnitElement get definingCompilationUnit => _definingCompilationUnit;

  FunctionElement get entryPoint => _entryPoint;

  List<LibraryElement> get exportedLibraries {
    Set<LibraryElement> libraries = new Set<LibraryElement>();
    for (ExportElement element in _exports) {
      LibraryElement library = element.exportedLibrary;
      if (library != null) {
        libraries.add(library);
      }
    }
    return new List.from(libraries);
  }

  List<ExportElement> get exports => _exports;

  List<LibraryElement> get importedLibraries {
    Set<LibraryElement> libraries = new Set<LibraryElement>();
    for (ImportElement element in _imports) {
      LibraryElement library = element.importedLibrary;
      if (library != null) {
        libraries.add(library);
      }
    }
    return new List.from(libraries);
  }

  List<ImportElement> get imports => _imports;

  ElementKind get kind => ElementKind.LIBRARY;

  LibraryElement get library => this;

  List<CompilationUnitElement> get parts => _parts;

  List<PrefixElement> get prefixes {
    Set<PrefixElement> prefixes = new Set<PrefixElement>();
    for (ImportElement element in _imports) {
      PrefixElement prefix = element.prefix;
      if (prefix != null) {
        prefixes.add(prefix);
      }
    }
    return new List.from(prefixes);
  }

  Source get source {
    if (_definingCompilationUnit == null) {
      return null;
    }
    return _definingCompilationUnit.source;
  }

  ClassElement getType(String className) {
    ClassElement type = _definingCompilationUnit.getType(className);
    if (type != null) {
      return type;
    }
    for (CompilationUnitElement part in _parts) {
      type = part.getType(className);
      if (type != null) {
        return type;
      }
    }
    return null;
  }

  int get hashCode => _definingCompilationUnit.hashCode;

  bool get isBrowserApplication => _entryPoint != null && isOrImportsBrowserLibrary;

  bool get isDartCore => name == "dart.core";

  bool get isInSdk => name.startsWith("dart.");

  bool isUpToDate2(int timeStamp) {
    Set<LibraryElement> visitedLibraries = new Set();
    return isUpToDate(this, timeStamp, visitedLibraries);
  }

  /**
   * Set the compilation unit that defines this library to the given compilation unit.
   *
   * @param definingCompilationUnit the compilation unit that defines this library
   */
  void set definingCompilationUnit(CompilationUnitElement definingCompilationUnit) {
    (definingCompilationUnit as CompilationUnitElementImpl).enclosingElement = this;
    this._definingCompilationUnit = definingCompilationUnit;
  }

  /**
   * Set the entry point for this library to the given function.
   *
   * @param entryPoint the entry point for this library
   */
  void set entryPoint(FunctionElement entryPoint) {
    this._entryPoint = entryPoint;
  }

  /**
   * Set the specifications of all of the exports defined in this library to the given array.
   *
   * @param exports the specifications of all of the exports defined in this library
   */
  void set exports(List<ExportElement> exports) {
    for (ExportElement exportElement in exports) {
      (exportElement as ExportElementImpl).enclosingElement = this;
    }
    this._exports = exports;
  }

  /**
   * Set the specifications of all of the imports defined in this library to the given array.
   *
   * @param imports the specifications of all of the imports defined in this library
   */
  void set imports(List<ImportElement> imports) {
    for (ImportElement importElement in imports) {
      (importElement as ImportElementImpl).enclosingElement = this;
      PrefixElementImpl prefix = importElement.prefix as PrefixElementImpl;
      if (prefix != null) {
        prefix.enclosingElement = this;
      }
    }
    this._imports = imports;
  }

  /**
   * Set the compilation units that are included in this library using a `part` directive.
   *
   * @param parts the compilation units that are included in this library using a `part`
   *          directive
   */
  void set parts(List<CompilationUnitElement> parts) {
    for (CompilationUnitElement compilationUnit in parts) {
      (compilationUnit as CompilationUnitElementImpl).enclosingElement = this;
    }
    this._parts = parts;
  }

  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChild(_definingCompilationUnit, visitor);
    safelyVisitChildren(_exports, visitor);
    safelyVisitChildren(_imports, visitor);
    safelyVisitChildren(_parts, visitor);
  }

  String get identifier => _definingCompilationUnit.source.encoding;

  /**
   * Answer `true` if the receiver directly or indirectly imports the dart:html libraries.
   *
   * @return `true` if the receiver directly or indirectly imports the dart:html libraries
   */
  bool get isOrImportsBrowserLibrary {
    List<LibraryElement> visited = new List<LibraryElement>();
    Source htmlLibSource = _context.sourceFactory.forUri(DartSdk.DART_HTML);
    visited.add(this);
    for (int index = 0; index < visited.length; index++) {
      LibraryElement library = visited[index];
      Source source = library.definingCompilationUnit.source;
      if (source == htmlLibSource) {
        return true;
      }
      for (LibraryElement importedLibrary in library.importedLibraries) {
        if (!visited.contains(importedLibrary)) {
          visited.add(importedLibrary);
        }
      }
      for (LibraryElement exportedLibrary in library.exportedLibraries) {
        if (!visited.contains(exportedLibrary)) {
          visited.add(exportedLibrary);
        }
      }
    }
    return false;
  }
}

/**
 * Instances of the class `LocalVariableElementImpl` implement a `LocalVariableElement`.
 *
 * @coverage dart.engine.element
 */
class LocalVariableElementImpl extends VariableElementImpl implements LocalVariableElement {
  /**
   * Is `true` if this variable is potentially mutated somewhere in its scope.
   */
  bool _isPotentiallyMutatedInScope2 = false;

  /**
   * Is `true` if this variable is potentially mutated somewhere in closure.
   */
  bool _isPotentiallyMutatedInClosure2 = false;

  /**
   * The offset to the beginning of the visible range for this element.
   */
  int _visibleRangeOffset = 0;

  /**
   * The length of the visible range for this element, or `-1` if this element does not have a
   * visible range.
   */
  int _visibleRangeLength = -1;

  /**
   * An empty array of field elements.
   */
  static List<LocalVariableElement> EMPTY_ARRAY = new List<LocalVariableElement>(0);

  /**
   * Initialize a newly created local variable element to have the given name.
   *
   * @param name the name of this element
   */
  LocalVariableElementImpl(Identifier name) : super.con1(name);

  accept(ElementVisitor visitor) => visitor.visitLocalVariableElement(this);

  ElementKind get kind => ElementKind.LOCAL_VARIABLE;

  SourceRange get visibleRange {
    if (_visibleRangeLength < 0) {
      return null;
    }
    return new SourceRange(_visibleRangeOffset, _visibleRangeLength);
  }

  bool get isPotentiallyMutatedInClosure => _isPotentiallyMutatedInClosure2;

  bool get isPotentiallyMutatedInScope => _isPotentiallyMutatedInScope2;

  /**
   * Specifies that this variable is potentially mutated somewhere in closure.
   */
  void markPotentiallyMutatedInClosure() {
    _isPotentiallyMutatedInClosure2 = true;
  }

  /**
   * Specifies that this variable is potentially mutated somewhere in its scope.
   */
  void markPotentiallyMutatedInScope() {
    _isPotentiallyMutatedInScope2 = true;
  }

  /**
   * Set the visible range for this element to the range starting at the given offset with the given
   * length.
   *
   * @param offset the offset to the beginning of the visible range for this element
   * @param length the length of the visible range for this element, or `-1` if this element
   *          does not have a visible range
   */
  void setVisibleRange(int offset, int length) {
    _visibleRangeOffset = offset;
    _visibleRangeLength = length;
  }

  void appendTo(JavaStringBuilder builder) {
    builder.append(type);
    builder.append(" ");
    builder.append(displayName);
  }

  String get identifier => "${super.identifier}@${nameOffset}";
}

/**
 * Instances of the class `MethodElementImpl` implement a `MethodElement`.
 *
 * @coverage dart.engine.element
 */
class MethodElementImpl extends ExecutableElementImpl implements MethodElement {
  /**
   * An empty array of method elements.
   */
  static List<MethodElement> EMPTY_ARRAY = new List<MethodElement>(0);

  /**
   * Initialize a newly created method element to have the given name.
   *
   * @param name the name of this element
   */
  MethodElementImpl.con1(Identifier name) : super.con1(name);

  /**
   * Initialize a newly created method element to have the given name.
   *
   * @param name the name of this element
   * @param nameOffset the offset of the name of this element in the file that contains the
   *          declaration of this element
   */
  MethodElementImpl.con2(String name, int nameOffset) : super.con2(name, nameOffset);

  accept(ElementVisitor visitor) => visitor.visitMethodElement(this);

  ClassElement get enclosingElement => super.enclosingElement as ClassElement;

  ElementKind get kind => ElementKind.METHOD;

  String get name {
    String name = super.name;
    if (isOperator && name == "-") {
      if (parameters.length == 0) {
        return "unary-";
      }
    }
    return super.name;
  }

  bool get isAbstract => hasModifier(Modifier.ABSTRACT);

  bool get isOperator {
    String name = displayName;
    if (name.isEmpty) {
      return false;
    }
    int first = name.codeUnitAt(0);
    return !((0x61 <= first && first <= 0x7A) || (0x41 <= first && first <= 0x5A) || first == 0x5F || first == 0x24);
  }

  bool get isStatic => hasModifier(Modifier.STATIC);

  /**
   * Set whether this method is abstract to correspond to the given value.
   *
   * @param isAbstract `true` if the method is abstract
   */
  void set abstract(bool isAbstract) {
    setModifier(Modifier.ABSTRACT, isAbstract);
  }

  /**
   * Set whether this method is static to correspond to the given value.
   *
   * @param isStatic `true` if the method is static
   */
  void set static(bool isStatic) {
    setModifier(Modifier.STATIC, isStatic);
  }

  void appendTo(JavaStringBuilder builder) {
    builder.append(enclosingElement.displayName);
    builder.append(".");
    builder.append(displayName);
    super.appendTo(builder);
  }
}

/**
 * The enumeration `Modifier` defines constants for all of the modifiers defined by the Dart
 * language and for a few additional flags that are useful.
 *
 * @coverage dart.engine.element
 */
class Modifier extends Enum<Modifier> {
  static final Modifier ABSTRACT = new Modifier('ABSTRACT', 0);

  static final Modifier CONST = new Modifier('CONST', 1);

  static final Modifier FACTORY = new Modifier('FACTORY', 2);

  static final Modifier FINAL = new Modifier('FINAL', 3);

  static final Modifier GETTER = new Modifier('GETTER', 4);

  static final Modifier MIXIN = new Modifier('MIXIN', 5);

  static final Modifier REFERENCES_SUPER = new Modifier('REFERENCES_SUPER', 6);

  static final Modifier SETTER = new Modifier('SETTER', 7);

  static final Modifier STATIC = new Modifier('STATIC', 8);

  static final Modifier SYNTHETIC = new Modifier('SYNTHETIC', 9);

  static final Modifier TYPEDEF = new Modifier('TYPEDEF', 10);

  static final List<Modifier> values = [
      ABSTRACT,
      CONST,
      FACTORY,
      FINAL,
      GETTER,
      MIXIN,
      REFERENCES_SUPER,
      SETTER,
      STATIC,
      SYNTHETIC,
      TYPEDEF];

  Modifier(String name, int ordinal) : super(name, ordinal);
}

/**
 * Instances of the class `MultiplyDefinedElementImpl` represent a collection of elements that
 * have the same name within the same scope.
 *
 * @coverage dart.engine.element
 */
class MultiplyDefinedElementImpl implements MultiplyDefinedElement {
  /**
   * Return an element that represents the given conflicting elements.
   *
   * @param context the analysis context in which the multiply defined elements are defined
   * @param firstElement the first element that conflicts
   * @param secondElement the second element that conflicts
   */
  static Element fromElements(AnalysisContext context, Element firstElement, Element secondElement) {
    List<Element> conflictingElements = computeConflictingElements(firstElement, secondElement);
    int length = conflictingElements.length;
    if (length == 0) {
      return null;
    } else if (length == 1) {
      return conflictingElements[0];
    }
    return new MultiplyDefinedElementImpl(context, conflictingElements);
  }

  /**
   * Add the given element to the list of elements. If the element is a multiply-defined element,
   * add all of the conflicting elements that it represents.
   *
   * @param elements the list to which the element(s) are to be added
   * @param element the element(s) to be added
   */
  static void add(Set<Element> elements, Element element) {
    if (element is MultiplyDefinedElementImpl) {
      for (Element conflictingElement in (element as MultiplyDefinedElementImpl)._conflictingElements) {
        elements.add(conflictingElement);
      }
    } else {
      elements.add(element);
    }
  }

  /**
   * Use the given elements to construct an array of conflicting elements. If either of the given
   * elements are multiply-defined elements then the conflicting elements they represent will be
   * included in the array. Otherwise, the element itself will be included.
   *
   * @param firstElement the first element to be included
   * @param secondElement the second element to be included
   * @return an array containing all of the conflicting elements
   */
  static List<Element> computeConflictingElements(Element firstElement, Element secondElement) {
    Set<Element> elements = new Set<Element>();
    add(elements, firstElement);
    add(elements, secondElement);
    return new List.from(elements);
  }

  /**
   * The analysis context in which the multiply defined elements are defined.
   */
  AnalysisContext _context;

  /**
   * The name of the conflicting elements.
   */
  String _name;

  /**
   * A list containing all of the elements that conflict.
   */
  List<Element> _conflictingElements;

  /**
   * Initialize a newly created element to represent a list of conflicting elements.
   *
   * @param context the analysis context in which the multiply defined elements are defined
   * @param conflictingElements the elements that conflict
   */
  MultiplyDefinedElementImpl(AnalysisContext context, List<Element> conflictingElements) {
    this._context = context;
    _name = conflictingElements[0].name;
    this._conflictingElements = conflictingElements;
  }

  accept(ElementVisitor visitor) => visitor.visitMultiplyDefinedElement(this);

  String computeDocumentationComment() => null;

  Element getAncestor(Type elementClass) => null;

  List<Element> get conflictingElements => _conflictingElements;

  AnalysisContext get context => _context;

  String get displayName => _name;

  Element get enclosingElement => null;

  ElementKind get kind => ElementKind.ERROR;

  LibraryElement get library => null;

  ElementLocation get location => null;

  List<ElementAnnotation> get metadata => ElementAnnotationImpl.EMPTY_ARRAY;

  String get name => _name;

  int get nameOffset => -1;

  Source get source => null;

  Type2 get type => DynamicTypeImpl.instance;

  bool isAccessibleIn(LibraryElement library) {
    for (Element element in _conflictingElements) {
      if (element.isAccessibleIn(library)) {
        return true;
      }
    }
    return false;
  }

  bool get isDeprecated => false;

  bool get isSynthetic => true;

  String toString() {
    JavaStringBuilder builder = new JavaStringBuilder();
    builder.append("[");
    int count = _conflictingElements.length;
    for (int i = 0; i < count; i++) {
      if (i > 0) {
        builder.append(", ");
      }
      (_conflictingElements[i] as ElementImpl).appendTo(builder);
    }
    builder.append("]");
    return builder.toString();
  }

  void visitChildren(ElementVisitor visitor) {
  }
}

/**
 * Instances of the class `ParameterElementImpl` implement a `ParameterElement`.
 *
 * @coverage dart.engine.element
 */
class ParameterElementImpl extends VariableElementImpl implements ParameterElement {
  /**
   * Is `true` if this variable is potentially mutated somewhere in its scope.
   */
  bool _isPotentiallyMutatedInScope3 = false;

  /**
   * Is `true` if this variable is potentially mutated somewhere in closure.
   */
  bool _isPotentiallyMutatedInClosure3 = false;

  /**
   * An array containing all of the parameters defined by this parameter element. There will only be
   * parameters if this parameter is a function typed parameter.
   */
  List<ParameterElement> _parameters = ParameterElementImpl.EMPTY_ARRAY;

  /**
   * The kind of this parameter.
   */
  ParameterKind _parameterKind;

  /**
   * The offset to the beginning of the default value range for this element.
   */
  int _defaultValueRangeOffset = 0;

  /**
   * The length of the default value range for this element, or `-1` if this element does not
   * have a default value.
   */
  int _defaultValueRangeLength = -1;

  /**
   * The offset to the beginning of the visible range for this element.
   */
  int _visibleRangeOffset = 0;

  /**
   * The length of the visible range for this element, or `-1` if this element does not have a
   * visible range.
   */
  int _visibleRangeLength = -1;

  /**
   * An empty array of field elements.
   */
  static List<ParameterElement> EMPTY_ARRAY = new List<ParameterElement>(0);

  /**
   * Initialize a newly created parameter element to have the given name.
   *
   * @param name the name of this element
   */
  ParameterElementImpl.con1(Identifier name) : super.con1(name);

  /**
   * Initialize a newly created parameter element to have the given name.
   *
   * @param name the name of this element
   * @param nameOffset the offset of the name of this element in the file that contains the
   *          declaration of this element
   */
  ParameterElementImpl.con2(String name, int nameOffset) : super.con2(name, nameOffset);

  accept(ElementVisitor visitor) => visitor.visitParameterElement(this);

  SourceRange get defaultValueRange {
    if (_defaultValueRangeLength < 0) {
      return null;
    }
    return new SourceRange(_defaultValueRangeOffset, _defaultValueRangeLength);
  }

  ElementKind get kind => ElementKind.PARAMETER;

  ParameterKind get parameterKind => _parameterKind;

  List<ParameterElement> get parameters => _parameters;

  SourceRange get visibleRange {
    if (_visibleRangeLength < 0) {
      return null;
    }
    return new SourceRange(_visibleRangeOffset, _visibleRangeLength);
  }

  bool get isInitializingFormal => false;

  bool get isPotentiallyMutatedInClosure => _isPotentiallyMutatedInClosure3;

  bool get isPotentiallyMutatedInScope => _isPotentiallyMutatedInScope3;

  /**
   * Specifies that this variable is potentially mutated somewhere in closure.
   */
  void markPotentiallyMutatedInClosure() {
    _isPotentiallyMutatedInClosure3 = true;
  }

  /**
   * Specifies that this variable is potentially mutated somewhere in its scope.
   */
  void markPotentiallyMutatedInScope() {
    _isPotentiallyMutatedInScope3 = true;
  }

  /**
   * Set the range of the default value for this parameter to the range starting at the given offset
   * with the given length.
   *
   * @param offset the offset to the beginning of the default value range for this element
   * @param length the length of the default value range for this element, or `-1` if this
   *          element does not have a default value
   */
  void setDefaultValueRange(int offset, int length) {
    _defaultValueRangeOffset = offset;
    _defaultValueRangeLength = length;
  }

  /**
   * Set the kind of this parameter to the given kind.
   *
   * @param parameterKind the new kind of this parameter
   */
  void set parameterKind(ParameterKind parameterKind) {
    this._parameterKind = parameterKind;
  }

  /**
   * Set the parameters defined by this executable element to the given parameters.
   *
   * @param parameters the parameters defined by this executable element
   */
  void set parameters(List<ParameterElement> parameters) {
    for (ParameterElement parameter in parameters) {
      (parameter as ParameterElementImpl).enclosingElement = this;
    }
    this._parameters = parameters;
  }

  /**
   * Set the visible range for this element to the range starting at the given offset with the given
   * length.
   *
   * @param offset the offset to the beginning of the visible range for this element
   * @param length the length of the visible range for this element, or `-1` if this element
   *          does not have a visible range
   */
  void setVisibleRange(int offset, int length) {
    _visibleRangeOffset = offset;
    _visibleRangeLength = length;
  }

  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChildren(_parameters, visitor);
  }

  void appendTo(JavaStringBuilder builder) {
    String left = "";
    String right = "";
    while (true) {
      if (parameterKind == ParameterKind.NAMED) {
        left = "{";
        right = "}";
      } else if (parameterKind == ParameterKind.POSITIONAL) {
        left = "[";
        right = "]";
      }
      break;
    }
    builder.append(left);
    builder.append(type);
    builder.append(" ");
    builder.append(displayName);
    builder.append(right);
  }
}

/**
 * Instances of the class `PrefixElementImpl` implement a `PrefixElement`.
 *
 * @coverage dart.engine.element
 */
class PrefixElementImpl extends ElementImpl implements PrefixElement {
  /**
   * An array containing all of the libraries that are imported using this prefix.
   */
  List<LibraryElement> _importedLibraries = LibraryElementImpl.EMPTY_ARRAY;

  /**
   * An empty array of prefix elements.
   */
  static List<PrefixElement> EMPTY_ARRAY = new List<PrefixElement>(0);

  /**
   * Initialize a newly created prefix element to have the given name.
   *
   * @param name the name of this element
   */
  PrefixElementImpl(Identifier name) : super.con1(name);

  accept(ElementVisitor visitor) => visitor.visitPrefixElement(this);

  LibraryElement get enclosingElement => super.enclosingElement as LibraryElement;

  List<LibraryElement> get importedLibraries => _importedLibraries;

  ElementKind get kind => ElementKind.PREFIX;

  /**
   * Set the libraries that are imported using this prefix to the given libraries.
   *
   * @param importedLibraries the libraries that are imported using this prefix
   */
  void set importedLibraries(List<LibraryElement> importedLibraries) {
    for (LibraryElement library in importedLibraries) {
      (library as LibraryElementImpl).enclosingElement = this;
    }
    this._importedLibraries = importedLibraries;
  }

  void appendTo(JavaStringBuilder builder) {
    builder.append("as ");
    super.appendTo(builder);
  }

  String get identifier => "_${super.identifier}";
}

/**
 * Instances of the class `PropertyAccessorElementImpl` implement a
 * `PropertyAccessorElement`.
 *
 * @coverage dart.engine.element
 */
class PropertyAccessorElementImpl extends ExecutableElementImpl implements PropertyAccessorElement {
  /**
   * The variable associated with this accessor.
   */
  PropertyInducingElement _variable;

  /**
   * An empty array of property accessor elements.
   */
  static List<PropertyAccessorElement> EMPTY_ARRAY = new List<PropertyAccessorElement>(0);

  /**
   * Initialize a newly created property accessor element to have the given name.
   *
   * @param name the name of this element
   */
  PropertyAccessorElementImpl.con1(Identifier name) : super.con1(name);

  /**
   * Initialize a newly created synthetic property accessor element to be associated with the given
   * variable.
   *
   * @param variable the variable with which this access is associated
   */
  PropertyAccessorElementImpl.con2(PropertyInducingElementImpl variable) : super.con2(variable.name, variable.nameOffset) {
    this._variable = variable;
    synthetic = true;
  }

  accept(ElementVisitor visitor) => visitor.visitPropertyAccessorElement(this);

  bool operator ==(Object object) => super == object && identical(isGetter, (object as PropertyAccessorElement).isGetter);

  PropertyAccessorElement get correspondingGetter {
    if (isGetter || _variable == null) {
      return null;
    }
    return _variable.getter;
  }

  PropertyAccessorElement get correspondingSetter {
    if (isSetter || _variable == null) {
      return null;
    }
    return _variable.setter;
  }

  ElementKind get kind {
    if (isGetter) {
      return ElementKind.GETTER;
    }
    return ElementKind.SETTER;
  }

  String get name {
    if (isSetter) {
      return "${super.name}=";
    }
    return super.name;
  }

  PropertyInducingElement get variable => _variable;

  bool get isAbstract => hasModifier(Modifier.ABSTRACT);

  bool get isGetter => hasModifier(Modifier.GETTER);

  bool get isSetter => hasModifier(Modifier.SETTER);

  bool get isStatic => hasModifier(Modifier.STATIC);

  /**
   * Set whether this accessor is abstract to correspond to the given value.
   *
   * @param isAbstract `true` if the accessor is abstract
   */
  void set abstract(bool isAbstract) {
    setModifier(Modifier.ABSTRACT, isAbstract);
  }

  /**
   * Set whether this accessor is a getter to correspond to the given value.
   *
   * @param isGetter `true` if the accessor is a getter
   */
  void set getter(bool isGetter) {
    setModifier(Modifier.GETTER, isGetter);
  }

  /**
   * Set whether this accessor is a setter to correspond to the given value.
   *
   * @param isSetter `true` if the accessor is a setter
   */
  void set setter(bool isSetter) {
    setModifier(Modifier.SETTER, isSetter);
  }

  /**
   * Set whether this accessor is static to correspond to the given value.
   *
   * @param isStatic `true` if the accessor is static
   */
  void set static(bool isStatic) {
    setModifier(Modifier.STATIC, isStatic);
  }

  /**
   * Set the variable associated with this accessor to the given variable.
   *
   * @param variable the variable associated with this accessor
   */
  void set variable(PropertyInducingElement variable) {
    this._variable = variable;
  }

  void appendTo(JavaStringBuilder builder) {
    builder.append(isGetter ? "get " : "set ");
    builder.append(variable.displayName);
    super.appendTo(builder);
  }
}

/**
 * Instances of the class `PropertyInducingElementImpl` implement a
 * `PropertyInducingElement`.
 *
 * @coverage dart.engine.element
 */
abstract class PropertyInducingElementImpl extends VariableElementImpl implements PropertyInducingElement {
  /**
   * The getter associated with this element.
   */
  PropertyAccessorElement _getter;

  /**
   * The setter associated with this element, or `null` if the element is effectively
   * `final` and therefore does not have a setter associated with it.
   */
  PropertyAccessorElement _setter;

  /**
   * An empty array of elements.
   */
  static List<PropertyInducingElement> EMPTY_ARRAY = new List<PropertyInducingElement>(0);

  /**
   * Initialize a newly created element to have the given name.
   *
   * @param name the name of this element
   */
  PropertyInducingElementImpl.con1(Identifier name) : super.con1(name);

  /**
   * Initialize a newly created synthetic element to have the given name.
   *
   * @param name the name of this element
   */
  PropertyInducingElementImpl.con2(String name) : super.con2(name, -1) {
    synthetic = true;
  }

  PropertyAccessorElement get getter => _getter;

  PropertyAccessorElement get setter => _setter;

  /**
   * Set the getter associated with this element to the given accessor.
   *
   * @param getter the getter associated with this element
   */
  void set getter(PropertyAccessorElement getter) {
    this._getter = getter;
  }

  /**
   * Set the setter associated with this element to the given accessor.
   *
   * @param setter the setter associated with this element
   */
  void set setter(PropertyAccessorElement setter) {
    this._setter = setter;
  }
}

/**
 * Instances of the class `ShowElementCombinatorImpl` implement a
 * [ShowElementCombinator].
 *
 * @coverage dart.engine.element
 */
class ShowElementCombinatorImpl implements ShowElementCombinator {
  /**
   * The names that are to be made visible in the importing library if they are defined in the
   * imported library.
   */
  List<String> _shownNames = StringUtilities.EMPTY_ARRAY;

  /**
   * The offset of the character immediately following the last character of this node.
   */
  int _end = -1;

  /**
   * The offset of the 'show' keyword of this element.
   */
  int _offset = 0;

  int get end => _end;

  int get offset => _offset;

  List<String> get shownNames => _shownNames;

  /**
   * Set the the offset of the character immediately following the last character of this node.
   */
  void set end(int endOffset) {
    this._end = endOffset;
  }

  /**
   * Sets the offset of the 'show' keyword of this directive.
   */
  void set offset(int offset) {
    this._offset = offset;
  }

  /**
   * Set the names that are to be made visible in the importing library if they are defined in the
   * imported library to the given names.
   *
   * @param shownNames the names that are to be made visible in the importing library
   */
  void set shownNames(List<String> shownNames) {
    this._shownNames = shownNames;
  }

  String toString() {
    JavaStringBuilder builder = new JavaStringBuilder();
    builder.append("show ");
    int count = _shownNames.length;
    for (int i = 0; i < count; i++) {
      if (i > 0) {
        builder.append(", ");
      }
      builder.append(_shownNames[i]);
    }
    return builder.toString();
  }
}

/**
 * Instances of the class `TopLevelVariableElementImpl` implement a
 * `TopLevelVariableElement`.
 *
 * @coverage dart.engine.element
 */
class TopLevelVariableElementImpl extends PropertyInducingElementImpl implements TopLevelVariableElement {
  /**
   * An empty array of top-level variable elements.
   */
  static List<TopLevelVariableElement> EMPTY_ARRAY = new List<TopLevelVariableElement>(0);

  /**
   * Initialize a newly created top-level variable element to have the given name.
   *
   * @param name the name of this element
   */
  TopLevelVariableElementImpl.con1(Identifier name) : super.con1(name);

  /**
   * Initialize a newly created synthetic top-level variable element to have the given name.
   *
   * @param name the name of this element
   */
  TopLevelVariableElementImpl.con2(String name) : super.con2(name);

  accept(ElementVisitor visitor) => visitor.visitTopLevelVariableElement(this);

  ElementKind get kind => ElementKind.TOP_LEVEL_VARIABLE;

  bool get isStatic => true;
}

/**
 * Instances of the class `TypeParameterElementImpl` implement a [TypeParameterElement].
 *
 * @coverage dart.engine.element
 */
class TypeParameterElementImpl extends ElementImpl implements TypeParameterElement {
  /**
   * The type defined by this type parameter.
   */
  TypeParameterType _type;

  /**
   * The type representing the bound associated with this parameter, or `null` if this
   * parameter does not have an explicit bound.
   */
  Type2 _bound;

  /**
   * An empty array of type parameter elements.
   */
  static List<TypeParameterElement> EMPTY_ARRAY = new List<TypeParameterElement>(0);

  /**
   * Initialize a newly created type parameter element to have the given name.
   *
   * @param name the name of this element
   */
  TypeParameterElementImpl(Identifier name) : super.con1(name);

  accept(ElementVisitor visitor) => visitor.visitTypeParameterElement(this);

  Type2 get bound => _bound;

  ElementKind get kind => ElementKind.TYPE_PARAMETER;

  TypeParameterType get type => _type;

  /**
   * Set the type representing the bound associated with this parameter to the given type.
   *
   * @param bound the type representing the bound associated with this parameter
   */
  void set bound(Type2 bound) {
    this._bound = bound;
  }

  /**
   * Set the type defined by this type parameter to the given type
   *
   * @param type the type defined by this type parameter
   */
  void set type(TypeParameterType type) {
    this._type = type;
  }

  void appendTo(JavaStringBuilder builder) {
    builder.append(displayName);
    if (_bound != null) {
      builder.append(" extends ");
      builder.append(_bound);
    }
  }
}

/**
 * Instances of the class `VariableElementImpl` implement a `VariableElement`.
 *
 * @coverage dart.engine.element
 */
abstract class VariableElementImpl extends ElementImpl implements VariableElement {
  /**
   * The declared type of this variable.
   */
  Type2 _type;

  /**
   * A synthetic function representing this variable's initializer, or `null` if this variable
   * does not have an initializer.
   */
  FunctionElement _initializer;

  /**
   * An empty array of variable elements.
   */
  static List<VariableElement> EMPTY_ARRAY = new List<VariableElement>(0);

  /**
   * Initialize a newly created variable element to have the given name.
   *
   * @param name the name of this element
   */
  VariableElementImpl.con1(Identifier name) : super.con1(name);

  /**
   * Initialize a newly created variable element to have the given name.
   *
   * @param name the name of this element
   * @param nameOffset the offset of the name of this element in the file that contains the
   *          declaration of this element
   */
  VariableElementImpl.con2(String name, int nameOffset) : super.con2(name, nameOffset);

  /**
   * Return the result of evaluating this variable's initializer as a compile-time constant
   * expression, or `null` if this variable is not a 'const' variable or does not have an
   * initializer.
   *
   * @return the result of evaluating this variable's initializer
   */
  EvaluationResultImpl get evaluationResult => null;

  FunctionElement get initializer => _initializer;

  Type2 get type => _type;

  bool get isConst => hasModifier(Modifier.CONST);

  bool get isFinal => hasModifier(Modifier.FINAL);

  /**
   * Return `true` if this variable is potentially mutated somewhere in closure. This
   * information is only available for local variables (including parameters).
   *
   * @return `true` if this variable is potentially mutated somewhere in closure
   */
  bool get isPotentiallyMutatedInClosure => false;

  /**
   * Return `true` if this variable is potentially mutated somewhere in its scope. This
   * information is only available for local variables (including parameters).
   *
   * @return `true` if this variable is potentially mutated somewhere in its scope
   */
  bool get isPotentiallyMutatedInScope => false;

  /**
   * Set whether this variable is const to correspond to the given value.
   *
   * @param isConst `true` if the variable is const
   */
  void set const3(bool isConst) {
    setModifier(Modifier.CONST, isConst);
  }

  /**
   * Set the result of evaluating this variable's initializer as a compile-time constant expression
   * to the given result.
   *
   * @param result the result of evaluating this variable's initializer
   */
  void set evaluationResult(EvaluationResultImpl result) {
    throw new IllegalStateException("Invalid attempt to set a compile-time constant result");
  }

  /**
   * Set whether this variable is final to correspond to the given value.
   *
   * @param isFinal `true` if the variable is final
   */
  void set final2(bool isFinal) {
    setModifier(Modifier.FINAL, isFinal);
  }

  /**
   * Set the function representing this variable's initializer to the given function.
   *
   * @param initializer the function representing this variable's initializer
   */
  void set initializer(FunctionElement initializer) {
    if (initializer != null) {
      (initializer as FunctionElementImpl).enclosingElement = this;
    }
    this._initializer = initializer;
  }

  /**
   * Set the declared type of this variable to the given type.
   *
   * @param type the declared type of this variable
   */
  void set type(Type2 type) {
    this._type = type;
  }

  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChild(_initializer, visitor);
  }

  void appendTo(JavaStringBuilder builder) {
    builder.append(type);
    builder.append(" ");
    builder.append(displayName);
  }
}

/**
 * Instances of the class `ConstructorMember` represent a constructor element defined in a
 * parameterized type where the values of the type parameters are known.
 */
class ConstructorMember extends ExecutableMember implements ConstructorElement {
  /**
   * If the given constructor's type is different when any type parameters from the defining type's
   * declaration are replaced with the actual type arguments from the defining type, create a
   * constructor member representing the given constructor. Return the member that was created, or
   * the base constructor if no member was created.
   *
   * @param baseConstructor the base constructor for which a member might be created
   * @param definingType the type defining the parameters and arguments to be used in the
   *          substitution
   * @return the constructor element that will return the correctly substituted types
   */
  static ConstructorElement from(ConstructorElement baseConstructor, InterfaceType definingType) {
    if (baseConstructor == null || definingType.typeArguments.length == 0) {
      return baseConstructor;
    }
    FunctionType baseType = baseConstructor.type;
    if (baseType == null) {
      return baseConstructor;
    }
    List<Type2> argumentTypes = definingType.typeArguments;
    List<Type2> parameterTypes = definingType.element.type.typeArguments;
    FunctionType substitutedType = baseType.substitute2(argumentTypes, parameterTypes);
    if (baseType == substitutedType) {
      return baseConstructor;
    }
    return new ConstructorMember(baseConstructor, definingType);
  }

  /**
   * Initialize a newly created element to represent a constructor of the given parameterized type.
   *
   * @param baseElement the element on which the parameterized element was created
   * @param definingType the type in which the element is defined
   */
  ConstructorMember(ConstructorElement baseElement, InterfaceType definingType) : super(baseElement, definingType);

  accept(ElementVisitor visitor) => visitor.visitConstructorElement(this);

  ConstructorElement get baseElement => super.baseElement as ConstructorElement;

  ClassElement get enclosingElement => baseElement.enclosingElement;

  ConstructorElement get redirectedConstructor => from(baseElement.redirectedConstructor, definingType);

  bool get isConst => baseElement.isConst;

  bool get isDefaultConstructor => baseElement.isDefaultConstructor;

  bool get isFactory => baseElement.isFactory;

  String toString() {
    ConstructorElement baseElement = this.baseElement;
    List<ParameterElement> parameters = this.parameters;
    FunctionType type = this.type;
    JavaStringBuilder builder = new JavaStringBuilder();
    builder.append(baseElement.enclosingElement.displayName);
    String name = displayName;
    if (name != null && !name.isEmpty) {
      builder.append(".");
      builder.append(name);
    }
    builder.append("(");
    int parameterCount = parameters.length;
    for (int i = 0; i < parameterCount; i++) {
      if (i > 0) {
        builder.append(", ");
      }
      builder.append(parameters[i]).toString();
    }
    builder.append(")");
    if (type != null) {
      builder.append(Element.RIGHT_ARROW);
      builder.append(type.returnType);
    }
    return builder.toString();
  }

  InterfaceType get definingType => super.definingType as InterfaceType;
}

/**
 * The abstract class `ExecutableMember` defines the behavior common to members that represent
 * an executable element defined in a parameterized type where the values of the type parameters are
 * known.
 */
abstract class ExecutableMember extends Member implements ExecutableElement {
  /**
   * Initialize a newly created element to represent an executable element of the given
   * parameterized type.
   *
   * @param baseElement the element on which the parameterized element was created
   * @param definingType the type in which the element is defined
   */
  ExecutableMember(ExecutableElement baseElement, InterfaceType definingType) : super(baseElement, definingType);

  ExecutableElement get baseElement => super.baseElement as ExecutableElement;

  List<FunctionElement> get functions {
    throw new UnsupportedOperationException();
  }

  List<LabelElement> get labels => baseElement.labels;

  List<LocalVariableElement> get localVariables {
    throw new UnsupportedOperationException();
  }

  List<ParameterElement> get parameters {
    List<ParameterElement> baseParameters = baseElement.parameters;
    int parameterCount = baseParameters.length;
    if (parameterCount == 0) {
      return baseParameters;
    }
    List<ParameterElement> parameterizedParameters = new List<ParameterElement>(parameterCount);
    for (int i = 0; i < parameterCount; i++) {
      parameterizedParameters[i] = ParameterMember.from(baseParameters[i], definingType);
    }
    return parameterizedParameters;
  }

  Type2 get returnType => substituteFor(baseElement.returnType);

  FunctionType get type => substituteFor(baseElement.type);

  bool get isOperator => baseElement.isOperator;

  bool get isStatic => baseElement.isStatic;

  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChildren(baseElement.functions, visitor);
    safelyVisitChildren(labels, visitor);
    safelyVisitChildren(baseElement.localVariables, visitor);
    safelyVisitChildren(parameters, visitor);
  }
}

/**
 * Instances of the class `FieldFormalParameterMember` represent a parameter element defined
 * in a parameterized type where the values of the type parameters are known.
 */
class FieldFormalParameterMember extends ParameterMember implements FieldFormalParameterElement {
  /**
   * Initialize a newly created element to represent a parameter of the given parameterized type.
   *
   * @param baseElement the element on which the parameterized element was created
   * @param definingType the type in which the element is defined
   */
  FieldFormalParameterMember(FieldFormalParameterElement baseElement, ParameterizedType definingType) : super(baseElement, definingType);

  accept(ElementVisitor visitor) => visitor.visitFieldFormalParameterElement(this);

  FieldElement get field => (baseElement as FieldFormalParameterElement).field;
}

/**
 * Instances of the class `FieldMember` represent a field element defined in a parameterized
 * type where the values of the type parameters are known.
 */
class FieldMember extends VariableMember implements FieldElement {
  /**
   * If the given field's type is different when any type parameters from the defining type's
   * declaration are replaced with the actual type arguments from the defining type, create a field
   * member representing the given field. Return the member that was created, or the base field if
   * no member was created.
   *
   * @param baseField the base field for which a member might be created
   * @param definingType the type defining the parameters and arguments to be used in the
   *          substitution
   * @return the field element that will return the correctly substituted types
   */
  static FieldElement from(FieldElement baseField, InterfaceType definingType) {
    if (baseField == null || definingType.typeArguments.length == 0) {
      return baseField;
    }
    Type2 baseType = baseField.type;
    if (baseType == null) {
      return baseField;
    }
    List<Type2> argumentTypes = definingType.typeArguments;
    List<Type2> parameterTypes = definingType.element.type.typeArguments;
    Type2 substitutedType = baseType.substitute2(argumentTypes, parameterTypes);
    if (baseType == substitutedType) {
      return baseField;
    }
    return new FieldMember(baseField, definingType);
  }

  /**
   * Initialize a newly created element to represent a field of the given parameterized type.
   *
   * @param baseElement the element on which the parameterized element was created
   * @param definingType the type in which the element is defined
   */
  FieldMember(FieldElement baseElement, InterfaceType definingType) : super(baseElement, definingType);

  accept(ElementVisitor visitor) => visitor.visitFieldElement(this);

  FieldElement get baseElement => super.baseElement as FieldElement;

  ClassElement get enclosingElement => baseElement.enclosingElement;

  PropertyAccessorElement get getter => PropertyAccessorMember.from(baseElement.getter, definingType);

  PropertyAccessorElement get setter => PropertyAccessorMember.from(baseElement.setter, definingType);

  bool get isStatic => baseElement.isStatic;

  InterfaceType get definingType => super.definingType as InterfaceType;
}

/**
 * The abstract class `Member` defines the behavior common to elements that represent members
 * of parameterized types.
 */
abstract class Member implements Element {
  /**
   * The element on which the parameterized element was created.
   */
  Element _baseElement;

  /**
   * The type in which the element is defined.
   */
  ParameterizedType _definingType;

  /**
   * Initialize a newly created element to represent the member of the given parameterized type.
   *
   * @param baseElement the element on which the parameterized element was created
   * @param definingType the type in which the element is defined
   */
  Member(Element baseElement, ParameterizedType definingType) {
    this._baseElement = baseElement;
    this._definingType = definingType;
  }

  String computeDocumentationComment() => _baseElement.computeDocumentationComment();

  Element getAncestor(Type elementClass) => baseElement.getAncestor(elementClass);

  /**
   * Return the element on which the parameterized element was created.
   *
   * @return the element on which the parameterized element was created
   */
  Element get baseElement => _baseElement;

  AnalysisContext get context => _baseElement.context;

  String get displayName => _baseElement.displayName;

  ElementKind get kind => _baseElement.kind;

  LibraryElement get library => _baseElement.library;

  ElementLocation get location => _baseElement.location;

  List<ElementAnnotation> get metadata => _baseElement.metadata;

  String get name => _baseElement.name;

  int get nameOffset => _baseElement.nameOffset;

  Source get source => _baseElement.source;

  bool isAccessibleIn(LibraryElement library) => _baseElement.isAccessibleIn(library);

  bool get isDeprecated => _baseElement.isDeprecated;

  bool get isSynthetic => _baseElement.isSynthetic;

  void visitChildren(ElementVisitor visitor) {
  }

  /**
   * Return the type in which the element is defined.
   *
   * @return the type in which the element is defined
   */
  ParameterizedType get definingType => _definingType;

  /**
   * If the given child is not `null`, use the given visitor to visit it.
   *
   * @param child the child to be visited
   * @param visitor the visitor to be used to visit the child
   */
  void safelyVisitChild(Element child, ElementVisitor visitor) {
    if (child != null) {
      child.accept(visitor);
    }
  }

  /**
   * Use the given visitor to visit all of the children in the given array.
   *
   * @param children the children to be visited
   * @param visitor the visitor being used to visit the children
   */
  void safelyVisitChildren(List<Element> children, ElementVisitor visitor) {
    if (children != null) {
      for (Element child in children) {
        child.accept(visitor);
      }
    }
  }

  /**
   * Return the type that results from replacing the type parameters in the given type with the type
   * arguments.
   *
   * @param type the type to be transformed
   * @return the result of transforming the type
   */
  Type2 substituteFor(Type2 type) {
    List<Type2> argumentTypes = _definingType.typeArguments;
    List<Type2> parameterTypes = TypeParameterTypeImpl.getTypes(_definingType.typeParameters);
    return type.substitute2(argumentTypes, parameterTypes) as Type2;
  }

  /**
   * Return the array of types that results from replacing the type parameters in the given types
   * with the type arguments.
   *
   * @param types the types to be transformed
   * @return the result of transforming the types
   */
  List<InterfaceType> substituteFor2(List<InterfaceType> types) {
    int count = types.length;
    List<InterfaceType> substitutedTypes = new List<InterfaceType>(count);
    for (int i = 0; i < count; i++) {
      substitutedTypes[i] = substituteFor(types[i]);
    }
    return substitutedTypes;
  }
}

/**
 * Instances of the class `MethodMember` represent a method element defined in a parameterized
 * type where the values of the type parameters are known.
 */
class MethodMember extends ExecutableMember implements MethodElement {
  /**
   * If the given method's type is different when any type parameters from the defining type's
   * declaration are replaced with the actual type arguments from the defining type, create a method
   * member representing the given method. Return the member that was created, or the base method if
   * no member was created.
   *
   * @param baseMethod the base method for which a member might be created
   * @param definingType the type defining the parameters and arguments to be used in the
   *          substitution
   * @return the method element that will return the correctly substituted types
   */
  static MethodElement from(MethodElement baseMethod, InterfaceType definingType) {
    if (baseMethod == null || definingType.typeArguments.length == 0) {
      return baseMethod;
    }
    FunctionType baseType = baseMethod.type;
    List<Type2> argumentTypes = definingType.typeArguments;
    List<Type2> parameterTypes = definingType.element.type.typeArguments;
    FunctionType substitutedType = baseType.substitute2(argumentTypes, parameterTypes);
    if (baseType == substitutedType) {
      return baseMethod;
    }
    return new MethodMember(baseMethod, definingType);
  }

  /**
   * Initialize a newly created element to represent a method of the given parameterized type.
   *
   * @param baseElement the element on which the parameterized element was created
   * @param definingType the type in which the element is defined
   */
  MethodMember(MethodElement baseElement, InterfaceType definingType) : super(baseElement, definingType);

  accept(ElementVisitor visitor) => visitor.visitMethodElement(this);

  MethodElement get baseElement => super.baseElement as MethodElement;

  ClassElement get enclosingElement => baseElement.enclosingElement;

  bool get isAbstract => baseElement.isAbstract;

  String toString() {
    MethodElement baseElement = this.baseElement;
    List<ParameterElement> parameters = this.parameters;
    FunctionType type = this.type;
    JavaStringBuilder builder = new JavaStringBuilder();
    builder.append(baseElement.enclosingElement.displayName);
    builder.append(".");
    builder.append(baseElement.displayName);
    builder.append("(");
    int parameterCount = parameters.length;
    for (int i = 0; i < parameterCount; i++) {
      if (i > 0) {
        builder.append(", ");
      }
      builder.append(parameters[i]).toString();
    }
    builder.append(")");
    if (type != null) {
      builder.append(Element.RIGHT_ARROW);
      builder.append(type.returnType);
    }
    return builder.toString();
  }
}

/**
 * Instances of the class `ParameterMember` represent a parameter element defined in a
 * parameterized type where the values of the type parameters are known.
 */
class ParameterMember extends VariableMember implements ParameterElement {
  /**
   * If the given parameter's type is different when any type parameters from the defining type's
   * declaration are replaced with the actual type arguments from the defining type, create a
   * parameter member representing the given parameter. Return the member that was created, or the
   * base parameter if no member was created.
   *
   * @param baseParameter the base parameter for which a member might be created
   * @param definingType the type defining the parameters and arguments to be used in the
   *          substitution
   * @return the parameter element that will return the correctly substituted types
   */
  static ParameterElement from(ParameterElement baseParameter, ParameterizedType definingType) {
    if (baseParameter == null || definingType.typeArguments.length == 0) {
      return baseParameter;
    }
    bool isFieldFormal = baseParameter is FieldFormalParameterElement;
    if (!isFieldFormal) {
      Type2 baseType = baseParameter.type;
      List<Type2> argumentTypes = definingType.typeArguments;
      List<Type2> parameterTypes = TypeParameterTypeImpl.getTypes(definingType.typeParameters);
      Type2 substitutedType = baseType.substitute2(argumentTypes, parameterTypes);
      if (baseType == substitutedType) {
        return baseParameter;
      }
    }
    if (isFieldFormal) {
      return new FieldFormalParameterMember(baseParameter as FieldFormalParameterElement, definingType);
    }
    return new ParameterMember(baseParameter, definingType);
  }

  /**
   * Initialize a newly created element to represent a parameter of the given parameterized type.
   *
   * @param baseElement the element on which the parameterized element was created
   * @param definingType the type in which the element is defined
   */
  ParameterMember(ParameterElement baseElement, ParameterizedType definingType) : super(baseElement, definingType);

  accept(ElementVisitor visitor) => visitor.visitParameterElement(this);

  Element getAncestor(Type elementClass) {
    Element element = baseElement.getAncestor(elementClass);
    ParameterizedType definingType = this.definingType;
    if (definingType is InterfaceType) {
      InterfaceType definingInterfaceType = definingType as InterfaceType;
      if (element is ConstructorElement) {
        return ConstructorMember.from(element as ConstructorElement, definingInterfaceType) as Element;
      } else if (element is MethodElement) {
        return MethodMember.from(element as MethodElement, definingInterfaceType) as Element;
      } else if (element is PropertyAccessorElement) {
        return PropertyAccessorMember.from(element as PropertyAccessorElement, definingInterfaceType) as Element;
      }
    }
    return element;
  }

  ParameterElement get baseElement => super.baseElement as ParameterElement;

  SourceRange get defaultValueRange => baseElement.defaultValueRange;

  Element get enclosingElement => baseElement.enclosingElement;

  ParameterKind get parameterKind => baseElement.parameterKind;

  List<ParameterElement> get parameters {
    List<ParameterElement> baseParameters = baseElement.parameters;
    int parameterCount = baseParameters.length;
    if (parameterCount == 0) {
      return baseParameters;
    }
    List<ParameterElement> parameterizedParameters = new List<ParameterElement>(parameterCount);
    for (int i = 0; i < parameterCount; i++) {
      parameterizedParameters[i] = ParameterMember.from(baseParameters[i], definingType);
    }
    return parameterizedParameters;
  }

  SourceRange get visibleRange => baseElement.visibleRange;

  bool get isInitializingFormal => baseElement.isInitializingFormal;

  String toString() {
    ParameterElement baseElement = this.baseElement;
    String left = "";
    String right = "";
    while (true) {
      if (baseElement.parameterKind == ParameterKind.NAMED) {
        left = "{";
        right = "}";
      } else if (baseElement.parameterKind == ParameterKind.POSITIONAL) {
        left = "[";
        right = "]";
      }
      break;
    }
    JavaStringBuilder builder = new JavaStringBuilder();
    builder.append(left);
    builder.append(type);
    builder.append(" ");
    builder.append(baseElement.displayName);
    builder.append(right);
    return builder.toString();
  }

  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChildren(parameters, visitor);
  }
}

/**
 * Instances of the class `PropertyAccessorMember` represent a property accessor element
 * defined in a parameterized type where the values of the type parameters are known.
 */
class PropertyAccessorMember extends ExecutableMember implements PropertyAccessorElement {
  /**
   * If the given property accessor's type is different when any type parameters from the defining
   * type's declaration are replaced with the actual type arguments from the defining type, create a
   * property accessor member representing the given property accessor. Return the member that was
   * created, or the base accessor if no member was created.
   *
   * @param baseAccessor the base property accessor for which a member might be created
   * @param definingType the type defining the parameters and arguments to be used in the
   *          substitution
   * @return the property accessor element that will return the correctly substituted types
   */
  static PropertyAccessorElement from(PropertyAccessorElement baseAccessor, InterfaceType definingType) {
    if (baseAccessor == null || definingType.typeArguments.length == 0) {
      return baseAccessor;
    }
    FunctionType baseType = baseAccessor.type;
    List<Type2> argumentTypes = definingType.typeArguments;
    List<Type2> parameterTypes = definingType.element.type.typeArguments;
    FunctionType substitutedType = baseType.substitute2(argumentTypes, parameterTypes);
    if (baseType == substitutedType) {
      return baseAccessor;
    }
    return new PropertyAccessorMember(baseAccessor, definingType);
  }

  /**
   * Initialize a newly created element to represent a property accessor of the given parameterized
   * type.
   *
   * @param baseElement the element on which the parameterized element was created
   * @param definingType the type in which the element is defined
   */
  PropertyAccessorMember(PropertyAccessorElement baseElement, InterfaceType definingType) : super(baseElement, definingType);

  accept(ElementVisitor visitor) => visitor.visitPropertyAccessorElement(this);

  PropertyAccessorElement get baseElement => super.baseElement as PropertyAccessorElement;

  PropertyAccessorElement get correspondingGetter => from(baseElement.correspondingGetter, definingType);

  PropertyAccessorElement get correspondingSetter => from(baseElement.correspondingSetter, definingType);

  Element get enclosingElement => baseElement.enclosingElement;

  PropertyInducingElement get variable {
    PropertyInducingElement variable = baseElement.variable;
    if (variable is FieldElement) {
      return FieldMember.from(variable as FieldElement, definingType);
    }
    return variable;
  }

  bool get isAbstract => baseElement.isAbstract;

  bool get isGetter => baseElement.isGetter;

  bool get isSetter => baseElement.isSetter;

  String toString() {
    PropertyAccessorElement baseElement = this.baseElement;
    List<ParameterElement> parameters = this.parameters;
    FunctionType type = this.type;
    JavaStringBuilder builder = new JavaStringBuilder();
    if (isGetter) {
      builder.append("get ");
    } else {
      builder.append("set ");
    }
    builder.append(baseElement.enclosingElement.displayName);
    builder.append(".");
    builder.append(baseElement.displayName);
    builder.append("(");
    int parameterCount = parameters.length;
    for (int i = 0; i < parameterCount; i++) {
      if (i > 0) {
        builder.append(", ");
      }
      builder.append(parameters[i]).toString();
    }
    builder.append(")");
    if (type != null) {
      builder.append(Element.RIGHT_ARROW);
      builder.append(type.returnType);
    }
    return builder.toString();
  }

  InterfaceType get definingType => super.definingType as InterfaceType;
}

/**
 * The abstract class `VariableMember` defines the behavior common to members that represent a
 * variable element defined in a parameterized type where the values of the type parameters are
 * known.
 */
abstract class VariableMember extends Member implements VariableElement {
  /**
   * Initialize a newly created element to represent an executable element of the given
   * parameterized type.
   *
   * @param baseElement the element on which the parameterized element was created
   * @param definingType the type in which the element is defined
   */
  VariableMember(VariableElement baseElement, ParameterizedType definingType) : super(baseElement, definingType);

  VariableElement get baseElement => super.baseElement as VariableElement;

  FunctionElement get initializer {
    throw new UnsupportedOperationException();
  }

  Type2 get type => substituteFor(baseElement.type);

  bool get isConst => baseElement.isConst;

  bool get isFinal => baseElement.isFinal;

  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChild(baseElement.initializer, visitor);
  }
}

/**
 * The unique instance of the class `BottomTypeImpl` implements the type `bottom`.
 *
 * @coverage dart.engine.type
 */
class BottomTypeImpl extends TypeImpl {
  /**
   * The unique instance of this class.
   */
  static final BottomTypeImpl instance = new BottomTypeImpl();

  /**
   * Prevent the creation of instances of this class.
   */
  BottomTypeImpl() : super(null, "<bottom>");

  bool operator ==(Object object) => identical(object, this);

  bool get isBottom => true;

  bool isSupertypeOf(Type2 type) => false;

  BottomTypeImpl substitute2(List<Type2> argumentTypes, List<Type2> parameterTypes) => this;

  bool internalIsMoreSpecificThan(Type2 type, bool withDynamic, Set<TypeImpl_TypePair> visitedTypePairs) => true;

  bool internalIsSubtypeOf(Type2 type, Set<TypeImpl_TypePair> visitedTypePairs) => true;
}

/**
 * The unique instance of the class `DynamicTypeImpl` implements the type `dynamic`.
 *
 * @coverage dart.engine.type
 */
class DynamicTypeImpl extends TypeImpl {
  /**
   * The unique instance of this class.
   */
  static final DynamicTypeImpl instance = new DynamicTypeImpl();

  /**
   * Prevent the creation of instances of this class.
   */
  DynamicTypeImpl() : super(new DynamicElementImpl(), Keyword.DYNAMIC.syntax) {
    (element as DynamicElementImpl).type = this;
  }

  bool operator ==(Object object) => object is DynamicTypeImpl;

  bool get isDynamic => true;

  bool isSupertypeOf(Type2 type) => true;

  Type2 substitute2(List<Type2> argumentTypes, List<Type2> parameterTypes) {
    int length = parameterTypes.length;
    for (int i = 0; i < length; i++) {
      if (parameterTypes[i] == this) {
        return argumentTypes[i];
      }
    }
    return this;
  }

  bool internalIsMoreSpecificThan(Type2 type, bool withDynamic, Set<TypeImpl_TypePair> visitedTypePairs) {
    if (identical(this, type)) {
      return true;
    }
    return withDynamic;
  }

  bool internalIsSubtypeOf(Type2 type, Set<TypeImpl_TypePair> visitedTypePairs) => true;
}

/**
 * Instances of the class `FunctionTypeImpl` defines the behavior common to objects
 * representing the type of a function, method, constructor, getter, or setter.
 *
 * @coverage dart.engine.type
 */
class FunctionTypeImpl extends TypeImpl implements FunctionType {
  /**
   * Return `true` if all of the name/type pairs in the first map are equal to the
   * corresponding name/type pairs in the second map. The maps are expected to iterate over their
   * entries in the same order in which those entries were added to the map.
   *
   * @param firstTypes the first map of name/type pairs being compared
   * @param secondTypes the second map of name/type pairs being compared
   * @return `true` if all of the name/type pairs in the first map are equal to the
   *         corresponding name/type pairs in the second map
   */
  static bool equals2(Map<String, Type2> firstTypes, Map<String, Type2> secondTypes) {
    if (secondTypes.length != firstTypes.length) {
      return false;
    }
    JavaIterator<MapEntry<String, Type2>> firstIterator = new JavaIterator(getMapEntrySet(firstTypes));
    JavaIterator<MapEntry<String, Type2>> secondIterator = new JavaIterator(getMapEntrySet(secondTypes));
    while (firstIterator.hasNext) {
      MapEntry<String, Type2> firstEntry = firstIterator.next();
      MapEntry<String, Type2> secondEntry = secondIterator.next();
      if (firstEntry.getKey() != secondEntry.getKey() || firstEntry.getValue() != secondEntry.getValue()) {
        return false;
      }
    }
    return true;
  }

  /**
   * An array containing the actual types of the type arguments.
   */
  List<Type2> _typeArguments = TypeImpl.EMPTY_ARRAY;

  /**
   * Initialize a newly created function type to be declared by the given element and to have the
   * given name.
   *
   * @param element the element representing the declaration of the function type
   */
  FunctionTypeImpl.con1(ExecutableElement element) : super(element, element == null ? null : element.name);

  /**
   * Initialize a newly created function type to be declared by the given element and to have the
   * given name.
   *
   * @param element the element representing the declaration of the function type
   */
  FunctionTypeImpl.con2(FunctionTypeAliasElement element) : super(element, element == null ? null : element.name);

  bool operator ==(Object object) {
    if (object is! FunctionTypeImpl) {
      return false;
    }
    FunctionTypeImpl otherType = object as FunctionTypeImpl;
    return (element == otherType.element) && JavaArrays.equals(normalParameterTypes, otherType.normalParameterTypes) && JavaArrays.equals(optionalParameterTypes, otherType.optionalParameterTypes) && equals2(namedParameterTypes, otherType.namedParameterTypes) && (returnType == otherType.returnType);
  }

  String get displayName {
    String name = this.name;
    if (name == null || name.length == 0) {
      List<Type2> normalParameterTypes = this.normalParameterTypes;
      List<Type2> optionalParameterTypes = this.optionalParameterTypes;
      Map<String, Type2> namedParameterTypes = this.namedParameterTypes;
      Type2 returnType = this.returnType;
      JavaStringBuilder builder = new JavaStringBuilder();
      builder.append("(");
      bool needsComma = false;
      if (normalParameterTypes.length > 0) {
        for (Type2 type in normalParameterTypes) {
          if (needsComma) {
            builder.append(", ");
          } else {
            needsComma = true;
          }
          builder.append(type.displayName);
        }
      }
      if (optionalParameterTypes.length > 0) {
        if (needsComma) {
          builder.append(", ");
          needsComma = false;
        }
        builder.append("[");
        for (Type2 type in optionalParameterTypes) {
          if (needsComma) {
            builder.append(", ");
          } else {
            needsComma = true;
          }
          builder.append(type.displayName);
        }
        builder.append("]");
        needsComma = true;
      }
      if (namedParameterTypes.length > 0) {
        if (needsComma) {
          builder.append(", ");
          needsComma = false;
        }
        builder.append("{");
        for (MapEntry<String, Type2> entry in getMapEntrySet(namedParameterTypes)) {
          if (needsComma) {
            builder.append(", ");
          } else {
            needsComma = true;
          }
          builder.append(entry.getKey());
          builder.append(": ");
          builder.append(entry.getValue().displayName);
        }
        builder.append("}");
        needsComma = true;
      }
      builder.append(")");
      builder.append(Element.RIGHT_ARROW);
      if (returnType == null) {
        builder.append("null");
      } else {
        builder.append(returnType.displayName);
      }
      name = builder.toString();
    }
    return name;
  }

  Map<String, Type2> get namedParameterTypes {
    LinkedHashMap<String, Type2> namedParameterTypes = new LinkedHashMap<String, Type2>();
    List<ParameterElement> parameters = baseParameters;
    if (parameters.length == 0) {
      return namedParameterTypes;
    }
    List<Type2> typeParameters = TypeParameterTypeImpl.getTypes(this.typeParameters);
    for (ParameterElement parameter in parameters) {
      if (identical(parameter.parameterKind, ParameterKind.NAMED)) {
        namedParameterTypes[parameter.name] = parameter.type.substitute2(_typeArguments, typeParameters);
      }
    }
    return namedParameterTypes;
  }

  List<Type2> get normalParameterTypes {
    List<ParameterElement> parameters = baseParameters;
    if (parameters.length == 0) {
      return TypeImpl.EMPTY_ARRAY;
    }
    List<Type2> typeParameters = TypeParameterTypeImpl.getTypes(this.typeParameters);
    List<Type2> types = new List<Type2>();
    for (ParameterElement parameter in parameters) {
      if (identical(parameter.parameterKind, ParameterKind.REQUIRED)) {
        types.add(parameter.type.substitute2(_typeArguments, typeParameters));
      }
    }
    return new List.from(types);
  }

  List<Type2> get optionalParameterTypes {
    List<ParameterElement> parameters = baseParameters;
    if (parameters.length == 0) {
      return TypeImpl.EMPTY_ARRAY;
    }
    List<Type2> typeParameters = TypeParameterTypeImpl.getTypes(this.typeParameters);
    List<Type2> types = new List<Type2>();
    for (ParameterElement parameter in parameters) {
      if (identical(parameter.parameterKind, ParameterKind.POSITIONAL)) {
        types.add(parameter.type.substitute2(_typeArguments, typeParameters));
      }
    }
    return new List.from(types);
  }

  List<ParameterElement> get parameters {
    List<ParameterElement> baseParameters = this.baseParameters;
    int parameterCount = baseParameters.length;
    if (parameterCount == 0) {
      return baseParameters;
    }
    List<ParameterElement> specializedParameters = new List<ParameterElement>(parameterCount);
    for (int i = 0; i < parameterCount; i++) {
      specializedParameters[i] = ParameterMember.from(baseParameters[i], this);
    }
    return specializedParameters;
  }

  Type2 get returnType {
    Type2 baseReturnType = this.baseReturnType;
    if (baseReturnType == null) {
      return DynamicTypeImpl.instance;
    }
    return baseReturnType.substitute2(_typeArguments, TypeParameterTypeImpl.getTypes(typeParameters));
  }

  List<Type2> get typeArguments => _typeArguments;

  List<TypeParameterElement> get typeParameters {
    Element element = this.element;
    if (element is FunctionTypeAliasElement) {
      return (element as FunctionTypeAliasElement).typeParameters;
    }
    ClassElement definingClass = element.getAncestor(ClassElement);
    if (definingClass != null) {
      return definingClass.typeParameters;
    }
    return TypeParameterElementImpl.EMPTY_ARRAY;
  }

  int get hashCode {
    Element element = this.element;
    if (element == null) {
      return 0;
    }
    return element.hashCode;
  }

  bool internalIsMoreSpecificThan(Type2 type, bool withDynamic, Set<TypeImpl_TypePair> visitedTypePairs) {
    if (type == null) {
      return false;
    } else if (identical(this, type) || type.isDynamic || type.isDartCoreFunction || type.isObject) {
      return true;
    } else if (type is! FunctionType) {
      return false;
    } else if (this == type) {
      return true;
    }
    FunctionType t = this;
    FunctionType s = type as FunctionType;
    List<Type2> tTypes = t.normalParameterTypes;
    List<Type2> tOpTypes = t.optionalParameterTypes;
    List<Type2> sTypes = s.normalParameterTypes;
    List<Type2> sOpTypes = s.optionalParameterTypes;
    if ((sOpTypes.length > 0 && t.namedParameterTypes.length > 0) || (tOpTypes.length > 0 && s.namedParameterTypes.length > 0)) {
      return false;
    }
    if (t.namedParameterTypes.length > 0) {
      if (t.normalParameterTypes.length != s.normalParameterTypes.length) {
        return false;
      } else if (t.normalParameterTypes.length > 0) {
        for (int i = 0; i < tTypes.length; i++) {
          if (!(tTypes[i] as TypeImpl).isMoreSpecificThan3(sTypes[i], withDynamic, visitedTypePairs)) {
            return false;
          }
        }
      }
      Map<String, Type2> namedTypesT = t.namedParameterTypes;
      Map<String, Type2> namedTypesS = s.namedParameterTypes;
      if (namedTypesT.length < namedTypesS.length) {
        return false;
      }
      JavaIterator<MapEntry<String, Type2>> iteratorS = new JavaIterator(getMapEntrySet(namedTypesS));
      while (iteratorS.hasNext) {
        MapEntry<String, Type2> entryS = iteratorS.next();
        Type2 typeT = namedTypesT[entryS.getKey()];
        if (typeT == null) {
          return false;
        }
        if (!(typeT as TypeImpl).isMoreSpecificThan3(entryS.getValue(), withDynamic, visitedTypePairs)) {
          return false;
        }
      }
    } else if (s.namedParameterTypes.length > 0) {
      return false;
    } else {
      int tArgLength = tTypes.length + tOpTypes.length;
      int sArgLength = sTypes.length + sOpTypes.length;
      if (tArgLength < sArgLength || sTypes.length < tTypes.length) {
        return false;
      }
      if (tOpTypes.length == 0 && sOpTypes.length == 0) {
        for (int i = 0; i < sTypes.length; i++) {
          if (!(tTypes[i] as TypeImpl).isMoreSpecificThan3(sTypes[i], withDynamic, visitedTypePairs)) {
            return false;
          }
        }
      } else {
        List<Type2> tAllTypes = new List<Type2>(sArgLength);
        for (int i = 0; i < tTypes.length; i++) {
          tAllTypes[i] = tTypes[i];
        }
        for (int i = tTypes.length, j = 0; i < sArgLength; i++, j++) {
          tAllTypes[i] = tOpTypes[j];
        }
        List<Type2> sAllTypes = new List<Type2>(sArgLength);
        for (int i = 0; i < sTypes.length; i++) {
          sAllTypes[i] = sTypes[i];
        }
        for (int i = sTypes.length, j = 0; i < sArgLength; i++, j++) {
          sAllTypes[i] = sOpTypes[j];
        }
        for (int i = 0; i < sAllTypes.length; i++) {
          if (!(tAllTypes[i] as TypeImpl).isMoreSpecificThan3(sAllTypes[i], withDynamic, visitedTypePairs)) {
            return false;
          }
        }
      }
    }
    Type2 tRetType = t.returnType;
    Type2 sRetType = s.returnType;
    return sRetType.isVoid || (tRetType as TypeImpl).isMoreSpecificThan3(sRetType, withDynamic, visitedTypePairs);
  }

  bool isAssignableTo(Type2 type) => isSubtypeOf3(type, new Set<TypeImpl_TypePair>());

  /**
   * Set the actual types of the type arguments to the given types.
   *
   * @param typeArguments the actual types of the type arguments
   */
  void set typeArguments(List<Type2> typeArguments) {
    this._typeArguments = typeArguments;
  }

  FunctionTypeImpl substitute3(List<Type2> argumentTypes) => substitute2(argumentTypes, typeArguments);

  FunctionTypeImpl substitute2(List<Type2> argumentTypes, List<Type2> parameterTypes) {
    if (argumentTypes.length != parameterTypes.length) {
      throw new IllegalArgumentException("argumentTypes.length (${argumentTypes.length}) != parameterTypes.length (${parameterTypes.length})");
    }
    if (argumentTypes.length == 0) {
      return this;
    }
    Element element = this.element;
    FunctionTypeImpl newType = (element is ExecutableElement) ? new FunctionTypeImpl.con1(element as ExecutableElement) : new FunctionTypeImpl.con2(element as FunctionTypeAliasElement);
    newType.typeArguments = TypeImpl.substitute(_typeArguments, argumentTypes, parameterTypes);
    return newType;
  }

  void appendTo(JavaStringBuilder builder) {
    List<Type2> normalParameterTypes = this.normalParameterTypes;
    List<Type2> optionalParameterTypes = this.optionalParameterTypes;
    Map<String, Type2> namedParameterTypes = this.namedParameterTypes;
    Type2 returnType = this.returnType;
    builder.append("(");
    bool needsComma = false;
    if (normalParameterTypes.length > 0) {
      for (Type2 type in normalParameterTypes) {
        if (needsComma) {
          builder.append(", ");
        } else {
          needsComma = true;
        }
        (type as TypeImpl).appendTo(builder);
      }
    }
    if (optionalParameterTypes.length > 0) {
      if (needsComma) {
        builder.append(", ");
        needsComma = false;
      }
      builder.append("[");
      for (Type2 type in optionalParameterTypes) {
        if (needsComma) {
          builder.append(", ");
        } else {
          needsComma = true;
        }
        (type as TypeImpl).appendTo(builder);
      }
      builder.append("]");
      needsComma = true;
    }
    if (namedParameterTypes.length > 0) {
      if (needsComma) {
        builder.append(", ");
        needsComma = false;
      }
      builder.append("{");
      for (MapEntry<String, Type2> entry in getMapEntrySet(namedParameterTypes)) {
        if (needsComma) {
          builder.append(", ");
        } else {
          needsComma = true;
        }
        builder.append(entry.getKey());
        builder.append(": ");
        (entry.getValue() as TypeImpl).appendTo(builder);
      }
      builder.append("}");
      needsComma = true;
    }
    builder.append(")");
    builder.append(Element.RIGHT_ARROW);
    if (returnType == null) {
      builder.append("null");
    } else {
      (returnType as TypeImpl).appendTo(builder);
    }
  }

  /**
   * @return the base parameter elements of this function element, not `null`.
   */
  List<ParameterElement> get baseParameters {
    Element element = this.element;
    if (element is ExecutableElement) {
      return (element as ExecutableElement).parameters;
    } else {
      return (element as FunctionTypeAliasElement).parameters;
    }
  }

  bool internalIsSubtypeOf(Type2 type, Set<TypeImpl_TypePair> visitedTypePairs) {
    if (type == null) {
      return false;
    } else if (identical(this, type) || type.isDynamic || type.isDartCoreFunction || type.isObject) {
      return true;
    } else if (type is! FunctionType) {
      return false;
    } else if (this == type) {
      return true;
    }
    FunctionType t = this;
    FunctionType s = type as FunctionType;
    List<Type2> tTypes = t.normalParameterTypes;
    List<Type2> tOpTypes = t.optionalParameterTypes;
    List<Type2> sTypes = s.normalParameterTypes;
    List<Type2> sOpTypes = s.optionalParameterTypes;
    if ((sOpTypes.length > 0 && t.namedParameterTypes.length > 0) || (tOpTypes.length > 0 && s.namedParameterTypes.length > 0)) {
      return false;
    }
    if (t.namedParameterTypes.length > 0) {
      if (t.normalParameterTypes.length != s.normalParameterTypes.length) {
        return false;
      } else if (t.normalParameterTypes.length > 0) {
        for (int i = 0; i < tTypes.length; i++) {
          if (!(tTypes[i] as TypeImpl).isAssignableTo2(sTypes[i], visitedTypePairs)) {
            return false;
          }
        }
      }
      Map<String, Type2> namedTypesT = t.namedParameterTypes;
      Map<String, Type2> namedTypesS = s.namedParameterTypes;
      if (namedTypesT.length < namedTypesS.length) {
        return false;
      }
      JavaIterator<MapEntry<String, Type2>> iteratorS = new JavaIterator(getMapEntrySet(namedTypesS));
      while (iteratorS.hasNext) {
        MapEntry<String, Type2> entryS = iteratorS.next();
        Type2 typeT = namedTypesT[entryS.getKey()];
        if (typeT == null) {
          return false;
        }
        if (!(typeT as TypeImpl).isAssignableTo2(entryS.getValue(), visitedTypePairs)) {
          return false;
        }
      }
    } else if (s.namedParameterTypes.length > 0) {
      return false;
    } else {
      int tArgLength = tTypes.length + tOpTypes.length;
      int sArgLength = sTypes.length + sOpTypes.length;
      if (tArgLength < sArgLength || sTypes.length < tTypes.length) {
        return false;
      }
      if (tOpTypes.length == 0 && sOpTypes.length == 0) {
        for (int i = 0; i < sTypes.length; i++) {
          if (!(tTypes[i] as TypeImpl).isAssignableTo2(sTypes[i], visitedTypePairs)) {
            return false;
          }
        }
      } else {
        List<Type2> tAllTypes = new List<Type2>(sArgLength);
        for (int i = 0; i < tTypes.length; i++) {
          tAllTypes[i] = tTypes[i];
        }
        for (int i = tTypes.length, j = 0; i < sArgLength; i++, j++) {
          tAllTypes[i] = tOpTypes[j];
        }
        List<Type2> sAllTypes = new List<Type2>(sArgLength);
        for (int i = 0; i < sTypes.length; i++) {
          sAllTypes[i] = sTypes[i];
        }
        for (int i = sTypes.length, j = 0; i < sArgLength; i++, j++) {
          sAllTypes[i] = sOpTypes[j];
        }
        for (int i = 0; i < sAllTypes.length; i++) {
          if (!(tAllTypes[i] as TypeImpl).isAssignableTo2(sAllTypes[i], visitedTypePairs)) {
            return false;
          }
        }
      }
    }
    Type2 tRetType = t.returnType;
    Type2 sRetType = s.returnType;
    return sRetType.isVoid || (tRetType as TypeImpl).isAssignableTo2(sRetType, visitedTypePairs);
  }

  /**
   * Return the return type defined by this function's element.
   *
   * @return the return type defined by this function's element
   */
  Type2 get baseReturnType {
    Element element = this.element;
    if (element is ExecutableElement) {
      return (element as ExecutableElement).returnType;
    } else {
      return (element as FunctionTypeAliasElement).returnType;
    }
  }
}

/**
 * Instances of the class `InterfaceTypeImpl` defines the behavior common to objects
 * representing the type introduced by either a class or an interface, or a reference to such a
 * type.
 *
 * @coverage dart.engine.type
 */
class InterfaceTypeImpl extends TypeImpl implements InterfaceType {
  /**
   * An empty array of types.
   */
  static List<InterfaceType> EMPTY_ARRAY = new List<InterfaceType>(0);

  /**
   * This method computes the longest inheritance path from some passed [Type] to Object.
   *
   * @param type the [Type] to compute the longest inheritance path of from the passed
   *          [Type] to Object
   * @return the computed longest inheritance path to Object
   * @see InterfaceType#getLeastUpperBound(Type)
   */
  static int computeLongestInheritancePathToObject(InterfaceType type) => computeLongestInheritancePathToObject2(type, 0, new Set<ClassElement>());

  /**
   * Returns the set of all superinterfaces of the passed [Type].
   *
   * @param type the [Type] to compute the set of superinterfaces of
   * @return the [Set] of superinterfaces of the passed [Type]
   * @see #getLeastUpperBound(Type)
   */
  static Set<InterfaceType> computeSuperinterfaceSet(InterfaceType type) => computeSuperinterfaceSet2(type, new Set<InterfaceType>());

  /**
   * This method computes the longest inheritance path from some passed [Type] to Object. This
   * method calls itself recursively, callers should use the public method
   * [computeLongestInheritancePathToObject].
   *
   * @param type the [Type] to compute the longest inheritance path of from the passed
   *          [Type] to Object
   * @param depth a field used recursively
   * @param visitedClasses the classes that have already been visited
   * @return the computed longest inheritance path to Object
   * @see #computeLongestInheritancePathToObject(Type)
   * @see #getLeastUpperBound(Type)
   */
  static int computeLongestInheritancePathToObject2(InterfaceType type, int depth, Set<ClassElement> visitedClasses) {
    ClassElement classElement = type.element;
    if (classElement.supertype == null || visitedClasses.contains(classElement)) {
      return depth;
    }
    int longestPath = 1;
    try {
      visitedClasses.add(classElement);
      List<InterfaceType> superinterfaces = classElement.interfaces;
      int pathLength;
      if (superinterfaces.length > 0) {
        for (InterfaceType superinterface in superinterfaces) {
          pathLength = computeLongestInheritancePathToObject2(superinterface, depth + 1, visitedClasses);
          if (pathLength > longestPath) {
            longestPath = pathLength;
          }
        }
      }
      InterfaceType supertype = classElement.supertype;
      pathLength = computeLongestInheritancePathToObject2(supertype, depth + 1, visitedClasses);
      if (pathLength > longestPath) {
        longestPath = pathLength;
      }
    } finally {
      visitedClasses.remove(classElement);
    }
    return longestPath;
  }

  /**
   * Returns the set of all superinterfaces of the passed [Type]. This is a recursive method,
   * callers should call the public [computeSuperinterfaceSet].
   *
   * @param type the [Type] to compute the set of superinterfaces of
   * @param set a [HashSet] used recursively by this method
   * @return the [Set] of superinterfaces of the passed [Type]
   * @see #computeSuperinterfaceSet(Type)
   * @see #getLeastUpperBound(Type)
   */
  static Set<InterfaceType> computeSuperinterfaceSet2(InterfaceType type, Set<InterfaceType> set) {
    Element element = type.element;
    if (element != null && element is ClassElement) {
      ClassElement classElement = element as ClassElement;
      List<InterfaceType> superinterfaces = classElement.interfaces;
      for (InterfaceType superinterface in superinterfaces) {
        if (set.add(superinterface)) {
          computeSuperinterfaceSet2(superinterface, set);
        }
      }
      InterfaceType supertype = classElement.supertype;
      if (supertype != null) {
        if (set.add(supertype)) {
          computeSuperinterfaceSet2(supertype, set);
        }
      }
    }
    return set;
  }

  /**
   * Return the intersection of the given sets of types, where intersection is based on the equality
   * of the elements of the types rather than on the equality of the types themselves. In cases
   * where two non-equal types have equal elements, which only happens when the class is
   * parameterized, the type that is added to the intersection is the base type with type arguments
   * that are the least upper bound of the type arguments of the two types.
   *
   * @param first the first set of types to be intersected
   * @param second the second set of types to be intersected
   * @return the intersection of the given sets of types
   */
  static List<InterfaceType> intersection(Set<InterfaceType> first, Set<InterfaceType> second) {
    Map<ClassElement, InterfaceType> firstMap = new Map<ClassElement, InterfaceType>();
    for (InterfaceType firstType in first) {
      firstMap[firstType.element] = firstType;
    }
    Set<InterfaceType> result = new Set<InterfaceType>();
    for (InterfaceType secondType in second) {
      InterfaceType firstType = firstMap[secondType.element];
      if (firstType != null) {
        result.add(leastUpperBound(firstType, secondType));
      }
    }
    return new List.from(result);
  }

  /**
   * Return the "least upper bound" of the given types under the assumption that the types have the
   * same element and differ only in terms of the type arguments. The resulting type is composed by
   * comparing the corresponding type arguments, keeping those that are the same, and using
   * 'dynamic' for those that are different.
   *
   * @param firstType the first type
   * @param secondType the second type
   * @return the "least upper bound" of the given types
   */
  static InterfaceType leastUpperBound(InterfaceType firstType, InterfaceType secondType) {
    if (firstType == secondType) {
      return firstType;
    }
    List<Type2> firstArguments = firstType.typeArguments;
    List<Type2> secondArguments = secondType.typeArguments;
    int argumentCount = firstArguments.length;
    if (argumentCount == 0) {
      return firstType;
    }
    List<Type2> lubArguments = new List<Type2>(argumentCount);
    for (int i = 0; i < argumentCount; i++) {
      if (firstArguments[i] == secondArguments[i]) {
        lubArguments[i] = firstArguments[i];
      }
      if (lubArguments[i] == null) {
        lubArguments[i] = DynamicTypeImpl.instance;
      }
    }
    InterfaceTypeImpl lub = new InterfaceTypeImpl.con1(firstType.element);
    lub.typeArguments = lubArguments;
    return lub;
  }

  /**
   * An array containing the actual types of the type arguments.
   */
  List<Type2> _typeArguments = TypeImpl.EMPTY_ARRAY;

  /**
   * Initialize a newly created type to be declared by the given element.
   *
   * @param element the element representing the declaration of the type
   */
  InterfaceTypeImpl.con1(ClassElement element) : super(element, element.displayName);

  /**
   * Initialize a newly created type to have the given name. This constructor should only be used in
   * cases where there is no declaration of the type.
   *
   * @param name the name of the type
   */
  InterfaceTypeImpl.con2(String name) : super(null, name);

  bool operator ==(Object object) {
    if (object is! InterfaceTypeImpl) {
      return false;
    }
    InterfaceTypeImpl otherType = object as InterfaceTypeImpl;
    return (element == otherType.element) && JavaArrays.equals(_typeArguments, otherType._typeArguments);
  }

  List<PropertyAccessorElement> get accessors {
    List<PropertyAccessorElement> accessors = element.accessors;
    List<PropertyAccessorElement> members = new List<PropertyAccessorElement>(accessors.length);
    for (int i = 0; i < accessors.length; i++) {
      members[i] = PropertyAccessorMember.from(accessors[i], this);
    }
    return members;
  }

  String get displayName {
    String name = this.name;
    List<Type2> typeArguments = this.typeArguments;
    bool allDynamic = true;
    for (Type2 type in typeArguments) {
      if (type != null && !type.isDynamic) {
        allDynamic = false;
        break;
      }
    }
    if (!allDynamic) {
      JavaStringBuilder builder = new JavaStringBuilder();
      builder.append(name);
      builder.append("<");
      for (int i = 0; i < typeArguments.length; i++) {
        if (i != 0) {
          builder.append(", ");
        }
        Type2 typeArg = typeArguments[i];
        builder.append(typeArg.displayName);
      }
      builder.append(">");
      name = builder.toString();
    }
    return name;
  }

  ClassElement get element => super.element as ClassElement;

  PropertyAccessorElement getGetter(String getterName) => PropertyAccessorMember.from((element as ClassElementImpl).getGetter(getterName), this);

  List<InterfaceType> get interfaces {
    ClassElement classElement = element;
    List<InterfaceType> interfaces = classElement.interfaces;
    List<TypeParameterElement> typeParameters = classElement.typeParameters;
    List<Type2> parameterTypes = classElement.type.typeArguments;
    if (typeParameters.length == 0) {
      return interfaces;
    }
    int count = interfaces.length;
    List<InterfaceType> typedInterfaces = new List<InterfaceType>(count);
    for (int i = 0; i < count; i++) {
      typedInterfaces[i] = interfaces[i].substitute2(_typeArguments, parameterTypes);
    }
    return typedInterfaces;
  }

  Type2 getLeastUpperBound(Type2 type) {
    if (identical(type, this)) {
      return this;
    }
    Type2 dynamicType = DynamicTypeImpl.instance;
    if (identical(this, dynamicType) || identical(type, dynamicType)) {
      return dynamicType;
    }
    if (type is! InterfaceType) {
      return null;
    }
    InterfaceType i = this;
    InterfaceType j = type as InterfaceType;
    Set<InterfaceType> si = computeSuperinterfaceSet(i);
    Set<InterfaceType> sj = computeSuperinterfaceSet(j);
    si.add(i);
    sj.add(j);
    List<InterfaceType> s = intersection(si, sj);
    List<int> depths = new List<int>.filled(s.length, 0);
    int maxDepth = 0;
    for (int n = 0; n < s.length; n++) {
      depths[n] = computeLongestInheritancePathToObject(s[n]);
      if (depths[n] > maxDepth) {
        maxDepth = depths[n];
      }
    }
    for (; maxDepth >= 0; maxDepth--) {
      int indexOfLeastUpperBound = -1;
      int numberOfTypesAtMaxDepth = 0;
      for (int m = 0; m < depths.length; m++) {
        if (depths[m] == maxDepth) {
          numberOfTypesAtMaxDepth++;
          indexOfLeastUpperBound = m;
        }
      }
      if (numberOfTypesAtMaxDepth == 1) {
        return s[indexOfLeastUpperBound];
      }
    }
    return null;
  }

  MethodElement getMethod(String methodName) => MethodMember.from((element as ClassElementImpl).getMethod(methodName), this);

  List<MethodElement> get methods {
    List<MethodElement> methods = element.methods;
    List<MethodElement> members = new List<MethodElement>(methods.length);
    for (int i = 0; i < methods.length; i++) {
      members[i] = MethodMember.from(methods[i], this);
    }
    return members;
  }

  List<InterfaceType> get mixins {
    ClassElement classElement = element;
    List<InterfaceType> mixins = classElement.mixins;
    List<TypeParameterElement> typeParameters = classElement.typeParameters;
    List<Type2> parameterTypes = classElement.type.typeArguments;
    if (typeParameters.length == 0) {
      return mixins;
    }
    int count = mixins.length;
    List<InterfaceType> typedMixins = new List<InterfaceType>(count);
    for (int i = 0; i < count; i++) {
      typedMixins[i] = mixins[i].substitute2(_typeArguments, parameterTypes);
    }
    return typedMixins;
  }

  PropertyAccessorElement getSetter(String setterName) => PropertyAccessorMember.from((element as ClassElementImpl).getSetter(setterName), this);

  InterfaceType get superclass {
    ClassElement classElement = element;
    InterfaceType supertype = classElement.supertype;
    if (supertype == null) {
      return null;
    }
    return supertype.substitute2(_typeArguments, classElement.type.typeArguments);
  }

  List<Type2> get typeArguments => _typeArguments;

  List<TypeParameterElement> get typeParameters => element.typeParameters;

  int get hashCode {
    ClassElement element = this.element;
    if (element == null) {
      return 0;
    }
    return element.hashCode;
  }

  bool get isDartCoreFunction {
    ClassElement element = this.element;
    if (element == null) {
      return false;
    }
    return element.name == "Function" && element.library.isDartCore;
  }

  bool isDirectSupertypeOf(InterfaceType type) {
    InterfaceType i = this;
    InterfaceType j = type;
    ClassElement jElement = j.element;
    InterfaceType supertype = jElement.supertype;
    if (supertype == null) {
      return false;
    }
    List<Type2> jArgs = j.typeArguments;
    List<Type2> jVars = jElement.type.typeArguments;
    supertype = supertype.substitute2(jArgs, jVars);
    if (supertype == i) {
      return true;
    }
    for (InterfaceType interfaceType in jElement.interfaces) {
      interfaceType = interfaceType.substitute2(jArgs, jVars);
      if (interfaceType == i) {
        return true;
      }
    }
    for (InterfaceType mixinType in jElement.mixins) {
      mixinType = mixinType.substitute2(jArgs, jVars);
      if (mixinType == i) {
        return true;
      }
    }
    return false;
  }

  bool get isObject => element.supertype == null;

  ConstructorElement lookUpConstructor(String constructorName, LibraryElement library) {
    ConstructorElement constructorElement;
    if (constructorName == null) {
      constructorElement = element.unnamedConstructor;
    } else {
      constructorElement = element.getNamedConstructor(constructorName);
    }
    if (constructorElement == null || !constructorElement.isAccessibleIn(library)) {
      return null;
    }
    return ConstructorMember.from(constructorElement, this);
  }

  PropertyAccessorElement lookUpGetter(String getterName, LibraryElement library) {
    PropertyAccessorElement element = getGetter(getterName);
    if (element != null && element.isAccessibleIn(library)) {
      return element;
    }
    return lookUpGetterInSuperclass(getterName, library);
  }

  PropertyAccessorElement lookUpGetterInSuperclass(String getterName, LibraryElement library) {
    for (InterfaceType mixin in mixins) {
      PropertyAccessorElement element = mixin.getGetter(getterName);
      if (element != null && element.isAccessibleIn(library)) {
        return element;
      }
    }
    Set<ClassElement> visitedClasses = new Set<ClassElement>();
    InterfaceType supertype = superclass;
    ClassElement supertypeElement = supertype == null ? null : supertype.element;
    while (supertype != null && !visitedClasses.contains(supertypeElement)) {
      visitedClasses.add(supertypeElement);
      PropertyAccessorElement element = supertype.getGetter(getterName);
      if (element != null && element.isAccessibleIn(library)) {
        return element;
      }
      for (InterfaceType mixin in supertype.mixins) {
        element = mixin.getGetter(getterName);
        if (element != null && element.isAccessibleIn(library)) {
          return element;
        }
      }
      supertype = supertype.superclass;
      supertypeElement = supertype == null ? null : supertype.element;
    }
    return null;
  }

  MethodElement lookUpMethod(String methodName, LibraryElement library) {
    MethodElement element = getMethod(methodName);
    if (element != null && element.isAccessibleIn(library)) {
      return element;
    }
    return lookUpMethodInSuperclass(methodName, library);
  }

  MethodElement lookUpMethodInSuperclass(String methodName, LibraryElement library) {
    for (InterfaceType mixin in mixins) {
      MethodElement element = mixin.getMethod(methodName);
      if (element != null && element.isAccessibleIn(library)) {
        return element;
      }
    }
    Set<ClassElement> visitedClasses = new Set<ClassElement>();
    InterfaceType supertype = superclass;
    ClassElement supertypeElement = supertype == null ? null : supertype.element;
    while (supertype != null && !visitedClasses.contains(supertypeElement)) {
      visitedClasses.add(supertypeElement);
      MethodElement element = supertype.getMethod(methodName);
      if (element != null && element.isAccessibleIn(library)) {
        return element;
      }
      for (InterfaceType mixin in supertype.mixins) {
        element = mixin.getMethod(methodName);
        if (element != null && element.isAccessibleIn(library)) {
          return element;
        }
      }
      supertype = supertype.superclass;
      supertypeElement = supertype == null ? null : supertype.element;
    }
    return null;
  }

  PropertyAccessorElement lookUpSetter(String setterName, LibraryElement library) {
    PropertyAccessorElement element = getSetter(setterName);
    if (element != null && element.isAccessibleIn(library)) {
      return element;
    }
    return lookUpSetterInSuperclass(setterName, library);
  }

  PropertyAccessorElement lookUpSetterInSuperclass(String setterName, LibraryElement library) {
    for (InterfaceType mixin in mixins) {
      PropertyAccessorElement element = mixin.getSetter(setterName);
      if (element != null && element.isAccessibleIn(library)) {
        return element;
      }
    }
    Set<ClassElement> visitedClasses = new Set<ClassElement>();
    InterfaceType supertype = superclass;
    ClassElement supertypeElement = supertype == null ? null : supertype.element;
    while (supertype != null && !visitedClasses.contains(supertypeElement)) {
      visitedClasses.add(supertypeElement);
      PropertyAccessorElement element = supertype.getSetter(setterName);
      if (element != null && element.isAccessibleIn(library)) {
        return element;
      }
      for (InterfaceType mixin in supertype.mixins) {
        element = mixin.getSetter(setterName);
        if (element != null && element.isAccessibleIn(library)) {
          return element;
        }
      }
      supertype = supertype.superclass;
      supertypeElement = supertype == null ? null : supertype.element;
    }
    return null;
  }

  /**
   * Set the actual types of the type arguments to those in the given array.
   *
   * @param typeArguments the actual types of the type arguments
   */
  void set typeArguments(List<Type2> typeArguments) {
    this._typeArguments = typeArguments;
  }

  InterfaceTypeImpl substitute4(List<Type2> argumentTypes) => substitute2(argumentTypes, typeArguments);

  InterfaceTypeImpl substitute2(List<Type2> argumentTypes, List<Type2> parameterTypes) {
    if (argumentTypes.length != parameterTypes.length) {
      throw new IllegalArgumentException("argumentTypes.length (${argumentTypes.length}) != parameterTypes.length (${parameterTypes.length})");
    }
    if (argumentTypes.length == 0 || _typeArguments.length == 0) {
      return this;
    }
    List<Type2> newTypeArguments = TypeImpl.substitute(_typeArguments, argumentTypes, parameterTypes);
    if (JavaArrays.equals(newTypeArguments, _typeArguments)) {
      return this;
    }
    InterfaceTypeImpl newType = new InterfaceTypeImpl.con1(element);
    newType.typeArguments = newTypeArguments;
    return newType;
  }

  void appendTo(JavaStringBuilder builder) {
    builder.append(name);
    int argumentCount = _typeArguments.length;
    if (argumentCount > 0) {
      builder.append("<");
      for (int i = 0; i < argumentCount; i++) {
        if (i > 0) {
          builder.append(", ");
        }
        (_typeArguments[i] as TypeImpl).appendTo(builder);
      }
      builder.append(">");
    }
  }

  bool internalIsMoreSpecificThan(Type2 type, bool withDynamic, Set<TypeImpl_TypePair> visitedTypePairs) {
    if (identical(type, DynamicTypeImpl.instance)) {
      return true;
    } else if (type is! InterfaceType) {
      return false;
    }
    return isMoreSpecificThan2(type as InterfaceType, new Set<ClassElement>(), withDynamic, visitedTypePairs);
  }

  bool internalIsSubtypeOf(Type2 type, Set<TypeImpl_TypePair> visitedTypePairs) {
    if (identical(type, DynamicTypeImpl.instance)) {
      return true;
    } else if (type is TypeParameterType) {
      return true;
    } else if (type is FunctionType) {
      ClassElement element = this.element;
      MethodElement callMethod = element.lookUpMethod("call", element.library);
      if (callMethod != null) {
        return callMethod.type.isSubtypeOf(type);
      }
      return false;
    } else if (type is! InterfaceType) {
      return false;
    } else if (this == type) {
      return true;
    }
    return isSubtypeOf2(type as InterfaceType, new Set<ClassElement>(), visitedTypePairs);
  }

  bool isMoreSpecificThan2(InterfaceType s, Set<ClassElement> visitedClasses, bool withDynamic, Set<TypeImpl_TypePair> visitedTypePairs) {
    if (this == s) {
      return true;
    }
    if (s.isDirectSupertypeOf(this)) {
      return true;
    }
    ClassElement tElement = this.element;
    ClassElement sElement = s.element;
    if (tElement == sElement) {
      List<Type2> tArguments = typeArguments;
      List<Type2> sArguments = s.typeArguments;
      if (tArguments.length != sArguments.length) {
        return false;
      }
      for (int i = 0; i < tArguments.length; i++) {
        if (!(tArguments[i] as TypeImpl).isMoreSpecificThan3(sArguments[i], withDynamic, visitedTypePairs)) {
          return false;
        }
      }
      return true;
    }
    ClassElement element = this.element;
    if (element == null || visitedClasses.contains(element)) {
      return false;
    }
    visitedClasses.add(element);
    InterfaceType supertype = superclass;
    if (supertype != null && (supertype as InterfaceTypeImpl).isMoreSpecificThan2(s, visitedClasses, withDynamic, visitedTypePairs)) {
      return true;
    }
    for (InterfaceType interfaceType in interfaces) {
      if ((interfaceType as InterfaceTypeImpl).isMoreSpecificThan2(s, visitedClasses, withDynamic, visitedTypePairs)) {
        return true;
      }
    }
    for (InterfaceType mixinType in mixins) {
      if ((mixinType as InterfaceTypeImpl).isMoreSpecificThan2(s, visitedClasses, withDynamic, visitedTypePairs)) {
        return true;
      }
    }
    return false;
  }

  bool isSubtypeOf2(InterfaceType type, Set<ClassElement> visitedClasses, Set<TypeImpl_TypePair> visitedTypePairs) {
    InterfaceType typeT = this;
    InterfaceType typeS = type;
    ClassElement elementT = element;
    if (elementT == null || visitedClasses.contains(elementT)) {
      return false;
    }
    visitedClasses.add(elementT);
    if (typeT == typeS) {
      return true;
    } else if (elementT == typeS.element) {
      List<Type2> typeTArgs = typeT.typeArguments;
      List<Type2> typeSArgs = typeS.typeArguments;
      if (typeTArgs.length != typeSArgs.length) {
        return false;
      }
      for (int i = 0; i < typeTArgs.length; i++) {
        if (!(typeTArgs[i] as TypeImpl).isSubtypeOf3(typeSArgs[i], visitedTypePairs)) {
          return false;
        }
      }
      return true;
    } else if (typeS.isDartCoreFunction && elementT.getMethod("call") != null) {
      return true;
    }
    InterfaceType supertype = superclass;
    if (supertype != null && (supertype as InterfaceTypeImpl).isSubtypeOf2(typeS, visitedClasses, visitedTypePairs)) {
      return true;
    }
    List<InterfaceType> interfaceTypes = interfaces;
    for (InterfaceType interfaceType in interfaceTypes) {
      if ((interfaceType as InterfaceTypeImpl).isSubtypeOf2(typeS, visitedClasses, visitedTypePairs)) {
        return true;
      }
    }
    List<InterfaceType> mixinTypes = mixins;
    for (InterfaceType mixinType in mixinTypes) {
      if ((mixinType as InterfaceTypeImpl).isSubtypeOf2(typeS, visitedClasses, visitedTypePairs)) {
        return true;
      }
    }
    return false;
  }
}

/**
 * The abstract class `TypeImpl` implements the behavior common to objects representing the
 * declared type of elements in the element model.
 *
 * @coverage dart.engine.type
 */
abstract class TypeImpl implements Type2 {
  /**
   * Return an array containing the results of using the given argument types and parameter types to
   * perform a substitution on all of the given types.
   *
   * @param types the types on which a substitution is to be performed
   * @param argumentTypes the argument types for the substitution
   * @param parameterTypes the parameter types for the substitution
   * @return the result of performing the substitution on each of the types
   */
  static List<Type2> substitute(List<Type2> types, List<Type2> argumentTypes, List<Type2> parameterTypes) {
    int length = types.length;
    if (length == 0) {
      return types;
    }
    List<Type2> newTypes = new List<Type2>(length);
    for (int i = 0; i < length; i++) {
      newTypes[i] = types[i].substitute2(argumentTypes, parameterTypes);
    }
    return newTypes;
  }

  /**
   * The element representing the declaration of this type, or `null` if the type has not, or
   * cannot, be associated with an element.
   */
  Element _element;

  /**
   * The name of this type, or `null` if the type does not have a name.
   */
  String _name;

  /**
   * An empty array of types.
   */
  static List<Type2> EMPTY_ARRAY = new List<Type2>(0);

  /**
   * Initialize a newly created type to be declared by the given element and to have the given name.
   *
   * @param element the element representing the declaration of the type
   * @param name the name of the type
   */
  TypeImpl(Element element, String name) {
    this._element = element;
    this._name = name;
  }

  String get displayName => name;

  Element get element => _element;

  Type2 getLeastUpperBound(Type2 type) => null;

  String get name => _name;

  bool isAssignableTo(Type2 type) => isAssignableTo2(type, new Set<TypeImpl_TypePair>());

  /**
   * Return `true` if this type is assignable to the given type. A type <i>T</i> may be
   * assigned to a type <i>S</i>, written <i>T</i> &hArr; <i>S</i>, iff either <i>T</i> <: <i>S</i>
   * or <i>S</i> <: <i>T</i>.
   *
   * The given set of pairs of types (T1, T2), where each pair indicates that we invoked this method
   * because we are in the process of answering the question of whether T1 is a subtype of T2, is
   * used to prevent infinite loops.
   *
   * @param type the type being compared with this type
   * @param visitedPairs the set of pairs of types used to prevent infinite loops
   * @return `true` if this type is assignable to the given type
   */
  bool isAssignableTo2(Type2 type, Set<TypeImpl_TypePair> visitedTypePairs) => isSubtypeOf3(type, visitedTypePairs) || (type as TypeImpl).isSubtypeOf3(this, visitedTypePairs);

  bool get isBottom => false;

  bool get isDartCoreFunction => false;

  bool get isDynamic => false;

  bool isMoreSpecificThan(Type2 type) => isMoreSpecificThan3(type, false, new Set<TypeImpl_TypePair>());

  /**
   * Return `true` if this type is more specific than the given type.
   *
   * The given set of pairs of types (T1, T2), where each pair indicates that we invoked this method
   * because we are in the process of answering the question of whether T1 is a subtype of T2, is
   * used to prevent infinite loops.
   *
   * @param type the type being compared with this type
   * @param withDynamic `true` if "dynamic" should be considered as a subtype of any type
   * @param visitedPairs the set of pairs of types used to prevent infinite loops
   * @return `true` if this type is more specific than the given type
   */
  bool isMoreSpecificThan3(Type2 type, bool withDynamic, Set<TypeImpl_TypePair> visitedTypePairs) {
    TypeImpl_TypePair typePair = new TypeImpl_TypePair(this, type);
    if (!visitedTypePairs.add(typePair)) {
      return false;
    }
    bool result = internalIsMoreSpecificThan(type, withDynamic, visitedTypePairs);
    visitedTypePairs.remove(typePair);
    return result;
  }

  bool get isObject => false;

  bool isSubtypeOf(Type2 type) => isSubtypeOf3(type, new Set<TypeImpl_TypePair>());

  /**
   * Return `true` if this type is a subtype of the given type.
   *
   * The given set of pairs of types (T1, T2), where each pair indicates that we invoked this method
   * because we are in the process of answering the question of whether T1 is a subtype of T2, is
   * used to prevent infinite loops.
   *
   * @param type the type being compared with this type
   * @param visitedPairs the set of pairs of types used to prevent infinite loops
   * @return `true` if this type is a subtype of the given type
   */
  bool isSubtypeOf3(Type2 type, Set<TypeImpl_TypePair> visitedTypePairs) {
    TypeImpl_TypePair typePair = new TypeImpl_TypePair(this, type);
    if (!visitedTypePairs.add(typePair)) {
      return false;
    }
    bool result = internalIsSubtypeOf(type, visitedTypePairs);
    visitedTypePairs.remove(typePair);
    return result;
  }

  bool isSupertypeOf(Type2 type) => type.isSubtypeOf(this);

  bool get isVoid => false;

  String toString() {
    JavaStringBuilder builder = new JavaStringBuilder();
    appendTo(builder);
    return builder.toString();
  }

  /**
   * Append a textual representation of this type to the given builder.
   *
   * @param builder the builder to which the text is to be appended
   */
  void appendTo(JavaStringBuilder builder) {
    if (_name == null) {
      builder.append("<unnamed type>");
    } else {
      builder.append(_name);
    }
  }

  bool internalIsMoreSpecificThan(Type2 type, bool withDynamic, Set<TypeImpl_TypePair> visitedTypePairs);

  bool internalIsSubtypeOf(Type2 type, Set<TypeImpl_TypePair> visitedTypePairs);
}

class TypeImpl_TypePair {
  Type2 _firstType;

  Type2 _secondType;

  TypeImpl_TypePair(Type2 firstType, Type2 secondType) {
    this._firstType = firstType;
    this._secondType = secondType;
  }

  bool operator ==(Object object) {
    if (identical(object, this)) {
      return true;
    }
    if (object is TypeImpl_TypePair) {
      TypeImpl_TypePair typePair = object as TypeImpl_TypePair;
      return _firstType == typePair._firstType && _secondType != null && _secondType == typePair._secondType;
    }
    return false;
  }

  int get hashCode {
    int firstHashCode = 0;
    if (_firstType != null) {
      firstHashCode = _firstType.element == null ? 0 : _firstType.element.hashCode;
    }
    int secondHashCode = 0;
    if (_secondType != null) {
      secondHashCode = _secondType.element == null ? 0 : _secondType.element.hashCode;
    }
    return firstHashCode + secondHashCode;
  }
}

/**
 * Instances of the class `TypeParameterTypeImpl` defines the behavior of objects representing
 * the type introduced by a type parameter.
 *
 * @coverage dart.engine.type
 */
class TypeParameterTypeImpl extends TypeImpl implements TypeParameterType {
  /**
   * An empty array of type parameter types.
   */
  static List<TypeParameterType> EMPTY_ARRAY = new List<TypeParameterType>(0);

  /**
   * Return an array containing the type parameter types defined by the given array of type
   * parameter elements.
   *
   * @param typeParameters the type parameter elements defining the type parameter types to be
   *          returned
   * @return the type parameter types defined by the type parameter elements
   */
  static List<TypeParameterType> getTypes(List<TypeParameterElement> typeParameters) {
    int count = typeParameters.length;
    if (count == 0) {
      return EMPTY_ARRAY;
    }
    List<TypeParameterType> types = new List<TypeParameterType>(count);
    for (int i = 0; i < count; i++) {
      types[i] = typeParameters[i].type;
    }
    return types;
  }

  /**
   * Initialize a newly created type parameter type to be declared by the given element and to have
   * the given name.
   *
   * @param element the element representing the declaration of the type parameter
   */
  TypeParameterTypeImpl(TypeParameterElement element) : super(element, element.name);

  bool operator ==(Object object) => object is TypeParameterTypeImpl && (element == (object as TypeParameterTypeImpl).element);

  TypeParameterElement get element => super.element as TypeParameterElement;

  int get hashCode => element.hashCode;

  Type2 substitute2(List<Type2> argumentTypes, List<Type2> parameterTypes) {
    int length = parameterTypes.length;
    for (int i = 0; i < length; i++) {
      if (parameterTypes[i] == this) {
        return argumentTypes[i];
      }
    }
    return this;
  }

  bool internalIsMoreSpecificThan(Type2 s, bool withDynamic, Set<TypeImpl_TypePair> visitedTypePairs) {
    if (this == s) {
      return true;
    }
    if (s.isBottom) {
      return true;
    }
    if (s.isDynamic) {
      return true;
    }
    return isMoreSpecificThan4(s, new Set<Type2>(), withDynamic, visitedTypePairs);
  }

  bool internalIsSubtypeOf(Type2 type, Set<TypeImpl_TypePair> visitedTypePairs) => isMoreSpecificThan3(type, true, new Set<TypeImpl_TypePair>());

  bool isMoreSpecificThan4(Type2 s, Set<Type2> visitedTypes, bool withDynamic, Set<TypeImpl_TypePair> visitedTypePairs) {
    Type2 bound = element.bound;
    if (s == bound) {
      return true;
    }
    if (s.isObject) {
      return true;
    }
    if (bound == null) {
      return false;
    }
    if (bound is TypeParameterTypeImpl) {
      TypeParameterTypeImpl boundTypeParameter = bound as TypeParameterTypeImpl;
      if (visitedTypes.contains(bound)) {
        return false;
      }
      visitedTypes.add(bound);
      return boundTypeParameter.isMoreSpecificThan4(s, visitedTypes, withDynamic, visitedTypePairs);
    }
    return (bound as TypeImpl).isMoreSpecificThan3(s, withDynamic, visitedTypePairs);
  }
}

/**
 * The unique instance of the class `VoidTypeImpl` implements the type `void`.
 *
 * @coverage dart.engine.type
 */
class VoidTypeImpl extends TypeImpl implements VoidType {
  /**
   * The unique instance of this class.
   */
  static final VoidTypeImpl instance = new VoidTypeImpl();

  /**
   * Prevent the creation of instances of this class.
   */
  VoidTypeImpl() : super(null, Keyword.VOID.syntax);

  bool operator ==(Object object) => identical(object, this);

  bool get isVoid => true;

  VoidTypeImpl substitute2(List<Type2> argumentTypes, List<Type2> parameterTypes) => this;

  bool internalIsMoreSpecificThan(Type2 type, bool withDynamic, Set<TypeImpl_TypePair> visitedTypePairs) => isSubtypeOf(type);

  bool internalIsSubtypeOf(Type2 type, Set<TypeImpl_TypePair> visitedTypePairs) => identical(type, this) || identical(type, DynamicTypeImpl.instance);
}

/**
 * The interface `FunctionType` defines the behavior common to objects representing the type
 * of a function, method, constructor, getter, or setter. Function types come in three variations:
 * <ol>
 * * The types of functions that only have required parameters. These have the general form
 * <i>(T<sub>1</sub>, &hellip;, T<sub>n</sub>) &rarr; T</i>.
 * * The types of functions with optional positional parameters. These have the general form
 * <i>(T<sub>1</sub>, &hellip;, T<sub>n</sub>, [T<sub>n+1</sub>, &hellip;, T<sub>n+k</sub>]) &rarr;
 * T</i>.
 * * The types of functions with named parameters. These have the general form <i>(T<sub>1</sub>,
 * &hellip;, T<sub>n</sub>, {T<sub>x1</sub> x1, &hellip;, T<sub>xk</sub> xk}) &rarr; T</i>.
 * </ol>
 *
 * @coverage dart.engine.type
 */
abstract class FunctionType implements ParameterizedType {
  /**
   * Return a map from the names of named parameters to the types of the named parameters of this
   * type of function. The entries in the map will be iterated in the same order as the order in
   * which the named parameters were defined. If there were no named parameters declared then the
   * map will be empty.
   *
   * @return a map from the name to the types of the named parameters of this type of function
   */
  Map<String, Type2> get namedParameterTypes;

  /**
   * Return an array containing the types of the normal parameters of this type of function. The
   * parameter types are in the same order as they appear in the declaration of the function.
   *
   * @return the types of the normal parameters of this type of function
   */
  List<Type2> get normalParameterTypes;

  /**
   * Return a map from the names of optional (positional) parameters to the types of the optional
   * parameters of this type of function. The entries in the map will be iterated in the same order
   * as the order in which the optional parameters were defined. If there were no optional
   * parameters declared then the map will be empty.
   *
   * @return a map from the name to the types of the optional parameters of this type of function
   */
  List<Type2> get optionalParameterTypes;

  /**
   * Return an array containing the parameters elements of this type of function. The parameter
   * types are in the same order as they appear in the declaration of the function.
   *
   * @return the parameters elements of this type of function
   */
  List<ParameterElement> get parameters;

  /**
   * Return the type of object returned by this type of function.
   *
   * @return the type of object returned by this type of function
   */
  Type2 get returnType;

  /**
   * Return `true` if this type is a subtype of the given type.
   *
   * A function type <i>(T<sub>1</sub>, &hellip;, T<sub>n</sub>) &rarr; T</i> is a subtype of the
   * function type <i>(S<sub>1</sub>, &hellip;, S<sub>n</sub>) &rarr; S</i>, if all of the following
   * conditions are met:
   *
   * * Either
   *
   * * <i>S</i> is void, or
   * * <i>T &hArr; S</i>.
   *
   *
   * * For all <i>i</i>, 1 <= <i>i</i> <= <i>n</i>, <i>T<sub>i</sub> &hArr; S<sub>i</sub></i>.
   *
   * A function type <i>(T<sub>1</sub>, &hellip;, T<sub>n</sub>, [T<sub>n+1</sub>, &hellip;,
   * T<sub>n+k</sub>]) &rarr; T</i> is a subtype of the function type <i>(S<sub>1</sub>, &hellip;,
   * S<sub>n</sub>, [S<sub>n+1</sub>, &hellip;, S<sub>n+m</sub>]) &rarr; S</i>, if all of the
   * following conditions are met:
   *
   * * Either
   *
   * * <i>S</i> is void, or
   * * <i>T &hArr; S</i>.
   *
   *
   * * <i>k</i> >= <i>m</i> and for all <i>i</i>, 1 <= <i>i</i> <= <i>n+m</i>, <i>T<sub>i</sub>
   * &hArr; S<sub>i</sub></i>.
   *
   * A function type <i>(T<sub>1</sub>, &hellip;, T<sub>n</sub>, {T<sub>x1</sub> x1, &hellip;,
   * T<sub>xk</sub> xk}) &rarr; T</i> is a subtype of the function type <i>(S<sub>1</sub>, &hellip;,
   * S<sub>n</sub>, {S<sub>y1</sub> y1, &hellip;, S<sub>ym</sub> ym}) &rarr; S</i>, if all of the
   * following conditions are met:
   *
   * * Either
   *
   * * <i>S</i> is void,
   * * or <i>T &hArr; S</i>.
   *
   *
   * * For all <i>i</i>, 1 <= <i>i</i> <= <i>n</i>, <i>T<sub>i</sub> &hArr; S<sub>i</sub></i>.
   * * <i>k</i> >= <i>m</i> and <i>y<sub>i</sub></i> in <i>{x<sub>1</sub>, &hellip;,
   * x<sub>k</sub>}</i>, 1 <= <i>i</i> <= <i>m</i>.
   * * For all <i>y<sub>i</sub></i> in <i>{y<sub>1</sub>, &hellip;, y<sub>m</sub>}</i>,
   * <i>y<sub>i</sub> = x<sub>j</sub> => Tj &hArr; Si</i>.
   *
   * In addition, the following subtype rules apply:
   *
   * <i>(T<sub>1</sub>, &hellip;, T<sub>n</sub>, []) &rarr; T <: (T<sub>1</sub>, &hellip;,
   * T<sub>n</sub>) &rarr; T.</i><br>
   * <i>(T<sub>1</sub>, &hellip;, T<sub>n</sub>) &rarr; T <: (T<sub>1</sub>, &hellip;,
   * T<sub>n</sub>, {}) &rarr; T.</i><br>
   * <i>(T<sub>1</sub>, &hellip;, T<sub>n</sub>, {}) &rarr; T <: (T<sub>1</sub>, &hellip;,
   * T<sub>n</sub>) &rarr; T.</i><br>
   * <i>(T<sub>1</sub>, &hellip;, T<sub>n</sub>) &rarr; T <: (T<sub>1</sub>, &hellip;,
   * T<sub>n</sub>, []) &rarr; T.</i>
   *
   * All functions implement the class `Function`. However not all function types are a
   * subtype of `Function`. If an interface type <i>I</i> includes a method named
   * `call()`, and the type of `call()` is the function type <i>F</i>, then <i>I</i> is
   * considered to be a subtype of <i>F</i>.
   *
   * @param type the type being compared with this type
   * @return `true` if this type is a subtype of the given type
   */
  bool isSubtypeOf(Type2 type);

  /**
   * Return the type resulting from substituting the given arguments for this type's parameters.
   * This is fully equivalent to `substitute(argumentTypes, getTypeArguments())`.
   *
   * @param argumentTypes the actual type arguments being substituted for the type parameters
   * @return the result of performing the substitution
   */
  FunctionType substitute3(List<Type2> argumentTypes);

  FunctionType substitute2(List<Type2> argumentTypes, List<Type2> parameterTypes);
}

/**
 * The interface `InterfaceType` defines the behavior common to objects representing the type
 * introduced by either a class or an interface, or a reference to such a type.
 *
 * @coverage dart.engine.type
 */
abstract class InterfaceType implements ParameterizedType {
  /**
   * Return an array containing all of the accessors (getters and setters) declared in this type.
   *
   * @return the accessors declared in this type
   */
  List<PropertyAccessorElement> get accessors;

  ClassElement get element;

  /**
   * Return the element representing the getter with the given name that is declared in this class,
   * or `null` if this class does not declare a getter with the given name.
   *
   * @param getterName the name of the getter to be returned
   * @return the getter declared in this class with the given name
   */
  PropertyAccessorElement getGetter(String getterName);

  /**
   * Return an array containing all of the interfaces that are implemented by this interface. Note
   * that this is <b>not</b>, in general, equivalent to getting the interfaces from this type's
   * element because the types returned by this method will have had their type parameters replaced.
   *
   * @return the interfaces that are implemented by this type
   */
  List<InterfaceType> get interfaces;

  /**
   * Return the least upper bound of this type and the given type, or `null` if there is no
   * least upper bound.
   *
   * Given two interfaces <i>I</i> and <i>J</i>, let <i>S<sub>I</sub></i> be the set of
   * superinterfaces of <i>I<i>, let <i>S<sub>J</sub></i> be the set of superinterfaces of <i>J</i>
   * and let <i>S = (I &cup; S<sub>I</sub>) &cap; (J &cup; S<sub>J</sub>)</i>. Furthermore, we
   * define <i>S<sub>n</sub> = {T | T &isin; S &and; depth(T) = n}</i> for any finite <i>n</i>,
   * where <i>depth(T)</i> is the number of steps in the longest inheritance path from <i>T</i> to
   * <i>Object</i>. Let <i>q</i> be the largest number such that <i>S<sub>q</sub></i> has
   * cardinality one. The least upper bound of <i>I</i> and <i>J</i> is the sole element of
   * <i>S<sub>q</sub></i>.
   *
   * @param type the other type used to compute the least upper bound
   * @return the least upper bound of this type and the given type
   */
  Type2 getLeastUpperBound(Type2 type);

  /**
   * Return the element representing the method with the given name that is declared in this class,
   * or `null` if this class does not declare a method with the given name.
   *
   * @param methodName the name of the method to be returned
   * @return the method declared in this class with the given name
   */
  MethodElement getMethod(String methodName);

  /**
   * Return an array containing all of the methods declared in this type.
   *
   * @return the methods declared in this type
   */
  List<MethodElement> get methods;

  /**
   * Return an array containing all of the mixins that are applied to the class being extended in
   * order to derive the superclass of this class. Note that this is <b>not</b>, in general,
   * equivalent to getting the mixins from this type's element because the types returned by this
   * method will have had their type parameters replaced.
   *
   * @return the mixins that are applied to derive the superclass of this class
   */
  List<InterfaceType> get mixins;

  /**
   * Return the element representing the setter with the given name that is declared in this class,
   * or `null` if this class does not declare a setter with the given name.
   *
   * @param setterName the name of the setter to be returned
   * @return the setter declared in this class with the given name
   */
  PropertyAccessorElement getSetter(String setterName);

  /**
   * Return the type representing the superclass of this type, or null if this type represents the
   * class 'Object'. Note that this is <b>not</b>, in general, equivalent to getting the superclass
   * from this type's element because the type returned by this method will have had it's type
   * parameters replaced.
   *
   * @return the superclass of this type
   */
  InterfaceType get superclass;

  /**
   * Return `true` if this type is a direct supertype of the given type. The implicit
   * interface of class <i>I</i> is a direct supertype of the implicit interface of class <i>J</i>
   * iff:
   *
   * * <i>I</i> is Object, and <i>J</i> has no extends clause.
   * * <i>I</i> is listed in the extends clause of <i>J</i>.
   * * <i>I</i> is listed in the implements clause of <i>J</i>.
   * * <i>I</i> is listed in the with clause of <i>J</i>.
   * * <i>J</i> is a mixin application of the mixin of <i>I</i>.
   *
   *
   * @param type the type being compared with this type
   * @return `true` if this type is a direct supertype of the given type
   */
  bool isDirectSupertypeOf(InterfaceType type);

  /**
   * Return `true` if this type is more specific than the given type. An interface type
   * <i>T</i> is more specific than an interface type <i>S</i>, written <i>T &laquo; S</i>, if one
   * of the following conditions is met:
   *
   * * Reflexivity: <i>T</i> is <i>S</i>.
   * * <i>T</i> is bottom.
   * * <i>S</i> is dynamic.
   * * Direct supertype: <i>S</i> is a direct supertype of <i>T</i>.
   * * <i>T</i> is a type parameter and <i>S</i> is the upper bound of <i>T</i>.
   * * Covariance: <i>T</i> is of the form <i>I&lt;T<sub>1</sub>, &hellip;, T<sub>n</sub>&gt;</i>
   * and S</i> is of the form <i>I&lt;S<sub>1</sub>, &hellip;, S<sub>n</sub>&gt;</i> and
   * <i>T<sub>i</sub> &laquo; S<sub>i</sub></i>, <i>1 <= i <= n</i>.
   * * Transitivity: <i>T &laquo; U</i> and <i>U &laquo; S</i>.
   *
   *
   * @param type the type being compared with this type
   * @return `true` if this type is more specific than the given type
   */
  bool isMoreSpecificThan(Type2 type);

  /**
   * Return `true` if this type is a subtype of the given type. An interface type <i>T</i> is
   * a subtype of an interface type <i>S</i>, written <i>T</i> <: <i>S</i>, iff
   * <i>[bottom/dynamic]T</i> &laquo; <i>S</i> (<i>T</i> is more specific than <i>S</i>). If an
   * interface type <i>I</i> includes a method named <i>call()</i>, and the type of <i>call()</i> is
   * the function type <i>F</i>, then <i>I</i> is considered to be a subtype of <i>F</i>.
   *
   * @param type the type being compared with this type
   * @return `true` if this type is a subtype of the given type
   */
  bool isSubtypeOf(Type2 type);

  /**
   * Return the element representing the constructor that results from looking up the given
   * constructor in this class with respect to the given library, or `null` if the look up
   * fails. The behavior of this method is defined by the Dart Language Specification in section
   * 12.11.1: <blockquote>If <i>e</i> is of the form <b>new</b> <i>T.id()</i> then let <i>q<i> be
   * the constructor <i>T.id</i>, otherwise let <i>q<i> be the constructor <i>T<i>. Otherwise, if
   * <i>q</i> is not defined or not accessible, a NoSuchMethodException is thrown. </blockquote>
   *
   * @param constructorName the name of the constructor being looked up
   * @param library the library with respect to which the lookup is being performed
   * @return the result of looking up the given constructor in this class with respect to the given
   *         library
   */
  ConstructorElement lookUpConstructor(String constructorName, LibraryElement library);

  /**
   * Return the element representing the getter that results from looking up the given getter in
   * this class with respect to the given library, or `null` if the look up fails. The
   * behavior of this method is defined by the Dart Language Specification in section 12.15.1:
   * <blockquote>The result of looking up getter (respectively setter) <i>m</i> in class <i>C</i>
   * with respect to library <i>L</i> is:
   *
   * * If <i>C</i> declares an instance getter (respectively setter) named <i>m</i> that is
   * accessible to <i>L</i>, then that getter (respectively setter) is the result of the lookup.
   * Otherwise, if <i>C</i> has a superclass <i>S</i>, then the result of the lookup is the result
   * of looking up getter (respectively setter) <i>m</i> in <i>S</i> with respect to <i>L</i>.
   * Otherwise, we say that the lookup has failed.
   *
   * </blockquote>
   *
   * @param getterName the name of the getter being looked up
   * @param library the library with respect to which the lookup is being performed
   * @return the result of looking up the given getter in this class with respect to the given
   *         library
   */
  PropertyAccessorElement lookUpGetter(String getterName, LibraryElement library);

  /**
   * Return the element representing the getter that results from looking up the given getter in the
   * superclass of this class with respect to the given library, or `null` if the look up
   * fails. The behavior of this method is defined by the Dart Language Specification in section
   * 12.15.1: <blockquote>The result of looking up getter (respectively setter) <i>m</i> in class
   * <i>C</i> with respect to library <i>L</i> is:
   *
   * * If <i>C</i> declares an instance getter (respectively setter) named <i>m</i> that is
   * accessible to <i>L</i>, then that getter (respectively setter) is the result of the lookup.
   * Otherwise, if <i>C</i> has a superclass <i>S</i>, then the result of the lookup is the result
   * of looking up getter (respectively setter) <i>m</i> in <i>S</i> with respect to <i>L</i>.
   * Otherwise, we say that the lookup has failed.
   *
   * </blockquote>
   *
   * @param getterName the name of the getter being looked up
   * @param library the library with respect to which the lookup is being performed
   * @return the result of looking up the given getter in this class with respect to the given
   *         library
   */
  PropertyAccessorElement lookUpGetterInSuperclass(String getterName, LibraryElement library);

  /**
   * Return the element representing the method that results from looking up the given method in
   * this class with respect to the given library, or `null` if the look up fails. The
   * behavior of this method is defined by the Dart Language Specification in section 12.15.1:
   * <blockquote> The result of looking up method <i>m</i> in class <i>C</i> with respect to library
   * <i>L</i> is:
   *
   * * If <i>C</i> declares an instance method named <i>m</i> that is accessible to <i>L</i>, then
   * that method is the result of the lookup. Otherwise, if <i>C</i> has a superclass <i>S</i>, then
   * the result of the lookup is the result of looking up method <i>m</i> in <i>S</i> with respect
   * to <i>L</i>. Otherwise, we say that the lookup has failed.
   *
   * </blockquote>
   *
   * @param methodName the name of the method being looked up
   * @param library the library with respect to which the lookup is being performed
   * @return the result of looking up the given method in this class with respect to the given
   *         library
   */
  MethodElement lookUpMethod(String methodName, LibraryElement library);

  /**
   * Return the element representing the method that results from looking up the given method in the
   * superclass of this class with respect to the given library, or `null` if the look up
   * fails. The behavior of this method is defined by the Dart Language Specification in section
   * 12.15.1: <blockquote> The result of looking up method <i>m</i> in class <i>C</i> with respect
   * to library <i>L</i> is:
   *
   * * If <i>C</i> declares an instance method named <i>m</i> that is accessible to <i>L</i>, then
   * that method is the result of the lookup. Otherwise, if <i>C</i> has a superclass <i>S</i>, then
   * the result of the lookup is the result of looking up method <i>m</i> in <i>S</i> with respect
   * to <i>L</i>. Otherwise, we say that the lookup has failed.
   *
   * </blockquote>
   *
   * @param methodName the name of the method being looked up
   * @param library the library with respect to which the lookup is being performed
   * @return the result of looking up the given method in this class with respect to the given
   *         library
   */
  MethodElement lookUpMethodInSuperclass(String methodName, LibraryElement library);

  /**
   * Return the element representing the setter that results from looking up the given setter in
   * this class with respect to the given library, or `null` if the look up fails. The
   * behavior of this method is defined by the Dart Language Specification in section 12.16:
   * <blockquote> The result of looking up getter (respectively setter) <i>m</i> in class <i>C</i>
   * with respect to library <i>L</i> is:
   *
   * * If <i>C</i> declares an instance getter (respectively setter) named <i>m</i> that is
   * accessible to <i>L</i>, then that getter (respectively setter) is the result of the lookup.
   * Otherwise, if <i>C</i> has a superclass <i>S</i>, then the result of the lookup is the result
   * of looking up getter (respectively setter) <i>m</i> in <i>S</i> with respect to <i>L</i>.
   * Otherwise, we say that the lookup has failed.
   *
   * </blockquote>
   *
   * @param setterName the name of the setter being looked up
   * @param library the library with respect to which the lookup is being performed
   * @return the result of looking up the given setter in this class with respect to the given
   *         library
   */
  PropertyAccessorElement lookUpSetter(String setterName, LibraryElement library);

  /**
   * Return the element representing the setter that results from looking up the given setter in the
   * superclass of this class with respect to the given library, or `null` if the look up
   * fails. The behavior of this method is defined by the Dart Language Specification in section
   * 12.16: <blockquote> The result of looking up getter (respectively setter) <i>m</i> in class
   * <i>C</i> with respect to library <i>L</i> is:
   *
   * * If <i>C</i> declares an instance getter (respectively setter) named <i>m</i> that is
   * accessible to <i>L</i>, then that getter (respectively setter) is the result of the lookup.
   * Otherwise, if <i>C</i> has a superclass <i>S</i>, then the result of the lookup is the result
   * of looking up getter (respectively setter) <i>m</i> in <i>S</i> with respect to <i>L</i>.
   * Otherwise, we say that the lookup has failed.
   *
   * </blockquote>
   *
   * @param setterName the name of the setter being looked up
   * @param library the library with respect to which the lookup is being performed
   * @return the result of looking up the given setter in this class with respect to the given
   *         library
   */
  PropertyAccessorElement lookUpSetterInSuperclass(String setterName, LibraryElement library);

  /**
   * Return the type resulting from substituting the given arguments for this type's parameters.
   * This is fully equivalent to `substitute(argumentTypes, getTypeArguments())`.
   *
   * @param argumentTypes the actual type arguments being substituted for the type parameters
   * @return the result of performing the substitution
   */
  InterfaceType substitute4(List<Type2> argumentTypes);

  InterfaceType substitute2(List<Type2> argumentTypes, List<Type2> parameterTypes);
}

/**
 * The interface `ParameterizedType` defines the behavior common to objects representing a
 * type with type parameters, such as a class or function type alias.
 *
 * @coverage dart.engine.type
 */
abstract class ParameterizedType implements Type2 {
  /**
   * Return an array containing the actual types of the type arguments. If this type's element does
   * not have type parameters, then the array should be empty (although it is possible for type
   * arguments to be erroneously declared). If the element has type parameters and the actual type
   * does not explicitly include argument values, then the type "dynamic" will be automatically
   * provided.
   *
   * @return the actual types of the type arguments
   */
  List<Type2> get typeArguments;

  /**
   * Return an array containing all of the type parameters declared for this type.
   *
   * @return the type parameters declared for this type
   */
  List<TypeParameterElement> get typeParameters;
}

/**
 * The interface `Type` defines the behavior of objects representing the declared type of
 * elements in the element model.
 *
 * @coverage dart.engine.type
 */
abstract class Type2 {
  /**
   * Return the name of this type as it should appear when presented to users in contexts such as
   * error messages.
   *
   * @return the name of this type
   */
  String get displayName;

  /**
   * Return the element representing the declaration of this type, or `null` if the type has
   * not, or cannot, be associated with an element. The former case will occur if the element model
   * is not yet complete; the latter case will occur if this object represents an undefined type.
   *
   * @return the element representing the declaration of this type
   */
  Element get element;

  /**
   * Return the least upper bound of this type and the given type, or `null` if there is no
   * least upper bound.
   *
   * @param type the other type used to compute the least upper bound
   * @return the least upper bound of this type and the given type
   */
  Type2 getLeastUpperBound(Type2 type);

  /**
   * Return the name of this type, or `null` if the type does not have a name, such as when
   * the type represents the type of an unnamed function.
   *
   * @return the name of this type
   */
  String get name;

  /**
   * Return `true` if this type is assignable to the given type. A type <i>T</i> may be
   * assigned to a type <i>S</i>, written <i>T</i> &hArr; <i>S</i>, iff either <i>T</i> <: <i>S</i>
   * or <i>S</i> <: <i>T</i>.
   *
   * @param type the type being compared with this type
   * @return `true` if this type is assignable to the given type
   */
  bool isAssignableTo(Type2 type);

  /**
   * Return `true` if this type represents the bottom type.
   *
   * @return `true` if this type represents the bottom type
   */
  bool get isBottom;

  /**
   * Return `true` if this type represents the type 'Function' defined in the dart:core
   * library.
   *
   * @return `true` if this type represents the type 'Function' defined in the dart:core
   *         library
   */
  bool get isDartCoreFunction;

  /**
   * Return `true` if this type represents the type 'dynamic'.
   *
   * @return `true` if this type represents the type 'dynamic'
   */
  bool get isDynamic;

  /**
   * Return `true` if this type is more specific than the given type.
   *
   * @param type the type being compared with this type
   * @return `true` if this type is more specific than the given type
   */
  bool isMoreSpecificThan(Type2 type);

  /**
   * Return `true` if this type represents the type 'Object'.
   *
   * @return `true` if this type represents the type 'Object'
   */
  bool get isObject;

  /**
   * Return `true` if this type is a subtype of the given type.
   *
   * @param type the type being compared with this type
   * @return `true` if this type is a subtype of the given type
   */
  bool isSubtypeOf(Type2 type);

  /**
   * Return `true` if this type is a supertype of the given type. A type <i>S</i> is a
   * supertype of <i>T</i>, written <i>S</i> :> <i>T</i>, iff <i>T</i> is a subtype of <i>S</i>.
   *
   * @param type the type being compared with this type
   * @return `true` if this type is a supertype of the given type
   */
  bool isSupertypeOf(Type2 type);

  /**
   * Return `true` if this type represents the type 'void'.
   *
   * @return `true` if this type represents the type 'void'
   */
  bool get isVoid;

  /**
   * Return the type resulting from substituting the given arguments for the given parameters in
   * this type. The specification defines this operation in section 2: <blockquote> The notation
   * <i>[x<sub>1</sub>, ..., x<sub>n</sub>/y<sub>1</sub>, ..., y<sub>n</sub>]E</i> denotes a copy of
   * <i>E</i> in which all occurrences of <i>y<sub>i</sub>, 1 <= i <= n</i> have been replaced with
   * <i>x<sub>i</sub></i>.</blockquote> Note that, contrary to the specification, this method will
   * not create a copy of this type if no substitutions were required, but will return this type
   * directly.
   *
   * @param argumentTypes the actual type arguments being substituted for the parameters
   * @param parameterTypes the parameters to be replaced
   * @return the result of performing the substitution
   */
  Type2 substitute2(List<Type2> argumentTypes, List<Type2> parameterTypes);
}

/**
 * The interface `TypeParameterType` defines the behavior of objects representing the type
 * introduced by a type parameter.
 *
 * @coverage dart.engine.type
 */
abstract class TypeParameterType implements Type2 {
  TypeParameterElement get element;
}

/**
 * The interface `VoidType` defines the behavior of the unique object representing the type
 * `void`.
 *
 * @coverage dart.engine.type
 */
abstract class VoidType implements Type2 {
  VoidType substitute2(List<Type2> argumentTypes, List<Type2> parameterTypes);
}