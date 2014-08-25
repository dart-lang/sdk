// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library services.completion;

import 'dart:collection';
import 'package:analysis_server/src/protocol.dart' show
    CompletionSuggestionKind;
import 'package:analyzer/src/generated/java_core.dart' hide StringUtils;
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'stubs.dart';
import 'util.dart';

class AstNodeClassifier_CompletionEngine_typeOf extends CompletionEngine_AstNodeClassifier {
  final CompletionEngine CompletionEngine_this;

  List<DartType> result;

  AstNodeClassifier_CompletionEngine_typeOf(this.CompletionEngine_this, this.result) : super();

  @override
  Object visitPrefixedIdentifier(PrefixedIdentifier node) => visitSimpleIdentifier(node.identifier);

  @override
  Object visitSimpleIdentifier(SimpleIdentifier node) {
    Element elem = node.bestElement;
    if (elem != null && elem.kind == ElementKind.GETTER) {
      PropertyAccessorElement accessor = elem as PropertyAccessorElement;
      if (accessor.isSynthetic) {
        PropertyInducingElement var2 = accessor.variable;
        result[0] = CompletionEngine_this._typeSearch(var2);
      }
    }
    return null;
  }
}

/**
 * The analysis engine for code completion.
 *
 * Note: During development package-private methods are used to group element-specific completion
 * utilities.
 *
 * TODO: Recognize when completion is requested in the middle of a multi-character operator.
 * Re-write the AST as it would be if an identifier were present at the completion point then
 * restart the analysis.
 */
class CompletionEngine {
  static String _C_DYNAMIC = "dynamic";

  static String _C_FALSE = "false";

  static String _C_NULL = "null";

  static String _C_PARAMNAME = "arg";

  static String _C_TRUE = "true";

  static String _C_VAR = "var";

  static String _C_VOID = "void";

  static bool _isPrivate(Element element) {
    String name = element.displayName;
    return Identifier.isPrivateName(name);
  }

  static bool _isSyntheticIdentifier(Expression expression) => expression is SimpleIdentifier && expression.isSynthetic;

  CompletionRequestor _requestor;

  final CompletionFactory _factory;

  AssistContext _context;

  Filter _filter;

  CompletionState _state;

  List<LibraryElement> _libraries;

  CompletionEngine(CompletionRequestor requestor, this._factory) {
    this._requestor = requestor;
    this._state = new CompletionState();
  }

  /**
   * Analyze the source unit in the given context to determine completion proposals at the selection
   * offset of the context.
   *
   * @throws Exception
   */
  void complete(AssistContext context) {
    this._context = context;
    _requestor.beginReporting();
    AstNode completionNode = context.coveredNode;
    if (completionNode != null) {
      _state.context = completionNode;
      CompletionEngine_TerminalNodeCompleter visitor = new CompletionEngine_TerminalNodeCompleter(this);
      completionNode.accept(visitor);
    }
    _requestor.endReporting();
  }

  void _analyzeAnnotationName(SimpleIdentifier identifier) {
    _filter = _createFilter(identifier);
    CompletionEngine_NameCollector names = _collectTopLevelElementVisibleAt(identifier);
    for (Element element in names.uniqueElements) {
      if (element is PropertyAccessorElement) {
        element = (element as PropertyAccessorElement).variable;
      }
      if (element is TopLevelVariableElement) {
        TopLevelVariableElement variable = element as TopLevelVariableElement;
        if (_state._isCompileTimeConstantRequired && !variable.isConst) {
          continue;
        }
        _proposeName(element, identifier, names);
      }
      if (element is ClassElement) {
        ClassElement classElement = element as ClassElement;
        for (ConstructorElement constructor in classElement.constructors) {
          _pNamedConstructor(classElement, constructor, identifier);
        }
      }
    }
  }

  void _analyzeConstructorTypeName(SimpleIdentifier identifier) {
    _filter = _createFilter(identifier);
    List<Element> types = _findAllTypes(currentLibrary, TopLevelNamesKind.DECLARED_AND_IMPORTS);
    for (Element type in types) {
      if (type is ClassElement) {
        _namedConstructorReference(type, identifier);
      }
    }
    List<Element> prefixes = _findAllPrefixes();
    for (Element prefix in prefixes) {
      _pName(prefix, identifier);
    }
  }

  void _analyzeDeclarationName(VariableDeclaration varDecl) {
    // We might want to propose multiple names for a declaration based on types someday.
    // For now, just use whatever is already there.
    SimpleIdentifier identifier = varDecl.name;
    _filter = _createFilter(identifier);
    VariableDeclarationList varList = varDecl.parent as VariableDeclarationList;
    TypeName type = varList.type;
    if (identifier.length > 0) {
      _pName3(identifier.name, CompletionSuggestionKind.LOCAL_VARIABLE);
    }
    if (type == null) {
      if (varList.keyword == null) {
        // Interpret as the type name of a typed variable declaration { DivE!; }
        _analyzeLocalName(identifier);
      }
    } else {
      _pParamName(type.name.name.toLowerCase());
    }
  }

  void _analyzeDirectAccess(DartType receiverType, SimpleIdentifier completionNode) {
    if (receiverType != null) {
      // Complete this.!y where this is absent
      Element rcvrTypeElem = receiverType.element;
      if (receiverType.isDynamic) {
        rcvrTypeElem = objectClassElement;
      }
      if (rcvrTypeElem is ClassElement) {
        _directAccess(rcvrTypeElem as ClassElement, completionNode);
      }
    }
  }

  void _analyzeImmediateField(SimpleIdentifier fieldName) {
    _filter = _createFilter(fieldName);
    ClassDeclaration classDecl = fieldName.getAncestor((node) => node is ClassDeclaration);
    ClassElement classElement = classDecl.element;
    for (FieldElement field in classElement.fields) {
      _pName3(field.displayName, CompletionSuggestionKind.FIELD);
    }
  }

  void _analyzeLiteralReference(BooleanLiteral literal) {
    //    state.setContext(literal);
    Ident ident = _createIdent(literal.parent);
    ident.token = literal.literal;
    _filter = _createFilter(ident);
    _analyzeLocalName(ident);
  }

  void _analyzeLocalName(SimpleIdentifier identifier) {
    // Completion x!
    _filter = _createFilter(identifier);
    // TODO Filter out types that have no static members.
    CompletionEngine_NameCollector names = _collectIdentifiersVisibleAt(identifier);
    for (Element element in names.uniqueElements) {
      if (_state._isSourceDeclarationStatic) {
        if (element is FieldElement) {
          if (!element.isStatic) {
            continue;
          }
        } else if (element is PropertyAccessorElement) {
          if (!element.isStatic) {
            continue;
          }
        }
      }
      if (_state._isOptionalArgumentRequired) {
        if (element is! ParameterElement) {
          continue;
        }
        ParameterElement param = element as ParameterElement;
        if (!param.parameterKind.isOptional) {
          continue;
        }
      }
      _proposeName(element, identifier, names);
    }
    if (_state._areLiteralsAllowed) {
      _pNull();
      _pTrue();
      _pFalse();
    }
  }

  void _analyzeNamedParameter(ArgumentList args, SimpleIdentifier identifier) {
    // Completion x!
    _filter = _createFilter(identifier);
    // prepare parameters
    List<ParameterElement> parameters = _getParameterElements(args);
    if (parameters == null) {
      return;
    }
    // remember already used names
    Set<String> usedNames = new Set();
    for (Expression arg in args.arguments) {
      if (arg is NamedExpression) {
        NamedExpression namedExpr = arg;
        String name = namedExpr.name.label.name;
        usedNames.add(name);
      }
    }
    // propose named parameters
    for (ParameterElement parameterElement in parameters) {
      // should be named
      if (parameterElement.parameterKind != ParameterKind.NAMED) {
        continue;
      }
      // filter by name
      if (_filterDisallows(parameterElement)) {
        continue;
      }
      // may be already used
      String parameterName = parameterElement.name;
      if (usedNames.contains(parameterName)) {
        continue;
      }
      // OK, add proposal
      CompletionProposal prop = _createProposal4(CompletionSuggestionKind.NAMED_ARGUMENT);
      prop.setCompletion(parameterName);
      prop.setParameterName(parameterName);
      prop.setParameterType(parameterElement.type.displayName);
      prop.setLocation(identifier.offset);
      prop.setReplacementLength(identifier.length);
      prop.setRelevance(CompletionProposal.RELEVANCE_HIGH);
      _requestor.accept(prop);
    }
  }

  void _analyzeNewParameterName(List<FormalParameter> params, SimpleIdentifier typeIdent, String identifierName) {
    String typeName = typeIdent.name;
    _filter = _createFilter(_createIdent(typeIdent));
    List<String> names = new List<String>();
    for (FormalParameter node in params) {
      names.add(node.identifier.name);
    }
    // Find name similar to typeName not in names, ditto for identifierName.
    if (identifierName == null || identifierName.isEmpty) {
      String candidate = typeName == null || typeName.isEmpty ? _C_PARAMNAME : typeName.toLowerCase();
      _pParamName(_makeNonconflictingName(candidate, names));
    } else {
      _pParamName(_makeNonconflictingName(identifierName, names));
      if (typeName != null && !typeName.isEmpty) {
        _pParamName(_makeNonconflictingName(typeName.toLowerCase(), names));
      }
    }
  }

  void _analyzePositionalArgument(ArgumentList args, SimpleIdentifier identifier) {
    // Show parameter name only if there is nothing to complete, so that if there is only
    // one match, we won't to force user to choose.
    if (!StringUtils.isEmpty(identifier.name)) {
      return;
    }
    // prepare parameters
    List<ParameterElement> parameters = _getParameterElements(args);
    if (parameters == null) {
      return;
    }
    // show current parameter
    int argIndex = args.arguments.indexOf(identifier);
    if (argIndex == -1) {
      argIndex = 0;
    }
    if (argIndex >= 0 && argIndex < parameters.length) {
      ParameterElement parameter = parameters[argIndex];
      if (parameter.parameterKind != ParameterKind.NAMED) {
        String parameterName = parameter.displayName;
        CompletionProposal prop = _createProposal4(CompletionSuggestionKind.OPTIONAL_ARGUMENT);
        prop.setCompletion(parameterName);
        prop.setParameterName(parameterName);
        prop.setParameterType(parameter.type.displayName);
        prop.setLocation(identifier.offset);
        prop.setReplacementLength(identifier.length);
        prop.setRelevance(CompletionProposal.RELEVANCE_HIGH);
        _requestor.accept(prop);
      }
    }
  }

  void _analyzePrefixedAccess(Expression receiver, SimpleIdentifier completionNode) {
    if (receiver is ThisExpression && !_state._isThisAllowed) {
      return;
    }
    DartType receiverType = _typeOf2(receiver);
    bool forSuper = receiver is SuperExpression;
    _analyzePrefixedAccess2(receiverType, forSuper, completionNode);
  }

  void _analyzePrefixedAccess2(DartType receiverType, bool forSuper, SimpleIdentifier completionNode) {
    if (receiverType != null) {
      // Complete x.!y
      Element rcvrTypeElem = receiverType.element;
      if (receiverType.isBottom) {
        receiverType = objectType;
      }
      if (receiverType.isDynamic) {
        receiverType = objectType;
      }
      if (receiverType is InterfaceType) {
        _prefixedAccess(receiverType, forSuper, completionNode);
      } else if (rcvrTypeElem is TypeParameterElement) {
        TypeParameterElement typeParamElem = rcvrTypeElem;
        _analyzePrefixedAccess2(typeParamElem.bound, false, completionNode);
      }
    }
  }

  void _analyzeReceiver(SimpleIdentifier identifier) {
    // Completion x!.y
    _filter = _createFilter(identifier);
    CompletionEngine_NameCollector names = _collectIdentifiersVisibleAt(identifier);
    for (Element element in names.uniqueElements) {
      _proposeName(element, identifier, names);
    }
  }

  void _analyzeSuperConstructorInvocation(SuperConstructorInvocation node) {
    ClassDeclaration enclosingClassNode = node.getAncestor((node) => node is ClassDeclaration);
    if (enclosingClassNode != null) {
      ClassElement enclosingClassElement = enclosingClassNode.element;
      if (enclosingClassElement != null) {
        ClassElement superClassElement = enclosingClassElement.supertype.element;
        _constructorReference(superClassElement, node.constructorName);
      }
    }
  }

  void _analyzeTypeName(SimpleIdentifier identifier, SimpleIdentifier nameIdent) {
    _filter = _createFilter(identifier);
    String name = nameIdent == null ? "" : nameIdent.name;
    List<Element> types = _findAllTypes(currentLibrary, TopLevelNamesKind.DECLARED_AND_IMPORTS);
    for (Element type in types) {
      if (_state._isForMixin) {
        if (type is! ClassElement) {
          continue;
        }
        ClassElement classElement = type as ClassElement;
        if (!classElement.isValidMixin) {
          continue;
        }
      }
      if (type.displayName == name) {
        continue;
      }
      _pName(type, nameIdent);
    }
    if (!_state._isForMixin) {
      ClassDeclaration classDecl = identifier.getAncestor((node) => node is ClassDeclaration);
      if (classDecl != null) {
        ClassElement classElement = classDecl.element;
        for (TypeParameterElement param in classElement.typeParameters) {
          _pName(param, nameIdent);
        }
      }
    }
    List<Element> prefixes = _findAllPrefixes();
    for (Element prefix in prefixes) {
      _pName(prefix, nameIdent);
    }
    if (_state._isDynamicAllowed) {
      _pDynamic();
    }
    if (_state._isVarAllowed) {
      _pVar();
    }
    if (_state._isVoidAllowed) {
      _pVoid();
    }
  }

  void _constructorReference(ClassElement classElement, SimpleIdentifier identifier) {
    // Complete identifier when it refers to a constructor defined in classElement.
    _filter = _createFilter(identifier);
    for (ConstructorElement cons in classElement.constructors) {
      if (_state._isCompileTimeConstantRequired == cons.isConst && _filterAllows(cons)) {
        _pExecutable2(cons, identifier, false);
      }
    }
  }

  void _directAccess(ClassElement classElement, SimpleIdentifier identifier) {
    _filter = _createFilter(identifier);
    CompletionEngine_NameCollector names = _createNameCollector();
    names.addLocalNames(identifier);
    names._addNamesDefinedByHierarchy(classElement, false);
    names._addTopLevelNames2(currentLibrary, TopLevelNamesKind.DECLARED_AND_IMPORTS);
    _proposeNames(names, identifier);
  }

  void _dispatchPrefixAnalysis(InstanceCreationExpression node) {
    // prepare ClassElement
    ClassElement classElement;
    {
      Element typeElement = _typeOf2(node).element;
      if (typeElement is! ClassElement) {
        return;
      }
      classElement = typeElement as ClassElement;
    }
    // prepare constructor name
    Identifier typeName = node.constructorName.type.name;
    SimpleIdentifier identifier = null;
    if (typeName is SimpleIdentifier) {
      identifier = typeName;
    } else if (typeName is PrefixedIdentifier) {
      identifier = typeName.identifier;
    }
    if (identifier == null) {
      identifier = _createIdent(node);
    }
    // analyze constructor name
    _analyzeConstructorTypeName(identifier);
    _constructorReference(classElement, identifier);
  }

  void _dispatchPrefixAnalysis2(MethodInvocation node) {
    // This might be a library prefix on a top-level function
    Expression expr = node.realTarget;
    if (expr is SimpleIdentifier) {
      SimpleIdentifier ident = expr;
      if (ident.bestElement is PrefixElement) {
        _prefixedAccess2(ident, node.methodName);
        return;
      } else if (ident.bestElement is ClassElement) {
        _state._areInstanceReferencesProhibited = true;
        _state._areStaticReferencesProhibited = false;
      } else {
        _state._areInstanceReferencesProhibited = false;
        _state._areStaticReferencesProhibited = true;
      }
    }
    if (expr == null) {
      _analyzeLocalName(_createIdent(node));
    } else {
      _analyzePrefixedAccess(expr, node.methodName);
    }
  }

  void _dispatchPrefixAnalysis3(PrefixedIdentifier node, SimpleIdentifier identifier) {
    SimpleIdentifier receiverName = node.prefix;
    Element receiver = receiverName.bestElement;
    if (receiver == null) {
      _prefixedAccess2(receiverName, identifier);
      return;
    }
    while (true) {
      if (receiver.kind == ElementKind.PREFIX || receiver.kind == ElementKind.IMPORT) {
        // Complete lib_prefix.name
        _prefixedAccess2(receiverName, identifier);
      } else {
        {
          DartType receiverType;
          DartType propType = _typeOf2(receiverName);
          if (propType == null || propType.isDynamic) {
            receiverType = _typeOf(receiver);
          } else {
            DartType declType = _typeOf(receiver);
            if (propType.isMoreSpecificThan(declType)) {
              receiverType = propType;
            } else {
              receiverType = declType;
            }
          }
          _analyzePrefixedAccess2(receiverType, false, identifier);
          break;
        }
      }
      break;
    }
  }

  void _fieldReference(ClassElement classElement, SimpleIdentifier identifier) {
    // Complete identifier when it refers to a constructor defined in classElement.
    _filter = _createFilter(identifier);
    for (FieldElement cons in classElement.fields) {
      if (_filterAllows(cons)) {
        _pField(cons, identifier, classElement);
      }
    }
  }

  void _namedConstructorReference(ClassElement classElement, SimpleIdentifier identifier) {
    // Complete identifier when it refers to a named constructor defined in classElement.
    if (_filter == null) {
      _filter = _createFilter(identifier);
    }
    for (ConstructorElement cons in classElement.constructors) {
      if (!_isVisible(cons)) {
        continue;
      }
      if (_state._isCompileTimeConstantRequired && !cons.isConst) {
        continue;
      }
      _pNamedConstructor(classElement, cons, identifier);
    }
  }

  void _namespacePubReference(NamespaceDirective node, Set<String> packageUris) {
    // no import URI or package:
    String prefix = _filter._prefix;
    List<String> prefixStrings = prefix.split(":");
    if (!prefix.isEmpty && !"package:".startsWith(prefixStrings[0])) {
      return;
    }
    // if no URI yet, propose package:
    if (prefix.isEmpty) {
      _pImportUriWithScheme(node, "package:");
      return;
    }
    // check "packages" folder for package libraries that are not added to AnalysisContext
    {
      Source contextSource = _context.source;
      if (contextSource is FileBasedSource) {
        FileBasedSource contextFileSource = contextSource;
        String contextFilePath = contextFileSource.fullName;
        JavaFile contextFile = new JavaFile(contextFilePath);
        JavaFile contextFolder = contextFile.getParentFile();
        JavaFile contextPackages = new JavaFile.relative(contextFolder, "packages");
        if (contextPackages.isDirectory()) {
          for (JavaFile packageFolder in contextPackages.listFiles()) {
            String packageName = packageFolder.getName();
            String packageLibName = "${packageName}.dart";
            JavaFile packageFile = new JavaFile.relative(packageFolder, packageLibName);
            if (packageFile.exists() && packageFile.isFile()) {
              packageUris.add("package:${packageName}/${packageLibName}");
            }
          }
        }
      }
    }
    // add known package: URIs
    for (String uri in packageUris) {
      if (_filterDisallows2(uri)) {
        continue;
      }
      CompletionProposal prop = _createProposal4(CompletionSuggestionKind.IMPORT);
      prop.setCompletion(uri);
      // put "lib" before "lib/src"
      if (!uri.contains("/src/")) {
        prop.setRelevance(CompletionProposal.RELEVANCE_HIGH);
      }
      // done
      _requestor.accept(prop);
    }
  }

  void _namespaceReference(NamespaceDirective node, SimpleStringLiteral literal) {
    String lit = literal.literal.lexeme;
    if (!lit.isEmpty) {
      lit = lit.substring(1, Math.max(lit.length - 1, 0));
    }
    _filter = _createFilter(new Ident.con2(node, lit, literal.offset + 1));
    Set<String> packageUris = new Set();
    List<LibraryElement> libraries = new List<LibraryElement>();
    List<LibraryElement> librariesInLib = new List<LibraryElement>();
    String currentLibraryName = currentLibrary.source.fullName;
    AnalysisContext ac = analysisContext;
    List<Source> sources = ac.librarySources;
    for (Source s in sources) {
      String sName = s.fullName;
      // skip current library
      if (currentLibraryName == sName) {
        continue;
      }
      // ".pub-cache/..../unittest-0.8.8/lib/unittest.dart" -> "package:unittest/unittest.dart"
      {
        Uri uri = ac.sourceFactory.restoreUri(s);
        if (uri != null) {
          String uriString = uri.toString();
          if (uriString.startsWith("package:")) {
            packageUris.add(uriString);
          }
        }
      }
      LibraryElement lib = ac.getLibraryElement(s);
      if (lib == null) {
        continue;
      } else if (_isUnitInLibFolder(lib.definingCompilationUnit)) {
        librariesInLib.add(lib);
      } else {
        libraries.add(lib);
      }
    }
    _namespaceSdkReference(node);
    _namespacePubReference(node, packageUris);
  }

  void _namespaceSdkReference(NamespaceDirective node) {
    String prefix = _filter._prefix;
    List<String> prefixStrings = prefix.split(":");
    if (!prefix.isEmpty && !"dart:".startsWith(prefixStrings[0])) {
      return;
    }
    if (prefix.isEmpty) {
      _pImportUriWithScheme(node, "dart:");
      return;
    }
    // add DartSdk libraries
    DartSdk dartSdk = analysisContext.sourceFactory.dartSdk;
    for (SdkLibrary library in dartSdk.sdkLibraries) {
      String name = library.shortName;
      // ignore internal
      if (library.isInternal) {
        continue;
      }
      // ignore implementation
      if (library.isImplementation) {
        continue;
      }
      // standard libraries name name starting with "dart:"
      name = StringUtils.removeStart(name, "dart:");
      // ignore private libraries
      if (Identifier.isPrivateName(name)) {
        continue;
      }
      // add with "dart:" prefix
      _pName3("dart:${name}", CompletionSuggestionKind.IMPORT);
    }
  }

  void _operatorAccess(Expression expr, SimpleIdentifier identifier) {
    _state._requiresOperators();
    _analyzePrefixedAccess(expr, identifier);
  }

  void _prefixedAccess(InterfaceType type, bool forSuper, SimpleIdentifier identifier) {
    // Complete identifier when it refers to field or method in classElement.
    _filter = _createFilter(identifier);
    CompletionEngine_NameCollector names = _createNameCollector();
    if (_state._areInstanceReferencesProhibited) {
      names._addNamesDefinedByType2(type);
    } else {
      names._addNamesDefinedByHierarchy2(type, forSuper);
    }
    _proposeNames(names, identifier);
  }

  void _prefixedAccess2(SimpleIdentifier prefixName, SimpleIdentifier identifier) {
    if (_filter == null) {
      _filter = _createFilter(identifier);
    }
    CompletionEngine_NameCollector names = _createNameCollector();
    List<ImportElement> prefixImports = _importsWithName(prefixName);
    // Library prefixes do not have a unique AST representation so we need to fudge state vars.
    bool litsAllowed = _state._areLiteralsAllowed;
    _state._areLiteralsAllowed = false;
    names._addTopLevelNames(prefixImports, TopLevelNamesKind.DECLARED_AND_EXPORTS);
    _state._areLiteralsAllowed = litsAllowed;
    _proposeNames(names, identifier);
  }

  List<InterfaceType> _allSubtypes(ClassElement classElement) {
    // TODO(scheglov) translate it
    return [];
  }

  CompletionEngine_NameCollector _collectIdentifiersVisibleAt(AstNode ident) {
    CompletionEngine_NameCollector names = _createNameCollector();
    ScopedNameFinder finder = new ScopedNameFinder(_completionLocation());
    ident.accept(finder);
    names.addAll(finder.locals.values);
    Declaration decl = finder.declaration;
    if (decl != null && decl.parent is ClassDeclaration) {
      ClassElement classElement = (decl.parent as ClassDeclaration).element;
      names._addNamesDefinedByHierarchy(classElement, false);
    }
    names._addTopLevelNames2(currentLibrary, TopLevelNamesKind.DECLARED_AND_IMPORTS);
    return names;
  }

  CompletionEngine_NameCollector _collectTopLevelElementVisibleAt(AstNode ident) {
    CompletionEngine_NameCollector names = _createNameCollector();
    names._addTopLevelNames2(currentLibrary, TopLevelNamesKind.DECLARED_AND_IMPORTS);
    return names;
  }

  int _completionLocation() => _context.selectionOffset;

  int _completionTokenOffset() => _completionLocation() - _filter._prefix.length;

  List<FormalParameter> _copyWithout(NodeList oldList, AstNode deletion) {
    List<FormalParameter> newList = new List<FormalParameter>();
    oldList.accept(new GeneralizingAstVisitor_CompletionEngine_copyWithout(deletion, newList));
    return newList;
  }

  Filter _createFilter(SimpleIdentifier ident) => new Filter.con1(ident, _context.selectionOffset);

  Ident _createIdent(AstNode node) => new Ident.con1(node, _completionLocation());

  CompletionEngine_NameCollector _createNameCollector() => new CompletionEngine_NameCollector(this);

  CompletionProposal _createProposal(Element element) {
    String completion = element.displayName;
    return _createProposal3(element, completion);
  }

  CompletionProposal _createProposal2(Element element, SimpleIdentifier identifier) {
    // Create a completion proposal for the element: variable, field, class, function.
    if (_filterDisallows(element)) {
      return null;
    }
    CompletionProposal prop = _createProposal(element);
    Element container = element.enclosingElement;
    if (container != null) {
      prop.setDeclaringType(container.displayName);
    }
    DartType type = _typeOf(element);
    if (type != null) {
      prop.setReturnType(type.name);
    }
    if (identifier != null) {
      prop.setReplacementLengthIdentifier(identifier.length);
    }
    return prop;
  }

  CompletionProposal _createProposal3(Element element, String completion) {
    CompletionSuggestionKind kind = _proposalKindOf(element);
    CompletionProposal prop = _createProposal4(kind);
    prop.setElement(element);
    prop.setCompletion(completion);
    prop.setDeprecated(_isDeprecated(element));
    if (_isPrivate(element)) {
      prop.setRelevance(CompletionProposal.RELEVANCE_LOW);
    }
    if (_filter._isSameCasePrefix(element.name)) {
      prop.incRelevance();
    }
    return prop;
  }

  CompletionProposal _createProposal4(CompletionSuggestionKind kind) => _factory.createCompletionProposal(kind, _completionTokenOffset());

  List<LibraryElement> _currentLibraryList() {
    Set<LibraryElement> libraries = new Set<LibraryElement>();
    LibraryElement curLib = currentLibrary;
    libraries.add(curLib);
    Queue<LibraryElement> queue = new Queue<LibraryElement>();
    queue.addAll(curLib.importedLibraries);
    _currentLibraryLister(queue, libraries);
    return new List.from(libraries);
  }

  void _currentLibraryLister(Queue<LibraryElement> queue, Set<LibraryElement> libraries) {
    while (!queue.isEmpty) {
      LibraryElement sourceLib = queue.removeFirst();
      libraries.add(sourceLib);
      List<LibraryElement> expLibs = sourceLib.exportedLibraries;
      for (LibraryElement lib in expLibs) {
        if (!libraries.contains(lib)) {
          queue.add(lib);
        }
      }
    }
  }

  bool _filterAllows(Element element) => _filter._match(element);

  bool _filterDisallows(Element element) => !_filter._match(element);

  bool _filterDisallows2(String name) => !_filter._match2(name);

  List<Element> _findAllNotTypes(List<Element> elements) {
    elements = [];
    for (JavaIterator<Element> I = new JavaIterator(elements); I.hasNext;) {
      Element element = I.next();
      ElementKind kind = element.kind;
      if (kind == ElementKind.FUNCTION || kind == ElementKind.TOP_LEVEL_VARIABLE || kind == ElementKind.GETTER || kind == ElementKind.SETTER) {
        continue;
      }
      I.remove();
    }
    return new List.from(elements);
  }

  List<Element> _findAllPrefixes() {
    LibraryElement lib = _context.compilationUnitElement.enclosingElement;
    return lib.prefixes;
  }

  List<Element> _findAllTypes(LibraryElement library, TopLevelNamesKind topKind) {
    List<Element> elements = _findTopLevelElements(library, topKind);
    return _findAllTypes2(elements);
  }

  List<Element> _findAllTypes2(List<Element> elements) {
    elements = [];
    for (JavaIterator<Element> I = new JavaIterator(elements); I.hasNext;) {
      Element element = I.next();
      ElementKind kind = element.kind;
      if (kind == ElementKind.CLASS || kind == ElementKind.FUNCTION_TYPE_ALIAS) {
        continue;
      }
      I.remove();
    }
    return new List.from(elements);
  }

  List<Element> _findTopLevelElements(LibraryElement library, TopLevelNamesKind topKind) {
    List<Element> elements = [];
    if (topKind == TopLevelNamesKind.DECLARED_AND_IMPORTS) {
      elements.addAll(CorrectionUtils.getTopLevelElements(library));
      for (ImportElement imp in library.imports) {
        elements.addAll(CorrectionUtils.getImportNamespace(imp).values);
      }
      _removeNotMatchingFilter(elements);
    }
    if (topKind == TopLevelNamesKind.DECLARED_AND_EXPORTS) {
      elements.addAll(CorrectionUtils.getExportNamespace2(library).values);
      _removeNotMatchingFilter(elements);
    }
    return elements;
  }

  AnalysisContext get analysisContext => _context.compilationUnitElement.context;

  LibraryElement get currentLibrary => _context.compilationUnitElement.enclosingElement;

  FunctionType _getFunctionType(Element element) {
    if (element is ExecutableElement) {
      ExecutableElement executableElement = element;
      return executableElement.type;
    }
    if (element is VariableElement) {
      VariableElement variableElement = element;
      DartType type = variableElement.type;
      if (type is FunctionType) {
        return type;
      }
    }
    return null;
  }

  ClassElement get objectClassElement => typeProvider.objectType.element;

  InterfaceType get objectType => typeProvider.objectType;

  List<ParameterElement> _getParameterElements(ArgumentList args) {
    List<ParameterElement> parameters = null;
    AstNode argsParent = args.parent;
    if (argsParent is MethodInvocation) {
      MethodInvocation invocation = argsParent;
      Element nameElement = invocation.methodName.staticElement;
      FunctionType functionType = _getFunctionType(nameElement);
      if (functionType != null) {
        parameters = functionType.parameters;
      }
    }
    if (argsParent is InstanceCreationExpression) {
      InstanceCreationExpression creation = argsParent;
      ConstructorElement element = creation.staticElement;
      if (element != null) {
        parameters = element.parameters;
      }
    }
    if (argsParent is Annotation) {
      Annotation annotation = argsParent;
      Element element = annotation.element;
      if (element is ConstructorElement) {
        parameters = element.parameters;
      }
    }
    return parameters;
  }

  TypeProvider get typeProvider {
    AnalysisContext analysisContext = _context.compilationUnitElement.context;
    try {
      return (analysisContext as InternalAnalysisContext).typeProvider;
    } on AnalysisException catch (exception) {
      // TODO(brianwilkerson) Figure out the right thing to do if the core cannot be resolved.
      return null;
    }
  }

  bool get hasErrorBeforeCompletionLocation {
    List<AnalysisError> errors = _context.errors;
    if (errors == null || errors.length == 0) {
      return false;
    }
    return errors[0].offset <= _completionLocation();
  }

  List<ImportElement> _importsWithName(SimpleIdentifier libName) {
    String name = libName.name;
    List<ImportElement> imports = [];
    for (ImportElement imp in currentLibrary.imports) {
      PrefixElement prefix = imp.prefix;
      if (prefix != null) {
        String impName = prefix.displayName;
        if (name == impName) {
          imports.add(imp);
        }
      }
    }
    return new List.from(imports);
  }

  bool _isCompletingKeyword(Token keyword) {
    if (keyword == null) {
      return false;
    }
    int completionLoc = _context.selectionOffset;
    if (completionLoc >= keyword.offset && completionLoc <= keyword.end) {
      return true;
    }
    return false;
  }

  bool _isCompletionAfter(int loc) => loc <= _completionLocation();

  bool _isCompletionBefore(int loc) => _completionLocation() <= loc;

  bool _isCompletionBetween(int firstLoc, int secondLoc) => _isCompletionAfter(firstLoc) && _isCompletionBefore(secondLoc);

  bool _isDeprecated(Element element) => element != null && element.isDeprecated;

  bool _isInCurrentLibrary(Element element) {
    LibraryElement libElement = currentLibrary;
    return identical(element.library, libElement);
  }

  bool _isUnitInLibFolder(CompilationUnitElement cu) {
    String pathString = cu.source.fullName;
    if (pathString.indexOf("/lib/") == -1) {
      return false;
    }
    return true;
  }

  bool _isVisible(Element element) => !_isPrivate(element) || _isInCurrentLibrary(element);

  String _makeNonconflictingName(String candidate, List<String> names) {
    String possibility = candidate;
    int count = 0;
    loop: while (true) {
      String name = count == 0 ? possibility : "${possibility}${count}";
      for (String conflict in names) {
        if (name == conflict) {
          count += 1;
          continue loop;
        }
      }
      return name;
    }
  }

  void _pArgumentList(CompletionProposal proposal, int offset, int len) {
    // prepare parameters
    List<String> parameterNames = proposal.parameterNames;
    if (parameterNames.length == 0) {
      return;
    }
    // fill arguments proposal
    CompletionProposal prop = _createProposal4(CompletionSuggestionKind.ARGUMENT_LIST);
    prop.setElement(proposal.element);
    prop.setCompletion(proposal.completion).setReturnType(proposal.returnType);
    prop.setParameterNames(parameterNames);
    prop.setParameterTypes(proposal.parameterTypes);
    prop.setParameterStyle(proposal.positionalParameterCount, proposal.hasNamed, proposal.hasPositional);
    prop.setReplacementLength(0).setLocation(_completionLocation());
    prop.setRelevance(CompletionProposal.RELEVANCE_HIGH);
    _requestor.accept(prop);
  }

  void _pDynamic() {
    _pWord(_C_DYNAMIC, CompletionSuggestionKind.LOCAL_VARIABLE);
  }

  void _pExecutable(Element element, FunctionType functionType, SimpleIdentifier identifier, bool isPotentialMatch) {
    // Create a completion proposal for the element: function, method, getter, setter, constructor.
    String name = element.displayName;
    if (name.isEmpty) {
      return;
    }
    if (_filterDisallows(element)) {
      return;
    }
    if (!_isVisible(element)) {
      return;
    }
    // May be we are in argument of function type parameter, propose function reference.
    if (_state._targetParameter != null) {
      DartType parameterType = _state._targetParameter.type;
      if (parameterType is FunctionType) {
        if (functionType.isAssignableTo(parameterType)) {
          _pName2(name, element, CompletionProposal.RELEVANCE_HIGH, CompletionSuggestionKind.METHOD_NAME);
        }
      }
    }
    CompletionProposal prop = _createProposal(element);
    prop.setPotentialMatch(isPotentialMatch);
    if (isPotentialMatch) {
      prop.setRelevance(CompletionProposal.RELEVANCE_LOW);
    }
    _setParameterInfo(functionType, prop);
    prop.setCompletion(name).setReturnType(functionType.returnType.displayName);
    // If there is already argument list, then update only method name.
    if (identifier.parent is MethodInvocation && (identifier.parent as MethodInvocation).argumentList != null) {
      prop.setKind(CompletionSuggestionKind.METHOD_NAME);
    }
    Element container = element.enclosingElement;
    if (container != null) {
      prop.setDeclaringType(container.displayName);
    }
    _requestor.accept(prop);
  }

  void _pExecutable2(ExecutableElement element, SimpleIdentifier identifier, bool isPotentialMatch) {
    _pExecutable(element, element.type, identifier, isPotentialMatch);
  }

  void _pExecutable3(VariableElement element, SimpleIdentifier identifier) {
    // Create a completion proposal for the element: top-level variable.
    String name = element.displayName;
    if (name.isEmpty || _filterDisallows(element)) {
      return;
    }
    CompletionProposal prop = _createProposal(element);
    if (element.type != null) {
      prop.setReturnType(element.type.name);
    }
    Element container = element.enclosingElement;
    if (container != null) {
      prop.setDeclaringType(container.displayName);
    }
    if (identifier != null) {
      prop.setReplacementLengthIdentifier(identifier.length);
    }
    _requestor.accept(prop);
  }

  void _pFalse() {
    _pWord(_C_FALSE, CompletionSuggestionKind.LOCAL_VARIABLE);
  }

  void _pField(FieldElement element, SimpleIdentifier identifier, ClassElement classElement) {
    // Create a completion proposal for the element: field only.
    if (_filterDisallows(element)) {
      return;
    }
    CompletionProposal prop = _createProposal(element);
    Element container = element.enclosingElement;
    prop.setDeclaringType(container.displayName);
    _requestor.accept(prop);
  }

  /**
   * Proposes URI with the given scheme for the given [NamespaceDirective].
   */
  void _pImportUriWithScheme(NamespaceDirective node, String uriScheme) {
    String newUri = "${uriScheme}${new String.fromCharCode(CompletionProposal.CURSOR_MARKER)}";
    if (node.uri.isSynthetic) {
      newUri = "'${newUri}'";
      if (node.semicolon == null || node.semicolon.isSynthetic) {
        newUri += ";";
      }
    }
    if (_context.selectionOffset == node.keyword.end) {
      newUri = " ${newUri}";
    }
    _pName3(newUri, CompletionSuggestionKind.IMPORT);
  }

  void _pKeyword(Token keyword) {
    _filter = new Filter.con2(keyword.lexeme, keyword.offset, _completionLocation());
    // This isn't as useful as it might seem. It only works in the case that completion
    // is requested on an existing recognizable keyword.
    // TODO: Add keyword proposal kind
    CompletionProposal prop = _createProposal4(CompletionSuggestionKind.LIBRARY_PREFIX);
    prop.setCompletion(keyword.lexeme);
    _requestor.accept(prop);
  }

  void _pName(Element element, SimpleIdentifier identifier) {
    CompletionProposal prop = _createProposal2(element, identifier);
    if (prop != null) {
      _requestor.accept(prop);
    }
  }

  void _pName2(String name, Element element, int relevance, CompletionSuggestionKind kind) {
    if (_filterDisallows2(name)) {
      return;
    }
    CompletionProposal prop = _createProposal4(kind);
    prop.setRelevance(relevance);
    prop.setCompletion(name);
    prop.setElement(element);
    _requestor.accept(prop);
  }

  void _pName3(String name, CompletionSuggestionKind kind) {
    if (_filterDisallows2(name)) {
      return;
    }
    CompletionProposal prop = _createProposal4(kind);
    prop.setCompletion(name);
    _requestor.accept(prop);
  }

  void _pNamedConstructor(ClassElement classElement, ConstructorElement element, SimpleIdentifier identifier) {
    // Create a completion proposal for the named constructor.
    String name = classElement.displayName;
    if (!element.displayName.isEmpty) {
      name += ".${element.displayName}";
    }
    if (_filterDisallows2(name)) {
      return;
    }
    CompletionProposal prop = _createProposal3(element, name);
    _setParameterInfo(element.type, prop);
    prop.setReturnType(element.type.returnType.name);
    Element container = element.enclosingElement;
    prop.setDeclaringType(container.displayName);
    if (identifier != null) {
      prop.setReplacementLengthIdentifier(identifier.length);
    }
    _requestor.accept(prop);
  }

  void _pNull() {
    _pWord(_C_NULL, CompletionSuggestionKind.LOCAL_VARIABLE);
  }

  void _pParamName(String name) {
    if (_filterDisallows2(name)) {
      return;
    }
    CompletionProposal prop = _createProposal4(CompletionSuggestionKind.PARAMETER);
    prop.setCompletion(name);
    _requestor.accept(prop);
  }

  CompletionSuggestionKind _proposalKindOf(Element element) {
    CompletionSuggestionKind kind;
    while (true) {
      if (element.kind == ElementKind.CONSTRUCTOR) {
        kind = CompletionSuggestionKind.CONSTRUCTOR;
      } else if (element.kind == ElementKind.FUNCTION) {
        kind = CompletionSuggestionKind.FUNCTION;
      } else if (element.kind == ElementKind.METHOD) {
        kind = CompletionSuggestionKind.METHOD;
      } else if (element.kind == ElementKind.GETTER) {
        kind = CompletionSuggestionKind.GETTER;
      } else if (element.kind == ElementKind.SETTER) {
        kind = CompletionSuggestionKind.SETTER;
      } else if (element.kind == ElementKind.CLASS) {
        kind = CompletionSuggestionKind.CLASS;
      } else if (element.kind == ElementKind.FIELD) {
        kind = CompletionSuggestionKind.FIELD;
      } else if (element.kind == ElementKind.IMPORT) {
        kind = CompletionSuggestionKind.IMPORT;
      } else if (element.kind == ElementKind.PARAMETER) {
        kind = CompletionSuggestionKind.PARAMETER;
      } else if (element.kind == ElementKind.PREFIX) {
        kind = CompletionSuggestionKind.LIBRARY_PREFIX;
      } else if (element.kind == ElementKind.FUNCTION_TYPE_ALIAS) {
        kind = CompletionSuggestionKind.CLASS_ALIAS;
      } else if (element.kind == ElementKind.TYPE_PARAMETER) {
        kind = CompletionSuggestionKind.TYPE_PARAMETER;
      } else if (element.kind == ElementKind.LOCAL_VARIABLE || element.kind == ElementKind.TOP_LEVEL_VARIABLE) {
        kind = CompletionSuggestionKind.LOCAL_VARIABLE;
      } else {
        throw new IllegalArgumentException();
      }
      break;
    }
    return kind;
  }

  void _proposeCombinator(Combinator node, SimpleIdentifier identifier) {
    _filter = _createFilter(identifier);
    NamespaceDirective directive = node.parent as NamespaceDirective;
    LibraryElement libraryElement = directive.uriElement;
    if (libraryElement != null) {
      // prepare Elements with unique names
      CompletionEngine_NameCollector nameCollector = _createNameCollector();
      Iterable<Element> elements = CorrectionUtils.getExportNamespace2(libraryElement).values;
      for (Element element in elements) {
        if (_filterDisallows(element)) {
          continue;
        }
        nameCollector._mergeName(element);
      }
      // propose each Element
      for (Element element in nameCollector.uniqueElements) {
        CompletionProposal proposal = _createProposal(element);
        if (proposal.kind == CompletionSuggestionKind.FUNCTION) {
          proposal.setKind(CompletionSuggestionKind.METHOD_NAME);
        }
        _requestor.accept(proposal);
      }
    }
  }

  void _proposeName(Element element, SimpleIdentifier identifier, CompletionEngine_NameCollector names) {
    while (true) {
      if (element.kind == ElementKind.FUNCTION || element.kind == ElementKind.GETTER || element.kind == ElementKind.METHOD || element.kind == ElementKind.SETTER) {
        ExecutableElement candidate = element as ExecutableElement;
        _pExecutable2(candidate, identifier, names._isPotentialMatch(candidate));
      } else if (element.kind == ElementKind.LOCAL_VARIABLE || element.kind == ElementKind.PARAMETER || element.kind == ElementKind.TOP_LEVEL_VARIABLE) {
        FunctionType functionType = _getFunctionType(element);
        if (functionType != null) {
          _pExecutable(element, functionType, identifier, names._isPotentialMatch(element));
        } else {
          VariableElement var2 = element as VariableElement;
          _pExecutable3(var2, identifier);
        }
      } else if (element.kind == ElementKind.CLASS) {
        _pName(element, identifier);
      } else {
      }
      break;
    }
  }

  void _proposeNames(CompletionEngine_NameCollector names, SimpleIdentifier identifier) {
    for (Element element in names.uniqueElements) {
      _proposeName(element, identifier, names);
    }
  }

  void _pTrue() {
    _pWord(_C_TRUE, CompletionSuggestionKind.LOCAL_VARIABLE);
  }

  void _pVar() {
    _pWord(_C_VAR, CompletionSuggestionKind.LOCAL_VARIABLE);
  }

  void _pVoid() {
    _pWord(_C_VOID, CompletionSuggestionKind.LOCAL_VARIABLE);
  }

  void _pWord(String word, CompletionSuggestionKind kind) {
    if (_filterDisallows2(word)) {
      return;
    }
    CompletionProposal prop = _createProposal4(kind);
    prop.setCompletion(word);
    _requestor.accept(prop);
  }

  void _removeNotMatchingFilter(List<Element> elements) {
    if (_filter == null) {
      return;
    }
    _filter._makePattern();
    _filter._removeNotMatching(elements);
  }

  void _setParameterInfo(FunctionType functionType, CompletionProposal prop) {
    List<String> params = new List<String>();
    List<String> types = new List<String>();
    bool named = false, positional = false;
    int posCount = 0;
    for (ParameterElement param in functionType.parameters) {
      if (!param.isSynthetic) {
        while (true) {
          if (param.parameterKind == ParameterKind.REQUIRED) {
            posCount += 1;
          } else if (param.parameterKind == ParameterKind.NAMED) {
            named = true;
          } else if (param.parameterKind == ParameterKind.POSITIONAL) {
            positional = true;
          }
          break;
        }
        params.add(param.displayName);
        types.add(param.type.toString());
      }
    }
    prop.setParameterNames(new List.from(params));
    prop.setParameterTypes(new List.from(types));
    prop.setParameterStyle(posCount, named, positional);
  }

  SimpleIdentifier _typeDeclarationName(AstNode node) {
    AstNode parent = node;
    while (parent != null) {
      if (parent is ClassDeclaration) {
        return (parent as ClassDeclaration).name;
      }
      if (parent is ClassTypeAlias) {
        return (parent as ClassTypeAlias).name;
      }
      if (parent is FunctionTypeAlias) {
        return (parent as FunctionTypeAlias).name;
      }
      parent = parent.parent;
    }
    return null;
  }

  DartType _typeOf(Element receiver) {
    DartType receiverType;
    while (true) {
      if (receiver.kind == ElementKind.FIELD || receiver.kind == ElementKind.PARAMETER || receiver.kind == ElementKind.LOCAL_VARIABLE || receiver.kind == ElementKind.TOP_LEVEL_VARIABLE) {
        {
          VariableElement receiverElement = receiver as VariableElement;
          receiverType = receiverElement.type;
          break;
        }
      } else if (receiver.kind == ElementKind.GETTER) {
        PropertyAccessorElement accessor = receiver as PropertyAccessorElement;
        if (accessor.isSynthetic) {
          PropertyInducingElement inducer = accessor.variable;
          DartType inducerType = inducer.type;
          if (inducerType == null || inducerType.isDynamic) {
            receiverType = _typeSearch(inducer);
            if (receiverType != null) {
              break;
            }
          }
        }
        FunctionType accType = accessor.type;
        receiverType = accType == null ? null : accType.returnType;
      } else if (receiver.kind == ElementKind.CONSTRUCTOR || receiver.kind == ElementKind.FUNCTION || receiver.kind == ElementKind.METHOD || receiver.kind == ElementKind.SETTER) {
        {
          ExecutableElement receiverElement = receiver as ExecutableElement;
          FunctionType funType = receiverElement.type;
          receiverType = funType == null ? null : funType.returnType;
          break;
        }
      } else if (receiver.kind == ElementKind.CLASS) {
        {
          ClassElement receiverElement = receiver as ClassElement;
          receiverType = receiverElement.type;
          break;
        }
      } else if (receiver.kind == ElementKind.DYNAMIC) {
        {
          receiverType = DynamicTypeImpl.instance;
          break;
        }
      } else if (receiver.kind == ElementKind.FUNCTION_TYPE_ALIAS) {
        {
          FunctionTypeAliasElement receiverElement = receiver as FunctionTypeAliasElement;
          FunctionType funType = receiverElement.type;
          receiverType = funType == null ? null : funType.returnType;
          break;
        }
      } else {
        {
          receiverType = null;
          break;
        }
      }
      break;
    }
    return receiverType;
  }

  DartType _typeOf2(Expression expr) {
    DartType type = expr.bestType;
    if (type.isDynamic) {
      List<DartType> result = new List<DartType>(1);
      CompletionEngine_AstNodeClassifier visitor = new AstNodeClassifier_CompletionEngine_typeOf(this, result);
      expr.accept(visitor);
      if (result[0] != null) {
        return result[0];
      }
    }
    return type;
  }

  DartType _typeOfContainingClass(AstNode node) {
    AstNode parent = node;
    while (parent != null) {
      if (parent is ClassDeclaration) {
        return (parent as ClassDeclaration).element.type;
      }
      parent = parent.parent;
    }
    return DynamicTypeImpl.instance;
  }

  DartType _typeSearch(PropertyInducingElement varElement) {
    // TODO(scheglov) translate it
    return null;
  }
}

abstract class CompletionEngine_AstNodeClassifier extends GeneralizingAstVisitor<Object> {
  @override
  Object visitNode(AstNode node) => null;
}

class CompletionEngine_CommentReferenceCompleter extends CompletionEngine_AstNodeClassifier {
  final CompletionEngine CompletionEngine_this;

  final SimpleIdentifier _identifier;

  CompletionEngine_NameCollector _names;

  Set<Element> _enclosingElements = new Set();

  CompletionEngine_CommentReferenceCompleter(this.CompletionEngine_this, this._identifier) {
    CompletionEngine_this._filter = CompletionEngine_this._createFilter(_identifier);
    _names = CompletionEngine_this._collectTopLevelElementVisibleAt(_identifier);
  }

  @override
  Object visitClassDeclaration(ClassDeclaration node) {
    ClassElement classElement = node.element;
    _names._addNamesDefinedByHierarchy(classElement, false);
    _enclosingElements.add(classElement);
    return null;
  }

  @override
  Object visitComment(Comment node) {
    node.parent.accept(this);
    // propose names
    for (Element element in _names.uniqueElements) {
      CompletionProposal proposal = CompletionEngine_this._createProposal2(element, _identifier);
      if (proposal != null) {
        // we don't want to add arguments, just names
        if (element is MethodElement || element is FunctionElement) {
          proposal.setKind(CompletionSuggestionKind.METHOD_NAME);
        }
        // elevate priority for local elements
        if (_enclosingElements.contains(element.enclosingElement)) {
          proposal.setRelevance(CompletionProposal.RELEVANCE_HIGH);
        }
        // propose
        CompletionEngine_this._requestor.accept(proposal);
      }
    }
    // done
    return null;
  }

  @override
  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    _visitExecutableDeclaration(node);
    // pass through
    return node.parent.accept(this);
  }

  @override
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    _visitExecutableDeclaration(node);
    return null;
  }

  @override
  Object visitFunctionTypeAlias(FunctionTypeAlias node) {
    FunctionTypeAliasElement element = node.element;
    _names._mergeNames(element.parameters);
    _enclosingElements.add(element);
    return null;
  }

  @override
  Object visitMethodDeclaration(MethodDeclaration node) {
    _visitExecutableDeclaration(node);
    // pass through
    return node.parent.accept(this);
  }

  void _visitExecutableDeclaration(Declaration node) {
    ExecutableElement element = node.element as ExecutableElement;
    _names._mergeNames(element.parameters);
    _enclosingElements.add(element);
  }
}

/**
 * An IdentifierCompleter is used to classify the parent of the completion node when it has
 * previously been determined that the completion node is a SimpleIdentifier.
 */
class CompletionEngine_IdentifierCompleter extends CompletionEngine_AstNodeClassifier {
  final CompletionEngine CompletionEngine_this;

  SimpleIdentifier _completionNode;

  CompletionEngine_IdentifierCompleter(this.CompletionEngine_this, SimpleIdentifier node) {
    _completionNode = node;
  }

  @override
  Object visitAnnotation(Annotation node) {
    if (_completionNode is SimpleIdentifier) {
      CompletionEngine_this._analyzeAnnotationName(_completionNode);
    }
    return null;
  }

  @override
  Object visitArgumentList(ArgumentList node) {
    if (_completionNode is SimpleIdentifier) {
      if (CompletionEngine_this._isCompletionBetween(node.leftParenthesis.end, node.rightParenthesis.offset)) {
        CompletionEngine_this._analyzeLocalName(_completionNode);
        CompletionEngine_this._analyzePositionalArgument(node, _completionNode);
        CompletionEngine_this._analyzeNamedParameter(node, _completionNode);
      }
    }
    return null;
  }

  @override
  Object visitAssignmentExpression(AssignmentExpression node) {
    if (_completionNode is SimpleIdentifier) {
      CompletionEngine_this._analyzeLocalName(_completionNode);
    }
    return null;
  }

  @override
  Object visitBinaryExpression(BinaryExpression node) {
    if (identical(node.leftOperand, _completionNode)) {
      CompletionEngine_this._analyzeLocalName(_completionNode);
    } else if (identical(node.rightOperand, _completionNode)) {
      CompletionEngine_this._analyzeLocalName(_completionNode);
    }
    return null;
  }

  @override
  Object visitCombinator(Combinator node) {
    CompletionEngine_this._proposeCombinator(node, _completionNode);
    return null;
  }

  @override
  Object visitCommentReference(CommentReference node) {
    AstNode comment = node.parent;
    CompletionEngine_CommentReferenceCompleter visitor = new CompletionEngine_CommentReferenceCompleter(CompletionEngine_this, _completionNode);
    return comment.accept(visitor);
  }

  @override
  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    if (identical(node.returnType, _completionNode)) {
      CompletionEngine_this._filter = CompletionEngine_this._createFilter(_completionNode);
      CompletionEngine_this._pName3(_completionNode.name, CompletionSuggestionKind.CONSTRUCTOR);
    }
    return null;
  }

  @override
  Object visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    // { A() : this.!x = 1; }
    if (identical(node.fieldName, _completionNode)) {
      ClassElement classElement = (node.parent as ConstructorDeclaration).element.enclosingElement;
      CompletionEngine_this._fieldReference(classElement, node.fieldName);
    }
    return null;
  }

  @override
  Object visitConstructorName(ConstructorName node) {
    if (identical(node.name, _completionNode)) {
      // { new A.!c(); }
      TypeName typeName = node.type;
      if (typeName != null) {
        DartType type = typeName.type;
        Element typeElement = type.element;
        if (typeElement is ClassElement) {
          ClassElement classElement = typeElement;
          CompletionEngine_this._constructorReference(classElement, node.name);
        }
      }
    }
    return null;
  }

  @override
  Object visitDoStatement(DoStatement node) {
    if (identical(node.condition, _completionNode)) {
      CompletionEngine_this._analyzeLocalName(_completionNode);
    }
    return null;
  }

  @override
  Object visitExpression(Expression node) {
    SimpleIdentifier ident;
    if (_completionNode is SimpleIdentifier) {
      ident = _completionNode;
    } else {
      ident = CompletionEngine_this._createIdent(node);
    }
    CompletionEngine_this._analyzeLocalName(ident);
    return null;
  }

  @override
  Object visitExpressionFunctionBody(ExpressionFunctionBody node) {
    if (identical(_completionNode, node.expression)) {
      CompletionEngine_this._analyzeLocalName(_completionNode);
    }
    return null;
  }

  @override
  Object visitExpressionStatement(ExpressionStatement node) {
    SimpleIdentifier ident;
    if (_completionNode is SimpleIdentifier) {
      ident = _completionNode;
    } else {
      ident = CompletionEngine_this._createIdent(node);
    }
    CompletionEngine_this._analyzeLocalName(ident);
    return null;
  }

  @override
  Object visitFieldFormalParameter(FieldFormalParameter node) {
    if (identical(_completionNode, node.identifier)) {
      CompletionEngine_this._analyzeImmediateField(node.identifier);
    }
    return null;
  }

  @override
  Object visitForEachStatement(ForEachStatement node) {
    if (identical(node.iterator, _completionNode)) {
      CompletionEngine_this._analyzeLocalName(_completionNode);
    }
    return null;
  }

  @override
  Object visitFunctionTypeAlias(FunctionTypeAlias node) {
    if (identical(node.name, _completionNode)) {
      if (node.returnType == null) {
        // This may be an incomplete class type alias
        CompletionEngine_this._state._includesUndefinedTypes();
        CompletionEngine_this._analyzeTypeName(node.name, CompletionEngine_this._typeDeclarationName(node));
      }
    }
    return null;
  }

  @override
  Object visitIfStatement(IfStatement node) {
    if (identical(node.condition, _completionNode)) {
      // { if (!) }
      CompletionEngine_this._analyzeLocalName(new Ident.con3(node, _completionNode.token));
    }
    return null;
  }

  @override
  Object visitInterpolationExpression(InterpolationExpression node) {
    if (node.expression is SimpleIdentifier) {
      SimpleIdentifier ident = node.expression as SimpleIdentifier;
      CompletionEngine_this._analyzeLocalName(ident);
    }
    return null;
  }

  @override
  Object visitLibraryIdentifier(LibraryIdentifier node) => null;

  @override
  Object visitMethodDeclaration(MethodDeclaration node) {
    if (identical(_completionNode, node.name)) {
      if (node.returnType == null) {
        // class Foo {const F!(); }
        CompletionEngine_this._analyzeLocalName(_completionNode);
      }
    }
    return null;
  }

  @override
  Object visitMethodInvocation(MethodInvocation node) {
    if (identical(node.methodName, _completionNode)) {
      // { x.!y() }
      Expression expr = node.realTarget;
      DartType receiverType;
      if (expr == null) {
        receiverType = CompletionEngine_this._typeOfContainingClass(node);
        CompletionEngine_this._analyzeDirectAccess(receiverType, node.methodName);
      } else {
        CompletionEngine_this._dispatchPrefixAnalysis2(node);
      }
    } else if (identical(node.target, _completionNode)) {
      // { x!.y() } -- only reached when node.getTarget() is a simple identifier.
      if (_completionNode is SimpleIdentifier) {
        SimpleIdentifier ident = _completionNode;
        CompletionEngine_this._analyzeReceiver(ident);
      }
    }
    return null;
  }

  @override
  Object visitParenthesizedExpression(ParenthesizedExpression node) {
    // Incomplete closure: foo((Str!)); We check if "()" is argument for function typed parameter.
    if (node.parent is ArgumentList) {
      ParameterElement parameterElement = node.bestParameterElement;
      if (parameterElement != null && parameterElement.type is FunctionType) {
        Ident ident = CompletionEngine_this._createIdent(_completionNode);
        CompletionEngine_this._analyzeTypeName(_completionNode, ident);
      }
    }
    return super.visitParenthesizedExpression(node);
  }

  @override
  Object visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (identical(node.prefix, _completionNode)) {
      // { x!.y }
      CompletionEngine_this._analyzeLocalName(node.prefix);
    } else {
      // { v.! }
      CompletionEngine_this._dispatchPrefixAnalysis3(node, node.identifier);
    }
    return null;
  }

  @override
  Object visitPropertyAccess(PropertyAccess node) {
    if (node.target != null && node.target.length == 0) {
      return null;
    }
    // { o.!hashCode }
    if (identical(node.propertyName, _completionNode)) {
      CompletionEngine_this._analyzePrefixedAccess(node.realTarget, node.propertyName);
    }
    return null;
  }

  @override
  Object visitRedirectingConstructorInvocation(RedirectingConstructorInvocation node) {
    // { A.Fac() : this.!b(); }
    if (identical(node.constructorName, _completionNode)) {
      ClassElement classElement = node.staticElement.enclosingElement;
      CompletionEngine_this._constructorReference(classElement, node.constructorName);
    }
    return null;
  }

  @override
  Object visitReturnStatement(ReturnStatement node) {
    if (_completionNode is SimpleIdentifier) {
      CompletionEngine_this._analyzeLocalName(_completionNode);
    }
    return null;
  }

  @override
  Object visitSimpleFormalParameter(SimpleFormalParameter node) {
    if (identical(node.identifier, _completionNode)) {
      if (node.keyword == null && node.type == null) {
        Ident ident = CompletionEngine_this._createIdent(node);
        CompletionEngine_this._analyzeTypeName(node.identifier, ident);
      }
    }
    return null;
  }

  @override
  Object visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    CompletionEngine_this._analyzeSuperConstructorInvocation(node);
    return null;
  }

  @override
  Object visitSwitchCase(SwitchCase node) {
    if (identical(_completionNode, node.expression)) {
      CompletionEngine_this._analyzeLocalName(_completionNode);
    }
    return null;
  }

  @override
  Object visitSwitchStatement(SwitchStatement node) {
    if (identical(node.expression, _completionNode)) {
      CompletionEngine_this._analyzeLocalName(_completionNode);
    }
    return null;
  }

  @override
  Object visitTypeName(TypeName node) {
    AstNode parent = node.parent;
    if (parent != null) {
      CompletionEngine_TypeNameCompleter visitor = new CompletionEngine_TypeNameCompleter(CompletionEngine_this, _completionNode, node);
      return parent.accept(visitor);
    }
    return null;
  }

  @override
  Object visitTypeParameter(TypeParameter node) {
    // { X<!Y> }
    if (CompletionEngine_this._isCompletionBetween(node.offset, node.end)) {
      CompletionEngine_this._analyzeTypeName(_completionNode, CompletionEngine_this._typeDeclarationName(node));
    }
    return null;
  }

  @override
  Object visitVariableDeclaration(VariableDeclaration node) {
    if (identical(node.name, _completionNode)) {
      CompletionEngine_this._analyzeDeclarationName(node);
    } else if (identical(node.initializer, _completionNode)) {
      CompletionEngine_this._analyzeLocalName(node.initializer as SimpleIdentifier);
    }
    return null;
  }

  @override
  Object visitWhileStatement(WhileStatement node) {
    if (identical(node.condition, _completionNode)) {
      CompletionEngine_this._analyzeLocalName(_completionNode);
    }
    return null;
  }
}

class CompletionEngine_NameCollector {
  final CompletionEngine CompletionEngine_this;

  Map<String, List<Element>> _uniqueNames = new Map<String, List<Element>>();

  Set<Element> _potentialMatches;

  CompletionEngine_NameCollector(this.CompletionEngine_this);

  void addAll(Iterable<SimpleIdentifier> values) {
    for (SimpleIdentifier id in values) {
      _mergeName(id.bestElement);
    }
  }

  void addLocalNames(SimpleIdentifier identifier) {
    AstNode node = identifier;
    Declaration decl;
    while ((decl = node.getAncestor((node) => node is Declaration)) != null) {
      Element declElement = decl.element;
      if (declElement is ExecutableElement) {
        _addNamesDefinedByExecutable(declElement);
      } else {
        return;
      }
      node = decl.parent;
    }
  }

  void _addNamesDefinedByExecutable(ExecutableElement execElement) {
    _mergeNames(execElement.parameters);
    _mergeNames(execElement.localVariables);
    _mergeNames(execElement.functions);
  }

  void _addNamesDefinedByHierarchy(ClassElement classElement, bool forSuper) {
    _addNamesDefinedByHierarchy2(classElement.type, forSuper);
  }

  void _addNamesDefinedByHierarchy2(InterfaceType type, bool forSuper) {
    List<InterfaceType> superTypes = type.element.allSupertypes;
    if (!forSuper) {
      superTypes = ArrayUtils.addAt(superTypes, 0, type);
    }
    _addNamesDefinedByTypes(superTypes);
    // Collect names defined by subtypes separately so they can be identified later.
    CompletionEngine_NameCollector potentialMatchCollector = CompletionEngine_this._createNameCollector();
    if (!type.isObject) {
      potentialMatchCollector._addNamesDefinedByTypes(CompletionEngine_this._allSubtypes(type.element));
    }
    _potentialMatches = new Set<Element>();
    for (List<Element> matches in potentialMatchCollector._uniqueNames.values) {
      for (Element match in matches) {
        _mergeName(match);
        _potentialMatches.add(match);
      }
    }
  }

  void _addNamesDefinedByType(ClassElement classElement) {
    _addNamesDefinedByType2(classElement.type);
  }

  void _addNamesDefinedByType2(InterfaceType type) {
    if (_inPrivateLibrary(type)) {
      return;
    }
    List<PropertyAccessorElement> accessors = type.accessors;
    _mergeNames(accessors);
    List<MethodElement> methods = type.methods;
    _mergeNames(methods);
    _mergeNames(type.element.typeParameters);
    _filterStaticRefs(accessors);
    _filterStaticRefs(methods);
  }

  void _addNamesDefinedByTypes(List<InterfaceType> types) {
    for (InterfaceType type in types) {
      _addNamesDefinedByType2(type);
    }
  }

  void _addTopLevelNames(List<ImportElement> imports, TopLevelNamesKind topKind) {
    for (ImportElement imp in imports) {
      Iterable<Element> elementsCollection = CorrectionUtils.getImportNamespace(imp).values;
      List<Element> elements = [];
      _addTopLevelNames4(elements);
    }
  }

  void _addTopLevelNames2(LibraryElement library, TopLevelNamesKind topKind) {
    List<Element> elements = CompletionEngine_this._findTopLevelElements(library, topKind);
    _addTopLevelNames4(elements);
  }

  void _addTopLevelNames3(List<LibraryElement> libraries, TopLevelNamesKind topKind) {
    for (LibraryElement library in libraries) {
      _addTopLevelNames2(library, topKind);
    }
  }

  Iterable<List<Element>> get names => _uniqueNames.values;

  Iterable<Element> get uniqueElements {
    List<Element> uniqueElements = [];
    for (List<Element> uniques in _uniqueNames.values) {
      Element element = uniques[0];
      uniqueElements.add(element);
    }
    return uniqueElements;
  }

  bool _isPotentialMatch(Element element) => _potentialMatches != null && _potentialMatches.contains(element);

  void _remove(Element element) {
    String name = element.displayName;
    List<Element> list = _uniqueNames[name];
    if (list == null) {
      return;
    }
    list.remove(element);
    if (list.isEmpty) {
      _uniqueNames.remove(name);
    }
  }

  void _addTopLevelNames4(List<Element> elements) {
    _mergeNames(CompletionEngine_this._findAllTypes2(elements));
    if (!CompletionEngine_this._state._areClassesRequired) {
      _mergeNames(CompletionEngine_this._findAllNotTypes(elements));
      _mergeNames(CompletionEngine_this._findAllPrefixes());
    }
  }

  void _filterStaticRefs(List<ExecutableElement> elements) {
    for (ExecutableElement execElem in elements) {
      if (CompletionEngine_this._state._areInstanceReferencesProhibited && !execElem.isStatic) {
        _remove(execElem);
      } else if (CompletionEngine_this._state._areStaticReferencesProhibited && execElem.isStatic) {
        _remove(execElem);
      } else if (!CompletionEngine_this._state._areOperatorsAllowed && execElem.isOperator) {
        _remove(execElem);
      } else if (CompletionEngine_this._state._areMethodsProhibited && !execElem.isOperator) {
        _remove(execElem);
      }
    }
  }

  bool _inPrivateLibrary(InterfaceType type) {
    LibraryElement lib = type.element.library;
    if (!lib.name.startsWith("_")) {
      return false;
    }
    // allow completion in the same library
    if (identical(lib, CompletionEngine_this.currentLibrary)) {
      return false;
    }
    // eliminate types defined in private libraries
    return true;
  }

  void _mergeName(Element element) {
    if (element == null) {
      return;
    }
    // ignore private
    String name = element.displayName;
    if (Identifier.isPrivateName(name)) {
      if (!CompletionEngine_this._isInCurrentLibrary(element)) {
        return;
      }
    }
    // add to other Element(s) with such name
    List<Element> dups = _uniqueNames[name];
    if (dups == null) {
      dups = new List<Element>();
      _uniqueNames[name] = dups;
    }
    dups.add(element);
  }

  void _mergeNames(List<Element> elements) {
    for (Element element in elements) {
      _mergeName(element);
    }
  }
}

/**
 * An StringCompleter is used to classify the parent of the completion node when it has previously
 * been determined that the completion node is a SimpleStringLiteral.
 */
class CompletionEngine_StringCompleter extends CompletionEngine_AstNodeClassifier {
  final CompletionEngine CompletionEngine_this;

  SimpleStringLiteral _completionNode;

  CompletionEngine_StringCompleter(this.CompletionEngine_this, SimpleStringLiteral node) {
    _completionNode = node;
  }

  @override
  Object visitNamespaceDirective(NamespaceDirective node) {
    if (identical(_completionNode, node.uri)) {
      CompletionEngine_this._namespaceReference(node, _completionNode);
    }
    return null;
  }
}

/**
 * A TerminalNodeCompleter is used to classify the completion node when nothing else is known
 * about it.
 */
class CompletionEngine_TerminalNodeCompleter extends CompletionEngine_AstNodeClassifier {
  final CompletionEngine CompletionEngine_this;

  CompletionEngine_TerminalNodeCompleter(this.CompletionEngine_this);

  @override
  Object visitArgumentList(ArgumentList node) {
    if (node.arguments.isEmpty && CompletionEngine_this._isCompletionBetween(node.leftParenthesis.end, node.rightParenthesis.offset)) {
      if (node.parent is MethodInvocation) {
        // or node.getParent().accept(this); ?
        MethodInvocation invokeNode = node.parent as MethodInvocation;
        SimpleIdentifier methodName = invokeNode.methodName;
        ProposalCollector proposalRequestor = new ProposalCollector(CompletionEngine_this._requestor);
        try {
          CompletionEngine_this._requestor = proposalRequestor;
          CompletionEngine_this._dispatchPrefixAnalysis2(invokeNode);
        } finally {
          CompletionEngine_this._requestor = proposalRequestor.requestor;
        }
        int offset = methodName.offset;
        int len = node.rightParenthesis.end - offset;
        String name = methodName.name;
        for (CompletionProposal proposal in proposalRequestor.proposals) {
          if (proposal.completion == name) {
            CompletionEngine_this._pArgumentList(proposal, offset, len);
          }
        }
      } else if (node.parent is InstanceCreationExpression) {
        InstanceCreationExpression invokeNode = node.parent as InstanceCreationExpression;
        ConstructorName methodName = invokeNode.constructorName;
        ProposalCollector proposalRequestor = new ProposalCollector(CompletionEngine_this._requestor);
        try {
          CompletionEngine_this._requestor = proposalRequestor;
          CompletionEngine_this._dispatchPrefixAnalysis(invokeNode);
        } finally {
          CompletionEngine_this._requestor = proposalRequestor.requestor;
        }
        int offset = methodName.offset;
        int len = node.rightParenthesis.end - offset;
        for (CompletionProposal proposal in proposalRequestor.proposals) {
          if (proposal.element == invokeNode.staticElement) {
            CompletionEngine_this._pArgumentList(proposal, offset, len);
          }
        }
      } else if (node.parent is Annotation) {
        Annotation annotation = node.parent as Annotation;
        Element annotationElement = annotation.element;
        if (annotationElement is ConstructorElement) {
          ConstructorElement constructorElement = annotationElement;
          // we don't need any filter
          CompletionEngine_this._filter = new Filter.con2("", -1, 0);
          // fill parameters for "pArgumentList"
          CompletionProposal prop = CompletionEngine_this._createProposal(constructorElement);
          CompletionEngine_this._setParameterInfo(constructorElement.type, prop);
          prop.setCompletion(constructorElement.enclosingElement.name);
          // propose the whole parameters list
          CompletionEngine_this._pArgumentList(prop, 0, 0);
        }
      }
    }
    if (CompletionEngine_this._isCompletionBetween(node.leftParenthesis.end, node.rightParenthesis.offset)) {
      Ident ident = CompletionEngine_this._createIdent(node);
      CompletionEngine_this._analyzeLocalName(ident);
      CompletionEngine_this._analyzePositionalArgument(node, ident);
      CompletionEngine_this._analyzeNamedParameter(node, ident);
    }
    return null;
  }

  @override
  Object visitAsExpression(AsExpression node) {
    if (CompletionEngine_this._isCompletionAfter(node.asOperator.end)) {
      CompletionEngine_this._state._isDynamicAllowed = false;
      CompletionEngine_this._state._isVoidAllowed = false;
      CompletionEngine_this._analyzeTypeName(CompletionEngine_this._createIdent(node), null);
    }
    return null;
  }

  @override
  Object visitAssertStatement(AssertStatement node) {
    if (CompletionEngine_this._isCompletingKeyword(node.keyword)) {
      CompletionEngine_this._pKeyword(node.keyword);
    }
    return null;
  }

  @override
  Object visitBlock(Block node) {
    if (CompletionEngine_this._isCompletionBetween(node.leftBracket.end, node.rightBracket.offset)) {
      // { {! stmt; !} }
      CompletionEngine_this._analyzeLocalName(CompletionEngine_this._createIdent(node));
    }
    return null;
  }

  @override
  Object visitBooleanLiteral(BooleanLiteral node) {
    CompletionEngine_this._analyzeLiteralReference(node);
    return null;
  }

  @override
  Object visitBreakStatement(BreakStatement node) {
    if (CompletionEngine_this._isCompletingKeyword(node.keyword)) {
      CompletionEngine_this._pKeyword(node.keyword);
    }
    return null;
  }

  @override
  Object visitCatchClause(CatchClause node) {
    if (CompletionEngine_this._isCompletingKeyword(node.onKeyword)) {
      CompletionEngine_this._pKeyword(node.onKeyword);
    } else if (CompletionEngine_this._isCompletingKeyword(node.catchKeyword)) {
      CompletionEngine_this._pKeyword(node.catchKeyword);
    }
    return null;
  }

  @override
  Object visitClassDeclaration(ClassDeclaration node) {
    if (CompletionEngine_this._isCompletingKeyword(node.classKeyword)) {
      CompletionEngine_this._pKeyword(node.classKeyword);
    } else if (CompletionEngine_this._isCompletingKeyword(node.abstractKeyword)) {
      CompletionEngine_this._pKeyword(node.abstractKeyword);
    } else if (!node.leftBracket.isSynthetic) {
      if (CompletionEngine_this._isCompletionAfter(node.leftBracket.end)) {
        if (node.rightBracket.isSynthetic || CompletionEngine_this._isCompletionBefore(node.rightBracket.offset)) {
          if (!CompletionEngine_this.hasErrorBeforeCompletionLocation) {
            CompletionEngine_this._analyzeLocalName(CompletionEngine_this._createIdent(node));
          }
        }
      }
    }
    // TODO { abstract ! class ! A ! extends B implements C, D ! {}}
    return null;
  }

  @override
  Object visitClassTypeAlias(ClassTypeAlias node) {
    if (CompletionEngine_this._isCompletingKeyword(node.keyword)) {
      CompletionEngine_this._pKeyword(node.keyword);
    }
    // TODO { typedef ! A ! = ! B ! with C, D !; }
    return null;
  }

  @override
  Object visitCombinator(Combinator node) {
    if (CompletionEngine_this._isCompletingKeyword(node.keyword)) {
      CompletionEngine_this._pKeyword(node.keyword);
    }
    return null;
  }

  @override
  Object visitCompilationUnit(CompilationUnit node) => null;

  @override
  Object visitConstructorName(ConstructorName node) {
    // { new A.!c(); }
    TypeName typeName = node.type;
    if (typeName != null) {
      DartType type = typeName.type;
      Element typeElement = type.element;
      if (typeElement is ClassElement) {
        ClassElement classElement = typeElement;
        CompletionEngine_this._constructorReference(classElement, node.name);
      }
    }
    return null;
  }

  @override
  Object visitContinueStatement(ContinueStatement node) {
    if (CompletionEngine_this._isCompletingKeyword(node.keyword)) {
      CompletionEngine_this._pKeyword(node.keyword);
    }
    return null;
  }

  @override
  Object visitDirective(Directive node) {
    if (CompletionEngine_this._isCompletingKeyword(node.keyword)) {
      CompletionEngine_this._pKeyword(node.keyword);
    }
    return null;
  }

  @override
  Object visitDoStatement(DoStatement node) {
    if (CompletionEngine_this._isCompletingKeyword(node.doKeyword)) {
      CompletionEngine_this._pKeyword(node.doKeyword);
    } else if (CompletionEngine_this._isCompletingKeyword(node.whileKeyword)) {
      CompletionEngine_this._pKeyword(node.whileKeyword);
    } else if (CompletionEngine_this._isCompletionBetween(node.condition.end, node.rightParenthesis.offset)) {
      CompletionEngine_this._operatorAccess(node.condition, CompletionEngine_this._createIdent(node));
    }
    return null;
  }

  @override
  Object visitDoubleLiteral(DoubleLiteral node) => null;

  @override
  Object visitExportDirective(ExportDirective node) {
    visitNamespaceDirective(node);
    return null;
  }

  @override
  Object visitExpression(Expression node) {
    CompletionEngine_this._analyzeLocalName(CompletionEngine_this._createIdent(node));
    return null;
  }

  @override
  Object visitExpressionFunctionBody(ExpressionFunctionBody node) {
    if (node.expression != null && node.semicolon != null) {
      if (CompletionEngine_this._isCompletionBetween(node.expression.end, node.semicolon.offset)) {
        CompletionEngine_this._operatorAccess(node.expression, CompletionEngine_this._createIdent(node));
      }
    }
    return null;
  }

  @override
  Object visitExpressionStatement(ExpressionStatement node) {
    CompletionEngine_this._analyzeLocalName(CompletionEngine_this._createIdent(node));
    return null;
  }

  @override
  Object visitExtendsClause(ExtendsClause node) {
    if (CompletionEngine_this._isCompletingKeyword(node.keyword)) {
      CompletionEngine_this._pKeyword(node.keyword);
    } else if (node.superclass == null) {
      // { X extends ! }
      CompletionEngine_this._analyzeTypeName(CompletionEngine_this._createIdent(node), CompletionEngine_this._typeDeclarationName(node));
    } else {
      // { X extends ! Y }
      CompletionEngine_this._analyzeTypeName(CompletionEngine_this._createIdent(node), CompletionEngine_this._typeDeclarationName(node));
    }
    return null;
  }

  @override
  Object visitForEachStatement(ForEachStatement node) {
    if (CompletionEngine_this._isCompletingKeyword(node.forKeyword)) {
      CompletionEngine_this._pKeyword(node.forKeyword);
    } else if (CompletionEngine_this._isCompletingKeyword(node.inKeyword)) {
      CompletionEngine_this._pKeyword(node.inKeyword);
    }
    return null;
  }

  @override
  Object visitFormalParameterList(FormalParameterList node) {
    if (CompletionEngine_this._isCompletionBetween(node.leftParenthesis.end, node.rightParenthesis.offset)) {
      NodeList<FormalParameter> params = node.parameters;
      if (!params.isEmpty) {
        FormalParameter last = params[params.length - 1];
        if (CompletionEngine_this._isCompletionBetween(last.end, node.rightParenthesis.offset)) {
          List<FormalParameter> newParams = CompletionEngine_this._copyWithout(params, last);
          CompletionEngine_this._analyzeNewParameterName(newParams, last.identifier, null);
        } else {
          Ident ident = CompletionEngine_this._createIdent(node);
          CompletionEngine_this._analyzeTypeName(ident, ident);
        }
      } else {
        Ident ident = CompletionEngine_this._createIdent(node);
        CompletionEngine_this._analyzeTypeName(ident, ident);
      }
    }
    return null;
  }

  @override
  Object visitForStatement(ForStatement node) {
    if (CompletionEngine_this._isCompletingKeyword(node.forKeyword)) {
      CompletionEngine_this._pKeyword(node.forKeyword);
    }
    return null;
  }

  @override
  Object visitFunctionTypeAlias(FunctionTypeAlias node) {
    if (CompletionEngine_this._isCompletingKeyword(node.keyword)) {
      CompletionEngine_this._pKeyword(node.keyword);
    }
    return null;
  }

  @override
  Object visitIfStatement(IfStatement node) {
    if (CompletionEngine_this._isCompletingKeyword(node.ifKeyword)) {
      CompletionEngine_this._pKeyword(node.ifKeyword);
    } else if (CompletionEngine_this._isCompletingKeyword(node.elseKeyword)) {
      CompletionEngine_this._pKeyword(node.elseKeyword);
    } else if (CompletionEngine_this._isCompletionBetween(node.condition.end, node.rightParenthesis.offset)) {
      CompletionEngine_this._operatorAccess(node.condition, CompletionEngine_this._createIdent(node));
    }
    return null;
  }

  @override
  Object visitImplementsClause(ImplementsClause node) {
    if (CompletionEngine_this._isCompletingKeyword(node.keyword)) {
      CompletionEngine_this._pKeyword(node.keyword);
    } else if (node.interfaces.isEmpty) {
      // { X implements ! }
      CompletionEngine_this._analyzeTypeName(CompletionEngine_this._createIdent(node), CompletionEngine_this._typeDeclarationName(node));
    } else {
      // { X implements ! Y }
      CompletionEngine_this._analyzeTypeName(CompletionEngine_this._createIdent(node), CompletionEngine_this._typeDeclarationName(node));
    }
    return null;
  }

  @override
  Object visitImportDirective(ImportDirective node) {
    if (CompletionEngine_this._isCompletingKeyword(node.asToken)) {
      CompletionEngine_this._pKeyword(node.asToken);
    } else {
      visitNamespaceDirective(node);
    }
    return null;
  }

  @override
  Object visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (CompletionEngine_this._isCompletingKeyword(node.keyword)) {
      CompletionEngine_this._pKeyword(node.keyword);
      Ident ident = new Ident.con3(node, node.keyword);
      CompletionEngine_this._analyzeLocalName(ident);
    } else {
      Ident ident = CompletionEngine_this._createIdent(node);
      CompletionEngine_this._analyzeConstructorTypeName(ident);
    }
    return null;
  }

  @override
  Object visitIsExpression(IsExpression node) {
    Ident ident;
    Token isToken = node.isOperator;
    int isTokenEnd = isToken.end;
    if (isTokenEnd == CompletionEngine_this._completionLocation()) {
      Expression expression = node.expression;
      int offset = isToken.offset;
      // { target.is! } possible name completion, parsed as "target.{synthetic} is!"
      if (expression is PrefixedIdentifier) {
        PrefixedIdentifier prefIdent = expression;
        if (prefIdent.identifier.isSynthetic) {
          CompletionEngine_this._analyzePrefixedAccess(prefIdent.prefix, new Ident.con2(node, "is", offset));
        } else {
          CompletionEngine_this._pKeyword(isToken);
        }
        return null;
      }
      // { expr is! }
      if (!CompletionEngine._isSyntheticIdentifier(expression)) {
        CompletionEngine_this._pKeyword(node.isOperator);
        return null;
      }
      // { is! } possible name completion
      ident = new Ident.con2(node, "is", offset);
    } else if (CompletionEngine_this._isCompletionAfter(isTokenEnd)) {
      CompletionEngine_this._state._isDynamicAllowed = false;
      CompletionEngine_this._state._isVoidAllowed = false;
      CompletionEngine_this._analyzeTypeName(CompletionEngine_this._createIdent(node), null);
      return null;
    } else {
      ident = CompletionEngine_this._createIdent(node);
    }
    CompletionEngine_this._analyzeLocalName(ident);
    return null;
  }

  @override
  Object visitLibraryIdentifier(LibraryIdentifier node) => null;

  @override
  Object visitMethodInvocation(MethodInvocation node) {
    Token period = node.period;
    if (period != null && CompletionEngine_this._isCompletionAfter(period.end)) {
      // { x.!y() }
      CompletionEngine_this._dispatchPrefixAnalysis2(node);
    }
    return null;
  }

  @override
  Object visitNamespaceDirective(NamespaceDirective node) {
    StringLiteral uri = node.uri;
    if (uri != null && uri.isSynthetic && node.keyword.end <= CompletionEngine_this._context.selectionOffset) {
      uri.accept(this);
    }
    return super.visitNamespaceDirective(node);
  }

  @override
  Object visitPartOfDirective(PartOfDirective node) {
    if (CompletionEngine_this._isCompletingKeyword(node.ofToken)) {
      CompletionEngine_this._pKeyword(node.ofToken);
    } else {
      visitDirective(node);
    }
    return null;
  }

  @override
  Object visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (CompletionEngine_this._isCompletionAfter(node.period.end)) {
      if (CompletionEngine_this._isCompletionBefore(node.identifier.offset)) {
        // { x.! } or { x.!  y } Note missing/implied semicolon before y; this looks like an
        // obscure case but it occurs frequently when editing existing code.
        CompletionEngine_this._dispatchPrefixAnalysis3(node, node.identifier);
      }
    }
    return null;
  }

  @override
  Object visitPropertyAccess(PropertyAccess node) {
    if (node.target != null && node.target.length == 0) {
      return null;
    }
    Expression target = node.realTarget;
    // The "1 + str.!.length" is parsed as "(1 + str).!.length",
    // but actually user wants "1 + (str.!).length".
    // So, if completion inside of period-period ".!." then it is not really a cascade completion.
    Token operator = node.operator;
    if (operator.type == TokenType.PERIOD_PERIOD) {
      int completionLocation = CompletionEngine_this._completionLocation();
      if (completionLocation > operator.offset && completionLocation < operator.end) {
        while (target is BinaryExpression) {
          target = (target as BinaryExpression).rightOperand;
        }
      }
    }
    // do prefixed completion
    CompletionEngine_this._analyzePrefixedAccess(target, node.propertyName);
    return null;
  }

  @override
  Object visitReturnStatement(ReturnStatement node) {
    if (CompletionEngine_this._isCompletingKeyword(node.keyword)) {
      CompletionEngine_this._pKeyword(node.keyword);
      return null;
    }
    Expression expression = node.expression;
    // return !
    if (expression is SimpleIdentifier) {
      SimpleIdentifier identifier = expression;
      CompletionEngine_this._analyzeLocalName(identifier);
      return null;
    }
    // return expression ! ;
    Token semicolon = node.semicolon;
    if (expression != null && semicolon != null && CompletionEngine_this._isCompletionBetween(expression.end, semicolon.offset)) {
      CompletionEngine_this._operatorAccess(expression, CompletionEngine_this._createIdent(node));
      return null;
    }
    return null;
  }

  @override
  Object visitSimpleFormalParameter(SimpleFormalParameter node) {
    if (node.keyword != null && CompletionEngine_this._isCompletionBefore(node.keyword.end)) {
      // f() { g(var! z) }
      Token token = node.keyword;
      Ident ident = new Ident.con3(node, token);
      CompletionEngine_this._analyzeTypeName(ident, ident);
    }
    return null;
  }

  @override
  Object visitSimpleIdentifier(SimpleIdentifier node) {
    AstNode parent = node.parent;
    if (parent != null) {
      CompletionEngine_IdentifierCompleter visitor = new CompletionEngine_IdentifierCompleter(CompletionEngine_this, node);
      return parent.accept(visitor);
    }
    return null;
  }

  @override
  Object visitSimpleStringLiteral(SimpleStringLiteral node) {
    AstNode parent = node.parent;
    if (parent is Directive) {
      CompletionEngine_StringCompleter visitor = new CompletionEngine_StringCompleter(CompletionEngine_this, node);
      return parent.accept(visitor);
    }
    return null;
  }

  @override
  Object visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    CompletionEngine_this._analyzeSuperConstructorInvocation(node);
    return null;
  }

  @override
  Object visitSwitchMember(SwitchMember node) {
    if (CompletionEngine_this._isCompletingKeyword(node.keyword)) {
      CompletionEngine_this._pKeyword(node.keyword);
    }
    return null;
  }

  @override
  Object visitSwitchStatement(SwitchStatement node) {
    if (CompletionEngine_this._isCompletingKeyword(node.keyword)) {
      CompletionEngine_this._pKeyword(node.keyword);
    }
    return null;
  }

  @override
  Object visitTryStatement(TryStatement node) {
    if (CompletionEngine_this._isCompletingKeyword(node.tryKeyword)) {
      CompletionEngine_this._pKeyword(node.tryKeyword);
    }
    return null;
  }

  @override
  Object visitTypeArgumentList(TypeArgumentList node) {
    if (CompletionEngine_this._isCompletionBetween(node.leftBracket.end, node.rightBracket.offset)) {
      CompletionEngine_this._analyzeTypeName(CompletionEngine_this._createIdent(node), null);
    }
    return null;
  }

  @override
  Object visitTypeParameter(TypeParameter node) {
    if (CompletionEngine_this._isCompletingKeyword(node.keyword)) {
      CompletionEngine_this._pKeyword(node.keyword);
    } else if (node.name.name.isEmpty && CompletionEngine_this._isCompletionBefore(node.keyword.offset)) {
      // { < ! extends X> }
      CompletionEngine_this._analyzeTypeName(node.name, CompletionEngine_this._typeDeclarationName(node));
    }
    // { <! X ! extends ! Y !> }
    return null;
  }

  @override
  Object visitTypeParameterList(TypeParameterList node) {
    // { <X extends A,! B,! > }
    if (CompletionEngine_this._isCompletionBetween(node.leftBracket.end, node.rightBracket.offset)) {
      CompletionEngine_this._analyzeTypeName(CompletionEngine_this._createIdent(node), CompletionEngine_this._typeDeclarationName(node));
    }
    return null;
  }

  @override
  Object visitVariableDeclaration(VariableDeclaration node) {
    if (CompletionEngine_this._isCompletionAfter(node.equals.end)) {
      // { var x =! ...}
      CompletionEngine_this._analyzeLocalName(CompletionEngine_this._createIdent(node));
    }
    return null;
  }

  @override
  Object visitVariableDeclarationList(VariableDeclarationList node) {
    if (CompletionEngine_this._isCompletingKeyword(node.keyword)) {
      CompletionEngine_this._pKeyword(node.keyword);
      CompletionEngine_this._analyzeTypeName(new Ident.con3(node, node.keyword), null);
    }
    return null;
  }

  @override
  Object visitWhileStatement(WhileStatement node) {
    if (CompletionEngine_this._isCompletingKeyword(node.keyword)) {
      CompletionEngine_this._pKeyword(node.keyword);
    } else if (CompletionEngine_this._isCompletionBetween(node.condition.end, node.rightParenthesis.offset)) {
      CompletionEngine_this._operatorAccess(node.condition, CompletionEngine_this._createIdent(node));
    }
    return null;
  }

  @override
  Object visitWithClause(WithClause node) {
    if (CompletionEngine_this._isCompletingKeyword(node.withKeyword)) {
      CompletionEngine_this._pKeyword(node.withKeyword);
    } else if (node.mixinTypes.isEmpty) {
      // { X with ! }
      CompletionEngine_this._analyzeTypeName(CompletionEngine_this._createIdent(node), CompletionEngine_this._typeDeclarationName(node));
    } else {
      // { X with ! Y }
      CompletionEngine_this._analyzeTypeName(CompletionEngine_this._createIdent(node), CompletionEngine_this._typeDeclarationName(node));
    }
    return null;
  }
}

/**
 * A TypeNameCompleter is used to classify the parent of a SimpleIdentifier after it has been
 * identified as a TypeName by the IdentifierCompleter.
 */
class CompletionEngine_TypeNameCompleter extends CompletionEngine_AstNodeClassifier {
  final CompletionEngine CompletionEngine_this;

  final SimpleIdentifier _identifier;

  final TypeName _typeName;

  CompletionEngine_TypeNameCompleter(this.CompletionEngine_this, this._identifier, this._typeName);

  @override
  Object visitAsExpression(AsExpression node) {
    if (identical(node.type, _typeName)) {
      CompletionEngine_this._state._isDynamicAllowed = false;
      CompletionEngine_this._state._isVoidAllowed = false;
      CompletionEngine_this._analyzeTypeName(_identifier, null);
    }
    return null;
  }

  @override
  Object visitCatchClause(CatchClause node) {
    if (identical(node.exceptionType, _typeName)) {
      CompletionEngine_this._analyzeTypeName(_identifier, null);
    }
    return null;
  }

  @override
  Object visitClassTypeAlias(ClassTypeAlias node) {
    CompletionEngine_this._analyzeTypeName(_identifier, CompletionEngine_this._typeDeclarationName(node));
    return null;
  }

  @override
  Object visitConstructorName(ConstructorName node) {
    if (identical(_typeName, node.type)) {
      if (node.period != null) {
        if (CompletionEngine_this._isCompletionAfter(node.period.end)) {
          // Is this branch reachable? Probably only in IdentifierCompleter.
          "".toString();
        } else {
          // { new Cla!ss.cons() }
          Element element = _identifier.bestElement;
          if (element is ClassElement) {
            CompletionEngine_this._namedConstructorReference(element, _identifier);
          }
        }
      } else {
        // { new ! } { new Na!me(); } { new js!on. }
        CompletionEngine_this._analyzeConstructorTypeName(_identifier);
      }
    }
    return null;
  }

  @override
  Object visitExtendsClause(ExtendsClause node) {
    CompletionEngine_this._analyzeTypeName(_identifier, CompletionEngine_this._typeDeclarationName(node));
    return null;
  }

  @override
  Object visitFunctionTypeAlias(FunctionTypeAlias node) {
    CompletionEngine_this._analyzeTypeName(_identifier, CompletionEngine_this._typeDeclarationName(node));
    return null;
  }

  @override
  Object visitImplementsClause(ImplementsClause node) {
    CompletionEngine_this._analyzeTypeName(_identifier, CompletionEngine_this._typeDeclarationName(node));
    return null;
  }

  @override
  Object visitIsExpression(IsExpression node) {
    if (identical(_typeName, node.type)) {
      Token isToken = node.isOperator;
      if (CompletionEngine_this._completionLocation() == isToken.end) {
        Expression expression = node.expression;
        int offset = isToken.offset;
        // { target.is! } possible name completion, parsed as "target.{synthetic} is!"
        if (expression is PrefixedIdentifier) {
          PrefixedIdentifier prefIdent = expression;
          if (prefIdent.identifier.isSynthetic) {
            CompletionEngine_this._analyzePrefixedAccess(prefIdent.prefix, new Ident.con2(node, "is", offset));
          } else {
            CompletionEngine_this._pKeyword(node.isOperator);
          }
          return null;
        }
        // { expr is! }
        if (!CompletionEngine._isSyntheticIdentifier(expression)) {
          CompletionEngine_this._pKeyword(node.isOperator);
          return null;
        }
        // { is! } possible name completion
        CompletionEngine_this._analyzeLocalName(new Ident.con2(node, "is", offset));
      } else {
        CompletionEngine_this._analyzeTypeName(node.type.name as SimpleIdentifier, null);
      }
    }
    return null;
  }

  @override
  Object visitMethodDeclaration(MethodDeclaration node) {
    if (identical(node.returnType, _typeName)) {
      CompletionEngine_this._analyzeTypeName(_identifier, null);
    }
    return null;
  }

  @override
  Object visitSimpleFormalParameter(SimpleFormalParameter node) {
    CompletionEngine_this._analyzeTypeName(_identifier, null);
    return null;
  }

  @override
  Object visitTypeArgumentList(TypeArgumentList node) {
    if (CompletionEngine_this._isCompletionBetween(node.leftBracket.end, node.rightBracket.offset)) {
      CompletionEngine_this._analyzeTypeName(_identifier, null);
    }
    return null;
  }

  @override
  Object visitTypeParameter(TypeParameter node) {
    if (identical(node.bound, _typeName)) {
      // { X<A extends !Y> }
      CompletionEngine_this._analyzeTypeName(_identifier, CompletionEngine_this._typeDeclarationName(node));
    }
    return null;
  }

  @override
  Object visitVariableDeclarationList(VariableDeclarationList node) {
    if (node.parent is Statement) {
      CompletionEngine_this._analyzeLocalName(_identifier);
    } else {
      CompletionEngine_this._analyzeTypeName(_identifier, null);
    }
    return null;
  }

  @override
  Object visitWithClause(WithClause node) {
    CompletionEngine_this._analyzeTypeName(_identifier, CompletionEngine_this._typeDeclarationName(node));
    return null;
  }
}

/**
 * The factory class used to create completion proposals.
 */
class CompletionFactory {
  /**
   * Create a completion proposal of the given kind.
   */
  CompletionProposal createCompletionProposal(CompletionSuggestionKind kind, int insertionPoint) {
    CompletionProposalImpl prop = new CompletionProposalImpl();
    prop.setKind(kind);
    prop.setLocation(insertionPoint);
    return prop;
  }
}

abstract class CompletionProposal {
  static final int RELEVANCE_LOW = 0;

  static final int RELEVANCE_DEFAULT = 10;

  static final int RELEVANCE_HIGH = 20;

  /**
   * This character is used to specify location of the cursor after completion.
   */
  static final int CURSOR_MARKER = 0x2758;

  void applyPartitionOffset(int partitionOffset);

  String get completion;

  String get declaringType;

  Element get element;

  CompletionSuggestionKind get kind;

  int get location;

  String get parameterName;

  List<String> get parameterNames;

  String get parameterType;

  List<String> get parameterTypes;

  int get positionalParameterCount;

  int get relevance;

  int get replacementLength;

  int get replacementLengthIdentifier;

  String get returnType;

  bool get hasNamed;

  bool get hasPositional;

  CompletionProposal incRelevance();

  bool get isDeprecated;

  bool get isPotentialMatch;

  CompletionProposal setCompletion(String x);

  CompletionProposal setDeclaringType(String name);

  CompletionProposal setDeprecated(bool deprecated);

  CompletionProposal setElement(Element element);

  CompletionProposal setKind(CompletionSuggestionKind x);

  CompletionProposal setLocation(int x);

  CompletionProposal setParameterName(String paramName);

  CompletionProposal setParameterNames(List<String> paramNames);

  CompletionProposal setParameterStyle(int count, bool named, bool positional);

  CompletionProposal setParameterType(String paramType);

  CompletionProposal setParameterTypes(List<String> paramTypes);

  CompletionProposal setPotentialMatch(bool isPotentialMatch);

  CompletionProposal setRelevance(int n);

  CompletionProposal setReplacementLength(int x);

  CompletionProposal setReplacementLengthIdentifier(int x);

  CompletionProposal setReturnType(String name);
}

class CompletionProposalImpl implements CompletionProposal {
  Element _element;

  String _completion = "";

  String _returnType = "";

  String _declaringType = "";

  List<String> _parameterNames = StringUtilities.EMPTY_ARRAY;

  List<String> _parameterTypes = StringUtilities.EMPTY_ARRAY;

  String _parameterName;

  String _parameterType;

  CompletionSuggestionKind _kind = null;

  int _location = 0;

  int _replacementLength = 0;

  int _replacementLength2 = 0;

  int _positionalParameterCount = 0;

  bool _named = false;

  bool _positional = false;

  bool _deprecated = false;

  bool _potential = false;

  int _relevance = CompletionProposal.RELEVANCE_DEFAULT;

  @override
  void applyPartitionOffset(int partitionOffset) {
    _location += partitionOffset;
  }

  @override
  String get completion => _completion;

  @override
  String get declaringType => _declaringType;

  @override
  Element get element => _element;

  @override
  CompletionSuggestionKind get kind => _kind;

  @override
  int get location => _location;

  @override
  String get parameterName => _parameterName;

  @override
  List<String> get parameterNames => _parameterNames;

  @override
  String get parameterType => _parameterType;

  @override
  List<String> get parameterTypes => _parameterTypes;

  @override
  int get positionalParameterCount => _positionalParameterCount;

  @override
  int get relevance => _relevance;

  @override
  int get replacementLength => _replacementLength;

  @override
  int get replacementLengthIdentifier => _replacementLength2;

  @override
  String get returnType => _returnType;

  @override
  bool get hasNamed => _named;

  @override
  bool get hasPositional => _positional;

  @override
  CompletionProposal incRelevance() {
    _relevance++;
    return this;
  }

  @override
  bool get isDeprecated => _deprecated;

  @override
  bool get isPotentialMatch => _potential;

  @override
  CompletionProposal setCompletion(String x) {
    _completion = x;
    if (_replacementLength == 0) {
      setReplacementLength(x.length);
    }
    return this;
  }

  @override
  CompletionProposal setDeclaringType(String name) {
    _declaringType = name;
    return this;
  }

  @override
  CompletionProposal setDeprecated(bool deprecated) {
    this._deprecated = deprecated;
    return this;
  }

  @override
  CompletionProposal setElement(Element element) {
    this._element = element;
    return this;
  }

  @override
  CompletionProposal setKind(CompletionSuggestionKind x) {
    _kind = x;
    return this;
  }

  @override
  CompletionProposal setLocation(int x) {
    _location = x;
    return this;
  }

  @override
  CompletionProposal setParameterName(String parameterName) {
    this._parameterName = parameterName;
    return this;
  }

  @override
  CompletionProposal setParameterNames(List<String> paramNames) {
    _parameterNames = paramNames;
    return this;
  }

  @override
  CompletionProposal setParameterStyle(int count, bool named, bool positional) {
    this._named = named;
    this._positional = positional;
    this._positionalParameterCount = count;
    return this;
  }

  @override
  CompletionProposal setParameterType(String parameterType) {
    this._parameterType = parameterType;
    return this;
  }

  @override
  CompletionProposal setParameterTypes(List<String> paramTypes) {
    _parameterTypes = paramTypes;
    return this;
  }

  @override
  CompletionProposal setPotentialMatch(bool isPotentialMatch) {
    _potential = isPotentialMatch;
    return this;
  }

  @override
  CompletionProposal setRelevance(int n) {
    _relevance = n;
    return this;
  }

  @override
  CompletionProposal setReplacementLength(int x) {
    _replacementLength = x;
    return this;
  }

  @override
  CompletionProposal setReplacementLengthIdentifier(int x) {
    _replacementLength2 = x;
    return this;
  }

  @override
  CompletionProposal setReturnType(String name) {
    _returnType = name;
    return this;
  }
}

/**
 * A pathway for reporting completion proposals back to the client.
 */
abstract class CompletionRequestor {
  /**
   * Record the given completion proposal for eventual presentation to the user.
   */
  accept(CompletionProposal proposal);

  void beginReporting();

  void endReporting();
}

/**
 */
class CompletionState {
  bool _isForMixin = false;

  bool _isVoidAllowed = false;

  bool _isDynamicAllowed = false;

  bool _isSourceDeclarationStatic = false;

  bool _isThisAllowed = true;

  bool _isVarAllowed = false;

  bool _areLiteralsAllowed = false;

  bool _areLiteralsProhibited = false;

  bool _areOperatorsAllowed = false;

  bool _areStaticReferencesProhibited = false;

  bool _areInstanceReferencesProhibited = false;

  bool _areUndefinedTypesProhibited = false;

  bool _isCompileTimeConstantRequired = false;

  bool _isOptionalArgumentRequired = false;

  bool _areMethodsProhibited = false;

  bool _areClassesRequired = false;

  ParameterElement _targetParameter;

  void mustBeInstantiableType() {
    _areClassesRequired = true;
    _prohibitsLiterals();
  }

  void _includesLiterals() {
    if (!_areLiteralsProhibited) {
      _areLiteralsAllowed = true;
    }
  }

  void _includesOperators() {
    _areOperatorsAllowed = true;
  }

  void _includesUndefinedDeclarationTypes() {
    if (!_areUndefinedTypesProhibited) {
      _isVoidAllowed = true;
      _isDynamicAllowed = true;
    }
  }

  void _includesUndefinedTypes() {
    _isVarAllowed = true;
    _isDynamicAllowed = true;
  }

  void _mustBeMixin() {
    _isForMixin = true;
  }

  void _prohibitsInstanceReferences() {
    _areInstanceReferencesProhibited = true;
  }

  void _prohibitsLiterals() {
    _areLiteralsAllowed = false;
    _areLiteralsProhibited = true;
  }

  void _prohibitsStaticReferences() {
    _areStaticReferencesProhibited = true;
  }

  void _prohibitThis() {
    _isThisAllowed = false;
  }

  void _prohibitsUndefinedTypes() {
    _areUndefinedTypesProhibited = true;
  }

  void _requiresConst(bool isConst) {
    _isCompileTimeConstantRequired = isConst;
  }

  void _requiresOperators() {
    _includesOperators();
    _areMethodsProhibited = true;
  }

  void _requiresOptionalArgument() {
    _isOptionalArgumentRequired = true;
    _prohibitsLiterals();
  }

  void set context(AstNode base) {
    base.accept(new ContextAnalyzer(this, base));
  }

  void _sourceDeclarationIsStatic(bool state) {
    _isSourceDeclarationStatic = state;
    if (state) {
      if (!_areStaticReferencesProhibited) {
        _prohibitsInstanceReferences();
      }
    }
  }
}

/**
 */
class ContextAnalyzer extends GeneralizingAstVisitor<Object> {
  final CompletionState _state;

  final AstNode _completionNode;

  AstNode _child;

  bool _inExpression = false;

  bool _inIdentifier = false;

  bool _inTypeName = false;

  bool _maybeInvocationArgument = true;

  ContextAnalyzer(this._state, this._completionNode);

  @override
  Object visitAnnotation(Annotation node) {
    _state._requiresConst(true);
    return super.visitAnnotation(node);
  }

  @override
  Object visitCatchClause(CatchClause node) {
    if (identical(node.exceptionType, _child)) {
      _state._prohibitsLiterals();
    }
    return null;
  }

  @override
  Object visitCompilationUnitMember(CompilationUnitMember node) {
    if (node is! ClassDeclaration) {
      _state._prohibitThis();
    }
    return super.visitCompilationUnitMember(node);
  }

  @override
  Object visitConstructorInitializer(ConstructorInitializer node) {
    _state._prohibitThis();
    return super.visitConstructorInitializer(node);
  }

  @override
  Object visitDirective(Directive node) {
    _state._prohibitsLiterals();
    return super.visitDirective(node);
  }

  @override
  Object visitDoStatement(DoStatement node) {
    if (identical(_child, node.condition)) {
      _state._includesLiterals();
    }
    return super.visitDoStatement(node);
  }

  @override
  Object visitExpression(Expression node) {
    _inExpression = true;
    _state._includesLiterals();
    _mayBeSetParameterElement(node);
    return super.visitExpression(node);
  }

  @override
  Object visitFieldDeclaration(FieldDeclaration node) {
    _state._prohibitThis();
    return super.visitFieldDeclaration(node);
  }

  @override
  Object visitForEachStatement(ForEachStatement node) {
    if (identical(_child, node.iterator)) {
      _state._includesLiterals();
    }
    return super.visitForEachStatement(node);
  }

  @override
  Object visitFunctionExpression(FunctionExpression node) {
    if (node.parent is Declaration) {
      // Function expressions that are part of a declaration are not to be treated as expressions.
      return visitNode(node);
    } else {
      return visitExpression(node);
    }
  }

  @override
  Object visitFunctionTypeAlias(FunctionTypeAlias node) {
    if (_inTypeName || node.returnType == null) {
      // This may be an incomplete class type alias
      _state._includesUndefinedDeclarationTypes();
    }
    return super.visitFunctionTypeAlias(node);
  }

  @override
  Object visitIdentifier(Identifier node) {
    _mayBeSetParameterElement(node);
    // Identifiers cannot safely be generalized to expressions, so just walk up one level.
    // LibraryIdentifier is never an expression. PrefixedIdentifier may be an expression, but
    // not in a catch-clause or a declaration. SimpleIdentifier may be an expression, but not
    // in a constructor name, label, or where PrefixedIdentifier is not.
    return visitNode(node);
  }

  @override
  Object visitInstanceCreationExpression(InstanceCreationExpression node) {
    _state._requiresConst(node.isConst);
    if (identical(_completionNode.parent.parent, _child)) {
      _state.mustBeInstantiableType();
    }
    return super.visitInstanceCreationExpression(node);
  }

  @override
  Object visitMethodDeclaration(MethodDeclaration node) {
    _state._sourceDeclarationIsStatic(node.isStatic);
    if (identical(_child, node.returnType)) {
      _state._includesUndefinedDeclarationTypes();
    }
    if (node.isStatic) {
      _state._prohibitThis();
    }
    return super.visitMethodDeclaration(node);
  }

  @override
  Object visitNode(AstNode node) {
    // Walk UP the tree, not down.
    AstNode parent = node.parent;
    _updateIfShouldGetTargetParameter(node, parent);
    if (parent != null) {
      _child = node;
      parent.accept(this);
    }
    return null;
  }

  @override
  Object visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (identical(node, _completionNode) || identical(node.identifier, _completionNode)) {
      SimpleIdentifier prefix = node.prefix;
      if (_isClassLiteral(prefix)) {
        _state._prohibitsInstanceReferences();
      } else {
        _state._prohibitsStaticReferences();
      }
    }
    return super.visitPrefixedIdentifier(node);
  }

  @override
  Object visitPropertyAccess(PropertyAccess node) {
    if (identical(node, _completionNode) || identical(node.propertyName, _completionNode)) {
      Expression target = node.realTarget;
      if (_isClassLiteral(target)) {
        _state._prohibitsInstanceReferences();
      } else {
        _state._prohibitsStaticReferences();
      }
    }
    return super.visitPropertyAccess(node);
  }

  @override
  Object visitSimpleFormalParameter(SimpleFormalParameter node) {
    _state._includesUndefinedTypes();
    return super.visitSimpleFormalParameter(node);
  }

  @override
  Object visitSimpleIdentifier(SimpleIdentifier node) {
    _inIdentifier = true;
    return super.visitSimpleIdentifier(node);
  }

  @override
  Object visitSwitchStatement(SwitchStatement node) {
    if (identical(_child, node.expression)) {
      _state._includesLiterals();
    }
    return super.visitSwitchStatement(node);
  }

  @override
  Object visitTypeArgumentList(TypeArgumentList node) {
    _state._prohibitsUndefinedTypes();
    return super.visitTypeArgumentList(node);
  }

  @override
  Object visitTypeName(TypeName node) {
    _inTypeName = true;
    return super.visitTypeName(node);
  }

  @override
  Object visitVariableDeclaration(VariableDeclaration node) {
    if (identical(node.name, _completionNode)) {
      _state._prohibitsLiterals();
    }
    return super.visitVariableDeclaration(node);
  }

  @override
  Object visitVariableDeclarationList(VariableDeclarationList node) {
    _state._includesUndefinedDeclarationTypes();
    return super.visitVariableDeclarationList(node);
  }

  @override
  Object visitWhileStatement(WhileStatement node) {
    if (identical(_child, node.condition)) {
      _state._includesLiterals();
    }
    return super.visitWhileStatement(node);
  }

  @override
  Object visitWithClause(WithClause node) {
    _state._mustBeMixin();
    return super.visitWithClause(node);
  }

  bool _isClassLiteral(Expression expression) => expression is Identifier && expression.staticElement is ClassElement;

  void _mayBeSetParameterElement(Expression node) {
    if (!_maybeInvocationArgument) {
      return;
    }
    if (node.parent is ArgumentList) {
      if (_state._targetParameter == null) {
        _state._targetParameter = node.bestParameterElement;
      }
    }
  }

  void _updateIfShouldGetTargetParameter(AstNode node, AstNode parent) {
    if (!_maybeInvocationArgument) {
      return;
    }
    // prefix.node
    if (parent is PrefixedIdentifier) {
      if (identical(parent.identifier, node)) {
        return;
      }
    }
    // something unknown
    _maybeInvocationArgument = false;
  }
}

class Filter {
  String _prefix;

  String _originalPrefix;

  RegExp _pattern;

  Filter.con1(SimpleIdentifier ident, int loc) : this.con2(ident.name, ident.offset, loc);

  Filter.con2(String name, int pos, int loc) {
    int len = loc - pos;
    if (len > 0) {
      if (len <= name.length) {
        _prefix = name.substring(0, len);
      } else {
        _prefix = name;
      }
    } else {
      _prefix = "";
    }
    _originalPrefix = _prefix;
    _prefix = _prefix.toLowerCase();
  }

  /**
   * @return `true` if the given name starts with the same prefix as used for filter.
   */
  bool _isSameCasePrefix(String name) => name.startsWith(_originalPrefix);

  String _makePattern() {
    // TODO(scheglov) translate it
    return null;
  }

  bool _match(Element elem) => _match2(elem.displayName);

  bool _match2(String name) {
    // Return true if the filter passes.
    if (name.toLowerCase().startsWith(_prefix)) {
      return true;
    }
    return _matchPattern(name);
  }

  void _removeNotMatching(List<Element> elements) {
    for (JavaIterator<Element> I = new JavaIterator(elements); I.hasNext;) {
      Element element = I.next();
      if (!_match(element)) {
        I.remove();
      }
    }
  }

  bool _matchPattern(String name) {
    // TODO(scheglov) translate it
    return false;
  }
}

class GeneralizingAstVisitor_CompletionEngine_copyWithout extends GeneralizingAstVisitor<Object> {
  AstNode deletion;

  List<FormalParameter> newList;

  GeneralizingAstVisitor_CompletionEngine_copyWithout(this.deletion, this.newList) : super();

  @override
  Object visitNode(AstNode node) {
    if (!identical(node, deletion)) {
      newList.add(node as FormalParameter);
    }
    return null;
  }
}

/**
 * An [Ident] is a wrapper for a String that provides type equivalence with SimpleIdentifier.
 */
class Ident extends EphemeralIdentifier {
  String _name;

  Ident.con1(AstNode parent, int offset) : super(parent, offset);

  Ident.con2(AstNode parent, String name, int offset) : super(parent, offset) {
    this._name = name;
  }

  Ident.con3(AstNode parent, Token name) : super(parent, name.offset) {
    this._name = name.lexeme;
  }

  @override
  String get name {
    if (_name != null) {
      return _name;
    }
    String n = super.name;
    if (n != null) {
      return n;
    }
    return "";
  }
}

class ProposalCollector implements CompletionRequestor {
  final CompletionRequestor requestor;

  List<CompletionProposal> _proposals;

  ProposalCollector(this.requestor) {
    this._proposals = new List<CompletionProposal>();
  }

  @override
  accept(CompletionProposal proposal) {
    _proposals.add(proposal);
  }

  @override
  void beginReporting() {
    requestor.beginReporting();
  }

  @override
  void endReporting() {
    requestor.endReporting();
  }

  List<CompletionProposal> get proposals => _proposals;
}

class SearchFilter_CompletionEngine_allSubtypes implements SearchFilter {
  ClassElement classElement;

  SearchFilter_CompletionEngine_allSubtypes(this.classElement);

  @override
  bool passes(SearchMatch match) {
    Element element = match.element;
    if (element is ClassElement) {
      ClassElement clElem = element;
      while (clElem != null) {
        InterfaceType ifType = clElem.supertype;
        if (ifType == null) {
          return false;
        }
        clElem = ifType.element;
        if (identical(clElem, classElement)) {
          return true;
        }
      }
    }
    return false;
  }
}

class TopLevelNamesKind extends Enum<TopLevelNamesKind> {
  static const TopLevelNamesKind DECLARED_AND_IMPORTS = const TopLevelNamesKind('DECLARED_AND_IMPORTS', 0);

  static const TopLevelNamesKind DECLARED_AND_EXPORTS = const TopLevelNamesKind('DECLARED_AND_EXPORTS', 1);

  static const List<TopLevelNamesKind> values = const [DECLARED_AND_IMPORTS, DECLARED_AND_EXPORTS];

  const TopLevelNamesKind(String name, int ordinal) : super(name, ordinal);
}