// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.resolver;

import 'dart:collection';
import 'java_core.dart';
import 'java_engine.dart';
import 'source.dart';
import 'error.dart';
import 'scanner.dart' as sc;
import 'utilities_dart.dart';
import 'ast.dart';
import 'parser.dart' show Parser;
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
   * The analysis context in which the element model will be built.
   */
  AnalysisContextImpl _analysisContext;
  /**
   * The listener to which errors will be reported.
   */
  AnalysisErrorListener _errorListener;
  /**
   * Initialize a newly created compilation unit element builder.
   * @param analysisContext the analysis context in which the element model will be built
   * @param errorListener the listener to which errors will be reported
   */
  CompilationUnitBuilder(AnalysisContextImpl analysisContext, AnalysisErrorListener errorListener) {
    this._analysisContext = analysisContext;
    this._errorListener = errorListener;
  }
  /**
   * Build the compilation unit element for the given source.
   * @param source the source describing the compilation unit
   * @return the compilation unit element that was built
   * @throws AnalysisException if the analysis could not be performed
   */
  CompilationUnitElementImpl buildCompilationUnit(Source source) => buildCompilationUnit2(source, _analysisContext.parse3(source, _errorListener));
  /**
   * Build the compilation unit element for the given source.
   * @param source the source describing the compilation unit
   * @param unit the AST structure representing the compilation unit
   * @return the compilation unit element that was built
   * @throws AnalysisException if the analysis could not be performed
   */
  CompilationUnitElementImpl buildCompilationUnit2(Source source13, CompilationUnit unit) {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = new ElementBuilder(holder);
    unit.accept(builder);
    CompilationUnitElementImpl element = new CompilationUnitElementImpl(source13.shortName);
    element.accessors = holder.accessors;
    element.functions = holder.functions;
    element.source = source13;
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
    visitChildren(holder, node);
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
    if (constructorName != null) {
      constructorName.element = element;
    }
    return null;
  }
  Object visitDeclaredIdentifier(DeclaredIdentifier node) {
    SimpleIdentifier variableName = node.identifier;
    sc.Token keyword27 = node.keyword;
    LocalVariableElementImpl element = new LocalVariableElementImpl(variableName);
    ForEachStatement statement = node.parent as ForEachStatement;
    int declarationEnd = node.offset + node.length;
    int statementEnd = statement.offset + statement.length;
    element.setVisibleRange(declarationEnd, statementEnd - declarationEnd - 1);
    element.const3 = matches(keyword27, sc.Keyword.CONST);
    element.final2 = matches(keyword27, sc.Keyword.FINAL);
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
      ParameterElementImpl parameter = new ParameterElementImpl(parameterName);
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
    SimpleIdentifier functionName = null;
    FunctionElementImpl element = new FunctionElementImpl.con1(functionName);
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
    List<ParameterElement> parameters10 = holder.parameters;
    List<TypeVariableElement> typeVariables6 = holder.typeVariables;
    FunctionTypeAliasElementImpl element = new FunctionTypeAliasElementImpl(aliasName);
    element.parameters = parameters10;
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
    visitChildren(new ElementHolder(), node);
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
      sc.Token keyword = node.modifierKeyword;
      element.abstract = matches(keyword, sc.Keyword.ABSTRACT);
      element.functions = holder.functions;
      element.labels = holder.labels;
      element.localVariables = holder.localVariables;
      element.parameters = holder.parameters;
      element.static = matches(keyword, sc.Keyword.STATIC);
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
    sc.Token keyword28 = ((node.parent as VariableDeclarationList)).keyword;
    bool isConst = matches(keyword28, sc.Keyword.CONST);
    bool isFinal = matches(keyword28, sc.Keyword.FINAL);
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
  bool matches(sc.Token token, sc.Keyword keyword36) => token != null && identical(token.type, sc.TokenType.KEYWORD) && identical(((token as sc.KeywordToken)).keyword, keyword36);
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
  List<PropertyAccessorElement> get accessors => new List.from(_accessors);
  List<ConstructorElement> get constructors => new List.from(_constructors);
  FieldElement getField(String fieldName) {
    for (FieldElement field in _fields) {
      if (field.name == fieldName) {
        return field;
      }
    }
    return null;
  }
  List<FieldElement> get fields => new List.from(_fields);
  List<FunctionElement> get functions => new List.from(_functions);
  List<LabelElement> get labels => new List.from(_labels);
  List<LocalVariableElement> get localVariables => new List.from(_localVariables);
  List<MethodElement> get methods => new List.from(_methods);
  List<ParameterElement> get parameters => new List.from(_parameters);
  List<TopLevelVariableElement> get topLevelVariables => new List.from(_topLevelVariables);
  List<FunctionTypeAliasElement> get typeAliases => new List.from(_typeAliases);
  List<ClassElement> get types => new List.from(_types);
  List<TypeVariableElement> get typeVariables => new List.from(_typeVariables);
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
  AnalysisContextImpl _context;
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
  HtmlUnitBuilder(AnalysisContextImpl context) {
    this._context = context;
  }
  /**
   * Build the HTML element for the given source.
   * @param source the source describing the compilation unit
   * @return the HTML element that was built
   * @throws AnalysisException if the analysis could not be performed
   */
  HtmlElementImpl buildHtmlElement(Source source) => buildHtmlElement2(source, _context.parseHtml(source).htmlUnit);
  /**
   * Build the HTML element for the given source.
   * @param source the source describing the compilation unit
   * @param unit the AST structure representing the HTML
   * @throws AnalysisException if the analysis could not be performed
   */
  HtmlElementImpl buildHtmlElement2(Source source14, ht.HtmlUnit unit) {
    HtmlElementImpl result = new HtmlElementImpl(_context, source14.shortName);
    result.source = source14;
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
        AnalysisErrorListener errorListener = new AnalysisErrorListener_2();
        sc.StringScanner scanner = new sc.StringScanner(null, contents, errorListener);
        sc.Token firstToken = scanner.tokenize();
        List<int> lineStarts2 = scanner.lineStarts;
        Parser parser = new Parser(null, errorListener);
        CompilationUnit unit = parser.parseCompilationUnit(firstToken);
        try {
          CompilationUnitBuilder builder = new CompilationUnitBuilder(_context, errorListener);
          CompilationUnitElementImpl elem = builder.buildCompilationUnit2(htmlSource, unit);
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
          script.scriptSource = htmlSource.resolve(scriptSourcePath);
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
class AnalysisErrorListener_2 implements AnalysisErrorListener {
  void onError(AnalysisError error) {
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
          Element leftElement = leftType.element;
          if (leftElement != null) {
            MethodElement method = lookUpMethod(leftElement, operator7.lexeme);
            if (method != null) {
              node.element = method;
            } else {
            }
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
      Element leftTypeElement;
      if (leftType == null || leftType.isDynamic()) {
        return null;
      } else if (leftType is FunctionType) {
        leftTypeElement = _resolver.typeProvider.functionType.element;
      } else {
        leftTypeElement = leftType.element;
      }
      String methodName = operator8.lexeme;
      MethodElement member = lookUpMethod(leftTypeElement, methodName);
      if (member == null) {
        _resolver.reportError3(ResolverErrorCode.CANNOT_BE_RESOLVED, operator8, [methodName]);
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
  Object visitConstructorName(ConstructorName node) {
    Type2 type13 = node.type.type;
    if (type13 is DynamicTypeImpl) {
      return null;
    } else if (type13 is! InterfaceType) {
      ASTNode parent14 = node.parent;
      if (parent14 is InstanceCreationExpression) {
        if (((parent14 as InstanceCreationExpression)).isConst()) {
        } else {
        }
      } else {
      }
      return null;
    }
    ClassElement classElement = ((type13 as InterfaceType)).element;
    ConstructorElement constructor;
    SimpleIdentifier name14 = node.name;
    if (name14 == null) {
      constructor = classElement.unnamedConstructor;
    } else {
      constructor = classElement.getNamedConstructor(name14.name);
      name14.element = constructor;
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
    Element element22 = node.element;
    if (element22 is ExportElement) {
      resolveCombinators(((element22 as ExportElement)).exportedLibrary, node.combinators);
    }
    return null;
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
    Element element23 = node.element;
    if (element23 is ImportElement) {
      resolveCombinators(((element23 as ImportElement)).importedLibrary, node.combinators);
    }
    return null;
  }
  Object visitIndexExpression(IndexExpression node) {
    Type2 arrayType = getType(node.realTarget);
    if (arrayType == null || arrayType.isDynamic()) {
      return null;
    }
    Element arrayTypeElement = arrayType.element;
    String operator;
    if (node.inSetterContext()) {
      operator = sc.TokenType.INDEX_EQ.lexeme;
    } else {
      operator = sc.TokenType.INDEX.lexeme;
    }
    MethodElement member = lookUpMethod(arrayTypeElement, operator);
    if (member == null) {
      _resolver.reportError(ResolverErrorCode.CANNOT_BE_RESOLVED, node, [operator]);
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
        element = lookUpMethod(_resolver.enclosingClass, methodName2.name);
        if (element == null) {
          PropertyAccessorElement getter = lookUpGetter(_resolver.enclosingClass, methodName2.name);
          if (getter != null) {
            FunctionType getterType = getter.type;
            if (getterType != null) {
              Type2 returnType4 = getterType.returnType;
              if (!isExecutableType(returnType4)) {
                _resolver.reportError(StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION, methodName2, [methodName2.name]);
              }
            }
            recordResolution(methodName2, getter);
            return null;
          }
        }
      }
    } else {
      Type2 targetType = getType(target);
      if (targetType is InterfaceType) {
        element = lookUpMethod(targetType.element, methodName2.name);
        if (element == null) {
          ClassElement targetClass = targetType.element as ClassElement;
          PropertyAccessorElement accessor = lookUpGetterInType(targetClass, methodName2.name);
          if (accessor != null) {
            Type2 returnType5 = accessor.type.returnType.substitute2(((targetType as InterfaceType)).typeArguments, TypeVariableTypeImpl.getTypes(targetClass.typeVariables));
            if (!isExecutableType(returnType5)) {
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
          String name9 = "${((target as SimpleIdentifier)).name}.${methodName2}";
          Identifier functionName = new Identifier_4(name9);
          element = _resolver.nameScope.lookup(functionName, _resolver.definingLibrary);
        } else {
          return null;
        }
      } else {
        return null;
      }
    }
    ExecutableElement invokedMethod = null;
    if (element is ExecutableElement) {
      invokedMethod = element as ExecutableElement;
    } else {
      if (element is PropertyInducingElement) {
        PropertyAccessorElement getter3 = ((element as PropertyInducingElement)).getter;
        FunctionType getterType = getter3.type;
        if (getterType != null) {
          Type2 returnType6 = getterType.returnType;
          if (!isExecutableType(returnType6)) {
            _resolver.reportError(StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION, methodName2, [methodName2.name]);
          }
        }
        recordResolution(methodName2, element);
        return null;
      } else if (element is VariableElement) {
        Type2 variableType = ((element as VariableElement)).type;
        if (!isExecutableType(variableType)) {
          _resolver.reportError(StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION, methodName2, [methodName2.name]);
        }
        recordResolution(methodName2, element);
        return null;
      } else {
        _resolver.reportError(StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION, methodName2, [methodName2.name]);
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
    Element operandTypeElement = operandType.element;
    String methodName;
    if (identical(operator9.type, sc.TokenType.PLUS_PLUS)) {
      methodName = sc.TokenType.PLUS.lexeme;
    } else {
      methodName = sc.TokenType.MINUS.lexeme;
    }
    MethodElement member = lookUpMethod(operandTypeElement, methodName);
    if (member == null) {
      _resolver.reportError3(ResolverErrorCode.CANNOT_BE_RESOLVED, operator9, [methodName]);
    } else {
      node.element = member;
    }
    return null;
  }
  Object visitPrefixedIdentifier(PrefixedIdentifier node) {
    SimpleIdentifier prefix6 = node.prefix;
    SimpleIdentifier identifier13 = node.identifier;
    Element prefixElement = prefix6.element;
    if (prefixElement is PrefixElement) {
      Element element = _resolver.nameScope.lookup(node, _resolver.definingLibrary);
      if (element == null) {
        return null;
      }
      recordResolution(identifier13, element);
      return null;
    }
    if (prefixElement is ClassElement) {
      Element memberElement;
      if (node.identifier.inSetterContext()) {
        memberElement = lookUpSetterInType((prefixElement as ClassElement), identifier13.name);
      } else {
        memberElement = lookUpGetterInType((prefixElement as ClassElement), identifier13.name);
      }
      if (memberElement == null) {
        MethodElement methodElement = lookUpMethod(prefixElement, identifier13.name);
        if (methodElement != null) {
          recordResolution(identifier13, methodElement);
          return null;
        }
      }
      if (memberElement == null) {
        reportGetterOrSetterNotFound(node, identifier13, prefixElement.name);
      } else {
        recordResolution(identifier13, memberElement);
      }
      return null;
    }
    Element variableTypeElement;
    if (prefixElement is PropertyAccessorElement) {
      PropertyAccessorElement accessor = prefixElement as PropertyAccessorElement;
      FunctionType type14 = accessor.type;
      if (type14 == null) {
        return null;
      }
      Type2 variableType;
      if (accessor.isGetter()) {
        variableType = type14.returnType;
      } else {
        variableType = type14.normalParameterTypes[0];
      }
      if (variableType == null || variableType.isDynamic()) {
        return null;
      }
      variableTypeElement = variableType.element;
    } else if (prefixElement is VariableElement) {
      Type2 prefixType = ((prefixElement as VariableElement)).type;
      if (prefixType == null || prefixType.isDynamic()) {
        return null;
      }
      variableTypeElement = prefixType.element;
    } else {
      return null;
    }
    PropertyAccessorElement memberElement = null;
    if (node.identifier.inSetterContext()) {
      memberElement = lookUpSetter(variableTypeElement, identifier13.name);
    }
    if (memberElement == null && node.identifier.inGetterContext()) {
      memberElement = lookUpGetter(variableTypeElement, identifier13.name);
    }
    if (memberElement == null) {
      MethodElement methodElement = lookUpMethod(variableTypeElement, identifier13.name);
      if (methodElement != null) {
        recordResolution(identifier13, methodElement);
        return null;
      }
    }
    if (memberElement == null) {
      reportGetterOrSetterNotFound(node, identifier13, variableTypeElement.name);
    } else {
      recordResolution(identifier13, memberElement);
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
      Element operandTypeElement = operandType.element;
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
      MethodElement member = lookUpMethod(operandTypeElement, methodName);
      if (member == null) {
        _resolver.reportError3(ResolverErrorCode.CANNOT_BE_RESOLVED, operator10, [methodName]);
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
    ClassElement targetElement = ((targetType as InterfaceType)).element;
    SimpleIdentifier identifier = node.propertyName;
    PropertyAccessorElement memberElement = null;
    if (identifier.inSetterContext()) {
      memberElement = lookUpSetter(targetElement, identifier.name);
    }
    if (memberElement == null && identifier.inGetterContext()) {
      memberElement = lookUpGetter(targetElement, identifier.name);
    }
    if (memberElement == null) {
      MethodElement methodElement = lookUpMethod(targetElement, identifier.name);
      if (methodElement != null) {
        recordResolution(identifier, methodElement);
        return null;
      }
    }
    if (memberElement == null) {
      _resolver.reportError(ResolverErrorCode.CANNOT_BE_RESOLVED, identifier, [identifier.name]);
    } else {
      recordResolution(identifier, memberElement);
    }
    return null;
  }
  Object visitRedirectingConstructorInvocation(RedirectingConstructorInvocation node) {
    ClassElement enclosingClass2 = _resolver.enclosingClass;
    if (enclosingClass2 == null) {
      return null;
    }
    SimpleIdentifier name = node.constructorName;
    ConstructorElement element;
    if (name == null) {
      element = enclosingClass2.unnamedConstructor;
    } else {
      element = enclosingClass2.getNamedConstructor(name.name);
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
      PropertyInducingElement variable4 = ((element as PropertyAccessorElement)).variable;
      if (variable4 != null) {
        PropertyAccessorElement setter3 = variable4.setter;
        if (setter3 != null) {
          element = setter3;
        }
      }
    }
    if (element == null && node.inSetterContext()) {
      element = lookUpSetter(_resolver.enclosingClass, node.name);
    }
    if (element == null && node.inGetterContext()) {
      element = lookUpGetter(_resolver.enclosingClass, node.name);
    }
    if (element == null) {
      element = lookUpMethod(_resolver.enclosingClass, node.name);
    }
    if (element == null) {
    }
    recordResolution(node, element);
    return null;
  }
  Object visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    ClassElement enclosingClass3 = _resolver.enclosingClass;
    if (enclosingClass3 == null) {
      return null;
    }
    ClassElement superclass = getSuperclass(enclosingClass3);
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
  ParameterElement findNamedParameter(List<ParameterElement> parameters, String name25) {
    for (ParameterElement parameter in parameters) {
      if (identical(parameter.parameterKind, ParameterKind.NAMED)) {
        String parameteName = parameter.name;
        if (parameteName != null && parameteName == name25) {
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
  bool isExecutableType(Type2 type) => type.isDynamic() || (type is FunctionType) || type.isDartCoreFunction();
  /**
   * Look up the getter with the given name in the given type. Return the element representing the
   * getter that was found, or {@code null} if there is no getter with the given name.
   * @param element the element representing the type in which the getter is defined
   * @param getterName the name of the getter being looked up
   * @return the element representing the getter that was found
   */
  PropertyAccessorElement lookUpGetter(Element element, String getterName) {
    if (identical(element, DynamicTypeImpl.instance)) {
      return null;
    }
    element = resolveTypeVariable(element);
    if (element is ClassElement) {
      ClassElement classElement = element as ClassElement;
      PropertyAccessorElement member = classElement.lookUpGetter(getterName, _resolver.definingLibrary);
      if (member != null) {
        return member;
      }
      return lookUpGetterInInterfaces((element as ClassElement), getterName, new Set<ClassElement>());
    }
    return null;
  }
  /**
   * Look up the name of a getter in the interfaces implemented by the given type, either directly
   * or indirectly. Return the element representing the getter that was found, or {@code null} if
   * there is no getter with the given name.
   * @param element the element representing the type in which the getter is defined
   * @param memberName the name of the getter being looked up
   * @param visitedInterfaces a set containing all of the interfaces that have been examined, used
   * to prevent infinite recursion and to optimize the search
   * @return the element representing the getter that was found
   */
  PropertyAccessorElement lookUpGetterInInterfaces(ClassElement targetClass, String memberName, Set<ClassElement> visitedInterfaces) {
    if (visitedInterfaces.contains(targetClass)) {
      return null;
    }
    javaSetAdd(visitedInterfaces, targetClass);
    PropertyAccessorElement member = lookUpGetterInType(targetClass, memberName);
    if (member != null) {
      return member;
    }
    for (InterfaceType interfaceType in targetClass.interfaces) {
      member = lookUpGetterInInterfaces(interfaceType.element, memberName, visitedInterfaces);
      if (member != null) {
        return member;
      }
    }
    ClassElement superclass = getSuperclass(targetClass);
    if (superclass == null) {
      return null;
    }
    return lookUpGetterInInterfaces(superclass, memberName, visitedInterfaces);
  }
  /**
   * Look up the name of a getter in the given type. Return the element representing the getter that
   * was found, or {@code null} if there is no getter with the given name.
   * @param element the element representing the type in which the getter is defined
   * @param memberName the name of the getter being looked up
   * @return the element representing the getter that was found
   */
  PropertyAccessorElement lookUpGetterInType(ClassElement element, String memberName) {
    for (PropertyAccessorElement accessor in element.accessors) {
      if (accessor.isGetter() && accessor.name == memberName) {
        return accessor;
      }
    }
    return null;
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
   * @param element the element representing the type in which the method is defined
   * @param methodName the name of the method being looked up
   * @return the element representing the method that was found
   */
  MethodElement lookUpMethod(Element element, String methodName) {
    if (identical(element, DynamicTypeImpl.instance)) {
      return null;
    }
    element = resolveTypeVariable(element);
    if (element is ClassElement) {
      ClassElement classElement = element as ClassElement;
      MethodElement member = classElement.lookUpMethod(methodName, _resolver.definingLibrary);
      if (member != null) {
        return member;
      }
      return lookUpMethodInInterfaces((element as ClassElement), methodName, new Set<ClassElement>());
    }
    return null;
  }
  /**
   * Look up the name of a member in the interfaces implemented by the given type, either directly
   * or indirectly. Return the element representing the member that was found, or {@code null} if
   * there is no member with the given name.
   * @param element the element representing the type in which the member is defined
   * @param memberName the name of the member being looked up
   * @param visitedInterfaces a set containing all of the interfaces that have been examined, used
   * to prevent infinite recursion and to optimize the search
   * @return the element representing the member that was found
   */
  MethodElement lookUpMethodInInterfaces(ClassElement targetClass, String memberName, Set<ClassElement> visitedInterfaces) {
    if (visitedInterfaces.contains(targetClass)) {
      return null;
    }
    javaSetAdd(visitedInterfaces, targetClass);
    MethodElement member = lookUpMethodInType(targetClass, memberName);
    if (member != null) {
      return member;
    }
    for (InterfaceType interfaceType in targetClass.interfaces) {
      member = lookUpMethodInInterfaces(interfaceType.element, memberName, visitedInterfaces);
      if (member != null) {
        return member;
      }
    }
    ClassElement superclass = getSuperclass(targetClass);
    if (superclass == null) {
      return null;
    }
    return lookUpMethodInInterfaces(superclass, memberName, visitedInterfaces);
  }
  /**
   * Look up the name of a method in the given type. Return the element representing the method that
   * was found, or {@code null} if there is no method with the given name.
   * @param element the element representing the type in which the method is defined
   * @param memberName the name of the method being looked up
   * @return the element representing the method that was found
   */
  MethodElement lookUpMethodInType(ClassElement element, String memberName) {
    for (MethodElement method in element.methods) {
      if (method.name == memberName) {
        return method;
      }
    }
    return null;
  }
  /**
   * Look up the setter with the given name in the given type. Return the element representing the
   * setter that was found, or {@code null} if there is no setter with the given name.
   * @param element the element representing the type in which the setter is defined
   * @param setterName the name of the setter being looked up
   * @return the element representing the setter that was found
   */
  PropertyAccessorElement lookUpSetter(Element element, String setterName) {
    if (identical(element, DynamicTypeImpl.instance)) {
      return null;
    }
    element = resolveTypeVariable(element);
    if (element is ClassElement) {
      ClassElement classElement = element as ClassElement;
      PropertyAccessorElement member = classElement.lookUpSetter(setterName, _resolver.definingLibrary);
      if (member != null) {
        return member;
      }
      return lookUpSetterInInterfaces((element as ClassElement), setterName, new Set<ClassElement>());
    }
    return null;
  }
  /**
   * Look up the name of a setter in the interfaces implemented by the given type, either directly
   * or indirectly. Return the element representing the setter that was found, or {@code null} if
   * there is no setter with the given name.
   * @param element the element representing the type in which the setter is defined
   * @param memberName the name of the setter being looked up
   * @param visitedInterfaces a set containing all of the interfaces that have been examined, used
   * to prevent infinite recursion and to optimize the search
   * @return the element representing the setter that was found
   */
  PropertyAccessorElement lookUpSetterInInterfaces(ClassElement targetClass, String memberName, Set<ClassElement> visitedInterfaces) {
    if (visitedInterfaces.contains(targetClass)) {
      return null;
    }
    javaSetAdd(visitedInterfaces, targetClass);
    PropertyAccessorElement member = lookUpSetterInType(targetClass, memberName);
    if (member != null) {
      return member;
    }
    for (InterfaceType interfaceType in targetClass.interfaces) {
      member = lookUpSetterInInterfaces(interfaceType.element, memberName, visitedInterfaces);
      if (member != null) {
        return member;
      }
    }
    ClassElement superclass = getSuperclass(targetClass);
    if (superclass == null) {
      return null;
    }
    return lookUpSetterInInterfaces(superclass, memberName, visitedInterfaces);
  }
  /**
   * Look up the name of a setter in the given type. Return the element representing the setter that
   * was found, or {@code null} if there is no setter with the given name.
   * @param element the element representing the type in which the setter is defined
   * @param memberName the name of the setter being looked up
   * @return the element representing the setter that was found
   */
  PropertyAccessorElement lookUpSetterInType(ClassElement element, String memberName) {
    for (PropertyAccessorElement accessor in element.accessors) {
      if (accessor.isSetter() && accessor.name == memberName) {
        return accessor;
      }
    }
    return null;
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
  void recordResolution(SimpleIdentifier node, Element element52) {
    if (element52 != null) {
      node.element = element52;
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
  void reportGetterOrSetterNotFound(PrefixedIdentifier node, SimpleIdentifier identifier30, String typeName) {
    bool isSetterContext = node.identifier.inSetterContext();
    ErrorCode errorCode = isSetterContext ? StaticTypeWarningCode.UNDEFINED_SETTER : StaticTypeWarningCode.UNDEFINED_GETTER;
    _resolver.reportError(errorCode, identifier30, [identifier30.name, typeName]);
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
    List<ParameterElement> parameters11 = invokedMethod.parameters;
    for (Expression argument in argumentList.arguments) {
      if (argument is NamedExpression) {
        SimpleIdentifier name15 = ((argument as NamedExpression)).name.label;
        ParameterElement parameter = findNamedParameter(parameters11, name15.name);
        if (parameter != null) {
          recordResolution(name15, parameter);
        }
      }
    }
  }
  /**
   * If the given element is a type variable, resolve it to the class that should be used when
   * looking up members. Otherwise, return the original element.
   * @param element the element that is to be resolved if it is a type variable
   * @return the class that should be used in place of the argument if it is a type variable, or the
   * original argument if it isn't a type variable
   */
  Element resolveTypeVariable(Element element53) {
    if (element53 is TypeVariableElement) {
      Type2 bound4 = ((element53 as TypeVariableElement)).bound;
      if (bound4 == null) {
        return _resolver.typeProvider.objectType.element;
      }
      return bound4.element;
    }
    return element53;
  }
}
class Identifier_4 extends Identifier {
  String name9;
  Identifier_4(this.name9) : super();
  accept(ASTVisitor visitor) => null;
  sc.Token get beginToken => null;
  Element get element => null;
  sc.Token get endToken => null;
  String get name => name9;
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
  AnalysisContextImpl _analysisContext;
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
  Library(AnalysisContextImpl analysisContext, AnalysisErrorListener errorListener, Source librarySource) {
    this._analysisContext = analysisContext;
    this._errorListener = errorListener;
    this._librarySource = librarySource;
    this._libraryElement = analysisContext.getLibraryElementOrNull(librarySource) as LibraryElementImpl;
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
      unit = _analysisContext.parse3(source, _errorListener);
      _astMap[source] = unit;
    }
    return unit;
  }
  /**
   * Return a collection containing the sources for the compilation units in this library.
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
      _libraryElement = _analysisContext.getLibraryElement(_librarySource) as LibraryElementImpl;
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
    return getSource2(getStringValue(uriLiteral));
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
    return _librarySource.resolve(uri);
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
  AnalysisContextImpl _analysisContext;
  /**
   * The listener to which errors will be reported.
   */
  AnalysisErrorListener _errorListener;
  /**
   * The name of the core library.
   */
  static String CORE_LIBRARY_URI = "dart:core";
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
    CompilationUnitBuilder builder = new CompilationUnitBuilder(_analysisContext, _errorListener);
    Source librarySource2 = library.librarySource;
    CompilationUnit definingCompilationUnit3 = library.definingCompilationUnit;
    CompilationUnitElementImpl definingCompilationUnitElement = builder.buildCompilationUnit2(librarySource2, definingCompilationUnit3);
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
        if (partSource != null) {
          CompilationUnitElementImpl part = builder.buildCompilationUnit(partSource);
          String partLibraryName = getPartLibraryName(library, partSource, directivesToResolve);
          if (partLibraryName == null) {
            _errorListener.onError(new AnalysisError.con2(librarySource2, partUri.offset, partUri.length, ResolverErrorCode.MISSING_PART_OF_DIRECTIVE, []));
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
  AnalysisContextImpl _analysisContext;
  /**
   * The listener to which analysis errors will be reported, this error listener is either
   * references {@link #recordingErrorListener}, or it unions the passed{@link AnalysisErrorListener} with the {@link #recordingErrorListener}.
   */
  AnalysisErrorListener _errorListener;
  /**
   * This error listener is used by the resolver to be able to call the listener and get back the
   * set of errors for each {@link Source}.
   * @see #recordErrors()
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
  LibraryResolver.con1(AnalysisContextImpl analysisContext) {
    _jtd_constructor_237_impl(analysisContext);
  }
  _jtd_constructor_237_impl(AnalysisContextImpl analysisContext) {
    _jtd_constructor_238_impl(analysisContext, null);
  }
  /**
   * Initialize a newly created library resolver to resolve libraries within the given context.
   * @param analysisContext the analysis context in which the library is being analyzed
   * @param errorListener the listener to which analysis errors will be reported
   */
  LibraryResolver.con2(AnalysisContextImpl analysisContext2, AnalysisErrorListener additionalAnalysisErrorListener) {
    _jtd_constructor_238_impl(analysisContext2, additionalAnalysisErrorListener);
  }
  _jtd_constructor_238_impl(AnalysisContextImpl analysisContext2, AnalysisErrorListener additionalAnalysisErrorListener) {
    this._analysisContext = analysisContext2;
    this._recordingErrorListener = new RecordingErrorListener();
    if (additionalAnalysisErrorListener == null) {
      this._errorListener = _recordingErrorListener;
    } else {
      this._errorListener = new AnalysisErrorListener_5(this, additionalAnalysisErrorListener);
    }
    _coreLibrarySource = analysisContext2.sourceFactory.forUri(LibraryElementBuilder.CORE_LIBRARY_URI);
  }
  /**
   * Return the analysis context in which the libraries are being analyzed.
   * @return the analysis context in which the libraries are being analyzed
   */
  AnalysisContextImpl get analysisContext => _analysisContext;
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
    Library targetLibrary = createLibrary(librarySource);
    _coreLibrary = _libraryMap[_coreLibrarySource];
    if (_coreLibrary == null) {
      _coreLibrary = createLibrary(_coreLibrarySource);
    }
    computeLibraryDependencies(targetLibrary);
    _librariesInCycles = computeLibrariesInCycles(targetLibrary);
    buildElementModels();
    buildDirectiveModels();
    _typeProvider = new TypeProviderImpl(_coreLibrary.libraryElement);
    buildTypeHierarchies();
    resolveReferencesAndTypes();
    if (fullAnalysis) {
      runAdditionalAnalyses();
    }
    recordLibraryElements();
    recordErrors();
    return targetLibrary.libraryElement;
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
        TypeResolverVisitor visitor = new TypeResolverVisitor(library, source, _typeProvider);
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
   * For each library, loop through the set of all {@link CompilationUnit}s recording the set of
   * resolution errors on each unit.
   */
  void recordErrors() {
    for (Library library in _librariesInCycles) {
      try {
        CompilationUnit definingUnit = library.definingCompilationUnit;
        definingUnit.resolutionErrors = _recordingErrorListener.getErrors2(library.librarySource);
      } on AnalysisException catch (e) {
        throw new AnalysisException();
      }
      Set<Source> sources = library.compilationUnitSources;
      for (Source source in sources) {
        try {
          CompilationUnit unit = library.getAST(source);
          unit.resolutionErrors = _recordingErrorListener.getErrors2(source);
        } on JavaException catch (e) {
          throw new AnalysisException();
        }
      }
    }
  }
  /**
   * As the final step in the process, record the resolved element models with the analysis context.
   */
  void recordLibraryElements() {
    Map<Source, LibraryElement> elementMap = new Map<Source, LibraryElement>();
    for (Library library in _librariesInCycles) {
      elementMap[library.librarySource] = library.libraryElement;
    }
    _analysisContext.recordLibraryElements(elementMap);
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
      ResolverVisitor visitor = new ResolverVisitor(library, source, _typeProvider);
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
class AnalysisErrorListener_5 implements AnalysisErrorListener {
  final LibraryResolver LibraryResolver_this;
  AnalysisErrorListener additionalAnalysisErrorListener;
  AnalysisErrorListener_5(this.LibraryResolver_this, this.additionalAnalysisErrorListener);
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
   * Initialize a newly created visitor to resolve the nodes in a compilation unit.
   * @param library the library containing the compilation unit being resolved
   * @param source the source representing the compilation unit being visited
   * @param typeProvider the object used to access the types from the core library
   */
  ResolverVisitor(Library library, Source source, TypeProvider typeProvider) : super(library, source, typeProvider) {
    this._elementResolver = new ElementResolver(this);
    this._typeAnalyzer = new StaticTypeAnalyzer(this);
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
      super.visitFunctionExpression(node);
    } finally {
      _enclosingFunction = outerFunction;
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
  Object visitNode(ASTNode node) {
    node.visitChildren(this);
    node.accept(_elementResolver);
    node.accept(_typeAnalyzer);
    return null;
  }
  Object visitPrefixedIdentifier(PrefixedIdentifier node) {
    SimpleIdentifier prefix7 = node.prefix;
    if (prefix7 != null) {
      prefix7.accept(this);
    }
    node.accept(_elementResolver);
    node.accept(_typeAnalyzer);
    return null;
  }
  Object visitPropertyAccess(PropertyAccess node) {
    Expression target4 = node.target;
    if (target4 != null) {
      target4.accept(this);
    }
    node.accept(_elementResolver);
    node.accept(_typeAnalyzer);
    return null;
  }
  Object visitRedirectingConstructorInvocation(RedirectingConstructorInvocation node) {
    ArgumentList argumentList10 = node.argumentList;
    if (argumentList10 != null) {
      argumentList10.accept(this);
    }
    node.accept(_elementResolver);
    node.accept(_typeAnalyzer);
    return null;
  }
  Object visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    ArgumentList argumentList11 = node.argumentList;
    if (argumentList11 != null) {
      argumentList11.accept(this);
    }
    node.accept(_elementResolver);
    node.accept(_typeAnalyzer);
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
  ScopedVisitor(Library library, Source source, TypeProvider typeProvider) {
    this._definingLibrary = library.libraryElement;
    this._source = source;
    LibraryScope libraryScope2 = library.libraryScope;
    this._errorListener = libraryScope2.errorListener;
    this._nameScope = libraryScope2;
    this._typeProvider = typeProvider;
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
      VariableElement element24 = node.element;
      if (element24 != null) {
        _nameScope.define(element24);
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
   * Initialize a newly created type analyzer.
   * @param resolver the resolver driving this participant
   */
  StaticTypeAnalyzer(ResolverVisitor resolver) {
    _typeProvider = resolver.typeProvider;
    _dynamicType = _typeProvider.dynamicType;
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
  Object visitAsExpression(AsExpression node) => recordType(node, getType3(node.type));
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
    return recordType(node, getType(node.rightHandSide));
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
  Object visitCascadeExpression(CascadeExpression node) => recordType(node, getType(node.target));
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
    Type2 thenType = getType(node.thenExpression);
    Type2 elseType = getType(node.elseExpression);
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
  Object visitInstanceCreationExpression(InstanceCreationExpression node) => recordType(node, node.constructorName.type.type);
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
        return recordType(node, _typeProvider.listType.substitute5(<Type2> [getType3(argumentType)]));
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
        return recordType(node, _typeProvider.mapType.substitute5(<Type2> [_typeProvider.stringType, getType3(valueType)]));
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
  Object visitMethodInvocation(MethodInvocation node) => recordReturnType(node, node.methodName.element);
  Object visitNamedExpression(NamedExpression node) => recordType(node, getType(node.expression));
  /**
   * The Dart Language Specification, 12.2: <blockquote>The static type of {@code null} is bottom.
   * </blockquote>
   */
  Object visitNullLiteral(NullLiteral node) => recordType(node, _typeProvider.bottomType);
  Object visitParenthesizedExpression(ParenthesizedExpression node) => recordType(node, getType(node.expression));
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
  Object visitPostfixExpression(PostfixExpression node) => recordType(node, getType(node.operand));
  /**
   * See {@link #visitSimpleIdentifier(SimpleIdentifier)}.
   */
  Object visitPrefixedIdentifier(PrefixedIdentifier node) {
    SimpleIdentifier prefixedIdentifier = node.identifier;
    Element element25 = prefixedIdentifier.element;
    if (element25 is VariableElement) {
      Type2 variableType = ((element25 as VariableElement)).type;
      recordType(prefixedIdentifier, variableType);
      return recordType(node, variableType);
    } else if (element25 is PropertyAccessorElement) {
      Type2 propertyType = getType2((element25 as PropertyAccessorElement));
      recordType(prefixedIdentifier, propertyType);
      return recordType(node, propertyType);
    } else if (element25 is MethodElement) {
      Type2 returnType = ((element25 as MethodElement)).type;
      recordType(prefixedIdentifier, returnType);
      return recordType(node, returnType);
    } else {
    }
    recordType(prefixedIdentifier, _dynamicType);
    return recordType(node, _dynamicType);
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
    Element element26 = propertyName2.element;
    if (element26 is MethodElement) {
      FunctionType type15 = ((element26 as MethodElement)).type;
      recordType(propertyName2, type15);
      return recordType(node, type15);
    } else if (element26 is PropertyAccessorElement) {
      Type2 propertyType = getType2((element26 as PropertyAccessorElement));
      recordType(propertyName2, propertyType);
      return recordType(node, propertyType);
    } else {
    }
    recordType(propertyName2, _dynamicType);
    return recordType(node, _dynamicType);
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
    Element element27 = node.element;
    if (element27 == null) {
      return recordType(node, _dynamicType);
    } else if (element27 is ClassElement) {
      if (isNotTypeLiteral(node)) {
        return recordType(node, ((element27 as ClassElement)).type);
      }
      return recordType(node, _typeProvider.typeType);
    } else if (element27 is TypeVariableElement) {
      return recordType(node, ((element27 as TypeVariableElement)).type);
    } else if (element27 is FunctionTypeAliasElement) {
      return recordType(node, ((element27 as FunctionTypeAliasElement)).type);
    } else if (element27 is VariableElement) {
      return recordType(node, ((element27 as VariableElement)).type);
    } else if (element27 is MethodElement) {
      return recordType(node, ((element27 as MethodElement)).type);
    } else if (element27 is PropertyAccessorElement) {
      return recordType(node, getType2((element27 as PropertyAccessorElement)));
    } else if (element27 is ExecutableElement) {
      return recordType(node, ((element27 as ExecutableElement)).type);
    } else if (element27 is PrefixElement) {
      return null;
    } else {
      return recordType(node, _dynamicType);
    }
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
  /**
   * Given a function declaration, compute the return type of the function. The return type of
   * functions with a block body is {@code dynamicType}, with an expression body it is the type of
   * the expression.
   * @param node the function expression whose return type is to be computed
   * @return the return type that was computed
   */
  Type2 computeReturnType(FunctionDeclaration node) {
    TypeName returnType7 = node.returnType;
    if (returnType7 == null) {
      return computeReturnType2(node.functionExpression);
    }
    return returnType7.type;
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
      return getType(((body4 as ExpressionFunctionBody)).expression);
    }
    return _dynamicType;
  }
  /**
   * Return the type of the given expression that is to be used for type analysis.
   * @param expression the expression whose type is to be returned
   * @return the type of the given expression
   */
  Type2 getType(Expression expression) {
    Type2 type = expression.staticType;
    if (type == null) {
      return _dynamicType;
    }
    return type;
  }
  /**
   * Return the type that should be recorded for a node that resolved to the given accessor.
   * @param accessor the accessor that the node resolved to
   * @return the type that should be recorded for a node that resolved to the given accessor
   */
  Type2 getType2(PropertyAccessorElement accessor) {
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
    return functionType.returnType;
  }
  /**
   * Return the type represented by the given type name.
   * @param typeName the type name representing the type to be returned
   * @return the type represented by the type name
   */
  Type2 getType3(TypeName typeName) {
    Type2 type16 = typeName.type;
    if (type16 == null) {
      return _dynamicType;
    }
    return type16;
  }
  /**
   * Return {@code true} if the given node is not a type literal.
   * @param node the node being tested
   * @return {@code true} if the given node is not a type literal
   */
  bool isNotTypeLiteral(SimpleIdentifier node) {
    ASTNode parent15 = node.parent;
    return parent15 is TypeName || (parent15 is PrefixedIdentifier && (parent15.parent is TypeName || identical(((parent15 as PrefixedIdentifier)).prefix, node))) || (parent15 is PropertyAccess && identical(((parent15 as PropertyAccess)).target, node)) || (parent15 is MethodInvocation && identical(node, ((parent15 as MethodInvocation)).target));
  }
  /**
   * Record that the static type of the given node is the type of the second argument to the method
   * represented by the given element.
   * @param expression the node whose type is to be recorded
   * @param element the element representing the method invoked by the given node
   */
  Object recordArgumentType(IndexExpression expression, MethodElement element) {
    if (element != null) {
      List<ParameterElement> parameters12 = element.parameters;
      if (parameters12 != null && parameters12.length == 2) {
        return recordType(expression, parameters12[1].type);
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
        Type2 returnType8 = propertyType.returnType;
        if (returnType8 is FunctionType) {
          Type2 innerReturnType = ((returnType8 as FunctionType)).returnType;
          if (innerReturnType != null) {
            return recordType(expression, innerReturnType);
          }
        }
        if (returnType8 != null) {
          return recordType(expression, returnType8);
        }
      }
    } else if (element is ExecutableElement) {
      FunctionType type17 = ((element as ExecutableElement)).type;
      if (type17 != null) {
        return recordType(expression, type17.returnType);
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
  void setTypeInformation(FunctionTypeImpl functionType, Type2 returnType11, FormalParameterList parameterList) {
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
    functionType.returnType = returnType11;
  }
  get thisType_J2DAccessor => _thisType;
  set thisType_J2DAccessor(__v) => _thisType = __v;
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
  TypeResolverVisitor(Library library, Source source, TypeProvider typeProvider) : super(library, source, typeProvider) {
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
        exceptionType = getType4(exceptionTypeName);
      }
      recordType(exception, exceptionType);
      Element element28 = exception.element;
      if (element28 is VariableElementImpl) {
        ((element28 as VariableElementImpl)).type = exceptionType;
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
      superclassType = resolveType(extendsClause4.superclass, CompileTimeErrorCode.EXTENDS_NON_CLASS, CompileTimeErrorCode.EXTENDS_NON_CLASS, null);
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
    InterfaceType superclassType = resolveType(node.superclass, CompileTimeErrorCode.EXTENDS_NON_CLASS, CompileTimeErrorCode.EXTENDS_NON_CLASS, null);
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
    ExecutableElementImpl element29 = node.element as ExecutableElementImpl;
    FunctionTypeImpl type = new FunctionTypeImpl.con1(element29);
    setTypeInformation(type, null, element29.parameters);
    type.returnType = ((element29.enclosingElement as ClassElement)).type;
    element29.type = type;
    return null;
  }
  Object visitDeclaredIdentifier(DeclaredIdentifier node) {
    super.visitDeclaredIdentifier(node);
    Type2 declaredType;
    TypeName typeName = node.type;
    if (typeName == null) {
      declaredType = _dynamicType;
    } else {
      declaredType = getType4(typeName);
    }
    LocalVariableElementImpl element30 = node.element as LocalVariableElementImpl;
    element30.type = declaredType;
    return null;
  }
  Object visitDefaultFormalParameter(DefaultFormalParameter node) {
    super.visitDefaultFormalParameter(node);
    return null;
  }
  Object visitFieldFormalParameter(FieldFormalParameter node) {
    super.visitFieldFormalParameter(node);
    Element element31 = node.identifier.element;
    if (element31 is ParameterElementImpl) {
      ParameterElementImpl parameter = element31 as ParameterElementImpl;
      Type2 type;
      TypeName typeName = node.type;
      if (typeName == null) {
        type = _dynamicType;
      } else {
        type = getType4(typeName);
      }
      parameter.type = type;
    } else {
    }
    return null;
  }
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    super.visitFunctionDeclaration(node);
    ExecutableElementImpl element32 = node.element as ExecutableElementImpl;
    FunctionTypeImpl type = new FunctionTypeImpl.con1(element32);
    setTypeInformation(type, node.returnType, element32.parameters);
    element32.type = type;
    return null;
  }
  Object visitFunctionTypeAlias(FunctionTypeAlias node) {
    super.visitFunctionTypeAlias(node);
    FunctionTypeAliasElementImpl element33 = node.element as FunctionTypeAliasElementImpl;
    FunctionTypeImpl type18 = element33.type as FunctionTypeImpl;
    setTypeInformation(type18, node.returnType, element33.parameters);
    return null;
  }
  Object visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    super.visitFunctionTypedFormalParameter(node);
    ParameterElementImpl element34 = node.identifier.element as ParameterElementImpl;
    FunctionTypeImpl type = new FunctionTypeImpl.con1((null as ExecutableElement));
    setTypeInformation(type, node.returnType, getElements(node.parameters));
    element34.type = type;
    return null;
  }
  Object visitMethodDeclaration(MethodDeclaration node) {
    super.visitMethodDeclaration(node);
    ExecutableElementImpl element35 = node.element as ExecutableElementImpl;
    FunctionTypeImpl type = new FunctionTypeImpl.con1(element35);
    setTypeInformation(type, node.returnType, element35.parameters);
    element35.type = type;
    if (element35 is PropertyAccessorElementImpl) {
      PropertyAccessorElementImpl accessor = element35 as PropertyAccessorElementImpl;
      PropertyInducingElementImpl variable5 = accessor.variable as PropertyInducingElementImpl;
      if (accessor.isGetter()) {
        variable5.type = type.returnType;
      } else if (variable5.type == null) {
        List<Type2> parameterTypes = type.normalParameterTypes;
        if (parameterTypes != null && parameterTypes.length > 0) {
          variable5.type = parameterTypes[0];
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
      declaredType = getType4(typeName);
    }
    Element element36 = node.identifier.element;
    if (element36 is ParameterElement) {
      ((element36 as ParameterElementImpl)).type = declaredType;
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
          SimpleIdentifier prefix8 = ((typeName as PrefixedIdentifier)).prefix;
          element = nameScope.lookup(prefix8, definingLibrary);
          if (element is PrefixElement) {
            return null;
          } else if (element != null) {
            name.name = ((typeName as PrefixedIdentifier)).identifier;
            name.period = ((typeName as PrefixedIdentifier)).period;
            node.name = prefix8;
            typeName = prefix8;
          }
        }
      }
    }
    if (element == null) {
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
    } else {
      setElement(typeName, _dynamicType.element);
      typeName.staticType = _dynamicType;
      node.type = _dynamicType;
      return null;
    }
    if (argumentList != null) {
      NodeList<TypeName> arguments6 = argumentList.arguments;
      int argumentCount = arguments6.length;
      List<Type2> parameters = getTypeArguments(type);
      int parameterCount = parameters.length;
      int count = Math.min(argumentCount, parameterCount);
      List<Type2> typeArguments = new List<Type2>();
      for (int i = 0; i < count; i++) {
        Type2 argumentType = getType4(arguments6[i]);
        if (argumentType != null) {
          typeArguments.add(argumentType);
        }
      }
      if (argumentCount != parameterCount) {
        reportError(getInvalidTypeParametersErrorCode(node), node, [typeName.name, argumentCount, parameterCount]);
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
      declaredType = getType4(typeName);
    }
    Element element37 = node.name.element;
    if (element37 is VariableElement) {
      ((element37 as VariableElementImpl)).type = declaredType;
      if (element37 is FieldElement) {
        FieldElement field = element37 as FieldElement;
        PropertyAccessorElementImpl getter5 = field.getter as PropertyAccessorElementImpl;
        FunctionTypeImpl getterType = new FunctionTypeImpl.con1(getter5);
        getterType.returnType = declaredType;
        getter5.type = getterType;
        PropertyAccessorElementImpl setter4 = field.setter as PropertyAccessorElementImpl;
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
    Element element38 = identifier.element;
    if (element38 is! ClassElementImpl) {
      return null;
    }
    return element38 as ClassElementImpl;
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
      ParameterElement element39 = parameter.identifier.element as ParameterElement;
      if (element39 != null) {
        elements.add(element39);
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
  Type2 getType4(TypeName typeName) {
    Type2 type19 = typeName.type;
    if (type19 == null) {
      return _dynamicType;
    }
    return type19;
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
      List<InterfaceType> mixinTypes2 = resolveTypes(withClause.mixinTypes, CompileTimeErrorCode.MIXIN_OF_NON_CLASS, CompileTimeErrorCode.MIXIN_OF_NON_CLASS, null);
      if (classElement != null) {
        classElement.mixins = mixinTypes2;
      }
    }
    if (implementsClause != null) {
      List<InterfaceType> interfaceTypes = resolveTypes(implementsClause.interfaces, CompileTimeErrorCode.IMPLEMENTS_NON_CLASS, CompileTimeErrorCode.IMPLEMENTS_NON_CLASS, null);
      if (classElement != null) {
        classElement.interfaces = interfaceTypes;
      }
    }
  }
  /**
   * Return the type specified by the given name.
   * @param typeName the type name specifying the type to be returned
   * @param undefinedError the error to produce if the type name is not defined
   * @param nonTypeError the error to produce if the type name is defined to be something other than
   * a type
   * @param nonInterfaceType the error to produce if the type is not an interface type
   * @return the type specified by the type name
   */
  InterfaceType resolveType(TypeName typeName, ErrorCode undefinedError, ErrorCode nonTypeError, ErrorCode nonInterfaceType) {
    Identifier name16 = typeName.name;
    Element element = nameScope.lookup(name16, definingLibrary);
    if (element == null) {
      reportError(undefinedError, name16, [name16.name]);
    } else if (element is ClassElement) {
      Type2 classType = ((element as ClassElement)).type;
      typeName.type = classType;
      if (classType is InterfaceType) {
        return classType as InterfaceType;
      }
      reportError(nonInterfaceType, name16, [name16.name]);
    } else if (element is MultiplyDefinedElement) {
      List<Element> elements = ((element as MultiplyDefinedElement)).conflictingElements;
      InterfaceType type = getType(elements);
      if (type != null) {
        typeName.type = type;
      }
    } else {
      reportError(nonTypeError, name16, [name16.name]);
    }
    return null;
  }
  /**
   * Resolve the types in the given list of type names.
   * @param typeNames the type names to be resolved
   * @param undefinedError the error to produce if the type name is not defined
   * @param nonTypeError the error to produce if the type name is defined to be something other than
   * a type
   * @param nonInterfaceType the error to produce if the type is not an interface type
   * @return an array containing all of the types that were resolved.
   */
  List<InterfaceType> resolveTypes(NodeList<TypeName> typeNames, ErrorCode undefinedError, ErrorCode nonTypeError, ErrorCode nonInterfaceType) {
    List<InterfaceType> types = new List<InterfaceType>();
    for (TypeName typeName in typeNames) {
      InterfaceType type = resolveType(typeName, undefinedError, nonTypeError, nonInterfaceType);
      if (type != null) {
        types.add(type);
      }
    }
    return new List.from(types);
  }
  void setElement(Identifier typeName, Element element54) {
    if (element54 != null) {
      if (typeName is SimpleIdentifier) {
        ((typeName as SimpleIdentifier)).element = element54;
      } else if (typeName is PrefixedIdentifier) {
        PrefixedIdentifier identifier = typeName as PrefixedIdentifier;
        identifier.identifier.element = element54;
        SimpleIdentifier prefix9 = identifier.prefix;
        Element prefixElement = nameScope.lookup(prefix9, definingLibrary);
        if (prefixElement != null) {
          prefix9.element = prefixElement;
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
  void setTypeInformation(FunctionTypeImpl functionType, TypeName returnType12, List<ParameterElement> parameters) {
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
    if (returnType12 == null) {
      functionType.returnType = _dynamicType;
    } else {
      functionType.returnType = returnType12.type;
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
      String name17 = functionElement.name;
      if (name17 != null && !name17.isEmpty) {
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
    _jtd_constructor_248_impl(outerScope, onSwitchStatement, onSwitchMember);
  }
  _jtd_constructor_248_impl(LabelScope outerScope, bool onSwitchStatement, bool onSwitchMember) {
    _jtd_constructor_249_impl(outerScope, EMPTY_LABEL, new LabelElementImpl(_EMPTY_LABEL_IDENTIFIER, onSwitchStatement, onSwitchMember));
  }
  /**
   * Initialize a newly created scope to represent the given label.
   * @param outerScope the label scope enclosing the new label scope
   * @param label the label defined in this scope
   * @param element the element to which the label resolves
   */
  LabelScope.con2(LabelScope outerScope2, String label4, LabelElement element19) {
    _jtd_constructor_249_impl(outerScope2, label4, element19);
  }
  _jtd_constructor_249_impl(LabelScope outerScope2, String label4, LabelElement element19) {
    this._outerScope = outerScope2;
    this._label = label4;
    this._element = element19;
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
    if (Scope.isPrivateName(name)) {
      return null;
    }
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
    addAll(definedNames2, namespace.definedNames);
  }
  /**
   * Add the given element to the given mapping table if it has a publicly visible name.
   * @param definedNames the mapping table to which the public name is to be added
   * @param element the element to be added
   */
  void addIfPublic(Map<String, Element> definedNames, Element element) {
    String name18 = element.name;
    if (name18 != null && !Scope.isPrivateName(name18)) {
      definedNames[name18] = element;
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
      addAll2(definedNames, ((library.context as AnalysisContextImpl)).getPublicNamespace(library));
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
    if (_definedNames.containsKey(name)) {
      errorListener.onError(getErrorForDuplicate(_definedNames[name], element));
    } else {
      _definedNames[name] = element;
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
  AnalysisError getErrorForDuplicate(Element existing, Element duplicate) => new AnalysisError.con2(source, duplicate.nameOffset, duplicate.name.length, CompileTimeErrorCode.DUPLICATE_DEFINITION, [existing.name]);
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
        String value10 = ((result as ValidResult)).value as String;
        if (keys.contains(value10)) {
          _errorReporter.reportError(StaticWarningCode.EQUAL_KEYS_IN_MAP, key4, []);
        } else {
          javaSetAdd(keys, value10);
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
    Expression initializer4 = node.initializer;
    if (initializer4 != null && node.isConst()) {
      EvaluationResultImpl result = validate(initializer4, CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE);
      VariableElementImpl element45 = node.element as VariableElementImpl;
      element45.evaluationResult = result;
    }
    return null;
  }
  /**
   * Validate that the given expression is a compile time constant. Return the value of the compile
   * time constant, or {@code null} if the expression is not a compile time constant.
   * @param expression the expression to be validated
   * @param errorCode the error code to be used if the expression is not a compile time constant
   * @return the value of the compile time constant
   */
  EvaluationResultImpl validate(Expression expression, ErrorCode errorCode4) {
    EvaluationResultImpl result = expression.accept(new ConstantVisitor());
    if (result is ErrorResult) {
      for (ErrorResult_ErrorData data in ((result as ErrorResult)).errorData) {
        if (identical(data.errorCode, CompileTimeErrorCode.COMPILE_TIME_CONSTANT_RAISES_EXCEPTION_DIVIDE_BY_ZERO)) {
          _errorReporter.reportError(data.errorCode, data.node, []);
        } else {
          _errorReporter.reportError(errorCode4, data.node, []);
        }
      }
    }
    return result;
  }
  /**
   * Validate that the default value associated with each of the parameters in the given list is a
   * compile time constant.
   * @param parameters the list of parameters to be validated
   */
  void validateDefaultValues(FormalParameterList parameters14) {
    if (parameters14 == null) {
      return;
    }
    for (FormalParameter parameter in parameters14.parameters) {
      if (parameter is DefaultFormalParameter) {
        DefaultFormalParameter defaultParameter = parameter as DefaultFormalParameter;
        Expression defaultValue2 = defaultParameter.defaultValue;
        if (defaultValue2 != null) {
          EvaluationResultImpl result = validate(defaultValue2, CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE);
          if (defaultParameter.isConst()) {
            VariableElementImpl element46 = parameter.element as VariableElementImpl;
            element46.evaluationResult = result;
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
   * The method or function that we are currently visiting, or {@code null} if we are not inside a
   * method or function.
   */
  ExecutableElement _currentFunction;
  ErrorVerifier(ErrorReporter errorReporter, LibraryElement currentLibrary, TypeProvider typeProvider) {
    this._errorReporter = errorReporter;
    this._currentLibrary = currentLibrary;
    this._typeProvider = typeProvider;
    _dynamicType = typeProvider.dynamicType;
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
  Object visitClassDeclaration(ClassDeclaration node) {
    checkForBuiltInIdentifierAsName(node.name, CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME);
    return super.visitClassDeclaration(node);
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
    ExecutableElement previousFunction = _currentFunction;
    try {
      _currentFunction = node.element;
      checkForConstConstructorWithNonFinalField(node);
      checkForConflictingConstructorNameAndMember(node);
      return super.visitConstructorDeclaration(node);
    } finally {
      _currentFunction = previousFunction;
    }
  }
  Object visitDoStatement(DoStatement node) {
    checkForNonBoolCondition(node.condition);
    return super.visitDoStatement(node);
  }
  Object visitFieldFormalParameter(FieldFormalParameter node) {
    checkForConstFormalParameter(node);
    return super.visitFieldFormalParameter(node);
  }
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    ExecutableElement previousFunction = _currentFunction;
    try {
      _currentFunction = node.element;
      return super.visitFunctionDeclaration(node);
    } finally {
      _currentFunction = previousFunction;
    }
  }
  Object visitFunctionExpression(FunctionExpression node) {
    ExecutableElement previousFunction = _currentFunction;
    try {
      _currentFunction = node.element;
      return super.visitFunctionExpression(node);
    } finally {
      _currentFunction = previousFunction;
    }
  }
  Object visitFunctionTypeAlias(FunctionTypeAlias node) {
    checkForBuiltInIdentifierAsName(node.name, CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME);
    return super.visitFunctionTypeAlias(node);
  }
  Object visitIfStatement(IfStatement node) {
    checkForNonBoolCondition(node.condition);
    return super.visitIfStatement(node);
  }
  Object visitInstanceCreationExpression(InstanceCreationExpression node) {
    ConstructorName constructorName4 = node.constructorName;
    TypeName typeName = constructorName4.type;
    Type2 type20 = typeName.type;
    if (type20 is InterfaceType) {
      InterfaceType interfaceType = type20 as InterfaceType;
      checkForConstWithNonConst(node);
      checkForConstOrNewWithAbstractClass(node, typeName, interfaceType);
      checkForTypeArgumentNotMatchingBounds(node, constructorName4.element, typeName);
    }
    return super.visitInstanceCreationExpression(node);
  }
  Object visitMethodDeclaration(MethodDeclaration node) {
    ExecutableElement previousFunction = _currentFunction;
    try {
      _currentFunction = node.element;
      return super.visitMethodDeclaration(node);
    } finally {
      _currentFunction = previousFunction;
    }
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
  Object visitTypeParameter(TypeParameter node) {
    checkForBuiltInIdentifierAsName(node.name, CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_VARIABLE_NAME);
    return super.visitTypeParameter(node);
  }
  Object visitVariableDeclarationList(VariableDeclarationList node) {
    checkForBuiltInIdentifierAsName2(node);
    return super.visitVariableDeclarationList(node);
  }
  Object visitWhileStatement(WhileStatement node) {
    checkForNonBoolCondition(node.condition);
    return super.visitWhileStatement(node);
  }
  /**
   * This verifies that the passed argument definition test identifier is a parameter.
   * @param node the {@link ArgumentDefinitionTest} to evaluate
   * @return return <code>true</code> if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#ARGUMENT_DEFINITION_TEST_NON_PARAMETER
   */
  bool checkForArgumentDefinitionTestNonParameter(ArgumentDefinitionTest node) {
    SimpleIdentifier identifier14 = node.identifier;
    Element element47 = identifier14.element;
    if (element47 != null && element47 is! ParameterElement) {
      _errorReporter.reportError(CompileTimeErrorCode.ARGUMENT_DEFINITION_TEST_NON_PARAMETER, identifier14, [identifier14.name]);
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
   * @return return <code>true</code> if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#BUILT_IN_IDENTIFIER_AS_TYPE_NAME
   * @see CompileTimeErrorCode#BUILT_IN_IDENTIFIER_AS_TYPE_VARIABLE_NAME
   * @see CompileTimeErrorCode#BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME
   */
  bool checkForBuiltInIdentifierAsName(SimpleIdentifier identifier, ErrorCode errorCode) {
    sc.Token token13 = identifier.token;
    if (identical(token13.type, sc.TokenType.KEYWORD)) {
      _errorReporter.reportError(errorCode, identifier, [identifier.name]);
      return true;
    }
    return false;
  }
  /**
   * This verifies that the passed variable declaration list does not have a built-in identifier.
   * @param node the variable declaration list to check
   * @return return <code>true</code> if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#BUILT_IN_IDENTIFIER_AS_TYPE
   */
  bool checkForBuiltInIdentifierAsName2(VariableDeclarationList node) {
    TypeName typeName = node.type;
    if (typeName != null) {
      Identifier identifier = typeName.name;
      if (identifier is SimpleIdentifier) {
        SimpleIdentifier simpleIdentifier = identifier as SimpleIdentifier;
        sc.Token token14 = simpleIdentifier.token;
        if (identical(token14.type, sc.TokenType.KEYWORD)) {
          if (((token14 as sc.KeywordToken)).keyword != sc.Keyword.DYNAMIC) {
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
   * @return return <code>true</code> if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS
   */
  bool checkForCaseExpressionTypeImplementsEquals(SwitchStatement node) {
    Expression expression16 = node.expression;
    Type2 type = expression16.staticType;
    if (type != null && type != _typeProvider.intType && type != _typeProvider.stringType) {
      Element element48 = type.element;
      if (element48 is ClassElement) {
        ClassElement classElement = element48 as ClassElement;
        MethodElement method = classElement.lookUpMethod("==", _currentLibrary);
        if (method != null && method.enclosingElement.type != _typeProvider.objectType) {
          _errorReporter.reportError(CompileTimeErrorCode.CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS, expression16, [element48.name]);
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
      String name20 = constructorName.name;
      ClassElement classElement = constructorElement.enclosingElement;
      List<FieldElement> fields3 = classElement.fields;
      for (FieldElement field in fields3) {
        if (field.name == name20) {
          _errorReporter.reportError(CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_NAME_AND_FIELD, node, [name20]);
          return true;
        }
      }
      List<MethodElement> methods3 = classElement.methods;
      for (MethodElement method in methods3) {
        if (method.name == name20) {
          _errorReporter.reportError(CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_NAME_AND_METHOD, node, [name20]);
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
   * @return return <code>true</code> if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD
   */
  bool checkForConstConstructorWithNonFinalField(ConstructorDeclaration node) {
    if (node.constKeyword == null) {
      return false;
    }
    ConstructorElement constructorElement = node.element;
    if (constructorElement != null) {
      ClassElement classElement = constructorElement.enclosingElement;
      List<FieldElement> elements = classElement.fields;
      for (FieldElement field in elements) {
        if (!field.isFinal() && !field.isConst() && !field.isSynthetic()) {
          _errorReporter.reportError(CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD, node, []);
          return true;
        }
      }
    }
    return false;
  }
  /**
   * This verifies that the passed normal formal parameter is not 'const'.
   * @param node the normal formal parameter to evaluate
   * @return return <code>true</code> if and only if an error code is generated on the passed node
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
   * @return return <code>true</code> if and only if an error code is generated on the passed node
   * @see StaticWarningCode#CONST_WITH_ABSTRACT_CLASS
   * @see StaticWarningCode#NEW_WITH_ABSTRACT_CLASS
   */
  bool checkForConstOrNewWithAbstractClass(InstanceCreationExpression node, TypeName typeName, InterfaceType type) {
    if (type.element.isAbstract()) {
      ConstructorElement element49 = node.element;
      if (element49 != null && !element49.isFactory()) {
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
   * @return return <code>true</code> if and only if an error code is generated on the passed node
   * @see CompileTimeErrorCode#CONST_WITH_NON_CONST
   */
  bool checkForConstWithNonConst(InstanceCreationExpression node) {
    if (node.isConst() && !node.element.isConst()) {
      _errorReporter.reportError(CompileTimeErrorCode.CONST_WITH_NON_CONST, node, []);
      return true;
    }
    return false;
  }
  /**
   * This verifies that the passed assignment expression represents a valid assignment.
   * @param node the assignment expression to evaluate
   * @return return <code>true</code> if and only if an error code is generated on the passed node
   * @see StaticTypeWarningCode#INVALID_ASSIGNMENT
   */
  bool checkForInvalidAssignment(AssignmentExpression node) {
    Expression lhs = node.leftHandSide;
    Expression rhs = node.rightHandSide;
    Type2 leftType = getType(lhs);
    Type2 rightType = getType(rhs);
    if (!rightType.isAssignableTo(leftType)) {
      _errorReporter.reportError(StaticTypeWarningCode.INVALID_ASSIGNMENT, rhs, [leftType.name, rightType.name]);
      return true;
    }
    return false;
  }
  /**
   * Checks to ensure that the expressions that need to be of type bool, are. Otherwise an error is
   * reported on the expression.
   * @param condition the conditional expression to test
   * @return return <code>true</code> if and only if an error code is generated on the passed node
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
   * @return return <code>true</code> if and only if an error code is generated on the passed node
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
   * This checks that the return type matches the type of the declared return type in the enclosing
   * method or function.
   * @param node the return statement to evaluate
   * @return return <code>true</code> if and only if an error code is generated on the passed node
   * @see StaticTypeWarningCode#RETURN_OF_INVALID_TYPE
   */
  bool checkForReturnOfInvalidType(ReturnStatement node) {
    FunctionType functionType = _currentFunction == null ? null : _currentFunction.type;
    Type2 expectedReturnType = functionType == null ? null : functionType.returnType;
    Expression returnExpression = node.expression;
    if (expectedReturnType != null && !expectedReturnType.isVoid() && returnExpression != null) {
      Type2 actualReturnType = getType(returnExpression);
      if (!actualReturnType.isAssignableTo(expectedReturnType)) {
        _errorReporter.reportError(StaticTypeWarningCode.RETURN_OF_INVALID_TYPE, returnExpression, [actualReturnType.name, expectedReturnType.name]);
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
   * @return return <code>true</code> if and only if an error code is generated on the passed node
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
}
/**
 * The enumeration {@code ResolverErrorCode} defines the error codes used for errors detected by the
 * resolver. The convention for this class is for the name of the error code to indicate the problem
 * that caused the error to be generated and for the error message to explain what is wrong and,
 * when appropriate, how the problem can be corrected.
 * @coverage dart.engine.resolver
 */
class ResolverErrorCode implements ErrorCode {
  static final ResolverErrorCode BREAK_LABEL_ON_SWITCH_MEMBER = new ResolverErrorCode('BREAK_LABEL_ON_SWITCH_MEMBER', 0, ErrorType.COMPILE_TIME_ERROR, "Break label resolves to case or default statement");
  static final ResolverErrorCode CANNOT_BE_RESOLVED = new ResolverErrorCode('CANNOT_BE_RESOLVED', 1, ErrorType.STATIC_WARNING, "Cannot resolve the name '%s'");
  static final ResolverErrorCode CONTINUE_LABEL_ON_SWITCH = new ResolverErrorCode('CONTINUE_LABEL_ON_SWITCH', 2, ErrorType.COMPILE_TIME_ERROR, "A continue label resolves to switch, must be loop or switch member");
  static final ResolverErrorCode MISSING_LIBRARY_DIRECTIVE_WITH_PART = new ResolverErrorCode('MISSING_LIBRARY_DIRECTIVE_WITH_PART', 3, ErrorType.COMPILE_TIME_ERROR, "Libraries that have parts must have a library directive");
  static final ResolverErrorCode MISSING_PART_OF_DIRECTIVE = new ResolverErrorCode('MISSING_PART_OF_DIRECTIVE', 4, ErrorType.COMPILE_TIME_ERROR, "The included part must have a part-of directive");
  static final List<ResolverErrorCode> values = [BREAK_LABEL_ON_SWITCH_MEMBER, CANNOT_BE_RESOLVED, CONTINUE_LABEL_ON_SWITCH, MISSING_LIBRARY_DIRECTIVE_WITH_PART, MISSING_PART_OF_DIRECTIVE];
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
  String toString() => __name;
}