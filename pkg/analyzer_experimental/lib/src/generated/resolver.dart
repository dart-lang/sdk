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
import 'sdk.dart' show DartSdk;
import 'element.dart' hide HideCombinator, ShowCombinator;
import 'html.dart' as ht;
import 'engine.dart';
import 'constant.dart';
import 'element.dart' as __imp_combi show HideCombinator, ShowCombinator;

/**
 * Instances of the class {@code CompilationUnitBuilder} build an element model for a single
 * compilation unit.
 * @coverage dart.engine.resolver
 */
class CompilationUnitBuilder {
  /**
   * Initialize a newly created compilation unit element builder.
   * @param analysisContext the analysis context in which the element model will be built
   */
  CompilationUnitBuilder() : super() {
  }
  /**
   * Build the compilation unit element for the given source.
   * @param source the source describing the compilation unit
   * @param unit the AST structure representing the compilation unit
   * @return the compilation unit element that was built
   * @throws AnalysisException if the analysis could not be performed
   */
  CompilationUnitElementImpl buildCompilationUnit(Source source18, CompilationUnit unit) {
    if (unit == null) {
      return null;
    }
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    unit.accept(builder);
    CompilationUnitElementImpl element = new CompilationUnitElementImpl(source18.shortName);
    element.accessors = holder.accessors;
    element.functions = holder.functions;
    element.source = source18;
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
    SimpleIdentifier exceptionParameter2 = node.exceptionParameter;
    if (exceptionParameter2 != null) {
      LocalVariableElementImpl exception = new LocalVariableElementImpl(exceptionParameter2);
      _currentHolder.addLocalVariable(exception);
      exceptionParameter2.element = exception;
      SimpleIdentifier stackTraceParameter2 = node.stackTraceParameter;
      if (stackTraceParameter2 != null) {
        LocalVariableElementImpl stackTrace = new LocalVariableElementImpl(stackTraceParameter2);
        _currentHolder.addLocalVariable(stackTrace);
        stackTraceParameter2.element = stackTrace;
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
    List<TypeVariableElement> typeVariables4 = holder.typeVariables;
    InterfaceTypeImpl interfaceType = new InterfaceTypeImpl.con1(element);
    interfaceType.typeArguments = createTypeVariableTypes(typeVariables4);
    element.type = interfaceType;
    List<ConstructorElement> constructors3 = holder.constructors;
    if (constructors3.length == 0) {
      ConstructorElementImpl constructor = new ConstructorElementImpl(null);
      constructor.synthetic = true;
      FunctionTypeImpl type = new FunctionTypeImpl.con1(constructor);
      type.returnType = interfaceType;
      constructor.type = type;
      constructors3 = <ConstructorElement> [constructor];
    }
    element.abstract = node.abstractKeyword != null;
    element.accessors = holder.accessors;
    element.constructors = constructors3;
    element.fields = holder.fields;
    element.methods = holder.methods;
    element.typeVariables = typeVariables4;
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
    List<TypeVariableElement> typeVariables5 = holder.typeVariables;
    element.typeVariables = typeVariables5;
    InterfaceTypeImpl interfaceType = new InterfaceTypeImpl.con1(element);
    interfaceType.typeArguments = createTypeVariableTypes(typeVariables5);
    element.type = interfaceType;
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
      Identifier returnType4 = node.returnType;
      if (returnType4 != null) {
        element.nameOffset = returnType4.offset;
      }
    } else {
      constructorName.element = element;
    }
    return null;
  }
  Object visitDeclaredIdentifier(DeclaredIdentifier node) {
    SimpleIdentifier variableName = node.identifier;
    sc.Token keyword28 = node.keyword;
    LocalVariableElementImpl element = new LocalVariableElementImpl(variableName);
    ForEachStatement statement = node.parent as ForEachStatement;
    int declarationEnd = node.offset + node.length;
    int statementEnd = statement.offset + statement.length;
    element.setVisibleRange(declarationEnd, statementEnd - declarationEnd - 1);
    element.const3 = matches(keyword28, sc.Keyword.CONST);
    element.final2 = matches(keyword28, sc.Keyword.FINAL);
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
      parameter.initializingFormal = true;
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
          _currentHolder.addField(field);
        }
        if (matches(property, sc.Keyword.GET)) {
          PropertyAccessorElementImpl getter = new PropertyAccessorElementImpl.con1(propertyNameNode);
          getter.functions = holder.functions;
          getter.labels = holder.labels;
          getter.localVariables = holder.localVariables;
          getter.variable = field;
          getter.getter = true;
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
    List<ParameterElement> parameters11 = holder.parameters;
    List<TypeVariableElement> typeVariables6 = holder.typeVariables;
    FunctionTypeAliasElementImpl element = new FunctionTypeAliasElementImpl(aliasName);
    element.parameters = parameters11;
    element.typeVariables = typeVariables6;
    FunctionTypeImpl type = new FunctionTypeImpl.con2(element);
    type.typeArguments = createTypeVariableTypes(typeVariables6);
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
      element.static = node.isStatic();
      _currentHolder.addMethod(element);
      methodName.element = element;
    } else {
      SimpleIdentifier propertyNameNode = node.name;
      String propertyName = propertyNameNode.name;
      FieldElementImpl field = _currentHolder.getField(propertyName) as FieldElementImpl;
      if (field == null) {
        field = new FieldElementImpl.con2(node.name.name);
        field.final2 = true;
        field.static = matches(node.modifierKeyword, sc.Keyword.STATIC);
        _currentHolder.addField(field);
      }
      if (matches(property, sc.Keyword.GET)) {
        PropertyAccessorElementImpl getter = new PropertyAccessorElementImpl.con1(propertyNameNode);
        getter.functions = holder.functions;
        getter.labels = holder.labels;
        getter.localVariables = holder.localVariables;
        getter.variable = field;
        getter.getter = true;
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
    sc.Token keyword29 = ((node.parent as VariableDeclarationList)).keyword;
    bool isConst = matches(keyword29, sc.Keyword.CONST);
    bool isFinal = matches(keyword29, sc.Keyword.FINAL);
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
      PropertyAccessorElementImpl getter = new PropertyAccessorElementImpl.con2(variable);
      getter.getter = true;
      _currentHolder.addAccessor(getter);
      variable.getter = getter;
      if (!isFinal) {
        PropertyAccessorElementImpl setter = new PropertyAccessorElementImpl.con2(variable);
        setter.setter = true;
        _currentHolder.addAccessor(setter);
        variable.setter = setter;
      }
      if (_inFieldContext) {
        ((variable as FieldElementImpl)).static = matches(((node.parent.parent as FieldDeclaration)).keyword, sc.Keyword.STATIC);
      }
    }
    return super.visitVariableDeclaration(node);
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
    ASTNode parent13 = node.parent;
    while (parent13 != null) {
      if (parent13 is FunctionExpression) {
        return ((parent13 as FunctionExpression)).body;
      } else if (parent13 is MethodDeclaration) {
        return ((parent13 as MethodDeclaration)).body;
      }
      parent13 = parent13.parent;
    }
    return null;
  }
  /**
   * Return {@code true} if the given token is a token for the given keyword.
   * @param token the token being tested
   * @param keyword the keyword being tested for
   * @return {@code true} if the given token is a token for the given keyword
   */
  bool matches(sc.Token token, sc.Keyword keyword37) => token != null && identical(token.type, sc.TokenType.KEYWORD) && identical(((token as sc.KeywordToken)).keyword, keyword37);
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
  /**
   * Initialize a newly created element holder.
   */
  ElementHolder() : super() {
  }
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
   * The HTML element being built.
   */
  HtmlElementImpl _htmlElement;
  /**
   * The script elements being built.
   */
  List<HtmlScriptElement> _scripts;
  /**
   * Initialize a newly created HTML unit builder.
   * @param context the analysis context in which the element model will be built
   */
  HtmlUnitBuilder(InternalAnalysisContext context) {
    this._context = context;
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
  HtmlElementImpl buildHtmlElement2(Source source19, ht.HtmlUnit unit) {
    HtmlElementImpl result = new HtmlElementImpl(_context, source19.shortName);
    result.source = source19;
    _htmlElement = result;
    unit.accept(this);
    _htmlElement = null;
    unit.element = result;
    return result;
  }
  Object visitHtmlUnit(ht.HtmlUnit node) {
    _scripts = new List<HtmlScriptElement>();
    node.visitChildren(this);
    _htmlElement.scripts = new List.from(_scripts);
    _scripts = null;
    return null;
  }
  Object visitXmlAttributeNode(ht.XmlAttributeNode node) => null;
  Object visitXmlTagNode(ht.XmlTagNode node) {
    if (isScriptNode(node)) {
      Source htmlSource = _htmlElement.source;
      String scriptSourcePath = getScriptSourcePath(node);
      if (identical(node.attributeEnd.type, ht.TokenType.GT) && scriptSourcePath == null) {
        EmbeddedHtmlScriptElementImpl script = new EmbeddedHtmlScriptElementImpl(node);
        String contents = node.content;
        AnalysisErrorListener errorListener = new AnalysisErrorListener_5();
        sc.StringScanner scanner = new sc.StringScanner(null, contents, errorListener);
        sc.Token firstToken = scanner.tokenize();
        List<int> lineStarts2 = scanner.lineStarts;
        Parser parser = new Parser(null, errorListener);
        CompilationUnit unit = parser.parseCompilationUnit(firstToken);
        try {
          CompilationUnitBuilder builder = new CompilationUnitBuilder();
          CompilationUnitElementImpl elem = builder.buildCompilationUnit(htmlSource, unit);
          LibraryElementImpl library = new LibraryElementImpl(_context, null);
          library.definingCompilationUnit = elem;
          script.scriptLibrary = library;
        } on AnalysisException catch (e) {
          print(e);
        }
        _scripts.add(script);
      } else {
        ExternalHtmlScriptElementImpl script = new ExternalHtmlScriptElementImpl(node);
        if (scriptSourcePath != null) {
          script.scriptSource = _context.sourceFactory.resolveUri(htmlSource, scriptSourcePath);
        }
        _scripts.add(script);
      }
    } else {
      node.visitChildren(this);
    }
    return null;
  }
  /**
   * Return the value of the source attribute if it exists.
   * @param node the node containing attributes
   * @return the source path or {@code null} if not defined
   */
  String getScriptSourcePath(ht.XmlTagNode node) {
    for (ht.XmlAttributeNode attribute in node.attributes) {
      if (attribute.name.lexeme == _SRC) {
        String text2 = attribute.text;
        return text2 != null && text2.length > 0 ? text2 : null;
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
}
class AnalysisErrorListener_5 implements AnalysisErrorListener {
  void onError(AnalysisError error) {
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
   * Initialize a newly created resolver.
   */
  DeclarationResolver() : super() {
  }
  /**
   * Resolve the declarations within the given compilation unit to the elements rooted at the given
   * element.
   * @param unit the compilation unit to be resolved
   * @param element the root of the element model used to resolve the AST nodes
   */
  void resolve(CompilationUnit unit, CompilationUnitElement element67) {
    _enclosingUnit = element67;
    unit.element = element67;
    unit.accept(this);
  }
  Object visitCatchClause(CatchClause node) {
    SimpleIdentifier exceptionParameter3 = node.exceptionParameter;
    if (exceptionParameter3 != null) {
      List<LocalVariableElement> localVariables3 = _enclosingExecutable.localVariables;
      find3(localVariables3, exceptionParameter3);
      SimpleIdentifier stackTraceParameter3 = node.stackTraceParameter;
      if (stackTraceParameter3 != null) {
        find3(localVariables3, stackTraceParameter3);
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
    ParameterElement element = find3(_enclosingExecutable.parameters, parameterName);
    Expression defaultValue2 = node.defaultValue;
    if (defaultValue2 != null) {
      ExecutableElement outerExecutable = _enclosingExecutable;
      try {
        if (element == null) {
        } else {
          _enclosingExecutable = element.initializer;
        }
        defaultValue2.accept(this);
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
    String uri3 = getStringValue(node.uri);
    if (uri3 != null) {
      LibraryElement library31 = _enclosingUnit.library;
      ExportElement exportElement = find5(library31.exports, _enclosingUnit.context.sourceFactory.resolveUri(_enclosingUnit.source, uri3));
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
    String uri4 = getStringValue(node.uri);
    if (uri4 != null) {
      LibraryElement library32 = _enclosingUnit.library;
      ImportElement importElement = find6(library32.imports, _enclosingUnit.context.sourceFactory.resolveUri(_enclosingUnit.source, uri4), node.prefix);
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
    String uri5 = getStringValue(node.uri);
    if (uri5 != null) {
      Source partSource = _enclosingUnit.context.sourceFactory.resolveUri(_enclosingUnit.source, uri5);
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
    Expression initializer5 = node.initializer;
    if (initializer5 != null) {
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
  Element find4(List<Element> elements, String name30, int offset) {
    for (Element element in elements) {
      if (element.name == name30 && element.nameOffset == offset) {
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
  ExportElement find5(List<ExportElement> exports, Source source21) {
    for (ExportElement export in exports) {
      if (export.exportedLibrary.source == source21) {
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
  ImportElement find6(List<ImportElement> imports, Source source22, SimpleIdentifier prefix12) {
    for (ImportElement element in imports) {
      if (element.importedLibrary.source == source22) {
        PrefixElement prefixElement = element.prefix;
        if (prefix12 == null) {
          if (prefixElement == null) {
            return element;
          }
        } else {
          if (prefixElement != null && prefix12.name == prefixElement.name) {
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
   * The resolver driving this participant.
   */
  ResolverVisitor _resolver;
  /**
   * Initialize a newly created visitor to resolve the nodes in a compilation unit.
   * @param resolver the resolver driving this participant
   */
  ElementResolver(ResolverVisitor resolver) {
    this._resolver = resolver;
  }
  Object visitAssignmentExpression(AssignmentExpression node) {
    sc.TokenType operator7 = node.operator.type;
    if (operator7 != sc.TokenType.EQ) {
      operator7 = operatorFromCompoundAssignment(operator7);
      Expression leftNode = node.leftHandSide;
      if (leftNode != null) {
        Type2 leftType = getType(leftNode);
        if (leftType != null) {
          MethodElement method = lookUpMethod(leftType, operator7.lexeme);
          if (method != null) {
            node.element = method;
          } else {
          }
        }
      }
    }
    return null;
  }
  Object visitBinaryExpression(BinaryExpression node) {
    sc.Token operator8 = node.operator;
    if (operator8.isUserDefinableOperator()) {
      Type2 leftType = getType(node.leftOperand);
      if (leftType == null || leftType.isDynamic()) {
        return null;
      } else if (leftType is FunctionType) {
        leftType = _resolver.typeProvider.functionType;
      }
      String methodName = operator8.lexeme;
      MethodElement member = lookUpMethod(leftType, methodName);
      if (member == null) {
        _resolver.reportError3(StaticWarningCode.UNDEFINED_OPERATOR, operator8, [methodName, leftType.name]);
      } else {
        node.element = member;
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
  Object visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    FieldElement fieldElement = null;
    SimpleIdentifier fieldName2 = node.fieldName;
    ClassElement enclosingClass2 = _resolver.enclosingClass;
    fieldElement = ((enclosingClass2 as ClassElementImpl)).getField(fieldName2.name);
    if (fieldElement != null && !fieldElement.isSynthetic()) {
      recordResolution(fieldName2, fieldElement);
    }
    return null;
  }
  Object visitConstructorName(ConstructorName node) {
    Type2 type14 = node.type.type;
    if (type14 is DynamicTypeImpl) {
      return null;
    } else if (type14 is! InterfaceType) {
      ASTNode parent14 = node.parent;
      if (parent14 is InstanceCreationExpression) {
        if (((parent14 as InstanceCreationExpression)).isConst()) {
        } else {
        }
      } else {
      }
      return null;
    }
    ClassElement classElement = ((type14 as InterfaceType)).element;
    ConstructorElement constructor;
    SimpleIdentifier name17 = node.name;
    if (name17 == null) {
      constructor = classElement.unnamedConstructor;
    } else {
      constructor = classElement.getNamedConstructor(name17.name);
      name17.element = constructor;
    }
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
  Object visitExportDirective(ExportDirective node) {
    Element element28 = node.element;
    if (element28 is ExportElement) {
      resolveCombinators(((element28 as ExportElement)).exportedLibrary, node.combinators);
    }
    return null;
  }
  Object visitFieldFormalParameter(FieldFormalParameter node) {
    String fieldName = node.identifier.name;
    ClassElement classElement = _resolver.enclosingClass;
    if (classElement != null) {
      FieldElement fieldElement = ((classElement as ClassElementImpl)).getField(fieldName);
      if (fieldElement != null) {
        if (!fieldElement.isSynthetic()) {
          ParameterElement parameterElement = node.element;
          if (parameterElement is FieldFormalParameterElementImpl) {
            ((parameterElement as FieldFormalParameterElementImpl)).field = fieldElement;
            if (fieldElement.isStatic()) {
              _resolver.reportError(CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_STATIC_FIELD, node, [fieldName]);
            }
          }
        }
      } else {
        _resolver.reportError(CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTANT_FIELD, node, [fieldName]);
      }
    }
    return super.visitFieldFormalParameter(node);
  }
  Object visitFunctionExpressionInvocation(FunctionExpressionInvocation node) => null;
  Object visitImportDirective(ImportDirective node) {
    SimpleIdentifier prefixNode = node.prefix;
    if (prefixNode != null) {
      String prefixName = prefixNode.name;
      for (PrefixElement prefixElement in _resolver.definingLibrary.prefixes) {
        if (prefixElement.name == prefixName) {
          recordResolution(prefixNode, prefixElement);
          break;
        }
      }
    }
    Element element29 = node.element;
    if (element29 is ImportElement) {
      resolveCombinators(((element29 as ImportElement)).importedLibrary, node.combinators);
    }
    return null;
  }
  Object visitIndexExpression(IndexExpression node) {
    Type2 arrayType = getType(node.realTarget);
    if (arrayType == null || arrayType.isDynamic()) {
      return null;
    }
    String operator;
    if (node.inSetterContext()) {
      operator = sc.TokenType.INDEX_EQ.lexeme;
    } else {
      operator = sc.TokenType.INDEX.lexeme;
    }
    MethodElement member = lookUpMethod(arrayType, operator);
    if (member == null) {
      _resolver.reportError(StaticWarningCode.UNDEFINED_OPERATOR, node, [operator, arrayType.name]);
    } else {
      node.element = member;
    }
    return null;
  }
  Object visitInstanceCreationExpression(InstanceCreationExpression node) {
    ConstructorElement invokedConstructor = node.constructorName.element;
    node.element = invokedConstructor;
    resolveNamedArguments(node.argumentList, invokedConstructor);
    return null;
  }
  Object visitMethodInvocation(MethodInvocation node) {
    SimpleIdentifier methodName2 = node.methodName;
    Expression target = node.realTarget;
    Element element;
    if (target == null) {
      element = _resolver.nameScope.lookup(methodName2, _resolver.definingLibrary);
      if (element == null) {
        ClassElement enclosingClass3 = _resolver.enclosingClass;
        if (enclosingClass3 != null) {
          InterfaceType enclosingType = enclosingClass3.type;
          element = lookUpMethod(enclosingType, methodName2.name);
          if (element == null) {
            PropertyAccessorElement getter = lookUpGetter(enclosingType, methodName2.name);
            if (getter != null) {
              FunctionType getterType = getter.type;
              if (getterType != null) {
                Type2 returnType5 = getterType.returnType;
                if (!isExecutableType(returnType5)) {
                  _resolver.reportError(StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION, methodName2, [methodName2.name]);
                }
              }
              recordResolution(methodName2, getter);
              return null;
            }
          }
        }
      }
    } else {
      Type2 targetType = getType(target);
      if (targetType is InterfaceType) {
        InterfaceType classType = targetType as InterfaceType;
        element = lookUpMethod(classType, methodName2.name);
        if (element == null) {
          PropertyAccessorElement accessor = classType.getGetter(methodName2.name);
          if (accessor != null) {
            Type2 returnType6 = accessor.type.returnType;
            if (!isExecutableType(returnType6)) {
              _resolver.reportError(StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION, methodName2, [methodName2.name]);
              return null;
            }
            element = accessor;
          }
        }
        if (element == null && target is SuperExpression) {
          _resolver.reportError(StaticTypeWarningCode.UNDEFINED_SUPER_METHOD, methodName2, [methodName2.name, targetType.element.name]);
          return null;
        }
      } else if (target is SimpleIdentifier) {
        Element targetElement = ((target as SimpleIdentifier)).element;
        if (targetElement is PrefixElement) {
          String name10 = "${((target as SimpleIdentifier)).name}.${methodName2}";
          Identifier functionName = new Identifier_8(name10);
          element = _resolver.nameScope.lookup(functionName, _resolver.definingLibrary);
        } else {
          return null;
        }
      } else {
        return null;
      }
    }
    ExecutableElement invokedMethod = null;
    if (element is PropertyAccessorElement) {
      PropertyAccessorElement getter = element as PropertyAccessorElement;
      FunctionType getterType = getter.type;
      if (getterType != null) {
        Type2 returnType7 = getterType.returnType;
        if (!isExecutableType(returnType7)) {
          _resolver.reportError(StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION, methodName2, [methodName2.name]);
        }
      }
      recordResolution(methodName2, element);
      return null;
    } else if (element is ExecutableElement) {
      invokedMethod = element as ExecutableElement;
    } else {
      if (element is PropertyInducingElement) {
        PropertyAccessorElement getter3 = ((element as PropertyInducingElement)).getter;
        FunctionType getterType = getter3.type;
        if (getterType != null) {
          Type2 returnType8 = getterType.returnType;
          if (!isExecutableType(returnType8)) {
            _resolver.reportError(StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION, methodName2, [methodName2.name]);
          }
        }
        recordResolution(methodName2, element);
        return null;
      } else if (element is VariableElement) {
        Type2 variableType = _resolver.overrideManager.getType(element);
        if (variableType == null) {
          variableType = ((element as VariableElement)).type;
        }
        if (!isExecutableType(variableType)) {
          _resolver.reportError(StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION, methodName2, [methodName2.name]);
        }
        recordResolution(methodName2, element);
        return null;
      } else {
        if (target == null) {
          ClassElement enclosingClass4 = _resolver.enclosingClass;
          if (enclosingClass4 == null) {
            _resolver.reportError(StaticTypeWarningCode.UNDEFINED_FUNCTION, methodName2, [methodName2.name]);
          } else if (element == null) {
            _resolver.reportError(StaticTypeWarningCode.UNDEFINED_METHOD, methodName2, [methodName2.name, enclosingClass4.name]);
          } else {
            _resolver.reportError(StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION, methodName2, [methodName2.name]);
          }
        } else {
          Type2 targetType = getType(target);
          String targetTypeName = targetType == null ? null : targetType.name;
          if (targetTypeName == null) {
            _resolver.reportError(StaticTypeWarningCode.UNDEFINED_FUNCTION, methodName2, [methodName2.name]);
          } else {
            _resolver.reportError(StaticTypeWarningCode.UNDEFINED_METHOD, methodName2, [methodName2.name, targetTypeName]);
          }
        }
        return null;
      }
    }
    recordResolution(methodName2, invokedMethod);
    resolveNamedArguments(node.argumentList, invokedMethod);
    return null;
  }
  Object visitPostfixExpression(PostfixExpression node) {
    sc.Token operator9 = node.operator;
    Type2 operandType = getType(node.operand);
    if (operandType == null || operandType.isDynamic()) {
      return null;
    }
    String methodName;
    if (identical(operator9.type, sc.TokenType.PLUS_PLUS)) {
      methodName = sc.TokenType.PLUS.lexeme;
    } else {
      methodName = sc.TokenType.MINUS.lexeme;
    }
    MethodElement member = lookUpMethod(operandType, methodName);
    if (member == null) {
      _resolver.reportError3(StaticWarningCode.UNDEFINED_OPERATOR, operator9, [methodName, operandType.name]);
    } else {
      node.element = member;
    }
    return null;
  }
  Object visitPrefixedIdentifier(PrefixedIdentifier node) {
    SimpleIdentifier prefix6 = node.prefix;
    SimpleIdentifier identifier14 = node.identifier;
    Element prefixElement = prefix6.element;
    if (prefixElement is PrefixElement) {
      Element element = _resolver.nameScope.lookup(node, _resolver.definingLibrary);
      if (element == null) {
        return null;
      }
      recordResolution(identifier14, element);
      return null;
    }
    if (prefixElement is ClassElement) {
      Element memberElement;
      if (node.identifier.inSetterContext()) {
        memberElement = ((prefixElement as ClassElementImpl)).getSetter(identifier14.name);
      } else {
        memberElement = ((prefixElement as ClassElementImpl)).getGetter(identifier14.name);
      }
      if (memberElement == null) {
        MethodElement methodElement = lookUpMethod(((prefixElement as ClassElement)).type, identifier14.name);
        if (methodElement != null) {
          recordResolution(identifier14, methodElement);
          return null;
        }
      }
      if (memberElement == null) {
        reportGetterOrSetterNotFound(node, identifier14, prefixElement.name);
      } else {
        recordResolution(identifier14, memberElement);
      }
      return null;
    }
    Type2 variableType;
    if (prefixElement is PropertyAccessorElement) {
      PropertyAccessorElement accessor = prefixElement as PropertyAccessorElement;
      FunctionType type15 = accessor.type;
      if (type15 == null) {
        return null;
      }
      if (accessor.isGetter()) {
        variableType = type15.returnType;
      } else {
        variableType = type15.normalParameterTypes[0];
      }
      if (variableType == null || variableType.isDynamic()) {
        return null;
      }
    } else if (prefixElement is VariableElement) {
      variableType = _resolver.overrideManager.getType(prefixElement);
      if (variableType == null) {
        variableType = ((prefixElement as VariableElement)).type;
      }
      if (variableType == null || variableType.isDynamic()) {
        return null;
      }
    } else {
      return null;
    }
    PropertyAccessorElement memberElement = null;
    if (node.identifier.inSetterContext()) {
      memberElement = lookUpSetter(variableType, identifier14.name);
    }
    if (memberElement == null && node.identifier.inGetterContext()) {
      memberElement = lookUpGetter(variableType, identifier14.name);
    }
    if (memberElement == null) {
      MethodElement methodElement = lookUpMethod(variableType, identifier14.name);
      if (methodElement != null) {
        recordResolution(identifier14, methodElement);
        return null;
      }
    }
    if (memberElement == null) {
      reportGetterOrSetterNotFound(node, identifier14, variableType.element.name);
    } else {
      recordResolution(identifier14, memberElement);
    }
    return null;
  }
  Object visitPrefixExpression(PrefixExpression node) {
    sc.Token operator10 = node.operator;
    sc.TokenType operatorType = operator10.type;
    if (operatorType.isUserDefinableOperator() || identical(operatorType, sc.TokenType.PLUS_PLUS) || identical(operatorType, sc.TokenType.MINUS_MINUS)) {
      Type2 operandType = getType(node.operand);
      if (operandType == null || operandType.isDynamic()) {
        return null;
      }
      String methodName;
      if (identical(operatorType, sc.TokenType.PLUS_PLUS)) {
        methodName = sc.TokenType.PLUS.lexeme;
      } else if (identical(operatorType, sc.TokenType.MINUS_MINUS)) {
        methodName = sc.TokenType.MINUS.lexeme;
      } else if (identical(operatorType, sc.TokenType.MINUS)) {
        methodName = "unary-";
      } else {
        methodName = operator10.lexeme;
      }
      MethodElement member = lookUpMethod(operandType, methodName);
      if (member == null) {
        _resolver.reportError3(StaticWarningCode.UNDEFINED_OPERATOR, operator10, [methodName, operandType.name]);
      } else {
        node.element = member;
      }
    }
    return null;
  }
  Object visitPropertyAccess(PropertyAccess node) {
    Type2 targetType = getType(node.realTarget);
    if (targetType is! InterfaceType) {
      return null;
    }
    SimpleIdentifier identifier = node.propertyName;
    PropertyAccessorElement memberElement = null;
    if (identifier.inSetterContext()) {
      memberElement = lookUpSetter(targetType, identifier.name);
    }
    if (memberElement == null && identifier.inGetterContext()) {
      memberElement = lookUpGetter(targetType, identifier.name);
    }
    if (memberElement == null) {
      MethodElement methodElement = lookUpMethod(targetType, identifier.name);
      if (methodElement != null) {
        recordResolution(identifier, methodElement);
        return null;
      }
    }
    if (memberElement == null) {
      if (identifier.inSetterContext()) {
        _resolver.reportError(StaticWarningCode.UNDEFINED_SETTER, identifier, [identifier.name, targetType.name]);
      } else if (identifier.inGetterContext()) {
        _resolver.reportError(StaticWarningCode.UNDEFINED_GETTER, identifier, [identifier.name, targetType.name]);
      } else {
        _resolver.reportError(StaticWarningCode.UNDEFINED_IDENTIFIER, identifier, [identifier.name]);
      }
    } else {
      recordResolution(identifier, memberElement);
    }
    return null;
  }
  Object visitRedirectingConstructorInvocation(RedirectingConstructorInvocation node) {
    ClassElement enclosingClass5 = _resolver.enclosingClass;
    if (enclosingClass5 == null) {
      return null;
    }
    SimpleIdentifier name = node.constructorName;
    ConstructorElement element;
    if (name == null) {
      element = enclosingClass5.unnamedConstructor;
    } else {
      element = enclosingClass5.getNamedConstructor(name.name);
    }
    if (element == null) {
      return null;
    }
    if (name != null) {
      recordResolution(name, element);
    }
    node.element = element;
    resolveNamedArguments(node.argumentList, element);
    return null;
  }
  Object visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.element != null) {
      return null;
    }
    Element element = _resolver.nameScope.lookup(node, _resolver.definingLibrary);
    if (element is PropertyAccessorElement && node.inSetterContext()) {
      PropertyInducingElement variable5 = ((element as PropertyAccessorElement)).variable;
      if (variable5 != null) {
        PropertyAccessorElement setter3 = variable5.setter;
        if (setter3 != null) {
          element = setter3;
        }
      }
    }
    ClassElement enclosingClass6 = _resolver.enclosingClass;
    if (element == null && enclosingClass6 != null) {
      InterfaceType enclosingType = enclosingClass6.type;
      if (element == null && node.inSetterContext()) {
        element = lookUpSetter(enclosingType, node.name);
      }
      if (element == null && node.inGetterContext()) {
        element = lookUpGetter(enclosingType, node.name);
      }
      if (element == null) {
        element = lookUpMethod(enclosingType, node.name);
      }
    }
    if (element == null) {
      _resolver.reportError(StaticWarningCode.UNDEFINED_IDENTIFIER, node, [node.name]);
    }
    recordResolution(node, element);
    return null;
  }
  Object visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    ClassElement enclosingClass7 = _resolver.enclosingClass;
    if (enclosingClass7 == null) {
      return null;
    }
    ClassElement superclass = getSuperclass(enclosingClass7);
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
      return null;
    }
    if (name != null) {
      recordResolution(name, element);
    }
    node.element = element;
    resolveNamedArguments(node.argumentList, element);
    return null;
  }
  Object visitTypeParameter(TypeParameter node) {
    TypeName bound3 = node.bound;
    if (bound3 != null) {
      TypeVariableElementImpl variable = node.name.element as TypeVariableElementImpl;
      if (variable != null) {
        variable.bound = bound3.type;
      }
    }
    return null;
  }
  /**
   * Search through the array of parameters for a parameter whose name matches the given name.
   * Return the parameter with the given name, or {@code null} if there is no such parameter.
   * @param parameters the parameters being searched
   * @param name the name being searched for
   * @return the parameter with the given name
   */
  ParameterElement findNamedParameter(List<ParameterElement> parameters, String name31) {
    for (ParameterElement parameter in parameters) {
      if (identical(parameter.parameterKind, ParameterKind.NAMED)) {
        String parameteName = parameter.name;
        if (parameteName != null && parameteName == name31) {
          return parameter;
        }
      }
    }
    return null;
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
   * Return the type of the given expression that is to be used for type analysis.
   * @param expression the expression whose type is to be returned
   * @return the type of the given expression
   */
  Type2 getType(Expression expression) {
    if (expression is NullLiteral) {
      return _resolver.typeProvider.objectType;
    }
    return expression.staticType;
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
      MethodElement methodElement = classElement.lookUpMethod("call", _resolver.definingLibrary);
      return methodElement != null;
    }
    return false;
  }
  /**
   * Look up the getter with the given name in the given type. Return the element representing the
   * getter that was found, or {@code null} if there is no getter with the given name.
   * @param type the type in which the getter is defined
   * @param getterName the name of the getter being looked up
   * @return the element representing the getter that was found
   */
  PropertyAccessorElement lookUpGetter(Type2 type, String getterName) {
    type = resolveTypeVariable(type);
    if (type is InterfaceType) {
      InterfaceType interfaceType = type as InterfaceType;
      PropertyAccessorElement accessor = interfaceType.lookUpGetter(getterName, _resolver.definingLibrary);
      if (accessor != null) {
        return accessor;
      }
      return lookUpGetterInInterfaces(interfaceType, getterName, new Set<ClassElement>());
    }
    return null;
  }
  /**
   * Look up the getter with the given name in the interfaces implemented by the given type, either
   * directly or indirectly. Return the element representing the getter that was found, or{@code null} if there is no getter with the given name.
   * @param targetType the type in which the getter might be defined
   * @param getterName the name of the getter being looked up
   * @param visitedInterfaces a set containing all of the interfaces that have been examined, used
   * to prevent infinite recursion and to optimize the search
   * @return the element representing the getter that was found
   */
  PropertyAccessorElement lookUpGetterInInterfaces(InterfaceType targetType, String getterName, Set<ClassElement> visitedInterfaces) {
    ClassElement targetClass = targetType.element;
    if (visitedInterfaces.contains(targetClass)) {
      return null;
    }
    javaSetAdd(visitedInterfaces, targetClass);
    PropertyAccessorElement getter = targetType.getGetter(getterName);
    if (getter != null) {
      return getter;
    }
    for (InterfaceType interfaceType in targetType.interfaces) {
      getter = lookUpGetterInInterfaces(interfaceType, getterName, visitedInterfaces);
      if (getter != null) {
        return getter;
      }
    }
    InterfaceType superclass3 = targetType.superclass;
    if (superclass3 == null) {
      return null;
    }
    return lookUpGetterInInterfaces(superclass3, getterName, visitedInterfaces);
  }
  /**
   * Find the element corresponding to the given label node in the current label scope.
   * @param parentNode the node containing the given label
   * @param labelNode the node representing the label being looked up
   * @return the element corresponding to the given label node in the current scope
   */
  LabelElementImpl lookupLabel(ASTNode parentNode, SimpleIdentifier labelNode) {
    LabelScope labelScope2 = _resolver.labelScope;
    LabelElementImpl labelElement = null;
    if (labelNode == null) {
      if (labelScope2 == null) {
      } else {
        labelElement = labelScope2.lookup2(LabelScope.EMPTY_LABEL) as LabelElementImpl;
        if (labelElement == null) {
        }
        labelElement = null;
      }
    } else {
      if (labelScope2 == null) {
        _resolver.reportError(CompileTimeErrorCode.LABEL_UNDEFINED, labelNode, [labelNode.name]);
      } else {
        labelElement = labelScope2.lookup(labelNode) as LabelElementImpl;
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
   * @param type the type in which the method is defined
   * @param methodName the name of the method being looked up
   * @return the element representing the method that was found
   */
  MethodElement lookUpMethod(Type2 type, String methodName) {
    type = resolveTypeVariable(type);
    if (type is InterfaceType) {
      InterfaceType interfaceType = type as InterfaceType;
      MethodElement method = interfaceType.lookUpMethod(methodName, _resolver.definingLibrary);
      if (method != null) {
        return method;
      }
      return lookUpMethodInInterfaces(interfaceType, methodName, new Set<ClassElement>());
    }
    return null;
  }
  /**
   * Look up the method with the given name in the interfaces implemented by the given type, either
   * directly or indirectly. Return the element representing the method that was found, or{@code null} if there is no method with the given name.
   * @param targetType the type in which the member might be defined
   * @param methodName the name of the method being looked up
   * @param visitedInterfaces a set containing all of the interfaces that have been examined, used
   * to prevent infinite recursion and to optimize the search
   * @return the element representing the method that was found
   */
  MethodElement lookUpMethodInInterfaces(InterfaceType targetType, String methodName, Set<ClassElement> visitedInterfaces) {
    ClassElement targetClass = targetType.element;
    if (visitedInterfaces.contains(targetClass)) {
      return null;
    }
    javaSetAdd(visitedInterfaces, targetClass);
    MethodElement method = targetType.getMethod(methodName);
    if (method != null) {
      return method;
    }
    for (InterfaceType interfaceType in targetType.interfaces) {
      method = lookUpMethodInInterfaces(interfaceType, methodName, visitedInterfaces);
      if (method != null) {
        return method;
      }
    }
    InterfaceType superclass4 = targetType.superclass;
    if (superclass4 == null) {
      return null;
    }
    return lookUpMethodInInterfaces(superclass4, methodName, visitedInterfaces);
  }
  /**
   * Look up the setter with the given name in the given type. Return the element representing the
   * setter that was found, or {@code null} if there is no setter with the given name.
   * @param type the type in which the setter is defined
   * @param setterName the name of the setter being looked up
   * @return the element representing the setter that was found
   */
  PropertyAccessorElement lookUpSetter(Type2 type, String setterName) {
    type = resolveTypeVariable(type);
    if (type is InterfaceType) {
      InterfaceType interfaceType = type as InterfaceType;
      PropertyAccessorElement accessor = interfaceType.lookUpSetter(setterName, _resolver.definingLibrary);
      if (accessor != null) {
        return accessor;
      }
      return lookUpSetterInInterfaces(interfaceType, setterName, new Set<ClassElement>());
    }
    return null;
  }
  /**
   * Look up the setter with the given name in the interfaces implemented by the given type, either
   * directly or indirectly. Return the element representing the setter that was found, or{@code null} if there is no setter with the given name.
   * @param targetType the type in which the setter might be defined
   * @param setterName the name of the setter being looked up
   * @param visitedInterfaces a set containing all of the interfaces that have been examined, used
   * to prevent infinite recursion and to optimize the search
   * @return the element representing the setter that was found
   */
  PropertyAccessorElement lookUpSetterInInterfaces(InterfaceType targetType, String setterName, Set<ClassElement> visitedInterfaces) {
    ClassElement targetClass = targetType.element;
    if (visitedInterfaces.contains(targetClass)) {
      return null;
    }
    javaSetAdd(visitedInterfaces, targetClass);
    PropertyAccessorElement setter = targetType.getGetter(setterName);
    if (setter != null) {
      return setter;
    }
    for (InterfaceType interfaceType in targetType.interfaces) {
      setter = lookUpSetterInInterfaces(interfaceType, setterName, visitedInterfaces);
      if (setter != null) {
        return setter;
      }
    }
    InterfaceType superclass5 = targetType.superclass;
    if (superclass5 == null) {
      return null;
    }
    return lookUpSetterInInterfaces(superclass5, setterName, visitedInterfaces);
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
  void recordResolution(SimpleIdentifier node, Element element68) {
    if (element68 != null) {
      node.element = element68;
    }
  }
  /**
   * Report the {@link StaticTypeWarningCode}s <code>UNDEFINED_SETTER</code> and
   * <code>UNDEFINED_GETTER</code>.
   * @param node the prefixed identifier that gives the context to determine if the error on the
   * undefined identifier is a getter or a setter
   * @param identifier the identifier in the passed prefix identifier
   * @param typeName the name of the type of the left hand side of the passed prefixed identifier
   */
  void reportGetterOrSetterNotFound(PrefixedIdentifier node, SimpleIdentifier identifier32, String typeName) {
    bool isSetterContext = node.identifier.inSetterContext();
    ErrorCode errorCode = isSetterContext ? StaticTypeWarningCode.UNDEFINED_SETTER : StaticTypeWarningCode.UNDEFINED_GETTER;
    _resolver.reportError(errorCode, identifier32, [identifier32.name, typeName]);
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
    Namespace namespace = new NamespaceBuilder().createExportNamespace(library);
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
   * Resolve the names associated with any named arguments to the parameter elements named by the
   * argument.
   * @param argumentList the arguments to be resolved
   * @param invokedMethod the method or function defining the parameters to which the named
   * arguments are to be resolved
   */
  void resolveNamedArguments(ArgumentList argumentList, ExecutableElement invokedMethod) {
    if (invokedMethod == null) {
      return;
    }
    List<ParameterElement> parameters13 = invokedMethod.parameters;
    for (Expression argument in argumentList.arguments) {
      if (argument is NamedExpression) {
        SimpleIdentifier name18 = ((argument as NamedExpression)).name.label;
        ParameterElement parameter = findNamedParameter(parameters13, name18.name);
        if (parameter != null) {
          recordResolution(name18, parameter);
        }
      }
    }
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
      Type2 bound4 = ((type as TypeVariableType)).element.bound;
      if (bound4 == null) {
        return _resolver.typeProvider.objectType;
      }
      return bound4;
    }
    return type;
  }
}
class Identifier_8 extends Identifier {
  String name10;
  Identifier_8(this.name10) : super();
  accept(ASTVisitor visitor) => null;
  sc.Token get beginToken => null;
  Element get element => null;
  sc.Token get endToken => null;
  String get name => name10;
  void visitChildren(ASTVisitor<Object> visitor) {
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
   * Return the result of resolving the given URI against the URI of the library, or {@code null} if
   * the URI is not valid. If the URI is not valid, report the error.
   * @param uriLiteral the string literal specifying the URI to be resolved
   * @return the result of resolving the given URI against the URI of the library
   */
  Source getSource(StringLiteral uriLiteral) {
    if (uriLiteral is StringInterpolation) {
      _errorListener.onError(new AnalysisError.con2(_librarySource, uriLiteral.offset, uriLiteral.length, CompileTimeErrorCode.URI_WITH_INTERPOLATION, []));
      return null;
    }
    Source source = getSource2(getStringValue(uriLiteral));
    if (source == null || !source.exists()) {
      _errorListener.onError(new AnalysisError.con2(_librarySource, uriLiteral.offset, uriLiteral.length, CompileTimeErrorCode.INVALID_URI, [uriLiteral.toSource()]));
    }
    return source;
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
  }
  String toString() => _librarySource.shortName;
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
  /**
   * Return the value of the given string literal, or {@code null} if the string is not a constant
   * string without any string interpolation.
   * @param literal the string literal whose value is to be returned
   * @return the value of the given string literal
   */
  String getStringValue(StringLiteral literal) {
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
    Source librarySource2 = library.librarySource;
    CompilationUnit definingCompilationUnit3 = library.definingCompilationUnit;
    CompilationUnitElementImpl definingCompilationUnitElement = builder.buildCompilationUnit(librarySource2, definingCompilationUnit3);
    NodeList<Directive> directives3 = definingCompilationUnit3.directives;
    LibraryIdentifier libraryNameNode = null;
    bool hasPartDirective = false;
    FunctionElement entryPoint = findEntryPoint(definingCompilationUnitElement);
    List<Directive> directivesToResolve = new List<Directive>();
    List<CompilationUnitElementImpl> sourcedCompilationUnits = new List<CompilationUnitElementImpl>();
    for (Directive directive in directives3) {
      if (directive is LibraryDirective) {
        if (libraryNameNode == null) {
          libraryNameNode = ((directive as LibraryDirective)).name;
          directivesToResolve.add(directive);
        }
      } else if (directive is PartDirective) {
        hasPartDirective = true;
        StringLiteral partUri = ((directive as PartDirective)).uri;
        Source partSource = library.getSource(partUri);
        if (partSource != null && partSource.exists()) {
          CompilationUnitElementImpl part = builder.buildCompilationUnit(partSource, library.getAST(partSource));
          String partLibraryName = getPartLibraryName(library, partSource, directivesToResolve);
          if (partLibraryName == null) {
            _errorListener.onError(new AnalysisError.con2(librarySource2, partUri.offset, partUri.length, CompileTimeErrorCode.PART_OF_NON_PART, [partUri.toSource()]));
          } else if (libraryNameNode == null) {
          } else if (libraryNameNode.name != partLibraryName) {
            _errorListener.onError(new AnalysisError.con2(librarySource2, partUri.offset, partUri.length, StaticWarningCode.PART_OF_DIFFERENT_LIBRARY, [libraryNameNode.name, partLibraryName]));
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
      _errorListener.onError(new AnalysisError.con1(librarySource2, ResolverErrorCode.MISSING_LIBRARY_DIRECTIVE_WITH_PART, []));
    }
    LibraryElementImpl libraryElement = new LibraryElementImpl(_analysisContext, libraryNameNode);
    libraryElement.definingCompilationUnit = definingCompilationUnitElement;
    if (entryPoint != null) {
      libraryElement.entryPoint = entryPoint;
    }
    libraryElement.parts = new List.from(sourcedCompilationUnits);
    for (Directive directive in directivesToResolve) {
      directive.element = libraryElement;
    }
    library.libraryElement = libraryElement;
    return libraryElement;
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
          LibraryIdentifier libraryName3 = ((directive as PartOfDirective)).libraryName;
          if (libraryName3 != null) {
            return libraryName3.name;
          }
        }
      }
    } on AnalysisException catch (exception) {
    }
    return null;
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
  AnalysisErrorListener _errorListener;
  /**
   * This error listener is used by the resolver to be able to call the listener and get back the
   * set of errors for each {@link Source}.
   * @see #recordResults()
   */
  RecordingErrorListener _recordingErrorListener;
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
  LibraryResolver.con1(InternalAnalysisContext analysisContext) {
    _jtd_constructor_263_impl(analysisContext);
  }
  _jtd_constructor_263_impl(InternalAnalysisContext analysisContext) {
    _jtd_constructor_264_impl(analysisContext, null);
  }
  /**
   * Initialize a newly created library resolver to resolve libraries within the given context.
   * @param analysisContext the analysis context in which the library is being analyzed
   * @param errorListener the listener to which analysis errors will be reported
   */
  LibraryResolver.con2(InternalAnalysisContext analysisContext2, AnalysisErrorListener additionalAnalysisErrorListener) {
    _jtd_constructor_264_impl(analysisContext2, additionalAnalysisErrorListener);
  }
  _jtd_constructor_264_impl(InternalAnalysisContext analysisContext2, AnalysisErrorListener additionalAnalysisErrorListener) {
    this._analysisContext = analysisContext2;
    this._recordingErrorListener = new RecordingErrorListener();
    if (additionalAnalysisErrorListener == null) {
      this._errorListener = _recordingErrorListener;
    } else {
      this._errorListener = new AnalysisErrorListener_9(this, additionalAnalysisErrorListener);
    }
    _coreLibrarySource = analysisContext2.sourceFactory.forUri(DartSdk.DART_CORE);
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
  AnalysisErrorListener get errorListener => _errorListener;
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
      recordResults();
      instrumentation.metric3("recordResults", "complete");
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
        HideCombinatorImpl hide = new HideCombinatorImpl();
        hide.hiddenNames = getIdentifiers(((combinator as HideCombinator)).hiddenNames);
        combinators.add(hide);
      } else {
        ShowCombinatorImpl show = new ShowCombinatorImpl();
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
      Source librarySource3 = library.librarySource;
      if (!library.explicitlyImportsCore && _coreLibrarySource != librarySource3) {
        ImportElementImpl importElement = new ImportElementImpl();
        importElement.importedLibrary = _coreLibrary.libraryElement;
        importElement.synthetic = true;
        imports.add(importElement);
      }
      LibraryElementImpl libraryElement3 = library.libraryElement;
      libraryElement3.imports = new List.from(imports);
      libraryElement3.exports = new List.from(exports);
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
        Source importedSource = library.getSource(importDirective.uri);
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
        Source exportedSource = library.getSource(exportDirective.uri);
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
    NodeList<Directive> directives4 = node.directives;
    for (Directive directive in directives4) {
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
   * Record the results of resolution with the analysis context. This includes recording
   * <ul>
   * <li>the resolved AST associated with each compilation unit,</li>
   * <li>the set of resolution errors produced for each compilation unit, and</li>
   * <li>the element models produced for each library.</li>
   * </ul>
   */
  void recordResults() {
    Map<Source, LibraryElement> elementMap = new Map<Source, LibraryElement>();
    for (Library library in _librariesInCycles) {
      recordResults2(library.librarySource, library.definingCompilationUnit);
      for (Source source in library.compilationUnitSources) {
        recordResults2(source, library.getAST(source));
      }
      elementMap[library.librarySource] = library.libraryElement;
    }
    _analysisContext.recordLibraryElements(elementMap);
  }
  void recordResults2(Source source, CompilationUnit unit) {
    List<AnalysisError> errors = _recordingErrorListener.getErrors2(source);
    unit.resolutionErrors = errors;
    _analysisContext.recordResolvedCompilationUnit(source, unit);
    _analysisContext.recordResolutionErrors(source, errors, unit.lineInfo);
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
      ErrorVerifier errorVerifier = new ErrorVerifier(errorReporter, library.libraryElement, _typeProvider);
      unit.accept(errorVerifier);
      ConstantVerifier constantVerifier = new ConstantVerifier(errorReporter);
      unit.accept(constantVerifier);
    }
  }
}
class AnalysisErrorListener_9 implements AnalysisErrorListener {
  final LibraryResolver LibraryResolver_this;
  AnalysisErrorListener additionalAnalysisErrorListener;
  AnalysisErrorListener_9(this.LibraryResolver_this, this.additionalAnalysisErrorListener);
  void onError(AnalysisError error) {
    additionalAnalysisErrorListener.onError(error);
    LibraryResolver_this._recordingErrorListener.onError(error);
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
    _jtd_constructor_265_impl(library, source, typeProvider);
  }
  _jtd_constructor_265_impl(Library library, Source source, TypeProvider typeProvider) {
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
    _jtd_constructor_266_impl(definingLibrary, source, typeProvider, errorListener);
  }
  _jtd_constructor_266_impl(LibraryElement definingLibrary, Source source, TypeProvider typeProvider, AnalysisErrorListener errorListener) {
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
    if (StaticTypeAnalyzer.USE_TYPE_PROPAGATION) {
      VariableElement element = getOverridableElement(node.expression);
      if (element != null) {
        Type2 type16 = node.type.type;
        if (type16 != null) {
          _overrideManager.setType(element, type16);
        }
      }
    }
    return null;
  }
  Object visitAssertStatement(AssertStatement node) {
    Expression condition3 = node.condition;
    condition3.accept(this);
    propagateTrueState(condition3);
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
  Object visitComment(Comment node) => null;
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
    return null;
  }
  Object visitConditionalExpression(ConditionalExpression node) {
    Expression condition4 = node.condition;
    condition4.accept(this);
    Expression thenExpression2 = node.thenExpression;
    if (thenExpression2 != null) {
      try {
        _overrideManager.enterScope();
        propagateTrueState(condition4);
        thenExpression2.accept(this);
      } finally {
        _overrideManager.exitScope();
      }
    }
    Expression elseExpression2 = node.elseExpression;
    if (elseExpression2 != null) {
      try {
        _overrideManager.enterScope();
        propagateFalseState(condition4);
        elseExpression2.accept(this);
      } finally {
        _overrideManager.exitScope();
      }
    }
    if (StaticTypeAnalyzer.USE_TYPE_PROPAGATION) {
      bool thenIsAbrupt = thenExpression2 != null && isAbruptTermination(thenExpression2);
      bool elseIsAbrupt = elseExpression2 != null && isAbruptTermination(elseExpression2);
      if (elseIsAbrupt && !thenIsAbrupt) {
        propagateTrueState(condition4);
      } else if (thenIsAbrupt && !elseIsAbrupt) {
        propagateFalseState(condition4);
      }
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
  Object visitFieldDeclaration(FieldDeclaration node) {
    try {
      _overrideManager.enterScope();
      super.visitFieldDeclaration(node);
    } finally {
      Map<Element, Type2> overrides = captureOverrides(node.fields);
      _overrideManager.exitScope();
      for (MapEntry<Element, Type2> entry in getMapEntrySet(overrides)) {
        _overrideManager.setType(entry.getKey(), entry.getValue());
      }
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
    Expression condition5 = node.condition;
    condition5.accept(this);
    Statement thenStatement2 = node.thenStatement;
    if (thenStatement2 != null) {
      try {
        _overrideManager.enterScope();
        propagateTrueState(condition5);
        thenStatement2.accept(this);
      } finally {
        _overrideManager.exitScope();
      }
    }
    Statement elseStatement2 = node.elseStatement;
    if (elseStatement2 != null) {
      try {
        _overrideManager.enterScope();
        propagateFalseState(condition5);
        elseStatement2.accept(this);
      } finally {
        _overrideManager.exitScope();
      }
    }
    if (StaticTypeAnalyzer.USE_TYPE_PROPAGATION) {
      bool thenIsAbrupt = thenStatement2 != null && isAbruptTermination2(thenStatement2);
      bool elseIsAbrupt = elseStatement2 != null && isAbruptTermination2(elseStatement2);
      if (elseIsAbrupt && !thenIsAbrupt) {
        propagateTrueState(condition5);
      } else if (thenIsAbrupt && !elseIsAbrupt) {
        propagateFalseState(condition5);
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
      Map<Element, Type2> overrides = captureOverrides(node.variables);
      _overrideManager.exitScope();
      for (MapEntry<Element, Type2> entry in getMapEntrySet(overrides)) {
        _overrideManager.setType(entry.getKey(), entry.getValue());
      }
    }
    return null;
  }
  Object visitTypeName(TypeName node) => null;
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
    if (expression is SimpleIdentifier) {
      Element element30 = ((expression as SimpleIdentifier)).element;
      if (element30 is VariableElement) {
        return element30 as VariableElement;
      }
    }
    return null;
  }
  /**
   * Return a map from the elements for the variables in the given list that have their types
   * overridden to the overriding type.
   * @param variableList the list of variables whose overriding types are to be captured
   * @return a table mapping elements to their overriding types
   */
  Map<Element, Type2> captureOverrides(VariableDeclarationList variableList) {
    Map<Element, Type2> overrides = new Map<Element, Type2>();
    if (StaticTypeAnalyzer.USE_TYPE_PROPAGATION) {
      if (variableList.isConst() || variableList.isFinal()) {
        for (VariableDeclaration variable in variableList.variables) {
          Element element31 = variable.element;
          if (element31 != null) {
            Type2 type = _overrideManager.getType(element31);
            if (type != null) {
              overrides[element31] = type;
            }
          }
        }
      }
    }
    return overrides;
  }
  /**
   * Return {@code true} if the given expression terminates abruptly (that is, if any expression
   * following the given expression will not be reached).
   * @param expression the expression being tested
   * @return {@code true} if the given expression terminates abruptly
   */
  bool isAbruptTermination(Expression expression18) {
    while (expression18 is ParenthesizedExpression) {
      expression18 = ((expression18 as ParenthesizedExpression)).expression;
    }
    return expression18 is ThrowExpression || expression18 is RethrowExpression;
  }
  /**
   * Return {@code true} if the given statement terminates abruptly (that is, if any statement
   * following the given statement will not be reached).
   * @param statement the statement being tested
   * @return {@code true} if the given statement terminates abruptly
   */
  bool isAbruptTermination2(Statement statement) {
    if (statement is ReturnStatement) {
      return true;
    } else if (statement is ExpressionStatement) {
      return isAbruptTermination(((statement as ExpressionStatement)).expression);
    } else if (statement is Block) {
      NodeList<Statement> statements2 = ((statement as Block)).statements;
      int size6 = statements2.length;
      if (size6 == 0) {
        return false;
      }
      return isAbruptTermination2(statements2[size6 - 1]);
    }
    return false;
  }
  /**
   * Propagate any type information that results from knowing that the given condition will have
   * evaluated to 'false'.
   * @param condition the condition that will have evaluated to 'false'
   */
  void propagateFalseState(Expression condition) {
    while (condition is ParenthesizedExpression) {
      condition = ((condition as ParenthesizedExpression)).expression;
    }
    if (condition is IsExpression) {
      IsExpression is2 = condition as IsExpression;
      if (is2.notOperator != null) {
        Element element = getOverridableElement(is2.expression);
        if (element != null) {
          Type2 type17 = is2.type.type;
          if (type17 != null) {
            _overrideManager.setType(element, type17);
          }
        }
      }
    } else if (condition is BinaryExpression) {
      BinaryExpression binary = condition as BinaryExpression;
      if (identical(binary.operator.type, sc.TokenType.BAR_BAR)) {
        propagateFalseState(binary.leftOperand);
        propagateFalseState(binary.rightOperand);
      }
    }
  }
  /**
   * Propagate any type information that results from knowing that the given condition will have
   * evaluated to 'true'.
   * @param condition the condition that will have evaluated to 'true'
   */
  void propagateTrueState(Expression condition) {
    while (condition is ParenthesizedExpression) {
      condition = ((condition as ParenthesizedExpression)).expression;
    }
    if (condition is IsExpression) {
      IsExpression is3 = condition as IsExpression;
      if (is3.notOperator == null) {
        Element element = getOverridableElement(is3.expression);
        if (element != null) {
          Type2 type18 = is3.type.type;
          if (type18 != null) {
            _overrideManager.setType(element, type18);
          }
        }
      }
    } else if (condition is BinaryExpression) {
      BinaryExpression binary = condition as BinaryExpression;
      if (identical(binary.operator.type, sc.TokenType.AMPERSAND_AMPERSAND)) {
        propagateTrueState(binary.leftOperand);
        propagateTrueState(binary.rightOperand);
      }
    }
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
  ScopedVisitor.con1(Library library, Source source8, TypeProvider typeProvider2) {
    _jtd_constructor_267_impl(library, source8, typeProvider2);
  }
  _jtd_constructor_267_impl(Library library, Source source8, TypeProvider typeProvider2) {
    this._definingLibrary = library.libraryElement;
    this._source = source8;
    LibraryScope libraryScope2 = library.libraryScope;
    this._errorListener = libraryScope2.errorListener;
    this._nameScope = libraryScope2;
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
  ScopedVisitor.con2(LibraryElement definingLibrary2, Source source9, TypeProvider typeProvider3, AnalysisErrorListener errorListener2) {
    _jtd_constructor_268_impl(definingLibrary2, source9, typeProvider3, errorListener2);
  }
  _jtd_constructor_268_impl(LibraryElement definingLibrary2, Source source9, TypeProvider typeProvider3, AnalysisErrorListener errorListener2) {
    this._definingLibrary = definingLibrary2;
    this._source = source9;
    this._errorListener = errorListener2;
    this._nameScope = new LibraryScope(definingLibrary2, errorListener2);
    this._typeProvider = typeProvider3;
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
    VariableElement element32 = node.element;
    if (element32 != null) {
      _nameScope.define(element32);
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
      super.visitForEachStatement(node);
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
      super.visitForStatement(node);
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
    LabelScope outerLabelScope = addScopesFor(node.labels);
    Scope outerNameScope = _nameScope;
    _nameScope = new EnclosedScope(_nameScope);
    try {
      node.statements.accept(this);
    } finally {
      _nameScope = outerNameScope;
      _labelScope = outerLabelScope;
    }
    return null;
  }
  Object visitSwitchDefault(SwitchDefault node) {
    LabelScope outerLabelScope = addScopesFor(node.labels);
    Scope outerNameScope = _nameScope;
    _nameScope = new EnclosedScope(_nameScope);
    try {
      node.statements.accept(this);
    } finally {
      _nameScope = outerNameScope;
      _labelScope = outerLabelScope;
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
        _labelScope = new LabelScope.con2(outerScope, labelName.name, labelElement);
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
      VariableElement element33 = node.element;
      if (element33 != null) {
        _nameScope.define(element33);
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
    _errorListener.onError(new AnalysisError.con2(_source, node.offset, node.length, errorCode, [arguments]));
  }
  /**
   * Report an error with the given error code and arguments.
   * @param errorCode the error code of the error to be reported
   * @param token the token specifying the location of the error
   * @param arguments the arguments to the error, used to compose the error message
   */
  void reportError3(ErrorCode errorCode, sc.Token token, List<Object> arguments) {
    _errorListener.onError(new AnalysisError.con2(_source, token.offset, token.length, errorCode, [arguments]));
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
   * A flag indicating whether type propagation should be enabled.
   */
  static bool USE_TYPE_PROPAGATION = true;
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
  Object visitAdjacentStrings(AdjacentStrings node) => recordType(node, _typeProvider.stringType);
  /**
   * The Dart Language Specification, 12.33: <blockquote>The static type of an argument definition
   * test is {@code bool}.</blockquote>
   */
  Object visitArgumentDefinitionTest(ArgumentDefinitionTest node) => recordType(node, _typeProvider.boolType);
  /**
   * The Dart Language Specification, 12.32: <blockquote>... the cast expression <i>e as T</i> ...
   * <p>
   * It is a static warning if <i>T</i> does not denote a type available in the current lexical
   * scope.
   * <p>
   * The static type of a cast expression <i>e as T</i> is <i>T</i>.</blockquote>
   */
  Object visitAsExpression(AsExpression node) => recordType(node, getType4(node.type));
  /**
   * The Dart Language Specification, 12.18: <blockquote> ... an assignment <i>a</i> of the form
   * <i>v = e</i> ...
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
   * ... an assignment of the form <i>e<sub>1</sub>[e<sub>2</sub>] = e<sub>3</sub></i> ...
   * <p>
   * The static type of the expression <i>e<sub>1</sub>[e<sub>2</sub>] = e<sub>3</sub></i> is the
   * static type of <i>e<sub>3</sub></i>.
   * <p>
   * A compound assignment of the form <i>v op= e</i> is equivalent to <i>v = v op e</i>. A compound
   * assignment of the form <i>C.v op= e</i> is equivalent to <i>C.v = C.v op e</i>. A compound
   * assignment of the form <i>e<sub>1</sub>.v op= e<sub>2</sub></i> is equivalent to <i>((x) => x.v
   * = x.v op e<sub>2</sub>)(e<sub>1</sub>)</i> where <i>x</i> is a variable that is not used in
   * <i>e<sub>2</sub></i>. A compound assignment of the form <i>e<sub>1</sub>[e<sub>2</sub>] op=
   * e<sub>3</sub></i> is equivalent to <i>((a, i) => a[i] = a[i] op e<sub>3</sub>)(e<sub>1</sub>,
   * e<sub>2</sub>)</i> where <i>a</i> and <i>i</i> are a variables that are not used in
   * <i>e<sub>3</sub></i>. </blockquote>
   */
  Object visitAssignmentExpression(AssignmentExpression node) {
    sc.TokenType operator11 = node.operator.type;
    if (operator11 != sc.TokenType.EQ) {
      return recordReturnType(node, node.element);
    }
    Type2 rightType = getType2(node.rightHandSide);
    if (USE_TYPE_PROPAGATION) {
      VariableElement element = _resolver.getOverridableElement(node.leftHandSide);
      if (element != null) {
        override(element, getType(element), rightType);
      }
    }
    return recordType(node, rightType);
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
    sc.TokenType operator12 = node.operator.type;
    while (true) {
      if (operator12 == sc.TokenType.AMPERSAND_AMPERSAND || operator12 == sc.TokenType.BAR_BAR || operator12 == sc.TokenType.EQ_EQ || operator12 == sc.TokenType.BANG_EQ) {
        return recordType(node, _typeProvider.boolType);
      } else if (operator12 == sc.TokenType.MINUS || operator12 == sc.TokenType.PERCENT || operator12 == sc.TokenType.PLUS || operator12 == sc.TokenType.STAR || operator12 == sc.TokenType.TILDE_SLASH) {
        Type2 intType2 = _typeProvider.intType;
        if (identical(getType2(node.leftOperand), intType2) && identical(getType2(node.rightOperand), intType2)) {
          return recordType(node, intType2);
        }
      } else if (operator12 == sc.TokenType.SLASH) {
        Type2 doubleType2 = _typeProvider.doubleType;
        if (identical(getType2(node.leftOperand), doubleType2) || identical(getType2(node.rightOperand), doubleType2)) {
          return recordType(node, doubleType2);
        }
      }
      break;
    }
    return recordReturnType(node, node.element);
  }
  /**
   * The Dart Language Specification, 12.4: <blockquote>The static type of a boolean literal is{@code bool}.</blockquote>
   */
  Object visitBooleanLiteral(BooleanLiteral node) => recordType(node, _typeProvider.boolType);
  /**
   * The Dart Language Specification, 12.15.2: <blockquote>A cascaded method invocation expression
   * of the form <i>e..suffix</i> is equivalent to the expression <i>(t) {t.suffix; return
   * t;}(e)</i>.</blockquote>
   */
  Object visitCascadeExpression(CascadeExpression node) => recordType(node, getType2(node.target));
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
    Type2 thenType = getType2(node.thenExpression);
    Type2 elseType = getType2(node.elseExpression);
    if (thenType == null) {
      return recordType(node, _dynamicType);
    }
    Type2 resultType = thenType.getLeastUpperBound(elseType);
    return recordType(node, resultType);
  }
  /**
   * The Dart Language Specification, 12.3: <blockquote>The static type of a literal double is{@code double}.</blockquote>
   */
  Object visitDoubleLiteral(DoubleLiteral node) => recordType(node, _typeProvider.doubleType);
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    FunctionExpression function = node.functionExpression;
    FunctionTypeImpl functionType = node.element.type as FunctionTypeImpl;
    setTypeInformation(functionType, computeReturnType(node), function.parameters);
    return recordType(function, functionType);
  }
  /**
   * The Dart Language Specification, 12.9: <blockquote>The static type of a function literal of the
   * form <i>(T<sub>1</sub> a<sub>1</sub>, &hellip;, T<sub>n</sub> a<sub>n</sub>, [T<sub>n+1</sub>
   * x<sub>n+1</sub> = d1, &hellip;, T<sub>n+k</sub> x<sub>n+k</sub> = dk]) => e</i> is
   * <i>(T<sub>1</sub>, &hellip;, Tn, [T<sub>n+1</sub> x<sub>n+1</sub>, &hellip;, T<sub>n+k</sub>
   * x<sub>n+k</sub>]) &rarr; T<sub>0</sub></i>, where <i>T<sub>0</sub></i> is the static type of
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
   * T<sub>n</sub> a<sub>n</sub>, [T<sub>n+1</sub> x<sub>n+1</sub> = d1, &hellip;, T<sub>n+k</sub>
   * x<sub>n+k</sub> = dk]) {s}</i> is <i>(T<sub>1</sub>, &hellip;, T<sub>n</sub>, [T<sub>n+1</sub>
   * x<sub>n+1</sub>, &hellip;, T<sub>n+k</sub> x<sub>n+k</sub>]) &rarr; dynamic</i>. In any case
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
    setTypeInformation(functionType, computeReturnType2(node), node.parameters);
    return recordType(node, functionType);
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
  Object visitFunctionExpressionInvocation(FunctionExpressionInvocation node) => recordReturnType(node, node.element);
  /**
   * The Dart Language Specification, 12.29: <blockquote>An assignable expression of the form
   * <i>e<sub>1</sub>[e<sub>2</sub>]</i> is evaluated as a method invocation of the operator method
   * <i>[]</i> on <i>e<sub>1</sub></i> with argument <i>e<sub>2</sub></i>.</blockquote>
   */
  Object visitIndexExpression(IndexExpression node) {
    if (node.inSetterContext()) {
      return recordArgumentType(node, node.element);
    }
    return recordReturnType(node, node.element);
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
    if (USE_TYPE_PROPAGATION) {
      ConstructorElement element34 = node.element;
      if (element34 != null && "Element" == element34.enclosingElement.name && "tag" == element34.name) {
        LibraryElement library33 = element34.library;
        if (isHtmlLibrary(library33)) {
          Type2 returnType = getFirstArgumentAsType2(library33, node.argumentList, _HTML_ELEMENT_TO_CLASS_MAP);
          if (returnType != null) {
            return recordType(node, returnType);
          }
        }
      }
    }
    return recordType(node, node.constructorName.type.type);
  }
  /**
   * The Dart Language Specification, 12.3: <blockquote>The static type of an integer literal is{@code int}.</blockquote>
   */
  Object visitIntegerLiteral(IntegerLiteral node) => recordType(node, _typeProvider.intType);
  /**
   * The Dart Language Specification, 12.31: <blockquote>It is a static warning if <i>T</i> does not
   * denote a type available in the current lexical scope.
   * <p>
   * The static type of an is-expression is {@code bool}.</blockquote>
   */
  Object visitIsExpression(IsExpression node) => recordType(node, _typeProvider.boolType);
  /**
   * The Dart Language Specification, 12.6: <blockquote>The static type of a list literal of the
   * form <i><b>const</b> &lt;E&gt;[e<sub>1</sub>, &hellip;, e<sub>n</sub>]</i> or the form
   * <i>&lt;E&gt;[e<sub>1</sub>, &hellip;, e<sub>n</sub>]</i> is {@code List&lt;E&gt;}. The static
   * type a list literal of the form <i><b>const</b> [e<sub>1</sub>, &hellip;, e<sub>n</sub>]</i> or
   * the form <i>[e<sub>1</sub>, &hellip;, e<sub>n</sub>]</i> is {@code List&lt;dynamic&gt;}.</blockquote>
   */
  Object visitListLiteral(ListLiteral node) {
    TypeArgumentList typeArguments8 = node.typeArguments;
    if (typeArguments8 != null) {
      NodeList<TypeName> arguments4 = typeArguments8.arguments;
      if (arguments4 != null && arguments4.length == 1) {
        TypeName argumentType = arguments4[0];
        return recordType(node, _typeProvider.listType.substitute5(<Type2> [getType4(argumentType)]));
      }
    }
    return recordType(node, _typeProvider.listType.substitute5(<Type2> [_dynamicType]));
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
    TypeArgumentList typeArguments9 = node.typeArguments;
    if (typeArguments9 != null) {
      NodeList<TypeName> arguments5 = typeArguments9.arguments;
      if (arguments5 != null && arguments5.length == 2) {
        TypeName keyType = arguments5[0];
        if (keyType != _typeProvider.stringType) {
        }
        TypeName valueType = arguments5[1];
        return recordType(node, _typeProvider.mapType.substitute5(<Type2> [_typeProvider.stringType, getType4(valueType)]));
      }
    }
    return recordType(node, _typeProvider.mapType.substitute5(<Type2> [_typeProvider.stringType, _dynamicType]));
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
    if (USE_TYPE_PROPAGATION) {
      String methodName3 = node.methodName.name;
      if (methodName3 == "\$dom_createEvent") {
        Expression target = node.realTarget;
        if (target != null) {
          Type2 targetType = getType2(target);
          if (targetType is InterfaceType && (targetType.name == "HtmlDocument" || targetType.name == "Document")) {
            LibraryElement library34 = targetType.element.library;
            if (isHtmlLibrary(library34)) {
              Type2 returnType = getFirstArgumentAsType(library34, node.argumentList);
              if (returnType != null) {
                return recordType(node, returnType);
              }
            }
          }
        }
      } else if (methodName3 == "query") {
        Expression target = node.realTarget;
        if (target == null) {
          Element methodElement = node.methodName.element;
          if (methodElement != null) {
            LibraryElement library35 = methodElement.library;
            if (isHtmlLibrary(library35)) {
              Type2 returnType = getFirstArgumentAsQuery(library35, node.argumentList);
              if (returnType != null) {
                return recordType(node, returnType);
              }
            }
          }
        } else {
          Type2 targetType = getType2(target);
          if (targetType is InterfaceType && (targetType.name == "HtmlDocument" || targetType.name == "Document")) {
            LibraryElement library36 = targetType.element.library;
            if (isHtmlLibrary(library36)) {
              Type2 returnType = getFirstArgumentAsQuery(library36, node.argumentList);
              if (returnType != null) {
                return recordType(node, returnType);
              }
            }
          }
        }
      } else if (methodName3 == "JS") {
        Type2 returnType = getFirstArgumentAsType(_typeProvider.objectType.element.library, node.argumentList);
        if (returnType != null) {
          return recordType(node, returnType);
        }
      }
    }
    return recordReturnType(node, node.methodName.element);
  }
  Object visitNamedExpression(NamedExpression node) => recordType(node, getType2(node.expression));
  /**
   * The Dart Language Specification, 12.2: <blockquote>The static type of {@code null} is bottom.
   * </blockquote>
   */
  Object visitNullLiteral(NullLiteral node) => recordType(node, _typeProvider.bottomType);
  Object visitParenthesizedExpression(ParenthesizedExpression node) => recordType(node, getType2(node.expression));
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
   * A postfix expression of the form <i>e1[e2]++</i> is equivalent to <i>(a, i){var r = a[i]; a[i]
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
   * A postfix expression of the form <i>e1[e2]--</i> is equivalent to <i>(a, i){var r = a[i]; a[i]
   * = r - 1; return r}(e1, e2)</i></blockquote>
   */
  Object visitPostfixExpression(PostfixExpression node) => recordType(node, getType2(node.operand));
  /**
   * See {@link #visitSimpleIdentifier(SimpleIdentifier)}.
   */
  Object visitPrefixedIdentifier(PrefixedIdentifier node) {
    SimpleIdentifier prefixedIdentifier = node.identifier;
    Element element35 = prefixedIdentifier.element;
    if (element35 == null) {
      return recordType(node, _dynamicType);
    }
    if (USE_TYPE_PROPAGATION) {
      Type2 type = _overrideManager.getType(element35);
      if (type != null) {
        return recordType(node, type);
      }
    }
    Type2 type;
    if (element35 is ClassElement) {
      if (isNotTypeLiteral(node)) {
        type = ((element35 as ClassElement)).type;
      } else {
        type = _typeProvider.typeType;
      }
    } else if (element35 is FunctionTypeAliasElement) {
      type = ((element35 as FunctionTypeAliasElement)).type;
    } else if (element35 is MethodElement) {
      type = ((element35 as MethodElement)).type;
    } else if (element35 is PropertyAccessorElement) {
      type = getType3((element35 as PropertyAccessorElement), node.prefix.staticType);
    } else if (element35 is ExecutableElement) {
      type = ((element35 as ExecutableElement)).type;
    } else if (element35 is TypeVariableElement) {
      type = ((element35 as TypeVariableElement)).type;
    } else if (element35 is VariableElement) {
      type = ((element35 as VariableElement)).type;
    } else {
      type = _dynamicType;
    }
    recordType(prefixedIdentifier, type);
    return recordType(node, type);
  }
  /**
   * The Dart Language Specification, 12.27: <blockquote>A unary expression <i>u</i> of the form
   * <i>op e</i> is equivalent to a method invocation <i>expression e.op()</i>. An expression of the
   * form <i>op super</i> is equivalent to the method invocation <i>super.op()<i>.</blockquote>
   */
  Object visitPrefixExpression(PrefixExpression node) {
    sc.TokenType operator13 = node.operator.type;
    if (identical(operator13, sc.TokenType.BANG)) {
      return recordType(node, _typeProvider.boolType);
    }
    return recordReturnType(node, node.element);
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
   * <li><i>(r<sub>1</sub>, &hellip;, r<sub>n</sub>, [p<sub>1</sub> = d<sub>1</sub>, &hellip;,
   * p<sub>k</sub> = d<sub>k</sub>]){return o.m(r<sub>1</sub>, &hellip;, r<sub>n</sub>,
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
    SimpleIdentifier propertyName2 = node.propertyName;
    Element element36 = propertyName2.element;
    if (USE_TYPE_PROPAGATION) {
      Type2 type = _overrideManager.getType(element36);
      if (type != null) {
        return recordType(node, type);
      }
    }
    if (element36 is MethodElement) {
      FunctionType type19 = ((element36 as MethodElement)).type;
      recordType(propertyName2, type19);
      return recordType(node, type19);
    } else if (element36 is PropertyAccessorElement) {
      Type2 propertyType = getType3((element36 as PropertyAccessorElement), node.target != null ? node.target.staticType : null);
      recordType(propertyName2, propertyType);
      return recordType(node, propertyType);
    } else {
    }
    recordType(propertyName2, _dynamicType);
    return recordType(node, _dynamicType);
  }
  /**
   * The Dart Language Specification, 12.9: <blockquote>The static type of a rethrow expression is
   * bottom.</blockquote>
   */
  Object visitRethrowExpression(RethrowExpression node) => recordType(node, _typeProvider.bottomType);
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
    Element element37 = node.element;
    if (element37 == null) {
      return recordType(node, _dynamicType);
    }
    if (USE_TYPE_PROPAGATION) {
      Type2 type = _overrideManager.getType(element37);
      if (type != null) {
        return recordType(node, type);
      }
    }
    Type2 type;
    if (element37 is ClassElement) {
      if (isNotTypeLiteral(node)) {
        type = ((element37 as ClassElement)).type;
      } else {
        type = _typeProvider.typeType;
      }
    } else if (element37 is FunctionTypeAliasElement) {
      type = ((element37 as FunctionTypeAliasElement)).type;
    } else if (element37 is MethodElement) {
      type = ((element37 as MethodElement)).type;
    } else if (element37 is PropertyAccessorElement) {
      type = getType3((element37 as PropertyAccessorElement), null);
    } else if (element37 is ExecutableElement) {
      type = ((element37 as ExecutableElement)).type;
    } else if (element37 is TypeVariableElement) {
      type = ((element37 as TypeVariableElement)).type;
    } else if (element37 is VariableElement) {
      type = ((element37 as VariableElement)).type;
    } else if (element37 is PrefixElement) {
      return null;
    } else {
      type = _dynamicType;
    }
    return recordType(node, type);
  }
  /**
   * The Dart Language Specification, 12.5: <blockquote>The static type of a string literal is{@code String}.</blockquote>
   */
  Object visitSimpleStringLiteral(SimpleStringLiteral node) => recordType(node, _typeProvider.stringType);
  /**
   * The Dart Language Specification, 12.5: <blockquote>The static type of a string literal is{@code String}.</blockquote>
   */
  Object visitStringInterpolation(StringInterpolation node) => recordType(node, _typeProvider.stringType);
  Object visitSuperExpression(SuperExpression node) {
    if (_thisType == null) {
      return recordType(node, _dynamicType);
    } else {
      return recordType(node, _thisType.superclass);
    }
  }
  /**
   * The Dart Language Specification, 12.10: <blockquote>The static type of {@code this} is the
   * interface of the immediately enclosing class.</blockquote>
   */
  Object visitThisExpression(ThisExpression node) {
    if (_thisType == null) {
      return recordType(node, _dynamicType);
    } else {
      return recordType(node, _thisType);
    }
  }
  /**
   * The Dart Language Specification, 12.8: <blockquote>The static type of a throw expression is
   * bottom.</blockquote>
   */
  Object visitThrowExpression(ThrowExpression node) => recordType(node, _typeProvider.bottomType);
  Object visitVariableDeclaration(VariableDeclaration node) {
    if (USE_TYPE_PROPAGATION) {
      Expression initializer6 = node.initializer;
      if (initializer6 != null) {
        Type2 rightType = getType2(initializer6);
        VariableElement element38 = node.name.element as VariableElement;
        if (element38 != null) {
          override(element38, getType(element38), rightType);
        }
      }
    }
    return null;
  }
  /**
   * Given a function declaration, compute the return type of the function. The return type of
   * functions with a block body is {@code dynamicType}, with an expression body it is the type of
   * the expression.
   * @param node the function expression whose return type is to be computed
   * @return the return type that was computed
   */
  Type2 computeReturnType(FunctionDeclaration node) {
    TypeName returnType9 = node.returnType;
    if (returnType9 == null) {
      return computeReturnType2(node.functionExpression);
    }
    return returnType9.type;
  }
  /**
   * Given a function expression, compute the return type of the function. The return type of
   * functions with a block body is {@code dynamicType}, with an expression body it is the type of
   * the expression.
   * @param node the function expression whose return type is to be computed
   * @return the return type that was computed
   */
  Type2 computeReturnType2(FunctionExpression node) {
    FunctionBody body4 = node.body;
    if (body4 is ExpressionFunctionBody) {
      return getType2(((body4 as ExpressionFunctionBody)).expression);
    }
    return _dynamicType;
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
    NodeList<Expression> arguments6 = argumentList.arguments;
    if (arguments6.length > 0) {
      Expression argument = arguments6[0];
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
  Type2 getType(Element element) {
    if (element is LocalVariableElement) {
      return ((element as LocalVariableElement)).type;
    } else if (element is ParameterElement) {
      return ((element as ParameterElement)).type;
    }
    return null;
  }
  /**
   * Return the type of the given expression that is to be used for type analysis.
   * @param expression the expression whose type is to be returned
   * @return the type of the given expression
   */
  Type2 getType2(Expression expression) {
    Type2 type = expression.staticType;
    if (type == null) {
      return _dynamicType;
    }
    return type;
  }
  /**
   * Return the type that should be recorded for a node that resolved to the given accessor.
   * @param accessor the accessor that the node resolved to
   * @param context if the accessor element has context [by being the RHS of a{@link PrefixedIdentifier} or {@link PropertyAccess}], and the return type of the
   * accessor is a parameter type, then the type of the LHS can be used to get more
   * specific type information
   * @return the type that should be recorded for a node that resolved to the given accessor
   */
  Type2 getType3(PropertyAccessorElement accessor, Type2 context) {
    FunctionType functionType = accessor.type;
    if (functionType == null) {
      return _dynamicType;
    }
    if (accessor.isSetter()) {
      List<Type2> parameterTypes = functionType.normalParameterTypes;
      if (parameterTypes != null && parameterTypes.length > 0) {
        return parameterTypes[0];
      }
      PropertyAccessorElement getter4 = accessor.variable.getter;
      if (getter4 != null) {
        functionType = getter4.type;
        if (functionType != null) {
          return functionType.returnType;
        }
      }
      return _dynamicType;
    }
    Type2 returnType10 = functionType.returnType;
    if (returnType10 is TypeVariableType && context is InterfaceType) {
      InterfaceType interfaceTypeContext = (context as InterfaceType);
      List<TypeVariableElement> parameterElements = interfaceTypeContext.element != null ? interfaceTypeContext.element.typeVariables : null;
      if (parameterElements != null) {
        for (int i = 0; i < parameterElements.length; i++) {
          TypeVariableElement varElt = parameterElements[i];
          if (returnType10.name == varElt.name) {
            return interfaceTypeContext.typeArguments[i];
          }
        }
      }
    }
    return returnType10;
  }
  /**
   * Return the type represented by the given type name.
   * @param typeName the type name representing the type to be returned
   * @return the type represented by the type name
   */
  Type2 getType4(TypeName typeName) {
    Type2 type20 = typeName.type;
    if (type20 == null) {
      return _dynamicType;
    }
    return type20;
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
    ASTNode parent15 = node.parent;
    return parent15 is TypeName || (parent15 is PrefixedIdentifier && (parent15.parent is TypeName || identical(((parent15 as PrefixedIdentifier)).prefix, node))) || (parent15 is PropertyAccess && identical(((parent15 as PropertyAccess)).target, node)) || (parent15 is MethodInvocation && identical(node, ((parent15 as MethodInvocation)).target));
  }
  /**
   * If it is appropriate to do so, override the type of the given element. Use the static type and
   * inferred type of the element to determine whether or not it is appropriate.
   * @param element the element whose type might be overridden
   * @param staticType the static type of the element
   * @param inferredType the inferred type of the element
   */
  void override(VariableElement element, Type2 staticType, Type2 inferredType) {
    if (identical(inferredType, BottomTypeImpl.instance) || element is! VariableElement) {
      return;
    }
    if (element is PropertyInducingElement) {
      PropertyInducingElement variable = element as PropertyInducingElement;
      if (!variable.isConst() && !variable.isFinal()) {
        return;
      }
    }
    if (staticType == null || (inferredType != null && inferredType.isMoreSpecificThan(staticType))) {
      _overrideManager.setType(element, inferredType);
    }
  }
  /**
   * Record that the static type of the given node is the type of the second argument to the method
   * represented by the given element.
   * @param expression the node whose type is to be recorded
   * @param element the element representing the method invoked by the given node
   */
  Object recordArgumentType(IndexExpression expression, MethodElement element) {
    if (element != null) {
      List<ParameterElement> parameters14 = element.parameters;
      if (parameters14 != null && parameters14.length == 2) {
        return recordType(expression, parameters14[1].type);
      }
    }
    return recordType(expression, _dynamicType);
  }
  /**
   * Record that the static type of the given node is the return type of the method or function
   * represented by the given element.
   * @param expression the node whose type is to be recorded
   * @param element the element representing the method or function invoked by the given node
   */
  Object recordReturnType(Expression expression, Element element) {
    if (element is PropertyAccessorElement) {
      FunctionType propertyType = ((element as PropertyAccessorElement)).type;
      if (propertyType != null) {
        Type2 returnType11 = propertyType.returnType;
        if (returnType11 is FunctionType) {
          Type2 innerReturnType = ((returnType11 as FunctionType)).returnType;
          if (innerReturnType != null) {
            return recordType(expression, innerReturnType);
          }
        } else if (returnType11.isDartCoreFunction()) {
          return recordType(expression, _dynamicType);
        }
        if (returnType11 != null) {
          return recordType(expression, returnType11);
        }
      }
    } else if (element is ExecutableElement) {
      FunctionType type21 = ((element as ExecutableElement)).type;
      if (type21 != null) {
        return recordType(expression, type21.returnType);
      }
    } else if (element is VariableElement) {
      Type2 variableType = ((element as VariableElement)).type;
      if (variableType is FunctionType) {
        return recordType(expression, ((variableType as FunctionType)).returnType);
      }
    }
    return recordType(expression, _dynamicType);
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
   * Set the return type and parameter type information for the given function type based on the
   * given return type and parameter elements.
   * @param functionType the function type to be filled in
   * @param returnType the return type of the function, or {@code null} if no type was declared
   * @param parameters the elements representing the parameters to the function
   */
  void setTypeInformation(FunctionTypeImpl functionType, Type2 returnType14, FormalParameterList parameterList) {
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
    functionType.returnType = returnType14;
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
   * Initialize a newly created override manager to not be in any scope.
   */
  TypeOverrideManager() : super() {
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
   * Initialize a newly created visitor to resolve the nodes in a compilation unit.
   * @param library the library containing the compilation unit being resolved
   * @param source the source representing the compilation unit being visited
   * @param typeProvider the object used to access the types from the core library
   */
  TypeResolverVisitor.con1(Library library, Source source, TypeProvider typeProvider) : super.con1(library, source, typeProvider) {
    _jtd_constructor_273_impl(library, source, typeProvider);
  }
  _jtd_constructor_273_impl(Library library, Source source, TypeProvider typeProvider) {
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
    _jtd_constructor_274_impl(definingLibrary, source, typeProvider, errorListener);
  }
  _jtd_constructor_274_impl(LibraryElement definingLibrary, Source source, TypeProvider typeProvider, AnalysisErrorListener errorListener) {
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
        exceptionType = getType5(exceptionTypeName);
      }
      recordType(exception, exceptionType);
      Element element39 = exception.element;
      if (element39 is VariableElementImpl) {
        ((element39 as VariableElementImpl)).type = exceptionType;
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
    super.visitClassDeclaration(node);
    ClassElementImpl classElement = getClassElement(node.name);
    InterfaceType superclassType = null;
    ExtendsClause extendsClause4 = node.extendsClause;
    if (extendsClause4 != null) {
      superclassType = resolveType(extendsClause4.superclass, CompileTimeErrorCode.EXTENDS_NON_CLASS);
      if (superclassType != typeProvider.objectType) {
        classElement.validMixin = false;
      }
    }
    if (classElement != null) {
      if (superclassType == null) {
        InterfaceType objectType2 = typeProvider.objectType;
        if (classElement.type != objectType2) {
          superclassType = objectType2;
        }
      }
      classElement.supertype = superclassType;
    }
    resolve(classElement, node.withClause, node.implementsClause);
    return null;
  }
  Object visitClassTypeAlias(ClassTypeAlias node) {
    super.visitClassTypeAlias(node);
    ClassElementImpl classElement = getClassElement(node.name);
    InterfaceType superclassType = resolveType(node.superclass, CompileTimeErrorCode.EXTENDS_NON_CLASS);
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
    ExecutableElementImpl element40 = node.element as ExecutableElementImpl;
    FunctionTypeImpl type = new FunctionTypeImpl.con1(element40);
    setTypeInformation(type, null, element40.parameters);
    type.returnType = ((element40.enclosingElement as ClassElement)).type;
    element40.type = type;
    return null;
  }
  Object visitDeclaredIdentifier(DeclaredIdentifier node) {
    super.visitDeclaredIdentifier(node);
    Type2 declaredType;
    TypeName typeName = node.type;
    if (typeName == null) {
      declaredType = _dynamicType;
    } else {
      declaredType = getType5(typeName);
    }
    LocalVariableElementImpl element41 = node.element as LocalVariableElementImpl;
    element41.type = declaredType;
    return null;
  }
  Object visitDefaultFormalParameter(DefaultFormalParameter node) {
    super.visitDefaultFormalParameter(node);
    return null;
  }
  Object visitFieldFormalParameter(FieldFormalParameter node) {
    super.visitFieldFormalParameter(node);
    Element element42 = node.identifier.element;
    if (element42 is ParameterElementImpl) {
      ParameterElementImpl parameter = element42 as ParameterElementImpl;
      Type2 type;
      TypeName typeName = node.type;
      if (typeName == null) {
        type = _dynamicType;
      } else {
        type = getType5(typeName);
      }
      parameter.type = type;
    } else {
    }
    return null;
  }
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    super.visitFunctionDeclaration(node);
    ExecutableElementImpl element43 = node.element as ExecutableElementImpl;
    FunctionTypeImpl type = new FunctionTypeImpl.con1(element43);
    setTypeInformation(type, node.returnType, element43.parameters);
    element43.type = type;
    return null;
  }
  Object visitFunctionTypeAlias(FunctionTypeAlias node) {
    super.visitFunctionTypeAlias(node);
    FunctionTypeAliasElementImpl element44 = node.element as FunctionTypeAliasElementImpl;
    FunctionTypeImpl type22 = element44.type as FunctionTypeImpl;
    setTypeInformation(type22, node.returnType, element44.parameters);
    return null;
  }
  Object visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    super.visitFunctionTypedFormalParameter(node);
    ParameterElementImpl element45 = node.identifier.element as ParameterElementImpl;
    FunctionTypeImpl type = new FunctionTypeImpl.con1((null as ExecutableElement));
    setTypeInformation(type, node.returnType, getElements(node.parameters));
    element45.type = type;
    return null;
  }
  Object visitMethodDeclaration(MethodDeclaration node) {
    super.visitMethodDeclaration(node);
    ExecutableElementImpl element46 = node.element as ExecutableElementImpl;
    FunctionTypeImpl type = new FunctionTypeImpl.con1(element46);
    setTypeInformation(type, node.returnType, element46.parameters);
    element46.type = type;
    if (element46 is PropertyAccessorElement) {
      PropertyAccessorElement accessor = element46 as PropertyAccessorElement;
      PropertyInducingElementImpl variable6 = accessor.variable as PropertyInducingElementImpl;
      if (accessor.isGetter()) {
        variable6.type = type.returnType;
      } else if (variable6.type == null) {
        List<Type2> parameterTypes = type.normalParameterTypes;
        if (parameterTypes != null && parameterTypes.length > 0) {
          variable6.type = parameterTypes[0];
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
      declaredType = getType5(typeName);
    }
    Element element47 = node.identifier.element;
    if (element47 is ParameterElement) {
      ((element47 as ParameterElementImpl)).type = declaredType;
    } else {
    }
    return null;
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
      ASTNode parent16 = node.parent;
      if (typeName is PrefixedIdentifier && parent16 is ConstructorName && argumentList == null) {
        ConstructorName name = parent16 as ConstructorName;
        if (name.name == null) {
          SimpleIdentifier prefix7 = ((typeName as PrefixedIdentifier)).prefix;
          element = nameScope.lookup(prefix7, definingLibrary);
          if (element is PrefixElement) {
            return null;
          } else if (element != null) {
            name.name = ((typeName as PrefixedIdentifier)).identifier;
            name.period = ((typeName as PrefixedIdentifier)).period;
            node.name = prefix7;
            typeName = prefix7;
          }
        }
      }
    }
    if (element == null) {
      Identifier simpleIdentifier;
      if (typeName is SimpleIdentifier) {
        simpleIdentifier = typeName;
      } else {
        simpleIdentifier = ((typeName as PrefixedIdentifier)).prefix;
      }
      reportError(StaticWarningCode.UNDEFINED_CLASS, simpleIdentifier, [simpleIdentifier.name]);
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
      setElement(typeName, _dynamicType.element);
      typeName.staticType = _dynamicType;
      node.type = _dynamicType;
      return null;
    }
    if (argumentList != null) {
      NodeList<TypeName> arguments7 = argumentList.arguments;
      int argumentCount = arguments7.length;
      List<Type2> parameters = getTypeArguments(type);
      int parameterCount = parameters.length;
      int count = Math.min(argumentCount, parameterCount);
      List<Type2> typeArguments = new List<Type2>();
      for (int i = 0; i < count; i++) {
        Type2 argumentType = getType5(arguments7[i]);
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
      declaredType = getType5(typeName);
    }
    Element element48 = node.name.element;
    if (element48 is VariableElement) {
      ((element48 as VariableElementImpl)).type = declaredType;
      if (element48 is PropertyInducingElement) {
        PropertyInducingElement variableElement = element48 as PropertyInducingElement;
        PropertyAccessorElementImpl getter5 = variableElement.getter as PropertyAccessorElementImpl;
        FunctionTypeImpl getterType = new FunctionTypeImpl.con1(getter5);
        getterType.returnType = declaredType;
        getter5.type = getterType;
        PropertyAccessorElementImpl setter4 = variableElement.setter as PropertyAccessorElementImpl;
        if (setter4 != null) {
          FunctionTypeImpl setterType = new FunctionTypeImpl.con1(setter4);
          setterType.returnType = VoidTypeImpl.instance;
          setterType.normalParameterTypes = <Type2> [declaredType];
          setter4.type = setterType;
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
    Element element49 = identifier.element;
    if (element49 is! ClassElementImpl) {
      return null;
    }
    return element49 as ClassElementImpl;
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
      ParameterElement element50 = parameter.identifier.element as ParameterElement;
      if (element50 != null) {
        elements.add(element50);
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
    ASTNode parent17 = node.parent;
    if (parent17 is ConstructorName) {
      parent17 = parent17.parent;
      if (parent17 is InstanceCreationExpression) {
        if (((parent17 as InstanceCreationExpression)).isConst()) {
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
  Type2 getType5(TypeName typeName) {
    Type2 type23 = typeName.type;
    if (type23 == null) {
      return _dynamicType;
    }
    return type23;
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
      List<InterfaceType> mixinTypes2 = resolveTypes(withClause.mixinTypes, CompileTimeErrorCode.MIXIN_OF_NON_CLASS);
      if (classElement != null) {
        classElement.mixins = mixinTypes2;
      }
    }
    if (implementsClause != null) {
      NodeList<TypeName> interfaces3 = implementsClause.interfaces;
      List<InterfaceType> interfaceTypes = resolveTypes(interfaces3, CompileTimeErrorCode.IMPLEMENTS_NON_CLASS);
      List<TypeName> typeNames = new List.from(interfaces3);
      String dynamicKeyword = sc.Keyword.DYNAMIC.syntax;
      List<bool> detectedRepeatOnIndex = new List<bool>.filled(typeNames.length, false);
      for (int i = 0; i < detectedRepeatOnIndex.length; i++) {
        detectedRepeatOnIndex[i] = false;
      }
      for (int i = 0; i < typeNames.length; i++) {
        TypeName typeName = typeNames[i];
        String name19 = typeName.name.name;
        if (name19 == dynamicKeyword) {
          reportError(CompileTimeErrorCode.IMPLEMENTS_DYNAMIC, typeName, []);
        } else {
          Element element51 = typeName.name.element;
          if (element51 != null && element51 == classElement) {
            reportError(CompileTimeErrorCode.IMPLEMENTS_SELF, typeName, [name19]);
          }
        }
        if (!detectedRepeatOnIndex[i]) {
          for (int j = i + 1; j < typeNames.length; j++) {
            Element element52 = typeName.name.element;
            TypeName typeName2 = typeNames[j];
            Identifier identifier2 = typeName2.name;
            String name2 = identifier2.name;
            Element element2 = identifier2.element;
            if (element52 != null && element52 == element2) {
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
    Type2 type24 = typeName.type;
    if (type24 is InterfaceType) {
      return type24 as InterfaceType;
    }
    Identifier name20 = typeName.name;
    if (name20.name != sc.Keyword.DYNAMIC.syntax) {
      reportError(nonTypeError, name20, [name20.name]);
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
  void setElement(Identifier typeName, Element element69) {
    if (element69 != null) {
      if (typeName is SimpleIdentifier) {
        ((typeName as SimpleIdentifier)).element = element69;
      } else if (typeName is PrefixedIdentifier) {
        PrefixedIdentifier identifier = typeName as PrefixedIdentifier;
        identifier.identifier.element = element69;
        SimpleIdentifier prefix8 = identifier.prefix;
        Element prefixElement = nameScope.lookup(prefix8, definingLibrary);
        if (prefixElement != null) {
          prefix8.element = prefixElement;
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
  void setTypeInformation(FunctionTypeImpl functionType, TypeName returnType15, List<ParameterElement> parameters) {
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
    if (returnType15 == null) {
      functionType.returnType = _dynamicType;
    } else {
      functionType.returnType = returnType15.type;
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
  Element lookup3(String name, LibraryElement referencingLibrary) {
    Element element = localLookup(name, referencingLibrary);
    if (element != null) {
      return element;
    }
    return _enclosingScope.lookup3(name, referencingLibrary);
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
      String name21 = functionElement.name;
      if (name21 != null && !name21.isEmpty) {
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
    defineTypeParameters(typeElement);
  }
  /**
   * Define the type parameters for the function type alias.
   * @param typeElement the element representing the type represented by this scope
   */
  void defineTypeParameters(FunctionTypeAliasElement typeElement) {
    Scope parameterScope = enclosingScope;
    for (TypeVariableElement parameter in typeElement.typeVariables) {
      parameterScope.define(parameter);
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
    _jtd_constructor_279_impl(outerScope, onSwitchStatement, onSwitchMember);
  }
  _jtd_constructor_279_impl(LabelScope outerScope, bool onSwitchStatement, bool onSwitchMember) {
    _jtd_constructor_280_impl(outerScope, EMPTY_LABEL, new LabelElementImpl(_EMPTY_LABEL_IDENTIFIER, onSwitchStatement, onSwitchMember));
  }
  /**
   * Initialize a newly created scope to represent the given label.
   * @param outerScope the label scope enclosing the new label scope
   * @param label the label defined in this scope
   * @param element the element to which the label resolves
   */
  LabelScope.con2(LabelScope outerScope2, String label4, LabelElement element21) {
    _jtd_constructor_280_impl(outerScope2, label4, element21);
  }
  _jtd_constructor_280_impl(LabelScope outerScope2, String label4, LabelElement element21) {
    this._outerScope = outerScope2;
    this._label = label4;
    this._element = element21;
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
    if (!Scope.isPrivateName(element.name)) {
      super.define(element);
    }
  }
  LibraryElement get definingLibrary => _definingLibrary;
  AnalysisErrorListener get errorListener => _errorListener;
  Element lookup3(String name, LibraryElement referencingLibrary) {
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
    }
    if (foundElement != null) {
      defineWithoutChecking(foundElement);
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
   * Initialize a newly created namespace builder.
   */
  NamespaceBuilder() : super() {
  }
  /**
   * Create a namespace representing the export namespace of the given library.
   * @param library the library whose export namespace is to be created
   * @return the export namespace that was created
   */
  Namespace createExportNamespace(LibraryElement library) => new Namespace(createExportMapping(library, new Set<LibraryElement>()));
  /**
   * Create a namespace representing the import namespace of the given library.
   * @param library the library whose import namespace is to be created
   * @return the import namespace that was created
   */
  Namespace createImportNamespace(ImportElement element) {
    LibraryElement importedLibrary4 = element.importedLibrary;
    if (importedLibrary4 == null) {
      return Namespace.EMPTY;
    }
    Map<String, Element> definedNames = createExportMapping(importedLibrary4, new Set<LibraryElement>());
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
    String name22 = element.name;
    if (name22 != null && !Scope.isPrivateName(name22)) {
      definedNames[name22] = element;
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
    for (VariableElement element in compilationUnit.topLevelVariables) {
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
      if (combinator is __imp_combi.HideCombinator) {
        hide(definedNames, ((combinator as __imp_combi.HideCombinator)).hiddenNames);
      } else if (combinator is __imp_combi.ShowCombinator) {
        definedNames = show(definedNames, ((combinator as __imp_combi.ShowCombinator)).shownNames);
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
        LibraryElement exportedLibrary3 = element.exportedLibrary;
        if (exportedLibrary3 != null && !visitedElements.contains(exportedLibrary3)) {
          Map<String, Element> exportedNames = createExportMapping(exportedLibrary3, visitedElements);
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
   * Initialize a newly created scope to be empty.
   */
  Scope() : super() {
  }
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
  Element lookup(Identifier identifier, LibraryElement referencingLibrary) => lookup3(identifier.name, referencingLibrary);
  /**
   * Add the given element to this scope without checking for duplication or hiding.
   * @param element the element to be added to this scope
   */
  void defineWithoutChecking(Element element) {
    _definedNames[getName(element)] = element;
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
    Source source15 = duplicate.source;
    if (source15 == null) {
      source15 = source;
    }
    return new AnalysisError.con2(source15, duplicate.nameOffset, duplicate.name.length, CompileTimeErrorCode.DUPLICATE_DEFINITION, [existing.name]);
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
   * @param name the name associated with the element to be returned
   * @param referencingLibrary the library that contains the reference to the name, used to
   * implement library-level privacy
   * @return the element with which the given name is associated
   */
  Element lookup3(String name, LibraryElement referencingLibrary);
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
    } else if (element is PropertyAccessorElement) {
      PropertyAccessorElement accessor = element as PropertyAccessorElement;
      if (accessor.isSetter()) {
        return "${accessor.name}${SETTER_SUFFIX}";
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
   * Initialize a newly created constant verifier.
   * @param errorReporter the error reporter by which errors will be reported
   */
  ConstantVerifier(ErrorReporter errorReporter) {
    this._errorReporter = errorReporter;
  }
  Object visitFunctionExpression(FunctionExpression node) {
    super.visitFunctionExpression(node);
    validateDefaultValues(node.parameters);
    return null;
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
    Set<String> keys = new Set<String>();
    for (MapLiteralEntry entry in node.entries) {
      StringLiteral key4 = entry.key;
      EvaluationResultImpl result = validate(key4, CompileTimeErrorCode.NON_CONSTANT_MAP_KEY);
      if (result is ValidResult && ((result as ValidResult)).value is String) {
        String value11 = ((result as ValidResult)).value as String;
        if (keys.contains(value11)) {
          _errorReporter.reportError(StaticWarningCode.EQUAL_KEYS_IN_MAP, key4, []);
        } else {
          javaSetAdd(keys, value11);
        }
      }
      if (isConst) {
        validate(entry.value, CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE);
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
    Expression initializer7 = node.initializer;
    if (initializer7 != null && node.isConst()) {
      VariableElementImpl element58 = node.element as VariableElementImpl;
      EvaluationResultImpl result = element58.evaluationResult;
      if (result == null) {
        result = validate(initializer7, CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE);
        element58.evaluationResult = result;
      } else if (result is ErrorResult) {
        reportErrors(result, CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE);
      }
    }
    return null;
  }
  /**
   * If the given result represents one or more errors, report those errors. Except for special
   * cases, use the given error code rather than the one reported in the error.
   * @param result the result containing any errors that need to be reported
   * @param errorCode the error code to be used if the result represents an error
   */
  void reportErrors(EvaluationResultImpl result, ErrorCode errorCode) {
    if (result is ErrorResult) {
      for (ErrorResult_ErrorData data in ((result as ErrorResult)).errorData) {
        _errorReporter.reportError(errorCode, data.node, []);
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
   * Validate that the default value associated with each of the parameters in the given list is a
   * compile time constant.
   * @param parameters the list of parameters to be validated
   */
  void validateDefaultValues(FormalParameterList parameters17) {
    if (parameters17 == null) {
      return;
    }
    for (FormalParameter parameter in parameters17.parameters) {
      if (parameter is DefaultFormalParameter) {
        DefaultFormalParameter defaultParameter = parameter as DefaultFormalParameter;
        Expression defaultValue3 = defaultParameter.defaultValue;
        if (defaultValue3 != null) {
          EvaluationResultImpl result = validate(defaultValue3, CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE);
          if (defaultParameter.isConst()) {
            VariableElementImpl element59 = parameter.element as VariableElementImpl;
            element59.evaluationResult = result;
          }
        }
      }
    }
  }
}
/**
 * Instances of the class {@code ErrorVerifier} traverse an AST structure looking for additional
 * errors and warnings not covered by the parser and resolver.
 * @coverage dart.engine.resolver
 */
class ErrorVerifier extends RecursiveASTVisitor<Object> {
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
   * This is set to {@code true} iff the visitor is currently visiting code in the SDK.
   */
  bool _isInSystemLibrary = false;
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
   * A list of types used by the {@link CompileTimeErrorCode#EXTENDS_DISALLOWED_CLASS} and{@link CompileTimeErrorCode#IMPLEMENTS_DISALLOWED_CLASS} error codes.
   */
  List<InterfaceType> _DISALLOWED_TYPES_TO_EXTEND_OR_IMPLEMENT;
  ErrorVerifier(ErrorReporter errorReporter, LibraryElement currentLibrary, TypeProvider typeProvider) {
    this._errorReporter = errorReporter;
    this._currentLibrary = currentLibrary;
    this._isInSystemLibrary = currentLibrary.source.isInSystemLibrary();
    this._typeProvider = typeProvider;
    _isEnclosingConstructorConst = false;
    _isInCatchClause = false;
    _dynamicType = typeProvider.dynamicType;
    _DISALLOWED_TYPES_TO_EXTEND_OR_IMPLEMENT = <InterfaceType> [typeProvider.numType, typeProvider.intType, typeProvider.doubleType, typeProvider.boolType, typeProvider.stringType];
  }
  Object visitArgumentDefinitionTest(ArgumentDefinitionTest node) {
    checkForArgumentDefinitionTestNonParameter(node);
    return super.visitArgumentDefinitionTest(node);
  }
  Object visitAssertStatement(AssertStatement node) {
    checkForNonBoolExpression(node);
    return super.visitAssertStatement(node);
  }
  Object visitAssignmentExpression(AssignmentExpression node) {
    checkForInvalidAssignment(node);
    return super.visitAssignmentExpression(node);
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
    try {
      checkForBuiltInIdentifierAsName(node.name, CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME);
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
    }
  }
  Object visitClassTypeAlias(ClassTypeAlias node) {
    checkForBuiltInIdentifierAsName(node.name, CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME);
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
      return super.visitConstructorDeclaration(node);
    } finally {
      _isEnclosingConstructorConst = false;
      _enclosingFunction = outerFunction;
    }
  }
  Object visitDoStatement(DoStatement node) {
    checkForNonBoolCondition(node.condition);
    return super.visitDoStatement(node);
  }
  Object visitExtendsClause(ExtendsClause node) {
    checkForExtendsDisallowedClass(node);
    return super.visitExtendsClause(node);
  }
  Object visitFieldFormalParameter(FieldFormalParameter node) {
    checkForConstFormalParameter(node);
    checkForFieldInitializerOutsideConstructor(node);
    return super.visitFieldFormalParameter(node);
  }
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
  Object visitImplementsClause(ImplementsClause node) {
    checkForImplementsDisallowedClass(node);
    return super.visitImplementsClause(node);
  }
  Object visitInstanceCreationExpression(InstanceCreationExpression node) {
    ConstructorName constructorName4 = node.constructorName;
    TypeName typeName = constructorName4.type;
    Type2 type25 = typeName.type;
    if (type25 is InterfaceType) {
      InterfaceType interfaceType = type25 as InterfaceType;
      checkForConstWithNonConst(node);
      checkForConstOrNewWithAbstractClass(node, typeName, interfaceType);
      checkForTypeArgumentNotMatchingBounds(node, constructorName4.element, typeName);
    }
    return super.visitInstanceCreationExpression(node);
  }
  Object visitMethodDeclaration(MethodDeclaration node) {
    ExecutableElement previousFunction = _enclosingFunction;
    try {
      _enclosingFunction = node.element;
      return super.visitMethodDeclaration(node);
    } finally {
      _enclosingFunction = previousFunction;
    }
  }
  Object visitNativeFunctionBody(NativeFunctionBody node) {
    checkForNativeFunctionBodyInNonSDKCode(node);
    return super.visitNativeFunctionBody(node);
  }
  Object visitRethrowExpression(RethrowExpression node) {
    checkForRethrowOutsideCatch(node);
    return super.visitRethrowExpression(node);
  }
  Object visitReturnStatement(ReturnStatement node) {
    checkForReturnOfInvalidType(node);
    return super.visitReturnStatement(node);
  }
  Object visitSimpleFormalParameter(SimpleFormalParameter node) {
    checkForConstFormalParameter(node);
    return super.visitSimpleFormalParameter(node);
  }
  Object visitSwitchStatement(SwitchStatement node) {
    checkForCaseExpressionTypeImplementsEquals(node);
    return super.visitSwitchStatement(node);
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
   * @return return {@code true} if and only if an error code is generated on the passed node
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
            _errorReporter.reportError(CompileTimeErrorCode.FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR, formalParameter.identifier, [fieldElement.name]);
            foundError = true;
          }
        } else if (identical(state, INIT_STATE.INIT_IN_FIELD_FORMAL)) {
          if (fieldElement.isFinal() || fieldElement.isConst()) {
            _errorReporter.reportError(CompileTimeErrorCode.FINAL_INITIALIZED_MULTIPLE_TIMES, formalParameter.identifier, [fieldElement.name]);
            foundError = true;
          }
        }
      }
    }
    NodeList<ConstructorInitializer> initializers2 = node.initializers;
    for (ConstructorInitializer constructorInitializer in initializers2) {
      if (constructorInitializer is ConstructorFieldInitializer) {
        ConstructorFieldInitializer constructorFieldInitializer = constructorInitializer as ConstructorFieldInitializer;
        SimpleIdentifier fieldName3 = constructorFieldInitializer.fieldName;
        Element element60 = fieldName3.element;
        if (element60 is FieldElement) {
          FieldElement fieldElement = element60 as FieldElement;
          INIT_STATE state = fieldElementsMap[fieldElement];
          if (identical(state, INIT_STATE.NOT_INIT)) {
            fieldElementsMap[fieldElement] = INIT_STATE.INIT_IN_INITIALIZERS;
          } else if (identical(state, INIT_STATE.INIT_IN_DECLARATION)) {
            if (fieldElement.isFinal() || fieldElement.isConst()) {
              _errorReporter.reportError(CompileTimeErrorCode.FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION, fieldName3, []);
              foundError = true;
            }
          } else if (identical(state, INIT_STATE.INIT_IN_FIELD_FORMAL)) {
            _errorReporter.reportError(CompileTimeErrorCode.FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER, fieldName3, []);
            foundError = true;
          } else if (identical(state, INIT_STATE.INIT_IN_INITIALIZERS)) {
            _errorReporter.reportError(CompileTimeErrorCode.FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS, fieldName3, [fieldElement.name]);
            foundError = true;
          }
        }
      }
    }
    return foundError;
  }
  /**
   * This verifies that the passed argument definition test identifier is a parameter.
   * @param node the {@link ArgumentDefinitionTest} to evaluate
   * @return return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#ARGUMENT_DEFINITION_TEST_NON_PARAMETER
   */
  bool checkForArgumentDefinitionTestNonParameter(ArgumentDefinitionTest node) {
    SimpleIdentifier identifier15 = node.identifier;
    Element element61 = identifier15.element;
    if (element61 != null && element61 is! ParameterElement) {
      _errorReporter.reportError(CompileTimeErrorCode.ARGUMENT_DEFINITION_TEST_NON_PARAMETER, identifier15, [identifier15.name]);
      return true;
    }
    return false;
  }
  /**
   * This verifies that the passed identifier is not a keyword, and generates the passed error code
   * on the identifier if it is a keyword.
   * @param identifier the identifier to check to ensure that it is not a keyword
   * @param errorCode if the passed identifier is a keyword then this error code is created on the
   * identifier, the error code will be one of{@link CompileTimeErrorCode#BUILT_IN_IDENTIFIER_AS_TYPE_NAME},{@link CompileTimeErrorCode#BUILT_IN_IDENTIFIER_AS_TYPE_VARIABLE_NAME} or{@link CompileTimeErrorCode#BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME}
   * @return return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#BUILT_IN_IDENTIFIER_AS_TYPE_NAME
   * @see CompileTimeErrorCode#BUILT_IN_IDENTIFIER_AS_TYPE_VARIABLE_NAME
   * @see CompileTimeErrorCode#BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME
   */
  bool checkForBuiltInIdentifierAsName(SimpleIdentifier identifier, ErrorCode errorCode) {
    sc.Token token18 = identifier.token;
    if (identical(token18.type, sc.TokenType.KEYWORD)) {
      _errorReporter.reportError(errorCode, identifier, [identifier.name]);
      return true;
    }
    return false;
  }
  /**
   * This verifies that the passed variable declaration list does not have a built-in identifier.
   * @param node the variable declaration list to check
   * @return return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#BUILT_IN_IDENTIFIER_AS_TYPE
   */
  bool checkForBuiltInIdentifierAsName2(VariableDeclarationList node) {
    TypeName typeName = node.type;
    if (typeName != null) {
      Identifier identifier = typeName.name;
      if (identifier is SimpleIdentifier) {
        SimpleIdentifier simpleIdentifier = identifier as SimpleIdentifier;
        sc.Token token19 = simpleIdentifier.token;
        if (identical(token19.type, sc.TokenType.KEYWORD)) {
          if (((token19 as sc.KeywordToken)).keyword != sc.Keyword.DYNAMIC) {
            _errorReporter.reportError(CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE, identifier, [identifier.name]);
            return true;
          }
        }
      }
    }
    return false;
  }
  /**
   * This verifies that the passed switch statement does not have a case expression with the
   * operator '==' overridden.
   * @param node the switch statement to evaluate
   * @return return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS
   */
  bool checkForCaseExpressionTypeImplementsEquals(SwitchStatement node) {
    Expression expression16 = node.expression;
    Type2 type = expression16.staticType;
    if (type != null && type != _typeProvider.intType && type != _typeProvider.stringType) {
      Element element62 = type.element;
      if (element62 is ClassElement) {
        ClassElement classElement = element62 as ClassElement;
        MethodElement method = classElement.lookUpMethod("==", _currentLibrary);
        if (method != null && method.enclosingElement.type != _typeProvider.objectType) {
          _errorReporter.reportError(CompileTimeErrorCode.CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS, expression16, [element62.name]);
          return true;
        }
      }
    }
    return false;
  }
  bool checkForConflictingConstructorNameAndMember(ConstructorDeclaration node) {
    ConstructorElement constructorElement = node.element;
    SimpleIdentifier constructorName = node.name;
    if (constructorName != null && constructorElement != null && !constructorName.isSynthetic()) {
      String name24 = constructorName.name;
      ClassElement classElement = constructorElement.enclosingElement;
      List<FieldElement> fields3 = classElement.fields;
      for (FieldElement field in fields3) {
        if (field.name == name24) {
          _errorReporter.reportError(CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_NAME_AND_FIELD, node, [name24]);
          return true;
        }
      }
      List<MethodElement> methods3 = classElement.methods;
      for (MethodElement method in methods3) {
        if (method.name == name24) {
          _errorReporter.reportError(CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_NAME_AND_METHOD, node, [name24]);
          return true;
        }
      }
    }
    return false;
  }
  /**
   * This verifies that the passed constructor declaration is not 'const' if it has a non-final
   * instance variable.
   * @param node the instance creation expression to evaluate
   * @return return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD
   */
  bool checkForConstConstructorWithNonFinalField(ConstructorDeclaration node) {
    if (!_isEnclosingConstructorConst) {
      return false;
    }
    ConstructorElement constructorElement = node.element;
    if (constructorElement != null) {
      ClassElement classElement = constructorElement.enclosingElement;
      List<FieldElement> elements = classElement.fields;
      for (FieldElement field in elements) {
        if (!field.isFinal() && !field.isConst() && !field.isStatic() && !field.isSynthetic()) {
          _errorReporter.reportError(CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD, node, []);
          return true;
        }
      }
    }
    return false;
  }
  /**
   * This verifies that the passed throw expression is not enclosed in a 'const' constructor
   * declaration.
   * @param node the throw expression expression to evaluate
   * @return return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#CONST_EVAL_THROWS_EXCEPTION
   */
  bool checkForConstEvalThrowsException(ThrowExpression node) {
    if (_isEnclosingConstructorConst) {
      _errorReporter.reportError(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, node, []);
      return true;
    }
    return false;
  }
  /**
   * This verifies that the passed normal formal parameter is not 'const'.
   * @param node the normal formal parameter to evaluate
   * @return return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#CONST_FORMAL_PARAMETER
   */
  bool checkForConstFormalParameter(NormalFormalParameter node) {
    if (node.isConst()) {
      _errorReporter.reportError(CompileTimeErrorCode.CONST_FORMAL_PARAMETER, node, []);
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
   * @return return {@code true} if and only if an error code is generated on the passed node
   * @see StaticWarningCode#CONST_WITH_ABSTRACT_CLASS
   * @see StaticWarningCode#NEW_WITH_ABSTRACT_CLASS
   */
  bool checkForConstOrNewWithAbstractClass(InstanceCreationExpression node, TypeName typeName, InterfaceType type) {
    if (type.element.isAbstract()) {
      ConstructorElement element63 = node.element;
      if (element63 != null && !element63.isFactory()) {
        if (identical(((node.keyword as sc.KeywordToken)).keyword, sc.Keyword.CONST)) {
          _errorReporter.reportError(StaticWarningCode.CONST_WITH_ABSTRACT_CLASS, typeName, []);
        } else {
          _errorReporter.reportError(StaticWarningCode.NEW_WITH_ABSTRACT_CLASS, typeName, []);
        }
        return true;
      }
    }
    return false;
  }
  /**
   * This verifies that if the passed instance creation expression is 'const', then it is not being
   * invoked on a constructor that is not 'const'.
   * @param node the instance creation expression to evaluate
   * @return return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#CONST_WITH_NON_CONST
   */
  bool checkForConstWithNonConst(InstanceCreationExpression node) {
    ConstructorElement constructorElement = node.element;
    if (node.isConst() && constructorElement != null && !constructorElement.isConst()) {
      _errorReporter.reportError(CompileTimeErrorCode.CONST_WITH_NON_CONST, node, []);
      return true;
    }
    return false;
  }
  /**
   * This verifies that there are no default parameters in the passed function type alias.
   * @param node the function type alias to evaluate
   * @return return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#DEFAULT_VALUE_IN_FUNCTION_TYPE_ALIAS
   */
  bool checkForDefaultValueInFunctionTypeAlias(FunctionTypeAlias node) {
    bool result = false;
    FormalParameterList formalParameterList = node.parameters;
    NodeList<FormalParameter> parameters15 = formalParameterList.parameters;
    for (FormalParameter formalParameter in parameters15) {
      if (formalParameter is DefaultFormalParameter) {
        DefaultFormalParameter defaultFormalParameter = formalParameter as DefaultFormalParameter;
        if (defaultFormalParameter.defaultValue != null) {
          _errorReporter.reportError(CompileTimeErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE_ALIAS, node, []);
          result = true;
        }
      }
    }
    return result;
  }
  /**
   * This verifies that the passed extends clause does not extend classes such as num or String.
   * @param node the extends clause to test
   * @return return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#EXTENDS_DISALLOWED_CLASS
   */
  bool checkForExtendsDisallowedClass(ExtendsClause extendsClause) => checkForExtendsOrImplementsDisallowedClass(extendsClause.superclass, CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS);
  /**
   * This verifies that the passed type name does not extend or implement classes such as 'num' or
   * 'String'.
   * @param node the type name to test
   * @return return {@code true} if and only if an error code is generated on the passed node
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
        _errorReporter.reportError(errorCode, typeName, [disallowedType.name]);
        return true;
      }
    }
    return false;
  }
  /**
   * This verifies that the passed field formal parameter is in a constructor declaration.
   * @param node the field formal parameter to test
   * @return return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR
   */
  bool checkForFieldInitializerOutsideConstructor(FieldFormalParameter node) {
    ASTNode parent18 = node.parent;
    if (parent18 != null) {
      ASTNode grandparent = parent18.parent;
      if (grandparent != null && grandparent is! ConstructorDeclaration && grandparent.parent is! ConstructorDeclaration) {
        _errorReporter.reportError(CompileTimeErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR, node, []);
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
      NodeList<VariableDeclaration> variables3 = node.variables;
      for (VariableDeclaration variable in variables3) {
        if (variable.initializer == null) {
          _errorReporter.reportError(CompileTimeErrorCode.FINAL_NOT_INITIALIZED, variable, [variable.name.name]);
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
   * @return return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#IMPLEMENTS_DISALLOWED_CLASS
   */
  bool checkForImplementsDisallowedClass(ImplementsClause implementsClause) {
    bool foundError = false;
    for (TypeName type in implementsClause.interfaces) {
      foundError = javaBooleanOr(foundError, checkForExtendsOrImplementsDisallowedClass(type, CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS));
    }
    return foundError;
  }
  /**
   * This verifies that the passed assignment expression represents a valid assignment.
   * @param node the assignment expression to evaluate
   * @return return {@code true} if and only if an error code is generated on the passed node
   * @see StaticTypeWarningCode#INVALID_ASSIGNMENT
   */
  bool checkForInvalidAssignment(AssignmentExpression node) {
    Expression lhs = node.leftHandSide;
    Expression rhs = node.rightHandSide;
    VariableElement leftElement = getVariableElement(lhs);
    Type2 leftType = (leftElement == null) ? getType(lhs) : leftElement.type;
    Type2 rightType = getType(rhs);
    if (!rightType.isAssignableTo(leftType)) {
      _errorReporter.reportError(StaticTypeWarningCode.INVALID_ASSIGNMENT, rhs, [rightType.name, leftType.name]);
      return true;
    }
    return false;
  }
  /**
   * Checks to ensure that native function bodies can only in SDK code.
   * @param node the native function body to test
   * @return return {@code true} if and only if an error code is generated on the passed node
   * @see ParserErrorCode#NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE
   */
  bool checkForNativeFunctionBodyInNonSDKCode(NativeFunctionBody node) {
    if (!_isInSystemLibrary) {
      _errorReporter.reportError(ParserErrorCode.NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE, node, []);
      return true;
    }
    return false;
  }
  /**
   * Checks to ensure that the expressions that need to be of type bool, are. Otherwise an error is
   * reported on the expression.
   * @param condition the conditional expression to test
   * @return return {@code true} if and only if an error code is generated on the passed node
   * @see StaticTypeWarningCode#NON_BOOL_CONDITION
   */
  bool checkForNonBoolCondition(Expression condition) {
    Type2 conditionType = getType(condition);
    if (conditionType != null && !conditionType.isAssignableTo(_typeProvider.boolType)) {
      _errorReporter.reportError(StaticTypeWarningCode.NON_BOOL_CONDITION, condition, []);
      return true;
    }
    return false;
  }
  /**
   * This verifies that the passed assert statement has either a 'bool' or '() -> bool' input.
   * @param node the assert statement to evaluate
   * @return return {@code true} if and only if an error code is generated on the passed node
   * @see StaticTypeWarningCode#NON_BOOL_EXPRESSION
   */
  bool checkForNonBoolExpression(AssertStatement node) {
    Expression expression = node.condition;
    Type2 type = getType(expression);
    if (type is InterfaceType) {
      if (!type.isAssignableTo(_typeProvider.boolType)) {
        _errorReporter.reportError(StaticTypeWarningCode.NON_BOOL_EXPRESSION, expression, []);
        return true;
      }
    } else if (type is FunctionType) {
      FunctionType functionType = type as FunctionType;
      if (functionType.typeArguments.length == 0 && !functionType.returnType.isAssignableTo(_typeProvider.boolType)) {
        _errorReporter.reportError(StaticTypeWarningCode.NON_BOOL_EXPRESSION, expression, []);
        return true;
      }
    }
    return false;
  }
  /**
   * This checks that the rethrow is inside of a catch clause.
   * @param node the rethrow expression to evaluate
   * @return {@code true} if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#RETHROW_OUTSIDE_CATCH
   */
  bool checkForRethrowOutsideCatch(RethrowExpression node) {
    if (!_isInCatchClause) {
      _errorReporter.reportError(CompileTimeErrorCode.RETHROW_OUTSIDE_CATCH, node, []);
      return true;
    }
    return false;
  }
  /**
   * This checks that the return type matches the type of the declared return type in the enclosing
   * method or function.
   * @param node the return statement to evaluate
   * @return return {@code true} if and only if an error code is generated on the passed node
   * @see StaticTypeWarningCode#RETURN_OF_INVALID_TYPE
   */
  bool checkForReturnOfInvalidType(ReturnStatement node) {
    FunctionType functionType = _enclosingFunction == null ? null : _enclosingFunction.type;
    Type2 expectedReturnType = functionType == null ? null : functionType.returnType;
    Expression returnExpression = node.expression;
    if (expectedReturnType != null && !expectedReturnType.isVoid() && returnExpression != null) {
      Type2 actualReturnType = getType(returnExpression);
      if (!actualReturnType.isAssignableTo(expectedReturnType)) {
        _errorReporter.reportError(StaticTypeWarningCode.RETURN_OF_INVALID_TYPE, returnExpression, [actualReturnType.name, expectedReturnType.name, _enclosingFunction.name]);
        return true;
      }
    }
    return false;
  }
  /**
   * This verifies that the type arguments in the passed instance creation expression are all within
   * their bounds as specified by the class element where the constructor [that is being invoked] is
   * declared.
   * @param node the instance creation expression to evaluate
   * @param typeName the {@link TypeName} of the {@link ConstructorName} from the{@link InstanceCreationExpression}, this is the AST node that the error is attached to
   * @param constructorElement the {@link ConstructorElement} from the instance creation expression
   * @return return {@code true} if and only if an error code is generated on the passed node
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
            _errorReporter.reportError(StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, argTypeName, [argTypeName.name, boundingElts[i].name]);
            return true;
          }
        }
      }
    }
    return false;
  }
  /**
   * Return the type of the given expression that is to be used for type analysis.
   * @param expression the expression whose type is to be returned
   * @return the type of the given expression
   */
  Type2 getType(Expression expression) {
    Type2 type = expression.staticType;
    return type == null ? _dynamicType : type;
  }
  /**
   * Return the variable element represented by the given expression, or {@code null} if there is no
   * such element.
   * @param expression the expression whose element is to be returned
   * @return the variable element represented by the expression
   */
  VariableElement getVariableElement(Expression expression) {
    if (expression is Identifier) {
      Element element64 = ((expression as Identifier)).element;
      if (element64 is VariableElement) {
        return element64 as VariableElement;
      }
    }
    return null;
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
  final String __name;
  final int __ordinal;
  int get ordinal => __ordinal;
  INIT_STATE(this.__name, this.__ordinal) {
  }
  int compareTo(INIT_STATE other) => __ordinal - other.__ordinal;
  String toString() => __name;
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
  final String __name;
  final int __ordinal;
  int get ordinal => __ordinal;
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
  ResolverErrorCode(this.__name, this.__ordinal, ErrorType type, String message) {
    this._type = type;
    this._message = message;
  }
  ErrorSeverity get errorSeverity => _type.severity;
  String get message => _message;
  ErrorType get type => _type;
  bool needsRecompilation() => true;
  int compareTo(ResolverErrorCode other) => __ordinal - other.__ordinal;
  String toString() => __name;
}