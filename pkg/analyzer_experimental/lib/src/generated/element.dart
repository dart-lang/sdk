// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.
library engine.element;
import 'dart:collection';
import 'java_core.dart';
import 'java_engine.dart';
import 'source.dart';
import 'scanner.dart' show Keyword;
import 'ast.dart' show Identifier, LibraryIdentifier;
import 'sdk.dart' show DartSdk;
import 'html.dart' show XmlTagNode;
import 'engine.dart' show AnalysisContext;
import 'constant.dart' show EvaluationResultImpl;
import 'utilities_dart.dart';
/**
 * The interface {@code ClassElement} defines the behavior of elements that represent a class.
 * @coverage dart.engine.element
 */
abstract class ClassElement implements Element {

  /**
   * Return an array containing all of the accessors (getters and setters) declared in this class.
   * @return the accessors declared in this class
   */
  List<PropertyAccessorElement> get accessors;

  /**
   * Return an array containing all the supertypes defined for this class and its supertypes. This
   * includes superclasses, mixins and interfaces.
   * @return all the supertypes of this class, including mixins
   */
  List<InterfaceType> get allSupertypes;

  /**
   * Return an array containing all of the constructors declared in this class.
   * @return the constructors declared in this class
   */
  List<ConstructorElement> get constructors;

  /**
   * Return an array containing all of the fields declared in this class.
   * @return the fields declared in this class
   */
  List<FieldElement> get fields;

  /**
   * Return the element representing the getter with the given name that is declared in this class,
   * or {@code null} if this class does not declare a getter with the given name.
   * @param getterName the name of the getter to be returned
   * @return the getter declared in this class with the given name
   */
  PropertyAccessorElement getGetter(String getterName);

  /**
   * Return an array containing all of the interfaces that are implemented by this class.
   * <p>
   * <b>Note:</b> Because the element model represents the state of the code, it is possible for it
   * to be semantically invalid. In particular, it is not safe to assume that the inheritance
   * structure of a class does not contain a cycle. Clients that traverse the inheritance structure
   * must explicitly guard against infinite loops.
   * @return the interfaces that are implemented by this class
   */
  List<InterfaceType> get interfaces;

  /**
   * Return the element representing the method with the given name that is declared in this class,
   * or {@code null} if this class does not declare a method with the given name.
   * @param methodName the name of the method to be returned
   * @return the method declared in this class with the given name
   */
  MethodElement getMethod(String methodName);

  /**
   * Return an array containing all of the methods declared in this class.
   * @return the methods declared in this class
   */
  List<MethodElement> get methods;

  /**
   * Return an array containing all of the mixins that are applied to the class being extended in
   * order to derive the superclass of this class.
   * <p>
   * <b>Note:</b> Because the element model represents the state of the code, it is possible for it
   * to be semantically invalid. In particular, it is not safe to assume that the inheritance
   * structure of a class does not contain a cycle. Clients that traverse the inheritance structure
   * must explicitly guard against infinite loops.
   * @return the mixins that are applied to derive the superclass of this class
   */
  List<InterfaceType> get mixins;

  /**
   * Return the named constructor declared in this class with the given name, or {@code null} if
   * this class does not declare a named constructor with the given name.
   * @param name the name of the constructor to be returned
   * @return the element representing the specified constructor
   */
  ConstructorElement getNamedConstructor(String name);

  /**
   * Return the element representing the setter with the given name that is declared in this class,
   * or {@code null} if this class does not declare a setter with the given name.
   * @param setterName the name of the getter to be returned
   * @return the setter declared in this class with the given name
   */
  PropertyAccessorElement getSetter(String setterName);

  /**
   * Return the superclass of this class, or {@code null} if the class represents the class
   * 'Object'. All other classes will have a non-{@code null} superclass. If the superclass was not
   * explicitly declared then the implicit superclass 'Object' will be returned.
   * <p>
   * <b>Note:</b> Because the element model represents the state of the code, it is possible for it
   * to be semantically invalid. In particular, it is not safe to assume that the inheritance
   * structure of a class does not contain a cycle. Clients that traverse the inheritance structure
   * must explicitly guard against infinite loops.
   * @return the superclass of this class
   */
  InterfaceType get supertype;

  /**
   * Return the type defined by the class.
   * @return the type defined by the class
   */
  InterfaceType get type;

  /**
   * Return an array containing all of the type variables declared for this class.
   * @return the type variables declared for this class
   */
  List<TypeVariableElement> get typeVariables;

  /**
   * Return the unnamed constructor declared in this class, or {@code null} if this class does not
   * declare an unnamed constructor but does declare named constructors. The returned constructor
   * will be synthetic if this class does not declare any constructors, in which case it will
   * represent the default constructor for the class.
   * @return the unnamed constructor defined in this class
   */
  ConstructorElement get unnamedConstructor;

  /**
   * Return {@code true} if this class or its superclass declares a non-final instance field.
   * @return {@code true} if this class or its superclass declares a non-final instance field
   */
  bool hasNonFinalField();

  /**
   * Return {@code true} if this class has reference to super (so, for example, cannot be used as a
   * mixin).
   * @return {@code true} if this class has reference to super
   */
  bool hasReferenceToSuper();

  /**
   * Return {@code true} if this class is abstract. A class is abstract if it has an explicit{@code abstract} modifier. Note, that this definition of <i>abstract</i> is different from
   * <i>has unimplemented members</i>.
   * @return {@code true} if this class is abstract
   */
  bool isAbstract();

  /**
   * Return {@code true} if this class is defined by a typedef construct.
   * @return {@code true} if this class is defined by a typedef construct
   */
  bool isTypedef();

  /**
   * Return {@code true} if this class can validly be used as a mixin when defining another class.
   * The behavior of this method is defined by the Dart Language Specification in section 9:
   * <blockquote>It is a compile-time error if a declared or derived mixin refers to super. It is a
   * compile-time error if a declared or derived mixin explicitly declares a constructor. It is a
   * compile-time error if a mixin is derived from a class whose superclass is not
   * Object.</blockquote>
   * @return {@code true} if this class can validly be used as a mixin
   */
  bool isValidMixin();

  /**
   * Return the element representing the getter that results from looking up the given getter in
   * this class with respect to the given library, or {@code null} if the look up fails. The
   * behavior of this method is defined by the Dart Language Specification in section 12.15.1:
   * <blockquote>The result of looking up getter (respectively setter) <i>m</i> in class <i>C</i>
   * with respect to library <i>L</i> is:
   * <ul>
   * <li>If <i>C</i> declares an instance getter (respectively setter) named <i>m</i> that is
   * accessible to <i>L</i>, then that getter (respectively setter) is the result of the lookup.
   * Otherwise, if <i>C</i> has a superclass <i>S</i>, then the result of the lookup is the result
   * of looking up getter (respectively setter) <i>m</i> in <i>S</i> with respect to <i>L</i>.
   * Otherwise, we say that the lookup has failed.</li>
   * </ul>
   * </blockquote>
   * @param getterName the name of the getter being looked up
   * @param library the library with respect to which the lookup is being performed
   * @return the result of looking up the given getter in this class with respect to the given
   * library
   */
  PropertyAccessorElement lookUpGetter(String getterName, LibraryElement library);

  /**
   * Return the element representing the method that results from looking up the given method in
   * this class with respect to the given library, or {@code null} if the look up fails. The
   * behavior of this method is defined by the Dart Language Specification in section 12.15.1:
   * <blockquote> The result of looking up method <i>m</i> in class <i>C</i> with respect to library
   * <i>L</i> is:
   * <ul>
   * <li>If <i>C</i> declares an instance method named <i>m</i> that is accessible to <i>L</i>, then
   * that method is the result of the lookup. Otherwise, if <i>C</i> has a superclass <i>S</i>, then
   * the result of the lookup is the result of looking up method <i>m</i> in <i>S</i> with respect
   * to <i>L</i>. Otherwise, we say that the lookup has failed.</li>
   * </ul>
   * </blockquote>
   * @param methodName the name of the method being looked up
   * @param library the library with respect to which the lookup is being performed
   * @return the result of looking up the given method in this class with respect to the given
   * library
   */
  MethodElement lookUpMethod(String methodName, LibraryElement library);

  /**
   * Return the element representing the setter that results from looking up the given setter in
   * this class with respect to the given library, or {@code null} if the look up fails. The
   * behavior of this method is defined by the Dart Language Specification in section 12.16:
   * <blockquote> The result of looking up getter (respectively setter) <i>m</i> in class <i>C</i>
   * with respect to library <i>L</i> is:
   * <ul>
   * <li>If <i>C</i> declares an instance getter (respectively setter) named <i>m</i> that is
   * accessible to <i>L</i>, then that getter (respectively setter) is the result of the lookup.
   * Otherwise, if <i>C</i> has a superclass <i>S</i>, then the result of the lookup is the result
   * of looking up getter (respectively setter) <i>m</i> in <i>S</i> with respect to <i>L</i>.
   * Otherwise, we say that the lookup has failed.</li>
   * </ul>
   * </blockquote>
   * @param setterName the name of the setter being looked up
   * @param library the library with respect to which the lookup is being performed
   * @return the result of looking up the given setter in this class with respect to the given
   * library
   */
  PropertyAccessorElement lookUpSetter(String setterName, LibraryElement library);
}
/**
 * The interface {@code ClassMemberElement} defines the behavior of elements that are contained
 * within a {@link ClassElement}.
 */
abstract class ClassMemberElement implements Element {

  /**
   * Return the type in which this member is defined.
   * @return the type in which this member is defined
   */
  ClassElement get enclosingElement;
}
/**
 * The interface {@code CompilationUnitElement} defines the behavior of elements representing a
 * compilation unit.
 * @coverage dart.engine.element
 */
abstract class CompilationUnitElement implements Element, UriReferencedElement {

  /**
   * Return an array containing all of the top-level accessors (getters and setters) contained in
   * this compilation unit.
   * @return the top-level accessors contained in this compilation unit
   */
  List<PropertyAccessorElement> get accessors;

  /**
   * Return the library in which this compilation unit is defined.
   * @return the library in which this compilation unit is defined
   */
  LibraryElement get enclosingElement;

  /**
   * Return an array containing all of the top-level functions contained in this compilation unit.
   * @return the top-level functions contained in this compilation unit
   */
  List<FunctionElement> get functions;

  /**
   * Return an array containing all of the function type aliases contained in this compilation unit.
   * @return the function type aliases contained in this compilation unit
   */
  List<FunctionTypeAliasElement> get functionTypeAliases;

  /**
   * Return an array containing all of the top-level variables contained in this compilation unit.
   * @return the top-level variables contained in this compilation unit
   */
  List<TopLevelVariableElement> get topLevelVariables;

  /**
   * Return the class defined in this compilation unit that has the given name, or {@code null} if
   * this compilation unit does not define a class with the given name.
   * @param className the name of the class to be returned
   * @return the class with the given name that is defined in this compilation unit
   */
  ClassElement getType(String className);

  /**
   * Return an array containing all of the classes contained in this compilation unit.
   * @return the classes contained in this compilation unit
   */
  List<ClassElement> get types;
}
/**
 * The interface {@code ConstructorElement} defines the behavior of elements representing a
 * constructor or a factory method defined within a type.
 * @coverage dart.engine.element
 */
abstract class ConstructorElement implements ClassMemberElement, ExecutableElement {

  /**
   * Return the constructor to which this constructor is redirecting.
   * @return the constructor to which this constructor is redirecting
   */
  ConstructorElement get redirectedConstructor;

  /**
   * Return {@code true} if this constructor is a const constructor.
   * @return {@code true} if this constructor is a const constructor
   */
  bool isConst();

  /**
   * Return {@code true} if this constructor represents a factory constructor.
   * @return {@code true} if this constructor represents a factory constructor
   */
  bool isFactory();
}
/**
 * The interface {@code Element} defines the behavior common to all of the elements in the element
 * model. Generally speaking, the element model is a semantic model of the program that represents
 * things that are declared with a name and hence can be referenced elsewhere in the code.
 * <p>
 * There are two exceptions to the general case. First, there are elements in the element model that
 * are created for the convenience of various kinds of analysis but that do not have any
 * corresponding declaration within the source code. Such elements are marked as being
 * <i>synthetic</i>. Examples of synthetic elements include
 * <ul>
 * <li>default constructors in classes that do not define any explicit constructors,
 * <li>getters and setters that are induced by explicit field declarations,
 * <li>fields that are induced by explicit declarations of getters and setters, and
 * <li>functions representing the initialization expression for a variable.
 * </ul>
 * <p>
 * Second, there are elements in the element model that do not have a name. These correspond to
 * unnamed functions and exist in order to more accurately represent the semantic structure of the
 * program.
 * @coverage dart.engine.element
 */
abstract class Element {

  /**
   * A comparator that can be used to sort elements by their name offset. Elements with a smaller
   * offset will be sorted to be before elements with a larger name offset.
   */
  static final Comparator<Element> SORT_BY_OFFSET = (Element firstElement, Element secondElement) => firstElement.nameOffset - secondElement.nameOffset;

  /**
   * Use the given visitor to visit this element.
   * @param visitor the visitor that will visit this element
   * @return the value returned by the visitor as a result of visiting this element
   */
  accept(ElementVisitor visitor);

  /**
   * Return the documentation comment for this element as it appears in the original source
   * (complete with the beginning and ending delimiters), or {@code null} if this element does not
   * have a documentation comment associated with it. This can be a long-running operation if the
   * information needed to access the comment is not cached.
   * @return this element's documentation comment
   * @throws AnalysisException if the documentation comment could not be determined because the
   * analysis could not be performed
   */
  String computeDocumentationComment();

  /**
   * Return the element of the given class that most immediately encloses this element, or{@code null} if there is no enclosing element of the given class.
   * @param elementClass the class of the element to be returned
   * @return the element that encloses this element
   */
  Element getAncestor(Type elementClass);

  /**
   * Return the analysis context in which this element is defined.
   * @return the analysis context in which this element is defined
   */
  AnalysisContext get context;

  /**
   * Return the display name of this element, or {@code null} if this element does not have a name.
   * <p>
   * In most cases the name and the display name are the same. Differences though are cases such as
   * setters where the name of some setter {@code set f(x)} is {@code f=}, instead of {@code f}.
   * @return the display name of this element
   */
  String get displayName;

  /**
   * Return the element that either physically or logically encloses this element. This will be{@code null} if this element is a library because libraries are the top-level elements in the
   * model.
   * @return the element that encloses this element
   */
  Element get enclosingElement;

  /**
   * Return the kind of element that this is.
   * @return the kind of this element
   */
  ElementKind get kind;

  /**
   * Return the library that contains this element. This will be the element itself if it is a
   * library element. This will be {@code null} if this element is an HTML file because HTML files
   * are not contained in libraries.
   * @return the library that contains this element
   */
  LibraryElement get library;

  /**
   * Return an object representing the location of this element in the element model. The object can
   * be used to locate this element at a later time.
   * @return the location of this element in the element model
   */
  ElementLocation get location;

  /**
   * Return an array containing all of the metadata associated with this element.
   * @return the metadata associated with this element
   */
  List<ElementAnnotation> get metadata;

  /**
   * Return the name of this element, or {@code null} if this element does not have a name.
   * @return the name of this element
   */
  String get name;

  /**
   * Return the offset of the name of this element in the file that contains the declaration of this
   * element, or {@code -1} if this element is synthetic, does not have a name, or otherwise does
   * not have an offset.
   * @return the offset of the name of this element
   */
  int get nameOffset;

  /**
   * Return the source that contains this element, or {@code null} if this element is not contained
   * in a source.
   * @return the source that contains this element
   */
  Source get source;

  /**
   * Return {@code true} if this element, assuming that it is within scope, is accessible to code in
   * the given library. This is defined by the Dart Language Specification in section 3.2:
   * <blockquote> A declaration <i>m</i> is accessible to library <i>L</i> if <i>m</i> is declared
   * in <i>L</i> or if <i>m</i> is public. </blockquote>
   * @param library the library in which a possible reference to this element would occur
   * @return {@code true} if this element is accessible to code in the given library
   */
  bool isAccessibleIn(LibraryElement library);

  /**
   * Return {@code true} if this element is synthetic. A synthetic element is an element that is not
   * represented in the source code explicitly, but is implied by the source code, such as the
   * default constructor for a class that does not explicitly define any constructors.
   * @return {@code true} if this element is synthetic
   */
  bool isSynthetic();

  /**
   * Use the given visitor to visit all of the children of this element. There is no guarantee of
   * the order in which the children will be visited.
   * @param visitor the visitor that will be used to visit the children of this element
   */
  void visitChildren(ElementVisitor<Object> visitor);
}
/**
 * The interface {@code ElementAnnotation} defines the behavior of objects representing a single
 * annotation associated with an element.
 * @coverage dart.engine.element
 */
abstract class ElementAnnotation {

  /**
   * Return the element representing the field, variable, or const constructor being used as an
   * annotation.
   * @return the field, variable, or constructor being used as an annotation
   */
  Element get element;
}
/**
 * The enumeration {@code ElementKind} defines the various kinds of elements in the element model.
 * @coverage dart.engine.element
 */
class ElementKind implements Comparable<ElementKind> {
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
  static final ElementKind TYPE_VARIABLE = new ElementKind('TYPE_VARIABLE', 23, "type variable");
  static final ElementKind UNIVERSE = new ElementKind('UNIVERSE', 24, "<universe>");
  static final List<ElementKind> values = [CLASS, COMPILATION_UNIT, CONSTRUCTOR, DYNAMIC, EMBEDDED_HTML_SCRIPT, ERROR, EXPORT, EXTERNAL_HTML_SCRIPT, FIELD, FUNCTION, GETTER, HTML, IMPORT, LABEL, LIBRARY, LOCAL_VARIABLE, METHOD, NAME, PARAMETER, PREFIX, SETTER, TOP_LEVEL_VARIABLE, FUNCTION_TYPE_ALIAS, TYPE_VARIABLE, UNIVERSE];

  /// The name of this enum constant, as declared in the enum declaration.
  final String name;

  /// The position in the enum declaration.
  final int ordinal;

  /**
   * Return the kind of the given element, or {@link #ERROR} if the element is {@code null}. This is
   * a utility method that can reduce the need for null checks in other places.
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
  String _displayName;

  /**
   * Initialize a newly created element kind to have the given display name.
   * @param displayName the name displayed in the UI for this kind of element
   */
  ElementKind(this.name, this.ordinal, String displayName) {
    this._displayName = displayName;
  }

  /**
   * Return the name displayed in the UI for this kind of element.
   * @return the name of this {@link ElementKind} to display in UI.
   */
  String get displayName => _displayName;
  int compareTo(ElementKind other) => ordinal - other.ordinal;
  int get hashCode => ordinal;
  String toString() => name;
}
/**
 * The interface {@code ElementLocation} defines the behavior of objects that represent the location
 * of an element within the element model.
 * @coverage dart.engine.element
 */
abstract class ElementLocation {

  /**
   * Return an encoded representation of this location that can be used to create a location that is
   * equal to this location.
   * @return an encoded representation of this location
   */
  String get encoding;
}
/**
 * The interface {@code ElementVisitor} defines the behavior of objects that can be used to visit an
 * element structure.
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
  R visitTypeVariableElement(TypeVariableElement element);
}
/**
 * The interface {@code EmbeddedHtmlScriptElement} defines the behavior of elements representing a
 * script tag in an HTML file having content that defines a Dart library.
 * @coverage dart.engine.element
 */
abstract class EmbeddedHtmlScriptElement implements HtmlScriptElement {

  /**
   * Return the library element defined by the content of the script tag.
   * @return the library element (not {@code null})
   */
  LibraryElement get scriptLibrary;
}
/**
 * The interface {@code ExecutableElement} defines the behavior of elements representing an
 * executable object, including functions, methods, constructors, getters, and setters.
 * @coverage dart.engine.element
 */
abstract class ExecutableElement implements Element {

  /**
   * Return an array containing all of the functions defined within this executable element.
   * @return the functions defined within this executable element
   */
  List<FunctionElement> get functions;

  /**
   * Return an array containing all of the labels defined within this executable element.
   * @return the labels defined within this executable element
   */
  List<LabelElement> get labels;

  /**
   * Return an array containing all of the local variables defined within this executable element.
   * @return the local variables defined within this executable element
   */
  List<LocalVariableElement> get localVariables;

  /**
   * Return an array containing all of the parameters defined by this executable element.
   * @return the parameters defined by this executable element
   */
  List<ParameterElement> get parameters;

  /**
   * Return the type of function defined by this executable element.
   * @return the type of function defined by this executable element
   */
  FunctionType get type;

  /**
   * Return {@code true} if this executable element is an operator. The test may be based on the
   * name of the executable element, in which case the result will be correct when the name is
   * legal.
   * @return {@code true} if this executable element is an operator
   */
  bool isOperator();

  /**
   * Return {@code true} if this element is a static element. A static element is an element that is
   * not associated with a particular instance, but rather with an entire library or class.
   * @return {@code true} if this executable element is a static element
   */
  bool isStatic();
}
/**
 * The interface {@code ExportElement} defines the behavior of objects representing information
 * about a single export directive within a library.
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
   * @return the combinators specified in the export directive
   */
  List<NamespaceCombinator> get combinators;

  /**
   * Return the library that is exported from this library by this export directive.
   * @return the library that is exported from this library
   */
  LibraryElement get exportedLibrary;
}
/**
 * The interface {@code ExternalHtmlScriptElement} defines the behavior of elements representing a
 * script tag in an HTML file having a {@code source} attribute that references a Dart library
 * source file.
 * @coverage dart.engine.element
 */
abstract class ExternalHtmlScriptElement implements HtmlScriptElement {

  /**
   * Return the source referenced by this element, or {@code null} if this element does not
   * reference a Dart library source file.
   * @return the source for the external Dart library
   */
  Source get scriptSource;
}
/**
 * The interface {@code FieldElement} defines the behavior of elements representing a field defined
 * within a type.
 * @coverage dart.engine.element
 */
abstract class FieldElement implements ClassMemberElement, PropertyInducingElement {
}
/**
 * The interface {@code FieldFormalParameterElement} defines the behavior of elements representing a
 * field formal parameter defined within a constructor element.
 */
abstract class FieldFormalParameterElement implements ParameterElement {

  /**
   * Return the field element associated with this field formal parameter, or {@code null} if the
   * parameter references a field that doesn't exist.
   * @return the field element associated with this field formal parameter
   */
  FieldElement get field;
}
/**
 * The interface {@code FunctionElement} defines the behavior of elements representing a function.
 * @coverage dart.engine.element
 */
abstract class FunctionElement implements ExecutableElement, LocalElement {
}
/**
 * The interface {@code FunctionTypeAliasElement} defines the behavior of elements representing a
 * function type alias ({@code typedef}).
 * @coverage dart.engine.element
 */
abstract class FunctionTypeAliasElement implements Element {

  /**
   * Return the compilation unit in which this type alias is defined.
   * @return the compilation unit in which this type alias is defined
   */
  CompilationUnitElement get enclosingElement;

  /**
   * Return an array containing all of the parameters defined by this type alias.
   * @return the parameters defined by this type alias
   */
  List<ParameterElement> get parameters;

  /**
   * Return the type of function defined by this type alias.
   * @return the type of function defined by this type alias
   */
  FunctionType get type;

  /**
   * Return an array containing all of the type variables defined for this type.
   * @return the type variables defined for this type
   */
  List<TypeVariableElement> get typeVariables;
}
/**
 * The interface {@code HideElementCombinator} defines the behavior of combinators that cause some
 * of the names in a namespace to be hidden when being imported.
 * @coverage dart.engine.element
 */
abstract class HideElementCombinator implements NamespaceCombinator {

  /**
   * Return an array containing the names that are not to be made visible in the importing library
   * even if they are defined in the imported library.
   * @return the names from the imported library that are hidden from the importing library
   */
  List<String> get hiddenNames;
}
/**
 * The interface {@code HtmlElement} defines the behavior of elements representing an HTML file.
 * @coverage dart.engine.element
 */
abstract class HtmlElement implements Element {

  /**
   * Return an array containing all of the script elements contained in the HTML file. This includes
   * scripts with libraries that are defined by the content of a script tag as well as libraries
   * that are referenced in the {@core source} attribute of a script tag.
   * @return the script elements in the HTML file (not {@code null}, contains no {@code null}s)
   */
  List<HtmlScriptElement> get scripts;
}
/**
 * The interface {@code HtmlScriptElement} defines the behavior of elements representing a script
 * tag in an HTML file.
 * @see EmbeddedHtmlScriptElement
 * @see ExternalHtmlScriptElement
 * @coverage dart.engine.element
 */
abstract class HtmlScriptElement implements Element {
}
/**
 * The interface {@code ImportElement} defines the behavior of objects representing information
 * about a single import directive within a library.
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
   * @return the combinators specified in the import directive
   */
  List<NamespaceCombinator> get combinators;

  /**
   * Return the library that is imported into this library by this import directive.
   * @return the library that is imported into this library
   */
  LibraryElement get importedLibrary;

  /**
   * Return the prefix that was specified as part of the import directive, or {@code null} if there
   * was no prefix specified.
   * @return the prefix that was specified as part of the import directive
   */
  PrefixElement get prefix;
}
/**
 * The interface {@code LabelElement} defines the behavior of elements representing a label
 * associated with a statement.
 * @coverage dart.engine.element
 */
abstract class LabelElement implements Element {

  /**
   * Return the executable element in which this label is defined.
   * @return the executable element in which this label is defined
   */
  ExecutableElement get enclosingElement;
}
/**
 * The interface {@code LibraryElement} defines the behavior of elements representing a library.
 * @coverage dart.engine.element
 */
abstract class LibraryElement implements Element {

  /**
   * Return the compilation unit that defines this library.
   * @return the compilation unit that defines this library
   */
  CompilationUnitElement get definingCompilationUnit;

  /**
   * Return the entry point for this library, or {@code null} if this library does not have an entry
   * point. The entry point is defined to be a zero argument top-level function whose name is{@code main}.
   * @return the entry point for this library
   */
  FunctionElement get entryPoint;

  /**
   * Return an array containing all of the libraries that are exported from this library.
   * @return an array containing all of the libraries that are exported from this library
   */
  List<LibraryElement> get exportedLibraries;

  /**
   * Return an array containing all of the exports defined in this library.
   * @return the exports defined in this library
   */
  List<ExportElement> get exports;

  /**
   * Return an array containing all of the libraries that are imported into this library. This
   * includes all of the libraries that are imported using a prefix (also available through the
   * prefixes returned by {@link #getPrefixes()}) and those that are imported without a prefix.
   * @return an array containing all of the libraries that are imported into this library
   */
  List<LibraryElement> get importedLibraries;

  /**
   * Return an array containing all of the imports defined in this library.
   * @return the imports defined in this library
   */
  List<ImportElement> get imports;

  /**
   * Return an array containing all of the compilation units that are included in this library using
   * a {@code part} directive. This does not include the defining compilation unit that contains the{@code part} directives.
   * @return the compilation units that are included in this library
   */
  List<CompilationUnitElement> get parts;

  /**
   * Return an array containing elements for each of the prefixes used to {@code import} libraries
   * into this library. Each prefix can be used in more than one {@code import} directive.
   * @return the prefixes used to {@code import} libraries into this library
   */
  List<PrefixElement> get prefixes;

  /**
   * Return the class defined in this library that has the given name, or {@code null} if this
   * library does not define a class with the given name.
   * @param className the name of the class to be returned
   * @return the class with the given name that is defined in this library
   */
  ClassElement getType(String className);

  /**
   * Answer {@code true} if this library is an application that can be run in the browser.
   * @return {@code true} if this library is an application that can be run in the browser
   */
  bool isBrowserApplication();

  /**
   * Return {@code true} if this library is the dart:core library.
   * @return {@code true} if this library is the dart:core library
   */
  bool isDartCore();

  /**
   * Return {@code true} if this library is up to date with respect to the given time stamp. If any
   * transitively referenced Source is newer than the time stamp, this method returns false.
   * @param timeStamp the time stamp to compare against
   * @return {@code true} if this library is up to date with respect to the given time stamp
   */
  bool isUpToDate2(int timeStamp);
}
/**
 * The interface {@code LocalElement} defines the behavior of elements that can be (but are not
 * required to be) defined within a method or function (an {@link ExecutableElement}).
 * @coverage dart.engine.element
 */
abstract class LocalElement implements Element {

  /**
   * Return a source range that covers the approximate portion of the source in which the name of
   * this element is visible, or {@code null} if there is no single range of characters within which
   * the element name is visible.
   * <ul>
   * <li>For a local variable, this includes everything from the end of the variable's initializer
   * to the end of the block that encloses the variable declaration.</li>
   * <li>For a parameter, this includes the body of the method or function that declares the
   * parameter.</li>
   * <li>For a local function, this includes everything from the beginning of the function's body to
   * the end of the block that encloses the function declaration.</li>
   * <li>For top-level functions, {@code null} will be returned because they are potentially visible
   * in multiple sources.</li>
   * </ul>
   * @return the range of characters in which the name of this element is visible
   */
  SourceRange get visibleRange;
}
/**
 * The interface {@code LocalVariableElement} defines the behavior common to elements that represent
 * a local variable.
 * @coverage dart.engine.element
 */
abstract class LocalVariableElement implements LocalElement, VariableElement {
}
/**
 * The interface {@code MethodElement} defines the behavior of elements that represent a method
 * defined within a type.
 * @coverage dart.engine.element
 */
abstract class MethodElement implements ClassMemberElement, ExecutableElement {

  /**
   * Return {@code true} if this method is abstract. Methods are abstract if they are not external
   * and have no body.
   * @return {@code true} if this method is abstract
   */
  bool isAbstract();
}
/**
 * The interface {@code MultiplyDefinedElement} defines the behavior of pseudo-elements that
 * represent multiple elements defined within a single scope that have the same name. This situation
 * is not allowed by the language, so objects implementing this interface always represent an error.
 * As a result, most of the normal operations on elements do not make sense and will return useless
 * results.
 * @coverage dart.engine.element
 */
abstract class MultiplyDefinedElement implements Element {

  /**
   * Return an array containing all of the elements that were defined within the scope to have the
   * same name.
   * @return the elements that were defined with the same name
   */
  List<Element> get conflictingElements;
}
/**
 * The interface {@code NamespaceCombinator} defines the behavior common to objects that control how
 * namespaces are combined.
 * @coverage dart.engine.element
 */
abstract class NamespaceCombinator {

  /**
   * An empty array of namespace combinators.
   */
  static final List<NamespaceCombinator> EMPTY_ARRAY = new List<NamespaceCombinator>(0);
}
/**
 * The interface {@code ParameterElement} defines the behavior of elements representing a parameter
 * defined within an executable element.
 * @coverage dart.engine.element
 */
abstract class ParameterElement implements LocalElement, VariableElement {

  /**
   * Return a source range that covers the portion of the source in which the default value for this
   * parameter is specified, or {@code null} if there is no default value.
   * @return the range of characters in which the default value of this parameter is specified
   */
  SourceRange get defaultValueRange;

  /**
   * Return the kind of this parameter.
   * @return the kind of this parameter
   */
  ParameterKind get parameterKind;

  /**
   * Return an array containing all of the parameters defined by this parameter. A parameter will
   * only define other parameters if it is a function typed parameter.
   * @return the parameters defined by this parameter element
   */
  List<ParameterElement> get parameters;

  /**
   * Return {@code true} if this parameter is an initializing formal parameter.
   * @return {@code true} if this parameter is an initializing formal parameter
   */
  bool isInitializingFormal();
}
/**
 * The interface {@code PrefixElement} defines the behavior common to elements that represent a
 * prefix used to import one or more libraries into another library.
 * @coverage dart.engine.element
 */
abstract class PrefixElement implements Element {

  /**
   * Return the library into which other libraries are imported using this prefix.
   * @return the library into which other libraries are imported using this prefix
   */
  LibraryElement get enclosingElement;

  /**
   * Return an array containing all of the libraries that are imported using this prefix.
   * @return the libraries that are imported using this prefix
   */
  List<LibraryElement> get importedLibraries;
}
/**
 * The interface {@code PropertyAccessorElement} defines the behavior of elements representing a
 * getter or a setter. Note that explicitly defined property accessors implicitly define a synthetic
 * field. Symmetrically, synthetic accessors are implicitly created for explicitly defined fields.
 * The following rules apply:
 * <ul>
 * <li>Every explicit field is represented by a non-synthetic {@link FieldElement}.
 * <li>Every explicit field induces a getter and possibly a setter, both of which are represented by
 * synthetic {@link PropertyAccessorElement}s.
 * <li>Every explicit getter or setter is represented by a non-synthetic{@link PropertyAccessorElement}.
 * <li>Every explicit getter or setter (or pair thereof if they have the same name) induces a field
 * that is represented by a synthetic {@link FieldElement}.
 * </ul>
 * @coverage dart.engine.element
 */
abstract class PropertyAccessorElement implements ExecutableElement {

  /**
   * Return the accessor representing the getter that corresponds to (has the same name as) this
   * setter, or {@code null} if this accessor is not a setter or if there is no corresponding
   * getter.
   * @return the getter that corresponds to this setter
   */
  PropertyAccessorElement get correspondingGetter;

  /**
   * Return the accessor representing the setter that corresponds to (has the same name as) this
   * getter, or {@code null} if this accessor is not a getter or if there is no corresponding
   * setter.
   * @return the setter that corresponds to this getter
   */
  PropertyAccessorElement get correspondingSetter;

  /**
   * Return the field or top-level variable associated with this accessor. If this accessor was
   * explicitly defined (is not synthetic) then the variable associated with it will be synthetic.
   * @return the variable associated with this accessor
   */
  PropertyInducingElement get variable;

  /**
   * Return {@code true} if this accessor is abstract. Accessors are abstract if they are not
   * external and have no body.
   * @return {@code true} if this accessor is abstract
   */
  bool isAbstract();

  /**
   * Return {@code true} if this accessor represents a getter.
   * @return {@code true} if this accessor represents a getter
   */
  bool isGetter();

  /**
   * Return {@code true} if this accessor represents a setter.
   * @return {@code true} if this accessor represents a setter
   */
  bool isSetter();
}
/**
 * The interface {@code PropertyInducingElement} defines the behavior of elements representing a
 * variable that has an associated getter and possibly a setter. Note that explicitly defined
 * variables implicitly define a synthetic getter and that non-{@code final} explicitly defined
 * variables implicitly define a synthetic setter. Symmetrically, synthetic fields are implicitly
 * created for explicitly defined getters and setters. The following rules apply:
 * <ul>
 * <li>Every explicit variable is represented by a non-synthetic {@link PropertyInducingElement}.
 * <li>Every explicit variable induces a getter and possibly a setter, both of which are represented
 * by synthetic {@link PropertyAccessorElement}s.
 * <li>Every explicit getter or setter is represented by a non-synthetic{@link PropertyAccessorElement}.
 * <li>Every explicit getter or setter (or pair thereof if they have the same name) induces a
 * variable that is represented by a synthetic {@link PropertyInducingElement}.
 * </ul>
 * @coverage dart.engine.element
 */
abstract class PropertyInducingElement implements VariableElement {

  /**
   * Return the getter associated with this variable. If this variable was explicitly defined (is
   * not synthetic) then the getter associated with it will be synthetic.
   * @return the getter associated with this variable
   */
  PropertyAccessorElement get getter;

  /**
   * Return the setter associated with this variable, or {@code null} if the variable is effectively{@code final} and therefore does not have a setter associated with it. (This can happen either
   * because the variable is explicitly defined as being {@code final} or because the variable is
   * induced by an explicit getter that does not have a corresponding setter.) If this variable was
   * explicitly defined (is not synthetic) then the setter associated with it will be synthetic.
   * @return the setter associated with this variable
   */
  PropertyAccessorElement get setter;

  /**
   * Return {@code true} if this element is a static element. A static element is an element that is
   * not associated with a particular instance, but rather with an entire library or class.
   * @return {@code true} if this executable element is a static element
   */
  bool isStatic();
}
/**
 * The interface {@code ShowElementCombinator} defines the behavior of combinators that cause some
 * of the names in a namespace to be visible (and the rest hidden) when being imported.
 * @coverage dart.engine.element
 */
abstract class ShowElementCombinator implements NamespaceCombinator {

  /**
   * Return an array containing the names that are to be made visible in the importing library if
   * they are defined in the imported library.
   * @return the names from the imported library that are visible in the importing library
   */
  List<String> get shownNames;
}
/**
 * The interface {@code TopLevelVariableElement} defines the behavior of elements representing a
 * top-level variable.
 * @coverage dart.engine.element
 */
abstract class TopLevelVariableElement implements PropertyInducingElement {
}
/**
 * The interface {@code TypeVariableElement} defines the behavior of elements representing a type
 * variable.
 * @coverage dart.engine.element
 */
abstract class TypeVariableElement implements Element {

  /**
   * Return the type representing the bound associated with this variable, or {@code null} if this
   * variable does not have an explicit bound.
   * @return the type representing the bound associated with this variable
   */
  Type2 get bound;

  /**
   * Return the type defined by this type variable.
   * @return the type defined by this type variable
   */
  TypeVariableType get type;
}
/**
 * The interface {@code UndefinedElement} defines the behavior of pseudo-elements that represent
 * names that are undefined. This situation is not allowed by the language, so objects implementing
 * this interface always represent an error. As a result, most of the normal operations on elements
 * do not make sense and will return useless results.
 * @coverage dart.engine.element
 */
abstract class UndefinedElement implements Element {
}
/**
 * The interface {@code UriReferencedElement} defines the behavior of objects included into a
 * library using some URI.
 * @coverage dart.engine.element
 */
abstract class UriReferencedElement implements Element {

  /**
   * Return the URI that is used to include this element into the enclosing library, or {@code null}if this is the defining compilation unit of a library.
   * @return the URI that is used to include this element into the enclosing library
   */
  String get uri;
}
/**
 * The interface {@code VariableElement} defines the behavior common to elements that represent a
 * variable.
 * @coverage dart.engine.element
 */
abstract class VariableElement implements Element {

  /**
   * Return a synthetic function representing this variable's initializer, or {@code null} if this
   * variable does not have an initializer. The function will have no parameters. The return type of
   * the function will be the compile-time type of the initialization expression.
   * @return a synthetic function representing this variable's initializer
   */
  FunctionElement get initializer;

  /**
   * Return the declared type of this variable, or {@code null} if the variable did not have a
   * declared type (such as if it was declared using the keyword 'var').
   * @return the declared type of this variable
   */
  Type2 get type;

  /**
   * Return {@code true} if this variable was declared with the 'const' modifier.
   * @return {@code true} if this variable was declared with the 'const' modifier
   */
  bool isConst();

  /**
   * Return {@code true} if this variable was declared with the 'final' modifier. Variables that are
   * declared with the 'const' modifier will return {@code false} even though they are implicitly
   * final.
   * @return {@code true} if this variable was declared with the 'final' modifier
   */
  bool isFinal();
}
/**
 * Instances of the class {@code GeneralizingElementVisitor} implement an element visitor that will
 * recursively visit all of the elements in an element model (like instances of the class{@link RecursiveElementVisitor}). In addition, when an element of a specific type is visited not
 * only will the visit method for that specific type of element be invoked, but additional methods
 * for the supertypes of that element will also be invoked. For example, using an instance of this
 * class to visit a {@link MethodElement} will cause the method{@link #visitMethodElement(MethodElement)} to be invoked but will also cause the methods{@link #visitExecutableElement(ExecutableElement)} and {@link #visitElement(Element)} to be
 * subsequently invoked. This allows visitors to be written that visit all executable elements
 * without needing to override the visit method for each of the specific subclasses of{@link ExecutableElement}.
 * <p>
 * Note, however, that unlike many visitors, element visitors visit objects based on the interfaces
 * implemented by those elements. Because interfaces form a graph structure rather than a tree
 * structure the way classes do, and because it is generally undesirable for an object to be visited
 * more than once, this class flattens the interface graph into a pseudo-tree. In particular, this
 * class treats elements as if the element types were structured in the following way:
 * <p>
 * <pre>
 * Element
 * ClassElement
 * CompilationUnitElement
 * ExecutableElement
 * ConstructorElement
 * LocalElement
 * FunctionElement
 * MethodElement
 * PropertyAccessorElement
 * ExportElement
 * HtmlElement
 * ImportElement
 * LabelElement
 * LibraryElement
 * MultiplyDefinedElement
 * PrefixElement
 * TypeAliasElement
 * TypeVariableElement
 * UndefinedElement
 * VariableElement
 * PropertyInducingElement
 * FieldElement
 * TopLevelVariableElement
 * LocalElement
 * LocalVariableElement
 * ParameterElement
 * FieldFormalParameterElement
 * </pre>
 * <p>
 * Subclasses that override a visit method must either invoke the overridden visit method or
 * explicitly invoke the more general visit method. Failure to do so will cause the visit methods
 * for superclasses of the element to not be invoked and will cause the children of the visited node
 * to not be visited.
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
      return visitVariableElement((element as LocalVariableElement));
    } else if (element is ParameterElement) {
      return visitVariableElement((element as ParameterElement));
    } else if (element is FunctionElement) {
      return visitExecutableElement((element as FunctionElement));
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
  R visitTypeVariableElement(TypeVariableElement element) => visitElement(element);
  R visitVariableElement(VariableElement element) => visitElement(element);
}
/**
 * Instances of the class {@code RecursiveElementVisitor} implement an element visitor that will
 * recursively visit all of the element in an element model. For example, using an instance of this
 * class to visit a {@link CompilationUnitElement} will also cause all of the types in the
 * compilation unit to be visited.
 * <p>
 * Subclasses that override a visit method must either invoke the overridden visit method or must
 * explicitly ask the visited element to visit its children. Failure to do so will cause the
 * children of the visited element to not be visited.
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
  R visitTypeVariableElement(TypeVariableElement element) {
    element.visitChildren(this);
    return null;
  }
}
/**
 * Instances of the class {@code SimpleElementVisitor} implement an element visitor that will do
 * nothing when visiting an element. It is intended to be a superclass for classes that use the
 * visitor pattern primarily as a dispatch mechanism (and hence don't need to recursively visit a
 * whole structure) and that only need to visit a small number of element types.
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
  R visitTypeVariableElement(TypeVariableElement element) => null;
}
/**
 * Instances of the class {@code ClassElementImpl} implement a {@code ClassElement}.
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
   * The superclass of the class, or {@code null} if the class does not have an explicit superclass.
   */
  InterfaceType _supertype;

  /**
   * The type defined by the class.
   */
  InterfaceType _type;

  /**
   * An array containing all of the type variables defined for this class.
   */
  List<TypeVariableElement> _typeVariables = TypeVariableElementImpl.EMPTY_ARRAY;

  /**
   * An empty array of type elements.
   */
  static List<ClassElement> EMPTY_ARRAY = new List<ClassElement>(0);

  /**
   * Initialize a newly created class element to have the given name.
   * @param name the name of this element
   */
  ClassElementImpl(Identifier name) : super.con1(name) {
  }
  accept(ElementVisitor visitor) => visitor.visitClassElement(this);
  List<PropertyAccessorElement> get accessors => _accessors;
  List<InterfaceType> get allSupertypes {
    List<InterfaceType> list = new List<InterfaceType>();
    collectAllSupertypes(list);
    return new List.from(list);
  }
  ElementImpl getChild(String identifier2) {
    for (PropertyAccessorElement accessor in _accessors) {
      if (((accessor as PropertyAccessorElementImpl)).identifier == identifier2) {
        return accessor as PropertyAccessorElementImpl;
      }
    }
    for (ConstructorElement constructor in _constructors) {
      if (((constructor as ConstructorElementImpl)).identifier == identifier2) {
        return constructor as ConstructorElementImpl;
      }
    }
    for (FieldElement field in _fields) {
      if (((field as FieldElementImpl)).identifier == identifier2) {
        return field as FieldElementImpl;
      }
    }
    for (MethodElement method in _methods) {
      if (((method as MethodElementImpl)).identifier == identifier2) {
        return method as MethodElementImpl;
      }
    }
    for (TypeVariableElement typeVariable in _typeVariables) {
      if (((typeVariable as TypeVariableElementImpl)).identifier == identifier2) {
        return typeVariable as TypeVariableElementImpl;
      }
    }
    return null;
  }
  List<ConstructorElement> get constructors => _constructors;

  /**
   * Given some name, this returns the {@link FieldElement} with the matching name, if there is no
   * such field, then {@code null} is returned.
   * @param name some name to lookup a field element with
   * @return the matching field element, or {@code null} if no such element was found
   */
  FieldElement getField(String name2) {
    for (FieldElement fieldElement in _fields) {
      if (name2 == fieldElement.name) {
        return fieldElement;
      }
    }
    return null;
  }
  List<FieldElement> get fields => _fields;
  PropertyAccessorElement getGetter(String getterName) {
    for (PropertyAccessorElement accessor in _accessors) {
      if (accessor.isGetter() && accessor.name == getterName) {
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
  ConstructorElement getNamedConstructor(String name2) {
    for (ConstructorElement element in constructors) {
      String elementName = element.name;
      if (elementName != null && elementName == name2) {
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
      if (accessor.isSetter() && accessor.name == setterName) {
        return accessor;
      }
    }
    return null;
  }
  InterfaceType get supertype => _supertype;
  InterfaceType get type => _type;
  List<TypeVariableElement> get typeVariables => _typeVariables;
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
      if (javaSetAdd(visitedClasses, currentElement)) {
        for (FieldElement field in currentElement.fields) {
          if (!field.isFinal() && !field.isConst() && !field.isStatic() && !field.isSynthetic()) {
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
  bool isAbstract() => hasModifier(Modifier.ABSTRACT);
  bool isTypedef() => hasModifier(Modifier.TYPEDEF);
  bool isValidMixin() => hasModifier(Modifier.MIXIN);
  PropertyAccessorElement lookUpGetter(String getterName, LibraryElement library) {
    Set<ClassElement> visitedClasses = new Set<ClassElement>();
    ClassElement currentElement = this;
    while (currentElement != null && !visitedClasses.contains(currentElement)) {
      javaSetAdd(visitedClasses, currentElement);
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
      javaSetAdd(visitedClasses, currentElement);
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
      javaSetAdd(visitedClasses, currentElement);
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
   * @param isAbstract {@code true} if the class is abstract
   */
  void set abstract(bool isAbstract) {
    setModifier(Modifier.ABSTRACT, isAbstract);
  }

  /**
   * Set the accessors contained in this class to the given accessors.
   * @param accessors the accessors contained in this class
   */
  void set accessors(List<PropertyAccessorElement> accessors2) {
    for (PropertyAccessorElement accessor in accessors2) {
      ((accessor as PropertyAccessorElementImpl)).enclosingElement = this;
    }
    this._accessors = accessors2;
  }

  /**
   * Set the constructors contained in this class to the given constructors.
   * @param constructors the constructors contained in this class
   */
  void set constructors(List<ConstructorElement> constructors2) {
    for (ConstructorElement constructor in constructors2) {
      ((constructor as ConstructorElementImpl)).enclosingElement = this;
    }
    this._constructors = constructors2;
  }

  /**
   * Set the fields contained in this class to the given fields.
   * @param fields the fields contained in this class
   */
  void set fields(List<FieldElement> fields2) {
    for (FieldElement field in fields2) {
      ((field as FieldElementImpl)).enclosingElement = this;
    }
    this._fields = fields2;
  }

  /**
   * Set whether this class references 'super' to the given value.
   * @param isReferencedSuper {@code true} references 'super'
   */
  void set hasReferenceToSuper2(bool isReferencedSuper) {
    setModifier(Modifier.REFERENCES_SUPER, isReferencedSuper);
  }

  /**
   * Set the interfaces that are implemented by this class to the given types.
   * @param the interfaces that are implemented by this class
   */
  void set interfaces(List<InterfaceType> interfaces2) {
    this._interfaces = interfaces2;
  }

  /**
   * Set the methods contained in this class to the given methods.
   * @param methods the methods contained in this class
   */
  void set methods(List<MethodElement> methods2) {
    for (MethodElement method in methods2) {
      ((method as MethodElementImpl)).enclosingElement = this;
    }
    this._methods = methods2;
  }

  /**
   * Set the mixins that are applied to the class being extended in order to derive the superclass
   * of this class to the given types.
   * @param mixins the mixins that are applied to derive the superclass of this class
   */
  void set mixins(List<InterfaceType> mixins2) {
    this._mixins = mixins2;
  }

  /**
   * Set the superclass of the class to the given type.
   * @param supertype the superclass of the class
   */
  void set supertype(InterfaceType supertype2) {
    this._supertype = supertype2;
  }

  /**
   * Set the type defined by the class to the given type.
   * @param type the type defined by the class
   */
  void set type(InterfaceType type2) {
    this._type = type2;
  }

  /**
   * Set whether this class is defined by a typedef construct to correspond to the given value.
   * @param isTypedef {@code true} if the class is defined by a typedef construct
   */
  void set typedef(bool isTypedef) {
    setModifier(Modifier.TYPEDEF, isTypedef);
  }

  /**
   * Set the type variables defined for this class to the given type variables.
   * @param typeVariables the type variables defined for this class
   */
  void set typeVariables(List<TypeVariableElement> typeVariables2) {
    for (TypeVariableElement typeVariable in typeVariables2) {
      ((typeVariable as TypeVariableElementImpl)).enclosingElement = this;
    }
    this._typeVariables = typeVariables2;
  }

  /**
   * Set whether this class is a valid mixin to correspond to the given value.
   * @param isValidMixin {@code true} if this class can be used as a mixin
   */
  void set validMixin(bool isValidMixin) {
    setModifier(Modifier.MIXIN, isValidMixin);
  }
  void visitChildren(ElementVisitor<Object> visitor) {
    super.visitChildren(visitor);
    safelyVisitChildren(_accessors, visitor);
    safelyVisitChildren(_constructors, visitor);
    safelyVisitChildren(_fields, visitor);
    safelyVisitChildren(_methods, visitor);
    safelyVisitChildren(_typeVariables, visitor);
  }
  void appendTo(JavaStringBuilder builder) {
    String name = displayName;
    if (name == null) {
      builder.append("{unnamed class}");
    } else {
      builder.append(name);
    }
    int variableCount = _typeVariables.length;
    if (variableCount > 0) {
      builder.append("<");
      for (int i = 0; i < variableCount; i++) {
        if (i > 0) {
          builder.append(", ");
        }
        ((_typeVariables[i] as TypeVariableElementImpl)).appendTo(builder);
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
 * Instances of the class {@code CompilationUnitElementImpl} implement a{@link CompilationUnitElement}.
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
   * The URI that is specified by the "part" directive in the enclosing library, or {@code null} if
   * this is the defining compilation unit of a library.
   */
  String _uri;

  /**
   * Initialize a newly created compilation unit element to have the given name.
   * @param name the name of this element
   */
  CompilationUnitElementImpl(String name) : super.con2(name, -1) {
  }
  accept(ElementVisitor visitor) => visitor.visitCompilationUnitElement(this);
  bool operator ==(Object object) => object != null && runtimeType == object.runtimeType && _source == ((object as CompilationUnitElementImpl)).source;
  List<PropertyAccessorElement> get accessors => _accessors;
  ElementImpl getChild(String identifier2) {
    for (PropertyAccessorElement accessor in _accessors) {
      if (((accessor as PropertyAccessorElementImpl)).identifier == identifier2) {
        return accessor as PropertyAccessorElementImpl;
      }
    }
    for (VariableElement variable in _variables) {
      if (((variable as VariableElementImpl)).identifier == identifier2) {
        return variable as VariableElementImpl;
      }
    }
    for (ExecutableElement function in _functions) {
      if (((function as ExecutableElementImpl)).identifier == identifier2) {
        return function as ExecutableElementImpl;
      }
    }
    for (FunctionTypeAliasElement typeAlias in _typeAliases) {
      if (((typeAlias as FunctionTypeAliasElementImpl)).identifier == identifier2) {
        return typeAlias as FunctionTypeAliasElementImpl;
      }
    }
    for (ClassElement type in _types) {
      if (((type as ClassElementImpl)).identifier == identifier2) {
        return type as ClassElementImpl;
      }
    }
    return null;
  }
  LibraryElement get enclosingElement => super.enclosingElement as LibraryElement;
  List<FunctionElement> get functions => _functions;
  List<FunctionTypeAliasElement> get functionTypeAliases => _typeAliases;
  String get identifier => source.encoding;
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
   * @param the top-level accessors (getters and setters) contained in this compilation unit
   */
  void set accessors(List<PropertyAccessorElement> accessors2) {
    for (PropertyAccessorElement accessor in accessors2) {
      ((accessor as PropertyAccessorElementImpl)).enclosingElement = this;
    }
    this._accessors = accessors2;
  }

  /**
   * Set the top-level functions contained in this compilation unit to the given functions.
   * @param functions the top-level functions contained in this compilation unit
   */
  void set functions(List<FunctionElement> functions2) {
    for (FunctionElement function in functions2) {
      ((function as FunctionElementImpl)).enclosingElement = this;
    }
    this._functions = functions2;
  }

  /**
   * Set the source that corresponds to this compilation unit to the given source.
   * @param source the source that corresponds to this compilation unit
   */
  void set source(Source source2) {
    this._source = source2;
  }

  /**
   * Set the top-level variables contained in this compilation unit to the given variables.
   * @param variables the top-level variables contained in this compilation unit
   */
  void set topLevelVariables(List<TopLevelVariableElement> variables2) {
    for (TopLevelVariableElement field in variables2) {
      ((field as TopLevelVariableElementImpl)).enclosingElement = this;
    }
    this._variables = variables2;
  }

  /**
   * Set the function type aliases contained in this compilation unit to the given type aliases.
   * @param typeAliases the function type aliases contained in this compilation unit
   */
  void set typeAliases(List<FunctionTypeAliasElement> typeAliases2) {
    for (FunctionTypeAliasElement typeAlias in typeAliases2) {
      ((typeAlias as FunctionTypeAliasElementImpl)).enclosingElement = this;
    }
    this._typeAliases = typeAliases2;
  }

  /**
   * Set the types contained in this compilation unit to the given types.
   * @param types types contained in this compilation unit
   */
  void set types(List<ClassElement> types2) {
    for (ClassElement type in types2) {
      ((type as ClassElementImpl)).enclosingElement = this;
    }
    this._types = types2;
  }

  /**
   * Set the URI that is specified by the "part" directive in the enclosing library.
   * @param uri the URI that is specified by the "part" directive in the enclosing library.
   */
  void set uri(String uri2) {
    this._uri = uri2;
  }
  void visitChildren(ElementVisitor<Object> visitor) {
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
}
/**
 * Instances of the class {@code ConstFieldElementImpl} implement a {@code FieldElement} for a
 * 'const' field that has an initializer.
 */
class ConstFieldElementImpl extends FieldElementImpl {

  /**
   * The result of evaluating this variable's initializer.
   */
  EvaluationResultImpl _result;

  /**
   * Initialize a newly created field element to have the given name.
   * @param name the name of this element
   */
  ConstFieldElementImpl(Identifier name) : super.con1(name) {
  }
  EvaluationResultImpl get evaluationResult => _result;
  void set evaluationResult(EvaluationResultImpl result2) {
    this._result = result2;
  }
}
/**
 * Instances of the class {@code ConstLocalVariableElementImpl} implement a{@code LocalVariableElement} for a local 'const' variable that has an initializer.
 * @coverage dart.engine.element
 */
class ConstLocalVariableElementImpl extends LocalVariableElementImpl {

  /**
   * The result of evaluating this variable's initializer.
   */
  EvaluationResultImpl _result;

  /**
   * Initialize a newly created local variable element to have the given name.
   * @param name the name of this element
   */
  ConstLocalVariableElementImpl(Identifier name) : super(name) {
  }
  EvaluationResultImpl get evaluationResult => _result;
  void set evaluationResult(EvaluationResultImpl result2) {
    this._result = result2;
  }
}
/**
 * Instances of the class {@code ConstParameterElementImpl} implement a {@code ParameterElement} for
 * a 'const' parameter that has an initializer.
 * @coverage dart.engine.element
 */
class ConstParameterElementImpl extends ParameterElementImpl {

  /**
   * The result of evaluating this variable's initializer.
   */
  EvaluationResultImpl _result;

  /**
   * Initialize a newly created parameter element to have the given name.
   * @param name the name of this element
   */
  ConstParameterElementImpl(Identifier name) : super(name) {
  }
  EvaluationResultImpl get evaluationResult => _result;
  void set evaluationResult(EvaluationResultImpl result2) {
    this._result = result2;
  }
}
/**
 * Instances of the class {@code ConstTopLevelVariableElementImpl} implement a{@code TopLevelVariableElement} for a top-level 'const' variable that has an initializer.
 */
class ConstTopLevelVariableElementImpl extends TopLevelVariableElementImpl {

  /**
   * The result of evaluating this variable's initializer.
   */
  EvaluationResultImpl _result;

  /**
   * Initialize a newly created top-level variable element to have the given name.
   * @param name the name of this element
   */
  ConstTopLevelVariableElementImpl(Identifier name) : super.con1(name) {
  }
  EvaluationResultImpl get evaluationResult => _result;
  void set evaluationResult(EvaluationResultImpl result2) {
    this._result = result2;
  }
}
/**
 * Instances of the class {@code ConstructorElementImpl} implement a {@code ConstructorElement}.
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
   * @param name the name of this element
   */
  ConstructorElementImpl(Identifier name) : super.con1(name) {
  }
  accept(ElementVisitor visitor) => visitor.visitConstructorElement(this);
  ClassElement get enclosingElement => super.enclosingElement as ClassElement;
  ElementKind get kind => ElementKind.CONSTRUCTOR;
  ConstructorElement get redirectedConstructor => _redirectedConstructor;
  bool isConst() => hasModifier(Modifier.CONST);
  bool isFactory() => hasModifier(Modifier.FACTORY);
  bool isStatic() => false;

  /**
   * Set whether this constructor represents a 'const' constructor to the given value.
   * @param isConst {@code true} if this constructor represents a 'const' constructor
   */
  void set const2(bool isConst) {
    setModifier(Modifier.CONST, isConst);
  }

  /**
   * Set whether this constructor represents a factory method to the given value.
   * @param isFactory {@code true} if this constructor represents a factory method
   */
  void set factory(bool isFactory) {
    setModifier(Modifier.FACTORY, isFactory);
  }

  /**
   * Sets the constructor to which this constructor is redirecting.
   * @param redirectedConstructor the constructor to which this constructor is redirecting
   */
  void set redirectedConstructor(ConstructorElement redirectedConstructor2) {
    this._redirectedConstructor = redirectedConstructor2;
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
 * Instances of the class {@code DynamicElementImpl} represent the synthetic element representing
 * the declaration of the type {@code dynamic}.
 * @coverage dart.engine.element
 */
class DynamicElementImpl extends ElementImpl {

  /**
   * Return the unique instance of this class.
   * @return the unique instance of this class
   */
  static DynamicElementImpl get instance => DynamicTypeImpl.instance.element as DynamicElementImpl;

  /**
   * The type defined by this element.
   */
  DynamicTypeImpl _type;

  /**
   * Initialize a newly created instance of this class. Instances of this class should <b>not</b> be
   * created except as part of creating the type associated with this element. The single instance
   * of this class should be accessed through the method {@link #getInstance()}.
   */
  DynamicElementImpl() : super.con2(Keyword.DYNAMIC.syntax, -1) {
    setModifier(Modifier.SYNTHETIC, true);
  }
  accept(ElementVisitor visitor) => null;
  ElementKind get kind => ElementKind.DYNAMIC;

  /**
   * Return the type defined by this element.
   * @return the type defined by this element
   */
  DynamicTypeImpl get type => _type;

  /**
   * Set the type defined by this element to the given type.
   * @param type the type defined by this element
   */
  void set type(DynamicTypeImpl type2) {
    this._type = type2;
  }
}
/**
 * Instances of the class {@code ElementAnnotationImpl} implement an {@link ElementAnnotation}.
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
   * Initialize a newly created annotation.
   * @param element the element representing the field, variable, or constructor being used as an
   * annotation
   */
  ElementAnnotationImpl(Element element) {
    this._element = element;
  }
  Element get element => _element;
  String toString() => "@${_element.toString()}";
}
/**
 * The abstract class {@code ElementImpl} implements the behavior common to objects that implement
 * an {@link Element}.
 * @coverage dart.engine.element
 */
abstract class ElementImpl implements Element {

  /**
   * The enclosing element of this element, or {@code null} if this element is at the root of the
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
  Set<Modifier> _modifiers;

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
   * @param name the name of this element
   */
  ElementImpl.con1(Identifier name2) {
    _jtd_constructor_194_impl(name2);
  }
  _jtd_constructor_194_impl(Identifier name2) {
    _jtd_constructor_195_impl(name2 == null ? "" : name2.name, name2 == null ? -1 : name2.offset);
  }

  /**
   * Initialize a newly created element to have the given name.
   * @param name the name of this element
   * @param nameOffset the offset of the name of this element in the file that contains the
   * declaration of this element
   */
  ElementImpl.con2(String name2, int nameOffset2) {
    _jtd_constructor_195_impl(name2, nameOffset2);
  }
  _jtd_constructor_195_impl(String name2, int nameOffset2) {
    this._name = StringUtilities.intern(name2);
    this._nameOffset = nameOffset2;
  }
  String computeDocumentationComment() {
    AnalysisContext context = this.context;
    if (context == null) {
      return null;
    }
    return context.computeDocumentationComment(this);
  }
  bool operator ==(Object object) => object != null && object.runtimeType == runtimeType && ((object as Element)).location == location;
  Element getAncestor(Type elementClass) {
    Element ancestor = _enclosingElement;
    while (ancestor != null && !isInstanceOf(ancestor, elementClass)) {
      ancestor = ancestor.enclosingElement;
    }
    return ancestor as Element;
  }

  /**
   * Return the child of this element that is uniquely identified by the given identifier, or{@code null} if there is no such child.
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
  bool isAccessibleIn(LibraryElement library2) {
    if (Identifier.isPrivateName(_name)) {
      return library2 == library;
    }
    return true;
  }
  bool isSynthetic() => hasModifier(Modifier.SYNTHETIC);

  /**
   * Set the metadata associate with this element to the given array of annotations.
   * @param metadata the metadata to be associated with this element
   */
  void set metadata(List<ElementAnnotation> metadata2) {
    this._metadata = metadata2;
  }

  /**
   * Set the offset of the name of this element in the file that contains the declaration of this
   * element to the given value. This is normally done via the constructor, but this method is
   * provided to support unnamed constructors.
   * @param nameOffset the offset to the beginning of the name
   */
  void set nameOffset(int nameOffset2) {
    this._nameOffset = nameOffset2;
  }

  /**
   * Set whether this element is synthetic to correspond to the given value.
   * @param isSynthetic {@code true} if the element is synthetic
   */
  void set synthetic(bool isSynthetic) {
    setModifier(Modifier.SYNTHETIC, isSynthetic);
  }
  String toString() {
    JavaStringBuilder builder = new JavaStringBuilder();
    appendTo(builder);
    return builder.toString();
  }
  void visitChildren(ElementVisitor<Object> visitor) {
  }

  /**
   * Append a textual representation of this type to the given builder.
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
   * @return an identifier that uniquely identifies this element relative to its parent
   */
  String get identifier => name;

  /**
   * Return {@code true} if this element has the given modifier associated with it.
   * @param modifier the modifier being tested for
   * @return {@code true} if this element has the given modifier associated with it
   */
  bool hasModifier(Modifier modifier) => _modifiers != null && _modifiers.contains(modifier);

  /**
   * If the given child is not {@code null}, use the given visitor to visit it.
   * @param child the child to be visited
   * @param visitor the visitor to be used to visit the child
   */
  void safelyVisitChild(Element child, ElementVisitor<Object> visitor) {
    if (child != null) {
      child.accept(visitor);
    }
  }

  /**
   * Use the given visitor to visit all of the children in the given array.
   * @param children the children to be visited
   * @param visitor the visitor being used to visit the children
   */
  void safelyVisitChildren(List<Element> children, ElementVisitor<Object> visitor) {
    if (children != null) {
      for (Element child in children) {
        child.accept(visitor);
      }
    }
  }

  /**
   * Set the enclosing element of this element to the given element.
   * @param element the enclosing element of this element
   */
  void set enclosingElement(ElementImpl element) {
    _enclosingElement = element;
  }

  /**
   * Set whether the given modifier is associated with this element to correspond to the given
   * value.
   * @param modifier the modifier to be set
   * @param value {@code true} if the modifier is to be associated with this element
   */
  void setModifier(Modifier modifier, bool value) {
    if (value) {
      if (_modifiers == null) {
        _modifiers = new Set();
      }
      _modifiers.add(modifier);
    } else {
      if (_modifiers != null) {
        _modifiers.remove(modifier);
        if (_modifiers.isEmpty) {
          _modifiers = null;
        }
      }
    }
  }
}
/**
 * Instances of the class {@code ElementLocationImpl} implement an {@link ElementLocation}.
 * @coverage dart.engine.element
 */
class ElementLocationImpl implements ElementLocation {

  /**
   * The path to the element whose location is represented by this object.
   */
  List<String> _components;

  /**
   * The character used to separate components in the encoded form.
   */
  static int _SEPARATOR_CHAR = 0x3B;

  /**
   * Initialize a newly created location to represent the given element.
   * @param element the element whose location is being represented
   */
  ElementLocationImpl.con1(Element element) {
    _jtd_constructor_196_impl(element);
  }
  _jtd_constructor_196_impl(Element element) {
    List<String> components = new List<String>();
    Element ancestor = element;
    while (ancestor != null) {
      components.insert(0, ((ancestor as ElementImpl)).identifier);
      ancestor = ancestor.enclosingElement;
    }
    this._components = new List.from(components);
  }

  /**
   * Initialize a newly created location from the given encoded form.
   * @param encoding the encoded form of a location
   */
  ElementLocationImpl.con2(String encoding) {
    _jtd_constructor_197_impl(encoding);
  }
  _jtd_constructor_197_impl(String encoding) {
    this._components = decode(encoding);
  }
  bool operator ==(Object object) {
    if (object is! ElementLocationImpl) {
      return false;
    }
    ElementLocationImpl location = object as ElementLocationImpl;
    List<String> otherComponents = location._components;
    int length = _components.length;
    if (otherComponents.length != length) {
      return false;
    }
    if (length > 0 && !equalSourceComponents(_components[0], otherComponents[0])) {
      return false;
    }
    if (length > 1 && !equalSourceComponents(_components[1], otherComponents[1])) {
      return false;
    }
    for (int i = 2; i < length; i++) {
      if (_components[i] != otherComponents[i]) {
        return false;
      }
    }
    return true;
  }

  /**
   * Return the path to the element whose location is represented by this object.
   * @return the path to the element whose location is represented by this object
   */
  List<String> get components => _components;
  String get encoding {
    JavaStringBuilder builder = new JavaStringBuilder();
    int length = _components.length;
    for (int i = 0; i < length; i++) {
      if (i > 0) {
        builder.appendChar(_SEPARATOR_CHAR);
      }
      encode(builder, _components[i]);
    }
    return builder.toString();
  }
  int get hashCode => JavaArrays.makeHashCode(_components);
  String toString() => encoding;

  /**
   * Decode the encoded form of a location into an array of components.
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
   * Return {@code true} if the given components, when interpreted to be encoded sources with a
   * leading source type indicator, are equal when the source type's are ignored.
   * @param left the left component being compared
   * @param right the right component being compared
   * @return {@code true} if the given components are equal when the source type's are ignored
   */
  bool equalSourceComponents(String left, String right) {
    if (left == null) {
      return right == null;
    } else if (right == null) {
      return false;
    }
    if (left.length <= 1 || right.length <= 1) {
      return left == right;
    }
    return left.substring(1) == right.substring(1);
  }
}
/**
 * Instances of the class {@code EmbeddedHtmlScriptElementImpl} implement an{@link EmbeddedHtmlScriptElement}.
 * @coverage dart.engine.element
 */
class EmbeddedHtmlScriptElementImpl extends HtmlScriptElementImpl implements EmbeddedHtmlScriptElement {

  /**
   * The library defined by the script tag's content.
   */
  LibraryElement _scriptLibrary;

  /**
   * Initialize a newly created script element to have the specified tag name and offset.
   * @param node the XML node from which this element is derived (not {@code null})
   */
  EmbeddedHtmlScriptElementImpl(XmlTagNode node) : super(node) {
  }
  accept(ElementVisitor visitor) => visitor.visitEmbeddedHtmlScriptElement(this);
  ElementKind get kind => ElementKind.EMBEDDED_HTML_SCRIPT;
  LibraryElement get scriptLibrary => _scriptLibrary;

  /**
   * Set the script library defined by the script tag's content.
   * @param scriptLibrary the library or {@code null} if none
   */
  void set scriptLibrary(LibraryElementImpl scriptLibrary2) {
    scriptLibrary2.enclosingElement = this;
    this._scriptLibrary = scriptLibrary2;
  }
  void visitChildren(ElementVisitor<Object> visitor) {
    safelyVisitChild(_scriptLibrary, visitor);
  }
}
/**
 * The abstract class {@code ExecutableElementImpl} implements the behavior common to{@code ExecutableElement}s.
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
   * The type of function defined by this executable element.
   */
  FunctionType _type;

  /**
   * An empty array of executable elements.
   */
  static List<ExecutableElement> EMPTY_ARRAY = new List<ExecutableElement>(0);

  /**
   * Initialize a newly created executable element to have the given name.
   * @param name the name of this element
   */
  ExecutableElementImpl.con1(Identifier name) : super.con1(name) {
    _jtd_constructor_199_impl(name);
  }
  _jtd_constructor_199_impl(Identifier name) {
  }

  /**
   * Initialize a newly created executable element to have the given name.
   * @param name the name of this element
   * @param nameOffset the offset of the name of this element in the file that contains the
   * declaration of this element
   */
  ExecutableElementImpl.con2(String name, int nameOffset) : super.con2(name, nameOffset) {
    _jtd_constructor_200_impl(name, nameOffset);
  }
  _jtd_constructor_200_impl(String name, int nameOffset) {
  }
  ElementImpl getChild(String identifier2) {
    for (ExecutableElement function in _functions) {
      if (((function as ExecutableElementImpl)).identifier == identifier2) {
        return function as ExecutableElementImpl;
      }
    }
    for (LabelElement label in _labels) {
      if (((label as LabelElementImpl)).identifier == identifier2) {
        return label as LabelElementImpl;
      }
    }
    for (VariableElement variable in _localVariables) {
      if (((variable as VariableElementImpl)).identifier == identifier2) {
        return variable as VariableElementImpl;
      }
    }
    for (ParameterElement parameter in _parameters) {
      if (((parameter as ParameterElementImpl)).identifier == identifier2) {
        return parameter as ParameterElementImpl;
      }
    }
    return null;
  }
  List<FunctionElement> get functions => _functions;
  List<LabelElement> get labels => _labels;
  List<LocalVariableElement> get localVariables => _localVariables;
  List<ParameterElement> get parameters => _parameters;
  FunctionType get type => _type;
  bool isOperator() => false;

  /**
   * Set the functions defined within this executable element to the given functions.
   * @param functions the functions defined within this executable element
   */
  void set functions(List<FunctionElement> functions2) {
    for (FunctionElement function in functions2) {
      ((function as FunctionElementImpl)).enclosingElement = this;
    }
    this._functions = functions2;
  }

  /**
   * Set the labels defined within this executable element to the given labels.
   * @param labels the labels defined within this executable element
   */
  void set labels(List<LabelElement> labels2) {
    for (LabelElement label in labels2) {
      ((label as LabelElementImpl)).enclosingElement = this;
    }
    this._labels = labels2;
  }

  /**
   * Set the local variables defined within this executable element to the given variables.
   * @param localVariables the local variables defined within this executable element
   */
  void set localVariables(List<LocalVariableElement> localVariables2) {
    for (LocalVariableElement variable in localVariables2) {
      ((variable as LocalVariableElementImpl)).enclosingElement = this;
    }
    this._localVariables = localVariables2;
  }

  /**
   * Set the parameters defined by this executable element to the given parameters.
   * @param parameters the parameters defined by this executable element
   */
  void set parameters(List<ParameterElement> parameters2) {
    for (ParameterElement parameter in parameters2) {
      ((parameter as ParameterElementImpl)).enclosingElement = this;
    }
    this._parameters = parameters2;
  }

  /**
   * Set the type of function defined by this executable element to the given type.
   * @param type the type of function defined by this executable element
   */
  void set type(FunctionType type2) {
    this._type = type2;
  }
  void visitChildren(ElementVisitor<Object> visitor) {
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
      ((_parameters[i] as ParameterElementImpl)).appendTo(builder);
    }
    builder.append(")");
    if (_type != null) {
      builder.append(" -> ");
      builder.append(_type.returnType);
    }
  }
}
/**
 * Instances of the class {@code ExportElementImpl} implement an {@link ExportElement}.
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
  ExportElementImpl() : super.con1(null) {
  }
  accept(ElementVisitor visitor) => visitor.visitExportElement(this);
  List<NamespaceCombinator> get combinators => _combinators;
  LibraryElement get exportedLibrary => _exportedLibrary;
  ElementKind get kind => ElementKind.EXPORT;
  String get uri => _uri;

  /**
   * Set the combinators that were specified as part of the export directive to the given array of
   * combinators.
   * @param combinators the combinators that were specified as part of the export directive
   */
  void set combinators(List<NamespaceCombinator> combinators2) {
    this._combinators = combinators2;
  }

  /**
   * Set the library that is exported from this library by this import directive to the given
   * library.
   * @param exportedLibrary the library that is exported from this library
   */
  void set exportedLibrary(LibraryElement exportedLibrary2) {
    this._exportedLibrary = exportedLibrary2;
  }

  /**
   * Set the URI that is specified by this directive.
   * @param uri the URI that is specified by this directive.
   */
  void set uri(String uri2) {
    this._uri = uri2;
  }
  void appendTo(JavaStringBuilder builder) {
    builder.append("export ");
    ((_exportedLibrary as LibraryElementImpl)).appendTo(builder);
  }
  String get identifier => _exportedLibrary.name;
}
/**
 * Instances of the class {@code ExternalHtmlScriptElementImpl} implement an{@link ExternalHtmlScriptElement}.
 * @coverage dart.engine.element
 */
class ExternalHtmlScriptElementImpl extends HtmlScriptElementImpl implements ExternalHtmlScriptElement {

  /**
   * The source specified in the {@code source} attribute or {@code null} if unspecified.
   */
  Source _scriptSource;

  /**
   * Initialize a newly created script element to have the specified tag name and offset.
   * @param node the XML node from which this element is derived (not {@code null})
   */
  ExternalHtmlScriptElementImpl(XmlTagNode node) : super(node) {
  }
  accept(ElementVisitor visitor) => visitor.visitExternalHtmlScriptElement(this);
  ElementKind get kind => ElementKind.EXTERNAL_HTML_SCRIPT;
  Source get scriptSource => _scriptSource;

  /**
   * Set the source specified in the {@code source} attribute.
   * @param scriptSource the script source or {@code null} if unspecified
   */
  void set scriptSource(Source scriptSource2) {
    this._scriptSource = scriptSource2;
  }
}
/**
 * Instances of the class {@code FieldElementImpl} implement a {@code FieldElement}.
 * @coverage dart.engine.element
 */
class FieldElementImpl extends PropertyInducingElementImpl implements FieldElement {

  /**
   * An empty array of field elements.
   */
  static List<FieldElement> EMPTY_ARRAY = new List<FieldElement>(0);

  /**
   * Initialize a newly created field element to have the given name.
   * @param name the name of this element
   */
  FieldElementImpl.con1(Identifier name) : super.con1(name) {
    _jtd_constructor_203_impl(name);
  }
  _jtd_constructor_203_impl(Identifier name) {
  }

  /**
   * Initialize a newly created synthetic field element to have the given name.
   * @param name the name of this element
   */
  FieldElementImpl.con2(String name) : super.con2(name) {
    _jtd_constructor_204_impl(name);
  }
  _jtd_constructor_204_impl(String name) {
  }
  accept(ElementVisitor visitor) => visitor.visitFieldElement(this);
  ClassElement get enclosingElement => super.enclosingElement as ClassElement;
  ElementKind get kind => ElementKind.FIELD;
  bool isStatic() => hasModifier(Modifier.STATIC);

  /**
   * Set whether this field is static to correspond to the given value.
   * @param isStatic {@code true} if the field is static
   */
  void set static(bool isStatic) {
    setModifier(Modifier.STATIC, isStatic);
  }
}
/**
 * Instances of the class {@code FieldFormalParameterElementImpl} extend{@link ParameterElementImpl} to provide the additional information of the {@link FieldElement}associated with the parameter.
 * @coverage dart.engine.element
 */
class FieldFormalParameterElementImpl extends ParameterElementImpl implements FieldFormalParameterElement {

  /**
   * The field associated with this field formal parameter.
   */
  FieldElement _field;

  /**
   * Initialize a newly created parameter element to have the given name.
   * @param name the name of this element
   */
  FieldFormalParameterElementImpl(Identifier name) : super(name) {
  }
  accept(ElementVisitor visitor) => visitor.visitFieldFormalParameterElement(this);
  FieldElement get field => _field;
  bool isInitializingFormal() => true;

  /**
   * Set the field element associated with this field formal parameter to the given element.
   * @param field the new field element
   */
  void set field(FieldElement field2) {
    this._field = field2;
  }
}
/**
 * Instances of the class {@code FunctionElementImpl} implement a {@code FunctionElement}.
 * @coverage dart.engine.element
 */
class FunctionElementImpl extends ExecutableElementImpl implements FunctionElement {

  /**
   * The offset to the beginning of the visible range for this element.
   */
  int _visibleRangeOffset = 0;

  /**
   * The length of the visible range for this element, or {@code -1} if this element does not have a
   * visible range.
   */
  int _visibleRangeLength = -1;

  /**
   * An empty array of function elements.
   */
  static List<FunctionElement> EMPTY_ARRAY = new List<FunctionElement>(0);

  /**
   * Initialize a newly created synthetic function element.
   */
  FunctionElementImpl() : super.con2("", -1) {
    _jtd_constructor_206_impl();
  }
  _jtd_constructor_206_impl() {
    synthetic = true;
  }

  /**
   * Initialize a newly created function element to have the given name.
   * @param name the name of this element
   */
  FunctionElementImpl.con1(Identifier name) : super.con1(name) {
    _jtd_constructor_207_impl(name);
  }
  _jtd_constructor_207_impl(Identifier name) {
  }

  /**
   * Initialize a newly created function element to have no name and the given offset. This is used
   * for function expressions, which have no name.
   * @param nameOffset the offset of the name of this element in the file that contains the
   * declaration of this element
   */
  FunctionElementImpl.con2(int nameOffset) : super.con2("", nameOffset) {
    _jtd_constructor_208_impl(nameOffset);
  }
  _jtd_constructor_208_impl(int nameOffset) {
  }
  accept(ElementVisitor visitor) => visitor.visitFunctionElement(this);
  String get identifier => "${name}@${nameOffset}";
  ElementKind get kind => ElementKind.FUNCTION;
  SourceRange get visibleRange {
    if (_visibleRangeLength < 0) {
      return null;
    }
    return new SourceRange(_visibleRangeOffset, _visibleRangeLength);
  }
  bool isStatic() => enclosingElement is CompilationUnitElement;

  /**
   * Set the visible range for this element to the range starting at the given offset with the given
   * length.
   * @param offset the offset to the beginning of the visible range for this element
   * @param length the length of the visible range for this element, or {@code -1} if this element
   * does not have a visible range
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
}
/**
 * Instances of the class {@code FunctionTypeAliasElementImpl} implement a{@code FunctionTypeAliasElement}.
 * @coverage dart.engine.element
 */
class FunctionTypeAliasElementImpl extends ElementImpl implements FunctionTypeAliasElement {

  /**
   * An array containing all of the parameters defined by this type alias.
   */
  List<ParameterElement> _parameters = ParameterElementImpl.EMPTY_ARRAY;

  /**
   * The type of function defined by this type alias.
   */
  FunctionType _type;

  /**
   * An array containing all of the type variables defined for this type.
   */
  List<TypeVariableElement> _typeVariables = TypeVariableElementImpl.EMPTY_ARRAY;

  /**
   * An empty array of type alias elements.
   */
  static List<FunctionTypeAliasElement> EMPTY_ARRAY = new List<FunctionTypeAliasElement>(0);

  /**
   * Initialize a newly created type alias element to have the given name.
   * @param name the name of this element
   */
  FunctionTypeAliasElementImpl(Identifier name) : super.con1(name) {
  }
  accept(ElementVisitor visitor) => visitor.visitFunctionTypeAliasElement(this);
  ElementImpl getChild(String identifier2) {
    for (VariableElement parameter in _parameters) {
      if (((parameter as VariableElementImpl)).identifier == identifier2) {
        return parameter as VariableElementImpl;
      }
    }
    for (TypeVariableElement typeVariable in _typeVariables) {
      if (((typeVariable as TypeVariableElementImpl)).identifier == identifier2) {
        return typeVariable as TypeVariableElementImpl;
      }
    }
    return null;
  }
  CompilationUnitElement get enclosingElement => super.enclosingElement as CompilationUnitElement;
  ElementKind get kind => ElementKind.FUNCTION_TYPE_ALIAS;
  List<ParameterElement> get parameters => _parameters;
  FunctionType get type => _type;
  List<TypeVariableElement> get typeVariables => _typeVariables;

  /**
   * Set the parameters defined by this type alias to the given parameters.
   * @param parameters the parameters defined by this type alias
   */
  void set parameters(List<ParameterElement> parameters2) {
    if (parameters2 != null) {
      for (ParameterElement parameter in parameters2) {
        ((parameter as ParameterElementImpl)).enclosingElement = this;
      }
    }
    this._parameters = parameters2;
  }

  /**
   * Set the type of function defined by this type alias to the given type.
   * @param type the type of function defined by this type alias
   */
  void set type(FunctionType type2) {
    this._type = type2;
  }

  /**
   * Set the type variables defined for this type to the given variables.
   * @param typeVariables the type variables defined for this type
   */
  void set typeVariables(List<TypeVariableElement> typeVariables2) {
    for (TypeVariableElement variable in typeVariables2) {
      ((variable as TypeVariableElementImpl)).enclosingElement = this;
    }
    this._typeVariables = typeVariables2;
  }
  void visitChildren(ElementVisitor<Object> visitor) {
    super.visitChildren(visitor);
    safelyVisitChildren(_parameters, visitor);
    safelyVisitChildren(_typeVariables, visitor);
  }
  void appendTo(JavaStringBuilder builder) {
    builder.append("typedef ");
    builder.append(displayName);
    int variableCount = _typeVariables.length;
    if (variableCount > 0) {
      builder.append("<");
      for (int i = 0; i < variableCount; i++) {
        if (i > 0) {
          builder.append(", ");
        }
        ((_typeVariables[i] as TypeVariableElementImpl)).appendTo(builder);
      }
      builder.append(">");
    }
    builder.append("(");
    int parameterCount = _parameters.length;
    for (int i = 0; i < parameterCount; i++) {
      if (i > 0) {
        builder.append(", ");
      }
      ((_parameters[i] as ParameterElementImpl)).appendTo(builder);
    }
    builder.append(")");
    if (_type != null) {
      builder.append(" -> ");
      builder.append(_type.returnType);
    }
  }
}
/**
 * Instances of the class {@code HideElementCombinatorImpl} implement a{@link HideElementCombinator}.
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
   * @param hiddenNames the names that are not to be made visible in the importing library
   */
  void set hiddenNames(List<String> hiddenNames2) {
    this._hiddenNames = hiddenNames2;
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
 * Instances of the class {@code HtmlElementImpl} implement an {@link HtmlElement}.
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
   * @param context the analysis context in which the HTML file is defined
   * @param name the name of this element
   */
  HtmlElementImpl(AnalysisContext context, String name) : super.con2(name, -1) {
    this._context = context;
  }
  accept(ElementVisitor visitor) => visitor.visitHtmlElement(this);
  bool operator ==(Object object) => runtimeType == object.runtimeType && _source == ((object as CompilationUnitElementImpl)).source;
  AnalysisContext get context => _context;
  ElementKind get kind => ElementKind.HTML;
  List<HtmlScriptElement> get scripts => _scripts;
  Source get source => _source;
  int get hashCode => _source.hashCode;

  /**
   * Set the scripts contained in the HTML file to the given scripts.
   * @param scripts the scripts
   */
  void set scripts(List<HtmlScriptElement> scripts2) {
    if (scripts2.length == 0) {
      scripts2 = HtmlScriptElementImpl.EMPTY_ARRAY;
    }
    for (HtmlScriptElement script in scripts2) {
      ((script as HtmlScriptElementImpl)).enclosingElement = this;
    }
    this._scripts = scripts2;
  }

  /**
   * Set the source that corresponds to this HTML file to the given source.
   * @param source the source that corresponds to this HTML file
   */
  void set source(Source source2) {
    this._source = source2;
  }
  void visitChildren(ElementVisitor<Object> visitor) {
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
 * Instances of the class {@code HtmlScriptElementImpl} implement an {@link HtmlScriptElement}.
 * @coverage dart.engine.element
 */
abstract class HtmlScriptElementImpl extends ElementImpl implements HtmlScriptElement {

  /**
   * An empty array of HTML script elements.
   */
  static List<HtmlScriptElement> EMPTY_ARRAY = new List<HtmlScriptElement>(0);

  /**
   * Initialize a newly created script element to have the specified tag name and offset.
   * @param node the XML node from which this element is derived (not {@code null})
   */
  HtmlScriptElementImpl(XmlTagNode node) : super.con2(node.tag.lexeme, node.tag.offset) {
  }
}
/**
 * Instances of the class {@code ImportElementImpl} implement an {@link ImportElement}.
 * @coverage dart.engine.element
 */
class ImportElementImpl extends ElementImpl implements ImportElement {

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
   * The prefix that was specified as part of the import directive, or {@code null} if there was no
   * prefix specified.
   */
  PrefixElement _prefix;

  /**
   * Initialize a newly created import element.
   */
  ImportElementImpl() : super.con1(null) {
  }
  accept(ElementVisitor visitor) => visitor.visitImportElement(this);
  List<NamespaceCombinator> get combinators => _combinators;
  LibraryElement get importedLibrary => _importedLibrary;
  ElementKind get kind => ElementKind.IMPORT;
  PrefixElement get prefix => _prefix;
  String get uri => _uri;

  /**
   * Set the combinators that were specified as part of the import directive to the given array of
   * combinators.
   * @param combinators the combinators that were specified as part of the import directive
   */
  void set combinators(List<NamespaceCombinator> combinators2) {
    this._combinators = combinators2;
  }

  /**
   * Set the library that is imported into this library by this import directive to the given
   * library.
   * @param importedLibrary the library that is imported into this library
   */
  void set importedLibrary(LibraryElement importedLibrary2) {
    this._importedLibrary = importedLibrary2;
  }

  /**
   * Set the prefix that was specified as part of the import directive to the given prefix.
   * @param prefix the prefix that was specified as part of the import directive
   */
  void set prefix(PrefixElement prefix2) {
    this._prefix = prefix2;
  }

  /**
   * Set the URI that is specified by this directive.
   * @param uri the URI that is specified by this directive.
   */
  void set uri(String uri2) {
    this._uri = uri2;
  }
  void visitChildren(ElementVisitor<Object> visitor) {
    super.visitChildren(visitor);
    safelyVisitChild(_prefix, visitor);
  }
  void appendTo(JavaStringBuilder builder) {
    builder.append("import ");
    ((_importedLibrary as LibraryElementImpl)).appendTo(builder);
  }
  String get identifier => ((_importedLibrary as LibraryElementImpl)).identifier;
}
/**
 * Instances of the class {@code LabelElementImpl} implement a {@code LabelElement}.
 * @coverage dart.engine.element
 */
class LabelElementImpl extends ElementImpl implements LabelElement {

  /**
   * A flag indicating whether this label is associated with a {@code switch} statement.
   */
  bool _onSwitchStatement = false;

  /**
   * A flag indicating whether this label is associated with a {@code switch} member ({@code case}or {@code default}).
   */
  bool _onSwitchMember = false;

  /**
   * An empty array of label elements.
   */
  static List<LabelElement> EMPTY_ARRAY = new List<LabelElement>(0);

  /**
   * Initialize a newly created label element to have the given name.
   * @param name the name of this element
   * @param onSwitchStatement {@code true} if this label is associated with a {@code switch}statement
   * @param onSwitchMember {@code true} if this label is associated with a {@code switch} member
   */
  LabelElementImpl(Identifier name, bool onSwitchStatement, bool onSwitchMember) : super.con1(name) {
    this._onSwitchStatement = onSwitchStatement;
    this._onSwitchMember = onSwitchMember;
  }
  accept(ElementVisitor visitor) => visitor.visitLabelElement(this);
  ExecutableElement get enclosingElement => super.enclosingElement as ExecutableElement;
  ElementKind get kind => ElementKind.LABEL;

  /**
   * Return {@code true} if this label is associated with a {@code switch} member ({@code case} or{@code default}).
   * @return {@code true} if this label is associated with a {@code switch} member
   */
  bool isOnSwitchMember() => _onSwitchMember;

  /**
   * Return {@code true} if this label is associated with a {@code switch} statement.
   * @return {@code true} if this label is associated with a {@code switch} statement
   */
  bool isOnSwitchStatement() => _onSwitchStatement;
}
/**
 * Instances of the class {@code LibraryElementImpl} implement a {@code LibraryElement}.
 * @coverage dart.engine.element
 */
class LibraryElementImpl extends ElementImpl implements LibraryElement {

  /**
   * An empty array of library elements.
   */
  static List<LibraryElement> EMPTY_ARRAY = new List<LibraryElement>(0);

  /**
   * Determine if the given library is up to date with respect to the given time stamp.
   * @param library the library to process
   * @param timeStamp the time stamp to check against
   * @param visitedLibraries the set of visited libraries
   */
  static bool isUpToDate(LibraryElement library, int timeStamp, Set<LibraryElement> visitedLibraries) {
    if (!visitedLibraries.contains(library)) {
      javaSetAdd(visitedLibraries, library);
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
   * The entry point for this library, or {@code null} if this library does not have an entry point.
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
   * An array containing all of the compilation units that are included in this library using a{@code part} directive.
   */
  List<CompilationUnitElement> _parts = CompilationUnitElementImpl.EMPTY_ARRAY;

  /**
   * Initialize a newly created library element to have the given name.
   * @param context the analysis context in which the library is defined
   * @param name the name of this element
   */
  LibraryElementImpl(AnalysisContext context, LibraryIdentifier name) : super.con1(name) {
    this._context = context;
  }
  accept(ElementVisitor visitor) => visitor.visitLibraryElement(this);
  bool operator ==(Object object) => object != null && runtimeType == object.runtimeType && _definingCompilationUnit == ((object as LibraryElementImpl)).definingCompilationUnit;
  ElementImpl getChild(String identifier2) {
    if (((_definingCompilationUnit as CompilationUnitElementImpl)).identifier == identifier2) {
      return _definingCompilationUnit as CompilationUnitElementImpl;
    }
    for (CompilationUnitElement part in _parts) {
      if (((part as CompilationUnitElementImpl)).identifier == identifier2) {
        return part as CompilationUnitElementImpl;
      }
    }
    for (ImportElement importElement in _imports) {
      if (((importElement as ImportElementImpl)).identifier == identifier2) {
        return importElement as ImportElementImpl;
      }
    }
    for (ExportElement exportElement in _exports) {
      if (((exportElement as ExportElementImpl)).identifier == identifier2) {
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
        javaSetAdd(libraries, library);
      }
    }
    return new List.from(libraries);
  }
  List<ExportElement> get exports => _exports;
  String get identifier => _definingCompilationUnit.source.encoding;
  List<LibraryElement> get importedLibraries {
    Set<LibraryElement> libraries = new Set<LibraryElement>();
    for (ImportElement element in _imports) {
      LibraryElement library = element.importedLibrary;
      if (library != null) {
        javaSetAdd(libraries, library);
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
        javaSetAdd(prefixes, prefix);
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
  bool isBrowserApplication() => _entryPoint != null && isOrImportsBrowserLibrary();
  bool isDartCore() => name == "dart.core";
  bool isUpToDate2(int timeStamp) {
    Set<LibraryElement> visitedLibraries = new Set();
    return isUpToDate(this, timeStamp, visitedLibraries);
  }

  /**
   * Set the compilation unit that defines this library to the given compilation unit.
   * @param definingCompilationUnit the compilation unit that defines this library
   */
  void set definingCompilationUnit(CompilationUnitElement definingCompilationUnit2) {
    ((definingCompilationUnit2 as CompilationUnitElementImpl)).enclosingElement = this;
    this._definingCompilationUnit = definingCompilationUnit2;
  }

  /**
   * Set the entry point for this library to the given function.
   * @param entryPoint the entry point for this library
   */
  void set entryPoint(FunctionElement entryPoint2) {
    this._entryPoint = entryPoint2;
  }

  /**
   * Set the specifications of all of the exports defined in this library to the given array.
   * @param exports the specifications of all of the exports defined in this library
   */
  void set exports(List<ExportElement> exports2) {
    for (ExportElement exportElement in exports2) {
      ((exportElement as ExportElementImpl)).enclosingElement = this;
    }
    this._exports = exports2;
  }

  /**
   * Set the specifications of all of the imports defined in this library to the given array.
   * @param imports the specifications of all of the imports defined in this library
   */
  void set imports(List<ImportElement> imports2) {
    for (ImportElement importElement in imports2) {
      ((importElement as ImportElementImpl)).enclosingElement = this;
      PrefixElementImpl prefix = importElement.prefix as PrefixElementImpl;
      if (prefix != null) {
        prefix.enclosingElement = this;
      }
    }
    this._imports = imports2;
  }

  /**
   * Set the compilation units that are included in this library using a {@code part} directive.
   * @param parts the compilation units that are included in this library using a {@code part}directive
   */
  void set parts(List<CompilationUnitElement> parts2) {
    for (CompilationUnitElement compilationUnit in parts2) {
      ((compilationUnit as CompilationUnitElementImpl)).enclosingElement = this;
    }
    this._parts = parts2;
  }
  void visitChildren(ElementVisitor<Object> visitor) {
    super.visitChildren(visitor);
    safelyVisitChild(_definingCompilationUnit, visitor);
    safelyVisitChildren(_exports, visitor);
    safelyVisitChildren(_imports, visitor);
    safelyVisitChildren(_parts, visitor);
  }

  /**
   * Answer {@code true} if the receiver directly or indirectly imports the dart:html libraries.
   * @return {@code true} if the receiver directly or indirectly imports the dart:html libraries
   */
  bool isOrImportsBrowserLibrary() {
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
 * Instances of the class {@code LocalVariableElementImpl} implement a {@code LocalVariableElement}.
 * @coverage dart.engine.element
 */
class LocalVariableElementImpl extends VariableElementImpl implements LocalVariableElement {

  /**
   * The offset to the beginning of the visible range for this element.
   */
  int _visibleRangeOffset = 0;

  /**
   * The length of the visible range for this element, or {@code -1} if this element does not have a
   * visible range.
   */
  int _visibleRangeLength = -1;

  /**
   * An empty array of field elements.
   */
  static List<LocalVariableElement> EMPTY_ARRAY = new List<LocalVariableElement>(0);

  /**
   * Initialize a newly created local variable element to have the given name.
   * @param name the name of this element
   */
  LocalVariableElementImpl(Identifier name) : super.con1(name) {
  }
  accept(ElementVisitor visitor) => visitor.visitLocalVariableElement(this);
  ElementKind get kind => ElementKind.LOCAL_VARIABLE;
  SourceRange get visibleRange {
    if (_visibleRangeLength < 0) {
      return null;
    }
    return new SourceRange(_visibleRangeOffset, _visibleRangeLength);
  }

  /**
   * Set the visible range for this element to the range starting at the given offset with the given
   * length.
   * @param offset the offset to the beginning of the visible range for this element
   * @param length the length of the visible range for this element, or {@code -1} if this element
   * does not have a visible range
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
 * Instances of the class {@code MethodElementImpl} implement a {@code MethodElement}.
 * @coverage dart.engine.element
 */
class MethodElementImpl extends ExecutableElementImpl implements MethodElement {

  /**
   * An empty array of method elements.
   */
  static List<MethodElement> EMPTY_ARRAY = new List<MethodElement>(0);

  /**
   * Initialize a newly created method element to have the given name.
   * @param name the name of this element
   */
  MethodElementImpl.con1(Identifier name) : super.con1(name) {
    _jtd_constructor_217_impl(name);
  }
  _jtd_constructor_217_impl(Identifier name) {
  }

  /**
   * Initialize a newly created method element to have the given name.
   * @param name the name of this element
   * @param nameOffset the offset of the name of this element in the file that contains the
   * declaration of this element
   */
  MethodElementImpl.con2(String name, int nameOffset) : super.con2(name, nameOffset) {
    _jtd_constructor_218_impl(name, nameOffset);
  }
  _jtd_constructor_218_impl(String name, int nameOffset) {
  }
  accept(ElementVisitor visitor) => visitor.visitMethodElement(this);
  ClassElement get enclosingElement => super.enclosingElement as ClassElement;
  ElementKind get kind => ElementKind.METHOD;
  String get name {
    String name = super.name;
    if (isOperator() && name == "-") {
      if (parameters.length == 0) {
        return "unary-";
      }
    }
    return super.name;
  }
  bool isAbstract() => hasModifier(Modifier.ABSTRACT);
  bool isOperator() {
    String name = displayName;
    if (name.isEmpty) {
      return false;
    }
    int first = name.codeUnitAt(0);
    return !((0x61 <= first && first <= 0x7A) || (0x41 <= first && first <= 0x5A) || first == 0x5F || first == 0x24);
  }
  bool isStatic() => hasModifier(Modifier.STATIC);

  /**
   * Set whether this method is abstract to correspond to the given value.
   * @param isAbstract {@code true} if the method is abstract
   */
  void set abstract(bool isAbstract) {
    setModifier(Modifier.ABSTRACT, isAbstract);
  }

  /**
   * Set whether this method is static to correspond to the given value.
   * @param isStatic {@code true} if the method is static
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
 * The enumeration {@code Modifier} defines constants for all of the modifiers defined by the Dart
 * language and for a few additional flags that are useful.
 * @coverage dart.engine.element
 */
class Modifier implements Comparable<Modifier> {
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
  static final List<Modifier> values = [ABSTRACT, CONST, FACTORY, FINAL, GETTER, MIXIN, REFERENCES_SUPER, SETTER, STATIC, SYNTHETIC, TYPEDEF];

  /// The name of this enum constant, as declared in the enum declaration.
  final String name;

  /// The position in the enum declaration.
  final int ordinal;
  Modifier(this.name, this.ordinal) {
  }
  int compareTo(Modifier other) => ordinal - other.ordinal;
  int get hashCode => ordinal;
  String toString() => name;
}
/**
 * Instances of the class {@code MultiplyDefinedElementImpl} represent a collection of elements that
 * have the same name within the same scope.
 * @coverage dart.engine.element
 */
class MultiplyDefinedElementImpl implements MultiplyDefinedElement {

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
   * @param context the analysis context in which the multiply defined elements are defined
   * @param firstElement the first element that conflicts
   * @param secondElement the second element that conflicts
   */
  MultiplyDefinedElementImpl(AnalysisContext context, Element firstElement, Element secondElement) {
    _name = firstElement.name;
    _conflictingElements = computeConflictingElements(firstElement, secondElement);
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
  bool isAccessibleIn(LibraryElement library) {
    for (Element element in _conflictingElements) {
      if (element.isAccessibleIn(library)) {
        return true;
      }
    }
    return false;
  }
  bool isSynthetic() => true;
  String toString() {
    JavaStringBuilder builder = new JavaStringBuilder();
    builder.append("[");
    int count = _conflictingElements.length;
    for (int i = 0; i < count; i++) {
      if (i > 0) {
        builder.append(", ");
      }
      ((_conflictingElements[i] as ElementImpl)).appendTo(builder);
    }
    builder.append("]");
    return builder.toString();
  }
  void visitChildren(ElementVisitor<Object> visitor) {
  }

  /**
   * Add the given element to the list of elements. If the element is a multiply-defined element,
   * add all of the conflicting elements that it represents.
   * @param elements the list to which the element(s) are to be added
   * @param element the element(s) to be added
   */
  void add(List<Element> elements, Element element) {
    if (element is MultiplyDefinedElementImpl) {
      for (Element conflictingElement in ((element as MultiplyDefinedElementImpl))._conflictingElements) {
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
   * @param firstElement the first element to be included
   * @param secondElement the second element to be included
   * @return an array containing all of the conflicting elements
   */
  List<Element> computeConflictingElements(Element firstElement, Element secondElement) {
    List<Element> elements = new List<Element>();
    add(elements, firstElement);
    add(elements, secondElement);
    return new List.from(elements);
  }
}
/**
 * Instances of the class {@code ParameterElementImpl} implement a {@code ParameterElement}.
 * @coverage dart.engine.element
 */
class ParameterElementImpl extends VariableElementImpl implements ParameterElement {

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
   * The length of the default value range for this element, or {@code -1} if this element does not
   * have a default value.
   */
  int _defaultValueRangeLength = -1;

  /**
   * The offset to the beginning of the visible range for this element.
   */
  int _visibleRangeOffset = 0;

  /**
   * The length of the visible range for this element, or {@code -1} if this element does not have a
   * visible range.
   */
  int _visibleRangeLength = -1;

  /**
   * An empty array of field elements.
   */
  static List<ParameterElement> EMPTY_ARRAY = new List<ParameterElement>(0);

  /**
   * Initialize a newly created parameter element to have the given name.
   * @param name the name of this element
   */
  ParameterElementImpl(Identifier name) : super.con1(name) {
  }
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
  bool isInitializingFormal() => false;

  /**
   * Set the range of the default value for this parameter to the range starting at the given offset
   * with the given length.
   * @param offset the offset to the beginning of the default value range for this element
   * @param length the length of the default value range for this element, or {@code -1} if this
   * element does not have a default value
   */
  void setDefaultValueRange(int offset, int length) {
    _defaultValueRangeOffset = offset;
    _defaultValueRangeLength = length;
  }

  /**
   * Set the kind of this parameter to the given kind.
   * @param parameterKind the new kind of this parameter
   */
  void set parameterKind(ParameterKind parameterKind2) {
    this._parameterKind = parameterKind2;
  }

  /**
   * Set the parameters defined by this executable element to the given parameters.
   * @param parameters the parameters defined by this executable element
   */
  void set parameters(List<ParameterElement> parameters2) {
    for (ParameterElement parameter in parameters2) {
      ((parameter as ParameterElementImpl)).enclosingElement = this;
    }
    this._parameters = parameters2;
  }

  /**
   * Set the visible range for this element to the range starting at the given offset with the given
   * length.
   * @param offset the offset to the beginning of the visible range for this element
   * @param length the length of the visible range for this element, or {@code -1} if this element
   * does not have a visible range
   */
  void setVisibleRange(int offset, int length) {
    _visibleRangeOffset = offset;
    _visibleRangeLength = length;
  }
  void visitChildren(ElementVisitor<Object> visitor) {
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
 * Instances of the class {@code PrefixElementImpl} implement a {@code PrefixElement}.
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
   * @param name the name of this element
   */
  PrefixElementImpl(Identifier name) : super.con1(name) {
  }
  accept(ElementVisitor visitor) => visitor.visitPrefixElement(this);
  LibraryElement get enclosingElement => super.enclosingElement as LibraryElement;
  List<LibraryElement> get importedLibraries => _importedLibraries;
  ElementKind get kind => ElementKind.PREFIX;

  /**
   * Set the libraries that are imported using this prefix to the given libraries.
   * @param importedLibraries the libraries that are imported using this prefix
   */
  void set importedLibraries(List<LibraryElement> importedLibraries2) {
    for (LibraryElement library in importedLibraries2) {
      ((library as LibraryElementImpl)).enclosingElement = this;
    }
    this._importedLibraries = importedLibraries2;
  }
  void appendTo(JavaStringBuilder builder) {
    builder.append("as ");
    super.appendTo(builder);
  }
}
/**
 * Instances of the class {@code PropertyAccessorElementImpl} implement a{@code PropertyAccessorElement}.
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
   * @param name the name of this element
   */
  PropertyAccessorElementImpl.con1(Identifier name) : super.con1(name) {
    _jtd_constructor_223_impl(name);
  }
  _jtd_constructor_223_impl(Identifier name) {
  }

  /**
   * Initialize a newly created synthetic property accessor element to be associated with the given
   * variable.
   * @param variable the variable with which this access is associated
   */
  PropertyAccessorElementImpl.con2(PropertyInducingElementImpl variable2) : super.con2(variable2.name, variable2.nameOffset) {
    _jtd_constructor_224_impl(variable2);
  }
  _jtd_constructor_224_impl(PropertyInducingElementImpl variable2) {
    this._variable = variable2;
    synthetic = true;
  }
  accept(ElementVisitor visitor) => visitor.visitPropertyAccessorElement(this);
  bool operator ==(Object object) => super == object && identical(isGetter(), ((object as PropertyAccessorElement)).isGetter());
  PropertyAccessorElement get correspondingGetter {
    if (isGetter() || _variable == null) {
      return null;
    }
    return _variable.getter;
  }
  PropertyAccessorElement get correspondingSetter {
    if (isSetter() || _variable == null) {
      return null;
    }
    return _variable.setter;
  }
  ElementKind get kind {
    if (isGetter()) {
      return ElementKind.GETTER;
    }
    return ElementKind.SETTER;
  }
  String get name {
    if (isSetter()) {
      return "${super.name}=";
    }
    return super.name;
  }
  PropertyInducingElement get variable => _variable;
  bool isAbstract() => hasModifier(Modifier.ABSTRACT);
  bool isGetter() => hasModifier(Modifier.GETTER);
  bool isSetter() => hasModifier(Modifier.SETTER);
  bool isStatic() => hasModifier(Modifier.STATIC);

  /**
   * Set whether this accessor is abstract to correspond to the given value.
   * @param isAbstract {@code true} if the accessor is abstract
   */
  void set abstract(bool isAbstract) {
    setModifier(Modifier.ABSTRACT, isAbstract);
  }

  /**
   * Set whether this accessor is a getter to correspond to the given value.
   * @param isGetter {@code true} if the accessor is a getter
   */
  void set getter(bool isGetter) {
    setModifier(Modifier.GETTER, isGetter);
  }

  /**
   * Set whether this accessor is a setter to correspond to the given value.
   * @param isSetter {@code true} if the accessor is a setter
   */
  void set setter(bool isSetter) {
    setModifier(Modifier.SETTER, isSetter);
  }

  /**
   * Set whether this accessor is static to correspond to the given value.
   * @param isStatic {@code true} if the accessor is static
   */
  void set static(bool isStatic) {
    setModifier(Modifier.STATIC, isStatic);
  }

  /**
   * Set the variable associated with this accessor to the given variable.
   * @param variable the variable associated with this accessor
   */
  void set variable(PropertyInducingElement variable2) {
    this._variable = variable2;
  }
  void appendTo(JavaStringBuilder builder) {
    builder.append(isGetter() ? "get " : "set ");
    builder.append(variable.displayName);
    super.appendTo(builder);
  }
}
/**
 * Instances of the class {@code PropertyInducingElementImpl} implement a{@code PropertyInducingElement}.
 * @coverage dart.engine.element
 */
abstract class PropertyInducingElementImpl extends VariableElementImpl implements PropertyInducingElement {

  /**
   * The getter associated with this element.
   */
  PropertyAccessorElement _getter;

  /**
   * The setter associated with this element, or {@code null} if the element is effectively{@code final} and therefore does not have a setter associated with it.
   */
  PropertyAccessorElement _setter;

  /**
   * An empty array of elements.
   */
  static List<PropertyInducingElement> EMPTY_ARRAY = new List<PropertyInducingElement>(0);

  /**
   * Initialize a newly created element to have the given name.
   * @param name the name of this element
   */
  PropertyInducingElementImpl.con1(Identifier name) : super.con1(name) {
    _jtd_constructor_225_impl(name);
  }
  _jtd_constructor_225_impl(Identifier name) {
  }

  /**
   * Initialize a newly created synthetic element to have the given name.
   * @param name the name of this element
   */
  PropertyInducingElementImpl.con2(String name) : super.con2(name, -1) {
    _jtd_constructor_226_impl(name);
  }
  _jtd_constructor_226_impl(String name) {
    synthetic = true;
  }
  PropertyAccessorElement get getter => _getter;
  PropertyAccessorElement get setter => _setter;

  /**
   * Set the getter associated with this element to the given accessor.
   * @param getter the getter associated with this element
   */
  void set getter(PropertyAccessorElement getter2) {
    this._getter = getter2;
  }

  /**
   * Set the setter associated with this element to the given accessor.
   * @param setter the setter associated with this element
   */
  void set setter(PropertyAccessorElement setter2) {
    this._setter = setter2;
  }
}
/**
 * Instances of the class {@code ShowElementCombinatorImpl} implement a{@link ShowElementCombinator}.
 * @coverage dart.engine.element
 */
class ShowElementCombinatorImpl implements ShowElementCombinator {

  /**
   * The names that are to be made visible in the importing library if they are defined in the
   * imported library.
   */
  List<String> _shownNames = StringUtilities.EMPTY_ARRAY;
  List<String> get shownNames => _shownNames;

  /**
   * Set the names that are to be made visible in the importing library if they are defined in the
   * imported library to the given names.
   * @param shownNames the names that are to be made visible in the importing library
   */
  void set shownNames(List<String> shownNames2) {
    this._shownNames = shownNames2;
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
 * Instances of the class {@code TopLevelVariableElementImpl} implement a{@code TopLevelVariableElement}.
 * @coverage dart.engine.element
 */
class TopLevelVariableElementImpl extends PropertyInducingElementImpl implements TopLevelVariableElement {

  /**
   * An empty array of top-level variable elements.
   */
  static List<TopLevelVariableElement> EMPTY_ARRAY = new List<TopLevelVariableElement>(0);

  /**
   * Initialize a newly created top-level variable element to have the given name.
   * @param name the name of this element
   */
  TopLevelVariableElementImpl.con1(Identifier name) : super.con1(name) {
    _jtd_constructor_228_impl(name);
  }
  _jtd_constructor_228_impl(Identifier name) {
  }

  /**
   * Initialize a newly created synthetic top-level variable element to have the given name.
   * @param name the name of this element
   */
  TopLevelVariableElementImpl.con2(String name) : super.con2(name) {
    _jtd_constructor_229_impl(name);
  }
  _jtd_constructor_229_impl(String name) {
  }
  accept(ElementVisitor visitor) => visitor.visitTopLevelVariableElement(this);
  ElementKind get kind => ElementKind.TOP_LEVEL_VARIABLE;
  bool isStatic() => true;
}
/**
 * Instances of the class {@code TypeVariableElementImpl} implement a {@code TypeVariableElement}.
 * @coverage dart.engine.element
 */
class TypeVariableElementImpl extends ElementImpl implements TypeVariableElement {

  /**
   * The type defined by this type variable.
   */
  TypeVariableType _type;

  /**
   * The type representing the bound associated with this variable, or {@code null} if this variable
   * does not have an explicit bound.
   */
  Type2 _bound;

  /**
   * An empty array of type variable elements.
   */
  static List<TypeVariableElement> EMPTY_ARRAY = new List<TypeVariableElement>(0);

  /**
   * Initialize a newly created type variable element to have the given name.
   * @param name the name of this element
   */
  TypeVariableElementImpl(Identifier name) : super.con1(name) {
  }
  accept(ElementVisitor visitor) => visitor.visitTypeVariableElement(this);
  Type2 get bound => _bound;
  ElementKind get kind => ElementKind.TYPE_VARIABLE;
  TypeVariableType get type => _type;

  /**
   * Set the type representing the bound associated with this variable to the given type.
   * @param bound the type representing the bound associated with this variable
   */
  void set bound(Type2 bound2) {
    this._bound = bound2;
  }

  /**
   * Set the type defined by this type variable to the given type
   * @param type the type defined by this type variable
   */
  void set type(TypeVariableType type2) {
    this._type = type2;
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
 * Instances of the class {@code VariableElementImpl} implement a {@code VariableElement}.
 * @coverage dart.engine.element
 */
abstract class VariableElementImpl extends ElementImpl implements VariableElement {

  /**
   * The declared type of this variable.
   */
  Type2 _type;

  /**
   * A synthetic function representing this variable's initializer, or {@code null} if this variable
   * does not have an initializer.
   */
  FunctionElement _initializer;

  /**
   * An empty array of variable elements.
   */
  static List<VariableElement> EMPTY_ARRAY = new List<VariableElement>(0);

  /**
   * Initialize a newly created variable element to have the given name.
   * @param name the name of this element
   */
  VariableElementImpl.con1(Identifier name) : super.con1(name) {
    _jtd_constructor_231_impl(name);
  }
  _jtd_constructor_231_impl(Identifier name) {
  }

  /**
   * Initialize a newly created variable element to have the given name.
   * @param name the name of this element
   * @param nameOffset the offset of the name of this element in the file that contains the
   * declaration of this element
   */
  VariableElementImpl.con2(String name, int nameOffset) : super.con2(name, nameOffset) {
    _jtd_constructor_232_impl(name, nameOffset);
  }
  _jtd_constructor_232_impl(String name, int nameOffset) {
  }

  /**
   * Return the result of evaluating this variable's initializer as a compile-time constant
   * expression, or {@code null} if this variable is not a 'const' variable or does not have an
   * initializer.
   * @return the result of evaluating this variable's initializer
   */
  EvaluationResultImpl get evaluationResult => null;
  FunctionElement get initializer => _initializer;
  Type2 get type => _type;
  bool isConst() => hasModifier(Modifier.CONST);
  bool isFinal() => hasModifier(Modifier.FINAL);

  /**
   * Set whether this variable is const to correspond to the given value.
   * @param isConst {@code true} if the variable is const
   */
  void set const3(bool isConst) {
    setModifier(Modifier.CONST, isConst);
  }

  /**
   * Set the result of evaluating this variable's initializer as a compile-time constant expression
   * to the given result.
   * @param result the result of evaluating this variable's initializer
   */
  void set evaluationResult(EvaluationResultImpl result) {
    throw new IllegalStateException("Invalid attempt to set a compile-time constant result");
  }

  /**
   * Set whether this variable is final to correspond to the given value.
   * @param isFinal {@code true} if the variable is final
   */
  void set final2(bool isFinal) {
    setModifier(Modifier.FINAL, isFinal);
  }

  /**
   * Set the function representing this variable's initializer to the given function.
   * @param initializer the function representing this variable's initializer
   */
  void set initializer(FunctionElement initializer2) {
    if (initializer2 != null) {
      ((initializer2 as FunctionElementImpl)).enclosingElement = this;
    }
    this._initializer = initializer2;
  }

  /**
   * Set the declared type of this variable to the given type.
   * @param type the declared type of this variable
   */
  void set type(Type2 type2) {
    this._type = type2;
  }
  void visitChildren(ElementVisitor<Object> visitor) {
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
 * Instances of the class {@code ConstructorMember} represent a constructor element defined in a
 * parameterized type where the values of the type parameters are known.
 */
class ConstructorMember extends ExecutableMember implements ConstructorElement {

  /**
   * If the given constructor's type is different when any type parameters from the defining type's
   * declaration are replaced with the actual type arguments from the defining type, create a
   * constructor member representing the given constructor. Return the member that was created, or
   * the base constructor if no member was created.
   * @param baseConstructor the base constructor for which a member might be created
   * @param definingType the type defining the parameters and arguments to be used in the
   * substitution
   * @return the constructor element that will return the correctly substituted types
   */
  static ConstructorElement from(ConstructorElement baseConstructor, InterfaceType definingType) {
    if (baseConstructor == null || definingType.typeArguments.length == 0) {
      return baseConstructor;
    }
    FunctionType baseType = baseConstructor.type;
    List<Type2> argumentTypes = definingType.typeArguments;
    List<Type2> parameterTypes = TypeVariableTypeImpl.getTypes(definingType.element.typeVariables);
    FunctionType substitutedType = baseType.substitute2(argumentTypes, parameterTypes);
    if (baseType == substitutedType) {
      return baseConstructor;
    }
    return new ConstructorMember(baseConstructor, definingType);
  }

  /**
   * Initialize a newly created element to represent a constructor of the given parameterized type.
   * @param baseElement the element on which the parameterized element was created
   * @param definingType the type in which the element is defined
   */
  ConstructorMember(ConstructorElement baseElement, InterfaceType definingType) : super(baseElement, definingType) {
  }
  accept(ElementVisitor visitor) => visitor.visitConstructorElement(this);
  ConstructorElement get baseElement => super.baseElement as ConstructorElement;
  ClassElement get enclosingElement => baseElement.enclosingElement;
  ConstructorElement get redirectedConstructor => from(baseElement.redirectedConstructor, definingType);
  bool isConst() => baseElement.isConst();
  bool isFactory() => baseElement.isFactory();
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
      builder.append(" -> ");
      builder.append(type.returnType);
    }
    return builder.toString();
  }
  InterfaceType get definingType => super.definingType as InterfaceType;
}
/**
 * The abstract class {@code ExecutableMember} defines the behavior common to members that represent
 * an executable element defined in a parameterized type where the values of the type parameters are
 * known.
 */
abstract class ExecutableMember extends Member implements ExecutableElement {

  /**
   * Initialize a newly created element to represent an executable element of the given
   * parameterized type.
   * @param baseElement the element on which the parameterized element was created
   * @param definingType the type in which the element is defined
   */
  ExecutableMember(ExecutableElement baseElement, InterfaceType definingType) : super(baseElement, definingType) {
  }
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
  FunctionType get type => substituteFor(baseElement.type);
  bool isOperator() => baseElement.isOperator();
  bool isStatic() => baseElement.isStatic();
  void visitChildren(ElementVisitor<Object> visitor) {
    super.visitChildren(visitor);
    safelyVisitChildren(baseElement.functions, visitor);
    safelyVisitChildren(labels, visitor);
    safelyVisitChildren(baseElement.localVariables, visitor);
    safelyVisitChildren(parameters, visitor);
  }
}
/**
 * Instances of the class {@code FieldMember} represent a field element defined in a parameterized
 * type where the values of the type parameters are known.
 */
class FieldMember extends VariableMember implements FieldElement {

  /**
   * If the given field's type is different when any type parameters from the defining type's
   * declaration are replaced with the actual type arguments from the defining type, create a field
   * member representing the given field. Return the member that was created, or the base field if
   * no member was created.
   * @param baseField the base field for which a member might be created
   * @param definingType the type defining the parameters and arguments to be used in the
   * substitution
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
    List<Type2> parameterTypes = TypeVariableTypeImpl.getTypes(definingType.element.typeVariables);
    Type2 substitutedType = baseType.substitute2(argumentTypes, parameterTypes);
    if (baseType == substitutedType) {
      return baseField;
    }
    return new FieldMember(baseField, definingType);
  }

  /**
   * Initialize a newly created element to represent a field of the given parameterized type.
   * @param baseElement the element on which the parameterized element was created
   * @param definingType the type in which the element is defined
   */
  FieldMember(FieldElement baseElement, InterfaceType definingType) : super(baseElement, definingType) {
  }
  accept(ElementVisitor visitor) => visitor.visitFieldElement(this);
  FieldElement get baseElement => super.baseElement as FieldElement;
  ClassElement get enclosingElement => baseElement.enclosingElement;
  PropertyAccessorElement get getter => PropertyAccessorMember.from(baseElement.getter, definingType);
  PropertyAccessorElement get setter => PropertyAccessorMember.from(baseElement.setter, definingType);
  bool isStatic() => baseElement.isStatic();
  InterfaceType get definingType => super.definingType as InterfaceType;
}
/**
 * The abstract class {@code Member} defines the behavior common to elements that represent members
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
  bool isSynthetic() => _baseElement.isSynthetic();
  void visitChildren(ElementVisitor<Object> visitor) {
  }

  /**
   * Return the type in which the element is defined.
   * @return the type in which the element is defined
   */
  ParameterizedType get definingType => _definingType;

  /**
   * If the given child is not {@code null}, use the given visitor to visit it.
   * @param child the child to be visited
   * @param visitor the visitor to be used to visit the child
   */
  void safelyVisitChild(Element child, ElementVisitor<Object> visitor) {
    if (child != null) {
      child.accept(visitor);
    }
  }

  /**
   * Use the given visitor to visit all of the children in the given array.
   * @param children the children to be visited
   * @param visitor the visitor being used to visit the children
   */
  void safelyVisitChildren(List<Element> children, ElementVisitor<Object> visitor) {
    if (children != null) {
      for (Element child in children) {
        child.accept(visitor);
      }
    }
  }

  /**
   * Return the type that results from replacing the type parameters in the given type with the type
   * arguments.
   * @param type the type to be transformed
   * @return the result of transforming the type
   */
  Type2 substituteFor(Type2 type) {
    List<Type2> argumentTypes = _definingType.typeArguments;
    List<Type2> parameterTypes = TypeVariableTypeImpl.getTypes(_definingType.typeVariables);
    return type.substitute2(argumentTypes, parameterTypes) as Type2;
  }

  /**
   * Return the array of types that results from replacing the type parameters in the given types
   * with the type arguments.
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
 * Instances of the class {@code MethodMember} represent a method element defined in a parameterized
 * type where the values of the type parameters are known.
 */
class MethodMember extends ExecutableMember implements MethodElement {

  /**
   * If the given method's type is different when any type parameters from the defining type's
   * declaration are replaced with the actual type arguments from the defining type, create a method
   * member representing the given method. Return the member that was created, or the base method if
   * no member was created.
   * @param baseMethod the base method for which a member might be created
   * @param definingType the type defining the parameters and arguments to be used in the
   * substitution
   * @return the method element that will return the correctly substituted types
   */
  static MethodElement from(MethodElement baseMethod, InterfaceType definingType) {
    if (baseMethod == null || definingType.typeArguments.length == 0) {
      return baseMethod;
    }
    FunctionType baseType = baseMethod.type;
    List<Type2> argumentTypes = definingType.typeArguments;
    List<Type2> parameterTypes = TypeVariableTypeImpl.getTypes(definingType.element.typeVariables);
    FunctionType substitutedType = baseType.substitute2(argumentTypes, parameterTypes);
    if (baseType == substitutedType) {
      return baseMethod;
    }
    return new MethodMember(baseMethod, definingType);
  }

  /**
   * Initialize a newly created element to represent a method of the given parameterized type.
   * @param baseElement the element on which the parameterized element was created
   * @param definingType the type in which the element is defined
   */
  MethodMember(MethodElement baseElement, InterfaceType definingType) : super(baseElement, definingType) {
  }
  accept(ElementVisitor visitor) => visitor.visitMethodElement(this);
  MethodElement get baseElement => super.baseElement as MethodElement;
  ClassElement get enclosingElement => baseElement.enclosingElement;
  bool isAbstract() => baseElement.isAbstract();
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
      builder.append(" -> ");
      builder.append(type.returnType);
    }
    return builder.toString();
  }
}
/**
 * Instances of the class {@code ParameterMember} represent a parameter element defined in a
 * parameterized type where the values of the type parameters are known.
 */
class ParameterMember extends VariableMember implements ParameterElement {

  /**
   * If the given parameter's type is different when any type parameters from the defining type's
   * declaration are replaced with the actual type arguments from the defining type, create a
   * parameter member representing the given parameter. Return the member that was created, or the
   * base parameter if no member was created.
   * @param baseParameter the base parameter for which a member might be created
   * @param definingType the type defining the parameters and arguments to be used in the
   * substitution
   * @return the parameter element that will return the correctly substituted types
   */
  static ParameterElement from(ParameterElement baseParameter, ParameterizedType definingType) {
    if (baseParameter == null || definingType.typeArguments.length == 0) {
      return baseParameter;
    }
    Type2 baseType = baseParameter.type;
    List<Type2> argumentTypes = definingType.typeArguments;
    List<Type2> parameterTypes = TypeVariableTypeImpl.getTypes(definingType.typeVariables);
    Type2 substitutedType = baseType.substitute2(argumentTypes, parameterTypes);
    if (baseType == substitutedType) {
      return baseParameter;
    }
    return new ParameterMember(baseParameter, definingType);
  }

  /**
   * Initialize a newly created element to represent a parameter of the given parameterized type.
   * @param baseElement the element on which the parameterized element was created
   * @param definingType the type in which the element is defined
   */
  ParameterMember(ParameterElement baseElement, ParameterizedType definingType) : super(baseElement, definingType) {
  }
  accept(ElementVisitor visitor) => visitor.visitParameterElement(this);
  Element getAncestor(Type elementClass) {
    Element element = baseElement.getAncestor(elementClass);
    ParameterizedType definingType = this.definingType;
    if (definingType is InterfaceType) {
      InterfaceType definingInterfaceType = definingType as InterfaceType;
      if (element is ConstructorElement) {
        return ConstructorMember.from((element as ConstructorElement), definingInterfaceType) as Element;
      } else if (element is MethodElement) {
        return MethodMember.from((element as MethodElement), definingInterfaceType) as Element;
      } else if (element is PropertyAccessorElement) {
        return PropertyAccessorMember.from((element as PropertyAccessorElement), definingInterfaceType) as Element;
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
  bool isInitializingFormal() => baseElement.isInitializingFormal();
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
  void visitChildren(ElementVisitor<Object> visitor) {
    super.visitChildren(visitor);
    safelyVisitChildren(parameters, visitor);
  }
}
/**
 * Instances of the class {@code PropertyAccessorMember} represent a property accessor element
 * defined in a parameterized type where the values of the type parameters are known.
 */
class PropertyAccessorMember extends ExecutableMember implements PropertyAccessorElement {

  /**
   * If the given property accessor's type is different when any type parameters from the defining
   * type's declaration are replaced with the actual type arguments from the defining type, create a
   * property accessor member representing the given property accessor. Return the member that was
   * created, or the base accessor if no member was created.
   * @param baseAccessor the base property accessor for which a member might be created
   * @param definingType the type defining the parameters and arguments to be used in the
   * substitution
   * @return the property accessor element that will return the correctly substituted types
   */
  static PropertyAccessorElement from(PropertyAccessorElement baseAccessor, InterfaceType definingType) {
    if (baseAccessor == null || definingType.typeArguments.length == 0) {
      return baseAccessor;
    }
    FunctionType baseType = baseAccessor.type;
    List<Type2> argumentTypes = definingType.typeArguments;
    List<Type2> parameterTypes = TypeVariableTypeImpl.getTypes(definingType.element.typeVariables);
    FunctionType substitutedType = baseType.substitute2(argumentTypes, parameterTypes);
    if (baseType == substitutedType) {
      return baseAccessor;
    }
    return new PropertyAccessorMember(baseAccessor, definingType);
  }

  /**
   * Initialize a newly created element to represent a property accessor of the given parameterized
   * type.
   * @param baseElement the element on which the parameterized element was created
   * @param definingType the type in which the element is defined
   */
  PropertyAccessorMember(PropertyAccessorElement baseElement, InterfaceType definingType) : super(baseElement, definingType) {
  }
  accept(ElementVisitor visitor) => visitor.visitPropertyAccessorElement(this);
  PropertyAccessorElement get baseElement => super.baseElement as PropertyAccessorElement;
  PropertyAccessorElement get correspondingGetter => from(baseElement.correspondingGetter, definingType);
  PropertyAccessorElement get correspondingSetter => from(baseElement.correspondingSetter, definingType);
  Element get enclosingElement => baseElement.enclosingElement;
  PropertyInducingElement get variable {
    PropertyInducingElement variable = baseElement.variable;
    if (variable is FieldElement) {
      return FieldMember.from(((variable as FieldElement)), definingType);
    }
    return variable;
  }
  bool isAbstract() => baseElement.isAbstract();
  bool isGetter() => baseElement.isGetter();
  bool isSetter() => baseElement.isSetter();
  InterfaceType get definingType => super.definingType as InterfaceType;
}
/**
 * The abstract class {@code VariableMember} defines the behavior common to members that represent a
 * variable element defined in a parameterized type where the values of the type parameters are
 * known.
 */
abstract class VariableMember extends Member implements VariableElement {

  /**
   * Initialize a newly created element to represent an executable element of the given
   * parameterized type.
   * @param baseElement the element on which the parameterized element was created
   * @param definingType the type in which the element is defined
   */
  VariableMember(VariableElement baseElement, ParameterizedType definingType) : super(baseElement, definingType) {
  }
  VariableElement get baseElement => super.baseElement as VariableElement;
  FunctionElement get initializer {
    throw new UnsupportedOperationException();
  }
  Type2 get type => substituteFor(baseElement.type);
  bool isConst() => baseElement.isConst();
  bool isFinal() => baseElement.isFinal();
  void visitChildren(ElementVisitor<Object> visitor) {
    super.visitChildren(visitor);
    safelyVisitChild(baseElement.initializer, visitor);
  }
}
/**
 * Instances of the class {@code AnonymousFunctionTypeImpl} extend the behavior of{@link FunctionTypeImpl} to support anonymous function types created for function typed
 * parameters.
 * @coverage dart.engine.type
 */
class AnonymousFunctionTypeImpl extends FunctionTypeImpl {

  /**
   * An array of parameters elements of this type of function.
   */
  List<ParameterElement> _baseParameters = ParameterElementImpl.EMPTY_ARRAY;
  AnonymousFunctionTypeImpl() : super.con2((null as FunctionTypeAliasElement)) {
  }

  /**
   * Sets the parameters elements of this type of function.
   * @param parameters the parameters elements of this type of function
   */
  void set baseParameters(List<ParameterElement> parameters) {
    this._baseParameters = parameters;
  }
  List<ParameterElement> get baseParameters => _baseParameters;
}
/**
 * The unique instance of the class {@code BottomTypeImpl} implements the type {@code bottom}.
 * @coverage dart.engine.type
 */
class BottomTypeImpl extends TypeImpl {

  /**
   * The unique instance of this class.
   */
  static BottomTypeImpl _INSTANCE = new BottomTypeImpl();

  /**
   * Return the unique instance of this class.
   * @return the unique instance of this class
   */
  static BottomTypeImpl get instance => _INSTANCE;

  /**
   * Prevent the creation of instances of this class.
   */
  BottomTypeImpl() : super(null, "<bottom>") {
  }
  bool operator ==(Object object) => identical(object, this);
  bool isMoreSpecificThan(Type2 type) => true;
  bool isSubtypeOf(Type2 type) => true;
  bool isSupertypeOf(Type2 type) => false;
  BottomTypeImpl substitute2(List<Type2> argumentTypes, List<Type2> parameterTypes) => this;
}
/**
 * The unique instance of the class {@code DynamicTypeImpl} implements the type {@code dynamic}.
 * @coverage dart.engine.type
 */
class DynamicTypeImpl extends TypeImpl {

  /**
   * The unique instance of this class.
   */
  static DynamicTypeImpl _INSTANCE = new DynamicTypeImpl();

  /**
   * Return the unique instance of this class.
   * @return the unique instance of this class
   */
  static DynamicTypeImpl get instance => _INSTANCE;

  /**
   * Prevent the creation of instances of this class.
   */
  DynamicTypeImpl() : super(new DynamicElementImpl(), Keyword.DYNAMIC.syntax) {
    ((element as DynamicElementImpl)).type = this;
  }
  bool operator ==(Object object) => object is DynamicTypeImpl;
  bool isDynamic() => true;
  bool isMoreSpecificThan(Type2 type) => false;
  bool isSubtypeOf(Type2 type) => identical(this, type);
  bool isSupertypeOf(Type2 type) => true;
  DynamicTypeImpl substitute2(List<Type2> argumentTypes, List<Type2> parameterTypes) => this;
}
/**
 * Instances of the class {@code FunctionTypeImpl} defines the behavior common to objects
 * representing the type of a function, method, constructor, getter, or setter.
 * @coverage dart.engine.type
 */
class FunctionTypeImpl extends TypeImpl implements FunctionType {

  /**
   * Return {@code true} if all of the name/type pairs in the first map are equal to the
   * corresponding name/type pairs in the second map. The maps are expected to iterate over their
   * entries in the same order in which those entries were added to the map.
   * @param firstTypes the first map of name/type pairs being compared
   * @param secondTypes the second map of name/type pairs being compared
   * @return {@code true} if all of the name/type pairs in the first map are equal to the
   * corresponding name/type pairs in the second map
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
   * Return a map containing the results of using the given argument types and parameter types to
   * perform a substitution on all of the values in the given map. The order of the entries will be
   * preserved.
   * @param types the types on which a substitution is to be performed
   * @param argumentTypes the argument types for the substitution
   * @param parameterTypes the parameter types for the substitution
   * @return the result of performing the substitution on each of the types
   */
  static Map<String, Type2> substitute3(Map<String, Type2> types, List<Type2> argumentTypes, List<Type2> parameterTypes) {
    if (types.isEmpty) {
      return types;
    }
    LinkedHashMap<String, Type2> newTypes = new LinkedHashMap<String, Type2>();
    for (MapEntry<String, Type2> entry in getMapEntrySet(types)) {
      newTypes[entry.getKey()] = entry.getValue().substitute2(argumentTypes, parameterTypes);
    }
    return newTypes;
  }

  /**
   * An array containing the actual types of the type arguments.
   */
  List<Type2> _typeArguments = TypeImpl.EMPTY_ARRAY;

  /**
   * An array containing the types of the normal parameters of this type of function. The parameter
   * types are in the same order as they appear in the declaration of the function.
   * @return the types of the normal parameters of this type of function
   */
  List<Type2> _normalParameterTypes = TypeImpl.EMPTY_ARRAY;

  /**
   * A table mapping the names of optional (positional) parameters to the types of the optional
   * parameters of this type of function.
   */
  List<Type2> _optionalParameterTypes = TypeImpl.EMPTY_ARRAY;

  /**
   * A table mapping the names of named parameters to the types of the named parameters of this type
   * of function.
   */
  Map<String, Type2> _namedParameterTypes = new Map();

  /**
   * The type of object returned by this type of function.
   */
  Type2 _returnType = VoidTypeImpl.instance;

  /**
   * Initialize a newly created function type to be declared by the given element and to have the
   * given name.
   * @param element the element representing the declaration of the function type
   */
  FunctionTypeImpl.con1(ExecutableElement element) : super(element, element == null ? null : element.name) {
    _jtd_constructor_299_impl(element);
  }
  _jtd_constructor_299_impl(ExecutableElement element) {
  }

  /**
   * Initialize a newly created function type to be declared by the given element and to have the
   * given name.
   * @param element the element representing the declaration of the function type
   */
  FunctionTypeImpl.con2(FunctionTypeAliasElement element) : super(element, element == null ? null : element.name) {
    _jtd_constructor_300_impl(element);
  }
  _jtd_constructor_300_impl(FunctionTypeAliasElement element) {
  }
  bool operator ==(Object object) {
    if (object is! FunctionTypeImpl) {
      return false;
    }
    FunctionTypeImpl otherType = object as FunctionTypeImpl;
    return element == otherType.element && JavaArrays.equals(_normalParameterTypes, otherType._normalParameterTypes) && JavaArrays.equals(_optionalParameterTypes, otherType._optionalParameterTypes) && equals2(_namedParameterTypes, otherType._namedParameterTypes) && _returnType == otherType._returnType;
  }
  String get displayName {
    String name = this.name;
    if (name == null) {
      JavaStringBuilder builder = new JavaStringBuilder();
      builder.append("(");
      bool needsComma = false;
      if (_normalParameterTypes.length > 0) {
        for (Type2 type in _normalParameterTypes) {
          if (needsComma) {
            builder.append(", ");
          } else {
            needsComma = true;
          }
          builder.append(type.displayName);
        }
      }
      if (_optionalParameterTypes.length > 0) {
        if (needsComma) {
          builder.append(", ");
          needsComma = false;
        }
        builder.append("[");
        for (Type2 type in _optionalParameterTypes) {
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
      if (_namedParameterTypes.length > 0) {
        if (needsComma) {
          builder.append(", ");
          needsComma = false;
        }
        builder.append("{");
        for (MapEntry<String, Type2> entry in getMapEntrySet(_namedParameterTypes)) {
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
      builder.append(") -> ");
      if (_returnType == null) {
        builder.append("null");
      } else {
        builder.append(_returnType.displayName);
      }
      name = builder.toString();
    }
    return name;
  }
  Map<String, Type2> get namedParameterTypes => _namedParameterTypes;
  List<Type2> get normalParameterTypes => _normalParameterTypes;
  List<Type2> get optionalParameterTypes => _optionalParameterTypes;
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
  Type2 get returnType => _returnType;
  List<Type2> get typeArguments => _typeArguments;
  List<TypeVariableElement> get typeVariables {
    Element element = this.element;
    if (element is FunctionTypeAliasElement) {
      return ((element as FunctionTypeAliasElement)).typeVariables;
    }
    return TypeVariableElementImpl.EMPTY_ARRAY;
  }
  int get hashCode {
    Element element = this.element;
    if (element == null) {
      return 0;
    }
    return element.hashCode;
  }
  bool isSubtypeOf(Type2 type) {
    if (type == null) {
      return false;
    } else if (identical(this, type) || type.isDynamic() || type.isDartCoreFunction() || type.isObject()) {
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
          if (!tTypes[i].isAssignableTo(sTypes[i])) {
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
        if (!entryS.getValue().isAssignableTo(typeT)) {
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
        if (!sAllTypes[i].isAssignableTo(tAllTypes[i])) {
          return false;
        }
      }
    }
    return s.returnType == VoidTypeImpl.instance || t.returnType.isAssignableTo(s.returnType);
  }

  /**
   * Set the mapping of the names of named parameters to the types of the named parameters of this
   * type of function to the given mapping.
   * @param namedParameterTypes the mapping of the names of named parameters to the types of the
   * named parameters of this type of function
   */
  void set namedParameterTypes(LinkedHashMap<String, Type2> namedParameterTypes2) {
    this._namedParameterTypes = namedParameterTypes2;
  }

  /**
   * Set the types of the normal parameters of this type of function to the types in the given
   * array.
   * @param normalParameterTypes the types of the normal parameters of this type of function
   */
  void set normalParameterTypes(List<Type2> normalParameterTypes2) {
    this._normalParameterTypes = normalParameterTypes2;
  }

  /**
   * Set the types of the optional parameters of this type of function to the types in the given
   * array.
   * @param optionalParameterTypes the types of the optional parameters of this type of function
   */
  void set optionalParameterTypes(List<Type2> optionalParameterTypes2) {
    this._optionalParameterTypes = optionalParameterTypes2;
  }

  /**
   * Set the type of object returned by this type of function to the given type.
   * @param returnType the type of object returned by this type of function
   */
  void set returnType(Type2 returnType2) {
    this._returnType = returnType2;
  }

  /**
   * Set the actual types of the type arguments to the given types.
   * @param typeArguments the actual types of the type arguments
   */
  void set typeArguments(List<Type2> typeArguments2) {
    this._typeArguments = typeArguments2;
  }
  FunctionTypeImpl substitute4(List<Type2> argumentTypes) => substitute2(argumentTypes, typeArguments);
  FunctionTypeImpl substitute2(List<Type2> argumentTypes, List<Type2> parameterTypes) {
    if (argumentTypes.length != parameterTypes.length) {
      throw new IllegalArgumentException("argumentTypes.length (${argumentTypes.length}) != parameterTypes.length (${parameterTypes.length})");
    }
    if (argumentTypes.length == 0) {
      return this;
    }
    Element element = this.element;
    FunctionTypeImpl newType = (element is ExecutableElement) ? new FunctionTypeImpl.con1((element as ExecutableElement)) : new FunctionTypeImpl.con2((element as FunctionTypeAliasElement));
    newType.returnType = _returnType.substitute2(argumentTypes, parameterTypes);
    newType.normalParameterTypes = TypeImpl.substitute(_normalParameterTypes, argumentTypes, parameterTypes);
    newType.optionalParameterTypes = TypeImpl.substitute(_optionalParameterTypes, argumentTypes, parameterTypes);
    newType._namedParameterTypes = substitute3(_namedParameterTypes, argumentTypes, parameterTypes);
    newType.typeArguments = argumentTypes;
    return newType;
  }
  void appendTo(JavaStringBuilder builder) {
    builder.append("(");
    bool needsComma = false;
    if (_normalParameterTypes.length > 0) {
      for (Type2 type in _normalParameterTypes) {
        if (needsComma) {
          builder.append(", ");
        } else {
          needsComma = true;
        }
        ((type as TypeImpl)).appendTo(builder);
      }
    }
    if (_optionalParameterTypes.length > 0) {
      if (needsComma) {
        builder.append(", ");
        needsComma = false;
      }
      builder.append("[");
      for (Type2 type in _optionalParameterTypes) {
        if (needsComma) {
          builder.append(", ");
        } else {
          needsComma = true;
        }
        ((type as TypeImpl)).appendTo(builder);
      }
      builder.append("]");
      needsComma = true;
    }
    if (_namedParameterTypes.length > 0) {
      if (needsComma) {
        builder.append(", ");
        needsComma = false;
      }
      builder.append("{");
      for (MapEntry<String, Type2> entry in getMapEntrySet(_namedParameterTypes)) {
        if (needsComma) {
          builder.append(", ");
        } else {
          needsComma = true;
        }
        builder.append(entry.getKey());
        builder.append(": ");
        ((entry.getValue() as TypeImpl)).appendTo(builder);
      }
      builder.append("}");
      needsComma = true;
    }
    builder.append(") -> ");
    if (_returnType == null) {
      builder.append("null");
    } else {
      ((_returnType as TypeImpl)).appendTo(builder);
    }
  }

  /**
   * @return the base parameter elements of this function element, not {@code null}.
   */
  List<ParameterElement> get baseParameters {
    Element element = this.element;
    if (element is ExecutableElement) {
      return ((element as ExecutableElement)).parameters;
    } else {
      return ((element as FunctionTypeAliasElement)).parameters;
    }
  }
}
/**
 * Instances of the class {@code InterfaceTypeImpl} defines the behavior common to objects
 * representing the type introduced by either a class or an interface, or a reference to such a
 * type.
 * @coverage dart.engine.type
 */
class InterfaceTypeImpl extends TypeImpl implements InterfaceType {

  /**
   * An empty array of types.
   */
  static List<InterfaceType> EMPTY_ARRAY = new List<InterfaceType>(0);

  /**
   * This method computes the longest inheritance path from some passed {@link Type} to Object.
   * @param type the {@link Type} to compute the longest inheritance path of from the passed{@link Type} to Object
   * @return the computed longest inheritance path to Object
   * @see InterfaceType#getLeastUpperBound(Type)
   */
  static int computeLongestInheritancePathToObject(InterfaceType type) => computeLongestInheritancePathToObject2(type, 0, new Set<ClassElement>());

  /**
   * Returns the set of all superinterfaces of the passed {@link Type}.
   * @param type the {@link Type} to compute the set of superinterfaces of
   * @return the {@link Set} of superinterfaces of the passed {@link Type}
   * @see #getLeastUpperBound(Type)
   */
  static Set<InterfaceType> computeSuperinterfaceSet(InterfaceType type) => computeSuperinterfaceSet2(type, new Set<InterfaceType>());

  /**
   * This method computes the longest inheritance path from some passed {@link Type} to Object. This
   * method calls itself recursively, callers should use the public method{@link #computeLongestInheritancePathToObject(Type)}.
   * @param type the {@link Type} to compute the longest inheritance path of from the passed{@link Type} to Object
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
      javaSetAdd(visitedClasses, classElement);
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
   * Returns the set of all superinterfaces of the passed {@link Type}. This is a recursive method,
   * callers should call the public {@link #computeSuperinterfaceSet(Type)}.
   * @param type the {@link Type} to compute the set of superinterfaces of
   * @param set a {@link HashSet} used recursively by this method
   * @return the {@link Set} of superinterfaces of the passed {@link Type}
   * @see #computeSuperinterfaceSet(Type)
   * @see #getLeastUpperBound(Type)
   */
  static Set<InterfaceType> computeSuperinterfaceSet2(InterfaceType type, Set<InterfaceType> set) {
    Element element = type.element;
    if (element != null && element is ClassElement) {
      ClassElement classElement = element as ClassElement;
      List<InterfaceType> superinterfaces = classElement.interfaces;
      for (InterfaceType superinterface in superinterfaces) {
        if (javaSetAdd(set, superinterface)) {
          computeSuperinterfaceSet2(superinterface, set);
        }
      }
      InterfaceType supertype = classElement.supertype;
      if (supertype != null) {
        if (javaSetAdd(set, supertype)) {
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
        javaSetAdd(result, leastUpperBound(firstType, secondType));
      }
    }
    return new List.from(result);
  }

  /**
   * Return the "least upper bound" of the given types under the assumption that the types have the
   * same element and differ only in terms of the type arguments. The resulting type is composed by
   * comparing the corresponding type arguments, keeping those that are the same, and using
   * 'dynamic' for those that are different.
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
   * @param element the element representing the declaration of the type
   */
  InterfaceTypeImpl.con1(ClassElement element) : super(element, element.displayName) {
    _jtd_constructor_301_impl(element);
  }
  _jtd_constructor_301_impl(ClassElement element) {
  }

  /**
   * Initialize a newly created type to have the given name. This constructor should only be used in
   * cases where there is no declaration of the type.
   * @param name the name of the type
   */
  InterfaceTypeImpl.con2(String name) : super(null, name) {
    _jtd_constructor_302_impl(name);
  }
  _jtd_constructor_302_impl(String name) {
  }
  bool operator ==(Object object) {
    if (object is! InterfaceTypeImpl) {
      return false;
    }
    InterfaceTypeImpl otherType = object as InterfaceTypeImpl;
    return element == otherType.element && JavaArrays.equals(_typeArguments, otherType._typeArguments);
  }
  ClassElement get element => super.element as ClassElement;
  PropertyAccessorElement getGetter(String getterName) => PropertyAccessorMember.from(((element as ClassElementImpl)).getGetter(getterName), this);
  List<InterfaceType> get interfaces {
    ClassElement classElement = element;
    List<InterfaceType> interfaces = classElement.interfaces;
    List<TypeVariableElement> typeVariables = classElement.typeVariables;
    if (typeVariables.length == 0) {
      return interfaces;
    }
    int count = interfaces.length;
    List<InterfaceType> typedInterfaces = new List<InterfaceType>(count);
    for (int i = 0; i < count; i++) {
      typedInterfaces[i] = interfaces[i].substitute2(_typeArguments, TypeVariableTypeImpl.getTypes(typeVariables));
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
    javaSetAdd(si, i);
    javaSetAdd(sj, j);
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
  MethodElement getMethod(String methodName) => MethodMember.from(((element as ClassElementImpl)).getMethod(methodName), this);
  List<InterfaceType> get mixins {
    ClassElement classElement = element;
    List<InterfaceType> mixins = classElement.mixins;
    List<TypeVariableElement> typeVariables = classElement.typeVariables;
    if (typeVariables.length == 0) {
      return mixins;
    }
    int count = mixins.length;
    List<InterfaceType> typedMixins = new List<InterfaceType>(count);
    for (int i = 0; i < count; i++) {
      typedMixins[i] = mixins[i].substitute2(_typeArguments, TypeVariableTypeImpl.getTypes(typeVariables));
    }
    return typedMixins;
  }
  PropertyAccessorElement getSetter(String setterName) => PropertyAccessorMember.from(((element as ClassElementImpl)).getSetter(setterName), this);
  InterfaceType get superclass {
    ClassElement classElement = element;
    InterfaceType supertype = classElement.supertype;
    if (supertype == null) {
      return null;
    }
    return supertype.substitute2(_typeArguments, TypeVariableTypeImpl.getTypes(classElement.typeVariables));
  }
  List<Type2> get typeArguments => _typeArguments;
  List<TypeVariableElement> get typeVariables => element.typeVariables;
  int get hashCode {
    ClassElement element = this.element;
    if (element == null) {
      return 0;
    }
    return element.hashCode;
  }
  bool isDartCoreFunction() {
    ClassElement element = this.element;
    if (element == null) {
      return false;
    }
    return element.name == "Function" && element.library.isDartCore();
  }
  bool isDirectSupertypeOf(InterfaceType type) {
    ClassElement i = element;
    ClassElement j = type.element;
    InterfaceType supertype = j.supertype;
    if (supertype == null) {
      return false;
    }
    ClassElement supertypeElement = supertype.element;
    if (supertypeElement == i) {
      return true;
    }
    for (InterfaceType interfaceType in j.interfaces) {
      if (interfaceType.element == i) {
        return true;
      }
    }
    for (InterfaceType mixinType in j.mixins) {
      if (mixinType.element == i) {
        return true;
      }
    }
    return false;
  }
  bool isMoreSpecificThan(Type2 type) {
    if (identical(type, DynamicTypeImpl.instance)) {
      return true;
    } else if (type is! InterfaceType) {
      return false;
    }
    return isMoreSpecificThan2((type as InterfaceType), new Set<ClassElement>());
  }
  bool isObject() => element.supertype == null;
  bool isSubtypeOf(Type2 type2) {
    if (identical(type2, DynamicTypeImpl.instance)) {
      return true;
    } else if (type2 is TypeVariableType) {
      return true;
    } else if (type2 is FunctionType) {
      ClassElement element = this.element;
      MethodElement callMethod = element.lookUpMethod("call", element.library);
      if (callMethod != null) {
        return callMethod.type.isSubtypeOf(type2);
      }
      return false;
    } else if (type2 is! InterfaceType) {
      return false;
    } else if (this == type2) {
      return true;
    }
    return isSubtypeOf2((type2 as InterfaceType), new Set<ClassElement>());
  }
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
      javaSetAdd(visitedClasses, supertypeElement);
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
      javaSetAdd(visitedClasses, supertypeElement);
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
      javaSetAdd(visitedClasses, supertypeElement);
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
   * @param typeArguments the actual types of the type arguments
   */
  void set typeArguments(List<Type2> typeArguments2) {
    this._typeArguments = typeArguments2;
  }
  InterfaceTypeImpl substitute5(List<Type2> argumentTypes) => substitute2(argumentTypes, typeArguments);
  InterfaceTypeImpl substitute2(List<Type2> argumentTypes, List<Type2> parameterTypes) {
    if (argumentTypes.length != parameterTypes.length) {
      throw new IllegalArgumentException("argumentTypes.length (${argumentTypes.length}) != parameterTypes.length (${parameterTypes.length})");
    }
    if (argumentTypes.length == 0) {
      return this;
    }
    InterfaceTypeImpl newType = new InterfaceTypeImpl.con1(element);
    newType.typeArguments = TypeImpl.substitute(_typeArguments, argumentTypes, parameterTypes);
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
        ((_typeArguments[i] as TypeImpl)).appendTo(builder);
      }
      builder.append(">");
    }
  }
  bool isMoreSpecificThan2(InterfaceType s, Set<ClassElement> visitedClasses) {
    if (this == s) {
      return true;
    }
    if (s.isDirectSupertypeOf(this)) {
      return true;
    }
    ClassElement tElement = element;
    ClassElement sElement = s.element;
    if (tElement == sElement) {
      List<Type2> tArguments = typeArguments;
      List<Type2> sArguments = s.typeArguments;
      if (tArguments.length != sArguments.length) {
        return false;
      }
      for (int i = 0; i < tArguments.length; i++) {
        if (!tArguments[i].isMoreSpecificThan(sArguments[i])) {
          return false;
        }
      }
      return true;
    }
    ClassElement element = this.element;
    if (element == null || visitedClasses.contains(element)) {
      return false;
    }
    javaSetAdd(visitedClasses, element);
    InterfaceType supertype = element.supertype;
    if (supertype != null && ((supertype as InterfaceTypeImpl)).isMoreSpecificThan2(s, visitedClasses)) {
      return true;
    }
    for (InterfaceType interfaceType in element.interfaces) {
      if (((interfaceType as InterfaceTypeImpl)).isMoreSpecificThan2(s, visitedClasses)) {
        return true;
      }
    }
    for (InterfaceType mixinType in element.mixins) {
      if (((mixinType as InterfaceTypeImpl)).isMoreSpecificThan2(s, visitedClasses)) {
        return true;
      }
    }
    return false;
  }
  bool isSubtypeOf2(InterfaceType type, Set<ClassElement> visitedClasses) {
    InterfaceType typeT = this;
    InterfaceType typeS = type;
    ClassElement elementT = element;
    if (elementT == null || visitedClasses.contains(elementT)) {
      return false;
    }
    javaSetAdd(visitedClasses, elementT);
    typeT = substitute2(_typeArguments, TypeVariableTypeImpl.getTypes(elementT.typeVariables));
    if (typeT == typeS) {
      return true;
    } else if (elementT == typeS.element) {
      List<Type2> typeTArgs = typeT.typeArguments;
      List<Type2> typeSArgs = typeS.typeArguments;
      if (typeTArgs.length != typeSArgs.length) {
        return false;
      }
      for (int i = 0; i < typeTArgs.length; i++) {
        if (!typeTArgs[i].isSubtypeOf(typeSArgs[i])) {
          return false;
        }
      }
      return true;
    } else if (typeS.isDartCoreFunction() && elementT.getMethod("call") != null) {
      return true;
    }
    InterfaceType supertype = elementT.supertype;
    if (supertype != null && ((supertype as InterfaceTypeImpl)).isSubtypeOf2(typeS, visitedClasses)) {
      return true;
    }
    List<InterfaceType> interfaceTypes = elementT.interfaces;
    for (InterfaceType interfaceType in interfaceTypes) {
      if (((interfaceType as InterfaceTypeImpl)).isSubtypeOf2(typeS, visitedClasses)) {
        return true;
      }
    }
    List<InterfaceType> mixinTypes = elementT.mixins;
    for (InterfaceType mixinType in mixinTypes) {
      if (((mixinType as InterfaceTypeImpl)).isSubtypeOf2(typeS, visitedClasses)) {
        return true;
      }
    }
    return false;
  }
}
/**
 * The abstract class {@code TypeImpl} implements the behavior common to objects representing the
 * declared type of elements in the element model.
 * @coverage dart.engine.type
 */
abstract class TypeImpl implements Type2 {

  /**
   * Return an array containing the results of using the given argument types and parameter types to
   * perform a substitution on all of the given types.
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
   * The element representing the declaration of this type, or {@code null} if the type has not, or
   * cannot, be associated with an element.
   */
  Element _element;

  /**
   * The name of this type, or {@code null} if the type does not have a name.
   */
  String _name;

  /**
   * An empty array of types.
   */
  static List<Type2> EMPTY_ARRAY = new List<Type2>(0);

  /**
   * Initialize a newly created type to be declared by the given element and to have the given name.
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
  bool isAssignableTo(Type2 type) => this.isSubtypeOf(type) || type.isSubtypeOf(this);
  bool isDartCoreFunction() => false;
  bool isDynamic() => false;
  bool isMoreSpecificThan(Type2 type) => false;
  bool isObject() => false;
  bool isSupertypeOf(Type2 type) => type.isSubtypeOf(this);
  bool isVoid() => false;
  String toString() {
    JavaStringBuilder builder = new JavaStringBuilder();
    appendTo(builder);
    return builder.toString();
  }

  /**
   * Append a textual representation of this type to the given builder.
   * @param builder the builder to which the text is to be appended
   */
  void appendTo(JavaStringBuilder builder) {
    if (_name == null) {
      builder.append("<unnamed type>");
    } else {
      builder.append(_name);
    }
  }
}
/**
 * Instances of the class {@code TypeVariableTypeImpl} defines the behavior of objects representing
 * the type introduced by a type variable.
 * @coverage dart.engine.type
 */
class TypeVariableTypeImpl extends TypeImpl implements TypeVariableType {

  /**
   * Return an array containing the type variable types defined by the given array of type variable
   * elements.
   * @param typeVariables the type variable elements defining the type variable types to be returned
   * @return the type variable types defined by the type variable elements
   */
  static List<TypeVariableType> getTypes(List<TypeVariableElement> typeVariables) {
    int count = typeVariables.length;
    List<TypeVariableType> types = new List<TypeVariableType>(count);
    for (int i = 0; i < count; i++) {
      types[i] = typeVariables[i].type;
    }
    return types;
  }

  /**
   * Initialize a newly created type variable to be declared by the given element and to have the
   * given name.
   * @param element the element representing the declaration of the type variable
   */
  TypeVariableTypeImpl(TypeVariableElement element) : super(element, element.name) {
  }
  bool operator ==(Object object) => object is TypeVariableTypeImpl && element == ((object as TypeVariableTypeImpl)).element;
  TypeVariableElement get element => super.element as TypeVariableElement;
  int get hashCode => element.hashCode;
  bool isMoreSpecificThan(Type2 type) {
    Type2 upperBound = element.bound;
    return type == upperBound;
  }
  bool isSubtypeOf(Type2 type) => true;
  Type2 substitute2(List<Type2> argumentTypes, List<Type2> parameterTypes) {
    int length = parameterTypes.length;
    for (int i = 0; i < length; i++) {
      if (parameterTypes[i] == this) {
        return argumentTypes[i];
      }
    }
    return this;
  }
}
/**
 * The unique instance of the class {@code VoidTypeImpl} implements the type {@code void}.
 * @coverage dart.engine.type
 */
class VoidTypeImpl extends TypeImpl implements VoidType {

  /**
   * The unique instance of this class.
   */
  static VoidTypeImpl _INSTANCE = new VoidTypeImpl();

  /**
   * Return the unique instance of this class.
   * @return the unique instance of this class
   */
  static VoidTypeImpl get instance => _INSTANCE;

  /**
   * Prevent the creation of instances of this class.
   */
  VoidTypeImpl() : super(null, Keyword.VOID.syntax) {
  }
  bool operator ==(Object object) => identical(object, this);
  bool isSubtypeOf(Type2 type) => identical(type, this) || identical(type, DynamicTypeImpl.instance);
  bool isVoid() => true;
  VoidTypeImpl substitute2(List<Type2> argumentTypes, List<Type2> parameterTypes) => this;
}
/**
 * The interface {@code FunctionType} defines the behavior common to objects representing the type
 * of a function, method, constructor, getter, or setter. Function types come in three variations:
 * <ol>
 * <li>The types of functions that only have required parameters. These have the general form
 * <i>(T<sub>1</sub>, &hellip;, T<sub>n</sub>) &rarr; T</i>.</li>
 * <li>The types of functions with optional positional parameters. These have the general form
 * <i>(T<sub>1</sub>, &hellip;, T<sub>n</sub>, \[T<sub>n+1</sub>, &hellip;, T<sub>n+k</sub>\]) &rarr;
 * T</i>.</li>
 * <li>The types of functions with named parameters. These have the general form <i>(T<sub>1</sub>,
 * &hellip;, T<sub>n</sub>, {T<sub>x1</sub> x1, &hellip;, T<sub>xk</sub> xk}) &rarr; T</i>.</li>
 * </ol>
 * @coverage dart.engine.type
 */
abstract class FunctionType implements ParameterizedType {

  /**
   * Return a map from the names of named parameters to the types of the named parameters of this
   * type of function. The entries in the map will be iterated in the same order as the order in
   * which the named parameters were defined. If there were no named parameters declared then the
   * map will be empty.
   * @return a map from the name to the types of the named parameters of this type of function
   */
  Map<String, Type2> get namedParameterTypes;

  /**
   * Return an array containing the types of the normal parameters of this type of function. The
   * parameter types are in the same order as they appear in the declaration of the function.
   * @return the types of the normal parameters of this type of function
   */
  List<Type2> get normalParameterTypes;

  /**
   * Return a map from the names of optional (positional) parameters to the types of the optional
   * parameters of this type of function. The entries in the map will be iterated in the same order
   * as the order in which the optional parameters were defined. If there were no optional
   * parameters declared then the map will be empty.
   * @return a map from the name to the types of the optional parameters of this type of function
   */
  List<Type2> get optionalParameterTypes;

  /**
   * Return an array containing the parameters elements of this type of function. The parameter
   * types are in the same order as they appear in the declaration of the function.
   * @return the parameters elements of this type of function
   */
  List<ParameterElement> get parameters;

  /**
   * Return the type of object returned by this type of function.
   * @return the type of object returned by this type of function
   */
  Type2 get returnType;

  /**
   * Return {@code true} if this type is a subtype of the given type.
   * <p>
   * A function type <i>(T<sub>1</sub>, &hellip;, T<sub>n</sub>) &rarr; T</i> is a subtype of the
   * function type <i>(S<sub>1</sub>, &hellip;, S<sub>n</sub>) &rarr; S</i>, if all of the following
   * conditions are met:
   * <ul>
   * <li>Either
   * <ul>
   * <li><i>S</i> is void, or</li>
   * <li><i>T &hArr; S</i>.</li>
   * </ul>
   * </li>
   * <li>For all <i>i</i>, 1 <= <i>i</i> <= <i>n</i>, <i>T<sub>i</sub> &hArr; S<sub>i</sub></i>.</li>
   * </ul>
   * A function type <i>(T<sub>1</sub>, &hellip;, T<sub>n</sub>, \[T<sub>n+1</sub>, &hellip;,
   * T<sub>n+k</sub>\]) &rarr; T</i> is a subtype of the function type <i>(S<sub>1</sub>, &hellip;,
   * S<sub>n</sub>, \[S<sub>n+1</sub>, &hellip;, S<sub>n+m</sub>\]) &rarr; S</i>, if all of the
   * following conditions are met:
   * <ul>
   * <li>Either
   * <ul>
   * <li><i>S</i> is void, or</li>
   * <li><i>T &hArr; S</i>.</li>
   * </ul>
   * </li>
   * <li><i>k</i> >= <i>m</i> and for all <i>i</i>, 1 <= <i>i</i> <= <i>n+m</i>, <i>T<sub>i</sub>
   * &hArr; S<sub>i</sub></i>.</li>
   * </ul>
   * A function type <i>(T<sub>1</sub>, &hellip;, T<sub>n</sub>, {T<sub>x1</sub> x1, &hellip;,
   * T<sub>xk</sub> xk}) &rarr; T</i> is a subtype of the function type <i>(S<sub>1</sub>, &hellip;,
   * S<sub>n</sub>, {S<sub>y1</sub> y1, &hellip;, S<sub>ym</sub> ym}) &rarr; S</i>, if all of the
   * following conditions are met:
   * <ul>
   * <li>Either
   * <ul>
   * <li><i>S</i> is void,</li>
   * <li>or <i>T &hArr; S</i>.</li>
   * </ul>
   * </li>
   * <li>For all <i>i</i>, 1 <= <i>i</i> <= <i>n</i>, <i>T<sub>i</sub> &hArr; S<sub>i</sub></i>.</li>
   * <li><i>k</i> >= <i>m</i> and <i>y<sub>i</sub></i> in <i>{x<sub>1</sub>, &hellip;,
   * x<sub>k</sub>}</i>, 1 <= <i>i</i> <= <i>m</i>.</li>
   * <li>For all <i>y<sub>i</sub></i> in <i>{y<sub>1</sub>, &hellip;, y<sub>m</sub>}</i>,
   * <i>y<sub>i</sub> = x<sub>j</sub> => Tj &hArr; Si</i>.</li>
   * </ul>
   * In addition, the following subtype rules apply:
   * <p>
   * <i>(T<sub>1</sub>, &hellip;, T<sub>n</sub>, \[\]) &rarr; T <: (T<sub>1</sub>, &hellip;,
   * T<sub>n</sub>) &rarr; T.</i><br>
   * <i>(T<sub>1</sub>, &hellip;, T<sub>n</sub>) &rarr; T <: (T<sub>1</sub>, &hellip;,
   * T<sub>n</sub>, {}) &rarr; T.</i><br>
   * <i>(T<sub>1</sub>, &hellip;, T<sub>n</sub>, {}) &rarr; T <: (T<sub>1</sub>, &hellip;,
   * T<sub>n</sub>) &rarr; T.</i><br>
   * <i>(T<sub>1</sub>, &hellip;, T<sub>n</sub>) &rarr; T <: (T<sub>1</sub>, &hellip;,
   * T<sub>n</sub>, \[\]) &rarr; T.</i>
   * <p>
   * All functions implement the class {@code Function}. However not all function types are a
   * subtype of {@code Function}. If an interface type <i>I</i> includes a method named{@code call()}, and the type of {@code call()} is the function type <i>F</i>, then <i>I</i> is
   * considered to be a subtype of <i>F</i>.
   * @param type the type being compared with this type
   * @return {@code true} if this type is a subtype of the given type
   */
  bool isSubtypeOf(Type2 type);

  /**
   * Return the type resulting from substituting the given arguments for this type's parameters.
   * This is fully equivalent to {@code substitute(argumentTypes, getTypeArguments())}.
   * @param argumentTypes the actual type arguments being substituted for the type parameters
   * @return the result of performing the substitution
   */
  FunctionType substitute4(List<Type2> argumentTypes);
  FunctionType substitute2(List<Type2> argumentTypes, List<Type2> parameterTypes);
}
/**
 * The interface {@code InterfaceType} defines the behavior common to objects representing the type
 * introduced by either a class or an interface, or a reference to such a type.
 * @coverage dart.engine.type
 */
abstract class InterfaceType implements ParameterizedType {
  ClassElement get element;

  /**
   * Return the element representing the getter with the given name that is declared in this class,
   * or {@code null} if this class does not declare a getter with the given name.
   * @param getterName the name of the getter to be returned
   * @return the getter declared in this class with the given name
   */
  PropertyAccessorElement getGetter(String getterName);

  /**
   * Return an array containing all of the interfaces that are implemented by this interface. Note
   * that this is <b>not</b>, in general, equivalent to getting the interfaces from this type's
   * element because the types returned by this method will have had their type parameters replaced.
   * @return the interfaces that are implemented by this type
   */
  List<InterfaceType> get interfaces;

  /**
   * Return the least upper bound of this type and the given type, or {@code null} if there is no
   * least upper bound.
   * <p>
   * Given two interfaces <i>I</i> and <i>J</i>, let <i>S<sub>I</sub></i> be the set of
   * superinterfaces of <i>I<i>, let <i>S<sub>J</sub></i> be the set of superinterfaces of <i>J</i>
   * and let <i>S = (I &cup; S<sub>I</sub>) &cap; (J &cup; S<sub>J</sub>)</i>. Furthermore, we
   * define <i>S<sub>n</sub> = {T | T &isin; S &and; depth(T) = n}</i> for any finite <i>n</i>,
   * where <i>depth(T)</i> is the number of steps in the longest inheritance path from <i>T</i> to
   * <i>Object</i>. Let <i>q</i> be the largest number such that <i>S<sub>q</sub></i> has
   * cardinality one. The least upper bound of <i>I</i> and <i>J</i> is the sole element of
   * <i>S<sub>q</sub></i>.
   * @param type the other type used to compute the least upper bound
   * @return the least upper bound of this type and the given type
   */
  Type2 getLeastUpperBound(Type2 type);

  /**
   * Return the element representing the method with the given name that is declared in this class,
   * or {@code null} if this class does not declare a method with the given name.
   * @param methodName the name of the method to be returned
   * @return the method declared in this class with the given name
   */
  MethodElement getMethod(String methodName);

  /**
   * Return an array containing all of the mixins that are applied to the class being extended in
   * order to derive the superclass of this class. Note that this is <b>not</b>, in general,
   * equivalent to getting the mixins from this type's element because the types returned by this
   * method will have had their type parameters replaced.
   * @return the mixins that are applied to derive the superclass of this class
   */
  List<InterfaceType> get mixins;

  /**
   * Return the element representing the setter with the given name that is declared in this class,
   * or {@code null} if this class does not declare a setter with the given name.
   * @param setterName the name of the setter to be returned
   * @return the setter declared in this class with the given name
   */
  PropertyAccessorElement getSetter(String setterName);

  /**
   * Return the type representing the superclass of this type, or null if this type represents the
   * class 'Object'. Note that this is <b>not</b>, in general, equivalent to getting the superclass
   * from this type's element because the type returned by this method will have had it's type
   * parameters replaced.
   * @return the superclass of this type
   */
  InterfaceType get superclass;

  /**
   * Return {@code true} if this type is a direct supertype of the given type. The implicit
   * interface of class <i>I</i> is a direct supertype of the implicit interface of class <i>J</i>
   * iff:
   * <ul>
   * <li><i>I</i> is Object, and <i>J</i> has no extends clause.</li>
   * <li><i>I</i> is listed in the extends clause of <i>J</i>.</li>
   * <li><i>I</i> is listed in the implements clause of <i>J</i>.</li>
   * <li><i>I</i> is listed in the with clause of <i>J</i>.</li>
   * <li><i>J</i> is a mixin application of the mixin of <i>I</i>.</li>
   * </ul>
   * @param type the type being compared with this type
   * @return {@code true} if this type is a direct supertype of the given type
   */
  bool isDirectSupertypeOf(InterfaceType type);

  /**
   * Return {@code true} if this type is more specific than the given type. An interface type
   * <i>T</i> is more specific than an interface type <i>S</i>, written <i>T &laquo; S</i>, if one
   * of the following conditions is met:
   * <ul>
   * <li>Reflexivity: <i>T</i> is <i>S</i>.
   * <li><i>T</i> is bottom.
   * <li><i>S</i> is dynamic.
   * <li>Direct supertype: <i>S</i> is a direct supertype of <i>T</i>.
   * <li><i>T</i> is a type variable and <i>S</i> is the upper bound of <i>T</i>.
   * <li>Covariance: <i>T</i> is of the form <i>I&lt;T<sub>1</sub>, &hellip;, T<sub>n</sub>&gt;</i>
   * and S</i> is of the form <i>I&lt;S<sub>1</sub>, &hellip;, S<sub>n</sub>&gt;</i> and
   * <i>T<sub>i</sub> &laquo; S<sub>i</sub></i>, <i>1 <= i <= n</i>.
   * <li>Transitivity: <i>T &laquo; U</i> and <i>U &laquo; S</i>.
   * </ul>
   * @param type the type being compared with this type
   * @return {@code true} if this type is more specific than the given type
   */
  bool isMoreSpecificThan(Type2 type);

  /**
   * Return {@code true} if this type is a subtype of the given type. An interface type <i>T</i> is
   * a subtype of an interface type <i>S</i>, written <i>T</i> <: <i>S</i>, iff
   * <i>\[bottom/dynamic\]T</i> &laquo; <i>S</i> (<i>T</i> is more specific than <i>S</i>). If an
   * interface type <i>I</i> includes a method named <i>call()</i>, and the type of <i>call()</i> is
   * the function type <i>F</i>, then <i>I</i> is considered to be a subtype of <i>F</i>.
   * @param type the type being compared with this type
   * @return {@code true} if this type is a subtype of the given type
   */
  bool isSubtypeOf(Type2 type);

  /**
   * Return the element representing the constructor that results from looking up the given
   * constructor in this class with respect to the given library, or {@code null} if the look up
   * fails. The behavior of this method is defined by the Dart Language Specification in section
   * 12.11.1: <blockquote>If <i>e</i> is of the form <b>new</b> <i>T.id()</i> then let <i>q<i> be
   * the constructor <i>T.id</i>, otherwise let <i>q<i> be the constructor <i>T<i>. Otherwise, if
   * <i>q</i> is not defined or not accessible, a NoSuchMethodException is thrown. </blockquote>
   * @param constructorName the name of the constructor being looked up
   * @param library the library with respect to which the lookup is being performed
   * @return the result of looking up the given constructor in this class with respect to the given
   * library
   */
  ConstructorElement lookUpConstructor(String constructorName, LibraryElement library);

  /**
   * Return the element representing the getter that results from looking up the given getter in
   * this class with respect to the given library, or {@code null} if the look up fails. The
   * behavior of this method is defined by the Dart Language Specification in section 12.15.1:
   * <blockquote>The result of looking up getter (respectively setter) <i>m</i> in class <i>C</i>
   * with respect to library <i>L</i> is:
   * <ul>
   * <li>If <i>C</i> declares an instance getter (respectively setter) named <i>m</i> that is
   * accessible to <i>L</i>, then that getter (respectively setter) is the result of the lookup.
   * Otherwise, if <i>C</i> has a superclass <i>S</i>, then the result of the lookup is the result
   * of looking up getter (respectively setter) <i>m</i> in <i>S</i> with respect to <i>L</i>.
   * Otherwise, we say that the lookup has failed.</li>
   * </ul>
   * </blockquote>
   * @param getterName the name of the getter being looked up
   * @param library the library with respect to which the lookup is being performed
   * @return the result of looking up the given getter in this class with respect to the given
   * library
   */
  PropertyAccessorElement lookUpGetter(String getterName, LibraryElement library);

  /**
   * Return the element representing the getter that results from looking up the given getter in the
   * superclass of this class with respect to the given library, or {@code null} if the look up
   * fails. The behavior of this method is defined by the Dart Language Specification in section
   * 12.15.1: <blockquote>The result of looking up getter (respectively setter) <i>m</i> in class
   * <i>C</i> with respect to library <i>L</i> is:
   * <ul>
   * <li>If <i>C</i> declares an instance getter (respectively setter) named <i>m</i> that is
   * accessible to <i>L</i>, then that getter (respectively setter) is the result of the lookup.
   * Otherwise, if <i>C</i> has a superclass <i>S</i>, then the result of the lookup is the result
   * of looking up getter (respectively setter) <i>m</i> in <i>S</i> with respect to <i>L</i>.
   * Otherwise, we say that the lookup has failed.</li>
   * </ul>
   * </blockquote>
   * @param getterName the name of the getter being looked up
   * @param library the library with respect to which the lookup is being performed
   * @return the result of looking up the given getter in this class with respect to the given
   * library
   */
  PropertyAccessorElement lookUpGetterInSuperclass(String getterName, LibraryElement library);

  /**
   * Return the element representing the method that results from looking up the given method in
   * this class with respect to the given library, or {@code null} if the look up fails. The
   * behavior of this method is defined by the Dart Language Specification in section 12.15.1:
   * <blockquote> The result of looking up method <i>m</i> in class <i>C</i> with respect to library
   * <i>L</i> is:
   * <ul>
   * <li>If <i>C</i> declares an instance method named <i>m</i> that is accessible to <i>L</i>, then
   * that method is the result of the lookup. Otherwise, if <i>C</i> has a superclass <i>S</i>, then
   * the result of the lookup is the result of looking up method <i>m</i> in <i>S</i> with respect
   * to <i>L</i>. Otherwise, we say that the lookup has failed.</li>
   * </ul>
   * </blockquote>
   * @param methodName the name of the method being looked up
   * @param library the library with respect to which the lookup is being performed
   * @return the result of looking up the given method in this class with respect to the given
   * library
   */
  MethodElement lookUpMethod(String methodName, LibraryElement library);

  /**
   * Return the element representing the method that results from looking up the given method in the
   * superclass of this class with respect to the given library, or {@code null} if the look up
   * fails. The behavior of this method is defined by the Dart Language Specification in section
   * 12.15.1: <blockquote> The result of looking up method <i>m</i> in class <i>C</i> with respect
   * to library <i>L</i> is:
   * <ul>
   * <li>If <i>C</i> declares an instance method named <i>m</i> that is accessible to <i>L</i>, then
   * that method is the result of the lookup. Otherwise, if <i>C</i> has a superclass <i>S</i>, then
   * the result of the lookup is the result of looking up method <i>m</i> in <i>S</i> with respect
   * to <i>L</i>. Otherwise, we say that the lookup has failed.</li>
   * </ul>
   * </blockquote>
   * @param methodName the name of the method being looked up
   * @param library the library with respect to which the lookup is being performed
   * @return the result of looking up the given method in this class with respect to the given
   * library
   */
  MethodElement lookUpMethodInSuperclass(String methodName, LibraryElement library);

  /**
   * Return the element representing the setter that results from looking up the given setter in
   * this class with respect to the given library, or {@code null} if the look up fails. The
   * behavior of this method is defined by the Dart Language Specification in section 12.16:
   * <blockquote> The result of looking up getter (respectively setter) <i>m</i> in class <i>C</i>
   * with respect to library <i>L</i> is:
   * <ul>
   * <li>If <i>C</i> declares an instance getter (respectively setter) named <i>m</i> that is
   * accessible to <i>L</i>, then that getter (respectively setter) is the result of the lookup.
   * Otherwise, if <i>C</i> has a superclass <i>S</i>, then the result of the lookup is the result
   * of looking up getter (respectively setter) <i>m</i> in <i>S</i> with respect to <i>L</i>.
   * Otherwise, we say that the lookup has failed.</li>
   * </ul>
   * </blockquote>
   * @param setterName the name of the setter being looked up
   * @param library the library with respect to which the lookup is being performed
   * @return the result of looking up the given setter in this class with respect to the given
   * library
   */
  PropertyAccessorElement lookUpSetter(String setterName, LibraryElement library);

  /**
   * Return the element representing the setter that results from looking up the given setter in the
   * superclass of this class with respect to the given library, or {@code null} if the look up
   * fails. The behavior of this method is defined by the Dart Language Specification in section
   * 12.16: <blockquote> The result of looking up getter (respectively setter) <i>m</i> in class
   * <i>C</i> with respect to library <i>L</i> is:
   * <ul>
   * <li>If <i>C</i> declares an instance getter (respectively setter) named <i>m</i> that is
   * accessible to <i>L</i>, then that getter (respectively setter) is the result of the lookup.
   * Otherwise, if <i>C</i> has a superclass <i>S</i>, then the result of the lookup is the result
   * of looking up getter (respectively setter) <i>m</i> in <i>S</i> with respect to <i>L</i>.
   * Otherwise, we say that the lookup has failed.</li>
   * </ul>
   * </blockquote>
   * @param setterName the name of the setter being looked up
   * @param library the library with respect to which the lookup is being performed
   * @return the result of looking up the given setter in this class with respect to the given
   * library
   */
  PropertyAccessorElement lookUpSetterInSuperclass(String setterName, LibraryElement library);

  /**
   * Return the type resulting from substituting the given arguments for this type's parameters.
   * This is fully equivalent to {@code substitute(argumentTypes, getTypeArguments())}.
   * @param argumentTypes the actual type arguments being substituted for the type parameters
   * @return the result of performing the substitution
   */
  InterfaceType substitute5(List<Type2> argumentTypes);
  InterfaceType substitute2(List<Type2> argumentTypes, List<Type2> parameterTypes);
}
/**
 * The interface {@code ParameterizedType} defines the behavior common to objects representing the
 * type with type parameters, such as class and function type alias.
 * @coverage dart.engine.type
 */
abstract class ParameterizedType implements Type2 {

  /**
   * Return an array containing the actual types of the type arguments. If this type's element does
   * not have type parameters, then the array should be empty (although it is possible for type
   * arguments to be erroneously declared). If the element has type parameters and the actual type
   * does not explicitly include argument values, then the type "dynamic" will be automatically
   * provided.
   * @return the actual types of the type arguments
   */
  List<Type2> get typeArguments;

  /**
   * Return an array containing all of the type variables declared for this type.
   * @return the type variables declared for this type
   */
  List<TypeVariableElement> get typeVariables;
}
/**
 * The interface {@code Type} defines the behavior of objects representing the declared type of
 * elements in the element model.
 * @coverage dart.engine.type
 */
abstract class Type2 {

  /**
   * Return the name of this type as it should appear when presented to users in contexts such as
   * error messages.
   * @return the name of this type
   */
  String get displayName;

  /**
   * Return the element representing the declaration of this type, or {@code null} if the type has
   * not, or cannot, be associated with an element. The former case will occur if the element model
   * is not yet complete; the latter case will occur if this object represents an undefined type.
   * @return the element representing the declaration of this type
   */
  Element get element;

  /**
   * Return the least upper bound of this type and the given type, or {@code null} if there is no
   * least upper bound.
   * @param type the other type used to compute the least upper bound
   * @return the least upper bound of this type and the given type
   */
  Type2 getLeastUpperBound(Type2 type);

  /**
   * Return the name of this type, or {@code null} if the type does not have a name, such as when
   * the type represents the type of an unnamed function.
   * @return the name of this type
   */
  String get name;

  /**
   * Return {@code true} if this type is assignable to the given type. A type <i>T</i> may be
   * assigned to a type <i>S</i>, written <i>T</i> &hArr; <i>S</i>, iff either <i>T</i> <: <i>S</i>
   * or <i>S</i> <: <i>T</i>.
   * @param type the type being compared with this type
   * @return {@code true} if this type is assignable to the given type
   */
  bool isAssignableTo(Type2 type);

  /**
   * Return {@code true} if this type represents the type 'Function' defined in the dart:core
   * library.
   * @return {@code true} if this type represents the type 'Function' defined in the dart:core
   * library
   */
  bool isDartCoreFunction();

  /**
   * Return {@code true} if this type represents the type 'dynamic'.
   * @return {@code true} if this type represents the type 'dynamic'
   */
  bool isDynamic();

  /**
   * Return {@code true} if this type is more specific than the given type.
   * @param type the type being compared with this type
   * @return {@code true} if this type is more specific than the given type
   */
  bool isMoreSpecificThan(Type2 type);

  /**
   * Return {@code true} if this type represents the type 'Object'.
   * @return {@code true} if this type represents the type 'Object'
   */
  bool isObject();

  /**
   * Return {@code true} if this type is a subtype of the given type.
   * @param type the type being compared with this type
   * @return {@code true} if this type is a subtype of the given type
   */
  bool isSubtypeOf(Type2 type);

  /**
   * Return {@code true} if this type is a supertype of the given type. A type <i>S</i> is a
   * supertype of <i>T</i>, written <i>S</i> :> <i>T</i>, iff <i>T</i> is a subtype of <i>S</i>.
   * @param type the type being compared with this type
   * @return {@code true} if this type is a supertype of the given type
   */
  bool isSupertypeOf(Type2 type);

  /**
   * Return {@code true} if this type represents the type 'void'.
   * @return {@code true} if this type represents the type 'void'
   */
  bool isVoid();

  /**
   * Return the type resulting from substituting the given arguments for the given parameters in
   * this type. The specification defines this operation in section 2: <blockquote> The notation
   * <i>\[x<sub>1</sub>, ..., x<sub>n</sub>/y<sub>1</sub>, ..., y<sub>n</sub>\]E</i> denotes a copy of
   * <i>E</i> in which all occurrences of <i>y<sub>i</sub>, 1 <= i <= n</i> have been replaced with
   * <i>x<sub>i</sub></i>.</blockquote> Note that, contrary to the specification, this method will
   * not create a copy of this type if no substitutions were required, but will return this type
   * directly.
   * @param argumentTypes the actual type arguments being substituted for the parameters
   * @param parameterTypes the parameters to be replaced
   * @return the result of performing the substitution
   */
  Type2 substitute2(List<Type2> argumentTypes, List<Type2> parameterTypes);
}
/**
 * The interface {@code TypeVariableType} defines the behavior of objects representing the type
 * introduced by a type variable.
 * @coverage dart.engine.type
 */
abstract class TypeVariableType implements Type2 {
  TypeVariableElement get element;
}
/**
 * The interface {@code VoidType} defines the behavior of the unique object representing the type{@code void}.
 * @coverage dart.engine.type
 */
abstract class VoidType implements Type2 {
  VoidType substitute2(List<Type2> argumentTypes, List<Type2> parameterTypes);
}