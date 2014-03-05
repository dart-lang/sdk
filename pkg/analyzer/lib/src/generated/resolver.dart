// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.resolver;

import 'dart:collection';
import 'java_core.dart';
import 'java_engine.dart';
import 'instrumentation.dart';
import 'source.dart';
import 'error.dart';
import 'scanner.dart' as sc;
import 'utilities_dart.dart';
import 'utilities_general.dart';
import 'ast.dart';
import 'parser.dart' show Parser, ParserErrorCode;
import 'sdk.dart' show DartSdk, SdkLibrary;
import 'element.dart';
import 'html.dart' as ht;
import 'engine.dart';
import 'constant.dart';

/**
 * Instances of the class `AngularCompilationUnitBuilder` build an Angular specific element
 * model for a single compilation unit.
 */
class AngularCompilationUnitBuilder {
  static String _NG_COMPONENT = "NgComponent";

  static String _NG_CONTROLLER = "NgController";

  static String _NG_DIRECTIVE = "NgDirective";

  static String _NG_FILTER = "NgFilter";

  static String _NAME = "name";

  static String _SELECTOR = "selector";

  static String _PUBLISH_AS = "publishAs";

  static String _TEMPLATE_URL = "templateUrl";

  static String _CSS_URL = "cssUrl";

  static String _NG_ATTR = "NgAttr";

  static String _NG_CALLBACK = "NgCallback";

  static String _NG_ONE_WAY = "NgOneWay";

  static String _NG_ONE_WAY_ONE_TIME = "NgOneWayOneTime";

  static String _NG_TWO_WAY = "NgTwoWay";

  static Element getElement(AstNode node, int offset) {
    // maybe node is not SimpleStringLiteral
    if (node is! SimpleStringLiteral) {
      return null;
    }
    SimpleStringLiteral literal = node as SimpleStringLiteral;
    // maybe has AngularElement
    {
      Element element = literal.toolkitElement;
      if (element is AngularElement) {
        return element;
      }
    }
    // prepare enclosing ClassDeclaration
    ClassDeclaration classDeclaration = node.getAncestor((node) => node is ClassDeclaration);
    if (classDeclaration == null) {
      return null;
    }
    // prepare ClassElement
    ClassElement classElement = classDeclaration.element;
    if (classElement == null) {
      return null;
    }
    // check toolkit objects
    for (ToolkitObjectElement toolkitObject in classElement.toolkitObjects) {
      List<AngularPropertyElement> properties = AngularPropertyElement.EMPTY_ARRAY;
      // maybe name
      if (toolkitObject is AngularElement) {
        if (isNameCoveredByLiteral(toolkitObject, node)) {
          return toolkitObject;
        }
      }
      // try selector
      if (toolkitObject is AngularHasSelectorElement) {
        AngularHasSelectorElement hasSelector = toolkitObject;
        AngularSelectorElement selector = hasSelector.selector;
        if (isNameCoveredByLiteral(selector, node)) {
          return selector;
        }
      }
      // try properties of AngularComponentElement
      if (toolkitObject is AngularComponentElement) {
        AngularComponentElement component = toolkitObject;
        properties = component.properties;
      }
      // try properties of AngularDirectiveElement
      if (toolkitObject is AngularDirectiveElement) {
        AngularDirectiveElement directive = toolkitObject;
        properties = directive.properties;
      }
      // check properties
      for (AngularPropertyElement property in properties) {
        // property name (use complete node range)
        if (isNameCoveredByLiteral(property, node)) {
          return property;
        }
        // field name (use complete node range, including @, => and <=>)
        FieldElement field = property.field;
        if (field != null) {
          int fieldOffset = property.fieldNameOffset;
          int fieldEnd = fieldOffset + field.name.length;
          if (node.offset <= fieldOffset && fieldEnd < node.end) {
            return field;
          }
        }
      }
    }
    // no Element
    return null;
  }

  /**
   * Parses given selector text and returns [AngularSelectorElement]. May be `null` if
   * cannot parse.
   */
  static AngularSelectorElement parseSelector(int offset, String text) {
    // [attribute]
    if (StringUtilities.startsWithChar(text, 0x5B) && StringUtilities.endsWithChar(text, 0x5D)) {
      int nameOffset = offset + 1;
      String attributeName = text.substring(1, text.length - 1);
      // TODO(scheglov) report warning if there are spaces between [ and identifier
      return new HasAttributeSelectorElementImpl(attributeName, nameOffset);
    }
    // .class
    if (StringUtilities.startsWithChar(text, 0x2E)) {
      int nameOffset = offset + 1;
      String className = text.substring(1, text.length);
      return new AngularHasClassSelectorElementImpl(className, nameOffset);
    }
    // tag[attribute]
    if (StringUtilities.endsWithChar(text, 0x5D)) {
      int index = StringUtilities.indexOf1(text, 0, 0x5B);
      if (index != -1) {
        String tagName = text.substring(0, index);
        String attributeName = text.substring(index + 1, text.length - 1);
        if (StringUtilities.isTagName(tagName)) {
          return new IsTagHasAttributeSelectorElementImpl(tagName, attributeName);
        }
      }
    }
    // tag
    if (StringUtilities.isTagName(text)) {
      return new AngularTagSelectorElementImpl(text, offset);
    }
    return null;
  }

  /**
   * Returns the [FieldElement] of the first field in the given [FieldDeclaration].
   */
  static FieldElement getOnlyFieldElement(FieldDeclaration fieldDeclaration) {
    NodeList<VariableDeclaration> fields = fieldDeclaration.fields.variables;
    return fields[0].element as FieldElement;
  }

  /**
   * If given [Annotation] has one argument and it is [SimpleStringLiteral], returns it,
   * otherwise returns `null`.
   */
  static SimpleStringLiteral getOnlySimpleStringLiteralArgument(Annotation annotation) {
    SimpleStringLiteral nameLiteral = null;
    ArgumentList argsNode = annotation.arguments;
    if (argsNode != null) {
      NodeList<Expression> args = argsNode.arguments;
      if (args.length == 1) {
        Expression arg = args[0];
        if (arg is SimpleStringLiteral) {
          nameLiteral = arg;
        }
      }
    }
    return nameLiteral;
  }

  /**
   * Checks if the name range of the given [Element] is completely covered by the given
   * [SimpleStringLiteral].
   */
  static bool isNameCoveredByLiteral(Element element, AstNode node) {
    if (element != null) {
      String name = element.name;
      if (name != null) {
        int nameOffset = element.nameOffset;
        int nameEnd = nameOffset + name.length;
        return node.offset <= nameOffset && nameEnd < node.end;
      }
    }
    return false;
  }

  /**
   * Parses given [SimpleStringLiteral] using [parseSelector].
   */
  static AngularSelectorElement parseSelectorFromString(SimpleStringLiteral literal) {
    int offset = literal.valueOffset;
    String text = literal.stringValue;
    return parseSelector(offset, text);
  }

  /**
   * The listener to which errors will be reported.
   */
  AnalysisErrorListener _errorListener;

  /**
   * The source containing the unit that will be analyzed.
   */
  Source _source;

  /**
   * The compilation unit with built Dart element models.
   */
  CompilationUnit _unit;

  /**
   * The [ClassDeclaration] that is currently being analyzed.
   */
  ClassDeclaration _classDeclaration;

  /**
   * The [ClassElementImpl] that is currently being analyzed.
   */
  ClassElementImpl _classElement;

  /**
   * The [ToolkitObjectElement]s to set for [classElement].
   */
  List<ToolkitObjectElement> _classToolkitObjects = [];

  /**
   * The [Annotation] that is currently being analyzed.
   */
  Annotation _annotation;

  /**
   * Initialize a newly created compilation unit element builder.
   *
   * @param errorListener the listener to which errors will be reported.
   * @param source the source containing the unit that will be analyzed
   * @param unit the compilation unit with built Dart element models
   */
  AngularCompilationUnitBuilder(AnalysisErrorListener errorListener, Source source, CompilationUnit unit) {
    this._errorListener = errorListener;
    this._source = source;
    this._unit = unit;
  }

  /**
   * Builds Angular specific element models and adds them to the existing Dart elements.
   */
  void build() {
    parseViews();
    // process classes
    for (CompilationUnitMember unitMember in _unit.declarations) {
      if (unitMember is ClassDeclaration) {
        this._classDeclaration = unitMember;
        this._classElement = _classDeclaration.element as ClassElementImpl;
        this._classToolkitObjects.clear();
        // process annotations
        NodeList<Annotation> annotations = _classDeclaration.metadata;
        for (Annotation annotation in annotations) {
          // verify annotation
          if (annotation.arguments == null) {
            continue;
          }
          this._annotation = annotation;
          // @NgFilter
          if (isAngularAnnotation(annotation, _NG_FILTER)) {
            parseNgFilter();
            continue;
          }
          // @NgComponent
          if (isAngularAnnotation(annotation, _NG_COMPONENT)) {
            parseNgComponent();
            continue;
          }
          // @NgController
          if (isAngularAnnotation(annotation, _NG_CONTROLLER)) {
            parseNgController();
            continue;
          }
          // @NgDirective
          if (isAngularAnnotation(annotation, _NG_DIRECTIVE)) {
            parseNgDirective();
            continue;
          }
        }
        // set toolkit objects
        if (!_classToolkitObjects.isEmpty) {
          List<ToolkitObjectElement> objects = _classToolkitObjects;
          _classElement.toolkitObjects = new List.from(objects);
        }
      }
    }
  }

  /**
   * @return the argument [Expression] with given name form [annotation], may be
   *         `null` if not found.
   */
  Expression getArgument(String name) {
    List<Expression> arguments = _annotation.arguments.arguments;
    for (Expression argument in arguments) {
      if (argument is NamedExpression) {
        NamedExpression namedExpression = argument;
        String argumentName = namedExpression.name.label.name;
        if (name == argumentName) {
          return namedExpression.expression;
        }
      }
    }
    return null;
  }

  /**
   * @return the [String] value of the named argument.
   */
  String getStringArgument(String name) => getStringLiteral(name).value;

  /**
   * @return the offset of the value of the named argument.
   */
  int getStringArgumentOffset(String name) {
    Expression argument = getArgument(name);
    return (argument as SimpleStringLiteral).valueOffset;
  }

  /**
   * @return the [SimpleStringLiteral] of the named argument.
   */
  SimpleStringLiteral getStringLiteral(String name) {
    Expression argument = getArgument(name);
    return argument as SimpleStringLiteral;
  }

  /**
   * Checks if [namedArguments] has string value for the argument with the given name.
   */
  bool hasStringArgument(String name) {
    Expression argument = getArgument(name);
    return argument is SimpleStringLiteral;
  }

  /**
   * Checks if given [Annotation] is an annotation with required name.
   */
  bool isAngularAnnotation(Annotation annotation, String name) {
    Element element = annotation.element;
    if (element is ConstructorElement) {
      ConstructorElement constructorElement = element;
      return constructorElement.returnType.displayName == name;
    }
    return false;
  }

  void parseNgComponent() {
    bool isValid = true;
    // publishAs
    String name = null;
    int nameOffset = -1;
    if (hasStringArgument(_PUBLISH_AS)) {
      name = getStringArgument(_PUBLISH_AS);
      nameOffset = getStringArgumentOffset(_PUBLISH_AS);
    }
    // selector
    AngularSelectorElement selector = null;
    if (!hasStringArgument(_SELECTOR)) {
      reportErrorForAnnotation(AngularCode.MISSING_SELECTOR, []);
      isValid = false;
    } else {
      SimpleStringLiteral selectorLiteral = getStringLiteral(_SELECTOR);
      selector = parseSelectorFromString(selectorLiteral);
      if (selector == null) {
        reportErrorForArgument(_SELECTOR, AngularCode.CANNOT_PARSE_SELECTOR, [selectorLiteral]);
        isValid = false;
      }
    }
    // templateUrl
    String templateUri = null;
    int templateUriOffset = -1;
    if (hasStringArgument(_TEMPLATE_URL)) {
      templateUri = getStringArgument(_TEMPLATE_URL);
      templateUriOffset = getStringArgumentOffset(_TEMPLATE_URL);
    }
    // cssUrl
    String styleUri = null;
    int styleUriOffset = -1;
    if (hasStringArgument(_CSS_URL)) {
      styleUri = getStringArgument(_CSS_URL);
      styleUriOffset = getStringArgumentOffset(_CSS_URL);
    }
    // create
    if (isValid) {
      AngularComponentElementImpl element = new AngularComponentElementImpl(name, nameOffset, _annotation.offset);
      element.selector = selector;
      element.templateUri = templateUri;
      element.templateUriOffset = templateUriOffset;
      element.styleUri = styleUri;
      element.styleUriOffset = styleUriOffset;
      element.properties = parseNgComponentProperties();
      element.scopeProperties = parseScopeProperties();
      _classToolkitObjects.add(element);
    }
  }

  /**
   * Parses [AngularPropertyElement]s from [annotation] and [classDeclaration].
   */
  List<AngularPropertyElement> parseNgComponentProperties() {
    List<AngularPropertyElement> properties = [];
    parseNgComponentProperties_fromMap(properties);
    parseNgComponentProperties_fromFields(properties);
    return new List.from(properties);
  }

  /**
   * Parses [AngularPropertyElement]s from [annotation].
   */
  void parseNgComponentProperties_fromFields(List<AngularPropertyElement> properties) {
    NodeList<ClassMember> members = _classDeclaration.members;
    for (ClassMember member in members) {
      if (member is FieldDeclaration) {
        FieldDeclaration fieldDeclaration = member;
        for (Annotation annotation in fieldDeclaration.metadata) {
          // prepare property kind (if property annotation at all)
          AngularPropertyKind kind = null;
          if (isAngularAnnotation(annotation, _NG_ATTR)) {
            kind = AngularPropertyKind.ATTR;
          } else if (isAngularAnnotation(annotation, _NG_CALLBACK)) {
            kind = AngularPropertyKind.CALLBACK;
          } else if (isAngularAnnotation(annotation, _NG_ONE_WAY)) {
            kind = AngularPropertyKind.ONE_WAY;
          } else if (isAngularAnnotation(annotation, _NG_ONE_WAY_ONE_TIME)) {
            kind = AngularPropertyKind.ONE_WAY_ONE_TIME;
          } else if (isAngularAnnotation(annotation, _NG_TWO_WAY)) {
            kind = AngularPropertyKind.TWO_WAY;
          }
          // add property
          if (kind != null) {
            SimpleStringLiteral nameLiteral = getOnlySimpleStringLiteralArgument(annotation);
            FieldElement field = getOnlyFieldElement(fieldDeclaration);
            if (nameLiteral != null && field != null) {
              AngularPropertyElementImpl property = new AngularPropertyElementImpl(nameLiteral.value, nameLiteral.valueOffset);
              property.field = field;
              property.propertyKind = kind;
              properties.add(property);
            }
          }
        }
      }
    }
  }

  /**
   * Parses [AngularPropertyElement]s from [annotation].
   */
  void parseNgComponentProperties_fromMap(List<AngularPropertyElement> properties) {
    Expression mapExpression = getArgument("map");
    // may be not properties
    if (mapExpression == null) {
      return;
    }
    // prepare map literal
    if (mapExpression is! MapLiteral) {
      reportErrorForNode(AngularCode.INVALID_PROPERTY_MAP, mapExpression, []);
      return;
    }
    MapLiteral mapLiteral = mapExpression as MapLiteral;
    // analyze map entries
    for (MapLiteralEntry entry in mapLiteral.entries) {
      // prepare property name
      Expression nameExpression = entry.key;
      if (nameExpression is! SimpleStringLiteral) {
        reportErrorForNode(AngularCode.INVALID_PROPERTY_NAME, nameExpression, []);
        continue;
      }
      SimpleStringLiteral nameLiteral = nameExpression as SimpleStringLiteral;
      String name = nameLiteral.value;
      int nameOffset = nameLiteral.valueOffset;
      // prepare field specification
      Expression specExpression = entry.value;
      if (specExpression is! SimpleStringLiteral) {
        reportErrorForNode(AngularCode.INVALID_PROPERTY_SPEC, specExpression, []);
        continue;
      }
      SimpleStringLiteral specLiteral = specExpression as SimpleStringLiteral;
      String spec = specLiteral.value;
      // parse binding kind and field name
      AngularPropertyKind kind;
      int fieldNameOffset;
      if (StringUtilities.startsWithChar(spec, 0x40)) {
        kind = AngularPropertyKind.ATTR;
        fieldNameOffset = 1;
      } else if (StringUtilities.startsWithChar(spec, 0x26)) {
        kind = AngularPropertyKind.CALLBACK;
        fieldNameOffset = 1;
      } else if (StringUtilities.startsWith3(spec, 0, 0x3D, 0x3E, 0x21)) {
        kind = AngularPropertyKind.ONE_WAY_ONE_TIME;
        fieldNameOffset = 3;
      } else if (StringUtilities.startsWith2(spec, 0, 0x3D, 0x3E)) {
        kind = AngularPropertyKind.ONE_WAY;
        fieldNameOffset = 2;
      } else if (StringUtilities.startsWith3(spec, 0, 0x3C, 0x3D, 0x3E)) {
        kind = AngularPropertyKind.TWO_WAY;
        fieldNameOffset = 3;
      } else {
        reportErrorForNode(AngularCode.INVALID_PROPERTY_KIND, specLiteral, [spec]);
        continue;
      }
      String fieldName = spec.substring(fieldNameOffset);
      fieldNameOffset += specLiteral.valueOffset;
      // prepare field
      PropertyAccessorElement setter = _classElement.type.lookUpSetter(fieldName, _classElement.library);
      if (setter == null) {
        reportErrorForOffset(AngularCode.INVALID_PROPERTY_FIELD, fieldNameOffset, fieldName.length, [fieldName]);
        continue;
      }
      FieldElement field = setter.variable as FieldElement;
      // add property
      AngularPropertyElementImpl property = new AngularPropertyElementImpl(name, nameOffset);
      property.field = field;
      property.propertyKind = kind;
      property.fieldNameOffset = fieldNameOffset;
      properties.add(property);
    }
  }

  void parseNgController() {
    bool isValid = true;
    // publishAs
    if (!hasStringArgument(_PUBLISH_AS)) {
      reportErrorForAnnotation(AngularCode.MISSING_PUBLISH_AS, []);
      isValid = false;
    }
    // selector
    AngularSelectorElement selector = null;
    if (!hasStringArgument(_SELECTOR)) {
      reportErrorForAnnotation(AngularCode.MISSING_SELECTOR, []);
      isValid = false;
    } else {
      SimpleStringLiteral selectorLiteral = getStringLiteral(_SELECTOR);
      selector = parseSelectorFromString(selectorLiteral);
      if (selector == null) {
        reportErrorForArgument(_SELECTOR, AngularCode.CANNOT_PARSE_SELECTOR, [selectorLiteral]);
        isValid = false;
      }
    }
    // create
    if (isValid) {
      String name = getStringArgument(_PUBLISH_AS);
      int nameOffset = getStringArgumentOffset(_PUBLISH_AS);
      AngularControllerElementImpl element = new AngularControllerElementImpl(name, nameOffset);
      element.selector = selector;
      _classToolkitObjects.add(element);
    }
  }

  void parseNgDirective() {
    bool isValid = true;
    // selector
    AngularSelectorElement selector = null;
    if (!hasStringArgument(_SELECTOR)) {
      reportErrorForAnnotation(AngularCode.MISSING_SELECTOR, []);
      isValid = false;
    } else {
      SimpleStringLiteral selectorLiteral = getStringLiteral(_SELECTOR);
      selector = parseSelectorFromString(selectorLiteral);
      if (selector == null) {
        reportErrorForArgument(_SELECTOR, AngularCode.CANNOT_PARSE_SELECTOR, [selectorLiteral]);
        isValid = false;
      }
    }
    // create
    if (isValid) {
      int offset = _annotation.offset;
      AngularDirectiveElementImpl element = new AngularDirectiveElementImpl(offset);
      element.selector = selector;
      element.properties = parseNgComponentProperties();
      _classToolkitObjects.add(element);
    }
  }

  void parseNgFilter() {
    bool isValid = true;
    // name
    if (!hasStringArgument(_NAME)) {
      reportErrorForAnnotation(AngularCode.MISSING_NAME, []);
      isValid = false;
    }
    // create
    if (isValid) {
      String name = getStringArgument(_NAME);
      int nameOffset = getStringArgumentOffset(_NAME);
      _classToolkitObjects.add(new AngularFilterElementImpl(name, nameOffset));
    }
  }

  List<AngularScopePropertyElement> parseScopeProperties() {
    List<AngularScopePropertyElement> properties = [];
    _classDeclaration.accept(new RecursiveAstVisitor_AngularCompilationUnitBuilder_parseScopeProperties(properties));
    return new List.from(properties);
  }

  /**
   * Create [AngularViewElement] for each valid <code>view('template.html')</code> invocation,
   * where <code>view</code> is <code>ViewFactory</code>.
   */
  void parseViews() {
    List<AngularViewElement> views = [];
    _unit.accept(new RecursiveAstVisitor_AngularCompilationUnitBuilder_parseViews(views));
    if (!views.isEmpty) {
      List<AngularViewElement> viewArray = new List.from(views);
      (_unit.element as CompilationUnitElementImpl).angularViews = viewArray;
    }
  }

  void reportErrorForAnnotation(ErrorCode errorCode, List<Object> arguments) {
    reportErrorForNode(errorCode, _annotation, arguments);
  }

  void reportErrorForArgument(String argumentName, ErrorCode errorCode, List<Object> arguments) {
    Expression argument = getArgument(argumentName);
    reportErrorForNode(errorCode, argument, arguments);
  }

  void reportErrorForNode(ErrorCode errorCode, AstNode node, List<Object> arguments) {
    int offset = node.offset;
    int length = node.length;
    reportErrorForOffset(errorCode, offset, length, arguments);
  }

  void reportErrorForOffset(ErrorCode errorCode, int offset, int length, List<Object> arguments) {
    _errorListener.onError(new AnalysisError.con2(_source, offset, length, errorCode, arguments));
  }
}

class RecursiveAstVisitor_AngularCompilationUnitBuilder_parseScopeProperties extends RecursiveAstVisitor<Object> {
  List<AngularScopePropertyElement> properties;

  RecursiveAstVisitor_AngularCompilationUnitBuilder_parseScopeProperties(this.properties) : super();

  Object visitAssignmentExpression(AssignmentExpression node) {
    addProperty(node);
    return super.visitAssignmentExpression(node);
  }

  void addProperty(AssignmentExpression node) {
    // try to find "name" in scope[name]
    SimpleStringLiteral nameNode = getNameNode(node.leftHandSide);
    if (nameNode == null) {
      return;
    }
    // prepare unique
    String name = nameNode.stringValue;
    if (hasPropertyWithName(name)) {
      return;
    }
    // do add property
    int nameOffset = nameNode.valueOffset;
    AngularScopePropertyElement property = new AngularScopePropertyElementImpl(name, nameOffset, node.rightHandSide.bestType);
    nameNode.toolkitElement = property;
    properties.add(property);
  }

  SimpleStringLiteral getNameNode(Expression node) {
    if (node is IndexExpression) {
      IndexExpression indexExpression = node;
      Expression target = indexExpression.target;
      Expression index = indexExpression.index;
      if (index is SimpleStringLiteral && isContext(target)) {
        return index;
      }
    }
    return null;
  }

  bool hasPropertyWithName(String name) {
    for (AngularScopePropertyElement property in properties) {
      if (property.name == name) {
        return true;
      }
    }
    return false;
  }

  bool isContext(Expression target) {
    if (target is PrefixedIdentifier) {
      PrefixedIdentifier prefixed = target;
      SimpleIdentifier prefix = prefixed.prefix;
      SimpleIdentifier identifier = prefixed.identifier;
      return (identifier.name == "context") && isScope(prefix);
    }
    return false;
  }

  bool isScope(Expression target) {
    if (target != null) {
      Type2 type = target.bestType;
      if (type is InterfaceType) {
        InterfaceType interfaceType = type;
        return interfaceType.name == "Scope";
      }
    }
    return false;
  }
}

class RecursiveAstVisitor_AngularCompilationUnitBuilder_parseViews extends RecursiveAstVisitor<Object> {
  List<AngularViewElement> views;

  RecursiveAstVisitor_AngularCompilationUnitBuilder_parseViews(this.views) : super();

  Object visitMethodInvocation(MethodInvocation node) {
    addView(node);
    return super.visitMethodInvocation(node);
  }

  void addView(MethodInvocation node) {
    // only one argument
    List<Expression> arguments = node.argumentList.arguments;
    if (arguments.length != 1) {
      return;
    }
    // String literal
    Expression argument = arguments[0];
    if (argument is! SimpleStringLiteral) {
      return;
    }
    SimpleStringLiteral literal = argument as SimpleStringLiteral;
    // just view('template')
    if (node.realTarget != null) {
      return;
    }
    // should be ViewFactory
    if (!isViewFactory(node.methodName)) {
      return;
    }
    // add AngularViewElement
    String templateUri = literal.stringValue;
    int templateUriOffset = literal.valueOffset;
    views.add(new AngularViewElementImpl(templateUri, templateUriOffset));
  }

  bool isViewFactory(Expression target) {
    if (target is SimpleIdentifier) {
      SimpleIdentifier identifier = target;
      Element element = identifier.staticElement;
      if (element is VariableElement) {
        VariableElement variable = element;
        Type2 type = variable.type;
        if (type is InterfaceType) {
          InterfaceType interfaceType = type;
          return interfaceType.name == "ViewFactory";
        }
      }
    }
    return false;
  }
}

/**
 * Instances of the class `CompilationUnitBuilder` build an element model for a single
 * compilation unit.
 */
class CompilationUnitBuilder {
  /**
   * Build the compilation unit element for the given source.
   *
   * @param source the source describing the compilation unit
   * @param unit the AST structure representing the compilation unit
   * @return the compilation unit element that was built
   * @throws AnalysisException if the analysis could not be performed
   */
  CompilationUnitElementImpl buildCompilationUnit(Source source, CompilationUnit unit) {
    TimeCounter_TimeCounterHandle timeCounter = PerformanceStatistics.resolve.start();
    try {
      if (unit == null) {
        return null;
      }
      ElementHolder holder = new ElementHolder();
      ElementBuilder builder = new ElementBuilder(holder);
      unit.accept(builder);
      CompilationUnitElementImpl element = new CompilationUnitElementImpl(source.shortName);
      element.accessors = holder.accessors;
      element.functions = holder.functions;
      element.source = source;
      element.typeAliases = holder.typeAliases;
      element.types = holder.types;
      element.topLevelVariables = holder.topLevelVariables;
      unit.element = element;
      return element;
    } finally {
      timeCounter.stop();
    }
  }
}

/**
 * Instances of the class `ElementBuilder` traverse an AST structure and build the element
 * model representing the AST structure.
 */
class ElementBuilder extends RecursiveAstVisitor<Object> {
  /**
   * The element holder associated with the element that is currently being built.
   */
  ElementHolder _currentHolder;

  /**
   * A flag indicating whether a variable declaration is in the context of a field declaration.
   */
  bool _inFieldContext = false;

  /**
   * A flag indicating whether a variable declaration is within the body of a method or function.
   */
  bool _inFunction = false;

  /**
   * A flag indicating whether the class currently being visited can be used as a mixin.
   */
  bool _isValidMixin = false;

  /**
   * A collection holding the function types defined in a class that need to have their type
   * arguments set to the types of the type parameters for the class, or `null` if we are not
   * currently processing nodes within a class.
   */
  List<FunctionTypeImpl> _functionTypesToFix = null;

  /**
   * A table mapping field names to field elements for the fields defined in the current class, or
   * `null` if we are not in the scope of a class.
   */
  Map<String, FieldElement> _fieldMap;

  /**
   * Initialize a newly created element builder to build the elements for a compilation unit.
   *
   * @param initialHolder the element holder associated with the compilation unit being built
   */
  ElementBuilder(ElementHolder initialHolder) {
    _currentHolder = initialHolder;
  }

  Object visitBlock(Block node) {
    bool wasInField = _inFieldContext;
    _inFieldContext = false;
    try {
      node.visitChildren(this);
    } finally {
      _inFieldContext = wasInField;
    }
    return null;
  }

  Object visitCatchClause(CatchClause node) {
    SimpleIdentifier exceptionParameter = node.exceptionParameter;
    if (exceptionParameter != null) {
      LocalVariableElementImpl exception = new LocalVariableElementImpl(exceptionParameter);
      _currentHolder.addLocalVariable(exception);
      exceptionParameter.staticElement = exception;
      SimpleIdentifier stackTraceParameter = node.stackTraceParameter;
      if (stackTraceParameter != null) {
        LocalVariableElementImpl stackTrace = new LocalVariableElementImpl(stackTraceParameter);
        _currentHolder.addLocalVariable(stackTrace);
        stackTraceParameter.staticElement = stackTrace;
      }
    }
    return super.visitCatchClause(node);
  }

  Object visitClassDeclaration(ClassDeclaration node) {
    ElementHolder holder = new ElementHolder();
    _isValidMixin = true;
    _functionTypesToFix = new List<FunctionTypeImpl>();
    //
    // Process field declarations before constructors and methods so that field formal parameters
    // can be correctly resolved to their fields.
    //
    ElementHolder previousHolder = _currentHolder;
    _currentHolder = holder;
    try {
      List<ClassMember> nonFields = new List<ClassMember>();
      node.visitChildren(new UnifyingAstVisitor_ElementBuilder_visitClassDeclaration(this, nonFields));
      buildFieldMap(holder.fieldsWithoutFlushing);
      int count = nonFields.length;
      for (int i = 0; i < count; i++) {
        nonFields[i].accept(this);
      }
    } finally {
      _currentHolder = previousHolder;
    }
    SimpleIdentifier className = node.name;
    ClassElementImpl element = new ClassElementImpl(className);
    List<TypeParameterElement> typeParameters = holder.typeParameters;
    List<Type2> typeArguments = createTypeParameterTypes(typeParameters);
    InterfaceTypeImpl interfaceType = new InterfaceTypeImpl.con1(element);
    interfaceType.typeArguments = typeArguments;
    element.type = interfaceType;
    List<ConstructorElement> constructors = holder.constructors;
    if (constructors.length == 0) {
      //
      // Create the default constructor.
      //
      constructors = createDefaultConstructors(interfaceType);
    }
    element.abstract = node.abstractKeyword != null;
    element.accessors = holder.accessors;
    element.constructors = constructors;
    element.fields = holder.fields;
    element.methods = holder.methods;
    element.typeParameters = typeParameters;
    element.validMixin = _isValidMixin;
    int functionTypeCount = _functionTypesToFix.length;
    for (int i = 0; i < functionTypeCount; i++) {
      _functionTypesToFix[i].typeArguments = typeArguments;
    }
    _functionTypesToFix = null;
    _currentHolder.addType(element);
    className.staticElement = element;
    _fieldMap = null;
    holder.validate();
    return null;
  }

  Object visitClassTypeAlias(ClassTypeAlias node) {
    ElementHolder holder = new ElementHolder();
    _functionTypesToFix = new List<FunctionTypeImpl>();
    visitChildren(holder, node);
    SimpleIdentifier className = node.name;
    ClassElementImpl element = new ClassElementImpl(className);
    element.abstract = node.abstractKeyword != null;
    element.typedef = true;
    List<TypeParameterElement> typeParameters = holder.typeParameters;
    element.typeParameters = typeParameters;
    List<Type2> typeArguments = createTypeParameterTypes(typeParameters);
    InterfaceTypeImpl interfaceType = new InterfaceTypeImpl.con1(element);
    interfaceType.typeArguments = typeArguments;
    element.type = interfaceType;
    // set default constructor
    element.constructors = createDefaultConstructors(interfaceType);
    for (FunctionTypeImpl functionType in _functionTypesToFix) {
      functionType.typeArguments = typeArguments;
    }
    _functionTypesToFix = null;
    _currentHolder.addType(element);
    className.staticElement = element;
    holder.validate();
    return null;
  }

  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    _isValidMixin = false;
    ElementHolder holder = new ElementHolder();
    bool wasInFunction = _inFunction;
    _inFunction = true;
    try {
      visitChildren(holder, node);
    } finally {
      _inFunction = wasInFunction;
    }
    SimpleIdentifier constructorName = node.name;
    ConstructorElementImpl element = new ConstructorElementImpl.con1(constructorName);
    if (node.factoryKeyword != null) {
      element.factory = true;
    }
    element.functions = holder.functions;
    element.labels = holder.labels;
    element.localVariables = holder.localVariables;
    element.parameters = holder.parameters;
    element.const2 = node.constKeyword != null;
    _currentHolder.addConstructor(element);
    node.element = element;
    if (constructorName == null) {
      Identifier returnType = node.returnType;
      if (returnType != null) {
        element.nameOffset = returnType.offset;
      }
    } else {
      constructorName.staticElement = element;
    }
    holder.validate();
    return null;
  }

  Object visitDeclaredIdentifier(DeclaredIdentifier node) {
    SimpleIdentifier variableName = node.identifier;
    sc.Token keyword = node.keyword;
    LocalVariableElementImpl element = new LocalVariableElementImpl(variableName);
    ForEachStatement statement = node.parent as ForEachStatement;
    int declarationEnd = node.offset + node.length;
    int statementEnd = statement.offset + statement.length;
    element.setVisibleRange(declarationEnd, statementEnd - declarationEnd - 1);
    element.const3 = matches(keyword, sc.Keyword.CONST);
    element.final2 = matches(keyword, sc.Keyword.FINAL);
    _currentHolder.addLocalVariable(element);
    variableName.staticElement = element;
    return super.visitDeclaredIdentifier(node);
  }

  Object visitDefaultFormalParameter(DefaultFormalParameter node) {
    ElementHolder holder = new ElementHolder();
    NormalFormalParameter normalParameter = node.parameter;
    SimpleIdentifier parameterName = normalParameter.identifier;
    ParameterElementImpl parameter;
    if (normalParameter is FieldFormalParameter) {
      parameter = new DefaultFieldFormalParameterElementImpl(parameterName);
      FieldElement field = _fieldMap == null ? null : _fieldMap[parameterName.name];
      if (field != null) {
        (parameter as DefaultFieldFormalParameterElementImpl).field = field;
      }
    } else {
      parameter = new DefaultParameterElementImpl(parameterName);
    }
    parameter.const3 = node.isConst;
    parameter.final2 = node.isFinal;
    parameter.parameterKind = node.kind;
    // set initializer, default value range
    Expression defaultValue = node.defaultValue;
    if (defaultValue != null) {
      visit(holder, defaultValue);
      FunctionElementImpl initializer = new FunctionElementImpl.con2(defaultValue.beginToken.offset);
      initializer.functions = holder.functions;
      initializer.labels = holder.labels;
      initializer.localVariables = holder.localVariables;
      initializer.parameters = holder.parameters;
      initializer.synthetic = true;
      parameter.initializer = initializer;
      parameter.setDefaultValueRange(defaultValue.offset, defaultValue.length);
    }
    // visible range
    setParameterVisibleRange(node, parameter);
    _currentHolder.addParameter(parameter);
    parameterName.staticElement = parameter;
    normalParameter.accept(this);
    holder.validate();
    return null;
  }

  Object visitFieldDeclaration(FieldDeclaration node) {
    bool wasInField = _inFieldContext;
    _inFieldContext = true;
    try {
      node.visitChildren(this);
    } finally {
      _inFieldContext = wasInField;
    }
    return null;
  }

  Object visitFieldFormalParameter(FieldFormalParameter node) {
    if (node.parent is! DefaultFormalParameter) {
      SimpleIdentifier parameterName = node.identifier;
      FieldElement field = _fieldMap == null ? null : _fieldMap[parameterName.name];
      FieldFormalParameterElementImpl parameter = new FieldFormalParameterElementImpl(parameterName);
      parameter.const3 = node.isConst;
      parameter.final2 = node.isFinal;
      parameter.parameterKind = node.kind;
      if (field != null) {
        parameter.field = field;
      }
      _currentHolder.addParameter(parameter);
      parameterName.staticElement = parameter;
    }
    //
    // The children of this parameter include any parameters defined on the type of this parameter.
    //
    ElementHolder holder = new ElementHolder();
    visitChildren(holder, node);
    (node.element as ParameterElementImpl).parameters = holder.parameters;
    holder.validate();
    return null;
  }

  Object visitFunctionDeclaration(FunctionDeclaration node) {
    FunctionExpression expression = node.functionExpression;
    if (expression != null) {
      ElementHolder holder = new ElementHolder();
      bool wasInFunction = _inFunction;
      _inFunction = true;
      try {
        visitChildren(holder, expression);
      } finally {
        _inFunction = wasInFunction;
      }
      sc.Token property = node.propertyKeyword;
      if (property == null) {
        SimpleIdentifier functionName = node.name;
        FunctionElementImpl element = new FunctionElementImpl.con1(functionName);
        element.functions = holder.functions;
        element.labels = holder.labels;
        element.localVariables = holder.localVariables;
        element.parameters = holder.parameters;
        if (_inFunction) {
          Block enclosingBlock = node.getAncestor((node) => node is Block);
          if (enclosingBlock != null) {
            int functionEnd = node.offset + node.length;
            int blockEnd = enclosingBlock.offset + enclosingBlock.length;
            element.setVisibleRange(functionEnd, blockEnd - functionEnd - 1);
          }
        }
        _currentHolder.addFunction(element);
        expression.element = element;
        functionName.staticElement = element;
      } else {
        SimpleIdentifier propertyNameNode = node.name;
        if (propertyNameNode == null) {
          // TODO(brianwilkerson) Report this internal error.
          return null;
        }
        String propertyName = propertyNameNode.name;
        TopLevelVariableElementImpl variable = _currentHolder.getTopLevelVariable(propertyName) as TopLevelVariableElementImpl;
        if (variable == null) {
          variable = new TopLevelVariableElementImpl.con2(node.name.name);
          variable.final2 = true;
          variable.synthetic = true;
          _currentHolder.addTopLevelVariable(variable);
        }
        if (matches(property, sc.Keyword.GET)) {
          PropertyAccessorElementImpl getter = new PropertyAccessorElementImpl.con1(propertyNameNode);
          getter.functions = holder.functions;
          getter.labels = holder.labels;
          getter.localVariables = holder.localVariables;
          getter.variable = variable;
          getter.getter = true;
          getter.static = true;
          variable.getter = getter;
          _currentHolder.addAccessor(getter);
          expression.element = getter;
          propertyNameNode.staticElement = getter;
        } else {
          PropertyAccessorElementImpl setter = new PropertyAccessorElementImpl.con1(propertyNameNode);
          setter.functions = holder.functions;
          setter.labels = holder.labels;
          setter.localVariables = holder.localVariables;
          setter.parameters = holder.parameters;
          setter.variable = variable;
          setter.setter = true;
          setter.static = true;
          variable.setter = setter;
          variable.final2 = false;
          _currentHolder.addAccessor(setter);
          expression.element = setter;
          propertyNameNode.staticElement = setter;
        }
      }
      holder.validate();
    }
    return null;
  }

  Object visitFunctionExpression(FunctionExpression node) {
    ElementHolder holder = new ElementHolder();
    bool wasInFunction = _inFunction;
    _inFunction = true;
    try {
      visitChildren(holder, node);
    } finally {
      _inFunction = wasInFunction;
    }
    FunctionElementImpl element = new FunctionElementImpl.con2(node.beginToken.offset);
    element.functions = holder.functions;
    element.labels = holder.labels;
    element.localVariables = holder.localVariables;
    element.parameters = holder.parameters;
    if (_inFunction) {
      Block enclosingBlock = node.getAncestor((node) => node is Block);
      if (enclosingBlock != null) {
        int functionEnd = node.offset + node.length;
        int blockEnd = enclosingBlock.offset + enclosingBlock.length;
        element.setVisibleRange(functionEnd, blockEnd - functionEnd - 1);
      }
    }
    FunctionTypeImpl type = new FunctionTypeImpl.con1(element);
    if (_functionTypesToFix != null) {
      _functionTypesToFix.add(type);
    }
    element.type = type;
    _currentHolder.addFunction(element);
    node.element = element;
    holder.validate();
    return null;
  }

  Object visitFunctionTypeAlias(FunctionTypeAlias node) {
    ElementHolder holder = new ElementHolder();
    visitChildren(holder, node);
    SimpleIdentifier aliasName = node.name;
    List<ParameterElement> parameters = holder.parameters;
    List<TypeParameterElement> typeParameters = holder.typeParameters;
    FunctionTypeAliasElementImpl element = new FunctionTypeAliasElementImpl(aliasName);
    element.parameters = parameters;
    element.typeParameters = typeParameters;
    FunctionTypeImpl type = new FunctionTypeImpl.con2(element);
    type.typeArguments = createTypeParameterTypes(typeParameters);
    element.type = type;
    _currentHolder.addTypeAlias(element);
    aliasName.staticElement = element;
    holder.validate();
    return null;
  }

  Object visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    if (node.parent is! DefaultFormalParameter) {
      SimpleIdentifier parameterName = node.identifier;
      ParameterElementImpl parameter = new ParameterElementImpl.con1(parameterName);
      parameter.parameterKind = node.kind;
      setParameterVisibleRange(node, parameter);
      _currentHolder.addParameter(parameter);
      parameterName.staticElement = parameter;
    }
    //
    // The children of this parameter include any parameters defined on the type of this parameter.
    //
    ElementHolder holder = new ElementHolder();
    visitChildren(holder, node);
    (node.element as ParameterElementImpl).parameters = holder.parameters;
    holder.validate();
    return null;
  }

  Object visitLabeledStatement(LabeledStatement node) {
    bool onSwitchStatement = node.statement is SwitchStatement;
    for (Label label in node.labels) {
      SimpleIdentifier labelName = label.label;
      LabelElementImpl element = new LabelElementImpl(labelName, onSwitchStatement, false);
      _currentHolder.addLabel(element);
      labelName.staticElement = element;
    }
    return super.visitLabeledStatement(node);
  }

  Object visitMethodDeclaration(MethodDeclaration node) {
    ElementHolder holder = new ElementHolder();
    bool wasInFunction = _inFunction;
    _inFunction = true;
    try {
      visitChildren(holder, node);
    } finally {
      _inFunction = wasInFunction;
    }
    bool isStatic = node.isStatic;
    sc.Token property = node.propertyKeyword;
    if (property == null) {
      SimpleIdentifier methodName = node.name;
      String nameOfMethod = methodName.name;
      if (nameOfMethod == sc.TokenType.MINUS.lexeme && node.parameters.parameters.length == 0) {
        nameOfMethod = "unary-";
      }
      MethodElementImpl element = new MethodElementImpl.con2(nameOfMethod, methodName.offset);
      element.abstract = node.isAbstract;
      element.functions = holder.functions;
      element.labels = holder.labels;
      element.localVariables = holder.localVariables;
      element.parameters = holder.parameters;
      element.static = isStatic;
      _currentHolder.addMethod(element);
      methodName.staticElement = element;
    } else {
      SimpleIdentifier propertyNameNode = node.name;
      String propertyName = propertyNameNode.name;
      FieldElementImpl field = _currentHolder.getField(propertyName) as FieldElementImpl;
      if (field == null) {
        field = new FieldElementImpl.con2(node.name.name);
        field.final2 = true;
        field.static = isStatic;
        field.synthetic = true;
        _currentHolder.addField(field);
      }
      if (matches(property, sc.Keyword.GET)) {
        PropertyAccessorElementImpl getter = new PropertyAccessorElementImpl.con1(propertyNameNode);
        getter.functions = holder.functions;
        getter.labels = holder.labels;
        getter.localVariables = holder.localVariables;
        getter.variable = field;
        getter.abstract = node.body is EmptyFunctionBody && node.externalKeyword == null;
        getter.getter = true;
        getter.static = isStatic;
        field.getter = getter;
        _currentHolder.addAccessor(getter);
        propertyNameNode.staticElement = getter;
      } else {
        PropertyAccessorElementImpl setter = new PropertyAccessorElementImpl.con1(propertyNameNode);
        setter.functions = holder.functions;
        setter.labels = holder.labels;
        setter.localVariables = holder.localVariables;
        setter.parameters = holder.parameters;
        setter.variable = field;
        setter.abstract = node.body is EmptyFunctionBody && !matches(node.externalKeyword, sc.Keyword.EXTERNAL);
        setter.setter = true;
        setter.static = isStatic;
        field.setter = setter;
        field.final2 = false;
        _currentHolder.addAccessor(setter);
        propertyNameNode.staticElement = setter;
      }
    }
    holder.validate();
    return null;
  }

  Object visitSimpleFormalParameter(SimpleFormalParameter node) {
    if (node.parent is! DefaultFormalParameter) {
      SimpleIdentifier parameterName = node.identifier;
      ParameterElementImpl parameter = new ParameterElementImpl.con1(parameterName);
      parameter.const3 = node.isConst;
      parameter.final2 = node.isFinal;
      parameter.parameterKind = node.kind;
      setParameterVisibleRange(node, parameter);
      _currentHolder.addParameter(parameter);
      parameterName.staticElement = parameter;
    }
    return super.visitSimpleFormalParameter(node);
  }

  Object visitSuperExpression(SuperExpression node) {
    _isValidMixin = false;
    return super.visitSuperExpression(node);
  }

  Object visitSwitchCase(SwitchCase node) {
    for (Label label in node.labels) {
      SimpleIdentifier labelName = label.label;
      LabelElementImpl element = new LabelElementImpl(labelName, false, true);
      _currentHolder.addLabel(element);
      labelName.staticElement = element;
    }
    return super.visitSwitchCase(node);
  }

  Object visitSwitchDefault(SwitchDefault node) {
    for (Label label in node.labels) {
      SimpleIdentifier labelName = label.label;
      LabelElementImpl element = new LabelElementImpl(labelName, false, true);
      _currentHolder.addLabel(element);
      labelName.staticElement = element;
    }
    return super.visitSwitchDefault(node);
  }

  Object visitTypeParameter(TypeParameter node) {
    SimpleIdentifier parameterName = node.name;
    TypeParameterElementImpl typeParameter = new TypeParameterElementImpl(parameterName);
    TypeParameterTypeImpl typeParameterType = new TypeParameterTypeImpl(typeParameter);
    typeParameter.type = typeParameterType;
    _currentHolder.addTypeParameter(typeParameter);
    parameterName.staticElement = typeParameter;
    return super.visitTypeParameter(node);
  }

  Object visitVariableDeclaration(VariableDeclaration node) {
    sc.Token keyword = (node.parent as VariableDeclarationList).keyword;
    bool isConst = matches(keyword, sc.Keyword.CONST);
    bool isFinal = matches(keyword, sc.Keyword.FINAL);
    bool hasInitializer = node.initializer != null;
    VariableElementImpl element;
    if (_inFieldContext) {
      SimpleIdentifier fieldName = node.name;
      FieldElementImpl field;
      if (isConst && hasInitializer) {
        field = new ConstFieldElementImpl(fieldName);
      } else {
        field = new FieldElementImpl.con1(fieldName);
      }
      element = field;
      _currentHolder.addField(field);
      fieldName.staticElement = field;
    } else if (_inFunction) {
      SimpleIdentifier variableName = node.name;
      LocalVariableElementImpl variable;
      if (isConst && hasInitializer) {
        variable = new ConstLocalVariableElementImpl(variableName);
      } else {
        variable = new LocalVariableElementImpl(variableName);
      }
      element = variable;
      Block enclosingBlock = node.getAncestor((node) => node is Block);
      int functionEnd = node.offset + node.length;
      int blockEnd = enclosingBlock.offset + enclosingBlock.length;
      // TODO(brianwilkerson) This isn't right for variables declared in a for loop.
      variable.setVisibleRange(functionEnd, blockEnd - functionEnd - 1);
      _currentHolder.addLocalVariable(variable);
      variableName.staticElement = element;
    } else {
      SimpleIdentifier variableName = node.name;
      TopLevelVariableElementImpl variable;
      if (isConst && hasInitializer) {
        variable = new ConstTopLevelVariableElementImpl(variableName);
      } else {
        variable = new TopLevelVariableElementImpl.con1(variableName);
      }
      element = variable;
      _currentHolder.addTopLevelVariable(variable);
      variableName.staticElement = element;
    }
    element.const3 = isConst;
    element.final2 = isFinal;
    if (hasInitializer) {
      ElementHolder holder = new ElementHolder();
      bool wasInFieldContext = _inFieldContext;
      _inFieldContext = false;
      try {
        visit(holder, node.initializer);
      } finally {
        _inFieldContext = wasInFieldContext;
      }
      FunctionElementImpl initializer = new FunctionElementImpl.con2(node.initializer.beginToken.offset);
      initializer.functions = holder.functions;
      initializer.labels = holder.labels;
      initializer.localVariables = holder.localVariables;
      initializer.synthetic = true;
      element.initializer = initializer;
      holder.validate();
    }
    if (element is PropertyInducingElementImpl) {
      PropertyInducingElementImpl variable = element as PropertyInducingElementImpl;
      if (_inFieldContext) {
        (variable as FieldElementImpl).static = matches((node.parent.parent as FieldDeclaration).staticKeyword, sc.Keyword.STATIC);
      }
      PropertyAccessorElementImpl getter = new PropertyAccessorElementImpl.con2(variable);
      getter.getter = true;
      getter.static = variable.isStatic;
      _currentHolder.addAccessor(getter);
      variable.getter = getter;
      if (!isFinal) {
        PropertyAccessorElementImpl setter = new PropertyAccessorElementImpl.con2(variable);
        setter.setter = true;
        setter.static = variable.isStatic;
        ParameterElementImpl parameter = new ParameterElementImpl.con2("_${variable.name}", variable.nameOffset);
        parameter.synthetic = true;
        parameter.parameterKind = ParameterKind.REQUIRED;
        setter.parameters = <ParameterElement> [parameter];
        _currentHolder.addAccessor(setter);
        variable.setter = setter;
      }
    }
    return null;
  }

  /**
   * Build the table mapping field names to field elements for the fields defined in the current
   * class.
   *
   * @param fields the field elements defined in the current class
   */
  void buildFieldMap(List<FieldElement> fields) {
    _fieldMap = new Map<String, FieldElement>();
    int count = fields.length;
    for (int i = 0; i < count; i++) {
      FieldElement field = fields[i];
      _fieldMap[field.name] = field;
    }
  }

  /**
   * Creates the [ConstructorElement]s array with the single default constructor element.
   *
   * @param interfaceType the interface type for which to create a default constructor
   * @return the [ConstructorElement]s array with the single default constructor element
   */
  List<ConstructorElement> createDefaultConstructors(InterfaceTypeImpl interfaceType) {
    ConstructorElementImpl constructor = new ConstructorElementImpl.con1(null);
    constructor.synthetic = true;
    constructor.returnType = interfaceType;
    FunctionTypeImpl type = new FunctionTypeImpl.con1(constructor);
    _functionTypesToFix.add(type);
    constructor.type = type;
    return <ConstructorElement> [constructor];
  }

  /**
   * Create the types associated with the given type parameters, setting the type of each type
   * parameter, and return an array of types corresponding to the given parameters.
   *
   * @param typeParameters the type parameters for which types are to be created
   * @return an array of types corresponding to the given parameters
   */
  List<Type2> createTypeParameterTypes(List<TypeParameterElement> typeParameters) {
    int typeParameterCount = typeParameters.length;
    List<Type2> typeArguments = new List<Type2>(typeParameterCount);
    for (int i = 0; i < typeParameterCount; i++) {
      TypeParameterElementImpl typeParameter = typeParameters[i] as TypeParameterElementImpl;
      TypeParameterTypeImpl typeParameterType = new TypeParameterTypeImpl(typeParameter);
      typeParameter.type = typeParameterType;
      typeArguments[i] = typeParameterType;
    }
    return typeArguments;
  }

  /**
   * Return the body of the function that contains the given parameter, or `null` if no
   * function body could be found.
   *
   * @param node the parameter contained in the function whose body is to be returned
   * @return the body of the function that contains the given parameter
   */
  FunctionBody getFunctionBody(FormalParameter node) {
    AstNode parent = node.parent;
    while (parent != null) {
      if (parent is ConstructorDeclaration) {
        return (parent as ConstructorDeclaration).body;
      } else if (parent is FunctionExpression) {
        return (parent as FunctionExpression).body;
      } else if (parent is MethodDeclaration) {
        return (parent as MethodDeclaration).body;
      }
      parent = parent.parent;
    }
    return null;
  }

  /**
   * Return `true` if the given token is a token for the given keyword.
   *
   * @param token the token being tested
   * @param keyword the keyword being tested for
   * @return `true` if the given token is a token for the given keyword
   */
  bool matches(sc.Token token, sc.Keyword keyword) => token != null && identical(token.type, sc.TokenType.KEYWORD) && identical((token as sc.KeywordToken).keyword, keyword);

  /**
   * Sets the visible source range for formal parameter.
   */
  void setParameterVisibleRange(FormalParameter node, ParameterElementImpl element) {
    FunctionBody body = getFunctionBody(node);
    if (body != null) {
      element.setVisibleRange(body.offset, body.length);
    }
  }

  /**
   * Make the given holder be the current holder while visiting the given node.
   *
   * @param holder the holder that will gather elements that are built while visiting the children
   * @param node the node to be visited
   */
  void visit(ElementHolder holder, AstNode node) {
    if (node != null) {
      ElementHolder previousHolder = _currentHolder;
      _currentHolder = holder;
      try {
        node.accept(this);
      } finally {
        _currentHolder = previousHolder;
      }
    }
  }

  /**
   * Make the given holder be the current holder while visiting the children of the given node.
   *
   * @param holder the holder that will gather elements that are built while visiting the children
   * @param node the node whose children are to be visited
   */
  void visitChildren(ElementHolder holder, AstNode node) {
    if (node != null) {
      ElementHolder previousHolder = _currentHolder;
      _currentHolder = holder;
      try {
        node.visitChildren(this);
      } finally {
        _currentHolder = previousHolder;
      }
    }
  }
}

class UnifyingAstVisitor_ElementBuilder_visitClassDeclaration extends UnifyingAstVisitor<Object> {
  final ElementBuilder ElementBuilder_this;

  List<ClassMember> nonFields;

  UnifyingAstVisitor_ElementBuilder_visitClassDeclaration(this.ElementBuilder_this, this.nonFields) : super();

  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    nonFields.add(node);
    return null;
  }

  Object visitMethodDeclaration(MethodDeclaration node) {
    nonFields.add(node);
    return null;
  }

  Object visitNode(AstNode node) => node.accept(ElementBuilder_this);
}

/**
 * Instances of the class `ElementHolder` hold on to elements created while traversing an AST
 * structure so that they can be accessed when creating their enclosing element.
 */
class ElementHolder {
  List<PropertyAccessorElement> _accessors;

  List<ConstructorElement> _constructors;

  List<FieldElement> _fields;

  List<FunctionElement> _functions;

  List<LabelElement> _labels;

  List<VariableElement> _localVariables;

  List<MethodElement> _methods;

  List<ParameterElement> _parameters;

  List<TopLevelVariableElement> _topLevelVariables;

  List<ClassElement> _types;

  List<FunctionTypeAliasElement> _typeAliases;

  List<TypeParameterElement> _typeParameters;

  void addAccessor(PropertyAccessorElement element) {
    if (_accessors == null) {
      _accessors = new List<PropertyAccessorElement>();
    }
    _accessors.add(element);
  }

  void addConstructor(ConstructorElement element) {
    if (_constructors == null) {
      _constructors = new List<ConstructorElement>();
    }
    _constructors.add(element);
  }

  void addField(FieldElement element) {
    if (_fields == null) {
      _fields = new List<FieldElement>();
    }
    _fields.add(element);
  }

  void addFunction(FunctionElement element) {
    if (_functions == null) {
      _functions = new List<FunctionElement>();
    }
    _functions.add(element);
  }

  void addLabel(LabelElement element) {
    if (_labels == null) {
      _labels = new List<LabelElement>();
    }
    _labels.add(element);
  }

  void addLocalVariable(LocalVariableElement element) {
    if (_localVariables == null) {
      _localVariables = new List<VariableElement>();
    }
    _localVariables.add(element);
  }

  void addMethod(MethodElement element) {
    if (_methods == null) {
      _methods = new List<MethodElement>();
    }
    _methods.add(element);
  }

  void addParameter(ParameterElement element) {
    if (_parameters == null) {
      _parameters = new List<ParameterElement>();
    }
    _parameters.add(element);
  }

  void addTopLevelVariable(TopLevelVariableElement element) {
    if (_topLevelVariables == null) {
      _topLevelVariables = new List<TopLevelVariableElement>();
    }
    _topLevelVariables.add(element);
  }

  void addType(ClassElement element) {
    if (_types == null) {
      _types = new List<ClassElement>();
    }
    _types.add(element);
  }

  void addTypeAlias(FunctionTypeAliasElement element) {
    if (_typeAliases == null) {
      _typeAliases = new List<FunctionTypeAliasElement>();
    }
    _typeAliases.add(element);
  }

  void addTypeParameter(TypeParameterElement element) {
    if (_typeParameters == null) {
      _typeParameters = new List<TypeParameterElement>();
    }
    _typeParameters.add(element);
  }

  List<PropertyAccessorElement> get accessors {
    if (_accessors == null) {
      return PropertyAccessorElementImpl.EMPTY_ARRAY;
    }
    List<PropertyAccessorElement> result = new List.from(_accessors);
    _accessors = null;
    return result;
  }

  List<ConstructorElement> get constructors {
    if (_constructors == null) {
      return ConstructorElementImpl.EMPTY_ARRAY;
    }
    List<ConstructorElement> result = new List.from(_constructors);
    _constructors = null;
    return result;
  }

  FieldElement getField(String fieldName) {
    if (_fields == null) {
      return null;
    }
    for (FieldElement field in _fields) {
      if (field.name == fieldName) {
        return field;
      }
    }
    return null;
  }

  List<FieldElement> get fields {
    if (_fields == null) {
      return FieldElementImpl.EMPTY_ARRAY;
    }
    List<FieldElement> result = new List.from(_fields);
    _fields = null;
    return result;
  }

  List<FieldElement> get fieldsWithoutFlushing {
    if (_fields == null) {
      return FieldElementImpl.EMPTY_ARRAY;
    }
    List<FieldElement> result = new List.from(_fields);
    return result;
  }

  List<FunctionElement> get functions {
    if (_functions == null) {
      return FunctionElementImpl.EMPTY_ARRAY;
    }
    List<FunctionElement> result = new List.from(_functions);
    _functions = null;
    return result;
  }

  List<LabelElement> get labels {
    if (_labels == null) {
      return LabelElementImpl.EMPTY_ARRAY;
    }
    List<LabelElement> result = new List.from(_labels);
    _labels = null;
    return result;
  }

  List<LocalVariableElement> get localVariables {
    if (_localVariables == null) {
      return LocalVariableElementImpl.EMPTY_ARRAY;
    }
    List<LocalVariableElement> result = new List.from(_localVariables);
    _localVariables = null;
    return result;
  }

  List<MethodElement> get methods {
    if (_methods == null) {
      return MethodElementImpl.EMPTY_ARRAY;
    }
    List<MethodElement> result = new List.from(_methods);
    _methods = null;
    return result;
  }

  List<ParameterElement> get parameters {
    if (_parameters == null) {
      return ParameterElementImpl.EMPTY_ARRAY;
    }
    List<ParameterElement> result = new List.from(_parameters);
    _parameters = null;
    return result;
  }

  TopLevelVariableElement getTopLevelVariable(String variableName) {
    if (_topLevelVariables == null) {
      return null;
    }
    for (TopLevelVariableElement variable in _topLevelVariables) {
      if (variable.name == variableName) {
        return variable;
      }
    }
    return null;
  }

  List<TopLevelVariableElement> get topLevelVariables {
    if (_topLevelVariables == null) {
      return TopLevelVariableElementImpl.EMPTY_ARRAY;
    }
    List<TopLevelVariableElement> result = new List.from(_topLevelVariables);
    _topLevelVariables = null;
    return result;
  }

  List<FunctionTypeAliasElement> get typeAliases {
    if (_typeAliases == null) {
      return FunctionTypeAliasElementImpl.EMPTY_ARRAY;
    }
    List<FunctionTypeAliasElement> result = new List.from(_typeAliases);
    _typeAliases = null;
    return result;
  }

  List<TypeParameterElement> get typeParameters {
    if (_typeParameters == null) {
      return TypeParameterElementImpl.EMPTY_ARRAY;
    }
    List<TypeParameterElement> result = new List.from(_typeParameters);
    _typeParameters = null;
    return result;
  }

  List<ClassElement> get types {
    if (_types == null) {
      return ClassElementImpl.EMPTY_ARRAY;
    }
    List<ClassElement> result = new List.from(_types);
    _types = null;
    return result;
  }

  void validate() {
    JavaStringBuilder builder = new JavaStringBuilder();
    if (_accessors != null) {
      builder.append(_accessors.length);
      builder.append(" accessors");
    }
    if (_constructors != null) {
      if (builder.length > 0) {
        builder.append("; ");
      }
      builder.append(_constructors.length);
      builder.append(" constructors");
    }
    if (_fields != null) {
      if (builder.length > 0) {
        builder.append("; ");
      }
      builder.append(_fields.length);
      builder.append(" fields");
    }
    if (_functions != null) {
      if (builder.length > 0) {
        builder.append("; ");
      }
      builder.append(_functions.length);
      builder.append(" functions");
    }
    if (_labels != null) {
      if (builder.length > 0) {
        builder.append("; ");
      }
      builder.append(_labels.length);
      builder.append(" labels");
    }
    if (_localVariables != null) {
      if (builder.length > 0) {
        builder.append("; ");
      }
      builder.append(_localVariables.length);
      builder.append(" local variables");
    }
    if (_methods != null) {
      if (builder.length > 0) {
        builder.append("; ");
      }
      builder.append(_methods.length);
      builder.append(" methods");
    }
    if (_parameters != null) {
      if (builder.length > 0) {
        builder.append("; ");
      }
      builder.append(_parameters.length);
      builder.append(" parameters");
    }
    if (_topLevelVariables != null) {
      if (builder.length > 0) {
        builder.append("; ");
      }
      builder.append(_topLevelVariables.length);
      builder.append(" top-level variables");
    }
    if (_types != null) {
      if (builder.length > 0) {
        builder.append("; ");
      }
      builder.append(_types.length);
      builder.append(" types");
    }
    if (_typeAliases != null) {
      if (builder.length > 0) {
        builder.append("; ");
      }
      builder.append(_typeAliases.length);
      builder.append(" type aliases");
    }
    if (_typeParameters != null) {
      if (builder.length > 0) {
        builder.append("; ");
      }
      builder.append(_typeParameters.length);
      builder.append(" type parameters");
    }
    if (builder.length > 0) {
      AnalysisEngine.instance.logger.logError("Failed to capture elements: ${builder.toString()}");
    }
  }
}

/**
 * Instances of the class `HtmlUnitBuilder` build an element model for a single HTML unit.
 */
class HtmlUnitBuilder implements ht.XmlVisitor<Object> {
  static String _SRC = "src";

  /**
   * The analysis context in which the element model will be built.
   */
  InternalAnalysisContext _context;

  /**
   * The error listener to which errors will be reported.
   */
  RecordingErrorListener _errorListener;

  /**
   * The modification time of the source for which an element is being built.
   */
  int _modificationStamp = 0;

  /**
   * The HTML element being built.
   */
  HtmlElementImpl _htmlElement;

  /**
   * The elements in the path from the HTML unit to the current tag node.
   */
  List<ht.XmlTagNode> _parentNodes;

  /**
   * The script elements being built.
   */
  List<HtmlScriptElement> _scripts;

  /**
   * A set of the libraries that were resolved while resolving the HTML unit.
   */
  Set<Library> _resolvedLibraries = new Set<Library>();

  /**
   * Initialize a newly created HTML unit builder.
   *
   * @param context the analysis context in which the element model will be built
   */
  HtmlUnitBuilder(InternalAnalysisContext context) {
    this._context = context;
    this._errorListener = new RecordingErrorListener();
  }

  /**
   * Build the HTML element for the given source.
   *
   * @param source the source describing the compilation unit
   * @return the HTML element that was built
   * @throws AnalysisException if the analysis could not be performed
   */
  HtmlElementImpl buildHtmlElement(Source source) => buildHtmlElement2(source, _context.getModificationStamp(source), _context.parseHtmlUnit(source));

  /**
   * Build the HTML element for the given source.
   *
   * @param source the source describing the compilation unit
   * @param modificationStamp the modification time of the source for which an element is being
   *          built
   * @param unit the AST structure representing the HTML
   * @throws AnalysisException if the analysis could not be performed
   */
  HtmlElementImpl buildHtmlElement2(Source source, int modificationStamp, ht.HtmlUnit unit) {
    this._modificationStamp = modificationStamp;
    HtmlElementImpl result = new HtmlElementImpl(_context, source.shortName);
    result.source = source;
    _htmlElement = result;
    unit.accept(this);
    _htmlElement = null;
    unit.element = result;
    return result;
  }

  /**
   * Return the listener to which analysis errors will be reported.
   *
   * @return the listener to which analysis errors will be reported
   */
  RecordingErrorListener get errorListener => _errorListener;

  /**
   * Return an array containing information about all of the libraries that were resolved.
   *
   * @return an array containing the libraries that were resolved
   */
  Set<Library> get resolvedLibraries => _resolvedLibraries;

  Object visitHtmlScriptTagNode(ht.HtmlScriptTagNode node) {
    if (_parentNodes.contains(node)) {
      return reportCircularity(node);
    }
    _parentNodes.add(node);
    try {
      Source htmlSource = _htmlElement.source;
      ht.XmlAttributeNode scriptAttribute = getScriptSourcePath(node);
      String scriptSourcePath = scriptAttribute == null ? null : scriptAttribute.text;
      if (identical(node.attributeEnd.type, ht.TokenType.GT) && scriptSourcePath == null) {
        EmbeddedHtmlScriptElementImpl script = new EmbeddedHtmlScriptElementImpl(node);
        try {
          LibraryResolver resolver = new LibraryResolver(_context);
          LibraryElementImpl library = resolver.resolveEmbeddedLibrary(htmlSource, _modificationStamp, node.script, true) as LibraryElementImpl;
          script.scriptLibrary = library;
          _resolvedLibraries.addAll(resolver.resolvedLibraries);
          _errorListener.addAll(resolver.errorListener);
        } on AnalysisException catch (exception) {
          //TODO (danrubel): Handle or forward the exception
          AnalysisEngine.instance.logger.logError2("Could not resolve script tag", exception);
        }
        node.scriptElement = script;
        _scripts.add(script);
      } else {
        ExternalHtmlScriptElementImpl script = new ExternalHtmlScriptElementImpl(node);
        if (scriptSourcePath != null) {
          try {
            scriptSourcePath = Uri.encodeFull(scriptSourcePath);
            // Force an exception to be thrown if the URI is invalid so that we can report the
            // problem.
            parseUriWithException(scriptSourcePath);
            Source scriptSource = _context.sourceFactory.resolveUri(htmlSource, scriptSourcePath);
            script.scriptSource = scriptSource;
            if (!_context.exists(scriptSource)) {
              reportValueError(HtmlWarningCode.URI_DOES_NOT_EXIST, scriptAttribute, [scriptSourcePath]);
            }
          } on URISyntaxException catch (exception) {
            reportValueError(HtmlWarningCode.INVALID_URI, scriptAttribute, [scriptSourcePath]);
          }
        }
        node.scriptElement = script;
        _scripts.add(script);
      }
    } finally {
      _parentNodes.remove(node);
    }
    return null;
  }

  Object visitHtmlUnit(ht.HtmlUnit node) {
    _parentNodes = new List<ht.XmlTagNode>();
    _scripts = new List<HtmlScriptElement>();
    try {
      node.visitChildren(this);
      _htmlElement.scripts = new List.from(_scripts);
    } finally {
      _scripts = null;
      _parentNodes = null;
    }
    return null;
  }

  Object visitXmlAttributeNode(ht.XmlAttributeNode node) => null;

  Object visitXmlTagNode(ht.XmlTagNode node) {
    if (_parentNodes.contains(node)) {
      return reportCircularity(node);
    }
    _parentNodes.add(node);
    try {
      node.visitChildren(this);
    } finally {
      _parentNodes.remove(node);
    }
    return null;
  }

  /**
   * Return the first source attribute for the given tag node, or `null` if it does not exist.
   *
   * @param node the node containing attributes
   * @return the source attribute contained in the given tag
   */
  ht.XmlAttributeNode getScriptSourcePath(ht.XmlTagNode node) {
    for (ht.XmlAttributeNode attribute in node.attributes) {
      if (attribute.name == _SRC) {
        return attribute;
      }
    }
    return null;
  }

  Object reportCircularity(ht.XmlTagNode node) {
    //
    // This should not be possible, but we have an error report that suggests that it happened at
    // least once. This code will guard against infinite recursion and might help us identify the
    // cause of the issue.
    //
    JavaStringBuilder builder = new JavaStringBuilder();
    builder.append("Found circularity in XML nodes: ");
    bool first = true;
    for (ht.XmlTagNode pathNode in _parentNodes) {
      if (first) {
        first = false;
      } else {
        builder.append(", ");
      }
      String tagName = pathNode.tag;
      if (identical(pathNode, node)) {
        builder.append("*");
        builder.append(tagName);
        builder.append("*");
      } else {
        builder.append(tagName);
      }
    }
    AnalysisEngine.instance.logger.logError(builder.toString());
    return null;
  }

  /**
   * Report an error with the given error code at the given location. Use the given arguments to
   * compose the error message.
   *
   * @param errorCode the error code of the error to be reported
   * @param offset the offset of the first character to be highlighted
   * @param length the number of characters to be highlighted
   * @param arguments the arguments used to compose the error message
   */
  void reportErrorForOffset(ErrorCode errorCode, int offset, int length, List<Object> arguments) {
    _errorListener.onError(new AnalysisError.con2(_htmlElement.source, offset, length, errorCode, arguments));
  }

  /**
   * Report an error with the given error code at the location of the value of the given attribute.
   * Use the given arguments to compose the error message.
   *
   * @param errorCode the error code of the error to be reported
   * @param offset the offset of the first character to be highlighted
   * @param length the number of characters to be highlighted
   * @param arguments the arguments used to compose the error message
   */
  void reportValueError(ErrorCode errorCode, ht.XmlAttributeNode attribute, List<Object> arguments) {
    int offset = attribute.valueToken.offset + 1;
    int length = attribute.valueToken.length - 2;
    reportErrorForOffset(errorCode, offset, length, arguments);
  }
}

/**
 * Instances of the class `BestPracticesVerifier` traverse an AST structure looking for
 * violations of Dart best practices.
 */
class BestPracticesVerifier extends RecursiveAstVisitor<Object> {
  static String _GETTER = "getter";

  static String _HASHCODE_GETTER_NAME = "hashCode";

  static String _METHOD = "method";

  static String _NULL_TYPE_NAME = "Null";

  static String _SETTER = "setter";

  static String _TO_INT_METHOD_NAME = "toInt";

  /**
   * Given a parenthesized expression, this returns the parent (or recursively grand-parent) of the
   * expression that is a parenthesized expression, but whose parent is not a parenthesized
   * expression.
   *
   * For example given the code `(((e)))`: `(e) -> (((e)))`.
   *
   * @param parenthesizedExpression some expression whose parent is a parenthesized expression
   * @return the first parent or grand-parent that is a parenthesized expression, that does not have
   *         a parenthesized expression parent
   */
  static ParenthesizedExpression wrapParenthesizedExpression(ParenthesizedExpression parenthesizedExpression) {
    if (parenthesizedExpression.parent is ParenthesizedExpression) {
      return wrapParenthesizedExpression(parenthesizedExpression.parent as ParenthesizedExpression);
    }
    return parenthesizedExpression;
  }

  /**
   * The class containing the AST nodes being visited, or `null` if we are not in the scope of
   * a class.
   */
  ClassElement _enclosingClass;

  /**
   * The error reporter by which errors will be reported.
   */
  ErrorReporter _errorReporter;

  /**
   * Create a new instance of the [BestPracticesVerifier].
   *
   * @param errorReporter the error reporter
   */
  BestPracticesVerifier(ErrorReporter errorReporter) {
    this._errorReporter = errorReporter;
  }

  Object visitAsExpression(AsExpression node) {
    checkForUnnecessaryCast(node);
    return super.visitAsExpression(node);
  }

  Object visitAssignmentExpression(AssignmentExpression node) {
    sc.TokenType operatorType = node.operator.type;
    if (operatorType != sc.TokenType.EQ) {
      checkForDeprecatedMemberUse(node.bestElement, node);
    } else {
      checkForUseOfVoidResult(node.rightHandSide);
    }
    return super.visitAssignmentExpression(node);
  }

  Object visitBinaryExpression(BinaryExpression node) {
    checkForDivisionOptimizationHint(node);
    checkForDeprecatedMemberUse(node.bestElement, node);
    return super.visitBinaryExpression(node);
  }

  Object visitClassDeclaration(ClassDeclaration node) {
    ClassElement outerClass = _enclosingClass;
    try {
      _enclosingClass = node.element;
      // Commented out until we decide that we want this hint in the analyzer
      //    checkForOverrideEqualsButNotHashCode(node);
      return super.visitClassDeclaration(node);
    } finally {
      _enclosingClass = outerClass;
    }
  }

  Object visitExportDirective(ExportDirective node) {
    checkForDeprecatedMemberUse(node.uriElement, node);
    return super.visitExportDirective(node);
  }

  Object visitFunctionDeclaration(FunctionDeclaration node) {
    checkForMissingReturn(node.returnType, node.functionExpression.body);
    return super.visitFunctionDeclaration(node);
  }

  Object visitImportDirective(ImportDirective node) {
    checkForDeprecatedMemberUse(node.uriElement, node);
    return super.visitImportDirective(node);
  }

  Object visitIndexExpression(IndexExpression node) {
    checkForDeprecatedMemberUse(node.bestElement, node);
    return super.visitIndexExpression(node);
  }

  Object visitInstanceCreationExpression(InstanceCreationExpression node) {
    checkForDeprecatedMemberUse(node.staticElement, node);
    return super.visitInstanceCreationExpression(node);
  }

  Object visitIsExpression(IsExpression node) {
    checkAllTypeChecks(node);
    return super.visitIsExpression(node);
  }

  Object visitMethodDeclaration(MethodDeclaration node) {
    // This was determined to not be a good hint, see: dartbug.com/16029
    //checkForOverridingPrivateMember(node);
    checkForMissingReturn(node.returnType, node.body);
    return super.visitMethodDeclaration(node);
  }

  Object visitPostfixExpression(PostfixExpression node) {
    checkForDeprecatedMemberUse(node.bestElement, node);
    return super.visitPostfixExpression(node);
  }

  Object visitPrefixExpression(PrefixExpression node) {
    checkForDeprecatedMemberUse(node.bestElement, node);
    return super.visitPrefixExpression(node);
  }

  Object visitRedirectingConstructorInvocation(RedirectingConstructorInvocation node) {
    checkForDeprecatedMemberUse(node.staticElement, node);
    return super.visitRedirectingConstructorInvocation(node);
  }

  Object visitSimpleIdentifier(SimpleIdentifier node) {
    checkForDeprecatedMemberUseAtIdentifier(node);
    return super.visitSimpleIdentifier(node);
  }

  Object visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    checkForDeprecatedMemberUse(node.staticElement, node);
    return super.visitSuperConstructorInvocation(node);
  }

  Object visitVariableDeclaration(VariableDeclaration node) {
    checkForUseOfVoidResult(node.initializer);
    return super.visitVariableDeclaration(node);
  }

  /**
   * Check for the passed is expression for the unnecessary type check hint codes as well as null
   * checks expressed using an is expression.
   *
   * @param node the is expression to check
   * @return `true` if and only if a hint code is generated on the passed node
   * @see HintCode#TYPE_CHECK_IS_NOT_NULL
   * @see HintCode#TYPE_CHECK_IS_NULL
   * @see HintCode#UNNECESSARY_TYPE_CHECK_TRUE
   * @see HintCode#UNNECESSARY_TYPE_CHECK_FALSE
   */
  bool checkAllTypeChecks(IsExpression node) {
    Expression expression = node.expression;
    TypeName typeName = node.type;
    Type2 lhsType = expression.staticType;
    Type2 rhsType = typeName.type;
    if (lhsType == null || rhsType == null) {
      return false;
    }
    String rhsNameStr = typeName.name.name;
    // if x is dynamic
    if (rhsType.isDynamic && rhsNameStr == sc.Keyword.DYNAMIC.syntax) {
      if (node.notOperator == null) {
        // the is case
        _errorReporter.reportError2(HintCode.UNNECESSARY_TYPE_CHECK_TRUE, node, []);
      } else {
        // the is not case
        _errorReporter.reportError2(HintCode.UNNECESSARY_TYPE_CHECK_FALSE, node, []);
      }
      return true;
    }
    Element rhsElement = rhsType.element;
    LibraryElement libraryElement = rhsElement != null ? rhsElement.library : null;
    if (libraryElement != null && libraryElement.isDartCore) {
      // if x is Object or null is Null
      if (rhsType.isObject || (expression is NullLiteral && rhsNameStr == _NULL_TYPE_NAME)) {
        if (node.notOperator == null) {
          // the is case
          _errorReporter.reportError2(HintCode.UNNECESSARY_TYPE_CHECK_TRUE, node, []);
        } else {
          // the is not case
          _errorReporter.reportError2(HintCode.UNNECESSARY_TYPE_CHECK_FALSE, node, []);
        }
        return true;
      } else if (rhsNameStr == _NULL_TYPE_NAME) {
        if (node.notOperator == null) {
          // the is case
          _errorReporter.reportError2(HintCode.TYPE_CHECK_IS_NULL, node, []);
        } else {
          // the is not case
          _errorReporter.reportError2(HintCode.TYPE_CHECK_IS_NOT_NULL, node, []);
        }
        return true;
      }
    }
    return false;
  }

  /**
   * Given some [Element], look at the associated metadata and report the use of the member if
   * it is declared as deprecated.
   *
   * @param element some element to check for deprecated use of
   * @param node the node use for the location of the error
   * @return `true` if and only if a hint code is generated on the passed node
   * @see HintCode#DEPRECATED_MEMBER_USE
   */
  bool checkForDeprecatedMemberUse(Element element, AstNode node) {
    if (element != null && element.isDeprecated) {
      String displayName = element.displayName;
      if (element is ConstructorElement) {
        // TODO(jwren) We should modify ConstructorElement.getDisplayName(), or have the logic
        // centralized elsewhere, instead of doing this logic here.
        ConstructorElement constructorElement = element;
        displayName = constructorElement.enclosingElement.displayName;
        if (!constructorElement.displayName.isEmpty) {
          displayName = "${displayName}.${constructorElement.displayName}";
        }
      }
      _errorReporter.reportError2(HintCode.DEPRECATED_MEMBER_USE, node, [displayName]);
      return true;
    }
    return false;
  }

  /**
   * For [SimpleIdentifier]s, only call [checkForDeprecatedMemberUse]
   * if the node is not in a declaration context.
   *
   * Also, if the identifier is a constructor name in a constructor invocation, then calls to the
   * deprecated constructor will be caught by
   * [visitInstanceCreationExpression] and
   * [visitSuperConstructorInvocation], and can be ignored by
   * this visit method.
   *
   * @param identifier some simple identifier to check for deprecated use of
   * @return `true` if and only if a hint code is generated on the passed node
   * @see HintCode#DEPRECATED_MEMBER_USE
   */
  bool checkForDeprecatedMemberUseAtIdentifier(SimpleIdentifier identifier) {
    if (identifier.inDeclarationContext()) {
      return false;
    }
    AstNode parent = identifier.parent;
    if ((parent is ConstructorName && identical(identifier, parent.name)) || (parent is SuperConstructorInvocation && identical(identifier, parent.constructorName)) || parent is HideCombinator) {
      return false;
    }
    return checkForDeprecatedMemberUse(identifier.bestElement, identifier);
  }

  /**
   * Check for the passed binary expression for the [HintCode#DIVISION_OPTIMIZATION].
   *
   * @param node the binary expression to check
   * @return `true` if and only if a hint code is generated on the passed node
   * @see HintCode#DIVISION_OPTIMIZATION
   */
  bool checkForDivisionOptimizationHint(BinaryExpression node) {
    // Return if the operator is not '/'
    if (node.operator.type != sc.TokenType.SLASH) {
      return false;
    }
    // Return if the '/' operator is not defined in core, or if we don't know its static or propagated type
    MethodElement methodElement = node.bestElement;
    if (methodElement == null) {
      return false;
    }
    LibraryElement libraryElement = methodElement.library;
    if (libraryElement != null && !libraryElement.isDartCore) {
      return false;
    }
    // Report error if the (x/y) has toInt() invoked on it
    if (node.parent is ParenthesizedExpression) {
      ParenthesizedExpression parenthesizedExpression = wrapParenthesizedExpression(node.parent as ParenthesizedExpression);
      if (parenthesizedExpression.parent is MethodInvocation) {
        MethodInvocation methodInvocation = parenthesizedExpression.parent as MethodInvocation;
        if (_TO_INT_METHOD_NAME == methodInvocation.methodName.name && methodInvocation.argumentList.arguments.isEmpty) {
          _errorReporter.reportError2(HintCode.DIVISION_OPTIMIZATION, methodInvocation, []);
          return true;
        }
      }
    }
    return false;
  }

  /**
   * Generate a hint for functions or methods that have a return type, but do not have a return
   * statement on all branches. At the end of blocks with no return, Dart implicitly returns
   * `null`, avoiding these implicit returns is considered a best practice.
   *
   * @param node the binary expression to check
   * @param body the function body
   * @return `true` if and only if a hint code is generated on the passed node
   * @see HintCode#MISSING_RETURN
   */
  bool checkForMissingReturn(TypeName returnType, FunctionBody body) {
    // Check that the method or function has a return type, and a function body
    if (returnType == null || body == null) {
      return false;
    }
    // Check that the body is a BlockFunctionBody
    if (body is! BlockFunctionBody) {
      return false;
    }
    // Check that the type is resolvable, and is not "void"
    Type2 returnTypeType = returnType.type;
    if (returnTypeType == null || returnTypeType.isVoid) {
      return false;
    }
    // Check the block for a return statement, if not, create the hint
    BlockFunctionBody blockFunctionBody = body as BlockFunctionBody;
    if (!blockFunctionBody.accept(new ExitDetector())) {
      _errorReporter.reportError2(HintCode.MISSING_RETURN, returnType, [returnTypeType.displayName]);
      return true;
    }
    return false;
  }

  /**
   * Check for the passed class declaration for the
   * [HintCode#OVERRIDE_EQUALS_BUT_NOT_HASH_CODE] hint code.
   *
   * @param node the class declaration to check
   * @return `true` if and only if a hint code is generated on the passed node
   * @see HintCode#OVERRIDE_EQUALS_BUT_NOT_HASH_CODE
   */
  bool checkForOverrideEqualsButNotHashCode(ClassDeclaration node) {
    ClassElement classElement = node.element;
    if (classElement == null) {
      return false;
    }
    MethodElement equalsOperatorMethodElement = classElement.getMethod(sc.TokenType.EQ_EQ.lexeme);
    if (equalsOperatorMethodElement != null) {
      PropertyAccessorElement hashCodeElement = classElement.getGetter(_HASHCODE_GETTER_NAME);
      if (hashCodeElement == null) {
        _errorReporter.reportError2(HintCode.OVERRIDE_EQUALS_BUT_NOT_HASH_CODE, node.name, [classElement.displayName]);
        return true;
      }
    }
    return false;
  }

  /**
   * Checks that if the passed method declaration is private, it does not override a private member
   * in a superclass.
   *
   * @param node the method declaration to check
   * @return `true` if and only if a hint code is generated on the passed node
   * @see HintCode#OVERRIDDING_PRIVATE_MEMBER
   */
  bool checkForOverridingPrivateMember(MethodDeclaration node) {
    // If not in an enclosing class, return false
    if (_enclosingClass == null) {
      return false;
    }
    // If the member is not private, return false
    if (!Identifier.isPrivateName(node.name.name)) {
      return false;
    }
    // Get the element of the member, if null, return false
    ExecutableElement executableElement = node.element;
    if (executableElement == null) {
      return false;
    }
    // Loop through all of the superclasses looking for a matching method or accessor
    // TODO(jwren) If the HintGenerator needs or has easy access to the InheritanceManager in the
    // future then this could be refactored down to be more readable, however, since we are only
    // looking through super classes (and not the entire interface graph) there is no pressing need
    String elementName = executableElement.name;
    bool isGetterOrSetter = executableElement is PropertyAccessorElement;
    InterfaceType superType = _enclosingClass.supertype;
    if (superType == null) {
      return false;
    }
    ClassElement classElement = superType.element;
    while (classElement != null) {
      if (_enclosingClass.library != classElement.library) {
        if (isGetterOrSetter) {
          PropertyAccessorElement overriddenAccessor = null;
          List<PropertyAccessorElement> accessors = classElement.accessors;
          for (PropertyAccessorElement propertyAccessorElement in accessors) {
            if (elementName == propertyAccessorElement.name) {
              overriddenAccessor = propertyAccessorElement;
              break;
            }
          }
          if (overriddenAccessor != null) {
            String memberType = (executableElement as PropertyAccessorElement).isGetter ? _GETTER : _SETTER;
            _errorReporter.reportError2(HintCode.OVERRIDDING_PRIVATE_MEMBER, node.name, [
                memberType,
                executableElement.displayName,
                classElement.displayName]);
            return true;
          }
        } else {
          MethodElement overriddenMethod = classElement.getMethod(elementName);
          if (overriddenMethod != null) {
            _errorReporter.reportError2(HintCode.OVERRIDDING_PRIVATE_MEMBER, node.name, [
                _METHOD,
                executableElement.displayName,
                classElement.displayName]);
            return true;
          }
        }
      }
      superType = classElement.supertype;
      classElement = superType != null ? superType.element : null;
    }
    return false;
  }

  /**
   * Check for the passed as expression for the [HintCode#UNNECESSARY_CAST] hint code.
   *
   * @param node the as expression to check
   * @return `true` if and only if a hint code is generated on the passed node
   * @see HintCode#UNNECESSARY_CAST
   */
  bool checkForUnnecessaryCast(AsExpression node) {
    Expression expression = node.expression;
    TypeName typeName = node.type;
    Type2 lhsType = expression.staticType;
    Type2 rhsType = typeName.type;
    // TODO(jwren) After dartbug.com/13732, revisit this, we should be able to remove the
    // !(x instanceof TypeParameterType) checks.
    if (lhsType != null && rhsType != null && !lhsType.isDynamic && !rhsType.isDynamic && lhsType is! TypeParameterType && rhsType is! TypeParameterType && lhsType.isSubtypeOf(rhsType)) {
      _errorReporter.reportError2(HintCode.UNNECESSARY_CAST, node, []);
      return true;
    }
    return false;
  }

  /**
   * Check for situations where the result of a method or function is used, when it returns 'void'.
   *
   * TODO(jwren) Many other situations of use could be covered. We currently cover the cases var x =
   * m() and x = m(), but we could also cover cases such as m().x, m()[k], a + m(), f(m()), return
   * m().
   *
   * @param node expression on the RHS of some assignment
   * @return `true` if and only if a hint code is generated on the passed node
   * @see HintCode#USE_OF_VOID_RESULT
   */
  bool checkForUseOfVoidResult(Expression expression) {
    if (expression == null || expression is! MethodInvocation) {
      return false;
    }
    MethodInvocation methodInvocation = expression as MethodInvocation;
    if (identical(methodInvocation.staticType, VoidTypeImpl.instance)) {
      SimpleIdentifier methodName = methodInvocation.methodName;
      _errorReporter.reportError2(HintCode.USE_OF_VOID_RESULT, methodName, [methodName.name]);
      return true;
    }
    return false;
  }
}

/**
 * Instances of the class `Dart2JSVerifier` traverse an AST structure looking for hints for
 * code that will be compiled to JS, such as [HintCode#IS_DOUBLE].
 */
class Dart2JSVerifier extends RecursiveAstVisitor<Object> {
  /**
   * The error reporter by which errors will be reported.
   */
  ErrorReporter _errorReporter;

  /**
   * The name of the `double` type.
   */
  static String _DOUBLE_TYPE_NAME = "double";

  /**
   * Create a new instance of the [Dart2JSVerifier].
   *
   * @param errorReporter the error reporter
   */
  Dart2JSVerifier(ErrorReporter errorReporter) {
    this._errorReporter = errorReporter;
  }

  Object visitIsExpression(IsExpression node) {
    checkForIsDoubleHints(node);
    return super.visitIsExpression(node);
  }

  /**
   * Check for instances of `x is double`, `x is int`, `x is! double` and
   * `x is! int`.
   *
   * @param node the is expression to check
   * @return `true` if and only if a hint code is generated on the passed node
   * @see HintCode#IS_DOUBLE
   * @see HintCode#IS_INT
   * @see HintCode#IS_NOT_DOUBLE
   * @see HintCode#IS_NOT_INT
   */
  bool checkForIsDoubleHints(IsExpression node) {
    TypeName typeName = node.type;
    Type2 type = typeName.type;
    if (type != null && type.element != null) {
      Element element = type.element;
      String typeNameStr = element.name;
      LibraryElement libraryElement = element.library;
      //      if (typeNameStr.equals(INT_TYPE_NAME) && libraryElement != null
      //          && libraryElement.isDartCore()) {
      //        if (node.getNotOperator() == null) {
      //          errorReporter.reportError(HintCode.IS_INT, node);
      //        } else {
      //          errorReporter.reportError(HintCode.IS_NOT_INT, node);
      //        }
      //        return true;
      //      } else
      if (typeNameStr == _DOUBLE_TYPE_NAME && libraryElement != null && libraryElement.isDartCore) {
        if (node.notOperator == null) {
          _errorReporter.reportError2(HintCode.IS_DOUBLE, node, []);
        } else {
          _errorReporter.reportError2(HintCode.IS_NOT_DOUBLE, node, []);
        }
        return true;
      }
    }
    return false;
  }
}

/**
 * Instances of the class `DeadCodeVerifier` traverse an AST structure looking for cases of
 * [HintCode#DEAD_CODE].
 */
class DeadCodeVerifier extends RecursiveAstVisitor<Object> {
  /**
   * The error reporter by which errors will be reported.
   */
  ErrorReporter _errorReporter;

  /**
   * Create a new instance of the [DeadCodeVerifier].
   *
   * @param errorReporter the error reporter
   */
  DeadCodeVerifier(ErrorReporter errorReporter) {
    this._errorReporter = errorReporter;
  }

  Object visitBinaryExpression(BinaryExpression node) {
    sc.Token operator = node.operator;
    bool isAmpAmp = identical(operator.type, sc.TokenType.AMPERSAND_AMPERSAND);
    bool isBarBar = identical(operator.type, sc.TokenType.BAR_BAR);
    if (isAmpAmp || isBarBar) {
      Expression lhsCondition = node.leftOperand;
      if (!isDebugConstant(lhsCondition)) {
        ValidResult lhsResult = getConstantBooleanValue(lhsCondition);
        if (lhsResult != null) {
          if (lhsResult.isTrue && isBarBar) {
            // report error on else block: true || !e!
            _errorReporter.reportError2(HintCode.DEAD_CODE, node.rightOperand, []);
            // only visit the LHS:
            safelyVisit(lhsCondition);
            return null;
          } else if (lhsResult.isFalse && isAmpAmp) {
            // report error on if block: false && !e!
            _errorReporter.reportError2(HintCode.DEAD_CODE, node.rightOperand, []);
            // only visit the LHS:
            safelyVisit(lhsCondition);
            return null;
          }
        }
      }
    }
    return super.visitBinaryExpression(node);
  }

  /**
   * For each [Block], this method reports and error on all statements between the end of the
   * block and the first return statement (assuming there it is not at the end of the block.)
   *
   * @param node the block to evaluate
   */
  Object visitBlock(Block node) {
    NodeList<Statement> statements = node.statements;
    int size = statements.length;
    for (int i = 0; i < size; i++) {
      Statement currentStatement = statements[i];
      safelyVisit(currentStatement);
      if (currentStatement is ReturnStatement && i != size - 1) {
        Statement nextStatement = statements[i + 1];
        Statement lastStatement = statements[size - 1];
        int offset = nextStatement.offset;
        int length = lastStatement.end - offset;
        _errorReporter.reportError4(HintCode.DEAD_CODE, offset, length, []);
        return null;
      }
    }
    return null;
  }

  Object visitConditionalExpression(ConditionalExpression node) {
    Expression conditionExpression = node.condition;
    safelyVisit(conditionExpression);
    if (!isDebugConstant(conditionExpression)) {
      ValidResult result = getConstantBooleanValue(conditionExpression);
      if (result != null) {
        if (result.isTrue) {
          // report error on else block: true ? 1 : !2!
          _errorReporter.reportError2(HintCode.DEAD_CODE, node.elseExpression, []);
          safelyVisit(node.thenExpression);
          return null;
        } else {
          // report error on if block: false ? !1! : 2
          _errorReporter.reportError2(HintCode.DEAD_CODE, node.thenExpression, []);
          safelyVisit(node.elseExpression);
          return null;
        }
      }
    }
    return super.visitConditionalExpression(node);
  }

  Object visitIfStatement(IfStatement node) {
    Expression conditionExpression = node.condition;
    safelyVisit(conditionExpression);
    if (!isDebugConstant(conditionExpression)) {
      ValidResult result = getConstantBooleanValue(conditionExpression);
      if (result != null) {
        if (result.isTrue) {
          // report error on else block: if(true) {} else {!}
          Statement elseStatement = node.elseStatement;
          if (elseStatement != null) {
            _errorReporter.reportError2(HintCode.DEAD_CODE, elseStatement, []);
            safelyVisit(node.thenStatement);
            return null;
          }
        } else {
          // report error on if block: if (false) {!} else {}
          _errorReporter.reportError2(HintCode.DEAD_CODE, node.thenStatement, []);
          safelyVisit(node.elseStatement);
          return null;
        }
      }
    }
    return super.visitIfStatement(node);
  }

  Object visitTryStatement(TryStatement node) {
    safelyVisit(node.body);
    safelyVisit(node.finallyBlock);
    NodeList<CatchClause> catchClauses = node.catchClauses;
    int numOfCatchClauses = catchClauses.length;
    List<Type2> visitedTypes = new List<Type2>();
    for (int i = 0; i < numOfCatchClauses; i++) {
      CatchClause catchClause = catchClauses[i];
      if (catchClause.onKeyword != null) {
        // on-catch clause found, verify that the exception type is not a subtype of a previous
        // on-catch exception type
        TypeName typeName = catchClause.exceptionType;
        if (typeName != null && typeName.type != null) {
          Type2 currentType = typeName.type;
          if (currentType.isObject) {
            // Found catch clause clause that has Object as an exception type, this is equivalent to
            // having a catch clause that doesn't have an exception type, visit the block, but
             // generate an error on any following catch clauses (and don't visit them).
            safelyVisit(catchClause);
            if (i + 1 != numOfCatchClauses) {
               // this catch clause is not the last in the try statement
              CatchClause nextCatchClause = catchClauses[i + 1];
              CatchClause lastCatchClause = catchClauses[numOfCatchClauses - 1];
              int offset = nextCatchClause.offset;
              int length = lastCatchClause.end - offset;
              _errorReporter.reportError4(HintCode.DEAD_CODE_CATCH_FOLLOWING_CATCH, offset, length, []);
              return null;
            }
          }
          for (Type2 type in visitedTypes) {
            if (currentType.isSubtypeOf(type)) {
              CatchClause lastCatchClause = catchClauses[numOfCatchClauses - 1];
              int offset = catchClause.offset;
              int length = lastCatchClause.end - offset;
              _errorReporter.reportError4(HintCode.DEAD_CODE_ON_CATCH_SUBTYPE, offset, length, [currentType.displayName, type.displayName]);
              return null;
            }
          }
          visitedTypes.add(currentType);
        }
        safelyVisit(catchClause);
      } else {
         // Found catch clause clause that doesn't have an exception type, visit the block, but
        // generate an error on any following catch clauses (and don't visit them).
        safelyVisit(catchClause);
        if (i + 1 != numOfCatchClauses) {
          // this catch clause is not the last in the try statement
          CatchClause nextCatchClause = catchClauses[i + 1];
          CatchClause lastCatchClause = catchClauses[numOfCatchClauses - 1];
          int offset = nextCatchClause.offset;
          int length = lastCatchClause.end - offset;
          _errorReporter.reportError4(HintCode.DEAD_CODE_CATCH_FOLLOWING_CATCH, offset, length, []);
          return null;
        }
      }
    }
    return null;
  }

  Object visitWhileStatement(WhileStatement node) {
    Expression conditionExpression = node.condition;
    safelyVisit(conditionExpression);
    if (!isDebugConstant(conditionExpression)) {
      ValidResult result = getConstantBooleanValue(conditionExpression);
      if (result != null) {
        if (result.isFalse) {
          // report error on if block: while (false) {!}
          _errorReporter.reportError2(HintCode.DEAD_CODE, node.body, []);
          return null;
        }
      }
    }
    safelyVisit(node.body);
    return null;
  }

  /**
   * Given some [Expression], this method returns [ValidResult#RESULT_TRUE] if it is
   * `true`, [ValidResult#RESULT_FALSE] if it is `false`, or `null` if the
   * expression is not a constant boolean value.
   *
   * @param expression the expression to evaluate
   * @return [ValidResult#RESULT_TRUE] if it is `true`, [ValidResult#RESULT_FALSE]
   *         if it is `false`, or `null` if the expression is not a constant boolean
   *         value
   */
  ValidResult getConstantBooleanValue(Expression expression) {
    if (expression is BooleanLiteral) {
      if (expression.value) {
        return new ValidResult(new DartObjectImpl(null, BoolState.from(true)));
      } else {
        return new ValidResult(new DartObjectImpl(null, BoolState.from(false)));
      }
    }
    // Don't consider situations where we could evaluate to a constant boolean expression with the
    // ConstantVisitor
//
       // else {
//
         // EvaluationResultImpl result = expression.accept(new ConstantVisitor());
//
         // if (result == ValidResult.RESULT_TRUE) {
//
           // return ValidResult.RESULT_TRUE;
//
         // } else if (result == ValidResult.RESULT_FALSE) {
//
           // return ValidResult.RESULT_FALSE;
//
         // }
//
         // return null;
//
       // }
    return null;
  }

  /**
   * Return `true` if and only if the passed expression is resolved to a constant variable.
   *
   * @param expression some conditional expression
   * @return `true` if and only if the passed expression is resolved to a constant variable
   */
  bool isDebugConstant(Expression expression) {
    Element element = null;
    if (expression is Identifier) {
      Identifier identifier = expression;
      element = identifier.staticElement;
    } else if (expression is PropertyAccess) {
      PropertyAccess propertyAccess = expression;
      element = propertyAccess.propertyName.staticElement;
    }
    if (element is PropertyAccessorElement) {
      PropertyAccessorElement pae = element as PropertyAccessorElement;
      PropertyInducingElement variable = pae.variable;
      return variable != null && variable.isConst;
    }
    return false;
  }

  /**
   * If the given node is not `null`, visit this instance of the dead code verifier.
   *
   * @param node the node to be visited
   */
  void safelyVisit(AstNode node) {
    if (node != null) {
      node.accept(this);
    }
  }
}

/**
 * Instances of the class `ExitDetector` determine whether the visited AST node is guaranteed
 * to terminate by executing a `return` statement, `throw` expression, `rethrow`
 * expression, or simple infinite loop such as `while(true)`.
 */
class ExitDetector extends GeneralizingAstVisitor<bool> {
  /**
   * Set to `true` when a `break` is encountered, and reset to `false` when a
   * `do`, `while`, `for` or `switch` block is entered.
   */
  bool _enclosingBlockContainsBreak = false;

  bool visitArgumentList(ArgumentList node) => visitExpressions(node.arguments);

  bool visitAsExpression(AsExpression node) => node.expression.accept(this);

  bool visitAssertStatement(AssertStatement node) => node.condition.accept(this);

  bool visitAssignmentExpression(AssignmentExpression node) => node.leftHandSide.accept(this) || node.rightHandSide.accept(this);

  bool visitBinaryExpression(BinaryExpression node) {
    Expression lhsExpression = node.leftOperand;
    sc.TokenType operatorType = node.operator.type;
    // If the operator is || and the left hand side is false literal, don't consider the RHS of the
    // binary expression.
    // TODO(jwren) Do we want to take constant expressions into account, evaluate if(false) {}
    // differently than if(<condition>), when <condition> evaluates to a constant false value?
    if (identical(operatorType, sc.TokenType.BAR_BAR)) {
      if (lhsExpression is BooleanLiteral) {
        BooleanLiteral booleanLiteral = lhsExpression;
        if (!booleanLiteral.value) {
          return false;
        }
      }
    }
    // If the operator is && and the left hand side is true literal, don't consider the RHS of the
    // binary expression.
    if (identical(operatorType, sc.TokenType.AMPERSAND_AMPERSAND)) {
      if (lhsExpression is BooleanLiteral) {
        BooleanLiteral booleanLiteral = lhsExpression;
        if (booleanLiteral.value) {
          return false;
        }
      }
    }
    return lhsExpression.accept(this) || node.rightOperand.accept(this);
  }

  bool visitBlock(Block node) => visitStatements(node.statements);

  bool visitBlockFunctionBody(BlockFunctionBody node) => node.block.accept(this);

  bool visitBreakStatement(BreakStatement node) {
    _enclosingBlockContainsBreak = true;
    return false;
  }

  bool visitCascadeExpression(CascadeExpression node) {
    Expression target = node.target;
    if (target.accept(this)) {
      return true;
    }
    return visitExpressions(node.cascadeSections);
  }

  bool visitConditionalExpression(ConditionalExpression node) {
    Expression conditionExpression = node.condition;
    Expression thenStatement = node.thenExpression;
    Expression elseStatement = node.elseExpression;
    // TODO(jwren) Do we want to take constant expressions into account, evaluate if(false) {}
    // differently than if(<condition>), when <condition> evaluates to a constant false value?
    if (conditionExpression.accept(this)) {
      return true;
    }
    if (thenStatement == null || elseStatement == null) {
      return false;
    }
    return thenStatement.accept(this) && elseStatement.accept(this);
  }

  bool visitContinueStatement(ContinueStatement node) => false;

  bool visitDoStatement(DoStatement node) {
    bool outerBreakValue = _enclosingBlockContainsBreak;
    _enclosingBlockContainsBreak = false;
    try {
      Expression conditionExpression = node.condition;
      if (conditionExpression.accept(this)) {
        return true;
      }
      // TODO(jwren) Do we want to take all constant expressions into account?
      if (conditionExpression is BooleanLiteral) {
        BooleanLiteral booleanLiteral = conditionExpression;
        // If do {} while (true), and the body doesn't return or the body doesn't have a break, then
        // return true.
        bool blockReturns = node.body.accept(this);
        if (booleanLiteral.value && (blockReturns || !_enclosingBlockContainsBreak)) {
          return true;
        }
      }
      return false;
    } finally {
      _enclosingBlockContainsBreak = outerBreakValue;
    }
  }

  bool visitEmptyStatement(EmptyStatement node) => false;

  bool visitExpressionStatement(ExpressionStatement node) => node.expression.accept(this);

  bool visitForEachStatement(ForEachStatement node) {
    bool outerBreakValue = _enclosingBlockContainsBreak;
    _enclosingBlockContainsBreak = false;
    try {
      return node.iterator.accept(this);
    } finally {
      _enclosingBlockContainsBreak = outerBreakValue;
    }
  }

  bool visitForStatement(ForStatement node) {
    bool outerBreakValue = _enclosingBlockContainsBreak;
    _enclosingBlockContainsBreak = false;
    try {
      if (node.variables != null && visitVariableDeclarations(node.variables.variables)) {
        return true;
      }
      if (node.initialization != null && node.initialization.accept(this)) {
        return true;
      }
      Expression conditionExpression = node.condition;
      if (conditionExpression != null && conditionExpression.accept(this)) {
        return true;
      }
      if (visitExpressions(node.updaters)) {
        return true;
      }
      // TODO(jwren) Do we want to take all constant expressions into account?
      // If for(; true; ) (or for(;;)), and the body doesn't return or the body doesn't have a
      // break, then return true.
      bool implicitOrExplictTrue = conditionExpression == null || (conditionExpression is BooleanLiteral && conditionExpression.value);
      if (implicitOrExplictTrue) {
        bool blockReturns = node.body.accept(this);
        if (blockReturns || !_enclosingBlockContainsBreak) {
          return true;
        }
      }
      return false;
    } finally {
      _enclosingBlockContainsBreak = outerBreakValue;
    }
  }

  bool visitFunctionDeclarationStatement(FunctionDeclarationStatement node) => false;

  bool visitFunctionExpression(FunctionExpression node) => false;

  bool visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    if (node.function.accept(this)) {
      return true;
    }
    return node.argumentList.accept(this);
  }

  bool visitIdentifier(Identifier node) => false;

  bool visitIfStatement(IfStatement node) {
    Expression conditionExpression = node.condition;
    Statement thenStatement = node.thenStatement;
    Statement elseStatement = node.elseStatement;
    if (conditionExpression.accept(this)) {
      return true;
    }
    // TODO(jwren) Do we want to take all constant expressions into account?
    if (conditionExpression is BooleanLiteral) {
      BooleanLiteral booleanLiteral = conditionExpression;
      if (booleanLiteral.value) {
        // if(true) ...
        return thenStatement.accept(this);
      } else if (elseStatement != null) {
        // if (false) ...
        return elseStatement.accept(this);
      }
    }
    if (thenStatement == null || elseStatement == null) {
      return false;
    }
    return thenStatement.accept(this) && elseStatement.accept(this);
  }

  bool visitIndexExpression(IndexExpression node) {
    Expression target = node.realTarget;
    if (target != null && target.accept(this)) {
      return true;
    }
    if (node.index.accept(this)) {
      return true;
    }
    return false;
  }

  bool visitInstanceCreationExpression(InstanceCreationExpression node) => node.argumentList.accept(this);

  bool visitIsExpression(IsExpression node) => node.expression.accept(this);

  bool visitLabel(Label node) => false;

  bool visitLabeledStatement(LabeledStatement node) => node.statement.accept(this);

  bool visitLiteral(Literal node) => false;

  bool visitMethodInvocation(MethodInvocation node) {
    Expression target = node.realTarget;
    if (target != null && target.accept(this)) {
      return true;
    }
    return node.argumentList.accept(this);
  }

  bool visitNamedExpression(NamedExpression node) => node.expression.accept(this);

  bool visitParenthesizedExpression(ParenthesizedExpression node) => node.expression.accept(this);

  bool visitPostfixExpression(PostfixExpression node) => false;

  bool visitPrefixExpression(PrefixExpression node) => false;

  bool visitPropertyAccess(PropertyAccess node) {
    Expression target = node.realTarget;
    if (target != null && target.accept(this)) {
      return true;
    }
    return false;
  }

  bool visitRethrowExpression(RethrowExpression node) => true;

  bool visitReturnStatement(ReturnStatement node) => true;

  bool visitSuperExpression(SuperExpression node) => false;

  bool visitSwitchCase(SwitchCase node) => visitStatements(node.statements);

  bool visitSwitchDefault(SwitchDefault node) => visitStatements(node.statements);

  bool visitSwitchStatement(SwitchStatement node) {
    bool outerBreakValue = _enclosingBlockContainsBreak;
    _enclosingBlockContainsBreak = false;
    try {
      bool hasDefault = false;
      NodeList<SwitchMember> memberList = node.members;
      List<SwitchMember> members = new List.from(memberList);
      for (int i = 0; i < members.length; i++) {
        SwitchMember switchMember = members[i];
        if (switchMember is SwitchDefault) {
          hasDefault = true;
          // If this is the last member and there are no statements, return false
          if (switchMember.statements.isEmpty && i + 1 == members.length) {
            return false;
          }
        }
        // For switch members with no statements, don't visit the children, otherwise, return false if
        // no return is found in the children statements
        if (!switchMember.statements.isEmpty && !switchMember.accept(this)) {
          return false;
        }
      }
      return hasDefault;
    } finally {
      _enclosingBlockContainsBreak = outerBreakValue;
    }
  }

  bool visitThisExpression(ThisExpression node) => false;

  bool visitThrowExpression(ThrowExpression node) => true;

  bool visitTryStatement(TryStatement node) {
    if (node.body.accept(this)) {
      return true;
    }
    Block finallyBlock = node.finallyBlock;
    if (finallyBlock != null && finallyBlock.accept(this)) {
      return true;
    }
    return false;
  }

  bool visitTypeName(TypeName node) => false;

  bool visitVariableDeclaration(VariableDeclaration node) {
    Expression initializer = node.initializer;
    if (initializer != null) {
      return initializer.accept(this);
    }
    return false;
  }

  bool visitVariableDeclarationList(VariableDeclarationList node) => visitVariableDeclarations(node.variables);

  bool visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    NodeList<VariableDeclaration> variables = node.variables.variables;
    for (int i = 0; i < variables.length; i++) {
      if (variables[i].accept(this)) {
        return true;
      }
    }
    return false;
  }

  bool visitWhileStatement(WhileStatement node) {
    bool outerBreakValue = _enclosingBlockContainsBreak;
    _enclosingBlockContainsBreak = false;
    try {
      Expression conditionExpression = node.condition;
      if (conditionExpression.accept(this)) {
        return true;
      }
      // TODO(jwren) Do we want to take all constant expressions into account?
      if (conditionExpression is BooleanLiteral) {
        BooleanLiteral booleanLiteral = conditionExpression;
        // If while(true), and the body doesn't return or the body doesn't have a break, then return
        // true.
        bool blockReturns = node.body.accept(this);
        if (booleanLiteral.value && (blockReturns || !_enclosingBlockContainsBreak)) {
          return true;
        }
      }
      return false;
    } finally {
      _enclosingBlockContainsBreak = outerBreakValue;
    }
  }

  bool visitExpressions(NodeList<Expression> expressions) {
    for (int i = expressions.length - 1; i >= 0; i--) {
      if (expressions[i].accept(this)) {
        return true;
      }
    }
    return false;
  }

  bool visitStatements(NodeList<Statement> statements) {
    for (int i = statements.length - 1; i >= 0; i--) {
      if (statements[i].accept(this)) {
        return true;
      }
    }
    return false;
  }

  bool visitVariableDeclarations(NodeList<VariableDeclaration> variableDeclarations) {
    for (int i = variableDeclarations.length - 1; i >= 0; i--) {
      if (variableDeclarations[i].accept(this)) {
        return true;
      }
    }
    return false;
  }
}

/**
 * Instances of the class `HintGenerator` traverse a library's worth of dart code at a time to
 * generate hints over the set of sources.
 *
 * @see HintCode
 */
class HintGenerator {
  List<CompilationUnit> _compilationUnits;

  AnalysisContext _context;

  AnalysisErrorListener _errorListener;

  ImportsVerifier _importsVerifier;

  bool _enableDart2JSHints = false;

  /**
   * The inheritance manager used to find overridden methods.
   */
  InheritanceManager _manager;

  HintGenerator(List<CompilationUnit> compilationUnits, AnalysisContext context, AnalysisErrorListener errorListener) {
    this._compilationUnits = compilationUnits;
    this._context = context;
    this._errorListener = errorListener;
    LibraryElement library = compilationUnits[0].element.library;
    _importsVerifier = new ImportsVerifier(library);
    _enableDart2JSHints = context.analysisOptions.dart2jsHint;
    _manager = new InheritanceManager(compilationUnits[0].element.library);
  }

  void generateForLibrary() {
    TimeCounter_TimeCounterHandle timeCounter = PerformanceStatistics.hints.start();
    try {
      for (int i = 0; i < _compilationUnits.length; i++) {
        CompilationUnitElement element = _compilationUnits[i].element;
        if (element != null) {
          if (i == 0) {
            _importsVerifier.inDefiningCompilationUnit = true;
            generateForCompilationUnit(_compilationUnits[i], element.source);
            _importsVerifier.inDefiningCompilationUnit = false;
          } else {
            generateForCompilationUnit(_compilationUnits[i], element.source);
          }
        }
      }
      ErrorReporter definingCompilationUnitErrorReporter = new ErrorReporter(_errorListener, _compilationUnits[0].element.source);
      _importsVerifier.generateDuplicateImportHints(definingCompilationUnitErrorReporter);
      _importsVerifier.generateUnusedImportHints(definingCompilationUnitErrorReporter);
    } finally {
      timeCounter.stop();
    }
  }

  void generateForCompilationUnit(CompilationUnit unit, Source source) {
    ErrorReporter errorReporter = new ErrorReporter(_errorListener, source);
    unit.accept(_importsVerifier);
    // dead code analysis
    unit.accept(new DeadCodeVerifier(errorReporter));
    // dart2js analysis
    if (_enableDart2JSHints) {
      unit.accept(new Dart2JSVerifier(errorReporter));
    }
    // Dart best practices
    unit.accept(new BestPracticesVerifier(errorReporter));
    unit.accept(new OverrideVerifier(_manager, errorReporter));
    // Find to-do comments
    new ToDoFinder(errorReporter).findIn(unit);
  }
}

/**
 * Instances of the class `ImportsVerifier` visit all of the referenced libraries in the
 * source code verifying that all of the imports are used, otherwise a
 * [HintCode#UNUSED_IMPORT] is generated with
 * [generateUnusedImportHints].
 *
 * While this class does not yet have support for an "Organize Imports" action, this logic built up
 * in this class could be used for such an action in the future.
 */
class ImportsVerifier extends RecursiveAstVisitor<Object> {
  /**
   * This is set to `true` if the current compilation unit which is being visited is the
   * defining compilation unit for the library, its value can be set with
   * [setInDefiningCompilationUnit].
   */
  bool _inDefiningCompilationUnit = false;

  /**
   * The current library.
   */
  LibraryElement _currentLibrary;

  /**
   * A list of [ImportDirective]s that the current library imports, as identifiers are visited
   * by this visitor and an import has been identified as being used by the library, the
   * [ImportDirective] is removed from this list. After all the sources in the library have
   * been evaluated, this list represents the set of unused imports.
   *
   * @see ImportsVerifier#generateUnusedImportErrors(ErrorReporter)
   */
  List<ImportDirective> _unusedImports;

  /**
   * After the list of [unusedImports] has been computed, this list is a proper subset of the
   * unused imports that are listed more than once.
   */
  List<ImportDirective> _duplicateImports;

  /**
   * This is a map between the set of [LibraryElement]s that the current library imports, and
   * a list of [ImportDirective]s that imports the library. In cases where the current library
   * imports a library with a single directive (such as `import lib1.dart;`), the library
   * element will map to a list of one [ImportDirective], which will then be removed from the
   * [unusedImports] list. In cases where the current library imports a library with multiple
   * directives (such as `import lib1.dart; import lib1.dart show C;`), the
   * [LibraryElement] will be mapped to a list of the import directives, and the namespace
   * will need to be used to compute the correct [ImportDirective] being used, see
   * [namespaceMap].
   */
  Map<LibraryElement, List<ImportDirective>> _libraryMap;

  /**
   * In cases where there is more than one import directive per library element, this mapping is
   * used to determine which of the multiple import directives are used by generating a
   * [Namespace] for each of the imports to do lookups in the same way that they are done from
   * the [ElementResolver].
   */
  Map<ImportDirective, Namespace> _namespaceMap;

  /**
   * This is a map between prefix elements and the import directive from which they are derived. In
   * cases where a type is referenced via a prefix element, the import directive can be marked as
   * used (removed from the unusedImports) by looking at the resolved `lib` in `lib.X`,
   * instead of looking at which library the `lib.X` resolves.
   */
  Map<PrefixElement, ImportDirective> _prefixElementMap;

  /**
   * Create a new instance of the [ImportsVerifier].
   *
   * @param errorReporter the error reporter
   */
  ImportsVerifier(LibraryElement library) {
    this._currentLibrary = library;
    this._unusedImports = new List<ImportDirective>();
    this._duplicateImports = new List<ImportDirective>();
    this._libraryMap = new Map<LibraryElement, List<ImportDirective>>();
    this._namespaceMap = new Map<ImportDirective, Namespace>();
    this._prefixElementMap = new Map<PrefixElement, ImportDirective>();
  }

  /**
   * Any time after the defining compilation unit has been visited by this visitor, this method can
   * be called to report an [HintCode#DUPLICATE_IMPORT] hint for each of the import directives
   * in the [duplicateImports] list.
   *
   * @param errorReporter the error reporter to report the set of [HintCode#DUPLICATE_IMPORT]
   *          hints to
   */
  void generateDuplicateImportHints(ErrorReporter errorReporter) {
    for (ImportDirective duplicateImport in _duplicateImports) {
      errorReporter.reportError2(HintCode.DUPLICATE_IMPORT, duplicateImport.uri, []);
    }
  }

  /**
   * After all of the compilation units have been visited by this visitor, this method can be called
   * to report an [HintCode#UNUSED_IMPORT] hint for each of the import directives in the
   * [unusedImports] list.
   *
   * @param errorReporter the error reporter to report the set of [HintCode#UNUSED_IMPORT]
   *          hints to
   */
  void generateUnusedImportHints(ErrorReporter errorReporter) {
    for (ImportDirective unusedImport in _unusedImports) {
      // Check that the import isn't dart:core
      ImportElement importElement = unusedImport.element;
      if (importElement != null) {
        LibraryElement libraryElement = importElement.importedLibrary;
        if (libraryElement != null && libraryElement.isDartCore) {
          continue;
        }
      }
      errorReporter.reportError2(HintCode.UNUSED_IMPORT, unusedImport.uri, []);
    }
  }

  Object visitCompilationUnit(CompilationUnit node) {
    if (_inDefiningCompilationUnit) {
      NodeList<Directive> directives = node.directives;
      for (Directive directive in directives) {
        if (directive is ImportDirective) {
          ImportDirective importDirective = directive;
          LibraryElement libraryElement = importDirective.uriElement;
          if (libraryElement != null) {
            _unusedImports.add(importDirective);
            //
            // Initialize prefixElementMap
            //
            if (importDirective.asToken != null) {
              SimpleIdentifier prefixIdentifier = importDirective.prefix;
              if (prefixIdentifier != null) {
                Element element = prefixIdentifier.staticElement;
                if (element is PrefixElement) {
                  PrefixElement prefixElementKey = element;
                  _prefixElementMap[prefixElementKey] = importDirective;
                }
              }
            }
            //
            // Initialize libraryMap: libraryElement -> importDirective
            //
            putIntoLibraryMap(libraryElement, importDirective);
            //
            // For this new addition to the libraryMap, also recursively add any exports from the
            // libraryElement
            //
            addAdditionalLibrariesForExports(libraryElement, importDirective, new List<LibraryElement>());
          }
        }
      }
    }
    // If there are no imports in this library, don't visit the identifiers in the library- there
    // can be no unused imports.
    if (_unusedImports.isEmpty) {
      return null;
    }
    if (_unusedImports.length > 1) {
      // order the list of unusedImports to find duplicates in faster than O(n^2) time
      List<ImportDirective> importDirectiveArray = new List.from(_unusedImports);
      importDirectiveArray.sort(ImportDirective.COMPARATOR);
      ImportDirective currentDirective = importDirectiveArray[0];
      for (int i = 1; i < importDirectiveArray.length; i++) {
        ImportDirective nextDirective = importDirectiveArray[i];
        if (ImportDirective.COMPARATOR(currentDirective, nextDirective) == 0) {
          // Add either the currentDirective or nextDirective depending on which comes second, this
          // guarantees that the first of the duplicates won't be highlighted.
          if (currentDirective.offset < nextDirective.offset) {
            _duplicateImports.add(nextDirective);
          } else {
            _duplicateImports.add(currentDirective);
          }
        }
        currentDirective = nextDirective;
      }
    }
    return super.visitCompilationUnit(node);
  }

  Object visitExportDirective(ExportDirective node) {
    visitMetadata(node.metadata);
    return null;
  }

  Object visitImportDirective(ImportDirective node) {
    visitMetadata(node.metadata);
    return null;
  }

  Object visitLibraryDirective(LibraryDirective node) {
    visitMetadata(node.metadata);
    return null;
  }

  Object visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (_unusedImports.isEmpty) {
      return null;
    }
    // If the prefixed identifier references some A.B, where A is a library prefix, then we can
    // lookup the associated ImportDirective in prefixElementMap and remove it from the
    // unusedImports list.
    SimpleIdentifier prefixIdentifier = node.prefix;
    Element element = prefixIdentifier.staticElement;
    if (element is PrefixElement) {
      _unusedImports.remove(_prefixElementMap[element]);
      return null;
    }
    // Otherwise, pass the prefixed identifier element and name onto visitIdentifier.
    return visitIdentifier(element, prefixIdentifier.name);
  }

  Object visitSimpleIdentifier(SimpleIdentifier node) {
    if (_unusedImports.isEmpty) {
      return null;
    }
    return visitIdentifier(node.staticElement, node.name);
  }

  void set inDefiningCompilationUnit(bool inDefiningCompilationUnit) {
    this._inDefiningCompilationUnit = inDefiningCompilationUnit;
  }

  /**
   * Recursively add any exported library elements into the [libraryMap].
   */
  void addAdditionalLibrariesForExports(LibraryElement library, ImportDirective importDirective, List<LibraryElement> exportPath) {
    if (exportPath.contains(library)) {
      return;
    }
    exportPath.add(library);
    for (LibraryElement exportedLibraryElt in library.exportedLibraries) {
      putIntoLibraryMap(exportedLibraryElt, importDirective);
      addAdditionalLibrariesForExports(exportedLibraryElt, importDirective, exportPath);
    }
  }

  /**
   * Lookup and return the [Namespace] from the [namespaceMap], if the map does not
   * have the computed namespace, compute it and cache it in the map. If the import directive is not
   * resolved or is not resolvable, `null` is returned.
   *
   * @param importDirective the import directive used to compute the returned namespace
   * @return the computed or looked up [Namespace]
   */
  Namespace computeNamespace(ImportDirective importDirective) {
    Namespace namespace = _namespaceMap[importDirective];
    if (namespace == null) {
      // If the namespace isn't in the namespaceMap, then compute and put it in the map
      ImportElement importElement = importDirective.element;
      if (importElement != null) {
        NamespaceBuilder builder = new NamespaceBuilder();
        namespace = builder.createImportNamespace(importElement);
        _namespaceMap[importDirective] = namespace;
      }
    }
    return namespace;
  }

  /**
   * The [libraryMap] is a mapping between a library elements and a list of import
   * directives, but when adding these mappings into the [libraryMap], this method can be
   * used to simply add the mapping between the library element an an import directive without
   * needing to check to see if a list needs to be created.
   */
  void putIntoLibraryMap(LibraryElement libraryElement, ImportDirective importDirective) {
    List<ImportDirective> importList = _libraryMap[libraryElement];
    if (importList == null) {
      importList = new List<ImportDirective>();
      _libraryMap[libraryElement] = importList;
    }
    importList.add(importDirective);
  }

  Object visitIdentifier(Element element, String name) {
    if (element == null) {
      return null;
    }
    // If the element is multiply defined then call this method recursively for each of the conflicting elements.
    if (element is MultiplyDefinedElement) {
      MultiplyDefinedElement multiplyDefinedElement = element;
      for (Element elt in multiplyDefinedElement.conflictingElements) {
        visitIdentifier(elt, name);
      }
      return null;
    } else if (element is PrefixElement) {
      _unusedImports.remove(_prefixElementMap[element]);
      return null;
    } else if (element.enclosingElement is! CompilationUnitElement) {
      // Identifiers that aren't a prefix element and whose enclosing element isn't a
      // CompilationUnit are ignored- this covers the case the identifier is a relative-reference,
      // a reference to an identifier not imported by this library.
      return null;
    }
    LibraryElement containingLibrary = element.library;
    if (containingLibrary == null) {
      return null;
    }
    // If the element is declared in the current library, return.
    if (_currentLibrary == containingLibrary) {
      return null;
    }
    List<ImportDirective> importsFromSameLibrary = _libraryMap[containingLibrary];
    if (importsFromSameLibrary == null) {
      return null;
    }
    if (importsFromSameLibrary.length == 1) {
      // If there is only one import directive for this library, then it must be the directive that
      // this element is imported with, remove it from the unusedImports list.
      ImportDirective usedImportDirective = importsFromSameLibrary[0];
      _unusedImports.remove(usedImportDirective);
    } else {
      // Otherwise, for each of the imported directives, use the namespaceMap to
      for (ImportDirective importDirective in importsFromSameLibrary) {
        // Get the namespace for this import
        Namespace namespace = computeNamespace(importDirective);
        if (namespace != null && namespace.get(name) != null) {
          _unusedImports.remove(importDirective);
        }
      }
    }
    return null;
  }

  /**
   * Given some [NodeList] of [Annotation]s, ensure that the identifiers are visited by
   * this visitor. Specifically, this covers the cases where AST nodes don't have their identifiers
   * visited by this visitor, but still need their annotations visited.
   *
   * @param annotations the list of annotations to visit
   */
  void visitMetadata(NodeList<Annotation> annotations) {
    for (Annotation annotation in annotations) {
      Identifier name = annotation.name;
      visitIdentifier(name.staticElement, name.name);
    }
  }
}

/**
 * Instances of the class `OverrideVerifier` visit all of the declarations in a compilation
 * unit to verify that if they have an override annotation it is being used correctly.
 */
class OverrideVerifier extends RecursiveAstVisitor<Object> {
  /**
   * The inheritance manager used to find overridden methods.
   */
  InheritanceManager _manager;

  /**
   * The error reporter used to report errors.
   */
  ErrorReporter _errorReporter;

  /**
   * Initialize a newly created verifier to look for inappropriate uses of the override annotation.
   *
   * @param manager the inheritance manager used to find overridden methods
   * @param errorReporter the error reporter used to report errors
   */
  OverrideVerifier(InheritanceManager manager, ErrorReporter errorReporter) {
    this._manager = manager;
    this._errorReporter = errorReporter;
  }

  Object visitMethodDeclaration(MethodDeclaration node) {
    ExecutableElement element = node.element;
    if (isOverride(element)) {
      if (getOverriddenMember(element) == null) {
        if (element is MethodElement) {
          _errorReporter.reportError2(HintCode.OVERRIDE_ON_NON_OVERRIDING_METHOD, node.name, []);
        } else if (element is PropertyAccessorElement) {
          if (element.isGetter) {
            _errorReporter.reportError2(HintCode.OVERRIDE_ON_NON_OVERRIDING_GETTER, node.name, []);
          } else {
            _errorReporter.reportError2(HintCode.OVERRIDE_ON_NON_OVERRIDING_SETTER, node.name, []);
          }
        }
      }
    }
    return super.visitMethodDeclaration(node);
  }

  /**
   * Return the member that overrides the given member.
   *
   * @param member the member that overrides the returned member
   * @return the member that overrides the given member
   */
  ExecutableElement getOverriddenMember(ExecutableElement member) {
    LibraryElement library = member.library;
    if (library == null) {
      return null;
    }
    ClassElement classElement = member.getAncestor((element) => element is ClassElement);
    if (classElement == null) {
      return null;
    }
    return _manager.lookupInheritance(classElement, member.name);
  }

  /**
   * Return `true` if the given element has an override annotation associated with it.
   *
   * @param element the element being tested
   * @return `true` if the element has an override annotation associated with it
   */
  bool isOverride(Element element) => element != null && element.isOverride;
}

/**
 * Instances of the class `PubVerifier` traverse an AST structure looking for deviations from
 * pub best practices.
 */
class PubVerifier extends RecursiveAstVisitor<Object> {
  static String _PUBSPEC_YAML = "pubspec.yaml";

  /**
   * The analysis context containing the sources to be analyzed
   */
  AnalysisContext _context;

  /**
   * The error reporter by which errors will be reported.
   */
  ErrorReporter _errorReporter;

  PubVerifier(AnalysisContext context, ErrorReporter errorReporter) {
    this._context = context;
    this._errorReporter = errorReporter;
  }

  Object visitImportDirective(ImportDirective directive) {
    return null;
  }

  /**
   * This verifies that the passed file import directive is not contained in a source inside a
   * package "lib" directory hierarchy referencing a source outside that package "lib" directory
   * hierarchy.
   *
   * @param uriLiteral the import URL (not `null`)
   * @param path the file path being verified (not `null`)
   * @return `true` if and only if an error code is generated on the passed node
   * @see PubSuggestionCode.FILE_IMPORT_INSIDE_LIB_REFERENCES_FILE_OUTSIDE
   */
  bool checkForFileImportInsideLibReferencesFileOutside(StringLiteral uriLiteral, String path) {
    Source source = getSource(uriLiteral);
    String fullName = getSourceFullName(source);
    if (fullName != null) {
      int pathIndex = 0;
      int fullNameIndex = fullName.length;
      while (pathIndex < path.length && StringUtilities.startsWith3(path, pathIndex, 0x2E, 0x2E, 0x2F)) {
        fullNameIndex = JavaString.lastIndexOf(fullName, '/', fullNameIndex);
        if (fullNameIndex < 4) {
          return false;
        }
        // Check for "/lib" at a specified place in the fullName
        if (StringUtilities.startsWith4(fullName, fullNameIndex - 4, 0x2F, 0x6C, 0x69, 0x62)) {
          String relativePubspecPath = path.substring(0, pathIndex + 3) + _PUBSPEC_YAML;
          Source pubspecSource = _context.sourceFactory.resolveUri(source, relativePubspecPath);
          if (_context.exists(pubspecSource)) {
            // Files inside the lib directory hierarchy should not reference files outside
            _errorReporter.reportError2(PubSuggestionCode.FILE_IMPORT_INSIDE_LIB_REFERENCES_FILE_OUTSIDE, uriLiteral, []);
          }
          return true;
        }
        pathIndex += 3;
      }
    }
    return false;
  }

  /**
   * This verifies that the passed file import directive is not contained in a source outside a
   * package "lib" directory hierarchy referencing a source inside that package "lib" directory
   * hierarchy.
   *
   * @param uriLiteral the import URL (not `null`)
   * @param path the file path being verified (not `null`)
   * @return `true` if and only if an error code is generated on the passed node
   * @see PubSuggestionCode.FILE_IMPORT_OUTSIDE_LIB_REFERENCES_FILE_INSIDE
   */
  bool checkForFileImportOutsideLibReferencesFileInside(StringLiteral uriLiteral, String path) {
    if (StringUtilities.startsWith4(path, 0, 0x6C, 0x69, 0x62, 0x2F)) {
      if (checkForFileImportOutsideLibReferencesFileInsideAtIndex(uriLiteral, path, 0)) {
        return true;
      }
    }
    int pathIndex = StringUtilities.indexOf5(path, 0, 0x2F, 0x6C, 0x69, 0x62, 0x2F);
    while (pathIndex != -1) {
      if (checkForFileImportOutsideLibReferencesFileInsideAtIndex(uriLiteral, path, pathIndex + 1)) {
        return true;
      }
      pathIndex = StringUtilities.indexOf5(path, pathIndex + 4, 0x2F, 0x6C, 0x69, 0x62, 0x2F);
    }
    return false;
  }

  bool checkForFileImportOutsideLibReferencesFileInsideAtIndex(StringLiteral uriLiteral, String path, int pathIndex) {
    Source source = getSource(uriLiteral);
    String relativePubspecPath = path.substring(0, pathIndex) + _PUBSPEC_YAML;
    Source pubspecSource = _context.sourceFactory.resolveUri(source, relativePubspecPath);
    if (!_context.exists(pubspecSource)) {
      return false;
    }
    String fullName = getSourceFullName(source);
    if (fullName != null) {
      if (StringUtilities.indexOf5(fullName, 0, 0x2F, 0x6C, 0x69, 0x62, 0x2F) < 0) {
        // Files outside the lib directory hierarchy should not reference files inside
        // ... use package: url instead
        _errorReporter.reportError2(PubSuggestionCode.FILE_IMPORT_OUTSIDE_LIB_REFERENCES_FILE_INSIDE, uriLiteral, []);
        return true;
      }
    }
    return false;
  }

  /**
   * This verifies that the passed package import directive does not contain ".."
   *
   * @param uriLiteral the import URL (not `null`)
   * @param path the path to be validated (not `null`)
   * @return `true` if and only if an error code is generated on the passed node
   * @see PubSuggestionCode.PACKAGE_IMPORT_CONTAINS_DOT_DOT
   */
  bool checkForPackageImportContainsDotDot(StringLiteral uriLiteral, String path) {
    if (StringUtilities.startsWith3(path, 0, 0x2E, 0x2E, 0x2F) || StringUtilities.indexOf4(path, 0, 0x2F, 0x2E, 0x2E, 0x2F) >= 0) {
      // Package import should not to contain ".."
      _errorReporter.reportError2(PubSuggestionCode.PACKAGE_IMPORT_CONTAINS_DOT_DOT, uriLiteral, []);
      return true;
    }
    return false;
  }

  /**
   * Answer the source associated with the compilation unit containing the given AST node.
   *
   * @param node the node (not `null`)
   * @return the source or `null` if it could not be determined
   */
  Source getSource(AstNode node) {
    Source source = null;
    CompilationUnit unit = node.getAncestor((node) => node is CompilationUnit);
    if (unit != null) {
      CompilationUnitElement element = unit.element;
      if (element != null) {
        source = element.source;
      }
    }
    return source;
  }

  /**
   * Answer the full name of the given source. The returned value will have all
   * [File#separatorChar] replace by '/'.
   *
   * @param source the source
   * @return the full name or `null` if it could not be determined
   */
  String getSourceFullName(Source source) {
    if (source != null) {
      String fullName = source.fullName;
      if (fullName != null) {
        return fullName.replaceAll(r'\', '/');
      }
    }
    return null;
  }
}

/**
 * Instances of the class `ToDoFinder` find to-do comments in Dart code.
 */
class ToDoFinder {
  /**
   * The error reporter by which to-do comments will be reported.
   */
  ErrorReporter _errorReporter;

  /**
   * Initialize a newly created to-do finder to report to-do comments to the given reporter.
   *
   * @param errorReporter the error reporter by which to-do comments will be reported
   */
  ToDoFinder(ErrorReporter errorReporter) {
    this._errorReporter = errorReporter;
  }

  /**
   * Search the comments in the given compilation unit for to-do comments and report an error for
   * each.
   *
   * @param unit the compilation unit containing the to-do comments
   */
  void findIn(CompilationUnit unit) {
    gatherTodoComments(unit.beginToken);
  }

  /**
   * Search the comment tokens reachable from the given token and create errors for each to-do
   * comment.
   *
   * @param token the head of the list of tokens being searched
   */
  void gatherTodoComments(sc.Token token) {
    while (token != null && token.type != sc.TokenType.EOF) {
      sc.Token commentToken = token.precedingComments;
      while (commentToken != null) {
        if (identical(commentToken.type, sc.TokenType.SINGLE_LINE_COMMENT) || identical(commentToken.type, sc.TokenType.MULTI_LINE_COMMENT)) {
          scrapeTodoComment(commentToken);
        }
        commentToken = commentToken.next;
      }
      token = token.next;
    }
  }

  /**
   * Look for user defined tasks in comments and convert them into info level analysis issues.
   *
   * @param commentToken the comment token to analyze
   */
  void scrapeTodoComment(sc.Token commentToken) {
    JavaPatternMatcher matcher = new JavaPatternMatcher(TodoCode.TODO_REGEX, commentToken.lexeme);
    if (matcher.find()) {
      int offset = commentToken.offset + matcher.start() + matcher.group(1).length;
      int length = matcher.group(2).length;
      _errorReporter.reportError4(TodoCode.TODO, offset, length, [matcher.group(2)]);
    }
  }
}

/**
 * Instances of the class `DeclarationMatcher` determine whether the element model defined by
 * a given AST structure matches an existing element model.
 */
class DeclarationMatcher extends RecursiveAstVisitor<Object> {
  /**
   * The compilation unit containing the AST nodes being visited.
   */
  CompilationUnitElement _enclosingUnit;

  /**
   * The function type alias containing the AST nodes being visited, or `null` if we are not
   * in the scope of a function type alias.
   */
  FunctionTypeAliasElement _enclosingAlias;

  /**
   * The class containing the AST nodes being visited, or `null` if we are not in the scope of
   * a class.
   */
  ClassElement _enclosingClass;

  /**
   * The method or function containing the AST nodes being visited, or `null` if we are not in
   * the scope of a method or function.
   */
  ExecutableElement _enclosingExecutable;

  /**
   * The parameter containing the AST nodes being visited, or `null` if we are not in the
   * scope of a parameter.
   */
  ParameterElement _enclosingParameter;

  /**
   * A set containing all of the elements in the element model that were defined by the old AST node
   * corresponding to the AST node being visited.
   */
  Set<Element> _allElements = new Set<Element>();

  /**
   * A set containing all of the elements in the element model that were defined by the old AST node
   * corresponding to the AST node being visited that have not already been matched to nodes in the
   * AST structure being visited.
   */
  Set<Element> _unmatchedElements = new Set<Element>();

  /**
   * Return `true` if the declarations within the given AST structure define an element model
   * that is equivalent to the corresponding elements rooted at the given element.
   *
   * @param node the AST structure being compared to the element model
   * @param element the root of the element model being compared to the AST structure
   * @return `true` if the AST structure defines the same elements as those in the given
   *         element model
   */
  bool matches(AstNode node, Element element) {
    captureEnclosingElements(element);
    gatherElements(element);
    try {
      node.accept(this);
    } on DeclarationMatcher_DeclarationMismatchException catch (exception) {
      return false;
    }
    return _unmatchedElements.isEmpty;
  }

  Object visitCatchClause(CatchClause node) {
    SimpleIdentifier exceptionParameter = node.exceptionParameter;
    if (exceptionParameter != null) {
      List<LocalVariableElement> localVariables = _enclosingExecutable.localVariables;
      LocalVariableElement exceptionElement = findIdentifier(localVariables, exceptionParameter);
      processElement(exceptionElement);
      SimpleIdentifier stackTraceParameter = node.stackTraceParameter;
      if (stackTraceParameter != null) {
        LocalVariableElement stackTraceElement = findIdentifier(localVariables, stackTraceParameter);
        processElement(stackTraceElement);
      }
    }
    return super.visitCatchClause(node);
  }

  Object visitClassDeclaration(ClassDeclaration node) {
    ClassElement outerClass = _enclosingClass;
    try {
      SimpleIdentifier className = node.name;
      _enclosingClass = findIdentifier(_enclosingUnit.types, className);
      processElement(_enclosingClass);
      if (!hasConstructor(node)) {
        ConstructorElement constructor = _enclosingClass.unnamedConstructor;
        if (constructor.isSynthetic) {
          processElement(constructor);
        }
      }
      return super.visitClassDeclaration(node);
    } finally {
      _enclosingClass = outerClass;
    }
  }

  Object visitClassTypeAlias(ClassTypeAlias node) {
    ClassElement outerClass = _enclosingClass;
    try {
      SimpleIdentifier className = node.name;
      _enclosingClass = findIdentifier(_enclosingUnit.types, className);
      processElement(_enclosingClass);
      return super.visitClassTypeAlias(node);
    } finally {
      _enclosingClass = outerClass;
    }
  }

  Object visitCompilationUnit(CompilationUnit node) {
    processElement(_enclosingUnit);
    return super.visitCompilationUnit(node);
  }

  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    ExecutableElement outerExecutable = _enclosingExecutable;
    try {
      SimpleIdentifier constructorName = node.name;
      if (constructorName == null) {
        _enclosingExecutable = _enclosingClass.unnamedConstructor;
      } else {
        _enclosingExecutable = _enclosingClass.getNamedConstructor(constructorName.name);
      }
      processElement(_enclosingExecutable);
      return super.visitConstructorDeclaration(node);
    } finally {
      _enclosingExecutable = outerExecutable;
    }
  }

  Object visitDeclaredIdentifier(DeclaredIdentifier node) {
    SimpleIdentifier variableName = node.identifier;
    LocalVariableElement element = findIdentifier(_enclosingExecutable.localVariables, variableName);
    processElement(element);
    return super.visitDeclaredIdentifier(node);
  }

  Object visitDefaultFormalParameter(DefaultFormalParameter node) {
    SimpleIdentifier parameterName = node.parameter.identifier;
    ParameterElement element = getElementForParameter(node, parameterName);
    Expression defaultValue = node.defaultValue;
    if (defaultValue != null) {
      ExecutableElement outerExecutable = _enclosingExecutable;
      try {
        if (element == null) {
        } else {
          _enclosingExecutable = element.initializer;
        }
        defaultValue.accept(this);
      } finally {
        _enclosingExecutable = outerExecutable;
      }
      processElement(_enclosingExecutable);
    }
    ParameterElement outerParameter = _enclosingParameter;
    try {
      _enclosingParameter = element;
      processElement(_enclosingParameter);
      return super.visitDefaultFormalParameter(node);
    } finally {
      _enclosingParameter = outerParameter;
    }
  }

  Object visitExportDirective(ExportDirective node) {
    String uri = getStringValue(node.uri);
    if (uri != null) {
      LibraryElement library = _enclosingUnit.library;
      ExportElement exportElement = findExport(library.exports, _enclosingUnit.context.sourceFactory.resolveUri(_enclosingUnit.source, uri));
      processElement(exportElement);
    }
    return super.visitExportDirective(node);
  }

  Object visitFieldFormalParameter(FieldFormalParameter node) {
    if (node.parent is! DefaultFormalParameter) {
      SimpleIdentifier parameterName = node.identifier;
      ParameterElement element = getElementForParameter(node, parameterName);
      ParameterElement outerParameter = _enclosingParameter;
      try {
        _enclosingParameter = element;
        processElement(_enclosingParameter);
        return super.visitFieldFormalParameter(node);
      } finally {
        _enclosingParameter = outerParameter;
      }
    } else {
      return super.visitFieldFormalParameter(node);
    }
  }

  Object visitFunctionDeclaration(FunctionDeclaration node) {
    ExecutableElement outerExecutable = _enclosingExecutable;
    try {
      SimpleIdentifier functionName = node.name;
      sc.Token property = node.propertyKeyword;
      if (property == null) {
        if (_enclosingExecutable != null) {
          _enclosingExecutable = findIdentifier(_enclosingExecutable.functions, functionName);
        } else {
          _enclosingExecutable = findIdentifier(_enclosingUnit.functions, functionName);
        }
      } else {
        PropertyAccessorElement accessor = findIdentifier(_enclosingUnit.accessors, functionName);
        if (identical((property as sc.KeywordToken).keyword, sc.Keyword.SET)) {
          accessor = accessor.variable.setter;
        }
        _enclosingExecutable = accessor;
      }
      processElement(_enclosingExecutable);
      return super.visitFunctionDeclaration(node);
    } finally {
      _enclosingExecutable = outerExecutable;
    }
  }

  Object visitFunctionExpression(FunctionExpression node) {
    if (node.parent is! FunctionDeclaration) {
      FunctionElement element = findAtOffset(_enclosingExecutable.functions, node.beginToken.offset);
      processElement(element);
    }
    ExecutableElement outerExecutable = _enclosingExecutable;
    try {
      _enclosingExecutable = node.element;
      processElement(_enclosingExecutable);
      return super.visitFunctionExpression(node);
    } finally {
      _enclosingExecutable = outerExecutable;
    }
  }

  Object visitFunctionTypeAlias(FunctionTypeAlias node) {
    FunctionTypeAliasElement outerAlias = _enclosingAlias;
    try {
      SimpleIdentifier aliasName = node.name;
      _enclosingAlias = findIdentifier(_enclosingUnit.functionTypeAliases, aliasName);
      processElement(_enclosingAlias);
      return super.visitFunctionTypeAlias(node);
    } finally {
      _enclosingAlias = outerAlias;
    }
  }

  Object visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    if (node.parent is! DefaultFormalParameter) {
      SimpleIdentifier parameterName = node.identifier;
      ParameterElement element = getElementForParameter(node, parameterName);
      ParameterElement outerParameter = _enclosingParameter;
      try {
        _enclosingParameter = element;
        processElement(_enclosingParameter);
        return super.visitFunctionTypedFormalParameter(node);
      } finally {
        _enclosingParameter = outerParameter;
      }
    } else {
      return super.visitFunctionTypedFormalParameter(node);
    }
  }

  Object visitImportDirective(ImportDirective node) {
    String uri = getStringValue(node.uri);
    if (uri != null) {
      LibraryElement library = _enclosingUnit.library;
      ImportElement importElement = findImport(library.imports, _enclosingUnit.context.sourceFactory.resolveUri(_enclosingUnit.source, uri), node.prefix);
      processElement(importElement);
    }
    return super.visitImportDirective(node);
  }

  Object visitLabeledStatement(LabeledStatement node) {
    for (Label label in node.labels) {
      SimpleIdentifier labelName = label.label;
      LabelElement element = findIdentifier(_enclosingExecutable.labels, labelName);
      processElement(element);
    }
    return super.visitLabeledStatement(node);
  }

  Object visitMethodDeclaration(MethodDeclaration node) {
    ExecutableElement outerExecutable = _enclosingExecutable;
    try {
      sc.Token property = node.propertyKeyword;
      SimpleIdentifier methodName = node.name;
      String nameOfMethod = methodName.name;
      if (nameOfMethod == sc.TokenType.MINUS.lexeme && node.parameters.parameters.length == 0) {
        nameOfMethod = "unary-";
      }
      if (property == null) {
        _enclosingExecutable = findWithNameAndOffset(_enclosingClass.methods, nameOfMethod, methodName.offset);
        methodName.staticElement = _enclosingExecutable;
      } else {
        PropertyAccessorElement accessor = findIdentifier(_enclosingClass.accessors, methodName);
        if (identical((property as sc.KeywordToken).keyword, sc.Keyword.SET)) {
          accessor = accessor.variable.setter;
          methodName.staticElement = accessor;
        }
        _enclosingExecutable = accessor;
      }
      processElement(_enclosingExecutable);
      return super.visitMethodDeclaration(node);
    } finally {
      _enclosingExecutable = outerExecutable;
    }
  }

  Object visitPartDirective(PartDirective node) {
    String uri = getStringValue(node.uri);
    if (uri != null) {
      Source partSource = _enclosingUnit.context.sourceFactory.resolveUri(_enclosingUnit.source, uri);
      CompilationUnitElement element = findPart(_enclosingUnit.library.parts, partSource);
      processElement(element);
    }
    return super.visitPartDirective(node);
  }

  Object visitSimpleFormalParameter(SimpleFormalParameter node) {
    if (node.parent is! DefaultFormalParameter) {
      SimpleIdentifier parameterName = node.identifier;
      ParameterElement element = getElementForParameter(node, parameterName);
      ParameterElement outerParameter = _enclosingParameter;
      try {
        _enclosingParameter = element;
        processElement(_enclosingParameter);
        return super.visitSimpleFormalParameter(node);
      } finally {
        _enclosingParameter = outerParameter;
      }
    } else {
    }
    return super.visitSimpleFormalParameter(node);
  }

  Object visitSwitchCase(SwitchCase node) {
    for (Label label in node.labels) {
      SimpleIdentifier labelName = label.label;
      LabelElement element = findIdentifier(_enclosingExecutable.labels, labelName);
      processElement(element);
    }
    return super.visitSwitchCase(node);
  }

  Object visitSwitchDefault(SwitchDefault node) {
    for (Label label in node.labels) {
      SimpleIdentifier labelName = label.label;
      LabelElement element = findIdentifier(_enclosingExecutable.labels, labelName);
      processElement(element);
    }
    return super.visitSwitchDefault(node);
  }

  Object visitTypeParameter(TypeParameter node) {
    SimpleIdentifier parameterName = node.name;
    TypeParameterElement element = null;
    if (_enclosingClass != null) {
      element = findIdentifier(_enclosingClass.typeParameters, parameterName);
    } else if (_enclosingAlias != null) {
      element = findIdentifier(_enclosingAlias.typeParameters, parameterName);
    }
    processElement(element);
    return super.visitTypeParameter(node);
  }

  Object visitVariableDeclaration(VariableDeclaration node) {
    VariableElement element = null;
    SimpleIdentifier variableName = node.name;
    if (_enclosingExecutable != null) {
      element = findIdentifier(_enclosingExecutable.localVariables, variableName);
    }
    if (element == null && _enclosingClass != null) {
      element = findIdentifier(_enclosingClass.fields, variableName);
    }
    if (element == null && _enclosingUnit != null) {
      element = findIdentifier(_enclosingUnit.topLevelVariables, variableName);
    }
    Expression initializer = node.initializer;
    if (initializer != null) {
      ExecutableElement outerExecutable = _enclosingExecutable;
      try {
        if (element == null) {
        } else {
          _enclosingExecutable = element.initializer;
        }
        processElement(element);
        processElement(_enclosingExecutable);
        return super.visitVariableDeclaration(node);
      } finally {
        _enclosingExecutable = outerExecutable;
      }
    }
    return super.visitVariableDeclaration(node);
  }

  void processElement(Element element) {
    if (element == null) {
      throw new DeclarationMatcher_DeclarationMismatchException();
    }
    if (!_allElements.contains(element)) {
      throw new DeclarationMatcher_DeclarationMismatchException();
    }
    _unmatchedElements.remove(element);
  }

  /**
   * Given that the comparison is to begin with the given element, capture the enclosing elements
   * that might be used while performing the comparison.
   *
   * @param element the element corresponding to the AST structure to be compared
   */
  void captureEnclosingElements(Element element) {
    Element parent = element is CompilationUnitElement ? element : element.enclosingElement;
    while (parent != null) {
      if (parent is CompilationUnitElement) {
        _enclosingUnit = parent as CompilationUnitElement;
      } else if (parent is ClassElement) {
        if (_enclosingClass == null) {
          _enclosingClass = parent as ClassElement;
        }
      } else if (parent is FunctionTypeAliasElement) {
        if (_enclosingAlias == null) {
          _enclosingAlias = parent as FunctionTypeAliasElement;
        }
      } else if (parent is ExecutableElement) {
        if (_enclosingExecutable == null) {
          _enclosingExecutable = parent as ExecutableElement;
        }
      } else if (parent is ParameterElement) {
        if (_enclosingParameter == null) {
          _enclosingParameter = parent as ParameterElement;
        }
      }
      parent = parent.enclosingElement;
    }
  }

  /**
   * Return the element in the given array of elements that was created for the declaration at the
   * given offset. This method should only be used when there is no name
   *
   * @param elements the elements of the appropriate kind that exist in the current context
   * @param offset the offset of the name of the element to be returned
   * @return the element at the given offset
   */
  Element findAtOffset(List<Element> elements, int offset) => findWithNameAndOffset(elements, "", offset);

  /**
   * Return the export element from the given array whose library has the given source, or
   * `null` if there is no such export.
   *
   * @param exports the export elements being searched
   * @param source the source of the library associated with the export element to being searched
   *          for
   * @return the export element whose library has the given source
   */
  ExportElement findExport(List<ExportElement> exports, Source source) {
    for (ExportElement export in exports) {
      if (export.exportedLibrary.source == source) {
        return export;
      }
    }
    return null;
  }

  /**
   * Return the element in the given array of elements that was created for the declaration with the
   * given name.
   *
   * @param elements the elements of the appropriate kind that exist in the current context
   * @param identifier the name node in the declaration of the element to be returned
   * @return the element created for the declaration with the given name
   */
  Element findIdentifier(List<Element> elements, SimpleIdentifier identifier) => findWithNameAndOffset(elements, identifier.name, identifier.offset);

  /**
   * Return the import element from the given array whose library has the given source and that has
   * the given prefix, or `null` if there is no such import.
   *
   * @param imports the import elements being searched
   * @param source the source of the library associated with the import element to being searched
   *          for
   * @param prefix the prefix with which the library was imported
   * @return the import element whose library has the given source and prefix
   */
  ImportElement findImport(List<ImportElement> imports, Source source, SimpleIdentifier prefix) {
    for (ImportElement element in imports) {
      if (element.importedLibrary.source == source) {
        PrefixElement prefixElement = element.prefix;
        if (prefix == null) {
          if (prefixElement == null) {
            return element;
          }
        } else {
          if (prefixElement != null && prefix.name == prefixElement.displayName) {
            return element;
          }
        }
      }
    }
    return null;
  }

  /**
   * Return the element for the part with the given source, or `null` if there is no element
   * for the given source.
   *
   * @param parts the elements for the parts
   * @param partSource the source for the part whose element is to be returned
   * @return the element for the part with the given source
   */
  CompilationUnitElement findPart(List<CompilationUnitElement> parts, Source partSource) {
    for (CompilationUnitElement part in parts) {
      if (part.source == partSource) {
        return part;
      }
    }
    return null;
  }

  /**
   * Return the element in the given array of elements that was created for the declaration with the
   * given name at the given offset.
   *
   * @param elements the elements of the appropriate kind that exist in the current context
   * @param name the name of the element to be returned
   * @param offset the offset of the name of the element to be returned
   * @return the element with the given name and offset
   */
  Element findWithNameAndOffset(List<Element> elements, String name, int offset) {
    for (Element element in elements) {
      if (element.displayName == name && element.nameOffset == offset) {
        return element;
      }
    }
    return null;
  }

  void gatherElements(Element element) {
    element.accept(new GeneralizingElementVisitor_DeclarationMatcher_gatherElements(this));
  }

  /**
   * Search the most closely enclosing list of parameters for a parameter with the given name.
   *
   * @param node the node defining the parameter with the given name
   * @param parameterName the name of the parameter being searched for
   * @return the element representing the parameter with that name
   */
  ParameterElement getElementForParameter(FormalParameter node, SimpleIdentifier parameterName) {
    List<ParameterElement> parameters = null;
    if (_enclosingParameter != null) {
      parameters = _enclosingParameter.parameters;
    }
    if (parameters == null && _enclosingExecutable != null) {
      parameters = _enclosingExecutable.parameters;
    }
    if (parameters == null && _enclosingAlias != null) {
      parameters = _enclosingAlias.parameters;
    }
    return parameters == null ? null : findIdentifier(parameters, parameterName);
  }

  /**
   * Return the value of the given string literal, or `null` if the string is not a constant
   * string without any string interpolation.
   *
   * @param literal the string literal whose value is to be returned
   * @return the value of the given string literal
   */
  String getStringValue(StringLiteral literal) {
    if (literal is StringInterpolation) {
      return null;
    }
    return literal.stringValue;
  }

  /**
   * Return `true` if the given class defines at least one constructor.
   *
   * @param node the class being tested
   * @return `true` if the class defines at least one constructor
   */
  bool hasConstructor(ClassDeclaration node) {
    for (ClassMember member in node.members) {
      if (member is ConstructorDeclaration) {
        return true;
      }
    }
    return false;
  }
}

/**
 * Instances of the class `DeclarationMismatchException` represent an exception that is
 * thrown when the element model defined by a given AST structure does not match an existing
 * element model.
 */
class DeclarationMatcher_DeclarationMismatchException extends RuntimeException {
}

class GeneralizingElementVisitor_DeclarationMatcher_gatherElements extends GeneralizingElementVisitor<Object> {
  final DeclarationMatcher DeclarationMatcher_this;

  GeneralizingElementVisitor_DeclarationMatcher_gatherElements(this.DeclarationMatcher_this) : super();

  Object visitElement(Element element) {
    DeclarationMatcher_this._allElements.add(element);
    DeclarationMatcher_this._unmatchedElements.add(element);
    return super.visitElement(element);
  }
}

/**
 * Instances of the class `DeclarationResolver` are used to resolve declarations in an AST
 * structure to already built elements.
 */
class DeclarationResolver extends RecursiveAstVisitor<Object> {
  /**
   * The compilation unit containing the AST nodes being visited.
   */
  CompilationUnitElement _enclosingUnit;

  /**
   * The function type alias containing the AST nodes being visited, or `null` if we are not
   * in the scope of a function type alias.
   */
  FunctionTypeAliasElement _enclosingAlias;

  /**
   * The class containing the AST nodes being visited, or `null` if we are not in the scope of
   * a class.
   */
  ClassElement _enclosingClass;

  /**
   * The method or function containing the AST nodes being visited, or `null` if we are not in
   * the scope of a method or function.
   */
  ExecutableElement _enclosingExecutable;

  /**
   * The parameter containing the AST nodes being visited, or `null` if we are not in the
   * scope of a parameter.
   */
  ParameterElement _enclosingParameter;

  /**
   * Resolve the declarations within the given compilation unit to the elements rooted at the given
   * element.
   *
   * @param unit the compilation unit to be resolved
   * @param element the root of the element model used to resolve the AST nodes
   */
  void resolve(CompilationUnit unit, CompilationUnitElement element) {
    _enclosingUnit = element;
    unit.element = element;
    unit.accept(this);
  }

  Object visitCatchClause(CatchClause node) {
    SimpleIdentifier exceptionParameter = node.exceptionParameter;
    if (exceptionParameter != null) {
      List<LocalVariableElement> localVariables = _enclosingExecutable.localVariables;
      findIdentifier(localVariables, exceptionParameter);
      SimpleIdentifier stackTraceParameter = node.stackTraceParameter;
      if (stackTraceParameter != null) {
        findIdentifier(localVariables, stackTraceParameter);
      }
    }
    return super.visitCatchClause(node);
  }

  Object visitClassDeclaration(ClassDeclaration node) {
    ClassElement outerClass = _enclosingClass;
    try {
      SimpleIdentifier className = node.name;
      _enclosingClass = findIdentifier(_enclosingUnit.types, className);
      return super.visitClassDeclaration(node);
    } finally {
      _enclosingClass = outerClass;
    }
  }

  Object visitClassTypeAlias(ClassTypeAlias node) {
    ClassElement outerClass = _enclosingClass;
    try {
      SimpleIdentifier className = node.name;
      _enclosingClass = findIdentifier(_enclosingUnit.types, className);
      return super.visitClassTypeAlias(node);
    } finally {
      _enclosingClass = outerClass;
    }
  }

  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    ExecutableElement outerExecutable = _enclosingExecutable;
    try {
      SimpleIdentifier constructorName = node.name;
      if (constructorName == null) {
        _enclosingExecutable = _enclosingClass.unnamedConstructor;
      } else {
        _enclosingExecutable = _enclosingClass.getNamedConstructor(constructorName.name);
        constructorName.staticElement = _enclosingExecutable;
      }
      node.element = _enclosingExecutable as ConstructorElement;
      return super.visitConstructorDeclaration(node);
    } finally {
      _enclosingExecutable = outerExecutable;
    }
  }

  Object visitDeclaredIdentifier(DeclaredIdentifier node) {
    SimpleIdentifier variableName = node.identifier;
    findIdentifier(_enclosingExecutable.localVariables, variableName);
    return super.visitDeclaredIdentifier(node);
  }

  Object visitDefaultFormalParameter(DefaultFormalParameter node) {
    SimpleIdentifier parameterName = node.parameter.identifier;
    ParameterElement element = getElementForParameter(node, parameterName);
    Expression defaultValue = node.defaultValue;
    if (defaultValue != null) {
      ExecutableElement outerExecutable = _enclosingExecutable;
      try {
        if (element == null) {
        } else {
          _enclosingExecutable = element.initializer;
        }
        defaultValue.accept(this);
      } finally {
        _enclosingExecutable = outerExecutable;
      }
    }
    ParameterElement outerParameter = _enclosingParameter;
    try {
      _enclosingParameter = element;
      return super.visitDefaultFormalParameter(node);
    } finally {
      _enclosingParameter = outerParameter;
    }
  }

  Object visitExportDirective(ExportDirective node) {
    String uri = getStringValue(node.uri);
    if (uri != null) {
      LibraryElement library = _enclosingUnit.library;
      ExportElement exportElement = findExport(library.exports, _enclosingUnit.context.sourceFactory.resolveUri(_enclosingUnit.source, uri));
      node.element = exportElement;
    }
    return super.visitExportDirective(node);
  }

  Object visitFieldFormalParameter(FieldFormalParameter node) {
    if (node.parent is! DefaultFormalParameter) {
      SimpleIdentifier parameterName = node.identifier;
      ParameterElement element = getElementForParameter(node, parameterName);
      ParameterElement outerParameter = _enclosingParameter;
      try {
        _enclosingParameter = element;
        return super.visitFieldFormalParameter(node);
      } finally {
        _enclosingParameter = outerParameter;
      }
    } else {
      return super.visitFieldFormalParameter(node);
    }
  }

  Object visitFunctionDeclaration(FunctionDeclaration node) {
    ExecutableElement outerExecutable = _enclosingExecutable;
    try {
      SimpleIdentifier functionName = node.name;
      sc.Token property = node.propertyKeyword;
      if (property == null) {
        if (_enclosingExecutable != null) {
          _enclosingExecutable = findIdentifier(_enclosingExecutable.functions, functionName);
        } else {
          _enclosingExecutable = findIdentifier(_enclosingUnit.functions, functionName);
        }
      } else {
        PropertyAccessorElement accessor = findIdentifier(_enclosingUnit.accessors, functionName);
        if (identical((property as sc.KeywordToken).keyword, sc.Keyword.SET)) {
          accessor = accessor.variable.setter;
          functionName.staticElement = accessor;
        }
        _enclosingExecutable = accessor;
      }
      node.functionExpression.element = _enclosingExecutable;
      return super.visitFunctionDeclaration(node);
    } finally {
      _enclosingExecutable = outerExecutable;
    }
  }

  Object visitFunctionExpression(FunctionExpression node) {
    if (node.parent is! FunctionDeclaration) {
      FunctionElement element = findAtOffset(_enclosingExecutable.functions, node.beginToken.offset);
      node.element = element;
    }
    ExecutableElement outerExecutable = _enclosingExecutable;
    try {
      _enclosingExecutable = node.element;
      return super.visitFunctionExpression(node);
    } finally {
      _enclosingExecutable = outerExecutable;
    }
  }

  Object visitFunctionTypeAlias(FunctionTypeAlias node) {
    FunctionTypeAliasElement outerAlias = _enclosingAlias;
    try {
      SimpleIdentifier aliasName = node.name;
      _enclosingAlias = findIdentifier(_enclosingUnit.functionTypeAliases, aliasName);
      return super.visitFunctionTypeAlias(node);
    } finally {
      _enclosingAlias = outerAlias;
    }
  }

  Object visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    if (node.parent is! DefaultFormalParameter) {
      SimpleIdentifier parameterName = node.identifier;
      ParameterElement element = getElementForParameter(node, parameterName);
      ParameterElement outerParameter = _enclosingParameter;
      try {
        _enclosingParameter = element;
        return super.visitFunctionTypedFormalParameter(node);
      } finally {
        _enclosingParameter = outerParameter;
      }
    } else {
      return super.visitFunctionTypedFormalParameter(node);
    }
  }

  Object visitImportDirective(ImportDirective node) {
    String uri = getStringValue(node.uri);
    if (uri != null) {
      LibraryElement library = _enclosingUnit.library;
      ImportElement importElement = findImport(library.imports, _enclosingUnit.context.sourceFactory.resolveUri(_enclosingUnit.source, uri), node.prefix);
      node.element = importElement;
    }
    return super.visitImportDirective(node);
  }

  Object visitLabeledStatement(LabeledStatement node) {
    for (Label label in node.labels) {
      SimpleIdentifier labelName = label.label;
      findIdentifier(_enclosingExecutable.labels, labelName);
    }
    return super.visitLabeledStatement(node);
  }

  Object visitLibraryDirective(LibraryDirective node) {
    node.element = _enclosingUnit.library;
    return super.visitLibraryDirective(node);
  }

  Object visitMethodDeclaration(MethodDeclaration node) {
    ExecutableElement outerExecutable = _enclosingExecutable;
    try {
      sc.Token property = node.propertyKeyword;
      SimpleIdentifier methodName = node.name;
      String nameOfMethod = methodName.name;
      if (nameOfMethod == sc.TokenType.MINUS.lexeme && node.parameters.parameters.length == 0) {
        nameOfMethod = "unary-";
      }
      if (property == null) {
        _enclosingExecutable = findWithNameAndOffset(_enclosingClass.methods, nameOfMethod, methodName.offset);
        methodName.staticElement = _enclosingExecutable;
      } else {
        PropertyAccessorElement accessor = findIdentifier(_enclosingClass.accessors, methodName);
        if (identical((property as sc.KeywordToken).keyword, sc.Keyword.SET)) {
          accessor = accessor.variable.setter;
          methodName.staticElement = accessor;
        }
        _enclosingExecutable = accessor;
      }
      return super.visitMethodDeclaration(node);
    } finally {
      _enclosingExecutable = outerExecutable;
    }
  }

  Object visitPartDirective(PartDirective node) {
    String uri = getStringValue(node.uri);
    if (uri != null) {
      Source partSource = _enclosingUnit.context.sourceFactory.resolveUri(_enclosingUnit.source, uri);
      node.element = findPart(_enclosingUnit.library.parts, partSource);
    }
    return super.visitPartDirective(node);
  }

  Object visitPartOfDirective(PartOfDirective node) {
    node.element = _enclosingUnit.library;
    return super.visitPartOfDirective(node);
  }

  Object visitSimpleFormalParameter(SimpleFormalParameter node) {
    if (node.parent is! DefaultFormalParameter) {
      SimpleIdentifier parameterName = node.identifier;
      ParameterElement element = getElementForParameter(node, parameterName);
      ParameterElement outerParameter = _enclosingParameter;
      try {
        _enclosingParameter = element;
        return super.visitSimpleFormalParameter(node);
      } finally {
        _enclosingParameter = outerParameter;
      }
    } else {
    }
    return super.visitSimpleFormalParameter(node);
  }

  Object visitSwitchCase(SwitchCase node) {
    for (Label label in node.labels) {
      SimpleIdentifier labelName = label.label;
      findIdentifier(_enclosingExecutable.labels, labelName);
    }
    return super.visitSwitchCase(node);
  }

  Object visitSwitchDefault(SwitchDefault node) {
    for (Label label in node.labels) {
      SimpleIdentifier labelName = label.label;
      findIdentifier(_enclosingExecutable.labels, labelName);
    }
    return super.visitSwitchDefault(node);
  }

  Object visitTypeParameter(TypeParameter node) {
    SimpleIdentifier parameterName = node.name;
    if (_enclosingClass != null) {
      findIdentifier(_enclosingClass.typeParameters, parameterName);
    } else if (_enclosingAlias != null) {
      findIdentifier(_enclosingAlias.typeParameters, parameterName);
    }
    return super.visitTypeParameter(node);
  }

  Object visitVariableDeclaration(VariableDeclaration node) {
    VariableElement element = null;
    SimpleIdentifier variableName = node.name;
    if (_enclosingExecutable != null) {
      element = findIdentifier(_enclosingExecutable.localVariables, variableName);
    }
    if (element == null && _enclosingClass != null) {
      element = findIdentifier(_enclosingClass.fields, variableName);
    }
    if (element == null && _enclosingUnit != null) {
      element = findIdentifier(_enclosingUnit.topLevelVariables, variableName);
    }
    Expression initializer = node.initializer;
    if (initializer != null) {
      ExecutableElement outerExecutable = _enclosingExecutable;
      try {
        if (element == null) {
        } else {
          _enclosingExecutable = element.initializer;
        }
        return super.visitVariableDeclaration(node);
      } finally {
        _enclosingExecutable = outerExecutable;
      }
    }
    return super.visitVariableDeclaration(node);
  }

  /**
   * Return the element in the given array of elements that was created for the declaration at the
   * given offset. This method should only be used when there is no name
   *
   * @param elements the elements of the appropriate kind that exist in the current context
   * @param offset the offset of the name of the element to be returned
   * @return the element at the given offset
   */
  Element findAtOffset(List<Element> elements, int offset) => findWithNameAndOffset(elements, "", offset);

  /**
   * Return the export element from the given array whose library has the given source, or
   * `null` if there is no such export.
   *
   * @param exports the export elements being searched
   * @param source the source of the library associated with the export element to being searched
   *          for
   * @return the export element whose library has the given source
   */
  ExportElement findExport(List<ExportElement> exports, Source source) {
    for (ExportElement export in exports) {
      if (export.exportedLibrary.source == source) {
        return export;
      }
    }
    return null;
  }

  /**
   * Return the element in the given array of elements that was created for the declaration with the
   * given name.
   *
   * @param elements the elements of the appropriate kind that exist in the current context
   * @param identifier the name node in the declaration of the element to be returned
   * @return the element created for the declaration with the given name
   */
  Element findIdentifier(List<Element> elements, SimpleIdentifier identifier) {
    Element element = findWithNameAndOffset(elements, identifier.name, identifier.offset);
    identifier.staticElement = element;
    return element;
  }

  /**
   * Return the import element from the given array whose library has the given source and that has
   * the given prefix, or `null` if there is no such import.
   *
   * @param imports the import elements being searched
   * @param source the source of the library associated with the import element to being searched
   *          for
   * @param prefix the prefix with which the library was imported
   * @return the import element whose library has the given source and prefix
   */
  ImportElement findImport(List<ImportElement> imports, Source source, SimpleIdentifier prefix) {
    for (ImportElement element in imports) {
      if (element.importedLibrary.source == source) {
        PrefixElement prefixElement = element.prefix;
        if (prefix == null) {
          if (prefixElement == null) {
            return element;
          }
        } else {
          if (prefixElement != null && prefix.name == prefixElement.displayName) {
            return element;
          }
        }
      }
    }
    return null;
  }

  /**
   * Return the element for the part with the given source, or `null` if there is no element
   * for the given source.
   *
   * @param parts the elements for the parts
   * @param partSource the source for the part whose element is to be returned
   * @return the element for the part with the given source
   */
  CompilationUnitElement findPart(List<CompilationUnitElement> parts, Source partSource) {
    for (CompilationUnitElement part in parts) {
      if (part.source == partSource) {
        return part;
      }
    }
    return null;
  }

  /**
   * Return the element in the given array of elements that was created for the declaration with the
   * given name at the given offset.
   *
   * @param elements the elements of the appropriate kind that exist in the current context
   * @param name the name of the element to be returned
   * @param offset the offset of the name of the element to be returned
   * @return the element with the given name and offset
   */
  Element findWithNameAndOffset(List<Element> elements, String name, int offset) {
    for (Element element in elements) {
      if (element.displayName == name && element.nameOffset == offset) {
        return element;
      }
    }
    return null;
  }

  /**
   * Search the most closely enclosing list of parameters for a parameter with the given name.
   *
   * @param node the node defining the parameter with the given name
   * @param parameterName the name of the parameter being searched for
   * @return the element representing the parameter with that name
   */
  ParameterElement getElementForParameter(FormalParameter node, SimpleIdentifier parameterName) {
    List<ParameterElement> parameters = null;
    if (_enclosingParameter != null) {
      parameters = _enclosingParameter.parameters;
    }
    if (parameters == null && _enclosingExecutable != null) {
      parameters = _enclosingExecutable.parameters;
    }
    if (parameters == null && _enclosingAlias != null) {
      parameters = _enclosingAlias.parameters;
    }
    ParameterElement element = parameters == null ? null : findIdentifier(parameters, parameterName);
    if (element == null) {
      PrintStringWriter writer = new PrintStringWriter();
      writer.println("Invalid state found in the Analysis Engine:");
      writer.println("DeclarationResolver.getElementForParameter() is visiting a parameter that does not appear to be in a method or function.");
      writer.println("Ancestors:");
      AstNode parent = node.parent;
      while (parent != null) {
        writer.println(parent.runtimeType.toString());
        writer.println("---------");
        parent = parent.parent;
      }
      AnalysisEngine.instance.logger.logError2(writer.toString(), new AnalysisException());
    }
    return element;
  }

  /**
   * Return the value of the given string literal, or `null` if the string is not a constant
   * string without any string interpolation.
   *
   * @param literal the string literal whose value is to be returned
   * @return the value of the given string literal
   */
  String getStringValue(StringLiteral literal) {
    if (literal is StringInterpolation) {
      return null;
    }
    return literal.stringValue;
  }
}

/**
 * Instances of the class `ElementResolver` are used by instances of [ResolverVisitor]
 * to resolve references within the AST structure to the elements being referenced. The requirements
 * for the element resolver are:
 * <ol>
 * * Every [SimpleIdentifier] should be resolved to the element to which it refers.
 * Specifically:
 * * An identifier within the declaration of that name should resolve to the element being
 * declared.
 * * An identifier denoting a prefix should resolve to the element representing the import that
 * defines the prefix (an [ImportElement]).
 * * An identifier denoting a variable should resolve to the element representing the variable (a
 * [VariableElement]).
 * * An identifier denoting a parameter should resolve to the element representing the parameter
 * (a [ParameterElement]).
 * * An identifier denoting a field should resolve to the element representing the getter or
 * setter being invoked (a [PropertyAccessorElement]).
 * * An identifier denoting the name of a method or function being invoked should resolve to the
 * element representing the method or function (a [ExecutableElement]).
 * * An identifier denoting a label should resolve to the element representing the label (a
 * [LabelElement]).
 * The identifiers within directives are exceptions to this rule and are covered below.
 * * Every node containing a token representing an operator that can be overridden (
 * [BinaryExpression], [PrefixExpression], [PostfixExpression]) should resolve to
 * the element representing the method invoked by that operator (a [MethodElement]).
 * * Every [FunctionExpressionInvocation] should resolve to the element representing the
 * function being invoked (a [FunctionElement]). This will be the same element as that to
 * which the name is resolved if the function has a name, but is provided for those cases where an
 * unnamed function is being invoked.
 * * Every [LibraryDirective] and [PartOfDirective] should resolve to the element
 * representing the library being specified by the directive (a [LibraryElement]) unless, in
 * the case of a part-of directive, the specified library does not exist.
 * * Every [ImportDirective] and [ExportDirective] should resolve to the element
 * representing the library being specified by the directive unless the specified library does not
 * exist (an [ImportElement] or [ExportElement]).
 * * The identifier representing the prefix in an [ImportDirective] should resolve to the
 * element representing the prefix (a [PrefixElement]).
 * * The identifiers in the hide and show combinators in [ImportDirective]s and
 * [ExportDirective]s should resolve to the elements that are being hidden or shown,
 * respectively, unless those names are not defined in the specified library (or the specified
 * library does not exist).
 * * Every [PartDirective] should resolve to the element representing the compilation unit
 * being specified by the string unless the specified compilation unit does not exist (a
 * [CompilationUnitElement]).
 * </ol>
 * Note that AST nodes that would represent elements that are not defined are not resolved to
 * anything. This includes such things as references to undeclared variables (which is an error) and
 * names in hide and show combinators that are not defined in the imported library (which is not an
 * error).
 */
class ElementResolver extends SimpleAstVisitor<Object> {
  /**
   * Checks if the given expression is the reference to the type, if it is then the
   * [ClassElement] is returned, otherwise `null` is returned.
   *
   * @param expression the expression to evaluate
   * @return the [ClassElement] if the given expression is the reference to the type, and
   *         `null` otherwise
   */
  static ClassElementImpl getTypeReference(Expression expression) {
    if (expression is Identifier) {
      Element staticElement = expression.staticElement;
      if (staticElement is ClassElementImpl) {
        return staticElement;
      }
    }
    return null;
  }

  /**
   * Return `true` if the given identifier is the return type of a constructor declaration.
   *
   * @return `true` if the given identifier is the return type of a constructor declaration.
   */
  static bool isConstructorReturnType(SimpleIdentifier identifier) {
    AstNode parent = identifier.parent;
    if (parent is ConstructorDeclaration) {
      return identical(parent.returnType, identifier);
    }
    return false;
  }

  /**
   * Return `true` if the given identifier is the return type of a factory constructor.
   *
   * @return `true` if the given identifier is the return type of a factory constructor
   *         declaration.
   */
  static bool isFactoryConstructorReturnType(SimpleIdentifier node) {
    AstNode parent = node.parent;
    if (parent is ConstructorDeclaration) {
      ConstructorDeclaration constructor = parent;
      return identical(constructor.returnType, node) && constructor.factoryKeyword != null;
    }
    return false;
  }

  /**
   * Return `true` if the given 'super' expression is used in a valid context.
   *
   * @param node the 'super' expression to analyze
   * @return `true` if the 'super' expression is in a valid context
   */
  static bool isSuperInValidContext(SuperExpression node) {
    for (AstNode n = node; n != null; n = n.parent) {
      if (n is CompilationUnit) {
        return false;
      }
      if (n is ConstructorDeclaration) {
        ConstructorDeclaration constructor = n as ConstructorDeclaration;
        return constructor.factoryKeyword == null;
      }
      if (n is ConstructorFieldInitializer) {
        return false;
      }
      if (n is MethodDeclaration) {
        MethodDeclaration method = n as MethodDeclaration;
        return !method.isStatic;
      }
    }
    return false;
  }

  /**
   * The resolver driving this participant.
   */
  ResolverVisitor _resolver;

  /**
   * The element for the library containing the compilation unit being visited.
   */
  LibraryElement _definingLibrary;

  /**
   * A flag indicating whether we should generate hints.
   */
  bool _enableHints = false;

  /**
   * The type representing the type 'dynamic'.
   */
  Type2 _dynamicType;

  /**
   * The type representing the type 'type'.
   */
  Type2 _typeType;

  /**
   * A utility class for the resolver to answer the question of "what are my subtypes?".
   */
  SubtypeManager _subtypeManager;

  /**
   * The object keeping track of which elements have had their types promoted.
   */
  TypePromotionManager _promoteManager;

  /**
   * The name of the method that can be implemented by a class to allow its instances to be invoked
   * as if they were a function.
   */
  static String CALL_METHOD_NAME = "call";

  /**
   * The name of the method that will be invoked if an attempt is made to invoke an undefined method
   * on an object.
   */
  static String NO_SUCH_METHOD_METHOD_NAME = "noSuchMethod";

  /**
   * Initialize a newly created visitor to resolve the nodes in a compilation unit.
   *
   * @param resolver the resolver driving this participant
   */
  ElementResolver(ResolverVisitor resolver) {
    this._resolver = resolver;
    this._definingLibrary = resolver.definingLibrary;
    AnalysisOptions options = _definingLibrary.context.analysisOptions;
    _enableHints = options.hint;
    _dynamicType = resolver.typeProvider.dynamicType;
    _typeType = resolver.typeProvider.typeType;
    _subtypeManager = new SubtypeManager();
    _promoteManager = resolver.promoteManager;
  }

  Object visitAssignmentExpression(AssignmentExpression node) {
    sc.Token operator = node.operator;
    sc.TokenType operatorType = operator.type;
    if (operatorType != sc.TokenType.EQ) {
      operatorType = operatorFromCompoundAssignment(operatorType);
      Expression leftHandSide = node.leftHandSide;
      if (leftHandSide != null) {
        String methodName = operatorType.lexeme;
        Type2 staticType = getStaticType(leftHandSide);
        MethodElement staticMethod = lookUpMethod(leftHandSide, staticType, methodName);
        node.staticElement = staticMethod;
        Type2 propagatedType = getPropagatedType(leftHandSide);
        MethodElement propagatedMethod = lookUpMethod(leftHandSide, propagatedType, methodName);
        node.propagatedElement = propagatedMethod;
        if (shouldReportMissingMember(staticType, staticMethod)) {
          _resolver.reportErrorProxyConditionalAnalysisError3(staticType.element, StaticTypeWarningCode.UNDEFINED_METHOD, operator, [methodName, staticType.displayName]);
        } else if (_enableHints && shouldReportMissingMember(propagatedType, propagatedMethod) && !memberFoundInSubclass(propagatedType.element, methodName, true, false)) {
          _resolver.reportErrorProxyConditionalAnalysisError3(propagatedType.element, HintCode.UNDEFINED_METHOD, operator, [methodName, propagatedType.displayName]);
        }
      }
    }
    return null;
  }

  Object visitBinaryExpression(BinaryExpression node) {
    sc.Token operator = node.operator;
    if (operator.isUserDefinableOperator) {
      Expression leftOperand = node.leftOperand;
      if (leftOperand != null) {
        String methodName = operator.lexeme;
        Type2 staticType = getStaticType(leftOperand);
        MethodElement staticMethod = lookUpMethod(leftOperand, staticType, methodName);
        node.staticElement = staticMethod;
        Type2 propagatedType = getPropagatedType(leftOperand);
        MethodElement propagatedMethod = lookUpMethod(leftOperand, propagatedType, methodName);
        node.propagatedElement = propagatedMethod;
        if (shouldReportMissingMember(staticType, staticMethod)) {
          _resolver.reportErrorProxyConditionalAnalysisError3(staticType.element, StaticTypeWarningCode.UNDEFINED_OPERATOR, operator, [methodName, staticType.displayName]);
        } else if (_enableHints && shouldReportMissingMember(propagatedType, propagatedMethod) && !memberFoundInSubclass(propagatedType.element, methodName, true, false)) {
          _resolver.reportErrorProxyConditionalAnalysisError3(propagatedType.element, HintCode.UNDEFINED_OPERATOR, operator, [methodName, propagatedType.displayName]);
        }
      }
    }
    return null;
  }

  Object visitBreakStatement(BreakStatement node) {
    lookupLabel(node, node.label);
    return null;
  }

  Object visitClassDeclaration(ClassDeclaration node) {
    setMetadata(node.element, node);
    return null;
  }

  Object visitClassTypeAlias(ClassTypeAlias node) {
    setMetadata(node.element, node);
    return null;
  }

  Object visitCommentReference(CommentReference node) {
    Identifier identifier = node.identifier;
    if (identifier is SimpleIdentifier) {
      SimpleIdentifier simpleIdentifier = identifier;
      Element element = resolveSimpleIdentifier(simpleIdentifier);
      if (element == null) {
        //
        // This might be a reference to an imported name that is missing the prefix.
        //
        element = findImportWithoutPrefix(simpleIdentifier);
        if (element is MultiplyDefinedElement) {
          // TODO(brianwilkerson) Report this error?
          element = null;
        }
      }
      if (element == null) {
      } else {
        if (element.library == null || element.library != _definingLibrary) {
        }
        simpleIdentifier.staticElement = element;
        if (node.newKeyword != null) {
          if (element is ClassElement) {
            ConstructorElement constructor = (element as ClassElement).unnamedConstructor;
            if (constructor == null) {
            } else {
              simpleIdentifier.staticElement = constructor;
            }
          } else {
          }
        }
      }
    } else if (identifier is PrefixedIdentifier) {
      PrefixedIdentifier prefixedIdentifier = identifier;
      SimpleIdentifier prefix = prefixedIdentifier.prefix;
      SimpleIdentifier name = prefixedIdentifier.identifier;
      Element element = resolveSimpleIdentifier(prefix);
      if (element == null) {
      } else {
        if (element is PrefixElement) {
          prefix.staticElement = element;
          // TODO(brianwilkerson) Report this error?
          element = _resolver.nameScope.lookup(identifier, _definingLibrary);
          name.staticElement = element;
          return null;
        }
        LibraryElement library = element.library;
        if (library == null) {
          // TODO(brianwilkerson) We need to understand how the library could ever be null.
          AnalysisEngine.instance.logger.logError("Found element with null library: ${element.name}");
        } else if (library != _definingLibrary) {
        }
        name.staticElement = element;
        if (node.newKeyword == null) {
          if (element is ClassElement) {
            Element memberElement = lookupGetterOrMethod((element as ClassElement).type, name.name);
            if (memberElement == null) {
              memberElement = (element as ClassElement).getNamedConstructor(name.name);
              if (memberElement == null) {
                memberElement = lookUpSetter(prefix, (element as ClassElement).type, name.name);
              }
            }
            if (memberElement == null) {
            } else {
              name.staticElement = memberElement;
            }
          } else {
          }
        } else {
          if (element is ClassElement) {
            ConstructorElement constructor = (element as ClassElement).getNamedConstructor(name.name);
            if (constructor == null) {
            } else {
              name.staticElement = constructor;
            }
          } else {
          }
        }
      }
    }
    return null;
  }

  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    super.visitConstructorDeclaration(node);
    ConstructorElement element = node.element;
    if (element is ConstructorElementImpl) {
      ConstructorElementImpl constructorElement = element;
      ConstructorName redirectedNode = node.redirectedConstructor;
      if (redirectedNode != null) {
        // set redirected factory constructor
        ConstructorElement redirectedElement = redirectedNode.staticElement;
        constructorElement.redirectedConstructor = redirectedElement;
      } else {
        // set redirected generative constructor
        for (ConstructorInitializer initializer in node.initializers) {
          if (initializer is RedirectingConstructorInvocation) {
            ConstructorElement redirectedElement = initializer.staticElement;
            constructorElement.redirectedConstructor = redirectedElement;
          }
        }
      }
      setMetadata(constructorElement, node);
    }
    return null;
  }

  Object visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    SimpleIdentifier fieldName = node.fieldName;
    ClassElement enclosingClass = _resolver.enclosingClass;
    FieldElement fieldElement = enclosingClass.getField(fieldName.name);
    fieldName.staticElement = fieldElement;
    return null;
  }

  Object visitConstructorName(ConstructorName node) {
    Type2 type = node.type.type;
    if (type != null && type.isDynamic) {
      return null;
    } else if (type is! InterfaceType) {
      // TODO(brianwilkerson) Report these errors.
      //      ASTNode parent = node.getParent();
      //      if (parent instanceof InstanceCreationExpression) {
      //        if (((InstanceCreationExpression) parent).isConst()) {
      //          // CompileTimeErrorCode.CONST_WITH_NON_TYPE
      //        } else {
      //          // StaticWarningCode.NEW_WITH_NON_TYPE
      //        }
      //      } else {
      //        // This is part of a redirecting factory constructor; not sure which error code to use
      //      }
      return null;
    }
    // look up ConstructorElement
    ConstructorElement constructor;
    SimpleIdentifier name = node.name;
    InterfaceType interfaceType = type as InterfaceType;
    if (name == null) {
      constructor = interfaceType.lookUpConstructor(null, _definingLibrary);
    } else {
      constructor = interfaceType.lookUpConstructor(name.name, _definingLibrary);
      name.staticElement = constructor;
    }
    node.staticElement = constructor;
    return null;
  }

  Object visitContinueStatement(ContinueStatement node) {
    lookupLabel(node, node.label);
    return null;
  }

  Object visitDeclaredIdentifier(DeclaredIdentifier node) {
    setMetadata(node.element, node);
    return null;
  }

  Object visitExportDirective(ExportDirective node) {
    Element element = node.element;
    if (element is ExportElement) {
      // The element is null when the URI is invalid
      // TODO(brianwilkerson) Figure out whether the element can ever be something other than an
      // ExportElement
      resolveCombinators(element.exportedLibrary, node.combinators);
      setMetadata(element, node);
    }
    return null;
  }

  Object visitFieldFormalParameter(FieldFormalParameter node) {
    setMetadataForParameter(node.element, node);
    return super.visitFieldFormalParameter(node);
  }

  Object visitFunctionDeclaration(FunctionDeclaration node) {
    setMetadata(node.element, node);
    return null;
  }

  Object visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    // TODO(brianwilkerson) Can we ever resolve the function being invoked?
    Expression expression = node.function;
    if (expression is FunctionExpression) {
      FunctionExpression functionExpression = expression;
      ExecutableElement functionElement = functionExpression.element;
      ArgumentList argumentList = node.argumentList;
      List<ParameterElement> parameters = resolveArgumentsToFunction(false, argumentList, functionElement);
      if (parameters != null) {
        argumentList.correspondingStaticParameters = parameters;
      }
    }
    return null;
  }

  Object visitFunctionTypeAlias(FunctionTypeAlias node) {
    setMetadata(node.element, node);
    return null;
  }

  Object visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    setMetadataForParameter(node.element, node);
    return null;
  }

  Object visitImportDirective(ImportDirective node) {
    SimpleIdentifier prefixNode = node.prefix;
    if (prefixNode != null) {
      String prefixName = prefixNode.name;
      for (PrefixElement prefixElement in _definingLibrary.prefixes) {
        if (prefixElement.displayName == prefixName) {
          prefixNode.staticElement = prefixElement;
          break;
        }
      }
    }
    ImportElement importElement = node.element;
    if (importElement != null) {
      // The element is null when the URI is invalid
      LibraryElement library = importElement.importedLibrary;
      if (library != null) {
        resolveCombinators(library, node.combinators);
      }
      setMetadata(importElement, node);
    }
    return null;
  }

  Object visitIndexExpression(IndexExpression node) {
    Expression target = node.realTarget;
    Type2 staticType = getStaticType(target);
    Type2 propagatedType = getPropagatedType(target);
    String getterMethodName = sc.TokenType.INDEX.lexeme;
    String setterMethodName = sc.TokenType.INDEX_EQ.lexeme;
    bool isInGetterContext = node.inGetterContext();
    bool isInSetterContext = node.inSetterContext();
    if (isInGetterContext && isInSetterContext) {
      // lookup setter
      MethodElement setterStaticMethod = lookUpMethod(target, staticType, setterMethodName);
      MethodElement setterPropagatedMethod = lookUpMethod(target, propagatedType, setterMethodName);
      // set setter element
      node.staticElement = setterStaticMethod;
      node.propagatedElement = setterPropagatedMethod;
      // generate undefined method warning
      checkForUndefinedIndexOperator(node, target, getterMethodName, setterStaticMethod, setterPropagatedMethod, staticType, propagatedType);
      // lookup getter method
      MethodElement getterStaticMethod = lookUpMethod(target, staticType, getterMethodName);
      MethodElement getterPropagatedMethod = lookUpMethod(target, propagatedType, getterMethodName);
      // set getter element
      AuxiliaryElements auxiliaryElements = new AuxiliaryElements(getterStaticMethod, getterPropagatedMethod);
      node.auxiliaryElements = auxiliaryElements;
      // generate undefined method warning
      checkForUndefinedIndexOperator(node, target, getterMethodName, getterStaticMethod, getterPropagatedMethod, staticType, propagatedType);
    } else if (isInGetterContext) {
      // lookup getter method
      MethodElement staticMethod = lookUpMethod(target, staticType, getterMethodName);
      MethodElement propagatedMethod = lookUpMethod(target, propagatedType, getterMethodName);
      // set getter element
      node.staticElement = staticMethod;
      node.propagatedElement = propagatedMethod;
      // generate undefined method warning
      checkForUndefinedIndexOperator(node, target, getterMethodName, staticMethod, propagatedMethod, staticType, propagatedType);
    } else if (isInSetterContext) {
      // lookup setter method
      MethodElement staticMethod = lookUpMethod(target, staticType, setterMethodName);
      MethodElement propagatedMethod = lookUpMethod(target, propagatedType, setterMethodName);
      // set setter element
      node.staticElement = staticMethod;
      node.propagatedElement = propagatedMethod;
      // generate undefined method warning
      checkForUndefinedIndexOperator(node, target, setterMethodName, staticMethod, propagatedMethod, staticType, propagatedType);
    }
    return null;
  }

  Object visitInstanceCreationExpression(InstanceCreationExpression node) {
    ConstructorElement invokedConstructor = node.constructorName.staticElement;
    node.staticElement = invokedConstructor;
    ArgumentList argumentList = node.argumentList;
    List<ParameterElement> parameters = resolveArgumentsToFunction(node.isConst, argumentList, invokedConstructor);
    if (parameters != null) {
      argumentList.correspondingStaticParameters = parameters;
    }
    return null;
  }

  Object visitLibraryDirective(LibraryDirective node) {
    setMetadata(node.element, node);
    return null;
  }

  Object visitMethodDeclaration(MethodDeclaration node) {
    setMetadata(node.element, node);
    return null;
  }

  Object visitMethodInvocation(MethodInvocation node) {
    SimpleIdentifier methodName = node.methodName;
    //
    // Synthetic identifiers have been already reported during parsing.
    //
    if (methodName.isSynthetic) {
      return null;
    }
    //
    // We have a method invocation of one of two forms: 'e.m(a1, ..., an)' or 'm(a1, ..., an)'. The
    // first step is to figure out which executable is being invoked, using both the static and the
    // propagated type information.
    //
    Expression target = node.realTarget;
    if (target is SuperExpression && !isSuperInValidContext(target)) {
      return null;
    }
    Element staticElement;
    Element propagatedElement;
    if (target == null) {
      staticElement = resolveInvokedElement(methodName);
      propagatedElement = null;
    } else {
      Type2 staticType = getStaticType(target);
      //
      // If this method invocation is of the form 'C.m' where 'C' is a class, then we don't call
      // resolveInvokedElement(..) which walks up the class hierarchy, instead we just look for the
      // member in the type only.
      //
      ClassElementImpl typeReference = getTypeReference(target);
      if (typeReference != null) {
        staticElement = propagatedElement = resolveElement(typeReference, methodName);
      } else {
        staticElement = resolveInvokedElementWithTarget(target, staticType, methodName);
        propagatedElement = resolveInvokedElementWithTarget(target, getPropagatedType(target), methodName);
      }
    }
    staticElement = convertSetterToGetter(staticElement);
    propagatedElement = convertSetterToGetter(propagatedElement);
    //
    // Record the results.
    //
    methodName.staticElement = staticElement;
    methodName.propagatedElement = propagatedElement;
    ArgumentList argumentList = node.argumentList;
    if (staticElement != null) {
      List<ParameterElement> parameters = computeCorrespondingParameters(argumentList, staticElement);
      if (parameters != null) {
        argumentList.correspondingStaticParameters = parameters;
      }
    }
    if (propagatedElement != null) {
      List<ParameterElement> parameters = computeCorrespondingParameters(argumentList, propagatedElement);
      if (parameters != null) {
        argumentList.correspondingPropagatedParameters = parameters;
      }
    }
    //
    // Then check for error conditions.
    //
    ErrorCode errorCode = checkForInvocationError(target, true, staticElement);
    bool generatedWithTypePropagation = false;
    if (_enableHints && errorCode == null && staticElement == null) {
      errorCode = checkForInvocationError(target, false, propagatedElement);
      if (identical(errorCode, StaticTypeWarningCode.UNDEFINED_METHOD)) {
        ClassElement classElementContext = null;
        if (target == null) {
          classElementContext = _resolver.enclosingClass;
        } else {
          Type2 type = target.bestType;
          if (type != null) {
            if (type.element is ClassElement) {
              classElementContext = type.element as ClassElement;
            }
          }
        }
        if (classElementContext != null) {
          _subtypeManager.ensureLibraryVisited(_definingLibrary);
          Set<ClassElement> subtypeElements = _subtypeManager.computeAllSubtypes(classElementContext);
          for (ClassElement subtypeElement in subtypeElements) {
            if (subtypeElement.getMethod(methodName.name) != null) {
              errorCode = null;
            }
          }
        }
      }
      generatedWithTypePropagation = true;
    }
    if (errorCode == null) {
      return null;
    }
    if (identical(errorCode, StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION)) {
      _resolver.reportErrorForNode(StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION, methodName, [methodName.name]);
    } else if (identical(errorCode, CompileTimeErrorCode.UNDEFINED_FUNCTION)) {
      _resolver.reportErrorForNode(CompileTimeErrorCode.UNDEFINED_FUNCTION, methodName, [methodName.name]);
    } else if (identical(errorCode, StaticTypeWarningCode.UNDEFINED_METHOD)) {
      String targetTypeName;
      if (target == null) {
        ClassElement enclosingClass = _resolver.enclosingClass;
        targetTypeName = enclosingClass.displayName;
        ErrorCode proxyErrorCode = (generatedWithTypePropagation ? HintCode.UNDEFINED_METHOD : StaticTypeWarningCode.UNDEFINED_METHOD) as ErrorCode;
        _resolver.reportErrorProxyConditionalAnalysisError(_resolver.enclosingClass, proxyErrorCode, methodName, [methodName.name, targetTypeName]);
      } else {
        // ignore Function "call"
        // (if we are about to create a hint using type propagation, then we can use type
        // propagation here as well)
        Type2 targetType = null;
        if (!generatedWithTypePropagation) {
          targetType = getStaticType(target);
        } else {
          // choose the best type
          targetType = getPropagatedType(target);
          if (targetType == null) {
            targetType = getStaticType(target);
          }
        }
        if (targetType != null && targetType.isDartCoreFunction && methodName.name == CALL_METHOD_NAME) {
          // TODO(brianwilkerson) Can we ever resolve the function being invoked?
          //resolveArgumentsToParameters(node.getArgumentList(), invokedFunction);
          return null;
        }
        targetTypeName = targetType == null ? null : targetType.displayName;
        ErrorCode proxyErrorCode = (generatedWithTypePropagation ? HintCode.UNDEFINED_METHOD : StaticTypeWarningCode.UNDEFINED_METHOD) as ErrorCode;
        _resolver.reportErrorProxyConditionalAnalysisError(targetType.element, proxyErrorCode, methodName, [methodName.name, targetTypeName]);
      }
    } else if (identical(errorCode, StaticTypeWarningCode.UNDEFINED_SUPER_METHOD)) {
      // Generate the type name.
      // The error code will never be generated via type propagation
      Type2 targetType = getStaticType(target);
      String targetTypeName = targetType == null ? null : targetType.name;
      _resolver.reportErrorForNode(StaticTypeWarningCode.UNDEFINED_SUPER_METHOD, methodName, [methodName.name, targetTypeName]);
    }
    return null;
  }

  Object visitPartDirective(PartDirective node) {
    setMetadata(node.element, node);
    return null;
  }

  Object visitPartOfDirective(PartOfDirective node) {
    setMetadata(node.element, node);
    return null;
  }

  Object visitPostfixExpression(PostfixExpression node) {
    Expression operand = node.operand;
    String methodName = getPostfixOperator(node);
    Type2 staticType = getStaticType(operand);
    MethodElement staticMethod = lookUpMethod(operand, staticType, methodName);
    node.staticElement = staticMethod;
    Type2 propagatedType = getPropagatedType(operand);
    MethodElement propagatedMethod = lookUpMethod(operand, propagatedType, methodName);
    node.propagatedElement = propagatedMethod;
    if (shouldReportMissingMember(staticType, staticMethod)) {
      _resolver.reportErrorProxyConditionalAnalysisError3(staticType.element, StaticTypeWarningCode.UNDEFINED_OPERATOR, node.operator, [methodName, staticType.displayName]);
    } else if (_enableHints && shouldReportMissingMember(propagatedType, propagatedMethod) && !memberFoundInSubclass(propagatedType.element, methodName, true, false)) {
      _resolver.reportErrorProxyConditionalAnalysisError3(propagatedType.element, HintCode.UNDEFINED_OPERATOR, node.operator, [methodName, propagatedType.displayName]);
    }
    return null;
  }

  Object visitPrefixedIdentifier(PrefixedIdentifier node) {
    SimpleIdentifier prefix = node.prefix;
    SimpleIdentifier identifier = node.identifier;
    //
    // First, check to see whether the prefix is really a prefix.
    //
    Element prefixElement = prefix.staticElement;
    if (prefixElement is PrefixElement) {
      Element element = _resolver.nameScope.lookup(node, _definingLibrary);
      if (element == null && identifier.inSetterContext()) {
        element = _resolver.nameScope.lookup(new ElementResolver_SyntheticIdentifier("${node.name}="), _definingLibrary);
      }
      if (element == null) {
        if (identifier.inSetterContext()) {
          _resolver.reportErrorForNode(StaticWarningCode.UNDEFINED_SETTER, identifier, [identifier.name, prefixElement.name]);
        } else if (node.parent is Annotation) {
          Annotation annotation = node.parent as Annotation;
          _resolver.reportErrorForNode(CompileTimeErrorCode.INVALID_ANNOTATION, annotation, []);
          return null;
        } else {
          _resolver.reportErrorForNode(StaticWarningCode.UNDEFINED_GETTER, identifier, [identifier.name, prefixElement.name]);
        }
        return null;
      }
      if (element is PropertyAccessorElement && identifier.inSetterContext()) {
        PropertyInducingElement variable = (element as PropertyAccessorElement).variable;
        if (variable != null) {
          PropertyAccessorElement setter = variable.setter;
          if (setter != null) {
            element = setter;
          }
        }
      }
      // TODO(brianwilkerson) The prefix needs to be resolved to the element for the import that
      // defines the prefix, not the prefix's element.
      identifier.staticElement = element;
      // Validate annotation element.
      if (node.parent is Annotation) {
        Annotation annotation = node.parent as Annotation;
        resolveAnnotationElement(annotation);
        return null;
      }
      return null;
    }
    // May be annotation, resolve invocation of "const" constructor.
    if (node.parent is Annotation) {
      Annotation annotation = node.parent as Annotation;
      resolveAnnotationElement(annotation);
    }
    //
    // Otherwise, the prefix is really an expression that happens to be a simple identifier and this
    // is really equivalent to a property access node.
    //
    resolvePropertyAccess(prefix, identifier);
    return null;
  }

  Object visitPrefixExpression(PrefixExpression node) {
    sc.Token operator = node.operator;
    sc.TokenType operatorType = operator.type;
    if (operatorType.isUserDefinableOperator || identical(operatorType, sc.TokenType.PLUS_PLUS) || identical(operatorType, sc.TokenType.MINUS_MINUS)) {
      Expression operand = node.operand;
      String methodName = getPrefixOperator(node);
      Type2 staticType = getStaticType(operand);
      MethodElement staticMethod = lookUpMethod(operand, staticType, methodName);
      node.staticElement = staticMethod;
      Type2 propagatedType = getPropagatedType(operand);
      MethodElement propagatedMethod = lookUpMethod(operand, propagatedType, methodName);
      node.propagatedElement = propagatedMethod;
      if (shouldReportMissingMember(staticType, staticMethod)) {
        _resolver.reportErrorProxyConditionalAnalysisError3(staticType.element, StaticTypeWarningCode.UNDEFINED_OPERATOR, operator, [methodName, staticType.displayName]);
      } else if (_enableHints && shouldReportMissingMember(propagatedType, propagatedMethod) && !memberFoundInSubclass(propagatedType.element, methodName, true, false)) {
        _resolver.reportErrorProxyConditionalAnalysisError3(propagatedType.element, HintCode.UNDEFINED_OPERATOR, operator, [methodName, propagatedType.displayName]);
      }
    }
    return null;
  }

  Object visitPropertyAccess(PropertyAccess node) {
    Expression target = node.realTarget;
    if (target is SuperExpression && !isSuperInValidContext(target)) {
      return null;
    }
    SimpleIdentifier propertyName = node.propertyName;
    resolvePropertyAccess(target, propertyName);
    return null;
  }

  Object visitRedirectingConstructorInvocation(RedirectingConstructorInvocation node) {
    ClassElement enclosingClass = _resolver.enclosingClass;
    if (enclosingClass == null) {
      // TODO(brianwilkerson) Report this error.
      return null;
    }
    SimpleIdentifier name = node.constructorName;
    ConstructorElement element;
    if (name == null) {
      element = enclosingClass.unnamedConstructor;
    } else {
      element = enclosingClass.getNamedConstructor(name.name);
    }
    if (element == null) {
      // TODO(brianwilkerson) Report this error and decide what element to associate with the node.
      return null;
    }
    if (name != null) {
      name.staticElement = element;
    }
    node.staticElement = element;
    ArgumentList argumentList = node.argumentList;
    List<ParameterElement> parameters = resolveArgumentsToFunction(false, argumentList, element);
    if (parameters != null) {
      argumentList.correspondingStaticParameters = parameters;
    }
    return null;
  }

  Object visitSimpleFormalParameter(SimpleFormalParameter node) {
    setMetadataForParameter(node.element, node);
    return null;
  }

  Object visitSimpleIdentifier(SimpleIdentifier node) {
    //
    // Synthetic identifiers have been already reported during parsing.
    //
    if (node.isSynthetic) {
      return null;
    }
    //
    // We ignore identifiers that have already been resolved, such as identifiers representing the
    // name in a declaration.
    //
    if (node.staticElement != null) {
      return null;
    }
    //
    // The name dynamic denotes a Type object even though dynamic is not a class.
    //
    if (node.name == _dynamicType.name) {
      node.staticElement = _dynamicType.element;
      node.staticType = _typeType;
      return null;
    }
    //
    // Otherwise, the node should be resolved.
    //
    Element element = resolveSimpleIdentifier(node);
    ClassElement enclosingClass = _resolver.enclosingClass;
    if (isFactoryConstructorReturnType(node) && element != enclosingClass) {
      _resolver.reportErrorForNode(CompileTimeErrorCode.INVALID_FACTORY_NAME_NOT_A_CLASS, node, []);
    } else if (isConstructorReturnType(node) && element != enclosingClass) {
      _resolver.reportErrorForNode(CompileTimeErrorCode.INVALID_CONSTRUCTOR_NAME, node, []);
      element = null;
    } else if (element == null || (element is PrefixElement && !isValidAsPrefix(node))) {
      // TODO(brianwilkerson) Recover from this error.
      if (isConstructorReturnType(node)) {
        _resolver.reportErrorForNode(CompileTimeErrorCode.INVALID_CONSTRUCTOR_NAME, node, []);
      } else if (node.parent is Annotation) {
        Annotation annotation = node.parent as Annotation;
        _resolver.reportErrorForNode(CompileTimeErrorCode.INVALID_ANNOTATION, annotation, []);
      } else {
        _resolver.reportErrorProxyConditionalAnalysisError(_resolver.enclosingClass, StaticWarningCode.UNDEFINED_IDENTIFIER, node, [node.name]);
      }
    }
    node.staticElement = element;
    if (node.inSetterContext() && node.inGetterContext() && enclosingClass != null) {
      InterfaceType enclosingType = enclosingClass.type;
      AuxiliaryElements auxiliaryElements = new AuxiliaryElements(lookUpGetter(null, enclosingType, node.name), null);
      node.auxiliaryElements = auxiliaryElements;
    }
    //
    // Validate annotation element.
    //
    if (node.parent is Annotation) {
      Annotation annotation = node.parent as Annotation;
      resolveAnnotationElement(annotation);
    }
    return null;
  }

  Object visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    ClassElement enclosingClass = _resolver.enclosingClass;
    if (enclosingClass == null) {
      // TODO(brianwilkerson) Report this error.
      return null;
    }
    InterfaceType superType = enclosingClass.supertype;
    if (superType == null) {
      // TODO(brianwilkerson) Report this error.
      return null;
    }
    SimpleIdentifier name = node.constructorName;
    String superName = name != null ? name.name : null;
    ConstructorElement element = superType.lookUpConstructor(superName, _definingLibrary);
    if (element == null) {
      if (name != null) {
        _resolver.reportErrorForNode(CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER, node, [superType.displayName, name]);
      } else {
        _resolver.reportErrorForNode(CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT, node, [superType.displayName]);
      }
      return null;
    } else {
      if (element.isFactory) {
        _resolver.reportErrorForNode(CompileTimeErrorCode.NON_GENERATIVE_CONSTRUCTOR, node, [element]);
      }
    }
    if (name != null) {
      name.staticElement = element;
    }
    node.staticElement = element;
    ArgumentList argumentList = node.argumentList;
    List<ParameterElement> parameters = resolveArgumentsToFunction(isInConstConstructor, argumentList, element);
    if (parameters != null) {
      argumentList.correspondingStaticParameters = parameters;
    }
    return null;
  }

  Object visitSuperExpression(SuperExpression node) {
    if (!isSuperInValidContext(node)) {
      _resolver.reportErrorForNode(CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT, node, []);
    }
    return super.visitSuperExpression(node);
  }

  Object visitTypeParameter(TypeParameter node) {
    setMetadata(node.element, node);
    return null;
  }

  Object visitVariableDeclaration(VariableDeclaration node) {
    setMetadata(node.element, node);
    return null;
  }

  /**
   * Generate annotation elements for each of the annotations in the given node list and add them to
   * the given list of elements.
   *
   * @param annotationList the list of elements to which new elements are to be added
   * @param annotations the AST nodes used to generate new elements
   */
  void addAnnotations(List<ElementAnnotationImpl> annotationList, NodeList<Annotation> annotations) {
    int annotationCount = annotations.length;
    for (int i = 0; i < annotationCount; i++) {
      Element resolvedElement = annotations[i].element;
      if (resolvedElement != null) {
        annotationList.add(new ElementAnnotationImpl(resolvedElement));
      }
    }
  }

  /**
   * Given that we have found code to invoke the given element, return the error code that should be
   * reported, or `null` if no error should be reported.
   *
   * @param target the target of the invocation, or `null` if there was no target
   * @param useStaticContext
   * @param element the element to be invoked
   * @return the error code that should be reported
   */
  ErrorCode checkForInvocationError(Expression target, bool useStaticContext, Element element) {
    // Prefix is not declared, instead "prefix.id" are declared.
    if (element is PrefixElement) {
      element = null;
    }
    if (element is PropertyAccessorElement) {
      //
      // This is really a function expression invocation.
      //
      // TODO(brianwilkerson) Consider the possibility of re-writing the AST.
      FunctionType getterType = element.type;
      if (getterType != null) {
        Type2 returnType = getterType.returnType;
        if (!isExecutableType(returnType)) {
          return StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION;
        }
      }
    } else if (element is ExecutableElement) {
      return null;
    } else if (element == null && target is SuperExpression) {
      // TODO(jwren) We should split the UNDEFINED_METHOD into two error codes, this one, and
      // a code that describes the situation where the method was found, but it was not
      // accessible from the current library.
      return StaticTypeWarningCode.UNDEFINED_SUPER_METHOD;
    } else {
      //
      // This is really a function expression invocation.
      //
      // TODO(brianwilkerson) Consider the possibility of re-writing the AST.
      if (element is PropertyInducingElement) {
        PropertyAccessorElement getter = element.getter;
        FunctionType getterType = getter.type;
        if (getterType != null) {
          Type2 returnType = getterType.returnType;
          if (!isExecutableType(returnType)) {
            return StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION;
          }
        }
      } else if (element is VariableElement) {
        Type2 variableType = element.type;
        if (!isExecutableType(variableType)) {
          return StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION;
        }
      } else {
        if (target == null) {
          ClassElement enclosingClass = _resolver.enclosingClass;
          if (enclosingClass == null) {
            return CompileTimeErrorCode.UNDEFINED_FUNCTION;
          } else if (element == null) {
            // Proxy-conditional warning, based on state of resolver.getEnclosingClass()
            return StaticTypeWarningCode.UNDEFINED_METHOD;
          } else {
            return StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION;
          }
        } else {
          Type2 targetType;
          if (useStaticContext) {
            targetType = getStaticType(target);
          } else {
            // Compute and use the propagated type, if it is null, then it may be the case that
            // static type is some type, in which the static type should be used.
            targetType = target.bestType;
          }
          if (targetType == null) {
            return CompileTimeErrorCode.UNDEFINED_FUNCTION;
          } else if (!targetType.isDynamic && !targetType.isBottom) {
            // Proxy-conditional warning, based on state of targetType.getElement()
            return StaticTypeWarningCode.UNDEFINED_METHOD;
          }
        }
      }
    }
    return null;
  }

  /**
   * Check that the for some index expression that the method element was resolved, otherwise a
   * [StaticWarningCode#UNDEFINED_OPERATOR] is generated.
   *
   * @param node the index expression to resolve
   * @param target the target of the expression
   * @param methodName the name of the operator associated with the context of using of the given
   *          index expression
   * @return `true` if and only if an error code is generated on the passed node
   */
  bool checkForUndefinedIndexOperator(IndexExpression node, Expression target, String methodName, MethodElement staticMethod, MethodElement propagatedMethod, Type2 staticType, Type2 propagatedType) {
    bool shouldReportMissingMember_static = shouldReportMissingMember(staticType, staticMethod);
    bool shouldReportMissingMember_propagated = !shouldReportMissingMember_static && _enableHints && shouldReportMissingMember(propagatedType, propagatedMethod) && !memberFoundInSubclass(propagatedType.element, methodName, true, false);
    if (shouldReportMissingMember_static || shouldReportMissingMember_propagated) {
      sc.Token leftBracket = node.leftBracket;
      sc.Token rightBracket = node.rightBracket;
      ErrorCode errorCode = (shouldReportMissingMember_static ? StaticTypeWarningCode.UNDEFINED_OPERATOR : HintCode.UNDEFINED_OPERATOR) as ErrorCode;
      if (leftBracket == null || rightBracket == null) {
        _resolver.reportErrorProxyConditionalAnalysisError(shouldReportMissingMember_static ? staticType.element : propagatedType.element, errorCode, node, [
            methodName,
            shouldReportMissingMember_static ? staticType.displayName : propagatedType.displayName]);
      } else {
        int offset = leftBracket.offset;
        int length = rightBracket.offset - offset + 1;
        _resolver.reportErrorProxyConditionalAnalysisError2(shouldReportMissingMember_static ? staticType.element : propagatedType.element, errorCode, offset, length, [
            methodName,
            shouldReportMissingMember_static ? staticType.displayName : propagatedType.displayName]);
      }
      return true;
    }
    return false;
  }

  /**
   * Given a list of arguments and the element that will be invoked using those argument, compute
   * the list of parameters that correspond to the list of arguments. Return the parameters that
   * correspond to the arguments, or `null` if no correspondence could be computed.
   *
   * @param argumentList the list of arguments being passed to the element
   * @param executableElement the element that will be invoked with the arguments
   * @return the parameters that correspond to the arguments
   */
  List<ParameterElement> computeCorrespondingParameters(ArgumentList argumentList, Element element) {
    if (element is PropertyAccessorElement) {
      //
      // This is an invocation of the call method defined on the value returned by the getter.
      //
      FunctionType getterType = element.type;
      if (getterType != null) {
        Type2 getterReturnType = getterType.returnType;
        if (getterReturnType is InterfaceType) {
          MethodElement callMethod = getterReturnType.lookUpMethod(CALL_METHOD_NAME, _definingLibrary);
          if (callMethod != null) {
            return resolveArgumentsToFunction(false, argumentList, callMethod);
          }
        } else if (getterReturnType is FunctionType) {
          Element functionElement = getterReturnType.element;
          if (functionElement is ExecutableElement) {
            return resolveArgumentsToFunction(false, argumentList, functionElement);
          }
        }
      }
    } else if (element is ExecutableElement) {
      return resolveArgumentsToFunction(false, argumentList, element);
    } else if (element is VariableElement) {
      VariableElement variable = element;
      Type2 type = _promoteManager.getStaticType(variable);
      if (type is FunctionType) {
        FunctionType functionType = type;
        List<ParameterElement> parameters = functionType.parameters;
        return resolveArgumentsToParameters(false, argumentList, parameters);
      } else if (type is InterfaceType) {
        // "call" invocation
        MethodElement callMethod = type.lookUpMethod(CALL_METHOD_NAME, _definingLibrary);
        if (callMethod != null) {
          List<ParameterElement> parameters = callMethod.parameters;
          return resolveArgumentsToParameters(false, argumentList, parameters);
        }
      }
    }
    return null;
  }

  /**
   * If the given element is a setter, return the getter associated with it. Otherwise, return the
   * element unchanged.
   *
   * @param element the element to be normalized
   * @return a non-setter element derived from the given element
   */
  Element convertSetterToGetter(Element element) {
    // TODO(brianwilkerson) Determine whether and why the element could ever be a setter.
    if (element is PropertyAccessorElement) {
      return element.variable.getter;
    }
    return element;
  }

  /**
   * Look for any declarations of the given identifier that are imported using a prefix. Return the
   * element that was found, or `null` if the name is not imported using a prefix.
   *
   * @param identifier the identifier that might have been imported using a prefix
   * @return the element that was found
   */
  Element findImportWithoutPrefix(SimpleIdentifier identifier) {
    Element element = null;
    Scope nameScope = _resolver.nameScope;
    for (ImportElement importElement in _definingLibrary.imports) {
      PrefixElement prefixElement = importElement.prefix;
      if (prefixElement != null) {
        Identifier prefixedIdentifier = new ElementResolver_SyntheticIdentifier("${prefixElement.name}.${identifier.name}");
        Element importedElement = nameScope.lookup(prefixedIdentifier, _definingLibrary);
        if (importedElement != null) {
          if (element == null) {
            element = importedElement;
          } else {
            element = MultiplyDefinedElementImpl.fromElements(_definingLibrary.context, element, importedElement);
          }
        }
      }
    }
    return element;
  }

  /**
   * Return the name of the method invoked by the given postfix expression.
   *
   * @param node the postfix expression being invoked
   * @return the name of the method invoked by the expression
   */
  String getPostfixOperator(PostfixExpression node) => (identical(node.operator.type, sc.TokenType.PLUS_PLUS)) ? sc.TokenType.PLUS.lexeme : sc.TokenType.MINUS.lexeme;

  /**
   * Return the name of the method invoked by the given postfix expression.
   *
   * @param node the postfix expression being invoked
   * @return the name of the method invoked by the expression
   */
  String getPrefixOperator(PrefixExpression node) {
    sc.Token operator = node.operator;
    sc.TokenType operatorType = operator.type;
    if (identical(operatorType, sc.TokenType.PLUS_PLUS)) {
      return sc.TokenType.PLUS.lexeme;
    } else if (identical(operatorType, sc.TokenType.MINUS_MINUS)) {
      return sc.TokenType.MINUS.lexeme;
    } else if (identical(operatorType, sc.TokenType.MINUS)) {
      return "unary-";
    } else {
      return operator.lexeme;
    }
  }

  /**
   * Return the propagated type of the given expression that is to be used for type analysis.
   *
   * @param expression the expression whose type is to be returned
   * @return the type of the given expression
   */
  Type2 getPropagatedType(Expression expression) {
    Type2 propagatedType = resolveTypeParameter(expression.propagatedType);
    if (propagatedType is FunctionType) {
      //
      // All function types are subtypes of 'Function', which is itself a subclass of 'Object'.
      //
      propagatedType = _resolver.typeProvider.functionType;
    }
    return propagatedType;
  }

  /**
   * Return the static type of the given expression that is to be used for type analysis.
   *
   * @param expression the expression whose type is to be returned
   * @return the type of the given expression
   */
  Type2 getStaticType(Expression expression) {
    if (expression is NullLiteral) {
      return _resolver.typeProvider.bottomType;
    }
    Type2 staticType = resolveTypeParameter(expression.staticType);
    if (staticType is FunctionType) {
      //
      // All function types are subtypes of 'Function', which is itself a subclass of 'Object'.
      //
      staticType = _resolver.typeProvider.functionType;
    }
    return staticType;
  }

  /**
   * Return `true` if the given type represents an object that could be invoked using the call
   * operator '()'.
   *
   * @param type the type being tested
   * @return `true` if the given type represents an object that could be invoked
   */
  bool isExecutableType(Type2 type) {
    if (type.isDynamic || (type is FunctionType) || type.isDartCoreFunction || type.isObject) {
      return true;
    } else if (type is InterfaceType) {
      ClassElement classElement = type.element;
      MethodElement methodElement = classElement.lookUpMethod(CALL_METHOD_NAME, _definingLibrary);
      return methodElement != null;
    }
    return false;
  }

  /**
   * @return `true` iff current enclosing function is constant constructor declaration.
   */
  bool get isInConstConstructor {
    ExecutableElement function = _resolver.enclosingFunction;
    if (function is ConstructorElement) {
      return function.isConst;
    }
    return false;
  }

  /**
   * Return `true` if the given element is a static element.
   *
   * @param element the element being tested
   * @return `true` if the given element is a static element
   */
  bool isStatic(Element element) {
    if (element is ExecutableElement) {
      return element.isStatic;
    } else if (element is PropertyInducingElement) {
      return element.isStatic;
    }
    return false;
  }

  /**
   * Return `true` if the given node can validly be resolved to a prefix:
   * * it is the prefix in an import directive, or
   * * it is the prefix in a prefixed identifier.
   *
   * @param node the node being tested
   * @return `true` if the given node is the prefix in an import directive
   */
  bool isValidAsPrefix(SimpleIdentifier node) {
    AstNode parent = node.parent;
    if (parent is ImportDirective) {
      return identical(parent.prefix, node);
    } else if (parent is PrefixedIdentifier) {
      return true;
    } else if (parent is MethodInvocation) {
      return identical(parent.target, node);
    }
    return false;
  }

  /**
   * Look up the getter with the given name in the given type. Return the element representing the
   * getter that was found, or `null` if there is no getter with the given name.
   *
   * @param target the target of the invocation, or `null` if there is no target
   * @param type the type in which the getter is defined
   * @param getterName the name of the getter being looked up
   * @return the element representing the getter that was found
   */
  PropertyAccessorElement lookUpGetter(Expression target, Type2 type, String getterName) {
    type = resolveTypeParameter(type);
    if (type is InterfaceType) {
      InterfaceType interfaceType = type;
      PropertyAccessorElement accessor;
      if (target is SuperExpression) {
        accessor = interfaceType.lookUpGetterInSuperclass(getterName, _definingLibrary);
      } else {
        accessor = interfaceType.lookUpGetter(getterName, _definingLibrary);
      }
      if (accessor != null) {
        return accessor;
      }
      return lookUpGetterInInterfaces(interfaceType, false, getterName, new Set<ClassElement>());
    }
    return null;
  }

  /**
   * Look up the getter with the given name in the interfaces implemented by the given type, either
   * directly or indirectly. Return the element representing the getter that was found, or
   * `null` if there is no getter with the given name.
   *
   * @param targetType the type in which the getter might be defined
   * @param includeTargetType `true` if the search should include the target type
   * @param getterName the name of the getter being looked up
   * @param visitedInterfaces a set containing all of the interfaces that have been examined, used
   *          to prevent infinite recursion and to optimize the search
   * @return the element representing the getter that was found
   */
  PropertyAccessorElement lookUpGetterInInterfaces(InterfaceType targetType, bool includeTargetType, String getterName, Set<ClassElement> visitedInterfaces) {
    // TODO(brianwilkerson) This isn't correct. Section 8.1.1 of the specification (titled
    // "Inheritance and Overriding" under "Interfaces") describes a much more complex scheme for
    // finding the inherited member. We need to follow that scheme. The code below should cover the
    // 80% case.
    ClassElement targetClass = targetType.element;
    if (visitedInterfaces.contains(targetClass)) {
      return null;
    }
    visitedInterfaces.add(targetClass);
    if (includeTargetType) {
      PropertyAccessorElement getter = targetType.getGetter(getterName);
      if (getter != null && getter.isAccessibleIn(_definingLibrary)) {
        return getter;
      }
    }
    for (InterfaceType interfaceType in targetType.interfaces) {
      PropertyAccessorElement getter = lookUpGetterInInterfaces(interfaceType, true, getterName, visitedInterfaces);
      if (getter != null) {
        return getter;
      }
    }
    for (InterfaceType mixinType in targetType.mixins) {
      PropertyAccessorElement getter = lookUpGetterInInterfaces(mixinType, true, getterName, visitedInterfaces);
      if (getter != null) {
        return getter;
      }
    }
    InterfaceType superclass = targetType.superclass;
    if (superclass == null) {
      return null;
    }
    return lookUpGetterInInterfaces(superclass, true, getterName, visitedInterfaces);
  }

  /**
   * Look up the method or getter with the given name in the given type. Return the element
   * representing the method or getter that was found, or `null` if there is no method or
   * getter with the given name.
   *
   * @param type the type in which the method or getter is defined
   * @param memberName the name of the method or getter being looked up
   * @return the element representing the method or getter that was found
   */
  ExecutableElement lookupGetterOrMethod(Type2 type, String memberName) {
    type = resolveTypeParameter(type);
    if (type is InterfaceType) {
      InterfaceType interfaceType = type;
      ExecutableElement member = interfaceType.lookUpMethod(memberName, _definingLibrary);
      if (member != null) {
        return member;
      }
      member = interfaceType.lookUpGetter(memberName, _definingLibrary);
      if (member != null) {
        return member;
      }
      return lookUpGetterOrMethodInInterfaces(interfaceType, false, memberName, new Set<ClassElement>());
    }
    return null;
  }

  /**
   * Look up the method or getter with the given name in the interfaces implemented by the given
   * type, either directly or indirectly. Return the element representing the method or getter that
   * was found, or `null` if there is no method or getter with the given name.
   *
   * @param targetType the type in which the method or getter might be defined
   * @param includeTargetType `true` if the search should include the target type
   * @param memberName the name of the method or getter being looked up
   * @param visitedInterfaces a set containing all of the interfaces that have been examined, used
   *          to prevent infinite recursion and to optimize the search
   * @return the element representing the method or getter that was found
   */
  ExecutableElement lookUpGetterOrMethodInInterfaces(InterfaceType targetType, bool includeTargetType, String memberName, Set<ClassElement> visitedInterfaces) {
    // TODO(brianwilkerson) This isn't correct. Section 8.1.1 of the specification (titled
    // "Inheritance and Overriding" under "Interfaces") describes a much more complex scheme for
    // finding the inherited member. We need to follow that scheme. The code below should cover the
    // 80% case.
    ClassElement targetClass = targetType.element;
    if (visitedInterfaces.contains(targetClass)) {
      return null;
    }
    visitedInterfaces.add(targetClass);
    if (includeTargetType) {
      ExecutableElement member = targetType.getMethod(memberName);
      if (member != null) {
        return member;
      }
      member = targetType.getGetter(memberName);
      if (member != null) {
        return member;
      }
    }
    for (InterfaceType interfaceType in targetType.interfaces) {
      ExecutableElement member = lookUpGetterOrMethodInInterfaces(interfaceType, true, memberName, visitedInterfaces);
      if (member != null) {
        return member;
      }
    }
    for (InterfaceType mixinType in targetType.mixins) {
      ExecutableElement member = lookUpGetterOrMethodInInterfaces(mixinType, true, memberName, visitedInterfaces);
      if (member != null) {
        return member;
      }
    }
    InterfaceType superclass = targetType.superclass;
    if (superclass == null) {
      return null;
    }
    return lookUpGetterOrMethodInInterfaces(superclass, true, memberName, visitedInterfaces);
  }

  /**
   * Find the element corresponding to the given label node in the current label scope.
   *
   * @param parentNode the node containing the given label
   * @param labelNode the node representing the label being looked up
   * @return the element corresponding to the given label node in the current scope
   */
  LabelElementImpl lookupLabel(AstNode parentNode, SimpleIdentifier labelNode) {
    LabelScope labelScope = _resolver.labelScope;
    LabelElementImpl labelElement = null;
    if (labelNode == null) {
      if (labelScope == null) {
      } else {
        labelElement = labelScope.lookup2(LabelScope.EMPTY_LABEL) as LabelElementImpl;
        if (labelElement == null) {
        }
        //
        // The label element that was returned was a marker for look-up and isn't stored in the
        // element model.
        //
        labelElement = null;
      }
    } else {
      if (labelScope == null) {
        _resolver.reportErrorForNode(CompileTimeErrorCode.LABEL_UNDEFINED, labelNode, [labelNode.name]);
      } else {
        labelElement = labelScope.lookup(labelNode) as LabelElementImpl;
        if (labelElement == null) {
          _resolver.reportErrorForNode(CompileTimeErrorCode.LABEL_UNDEFINED, labelNode, [labelNode.name]);
        } else {
          labelNode.staticElement = labelElement;
        }
      }
    }
    if (labelElement != null) {
      ExecutableElement labelContainer = labelElement.getAncestor((element) => element is ExecutableElement);
      if (labelContainer != _resolver.enclosingFunction) {
        _resolver.reportErrorForNode(CompileTimeErrorCode.LABEL_IN_OUTER_SCOPE, labelNode, [labelNode.name]);
        labelElement = null;
      }
    }
    return labelElement;
  }

  /**
   * Look up the method with the given name in the given type. Return the element representing the
   * method that was found, or `null` if there is no method with the given name.
   *
   * @param target the target of the invocation, or `null` if there is no target
   * @param type the type in which the method is defined
   * @param methodName the name of the method being looked up
   * @return the element representing the method that was found
   */
  MethodElement lookUpMethod(Expression target, Type2 type, String methodName) {
    type = resolveTypeParameter(type);
    if (type is InterfaceType) {
      InterfaceType interfaceType = type;
      MethodElement method;
      if (target is SuperExpression) {
        method = interfaceType.lookUpMethodInSuperclass(methodName, _definingLibrary);
      } else {
        method = interfaceType.lookUpMethod(methodName, _definingLibrary);
      }
      if (method != null) {
        return method;
      }
      return lookUpMethodInInterfaces(interfaceType, false, methodName, new Set<ClassElement>());
    }
    return null;
  }

  /**
   * Look up the method with the given name in the interfaces implemented by the given type, either
   * directly or indirectly. Return the element representing the method that was found, or
   * `null` if there is no method with the given name.
   *
   * @param targetType the type in which the member might be defined
   * @param includeTargetType `true` if the search should include the target type
   * @param methodName the name of the method being looked up
   * @param visitedInterfaces a set containing all of the interfaces that have been examined, used
   *          to prevent infinite recursion and to optimize the search
   * @return the element representing the method that was found
   */
  MethodElement lookUpMethodInInterfaces(InterfaceType targetType, bool includeTargetType, String methodName, Set<ClassElement> visitedInterfaces) {
    // TODO(brianwilkerson) This isn't correct. Section 8.1.1 of the specification (titled
    // "Inheritance and Overriding" under "Interfaces") describes a much more complex scheme for
    // finding the inherited member. We need to follow that scheme. The code below should cover the
    // 80% case.
    ClassElement targetClass = targetType.element;
    if (visitedInterfaces.contains(targetClass)) {
      return null;
    }
    visitedInterfaces.add(targetClass);
    if (includeTargetType) {
      MethodElement method = targetType.getMethod(methodName);
      if (method != null && method.isAccessibleIn(_definingLibrary)) {
        return method;
      }
    }
    for (InterfaceType interfaceType in targetType.interfaces) {
      MethodElement method = lookUpMethodInInterfaces(interfaceType, true, methodName, visitedInterfaces);
      if (method != null) {
        return method;
      }
    }
    for (InterfaceType mixinType in targetType.mixins) {
      MethodElement method = lookUpMethodInInterfaces(mixinType, true, methodName, visitedInterfaces);
      if (method != null) {
        return method;
      }
    }
    InterfaceType superclass = targetType.superclass;
    if (superclass == null) {
      return null;
    }
    return lookUpMethodInInterfaces(superclass, true, methodName, visitedInterfaces);
  }

  /**
   * Look up the setter with the given name in the given type. Return the element representing the
   * setter that was found, or `null` if there is no setter with the given name.
   *
   * @param target the target of the invocation, or `null` if there is no target
   * @param type the type in which the setter is defined
   * @param setterName the name of the setter being looked up
   * @return the element representing the setter that was found
   */
  PropertyAccessorElement lookUpSetter(Expression target, Type2 type, String setterName) {
    type = resolveTypeParameter(type);
    if (type is InterfaceType) {
      InterfaceType interfaceType = type;
      PropertyAccessorElement accessor;
      if (target is SuperExpression) {
        accessor = interfaceType.lookUpSetterInSuperclass(setterName, _definingLibrary);
      } else {
        accessor = interfaceType.lookUpSetter(setterName, _definingLibrary);
      }
      if (accessor != null) {
        return accessor;
      }
      return lookUpSetterInInterfaces(interfaceType, false, setterName, new Set<ClassElement>());
    }
    return null;
  }

  /**
   * Look up the setter with the given name in the interfaces implemented by the given type, either
   * directly or indirectly. Return the element representing the setter that was found, or
   * `null` if there is no setter with the given name.
   *
   * @param targetType the type in which the setter might be defined
   * @param includeTargetType `true` if the search should include the target type
   * @param setterName the name of the setter being looked up
   * @param visitedInterfaces a set containing all of the interfaces that have been examined, used
   *          to prevent infinite recursion and to optimize the search
   * @return the element representing the setter that was found
   */
  PropertyAccessorElement lookUpSetterInInterfaces(InterfaceType targetType, bool includeTargetType, String setterName, Set<ClassElement> visitedInterfaces) {
    // TODO(brianwilkerson) This isn't correct. Section 8.1.1 of the specification (titled
    // "Inheritance and Overriding" under "Interfaces") describes a much more complex scheme for
    // finding the inherited member. We need to follow that scheme. The code below should cover the
    // 80% case.
    ClassElement targetClass = targetType.element;
    if (visitedInterfaces.contains(targetClass)) {
      return null;
    }
    visitedInterfaces.add(targetClass);
    if (includeTargetType) {
      PropertyAccessorElement setter = targetType.getSetter(setterName);
      if (setter != null && setter.isAccessibleIn(_definingLibrary)) {
        return setter;
      }
    }
    for (InterfaceType interfaceType in targetType.interfaces) {
      PropertyAccessorElement setter = lookUpSetterInInterfaces(interfaceType, true, setterName, visitedInterfaces);
      if (setter != null) {
        return setter;
      }
    }
    for (InterfaceType mixinType in targetType.mixins) {
      PropertyAccessorElement setter = lookUpSetterInInterfaces(mixinType, true, setterName, visitedInterfaces);
      if (setter != null) {
        return setter;
      }
    }
    InterfaceType superclass = targetType.superclass;
    if (superclass == null) {
      return null;
    }
    return lookUpSetterInInterfaces(superclass, true, setterName, visitedInterfaces);
  }

  /**
   * Given some class element, this method uses [subtypeManager] to find the set of all
   * subtypes; the subtypes are then searched for a member (method, getter, or setter), that matches
   * a passed
   *
   * @param element the class element to search the subtypes of, if a non-ClassElement element is
   *          passed, then `false` is returned
   * @param memberName the member name to search for
   * @param asMethod `true` if the methods should be searched for in the subtypes
   * @param asAccessor `true` if the accessors (getters and setters) should be searched for in
   *          the subtypes
   * @return `true` if and only if the passed memberName was found in a subtype
   */
  bool memberFoundInSubclass(Element element, String memberName, bool asMethod, bool asAccessor) {
    if (element is ClassElement) {
      _subtypeManager.ensureLibraryVisited(_definingLibrary);
      Set<ClassElement> subtypeElements = _subtypeManager.computeAllSubtypes(element);
      for (ClassElement subtypeElement in subtypeElements) {
        if (asMethod && subtypeElement.getMethod(memberName) != null) {
          return true;
        } else if (asAccessor && (subtypeElement.getGetter(memberName) != null || subtypeElement.getSetter(memberName) != null)) {
          return true;
        }
      }
    }
    return false;
  }

  /**
   * Return the binary operator that is invoked by the given compound assignment operator.
   *
   * @param operator the assignment operator being mapped
   * @return the binary operator that invoked by the given assignment operator
   */
  sc.TokenType operatorFromCompoundAssignment(sc.TokenType operator) {
    while (true) {
      if (operator == sc.TokenType.AMPERSAND_EQ) {
        return sc.TokenType.AMPERSAND;
      } else if (operator == sc.TokenType.BAR_EQ) {
        return sc.TokenType.BAR;
      } else if (operator == sc.TokenType.CARET_EQ) {
        return sc.TokenType.CARET;
      } else if (operator == sc.TokenType.GT_GT_EQ) {
        return sc.TokenType.GT_GT;
      } else if (operator == sc.TokenType.LT_LT_EQ) {
        return sc.TokenType.LT_LT;
      } else if (operator == sc.TokenType.MINUS_EQ) {
        return sc.TokenType.MINUS;
      } else if (operator == sc.TokenType.PERCENT_EQ) {
        return sc.TokenType.PERCENT;
      } else if (operator == sc.TokenType.PLUS_EQ) {
        return sc.TokenType.PLUS;
      } else if (operator == sc.TokenType.SLASH_EQ) {
        return sc.TokenType.SLASH;
      } else if (operator == sc.TokenType.STAR_EQ) {
        return sc.TokenType.STAR;
      } else if (operator == sc.TokenType.TILDE_SLASH_EQ) {
        return sc.TokenType.TILDE_SLASH;
      } else {
        // Internal error: Unmapped assignment operator.
        AnalysisEngine.instance.logger.logError("Failed to map ${operator.lexeme} to it's corresponding operator");
        return operator;
      }
      break;
    }
  }

  void resolveAnnotationConstructorInvocationArguments(Annotation annotation, ConstructorElement constructor) {
    ArgumentList argumentList = annotation.arguments;
    // error will be reported in ConstantVerifier
    if (argumentList == null) {
      return;
    }
    // resolve arguments to parameters
    List<ParameterElement> parameters = resolveArgumentsToFunction(true, argumentList, constructor);
    if (parameters != null) {
      argumentList.correspondingStaticParameters = parameters;
    }
  }

  /**
   * Continues resolution of the given [Annotation].
   *
   * @param annotation the [Annotation] to resolve
   */
  void resolveAnnotationElement(Annotation annotation) {
    SimpleIdentifier nameNode1;
    SimpleIdentifier nameNode2;
    {
      Identifier annName = annotation.name;
      if (annName is PrefixedIdentifier) {
        PrefixedIdentifier prefixed = annName;
        nameNode1 = prefixed.prefix;
        nameNode2 = prefixed.identifier;
      } else {
        nameNode1 = annName as SimpleIdentifier;
        nameNode2 = null;
      }
    }
    SimpleIdentifier nameNode3 = annotation.constructorName;
    ConstructorElement constructor = null;
    //
    // CONST or Class(args)
    //
    if (nameNode1 != null && nameNode2 == null && nameNode3 == null) {
      Element element1 = nameNode1.staticElement;
      // CONST
      if (element1 is PropertyAccessorElement) {
        resolveAnnotationElementGetter(annotation, element1);
        return;
      }
      // Class(args)
      if (element1 is ClassElement) {
        ClassElement classElement = element1;
        constructor = new InterfaceTypeImpl.con1(classElement).lookUpConstructor(null, _definingLibrary);
      }
    }
    //
    // prefix.CONST or prefix.Class() or Class.CONST or Class.constructor(args)
    //
    if (nameNode1 != null && nameNode2 != null && nameNode3 == null) {
      Element element1 = nameNode1.staticElement;
      Element element2 = nameNode2.staticElement;
      // Class.CONST - not resolved yet
      if (element1 is ClassElement) {
        ClassElement classElement = element1;
        element2 = classElement.lookUpGetter(nameNode2.name, _definingLibrary);
      }
      // prefix.CONST or Class.CONST
      if (element2 is PropertyAccessorElement) {
        nameNode2.staticElement = element2;
        annotation.element = element2;
        resolveAnnotationElementGetter(annotation, element2 as PropertyAccessorElement);
        return;
      }
      // prefix.Class()
      if (element2 is ClassElement) {
        ClassElement classElement = element2 as ClassElement;
        constructor = classElement.unnamedConstructor;
      }
      // Class.constructor(args)
      if (element1 is ClassElement) {
        ClassElement classElement = element1;
        constructor = new InterfaceTypeImpl.con1(classElement).lookUpConstructor(nameNode2.name, _definingLibrary);
        nameNode2.staticElement = constructor;
      }
    }
    //
    // prefix.Class.CONST or prefix.Class.constructor(args)
    //
    if (nameNode1 != null && nameNode2 != null && nameNode3 != null) {
      Element element2 = nameNode2.staticElement;
      // element2 should be ClassElement
      if (element2 is ClassElement) {
        ClassElement classElement = element2;
        String name3 = nameNode3.name;
        // prefix.Class.CONST
        PropertyAccessorElement getter = classElement.lookUpGetter(name3, _definingLibrary);
        if (getter != null) {
          nameNode3.staticElement = getter;
          annotation.element = element2;
          resolveAnnotationElementGetter(annotation, getter);
          return;
        }
        // prefix.Class.constructor(args)
        constructor = new InterfaceTypeImpl.con1(classElement).lookUpConstructor(name3, _definingLibrary);
        nameNode3.staticElement = constructor;
      }
    }
    // we need constructor
    if (constructor == null) {
      _resolver.reportErrorForNode(CompileTimeErrorCode.INVALID_ANNOTATION, annotation, []);
      return;
    }
    // record element
    annotation.element = constructor;
    // resolve arguments
    resolveAnnotationConstructorInvocationArguments(annotation, constructor);
  }

  void resolveAnnotationElementGetter(Annotation annotation, PropertyAccessorElement accessorElement) {
    // accessor should be synthetic
    if (!accessorElement.isSynthetic) {
      _resolver.reportErrorForNode(CompileTimeErrorCode.INVALID_ANNOTATION, annotation, []);
      return;
    }
    // variable should be constant
    VariableElement variableElement = accessorElement.variable;
    if (!variableElement.isConst) {
      _resolver.reportErrorForNode(CompileTimeErrorCode.INVALID_ANNOTATION, annotation, []);
    }
    // OK
    return;
  }

  /**
   * Given a list of arguments and the element that will be invoked using those argument, compute
   * the list of parameters that correspond to the list of arguments. Return the parameters that
   * correspond to the arguments, or `null` if no correspondence could be computed.
   *
   * @param reportError if `true` then compile-time error should be reported; if `false`
   *          then compile-time warning
   * @param argumentList the list of arguments being passed to the element
   * @param executableElement the element that will be invoked with the arguments
   * @return the parameters that correspond to the arguments
   */
  List<ParameterElement> resolveArgumentsToFunction(bool reportError, ArgumentList argumentList, ExecutableElement executableElement) {
    if (executableElement == null) {
      return null;
    }
    List<ParameterElement> parameters = executableElement.parameters;
    return resolveArgumentsToParameters(reportError, argumentList, parameters);
  }

  /**
   * Given a list of arguments and the parameters related to the element that will be invoked using
   * those argument, compute the list of parameters that correspond to the list of arguments. Return
   * the parameters that correspond to the arguments.
   *
   * @param reportError if `true` then compile-time error should be reported; if `false`
   *          then compile-time warning
   * @param argumentList the list of arguments being passed to the element
   * @param parameters the of the function that will be invoked with the arguments
   * @return the parameters that correspond to the arguments
   */
  List<ParameterElement> resolveArgumentsToParameters(bool reportError, ArgumentList argumentList, List<ParameterElement> parameters) {
    List<ParameterElement> requiredParameters = new List<ParameterElement>();
    List<ParameterElement> positionalParameters = new List<ParameterElement>();
    Map<String, ParameterElement> namedParameters = new Map<String, ParameterElement>();
    for (ParameterElement parameter in parameters) {
      ParameterKind kind = parameter.parameterKind;
      if (identical(kind, ParameterKind.REQUIRED)) {
        requiredParameters.add(parameter);
      } else if (identical(kind, ParameterKind.POSITIONAL)) {
        positionalParameters.add(parameter);
      } else {
        namedParameters[parameter.name] = parameter;
      }
    }
    List<ParameterElement> unnamedParameters = new List<ParameterElement>.from(requiredParameters);
    unnamedParameters.addAll(positionalParameters);
    int unnamedParameterCount = unnamedParameters.length;
    int unnamedIndex = 0;
    NodeList<Expression> arguments = argumentList.arguments;
    int argumentCount = arguments.length;
    List<ParameterElement> resolvedParameters = new List<ParameterElement>(argumentCount);
    int positionalArgumentCount = 0;
    Set<String> usedNames = new Set<String>();
    for (int i = 0; i < argumentCount; i++) {
      Expression argument = arguments[i];
      if (argument is NamedExpression) {
        SimpleIdentifier nameNode = argument.name.label;
        String name = nameNode.name;
        ParameterElement element = namedParameters[name];
        if (element == null) {
          ErrorCode errorCode = (reportError ? CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER : StaticWarningCode.UNDEFINED_NAMED_PARAMETER) as ErrorCode;
          _resolver.reportErrorForNode(errorCode, nameNode, [name]);
        } else {
          resolvedParameters[i] = element;
          nameNode.staticElement = element;
        }
        if (!usedNames.add(name)) {
          _resolver.reportErrorForNode(CompileTimeErrorCode.DUPLICATE_NAMED_ARGUMENT, nameNode, [name]);
        }
      } else {
        positionalArgumentCount++;
        if (unnamedIndex < unnamedParameterCount) {
          resolvedParameters[i] = unnamedParameters[unnamedIndex++];
        }
      }
    }
    if (positionalArgumentCount < requiredParameters.length) {
      ErrorCode errorCode = (reportError ? CompileTimeErrorCode.NOT_ENOUGH_REQUIRED_ARGUMENTS : StaticWarningCode.NOT_ENOUGH_REQUIRED_ARGUMENTS) as ErrorCode;
      _resolver.reportErrorForNode(errorCode, argumentList, [requiredParameters.length, positionalArgumentCount]);
    } else if (positionalArgumentCount > unnamedParameterCount) {
      ErrorCode errorCode = (reportError ? CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS : StaticWarningCode.EXTRA_POSITIONAL_ARGUMENTS) as ErrorCode;
      _resolver.reportErrorForNode(errorCode, argumentList, [unnamedParameterCount, positionalArgumentCount]);
    }
    return resolvedParameters;
  }

  /**
   * Resolve the names in the given combinators in the scope of the given library.
   *
   * @param library the library that defines the names
   * @param combinators the combinators containing the names to be resolved
   */
  void resolveCombinators(LibraryElement library, NodeList<Combinator> combinators) {
    if (library == null) {
      //
      // The library will be null if the directive containing the combinators has a URI that is not
      // valid.
      //
      return;
    }
    Namespace namespace = new NamespaceBuilder().createExportNamespace2(library);
    for (Combinator combinator in combinators) {
      NodeList<SimpleIdentifier> names;
      if (combinator is HideCombinator) {
        names = combinator.hiddenNames;
      } else {
        names = (combinator as ShowCombinator).shownNames;
      }
      for (SimpleIdentifier name in names) {
        Element element = namespace.get(name.name);
        if (element != null) {
          name.staticElement = element;
        }
      }
    }
  }

  /**
   * Given an invocation of the form 'C.x()' where 'C' is a class, find and return the element 'x'
   * in 'C'.
   *
   * @param classElement the class element
   * @param nameNode the member name node
   */
  Element resolveElement(ClassElementImpl classElement, SimpleIdentifier nameNode) {
    String name = nameNode.name;
    Element element = null;
    element = classElement.getMethod(name);
    if (element == null && nameNode.inSetterContext()) {
      element = classElement.getSetter(name);
    }
    if (element == null && nameNode.inGetterContext()) {
      element = classElement.getGetter(name);
    }
    if (element != null && element.isAccessibleIn(_definingLibrary)) {
      return element;
    }
    return null;
  }

  /**
   * Given an invocation of the form 'm(a1, ..., an)', resolve 'm' to the element being invoked. If
   * the returned element is a method, then the method will be invoked. If the returned element is a
   * getter, the getter will be invoked without arguments and the result of that invocation will
   * then be invoked with the arguments.
   *
   * @param methodName the name of the method being invoked ('m')
   * @return the element being invoked
   */
  Element resolveInvokedElement(SimpleIdentifier methodName) {
    //
    // Look first in the lexical scope.
    //
    Element element = _resolver.nameScope.lookup(methodName, _definingLibrary);
    if (element == null) {
      //
      // If it isn't defined in the lexical scope, and the invocation is within a class, then look
      // in the inheritance scope.
      //
      ClassElement enclosingClass = _resolver.enclosingClass;
      if (enclosingClass != null) {
        InterfaceType enclosingType = enclosingClass.type;
        element = lookUpMethod(null, enclosingType, methodName.name);
        if (element == null) {
          //
          // If there's no method, then it's possible that 'm' is a getter that returns a function.
          //
          element = lookUpGetter(null, enclosingType, methodName.name);
        }
      }
    }
    // TODO(brianwilkerson) Report this error.
    return element;
  }

  /**
   * Given an invocation of the form 'e.m(a1, ..., an)', resolve 'e.m' to the element being invoked.
   * If the returned element is a method, then the method will be invoked. If the returned element
   * is a getter, the getter will be invoked without arguments and the result of that invocation
   * will then be invoked with the arguments.
   *
   * @param target the target of the invocation ('e')
   * @param targetType the type of the target
   * @param methodName the name of the method being invoked ('m')
   * @return the element being invoked
   */
  Element resolveInvokedElementWithTarget(Expression target, Type2 targetType, SimpleIdentifier methodName) {
    if (targetType is InterfaceType) {
      InterfaceType classType = targetType;
      Element element = lookUpMethod(target, classType, methodName.name);
      if (element == null) {
        //
        // If there's no method, then it's possible that 'm' is a getter that returns a function.
        //
        element = lookUpGetter(target, classType, methodName.name);
      }
      return element;
    } else if (target is SimpleIdentifier) {
      Element targetElement = target.staticElement;
      if (targetElement is PrefixElement) {
        //
        // Look to see whether the name of the method is really part of a prefixed identifier for an
        // imported top-level function or top-level getter that returns a function.
        //
        String name = "${target.name}.${methodName}";
        Identifier functionName = new ElementResolver_SyntheticIdentifier(name);
        Element element = _resolver.nameScope.lookup(functionName, _definingLibrary);
        if (element != null) {
          // TODO(brianwilkerson) This isn't a method invocation, it's a function invocation where
          // the function name is a prefixed identifier. Consider re-writing the AST.
          return element;
        }
      }
    }
    // TODO(brianwilkerson) Report this error.
    return null;
  }

  /**
   * Given that we are accessing a property of the given type with the given name, return the
   * element that represents the property.
   *
   * @param target the target of the invocation ('e')
   * @param targetType the type in which the search for the property should begin
   * @param propertyName the name of the property being accessed
   * @return the element that represents the property
   */
  ExecutableElement resolveProperty(Expression target, Type2 targetType, SimpleIdentifier propertyName) {
    ExecutableElement memberElement = null;
    if (propertyName.inSetterContext()) {
      memberElement = lookUpSetter(target, targetType, propertyName.name);
    }
    if (memberElement == null) {
      memberElement = lookUpGetter(target, targetType, propertyName.name);
    }
    if (memberElement == null) {
      memberElement = lookUpMethod(target, targetType, propertyName.name);
    }
    return memberElement;
  }

  void resolvePropertyAccess(Expression target, SimpleIdentifier propertyName) {
    Type2 staticType = getStaticType(target);
    Type2 propagatedType = getPropagatedType(target);
    Element staticElement = null;
    Element propagatedElement = null;
    //
    // If this property access is of the form 'C.m' where 'C' is a class, then we don't call
    // resolveProperty(..) which walks up the class hierarchy, instead we just look for the
    // member in the type only.
    //
    ClassElementImpl typeReference = getTypeReference(target);
    if (typeReference != null) {
      staticElement = propagatedElement = resolveElement(typeReference, propertyName);
    } else {
      staticElement = resolveProperty(target, staticType, propertyName);
      propagatedElement = resolveProperty(target, propagatedType, propertyName);
    }
    // May be part of annotation, record property element only if exists.
    // Error was already reported in validateAnnotationElement().
    if (target.parent.parent is Annotation) {
      if (staticElement != null) {
        propertyName.staticElement = staticElement;
      }
      return;
    }
    propertyName.staticElement = staticElement;
    propertyName.propagatedElement = propagatedElement;
    bool shouldReportMissingMember_static = shouldReportMissingMember(staticType, staticElement);
    bool shouldReportMissingMember_propagated = !shouldReportMissingMember_static && _enableHints ? shouldReportMissingMember(propagatedType, propagatedElement) : false;
    // If we are about to generate the hint (propagated version of this warning), then check
    // that the member is not in a subtype of the propagated type.
    if (shouldReportMissingMember_propagated) {
      if (memberFoundInSubclass(propagatedType.element, propertyName.name, false, true)) {
        shouldReportMissingMember_propagated = false;
      }
    }
    if (shouldReportMissingMember_static || shouldReportMissingMember_propagated) {
      if (staticType.isVoid) {
        if (propertyName.inSetterContext()) {
          ErrorCode errorCode = (shouldReportMissingMember_static ? StaticTypeWarningCode.UNDEFINED_SETTER : HintCode.UNDEFINED_SETTER) as ErrorCode;
          _resolver.reportErrorForNode(errorCode, propertyName, [propertyName.name, staticType.displayName]);
        } else if (propertyName.inGetterContext()) {
          ErrorCode errorCode = (shouldReportMissingMember_static ? StaticTypeWarningCode.UNDEFINED_GETTER : HintCode.UNDEFINED_GETTER) as ErrorCode;
          _resolver.reportErrorForNode(errorCode, propertyName, [propertyName.name, staticType.displayName]);
        } else {
          _resolver.reportErrorForNode(StaticWarningCode.UNDEFINED_IDENTIFIER, propertyName, [propertyName.name]);
        }
      }
      Element staticOrPropagatedEnclosingElt = shouldReportMissingMember_static ? staticType.element : propagatedType.element;
      if (staticOrPropagatedEnclosingElt != null) {
        bool isStaticProperty = isStatic(staticOrPropagatedEnclosingElt);
        if (propertyName.inSetterContext()) {
          if (isStaticProperty) {
            ErrorCode errorCode = (shouldReportMissingMember_static ? StaticWarningCode.UNDEFINED_SETTER : HintCode.UNDEFINED_SETTER) as ErrorCode;
            _resolver.reportErrorProxyConditionalAnalysisError(staticOrPropagatedEnclosingElt, errorCode, propertyName, [
                propertyName.name,
                staticOrPropagatedEnclosingElt.displayName]);
          } else {
            ErrorCode errorCode = (shouldReportMissingMember_static ? StaticTypeWarningCode.UNDEFINED_SETTER : HintCode.UNDEFINED_SETTER) as ErrorCode;
            _resolver.reportErrorProxyConditionalAnalysisError(staticOrPropagatedEnclosingElt, errorCode, propertyName, [
                propertyName.name,
                staticOrPropagatedEnclosingElt.displayName]);
          }
        } else if (propertyName.inGetterContext()) {
          if (isStaticProperty) {
            ErrorCode errorCode = (shouldReportMissingMember_static ? StaticWarningCode.UNDEFINED_GETTER : HintCode.UNDEFINED_GETTER) as ErrorCode;
            _resolver.reportErrorProxyConditionalAnalysisError(staticOrPropagatedEnclosingElt, errorCode, propertyName, [
                propertyName.name,
                staticOrPropagatedEnclosingElt.displayName]);
          } else {
            ErrorCode errorCode = (shouldReportMissingMember_static ? StaticTypeWarningCode.UNDEFINED_GETTER : HintCode.UNDEFINED_GETTER) as ErrorCode;
            _resolver.reportErrorProxyConditionalAnalysisError(staticOrPropagatedEnclosingElt, errorCode, propertyName, [
                propertyName.name,
                staticOrPropagatedEnclosingElt.displayName]);
          }
        } else {
          _resolver.reportErrorProxyConditionalAnalysisError(staticOrPropagatedEnclosingElt, StaticWarningCode.UNDEFINED_IDENTIFIER, propertyName, [propertyName.name]);
        }
      }
    }
  }

  /**
   * Resolve the given simple identifier if possible. Return the element to which it could be
   * resolved, or `null` if it could not be resolved. This does not record the results of the
   * resolution.
   *
   * @param node the identifier to be resolved
   * @return the element to which the identifier could be resolved
   */
  Element resolveSimpleIdentifier(SimpleIdentifier node) {
    Element element = _resolver.nameScope.lookup(node, _definingLibrary);
    if (element is PropertyAccessorElement && node.inSetterContext()) {
      PropertyInducingElement variable = (element as PropertyAccessorElement).variable;
      if (variable != null) {
        PropertyAccessorElement setter = variable.setter;
        if (setter == null) {
          //
          // Check to see whether there might be a locally defined getter and an inherited setter.
          //
          ClassElement enclosingClass = _resolver.enclosingClass;
          if (enclosingClass != null) {
            setter = lookUpSetter(null, enclosingClass.type, node.name);
          }
        }
        if (setter != null) {
          element = setter;
        }
      }
    } else if (element == null && node.inSetterContext()) {
      element = _resolver.nameScope.lookup(new ElementResolver_SyntheticIdentifier("${node.name}="), _definingLibrary);
    }
    ClassElement enclosingClass = _resolver.enclosingClass;
    if (element == null && enclosingClass != null) {
      InterfaceType enclosingType = enclosingClass.type;
      if (element == null && node.inSetterContext()) {
        element = lookUpSetter(null, enclosingType, node.name);
      }
      if (element == null && node.inGetterContext()) {
        element = lookUpGetter(null, enclosingType, node.name);
      }
      if (element == null) {
        element = lookUpMethod(null, enclosingType, node.name);
      }
    }
    return element;
  }

  /**
   * If the given type is a type parameter, resolve it to the type that should be used when looking
   * up members. Otherwise, return the original type.
   *
   * @param type the type that is to be resolved if it is a type parameter
   * @return the type that should be used in place of the argument if it is a type parameter, or the
   *         original argument if it isn't a type parameter
   */
  Type2 resolveTypeParameter(Type2 type) {
    if (type is TypeParameterType) {
      Type2 bound = type.element.bound;
      if (bound == null) {
        return _resolver.typeProvider.objectType;
      }
      return bound;
    }
    return type;
  }

  /**
   * Given a node that can have annotations associated with it and the element to which that node
   * has been resolved, create the annotations in the element model representing the annotations on
   * the node.
   *
   * @param element the element to which the node has been resolved
   * @param node the node that can have annotations associated with it
   */
  void setMetadata(Element element, AnnotatedNode node) {
    if (element is! ElementImpl) {
      return;
    }
    List<ElementAnnotationImpl> annotationList = new List<ElementAnnotationImpl>();
    addAnnotations(annotationList, node.metadata);
    if (node is VariableDeclaration && node.parent is VariableDeclarationList) {
      VariableDeclarationList list = node.parent as VariableDeclarationList;
      addAnnotations(annotationList, list.metadata);
      if (list.parent is FieldDeclaration) {
        FieldDeclaration fieldDeclaration = list.parent as FieldDeclaration;
        addAnnotations(annotationList, fieldDeclaration.metadata);
      } else if (list.parent is TopLevelVariableDeclaration) {
        TopLevelVariableDeclaration variableDeclaration = list.parent as TopLevelVariableDeclaration;
        addAnnotations(annotationList, variableDeclaration.metadata);
      }
    }
    if (!annotationList.isEmpty) {
      (element as ElementImpl).metadata = new List.from(annotationList);
    }
  }

  /**
   * Given a node that can have annotations associated with it and the element to which that node
   * has been resolved, create the annotations in the element model representing the annotations on
   * the node.
   *
   * @param element the element to which the node has been resolved
   * @param node the node that can have annotations associated with it
   */
  void setMetadataForParameter(Element element, NormalFormalParameter node) {
    if (element is! ElementImpl) {
      return;
    }
    List<ElementAnnotationImpl> annotationList = new List<ElementAnnotationImpl>();
    addAnnotations(annotationList, node.metadata);
    if (!annotationList.isEmpty) {
      (element as ElementImpl).metadata = new List.from(annotationList);
    }
  }

  /**
   * Return `true` if we should report an error as a result of looking up a member in the
   * given type and not finding any member.
   *
   * @param type the type in which we attempted to perform the look-up
   * @param member the result of the look-up
   * @return `true` if we should report an error
   */
  bool shouldReportMissingMember(Type2 type, Element member) {
    if (member != null || type == null || type.isDynamic || type.isBottom) {
      return false;
    }
    return true;
  }
}

/**
 * Instances of the class `SyntheticIdentifier` implement an identifier that can be used to
 * look up names in the lexical scope when there is no identifier in the AST structure. There is
 * no identifier in the AST when the parser could not distinguish between a method invocation and
 * an invocation of a top-level function imported with a prefix.
 */
class ElementResolver_SyntheticIdentifier extends Identifier {
  /**
   * The name of the synthetic identifier.
   */
  final String name;

  /**
   * Initialize a newly created synthetic identifier to have the given name.
   *
   * @param name the name of the synthetic identifier
   */
  ElementResolver_SyntheticIdentifier(this.name);

  accept(AstVisitor visitor) => null;

  sc.Token get beginToken => null;

  Element get bestElement => null;

  sc.Token get endToken => null;

  int get precedence => 16;

  Element get propagatedElement => null;

  Element get staticElement => null;

  void visitChildren(AstVisitor visitor) {
  }
}

/**
 * Instances of the class `IncrementalResolver` resolve the smallest portion of an AST
 * structure that we currently know how to resolve.
 */
class IncrementalResolver {
  /**
   * The element for the library containing the compilation unit being visited.
   */
  LibraryElement _definingLibrary;

  /**
   * The source representing the compilation unit being visited.
   */
  Source _source;

  /**
   * The object used to access the types from the core library.
   */
  TypeProvider _typeProvider;

  /**
   * The error listener that will be informed of any errors that are found during resolution.
   */
  AnalysisErrorListener _errorListener;

  /**
   * Initialize a newly created incremental resolver to resolve a node in the given source in the
   * given library, reporting errors to the given error listener.
   *
   * @param definingLibrary the element for the library containing the compilation unit being
   *          visited
   * @param source the source representing the compilation unit being visited
   * @param typeProvider the object used to access the types from the core library
   * @param errorListener the error listener that will be informed of any errors that are found
   *          during resolution
   */
  IncrementalResolver(LibraryElement definingLibrary, Source source, TypeProvider typeProvider, AnalysisErrorListener errorListener) {
    this._definingLibrary = definingLibrary;
    this._source = source;
    this._typeProvider = typeProvider;
    this._errorListener = errorListener;
  }

  /**
   * Resolve the given node, reporting any errors or warnings to the given listener.
   *
   * @param node the root of the AST structure to be resolved
   * @throws AnalysisException if the node could not be resolved
   */
  void resolve(AstNode node) {
    AstNode rootNode = findResolutionRoot(node);
    Scope scope = ScopeBuilder.scopeFor(rootNode, _errorListener);
    if (elementModelChanged(rootNode.parent)) {
      throw new AnalysisException.con1("Cannot resolve node: element model changed");
    }
    resolveTypes(node, scope);
    resolveVariables(node, scope);
    resolveReferences(node, scope);
  }

  /**
   * Return `true` if the given node can be resolved independently of any other nodes.
   *
   * <b>Note:</b> This method needs to be kept in sync with [ScopeBuilder#scopeForAstNode].
   *
   * @param node the node being tested
   * @return `true` if the given node can be resolved independently of any other nodes
   */
  bool canBeResolved(AstNode node) => node is ClassDeclaration || node is ClassTypeAlias || node is CompilationUnit || node is ConstructorDeclaration || node is FunctionDeclaration || node is FunctionTypeAlias || node is MethodDeclaration;

  /**
   * Return `true` if the portion of the element model defined by the given node has changed.
   *
   * @param node the node defining the portion of the element model being tested
   * @return `true` if the element model defined by the given node has changed
   * @throws AnalysisException if the correctness of the element model cannot be determined
   */
  bool elementModelChanged(AstNode node) {
    Element element = getElement(node);
    if (element == null) {
      throw new AnalysisException.con1("Cannot resolve node: a ${node.runtimeType.toString()} does not define an element");
    }
    DeclarationMatcher matcher = new DeclarationMatcher();
    return !matcher.matches(node, element);
  }

  /**
   * Starting at the given node, find the smallest AST node that can be resolved independently of
   * any other nodes. Return the node that was found.
   *
   * @param node the node at which the search is to begin
   * @return the smallest AST node that can be resolved independently of any other nodes
   * @throws AnalysisException if there is no such node
   */
  AstNode findResolutionRoot(AstNode node) {
    AstNode result = node;
    AstNode parent = result.parent;
    while (parent != null && !canBeResolved(parent)) {
      result = parent;
      parent = result.parent;
    }
    if (parent == null) {
      throw new AnalysisException.con1("Cannot resolve node: no resolvable node");
    }
    return result;
  }

  /**
   * Return the element defined by the given node, or `null` if the node does not define an
   * element.
   *
   * @param node the node defining the element to be returned
   * @return the element defined by the given node
   */
  Element getElement(AstNode node) {
    if (node is Declaration) {
      return node.element;
    } else if (node is CompilationUnit) {
      return node.element;
    }
    return null;
  }

  void resolveReferences(AstNode node, Scope scope) {
    ResolverVisitor visitor = new ResolverVisitor.con3(_definingLibrary, _source, _typeProvider, scope, _errorListener);
    node.accept(visitor);
    for (ProxyConditionalAnalysisError conditionalCode in visitor.proxyConditionalAnalysisErrors) {
      if (conditionalCode.shouldIncludeErrorCode()) {
        visitor.reportError(conditionalCode.analysisError);
      }
    }
  }

  void resolveTypes(AstNode node, Scope scope) {
    TypeResolverVisitor visitor = new TypeResolverVisitor.con3(_definingLibrary, _source, _typeProvider, scope, _errorListener);
    node.accept(visitor);
  }

  void resolveVariables(AstNode node, Scope scope) {
    VariableResolverVisitor visitor = new VariableResolverVisitor.con2(_definingLibrary, _source, _typeProvider, scope, _errorListener);
    node.accept(visitor);
  }
}

/**
 * Instances of the class `InheritanceManager` manage the knowledge of where class members
 * (methods, getters & setters) are inherited from.
 */
class InheritanceManager {
  /**
   * Given some array of [ExecutableElement]s, this method creates a synthetic element as
   * described in the Superinterfaces section of Inheritance and Overriding.
   *
   * TODO (jwren) Copy contents from the Spec into this javadoc.
   *
   * TODO (jwren) Associate a propagated type to the synthetic method element using least upper
   * bound calls
   */
  static ExecutableElement computeMergedExecutableElement(List<ExecutableElement> elementArrayToMerge) {
    int h = getNumOfPositionalParameters(elementArrayToMerge[0]);
    int r = getNumOfRequiredParameters(elementArrayToMerge[0]);
    Set<String> namedParametersList = new Set<String>();
    for (int i = 1; i < elementArrayToMerge.length; i++) {
      ExecutableElement element = elementArrayToMerge[i];
      int numOfPositionalParams = getNumOfPositionalParameters(element);
      if (h < numOfPositionalParams) {
        h = numOfPositionalParams;
      }
      int numOfRequiredParams = getNumOfRequiredParameters(element);
      if (r > numOfRequiredParams) {
        r = numOfRequiredParams;
      }
      namedParametersList.addAll(getNamedParameterNames(element));
    }
    if (r > h) {
      return null;
    }
    return createSyntheticExecutableElement(elementArrayToMerge, elementArrayToMerge[0].displayName, r, h - r, new List.from(namedParametersList));
  }

  /**
   * Used by [computeMergedExecutableElement] to actually create the
   * synthetic element.
   *
   * @param elementArrayToMerge the array used to create the synthetic element
   * @param name the name of the method, getter or setter
   * @param numOfRequiredParameters the number of required parameters
   * @param numOfPositionalParameters the number of positional parameters
   * @param namedParameters the list of [String]s that are the named parameters
   * @return the created synthetic element
   */
  static ExecutableElement createSyntheticExecutableElement(List<ExecutableElement> elementArrayToMerge, String name, int numOfRequiredParameters, int numOfPositionalParameters, List<String> namedParameters) {
    DynamicTypeImpl dynamicType = DynamicTypeImpl.instance;
    SimpleIdentifier nameIdentifier = new SimpleIdentifier(new sc.StringToken(sc.TokenType.IDENTIFIER, name, 0));
    ExecutableElementImpl executable;
    if (elementArrayToMerge[0] is MethodElement) {
      MultiplyInheritedMethodElementImpl unionedMethod = new MultiplyInheritedMethodElementImpl(nameIdentifier);
      unionedMethod.inheritedElements = elementArrayToMerge;
      executable = unionedMethod;
    } else {
      MultiplyInheritedPropertyAccessorElementImpl unionedPropertyAccessor = new MultiplyInheritedPropertyAccessorElementImpl(nameIdentifier);
      unionedPropertyAccessor.getter = (elementArrayToMerge[0] as PropertyAccessorElement).isGetter;
      unionedPropertyAccessor.setter = (elementArrayToMerge[0] as PropertyAccessorElement).isSetter;
      unionedPropertyAccessor.inheritedElements = elementArrayToMerge;
      executable = unionedPropertyAccessor;
    }
    int numOfParameters = numOfRequiredParameters + numOfPositionalParameters + namedParameters.length;
    List<ParameterElement> parameters = new List<ParameterElement>(numOfParameters);
    int i = 0;
    for (int j = 0; j < numOfRequiredParameters; j++, i++) {
      ParameterElementImpl parameter = new ParameterElementImpl.con2("", 0);
      parameter.type = dynamicType;
      parameter.parameterKind = ParameterKind.REQUIRED;
      parameters[i] = parameter;
    }
    for (int k = 0; k < numOfPositionalParameters; k++, i++) {
      ParameterElementImpl parameter = new ParameterElementImpl.con2("", 0);
      parameter.type = dynamicType;
      parameter.parameterKind = ParameterKind.POSITIONAL;
      parameters[i] = parameter;
    }
    for (int m = 0; m < namedParameters.length; m++, i++) {
      ParameterElementImpl parameter = new ParameterElementImpl.con2(namedParameters[m], 0);
      parameter.type = dynamicType;
      parameter.parameterKind = ParameterKind.NAMED;
      parameters[i] = parameter;
    }
    executable.returnType = dynamicType;
    executable.parameters = parameters;
    FunctionTypeImpl methodType = new FunctionTypeImpl.con1(executable);
    executable.type = methodType;
    return executable;
  }

  /**
   * Given some [ExecutableElement], return the list of named parameters.
   */
  static List<String> getNamedParameterNames(ExecutableElement executableElement) {
    List<String> namedParameterNames = new List<String>();
    List<ParameterElement> parameters = executableElement.parameters;
    for (int i = 0; i < parameters.length; i++) {
      ParameterElement parameterElement = parameters[i];
      if (identical(parameterElement.parameterKind, ParameterKind.NAMED)) {
        namedParameterNames.add(parameterElement.name);
      }
    }
    return namedParameterNames;
  }

  /**
   * Given some [ExecutableElement] return the number of parameters of the specified kind.
   */
  static int getNumOfParameters(ExecutableElement executableElement, ParameterKind parameterKind) {
    int parameterCount = 0;
    List<ParameterElement> parameters = executableElement.parameters;
    for (int i = 0; i < parameters.length; i++) {
      ParameterElement parameterElement = parameters[i];
      if (identical(parameterElement.parameterKind, parameterKind)) {
        parameterCount++;
      }
    }
    return parameterCount;
  }

  /**
   * Given some [ExecutableElement] return the number of positional parameters.
   *
   * Note: by positional we mean [ParameterKind#REQUIRED] or [ParameterKind#POSITIONAL].
   */
  static int getNumOfPositionalParameters(ExecutableElement executableElement) => getNumOfParameters(executableElement, ParameterKind.REQUIRED) + getNumOfParameters(executableElement, ParameterKind.POSITIONAL);

  /**
   * Given some [ExecutableElement] return the number of required parameters.
   */
  static int getNumOfRequiredParameters(ExecutableElement executableElement) => getNumOfParameters(executableElement, ParameterKind.REQUIRED);

  /**
   * Given some [ExecutableElement] returns `true` if it is an abstract member of a
   * class.
   *
   * @param executableElement some [ExecutableElement] to evaluate
   * @return `true` if the given element is an abstract member of a class
   */
  static bool isAbstract(ExecutableElement executableElement) {
    if (executableElement is MethodElement) {
      return executableElement.isAbstract;
    } else if (executableElement is PropertyAccessorElement) {
      return executableElement.isAbstract;
    }
    return false;
  }

  /**
   * The [LibraryElement] that is managed by this manager.
   */
  LibraryElement _library;

  /**
   * This is a mapping between each [ClassElement] and a map between the [String] member
   * names and the associated [ExecutableElement] in the mixin and superclass chain.
   */
  Map<ClassElement, MemberMap> _classLookup;

  /**
   * This is a mapping between each [ClassElement] and a map between the [String] member
   * names and the associated [ExecutableElement] in the interface set.
   */
  Map<ClassElement, MemberMap> _interfaceLookup;

  /**
   * A map between each visited [ClassElement] and the set of [AnalysisError]s found on
   * the class element.
   */
  Map<ClassElement, Set<AnalysisError>> _errorsInClassElement = new Map<ClassElement, Set<AnalysisError>>();

  /**
   * Initialize a newly created inheritance manager.
   *
   * @param library the library element context that the inheritance mappings are being generated
   */
  InheritanceManager(LibraryElement library) {
    this._library = library;
    _classLookup = new Map<ClassElement, MemberMap>();
    _interfaceLookup = new Map<ClassElement, MemberMap>();
  }

  /**
   * Return the set of [AnalysisError]s found on the passed [ClassElement], or
   * `null` if there are none.
   *
   * @param classElt the class element to query
   * @return the set of [AnalysisError]s found on the passed [ClassElement], or
   *         `null` if there are none
   */
  Set<AnalysisError> getErrors(ClassElement classElt) => _errorsInClassElement[classElt];

  /**
   * Get and return a mapping between the set of all string names of the members inherited from the
   * passed [ClassElement] superclass hierarchy, and the associated [ExecutableElement].
   *
   * @param classElt the class element to query
   * @return a mapping between the set of all members inherited from the passed [ClassElement]
   *         superclass hierarchy, and the associated [ExecutableElement]
   */
  MemberMap getMapOfMembersInheritedFromClasses(ClassElement classElt) => computeClassChainLookupMap(classElt, new Set<ClassElement>());

  /**
   * Get and return a mapping between the set of all string names of the members inherited from the
   * passed [ClassElement] interface hierarchy, and the associated [ExecutableElement].
   *
   * @param classElt the class element to query
   * @return a mapping between the set of all string names of the members inherited from the passed
   *         [ClassElement] interface hierarchy, and the associated [ExecutableElement].
   */
  MemberMap getMapOfMembersInheritedFromInterfaces(ClassElement classElt) => computeInterfaceLookupMap(classElt, new Set<ClassElement>());

  /**
   * Given some [ClassElement] and some member name, this returns the
   * [ExecutableElement] that the class inherits from the mixins,
   * superclasses or interfaces, that has the member name, if no member is inherited `null` is
   * returned.
   *
   * @param classElt the class element to query
   * @param memberName the name of the executable element to find and return
   * @return the inherited executable element with the member name, or `null` if no such
   *         member exists
   */
  ExecutableElement lookupInheritance(ClassElement classElt, String memberName) {
    if (memberName == null || memberName.isEmpty) {
      return null;
    }
    ExecutableElement executable = computeClassChainLookupMap(classElt, new Set<ClassElement>()).get(memberName);
    if (executable == null) {
      return computeInterfaceLookupMap(classElt, new Set<ClassElement>()).get(memberName);
    }
    return executable;
  }

  /**
   * Given some [ClassElement] and some member name, this returns the
   * [ExecutableElement] that the class either declares itself, or
   * inherits, that has the member name, if no member is inherited `null` is returned.
   *
   * @param classElt the class element to query
   * @param memberName the name of the executable element to find and return
   * @return the inherited executable element with the member name, or `null` if no such
   *         member exists
   */
  ExecutableElement lookupMember(ClassElement classElt, String memberName) {
    ExecutableElement element = lookupMemberInClass(classElt, memberName);
    if (element != null) {
      return element;
    }
    return lookupInheritance(classElt, memberName);
  }

  /**
   * Given some [InterfaceType] and some member name, this returns the
   * [FunctionType] of the [ExecutableElement] that the
   * class either declares itself, or inherits, that has the member name, if no member is inherited
   * `null` is returned. The returned [FunctionType] has all type
   * parameters substituted with corresponding type arguments from the given [InterfaceType].
   *
   * @param interfaceType the interface type to query
   * @param memberName the name of the executable element to find and return
   * @return the member's function type, or `null` if no such member exists
   */
  FunctionType lookupMemberType(InterfaceType interfaceType, String memberName) {
    ExecutableElement iteratorMember = lookupMember(interfaceType.element, memberName);
    if (iteratorMember == null) {
      return null;
    }
    return substituteTypeArgumentsInMemberFromInheritance(iteratorMember.type, memberName, interfaceType);
  }

  /**
   * Set the new library element context.
   *
   * @param library the new library element
   */
  void set libraryElement(LibraryElement library) {
    this._library = library;
  }

  /**
   * This method takes some inherited [FunctionType], and resolves all the parameterized types
   * in the function type, dependent on the class in which it is being overridden.
   *
   * @param baseFunctionType the function type that is being overridden
   * @param memberName the name of the member, this is used to lookup the inheritance path of the
   *          override
   * @param definingType the type that is overriding the member
   * @return the passed function type with any parameterized types substituted
   */
  FunctionType substituteTypeArgumentsInMemberFromInheritance(FunctionType baseFunctionType, String memberName, InterfaceType definingType) {
    if (baseFunctionType == null) {
      return baseFunctionType;
    }
    // First, generate the path from the defining type to the overridden member
    Queue<InterfaceType> inheritancePath = new Queue<InterfaceType>();
    computeInheritancePath(inheritancePath, definingType, memberName);
    if (inheritancePath == null || inheritancePath.isEmpty) {
      // TODO(jwren) log analysis engine error
      return baseFunctionType;
    }
    FunctionType functionTypeToReturn = baseFunctionType;
    // loop backward through the list substituting as we go:
    while (!inheritancePath.isEmpty) {
      InterfaceType lastType = inheritancePath.removeLast();
      List<Type2> parameterTypes = lastType.element.type.typeArguments;
      List<Type2> argumentTypes = lastType.typeArguments;
      functionTypeToReturn = functionTypeToReturn.substitute2(argumentTypes, parameterTypes);
    }
    return functionTypeToReturn;
  }

  /**
   * Compute and return a mapping between the set of all string names of the members inherited from
   * the passed [ClassElement] superclass hierarchy, and the associated
   * [ExecutableElement].
   *
   * @param classElt the class element to query
   * @param visitedClasses a set of visited classes passed back into this method when it calls
   *          itself recursively
   * @return a mapping between the set of all string names of the members inherited from the passed
   *         [ClassElement] superclass hierarchy, and the associated [ExecutableElement]
   */
  MemberMap computeClassChainLookupMap(ClassElement classElt, Set<ClassElement> visitedClasses) {
    MemberMap resultMap = _classLookup[classElt];
    if (resultMap != null) {
      return resultMap;
    } else {
      resultMap = new MemberMap();
    }
    ClassElement superclassElt = null;
    InterfaceType supertype = classElt.supertype;
    if (supertype != null) {
      superclassElt = supertype.element;
    } else {
      // classElt is Object
      _classLookup[classElt] = resultMap;
      return resultMap;
    }
    if (superclassElt != null) {
      if (!visitedClasses.contains(superclassElt)) {
        visitedClasses.add(superclassElt);
        try {
          resultMap = new MemberMap.con2(computeClassChainLookupMap(superclassElt, visitedClasses));
          //
          // Substitute the super types down the hierarchy.
          //
          substituteTypeParametersDownHierarchy(supertype, resultMap);
          //
          // Include the members from the superclass in the resultMap.
          //
          recordMapWithClassMembers(resultMap, supertype, false);
        } finally {
          visitedClasses.remove(superclassElt);
        }
      } else {
        // This case happens only when the superclass was previously visited and not in the lookup,
        // meaning this is meant to shorten the compute for recursive cases.
        _classLookup[superclassElt] = resultMap;
        return resultMap;
      }
    }
    //
    // Include the members from the mixins in the resultMap
    //
    List<InterfaceType> mixins = classElt.mixins;
    for (int i = mixins.length - 1; i >= 0; i--) {
      ClassElement mixinElement = mixins[i].element;
      if (mixinElement != null) {
        if (!visitedClasses.contains(mixinElement)) {
          visitedClasses.add(mixinElement);
          try {
            MemberMap map = new MemberMap.con2(computeClassChainLookupMap(mixinElement, visitedClasses));
            //
            // Substitute the super types down the hierarchy.
            //
            substituteTypeParametersDownHierarchy(mixins[i], map);
            //
            // Include the members from the superclass in the resultMap.
            //
            recordMapWithClassMembers(map, mixins[i], false);
            //
            // Add the members from map into result map.
            //
            for (int j = 0; j < map.size; j++) {
              String key = map.getKey(j);
              ExecutableElement value = map.getValue(j);
              if (key != null) {
                if (resultMap.get(key) == null || (resultMap.get(key) != null && !isAbstract(value))) {
                  resultMap.put(key, value);
                }
              }
            }
          } finally {
            visitedClasses.remove(mixinElement);
          }
        } else {
          // This case happens only when the superclass was previously visited and not in the lookup,
          // meaning this is meant to shorten the compute for recursive cases.
          _classLookup[mixinElement] = resultMap;
          return resultMap;
        }
      }
    }
    _classLookup[classElt] = resultMap;
    return resultMap;
  }

  /**
   * Compute and return the inheritance path given the context of a type and a member that is
   * overridden in the inheritance path (for which the type is in the path).
   *
   * @param chain the inheritance path that is built up as this method calls itself recursively,
   *          when this method is called an empty [LinkedList] should be provided
   * @param currentType the current type in the inheritance path
   * @param memberName the name of the member that is being looked up the inheritance path
   */
  void computeInheritancePath(Queue<InterfaceType> chain, InterfaceType currentType, String memberName) {
    // TODO (jwren) create a public version of this method which doesn't require the initial chain
    // to be provided, then provided tests for this functionality in InheritanceManagerTest
    chain.add(currentType);
    ClassElement classElt = currentType.element;
    InterfaceType supertype = classElt.supertype;
    // Base case- reached Object
    if (supertype == null) {
      // Looked up the chain all the way to Object, return null.
      // This should never happen.
      return;
    }
    // If we are done, return the chain
    // We are not done if this is the first recursive call on this method.
    if (chain.length != 1) {
      // We are done however if the member is in this classElt
      if (lookupMemberInClass(classElt, memberName) != null) {
        return;
      }
    }
    // Mixins- note that mixins call lookupMemberInClass, not lookupMember
    List<InterfaceType> mixins = classElt.mixins;
    for (int i = mixins.length - 1; i >= 0; i--) {
      ClassElement mixinElement = mixins[i].element;
      if (mixinElement != null) {
        ExecutableElement elt = lookupMemberInClass(mixinElement, memberName);
        if (elt != null) {
          // this is equivalent (but faster than) calling this method recursively
          // (return computeInheritancePath(chain, mixins[i], memberName);)
          chain.add(mixins[i]);
          return;
        }
      }
    }
    // Superclass
    ClassElement superclassElt = supertype.element;
    if (lookupMember(superclassElt, memberName) != null) {
      computeInheritancePath(chain, supertype, memberName);
      return;
    }
    // Interfaces
    List<InterfaceType> interfaces = classElt.interfaces;
    for (InterfaceType interfaceType in interfaces) {
      ClassElement interfaceElement = interfaceType.element;
      if (interfaceElement != null && lookupMember(interfaceElement, memberName) != null) {
        computeInheritancePath(chain, interfaceType, memberName);
        return;
      }
    }
  }

  /**
   * Compute and return a mapping between the set of all string names of the members inherited from
   * the passed [ClassElement] interface hierarchy, and the associated
   * [ExecutableElement].
   *
   * @param classElt the class element to query
   * @param visitedInterfaces a set of visited classes passed back into this method when it calls
   *          itself recursively
   * @return a mapping between the set of all string names of the members inherited from the passed
   *         [ClassElement] interface hierarchy, and the associated [ExecutableElement]
   */
  MemberMap computeInterfaceLookupMap(ClassElement classElt, Set<ClassElement> visitedInterfaces) {
    MemberMap resultMap = _interfaceLookup[classElt];
    if (resultMap != null) {
      return resultMap;
    } else {
      resultMap = new MemberMap();
    }
    InterfaceType supertype = classElt.supertype;
    ClassElement superclassElement = supertype != null ? supertype.element : null;
    List<InterfaceType> mixins = classElt.mixins;
    List<InterfaceType> interfaces = classElt.interfaces;
    // Recursively collect the list of mappings from all of the interface types
    List<MemberMap> lookupMaps = new List<MemberMap>();
    //
    // Superclass element
    //
    if (superclassElement != null) {
      if (!visitedInterfaces.contains(superclassElement)) {
        try {
          visitedInterfaces.add(superclassElement);
          //
          // Recursively compute the map for the super type.
          //
          MemberMap map = computeInterfaceLookupMap(superclassElement, visitedInterfaces);
          map = new MemberMap.con2(map);
          //
          // Substitute the super type down the hierarchy.
          //
          substituteTypeParametersDownHierarchy(supertype, map);
          //
          // Add any members from the super type into the map as well.
          //
          recordMapWithClassMembers(map, supertype, true);
          lookupMaps.add(map);
        } finally {
          visitedInterfaces.remove(superclassElement);
        }
      } else {
        MemberMap map = _interfaceLookup[classElt];
        if (map != null) {
          lookupMaps.add(map);
        } else {
          _interfaceLookup[superclassElement] = resultMap;
          return resultMap;
        }
      }
    }
    //
    // Mixin elements
    //
    for (int i = mixins.length - 1; i >= 0; i--) {
      InterfaceType mixinType = mixins[i];
      ClassElement mixinElement = mixinType.element;
      if (mixinElement != null) {
        if (!visitedInterfaces.contains(mixinElement)) {
          try {
            visitedInterfaces.add(mixinElement);
            //
            // Recursively compute the map for the mixin.
            //
            MemberMap map = computeInterfaceLookupMap(mixinElement, visitedInterfaces);
            map = new MemberMap.con2(map);
            //
            // Substitute the mixin type down the hierarchy.
            //
            substituteTypeParametersDownHierarchy(mixinType, map);
            //
            // Add any members from the mixin type into the map as well.
            //
            recordMapWithClassMembers(map, mixinType, true);
            lookupMaps.add(map);
          } finally {
            visitedInterfaces.remove(mixinElement);
          }
        } else {
          MemberMap map = _interfaceLookup[classElt];
          if (map != null) {
            lookupMaps.add(map);
          } else {
            _interfaceLookup[mixinElement] = resultMap;
            return resultMap;
          }
        }
      }
    }
    //
    // Interface elements
    //
    for (InterfaceType interfaceType in interfaces) {
      ClassElement interfaceElement = interfaceType.element;
      if (interfaceElement != null) {
        if (!visitedInterfaces.contains(interfaceElement)) {
          try {
            visitedInterfaces.add(interfaceElement);
            //
            // Recursively compute the map for the interfaces.
            //
            MemberMap map = computeInterfaceLookupMap(interfaceElement, visitedInterfaces);
            map = new MemberMap.con2(map);
            //
            // Substitute the supertypes down the hierarchy
            //
            substituteTypeParametersDownHierarchy(interfaceType, map);
            //
            // And add any members from the interface into the map as well.
            //
            recordMapWithClassMembers(map, interfaceType, true);
            lookupMaps.add(map);
          } finally {
            visitedInterfaces.remove(interfaceElement);
          }
        } else {
          MemberMap map = _interfaceLookup[classElt];
          if (map != null) {
            lookupMaps.add(map);
          } else {
            _interfaceLookup[interfaceElement] = resultMap;
            return resultMap;
          }
        }
      }
    }
    if (lookupMaps.length == 0) {
      _interfaceLookup[classElt] = resultMap;
      return resultMap;
    }
    //
    // Union all of the lookupMaps together into unionMap, grouping the ExecutableElements into a
    // list where none of the elements are equal where equality is determined by having equal
    // function types. (We also take note too of the kind of the element: ()->int and () -> int may
    // not be equal if one is a getter and the other is a method.)
    //
    Map<String, List<ExecutableElement>> unionMap = new Map<String, List<ExecutableElement>>();
    for (MemberMap lookupMap in lookupMaps) {
      int lookupMapSize = lookupMap.size;
      for (int i = 0; i < lookupMapSize; i++) {
        // Get the string key, if null, break.
        String key = lookupMap.getKey(i);
        if (key == null) {
          break;
        }
        // Get the list value out of the unionMap
        List<ExecutableElement> list = unionMap[key];
        // If we haven't created such a map for this key yet, do create it and put the list entry
        // into the unionMap.
        if (list == null) {
          list = new List<ExecutableElement>();
          unionMap[key] = list;
        }
        // Fetch the entry out of this lookupMap
        ExecutableElement newExecutableElementEntry = lookupMap.getValue(i);
        if (list.isEmpty) {
          // If the list is empty, just the new value
          list.add(newExecutableElementEntry);
        } else {
          // Otherwise, only add the newExecutableElementEntry if it isn't already in the list, this
          // covers situation where a class inherits two methods (or two getters) that are
          // identical.
          bool alreadyInList = false;
          bool isMethod1 = newExecutableElementEntry is MethodElement;
          for (ExecutableElement executableElementInList in list) {
            bool isMethod2 = executableElementInList is MethodElement;
            if (identical(isMethod1, isMethod2) && executableElementInList.type == newExecutableElementEntry.type) {
              alreadyInList = true;
              break;
            }
          }
          if (!alreadyInList) {
            list.add(newExecutableElementEntry);
          }
        }
      }
    }
    //
    // Loop through the entries in the unionMap, adding them to the resultMap appropriately.
    //
    for (MapEntry<String, List<ExecutableElement>> entry in getMapEntrySet(unionMap)) {
      String key = entry.getKey();
      List<ExecutableElement> list = entry.getValue();
      int numOfEltsWithMatchingNames = list.length;
      if (numOfEltsWithMatchingNames == 1) {
        //
        // Example: class A inherits only 1 method named 'm'.  Since it is the only such method, it
        // is inherited.
        // Another example: class A inherits 2 methods named 'm' from 2 different interfaces, but
        // they both have the same signature, so it is the method inherited.
        //
        resultMap.put(key, list[0]);
      } else {
        //
        // Then numOfEltsWithMatchingNames > 1, check for the warning cases.
        //
        bool allMethods = true;
        bool allSetters = true;
        bool allGetters = true;
        for (ExecutableElement executableElement in list) {
          if (executableElement is PropertyAccessorElement) {
            allMethods = false;
            if (executableElement.isSetter) {
              allGetters = false;
            } else {
              allSetters = false;
            }
          } else {
            allGetters = false;
            allSetters = false;
          }
        }
        //
        // If there isn't a mixture of methods with getters, then continue, otherwise create a
        // warning.
        //
        if (allMethods || allGetters || allSetters) {
          //
          // Compute the element whose type is the subtype of all of the other types.
          //
          List<ExecutableElement> elements = new List.from(list);
          List<FunctionType> executableElementTypes = new List<FunctionType>(numOfEltsWithMatchingNames);
          for (int i = 0; i < numOfEltsWithMatchingNames; i++) {
            executableElementTypes[i] = elements[i].type;
          }
          List<int> subtypesOfAllOtherTypesIndexes = new List<int>();
          for (int i = 0; i < numOfEltsWithMatchingNames; i++) {
            FunctionType subtype = executableElementTypes[i];
            if (subtype == null) {
              continue;
            }
            bool subtypeOfAllTypes = true;
            for (int j = 0; j < numOfEltsWithMatchingNames && subtypeOfAllTypes; j++) {
              if (i != j) {
                if (!subtype.isSubtypeOf(executableElementTypes[j])) {
                  subtypeOfAllTypes = false;
                  break;
                }
              }
            }
            if (subtypeOfAllTypes) {
              subtypesOfAllOtherTypesIndexes.add(i);
            }
          }
          //
          // The following is split into three cases determined by the number of elements in subtypesOfAllOtherTypes
          //
          if (subtypesOfAllOtherTypesIndexes.length == 1) {
            //
            // Example: class A inherited only 2 method named 'm'. One has the function type
            // '() -> dynamic' and one has the function type '([int]) -> dynamic'. Since the second
            // method is a subtype of all the others, it is the inherited method.
            // Tests: InheritanceManagerTest.test_getMapOfMembersInheritedFromInterfaces_union_oneSubtype_*
            //
            resultMap.put(key, elements[subtypesOfAllOtherTypesIndexes[0]]);
          } else {
            if (subtypesOfAllOtherTypesIndexes.isEmpty) {
              //
              // Example: class A inherited only 2 method named 'm'. One has the function type
              // '() -> int' and one has the function type '() -> String'. Since neither is a subtype
              // of the other, we create a warning, and have this class inherit nothing.
              //
              String firstTwoFuntionTypesStr = "${executableElementTypes[0].toString()}, ${executableElementTypes[1].toString()}";
              reportError(classElt, classElt.nameOffset, classElt.displayName.length, StaticTypeWarningCode.INCONSISTENT_METHOD_INHERITANCE, [key, firstTwoFuntionTypesStr]);
            } else {
              //
              // Example: class A inherits 2 methods named 'm'. One has the function type
              // '(int) -> dynamic' and one has the function type '(num) -> dynamic'. Since they are
              // both a subtype of the other, a synthetic function '(dynamic) -> dynamic' is
              // inherited.
              // Tests: test_getMapOfMembersInheritedFromInterfaces_union_multipleSubtypes_*
              //
              List<ExecutableElement> elementArrayToMerge = new List<ExecutableElement>(subtypesOfAllOtherTypesIndexes.length);
              for (int i = 0; i < elementArrayToMerge.length; i++) {
                elementArrayToMerge[i] = elements[subtypesOfAllOtherTypesIndexes[i]];
              }
              ExecutableElement mergedExecutableElement = computeMergedExecutableElement(elementArrayToMerge);
              if (mergedExecutableElement != null) {
                resultMap.put(key, mergedExecutableElement);
              }
            }
          }
        } else {
          reportError(classElt, classElt.nameOffset, classElt.displayName.length, StaticWarningCode.INCONSISTENT_METHOD_INHERITANCE_GETTER_AND_METHOD, [key]);
        }
      }
    }
    _interfaceLookup[classElt] = resultMap;
    return resultMap;
  }

  /**
   * Given some [ClassElement], this method finds and returns the [ExecutableElement] of
   * the passed name in the class element. Static members, members in super types and members not
   * accessible from the current library are not considered.
   *
   * @param classElt the class element to query
   * @param memberName the name of the member to lookup in the class
   * @return the found [ExecutableElement], or `null` if no such member was found
   */
  ExecutableElement lookupMemberInClass(ClassElement classElt, String memberName) {
    List<MethodElement> methods = classElt.methods;
    for (MethodElement method in methods) {
      if (memberName == method.name && method.isAccessibleIn(_library) && !method.isStatic) {
        return method;
      }
    }
    List<PropertyAccessorElement> accessors = classElt.accessors;
    for (PropertyAccessorElement accessor in accessors) {
      if (memberName == accessor.name && accessor.isAccessibleIn(_library) && !accessor.isStatic) {
        return accessor;
      }
    }
    return null;
  }

  /**
   * Record the passed map with the set of all members (methods, getters and setters) in the type
   * into the passed map.
   *
   * @param map some non-`null` map to put the methods and accessors from the passed
   *          [ClassElement] into
   * @param type the type that will be recorded into the passed map
   * @param doIncludeAbstract `true` if abstract members will be put into the map
   */
  void recordMapWithClassMembers(MemberMap map, InterfaceType type, bool doIncludeAbstract) {
    List<MethodElement> methods = type.methods;
    for (MethodElement method in methods) {
      if (method.isAccessibleIn(_library) && !method.isStatic && (doIncludeAbstract || !method.isAbstract)) {
        map.put(method.name, method);
      }
    }
    List<PropertyAccessorElement> accessors = type.accessors;
    for (PropertyAccessorElement accessor in accessors) {
      if (accessor.isAccessibleIn(_library) && !accessor.isStatic && (doIncludeAbstract || !accessor.isAbstract)) {
        map.put(accessor.name, accessor);
      }
    }
  }

  /**
   * This method is used to report errors on when they are found computing inheritance information.
   * See [ErrorVerifier#checkForInconsistentMethodInheritance] to see where these generated
   * error codes are reported back into the analysis engine.
   *
   * @param classElt the location of the source for which the exception occurred
   * @param offset the offset of the location of the error
   * @param length the length of the location of the error
   * @param errorCode the error code to be associated with this error
   * @param arguments the arguments used to build the error message
   */
  void reportError(ClassElement classElt, int offset, int length, ErrorCode errorCode, List<Object> arguments) {
    Set<AnalysisError> errorSet = _errorsInClassElement[classElt];
    if (errorSet == null) {
      errorSet = new Set<AnalysisError>();
      _errorsInClassElement[classElt] = errorSet;
    }
    errorSet.add(new AnalysisError.con2(classElt.source, offset, length, errorCode, arguments));
  }

  /**
   * Loop through all of the members in some [MemberMap], performing type parameter
   * substitutions using a passed supertype.
   *
   * @param superType the supertype to substitute into the members of the [MemberMap]
   * @param map the MemberMap to perform the substitutions on
   */
  void substituteTypeParametersDownHierarchy(InterfaceType superType, MemberMap map) {
    for (int i = 0; i < map.size; i++) {
      ExecutableElement executableElement = map.getValue(i);
      if (executableElement is MethodMember) {
        executableElement = MethodMember.from(executableElement as MethodMember, superType);
        map.setValue(i, executableElement);
      } else if (executableElement is PropertyAccessorMember) {
        executableElement = PropertyAccessorMember.from(executableElement as PropertyAccessorMember, superType);
        map.setValue(i, executableElement);
      }
    }
  }
}

/**
 * Instances of the class `Library` represent the data about a single library during the
 * resolution of some (possibly different) library. They are not intended to be used except during
 * the resolution process.
 */
class Library {
  /**
   * The analysis context in which this library is being analyzed.
   */
  InternalAnalysisContext _analysisContext;

  /**
   * The inheritance manager which is used for this member lookups in this library.
   */
  InheritanceManager _inheritanceManager;

  /**
   * The listener to which analysis errors will be reported.
   */
  AnalysisErrorListener _errorListener;

  /**
   * The source specifying the defining compilation unit of this library.
   */
  final Source librarySource;

  /**
   * The library element representing this library.
   */
  LibraryElementImpl _libraryElement;

  /**
   * A list containing all of the libraries that are imported into this library.
   */
  List<Library> _importedLibraries = _EMPTY_ARRAY;

  /**
   * A table mapping URI-based directive to the actual URI value.
   */
  Map<UriBasedDirective, String> _directiveUris = new Map<UriBasedDirective, String>();

  /**
   * A flag indicating whether this library explicitly imports core.
   */
  bool explicitlyImportsCore = false;

  /**
   * A list containing all of the libraries that are exported from this library.
   */
  List<Library> _exportedLibraries = _EMPTY_ARRAY;

  /**
   * A table mapping the sources for the compilation units in this library to their corresponding
   * AST structures.
   */
  Map<Source, ResolvableCompilationUnit> _astMap = new Map<Source, ResolvableCompilationUnit>();

  /**
   * The library scope used when resolving elements within this library's compilation units.
   */
  LibraryScope _libraryScope;

  /**
   * An empty array that can be used to initialize lists of libraries.
   */
  static List<Library> _EMPTY_ARRAY = new List<Library>(0);

  /**
   * The prefix of a URI using the dart-ext scheme to reference a native code library.
   */
  static String _DART_EXT_SCHEME = "dart-ext:";

  /**
   * Initialize a newly created data holder that can maintain the data associated with a library.
   *
   * @param analysisContext the analysis context in which this library is being analyzed
   * @param errorListener the listener to which analysis errors will be reported
   * @param librarySource the source specifying the defining compilation unit of this library
   */
  Library(InternalAnalysisContext analysisContext, AnalysisErrorListener errorListener, this.librarySource) {
    this._analysisContext = analysisContext;
    this._errorListener = errorListener;
    this._libraryElement = analysisContext.getLibraryElement(librarySource) as LibraryElementImpl;
  }

  /**
   * Return the AST structure associated with the given source.
   *
   * @param source the source representing the compilation unit whose AST is to be returned
   * @return the AST structure associated with the given source
   * @throws AnalysisException if an AST structure could not be created for the compilation unit
   */
  CompilationUnit getAST(Source source) {
    ResolvableCompilationUnit holder = _astMap[source];
    if (holder == null) {
      holder = _analysisContext.computeResolvableCompilationUnit(source);
      _astMap[source] = holder;
    }
    return holder.compilationUnit;
  }

  /**
   * Return an array of the [CompilationUnit]s that make up the library. The first unit is
   * always the defining unit.
   *
   * @return an array of the [CompilationUnit]s that make up the library. The first unit is
   *         always the defining unit
   */
  List<CompilationUnit> get compilationUnits {
    List<CompilationUnit> unitArrayList = new List<CompilationUnit>();
    unitArrayList.add(definingCompilationUnit);
    for (Source source in _astMap.keys.toSet()) {
      if (librarySource != source) {
        unitArrayList.add(getAST(source));
      }
    }
    return new List.from(unitArrayList);
  }

  /**
   * Return a collection containing the sources for the compilation units in this library, including
   * the defining compilation unit.
   *
   * @return the sources for the compilation units in this library
   */
  Set<Source> get compilationUnitSources => _astMap.keys.toSet();

  /**
   * Return the AST structure associated with the defining compilation unit for this library.
   *
   * @return the AST structure associated with the defining compilation unit for this library
   * @throws AnalysisException if an AST structure could not be created for the defining compilation
   *           unit
   */
  CompilationUnit get definingCompilationUnit => getAST(librarySource);

  /**
   * Return an array containing the libraries that are exported from this library.
   *
   * @return an array containing the libraries that are exported from this library
   */
  List<Library> get exports => _exportedLibraries;

  /**
   * Return an array containing the libraries that are imported into this library.
   *
   * @return an array containing the libraries that are imported into this library
   */
  List<Library> get imports => _importedLibraries;

  /**
   * Return an array containing the libraries that are either imported or exported from this
   * library.
   *
   * @return the libraries that are either imported or exported from this library
   */
  List<Library> get importsAndExports {
    Set<Library> libraries = new Set<Library>();
    for (Library library in _importedLibraries) {
      libraries.add(library);
    }
    for (Library library in _exportedLibraries) {
      libraries.add(library);
    }
    return new List.from(libraries);
  }

  /**
   * Return the inheritance manager for this library.
   *
   * @return the inheritance manager for this library
   */
  InheritanceManager get inheritanceManager {
    if (_inheritanceManager == null) {
      return _inheritanceManager = new InheritanceManager(_libraryElement);
    }
    return _inheritanceManager;
  }

  /**
   * Return the library element representing this library, creating it if necessary.
   *
   * @return the library element representing this library
   */
  LibraryElementImpl get libraryElement {
    if (_libraryElement == null) {
      try {
        _libraryElement = _analysisContext.computeLibraryElement(librarySource) as LibraryElementImpl;
      } on AnalysisException catch (exception) {
        AnalysisEngine.instance.logger.logError2("Could not compute library element for ${librarySource.fullName}", exception);
      }
    }
    return _libraryElement;
  }

  /**
   * Return the library scope used when resolving elements within this library's compilation units.
   *
   * @return the library scope used when resolving elements within this library's compilation units
   */
  LibraryScope get libraryScope {
    if (_libraryScope == null) {
      _libraryScope = new LibraryScope(_libraryElement, _errorListener);
    }
    return _libraryScope;
  }

  /**
   * Return the modification time associated with the given source.
   *
   * @param source the source representing the compilation unit whose modification time is to be
   *          returned
   * @return the modification time associated with the given source
   * @throws AnalysisException if an AST structure could not be created for the compilation unit
   */
  int getModificationTime(Source source) {
    ResolvableCompilationUnit holder = _astMap[source];
    if (holder == null) {
      holder = _analysisContext.computeResolvableCompilationUnit(source);
      _astMap[source] = holder;
    }
    return holder.modificationTime;
  }

  /**
   * Return the result of resolving the URI of the given URI-based directive against the URI of the
   * library, or `null` if the URI is not valid. If the URI is not valid, report the error.
   *
   * @param directive the directive which URI should be resolved
   * @return the result of resolving the URI against the URI of the library
   */
  Source getSource(UriBasedDirective directive) {
    StringLiteral uriLiteral = directive.uri;
    if (uriLiteral is StringInterpolation) {
      _errorListener.onError(new AnalysisError.con2(librarySource, uriLiteral.offset, uriLiteral.length, CompileTimeErrorCode.URI_WITH_INTERPOLATION, []));
      return null;
    }
    String uriContent = uriLiteral.stringValue.trim();
    _directiveUris[directive] = uriContent;
    uriContent = Uri.encodeFull(uriContent);
    if (directive is ImportDirective && uriContent.startsWith(_DART_EXT_SCHEME)) {
      _libraryElement.hasExtUri2 = true;
      return null;
    }
    try {
      parseUriWithException(uriContent);
      Source source = _analysisContext.sourceFactory.resolveUri(librarySource, uriContent);
      if (!_analysisContext.exists(source)) {
        _errorListener.onError(new AnalysisError.con2(librarySource, uriLiteral.offset, uriLiteral.length, CompileTimeErrorCode.URI_DOES_NOT_EXIST, [uriContent]));
      }
      return source;
    } on URISyntaxException catch (exception) {
      _errorListener.onError(new AnalysisError.con2(librarySource, uriLiteral.offset, uriLiteral.length, CompileTimeErrorCode.INVALID_URI, [uriContent]));
    }
    return null;
  }

  /**
   * Returns the URI value of the given directive.
   */
  String getUri(UriBasedDirective directive) => _directiveUris[directive];

  /**
   * Set the AST structure associated with the defining compilation unit for this library to the
   * given AST structure.
   *
   * @param modificationStamp the modification time of the source from which the compilation unit
   *          was created
   * @param unit the AST structure associated with the defining compilation unit for this library
   */
  void setDefiningCompilationUnit(int modificationStamp, CompilationUnit unit) {
    _astMap[librarySource] = new ResolvableCompilationUnit(modificationStamp, unit);
  }

  /**
   * Set the libraries that are exported by this library to be those in the given array.
   *
   * @param exportedLibraries the libraries that are exported by this library
   */
  void set exportedLibraries(List<Library> exportedLibraries) {
    this._exportedLibraries = exportedLibraries;
  }

  /**
   * Set the libraries that are imported into this library to be those in the given array.
   *
   * @param importedLibraries the libraries that are imported into this library
   */
  void set importedLibraries(List<Library> importedLibraries) {
    this._importedLibraries = importedLibraries;
  }

  /**
   * Set the library element representing this library to the given library element.
   *
   * @param libraryElement the library element representing this library
   */
  void set libraryElement(LibraryElementImpl libraryElement) {
    this._libraryElement = libraryElement;
    if (_inheritanceManager != null) {
      _inheritanceManager.libraryElement = libraryElement;
    }
  }

  String toString() => librarySource.shortName;
}

/**
 * Instances of the class `LibraryElementBuilder` build an element model for a single library.
 */
class LibraryElementBuilder {
  /**
   * The analysis context in which the element model will be built.
   */
  InternalAnalysisContext _analysisContext;

  /**
   * The listener to which errors will be reported.
   */
  AnalysisErrorListener _errorListener;

  /**
   * The name of the function used as an entry point.
   */
  static String ENTRY_POINT_NAME = "main";

  /**
   * Initialize a newly created library element builder.
   *
   * @param resolver the resolver for which the element model is being built
   */
  LibraryElementBuilder(LibraryResolver resolver) {
    this._analysisContext = resolver.analysisContext;
    this._errorListener = resolver.errorListener;
  }

  /**
   * Build the library element for the given library.
   *
   * @param library the library for which an element model is to be built
   * @return the library element that was built
   * @throws AnalysisException if the analysis could not be performed
   */
  LibraryElementImpl buildLibrary(Library library) {
    CompilationUnitBuilder builder = new CompilationUnitBuilder();
    Source librarySource = library.librarySource;
    CompilationUnit definingCompilationUnit = library.definingCompilationUnit;
    CompilationUnitElementImpl definingCompilationUnitElement = builder.buildCompilationUnit(librarySource, definingCompilationUnit);
    NodeList<Directive> directives = definingCompilationUnit.directives;
    LibraryIdentifier libraryNameNode = null;
    bool hasPartDirective = false;
    FunctionElement entryPoint = findEntryPoint(definingCompilationUnitElement);
    List<Directive> directivesToResolve = new List<Directive>();
    List<CompilationUnitElementImpl> sourcedCompilationUnits = new List<CompilationUnitElementImpl>();
    for (Directive directive in directives) {
      //
      // We do not build the elements representing the import and export directives at this point.
      // That is not done until we get to LibraryResolver.buildDirectiveModels() because we need the
      // LibraryElements for the referenced libraries, which might not exist at this point (due to
      // the possibility of circular references).
      //
      if (directive is LibraryDirective) {
        if (libraryNameNode == null) {
          libraryNameNode = directive.name;
          directivesToResolve.add(directive);
        }
      } else if (directive is PartDirective) {
        PartDirective partDirective = directive;
        StringLiteral partUri = partDirective.uri;
        Source partSource = library.getSource(partDirective);
        if (_analysisContext.exists(partSource)) {
          hasPartDirective = true;
          CompilationUnitElementImpl part = builder.buildCompilationUnit(partSource, library.getAST(partSource));
          part.uri = library.getUri(partDirective);
          //
          // Validate that the part contains a part-of directive with the same name as the library.
          //
          String partLibraryName = getPartLibraryName(library, partSource, directivesToResolve);
          if (partLibraryName == null) {
            _errorListener.onError(new AnalysisError.con2(librarySource, partUri.offset, partUri.length, CompileTimeErrorCode.PART_OF_NON_PART, [partUri.toSource()]));
          } else if (libraryNameNode == null) {
          } else if (libraryNameNode.name != partLibraryName) {
            _errorListener.onError(new AnalysisError.con2(librarySource, partUri.offset, partUri.length, StaticWarningCode.PART_OF_DIFFERENT_LIBRARY, [libraryNameNode.name, partLibraryName]));
          }
          if (entryPoint == null) {
            entryPoint = findEntryPoint(part);
          }
          directive.element = part;
          sourcedCompilationUnits.add(part);
        }
      }
    }
    if (hasPartDirective && libraryNameNode == null) {
      _errorListener.onError(new AnalysisError.con1(librarySource, ResolverErrorCode.MISSING_LIBRARY_DIRECTIVE_WITH_PART, []));
    }
    //
    // Create and populate the library element.
    //
    LibraryElementImpl libraryElement = new LibraryElementImpl(_analysisContext, libraryNameNode);
    libraryElement.definingCompilationUnit = definingCompilationUnitElement;
    if (entryPoint != null) {
      libraryElement.entryPoint = entryPoint;
    }
    int sourcedUnitCount = sourcedCompilationUnits.length;
    libraryElement.parts = new List.from(sourcedCompilationUnits);
    for (Directive directive in directivesToResolve) {
      directive.element = libraryElement;
    }
    library.libraryElement = libraryElement;
    if (sourcedUnitCount > 0) {
      patchTopLevelAccessors(libraryElement);
    }
    return libraryElement;
  }

  /**
   * Add all of the non-synthetic getters and setters defined in the given compilation unit that
   * have no corresponding accessor to one of the given collections.
   *
   * @param getters the map to which getters are to be added
   * @param setters the list to which setters are to be added
   * @param unit the compilation unit defining the accessors that are potentially being added
   */
  void collectAccessors(Map<String, PropertyAccessorElement> getters, List<PropertyAccessorElement> setters, CompilationUnitElement unit) {
    for (PropertyAccessorElement accessor in unit.accessors) {
      if (accessor.isGetter) {
        if (!accessor.isSynthetic && accessor.correspondingSetter == null) {
          getters[accessor.displayName] = accessor;
        }
      } else {
        if (!accessor.isSynthetic && accessor.correspondingGetter == null) {
          setters.add(accessor);
        }
      }
    }
  }

  /**
   * Search the top-level functions defined in the given compilation unit for the entry point.
   *
   * @param element the compilation unit to be searched
   * @return the entry point that was found, or `null` if the compilation unit does not define
   *         an entry point
   */
  FunctionElement findEntryPoint(CompilationUnitElementImpl element) {
    for (FunctionElement function in element.functions) {
      if (function.name == ENTRY_POINT_NAME) {
        return function;
      }
    }
    return null;
  }

  /**
   * Return the name of the library that the given part is declared to be a part of, or `null`
   * if the part does not contain a part-of directive.
   *
   * @param library the library containing the part
   * @param partSource the source representing the part
   * @param directivesToResolve a list of directives that should be resolved to the library being
   *          built
   * @return the name of the library that the given part is declared to be a part of
   */
  String getPartLibraryName(Library library, Source partSource, List<Directive> directivesToResolve) {
    try {
      CompilationUnit partUnit = library.getAST(partSource);
      for (Directive directive in partUnit.directives) {
        if (directive is PartOfDirective) {
          directivesToResolve.add(directive);
          LibraryIdentifier libraryName = directive.libraryName;
          if (libraryName != null) {
            return libraryName.name;
          }
        }
      }
    } on AnalysisException catch (exception) {
    }
    return null;
  }

  /**
   * Look through all of the compilation units defined for the given library, looking for getters
   * and setters that are defined in different compilation units but that have the same names. If
   * any are found, make sure that they have the same variable element.
   *
   * @param libraryElement the library defining the compilation units to be processed
   */
  void patchTopLevelAccessors(LibraryElementImpl libraryElement) {
    Map<String, PropertyAccessorElement> getters = new Map<String, PropertyAccessorElement>();
    List<PropertyAccessorElement> setters = new List<PropertyAccessorElement>();
    collectAccessors(getters, setters, libraryElement.definingCompilationUnit);
    for (CompilationUnitElement unit in libraryElement.parts) {
      collectAccessors(getters, setters, unit);
    }
    for (PropertyAccessorElement setter in setters) {
      PropertyAccessorElement getter = getters[setter.displayName];
      if (getter != null) {
        PropertyInducingElementImpl variable = getter.variable as PropertyInducingElementImpl;
        variable.setter = setter;
        (setter as PropertyAccessorElementImpl).variable = variable;
      }
    }
  }
}

/**
 * Instances of the class `LibraryResolver` are used to resolve one or more mutually dependent
 * libraries within a single context.
 */
class LibraryResolver {
  /**
   * The analysis context in which the libraries are being analyzed.
   */
  final InternalAnalysisContext analysisContext;

  /**
   * The listener to which analysis errors will be reported, this error listener is either
   * references [recordingErrorListener], or it unions the passed
   * [AnalysisErrorListener] with the [recordingErrorListener].
   */
  RecordingErrorListener _errorListener;

  /**
   * A source object representing the core library (dart:core).
   */
  Source _coreLibrarySource;

  /**
   * The object representing the core library.
   */
  Library _coreLibrary;

  /**
   * The object used to access the types from the core library.
   */
  TypeProvider _typeProvider;

  /**
   * A table mapping library sources to the information being maintained for those libraries.
   */
  Map<Source, Library> _libraryMap = new Map<Source, Library>();

  /**
   * A collection containing the libraries that are being resolved together.
   */
  Set<Library> _librariesInCycles;

  /**
   * Initialize a newly created library resolver to resolve libraries within the given context.
   *
   * @param analysisContext the analysis context in which the library is being analyzed
   */
  LibraryResolver(this.analysisContext) {
    this._errorListener = new RecordingErrorListener();
    _coreLibrarySource = analysisContext.sourceFactory.forUri(DartSdk.DART_CORE);
  }

  /**
   * Return the listener to which analysis errors will be reported.
   *
   * @return the listener to which analysis errors will be reported
   */
  RecordingErrorListener get errorListener => _errorListener;

  /**
   * Return an array containing information about all of the libraries that were resolved.
   *
   * @return an array containing the libraries that were resolved
   */
  Set<Library> get resolvedLibraries => _librariesInCycles;

  /**
   * Resolve the library specified by the given source in the given context. The library is assumed
   * to be embedded in the given source.
   *
   * @param librarySource the source specifying the defining compilation unit of the library to be
   *          resolved
   * @param modificationStamp the time stamp of the source from which the compilation unit was
   *          created
   * @param unit the compilation unit representing the embedded library
   * @param fullAnalysis `true` if a full analysis should be performed
   * @return the element representing the resolved library
   * @throws AnalysisException if the library could not be resolved for some reason
   */
  LibraryElement resolveEmbeddedLibrary(Source librarySource, int modificationStamp, CompilationUnit unit, bool fullAnalysis) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("dart.engine.LibraryResolver.resolveEmbeddedLibrary");
    try {
      instrumentation.metric("fullAnalysis", fullAnalysis);
      instrumentation.data3("fullName", librarySource.fullName);
      //
      // Create the objects representing the library being resolved and the core library.
      //
      Library targetLibrary = createLibraryWithUnit(librarySource, modificationStamp, unit);
      _coreLibrary = _libraryMap[_coreLibrarySource];
      if (_coreLibrary == null) {
        // This will be true unless the library being analyzed is the core library.
        _coreLibrary = createLibrary(_coreLibrarySource);
      }
      instrumentation.metric3("createLibrary", "complete");
      //
      // Compute the set of libraries that need to be resolved together.
      //
      computeEmbeddedLibraryDependencies(targetLibrary, unit);
      _librariesInCycles = computeLibrariesInCycles(targetLibrary);
      //
      // Build the element models representing the libraries being resolved. This is done in three
      // steps:
      //
      // 1. Build the basic element models without making any connections between elements other than
      //    the basic parent/child relationships. This includes building the elements representing the
      //    libraries.
      // 2. Build the elements for the import and export directives. This requires that we have the
      //    elements built for the referenced libraries, but because of the possibility of circular
      //    references needs to happen after all of the library elements have been created.
      // 3. Build the rest of the type model by connecting superclasses, mixins, and interfaces. This
      //    requires that we be able to compute the names visible in the libraries being resolved,
      //    which in turn requires that we have resolved the import directives.
      //
      buildElementModels();
      instrumentation.metric3("buildElementModels", "complete");
      LibraryElement coreElement = _coreLibrary.libraryElement;
      if (coreElement == null) {
        throw new AnalysisException.con1("Could not resolve dart:core");
      }
      buildDirectiveModels();
      instrumentation.metric3("buildDirectiveModels", "complete");
      _typeProvider = new TypeProviderImpl(coreElement);
      buildTypeHierarchies();
      instrumentation.metric3("buildTypeHierarchies", "complete");
      //
      // Perform resolution and type analysis.
      //
      // TODO(brianwilkerson) Decide whether we want to resolve all of the libraries or whether we
      // want to only resolve the target library. The advantage to resolving everything is that we
      // have already done part of the work so we'll avoid duplicated effort. The disadvantage of
      // resolving everything is that we might do extra work that we don't really care about. Another
      // possibility is to add a parameter to this method and punt the decision to the clients.
      //
      //if (analyzeAll) {
      resolveReferencesAndTypes();
      instrumentation.metric3("resolveReferencesAndTypes", "complete");
      //} else {
      //  resolveReferencesAndTypes(targetLibrary);
      //}
      performConstantEvaluation();
      instrumentation.metric3("performConstantEvaluation", "complete");
      return targetLibrary.libraryElement;
    } finally {
      instrumentation.log();
    }
  }

  /**
   * Resolve the library specified by the given source in the given context.
   *
   * Note that because Dart allows circular imports between libraries, it is possible that more than
   * one library will need to be resolved. In such cases the error listener can receive errors from
   * multiple libraries.
   *
   * @param librarySource the source specifying the defining compilation unit of the library to be
   *          resolved
   * @param fullAnalysis `true` if a full analysis should be performed
   * @return the element representing the resolved library
   * @throws AnalysisException if the library could not be resolved for some reason
   */
  LibraryElement resolveLibrary(Source librarySource, bool fullAnalysis) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("dart.engine.LibraryResolver.resolveLibrary");
    try {
      instrumentation.metric("fullAnalysis", fullAnalysis);
      instrumentation.data3("fullName", librarySource.fullName);
      //
      // Create the objects representing the library being resolved and the core library.
      //
      Library targetLibrary = createLibrary(librarySource);
      _coreLibrary = _libraryMap[_coreLibrarySource];
      if (_coreLibrary == null) {
        // This will be true unless the library being analyzed is the core library.
        _coreLibrary = createLibraryOrNull(_coreLibrarySource);
        if (_coreLibrary == null) {
          throw new AnalysisException.con1("Core library does not exist");
        }
      }
      instrumentation.metric3("createLibrary", "complete");
      //
      // Compute the set of libraries that need to be resolved together.
      //
      computeLibraryDependencies(targetLibrary);
      _librariesInCycles = computeLibrariesInCycles(targetLibrary);
      //
      // Build the element models representing the libraries being resolved. This is done in three
      // steps:
      //
      // 1. Build the basic element models without making any connections between elements other than
      //    the basic parent/child relationships. This includes building the elements representing the
      //    libraries.
      // 2. Build the elements for the import and export directives. This requires that we have the
      //    elements built for the referenced libraries, but because of the possibility of circular
      //    references needs to happen after all of the library elements have been created.
      // 3. Build the rest of the type model by connecting superclasses, mixins, and interfaces. This
      //    requires that we be able to compute the names visible in the libraries being resolved,
      //    which in turn requires that we have resolved the import directives.
      //
      buildElementModels();
      instrumentation.metric3("buildElementModels", "complete");
      LibraryElement coreElement = _coreLibrary.libraryElement;
      if (coreElement == null) {
        throw new AnalysisException.con1("Could not resolve dart:core");
      }
      buildDirectiveModels();
      instrumentation.metric3("buildDirectiveModels", "complete");
      _typeProvider = new TypeProviderImpl(coreElement);
      buildTypeHierarchies();
      instrumentation.metric3("buildTypeHierarchies", "complete");
      //
      // Perform resolution and type analysis.
      //
      // TODO(brianwilkerson) Decide whether we want to resolve all of the libraries or whether we
      // want to only resolve the target library. The advantage to resolving everything is that we
      // have already done part of the work so we'll avoid duplicated effort. The disadvantage of
      // resolving everything is that we might do extra work that we don't really care about. Another
      // possibility is to add a parameter to this method and punt the decision to the clients.
      //
      //if (analyzeAll) {
      resolveReferencesAndTypes();
      instrumentation.metric3("resolveReferencesAndTypes", "complete");
      //} else {
      //  resolveReferencesAndTypes(targetLibrary);
      //}
      performConstantEvaluation();
      instrumentation.metric3("performConstantEvaluation", "complete");
      instrumentation.metric2("librariesInCycles", _librariesInCycles.length);
      for (Library lib in _librariesInCycles) {
        instrumentation.metric2("librariesInCycles-CompilationUnitSources-Size", lib.compilationUnitSources.length);
      }
      return targetLibrary.libraryElement;
    } finally {
      instrumentation.log();
    }
  }

  /**
   * Add a dependency to the given map from the referencing library to the referenced library.
   *
   * @param dependencyMap the map to which the dependency is to be added
   * @param referencingLibrary the library that references the referenced library
   * @param referencedLibrary the library referenced by the referencing library
   */
  void addDependencyToMap(Map<Library, List<Library>> dependencyMap, Library referencingLibrary, Library referencedLibrary) {
    List<Library> dependentLibraries = dependencyMap[referencedLibrary];
    if (dependentLibraries == null) {
      dependentLibraries = new List<Library>();
      dependencyMap[referencedLibrary] = dependentLibraries;
    }
    dependentLibraries.add(referencingLibrary);
  }

  /**
   * Given a library that is part of a cycle that includes the root library, add to the given set of
   * libraries all of the libraries reachable from the root library that are also included in the
   * cycle.
   *
   * @param library the library to be added to the collection of libraries in cycles
   * @param librariesInCycle a collection of the libraries that are in the cycle
   * @param dependencyMap a table mapping libraries to the collection of libraries from which those
   *          libraries are referenced
   */
  void addLibrariesInCycle(Library library, Set<Library> librariesInCycle, Map<Library, List<Library>> dependencyMap) {
    if (librariesInCycle.add(library)) {
      List<Library> dependentLibraries = dependencyMap[library];
      if (dependentLibraries != null) {
        for (Library dependentLibrary in dependentLibraries) {
          addLibrariesInCycle(dependentLibrary, librariesInCycle, dependencyMap);
        }
      }
    }
  }

  /**
   * Add the given library, and all libraries reachable from it that have not already been visited,
   * to the given dependency map.
   *
   * @param library the library currently being added to the dependency map
   * @param dependencyMap the dependency map being computed
   * @param visitedLibraries the libraries that have already been visited, used to prevent infinite
   *          recursion
   */
  void addToDependencyMap(Library library, Map<Library, List<Library>> dependencyMap, Set<Library> visitedLibraries) {
    if (visitedLibraries.add(library)) {
      for (Library referencedLibrary in library.importsAndExports) {
        addDependencyToMap(dependencyMap, library, referencedLibrary);
        addToDependencyMap(referencedLibrary, dependencyMap, visitedLibraries);
      }
      if (!library.explicitlyImportsCore && library != _coreLibrary) {
        addDependencyToMap(dependencyMap, library, _coreLibrary);
      }
    }
  }

  /**
   * Build the element model representing the combinators declared by the given directive.
   *
   * @param directive the directive that declares the combinators
   * @return an array containing the import combinators that were built
   */
  List<NamespaceCombinator> buildCombinators(NamespaceDirective directive) {
    List<NamespaceCombinator> combinators = new List<NamespaceCombinator>();
    for (Combinator combinator in directive.combinators) {
      if (combinator is HideCombinator) {
        HideElementCombinatorImpl hide = new HideElementCombinatorImpl();
        hide.hiddenNames = getIdentifiers(combinator.hiddenNames);
        combinators.add(hide);
      } else {
        ShowElementCombinatorImpl show = new ShowElementCombinatorImpl();
        show.offset = combinator.offset;
        show.end = combinator.end;
        show.shownNames = getIdentifiers((combinator as ShowCombinator).shownNames);
        combinators.add(show);
      }
    }
    return new List.from(combinators);
  }

  /**
   * Every library now has a corresponding [LibraryElement], so it is now possible to resolve
   * the import and export directives.
   *
   * @throws AnalysisException if the defining compilation unit for any of the libraries could not
   *           be accessed
   */
  void buildDirectiveModels() {
    for (Library library in _librariesInCycles) {
      Map<String, PrefixElementImpl> nameToPrefixMap = new Map<String, PrefixElementImpl>();
      List<ImportElement> imports = new List<ImportElement>();
      List<ExportElement> exports = new List<ExportElement>();
      for (Directive directive in library.definingCompilationUnit.directives) {
        if (directive is ImportDirective) {
          ImportDirective importDirective = directive;
          Source importedSource = library.getSource(importDirective);
          if (importedSource != null) {
            // The imported source will be null if the URI in the import directive was invalid.
            Library importedLibrary = _libraryMap[importedSource];
            if (importedLibrary != null) {
              ImportElementImpl importElement = new ImportElementImpl(directive.offset);
              StringLiteral uriLiteral = importDirective.uri;
              if (uriLiteral != null) {
                importElement.uriEnd = uriLiteral.end;
              }
              importElement.uri = library.getUri(importDirective);
              importElement.combinators = buildCombinators(importDirective);
              LibraryElement importedLibraryElement = importedLibrary.libraryElement;
              if (importedLibraryElement != null) {
                importElement.importedLibrary = importedLibraryElement;
              }
              SimpleIdentifier prefixNode = directive.prefix;
              if (prefixNode != null) {
                importElement.prefixOffset = prefixNode.offset;
                String prefixName = prefixNode.name;
                PrefixElementImpl prefix = nameToPrefixMap[prefixName];
                if (prefix == null) {
                  prefix = new PrefixElementImpl(prefixNode);
                  nameToPrefixMap[prefixName] = prefix;
                }
                importElement.prefix = prefix;
                prefixNode.staticElement = prefix;
              }
              directive.element = importElement;
              imports.add(importElement);
              if (analysisContext.computeKindOf(importedSource) != SourceKind.LIBRARY) {
                _errorListener.onError(new AnalysisError.con2(library.librarySource, uriLiteral.offset, uriLiteral.length, CompileTimeErrorCode.IMPORT_OF_NON_LIBRARY, [uriLiteral.toSource()]));
              }
            }
          }
        } else if (directive is ExportDirective) {
          ExportDirective exportDirective = directive;
          Source exportedSource = library.getSource(exportDirective);
          if (exportedSource != null) {
            // The exported source will be null if the URI in the export directive was invalid.
            Library exportedLibrary = _libraryMap[exportedSource];
            if (exportedLibrary != null) {
              ExportElementImpl exportElement = new ExportElementImpl();
              exportElement.uri = library.getUri(exportDirective);
              exportElement.combinators = buildCombinators(exportDirective);
              LibraryElement exportedLibraryElement = exportedLibrary.libraryElement;
              if (exportedLibraryElement != null) {
                exportElement.exportedLibrary = exportedLibraryElement;
              }
              directive.element = exportElement;
              exports.add(exportElement);
              if (analysisContext.computeKindOf(exportedSource) != SourceKind.LIBRARY) {
                StringLiteral uriLiteral = exportDirective.uri;
                _errorListener.onError(new AnalysisError.con2(library.librarySource, uriLiteral.offset, uriLiteral.length, CompileTimeErrorCode.EXPORT_OF_NON_LIBRARY, [uriLiteral.toSource()]));
              }
            }
          }
        }
      }
      Source librarySource = library.librarySource;
      if (!library.explicitlyImportsCore && _coreLibrarySource != librarySource) {
        ImportElementImpl importElement = new ImportElementImpl(-1);
        importElement.importedLibrary = _coreLibrary.libraryElement;
        importElement.synthetic = true;
        imports.add(importElement);
      }
      LibraryElementImpl libraryElement = library.libraryElement;
      libraryElement.imports = new List.from(imports);
      libraryElement.exports = new List.from(exports);
      if (libraryElement.entryPoint == null) {
        Namespace namespace = new NamespaceBuilder().createExportNamespace2(libraryElement);
        Element element = namespace.get(LibraryElementBuilder.ENTRY_POINT_NAME);
        if (element is FunctionElement) {
          libraryElement.entryPoint = element;
        }
      }
    }
  }

  /**
   * Build element models for all of the libraries in the current cycle.
   *
   * @throws AnalysisException if any of the element models cannot be built
   */
  void buildElementModels() {
    for (Library library in _librariesInCycles) {
      LibraryElementBuilder builder = new LibraryElementBuilder(this);
      LibraryElementImpl libraryElement = builder.buildLibrary(library);
      library.libraryElement = libraryElement;
    }
  }

  /**
   * Resolve the type hierarchy across all of the types declared in the libraries in the current
   * cycle.
   *
   * @throws AnalysisException if any of the type hierarchies could not be resolved
   */
  void buildTypeHierarchies() {
    TimeCounter_TimeCounterHandle timeCounter = PerformanceStatistics.resolve.start();
    try {
      for (Library library in _librariesInCycles) {
        for (Source source in library.compilationUnitSources) {
          TypeResolverVisitor visitor = new TypeResolverVisitor.con1(library, source, _typeProvider);
          library.getAST(source).accept(visitor);
        }
      }
    } finally {
      timeCounter.stop();
    }
  }

  /**
   * Compute a dependency map of libraries reachable from the given library. A dependency map is a
   * table that maps individual libraries to a list of the libraries that either import or export
   * those libraries.
   *
   * This map is used to compute all of the libraries involved in a cycle that include the root
   * library. Given that we only add libraries that are reachable from the root library, when we
   * work backward we are guaranteed to only get libraries in the cycle.
   *
   * @param library the library currently being added to the dependency map
   */
  Map<Library, List<Library>> computeDependencyMap(Library library) {
    Map<Library, List<Library>> dependencyMap = new Map<Library, List<Library>>();
    addToDependencyMap(library, dependencyMap, new Set<Library>());
    return dependencyMap;
  }

  /**
   * Recursively traverse the libraries reachable from the given library, creating instances of the
   * class [Library] to represent them, and record the references in the library objects.
   *
   * @param library the library to be processed to find libraries that have not yet been traversed
   * @throws AnalysisException if some portion of the library graph could not be traversed
   */
  void computeEmbeddedLibraryDependencies(Library library, CompilationUnit unit) {
    Source librarySource = library.librarySource;
    Set<Source> exportedSources = new Set<Source>();
    Set<Source> importedSources = new Set<Source>();
    for (Directive directive in unit.directives) {
      if (directive is ExportDirective) {
        Source exportSource = resolveSource(librarySource, directive);
        if (exportSource != null) {
          exportedSources.add(exportSource);
        }
      } else if (directive is ImportDirective) {
        Source importSource = resolveSource(librarySource, directive);
        if (importSource != null) {
          importedSources.add(importSource);
        }
      }
    }
    computeLibraryDependenciesFromDirectives(library, new List.from(importedSources), new List.from(exportedSources));
  }

  /**
   * Return a collection containing all of the libraries reachable from the given library that are
   * contained in a cycle that includes the given library.
   *
   * @param library the library that must be included in any cycles whose members are to be returned
   * @return all of the libraries referenced by the given library that have a circular reference
   *         back to the given library
   */
  Set<Library> computeLibrariesInCycles(Library library) {
    Map<Library, List<Library>> dependencyMap = computeDependencyMap(library);
    Set<Library> librariesInCycle = new Set<Library>();
    addLibrariesInCycle(library, librariesInCycle, dependencyMap);
    return librariesInCycle;
  }

  /**
   * Recursively traverse the libraries reachable from the given library, creating instances of the
   * class [Library] to represent them, and record the references in the library objects.
   *
   * @param library the library to be processed to find libraries that have not yet been traversed
   * @throws AnalysisException if some portion of the library graph could not be traversed
   */
  void computeLibraryDependencies(Library library) {
    Source librarySource = library.librarySource;
    computeLibraryDependenciesFromDirectives(library, analysisContext.computeImportedLibraries(librarySource), analysisContext.computeExportedLibraries(librarySource));
  }

  /**
   * Recursively traverse the libraries reachable from the given library, creating instances of the
   * class [Library] to represent them, and record the references in the library objects.
   *
   * @param library the library to be processed to find libraries that have not yet been traversed
   * @param importedSources an array containing the sources that are imported into the given library
   * @param exportedSources an array containing the sources that are exported from the given library
   * @throws AnalysisException if some portion of the library graph could not be traversed
   */
  void computeLibraryDependenciesFromDirectives(Library library, List<Source> importedSources, List<Source> exportedSources) {
    List<Library> importedLibraries = new List<Library>();
    bool explicitlyImportsCore = false;
    for (Source importedSource in importedSources) {
      if (importedSource == _coreLibrarySource) {
        explicitlyImportsCore = true;
      }
      Library importedLibrary = _libraryMap[importedSource];
      if (importedLibrary == null) {
        importedLibrary = createLibraryOrNull(importedSource);
        if (importedLibrary != null) {
          computeLibraryDependencies(importedLibrary);
        }
      }
      if (importedLibrary != null) {
        importedLibraries.add(importedLibrary);
      }
    }
    library.importedLibraries = new List.from(importedLibraries);
    List<Library> exportedLibraries = new List<Library>();
    for (Source exportedSource in exportedSources) {
      Library exportedLibrary = _libraryMap[exportedSource];
      if (exportedLibrary == null) {
        exportedLibrary = createLibraryOrNull(exportedSource);
        if (exportedLibrary != null) {
          computeLibraryDependencies(exportedLibrary);
        }
      }
      if (exportedLibrary != null) {
        exportedLibraries.add(exportedLibrary);
      }
    }
    library.exportedLibraries = new List.from(exportedLibraries);
    library.explicitlyImportsCore = explicitlyImportsCore;
    if (!explicitlyImportsCore && _coreLibrarySource != library.librarySource) {
      Library importedLibrary = _libraryMap[_coreLibrarySource];
      if (importedLibrary == null) {
        importedLibrary = createLibraryOrNull(_coreLibrarySource);
        if (importedLibrary != null) {
          computeLibraryDependencies(importedLibrary);
        }
      }
    }
  }

  /**
   * Create an object to represent the information about the library defined by the compilation unit
   * with the given source.
   *
   * @param librarySource the source of the library's defining compilation unit
   * @return the library object that was created
   * @throws AnalysisException if the library source is not valid
   */
  Library createLibrary(Source librarySource) {
    Library library = new Library(analysisContext, _errorListener, librarySource);
    _libraryMap[librarySource] = library;
    return library;
  }

  /**
   * Create an object to represent the information about the library defined by the compilation unit
   * with the given source. Return the library object that was created, or `null` if the
   * source is not valid.
   *
   * @param librarySource the source of the library's defining compilation unit
   * @return the library object that was created
   */
  Library createLibraryOrNull(Source librarySource) {
    if (!analysisContext.exists(librarySource)) {
      return null;
    }
    Library library = new Library(analysisContext, _errorListener, librarySource);
    _libraryMap[librarySource] = library;
    return library;
  }

  /**
   * Create an object to represent the information about the library defined by the compilation unit
   * with the given source.
   *
   * @param librarySource the source of the library's defining compilation unit
   * @param modificationStamp the modification time of the source from which the compilation unit
   *          was created
   * @param unit the compilation unit that defines the library
   * @return the library object that was created
   * @throws AnalysisException if the library source is not valid
   */
  Library createLibraryWithUnit(Source librarySource, int modificationStamp, CompilationUnit unit) {
    Library library = new Library(analysisContext, _errorListener, librarySource);
    library.setDefiningCompilationUnit(modificationStamp, unit);
    _libraryMap[librarySource] = library;
    return library;
  }

  /**
   * Return an array containing the lexical identifiers associated with the nodes in the given list.
   *
   * @param names the AST nodes representing the identifiers
   * @return the lexical identifiers associated with the nodes in the list
   */
  List<String> getIdentifiers(NodeList<SimpleIdentifier> names) {
    int count = names.length;
    List<String> identifiers = new List<String>(count);
    for (int i = 0; i < count; i++) {
      identifiers[i] = names[i].name;
    }
    return identifiers;
  }

  /**
   * Compute a value for all of the constants in the libraries being analyzed.
   */
  void performConstantEvaluation() {
    TimeCounter_TimeCounterHandle timeCounter = PerformanceStatistics.resolve.start();
    try {
      ConstantValueComputer computer = new ConstantValueComputer(_typeProvider);
      for (Library library in _librariesInCycles) {
        for (Source source in library.compilationUnitSources) {
          try {
            CompilationUnit unit = library.getAST(source);
            if (unit != null) {
              computer.add(unit);
            }
          } on AnalysisException catch (exception) {
            AnalysisEngine.instance.logger.logError2("Internal Error: Could not access AST for ${source.fullName} during constant evaluation", exception);
          }
        }
      }
      computer.computeValues();
    } finally {
      timeCounter.stop();
    }
  }

  /**
   * Resolve the identifiers and perform type analysis in the libraries in the current cycle.
   *
   * @throws AnalysisException if any of the identifiers could not be resolved or if any of the
   *           libraries could not have their types analyzed
   */
  void resolveReferencesAndTypes() {
    for (Library library in _librariesInCycles) {
      resolveReferencesAndTypesInLibrary(library);
    }
  }

  /**
   * Resolve the identifiers and perform type analysis in the given library.
   *
   * @param library the library to be resolved
   * @throws AnalysisException if any of the identifiers could not be resolved or if the types in
   *           the library cannot be analyzed
   */
  void resolveReferencesAndTypesInLibrary(Library library) {
    TimeCounter_TimeCounterHandle timeCounter = PerformanceStatistics.resolve.start();
    try {
      for (Source source in library.compilationUnitSources) {
        CompilationUnit ast = library.getAST(source);
        ast.accept(new VariableResolverVisitor.con1(library, source, _typeProvider));
        ResolverVisitor visitor = new ResolverVisitor.con1(library, source, _typeProvider);
        ast.accept(visitor);
        for (ProxyConditionalAnalysisError conditionalCode in visitor.proxyConditionalAnalysisErrors) {
          if (conditionalCode.shouldIncludeErrorCode()) {
            visitor.reportError(conditionalCode.analysisError);
          }
        }
      }
    } finally {
      timeCounter.stop();
    }
    // Angular
    timeCounter = PerformanceStatistics.angular.start();
    try {
      for (Source source in library.compilationUnitSources) {
        CompilationUnit ast = library.getAST(source);
        new AngularCompilationUnitBuilder(_errorListener, source, ast).build();
      }
    } finally {
      timeCounter.stop();
    }
  }

  /**
   * Return the result of resolving the URI of the given URI-based directive against the URI of the
   * given library, or `null` if the URI is not valid.
   *
   * @param librarySource the source representing the library containing the directive
   * @param directive the directive which URI should be resolved
   * @return the result of resolving the URI against the URI of the library
   */
  Source resolveSource(Source librarySource, UriBasedDirective directive) {
    StringLiteral uriLiteral = directive.uri;
    if (uriLiteral is StringInterpolation) {
      return null;
    }
    String uriContent = uriLiteral.stringValue.trim();
    if (uriContent == null || uriContent.isEmpty) {
      return null;
    }
    uriContent = Uri.encodeFull(uriContent);
    return analysisContext.sourceFactory.resolveUri(librarySource, uriContent);
  }
}

/**
 * This class is used to replace uses of `HashMap<String, ExecutableElement>` which are not as
 * performant as this class.
 */
class MemberMap {
  /**
   * The current size of this map.
   */
  int _size = 0;

  /**
   * The array of keys.
   */
  List<String> _keys;

  /**
   * The array of ExecutableElement values.
   */
  List<ExecutableElement> _values;

  /**
   * Default constructor.
   */
  MemberMap() : this.con1(10);

  /**
   * This constructor takes an initial capacity of the map.
   *
   * @param initialCapacity the initial capacity
   */
  MemberMap.con1(int initialCapacity) {
    initArrays(initialCapacity);
  }

  /**
   * Copy constructor.
   */
  MemberMap.con2(MemberMap memberMap) {
    initArrays(memberMap._size + 5);
    for (int i = 0; i < memberMap._size; i++) {
      _keys[i] = memberMap._keys[i];
      _values[i] = memberMap._values[i];
    }
    _size = memberMap._size;
  }

  /**
   * Given some key, return the ExecutableElement value from the map, if the key does not exist in
   * the map, `null` is returned.
   *
   * @param key some key to look up in the map
   * @return the associated ExecutableElement value from the map, if the key does not exist in the
   *         map, `null` is returned
   */
  ExecutableElement get(String key) {
    for (int i = 0; i < _size; i++) {
      if (_keys[i] != null && _keys[i] == key) {
        return _values[i];
      }
    }
    return null;
  }

  /**
   * Get and return the key at the specified location. If the key/value pair has been removed from
   * the set, then `null` is returned.
   *
   * @param i some non-zero value less than size
   * @return the key at the passed index
   * @throw ArrayIndexOutOfBoundsException this exception is thrown if the passed index is less than
   *        zero or greater than or equal to the capacity of the arrays
   */
  String getKey(int i) => _keys[i];

  /**
   * The size of the map.
   *
   * @return the size of the map.
   */
  int get size => _size;

  /**
   * Get and return the ExecutableElement at the specified location. If the key/value pair has been
   * removed from the set, then then `null` is returned.
   *
   * @param i some non-zero value less than size
   * @return the key at the passed index
   * @throw ArrayIndexOutOfBoundsException this exception is thrown if the passed index is less than
   *        zero or greater than or equal to the capacity of the arrays
   */
  ExecutableElement getValue(int i) => _values[i];

  /**
   * Given some key/value pair, store the pair in the map. If the key exists already, then the new
   * value overrides the old value.
   *
   * @param key the key to store in the map
   * @param value the ExecutableElement value to store in the map
   */
  void put(String key, ExecutableElement value) {
    // If we already have a value with this key, override the value
    for (int i = 0; i < _size; i++) {
      if (_keys[i] != null && _keys[i] == key) {
        _values[i] = value;
        return;
      }
    }
    // If needed, double the size of our arrays and copy values over in both arrays
    if (_size == _keys.length) {
      int newArrayLength = _size * 2;
      List<String> keys_new_array = new List<String>(newArrayLength);
      List<ExecutableElement> values_new_array = new List<ExecutableElement>(newArrayLength);
      for (int i = 0; i < _size; i++) {
        keys_new_array[i] = _keys[i];
      }
      for (int i = 0; i < _size; i++) {
        values_new_array[i] = _values[i];
      }
      _keys = keys_new_array;
      _values = values_new_array;
    }
    // Put new value at end of array
    _keys[_size] = key;
    _values[_size] = value;
    _size++;
  }

  /**
   * Given some [String] key, this method replaces the associated key and value pair with
   * `null`. The size is not decremented with this call, instead it is expected that the users
   * check for `null`.
   *
   * @param key the key of the key/value pair to remove from the map
   */
  void remove(String key) {
    for (int i = 0; i < _size; i++) {
      if (_keys[i] == key) {
        _keys[i] = null;
        _values[i] = null;
        return;
      }
    }
  }

  /**
   * Sets the ExecutableElement at the specified location.
   *
   * @param i some non-zero value less than size
   * @param value the ExecutableElement value to store in the map
   */
  void setValue(int i, ExecutableElement value) {
    _values[i] = value;
  }

  /**
   * Initializes [keys] and [values].
   */
  void initArrays(int initialCapacity) {
    _keys = new List<String>(initialCapacity);
    _values = new List<ExecutableElement>(initialCapacity);
  }
}

/**
 * This class is a wrapper for an [AnalysisError] which can also be queried after resolution
 * to find out if the error should actually be reported. In this case, these errors are conditional
 * on the non-existence of an `@proxy` annotation.
 *
 * If we have other conditional error codes in the future, we should have this class implement some
 * ConditionalErrorCode so that after resolution, a list of ConditionalErrorCode can be visited
 * instead of multiple lists of *ConditionalErrorCodes.
 */
class ProxyConditionalAnalysisError {
  /**
   * The enclosing [ClassElement], this is what will determine if the error code should, or
   * should not, be generated on the source.
   */
  Element _enclosingElement;

  /**
   * The conditional analysis error.
   */
  final AnalysisError analysisError;

  /**
   * Instantiate a new [ProxyConditionalAnalysisError] with some enclosing element and the
   * conditional analysis error.
   *
   * @param enclosingElement the enclosing element
   * @param analysisError the conditional analysis error
   */
  ProxyConditionalAnalysisError(Element enclosingElement, this.analysisError) {
    this._enclosingElement = enclosingElement;
  }

  /**
   * Return `true` iff the enclosing class has the proxy annotation.
   *
   * @return `true` iff the enclosing class has the proxy annotation
   */
  bool shouldIncludeErrorCode() {
    if (_enclosingElement is ClassElement) {
      return !(_enclosingElement as ClassElement).isOrInheritsProxy;
    }
    return true;
  }
}

/**
 * Instances of the class `ResolverVisitor` are used to resolve the nodes within a single
 * compilation unit.
 */
class ResolverVisitor extends ScopedVisitor {
  /**
   * The manager for the inheritance mappings.
   */
  InheritanceManager _inheritanceManager;

  /**
   * The object used to resolve the element associated with the current node.
   */
  ElementResolver _elementResolver;

  /**
   * The object used to compute the type associated with the current node.
   */
  StaticTypeAnalyzer _typeAnalyzer;

  /**
   * The class element representing the class containing the current node, or `null` if the
   * current node is not contained in a class.
   */
  ClassElement _enclosingClass = null;

  /**
   * The element representing the function containing the current node, or `null` if the
   * current node is not contained in a function.
   */
  ExecutableElement _enclosingFunction = null;

  /**
   * The [Comment] before a [FunctionDeclaration] or a [MethodDeclaration] that
   * cannot be resolved where we visited it, because it should be resolved in the scope of the body.
   */
  Comment _commentBeforeFunction = null;

  /**
   * The object keeping track of which elements have had their types overridden.
   */
  TypeOverrideManager _overrideManager = new TypeOverrideManager();

  /**
   * The object keeping track of which elements have had their types promoted.
   */
  TypePromotionManager _promoteManager = new TypePromotionManager();

  /**
   * Proxy conditional error codes.
   */
  List<ProxyConditionalAnalysisError> _proxyConditionalAnalysisErrors = new List<ProxyConditionalAnalysisError>();

  /**
   * Initialize a newly created visitor to resolve the nodes in a compilation unit.
   *
   * @param library the library containing the compilation unit being resolved
   * @param source the source representing the compilation unit being visited
   * @param typeProvider the object used to access the types from the core library
   */
  ResolverVisitor.con1(Library library, Source source, TypeProvider typeProvider) : super.con1(library, source, typeProvider) {
    this._inheritanceManager = library.inheritanceManager;
    this._elementResolver = new ElementResolver(this);
    this._typeAnalyzer = new StaticTypeAnalyzer(this);
  }

  /**
   * Initialize a newly created visitor to resolve the nodes in a compilation unit.
   *
   * @param definingLibrary the element for the library containing the compilation unit being
   *          visited
   * @param source the source representing the compilation unit being visited
   * @param typeProvider the object used to access the types from the core library
   * @param errorListener the error listener that will be informed of any errors that are found
   *          during resolution
   */
  ResolverVisitor.con2(LibraryElement definingLibrary, Source source, TypeProvider typeProvider, InheritanceManager inheritanceManager, AnalysisErrorListener errorListener) : super.con2(definingLibrary, source, typeProvider, errorListener) {
    this._inheritanceManager = inheritanceManager;
    this._elementResolver = new ElementResolver(this);
    this._typeAnalyzer = new StaticTypeAnalyzer(this);
  }

  /**
   * Initialize a newly created visitor to resolve the nodes in an AST node.
   *
   * @param definingLibrary the element for the library containing the node being visited
   * @param source the source representing the compilation unit containing the node being visited
   * @param typeProvider the object used to access the types from the core library
   * @param nameScope the scope used to resolve identifiers in the node that will first be visited
   * @param errorListener the error listener that will be informed of any errors that are found
   *          during resolution
   */
  ResolverVisitor.con3(LibraryElement definingLibrary, Source source, TypeProvider typeProvider, Scope nameScope, AnalysisErrorListener errorListener) : super.con3(definingLibrary, source, typeProvider, nameScope, errorListener) {
    this._inheritanceManager = new InheritanceManager(definingLibrary);
    this._elementResolver = new ElementResolver(this);
    this._typeAnalyzer = new StaticTypeAnalyzer(this);
  }

  /**
   * Return the object keeping track of which elements have had their types overridden.
   *
   * @return the object keeping track of which elements have had their types overridden
   */
  TypeOverrideManager get overrideManager => _overrideManager;

  /**
   * Return the object keeping track of which elements have had their types promoted.
   *
   * @return the object keeping track of which elements have had their types promoted
   */
  TypePromotionManager get promoteManager => _promoteManager;

  List<ProxyConditionalAnalysisError> get proxyConditionalAnalysisErrors => _proxyConditionalAnalysisErrors;

  Object visitAsExpression(AsExpression node) {
    super.visitAsExpression(node);
    override(node.expression, node.type.type);
    return null;
  }

  Object visitAssertStatement(AssertStatement node) {
    super.visitAssertStatement(node);
    propagateTrueState(node.condition);
    return null;
  }

  Object visitBinaryExpression(BinaryExpression node) {
    sc.TokenType operatorType = node.operator.type;
    Expression leftOperand = node.leftOperand;
    Expression rightOperand = node.rightOperand;
    if (identical(operatorType, sc.TokenType.AMPERSAND_AMPERSAND)) {
      safelyVisit(leftOperand);
      if (rightOperand != null) {
        try {
          _overrideManager.enterScope();
          _promoteManager.enterScope();
          propagateTrueState(leftOperand);
          // Type promotion.
          promoteTypes(leftOperand);
          clearTypePromotionsIfPotentiallyMutatedIn(leftOperand);
          clearTypePromotionsIfPotentiallyMutatedIn(rightOperand);
          clearTypePromotionsIfAccessedInClosureAndProtentiallyMutated(rightOperand);
          // Visit right operand.
          rightOperand.accept(this);
        } finally {
          _overrideManager.exitScope();
          _promoteManager.exitScope();
        }
      }
    } else if (identical(operatorType, sc.TokenType.BAR_BAR)) {
      safelyVisit(leftOperand);
      if (rightOperand != null) {
        try {
          _overrideManager.enterScope();
          propagateFalseState(leftOperand);
          rightOperand.accept(this);
        } finally {
          _overrideManager.exitScope();
        }
      }
    } else {
      safelyVisit(leftOperand);
      safelyVisit(rightOperand);
    }
    node.accept(_elementResolver);
    node.accept(_typeAnalyzer);
    return null;
  }

  Object visitBlockFunctionBody(BlockFunctionBody node) {
    safelyVisit(_commentBeforeFunction);
    try {
      _overrideManager.enterScope();
      super.visitBlockFunctionBody(node);
    } finally {
      _overrideManager.exitScope();
    }
    return null;
  }

  Object visitBreakStatement(BreakStatement node) {
    //
    // We do not visit the label because it needs to be visited in the context of the statement.
    //
    node.accept(_elementResolver);
    node.accept(_typeAnalyzer);
    return null;
  }

  Object visitClassDeclaration(ClassDeclaration node) {
    ClassElement outerType = _enclosingClass;
    try {
      _enclosingClass = node.element;
      _typeAnalyzer.thisType = _enclosingClass == null ? null : _enclosingClass.type;
      super.visitClassDeclaration(node);
    } finally {
      _typeAnalyzer.thisType = outerType == null ? null : outerType.type;
      _enclosingClass = outerType;
    }
    return null;
  }

  Object visitComment(Comment node) {
    if (node.parent is FunctionDeclaration || node.parent is ConstructorDeclaration || node.parent is MethodDeclaration) {
      if (node != _commentBeforeFunction) {
        _commentBeforeFunction = node;
        return null;
      }
    }
    super.visitComment(node);
    _commentBeforeFunction = null;
    return null;
  }

  Object visitCommentReference(CommentReference node) {
    //
    // We do not visit the identifier because it needs to be visited in the context of the reference.
    //
    node.accept(_elementResolver);
    node.accept(_typeAnalyzer);
    return null;
  }

  Object visitCompilationUnit(CompilationUnit node) {
    //
    // TODO(brianwilkerson) The goal of the code below is to visit the declarations in such an
    // order that we can infer type information for top-level variables before we visit references
    // to them. This is better than making no effort, but still doesn't completely satisfy that
    // goal (consider for example "final var a = b; final var b = 0;"; we'll infer a type of 'int'
    // for 'b', but not for 'a' because of the order of the visits). Ideally we would create a
    // dependency graph, but that would require references to be resolved, which they are not.
    //
    try {
      _overrideManager.enterScope();
      NodeList<Directive> directives = node.directives;
      int directiveCount = directives.length;
      for (int i = 0; i < directiveCount; i++) {
        directives[i].accept(this);
      }
      NodeList<CompilationUnitMember> declarations = node.declarations;
      int declarationCount = declarations.length;
      for (int i = 0; i < declarationCount; i++) {
        CompilationUnitMember declaration = declarations[i];
        if (declaration is! ClassDeclaration) {
          declaration.accept(this);
        }
      }
      for (int i = 0; i < declarationCount; i++) {
        CompilationUnitMember declaration = declarations[i];
        if (declaration is ClassDeclaration) {
          declaration.accept(this);
        }
      }
    } finally {
      _overrideManager.exitScope();
    }
    node.accept(_elementResolver);
    node.accept(_typeAnalyzer);
    return null;
  }

  Object visitConditionalExpression(ConditionalExpression node) {
    Expression condition = node.condition;
    safelyVisit(condition);
    Expression thenExpression = node.thenExpression;
    if (thenExpression != null) {
      try {
        _overrideManager.enterScope();
        _promoteManager.enterScope();
        propagateTrueState(condition);
        // Type promotion.
        promoteTypes(condition);
        clearTypePromotionsIfPotentiallyMutatedIn(thenExpression);
        clearTypePromotionsIfAccessedInClosureAndProtentiallyMutated(thenExpression);
        // Visit "then" expression.
        thenExpression.accept(this);
      } finally {
        _overrideManager.exitScope();
        _promoteManager.exitScope();
      }
    }
    Expression elseExpression = node.elseExpression;
    if (elseExpression != null) {
      try {
        _overrideManager.enterScope();
        propagateFalseState(condition);
        elseExpression.accept(this);
      } finally {
        _overrideManager.exitScope();
      }
    }
    node.accept(_elementResolver);
    node.accept(_typeAnalyzer);
    bool thenIsAbrupt = isAbruptTermination(thenExpression);
    bool elseIsAbrupt = isAbruptTermination(elseExpression);
    if (elseIsAbrupt && !thenIsAbrupt) {
      propagateTrueState(condition);
      propagateState(thenExpression);
    } else if (thenIsAbrupt && !elseIsAbrupt) {
      propagateFalseState(condition);
      propagateState(elseExpression);
    }
    return null;
  }

  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    ExecutableElement outerFunction = _enclosingFunction;
    try {
      _enclosingFunction = node.element;
      super.visitConstructorDeclaration(node);
    } finally {
      _enclosingFunction = outerFunction;
    }
    return null;
  }

  Object visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    //
    // We visit the expression, but do not visit the field name because it needs to be visited in
    // the context of the constructor field initializer node.
    //
    safelyVisit(node.expression);
    node.accept(_elementResolver);
    node.accept(_typeAnalyzer);
    return null;
  }

  Object visitConstructorName(ConstructorName node) {
    //
    // We do not visit either the type name, because it won't be visited anyway, or the name,
    // because it needs to be visited in the context of the constructor name.
    //
    node.accept(_elementResolver);
    node.accept(_typeAnalyzer);
    return null;
  }

  Object visitContinueStatement(ContinueStatement node) {
    //
    // We do not visit the label because it needs to be visited in the context of the statement.
    //
    node.accept(_elementResolver);
    node.accept(_typeAnalyzer);
    return null;
  }

  Object visitDoStatement(DoStatement node) {
    try {
      _overrideManager.enterScope();
      super.visitDoStatement(node);
    } finally {
      _overrideManager.exitScope();
    }
    // TODO(brianwilkerson) If the loop can only be exited because the condition is false, then
    // propagateFalseState(node.getCondition());
    return null;
  }

  Object visitEmptyFunctionBody(EmptyFunctionBody node) {
    safelyVisit(_commentBeforeFunction);
    return super.visitEmptyFunctionBody(node);
  }

  Object visitExpressionFunctionBody(ExpressionFunctionBody node) {
    safelyVisit(_commentBeforeFunction);
    try {
      _overrideManager.enterScope();
      super.visitExpressionFunctionBody(node);
    } finally {
      _overrideManager.exitScope();
    }
    return null;
  }

  Object visitFieldDeclaration(FieldDeclaration node) {
    try {
      _overrideManager.enterScope();
      super.visitFieldDeclaration(node);
    } finally {
      Map<Element, Type2> overrides = _overrideManager.captureOverrides(node.fields);
      _overrideManager.exitScope();
      _overrideManager.applyOverrides(overrides);
    }
    return null;
  }

  Object visitForEachStatement(ForEachStatement node) {
    try {
      _overrideManager.enterScope();
      super.visitForEachStatement(node);
    } finally {
      _overrideManager.exitScope();
    }
    return null;
  }

  Object visitForStatement(ForStatement node) {
    try {
      _overrideManager.enterScope();
      super.visitForStatement(node);
    } finally {
      _overrideManager.exitScope();
    }
    return null;
  }

  Object visitFunctionDeclaration(FunctionDeclaration node) {
    ExecutableElement outerFunction = _enclosingFunction;
    try {
      SimpleIdentifier functionName = node.name;
      _enclosingFunction = functionName.staticElement as ExecutableElement;
      super.visitFunctionDeclaration(node);
    } finally {
      _enclosingFunction = outerFunction;
    }
    return null;
  }

  Object visitFunctionExpression(FunctionExpression node) {
    ExecutableElement outerFunction = _enclosingFunction;
    try {
      _enclosingFunction = node.element;
      _overrideManager.enterScope();
      super.visitFunctionExpression(node);
    } finally {
      _overrideManager.exitScope();
      _enclosingFunction = outerFunction;
    }
    return null;
  }

  Object visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    safelyVisit(node.function);
    node.accept(_elementResolver);
    inferFunctionExpressionsParametersTypes(node.argumentList);
    safelyVisit(node.argumentList);
    node.accept(_typeAnalyzer);
    return null;
  }

  Object visitHideCombinator(HideCombinator node) => null;

  Object visitIfStatement(IfStatement node) {
    Expression condition = node.condition;
    safelyVisit(condition);
    Map<Element, Type2> thenOverrides = null;
    Statement thenStatement = node.thenStatement;
    if (thenStatement != null) {
      try {
        _overrideManager.enterScope();
        _promoteManager.enterScope();
        propagateTrueState(condition);
        // Type promotion.
        promoteTypes(condition);
        clearTypePromotionsIfPotentiallyMutatedIn(thenStatement);
        clearTypePromotionsIfAccessedInClosureAndProtentiallyMutated(thenStatement);
        // Visit "then".
        visitStatementInScope(thenStatement);
      } finally {
        thenOverrides = _overrideManager.captureLocalOverrides();
        _overrideManager.exitScope();
        _promoteManager.exitScope();
      }
    }
    Map<Element, Type2> elseOverrides = null;
    Statement elseStatement = node.elseStatement;
    if (elseStatement != null) {
      try {
        _overrideManager.enterScope();
        propagateFalseState(condition);
        visitStatementInScope(elseStatement);
      } finally {
        elseOverrides = _overrideManager.captureLocalOverrides();
        _overrideManager.exitScope();
      }
    }
    node.accept(_elementResolver);
    node.accept(_typeAnalyzer);
    bool thenIsAbrupt = isAbruptTermination2(thenStatement);
    bool elseIsAbrupt = isAbruptTermination2(elseStatement);
    if (elseIsAbrupt && !thenIsAbrupt) {
      propagateTrueState(condition);
      if (thenOverrides != null) {
        _overrideManager.applyOverrides(thenOverrides);
      }
    } else if (thenIsAbrupt && !elseIsAbrupt) {
      propagateFalseState(condition);
      if (elseOverrides != null) {
        _overrideManager.applyOverrides(elseOverrides);
      }
    }
    return null;
  }

  Object visitLabel(Label node) => null;

  Object visitLibraryIdentifier(LibraryIdentifier node) => null;

  Object visitMethodDeclaration(MethodDeclaration node) {
    ExecutableElement outerFunction = _enclosingFunction;
    try {
      _enclosingFunction = node.element;
      super.visitMethodDeclaration(node);
    } finally {
      _enclosingFunction = outerFunction;
    }
    return null;
  }

  Object visitMethodInvocation(MethodInvocation node) {
    //
    // We visit the target and argument list, but do not visit the method name because it needs to
    // be visited in the context of the invocation.
    //
    safelyVisit(node.target);
    node.accept(_elementResolver);
    inferFunctionExpressionsParametersTypes(node.argumentList);
    safelyVisit(node.argumentList);
    node.accept(_typeAnalyzer);
    return null;
  }

  Object visitNode(AstNode node) {
    node.visitChildren(this);
    node.accept(_elementResolver);
    node.accept(_typeAnalyzer);
    return null;
  }

  Object visitPrefixedIdentifier(PrefixedIdentifier node) {
    //
    // We visit the prefix, but do not visit the identifier because it needs to be visited in the
    // context of the prefix.
    //
    safelyVisit(node.prefix);
    node.accept(_elementResolver);
    node.accept(_typeAnalyzer);
    return null;
  }

  Object visitPropertyAccess(PropertyAccess node) {
    //
    // We visit the target, but do not visit the property name because it needs to be visited in the
    // context of the property access node.
    //
    safelyVisit(node.target);
    node.accept(_elementResolver);
    node.accept(_typeAnalyzer);
    return null;
  }

  Object visitRedirectingConstructorInvocation(RedirectingConstructorInvocation node) {
    //
    // We visit the argument list, but do not visit the optional identifier because it needs to be
    // visited in the context of the constructor invocation.
    //
    safelyVisit(node.argumentList);
    node.accept(_elementResolver);
    node.accept(_typeAnalyzer);
    return null;
  }

  Object visitShowCombinator(ShowCombinator node) => null;

  Object visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    //
    // We visit the argument list, but do not visit the optional identifier because it needs to be
    // visited in the context of the constructor invocation.
    //
    safelyVisit(node.argumentList);
    node.accept(_elementResolver);
    node.accept(_typeAnalyzer);
    return null;
  }

  Object visitSwitchCase(SwitchCase node) {
    try {
      _overrideManager.enterScope();
      super.visitSwitchCase(node);
    } finally {
      _overrideManager.exitScope();
    }
    return null;
  }

  Object visitSwitchDefault(SwitchDefault node) {
    try {
      _overrideManager.enterScope();
      super.visitSwitchDefault(node);
    } finally {
      _overrideManager.exitScope();
    }
    return null;
  }

  Object visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    try {
      _overrideManager.enterScope();
      super.visitTopLevelVariableDeclaration(node);
    } finally {
      Map<Element, Type2> overrides = _overrideManager.captureOverrides(node.variables);
      _overrideManager.exitScope();
      _overrideManager.applyOverrides(overrides);
    }
    return null;
  }

  Object visitTypeName(TypeName node) => null;

  Object visitWhileStatement(WhileStatement node) {
    Expression condition = node.condition;
    safelyVisit(condition);
    Statement body = node.body;
    if (body != null) {
      try {
        _overrideManager.enterScope();
        propagateTrueState(condition);
        visitStatementInScope(body);
      } finally {
        _overrideManager.exitScope();
      }
    }
    // TODO(brianwilkerson) If the loop can only be exited because the condition is false, then
    // propagateFalseState(condition);
    node.accept(_elementResolver);
    node.accept(_typeAnalyzer);
    return null;
  }

  /**
   * Return the class element representing the class containing the current node, or `null` if
   * the current node is not contained in a class.
   *
   * @return the class element representing the class containing the current node
   */
  ClassElement get enclosingClass => _enclosingClass;

  /**
   * Return the element representing the function containing the current node, or `null` if
   * the current node is not contained in a function.
   *
   * @return the element representing the function containing the current node
   */
  ExecutableElement get enclosingFunction => _enclosingFunction;

  /**
   * Return the propagated element associated with the given expression whose type can be
   * overridden, or `null` if there is no element whose type can be overridden.
   *
   * @param expression the expression with which the element is associated
   * @return the element associated with the given expression
   */
  VariableElement getOverridablePropagatedElement(Expression expression) {
    Element element = null;
    if (expression is SimpleIdentifier) {
      element = expression.propagatedElement;
    } else if (expression is PrefixedIdentifier) {
      element = expression.propagatedElement;
    } else if (expression is PropertyAccess) {
      element = expression.propertyName.propagatedElement;
    }
    if (element is VariableElement) {
      return element as VariableElement;
    }
    return null;
  }

  /**
   * Return the static element associated with the given expression whose type can be overridden, or
   * `null` if there is no element whose type can be overridden.
   *
   * @param expression the expression with which the element is associated
   * @return the element associated with the given expression
   */
  VariableElement getOverridableStaticElement(Expression expression) {
    Element element = null;
    if (expression is SimpleIdentifier) {
      element = expression.staticElement;
    } else if (expression is PrefixedIdentifier) {
      element = expression.staticElement;
    } else if (expression is PropertyAccess) {
      element = expression.propertyName.staticElement;
    }
    if (element is VariableElement) {
      return element as VariableElement;
    }
    return null;
  }

  /**
   * Return the static element associated with the given expression whose type can be promoted, or
   * `null` if there is no element whose type can be promoted.
   *
   * @param expression the expression with which the element is associated
   * @return the element associated with the given expression
   */
  VariableElement getPromotionStaticElement(Expression expression) {
    while (expression is ParenthesizedExpression) {
      expression = (expression as ParenthesizedExpression).expression;
    }
    if (expression is! SimpleIdentifier) {
      return null;
    }
    SimpleIdentifier identifier = expression as SimpleIdentifier;
    Element element = identifier.staticElement;
    if (element is! VariableElement) {
      return null;
    }
    ElementKind kind = element.kind;
    if (identical(kind, ElementKind.LOCAL_VARIABLE)) {
      return element as VariableElement;
    }
    if (identical(kind, ElementKind.PARAMETER)) {
      return element as VariableElement;
    }
    return null;
  }

  /**
   * If it is appropriate to do so, override the current type of the static and propagated elements
   * associated with the given expression with the given type. Generally speaking, it is appropriate
   * if the given type is more specific than the current type.
   *
   * @param expression the expression used to access the static and propagated elements whose types
   *          might be overridden
   * @param potentialType the potential type of the elements
   */
  void override(Expression expression, Type2 potentialType) {
    VariableElement element = getOverridableStaticElement(expression);
    if (element != null) {
      override2(element, potentialType);
    }
    element = getOverridablePropagatedElement(expression);
    if (element != null) {
      override2(element, potentialType);
    }
  }

  /**
   * If it is appropriate to do so, override the current type of the given element with the given
   * type. Generally speaking, it is appropriate if the given type is more specific than the current
   * type.
   *
   * @param element the element whose type might be overridden
   * @param potentialType the potential type of the element
   */
  void override2(VariableElement element, Type2 potentialType) {
    if (potentialType == null || potentialType.isBottom) {
      return;
    }
    if (element is PropertyInducingElement) {
      PropertyInducingElement variable = element;
      if (!variable.isConst && !variable.isFinal) {
        return;
      }
    }
    Type2 currentType = getBestType(element);
    if (currentType == null || !currentType.isMoreSpecificThan(potentialType)) {
      _overrideManager.setType(element, potentialType);
    }
  }

  /**
   * Report a conditional analysis error with the given error code and arguments.
   *
   * @param enclosingElement the enclosing element
   * @param errorCode the error code of the error to be reported
   * @param node the node specifying the location of the error
   * @param arguments the arguments to the error, used to compose the error message
   */
  void reportErrorProxyConditionalAnalysisError(Element enclosingElement, ErrorCode errorCode, AstNode node, List<Object> arguments) {
    _proxyConditionalAnalysisErrors.add(new ProxyConditionalAnalysisError(enclosingElement, new AnalysisError.con2(source, node.offset, node.length, errorCode, arguments)));
  }

  /**
   * Report a conditional analysis error with the given error code and arguments.
   *
   * @param enclosingElement the enclosing element
   * @param errorCode the error code of the error to be reported
   * @param offset the offset of the location of the error
   * @param length the length of the location of the error
   * @param arguments the arguments to the error, used to compose the error message
   */
  void reportErrorProxyConditionalAnalysisError2(Element enclosingElement, ErrorCode errorCode, int offset, int length, List<Object> arguments) {
    _proxyConditionalAnalysisErrors.add(new ProxyConditionalAnalysisError(enclosingElement, new AnalysisError.con2(source, offset, length, errorCode, arguments)));
  }

  /**
   * Report a conditional analysis error with the given error code and arguments.
   *
   * @param enclosingElement the enclosing element
   * @param errorCode the error code of the error to be reported
   * @param token the token specifying the location of the error
   * @param arguments the arguments to the error, used to compose the error message
   */
  void reportErrorProxyConditionalAnalysisError3(Element enclosingElement, ErrorCode errorCode, sc.Token token, List<Object> arguments) {
    _proxyConditionalAnalysisErrors.add(new ProxyConditionalAnalysisError(enclosingElement, new AnalysisError.con2(source, token.offset, token.length, errorCode, arguments)));
  }

  void visitForEachStatementInScope(ForEachStatement node) {
    //
    // We visit the iterator before the loop variable because the loop variable cannot be in scope
    // while visiting the iterator.
    //
    Expression iterator = node.iterator;
    safelyVisit(iterator);
    DeclaredIdentifier loopVariable = node.loopVariable;
    SimpleIdentifier identifier = node.identifier;
    safelyVisit(loopVariable);
    safelyVisit(identifier);
    Statement body = node.body;
    if (body != null) {
      try {
        _overrideManager.enterScope();
        if (loopVariable != null && iterator != null) {
          LocalVariableElement loopElement = loopVariable.element;
          if (loopElement != null) {
            Type2 iteratorElementType = getIteratorElementType(iterator);
            override2(loopElement, iteratorElementType);
            recordPropagatedType(loopVariable.identifier, iteratorElementType);
          }
        } else if (identifier != null && iterator != null) {
          Element identifierElement = identifier.staticElement;
          if (identifierElement is VariableElement) {
            Type2 iteratorElementType = getIteratorElementType(iterator);
            override2(identifierElement, iteratorElementType);
            recordPropagatedType(identifier, iteratorElementType);
          }
        }
        visitStatementInScope(body);
      } finally {
        _overrideManager.exitScope();
      }
    }
    node.accept(_elementResolver);
    node.accept(_typeAnalyzer);
  }

  void visitForStatementInScope(ForStatement node) {
    safelyVisit(node.variables);
    safelyVisit(node.initialization);
    safelyVisit(node.condition);
    _overrideManager.enterScope();
    try {
      propagateTrueState(node.condition);
      visitStatementInScope(node.body);
      node.updaters.accept(this);
    } finally {
      _overrideManager.exitScope();
    }
  }

  /**
   * Checks each promoted variable in the current scope for compliance with the following
   * specification statement:
   *
   * If the variable <i>v</i> is accessed by a closure in <i>s<sub>1</sub></i> then the variable
   * <i>v</i> is not potentially mutated anywhere in the scope of <i>v</i>.
   */
  void clearTypePromotionsIfAccessedInClosureAndProtentiallyMutated(AstNode target) {
    for (Element element in _promoteManager.promotedElements) {
      if ((element as VariableElementImpl).isPotentiallyMutatedInScope) {
        if (isVariableAccessedInClosure(element, target)) {
          _promoteManager.setType(element, null);
        }
      }
    }
  }

  /**
   * Checks each promoted variable in the current scope for compliance with the following
   * specification statement:
   *
   * <i>v</i> is not potentially mutated in <i>s<sub>1</sub></i> or within a closure.
   */
  void clearTypePromotionsIfPotentiallyMutatedIn(AstNode target) {
    for (Element element in _promoteManager.promotedElements) {
      if (isVariablePotentiallyMutatedIn(element, target)) {
        _promoteManager.setType(element, null);
      }
    }
  }

  /**
   * Return the best type information available for the given element. If the type of the element
   * has been overridden, then return the overriding type. Otherwise, return the static type.
   *
   * @param element the element for which type information is to be returned
   * @return the best type information available for the given element
   */
  Type2 getBestType(Element element) {
    Type2 bestType = _overrideManager.getType(element);
    if (bestType == null) {
      if (element is LocalVariableElement) {
        bestType = element.type;
      } else if (element is ParameterElement) {
        bestType = element.type;
      }
    }
    return bestType;
  }

  /**
   * The given expression is the expression used to compute the iterator for a for-each statement.
   * Attempt to compute the type of objects that will be assigned to the loop variable and return
   * that type. Return `null` if the type could not be determined.
   *
   * @param iterator the iterator for a for-each statement
   * @return the type of objects that will be assigned to the loop variable
   */
  Type2 getIteratorElementType(Expression iteratorExpression) {
    Type2 expressionType = iteratorExpression.staticType;
    if (expressionType is InterfaceType) {
      InterfaceType interfaceType = expressionType;
      FunctionType iteratorFunction = _inheritanceManager.lookupMemberType(interfaceType, "iterator");
      if (iteratorFunction == null) {
        // TODO(brianwilkerson) Should we report this error?
        return null;
      }
      Type2 iteratorType = iteratorFunction.returnType;
      if (iteratorType is InterfaceType) {
        InterfaceType iteratorInterfaceType = iteratorType;
        FunctionType currentFunction = _inheritanceManager.lookupMemberType(iteratorInterfaceType, "current");
        if (currentFunction == null) {
          // TODO(brianwilkerson) Should we report this error?
          return null;
        }
        return currentFunction.returnType;
      }
    }
    return null;
  }

  /**
   * If given "mayBeClosure" is [FunctionExpression] without explicit parameters types and its
   * required type is [FunctionType], then infer parameters types from [FunctionType].
   */
  void inferFunctionExpressionParametersTypes(Expression mayBeClosure, Type2 mayByFunctionType) {
    // prepare closure
    if (mayBeClosure is! FunctionExpression) {
      return;
    }
    FunctionExpression closure = mayBeClosure as FunctionExpression;
    // prepare expected closure type
    if (mayByFunctionType is! FunctionType) {
      return;
    }
    FunctionType expectedClosureType = mayByFunctionType as FunctionType;
    // set propagated type for the closure
    closure.propagatedType = expectedClosureType;
    // set inferred types for parameters
    NodeList<FormalParameter> parameters = closure.parameters.parameters;
    List<ParameterElement> expectedParameters = expectedClosureType.parameters;
    for (int i = 0; i < parameters.length && i < expectedParameters.length; i++) {
      FormalParameter parameter = parameters[i];
      ParameterElement element = parameter.element;
      Type2 currentType = getBestType(element);
      // may be override the type
      Type2 expectedType = expectedParameters[i].type;
      if (currentType == null || expectedType.isMoreSpecificThan(currentType)) {
        _overrideManager.setType(element, expectedType);
      }
    }
  }

  /**
   * Try to infer types of parameters of the [FunctionExpression] arguments.
   */
  void inferFunctionExpressionsParametersTypes(ArgumentList argumentList) {
    for (Expression argument in argumentList.arguments) {
      ParameterElement parameter = argument.propagatedParameterElement;
      if (parameter == null) {
        parameter = argument.staticParameterElement;
      }
      if (parameter != null) {
        inferFunctionExpressionParametersTypes(argument, parameter.type);
      }
    }
  }

  /**
   * Return `true` if the given expression terminates abruptly (that is, if any expression
   * following the given expression will not be reached).
   *
   * @param expression the expression being tested
   * @return `true` if the given expression terminates abruptly
   */
  bool isAbruptTermination(Expression expression) {
    // TODO(brianwilkerson) This needs to be significantly improved. Ideally we would eventually
    // turn this into a method on Expression that returns a termination indication (normal, abrupt
    // with no exception, abrupt with an exception).
    while (expression is ParenthesizedExpression) {
      expression = (expression as ParenthesizedExpression).expression;
    }
    return expression is ThrowExpression || expression is RethrowExpression;
  }

  /**
   * Return `true` if the given statement terminates abruptly (that is, if any statement
   * following the given statement will not be reached).
   *
   * @param statement the statement being tested
   * @return `true` if the given statement terminates abruptly
   */
  bool isAbruptTermination2(Statement statement) {
    // TODO(brianwilkerson) This needs to be significantly improved. Ideally we would eventually
    // turn this into a method on Statement that returns a termination indication (normal, abrupt
    // with no exception, abrupt with an exception).
    if (statement is ReturnStatement || statement is BreakStatement || statement is ContinueStatement) {
      return true;
    } else if (statement is ExpressionStatement) {
      return isAbruptTermination(statement.expression);
    } else if (statement is Block) {
      NodeList<Statement> statements = statement.statements;
      int size = statements.length;
      if (size == 0) {
        return false;
      }
      return isAbruptTermination2(statements[size - 1]);
    }
    return false;
  }

  /**
   * Return `true` if the given variable is accessed within a closure in the given
   * [AstNode] and also mutated somewhere in variable scope. This information is only
   * available for local variables (including parameters).
   *
   * @param variable the variable to check
   * @param target the [AstNode] to check within
   * @return `true` if this variable is potentially mutated somewhere in the given ASTNode
   */
  bool isVariableAccessedInClosure(Element variable, AstNode target) {
    List<bool> result = [false];
    target.accept(new RecursiveAstVisitor_ResolverVisitor_isVariableAccessedInClosure(result, variable));
    return result[0];
  }

  /**
   * Return `true` if the given variable is potentially mutated somewhere in the given
   * [AstNode]. This information is only available for local variables (including parameters).
   *
   * @param variable the variable to check
   * @param target the [AstNode] to check within
   * @return `true` if this variable is potentially mutated somewhere in the given ASTNode
   */
  bool isVariablePotentiallyMutatedIn(Element variable, AstNode target) {
    List<bool> result = [false];
    target.accept(new RecursiveAstVisitor_ResolverVisitor_isVariablePotentiallyMutatedIn(result, variable));
    return result[0];
  }

  /**
   * If it is appropriate to do so, promotes the current type of the static element associated with
   * the given expression with the given type. Generally speaking, it is appropriate if the given
   * type is more specific than the current type.
   *
   * @param expression the expression used to access the static element whose types might be
   *          promoted
   * @param potentialType the potential type of the elements
   */
  void promote(Expression expression, Type2 potentialType) {
    VariableElement element = getPromotionStaticElement(expression);
    if (element != null) {
      // may be mutated somewhere in closure
      if ((element as VariableElementImpl).isPotentiallyMutatedInClosure) {
        return;
      }
      // prepare current variable type
      Type2 type = _promoteManager.getType(element);
      if (type == null) {
        type = expression.staticType;
      }
      // Declared type should not be "dynamic".
      if (type == null || type.isDynamic) {
        return;
      }
      // Promoted type should not be "dynamic".
      if (potentialType == null || potentialType.isDynamic) {
        return;
      }
      // Promoted type should be more specific than declared.
      if (!potentialType.isMoreSpecificThan(type)) {
        return;
      }
      // Do promote type of variable.
      _promoteManager.setType(element, potentialType);
    }
  }

  /**
   * Promotes type information using given condition.
   */
  void promoteTypes(Expression condition) {
    if (condition is BinaryExpression) {
      BinaryExpression binary = condition;
      if (identical(binary.operator.type, sc.TokenType.AMPERSAND_AMPERSAND)) {
        Expression left = binary.leftOperand;
        Expression right = binary.rightOperand;
        promoteTypes(left);
        promoteTypes(right);
        clearTypePromotionsIfPotentiallyMutatedIn(right);
      }
    } else if (condition is IsExpression) {
      IsExpression is2 = condition;
      if (is2.notOperator == null) {
        promote(is2.expression, is2.type.type);
      }
    } else if (condition is ParenthesizedExpression) {
      promoteTypes(condition.expression);
    }
  }

  /**
   * Propagate any type information that results from knowing that the given condition will have
   * been evaluated to 'false'.
   *
   * @param condition the condition that will have evaluated to 'false'
   */
  void propagateFalseState(Expression condition) {
    if (condition is BinaryExpression) {
      BinaryExpression binary = condition;
      if (identical(binary.operator.type, sc.TokenType.BAR_BAR)) {
        propagateFalseState(binary.leftOperand);
        propagateFalseState(binary.rightOperand);
      }
    } else if (condition is IsExpression) {
      IsExpression is2 = condition;
      if (is2.notOperator != null) {
        override(is2.expression, is2.type.type);
      }
    } else if (condition is PrefixExpression) {
      PrefixExpression prefix = condition;
      if (identical(prefix.operator.type, sc.TokenType.BANG)) {
        propagateTrueState(prefix.operand);
      }
    } else if (condition is ParenthesizedExpression) {
      propagateFalseState(condition.expression);
    }
  }

  /**
   * Propagate any type information that results from knowing that the given expression will have
   * been evaluated without altering the flow of execution.
   *
   * @param expression the expression that will have been evaluated
   */
  void propagateState(Expression expression) {
  }

  /**
   * Propagate any type information that results from knowing that the given condition will have
   * been evaluated to 'true'.
   *
   * @param condition the condition that will have evaluated to 'true'
   */
  void propagateTrueState(Expression condition) {
    if (condition is BinaryExpression) {
      BinaryExpression binary = condition;
      if (identical(binary.operator.type, sc.TokenType.AMPERSAND_AMPERSAND)) {
        propagateTrueState(binary.leftOperand);
        propagateTrueState(binary.rightOperand);
      }
    } else if (condition is IsExpression) {
      IsExpression is2 = condition;
      if (is2.notOperator == null) {
        override(is2.expression, is2.type.type);
      }
    } else if (condition is PrefixExpression) {
      PrefixExpression prefix = condition;
      if (identical(prefix.operator.type, sc.TokenType.BANG)) {
        propagateFalseState(prefix.operand);
      }
    } else if (condition is ParenthesizedExpression) {
      propagateTrueState(condition.expression);
    }
  }

  /**
   * Record that the propagated type of the given node is the given type.
   *
   * @param expression the node whose type is to be recorded
   * @param type the propagated type of the node
   */
  void recordPropagatedType(Expression expression, Type2 type) {
    if (type != null && !type.isDynamic) {
      expression.propagatedType = type;
    }
  }

  get elementResolver_J2DAccessor => _elementResolver;

  set elementResolver_J2DAccessor(__v) => _elementResolver = __v;

  get labelScope_J2DAccessor => _labelScope;

  set labelScope_J2DAccessor(__v) => _labelScope = __v;

  get nameScope_J2DAccessor => _nameScope;

  set nameScope_J2DAccessor(__v) => _nameScope = __v;

  get typeAnalyzer_J2DAccessor => _typeAnalyzer;

  set typeAnalyzer_J2DAccessor(__v) => _typeAnalyzer = __v;

  get enclosingClass_J2DAccessor => _enclosingClass;

  set enclosingClass_J2DAccessor(__v) => _enclosingClass = __v;
}

class RecursiveAstVisitor_ResolverVisitor_isVariableAccessedInClosure extends RecursiveAstVisitor<Object> {
  List<bool> result;

  Element variable;

  RecursiveAstVisitor_ResolverVisitor_isVariableAccessedInClosure(this.result, this.variable) : super();

  bool _inClosure = false;

  Object visitFunctionExpression(FunctionExpression node) {
    bool inClosure = this._inClosure;
    try {
      this._inClosure = true;
      return super.visitFunctionExpression(node);
    } finally {
      this._inClosure = inClosure;
    }
  }

  Object visitSimpleIdentifier(SimpleIdentifier node) {
    if (result[0]) {
      return null;
    }
    if (_inClosure && identical(node.staticElement, variable)) {
      result[0] = javaBooleanOr(result[0], true);
    }
    return null;
  }
}

class RecursiveAstVisitor_ResolverVisitor_isVariablePotentiallyMutatedIn extends RecursiveAstVisitor<Object> {
  List<bool> result;

  Element variable;

  RecursiveAstVisitor_ResolverVisitor_isVariablePotentiallyMutatedIn(this.result, this.variable) : super();

  Object visitSimpleIdentifier(SimpleIdentifier node) {
    if (result[0]) {
      return null;
    }
    if (identical(node.staticElement, variable)) {
      if (node.inSetterContext()) {
        result[0] = javaBooleanOr(result[0], true);
      }
    }
    return null;
  }
}

/**
 * The abstract class `ScopedVisitor` maintains name and label scopes as an AST structure is
 * being visited.
 */
abstract class ScopedVisitor extends UnifyingAstVisitor<Object> {
  /**
   * The element for the library containing the compilation unit being visited.
   */
  LibraryElement _definingLibrary;

  /**
   * The source representing the compilation unit being visited.
   */
  final Source source;

  /**
   * The error listener that will be informed of any errors that are found during resolution.
   */
  AnalysisErrorListener _errorListener;

  /**
   * The scope used to resolve identifiers.
   */
  Scope _nameScope;

  /**
   * The object used to access the types from the core library.
   */
  final TypeProvider typeProvider;

  /**
   * The scope used to resolve labels for `break` and `continue` statements, or
   * `null` if no labels have been defined in the current context.
   */
  LabelScope _labelScope;

  /**
   * Initialize a newly created visitor to resolve the nodes in a compilation unit.
   *
   * @param library the library containing the compilation unit being resolved
   * @param source the source representing the compilation unit being visited
   * @param typeProvider the object used to access the types from the core library
   */
  ScopedVisitor.con1(Library library, this.source, this.typeProvider) {
    this._definingLibrary = library.libraryElement;
    LibraryScope libraryScope = library.libraryScope;
    this._errorListener = libraryScope.errorListener;
    this._nameScope = libraryScope;
  }

  /**
   * Initialize a newly created visitor to resolve the nodes in a compilation unit.
   *
   * @param definingLibrary the element for the library containing the compilation unit being
   *          visited
   * @param source the source representing the compilation unit being visited
   * @param typeProvider the object used to access the types from the core library
   * @param errorListener the error listener that will be informed of any errors that are found
   *          during resolution
   */
  ScopedVisitor.con2(LibraryElement definingLibrary, this.source, this.typeProvider, AnalysisErrorListener errorListener) {
    this._definingLibrary = definingLibrary;
    this._errorListener = errorListener;
    this._nameScope = new LibraryScope(definingLibrary, errorListener);
  }

  /**
   * Initialize a newly created visitor to resolve the nodes in a compilation unit.
   *
   * @param definingLibrary the element for the library containing the compilation unit being
   *          visited
   * @param source the source representing the compilation unit being visited
   * @param typeProvider the object used to access the types from the core library
   * @param nameScope the scope used to resolve identifiers in the node that will first be visited
   * @param errorListener the error listener that will be informed of any errors that are found
   *          during resolution
   */
  ScopedVisitor.con3(LibraryElement definingLibrary, this.source, this.typeProvider, Scope nameScope, AnalysisErrorListener errorListener) {
    this._definingLibrary = definingLibrary;
    this._errorListener = errorListener;
    this._nameScope = nameScope;
  }

  /**
   * Return the library element for the library containing the compilation unit being resolved.
   *
   * @return the library element for the library containing the compilation unit being resolved
   */
  LibraryElement get definingLibrary => _definingLibrary;

  /**
   * Replaces the current [Scope] with the enclosing [Scope].
   *
   * @return the enclosing [Scope].
   */
  Scope popNameScope() {
    _nameScope = _nameScope.enclosingScope;
    return _nameScope;
  }

  /**
   * Pushes a new [Scope] into the visitor.
   *
   * @return the new [Scope].
   */
  Scope pushNameScope() {
    Scope newScope = new EnclosedScope(_nameScope);
    _nameScope = newScope;
    return _nameScope;
  }

  /**
   * Report an error with the given analysis error.
   *
   * @param errorCode analysis error
   */
  void reportError(AnalysisError analysisError) {
    _errorListener.onError(analysisError);
  }

  Object visitBlock(Block node) {
    Scope outerScope = _nameScope;
    try {
      EnclosedScope enclosedScope = new EnclosedScope(_nameScope);
      hideNamesDefinedInBlock(enclosedScope, node);
      _nameScope = enclosedScope;
      super.visitBlock(node);
    } finally {
      _nameScope = outerScope;
    }
    return null;
  }

  Object visitCatchClause(CatchClause node) {
    SimpleIdentifier exception = node.exceptionParameter;
    if (exception != null) {
      Scope outerScope = _nameScope;
      try {
        _nameScope = new EnclosedScope(_nameScope);
        _nameScope.define(exception.staticElement);
        SimpleIdentifier stackTrace = node.stackTraceParameter;
        if (stackTrace != null) {
          _nameScope.define(stackTrace.staticElement);
        }
        super.visitCatchClause(node);
      } finally {
        _nameScope = outerScope;
      }
    } else {
      super.visitCatchClause(node);
    }
    return null;
  }

  Object visitClassDeclaration(ClassDeclaration node) {
    Scope outerScope = _nameScope;
    try {
      _nameScope = new ClassScope(_nameScope, node.element);
      visitClassDeclarationInScope(node);
    } finally {
      _nameScope = outerScope;
    }
    return null;
  }

  Object visitClassTypeAlias(ClassTypeAlias node) {
    Scope outerScope = _nameScope;
    try {
      _nameScope = new ClassScope(_nameScope, node.element);
      super.visitClassTypeAlias(node);
    } finally {
      _nameScope = outerScope;
    }
    return null;
  }

  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    Scope outerScope = _nameScope;
    try {
      _nameScope = new FunctionScope(_nameScope, node.element);
      super.visitConstructorDeclaration(node);
    } finally {
      _nameScope = outerScope;
    }
    return null;
  }

  Object visitDeclaredIdentifier(DeclaredIdentifier node) {
    VariableElement element = node.element;
    if (element != null) {
      _nameScope.define(element);
    }
    super.visitDeclaredIdentifier(node);
    return null;
  }

  Object visitDoStatement(DoStatement node) {
    LabelScope outerLabelScope = _labelScope;
    try {
      _labelScope = new LabelScope.con1(_labelScope, false, false);
      visitStatementInScope(node.body);
      safelyVisit(node.condition);
    } finally {
      _labelScope = outerLabelScope;
    }
    return null;
  }

  Object visitForEachStatement(ForEachStatement node) {
    Scope outerNameScope = _nameScope;
    LabelScope outerLabelScope = _labelScope;
    try {
      _nameScope = new EnclosedScope(_nameScope);
      _labelScope = new LabelScope.con1(outerLabelScope, false, false);
      visitForEachStatementInScope(node);
    } finally {
      _labelScope = outerLabelScope;
      _nameScope = outerNameScope;
    }
    return null;
  }

  Object visitFormalParameterList(FormalParameterList node) {
    super.visitFormalParameterList(node);
    // We finished resolving function signature, now include formal parameters scope.
    if (_nameScope is FunctionScope) {
      (_nameScope as FunctionScope).defineParameters();
    }
    if (_nameScope is FunctionTypeScope) {
      (_nameScope as FunctionTypeScope).defineParameters();
    }
    return null;
  }

  Object visitForStatement(ForStatement node) {
    Scope outerNameScope = _nameScope;
    LabelScope outerLabelScope = _labelScope;
    try {
      _nameScope = new EnclosedScope(_nameScope);
      _labelScope = new LabelScope.con1(outerLabelScope, false, false);
      visitForStatementInScope(node);
    } finally {
      _labelScope = outerLabelScope;
      _nameScope = outerNameScope;
    }
    return null;
  }

  Object visitFunctionDeclaration(FunctionDeclaration node) {
    ExecutableElement function = node.element;
    Scope outerScope = _nameScope;
    try {
      _nameScope = new FunctionScope(_nameScope, function);
      super.visitFunctionDeclaration(node);
    } finally {
      _nameScope = outerScope;
    }
    if (function.enclosingElement is! CompilationUnitElement) {
      _nameScope.define(function);
    }
    return null;
  }

  Object visitFunctionExpression(FunctionExpression node) {
    if (node.parent is FunctionDeclaration) {
      // We have already created a function scope and don't need to do so again.
      super.visitFunctionExpression(node);
    } else {
      Scope outerScope = _nameScope;
      try {
        ExecutableElement functionElement = node.element;
        if (functionElement == null) {
        } else {
          _nameScope = new FunctionScope(_nameScope, functionElement);
        }
        super.visitFunctionExpression(node);
      } finally {
        _nameScope = outerScope;
      }
    }
    return null;
  }

  Object visitFunctionTypeAlias(FunctionTypeAlias node) {
    Scope outerScope = _nameScope;
    try {
      _nameScope = new FunctionTypeScope(_nameScope, node.element);
      super.visitFunctionTypeAlias(node);
    } finally {
      _nameScope = outerScope;
    }
    return null;
  }

  Object visitIfStatement(IfStatement node) {
    safelyVisit(node.condition);
    visitStatementInScope(node.thenStatement);
    visitStatementInScope(node.elseStatement);
    return null;
  }

  Object visitLabeledStatement(LabeledStatement node) {
    LabelScope outerScope = addScopesFor(node.labels);
    try {
      super.visitLabeledStatement(node);
    } finally {
      _labelScope = outerScope;
    }
    return null;
  }

  Object visitMethodDeclaration(MethodDeclaration node) {
    Scope outerScope = _nameScope;
    try {
      _nameScope = new FunctionScope(_nameScope, node.element);
      super.visitMethodDeclaration(node);
    } finally {
      _nameScope = outerScope;
    }
    return null;
  }

  Object visitSwitchCase(SwitchCase node) {
    node.expression.accept(this);
    Scope outerNameScope = _nameScope;
    try {
      _nameScope = new EnclosedScope(_nameScope);
      node.statements.accept(this);
    } finally {
      _nameScope = outerNameScope;
    }
    return null;
  }

  Object visitSwitchDefault(SwitchDefault node) {
    Scope outerNameScope = _nameScope;
    try {
      _nameScope = new EnclosedScope(_nameScope);
      node.statements.accept(this);
    } finally {
      _nameScope = outerNameScope;
    }
    return null;
  }

  Object visitSwitchStatement(SwitchStatement node) {
    LabelScope outerScope = _labelScope;
    try {
      _labelScope = new LabelScope.con1(outerScope, true, false);
      for (SwitchMember member in node.members) {
        for (Label label in member.labels) {
          SimpleIdentifier labelName = label.label;
          LabelElement labelElement = labelName.staticElement as LabelElement;
          _labelScope = new LabelScope.con2(_labelScope, labelName.name, labelElement);
        }
      }
      super.visitSwitchStatement(node);
    } finally {
      _labelScope = outerScope;
    }
    return null;
  }

  Object visitVariableDeclaration(VariableDeclaration node) {
    super.visitVariableDeclaration(node);
    if (node.parent.parent is! TopLevelVariableDeclaration && node.parent.parent is! FieldDeclaration) {
      VariableElement element = node.element;
      if (element != null) {
        _nameScope.define(element);
      }
    }
    return null;
  }

  Object visitWhileStatement(WhileStatement node) {
    LabelScope outerScope = _labelScope;
    try {
      _labelScope = new LabelScope.con1(outerScope, false, false);
      safelyVisit(node.condition);
      visitStatementInScope(node.body);
    } finally {
      _labelScope = outerScope;
    }
    return null;
  }

  /**
   * Return the label scope in which the current node is being resolved.
   *
   * @return the label scope in which the current node is being resolved
   */
  LabelScope get labelScope => _labelScope;

  /**
   * Return the name scope in which the current node is being resolved.
   *
   * @return the name scope in which the current node is being resolved
   */
  Scope get nameScope => _nameScope;

  /**
   * Report an error with the given error code and arguments.
   *
   * @param errorCode the error code of the error to be reported
   * @param node the node specifying the location of the error
   * @param arguments the arguments to the error, used to compose the error message
   */
  void reportErrorForNode(ErrorCode errorCode, AstNode node, List<Object> arguments) {
    _errorListener.onError(new AnalysisError.con2(source, node.offset, node.length, errorCode, arguments));
  }

  /**
   * Report an error with the given error code and arguments.
   *
   * @param errorCode the error code of the error to be reported
   * @param offset the offset of the location of the error
   * @param length the length of the location of the error
   * @param arguments the arguments to the error, used to compose the error message
   */
  void reportErrorForOffset(ErrorCode errorCode, int offset, int length, List<Object> arguments) {
    _errorListener.onError(new AnalysisError.con2(source, offset, length, errorCode, arguments));
  }

  /**
   * Report an error with the given error code and arguments.
   *
   * @param errorCode the error code of the error to be reported
   * @param token the token specifying the location of the error
   * @param arguments the arguments to the error, used to compose the error message
   */
  void reportErrorForToken(ErrorCode errorCode, sc.Token token, List<Object> arguments) {
    _errorListener.onError(new AnalysisError.con2(source, token.offset, token.length, errorCode, arguments));
  }

  /**
   * Visit the given AST node if it is not null.
   *
   * @param node the node to be visited
   */
  void safelyVisit(AstNode node) {
    if (node != null) {
      node.accept(this);
    }
  }

  void visitClassDeclarationInScope(ClassDeclaration node) {
    super.visitClassDeclaration(node);
  }

  /**
   * Visit the given statement after it's scope has been created. This replaces the normal call to
   * the inherited visit method so that ResolverVisitor can intervene when type propagation is
   * enabled.
   *
   * @param node the statement to be visited
   */
  void visitForEachStatementInScope(ForEachStatement node) {
    //
    // We visit the iterator before the loop variable because the loop variable cannot be in scope
    // while visiting the iterator.
    //
    safelyVisit(node.identifier);
    safelyVisit(node.iterator);
    safelyVisit(node.loopVariable);
    visitStatementInScope(node.body);
  }

  /**
   * Visit the given statement after it's scope has been created. This replaces the normal call to
   * the inherited visit method so that ResolverVisitor can intervene when type propagation is
   * enabled.
   *
   * @param node the statement to be visited
   */
  void visitForStatementInScope(ForStatement node) {
    safelyVisit(node.variables);
    safelyVisit(node.initialization);
    safelyVisit(node.condition);
    node.updaters.accept(this);
    visitStatementInScope(node.body);
  }

  /**
   * Visit the given statement after it's scope has been created. This is used by ResolverVisitor to
   * correctly visit the 'then' and 'else' statements of an 'if' statement.
   *
   * @param node the statement to be visited
   */
  void visitStatementInScope(Statement node) {
    if (node is Block) {
      // Don't create a scope around a block because the block will create it's own scope.
      visitBlock(node);
    } else if (node != null) {
      Scope outerNameScope = _nameScope;
      try {
        _nameScope = new EnclosedScope(_nameScope);
        node.accept(this);
      } finally {
        _nameScope = outerNameScope;
      }
    }
  }

  /**
   * Add scopes for each of the given labels.
   *
   * @param labels the labels for which new scopes are to be added
   * @return the scope that was in effect before the new scopes were added
   */
  LabelScope addScopesFor(NodeList<Label> labels) {
    LabelScope outerScope = _labelScope;
    for (Label label in labels) {
      SimpleIdentifier labelNameNode = label.label;
      String labelName = labelNameNode.name;
      LabelElement labelElement = labelNameNode.staticElement as LabelElement;
      _labelScope = new LabelScope.con2(_labelScope, labelName, labelElement);
    }
    return outerScope;
  }

  /**
   * Marks the local declarations of the given [Block] hidden in the enclosing scope.
   * According to the scoping rules name is hidden if block defines it, but name is defined after
   * its declaration statement.
   */
  void hideNamesDefinedInBlock(EnclosedScope scope, Block block) {
    NodeList<Statement> statements = block.statements;
    int statementCount = statements.length;
    for (int i = 0; i < statementCount; i++) {
      Statement statement = statements[i];
      if (statement is VariableDeclarationStatement) {
        VariableDeclarationStatement vds = statement;
        NodeList<VariableDeclaration> variables = vds.variables.variables;
        int variableCount = variables.length;
        for (int j = 0; j < variableCount; j++) {
          scope.hide(variables[j].element);
        }
      } else if (statement is FunctionDeclarationStatement) {
        FunctionDeclarationStatement fds = statement;
        scope.hide(fds.functionDeclaration.element);
      }
    }
  }
}

/**
 * Instances of the class `StaticTypeAnalyzer` perform two type-related tasks. First, they
 * compute the static type of every expression. Second, they look for any static type errors or
 * warnings that might need to be generated. The requirements for the type analyzer are:
 * <ol>
 * * Every element that refers to types should be fully populated.
 * * Every node representing an expression should be resolved to the Type of the expression.
 * </ol>
 */
class StaticTypeAnalyzer extends SimpleAstVisitor<Object> {
  /**
   * Create a table mapping HTML tag names to the names of the classes (in 'dart:html') that
   * implement those tags.
   *
   * @return the table that was created
   */
  static Map<String, String> createHtmlTagToClassMap() {
    Map<String, String> map = new Map<String, String>();
    map["a"] = "AnchorElement";
    map["area"] = "AreaElement";
    map["br"] = "BRElement";
    map["base"] = "BaseElement";
    map["body"] = "BodyElement";
    map["button"] = "ButtonElement";
    map["canvas"] = "CanvasElement";
    map["content"] = "ContentElement";
    map["dl"] = "DListElement";
    map["datalist"] = "DataListElement";
    map["details"] = "DetailsElement";
    map["div"] = "DivElement";
    map["embed"] = "EmbedElement";
    map["fieldset"] = "FieldSetElement";
    map["form"] = "FormElement";
    map["hr"] = "HRElement";
    map["head"] = "HeadElement";
    map["h1"] = "HeadingElement";
    map["h2"] = "HeadingElement";
    map["h3"] = "HeadingElement";
    map["h4"] = "HeadingElement";
    map["h5"] = "HeadingElement";
    map["h6"] = "HeadingElement";
    map["html"] = "HtmlElement";
    map["iframe"] = "IFrameElement";
    map["img"] = "ImageElement";
    map["input"] = "InputElement";
    map["keygen"] = "KeygenElement";
    map["li"] = "LIElement";
    map["label"] = "LabelElement";
    map["legend"] = "LegendElement";
    map["link"] = "LinkElement";
    map["map"] = "MapElement";
    map["menu"] = "MenuElement";
    map["meter"] = "MeterElement";
    map["ol"] = "OListElement";
    map["object"] = "ObjectElement";
    map["optgroup"] = "OptGroupElement";
    map["output"] = "OutputElement";
    map["p"] = "ParagraphElement";
    map["param"] = "ParamElement";
    map["pre"] = "PreElement";
    map["progress"] = "ProgressElement";
    map["script"] = "ScriptElement";
    map["select"] = "SelectElement";
    map["source"] = "SourceElement";
    map["span"] = "SpanElement";
    map["style"] = "StyleElement";
    map["caption"] = "TableCaptionElement";
    map["td"] = "TableCellElement";
    map["col"] = "TableColElement";
    map["table"] = "TableElement";
    map["tr"] = "TableRowElement";
    map["textarea"] = "TextAreaElement";
    map["title"] = "TitleElement";
    map["track"] = "TrackElement";
    map["ul"] = "UListElement";
    map["video"] = "VideoElement";
    return map;
  }

  /**
   * The resolver driving the resolution and type analysis.
   */
  ResolverVisitor _resolver;

  /**
   * The object providing access to the types defined by the language.
   */
  TypeProvider _typeProvider;

  /**
   * The type representing the type 'dynamic'.
   */
  Type2 _dynamicType;

  /**
   * The type representing the class containing the nodes being analyzed, or `null` if the
   * nodes are not within a class.
   */
  InterfaceType _thisType;

  /**
   * The object keeping track of which elements have had their types overridden.
   */
  TypeOverrideManager _overrideManager;

  /**
   * The object keeping track of which elements have had their types promoted.
   */
  TypePromotionManager _promoteManager;

  /**
   * A table mapping [ExecutableElement]s to their propagated return types.
   */
  Map<ExecutableElement, Type2> _propagatedReturnTypes = new Map<ExecutableElement, Type2>();

  /**
   * A table mapping HTML tag names to the names of the classes (in 'dart:html') that implement
   * those tags.
   */
  static Map<String, String> _HTML_ELEMENT_TO_CLASS_MAP = createHtmlTagToClassMap();

  /**
   * Initialize a newly created type analyzer.
   *
   * @param resolver the resolver driving this participant
   */
  StaticTypeAnalyzer(ResolverVisitor resolver) {
    this._resolver = resolver;
    _typeProvider = resolver.typeProvider;
    _dynamicType = _typeProvider.dynamicType;
    _overrideManager = resolver.overrideManager;
    _promoteManager = resolver.promoteManager;
  }

  /**
   * Set the type of the class being analyzed to the given type.
   *
   * @param thisType the type representing the class containing the nodes being analyzed
   */
  void set thisType(InterfaceType thisType) {
    this._thisType = thisType;
  }

  /**
   * The Dart Language Specification, 12.5: <blockquote>The static type of a string literal is
   * `String`.</blockquote>
   */
  Object visitAdjacentStrings(AdjacentStrings node) {
    recordStaticType(node, _typeProvider.stringType);
    return null;
  }

  /**
   * The Dart Language Specification, 12.33: <blockquote>The static type of an argument definition
   * test is `bool`.</blockquote>
   */
  Object visitArgumentDefinitionTest(ArgumentDefinitionTest node) {
    recordStaticType(node, _typeProvider.boolType);
    return null;
  }

  /**
   * The Dart Language Specification, 12.32: <blockquote>... the cast expression <i>e as T</i> ...
   *
   * It is a static warning if <i>T</i> does not denote a type available in the current lexical
   * scope.
   *
   * The static type of a cast expression <i>e as T</i> is <i>T</i>.</blockquote>
   */
  Object visitAsExpression(AsExpression node) {
    recordStaticType(node, getType(node.type));
    return null;
  }

  /**
   * The Dart Language Specification, 12.18: <blockquote>... an assignment <i>a</i> of the form <i>v
   * = e</i> ...
   *
   * It is a static type warning if the static type of <i>e</i> may not be assigned to the static
   * type of <i>v</i>.
   *
   * The static type of the expression <i>v = e</i> is the static type of <i>e</i>.
   *
   * ... an assignment of the form <i>C.v = e</i> ...
   *
   * It is a static type warning if the static type of <i>e</i> may not be assigned to the static
   * type of <i>C.v</i>.
   *
   * The static type of the expression <i>C.v = e</i> is the static type of <i>e</i>.
   *
   * ... an assignment of the form <i>e<sub>1</sub>.v = e<sub>2</sub></i> ...
   *
   * Let <i>T</i> be the static type of <i>e<sub>1</sub></i>. It is a static type warning if
   * <i>T</i> does not have an accessible instance setter named <i>v=</i>. It is a static type
   * warning if the static type of <i>e<sub>2</sub></i> may not be assigned to <i>T</i>.
   *
   * The static type of the expression <i>e<sub>1</sub>.v = e<sub>2</sub></i> is the static type of
   * <i>e<sub>2</sub></i>.
   *
   * ... an assignment of the form <i>e<sub>1</sub>[e<sub>2</sub>] = e<sub>3</sub></i> ...
   *
   * The static type of the expression <i>e<sub>1</sub>[e<sub>2</sub>] = e<sub>3</sub></i> is the
   * static type of <i>e<sub>3</sub></i>.
   *
   * A compound assignment of the form <i>v op= e</i> is equivalent to <i>v = v op e</i>. A compound
   * assignment of the form <i>C.v op= e</i> is equivalent to <i>C.v = C.v op e</i>. A compound
   * assignment of the form <i>e<sub>1</sub>.v op= e<sub>2</sub></i> is equivalent to <i>((x) => x.v
   * = x.v op e<sub>2</sub>)(e<sub>1</sub>)</i> where <i>x</i> is a variable that is not used in
   * <i>e<sub>2</sub></i>. A compound assignment of the form <i>e<sub>1</sub>[e<sub>2</sub>] op=
   * e<sub>3</sub></i> is equivalent to <i>((a, i) => a[i] = a[i] op e<sub>3</sub>)(e<sub>1</sub>,
   * e<sub>2</sub>)</i> where <i>a</i> and <i>i</i> are a variables that are not used in
   * <i>e<sub>3</sub></i>.</blockquote>
   */
  Object visitAssignmentExpression(AssignmentExpression node) {
    sc.TokenType operator = node.operator.type;
    if (identical(operator, sc.TokenType.EQ)) {
      Expression rightHandSide = node.rightHandSide;
      Type2 staticType = getStaticType(rightHandSide);
      recordStaticType(node, staticType);
      Type2 overrideType = staticType;
      Type2 propagatedType = rightHandSide.propagatedType;
      if (propagatedType != null) {
        if (propagatedType.isMoreSpecificThan(staticType)) {
          recordPropagatedType(node, propagatedType);
        }
        overrideType = propagatedType;
      }
      _resolver.override(node.leftHandSide, overrideType);
    } else {
      ExecutableElement staticMethodElement = node.staticElement;
      Type2 staticType = computeStaticReturnType(staticMethodElement);
      recordStaticType(node, staticType);
      MethodElement propagatedMethodElement = node.propagatedElement;
      if (propagatedMethodElement != staticMethodElement) {
        Type2 propagatedType = computeStaticReturnType(propagatedMethodElement);
        if (propagatedType != null && propagatedType.isMoreSpecificThan(staticType)) {
          recordPropagatedType(node, propagatedType);
        }
      }
    }
    return null;
  }

  /**
   * The Dart Language Specification, 12.20: <blockquote>The static type of a logical boolean
   * expression is `bool`.</blockquote>
   *
   * The Dart Language Specification, 12.21:<blockquote>A bitwise expression of the form
   * <i>e<sub>1</sub> op e<sub>2</sub></i> is equivalent to the method invocation
   * <i>e<sub>1</sub>.op(e<sub>2</sub>)</i>. A bitwise expression of the form <i>super op
   * e<sub>2</sub></i> is equivalent to the method invocation
   * <i>super.op(e<sub>2</sub>)</i>.</blockquote>
   *
   * The Dart Language Specification, 12.22: <blockquote>The static type of an equality expression
   * is `bool`.</blockquote>
   *
   * The Dart Language Specification, 12.23: <blockquote>A relational expression of the form
   * <i>e<sub>1</sub> op e<sub>2</sub></i> is equivalent to the method invocation
   * <i>e<sub>1</sub>.op(e<sub>2</sub>)</i>. A relational expression of the form <i>super op
   * e<sub>2</sub></i> is equivalent to the method invocation
   * <i>super.op(e<sub>2</sub>)</i>.</blockquote>
   *
   * The Dart Language Specification, 12.24: <blockquote>A shift expression of the form
   * <i>e<sub>1</sub> op e<sub>2</sub></i> is equivalent to the method invocation
   * <i>e<sub>1</sub>.op(e<sub>2</sub>)</i>. A shift expression of the form <i>super op
   * e<sub>2</sub></i> is equivalent to the method invocation
   * <i>super.op(e<sub>2</sub>)</i>.</blockquote>
   *
   * The Dart Language Specification, 12.25: <blockquote>An additive expression of the form
   * <i>e<sub>1</sub> op e<sub>2</sub></i> is equivalent to the method invocation
   * <i>e<sub>1</sub>.op(e<sub>2</sub>)</i>. An additive expression of the form <i>super op
   * e<sub>2</sub></i> is equivalent to the method invocation
   * <i>super.op(e<sub>2</sub>)</i>.</blockquote>
   *
   * The Dart Language Specification, 12.26: <blockquote>A multiplicative expression of the form
   * <i>e<sub>1</sub> op e<sub>2</sub></i> is equivalent to the method invocation
   * <i>e<sub>1</sub>.op(e<sub>2</sub>)</i>. A multiplicative expression of the form <i>super op
   * e<sub>2</sub></i> is equivalent to the method invocation
   * <i>super.op(e<sub>2</sub>)</i>.</blockquote>
   */
  Object visitBinaryExpression(BinaryExpression node) {
    ExecutableElement staticMethodElement = node.staticElement;
    Type2 staticType = computeStaticReturnType(staticMethodElement);
    staticType = refineBinaryExpressionType(node, staticType);
    recordStaticType(node, staticType);
    MethodElement propagatedMethodElement = node.propagatedElement;
    if (propagatedMethodElement != staticMethodElement) {
      Type2 propagatedType = computeStaticReturnType(propagatedMethodElement);
      if (propagatedType != null && propagatedType.isMoreSpecificThan(staticType)) {
        recordPropagatedType(node, propagatedType);
      }
    }
    return null;
  }

  /**
   * The Dart Language Specification, 12.4: <blockquote>The static type of a boolean literal is
   * bool.</blockquote>
   */
  Object visitBooleanLiteral(BooleanLiteral node) {
    recordStaticType(node, _typeProvider.boolType);
    return null;
  }

  /**
   * The Dart Language Specification, 12.15.2: <blockquote>A cascaded method invocation expression
   * of the form <i>e..suffix</i> is equivalent to the expression <i>(t) {t.suffix; return
   * t;}(e)</i>.</blockquote>
   */
  Object visitCascadeExpression(CascadeExpression node) {
    recordStaticType(node, getStaticType(node.target));
    recordPropagatedType(node, node.target.propagatedType);
    return null;
  }

  /**
   * The Dart Language Specification, 12.19: <blockquote> ... a conditional expression <i>c</i> of
   * the form <i>e<sub>1</sub> ? e<sub>2</sub> : e<sub>3</sub></i> ...
   *
   * It is a static type warning if the type of e<sub>1</sub> may not be assigned to `bool`.
   *
   * The static type of <i>c</i> is the least upper bound of the static type of <i>e<sub>2</sub></i>
   * and the static type of <i>e<sub>3</sub></i>.</blockquote>
   */
  Object visitConditionalExpression(ConditionalExpression node) {
    Type2 staticThenType = getStaticType(node.thenExpression);
    Type2 staticElseType = getStaticType(node.elseExpression);
    if (staticThenType == null) {
      // TODO(brianwilkerson) Determine whether this can still happen.
      staticThenType = _dynamicType;
    }
    if (staticElseType == null) {
      // TODO(brianwilkerson) Determine whether this can still happen.
      staticElseType = _dynamicType;
    }
    Type2 staticType = staticThenType.getLeastUpperBound(staticElseType);
    if (staticType == null) {
      staticType = _dynamicType;
    }
    recordStaticType(node, staticType);
    Type2 propagatedThenType = node.thenExpression.propagatedType;
    Type2 propagatedElseType = node.elseExpression.propagatedType;
    if (propagatedThenType != null || propagatedElseType != null) {
      if (propagatedThenType == null) {
        propagatedThenType = staticThenType;
      }
      if (propagatedElseType == null) {
        propagatedElseType = staticElseType;
      }
      Type2 propagatedType = propagatedThenType.getLeastUpperBound(propagatedElseType);
      if (propagatedType != null && propagatedType.isMoreSpecificThan(staticType)) {
        recordPropagatedType(node, propagatedType);
      }
    }
    return null;
  }

  /**
   * The Dart Language Specification, 12.3: <blockquote>The static type of a literal double is
   * double.</blockquote>
   */
  Object visitDoubleLiteral(DoubleLiteral node) {
    recordStaticType(node, _typeProvider.doubleType);
    return null;
  }

  Object visitFunctionDeclaration(FunctionDeclaration node) {
    FunctionExpression function = node.functionExpression;
    ExecutableElementImpl functionElement = node.element as ExecutableElementImpl;
    functionElement.returnType = computeStaticReturnTypeOfFunctionDeclaration(node);
    recordPropagatedTypeOfFunction(functionElement, function.body);
    recordStaticType(function, functionElement.type);
    return null;
  }

  /**
   * The Dart Language Specification, 12.9: <blockquote>The static type of a function literal of the
   * form <i>(T<sub>1</sub> a<sub>1</sub>, &hellip;, T<sub>n</sub> a<sub>n</sub>, [T<sub>n+1</sub>
   * x<sub>n+1</sub> = d1, &hellip;, T<sub>n+k</sub> x<sub>n+k</sub> = dk]) => e</i> is
   * <i>(T<sub>1</sub>, &hellip;, Tn, [T<sub>n+1</sub> x<sub>n+1</sub>, &hellip;, T<sub>n+k</sub>
   * x<sub>n+k</sub>]) &rarr; T<sub>0</sub></i>, where <i>T<sub>0</sub></i> is the static type of
   * <i>e</i>. In any case where <i>T<sub>i</sub>, 1 &lt;= i &lt;= n</i>, is not specified, it is
   * considered to have been specified as dynamic.
   *
   * The static type of a function literal of the form <i>(T<sub>1</sub> a<sub>1</sub>, &hellip;,
   * T<sub>n</sub> a<sub>n</sub>, {T<sub>n+1</sub> x<sub>n+1</sub> : d1, &hellip;, T<sub>n+k</sub>
   * x<sub>n+k</sub> : dk}) => e</i> is <i>(T<sub>1</sub>, &hellip;, T<sub>n</sub>, {T<sub>n+1</sub>
   * x<sub>n+1</sub>, &hellip;, T<sub>n+k</sub> x<sub>n+k</sub>}) &rarr; T<sub>0</sub></i>, where
   * <i>T<sub>0</sub></i> is the static type of <i>e</i>. In any case where <i>T<sub>i</sub>, 1
   * &lt;= i &lt;= n</i>, is not specified, it is considered to have been specified as dynamic.
   *
   * The static type of a function literal of the form <i>(T<sub>1</sub> a<sub>1</sub>, &hellip;,
   * T<sub>n</sub> a<sub>n</sub>, [T<sub>n+1</sub> x<sub>n+1</sub> = d1, &hellip;, T<sub>n+k</sub>
   * x<sub>n+k</sub> = dk]) {s}</i> is <i>(T<sub>1</sub>, &hellip;, T<sub>n</sub>, [T<sub>n+1</sub>
   * x<sub>n+1</sub>, &hellip;, T<sub>n+k</sub> x<sub>n+k</sub>]) &rarr; dynamic</i>. In any case
   * where <i>T<sub>i</sub>, 1 &lt;= i &lt;= n</i>, is not specified, it is considered to have been
   * specified as dynamic.
   *
   * The static type of a function literal of the form <i>(T<sub>1</sub> a<sub>1</sub>, &hellip;,
   * T<sub>n</sub> a<sub>n</sub>, {T<sub>n+1</sub> x<sub>n+1</sub> : d1, &hellip;, T<sub>n+k</sub>
   * x<sub>n+k</sub> : dk}) {s}</i> is <i>(T<sub>1</sub>, &hellip;, T<sub>n</sub>, {T<sub>n+1</sub>
   * x<sub>n+1</sub>, &hellip;, T<sub>n+k</sub> x<sub>n+k</sub>}) &rarr; dynamic</i>. In any case
   * where <i>T<sub>i</sub>, 1 &lt;= i &lt;= n</i>, is not specified, it is considered to have been
   * specified as dynamic.</blockquote>
   */
  Object visitFunctionExpression(FunctionExpression node) {
    if (node.parent is FunctionDeclaration) {
      // The function type will be resolved and set when we visit the parent node.
      return null;
    }
    ExecutableElementImpl functionElement = node.element as ExecutableElementImpl;
    functionElement.returnType = computeStaticReturnTypeOfFunctionExpression(node);
    recordPropagatedTypeOfFunction(functionElement, node.body);
    recordStaticType(node, node.element.type);
    return null;
  }

  /**
   * The Dart Language Specification, 12.14.4: <blockquote>A function expression invocation <i>i</i>
   * has the form <i>e<sub>f</sub>(a<sub>1</sub>, &hellip;, a<sub>n</sub>, x<sub>n+1</sub>:
   * a<sub>n+1</sub>, &hellip;, x<sub>n+k</sub>: a<sub>n+k</sub>)</i>, where <i>e<sub>f</sub></i> is
   * an expression.
   *
   * It is a static type warning if the static type <i>F</i> of <i>e<sub>f</sub></i> may not be
   * assigned to a function type.
   *
   * If <i>F</i> is not a function type, the static type of <i>i</i> is dynamic. Otherwise the
   * static type of <i>i</i> is the declared return type of <i>F</i>.</blockquote>
   */
  Object visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    ExecutableElement staticMethodElement = node.staticElement;
    // Record static return type of the static element.
    Type2 staticStaticType = computeStaticReturnType(staticMethodElement);
    recordStaticType(node, staticStaticType);
    // Record propagated return type of the static element.
    Type2 staticPropagatedType = computePropagatedReturnType(staticMethodElement);
    if (staticPropagatedType != null && (staticStaticType == null || staticPropagatedType.isMoreSpecificThan(staticStaticType))) {
      recordPropagatedType(node, staticPropagatedType);
    }
    ExecutableElement propagatedMethodElement = node.propagatedElement;
    if (propagatedMethodElement != staticMethodElement) {
      // Record static return type of the propagated element.
      Type2 propagatedStaticType = computeStaticReturnType(propagatedMethodElement);
      if (propagatedStaticType != null && (staticStaticType == null || propagatedStaticType.isMoreSpecificThan(staticStaticType)) && (staticPropagatedType == null || propagatedStaticType.isMoreSpecificThan(staticPropagatedType))) {
        recordPropagatedType(node, propagatedStaticType);
      }
      // Record propagated return type of the propagated element.
      Type2 propagatedPropagatedType = computePropagatedReturnType(propagatedMethodElement);
      if (propagatedPropagatedType != null && (staticStaticType == null || propagatedPropagatedType.isMoreSpecificThan(staticStaticType)) && (staticPropagatedType == null || propagatedPropagatedType.isMoreSpecificThan(staticPropagatedType)) && (propagatedStaticType == null || propagatedPropagatedType.isMoreSpecificThan(propagatedStaticType))) {
        recordPropagatedType(node, propagatedPropagatedType);
      }
    }
    return null;
  }

  /**
   * The Dart Language Specification, 12.29: <blockquote>An assignable expression of the form
   * <i>e<sub>1</sub>[e<sub>2</sub>]</i> is evaluated as a method invocation of the operator method
   * <i>[]</i> on <i>e<sub>1</sub></i> with argument <i>e<sub>2</sub></i>.</blockquote>
   */
  Object visitIndexExpression(IndexExpression node) {
    if (node.inSetterContext()) {
      ExecutableElement staticMethodElement = node.staticElement;
      Type2 staticType = computeArgumentType(staticMethodElement);
      recordStaticType(node, staticType);
      MethodElement propagatedMethodElement = node.propagatedElement;
      if (propagatedMethodElement != staticMethodElement) {
        Type2 propagatedType = computeArgumentType(propagatedMethodElement);
        if (propagatedType != null && propagatedType.isMoreSpecificThan(staticType)) {
          recordPropagatedType(node, propagatedType);
        }
      }
    } else {
      ExecutableElement staticMethodElement = node.staticElement;
      Type2 staticType = computeStaticReturnType(staticMethodElement);
      recordStaticType(node, staticType);
      MethodElement propagatedMethodElement = node.propagatedElement;
      if (propagatedMethodElement != staticMethodElement) {
        Type2 propagatedType = computeStaticReturnType(propagatedMethodElement);
        if (propagatedType != null && propagatedType.isMoreSpecificThan(staticType)) {
          recordPropagatedType(node, propagatedType);
        }
      }
    }
    return null;
  }

  /**
   * The Dart Language Specification, 12.11.1: <blockquote>The static type of a new expression of
   * either the form <i>new T.id(a<sub>1</sub>, &hellip;, a<sub>n</sub>)</i> or the form <i>new
   * T(a<sub>1</sub>, &hellip;, a<sub>n</sub>)</i> is <i>T</i>.</blockquote>
   *
   * The Dart Language Specification, 12.11.2: <blockquote>The static type of a constant object
   * expression of either the form <i>const T.id(a<sub>1</sub>, &hellip;, a<sub>n</sub>)</i> or the
   * form <i>const T(a<sub>1</sub>, &hellip;, a<sub>n</sub>)</i> is <i>T</i>. </blockquote>
   */
  Object visitInstanceCreationExpression(InstanceCreationExpression node) {
    recordStaticType(node, node.constructorName.type.type);
    ConstructorElement element = node.staticElement;
    if (element != null && "Element" == element.enclosingElement.name) {
      LibraryElement library = element.library;
      if (isHtmlLibrary(library)) {
        String constructorName = element.name;
        if ("tag" == constructorName) {
          Type2 returnType = getFirstArgumentAsTypeWithMap(library, node.argumentList, _HTML_ELEMENT_TO_CLASS_MAP);
          if (returnType != null) {
            recordPropagatedType(node, returnType);
          }
        } else {
          Type2 returnType = getElementNameAsType(library, constructorName, _HTML_ELEMENT_TO_CLASS_MAP);
          if (returnType != null) {
            recordPropagatedType(node, returnType);
          }
        }
      }
    }
    return null;
  }

  /**
   * The Dart Language Specification, 12.3: <blockquote>The static type of an integer literal is
   * `int`.</blockquote>
   */
  Object visitIntegerLiteral(IntegerLiteral node) {
    recordStaticType(node, _typeProvider.intType);
    return null;
  }

  /**
   * The Dart Language Specification, 12.31: <blockquote>It is a static warning if <i>T</i> does not
   * denote a type available in the current lexical scope.
   *
   * The static type of an is-expression is `bool`.</blockquote>
   */
  Object visitIsExpression(IsExpression node) {
    recordStaticType(node, _typeProvider.boolType);
    return null;
  }

  /**
   * The Dart Language Specification, 12.6: <blockquote>The static type of a list literal of the
   * form <i><b>const</b> &lt;E&gt;[e<sub>1</sub>, &hellip;, e<sub>n</sub>]</i> or the form
   * <i>&lt;E&gt;[e<sub>1</sub>, &hellip;, e<sub>n</sub>]</i> is `List&lt;E&gt;`. The static
   * type a list literal of the form <i><b>const</b> [e<sub>1</sub>, &hellip;, e<sub>n</sub>]</i> or
   * the form <i>[e<sub>1</sub>, &hellip;, e<sub>n</sub>]</i> is `List&lt;dynamic&gt;`
   * .</blockquote>
   */
  Object visitListLiteral(ListLiteral node) {
    Type2 staticType = _dynamicType;
    TypeArgumentList typeArguments = node.typeArguments;
    if (typeArguments != null) {
      NodeList<TypeName> arguments = typeArguments.arguments;
      if (arguments != null && arguments.length == 1) {
        TypeName argumentTypeName = arguments[0];
        Type2 argumentType = getType(argumentTypeName);
        if (argumentType != null) {
          staticType = argumentType;
        }
      }
    }
    recordStaticType(node, _typeProvider.listType.substitute4(<Type2> [staticType]));
    NodeList<Expression> elements = node.elements;
    int count = elements.length;
    if (count > 0) {
      Type2 propagatedType = elements[0].bestType;
      for (int i = 1; i < count; i++) {
        Type2 elementType = elements[i].bestType;
        if (propagatedType != elementType) {
          propagatedType = _dynamicType;
        } else {
          propagatedType = propagatedType.getLeastUpperBound(elementType);
          if (propagatedType == null) {
            propagatedType = _dynamicType;
          }
        }
      }
      if (propagatedType.isMoreSpecificThan(staticType)) {
        recordPropagatedType(node, _typeProvider.listType.substitute4(<Type2> [propagatedType]));
      }
    }
    return null;
  }

  /**
   * The Dart Language Specification, 12.7: <blockquote>The static type of a map literal of the form
   * <i><b>const</b> &lt;String, V&gt; {k<sub>1</sub>:e<sub>1</sub>, &hellip;,
   * k<sub>n</sub>:e<sub>n</sub>}</i> or the form <i>&lt;String, V&gt; {k<sub>1</sub>:e<sub>1</sub>,
   * &hellip;, k<sub>n</sub>:e<sub>n</sub>}</i> is `Map&lt;String, V&gt;`. The static type a
   * map literal of the form <i><b>const</b> {k<sub>1</sub>:e<sub>1</sub>, &hellip;,
   * k<sub>n</sub>:e<sub>n</sub>}</i> or the form <i>{k<sub>1</sub>:e<sub>1</sub>, &hellip;,
   * k<sub>n</sub>:e<sub>n</sub>}</i> is `Map&lt;String, dynamic&gt;`.
   *
   * It is a compile-time error if the first type argument to a map literal is not
   * <i>String</i>.</blockquote>
   */
  Object visitMapLiteral(MapLiteral node) {
    Type2 staticKeyType = _dynamicType;
    Type2 staticValueType = _dynamicType;
    TypeArgumentList typeArguments = node.typeArguments;
    if (typeArguments != null) {
      NodeList<TypeName> arguments = typeArguments.arguments;
      if (arguments != null && arguments.length == 2) {
        TypeName entryKeyTypeName = arguments[0];
        Type2 entryKeyType = getType(entryKeyTypeName);
        if (entryKeyType != null) {
          staticKeyType = entryKeyType;
        }
        TypeName entryValueTypeName = arguments[1];
        Type2 entryValueType = getType(entryValueTypeName);
        if (entryValueType != null) {
          staticValueType = entryValueType;
        }
      }
    }
    recordStaticType(node, _typeProvider.mapType.substitute4(<Type2> [staticKeyType, staticValueType]));
    NodeList<MapLiteralEntry> entries = node.entries;
    int count = entries.length;
    if (count > 0) {
      MapLiteralEntry entry = entries[0];
      Type2 propagatedKeyType = entry.key.bestType;
      Type2 propagatedValueType = entry.value.bestType;
      for (int i = 1; i < count; i++) {
        entry = entries[i];
        Type2 elementKeyType = entry.key.bestType;
        if (propagatedKeyType != elementKeyType) {
          propagatedKeyType = _dynamicType;
        } else {
          propagatedKeyType = propagatedKeyType.getLeastUpperBound(elementKeyType);
          if (propagatedKeyType == null) {
            propagatedKeyType = _dynamicType;
          }
        }
        Type2 elementValueType = entry.value.bestType;
        if (propagatedValueType != elementValueType) {
          propagatedValueType = _dynamicType;
        } else {
          propagatedValueType = propagatedValueType.getLeastUpperBound(elementValueType);
          if (propagatedValueType == null) {
            propagatedValueType = _dynamicType;
          }
        }
      }
      bool betterKey = propagatedKeyType != null && propagatedKeyType.isMoreSpecificThan(staticKeyType);
      bool betterValue = propagatedValueType != null && propagatedValueType.isMoreSpecificThan(staticValueType);
      if (betterKey || betterValue) {
        if (!betterKey) {
          propagatedKeyType = staticKeyType;
        }
        if (!betterValue) {
          propagatedValueType = staticValueType;
        }
        recordPropagatedType(node, _typeProvider.mapType.substitute4(<Type2> [propagatedKeyType, propagatedValueType]));
      }
    }
    return null;
  }

  /**
   * The Dart Language Specification, 12.15.1: <blockquote>An ordinary method invocation <i>i</i>
   * has the form <i>o.m(a<sub>1</sub>, &hellip;, a<sub>n</sub>, x<sub>n+1</sub>: a<sub>n+1</sub>,
   * &hellip;, x<sub>n+k</sub>: a<sub>n+k</sub>)</i>.
   *
   * Let <i>T</i> be the static type of <i>o</i>. It is a static type warning if <i>T</i> does not
   * have an accessible instance member named <i>m</i>. If <i>T.m</i> exists, it is a static warning
   * if the type <i>F</i> of <i>T.m</i> may not be assigned to a function type.
   *
   * If <i>T.m</i> does not exist, or if <i>F</i> is not a function type, the static type of
   * <i>i</i> is dynamic. Otherwise the static type of <i>i</i> is the declared return type of
   * <i>F</i>.</blockquote>
   *
   * The Dart Language Specification, 11.15.3: <blockquote>A static method invocation <i>i</i> has
   * the form <i>C.m(a<sub>1</sub>, &hellip;, a<sub>n</sub>, x<sub>n+1</sub>: a<sub>n+1</sub>,
   * &hellip;, x<sub>n+k</sub>: a<sub>n+k</sub>)</i>.
   *
   * It is a static type warning if the type <i>F</i> of <i>C.m</i> may not be assigned to a
   * function type.
   *
   * If <i>F</i> is not a function type, or if <i>C.m</i> does not exist, the static type of i is
   * dynamic. Otherwise the static type of <i>i</i> is the declared return type of
   * <i>F</i>.</blockquote>
   *
   * The Dart Language Specification, 11.15.4: <blockquote>A super method invocation <i>i</i> has
   * the form <i>super.m(a<sub>1</sub>, &hellip;, a<sub>n</sub>, x<sub>n+1</sub>: a<sub>n+1</sub>,
   * &hellip;, x<sub>n+k</sub>: a<sub>n+k</sub>)</i>.
   *
   * It is a static type warning if <i>S</i> does not have an accessible instance member named m. If
   * <i>S.m</i> exists, it is a static warning if the type <i>F</i> of <i>S.m</i> may not be
   * assigned to a function type.
   *
   * If <i>S.m</i> does not exist, or if <i>F</i> is not a function type, the static type of
   * <i>i</i> is dynamic. Otherwise the static type of <i>i</i> is the declared return type of
   * <i>F</i>.</blockquote>
   */
  Object visitMethodInvocation(MethodInvocation node) {
    SimpleIdentifier methodNameNode = node.methodName;
    Element staticMethodElement = methodNameNode.staticElement;
    // Record types of the local variable invoked as a function.
    if (staticMethodElement is LocalVariableElement) {
      LocalVariableElement variable = staticMethodElement;
      Type2 staticType = variable.type;
      recordStaticType(methodNameNode, staticType);
      Type2 propagatedType = _overrideManager.getType(variable);
      if (propagatedType != null && propagatedType.isMoreSpecificThan(staticType)) {
        recordPropagatedType(methodNameNode, propagatedType);
      }
    }
    // Record static return type of the static element.
    Type2 staticStaticType = computeStaticReturnType(staticMethodElement);
    recordStaticType(node, staticStaticType);
    // Record propagated return type of the static element.
    Type2 staticPropagatedType = computePropagatedReturnType(staticMethodElement);
    if (staticPropagatedType != null && (staticStaticType == null || staticPropagatedType.isMoreSpecificThan(staticStaticType))) {
      recordPropagatedType(node, staticPropagatedType);
    }
    String methodName = methodNameNode.name;
    // Future.then(closure) return type is:
    // 1) the returned Future type, if the closure returns a Future;
    // 2) Future<valueType>, if the closure returns a value.
    if (methodName == "then") {
      Expression target = node.realTarget;
      Type2 targetType = target == null ? null : target.bestType;
      if (isAsyncFutureType(targetType)) {
        NodeList<Expression> arguments = node.argumentList.arguments;
        if (arguments.length == 1) {
          // TODO(brianwilkerson) Handle the case where both arguments are provided.
          Expression closureArg = arguments[0];
          if (closureArg is FunctionExpression) {
            FunctionExpression closureExpr = closureArg;
            Type2 returnType = computePropagatedReturnType(closureExpr.element);
            if (returnType != null) {
              // prepare the type of the returned Future
              InterfaceTypeImpl newFutureType;
              if (isAsyncFutureType(returnType)) {
                newFutureType = returnType as InterfaceTypeImpl;
              } else {
                InterfaceType futureType = targetType as InterfaceType;
                newFutureType = new InterfaceTypeImpl.con1(futureType.element);
                newFutureType.typeArguments = <Type2> [returnType];
              }
              // set the 'then' invocation type
              recordPropagatedType(node, newFutureType);
              return null;
            }
          }
        }
      }
    }
    if (methodName == "\$dom_createEvent") {
      Expression target = node.realTarget;
      if (target != null) {
        Type2 targetType = target.bestType;
        if (targetType is InterfaceType && (targetType.name == "HtmlDocument" || targetType.name == "Document")) {
          LibraryElement library = targetType.element.library;
          if (isHtmlLibrary(library)) {
            Type2 returnType = getFirstArgumentAsType(library, node.argumentList);
            if (returnType != null) {
              recordPropagatedType(node, returnType);
            }
          }
        }
      }
    } else if (methodName == "query") {
      Expression target = node.realTarget;
      if (target == null) {
        Element methodElement = methodNameNode.bestElement;
        if (methodElement != null) {
          LibraryElement library = methodElement.library;
          if (isHtmlLibrary(library)) {
            Type2 returnType = getFirstArgumentAsQuery(library, node.argumentList);
            if (returnType != null) {
              recordPropagatedType(node, returnType);
            }
          }
        }
      } else {
        Type2 targetType = target.bestType;
        if (targetType is InterfaceType && (targetType.name == "HtmlDocument" || targetType.name == "Document")) {
          LibraryElement library = targetType.element.library;
          if (isHtmlLibrary(library)) {
            Type2 returnType = getFirstArgumentAsQuery(library, node.argumentList);
            if (returnType != null) {
              recordPropagatedType(node, returnType);
            }
          }
        }
      }
    } else if (methodName == "\$dom_createElement") {
      Expression target = node.realTarget;
      Type2 targetType = target.bestType;
      if (targetType is InterfaceType && (targetType.name == "HtmlDocument" || targetType.name == "Document")) {
        LibraryElement library = targetType.element.library;
        if (isHtmlLibrary(library)) {
          Type2 returnType = getFirstArgumentAsQuery(library, node.argumentList);
          if (returnType != null) {
            recordPropagatedType(node, returnType);
          }
        }
      }
    } else if (methodName == "JS") {
      Type2 returnType = getFirstArgumentAsType(_typeProvider.objectType.element.library, node.argumentList);
      if (returnType != null) {
        recordPropagatedType(node, returnType);
      }
    } else {
      Element propagatedElement = methodNameNode.propagatedElement;
      if (propagatedElement != staticMethodElement) {
        // Record static return type of the propagated element.
        Type2 propagatedStaticType = computeStaticReturnType(propagatedElement);
        if (propagatedStaticType != null && (staticStaticType == null || propagatedStaticType.isMoreSpecificThan(staticStaticType)) && (staticPropagatedType == null || propagatedStaticType.isMoreSpecificThan(staticPropagatedType))) {
          recordPropagatedType(node, propagatedStaticType);
        }
        // Record propagated return type of the propagated element.
        Type2 propagatedPropagatedType = computePropagatedReturnType(propagatedElement);
        if (propagatedPropagatedType != null && (staticStaticType == null || propagatedPropagatedType.isMoreSpecificThan(staticStaticType)) && (staticPropagatedType == null || propagatedPropagatedType.isMoreSpecificThan(staticPropagatedType)) && (propagatedStaticType == null || propagatedPropagatedType.isMoreSpecificThan(propagatedStaticType))) {
          recordPropagatedType(node, propagatedPropagatedType);
        }
      }
    }
    return null;
  }

  Object visitNamedExpression(NamedExpression node) {
    Expression expression = node.expression;
    recordStaticType(node, getStaticType(expression));
    recordPropagatedType(node, expression.propagatedType);
    return null;
  }

  /**
   * The Dart Language Specification, 12.2: <blockquote>The static type of `null` is bottom.
   * </blockquote>
   */
  Object visitNullLiteral(NullLiteral node) {
    recordStaticType(node, _typeProvider.bottomType);
    return null;
  }

  Object visitParenthesizedExpression(ParenthesizedExpression node) {
    Expression expression = node.expression;
    recordStaticType(node, getStaticType(expression));
    recordPropagatedType(node, expression.propagatedType);
    return null;
  }

  /**
   * The Dart Language Specification, 12.28: <blockquote>A postfix expression of the form
   * <i>v++</i>, where <i>v</i> is an identifier, is equivalent to <i>(){var r = v; v = r + 1;
   * return r}()</i>.
   *
   * A postfix expression of the form <i>C.v++</i> is equivalent to <i>(){var r = C.v; C.v = r + 1;
   * return r}()</i>.
   *
   * A postfix expression of the form <i>e1.v++</i> is equivalent to <i>(x){var r = x.v; x.v = r +
   * 1; return r}(e1)</i>.
   *
   * A postfix expression of the form <i>e1[e2]++</i> is equivalent to <i>(a, i){var r = a[i]; a[i]
   * = r + 1; return r}(e1, e2)</i>
   *
   * A postfix expression of the form <i>v--</i>, where <i>v</i> is an identifier, is equivalent to
   * <i>(){var r = v; v = r - 1; return r}()</i>.
   *
   * A postfix expression of the form <i>C.v--</i> is equivalent to <i>(){var r = C.v; C.v = r - 1;
   * return r}()</i>.
   *
   * A postfix expression of the form <i>e1.v--</i> is equivalent to <i>(x){var r = x.v; x.v = r -
   * 1; return r}(e1)</i>.
   *
   * A postfix expression of the form <i>e1[e2]--</i> is equivalent to <i>(a, i){var r = a[i]; a[i]
   * = r - 1; return r}(e1, e2)</i></blockquote>
   */
  Object visitPostfixExpression(PostfixExpression node) {
    Expression operand = node.operand;
    Type2 staticType = getStaticType(operand);
    sc.TokenType operator = node.operator.type;
    if (identical(operator, sc.TokenType.MINUS_MINUS) || identical(operator, sc.TokenType.PLUS_PLUS)) {
      Type2 intType = _typeProvider.intType;
      if (identical(getStaticType(node.operand), intType)) {
        staticType = intType;
      }
    }
    recordStaticType(node, staticType);
    recordPropagatedType(node, operand.propagatedType);
    return null;
  }

  /**
   * See [visitSimpleIdentifier].
   */
  Object visitPrefixedIdentifier(PrefixedIdentifier node) {
    SimpleIdentifier prefixedIdentifier = node.identifier;
    Element staticElement = prefixedIdentifier.staticElement;
    Type2 staticType = _dynamicType;
    if (staticElement is ClassElement) {
      if (isNotTypeLiteral(node)) {
        staticType = staticElement.type;
      } else {
        staticType = _typeProvider.typeType;
      }
    } else if (staticElement is FunctionTypeAliasElement) {
      if (isNotTypeLiteral(node)) {
        staticType = staticElement.type;
      } else {
        staticType = _typeProvider.typeType;
      }
    } else if (staticElement is MethodElement) {
      staticType = staticElement.type;
    } else if (staticElement is PropertyAccessorElement) {
      staticType = getTypeOfProperty(staticElement, node.prefix.staticType);
    } else if (staticElement is ExecutableElement) {
      staticType = staticElement.type;
    } else if (staticElement is TypeParameterElement) {
      staticType = staticElement.type;
    } else if (staticElement is VariableElement) {
      staticType = staticElement.type;
    }
    recordStaticType(prefixedIdentifier, staticType);
    recordStaticType(node, staticType);
    Element propagatedElement = prefixedIdentifier.propagatedElement;
    Type2 propagatedType = null;
    if (propagatedElement is ClassElement) {
      if (isNotTypeLiteral(node)) {
        propagatedType = propagatedElement.type;
      } else {
        propagatedType = _typeProvider.typeType;
      }
    } else if (propagatedElement is FunctionTypeAliasElement) {
      propagatedType = propagatedElement.type;
    } else if (propagatedElement is MethodElement) {
      propagatedType = propagatedElement.type;
    } else if (propagatedElement is PropertyAccessorElement) {
      propagatedType = getTypeOfProperty(propagatedElement, node.prefix.staticType);
    } else if (propagatedElement is ExecutableElement) {
      propagatedType = propagatedElement.type;
    } else if (propagatedElement is TypeParameterElement) {
      propagatedType = propagatedElement.type;
    } else if (propagatedElement is VariableElement) {
      propagatedType = propagatedElement.type;
    }
    Type2 overriddenType = _overrideManager.getType(propagatedElement);
    if (propagatedType == null || (overriddenType != null && overriddenType.isMoreSpecificThan(propagatedType))) {
      propagatedType = overriddenType;
    }
    if (propagatedType != null && propagatedType.isMoreSpecificThan(staticType)) {
      recordPropagatedType(prefixedIdentifier, propagatedType);
      recordPropagatedType(node, propagatedType);
    }
    return null;
  }

  /**
   * The Dart Language Specification, 12.27: <blockquote>A unary expression <i>u</i> of the form
   * <i>op e</i> is equivalent to a method invocation <i>expression e.op()</i>. An expression of the
   * form <i>op super</i> is equivalent to the method invocation <i>super.op()<i>.</blockquote>
   */
  Object visitPrefixExpression(PrefixExpression node) {
    sc.TokenType operator = node.operator.type;
    if (identical(operator, sc.TokenType.BANG)) {
      recordStaticType(node, _typeProvider.boolType);
    } else {
      // The other cases are equivalent to invoking a method.
      ExecutableElement staticMethodElement = node.staticElement;
      Type2 staticType = computeStaticReturnType(staticMethodElement);
      if (identical(operator, sc.TokenType.MINUS_MINUS) || identical(operator, sc.TokenType.PLUS_PLUS)) {
        Type2 intType = _typeProvider.intType;
        if (identical(getStaticType(node.operand), intType)) {
          staticType = intType;
        }
      }
      recordStaticType(node, staticType);
      MethodElement propagatedMethodElement = node.propagatedElement;
      if (propagatedMethodElement != staticMethodElement) {
        Type2 propagatedType = computeStaticReturnType(propagatedMethodElement);
        if (propagatedType != null && propagatedType.isMoreSpecificThan(staticType)) {
          recordPropagatedType(node, propagatedType);
        }
      }
    }
    return null;
  }

  /**
   * The Dart Language Specification, 12.13: <blockquote> Property extraction allows for a member of
   * an object to be concisely extracted from the object. If <i>o</i> is an object, and if <i>m</i>
   * is the name of a method member of <i>o</i>, then
   * * <i>o.m</i> is defined to be equivalent to: <i>(r<sub>1</sub>, &hellip;, r<sub>n</sub>,
   * {p<sub>1</sub> : d<sub>1</sub>, &hellip;, p<sub>k</sub> : d<sub>k</sub>}){return
   * o.m(r<sub>1</sub>, &hellip;, r<sub>n</sub>, p<sub>1</sub>: p<sub>1</sub>, &hellip;,
   * p<sub>k</sub>: p<sub>k</sub>);}</i> if <i>m</i> has required parameters <i>r<sub>1</sub>,
   * &hellip;, r<sub>n</sub></i>, and named parameters <i>p<sub>1</sub> &hellip; p<sub>k</sub></i>
   * with defaults <i>d<sub>1</sub>, &hellip;, d<sub>k</sub></i>.
   * * <i>(r<sub>1</sub>, &hellip;, r<sub>n</sub>, [p<sub>1</sub> = d<sub>1</sub>, &hellip;,
   * p<sub>k</sub> = d<sub>k</sub>]){return o.m(r<sub>1</sub>, &hellip;, r<sub>n</sub>,
   * p<sub>1</sub>, &hellip;, p<sub>k</sub>);}</i> if <i>m</i> has required parameters
   * <i>r<sub>1</sub>, &hellip;, r<sub>n</sub></i>, and optional positional parameters
   * <i>p<sub>1</sub> &hellip; p<sub>k</sub></i> with defaults <i>d<sub>1</sub>, &hellip;,
   * d<sub>k</sub></i>.
   * Otherwise, if <i>m</i> is the name of a getter member of <i>o</i> (declared implicitly or
   * explicitly) then <i>o.m</i> evaluates to the result of invoking the getter. </blockquote>
   *
   * The Dart Language Specification, 12.17: <blockquote> ... a getter invocation <i>i</i> of the
   * form <i>e.m</i> ...
   *
   * Let <i>T</i> be the static type of <i>e</i>. It is a static type warning if <i>T</i> does not
   * have a getter named <i>m</i>.
   *
   * The static type of <i>i</i> is the declared return type of <i>T.m</i>, if <i>T.m</i> exists;
   * otherwise the static type of <i>i</i> is dynamic.
   *
   * ... a getter invocation <i>i</i> of the form <i>C.m</i> ...
   *
   * It is a static warning if there is no class <i>C</i> in the enclosing lexical scope of
   * <i>i</i>, or if <i>C</i> does not declare, implicitly or explicitly, a getter named <i>m</i>.
   *
   * The static type of <i>i</i> is the declared return type of <i>C.m</i> if it exists or dynamic
   * otherwise.
   *
   * ... a top-level getter invocation <i>i</i> of the form <i>m</i>, where <i>m</i> is an
   * identifier ...
   *
   * The static type of <i>i</i> is the declared return type of <i>m</i>.</blockquote>
   */
  Object visitPropertyAccess(PropertyAccess node) {
    SimpleIdentifier propertyName = node.propertyName;
    Element staticElement = propertyName.staticElement;
    Type2 staticType = _dynamicType;
    if (staticElement is MethodElement) {
      staticType = staticElement.type;
    } else if (staticElement is PropertyAccessorElement) {
      Expression realTarget = node.realTarget;
      staticType = getTypeOfProperty(staticElement, realTarget != null ? getStaticType(realTarget) : null);
    } else {
    }
    recordStaticType(propertyName, staticType);
    recordStaticType(node, staticType);
    Element propagatedElement = propertyName.propagatedElement;
    Type2 propagatedType = _overrideManager.getType(propagatedElement);
    if (propagatedElement is MethodElement) {
      propagatedType = propagatedElement.type;
    } else if (propagatedElement is PropertyAccessorElement) {
      Expression realTarget = node.realTarget;
      propagatedType = getTypeOfProperty(propagatedElement, realTarget != null ? realTarget.bestType : null);
    } else {
    }
    if (propagatedType != null && propagatedType.isMoreSpecificThan(staticType)) {
      recordPropagatedType(propertyName, propagatedType);
      recordPropagatedType(node, propagatedType);
    }
    return null;
  }

  /**
   * The Dart Language Specification, 12.9: <blockquote>The static type of a rethrow expression is
   * bottom.</blockquote>
   */
  Object visitRethrowExpression(RethrowExpression node) {
    recordStaticType(node, _typeProvider.bottomType);
    return null;
  }

  /**
   * The Dart Language Specification, 12.30: <blockquote>Evaluation of an identifier expression
   * <i>e</i> of the form <i>id</i> proceeds as follows:
   *
   * Let <i>d</i> be the innermost declaration in the enclosing lexical scope whose name is
   * <i>id</i>. If no such declaration exists in the lexical scope, let <i>d</i> be the declaration
   * of the inherited member named <i>id</i> if it exists.
   * * If <i>d</i> is a class or type alias <i>T</i>, the value of <i>e</i> is the unique instance
   * of class `Type` reifying <i>T</i>.
   * * If <i>d</i> is a type parameter <i>T</i>, then the value of <i>e</i> is the value of the
   * actual type argument corresponding to <i>T</i> that was passed to the generative constructor
   * that created the current binding of this. We are assured that this is well defined, because if
   * we were in a static member the reference to <i>T</i> would be a compile-time error.
   * * If <i>d</i> is a library variable then:
   * * If <i>d</i> is of one of the forms <i>var v = e<sub>i</sub>;</i>, <i>T v =
   * e<sub>i</sub>;</i>, <i>final v = e<sub>i</sub>;</i>, <i>final T v = e<sub>i</sub>;</i>, and no
   * value has yet been stored into <i>v</i> then the initializer expression <i>e<sub>i</sub></i> is
   * evaluated. If, during the evaluation of <i>e<sub>i</sub></i>, the getter for <i>v</i> is
   * referenced, a CyclicInitializationError is thrown. If the evaluation succeeded yielding an
   * object <i>o</i>, let <i>r = o</i>, otherwise let <i>r = null</i>. In any case, <i>r</i> is
   * stored into <i>v</i>. The value of <i>e</i> is <i>r</i>.
   * * If <i>d</i> is of one of the forms <i>const v = e;</i> or <i>const T v = e;</i> the result
   * of the getter is the value of the compile time constant <i>e</i>. Otherwise
   * * <i>e</i> evaluates to the current binding of <i>id</i>.
   * * If <i>d</i> is a local variable or formal parameter then <i>e</i> evaluates to the current
   * binding of <i>id</i>.
   * * If <i>d</i> is a static method, top level function or local function then <i>e</i>
   * evaluates to the function defined by <i>d</i>.
   * * If <i>d</i> is the declaration of a static variable or static getter declared in class
   * <i>C</i>, then <i>e</i> is equivalent to the getter invocation <i>C.id</i>.
   * * If <i>d</i> is the declaration of a top level getter, then <i>e</i> is equivalent to the
   * getter invocation <i>id</i>.
   * * Otherwise, if <i>e</i> occurs inside a top level or static function (be it function,
   * method, getter, or setter) or variable initializer, evaluation of e causes a NoSuchMethodError
   * to be thrown.
   * * Otherwise <i>e</i> is equivalent to the property extraction <i>this.id</i>.
   * </blockquote>
   */
  Object visitSimpleIdentifier(SimpleIdentifier node) {
    Element element = node.staticElement;
    Type2 staticType = _dynamicType;
    if (element is ClassElement) {
      if (isNotTypeLiteral(node)) {
        staticType = element.type;
      } else {
        staticType = _typeProvider.typeType;
      }
    } else if (element is FunctionTypeAliasElement) {
      if (isNotTypeLiteral(node)) {
        staticType = element.type;
      } else {
        staticType = _typeProvider.typeType;
      }
    } else if (element is MethodElement) {
      staticType = element.type;
    } else if (element is PropertyAccessorElement) {
      staticType = getTypeOfProperty(element, null);
    } else if (element is ExecutableElement) {
      staticType = element.type;
    } else if (element is TypeParameterElement) {
      //      if (isTypeName(node)) {
      staticType = element.type;
    } else if (element is VariableElement) {
      VariableElement variable = element;
      staticType = _promoteManager.getStaticType(variable);
    } else if (element is PrefixElement) {
      return null;
    } else {
      staticType = _dynamicType;
    }
    recordStaticType(node, staticType);
    // TODO(brianwilkerson) I think we want to repeat the logic above using the propagated element
    // to get another candidate for the propagated type.
    Type2 propagatedType = _overrideManager.getType(element);
    if (propagatedType != null && propagatedType.isMoreSpecificThan(staticType)) {
      recordPropagatedType(node, propagatedType);
    }
    return null;
  }

  /**
   * The Dart Language Specification, 12.5: <blockquote>The static type of a string literal is
   * `String`.</blockquote>
   */
  Object visitSimpleStringLiteral(SimpleStringLiteral node) {
    recordStaticType(node, _typeProvider.stringType);
    return null;
  }

  /**
   * The Dart Language Specification, 12.5: <blockquote>The static type of a string literal is
   * `String`.</blockquote>
   */
  Object visitStringInterpolation(StringInterpolation node) {
    recordStaticType(node, _typeProvider.stringType);
    return null;
  }

  Object visitSuperExpression(SuperExpression node) {
    if (_thisType == null) {
      // TODO(brianwilkerson) Report this error if it hasn't already been reported
      recordStaticType(node, _dynamicType);
    } else {
      recordStaticType(node, _thisType);
    }
    return null;
  }

  Object visitSymbolLiteral(SymbolLiteral node) {
    recordStaticType(node, _typeProvider.symbolType);
    return null;
  }

  /**
   * The Dart Language Specification, 12.10: <blockquote>The static type of `this` is the
   * interface of the immediately enclosing class.</blockquote>
   */
  Object visitThisExpression(ThisExpression node) {
    if (_thisType == null) {
      // TODO(brianwilkerson) Report this error if it hasn't already been reported
      recordStaticType(node, _dynamicType);
    } else {
      recordStaticType(node, _thisType);
    }
    return null;
  }

  /**
   * The Dart Language Specification, 12.8: <blockquote>The static type of a throw expression is
   * bottom.</blockquote>
   */
  Object visitThrowExpression(ThrowExpression node) {
    recordStaticType(node, _typeProvider.bottomType);
    return null;
  }

  Object visitVariableDeclaration(VariableDeclaration node) {
    Expression initializer = node.initializer;
    if (initializer != null) {
      Type2 rightType = initializer.bestType;
      SimpleIdentifier name = node.name;
      recordPropagatedType(name, rightType);
      VariableElement element = name.staticElement as VariableElement;
      if (element != null) {
        _resolver.override2(element, rightType);
      }
    }
    return null;
  }

  /**
   * Record that the static type of the given node is the type of the second argument to the method
   * represented by the given element.
   *
   * @param element the element representing the method invoked by the given node
   */
  Type2 computeArgumentType(ExecutableElement element) {
    if (element != null) {
      List<ParameterElement> parameters = element.parameters;
      if (parameters != null && parameters.length == 2) {
        return parameters[1].type;
      }
    }
    return _dynamicType;
  }

  /**
   * Compute the propagated return type of the method or function represented by the given element.
   *
   * @param element the element representing the method or function invoked by the given node
   * @return the propagated return type that was computed
   */
  Type2 computePropagatedReturnType(Element element) {
    if (element is ExecutableElement) {
      return _propagatedReturnTypes[element];
    }
    return null;
  }

  /**
   * Given a function body, compute the propagated return type of the function. The propagated
   * return type of functions with a block body is the least upper bound of all
   * [ReturnStatement] expressions, with an expression body it is the type of the expression.
   *
   * @param body the boy of the function whose propagated return type is to be computed
   * @return the propagated return type that was computed
   */
  Type2 computePropagatedReturnTypeOfFunction(FunctionBody body) {
    if (body is ExpressionFunctionBody) {
      ExpressionFunctionBody expressionBody = body;
      return expressionBody.expression.bestType;
    }
    if (body is BlockFunctionBody) {
      List<Type2> result = [null];
      body.accept(new GeneralizingAstVisitor_StaticTypeAnalyzer_computePropagatedReturnTypeOfFunction(result));
      return result[0];
    }
    return null;
  }

  /**
   * Compute the static return type of the method or function represented by the given element.
   *
   * @param element the element representing the method or function invoked by the given node
   * @return the static return type that was computed
   */
  Type2 computeStaticReturnType(Element element) {
    if (element is PropertyAccessorElement) {
      //
      // This is a function invocation expression disguised as something else. We are invoking a
      // getter and then invoking the returned function.
      //
      FunctionType propertyType = element.type;
      if (propertyType != null) {
        Type2 returnType = propertyType.returnType;
        if (returnType.isDartCoreFunction) {
          return _dynamicType;
        } else if (returnType is InterfaceType) {
          MethodElement callMethod = returnType.lookUpMethod(ElementResolver.CALL_METHOD_NAME, _resolver.definingLibrary);
          if (callMethod != null) {
            return callMethod.type.returnType;
          }
        } else if (returnType is FunctionType) {
          Type2 innerReturnType = returnType.returnType;
          if (innerReturnType != null) {
            return innerReturnType;
          }
        }
        if (returnType != null) {
          return returnType;
        }
      }
    } else if (element is ExecutableElement) {
      FunctionType type = element.type;
      if (type != null) {
        // TODO(brianwilkerson) Figure out the conditions under which the type is null.
        return type.returnType;
      }
    } else if (element is VariableElement) {
      VariableElement variable = element;
      Type2 variableType = _promoteManager.getStaticType(variable);
      if (variableType is FunctionType) {
        return variableType.returnType;
      }
    }
    return _dynamicType;
  }

  /**
   * Given a function declaration, compute the return static type of the function. The return type
   * of functions with a block body is `dynamicType`, with an expression body it is the type
   * of the expression.
   *
   * @param node the function expression whose static return type is to be computed
   * @return the static return type that was computed
   */
  Type2 computeStaticReturnTypeOfFunctionDeclaration(FunctionDeclaration node) {
    TypeName returnType = node.returnType;
    if (returnType == null) {
      return _dynamicType;
    }
    return returnType.type;
  }

  /**
   * Given a function expression, compute the return type of the function. The return type of
   * functions with a block body is `dynamicType`, with an expression body it is the type of
   * the expression.
   *
   * @param node the function expression whose return type is to be computed
   * @return the return type that was computed
   */
  Type2 computeStaticReturnTypeOfFunctionExpression(FunctionExpression node) {
    FunctionBody body = node.body;
    if (body is ExpressionFunctionBody) {
      return getStaticType(body.expression);
    }
    return _dynamicType;
  }

  /**
   * If the given element name can be mapped to the name of a class defined within the given
   * library, return the type specified by the argument.
   *
   * @param library the library in which the specified type would be defined
   * @param elementName the name of the element for which a type is being sought
   * @param nameMap an optional map used to map the element name to a type name
   * @return the type specified by the first argument in the argument list
   */
  Type2 getElementNameAsType(LibraryElement library, String elementName, Map<String, String> nameMap) {
    if (elementName != null) {
      if (nameMap != null) {
        elementName = nameMap[elementName.toLowerCase()];
      }
      ClassElement returnType = library.getType(elementName);
      if (returnType != null) {
        return returnType.type;
      }
    }
    return null;
  }

  /**
   * If the given argument list contains at least one argument, and if the argument is a simple
   * string literal, then parse that argument as a query string and return the type specified by the
   * argument.
   *
   * @param library the library in which the specified type would be defined
   * @param argumentList the list of arguments from which a type is to be extracted
   * @return the type specified by the first argument in the argument list
   */
  Type2 getFirstArgumentAsQuery(LibraryElement library, ArgumentList argumentList) {
    String argumentValue = getFirstArgumentAsString(argumentList);
    if (argumentValue != null) {
      //
      // If the query has spaces, full parsing is required because it might be:
      //   E[text='warning text']
      //
      if (StringUtilities.indexOf1(argumentValue, 0, 0x20) >= 0) {
        return null;
      }
      //
      // Otherwise, try to extract the tag based on http://www.w3.org/TR/CSS2/selector.html.
      //
      String tag = argumentValue;
      tag = StringUtilities.substringBeforeChar(tag, 0x3A);
      tag = StringUtilities.substringBeforeChar(tag, 0x5B);
      tag = StringUtilities.substringBeforeChar(tag, 0x2E);
      tag = StringUtilities.substringBeforeChar(tag, 0x23);
      tag = _HTML_ELEMENT_TO_CLASS_MAP[tag.toLowerCase()];
      ClassElement returnType = library.getType(tag);
      if (returnType != null) {
        return returnType.type;
      }
    }
    return null;
  }

  /**
   * If the given argument list contains at least one argument, and if the argument is a simple
   * string literal, return the String value of the argument.
   *
   * @param argumentList the list of arguments from which a string value is to be extracted
   * @return the string specified by the first argument in the argument list
   */
  String getFirstArgumentAsString(ArgumentList argumentList) {
    NodeList<Expression> arguments = argumentList.arguments;
    if (arguments.length > 0) {
      Expression argument = arguments[0];
      if (argument is SimpleStringLiteral) {
        return argument.value;
      }
    }
    return null;
  }

  /**
   * If the given argument list contains at least one argument, and if the argument is a simple
   * string literal, and if the value of the argument is the name of a class defined within the
   * given library, return the type specified by the argument.
   *
   * @param library the library in which the specified type would be defined
   * @param argumentList the list of arguments from which a type is to be extracted
   * @return the type specified by the first argument in the argument list
   */
  Type2 getFirstArgumentAsType(LibraryElement library, ArgumentList argumentList) => getFirstArgumentAsTypeWithMap(library, argumentList, null);

  /**
   * If the given argument list contains at least one argument, and if the argument is a simple
   * string literal, and if the value of the argument is the name of a class defined within the
   * given library, return the type specified by the argument.
   *
   * @param library the library in which the specified type would be defined
   * @param argumentList the list of arguments from which a type is to be extracted
   * @param nameMap an optional map used to map the element name to a type name
   * @return the type specified by the first argument in the argument list
   */
  Type2 getFirstArgumentAsTypeWithMap(LibraryElement library, ArgumentList argumentList, Map<String, String> nameMap) => getElementNameAsType(library, getFirstArgumentAsString(argumentList), nameMap);

  /**
   * Return the static type of the given expression.
   *
   * @param expression the expression whose type is to be returned
   * @return the static type of the given expression
   */
  Type2 getStaticType(Expression expression) {
    Type2 type = expression.staticType;
    if (type == null) {
      // TODO(brianwilkerson) Determine the conditions for which the static type is null.
      return _dynamicType;
    }
    return type;
  }

  /**
   * Return the type represented by the given type name.
   *
   * @param typeName the type name representing the type to be returned
   * @return the type represented by the type name
   */
  Type2 getType(TypeName typeName) {
    Type2 type = typeName.type;
    if (type == null) {
      //TODO(brianwilkerson) Determine the conditions for which the type is null.
      return _dynamicType;
    }
    return type;
  }

  /**
   * Return the type that should be recorded for a node that resolved to the given accessor.
   *
   * @param accessor the accessor that the node resolved to
   * @param context if the accessor element has context [by being the RHS of a
   *          [PrefixedIdentifier] or [PropertyAccess]], and the return type of the
   *          accessor is a parameter type, then the type of the LHS can be used to get more
   *          specific type information
   * @return the type that should be recorded for a node that resolved to the given accessor
   */
  Type2 getTypeOfProperty(PropertyAccessorElement accessor, Type2 context) {
    FunctionType functionType = accessor.type;
    if (functionType == null) {
      // TODO(brianwilkerson) Report this internal error. This happens when we are analyzing a
      // reference to a property before we have analyzed the declaration of the property or when
      // the property does not have a defined type.
      return _dynamicType;
    }
    if (accessor.isSetter) {
      List<Type2> parameterTypes = functionType.normalParameterTypes;
      if (parameterTypes != null && parameterTypes.length > 0) {
        return parameterTypes[0];
      }
      PropertyAccessorElement getter = accessor.variable.getter;
      if (getter != null) {
        functionType = getter.type;
        if (functionType != null) {
          return functionType.returnType;
        }
      }
      return _dynamicType;
    }
    Type2 returnType = functionType.returnType;
    if (returnType is TypeParameterType && context is InterfaceType) {
      // if the return type is a TypeParameter, we try to use the context [that the function is being
      // called on] to get a more accurate returnType type
      InterfaceType interfaceTypeContext = context;
      //      Type[] argumentTypes = interfaceTypeContext.getTypeArguments();
      List<TypeParameterElement> typeParameterElements = interfaceTypeContext.element != null ? interfaceTypeContext.element.typeParameters : null;
      if (typeParameterElements != null) {
        for (int i = 0; i < typeParameterElements.length; i++) {
          TypeParameterElement typeParameterElement = typeParameterElements[i];
          if (returnType.name == typeParameterElement.name) {
            return interfaceTypeContext.typeArguments[i];
          }
        }
      }
    }
    return returnType;
  }

  /**
   * Return `true` if the given [Type] is the `Future` form the 'dart:async'
   * library.
   */
  bool isAsyncFutureType(Type2 type) => type is InterfaceType && type.name == "Future" && isAsyncLibrary(type.element.library);

  /**
   * Return `true` if the given library is the 'dart:async' library.
   *
   * @param library the library being tested
   * @return `true` if the library is 'dart:async'
   */
  bool isAsyncLibrary(LibraryElement library) => library.name == "dart.async";

  /**
   * Return `true` if the given library is the 'dart:html' library.
   *
   * @param library the library being tested
   * @return `true` if the library is 'dart:html'
   */
  bool isHtmlLibrary(LibraryElement library) => library != null && "dart.dom.html" == library.name;

  /**
   * Return `true` if the given node is not a type literal.
   *
   * @param node the node being tested
   * @return `true` if the given node is not a type literal
   */
  bool isNotTypeLiteral(Identifier node) {
    AstNode parent = node.parent;
    return parent is TypeName || (parent is PrefixedIdentifier && (parent.parent is TypeName || identical(parent.prefix, node))) || (parent is PropertyAccess && identical(parent.target, node)) || (parent is MethodInvocation && identical(node, parent.target));
  }

  /**
   * Record that the propagated type of the given node is the given type.
   *
   * @param expression the node whose type is to be recorded
   * @param type the propagated type of the node
   */
  void recordPropagatedType(Expression expression, Type2 type) {
    if (type != null && !type.isDynamic) {
      expression.propagatedType = type;
    }
  }

  /**
   * Given a function element and its body, compute and record the propagated return type of the
   * function.
   *
   * @param functionElement the function element to record propagated return type for
   * @param body the boy of the function whose propagated return type is to be computed
   * @return the propagated return type that was computed, may be `null` if it is not more
   *         specific than the static return type.
   */
  void recordPropagatedTypeOfFunction(ExecutableElement functionElement, FunctionBody body) {
    Type2 propagatedReturnType = computePropagatedReturnTypeOfFunction(body);
    if (propagatedReturnType == null) {
      return;
    }
    // Ignore 'bottom' type.
    if (propagatedReturnType.isBottom) {
      return;
    }
    // Record only if we inferred more specific type.
    Type2 staticReturnType = functionElement.returnType;
    if (!propagatedReturnType.isMoreSpecificThan(staticReturnType)) {
      return;
    }
    // OK, do record.
    _propagatedReturnTypes[functionElement] = propagatedReturnType;
  }

  /**
   * Record that the static type of the given node is the given type.
   *
   * @param expression the node whose type is to be recorded
   * @param type the static type of the node
   */
  void recordStaticType(Expression expression, Type2 type) {
    if (type == null) {
      expression.staticType = _dynamicType;
    } else {
      expression.staticType = type;
    }
  }

  /**
   * Attempts to make a better guess for the static type of the given binary expression.
   *
   * @param node the binary expression to analyze
   * @param staticType the static type of the expression as resolved
   * @return the better type guess, or the same static type as given
   */
  Type2 refineBinaryExpressionType(BinaryExpression node, Type2 staticType) {
    sc.TokenType operator = node.operator.type;
    // bool
    if (identical(operator, sc.TokenType.AMPERSAND_AMPERSAND) || identical(operator, sc.TokenType.BAR_BAR) || identical(operator, sc.TokenType.EQ_EQ) || identical(operator, sc.TokenType.BANG_EQ)) {
      return _typeProvider.boolType;
    }
    Type2 intType = _typeProvider.intType;
    if (getStaticType(node.leftOperand) == intType) {
      // int op double
      if (identical(operator, sc.TokenType.MINUS) || identical(operator, sc.TokenType.PERCENT) || identical(operator, sc.TokenType.PLUS) || identical(operator, sc.TokenType.STAR)) {
        Type2 doubleType = _typeProvider.doubleType;
        if (getStaticType(node.rightOperand) == doubleType) {
          return doubleType;
        }
      }
      // int op int
      if (identical(operator, sc.TokenType.MINUS) || identical(operator, sc.TokenType.PERCENT) || identical(operator, sc.TokenType.PLUS) || identical(operator, sc.TokenType.STAR) || identical(operator, sc.TokenType.TILDE_SLASH)) {
        if (getStaticType(node.rightOperand) == intType) {
          staticType = intType;
        }
      }
    }
    // default
    return staticType;
  }

  get thisType_J2DAccessor => _thisType;

  set thisType_J2DAccessor(__v) => _thisType = __v;
}

class GeneralizingAstVisitor_StaticTypeAnalyzer_computePropagatedReturnTypeOfFunction extends GeneralizingAstVisitor<Object> {
  List<Type2> result;

  GeneralizingAstVisitor_StaticTypeAnalyzer_computePropagatedReturnTypeOfFunction(this.result) : super();

  Object visitExpression(Expression node) => null;

  Object visitReturnStatement(ReturnStatement node) {
    // prepare this 'return' type
    Type2 type;
    Expression expression = node.expression;
    if (expression != null) {
      type = expression.bestType;
    } else {
      type = BottomTypeImpl.instance;
    }
    // merge types
    if (result[0] == null) {
      result[0] = type;
    } else {
      result[0] = result[0].getLeastUpperBound(type);
    }
    return null;
  }
}

/**
 * Instances of this class manage the knowledge of what the set of subtypes are for a given type.
 */
class SubtypeManager {
  /**
   * A map between [ClassElement]s and a set of [ClassElement]s that are subtypes of the
   * key.
   */
  Map<ClassElement, Set<ClassElement>> _subtypeMap = new Map<ClassElement, Set<ClassElement>>();

  /**
   * The set of all [LibraryElement]s that have been visited by the manager. This is used both
   * to prevent infinite loops in the recursive methods, and also as a marker for the scope of the
   * libraries visited by this manager.
   */
  Set<LibraryElement> _visitedLibraries = new Set<LibraryElement>();

  /**
   * Given some [ClassElement], return the set of all subtypes, and subtypes of subtypes.
   *
   * @param classElement the class to recursively return the set of subtypes of
   */
  Set<ClassElement> computeAllSubtypes(ClassElement classElement) {
    // Ensure that we have generated the subtype map for the library
    computeSubtypesInLibrary(classElement.library);
    // use the subtypeMap to compute the set of all subtypes and subtype's subtypes
    Set<ClassElement> allSubtypes = new Set<ClassElement>();
    safelyComputeAllSubtypes(classElement, new Set<ClassElement>(), allSubtypes);
    return allSubtypes;
  }

  /**
   * Given some [LibraryElement], visit all of the types in the library, the passed library,
   * and any imported libraries, will be in the [visitedLibraries] set.
   *
   * @param libraryElement the library to visit, it it hasn't been visited already
   */
  void ensureLibraryVisited(LibraryElement libraryElement) {
    computeSubtypesInLibrary(libraryElement);
  }

  /**
   * Given some [ClassElement], this method adds all of the pairs combinations of itself and
   * all of its supertypes to the [subtypeMap] map.
   *
   * @param classElement the class element
   */
  void computeSubtypesInClass(ClassElement classElement) {
    InterfaceType supertypeType = classElement.supertype;
    if (supertypeType != null) {
      ClassElement supertypeElement = supertypeType.element;
      if (supertypeElement != null) {
        putInSubtypeMap(supertypeElement, classElement);
      }
    }
    List<InterfaceType> interfaceTypes = classElement.interfaces;
    for (InterfaceType interfaceType in interfaceTypes) {
      ClassElement interfaceElement = interfaceType.element;
      if (interfaceElement != null) {
        putInSubtypeMap(interfaceElement, classElement);
      }
    }
    List<InterfaceType> mixinTypes = classElement.mixins;
    for (InterfaceType mixinType in mixinTypes) {
      ClassElement mixinElement = mixinType.element;
      if (mixinElement != null) {
        putInSubtypeMap(mixinElement, classElement);
      }
    }
  }

  /**
   * Given some [CompilationUnitElement], this method calls
   * [computeAllSubtypes] on all of the [ClassElement]s in the
   * compilation unit.
   *
   * @param unitElement the compilation unit element
   */
  void computeSubtypesInCompilationUnit(CompilationUnitElement unitElement) {
    List<ClassElement> classElements = unitElement.types;
    for (ClassElement classElement in classElements) {
      computeSubtypesInClass(classElement);
    }
  }

  /**
   * Given some [LibraryElement], this method calls
   * [computeAllSubtypes] on all of the [ClassElement]s in the
   * compilation unit, and itself for all imported and exported libraries. All visited libraries are
   * added to the [visitedLibraries] set.
   *
   * @param libraryElement the library element
   */
  void computeSubtypesInLibrary(LibraryElement libraryElement) {
    if (libraryElement == null || _visitedLibraries.contains(libraryElement)) {
      return;
    }
    _visitedLibraries.add(libraryElement);
    computeSubtypesInCompilationUnit(libraryElement.definingCompilationUnit);
    List<CompilationUnitElement> parts = libraryElement.parts;
    for (CompilationUnitElement part in parts) {
      computeSubtypesInCompilationUnit(part);
    }
    List<LibraryElement> imports = libraryElement.importedLibraries;
    for (LibraryElement importElt in imports) {
      computeSubtypesInLibrary(importElt.library);
    }
    List<LibraryElement> exports = libraryElement.exportedLibraries;
    for (LibraryElement exportElt in exports) {
      computeSubtypesInLibrary(exportElt.library);
    }
  }

  /**
   * Add some key/ value pair into the [subtypeMap] map.
   *
   * @param supertypeElement the key for the [subtypeMap] map
   * @param subtypeElement the value for the [subtypeMap] map
   */
  void putInSubtypeMap(ClassElement supertypeElement, ClassElement subtypeElement) {
    Set<ClassElement> subtypes = _subtypeMap[supertypeElement];
    if (subtypes == null) {
      subtypes = new Set<ClassElement>();
      _subtypeMap[supertypeElement] = subtypes;
    }
    subtypes.add(subtypeElement);
  }

  /**
   * Given some [ClassElement] and a [HashSet<ClassElement>], this method recursively
   * adds all of the subtypes of the [ClassElement] to the passed array.
   *
   * @param classElement the type to compute the set of subtypes of
   * @param visitedClasses the set of class elements that this method has already recursively seen
   * @param allSubtypes the computed set of subtypes of the passed class element
   */
  void safelyComputeAllSubtypes(ClassElement classElement, Set<ClassElement> visitedClasses, Set<ClassElement> allSubtypes) {
    if (!visitedClasses.add(classElement)) {
      // if this class has already been called on this class element
      return;
    }
    Set<ClassElement> subtypes = _subtypeMap[classElement];
    if (subtypes == null) {
      return;
    }
    for (ClassElement subtype in subtypes) {
      safelyComputeAllSubtypes(subtype, visitedClasses, allSubtypes);
    }
    allSubtypes.addAll(subtypes);
  }
}

/**
 * Instances of the class `TypeOverrideManager` manage the ability to override the type of an
 * element within a given context.
 */
class TypeOverrideManager {
  /**
   * The current override scope, or `null` if no scope has been entered.
   */
  TypeOverrideManager_TypeOverrideScope _currentScope;

  /**
   * Apply a set of overrides that were previously captured.
   *
   * @param overrides the overrides to be applied
   */
  void applyOverrides(Map<Element, Type2> overrides) {
    if (_currentScope == null) {
      throw new IllegalStateException("Cannot apply overrides without a scope");
    }
    _currentScope.applyOverrides(overrides);
  }

  /**
   * Return a table mapping the elements whose type is overridden in the current scope to the
   * overriding type.
   *
   * @return the overrides in the current scope
   */
  Map<Element, Type2> captureLocalOverrides() {
    if (_currentScope == null) {
      throw new IllegalStateException("Cannot capture local overrides without a scope");
    }
    return _currentScope.captureLocalOverrides();
  }

  /**
   * Return a map from the elements for the variables in the given list that have their types
   * overridden to the overriding type.
   *
   * @param variableList the list of variables whose overriding types are to be captured
   * @return a table mapping elements to their overriding types
   */
  Map<Element, Type2> captureOverrides(VariableDeclarationList variableList) {
    if (_currentScope == null) {
      throw new IllegalStateException("Cannot capture overrides without a scope");
    }
    return _currentScope.captureOverrides(variableList);
  }

  /**
   * Enter a new override scope.
   */
  void enterScope() {
    _currentScope = new TypeOverrideManager_TypeOverrideScope(_currentScope);
  }

  /**
   * Exit the current override scope.
   */
  void exitScope() {
    if (_currentScope == null) {
      throw new IllegalStateException("No scope to exit");
    }
    _currentScope = _currentScope._outerScope;
  }

  /**
   * Return the overridden type of the given element, or `null` if the type of the element has
   * not been overridden.
   *
   * @param element the element whose type might have been overridden
   * @return the overridden type of the given element
   */
  Type2 getType(Element element) {
    if (_currentScope == null) {
      return null;
    }
    return _currentScope.getType(element);
  }

  /**
   * Set the overridden type of the given element to the given type
   *
   * @param element the element whose type might have been overridden
   * @param type the overridden type of the given element
   */
  void setType(Element element, Type2 type) {
    if (_currentScope == null) {
      throw new IllegalStateException("Cannot override without a scope");
    }
    _currentScope.setType(element, type);
  }
}

/**
 * Instances of the class `TypeOverrideScope` represent a scope in which the types of
 * elements can be overridden.
 */
class TypeOverrideManager_TypeOverrideScope {
  /**
   * The outer scope in which types might be overridden.
   */
  TypeOverrideManager_TypeOverrideScope _outerScope;

  /**
   * A table mapping elements to the overridden type of that element.
   */
  Map<Element, Type2> _overridenTypes = new Map<Element, Type2>();

  /**
   * Initialize a newly created scope to be an empty child of the given scope.
   *
   * @param outerScope the outer scope in which types might be overridden
   */
  TypeOverrideManager_TypeOverrideScope(TypeOverrideManager_TypeOverrideScope outerScope) {
    this._outerScope = outerScope;
  }

  /**
   * Apply a set of overrides that were previously captured.
   *
   * @param overrides the overrides to be applied
   */
  void applyOverrides(Map<Element, Type2> overrides) {
    for (MapEntry<Element, Type2> entry in getMapEntrySet(overrides)) {
      _overridenTypes[entry.getKey()] = entry.getValue();
    }
  }

  /**
   * Return a table mapping the elements whose type is overridden in the current scope to the
   * overriding type.
   *
   * @return the overrides in the current scope
   */
  Map<Element, Type2> captureLocalOverrides() => _overridenTypes;

  /**
   * Return a map from the elements for the variables in the given list that have their types
   * overridden to the overriding type.
   *
   * @param variableList the list of variables whose overriding types are to be captured
   * @return a table mapping elements to their overriding types
   */
  Map<Element, Type2> captureOverrides(VariableDeclarationList variableList) {
    Map<Element, Type2> overrides = new Map<Element, Type2>();
    if (variableList.isConst || variableList.isFinal) {
      for (VariableDeclaration variable in variableList.variables) {
        Element element = variable.element;
        if (element != null) {
          Type2 type = _overridenTypes[element];
          if (type != null) {
            overrides[element] = type;
          }
        }
      }
    }
    return overrides;
  }

  /**
   * Return the overridden type of the given element, or `null` if the type of the element
   * has not been overridden.
   *
   * @param element the element whose type might have been overridden
   * @return the overridden type of the given element
   */
  Type2 getType(Element element) {
    Type2 type = _overridenTypes[element];
    if (type == null && element is PropertyAccessorElement) {
      type = _overridenTypes[element.variable];
    }
    if (type != null) {
      return type;
    } else if (_outerScope != null) {
      return _outerScope.getType(element);
    }
    return null;
  }

  /**
   * Set the overridden type of the given element to the given type
   *
   * @param element the element whose type might have been overridden
   * @param type the overridden type of the given element
   */
  void setType(Element element, Type2 type) {
    _overridenTypes[element] = type;
  }
}

/**
 * Instances of the class `TypePromotionManager` manage the ability to promote types of local
 * variables and formal parameters from their declared types based on control flow.
 */
class TypePromotionManager {
  /**
   * The current promotion scope, or `null` if no scope has been entered.
   */
  TypePromotionManager_TypePromoteScope _currentScope;

  /**
   * Enter a new promotions scope.
   */
  void enterScope() {
    _currentScope = new TypePromotionManager_TypePromoteScope(_currentScope);
  }

  /**
   * Exit the current promotion scope.
   */
  void exitScope() {
    if (_currentScope == null) {
      throw new IllegalStateException("No scope to exit");
    }
    _currentScope = _currentScope._outerScope;
  }

  /**
   * Returns the elements with promoted types.
   */
  Iterable<Element> get promotedElements => _currentScope.promotedElements;

  /**
   * Returns static type of the given variable - declared or promoted.
   *
   * @return the static type of the given variable - declared or promoted
   */
  Type2 getStaticType(VariableElement variable) {
    Type2 staticType = getType(variable);
    if (staticType == null) {
      staticType = variable.type;
    }
    return staticType;
  }

  /**
   * Return the promoted type of the given element, or `null` if the type of the element has
   * not been promoted.
   *
   * @param element the element whose type might have been promoted
   * @return the promoted type of the given element
   */
  Type2 getType(Element element) {
    if (_currentScope == null) {
      return null;
    }
    return _currentScope.getType(element);
  }

  /**
   * Set the promoted type of the given element to the given type.
   *
   * @param element the element whose type might have been promoted
   * @param type the promoted type of the given element
   */
  void setType(Element element, Type2 type) {
    if (_currentScope == null) {
      throw new IllegalStateException("Cannot promote without a scope");
    }
    _currentScope.setType(element, type);
  }
}

/**
 * Instances of the class `TypePromoteScope` represent a scope in which the types of
 * elements can be promoted.
 */
class TypePromotionManager_TypePromoteScope {
  /**
   * The outer scope in which types might be promoter.
   */
  TypePromotionManager_TypePromoteScope _outerScope;

  /**
   * A table mapping elements to the promoted type of that element.
   */
  Map<Element, Type2> _promotedTypes = new Map<Element, Type2>();

  /**
   * Initialize a newly created scope to be an empty child of the given scope.
   *
   * @param outerScope the outer scope in which types might be promoted
   */
  TypePromotionManager_TypePromoteScope(TypePromotionManager_TypePromoteScope outerScope) {
    this._outerScope = outerScope;
  }

  /**
   * Returns the elements with promoted types.
   */
  Iterable<Element> get promotedElements => _promotedTypes.keys.toSet();

  /**
   * Return the promoted type of the given element, or `null` if the type of the element has
   * not been promoted.
   *
   * @param element the element whose type might have been promoted
   * @return the promoted type of the given element
   */
  Type2 getType(Element element) {
    Type2 type = _promotedTypes[element];
    if (type == null && element is PropertyAccessorElement) {
      type = _promotedTypes[element.variable];
    }
    if (type != null) {
      return type;
    } else if (_outerScope != null) {
      return _outerScope.getType(element);
    }
    return null;
  }

  /**
   * Set the promoted type of the given element to the given type.
   *
   * @param element the element whose type might have been promoted
   * @param type the promoted type of the given element
   */
  void setType(Element element, Type2 type) {
    _promotedTypes[element] = type;
  }
}

/**
 * The interface `TypeProvider` defines the behavior of objects that provide access to types
 * defined by the language.
 */
abstract class TypeProvider {
  /**
   * Return the type representing the built-in type 'bool'.
   *
   * @return the type representing the built-in type 'bool'
   */
  InterfaceType get boolType;

  /**
   * Return the type representing the type 'bottom'.
   *
   * @return the type representing the type 'bottom'
   */
  Type2 get bottomType;

  /**
   * Return the type representing the built-in type 'Deprecated'.
   *
   * @return the type representing the built-in type 'Deprecated'
   */
  InterfaceType get deprecatedType;

  /**
   * Return the type representing the built-in type 'double'.
   *
   * @return the type representing the built-in type 'double'
   */
  InterfaceType get doubleType;

  /**
   * Return the type representing the built-in type 'dynamic'.
   *
   * @return the type representing the built-in type 'dynamic'
   */
  Type2 get dynamicType;

  /**
   * Return the type representing the built-in type 'Function'.
   *
   * @return the type representing the built-in type 'Function'
   */
  InterfaceType get functionType;

  /**
   * Return the type representing the built-in type 'int'.
   *
   * @return the type representing the built-in type 'int'
   */
  InterfaceType get intType;

  /**
   * Return the type representing the built-in type 'List'.
   *
   * @return the type representing the built-in type 'List'
   */
  InterfaceType get listType;

  /**
   * Return the type representing the built-in type 'Map'.
   *
   * @return the type representing the built-in type 'Map'
   */
  InterfaceType get mapType;

  /**
   * Return the type representing the built-in type 'Null'.
   *
   * @return the type representing the built-in type 'null'
   */
  InterfaceType get nullType;

  /**
   * Return the type representing the built-in type 'num'.
   *
   * @return the type representing the built-in type 'num'
   */
  InterfaceType get numType;

  /**
   * Return the type representing the built-in type 'Object'.
   *
   * @return the type representing the built-in type 'Object'
   */
  InterfaceType get objectType;

  /**
   * Return the type representing the built-in type 'StackTrace'.
   *
   * @return the type representing the built-in type 'StackTrace'
   */
  InterfaceType get stackTraceType;

  /**
   * Return the type representing the built-in type 'String'.
   *
   * @return the type representing the built-in type 'String'
   */
  InterfaceType get stringType;

  /**
   * Return the type representing the built-in type 'Symbol'.
   *
   * @return the type representing the built-in type 'Symbol'
   */
  InterfaceType get symbolType;

  /**
   * Return the type representing the built-in type 'Type'.
   *
   * @return the type representing the built-in type 'Type'
   */
  InterfaceType get typeType;
}

/**
 * Instances of the class `TypeProviderImpl` provide access to types defined by the language
 * by looking for those types in the element model for the core library.
 */
class TypeProviderImpl implements TypeProvider {
  /**
   * The type representing the built-in type 'bool'.
   */
  InterfaceType _boolType;

  /**
   * The type representing the type 'bottom'.
   */
  Type2 _bottomType;

  /**
   * The type representing the built-in type 'double'.
   */
  InterfaceType _doubleType;

  /**
   * The type representing the built-in type 'Deprecated'.
   */
  InterfaceType _deprecatedType;

  /**
   * The type representing the built-in type 'dynamic'.
   */
  Type2 _dynamicType;

  /**
   * The type representing the built-in type 'Function'.
   */
  InterfaceType _functionType;

  /**
   * The type representing the built-in type 'int'.
   */
  InterfaceType _intType;

  /**
   * The type representing the built-in type 'List'.
   */
  InterfaceType _listType;

  /**
   * The type representing the built-in type 'Map'.
   */
  InterfaceType _mapType;

  /**
   * The type representing the type 'Null'.
   */
  InterfaceType _nullType;

  /**
   * The type representing the built-in type 'num'.
   */
  InterfaceType _numType;

  /**
   * The type representing the built-in type 'Object'.
   */
  InterfaceType _objectType;

  /**
   * The type representing the built-in type 'StackTrace'.
   */
  InterfaceType _stackTraceType;

  /**
   * The type representing the built-in type 'String'.
   */
  InterfaceType _stringType;

  /**
   * The type representing the built-in type 'Symbol'.
   */
  InterfaceType _symbolType;

  /**
   * The type representing the built-in type 'Type'.
   */
  InterfaceType _typeType;

  /**
   * Initialize a newly created type provider to provide the types defined in the given library.
   *
   * @param coreLibrary the element representing the core library (dart:core).
   */
  TypeProviderImpl(LibraryElement coreLibrary) {
    initializeFrom(coreLibrary);
  }

  InterfaceType get boolType => _boolType;

  Type2 get bottomType => _bottomType;

  InterfaceType get deprecatedType => _deprecatedType;

  InterfaceType get doubleType => _doubleType;

  Type2 get dynamicType => _dynamicType;

  InterfaceType get functionType => _functionType;

  InterfaceType get intType => _intType;

  InterfaceType get listType => _listType;

  InterfaceType get mapType => _mapType;

  InterfaceType get nullType => _nullType;

  InterfaceType get numType => _numType;

  InterfaceType get objectType => _objectType;

  InterfaceType get stackTraceType => _stackTraceType;

  InterfaceType get stringType => _stringType;

  InterfaceType get symbolType => _symbolType;

  InterfaceType get typeType => _typeType;

  /**
   * Return the type with the given name from the given namespace, or `null` if there is no
   * class with the given name.
   *
   * @param namespace the namespace in which to search for the given name
   * @param typeName the name of the type being searched for
   * @return the type that was found
   */
  InterfaceType getType(Namespace namespace, String typeName) {
    Element element = namespace.get(typeName);
    if (element == null) {
      AnalysisEngine.instance.logger.logInformation("No definition of type ${typeName}");
      return null;
    }
    return (element as ClassElement).type;
  }

  /**
   * Initialize the types provided by this type provider from the given library.
   *
   * @param library the library containing the definitions of the core types
   */
  void initializeFrom(LibraryElement library) {
    Namespace namespace = new NamespaceBuilder().createPublicNamespace(library);
    _boolType = getType(namespace, "bool");
    _bottomType = BottomTypeImpl.instance;
    _deprecatedType = getType(namespace, "Deprecated");
    _doubleType = getType(namespace, "double");
    _dynamicType = DynamicTypeImpl.instance;
    _functionType = getType(namespace, "Function");
    _intType = getType(namespace, "int");
    _listType = getType(namespace, "List");
    _mapType = getType(namespace, "Map");
    _nullType = getType(namespace, "Null");
    _numType = getType(namespace, "num");
    _objectType = getType(namespace, "Object");
    _stackTraceType = getType(namespace, "StackTrace");
    _stringType = getType(namespace, "String");
    _symbolType = getType(namespace, "Symbol");
    _typeType = getType(namespace, "Type");
  }
}

/**
 * Instances of the class `TypeResolverVisitor` are used to resolve the types associated with
 * the elements in the element model. This includes the types of superclasses, mixins, interfaces,
 * fields, methods, parameters, and local variables. As a side-effect, this also finishes building
 * the type hierarchy.
 */
class TypeResolverVisitor extends ScopedVisitor {
  /**
   * @return `true` if the name of the given [TypeName] is an built-in identifier.
   */
  static bool isBuiltInIdentifier(TypeName node) {
    sc.Token token = node.name.beginToken;
    return identical(token.type, sc.TokenType.KEYWORD);
  }

  /**
   * @return `true` if given [TypeName] is used as a type annotation.
   */
  static bool isTypeAnnotation(TypeName node) {
    AstNode parent = node.parent;
    if (parent is VariableDeclarationList) {
      return identical(parent.type, node);
    }
    if (parent is FieldFormalParameter) {
      return identical(parent.type, node);
    }
    if (parent is SimpleFormalParameter) {
      return identical(parent.type, node);
    }
    return false;
  }

  /**
   * The type representing the type 'dynamic'.
   */
  Type2 _dynamicType;

  /**
   * The flag specifying if currently visited class references 'super' expression.
   */
  bool _hasReferenceToSuper = false;

  /**
   * Initialize a newly created visitor to resolve the nodes in a compilation unit.
   *
   * @param library the library containing the compilation unit being resolved
   * @param source the source representing the compilation unit being visited
   * @param typeProvider the object used to access the types from the core library
   */
  TypeResolverVisitor.con1(Library library, Source source, TypeProvider typeProvider) : super.con1(library, source, typeProvider) {
    _dynamicType = typeProvider.dynamicType;
  }

  /**
   * Initialize a newly created visitor to resolve the nodes in a compilation unit.
   *
   * @param definingLibrary the element for the library containing the compilation unit being
   *          visited
   * @param source the source representing the compilation unit being visited
   * @param typeProvider the object used to access the types from the core library
   * @param errorListener the error listener that will be informed of any errors that are found
   *          during resolution
   */
  TypeResolverVisitor.con2(LibraryElement definingLibrary, Source source, TypeProvider typeProvider, AnalysisErrorListener errorListener) : super.con2(definingLibrary, source, typeProvider, errorListener) {
    _dynamicType = typeProvider.dynamicType;
  }

  /**
   * Initialize a newly created visitor to resolve the nodes in an AST node.
   *
   * @param definingLibrary the element for the library containing the node being visited
   * @param source the source representing the compilation unit containing the node being visited
   * @param typeProvider the object used to access the types from the core library
   * @param nameScope the scope used to resolve identifiers in the node that will first be visited
   * @param errorListener the error listener that will be informed of any errors that are found
   *          during resolution
   */
  TypeResolverVisitor.con3(LibraryElement definingLibrary, Source source, TypeProvider typeProvider, Scope nameScope, AnalysisErrorListener errorListener) : super.con3(definingLibrary, source, typeProvider, nameScope, errorListener) {
    _dynamicType = typeProvider.dynamicType;
  }

  Object visitCatchClause(CatchClause node) {
    super.visitCatchClause(node);
    SimpleIdentifier exception = node.exceptionParameter;
    if (exception != null) {
      // If an 'on' clause is provided the type of the exception parameter is the type in the 'on'
      // clause. Otherwise, the type of the exception parameter is 'Object'.
      TypeName exceptionTypeName = node.exceptionType;
      Type2 exceptionType;
      if (exceptionTypeName == null) {
        exceptionType = typeProvider.dynamicType;
      } else {
        exceptionType = getType(exceptionTypeName);
      }
      recordType(exception, exceptionType);
      Element element = exception.staticElement;
      if (element is VariableElementImpl) {
        element.type = exceptionType;
      } else {
      }
    }
    SimpleIdentifier stackTrace = node.stackTraceParameter;
    if (stackTrace != null) {
      recordType(stackTrace, typeProvider.stackTraceType);
    }
    return null;
  }

  Object visitClassDeclaration(ClassDeclaration node) {
    _hasReferenceToSuper = false;
    super.visitClassDeclaration(node);
    ClassElementImpl classElement = getClassElement(node.name);
    InterfaceType superclassType = null;
    ExtendsClause extendsClause = node.extendsClause;
    if (extendsClause != null) {
      ErrorCode errorCode = (node.withClause == null ? CompileTimeErrorCode.EXTENDS_NON_CLASS : CompileTimeErrorCode.MIXIN_WITH_NON_CLASS_SUPERCLASS);
      superclassType = resolveType(extendsClause.superclass, errorCode, errorCode);
      if (superclassType != typeProvider.objectType) {
        classElement.validMixin = false;
      }
    }
    if (classElement != null) {
      if (superclassType == null) {
        InterfaceType objectType = typeProvider.objectType;
        if (classElement.type != objectType) {
          superclassType = objectType;
        }
      }
      classElement.supertype = superclassType;
      classElement.hasReferenceToSuper2 = _hasReferenceToSuper;
    }
    resolve(classElement, node.withClause, node.implementsClause);
    return null;
  }

  Object visitClassTypeAlias(ClassTypeAlias node) {
    super.visitClassTypeAlias(node);
    ClassElementImpl classElement = getClassElement(node.name);
    ErrorCode errorCode = CompileTimeErrorCode.MIXIN_WITH_NON_CLASS_SUPERCLASS;
    InterfaceType superclassType = resolveType(node.superclass, errorCode, errorCode);
    if (superclassType == null) {
      superclassType = typeProvider.objectType;
    }
    if (classElement != null && superclassType != null) {
      classElement.supertype = superclassType;
      ClassElement superclassElement = superclassType.element;
      if (superclassElement != null) {
        List<ConstructorElement> constructors = superclassElement.constructors;
        int count = constructors.length;
        if (count > 0) {
          List<Type2> parameterTypes = TypeParameterTypeImpl.getTypes(superclassType.typeParameters);
          List<Type2> argumentTypes = getArgumentTypes(node.superclass.typeArguments, parameterTypes);
          InterfaceType classType = classElement.type;
          List<ConstructorElement> implicitConstructors = new List<ConstructorElement>();
          for (int i = 0; i < count; i++) {
            ConstructorElement explicitConstructor = constructors[i];
            if (!explicitConstructor.isFactory) {
              implicitConstructors.add(createImplicitContructor(classType, explicitConstructor, parameterTypes, argumentTypes));
            }
          }
          classElement.constructors = new List.from(implicitConstructors);
        }
      }
    }
    resolve(classElement, node.withClause, node.implementsClause);
    return null;
  }

  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    super.visitConstructorDeclaration(node);
    ExecutableElementImpl element = node.element as ExecutableElementImpl;
    ClassElement definingClass = element.enclosingElement as ClassElement;
    element.returnType = definingClass.type;
    FunctionTypeImpl type = new FunctionTypeImpl.con1(element);
    type.typeArguments = definingClass.type.typeArguments;
    element.type = type;
    return null;
  }

  Object visitDeclaredIdentifier(DeclaredIdentifier node) {
    super.visitDeclaredIdentifier(node);
    Type2 declaredType;
    TypeName typeName = node.type;
    if (typeName == null) {
      declaredType = _dynamicType;
    } else {
      declaredType = getType(typeName);
    }
    LocalVariableElementImpl element = node.element as LocalVariableElementImpl;
    element.type = declaredType;
    return null;
  }

  Object visitFieldFormalParameter(FieldFormalParameter node) {
    super.visitFieldFormalParameter(node);
    Element element = node.identifier.staticElement;
    if (element is ParameterElementImpl) {
      ParameterElementImpl parameter = element;
      FormalParameterList parameterList = node.parameters;
      if (parameterList == null) {
        Type2 type;
        TypeName typeName = node.type;
        if (typeName == null) {
          type = _dynamicType;
          if (parameter is FieldFormalParameterElement) {
            FieldElement fieldElement = (parameter as FieldFormalParameterElement).field;
            if (fieldElement != null) {
              type = fieldElement.type;
            }
          }
        } else {
          type = getType(typeName);
        }
        parameter.type = type;
      } else {
        setFunctionTypedParameterType(parameter, node.type, node.parameters);
      }
    } else {
    }
    return null;
  }

  Object visitFunctionDeclaration(FunctionDeclaration node) {
    super.visitFunctionDeclaration(node);
    ExecutableElementImpl element = node.element as ExecutableElementImpl;
    element.returnType = computeReturnType(node.returnType);
    FunctionTypeImpl type = new FunctionTypeImpl.con1(element);
    ClassElement definingClass = element.getAncestor((element) => element is ClassElement);
    if (definingClass != null) {
      type.typeArguments = definingClass.type.typeArguments;
    }
    element.type = type;
    return null;
  }

  Object visitFunctionTypeAlias(FunctionTypeAlias node) {
    super.visitFunctionTypeAlias(node);
    FunctionTypeAliasElementImpl element = node.element as FunctionTypeAliasElementImpl;
    element.returnType = computeReturnType(node.returnType);
    return null;
  }

  Object visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    super.visitFunctionTypedFormalParameter(node);
    Element element = node.identifier.staticElement;
    if (element is ParameterElementImpl) {
      setFunctionTypedParameterType(element, node.returnType, node.parameters);
    } else {
    }
    return null;
  }

  Object visitMethodDeclaration(MethodDeclaration node) {
    super.visitMethodDeclaration(node);
    ExecutableElementImpl element = node.element as ExecutableElementImpl;
    element.returnType = computeReturnType(node.returnType);
    FunctionTypeImpl type = new FunctionTypeImpl.con1(element);
    ClassElement definingClass = element.getAncestor((element) => element is ClassElement);
    if (definingClass != null) {
      type.typeArguments = definingClass.type.typeArguments;
    }
    element.type = type;
    if (element is PropertyAccessorElement) {
      PropertyAccessorElement accessor = element as PropertyAccessorElement;
      PropertyInducingElementImpl variable = accessor.variable as PropertyInducingElementImpl;
      if (accessor.isGetter) {
        variable.type = type.returnType;
      } else if (variable.type == null) {
        List<Type2> parameterTypes = type.normalParameterTypes;
        if (parameterTypes != null && parameterTypes.length > 0) {
          variable.type = parameterTypes[0];
        }
      }
    }
    return null;
  }

  Object visitSimpleFormalParameter(SimpleFormalParameter node) {
    super.visitSimpleFormalParameter(node);
    Type2 declaredType;
    TypeName typeName = node.type;
    if (typeName == null) {
      declaredType = _dynamicType;
    } else {
      declaredType = getType(typeName);
    }
    Element element = node.identifier.staticElement;
    if (element is ParameterElement) {
      (element as ParameterElementImpl).type = declaredType;
    } else {
    }
    return null;
  }

  Object visitSuperExpression(SuperExpression node) {
    _hasReferenceToSuper = true;
    return super.visitSuperExpression(node);
  }

  Object visitTypeName(TypeName node) {
    super.visitTypeName(node);
    Identifier typeName = node.name;
    TypeArgumentList argumentList = node.typeArguments;
    Element element = nameScope.lookup(typeName, definingLibrary);
    if (element == null) {
      //
      // Check to see whether the type name is either 'dynamic' or 'void', neither of which are in
      // the name scope and hence will not be found by normal means.
      //
      if (typeName.name == this._dynamicType.name) {
        setElement(typeName, this._dynamicType.element);
        if (argumentList != null) {
        }
        typeName.staticType = this._dynamicType;
        node.type = this._dynamicType;
        return null;
      }
      VoidTypeImpl voidType = VoidTypeImpl.instance;
      if (typeName.name == voidType.name) {
        // There is no element for 'void'.
        if (argumentList != null) {
        }
        typeName.staticType = voidType;
        node.type = voidType;
        return null;
      }
      //
      // If not, the look to see whether we might have created the wrong AST structure for a
      // constructor name. If so, fix the AST structure and then proceed.
      //
      AstNode parent = node.parent;
      if (typeName is PrefixedIdentifier && parent is ConstructorName && argumentList == null) {
        ConstructorName name = parent;
        if (name.name == null) {
          PrefixedIdentifier prefixedIdentifier = typeName as PrefixedIdentifier;
          SimpleIdentifier prefix = prefixedIdentifier.prefix;
          element = nameScope.lookup(prefix, definingLibrary);
          if (element is PrefixElement) {
            if (parent.parent is InstanceCreationExpression && (parent.parent as InstanceCreationExpression).isConst) {
              // If, if this is a const expression, then generate a
              // CompileTimeErrorCode.CONST_WITH_NON_TYPE error.
              reportErrorForNode(CompileTimeErrorCode.CONST_WITH_NON_TYPE, prefixedIdentifier.identifier, [prefixedIdentifier.identifier.name]);
            } else {
              // Else, if this expression is a new expression, report a NEW_WITH_NON_TYPE warning.
              reportErrorForNode(StaticWarningCode.NEW_WITH_NON_TYPE, prefixedIdentifier.identifier, [prefixedIdentifier.identifier.name]);
            }
            setElement(prefix, element);
            return null;
          } else if (element != null) {
            //
            // Rewrite the constructor name. The parser, when it sees a constructor named "a.b",
            // cannot tell whether "a" is a prefix and "b" is a class name, or whether "a" is a
            // class name and "b" is a constructor name. It arbitrarily chooses the former, but
            // in this case was wrong.
            //
            name.name = prefixedIdentifier.identifier;
            name.period = prefixedIdentifier.period;
            node.name = prefix;
            typeName = prefix;
          }
        }
      }
    }
    // check element
    bool elementValid = element is! MultiplyDefinedElement;
    if (elementValid && element is! ClassElement && isTypeNameInInstanceCreationExpression(node)) {
      SimpleIdentifier typeNameSimple = getTypeSimpleIdentifier(typeName);
      InstanceCreationExpression creation = node.parent.parent as InstanceCreationExpression;
      if (creation.isConst) {
        if (element == null) {
          reportErrorForNode(CompileTimeErrorCode.UNDEFINED_CLASS, typeNameSimple, [typeName]);
        } else {
          reportErrorForNode(CompileTimeErrorCode.CONST_WITH_NON_TYPE, typeNameSimple, [typeName]);
        }
        elementValid = false;
      } else {
        if (element != null) {
          reportErrorForNode(StaticWarningCode.NEW_WITH_NON_TYPE, typeNameSimple, [typeName]);
          elementValid = false;
        }
      }
    }
    if (elementValid && element == null) {
      // We couldn't resolve the type name.
      // TODO(jwren) Consider moving the check for CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE
      // from the ErrorVerifier, so that we don't have two errors on a built in identifier being
      // used as a class name. See CompileTimeErrorCodeTest.test_builtInIdentifierAsType().
      SimpleIdentifier typeNameSimple = getTypeSimpleIdentifier(typeName);
      RedirectingConstructorKind redirectingConstructorKind;
      if (isBuiltInIdentifier(node) && isTypeAnnotation(node)) {
        reportErrorForNode(CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE, typeName, [typeName.name]);
      } else if (typeNameSimple.name == "boolean") {
        reportErrorForNode(StaticWarningCode.UNDEFINED_CLASS_BOOLEAN, typeNameSimple, []);
      } else if (isTypeNameInCatchClause(node)) {
        reportErrorForNode(StaticWarningCode.NON_TYPE_IN_CATCH_CLAUSE, typeName, [typeName.name]);
      } else if (isTypeNameInAsExpression(node)) {
        reportErrorForNode(StaticWarningCode.CAST_TO_NON_TYPE, typeName, [typeName.name]);
      } else if (isTypeNameInIsExpression(node)) {
        reportErrorForNode(StaticWarningCode.TYPE_TEST_NON_TYPE, typeName, [typeName.name]);
      } else if ((redirectingConstructorKind = getRedirectingConstructorKind(node)) != null) {
        ErrorCode errorCode = (identical(redirectingConstructorKind, RedirectingConstructorKind.CONST) ? CompileTimeErrorCode.REDIRECT_TO_NON_CLASS : StaticWarningCode.REDIRECT_TO_NON_CLASS) as ErrorCode;
        reportErrorForNode(errorCode, typeName, [typeName.name]);
      } else if (isTypeNameInTypeArgumentList(node)) {
        reportErrorForNode(StaticTypeWarningCode.NON_TYPE_AS_TYPE_ARGUMENT, typeName, [typeName.name]);
      } else {
        reportErrorForNode(StaticWarningCode.UNDEFINED_CLASS, typeName, [typeName.name]);
      }
      elementValid = false;
    }
    if (!elementValid) {
      if (element is MultiplyDefinedElement) {
        setElement(typeName, element);
      } else {
        setElement(typeName, this._dynamicType.element);
      }
      typeName.staticType = this._dynamicType;
      node.type = this._dynamicType;
      return null;
    }
    Type2 type = null;
    if (element is ClassElement) {
      setElement(typeName, element);
      type = (element as ClassElement).type;
    } else if (element is FunctionTypeAliasElement) {
      setElement(typeName, element);
      type = (element as FunctionTypeAliasElement).type;
    } else if (element is TypeParameterElement) {
      setElement(typeName, element);
      type = (element as TypeParameterElement).type;
      if (argumentList != null) {
      }
    } else if (element is MultiplyDefinedElement) {
      List<Element> elements = (element as MultiplyDefinedElement).conflictingElements;
      type = getTypeWhenMultiplyDefined(elements);
      if (type != null) {
        node.type = type;
      }
    } else {
      // The name does not represent a type.
      RedirectingConstructorKind redirectingConstructorKind;
      if (isTypeNameInCatchClause(node)) {
        reportErrorForNode(StaticWarningCode.NON_TYPE_IN_CATCH_CLAUSE, typeName, [typeName.name]);
      } else if (isTypeNameInAsExpression(node)) {
        reportErrorForNode(StaticWarningCode.CAST_TO_NON_TYPE, typeName, [typeName.name]);
      } else if (isTypeNameInIsExpression(node)) {
        reportErrorForNode(StaticWarningCode.TYPE_TEST_NON_TYPE, typeName, [typeName.name]);
      } else if ((redirectingConstructorKind = getRedirectingConstructorKind(node)) != null) {
        ErrorCode errorCode = (identical(redirectingConstructorKind, RedirectingConstructorKind.CONST) ? CompileTimeErrorCode.REDIRECT_TO_NON_CLASS : StaticWarningCode.REDIRECT_TO_NON_CLASS) as ErrorCode;
        reportErrorForNode(errorCode, typeName, [typeName.name]);
      } else if (isTypeNameInTypeArgumentList(node)) {
        reportErrorForNode(StaticTypeWarningCode.NON_TYPE_AS_TYPE_ARGUMENT, typeName, [typeName.name]);
      } else {
        AstNode parent = typeName.parent;
        while (parent is TypeName) {
          parent = parent.parent;
        }
        if (parent is ExtendsClause || parent is ImplementsClause || parent is WithClause || parent is ClassTypeAlias) {
        } else {
          reportErrorForNode(StaticWarningCode.NOT_A_TYPE, typeName, [typeName.name]);
        }
      }
      setElement(typeName, this._dynamicType.element);
      typeName.staticType = this._dynamicType;
      node.type = this._dynamicType;
      return null;
    }
    if (argumentList != null) {
      NodeList<TypeName> arguments = argumentList.arguments;
      int argumentCount = arguments.length;
      List<Type2> parameters = getTypeArguments(type);
      int parameterCount = parameters.length;
      int count = Math.min(argumentCount, parameterCount);
      List<Type2> typeArguments = new List<Type2>();
      for (int i = 0; i < count; i++) {
        Type2 argumentType = getType(arguments[i]);
        if (argumentType != null) {
          typeArguments.add(argumentType);
        }
      }
      if (argumentCount != parameterCount) {
        reportErrorForNode(getInvalidTypeParametersErrorCode(node), node, [typeName.name, parameterCount, argumentCount]);
      }
      argumentCount = typeArguments.length;
      if (argumentCount < parameterCount) {
        //
        // If there were too many arguments, we already handled it by not adding the values of the
        // extra arguments to the list. If there are too few, we handle it by adding 'dynamic'
        // enough times to make the count equal.
        //
        for (int i = argumentCount; i < parameterCount; i++) {
          typeArguments.add(this._dynamicType);
        }
      }
      if (type is InterfaceTypeImpl) {
        InterfaceTypeImpl interfaceType = type as InterfaceTypeImpl;
        type = interfaceType.substitute4(new List.from(typeArguments));
      } else if (type is FunctionTypeImpl) {
        FunctionTypeImpl functionType = type as FunctionTypeImpl;
        type = functionType.substitute3(new List.from(typeArguments));
      } else {
      }
    } else {
      //
      // Check for the case where there are no type arguments given for a parameterized type.
      //
      List<Type2> parameters = getTypeArguments(type);
      int parameterCount = parameters.length;
      if (parameterCount > 0) {
        DynamicTypeImpl dynamicType = DynamicTypeImpl.instance;
        List<Type2> arguments = new List<Type2>(parameterCount);
        for (int i = 0; i < parameterCount; i++) {
          arguments[i] = dynamicType;
        }
        type = type.substitute2(arguments, parameters);
      }
    }
    typeName.staticType = type;
    node.type = type;
    return null;
  }

  Object visitTypeParameter(TypeParameter node) {
    super.visitTypeParameter(node);
    TypeName bound = node.bound;
    if (bound != null) {
      TypeParameterElementImpl typeParameter = node.name.staticElement as TypeParameterElementImpl;
      if (typeParameter != null) {
        typeParameter.bound = bound.type;
      }
    }
    return null;
  }

  Object visitVariableDeclaration(VariableDeclaration node) {
    super.visitVariableDeclaration(node);
    Type2 declaredType;
    TypeName typeName = (node.parent as VariableDeclarationList).type;
    if (typeName == null) {
      declaredType = _dynamicType;
    } else {
      declaredType = getType(typeName);
    }
    Element element = node.name.staticElement;
    if (element is VariableElement) {
      (element as VariableElementImpl).type = declaredType;
      if (element is PropertyInducingElement) {
        PropertyInducingElement variableElement = element;
        PropertyAccessorElementImpl getter = variableElement.getter as PropertyAccessorElementImpl;
        getter.returnType = declaredType;
        FunctionTypeImpl getterType = new FunctionTypeImpl.con1(getter);
        ClassElement definingClass = element.getAncestor((element) => element is ClassElement);
        if (definingClass != null) {
          getterType.typeArguments = definingClass.type.typeArguments;
        }
        getter.type = getterType;
        PropertyAccessorElementImpl setter = variableElement.setter as PropertyAccessorElementImpl;
        if (setter != null) {
          List<ParameterElement> parameters = setter.parameters;
          if (parameters.length > 0) {
            (parameters[0] as ParameterElementImpl).type = declaredType;
          }
          setter.returnType = VoidTypeImpl.instance;
          FunctionTypeImpl setterType = new FunctionTypeImpl.con1(setter);
          if (definingClass != null) {
            setterType.typeArguments = definingClass.type.typeArguments;
          }
          setter.type = setterType;
        }
      }
    } else {
    }
    return null;
  }

  void visitClassDeclarationInScope(ClassDeclaration node) {
    //
    // Process field declarations before constructors and methods so that the types of field formal
    // parameters can be correctly resolved.
    //
    List<ClassMember> nonFields = new List<ClassMember>();
    node.visitChildren(new UnifyingAstVisitor_TypeResolverVisitor_visitClassDeclarationInScope(this, nonFields));
    int count = nonFields.length;
    for (int i = 0; i < count; i++) {
      nonFields[i].accept(this);
    }
  }

  /**
   * Given a type name representing the return type of a function, compute the return type of the
   * function.
   *
   * @param returnType the type name representing the return type of the function
   * @return the return type that was computed
   */
  Type2 computeReturnType(TypeName returnType) {
    if (returnType == null) {
      return _dynamicType;
    } else {
      return returnType.type;
    }
  }

  /**
   * Create an implicit constructor that is copied from the given constructor, but that is in the
   * given class.
   *
   * @param classType the class in which the implicit constructor is defined
   * @param explicitConstructor the constructor on which the implicit constructor is modeled
   * @param parameterTypes the types to be replaced when creating parameters
   * @param argumentTypes the types with which the parameters are to be replaced
   * @return the implicit constructor that was created
   */
  ConstructorElement createImplicitContructor(InterfaceType classType, ConstructorElement explicitConstructor, List<Type2> parameterTypes, List<Type2> argumentTypes) {
    ConstructorElementImpl implicitConstructor = new ConstructorElementImpl.con2(explicitConstructor.name, -1);
    implicitConstructor.synthetic = true;
    implicitConstructor.redirectedConstructor = explicitConstructor;
    implicitConstructor.const2 = explicitConstructor.isConst;
    implicitConstructor.returnType = classType;
    List<ParameterElement> explicitParameters = explicitConstructor.parameters;
    int count = explicitParameters.length;
    if (count > 0) {
      List<ParameterElement> implicitParameters = new List<ParameterElement>(count);
      for (int i = 0; i < count; i++) {
        ParameterElement explicitParameter = explicitParameters[i];
        ParameterElementImpl implicitParameter = new ParameterElementImpl.con2(explicitParameter.name, -1);
        implicitParameter.const3 = explicitParameter.isConst;
        implicitParameter.final2 = explicitParameter.isFinal;
        implicitParameter.parameterKind = explicitParameter.parameterKind;
        implicitParameter.synthetic = true;
        implicitParameter.type = explicitParameter.type.substitute2(argumentTypes, parameterTypes);
        implicitParameters[i] = implicitParameter;
      }
      implicitConstructor.parameters = implicitParameters;
    }
    FunctionTypeImpl type = new FunctionTypeImpl.con1(implicitConstructor);
    type.typeArguments = classType.typeArguments;
    implicitConstructor.type = type;
    return implicitConstructor;
  }

  /**
   * Return an array of argument types that corresponds to the array of parameter types and that are
   * derived from the given list of type arguments.
   *
   * @param typeArguments the type arguments from which the types will be taken
   * @param parameterTypes the parameter types that must be matched by the type arguments
   * @return the argument types that correspond to the parameter types
   */
  List<Type2> getArgumentTypes(TypeArgumentList typeArguments, List<Type2> parameterTypes) {
    DynamicTypeImpl dynamic = DynamicTypeImpl.instance;
    int parameterCount = parameterTypes.length;
    List<Type2> types = new List<Type2>(parameterCount);
    if (typeArguments == null) {
      for (int i = 0; i < parameterCount; i++) {
        types[i] = dynamic;
      }
    } else {
      NodeList<TypeName> arguments = typeArguments.arguments;
      int argumentCount = Math.min(arguments.length, parameterCount);
      for (int i = 0; i < argumentCount; i++) {
        types[i] = arguments[i].type;
      }
      for (int i = argumentCount; i < parameterCount; i++) {
        types[i] = dynamic;
      }
    }
    return types;
  }

  /**
   * Return the class element that represents the class whose name was provided.
   *
   * @param identifier the name from the declaration of a class
   * @return the class element that represents the class
   */
  ClassElementImpl getClassElement(SimpleIdentifier identifier) {
    // TODO(brianwilkerson) Seems like we should be using ClassDeclaration.getElement().
    if (identifier == null) {
      // TODO(brianwilkerson) Report this
      // Internal error: We should never build a class declaration without a name.
      return null;
    }
    Element element = identifier.staticElement;
    if (element is! ClassElementImpl) {
      // TODO(brianwilkerson) Report this
      // Internal error: Failed to create an element for a class declaration.
      return null;
    }
    return element as ClassElementImpl;
  }

  /**
   * Return an array containing all of the elements associated with the parameters in the given
   * list.
   *
   * @param parameterList the list of parameters whose elements are to be returned
   * @return the elements associated with the parameters
   */
  List<ParameterElement> getElements(FormalParameterList parameterList) {
    List<ParameterElement> elements = new List<ParameterElement>();
    for (FormalParameter parameter in parameterList.parameters) {
      ParameterElement element = parameter.identifier.staticElement as ParameterElement;
      // TODO(brianwilkerson) Understand why the element would be null.
      if (element != null) {
        elements.add(element);
      }
    }
    return new List.from(elements);
  }

  /**
   * The number of type arguments in the given type name does not match the number of parameters in
   * the corresponding class element. Return the error code that should be used to report this
   * error.
   *
   * @param node the type name with the wrong number of type arguments
   * @return the error code that should be used to report that the wrong number of type arguments
   *         were provided
   */
  ErrorCode getInvalidTypeParametersErrorCode(TypeName node) {
    AstNode parent = node.parent;
    if (parent is ConstructorName) {
      parent = parent.parent;
      if (parent is InstanceCreationExpression) {
        if ((parent as InstanceCreationExpression).isConst) {
          return CompileTimeErrorCode.CONST_WITH_INVALID_TYPE_PARAMETERS;
        } else {
          return StaticWarningCode.NEW_WITH_INVALID_TYPE_PARAMETERS;
        }
      }
    }
    return StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS;
  }

  /**
   * Checks if the given type name is the target in a redirected constructor.
   *
   * @param typeName the type name to analyze
   * @return some [RedirectingConstructorKind] if the given type name is used as the type in a
   *         redirected constructor, or `null` otherwise
   */
  RedirectingConstructorKind getRedirectingConstructorKind(TypeName typeName) {
    AstNode parent = typeName.parent;
    if (parent is ConstructorName) {
      ConstructorName constructorName = parent as ConstructorName;
      parent = constructorName.parent;
      if (parent is ConstructorDeclaration) {
        ConstructorDeclaration constructorDeclaration = parent as ConstructorDeclaration;
        if (identical(constructorDeclaration.redirectedConstructor, constructorName)) {
          if (constructorDeclaration.constKeyword != null) {
            return RedirectingConstructorKind.CONST;
          }
          return RedirectingConstructorKind.NORMAL;
        }
      }
    }
    return null;
  }

  /**
   * Return the type represented by the given type name.
   *
   * @param typeName the type name representing the type to be returned
   * @return the type represented by the type name
   */
  Type2 getType(TypeName typeName) {
    Type2 type = typeName.type;
    if (type == null) {
      return _dynamicType;
    }
    return type;
  }

  /**
   * Return the type arguments associated with the given type.
   *
   * @param type the type whole type arguments are to be returned
   * @return the type arguments associated with the given type
   */
  List<Type2> getTypeArguments(Type2 type) {
    if (type is InterfaceType) {
      return type.typeArguments;
    } else if (type is FunctionType) {
      return type.typeArguments;
    }
    return TypeImpl.EMPTY_ARRAY;
  }

  /**
   * Returns the simple identifier of the given (may be qualified) type name.
   *
   * @param typeName the (may be qualified) qualified type name
   * @return the simple identifier of the given (may be qualified) type name.
   */
  SimpleIdentifier getTypeSimpleIdentifier(Identifier typeName) {
    if (typeName is SimpleIdentifier) {
      return typeName;
    } else {
      return (typeName as PrefixedIdentifier).identifier;
    }
  }

  /**
   * Given the multiple elements to which a single name could potentially be resolved, return the
   * single interface type that should be used, or `null` if there is no clear choice.
   *
   * @param elements the elements to which a single name could potentially be resolved
   * @return the single interface type that should be used for the type name
   */
  InterfaceType getTypeWhenMultiplyDefined(List<Element> elements) {
    InterfaceType type = null;
    for (Element element in elements) {
      if (element is ClassElement) {
        if (type != null) {
          return null;
        }
        type = element.type;
      }
    }
    return type;
  }

  /**
   * Checks if the given type name is used as the type in an as expression.
   *
   * @param typeName the type name to analyzer
   * @return `true` if the given type name is used as the type in an as expression
   */
  bool isTypeNameInAsExpression(TypeName typeName) {
    AstNode parent = typeName.parent;
    if (parent is AsExpression) {
      AsExpression asExpression = parent;
      return identical(asExpression.type, typeName);
    }
    return false;
  }

  /**
   * Checks if the given type name is used as the exception type in a catch clause.
   *
   * @param typeName the type name to analyzer
   * @return `true` if the given type name is used as the exception type in a catch clause
   */
  bool isTypeNameInCatchClause(TypeName typeName) {
    AstNode parent = typeName.parent;
    if (parent is CatchClause) {
      CatchClause catchClause = parent;
      return identical(catchClause.exceptionType, typeName);
    }
    return false;
  }

  /**
   * Checks if the given type name is used as the type in an instance creation expression.
   *
   * @param typeName the type name to analyzer
   * @return `true` if the given type name is used as the type in an instance creation
   *         expression
   */
  bool isTypeNameInInstanceCreationExpression(TypeName typeName) {
    AstNode parent = typeName.parent;
    if (parent is ConstructorName && parent.parent is InstanceCreationExpression) {
      ConstructorName constructorName = parent;
      return constructorName != null && identical(constructorName.type, typeName);
    }
    return false;
  }

  /**
   * Checks if the given type name is used as the type in an is expression.
   *
   * @param typeName the type name to analyzer
   * @return `true` if the given type name is used as the type in an is expression
   */
  bool isTypeNameInIsExpression(TypeName typeName) {
    AstNode parent = typeName.parent;
    if (parent is IsExpression) {
      IsExpression isExpression = parent;
      return identical(isExpression.type, typeName);
    }
    return false;
  }

  /**
   * Checks if the given type name used in a type argument list.
   *
   * @param typeName the type name to analyzer
   * @return `true` if the given type name is in a type argument list
   */
  bool isTypeNameInTypeArgumentList(TypeName typeName) => typeName.parent is TypeArgumentList;

  /**
   * Record that the static type of the given node is the given type.
   *
   * @param expression the node whose type is to be recorded
   * @param type the static type of the node
   */
  Object recordType(Expression expression, Type2 type) {
    if (type == null) {
      expression.staticType = _dynamicType;
    } else {
      expression.staticType = type;
    }
    return null;
  }

  /**
   * Resolve the types in the given with and implements clauses and associate those types with the
   * given class element.
   *
   * @param classElement the class element with which the mixin and interface types are to be
   *          associated
   * @param withClause the with clause to be resolved
   * @param implementsClause the implements clause to be resolved
   */
  void resolve(ClassElementImpl classElement, WithClause withClause, ImplementsClause implementsClause) {
    if (withClause != null) {
      List<InterfaceType> mixinTypes = resolveTypes(withClause.mixinTypes, CompileTimeErrorCode.MIXIN_OF_NON_CLASS, CompileTimeErrorCode.MIXIN_OF_NON_CLASS);
      if (classElement != null) {
        classElement.mixins = mixinTypes;
      }
    }
    if (implementsClause != null) {
      NodeList<TypeName> interfaces = implementsClause.interfaces;
      List<InterfaceType> interfaceTypes = resolveTypes(interfaces, CompileTimeErrorCode.IMPLEMENTS_NON_CLASS, CompileTimeErrorCode.IMPLEMENTS_DYNAMIC);
      if (classElement != null) {
        classElement.interfaces = interfaceTypes;
      }
      // TODO(brianwilkerson) Move the following checks to ErrorVerifier.
      List<TypeName> typeNames = new List.from(interfaces);
      List<bool> detectedRepeatOnIndex = new List<bool>.filled(typeNames.length, false);
      for (int i = 0; i < detectedRepeatOnIndex.length; i++) {
        detectedRepeatOnIndex[i] = false;
      }
      for (int i = 0; i < typeNames.length; i++) {
        TypeName typeName = typeNames[i];
        if (!detectedRepeatOnIndex[i]) {
          Element element = typeName.name.staticElement;
          for (int j = i + 1; j < typeNames.length; j++) {
            TypeName typeName2 = typeNames[j];
            Identifier identifier2 = typeName2.name;
            String name2 = identifier2.name;
            Element element2 = identifier2.staticElement;
            if (element != null && element == element2) {
              detectedRepeatOnIndex[j] = true;
              reportErrorForNode(CompileTimeErrorCode.IMPLEMENTS_REPEATED, typeName2, [name2]);
            }
          }
        }
      }
    }
  }

  /**
   * Return the type specified by the given name.
   *
   * @param typeName the type name specifying the type to be returned
   * @param nonTypeError the error to produce if the type name is defined to be something other than
   *          a type
   * @param dynamicTypeError the error to produce if the type name is "dynamic"
   * @return the type specified by the type name
   */
  InterfaceType resolveType(TypeName typeName, ErrorCode nonTypeError, ErrorCode dynamicTypeError) {
    Type2 type = typeName.type;
    if (type is InterfaceType) {
      return type;
    }
    // If the type is not an InterfaceType, then visitTypeName() sets the type to be a DynamicTypeImpl
    Identifier name = typeName.name;
    if (name.name == sc.Keyword.DYNAMIC.syntax) {
      reportErrorForNode(dynamicTypeError, name, [name.name]);
    } else {
      reportErrorForNode(nonTypeError, name, [name.name]);
    }
    return null;
  }

  /**
   * Resolve the types in the given list of type names.
   *
   * @param typeNames the type names to be resolved
   * @param nonTypeError the error to produce if the type name is defined to be something other than
   *          a type
   * @param dynamicTypeError the error to produce if the type name is "dynamic"
   * @return an array containing all of the types that were resolved.
   */
  List<InterfaceType> resolveTypes(NodeList<TypeName> typeNames, ErrorCode nonTypeError, ErrorCode dynamicTypeError) {
    List<InterfaceType> types = new List<InterfaceType>();
    for (TypeName typeName in typeNames) {
      InterfaceType type = resolveType(typeName, nonTypeError, dynamicTypeError);
      if (type != null) {
        types.add(type);
      }
    }
    return new List.from(types);
  }

  void setElement(Identifier typeName, Element element) {
    if (element != null) {
      if (typeName is SimpleIdentifier) {
        typeName.staticElement = element;
      } else if (typeName is PrefixedIdentifier) {
        PrefixedIdentifier identifier = typeName;
        identifier.identifier.staticElement = element;
        SimpleIdentifier prefix = identifier.prefix;
        Element prefixElement = nameScope.lookup(prefix, definingLibrary);
        if (prefixElement != null) {
          prefix.staticElement = prefixElement;
        }
      }
    }
  }

  /**
   * Given a parameter element, create a function type based on the given return type and parameter
   * list and associate the created type with the element.
   *
   * @param element the parameter element whose type is to be set
   * @param returnType the (possibly `null`) return type of the function
   * @param parameterList the list of parameters to the function
   */
  void setFunctionTypedParameterType(ParameterElementImpl element, TypeName returnType, FormalParameterList parameterList) {
    List<ParameterElement> parameters = getElements(parameterList);
    FunctionTypeAliasElementImpl aliasElement = new FunctionTypeAliasElementImpl(null);
    aliasElement.synthetic = true;
    aliasElement.shareParameters(parameters);
    aliasElement.returnType = computeReturnType(returnType);
    FunctionTypeImpl type = new FunctionTypeImpl.con2(aliasElement);
    ClassElement definingClass = element.getAncestor((element) => element is ClassElement);
    if (definingClass != null) {
      aliasElement.shareTypeParameters(definingClass.typeParameters);
      type.typeArguments = definingClass.type.typeArguments;
    } else {
      FunctionTypeAliasElement alias = element.getAncestor((element) => element is FunctionTypeAliasElement);
      while (alias != null && alias.isSynthetic) {
        alias = alias.getAncestor((element) => element is FunctionTypeAliasElement);
      }
      if (alias != null) {
        aliasElement.typeParameters = alias.typeParameters;
        type.typeArguments = alias.type.typeArguments;
      } else {
        type.typeArguments = TypeImpl.EMPTY_ARRAY;
      }
    }
    element.type = type;
  }
}

/**
 * Kind of the redirecting constructor.
 */
class RedirectingConstructorKind extends Enum<RedirectingConstructorKind> {
  static final RedirectingConstructorKind CONST = new RedirectingConstructorKind('CONST', 0);

  static final RedirectingConstructorKind NORMAL = new RedirectingConstructorKind('NORMAL', 1);

  static final List<RedirectingConstructorKind> values = [CONST, NORMAL];

  RedirectingConstructorKind(String name, int ordinal) : super(name, ordinal);
}

class UnifyingAstVisitor_TypeResolverVisitor_visitClassDeclarationInScope extends UnifyingAstVisitor<Object> {
  final TypeResolverVisitor TypeResolverVisitor_this;

  List<ClassMember> nonFields;

  UnifyingAstVisitor_TypeResolverVisitor_visitClassDeclarationInScope(this.TypeResolverVisitor_this, this.nonFields) : super();

  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    nonFields.add(node);
    return null;
  }

  Object visitMethodDeclaration(MethodDeclaration node) {
    nonFields.add(node);
    return null;
  }

  Object visitNode(AstNode node) => node.accept(TypeResolverVisitor_this);
}

/**
 * Instances of the class `VariableResolverVisitor` are used to resolve
 * [SimpleIdentifier]s to local variables and formal parameters.
 */
class VariableResolverVisitor extends ScopedVisitor {
  /**
   * The method or function that we are currently visiting, or `null` if we are not inside a
   * method or function.
   */
  ExecutableElement _enclosingFunction;

  /**
   * Initialize a newly created visitor to resolve the nodes in a compilation unit.
   *
   * @param library the library containing the compilation unit being resolved
   * @param source the source representing the compilation unit being visited
   * @param typeProvider the object used to access the types from the core library
   */
  VariableResolverVisitor.con1(Library library, Source source, TypeProvider typeProvider) : super.con1(library, source, typeProvider);

  /**
   * Initialize a newly created visitor to resolve the nodes in an AST node.
   *
   * @param definingLibrary the element for the library containing the node being visited
   * @param source the source representing the compilation unit containing the node being visited
   * @param typeProvider the object used to access the types from the core library
   * @param nameScope the scope used to resolve identifiers in the node that will first be visited
   * @param errorListener the error listener that will be informed of any errors that are found
   *          during resolution
   */
  VariableResolverVisitor.con2(LibraryElement definingLibrary, Source source, TypeProvider typeProvider, Scope nameScope, AnalysisErrorListener errorListener) : super.con3(definingLibrary, source, typeProvider, nameScope, errorListener);

  Object visitFunctionDeclaration(FunctionDeclaration node) {
    ExecutableElement outerFunction = _enclosingFunction;
    try {
      _enclosingFunction = node.element;
      return super.visitFunctionDeclaration(node);
    } finally {
      _enclosingFunction = outerFunction;
    }
  }

  Object visitFunctionExpression(FunctionExpression node) {
    if (node.parent is! FunctionDeclaration) {
      ExecutableElement outerFunction = _enclosingFunction;
      try {
        _enclosingFunction = node.element;
        return super.visitFunctionExpression(node);
      } finally {
        _enclosingFunction = outerFunction;
      }
    } else {
      return super.visitFunctionExpression(node);
    }
  }

  Object visitSimpleIdentifier(SimpleIdentifier node) {
    // Ignore if already resolved - declaration or type.
    if (node.staticElement != null) {
      return null;
    }
    // Ignore if qualified.
    AstNode parent = node.parent;
    if (parent is PrefixedIdentifier && identical(parent.identifier, node)) {
      return null;
    }
    if (parent is PropertyAccess && identical(parent.propertyName, node)) {
      return null;
    }
    if (parent is MethodInvocation && identical(parent.methodName, node)) {
      return null;
    }
    if (parent is ConstructorName) {
      return null;
    }
    if (parent is Label) {
      return null;
    }
    // Prepare VariableElement.
    Element element = nameScope.lookup(node, definingLibrary);
    if (element is! VariableElement) {
      return null;
    }
    // Must be local or parameter.
    ElementKind kind = element.kind;
    if (identical(kind, ElementKind.LOCAL_VARIABLE)) {
      node.staticElement = element;
      if (node.inSetterContext()) {
        LocalVariableElementImpl variableImpl = element as LocalVariableElementImpl;
        variableImpl.markPotentiallyMutatedInScope();
        if (element.enclosingElement != _enclosingFunction) {
          variableImpl.markPotentiallyMutatedInClosure();
        }
      }
    } else if (identical(kind, ElementKind.PARAMETER)) {
      node.staticElement = element;
      if (node.inSetterContext()) {
        ParameterElementImpl parameterImpl = element as ParameterElementImpl;
        parameterImpl.markPotentiallyMutatedInScope();
        // If we are in some closure, check if it is not the same as where variable is declared.
        if (_enclosingFunction != null && (element.enclosingElement != _enclosingFunction)) {
          parameterImpl.markPotentiallyMutatedInClosure();
        }
      }
    }
    return null;
  }
}

/**
 * Instances of the class `ClassScope` implement the scope defined by a class.
 */
class ClassScope extends EnclosedScope {
  /**
   * Initialize a newly created scope enclosed within another scope.
   *
   * @param enclosingScope the scope in which this scope is lexically enclosed
   * @param typeElement the element representing the type represented by this scope
   */
  ClassScope(Scope enclosingScope, ClassElement typeElement) : super(new EnclosedScope(enclosingScope)) {
    defineTypeParameters(typeElement);
    defineMembers(typeElement);
  }

  AnalysisError getErrorForDuplicate(Element existing, Element duplicate) {
    if (existing is PropertyAccessorElement && duplicate is MethodElement) {
      if (existing.nameOffset < duplicate.nameOffset) {
        return new AnalysisError.con2(duplicate.source, duplicate.nameOffset, duplicate.displayName.length, CompileTimeErrorCode.METHOD_AND_GETTER_WITH_SAME_NAME, [existing.displayName]);
      } else {
        return new AnalysisError.con2(existing.source, existing.nameOffset, existing.displayName.length, CompileTimeErrorCode.GETTER_AND_METHOD_WITH_SAME_NAME, [existing.displayName]);
      }
    }
    return super.getErrorForDuplicate(existing, duplicate);
  }

  /**
   * Define the instance members defined by the class.
   *
   * @param typeElement the element representing the type represented by this scope
   */
  void defineMembers(ClassElement typeElement) {
    for (PropertyAccessorElement accessor in typeElement.accessors) {
      define(accessor);
    }
    for (MethodElement method in typeElement.methods) {
      define(method);
    }
  }

  /**
   * Define the type parameters for the class.
   *
   * @param typeElement the element representing the type represented by this scope
   */
  void defineTypeParameters(ClassElement typeElement) {
    Scope parameterScope = enclosingScope;
    for (TypeParameterElement typeParameter in typeElement.typeParameters) {
      parameterScope.define(typeParameter);
    }
  }
}

/**
 * Instances of the class `EnclosedScope` implement a scope that is lexically enclosed in
 * another scope.
 */
class EnclosedScope extends Scope {
  /**
   * The scope in which this scope is lexically enclosed.
   */
  final Scope enclosingScope;

  /**
   * A table mapping names that will be defined in this scope, but right now are not initialized.
   * According to the scoping rules these names are hidden, even if they were defined in an outer
   * scope.
   */
  Map<String, Element> _hiddenElements = new Map<String, Element>();

  /**
   * A flag indicating whether there are any names defined in this scope.
   */
  bool _hasHiddenName = false;

  /**
   * Initialize a newly created scope enclosed within another scope.
   *
   * @param enclosingScope the scope in which this scope is lexically enclosed
   */
  EnclosedScope(this.enclosingScope);

  AnalysisErrorListener get errorListener => enclosingScope.errorListener;

  /**
   * Record that given element is declared in this scope, but hasn't been initialized yet, so it is
   * error to use. If there is already an element with the given name defined in an outer scope,
   * then it will become unavailable.
   *
   * @param element the element declared, but not initialized in this scope
   */
  void hide(Element element) {
    if (element != null) {
      String name = element.name;
      if (name != null && !name.isEmpty) {
        _hiddenElements[name] = element;
        _hasHiddenName = true;
      }
    }
  }

  Element lookup3(Identifier identifier, String name, LibraryElement referencingLibrary) {
    Element element = localLookup(name, referencingLibrary);
    if (element != null) {
      return element;
    }
    // May be there is a hidden Element.
    if (_hasHiddenName) {
      Element hiddenElement = _hiddenElements[name];
      if (hiddenElement != null) {
        errorListener.onError(new AnalysisError.con2(getSource(identifier), identifier.offset, identifier.length, CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION, []));
        return hiddenElement;
      }
    }
    // Check enclosing scope.
    return enclosingScope.lookup3(identifier, name, referencingLibrary);
  }
}

/**
 * Instances of the class `FunctionScope` implement the scope defined by a function.
 */
class FunctionScope extends EnclosedScope {
  ExecutableElement _functionElement;

  bool _parametersDefined = false;

  /**
   * Initialize a newly created scope enclosed within another scope.
   *
   * @param enclosingScope the scope in which this scope is lexically enclosed
   * @param functionElement the element representing the type represented by this scope
   */
  FunctionScope(Scope enclosingScope, ExecutableElement functionElement) : super(new EnclosedScope(enclosingScope)) {
    this._functionElement = functionElement;
  }

  /**
   * Define the parameters for the given function in the scope that encloses this function.
   */
  void defineParameters() {
    if (_parametersDefined) {
      return;
    }
    _parametersDefined = true;
    Scope parameterScope = enclosingScope;
    if (_functionElement.enclosingElement is ExecutableElement) {
      String name = _functionElement.name;
      if (name != null && !name.isEmpty) {
        parameterScope.define(_functionElement);
      }
    }
    for (ParameterElement parameter in _functionElement.parameters) {
      if (!parameter.isInitializingFormal) {
        parameterScope.define(parameter);
      }
    }
  }
}

/**
 * Instances of the class `FunctionTypeScope` implement the scope defined by a function type
 * alias.
 */
class FunctionTypeScope extends EnclosedScope {
  FunctionTypeAliasElement _typeElement;

  bool _parametersDefined = false;

  /**
   * Initialize a newly created scope enclosed within another scope.
   *
   * @param enclosingScope the scope in which this scope is lexically enclosed
   * @param typeElement the element representing the type alias represented by this scope
   */
  FunctionTypeScope(Scope enclosingScope, FunctionTypeAliasElement typeElement) : super(new EnclosedScope(enclosingScope)) {
    this._typeElement = typeElement;
    defineTypeParameters();
  }

  /**
   * Define the parameters for the function type alias.
   *
   * @param typeElement the element representing the type represented by this scope
   */
  void defineParameters() {
    if (_parametersDefined) {
      return;
    }
    _parametersDefined = true;
    for (ParameterElement parameter in _typeElement.parameters) {
      define(parameter);
    }
  }

  /**
   * Define the type parameters for the function type alias.
   *
   * @param typeElement the element representing the type represented by this scope
   */
  void defineTypeParameters() {
    Scope typeParameterScope = enclosingScope;
    for (TypeParameterElement typeParameter in _typeElement.typeParameters) {
      typeParameterScope.define(typeParameter);
    }
  }
}

/**
 * Instances of the class `LabelScope` represent a scope in which a single label is defined.
 */
class LabelScope {
  /**
   * The label scope enclosing this label scope.
   */
  LabelScope _outerScope;

  /**
   * The label defined in this scope.
   */
  String _label;

  /**
   * The element to which the label resolves.
   */
  LabelElement _element;

  /**
   * The marker used to look up a label element for an unlabeled `break` or `continue`.
   */
  static String EMPTY_LABEL = "";

  /**
   * The label element returned for scopes that can be the target of an unlabeled `break` or
   * `continue`.
   */
  static SimpleIdentifier _EMPTY_LABEL_IDENTIFIER = new SimpleIdentifier(new sc.StringToken(sc.TokenType.IDENTIFIER, "", 0));

  /**
   * Initialize a newly created scope to represent the potential target of an unlabeled
   * `break` or `continue`.
   *
   * @param outerScope the label scope enclosing the new label scope
   * @param onSwitchStatement `true` if this label is associated with a `switch`
   *          statement
   * @param onSwitchMember `true` if this label is associated with a `switch` member
   */
  LabelScope.con1(LabelScope outerScope, bool onSwitchStatement, bool onSwitchMember) : this.con2(outerScope, EMPTY_LABEL, new LabelElementImpl(_EMPTY_LABEL_IDENTIFIER, onSwitchStatement, onSwitchMember));

  /**
   * Initialize a newly created scope to represent the given label.
   *
   * @param outerScope the label scope enclosing the new label scope
   * @param label the label defined in this scope
   * @param element the element to which the label resolves
   */
  LabelScope.con2(LabelScope outerScope, String label, LabelElement element) {
    this._outerScope = outerScope;
    this._label = label;
    this._element = element;
  }

  /**
   * Return the label element corresponding to the given label, or `null` if the given label
   * is not defined in this scope.
   *
   * @param targetLabel the label being looked up
   * @return the label element corresponding to the given label
   */
  LabelElement lookup(SimpleIdentifier targetLabel) => lookup2(targetLabel.name);

  /**
   * Return the label element corresponding to the given label, or `null` if the given label
   * is not defined in this scope.
   *
   * @param targetLabel the label being looked up
   * @return the label element corresponding to the given label
   */
  LabelElement lookup2(String targetLabel) {
    if (_label == targetLabel) {
      return _element;
    } else if (_outerScope != null) {
      return _outerScope.lookup2(targetLabel);
    } else {
      return null;
    }
  }
}

/**
 * Instances of the class `LibraryImportScope` represent the scope containing all of the names
 * available from imported libraries.
 */
class LibraryImportScope extends Scope {
  /**
   * The element representing the library in which this scope is enclosed.
   */
  LibraryElement _definingLibrary;

  /**
   * The listener that is to be informed when an error is encountered.
   */
  final AnalysisErrorListener errorListener;

  /**
   * A list of the namespaces representing the names that are available in this scope from imported
   * libraries.
   */
  List<Namespace> _importedNamespaces;

  /**
   * Initialize a newly created scope representing the names imported into the given library.
   *
   * @param definingLibrary the element representing the library that imports the names defined in
   *          this scope
   * @param errorListener the listener that is to be informed when an error is encountered
   */
  LibraryImportScope(LibraryElement definingLibrary, this.errorListener) {
    this._definingLibrary = definingLibrary;
    createImportedNamespaces(definingLibrary);
  }

  void define(Element element) {
    if (!Scope.isPrivateName(element.displayName)) {
      super.define(element);
    }
  }

  Element lookup3(Identifier identifier, String name, LibraryElement referencingLibrary) {
    Element foundElement = localLookup(name, referencingLibrary);
    if (foundElement != null) {
      return foundElement;
    }
    for (Namespace nameSpace in _importedNamespaces) {
      Element element = nameSpace.get(name);
      if (element != null) {
        if (foundElement == null) {
          foundElement = element;
        } else if (foundElement != element) {
          foundElement = MultiplyDefinedElementImpl.fromElements(_definingLibrary.context, foundElement, element);
        }
      }
    }
    if (foundElement is MultiplyDefinedElementImpl) {
      foundElement = removeSdkElements(identifier, name, foundElement as MultiplyDefinedElementImpl);
    }
    if (foundElement is MultiplyDefinedElementImpl) {
      String foundEltName = foundElement.displayName;
      List<Element> conflictingMembers = (foundElement as MultiplyDefinedElementImpl).conflictingElements;
      String libName1 = getLibraryName(conflictingMembers[0], "");
      String libName2 = getLibraryName(conflictingMembers[1], "");
      // TODO (jwren) Change the error message to include a list of all library names instead of
      // just the first two
      errorListener.onError(new AnalysisError.con2(getSource(identifier), identifier.offset, identifier.length, StaticWarningCode.AMBIGUOUS_IMPORT, [foundEltName, libName1, libName2]));
      return foundElement;
    }
    if (foundElement != null) {
      defineWithoutChecking2(name, foundElement);
    }
    return foundElement;
  }

  /**
   * Create all of the namespaces associated with the libraries imported into this library. The
   * names are not added to this scope, but are stored for later reference.
   *
   * @param definingLibrary the element representing the library that imports the libraries for
   *          which namespaces will be created
   */
  void createImportedNamespaces(LibraryElement definingLibrary) {
    NamespaceBuilder builder = new NamespaceBuilder();
    List<ImportElement> imports = definingLibrary.imports;
    int count = imports.length;
    _importedNamespaces = new List<Namespace>(count);
    for (int i = 0; i < count; i++) {
      _importedNamespaces[i] = builder.createImportNamespace(imports[i]);
    }
  }

  /**
   * Returns the name of the library that defines given element.
   *
   * @param element the element to get library name
   * @param def the default name to use
   * @return the name of the library that defines given element
   */
  String getLibraryName(Element element, String def) {
    if (element == null) {
      return def;
    }
    LibraryElement library = element.library;
    if (library == null) {
      return def;
    }
    return library.definingCompilationUnit.displayName;
  }

  /**
   * Given a collection of elements that a single name could all be mapped to, remove from the list
   * all of the names defined in the SDK. Return the element(s) that remain.
   *
   * @param identifier the identifier node to lookup element for, used to report correct kind of a
   *          problem and associate problem with
   * @param name the name associated with the element
   * @param foundElement the element encapsulating the collection of elements
   * @return all of the elements that are not defined in the SDK
   */
  Element removeSdkElements(Identifier identifier, String name, MultiplyDefinedElementImpl foundElement) {
    List<Element> conflictingMembers = foundElement.conflictingElements;
    int length = conflictingMembers.length;
    int to = 0;
    Element sdkElement = null;
    for (Element member in conflictingMembers) {
      if (member.library.isInSdk) {
        sdkElement = member;
      } else {
        conflictingMembers[to++] = member;
      }
    }
    if (sdkElement != null && to > 0) {
      String sdkLibName = getLibraryName(sdkElement, "");
      String otherLibName = getLibraryName(conflictingMembers[0], "");
      errorListener.onError(new AnalysisError.con2(getSource(identifier), identifier.offset, identifier.length, StaticWarningCode.CONFLICTING_DART_IMPORT, [name, sdkLibName, otherLibName]));
    }
    if (to == length) {
      // None of the members were removed
      return foundElement;
    } else if (to == 1) {
      // All but one member was removed
      return conflictingMembers[0];
    } else if (to == 0) {
      // All members were removed
      AnalysisEngine.instance.logger.logInformation("Multiply defined SDK element: ${foundElement}");
      return foundElement;
    }
    List<Element> remaining = new List<Element>(to);
    JavaSystem.arraycopy(conflictingMembers, 0, remaining, 0, to);
    return new MultiplyDefinedElementImpl(_definingLibrary.context, remaining);
  }
}

/**
 * Instances of the class `LibraryScope` implement a scope containing all of the names defined
 * in a given library.
 */
class LibraryScope extends EnclosedScope {
  /**
   * Initialize a newly created scope representing the names defined in the given library.
   *
   * @param definingLibrary the element representing the library represented by this scope
   * @param errorListener the listener that is to be informed when an error is encountered
   */
  LibraryScope(LibraryElement definingLibrary, AnalysisErrorListener errorListener) : super(new LibraryImportScope(definingLibrary, errorListener)) {
    defineTopLevelNames(definingLibrary);
  }

  AnalysisError getErrorForDuplicate(Element existing, Element duplicate) {
    if (existing is PrefixElement) {
      // TODO(scheglov) consider providing actual 'nameOffset' from the synthetic accessor
      int offset = duplicate.nameOffset;
      if (duplicate is PropertyAccessorElement) {
        PropertyAccessorElement accessor = duplicate;
        if (accessor.isSynthetic) {
          offset = accessor.variable.nameOffset;
        }
      }
      return new AnalysisError.con2(duplicate.source, offset, duplicate.displayName.length, CompileTimeErrorCode.PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER, [existing.displayName]);
    }
    return super.getErrorForDuplicate(existing, duplicate);
  }

  /**
   * Add to this scope all of the public top-level names that are defined in the given compilation
   * unit.
   *
   * @param compilationUnit the compilation unit defining the top-level names to be added to this
   *          scope
   */
  void defineLocalNames(CompilationUnitElement compilationUnit) {
    for (PropertyAccessorElement element in compilationUnit.accessors) {
      define(element);
    }
    for (FunctionElement element in compilationUnit.functions) {
      define(element);
    }
    for (FunctionTypeAliasElement element in compilationUnit.functionTypeAliases) {
      define(element);
    }
    for (ClassElement element in compilationUnit.types) {
      define(element);
    }
  }

  /**
   * Add to this scope all of the names that are explicitly defined in the given library.
   *
   * @param definingLibrary the element representing the library that defines the names in this
   *          scope
   */
  void defineTopLevelNames(LibraryElement definingLibrary) {
    for (PrefixElement prefix in definingLibrary.prefixes) {
      define(prefix);
    }
    defineLocalNames(definingLibrary.definingCompilationUnit);
    for (CompilationUnitElement compilationUnit in definingLibrary.parts) {
      defineLocalNames(compilationUnit);
    }
  }
}

/**
 * Instances of the class `Namespace` implement a mapping of identifiers to the elements
 * represented by those identifiers. Namespaces are the building blocks for scopes.
 */
class Namespace {
  /**
   * A table mapping names that are defined in this namespace to the element representing the thing
   * declared with that name.
   */
  Map<String, Element> _definedNames;

  /**
   * An empty namespace.
   */
  static Namespace EMPTY = new Namespace(new Map<String, Element>());

  /**
   * Initialize a newly created namespace to have the given defined names.
   *
   * @param definedNames the mapping from names that are defined in this namespace to the
   *          corresponding elements
   */
  Namespace(Map<String, Element> definedNames) {
    this._definedNames = definedNames;
  }

  /**
   * Return the element in this namespace that is available to the containing scope using the given
   * name.
   *
   * @param name the name used to reference the
   * @return the element represented by the given identifier
   */
  Element get(String name) => _definedNames[name];

  /**
   * Return a table containing the same mappings as those defined by this namespace.
   *
   * @return a table containing the same mappings as those defined by this namespace
   */
  Map<String, Element> get definedNames => new Map<String, Element>.from(_definedNames);
}

/**
 * Instances of the class `NamespaceBuilder` are used to build a `Namespace`. Namespace
 * builders are thread-safe and re-usable.
 */
class NamespaceBuilder {
  /**
   * Create a namespace representing the export namespace of the given [ExportElement].
   *
   * @param element the export element whose export namespace is to be created
   * @return the export namespace that was created
   */
  Namespace createExportNamespace(ExportElement element) {
    LibraryElement exportedLibrary = element.exportedLibrary;
    if (exportedLibrary == null) {
      //
      // The exported library will be null if the URI does not reference a valid library.
      //
      return Namespace.EMPTY;
    }
    Map<String, Element> definedNames = createExportMapping(exportedLibrary, new Set<LibraryElement>());
    definedNames = apply(definedNames, element.combinators);
    return new Namespace(definedNames);
  }

  /**
   * Create a namespace representing the export namespace of the given library.
   *
   * @param library the library whose export namespace is to be created
   * @return the export namespace that was created
   */
  Namespace createExportNamespace2(LibraryElement library) => new Namespace(createExportMapping(library, new Set<LibraryElement>()));

  /**
   * Create a namespace representing the import namespace of the given library.
   *
   * @param library the library whose import namespace is to be created
   * @return the import namespace that was created
   */
  Namespace createImportNamespace(ImportElement element) {
    LibraryElement importedLibrary = element.importedLibrary;
    if (importedLibrary == null) {
      //
      // The imported library will be null if the URI does not reference a valid library.
      //
      return Namespace.EMPTY;
    }
    Map<String, Element> definedNames = createExportMapping(importedLibrary, new Set<LibraryElement>());
    definedNames = apply(definedNames, element.combinators);
    definedNames = apply2(definedNames, element.prefix);
    return new Namespace(definedNames);
  }

  /**
   * Create a namespace representing the public namespace of the given library.
   *
   * @param library the library whose public namespace is to be created
   * @return the public namespace that was created
   */
  Namespace createPublicNamespace(LibraryElement library) {
    Map<String, Element> definedNames = new Map<String, Element>();
    addPublicNames(definedNames, library.definingCompilationUnit);
    for (CompilationUnitElement compilationUnit in library.parts) {
      addPublicNames(definedNames, compilationUnit);
    }
    return new Namespace(definedNames);
  }

  /**
   * Add all of the names in the given namespace to the given mapping table.
   *
   * @param definedNames the mapping table to which the names in the given namespace are to be added
   * @param namespace the namespace containing the names to be added to this namespace
   */
  void addAll(Map<String, Element> definedNames, Map<String, Element> newNames) {
    for (MapEntry<String, Element> entry in getMapEntrySet(newNames)) {
      definedNames[entry.getKey()] = entry.getValue();
    }
  }

  /**
   * Add all of the names in the given namespace to the given mapping table.
   *
   * @param definedNames the mapping table to which the names in the given namespace are to be added
   * @param namespace the namespace containing the names to be added to this namespace
   */
  void addAll2(Map<String, Element> definedNames, Namespace namespace) {
    if (namespace != null) {
      addAll(definedNames, namespace.definedNames);
    }
  }

  /**
   * Add the given element to the given mapping table if it has a publicly visible name.
   *
   * @param definedNames the mapping table to which the public name is to be added
   * @param element the element to be added
   */
  void addIfPublic(Map<String, Element> definedNames, Element element) {
    String name = element.name;
    if (name != null && !Scope.isPrivateName(name)) {
      definedNames[name] = element;
    }
  }

  /**
   * Add to the given mapping table all of the public top-level names that are defined in the given
   * compilation unit.
   *
   * @param definedNames the mapping table to which the public names are to be added
   * @param compilationUnit the compilation unit defining the top-level names to be added to this
   *          namespace
   */
  void addPublicNames(Map<String, Element> definedNames, CompilationUnitElement compilationUnit) {
    for (PropertyAccessorElement element in compilationUnit.accessors) {
      addIfPublic(definedNames, element);
    }
    for (FunctionElement element in compilationUnit.functions) {
      addIfPublic(definedNames, element);
    }
    for (FunctionTypeAliasElement element in compilationUnit.functionTypeAliases) {
      addIfPublic(definedNames, element);
    }
    for (ClassElement element in compilationUnit.types) {
      addIfPublic(definedNames, element);
    }
  }

  /**
   * Apply the given combinators to all of the names in the given mapping table.
   *
   * @param definedNames the mapping table to which the namespace operations are to be applied
   * @param combinators the combinators to be applied
   */
  Map<String, Element> apply(Map<String, Element> definedNames, List<NamespaceCombinator> combinators) {
    for (NamespaceCombinator combinator in combinators) {
      if (combinator is HideElementCombinator) {
        hide(definedNames, combinator.hiddenNames);
      } else if (combinator is ShowElementCombinator) {
        definedNames = show(definedNames, combinator.shownNames);
      } else {
        // Internal error.
        AnalysisEngine.instance.logger.logError("Unknown type of combinator: ${combinator.runtimeType.toString()}");
      }
    }
    return definedNames;
  }

  /**
   * Apply the given prefix to all of the names in the table of defined names.
   *
   * @param definedNames the names that were defined before this operation
   * @param prefixElement the element defining the prefix to be added to the names
   */
  Map<String, Element> apply2(Map<String, Element> definedNames, PrefixElement prefixElement) {
    if (prefixElement != null) {
      String prefix = prefixElement.name;
      Map<String, Element> newNames = new Map<String, Element>();
      for (MapEntry<String, Element> entry in getMapEntrySet(definedNames)) {
        newNames["${prefix}.${entry.getKey()}"] = entry.getValue();
      }
      return newNames;
    } else {
      return definedNames;
    }
  }

  /**
   * Create a mapping table representing the export namespace of the given library.
   *
   * @param library the library whose public namespace is to be created
   * @param visitedElements a set of libraries that do not need to be visited when processing the
   *          export directives of the given library because all of the names defined by them will
   *          be added by another library
   * @return the mapping table that was created
   */
  Map<String, Element> createExportMapping(LibraryElement library, Set<LibraryElement> visitedElements) {
    visitedElements.add(library);
    try {
      Map<String, Element> definedNames = new Map<String, Element>();
      for (ExportElement element in library.exports) {
        LibraryElement exportedLibrary = element.exportedLibrary;
        if (exportedLibrary != null && !visitedElements.contains(exportedLibrary)) {
          //
          // The exported library will be null if the URI does not reference a valid library.
          //
          Map<String, Element> exportedNames = createExportMapping(exportedLibrary, visitedElements);
          exportedNames = apply(exportedNames, element.combinators);
          addAll(definedNames, exportedNames);
        }
      }
      addAll2(definedNames, (library.context as InternalAnalysisContext).getPublicNamespace(library));
      return definedNames;
    } finally {
      visitedElements.remove(library);
    }
  }

  /**
   * Hide all of the given names by removing them from the given collection of defined names.
   *
   * @param definedNames the names that were defined before this operation
   * @param hiddenNames the names to be hidden
   */
  void hide(Map<String, Element> definedNames, List<String> hiddenNames) {
    for (String name in hiddenNames) {
      definedNames.remove(name);
      definedNames.remove("${name}=");
    }
  }

  /**
   * Show only the given names by removing all other names from the given collection of defined
   * names.
   *
   * @param definedNames the names that were defined before this operation
   * @param shownNames the names to be shown
   */
  Map<String, Element> show(Map<String, Element> definedNames, List<String> shownNames) {
    Map<String, Element> newNames = new Map<String, Element>();
    for (String name in shownNames) {
      Element element = definedNames[name];
      if (element != null) {
        newNames[name] = element;
      }
      String setterName = "${name}=";
      element = definedNames[setterName];
      if (element != null) {
        newNames[setterName] = element;
      }
    }
    return newNames;
  }
}

/**
 * The abstract class `Scope` defines the behavior common to name scopes used by the resolver
 * to determine which names are visible at any given point in the code.
 */
abstract class Scope {
  /**
   * The prefix used to mark an identifier as being private to its library.
   */
  static int PRIVATE_NAME_PREFIX = 0x5F;

  /**
   * The suffix added to the declared name of a setter when looking up the setter. Used to
   * disambiguate between a getter and a setter that have the same name.
   */
  static String SETTER_SUFFIX = "=";

  /**
   * The name used to look up the method used to implement the unary minus operator. Used to
   * disambiguate between the unary and binary operators.
   */
  static String UNARY_MINUS = "unary-";

  /**
   * Return `true` if the given name is a library-private name.
   *
   * @param name the name being tested
   * @return `true` if the given name is a library-private name
   */
  static bool isPrivateName(String name) => name != null && StringUtilities.startsWithChar(name, PRIVATE_NAME_PREFIX);

  /**
   * A table mapping names that are defined in this scope to the element representing the thing
   * declared with that name.
   */
  Map<String, Element> _definedNames = new Map<String, Element>();

  /**
   * A flag indicating whether there are any names defined in this scope.
   */
  bool _hasName = false;

  /**
   * Add the given element to this scope. If there is already an element with the given name defined
   * in this scope, then an error will be generated and the original element will continue to be
   * mapped to the name. If there is an element with the given name in an enclosing scope, then a
   * warning will be generated but the given element will hide the inherited element.
   *
   * @param element the element to be added to this scope
   */
  void define(Element element) {
    String name = getName(element);
    if (name != null && !name.isEmpty) {
      if (_definedNames.containsKey(name)) {
        errorListener.onError(getErrorForDuplicate(_definedNames[name], element));
      } else {
        _definedNames[name] = element;
        _hasName = true;
      }
    }
  }

  /**
   * Return the scope in which this scope is lexically enclosed.
   *
   * @return the scope in which this scope is lexically enclosed
   */
  Scope get enclosingScope => null;

  /**
   * Return the element with which the given identifier is associated, or `null` if the name
   * is not defined within this scope.
   *
   * @param identifier the identifier associated with the element to be returned
   * @param referencingLibrary the library that contains the reference to the name, used to
   *          implement library-level privacy
   * @return the element with which the given identifier is associated
   */
  Element lookup(Identifier identifier, LibraryElement referencingLibrary) => lookup3(identifier, identifier.name, referencingLibrary);

  /**
   * Add the given element to this scope without checking for duplication or hiding.
   *
   * @param element the element to be added to this scope
   */
  void defineWithoutChecking(Element element) {
    _definedNames[getName(element)] = element;
    _hasName = true;
  }

  /**
   * Add the given element to this scope without checking for duplication or hiding.
   *
   * @param name the name of the element to be added
   * @param element the element to be added to this scope
   */
  void defineWithoutChecking2(String name, Element element) {
    _definedNames[name] = element;
    _hasName = true;
  }

  /**
   * Return the error code to be used when reporting that a name being defined locally conflicts
   * with another element of the same name in the local scope.
   *
   * @param existing the first element to be declared with the conflicting name
   * @param duplicate another element declared with the conflicting name
   * @return the error code used to report duplicate names within a scope
   */
  AnalysisError getErrorForDuplicate(Element existing, Element duplicate) {
    // TODO(brianwilkerson) Customize the error message based on the types of elements that share
    // the same name.
    // TODO(jwren) There are 4 error codes for duplicate, but only 1 is being generated.
    Source source = duplicate.source;
    return new AnalysisError.con2(source, duplicate.nameOffset, duplicate.displayName.length, CompileTimeErrorCode.DUPLICATE_DEFINITION, [existing.displayName]);
  }

  /**
   * Return the listener that is to be informed when an error is encountered.
   *
   * @return the listener that is to be informed when an error is encountered
   */
  AnalysisErrorListener get errorListener;

  /**
   * Return the source that contains the given identifier, or the source associated with this scope
   * if the source containing the identifier could not be determined.
   *
   * @param identifier the identifier whose source is to be returned
   * @return the source that contains the given identifier
   */
  Source getSource(AstNode node) {
    CompilationUnit unit = node.getAncestor((node) => node is CompilationUnit);
    if (unit != null) {
      CompilationUnitElement unitElement = unit.element;
      if (unitElement != null) {
        return unitElement.source;
      }
    }
    return null;
  }

  /**
   * Return the element with which the given name is associated, or `null` if the name is not
   * defined within this scope. This method only returns elements that are directly defined within
   * this scope, not elements that are defined in an enclosing scope.
   *
   * @param name the name associated with the element to be returned
   * @param referencingLibrary the library that contains the reference to the name, used to
   *          implement library-level privacy
   * @return the element with which the given name is associated
   */
  Element localLookup(String name, LibraryElement referencingLibrary) {
    if (_hasName) {
      return _definedNames[name];
    }
    return null;
  }

  /**
   * Return the element with which the given name is associated, or `null` if the name is not
   * defined within this scope.
   *
   * @param identifier the identifier node to lookup element for, used to report correct kind of a
   *          problem and associate problem with
   * @param name the name associated with the element to be returned
   * @param referencingLibrary the library that contains the reference to the name, used to
   *          implement library-level privacy
   * @return the element with which the given name is associated
   */
  Element lookup3(Identifier identifier, String name, LibraryElement referencingLibrary);

  /**
   * Return the name that will be used to look up the given element.
   *
   * @param element the element whose look-up name is to be returned
   * @return the name that will be used to look up the given element
   */
  String getName(Element element) {
    if (element is MethodElement) {
      MethodElement method = element;
      if (method.name == "-" && method.parameters.length == 0) {
        return UNARY_MINUS;
      }
    }
    return element.name;
  }
}

/**
 * Instances of the class `ScopeBuilder` build the scope for a given node in an AST structure.
 * At the moment, this class only handles top-level and class-level declarations.
 */
class ScopeBuilder {
  /**
   * Return the scope in which the given AST structure should be resolved.
   *
   * @param node the root of the AST structure to be resolved
   * @param errorListener the listener to which analysis errors will be reported
   * @return the scope in which the given AST structure should be resolved
   * @throws AnalysisException if the AST structure has not been resolved or is not part of a
   *           [CompilationUnit]
   */
  static Scope scopeFor(AstNode node, AnalysisErrorListener errorListener) {
    if (node == null) {
      throw new AnalysisException.con1("Cannot create scope: node is null");
    } else if (node is CompilationUnit) {
      ScopeBuilder builder = new ScopeBuilder(errorListener);
      return builder.scopeForAstNode(node);
    }
    AstNode parent = node.parent;
    if (parent == null) {
      throw new AnalysisException.con1("Cannot create scope: node is not part of a CompilationUnit");
    }
    ScopeBuilder builder = new ScopeBuilder(errorListener);
    return builder.scopeForAstNode(parent);
  }

  /**
   * The listener to which analysis errors will be reported.
   */
  AnalysisErrorListener _errorListener;

  /**
   * Initialize a newly created scope builder to generate a scope that will report errors to the
   * given listener.
   *
   * @param errorListener the listener to which analysis errors will be reported
   */
  ScopeBuilder(AnalysisErrorListener errorListener) {
    this._errorListener = errorListener;
  }

  /**
   * Return the scope in which the given AST structure should be resolved.
   *
   * <b>Note:</b> This method needs to be kept in sync with
   * [IncrementalResolver#canBeResolved].
   *
   * @param node the root of the AST structure to be resolved
   * @return the scope in which the given AST structure should be resolved
   * @throws AnalysisException if the AST structure has not been resolved or is not part of a
   *           [CompilationUnit]
   */
  Scope scopeForAstNode(AstNode node) {
    if (node is CompilationUnit) {
      return scopeForCompilationUnit(node);
    }
    AstNode parent = node.parent;
    if (parent == null) {
      throw new AnalysisException.con1("Cannot create scope: node is not part of a CompilationUnit");
    }
    Scope scope = scopeForAstNode(parent);
    if (node is ClassDeclaration) {
      scope = new ClassScope(scope, node.element);
    } else if (node is ClassTypeAlias) {
      scope = new ClassScope(scope, node.element);
    } else if (node is ConstructorDeclaration) {
      FunctionScope functionScope = new FunctionScope(scope, node.element);
      functionScope.defineParameters();
      scope = functionScope;
    } else if (node is FunctionDeclaration) {
      FunctionScope functionScope = new FunctionScope(scope, node.element);
      functionScope.defineParameters();
      scope = functionScope;
    } else if (node is FunctionTypeAlias) {
      scope = new FunctionTypeScope(scope, node.element);
    } else if (node is MethodDeclaration) {
      FunctionScope functionScope = new FunctionScope(scope, node.element);
      functionScope.defineParameters();
      scope = functionScope;
    }
    return scope;
  }

  Scope scopeForCompilationUnit(CompilationUnit node) {
    CompilationUnitElement unitElement = node.element;
    if (unitElement == null) {
      throw new AnalysisException.con1("Cannot create scope: compilation unit is not resolved");
    }
    LibraryElement libraryElement = unitElement.library;
    if (libraryElement == null) {
      throw new AnalysisException.con1("Cannot create scope: compilation unit is not part of a library");
    }
    return new LibraryScope(libraryElement, _errorListener);
  }
}

/**
 * Instances of the class `ConstantVerifier` traverse an AST structure looking for additional
 * errors and warnings not covered by the parser and resolver. In particular, it looks for errors
 * and warnings related to constant expressions.
 */
class ConstantVerifier extends RecursiveAstVisitor<Object> {
  /**
   * The error reporter by which errors will be reported.
   */
  ErrorReporter _errorReporter;

  /**
   * The type provider used to access the known types.
   */
  TypeProvider _typeProvider;

  /**
   * The type representing the type 'bool'.
   */
  InterfaceType _boolType;

  /**
   * The type representing the type 'int'.
   */
  InterfaceType _intType;

  /**
   * The type representing the type 'num'.
   */
  InterfaceType _numType;

  /**
   * The type representing the type 'string'.
   */
  InterfaceType _stringType;

  /**
   * Initialize a newly created constant verifier.
   *
   * @param errorReporter the error reporter by which errors will be reported
   */
  ConstantVerifier(ErrorReporter errorReporter, TypeProvider typeProvider) {
    this._errorReporter = errorReporter;
    this._typeProvider = typeProvider;
    this._boolType = typeProvider.boolType;
    this._intType = typeProvider.intType;
    this._numType = typeProvider.numType;
    this._stringType = typeProvider.stringType;
  }

  Object visitAnnotation(Annotation node) {
    super.visitAnnotation(node);
    // check annotation creation
    Element element = node.element;
    if (element is ConstructorElement) {
      ConstructorElement constructorElement = element;
      // should 'const' constructor
      if (!constructorElement.isConst) {
        _errorReporter.reportError2(CompileTimeErrorCode.NON_CONSTANT_ANNOTATION_CONSTRUCTOR, node, []);
        return null;
      }
      // should have arguments
      ArgumentList argumentList = node.arguments;
      if (argumentList == null) {
        _errorReporter.reportError2(CompileTimeErrorCode.NO_ANNOTATION_CONSTRUCTOR_ARGUMENTS, node, []);
        return null;
      }
      // arguments should be constants
      validateConstantArguments(argumentList);
    }
    return null;
  }

  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    if (node.constKeyword != null) {
      validateInitializers(node);
    }
    validateDefaultValues(node.parameters);
    return super.visitConstructorDeclaration(node);
  }

  Object visitFunctionExpression(FunctionExpression node) {
    super.visitFunctionExpression(node);
    validateDefaultValues(node.parameters);
    return null;
  }

  Object visitInstanceCreationExpression(InstanceCreationExpression node) {
    validateInstanceCreationArguments(node);
    return super.visitInstanceCreationExpression(node);
  }

  Object visitListLiteral(ListLiteral node) {
    super.visitListLiteral(node);
    if (node.constKeyword != null) {
      for (Expression element in node.elements) {
        validate(element, CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT);
      }
    }
    return null;
  }

  Object visitMapLiteral(MapLiteral node) {
    super.visitMapLiteral(node);
    bool isConst = node.constKeyword != null;
    bool reportEqualKeys = true;
    Set<DartObject> keys = new Set<DartObject>();
    List<Expression> invalidKeys = new List<Expression>();
    for (MapLiteralEntry entry in node.entries) {
      Expression key = entry.key;
      if (isConst) {
        EvaluationResultImpl result = validate(key, CompileTimeErrorCode.NON_CONSTANT_MAP_KEY);
        validate(entry.value, CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE);
        if (result is ValidResult) {
          DartObject value = result.value;
          if (keys.contains(value)) {
            invalidKeys.add(key);
          } else {
            keys.add(value);
          }
        }
      } else {
        EvaluationResultImpl result = key.accept(new ConstantVisitor(_typeProvider));
        if (result is ValidResult) {
          DartObject value = result.value;
          if (keys.contains(value)) {
            invalidKeys.add(key);
          } else {
            keys.add(value);
          }
        } else {
          reportEqualKeys = false;
        }
      }
    }
    if (reportEqualKeys) {
      for (Expression key in invalidKeys) {
        _errorReporter.reportError2(StaticWarningCode.EQUAL_KEYS_IN_MAP, key, []);
      }
    }
    return null;
  }

  Object visitMethodDeclaration(MethodDeclaration node) {
    super.visitMethodDeclaration(node);
    validateDefaultValues(node.parameters);
    return null;
  }

  Object visitSwitchCase(SwitchCase node) {
    super.visitSwitchCase(node);
    validate(node.expression, CompileTimeErrorCode.NON_CONSTANT_CASE_EXPRESSION);
    return null;
  }

  Object visitVariableDeclaration(VariableDeclaration node) {
    super.visitVariableDeclaration(node);
    Expression initializer = node.initializer;
    if (initializer != null && node.isConst) {
      VariableElementImpl element = node.element as VariableElementImpl;
      EvaluationResultImpl result = element.evaluationResult;
      if (result == null) {
        //
        // Normally we don't need to visit const variable declarations because we have already
        // computed their values. But if we missed it for some reason, this gives us a second
        // chance.
        //
        result = validate(initializer, CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE);
        element.evaluationResult = result;
      } else if (result is ErrorResult) {
        reportErrors(result, CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE);
      }
    }
    return null;
  }

  /**
   * If the given result represents one or more errors, report those errors. Except for special
   * cases, use the given error code rather than the one reported in the error.
   *
   * @param result the result containing any errors that need to be reported
   * @param errorCode the error code to be used if the result represents an error
   */
  void reportErrors(EvaluationResultImpl result, ErrorCode errorCode) {
    if (result is ErrorResult) {
      for (ErrorResult_ErrorData data in result.errorData) {
        ErrorCode dataErrorCode = data.errorCode;
        if (identical(dataErrorCode, CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION) || identical(dataErrorCode, CompileTimeErrorCode.CONST_EVAL_THROWS_IDBZE) || identical(dataErrorCode, CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_NUM_STRING) || identical(dataErrorCode, CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL) || identical(dataErrorCode, CompileTimeErrorCode.CONST_EVAL_TYPE_INT) || identical(dataErrorCode, CompileTimeErrorCode.CONST_EVAL_TYPE_NUM)) {
          _errorReporter.reportError2(dataErrorCode, data.node, []);
        } else {
          _errorReporter.reportError2(errorCode, data.node, []);
        }
      }
    }
  }

  ValidResult valid(InterfaceType type, InstanceState state) => new ValidResult(new DartObjectImpl(type, state));

  /**
   * Validate that the given expression is a compile time constant. Return the value of the compile
   * time constant, or `null` if the expression is not a compile time constant.
   *
   * @param expression the expression to be validated
   * @param errorCode the error code to be used if the expression is not a compile time constant
   * @return the value of the compile time constant
   */
  EvaluationResultImpl validate(Expression expression, ErrorCode errorCode) {
    EvaluationResultImpl result = expression.accept(new ConstantVisitor(_typeProvider));
    reportErrors(result, errorCode);
    return result;
  }

  /**
   * Validate that if the passed arguments are constant expressions.
   *
   * @param argumentList the argument list to evaluate
   */
  void validateConstantArguments(ArgumentList argumentList) {
    for (Expression argument in argumentList.arguments) {
      if (argument is NamedExpression) {
        argument = (argument as NamedExpression).expression;
      }
      validate(argument, CompileTimeErrorCode.CONST_WITH_NON_CONSTANT_ARGUMENT);
    }
  }

  /**
   * Validate that the default value associated with each of the parameters in the given list is a
   * compile time constant.
   *
   * @param parameters the list of parameters to be validated
   */
  void validateDefaultValues(FormalParameterList parameters) {
    if (parameters == null) {
      return;
    }
    for (FormalParameter parameter in parameters.parameters) {
      if (parameter is DefaultFormalParameter) {
        DefaultFormalParameter defaultParameter = parameter;
        Expression defaultValue = defaultParameter.defaultValue;
        if (defaultValue != null) {
          EvaluationResultImpl result = validate(defaultValue, CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE);
          VariableElementImpl element = parameter.element as VariableElementImpl;
          element.evaluationResult = result;
        }
      }
    }
  }

  /**
   * Validates that the given expression is a compile time constant.
   *
   * @param parameterElements the elements of parameters of constant constructor, they are
   *          considered as a valid potentially constant expressions
   * @param expression the expression to validate
   */
  void validateInitializerExpression(List<ParameterElement> parameterElements, Expression expression) {
    EvaluationResultImpl result = expression.accept(new ConstantVisitor_ConstantVerifier_validateInitializerExpression(_typeProvider, this, parameterElements));
    reportErrors(result, CompileTimeErrorCode.NON_CONSTANT_VALUE_IN_INITIALIZER);
  }

  /**
   * Validates that all of the arguments of a constructor initializer are compile time constants.
   *
   * @param parameterElements the elements of parameters of constant constructor, they are
   *          considered as a valid potentially constant expressions
   * @param argumentList the argument list to validate
   */
  void validateInitializerInvocationArguments(List<ParameterElement> parameterElements, ArgumentList argumentList) {
    if (argumentList == null) {
      return;
    }
    for (Expression argument in argumentList.arguments) {
      validateInitializerExpression(parameterElements, argument);
    }
  }

  /**
   * Validates that the expressions of the given initializers (of a constant constructor) are all
   * compile time constants.
   *
   * @param constructor the constant constructor declaration to validate
   */
  void validateInitializers(ConstructorDeclaration constructor) {
    List<ParameterElement> parameterElements = constructor.parameters.parameterElements;
    NodeList<ConstructorInitializer> initializers = constructor.initializers;
    for (ConstructorInitializer initializer in initializers) {
      if (initializer is ConstructorFieldInitializer) {
        ConstructorFieldInitializer fieldInitializer = initializer;
        validateInitializerExpression(parameterElements, fieldInitializer.expression);
      }
      if (initializer is RedirectingConstructorInvocation) {
        RedirectingConstructorInvocation invocation = initializer;
        validateInitializerInvocationArguments(parameterElements, invocation.argumentList);
      }
      if (initializer is SuperConstructorInvocation) {
        SuperConstructorInvocation invocation = initializer;
        validateInitializerInvocationArguments(parameterElements, invocation.argumentList);
      }
    }
  }

  /**
   * Validate that if the passed instance creation is 'const' then all its arguments are constant
   * expressions.
   *
   * @param node the instance creation evaluate
   */
  void validateInstanceCreationArguments(InstanceCreationExpression node) {
    if (!node.isConst) {
      return;
    }
    ArgumentList argumentList = node.argumentList;
    if (argumentList == null) {
      return;
    }
    validateConstantArguments(argumentList);
  }
}

class ConstantVisitor_ConstantVerifier_validateInitializerExpression extends ConstantVisitor {
  final ConstantVerifier ConstantVerifier_this;

  List<ParameterElement> parameterElements;

  ConstantVisitor_ConstantVerifier_validateInitializerExpression(TypeProvider arg0, this.ConstantVerifier_this, this.parameterElements) : super(arg0);

  EvaluationResultImpl visitSimpleIdentifier(SimpleIdentifier node) {
    Element element = node.staticElement;
    for (ParameterElement parameterElement in parameterElements) {
      if (identical(parameterElement, element) && parameterElement != null) {
        Type2 type = parameterElement.type;
        if (type != null) {
          if (type.isDynamic) {
            return ConstantVerifier_this.valid(ConstantVerifier_this._typeProvider.objectType, DynamicState.DYNAMIC_STATE);
          } else if (type.isSubtypeOf(ConstantVerifier_this._boolType)) {
            return ConstantVerifier_this.valid(ConstantVerifier_this._typeProvider.boolType, BoolState.UNKNOWN_VALUE);
          } else if (type.isSubtypeOf(ConstantVerifier_this._typeProvider.doubleType)) {
            return ConstantVerifier_this.valid(ConstantVerifier_this._typeProvider.doubleType, DoubleState.UNKNOWN_VALUE);
          } else if (type.isSubtypeOf(ConstantVerifier_this._intType)) {
            return ConstantVerifier_this.valid(ConstantVerifier_this._typeProvider.intType, IntState.UNKNOWN_VALUE);
          } else if (type.isSubtypeOf(ConstantVerifier_this._numType)) {
            return ConstantVerifier_this.valid(ConstantVerifier_this._typeProvider.numType, NumState.UNKNOWN_VALUE);
          } else if (type.isSubtypeOf(ConstantVerifier_this._stringType)) {
            return ConstantVerifier_this.valid(ConstantVerifier_this._typeProvider.stringType, StringState.UNKNOWN_VALUE);
          }
        }
        return ConstantVerifier_this.valid(type is InterfaceType ? type : ConstantVerifier_this._typeProvider.objectType, GenericState.UNKNOWN_VALUE);
      }
    }
    return super.visitSimpleIdentifier(node);
  }
}

/**
 * Instances of the class `ErrorVerifier` traverse an AST structure looking for additional
 * errors and warnings not covered by the parser and resolver.
 */
class ErrorVerifier extends RecursiveAstVisitor<Object> {
  /**
   * The error reporter by which errors will be reported.
   */
  ErrorReporter _errorReporter;

  /**
   * The current library that is being analyzed.
   */
  LibraryElement _currentLibrary;

  /**
   * The type representing the type 'dynamic'.
   */
  Type2 _dynamicType;

  /**
   * The type representing the type 'bool'.
   */
  InterfaceType _boolType;

  /**
   * The object providing access to the types defined by the language.
   */
  TypeProvider _typeProvider;

  /**
   * The manager for the inheritance mappings.
   */
  InheritanceManager _inheritanceManager;

  /**
   * This is set to `true` iff the visitor is currently visiting children nodes of a
   * [ConstructorDeclaration] and the constructor is 'const'.
   *
   * @see #visitConstructorDeclaration(ConstructorDeclaration)
   */
  bool _isEnclosingConstructorConst = false;

  /**
   * This is set to `true` iff the visitor is currently visiting children nodes of a
   * [CatchClause].
   *
   * @see #visitCatchClause(CatchClause)
   */
  bool _isInCatchClause = false;

  /**
   * This is set to `true` iff the visitor is currently visiting children nodes of an
   * [Comment].
   */
  bool _isInComment = false;

  /**
   * This is set to `true` iff the visitor is currently visiting children nodes of an
   * [InstanceCreationExpression].
   */
  bool _isInConstInstanceCreation = false;

  /**
   * This is set to `true` iff the visitor is currently visiting children nodes of a native
   * [ClassDeclaration].
   */
  bool _isInNativeClass = false;

  /**
   * This is set to `true` iff the visitor is currently visiting a static variable
   * declaration.
   */
  bool _isInStaticVariableDeclaration = false;

  /**
   * This is set to `true` iff the visitor is currently visiting an instance variable
   * declaration.
   */
  bool _isInInstanceVariableDeclaration = false;

  /**
   * This is set to `true` iff the visitor is currently visiting an instance variable
   * initializer.
   */
  bool _isInInstanceVariableInitializer = false;

  /**
   * This is set to `true` iff the visitor is currently visiting a
   * [ConstructorInitializer].
   */
  bool _isInConstructorInitializer = false;

  /**
   * This is set to `true` iff the visitor is currently visiting a
   * [FunctionTypedFormalParameter].
   */
  bool _isInFunctionTypedFormalParameter = false;

  /**
   * This is set to `true` iff the visitor is currently visiting a static method. By "method"
   * here getter, setter and operator declarations are also implied since they are all represented
   * with a [MethodDeclaration] in the AST structure.
   */
  bool _isInStaticMethod = false;

  /**
   * This is set to `true` iff the visitor is currently visiting code in the SDK.
   */
  bool _isInSystemLibrary = false;

  /**
   * A flag indicating whether the current library contains at least one import directive with a URI
   * that uses the "dart-ext" scheme.
   */
  bool _hasExtUri = false;

  /**
   * The class containing the AST nodes being visited, or `null` if we are not in the scope of
   * a class.
   */
  ClassElement _enclosingClass;

  /**
   * The method or function that we are currently visiting, or `null` if we are not inside a
   * method or function.
   */
  ExecutableElement _enclosingFunction;

  /**
   * The return statements found in the method or function that we are currently visiting that have
   * a return value.
   */
  List<ReturnStatement> _returnsWith = new List<ReturnStatement>();

  /**
   * The return statements found in the method or function that we are currently visiting that do
   * not have a return value.
   */
  List<ReturnStatement> _returnsWithout = new List<ReturnStatement>();

  /**
   * This map is initialized when visiting the contents of a class declaration. If the visitor is
   * not in an enclosing class declaration, then the map is set to `null`.
   *
   * When set the map maps the set of [FieldElement]s in the class to an
   * [INIT_STATE#NOT_INIT] or [INIT_STATE#INIT_IN_DECLARATION]. <code>checkFor*</code>
   * methods, specifically [checkForAllFinalInitializedErrorCodes],
   * can make a copy of the map to compute error code states. <code>checkFor*</code> methods should
   * only ever make a copy, or read from this map after it has been set in
   * [visitClassDeclaration].
   *
   * @see #visitClassDeclaration(ClassDeclaration)
   * @see #checkForAllFinalInitializedErrorCodes(ConstructorDeclaration)
   */
  Map<FieldElement, INIT_STATE> _initialFieldElementsMap;

  /**
   * A table mapping name of the library to the export directive which export this library.
   */
  Map<String, LibraryElement> _nameToExportElement = new Map<String, LibraryElement>();

  /**
   * A table mapping name of the library to the import directive which import this library.
   */
  Map<String, LibraryElement> _nameToImportElement = new Map<String, LibraryElement>();

  /**
   * A table mapping names to the exported elements.
   */
  Map<String, Element> _exportedElements = new Map<String, Element>();

  /**
   * A set of the names of the variable initializers we are visiting now.
   */
  Set<String> _namesForReferenceToDeclaredVariableInInitializer = new Set<String>();

  /**
   * A list of types used by the [CompileTimeErrorCode#EXTENDS_DISALLOWED_CLASS] and
   * [CompileTimeErrorCode#IMPLEMENTS_DISALLOWED_CLASS] error codes.
   */
  List<InterfaceType> _DISALLOWED_TYPES_TO_EXTEND_OR_IMPLEMENT;

  ErrorVerifier(ErrorReporter errorReporter, LibraryElement currentLibrary, TypeProvider typeProvider, InheritanceManager inheritanceManager) {
    this._errorReporter = errorReporter;
    this._currentLibrary = currentLibrary;
    this._isInSystemLibrary = currentLibrary.source.isInSystemLibrary;
    this._hasExtUri = currentLibrary.hasExtUri();
    this._typeProvider = typeProvider;
    this._inheritanceManager = inheritanceManager;
    _isEnclosingConstructorConst = false;
    _isInCatchClause = false;
    _isInStaticVariableDeclaration = false;
    _isInInstanceVariableDeclaration = false;
    _isInInstanceVariableInitializer = false;
    _isInConstructorInitializer = false;
    _isInStaticMethod = false;
    _boolType = typeProvider.boolType;
    _dynamicType = typeProvider.dynamicType;
    _DISALLOWED_TYPES_TO_EXTEND_OR_IMPLEMENT = <InterfaceType> [
        typeProvider.nullType,
        typeProvider.numType,
        typeProvider.intType,
        typeProvider.doubleType,
        _boolType,
        typeProvider.stringType];
  }

  Object visitArgumentDefinitionTest(ArgumentDefinitionTest node) {
    checkForArgumentDefinitionTestNonParameter(node);
    return super.visitArgumentDefinitionTest(node);
  }

  Object visitArgumentList(ArgumentList node) {
    checkForArgumentTypesNotAssignableInList(node);
    return super.visitArgumentList(node);
  }

  Object visitAssertStatement(AssertStatement node) {
    checkForNonBoolExpression(node);
    return super.visitAssertStatement(node);
  }

  Object visitAssignmentExpression(AssignmentExpression node) {
    sc.Token operator = node.operator;
    sc.TokenType operatorType = operator.type;
    if (identical(operatorType, sc.TokenType.EQ)) {
      checkForInvalidAssignment(node.leftHandSide, node.rightHandSide);
    } else {
      checkForInvalidCompoundAssignment(node);
    }
    checkForAssignmentToFinal(node.leftHandSide);
    checkForArgumentTypeNotAssignableForArgument(node.rightHandSide);
    return super.visitAssignmentExpression(node);
  }

  Object visitBinaryExpression(BinaryExpression node) {
    checkForArgumentTypeNotAssignableForArgument(node.rightOperand);
    return super.visitBinaryExpression(node);
  }

  Object visitBlockFunctionBody(BlockFunctionBody node) {
    List<ReturnStatement> previousReturnsWith = _returnsWith;
    List<ReturnStatement> previousReturnsWithout = _returnsWithout;
    try {
      _returnsWith = new List<ReturnStatement>();
      _returnsWithout = new List<ReturnStatement>();
      super.visitBlockFunctionBody(node);
      checkForMixedReturns(node);
    } finally {
      _returnsWith = previousReturnsWith;
      _returnsWithout = previousReturnsWithout;
    }
    return null;
  }

  Object visitBreakStatement(BreakStatement node) {
    SimpleIdentifier labelNode = node.label;
    if (labelNode != null) {
      Element labelElement = labelNode.staticElement;
      if (labelElement is LabelElementImpl && labelElement.isOnSwitchMember) {
        _errorReporter.reportError2(ResolverErrorCode.BREAK_LABEL_ON_SWITCH_MEMBER, labelNode, []);
      }
    }
    return null;
  }

  Object visitCatchClause(CatchClause node) {
    bool previousIsInCatchClause = _isInCatchClause;
    try {
      _isInCatchClause = true;
      return super.visitCatchClause(node);
    } finally {
      _isInCatchClause = previousIsInCatchClause;
    }
  }

  Object visitClassDeclaration(ClassDeclaration node) {
    ClassElement outerClass = _enclosingClass;
    try {
      _isInNativeClass = node.nativeClause != null;
      _enclosingClass = node.element;
      WithClause withClause = node.withClause;
      ImplementsClause implementsClause = node.implementsClause;
      ExtendsClause extendsClause = node.extendsClause;
      checkForBuiltInIdentifierAsName(node.name, CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME);
      checkForMemberWithClassName();
      checkForNoDefaultSuperConstructorImplicit(node);
      checkForConflictingTypeVariableErrorCodes(node);
      // Only do error checks on the clause nodes if there is a non-null clause
      if (implementsClause != null || extendsClause != null || withClause != null) {
        // Only check for all of the inheritance logic around clauses if there isn't an error code
        // such as "Cannot extend double" already on the class.
        if (!checkForImplementsDisallowedClass(implementsClause) && !checkForExtendsDisallowedClass(extendsClause) && !checkForAllMixinErrorCodes(withClause)) {
          checkForNonAbstractClassInheritsAbstractMember(node);
          checkForInconsistentMethodInheritance();
          checkForRecursiveInterfaceInheritance(_enclosingClass);
        }
      }
      // initialize initialFieldElementsMap
      ClassElement classElement = node.element;
      if (classElement != null) {
        List<FieldElement> fieldElements = classElement.fields;
        _initialFieldElementsMap = new Map<FieldElement, INIT_STATE>();
        for (FieldElement fieldElement in fieldElements) {
          if (!fieldElement.isSynthetic) {
            _initialFieldElementsMap[fieldElement] = fieldElement.initializer == null ? INIT_STATE.NOT_INIT : INIT_STATE.INIT_IN_DECLARATION;
          }
        }
      }
      checkForFinalNotInitializedInClass(node);
      checkForDuplicateDefinitionInheritance();
      checkForConflictingGetterAndMethod();
      checkForConflictingInstanceGetterAndSuperclassMember();
      checkImplementsSuperClass(node);
      checkImplementsFunctionWithoutCall(node);
      return super.visitClassDeclaration(node);
    } finally {
      _isInNativeClass = false;
      _initialFieldElementsMap = null;
      _enclosingClass = outerClass;
    }
  }

  Object visitClassTypeAlias(ClassTypeAlias node) {
    checkForBuiltInIdentifierAsName(node.name, CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME);
    checkForAllMixinErrorCodes(node.withClause);
    ClassElement outerClassElement = _enclosingClass;
    try {
      _enclosingClass = node.element;
      checkForRecursiveInterfaceInheritance(node.element);
      checkForTypeAliasCannotReferenceItself_mixin(node);
    } finally {
      _enclosingClass = outerClassElement;
    }
    return super.visitClassTypeAlias(node);
  }

  Object visitComment(Comment node) {
    _isInComment = true;
    try {
      return super.visitComment(node);
    } finally {
      _isInComment = false;
    }
  }

  Object visitConditionalExpression(ConditionalExpression node) {
    checkForNonBoolCondition(node.condition);
    return super.visitConditionalExpression(node);
  }

  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    ExecutableElement outerFunction = _enclosingFunction;
    try {
      _enclosingFunction = node.element;
      _isEnclosingConstructorConst = node.constKeyword != null;
      checkForConstConstructorWithNonFinalField(node);
      checkForConstConstructorWithNonConstSuper(node);
      checkForConflictingConstructorNameAndMember(node);
      checkForAllFinalInitializedErrorCodes(node);
      checkForRedirectingConstructorErrorCodes(node);
      checkForMultipleSuperInitializers(node);
      checkForRecursiveConstructorRedirect(node);
      if (!checkForRecursiveFactoryRedirect(node)) {
        checkForAllRedirectConstructorErrorCodes(node);
      }
      checkForUndefinedConstructorInInitializerImplicit(node);
      checkForRedirectToNonConstConstructor(node);
      checkForReturnInGenerativeConstructor(node);
      return super.visitConstructorDeclaration(node);
    } finally {
      _isEnclosingConstructorConst = false;
      _enclosingFunction = outerFunction;
    }
  }

  Object visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    _isInConstructorInitializer = true;
    try {
      checkForInvalidField(node);
      checkForFieldInitializerNotAssignable(node);
      return super.visitConstructorFieldInitializer(node);
    } finally {
      _isInConstructorInitializer = false;
    }
  }

  Object visitContinueStatement(ContinueStatement node) {
    SimpleIdentifier labelNode = node.label;
    if (labelNode != null) {
      Element labelElement = labelNode.staticElement;
      if (labelElement is LabelElementImpl && labelElement.isOnSwitchStatement) {
        _errorReporter.reportError2(ResolverErrorCode.CONTINUE_LABEL_ON_SWITCH, labelNode, []);
      }
    }
    return null;
  }

  Object visitDefaultFormalParameter(DefaultFormalParameter node) {
    checkForInvalidAssignment(node.identifier, node.defaultValue);
    checkForDefaultValueInFunctionTypedParameter(node);
    return super.visitDefaultFormalParameter(node);
  }

  Object visitDoStatement(DoStatement node) {
    checkForNonBoolCondition(node.condition);
    return super.visitDoStatement(node);
  }

  Object visitExportDirective(ExportDirective node) {
    checkForAmbiguousExport(node);
    checkForExportDuplicateLibraryName(node);
    checkForExportInternalLibrary(node);
    return super.visitExportDirective(node);
  }

  Object visitExpressionFunctionBody(ExpressionFunctionBody node) {
    FunctionType functionType = _enclosingFunction == null ? null : _enclosingFunction.type;
    Type2 expectedReturnType = functionType == null ? DynamicTypeImpl.instance : functionType.returnType;
    checkForReturnOfInvalidType(node.expression, expectedReturnType);
    return super.visitExpressionFunctionBody(node);
  }

  Object visitFieldDeclaration(FieldDeclaration node) {
    if (!node.isStatic) {
      VariableDeclarationList variables = node.fields;
      if (variables.isConst) {
        _errorReporter.reportError5(CompileTimeErrorCode.CONST_INSTANCE_FIELD, variables.keyword, []);
      }
    }
    _isInStaticVariableDeclaration = node.isStatic;
    _isInInstanceVariableDeclaration = !_isInStaticVariableDeclaration;
    try {
      checkForAllInvalidOverrideErrorCodesForField(node);
      return super.visitFieldDeclaration(node);
    } finally {
      _isInStaticVariableDeclaration = false;
      _isInInstanceVariableDeclaration = false;
    }
  }

  Object visitFieldFormalParameter(FieldFormalParameter node) {
    checkForValidField(node);
    checkForConstFormalParameter(node);
    checkForPrivateOptionalParameter(node);
    checkForFieldInitializingFormalRedirectingConstructor(node);
    return super.visitFieldFormalParameter(node);
  }

  Object visitFunctionDeclaration(FunctionDeclaration node) {
    ExecutableElement outerFunction = _enclosingFunction;
    try {
      SimpleIdentifier identifier = node.name;
      String methodName = "";
      if (identifier != null) {
        methodName = identifier.name;
      }
      _enclosingFunction = node.element;
      if (node.isSetter || node.isGetter) {
        checkForMismatchedAccessorTypes(node, methodName);
        if (node.isSetter) {
          FunctionExpression functionExpression = node.functionExpression;
          if (functionExpression != null) {
            checkForWrongNumberOfParametersForSetter(node.name, functionExpression.parameters);
          }
          TypeName returnType = node.returnType;
          checkForNonVoidReturnTypeForSetter(returnType);
        }
      }
      return super.visitFunctionDeclaration(node);
    } finally {
      _enclosingFunction = outerFunction;
    }
  }

  Object visitFunctionExpression(FunctionExpression node) {
    // If this function expression is wrapped in a function declaration, don't change the
    // enclosingFunction field.
    if (node.parent is! FunctionDeclaration) {
      ExecutableElement outerFunction = _enclosingFunction;
      try {
        _enclosingFunction = node.element;
        return super.visitFunctionExpression(node);
      } finally {
        _enclosingFunction = outerFunction;
      }
    } else {
      return super.visitFunctionExpression(node);
    }
  }

  Object visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    Expression functionExpression = node.function;
    Type2 expressionType = functionExpression.staticType;
    if (!isFunctionType(expressionType)) {
      _errorReporter.reportError2(StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION, functionExpression, []);
    }
    return super.visitFunctionExpressionInvocation(node);
  }

  Object visitFunctionTypeAlias(FunctionTypeAlias node) {
    checkForBuiltInIdentifierAsName(node.name, CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME);
    checkForDefaultValueInFunctionTypeAlias(node);
    checkForTypeAliasCannotReferenceItself_function(node);
    return super.visitFunctionTypeAlias(node);
  }

  Object visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    bool old = _isInFunctionTypedFormalParameter;
    _isInFunctionTypedFormalParameter = true;
    try {
      return super.visitFunctionTypedFormalParameter(node);
    } finally {
      _isInFunctionTypedFormalParameter = old;
    }
  }

  Object visitIfStatement(IfStatement node) {
    checkForNonBoolCondition(node.condition);
    return super.visitIfStatement(node);
  }

  Object visitImportDirective(ImportDirective node) {
    checkForImportDuplicateLibraryName(node);
    checkForImportInternalLibrary(node);
    return super.visitImportDirective(node);
  }

  Object visitIndexExpression(IndexExpression node) {
    checkForArgumentTypeNotAssignableForArgument(node.index);
    return super.visitIndexExpression(node);
  }

  Object visitInstanceCreationExpression(InstanceCreationExpression node) {
    _isInConstInstanceCreation = node.isConst;
    try {
      ConstructorName constructorName = node.constructorName;
      TypeName typeName = constructorName.type;
      Type2 type = typeName.type;
      if (type is InterfaceType) {
        InterfaceType interfaceType = type;
        checkForConstOrNewWithAbstractClass(node, typeName, interfaceType);
        if (_isInConstInstanceCreation) {
          checkForConstWithNonConst(node);
          checkForConstWithUndefinedConstructor(node);
          checkForConstWithTypeParametersInCreation(node);
        } else {
          checkForNewWithUndefinedConstructor(node);
        }
      }
      return super.visitInstanceCreationExpression(node);
    } finally {
      _isInConstInstanceCreation = false;
    }
  }

  Object visitListLiteral(ListLiteral node) {
    if (node.constKeyword != null) {
      TypeArgumentList typeArguments = node.typeArguments;
      if (typeArguments != null) {
        NodeList<TypeName> arguments = typeArguments.arguments;
        if (arguments.length != 0) {
          checkForInvalidTypeArgumentInConstTypedLiteral(arguments, CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_LIST);
        }
      }
    }
    checkForExpectedOneListTypeArgument(node);
    checkForListElementTypeNotAssignable(node);
    return super.visitListLiteral(node);
  }

  Object visitMapLiteral(MapLiteral node) {
    TypeArgumentList typeArguments = node.typeArguments;
    if (typeArguments != null) {
      NodeList<TypeName> arguments = typeArguments.arguments;
      if (arguments.length != 0) {
        if (node.constKeyword != null) {
          checkForInvalidTypeArgumentInConstTypedLiteral(arguments, CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_MAP);
        }
      }
    }
    checkExpectedTwoMapTypeArguments(typeArguments);
    checkForNonConstMapAsExpressionStatement(node);
    checkForMapTypeNotAssignable(node);
    checkForConstMapKeyExpressionTypeImplementsEquals(node);
    return super.visitMapLiteral(node);
  }

  Object visitMethodDeclaration(MethodDeclaration node) {
    ExecutableElement previousFunction = _enclosingFunction;
    try {
      _isInStaticMethod = node.isStatic;
      _enclosingFunction = node.element;
      SimpleIdentifier identifier = node.name;
      String methodName = "";
      if (identifier != null) {
        methodName = identifier.name;
      }
      if (node.isSetter || node.isGetter) {
        checkForMismatchedAccessorTypes(node, methodName);
      }
      if (node.isGetter) {
        checkForConflictingStaticGetterAndInstanceSetter(node);
      } else if (node.isSetter) {
        checkForWrongNumberOfParametersForSetter(node.name, node.parameters);
        checkForNonVoidReturnTypeForSetter(node.returnType);
        checkForConflictingStaticSetterAndInstanceMember(node);
      } else if (node.isOperator) {
        checkForOptionalParameterInOperator(node);
        checkForWrongNumberOfParametersForOperator(node);
        checkForNonVoidReturnTypeForOperator(node);
      } else {
        checkForConflictingInstanceMethodSetter(node);
      }
      checkForConcreteClassWithAbstractMember(node);
      checkForAllInvalidOverrideErrorCodesForMethod(node);
      return super.visitMethodDeclaration(node);
    } finally {
      _enclosingFunction = previousFunction;
      _isInStaticMethod = false;
    }
  }

  Object visitMethodInvocation(MethodInvocation node) {
    Expression target = node.realTarget;
    SimpleIdentifier methodName = node.methodName;
    if (target != null) {
      ClassElement typeReference = ElementResolver.getTypeReference(target);
      checkForStaticAccessToInstanceMember(typeReference, methodName);
      checkForInstanceAccessToStaticMember(typeReference, methodName);
    } else {
      checkForUnqualifiedReferenceToNonLocalStaticMember(methodName);
    }
    return super.visitMethodInvocation(node);
  }

  Object visitNativeClause(NativeClause node) {
    // TODO(brianwilkerson) Figure out the right rule for when 'native' is allowed.
    if (!_isInSystemLibrary) {
      _errorReporter.reportError2(ParserErrorCode.NATIVE_CLAUSE_IN_NON_SDK_CODE, node, []);
    }
    return super.visitNativeClause(node);
  }

  Object visitNativeFunctionBody(NativeFunctionBody node) {
    checkForNativeFunctionBodyInNonSDKCode(node);
    return super.visitNativeFunctionBody(node);
  }

  Object visitPostfixExpression(PostfixExpression node) {
    checkForAssignmentToFinal(node.operand);
    checkForIntNotAssignable(node.operand);
    return super.visitPostfixExpression(node);
  }

  Object visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.parent is! Annotation) {
      ClassElement typeReference = ElementResolver.getTypeReference(node.prefix);
      SimpleIdentifier name = node.identifier;
      checkForStaticAccessToInstanceMember(typeReference, name);
      checkForInstanceAccessToStaticMember(typeReference, name);
    }
    return super.visitPrefixedIdentifier(node);
  }

  Object visitPrefixExpression(PrefixExpression node) {
    sc.TokenType operatorType = node.operator.type;
    Expression operand = node.operand;
    if (identical(operatorType, sc.TokenType.BANG)) {
      checkForNonBoolNegationExpression(operand);
    } else if (operatorType.isIncrementOperator) {
      checkForAssignmentToFinal(operand);
    }
    checkForIntNotAssignable(operand);
    return super.visitPrefixExpression(node);
  }

  Object visitPropertyAccess(PropertyAccess node) {
    ClassElement typeReference = ElementResolver.getTypeReference(node.realTarget);
    SimpleIdentifier propertyName = node.propertyName;
    checkForStaticAccessToInstanceMember(typeReference, propertyName);
    checkForInstanceAccessToStaticMember(typeReference, propertyName);
    return super.visitPropertyAccess(node);
  }

  Object visitRedirectingConstructorInvocation(RedirectingConstructorInvocation node) {
    _isInConstructorInitializer = true;
    try {
      return super.visitRedirectingConstructorInvocation(node);
    } finally {
      _isInConstructorInitializer = false;
    }
  }

  Object visitRethrowExpression(RethrowExpression node) {
    checkForRethrowOutsideCatch(node);
    return super.visitRethrowExpression(node);
  }

  Object visitReturnStatement(ReturnStatement node) {
    if (node.expression == null) {
      _returnsWithout.add(node);
    } else {
      _returnsWith.add(node);
    }
    checkForAllReturnStatementErrorCodes(node);
    return super.visitReturnStatement(node);
  }

  Object visitSimpleFormalParameter(SimpleFormalParameter node) {
    checkForConstFormalParameter(node);
    checkForPrivateOptionalParameter(node);
    return super.visitSimpleFormalParameter(node);
  }

  Object visitSimpleIdentifier(SimpleIdentifier node) {
    checkForImplicitThisReferenceInInitializer(node);
    if (!isUnqualifiedReferenceToNonLocalStaticMemberAllowed(node)) {
      checkForUnqualifiedReferenceToNonLocalStaticMember(node);
    }
    return super.visitSimpleIdentifier(node);
  }

  Object visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    _isInConstructorInitializer = true;
    try {
      return super.visitSuperConstructorInvocation(node);
    } finally {
      _isInConstructorInitializer = false;
    }
  }

  Object visitSwitchStatement(SwitchStatement node) {
    checkForInconsistentCaseExpressionTypes(node);
    checkForSwitchExpressionNotAssignable(node);
    checkForCaseBlocksNotTerminated(node);
    return super.visitSwitchStatement(node);
  }

  Object visitThisExpression(ThisExpression node) {
    checkForInvalidReferenceToThis(node);
    return super.visitThisExpression(node);
  }

  Object visitThrowExpression(ThrowExpression node) {
    checkForConstEvalThrowsException(node);
    return super.visitThrowExpression(node);
  }

  Object visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    checkForFinalNotInitialized(node.variables);
    return super.visitTopLevelVariableDeclaration(node);
  }

  Object visitTypeName(TypeName node) {
    checkForTypeArgumentNotMatchingBounds(node);
    checkForTypeParameterReferencedByStatic(node);
    return super.visitTypeName(node);
  }

  Object visitTypeParameter(TypeParameter node) {
    checkForBuiltInIdentifierAsName(node.name, CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_PARAMETER_NAME);
    checkForTypeParameterSupertypeOfItsBound(node);
    return super.visitTypeParameter(node);
  }

  Object visitVariableDeclaration(VariableDeclaration node) {
    SimpleIdentifier nameNode = node.name;
    Expression initializerNode = node.initializer;
    // do checks
    checkForInvalidAssignment(nameNode, initializerNode);
    // visit name
    nameNode.accept(this);
    // visit initializer
    String name = nameNode.name;
    _namesForReferenceToDeclaredVariableInInitializer.add(name);
    _isInInstanceVariableInitializer = _isInInstanceVariableDeclaration;
    try {
      if (initializerNode != null) {
        initializerNode.accept(this);
      }
    } finally {
      _isInInstanceVariableInitializer = false;
      _namesForReferenceToDeclaredVariableInInitializer.remove(name);
    }
    // done
    return null;
  }

  Object visitVariableDeclarationList(VariableDeclarationList node) => super.visitVariableDeclarationList(node);

  Object visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    checkForFinalNotInitialized(node.variables);
    return super.visitVariableDeclarationStatement(node);
  }

  Object visitWhileStatement(WhileStatement node) {
    checkForNonBoolCondition(node.condition);
    return super.visitWhileStatement(node);
  }

  /**
   * This verifies if the passed map literal has type arguments then there is exactly two.
   *
   * @param node the map literal to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see StaticTypeWarningCode#EXPECTED_TWO_MAP_TYPE_ARGUMENTS
   */
  bool checkExpectedTwoMapTypeArguments(TypeArgumentList typeArguments) {
    // has type arguments
    if (typeArguments == null) {
      return false;
    }
    // check number of type arguments
    int num = typeArguments.arguments.length;
    if (num == 2) {
      return false;
    }
    // report problem
    _errorReporter.reportError2(StaticTypeWarningCode.EXPECTED_TWO_MAP_TYPE_ARGUMENTS, typeArguments, [num]);
    return true;
  }

  /**
   * This verifies that the passed constructor declaration does not violate any of the error codes
   * relating to the initialization of fields in the enclosing class.
   *
   * @param node the [ConstructorDeclaration] to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see #initialFieldElementsMap
   * @see CompileTimeErrorCode#FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR
   * @see CompileTimeErrorCode#FINAL_INITIALIZED_MULTIPLE_TIMES
   */
  bool checkForAllFinalInitializedErrorCodes(ConstructorDeclaration node) {
    if (node.factoryKeyword != null || node.redirectedConstructor != null || node.externalKeyword != null) {
      return false;
    }
    // Ignore if native class.
    if (_isInNativeClass) {
      return false;
    }
    bool foundError = false;
    Map<FieldElement, INIT_STATE> fieldElementsMap = new Map<FieldElement, INIT_STATE>.from(_initialFieldElementsMap);
    // Visit all of the field formal parameters
    NodeList<FormalParameter> formalParameters = node.parameters.parameters;
    for (FormalParameter formalParameter in formalParameters) {
      FormalParameter parameter = formalParameter;
      if (parameter is DefaultFormalParameter) {
        parameter = (parameter as DefaultFormalParameter).parameter;
      }
      if (parameter is FieldFormalParameter) {
        FieldElement fieldElement = (parameter.element as FieldFormalParameterElementImpl).field;
        INIT_STATE state = fieldElementsMap[fieldElement];
        if (identical(state, INIT_STATE.NOT_INIT)) {
          fieldElementsMap[fieldElement] = INIT_STATE.INIT_IN_FIELD_FORMAL;
        } else if (identical(state, INIT_STATE.INIT_IN_DECLARATION)) {
          if (fieldElement.isFinal || fieldElement.isConst) {
            _errorReporter.reportError2(StaticWarningCode.FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR, formalParameter.identifier, [fieldElement.displayName]);
            foundError = true;
          }
        } else if (identical(state, INIT_STATE.INIT_IN_FIELD_FORMAL)) {
          if (fieldElement.isFinal || fieldElement.isConst) {
            _errorReporter.reportError2(CompileTimeErrorCode.FINAL_INITIALIZED_MULTIPLE_TIMES, formalParameter.identifier, [fieldElement.displayName]);
            foundError = true;
          }
        }
      }
    }
    // Visit all of the initializers
    NodeList<ConstructorInitializer> initializers = node.initializers;
    for (ConstructorInitializer constructorInitializer in initializers) {
      if (constructorInitializer is RedirectingConstructorInvocation) {
        return false;
      }
      if (constructorInitializer is ConstructorFieldInitializer) {
        ConstructorFieldInitializer constructorFieldInitializer = constructorInitializer;
        SimpleIdentifier fieldName = constructorFieldInitializer.fieldName;
        Element element = fieldName.staticElement;
        if (element is FieldElement) {
          FieldElement fieldElement = element;
          INIT_STATE state = fieldElementsMap[fieldElement];
          if (identical(state, INIT_STATE.NOT_INIT)) {
            fieldElementsMap[fieldElement] = INIT_STATE.INIT_IN_INITIALIZERS;
          } else if (identical(state, INIT_STATE.INIT_IN_DECLARATION)) {
            if (fieldElement.isFinal || fieldElement.isConst) {
              _errorReporter.reportError2(StaticWarningCode.FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION, fieldName, []);
              foundError = true;
            }
          } else if (identical(state, INIT_STATE.INIT_IN_FIELD_FORMAL)) {
            _errorReporter.reportError2(CompileTimeErrorCode.FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER, fieldName, []);
            foundError = true;
          } else if (identical(state, INIT_STATE.INIT_IN_INITIALIZERS)) {
            _errorReporter.reportError2(CompileTimeErrorCode.FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS, fieldName, [fieldElement.displayName]);
            foundError = true;
          }
        }
      }
    }
    // Visit all of the states in the map to ensure that none were never initialized.
    for (MapEntry<FieldElement, INIT_STATE> entry in getMapEntrySet(fieldElementsMap)) {
      if (identical(entry.getValue(), INIT_STATE.NOT_INIT)) {
        FieldElement fieldElement = entry.getKey();
        if (fieldElement.isConst) {
          _errorReporter.reportError2(CompileTimeErrorCode.CONST_NOT_INITIALIZED, node.returnType, [fieldElement.name]);
          foundError = true;
        } else if (fieldElement.isFinal) {
          _errorReporter.reportError2(StaticWarningCode.FINAL_NOT_INITIALIZED, node.returnType, [fieldElement.name]);
          foundError = true;
        }
      }
    }
    return foundError;
  }

  /**
   * This checks the passed executable element against override-error codes.
   *
   * @param executableElement a non-null [ExecutableElement] to evaluate
   * @param overriddenExecutable the element that the executableElement is overriding
   * @param parameters the parameters of the executable element
   * @param errorNameTarget the node to report problems on
   * @return `true` if and only if an error code is generated on the passed node
   * @see StaticWarningCode#INSTANCE_METHOD_NAME_COLLIDES_WITH_SUPERCLASS_STATIC
   * @see CompileTimeErrorCode#INVALID_OVERRIDE_REQUIRED
   * @see CompileTimeErrorCode#INVALID_OVERRIDE_POSITIONAL
   * @see CompileTimeErrorCode#INVALID_OVERRIDE_NAMED
   * @see StaticWarningCode#INVALID_GETTER_OVERRIDE_RETURN_TYPE
   * @see StaticWarningCode#INVALID_METHOD_OVERRIDE_RETURN_TYPE
   * @see StaticWarningCode#INVALID_METHOD_OVERRIDE_NORMAL_PARAM_TYPE
   * @see StaticWarningCode#INVALID_SETTER_OVERRIDE_NORMAL_PARAM_TYPE
   * @see StaticWarningCode#INVALID_METHOD_OVERRIDE_OPTIONAL_PARAM_TYPE
   * @see StaticWarningCode#INVALID_METHOD_OVERRIDE_NAMED_PARAM_TYPE
   * @see StaticWarningCode#INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES
   */
  bool checkForAllInvalidOverrideErrorCodes(ExecutableElement executableElement, ExecutableElement overriddenExecutable, List<ParameterElement> parameters, List<AstNode> parameterLocations, SimpleIdentifier errorNameTarget) {
    bool isGetter = false;
    bool isSetter = false;
    if (executableElement is PropertyAccessorElement) {
      PropertyAccessorElement accessorElement = executableElement;
      isGetter = accessorElement.isGetter;
      isSetter = accessorElement.isSetter;
    }
    String executableElementName = executableElement.name;
    // SWC.INSTANCE_METHOD_NAME_COLLIDES_WITH_SUPERCLASS_STATIC
    if (overriddenExecutable == null) {
      if (!isGetter && !isSetter && !executableElement.isOperator) {
        Set<ClassElement> visitedClasses = new Set<ClassElement>();
        InterfaceType superclassType = _enclosingClass.supertype;
        ClassElement superclassElement = superclassType == null ? null : superclassType.element;
        bool executableElementPrivate = Identifier.isPrivateName(executableElementName);
        while (superclassElement != null && !visitedClasses.contains(superclassElement)) {
          visitedClasses.add(superclassElement);
          LibraryElement superclassLibrary = superclassElement.library;
          // Check fields.
          List<FieldElement> fieldElts = superclassElement.fields;
          for (FieldElement fieldElt in fieldElts) {
            // We need the same name.
            if (fieldElt.name != executableElementName) {
              continue;
            }
            // Ignore if private in a different library - cannot collide.
            if (executableElementPrivate && _currentLibrary != superclassLibrary) {
              continue;
            }
            // instance vs. static
            if (fieldElt.isStatic) {
              _errorReporter.reportError2(StaticWarningCode.INSTANCE_METHOD_NAME_COLLIDES_WITH_SUPERCLASS_STATIC, errorNameTarget, [
                  executableElementName,
                  fieldElt.enclosingElement.displayName]);
              return true;
            }
          }
          // Check methods.
          List<MethodElement> methodElements = superclassElement.methods;
          for (MethodElement methodElement in methodElements) {
            // We need the same name.
            if (methodElement.name != executableElementName) {
              continue;
            }
            // Ignore if private in a different library - cannot collide.
            if (executableElementPrivate && _currentLibrary != superclassLibrary) {
              continue;
            }
            // instance vs. static
            if (methodElement.isStatic) {
              _errorReporter.reportError2(StaticWarningCode.INSTANCE_METHOD_NAME_COLLIDES_WITH_SUPERCLASS_STATIC, errorNameTarget, [
                  executableElementName,
                  methodElement.enclosingElement.displayName]);
              return true;
            }
          }
          superclassType = superclassElement.supertype;
          superclassElement = superclassType == null ? null : superclassType.element;
        }
      }
      return false;
    }
    FunctionType overridingFT = executableElement.type;
    FunctionType overriddenFT = overriddenExecutable.type;
    InterfaceType enclosingType = _enclosingClass.type;
    overriddenFT = _inheritanceManager.substituteTypeArgumentsInMemberFromInheritance(overriddenFT, executableElementName, enclosingType);
    if (overridingFT == null || overriddenFT == null) {
      return false;
    }
    Type2 overridingFTReturnType = overridingFT.returnType;
    Type2 overriddenFTReturnType = overriddenFT.returnType;
    List<Type2> overridingNormalPT = overridingFT.normalParameterTypes;
    List<Type2> overriddenNormalPT = overriddenFT.normalParameterTypes;
    List<Type2> overridingPositionalPT = overridingFT.optionalParameterTypes;
    List<Type2> overriddenPositionalPT = overriddenFT.optionalParameterTypes;
    Map<String, Type2> overridingNamedPT = overridingFT.namedParameterTypes;
    Map<String, Type2> overriddenNamedPT = overriddenFT.namedParameterTypes;
    // CTEC.INVALID_OVERRIDE_REQUIRED, CTEC.INVALID_OVERRIDE_POSITIONAL and CTEC.INVALID_OVERRIDE_NAMED
    if (overridingNormalPT.length > overriddenNormalPT.length) {
      _errorReporter.reportError2(StaticWarningCode.INVALID_OVERRIDE_REQUIRED, errorNameTarget, [
          overriddenNormalPT.length,
          overriddenExecutable.enclosingElement.displayName]);
      return true;
    }
    if (overridingNormalPT.length + overridingPositionalPT.length < overriddenPositionalPT.length + overriddenNormalPT.length) {
      _errorReporter.reportError2(StaticWarningCode.INVALID_OVERRIDE_POSITIONAL, errorNameTarget, [
          overriddenPositionalPT.length + overriddenNormalPT.length,
          overriddenExecutable.enclosingElement.displayName]);
      return true;
    }
    // For each named parameter in the overridden method, verify that there is the same name in
    // the overriding method, and in the same order.
    Set<String> overridingParameterNameSet = overridingNamedPT.keys.toSet();
    JavaIterator<String> overriddenParameterNameIterator = new JavaIterator(overriddenNamedPT.keys.toSet());
    while (overriddenParameterNameIterator.hasNext) {
      String overriddenParamName = overriddenParameterNameIterator.next();
      if (!overridingParameterNameSet.contains(overriddenParamName)) {
        // The overridden method expected the overriding method to have overridingParamName,
        // but it does not.
        _errorReporter.reportError2(StaticWarningCode.INVALID_OVERRIDE_NAMED, errorNameTarget, [
            overriddenParamName,
            overriddenExecutable.enclosingElement.displayName]);
        return true;
      }
    }
    // SWC.INVALID_METHOD_OVERRIDE_RETURN_TYPE
    if (overriddenFTReturnType != VoidTypeImpl.instance && !overridingFTReturnType.isAssignableTo(overriddenFTReturnType)) {
      _errorReporter.reportError2(!isGetter ? StaticWarningCode.INVALID_METHOD_OVERRIDE_RETURN_TYPE : StaticWarningCode.INVALID_GETTER_OVERRIDE_RETURN_TYPE, errorNameTarget, [
          overridingFTReturnType.displayName,
          overriddenFTReturnType.displayName,
          overriddenExecutable.enclosingElement.displayName]);
      return true;
    }
    // SWC.INVALID_METHOD_OVERRIDE_NORMAL_PARAM_TYPE
    if (parameterLocations == null) {
      return false;
    }
    int parameterIndex = 0;
    for (int i = 0; i < overridingNormalPT.length; i++) {
      if (!overridingNormalPT[i].isAssignableTo(overriddenNormalPT[i])) {
        _errorReporter.reportError2(!isSetter ? StaticWarningCode.INVALID_METHOD_OVERRIDE_NORMAL_PARAM_TYPE : StaticWarningCode.INVALID_SETTER_OVERRIDE_NORMAL_PARAM_TYPE, parameterLocations[parameterIndex], [
            overridingNormalPT[i].displayName,
            overriddenNormalPT[i].displayName,
            overriddenExecutable.enclosingElement.displayName]);
        return true;
      }
      parameterIndex++;
    }
    // SWC.INVALID_METHOD_OVERRIDE_OPTIONAL_PARAM_TYPE
    for (int i = 0; i < overriddenPositionalPT.length; i++) {
      if (!overridingPositionalPT[i].isAssignableTo(overriddenPositionalPT[i])) {
        _errorReporter.reportError2(StaticWarningCode.INVALID_METHOD_OVERRIDE_OPTIONAL_PARAM_TYPE, parameterLocations[parameterIndex], [
            overridingPositionalPT[i].displayName,
            overriddenPositionalPT[i].displayName,
            overriddenExecutable.enclosingElement.displayName]);
        return true;
      }
      parameterIndex++;
    }
    // SWC.INVALID_METHOD_OVERRIDE_NAMED_PARAM_TYPE & SWC.INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES
    JavaIterator<MapEntry<String, Type2>> overriddenNamedPTIterator = new JavaIterator(getMapEntrySet(overriddenNamedPT));
    while (overriddenNamedPTIterator.hasNext) {
      MapEntry<String, Type2> overriddenNamedPTEntry = overriddenNamedPTIterator.next();
      Type2 overridingType = overridingNamedPT[overriddenNamedPTEntry.getKey()];
      if (overridingType == null) {
        // Error, this is never reached- INVALID_OVERRIDE_NAMED would have been created above if
        // this could be reached.
        continue;
      }
      if (!overriddenNamedPTEntry.getValue().isAssignableTo(overridingType)) {
        // lookup the parameter for the error to select
        ParameterElement parameterToSelect = null;
        AstNode parameterLocationToSelect = null;
        for (int i = 0; i < parameters.length; i++) {
          ParameterElement parameter = parameters[i];
          if (identical(parameter.parameterKind, ParameterKind.NAMED) && overriddenNamedPTEntry.getKey() == parameter.name) {
            parameterToSelect = parameter;
            parameterLocationToSelect = parameterLocations[i];
            break;
          }
        }
        if (parameterToSelect != null) {
          _errorReporter.reportError2(StaticWarningCode.INVALID_METHOD_OVERRIDE_NAMED_PARAM_TYPE, parameterLocationToSelect, [
              overridingType.displayName,
              overriddenNamedPTEntry.getValue().displayName,
              overriddenExecutable.enclosingElement.displayName]);
          return true;
        }
      }
    }
    // SWC.INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES
    //
    // Create three arrays: an array of the optional parameter ASTs (FormalParameters), an array of
    // the optional parameters elements from our method, and finally an array of the optional
    // parameter elements from the method we are overriding.
    //
    bool foundError = false;
    List<AstNode> formalParameters = new List<AstNode>();
    List<ParameterElementImpl> parameterElts = new List<ParameterElementImpl>();
    List<ParameterElementImpl> overriddenParameterElts = new List<ParameterElementImpl>();
    List<ParameterElement> overriddenPEs = overriddenExecutable.parameters;
    for (int i = 0; i < parameters.length; i++) {
      ParameterElement parameter = parameters[i];
      if (parameter.parameterKind.isOptional) {
        formalParameters.add(parameterLocations[i]);
        parameterElts.add(parameter as ParameterElementImpl);
      }
    }
    for (ParameterElement parameterElt in overriddenPEs) {
      if (parameterElt.parameterKind.isOptional) {
        if (parameterElt is ParameterElementImpl) {
          overriddenParameterElts.add(parameterElt);
        }
      }
    }
    //
    // Next compare the list of optional parameter elements to the list of overridden optional
    // parameter elements.
    //
    if (parameterElts.length > 0) {
      if (identical(parameterElts[0].parameterKind, ParameterKind.NAMED)) {
        // Named parameters, consider the names when matching the parameterElts to the overriddenParameterElts
        for (int i = 0; i < parameterElts.length; i++) {
          ParameterElementImpl parameterElt = parameterElts[i];
          EvaluationResultImpl result = parameterElt.evaluationResult;
          // TODO (jwren) Ignore Object types, see Dart bug 11287
          if (isUserDefinedObject(result)) {
            continue;
          }
          String parameterName = parameterElt.name;
          for (int j = 0; j < overriddenParameterElts.length; j++) {
            ParameterElementImpl overriddenParameterElt = overriddenParameterElts[j];
            String overriddenParameterName = overriddenParameterElt.name;
            if (parameterName != null && parameterName == overriddenParameterName) {
              EvaluationResultImpl overriddenResult = overriddenParameterElt.evaluationResult;
              if (isUserDefinedObject(overriddenResult)) {
                break;
              }
              if (!result.equalValues(_typeProvider, overriddenResult)) {
                _errorReporter.reportError2(StaticWarningCode.INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_NAMED, formalParameters[i], [
                    overriddenExecutable.enclosingElement.displayName,
                    overriddenExecutable.displayName,
                    parameterName]);
                foundError = true;
              }
            }
          }
        }
      } else {
        // Positional parameters, consider the positions when matching the parameterElts to the overriddenParameterElts
        for (int i = 0; i < parameterElts.length && i < overriddenParameterElts.length; i++) {
          ParameterElementImpl parameterElt = parameterElts[i];
          EvaluationResultImpl result = parameterElt.evaluationResult;
          // TODO (jwren) Ignore Object types, see Dart bug 11287
          if (isUserDefinedObject(result)) {
            continue;
          }
          ParameterElementImpl overriddenParameterElt = overriddenParameterElts[i];
          EvaluationResultImpl overriddenResult = overriddenParameterElt.evaluationResult;
          if (isUserDefinedObject(overriddenResult)) {
            continue;
          }
          if (!result.equalValues(_typeProvider, overriddenResult)) {
            _errorReporter.reportError2(StaticWarningCode.INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_POSITIONAL, formalParameters[i], [
                overriddenExecutable.enclosingElement.displayName,
                overriddenExecutable.displayName]);
            foundError = true;
          }
        }
      }
    }
    return foundError;
  }

  /**
   * This checks the passed executable element against override-error codes. This method computes
   * the passed executableElement is overriding and calls
   * [checkForAllInvalidOverrideErrorCodes]
   * when the [InheritanceManager] returns a [MultiplyInheritedExecutableElement], this
   * method loops through the array in the [MultiplyInheritedExecutableElement].
   *
   * @param executableElement a non-null [ExecutableElement] to evaluate
   * @param parameters the parameters of the executable element
   * @param errorNameTarget the node to report problems on
   * @return `true` if and only if an error code is generated on the passed node
   */
  bool checkForAllInvalidOverrideErrorCodesForExecutable(ExecutableElement executableElement, List<ParameterElement> parameters, List<AstNode> parameterLocations, SimpleIdentifier errorNameTarget) {
    //
    // Compute the overridden executable from the InheritanceManager
    //
    ExecutableElement overriddenExecutable = _inheritanceManager.lookupInheritance(_enclosingClass, executableElement.name);
    //
    // If the result is a MultiplyInheritedExecutableElement call
    // checkForAllInvalidOverrideErrorCodes on all of the elements, until an error is found.
    //
    if (overriddenExecutable is MultiplyInheritedExecutableElement) {
      MultiplyInheritedExecutableElement multiplyInheritedElement = overriddenExecutable;
      List<ExecutableElement> overriddenElement = multiplyInheritedElement.inheritedElements;
      for (int i = 0; i < overriddenElement.length; i++) {
        if (checkForAllInvalidOverrideErrorCodes(executableElement, overriddenElement[i], parameters, parameterLocations, errorNameTarget)) {
          return true;
        }
      }
      return false;
    }
    //
    // Otherwise, just call checkForAllInvalidOverrideErrorCodes.
    //
    return checkForAllInvalidOverrideErrorCodes(executableElement, overriddenExecutable, parameters, parameterLocations, errorNameTarget);
  }

  /**
   * This checks the passed field declaration against override-error codes.
   *
   * @param node the [MethodDeclaration] to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see #checkForAllInvalidOverrideErrorCodes(ExecutableElement)
   */
  bool checkForAllInvalidOverrideErrorCodesForField(FieldDeclaration node) {
    if (_enclosingClass == null || node.isStatic) {
      return false;
    }
    bool hasProblems = false;
    VariableDeclarationList fields = node.fields;
    for (VariableDeclaration field in fields.variables) {
      FieldElement element = field.element as FieldElement;
      if (element == null) {
        continue;
      }
      PropertyAccessorElement getter = element.getter;
      PropertyAccessorElement setter = element.setter;
      SimpleIdentifier fieldName = field.name;
      if (getter != null) {
        hasProblems = javaBooleanOr(hasProblems, checkForAllInvalidOverrideErrorCodesForExecutable(getter, ParameterElementImpl.EMPTY_ARRAY, AstNode.EMPTY_ARRAY, fieldName));
      }
      if (setter != null) {
        hasProblems = javaBooleanOr(hasProblems, checkForAllInvalidOverrideErrorCodesForExecutable(setter, setter.parameters, <AstNode> [fieldName], fieldName));
      }
    }
    return hasProblems;
  }

  /**
   * This checks the passed method declaration against override-error codes.
   *
   * @param node the [MethodDeclaration] to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see #checkForAllInvalidOverrideErrorCodes(ExecutableElement)
   */
  bool checkForAllInvalidOverrideErrorCodesForMethod(MethodDeclaration node) {
    if (_enclosingClass == null || node.isStatic || node.body is NativeFunctionBody) {
      return false;
    }
    ExecutableElement executableElement = node.element;
    if (executableElement == null) {
      return false;
    }
    SimpleIdentifier methodName = node.name;
    if (methodName.isSynthetic) {
      return false;
    }
    FormalParameterList formalParameterList = node.parameters;
    NodeList<FormalParameter> parameterList = formalParameterList != null ? formalParameterList.parameters : null;
    List<AstNode> parameters = parameterList != null ? new List.from(parameterList) : null;
    return checkForAllInvalidOverrideErrorCodesForExecutable(executableElement, executableElement.parameters, parameters, methodName);
  }

  /**
   * This verifies that all classes of the passed 'with' clause are valid.
   *
   * @param node the 'with' clause to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#MIXIN_DECLARES_CONSTRUCTOR
   * @see CompileTimeErrorCode#MIXIN_INHERITS_FROM_NOT_OBJECT
   * @see CompileTimeErrorCode#MIXIN_REFERENCES_SUPER
   */
  bool checkForAllMixinErrorCodes(WithClause withClause) {
    if (withClause == null) {
      return false;
    }
    bool problemReported = false;
    for (TypeName mixinName in withClause.mixinTypes) {
      Type2 mixinType = mixinName.type;
      if (mixinType is! InterfaceType) {
        continue;
      }
      if (checkForExtendsOrImplementsDisallowedClass(mixinName, CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS)) {
        problemReported = true;
      } else {
        ClassElement mixinElement = (mixinType as InterfaceType).element;
        problemReported = javaBooleanOr(problemReported, checkForMixinDeclaresConstructor(mixinName, mixinElement));
        problemReported = javaBooleanOr(problemReported, checkForMixinInheritsNotFromObject(mixinName, mixinElement));
        problemReported = javaBooleanOr(problemReported, checkForMixinReferencesSuper(mixinName, mixinElement));
      }
    }
    return problemReported;
  }

  /**
   * This checks error related to the redirected constructors.
   *
   * @param node the constructor declaration to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see StaticWarningCode#REDIRECT_TO_INVALID_RETURN_TYPE
   * @see StaticWarningCode#REDIRECT_TO_INVALID_FUNCTION_TYPE
   * @see StaticWarningCode#REDIRECT_TO_MISSING_CONSTRUCTOR
   */
  bool checkForAllRedirectConstructorErrorCodes(ConstructorDeclaration node) {
    //
    // Prepare redirected constructor node
    //
    ConstructorName redirectedConstructor = node.redirectedConstructor;
    if (redirectedConstructor == null) {
      return false;
    }
    //
    // Prepare redirected constructor type
    //
    ConstructorElement redirectedElement = redirectedConstructor.staticElement;
    if (redirectedElement == null) {
      //
      // If the element is null, we check for the REDIRECT_TO_MISSING_CONSTRUCTOR case
      //
      TypeName constructorTypeName = redirectedConstructor.type;
      Type2 redirectedType = constructorTypeName.type;
      if (redirectedType != null && redirectedType.element != null && !redirectedType.isDynamic) {
        //
        // Prepare the constructor name
        //
        String constructorStrName = constructorTypeName.name.name;
        if (redirectedConstructor.name != null) {
          constructorStrName += ".${redirectedConstructor.name.name}";
        }
        ErrorCode errorCode = (node.constKeyword != null ? CompileTimeErrorCode.REDIRECT_TO_MISSING_CONSTRUCTOR : StaticWarningCode.REDIRECT_TO_MISSING_CONSTRUCTOR) as ErrorCode;
        _errorReporter.reportError2(errorCode, redirectedConstructor, [constructorStrName, redirectedType.displayName]);
        return true;
      }
      return false;
    }
    FunctionType redirectedType = redirectedElement.type;
    Type2 redirectedReturnType = redirectedType.returnType;
    //
    // Report specific problem when return type is incompatible
    //
    FunctionType constructorType = node.element.type;
    Type2 constructorReturnType = constructorType.returnType;
    if (!redirectedReturnType.isAssignableTo(constructorReturnType)) {
      _errorReporter.reportError2(StaticWarningCode.REDIRECT_TO_INVALID_RETURN_TYPE, redirectedConstructor, [redirectedReturnType, constructorReturnType]);
      return true;
    }
    //
    // Check parameters
    //
    if (!redirectedType.isSubtypeOf(constructorType)) {
      _errorReporter.reportError2(StaticWarningCode.REDIRECT_TO_INVALID_FUNCTION_TYPE, redirectedConstructor, [redirectedType, constructorType]);
      return true;
    }
    return false;
  }

  /**
   * This checks that the return statement of the form <i>return e;</i> is not in a generative
   * constructor.
   *
   * This checks that return statements without expressions are not in a generative constructor and
   * the return type is not assignable to `null`; that is, we don't have `return;` if
   * the enclosing method has a return type.
   *
   * This checks that the return type matches the type of the declared return type in the enclosing
   * method or function.
   *
   * @param node the return statement to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#RETURN_IN_GENERATIVE_CONSTRUCTOR
   * @see StaticWarningCode#RETURN_WITHOUT_VALUE
   * @see StaticTypeWarningCode#RETURN_OF_INVALID_TYPE
   */
  bool checkForAllReturnStatementErrorCodes(ReturnStatement node) {
    FunctionType functionType = _enclosingFunction == null ? null : _enclosingFunction.type;
    Type2 expectedReturnType = functionType == null ? DynamicTypeImpl.instance : functionType.returnType;
    Expression returnExpression = node.expression;
    // RETURN_IN_GENERATIVE_CONSTRUCTOR
    bool isGenerativeConstructor = _enclosingFunction is ConstructorElement && !(_enclosingFunction as ConstructorElement).isFactory;
    if (isGenerativeConstructor) {
      if (returnExpression == null) {
        return false;
      }
      _errorReporter.reportError2(CompileTimeErrorCode.RETURN_IN_GENERATIVE_CONSTRUCTOR, returnExpression, []);
      return true;
    }
    // RETURN_WITHOUT_VALUE
    if (returnExpression == null) {
      if (VoidTypeImpl.instance.isAssignableTo(expectedReturnType)) {
        return false;
      }
      _errorReporter.reportError2(StaticWarningCode.RETURN_WITHOUT_VALUE, node, []);
      return true;
    }
    // RETURN_OF_INVALID_TYPE
    return checkForReturnOfInvalidType(returnExpression, expectedReturnType);
  }

  /**
   * This verifies that the export namespace of the passed export directive does not export any name
   * already exported by other export directive.
   *
   * @param node the export directive node to report problem on
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#AMBIGUOUS_EXPORT
   */
  bool checkForAmbiguousExport(ExportDirective node) {
    // prepare ExportElement
    if (node.element is! ExportElement) {
      return false;
    }
    ExportElement exportElement = node.element as ExportElement;
    // prepare exported library
    LibraryElement exportedLibrary = exportElement.exportedLibrary;
    if (exportedLibrary == null) {
      return false;
    }
    // check exported names
    Namespace namespace = new NamespaceBuilder().createExportNamespace(exportElement);
    Map<String, Element> definedNames = namespace.definedNames;
    for (MapEntry<String, Element> definedEntry in getMapEntrySet(definedNames)) {
      String name = definedEntry.getKey();
      Element element = definedEntry.getValue();
      Element prevElement = _exportedElements[name];
      if (element != null && prevElement != null && prevElement != element) {
        _errorReporter.reportError2(CompileTimeErrorCode.AMBIGUOUS_EXPORT, node, [
            name,
            prevElement.library.definingCompilationUnit.displayName,
            element.library.definingCompilationUnit.displayName]);
        return true;
      } else {
        _exportedElements[name] = element;
      }
    }
    return false;
  }

  /**
   * This verifies that the passed argument definition test identifier is a parameter.
   *
   * @param node the [ArgumentDefinitionTest] to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#ARGUMENT_DEFINITION_TEST_NON_PARAMETER
   */
  bool checkForArgumentDefinitionTestNonParameter(ArgumentDefinitionTest node) {
    SimpleIdentifier identifier = node.identifier;
    Element element = identifier.staticElement;
    if (element != null && element is! ParameterElement) {
      _errorReporter.reportError2(CompileTimeErrorCode.ARGUMENT_DEFINITION_TEST_NON_PARAMETER, identifier, [identifier.name]);
      return true;
    }
    return false;
  }

  /**
   * This verifies that the passed expression can be assigned to its corresponding parameters.
   *
   * @param expression the expression to evaluate
   * @param expectedStaticType the expected static type of the parameter
   * @param actualStaticType the actual static type of the argument
   * @param expectedPropagatedType the expected propagated type of the parameter, may be
   *          `null`
   * @param actualPropagatedType the expected propagated type of the parameter, may be `null`
   * @return `true` if and only if an error code is generated on the passed node
   * @see StaticWarningCode#ARGUMENT_TYPE_NOT_ASSIGNABLE
   */
  bool checkForArgumentTypeNotAssignable(Expression expression, Type2 expectedStaticType, Type2 actualStaticType, Type2 expectedPropagatedType, Type2 actualPropagatedType, ErrorCode errorCode) {
    //
    // Test static type information
    //
    if (actualStaticType == null || expectedStaticType == null) {
      return false;
    }
    if (actualStaticType.isAssignableTo(expectedStaticType)) {
      return false;
    }
    _errorReporter.reportError2(errorCode, expression, [
        actualStaticType.displayName,
        expectedStaticType.displayName]);
    return true;
  }

  /**
   * This verifies that the passed argument can be assigned to its corresponding parameter.
   *
   * @param argument the argument to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see StaticWarningCode#ARGUMENT_TYPE_NOT_ASSIGNABLE
   */
  bool checkForArgumentTypeNotAssignableForArgument(Expression argument) {
    if (argument == null) {
      return false;
    }
    ParameterElement staticParameterElement = argument.staticParameterElement;
    Type2 staticParameterType = staticParameterElement == null ? null : staticParameterElement.type;
    ParameterElement propagatedParameterElement = argument.propagatedParameterElement;
    Type2 propagatedParameterType = propagatedParameterElement == null ? null : propagatedParameterElement.type;
    return checkForArgumentTypeNotAssignableWithExpectedTypes(argument, staticParameterType, propagatedParameterType, StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE);
  }

  /**
   * This verifies that the passed expression can be assigned to its corresponding parameters.
   *
   * @param expression the expression to evaluate
   * @param expectedStaticType the expected static type
   * @param expectedPropagatedType the expected propagated type, may be `null`
   * @return `true` if and only if an error code is generated on the passed node
   * @see StaticWarningCode#ARGUMENT_TYPE_NOT_ASSIGNABLE
   */
  bool checkForArgumentTypeNotAssignableWithExpectedTypes(Expression expression, Type2 expectedStaticType, Type2 expectedPropagatedType, ErrorCode errorCode) => checkForArgumentTypeNotAssignable(expression, expectedStaticType, getStaticType(expression), expectedPropagatedType, expression.propagatedType, errorCode);

  /**
   * This verifies that the passed arguments can be assigned to their corresponding parameters.
   *
   * @param node the arguments to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see StaticWarningCode#ARGUMENT_TYPE_NOT_ASSIGNABLE
   */
  bool checkForArgumentTypesNotAssignableInList(ArgumentList argumentList) {
    if (argumentList == null) {
      return false;
    }
    bool problemReported = false;
    for (Expression argument in argumentList.arguments) {
      problemReported = javaBooleanOr(problemReported, checkForArgumentTypeNotAssignableForArgument(argument));
    }
    // done
    return problemReported;
  }

  /**
   * This verifies that the passed expression is not final.
   *
   * @param node the expression to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see StaticWarningCode#ASSIGNMENT_TO_CONST
   * @see StaticWarningCode#ASSIGNMENT_TO_FINAL
   * @see StaticWarningCode#ASSIGNMENT_TO_METHOD
   */
  bool checkForAssignmentToFinal(Expression expression) {
    // prepare element
    Element element = null;
    if (expression is Identifier) {
      element = expression.staticElement;
    }
    if (expression is PropertyAccess) {
      element = expression.propertyName.staticElement;
    }
    // check if element is assignable
    if (element is PropertyAccessorElement) {
      PropertyAccessorElement accessor = element as PropertyAccessorElement;
      element = accessor.variable;
    }
    if (element is VariableElement) {
      VariableElement variable = element as VariableElement;
      if (variable.isConst) {
        _errorReporter.reportError2(StaticWarningCode.ASSIGNMENT_TO_CONST, expression, []);
        return true;
      }
      if (variable.isFinal) {
        _errorReporter.reportError2(StaticWarningCode.ASSIGNMENT_TO_FINAL, expression, [variable.name]);
        return true;
      }
      return false;
    }
    if (element is MethodElement) {
      _errorReporter.reportError2(StaticWarningCode.ASSIGNMENT_TO_METHOD, expression, []);
      return true;
    }
    return false;
  }

  /**
   * This verifies that the passed identifier is not a keyword, and generates the passed error code
   * on the identifier if it is a keyword.
   *
   * @param identifier the identifier to check to ensure that it is not a keyword
   * @param errorCode if the passed identifier is a keyword then this error code is created on the
   *          identifier, the error code will be one of
   *          [CompileTimeErrorCode#BUILT_IN_IDENTIFIER_AS_TYPE_NAME],
   *          [CompileTimeErrorCode#BUILT_IN_IDENTIFIER_AS_TYPE_PARAMETER_NAME] or
   *          [CompileTimeErrorCode#BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME]
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#BUILT_IN_IDENTIFIER_AS_TYPE_NAME
   * @see CompileTimeErrorCode#BUILT_IN_IDENTIFIER_AS_TYPE_PARAMETER_NAME
   * @see CompileTimeErrorCode#BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME
   */
  bool checkForBuiltInIdentifierAsName(SimpleIdentifier identifier, ErrorCode errorCode) {
    sc.Token token = identifier.token;
    if (identical(token.type, sc.TokenType.KEYWORD)) {
      _errorReporter.reportError2(errorCode, identifier, [identifier.name]);
      return true;
    }
    return false;
  }

  /**
   * This verifies that the given switch case is terminated with 'break', 'continue', 'return' or
   * 'throw'.
   *
   * @param node the switch case to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see StaticWarningCode#CASE_BLOCK_NOT_TERMINATED
   */
  bool checkForCaseBlockNotTerminated(SwitchCase node) {
    NodeList<Statement> statements = node.statements;
    if (statements.isEmpty) {
      // fall-through without statements at all
      AstNode parent = node.parent;
      if (parent is SwitchStatement) {
        SwitchStatement switchStatement = parent;
        NodeList<SwitchMember> members = switchStatement.members;
        int index = members.indexOf(node);
        if (index != -1 && index < members.length - 1) {
          return false;
        }
      }
    } else {
      Statement statement = statements[statements.length - 1];
      // terminated with statement
      if (statement is BreakStatement || statement is ContinueStatement || statement is ReturnStatement) {
        return false;
      }
      // terminated with 'throw' expression
      if (statement is ExpressionStatement) {
        Expression expression = statement.expression;
        if (expression is ThrowExpression) {
          return false;
        }
      }
    }
    // report error
    _errorReporter.reportError5(StaticWarningCode.CASE_BLOCK_NOT_TERMINATED, node.keyword, []);
    return true;
  }

  /**
   * This verifies that the switch cases in the given switch statement is terminated with 'break',
   * 'continue', 'return' or 'throw'.
   *
   * @param node the switch statement containing the cases to be checked
   * @return `true` if and only if an error code is generated on the passed node
   * @see StaticWarningCode#CASE_BLOCK_NOT_TERMINATED
   */
  bool checkForCaseBlocksNotTerminated(SwitchStatement node) {
    bool foundError = false;
    NodeList<SwitchMember> members = node.members;
    int lastMember = members.length - 1;
    for (int i = 0; i < lastMember; i++) {
      SwitchMember member = members[i];
      if (member is SwitchCase) {
        foundError = javaBooleanOr(foundError, checkForCaseBlockNotTerminated(member));
      }
    }
    return foundError;
  }

  /**
   * This verifies that the passed switch statement does not have a case expression with the
   * operator '==' overridden.
   *
   * @param node the switch statement to evaluate
   * @param type the common type of all 'case' expressions
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS
   */
  bool checkForCaseExpressionTypeImplementsEquals(SwitchStatement node, Type2 type) {
    if (!implementsEqualsWhenNotAllowed(type)) {
      return false;
    }
    // report error
    _errorReporter.reportError5(CompileTimeErrorCode.CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS, node.keyword, [type.displayName]);
    return true;
  }

  /**
   * This verifies that the passed method declaration is abstract only if the enclosing class is
   * also abstract.
   *
   * @param node the method declaration to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see StaticWarningCode#CONCRETE_CLASS_WITH_ABSTRACT_MEMBER
   */
  bool checkForConcreteClassWithAbstractMember(MethodDeclaration node) {
    if (node.isAbstract && _enclosingClass != null && !_enclosingClass.isAbstract) {
      SimpleIdentifier methodName = node.name;
      _errorReporter.reportError2(StaticWarningCode.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER, methodName, [methodName.name, _enclosingClass.displayName]);
      return true;
    }
    return false;
  }

  /**
   * This verifies all possible conflicts of the constructor name with other constructors and
   * members of the same class.
   *
   * @param node the constructor declaration to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#DUPLICATE_CONSTRUCTOR_DEFAULT
   * @see CompileTimeErrorCode#DUPLICATE_CONSTRUCTOR_NAME
   * @see CompileTimeErrorCode#CONFLICTING_CONSTRUCTOR_NAME_AND_FIELD
   * @see CompileTimeErrorCode#CONFLICTING_CONSTRUCTOR_NAME_AND_METHOD
   */
  bool checkForConflictingConstructorNameAndMember(ConstructorDeclaration node) {
    ConstructorElement constructorElement = node.element;
    SimpleIdentifier constructorName = node.name;
    String name = constructorElement.name;
    ClassElement classElement = constructorElement.enclosingElement;
    // constructors
    List<ConstructorElement> constructors = classElement.constructors;
    for (ConstructorElement otherConstructor in constructors) {
      if (identical(otherConstructor, constructorElement)) {
        continue;
      }
      if (name == otherConstructor.name) {
        if (name == null || name.length == 0) {
          _errorReporter.reportError2(CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_DEFAULT, node, []);
        } else {
          _errorReporter.reportError2(CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_NAME, node, [name]);
        }
        return true;
      }
    }
    // conflict with class member
    if (constructorName != null && constructorElement != null && !constructorName.isSynthetic) {
      // fields
      FieldElement field = classElement.getField(name);
      if (field != null) {
        _errorReporter.reportError2(CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_NAME_AND_FIELD, node, [name]);
        return true;
      }
      // methods
      MethodElement method = classElement.getMethod(name);
      if (method != null) {
        _errorReporter.reportError2(CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_NAME_AND_METHOD, node, [name]);
        return true;
      }
    }
    return false;
  }

  /**
   * This verifies that the [enclosingClass] does not have method and getter with the same
   * names.
   *
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#CONFLICTING_GETTER_AND_METHOD
   * @see CompileTimeErrorCode#CONFLICTING_METHOD_AND_GETTER
   */
  bool checkForConflictingGetterAndMethod() {
    if (_enclosingClass == null) {
      return false;
    }
    bool hasProblem = false;
    // method declared in the enclosing class vs. inherited getter
    for (MethodElement method in _enclosingClass.methods) {
      String name = method.name;
      // find inherited property accessor (and can be only getter)
      ExecutableElement inherited = _inheritanceManager.lookupInheritance(_enclosingClass, name);
      if (inherited is! PropertyAccessorElement) {
        continue;
      }
      // report problem
      hasProblem = true;
      _errorReporter.reportError4(CompileTimeErrorCode.CONFLICTING_GETTER_AND_METHOD, method.nameOffset, name.length, [
          _enclosingClass.displayName,
          inherited.enclosingElement.displayName,
          name]);
    }
    // getter declared in the enclosing class vs. inherited method
    for (PropertyAccessorElement accessor in _enclosingClass.accessors) {
      if (!accessor.isGetter) {
        continue;
      }
      String name = accessor.name;
      // find inherited method
      ExecutableElement inherited = _inheritanceManager.lookupInheritance(_enclosingClass, name);
      if (inherited is! MethodElement) {
        continue;
      }
      // report problem
      hasProblem = true;
      _errorReporter.reportError4(CompileTimeErrorCode.CONFLICTING_METHOD_AND_GETTER, accessor.nameOffset, name.length, [
          _enclosingClass.displayName,
          inherited.enclosingElement.displayName,
          name]);
    }
    // done
    return hasProblem;
  }

  /**
   * This verifies that the superclass of the [enclosingClass] does not declare accessible
   * static members with the same name as the instance getters/setters declared in
   * [enclosingClass].
   *
   * @param node the method declaration to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see StaticWarningCode#CONFLICTING_INSTANCE_GETTER_AND_SUPERCLASS_MEMBER
   * @see StaticWarningCode#CONFLICTING_INSTANCE_SETTER_AND_SUPERCLASS_MEMBER
   */
  bool checkForConflictingInstanceGetterAndSuperclassMember() {
    if (_enclosingClass == null) {
      return false;
    }
    InterfaceType enclosingType = _enclosingClass.type;
    // check every accessor
    bool hasProblem = false;
    for (PropertyAccessorElement accessor in _enclosingClass.accessors) {
      // we analyze instance accessors here
      if (accessor.isStatic) {
        continue;
      }
      // prepare accessor properties
      String name = accessor.displayName;
      bool getter = accessor.isGetter;
      // if non-final variable, ignore setter - we alreay reported problem for getter
      if (accessor.isSetter && accessor.isSynthetic) {
        continue;
      }
      // try to find super element
      ExecutableElement superElement;
      superElement = enclosingType.lookUpGetterInSuperclass(name, _currentLibrary);
      if (superElement == null) {
        superElement = enclosingType.lookUpSetterInSuperclass(name, _currentLibrary);
      }
      if (superElement == null) {
        superElement = enclosingType.lookUpMethodInSuperclass(name, _currentLibrary);
      }
      if (superElement == null) {
        continue;
      }
      // OK, not static
      if (!superElement.isStatic) {
        continue;
      }
      // prepare "super" type to report its name
      ClassElement superElementClass = superElement.enclosingElement as ClassElement;
      InterfaceType superElementType = superElementClass.type;
      // report problem
      hasProblem = true;
      if (getter) {
        _errorReporter.reportError3(StaticWarningCode.CONFLICTING_INSTANCE_GETTER_AND_SUPERCLASS_MEMBER, accessor, [superElementType.displayName]);
      } else {
        _errorReporter.reportError3(StaticWarningCode.CONFLICTING_INSTANCE_SETTER_AND_SUPERCLASS_MEMBER, accessor, [superElementType.displayName]);
      }
    }
    // done
    return hasProblem;
  }

  /**
   * This verifies that the enclosing class does not have a setter with the same name as the passed
   * instance method declaration.
   *
   * @param node the method declaration to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see StaticWarningCode#CONFLICTING_INSTANCE_METHOD_SETTER
   */
  bool checkForConflictingInstanceMethodSetter(MethodDeclaration node) {
    if (node.isStatic) {
      return false;
    }
    // prepare name
    SimpleIdentifier nameNode = node.name;
    if (nameNode == null) {
      return false;
    }
    String name = nameNode.name;
    // ensure that we have enclosing class
    if (_enclosingClass == null) {
      return false;
    }
    // try to find setter
    ExecutableElement setter = _inheritanceManager.lookupMember(_enclosingClass, "${name}=");
    if (setter == null) {
      return false;
    }
    // report problem
    _errorReporter.reportError2(StaticWarningCode.CONFLICTING_INSTANCE_METHOD_SETTER, nameNode, [
        _enclosingClass.displayName,
        name,
        setter.enclosingElement.displayName]);
    return true;
  }

  /**
   * This verifies that the enclosing class does not have an instance member with the same name as
   * the passed static getter method declaration.
   *
   * @param node the method declaration to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see StaticWarningCode#CONFLICTING_STATIC_GETTER_AND_INSTANCE_SETTER
   */
  bool checkForConflictingStaticGetterAndInstanceSetter(MethodDeclaration node) {
    if (!node.isStatic) {
      return false;
    }
    // prepare name
    SimpleIdentifier nameNode = node.name;
    if (nameNode == null) {
      return false;
    }
    String name = nameNode.name;
    // prepare enclosing type
    if (_enclosingClass == null) {
      return false;
    }
    InterfaceType enclosingType = _enclosingClass.type;
    // try to find setter
    ExecutableElement setter = enclosingType.lookUpSetter(name, _currentLibrary);
    if (setter == null) {
      return false;
    }
    // OK, also static
    if (setter.isStatic) {
      return false;
    }
    // prepare "setter" type to report its name
    ClassElement setterClass = setter.enclosingElement as ClassElement;
    InterfaceType setterType = setterClass.type;
    // report problem
    _errorReporter.reportError2(StaticWarningCode.CONFLICTING_STATIC_GETTER_AND_INSTANCE_SETTER, nameNode, [setterType.displayName]);
    return true;
  }

  /**
   * This verifies that the enclosing class does not have an instance member with the same name as
   * the passed static getter method declaration.
   *
   * @param node the method declaration to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see StaticWarningCode#CONFLICTING_STATIC_SETTER_AND_INSTANCE_MEMBER
   */
  bool checkForConflictingStaticSetterAndInstanceMember(MethodDeclaration node) {
    if (!node.isStatic) {
      return false;
    }
    // prepare name
    SimpleIdentifier nameNode = node.name;
    if (nameNode == null) {
      return false;
    }
    String name = nameNode.name;
    // prepare enclosing type
    if (_enclosingClass == null) {
      return false;
    }
    InterfaceType enclosingType = _enclosingClass.type;
    // try to find member
    ExecutableElement member;
    member = enclosingType.lookUpMethod(name, _currentLibrary);
    if (member == null) {
      member = enclosingType.lookUpGetter(name, _currentLibrary);
    }
    if (member == null) {
      member = enclosingType.lookUpSetter(name, _currentLibrary);
    }
    if (member == null) {
      return false;
    }
    // OK, also static
    if (member.isStatic) {
      return false;
    }
    // prepare "member" type to report its name
    ClassElement memberClass = member.enclosingElement as ClassElement;
    InterfaceType memberType = memberClass.type;
    // report problem
    _errorReporter.reportError2(StaticWarningCode.CONFLICTING_STATIC_SETTER_AND_INSTANCE_MEMBER, nameNode, [memberType.displayName]);
    return true;
  }

  /**
   * This verifies all conflicts between type variable and enclosing class. TODO(scheglov)
   *
   * @param node the class declaration to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#CONFLICTING_TYPE_VARIABLE_AND_CLASS
   * @see CompileTimeErrorCode#CONFLICTING_TYPE_VARIABLE_AND_MEMBER
   */
  bool checkForConflictingTypeVariableErrorCodes(ClassDeclaration node) {
    bool problemReported = false;
    for (TypeParameterElement typeParameter in _enclosingClass.typeParameters) {
      String name = typeParameter.name;
      // name is same as the name of the enclosing class
      if (_enclosingClass.name == name) {
        _errorReporter.reportError4(CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_CLASS, typeParameter.nameOffset, name.length, [name]);
        problemReported = true;
      }
      // check members
      if (_enclosingClass.getMethod(name) != null || _enclosingClass.getGetter(name) != null || _enclosingClass.getSetter(name) != null) {
        _errorReporter.reportError4(CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER, typeParameter.nameOffset, name.length, [name]);
        problemReported = true;
      }
    }
    return problemReported;
  }

  /**
   * This verifies that if the passed constructor declaration is 'const' then there are no
   * invocations of non-'const' super constructors.
   *
   * @param node the constructor declaration to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER
   */
  bool checkForConstConstructorWithNonConstSuper(ConstructorDeclaration node) {
    if (!_isEnclosingConstructorConst) {
      return false;
    }
    // OK, const factory, checked elsewhere
    if (node.factoryKeyword != null) {
      return false;
    }
    // try to find and check super constructor invocation
    for (ConstructorInitializer initializer in node.initializers) {
      if (initializer is SuperConstructorInvocation) {
        SuperConstructorInvocation superInvocation = initializer;
        ConstructorElement element = superInvocation.staticElement;
        if (element == null || element.isConst) {
          return false;
        }
        _errorReporter.reportError2(CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER, superInvocation, []);
        return true;
      }
    }
    // no explicit super constructor invocation, check default constructor
    InterfaceType supertype = _enclosingClass.supertype;
    if (supertype == null) {
      return false;
    }
    if (supertype.isObject) {
      return false;
    }
    ConstructorElement unnamedConstructor = supertype.element.unnamedConstructor;
    if (unnamedConstructor == null) {
      return false;
    }
    if (unnamedConstructor.isConst) {
      return false;
    }
    // default constructor is not 'const', report problem
    _errorReporter.reportError2(CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER, node, []);
    return true;
  }

  /**
   * This verifies that if the passed constructor declaration is 'const' then there are no non-final
   * instance variable.
   *
   * @param node the constructor declaration to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD
   */
  bool checkForConstConstructorWithNonFinalField(ConstructorDeclaration node) {
    if (!_isEnclosingConstructorConst) {
      return false;
    }
    // check if there is non-final field
    ConstructorElement constructorElement = node.element;
    ClassElement classElement = constructorElement.enclosingElement;
    if (!classElement.hasNonFinalField()) {
      return false;
    }
    // report problem
    _errorReporter.reportError2(CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD, node, []);
    return true;
  }

  /**
   * This verifies that the passed throw expression is not enclosed in a 'const' constructor
   * declaration.
   *
   * @param node the throw expression expression to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#CONST_CONSTRUCTOR_THROWS_EXCEPTION
   */
  bool checkForConstEvalThrowsException(ThrowExpression node) {
    if (_isEnclosingConstructorConst) {
      _errorReporter.reportError2(CompileTimeErrorCode.CONST_CONSTRUCTOR_THROWS_EXCEPTION, node, []);
      return true;
    }
    return false;
  }

  /**
   * This verifies that the passed normal formal parameter is not 'const'.
   *
   * @param node the normal formal parameter to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#CONST_FORMAL_PARAMETER
   */
  bool checkForConstFormalParameter(NormalFormalParameter node) {
    if (node.isConst) {
      _errorReporter.reportError2(CompileTimeErrorCode.CONST_FORMAL_PARAMETER, node, []);
      return true;
    }
    return false;
  }

  /**
   * This verifies that the all keys of the passed map literal have class type that does not declare
   * operator <i>==<i>.
   *
   * @param key the map literal to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#CONST_MAP_KEY_EXPRESSION_TYPE_IMPLEMENTS_EQUALS
   */
  bool checkForConstMapKeyExpressionTypeImplementsEquals(MapLiteral node) {
    // OK, not const.
    if (node.constKeyword == null) {
      return false;
    }
    // Check every map entry.
    bool hasProblems = false;
    for (MapLiteralEntry entry in node.entries) {
      Expression key = entry.key;
      Type2 type = key.staticType;
      if (implementsEqualsWhenNotAllowed(type)) {
        _errorReporter.reportError2(CompileTimeErrorCode.CONST_MAP_KEY_EXPRESSION_TYPE_IMPLEMENTS_EQUALS, key, [type.displayName]);
        hasProblems = true;
      }
    }
    return hasProblems;
  }

  /**
   * This verifies that the passed instance creation expression is not being invoked on an abstract
   * class.
   *
   * @param node the instance creation expression to evaluate
   * @param typeName the [TypeName] of the [ConstructorName] from the
   *          [InstanceCreationExpression], this is the AST node that the error is attached to
   * @param type the type being constructed with this [InstanceCreationExpression]
   * @return `true` if and only if an error code is generated on the passed node
   * @see StaticWarningCode#CONST_WITH_ABSTRACT_CLASS
   * @see StaticWarningCode#NEW_WITH_ABSTRACT_CLASS
   */
  bool checkForConstOrNewWithAbstractClass(InstanceCreationExpression node, TypeName typeName, InterfaceType type) {
    if (type.element.isAbstract) {
      ConstructorElement element = node.staticElement;
      if (element != null && !element.isFactory) {
        if (identical((node.keyword as sc.KeywordToken).keyword, sc.Keyword.CONST)) {
          _errorReporter.reportError2(StaticWarningCode.CONST_WITH_ABSTRACT_CLASS, typeName, []);
        } else {
          _errorReporter.reportError2(StaticWarningCode.NEW_WITH_ABSTRACT_CLASS, typeName, []);
        }
        return true;
      }
    }
    return false;
  }

  /**
   * This verifies that the passed 'const' instance creation expression is not being invoked on a
   * constructor that is not 'const'.
   *
   * This method assumes that the instance creation was tested to be 'const' before being called.
   *
   * @param node the instance creation expression to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#CONST_WITH_NON_CONST
   */
  bool checkForConstWithNonConst(InstanceCreationExpression node) {
    ConstructorElement constructorElement = node.staticElement;
    if (constructorElement != null && !constructorElement.isConst) {
      _errorReporter.reportError2(CompileTimeErrorCode.CONST_WITH_NON_CONST, node, []);
      return true;
    }
    return false;
  }

  /**
   * This verifies that the passed type name does not reference any type parameters.
   *
   * @param typeName the type name to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#CONST_WITH_TYPE_PARAMETERS
   */
  bool checkForConstWithTypeParameters(TypeName typeName) {
    // something wrong with AST
    if (typeName == null) {
      return false;
    }
    Identifier name = typeName.name;
    if (name == null) {
      return false;
    }
    // should not be a type parameter
    if (name.staticElement is TypeParameterElement) {
      _errorReporter.reportError2(CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS, name, []);
    }
    // check type arguments
    TypeArgumentList typeArguments = typeName.typeArguments;
    if (typeArguments != null) {
      bool hasError = false;
      for (TypeName argument in typeArguments.arguments) {
        hasError = javaBooleanOr(hasError, checkForConstWithTypeParameters(argument));
      }
      return hasError;
    }
    // OK
    return false;
  }

  /**
   * This verifies that the passed 'const' instance creation expression does not reference any type
   * parameters.
   *
   * This method assumes that the instance creation was tested to be 'const' before being called.
   *
   * @param node the instance creation expression to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#CONST_WITH_TYPE_PARAMETERS
   */
  bool checkForConstWithTypeParametersInCreation(InstanceCreationExpression node) {
    ConstructorName constructorName = node.constructorName;
    if (constructorName == null) {
      return false;
    }
    TypeName typeName = constructorName.type;
    return checkForConstWithTypeParameters(typeName);
  }

  /**
   * This verifies that if the passed 'const' instance creation expression is being invoked on the
   * resolved constructor.
   *
   * This method assumes that the instance creation was tested to be 'const' before being called.
   *
   * @param node the instance creation expression to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#CONST_WITH_UNDEFINED_CONSTRUCTOR
   * @see CompileTimeErrorCode#CONST_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT
   */
  bool checkForConstWithUndefinedConstructor(InstanceCreationExpression node) {
    // OK if resolved
    if (node.staticElement != null) {
      return false;
    }
    // prepare constructor name
    ConstructorName constructorName = node.constructorName;
    if (constructorName == null) {
      return false;
    }
    // prepare class name
    TypeName type = constructorName.type;
    if (type == null) {
      return false;
    }
    Identifier className = type.name;
    // report as named or default constructor absence
    SimpleIdentifier name = constructorName.name;
    if (name != null) {
      _errorReporter.reportError2(CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR, name, [className, name]);
    } else {
      _errorReporter.reportError2(CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT, constructorName, [className]);
    }
    return true;
  }

  /**
   * This verifies that there are no default parameters in the passed function type alias.
   *
   * @param node the function type alias to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#DEFAULT_VALUE_IN_FUNCTION_TYPE_ALIAS
   */
  bool checkForDefaultValueInFunctionTypeAlias(FunctionTypeAlias node) {
    bool result = false;
    FormalParameterList formalParameterList = node.parameters;
    NodeList<FormalParameter> parameters = formalParameterList.parameters;
    for (FormalParameter formalParameter in parameters) {
      if (formalParameter is DefaultFormalParameter) {
        DefaultFormalParameter defaultFormalParameter = formalParameter;
        if (defaultFormalParameter.defaultValue != null) {
          _errorReporter.reportError2(CompileTimeErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE_ALIAS, node, []);
          result = true;
        }
      }
    }
    return result;
  }

  /**
   * This verifies that the given default formal parameter is not part of a function typed
   * parameter.
   *
   * @param node the default formal parameter to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#DEFAULT_VALUE_IN_FUNCTION_TYPED_PARAMETER
   */
  bool checkForDefaultValueInFunctionTypedParameter(DefaultFormalParameter node) {
    // OK, not in a function typed parameter.
    if (!_isInFunctionTypedFormalParameter) {
      return false;
    }
    // OK, no default value.
    if (node.defaultValue == null) {
      return false;
    }
    // Report problem.
    _errorReporter.reportError2(CompileTimeErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPED_PARAMETER, node, []);
    return true;
  }

  /**
   * This verifies that the enclosing class does not have an instance member with the given name of
   * the static member.
   *
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#DUPLICATE_DEFINITION_INHERITANCE
   */
  bool checkForDuplicateDefinitionInheritance() {
    if (_enclosingClass == null) {
      return false;
    }
    bool hasProblem = false;
    for (ExecutableElement member in _enclosingClass.methods) {
      if (!member.isStatic) {
        continue;
      }
      hasProblem = javaBooleanOr(hasProblem, checkForDuplicateDefinitionOfMember(member));
    }
    for (ExecutableElement member in _enclosingClass.accessors) {
      if (!member.isStatic) {
        continue;
      }
      hasProblem = javaBooleanOr(hasProblem, checkForDuplicateDefinitionOfMember(member));
    }
    return hasProblem;
  }

  /**
   * This verifies that the enclosing class does not have an instance member with the given name of
   * the static member.
   *
   * @param staticMember the static member to check conflict for
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#DUPLICATE_DEFINITION_INHERITANCE
   */
  bool checkForDuplicateDefinitionOfMember(ExecutableElement staticMember) {
    // prepare name
    String name = staticMember.name;
    if (name == null) {
      return false;
    }
    // try to find member
    ExecutableElement inheritedMember = _inheritanceManager.lookupInheritance(_enclosingClass, name);
    if (inheritedMember == null) {
      return false;
    }
    // OK, also static
    if (inheritedMember.isStatic) {
      return false;
    }
    // report problem
    _errorReporter.reportError4(CompileTimeErrorCode.DUPLICATE_DEFINITION_INHERITANCE, staticMember.nameOffset, name.length, [name, inheritedMember.enclosingElement.displayName]);
    return true;
  }

  /**
   * This verifies if the passed list literal has type arguments then there is exactly one.
   *
   * @param node the list literal to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see StaticTypeWarningCode#EXPECTED_ONE_LIST_TYPE_ARGUMENTS
   */
  bool checkForExpectedOneListTypeArgument(ListLiteral node) {
    // prepare type arguments
    TypeArgumentList typeArguments = node.typeArguments;
    if (typeArguments == null) {
      return false;
    }
    // check number of type arguments
    int num = typeArguments.arguments.length;
    if (num == 1) {
      return false;
    }
    // report problem
    _errorReporter.reportError2(StaticTypeWarningCode.EXPECTED_ONE_LIST_TYPE_ARGUMENTS, typeArguments, [num]);
    return true;
  }

  /**
   * This verifies the passed import has unique name among other exported libraries.
   *
   * @param node the export directive to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#EXPORT_DUPLICATED_LIBRARY_NAME
   */
  bool checkForExportDuplicateLibraryName(ExportDirective node) {
    // prepare import element
    Element nodeElement = node.element;
    if (nodeElement is! ExportElement) {
      return false;
    }
    ExportElement nodeExportElement = nodeElement as ExportElement;
    // prepare exported library
    LibraryElement nodeLibrary = nodeExportElement.exportedLibrary;
    if (nodeLibrary == null) {
      return false;
    }
    String name = nodeLibrary.name;
    // check if there is other exported library with the same name
    LibraryElement prevLibrary = _nameToExportElement[name];
    if (prevLibrary != null) {
      if (prevLibrary != nodeLibrary) {
        _errorReporter.reportError2(StaticWarningCode.EXPORT_DUPLICATED_LIBRARY_NAME, node, [
            prevLibrary.definingCompilationUnit.displayName,
            nodeLibrary.definingCompilationUnit.displayName,
            name]);
        return true;
      }
    } else {
      _nameToExportElement[name] = nodeLibrary;
    }
    // OK
    return false;
  }

  /**
   * Check that if the visiting library is not system, then any passed library should not be SDK
   * internal library.
   *
   * @param node the export directive to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#EXPORT_INTERNAL_LIBRARY
   */
  bool checkForExportInternalLibrary(ExportDirective node) {
    if (_isInSystemLibrary) {
      return false;
    }
    // prepare export element
    Element element = node.element;
    if (element is! ExportElement) {
      return false;
    }
    ExportElement exportElement = element as ExportElement;
    // should be private
    DartSdk sdk = _currentLibrary.context.sourceFactory.dartSdk;
    String uri = exportElement.uri;
    SdkLibrary sdkLibrary = sdk.getSdkLibrary(uri);
    if (sdkLibrary == null) {
      return false;
    }
    if (!sdkLibrary.isInternal) {
      return false;
    }
    // report problem
    _errorReporter.reportError2(CompileTimeErrorCode.EXPORT_INTERNAL_LIBRARY, node, [node.uri]);
    return true;
  }

  /**
   * This verifies that the passed extends clause does not extend classes such as num or String.
   *
   * @param node the extends clause to test
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#EXTENDS_DISALLOWED_CLASS
   */
  bool checkForExtendsDisallowedClass(ExtendsClause node) {
    if (node == null) {
      return false;
    }
    return checkForExtendsOrImplementsDisallowedClass(node.superclass, CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS);
  }

  /**
   * This verifies that the passed type name does not extend or implement classes such as 'num' or
   * 'String'.
   *
   * @param node the type name to test
   * @return `true` if and only if an error code is generated on the passed node
   * @see #checkForExtendsDisallowedClass(ExtendsClause)
   * @see #checkForImplementsDisallowedClass(ImplementsClause)
   * @see CompileTimeErrorCode#EXTENDS_DISALLOWED_CLASS
   * @see CompileTimeErrorCode#IMPLEMENTS_DISALLOWED_CLASS
   */
  bool checkForExtendsOrImplementsDisallowedClass(TypeName typeName, ErrorCode errorCode) {
    if (typeName.isSynthetic) {
      return false;
    }
    Type2 superType = typeName.type;
    for (InterfaceType disallowedType in _DISALLOWED_TYPES_TO_EXTEND_OR_IMPLEMENT) {
      if (superType != null && superType == disallowedType) {
        // if the violating type happens to be 'num', we need to rule out the case where the
        // enclosing class is 'int' or 'double'
        if (superType == _typeProvider.numType) {
          AstNode grandParent = typeName.parent.parent;
          // Note: this is a corner case that won't happen often, so adding a field currentClass
          // (see currentFunction) to ErrorVerifier isn't worth if for this case, but if the field
          // currentClass is added, then this message should become a todo to not lookup the
          // grandparent node
          if (grandParent is ClassDeclaration) {
            ClassElement classElement = grandParent.element;
            Type2 classType = classElement.type;
            if (classType != null && (classType == _typeProvider.intType || classType == _typeProvider.doubleType)) {
              return false;
            }
          }
        }
        // otherwise, report the error
        _errorReporter.reportError2(errorCode, typeName, [disallowedType.displayName]);
        return true;
      }
    }
    return false;
  }

  /**
   * This verifies that the passed constructor field initializer has compatible field and
   * initializer expression types.
   *
   * @param node the constructor field initializer to test
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#CONST_FIELD_INITIALIZER_NOT_ASSIGNABLE
   * @see StaticWarningCode#FIELD_INITIALIZER_NOT_ASSIGNABLE
   */
  bool checkForFieldInitializerNotAssignable(ConstructorFieldInitializer node) {
    // prepare field element
    Element staticElement = node.fieldName.staticElement;
    if (staticElement is! FieldElement) {
      return false;
    }
    FieldElement fieldElement = staticElement as FieldElement;
    // prepare field type
    Type2 fieldType = fieldElement.type;
    // prepare expression type
    Expression expression = node.expression;
    if (expression == null) {
      return false;
    }
    // test the static type of the expression
    Type2 staticType = getStaticType(expression);
    if (staticType == null) {
      return false;
    }
    if (staticType.isAssignableTo(fieldType)) {
      return false;
    }
    // report problem
    if (_isEnclosingConstructorConst) {
      _errorReporter.reportError2(CompileTimeErrorCode.CONST_FIELD_INITIALIZER_NOT_ASSIGNABLE, expression, [staticType.displayName, fieldType.displayName]);
    } else {
      _errorReporter.reportError2(StaticWarningCode.FIELD_INITIALIZER_NOT_ASSIGNABLE, expression, [staticType.displayName, fieldType.displayName]);
    }
    return true;
  }

  /**
   * This verifies that the passed field formal parameter is in a constructor declaration.
   *
   * @param node the field formal parameter to test
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR
   */
  bool checkForFieldInitializingFormalRedirectingConstructor(FieldFormalParameter node) {
    ConstructorDeclaration constructor = node.getAncestor((node) => node is ConstructorDeclaration);
    if (constructor == null) {
      _errorReporter.reportError2(CompileTimeErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR, node, []);
      return true;
    }
    // constructor cannot be a factory
    if (constructor.factoryKeyword != null) {
      _errorReporter.reportError2(CompileTimeErrorCode.FIELD_INITIALIZER_FACTORY_CONSTRUCTOR, node, []);
      return true;
    }
    // constructor cannot have a redirection
    for (ConstructorInitializer initializer in constructor.initializers) {
      if (initializer is RedirectingConstructorInvocation) {
        _errorReporter.reportError2(CompileTimeErrorCode.FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR, node, []);
        return true;
      }
    }
    // OK
    return false;
  }

  /**
   * This verifies that the passed variable declaration list has only initialized variables if the
   * list is final or const. This method is called by
   * [checkForFinalNotInitializedInClass],
   * [visitTopLevelVariableDeclaration] and
   * [visitVariableDeclarationStatement].
   *
   * @param node the class declaration to test
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#CONST_NOT_INITIALIZED
   * @see StaticWarningCode#FINAL_NOT_INITIALIZED
   */
  bool checkForFinalNotInitialized(VariableDeclarationList node) {
    if (_isInNativeClass) {
      return false;
    }
    bool foundError = false;
    if (!node.isSynthetic) {
      NodeList<VariableDeclaration> variables = node.variables;
      for (VariableDeclaration variable in variables) {
        if (variable.initializer == null) {
          if (node.isConst) {
            _errorReporter.reportError2(CompileTimeErrorCode.CONST_NOT_INITIALIZED, variable.name, [variable.name.name]);
          } else if (node.isFinal) {
            _errorReporter.reportError2(StaticWarningCode.FINAL_NOT_INITIALIZED, variable.name, [variable.name.name]);
          }
          foundError = true;
        }
      }
    }
    return foundError;
  }

  /**
   * This verifies that final fields that are declared, without any constructors in the enclosing
   * class, are initialized. Cases in which there is at least one constructor are handled at the end
   * of [checkForAllFinalInitializedErrorCodes].
   *
   * @param node the class declaration to test
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#CONST_NOT_INITIALIZED
   * @see StaticWarningCode#FINAL_NOT_INITIALIZED
   */
  bool checkForFinalNotInitializedInClass(ClassDeclaration node) {
    NodeList<ClassMember> classMembers = node.members;
    for (ClassMember classMember in classMembers) {
      if (classMember is ConstructorDeclaration) {
        return false;
      }
    }
    bool foundError = false;
    for (ClassMember classMember in classMembers) {
      if (classMember is FieldDeclaration) {
        FieldDeclaration field = classMember;
        foundError = javaBooleanOr(foundError, checkForFinalNotInitialized(field.fields));
      }
    }
    return foundError;
  }

  /**
   * This verifies that the passed implements clause does not implement classes such as 'num' or
   * 'String'.
   *
   * @param node the implements clause to test
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#IMPLEMENTS_DISALLOWED_CLASS
   */
  bool checkForImplementsDisallowedClass(ImplementsClause node) {
    if (node == null) {
      return false;
    }
    bool foundError = false;
    for (TypeName type in node.interfaces) {
      foundError = javaBooleanOr(foundError, checkForExtendsOrImplementsDisallowedClass(type, CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS));
    }
    return foundError;
  }

  /**
   * This verifies that if the passed identifier is part of constructor initializer, then it does
   * not reference implicitly 'this' expression.
   *
   * @param node the simple identifier to test
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#IMPLICIT_THIS_REFERENCE_IN_INITIALIZER
   * @see CompileTimeErrorCode#INSTANCE_MEMBER_ACCESS_FROM_STATIC TODO(scheglov) rename thid method
   */
  bool checkForImplicitThisReferenceInInitializer(SimpleIdentifier node) {
    if (!_isInConstructorInitializer && !_isInStaticMethod && !_isInInstanceVariableInitializer && !_isInStaticVariableDeclaration) {
      return false;
    }
    // prepare element
    Element element = node.staticElement;
    if (!(element is MethodElement || element is PropertyAccessorElement)) {
      return false;
    }
    // static element
    ExecutableElement executableElement = element as ExecutableElement;
    if (executableElement.isStatic) {
      return false;
    }
    // not a class member
    Element enclosingElement = element.enclosingElement;
    if (enclosingElement is! ClassElement) {
      return false;
    }
    // comment
    AstNode parent = node.parent;
    if (parent is CommentReference) {
      return false;
    }
    // qualified method invocation
    if (parent is MethodInvocation) {
      MethodInvocation invocation = parent;
      if (identical(invocation.methodName, node) && invocation.realTarget != null) {
        return false;
      }
    }
    // qualified property access
    if (parent is PropertyAccess) {
      PropertyAccess access = parent;
      if (identical(access.propertyName, node) && access.realTarget != null) {
        return false;
      }
    }
    if (parent is PrefixedIdentifier) {
      PrefixedIdentifier prefixed = parent;
      if (identical(prefixed.identifier, node)) {
        return false;
      }
    }
    // report problem
    if (_isInStaticMethod) {
      _errorReporter.reportError2(CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_STATIC, node, []);
    } else {
      _errorReporter.reportError2(CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER, node, []);
    }
    return true;
  }

  /**
   * This verifies the passed import has unique name among other imported libraries.
   *
   * @param node the import directive to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#IMPORT_DUPLICATED_LIBRARY_NAME
   */
  bool checkForImportDuplicateLibraryName(ImportDirective node) {
    // prepare import element
    ImportElement nodeImportElement = node.element;
    if (nodeImportElement == null) {
      return false;
    }
    // prepare imported library
    LibraryElement nodeLibrary = nodeImportElement.importedLibrary;
    if (nodeLibrary == null) {
      return false;
    }
    String name = nodeLibrary.name;
    // check if there is other imported library with the same name
    LibraryElement prevLibrary = _nameToImportElement[name];
    if (prevLibrary != null) {
      if (prevLibrary != nodeLibrary) {
        _errorReporter.reportError2(StaticWarningCode.IMPORT_DUPLICATED_LIBRARY_NAME, node, [
            prevLibrary.definingCompilationUnit.displayName,
            nodeLibrary.definingCompilationUnit.displayName,
            name]);
        return true;
      }
    } else {
      _nameToImportElement[name] = nodeLibrary;
    }
    // OK
    return false;
  }

  /**
   * Check that if the visiting library is not system, then any passed library should not be SDK
   * internal library.
   *
   * @param node the import directive to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#IMPORT_INTERNAL_LIBRARY
   */
  bool checkForImportInternalLibrary(ImportDirective node) {
    if (_isInSystemLibrary) {
      return false;
    }
    // prepare import element
    ImportElement importElement = node.element;
    if (importElement == null) {
      return false;
    }
    // should be private
    DartSdk sdk = _currentLibrary.context.sourceFactory.dartSdk;
    String uri = importElement.uri;
    SdkLibrary sdkLibrary = sdk.getSdkLibrary(uri);
    if (sdkLibrary == null) {
      return false;
    }
    if (!sdkLibrary.isInternal) {
      return false;
    }
    // report problem
    _errorReporter.reportError2(CompileTimeErrorCode.IMPORT_INTERNAL_LIBRARY, node, [node.uri]);
    return true;
  }

  /**
   * This verifies that the passed switch statement case expressions all have the same type.
   *
   * @param node the switch statement to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#INCONSISTENT_CASE_EXPRESSION_TYPES
   */
  bool checkForInconsistentCaseExpressionTypes(SwitchStatement node) {
    // TODO(jwren) Revisit this algorithm, should there up to n-1 errors?
    NodeList<SwitchMember> switchMembers = node.members;
    bool foundError = false;
    Type2 firstType = null;
    for (SwitchMember switchMember in switchMembers) {
      if (switchMember is SwitchCase) {
        SwitchCase switchCase = switchMember;
        Expression expression = switchCase.expression;
        if (firstType == null) {
          // TODO(brianwilkerson) This is failing with const variables whose declared type is
          // dynamic. The problem is that we don't have any way to propagate type information for
          // the variable.
          firstType = expression.bestType;
        } else {
          Type2 nType = expression.bestType;
          if (firstType != nType) {
            _errorReporter.reportError2(CompileTimeErrorCode.INCONSISTENT_CASE_EXPRESSION_TYPES, expression, [expression.toSource(), firstType.displayName]);
            foundError = true;
          }
        }
      }
    }
    if (!foundError) {
      checkForCaseExpressionTypeImplementsEquals(node, firstType);
    }
    return foundError;
  }

  /**
   * For each class declaration, this method is called which verifies that all inherited members are
   * inherited consistently.
   *
   * @return `true` if and only if an error code is generated on the passed node
   * @see StaticTypeWarningCode#INCONSISTENT_METHOD_INHERITANCE
   */
  bool checkForInconsistentMethodInheritance() {
    // Ensure that the inheritance manager has a chance to generate all errors we may care about,
    // note that we ensure that the interfaces data since there are no errors.
    _inheritanceManager.getMapOfMembersInheritedFromInterfaces(_enclosingClass);
    Set<AnalysisError> errors = _inheritanceManager.getErrors(_enclosingClass);
    if (errors == null || errors.isEmpty) {
      return false;
    }
    for (AnalysisError error in errors) {
      _errorReporter.reportError(error);
    }
    return true;
  }

  /**
   * This checks the given "typeReference" is not a type reference and that then the "name" is
   * reference to an instance member.
   *
   * @param typeReference the resolved [ClassElement] of the left hand side of the expression,
   *          or `null`, aka, the class element of 'C' in 'C.x', see
   *          [getTypeReference]
   * @param name the accessed name to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see StaticTypeWarningCode#INSTANCE_ACCESS_TO_STATIC_MEMBER
   */
  bool checkForInstanceAccessToStaticMember(ClassElement typeReference, SimpleIdentifier name) {
    // OK, in comment
    if (_isInComment) {
      return false;
    }
    // OK, target is a type
    if (typeReference != null) {
      return false;
    }
    // prepare member Element
    Element element = name.staticElement;
    if (element is! ExecutableElement) {
      return false;
    }
    ExecutableElement executableElement = element as ExecutableElement;
    // OK, top-level element
    if (executableElement.enclosingElement is! ClassElement) {
      return false;
    }
    // OK, instance member
    if (!executableElement.isStatic) {
      return false;
    }
    // report problem
    _errorReporter.reportError2(StaticTypeWarningCode.INSTANCE_ACCESS_TO_STATIC_MEMBER, name, [name.name]);
    return true;
  }

  /**
   * This verifies that an 'int' can be assigned to the parameter corresponding to the given
   * expression. This is used for prefix and postfix expressions where the argument value is
   * implicit.
   *
   * @param argument the expression to which the operator is being applied
   * @return `true` if and only if an error code is generated on the passed node
   * @see StaticWarningCode#ARGUMENT_TYPE_NOT_ASSIGNABLE
   */
  bool checkForIntNotAssignable(Expression argument) {
    if (argument == null) {
      return false;
    }
    ParameterElement staticParameterElement = argument.staticParameterElement;
    Type2 staticParameterType = staticParameterElement == null ? null : staticParameterElement.type;
    ParameterElement propagatedParameterElement = argument.propagatedParameterElement;
    Type2 propagatedParameterType = propagatedParameterElement == null ? null : propagatedParameterElement.type;
    return checkForArgumentTypeNotAssignable(argument, staticParameterType, _typeProvider.intType, propagatedParameterType, _typeProvider.intType, StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE);
  }

  /**
   * This verifies that the passed left hand side and right hand side represent a valid assignment.
   *
   * @param lhs the left hand side expression
   * @param rhs the right hand side expression
   * @return `true` if and only if an error code is generated on the passed node
   * @see StaticTypeWarningCode#INVALID_ASSIGNMENT
   */
  bool checkForInvalidAssignment(Expression lhs, Expression rhs) {
    if (lhs == null || rhs == null) {
      return false;
    }
    VariableElement leftElement = getVariableElement(lhs);
    Type2 leftType = (leftElement == null) ? getStaticType(lhs) : leftElement.type;
    Type2 staticRightType = getStaticType(rhs);
    bool isStaticAssignable = staticRightType.isAssignableTo(leftType);
    if (!isStaticAssignable) {
      String leftName = leftType.displayName;
      String rightName = staticRightType.displayName;
      if (leftName == rightName) {
        leftName = getExtendedDisplayName(leftType);
        rightName = getExtendedDisplayName(staticRightType);
      }
      _errorReporter.reportError2(StaticTypeWarningCode.INVALID_ASSIGNMENT, rhs, [rightName, leftName]);
      return true;
    }
    // TODO(brianwilkerson) Define a hint corresponding to the warning and report it if appropriate.
    //    Type propagatedRightType = rhs.getPropagatedType();
    //    boolean isPropagatedAssignable = propagatedRightType.isAssignableTo(leftType);
    //    if (!isStaticAssignable && !isPropagatedAssignable) {
    //      errorReporter.reportError(
    //          StaticTypeWarningCode.INVALID_ASSIGNMENT,
    //          rhs,
    //          staticRightType.getDisplayName(),
    //          leftType.getDisplayName());
    //      return true;
    //    }
    return false;
  }

  /**
   * Given an assignment using a compound assignment operator, this verifies that the given
   * assignment is valid.
   *
   * @param node the assignment expression being tested
   * @return `true` if and only if an error code is generated on the passed node
   * @see StaticTypeWarningCode#INVALID_ASSIGNMENT
   */
  bool checkForInvalidCompoundAssignment(AssignmentExpression node) {
    Expression lhs = node.leftHandSide;
    if (lhs == null) {
      return false;
    }
    VariableElement leftElement = getVariableElement(lhs);
    Type2 leftType = (leftElement == null) ? getStaticType(lhs) : leftElement.type;
    MethodElement invokedMethod = node.staticElement;
    if (invokedMethod == null) {
      return false;
    }
    Type2 rightType = invokedMethod.type.returnType;
    if (leftType == null || rightType == null) {
      return false;
    }
    if (!rightType.isAssignableTo(leftType)) {
      String leftName = leftType.displayName;
      String rightName = rightType.displayName;
      if (leftName == rightName) {
        leftName = getExtendedDisplayName(leftType);
        rightName = getExtendedDisplayName(rightType);
      }
      _errorReporter.reportError2(StaticTypeWarningCode.INVALID_ASSIGNMENT, node.rightHandSide, [rightName, leftName]);
      return true;
    }
    return false;
  }

  /**
   * Check the given initializer to ensure that the field being initialized is a valid field.
   *
   * @param node the field initializer being checked
   */
  void checkForInvalidField(ConstructorFieldInitializer node) {
    SimpleIdentifier fieldName = node.fieldName;
    Element staticElement = fieldName.staticElement;
    if (staticElement is FieldElement) {
      FieldElement fieldElement = staticElement;
      if (fieldElement.isSynthetic) {
        _errorReporter.reportError2(CompileTimeErrorCode.INITIALIZER_FOR_NON_EXISTANT_FIELD, node, [fieldName]);
      } else if (fieldElement.isStatic) {
        _errorReporter.reportError2(CompileTimeErrorCode.INITIALIZER_FOR_STATIC_FIELD, node, [fieldName]);
      }
    } else {
      _errorReporter.reportError2(CompileTimeErrorCode.INITIALIZER_FOR_NON_EXISTANT_FIELD, node, [fieldName]);
      return;
    }
  }

  /**
   * This verifies that the usage of the passed 'this' is valid.
   *
   * @param node the 'this' expression to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#INVALID_REFERENCE_TO_THIS
   */
  bool checkForInvalidReferenceToThis(ThisExpression node) {
    if (!isThisInValidContext(node)) {
      _errorReporter.reportError2(CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS, node, []);
      return true;
    }
    return false;
  }

  /**
   * Checks to ensure that the passed [ListLiteral] or [MapLiteral] does not have a type
   * parameter as a type argument.
   *
   * @param arguments a non-`null`, non-empty [TypeName] node list from the respective
   *          [ListLiteral] or [MapLiteral]
   * @param errorCode either [CompileTimeErrorCode#INVALID_TYPE_ARGUMENT_IN_CONST_LIST] or
   *          [CompileTimeErrorCode#INVALID_TYPE_ARGUMENT_IN_CONST_MAP]
   * @return `true` if and only if an error code is generated on the passed node
   */
  bool checkForInvalidTypeArgumentInConstTypedLiteral(NodeList<TypeName> arguments, ErrorCode errorCode) {
    bool foundError = false;
    for (TypeName typeName in arguments) {
      if (typeName.type is TypeParameterType) {
        _errorReporter.reportError2(errorCode, typeName, [typeName.name]);
        foundError = true;
      }
    }
    return foundError;
  }

  /**
   * This verifies that the elements given [ListLiteral] are subtypes of the specified element
   * type.
   *
   * @param node the list literal to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
   * @see StaticWarningCode#LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
   */
  bool checkForListElementTypeNotAssignable(ListLiteral node) {
    // Prepare list element type.
    TypeArgumentList typeArgumentList = node.typeArguments;
    if (typeArgumentList == null) {
      return false;
    }
    NodeList<TypeName> typeArguments = typeArgumentList.arguments;
    if (typeArguments.length < 1) {
      return false;
    }
    Type2 listElementType = typeArguments[0].type;
    // Prepare problem to report.
    ErrorCode errorCode;
    if (node.constKeyword != null) {
      errorCode = CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE;
    } else {
      errorCode = StaticWarningCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE;
    }
    // Check every list element.
    bool hasProblems = false;
    for (Expression element in node.elements) {
      hasProblems = javaBooleanOr(hasProblems, checkForArgumentTypeNotAssignableWithExpectedTypes(element, listElementType, null, errorCode));
    }
    return hasProblems;
  }

  /**
   * This verifies that the key/value of entries of the given [MapLiteral] are subtypes of the
   * key/value types specified in the type arguments.
   *
   * @param node the map literal to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#MAP_KEY_TYPE_NOT_ASSIGNABLE
   * @see CompileTimeErrorCode#MAP_VALUE_TYPE_NOT_ASSIGNABLE
   * @see StaticWarningCode#MAP_KEY_TYPE_NOT_ASSIGNABLE
   * @see StaticWarningCode#MAP_VALUE_TYPE_NOT_ASSIGNABLE
   */
  bool checkForMapTypeNotAssignable(MapLiteral node) {
    // Prepare maps key/value types.
    TypeArgumentList typeArgumentList = node.typeArguments;
    if (typeArgumentList == null) {
      return false;
    }
    NodeList<TypeName> typeArguments = typeArgumentList.arguments;
    if (typeArguments.length < 2) {
      return false;
    }
    Type2 keyType = typeArguments[0].type;
    Type2 valueType = typeArguments[1].type;
    // Prepare problem to report.
    ErrorCode keyErrorCode;
    ErrorCode valueErrorCode;
    if (node.constKeyword != null) {
      keyErrorCode = CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE;
      valueErrorCode = CompileTimeErrorCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE;
    } else {
      keyErrorCode = StaticWarningCode.MAP_KEY_TYPE_NOT_ASSIGNABLE;
      valueErrorCode = StaticWarningCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE;
    }
    // Check every map entry.
    bool hasProblems = false;
    NodeList<MapLiteralEntry> entries = node.entries;
    for (MapLiteralEntry entry in entries) {
      Expression key = entry.key;
      Expression value = entry.value;
      hasProblems = javaBooleanOr(hasProblems, checkForArgumentTypeNotAssignableWithExpectedTypes(key, keyType, null, keyErrorCode));
      hasProblems = javaBooleanOr(hasProblems, checkForArgumentTypeNotAssignableWithExpectedTypes(value, valueType, null, valueErrorCode));
    }
    return hasProblems;
  }

  /**
   * This verifies that the [enclosingClass] does not define members with the same name as
   * the enclosing class.
   *
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#MEMBER_WITH_CLASS_NAME
   */
  bool checkForMemberWithClassName() {
    if (_enclosingClass == null) {
      return false;
    }
    String className = _enclosingClass.name;
    if (className == null) {
      return false;
    }
    bool problemReported = false;
    // check accessors
    for (PropertyAccessorElement accessor in _enclosingClass.accessors) {
      if (className == accessor.name) {
        _errorReporter.reportError4(CompileTimeErrorCode.MEMBER_WITH_CLASS_NAME, accessor.nameOffset, className.length, []);
        problemReported = true;
      }
    }
    // don't check methods, they would be constructors
    // done
    return problemReported;
  }

  /**
   * Check to make sure that all similarly typed accessors are of the same type (including inherited
   * accessors).
   *
   * @param node the accessor currently being visited
   * @return `true` if and only if an error code is generated on the passed node
   * @see StaticWarningCode.MISMATCHED_GETTER_AND_SETTER_TYPES
   * @see StaticWarningCode.MISMATCHED_GETTER_AND_SETTER_TYPES_FROM_SUPERTYPE
   */
  bool checkForMismatchedAccessorTypes(Declaration accessorDeclaration, String accessorTextName) {
    ExecutableElement accessorElement = accessorDeclaration.element as ExecutableElement;
    if (accessorElement is! PropertyAccessorElement) {
      return false;
    }
    PropertyAccessorElement propertyAccessorElement = accessorElement as PropertyAccessorElement;
    PropertyAccessorElement counterpartAccessor = null;
    ClassElement enclosingClassForCounterpart = null;
    if (propertyAccessorElement.isGetter) {
      counterpartAccessor = propertyAccessorElement.correspondingSetter;
    } else {
      counterpartAccessor = propertyAccessorElement.correspondingGetter;
      // If the setter and getter are in the same enclosing element, return, this prevents having
      // MISMATCHED_GETTER_AND_SETTER_TYPES reported twice.
      if (counterpartAccessor != null && identical(counterpartAccessor.enclosingElement, propertyAccessorElement.enclosingElement)) {
        return false;
      }
    }
    if (counterpartAccessor == null) {
      // If the accessor is declared in a class, check the superclasses.
      if (_enclosingClass != null) {
        // Figure out the correct identifier to lookup in the inheritance graph, if 'x', then 'x=',
        // or if 'x=', then 'x'.
        String lookupIdentifier = propertyAccessorElement.name;
        if (StringUtilities.endsWithChar(lookupIdentifier, 0x3D)) {
          lookupIdentifier = lookupIdentifier.substring(0, lookupIdentifier.length - 1);
        } else {
          lookupIdentifier += "=";
        }
        // lookup with the identifier.
        ExecutableElement elementFromInheritance = _inheritanceManager.lookupInheritance(_enclosingClass, lookupIdentifier);
        // Verify that we found something, and that it is an accessor
        if (elementFromInheritance != null && elementFromInheritance is PropertyAccessorElement) {
          enclosingClassForCounterpart = elementFromInheritance.enclosingElement as ClassElement;
          counterpartAccessor = elementFromInheritance;
        }
      }
      if (counterpartAccessor == null) {
        return false;
      }
    }
    // Default of null == no accessor or no type (dynamic)
    Type2 getterType = null;
    Type2 setterType = null;
    // Get an existing counterpart accessor if any.
    if (propertyAccessorElement.isGetter) {
      getterType = getGetterType(propertyAccessorElement);
      setterType = getSetterType(counterpartAccessor);
    } else if (propertyAccessorElement.isSetter) {
      setterType = getSetterType(propertyAccessorElement);
      getterType = getGetterType(counterpartAccessor);
    }
    // If either types are not assignable to each other, report an error (if the getter is null,
    // it is dynamic which is assignable to everything).
    if (setterType != null && getterType != null && !getterType.isAssignableTo(setterType)) {
      if (enclosingClassForCounterpart == null) {
        _errorReporter.reportError2(StaticWarningCode.MISMATCHED_GETTER_AND_SETTER_TYPES, accessorDeclaration, [
            accessorTextName,
            setterType.displayName,
            getterType.displayName]);
        return true;
      } else {
        _errorReporter.reportError2(StaticWarningCode.MISMATCHED_GETTER_AND_SETTER_TYPES_FROM_SUPERTYPE, accessorDeclaration, [
            accessorTextName,
            setterType.displayName,
            getterType.displayName,
            enclosingClassForCounterpart.displayName]);
      }
    }
    return false;
  }

  /**
   * This verifies that the given function body does not contain return statements that both have
   * and do not have return values.
   *
   * @param node the function body being tested
   * @return `true` if and only if an error code is generated on the passed node
   * @see StaticWarningCode#MIXED_RETURN_TYPES
   */
  bool checkForMixedReturns(BlockFunctionBody node) {
    int withCount = _returnsWith.length;
    int withoutCount = _returnsWithout.length;
    if (withCount > 0 && withoutCount > 0) {
      for (int i = 0; i < withCount; i++) {
        _errorReporter.reportError5(StaticWarningCode.MIXED_RETURN_TYPES, _returnsWith[i].keyword, []);
      }
      for (int i = 0; i < withoutCount; i++) {
        _errorReporter.reportError5(StaticWarningCode.MIXED_RETURN_TYPES, _returnsWithout[i].keyword, []);
      }
      return true;
    }
    return false;
  }

  /**
   * This verifies that the passed mixin does not have an explicitly declared constructor.
   *
   * @param mixinName the node to report problem on
   * @param mixinElement the mixing to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#MIXIN_DECLARES_CONSTRUCTOR
   */
  bool checkForMixinDeclaresConstructor(TypeName mixinName, ClassElement mixinElement) {
    for (ConstructorElement constructor in mixinElement.constructors) {
      if (!constructor.isSynthetic && !constructor.isFactory) {
        _errorReporter.reportError2(CompileTimeErrorCode.MIXIN_DECLARES_CONSTRUCTOR, mixinName, [mixinElement.name]);
        return true;
      }
    }
    return false;
  }

  /**
   * This verifies that the passed mixin has the 'Object' superclass.
   *
   * @param mixinName the node to report problem on
   * @param mixinElement the mixing to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#MIXIN_INHERITS_FROM_NOT_OBJECT
   */
  bool checkForMixinInheritsNotFromObject(TypeName mixinName, ClassElement mixinElement) {
    InterfaceType mixinSupertype = mixinElement.supertype;
    if (mixinSupertype != null) {
      if (!mixinSupertype.isObject || !mixinElement.isTypedef && mixinElement.mixins.length != 0) {
        _errorReporter.reportError2(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, mixinName, [mixinElement.name]);
        return true;
      }
    }
    return false;
  }

  /**
   * This verifies that the passed mixin does not reference 'super'.
   *
   * @param mixinName the node to report problem on
   * @param mixinElement the mixing to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#MIXIN_REFERENCES_SUPER
   */
  bool checkForMixinReferencesSuper(TypeName mixinName, ClassElement mixinElement) {
    if (mixinElement.hasReferenceToSuper()) {
      _errorReporter.reportError2(CompileTimeErrorCode.MIXIN_REFERENCES_SUPER, mixinName, [mixinElement.name]);
    }
    return false;
  }

  /**
   * This verifies that the passed constructor has at most one 'super' initializer.
   *
   * @param node the constructor declaration to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#MULTIPLE_SUPER_INITIALIZERS
   */
  bool checkForMultipleSuperInitializers(ConstructorDeclaration node) {
    int numSuperInitializers = 0;
    for (ConstructorInitializer initializer in node.initializers) {
      if (initializer is SuperConstructorInvocation) {
        numSuperInitializers++;
        if (numSuperInitializers > 1) {
          _errorReporter.reportError2(CompileTimeErrorCode.MULTIPLE_SUPER_INITIALIZERS, initializer, []);
        }
      }
    }
    return numSuperInitializers > 0;
  }

  /**
   * Checks to ensure that native function bodies can only in SDK code.
   *
   * @param node the native function body to test
   * @return `true` if and only if an error code is generated on the passed node
   * @see ParserErrorCode#NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE
   */
  bool checkForNativeFunctionBodyInNonSDKCode(NativeFunctionBody node) {
    if (!_isInSystemLibrary && !_hasExtUri) {
      _errorReporter.reportError2(ParserErrorCode.NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE, node, []);
      return true;
    }
    return false;
  }

  /**
   * This verifies that the passed 'new' instance creation expression invokes existing constructor.
   *
   * This method assumes that the instance creation was tested to be 'new' before being called.
   *
   * @param node the instance creation expression to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see StaticWarningCode#NEW_WITH_UNDEFINED_CONSTRUCTOR
   */
  bool checkForNewWithUndefinedConstructor(InstanceCreationExpression node) {
    // OK if resolved
    if (node.staticElement != null) {
      return false;
    }
    // prepare constructor name
    ConstructorName constructorName = node.constructorName;
    if (constructorName == null) {
      return false;
    }
    // prepare class name
    TypeName type = constructorName.type;
    if (type == null) {
      return false;
    }
    Identifier className = type.name;
    // report as named or default constructor absence
    SimpleIdentifier name = constructorName.name;
    if (name != null) {
      _errorReporter.reportError2(StaticWarningCode.NEW_WITH_UNDEFINED_CONSTRUCTOR, name, [className, name]);
    } else {
      _errorReporter.reportError2(StaticWarningCode.NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT, constructorName, [className]);
    }
    return true;
  }

  /**
   * This checks that if the passed class declaration implicitly calls default constructor of its
   * superclass, there should be such default constructor - implicit or explicit.
   *
   * @param node the [ClassDeclaration] to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT
   */
  bool checkForNoDefaultSuperConstructorImplicit(ClassDeclaration node) {
    // do nothing if there is explicit constructor
    List<ConstructorElement> constructors = _enclosingClass.constructors;
    if (!constructors[0].isSynthetic) {
      return false;
    }
    // prepare super
    InterfaceType superType = _enclosingClass.supertype;
    if (superType == null) {
      return false;
    }
    ClassElement superElement = superType.element;
    // try to find default generative super constructor
    ConstructorElement superUnnamedConstructor = superElement.unnamedConstructor;
    if (superUnnamedConstructor != null) {
      if (superUnnamedConstructor.isFactory) {
        _errorReporter.reportError2(CompileTimeErrorCode.NON_GENERATIVE_CONSTRUCTOR, node.name, [superUnnamedConstructor]);
        return true;
      }
      if (superUnnamedConstructor.isDefaultConstructor) {
        return true;
      }
    }
    // report problem
    _errorReporter.reportError2(CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT, node.name, [superType.displayName]);
    return true;
  }

  /**
   * This checks that passed class declaration overrides all members required by its superclasses
   * and interfaces.
   *
   * @param node the [ClassDeclaration] to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see StaticWarningCode#NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE
   * @see StaticWarningCode#NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO
   * @see StaticWarningCode#NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_THREE
   * @see StaticWarningCode#NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FOUR
   * @see StaticWarningCode#NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FIVE_PLUS
   */
  bool checkForNonAbstractClassInheritsAbstractMember(ClassDeclaration node) {
    if (_enclosingClass.isAbstract) {
      return false;
    }
    //
    // Store in local sets the set of all method and accessor names
    //
    List<MethodElement> methods = _enclosingClass.methods;
    List<PropertyAccessorElement> accessors = _enclosingClass.accessors;
    Set<String> methodsInEnclosingClass = new Set<String>();
    for (MethodElement method in methods) {
      String methodName = method.name;
      // If the enclosing class declares the method noSuchMethod(), then return.
      // From Spec:  It is a static warning if a concrete class does not have an implementation for
      // a method in any of its superinterfaces unless it declares its own noSuchMethod
      // method (7.10).
      if (methodName == ElementResolver.NO_SUCH_METHOD_METHOD_NAME) {
        return false;
      }
      methodsInEnclosingClass.add(methodName);
    }
    Set<String> accessorsInEnclosingClass = new Set<String>();
    for (PropertyAccessorElement accessor in accessors) {
      accessorsInEnclosingClass.add(accessor.name);
    }
    Set<ExecutableElement> missingOverrides = new Set<ExecutableElement>();
    //
    // Loop through the set of all executable elements declared in the implicit interface.
    //
    MemberMap membersInheritedFromInterfaces = _inheritanceManager.getMapOfMembersInheritedFromInterfaces(_enclosingClass);
    MemberMap membersInheritedFromSuperclasses = _inheritanceManager.getMapOfMembersInheritedFromClasses(_enclosingClass);
    for (int i = 0; i < membersInheritedFromInterfaces.size; i++) {
      String memberName = membersInheritedFromInterfaces.getKey(i);
      ExecutableElement executableElt = membersInheritedFromInterfaces.getValue(i);
      if (memberName == null) {
        break;
      }
      // If the element is not synthetic and can be determined to be defined in Object, skip it.
      if (executableElt.enclosingElement != null && (executableElt.enclosingElement as ClassElement).type.isObject) {
        continue;
      }
      // Reference the type of the enclosing class
      InterfaceType enclosingType = _enclosingClass.type;
      // Check to see if some element is in local enclosing class that matches the name of the
      // required member.
      if (isMemberInClassOrMixin(executableElt, _enclosingClass)) {
        // We do not have to verify that this implementation of the found method matches the
        // required function type: the set of StaticWarningCode.INVALID_METHOD_OVERRIDE_* warnings
        // break out the different specific situations.
        continue;
      }
      // First check to see if this element was declared in the superclass chain, in which case
      // there is already a concrete implementation.
      ExecutableElement elt = membersInheritedFromSuperclasses.get(executableElt.name);
      // Check to see if an element was found in the superclass chain with the correct name.
      if (elt != null) {
        // Some element was found in the superclass chain that matches the name of the required
        // member.
        // If it is not abstract and it is the correct one (types match- the version of this method
        // that we have has the correct number of parameters, etc), then this class has a valid
        // implementation of this method, so skip it.
        if ((elt is MethodElement && !elt.isAbstract) || (elt is PropertyAccessorElement && !elt.isAbstract)) {
          // Since we are comparing two function types, we need to do the appropriate type
          // substitutions first ().
          FunctionType foundConcreteFT = _inheritanceManager.substituteTypeArgumentsInMemberFromInheritance(elt.type, executableElt.name, enclosingType);
          FunctionType requiredMemberFT = _inheritanceManager.substituteTypeArgumentsInMemberFromInheritance(executableElt.type, executableElt.name, enclosingType);
          if (foundConcreteFT.isSubtypeOf(requiredMemberFT)) {
            continue;
          }
        }
      }
      // The not qualifying concrete executable element was found, add it to the list.
      missingOverrides.add(executableElt);
    }
    // Now that we have the set of missing overrides, generate a warning on this class
    int missingOverridesSize = missingOverrides.length;
    if (missingOverridesSize == 0) {
      return false;
    }
    List<ExecutableElement> missingOverridesArray = new List.from(missingOverrides);
    List<String> stringMembersArrayListSet = new List<String>();
    for (int i = 0; i < missingOverridesArray.length; i++) {
      String newStrMember;
      if (missingOverridesArray[i].enclosingElement != null) {
        newStrMember = "${missingOverridesArray[i].enclosingElement.displayName}.${missingOverridesArray[i].displayName}";
      } else {
        newStrMember = missingOverridesArray[i].displayName;
      }
      if (!stringMembersArrayListSet.contains(newStrMember)) {
        stringMembersArrayListSet.add(newStrMember);
      }
    }
    List<String> stringMembersArray = new List.from(stringMembersArrayListSet);
    AnalysisErrorWithProperties analysisError;
    if (stringMembersArray.length == 1) {
      analysisError = _errorReporter.newErrorWithProperties(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE, node.name, [stringMembersArray[0]]);
    } else if (stringMembersArray.length == 2) {
      analysisError = _errorReporter.newErrorWithProperties(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO, node.name, [stringMembersArray[0], stringMembersArray[1]]);
    } else if (stringMembersArray.length == 3) {
      analysisError = _errorReporter.newErrorWithProperties(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_THREE, node.name, [
          stringMembersArray[0],
          stringMembersArray[1],
          stringMembersArray[2]]);
    } else if (stringMembersArray.length == 4) {
      analysisError = _errorReporter.newErrorWithProperties(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FOUR, node.name, [
          stringMembersArray[0],
          stringMembersArray[1],
          stringMembersArray[2],
          stringMembersArray[3]]);
    } else {
      analysisError = _errorReporter.newErrorWithProperties(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FIVE_PLUS, node.name, [
          stringMembersArray[0],
          stringMembersArray[1],
          stringMembersArray[2],
          stringMembersArray[3],
          stringMembersArray.length - 4]);
    }
    analysisError.setProperty(ErrorProperty.UNIMPLEMENTED_METHODS, missingOverridesArray);
    _errorReporter.reportError(analysisError);
    return true;
  }

  /**
   * Checks to ensure that the expressions that need to be of type bool, are. Otherwise an error is
   * reported on the expression.
   *
   * @param condition the conditional expression to test
   * @return `true` if and only if an error code is generated on the passed node
   * @see StaticTypeWarningCode#NON_BOOL_CONDITION
   */
  bool checkForNonBoolCondition(Expression condition) {
    Type2 conditionType = getStaticType(condition);
    if (conditionType != null && !conditionType.isAssignableTo(_boolType)) {
      _errorReporter.reportError2(StaticTypeWarningCode.NON_BOOL_CONDITION, condition, []);
      return true;
    }
    return false;
  }

  /**
   * This verifies that the passed assert statement has either a 'bool' or '() -> bool' input.
   *
   * @param node the assert statement to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see StaticTypeWarningCode#NON_BOOL_EXPRESSION
   */
  bool checkForNonBoolExpression(AssertStatement node) {
    Expression expression = node.condition;
    Type2 type = getStaticType(expression);
    if (type is InterfaceType) {
      if (!type.isAssignableTo(_boolType)) {
        _errorReporter.reportError2(StaticTypeWarningCode.NON_BOOL_EXPRESSION, expression, []);
        return true;
      }
    } else if (type is FunctionType) {
      FunctionType functionType = type;
      if (functionType.typeArguments.length == 0 && !functionType.returnType.isAssignableTo(_boolType)) {
        _errorReporter.reportError2(StaticTypeWarningCode.NON_BOOL_EXPRESSION, expression, []);
        return true;
      }
    }
    return false;
  }

  /**
   * Checks to ensure that the given expression is assignable to bool.
   *
   * @param expression the expression expression to test
   * @return `true` if and only if an error code is generated on the passed node
   * @see StaticTypeWarningCode#NON_BOOL_NEGATION_EXPRESSION
   */
  bool checkForNonBoolNegationExpression(Expression expression) {
    Type2 conditionType = getStaticType(expression);
    if (conditionType != null && !conditionType.isAssignableTo(_boolType)) {
      _errorReporter.reportError2(StaticTypeWarningCode.NON_BOOL_NEGATION_EXPRESSION, expression, []);
      return true;
    }
    return false;
  }

  /**
   * This verifies the passed map literal either:
   * * has `const modifier`
   * * has explicit type arguments
   * * is not start of the statement
   *
   * @param node the map literal to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#NON_CONST_MAP_AS_EXPRESSION_STATEMENT
   */
  bool checkForNonConstMapAsExpressionStatement(MapLiteral node) {
    // "const"
    if (node.constKeyword != null) {
      return false;
    }
    // has type arguments
    if (node.typeArguments != null) {
      return false;
    }
    // prepare statement
    Statement statement = node.getAncestor((node) => node is ExpressionStatement);
    if (statement == null) {
      return false;
    }
    // OK, statement does not start with map
    if (statement.beginToken != node.beginToken) {
      return false;
    }
    // report problem
    _errorReporter.reportError2(CompileTimeErrorCode.NON_CONST_MAP_AS_EXPRESSION_STATEMENT, node, []);
    return true;
  }

  /**
   * This verifies the passed method declaration of operator `[]=`, has `void` return
   * type.
   *
   * @param node the method declaration to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see StaticWarningCode#NON_VOID_RETURN_FOR_OPERATOR
   */
  bool checkForNonVoidReturnTypeForOperator(MethodDeclaration node) {
    // check that []= operator
    SimpleIdentifier name = node.name;
    if (name.name != "[]=") {
      return false;
    }
    // check return type
    TypeName typeName = node.returnType;
    if (typeName != null) {
      Type2 type = typeName.type;
      if (type != null && !type.isVoid) {
        _errorReporter.reportError2(StaticWarningCode.NON_VOID_RETURN_FOR_OPERATOR, typeName, []);
      }
    }
    // no warning
    return false;
  }

  /**
   * This verifies the passed setter has no return type or the `void` return type.
   *
   * @param typeName the type name to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see StaticWarningCode#NON_VOID_RETURN_FOR_SETTER
   */
  bool checkForNonVoidReturnTypeForSetter(TypeName typeName) {
    if (typeName != null) {
      Type2 type = typeName.type;
      if (type != null && !type.isVoid) {
        _errorReporter.reportError2(StaticWarningCode.NON_VOID_RETURN_FOR_SETTER, typeName, []);
      }
    }
    return false;
  }

  /**
   * This verifies the passed operator-method declaration, does not have an optional parameter.
   *
   * This method assumes that the method declaration was tested to be an operator declaration before
   * being called.
   *
   * @param node the method declaration to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#OPTIONAL_PARAMETER_IN_OPERATOR
   */
  bool checkForOptionalParameterInOperator(MethodDeclaration node) {
    FormalParameterList parameterList = node.parameters;
    if (parameterList == null) {
      return false;
    }
    bool foundError = false;
    NodeList<FormalParameter> formalParameters = parameterList.parameters;
    for (FormalParameter formalParameter in formalParameters) {
      if (formalParameter.kind.isOptional) {
        _errorReporter.reportError2(CompileTimeErrorCode.OPTIONAL_PARAMETER_IN_OPERATOR, formalParameter, []);
        foundError = true;
      }
    }
    return foundError;
  }

  /**
   * This checks for named optional parameters that begin with '_'.
   *
   * @param node the default formal parameter to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#PRIVATE_OPTIONAL_PARAMETER
   */
  bool checkForPrivateOptionalParameter(FormalParameter node) {
    // should be named parameter
    if (node.kind != ParameterKind.NAMED) {
      return false;
    }
    // name should start with '_'
    SimpleIdentifier name = node.identifier;
    if (name.isSynthetic || !StringUtilities.startsWithChar(name.name, 0x5F)) {
      return false;
    }
    // report problem
    _errorReporter.reportError2(CompileTimeErrorCode.PRIVATE_OPTIONAL_PARAMETER, node, []);
    return true;
  }

  /**
   * This checks if the passed constructor declaration is the redirecting generative constructor and
   * references itself directly or indirectly.
   *
   * @param node the constructor declaration to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#RECURSIVE_CONSTRUCTOR_REDIRECT
   */
  bool checkForRecursiveConstructorRedirect(ConstructorDeclaration node) {
    // we check generative constructor here
    if (node.factoryKeyword != null) {
      return false;
    }
    // try to find redirecting constructor invocation and analyzer it for recursion
    for (ConstructorInitializer initializer in node.initializers) {
      if (initializer is RedirectingConstructorInvocation) {
        // OK if no cycle
        ConstructorElement element = node.element;
        if (!hasRedirectingFactoryConstructorCycle(element)) {
          return false;
        }
        // report error
        _errorReporter.reportError2(CompileTimeErrorCode.RECURSIVE_CONSTRUCTOR_REDIRECT, initializer, []);
        return true;
      }
    }
    // OK, no redirecting constructor invocation
    return false;
  }

  /**
   * This checks if the passed constructor declaration has redirected constructor and references
   * itself directly or indirectly.
   *
   * @param node the constructor declaration to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#RECURSIVE_FACTORY_REDIRECT
   */
  bool checkForRecursiveFactoryRedirect(ConstructorDeclaration node) {
    // prepare redirected constructor
    ConstructorName redirectedConstructorNode = node.redirectedConstructor;
    if (redirectedConstructorNode == null) {
      return false;
    }
    // OK if no cycle
    ConstructorElement element = node.element;
    if (!hasRedirectingFactoryConstructorCycle(element)) {
      return false;
    }
    // report error
    _errorReporter.reportError2(CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT, redirectedConstructorNode, []);
    return true;
  }

  /**
   * This checks the class declaration is not a superinterface to itself.
   *
   * @param classElt the class element to test
   * @return `true` if and only if an error code is generated on the passed element
   * @see CompileTimeErrorCode#RECURSIVE_INTERFACE_INHERITANCE
   * @see CompileTimeErrorCode#RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_EXTENDS
   * @see CompileTimeErrorCode#RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_IMPLEMENTS
   */
  bool checkForRecursiveInterfaceInheritance(ClassElement classElt) {
    if (classElt == null) {
      return false;
    }
    return safeCheckForRecursiveInterfaceInheritance(classElt, new List<ClassElement>());
  }

  /**
   * This checks the passed constructor declaration has a valid combination of redirected
   * constructor invocation(s), super constructor invocations and field initializers.
   *
   * @param node the constructor declaration to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#DEFAULT_VALUE_IN_REDIRECTING_FACTORY_CONSTRUCTOR
   * @see CompileTimeErrorCode#FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR
   * @see CompileTimeErrorCode#MULTIPLE_REDIRECTING_CONSTRUCTOR_INVOCATIONS
   * @see CompileTimeErrorCode#SUPER_IN_REDIRECTING_CONSTRUCTOR
   */
  bool checkForRedirectingConstructorErrorCodes(ConstructorDeclaration node) {
    bool errorReported = false;
    //
    // Check for default values in the parameters
    //
    ConstructorName redirectedConstructor = node.redirectedConstructor;
    if (redirectedConstructor != null) {
      for (FormalParameter parameter in node.parameters.parameters) {
        if (parameter is DefaultFormalParameter && parameter.defaultValue != null) {
          _errorReporter.reportError2(CompileTimeErrorCode.DEFAULT_VALUE_IN_REDIRECTING_FACTORY_CONSTRUCTOR, parameter.identifier, []);
          errorReported = true;
        }
      }
    }
    // check if there are redirected invocations
    int numRedirections = 0;
    for (ConstructorInitializer initializer in node.initializers) {
      if (initializer is RedirectingConstructorInvocation) {
        if (numRedirections > 0) {
          _errorReporter.reportError2(CompileTimeErrorCode.MULTIPLE_REDIRECTING_CONSTRUCTOR_INVOCATIONS, initializer, []);
          errorReported = true;
        }
        numRedirections++;
      }
    }
    // check for other initializers
    if (numRedirections > 0) {
      for (ConstructorInitializer initializer in node.initializers) {
        if (initializer is SuperConstructorInvocation) {
          _errorReporter.reportError2(CompileTimeErrorCode.SUPER_IN_REDIRECTING_CONSTRUCTOR, initializer, []);
          errorReported = true;
        }
        if (initializer is ConstructorFieldInitializer) {
          _errorReporter.reportError2(CompileTimeErrorCode.FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR, initializer, []);
          errorReported = true;
        }
      }
    }
    // done
    return errorReported;
  }

  /**
   * This checks if the passed constructor declaration has redirected constructor and references
   * itself directly or indirectly.
   *
   * @param node the constructor declaration to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#REDIRECT_TO_NON_CONST_CONSTRUCTOR
   */
  bool checkForRedirectToNonConstConstructor(ConstructorDeclaration node) {
    // prepare redirected constructor
    ConstructorName redirectedConstructorNode = node.redirectedConstructor;
    if (redirectedConstructorNode == null) {
      return false;
    }
    // prepare element
    ConstructorElement element = node.element;
    if (element == null) {
      return false;
    }
    // OK, it is not 'const'
    if (!element.isConst) {
      return false;
    }
    // prepare redirected constructor
    ConstructorElement redirectedConstructor = element.redirectedConstructor;
    if (redirectedConstructor == null) {
      return false;
    }
    // OK, it is also 'const'
    if (redirectedConstructor.isConst) {
      return false;
    }
    // report error
    _errorReporter.reportError2(CompileTimeErrorCode.REDIRECT_TO_NON_CONST_CONSTRUCTOR, redirectedConstructorNode, []);
    return true;
  }

  /**
   * This checks that the rethrow is inside of a catch clause.
   *
   * @param node the rethrow expression to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#RETHROW_OUTSIDE_CATCH
   */
  bool checkForRethrowOutsideCatch(RethrowExpression node) {
    if (!_isInCatchClause) {
      _errorReporter.reportError2(CompileTimeErrorCode.RETHROW_OUTSIDE_CATCH, node, []);
      return true;
    }
    return false;
  }

  /**
   * This checks that if the the given constructor declaration is generative, then it does not have
   * an expression function body.
   *
   * @param node the constructor to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#RETURN_IN_GENERATIVE_CONSTRUCTOR
   */
  bool checkForReturnInGenerativeConstructor(ConstructorDeclaration node) {
    // ignore factory
    if (node.factoryKeyword != null) {
      return false;
    }
    // block body (with possible return statement) is checked elsewhere
    FunctionBody body = node.body;
    if (body is! ExpressionFunctionBody) {
      return false;
    }
    // report error
    _errorReporter.reportError2(CompileTimeErrorCode.RETURN_IN_GENERATIVE_CONSTRUCTOR, body, []);
    return true;
  }

  /**
   * This checks that a type mis-match between the return type and the expressed return type by the
   * enclosing method or function.
   *
   * This method is called both by [checkForAllReturnStatementErrorCodes]
   * and [visitExpressionFunctionBody].
   *
   * @param returnExpression the returned expression to evaluate
   * @param expectedReturnType the expressed return type by the enclosing method or function
   * @return `true` if and only if an error code is generated on the passed node
   * @see StaticTypeWarningCode#RETURN_OF_INVALID_TYPE
   */
  bool checkForReturnOfInvalidType(Expression returnExpression, Type2 expectedReturnType) {
    Type2 staticReturnType = getStaticType(returnExpression);
    if (expectedReturnType.isVoid) {
      if (staticReturnType.isVoid || staticReturnType.isDynamic || staticReturnType.isBottom) {
        return false;
      }
      _errorReporter.reportError2(StaticTypeWarningCode.RETURN_OF_INVALID_TYPE, returnExpression, [
          staticReturnType.displayName,
          expectedReturnType.displayName,
          _enclosingFunction.displayName]);
      return true;
    }
    bool isStaticAssignable = staticReturnType.isAssignableTo(expectedReturnType);
    if (isStaticAssignable) {
      return false;
    }
    _errorReporter.reportError2(StaticTypeWarningCode.RETURN_OF_INVALID_TYPE, returnExpression, [
        staticReturnType.displayName,
        expectedReturnType.displayName,
        _enclosingFunction.displayName]);
    return true;
  }

  /**
   * This checks the given "typeReference" and that the "name" is not the reference to an instance
   * member.
   *
   * @param typeReference the resolved [ClassElement] of the left hand side of the expression,
   *          or `null`, aka, the class element of 'C' in 'C.x', see
   *          [getTypeReference]
   * @param name the accessed name to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see StaticWarningCode#STATIC_ACCESS_TO_INSTANCE_MEMBER
   */
  bool checkForStaticAccessToInstanceMember(ClassElement typeReference, SimpleIdentifier name) {
    // OK, target is not a type
    if (typeReference == null) {
      return false;
    }
    // prepare member Element
    Element element = name.staticElement;
    if (element is! ExecutableElement) {
      return false;
    }
    ExecutableElement memberElement = element as ExecutableElement;
    // OK, static
    if (memberElement.isStatic) {
      return false;
    }
    // report problem
    _errorReporter.reportError2(StaticWarningCode.STATIC_ACCESS_TO_INSTANCE_MEMBER, name, [name.name]);
    return true;
  }

  /**
   * This checks that the type of the passed 'switch' expression is assignable to the type of the
   * 'case' members.
   *
   * @param node the 'switch' statement to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see StaticWarningCode#SWITCH_EXPRESSION_NOT_ASSIGNABLE
   */
  bool checkForSwitchExpressionNotAssignable(SwitchStatement node) {
    // prepare 'switch' expression type
    Expression expression = node.expression;
    Type2 expressionType = getStaticType(expression);
    if (expressionType == null) {
      return false;
    }
    // compare with type of the first 'case'
    NodeList<SwitchMember> members = node.members;
    for (SwitchMember switchMember in members) {
      if (switchMember is! SwitchCase) {
        continue;
      }
      SwitchCase switchCase = switchMember as SwitchCase;
      // prepare 'case' type
      Expression caseExpression = switchCase.expression;
      Type2 caseType = getStaticType(caseExpression);
      // check types
      if (expressionType.isAssignableTo(caseType)) {
        return false;
      }
      // report problem
      _errorReporter.reportError2(StaticWarningCode.SWITCH_EXPRESSION_NOT_ASSIGNABLE, expression, [expressionType, caseType]);
      return true;
    }
    return false;
  }

  /**
   * This verifies that the passed function type alias does not reference itself directly.
   *
   * @param node the function type alias to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#TYPE_ALIAS_CANNOT_REFERENCE_ITSELF
   */
  bool checkForTypeAliasCannotReferenceItself_function(FunctionTypeAlias node) {
    FunctionTypeAliasElement element = node.element;
    if (!hasTypedefSelfReference(element)) {
      return false;
    }
    _errorReporter.reportError2(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, node, []);
    return true;
  }

  /**
   * This verifies that the given class type alias does not reference itself.
   *
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#TYPE_ALIAS_CANNOT_REFERENCE_ITSELF
   */
  bool checkForTypeAliasCannotReferenceItself_mixin(ClassTypeAlias node) {
    ClassElement element = node.element;
    if (!hasTypedefSelfReference(element)) {
      return false;
    }
    _errorReporter.reportError2(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, node, []);
    return true;
  }

  /**
   * This verifies that the type arguments in the passed type name are all within their bounds.
   *
   * @param node the [TypeName] to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see StaticTypeWarningCode#TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
   */
  bool checkForTypeArgumentNotMatchingBounds(TypeName node) {
    if (node.typeArguments == null) {
      return false;
    }
    // prepare Type
    Type2 type = node.type;
    if (type == null) {
      return false;
    }
    // prepare ClassElement
    Element element = type.element;
    if (element is! ClassElement) {
      return false;
    }
    ClassElement classElement = element as ClassElement;
    // prepare type parameters
    List<Type2> typeParameters = classElement.type.typeArguments;
    List<TypeParameterElement> boundingElts = classElement.typeParameters;
    // iterate over each bounded type parameter and corresponding argument
    NodeList<TypeName> typeNameArgList = node.typeArguments.arguments;
    List<Type2> typeArguments = (type as InterfaceType).typeArguments;
    int loopThroughIndex = Math.min(typeNameArgList.length, boundingElts.length);
    bool foundError = false;
    for (int i = 0; i < loopThroughIndex; i++) {
      TypeName argTypeName = typeNameArgList[i];
      Type2 argType = argTypeName.type;
      Type2 boundType = boundingElts[i].bound;
      if (argType != null && boundType != null) {
        boundType = boundType.substitute2(typeArguments, typeParameters);
        if (!argType.isSubtypeOf(boundType)) {
          ErrorCode errorCode;
          if (isInConstConstructorInvocation(node)) {
            errorCode = CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS;
          } else {
            errorCode = StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS;
          }
          _errorReporter.reportError2(errorCode, argTypeName, [argType.displayName, boundType.displayName]);
          foundError = true;
        }
      }
    }
    return foundError;
  }

  /**
   * This checks that if the passed type name is a type parameter being used to define a static
   * member.
   *
   * @param node the type name to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see StaticWarningCode#TYPE_PARAMETER_REFERENCED_BY_STATIC
   */
  bool checkForTypeParameterReferencedByStatic(TypeName node) {
    if (_isInStaticMethod || _isInStaticVariableDeclaration) {
      Type2 type = node.type;
      if (type is TypeParameterType) {
        _errorReporter.reportError2(StaticWarningCode.TYPE_PARAMETER_REFERENCED_BY_STATIC, node, []);
        return true;
      }
    }
    return false;
  }

  /**
   * This checks that if the passed type parameter is a supertype of its bound.
   *
   * @param node the type parameter to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see StaticTypeWarningCode#TYPE_PARAMETER_SUPERTYPE_OF_ITS_BOUND
   */
  bool checkForTypeParameterSupertypeOfItsBound(TypeParameter node) {
    TypeParameterElement element = node.element;
    // prepare bound
    Type2 bound = element.bound;
    if (bound == null) {
      return false;
    }
    // OK, type parameter is not supertype of its bound
    if (!bound.isMoreSpecificThan(element.type)) {
      return false;
    }
    // report problem
    _errorReporter.reportError2(StaticTypeWarningCode.TYPE_PARAMETER_SUPERTYPE_OF_ITS_BOUND, node, [element.displayName]);
    return true;
  }

  /**
   * This checks that if the passed generative constructor has neither an explicit super constructor
   * invocation nor a redirecting constructor invocation, that the superclass has a default
   * generative constructor.
   *
   * @param node the constructor declaration to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT
   * @see CompileTimeErrorCode#NON_GENERATIVE_CONSTRUCTOR
   * @see StaticWarningCode#NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT
   */
  bool checkForUndefinedConstructorInInitializerImplicit(ConstructorDeclaration node) {
    //
    // Ignore if the constructor is not generative.
    //
    if (node.factoryKeyword != null) {
      return false;
    }
    //
    // Ignore if the constructor has either an implicit super constructor invocation or a
    // redirecting constructor invocation.
    //
    for (ConstructorInitializer constructorInitializer in node.initializers) {
      if (constructorInitializer is SuperConstructorInvocation || constructorInitializer is RedirectingConstructorInvocation) {
        return false;
      }
    }
    //
    // Check to see whether the superclass has a non-factory unnamed constructor.
    //
    if (_enclosingClass == null) {
      return false;
    }
    InterfaceType superType = _enclosingClass.supertype;
    if (superType == null) {
      return false;
    }
    ClassElement superElement = superType.element;
    ConstructorElement superUnnamedConstructor = superElement.unnamedConstructor;
    if (superUnnamedConstructor != null) {
      if (superUnnamedConstructor.isFactory) {
        _errorReporter.reportError2(CompileTimeErrorCode.NON_GENERATIVE_CONSTRUCTOR, node.returnType, [superUnnamedConstructor]);
        return true;
      }
      if (!superUnnamedConstructor.isDefaultConstructor) {
        int offset;
        int length;
        {
          Identifier returnType = node.returnType;
          SimpleIdentifier name = node.name;
          offset = returnType.offset;
          length = (name != null ? name.end : returnType.end) - offset;
        }
        _errorReporter.reportError4(CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT, offset, length, [superType.displayName]);
      }
      return false;
    }
    _errorReporter.reportError2(CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT, node.returnType, [superElement.name]);
    return true;
  }

  /**
   * This checks that if the given name is a reference to a static member it is defined in the
   * enclosing class rather than in a superclass.
   *
   * @param name the name to be evaluated
   * @return `true` if and only if an error code is generated on the passed node
   * @see StaticTypeWarningCode#UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER
   */
  bool checkForUnqualifiedReferenceToNonLocalStaticMember(SimpleIdentifier name) {
    Element element = name.staticElement;
    if (element == null || element is TypeParameterElement) {
      return false;
    }
    Element enclosingElement = element.enclosingElement;
    if (enclosingElement is! ClassElement) {
      return false;
    }
    if ((element is MethodElement && !element.isStatic) || (element is PropertyAccessorElement && !element.isStatic)) {
      return false;
    }
    if (identical(enclosingElement, _enclosingClass)) {
      return false;
    }
    _errorReporter.reportError2(StaticTypeWarningCode.UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER, name, [name.name]);
    return true;
  }

  void checkForValidField(FieldFormalParameter node) {
    ParameterElement element = node.element;
    if (element is FieldFormalParameterElement) {
      FieldElement fieldElement = element.field;
      if (fieldElement == null || fieldElement.isSynthetic) {
        _errorReporter.reportError2(CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTANT_FIELD, node, [node.identifier.name]);
      } else {
        ParameterElement parameterElement = node.element;
        if (parameterElement is FieldFormalParameterElementImpl) {
          FieldFormalParameterElementImpl fieldFormal = parameterElement;
          Type2 declaredType = fieldFormal.type;
          Type2 fieldType = fieldElement.type;
          if (fieldElement.isSynthetic) {
            _errorReporter.reportError2(CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTANT_FIELD, node, [node.identifier.name]);
          } else if (fieldElement.isStatic) {
            _errorReporter.reportError2(CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_STATIC_FIELD, node, [node.identifier.name]);
          } else if (declaredType != null && fieldType != null && !declaredType.isAssignableTo(fieldType)) {
            _errorReporter.reportError2(StaticWarningCode.FIELD_INITIALIZING_FORMAL_NOT_ASSIGNABLE, node, [declaredType.displayName, fieldType.displayName]);
          }
        } else {
          if (fieldElement.isSynthetic) {
            _errorReporter.reportError2(CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTANT_FIELD, node, [node.identifier.name]);
          } else if (fieldElement.isStatic) {
            _errorReporter.reportError2(CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_STATIC_FIELD, node, [node.identifier.name]);
          }
        }
      }
    }
  }

  /**
   * This verifies the passed operator-method declaration, has correct number of parameters.
   *
   * This method assumes that the method declaration was tested to be an operator declaration before
   * being called.
   *
   * @param node the method declaration to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR
   */
  bool checkForWrongNumberOfParametersForOperator(MethodDeclaration node) {
    // prepare number of parameters
    FormalParameterList parameterList = node.parameters;
    if (parameterList == null) {
      return false;
    }
    int numParameters = parameterList.parameters.length;
    // prepare operator name
    SimpleIdentifier nameNode = node.name;
    if (nameNode == null) {
      return false;
    }
    String name = nameNode.name;
    // check for exact number of parameters
    int expected = -1;
    if ("[]=" == name) {
      expected = 2;
    } else if ("<" == name || ">" == name || "<=" == name || ">=" == name || "==" == name || "+" == name || "/" == name || "~/" == name || "*" == name || "%" == name || "|" == name || "^" == name || "&" == name || "<<" == name || ">>" == name || "[]" == name) {
      expected = 1;
    } else if ("~" == name) {
      expected = 0;
    }
    if (expected != -1 && numParameters != expected) {
      _errorReporter.reportError2(CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR, nameNode, [name, expected, numParameters]);
      return true;
    }
    // check for operator "-"
    if ("-" == name && numParameters > 1) {
      _errorReporter.reportError2(CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR_MINUS, nameNode, [numParameters]);
      return true;
    }
    // OK
    return false;
  }

  /**
   * This verifies if the passed setter parameter list have only one required parameter.
   *
   * This method assumes that the method declaration was tested to be a setter before being called.
   *
   * @param setterName the name of the setter to report problems on
   * @param parameterList the parameter list to evaluate
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER
   */
  bool checkForWrongNumberOfParametersForSetter(SimpleIdentifier setterName, FormalParameterList parameterList) {
    if (setterName == null) {
      return false;
    }
    if (parameterList == null) {
      return false;
    }
    NodeList<FormalParameter> parameters = parameterList.parameters;
    if (parameters.length != 1 || parameters[0].kind != ParameterKind.REQUIRED) {
      _errorReporter.reportError2(CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER, setterName, []);
      return true;
    }
    return false;
  }

  /**
   * This verifies that if the given class declaration implements the class Function that it has a
   * concrete implementation of the call method.
   *
   * @return `true` if and only if an error code is generated on the passed node
   * @see StaticWarningCode#FUNCTION_WITHOUT_CALL
   */
  bool checkImplementsFunctionWithoutCall(ClassDeclaration node) {
    if (node.abstractKeyword != null) {
      return false;
    }
    ClassElement classElement = node.element;
    if (classElement == null) {
      return false;
    }
    if (!classElement.type.isSubtypeOf(_typeProvider.functionType)) {
      return false;
    }
    ExecutableElement callMethod = _inheritanceManager.lookupMember(classElement, "call");
    if (callMethod == null || callMethod is! MethodElement || (callMethod as MethodElement).isAbstract) {
      _errorReporter.reportError2(StaticWarningCode.FUNCTION_WITHOUT_CALL, node.name, []);
      return true;
    }
    return false;
  }

  /**
   * This verifies that the given class declaration does not have the same class in the 'extends'
   * and 'implements' clauses.
   *
   * @return `true` if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#IMPLEMENTS_SUPER_CLASS
   */
  bool checkImplementsSuperClass(ClassDeclaration node) {
    // prepare super type
    InterfaceType superType = _enclosingClass.supertype;
    if (superType == null) {
      return false;
    }
    // prepare interfaces
    ImplementsClause implementsClause = node.implementsClause;
    if (implementsClause == null) {
      return false;
    }
    // check interfaces
    bool hasProblem = false;
    for (TypeName interfaceNode in implementsClause.interfaces) {
      if (interfaceNode.type == superType) {
        hasProblem = true;
        _errorReporter.reportError2(CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS, interfaceNode, [superType.displayName]);
      }
    }
    // done
    return hasProblem;
  }

  /**
   * Return a display name for the given type that includes the path to the compilation unit in
   * which the type is defined.
   *
   * @param type the type for which an extended display name is to be returned
   * @return a display name that can help distiguish between two types with the same name
   */
  String getExtendedDisplayName(Type2 type) {
    Element element = type.element;
    if (element != null) {
      Source source = element.source;
      if (source != null) {
        return "${type.displayName} (${source.fullName})";
      }
    }
    return type.displayName;
  }

  /**
   * Returns the Type (return type) for a given getter.
   *
   * @param propertyAccessorElement
   * @return The type of the given getter.
   */
  Type2 getGetterType(PropertyAccessorElement propertyAccessorElement) {
    FunctionType functionType = propertyAccessorElement.type;
    if (functionType != null) {
      return functionType.returnType;
    } else {
      return null;
    }
  }

  /**
   * Returns the Type (first and only parameter) for a given setter.
   *
   * @param propertyAccessorElement
   * @return The type of the given setter.
   */
  Type2 getSetterType(PropertyAccessorElement propertyAccessorElement) {
    // Get the parameters for MethodDeclaration or FunctionDeclaration
    List<ParameterElement> setterParameters = propertyAccessorElement.parameters;
    // If there are no setter parameters, return no type.
    if (setterParameters.length == 0) {
      return null;
    }
    return setterParameters[0].type;
  }

  /**
   * Return the static type of the given expression that is to be used for type analysis.
   *
   * @param expression the expression whose type is to be returned
   * @return the static type of the given expression
   */
  Type2 getStaticType(Expression expression) {
    Type2 type = expression.staticType;
    if (type == null) {
      // TODO(brianwilkerson) This should never happen.
      return _dynamicType;
    }
    return type;
  }

  /**
   * Return the variable element represented by the given expression, or `null` if there is no
   * such element.
   *
   * @param expression the expression whose element is to be returned
   * @return the variable element represented by the expression
   */
  VariableElement getVariableElement(Expression expression) {
    if (expression is Identifier) {
      Element element = expression.staticElement;
      if (element is VariableElement) {
        return element;
      }
    }
    return null;
  }

  /**
   * @return `true` if the given constructor redirects to itself, directly or indirectly
   */
  bool hasRedirectingFactoryConstructorCycle(ConstructorElement element) {
    Set<ConstructorElement> constructors = new Set<ConstructorElement>();
    ConstructorElement current = element;
    while (current != null) {
      if (constructors.contains(current)) {
        return identical(current, element);
      }
      constructors.add(current);
      current = current.redirectedConstructor;
      if (current is ConstructorMember) {
        current = (current as ConstructorMember).baseElement;
      }
    }
    return false;
  }

  /**
   * @return <code>true</code> if given [Element] has direct or indirect reference to itself
   *         from anywhere except [ClassElement] or type parameter bounds.
   */
  bool hasTypedefSelfReference(Element target) {
    Set<Element> checked = new Set<Element>();
    List<Element> toCheck = new List<Element>();
    toCheck.add(target);
    bool firstIteration = true;
    while (true) {
      Element current;
      // get next element
      while (true) {
        // may be no more elements to check
        if (toCheck.isEmpty) {
          return false;
        }
        // try to get next element
        current = toCheck.removeAt(toCheck.length - 1);
        if (target == current) {
          if (firstIteration) {
            firstIteration = false;
            break;
          } else {
            return true;
          }
        }
        if (current != null && !checked.contains(current)) {
          break;
        }
      }
      // check current element
      current.accept(new GeneralizingElementVisitor_ErrorVerifier_hasTypedefSelfReference(target, toCheck));
      checked.add(current);
    }
  }

  /**
   * @return `true` if given [Type] implements operator <i>==</i>, and it is not
   *         <i>int</i> or <i>String</i>.
   */
  bool implementsEqualsWhenNotAllowed(Type2 type) {
    // ignore int or String
    if (type == null || type == _typeProvider.intType || type == _typeProvider.stringType) {
      return false;
    }
    // prepare ClassElement
    Element element = type.element;
    if (element is! ClassElement) {
      return false;
    }
    ClassElement classElement = element as ClassElement;
    // lookup for ==
    MethodElement method = classElement.lookUpMethod("==", _currentLibrary);
    if (method == null || method.enclosingElement.type.isObject) {
      return false;
    }
    // there is == that we don't like
    return true;
  }

  bool isFunctionType(Type2 type) {
    if (type.isDynamic || type.isBottom) {
      return true;
    } else if (type is FunctionType || type.isDartCoreFunction) {
      return true;
    } else if (type is InterfaceType) {
      MethodElement callMethod = type.lookUpMethod(ElementResolver.CALL_METHOD_NAME, _currentLibrary);
      return callMethod != null;
    }
    return false;
  }

  /**
   * @return `true` if the given [AstNode] is the part of constant constructor
   *         invocation.
   */
  bool isInConstConstructorInvocation(AstNode node) {
    InstanceCreationExpression creation = node.getAncestor((node) => node is InstanceCreationExpression);
    if (creation == null) {
      return false;
    }
    return creation.isConst;
  }

  /**
   * Return `true` iff the passed [ClassElement] has a method, getter or setter that
   * matches the name of the passed [ExecutableElement] in either the class itself, or one of
   * its' mixins.
   *
   * By "match", only the name of the member is tested to match, it does not have to equal or be a
   * subtype of the passed executable element, this is due to the specific use where this method is
   * used in [checkForNonAbstractClassInheritsAbstractMember].
   *
   * @param executableElt the executable to search for in the passed class element
   * @param classElt the class method to search through the members of
   * @return `true` iff the passed member is found in the passed class element
   */
  bool isMemberInClassOrMixin(ExecutableElement executableElt, ClassElement classElt) {
    ExecutableElement foundElt;
    String executableName = executableElt.name;
    if (executableElt is MethodElement) {
      foundElt = classElt.getMethod(executableName);
      if (foundElt != null) {
        return true;
      }
      List<InterfaceType> mixins = classElt.mixins;
      for (int i = 0; i < mixins.length && foundElt == null; i++) {
        foundElt = mixins[i].getMethod(executableName);
      }
      if (foundElt != null) {
        return true;
      }
    } else if (executableElt is PropertyAccessorElement) {
      foundElt = classElt.getGetter(executableElt.name);
      if (foundElt == null) {
        foundElt = classElt.getSetter(executableName);
      }
      if (foundElt != null) {
        return true;
      }
      List<InterfaceType> mixins = classElt.mixins;
      for (int i = 0; i < mixins.length && foundElt == null; i++) {
        foundElt = mixins[i].getGetter(executableName);
        if (foundElt == null) {
          foundElt = mixins[i].getSetter(executableName);
        }
      }
      if (foundElt != null) {
        return true;
      }
    }
    return false;
  }

  /**
   * @param node the 'this' expression to analyze
   * @return `true` if the given 'this' expression is in the valid context
   */
  bool isThisInValidContext(ThisExpression node) {
    for (AstNode n = node; n != null; n = n.parent) {
      if (n is CompilationUnit) {
        return false;
      }
      if (n is ConstructorDeclaration) {
        ConstructorDeclaration constructor = n as ConstructorDeclaration;
        return constructor.factoryKeyword == null;
      }
      if (n is ConstructorInitializer) {
        return false;
      }
      if (n is MethodDeclaration) {
        MethodDeclaration method = n as MethodDeclaration;
        return !method.isStatic;
      }
    }
    return false;
  }

  /**
   * Return `true` if the given identifier is in a location where it is allowed to resolve to
   * a static member of a supertype.
   *
   * @param node the node being tested
   * @return `true` if the given identifier is in a location where it is allowed to resolve to
   *         a static member of a supertype
   */
  bool isUnqualifiedReferenceToNonLocalStaticMemberAllowed(SimpleIdentifier node) {
    if (node.inDeclarationContext()) {
      return true;
    }
    AstNode parent = node.parent;
    if (parent is ConstructorName || parent is MethodInvocation || parent is PropertyAccess || parent is SuperConstructorInvocation) {
      return true;
    }
    if (parent is PrefixedIdentifier && identical(parent.identifier, node)) {
      return true;
    }
    if (parent is Annotation && identical(parent.constructorName, node)) {
      return true;
    }
    if (parent is CommentReference) {
      CommentReference commentReference = parent;
      if (commentReference.newKeyword != null) {
        return true;
      }
    }
    return false;
  }

  bool isUserDefinedObject(EvaluationResultImpl result) => result == null || (result is ValidResult && result.isUserDefinedObject);

  /**
   * This checks the class declaration is not a superinterface to itself.
   *
   * @param classElt the class element to test
   * @param path a list containing the potentially cyclic implements path
   * @return `true` if and only if an error code is generated on the passed element
   * @see CompileTimeErrorCode#RECURSIVE_INTERFACE_INHERITANCE
   * @see CompileTimeErrorCode#RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_EXTENDS
   * @see CompileTimeErrorCode#RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_IMPLEMENTS
   */
  bool safeCheckForRecursiveInterfaceInheritance(ClassElement classElt, List<ClassElement> path) {
    // Detect error condition.
    int size = path.length;
    // If this is not the base case (size > 0), and the enclosing class is the passed class
    // element then an error an error.
    if (size > 0 && _enclosingClass == classElt) {
      String enclosingClassName = _enclosingClass.displayName;
      if (size > 1) {
        // Construct a string showing the cyclic implements path: "A, B, C, D, A"
        String separator = ", ";
        JavaStringBuilder builder = new JavaStringBuilder();
        for (int i = 0; i < size; i++) {
          builder.append(path[i].displayName);
          builder.append(separator);
        }
        builder.append(classElt.displayName);
        _errorReporter.reportError4(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, _enclosingClass.nameOffset, enclosingClassName.length, [enclosingClassName, builder.toString()]);
        return true;
      } else {
        // RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_IMPLEMENTS or RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_EXTENDS
        InterfaceType supertype = classElt.supertype;
        ErrorCode errorCode = (supertype != null && _enclosingClass == supertype.element ? CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_EXTENDS : CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_IMPLEMENTS);
        _errorReporter.reportError4(errorCode, _enclosingClass.nameOffset, enclosingClassName.length, [enclosingClassName]);
        return true;
      }
    }
    if (path.indexOf(classElt) > 0) {
      return false;
    }
    path.add(classElt);
    // n-case
    InterfaceType supertype = classElt.supertype;
    if (supertype != null && safeCheckForRecursiveInterfaceInheritance(supertype.element, path)) {
      return true;
    }
    List<InterfaceType> interfaceTypes = classElt.interfaces;
    for (InterfaceType interfaceType in interfaceTypes) {
      if (safeCheckForRecursiveInterfaceInheritance(interfaceType.element, path)) {
        return true;
      }
    }
    path.removeAt(path.length - 1);
    return false;
  }
}

/**
 * This enum holds one of four states of a field initialization state through a constructor
 * signature, not initialized, initialized in the field declaration, initialized in the field
 * formal, and finally, initialized in the initializers list.
 */
class INIT_STATE extends Enum<INIT_STATE> {
  static final INIT_STATE NOT_INIT = new INIT_STATE('NOT_INIT', 0);

  static final INIT_STATE INIT_IN_DECLARATION = new INIT_STATE('INIT_IN_DECLARATION', 1);

  static final INIT_STATE INIT_IN_FIELD_FORMAL = new INIT_STATE('INIT_IN_FIELD_FORMAL', 2);

  static final INIT_STATE INIT_IN_INITIALIZERS = new INIT_STATE('INIT_IN_INITIALIZERS', 3);

  static final List<INIT_STATE> values = [
      NOT_INIT,
      INIT_IN_DECLARATION,
      INIT_IN_FIELD_FORMAL,
      INIT_IN_INITIALIZERS];

  INIT_STATE(String name, int ordinal) : super(name, ordinal);
}

class GeneralizingElementVisitor_ErrorVerifier_hasTypedefSelfReference extends GeneralizingElementVisitor<Object> {
  Element target;

  List<Element> toCheck;

  GeneralizingElementVisitor_ErrorVerifier_hasTypedefSelfReference(this.target, this.toCheck) : super();

  bool _inClass = false;

  Object visitClassElement(ClassElement element) {
    addTypeToCheck(element.supertype);
    for (InterfaceType mixin in element.mixins) {
      addTypeToCheck(mixin);
    }
    _inClass = !element.isTypedef;
    try {
      return super.visitClassElement(element);
    } finally {
      _inClass = false;
    }
  }

  Object visitExecutableElement(ExecutableElement element) {
    if (element.isSynthetic) {
      return null;
    }
    addTypeToCheck(element.returnType);
    return super.visitExecutableElement(element);
  }

  Object visitFunctionTypeAliasElement(FunctionTypeAliasElement element) {
    addTypeToCheck(element.returnType);
    return super.visitFunctionTypeAliasElement(element);
  }

  Object visitParameterElement(ParameterElement element) {
    addTypeToCheck(element.type);
    return super.visitParameterElement(element);
  }

  Object visitTypeParameterElement(TypeParameterElement element) {
    addTypeToCheck(element.bound);
    return super.visitTypeParameterElement(element);
  }

  Object visitVariableElement(VariableElement element) {
    addTypeToCheck(element.type);
    return super.visitVariableElement(element);
  }

  void addTypeToCheck(Type2 type) {
    if (type == null) {
      return;
    }
    Element element = type.element;
    // it is OK to reference target from class
    if (_inClass && target == element) {
      return;
    }
    // schedule for checking
    toCheck.add(element);
    // type arguments
    if (type is InterfaceType) {
      InterfaceType interfaceType = type;
      for (Type2 typeArgument in interfaceType.typeArguments) {
        addTypeToCheck(typeArgument);
      }
    }
  }
}

/**
 * The enumeration `ResolverErrorCode` defines the error codes used for errors detected by the
 * resolver. The convention for this class is for the name of the error code to indicate the problem
 * that caused the error to be generated and for the error message to explain what is wrong and,
 * when appropriate, how the problem can be corrected.
 */
class ResolverErrorCode extends Enum<ResolverErrorCode> implements ErrorCode {
  static final ResolverErrorCode BREAK_LABEL_ON_SWITCH_MEMBER = new ResolverErrorCode.con1('BREAK_LABEL_ON_SWITCH_MEMBER', 0, ErrorType.COMPILE_TIME_ERROR, "Break label resolves to case or default statement");

  static final ResolverErrorCode CONTINUE_LABEL_ON_SWITCH = new ResolverErrorCode.con1('CONTINUE_LABEL_ON_SWITCH', 1, ErrorType.COMPILE_TIME_ERROR, "A continue label resolves to switch, must be loop or switch member");

  static final ResolverErrorCode MISSING_LIBRARY_DIRECTIVE_WITH_PART = new ResolverErrorCode.con1('MISSING_LIBRARY_DIRECTIVE_WITH_PART', 2, ErrorType.COMPILE_TIME_ERROR, "Libraries that have parts must have a library directive");

  static final List<ResolverErrorCode> values = [
      BREAK_LABEL_ON_SWITCH_MEMBER,
      CONTINUE_LABEL_ON_SWITCH,
      MISSING_LIBRARY_DIRECTIVE_WITH_PART];

  /**
   * The type of this error.
   */
  final ErrorType type;

  /**
   * The template used to create the message to be displayed for this error.
   */
  final String message;

  /**
   * The template used to create the correction to be displayed for this error, or `null` if
   * there is no correction information for this error.
   */
  String correction9;

  /**
   * Initialize a newly created error code to have the given type and message.
   *
   * @param type the type of this error
   * @param message the message template used to create the message to be displayed for the error
   */
  ResolverErrorCode.con1(String name, int ordinal, this.type, this.message) : super(name, ordinal);

  /**
   * Initialize a newly created error code to have the given type, message and correction.
   *
   * @param type the type of this error
   * @param message the template used to create the message to be displayed for the error
   * @param correction the template used to create the correction to be displayed for the error
   */
  ResolverErrorCode.con2(String name, int ordinal, this.type, this.message, String correction) : super(name, ordinal) {
    this.correction9 = correction;
  }

  String get correction => correction9;

  ErrorSeverity get errorSeverity => type.severity;
}