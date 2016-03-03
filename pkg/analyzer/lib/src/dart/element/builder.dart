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
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';

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
      importElement.synthetic = true;
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
    Source exportedSource = node.source;
    if (exportedSource != null && context.exists(exportedSource)) {
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
        exportElement.uri = node.uriContent;
        exportElement.combinators = _buildCombinators(node);
        exportElement.exportedLibrary = exportedLibrary;
        setElementDocumentationComment(exportElement, node);
        node.element = exportElement;
        exports.add(exportElement);
        if (exportSourceKindMap[exportedSource] != SourceKind.LIBRARY) {
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
    }
    return null;
  }

  @override
  Object visitImportDirective(ImportDirective node) {
    // Remove previous element. (It will remain null if the target is missing.)
    node.element = null;

    String uriContent = node.uriContent;
    if (DartUriResolver.isDartExtUri(uriContent)) {
      libraryElement.hasExtUri = true;
    }
    Source importedSource = node.source;
    if (importedSource != null && context.exists(importedSource)) {
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
        importElement.uri = uriContent;
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
        if (importSourceKindMap[importedSource] != SourceKind.LIBRARY) {
          int offset = node.offset;
          int length = node.length;
          if (uriLiteral != null) {
            offset = uriLiteral.offset;
            length = uriLiteral.length;
          }
          ErrorCode errorCode = (importElement.isDeferred
              ? StaticWarningCode.IMPORT_OF_NON_LIBRARY
              : CompileTimeErrorCode.IMPORT_OF_NON_LIBRARY);
          errors.add(new AnalysisError(libraryElement.source, offset, length,
              errorCode, [uriLiteral.toSource()]));
        }
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
class ElementBuilder extends RecursiveAstVisitor<Object> {
  /**
   * The compilation unit element into which the elements being built will be
   * stored.
   */
  final CompilationUnitElement compilationUnitElement;

  /**
   * The element holder associated with the element that is currently being built.
   */
  ElementHolder _currentHolder;

  /**
   * A flag indicating whether a variable declaration is within the body of a method or function.
   */
  bool _inFunction = false;

  /**
   * A collection holding the elements defined in a class that need to have
   * their function type fixed to take into account type parameters of the
   * enclosing class, or `null` if we are not currently processing nodes within
   * a class.
   */
  List<ExecutableElementImpl> _functionTypesToFix = null;

  /**
   * A table mapping field names to field elements for the fields defined in the current class, or
   * `null` if we are not in the scope of a class.
   */
  HashMap<String, FieldElement> _fieldMap;

  /**
   * Initialize a newly created element builder to build the elements for a compilation unit.
   *
   * @param initialHolder the element holder associated with the compilation unit being built
   */
  ElementBuilder(ElementHolder initialHolder, this.compilationUnitElement) {
    _currentHolder = initialHolder;
  }

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
  Object visitCatchClause(CatchClause node) {
    SimpleIdentifier exceptionParameter = node.exceptionParameter;
    if (exceptionParameter != null) {
      // exception
      LocalVariableElementImpl exception =
          new LocalVariableElementImpl.forNode(exceptionParameter);
      if (node.exceptionType == null) {
        exception.hasImplicitType = true;
      }
      _currentHolder.addLocalVariable(exception);
      exceptionParameter.staticElement = exception;
      // stack trace
      SimpleIdentifier stackTraceParameter = node.stackTraceParameter;
      if (stackTraceParameter != null) {
        LocalVariableElementImpl stackTrace =
            new LocalVariableElementImpl.forNode(stackTraceParameter);
        _setCodeRange(stackTrace, stackTraceParameter);
        _currentHolder.addLocalVariable(stackTrace);
        stackTraceParameter.staticElement = stackTrace;
      }
    }
    return super.visitCatchClause(node);
  }

  @override
  Object visitClassDeclaration(ClassDeclaration node) {
    ElementHolder holder = new ElementHolder();
    _functionTypesToFix = new List<ExecutableElementImpl>();
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
    List<TypeParameterElement> typeParameters = holder.typeParameters;
    List<DartType> typeArguments = _createTypeParameterTypes(typeParameters);
    InterfaceTypeImpl interfaceType = new InterfaceTypeImpl(element);
    interfaceType.typeArguments = typeArguments;
    element.type = interfaceType;
    element.typeParameters = typeParameters;
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
    // Function types must be initialized after the enclosing element has been
    // set, for them to pick up the type parameters.
    for (ExecutableElementImpl e in _functionTypesToFix) {
      e.type = new FunctionTypeImpl(e);
    }
    _functionTypesToFix = null;
    _currentHolder.addType(element);
    className.staticElement = element;
    _fieldMap = null;
    holder.validate();
    return null;
  }

  /**
   * Implementation of this method should be synchronized with
   * [visitClassDeclaration].
   */
  void visitClassDeclarationIncrementally(ClassDeclaration node) {
    //
    // Process field declarations before constructors and methods so that field
    // formal parameters can be correctly resolved to their fields.
    //
    ClassElement classElement = node.element;
    _buildFieldMap(classElement.fields);
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
    List<TypeParameterElement> typeParameters = holder.typeParameters;
    element.typeParameters = typeParameters;
    List<DartType> typeArguments = _createTypeParameterTypes(typeParameters);
    InterfaceTypeImpl interfaceType = new InterfaceTypeImpl(element);
    interfaceType.typeArguments = typeArguments;
    element.type = interfaceType;
    setElementDocumentationComment(element, node);
    _currentHolder.addType(element);
    className.staticElement = element;
    holder.validate();
    return null;
  }

  @override
  Object visitCompilationUnit(CompilationUnit node) {
    if (compilationUnitElement is ElementImpl) {
      _setCodeRange(compilationUnitElement as ElementImpl, node);
    }
    return super.visitCompilationUnit(node);
  }

  @override
  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    ElementHolder holder = new ElementHolder();
    bool wasInFunction = _inFunction;
    _inFunction = true;
    try {
      _visitChildren(holder, node);
    } finally {
      _inFunction = wasInFunction;
    }
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
    element.const2 = node.constKeyword != null;
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
  Object visitDeclaredIdentifier(DeclaredIdentifier node) {
    SimpleIdentifier variableName = node.identifier;
    LocalVariableElementImpl element =
        new LocalVariableElementImpl.forNode(variableName);
    _setCodeRange(element, node);
    element.metadata = _createElementAnnotations(node.metadata);
    ForEachStatement statement = node.parent as ForEachStatement;
    int declarationEnd = node.offset + node.length;
    int statementEnd = statement.offset + statement.length;
    element.setVisibleRange(declarationEnd, statementEnd - declarationEnd - 1);
    element.const3 = node.isConst;
    element.final2 = node.isFinal;
    if (node.type == null) {
      element.hasImplicitType = true;
    }
    _currentHolder.addLocalVariable(element);
    variableName.staticElement = element;
    return super.visitDeclaredIdentifier(node);
  }

  @override
  Object visitDefaultFormalParameter(DefaultFormalParameter node) {
    ElementHolder holder = new ElementHolder();
    NormalFormalParameter normalParameter = node.parameter;
    SimpleIdentifier parameterName = normalParameter.identifier;
    ParameterElementImpl parameter;
    if (normalParameter is FieldFormalParameter) {
      parameter =
          new DefaultFieldFormalParameterElementImpl.forNode(parameterName);
      FieldElement field =
          _fieldMap == null ? null : _fieldMap[parameterName.name];
      if (field != null) {
        (parameter as DefaultFieldFormalParameterElementImpl).field = field;
      }
    } else {
      parameter = new DefaultParameterElementImpl.forNode(parameterName);
    }
    _setCodeRange(parameter, node);
    parameter.const3 = node.isConst;
    parameter.final2 = node.isFinal;
    parameter.parameterKind = node.kind;
    // set initializer, default value range
    Expression defaultValue = node.defaultValue;
    if (defaultValue != null) {
      _visit(holder, defaultValue);
      FunctionElementImpl initializer =
          new FunctionElementImpl.forOffset(defaultValue.beginToken.offset);
      initializer.hasImplicitReturnType = true;
      initializer.functions = holder.functions;
      initializer.labels = holder.labels;
      initializer.localVariables = holder.localVariables;
      initializer.parameters = holder.parameters;
      initializer.synthetic = true;
      initializer.type = new FunctionTypeImpl(initializer);
      parameter.initializer = initializer;
      parameter.defaultValueCode = defaultValue.toSource();
    }
    // visible range
    _setParameterVisibleRange(node, parameter);
    if (normalParameter is SimpleFormalParameter &&
        normalParameter.type == null) {
      parameter.hasImplicitType = true;
    }
    _currentHolder.addParameter(parameter);
    parameterName.staticElement = parameter;
    normalParameter.accept(this);
    holder.validate();
    return null;
  }

  @override
  Object visitEnumDeclaration(EnumDeclaration node) {
    SimpleIdentifier enumName = node.name;
    ClassElementImpl enumElement = new ClassElementImpl.forNode(enumName);
    _setCodeRange(enumElement, node);
    enumElement.metadata = _createElementAnnotations(node.metadata);
    enumElement.enum2 = true;
    setElementDocumentationComment(enumElement, node);
    InterfaceTypeImpl enumType = new InterfaceTypeImpl(enumElement);
    enumElement.type = enumType;
    // The equivalent code for enums in the spec shows a single constructor,
    // but that constructor is not callable (since it is a compile-time error
    // to subclass, mix-in, implement, or explicitly instantiate an enum).  So
    // we represent this as having no constructors.
    enumElement.constructors = ConstructorElement.EMPTY_LIST;
    _currentHolder.addEnum(enumElement);
    enumName.staticElement = enumElement;
    return super.visitEnumDeclaration(node);
  }

  @override
  Object visitExportDirective(ExportDirective node) {
    _createElementAnnotations(node.metadata);
    return super.visitExportDirective(node);
  }

  @override
  Object visitFieldFormalParameter(FieldFormalParameter node) {
    if (node.parent is! DefaultFormalParameter) {
      SimpleIdentifier parameterName = node.identifier;
      FieldElement field =
          _fieldMap == null ? null : _fieldMap[parameterName.name];
      FieldFormalParameterElementImpl parameter =
          new FieldFormalParameterElementImpl.forNode(parameterName);
      _setCodeRange(parameter, node);
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
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    FunctionExpression expression = node.functionExpression;
    if (expression != null) {
      ElementHolder holder = new ElementHolder();
      bool wasInFunction = _inFunction;
      _inFunction = true;
      try {
        _visitChildren(holder, node);
      } finally {
        _inFunction = wasInFunction;
      }
      FunctionBody body = expression.body;
      Token property = node.propertyKeyword;
      if (property == null || _inFunction) {
        SimpleIdentifier functionName = node.name;
        FunctionElementImpl element =
            new FunctionElementImpl.forNode(functionName);
        _setCodeRange(element, node);
        element.metadata = _createElementAnnotations(node.metadata);
        setElementDocumentationComment(element, node);
        if (node.externalKeyword != null) {
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
        if (_inFunction) {
          Block enclosingBlock = node.getAncestor((node) => node is Block);
          if (enclosingBlock != null) {
            element.setVisibleRange(
                enclosingBlock.offset, enclosingBlock.length);
          }
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
          variable.final2 = true;
          variable.synthetic = true;
          _currentHolder.addTopLevelVariable(variable);
        }
        if (node.isGetter) {
          PropertyAccessorElementImpl getter =
              new PropertyAccessorElementImpl.forNode(propertyNameNode);
          _setCodeRange(getter, node);
          getter.metadata = _createElementAnnotations(node.metadata);
          setElementDocumentationComment(getter, node);
          if (node.externalKeyword != null) {
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
          getter.static = true;
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
          if (node.externalKeyword != null) {
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
          setter.static = true;
          if (node.returnType == null) {
            setter.hasImplicitReturnType = true;
          }
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

  @override
  Object visitFunctionExpression(FunctionExpression node) {
    if (node.parent is FunctionDeclaration) {
      // visitFunctionDeclaration has already created the element for the
      // declaration.  We just need to visit children.
      return super.visitFunctionExpression(node);
    }
    ElementHolder holder = new ElementHolder();
    bool wasInFunction = _inFunction;
    _inFunction = true;
    try {
      _visitChildren(holder, node);
    } finally {
      _inFunction = wasInFunction;
    }
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
    if (_inFunction) {
      Block enclosingBlock = node.getAncestor((node) => node is Block);
      if (enclosingBlock != null) {
        element.setVisibleRange(enclosingBlock.offset, enclosingBlock.length);
      }
    }
    if (_functionTypesToFix != null) {
      _functionTypesToFix.add(element);
    } else {
      element.type = new FunctionTypeImpl(element);
    }
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
  Object visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    if (node.parent is! DefaultFormalParameter) {
      SimpleIdentifier parameterName = node.identifier;
      ParameterElementImpl parameter =
          new ParameterElementImpl.forNode(parameterName);
      _setCodeRange(parameter, node);
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
  Object visitImportDirective(ImportDirective node) {
    _createElementAnnotations(node.metadata);
    return super.visitImportDirective(node);
  }

  @override
  Object visitLabeledStatement(LabeledStatement node) {
    bool onSwitchStatement = node.statement is SwitchStatement;
    for (Label label in node.labels) {
      SimpleIdentifier labelName = label.label;
      LabelElementImpl element =
          new LabelElementImpl.forNode(labelName, onSwitchStatement, false);
      _currentHolder.addLabel(element);
      labelName.staticElement = element;
    }
    return super.visitLabeledStatement(node);
  }

  @override
  Object visitLibraryDirective(LibraryDirective node) {
    _createElementAnnotations(node.metadata);
    return super.visitLibraryDirective(node);
  }

  @override
  Object visitMethodDeclaration(MethodDeclaration node) {
    try {
      ElementHolder holder = new ElementHolder();
      bool wasInFunction = _inFunction;
      _inFunction = true;
      try {
        _visitChildren(holder, node);
      } finally {
        _inFunction = wasInFunction;
      }
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
        if (node.externalKeyword != null) {
          element.external = true;
        }
        element.functions = holder.functions;
        element.labels = holder.labels;
        element.localVariables = holder.localVariables;
        element.parameters = holder.parameters;
        element.static = isStatic;
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
        FieldElementImpl field =
            _currentHolder.getField(propertyName) as FieldElementImpl;
        if (field == null) {
          field = new FieldElementImpl(node.name.name, -1);
          field.final2 = true;
          field.static = isStatic;
          field.synthetic = true;
          _currentHolder.addField(field);
        }
        if (node.isGetter) {
          PropertyAccessorElementImpl getter =
              new PropertyAccessorElementImpl.forNode(propertyNameNode);
          _setCodeRange(getter, node);
          getter.metadata = _createElementAnnotations(node.metadata);
          setElementDocumentationComment(getter, node);
          if (node.externalKeyword != null) {
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
          getter.static = isStatic;
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
          if (node.externalKeyword != null) {
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
          setter.static = isStatic;
          if (node.returnType == null) {
            setter.hasImplicitReturnType = true;
          }
          field.setter = setter;
          field.final2 = false;
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
    _createElementAnnotations(node.metadata);
    return super.visitPartDirective(node);
  }

  @override
  Object visitSimpleFormalParameter(SimpleFormalParameter node) {
    if (node.parent is! DefaultFormalParameter) {
      SimpleIdentifier parameterName = node.identifier;
      ParameterElementImpl parameter =
          new ParameterElementImpl.forNode(parameterName);
      _setCodeRange(parameter, node);
      parameter.const3 = node.isConst;
      parameter.final2 = node.isFinal;
      parameter.parameterKind = node.kind;
      _setParameterVisibleRange(node, parameter);
      if (node.type == null) {
        parameter.hasImplicitType = true;
      }
      _currentHolder.addParameter(parameter);
      parameterName.staticElement = parameter;
    }
    super.visitSimpleFormalParameter(node);
    (node.element as ElementImpl).metadata =
        _createElementAnnotations(node.metadata);
    return null;
  }

  @override
  Object visitSwitchCase(SwitchCase node) {
    for (Label label in node.labels) {
      SimpleIdentifier labelName = label.label;
      LabelElementImpl element =
          new LabelElementImpl.forNode(labelName, false, true);
      _currentHolder.addLabel(element);
      labelName.staticElement = element;
    }
    return super.visitSwitchCase(node);
  }

  @override
  Object visitSwitchDefault(SwitchDefault node) {
    for (Label label in node.labels) {
      SimpleIdentifier labelName = label.label;
      LabelElementImpl element =
          new LabelElementImpl.forNode(labelName, false, true);
      _currentHolder.addLabel(element);
      labelName.staticElement = element;
    }
    return super.visitSwitchDefault(node);
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

  @override
  Object visitVariableDeclaration(VariableDeclaration node) {
    bool isConst = node.isConst;
    bool isFinal = node.isFinal;
    bool hasInitializer = node.initializer != null;
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
      field.static = fieldNode.isStatic;
      _setCodeRange(element, node);
      setElementDocumentationComment(element, fieldNode);
      field.hasImplicitType = varList.type == null;
      _currentHolder.addField(field);
      fieldName.staticElement = field;
    } else if (_inFunction) {
      SimpleIdentifier variableName = node.name;
      LocalVariableElementImpl variable;
      if (isConst && hasInitializer) {
        variable = new ConstLocalVariableElementImpl.forNode(variableName);
      } else {
        variable = new LocalVariableElementImpl.forNode(variableName);
      }
      element = variable;
      _setCodeRange(element, node);
      Block enclosingBlock = node.getAncestor((node) => node is Block);
      // TODO(brianwilkerson) This isn't right for variables declared in a for
      // loop.
      variable.setVisibleRange(enclosingBlock.offset, enclosingBlock.length);
      variable.hasImplicitType = varList.type == null;
      _currentHolder.addLocalVariable(variable);
      variableName.staticElement = element;
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
    element.const3 = isConst;
    element.final2 = isFinal;
    if (hasInitializer) {
      ElementHolder holder = new ElementHolder();
      _visit(holder, node.initializer);
      FunctionElementImpl initializer =
          new FunctionElementImpl.forOffset(node.initializer.beginToken.offset);
      initializer.hasImplicitReturnType = true;
      initializer.functions = holder.functions;
      initializer.labels = holder.labels;
      initializer.localVariables = holder.localVariables;
      initializer.synthetic = true;
      initializer.type = new FunctionTypeImpl(initializer);
      element.initializer = initializer;
      holder.validate();
    }
    if (element is PropertyInducingElementImpl) {
      PropertyAccessorElementImpl getter =
          new PropertyAccessorElementImpl.forVariable(element);
      getter.getter = true;
      if (element.hasImplicitType) {
        getter.hasImplicitReturnType = true;
      }
      _currentHolder.addAccessor(getter);
      element.getter = getter;
      if (!isConst && !isFinal) {
        PropertyAccessorElementImpl setter =
            new PropertyAccessorElementImpl.forVariable(element);
        setter.setter = true;
        ParameterElementImpl parameter =
            new ParameterElementImpl("_${element.name}", element.nameOffset);
        parameter.synthetic = true;
        parameter.parameterKind = ParameterKind.REQUIRED;
        setter.parameters = <ParameterElement>[parameter];
        _currentHolder.addAccessor(setter);
        element.setter = setter;
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
    for (VariableDeclaration variableDeclaration in node.variables) {
      ElementImpl element = variableDeclaration.element as ElementImpl;
      _setCodeRange(element, node.parent);
      element.metadata = elementAnnotations;
    }
    return null;
  }

  /**
   * Build the table mapping field names to field elements for the fields defined in the current
   * class.
   *
   * @param fields the field elements defined in the current class
   */
  void _buildFieldMap(List<FieldElement> fields) {
    _fieldMap = new HashMap<String, FieldElement>();
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
  List<ConstructorElement> _createDefaultConstructors(
      ClassElementImpl definingClass) {
    ConstructorElementImpl constructor =
        new ConstructorElementImpl.forNode(null);
    constructor.synthetic = true;
    constructor.returnType = definingClass.type;
    constructor.enclosingElement = definingClass;
    constructor.type = new FunctionTypeImpl(constructor);
    return <ConstructorElement>[constructor];
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
          new ElementAnnotationImpl(compilationUnitElement);
      a.elementAnnotation = elementAnnotation;
      return elementAnnotation;
    }).toList();
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
  final ElementBuilder builder;

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
