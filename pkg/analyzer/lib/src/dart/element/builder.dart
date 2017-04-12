// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.dart.element.builder;

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';

/**
 * Instances of the class `ApiElementBuilder` traverse an AST structure and
 * build elements outside of function bodies and initializers.
 */
class ApiElementBuilder extends _BaseElementBuilder {
  /**
   * A table mapping field names to field elements for the fields defined in the current class, or
   * `null` if we are not in the scope of a class.
   */
  HashMap<String, FieldElement> _fieldMap;

  /**
   * Initialize a newly created element builder to build the elements for a
   * compilation unit. The [initialHolder] is the element holder to which the
   * children of the visited compilation unit node will be added.
   */
  ApiElementBuilder(ElementHolder initialHolder,
      CompilationUnitElementImpl compilationUnitElement)
      : super(initialHolder, compilationUnitElement);

  @override
  Object visitAnnotation(Annotation node) {
    // Although it isn't valid to do so because closures are not constant
    // expressions, it's possible for one of the arguments to the constructor to
    // contain a closure. Wrapping the processing of the annotation this way
    // prevents these closures from being added to the list of functions in the
    // annotated declaration.
    ElementHolder holder = new ElementHolder();
    ElementHolder previousHolder = _currentHolder;
    _currentHolder = holder;
    try {
      super.visitAnnotation(node);
    } finally {
      _currentHolder = previousHolder;
    }
    return null;
  }

  @override
  Object visitBlockFunctionBody(BlockFunctionBody node) {
    return null;
  }

  @override
  Object visitClassDeclaration(ClassDeclaration node) {
    ElementHolder holder = new ElementHolder();
    //
    // Process field declarations before constructors and methods so that field
    // formal parameters can be correctly resolved to their fields.
    //
    ElementHolder previousHolder = _currentHolder;
    _currentHolder = holder;
    try {
      List<ClassMember> nonFields = new List<ClassMember>();
      node.visitChildren(
          new _ElementBuilder_visitClassDeclaration(this, nonFields));
      _buildFieldMap(holder.fieldsWithoutFlushing);
      int count = nonFields.length;
      for (int i = 0; i < count; i++) {
        nonFields[i].accept(this);
      }
    } finally {
      _currentHolder = previousHolder;
    }
    SimpleIdentifier className = node.name;
    ClassElementImpl element = new ClassElementImpl.forNode(className);
    _setCodeRange(element, node);
    element.metadata = _createElementAnnotations(node.metadata);
    element.typeParameters = holder.typeParameters;
    setElementDocumentationComment(element, node);
    element.abstract = node.isAbstract;
    element.accessors = holder.accessors;
    List<ConstructorElement> constructors = holder.constructors;
    if (constructors.isEmpty) {
      constructors = _createDefaultConstructors(element);
    }
    element.constructors = constructors;
    element.fields = holder.fields;
    element.methods = holder.methods;
    _currentHolder.addType(element);
    className.staticElement = element;
    _fieldMap = null;
    holder.validate();
    return null;
  }

  @override
  Object visitClassTypeAlias(ClassTypeAlias node) {
    ElementHolder holder = new ElementHolder();
    _visitChildren(holder, node);
    SimpleIdentifier className = node.name;
    ClassElementImpl element = new ClassElementImpl.forNode(className);
    _setCodeRange(element, node);
    element.metadata = _createElementAnnotations(node.metadata);
    element.abstract = node.abstractKeyword != null;
    element.mixinApplication = true;
    element.typeParameters = holder.typeParameters;
    setElementDocumentationComment(element, node);
    _currentHolder.addType(element);
    className.staticElement = element;
    holder.validate();
    return null;
  }

  @override
  Object visitCompilationUnit(CompilationUnit node) {
    if (_unitElement is ElementImpl) {
      _setCodeRange(_unitElement, node);
    }
    return super.visitCompilationUnit(node);
  }

  @override
  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    ElementHolder holder = new ElementHolder();
    _visitChildren(holder, node);
    FunctionBody body = node.body;
    SimpleIdentifier constructorName = node.name;
    ConstructorElementImpl element =
        new ConstructorElementImpl.forNode(constructorName);
    _setCodeRange(element, node);
    element.metadata = _createElementAnnotations(node.metadata);
    setElementDocumentationComment(element, node);
    if (node.externalKeyword != null) {
      element.external = true;
    }
    if (node.factoryKeyword != null) {
      element.factory = true;
    }
    element.functions = holder.functions;
    element.labels = holder.labels;
    element.localVariables = holder.localVariables;
    element.parameters = holder.parameters;
    element.isConst = node.constKeyword != null;
    element.isCycleFree = element.isConst;
    if (body.isAsynchronous) {
      element.asynchronous = true;
    }
    if (body.isGenerator) {
      element.generator = true;
    }
    _currentHolder.addConstructor(element);
    node.element = element;
    if (constructorName == null) {
      Identifier returnType = node.returnType;
      if (returnType != null) {
        element.nameOffset = returnType.offset;
        element.nameEnd = returnType.end;
      }
    } else {
      constructorName.staticElement = element;
      element.periodOffset = node.period.offset;
      element.nameEnd = constructorName.end;
    }
    holder.validate();
    return null;
  }

  @override
  Object visitEnumDeclaration(EnumDeclaration node) {
    SimpleIdentifier enumName = node.name;
    EnumElementImpl enumElement = new EnumElementImpl.forNode(enumName);
    _setCodeRange(enumElement, node);
    enumElement.metadata = _createElementAnnotations(node.metadata);
    setElementDocumentationComment(enumElement, node);
    InterfaceTypeImpl enumType = enumElement.type;
    //
    // Build the elements for the constants. These are minimal elements; the
    // rest of the constant elements (and elements for other fields) must be
    // built later after we can access the type provider.
    //
    List<FieldElement> fields = new List<FieldElement>();
    NodeList<EnumConstantDeclaration> constants = node.constants;
    for (EnumConstantDeclaration constant in constants) {
      SimpleIdentifier constantName = constant.name;
      FieldElementImpl constantField =
          new ConstFieldElementImpl.forNode(constantName);
      constantField.isStatic = true;
      constantField.isConst = true;
      constantField.type = enumType;
      setElementDocumentationComment(constantField, constant);
      fields.add(constantField);
      new PropertyAccessorElementImpl_ImplicitGetter(constantField);
      constantName.staticElement = constantField;
    }
    enumElement.fields = fields;

    _currentHolder.addEnum(enumElement);
    enumName.staticElement = enumElement;
    return super.visitEnumDeclaration(node);
  }

  @override
  Object visitExportDirective(ExportDirective node) {
    List<ElementAnnotation> annotations =
        _createElementAnnotations(node.metadata);
    _unitElement.setAnnotations(node.offset, annotations);
    return super.visitExportDirective(node);
  }

  @override
  Object visitExpressionFunctionBody(ExpressionFunctionBody node) {
    return null;
  }

  @override
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    FunctionExpression expression = node.functionExpression;
    if (expression != null) {
      ElementHolder holder = new ElementHolder();
      _visitChildren(holder, node);
      FunctionBody body = expression.body;
      Token property = node.propertyKeyword;
      if (property == null) {
        SimpleIdentifier functionName = node.name;
        FunctionElementImpl element =
            new FunctionElementImpl.forNode(functionName);
        _setCodeRange(element, node);
        element.metadata = _createElementAnnotations(node.metadata);
        setElementDocumentationComment(element, node);
        if (node.externalKeyword != null || body is NativeFunctionBody) {
          element.external = true;
        }
        element.functions = holder.functions;
        element.labels = holder.labels;
        element.localVariables = holder.localVariables;
        element.parameters = holder.parameters;
        element.typeParameters = holder.typeParameters;
        if (body.isAsynchronous) {
          element.asynchronous = true;
        }
        if (body.isGenerator) {
          element.generator = true;
        }
        if (node.returnType == null) {
          element.hasImplicitReturnType = true;
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
        TopLevelVariableElementImpl variable = _currentHolder
            .getTopLevelVariable(propertyName) as TopLevelVariableElementImpl;
        if (variable == null) {
          variable = new TopLevelVariableElementImpl(node.name.name, -1);
          variable.isFinal = true;
          variable.isSynthetic = true;
          _currentHolder.addTopLevelVariable(variable);
        }
        if (node.isGetter) {
          PropertyAccessorElementImpl getter =
              new PropertyAccessorElementImpl.forNode(propertyNameNode);
          _setCodeRange(getter, node);
          getter.metadata = _createElementAnnotations(node.metadata);
          setElementDocumentationComment(getter, node);
          if (node.externalKeyword != null || body is NativeFunctionBody) {
            getter.external = true;
          }
          getter.functions = holder.functions;
          getter.labels = holder.labels;
          getter.localVariables = holder.localVariables;
          if (body.isAsynchronous) {
            getter.asynchronous = true;
          }
          if (body.isGenerator) {
            getter.generator = true;
          }
          getter.variable = variable;
          getter.getter = true;
          getter.isStatic = true;
          variable.getter = getter;
          if (node.returnType == null) {
            getter.hasImplicitReturnType = true;
          }
          _currentHolder.addAccessor(getter);
          expression.element = getter;
          propertyNameNode.staticElement = getter;
        } else {
          PropertyAccessorElementImpl setter =
              new PropertyAccessorElementImpl.forNode(propertyNameNode);
          _setCodeRange(setter, node);
          setter.metadata = _createElementAnnotations(node.metadata);
          setElementDocumentationComment(setter, node);
          if (node.externalKeyword != null || body is NativeFunctionBody) {
            setter.external = true;
          }
          setter.functions = holder.functions;
          setter.labels = holder.labels;
          setter.localVariables = holder.localVariables;
          setter.parameters = holder.parameters;
          if (body.isAsynchronous) {
            setter.asynchronous = true;
          }
          if (body.isGenerator) {
            setter.generator = true;
          }
          setter.variable = variable;
          setter.setter = true;
          setter.isStatic = true;
          if (node.returnType == null) {
            setter.hasImplicitReturnType = true;
          }
          variable.setter = setter;
          variable.isFinal = false;
          _currentHolder.addAccessor(setter);
          expression.element = setter;
          propertyNameNode.staticElement = setter;
        }
      }
      holder.validate();
    }
    return null;
  }

  @override
  Object visitFunctionExpression(FunctionExpression node) {
    if (node.parent is FunctionDeclaration) {
      // visitFunctionDeclaration has already created the element for the
      // declaration.  We just need to visit children.
      return super.visitFunctionExpression(node);
    }
    ElementHolder holder = new ElementHolder();
    _visitChildren(holder, node);
    FunctionBody body = node.body;
    FunctionElementImpl element =
        new FunctionElementImpl.forOffset(node.beginToken.offset);
    _setCodeRange(element, node);
    element.functions = holder.functions;
    element.labels = holder.labels;
    element.localVariables = holder.localVariables;
    element.parameters = holder.parameters;
    element.typeParameters = holder.typeParameters;
    if (body.isAsynchronous) {
      element.asynchronous = true;
    }
    if (body.isGenerator) {
      element.generator = true;
    }
    element.type = new FunctionTypeImpl(element);
    element.hasImplicitReturnType = true;
    _currentHolder.addFunction(element);
    node.element = element;
    holder.validate();
    return null;
  }

  @override
  Object visitFunctionTypeAlias(FunctionTypeAlias node) {
    ElementHolder holder = new ElementHolder();
    _visitChildren(holder, node);
    SimpleIdentifier aliasName = node.name;
    List<ParameterElement> parameters = holder.parameters;
    List<TypeParameterElement> typeParameters = holder.typeParameters;
    FunctionTypeAliasElementImpl element =
        new FunctionTypeAliasElementImpl.forNode(aliasName);
    _setCodeRange(element, node);
    element.metadata = _createElementAnnotations(node.metadata);
    setElementDocumentationComment(element, node);
    element.parameters = parameters;
    element.typeParameters = typeParameters;
    _createTypeParameterTypes(typeParameters);
    element.type = new FunctionTypeImpl.forTypedef(element);
    _currentHolder.addTypeAlias(element);
    aliasName.staticElement = element;
    holder.validate();
    return null;
  }

  @override
  Object visitGenericTypeAlias(GenericTypeAlias node) {
    ElementHolder holder = new ElementHolder();
    _visitChildren(holder, node);
    SimpleIdentifier aliasName = node.name;
    List<TypeParameterElement> typeParameters = holder.typeParameters;
    GenericTypeAliasElementImpl element =
        new GenericTypeAliasElementImpl.forNode(aliasName);
    _setCodeRange(element, node);
    element.metadata = _createElementAnnotations(node.metadata);
    setElementDocumentationComment(element, node);
    element.typeParameters = typeParameters;
    _createTypeParameterTypes(typeParameters);
    element.type = new FunctionTypeImpl.forTypedef(element);
    element.function = node.functionType?.type?.element;
    _currentHolder.addTypeAlias(element);
    aliasName.staticElement = element;
    holder.validate();
    return null;
  }

  @override
  Object visitImportDirective(ImportDirective node) {
    List<ElementAnnotation> annotations =
        _createElementAnnotations(node.metadata);
    _unitElement.setAnnotations(node.offset, annotations);
    return super.visitImportDirective(node);
  }

  @override
  Object visitLibraryDirective(LibraryDirective node) {
    List<ElementAnnotation> annotations =
        _createElementAnnotations(node.metadata);
    _unitElement.setAnnotations(node.offset, annotations);
    return super.visitLibraryDirective(node);
  }

  @override
  Object visitMethodDeclaration(MethodDeclaration node) {
    try {
      ElementHolder holder = new ElementHolder();
      _visitChildren(holder, node);
      bool isStatic = node.isStatic;
      Token property = node.propertyKeyword;
      FunctionBody body = node.body;
      if (property == null) {
        SimpleIdentifier methodName = node.name;
        String nameOfMethod = methodName.name;
        if (nameOfMethod == TokenType.MINUS.lexeme &&
            node.parameters.parameters.length == 0) {
          nameOfMethod = "unary-";
        }
        MethodElementImpl element =
            new MethodElementImpl(nameOfMethod, methodName.offset);
        _setCodeRange(element, node);
        element.metadata = _createElementAnnotations(node.metadata);
        setElementDocumentationComment(element, node);
        element.abstract = node.isAbstract;
        if (node.externalKeyword != null || body is NativeFunctionBody) {
          element.external = true;
        }
        element.functions = holder.functions;
        element.labels = holder.labels;
        element.localVariables = holder.localVariables;
        element.parameters = holder.parameters;
        element.isStatic = isStatic;
        element.typeParameters = holder.typeParameters;
        if (body.isAsynchronous) {
          element.asynchronous = true;
        }
        if (body.isGenerator) {
          element.generator = true;
        }
        if (node.returnType == null) {
          element.hasImplicitReturnType = true;
        }
        _currentHolder.addMethod(element);
        methodName.staticElement = element;
      } else {
        SimpleIdentifier propertyNameNode = node.name;
        String propertyName = propertyNameNode.name;
        FieldElementImpl field = _currentHolder.getField(propertyName,
            synthetic: true) as FieldElementImpl;
        if (field == null) {
          field = new FieldElementImpl(node.name.name, -1);
          field.isFinal = true;
          field.isStatic = isStatic;
          field.isSynthetic = true;
          _currentHolder.addField(field);
        }
        if (node.isGetter) {
          PropertyAccessorElementImpl getter =
              new PropertyAccessorElementImpl.forNode(propertyNameNode);
          _setCodeRange(getter, node);
          getter.metadata = _createElementAnnotations(node.metadata);
          setElementDocumentationComment(getter, node);
          if (node.externalKeyword != null || body is NativeFunctionBody) {
            getter.external = true;
          }
          getter.functions = holder.functions;
          getter.labels = holder.labels;
          getter.localVariables = holder.localVariables;
          if (body.isAsynchronous) {
            getter.asynchronous = true;
          }
          if (body.isGenerator) {
            getter.generator = true;
          }
          getter.variable = field;
          getter.abstract = node.isAbstract;
          getter.getter = true;
          getter.isStatic = isStatic;
          field.getter = getter;
          if (node.returnType == null) {
            getter.hasImplicitReturnType = true;
          }
          _currentHolder.addAccessor(getter);
          propertyNameNode.staticElement = getter;
        } else {
          PropertyAccessorElementImpl setter =
              new PropertyAccessorElementImpl.forNode(propertyNameNode);
          _setCodeRange(setter, node);
          setter.metadata = _createElementAnnotations(node.metadata);
          setElementDocumentationComment(setter, node);
          if (node.externalKeyword != null || body is NativeFunctionBody) {
            setter.external = true;
          }
          setter.functions = holder.functions;
          setter.labels = holder.labels;
          setter.localVariables = holder.localVariables;
          setter.parameters = holder.parameters;
          if (body.isAsynchronous) {
            setter.asynchronous = true;
          }
          if (body.isGenerator) {
            setter.generator = true;
          }
          setter.variable = field;
          setter.abstract = node.isAbstract;
          setter.setter = true;
          setter.isStatic = isStatic;
          if (node.returnType == null) {
            setter.hasImplicitReturnType = true;
          }
          field.setter = setter;
          field.isFinal = false;
          _currentHolder.addAccessor(setter);
          propertyNameNode.staticElement = setter;
        }
      }
      holder.validate();
    } catch (exception, stackTrace) {
      if (node.name.staticElement == null) {
        ClassDeclaration classNode =
            node.getAncestor((node) => node is ClassDeclaration);
        StringBuffer buffer = new StringBuffer();
        buffer.write("The element for the method ");
        buffer.write(node.name);
        buffer.write(" in ");
        buffer.write(classNode.name);
        buffer.write(" was not set while trying to build the element model.");
        AnalysisEngine.instance.logger.logError(
            buffer.toString(), new CaughtException(exception, stackTrace));
      } else {
        String message =
            "Exception caught in ElementBuilder.visitMethodDeclaration()";
        AnalysisEngine.instance.logger
            .logError(message, new CaughtException(exception, stackTrace));
      }
    } finally {
      if (node.name.staticElement == null) {
        ClassDeclaration classNode =
            node.getAncestor((node) => node is ClassDeclaration);
        StringBuffer buffer = new StringBuffer();
        buffer.write("The element for the method ");
        buffer.write(node.name);
        buffer.write(" in ");
        buffer.write(classNode.name);
        buffer.write(" was not set while trying to resolve types.");
        AnalysisEngine.instance.logger.logError(
            buffer.toString(),
            new CaughtException(
                new AnalysisException(buffer.toString()), null));
      }
    }
    return null;
  }

  @override
  Object visitPartDirective(PartDirective node) {
    List<ElementAnnotation> annotations =
        _createElementAnnotations(node.metadata);
    _unitElement.setAnnotations(node.offset, annotations);
    return super.visitPartDirective(node);
  }

  @override
  Object visitVariableDeclaration(VariableDeclaration node) {
    bool isConst = node.isConst;
    bool isFinal = node.isFinal;
    Expression initializerNode = node.initializer;
    bool hasInitializer = initializerNode != null;
    VariableDeclarationList varList = node.parent;
    FieldDeclaration fieldNode =
        varList.parent is FieldDeclaration ? varList.parent : null;
    VariableElementImpl element;
    if (fieldNode != null) {
      SimpleIdentifier fieldName = node.name;
      FieldElementImpl field;
      if ((isConst || isFinal && !fieldNode.isStatic) && hasInitializer) {
        field = new ConstFieldElementImpl.forNode(fieldName);
      } else {
        field = new FieldElementImpl.forNode(fieldName);
      }
      element = field;
      field.isCovariant = fieldNode.covariantKeyword != null;
      field.isStatic = fieldNode.isStatic;
      _setCodeRange(element, node);
      setElementDocumentationComment(element, fieldNode);
      field.hasImplicitType = varList.type == null;
      _currentHolder.addField(field);
      fieldName.staticElement = field;
    } else {
      SimpleIdentifier variableName = node.name;
      TopLevelVariableElementImpl variable;
      if (isConst && hasInitializer) {
        variable = new ConstTopLevelVariableElementImpl.forNode(variableName);
      } else {
        variable = new TopLevelVariableElementImpl.forNode(variableName);
      }
      element = variable;
      _setCodeRange(element, node);
      if (varList.parent is TopLevelVariableDeclaration) {
        setElementDocumentationComment(element, varList.parent);
      }
      variable.hasImplicitType = varList.type == null;
      _currentHolder.addTopLevelVariable(variable);
      variableName.staticElement = element;
    }
    element.isConst = isConst;
    element.isFinal = isFinal;
    if (element is PropertyInducingElementImpl) {
      PropertyAccessorElementImpl_ImplicitGetter getter =
          new PropertyAccessorElementImpl_ImplicitGetter(element);
      _currentHolder.addAccessor(getter);
      if (!isConst && !isFinal) {
        PropertyAccessorElementImpl_ImplicitSetter setter =
            new PropertyAccessorElementImpl_ImplicitSetter(element);
        if (fieldNode != null) {
          (setter.parameters[0] as ParameterElementImpl).isExplicitlyCovariant =
              fieldNode.covariantKeyword != null;
        }
        _currentHolder.addAccessor(setter);
      }
    }
    return null;
  }

  @override
  Object visitVariableDeclarationList(VariableDeclarationList node) {
    super.visitVariableDeclarationList(node);
    AstNode parent = node.parent;
    List<ElementAnnotation> elementAnnotations;
    if (parent is FieldDeclaration) {
      elementAnnotations = _createElementAnnotations(parent.metadata);
    } else if (parent is TopLevelVariableDeclaration) {
      elementAnnotations = _createElementAnnotations(parent.metadata);
    } else {
      // Local variable declaration
      elementAnnotations = _createElementAnnotations(node.metadata);
    }
    _setVariableDeclarationListAnnotations(node, elementAnnotations);
    return null;
  }

  /**
   * Build the table mapping field names to field elements for the [fields]
   * defined in the current class.
   */
  void _buildFieldMap(List<FieldElement> fields) {
    _fieldMap = new HashMap<String, FieldElement>();
    int count = fields.length;
    for (int i = 0; i < count; i++) {
      FieldElement field = fields[i];
      _fieldMap[field.name] ??= field;
    }
  }

  /**
   * Creates the [ConstructorElement]s array with the single default constructor element.
   *
   * @param interfaceType the interface type for which to create a default constructor
   * @return the [ConstructorElement]s array with the single default constructor element
   */
  List<ConstructorElement> _createDefaultConstructors(
      ClassElementImpl definingClass) {
    ConstructorElementImpl constructor =
        new ConstructorElementImpl.forNode(null);
    constructor.isSynthetic = true;
    constructor.enclosingElement = definingClass;
    return <ConstructorElement>[constructor];
  }

  /**
   * Create the types associated with the given type parameters, setting the type of each type
   * parameter, and return an array of types corresponding to the given parameters.
   *
   * @param typeParameters the type parameters for which types are to be created
   * @return an array of types corresponding to the given parameters
   */
  List<DartType> _createTypeParameterTypes(
      List<TypeParameterElement> typeParameters) {
    int typeParameterCount = typeParameters.length;
    List<DartType> typeArguments = new List<DartType>(typeParameterCount);
    for (int i = 0; i < typeParameterCount; i++) {
      TypeParameterElementImpl typeParameter =
          typeParameters[i] as TypeParameterElementImpl;
      TypeParameterTypeImpl typeParameterType =
          new TypeParameterTypeImpl(typeParameter);
      typeParameter.type = typeParameterType;
      typeArguments[i] = typeParameterType;
    }
    return typeArguments;
  }

  @override
  void _setFieldParameterField(
      FormalParameter node, FieldFormalParameterElementImpl element) {
    if (node.parent?.parent is ConstructorDeclaration) {
      FieldElement field = _fieldMap == null ? null : _fieldMap[element.name];
      if (field != null) {
        element.field = field;
      }
    }
  }
}

/**
 * A `CompilationUnitBuilder` builds an element model for a single compilation
 * unit.
 */
class CompilationUnitBuilder {
  /**
   * Build the compilation unit element for the given [source] based on the
   * compilation [unit] associated with the source. Throw an AnalysisException
   * if the element could not be built.  [librarySource] is the source for the
   * containing library.
   */
  CompilationUnitElementImpl buildCompilationUnit(
      Source source, CompilationUnit unit, Source librarySource) {
    return PerformanceStatistics.resolve.makeCurrentWhile(() {
      if (unit == null) {
        return null;
      }
      ElementHolder holder = new ElementHolder();
      CompilationUnitElementImpl element =
          new CompilationUnitElementImpl(source.shortName);
      ElementBuilder builder = new ElementBuilder(holder, element);
      unit.accept(builder);
      element.accessors = holder.accessors;
      element.enums = holder.enums;
      element.functions = holder.functions;
      element.source = source;
      element.librarySource = librarySource;
      element.typeAliases = holder.typeAliases;
      element.types = holder.types;
      element.topLevelVariables = holder.topLevelVariables;
      unit.element = element;
      holder.validate();
      return element;
    });
  }
}

/**
 * Instances of the class `DirectiveElementBuilder` build elements for top
 * level library directives.
 */
class DirectiveElementBuilder extends SimpleAstVisitor<Object> {
  /**
   * The analysis context within which directive elements are being built.
   */
  final AnalysisContext context;

  /**
   * The library element for which directive elements are being built.
   */
  final LibraryElementImpl libraryElement;

  /**
   * Map from sources referenced by this library to their modification times.
   */
  final Map<Source, int> sourceModificationTimeMap;

  /**
   * Map from sources imported by this library to their corresponding library
   * elements.
   */
  final Map<Source, LibraryElement> importLibraryMap;

  /**
   * Map from sources imported by this library to their corresponding source
   * kinds.
   */
  final Map<Source, SourceKind> importSourceKindMap;

  /**
   * Map from sources exported by this library to their corresponding library
   * elements.
   */
  final Map<Source, LibraryElement> exportLibraryMap;

  /**
   * Map from sources exported by this library to their corresponding source
   * kinds.
   */
  final Map<Source, SourceKind> exportSourceKindMap;

  /**
   * The [ImportElement]s created so far.
   */
  final List<ImportElement> imports = <ImportElement>[];

  /**
   * The [ExportElement]s created so far.
   */
  final List<ExportElement> exports = <ExportElement>[];

  /**
   * The errors found while building directive elements.
   */
  final List<AnalysisError> errors = <AnalysisError>[];

  /**
   * Map from prefix names to their corresponding elements.
   */
  final HashMap<String, PrefixElementImpl> nameToPrefixMap =
      new HashMap<String, PrefixElementImpl>();

  /**
   * Indicates whether an explicit import of `dart:core` has been found.
   */
  bool explicitlyImportsCore = false;

  DirectiveElementBuilder(
      this.context,
      this.libraryElement,
      this.sourceModificationTimeMap,
      this.importLibraryMap,
      this.importSourceKindMap,
      this.exportLibraryMap,
      this.exportSourceKindMap);

  @override
  Object visitCompilationUnit(CompilationUnit node) {
    //
    // Resolve directives.
    //
    for (Directive directive in node.directives) {
      directive.accept(this);
    }
    //
    // Ensure "dart:core" import.
    //
    Source librarySource = libraryElement.source;
    Source coreLibrarySource = context.sourceFactory.forUri(DartSdk.DART_CORE);
    if (!explicitlyImportsCore && coreLibrarySource != librarySource) {
      ImportElementImpl importElement = new ImportElementImpl(-1);
      importElement.importedLibrary = importLibraryMap[coreLibrarySource];
      importElement.isSynthetic = true;
      imports.add(importElement);
    }
    //
    // Populate the library element.
    //
    libraryElement.imports = imports;
    libraryElement.exports = exports;
    return null;
  }

  @override
  Object visitExportDirective(ExportDirective node) {
    // Remove previous element. (It will remain null if the target is missing.)
    node.element = null;
    Source exportedSource = node.selectedSource;
    int exportedTime = sourceModificationTimeMap[exportedSource] ?? -1;
    // The exported source will be null if the URI in the export
    // directive was invalid.
    LibraryElement exportedLibrary = exportLibraryMap[exportedSource];
    if (exportedLibrary != null) {
      ExportElementImpl exportElement = new ExportElementImpl(node.offset);
      exportElement.metadata = _getElementAnnotations(node.metadata);
      StringLiteral uriLiteral = node.uri;
      if (uriLiteral != null) {
        exportElement.uriOffset = uriLiteral.offset;
        exportElement.uriEnd = uriLiteral.end;
      }
      exportElement.uri = node.selectedUriContent;
      exportElement.combinators = _buildCombinators(node);
      exportElement.exportedLibrary = exportedLibrary;
      setElementDocumentationComment(exportElement, node);
      node.element = exportElement;
      exports.add(exportElement);
      if (exportedTime >= 0 &&
          exportSourceKindMap[exportedSource] != SourceKind.LIBRARY) {
        int offset = node.offset;
        int length = node.length;
        if (uriLiteral != null) {
          offset = uriLiteral.offset;
          length = uriLiteral.length;
        }
        errors.add(new AnalysisError(
            libraryElement.source,
            offset,
            length,
            CompileTimeErrorCode.EXPORT_OF_NON_LIBRARY,
            [uriLiteral.toSource()]));
      }
    }
    return null;
  }

  @override
  Object visitImportDirective(ImportDirective node) {
    // Remove previous element. (It will remain null if the target is missing.)
    node.element = null;
    Source importedSource = node.selectedSource;
    int importedTime = sourceModificationTimeMap[importedSource] ?? -1;
    // The imported source will be null if the URI in the import
    // directive was invalid.
    LibraryElement importedLibrary = importLibraryMap[importedSource];
    if (importedLibrary != null) {
      if (importedLibrary.isDartCore) {
        explicitlyImportsCore = true;
      }
      ImportElementImpl importElement = new ImportElementImpl(node.offset);
      importElement.metadata = _getElementAnnotations(node.metadata);
      StringLiteral uriLiteral = node.uri;
      if (uriLiteral != null) {
        importElement.uriOffset = uriLiteral.offset;
        importElement.uriEnd = uriLiteral.end;
      }
      importElement.uri = node.selectedUriContent;
      importElement.deferred = node.deferredKeyword != null;
      importElement.combinators = _buildCombinators(node);
      importElement.importedLibrary = importedLibrary;
      setElementDocumentationComment(importElement, node);
      SimpleIdentifier prefixNode = node.prefix;
      if (prefixNode != null) {
        importElement.prefixOffset = prefixNode.offset;
        String prefixName = prefixNode.name;
        PrefixElementImpl prefix = nameToPrefixMap[prefixName];
        if (prefix == null) {
          prefix = new PrefixElementImpl.forNode(prefixNode);
          nameToPrefixMap[prefixName] = prefix;
        }
        importElement.prefix = prefix;
        prefixNode.staticElement = prefix;
      }
      node.element = importElement;
      imports.add(importElement);
      if (importedTime >= 0 &&
          importSourceKindMap[importedSource] != SourceKind.LIBRARY) {
        int offset = node.offset;
        int length = node.length;
        if (uriLiteral != null) {
          offset = uriLiteral.offset;
          length = uriLiteral.length;
        }
        ErrorCode errorCode = importElement.isDeferred
            ? StaticWarningCode.IMPORT_OF_NON_LIBRARY
            : CompileTimeErrorCode.IMPORT_OF_NON_LIBRARY;
        errors.add(new AnalysisError(libraryElement.source, offset, length,
            errorCode, [uriLiteral.toSource()]));
      }
    }
    return null;
  }

  @override
  Object visitLibraryDirective(LibraryDirective node) {
    (node.element as LibraryElementImpl)?.metadata =
        _getElementAnnotations(node.metadata);
    return null;
  }

  @override
  Object visitPartDirective(PartDirective node) {
    (node.element as CompilationUnitElementImpl)?.metadata =
        _getElementAnnotations(node.metadata);
    return null;
  }

  /**
   * Gather a list of the [ElementAnnotation]s referred to by the [Annotation]s
   * in [metadata].
   */
  List<ElementAnnotation> _getElementAnnotations(
      NodeList<Annotation> metadata) {
    if (metadata.isEmpty) {
      return ElementAnnotation.EMPTY_LIST;
    }
    return metadata.map((Annotation a) => a.elementAnnotation).toList();
  }

  /**
   * Build the element model representing the combinators declared by
   * the given [directive].
   */
  static List<NamespaceCombinator> _buildCombinators(
      NamespaceDirective directive) {
    _NamespaceCombinatorBuilder namespaceCombinatorBuilder =
        new _NamespaceCombinatorBuilder();
    for (Combinator combinator in directive.combinators) {
      combinator.accept(namespaceCombinatorBuilder);
    }
    return namespaceCombinatorBuilder.combinators;
  }
}

/**
 * Instances of the class `ElementBuilder` traverse an AST structure and build the element
 * model representing the AST structure.
 */
class ElementBuilder extends ApiElementBuilder {
  /**
   * Initialize a newly created element builder to build the elements for a
   * compilation unit. The [initialHolder] is the element holder to which the
   * children of the visited compilation unit node will be added.
   */
  ElementBuilder(ElementHolder initialHolder,
      CompilationUnitElement compilationUnitElement)
      : super(initialHolder, compilationUnitElement);

  @override
  Object visitBlockFunctionBody(BlockFunctionBody node) {
    _buildLocal(node);
    return null;
  }

  @override
  Object visitDefaultFormalParameter(DefaultFormalParameter node) {
    super.visitDefaultFormalParameter(node);
    buildParameterInitializer(
        node.element as ParameterElementImpl, node.defaultValue);
    return null;
  }

  @override
  Object visitExpressionFunctionBody(ExpressionFunctionBody node) {
    _buildLocal(node);
    return null;
  }

  @override
  Object visitVariableDeclaration(VariableDeclaration node) {
    super.visitVariableDeclaration(node);
    VariableElementImpl element = node.element as VariableElementImpl;
    buildVariableInitializer(element, node.initializer);
    return null;
  }

  void _buildLocal(AstNode node) {
    node.accept(new LocalElementBuilder(_currentHolder, _unitElement));
  }
}

/**
 * Traverse a [FunctionBody] and build elements for AST structures.
 */
class LocalElementBuilder extends _BaseElementBuilder {
  /**
   * Initialize a newly created element builder to build the elements for a
   * compilation unit. The [initialHolder] is the element holder to which the
   * children of the visited compilation unit node will be added.
   */
  LocalElementBuilder(ElementHolder initialHolder,
      CompilationUnitElementImpl compilationUnitElement)
      : super(initialHolder, compilationUnitElement);

  /**
   * Builds the variable elements associated with [node] and stores them in
   * the element holder.
   */
  void buildCatchVariableElements(CatchClause node) {
    SimpleIdentifier exceptionParameter = node.exceptionParameter;
    if (exceptionParameter != null) {
      // exception
      LocalVariableElementImpl exception =
          new LocalVariableElementImpl.forNode(exceptionParameter);
      if (node.exceptionType == null) {
        exception.hasImplicitType = true;
      }
      exception.setVisibleRange(node.offset, node.length);
      _currentHolder.addLocalVariable(exception);
      exceptionParameter.staticElement = exception;
      // stack trace
      SimpleIdentifier stackTraceParameter = node.stackTraceParameter;
      if (stackTraceParameter != null) {
        LocalVariableElementImpl stackTrace =
            new LocalVariableElementImpl.forNode(stackTraceParameter);
        _setCodeRange(stackTrace, stackTraceParameter);
        stackTrace.setVisibleRange(node.offset, node.length);
        _currentHolder.addLocalVariable(stackTrace);
        stackTraceParameter.staticElement = stackTrace;
      }
    }
  }

  /**
   * Builds the label elements associated with [labels] and stores them in the
   * element holder.
   */
  void buildLabelElements(
      NodeList<Label> labels, bool onSwitchStatement, bool onSwitchMember) {
    for (Label label in labels) {
      SimpleIdentifier labelName = label.label;
      LabelElementImpl element = new LabelElementImpl.forNode(
          labelName, onSwitchStatement, onSwitchMember);
      labelName.staticElement = element;
      _currentHolder.addLabel(element);
    }
  }

  @override
  Object visitCatchClause(CatchClause node) {
    buildCatchVariableElements(node);
    return super.visitCatchClause(node);
  }

  @override
  Object visitDeclaredIdentifier(DeclaredIdentifier node) {
    SimpleIdentifier variableName = node.identifier;
    LocalVariableElementImpl element =
        new LocalVariableElementImpl.forNode(variableName);
    _setCodeRange(element, node);
    element.metadata = _createElementAnnotations(node.metadata);
    ForEachStatement statement = node.parent as ForEachStatement;
    element.setVisibleRange(statement.offset, statement.length);
    element.isConst = node.isConst;
    element.isFinal = node.isFinal;
    if (node.type == null) {
      element.hasImplicitType = true;
    }
    _currentHolder.addLocalVariable(element);
    variableName.staticElement = element;
    return null;
  }

  @override
  Object visitDefaultFormalParameter(DefaultFormalParameter node) {
    super.visitDefaultFormalParameter(node);
    buildParameterInitializer(
        node.element as ParameterElementImpl, node.defaultValue);
    return null;
  }

  @override
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    FunctionExpression expression = node.functionExpression;
    if (expression == null) {
      return null;
    }

    ElementHolder holder = new ElementHolder();
    _visitChildren(holder, node);

    FunctionElementImpl element = new FunctionElementImpl.forNode(node.name);
    _setCodeRange(element, node);
    setElementDocumentationComment(element, node);
    element.metadata = _createElementAnnotations(node.metadata);
    FunctionBody body = expression.body;
    if (node.externalKeyword != null || body is NativeFunctionBody) {
      element.external = true;
    }
    element.functions = holder.functions;
    element.labels = holder.labels;
    element.localVariables = holder.localVariables;
    element.parameters = holder.parameters;
    element.typeParameters = holder.typeParameters;

    if (body.isAsynchronous) {
      element.asynchronous = body.isAsynchronous;
    }
    if (body.isGenerator) {
      element.generator = true;
    }

    {
      Block enclosingBlock = node.getAncestor((node) => node is Block);
      if (enclosingBlock != null) {
        element.setVisibleRange(enclosingBlock.offset, enclosingBlock.length);
      }
    }

    if (node.returnType == null) {
      element.hasImplicitReturnType = true;
    }

    _currentHolder.addFunction(element);
    expression.element = element;
    node.name.staticElement = element;
    holder.validate();
    return null;
  }

  @override
  Object visitFunctionExpression(FunctionExpression node) {
    if (node.parent is FunctionDeclaration) {
      // visitFunctionDeclaration has already created the element for the
      // declaration.  We just need to visit children.
      return super.visitFunctionExpression(node);
    }

    ElementHolder holder = new ElementHolder();
    _visitChildren(holder, node);
    FunctionElementImpl element =
        new FunctionElementImpl.forOffset(node.beginToken.offset);
    _setCodeRange(element, node);
    element.functions = holder.functions;
    element.labels = holder.labels;
    element.localVariables = holder.localVariables;
    element.parameters = holder.parameters;
    element.typeParameters = holder.typeParameters;

    FunctionBody body = node.body;
    if (body.isAsynchronous) {
      element.asynchronous = true;
    }
    if (body.isGenerator) {
      element.generator = true;
    }

    {
      Block enclosingBlock = node.getAncestor((node) => node is Block);
      if (enclosingBlock != null) {
        element.setVisibleRange(enclosingBlock.offset, enclosingBlock.length);
      }
    }

    element.type = new FunctionTypeImpl(element);
    element.hasImplicitReturnType = true;
    _currentHolder.addFunction(element);
    node.element = element;
    holder.validate();
    return null;
  }

  @override
  Object visitLabeledStatement(LabeledStatement node) {
    bool onSwitchStatement = node.statement is SwitchStatement;
    buildLabelElements(node.labels, onSwitchStatement, false);
    return super.visitLabeledStatement(node);
  }

  @override
  Object visitSwitchCase(SwitchCase node) {
    buildLabelElements(node.labels, false, true);
    return super.visitSwitchCase(node);
  }

  @override
  Object visitSwitchDefault(SwitchDefault node) {
    buildLabelElements(node.labels, false, true);
    return super.visitSwitchDefault(node);
  }

  @override
  Object visitVariableDeclaration(VariableDeclaration node) {
    bool isConst = node.isConst;
    bool isFinal = node.isFinal;
    Expression initializerNode = node.initializer;
    VariableDeclarationList varList = node.parent;
    SimpleIdentifier variableName = node.name;
    LocalVariableElementImpl element;
    if (isConst && initializerNode != null) {
      element = new ConstLocalVariableElementImpl.forNode(variableName);
    } else {
      element = new LocalVariableElementImpl.forNode(variableName);
    }
    _setCodeRange(element, node);
    _setVariableVisibleRange(element, node);
    element.hasImplicitType = varList.type == null;
    _currentHolder.addLocalVariable(element);
    variableName.staticElement = element;
    element.isConst = isConst;
    element.isFinal = isFinal;
    buildVariableInitializer(element, initializerNode);
    return null;
  }

  @override
  Object visitVariableDeclarationList(VariableDeclarationList node) {
    super.visitVariableDeclarationList(node);
    List<ElementAnnotation> elementAnnotations =
        _createElementAnnotations(node.metadata);
    _setVariableDeclarationListAnnotations(node, elementAnnotations);
    return null;
  }

  void _setVariableVisibleRange(
      LocalVariableElementImpl element, VariableDeclaration node) {
    AstNode scopeNode;
    AstNode parent2 = node.parent.parent;
    if (parent2 is ForStatement) {
      scopeNode = parent2;
    } else {
      scopeNode = node.getAncestor((node) => node is Block);
    }
    element.setVisibleRange(scopeNode.offset, scopeNode.length);
  }
}

/**
 * Base class for API and local element builders.
 */
abstract class _BaseElementBuilder extends RecursiveAstVisitor<Object> {
  /**
   * The compilation unit element into which the elements being built will be
   * stored.
   */
  final CompilationUnitElementImpl _unitElement;

  /**
   * The element holder associated with the element that is currently being built.
   */
  ElementHolder _currentHolder;

  _BaseElementBuilder(this._currentHolder, this._unitElement);

  /**
   * If the [defaultValue] is not `null`, build the [FunctionElementImpl]
   * that corresponds it, and set it as the initializer for the [parameter].
   */
  void buildParameterInitializer(
      ParameterElementImpl parameter, Expression defaultValue) {
    if (defaultValue != null) {
      ElementHolder holder = new ElementHolder();
      _visit(holder, defaultValue);
      FunctionElementImpl initializer =
          new FunctionElementImpl.forOffset(defaultValue.beginToken.offset);
      initializer.hasImplicitReturnType = true;
      initializer.functions = holder.functions;
      initializer.labels = holder.labels;
      initializer.localVariables = holder.localVariables;
      initializer.parameters = holder.parameters;
      initializer.isSynthetic = true;
      initializer.type = new FunctionTypeImpl(initializer);
      parameter.initializer = initializer;
      parameter.defaultValueCode = defaultValue.toSource();
      holder.validate();
    }
  }

  /**
   * If the [initializer] is not `null`, build the [FunctionElementImpl] that
   * corresponds it, and set it as the initializer for the [variable].
   */
  void buildVariableInitializer(
      VariableElementImpl variable, Expression initializer) {
    if (initializer != null) {
      ElementHolder holder = new ElementHolder();
      _visit(holder, initializer);
      FunctionElementImpl initializerElement =
          new FunctionElementImpl.forOffset(initializer.beginToken.offset);
      initializerElement.hasImplicitReturnType = true;
      initializerElement.functions = holder.functions;
      initializerElement.labels = holder.labels;
      initializerElement.localVariables = holder.localVariables;
      initializerElement.isSynthetic = true;
      initializerElement.type = new FunctionTypeImpl(initializerElement);
      variable.initializer = initializerElement;
      holder.validate();
    }
  }

  @override
  Object visitDefaultFormalParameter(DefaultFormalParameter node) {
    NormalFormalParameter normalParameter = node.parameter;
    SimpleIdentifier parameterName = normalParameter.identifier;
    ParameterElementImpl parameter;
    if (normalParameter is FieldFormalParameter) {
      DefaultFieldFormalParameterElementImpl fieldParameter =
          new DefaultFieldFormalParameterElementImpl.forNode(parameterName);
      _setFieldParameterField(node, fieldParameter);
      parameter = fieldParameter;
    } else {
      parameter = new DefaultParameterElementImpl.forNode(parameterName);
    }
    _setCodeRange(parameter, node);
    parameter.isConst = node.isConst;
    parameter.isExplicitlyCovariant = node.parameter.covariantKeyword != null;
    parameter.isFinal = node.isFinal;
    parameter.parameterKind = node.kind;
    // visible range
    _setParameterVisibleRange(node, parameter);
    if (normalParameter is SimpleFormalParameter &&
        normalParameter.type == null) {
      parameter.hasImplicitType = true;
    }
    _currentHolder.addParameter(parameter);
    if (normalParameter is SimpleFormalParameterImpl) {
      normalParameter.element = parameter;
    }
    parameterName?.staticElement = parameter;
    normalParameter.accept(this);
    return null;
  }

  @override
  Object visitFieldFormalParameter(FieldFormalParameter node) {
    if (node.parent is! DefaultFormalParameter) {
      SimpleIdentifier parameterName = node.identifier;
      FieldFormalParameterElementImpl parameter =
          new FieldFormalParameterElementImpl.forNode(parameterName);
      _setCodeRange(parameter, node);
      _setFieldParameterField(node, parameter);
      parameter.isConst = node.isConst;
      parameter.isExplicitlyCovariant = node.covariantKeyword != null;
      parameter.isFinal = node.isFinal;
      parameter.parameterKind = node.kind;
      _currentHolder.addParameter(parameter);
      parameterName.staticElement = parameter;
    }
    //
    // The children of this parameter include any parameters defined on the type
    // of this parameter.
    //
    ElementHolder holder = new ElementHolder();
    _visitChildren(holder, node);
    ParameterElementImpl element = node.element;
    element.metadata = _createElementAnnotations(node.metadata);
    element.parameters = holder.parameters;
    element.typeParameters = holder.typeParameters;
    holder.validate();
    return null;
  }

  @override
  Object visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    if (node.parent is! DefaultFormalParameter) {
      SimpleIdentifier parameterName = node.identifier;
      ParameterElementImpl parameter =
          new ParameterElementImpl.forNode(parameterName);
      _setCodeRange(parameter, node);
      parameter.isConst = node.isConst;
      parameter.isExplicitlyCovariant = node.covariantKeyword != null;
      parameter.isFinal = node.isFinal;
      parameter.parameterKind = node.kind;
      _setParameterVisibleRange(node, parameter);
      _currentHolder.addParameter(parameter);
      parameterName.staticElement = parameter;
    }
    //
    // The children of this parameter include any parameters defined on the type
    //of this parameter.
    //
    ElementHolder holder = new ElementHolder();
    _visitChildren(holder, node);
    ParameterElementImpl element = node.element;
    element.metadata = _createElementAnnotations(node.metadata);
    element.parameters = holder.parameters;
    element.typeParameters = holder.typeParameters;
    holder.validate();
    return null;
  }

  @override
  Object visitGenericFunctionType(GenericFunctionType node) {
    ElementHolder holder = new ElementHolder();
    _visitChildren(holder, node);
    GenericFunctionTypeElementImpl element =
        new GenericFunctionTypeElementImpl.forOffset(node.beginToken.offset);
    _setCodeRange(element, node);
    element.parameters = holder.parameters;
    element.typeParameters = holder.typeParameters;
    FunctionType type = new FunctionTypeImpl(element);
    element.type = type;
    (node as GenericFunctionTypeImpl).type = type;
    holder.validate();
    return null;
  }

  @override
  Object visitSimpleFormalParameter(SimpleFormalParameter node) {
    ParameterElementImpl parameter;
    if (node.parent is! DefaultFormalParameter) {
      SimpleIdentifier parameterName = node.identifier;
      parameter = new ParameterElementImpl.forNode(parameterName);
      _setCodeRange(parameter, node);
      parameter.isConst = node.isConst;
      parameter.isExplicitlyCovariant = node.covariantKeyword != null;
      parameter.isFinal = node.isFinal;
      parameter.parameterKind = node.kind;
      _setParameterVisibleRange(node, parameter);
      if (node.type == null) {
        parameter.hasImplicitType = true;
      }
      _currentHolder.addParameter(parameter);
      (node as SimpleFormalParameterImpl).element = parameter;
      parameterName?.staticElement = parameter;
    }
    super.visitSimpleFormalParameter(node);
    parameter ??= node.element;
    parameter?.metadata = _createElementAnnotations(node.metadata);
    return null;
  }

  @override
  Object visitTypeParameter(TypeParameter node) {
    SimpleIdentifier parameterName = node.name;
    TypeParameterElementImpl typeParameter =
        new TypeParameterElementImpl.forNode(parameterName);
    _setCodeRange(typeParameter, node);
    typeParameter.metadata = _createElementAnnotations(node.metadata);
    TypeParameterTypeImpl typeParameterType =
        new TypeParameterTypeImpl(typeParameter);
    typeParameter.type = typeParameterType;
    _currentHolder.addTypeParameter(typeParameter);
    parameterName.staticElement = typeParameter;
    return super.visitTypeParameter(node);
  }

  /**
   * For each [Annotation] found in [annotations], create a new
   * [ElementAnnotation] object and set the [Annotation] to point to it.
   */
  List<ElementAnnotation> _createElementAnnotations(
      NodeList<Annotation> annotations) {
    if (annotations.isEmpty) {
      return ElementAnnotation.EMPTY_LIST;
    }
    return annotations.map((Annotation a) {
      ElementAnnotationImpl elementAnnotation =
          new ElementAnnotationImpl(_unitElement);
      a.elementAnnotation = elementAnnotation;
      return elementAnnotation;
    }).toList();
  }

  /**
   * Return the body of the function that contains the given [parameter], or
   * `null` if no function body could be found.
   */
  FunctionBody _getFunctionBody(FormalParameter parameter) {
    AstNode parent = parameter?.parent?.parent;
    if (parent is ConstructorDeclaration) {
      return parent.body;
    } else if (parent is FunctionExpression) {
      return parent.body;
    } else if (parent is MethodDeclaration) {
      return parent.body;
    }
    return null;
  }

  void _setCodeRange(ElementImpl element, AstNode node) {
    element.setCodeRange(node.offset, node.length);
  }

  void _setFieldParameterField(
      FormalParameter node, FieldFormalParameterElementImpl element) {}

  /**
   * Sets the visible source range for formal parameter.
   */
  void _setParameterVisibleRange(
      FormalParameter node, ParameterElementImpl element) {
    FunctionBody body = _getFunctionBody(node);
    if (body is BlockFunctionBody || body is ExpressionFunctionBody) {
      element.setVisibleRange(body.offset, body.length);
    }
  }

  void _setVariableDeclarationListAnnotations(VariableDeclarationList node,
      List<ElementAnnotation> elementAnnotations) {
    for (VariableDeclaration variableDeclaration in node.variables) {
      ElementImpl element = variableDeclaration.element as ElementImpl;
      _setCodeRange(element, node.parent);
      element.metadata = elementAnnotations;
    }
  }

  /**
   * Make the given holder be the current holder while visiting the given node.
   *
   * @param holder the holder that will gather elements that are built while visiting the children
   * @param node the node to be visited
   */
  void _visit(ElementHolder holder, AstNode node) {
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
  void _visitChildren(ElementHolder holder, AstNode node) {
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

class _ElementBuilder_visitClassDeclaration extends UnifyingAstVisitor<Object> {
  final ApiElementBuilder builder;

  List<ClassMember> nonFields;

  _ElementBuilder_visitClassDeclaration(this.builder, this.nonFields) : super();

  @override
  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    nonFields.add(node);
    return null;
  }

  @override
  Object visitMethodDeclaration(MethodDeclaration node) {
    nonFields.add(node);
    return null;
  }

  @override
  Object visitNode(AstNode node) => node.accept(builder);
}

/**
 * Instances of the class [_NamespaceCombinatorBuilder] can be used to visit
 * [Combinator] AST nodes and generate [NamespaceCombinator] elements.
 */
class _NamespaceCombinatorBuilder extends SimpleAstVisitor<Object> {
  /**
   * Elements generated so far.
   */
  final List<NamespaceCombinator> combinators = <NamespaceCombinator>[];

  @override
  Object visitHideCombinator(HideCombinator node) {
    HideElementCombinatorImpl hide = new HideElementCombinatorImpl();
    hide.hiddenNames = _getIdentifiers(node.hiddenNames);
    combinators.add(hide);
    return null;
  }

  @override
  Object visitShowCombinator(ShowCombinator node) {
    ShowElementCombinatorImpl show = new ShowElementCombinatorImpl();
    show.offset = node.offset;
    show.end = node.end;
    show.shownNames = _getIdentifiers(node.shownNames);
    combinators.add(show);
    return null;
  }

  /**
   * Return the lexical identifiers associated with the given [identifiers].
   */
  static List<String> _getIdentifiers(NodeList<SimpleIdentifier> identifiers) {
    return identifiers.map((identifier) => identifier.name).toList();
  }
}
