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
import 'ast.dart';
import 'parser.dart' show Parser, ParserErrorCode;
import 'sdk.dart' show DartSdk, SdkLibrary;
import 'element.dart';
import 'html.dart' as ht;
import 'engine.dart';
import 'constant.dart';
/**
 * Instances of the class {@code CompilationUnitBuilder} build an element model for a single
 * compilation unit.
 * @coverage dart.engine.resolver
 */
class CompilationUnitBuilder {

  /**
   * Build the compilation unit element for the given source.
   * @param source the source describing the compilation unit
   * @param unit the AST structure representing the compilation unit
   * @return the compilation unit element that was built
   * @throws AnalysisException if the analysis could not be performed
   */
  CompilationUnitElementImpl buildCompilationUnit(Source source2, CompilationUnit unit) {
    if (unit == null) {
      return null;
    }
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    unit.accept(builder);
    CompilationUnitElementImpl element = new CompilationUnitElementImpl(source2.shortName);
    element.accessors = holder.accessors;
    element.functions = holder.functions;
    element.source = source2;
    element.typeAliases = holder.typeAliases;
    element.types = holder.types;
    element.topLevelVariables = holder.topLevelVariables;
    unit.element = element;
    return element;
  }
}
/**
 * Instances of the class {@code ElementBuilder} traverse an AST structure and build the element
 * model representing the AST structure.
 * @coverage dart.engine.resolver
 */
class ElementBuilder extends RecursiveASTVisitor<Object> {

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
   * Initialize a newly created element builder to build the elements for a compilation unit.
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
      exceptionParameter.element = exception;
      SimpleIdentifier stackTraceParameter = node.stackTraceParameter;
      if (stackTraceParameter != null) {
        LocalVariableElementImpl stackTrace = new LocalVariableElementImpl(stackTraceParameter);
        _currentHolder.addLocalVariable(stackTrace);
        stackTraceParameter.element = stackTrace;
      }
    }
    return super.visitCatchClause(node);
  }
  Object visitClassDeclaration(ClassDeclaration node) {
    ElementHolder holder = new ElementHolder();
    _isValidMixin = true;
    visitChildren(holder, node);
    SimpleIdentifier className = node.name;
    ClassElementImpl element = new ClassElementImpl(className);
    List<TypeVariableElement> typeVariables = holder.typeVariables;
    InterfaceTypeImpl interfaceType = new InterfaceTypeImpl.con1(element);
    interfaceType.typeArguments = createTypeVariableTypes(typeVariables);
    element.type = interfaceType;
    List<ConstructorElement> constructors = holder.constructors;
    if (constructors.length == 0) {
      constructors = createDefaultConstructors(interfaceType);
    }
    element.abstract = node.abstractKeyword != null;
    element.accessors = holder.accessors;
    element.constructors = constructors;
    element.fields = holder.fields;
    element.methods = holder.methods;
    element.typeVariables = typeVariables;
    element.validMixin = _isValidMixin;
    _currentHolder.addType(element);
    className.element = element;
    return null;
  }
  Object visitClassTypeAlias(ClassTypeAlias node) {
    ElementHolder holder = new ElementHolder();
    visitChildren(holder, node);
    SimpleIdentifier className = node.name;
    ClassElementImpl element = new ClassElementImpl(className);
    element.abstract = node.abstractKeyword != null;
    element.typedef = true;
    List<TypeVariableElement> typeVariables = holder.typeVariables;
    element.typeVariables = typeVariables;
    InterfaceTypeImpl interfaceType = new InterfaceTypeImpl.con1(element);
    interfaceType.typeArguments = createTypeVariableTypes(typeVariables);
    element.type = interfaceType;
    element.constructors = createDefaultConstructors(interfaceType);
    _currentHolder.addType(element);
    className.element = element;
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
    ConstructorElementImpl element = new ConstructorElementImpl(constructorName);
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
      constructorName.element = element;
    }
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
    variableName.element = element;
    return super.visitDeclaredIdentifier(node);
  }
  Object visitDefaultFormalParameter(DefaultFormalParameter node) {
    ElementHolder holder = new ElementHolder();
    visit(holder, node.defaultValue);
    FunctionElementImpl initializer = new FunctionElementImpl();
    initializer.functions = holder.functions;
    initializer.labels = holder.labels;
    initializer.localVariables = holder.localVariables;
    initializer.parameters = holder.parameters;
    SimpleIdentifier parameterName = node.parameter.identifier;
    ParameterElementImpl parameter;
    if (node.isConst()) {
      parameter = new ConstParameterElementImpl(parameterName);
      parameter.const3 = true;
    } else if (node.parameter is FieldFormalParameter) {
      parameter = new FieldFormalParameterElementImpl(parameterName);
    } else {
      parameter = new ParameterElementImpl(parameterName);
    }
    parameter.final2 = node.isFinal();
    parameter.initializer = initializer;
    parameter.parameterKind = node.kind;
    Expression defaultValue = node.defaultValue;
    if (defaultValue != null) {
      parameter.setDefaultValueRange(defaultValue.offset, defaultValue.length);
    }
    FunctionBody body = getFunctionBody(node);
    if (body != null) {
      parameter.setVisibleRange(body.offset, body.length);
    }
    _currentHolder.addParameter(parameter);
    parameterName.element = parameter;
    node.parameter.accept(this);
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
      FieldFormalParameterElementImpl parameter = new FieldFormalParameterElementImpl(parameterName);
      parameter.const3 = node.isConst();
      parameter.final2 = node.isFinal();
      parameter.parameterKind = node.kind;
      _currentHolder.addParameter(parameter);
      parameterName.element = parameter;
    }
    return super.visitFieldFormalParameter(node);
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
        FunctionTypeImpl type = new FunctionTypeImpl.con1(element);
        element.type = type;
        _currentHolder.addFunction(element);
        expression.element = element;
        functionName.element = element;
      } else {
        SimpleIdentifier propertyNameNode = node.name;
        if (propertyNameNode == null) {
          return null;
        }
        String propertyName = propertyNameNode.name;
        FieldElementImpl field = _currentHolder.getField(propertyName) as FieldElementImpl;
        if (field == null) {
          field = new FieldElementImpl.con2(node.name.name);
          field.final2 = true;
          field.static = true;
          _currentHolder.addField(field);
        }
        if (matches(property, sc.Keyword.GET)) {
          PropertyAccessorElementImpl getter = new PropertyAccessorElementImpl.con1(propertyNameNode);
          getter.functions = holder.functions;
          getter.labels = holder.labels;
          getter.localVariables = holder.localVariables;
          getter.variable = field;
          getter.getter = true;
          getter.static = true;
          field.getter = getter;
          _currentHolder.addAccessor(getter);
          propertyNameNode.element = getter;
        } else {
          PropertyAccessorElementImpl setter = new PropertyAccessorElementImpl.con1(propertyNameNode);
          setter.functions = holder.functions;
          setter.labels = holder.labels;
          setter.localVariables = holder.localVariables;
          setter.parameters = holder.parameters;
          setter.variable = field;
          setter.setter = true;
          setter.static = true;
          field.setter = setter;
          field.final2 = false;
          _currentHolder.addAccessor(setter);
          propertyNameNode.element = setter;
        }
      }
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
      Block enclosingBlock = node.getAncestor(Block);
      if (enclosingBlock != null) {
        int functionEnd = node.offset + node.length;
        int blockEnd = enclosingBlock.offset + enclosingBlock.length;
        element.setVisibleRange(functionEnd, blockEnd - functionEnd - 1);
      }
    }
    FunctionTypeImpl type = new FunctionTypeImpl.con1(element);
    element.type = type;
    _currentHolder.addFunction(element);
    node.element = element;
    return null;
  }
  Object visitFunctionTypeAlias(FunctionTypeAlias node) {
    ElementHolder holder = new ElementHolder();
    visitChildren(holder, node);
    SimpleIdentifier aliasName = node.name;
    List<ParameterElement> parameters = holder.parameters;
    List<TypeVariableElement> typeVariables = holder.typeVariables;
    FunctionTypeAliasElementImpl element = new FunctionTypeAliasElementImpl(aliasName);
    element.parameters = parameters;
    element.typeVariables = typeVariables;
    FunctionTypeImpl type = new FunctionTypeImpl.con2(element);
    type.typeArguments = createTypeVariableTypes(typeVariables);
    element.type = type;
    _currentHolder.addTypeAlias(element);
    aliasName.element = element;
    return null;
  }
  Object visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    if (node.parent is! DefaultFormalParameter) {
      SimpleIdentifier parameterName = node.identifier;
      ParameterElementImpl parameter = new ParameterElementImpl(parameterName);
      parameter.parameterKind = node.kind;
      _currentHolder.addParameter(parameter);
      parameterName.element = parameter;
    }
    ElementHolder holder = new ElementHolder();
    visitChildren(holder, node);
    ((node.element as ParameterElementImpl)).parameters = holder.parameters;
    return null;
  }
  Object visitLabeledStatement(LabeledStatement node) {
    bool onSwitchStatement = node.statement is SwitchStatement;
    for (Label label in node.labels) {
      SimpleIdentifier labelName = label.label;
      LabelElementImpl element = new LabelElementImpl(labelName, onSwitchStatement, false);
      _currentHolder.addLabel(element);
      labelName.element = element;
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
    bool isStatic = node.isStatic();
    sc.Token property = node.propertyKeyword;
    if (property == null) {
      SimpleIdentifier methodName = node.name;
      String nameOfMethod = methodName.name;
      if (nameOfMethod == sc.TokenType.MINUS.lexeme && node.parameters.parameters.length == 0) {
        nameOfMethod = "unary-";
      }
      MethodElementImpl element = new MethodElementImpl.con2(nameOfMethod, methodName.offset);
      element.abstract = node.isAbstract();
      element.functions = holder.functions;
      element.labels = holder.labels;
      element.localVariables = holder.localVariables;
      element.parameters = holder.parameters;
      element.static = isStatic;
      _currentHolder.addMethod(element);
      methodName.element = element;
    } else {
      SimpleIdentifier propertyNameNode = node.name;
      String propertyName = propertyNameNode.name;
      FieldElementImpl field = _currentHolder.getField(propertyName) as FieldElementImpl;
      if (field == null) {
        field = new FieldElementImpl.con2(node.name.name);
        field.final2 = true;
        field.static = isStatic;
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
        propertyNameNode.element = getter;
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
        propertyNameNode.element = setter;
      }
    }
    return null;
  }
  Object visitSimpleFormalParameter(SimpleFormalParameter node) {
    if (node.parent is! DefaultFormalParameter) {
      SimpleIdentifier parameterName = node.identifier;
      ParameterElementImpl parameter = new ParameterElementImpl(parameterName);
      parameter.const3 = node.isConst();
      parameter.final2 = node.isFinal();
      parameter.parameterKind = node.kind;
      _currentHolder.addParameter(parameter);
      parameterName.element = parameter;
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
      labelName.element = element;
    }
    return super.visitSwitchCase(node);
  }
  Object visitSwitchDefault(SwitchDefault node) {
    for (Label label in node.labels) {
      SimpleIdentifier labelName = label.label;
      LabelElementImpl element = new LabelElementImpl(labelName, false, true);
      _currentHolder.addLabel(element);
      labelName.element = element;
    }
    return super.visitSwitchDefault(node);
  }
  Object visitTypeParameter(TypeParameter node) {
    SimpleIdentifier parameterName = node.name;
    TypeVariableElementImpl element = new TypeVariableElementImpl(parameterName);
    TypeVariableTypeImpl type = new TypeVariableTypeImpl(element);
    element.type = type;
    _currentHolder.addTypeVariable(element);
    parameterName.element = element;
    return super.visitTypeParameter(node);
  }
  Object visitVariableDeclaration(VariableDeclaration node) {
    sc.Token keyword = ((node.parent as VariableDeclarationList)).keyword;
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
      fieldName.element = field;
    } else if (_inFunction) {
      SimpleIdentifier variableName = node.name;
      LocalVariableElementImpl variable;
      if (isConst && hasInitializer) {
        variable = new ConstLocalVariableElementImpl(variableName);
      } else {
        variable = new LocalVariableElementImpl(variableName);
      }
      element = variable;
      Block enclosingBlock = node.getAncestor(Block);
      int functionEnd = node.offset + node.length;
      int blockEnd = enclosingBlock.offset + enclosingBlock.length;
      variable.setVisibleRange(functionEnd, blockEnd - functionEnd - 1);
      _currentHolder.addLocalVariable(variable);
      variableName.element = element;
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
      variableName.element = element;
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
      FunctionElementImpl initializer = new FunctionElementImpl();
      initializer.functions = holder.functions;
      initializer.labels = holder.labels;
      initializer.localVariables = holder.localVariables;
      initializer.synthetic = true;
      element.initializer = initializer;
    }
    if (element is PropertyInducingElementImpl) {
      PropertyInducingElementImpl variable = element as PropertyInducingElementImpl;
      if (_inFieldContext) {
        ((variable as FieldElementImpl)).static = matches(((node.parent.parent as FieldDeclaration)).keyword, sc.Keyword.STATIC);
      }
      PropertyAccessorElementImpl getter = new PropertyAccessorElementImpl.con2(variable);
      getter.getter = true;
      getter.static = variable.isStatic();
      _currentHolder.addAccessor(getter);
      variable.getter = getter;
      if (!isFinal) {
        PropertyAccessorElementImpl setter = new PropertyAccessorElementImpl.con2(variable);
        setter.setter = true;
        setter.static = variable.isStatic();
        _currentHolder.addAccessor(setter);
        variable.setter = setter;
      }
    }
    return null;
  }

  /**
   * Creates the {@link ConstructorElement}s array with the single default constructor element.
   * @param interfaceType the interface type for which to create a default constructor
   * @return the {@link ConstructorElement}s array with the single default constructor element
   */
  List<ConstructorElement> createDefaultConstructors(InterfaceTypeImpl interfaceType) {
    ConstructorElementImpl constructor = new ConstructorElementImpl(null);
    constructor.synthetic = true;
    FunctionTypeImpl type = new FunctionTypeImpl.con1(constructor);
    type.returnType = interfaceType;
    constructor.type = type;
    return <ConstructorElement> [constructor];
  }
  List<Type2> createTypeVariableTypes(List<TypeVariableElement> typeVariables) {
    int typeVariableCount = typeVariables.length;
    List<Type2> typeArguments = new List<Type2>(typeVariableCount);
    for (int i = 0; i < typeVariableCount; i++) {
      TypeVariableElementImpl typeVariable = typeVariables[i] as TypeVariableElementImpl;
      TypeVariableTypeImpl typeArgument = new TypeVariableTypeImpl(typeVariable);
      typeVariable.type = typeArgument;
      typeArguments[i] = typeArgument;
    }
    return typeArguments;
  }

  /**
   * Return the body of the function that contains the given parameter, or {@code null} if no
   * function body could be found.
   * @param node the parameter contained in the function whose body is to be returned
   * @return the body of the function that contains the given parameter
   */
  FunctionBody getFunctionBody(FormalParameter node) {
    ASTNode parent = node.parent;
    while (parent != null) {
      if (parent is FunctionExpression) {
        return ((parent as FunctionExpression)).body;
      } else if (parent is MethodDeclaration) {
        return ((parent as MethodDeclaration)).body;
      }
      parent = parent.parent;
    }
    return null;
  }

  /**
   * Return {@code true} if the given token is a token for the given keyword.
   * @param token the token being tested
   * @param keyword the keyword being tested for
   * @return {@code true} if the given token is a token for the given keyword
   */
  bool matches(sc.Token token, sc.Keyword keyword2) => token != null && identical(token.type, sc.TokenType.KEYWORD) && identical(((token as sc.KeywordToken)).keyword, keyword2);

  /**
   * Make the given holder be the current holder while visiting the given node.
   * @param holder the holder that will gather elements that are built while visiting the children
   * @param node the node to be visited
   */
  void visit(ElementHolder holder, ASTNode node) {
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
   * @param holder the holder that will gather elements that are built while visiting the children
   * @param node the node whose children are to be visited
   */
  void visitChildren(ElementHolder holder, ASTNode node) {
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
/**
 * Instances of the class {@code ElementHolder} hold on to elements created while traversing an AST
 * structure so that they can be accessed when creating their enclosing element.
 * @coverage dart.engine.resolver
 */
class ElementHolder {
  List<PropertyAccessorElement> _accessors = new List<PropertyAccessorElement>();
  List<ConstructorElement> _constructors = new List<ConstructorElement>();
  List<FieldElement> _fields = new List<FieldElement>();
  List<FunctionElement> _functions = new List<FunctionElement>();
  List<LabelElement> _labels = new List<LabelElement>();
  List<VariableElement> _localVariables = new List<VariableElement>();
  List<MethodElement> _methods = new List<MethodElement>();
  List<FunctionTypeAliasElement> _typeAliases = new List<FunctionTypeAliasElement>();
  List<ParameterElement> _parameters = new List<ParameterElement>();
  List<VariableElement> _topLevelVariables = new List<VariableElement>();
  List<ClassElement> _types = new List<ClassElement>();
  List<TypeVariableElement> _typeVariables = new List<TypeVariableElement>();
  void addAccessor(PropertyAccessorElement element) {
    _accessors.add(element);
  }
  void addConstructor(ConstructorElement element) {
    _constructors.add(element);
  }
  void addField(FieldElement element) {
    _fields.add(element);
  }
  void addFunction(FunctionElement element) {
    _functions.add(element);
  }
  void addLabel(LabelElement element) {
    _labels.add(element);
  }
  void addLocalVariable(LocalVariableElement element) {
    _localVariables.add(element);
  }
  void addMethod(MethodElement element) {
    _methods.add(element);
  }
  void addParameter(ParameterElement element) {
    _parameters.add(element);
  }
  void addTopLevelVariable(TopLevelVariableElement element) {
    _topLevelVariables.add(element);
  }
  void addType(ClassElement element) {
    _types.add(element);
  }
  void addTypeAlias(FunctionTypeAliasElement element) {
    _typeAliases.add(element);
  }
  void addTypeVariable(TypeVariableElement element) {
    _typeVariables.add(element);
  }
  List<PropertyAccessorElement> get accessors {
    if (_accessors.isEmpty) {
      return PropertyAccessorElementImpl.EMPTY_ARRAY;
    }
    return new List.from(_accessors);
  }
  List<ConstructorElement> get constructors {
    if (_constructors.isEmpty) {
      return ConstructorElementImpl.EMPTY_ARRAY;
    }
    return new List.from(_constructors);
  }
  FieldElement getField(String fieldName) {
    for (FieldElement field in _fields) {
      if (field.name == fieldName) {
        return field;
      }
    }
    return null;
  }
  List<FieldElement> get fields {
    if (_fields.isEmpty) {
      return FieldElementImpl.EMPTY_ARRAY;
    }
    return new List.from(_fields);
  }
  List<FunctionElement> get functions {
    if (_functions.isEmpty) {
      return FunctionElementImpl.EMPTY_ARRAY;
    }
    return new List.from(_functions);
  }
  List<LabelElement> get labels {
    if (_labels.isEmpty) {
      return LabelElementImpl.EMPTY_ARRAY;
    }
    return new List.from(_labels);
  }
  List<LocalVariableElement> get localVariables {
    if (_localVariables.isEmpty) {
      return LocalVariableElementImpl.EMPTY_ARRAY;
    }
    return new List.from(_localVariables);
  }
  List<MethodElement> get methods {
    if (_methods.isEmpty) {
      return MethodElementImpl.EMPTY_ARRAY;
    }
    return new List.from(_methods);
  }
  List<ParameterElement> get parameters {
    if (_parameters.isEmpty) {
      return ParameterElementImpl.EMPTY_ARRAY;
    }
    return new List.from(_parameters);
  }
  List<TopLevelVariableElement> get topLevelVariables {
    if (_topLevelVariables.isEmpty) {
      return TopLevelVariableElementImpl.EMPTY_ARRAY;
    }
    return new List.from(_topLevelVariables);
  }
  List<FunctionTypeAliasElement> get typeAliases {
    if (_typeAliases.isEmpty) {
      return FunctionTypeAliasElementImpl.EMPTY_ARRAY;
    }
    return new List.from(_typeAliases);
  }
  List<ClassElement> get types {
    if (_types.isEmpty) {
      return ClassElementImpl.EMPTY_ARRAY;
    }
    return new List.from(_types);
  }
  List<TypeVariableElement> get typeVariables {
    if (_typeVariables.isEmpty) {
      return TypeVariableElementImpl.EMPTY_ARRAY;
    }
    return new List.from(_typeVariables);
  }
}
/**
 * Instances of the class {@code HtmlUnitBuilder} build an element model for a single HTML unit.
 */
class HtmlUnitBuilder implements ht.XmlVisitor<Object> {
  static String _APPLICATION_DART_IN_DOUBLE_QUOTES = "\"application/dart\"";
  static String _APPLICATION_DART_IN_SINGLE_QUOTES = "'application/dart'";
  static String _SCRIPT = "script";
  static String _SRC = "src";
  static String _TYPE = "type";

  /**
   * The analysis context in which the element model will be built.
   */
  InternalAnalysisContext _context;

  /**
   * The error listener to which errors will be reported.
   */
  RecordingErrorListener _errorListener;

  /**
   * The line information associated with the source for which an element is being built, or{@code null} if we are not building an element.
   */
  LineInfo _lineInfo;

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
   * @param context the analysis context in which the element model will be built
   */
  HtmlUnitBuilder(InternalAnalysisContext context) {
    this._context = context;
    this._errorListener = new RecordingErrorListener();
  }

  /**
   * Build the HTML element for the given source.
   * @param source the source describing the compilation unit
   * @return the HTML element that was built
   * @throws AnalysisException if the analysis could not be performed
   */
  HtmlElementImpl buildHtmlElement(Source source) => buildHtmlElement2(source, _context.parseHtmlUnit(source));

  /**
   * Build the HTML element for the given source.
   * @param source the source describing the compilation unit
   * @param unit the AST structure representing the HTML
   * @throws AnalysisException if the analysis could not be performed
   */
  HtmlElementImpl buildHtmlElement2(Source source2, ht.HtmlUnit unit) {
    _lineInfo = _context.computeLineInfo(source2);
    HtmlElementImpl result = new HtmlElementImpl(_context, source2.shortName);
    result.source = source2;
    _htmlElement = result;
    unit.accept(this);
    _htmlElement = null;
    unit.element = result;
    return result;
  }

  /**
   * Return the listener to which analysis errors will be reported.
   * @return the listener to which analysis errors will be reported
   */
  RecordingErrorListener get errorListener => _errorListener;

  /**
   * Return an array containing information about all of the libraries that were resolved.
   * @return an array containing the libraries that were resolved
   */
  Set<Library> get resolvedLibraries => _resolvedLibraries;
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
      JavaStringBuilder builder = new JavaStringBuilder();
      builder.append("Found circularity in XML nodes: ");
      bool first = true;
      for (ht.XmlTagNode pathNode in _parentNodes) {
        if (first) {
          first = false;
        } else {
          builder.append(", ");
        }
        String tagName = pathNode.tag.lexeme;
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
    _parentNodes.add(node);
    try {
      if (isScriptNode(node)) {
        Source htmlSource = _htmlElement.source;
        ht.XmlAttributeNode scriptAttribute = getScriptSourcePath(node);
        String scriptSourcePath = scriptAttribute == null ? null : scriptAttribute.text;
        if (identical(node.attributeEnd.type, ht.TokenType.GT) && scriptSourcePath == null) {
          EmbeddedHtmlScriptElementImpl script = new EmbeddedHtmlScriptElementImpl(node);
          String contents = node.content;
          int attributeEnd = node.attributeEnd.end;
          LineInfo_Location location = _lineInfo.getLocation(attributeEnd);
          sc.StringScanner scanner = new sc.StringScanner(htmlSource, contents, _errorListener);
          scanner.setSourceStart(location.lineNumber, location.columnNumber, attributeEnd);
          sc.Token firstToken = scanner.tokenize();
          List<int> lineStarts = scanner.lineStarts;
          Parser parser = new Parser(htmlSource, _errorListener);
          CompilationUnit unit = parser.parseCompilationUnit(firstToken);
          unit.lineInfo = new LineInfo(lineStarts);
          try {
            LibraryResolver resolver = new LibraryResolver(_context);
            LibraryElementImpl library = resolver.resolveEmbeddedLibrary(htmlSource, unit, true) as LibraryElementImpl;
            script.scriptLibrary = library;
            _resolvedLibraries.addAll(resolver.resolvedLibraries);
            _errorListener.addAll(resolver.errorListener);
          } on AnalysisException catch (exception) {
            AnalysisEngine.instance.logger.logError3(exception);
          }
          _scripts.add(script);
        } else {
          ExternalHtmlScriptElementImpl script = new ExternalHtmlScriptElementImpl(node);
          if (scriptSourcePath != null) {
            try {
              parseUriWithException(scriptSourcePath);
              Source scriptSource = _context.sourceFactory.resolveUri(htmlSource, scriptSourcePath);
              script.scriptSource = scriptSource;
              if (!scriptSource.exists()) {
                reportError(HtmlWarningCode.URI_DOES_NOT_EXIST, scriptAttribute.offset + 1, scriptSourcePath.length, [scriptSourcePath]);
              }
            } on URISyntaxException catch (exception) {
              reportError(HtmlWarningCode.INVALID_URI, scriptAttribute.offset + 1, scriptSourcePath.length, [scriptSourcePath]);
            }
          }
          _scripts.add(script);
        }
      } else {
        node.visitChildren(this);
      }
    } finally {
      _parentNodes.remove(node);
    }
    return null;
  }

  /**
   * Return the first source attribute for the given tag node, or {@code null} if it does not exist.
   * @param node the node containing attributes
   * @return the source attribute contained in the given tag
   */
  ht.XmlAttributeNode getScriptSourcePath(ht.XmlTagNode node) {
    for (ht.XmlAttributeNode attribute in node.attributes) {
      if (attribute.name.lexeme == _SRC) {
        return attribute;
      }
    }
    return null;
  }

  /**
   * Determine if the specified node is a Dart script.
   * @param node the node to be tested (not {@code null})
   * @return {@code true} if the node is a Dart script
   */
  bool isScriptNode(ht.XmlTagNode node) {
    if (node.tagNodes.length != 0 || node.tag.lexeme != _SCRIPT) {
      return false;
    }
    for (ht.XmlAttributeNode attribute in node.attributes) {
      if (attribute.name.lexeme == _TYPE) {
        ht.Token valueToken = attribute.value;
        if (valueToken != null) {
          String value = valueToken.lexeme;
          if (value == _APPLICATION_DART_IN_DOUBLE_QUOTES || value == _APPLICATION_DART_IN_SINGLE_QUOTES) {
            return true;
          }
        }
      }
    }
    return false;
  }

  /**
   * Report an error with the given error code at the given location. Use the given arguments to
   * compose the error message.
   * @param errorCode the error code of the error to be reported
   * @param offset the offset of the first character to be highlighted
   * @param length the number of characters to be highlighted
   * @param arguments the arguments used to compose the error message
   */
  void reportError(ErrorCode errorCode, int offset, int length, List<Object> arguments) {
    _errorListener.onError(new AnalysisError.con2(_htmlElement.source, offset, length, errorCode, arguments));
  }
}
/**
 * Instances of the class {@code DeclarationResolver} are used to resolve declarations in an AST
 * structure to already built elements.
 */
class DeclarationResolver extends RecursiveASTVisitor<Object> {

  /**
   * The compilation unit containing the AST nodes being visited.
   */
  CompilationUnitElement _enclosingUnit;

  /**
   * The function type alias containing the AST nodes being visited, or {@code null} if we are not
   * in the scope of a function type alias.
   */
  FunctionTypeAliasElement _enclosingAlias;

  /**
   * The class containing the AST nodes being visited, or {@code null} if we are not in the scope of
   * a class.
   */
  ClassElement _enclosingClass;

  /**
   * The method or function containing the AST nodes being visited, or {@code null} if we are not in
   * the scope of a method or function.
   */
  ExecutableElement _enclosingExecutable;

  /**
   * The parameter containing the AST nodes being visited, or {@code null} if we are not in the
   * scope of a parameter.
   */
  ParameterElement _enclosingParameter;

  /**
   * Resolve the declarations within the given compilation unit to the elements rooted at the given
   * element.
   * @param unit the compilation unit to be resolved
   * @param element the root of the element model used to resolve the AST nodes
   */
  void resolve(CompilationUnit unit, CompilationUnitElement element2) {
    _enclosingUnit = element2;
    unit.element = element2;
    unit.accept(this);
  }
  Object visitCatchClause(CatchClause node) {
    SimpleIdentifier exceptionParameter = node.exceptionParameter;
    if (exceptionParameter != null) {
      List<LocalVariableElement> localVariables = _enclosingExecutable.localVariables;
      find3(localVariables, exceptionParameter);
      SimpleIdentifier stackTraceParameter = node.stackTraceParameter;
      if (stackTraceParameter != null) {
        find3(localVariables, stackTraceParameter);
      }
    }
    return super.visitCatchClause(node);
  }
  Object visitClassDeclaration(ClassDeclaration node) {
    ClassElement outerClass = _enclosingClass;
    try {
      SimpleIdentifier className = node.name;
      _enclosingClass = find3(_enclosingUnit.types, className);
      return super.visitClassDeclaration(node);
    } finally {
      _enclosingClass = outerClass;
    }
  }
  Object visitClassTypeAlias(ClassTypeAlias node) {
    ClassElement outerClass = _enclosingClass;
    try {
      SimpleIdentifier className = node.name;
      _enclosingClass = find3(_enclosingUnit.types, className);
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
        constructorName.element = _enclosingExecutable;
      }
      node.element = _enclosingExecutable as ConstructorElement;
      return super.visitConstructorDeclaration(node);
    } finally {
      _enclosingExecutable = outerExecutable;
    }
  }
  Object visitDeclaredIdentifier(DeclaredIdentifier node) {
    SimpleIdentifier variableName = node.identifier;
    find3(_enclosingExecutable.localVariables, variableName);
    return super.visitDeclaredIdentifier(node);
  }
  Object visitDefaultFormalParameter(DefaultFormalParameter node) {
    SimpleIdentifier parameterName = node.parameter.identifier;
    ParameterElement element = null;
    if (_enclosingExecutable != null) {
      element = find3(_enclosingExecutable.parameters, parameterName);
    } else {
      PrintStringWriter writer = new PrintStringWriter();
      writer.println("Invalid state found in the Analysis Engine:");
      writer.println("DeclarationResolver.visitDefaultFormalParameter() is visiting a parameter that does not appear to be in a method or function.");
      writer.println("Ancestors:");
      ASTNode parent = node.parent;
      while (parent != null) {
        writer.println(parent.runtimeType.toString());
        writer.println("---------");
        parent = parent.parent;
      }
      AnalysisEngine.instance.logger.logError2(writer.toString(), new AnalysisException());
    }
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
      ExportElement exportElement = find5(library.exports, _enclosingUnit.context.sourceFactory.resolveUri(_enclosingUnit.source, uri));
      node.element = exportElement;
    }
    return super.visitExportDirective(node);
  }
  Object visitFieldFormalParameter(FieldFormalParameter node) {
    if (node.parent is! DefaultFormalParameter) {
      SimpleIdentifier parameterName = node.identifier;
      ParameterElement element = find3(_enclosingExecutable.parameters, parameterName);
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
          _enclosingExecutable = find3(_enclosingExecutable.functions, functionName);
        } else {
          _enclosingExecutable = find3(_enclosingUnit.functions, functionName);
        }
      } else {
        PropertyAccessorElement accessor = find3(_enclosingUnit.accessors, functionName);
        if (identical(((property as sc.KeywordToken)).keyword, sc.Keyword.SET)) {
          accessor = accessor.variable.setter;
          functionName.element = accessor;
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
      FunctionElement element = find2(_enclosingExecutable.functions, node.beginToken.offset);
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
      _enclosingAlias = find3(_enclosingUnit.functionTypeAliases, aliasName);
      return super.visitFunctionTypeAlias(node);
    } finally {
      _enclosingAlias = outerAlias;
    }
  }
  Object visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    if (node.parent is! DefaultFormalParameter) {
      SimpleIdentifier parameterName = node.identifier;
      ParameterElement element = find3(_enclosingExecutable.parameters, parameterName);
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
      ImportElement importElement = find6(library.imports, _enclosingUnit.context.sourceFactory.resolveUri(_enclosingUnit.source, uri), node.prefix);
      node.element = importElement;
    }
    return super.visitImportDirective(node);
  }
  Object visitLabeledStatement(LabeledStatement node) {
    for (Label label in node.labels) {
      SimpleIdentifier labelName = label.label;
      find3(_enclosingExecutable.labels, labelName);
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
        _enclosingExecutable = find4(_enclosingClass.methods, nameOfMethod, methodName.offset);
        methodName.element = _enclosingExecutable;
      } else {
        PropertyAccessorElement accessor = find3(_enclosingClass.accessors, methodName);
        if (identical(((property as sc.KeywordToken)).keyword, sc.Keyword.SET)) {
          accessor = accessor.variable.setter;
          methodName.element = accessor;
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
      node.element = find(_enclosingUnit.library.parts, partSource);
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
      ParameterElement element = null;
      if (_enclosingParameter != null) {
        element = find3(_enclosingParameter.parameters, parameterName);
      } else if (_enclosingExecutable != null) {
        element = find3(_enclosingExecutable.parameters, parameterName);
      } else if (_enclosingAlias != null) {
        element = find3(_enclosingAlias.parameters, parameterName);
      } else {
      }
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
      find3(_enclosingExecutable.labels, labelName);
    }
    return super.visitSwitchCase(node);
  }
  Object visitSwitchDefault(SwitchDefault node) {
    for (Label label in node.labels) {
      SimpleIdentifier labelName = label.label;
      find3(_enclosingExecutable.labels, labelName);
    }
    return super.visitSwitchDefault(node);
  }
  Object visitTypeParameter(TypeParameter node) {
    SimpleIdentifier parameterName = node.name;
    if (_enclosingClass != null) {
      find3(_enclosingClass.typeVariables, parameterName);
    } else if (_enclosingAlias != null) {
      find3(_enclosingAlias.typeVariables, parameterName);
    }
    return super.visitTypeParameter(node);
  }
  Object visitVariableDeclaration(VariableDeclaration node) {
    VariableElement element = null;
    SimpleIdentifier variableName = node.name;
    if (_enclosingExecutable != null) {
      element = find3(_enclosingExecutable.localVariables, variableName);
    }
    if (element == null && _enclosingClass != null) {
      element = find3(_enclosingClass.fields, variableName);
    }
    if (element == null && _enclosingUnit != null) {
      element = find3(_enclosingUnit.topLevelVariables, variableName);
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
   * Append the value of the given string literal to the given string builder.
   * @param builder the builder to which the string's value is to be appended
   * @param literal the string literal whose value is to be appended to the builder
   * @throws IllegalArgumentException if the string is not a constant string without any string
   * interpolation
   */
  void appendStringValue(JavaStringBuilder builder, StringLiteral literal) {
    if (literal is SimpleStringLiteral) {
      builder.append(((literal as SimpleStringLiteral)).value);
    } else if (literal is AdjacentStrings) {
      for (StringLiteral stringLiteral in ((literal as AdjacentStrings)).strings) {
        appendStringValue(builder, stringLiteral);
      }
    } else {
      throw new IllegalArgumentException();
    }
  }

  /**
   * Return the element for the part with the given source, or {@code null} if there is no element
   * for the given source.
   * @param parts the elements for the parts
   * @param partSource the source for the part whose element is to be returned
   * @return the element for the part with the given source
   */
  CompilationUnitElement find(List<CompilationUnitElement> parts, Source partSource) {
    for (CompilationUnitElement part in parts) {
      if (part.source == partSource) {
        return part;
      }
    }
    return null;
  }

  /**
   * Return the element in the given array of elements that was created for the declaration at the
   * given offset. This method should only be used when there is no name
   * @param elements the elements of the appropriate kind that exist in the current context
   * @param offset the offset of the name of the element to be returned
   * @return the element at the given offset
   */
  Element find2(List<Element> elements, int offset) => find4(elements, "", offset);

  /**
   * Return the element in the given array of elements that was created for the declaration with the
   * given name.
   * @param elements the elements of the appropriate kind that exist in the current context
   * @param identifier the name node in the declaration of the element to be returned
   * @return the element created for the declaration with the given name
   */
  Element find3(List<Element> elements, SimpleIdentifier identifier) {
    Element element = find4(elements, identifier.name, identifier.offset);
    identifier.element = element;
    return element;
  }

  /**
   * Return the element in the given array of elements that was created for the declaration with the
   * given name at the given offset.
   * @param elements the elements of the appropriate kind that exist in the current context
   * @param name the name of the element to be returned
   * @param offset the offset of the name of the element to be returned
   * @return the element with the given name and offset
   */
  Element find4(List<Element> elements, String name, int offset) {
    for (Element element in elements) {
      if (element.displayName == name && element.nameOffset == offset) {
        return element;
      }
    }
    return null;
  }

  /**
   * Return the export element from the given array whose library has the given source, or{@code null} if there is no such export.
   * @param exports the export elements being searched
   * @param source the source of the library associated with the export element to being searched
   * for
   * @return the export element whose library has the given source
   */
  ExportElement find5(List<ExportElement> exports, Source source2) {
    for (ExportElement export in exports) {
      if (export.exportedLibrary.source == source2) {
        return export;
      }
    }
    return null;
  }

  /**
   * Return the import element from the given array whose library has the given source and that has
   * the given prefix, or {@code null} if there is no such import.
   * @param imports the import elements being searched
   * @param source the source of the library associated with the import element to being searched
   * for
   * @param prefix the prefix with which the library was imported
   * @return the import element whose library has the given source and prefix
   */
  ImportElement find6(List<ImportElement> imports, Source source2, SimpleIdentifier prefix2) {
    for (ImportElement element in imports) {
      if (element.importedLibrary.source == source2) {
        PrefixElement prefixElement = element.prefix;
        if (prefix2 == null) {
          if (prefixElement == null) {
            return element;
          }
        } else {
          if (prefixElement != null && prefix2.name == prefixElement.displayName) {
            return element;
          }
        }
      }
    }
    return null;
  }

  /**
   * Return the value of the given string literal, or {@code null} if the string is not a constant
   * string without any string interpolation.
   * @param literal the string literal whose value is to be returned
   * @return the value of the given string literal
   */
  String getStringValue(StringLiteral literal) {
    if (literal is StringInterpolation) {
      return null;
    }
    JavaStringBuilder builder = new JavaStringBuilder();
    try {
      appendStringValue(builder, literal);
    } on IllegalArgumentException catch (exception) {
      return null;
    }
    return builder.toString().trim();
  }
}
/**
 * Instances of the class {@code ElementResolver} are used by instances of {@link ResolverVisitor}to resolve references within the AST structure to the elements being referenced. The requirements
 * for the element resolver are:
 * <ol>
 * <li>Every {@link SimpleIdentifier} should be resolved to the element to which it refers.
 * Specifically:
 * <ul>
 * <li>An identifier within the declaration of that name should resolve to the element being
 * declared.</li>
 * <li>An identifier denoting a prefix should resolve to the element representing the import that
 * defines the prefix (an {@link ImportElement}).</li>
 * <li>An identifier denoting a variable should resolve to the element representing the variable (a{@link VariableElement}).</li>
 * <li>An identifier denoting a parameter should resolve to the element representing the parameter
 * (a {@link ParameterElement}).</li>
 * <li>An identifier denoting a field should resolve to the element representing the getter or
 * setter being invoked (a {@link PropertyAccessorElement}).</li>
 * <li>An identifier denoting the name of a method or function being invoked should resolve to the
 * element representing the method or function (a {@link ExecutableElement}).</li>
 * <li>An identifier denoting a label should resolve to the element representing the label (a{@link LabelElement}).</li>
 * </ul>
 * The identifiers within directives are exceptions to this rule and are covered below.</li>
 * <li>Every node containing a token representing an operator that can be overridden ({@link BinaryExpression}, {@link PrefixExpression}, {@link PostfixExpression}) should resolve to
 * the element representing the method invoked by that operator (a {@link MethodElement}).</li>
 * <li>Every {@link FunctionExpressionInvocation} should resolve to the element representing the
 * function being invoked (a {@link FunctionElement}). This will be the same element as that to
 * which the name is resolved if the function has a name, but is provided for those cases where an
 * unnamed function is being invoked.</li>
 * <li>Every {@link LibraryDirective} and {@link PartOfDirective} should resolve to the element
 * representing the library being specified by the directive (a {@link LibraryElement}) unless, in
 * the case of a part-of directive, the specified library does not exist.</li>
 * <li>Every {@link ImportDirective} and {@link ExportDirective} should resolve to the element
 * representing the library being specified by the directive unless the specified library does not
 * exist (an {@link ImportElement} or {@link ExportElement}).</li>
 * <li>The identifier representing the prefix in an {@link ImportDirective} should resolve to the
 * element representing the prefix (a {@link PrefixElement}).</li>
 * <li>The identifiers in the hide and show combinators in {@link ImportDirective}s and{@link ExportDirective}s should resolve to the elements that are being hidden or shown,
 * respectively, unless those names are not defined in the specified library (or the specified
 * library does not exist).</li>
 * <li>Every {@link PartDirective} should resolve to the element representing the compilation unit
 * being specified by the string unless the specified compilation unit does not exist (a{@link CompilationUnitElement}).</li>
 * </ol>
 * Note that AST nodes that would represent elements that are not defined are not resolved to
 * anything. This includes such things as references to undeclared variables (which is an error) and
 * names in hide and show combinators that are not defined in the imported library (which is not an
 * error).
 * @coverage dart.engine.resolver
 */
class ElementResolver extends SimpleASTVisitor<Object> {

  /**
   * @return {@code true} if the given identifier is the return type of a constructor declaration.
   */
  static bool isConstructorReturnType(SimpleIdentifier node) {
    ASTNode parent = node.parent;
    if (parent is ConstructorDeclaration) {
      ConstructorDeclaration constructor = parent as ConstructorDeclaration;
      return identical(constructor.returnType, node);
    }
    return false;
  }

  /**
   * @return {@code true} if the given identifier is the return type of a factory constructor
   * declaration.
   */
  static bool isFactoryConstructorReturnType(SimpleIdentifier node) {
    ASTNode parent = node.parent;
    if (parent is ConstructorDeclaration) {
      ConstructorDeclaration constructor = parent as ConstructorDeclaration;
      return identical(constructor.returnType, node) && constructor.factoryKeyword != null;
    }
    return false;
  }

  /**
   * Checks if the given 'super' expression is used in the valid context.
   * @param node the 'super' expression to analyze
   * @return {@code true} if the given 'super' expression is in the valid context
   */
  static bool isSuperInValidContext(SuperExpression node) {
    for (ASTNode n = node; n != null; n = n.parent) {
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
        return !method.isStatic();
      }
    }
    return false;
  }

  /**
   * The resolver driving this participant.
   */
  ResolverVisitor _resolver;

  /**
   * A flag indicating whether we are running in strict mode. In strict mode, error reporting is
   * based exclusively on the static type information.
   */
  bool _strictMode = false;

  /**
   * The name of the method that can be implemented by a class to allow its instances to be invoked
   * as if they were a function.
   */
  static String CALL_METHOD_NAME = "call";

  /**
   * The name of the method that will be invoked if an attempt is made to invoke an undefined method
   * on an object.
   */
  static String _NO_SUCH_METHOD_METHOD_NAME = "noSuchMethod";

  /**
   * Initialize a newly created visitor to resolve the nodes in a compilation unit.
   * @param resolver the resolver driving this participant
   */
  ElementResolver(ResolverVisitor resolver) {
    this._resolver = resolver;
    _strictMode = resolver.definingLibrary.context.analysisOptions.strictMode;
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
        node.element = select3(staticMethod, propagatedMethod);
        if (shouldReportMissingMember(staticType, staticMethod) && (_strictMode || propagatedType == null || shouldReportMissingMember(propagatedType, propagatedMethod))) {
          _resolver.reportError6(StaticTypeWarningCode.UNDEFINED_METHOD, operator, [methodName, staticType.displayName]);
        }
      }
    }
    return null;
  }
  Object visitBinaryExpression(BinaryExpression node) {
    sc.Token operator = node.operator;
    if (operator.isUserDefinableOperator()) {
      Expression leftOperand = node.leftOperand;
      if (leftOperand != null) {
        String methodName = operator.lexeme;
        Type2 staticType = getStaticType(leftOperand);
        MethodElement staticMethod = lookUpMethod(leftOperand, staticType, methodName);
        node.staticElement = staticMethod;
        Type2 propagatedType = getPropagatedType(leftOperand);
        MethodElement propagatedMethod = lookUpMethod(leftOperand, propagatedType, methodName);
        node.element = select3(staticMethod, propagatedMethod);
        if (shouldReportMissingMember(staticType, staticMethod) && (_strictMode || propagatedType == null || shouldReportMissingMember(propagatedType, propagatedMethod))) {
          _resolver.reportError6(StaticTypeWarningCode.UNDEFINED_OPERATOR, operator, [methodName, staticType.displayName]);
        }
      }
    }
    return null;
  }
  Object visitBreakStatement(BreakStatement node) {
    SimpleIdentifier labelNode = node.label;
    LabelElementImpl labelElement = lookupLabel(node, labelNode);
    if (labelElement != null && labelElement.isOnSwitchMember()) {
      _resolver.reportError(ResolverErrorCode.BREAK_LABEL_ON_SWITCH_MEMBER, labelNode, []);
    }
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
      SimpleIdentifier simpleIdentifier = identifier as SimpleIdentifier;
      Element element = resolveSimpleIdentifier(simpleIdentifier);
      if (element == null) {
        element = findImportWithoutPrefix(simpleIdentifier);
        if (element is MultiplyDefinedElement) {
          element = null;
        }
      }
      if (element == null) {
      } else {
        if (element.library != _resolver.definingLibrary) {
        }
        recordResolution(simpleIdentifier, element);
        if (node.newKeyword != null) {
          if (element is ClassElement) {
            ConstructorElement constructor = ((element as ClassElement)).unnamedConstructor;
            if (constructor == null) {
            } else {
              recordResolution(simpleIdentifier, constructor);
            }
          } else {
          }
        }
      }
    } else if (identifier is PrefixedIdentifier) {
      PrefixedIdentifier prefixedIdentifier = identifier as PrefixedIdentifier;
      SimpleIdentifier prefix = prefixedIdentifier.prefix;
      SimpleIdentifier name = prefixedIdentifier.identifier;
      Element element = resolveSimpleIdentifier(prefix);
      if (element == null) {
      } else {
        if (element is PrefixElement) {
          recordResolution(prefix, element);
          element = _resolver.nameScope.lookup(identifier, _resolver.definingLibrary);
          recordResolution(name, element);
          return null;
        }
        LibraryElement library = element.library;
        if (library == null) {
          AnalysisEngine.instance.logger.logError("Found element with null library: ${element.name}");
        } else if (library != _resolver.definingLibrary) {
        }
        recordResolution(name, element);
        if (node.newKeyword == null) {
          if (element is ClassElement) {
            Element memberElement = lookupGetterOrMethod(((element as ClassElement)).type, name.name);
            if (memberElement == null) {
              memberElement = ((element as ClassElement)).getNamedConstructor(name.name);
              if (memberElement == null) {
                memberElement = lookUpSetter(prefix, ((element as ClassElement)).type, name.name);
              }
            }
            if (memberElement == null) {
            } else {
              recordResolution(name, memberElement);
            }
          } else {
          }
        } else {
          if (element is ClassElement) {
            ConstructorElement constructor = ((element as ClassElement)).getNamedConstructor(name.name);
            if (constructor == null) {
            } else {
              recordResolution(name, constructor);
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
      ConstructorElementImpl constructorElement = element as ConstructorElementImpl;
      ConstructorName redirectedNode = node.redirectedConstructor;
      if (redirectedNode != null) {
        ConstructorElement redirectedElement = redirectedNode.element;
        constructorElement.redirectedConstructor = redirectedElement;
      }
      for (ConstructorInitializer initializer in node.initializers) {
        if (initializer is RedirectingConstructorInvocation) {
          ConstructorElement redirectedElement = ((initializer as RedirectingConstructorInvocation)).element;
          constructorElement.redirectedConstructor = redirectedElement;
        }
      }
      setMetadata(constructorElement, node);
    }
    return null;
  }
  Object visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    SimpleIdentifier fieldName = node.fieldName;
    ClassElement enclosingClass = _resolver.enclosingClass;
    FieldElement fieldElement = ((enclosingClass as ClassElementImpl)).getField(fieldName.name);
    recordResolution(fieldName, fieldElement);
    if (fieldElement == null || fieldElement.isSynthetic()) {
      _resolver.reportError(CompileTimeErrorCode.INITIALIZER_FOR_NON_EXISTANT_FIELD, node, [fieldName]);
    } else if (fieldElement.isStatic()) {
      _resolver.reportError(CompileTimeErrorCode.INITIALIZER_FOR_STATIC_FIELD, node, [fieldName]);
    }
    return null;
  }
  Object visitConstructorName(ConstructorName node) {
    Type2 type = node.type.type;
    if (type != null && type.isDynamic()) {
      return null;
    } else if (type is! InterfaceType) {
      ASTNode parent = node.parent;
      if (parent is InstanceCreationExpression) {
        if (((parent as InstanceCreationExpression)).isConst()) {
        } else {
        }
      } else {
      }
      return null;
    }
    ConstructorElement constructor;
    SimpleIdentifier name = node.name;
    InterfaceType interfaceType = type as InterfaceType;
    LibraryElement definingLibrary = _resolver.definingLibrary;
    if (name == null) {
      constructor = interfaceType.lookUpConstructor(null, definingLibrary);
    } else {
      constructor = interfaceType.lookUpConstructor(name.name, definingLibrary);
      name.staticElement = constructor;
      name.element = constructor;
    }
    node.staticElement = constructor;
    node.element = constructor;
    return null;
  }
  Object visitContinueStatement(ContinueStatement node) {
    SimpleIdentifier labelNode = node.label;
    LabelElementImpl labelElement = lookupLabel(node, labelNode);
    if (labelElement != null && labelElement.isOnSwitchStatement()) {
      _resolver.reportError(ResolverErrorCode.CONTINUE_LABEL_ON_SWITCH, labelNode, []);
    }
    return null;
  }
  Object visitDeclaredIdentifier(DeclaredIdentifier node) {
    setMetadata(node.element, node);
    return null;
  }
  Object visitExportDirective(ExportDirective node) {
    Element element = node.element;
    if (element is ExportElement) {
      resolveCombinators(((element as ExportElement)).exportedLibrary, node.combinators);
      setMetadata(element, node);
    }
    return null;
  }
  Object visitFieldFormalParameter(FieldFormalParameter node) {
    String fieldName = node.identifier.name;
    ClassElement classElement = _resolver.enclosingClass;
    if (classElement != null) {
      FieldElement fieldElement = ((classElement as ClassElementImpl)).getField(fieldName);
      if (fieldElement == null) {
        _resolver.reportError(CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTANT_FIELD, node, [fieldName]);
      } else {
        ParameterElement parameterElement = node.element;
        if (parameterElement is FieldFormalParameterElementImpl) {
          FieldFormalParameterElementImpl fieldFormal = parameterElement as FieldFormalParameterElementImpl;
          fieldFormal.field = fieldElement;
          Type2 declaredType = fieldFormal.type;
          Type2 fieldType = fieldElement.type;
          if (node.type == null) {
            fieldFormal.type = fieldType;
          }
          if (fieldElement.isSynthetic()) {
            _resolver.reportError(CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTANT_FIELD, node, [fieldName]);
          } else if (fieldElement.isStatic()) {
            _resolver.reportError(CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_STATIC_FIELD, node, [fieldName]);
          } else if (declaredType != null && fieldType != null && !declaredType.isAssignableTo(fieldType)) {
            _resolver.reportError(StaticWarningCode.FIELD_INITIALIZING_FORMAL_NOT_ASSIGNABLE, node, [declaredType.displayName, fieldType.displayName]);
          }
        } else {
          if (fieldElement.isSynthetic()) {
            _resolver.reportError(CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTANT_FIELD, node, [fieldName]);
          } else if (fieldElement.isStatic()) {
            _resolver.reportError(CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_STATIC_FIELD, node, [fieldName]);
          }
        }
      }
    }
    return super.visitFieldFormalParameter(node);
  }
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    setMetadata(node.element, node);
    return null;
  }
  Object visitFunctionExpressionInvocation(FunctionExpressionInvocation node) => null;
  Object visitFunctionTypeAlias(FunctionTypeAlias node) {
    setMetadata(node.element, node);
    return null;
  }
  Object visitImportDirective(ImportDirective node) {
    SimpleIdentifier prefixNode = node.prefix;
    if (prefixNode != null) {
      String prefixName = prefixNode.name;
      for (PrefixElement prefixElement in _resolver.definingLibrary.prefixes) {
        if (prefixElement.displayName == prefixName) {
          recordResolution(prefixNode, prefixElement);
          break;
        }
      }
    }
    Element element = node.element;
    if (element is ImportElement) {
      ImportElement importElement = element as ImportElement;
      LibraryElement library = importElement.importedLibrary;
      if (library != null) {
        resolveCombinators(library, node.combinators);
      }
      setMetadata(element, node);
    }
    return null;
  }
  Object visitIndexExpression(IndexExpression node) {
    Expression target = node.realTarget;
    Type2 staticType = getStaticType(target);
    Type2 propagatedType = getPropagatedType(target);
    if (node.inGetterContext()) {
      String methodName = sc.TokenType.INDEX.lexeme;
      bool error = lookUpCheckIndexOperator(node, target, methodName, staticType, propagatedType);
      if (error) {
        return null;
      }
    }
    if (node.inSetterContext()) {
      String methodName = sc.TokenType.INDEX_EQ.lexeme;
      lookUpCheckIndexOperator(node, target, methodName, staticType, propagatedType);
    }
    return null;
  }
  Object visitInstanceCreationExpression(InstanceCreationExpression node) {
    ConstructorElement invokedConstructor = node.constructorName.element;
    node.staticElement = invokedConstructor;
    node.element = invokedConstructor;
    ArgumentList argumentList = node.argumentList;
    List<ParameterElement> parameters = resolveArgumentsToParameters(node.isConst(), argumentList, invokedConstructor);
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
    Expression target = node.realTarget;
    Element staticElement;
    Element propagatedElement;
    if (target is SuperExpression && !isSuperInValidContext((target as SuperExpression))) {
      return null;
    }
    if (target == null) {
      staticElement = resolveInvokedElement2(methodName);
      propagatedElement = null;
    } else {
      Type2 targetType = getStaticType(target);
      staticElement = resolveInvokedElement(target, targetType, methodName);
      propagatedElement = resolveInvokedElement(target, getPropagatedType(target), methodName);
    }
    staticElement = convertSetterToGetter(staticElement);
    propagatedElement = convertSetterToGetter(propagatedElement);
    recordResolution2(methodName, staticElement, propagatedElement);
    ArgumentList argumentList = node.argumentList;
    if (staticElement != null) {
      List<ParameterElement> parameters = computePropagatedParameters(argumentList, staticElement);
      if (parameters != null) {
        argumentList.correspondingStaticParameters = parameters;
      }
    }
    if (propagatedElement != null) {
      List<ParameterElement> parameters = computePropagatedParameters(argumentList, propagatedElement);
      if (parameters != null) {
        argumentList.correspondingParameters = parameters;
      }
    }
    ErrorCode errorCode;
    if (staticElement == null) {
      if (propagatedElement == null) {
        errorCode = checkForInvocationError(target, staticElement);
      } else {
        errorCode = checkForInvocationError(target, propagatedElement);
      }
    } else {
      errorCode = checkForInvocationError(target, staticElement);
      if (propagatedElement != null) {
        ErrorCode propagatedError = checkForInvocationError(target, propagatedElement);
        errorCode = select(errorCode, propagatedError);
      }
    }
    if (identical(errorCode, StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION)) {
      _resolver.reportError(StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION, methodName, [methodName.name]);
    } else if (identical(errorCode, StaticTypeWarningCode.UNDEFINED_FUNCTION)) {
      _resolver.reportError(StaticTypeWarningCode.UNDEFINED_FUNCTION, methodName, [methodName.name]);
    } else if (identical(errorCode, StaticTypeWarningCode.UNDEFINED_METHOD)) {
      String targetTypeName;
      if (target == null) {
        ClassElement enclosingClass = _resolver.enclosingClass;
        targetTypeName = enclosingClass.displayName;
      } else {
        Type2 targetType = getPropagatedType(target);
        if (targetType == null) {
          targetType = getStaticType(target);
        }
        targetTypeName = targetType == null ? null : targetType.displayName;
      }
      _resolver.reportError(StaticTypeWarningCode.UNDEFINED_METHOD, methodName, [methodName.name, targetTypeName]);
    } else if (identical(errorCode, StaticTypeWarningCode.UNDEFINED_SUPER_METHOD)) {
      Type2 targetType = getPropagatedType(target);
      if (targetType == null) {
        targetType = getStaticType(target);
      }
      String targetTypeName = targetType == null ? null : targetType.name;
      _resolver.reportError(StaticTypeWarningCode.UNDEFINED_SUPER_METHOD, methodName, [methodName.name, targetTypeName]);
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
    node.element = select3(staticMethod, propagatedMethod);
    if (shouldReportMissingMember(staticType, staticMethod) && (_strictMode || propagatedType == null || shouldReportMissingMember(propagatedType, propagatedMethod))) {
      _resolver.reportError6(StaticTypeWarningCode.UNDEFINED_OPERATOR, node.operator, [methodName, staticType.displayName]);
    }
    return null;
  }
  Object visitPrefixedIdentifier(PrefixedIdentifier node) {
    SimpleIdentifier prefix = node.prefix;
    SimpleIdentifier identifier = node.identifier;
    Element prefixElement = prefix.element;
    if (prefixElement is PrefixElement) {
      Element element = _resolver.nameScope.lookup(node, _resolver.definingLibrary);
      if (element == null) {
        return null;
      }
      if (element is PropertyAccessorElement && identifier.inSetterContext()) {
        PropertyInducingElement variable = ((element as PropertyAccessorElement)).variable;
        if (variable != null) {
          PropertyAccessorElement setter = variable.setter;
          if (setter != null) {
            element = setter;
          }
        }
      }
      recordResolution(identifier, element);
      return null;
    }
    resolvePropertyAccess(prefix, identifier);
    return null;
  }
  Object visitPrefixExpression(PrefixExpression node) {
    sc.Token operator = node.operator;
    sc.TokenType operatorType = operator.type;
    if (operatorType.isUserDefinableOperator() || identical(operatorType, sc.TokenType.PLUS_PLUS) || identical(operatorType, sc.TokenType.MINUS_MINUS)) {
      Expression operand = node.operand;
      String methodName = getPrefixOperator(node);
      Type2 staticType = getStaticType(operand);
      MethodElement staticMethod = lookUpMethod(operand, staticType, methodName);
      node.staticElement = staticMethod;
      Type2 propagatedType = getPropagatedType(operand);
      MethodElement propagatedMethod = lookUpMethod(operand, propagatedType, methodName);
      node.element = select3(staticMethod, propagatedMethod);
      if (shouldReportMissingMember(staticType, staticMethod) && (_strictMode || propagatedType == null || shouldReportMissingMember(propagatedType, propagatedMethod))) {
        _resolver.reportError6(StaticTypeWarningCode.UNDEFINED_OPERATOR, operator, [methodName, staticType.displayName]);
      }
    }
    return null;
  }
  Object visitPropertyAccess(PropertyAccess node) {
    Expression target = node.realTarget;
    if (target is SuperExpression && !isSuperInValidContext((target as SuperExpression))) {
      return null;
    }
    SimpleIdentifier propertyName = node.propertyName;
    resolvePropertyAccess(target, propertyName);
    return null;
  }
  Object visitRedirectingConstructorInvocation(RedirectingConstructorInvocation node) {
    ClassElement enclosingClass = _resolver.enclosingClass;
    if (enclosingClass == null) {
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
      return null;
    }
    if (name != null) {
      recordResolution(name, element);
    }
    node.staticElement = element;
    node.element = element;
    ArgumentList argumentList = node.argumentList;
    List<ParameterElement> parameters = resolveArgumentsToParameters(false, argumentList, element);
    if (parameters != null) {
      argumentList.correspondingStaticParameters = parameters;
    }
    return null;
  }
  Object visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.element != null) {
      return null;
    }
    Element element = resolveSimpleIdentifier(node);
    if (isFactoryConstructorReturnType(node) && element != _resolver.enclosingClass) {
      _resolver.reportError(CompileTimeErrorCode.INVALID_FACTORY_NAME_NOT_A_CLASS, node, []);
    } else if (element == null) {
      if (isConstructorReturnType(node)) {
        _resolver.reportError(CompileTimeErrorCode.INVALID_CONSTRUCTOR_NAME, node, []);
      } else if (!classDeclaresNoSuchMethod(_resolver.enclosingClass)) {
        _resolver.reportError(StaticWarningCode.UNDEFINED_IDENTIFIER, node, [node.name]);
      }
    }
    recordResolution(node, element);
    return null;
  }
  Object visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    ClassElement enclosingClass = _resolver.enclosingClass;
    if (enclosingClass == null) {
      return null;
    }
    ClassElement superclass = getSuperclass(enclosingClass);
    if (superclass == null) {
      return null;
    }
    SimpleIdentifier name = node.constructorName;
    ConstructorElement element;
    if (name == null) {
      element = superclass.unnamedConstructor;
    } else {
      element = superclass.getNamedConstructor(name.name);
    }
    if (element == null) {
      if (name != null) {
        _resolver.reportError(CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER, node, [superclass.name, name]);
      } else {
        _resolver.reportError(CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT, node, [superclass.name]);
      }
      return null;
    } else {
      if (element.isFactory()) {
        _resolver.reportError(CompileTimeErrorCode.NON_GENERATIVE_CONSTRUCTOR, node, [element]);
      }
    }
    if (name != null) {
      recordResolution(name, element);
    }
    node.staticElement = element;
    node.element = element;
    ArgumentList argumentList = node.argumentList;
    List<ParameterElement> parameters = resolveArgumentsToParameters(false, argumentList, element);
    if (parameters != null) {
      argumentList.correspondingStaticParameters = parameters;
    }
    return null;
  }
  Object visitSuperExpression(SuperExpression node) {
    if (!isSuperInValidContext(node)) {
      _resolver.reportError(CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT, node, []);
    }
    return super.visitSuperExpression(node);
  }
  Object visitTypeParameter(TypeParameter node) {
    TypeName bound = node.bound;
    if (bound != null) {
      TypeVariableElementImpl variable = node.name.element as TypeVariableElementImpl;
      if (variable != null) {
        variable.bound = bound.type;
      }
    }
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
   * @param annotationList the list of elements to which new elements are to be added
   * @param annotations the AST nodes used to generate new elements
   */
  void addAnnotations(List<ElementAnnotationImpl> annotationList, NodeList<Annotation> annotations) {
    for (Annotation annotationNode in annotations) {
      Element resolvedElement = annotationNode.element;
      if (resolvedElement != null) {
        annotationList.add(new ElementAnnotationImpl(resolvedElement));
      }
    }
  }

  /**
   * Given that we have found code to invoke the given element, return the error code that should be
   * reported, or {@code null} if no error should be reported.
   * @param target the target of the invocation, or {@code null} if there was no target
   * @param element the element to be invoked
   * @return the error code that should be reported
   */
  ErrorCode checkForInvocationError(Expression target, Element element2) {
    if (element2 is PropertyAccessorElement) {
      FunctionType getterType = ((element2 as PropertyAccessorElement)).type;
      if (getterType != null) {
        Type2 returnType = getterType.returnType;
        if (!isExecutableType(returnType)) {
          return StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION;
        }
      }
    } else if (element2 is ExecutableElement) {
      return null;
    } else if (element2 == null && target is SuperExpression) {
      return StaticTypeWarningCode.UNDEFINED_SUPER_METHOD;
    } else {
      if (element2 is PropertyInducingElement) {
        PropertyAccessorElement getter = ((element2 as PropertyInducingElement)).getter;
        FunctionType getterType = getter.type;
        if (getterType != null) {
          Type2 returnType = getterType.returnType;
          if (!isExecutableType(returnType)) {
            return StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION;
          }
        }
      } else if (element2 is VariableElement) {
        Type2 variableType = _resolver.overrideManager.getType(element2);
        if (variableType == null) {
          variableType = ((element2 as VariableElement)).type;
        }
        if (!isExecutableType(variableType)) {
          return StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION;
        }
      } else {
        if (target == null) {
          ClassElement enclosingClass = _resolver.enclosingClass;
          if (enclosingClass == null) {
            return StaticTypeWarningCode.UNDEFINED_FUNCTION;
          } else if (element2 == null) {
            if (!classDeclaresNoSuchMethod(enclosingClass)) {
              return StaticTypeWarningCode.UNDEFINED_METHOD;
            }
          } else {
            return StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION;
          }
        } else {
          Type2 targetType = getStaticType(target);
          if (targetType == null) {
            return StaticTypeWarningCode.UNDEFINED_FUNCTION;
          } else if (!targetType.isDynamic() && !classDeclaresNoSuchMethod2(targetType.element)) {
            return StaticTypeWarningCode.UNDEFINED_METHOD;
          }
        }
      }
    }
    return null;
  }

  /**
   * Return {@code true} if the given class declares a method named "noSuchMethod" and is not the
   * class 'Object'.
   * @param element the class being tested
   * @return {@code true} if the given class declares a method named "noSuchMethod"
   */
  bool classDeclaresNoSuchMethod(ClassElement classElement) {
    if (classElement == null) {
      return false;
    }
    MethodElement methodElement = classElement.lookUpMethod(_NO_SUCH_METHOD_METHOD_NAME, _resolver.definingLibrary);
    return methodElement != null && methodElement.enclosingElement.supertype != null;
  }

  /**
   * Return {@code true} if the given element represents a class that declares a method named
   * "noSuchMethod" and is not the class 'Object'.
   * @param element the element being tested
   * @return {@code true} if the given element represents a class that declares a method named
   * "noSuchMethod"
   */
  bool classDeclaresNoSuchMethod2(Element element) {
    if (element is ClassElement) {
      return classDeclaresNoSuchMethod((element as ClassElement));
    }
    return false;
  }

  /**
   * Given a list of arguments and the element that will be invoked using those argument, compute
   * the list of parameters that correspond to the list of arguments. Return the parameters that
   * correspond to the arguments, or {@code null} if no correspondence could be computed.
   * @param argumentList the list of arguments being passed to the element
   * @param executableElement the element that will be invoked with the arguments
   * @return the parameters that correspond to the arguments
   */
  List<ParameterElement> computePropagatedParameters(ArgumentList argumentList, Element element2) {
    if (element2 is PropertyAccessorElement) {
      FunctionType getterType = ((element2 as PropertyAccessorElement)).type;
      if (getterType != null) {
        Type2 getterReturnType = getterType.returnType;
        if (getterReturnType is InterfaceType) {
          MethodElement callMethod = ((getterReturnType as InterfaceType)).lookUpMethod(CALL_METHOD_NAME, _resolver.definingLibrary);
          if (callMethod != null) {
            return resolveArgumentsToParameters(false, argumentList, callMethod);
          }
        } else if (getterReturnType is FunctionType) {
          Element functionElement = ((getterReturnType as FunctionType)).element;
          if (functionElement is ExecutableElement) {
            return resolveArgumentsToParameters(false, argumentList, (functionElement as ExecutableElement));
          }
        }
      }
    } else if (element2 is ExecutableElement) {
      return resolveArgumentsToParameters(false, argumentList, (element2 as ExecutableElement));
    } else if (element2 is VariableElement) {
      VariableElement variable = element2 as VariableElement;
      Type2 type = variable.type;
      if (type is FunctionType) {
        FunctionType functionType = type as FunctionType;
        List<ParameterElement> parameters = functionType.parameters;
        return resolveArgumentsToParameters2(false, argumentList, parameters);
      } else if (type is InterfaceType) {
        MethodElement callMethod = ((type as InterfaceType)).lookUpMethod(CALL_METHOD_NAME, _resolver.definingLibrary);
        if (callMethod != null) {
          List<ParameterElement> parameters = callMethod.parameters;
          return resolveArgumentsToParameters2(false, argumentList, parameters);
        }
      }
    }
    return null;
  }

  /**
   * If the given element is a setter, return the getter associated with it. Otherwise, return the
   * element unchanged.
   * @param element the element to be normalized
   * @return a non-setter element derived from the given element
   */
  Element convertSetterToGetter(Element element) {
    if (element is PropertyAccessorElement) {
      return ((element as PropertyAccessorElement)).variable.getter;
    }
    return element;
  }

  /**
   * Look for any declarations of the given identifier that are imported using a prefix. Return the
   * element that was found, or {@code null} if the name is not imported using a prefix.
   * @param identifier the identifier that might have been imported using a prefix
   * @return the element that was found
   */
  Element findImportWithoutPrefix(SimpleIdentifier identifier) {
    Element element = null;
    Scope nameScope = _resolver.nameScope;
    LibraryElement definingLibrary = _resolver.definingLibrary;
    for (ImportElement importElement in definingLibrary.imports) {
      PrefixElement prefixElement = importElement.prefix;
      if (prefixElement != null) {
        Identifier prefixedIdentifier = new ElementResolver_SyntheticIdentifier("${prefixElement.name}.${identifier.name}");
        Element importedElement = nameScope.lookup(prefixedIdentifier, definingLibrary);
        if (importedElement != null) {
          if (element == null) {
            element = importedElement;
          } else {
            element = new MultiplyDefinedElementImpl(definingLibrary.context, element, importedElement);
          }
        }
      }
    }
    return element;
  }

  /**
   * Return the name of the method invoked by the given postfix expression.
   * @param node the postfix expression being invoked
   * @return the name of the method invoked by the expression
   */
  String getPostfixOperator(PostfixExpression node) => (identical(node.operator.type, sc.TokenType.PLUS_PLUS)) ? sc.TokenType.PLUS.lexeme : sc.TokenType.MINUS.lexeme;

  /**
   * Return the name of the method invoked by the given postfix expression.
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
   * @param expression the expression whose type is to be returned
   * @return the type of the given expression
   */
  Type2 getPropagatedType(Expression expression) {
    Type2 propagatedType = resolveTypeVariable(expression.propagatedType);
    if (propagatedType is FunctionType) {
      propagatedType = _resolver.typeProvider.functionType;
    }
    return propagatedType;
  }

  /**
   * Return the static type of the given expression that is to be used for type analysis.
   * @param expression the expression whose type is to be returned
   * @return the type of the given expression
   */
  Type2 getStaticType(Expression expression) {
    if (expression is NullLiteral) {
      return _resolver.typeProvider.objectType;
    }
    Type2 staticType = resolveTypeVariable(expression.staticType);
    if (staticType is FunctionType) {
      staticType = _resolver.typeProvider.functionType;
    }
    return staticType;
  }

  /**
   * Return the element representing the superclass of the given class.
   * @param targetClass the class whose superclass is to be returned
   * @return the element representing the superclass of the given class
   */
  ClassElement getSuperclass(ClassElement targetClass) {
    InterfaceType superType = targetClass.supertype;
    if (superType == null) {
      return null;
    }
    return superType.element;
  }

  /**
   * Return {@code true} if the given type represents an object that could be invoked using the call
   * operator '()'.
   * @param type the type being tested
   * @return {@code true} if the given type represents an object that could be invoked
   */
  bool isExecutableType(Type2 type) {
    if (type.isDynamic() || (type is FunctionType) || type.isDartCoreFunction()) {
      return true;
    } else if (type is InterfaceType) {
      ClassElement classElement = ((type as InterfaceType)).element;
      MethodElement methodElement = classElement.lookUpMethod(CALL_METHOD_NAME, _resolver.definingLibrary);
      return methodElement != null;
    }
    return false;
  }

  /**
   * Return {@code true} if the given element is a static element.
   * @param element the element being tested
   * @return {@code true} if the given element is a static element
   */
  bool isStatic(Element element) {
    if (element is ExecutableElement) {
      return ((element as ExecutableElement)).isStatic();
    } else if (element is PropertyInducingElement) {
      return ((element as PropertyInducingElement)).isStatic();
    }
    return false;
  }

  /**
   * Looks up the method element with the given name for index expression, reports{@link StaticWarningCode#UNDEFINED_OPERATOR} if not found.
   * @param node the index expression to resolve
   * @param target the target of the expression
   * @param methodName the name of the operator associated with the context of using of the given
   * index expression
   * @return {@code true} if and only if an error code is generated on the passed node
   */
  bool lookUpCheckIndexOperator(IndexExpression node, Expression target, String methodName, Type2 staticType, Type2 propagatedType) {
    MethodElement staticMethod = lookUpMethod(target, staticType, methodName);
    MethodElement propagatedMethod = lookUpMethod(target, propagatedType, methodName);
    node.staticElement = staticMethod;
    node.element = select3(staticMethod, propagatedMethod);
    if (shouldReportMissingMember(staticType, staticMethod) && (_strictMode || propagatedType == null || shouldReportMissingMember(propagatedType, propagatedMethod))) {
      sc.Token leftBracket = node.leftBracket;
      sc.Token rightBracket = node.rightBracket;
      if (leftBracket == null || rightBracket == null) {
        _resolver.reportError(StaticTypeWarningCode.UNDEFINED_OPERATOR, node, [methodName, staticType.displayName]);
        return true;
      } else {
        int offset = leftBracket.offset;
        int length = rightBracket.offset - offset + 1;
        _resolver.reportError5(StaticTypeWarningCode.UNDEFINED_OPERATOR, offset, length, [methodName, staticType.displayName]);
        return true;
      }
    }
    return false;
  }

  /**
   * Look up the getter with the given name in the given type. Return the element representing the
   * getter that was found, or {@code null} if there is no getter with the given name.
   * @param target the target of the invocation, or {@code null} if there is no target
   * @param type the type in which the getter is defined
   * @param getterName the name of the getter being looked up
   * @return the element representing the getter that was found
   */
  PropertyAccessorElement lookUpGetter(Expression target, Type2 type, String getterName) {
    type = resolveTypeVariable(type);
    if (type is InterfaceType) {
      InterfaceType interfaceType = type as InterfaceType;
      PropertyAccessorElement accessor;
      if (target is SuperExpression) {
        accessor = interfaceType.lookUpGetterInSuperclass(getterName, _resolver.definingLibrary);
      } else {
        accessor = interfaceType.lookUpGetter(getterName, _resolver.definingLibrary);
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
   * directly or indirectly. Return the element representing the getter that was found, or{@code null} if there is no getter with the given name.
   * @param targetType the type in which the getter might be defined
   * @param includeTargetType {@code true} if the search should include the target type
   * @param getterName the name of the getter being looked up
   * @param visitedInterfaces a set containing all of the interfaces that have been examined, used
   * to prevent infinite recursion and to optimize the search
   * @return the element representing the getter that was found
   */
  PropertyAccessorElement lookUpGetterInInterfaces(InterfaceType targetType, bool includeTargetType, String getterName, Set<ClassElement> visitedInterfaces) {
    ClassElement targetClass = targetType.element;
    if (visitedInterfaces.contains(targetClass)) {
      return null;
    }
    javaSetAdd(visitedInterfaces, targetClass);
    if (includeTargetType) {
      PropertyAccessorElement getter = targetType.getGetter(getterName);
      if (getter != null) {
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
   * representing the method or getter that was found, or {@code null} if there is no method or
   * getter with the given name.
   * @param type the type in which the method or getter is defined
   * @param memberName the name of the method or getter being looked up
   * @return the element representing the method or getter that was found
   */
  ExecutableElement lookupGetterOrMethod(Type2 type, String memberName) {
    type = resolveTypeVariable(type);
    if (type is InterfaceType) {
      InterfaceType interfaceType = type as InterfaceType;
      ExecutableElement member = interfaceType.lookUpMethod(memberName, _resolver.definingLibrary);
      if (member != null) {
        return member;
      }
      member = interfaceType.lookUpGetter(memberName, _resolver.definingLibrary);
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
   * was found, or {@code null} if there is no method or getter with the given name.
   * @param targetType the type in which the method or getter might be defined
   * @param includeTargetType {@code true} if the search should include the target type
   * @param memberName the name of the method or getter being looked up
   * @param visitedInterfaces a set containing all of the interfaces that have been examined, used
   * to prevent infinite recursion and to optimize the search
   * @return the element representing the method or getter that was found
   */
  ExecutableElement lookUpGetterOrMethodInInterfaces(InterfaceType targetType, bool includeTargetType, String memberName, Set<ClassElement> visitedInterfaces) {
    ClassElement targetClass = targetType.element;
    if (visitedInterfaces.contains(targetClass)) {
      return null;
    }
    javaSetAdd(visitedInterfaces, targetClass);
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
   * @param parentNode the node containing the given label
   * @param labelNode the node representing the label being looked up
   * @return the element corresponding to the given label node in the current scope
   */
  LabelElementImpl lookupLabel(ASTNode parentNode, SimpleIdentifier labelNode) {
    LabelScope labelScope = _resolver.labelScope;
    LabelElementImpl labelElement = null;
    if (labelNode == null) {
      if (labelScope == null) {
      } else {
        labelElement = labelScope.lookup2(LabelScope.EMPTY_LABEL) as LabelElementImpl;
        if (labelElement == null) {
        }
        labelElement = null;
      }
    } else {
      if (labelScope == null) {
        _resolver.reportError(CompileTimeErrorCode.LABEL_UNDEFINED, labelNode, [labelNode.name]);
      } else {
        labelElement = labelScope.lookup(labelNode) as LabelElementImpl;
        if (labelElement == null) {
          _resolver.reportError(CompileTimeErrorCode.LABEL_UNDEFINED, labelNode, [labelNode.name]);
        } else {
          recordResolution(labelNode, labelElement);
        }
      }
    }
    if (labelElement != null) {
      ExecutableElement labelContainer = labelElement.getAncestor(ExecutableElement);
      if (labelContainer != _resolver.enclosingFunction) {
        _resolver.reportError(CompileTimeErrorCode.LABEL_IN_OUTER_SCOPE, labelNode, [labelNode.name]);
        labelElement = null;
      }
    }
    return labelElement;
  }

  /**
   * Look up the method with the given name in the given type. Return the element representing the
   * method that was found, or {@code null} if there is no method with the given name.
   * @param target the target of the invocation, or {@code null} if there is no target
   * @param type the type in which the method is defined
   * @param methodName the name of the method being looked up
   * @return the element representing the method that was found
   */
  MethodElement lookUpMethod(Expression target, Type2 type, String methodName) {
    type = resolveTypeVariable(type);
    if (type is InterfaceType) {
      InterfaceType interfaceType = type as InterfaceType;
      MethodElement method;
      if (target is SuperExpression) {
        method = interfaceType.lookUpMethodInSuperclass(methodName, _resolver.definingLibrary);
      } else {
        method = interfaceType.lookUpMethod(methodName, _resolver.definingLibrary);
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
   * directly or indirectly. Return the element representing the method that was found, or{@code null} if there is no method with the given name.
   * @param targetType the type in which the member might be defined
   * @param includeTargetType {@code true} if the search should include the target type
   * @param methodName the name of the method being looked up
   * @param visitedInterfaces a set containing all of the interfaces that have been examined, used
   * to prevent infinite recursion and to optimize the search
   * @return the element representing the method that was found
   */
  MethodElement lookUpMethodInInterfaces(InterfaceType targetType, bool includeTargetType, String methodName, Set<ClassElement> visitedInterfaces) {
    ClassElement targetClass = targetType.element;
    if (visitedInterfaces.contains(targetClass)) {
      return null;
    }
    javaSetAdd(visitedInterfaces, targetClass);
    if (includeTargetType) {
      MethodElement method = targetType.getMethod(methodName);
      if (method != null) {
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
   * setter that was found, or {@code null} if there is no setter with the given name.
   * @param target the target of the invocation, or {@code null} if there is no target
   * @param type the type in which the setter is defined
   * @param setterName the name of the setter being looked up
   * @return the element representing the setter that was found
   */
  PropertyAccessorElement lookUpSetter(Expression target, Type2 type, String setterName) {
    type = resolveTypeVariable(type);
    if (type is InterfaceType) {
      InterfaceType interfaceType = type as InterfaceType;
      PropertyAccessorElement accessor;
      if (target is SuperExpression) {
        accessor = interfaceType.lookUpSetterInSuperclass(setterName, _resolver.definingLibrary);
      } else {
        accessor = interfaceType.lookUpSetter(setterName, _resolver.definingLibrary);
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
   * directly or indirectly. Return the element representing the setter that was found, or{@code null} if there is no setter with the given name.
   * @param targetType the type in which the setter might be defined
   * @param includeTargetType {@code true} if the search should include the target type
   * @param setterName the name of the setter being looked up
   * @param visitedInterfaces a set containing all of the interfaces that have been examined, used
   * to prevent infinite recursion and to optimize the search
   * @return the element representing the setter that was found
   */
  PropertyAccessorElement lookUpSetterInInterfaces(InterfaceType targetType, bool includeTargetType, String setterName, Set<ClassElement> visitedInterfaces) {
    ClassElement targetClass = targetType.element;
    if (visitedInterfaces.contains(targetClass)) {
      return null;
    }
    javaSetAdd(visitedInterfaces, targetClass);
    if (includeTargetType) {
      PropertyAccessorElement setter = targetType.getSetter(setterName);
      if (setter != null) {
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
   * Return the binary operator that is invoked by the given compound assignment operator.
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
      }
      break;
    }
    AnalysisEngine.instance.logger.logError("Failed to map ${operator.lexeme} to it's corresponding operator");
    return operator;
  }

  /**
   * Record the fact that the given AST node was resolved to the given element.
   * @param node the AST node that was resolved
   * @param element the element to which the AST node was resolved
   */
  void recordResolution(SimpleIdentifier node, Element element2) {
    node.staticElement = element2;
    node.element = element2;
  }

  /**
   * Record the fact that the given AST node was resolved to the given elements.
   * @param node the AST node that was resolved
   * @param staticElement the element to which the AST node was resolved using static type
   * information
   * @param propagatedElement the element to which the AST node was resolved using propagated type
   * information
   * @return the element that was associated with the node
   */
  void recordResolution2(SimpleIdentifier node, Element staticElement2, Element propagatedElement) {
    node.staticElement = staticElement2;
    node.element = propagatedElement == null ? staticElement2 : propagatedElement;
  }

  /**
   * Given a list of arguments and the element that will be invoked using those argument, compute
   * the list of parameters that correspond to the list of arguments. Return the parameters that
   * correspond to the arguments, or {@code null} if no correspondence could be computed.
   * @param reportError if {@code true} then compile-time error should be reported; if {@code false}then compile-time warning
   * @param argumentList the list of arguments being passed to the element
   * @param executableElement the element that will be invoked with the arguments
   * @return the parameters that correspond to the arguments
   */
  List<ParameterElement> resolveArgumentsToParameters(bool reportError, ArgumentList argumentList, ExecutableElement executableElement) {
    if (executableElement == null) {
      return null;
    }
    List<ParameterElement> parameters = executableElement.parameters;
    return resolveArgumentsToParameters2(reportError, argumentList, parameters);
  }

  /**
   * Given a list of arguments and the parameters related to the element that will be invoked using
   * those argument, compute the list of parameters that correspond to the list of arguments. Return
   * the parameters that correspond to the arguments.
   * @param reportError if {@code true} then compile-time error should be reported; if {@code false}then compile-time warning
   * @param argumentList the list of arguments being passed to the element
   * @param parameters the of the function that will be invoked with the arguments
   * @return the parameters that correspond to the arguments
   */
  List<ParameterElement> resolveArgumentsToParameters2(bool reportError2, ArgumentList argumentList, List<ParameterElement> parameters) {
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
        SimpleIdentifier nameNode = ((argument as NamedExpression)).name.label;
        String name = nameNode.name;
        ParameterElement element = namedParameters[name];
        if (element == null) {
          ErrorCode errorCode = reportError2 ? CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER : StaticWarningCode.UNDEFINED_NAMED_PARAMETER;
          _resolver.reportError(errorCode, nameNode, [name]);
        } else {
          resolvedParameters[i] = element;
          recordResolution(nameNode, element);
        }
        if (!javaSetAdd(usedNames, name)) {
          _resolver.reportError(CompileTimeErrorCode.DUPLICATE_NAMED_ARGUMENT, nameNode, [name]);
        }
      } else {
        positionalArgumentCount++;
        if (unnamedIndex < unnamedParameterCount) {
          resolvedParameters[i] = unnamedParameters[unnamedIndex++];
        }
      }
    }
    if (positionalArgumentCount < requiredParameters.length) {
      ErrorCode errorCode = reportError2 ? CompileTimeErrorCode.NOT_ENOUGH_REQUIRED_ARGUMENTS : StaticWarningCode.NOT_ENOUGH_REQUIRED_ARGUMENTS;
      _resolver.reportError(errorCode, argumentList, [requiredParameters.length, positionalArgumentCount]);
    } else if (positionalArgumentCount > unnamedParameterCount) {
      ErrorCode errorCode = reportError2 ? CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS : StaticWarningCode.EXTRA_POSITIONAL_ARGUMENTS;
      _resolver.reportError(errorCode, argumentList, [unnamedParameterCount, positionalArgumentCount]);
    }
    return resolvedParameters;
  }

  /**
   * Resolve the names in the given combinators in the scope of the given library.
   * @param library the library that defines the names
   * @param combinators the combinators containing the names to be resolved
   */
  void resolveCombinators(LibraryElement library, NodeList<Combinator> combinators) {
    if (library == null) {
      return;
    }
    Namespace namespace = new NamespaceBuilder().createExportNamespace2(library);
    for (Combinator combinator in combinators) {
      NodeList<SimpleIdentifier> names;
      if (combinator is HideCombinator) {
        names = ((combinator as HideCombinator)).hiddenNames;
      } else {
        names = ((combinator as ShowCombinator)).shownNames;
      }
      for (SimpleIdentifier name in names) {
        Element element = namespace.get(name.name);
        if (element != null) {
          name.element = element;
        }
      }
    }
  }

  /**
   * Given an invocation of the form 'e.m(a1, ..., an)', resolve 'e.m' to the element being invoked.
   * If the returned element is a method, then the method will be invoked. If the returned element
   * is a getter, the getter will be invoked without arguments and the result of that invocation
   * will then be invoked with the arguments.
   * @param target the target of the invocation ('e')
   * @param targetType the type of the target
   * @param methodName the name of the method being invoked ('m')
   * @return the element being invoked
   */
  Element resolveInvokedElement(Expression target, Type2 targetType, SimpleIdentifier methodName) {
    if (targetType is InterfaceType) {
      InterfaceType classType = targetType as InterfaceType;
      Element element = lookUpMethod(target, classType, methodName.name);
      if (element == null) {
        element = classType.getGetter(methodName.name);
      }
      return element;
    } else if (target is SimpleIdentifier) {
      Element targetElement = ((target as SimpleIdentifier)).element;
      if (targetElement is PrefixElement) {
        String name = "${((target as SimpleIdentifier)).name}.${methodName}";
        Identifier functionName = new ElementResolver_SyntheticIdentifier(name);
        Element element = _resolver.nameScope.lookup(functionName, _resolver.definingLibrary);
        if (element != null) {
          return element;
        }
      }
    }
    return null;
  }

  /**
   * Given an invocation of the form 'm(a1, ..., an)', resolve 'm' to the element being invoked. If
   * the returned element is a method, then the method will be invoked. If the returned element is a
   * getter, the getter will be invoked without arguments and the result of that invocation will
   * then be invoked with the arguments.
   * @param methodName the name of the method being invoked ('m')
   * @return the element being invoked
   */
  Element resolveInvokedElement2(SimpleIdentifier methodName) {
    Element element = _resolver.nameScope.lookup(methodName, _resolver.definingLibrary);
    if (element == null) {
      ClassElement enclosingClass = _resolver.enclosingClass;
      if (enclosingClass != null) {
        InterfaceType enclosingType = enclosingClass.type;
        element = lookUpMethod(null, enclosingType, methodName.name);
        if (element == null) {
          element = lookUpGetter(null, enclosingType, methodName.name);
        }
      }
    }
    return element;
  }

  /**
   * Given that we are accessing a property of the given type with the given name, return the
   * element that represents the property.
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
    ExecutableElement staticElement = resolveProperty(target, staticType, propertyName);
    propertyName.staticElement = staticElement;
    Type2 propagatedType = getPropagatedType(target);
    ExecutableElement propagatedElement = resolveProperty(target, propagatedType, propertyName);
    Element selectedElement = select2(staticElement, propagatedElement);
    propertyName.element = selectedElement;
    if (shouldReportMissingMember(staticType, staticElement) && (_strictMode || propagatedType == null || shouldReportMissingMember(propagatedType, propagatedElement))) {
      bool staticNoSuchMethod = staticType != null && classDeclaresNoSuchMethod2(staticType.element);
      bool propagatedNoSuchMethod = propagatedType != null && classDeclaresNoSuchMethod2(propagatedType.element);
      if (!staticNoSuchMethod && (_strictMode || !propagatedNoSuchMethod)) {
        bool isStaticProperty = isStatic(selectedElement);
        if (propertyName.inSetterContext()) {
          if (isStaticProperty) {
            _resolver.reportError(StaticWarningCode.UNDEFINED_SETTER, propertyName, [propertyName.name, staticType.displayName]);
          } else {
            _resolver.reportError(StaticTypeWarningCode.UNDEFINED_SETTER, propertyName, [propertyName.name, staticType.displayName]);
          }
        } else if (propertyName.inGetterContext()) {
          if (isStaticProperty) {
            _resolver.reportError(StaticWarningCode.UNDEFINED_GETTER, propertyName, [propertyName.name, staticType.displayName]);
          } else {
            _resolver.reportError(StaticTypeWarningCode.UNDEFINED_GETTER, propertyName, [propertyName.name, staticType.displayName]);
          }
        } else {
          _resolver.reportError(StaticWarningCode.UNDEFINED_IDENTIFIER, propertyName, [propertyName.name]);
        }
      }
    }
  }

  /**
   * Resolve the given simple identifier if possible. Return the element to which it could be
   * resolved, or {@code null} if it could not be resolved. This does not record the results of the
   * resolution.
   * @param node the identifier to be resolved
   * @return the element to which the identifier could be resolved
   */
  Element resolveSimpleIdentifier(SimpleIdentifier node) {
    Element element = _resolver.nameScope.lookup(node, _resolver.definingLibrary);
    if (element is PropertyAccessorElement && node.inSetterContext()) {
      PropertyInducingElement variable = ((element as PropertyAccessorElement)).variable;
      if (variable != null) {
        PropertyAccessorElement setter = variable.setter;
        if (setter == null) {
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
      element = _resolver.nameScope.lookup(new ElementResolver_SyntheticIdentifier("${node.name}="), _resolver.definingLibrary);
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
   * If the given type is a type variable, resolve it to the type that should be used when looking
   * up members. Otherwise, return the original type.
   * @param type the type that is to be resolved if it is a type variable
   * @return the type that should be used in place of the argument if it is a type variable, or the
   * original argument if it isn't a type variable
   */
  Type2 resolveTypeVariable(Type2 type) {
    if (type is TypeVariableType) {
      Type2 bound = ((type as TypeVariableType)).element.bound;
      if (bound == null) {
        return _resolver.typeProvider.objectType;
      }
      return bound;
    }
    return type;
  }

  /**
   * Given two possible error codes for the same piece of code, one computed using static type
   * information and the other using propagated type information, return the error code that should
   * be reported, or {@code null} if no error should be reported.
   * @param staticError the error code computed using static type information
   * @param propagatedError the error code computed using propagated type information
   * @return the error code that should be reported
   */
  ErrorCode select(ErrorCode staticError, ErrorCode propagatedError) {
    if (staticError == null || propagatedError == null) {
      return null;
    }
    return propagatedError;
  }

  /**
   * Return the propagated element if it is not {@code null}, or the static element if it is.
   * @param staticElement the element computed using static type information
   * @param propagatedElement the element computed using propagated type information
   * @return the more specific of the two elements
   */
  ExecutableElement select2(ExecutableElement staticElement, ExecutableElement propagatedElement) => propagatedElement != null ? propagatedElement : staticElement;

  /**
   * Return the propagated method if it is not {@code null}, or the static method if it is.
   * @param staticMethod the method computed using static type information
   * @param propagatedMethod the method computed using propagated type information
   * @return the more specific of the two methods
   */
  MethodElement select3(MethodElement staticMethod, MethodElement propagatedMethod) => propagatedMethod != null ? propagatedMethod : staticMethod;

  /**
   * Given a node that can have annotations associated with it and the element to which that node
   * has been resolved, create the annotations in the element model representing the annotations on
   * the node.
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
      ((element as ElementImpl)).metadata = new List.from(annotationList);
    }
  }

  /**
   * Return {@code true} if we should report an error as a result of looking up a member in the
   * given type and not finding any member.
   * @param type the type in which we attempted to perform the look-up
   * @param member the result of the look-up
   * @return {@code true} if we should report an error
   */
  bool shouldReportMissingMember(Type2 type, ExecutableElement member) {
    if (member != null || type == null || type.isDynamic()) {
      return false;
    }
    if (type is InterfaceType) {
      return !classDeclaresNoSuchMethod(((type as InterfaceType)).element);
    }
    return true;
  }
}
/**
 * Instances of the class {@code SyntheticIdentifier} implement an identifier that can be used to
 * look up names in the lexical scope when there is no identifier in the AST structure. There is
 * no identifier in the AST when the parser could not distinguish between a method invocation and
 * an invocation of a top-level function imported with a prefix.
 */
class ElementResolver_SyntheticIdentifier extends Identifier {

  /**
   * The name of the synthetic identifier.
   */
  String _name;

  /**
   * Initialize a newly created synthetic identifier to have the given name.
   * @param name the name of the synthetic identifier
   */
  ElementResolver_SyntheticIdentifier(String name) {
    this._name = name;
  }
  accept(ASTVisitor visitor) => null;
  sc.Token get beginToken => null;
  Element get element => null;
  sc.Token get endToken => null;
  String get name => _name;
  Element get staticElement => null;
  void visitChildren(ASTVisitor<Object> visitor) {
  }
}
/**
 * Instances of the class {@code InheritanceManager} manage the knowledge of where class members
 * (methods, getters & setters) are inherited from.
 * @coverage dart.engine.resolver
 */
class InheritanceManager {

  /**
   * The {@link LibraryElement} that is managed by this manager.
   */
  LibraryElement _library;

  /**
   * This is a mapping between each {@link ClassElement} and a map between the {@link String} member
   * names and the associated {@link ExecutableElement} in the mixin and superclass chain.
   */
  Map<ClassElement, Map<String, ExecutableElement>> _classLookup;

  /**
   * This is a mapping between each {@link ClassElement} and a map between the {@link String} member
   * names and the associated {@link ExecutableElement} in the interface set.
   */
  Map<ClassElement, Map<String, ExecutableElement>> _interfaceLookup;

  /**
   * A map between each visited {@link ClassElement} and the set of {@link AnalysisError}s found on
   * the class element.
   */
  Map<ClassElement, Set<AnalysisError>> _errorsInClassElement = new Map<ClassElement, Set<AnalysisError>>();

  /**
   * Initialize a newly created inheritance manager.
   * @param library the library element context that the inheritance mappings are being generated
   */
  InheritanceManager(LibraryElement library) {
    this._library = library;
    _classLookup = new Map<ClassElement, Map<String, ExecutableElement>>();
    _interfaceLookup = new Map<ClassElement, Map<String, ExecutableElement>>();
  }

  /**
   * Return the set of {@link AnalysisError}s found on the passed {@link ClassElement}, or{@code null} if there are none.
   * @param classElt the class element to query
   * @return the set of {@link AnalysisError}s found on the passed {@link ClassElement}, or{@code null} if there are none
   */
  Set<AnalysisError> getErrors(ClassElement classElt) => _errorsInClassElement[classElt];

  /**
   * Get and return a mapping between the set of all string names of the members inherited from the
   * passed {@link ClassElement} superclass hierarchy, and the associated {@link ExecutableElement}.
   * @param classElt the class element to query
   * @return a mapping between the set of all members inherited from the passed {@link ClassElement}superclass hierarchy, and the associated {@link ExecutableElement}
   */
  Map<String, ExecutableElement> getMapOfMembersInheritedFromClasses(ClassElement classElt) => computeClassChainLookupMap(classElt, new Set<ClassElement>());

  /**
   * Get and return a mapping between the set of all string names of the members inherited from the
   * passed {@link ClassElement} interface hierarchy, and the associated {@link ExecutableElement}.
   * @param classElt the class element to query
   * @return a mapping between the set of all string names of the members inherited from the passed{@link ClassElement} interface hierarchy, and the associated {@link ExecutableElement}.
   */
  Map<String, ExecutableElement> getMapOfMembersInheritedFromInterfaces(ClassElement classElt) => computeInterfaceLookupMap(classElt, new Set<ClassElement>());

  /**
   * Given some {@link ClassElement class element} and some member name, this returns the{@link ExecutableElement executable element} that the class inherits from the mixins,
   * superclasses or interfaces, that has the member name, if no member is inherited {@code null} is
   * returned.
   * @param classElt the class element to query
   * @param memberName the name of the executable element to find and return
   * @return the inherited executable element with the member name, or {@code null} if no such
   * member exists
   */
  ExecutableElement lookupInheritance(ClassElement classElt, String memberName) {
    if (memberName == null || memberName.isEmpty) {
      return null;
    }
    ExecutableElement executable = computeClassChainLookupMap(classElt, new Set<ClassElement>())[memberName];
    if (executable == null) {
      return computeInterfaceLookupMap(classElt, new Set<ClassElement>())[memberName];
    }
    return executable;
  }

  /**
   * Given some {@link ClassElement class element} and some member name, this returns the{@link ExecutableElement executable element} that the class either declares itself, or
   * inherits, that has the member name, if no member is inherited {@code null} is returned.
   * @param classElt the class element to query
   * @param memberName the name of the executable element to find and return
   * @return the inherited executable element with the member name, or {@code null} if no such
   * member exists
   */
  ExecutableElement lookupMember(ClassElement classElt, String memberName) {
    ExecutableElement element = lookupMemberInClass(classElt, memberName);
    if (element != null) {
      return element;
    }
    return lookupInheritance(classElt, memberName);
  }

  /**
   * Set the new library element context.
   * @param library the new library element
   */
  void set libraryElement(LibraryElement library2) {
    this._library = library2;
  }

  /**
   * This method takes some inherited {@link FunctionType}, and resolves all the parameterized types
   * in the function type, dependent on the class in which it is being overridden.
   * @param baseFunctionType the function type that is being overridden
   * @param memberName the name of the member, this is used to lookup the inheritance path of the
   * override
   * @param definingType the type that is overriding the member
   * @return the passed function type with any parameterized types substituted
   */
  FunctionType substituteTypeArgumentsInMemberFromInheritance(FunctionType baseFunctionType, String memberName, InterfaceType definingType) {
    if (baseFunctionType == null) {
      return baseFunctionType;
    }
    Queue<InterfaceType> inheritancePath = new Queue<InterfaceType>();
    computeInheritancePath(inheritancePath, definingType, memberName);
    if (inheritancePath == null || inheritancePath.length < 2) {
      return baseFunctionType;
    }
    FunctionType functionTypeToReturn = baseFunctionType;
    InterfaceType lastType = inheritancePath.removeLast();
    while (inheritancePath.length > 0) {
      List<Type2> paramTypes = TypeVariableTypeImpl.getTypes(lastType.element.typeVariables);
      List<Type2> argTypes = lastType.typeArguments;
      functionTypeToReturn = functionTypeToReturn.substitute2(argTypes, paramTypes);
      lastType = inheritancePath.removeLast();
    }
    return functionTypeToReturn;
  }

  /**
   * Compute and return a mapping between the set of all string names of the members inherited from
   * the passed {@link ClassElement} superclass hierarchy, and the associated{@link ExecutableElement}.
   * @param classElt the class element to query
   * @param visitedClasses a set of visited classes passed back into this method when it calls
   * itself recursively
   * @return a mapping between the set of all string names of the members inherited from the passed{@link ClassElement} superclass hierarchy, and the associated {@link ExecutableElement}
   */
  Map<String, ExecutableElement> computeClassChainLookupMap(ClassElement classElt, Set<ClassElement> visitedClasses) {
    Map<String, ExecutableElement> resultMap = _classLookup[classElt];
    if (resultMap != null) {
      return resultMap;
    } else {
      resultMap = new Map<String, ExecutableElement>();
    }
    ClassElement superclassElt = null;
    InterfaceType supertype = classElt.supertype;
    if (supertype != null) {
      superclassElt = supertype.element;
    } else {
      _classLookup[classElt] = resultMap;
      return resultMap;
    }
    if (superclassElt != null) {
      if (!visitedClasses.contains(superclassElt)) {
        javaSetAdd(visitedClasses, classElt);
        resultMap = new Map<String, ExecutableElement>.from(computeClassChainLookupMap(superclassElt, visitedClasses));
      } else {
        _classLookup[superclassElt] = resultMap;
        return resultMap;
      }
      recordMapWithClassMembers(resultMap, superclassElt);
    }
    List<InterfaceType> mixins = classElt.mixins;
    for (int i = mixins.length - 1; i >= 0; i--) {
      ClassElement mixinElement = mixins[i].element;
      if (mixinElement != null) {
        recordMapWithClassMembers(resultMap, mixinElement);
      }
    }
    _classLookup[classElt] = resultMap;
    return resultMap;
  }

  /**
   * Compute and return the inheritance path given the context of a type and a member that is
   * overridden in the inheritance path (for which the type is in the path).
   * @param chain the inheritance path that is built up as this method calls itself recursively,
   * when this method is called an empty {@link LinkedList} should be provided
   * @param currentType the current type in the inheritance path
   * @param memberName the name of the member that is being looked up the inheritance path
   */
  void computeInheritancePath(Queue<InterfaceType> chain, InterfaceType currentType, String memberName) {
    chain.add(currentType);
    ClassElement classElt = currentType.element;
    InterfaceType supertype = classElt.supertype;
    if (supertype == null) {
      return;
    }
    if (chain.length != 1) {
      if (lookupMemberInClass(classElt, memberName) != null) {
        return;
      }
    }
    List<InterfaceType> mixins = classElt.mixins;
    for (int i = mixins.length - 1; i >= 0; i--) {
      ClassElement mixinElement = mixins[i].element;
      if (mixinElement != null) {
        ExecutableElement elt = lookupMemberInClass(mixinElement, memberName);
        if (elt != null) {
          chain.add(mixins[i]);
          return;
        }
      }
    }
    ClassElement superclassElt = supertype.element;
    if (lookupMember(superclassElt, memberName) != null) {
      computeInheritancePath(chain, supertype, memberName);
      return;
    }
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
   * the passed {@link ClassElement} interface hierarchy, and the associated{@link ExecutableElement}.
   * @param classElt the class element to query
   * @param visitedInterfaces a set of visited classes passed back into this method when it calls
   * itself recursively
   * @return a mapping between the set of all string names of the members inherited from the passed{@link ClassElement} interface hierarchy, and the associated {@link ExecutableElement}
   */
  Map<String, ExecutableElement> computeInterfaceLookupMap(ClassElement classElt, Set<ClassElement> visitedInterfaces) {
    Map<String, ExecutableElement> resultMap = _interfaceLookup[classElt];
    if (resultMap != null) {
      return resultMap;
    } else {
      resultMap = new Map<String, ExecutableElement>();
    }
    InterfaceType supertype = classElt.supertype;
    ClassElement superclassElement = supertype != null ? supertype.element : null;
    List<InterfaceType> interfaces = classElt.interfaces;
    if (superclassElement == null || interfaces.length == 0) {
      _interfaceLookup[classElt] = resultMap;
      return resultMap;
    }
    List<Map<String, ExecutableElement>> lookupMaps = new List<Map<String, ExecutableElement>>();
    if (superclassElement != null) {
      if (!visitedInterfaces.contains(superclassElement)) {
        try {
          javaSetAdd(visitedInterfaces, superclassElement);
          lookupMaps.add(computeInterfaceLookupMap(superclassElement, visitedInterfaces));
        } finally {
          visitedInterfaces.remove(superclassElement);
        }
      } else {
        Map<String, ExecutableElement> map = _interfaceLookup[classElt];
        if (map != null) {
          lookupMaps.add(map);
        } else {
          _interfaceLookup[superclassElement] = resultMap;
          return resultMap;
        }
      }
    }
    for (InterfaceType interfaceType in interfaces) {
      ClassElement interfaceElement = interfaceType.element;
      if (interfaceElement != null) {
        if (!visitedInterfaces.contains(interfaceElement)) {
          try {
            javaSetAdd(visitedInterfaces, interfaceElement);
            lookupMaps.add(computeInterfaceLookupMap(interfaceElement, visitedInterfaces));
          } finally {
            visitedInterfaces.remove(interfaceElement);
          }
        } else {
          Map<String, ExecutableElement> map = _interfaceLookup[classElt];
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
    Map<String, Set<ExecutableElement>> unionMap = new Map<String, Set<ExecutableElement>>();
    for (Map<String, ExecutableElement> lookupMap in lookupMaps) {
      for (MapEntry<String, ExecutableElement> entry in getMapEntrySet(lookupMap)) {
        String key = entry.getKey();
        if (!unionMap.containsKey(key)) {
          Set<ExecutableElement> set = new Set<ExecutableElement>();
          javaSetAdd(set, entry.getValue());
          unionMap[key] = set;
        } else {
          javaSetAdd(unionMap[key], entry.getValue());
        }
      }
    }
    if (superclassElement != null) {
      List<MethodElement> methods = superclassElement.methods;
      for (MethodElement method in methods) {
        if (method.isAccessibleIn(_library) && !method.isStatic()) {
          String key = method.name;
          if (!unionMap.containsKey(key)) {
            Set<ExecutableElement> set = new Set<ExecutableElement>();
            javaSetAdd(set, method);
            unionMap[key] = set;
          } else {
            javaSetAdd(unionMap[key], method);
          }
        }
      }
      List<PropertyAccessorElement> accessors = superclassElement.accessors;
      for (PropertyAccessorElement accessor in accessors) {
        if (accessor.isAccessibleIn(_library) && !accessor.isStatic()) {
          String key = accessor.name;
          if (!unionMap.containsKey(key)) {
            Set<ExecutableElement> set = new Set<ExecutableElement>();
            javaSetAdd(set, accessor);
            unionMap[key] = set;
          } else {
            javaSetAdd(unionMap[key], accessor);
          }
        }
      }
    }
    for (InterfaceType interfaceType in interfaces) {
      ClassElement interfaceElement = interfaceType.element;
      if (interfaceElement != null) {
        List<MethodElement> methods = interfaceElement.methods;
        for (MethodElement method in methods) {
          if (method.isAccessibleIn(_library) && !method.isStatic()) {
            String key = method.name;
            if (!unionMap.containsKey(key)) {
              Set<ExecutableElement> set = new Set<ExecutableElement>();
              javaSetAdd(set, method);
              unionMap[key] = set;
            } else {
              javaSetAdd(unionMap[key], method);
            }
          }
        }
        List<PropertyAccessorElement> accessors = interfaceElement.accessors;
        for (PropertyAccessorElement accessor in accessors) {
          if (accessor.isAccessibleIn(_library) && !accessor.isStatic()) {
            String key = accessor.name;
            if (!unionMap.containsKey(key)) {
              Set<ExecutableElement> set = new Set<ExecutableElement>();
              javaSetAdd(set, accessor);
              unionMap[key] = set;
            } else {
              javaSetAdd(unionMap[key], accessor);
            }
          }
        }
      }
    }
    for (MapEntry<String, Set<ExecutableElement>> entry in getMapEntrySet(unionMap)) {
      String key = entry.getKey();
      Set<ExecutableElement> set = entry.getValue();
      int numOfEltsWithMatchingNames = set.length;
      if (numOfEltsWithMatchingNames == 1) {
        resultMap[key] = new JavaIterator(set).next();
      } else {
        bool allMethods = true;
        bool allSetters = true;
        bool allGetters = true;
        for (ExecutableElement executableElement in set) {
          if (executableElement is PropertyAccessorElement) {
            allMethods = false;
            if (((executableElement as PropertyAccessorElement)).isSetter()) {
              allGetters = false;
            } else {
              allSetters = false;
            }
          } else {
            allGetters = false;
            allSetters = false;
          }
        }
        if (allMethods || allGetters || allSetters) {
          List<ExecutableElement> elements = new List.from(set);
          List<FunctionType> executableElementTypes = new List<FunctionType>(numOfEltsWithMatchingNames);
          for (int i = 0; i < numOfEltsWithMatchingNames; i++) {
            executableElementTypes[i] = elements[i].type;
          }
          bool foundSubtypeOfAllTypes = false;
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
              foundSubtypeOfAllTypes = true;
              resultMap[key] = elements[i];
              break;
            }
          }
          if (!foundSubtypeOfAllTypes) {
            reportError(classElt, classElt.nameOffset, classElt.displayName.length, StaticTypeWarningCode.INCONSISTENT_METHOD_INHERITANCE, [key]);
          }
        } else {
          if (!allMethods && !allGetters) {
            reportError(classElt, classElt.nameOffset, classElt.displayName.length, StaticWarningCode.INCONSISTENT_METHOD_INHERITANCE_GETTER_AND_METHOD, [key]);
          }
          resultMap.remove(entry.getKey());
        }
      }
    }
    _interfaceLookup[classElt] = resultMap;
    return resultMap;
  }

  /**
   * Given some {@link ClassElement}, this method finds and returns the {@link ExecutableElement} of
   * the passed name in the class element. Static members, members in super types and members not
   * accessible from the current library are not considered.
   * @param classElt the class element to query
   * @param memberName the name of the member to lookup in the class
   * @return the found {@link ExecutableElement}, or {@code null} if no such member was found
   */
  ExecutableElement lookupMemberInClass(ClassElement classElt, String memberName) {
    List<MethodElement> methods = classElt.methods;
    for (MethodElement method in methods) {
      if (memberName == method.name && method.isAccessibleIn(_library) && !method.isStatic()) {
        return method;
      }
    }
    List<PropertyAccessorElement> accessors = classElt.accessors;
    for (PropertyAccessorElement accessor in accessors) {
      if (memberName == accessor.name && accessor.isAccessibleIn(_library) && !accessor.isStatic()) {
        return accessor;
      }
    }
    return null;
  }

  /**
   * Record the passed map with the set of all members (methods, getters and setters) in the class
   * into the passed map.
   * @param map some non-{@code null}
   * @param classElt the class element that will be recorded into the passed map
   */
  void recordMapWithClassMembers(Map<String, ExecutableElement> map, ClassElement classElt) {
    List<MethodElement> methods = classElt.methods;
    for (MethodElement method in methods) {
      if (method.isAccessibleIn(_library) && !method.isStatic()) {
        map[method.name] = method;
      }
    }
    List<PropertyAccessorElement> accessors = classElt.accessors;
    for (PropertyAccessorElement accessor in accessors) {
      if (accessor.isAccessibleIn(_library) && !accessor.isStatic()) {
        map[accessor.name] = accessor;
      }
    }
  }

  /**
   * This method is used to report errors on when they are found computing inheritance information.
   * See {@link ErrorVerifier#checkForInconsistentMethodInheritance()} to see where these generated
   * error codes are reported back into the analysis engine.
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
    javaSetAdd(errorSet, new AnalysisError.con2(classElt.source, offset, length, errorCode, arguments));
  }
}
/**
 * Instances of the class {@code Library} represent the data about a single library during the
 * resolution of some (possibly different) library. They are not intended to be used except during
 * the resolution process.
 * @coverage dart.engine.resolver
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
  Source _librarySource;

  /**
   * The library element representing this library.
   */
  LibraryElementImpl _libraryElement;

  /**
   * A list containing all of the libraries that are imported into this library.
   */
  Map<ImportDirective, Library> _importedLibraries = new Map<ImportDirective, Library>();

  /**
   * A table mapping URI-based directive to the actual URI value.
   */
  Map<UriBasedDirective, String> _directiveUris = new Map<UriBasedDirective, String>();

  /**
   * A flag indicating whether this library explicitly imports core.
   */
  bool _explicitlyImportsCore = false;

  /**
   * A list containing all of the libraries that are exported from this library.
   */
  Map<ExportDirective, Library> _exportedLibraries = new Map<ExportDirective, Library>();

  /**
   * A table mapping the sources for the compilation units in this library to their corresponding
   * AST structures.
   */
  Map<Source, CompilationUnit> _astMap = new Map<Source, CompilationUnit>();

  /**
   * The library scope used when resolving elements within this library's compilation units.
   */
  LibraryScope _libraryScope;

  /**
   * Initialize a newly created data holder that can maintain the data associated with a library.
   * @param analysisContext the analysis context in which this library is being analyzed
   * @param errorListener the listener to which analysis errors will be reported
   * @param librarySource the source specifying the defining compilation unit of this library
   */
  Library(InternalAnalysisContext analysisContext, AnalysisErrorListener errorListener, Source librarySource) {
    this._analysisContext = analysisContext;
    this._errorListener = errorListener;
    this._librarySource = librarySource;
    this._libraryElement = analysisContext.getLibraryElement(librarySource) as LibraryElementImpl;
  }

  /**
   * Record that the given library is exported from this library.
   * @param importLibrary the library that is exported from this library
   */
  void addExport(ExportDirective directive, Library exportLibrary) {
    _exportedLibraries[directive] = exportLibrary;
  }

  /**
   * Record that the given library is imported into this library.
   * @param importLibrary the library that is imported into this library
   */
  void addImport(ImportDirective directive, Library importLibrary) {
    _importedLibraries[directive] = importLibrary;
  }

  /**
   * Return the AST structure associated with the given source.
   * @param source the source representing the compilation unit whose AST is to be returned
   * @return the AST structure associated with the given source
   * @throws AnalysisException if an AST structure could not be created for the compilation unit
   */
  CompilationUnit getAST(Source source) {
    CompilationUnit unit = _astMap[source];
    if (unit == null) {
      unit = _analysisContext.computeResolvableCompilationUnit(source);
      _astMap[source] = unit;
    }
    return unit;
  }

  /**
   * Return a collection containing the sources for the compilation units in this library, including
   * the defining compilation unit.
   * @return the sources for the compilation units in this library
   */
  Set<Source> get compilationUnitSources => _astMap.keys.toSet();

  /**
   * Return the AST structure associated with the defining compilation unit for this library.
   * @return the AST structure associated with the defining compilation unit for this library
   * @throws AnalysisException if an AST structure could not be created for the defining compilation
   * unit
   */
  CompilationUnit get definingCompilationUnit => getAST(librarySource);

  /**
   * Return {@code true} if this library explicitly imports core.
   * @return {@code true} if this library explicitly imports core
   */
  bool get explicitlyImportsCore => _explicitlyImportsCore;

  /**
   * Return the library exported by the given directive.
   * @param directive the directive that exports the library to be returned
   * @return the library exported by the given directive
   */
  Library getExport(ExportDirective directive) => _exportedLibraries[directive];

  /**
   * Return an array containing the libraries that are exported from this library.
   * @return an array containing the libraries that are exported from this library
   */
  List<Library> get exports {
    Set<Library> libraries = new Set<Library>();
    libraries.addAll(_exportedLibraries.values);
    return new List.from(libraries);
  }

  /**
   * Return the library imported by the given directive.
   * @param directive the directive that imports the library to be returned
   * @return the library imported by the given directive
   */
  Library getImport(ImportDirective directive) => _importedLibraries[directive];

  /**
   * Return an array containing the libraries that are imported into this library.
   * @return an array containing the libraries that are imported into this library
   */
  List<Library> get imports {
    Set<Library> libraries = new Set<Library>();
    libraries.addAll(_importedLibraries.values);
    return new List.from(libraries);
  }

  /**
   * Return an array containing the libraries that are either imported or exported from this
   * library.
   * @return the libraries that are either imported or exported from this library
   */
  List<Library> get importsAndExports {
    Set<Library> libraries = new Set<Library>();
    libraries.addAll(_importedLibraries.values);
    libraries.addAll(_exportedLibraries.values);
    return new List.from(libraries);
  }

  /**
   * Return the inheritance manager for this library.
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
   * @return the library element representing this library
   */
  LibraryElementImpl get libraryElement {
    if (_libraryElement == null) {
      try {
        _libraryElement = _analysisContext.computeLibraryElement(_librarySource) as LibraryElementImpl;
      } on AnalysisException catch (exception) {
        AnalysisEngine.instance.logger.logError2("Could not compute ilbrary element for ${_librarySource.fullName}", exception);
      }
    }
    return _libraryElement;
  }

  /**
   * Return the library scope used when resolving elements within this library's compilation units.
   * @return the library scope used when resolving elements within this library's compilation units
   */
  LibraryScope get libraryScope {
    if (_libraryScope == null) {
      _libraryScope = new LibraryScope(_libraryElement, _errorListener);
    }
    return _libraryScope;
  }

  /**
   * Return the source specifying the defining compilation unit of this library.
   * @return the source specifying the defining compilation unit of this library
   */
  Source get librarySource => _librarySource;

  /**
   * Return the result of resolving the URI of the given URI-based directive against the URI of the
   * library, or {@code null} if the URI is not valid. If the URI is not valid, report the error.
   * @param directive the directive which URI should be resolved
   * @return the result of resolving the URI against the URI of the library
   */
  Source getSource(UriBasedDirective directive) {
    StringLiteral uriLiteral = directive.uri;
    if (uriLiteral is StringInterpolation) {
      _errorListener.onError(new AnalysisError.con2(_librarySource, uriLiteral.offset, uriLiteral.length, CompileTimeErrorCode.URI_WITH_INTERPOLATION, []));
      return null;
    }
    String uriContent = uriLiteral.stringValue.trim();
    _directiveUris[directive] = uriContent;
    try {
      parseUriWithException(uriContent);
      Source source = getSource2(uriContent);
      if (source == null || !source.exists()) {
        _errorListener.onError(new AnalysisError.con2(_librarySource, uriLiteral.offset, uriLiteral.length, CompileTimeErrorCode.URI_DOES_NOT_EXIST, [uriContent]));
      }
      return source;
    } on URISyntaxException catch (exception) {
      _errorListener.onError(new AnalysisError.con2(_librarySource, uriLiteral.offset, uriLiteral.length, CompileTimeErrorCode.INVALID_URI, [uriContent]));
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
   * @param unit the AST structure associated with the defining compilation unit for this library
   */
  void set definingCompilationUnit(CompilationUnit unit) {
    _astMap[librarySource] = unit;
  }

  /**
   * Set whether this library explicitly imports core to match the given value.
   * @param explicitlyImportsCore {@code true} if this library explicitly imports core
   */
  void set explicitlyImportsCore(bool explicitlyImportsCore2) {
    this._explicitlyImportsCore = explicitlyImportsCore2;
  }

  /**
   * Set the library element representing this library to the given library element.
   * @param libraryElement the library element representing this library
   */
  void set libraryElement(LibraryElementImpl libraryElement2) {
    this._libraryElement = libraryElement2;
    if (_inheritanceManager != null) {
      _inheritanceManager.libraryElement = libraryElement2;
    }
  }
  String toString() => _librarySource.shortName;

  /**
   * Return the result of resolving the given URI against the URI of the library, or {@code null} if
   * the URI is not valid.
   * @param uri the URI to be resolved
   * @return the result of resolving the given URI against the URI of the library
   */
  Source getSource2(String uri) {
    if (uri == null) {
      return null;
    }
    return _analysisContext.sourceFactory.resolveUri(_librarySource, uri);
  }
}
/**
 * Instances of the class {@code LibraryElementBuilder} build an element model for a single library.
 * @coverage dart.engine.resolver
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
  static String _ENTRY_POINT_NAME = "main";

  /**
   * Initialize a newly created library element builder.
   * @param resolver the resolver for which the element model is being built
   */
  LibraryElementBuilder(LibraryResolver resolver) {
    this._analysisContext = resolver.analysisContext;
    this._errorListener = resolver.errorListener;
  }

  /**
   * Build the library element for the given library.
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
      if (directive is LibraryDirective) {
        if (libraryNameNode == null) {
          libraryNameNode = ((directive as LibraryDirective)).name;
          directivesToResolve.add(directive);
        }
      } else if (directive is PartDirective) {
        PartDirective partDirective = directive as PartDirective;
        StringLiteral partUri = partDirective.uri;
        Source partSource = library.getSource(partDirective);
        if (partSource != null && partSource.exists()) {
          hasPartDirective = true;
          CompilationUnitElementImpl part = builder.buildCompilationUnit(partSource, library.getAST(partSource));
          part.uri = library.getUri(partDirective);
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
   * @param getters the map to which getters are to be added
   * @param setters the list to which setters are to be added
   * @param unit the compilation unit defining the accessors that are potentially being added
   */
  void collectAccessors(Map<String, PropertyAccessorElement> getters, List<PropertyAccessorElement> setters, CompilationUnitElement unit) {
    for (PropertyAccessorElement accessor in unit.accessors) {
      if (accessor.isGetter()) {
        if (!accessor.isSynthetic() && accessor.correspondingSetter == null) {
          getters[accessor.displayName] = accessor;
        }
      } else {
        if (!accessor.isSynthetic() && accessor.correspondingGetter == null) {
          setters.add(accessor);
        }
      }
    }
  }

  /**
   * Search the top-level functions defined in the given compilation unit for the entry point.
   * @param element the compilation unit to be searched
   * @return the entry point that was found, or {@code null} if the compilation unit does not define
   * an entry point
   */
  FunctionElement findEntryPoint(CompilationUnitElementImpl element) {
    for (FunctionElement function in element.functions) {
      if (function.name == _ENTRY_POINT_NAME) {
        return function;
      }
    }
    return null;
  }

  /**
   * Return the name of the library that the given part is declared to be a part of, or {@code null}if the part does not contain a part-of directive.
   * @param library the library containing the part
   * @param partSource the source representing the part
   * @param directivesToResolve a list of directives that should be resolved to the library being
   * built
   * @return the name of the library that the given part is declared to be a part of
   */
  String getPartLibraryName(Library library, Source partSource, List<Directive> directivesToResolve) {
    try {
      CompilationUnit partUnit = library.getAST(partSource);
      for (Directive directive in partUnit.directives) {
        if (directive is PartOfDirective) {
          directivesToResolve.add(directive);
          LibraryIdentifier libraryName = ((directive as PartOfDirective)).libraryName;
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
        ((setter as PropertyAccessorElementImpl)).variable = variable;
      }
    }
  }
}
/**
 * Instances of the class {@code LibraryResolver} are used to resolve one or more mutually dependent
 * libraries within a single context.
 * @coverage dart.engine.resolver
 */
class LibraryResolver {

  /**
   * The analysis context in which the libraries are being analyzed.
   */
  InternalAnalysisContext _analysisContext;

  /**
   * The listener to which analysis errors will be reported, this error listener is either
   * references {@link #recordingErrorListener}, or it unions the passed{@link AnalysisErrorListener} with the {@link #recordingErrorListener}.
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
   * @param analysisContext the analysis context in which the library is being analyzed
   */
  LibraryResolver(InternalAnalysisContext analysisContext) {
    this._analysisContext = analysisContext;
    this._errorListener = new RecordingErrorListener();
    _coreLibrarySource = analysisContext.sourceFactory.forUri(DartSdk.DART_CORE);
  }

  /**
   * Return the analysis context in which the libraries are being analyzed.
   * @return the analysis context in which the libraries are being analyzed
   */
  InternalAnalysisContext get analysisContext => _analysisContext;

  /**
   * Return the listener to which analysis errors will be reported.
   * @return the listener to which analysis errors will be reported
   */
  RecordingErrorListener get errorListener => _errorListener;

  /**
   * Return an array containing information about all of the libraries that were resolved.
   * @return an array containing the libraries that were resolved
   */
  Set<Library> get resolvedLibraries => _librariesInCycles;

  /**
   * Resolve the library specified by the given source in the given context. The library is assumed
   * to be embedded in the given source.
   * @param librarySource the source specifying the defining compilation unit of the library to be
   * resolved
   * @param unit the compilation unit representing the embedded library
   * @param fullAnalysis {@code true} if a full analysis should be performed
   * @return the element representing the resolved library
   * @throws AnalysisException if the library could not be resolved for some reason
   */
  LibraryElement resolveEmbeddedLibrary(Source librarySource, CompilationUnit unit, bool fullAnalysis) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("dart.engine.LibraryResolver.resolveEmbeddedLibrary");
    try {
      instrumentation.metric("fullAnalysis", fullAnalysis);
      instrumentation.data3("fullName", librarySource.fullName);
      Library targetLibrary = createLibrary2(librarySource, unit);
      _coreLibrary = _libraryMap[_coreLibrarySource];
      if (_coreLibrary == null) {
        _coreLibrary = createLibrary(_coreLibrarySource);
      }
      instrumentation.metric3("createLibrary", "complete");
      computeLibraryDependencies(targetLibrary);
      _librariesInCycles = computeLibrariesInCycles(targetLibrary);
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
      resolveReferencesAndTypes();
      instrumentation.metric3("resolveReferencesAndTypes", "complete");
      performConstantEvaluation();
      instrumentation.metric3("performConstantEvaluation", "complete");
      if (fullAnalysis) {
        runAdditionalAnalyses();
        instrumentation.metric3("runAdditionalAnalyses", "complete");
      }
      return targetLibrary.libraryElement;
    } finally {
      instrumentation.log();
    }
  }

  /**
   * Resolve the library specified by the given source in the given context.
   * <p>
   * Note that because Dart allows circular imports between libraries, it is possible that more than
   * one library will need to be resolved. In such cases the error listener can receive errors from
   * multiple libraries.
   * @param librarySource the source specifying the defining compilation unit of the library to be
   * resolved
   * @param fullAnalysis {@code true} if a full analysis should be performed
   * @return the element representing the resolved library
   * @throws AnalysisException if the library could not be resolved for some reason
   */
  LibraryElement resolveLibrary(Source librarySource, bool fullAnalysis) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("dart.engine.LibraryResolver.resolveLibrary");
    try {
      instrumentation.metric("fullAnalysis", fullAnalysis);
      instrumentation.data3("fullName", librarySource.fullName);
      Library targetLibrary = createLibrary(librarySource);
      _coreLibrary = _libraryMap[_coreLibrarySource];
      if (_coreLibrary == null) {
        _coreLibrary = createLibrary(_coreLibrarySource);
      }
      instrumentation.metric3("createLibrary", "complete");
      computeLibraryDependencies(targetLibrary);
      _librariesInCycles = computeLibrariesInCycles(targetLibrary);
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
      resolveReferencesAndTypes();
      instrumentation.metric3("resolveReferencesAndTypes", "complete");
      performConstantEvaluation();
      instrumentation.metric3("performConstantEvaluation", "complete");
      if (fullAnalysis) {
        runAdditionalAnalyses();
        instrumentation.metric3("runAdditionalAnalyses", "complete");
      }
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
   * @param library the library to be added to the collection of libraries in cycles
   * @param librariesInCycle a collection of the libraries that are in the cycle
   * @param dependencyMap a table mapping libraries to the collection of libraries from which those
   * libraries are referenced
   */
  void addLibrariesInCycle(Library library, Set<Library> librariesInCycle, Map<Library, List<Library>> dependencyMap) {
    if (javaSetAdd(librariesInCycle, library)) {
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
   * @param library the library currently being added to the dependency map
   * @param dependencyMap the dependency map being computed
   * @param visitedLibraries the libraries that have already been visited, used to prevent infinite
   * recursion
   */
  void addToDependencyMap(Library library, Map<Library, List<Library>> dependencyMap, Set<Library> visitedLibraries) {
    if (javaSetAdd(visitedLibraries, library)) {
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
   * @param directive the directive that declares the combinators
   * @return an array containing the import combinators that were built
   */
  List<NamespaceCombinator> buildCombinators(NamespaceDirective directive) {
    List<NamespaceCombinator> combinators = new List<NamespaceCombinator>();
    for (Combinator combinator in directive.combinators) {
      if (combinator is HideCombinator) {
        HideElementCombinatorImpl hide = new HideElementCombinatorImpl();
        hide.hiddenNames = getIdentifiers(((combinator as HideCombinator)).hiddenNames);
        combinators.add(hide);
      } else {
        ShowElementCombinatorImpl show = new ShowElementCombinatorImpl();
        show.shownNames = getIdentifiers(((combinator as ShowCombinator)).shownNames);
        combinators.add(show);
      }
    }
    return new List.from(combinators);
  }

  /**
   * Every library now has a corresponding {@link LibraryElement}, so it is now possible to resolve
   * the import and export directives.
   * @throws AnalysisException if the defining compilation unit for any of the libraries could not
   * be accessed
   */
  void buildDirectiveModels() {
    for (Library library in _librariesInCycles) {
      Map<String, PrefixElementImpl> nameToPrefixMap = new Map<String, PrefixElementImpl>();
      List<ImportElement> imports = new List<ImportElement>();
      List<ExportElement> exports = new List<ExportElement>();
      for (Directive directive in library.definingCompilationUnit.directives) {
        if (directive is ImportDirective) {
          ImportDirective importDirective = directive as ImportDirective;
          Library importedLibrary = library.getImport(importDirective);
          if (importedLibrary != null) {
            ImportElementImpl importElement = new ImportElementImpl();
            importElement.uri = library.getUri(importDirective);
            importElement.combinators = buildCombinators(importDirective);
            LibraryElement importedLibraryElement = importedLibrary.libraryElement;
            if (importedLibraryElement != null) {
              importElement.importedLibrary = importedLibraryElement;
            }
            SimpleIdentifier prefixNode = ((directive as ImportDirective)).prefix;
            if (prefixNode != null) {
              String prefixName = prefixNode.name;
              PrefixElementImpl prefix = nameToPrefixMap[prefixName];
              if (prefix == null) {
                prefix = new PrefixElementImpl(prefixNode);
                nameToPrefixMap[prefixName] = prefix;
              }
              importElement.prefix = prefix;
            }
            directive.element = importElement;
            imports.add(importElement);
          }
        } else if (directive is ExportDirective) {
          ExportDirective exportDirective = directive as ExportDirective;
          ExportElementImpl exportElement = new ExportElementImpl();
          exportElement.uri = library.getUri(exportDirective);
          exportElement.combinators = buildCombinators(exportDirective);
          Library exportedLibrary = library.getExport(exportDirective);
          if (exportedLibrary != null) {
            LibraryElement exportedLibraryElement = exportedLibrary.libraryElement;
            if (exportedLibraryElement != null) {
              exportElement.exportedLibrary = exportedLibraryElement;
            }
            directive.element = exportElement;
            exports.add(exportElement);
          }
        }
      }
      Source librarySource = library.librarySource;
      if (!library.explicitlyImportsCore && _coreLibrarySource != librarySource) {
        ImportElementImpl importElement = new ImportElementImpl();
        importElement.importedLibrary = _coreLibrary.libraryElement;
        importElement.synthetic = true;
        imports.add(importElement);
      }
      LibraryElementImpl libraryElement = library.libraryElement;
      libraryElement.imports = new List.from(imports);
      libraryElement.exports = new List.from(exports);
    }
  }

  /**
   * Build element models for all of the libraries in the current cycle.
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
   * @throws AnalysisException if any of the type hierarchies could not be resolved
   */
  void buildTypeHierarchies() {
    for (Library library in _librariesInCycles) {
      for (Source source in library.compilationUnitSources) {
        TypeResolverVisitor visitor = new TypeResolverVisitor.con1(library, source, _typeProvider);
        library.getAST(source).accept(visitor);
      }
    }
  }

  /**
   * Compute a dependency map of libraries reachable from the given library. A dependency map is a
   * table that maps individual libraries to a list of the libraries that either import or export
   * those libraries.
   * <p>
   * This map is used to compute all of the libraries involved in a cycle that include the root
   * library. Given that we only add libraries that are reachable from the root library, when we
   * work backward we are guaranteed to only get libraries in the cycle.
   * @param library the library currently being added to the dependency map
   */
  Map<Library, List<Library>> computeDependencyMap(Library library) {
    Map<Library, List<Library>> dependencyMap = new Map<Library, List<Library>>();
    addToDependencyMap(library, dependencyMap, new Set<Library>());
    return dependencyMap;
  }

  /**
   * Return a collection containing all of the libraries reachable from the given library that are
   * contained in a cycle that includes the given library.
   * @param library the library that must be included in any cycles whose members are to be returned
   * @return all of the libraries referenced by the given library that have a circular reference
   * back to the given library
   */
  Set<Library> computeLibrariesInCycles(Library library) {
    Map<Library, List<Library>> dependencyMap = computeDependencyMap(library);
    Set<Library> librariesInCycle = new Set<Library>();
    addLibrariesInCycle(library, librariesInCycle, dependencyMap);
    return librariesInCycle;
  }

  /**
   * Recursively traverse the libraries reachable from the given library, creating instances of the
   * class {@link Library} to represent them, and record the references in the library objects.
   * @param library the library to be processed to find libraries that have not yet been traversed
   * @throws AnalysisException if some portion of the library graph could not be traversed
   */
  void computeLibraryDependencies(Library library) {
    bool explicitlyImportsCore = false;
    CompilationUnit unit = library.definingCompilationUnit;
    for (Directive directive in unit.directives) {
      if (directive is ImportDirective) {
        ImportDirective importDirective = directive as ImportDirective;
        Source importedSource = library.getSource(importDirective);
        if (importedSource != null) {
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
            library.addImport(importDirective, importedLibrary);
            if (doesCompilationUnitHavePartOfDirective(importedLibrary.getAST(importedSource))) {
              StringLiteral uriLiteral = importDirective.uri;
              _errorListener.onError(new AnalysisError.con2(library.librarySource, uriLiteral.offset, uriLiteral.length, CompileTimeErrorCode.IMPORT_OF_NON_LIBRARY, [uriLiteral.toSource()]));
            }
          }
        }
      } else if (directive is ExportDirective) {
        ExportDirective exportDirective = directive as ExportDirective;
        Source exportedSource = library.getSource(exportDirective);
        if (exportedSource != null) {
          Library exportedLibrary = _libraryMap[exportedSource];
          if (exportedLibrary == null) {
            exportedLibrary = createLibraryOrNull(exportedSource);
            if (exportedLibrary != null) {
              computeLibraryDependencies(exportedLibrary);
            }
          }
          if (exportedLibrary != null) {
            library.addExport(exportDirective, exportedLibrary);
            if (doesCompilationUnitHavePartOfDirective(exportedLibrary.getAST(exportedSource))) {
              StringLiteral uriLiteral = exportDirective.uri;
              _errorListener.onError(new AnalysisError.con2(library.librarySource, uriLiteral.offset, uriLiteral.length, CompileTimeErrorCode.EXPORT_OF_NON_LIBRARY, [uriLiteral.toSource()]));
            }
          }
        }
      }
    }
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
   * @param librarySource the source of the library's defining compilation unit
   * @return the library object that was created
   * @throws AnalysisException if the library source is not valid
   */
  Library createLibrary(Source librarySource) {
    Library library = new Library(_analysisContext, _errorListener, librarySource);
    library.definingCompilationUnit;
    _libraryMap[librarySource] = library;
    return library;
  }

  /**
   * Create an object to represent the information about the library defined by the compilation unit
   * with the given source.
   * @param librarySource the source of the library's defining compilation unit
   * @return the library object that was created
   * @throws AnalysisException if the library source is not valid
   */
  Library createLibrary2(Source librarySource, CompilationUnit unit) {
    Library library = new Library(_analysisContext, _errorListener, librarySource);
    library.definingCompilationUnit = unit;
    _libraryMap[librarySource] = library;
    return library;
  }

  /**
   * Create an object to represent the information about the library defined by the compilation unit
   * with the given source. Return the library object that was created, or {@code null} if the
   * source is not valid.
   * @param librarySource the source of the library's defining compilation unit
   * @return the library object that was created
   */
  Library createLibraryOrNull(Source librarySource) {
    if (!librarySource.exists()) {
      return null;
    }
    Library library = new Library(_analysisContext, _errorListener, librarySource);
    try {
      library.definingCompilationUnit;
    } on AnalysisException catch (exception) {
      return null;
    }
    _libraryMap[librarySource] = library;
    return library;
  }

  /**
   * Return {@code true} if and only if the passed {@link CompilationUnit} has a part-of directive.
   * @param node the {@link CompilationUnit} to test
   * @return {@code true} if and only if the passed {@link CompilationUnit} has a part-of directive
   */
  bool doesCompilationUnitHavePartOfDirective(CompilationUnit node) {
    NodeList<Directive> directives = node.directives;
    for (Directive directive in directives) {
      if (directive is PartOfDirective) {
        return true;
      }
    }
    return false;
  }

  /**
   * Return an array containing the lexical identifiers associated with the nodes in the given list.
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
    ConstantValueComputer computer = new ConstantValueComputer();
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
  }

  /**
   * Resolve the identifiers and perform type analysis in the libraries in the current cycle.
   * @throws AnalysisException if any of the identifiers could not be resolved or if any of the
   * libraries could not have their types analyzed
   */
  void resolveReferencesAndTypes() {
    for (Library library in _librariesInCycles) {
      resolveReferencesAndTypes2(library);
    }
  }

  /**
   * Resolve the identifiers and perform type analysis in the given library.
   * @param library the library to be resolved
   * @throws AnalysisException if any of the identifiers could not be resolved or if the types in
   * the library cannot be analyzed
   */
  void resolveReferencesAndTypes2(Library library) {
    for (Source source in library.compilationUnitSources) {
      ResolverVisitor visitor = new ResolverVisitor.con1(library, source, _typeProvider);
      library.getAST(source).accept(visitor);
    }
  }

  /**
   * Run additional analyses, such as the {@link ConstantVerifier} and {@link ErrorVerifier}analysis in the current cycle.
   * @throws AnalysisException if any of the identifiers could not be resolved or if the types in
   * the library cannot be analyzed
   */
  void runAdditionalAnalyses() {
    for (Library library in _librariesInCycles) {
      runAdditionalAnalyses2(library);
    }
  }

  /**
   * Run additional analyses, such as the {@link ConstantVerifier} and {@link ErrorVerifier}analysis in the given library.
   * @param library the library to have the extra analyses processes run
   * @throws AnalysisException if any of the identifiers could not be resolved or if the types in
   * the library cannot be analyzed
   */
  void runAdditionalAnalyses2(Library library) {
    for (Source source in library.compilationUnitSources) {
      ErrorReporter errorReporter = new ErrorReporter(_errorListener, source);
      CompilationUnit unit = library.getAST(source);
      ErrorVerifier errorVerifier = new ErrorVerifier(errorReporter, library.libraryElement, _typeProvider, library.inheritanceManager);
      unit.accept(errorVerifier);
      unit.accept(new PubVerifier(_analysisContext, errorReporter));
      ConstantVerifier constantVerifier = new ConstantVerifier(errorReporter, _typeProvider);
      unit.accept(constantVerifier);
    }
  }
}
/**
 * Instances of the class {@code ResolverVisitor} are used to resolve the nodes within a single
 * compilation unit.
 * @coverage dart.engine.resolver
 */
class ResolverVisitor extends ScopedVisitor {

  /**
   * The object used to resolve the element associated with the current node.
   */
  ElementResolver _elementResolver;

  /**
   * The object used to compute the type associated with the current node.
   */
  StaticTypeAnalyzer _typeAnalyzer;

  /**
   * The class element representing the class containing the current node, or {@code null} if the
   * current node is not contained in a class.
   */
  ClassElement _enclosingClass = null;

  /**
   * The element representing the function containing the current node, or {@code null} if the
   * current node is not contained in a function.
   */
  ExecutableElement _enclosingFunction = null;

  /**
   * The object keeping track of which elements have had their types overridden.
   */
  TypeOverrideManager _overrideManager = new TypeOverrideManager();

  /**
   * Initialize a newly created visitor to resolve the nodes in a compilation unit.
   * @param library the library containing the compilation unit being resolved
   * @param source the source representing the compilation unit being visited
   * @param typeProvider the object used to access the types from the core library
   */
  ResolverVisitor.con1(Library library, Source source, TypeProvider typeProvider) : super.con1(library, source, typeProvider) {
    _jtd_constructor_273_impl(library, source, typeProvider);
  }
  _jtd_constructor_273_impl(Library library, Source source, TypeProvider typeProvider) {
    this._elementResolver = new ElementResolver(this);
    this._typeAnalyzer = new StaticTypeAnalyzer(this);
  }

  /**
   * Initialize a newly created visitor to resolve the nodes in a compilation unit.
   * @param definingLibrary the element for the library containing the compilation unit being
   * visited
   * @param source the source representing the compilation unit being visited
   * @param typeProvider the object used to access the types from the core library
   * @param errorListener the error listener that will be informed of any errors that are found
   * during resolution
   */
  ResolverVisitor.con2(LibraryElement definingLibrary, Source source, TypeProvider typeProvider, AnalysisErrorListener errorListener) : super.con2(definingLibrary, source, typeProvider, errorListener) {
    _jtd_constructor_274_impl(definingLibrary, source, typeProvider, errorListener);
  }
  _jtd_constructor_274_impl(LibraryElement definingLibrary, Source source, TypeProvider typeProvider, AnalysisErrorListener errorListener) {
    this._elementResolver = new ElementResolver(this);
    this._typeAnalyzer = new StaticTypeAnalyzer(this);
  }

  /**
   * Return the object keeping track of which elements have had their types overridden.
   * @return the object keeping track of which elements have had their types overridden
   */
  TypeOverrideManager get overrideManager => _overrideManager;
  Object visitAsExpression(AsExpression node) {
    super.visitAsExpression(node);
    VariableElement element = getOverridableElement(node.expression);
    if (element != null) {
      override(element, node.type.type);
    }
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
          propagateTrueState(leftOperand);
          rightOperand.accept(this);
        } finally {
          _overrideManager.exitScope();
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
  Object visitBreakStatement(BreakStatement node) {
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
  Object visitCommentReference(CommentReference node) {
    node.accept(_elementResolver);
    node.accept(_typeAnalyzer);
    return null;
  }
  Object visitCompilationUnit(CompilationUnit node) {
    try {
      _overrideManager.enterScope();
      for (Directive directive in node.directives) {
        directive.accept(this);
      }
      List<CompilationUnitMember> classes = new List<CompilationUnitMember>();
      for (CompilationUnitMember declaration in node.declarations) {
        if (declaration is ClassDeclaration) {
          classes.add(declaration);
        } else {
          declaration.accept(this);
        }
      }
      for (CompilationUnitMember declaration in classes) {
        declaration.accept(this);
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
        propagateTrueState(condition);
        thenExpression.accept(this);
      } finally {
        _overrideManager.exitScope();
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
    safelyVisit(node.expression);
    node.accept(_elementResolver);
    node.accept(_typeAnalyzer);
    return null;
  }
  Object visitConstructorName(ConstructorName node) {
    node.accept(_elementResolver);
    node.accept(_typeAnalyzer);
    return null;
  }
  Object visitContinueStatement(ContinueStatement node) {
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
  Object visitFunctionBody(FunctionBody node) {
    try {
      _overrideManager.enterScope();
      super.visitFunctionBody(node);
    } finally {
      _overrideManager.exitScope();
    }
    return null;
  }
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    ExecutableElement outerFunction = _enclosingFunction;
    try {
      SimpleIdentifier functionName = node.name;
      _enclosingFunction = functionName.element as ExecutableElement;
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
  Object visitHideCombinator(HideCombinator node) => null;
  Object visitIfStatement(IfStatement node) {
    Expression condition = node.condition;
    safelyVisit(condition);
    Map<Element, Type2> thenOverrides = null;
    Statement thenStatement = node.thenStatement;
    if (thenStatement != null) {
      try {
        _overrideManager.enterScope();
        propagateTrueState(condition);
        thenStatement.accept(this);
      } finally {
        thenOverrides = _overrideManager.captureLocalOverrides();
        _overrideManager.exitScope();
      }
    }
    Map<Element, Type2> elseOverrides = null;
    Statement elseStatement = node.elseStatement;
    if (elseStatement != null) {
      try {
        _overrideManager.enterScope();
        propagateFalseState(condition);
        elseStatement.accept(this);
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
    safelyVisit(node.target);
    safelyVisit(node.argumentList);
    node.accept(_elementResolver);
    node.accept(_typeAnalyzer);
    return null;
  }
  Object visitNode(ASTNode node) {
    node.visitChildren(this);
    node.accept(_elementResolver);
    node.accept(_typeAnalyzer);
    return null;
  }
  Object visitPrefixedIdentifier(PrefixedIdentifier node) {
    safelyVisit(node.prefix);
    node.accept(_elementResolver);
    node.accept(_typeAnalyzer);
    return null;
  }
  Object visitPropertyAccess(PropertyAccess node) {
    safelyVisit(node.target);
    node.accept(_elementResolver);
    node.accept(_typeAnalyzer);
    return null;
  }
  Object visitRedirectingConstructorInvocation(RedirectingConstructorInvocation node) {
    safelyVisit(node.argumentList);
    node.accept(_elementResolver);
    node.accept(_typeAnalyzer);
    return null;
  }
  Object visitShowCombinator(ShowCombinator node) => null;
  Object visitSuperConstructorInvocation(SuperConstructorInvocation node) {
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
        body.accept(this);
      } finally {
        _overrideManager.exitScope();
      }
    }
    node.accept(_elementResolver);
    node.accept(_typeAnalyzer);
    return null;
  }

  /**
   * Return the class element representing the class containing the current node, or {@code null} if
   * the current node is not contained in a class.
   * @return the class element representing the class containing the current node
   */
  ClassElement get enclosingClass => _enclosingClass;

  /**
   * Return the element representing the function containing the current node, or {@code null} if
   * the current node is not contained in a function.
   * @return the element representing the function containing the current node
   */
  ExecutableElement get enclosingFunction => _enclosingFunction;

  /**
   * Return the element associated with the given expression whose type can be overridden, or{@code null} if there is no element whose type can be overridden.
   * @param expression the expression with which the element is associated
   * @return the element associated with the given expression
   */
  VariableElement getOverridableElement(Expression expression) {
    Element element = null;
    if (expression is SimpleIdentifier) {
      element = ((expression as SimpleIdentifier)).element;
    } else if (expression is PrefixedIdentifier) {
      element = ((expression as PrefixedIdentifier)).element;
    } else if (expression is PropertyAccess) {
      element = ((expression as PropertyAccess)).propertyName.element;
    }
    if (element is VariableElement) {
      return element as VariableElement;
    }
    return null;
  }

  /**
   * If it is appropriate to do so, override the current type of the given element with the given
   * type. Generally speaking, it is appropriate if the given type is more specific than the current
   * type.
   * @param element the element whose type might be overridden
   * @param potentialType the potential type of the element
   */
  void override(VariableElement element, Type2 potentialType) {
    if (potentialType == null || identical(potentialType, BottomTypeImpl.instance)) {
      return;
    }
    if (element is PropertyInducingElement) {
      PropertyInducingElement variable = element as PropertyInducingElement;
      if (!variable.isConst() && !variable.isFinal()) {
        return;
      }
    }
    Type2 currentType = getBestType(element);
    if (currentType == null || !currentType.isMoreSpecificThan(potentialType)) {
      _overrideManager.setType(element, potentialType);
    }
  }
  void visitForEachStatementInScope(ForEachStatement node) {
    Expression iterator = node.iterator;
    safelyVisit(iterator);
    DeclaredIdentifier loopVariable = node.loopVariable;
    safelyVisit(loopVariable);
    Statement body = node.body;
    if (body != null) {
      try {
        _overrideManager.enterScope();
        if (loopVariable != null && iterator != null) {
          LocalVariableElement loopElement = loopVariable.element;
          if (loopElement != null) {
            override(loopElement, getIteratorElementType(iterator));
          }
        }
        body.accept(this);
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
      safelyVisit(node.body);
      node.updaters.accept(this);
    } finally {
      _overrideManager.exitScope();
    }
  }

  /**
   * Return the best type information available for the given element. If the type of the element
   * has been overridden, then return the overriding type. Otherwise, return the static type.
   * @param element the element for which type information is to be returned
   * @return the best type information available for the given element
   */
  Type2 getBestType(Element element) {
    Type2 bestType = _overrideManager.getType(element);
    if (bestType == null) {
      if (element is LocalVariableElement) {
        bestType = ((element as LocalVariableElement)).type;
      } else if (element is ParameterElement) {
        bestType = ((element as ParameterElement)).type;
      }
    }
    return bestType;
  }

  /**
   * The given expression is the expression used to compute the iterator for a for-each statement.
   * Attempt to compute the type of objects that will be assigned to the loop variable and return
   * that type. Return {@code null} if the type could not be determined.
   * @param iterator the iterator for a for-each statement
   * @return the type of objects that will be assigned to the loop variable
   */
  Type2 getIteratorElementType(Expression iteratorExpression) {
    Type2 expressionType = iteratorExpression.staticType;
    if (expressionType is InterfaceType) {
      PropertyAccessorElement iterator = ((expressionType as InterfaceType)).lookUpGetter("iterator", definingLibrary);
      if (iterator == null) {
        return null;
      }
      Type2 iteratorType = iterator.type.returnType;
      if (iteratorType is InterfaceType) {
        PropertyAccessorElement current = ((iteratorType as InterfaceType)).lookUpGetter("current", definingLibrary);
        if (current == null) {
          return null;
        }
        return current.type.returnType;
      }
    }
    return null;
  }

  /**
   * Return {@code true} if the given expression terminates abruptly (that is, if any expression
   * following the given expression will not be reached).
   * @param expression the expression being tested
   * @return {@code true} if the given expression terminates abruptly
   */
  bool isAbruptTermination(Expression expression2) {
    while (expression2 is ParenthesizedExpression) {
      expression2 = ((expression2 as ParenthesizedExpression)).expression;
    }
    return expression2 is ThrowExpression || expression2 is RethrowExpression;
  }

  /**
   * Return {@code true} if the given statement terminates abruptly (that is, if any statement
   * following the given statement will not be reached).
   * @param statement the statement being tested
   * @return {@code true} if the given statement terminates abruptly
   */
  bool isAbruptTermination2(Statement statement) {
    if (statement is ReturnStatement || statement is BreakStatement || statement is ContinueStatement) {
      return true;
    } else if (statement is ExpressionStatement) {
      return isAbruptTermination(((statement as ExpressionStatement)).expression);
    } else if (statement is Block) {
      NodeList<Statement> statements = ((statement as Block)).statements;
      int size = statements.length;
      if (size == 0) {
        return false;
      }
      return isAbruptTermination2(statements[size - 1]);
    }
    return false;
  }

  /**
   * Propagate any type information that results from knowing that the given condition will have
   * been evaluated to 'false'.
   * @param condition the condition that will have evaluated to 'false'
   */
  void propagateFalseState(Expression condition) {
    if (condition is BinaryExpression) {
      BinaryExpression binary = condition as BinaryExpression;
      if (identical(binary.operator.type, sc.TokenType.BAR_BAR)) {
        propagateFalseState(binary.leftOperand);
        propagateFalseState(binary.rightOperand);
      }
    } else if (condition is IsExpression) {
      IsExpression is2 = condition as IsExpression;
      if (is2.notOperator != null) {
        VariableElement element = getOverridableElement(is2.expression);
        if (element != null) {
          override(element, is2.type.type);
        }
      }
    } else if (condition is PrefixExpression) {
      PrefixExpression prefix = condition as PrefixExpression;
      if (identical(prefix.operator.type, sc.TokenType.BANG)) {
        propagateTrueState(prefix.operand);
      }
    } else if (condition is ParenthesizedExpression) {
      propagateFalseState(((condition as ParenthesizedExpression)).expression);
    }
  }

  /**
   * Propagate any type information that results from knowing that the given expression will have
   * been evaluated without altering the flow of execution.
   * @param expression the expression that will have been evaluated
   */
  void propagateState(Expression expression) {
  }

  /**
   * Propagate any type information that results from knowing that the given condition will have
   * been evaluated to 'true'.
   * @param condition the condition that will have evaluated to 'true'
   */
  void propagateTrueState(Expression condition) {
    if (condition is BinaryExpression) {
      BinaryExpression binary = condition as BinaryExpression;
      if (identical(binary.operator.type, sc.TokenType.AMPERSAND_AMPERSAND)) {
        propagateTrueState(binary.leftOperand);
        propagateTrueState(binary.rightOperand);
      }
    } else if (condition is IsExpression) {
      IsExpression is2 = condition as IsExpression;
      if (is2.notOperator == null) {
        VariableElement element = getOverridableElement(is2.expression);
        if (element != null) {
          override(element, is2.type.type);
        }
      }
    } else if (condition is PrefixExpression) {
      PrefixExpression prefix = condition as PrefixExpression;
      if (identical(prefix.operator.type, sc.TokenType.BANG)) {
        propagateFalseState(prefix.operand);
      }
    } else if (condition is ParenthesizedExpression) {
      propagateTrueState(((condition as ParenthesizedExpression)).expression);
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
/**
 * The abstract class {@code ScopedVisitor} maintains name and label scopes as an AST structure is
 * being visited.
 * @coverage dart.engine.resolver
 */
abstract class ScopedVisitor extends GeneralizingASTVisitor<Object> {

  /**
   * The element for the library containing the compilation unit being visited.
   */
  LibraryElement _definingLibrary;

  /**
   * The source representing the compilation unit being visited.
   */
  Source _source;

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
  TypeProvider _typeProvider;

  /**
   * The scope used to resolve labels for {@code break} and {@code continue} statements, or{@code null} if no labels have been defined in the current context.
   */
  LabelScope _labelScope;

  /**
   * Initialize a newly created visitor to resolve the nodes in a compilation unit.
   * @param library the library containing the compilation unit being resolved
   * @param source the source representing the compilation unit being visited
   * @param typeProvider the object used to access the types from the core library
   */
  ScopedVisitor.con1(Library library, Source source2, TypeProvider typeProvider2) {
    _jtd_constructor_275_impl(library, source2, typeProvider2);
  }
  _jtd_constructor_275_impl(Library library, Source source2, TypeProvider typeProvider2) {
    this._definingLibrary = library.libraryElement;
    this._source = source2;
    LibraryScope libraryScope = library.libraryScope;
    this._errorListener = libraryScope.errorListener;
    this._nameScope = libraryScope;
    this._typeProvider = typeProvider2;
  }

  /**
   * Initialize a newly created visitor to resolve the nodes in a compilation unit.
   * @param definingLibrary the element for the library containing the compilation unit being
   * visited
   * @param source the source representing the compilation unit being visited
   * @param typeProvider the object used to access the types from the core library
   * @param errorListener the error listener that will be informed of any errors that are found
   * during resolution
   */
  ScopedVisitor.con2(LibraryElement definingLibrary2, Source source2, TypeProvider typeProvider2, AnalysisErrorListener errorListener2) {
    _jtd_constructor_276_impl(definingLibrary2, source2, typeProvider2, errorListener2);
  }
  _jtd_constructor_276_impl(LibraryElement definingLibrary2, Source source2, TypeProvider typeProvider2, AnalysisErrorListener errorListener2) {
    this._definingLibrary = definingLibrary2;
    this._source = source2;
    this._errorListener = errorListener2;
    this._nameScope = new LibraryScope(definingLibrary2, errorListener2);
    this._typeProvider = typeProvider2;
  }

  /**
   * Return the library element for the library containing the compilation unit being resolved.
   * @return the library element for the library containing the compilation unit being resolved
   */
  LibraryElement get definingLibrary => _definingLibrary;

  /**
   * Return the object used to access the types from the core library.
   * @return the object used to access the types from the core library
   */
  TypeProvider get typeProvider => _typeProvider;
  Object visitBlock(Block node) {
    Scope outerScope = _nameScope;
    _nameScope = new EnclosedScope(_nameScope);
    try {
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
      _nameScope = new EnclosedScope(_nameScope);
      try {
        _nameScope.define(exception.element);
        SimpleIdentifier stackTrace = node.stackTraceParameter;
        if (stackTrace != null) {
          _nameScope.define(stackTrace.element);
        }
        super.visitCatchClause(node);
      } finally {
        _nameScope = outerScope;
      }
    }
    return null;
  }
  Object visitClassDeclaration(ClassDeclaration node) {
    Scope outerScope = _nameScope;
    try {
      _nameScope = new ClassScope(_nameScope, node.element);
      super.visitClassDeclaration(node);
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
    LabelScope outerScope = _labelScope;
    _labelScope = new LabelScope.con1(outerScope, false, false);
    try {
      super.visitDoStatement(node);
    } finally {
      _labelScope = outerScope;
    }
    return null;
  }
  Object visitForEachStatement(ForEachStatement node) {
    LabelScope outerLabelScope = _labelScope;
    _labelScope = new LabelScope.con1(outerLabelScope, false, false);
    Scope outerNameScope = _nameScope;
    _nameScope = new EnclosedScope(_nameScope);
    try {
      visitForEachStatementInScope(node);
    } finally {
      _nameScope = outerNameScope;
      _labelScope = outerLabelScope;
    }
    return null;
  }
  Object visitForStatement(ForStatement node) {
    LabelScope outerLabelScope = _labelScope;
    _labelScope = new LabelScope.con1(outerLabelScope, false, false);
    Scope outerNameScope = _nameScope;
    _nameScope = new EnclosedScope(_nameScope);
    try {
      visitForStatementInScope(node);
    } finally {
      _nameScope = outerNameScope;
      _labelScope = outerLabelScope;
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
    _nameScope = new EnclosedScope(_nameScope);
    try {
      node.statements.accept(this);
    } finally {
      _nameScope = outerNameScope;
    }
    return null;
  }
  Object visitSwitchDefault(SwitchDefault node) {
    Scope outerNameScope = _nameScope;
    _nameScope = new EnclosedScope(_nameScope);
    try {
      node.statements.accept(this);
    } finally {
      _nameScope = outerNameScope;
    }
    return null;
  }
  Object visitSwitchStatement(SwitchStatement node) {
    LabelScope outerScope = _labelScope;
    _labelScope = new LabelScope.con1(outerScope, true, false);
    for (SwitchMember member in node.members) {
      for (Label label in member.labels) {
        SimpleIdentifier labelName = label.label;
        LabelElement labelElement = labelName.element as LabelElement;
        _labelScope = new LabelScope.con2(_labelScope, labelName.name, labelElement);
      }
    }
    try {
      super.visitSwitchStatement(node);
    } finally {
      _labelScope = outerScope;
    }
    return null;
  }
  Object visitVariableDeclaration(VariableDeclaration node) {
    if (node.parent.parent is! TopLevelVariableDeclaration && node.parent.parent is! FieldDeclaration) {
      VariableElement element = node.element;
      if (element != null) {
        _nameScope.define(element);
      }
    }
    super.visitVariableDeclaration(node);
    return null;
  }
  Object visitWhileStatement(WhileStatement node) {
    LabelScope outerScope = _labelScope;
    _labelScope = new LabelScope.con1(outerScope, false, false);
    try {
      super.visitWhileStatement(node);
    } finally {
      _labelScope = outerScope;
    }
    return null;
  }

  /**
   * Return the label scope in which the current node is being resolved.
   * @return the label scope in which the current node is being resolved
   */
  LabelScope get labelScope => _labelScope;

  /**
   * Return the name scope in which the current node is being resolved.
   * @return the name scope in which the current node is being resolved
   */
  Scope get nameScope => _nameScope;

  /**
   * Report an error with the given error code and arguments.
   * @param errorCode the error code of the error to be reported
   * @param node the node specifying the location of the error
   * @param arguments the arguments to the error, used to compose the error message
   */
  void reportError(ErrorCode errorCode, ASTNode node, List<Object> arguments) {
    _errorListener.onError(new AnalysisError.con2(_source, node.offset, node.length, errorCode, arguments));
  }

  /**
   * Report an error with the given error code and arguments.
   * @param errorCode the error code of the error to be reported
   * @param offset the offset of the location of the error
   * @param length the length of the location of the error
   * @param arguments the arguments to the error, used to compose the error message
   */
  void reportError5(ErrorCode errorCode, int offset, int length, List<Object> arguments) {
    _errorListener.onError(new AnalysisError.con2(_source, offset, length, errorCode, arguments));
  }

  /**
   * Report an error with the given error code and arguments.
   * @param errorCode the error code of the error to be reported
   * @param token the token specifying the location of the error
   * @param arguments the arguments to the error, used to compose the error message
   */
  void reportError6(ErrorCode errorCode, sc.Token token, List<Object> arguments) {
    _errorListener.onError(new AnalysisError.con2(_source, token.offset, token.length, errorCode, arguments));
  }

  /**
   * Visit the given AST node if it is not null.
   * @param node the node to be visited
   */
  void safelyVisit(ASTNode node) {
    if (node != null) {
      node.accept(this);
    }
  }

  /**
   * Visit the given statement after it's scope has been created. This replaces the normal call to
   * the inherited visit method so that ResolverVisitor can intervene when type propagation is
   * enabled.
   * @param node the statement to be visited
   */
  void visitForEachStatementInScope(ForEachStatement node) {
    safelyVisit(node.iterator);
    safelyVisit(node.loopVariable);
    safelyVisit(node.body);
  }

  /**
   * Visit the given statement after it's scope has been created. This replaces the normal call to
   * the inherited visit method so that ResolverVisitor can intervene when type propagation is
   * enabled.
   * @param node the statement to be visited
   */
  void visitForStatementInScope(ForStatement node) {
    super.visitForStatement(node);
  }

  /**
   * Add scopes for each of the given labels.
   * @param labels the labels for which new scopes are to be added
   * @return the scope that was in effect before the new scopes were added
   */
  LabelScope addScopesFor(NodeList<Label> labels) {
    LabelScope outerScope = _labelScope;
    for (Label label in labels) {
      SimpleIdentifier labelNameNode = label.label;
      String labelName = labelNameNode.name;
      LabelElement labelElement = labelNameNode.element as LabelElement;
      _labelScope = new LabelScope.con2(_labelScope, labelName, labelElement);
    }
    return outerScope;
  }
}
/**
 * Instances of the class {@code StaticTypeAnalyzer} perform two type-related tasks. First, they
 * compute the static type of every expression. Second, they look for any static type errors or
 * warnings that might need to be generated. The requirements for the type analyzer are:
 * <ol>
 * <li>Every element that refers to types should be fully populated.
 * <li>Every node representing an expression should be resolved to the Type of the expression.</li>
 * </ol>
 * @coverage dart.engine.resolver
 */
class StaticTypeAnalyzer extends SimpleASTVisitor<Object> {

  /**
   * Create a table mapping HTML tag names to the names of the classes (in 'dart:html') that
   * implement those tags.
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
   * The type representing the class containing the nodes being analyzed, or {@code null} if the
   * nodes are not within a class.
   */
  InterfaceType _thisType;

  /**
   * The object keeping track of which elements have had their types overridden.
   */
  TypeOverrideManager _overrideManager;

  /**
   * A table mapping HTML tag names to the names of the classes (in 'dart:html') that implement
   * those tags.
   */
  static Map<String, String> _HTML_ELEMENT_TO_CLASS_MAP = createHtmlTagToClassMap();

  /**
   * Initialize a newly created type analyzer.
   * @param resolver the resolver driving this participant
   */
  StaticTypeAnalyzer(ResolverVisitor resolver) {
    this._resolver = resolver;
    _typeProvider = resolver.typeProvider;
    _dynamicType = _typeProvider.dynamicType;
    _overrideManager = resolver.overrideManager;
  }

  /**
   * Set the type of the class being analyzed to the given type.
   * @param thisType the type representing the class containing the nodes being analyzed
   */
  void set thisType(InterfaceType thisType2) {
    this._thisType = thisType2;
  }

  /**
   * The Dart Language Specification, 12.5: <blockquote>The static type of a string literal is{@code String}.</blockquote>
   */
  Object visitAdjacentStrings(AdjacentStrings node) {
    recordStaticType(node, _typeProvider.stringType);
    return null;
  }

  /**
   * The Dart Language Specification, 12.33: <blockquote>The static type of an argument definition
   * test is {@code bool}.</blockquote>
   */
  Object visitArgumentDefinitionTest(ArgumentDefinitionTest node) {
    recordStaticType(node, _typeProvider.boolType);
    return null;
  }

  /**
   * The Dart Language Specification, 12.32: <blockquote>... the cast expression <i>e as T</i> ...
   * <p>
   * It is a static warning if <i>T</i> does not denote a type available in the current lexical
   * scope.
   * <p>
   * The static type of a cast expression <i>e as T</i> is <i>T</i>.</blockquote>
   */
  Object visitAsExpression(AsExpression node) {
    recordStaticType(node, getType2(node.type));
    return null;
  }

  /**
   * The Dart Language Specification, 12.18: <blockquote>... an assignment <i>a</i> of the form <i>v
   * = e</i> ...
   * <p>
   * It is a static type warning if the static type of <i>e</i> may not be assigned to the static
   * type of <i>v</i>.
   * <p>
   * The static type of the expression <i>v = e</i> is the static type of <i>e</i>.
   * <p>
   * ... an assignment of the form <i>C.v = e</i> ...
   * <p>
   * It is a static type warning if the static type of <i>e</i> may not be assigned to the static
   * type of <i>C.v</i>.
   * <p>
   * The static type of the expression <i>C.v = e</i> is the static type of <i>e</i>.
   * <p>
   * ... an assignment of the form <i>e<sub>1</sub>.v = e<sub>2</sub></i> ...
   * <p>
   * Let <i>T</i> be the static type of <i>e<sub>1</sub></i>. It is a static type warning if
   * <i>T</i> does not have an accessible instance setter named <i>v=</i>. It is a static type
   * warning if the static type of <i>e<sub>2</sub></i> may not be assigned to <i>T</i>.
   * <p>
   * The static type of the expression <i>e<sub>1</sub>.v = e<sub>2</sub></i> is the static type of
   * <i>e<sub>2</sub></i>.
   * <p>
   * ... an assignment of the form <i>e<sub>1</sub>\[e<sub>2</sub>\] = e<sub>3</sub></i> ...
   * <p>
   * The static type of the expression <i>e<sub>1</sub>\[e<sub>2</sub>\] = e<sub>3</sub></i> is the
   * static type of <i>e<sub>3</sub></i>.
   * <p>
   * A compound assignment of the form <i>v op= e</i> is equivalent to <i>v = v op e</i>. A compound
   * assignment of the form <i>C.v op= e</i> is equivalent to <i>C.v = C.v op e</i>. A compound
   * assignment of the form <i>e<sub>1</sub>.v op= e<sub>2</sub></i> is equivalent to <i>((x) => x.v
   * = x.v op e<sub>2</sub>)(e<sub>1</sub>)</i> where <i>x</i> is a variable that is not used in
   * <i>e<sub>2</sub></i>. A compound assignment of the form <i>e<sub>1</sub>\[e<sub>2</sub>\] op=
   * e<sub>3</sub></i> is equivalent to <i>((a, i) => a\[i\] = a\[i\] op e<sub>3</sub>)(e<sub>1</sub>,
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
      Type2 propagatedType = getPropagatedType(rightHandSide);
      if (propagatedType != null) {
        if (propagatedType.isMoreSpecificThan(staticType)) {
          recordPropagatedType(node, propagatedType);
        }
        overrideType = propagatedType;
      }
      VariableElement element = _resolver.getOverridableElement(node.leftHandSide);
      if (element != null) {
        _resolver.override(element, overrideType);
      }
    } else {
      ExecutableElement staticMethodElement = node.staticElement;
      Type2 staticType = computeReturnType(staticMethodElement);
      recordStaticType(node, staticType);
      MethodElement propagatedMethodElement = node.element;
      if (propagatedMethodElement != staticMethodElement) {
        Type2 propagatedType = computeReturnType(propagatedMethodElement);
        if (propagatedType != null && propagatedType.isMoreSpecificThan(staticType)) {
          recordPropagatedType(node, propagatedType);
        }
      }
    }
    return null;
  }

  /**
   * The Dart Language Specification, 12.20: <blockquote>The static type of a logical boolean
   * expression is {@code bool}.</blockquote>
   * <p>
   * The Dart Language Specification, 12.21:<blockquote>A bitwise expression of the form
   * <i>e<sub>1</sub> op e<sub>2</sub></i> is equivalent to the method invocation
   * <i>e<sub>1</sub>.op(e<sub>2</sub>)</i>. A bitwise expression of the form <i>super op
   * e<sub>2</sub></i> is equivalent to the method invocation
   * <i>super.op(e<sub>2</sub>)</i>.</blockquote>
   * <p>
   * The Dart Language Specification, 12.22: <blockquote>The static type of an equality expression
   * is {@code bool}.</blockquote>
   * <p>
   * The Dart Language Specification, 12.23: <blockquote>A relational expression of the form
   * <i>e<sub>1</sub> op e<sub>2</sub></i> is equivalent to the method invocation
   * <i>e<sub>1</sub>.op(e<sub>2</sub>)</i>. A relational expression of the form <i>super op
   * e<sub>2</sub></i> is equivalent to the method invocation
   * <i>super.op(e<sub>2</sub>)</i>.</blockquote>
   * <p>
   * The Dart Language Specification, 12.24: <blockquote>A shift expression of the form
   * <i>e<sub>1</sub> op e<sub>2</sub></i> is equivalent to the method invocation
   * <i>e<sub>1</sub>.op(e<sub>2</sub>)</i>. A shift expression of the form <i>super op
   * e<sub>2</sub></i> is equivalent to the method invocation
   * <i>super.op(e<sub>2</sub>)</i>.</blockquote>
   * <p>
   * The Dart Language Specification, 12.25: <blockquote>An additive expression of the form
   * <i>e<sub>1</sub> op e<sub>2</sub></i> is equivalent to the method invocation
   * <i>e<sub>1</sub>.op(e<sub>2</sub>)</i>. An additive expression of the form <i>super op
   * e<sub>2</sub></i> is equivalent to the method invocation
   * <i>super.op(e<sub>2</sub>)</i>.</blockquote>
   * <p>
   * The Dart Language Specification, 12.26: <blockquote>A multiplicative expression of the form
   * <i>e<sub>1</sub> op e<sub>2</sub></i> is equivalent to the method invocation
   * <i>e<sub>1</sub>.op(e<sub>2</sub>)</i>. A multiplicative expression of the form <i>super op
   * e<sub>2</sub></i> is equivalent to the method invocation
   * <i>super.op(e<sub>2</sub>)</i>.</blockquote>
   */
  Object visitBinaryExpression(BinaryExpression node) {
    ExecutableElement staticMethodElement = node.staticElement;
    Type2 staticType = computeReturnType(staticMethodElement);
    staticType = refineBinaryExpressionType(node, staticType);
    recordStaticType(node, staticType);
    MethodElement propagatedMethodElement = node.element;
    if (propagatedMethodElement != staticMethodElement) {
      Type2 propagatedType = computeReturnType(propagatedMethodElement);
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
    recordPropagatedType(node, getPropagatedType(node.target));
    return null;
  }

  /**
   * The Dart Language Specification, 12.19: <blockquote> ... a conditional expression <i>c</i> of
   * the form <i>e<sub>1</sub> ? e<sub>2</sub> : e<sub>3</sub></i> ...
   * <p>
   * It is a static type warning if the type of e<sub>1</sub> may not be assigned to {@code bool}.
   * <p>
   * The static type of <i>c</i> is the least upper bound of the static type of <i>e<sub>2</sub></i>
   * and the static type of <i>e<sub>3</sub></i>.</blockquote>
   */
  Object visitConditionalExpression(ConditionalExpression node) {
    Type2 staticThenType = getStaticType(node.thenExpression);
    Type2 staticElseType = getStaticType(node.elseExpression);
    if (staticThenType == null) {
      staticThenType = _dynamicType;
    }
    if (staticElseType == null) {
      staticElseType = _dynamicType;
    }
    Type2 staticType = staticThenType.getLeastUpperBound(staticElseType);
    if (staticType == null) {
      staticType = _dynamicType;
    }
    recordStaticType(node, staticType);
    Type2 propagatedThenType = getPropagatedType(node.thenExpression);
    Type2 propagatedElseType = getPropagatedType(node.elseExpression);
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
    FunctionTypeImpl functionType = node.element.type as FunctionTypeImpl;
    setTypeInformation(functionType, computeReturnType2(node), function.parameters);
    recordStaticType(function, functionType);
    return null;
  }

  /**
   * The Dart Language Specification, 12.9: <blockquote>The static type of a function literal of the
   * form <i>(T<sub>1</sub> a<sub>1</sub>, &hellip;, T<sub>n</sub> a<sub>n</sub>, \[T<sub>n+1</sub>
   * x<sub>n+1</sub> = d1, &hellip;, T<sub>n+k</sub> x<sub>n+k</sub> = dk\]) => e</i> is
   * <i>(T<sub>1</sub>, &hellip;, Tn, \[T<sub>n+1</sub> x<sub>n+1</sub>, &hellip;, T<sub>n+k</sub>
   * x<sub>n+k</sub>\]) &rarr; T<sub>0</sub></i>, where <i>T<sub>0</sub></i> is the static type of
   * <i>e</i>. In any case where <i>T<sub>i</sub>, 1 &lt;= i &lt;= n</i>, is not specified, it is
   * considered to have been specified as dynamic.
   * <p>
   * The static type of a function literal of the form <i>(T<sub>1</sub> a<sub>1</sub>, &hellip;,
   * T<sub>n</sub> a<sub>n</sub>, {T<sub>n+1</sub> x<sub>n+1</sub> : d1, &hellip;, T<sub>n+k</sub>
   * x<sub>n+k</sub> : dk}) => e</i> is <i>(T<sub>1</sub>, &hellip;, T<sub>n</sub>, {T<sub>n+1</sub>
   * x<sub>n+1</sub>, &hellip;, T<sub>n+k</sub> x<sub>n+k</sub>}) &rarr; T<sub>0</sub></i>, where
   * <i>T<sub>0</sub></i> is the static type of <i>e</i>. In any case where <i>T<sub>i</sub>, 1
   * &lt;= i &lt;= n</i>, is not specified, it is considered to have been specified as dynamic.
   * <p>
   * The static type of a function literal of the form <i>(T<sub>1</sub> a<sub>1</sub>, &hellip;,
   * T<sub>n</sub> a<sub>n</sub>, \[T<sub>n+1</sub> x<sub>n+1</sub> = d1, &hellip;, T<sub>n+k</sub>
   * x<sub>n+k</sub> = dk\]) {s}</i> is <i>(T<sub>1</sub>, &hellip;, T<sub>n</sub>, \[T<sub>n+1</sub>
   * x<sub>n+1</sub>, &hellip;, T<sub>n+k</sub> x<sub>n+k</sub>\]) &rarr; dynamic</i>. In any case
   * where <i>T<sub>i</sub>, 1 &lt;= i &lt;= n</i>, is not specified, it is considered to have been
   * specified as dynamic.
   * <p>
   * The static type of a function literal of the form <i>(T<sub>1</sub> a<sub>1</sub>, &hellip;,
   * T<sub>n</sub> a<sub>n</sub>, {T<sub>n+1</sub> x<sub>n+1</sub> : d1, &hellip;, T<sub>n+k</sub>
   * x<sub>n+k</sub> : dk}) {s}</i> is <i>(T<sub>1</sub>, &hellip;, T<sub>n</sub>, {T<sub>n+1</sub>
   * x<sub>n+1</sub>, &hellip;, T<sub>n+k</sub> x<sub>n+k</sub>}) &rarr; dynamic</i>. In any case
   * where <i>T<sub>i</sub>, 1 &lt;= i &lt;= n</i>, is not specified, it is considered to have been
   * specified as dynamic.</blockquote>
   */
  Object visitFunctionExpression(FunctionExpression node) {
    if (node.parent is FunctionDeclaration) {
      return null;
    }
    FunctionTypeImpl functionType = node.element.type as FunctionTypeImpl;
    setTypeInformation(functionType, computeReturnType3(node), node.parameters);
    recordStaticType(node, functionType);
    return null;
  }

  /**
   * The Dart Language Specification, 12.14.4: <blockquote>A function expression invocation <i>i</i>
   * has the form <i>e<sub>f</sub>(a<sub>1</sub>, &hellip;, a<sub>n</sub>, x<sub>n+1</sub>:
   * a<sub>n+1</sub>, &hellip;, x<sub>n+k</sub>: a<sub>n+k</sub>)</i>, where <i>e<sub>f</sub></i> is
   * an expression.
   * <p>
   * It is a static type warning if the static type <i>F</i> of <i>e<sub>f</sub></i> may not be
   * assigned to a function type.
   * <p>
   * If <i>F</i> is not a function type, the static type of <i>i</i> is dynamic. Otherwise the
   * static type of <i>i</i> is the declared return type of <i>F</i>.</blockquote>
   */
  Object visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    ExecutableElement staticMethodElement = node.staticElement;
    Type2 staticType = computeReturnType(staticMethodElement);
    recordStaticType(node, staticType);
    ExecutableElement propagatedMethodElement = node.element;
    Type2 propagatedType = computeReturnType(propagatedMethodElement);
    if (staticType == null) {
      recordStaticType(node, propagatedType);
    } else if (propagatedType != null && propagatedType.isMoreSpecificThan(staticType)) {
      recordPropagatedType(node, propagatedType);
    }
    return null;
  }

  /**
   * The Dart Language Specification, 12.29: <blockquote>An assignable expression of the form
   * <i>e<sub>1</sub>\[e<sub>2</sub>\]</i> is evaluated as a method invocation of the operator method
   * <i>\[\]</i> on <i>e<sub>1</sub></i> with argument <i>e<sub>2</sub></i>.</blockquote>
   */
  Object visitIndexExpression(IndexExpression node) {
    if (node.inSetterContext()) {
      ExecutableElement staticMethodElement = node.staticElement;
      Type2 staticType = computeArgumentType(staticMethodElement);
      recordStaticType(node, staticType);
      MethodElement propagatedMethodElement = node.element;
      if (propagatedMethodElement != staticMethodElement) {
        Type2 propagatedType = computeArgumentType(propagatedMethodElement);
        if (propagatedType != null && propagatedType.isMoreSpecificThan(staticType)) {
          recordPropagatedType(node, propagatedType);
        }
      }
    } else {
      ExecutableElement staticMethodElement = node.staticElement;
      Type2 staticType = computeReturnType(staticMethodElement);
      recordStaticType(node, staticType);
      MethodElement propagatedMethodElement = node.element;
      if (propagatedMethodElement != staticMethodElement) {
        Type2 propagatedType = computeReturnType(propagatedMethodElement);
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
   * <p>
   * The Dart Language Specification, 12.11.2: <blockquote>The static type of a constant object
   * expression of either the form <i>const T.id(a<sub>1</sub>, &hellip;, a<sub>n</sub>)</i> or the
   * form <i>const T(a<sub>1</sub>, &hellip;, a<sub>n</sub>)</i> is <i>T</i>. </blockquote>
   */
  Object visitInstanceCreationExpression(InstanceCreationExpression node) {
    recordStaticType(node, node.constructorName.type.type);
    ConstructorElement element = node.element;
    if (element != null && "Element" == element.enclosingElement.name && "tag" == element.name) {
      LibraryElement library = element.library;
      if (isHtmlLibrary(library)) {
        Type2 returnType = getFirstArgumentAsType2(library, node.argumentList, _HTML_ELEMENT_TO_CLASS_MAP);
        if (returnType != null) {
          recordPropagatedType(node, returnType);
        }
      }
    }
    return null;
  }

  /**
   * The Dart Language Specification, 12.3: <blockquote>The static type of an integer literal is{@code int}.</blockquote>
   */
  Object visitIntegerLiteral(IntegerLiteral node) {
    recordStaticType(node, _typeProvider.intType);
    return null;
  }

  /**
   * The Dart Language Specification, 12.31: <blockquote>It is a static warning if <i>T</i> does not
   * denote a type available in the current lexical scope.
   * <p>
   * The static type of an is-expression is {@code bool}.</blockquote>
   */
  Object visitIsExpression(IsExpression node) {
    recordStaticType(node, _typeProvider.boolType);
    return null;
  }

  /**
   * The Dart Language Specification, 12.6: <blockquote>The static type of a list literal of the
   * form <i><b>const</b> &lt;E&gt;\[e<sub>1</sub>, &hellip;, e<sub>n</sub>\]</i> or the form
   * <i>&lt;E&gt;\[e<sub>1</sub>, &hellip;, e<sub>n</sub>\]</i> is {@code List&lt;E&gt;}. The static
   * type a list literal of the form <i><b>const</b> \[e<sub>1</sub>, &hellip;, e<sub>n</sub>\]</i> or
   * the form <i>\[e<sub>1</sub>, &hellip;, e<sub>n</sub>\]</i> is {@code List&lt;dynamic&gt;}.</blockquote>
   */
  Object visitListLiteral(ListLiteral node) {
    Type2 staticType = _dynamicType;
    TypeArgumentList typeArguments = node.typeArguments;
    if (typeArguments != null) {
      NodeList<TypeName> arguments = typeArguments.arguments;
      if (arguments != null && arguments.length == 1) {
        TypeName argumentTypeName = arguments[0];
        Type2 argumentType = getType2(argumentTypeName);
        if (argumentType != null) {
          staticType = argumentType;
        }
      }
    }
    recordStaticType(node, _typeProvider.listType.substitute5(<Type2> [staticType]));
    NodeList<Expression> elements = node.elements;
    int count = elements.length;
    if (count > 0) {
      Type2 propagatedType = getBestType(elements[0]);
      for (int i = 1; i < count; i++) {
        Type2 elementType = getBestType(elements[i]);
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
        recordPropagatedType(node, _typeProvider.listType.substitute5(<Type2> [propagatedType]));
      }
    }
    return null;
  }

  /**
   * The Dart Language Specification, 12.7: <blockquote>The static type of a map literal of the form
   * <i><b>const</b> &lt;String, V&gt; {k<sub>1</sub>:e<sub>1</sub>, &hellip;,
   * k<sub>n</sub>:e<sub>n</sub>}</i> or the form <i>&lt;String, V&gt; {k<sub>1</sub>:e<sub>1</sub>,
   * &hellip;, k<sub>n</sub>:e<sub>n</sub>}</i> is {@code Map&lt;String, V&gt;}. The static type a
   * map literal of the form <i><b>const</b> {k<sub>1</sub>:e<sub>1</sub>, &hellip;,
   * k<sub>n</sub>:e<sub>n</sub>}</i> or the form <i>{k<sub>1</sub>:e<sub>1</sub>, &hellip;,
   * k<sub>n</sub>:e<sub>n</sub>}</i> is {@code Map&lt;String, dynamic&gt;}.
   * <p>
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
        Type2 entryKeyType = getType2(entryKeyTypeName);
        if (entryKeyType != null) {
          staticKeyType = entryKeyType;
        }
        TypeName entryValueTypeName = arguments[1];
        Type2 entryValueType = getType2(entryValueTypeName);
        if (entryValueType != null) {
          staticValueType = entryValueType;
        }
      }
    }
    recordStaticType(node, _typeProvider.mapType.substitute5(<Type2> [staticKeyType, staticValueType]));
    NodeList<MapLiteralEntry> entries = node.entries;
    int count = entries.length;
    if (count > 0) {
      MapLiteralEntry entry = entries[0];
      Type2 propagatedKeyType = getBestType(entry.key);
      Type2 propagatedValueType = getBestType(entry.value);
      for (int i = 1; i < count; i++) {
        entry = entries[i];
        Type2 elementKeyType = getBestType(entry.key);
        if (propagatedKeyType != elementKeyType) {
          propagatedKeyType = _dynamicType;
        } else {
          propagatedKeyType = propagatedKeyType.getLeastUpperBound(elementKeyType);
          if (propagatedKeyType == null) {
            propagatedKeyType = _dynamicType;
          }
        }
        Type2 elementValueType = getBestType(entry.value);
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
        recordPropagatedType(node, _typeProvider.mapType.substitute5(<Type2> [propagatedKeyType, propagatedValueType]));
      }
    }
    return null;
  }

  /**
   * The Dart Language Specification, 12.15.1: <blockquote>An ordinary method invocation <i>i</i>
   * has the form <i>o.m(a<sub>1</sub>, &hellip;, a<sub>n</sub>, x<sub>n+1</sub>: a<sub>n+1</sub>,
   * &hellip;, x<sub>n+k</sub>: a<sub>n+k</sub>)</i>.
   * <p>
   * Let <i>T</i> be the static type of <i>o</i>. It is a static type warning if <i>T</i> does not
   * have an accessible instance member named <i>m</i>. If <i>T.m</i> exists, it is a static warning
   * if the type <i>F</i> of <i>T.m</i> may not be assigned to a function type.
   * <p>
   * If <i>T.m</i> does not exist, or if <i>F</i> is not a function type, the static type of
   * <i>i</i> is dynamic. Otherwise the static type of <i>i</i> is the declared return type of
   * <i>F</i>.</blockquote>
   * <p>
   * The Dart Language Specification, 11.15.3: <blockquote>A static method invocation <i>i</i> has
   * the form <i>C.m(a<sub>1</sub>, &hellip;, a<sub>n</sub>, x<sub>n+1</sub>: a<sub>n+1</sub>,
   * &hellip;, x<sub>n+k</sub>: a<sub>n+k</sub>)</i>.
   * <p>
   * It is a static type warning if the type <i>F</i> of <i>C.m</i> may not be assigned to a
   * function type.
   * <p>
   * If <i>F</i> is not a function type, or if <i>C.m</i> does not exist, the static type of i is
   * dynamic. Otherwise the static type of <i>i</i> is the declared return type of
   * <i>F</i>.</blockquote>
   * <p>
   * The Dart Language Specification, 11.15.4: <blockquote>A super method invocation <i>i</i> has
   * the form <i>super.m(a<sub>1</sub>, &hellip;, a<sub>n</sub>, x<sub>n+1</sub>: a<sub>n+1</sub>,
   * &hellip;, x<sub>n+k</sub>: a<sub>n+k</sub>)</i>.
   * <p>
   * It is a static type warning if <i>S</i> does not have an accessible instance member named m. If
   * <i>S.m</i> exists, it is a static warning if the type <i>F</i> of <i>S.m</i> may not be
   * assigned to a function type.
   * <p>
   * If <i>S.m</i> does not exist, or if <i>F</i> is not a function type, the static type of
   * <i>i</i> is dynamic. Otherwise the static type of <i>i</i> is the declared return type of
   * <i>F</i>.</blockquote>
   */
  Object visitMethodInvocation(MethodInvocation node) {
    SimpleIdentifier methodNameNode = node.methodName;
    Element staticMethodElement = methodNameNode.staticElement;
    if (staticMethodElement == null) {
      staticMethodElement = methodNameNode.element;
    }
    Type2 staticType = computeReturnType(staticMethodElement);
    recordStaticType(node, staticType);
    String methodName = methodNameNode.name;
    if (methodName == "\$dom_createEvent") {
      Expression target = node.realTarget;
      if (target != null) {
        Type2 targetType = getBestType(target);
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
        Element methodElement = methodNameNode.element;
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
        Type2 targetType = getBestType(target);
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
      Type2 targetType = getBestType(target);
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
      Element propagatedElement = methodNameNode.element;
      if (propagatedElement != staticMethodElement) {
        Type2 propagatedType = computeReturnType(propagatedElement);
        if (propagatedType != null && propagatedType.isMoreSpecificThan(staticType)) {
          recordPropagatedType(node, propagatedType);
        }
      }
    }
    return null;
  }
  Object visitNamedExpression(NamedExpression node) {
    Expression expression = node.expression;
    recordStaticType(node, getStaticType(expression));
    recordPropagatedType(node, getPropagatedType(expression));
    return null;
  }

  /**
   * The Dart Language Specification, 12.2: <blockquote>The static type of {@code null} is bottom.
   * </blockquote>
   */
  Object visitNullLiteral(NullLiteral node) {
    recordStaticType(node, _typeProvider.bottomType);
    return null;
  }
  Object visitParenthesizedExpression(ParenthesizedExpression node) {
    Expression expression = node.expression;
    recordStaticType(node, getStaticType(expression));
    recordPropagatedType(node, getPropagatedType(expression));
    return null;
  }

  /**
   * The Dart Language Specification, 12.28: <blockquote>A postfix expression of the form
   * <i>v++</i>, where <i>v</i> is an identifier, is equivalent to <i>(){var r = v; v = r + 1;
   * return r}()</i>.
   * <p>
   * A postfix expression of the form <i>C.v++</i> is equivalent to <i>(){var r = C.v; C.v = r + 1;
   * return r}()</i>.
   * <p>
   * A postfix expression of the form <i>e1.v++</i> is equivalent to <i>(x){var r = x.v; x.v = r +
   * 1; return r}(e1)</i>.
   * <p>
   * A postfix expression of the form <i>e1\[e2\]++</i> is equivalent to <i>(a, i){var r = a\[i\]; a\[i\]
   * = r + 1; return r}(e1, e2)</i>
   * <p>
   * A postfix expression of the form <i>v--</i>, where <i>v</i> is an identifier, is equivalent to
   * <i>(){var r = v; v = r - 1; return r}()</i>.
   * <p>
   * A postfix expression of the form <i>C.v--</i> is equivalent to <i>(){var r = C.v; C.v = r - 1;
   * return r}()</i>.
   * <p>
   * A postfix expression of the form <i>e1.v--</i> is equivalent to <i>(x){var r = x.v; x.v = r -
   * 1; return r}(e1)</i>.
   * <p>
   * A postfix expression of the form <i>e1\[e2\]--</i> is equivalent to <i>(a, i){var r = a\[i\]; a\[i\]
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
    recordPropagatedType(node, getPropagatedType(operand));
    return null;
  }

  /**
   * See {@link #visitSimpleIdentifier(SimpleIdentifier)}.
   */
  Object visitPrefixedIdentifier(PrefixedIdentifier node) {
    SimpleIdentifier prefixedIdentifier = node.identifier;
    Element element = prefixedIdentifier.element;
    Type2 staticType = _dynamicType;
    if (element is ClassElement) {
      if (isNotTypeLiteral(node)) {
        staticType = ((element as ClassElement)).type;
      } else {
        staticType = _typeProvider.typeType;
      }
    } else if (element is FunctionTypeAliasElement) {
      staticType = ((element as FunctionTypeAliasElement)).type;
    } else if (element is MethodElement) {
      staticType = ((element as MethodElement)).type;
    } else if (element is PropertyAccessorElement) {
      staticType = getType((element as PropertyAccessorElement), node.prefix.staticType);
    } else if (element is ExecutableElement) {
      staticType = ((element as ExecutableElement)).type;
    } else if (element is TypeVariableElement) {
      staticType = ((element as TypeVariableElement)).type;
    } else if (element is VariableElement) {
      staticType = ((element as VariableElement)).type;
    }
    recordStaticType(prefixedIdentifier, staticType);
    recordStaticType(node, staticType);
    Type2 propagatedType = _overrideManager.getType(element);
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
      ExecutableElement staticMethodElement = node.staticElement;
      Type2 staticType = computeReturnType(staticMethodElement);
      if (identical(operator, sc.TokenType.MINUS_MINUS) || identical(operator, sc.TokenType.PLUS_PLUS)) {
        Type2 intType = _typeProvider.intType;
        if (identical(getStaticType(node.operand), intType)) {
          staticType = intType;
        }
      }
      recordStaticType(node, staticType);
      MethodElement propagatedMethodElement = node.element;
      if (propagatedMethodElement != staticMethodElement) {
        Type2 propagatedType = computeReturnType(propagatedMethodElement);
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
   * <ul>
   * <li><i>o.m</i> is defined to be equivalent to: <i>(r<sub>1</sub>, &hellip;, r<sub>n</sub>,
   * {p<sub>1</sub> : d<sub>1</sub>, &hellip;, p<sub>k</sub> : d<sub>k</sub>}){return
   * o.m(r<sub>1</sub>, &hellip;, r<sub>n</sub>, p<sub>1</sub>: p<sub>1</sub>, &hellip;,
   * p<sub>k</sub>: p<sub>k</sub>);}</i> if <i>m</i> has required parameters <i>r<sub>1</sub>,
   * &hellip;, r<sub>n</sub></i>, and named parameters <i>p<sub>1</sub> &hellip; p<sub>k</sub></i>
   * with defaults <i>d<sub>1</sub>, &hellip;, d<sub>k</sub></i>.</li>
   * <li><i>(r<sub>1</sub>, &hellip;, r<sub>n</sub>, \[p<sub>1</sub> = d<sub>1</sub>, &hellip;,
   * p<sub>k</sub> = d<sub>k</sub>\]){return o.m(r<sub>1</sub>, &hellip;, r<sub>n</sub>,
   * p<sub>1</sub>, &hellip;, p<sub>k</sub>);}</i> if <i>m</i> has required parameters
   * <i>r<sub>1</sub>, &hellip;, r<sub>n</sub></i>, and optional positional parameters
   * <i>p<sub>1</sub> &hellip; p<sub>k</sub></i> with defaults <i>d<sub>1</sub>, &hellip;,
   * d<sub>k</sub></i>.</li>
   * </ul>
   * Otherwise, if <i>m</i> is the name of a getter member of <i>o</i> (declared implicitly or
   * explicitly) then <i>o.m</i> evaluates to the result of invoking the getter. </blockquote>
   * <p>
   * The Dart Language Specification, 12.17: <blockquote> ... a getter invocation <i>i</i> of the
   * form <i>e.m</i> ...
   * <p>
   * Let <i>T</i> be the static type of <i>e</i>. It is a static type warning if <i>T</i> does not
   * have a getter named <i>m</i>.
   * <p>
   * The static type of <i>i</i> is the declared return type of <i>T.m</i>, if <i>T.m</i> exists;
   * otherwise the static type of <i>i</i> is dynamic.
   * <p>
   * ... a getter invocation <i>i</i> of the form <i>C.m</i> ...
   * <p>
   * It is a static warning if there is no class <i>C</i> in the enclosing lexical scope of
   * <i>i</i>, or if <i>C</i> does not declare, implicitly or explicitly, a getter named <i>m</i>.
   * <p>
   * The static type of <i>i</i> is the declared return type of <i>C.m</i> if it exists or dynamic
   * otherwise.
   * <p>
   * ... a top-level getter invocation <i>i</i> of the form <i>m</i>, where <i>m</i> is an
   * identifier ...
   * <p>
   * The static type of <i>i</i> is the declared return type of <i>m</i>.</blockquote>
   */
  Object visitPropertyAccess(PropertyAccess node) {
    SimpleIdentifier propertyName = node.propertyName;
    Element element = propertyName.element;
    Type2 staticType = _dynamicType;
    if (element is MethodElement) {
      staticType = ((element as MethodElement)).type;
    } else if (element is PropertyAccessorElement) {
      staticType = getType((element as PropertyAccessorElement), node.target != null ? getStaticType(node.target) : null);
    } else {
    }
    recordStaticType(propertyName, staticType);
    recordStaticType(node, staticType);
    Type2 propagatedType = _overrideManager.getType(element);
    if (propagatedType != null && propagatedType.isMoreSpecificThan(staticType)) {
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
   * <p>
   * Let <i>d</i> be the innermost declaration in the enclosing lexical scope whose name is
   * <i>id</i>. If no such declaration exists in the lexical scope, let <i>d</i> be the declaration
   * of the inherited member named <i>id</i> if it exists.
   * <ul>
   * <li>If <i>d</i> is a class or type alias <i>T</i>, the value of <i>e</i> is the unique instance
   * of class {@code Type} reifying <i>T</i>.
   * <li>If <i>d</i> is a type parameter <i>T</i>, then the value of <i>e</i> is the value of the
   * actual type argument corresponding to <i>T</i> that was passed to the generative constructor
   * that created the current binding of this. We are assured that this is well defined, because if
   * we were in a static member the reference to <i>T</i> would be a compile-time error.
   * <li>If <i>d</i> is a library variable then:
   * <ul>
   * <li>If <i>d</i> is of one of the forms <i>var v = e<sub>i</sub>;</i>, <i>T v =
   * e<sub>i</sub>;</i>, <i>final v = e<sub>i</sub>;</i>, <i>final T v = e<sub>i</sub>;</i>, and no
   * value has yet been stored into <i>v</i> then the initializer expression <i>e<sub>i</sub></i> is
   * evaluated. If, during the evaluation of <i>e<sub>i</sub></i>, the getter for <i>v</i> is
   * referenced, a CyclicInitializationError is thrown. If the evaluation succeeded yielding an
   * object <i>o</i>, let <i>r = o</i>, otherwise let <i>r = null</i>. In any case, <i>r</i> is
   * stored into <i>v</i>. The value of <i>e</i> is <i>r</i>.
   * <li>If <i>d</i> is of one of the forms <i>const v = e;</i> or <i>const T v = e;</i> the result
   * of the getter is the value of the compile time constant <i>e</i>. Otherwise
   * <li><i>e</i> evaluates to the current binding of <i>id</i>.
   * </ul>
   * <li>If <i>d</i> is a local variable or formal parameter then <i>e</i> evaluates to the current
   * binding of <i>id</i>.
   * <li>If <i>d</i> is a static method, top level function or local function then <i>e</i>
   * evaluates to the function defined by <i>d</i>.
   * <li>If <i>d</i> is the declaration of a static variable or static getter declared in class
   * <i>C</i>, then <i>e</i> is equivalent to the getter invocation <i>C.id</i>.
   * <li>If <i>d</i> is the declaration of a top level getter, then <i>e</i> is equivalent to the
   * getter invocation <i>id</i>.
   * <li>Otherwise, if <i>e</i> occurs inside a top level or static function (be it function,
   * method, getter, or setter) or variable initializer, evaluation of e causes a NoSuchMethodError
   * to be thrown.
   * <li>Otherwise <i>e</i> is equivalent to the property extraction <i>this.id</i>.
   * </ul>
   * </blockquote>
   */
  Object visitSimpleIdentifier(SimpleIdentifier node) {
    Element element = node.element;
    Type2 staticType = _dynamicType;
    if (element is ClassElement) {
      if (isNotTypeLiteral(node)) {
        staticType = ((element as ClassElement)).type;
      } else {
        staticType = _typeProvider.typeType;
      }
    } else if (element is FunctionTypeAliasElement) {
      staticType = ((element as FunctionTypeAliasElement)).type;
    } else if (element is MethodElement) {
      staticType = ((element as MethodElement)).type;
    } else if (element is PropertyAccessorElement) {
      staticType = getType((element as PropertyAccessorElement), null);
    } else if (element is ExecutableElement) {
      staticType = ((element as ExecutableElement)).type;
    } else if (element is TypeVariableElement) {
      staticType = ((element as TypeVariableElement)).type;
    } else if (element is VariableElement) {
      staticType = ((element as VariableElement)).type;
    } else if (element is PrefixElement) {
      return null;
    } else {
      staticType = _dynamicType;
    }
    recordStaticType(node, staticType);
    Type2 propagatedType = _overrideManager.getType(element);
    if (propagatedType != null && propagatedType.isMoreSpecificThan(staticType)) {
      recordPropagatedType(node, propagatedType);
    }
    return null;
  }

  /**
   * The Dart Language Specification, 12.5: <blockquote>The static type of a string literal is{@code String}.</blockquote>
   */
  Object visitSimpleStringLiteral(SimpleStringLiteral node) {
    recordStaticType(node, _typeProvider.stringType);
    return null;
  }

  /**
   * The Dart Language Specification, 12.5: <blockquote>The static type of a string literal is{@code String}.</blockquote>
   */
  Object visitStringInterpolation(StringInterpolation node) {
    recordStaticType(node, _typeProvider.stringType);
    return null;
  }
  Object visitSuperExpression(SuperExpression node) {
    if (_thisType == null) {
      recordStaticType(node, _dynamicType);
    } else {
      recordStaticType(node, _thisType);
    }
    return null;
  }

  /**
   * The Dart Language Specification, 12.10: <blockquote>The static type of {@code this} is the
   * interface of the immediately enclosing class.</blockquote>
   */
  Object visitThisExpression(ThisExpression node) {
    if (_thisType == null) {
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
      Type2 rightType = getBestType(initializer);
      VariableElement element = node.name.element as VariableElement;
      if (element != null) {
        _resolver.override(element, rightType);
      }
    }
    return null;
  }

  /**
   * Record that the static type of the given node is the type of the second argument to the method
   * represented by the given element.
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
   * Compute the return type of the method or function represented by the given element.
   * @param element the element representing the method or function invoked by the given node
   * @return the return type that was computed
   */
  Type2 computeReturnType(Element element) {
    if (element is PropertyAccessorElement) {
      FunctionType propertyType = ((element as PropertyAccessorElement)).type;
      if (propertyType != null) {
        Type2 returnType = propertyType.returnType;
        if (returnType is InterfaceType) {
          if (identical(returnType, _typeProvider.functionType)) {
            return _dynamicType;
          }
          MethodElement callMethod = ((returnType as InterfaceType)).lookUpMethod(ElementResolver.CALL_METHOD_NAME, _resolver.definingLibrary);
          if (callMethod != null) {
            return callMethod.type.returnType;
          }
        } else if (returnType is FunctionType) {
          Type2 innerReturnType = ((returnType as FunctionType)).returnType;
          if (innerReturnType != null) {
            return innerReturnType;
          }
        } else if (returnType.isDartCoreFunction()) {
          return _dynamicType;
        }
        if (returnType != null) {
          return returnType;
        }
      }
    } else if (element is ExecutableElement) {
      FunctionType type = ((element as ExecutableElement)).type;
      if (type != null) {
        return type.returnType;
      }
    } else if (element is VariableElement) {
      Type2 variableType = ((element as VariableElement)).type;
      if (variableType is FunctionType) {
        return ((variableType as FunctionType)).returnType;
      }
    }
    return _dynamicType;
  }

  /**
   * Given a function declaration, compute the return type of the function. The return type of
   * functions with a block body is {@code dynamicType}, with an expression body it is the type of
   * the expression.
   * @param node the function expression whose return type is to be computed
   * @return the return type that was computed
   */
  Type2 computeReturnType2(FunctionDeclaration node) {
    TypeName returnType = node.returnType;
    if (returnType == null) {
      return _dynamicType;
    }
    return returnType.type;
  }

  /**
   * Given a function expression, compute the return type of the function. The return type of
   * functions with a block body is {@code dynamicType}, with an expression body it is the type of
   * the expression.
   * @param node the function expression whose return type is to be computed
   * @return the return type that was computed
   */
  Type2 computeReturnType3(FunctionExpression node) {
    FunctionBody body = node.body;
    if (body is ExpressionFunctionBody) {
      return getStaticType(((body as ExpressionFunctionBody)).expression);
    }
    return _dynamicType;
  }

  /**
   * Return the propagated type of the given expression if it is available, or the static type if
   * there is no propagated type.
   * @param expression the expression whose type is to be returned
   * @return the propagated or static type of the given expression
   */
  Type2 getBestType(Expression expression) {
    Type2 type = expression.propagatedType;
    if (type == null) {
      type = expression.staticType;
      if (type == null) {
        return _dynamicType;
      }
    }
    return type;
  }

  /**
   * If the given argument list contains at least one argument, and if the argument is a simple
   * string literal, then parse that argument as a query string and return the type specified by the
   * argument.
   * @param library the library in which the specified type would be defined
   * @param argumentList the list of arguments from which a type is to be extracted
   * @return the type specified by the first argument in the argument list
   */
  Type2 getFirstArgumentAsQuery(LibraryElement library, ArgumentList argumentList) {
    String argumentValue = getFirstArgumentAsString(argumentList);
    if (argumentValue != null) {
      if (argumentValue.contains(" ")) {
        return null;
      }
      String tag = argumentValue;
      tag = StringUtilities.substringBefore(tag, ":");
      tag = StringUtilities.substringBefore(tag, "[");
      tag = StringUtilities.substringBefore(tag, ".");
      tag = StringUtilities.substringBefore(tag, "#");
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
   * @param argumentList the list of arguments from which a string value is to be extracted
   * @return the string specified by the first argument in the argument list
   */
  String getFirstArgumentAsString(ArgumentList argumentList) {
    NodeList<Expression> arguments = argumentList.arguments;
    if (arguments.length > 0) {
      Expression argument = arguments[0];
      if (argument is SimpleStringLiteral) {
        return ((argument as SimpleStringLiteral)).value;
      }
    }
    return null;
  }

  /**
   * If the given argument list contains at least one argument, and if the argument is a simple
   * string literal, and if the value of the argument is the name of a class defined within the
   * given library, return the type specified by the argument.
   * @param library the library in which the specified type would be defined
   * @param argumentList the list of arguments from which a type is to be extracted
   * @return the type specified by the first argument in the argument list
   */
  Type2 getFirstArgumentAsType(LibraryElement library, ArgumentList argumentList) => getFirstArgumentAsType2(library, argumentList, null);

  /**
   * If the given argument list contains at least one argument, and if the argument is a simple
   * string literal, and if the value of the argument is the name of a class defined within the
   * given library, return the type specified by the argument.
   * @param library the library in which the specified type would be defined
   * @param argumentList the list of arguments from which a type is to be extracted
   * @return the type specified by the first argument in the argument list
   */
  Type2 getFirstArgumentAsType2(LibraryElement library, ArgumentList argumentList, Map<String, String> nameMap) {
    String argumentValue = getFirstArgumentAsString(argumentList);
    if (argumentValue != null) {
      if (nameMap != null) {
        argumentValue = nameMap[argumentValue.toLowerCase()];
      }
      ClassElement returnType = library.getType(argumentValue);
      if (returnType != null) {
        return returnType.type;
      }
    }
    return null;
  }

  /**
   * Return the propagated type of the given expression.
   * @param expression the expression whose type is to be returned
   * @return the propagated type of the given expression
   */
  Type2 getPropagatedType(Expression expression) {
    Type2 type = expression.propagatedType;
    return type;
  }

  /**
   * Return the static type of the given expression.
   * @param expression the expression whose type is to be returned
   * @return the static type of the given expression
   */
  Type2 getStaticType(Expression expression) {
    Type2 type = expression.staticType;
    if (type == null) {
      return _dynamicType;
    }
    return type;
  }

  /**
   * Return the type that should be recorded for a node that resolved to the given accessor.
   * @param accessor the accessor that the node resolved to
   * @param context if the accessor element has context \[by being the RHS of a{@link PrefixedIdentifier} or {@link PropertyAccess}\], and the return type of the
   * accessor is a parameter type, then the type of the LHS can be used to get more
   * specific type information
   * @return the type that should be recorded for a node that resolved to the given accessor
   */
  Type2 getType(PropertyAccessorElement accessor, Type2 context) {
    FunctionType functionType = accessor.type;
    if (functionType == null) {
      return _dynamicType;
    }
    if (accessor.isSetter()) {
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
    if (returnType is TypeVariableType && context is InterfaceType) {
      InterfaceType interfaceTypeContext = (context as InterfaceType);
      List<TypeVariableElement> parameterElements = interfaceTypeContext.element != null ? interfaceTypeContext.element.typeVariables : null;
      if (parameterElements != null) {
        for (int i = 0; i < parameterElements.length; i++) {
          TypeVariableElement varElt = parameterElements[i];
          if (returnType.name == varElt.name) {
            return interfaceTypeContext.typeArguments[i];
          }
        }
      }
    }
    return returnType;
  }

  /**
   * Return the type represented by the given type name.
   * @param typeName the type name representing the type to be returned
   * @return the type represented by the type name
   */
  Type2 getType2(TypeName typeName) {
    Type2 type = typeName.type;
    if (type == null) {
      return _dynamicType;
    }
    return type;
  }

  /**
   * Return {@code true} if the given library is the 'dart:html' library.
   * @param library the library being tested
   * @return {@code true} if the library is 'dart:html'
   */
  bool isHtmlLibrary(LibraryElement library) => library.name == "dart.dom.html";

  /**
   * Return {@code true} if the given node is not a type literal.
   * @param node the node being tested
   * @return {@code true} if the given node is not a type literal
   */
  bool isNotTypeLiteral(Identifier node) {
    ASTNode parent = node.parent;
    return parent is TypeName || (parent is PrefixedIdentifier && (parent.parent is TypeName || identical(((parent as PrefixedIdentifier)).prefix, node))) || (parent is PropertyAccess && identical(((parent as PropertyAccess)).target, node)) || (parent is MethodInvocation && identical(node, ((parent as MethodInvocation)).target));
  }

  /**
   * Record that the propagated type of the given node is the given type.
   * @param expression the node whose type is to be recorded
   * @param type the propagated type of the node
   */
  void recordPropagatedType(Expression expression, Type2 type) {
    if (type != null && !type.isDynamic()) {
      expression.propagatedType = type;
    }
  }

  /**
   * Record that the static type of the given node is the given type.
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
   * @param node the binary expression to analyze
   * @param staticType the static type of the expression as resolved
   * @return the better type guess, or the same static type as given
   */
  Type2 refineBinaryExpressionType(BinaryExpression node, Type2 staticType) {
    sc.TokenType operator = node.operator.type;
    if (identical(operator, sc.TokenType.AMPERSAND_AMPERSAND) || identical(operator, sc.TokenType.BAR_BAR) || identical(operator, sc.TokenType.EQ_EQ) || identical(operator, sc.TokenType.BANG_EQ)) {
      return _typeProvider.boolType;
    }
    if (identical(operator, sc.TokenType.MINUS) || identical(operator, sc.TokenType.PERCENT) || identical(operator, sc.TokenType.PLUS) || identical(operator, sc.TokenType.STAR)) {
      Type2 doubleType = _typeProvider.doubleType;
      if (identical(getStaticType(node.leftOperand), _typeProvider.intType) && identical(getStaticType(node.rightOperand), doubleType)) {
        return doubleType;
      }
    }
    if (identical(operator, sc.TokenType.MINUS) || identical(operator, sc.TokenType.PERCENT) || identical(operator, sc.TokenType.PLUS) || identical(operator, sc.TokenType.STAR) || identical(operator, sc.TokenType.TILDE_SLASH)) {
      Type2 intType = _typeProvider.intType;
      if (identical(getStaticType(node.leftOperand), intType) && identical(getStaticType(node.rightOperand), intType)) {
        staticType = intType;
      }
    }
    return staticType;
  }

  /**
   * Set the return type and parameter type information for the given function type based on the
   * given return type and parameter elements.
   * @param functionType the function type to be filled in
   * @param returnType the return type of the function, or {@code null} if no type was declared
   * @param parameters the elements representing the parameters to the function
   */
  void setTypeInformation(FunctionTypeImpl functionType, Type2 returnType2, FormalParameterList parameterList) {
    List<Type2> normalParameterTypes = new List<Type2>();
    List<Type2> optionalParameterTypes = new List<Type2>();
    LinkedHashMap<String, Type2> namedParameterTypes = new LinkedHashMap<String, Type2>();
    if (parameterList != null) {
      for (ParameterElement parameter in parameterList.elements) {
        while (true) {
          if (parameter.parameterKind == ParameterKind.REQUIRED) {
            normalParameterTypes.add(parameter.type);
          } else if (parameter.parameterKind == ParameterKind.POSITIONAL) {
            optionalParameterTypes.add(parameter.type);
          } else if (parameter.parameterKind == ParameterKind.NAMED) {
            namedParameterTypes[parameter.name] = parameter.type;
          }
          break;
        }
      }
    }
    functionType.normalParameterTypes = new List.from(normalParameterTypes);
    functionType.optionalParameterTypes = new List.from(optionalParameterTypes);
    functionType.namedParameterTypes = namedParameterTypes;
    functionType.returnType = returnType2;
  }
  get thisType_J2DAccessor => _thisType;
  set thisType_J2DAccessor(__v) => _thisType = __v;
}
/**
 * Instances of the class {@code TypeOverrideManager} manage the ability to override the type of an
 * element within a given context.
 */
class TypeOverrideManager {

  /**
   * The current override scope, or {@code null} if no scope has been entered.
   */
  TypeOverrideManager_TypeOverrideScope _currentScope;

  /**
   * Apply a set of overrides that were previously captured.
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
   * Return the overridden type of the given element, or {@code null} if the type of the element has
   * not been overridden.
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
 * Instances of the class {@code TypeOverrideScope} represent a scope in which the types of
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
   * @param outerScope the outer scope in which types might be overridden
   */
  TypeOverrideManager_TypeOverrideScope(TypeOverrideManager_TypeOverrideScope outerScope) {
    this._outerScope = outerScope;
  }

  /**
   * Apply a set of overrides that were previously captured.
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
   * @return the overrides in the current scope
   */
  Map<Element, Type2> captureLocalOverrides() => _overridenTypes;

  /**
   * Return a map from the elements for the variables in the given list that have their types
   * overridden to the overriding type.
   * @param variableList the list of variables whose overriding types are to be captured
   * @return a table mapping elements to their overriding types
   */
  Map<Element, Type2> captureOverrides(VariableDeclarationList variableList) {
    Map<Element, Type2> overrides = new Map<Element, Type2>();
    if (variableList.isConst() || variableList.isFinal()) {
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
   * Return the overridden type of the given element, or {@code null} if the type of the element
   * has not been overridden.
   * @param element the element whose type might have been overridden
   * @return the overridden type of the given element
   */
  Type2 getType(Element element) {
    Type2 type = _overridenTypes[element];
    if (type == null && element is PropertyAccessorElement) {
      type = _overridenTypes[((element as PropertyAccessorElement)).variable];
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
   * @param element the element whose type might have been overridden
   * @param type the overridden type of the given element
   */
  void setType(Element element, Type2 type) {
    _overridenTypes[element] = type;
  }
}
/**
 * The interface {@code TypeProvider} defines the behavior of objects that provide access to types
 * defined by the language.
 * @coverage dart.engine.resolver
 */
abstract class TypeProvider {

  /**
   * Return the type representing the built-in type 'bool'.
   * @return the type representing the built-in type 'bool'
   */
  InterfaceType get boolType;

  /**
   * Return the type representing the type 'bottom'.
   * @return the type representing the type 'bottom'
   */
  Type2 get bottomType;

  /**
   * Return the type representing the built-in type 'double'.
   * @return the type representing the built-in type 'double'
   */
  InterfaceType get doubleType;

  /**
   * Return the type representing the built-in type 'dynamic'.
   * @return the type representing the built-in type 'dynamic'
   */
  Type2 get dynamicType;

  /**
   * Return the type representing the built-in type 'Function'.
   * @return the type representing the built-in type 'Function'
   */
  InterfaceType get functionType;

  /**
   * Return the type representing the built-in type 'int'.
   * @return the type representing the built-in type 'int'
   */
  InterfaceType get intType;

  /**
   * Return the type representing the built-in type 'List'.
   * @return the type representing the built-in type 'List'
   */
  InterfaceType get listType;

  /**
   * Return the type representing the built-in type 'Map'.
   * @return the type representing the built-in type 'Map'
   */
  InterfaceType get mapType;

  /**
   * Return the type representing the built-in type 'num'.
   * @return the type representing the built-in type 'num'
   */
  InterfaceType get numType;

  /**
   * Return the type representing the built-in type 'Object'.
   * @return the type representing the built-in type 'Object'
   */
  InterfaceType get objectType;

  /**
   * Return the type representing the built-in type 'StackTrace'.
   * @return the type representing the built-in type 'StackTrace'
   */
  InterfaceType get stackTraceType;

  /**
   * Return the type representing the built-in type 'String'.
   * @return the type representing the built-in type 'String'
   */
  InterfaceType get stringType;

  /**
   * Return the type representing the built-in type 'Type'.
   * @return the type representing the built-in type 'Type'
   */
  InterfaceType get typeType;
}
/**
 * Instances of the class {@code TypeProviderImpl} provide access to types defined by the language
 * by looking for those types in the element model for the core library.
 * @coverage dart.engine.resolver
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
   * The type representing the built-in type 'Type'.
   */
  InterfaceType _typeType;

  /**
   * Initialize a newly created type provider to provide the types defined in the given library.
   * @param coreLibrary the element representing the core library (dart:core).
   */
  TypeProviderImpl(LibraryElement coreLibrary) {
    initializeFrom(coreLibrary);
  }
  InterfaceType get boolType => _boolType;
  Type2 get bottomType => _bottomType;
  InterfaceType get doubleType => _doubleType;
  Type2 get dynamicType => _dynamicType;
  InterfaceType get functionType => _functionType;
  InterfaceType get intType => _intType;
  InterfaceType get listType => _listType;
  InterfaceType get mapType => _mapType;
  InterfaceType get numType => _numType;
  InterfaceType get objectType => _objectType;
  InterfaceType get stackTraceType => _stackTraceType;
  InterfaceType get stringType => _stringType;
  InterfaceType get typeType => _typeType;

  /**
   * Return the type with the given name from the given namespace, or {@code null} if there is no
   * class with the given name.
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
    return ((element as ClassElement)).type;
  }

  /**
   * Initialize the types provided by this type provider from the given library.
   * @param library the library containing the definitions of the core types
   */
  void initializeFrom(LibraryElement library) {
    Namespace namespace = new NamespaceBuilder().createPublicNamespace(library);
    _boolType = getType(namespace, "bool");
    _bottomType = BottomTypeImpl.instance;
    _doubleType = getType(namespace, "double");
    _dynamicType = DynamicTypeImpl.instance;
    _functionType = getType(namespace, "Function");
    _intType = getType(namespace, "int");
    _listType = getType(namespace, "List");
    _mapType = getType(namespace, "Map");
    _numType = getType(namespace, "num");
    _objectType = getType(namespace, "Object");
    _stackTraceType = getType(namespace, "StackTrace");
    _stringType = getType(namespace, "String");
    _typeType = getType(namespace, "Type");
  }
}
/**
 * Instances of the class {@code TypeResolverVisitor} are used to resolve the types associated with
 * the elements in the element model. This includes the types of superclasses, mixins, interfaces,
 * fields, methods, parameters, and local variables. As a side-effect, this also finishes building
 * the type hierarchy.
 * @coverage dart.engine.resolver
 */
class TypeResolverVisitor extends ScopedVisitor {

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
   * @param library the library containing the compilation unit being resolved
   * @param source the source representing the compilation unit being visited
   * @param typeProvider the object used to access the types from the core library
   */
  TypeResolverVisitor.con1(Library library, Source source, TypeProvider typeProvider) : super.con1(library, source, typeProvider) {
    _jtd_constructor_281_impl(library, source, typeProvider);
  }
  _jtd_constructor_281_impl(Library library, Source source, TypeProvider typeProvider) {
    _dynamicType = typeProvider.dynamicType;
  }

  /**
   * Initialize a newly created visitor to resolve the nodes in a compilation unit.
   * @param definingLibrary the element for the library containing the compilation unit being
   * visited
   * @param source the source representing the compilation unit being visited
   * @param typeProvider the object used to access the types from the core library
   * @param errorListener the error listener that will be informed of any errors that are found
   * during resolution
   */
  TypeResolverVisitor.con2(LibraryElement definingLibrary, Source source, TypeProvider typeProvider, AnalysisErrorListener errorListener) : super.con2(definingLibrary, source, typeProvider, errorListener) {
    _jtd_constructor_282_impl(definingLibrary, source, typeProvider, errorListener);
  }
  _jtd_constructor_282_impl(LibraryElement definingLibrary, Source source, TypeProvider typeProvider, AnalysisErrorListener errorListener) {
    _dynamicType = typeProvider.dynamicType;
  }
  Object visitCatchClause(CatchClause node) {
    super.visitCatchClause(node);
    SimpleIdentifier exception = node.exceptionParameter;
    if (exception != null) {
      TypeName exceptionTypeName = node.exceptionType;
      Type2 exceptionType;
      if (exceptionTypeName == null) {
        exceptionType = typeProvider.objectType;
      } else {
        exceptionType = getType3(exceptionTypeName);
      }
      recordType(exception, exceptionType);
      Element element = exception.element;
      if (element is VariableElementImpl) {
        ((element as VariableElementImpl)).type = exceptionType;
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
      ErrorCode errorCode = node.withClause == null ? CompileTimeErrorCode.EXTENDS_NON_CLASS : CompileTimeErrorCode.MIXIN_WITH_NON_CLASS_SUPERCLASS;
      superclassType = resolveType(extendsClause.superclass, errorCode);
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
    InterfaceType superclassType = resolveType(node.superclass, CompileTimeErrorCode.MIXIN_WITH_NON_CLASS_SUPERCLASS);
    if (superclassType == null) {
      superclassType = typeProvider.objectType;
    }
    if (classElement != null && superclassType != null) {
      classElement.supertype = superclassType;
    }
    resolve(classElement, node.withClause, node.implementsClause);
    return null;
  }
  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    super.visitConstructorDeclaration(node);
    ExecutableElementImpl element = node.element as ExecutableElementImpl;
    FunctionTypeImpl type = new FunctionTypeImpl.con1(element);
    setTypeInformation(type, null, element.parameters);
    type.returnType = ((element.enclosingElement as ClassElement)).type;
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
      declaredType = getType3(typeName);
    }
    LocalVariableElementImpl element = node.element as LocalVariableElementImpl;
    element.type = declaredType;
    return null;
  }
  Object visitDefaultFormalParameter(DefaultFormalParameter node) {
    super.visitDefaultFormalParameter(node);
    return null;
  }
  Object visitFieldFormalParameter(FieldFormalParameter node) {
    super.visitFieldFormalParameter(node);
    Element element = node.identifier.element;
    if (element is ParameterElementImpl) {
      ParameterElementImpl parameter = element as ParameterElementImpl;
      Type2 type;
      TypeName typeName = node.type;
      if (typeName == null) {
        type = _dynamicType;
      } else {
        type = getType3(typeName);
      }
      parameter.type = type;
    } else {
    }
    return null;
  }
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    super.visitFunctionDeclaration(node);
    ExecutableElementImpl element = node.element as ExecutableElementImpl;
    FunctionTypeImpl type = new FunctionTypeImpl.con1(element);
    setTypeInformation(type, node.returnType, element.parameters);
    element.type = type;
    return null;
  }
  Object visitFunctionTypeAlias(FunctionTypeAlias node) {
    super.visitFunctionTypeAlias(node);
    FunctionTypeAliasElementImpl element = node.element as FunctionTypeAliasElementImpl;
    FunctionTypeImpl type = element.type as FunctionTypeImpl;
    setTypeInformation(type, node.returnType, element.parameters);
    return null;
  }
  Object visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    super.visitFunctionTypedFormalParameter(node);
    ParameterElementImpl element = node.identifier.element as ParameterElementImpl;
    AnonymousFunctionTypeImpl type = new AnonymousFunctionTypeImpl();
    List<ParameterElement> parameters = getElements(node.parameters);
    setTypeInformation(type, node.returnType, parameters);
    type.baseParameters = parameters;
    element.type = type;
    return null;
  }
  Object visitMethodDeclaration(MethodDeclaration node) {
    super.visitMethodDeclaration(node);
    ExecutableElementImpl element = node.element as ExecutableElementImpl;
    FunctionTypeImpl type = new FunctionTypeImpl.con1(element);
    setTypeInformation(type, node.returnType, element.parameters);
    element.type = type;
    if (element is PropertyAccessorElement) {
      PropertyAccessorElement accessor = element as PropertyAccessorElement;
      PropertyInducingElementImpl variable = accessor.variable as PropertyInducingElementImpl;
      if (accessor.isGetter()) {
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
      declaredType = getType3(typeName);
    }
    Element element = node.identifier.element;
    if (element is ParameterElement) {
      ((element as ParameterElementImpl)).type = declaredType;
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
      if (typeName.name == _dynamicType.name) {
        setElement(typeName, _dynamicType.element);
        if (argumentList != null) {
        }
        typeName.staticType = _dynamicType;
        node.type = _dynamicType;
        return null;
      }
      VoidTypeImpl voidType = VoidTypeImpl.instance;
      if (typeName.name == voidType.name) {
        if (argumentList != null) {
        }
        typeName.staticType = voidType;
        node.type = voidType;
        return null;
      }
      ASTNode parent = node.parent;
      if (typeName is PrefixedIdentifier && parent is ConstructorName && argumentList == null) {
        ConstructorName name = parent as ConstructorName;
        if (name.name == null) {
          SimpleIdentifier prefix = ((typeName as PrefixedIdentifier)).prefix;
          element = nameScope.lookup(prefix, definingLibrary);
          if (element is PrefixElement) {
            return null;
          } else if (element != null) {
            name.name = ((typeName as PrefixedIdentifier)).identifier;
            name.period = ((typeName as PrefixedIdentifier)).period;
            node.name = prefix;
            typeName = prefix;
          }
        }
      }
    }
    bool elementValid = element is! MultiplyDefinedElement;
    if (elementValid && element is! ClassElement && isTypeNameInInstanceCreationExpression(node)) {
      SimpleIdentifier typeNameSimple = getTypeSimpleIdentifier(typeName);
      InstanceCreationExpression creation = node.parent.parent as InstanceCreationExpression;
      if (creation.isConst()) {
        if (element == null) {
          reportError(CompileTimeErrorCode.UNDEFINED_CLASS, typeNameSimple, [typeName]);
        } else {
          reportError(CompileTimeErrorCode.CONST_WITH_NON_TYPE, typeNameSimple, [typeName]);
        }
        elementValid = false;
      } else {
        if (element != null) {
          reportError(StaticWarningCode.NEW_WITH_NON_TYPE, typeNameSimple, [typeName]);
          elementValid = false;
        }
      }
    }
    if (elementValid && element == null) {
      SimpleIdentifier typeNameSimple = getTypeSimpleIdentifier(typeName);
      if (typeNameSimple.name == "boolean") {
        reportError(StaticWarningCode.UNDEFINED_CLASS_BOOLEAN, typeNameSimple, []);
      } else if (isTypeNameInCatchClause(node)) {
        reportError(StaticWarningCode.NON_TYPE_IN_CATCH_CLAUSE, typeName, [typeName.name]);
      } else if (isTypeNameInAsExpression(node)) {
        reportError(StaticWarningCode.CAST_TO_NON_TYPE, typeName, [typeName.name]);
      } else if (isTypeNameInIsExpression(node)) {
        reportError(StaticWarningCode.TYPE_TEST_NON_TYPE, typeName, [typeName.name]);
      } else if (isTypeNameTargetInRedirectedConstructor(node)) {
        reportError(StaticWarningCode.REDIRECT_TO_NON_CLASS, typeName, [typeName.name]);
      } else {
        reportError(StaticWarningCode.UNDEFINED_CLASS, typeName, [typeName.name]);
      }
      elementValid = false;
    }
    if (!elementValid) {
      setElement(typeName, _dynamicType.element);
      typeName.staticType = _dynamicType;
      node.type = _dynamicType;
      return null;
    }
    Type2 type = null;
    if (element is ClassElement) {
      setElement(typeName, element);
      type = ((element as ClassElement)).type;
    } else if (element is FunctionTypeAliasElement) {
      setElement(typeName, element);
      type = ((element as FunctionTypeAliasElement)).type;
    } else if (element is TypeVariableElement) {
      setElement(typeName, element);
      type = ((element as TypeVariableElement)).type;
      if (argumentList != null) {
      }
    } else if (element is MultiplyDefinedElement) {
      List<Element> elements = ((element as MultiplyDefinedElement)).conflictingElements;
      type = getType(elements);
      if (type != null) {
        node.type = type;
      }
    } else {
      if (isTypeNameInCatchClause(node)) {
        reportError(StaticWarningCode.NON_TYPE_IN_CATCH_CLAUSE, typeName, [typeName.name]);
      } else if (isTypeNameInAsExpression(node)) {
        reportError(StaticWarningCode.CAST_TO_NON_TYPE, typeName, [typeName.name]);
      } else if (isTypeNameInIsExpression(node)) {
        reportError(StaticWarningCode.TYPE_TEST_NON_TYPE, typeName, [typeName.name]);
      } else {
        ASTNode parent = typeName.parent;
        while (parent is TypeName) {
          parent = parent.parent;
        }
        if (parent is ExtendsClause || parent is ImplementsClause || parent is WithClause || parent is ClassTypeAlias) {
        } else {
          reportError(StaticWarningCode.NOT_A_TYPE, typeName, [typeName.name]);
        }
      }
      setElement(typeName, _dynamicType.element);
      typeName.staticType = _dynamicType;
      node.type = _dynamicType;
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
        Type2 argumentType = getType3(arguments[i]);
        if (argumentType != null) {
          typeArguments.add(argumentType);
        }
      }
      if (argumentCount != parameterCount) {
        reportError(getInvalidTypeParametersErrorCode(node), node, [typeName.name, parameterCount, argumentCount]);
      }
      argumentCount = typeArguments.length;
      if (argumentCount < parameterCount) {
        for (int i = argumentCount; i < parameterCount; i++) {
          typeArguments.add(_dynamicType);
        }
      }
      if (type is InterfaceTypeImpl) {
        InterfaceTypeImpl interfaceType = type as InterfaceTypeImpl;
        type = interfaceType.substitute5(new List.from(typeArguments));
      } else if (type is FunctionTypeImpl) {
        FunctionTypeImpl functionType = type as FunctionTypeImpl;
        type = functionType.substitute4(new List.from(typeArguments));
      } else {
      }
    } else {
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
  Object visitVariableDeclaration(VariableDeclaration node) {
    super.visitVariableDeclaration(node);
    Type2 declaredType;
    TypeName typeName = ((node.parent as VariableDeclarationList)).type;
    if (typeName == null) {
      declaredType = _dynamicType;
    } else {
      declaredType = getType3(typeName);
    }
    Element element = node.name.element;
    if (element is VariableElement) {
      ((element as VariableElementImpl)).type = declaredType;
      if (element is PropertyInducingElement) {
        PropertyInducingElement variableElement = element as PropertyInducingElement;
        PropertyAccessorElementImpl getter = variableElement.getter as PropertyAccessorElementImpl;
        FunctionTypeImpl getterType = new FunctionTypeImpl.con1(getter);
        getterType.returnType = declaredType;
        getter.type = getterType;
        PropertyAccessorElementImpl setter = variableElement.setter as PropertyAccessorElementImpl;
        if (setter != null) {
          FunctionTypeImpl setterType = new FunctionTypeImpl.con1(setter);
          setterType.returnType = VoidTypeImpl.instance;
          setterType.normalParameterTypes = <Type2> [declaredType];
          setter.type = setterType;
        }
      }
    } else {
    }
    return null;
  }

  /**
   * Return the class element that represents the class whose name was provided.
   * @param identifier the name from the declaration of a class
   * @return the class element that represents the class
   */
  ClassElementImpl getClassElement(SimpleIdentifier identifier) {
    if (identifier == null) {
      return null;
    }
    Element element = identifier.element;
    if (element is! ClassElementImpl) {
      return null;
    }
    return element as ClassElementImpl;
  }

  /**
   * Return an array containing all of the elements associated with the parameters in the given
   * list.
   * @param parameterList the list of parameters whose elements are to be returned
   * @return the elements associated with the parameters
   */
  List<ParameterElement> getElements(FormalParameterList parameterList) {
    List<ParameterElement> elements = new List<ParameterElement>();
    for (FormalParameter parameter in parameterList.parameters) {
      ParameterElement element = parameter.identifier.element as ParameterElement;
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
   * @param node the type name with the wrong number of type arguments
   * @return the error code that should be used to report that the wrong number of type arguments
   * were provided
   */
  ErrorCode getInvalidTypeParametersErrorCode(TypeName node) {
    ASTNode parent = node.parent;
    if (parent is ConstructorName) {
      parent = parent.parent;
      if (parent is InstanceCreationExpression) {
        if (((parent as InstanceCreationExpression)).isConst()) {
          return CompileTimeErrorCode.CONST_WITH_INVALID_TYPE_PARAMETERS;
        } else {
          return CompileTimeErrorCode.NEW_WITH_INVALID_TYPE_PARAMETERS;
        }
      }
    }
    return StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS;
  }

  /**
   * Given the multiple elements to which a single name could potentially be resolved, return the
   * single interface type that should be used, or {@code null} if there is no clear choice.
   * @param elements the elements to which a single name could potentially be resolved
   * @return the single interface type that should be used for the type name
   */
  InterfaceType getType(List<Element> elements) {
    InterfaceType type = null;
    for (Element element in elements) {
      if (element is ClassElement) {
        if (type != null) {
          return null;
        }
        type = ((element as ClassElement)).type;
      }
    }
    return type;
  }

  /**
   * Return the type represented by the given type name.
   * @param typeName the type name representing the type to be returned
   * @return the type represented by the type name
   */
  Type2 getType3(TypeName typeName) {
    Type2 type = typeName.type;
    if (type == null) {
      return _dynamicType;
    }
    return type;
  }

  /**
   * Return the type arguments associated with the given type.
   * @param type the type whole type arguments are to be returned
   * @return the type arguments associated with the given type
   */
  List<Type2> getTypeArguments(Type2 type) {
    if (type is InterfaceType) {
      return ((type as InterfaceType)).typeArguments;
    } else if (type is FunctionType) {
      return ((type as FunctionType)).typeArguments;
    }
    return TypeImpl.EMPTY_ARRAY;
  }

  /**
   * Returns the simple identifier of the given (may be qualified) type name.
   * @param typeName the (may be qualified) qualified type name
   * @return the simple identifier of the given (may be qualified) type name.
   */
  SimpleIdentifier getTypeSimpleIdentifier(Identifier typeName) {
    if (typeName is SimpleIdentifier) {
      return typeName as SimpleIdentifier;
    } else {
      return ((typeName as PrefixedIdentifier)).identifier;
    }
  }

  /**
   * Checks if the given type name is used as the type in an as expression.
   * @param typeName the type name to analyzer
   * @return {@code true} if the given type name is used as the type in an as expression
   */
  bool isTypeNameInAsExpression(TypeName typeName) {
    ASTNode parent = typeName.parent;
    if (parent is AsExpression) {
      AsExpression asExpression = parent as AsExpression;
      return identical(asExpression.type, typeName);
    }
    return false;
  }

  /**
   * Checks if the given type name is used as the exception type in a catch clause.
   * @param typeName the type name to analyzer
   * @return {@code true} if the given type name is used as the exception type in a catch clause
   */
  bool isTypeNameInCatchClause(TypeName typeName) {
    ASTNode parent = typeName.parent;
    if (parent is CatchClause) {
      CatchClause catchClause = parent as CatchClause;
      return identical(catchClause.exceptionType, typeName);
    }
    return false;
  }

  /**
   * Checks if the given type name is used as the type in an instance creation expression.
   * @param typeName the type name to analyzer
   * @return {@code true} if the given type name is used as the type in an instance creation
   * expression
   */
  bool isTypeNameInInstanceCreationExpression(TypeName typeName) {
    ASTNode parent = typeName.parent;
    if (parent is ConstructorName && parent.parent is InstanceCreationExpression) {
      ConstructorName constructorName = parent as ConstructorName;
      return constructorName != null && identical(constructorName.type, typeName);
    }
    return false;
  }

  /**
   * Checks if the given type name is used as the type in an is expression.
   * @param typeName the type name to analyzer
   * @return {@code true} if the given type name is used as the type in an is expression
   */
  bool isTypeNameInIsExpression(TypeName typeName) {
    ASTNode parent = typeName.parent;
    if (parent is IsExpression) {
      IsExpression isExpression = parent as IsExpression;
      return identical(isExpression.type, typeName);
    }
    return false;
  }

  /**
   * Checks if the given type name is the target in a redirected constructor.
   * @param typeName the type name to analyzer
   * @return {@code true} if the given type name is used as the type in a redirected constructor
   */
  bool isTypeNameTargetInRedirectedConstructor(TypeName typeName) {
    ASTNode parent = typeName.parent;
    if (parent is ConstructorName) {
      ConstructorName constructorName = parent as ConstructorName;
      parent = constructorName.parent;
      if (parent is ConstructorDeclaration) {
        ConstructorDeclaration constructorDeclaration = parent as ConstructorDeclaration;
        return constructorName == constructorDeclaration.redirectedConstructor;
      }
    }
    return false;
  }

  /**
   * Record that the static type of the given node is the given type.
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
   * @param classElement the class element with which the mixin and interface types are to be
   * associated
   * @param withClause the with clause to be resolved
   * @param implementsClause the implements clause to be resolved
   */
  void resolve(ClassElementImpl classElement, WithClause withClause, ImplementsClause implementsClause) {
    if (withClause != null) {
      List<InterfaceType> mixinTypes = resolveTypes(withClause.mixinTypes, CompileTimeErrorCode.MIXIN_OF_NON_CLASS);
      if (classElement != null) {
        classElement.mixins = mixinTypes;
      }
    }
    if (implementsClause != null) {
      NodeList<TypeName> interfaces = implementsClause.interfaces;
      List<InterfaceType> interfaceTypes = resolveTypes(interfaces, CompileTimeErrorCode.IMPLEMENTS_NON_CLASS);
      List<TypeName> typeNames = new List.from(interfaces);
      String dynamicKeyword = sc.Keyword.DYNAMIC.syntax;
      List<bool> detectedRepeatOnIndex = new List<bool>.filled(typeNames.length, false);
      for (int i = 0; i < detectedRepeatOnIndex.length; i++) {
        detectedRepeatOnIndex[i] = false;
      }
      for (int i = 0; i < typeNames.length; i++) {
        TypeName typeName = typeNames[i];
        String name = typeName.name.name;
        if (name == dynamicKeyword) {
          reportError(CompileTimeErrorCode.IMPLEMENTS_DYNAMIC, typeName, []);
        }
        if (!detectedRepeatOnIndex[i]) {
          for (int j = i + 1; j < typeNames.length; j++) {
            Element element = typeName.name.element;
            TypeName typeName2 = typeNames[j];
            Identifier identifier2 = typeName2.name;
            String name2 = identifier2.name;
            Element element2 = identifier2.element;
            if (element != null && element == element2) {
              detectedRepeatOnIndex[j] = true;
              reportError(CompileTimeErrorCode.IMPLEMENTS_REPEATED, typeName2, [name2]);
            }
          }
        }
      }
      if (classElement != null) {
        classElement.interfaces = interfaceTypes;
      }
    }
  }

  /**
   * Return the type specified by the given name.
   * @param typeName the type name specifying the type to be returned
   * @param nonTypeError the error to produce if the type name is defined to be something other than
   * a type
   * @return the type specified by the type name
   */
  InterfaceType resolveType(TypeName typeName, ErrorCode nonTypeError) {
    Type2 type = typeName.type;
    if (type is InterfaceType) {
      return type as InterfaceType;
    }
    Identifier name = typeName.name;
    if (name.name != sc.Keyword.DYNAMIC.syntax) {
      reportError(nonTypeError, name, [name.name]);
    }
    return null;
  }

  /**
   * Resolve the types in the given list of type names.
   * @param typeNames the type names to be resolved
   * @param nonTypeError the error to produce if the type name is defined to be something other than
   * a type
   * @return an array containing all of the types that were resolved.
   */
  List<InterfaceType> resolveTypes(NodeList<TypeName> typeNames, ErrorCode nonTypeError) {
    List<InterfaceType> types = new List<InterfaceType>();
    for (TypeName typeName in typeNames) {
      InterfaceType type = resolveType(typeName, nonTypeError);
      if (type != null) {
        types.add(type);
      }
    }
    return new List.from(types);
  }
  void setElement(Identifier typeName, Element element2) {
    if (element2 != null) {
      if (typeName is SimpleIdentifier) {
        ((typeName as SimpleIdentifier)).staticElement = element2;
        ((typeName as SimpleIdentifier)).element = element2;
      } else if (typeName is PrefixedIdentifier) {
        PrefixedIdentifier identifier = typeName as PrefixedIdentifier;
        identifier.identifier.staticElement = element2;
        identifier.identifier.element = element2;
        SimpleIdentifier prefix = identifier.prefix;
        Element prefixElement = nameScope.lookup(prefix, definingLibrary);
        if (prefixElement != null) {
          prefix.staticElement = prefixElement;
          prefix.element = prefixElement;
        }
      }
    }
  }

  /**
   * Set the return type and parameter type information for the given function type based on the
   * given return type and parameter elements.
   * @param functionType the function type to be filled in
   * @param returnType the return type of the function, or {@code null} if no type was declared
   * @param parameters the elements representing the parameters to the function
   */
  void setTypeInformation(FunctionTypeImpl functionType, TypeName returnType2, List<ParameterElement> parameters) {
    List<Type2> normalParameterTypes = new List<Type2>();
    List<Type2> optionalParameterTypes = new List<Type2>();
    LinkedHashMap<String, Type2> namedParameterTypes = new LinkedHashMap<String, Type2>();
    for (ParameterElement parameter in parameters) {
      while (true) {
        if (parameter.parameterKind == ParameterKind.REQUIRED) {
          normalParameterTypes.add(parameter.type);
        } else if (parameter.parameterKind == ParameterKind.POSITIONAL) {
          optionalParameterTypes.add(parameter.type);
        } else if (parameter.parameterKind == ParameterKind.NAMED) {
          namedParameterTypes[parameter.name] = parameter.type;
        }
        break;
      }
    }
    if (!normalParameterTypes.isEmpty) {
      functionType.normalParameterTypes = new List.from(normalParameterTypes);
    }
    if (!optionalParameterTypes.isEmpty) {
      functionType.optionalParameterTypes = new List.from(optionalParameterTypes);
    }
    if (!namedParameterTypes.isEmpty) {
      functionType.namedParameterTypes = namedParameterTypes;
    }
    if (returnType2 == null) {
      functionType.returnType = _dynamicType;
    } else {
      functionType.returnType = returnType2.type;
    }
  }
}
/**
 * Instances of the class {@code ClassScope} implement the scope defined by a class.
 * @coverage dart.engine.resolver
 */
class ClassScope extends EnclosedScope {

  /**
   * Initialize a newly created scope enclosed within another scope.
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
   * @param typeElement the element representing the type represented by this scope
   */
  void defineTypeParameters(ClassElement typeElement) {
    Scope parameterScope = enclosingScope;
    for (TypeVariableElement parameter in typeElement.typeVariables) {
      parameterScope.define(parameter);
    }
  }
}
/**
 * Instances of the class {@code EnclosedScope} implement a scope that is lexically enclosed in
 * another scope.
 * @coverage dart.engine.resolver
 */
class EnclosedScope extends Scope {

  /**
   * The scope in which this scope is lexically enclosed.
   */
  Scope _enclosingScope;

  /**
   * Initialize a newly created scope enclosed within another scope.
   * @param enclosingScope the scope in which this scope is lexically enclosed
   */
  EnclosedScope(Scope enclosingScope) {
    this._enclosingScope = enclosingScope;
  }
  LibraryElement get definingLibrary => _enclosingScope.definingLibrary;
  AnalysisErrorListener get errorListener => _enclosingScope.errorListener;

  /**
   * Return the scope in which this scope is lexically enclosed.
   * @return the scope in which this scope is lexically enclosed
   */
  Scope get enclosingScope => _enclosingScope;
  Element lookup3(Identifier identifier, String name, LibraryElement referencingLibrary) {
    Element element = localLookup(name, referencingLibrary);
    if (element != null) {
      return element;
    }
    return _enclosingScope.lookup3(identifier, name, referencingLibrary);
  }
}
/**
 * Instances of the class {@code FunctionScope} implement the scope defined by a function.
 * @coverage dart.engine.resolver
 */
class FunctionScope extends EnclosedScope {

  /**
   * Initialize a newly created scope enclosed within another scope.
   * @param enclosingScope the scope in which this scope is lexically enclosed
   * @param functionElement the element representing the type represented by this scope
   */
  FunctionScope(Scope enclosingScope, ExecutableElement functionElement) : super(new EnclosedScope(enclosingScope)) {
    defineParameters(functionElement);
  }

  /**
   * Define the parameters for the given function in the scope that encloses this function.
   * @param functionElement the element representing the function represented by this scope
   */
  void defineParameters(ExecutableElement functionElement) {
    Scope parameterScope = enclosingScope;
    if (functionElement.enclosingElement is ExecutableElement) {
      String name = functionElement.name;
      if (name != null && !name.isEmpty) {
        parameterScope.define(functionElement);
      }
    }
    for (ParameterElement parameter in functionElement.parameters) {
      if (!parameter.isInitializingFormal()) {
        parameterScope.define(parameter);
      }
    }
  }
}
/**
 * Instances of the class {@code FunctionTypeScope} implement the scope defined by a function type
 * alias.
 * @coverage dart.engine.resolver
 */
class FunctionTypeScope extends EnclosedScope {

  /**
   * Initialize a newly created scope enclosed within another scope.
   * @param enclosingScope the scope in which this scope is lexically enclosed
   * @param typeElement the element representing the type alias represented by this scope
   */
  FunctionTypeScope(Scope enclosingScope, FunctionTypeAliasElement typeElement) : super(new EnclosedScope(enclosingScope)) {
    defineTypeVariables(typeElement);
    defineParameters(typeElement);
  }

  /**
   * Define the parameters for the function type alias.
   * @param typeElement the element representing the type represented by this scope
   */
  void defineParameters(FunctionTypeAliasElement typeElement) {
    for (ParameterElement parameter in typeElement.parameters) {
      define(parameter);
    }
  }

  /**
   * Define the type variables for the function type alias.
   * @param typeElement the element representing the type represented by this scope
   */
  void defineTypeVariables(FunctionTypeAliasElement typeElement) {
    Scope typeVariableScope = enclosingScope;
    for (TypeVariableElement typeVariable in typeElement.typeVariables) {
      typeVariableScope.define(typeVariable);
    }
  }
}
/**
 * Instances of the class {@code LabelScope} represent a scope in which a single label is defined.
 * @coverage dart.engine.resolver
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
   * The marker used to look up a label element for an unlabeled {@code break} or {@code continue}.
   */
  static String EMPTY_LABEL = "";

  /**
   * The label element returned for scopes that can be the target of an unlabeled {@code break} or{@code continue}.
   */
  static SimpleIdentifier _EMPTY_LABEL_IDENTIFIER = new SimpleIdentifier.full(new sc.StringToken(sc.TokenType.IDENTIFIER, "", 0));

  /**
   * Initialize a newly created scope to represent the potential target of an unlabeled{@code break} or {@code continue}.
   * @param outerScope the label scope enclosing the new label scope
   * @param onSwitchStatement {@code true} if this label is associated with a {@code switch}statement
   * @param onSwitchMember {@code true} if this label is associated with a {@code switch} member
   */
  LabelScope.con1(LabelScope outerScope, bool onSwitchStatement, bool onSwitchMember) {
    _jtd_constructor_287_impl(outerScope, onSwitchStatement, onSwitchMember);
  }
  _jtd_constructor_287_impl(LabelScope outerScope, bool onSwitchStatement, bool onSwitchMember) {
    _jtd_constructor_288_impl(outerScope, EMPTY_LABEL, new LabelElementImpl(_EMPTY_LABEL_IDENTIFIER, onSwitchStatement, onSwitchMember));
  }

  /**
   * Initialize a newly created scope to represent the given label.
   * @param outerScope the label scope enclosing the new label scope
   * @param label the label defined in this scope
   * @param element the element to which the label resolves
   */
  LabelScope.con2(LabelScope outerScope2, String label2, LabelElement element2) {
    _jtd_constructor_288_impl(outerScope2, label2, element2);
  }
  _jtd_constructor_288_impl(LabelScope outerScope2, String label2, LabelElement element2) {
    this._outerScope = outerScope2;
    this._label = label2;
    this._element = element2;
  }

  /**
   * Return the label element corresponding to the given label, or {@code null} if the given label
   * is not defined in this scope.
   * @param targetLabel the label being looked up
   * @return the label element corresponding to the given label
   */
  LabelElement lookup(SimpleIdentifier targetLabel) => lookup2(targetLabel.name);

  /**
   * Return the label element corresponding to the given label, or {@code null} if the given label
   * is not defined in this scope.
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
 * Instances of the class {@code LibraryImportScope} represent the scope containing all of the names
 * available from imported libraries.
 * @coverage dart.engine.resolver
 */
class LibraryImportScope extends Scope {

  /**
   * @return {@code true} if the given {@link Identifier} is the part of type annotation.
   */
  static bool isTypeAnnotation(Identifier identifier) {
    ASTNode parent = identifier.parent;
    if (parent is TypeName) {
      ASTNode parent2 = parent.parent;
      if (parent2 is FunctionDeclaration) {
        FunctionDeclaration decl = parent2 as FunctionDeclaration;
        return identical(decl.returnType, parent);
      }
      if (parent2 is FunctionTypeAlias) {
        FunctionTypeAlias decl = parent2 as FunctionTypeAlias;
        return identical(decl.returnType, parent);
      }
      if (parent2 is MethodDeclaration) {
        MethodDeclaration decl = parent2 as MethodDeclaration;
        return identical(decl.returnType, parent);
      }
      if (parent2 is VariableDeclarationList) {
        VariableDeclarationList decl = parent2 as VariableDeclarationList;
        return identical(decl.type, parent);
      }
      if (parent2 is SimpleFormalParameter) {
        SimpleFormalParameter decl = parent2 as SimpleFormalParameter;
        return identical(decl.type, parent);
      }
      if (parent2 is TypeParameter) {
        TypeParameter decl = parent2 as TypeParameter;
        return identical(decl.bound, parent);
      }
      if (parent2 is TypeArgumentList) {
        ASTNode parent3 = parent2.parent;
        if (parent3 is TypeName) {
          TypeName typeName = parent3 as TypeName;
          if (identical((typeName).typeArguments, parent2)) {
            return isTypeAnnotation(typeName.name);
          }
        }
      }
      return false;
    }
    return false;
  }

  /**
   * The element representing the library in which this scope is enclosed.
   */
  LibraryElement _definingLibrary;

  /**
   * The listener that is to be informed when an error is encountered.
   */
  AnalysisErrorListener _errorListener;

  /**
   * A list of the namespaces representing the names that are available in this scope from imported
   * libraries.
   */
  List<Namespace> _importedNamespaces = new List<Namespace>();

  /**
   * Initialize a newly created scope representing the names imported into the given library.
   * @param definingLibrary the element representing the library that imports the names defined in
   * this scope
   * @param errorListener the listener that is to be informed when an error is encountered
   */
  LibraryImportScope(LibraryElement definingLibrary, AnalysisErrorListener errorListener) {
    this._definingLibrary = definingLibrary;
    this._errorListener = errorListener;
    createImportedNamespaces(definingLibrary);
  }
  void define(Element element) {
    if (!Scope.isPrivateName(element.displayName)) {
      super.define(element);
    }
  }
  LibraryElement get definingLibrary => _definingLibrary;
  AnalysisErrorListener get errorListener => _errorListener;
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
        } else {
          foundElement = new MultiplyDefinedElementImpl(_definingLibrary.context, foundElement, element);
        }
      }
    }
    if (foundElement is MultiplyDefinedElementImpl) {
      String foundEltName = foundElement.displayName;
      String libName1 = "", libName2 = "";
      List<Element> conflictingMembers = ((foundElement as MultiplyDefinedElementImpl)).conflictingElements;
      LibraryElement enclosingLibrary = conflictingMembers[0].getAncestor(LibraryElement);
      if (enclosingLibrary != null) {
        libName1 = enclosingLibrary.definingCompilationUnit.displayName;
      }
      enclosingLibrary = conflictingMembers[1].getAncestor(LibraryElement);
      if (enclosingLibrary != null) {
        libName2 = enclosingLibrary.definingCompilationUnit.displayName;
      }
      ErrorCode errorCode = isTypeAnnotation(identifier) ? StaticWarningCode.AMBIGUOUS_IMPORT : CompileTimeErrorCode.AMBIGUOUS_IMPORT;
      _errorListener.onError(new AnalysisError.con2(source, identifier.offset, identifier.length, errorCode, [foundEltName, libName1, libName2]));
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
   * @param definingLibrary the element representing the library that imports the libraries for
   * which namespaces will be created
   */
  void createImportedNamespaces(LibraryElement definingLibrary) {
    NamespaceBuilder builder = new NamespaceBuilder();
    for (ImportElement element in definingLibrary.imports) {
      _importedNamespaces.add(builder.createImportNamespace(element));
    }
  }
}
/**
 * Instances of the class {@code LibraryScope} implement a scope containing all of the names defined
 * in a given library.
 * @coverage dart.engine.resolver
 */
class LibraryScope extends EnclosedScope {

  /**
   * Initialize a newly created scope representing the names defined in the given library.
   * @param definingLibrary the element representing the library represented by this scope
   * @param errorListener the listener that is to be informed when an error is encountered
   */
  LibraryScope(LibraryElement definingLibrary, AnalysisErrorListener errorListener) : super(new LibraryImportScope(definingLibrary, errorListener)) {
    defineTopLevelNames(definingLibrary);
  }
  AnalysisError getErrorForDuplicate(Element existing, Element duplicate) {
    if (existing is PrefixElement) {
      int offset = duplicate.nameOffset;
      if (duplicate is PropertyAccessorElement) {
        PropertyAccessorElement accessor = duplicate as PropertyAccessorElement;
        if (accessor.isSynthetic()) {
          offset = accessor.variable.nameOffset;
        }
      }
      return new AnalysisError.con2(source, offset, duplicate.displayName.length, CompileTimeErrorCode.PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER, [existing.displayName]);
    }
    return super.getErrorForDuplicate(existing, duplicate);
  }

  /**
   * Add to this scope all of the public top-level names that are defined in the given compilation
   * unit.
   * @param compilationUnit the compilation unit defining the top-level names to be added to this
   * scope
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
   * @param definingLibrary the element representing the library that defines the names in this
   * scope
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
 * Instances of the class {@code Namespace} implement a mapping of identifiers to the elements
 * represented by those identifiers. Namespaces are the building blocks for scopes.
 * @coverage dart.engine.resolver
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
   * @param definedNames the mapping from names that are defined in this namespace to the
   * corresponding elements
   */
  Namespace(Map<String, Element> definedNames) {
    this._definedNames = definedNames;
  }

  /**
   * Return the element in this namespace that is available to the containing scope using the given
   * name.
   * @param name the name used to reference the
   * @return the element represented by the given identifier
   */
  Element get(String name) => _definedNames[name];

  /**
   * Return a table containing the same mappings as those defined by this namespace.
   * @return a table containing the same mappings as those defined by this namespace
   */
  Map<String, Element> get definedNames => new Map<String, Element>.from(_definedNames);
}
/**
 * Instances of the class {@code NamespaceBuilder} are used to build a {@code Namespace}. Namespace
 * builders are thread-safe and re-usable.
 * @coverage dart.engine.resolver
 */
class NamespaceBuilder {

  /**
   * Create a namespace representing the export namespace of the given {@link ExportElement}.
   * @param element the export element whose export namespace is to be created
   * @return the export namespace that was created
   */
  Namespace createExportNamespace(ExportElement element) {
    LibraryElement exportedLibrary = element.exportedLibrary;
    if (exportedLibrary == null) {
      return Namespace.EMPTY;
    }
    Map<String, Element> definedNames = createExportMapping(exportedLibrary, new Set<LibraryElement>());
    definedNames = apply(definedNames, element.combinators);
    return new Namespace(definedNames);
  }

  /**
   * Create a namespace representing the export namespace of the given library.
   * @param library the library whose export namespace is to be created
   * @return the export namespace that was created
   */
  Namespace createExportNamespace2(LibraryElement library) => new Namespace(createExportMapping(library, new Set<LibraryElement>()));

  /**
   * Create a namespace representing the import namespace of the given library.
   * @param library the library whose import namespace is to be created
   * @return the import namespace that was created
   */
  Namespace createImportNamespace(ImportElement element) {
    LibraryElement importedLibrary = element.importedLibrary;
    if (importedLibrary == null) {
      return Namespace.EMPTY;
    }
    Map<String, Element> definedNames = createExportMapping(importedLibrary, new Set<LibraryElement>());
    definedNames = apply(definedNames, element.combinators);
    definedNames = apply2(definedNames, element.prefix);
    return new Namespace(definedNames);
  }

  /**
   * Create a namespace representing the public namespace of the given library.
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
   * @param definedNames the mapping table to which the names in the given namespace are to be added
   * @param namespace the namespace containing the names to be added to this namespace
   */
  void addAll2(Map<String, Element> definedNames2, Namespace namespace) {
    if (namespace != null) {
      addAll(definedNames2, namespace.definedNames);
    }
  }

  /**
   * Add the given element to the given mapping table if it has a publicly visible name.
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
   * @param definedNames the mapping table to which the public names are to be added
   * @param compilationUnit the compilation unit defining the top-level names to be added to this
   * namespace
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
   * @param definedNames the mapping table to which the namespace operations are to be applied
   * @param combinators the combinators to be applied
   */
  Map<String, Element> apply(Map<String, Element> definedNames, List<NamespaceCombinator> combinators) {
    for (NamespaceCombinator combinator in combinators) {
      if (combinator is HideElementCombinator) {
        hide(definedNames, ((combinator as HideElementCombinator)).hiddenNames);
      } else if (combinator is ShowElementCombinator) {
        definedNames = show(definedNames, ((combinator as ShowElementCombinator)).shownNames);
      } else {
        AnalysisEngine.instance.logger.logError("Unknown type of combinator: ${combinator.runtimeType.toString()}");
      }
    }
    return definedNames;
  }

  /**
   * Apply the given prefix to all of the names in the table of defined names.
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
   * @param library the library whose public namespace is to be created
   * @param visitedElements a set of libraries that do not need to be visited when processing the
   * export directives of the given library because all of the names defined by them will
   * be added by another library
   * @return the mapping table that was created
   */
  Map<String, Element> createExportMapping(LibraryElement library, Set<LibraryElement> visitedElements) {
    javaSetAdd(visitedElements, library);
    try {
      Map<String, Element> definedNames = new Map<String, Element>();
      for (ExportElement element in library.exports) {
        LibraryElement exportedLibrary = element.exportedLibrary;
        if (exportedLibrary != null && !visitedElements.contains(exportedLibrary)) {
          Map<String, Element> exportedNames = createExportMapping(exportedLibrary, visitedElements);
          exportedNames = apply(exportedNames, element.combinators);
          addAll(definedNames, exportedNames);
        }
      }
      addAll2(definedNames, ((library.context as InternalAnalysisContext)).getPublicNamespace(library));
      return definedNames;
    } finally {
      visitedElements.remove(library);
    }
  }

  /**
   * Hide all of the given names by removing them from the given collection of defined names.
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
 * The abstract class {@code Scope} defines the behavior common to name scopes used by the resolver
 * to determine which names are visible at any given point in the code.
 * @coverage dart.engine.resolver
 */
abstract class Scope {

  /**
   * The prefix used to mark an identifier as being private to its library.
   */
  static String PRIVATE_NAME_PREFIX = "_";

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
   * Return {@code true} if the given name is a library-private name.
   * @param name the name being tested
   * @return {@code true} if the given name is a library-private name
   */
  static bool isPrivateName(String name) => name != null && name.startsWith(PRIVATE_NAME_PREFIX);

  /**
   * A table mapping names that are defined in this scope to the element representing the thing
   * declared with that name.
   */
  Map<String, Element> _definedNames = new Map<String, Element>();

  /**
   * Add the given element to this scope. If there is already an element with the given name defined
   * in this scope, then an error will be generated and the original element will continue to be
   * mapped to the name. If there is an element with the given name in an enclosing scope, then a
   * warning will be generated but the given element will hide the inherited element.
   * @param element the element to be added to this scope
   */
  void define(Element element) {
    String name = getName(element);
    if (name != null && !name.isEmpty) {
      if (_definedNames.containsKey(name)) {
        errorListener.onError(getErrorForDuplicate(_definedNames[name], element));
      } else {
        _definedNames[name] = element;
      }
    }
  }

  /**
   * Return the element with which the given identifier is associated, or {@code null} if the name
   * is not defined within this scope.
   * @param identifier the identifier associated with the element to be returned
   * @param referencingLibrary the library that contains the reference to the name, used to
   * implement library-level privacy
   * @return the element with which the given identifier is associated
   */
  Element lookup(Identifier identifier, LibraryElement referencingLibrary) => lookup3(identifier, identifier.name, referencingLibrary);

  /**
   * Add the given element to this scope without checking for duplication or hiding.
   * @param element the element to be added to this scope
   */
  void defineWithoutChecking(Element element) {
    _definedNames[getName(element)] = element;
  }

  /**
   * Add the given element to this scope without checking for duplication or hiding.
   * @param name the name of the element to be added
   * @param element the element to be added to this scope
   */
  void defineWithoutChecking2(String name, Element element) {
    _definedNames[name] = element;
  }

  /**
   * Return the element representing the library in which this scope is enclosed.
   * @return the element representing the library in which this scope is enclosed
   */
  LibraryElement get definingLibrary;

  /**
   * Return the error code to be used when reporting that a name being defined locally conflicts
   * with another element of the same name in the local scope.
   * @param existing the first element to be declared with the conflicting name
   * @param duplicate another element declared with the conflicting name
   * @return the error code used to report duplicate names within a scope
   */
  AnalysisError getErrorForDuplicate(Element existing, Element duplicate) {
    Source source = duplicate.source;
    if (source == null) {
      source = source;
    }
    return new AnalysisError.con2(source, duplicate.nameOffset, duplicate.displayName.length, CompileTimeErrorCode.DUPLICATE_DEFINITION, [existing.displayName]);
  }

  /**
   * Return the listener that is to be informed when an error is encountered.
   * @return the listener that is to be informed when an error is encountered
   */
  AnalysisErrorListener get errorListener;

  /**
   * Return the source object representing the compilation unit with which errors related to this
   * scope should be associated.
   * @return the source object with which errors should be associated
   */
  Source get source => definingLibrary.definingCompilationUnit.source;

  /**
   * Return the element with which the given name is associated, or {@code null} if the name is not
   * defined within this scope. This method only returns elements that are directly defined within
   * this scope, not elements that are defined in an enclosing scope.
   * @param name the name associated with the element to be returned
   * @param referencingLibrary the library that contains the reference to the name, used to
   * implement library-level privacy
   * @return the element with which the given name is associated
   */
  Element localLookup(String name, LibraryElement referencingLibrary) => _definedNames[name];

  /**
   * Return the element with which the given name is associated, or {@code null} if the name is not
   * defined within this scope.
   * @param identifier the identifier node to lookup element for, used to report correct kind of a
   * problem and associate problem with
   * @param name the name associated with the element to be returned
   * @param referencingLibrary the library that contains the reference to the name, used to
   * implement library-level privacy
   * @return the element with which the given name is associated
   */
  Element lookup3(Identifier identifier, String name, LibraryElement referencingLibrary);

  /**
   * Return the name that will be used to look up the given element.
   * @param element the element whose look-up name is to be returned
   * @return the name that will be used to look up the given element
   */
  String getName(Element element) {
    if (element is MethodElement) {
      MethodElement method = element as MethodElement;
      if (method.name == "-" && method.parameters.length == 0) {
        return UNARY_MINUS;
      }
    }
    return element.name;
  }
}
/**
 * Instances of the class {@code ConstantVerifier} traverse an AST structure looking for additional
 * errors and warnings not covered by the parser and resolver. In particular, it looks for errors
 * and warnings related to constant expressions.
 * @coverage dart.engine.resolver
 */
class ConstantVerifier extends RecursiveASTVisitor<Object> {

  /**
   * The error reporter by which errors will be reported.
   */
  ErrorReporter _errorReporter;

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
   * @param errorReporter the error reporter by which errors will be reported
   */
  ConstantVerifier(ErrorReporter errorReporter, TypeProvider typeProvider) {
    this._errorReporter = errorReporter;
    this._boolType = typeProvider.boolType;
    this._intType = typeProvider.intType;
    this._numType = typeProvider.numType;
    this._stringType = typeProvider.stringType;
  }
  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    if (node.constKeyword != null) {
      validateInitializers(node);
    }
    return super.visitConstructorDeclaration(node);
  }
  Object visitFunctionExpression(FunctionExpression node) {
    super.visitFunctionExpression(node);
    validateDefaultValues(node.parameters);
    return null;
  }
  Object visitInstanceCreationExpression(InstanceCreationExpression node) {
    validateConstantArguments(node);
    return super.visitInstanceCreationExpression(node);
  }
  Object visitListLiteral(ListLiteral node) {
    super.visitListLiteral(node);
    if (node.modifier != null) {
      for (Expression element in node.elements) {
        validate(element, CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT);
      }
    }
    return null;
  }
  Object visitMapLiteral(MapLiteral node) {
    super.visitMapLiteral(node);
    bool isConst = node.modifier != null;
    bool reportEqualKeys = true;
    Set<Object> keys = new Set<Object>();
    List<Expression> invalidKeys = new List<Expression>();
    for (MapLiteralEntry entry in node.entries) {
      Expression key = entry.key;
      if (isConst) {
        EvaluationResultImpl result = validate(key, CompileTimeErrorCode.NON_CONSTANT_MAP_KEY);
        validate(entry.value, CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE);
        if (result is ValidResult) {
          Object value = ((result as ValidResult)).value;
          if (keys.contains(value)) {
            invalidKeys.add(key);
          } else {
            javaSetAdd(keys, value);
          }
        }
      } else {
        EvaluationResultImpl result = key.accept(new ConstantVisitor());
        if (result is ValidResult) {
          Object value = ((result as ValidResult)).value;
          if (keys.contains(value)) {
            invalidKeys.add(key);
          } else {
            javaSetAdd(keys, value);
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
    if (initializer != null && node.isConst()) {
      VariableElementImpl element = node.element as VariableElementImpl;
      EvaluationResultImpl result = element.evaluationResult;
      if (result == null) {
        result = validate(initializer, CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE);
        element.evaluationResult = result;
      } else if (result is ErrorResult) {
        reportErrors(result, CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE);
      }
    }
    return null;
  }

  /**
   * Return {@code true} if the given value is the result of evaluating an expression whose value is
   * a valid key in a const map literal. Keys in const map literals must be either a string, number,
   * boolean, list, map, or null.
   * @param value
   * @return {@code true} if the given value is a valid key in a const map literal
   */
  bool isValidConstMapKey(Object value) => true;

  /**
   * If the given result represents one or more errors, report those errors. Except for special
   * cases, use the given error code rather than the one reported in the error.
   * @param result the result containing any errors that need to be reported
   * @param errorCode the error code to be used if the result represents an error
   */
  void reportErrors(EvaluationResultImpl result, ErrorCode errorCode2) {
    if (result is ErrorResult) {
      for (ErrorResult_ErrorData data in ((result as ErrorResult)).errorData) {
        ErrorCode dataErrorCode = data.errorCode;
        if (identical(dataErrorCode, CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION) || identical(dataErrorCode, CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_NUM_STRING) || identical(dataErrorCode, CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL) || identical(dataErrorCode, CompileTimeErrorCode.CONST_EVAL_TYPE_INT) || identical(dataErrorCode, CompileTimeErrorCode.CONST_EVAL_TYPE_NUM)) {
          _errorReporter.reportError2(dataErrorCode, data.node, []);
        } else {
          _errorReporter.reportError2(errorCode2, data.node, []);
        }
      }
    }
  }

  /**
   * Validate that the given expression is a compile time constant. Return the value of the compile
   * time constant, or {@code null} if the expression is not a compile time constant.
   * @param expression the expression to be validated
   * @param errorCode the error code to be used if the expression is not a compile time constant
   * @return the value of the compile time constant
   */
  EvaluationResultImpl validate(Expression expression, ErrorCode errorCode) {
    EvaluationResultImpl result = expression.accept(new ConstantVisitor());
    reportErrors(result, errorCode);
    return result;
  }

  /**
   * Validate that if the passed instance creation is 'const' then all its arguments are constant
   * expressions.
   * @param node the instance creation evaluate
   */
  void validateConstantArguments(InstanceCreationExpression node) {
    if (!node.isConst()) {
      return;
    }
    ArgumentList argumentList = node.argumentList;
    if (argumentList == null) {
      return;
    }
    for (Expression argument in argumentList.arguments) {
      if (argument is NamedExpression) {
        argument = ((argument as NamedExpression)).expression;
      }
      validate(argument, CompileTimeErrorCode.CONST_WITH_NON_CONSTANT_ARGUMENT);
    }
  }

  /**
   * Validate that the default value associated with each of the parameters in the given list is a
   * compile time constant.
   * @param parameters the list of parameters to be validated
   */
  void validateDefaultValues(FormalParameterList parameters2) {
    if (parameters2 == null) {
      return;
    }
    for (FormalParameter parameter in parameters2.parameters) {
      if (parameter is DefaultFormalParameter) {
        DefaultFormalParameter defaultParameter = parameter as DefaultFormalParameter;
        Expression defaultValue = defaultParameter.defaultValue;
        if (defaultValue != null) {
          EvaluationResultImpl result = validate(defaultValue, CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE);
          if (defaultParameter.isConst()) {
            VariableElementImpl element = parameter.element as VariableElementImpl;
            element.evaluationResult = result;
          }
        }
      }
    }
  }

  /**
   * Validates that the given expression is a compile time constant.
   * @param parameterElements the elements of parameters of constant constructor, they are
   * considered as a valid potentially constant expressions
   * @param expression the expression to validate
   */
  void validateInitializerExpression(List<ParameterElement> parameterElements, Expression expression) {
    EvaluationResultImpl result = expression.accept(new ConstantVisitor_9(this, parameterElements));
    reportErrors(result, CompileTimeErrorCode.NON_CONSTANT_VALUE_IN_INITIALIZER);
  }

  /**
   * Validates that all of the arguments of a constructor initializer are compile time constants.
   * @param parameterElements the elements of parameters of constant constructor, they are
   * considered as a valid potentially constant expressions
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
   * @param constructor the constant constructor declaration to validate
   */
  void validateInitializers(ConstructorDeclaration constructor) {
    List<ParameterElement> parameterElements = constructor.parameters.elements;
    NodeList<ConstructorInitializer> initializers = constructor.initializers;
    for (ConstructorInitializer initializer in initializers) {
      if (initializer is ConstructorFieldInitializer) {
        ConstructorFieldInitializer fieldInitializer = initializer as ConstructorFieldInitializer;
        validateInitializerExpression(parameterElements, fieldInitializer.expression);
      }
      if (initializer is RedirectingConstructorInvocation) {
        RedirectingConstructorInvocation invocation = initializer as RedirectingConstructorInvocation;
        validateInitializerInvocationArguments(parameterElements, invocation.argumentList);
      }
      if (initializer is SuperConstructorInvocation) {
        SuperConstructorInvocation invocation = initializer as SuperConstructorInvocation;
        validateInitializerInvocationArguments(parameterElements, invocation.argumentList);
      }
    }
  }
}
class ConstantVisitor_9 extends ConstantVisitor {
  final ConstantVerifier ConstantVerifier_this;
  List<ParameterElement> parameterElements;
  ConstantVisitor_9(this.ConstantVerifier_this, this.parameterElements) : super();
  EvaluationResultImpl visitSimpleIdentifier(SimpleIdentifier node) {
    Element element = node.element;
    for (ParameterElement parameterElement in parameterElements) {
      if (identical(parameterElement, element) && parameterElement != null) {
        Type2 type = parameterElement.type;
        if (type != null) {
          if (type.isDynamic()) {
            return ValidResult.RESULT_DYNAMIC;
          }
          if (type.isSubtypeOf(ConstantVerifier_this._boolType)) {
            return ValidResult.RESULT_BOOL;
          }
          if (type.isSubtypeOf(ConstantVerifier_this._intType)) {
            return ValidResult.RESULT_INT;
          }
          if (type.isSubtypeOf(ConstantVerifier_this._numType)) {
            return ValidResult.RESULT_NUM;
          }
          if (type.isSubtypeOf(ConstantVerifier_this._stringType)) {
            return ValidResult.RESULT_STRING;
          }
        }
        return ValidResult.RESULT_OBJECT;
      }
    }
    return super.visitSimpleIdentifier(node);
  }
}
/**
 * Instances of the class {@code ErrorVerifier} traverse an AST structure looking for additional
 * errors and warnings not covered by the parser and resolver.
 * @coverage dart.engine.resolver
 */
class ErrorVerifier extends RecursiveASTVisitor<Object> {

  /**
   * Checks if the given expression is the reference to the type.
   * @param expr the expression to evaluate
   * @return {@code true} if the given expression is the reference to the type
   */
  static bool isTypeReference(Expression expr) {
    if (expr is Identifier) {
      Identifier identifier = expr as Identifier;
      return identifier.element is ClassElement;
    }
    return false;
  }

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
   * The object providing access to the types defined by the language.
   */
  TypeProvider _typeProvider;

  /**
   * The manager for the inheritance mappings.
   */
  InheritanceManager _inheritanceManager;

  /**
   * A flag indicating whether we are running in strict mode. In strict mode, error reporting is
   * based exclusively on the static type information.
   */
  bool _strictMode = false;

  /**
   * This is set to {@code true} iff the visitor is currently visiting children nodes of a{@link ConstructorDeclaration} and the constructor is 'const'.
   * @see #visitConstructorDeclaration(ConstructorDeclaration)
   */
  bool _isEnclosingConstructorConst = false;

  /**
   * This is set to {@code true} iff the visitor is currently visiting children nodes of a{@link CatchClause}.
   * @see #visitCatchClause(CatchClause)
   */
  bool _isInCatchClause = false;

  /**
   * This is set to {@code true} iff the visitor is currently visiting a{@link ConstructorInitializer}.
   */
  bool _isInConstructorInitializer = false;

  /**
   * This is set to {@code true} iff the visitor is currently visiting code in the SDK.
   */
  bool _isInSystemLibrary = false;

  /**
   * The class containing the AST nodes being visited, or {@code null} if we are not in the scope of
   * a class.
   */
  ClassElement _enclosingClass;

  /**
   * The method or function that we are currently visiting, or {@code null} if we are not inside a
   * method or function.
   */
  ExecutableElement _enclosingFunction;

  /**
   * This map is initialized when visiting the contents of a class declaration. If the visitor is
   * not in an enclosing class declaration, then the map is set to {@code null}.
   * <p>
   * When set the map maps the set of {@link FieldElement}s in the class to an{@link INIT_STATE#NOT_INIT} or {@link INIT_STATE#INIT_IN_DECLARATION}. <code>checkFor*</code>
   * methods, specifically {@link #checkForAllFinalInitializedErrorCodes(ConstructorDeclaration)},
   * can make a copy of the map to compute error code states. <code>checkFor*</code> methods should
   * only ever make a copy, or read from this map after it has been set in{@link #visitClassDeclaration(ClassDeclaration)}.
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
   * A table mapping names to the export elements exported them.
   */
  Map<String, ExportElement> _exportedNames = new Map<String, ExportElement>();

  /**
   * A set of the names of the variable initializers we are visiting now.
   */
  Set<String> _namesForReferenceToDeclaredVariableInInitializer = new Set<String>();

  /**
   * A list of types used by the {@link CompileTimeErrorCode#EXTENDS_DISALLOWED_CLASS} and{@link CompileTimeErrorCode#IMPLEMENTS_DISALLOWED_CLASS} error codes.
   */
  List<InterfaceType> _DISALLOWED_TYPES_TO_EXTEND_OR_IMPLEMENT;
  ErrorVerifier(ErrorReporter errorReporter, LibraryElement currentLibrary, TypeProvider typeProvider, InheritanceManager inheritanceManager) {
    this._errorReporter = errorReporter;
    this._currentLibrary = currentLibrary;
    this._isInSystemLibrary = currentLibrary.source.isInSystemLibrary();
    this._typeProvider = typeProvider;
    this._inheritanceManager = inheritanceManager;
    _strictMode = currentLibrary.context.analysisOptions.strictMode;
    _isEnclosingConstructorConst = false;
    _isInCatchClause = false;
    _dynamicType = typeProvider.dynamicType;
    _DISALLOWED_TYPES_TO_EXTEND_OR_IMPLEMENT = <InterfaceType> [typeProvider.numType, typeProvider.intType, typeProvider.doubleType, typeProvider.boolType, typeProvider.stringType];
  }
  Object visitArgumentDefinitionTest(ArgumentDefinitionTest node) {
    checkForArgumentDefinitionTestNonParameter(node);
    return super.visitArgumentDefinitionTest(node);
  }
  Object visitArgumentList(ArgumentList node) {
    checkForArgumentTypeNotAssignable(node);
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
      checkForInvalidAssignment2(node.leftHandSide, node.rightHandSide);
    } else {
      checkForInvalidAssignment(node);
    }
    checkForAssignmentToFinal(node);
    return super.visitAssignmentExpression(node);
  }
  Object visitBinaryExpression(BinaryExpression node) {
    checkForArgumentTypeNotAssignable2(node.rightOperand);
    return super.visitBinaryExpression(node);
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
      _enclosingClass = node.element;
      WithClause withClause = node.withClause;
      ImplementsClause implementsClause = node.implementsClause;
      ExtendsClause extendsClause = node.extendsClause;
      checkForBuiltInIdentifierAsName(node.name, CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME);
      checkForMemberWithClassName();
      checkForAllMixinErrorCodes(withClause);
      if (implementsClause != null || extendsClause != null) {
        if (!checkForImplementsDisallowedClass(implementsClause) && !checkForExtendsDisallowedClass(extendsClause)) {
          checkForNonAbstractClassInheritsAbstractMember(node);
          checkForInconsistentMethodInheritance();
          checkForRecursiveInterfaceInheritance(_enclosingClass, new List<ClassElement>());
        }
      }
      ClassElement classElement = node.element;
      if (classElement != null) {
        List<FieldElement> fieldElements = classElement.fields;
        _initialFieldElementsMap = new Map<FieldElement, INIT_STATE>();
        for (FieldElement fieldElement in fieldElements) {
          if (!fieldElement.isSynthetic()) {
            _initialFieldElementsMap[fieldElement] = fieldElement.initializer == null ? INIT_STATE.NOT_INIT : INIT_STATE.INIT_IN_DECLARATION;
          }
        }
      }
      checkForFinalNotInitialized(node);
      return super.visitClassDeclaration(node);
    } finally {
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
      checkForRecursiveInterfaceInheritance(node.element, new List<ClassElement>());
    } finally {
      _enclosingClass = outerClassElement;
    }
    return super.visitClassTypeAlias(node);
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
      checkForConflictingConstructorNameAndMember(node);
      checkForAllFinalInitializedErrorCodes(node);
      checkForRedirectingConstructorErrorCodes(node);
      checkForMultipleSuperInitializers(node);
      checkForRecursiveConstructorRedirect(node);
      checkForRecursiveFactoryRedirect(node);
      checkForAllRedirectConstructorErrorCodes(node);
      checkForUndefinedConstructorInInitializerImplicit(node);
      checkForRedirectToNonConstConstructor(node);
      return super.visitConstructorDeclaration(node);
    } finally {
      _isEnclosingConstructorConst = false;
      _enclosingFunction = outerFunction;
    }
  }
  Object visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    _isInConstructorInitializer = true;
    try {
      checkForFieldInitializerNotAssignable(node);
      return super.visitConstructorFieldInitializer(node);
    } finally {
      _isInConstructorInitializer = false;
    }
  }
  Object visitDefaultFormalParameter(DefaultFormalParameter node) {
    checkForPrivateOptionalParameter(node);
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
  Object visitFieldDeclaration(FieldDeclaration node) {
    if (!node.isStatic()) {
      VariableDeclarationList variables = node.fields;
      if (variables.isConst()) {
        _errorReporter.reportError4(CompileTimeErrorCode.CONST_INSTANCE_FIELD, variables.keyword, []);
      }
    }
    return super.visitFieldDeclaration(node);
  }
  Object visitFieldFormalParameter(FieldFormalParameter node) {
    checkForConstFormalParameter(node);
    checkForFieldInitializingFormalRedirectingConstructor(node);
    return super.visitFieldFormalParameter(node);
  }
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    ExecutableElement outerFunction = _enclosingFunction;
    try {
      SimpleIdentifier identifier = node.name;
      String methoName = "";
      if (identifier != null) {
        methoName = identifier.name;
      }
      _enclosingFunction = node.element;
      if (node.isSetter() || node.isGetter()) {
        checkForMismatchedAccessorTypes(node, methoName);
        if (node.isSetter()) {
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
    ExecutableElement outerFunction = _enclosingFunction;
    try {
      _enclosingFunction = node.element;
      return super.visitFunctionExpression(node);
    } finally {
      _enclosingFunction = outerFunction;
    }
  }
  Object visitFunctionTypeAlias(FunctionTypeAlias node) {
    checkForBuiltInIdentifierAsName(node.name, CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME);
    checkForDefaultValueInFunctionTypeAlias(node);
    return super.visitFunctionTypeAlias(node);
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
    checkForArgumentTypeNotAssignable2(node.index);
    return super.visitIndexExpression(node);
  }
  Object visitInstanceCreationExpression(InstanceCreationExpression node) {
    ConstructorName constructorName = node.constructorName;
    TypeName typeName = constructorName.type;
    Type2 type = typeName.type;
    if (type is InterfaceType) {
      InterfaceType interfaceType = type as InterfaceType;
      checkForConstOrNewWithAbstractClass(node, typeName, interfaceType);
      if (node.isConst()) {
        checkForConstWithNonConst(node);
        checkForConstWithUndefinedConstructor(node);
        checkForConstWithTypeParameters(node);
      } else {
        checkForNewWithUndefinedConstructor(node);
      }
      checkForTypeArgumentNotMatchingBounds(node, constructorName.element, typeName);
    }
    return super.visitInstanceCreationExpression(node);
  }
  Object visitListLiteral(ListLiteral node) {
    if (node.modifier != null) {
      TypeArgumentList typeArguments = node.typeArguments;
      if (typeArguments != null) {
        NodeList<TypeName> arguments = typeArguments.arguments;
        if (arguments.length != 0) {
          checkForInvalidTypeArgumentInConstTypedLiteral(arguments, CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_LIST);
        }
      }
    }
    return super.visitListLiteral(node);
  }
  Object visitMapLiteral(MapLiteral node) {
    TypeArgumentList typeArguments = node.typeArguments;
    if (typeArguments != null) {
      NodeList<TypeName> arguments = typeArguments.arguments;
      if (arguments.length != 0) {
        checkForInvalidTypeArgumentForKey(arguments);
        if (node.modifier != null) {
          checkForInvalidTypeArgumentInConstTypedLiteral(arguments, CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_MAP);
        }
      }
    }
    checkForNonConstMapAsExpressionStatement(node);
    return super.visitMapLiteral(node);
  }
  Object visitMethodDeclaration(MethodDeclaration node) {
    ExecutableElement previousFunction = _enclosingFunction;
    try {
      _enclosingFunction = node.element;
      SimpleIdentifier identifier = node.name;
      String methoName = "";
      if (identifier != null) {
        methoName = identifier.name;
      }
      if (node.isSetter() || node.isGetter()) {
        checkForMismatchedAccessorTypes(node, methoName);
        checkForConflictingInstanceGetterAndSuperclassMember(node);
      }
      if (node.isGetter()) {
        checkForConflictingStaticGetterAndInstanceSetter(node);
      } else if (node.isSetter()) {
        checkForWrongNumberOfParametersForSetter(node.name, node.parameters);
        checkForNonVoidReturnTypeForSetter(node.returnType);
        checkForConflictingStaticSetterAndInstanceMember(node);
      } else if (node.isOperator()) {
        checkForOptionalParameterInOperator(node);
        checkForWrongNumberOfParametersForOperator(node);
        checkForNonVoidReturnTypeForOperator(node);
      }
      checkForConcreteClassWithAbstractMember(node);
      checkForAllInvalidOverrideErrorCodes(node);
      return super.visitMethodDeclaration(node);
    } finally {
      _enclosingFunction = previousFunction;
    }
  }
  Object visitMethodInvocation(MethodInvocation node) {
    checkForStaticAccessToInstanceMember(node.target, node.methodName);
    return super.visitMethodInvocation(node);
  }
  Object visitNativeFunctionBody(NativeFunctionBody node) {
    checkForNativeFunctionBodyInNonSDKCode(node);
    return super.visitNativeFunctionBody(node);
  }
  Object visitPostfixExpression(PostfixExpression node) {
    checkForAssignmentToFinal2(node.operand);
    return super.visitPostfixExpression(node);
  }
  Object visitPrefixedIdentifier(PrefixedIdentifier node) {
    checkForStaticAccessToInstanceMember(node.prefix, node.identifier);
    return super.visitPrefixedIdentifier(node);
  }
  Object visitPrefixExpression(PrefixExpression node) {
    if (node.operator.type.isIncrementOperator()) {
      checkForAssignmentToFinal2(node.operand);
    }
    return super.visitPrefixExpression(node);
  }
  Object visitPropertyAccess(PropertyAccess node) {
    checkForStaticAccessToInstanceMember(node.target, node.propertyName);
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
    checkForAllReturnStatementErrorCodes(node);
    return super.visitReturnStatement(node);
  }
  Object visitSimpleFormalParameter(SimpleFormalParameter node) {
    checkForConstFormalParameter(node);
    return super.visitSimpleFormalParameter(node);
  }
  Object visitSimpleIdentifier(SimpleIdentifier node) {
    checkForReferenceToDeclaredVariableInInitializer(node);
    checkForImplicitThisReferenceInInitializer(node);
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
    checkForCaseExpressionTypeImplementsEquals(node);
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
    checkForFinalNotInitialized2(node.variables);
    return super.visitTopLevelVariableDeclaration(node);
  }
  Object visitTypeParameter(TypeParameter node) {
    checkForBuiltInIdentifierAsName(node.name, CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_VARIABLE_NAME);
    return super.visitTypeParameter(node);
  }
  Object visitVariableDeclaration(VariableDeclaration node) {
    SimpleIdentifier nameNode = node.name;
    Expression initializerNode = node.initializer;
    checkForInvalidAssignment2(nameNode, initializerNode);
    nameNode.accept(this);
    String name = nameNode.name;
    javaSetAdd(_namesForReferenceToDeclaredVariableInInitializer, name);
    try {
      if (initializerNode != null) {
        initializerNode.accept(this);
      }
    } finally {
      _namesForReferenceToDeclaredVariableInInitializer.remove(name);
    }
    return null;
  }
  Object visitVariableDeclarationList(VariableDeclarationList node) {
    checkForBuiltInIdentifierAsName2(node);
    return super.visitVariableDeclarationList(node);
  }
  Object visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    checkForFinalNotInitialized2(node.variables);
    return super.visitVariableDeclarationStatement(node);
  }
  Object visitWhileStatement(WhileStatement node) {
    checkForNonBoolCondition(node.condition);
    return super.visitWhileStatement(node);
  }

  /**
   * This verifies that the passed constructor declaration does not violate any of the error codes
   * relating to the initialization of fields in the enclosing class.
   * @param node the {@link ConstructorDeclaration} to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see #initialFieldElementsMap
   * @see CompileTimeErrorCode#FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR
   * @see CompileTimeErrorCode#FINAL_INITIALIZED_MULTIPLE_TIMES
   */
  bool checkForAllFinalInitializedErrorCodes(ConstructorDeclaration node) {
    if (node.factoryKeyword != null || node.redirectedConstructor != null || node.externalKeyword != null) {
      return false;
    }
    bool foundError = false;
    Map<FieldElement, INIT_STATE> fieldElementsMap = new Map<FieldElement, INIT_STATE>.from(_initialFieldElementsMap);
    NodeList<FormalParameter> formalParameters = node.parameters.parameters;
    for (FormalParameter formalParameter in formalParameters) {
      FormalParameter parameter = formalParameter;
      if (parameter is DefaultFormalParameter) {
        parameter = ((parameter as DefaultFormalParameter)).parameter;
      }
      if (parameter is FieldFormalParameter) {
        FieldElement fieldElement = ((parameter.element as FieldFormalParameterElementImpl)).field;
        INIT_STATE state = fieldElementsMap[fieldElement];
        if (identical(state, INIT_STATE.NOT_INIT)) {
          fieldElementsMap[fieldElement] = INIT_STATE.INIT_IN_FIELD_FORMAL;
        } else if (identical(state, INIT_STATE.INIT_IN_DECLARATION)) {
          if (fieldElement.isFinal() || fieldElement.isConst()) {
            _errorReporter.reportError2(CompileTimeErrorCode.FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR, formalParameter.identifier, [fieldElement.displayName]);
            foundError = true;
          }
        } else if (identical(state, INIT_STATE.INIT_IN_FIELD_FORMAL)) {
          if (fieldElement.isFinal() || fieldElement.isConst()) {
            _errorReporter.reportError2(CompileTimeErrorCode.FINAL_INITIALIZED_MULTIPLE_TIMES, formalParameter.identifier, [fieldElement.displayName]);
            foundError = true;
          }
        }
      }
    }
    NodeList<ConstructorInitializer> initializers = node.initializers;
    for (ConstructorInitializer constructorInitializer in initializers) {
      if (constructorInitializer is ConstructorFieldInitializer) {
        ConstructorFieldInitializer constructorFieldInitializer = constructorInitializer as ConstructorFieldInitializer;
        SimpleIdentifier fieldName = constructorFieldInitializer.fieldName;
        Element element = fieldName.element;
        if (element is FieldElement) {
          FieldElement fieldElement = element as FieldElement;
          INIT_STATE state = fieldElementsMap[fieldElement];
          if (identical(state, INIT_STATE.NOT_INIT)) {
            fieldElementsMap[fieldElement] = INIT_STATE.INIT_IN_INITIALIZERS;
          } else if (identical(state, INIT_STATE.INIT_IN_DECLARATION)) {
            if (fieldElement.isFinal() || fieldElement.isConst()) {
              _errorReporter.reportError2(CompileTimeErrorCode.FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION, fieldName, []);
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
    return foundError;
  }

  /**
   * This checks the passed method declaration against override-error codes.
   * @param node the {@link MethodDeclaration} to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
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
   */
  bool checkForAllInvalidOverrideErrorCodes(MethodDeclaration node) {
    if (_enclosingClass == null || node.isStatic() || node.body is NativeFunctionBody) {
      return false;
    }
    ExecutableElement executableElement = node.element;
    if (executableElement == null) {
      return false;
    }
    SimpleIdentifier methodName = node.name;
    if (methodName.isSynthetic()) {
      return false;
    }
    String methodNameStr = methodName.name;
    ExecutableElement overriddenExecutable = _inheritanceManager.lookupInheritance(_enclosingClass, executableElement.name);
    if (overriddenExecutable == null) {
      if (!node.isGetter() && !node.isSetter() && !node.isOperator()) {
        Set<ClassElement> visitedClasses = new Set<ClassElement>();
        InterfaceType superclassType = _enclosingClass.supertype;
        ClassElement superclassElement = superclassType == null ? null : superclassType.element;
        while (superclassElement != null && !visitedClasses.contains(superclassElement)) {
          javaSetAdd(visitedClasses, superclassElement);
          List<FieldElement> fieldElts = superclassElement.fields;
          for (FieldElement fieldElt in fieldElts) {
            if (fieldElt.name == methodNameStr && fieldElt.isStatic()) {
              _errorReporter.reportError2(StaticWarningCode.INSTANCE_METHOD_NAME_COLLIDES_WITH_SUPERCLASS_STATIC, methodName, [methodNameStr, fieldElt.enclosingElement.displayName]);
              return true;
            }
          }
          List<PropertyAccessorElement> propertyAccessorElts = superclassElement.accessors;
          for (PropertyAccessorElement accessorElt in propertyAccessorElts) {
            if (accessorElt.name == methodNameStr && accessorElt.isStatic()) {
              _errorReporter.reportError2(StaticWarningCode.INSTANCE_METHOD_NAME_COLLIDES_WITH_SUPERCLASS_STATIC, methodName, [methodNameStr, accessorElt.enclosingElement.displayName]);
              return true;
            }
          }
          List<MethodElement> methodElements = superclassElement.methods;
          for (MethodElement methodElement in methodElements) {
            if (methodElement.name == methodNameStr && methodElement.isStatic()) {
              _errorReporter.reportError2(StaticWarningCode.INSTANCE_METHOD_NAME_COLLIDES_WITH_SUPERCLASS_STATIC, methodName, [methodNameStr, methodElement.enclosingElement.displayName]);
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
    overriddenFT = _inheritanceManager.substituteTypeArgumentsInMemberFromInheritance(overriddenFT, methodNameStr, enclosingType);
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
    if (overridingNormalPT.length != overriddenNormalPT.length) {
      _errorReporter.reportError2(CompileTimeErrorCode.INVALID_OVERRIDE_REQUIRED, methodName, [overriddenNormalPT.length, overriddenExecutable.enclosingElement.displayName]);
      return true;
    }
    if (overridingPositionalPT.length < overriddenPositionalPT.length) {
      _errorReporter.reportError2(CompileTimeErrorCode.INVALID_OVERRIDE_POSITIONAL, methodName, [overriddenPositionalPT.length, overriddenExecutable.enclosingElement.displayName]);
      return true;
    }
    Set<String> overridingParameterNameSet = overridingNamedPT.keys.toSet();
    JavaIterator<String> overriddenParameterNameIterator = new JavaIterator(overriddenNamedPT.keys.toSet());
    while (overriddenParameterNameIterator.hasNext) {
      String overriddenParamName = overriddenParameterNameIterator.next();
      if (!overridingParameterNameSet.contains(overriddenParamName)) {
        _errorReporter.reportError2(CompileTimeErrorCode.INVALID_OVERRIDE_NAMED, methodName, [overriddenParamName, overriddenExecutable.enclosingElement.displayName]);
        return true;
      }
    }
    if (overriddenFTReturnType != VoidTypeImpl.instance && !overridingFTReturnType.isAssignableTo(overriddenFTReturnType)) {
      _errorReporter.reportError2(!node.isGetter() ? StaticWarningCode.INVALID_METHOD_OVERRIDE_RETURN_TYPE : StaticWarningCode.INVALID_GETTER_OVERRIDE_RETURN_TYPE, methodName, [overridingFTReturnType.displayName, overriddenFTReturnType.displayName, overriddenExecutable.enclosingElement.displayName]);
      return true;
    }
    FormalParameterList formalParameterList = node.parameters;
    if (formalParameterList == null) {
      return false;
    }
    NodeList<FormalParameter> parameterNodeList = formalParameterList.parameters;
    int parameterIndex = 0;
    for (int i = 0; i < overridingNormalPT.length; i++) {
      if (!overridingNormalPT[i].isAssignableTo(overriddenNormalPT[i])) {
        _errorReporter.reportError2(!node.isSetter() ? StaticWarningCode.INVALID_METHOD_OVERRIDE_NORMAL_PARAM_TYPE : StaticWarningCode.INVALID_SETTER_OVERRIDE_NORMAL_PARAM_TYPE, parameterNodeList[parameterIndex], [overridingNormalPT[i].displayName, overriddenNormalPT[i].displayName, overriddenExecutable.enclosingElement.displayName]);
        return true;
      }
      parameterIndex++;
    }
    for (int i = 0; i < overriddenPositionalPT.length; i++) {
      if (!overridingPositionalPT[i].isAssignableTo(overriddenPositionalPT[i])) {
        _errorReporter.reportError2(StaticWarningCode.INVALID_METHOD_OVERRIDE_OPTIONAL_PARAM_TYPE, parameterNodeList[parameterIndex], [overridingPositionalPT[i].displayName, overriddenPositionalPT[i].displayName, overriddenExecutable.enclosingElement.displayName]);
        return true;
      }
      parameterIndex++;
    }
    JavaIterator<MapEntry<String, Type2>> overriddenNamedPTIterator = new JavaIterator(getMapEntrySet(overriddenNamedPT));
    while (overriddenNamedPTIterator.hasNext) {
      MapEntry<String, Type2> overriddenNamedPTEntry = overriddenNamedPTIterator.next();
      Type2 overridingType = overridingNamedPT[overriddenNamedPTEntry.getKey()];
      if (overridingType == null) {
        continue;
      }
      if (!overriddenNamedPTEntry.getValue().isAssignableTo(overridingType)) {
        NormalFormalParameter parameterToSelect = null;
        for (FormalParameter formalParameter in parameterNodeList) {
          if (formalParameter is DefaultFormalParameter && identical(formalParameter.kind, ParameterKind.NAMED)) {
            DefaultFormalParameter defaultFormalParameter = formalParameter as DefaultFormalParameter;
            NormalFormalParameter normalFormalParameter = defaultFormalParameter.parameter;
            if (overriddenNamedPTEntry.getKey() == normalFormalParameter.identifier.name) {
              parameterToSelect = normalFormalParameter;
              break;
            }
          }
        }
        if (parameterToSelect != null) {
          _errorReporter.reportError2(StaticWarningCode.INVALID_METHOD_OVERRIDE_NAMED_PARAM_TYPE, parameterToSelect, [overridingType.displayName, overriddenNamedPTEntry.getValue().displayName, overriddenExecutable.enclosingElement.displayName]);
          return true;
        }
      }
    }
    return false;
  }

  /**
   * This verifies that all classes of the passed 'with' clause are valid.
   * @param node the 'with' clause to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
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
      ClassElement mixinElement = ((mixinType as InterfaceType)).element;
      problemReported = javaBooleanOr(problemReported, checkForMixinDeclaresConstructor(mixinName, mixinElement));
      problemReported = javaBooleanOr(problemReported, checkForMixinInheritsNotFromObject(mixinName, mixinElement));
      problemReported = javaBooleanOr(problemReported, checkForMixinReferencesSuper(mixinName, mixinElement));
    }
    return problemReported;
  }

  /**
   * This checks error related to the redirected constructors.
   * @param node the constructor declaration to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see StaticWarningCode#REDIRECT_TO_INVALID_RETURN_TYPE
   * @see StaticWarningCode#REDIRECT_TO_INVALID_FUNCTION_TYPE
   * @see StaticWarningCode#REDIRECT_TO_MISSING_CONSTRUCTOR
   */
  bool checkForAllRedirectConstructorErrorCodes(ConstructorDeclaration node) {
    ConstructorName redirectedNode = node.redirectedConstructor;
    if (redirectedNode == null) {
      return false;
    }
    ConstructorElement redirectedElement = redirectedNode.element;
    if (redirectedElement == null) {
      TypeName constructorTypeName = redirectedNode.type;
      Type2 redirectedType = constructorTypeName.type;
      if (redirectedType != null && redirectedType.element != null && redirectedType.element != DynamicElementImpl.instance) {
        String constructorStrName = constructorTypeName.name.name;
        if (redirectedNode.name != null) {
          constructorStrName += ".${redirectedNode.name.name}";
        }
        _errorReporter.reportError2(StaticWarningCode.REDIRECT_TO_MISSING_CONSTRUCTOR, redirectedNode, [constructorStrName, redirectedType.displayName]);
        return true;
      }
      return false;
    }
    FunctionType redirectedType = redirectedElement.type;
    Type2 redirectedReturnType = redirectedType.returnType;
    FunctionType constructorType = node.element.type;
    Type2 constructorReturnType = constructorType.returnType;
    if (!redirectedReturnType.isSubtypeOf(constructorReturnType)) {
      _errorReporter.reportError2(StaticWarningCode.REDIRECT_TO_INVALID_RETURN_TYPE, redirectedNode, [redirectedReturnType, constructorReturnType]);
      return true;
    }
    if (!redirectedType.isSubtypeOf(constructorType)) {
      _errorReporter.reportError2(StaticWarningCode.REDIRECT_TO_INVALID_FUNCTION_TYPE, redirectedNode, [redirectedType, constructorType]);
      return true;
    }
    return false;
  }

  /**
   * This checks that the return statement of the form <i>return e;</i> is not in a generative
   * constructor.
   * <p>
   * This checks that return statements without expressions are not in a generative constructor and
   * the return type is not assignable to {@code null}; that is, we don't have {@code return;} if
   * the enclosing method has a return type.
   * <p>
   * This checks that the return type matches the type of the declared return type in the enclosing
   * method or function.
   * @param node the return statement to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#RETURN_IN_GENERATIVE_CONSTRUCTOR
   * @see StaticWarningCode#RETURN_WITHOUT_VALUE
   * @see StaticTypeWarningCode#RETURN_OF_INVALID_TYPE
   */
  bool checkForAllReturnStatementErrorCodes(ReturnStatement node) {
    FunctionType functionType = _enclosingFunction == null ? null : _enclosingFunction.type;
    Type2 expectedReturnType = functionType == null ? DynamicTypeImpl.instance : functionType.returnType;
    Expression returnExpression = node.expression;
    bool isGenerativeConstructor = _enclosingFunction is ConstructorElement && !((_enclosingFunction as ConstructorElement)).isFactory();
    if (isGenerativeConstructor) {
      if (returnExpression == null) {
        return false;
      }
      _errorReporter.reportError2(CompileTimeErrorCode.RETURN_IN_GENERATIVE_CONSTRUCTOR, returnExpression, []);
      return true;
    }
    if (returnExpression == null) {
      if (VoidTypeImpl.instance.isAssignableTo(expectedReturnType)) {
        return false;
      }
      _errorReporter.reportError2(StaticWarningCode.RETURN_WITHOUT_VALUE, node, []);
      return true;
    }
    Type2 staticReturnType = getStaticType(returnExpression);
    if (expectedReturnType.isVoid()) {
      if (staticReturnType.isVoid() || staticReturnType.isDynamic() || identical(staticReturnType, BottomTypeImpl.instance)) {
        return false;
      }
      _errorReporter.reportError2(StaticTypeWarningCode.RETURN_OF_INVALID_TYPE, returnExpression, [staticReturnType.displayName, expectedReturnType.displayName, _enclosingFunction.displayName]);
      return true;
    }
    bool isStaticAssignable = staticReturnType.isAssignableTo(expectedReturnType);
    Type2 propagatedReturnType = getPropagatedType(returnExpression);
    if (_strictMode || propagatedReturnType == null) {
      if (isStaticAssignable) {
        return false;
      }
      _errorReporter.reportError2(StaticTypeWarningCode.RETURN_OF_INVALID_TYPE, returnExpression, [staticReturnType.displayName, expectedReturnType.displayName, _enclosingFunction.displayName]);
      return true;
    } else {
      bool isPropagatedAssignable = propagatedReturnType.isAssignableTo(expectedReturnType);
      if (isStaticAssignable || isPropagatedAssignable) {
        return false;
      }
      _errorReporter.reportError2(StaticTypeWarningCode.RETURN_OF_INVALID_TYPE, returnExpression, [staticReturnType.displayName, expectedReturnType.displayName, _enclosingFunction.displayName]);
      return true;
    }
  }

  /**
   * This verifies that the export namespace of the passed export directive does not export any name
   * already exported by other export directive.
   * @param node the export directive node to report problem on
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#AMBIGUOUS_EXPORT
   */
  bool checkForAmbiguousExport(ExportDirective node) {
    if (node.element is! ExportElement) {
      return false;
    }
    ExportElement exportElement = node.element as ExportElement;
    LibraryElement exportedLibrary = exportElement.exportedLibrary;
    if (exportedLibrary == null) {
      return false;
    }
    Namespace namespace = new NamespaceBuilder().createExportNamespace(exportElement);
    Set<String> newNames = namespace.definedNames.keys.toSet();
    for (String name in newNames) {
      ExportElement prevElement = _exportedNames[name];
      if (prevElement != null && prevElement != exportElement) {
        _errorReporter.reportError2(CompileTimeErrorCode.AMBIGUOUS_EXPORT, node, [name, prevElement.exportedLibrary.definingCompilationUnit.displayName, exportedLibrary.definingCompilationUnit.displayName]);
        return true;
      } else {
        _exportedNames[name] = exportElement;
      }
    }
    return false;
  }

  /**
   * This verifies that the passed argument definition test identifier is a parameter.
   * @param node the {@link ArgumentDefinitionTest} to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#ARGUMENT_DEFINITION_TEST_NON_PARAMETER
   */
  bool checkForArgumentDefinitionTestNonParameter(ArgumentDefinitionTest node) {
    SimpleIdentifier identifier = node.identifier;
    Element element = identifier.element;
    if (element != null && element is! ParameterElement) {
      _errorReporter.reportError2(CompileTimeErrorCode.ARGUMENT_DEFINITION_TEST_NON_PARAMETER, identifier, [identifier.name]);
      return true;
    }
    return false;
  }

  /**
   * This verifies that the passed arguments can be assigned to their corresponding parameters.
   * @param node the arguments to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see StaticWarningCode#ARGUMENT_TYPE_NOT_ASSIGNABLE
   */
  bool checkForArgumentTypeNotAssignable(ArgumentList argumentList) {
    if (argumentList == null) {
      return false;
    }
    bool problemReported = false;
    for (Expression argument in argumentList.arguments) {
      problemReported = javaBooleanOr(problemReported, checkForArgumentTypeNotAssignable2(argument));
    }
    return problemReported;
  }

  /**
   * This verifies that the passed argument can be assigned to their corresponding parameters.
   * @param node the argument to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see StaticWarningCode#ARGUMENT_TYPE_NOT_ASSIGNABLE
   */
  bool checkForArgumentTypeNotAssignable2(Expression argument) {
    if (argument == null) {
      return false;
    }
    ParameterElement staticParameterElement = argument.staticParameterElement;
    Type2 staticParameterType = staticParameterElement == null ? null : staticParameterElement.type;
    Type2 staticArgumentType = getStaticType(argument);
    if (staticArgumentType == null || staticParameterType == null) {
      return false;
    }
    if (_strictMode) {
      if (staticArgumentType.isAssignableTo(staticParameterType)) {
        return false;
      }
      _errorReporter.reportError2(StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, argument, [staticArgumentType.displayName, staticParameterType.displayName]);
      return true;
    }
    ParameterElement propagatedParameterElement = argument.parameterElement;
    Type2 propagatedParameterType = propagatedParameterElement == null ? null : propagatedParameterElement.type;
    Type2 propagatedArgumentType = getPropagatedType(argument);
    if (propagatedArgumentType == null || propagatedParameterType == null) {
      if (staticArgumentType.isAssignableTo(staticParameterType)) {
        return false;
      }
      _errorReporter.reportError2(StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, argument, [staticArgumentType.displayName, staticParameterType.displayName]);
      return true;
    }
    if (staticArgumentType.isAssignableTo(staticParameterType) || staticArgumentType.isAssignableTo(propagatedParameterType) || propagatedArgumentType.isAssignableTo(staticParameterType) || propagatedArgumentType.isAssignableTo(propagatedParameterType)) {
      return false;
    }
    _errorReporter.reportError2(StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, argument, [(propagatedArgumentType == null ? staticArgumentType : propagatedArgumentType).displayName, (propagatedParameterType == null ? staticParameterType : propagatedParameterType).displayName]);
    return true;
  }

  /**
   * This verifies that left hand side of the passed assignment expression is not final.
   * @param node the assignment expression to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see StaticWarningCode#ASSIGNMENT_TO_FINAL
   */
  bool checkForAssignmentToFinal(AssignmentExpression node) {
    Expression leftExpression = node.leftHandSide;
    return checkForAssignmentToFinal2(leftExpression);
  }

  /**
   * This verifies that the passed expression is not final.
   * @param node the expression to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see StaticWarningCode#ASSIGNMENT_TO_FINAL
   */
  bool checkForAssignmentToFinal2(Expression expression) {
    Element element = null;
    if (expression is Identifier) {
      element = ((expression as Identifier)).element;
    }
    if (expression is PropertyAccess) {
      element = ((expression as PropertyAccess)).propertyName.element;
    }
    if (element is VariableElement) {
      VariableElement leftVar = element as VariableElement;
      if (leftVar.isFinal()) {
        _errorReporter.reportError2(StaticWarningCode.ASSIGNMENT_TO_FINAL, expression, []);
        return true;
      }
      return false;
    }
    if (element is PropertyAccessorElement) {
      PropertyAccessorElement leftAccessor = element as PropertyAccessorElement;
      if (!leftAccessor.isSetter()) {
        _errorReporter.reportError2(StaticWarningCode.ASSIGNMENT_TO_FINAL, expression, []);
        return true;
      }
      return false;
    }
    return false;
  }

  /**
   * This verifies that the passed identifier is not a keyword, and generates the passed error code
   * on the identifier if it is a keyword.
   * @param identifier the identifier to check to ensure that it is not a keyword
   * @param errorCode if the passed identifier is a keyword then this error code is created on the
   * identifier, the error code will be one of{@link CompileTimeErrorCode#BUILT_IN_IDENTIFIER_AS_TYPE_NAME},{@link CompileTimeErrorCode#BUILT_IN_IDENTIFIER_AS_TYPE_VARIABLE_NAME} or{@link CompileTimeErrorCode#BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME}
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#BUILT_IN_IDENTIFIER_AS_TYPE_NAME
   * @see CompileTimeErrorCode#BUILT_IN_IDENTIFIER_AS_TYPE_VARIABLE_NAME
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
   * This verifies that the passed variable declaration list does not have a built-in identifier.
   * @param node the variable declaration list to check
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#BUILT_IN_IDENTIFIER_AS_TYPE
   */
  bool checkForBuiltInIdentifierAsName2(VariableDeclarationList node) {
    TypeName typeName = node.type;
    if (typeName != null) {
      Identifier identifier = typeName.name;
      if (identifier is SimpleIdentifier) {
        SimpleIdentifier simpleIdentifier = identifier as SimpleIdentifier;
        sc.Token token = simpleIdentifier.token;
        if (identical(token.type, sc.TokenType.KEYWORD)) {
          if (((token as sc.KeywordToken)).keyword != sc.Keyword.DYNAMIC) {
            _errorReporter.reportError2(CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE, identifier, [identifier.name]);
            return true;
          }
        }
      }
    }
    return false;
  }

  /**
   * This verifies that the given switch case is terminated with 'break', 'continue', 'return' or
   * 'throw'.
   * @param node the switch case to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see StaticWarningCode#CASE_BLOCK_NOT_TERMINATED
   */
  bool checkForCaseBlockNotTerminated(SwitchCase node) {
    NodeList<Statement> statements = node.statements;
    if (statements.isEmpty) {
      ASTNode parent = node.parent;
      if (parent is SwitchStatement) {
        SwitchStatement switchStatement = parent as SwitchStatement;
        NodeList<SwitchMember> members = switchStatement.members;
        int index = members.indexOf(node);
        if (index != -1 && index < members.length - 1) {
          return false;
        }
      }
    } else {
      Statement statement = statements[statements.length - 1];
      if (statement is BreakStatement || statement is ContinueStatement || statement is ReturnStatement) {
        return false;
      }
      if (statement is ExpressionStatement) {
        Expression expression = ((statement as ExpressionStatement)).expression;
        if (expression is ThrowExpression) {
          return false;
        }
      }
    }
    _errorReporter.reportError4(StaticWarningCode.CASE_BLOCK_NOT_TERMINATED, node.keyword, []);
    return true;
  }

  /**
   * This verifies that the switch cases in the given switch statement is terminated with 'break',
   * 'continue', 'return' or 'throw'.
   * @param node the switch statement containing the cases to be checked
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see StaticWarningCode#CASE_BLOCK_NOT_TERMINATED
   */
  bool checkForCaseBlocksNotTerminated(SwitchStatement node) {
    bool foundError = false;
    NodeList<SwitchMember> members = node.members;
    int lastMember = members.length - 1;
    for (int i = 0; i < lastMember; i++) {
      SwitchMember member = members[i];
      if (member is SwitchCase) {
        foundError = javaBooleanOr(foundError, checkForCaseBlockNotTerminated((member as SwitchCase)));
      }
    }
    return foundError;
  }

  /**
   * This verifies that the passed switch statement does not have a case expression with the
   * operator '==' overridden.
   * @param node the switch statement to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS
   */
  bool checkForCaseExpressionTypeImplementsEquals(SwitchStatement node) {
    Expression expression = node.expression;
    Type2 type = getStaticType(expression);
    if (type != null && type != _typeProvider.intType && type != _typeProvider.stringType) {
      Element element = type.element;
      if (element is ClassElement) {
        ClassElement classElement = element as ClassElement;
        MethodElement method = classElement.lookUpMethod("==", _currentLibrary);
        if (method != null && method.enclosingElement.type != _typeProvider.objectType) {
          _errorReporter.reportError2(CompileTimeErrorCode.CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS, expression, [element.displayName]);
          return true;
        }
      }
    }
    return false;
  }

  /**
   * This verifies that the passed method declaration is abstract only if the enclosing class is
   * also abstract.
   * @param node the method declaration to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see StaticWarningCode#CONCRETE_CLASS_WITH_ABSTRACT_MEMBER
   */
  bool checkForConcreteClassWithAbstractMember(MethodDeclaration node) {
    if (node.isAbstract() && _enclosingClass != null && !_enclosingClass.isAbstract()) {
      SimpleIdentifier methodName = node.name;
      _errorReporter.reportError2(StaticWarningCode.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER, methodName, [methodName.name, _enclosingClass.displayName]);
      return true;
    }
    return false;
  }

  /**
   * This verifies all possible conflicts of the constructor name with other constructors and
   * members of the same class.
   * @param node the constructor declaration to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
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
    if (constructorName != null && constructorElement != null && !constructorName.isSynthetic()) {
      List<FieldElement> fields = classElement.fields;
      for (FieldElement field in fields) {
        if (field.name == name) {
          _errorReporter.reportError2(CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_NAME_AND_FIELD, node, [name]);
          return true;
        }
      }
      List<MethodElement> methods = classElement.methods;
      for (MethodElement method in methods) {
        if (method.name == name) {
          _errorReporter.reportError2(CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_NAME_AND_METHOD, node, [name]);
          return true;
        }
      }
    }
    return false;
  }

  /**
   * This verifies that the superclass of the enclosing class does not declare accessible static
   * member with the same name as the passed instance getter/setter method declaration.
   * @param node the method declaration to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see StaticWarningCode#CONFLICTING_INSTANCE_GETTER_AND_SUPERCLASS_MEMBER
   * @see StaticWarningCode#CONFLICTING_INSTANCE_SETTER_AND_SUPERCLASS_MEMBER
   */
  bool checkForConflictingInstanceGetterAndSuperclassMember(MethodDeclaration node) {
    if (node.isStatic()) {
      return false;
    }
    SimpleIdentifier nameNode = node.name;
    if (nameNode == null) {
      return false;
    }
    String name = nameNode.name;
    if (_enclosingClass == null) {
      return false;
    }
    InterfaceType enclosingType = _enclosingClass.type;
    ExecutableElement superElement;
    superElement = enclosingType.lookUpGetterInSuperclass(name, _currentLibrary);
    if (superElement == null) {
      superElement = enclosingType.lookUpSetterInSuperclass(name, _currentLibrary);
    }
    if (superElement == null) {
      superElement = enclosingType.lookUpMethodInSuperclass(name, _currentLibrary);
    }
    if (superElement == null) {
      return false;
    }
    if (!superElement.isStatic()) {
      return false;
    }
    ClassElement superElementClass = superElement.enclosingElement as ClassElement;
    InterfaceType superElementType = superElementClass.type;
    if (node.isGetter()) {
      _errorReporter.reportError2(StaticWarningCode.CONFLICTING_INSTANCE_GETTER_AND_SUPERCLASS_MEMBER, nameNode, [superElementType.displayName]);
    } else {
      _errorReporter.reportError2(StaticWarningCode.CONFLICTING_INSTANCE_SETTER_AND_SUPERCLASS_MEMBER, nameNode, [superElementType.displayName]);
    }
    return true;
  }

  /**
   * This verifies that the enclosing class does not have an instance member with the same name as
   * the passed static getter method declaration.
   * @param node the method declaration to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see StaticWarningCode#CONFLICTING_STATIC_GETTER_AND_INSTANCE_SETTER
   */
  bool checkForConflictingStaticGetterAndInstanceSetter(MethodDeclaration node) {
    if (!node.isStatic()) {
      return false;
    }
    SimpleIdentifier nameNode = node.name;
    if (nameNode == null) {
      return false;
    }
    String name = nameNode.name;
    if (_enclosingClass == null) {
      return false;
    }
    InterfaceType enclosingType = _enclosingClass.type;
    ExecutableElement setter = enclosingType.lookUpSetter(name, _currentLibrary);
    if (setter == null) {
      return false;
    }
    if (setter.isStatic()) {
      return false;
    }
    ClassElement setterClass = setter.enclosingElement as ClassElement;
    InterfaceType setterType = setterClass.type;
    _errorReporter.reportError2(StaticWarningCode.CONFLICTING_STATIC_GETTER_AND_INSTANCE_SETTER, nameNode, [setterType.displayName]);
    return true;
  }

  /**
   * This verifies that the enclosing class does not have an instance member with the same name as
   * the passed static getter method declaration.
   * @param node the method declaration to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see StaticWarningCode#CONFLICTING_STATIC_SETTER_AND_INSTANCE_MEMBER
   */
  bool checkForConflictingStaticSetterAndInstanceMember(MethodDeclaration node) {
    if (!node.isStatic()) {
      return false;
    }
    SimpleIdentifier nameNode = node.name;
    if (nameNode == null) {
      return false;
    }
    String name = nameNode.name;
    if (_enclosingClass == null) {
      return false;
    }
    InterfaceType enclosingType = _enclosingClass.type;
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
    if (member.isStatic()) {
      return false;
    }
    ClassElement memberClass = member.enclosingElement as ClassElement;
    InterfaceType memberType = memberClass.type;
    _errorReporter.reportError2(StaticWarningCode.CONFLICTING_STATIC_SETTER_AND_INSTANCE_MEMBER, nameNode, [memberType.displayName]);
    return true;
  }

  /**
   * This verifies that the passed constructor declaration is 'const' then there are no non-final
   * instance variable.
   * @param node the constructor declaration to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD
   */
  bool checkForConstConstructorWithNonFinalField(ConstructorDeclaration node) {
    if (!_isEnclosingConstructorConst) {
      return false;
    }
    ConstructorElement constructorElement = node.element;
    ClassElement classElement = constructorElement.enclosingElement;
    if (!classElement.hasNonFinalField()) {
      return false;
    }
    _errorReporter.reportError2(CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD, node, []);
    return true;
  }

  /**
   * This verifies that the passed throw expression is not enclosed in a 'const' constructor
   * declaration.
   * @param node the throw expression expression to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
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
   * @param node the normal formal parameter to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#CONST_FORMAL_PARAMETER
   */
  bool checkForConstFormalParameter(NormalFormalParameter node) {
    if (node.isConst()) {
      _errorReporter.reportError2(CompileTimeErrorCode.CONST_FORMAL_PARAMETER, node, []);
      return true;
    }
    return false;
  }

  /**
   * This verifies that the passed instance creation expression is not being invoked on an abstract
   * class.
   * @param node the instance creation expression to evaluate
   * @param typeName the {@link TypeName} of the {@link ConstructorName} from the{@link InstanceCreationExpression}, this is the AST node that the error is attached to
   * @param type the type being constructed with this {@link InstanceCreationExpression}
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see StaticWarningCode#CONST_WITH_ABSTRACT_CLASS
   * @see StaticWarningCode#NEW_WITH_ABSTRACT_CLASS
   */
  bool checkForConstOrNewWithAbstractClass(InstanceCreationExpression node, TypeName typeName, InterfaceType type) {
    if (type.element.isAbstract()) {
      ConstructorElement element = node.element;
      if (element != null && !element.isFactory()) {
        if (identical(((node.keyword as sc.KeywordToken)).keyword, sc.Keyword.CONST)) {
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
   * <p>
   * This method assumes that the instance creation was tested to be 'const' before being called.
   * @param node the instance creation expression to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#CONST_WITH_NON_CONST
   */
  bool checkForConstWithNonConst(InstanceCreationExpression node) {
    ConstructorElement constructorElement = node.element;
    if (constructorElement != null && !constructorElement.isConst()) {
      _errorReporter.reportError2(CompileTimeErrorCode.CONST_WITH_NON_CONST, node, []);
      return true;
    }
    return false;
  }

  /**
   * This verifies that the passed 'const' instance creation expression does not reference any type
   * parameters.
   * <p>
   * This method assumes that the instance creation was tested to be 'const' before being called.
   * @param node the instance creation expression to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#CONST_WITH_TYPE_PARAMETERS
   */
  bool checkForConstWithTypeParameters(InstanceCreationExpression node) {
    ConstructorName constructorName = node.constructorName;
    if (constructorName == null) {
      return false;
    }
    TypeName typeName = constructorName.type;
    return checkForConstWithTypeParameters2(typeName);
  }

  /**
   * This verifies that the passed type name does not reference any type parameters.
   * @param typeName the type name to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#CONST_WITH_TYPE_PARAMETERS
   */
  bool checkForConstWithTypeParameters2(TypeName typeName) {
    if (typeName == null) {
      return false;
    }
    Identifier name = typeName.name;
    if (name == null) {
      return false;
    }
    if (name.element is TypeVariableElement) {
      _errorReporter.reportError2(CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS, name, []);
    }
    TypeArgumentList typeArguments = typeName.typeArguments;
    if (typeArguments != null) {
      bool hasError = false;
      for (TypeName argument in typeArguments.arguments) {
        hasError = javaBooleanOr(hasError, checkForConstWithTypeParameters2(argument));
      }
      return hasError;
    }
    return false;
  }

  /**
   * This verifies that if the passed 'const' instance creation expression is being invoked on the
   * resolved constructor.
   * <p>
   * This method assumes that the instance creation was tested to be 'const' before being called.
   * @param node the instance creation expression to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#CONST_WITH_UNDEFINED_CONSTRUCTOR
   * @see CompileTimeErrorCode#CONST_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT
   */
  bool checkForConstWithUndefinedConstructor(InstanceCreationExpression node) {
    if (node.element != null) {
      return false;
    }
    ConstructorName constructorName = node.constructorName;
    if (constructorName == null) {
      return false;
    }
    TypeName type = constructorName.type;
    if (type == null) {
      return false;
    }
    Identifier className = type.name;
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
   * @param node the function type alias to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#DEFAULT_VALUE_IN_FUNCTION_TYPE_ALIAS
   */
  bool checkForDefaultValueInFunctionTypeAlias(FunctionTypeAlias node) {
    bool result = false;
    FormalParameterList formalParameterList = node.parameters;
    NodeList<FormalParameter> parameters = formalParameterList.parameters;
    for (FormalParameter formalParameter in parameters) {
      if (formalParameter is DefaultFormalParameter) {
        DefaultFormalParameter defaultFormalParameter = formalParameter as DefaultFormalParameter;
        if (defaultFormalParameter.defaultValue != null) {
          _errorReporter.reportError2(CompileTimeErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE_ALIAS, node, []);
          result = true;
        }
      }
    }
    return result;
  }

  /**
   * This verifies the passed import has unique name among other exported libraries.
   * @param node the export directive to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#EXPORT_DUPLICATED_LIBRARY_NAME
   */
  bool checkForExportDuplicateLibraryName(ExportDirective node) {
    Element nodeElement = node.element;
    if (nodeElement is! ExportElement) {
      return false;
    }
    ExportElement nodeExportElement = nodeElement as ExportElement;
    LibraryElement nodeLibrary = nodeExportElement.exportedLibrary;
    if (nodeLibrary == null) {
      return false;
    }
    String name = nodeLibrary.name;
    LibraryElement prevLibrary = _nameToExportElement[name];
    if (prevLibrary != null) {
      if (prevLibrary != nodeLibrary) {
        _errorReporter.reportError2(StaticWarningCode.EXPORT_DUPLICATED_LIBRARY_NAME, node, [prevLibrary.definingCompilationUnit.displayName, nodeLibrary.definingCompilationUnit.displayName, name]);
        return true;
      }
    } else {
      _nameToExportElement[name] = nodeLibrary;
    }
    return false;
  }

  /**
   * Check that if the visiting library is not system, then any passed library should not be SDK
   * internal library.
   * @param node the export directive to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#EXPORT_INTERNAL_LIBRARY
   */
  bool checkForExportInternalLibrary(ExportDirective node) {
    if (_isInSystemLibrary) {
      return false;
    }
    Element element = node.element;
    if (element is! ExportElement) {
      return false;
    }
    ExportElement exportElement = element as ExportElement;
    DartSdk sdk = _currentLibrary.context.sourceFactory.dartSdk;
    String uri = exportElement.uri;
    SdkLibrary sdkLibrary = sdk.getSdkLibrary(uri);
    if (sdkLibrary == null) {
      return false;
    }
    if (!sdkLibrary.isInternal()) {
      return false;
    }
    _errorReporter.reportError2(CompileTimeErrorCode.EXPORT_INTERNAL_LIBRARY, node, [node.uri]);
    return true;
  }

  /**
   * This verifies that the passed extends clause does not extend classes such as num or String.
   * @param node the extends clause to test
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#EXTENDS_DISALLOWED_CLASS
   */
  bool checkForExtendsDisallowedClass(ExtendsClause extendsClause) {
    if (extendsClause == null) {
      return false;
    }
    return checkForExtendsOrImplementsDisallowedClass(extendsClause.superclass, CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS);
  }

  /**
   * This verifies that the passed type name does not extend or implement classes such as 'num' or
   * 'String'.
   * @param node the type name to test
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see #checkForExtendsDisallowedClass(ExtendsClause)
   * @see #checkForImplementsDisallowedClass(ImplementsClause)
   * @see CompileTimeErrorCode#EXTENDS_DISALLOWED_CLASS
   * @see CompileTimeErrorCode#IMPLEMENTS_DISALLOWED_CLASS
   */
  bool checkForExtendsOrImplementsDisallowedClass(TypeName typeName, ErrorCode errorCode) {
    if (typeName.isSynthetic()) {
      return false;
    }
    Type2 superType = typeName.type;
    for (InterfaceType disallowedType in _DISALLOWED_TYPES_TO_EXTEND_OR_IMPLEMENT) {
      if (superType != null && superType == disallowedType) {
        if (superType == _typeProvider.numType) {
          ASTNode grandParent = typeName.parent.parent;
          if (grandParent is ClassDeclaration) {
            ClassElement classElement = ((grandParent as ClassDeclaration)).element;
            Type2 classType = classElement.type;
            if (classType != null && (classType == _typeProvider.intType || classType == _typeProvider.doubleType)) {
              return false;
            }
          }
        }
        _errorReporter.reportError2(errorCode, typeName, [disallowedType.displayName]);
        return true;
      }
    }
    return false;
  }

  /**
   * This verifies that the passed constructor field initializer has compatible field and
   * initializer expression types.
   * @param node the constructor field initializer to test
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#CONST_FIELD_INITIALIZER_NOT_ASSIGNABLE
   * @see StaticWarningCode#FIELD_INITIALIZER_NOT_ASSIGNABLE
   */
  bool checkForFieldInitializerNotAssignable(ConstructorFieldInitializer node) {
    Element fieldNameElement = node.fieldName.element;
    if (fieldNameElement is! FieldElement) {
      return false;
    }
    FieldElement fieldElement = fieldNameElement as FieldElement;
    Type2 fieldType = fieldElement.type;
    Expression expression = node.expression;
    if (expression == null) {
      return false;
    }
    Type2 staticType = getStaticType(expression);
    if (staticType == null) {
      return false;
    }
    if (staticType.isAssignableTo(fieldType)) {
      return false;
    } else if (_strictMode) {
      if (_isEnclosingConstructorConst) {
        _errorReporter.reportError2(CompileTimeErrorCode.CONST_FIELD_INITIALIZER_NOT_ASSIGNABLE, expression, [staticType.displayName, fieldType.displayName]);
      } else {
        _errorReporter.reportError2(StaticWarningCode.FIELD_INITIALIZER_NOT_ASSIGNABLE, expression, [staticType.displayName, fieldType.displayName]);
      }
      return true;
    }
    Type2 propagatedType = getPropagatedType(expression);
    if (propagatedType != null && propagatedType.isAssignableTo(fieldType)) {
      return false;
    }
    if (_isEnclosingConstructorConst) {
      _errorReporter.reportError2(CompileTimeErrorCode.CONST_FIELD_INITIALIZER_NOT_ASSIGNABLE, expression, [(propagatedType == null ? staticType : propagatedType).displayName, fieldType.displayName]);
    } else {
      _errorReporter.reportError2(StaticWarningCode.FIELD_INITIALIZER_NOT_ASSIGNABLE, expression, [(propagatedType == null ? staticType : propagatedType).displayName, fieldType.displayName]);
    }
    return true;
  }

  /**
   * This verifies that the passed field formal parameter is in a constructor declaration.
   * @param node the field formal parameter to test
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR
   */
  bool checkForFieldInitializingFormalRedirectingConstructor(FieldFormalParameter node) {
    ConstructorDeclaration constructor = node.getAncestor(ConstructorDeclaration);
    if (constructor == null) {
      _errorReporter.reportError2(CompileTimeErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR, node, []);
      return true;
    }
    if (constructor.factoryKeyword != null) {
      _errorReporter.reportError2(CompileTimeErrorCode.FIELD_INITIALIZER_FACTORY_CONSTRUCTOR, node, []);
      return true;
    }
    for (ConstructorInitializer initializer in constructor.initializers) {
      if (initializer is RedirectingConstructorInvocation) {
        _errorReporter.reportError2(CompileTimeErrorCode.FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR, node, []);
        return true;
      }
    }
    return false;
  }

  /**
   * This verifies that final fields that are declared, without any constructors in the enclosing
   * class, are initialized. Cases in which there is at least one constructor are handled at the end
   * of {@link #checkForAllFinalInitializedErrorCodes(ConstructorDeclaration)}.
   * @param node the class declaration to test
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#FINAL_NOT_INITIALIZED
   */
  bool checkForFinalNotInitialized(ClassDeclaration node) {
    NodeList<ClassMember> classMembers = node.members;
    for (ClassMember classMember in classMembers) {
      if (classMember is ConstructorDeclaration) {
        return false;
      }
    }
    bool foundError = false;
    for (ClassMember classMember in classMembers) {
      if (classMember is FieldDeclaration) {
        FieldDeclaration field = classMember as FieldDeclaration;
        foundError = javaBooleanOr(foundError, checkForFinalNotInitialized2(field.fields));
      }
    }
    return foundError;
  }

  /**
   * This verifies that the passed variable declaration list has only initialized variables if the
   * list is final or const. This method is called by{@link #checkForFinalNotInitialized(ClassDeclaration)},{@link #visitTopLevelVariableDeclaration(TopLevelVariableDeclaration)} and{@link #visitVariableDeclarationStatement(VariableDeclarationStatement)}.
   * @param node the class declaration to test
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#FINAL_NOT_INITIALIZED
   */
  bool checkForFinalNotInitialized2(VariableDeclarationList node) {
    bool foundError = false;
    if (!node.isSynthetic() && (node.isConst() || node.isFinal())) {
      NodeList<VariableDeclaration> variables = node.variables;
      for (VariableDeclaration variable in variables) {
        if (variable.initializer == null) {
          _errorReporter.reportError2(StaticWarningCode.FINAL_NOT_INITIALIZED, variable, [variable.name.name]);
          foundError = true;
        }
      }
    }
    return foundError;
  }

  /**
   * This verifies that the passed implements clause does not implement classes such as 'num' or
   * 'String'.
   * @param node the implements clause to test
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#IMPLEMENTS_DISALLOWED_CLASS
   */
  bool checkForImplementsDisallowedClass(ImplementsClause implementsClause) {
    if (implementsClause == null) {
      return false;
    }
    bool foundError = false;
    for (TypeName type in implementsClause.interfaces) {
      foundError = javaBooleanOr(foundError, checkForExtendsOrImplementsDisallowedClass(type, CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS));
    }
    return foundError;
  }

  /**
   * This verifies that if the passed identifier is part of constructor initializer, then it does
   * not reference implicitly 'this' expression.
   * @param node the simple identifier to test
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#IMPLICIT_THIS_REFERENCE_IN_INITIALIZER
   */
  bool checkForImplicitThisReferenceInInitializer(SimpleIdentifier node) {
    if (!_isInConstructorInitializer) {
      return false;
    }
    Element element = node.element;
    if (!(element is MethodElement || element is PropertyAccessorElement)) {
      return false;
    }
    ExecutableElement executableElement = element as ExecutableElement;
    if (executableElement.isStatic()) {
      return false;
    }
    Element enclosingElement = element.enclosingElement;
    if (enclosingElement is! ClassElement) {
      return false;
    }
    ASTNode parent = node.parent;
    if (parent is MethodInvocation) {
      MethodInvocation invocation = parent as MethodInvocation;
      if (identical(invocation.methodName, node) && invocation.realTarget != null) {
        return false;
      }
    }
    {
      if (parent is PropertyAccess) {
        PropertyAccess access = parent as PropertyAccess;
        if (identical(access.propertyName, node) && access.realTarget != null) {
          return false;
        }
      }
      if (parent is PrefixedIdentifier) {
        PrefixedIdentifier prefixed = parent as PrefixedIdentifier;
        if (identical(prefixed.identifier, node)) {
          return false;
        }
      }
    }
    _errorReporter.reportError2(CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER, node, []);
    return true;
  }

  /**
   * This verifies the passed import has unique name among other imported libraries.
   * @param node the import directive to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#IMPORT_DUPLICATED_LIBRARY_NAME
   */
  bool checkForImportDuplicateLibraryName(ImportDirective node) {
    Element nodeElement = node.element;
    if (nodeElement is! ImportElement) {
      return false;
    }
    ImportElement nodeImportElement = nodeElement as ImportElement;
    LibraryElement nodeLibrary = nodeImportElement.importedLibrary;
    if (nodeLibrary == null) {
      return false;
    }
    String name = nodeLibrary.name;
    LibraryElement prevLibrary = _nameToImportElement[name];
    if (prevLibrary != null) {
      if (prevLibrary != nodeLibrary) {
        _errorReporter.reportError2(StaticWarningCode.IMPORT_DUPLICATED_LIBRARY_NAME, node, [prevLibrary.definingCompilationUnit.displayName, nodeLibrary.definingCompilationUnit.displayName, name]);
        return true;
      }
    } else {
      _nameToImportElement[name] = nodeLibrary;
    }
    return false;
  }

  /**
   * Check that if the visiting library is not system, then any passed library should not be SDK
   * internal library.
   * @param node the import directive to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#IMPORT_INTERNAL_LIBRARY
   */
  bool checkForImportInternalLibrary(ImportDirective node) {
    if (_isInSystemLibrary) {
      return false;
    }
    Element element = node.element;
    if (element is! ImportElement) {
      return false;
    }
    ImportElement importElement = element as ImportElement;
    DartSdk sdk = _currentLibrary.context.sourceFactory.dartSdk;
    String uri = importElement.uri;
    SdkLibrary sdkLibrary = sdk.getSdkLibrary(uri);
    if (sdkLibrary == null) {
      return false;
    }
    if (!sdkLibrary.isInternal()) {
      return false;
    }
    _errorReporter.reportError2(CompileTimeErrorCode.IMPORT_INTERNAL_LIBRARY, node, [node.uri]);
    return true;
  }

  /**
   * This verifies that the passed switch statement case expressions all have the same type.
   * @param node the switch statement to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#INCONSISTENT_CASE_EXPRESSION_TYPES
   */
  bool checkForInconsistentCaseExpressionTypes(SwitchStatement node) {
    NodeList<SwitchMember> switchMembers = node.members;
    bool foundError = false;
    Type2 firstType = null;
    for (SwitchMember switchMember in switchMembers) {
      if (switchMember is SwitchCase) {
        SwitchCase switchCase = switchMember as SwitchCase;
        Expression expression = switchCase.expression;
        if (firstType == null) {
          firstType = getBestType(expression);
        } else {
          Type2 nType = getBestType(expression);
          if (firstType != nType) {
            _errorReporter.reportError2(CompileTimeErrorCode.INCONSISTENT_CASE_EXPRESSION_TYPES, expression, [expression.toSource(), firstType.displayName]);
            foundError = true;
          }
        }
      }
    }
    return foundError;
  }

  /**
   * For each class declaration, this method is called which verifies that all inherited members are
   * inherited consistently.
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see StaticTypeWarningCode#INCONSISTENT_METHOD_INHERITANCE
   */
  bool checkForInconsistentMethodInheritance() {
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
   * Given an assignment using a compound assignment operator, this verifies that the given
   * assignment is valid.
   * @param node the assignment expression being tested
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see StaticTypeWarningCode#INVALID_ASSIGNMENT
   */
  bool checkForInvalidAssignment(AssignmentExpression node) {
    Expression lhs = node.leftHandSide;
    if (lhs == null) {
      return false;
    }
    VariableElement leftElement = getVariableElement(lhs);
    Type2 leftType = (leftElement == null) ? getStaticType(lhs) : leftElement.type;
    MethodElement invokedMethod = node.element;
    if (invokedMethod == null) {
      return false;
    }
    Type2 rightType = invokedMethod.type.returnType;
    if (leftType == null || rightType == null) {
      return false;
    }
    if (!rightType.isAssignableTo(leftType)) {
      _errorReporter.reportError2(StaticTypeWarningCode.INVALID_ASSIGNMENT, node.rightHandSide, [rightType.displayName, leftType.displayName]);
      return true;
    }
    return false;
  }

  /**
   * This verifies that the passed left hand side and right hand side represent a valid assignment.
   * @param lhs the left hand side expression
   * @param rhs the right hand side expression
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see StaticTypeWarningCode#INVALID_ASSIGNMENT
   */
  bool checkForInvalidAssignment2(Expression lhs, Expression rhs) {
    if (lhs == null || rhs == null) {
      return false;
    }
    VariableElement leftElement = getVariableElement(lhs);
    Type2 leftType = (leftElement == null) ? getStaticType(lhs) : leftElement.type;
    Type2 staticRightType = getStaticType(rhs);
    bool isStaticAssignable = staticRightType.isAssignableTo(leftType);
    Type2 propagatedRightType = getPropagatedType(rhs);
    if (_strictMode || propagatedRightType == null) {
      if (!isStaticAssignable) {
        _errorReporter.reportError2(StaticTypeWarningCode.INVALID_ASSIGNMENT, rhs, [staticRightType.displayName, leftType.displayName]);
        return true;
      }
    } else {
      bool isPropagatedAssignable = propagatedRightType.isAssignableTo(leftType);
      if (!isStaticAssignable && !isPropagatedAssignable) {
        _errorReporter.reportError2(StaticTypeWarningCode.INVALID_ASSIGNMENT, rhs, [staticRightType.displayName, leftType.displayName]);
        return true;
      }
    }
    return false;
  }

  /**
   * This verifies that the usage of the passed 'this' is valid.
   * @param node the 'this' expression to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
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
   * Checks to ensure that first type argument to a map literal must be the 'String' type.
   * @param arguments a non-{@code null}, non-empty {@link TypeName} node list from the respective{@link MapLiteral}
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#INVALID_TYPE_ARGUMENT_FOR_KEY
   */
  bool checkForInvalidTypeArgumentForKey(NodeList<TypeName> arguments) {
    TypeName firstArgument = arguments[0];
    Type2 firstArgumentType = firstArgument.type;
    if (firstArgumentType != null && firstArgumentType != _typeProvider.stringType) {
      _errorReporter.reportError2(CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_FOR_KEY, firstArgument, []);
      return true;
    }
    return false;
  }

  /**
   * Checks to ensure that the passed {@link ListLiteral} or {@link MapLiteral} does not have a type
   * parameter as a type argument.
   * @param arguments a non-{@code null}, non-empty {@link TypeName} node list from the respective{@link ListLiteral} or {@link MapLiteral}
   * @param errorCode either {@link CompileTimeErrorCode#INVALID_TYPE_ARGUMENT_IN_CONST_LIST} or{@link CompileTimeErrorCode#INVALID_TYPE_ARGUMENT_IN_CONST_MAP}
   * @return {@code true} if and only if an error code is generated on the passed node
   */
  bool checkForInvalidTypeArgumentInConstTypedLiteral(NodeList<TypeName> arguments, ErrorCode errorCode) {
    bool foundError = false;
    for (TypeName typeName in arguments) {
      if (typeName.type is TypeVariableType) {
        _errorReporter.reportError2(errorCode, typeName, [typeName.name]);
        foundError = true;
      }
    }
    return foundError;
  }

  /**
   * This verifies that the {@link #enclosingClass} does not define members with the same name as
   * the enclosing class.
   * @return {@code true} if and only if an error code is generated on the passed node
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
    for (PropertyAccessorElement accessor in _enclosingClass.accessors) {
      if (className == accessor.name) {
        _errorReporter.reportError3(CompileTimeErrorCode.MEMBER_WITH_CLASS_NAME, accessor.nameOffset, className.length, []);
        problemReported = true;
      }
    }
    return problemReported;
  }

  /**
   * Check to make sure that all similarly typed accessors are of the same type (including inherited
   * accessors).
   * @param node The accessor currently being visited.
   */
  void checkForMismatchedAccessorTypes(Declaration accessorDeclaration, String accessorTextName) {
    PropertyAccessorElement counterpartAccessor = null;
    ExecutableElement accessorElement = accessorDeclaration.element as ExecutableElement;
    if (accessorElement is! PropertyAccessorElement) {
      return;
    }
    PropertyAccessorElement propertyAccessorElement = accessorElement as PropertyAccessorElement;
    counterpartAccessor = propertyAccessorElement.correspondingSetter;
    if (counterpartAccessor == null) {
      return;
    }
    Type2 getterType = null;
    Type2 setterType = null;
    if (propertyAccessorElement.isGetter()) {
      getterType = getGetterType(propertyAccessorElement);
      setterType = getSetterType(counterpartAccessor);
    } else if (propertyAccessorElement.isSetter()) {
      setterType = getSetterType(propertyAccessorElement);
      counterpartAccessor = propertyAccessorElement.correspondingGetter;
      getterType = getGetterType(counterpartAccessor);
    }
    if (setterType != null && getterType != null && !getterType.isAssignableTo(setterType)) {
      _errorReporter.reportError2(StaticWarningCode.MISMATCHED_GETTER_AND_SETTER_TYPES, accessorDeclaration, [accessorTextName, setterType.displayName, getterType.displayName]);
    }
  }

  /**
   * This verifies that the passed mixin does not have an explicitly declared constructor.
   * @param mixinName the node to report problem on
   * @param mixinElement the mixing to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#MIXIN_DECLARES_CONSTRUCTOR
   */
  bool checkForMixinDeclaresConstructor(TypeName mixinName, ClassElement mixinElement) {
    for (ConstructorElement constructor in mixinElement.constructors) {
      if (!constructor.isSynthetic() && !constructor.isFactory()) {
        _errorReporter.reportError2(CompileTimeErrorCode.MIXIN_DECLARES_CONSTRUCTOR, mixinName, [mixinElement.name]);
        return true;
      }
    }
    return false;
  }

  /**
   * This verifies that the passed mixin has the 'Object' superclass.
   * @param mixinName the node to report problem on
   * @param mixinElement the mixing to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#MIXIN_INHERITS_FROM_NOT_OBJECT
   */
  bool checkForMixinInheritsNotFromObject(TypeName mixinName, ClassElement mixinElement) {
    InterfaceType mixinSupertype = mixinElement.supertype;
    if (mixinSupertype != null) {
      if (!mixinSupertype.isObject() || !mixinElement.isTypedef() && mixinElement.mixins.length != 0) {
        _errorReporter.reportError2(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, mixinName, [mixinElement.name]);
        return true;
      }
    }
    return false;
  }

  /**
   * This verifies that the passed mixin does not reference 'super'.
   * @param mixinName the node to report problem on
   * @param mixinElement the mixing to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
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
   * @param node the constructor declaration to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
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
   * @param node the native function body to test
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see ParserErrorCode#NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE
   */
  bool checkForNativeFunctionBodyInNonSDKCode(NativeFunctionBody node) {
    if (!_isInSystemLibrary) {
      _errorReporter.reportError2(ParserErrorCode.NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE, node, []);
      return true;
    }
    return false;
  }

  /**
   * This verifies that the passed 'new' instance creation expression invokes existing constructor.
   * <p>
   * This method assumes that the instance creation was tested to be 'new' before being called.
   * @param node the instance creation expression to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see StaticWarningCode#NEW_WITH_UNDEFINED_CONSTRUCTOR
   */
  bool checkForNewWithUndefinedConstructor(InstanceCreationExpression node) {
    if (node.element != null) {
      return false;
    }
    ConstructorName constructorName = node.constructorName;
    if (constructorName == null) {
      return false;
    }
    TypeName type = constructorName.type;
    if (type == null) {
      return false;
    }
    Identifier className = type.name;
    SimpleIdentifier name = constructorName.name;
    if (name != null) {
      _errorReporter.reportError2(StaticWarningCode.NEW_WITH_UNDEFINED_CONSTRUCTOR, name, [className, name]);
    } else {
      _errorReporter.reportError2(StaticWarningCode.NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT, constructorName, [className]);
    }
    return true;
  }

  /**
   * This checks that passed class declaration overrides all members required by its superclasses
   * and interfaces.
   * @param node the {@link ClassDeclaration} to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see StaticWarningCode#NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE
   * @see StaticWarningCode#NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO
   * @see StaticWarningCode#NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_THREE
   * @see StaticWarningCode#NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FOUR
   * @see StaticWarningCode#NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FIVE_PLUS
   */
  bool checkForNonAbstractClassInheritsAbstractMember(ClassDeclaration node) {
    if (_enclosingClass.isAbstract()) {
      return false;
    }
    Set<ExecutableElement> missingOverrides = new Set<ExecutableElement>();
    Set<String> methodsInEnclosingClass = new Set<String>();
    Set<String> accessorsInEnclosingClass = new Set<String>();
    List<MethodElement> methods = _enclosingClass.methods;
    for (MethodElement method in methods) {
      javaSetAdd(methodsInEnclosingClass, method.name);
    }
    List<PropertyAccessorElement> accessors = _enclosingClass.accessors;
    for (PropertyAccessorElement accessor in accessors) {
      javaSetAdd(accessorsInEnclosingClass, accessor.name);
    }
    Map<String, ExecutableElement> membersInheritedFromSuperclasses = _inheritanceManager.getMapOfMembersInheritedFromClasses(_enclosingClass);
    for (MapEntry<String, ExecutableElement> entry in getMapEntrySet(membersInheritedFromSuperclasses)) {
      ExecutableElement executableElt = entry.getValue();
      if (executableElt is MethodElement) {
        MethodElement methodElt = executableElt as MethodElement;
        if (methodElt.isAbstract()) {
          String methodName = entry.getKey();
          if (!methodsInEnclosingClass.contains(methodName)) {
            javaSetAdd(missingOverrides, executableElt);
          }
        }
      } else if (executableElt is PropertyAccessorElement) {
        PropertyAccessorElement propertyAccessorElt = executableElt as PropertyAccessorElement;
        if (propertyAccessorElt.isAbstract()) {
          String accessorName = entry.getKey();
          if (!accessorsInEnclosingClass.contains(accessorName)) {
            javaSetAdd(missingOverrides, executableElt);
          }
        }
      }
    }
    Map<String, ExecutableElement> membersInheritedFromInterfaces = _inheritanceManager.getMapOfMembersInheritedFromInterfaces(_enclosingClass);
    for (MapEntry<String, ExecutableElement> entry in getMapEntrySet(membersInheritedFromInterfaces)) {
      ExecutableElement executableElt = entry.getValue();
      ExecutableElement elt = membersInheritedFromSuperclasses[executableElt.name];
      if (elt != null) {
        if (elt is MethodElement && !((elt as MethodElement)).isAbstract()) {
          continue;
        } else if (elt is PropertyAccessorElement && !((elt as PropertyAccessorElement)).isAbstract()) {
          continue;
        }
      }
      if (executableElt is MethodElement) {
        String methodName = entry.getKey();
        if (!methodsInEnclosingClass.contains(methodName)) {
          javaSetAdd(missingOverrides, executableElt);
        }
      } else if (executableElt is PropertyAccessorElement) {
        String accessorName = entry.getKey();
        if (!accessorsInEnclosingClass.contains(accessorName)) {
          javaSetAdd(missingOverrides, executableElt);
        }
      }
    }
    int missingOverridesSize = missingOverrides.length;
    if (missingOverridesSize == 0) {
      return false;
    }
    List<ExecutableElement> missingOverridesArray = new List.from(missingOverrides);
    List<String> stringTypeArray = new List<String>(Math.min(missingOverridesSize, 4));
    String GET = "get ";
    String SET = "set ";
    for (int i = 0; i < stringTypeArray.length; i++) {
      stringTypeArray[i] = StringUtilities.EMPTY;
      if (missingOverridesArray[i] is PropertyAccessorElement) {
        stringTypeArray[i] = ((missingOverridesArray[i] as PropertyAccessorElement)).isGetter() ? GET : SET;
      }
    }
    AnalysisErrorWithProperties analysisError;
    if (missingOverridesSize == 1) {
      analysisError = _errorReporter.newErrorWithProperties(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE, node.name, [stringTypeArray[0], missingOverridesArray[0].enclosingElement.displayName, missingOverridesArray[0].displayName]);
    } else if (missingOverridesSize == 2) {
      analysisError = _errorReporter.newErrorWithProperties(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO, node.name, [stringTypeArray[0], missingOverridesArray[0].enclosingElement.displayName, missingOverridesArray[0].displayName, stringTypeArray[1], missingOverridesArray[1].enclosingElement.displayName, missingOverridesArray[1].displayName]);
    } else if (missingOverridesSize == 3) {
      analysisError = _errorReporter.newErrorWithProperties(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_THREE, node.name, [stringTypeArray[0], missingOverridesArray[0].enclosingElement.displayName, missingOverridesArray[0].displayName, stringTypeArray[1], missingOverridesArray[1].enclosingElement.displayName, missingOverridesArray[1].displayName, stringTypeArray[2], missingOverridesArray[2].enclosingElement.displayName, missingOverridesArray[2].displayName]);
    } else if (missingOverridesSize == 4) {
      analysisError = _errorReporter.newErrorWithProperties(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FOUR, node.name, [stringTypeArray[0], missingOverridesArray[0].enclosingElement.displayName, missingOverridesArray[0].displayName, stringTypeArray[1], missingOverridesArray[1].enclosingElement.displayName, missingOverridesArray[1].displayName, stringTypeArray[2], missingOverridesArray[2].enclosingElement.displayName, missingOverridesArray[2].displayName, stringTypeArray[3], missingOverridesArray[3].enclosingElement.displayName, missingOverridesArray[3].displayName]);
    } else {
      analysisError = _errorReporter.newErrorWithProperties(StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FIVE_PLUS, node.name, [stringTypeArray[0], missingOverridesArray[0].enclosingElement.displayName, missingOverridesArray[0].displayName, stringTypeArray[1], missingOverridesArray[1].enclosingElement.displayName, missingOverridesArray[1].displayName, stringTypeArray[2], missingOverridesArray[2].enclosingElement.displayName, missingOverridesArray[2].displayName, stringTypeArray[3], missingOverridesArray[3].enclosingElement.displayName, missingOverridesArray[3].displayName, missingOverridesArray.length - 4]);
    }
    analysisError.setProperty(ErrorProperty.UNIMPLEMENTED_METHODS, missingOverridesArray);
    _errorReporter.reportError(analysisError);
    return true;
  }

  /**
   * Checks to ensure that the expressions that need to be of type bool, are. Otherwise an error is
   * reported on the expression.
   * @param condition the conditional expression to test
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see StaticTypeWarningCode#NON_BOOL_CONDITION
   */
  bool checkForNonBoolCondition(Expression condition) {
    Type2 conditionType = getStaticType(condition);
    if (conditionType != null && !conditionType.isAssignableTo(_typeProvider.boolType)) {
      _errorReporter.reportError2(StaticTypeWarningCode.NON_BOOL_CONDITION, condition, []);
      return true;
    }
    return false;
  }

  /**
   * This verifies that the passed assert statement has either a 'bool' or '() -> bool' input.
   * @param node the assert statement to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see StaticTypeWarningCode#NON_BOOL_EXPRESSION
   */
  bool checkForNonBoolExpression(AssertStatement node) {
    Expression expression = node.condition;
    Type2 type = getStaticType(expression);
    if (type is InterfaceType) {
      if (!type.isAssignableTo(_typeProvider.boolType)) {
        _errorReporter.reportError2(StaticTypeWarningCode.NON_BOOL_EXPRESSION, expression, []);
        return true;
      }
    } else if (type is FunctionType) {
      FunctionType functionType = type as FunctionType;
      if (functionType.typeArguments.length == 0 && !functionType.returnType.isAssignableTo(_typeProvider.boolType)) {
        _errorReporter.reportError2(StaticTypeWarningCode.NON_BOOL_EXPRESSION, expression, []);
        return true;
      }
    }
    return false;
  }

  /**
   * This verifies the passed map literal either:
   * <ul>
   * <li>has {@code const modifier}</li>
   * <li>has explicit type arguments</li>
   * <li>is not start of the statement</li>
   * <ul>
   * @param node the map literal to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#NON_CONST_MAP_AS_EXPRESSION_STATEMENT
   */
  bool checkForNonConstMapAsExpressionStatement(MapLiteral node) {
    if (node.modifier != null) {
      return false;
    }
    if (node.typeArguments != null) {
      return false;
    }
    Statement statement = node.getAncestor(ExpressionStatement);
    if (statement == null) {
      return false;
    }
    if (statement.beginToken != node.beginToken) {
      return false;
    }
    _errorReporter.reportError2(CompileTimeErrorCode.NON_CONST_MAP_AS_EXPRESSION_STATEMENT, node, []);
    return true;
  }

  /**
   * This verifies the passed method declaration of operator {@code \[\]=}, has {@code void} return
   * type.
   * @param node the method declaration to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see StaticWarningCode#NON_VOID_RETURN_FOR_OPERATOR
   */
  bool checkForNonVoidReturnTypeForOperator(MethodDeclaration node) {
    SimpleIdentifier name = node.name;
    if (name.name != "[]=") {
      return false;
    }
    TypeName typeName = node.returnType;
    if (typeName != null) {
      Type2 type = typeName.type;
      if (type != null && !type.isVoid()) {
        _errorReporter.reportError2(StaticWarningCode.NON_VOID_RETURN_FOR_OPERATOR, typeName, []);
      }
    }
    return false;
  }

  /**
   * This verifies the passed setter has no return type or the {@code void} return type.
   * @param typeName the type name to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see StaticWarningCode#NON_VOID_RETURN_FOR_SETTER
   */
  bool checkForNonVoidReturnTypeForSetter(TypeName typeName) {
    if (typeName != null) {
      Type2 type = typeName.type;
      if (type != null && !type.isVoid()) {
        _errorReporter.reportError2(StaticWarningCode.NON_VOID_RETURN_FOR_SETTER, typeName, []);
      }
    }
    return false;
  }

  /**
   * This verifies the passed operator-method declaration, does not have an optional parameter.
   * <p>
   * This method assumes that the method declaration was tested to be an operator declaration before
   * being called.
   * @param node the method declaration to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
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
      if (formalParameter.kind.isOptional()) {
        _errorReporter.reportError2(CompileTimeErrorCode.OPTIONAL_PARAMETER_IN_OPERATOR, formalParameter, []);
        foundError = true;
      }
    }
    return foundError;
  }

  /**
   * This checks for named optional parameters that begin with '_'.
   * @param node the default formal parameter to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#PRIVATE_OPTIONAL_PARAMETER
   */
  bool checkForPrivateOptionalParameter(DefaultFormalParameter node) {
    sc.Token separator = node.separator;
    if (separator != null && separator.lexeme == ":") {
      NormalFormalParameter parameter = node.parameter;
      SimpleIdentifier name = parameter.identifier;
      if (!name.isSynthetic() && name.name.startsWith("_")) {
        _errorReporter.reportError2(CompileTimeErrorCode.PRIVATE_OPTIONAL_PARAMETER, node, []);
        return true;
      }
    }
    return false;
  }

  /**
   * This checks if the passed constructor declaration is the redirecting generative constructor and
   * references itself directly or indirectly.
   * @param node the constructor declaration to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#RECURSIVE_CONSTRUCTOR_REDIRECT
   */
  bool checkForRecursiveConstructorRedirect(ConstructorDeclaration node) {
    if (node.factoryKeyword != null) {
      return false;
    }
    for (ConstructorInitializer initializer in node.initializers) {
      if (initializer is RedirectingConstructorInvocation) {
        ConstructorElement element = node.element;
        if (!hasRedirectingFactoryConstructorCycle(element)) {
          return false;
        }
        _errorReporter.reportError2(CompileTimeErrorCode.RECURSIVE_CONSTRUCTOR_REDIRECT, initializer, []);
        return true;
      }
    }
    return false;
  }

  /**
   * This checks if the passed constructor declaration has redirected constructor and references
   * itself directly or indirectly.
   * @param node the constructor declaration to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#RECURSIVE_FACTORY_REDIRECT
   */
  bool checkForRecursiveFactoryRedirect(ConstructorDeclaration node) {
    ConstructorName redirectedConstructorNode = node.redirectedConstructor;
    if (redirectedConstructorNode == null) {
      return false;
    }
    ConstructorElement element = node.element;
    if (!hasRedirectingFactoryConstructorCycle(element)) {
      return false;
    }
    _errorReporter.reportError2(CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT, redirectedConstructorNode, []);
    return true;
  }

  /**
   * This checks the class declaration is not a superinterface to itself.
   * @param classElt the class element to test
   * @param list a list containing the potentially cyclic implements path
   * @return {@code true} if and only if an error code is generated on the passed element
   * @see CompileTimeErrorCode#RECURSIVE_INTERFACE_INHERITANCE
   * @see CompileTimeErrorCode#RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_EXTENDS
   * @see CompileTimeErrorCode#RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_IMPLEMENTS
   */
  bool checkForRecursiveInterfaceInheritance(ClassElement classElt, List<ClassElement> list) {
    if (classElt == null) {
      return false;
    }
    InterfaceType supertype = classElt.supertype;
    list.add(classElt);
    if (list.length != 1 && _enclosingClass == classElt) {
      String enclosingClassName = _enclosingClass.displayName;
      if (list.length > 2) {
        String separator = ", ";
        int listLength = list.length;
        JavaStringBuilder builder = new JavaStringBuilder();
        for (int i = 0; i < listLength; i++) {
          builder.append(list[i].displayName);
          if (i != listLength - 1) {
            builder.append(separator);
          }
        }
        _errorReporter.reportError3(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, _enclosingClass.nameOffset, enclosingClassName.length, [enclosingClassName, builder.toString()]);
        return true;
      } else if (list.length == 2) {
        ErrorCode errorCode = supertype != null && _enclosingClass == supertype.element ? CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_EXTENDS : CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_IMPLEMENTS;
        _errorReporter.reportError3(errorCode, _enclosingClass.nameOffset, enclosingClassName.length, [enclosingClassName]);
        return true;
      }
    }
    for (int i = 1; i < list.length - 1; i++) {
      if (classElt == list[i]) {
        list.removeAt(list.length - 1);
        return false;
      }
    }
    List<ClassElement> interfaceElements;
    List<InterfaceType> interfaceTypes = classElt.interfaces;
    if (supertype != null && !supertype.isObject()) {
      interfaceElements = new List<ClassElement>(interfaceTypes.length + 1);
      interfaceElements[0] = supertype.element;
      for (int i = 0; i < interfaceTypes.length; i++) {
        interfaceElements[i + 1] = interfaceTypes[i].element;
      }
    } else {
      interfaceElements = new List<ClassElement>(interfaceTypes.length);
      for (int i = 0; i < interfaceTypes.length; i++) {
        interfaceElements[i] = interfaceTypes[i].element;
      }
    }
    for (ClassElement classElt2 in interfaceElements) {
      if (checkForRecursiveInterfaceInheritance(classElt2, list)) {
        return true;
      }
    }
    list.removeAt(list.length - 1);
    return false;
  }

  /**
   * This checks the passed constructor declaration has a valid combination of redirected
   * constructor invocation(s), super constructor invocations and field initializers.
   * @param node the constructor declaration to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#MULTIPLE_REDIRECTING_CONSTRUCTOR_INVOCATIONS
   * @see CompileTimeErrorCode#SUPER_IN_REDIRECTING_CONSTRUCTOR
   * @see CompileTimeErrorCode#FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR
   */
  bool checkForRedirectingConstructorErrorCodes(ConstructorDeclaration node) {
    int numProblems = 0;
    int numRedirections = 0;
    for (ConstructorInitializer initializer in node.initializers) {
      if (initializer is RedirectingConstructorInvocation) {
        if (numRedirections > 0) {
          _errorReporter.reportError2(CompileTimeErrorCode.MULTIPLE_REDIRECTING_CONSTRUCTOR_INVOCATIONS, initializer, []);
          numProblems++;
        }
        numRedirections++;
      }
    }
    if (numRedirections > 0) {
      for (ConstructorInitializer initializer in node.initializers) {
        if (initializer is SuperConstructorInvocation) {
          _errorReporter.reportError2(CompileTimeErrorCode.SUPER_IN_REDIRECTING_CONSTRUCTOR, initializer, []);
          numProblems++;
        }
        if (initializer is ConstructorFieldInitializer) {
          _errorReporter.reportError2(CompileTimeErrorCode.FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR, initializer, []);
          numProblems++;
        }
      }
    }
    return numProblems != 0;
  }

  /**
   * This checks if the passed constructor declaration has redirected constructor and references
   * itself directly or indirectly. TODO(scheglov)
   * @param node the constructor declaration to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#REDIRECT_TO_NON_CONST_CONSTRUCTOR
   */
  bool checkForRedirectToNonConstConstructor(ConstructorDeclaration node) {
    ConstructorName redirectedConstructorNode = node.redirectedConstructor;
    if (redirectedConstructorNode == null) {
      return false;
    }
    ConstructorElement element = node.element;
    if (element == null) {
      return false;
    }
    if (!element.isConst()) {
      return false;
    }
    ConstructorElement redirectedConstructor = element.redirectedConstructor;
    if (redirectedConstructor == null) {
      return false;
    }
    if (redirectedConstructor.isConst()) {
      return false;
    }
    _errorReporter.reportError2(CompileTimeErrorCode.REDIRECT_TO_NON_CONST_CONSTRUCTOR, redirectedConstructorNode, []);
    return true;
  }

  /**
   * This checks if the passed identifier is banned because it is part of the variable declaration
   * with the same name.
   * @param node the identifier to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#REFERENCE_TO_DECLARED_VARIABLE_IN_INITIALIZER
   */
  bool checkForReferenceToDeclaredVariableInInitializer(SimpleIdentifier node) {
    ASTNode parent = node.parent;
    if (parent is PrefixedIdentifier) {
      PrefixedIdentifier prefixedIdentifier = parent as PrefixedIdentifier;
      if (identical(prefixedIdentifier.identifier, node)) {
        return false;
      }
    }
    if (parent is PropertyAccess) {
      PropertyAccess propertyAccess = parent as PropertyAccess;
      if (identical(propertyAccess.propertyName, node)) {
        return false;
      }
    }
    if (parent is MethodInvocation) {
      MethodInvocation methodInvocation = parent as MethodInvocation;
      if (methodInvocation.target != null && identical(methodInvocation.methodName, node)) {
        return false;
      }
    }
    if (parent is ConstructorName) {
      ConstructorName constructorName = parent as ConstructorName;
      if (identical(constructorName.name, node)) {
        return false;
      }
    }
    if (parent is Label) {
      Label label = parent as Label;
      if (identical(label.label, node)) {
        return false;
      }
    }
    String name = node.name;
    if (!_namesForReferenceToDeclaredVariableInInitializer.contains(name)) {
      return false;
    }
    _errorReporter.reportError2(CompileTimeErrorCode.REFERENCE_TO_DECLARED_VARIABLE_IN_INITIALIZER, node, [name]);
    return true;
  }

  /**
   * This checks that the rethrow is inside of a catch clause.
   * @param node the rethrow expression to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
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
   * This checks that if the given "target" is the type reference then the "name" is not the
   * reference to a instance member.
   * @param target the target of the name access to evaluate
   * @param name the accessed name to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see StaticWarningCode#STATIC_ACCESS_TO_INSTANCE_MEMBER
   */
  bool checkForStaticAccessToInstanceMember(Expression target, SimpleIdentifier name2) {
    Element element = name2.element;
    if (element is! ExecutableElement) {
      return false;
    }
    ExecutableElement memberElement = element as ExecutableElement;
    if (memberElement.isStatic()) {
      return false;
    }
    if (!isTypeReference(target)) {
      return false;
    }
    _errorReporter.reportError2(StaticWarningCode.STATIC_ACCESS_TO_INSTANCE_MEMBER, name2, [name2.name]);
    return true;
  }

  /**
   * This checks that the type of the passed 'switch' expression is assignable to the type of the
   * 'case' members.
   * @param node the 'switch' statement to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see StaticWarningCode#SWITCH_EXPRESSION_NOT_ASSIGNABLE
   */
  bool checkForSwitchExpressionNotAssignable(SwitchStatement node) {
    Expression expression = node.expression;
    Type2 expressionType = getStaticType(expression);
    if (expressionType == null) {
      return false;
    }
    NodeList<SwitchMember> members = node.members;
    for (SwitchMember switchMember in members) {
      if (switchMember is! SwitchCase) {
        continue;
      }
      SwitchCase switchCase = switchMember as SwitchCase;
      Expression caseExpression = switchCase.expression;
      Type2 caseType = getStaticType(caseExpression);
      if (expressionType.isAssignableTo(caseType)) {
        return false;
      }
      _errorReporter.reportError2(StaticWarningCode.SWITCH_EXPRESSION_NOT_ASSIGNABLE, expression, [expressionType, caseType]);
      return true;
    }
    return false;
  }

  /**
   * This verifies that the type arguments in the passed instance creation expression are all within
   * their bounds as specified by the class element where the constructor \[that is being invoked\] is
   * declared.
   * @param node the instance creation expression to evaluate
   * @param typeName the {@link TypeName} of the {@link ConstructorName} from the{@link InstanceCreationExpression}, this is the AST node that the error is attached to
   * @param constructorElement the {@link ConstructorElement} from the instance creation expression
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see StaticTypeWarningCode#TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
   */
  bool checkForTypeArgumentNotMatchingBounds(InstanceCreationExpression node, ConstructorElement constructorElement, TypeName typeName) {
    if (typeName.typeArguments != null && constructorElement != null) {
      NodeList<TypeName> typeNameArgList = typeName.typeArguments.arguments;
      List<TypeVariableElement> boundingElts = constructorElement.enclosingElement.typeVariables;
      int loopThroughIndex = Math.min(typeNameArgList.length, boundingElts.length);
      for (int i = 0; i < loopThroughIndex; i++) {
        TypeName argTypeName = typeNameArgList[i];
        Type2 argType = argTypeName.type;
        Type2 boundType = boundingElts[i].bound;
        if (argType != null && boundType != null) {
          if (!argType.isSubtypeOf(boundType)) {
            _errorReporter.reportError2(StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, argTypeName, [argTypeName.name, boundingElts[i].displayName]);
            return true;
          }
        }
      }
    }
    return false;
  }

  /**
   * This checks that if the passed generative constructor has neither an explicit super constructor
   * invocation nor a redirecting constructor invocation, that the superclass has a default
   * generative constructor.
   * @param node the constructor declaration to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT
   * @see CompileTimeErrorCode#NON_GENERATIVE_CONSTRUCTOR
   */
  bool checkForUndefinedConstructorInInitializerImplicit(ConstructorDeclaration node) {
    if (node.factoryKeyword != null) {
      return false;
    }
    for (ConstructorInitializer constructorInitializer in node.initializers) {
      if (constructorInitializer is SuperConstructorInvocation || constructorInitializer is RedirectingConstructorInvocation) {
        return false;
      }
    }
    if (_enclosingClass == null) {
      return false;
    }
    InterfaceType superType = _enclosingClass.supertype;
    if (superType == null) {
      return false;
    }
    ClassElement superElement = superType.element;
    ConstructorElement superDefaultConstructor = superElement.unnamedConstructor;
    if (superDefaultConstructor != null) {
      if (superDefaultConstructor.isFactory()) {
        _errorReporter.reportError2(CompileTimeErrorCode.NON_GENERATIVE_CONSTRUCTOR, node.returnType, [superDefaultConstructor]);
        return true;
      }
      return false;
    }
    _errorReporter.reportError2(CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT, node.returnType, [superElement.name]);
    return true;
  }

  /**
   * This verifies the passed operator-method declaration, has correct number of parameters.
   * <p>
   * This method assumes that the method declaration was tested to be an operator declaration before
   * being called.
   * @param node the method declaration to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR
   */
  bool checkForWrongNumberOfParametersForOperator(MethodDeclaration node) {
    FormalParameterList parameterList = node.parameters;
    if (parameterList == null) {
      return false;
    }
    int numParameters = parameterList.parameters.length;
    SimpleIdentifier nameNode = node.name;
    if (nameNode == null) {
      return false;
    }
    String name = nameNode.name;
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
    if ("-" == name && numParameters > 1) {
      _errorReporter.reportError2(CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR_MINUS, nameNode, [numParameters]);
      return true;
    }
    return false;
  }

  /**
   * This verifies if the passed setter parameter list have only one parameter.
   * <p>
   * This method assumes that the method declaration was tested to be a setter before being called.
   * @param setterName the name of the setter to report problems on
   * @param parameterList the parameter list to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER
   */
  bool checkForWrongNumberOfParametersForSetter(SimpleIdentifier setterName, FormalParameterList parameterList) {
    if (setterName == null) {
      return false;
    }
    if (parameterList == null) {
      return false;
    }
    int numberOfParameters = parameterList.parameters.length;
    if (numberOfParameters != 1) {
      _errorReporter.reportError2(CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER, setterName, [numberOfParameters]);
      return true;
    }
    return false;
  }

  /**
   * Return the propagated type of the given expression, or the static type if there is no
   * propagated type information.
   * @param expression the expression whose type is to be returned
   * @return the propagated or static type of the given expression, whichever is best
   */
  Type2 getBestType(Expression expression) {
    Type2 type = getPropagatedType(expression);
    if (type == null) {
      type = getStaticType(expression);
    }
    return type;
  }

  /**
   * Returns the Type (return type) for a given getter.
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
   * Return the propagated type of the given expression that is to be used for type analysis.
   * @param expression the expression whose type is to be returned
   * @return the propagated type of the given expression
   */
  Type2 getPropagatedType(Expression expression) => expression.propagatedType;

  /**
   * Returns the Type (first and only parameter) for a given setter.
   * @param propertyAccessorElement
   * @return The type of the given setter.
   */
  Type2 getSetterType(PropertyAccessorElement propertyAccessorElement) {
    List<ParameterElement> setterParameters = propertyAccessorElement.parameters;
    if (setterParameters.length == 0) {
      return null;
    }
    return setterParameters[0].type;
  }

  /**
   * Return the static type of the given expression that is to be used for type analysis.
   * @param expression the expression whose type is to be returned
   * @return the static type of the given expression
   */
  Type2 getStaticType(Expression expression) {
    Type2 type = expression.staticType;
    if (type == null) {
      return _dynamicType;
    }
    return type;
  }

  /**
   * Return the variable element represented by the given expression, or {@code null} if there is no
   * such element.
   * @param expression the expression whose element is to be returned
   * @return the variable element represented by the expression
   */
  VariableElement getVariableElement(Expression expression) {
    if (expression is Identifier) {
      Element element = ((expression as Identifier)).element;
      if (element is VariableElement) {
        return element as VariableElement;
      }
    }
    return null;
  }

  /**
   * @return {@code true} if the given constructor redirects to itself, directly or indirectly
   */
  bool hasRedirectingFactoryConstructorCycle(ConstructorElement element) {
    Set<ConstructorElement> constructors = new Set<ConstructorElement>();
    ConstructorElement current = element;
    while (current != null) {
      if (constructors.contains(current)) {
        return identical(current, element);
      }
      javaSetAdd(constructors, current);
      current = current.redirectedConstructor;
      if (current is ConstructorMember) {
        current = ((current as ConstructorMember)).baseElement;
      }
    }
    return false;
  }

  /**
   * @param node the 'this' expression to analyze
   * @return {@code true} if the given 'this' expression is in the valid context
   */
  bool isThisInValidContext(ThisExpression node) {
    for (ASTNode n = node; n != null; n = n.parent) {
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
        return !method.isStatic();
      }
    }
    return false;
  }
}
/**
 * This enum holds one of four states of a field initialization state through a constructor
 * signature, not initialized, initialized in the field declaration, initialized in the field
 * formal, and finally, initialized in the initializers list.
 */
class INIT_STATE implements Comparable<INIT_STATE> {
  static final INIT_STATE NOT_INIT = new INIT_STATE('NOT_INIT', 0);
  static final INIT_STATE INIT_IN_DECLARATION = new INIT_STATE('INIT_IN_DECLARATION', 1);
  static final INIT_STATE INIT_IN_FIELD_FORMAL = new INIT_STATE('INIT_IN_FIELD_FORMAL', 2);
  static final INIT_STATE INIT_IN_DEFAULT_VALUE = new INIT_STATE('INIT_IN_DEFAULT_VALUE', 3);
  static final INIT_STATE INIT_IN_INITIALIZERS = new INIT_STATE('INIT_IN_INITIALIZERS', 4);
  static final List<INIT_STATE> values = [NOT_INIT, INIT_IN_DECLARATION, INIT_IN_FIELD_FORMAL, INIT_IN_DEFAULT_VALUE, INIT_IN_INITIALIZERS];

  /// The name of this enum constant, as declared in the enum declaration.
  final String name;

  /// The position in the enum declaration.
  final int ordinal;
  INIT_STATE(this.name, this.ordinal) {
  }
  int compareTo(INIT_STATE other) => ordinal - other.ordinal;
  int get hashCode => ordinal;
  String toString() => name;
}
/**
 * Instances of the class {@code PubVerifier} traverse an AST structure looking for deviations from
 * pub best practices.
 */
class PubVerifier extends RecursiveASTVisitor<Object> {
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
   * @param uriLiteral the import URL (not {@code null})
   * @param path the file path being verified (not {@code null})
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see PubSuggestionCode.FILE_IMPORT_INSIDE_LIB_REFERENCES_FILE_OUTSIDE
   */
  bool checkForFileImportInsideLibReferencesFileOutside(StringLiteral uriLiteral, String path) {
    Source source = getSource(uriLiteral);
    String fullName = getSourceFullName(source);
    if (fullName != null) {
      int pathIndex = 0;
      int fullNameIndex = fullName.length;
      while (pathIndex < path.length && JavaString.startsWithBefore(path, "../", pathIndex)) {
        fullNameIndex = fullName.lastIndexOf('/', fullNameIndex);
        if (fullNameIndex < 4) {
          return false;
        }
        if (JavaString.startsWithBefore(fullName, "/lib", fullNameIndex - 4)) {
          String relativePubspecPath = path.substring(0, pathIndex + 3) + _PUBSPEC_YAML;
          Source pubspecSource = _context.sourceFactory.resolveUri(source, relativePubspecPath);
          if (pubspecSource.exists()) {
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
   * @param uriLiteral the import URL (not {@code null})
   * @param path the file path being verified (not {@code null})
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see PubSuggestionCode.FILE_IMPORT_OUTSIDE_LIB_REFERENCES_FILE_INSIDE
   */
  bool checkForFileImportOutsideLibReferencesFileInside(StringLiteral uriLiteral, String path) {
    if (path.startsWith("lib/")) {
      if (checkForFileImportOutsideLibReferencesFileInside2(uriLiteral, path, 0)) {
        return true;
      }
    }
    int pathIndex = path.indexOf("/lib/");
    while (pathIndex != -1) {
      if (checkForFileImportOutsideLibReferencesFileInside2(uriLiteral, path, pathIndex + 1)) {
        return true;
      }
      pathIndex = path.indexOf("/lib/", pathIndex + 4);
    }
    return false;
  }
  bool checkForFileImportOutsideLibReferencesFileInside2(StringLiteral uriLiteral, String path, int pathIndex) {
    Source source = getSource(uriLiteral);
    String relativePubspecPath = path.substring(0, pathIndex) + _PUBSPEC_YAML;
    Source pubspecSource = _context.sourceFactory.resolveUri(source, relativePubspecPath);
    if (!pubspecSource.exists()) {
      return false;
    }
    String fullName = getSourceFullName(source);
    if (fullName != null) {
      if (!fullName.contains("/lib/")) {
        _errorReporter.reportError2(PubSuggestionCode.FILE_IMPORT_OUTSIDE_LIB_REFERENCES_FILE_INSIDE, uriLiteral, []);
        return true;
      }
    }
    return false;
  }

  /**
   * This verifies that the passed package import directive does not contain ".."
   * @param uriLiteral the import URL (not {@code null})
   * @param path the path to be validated (not {@code null})
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see PubSuggestionCode.PACKAGE_IMPORT_CONTAINS_DOT_DOT
   */
  bool checkForPackageImportContainsDotDot(StringLiteral uriLiteral, String path) {
    if (path.startsWith("../") || path.contains("/../")) {
      _errorReporter.reportError2(PubSuggestionCode.PACKAGE_IMPORT_CONTAINS_DOT_DOT, uriLiteral, []);
      return true;
    }
    return false;
  }

  /**
   * Answer the source associated with the compilation unit containing the given AST node.
   * @param node the node (not {@code null})
   * @return the source or {@code null} if it could not be determined
   */
  Source getSource(ASTNode node) {
    Source source = null;
    CompilationUnit unit = node.getAncestor(CompilationUnit);
    if (unit != null) {
      CompilationUnitElement element = unit.element;
      if (element != null) {
        source = element.source;
      }
    }
    return source;
  }

  /**
   * Answer the full name of the given source. The returned value will have all{@link File#separatorChar} replace by '/'.
   * @param source the source
   * @return the full name or {@code null} if it could not be determined
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
 * The enumeration {@code ResolverErrorCode} defines the error codes used for errors detected by the
 * resolver. The convention for this class is for the name of the error code to indicate the problem
 * that caused the error to be generated and for the error message to explain what is wrong and,
 * when appropriate, how the problem can be corrected.
 * @coverage dart.engine.resolver
 */
class ResolverErrorCode implements Comparable<ResolverErrorCode>, ErrorCode {
  static final ResolverErrorCode BREAK_LABEL_ON_SWITCH_MEMBER = new ResolverErrorCode('BREAK_LABEL_ON_SWITCH_MEMBER', 0, ErrorType.COMPILE_TIME_ERROR, "Break label resolves to case or default statement");
  static final ResolverErrorCode CONTINUE_LABEL_ON_SWITCH = new ResolverErrorCode('CONTINUE_LABEL_ON_SWITCH', 1, ErrorType.COMPILE_TIME_ERROR, "A continue label resolves to switch, must be loop or switch member");
  static final ResolverErrorCode MISSING_LIBRARY_DIRECTIVE_WITH_PART = new ResolverErrorCode('MISSING_LIBRARY_DIRECTIVE_WITH_PART', 2, ErrorType.COMPILE_TIME_ERROR, "Libraries that have parts must have a library directive");
  static final List<ResolverErrorCode> values = [BREAK_LABEL_ON_SWITCH_MEMBER, CONTINUE_LABEL_ON_SWITCH, MISSING_LIBRARY_DIRECTIVE_WITH_PART];

  /// The name of this enum constant, as declared in the enum declaration.
  final String name;

  /// The position in the enum declaration.
  final int ordinal;

  /**
   * The type of this error.
   */
  ErrorType _type;

  /**
   * The message template used to create the message to be displayed for this error.
   */
  String _message;

  /**
   * Initialize a newly created error code to have the given type and message.
   * @param type the type of this error
   * @param message the message template used to create the message to be displayed for the error
   */
  ResolverErrorCode(this.name, this.ordinal, ErrorType type, String message) {
    this._type = type;
    this._message = message;
  }
  ErrorSeverity get errorSeverity => _type.severity;
  String get message => _message;
  ErrorType get type => _type;
  int compareTo(ResolverErrorCode other) => ordinal - other.ordinal;
  int get hashCode => ordinal;
  String toString() => name;
}