// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library summary_resynthesizer;

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/handle.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/testing/ast_test_factory.dart';
import 'package:analyzer/src/generated/testing/token_factory.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/summary_sdk.dart';

/**
 * Implementation of [ElementResynthesizer] used when resynthesizing an element
 * model from summaries.
 */
abstract class SummaryResynthesizer extends ElementResynthesizer {
  /**
   * Source factory used to convert URIs to [Source] objects.
   */
  final SourceFactory sourceFactory;

  /**
   * Cache of [Source] objects that have already been converted from URIs.
   */
  final Map<String, Source> _sources = <String, Source>{};

  /**
   * The `dart:core` library for the context.
   */
  LibraryElementImpl _coreLibrary;

  /**
   * The `dart:async` library for the context.
   */
  LibraryElementImpl _asyncLibrary;

  /**
   * The [TypeProvider] used to obtain SDK types during resynthesis.
   */
  TypeProvider _typeProvider;

  /**
   * Indicates whether the summary should be resynthesized assuming strong mode
   * semantics.
   */
  final bool strongMode;

  /**
   * Map of compilation units resynthesized from summaries.  The two map keys
   * are the first two elements of the element's location (the library URI and
   * the compilation unit URI).
   */
  final Map<String, Map<String, CompilationUnitElementImpl>>
      _resynthesizedUnits = <String, Map<String, CompilationUnitElementImpl>>{};

  /**
   * Map of top level elements resynthesized from summaries.  The three map
   * keys are the first three elements of the element's location (the library
   * URI, the compilation unit URI, and the name of the top level declaration).
   */
  final Map<String, Map<String, Map<String, Element>>> _resynthesizedElements =
      <String, Map<String, Map<String, Element>>>{};

  /**
   * Map of libraries which have been resynthesized from summaries.  The map
   * key is the library URI.
   */
  final Map<String, LibraryElement> _resynthesizedLibraries =
      <String, LibraryElement>{};

  SummaryResynthesizer(
      AnalysisContext context, this.sourceFactory, this.strongMode)
      : super(context) {
    _buildTypeProvider();
  }

  /**
   * Number of libraries that have been resynthesized so far.
   */
  int get resynthesisCount => _resynthesizedLibraries.length;

  /**
   * The [TypeProvider] used to obtain SDK types during resynthesis.
   */
  TypeProvider get typeProvider => _typeProvider;

  /**
   * The client installed this resynthesizer into the context, and set its
   * type provider, so it is not safe to access type provider to create
   * additional types.
   */
  void finishCoreAsyncLibraries() {
    _coreLibrary.createLoadLibraryFunction(_typeProvider);
    _asyncLibrary.createLoadLibraryFunction(_typeProvider);
  }

  @override
  Element getElement(ElementLocation location) {
    List<String> components = location.components;
    String libraryUri = components[0];
    // Resynthesize locally.
    if (components.length == 1) {
      return getLibraryElement(libraryUri);
    } else if (components.length == 2) {
      LibraryElement libraryElement = getLibraryElement(libraryUri);
      // Try to find the unit element.
      {
        Map<String, CompilationUnitElement> libraryMap =
            _resynthesizedUnits[libraryUri];
        assert(libraryMap != null);
        String unitUri = components[1];
        CompilationUnitElement unitElement = libraryMap[unitUri];
        if (unitElement != null) {
          return unitElement;
        }
      }
      // Try to find the prefix element.
      {
        String name = components[1];
        for (PrefixElement prefix in libraryElement.prefixes) {
          if (prefix.name == name) {
            return prefix;
          }
        }
      }
      // Fail.
      throw new Exception('The element not found in summary: $location');
    } else if (components.length == 3 || components.length == 4) {
      String unitUri = components[1];
      // Prepare elements-in-units in the library.
      Map<String, Map<String, Element>> unitsInLibrary =
          _resynthesizedElements[libraryUri];
      if (unitsInLibrary == null) {
        unitsInLibrary = new HashMap<String, Map<String, Element>>();
        _resynthesizedElements[libraryUri] = unitsInLibrary;
      }
      // Prepare elements in the unit.
      Map<String, Element> elementsInUnit = unitsInLibrary[unitUri];
      if (elementsInUnit == null) {
        // Prepare the CompilationUnitElementImpl.
        Map<String, CompilationUnitElementImpl> libraryMap =
            _resynthesizedUnits[libraryUri];
        if (libraryMap == null) {
          getLibraryElement(libraryUri);
          libraryMap = _resynthesizedUnits[libraryUri];
          assert(libraryMap != null);
        }
        CompilationUnitElementImpl unitElement = libraryMap[unitUri];
        // Fill elements in the unit map.
        if (unitElement != null) {
          elementsInUnit = new HashMap<String, Element>();
          void putElement(Element e) {
            String id =
                e is PropertyAccessorElementImpl ? e.identifier : e.name;
            elementsInUnit[id] = e;
          }

          unitElement.accessors.forEach(putElement);
          unitElement.enums.forEach(putElement);
          unitElement.functions.forEach(putElement);
          unitElement.functionTypeAliases.forEach(putElement);
          unitElement.topLevelVariables.forEach(putElement);
          unitElement.types.forEach(putElement);
          unitsInLibrary[unitUri] = elementsInUnit;
        }
      }
      // Get the element.
      Element element = elementsInUnit[components[2]];
      if (element != null && components.length == 4) {
        String name = components[3];
        Element parentElement = element;
        if (parentElement is ClassElement) {
          if (name.endsWith('?')) {
            element =
                parentElement.getGetter(name.substring(0, name.length - 1));
          } else if (name.endsWith('=')) {
            element =
                parentElement.getSetter(name.substring(0, name.length - 1));
          } else if (name.isEmpty) {
            element = parentElement.unnamedConstructor;
          } else {
            element = parentElement.getField(name) ??
                parentElement.getMethod(name) ??
                parentElement.getNamedConstructor(name);
          }
        } else {
          // The only elements that are currently retrieved using 4-component
          // locations are class members.
          throw new StateError(
              '4-element locations not supported for ${element.runtimeType}');
        }
      }
      if (element == null) {
        throw new Exception('Element not found in summary: $location');
      }
      return element;
    } else {
      throw new UnimplementedError(location.toString());
    }
  }

  /**
   * Get the [LibraryElement] for the given [uri], resynthesizing it if it
   * hasn't been resynthesized already.
   */
  LibraryElement getLibraryElement(String uri) {
    return _resynthesizedLibraries.putIfAbsent(uri, () {
      LinkedLibrary serializedLibrary = getLinkedSummary(uri);
      Source librarySource = _getSource(uri);
      if (serializedLibrary == null) {
        LibraryElementImpl libraryElement =
            new LibraryElementImpl(context, '', -1, 0);
        libraryElement.isSynthetic = true;
        CompilationUnitElementImpl unitElement =
            new CompilationUnitElementImpl(librarySource.shortName);
        libraryElement.definingCompilationUnit = unitElement;
        unitElement.source = librarySource;
        unitElement.librarySource = librarySource;
        libraryElement.createLoadLibraryFunction(typeProvider);
        libraryElement.publicNamespace = new Namespace({});
        libraryElement.exportNamespace = new Namespace({});
        return libraryElement;
      }
      UnlinkedUnit unlinkedSummary = getUnlinkedSummary(uri);
      if (unlinkedSummary == null) {
        throw new StateError('Unable to find unlinked summary: $uri');
      }
      List<UnlinkedUnit> serializedUnits = <UnlinkedUnit>[unlinkedSummary];
      for (String part in serializedUnits[0].publicNamespace.parts) {
        Source partSource = sourceFactory.resolveUri(librarySource, part);
        UnlinkedUnit partUnlinkedUnit;
        if (partSource != null) {
          String partAbsUri = partSource.uri.toString();
          partUnlinkedUnit = getUnlinkedSummary(partAbsUri);
        }
        serializedUnits.add(partUnlinkedUnit ??
            new UnlinkedUnitBuilder(codeRange: new CodeRangeBuilder()));
      }
      _LibraryResynthesizer libraryResynthesizer = new _LibraryResynthesizer(
          this, serializedLibrary, serializedUnits, librarySource);
      LibraryElement library = libraryResynthesizer.buildLibrary();
      _resynthesizedUnits[uri] = libraryResynthesizer.resynthesizedUnits;
      return library;
    });
  }

  /**
   * Return the [LinkedLibrary] for the given [uri] or `null` if it could not
   * be found.  Caller has already checked that `parent.hasLibrarySummary(uri)`
   * returns `false`.
   */
  LinkedLibrary getLinkedSummary(String uri);

  /**
   * Return the [UnlinkedUnit] for the given [uri] or `null` if it could not
   * be found.  Caller has already checked that `parent.hasLibrarySummary(uri)`
   * returns `false`.
   */
  UnlinkedUnit getUnlinkedSummary(String uri);

  /**
   * Return `true` if this resynthesizer can provide summaries of the libraries
   * with the given [uri].  Caller has already checked that
   * `parent.hasLibrarySummary(uri)` returns `false`.
   */
  bool hasLibrarySummary(String uri);

  void _buildTypeProvider() {
    _coreLibrary = getLibraryElement('dart:core') as LibraryElementImpl;
    _asyncLibrary = getLibraryElement('dart:async') as LibraryElementImpl;
    SummaryTypeProvider summaryTypeProvider = new SummaryTypeProvider();
    summaryTypeProvider.initializeCore(_coreLibrary);
    summaryTypeProvider.initializeAsync(_asyncLibrary);
    _typeProvider = summaryTypeProvider;
  }

  /**
   * Get the [Source] object for the given [uri].
   */
  Source _getSource(String uri) {
    return _sources.putIfAbsent(uri, () => sourceFactory.forUri(uri));
  }
}

/**
 * Builder of [Expression]s from [UnlinkedExpr]s.
 */
class _ConstExprBuilder {
  static const ARGUMENT_LIST = 'ARGUMENT_LIST';

  final _UnitResynthesizer resynthesizer;
  final ElementImpl context;
  final UnlinkedExpr uc;

  int intPtr = 0;
  int doublePtr = 0;
  int stringPtr = 0;
  int refPtr = 0;
  final List<Expression> stack = <Expression>[];

  _ConstExprBuilder(this.resynthesizer, this.context, this.uc);

  /**
   * Return the [ConstructorElement] enclosing [context].
   */
  ConstructorElement get _enclosingConstructor {
    for (Element e = context; e != null; e = e.enclosingElement) {
      if (e is ConstructorElement) {
        return e;
      }
    }
    throw new StateError(
        'Unable to find the enclosing constructor of $context');
  }

  Expression build() {
    if (!uc.isValidConst) {
      return null;
    }
    try {
      for (UnlinkedExprOperation operation in uc.operations) {
        switch (operation) {
          case UnlinkedExprOperation.pushNull:
            _push(AstTestFactory.nullLiteral());
            break;
          // bool
          case UnlinkedExprOperation.pushFalse:
            _push(AstTestFactory.booleanLiteral(false));
            break;
          case UnlinkedExprOperation.pushTrue:
            _push(AstTestFactory.booleanLiteral(true));
            break;
          // literals
          case UnlinkedExprOperation.pushInt:
            int value = uc.ints[intPtr++];
            _push(AstTestFactory.integer(value));
            break;
          case UnlinkedExprOperation.pushLongInt:
            int value = 0;
            int count = uc.ints[intPtr++];
            for (int i = 0; i < count; i++) {
              int next = uc.ints[intPtr++];
              value = value << 32 | next;
            }
            _push(AstTestFactory.integer(value));
            break;
          case UnlinkedExprOperation.pushDouble:
            double value = uc.doubles[doublePtr++];
            _push(AstTestFactory.doubleLiteral(value));
            break;
          case UnlinkedExprOperation.makeSymbol:
            String component = uc.strings[stringPtr++];
            _push(AstTestFactory.symbolLiteral([component]));
            break;
          // String
          case UnlinkedExprOperation.pushString:
            String value = uc.strings[stringPtr++];
            _push(AstTestFactory.string2(value));
            break;
          case UnlinkedExprOperation.concatenate:
            int count = uc.ints[intPtr++];
            List<InterpolationElement> elements = <InterpolationElement>[];
            for (int i = 0; i < count; i++) {
              Expression expr = _pop();
              InterpolationElement element = _newInterpolationElement(expr);
              elements.insert(0, element);
            }
            _push(AstTestFactory.string(elements));
            break;
          // binary
          case UnlinkedExprOperation.equal:
            _pushBinary(TokenType.EQ_EQ);
            break;
          case UnlinkedExprOperation.notEqual:
            _pushBinary(TokenType.BANG_EQ);
            break;
          case UnlinkedExprOperation.and:
            _pushBinary(TokenType.AMPERSAND_AMPERSAND);
            break;
          case UnlinkedExprOperation.or:
            _pushBinary(TokenType.BAR_BAR);
            break;
          case UnlinkedExprOperation.bitXor:
            _pushBinary(TokenType.CARET);
            break;
          case UnlinkedExprOperation.bitAnd:
            _pushBinary(TokenType.AMPERSAND);
            break;
          case UnlinkedExprOperation.bitOr:
            _pushBinary(TokenType.BAR);
            break;
          case UnlinkedExprOperation.bitShiftLeft:
            _pushBinary(TokenType.LT_LT);
            break;
          case UnlinkedExprOperation.bitShiftRight:
            _pushBinary(TokenType.GT_GT);
            break;
          case UnlinkedExprOperation.add:
            _pushBinary(TokenType.PLUS);
            break;
          case UnlinkedExprOperation.subtract:
            _pushBinary(TokenType.MINUS);
            break;
          case UnlinkedExprOperation.multiply:
            _pushBinary(TokenType.STAR);
            break;
          case UnlinkedExprOperation.divide:
            _pushBinary(TokenType.SLASH);
            break;
          case UnlinkedExprOperation.floorDivide:
            _pushBinary(TokenType.TILDE_SLASH);
            break;
          case UnlinkedExprOperation.modulo:
            _pushBinary(TokenType.PERCENT);
            break;
          case UnlinkedExprOperation.greater:
            _pushBinary(TokenType.GT);
            break;
          case UnlinkedExprOperation.greaterEqual:
            _pushBinary(TokenType.GT_EQ);
            break;
          case UnlinkedExprOperation.less:
            _pushBinary(TokenType.LT);
            break;
          case UnlinkedExprOperation.lessEqual:
            _pushBinary(TokenType.LT_EQ);
            break;
          // prefix
          case UnlinkedExprOperation.complement:
            _pushPrefix(TokenType.TILDE);
            break;
          case UnlinkedExprOperation.negate:
            _pushPrefix(TokenType.MINUS);
            break;
          case UnlinkedExprOperation.not:
            _pushPrefix(TokenType.BANG);
            break;
          // conditional
          case UnlinkedExprOperation.conditional:
            Expression elseExpr = _pop();
            Expression thenExpr = _pop();
            Expression condition = _pop();
            _push(AstTestFactory.conditionalExpression(
                condition, thenExpr, elseExpr));
            break;
          // invokeMethodRef
          case UnlinkedExprOperation.invokeMethodRef:
            _pushInvokeMethodRef();
            break;
          // containers
          case UnlinkedExprOperation.makeUntypedList:
            _pushList(null);
            break;
          case UnlinkedExprOperation.makeTypedList:
            TypeAnnotation itemType = _newTypeName();
            _pushList(
                AstTestFactory.typeArgumentList(<TypeAnnotation>[itemType]));
            break;
          case UnlinkedExprOperation.makeUntypedMap:
            _pushMap(null);
            break;
          case UnlinkedExprOperation.makeTypedMap:
            TypeAnnotation keyType = _newTypeName();
            TypeAnnotation valueType = _newTypeName();
            _pushMap(AstTestFactory
                .typeArgumentList(<TypeAnnotation>[keyType, valueType]));
            break;
          case UnlinkedExprOperation.pushReference:
            _pushReference();
            break;
          case UnlinkedExprOperation.extractProperty:
            _pushExtractProperty();
            break;
          case UnlinkedExprOperation.invokeConstructor:
            _pushInstanceCreation();
            break;
          case UnlinkedExprOperation.pushParameter:
            String name = uc.strings[stringPtr++];
            SimpleIdentifier identifier = AstTestFactory.identifier3(name);
            identifier.staticElement = _enclosingConstructor.parameters
                .firstWhere((parameter) => parameter.name == name,
                    orElse: () => throw new StateError(
                        'Unable to resolve constructor parameter: $name'));
            _push(identifier);
            break;
          case UnlinkedExprOperation.ifNull:
            _pushBinary(TokenType.QUESTION_QUESTION);
            break;
          case UnlinkedExprOperation.await:
            Expression expression = _pop();
            _push(AstTestFactory.awaitExpression(expression));
            break;
          case UnlinkedExprOperation.pushSuper:
          case UnlinkedExprOperation.pushThis:
            throw const _UnresolvedReferenceException();
          case UnlinkedExprOperation.assignToRef:
          case UnlinkedExprOperation.assignToProperty:
          case UnlinkedExprOperation.assignToIndex:
          case UnlinkedExprOperation.extractIndex:
          case UnlinkedExprOperation.invokeMethod:
          case UnlinkedExprOperation.cascadeSectionBegin:
          case UnlinkedExprOperation.cascadeSectionEnd:
          case UnlinkedExprOperation.typeCast:
          case UnlinkedExprOperation.typeCheck:
          case UnlinkedExprOperation.throwException:
          case UnlinkedExprOperation.pushLocalFunctionReference:
          case UnlinkedExprOperation.pushError:
          case UnlinkedExprOperation.pushTypedAbstract:
          case UnlinkedExprOperation.pushUntypedAbstract:
            throw new UnimplementedError(
                'Unexpected $operation in a constant expression.');
        }
      }
    } on _UnresolvedReferenceException {
      return AstTestFactory.identifier3(r'#invalidConst');
    }
    return stack.single;
  }

  List<Expression> _buildArguments() {
    List<Expression> arguments;
    {
      int numNamedArgs = uc.ints[intPtr++];
      int numPositionalArgs = uc.ints[intPtr++];
      int numArgs = numNamedArgs + numPositionalArgs;
      arguments = _removeTopItems(numArgs);
      // add names to the named arguments
      for (int i = 0; i < numNamedArgs; i++) {
        String name = uc.strings[stringPtr++];
        int index = numPositionalArgs + i;
        arguments[index] =
            AstTestFactory.namedExpression2(name, arguments[index]);
      }
    }
    return arguments;
  }

  /**
   * Build the identifier sequence (a single or prefixed identifier, or a
   * property access) corresponding to the given reference [info].
   */
  Expression _buildIdentifierSequence(_ReferenceInfo info) {
    Expression enclosing;
    if (info.enclosing != null) {
      enclosing = _buildIdentifierSequence(info.enclosing);
    }
    Element element = info.element;
    if (element == null && info.name == 'length') {
      element = _getStringLengthElement();
    }
    if (enclosing == null) {
      return AstTestFactory.identifier3(info.name)..staticElement = element;
    }
    if (enclosing is SimpleIdentifier) {
      SimpleIdentifier identifier = AstTestFactory.identifier3(info.name)
        ..staticElement = element;
      return AstTestFactory.identifier(enclosing, identifier);
    }
    if (element == null) {
      throw const _UnresolvedReferenceException();
    }
    SimpleIdentifier property = AstTestFactory.identifier3(info.name)
      ..staticElement = element;
    return AstTestFactory.propertyAccess(enclosing, property);
  }

  TypeAnnotation _buildTypeAst(DartType type) {
    List<TypeAnnotation> argumentNodes;
    if (type is ParameterizedType) {
      if (!resynthesizer.libraryResynthesizer.typesWithImplicitTypeArguments
          .contains(type)) {
        List<DartType> typeArguments = type.typeArguments;
        argumentNodes = typeArguments.every((a) => a.isDynamic)
            ? null
            : typeArguments.map(_buildTypeAst).toList();
      }
    }
    TypeName node = AstTestFactory.typeName4(type.name, argumentNodes);
    node.type = type;
    (node.name as SimpleIdentifier).staticElement = type.element;
    return node;
  }

  PropertyAccessorElement _getStringLengthElement() =>
      resynthesizer.typeProvider.stringType.getGetter('length');

  InterpolationElement _newInterpolationElement(Expression expr) {
    if (expr is SimpleStringLiteral) {
      return astFactory.interpolationString(expr.literal, expr.value);
    } else {
      return astFactory.interpolationExpression(
          TokenFactory.tokenFromType(TokenType.STRING_INTERPOLATION_EXPRESSION),
          expr,
          TokenFactory.tokenFromType(TokenType.CLOSE_CURLY_BRACKET));
    }
  }

  /**
   * Convert the next reference to the [DartType] and return the AST
   * corresponding to this type.
   */
  TypeAnnotation _newTypeName() {
    EntityRef typeRef = uc.references[refPtr++];
    DartType type = resynthesizer.buildType(context, typeRef);
    return _buildTypeAst(type);
  }

  Expression _pop() => stack.removeLast();

  void _push(Expression expr) {
    stack.add(expr);
  }

  void _pushBinary(TokenType operator) {
    Expression right = _pop();
    Expression left = _pop();
    _push(AstTestFactory.binaryExpression(left, operator, right));
  }

  void _pushExtractProperty() {
    Expression target = _pop();
    String name = uc.strings[stringPtr++];
    SimpleIdentifier propertyNode = AstTestFactory.identifier3(name);
    // Only String.length property access can be potentially resolved.
    if (name == 'length') {
      propertyNode.staticElement = _getStringLengthElement();
    }
    _push(AstTestFactory.propertyAccess(target, propertyNode));
  }

  void _pushInstanceCreation() {
    EntityRef ref = uc.references[refPtr++];
    _ReferenceInfo info = resynthesizer.getReferenceInfo(ref.reference);
    // prepare ConstructorElement
    TypeName typeNode;
    String constructorName;
    ConstructorElement constructorElement;
    if (info.element != null) {
      if (info.element is ConstructorElement) {
        constructorName = info.name;
      } else if (info.element is ClassElement) {
        constructorName = null;
      } else {
        List<Expression> arguments = _buildArguments();
        SimpleIdentifier name = AstTestFactory.identifier3(info.name);
        name.staticElement = info.element;
        name.setProperty(ARGUMENT_LIST, AstTestFactory.argumentList(arguments));
        _push(name);
        return;
      }
      InterfaceType definingType = resynthesizer._createConstructorDefiningType(
          context, info, ref.typeArguments);
      constructorElement =
          resynthesizer._getConstructorForInfo(definingType, info);
      typeNode = _buildTypeAst(definingType);
    } else {
      if (info.enclosing != null) {
        if (info.enclosing.enclosing != null) {
          PrefixedIdentifier typeName = AstTestFactory.identifier5(
              info.enclosing.enclosing.name, info.enclosing.name);
          typeName.prefix.staticElement = info.enclosing.enclosing.element;
          typeName.identifier.staticElement = info.enclosing.element;
          typeName.identifier.staticType = info.enclosing.type;
          typeNode = AstTestFactory.typeName3(typeName);
          typeNode.type = info.enclosing.type;
          constructorName = info.name;
        } else if (info.enclosing.element != null) {
          SimpleIdentifier typeName =
              AstTestFactory.identifier3(info.enclosing.name);
          typeName.staticElement = info.enclosing.element;
          typeName.staticType = info.enclosing.type;
          typeNode = AstTestFactory.typeName3(typeName);
          typeNode.type = info.enclosing.type;
          constructorName = info.name;
        } else {
          typeNode = AstTestFactory.typeName3(
              AstTestFactory.identifier5(info.enclosing.name, info.name));
          constructorName = null;
        }
      } else {
        typeNode = AstTestFactory.typeName4(info.name);
      }
    }
    // prepare arguments
    List<Expression> arguments = _buildArguments();
    // create ConstructorName
    ConstructorName constructorNode;
    if (constructorName != null) {
      constructorNode =
          AstTestFactory.constructorName(typeNode, constructorName);
      constructorNode.name.staticElement = constructorElement;
    } else {
      constructorNode = AstTestFactory.constructorName(typeNode, null);
    }
    constructorNode.staticElement = constructorElement;
    if (constructorElement == null) {
      throw const _UnresolvedReferenceException();
    }
    // create InstanceCreationExpression
    InstanceCreationExpression instanceCreation = AstTestFactory
        .instanceCreationExpression(Keyword.CONST, constructorNode, arguments);
    instanceCreation.staticElement = constructorElement;
    _push(instanceCreation);
  }

  void _pushInvokeMethodRef() {
    List<Expression> arguments = _buildArguments();
    EntityRef ref = uc.references[refPtr++];
    _ReferenceInfo info = resynthesizer.getReferenceInfo(ref.reference);
    Expression node = _buildIdentifierSequence(info);
    TypeArgumentList typeArguments;
    int numTypeArguments = uc.ints[intPtr++];
    if (numTypeArguments > 0) {
      List<TypeAnnotation> typeNames =
          new List<TypeAnnotation>(numTypeArguments);
      for (int i = 0; i < numTypeArguments; i++) {
        typeNames[i] = _newTypeName();
      }
      typeArguments = AstTestFactory.typeArgumentList(typeNames);
    }
    if (node is SimpleIdentifier) {
      _push(astFactory.methodInvocation(
          null,
          TokenFactory.tokenFromType(TokenType.PERIOD),
          node,
          typeArguments,
          AstTestFactory.argumentList(arguments)));
    } else {
      throw new UnimplementedError('For ${node?.runtimeType}: $node');
    }
  }

  void _pushList(TypeArgumentList typeArguments) {
    int count = uc.ints[intPtr++];
    List<Expression> elements = <Expression>[];
    for (int i = 0; i < count; i++) {
      elements.insert(0, _pop());
    }
    _push(AstTestFactory.listLiteral2(Keyword.CONST, typeArguments, elements));
  }

  void _pushMap(TypeArgumentList typeArguments) {
    int count = uc.ints[intPtr++];
    List<MapLiteralEntry> entries = <MapLiteralEntry>[];
    for (int i = 0; i < count; i++) {
      Expression value = _pop();
      Expression key = _pop();
      entries.insert(0, AstTestFactory.mapLiteralEntry2(key, value));
    }
    _push(AstTestFactory.mapLiteral(Keyword.CONST, typeArguments, entries));
  }

  void _pushPrefix(TokenType operator) {
    Expression operand = _pop();
    _push(AstTestFactory.prefixExpression(operator, operand));
  }

  void _pushReference() {
    EntityRef ref = uc.references[refPtr++];
    _ReferenceInfo info = resynthesizer.getReferenceInfo(ref.reference);
    Expression node = _buildIdentifierSequence(info);
    if (node is Identifier && node.staticElement == null) {
      throw const _UnresolvedReferenceException();
    }
    _push(node);
  }

  List<Expression> _removeTopItems(int count) {
    int start = stack.length - count;
    int end = stack.length;
    List<Expression> items = stack.getRange(start, end).toList();
    stack.removeRange(start, end);
    return items;
  }
}

/**
 * Local function element representing the initializer for a variable that has
 * been resynthesized from a summary.  The actual element won't be constructed
 * until it is requested.  But properties [context] and [enclosingElement] can
 * be used without creating the actual element.
 */
class _DeferredInitializerElement extends FunctionElementHandle {
  /**
   * The variable element containing this element.
   */
  @override
  final VariableElement enclosingElement;

  _DeferredInitializerElement(this.enclosingElement) : super(null, null);

  @override
  FunctionElement get actualElement => enclosingElement.initializer;

  @override
  AnalysisContext get context => enclosingElement.context;

  @override
  ElementLocation get location => actualElement.location;
}

/**
 * An instance of [_LibraryResynthesizer] is responsible for resynthesizing the
 * elements in a single library from that library's summary.
 */
class _LibraryResynthesizer {
  /**
   * The [SummaryResynthesizer] which is being used to obtain summaries.
   */
  final SummaryResynthesizer summaryResynthesizer;

  /**
   * Linked summary of the library to be resynthesized.
   */
  final LinkedLibrary linkedLibrary;

  /**
   * Unlinked compilation units constituting the library to be resynthesized.
   */
  final List<UnlinkedUnit> unlinkedUnits;

  /**
   * [Source] object for the library to be resynthesized.
   */
  final Source librarySource;

  /**
   * The URI of [librarySource].
   */
  String libraryUri;

  /**
   * Indicates whether [librarySource] is the `dart:core` library.
   */
  bool isCoreLibrary;

  /**
   * The resynthesized library.
   */
  LibraryElementImpl library;

  /**
   * Map of compilation unit elements that have been resynthesized so far.  The
   * key is the URI of the compilation unit.
   */
  final Map<String, CompilationUnitElementImpl> resynthesizedUnits =
      <String, CompilationUnitElementImpl>{};

  /**
   * Types with implicit type arguments, which are the same as type parameter
   * bounds (in strong mode), or `dynamic` (in spec mode).
   */
  final Set<DartType> typesWithImplicitTypeArguments =
      new Set<DartType>.identity();

  _LibraryResynthesizer(this.summaryResynthesizer, this.linkedLibrary,
      this.unlinkedUnits, this.librarySource) {
    libraryUri = librarySource.uri.toString();
    isCoreLibrary = libraryUri == 'dart:core';
  }

  /**
   * Resynthesize a [NamespaceCombinator].
   */
  NamespaceCombinator buildCombinator(UnlinkedCombinator serializedCombinator) {
    if (serializedCombinator.shows.isNotEmpty) {
      return new ShowElementCombinatorImpl.forSerialized(serializedCombinator);
    } else {
      return new HideElementCombinatorImpl.forSerialized(serializedCombinator);
    }
  }

  /**
   * Build an [ElementHandle] referring to the entity referred to by the given
   * [exportName].
   */
  ElementHandle buildExportName(LinkedExportName exportName) {
    String name = exportName.name;
    if (exportName.kind == ReferenceKind.topLevelPropertyAccessor &&
        !name.endsWith('=')) {
      name += '?';
    }
    ElementLocationImpl location = new ElementLocationImpl.con3(
        getReferencedLocationComponents(
            exportName.dependency, exportName.unit, name));
    switch (exportName.kind) {
      case ReferenceKind.classOrEnum:
        return new ClassElementHandle(summaryResynthesizer, location);
      case ReferenceKind.typedef:
        return new FunctionTypeAliasElementHandle(
            summaryResynthesizer, location);
      case ReferenceKind.genericFunctionTypedef:
        return new GenericTypeAliasElementHandle(
            summaryResynthesizer, location);
      case ReferenceKind.topLevelFunction:
        return new FunctionElementHandle(summaryResynthesizer, location);
      case ReferenceKind.topLevelPropertyAccessor:
        return new PropertyAccessorElementHandle(
            summaryResynthesizer, location);
      case ReferenceKind.constructor:
      case ReferenceKind.function:
      case ReferenceKind.propertyAccessor:
      case ReferenceKind.method:
      case ReferenceKind.prefix:
      case ReferenceKind.unresolved:
      case ReferenceKind.variable:
        // Should never happen.  Exported names never refer to import prefixes,
        // and they always refer to defined top-level entities.
        throw new StateError('Unexpected export name kind: ${exportName.kind}');
    }
    return null;
  }

  /**
   * Build the export namespace for the library by aggregating together its
   * [publicNamespace] and [exportNames].
   */
  Namespace buildExportNamespace(
      Namespace publicNamespace, List<LinkedExportName> exportNames) {
    HashMap<String, Element> definedNames = new HashMap<String, Element>();
    // Start by populating all the public names from [publicNamespace].
    publicNamespace.definedNames.forEach((String name, Element element) {
      definedNames[name] = element;
    });
    // Add all the names from [exportNames].
    for (LinkedExportName exportName in exportNames) {
      definedNames.putIfAbsent(
          exportName.name, () => buildExportName(exportName));
    }
    return new Namespace(definedNames);
  }

  /**
   * Main entry point.  Resynthesize the [LibraryElement] and return it.
   */
  LibraryElement buildLibrary() {
    // Create LibraryElementImpl.
    bool hasName = unlinkedUnits[0].libraryName.isNotEmpty;
    library = new LibraryElementImpl.forSerialized(
        summaryResynthesizer.context,
        unlinkedUnits[0].libraryName,
        hasName ? unlinkedUnits[0].libraryNameOffset : -1,
        unlinkedUnits[0].libraryNameLength,
        new _LibraryResynthesizerContext(this),
        unlinkedUnits[0]);
    // Create the defining unit.
    _UnitResynthesizer definingUnitResynthesizer =
        createUnitResynthesizer(0, librarySource, null);
    CompilationUnitElementImpl definingUnit = definingUnitResynthesizer.unit;
    library.definingCompilationUnit = definingUnit;
    definingUnit.source = librarySource;
    definingUnit.librarySource = librarySource;
    // Create parts.
    List<_UnitResynthesizer> partResynthesizers = <_UnitResynthesizer>[];
    UnlinkedUnit unlinkedDefiningUnit = unlinkedUnits[0];
    assert(unlinkedDefiningUnit.publicNamespace.parts.length + 1 ==
        linkedLibrary.units.length);
    for (int i = 1; i < linkedLibrary.units.length; i++) {
      _UnitResynthesizer partResynthesizer = buildPart(
          definingUnitResynthesizer,
          unlinkedDefiningUnit.publicNamespace.parts[i - 1],
          unlinkedDefiningUnit.parts[i - 1],
          i);
      if (partResynthesizer != null) {
        partResynthesizers.add(partResynthesizer);
      }
    }
    library.parts = partResynthesizers.map((r) => r.unit).toList();
    // Populate units.
    rememberUriToUnit(definingUnitResynthesizer);
    for (_UnitResynthesizer partResynthesizer in partResynthesizers) {
      rememberUriToUnit(partResynthesizer);
    }
    // Create the synthetic element for `loadLibrary`.
    // Until the client received dart:core and dart:async, we cannot do this,
    // because the TypeProvider is not fully initialized. So, it is up to the
    // Dart SDK client to initialize TypeProvider and finish the dart:core and
    // dart:async libraries creation.
    if (library.name != 'dart.core' && library.name != 'dart.async') {
      library.createLoadLibraryFunction(summaryResynthesizer.typeProvider);
    }
    // Done.
    return library;
  }

  /**
   * Create a [_UnitResynthesizer] that will resynthesize the part with the
   * given [uri]. Return `null` if the [uri] is invalid.
   */
  _UnitResynthesizer buildPart(_UnitResynthesizer definingUnitResynthesizer,
      String uri, UnlinkedPart partDecl, int unitNum) {
    Source unitSource =
        summaryResynthesizer.sourceFactory.resolveUri(librarySource, uri);
    _UnitResynthesizer partResynthesizer =
        createUnitResynthesizer(unitNum, unitSource, partDecl);
    CompilationUnitElementImpl partUnit = partResynthesizer.unit;
    partUnit.uriOffset = partDecl.uriOffset;
    partUnit.uriEnd = partDecl.uriEnd;
    partUnit.source = unitSource;
    partUnit.librarySource = librarySource;
    partUnit.uri = uri;
    return partResynthesizer;
  }

  /**
   * Set up data structures for deserializing a compilation unit.
   */
  _UnitResynthesizer createUnitResynthesizer(
      int unitNum, Source unitSource, UnlinkedPart unlinkedPart) {
    LinkedUnit linkedUnit = linkedLibrary.units[unitNum];
    UnlinkedUnit unlinkedUnit = unlinkedUnits[unitNum];
    return new _UnitResynthesizer(
        this, unlinkedUnit, linkedUnit, unitSource, unlinkedPart);
  }

  /**
   * Build the components of an [ElementLocationImpl] for the entity in the
   * given [unit] of the dependency located at [dependencyIndex], and having
   * the given [name].
   */
  List<String> getReferencedLocationComponents(
      int dependencyIndex, int unit, String name) {
    if (dependencyIndex == 0) {
      String referencedLibraryUri = libraryUri;
      String partUri;
      if (unit != 0) {
        String uri = unlinkedUnits[0].publicNamespace.parts[unit - 1];
        Source partSource =
            summaryResynthesizer.sourceFactory.resolveUri(librarySource, uri);
        partUri = partSource.uri.toString();
      } else {
        partUri = referencedLibraryUri;
      }
      return <String>[referencedLibraryUri, partUri, name];
    }
    LinkedDependency dependency = linkedLibrary.dependencies[dependencyIndex];
    Source referencedLibrarySource = summaryResynthesizer.sourceFactory
        .resolveUri(librarySource, dependency.uri);
    String referencedLibraryUri = referencedLibrarySource.uri.toString();
    String partUri;
    if (unit != 0) {
      String uri = dependency.parts[unit - 1];
      Source partSource =
          summaryResynthesizer.sourceFactory.resolveUri(librarySource, uri);
      partUri = partSource.uri.toString();
    } else {
      partUri = referencedLibraryUri;
    }
    return <String>[referencedLibraryUri, partUri, name];
  }

  /**
   * Remember the absolute URI to the corresponding unit mapping.
   */
  void rememberUriToUnit(_UnitResynthesizer unitResynthesizer) {
    CompilationUnitElementImpl unit = unitResynthesizer.unit;
    Source source = unit.source;
    if (source != null) {
      String absoluteUri = source.uri.toString();
      resynthesizedUnits[absoluteUri] = unit;
    }
  }
}

/**
 * Implementation of [LibraryResynthesizerContext] for [_LibraryResynthesizer].
 */
class _LibraryResynthesizerContext implements LibraryResynthesizerContext {
  final _LibraryResynthesizer resynthesizer;

  _LibraryResynthesizerContext(this.resynthesizer);

  @override
  LinkedLibrary get linkedLibrary => resynthesizer.linkedLibrary;

  @override
  LibraryElement buildExportedLibrary(String relativeUri) {
    return _getLibraryByRelativeUri(relativeUri);
  }

  @override
  Namespace buildExportNamespace() {
    LibraryElementImpl library = resynthesizer.library;
    return resynthesizer.buildExportNamespace(
        library.publicNamespace, resynthesizer.linkedLibrary.exportNames);
  }

  @override
  LibraryElement buildImportedLibrary(int dependency) {
    String depUri = resynthesizer.linkedLibrary.dependencies[dependency].uri;
    return _getLibraryByRelativeUri(depUri);
  }

  @override
  Namespace buildPublicNamespace() {
    LibraryElementImpl library = resynthesizer.library;
    return new NamespaceBuilder().createPublicNamespaceForLibrary(library);
  }

  @override
  FunctionElement findEntryPoint() {
    LibraryElementImpl library = resynthesizer.library;
    Element entryPoint =
        library.exportNamespace.get(FunctionElement.MAIN_FUNCTION_NAME);
    if (entryPoint is FunctionElement) {
      return entryPoint;
    }
    return null;
  }

  @override
  void patchTopLevelAccessors() {
    LibraryElementImpl library = resynthesizer.library;
    BuildLibraryElementUtils.patchTopLevelAccessors(library);
  }

  LibraryElementHandle _getLibraryByRelativeUri(String depUri) {
    Source source = resynthesizer.summaryResynthesizer.sourceFactory
        .resolveUri(resynthesizer.librarySource, depUri);
    if (source == null) {
      return null;
    }
    String absoluteUri = source.uri.toString();
    return new LibraryElementHandle(resynthesizer.summaryResynthesizer,
        new ElementLocationImpl.con3(<String>[absoluteUri]));
  }
}

/**
 * Data structure used during resynthesis to record all the information that is
 * known about how to resynthesize a single entry in [LinkedUnit.references]
 * (and its associated entry in [UnlinkedUnit.references], if it exists).
 */
class _ReferenceInfo {
  /**
   * The [_LibraryResynthesizer] which is being used to obtain summaries.
   */
  final _LibraryResynthesizer libraryResynthesizer;

  /**
   * The enclosing [_ReferenceInfo], or `null` for top-level elements.
   */
  final _ReferenceInfo enclosing;

  /**
   * The name of the entity referred to by this reference.
   */
  final String name;

  /**
   * Is `true` if the [element] can be used as a declared type.
   */
  final bool isDeclarableType;

  /**
   * The element referred to by this reference, or `null` if there is no
   * associated element (e.g. because it is a reference to an undefined
   * entity).
   */
  final Element element;

  /**
   * If this reference refers to a non-generic type, the type it refers to.
   * Otherwise `null`.
   */
  DartType _type;

  /**
   * The number of type parameters accepted by the entity referred to by this
   * reference, or zero if it doesn't accept any type parameters.
   */
  final int numTypeParameters;

  bool _isBeingInstantiatedToBounds = false;
  bool _isRecursiveWhileInstantiateToBounds = false;

  /**
   * Create a new [_ReferenceInfo] object referring to an element called [name]
   * via the element handle [element], and having [numTypeParameters] type
   * parameters.
   *
   * For the special types `dynamic` and `void`, [specialType] should point to
   * the type itself.  Otherwise, pass `null` and the type will be computed
   * when appropriate.
   */
  _ReferenceInfo(
      this.libraryResynthesizer,
      this.enclosing,
      this.name,
      this.isDeclarableType,
      this.element,
      DartType specialType,
      this.numTypeParameters) {
    if (specialType != null) {
      _type = specialType;
    }
  }

  /**
   * If this reference refers to a non-generic type, the type it refers to.
   * Otherwise `null`.
   */
  DartType get type {
    if (_type == null) {
      _type = _buildType(true, 0, (_) => DynamicTypeImpl.instance, const []);
    }
    return _type;
  }

  List<DartType> get _dynamicTypeArguments =>
      new List<DartType>.filled(numTypeParameters, DynamicTypeImpl.instance);

  /**
   * Build a [DartType] corresponding to the result of applying some type
   * arguments to the entity referred to by this [_ReferenceInfo].  The type
   * arguments are retrieved by calling [getTypeArgument].
   *
   * If [implicitFunctionTypeIndices] is not empty, a [DartType] should be
   * created which refers to a function type implicitly defined by one of the
   * element's parameters.  [implicitFunctionTypeIndices] is interpreted as in
   * [EntityRef.implicitFunctionTypeIndices].
   *
   * If the entity referred to by this [_ReferenceInfo] is not a type, `null`
   * is returned.
   */
  DartType buildType(bool instantiateToBoundsAllowed, int numTypeArguments,
      DartType getTypeArgument(int i), List<int> implicitFunctionTypeIndices) {
    DartType result =
        (numTypeParameters == 0 && implicitFunctionTypeIndices.isEmpty)
            ? type
            : _buildType(instantiateToBoundsAllowed, numTypeArguments,
                getTypeArgument, implicitFunctionTypeIndices);
    if (result == null) {
      return DynamicTypeImpl.instance;
    }
    return result;
  }

  /**
   * If this reference refers to a type, build a [DartType].  Otherwise return
   * `null`.  If [numTypeArguments] is the same as the [numTypeParameters],
   * the type is instantiated with type arguments returned by [getTypeArgument],
   * otherwise it is instantiated with type parameter bounds (if strong mode),
   * or with `dynamic` type arguments.
   *
   * If [implicitFunctionTypeIndices] is not null, a [DartType] should be
   * created which refers to a function type implicitly defined by one of the
   * element's parameters.  [implicitFunctionTypeIndices] is interpreted as in
   * [EntityRef.implicitFunctionTypeIndices].
   */
  DartType _buildType(bool instantiateToBoundsAllowed, int numTypeArguments,
      DartType getTypeArgument(int i), List<int> implicitFunctionTypeIndices) {
    ElementHandle element = this.element; // To allow type promotion
    if (element is ClassElementHandle) {
      List<DartType> typeArguments = null;
      // If type arguments are specified, use them.
      // Otherwise, delay until they are requested.
      if (numTypeParameters == 0) {
        return element.type;
      } else if (numTypeArguments == numTypeParameters) {
        typeArguments = _buildTypeArguments(numTypeArguments, getTypeArgument);
      }
      InterfaceTypeImpl type =
          new InterfaceTypeImpl.elementWithNameAndArgs(element, name, () {
        if (typeArguments == null) {
          if (libraryResynthesizer.summaryResynthesizer.strongMode &&
              instantiateToBoundsAllowed) {
            InterfaceType instantiatedToBounds = libraryResynthesizer
                .summaryResynthesizer.context.typeSystem
                .instantiateToBounds(element.type) as InterfaceType;
            return instantiatedToBounds.typeArguments;
          } else {
            return _dynamicTypeArguments;
          }
        }
        return typeArguments;
      });
      // Mark the type as having implicit type arguments, so that we don't
      // attempt to request them during constant expression resynthesizing.
      if (typeArguments == null) {
        libraryResynthesizer.typesWithImplicitTypeArguments.add(type);
      }
      // Done.
      return type;
    } else if (element is GenericTypeAliasElementHandle) {
      GenericTypeAliasElementImpl actualElement = element.actualElement;
      List<DartType> argumentTypes =
          new List.generate(numTypeArguments, getTypeArgument);
      return actualElement.typeAfterSubstitution(argumentTypes);
    } else if (element is FunctionTypedElement) {
      if (element is FunctionTypeAliasElementHandle) {
        List<DartType> typeArguments;
        if (numTypeArguments == numTypeParameters) {
          typeArguments =
              _buildTypeArguments(numTypeArguments, getTypeArgument);
        } else if (libraryResynthesizer.summaryResynthesizer.strongMode &&
            instantiateToBoundsAllowed) {
          if (!_isBeingInstantiatedToBounds) {
            _isBeingInstantiatedToBounds = true;
            _isRecursiveWhileInstantiateToBounds = false;
            try {
              FunctionType instantiatedToBounds = libraryResynthesizer
                  .summaryResynthesizer.context.typeSystem
                  .instantiateToBounds(element.type) as FunctionType;
              if (!_isRecursiveWhileInstantiateToBounds) {
                typeArguments = instantiatedToBounds.typeArguments;
              } else {
                typeArguments = _dynamicTypeArguments;
              }
            } finally {
              _isBeingInstantiatedToBounds = false;
            }
          } else {
            _isRecursiveWhileInstantiateToBounds = true;
            typeArguments = _dynamicTypeArguments;
          }
        } else {
          typeArguments = _dynamicTypeArguments;
        }
        return new FunctionTypeImpl.elementWithNameAndArgs(
            element, name, typeArguments, numTypeParameters != 0);
      } else {
        FunctionTypedElementComputer computer;
        if (implicitFunctionTypeIndices.isNotEmpty) {
          numTypeArguments = numTypeParameters;
          computer = () {
            FunctionTypedElement element = this.element;
            for (int index in implicitFunctionTypeIndices) {
              element = element.parameters[index].type.element;
            }
            return element;
          };
        } else {
          // For a type that refers to a generic executable, the type arguments are
          // not supposed to include the arguments to the executable itself.
          numTypeArguments = enclosing?.numTypeParameters ?? 0;
          computer = () => this.element as FunctionTypedElement;
        }
        // TODO(paulberry): Is it a bug that we have to pass `false` for
        // isInstantiated?
        return new DeferredFunctionTypeImpl(computer, null,
            _buildTypeArguments(numTypeArguments, getTypeArgument), false);
      }
    } else {
      return null;
    }
  }

  /**
   * Build a list of type arguments having length [numTypeArguments] where each
   * type argument is obtained by calling [getTypeArgument].
   */
  List<DartType> _buildTypeArguments(
      int numTypeArguments, DartType getTypeArgument(int i)) {
    List<DartType> typeArguments = const <DartType>[];
    if (numTypeArguments != 0) {
      typeArguments = new List<DartType>(numTypeArguments);
      for (int i = 0; i < numTypeArguments; i++) {
        typeArguments[i] = getTypeArgument(i);
      }
    }
    return typeArguments;
  }
}

class _ResynthesizerContext implements ResynthesizerContext {
  final _UnitResynthesizer _unitResynthesizer;

  _ResynthesizerContext(this._unitResynthesizer);

  @override
  bool get isStrongMode => _unitResynthesizer.summaryResynthesizer.strongMode;

  @override
  ElementAnnotationImpl buildAnnotation(ElementImpl context, UnlinkedExpr uc) {
    return _unitResynthesizer.buildAnnotation(context, uc);
  }

  @override
  Expression buildExpression(ElementImpl context, UnlinkedExpr uc) {
    return _unitResynthesizer._buildConstExpression(context, uc);
  }

  @override
  UnitExplicitTopLevelAccessors buildTopLevelAccessors() {
    return _unitResynthesizer.buildUnitExplicitTopLevelAccessors();
  }

  @override
  UnitExplicitTopLevelVariables buildTopLevelVariables() {
    return _unitResynthesizer.buildUnitExplicitTopLevelVariables();
  }

  @override
  TopLevelInferenceError getTypeInferenceError(int slot) {
    return _unitResynthesizer.getTypeInferenceError(slot);
  }

  @override
  bool inheritsCovariant(int slot) {
    return _unitResynthesizer.parametersInheritingCovariant.contains(slot);
  }

  @override
  bool isInConstCycle(int slot) {
    return _unitResynthesizer.constCycles.contains(slot);
  }

  @override
  ConstructorElement resolveConstructorRef(
      ElementImpl context, EntityRef entry) {
    return _unitResynthesizer._getConstructorForEntry(context, entry);
  }

  @override
  DartType resolveLinkedType(ElementImpl context, int slot) {
    return _unitResynthesizer.buildLinkedType(context, slot);
  }

  @override
  DartType resolveTypeRef(ElementImpl context, EntityRef type,
      {bool defaultVoid: false,
      bool instantiateToBoundsAllowed: true,
      bool declaredType: false}) {
    return _unitResynthesizer.buildType(context, type,
        defaultVoid: defaultVoid,
        instantiateToBoundsAllowed: instantiateToBoundsAllowed,
        declaredType: declaredType);
  }
}

/**
 * An instance of [_UnitResynthesizer] is responsible for resynthesizing the
 * elements in a single unit from that unit's summary.
 */
class _UnitResynthesizer {
  /**
   * The [_LibraryResynthesizer] which is being used to obtain summaries.
   */
  final _LibraryResynthesizer libraryResynthesizer;

  /**
   * The [UnlinkedUnit] from which elements are currently being resynthesized.
   */
  final UnlinkedUnit unlinkedUnit;

  /**
   * The [LinkedUnit] from which elements are currently being resynthesized.
   */
  final LinkedUnit linkedUnit;

  /**
   * The [CompilationUnitElementImpl] for the compilation unit currently being
   * resynthesized.
   */
  CompilationUnitElementImpl unit;

  /**
   * Map from slot id to the corresponding [EntityRef] object for linked types
   * (i.e. propagated and inferred types).
   */
  final Map<int, EntityRef> linkedTypeMap = <int, EntityRef>{};

  /**
   * Set of slot ids corresponding to const constructors that are part of
   * cycles.
   */
  Set<int> constCycles;

  /**
   * Set of slot ids corresponding to parameters that inherit `@covariant`
   * behavior.
   */
  Set<int> parametersInheritingCovariant;

  int numLinkedReferences;
  int numUnlinkedReferences;

  /**
   * List of [_ReferenceInfo] objects describing the references in the current
   * compilation unit.  This list is works as a lazily filled cache, use
   * [getReferenceInfo] to get the [_ReferenceInfo] for an index.
   */
  List<_ReferenceInfo> referenceInfos;

  /**
   * The [ResynthesizerContext] for this resynthesize session.
   */
  ResynthesizerContext _resynthesizerContext;

  _UnitResynthesizer(this.libraryResynthesizer, this.unlinkedUnit,
      this.linkedUnit, Source unitSource, UnlinkedPart unlinkedPart) {
    _resynthesizerContext = new _ResynthesizerContext(this);
    unit = new CompilationUnitElementImpl.forSerialized(
        libraryResynthesizer.library,
        _resynthesizerContext,
        unlinkedUnit,
        unlinkedPart,
        unitSource?.shortName);

    {
      List<int> lineStarts = unlinkedUnit.lineStarts;
      if (lineStarts.isEmpty) {
        lineStarts = const <int>[0];
      }
      unit.lineInfo = new LineInfo(lineStarts);
    }

    for (EntityRef t in linkedUnit.types) {
      linkedTypeMap[t.slot] = t;
    }
    constCycles = linkedUnit.constCycles.toSet();
    parametersInheritingCovariant =
        linkedUnit.parametersInheritingCovariant.toSet();
    numLinkedReferences = linkedUnit.references.length;
    numUnlinkedReferences = unlinkedUnit.references.length;
    referenceInfos = new List<_ReferenceInfo>(numLinkedReferences);
  }

  SummaryResynthesizer get summaryResynthesizer =>
      libraryResynthesizer.summaryResynthesizer;

  TypeProvider get typeProvider => summaryResynthesizer.typeProvider;

  /**
   * Build [ElementAnnotationImpl] for the given [UnlinkedExpr].
   */
  ElementAnnotationImpl buildAnnotation(ElementImpl context, UnlinkedExpr uc) {
    ElementAnnotationImpl elementAnnotation = new ElementAnnotationImpl(unit);
    Expression constExpr = _buildConstExpression(context, uc);
    if (constExpr == null) {
      // Invalid constant expression.
    } else if (constExpr is Identifier) {
      var element = constExpr.staticElement;
      ArgumentList arguments =
          constExpr.getProperty(_ConstExprBuilder.ARGUMENT_LIST);
      if (element is PropertyAccessorElement && arguments == null) {
        elementAnnotation.element = element;
        elementAnnotation.annotationAst = AstTestFactory.annotation(constExpr);
      } else if (element is ConstructorElement && arguments != null) {
        elementAnnotation.element = element;
        elementAnnotation.annotationAst =
            AstTestFactory.annotation2(constExpr, null, arguments);
      } else {
        elementAnnotation.annotationAst = AstTestFactory
            .annotation(AstTestFactory.identifier3(r'#invalidConst'));
      }
    } else if (constExpr is InstanceCreationExpression) {
      elementAnnotation.element = constExpr.staticElement;
      Identifier typeName = constExpr.constructorName.type.name;
      SimpleIdentifier constructorName = constExpr.constructorName.name;
      if (typeName is SimpleIdentifier && constructorName != null) {
        // E.g. `@cls.ctor()`.  Since `cls.ctor` would have been parsed as
        // a PrefixedIdentifier, we need to resynthesize it as one.
        typeName = AstTestFactory.identifier(typeName, constructorName);
        constructorName = null;
      }
      elementAnnotation.annotationAst = AstTestFactory.annotation2(
          typeName, constructorName, constExpr.argumentList)
        ..element = constExpr.staticElement;
    } else if (constExpr is PropertyAccess) {
      var target = constExpr.target as Identifier;
      var propertyName = constExpr.propertyName;
      var propertyElement = propertyName.staticElement;
      ArgumentList arguments =
          constExpr.getProperty(_ConstExprBuilder.ARGUMENT_LIST);
      if (propertyElement is PropertyAccessorElement && arguments == null) {
        elementAnnotation.element = propertyElement;
        elementAnnotation.annotationAst = AstTestFactory.annotation2(
            target, propertyName, null)
          ..element = propertyElement;
      } else if (propertyElement is ConstructorElement && arguments != null) {
        elementAnnotation.element = propertyElement;
        elementAnnotation.annotationAst = AstTestFactory.annotation2(
            target, propertyName, arguments)
          ..element = propertyElement;
      } else {
        elementAnnotation.annotationAst = AstTestFactory
            .annotation(AstTestFactory.identifier3(r'#invalidConst'));
      }
    } else {
      throw new StateError(
          'Unexpected annotation type: ${constExpr.runtimeType}');
    }
    return elementAnnotation;
  }

  /**
   * Build an implicit getter for the given [property] and bind it to the
   * [property] and to its enclosing element.
   */
  PropertyAccessorElementImpl buildImplicitGetter(
      PropertyInducingElementImpl property) {
    PropertyAccessorElementImpl_ImplicitGetter getter =
        new PropertyAccessorElementImpl_ImplicitGetter(property);
    getter.enclosingElement = property.enclosingElement;
    return getter;
  }

  /**
   * Build an implicit setter for the given [property] and bind it to the
   * [property] and to its enclosing element.
   */
  PropertyAccessorElementImpl buildImplicitSetter(
      PropertyInducingElementImpl property) {
    PropertyAccessorElementImpl_ImplicitSetter setter =
        new PropertyAccessorElementImpl_ImplicitSetter(property);
    setter.enclosingElement = property.enclosingElement;
    return setter;
  }

  /**
   * Build the appropriate [DartType] object corresponding to a slot id in the
   * [LinkedUnit.types] table.
   */
  DartType buildLinkedType(ElementImpl context, int slot) {
    if (slot == 0) {
      // A slot id of 0 means there is no [DartType] object to build.
      return null;
    }
    EntityRef type = linkedTypeMap[slot];
    if (type == null) {
      // A missing entry in [LinkedUnit.types] means there is no [DartType]
      // stored in this slot.
      return null;
    }
    return buildType(context, type);
  }

  /**
   * Build a [DartType] object based on a [EntityRef].  This [DartType]
   * may refer to elements in other libraries than the library being
   * deserialized, so handles are used to avoid having to deserialize other
   * libraries in the process.
   */
  DartType buildType(ElementImpl context, EntityRef type,
      {bool defaultVoid: false,
      bool instantiateToBoundsAllowed: true,
      bool declaredType: false}) {
    if (type == null) {
      if (defaultVoid) {
        return VoidTypeImpl.instance;
      } else {
        return DynamicTypeImpl.instance;
      }
    }
    if (type.paramReference != 0) {
      return context.typeParameterContext
          .getTypeParameterType(type.paramReference);
    } else if (type.entityKind == EntityRefKind.genericFunctionType) {
      GenericFunctionTypeElement element =
          new GenericFunctionTypeElementImpl.forSerialized(context, type);
      return element.type;
    } else if (type.syntheticReturnType != null) {
      FunctionElementImpl element =
          new FunctionElementImpl_forLUB(context, type);
      return element.type;
    } else {
      DartType getTypeArgument(int i) {
        if (i < type.typeArguments.length) {
          return buildType(context, type.typeArguments[i],
              declaredType: declaredType);
        } else {
          return DynamicTypeImpl.instance;
        }
      }

      _ReferenceInfo referenceInfo = getReferenceInfo(type.reference);
      if (declaredType && !referenceInfo.isDeclarableType) {
        return DynamicTypeImpl.instance;
      }
      return referenceInfo.buildType(
          instantiateToBoundsAllowed,
          type.typeArguments.length,
          getTypeArgument,
          type.implicitFunctionTypeIndices);
    }
  }

  UnitExplicitTopLevelAccessors buildUnitExplicitTopLevelAccessors() {
    HashMap<String, TopLevelVariableElementImpl> implicitVariables =
        new HashMap<String, TopLevelVariableElementImpl>();
    UnitExplicitTopLevelAccessors accessorsData =
        new UnitExplicitTopLevelAccessors();
    for (UnlinkedExecutable unlinkedExecutable in unlinkedUnit.executables) {
      UnlinkedExecutableKind kind = unlinkedExecutable.kind;
      if (kind == UnlinkedExecutableKind.getter ||
          kind == UnlinkedExecutableKind.setter) {
        // name
        String name = unlinkedExecutable.name;
        if (kind == UnlinkedExecutableKind.setter) {
          assert(name.endsWith('='));
          name = name.substring(0, name.length - 1);
        }
        // create
        PropertyAccessorElementImpl accessor =
            new PropertyAccessorElementImpl.forSerialized(
                unlinkedExecutable, unit);
        accessorsData.accessors.add(accessor);
        // implicit variable
        TopLevelVariableElementImpl variable = implicitVariables[name];
        if (variable == null) {
          variable = new TopLevelVariableElementImpl(name, -1);
          variable.enclosingElement = unit;
          implicitVariables[name] = variable;
          accessorsData.implicitVariables.add(variable);
          variable.isSynthetic = true;
          variable.isFinal = kind == UnlinkedExecutableKind.getter;
        } else {
          variable.isFinal = false;
        }
        accessor.variable = variable;
        // link
        if (kind == UnlinkedExecutableKind.getter) {
          variable.getter = accessor;
        } else {
          variable.setter = accessor;
        }
      }
    }
    return accessorsData;
  }

  UnitExplicitTopLevelVariables buildUnitExplicitTopLevelVariables() {
    List<UnlinkedVariable> unlinkedVariables = unlinkedUnit.variables;
    int numberOfVariables = unlinkedVariables.length;
    UnitExplicitTopLevelVariables variablesData =
        new UnitExplicitTopLevelVariables(numberOfVariables);
    for (int i = 0; i < numberOfVariables; i++) {
      UnlinkedVariable unlinkedVariable = unlinkedVariables[i];
      TopLevelVariableElementImpl element;
      if (unlinkedVariable.initializer?.bodyExpr != null &&
          unlinkedVariable.isConst) {
        element = new ConstTopLevelVariableElementImpl.forSerialized(
            unlinkedVariable, unit);
      } else {
        element = new TopLevelVariableElementImpl.forSerialized(
            unlinkedVariable, unit);
      }
      variablesData.variables[i] = element;
      // implicit accessors
      variablesData.implicitAccessors.add(buildImplicitGetter(element));
      if (!(element.isConst || element.isFinal)) {
        variablesData.implicitAccessors.add(buildImplicitSetter(element));
      }
    }
    return variablesData;
  }

  /**
   * Return [_ReferenceInfo] with the given [index], lazily resolving it.
   */
  _ReferenceInfo getReferenceInfo(int index) {
    _ReferenceInfo result = referenceInfos[index];
    if (result == null) {
      LinkedReference linkedReference = linkedUnit.references[index];
      String name;
      int containingReference;
      if (index < numUnlinkedReferences) {
        name = unlinkedUnit.references[index].name;
        containingReference = unlinkedUnit.references[index].prefixReference;
      } else {
        name = linkedUnit.references[index].name;
        containingReference = linkedUnit.references[index].containingReference;
      }
      _ReferenceInfo enclosingInfo = containingReference != 0
          ? getReferenceInfo(containingReference)
          : null;
      Element element;
      DartType type;
      bool isDeclarableType = false;
      int numTypeParameters = linkedReference.numTypeParameters;
      if (linkedReference.kind == ReferenceKind.unresolved) {
        type = UndefinedTypeImpl.instance;
        element = null;
        isDeclarableType = true;
      } else if (name == 'dynamic') {
        type = DynamicTypeImpl.instance;
        element = type.element;
        isDeclarableType = true;
      } else if (name == 'void') {
        type = VoidTypeImpl.instance;
        element = type.element;
        isDeclarableType = true;
      } else if (name == '*bottom*') {
        type = BottomTypeImpl.instance;
        element = null;
        isDeclarableType = true;
      } else {
        List<String> locationComponents;
        if (enclosingInfo != null && enclosingInfo.element is ClassElement) {
          String identifier = _getElementIdentifier(name, linkedReference.kind);
          locationComponents =
              enclosingInfo.element.location.components.toList();
          locationComponents.add(identifier);
        } else {
          String identifier = _getElementIdentifier(name, linkedReference.kind);
          locationComponents =
              libraryResynthesizer.getReferencedLocationComponents(
                  linkedReference.dependency, linkedReference.unit, identifier);
          if (linkedReference.kind == ReferenceKind.prefix) {
            locationComponents = <String>[
              locationComponents[0],
              locationComponents[2]
            ];
          }
        }
        if (!_resynthesizerContext.isStrongMode &&
            locationComponents.length == 3 &&
            locationComponents[0] == 'dart:async' &&
            locationComponents[2] == 'FutureOr') {
          type = typeProvider.dynamicType;
          numTypeParameters = 0;
        }
        ElementLocation location =
            new ElementLocationImpl.con3(locationComponents);
        if (enclosingInfo != null) {
          numTypeParameters += enclosingInfo.numTypeParameters;
        }
        switch (linkedReference.kind) {
          case ReferenceKind.classOrEnum:
            element = new ClassElementHandle(summaryResynthesizer, location);
            isDeclarableType = true;
            break;
          case ReferenceKind.constructor:
            assert(location.components.length == 4);
            element =
                new ConstructorElementHandle(summaryResynthesizer, location);
            break;
          case ReferenceKind.method:
            assert(location.components.length == 4);
            element = new MethodElementHandle(summaryResynthesizer, location);
            break;
          case ReferenceKind.propertyAccessor:
            assert(location.components.length == 4);
            element = new PropertyAccessorElementHandle(
                summaryResynthesizer, location);
            break;
          case ReferenceKind.topLevelFunction:
            assert(location.components.length == 3);
            element = new FunctionElementHandle(summaryResynthesizer, location);
            break;
          case ReferenceKind.topLevelPropertyAccessor:
            element = new PropertyAccessorElementHandle(
                summaryResynthesizer, location);
            break;
          case ReferenceKind.typedef:
          case ReferenceKind.genericFunctionTypedef:
            element = new GenericTypeAliasElementHandle(
                summaryResynthesizer, location);
            isDeclarableType = true;
            break;
          case ReferenceKind.function:
            Element enclosingElement = enclosingInfo.element;
            if (enclosingElement is VariableElement) {
              element = new _DeferredInitializerElement(enclosingElement);
            } else {
              throw new StateError('Unexpected element enclosing function:'
                  ' ${enclosingElement.runtimeType}');
            }
            break;
          case ReferenceKind.prefix:
            element = new PrefixElementHandle(summaryResynthesizer, location);
            break;
          case ReferenceKind.variable:
          case ReferenceKind.unresolved:
            break;
        }
      }
      result = new _ReferenceInfo(libraryResynthesizer, enclosingInfo, name,
          isDeclarableType, element, type, numTypeParameters);
      referenceInfos[index] = result;
    }
    return result;
  }

  /**
   * Return the error reported during type inference for the given [slot],
   * or `null` if there were no error.
   */
  TopLevelInferenceError getTypeInferenceError(int slot) {
    if (slot == 0) {
      return null;
    }
    for (TopLevelInferenceError error in linkedUnit.topLevelInferenceErrors) {
      if (error.slot == slot) {
        return error;
      }
    }
    return null;
  }

  Expression _buildConstExpression(ElementImpl context, UnlinkedExpr uc) {
    return new _ConstExprBuilder(this, context, uc).build();
  }

  /**
   * Return the defining type for a [ConstructorElement] by applying
   * [typeArgumentRefs] to the given linked [info].  Return [DynamicTypeImpl]
   * if the [info] is unresolved.
   */
  DartType _createConstructorDefiningType(ElementImpl context,
      _ReferenceInfo info, List<EntityRef> typeArgumentRefs) {
    bool isClass = info.element is ClassElement;
    _ReferenceInfo classInfo = isClass ? info : info.enclosing;
    if (classInfo == null) {
      return DynamicTypeImpl.instance;
    }
    List<DartType> typeArguments =
        typeArgumentRefs.map((t) => buildType(context, t)).toList();
    return classInfo.buildType(true, typeArguments.length, (i) {
      if (i < typeArguments.length) {
        return typeArguments[i];
      } else {
        return DynamicTypeImpl.instance;
      }
    }, const <int>[]);
  }

  /**
   * Return the [ConstructorElement] corresponding to the given [entry].
   */
  ConstructorElement _getConstructorForEntry(
      ElementImpl context, EntityRef entry) {
    _ReferenceInfo info = getReferenceInfo(entry.reference);
    DartType type =
        _createConstructorDefiningType(context, info, entry.typeArguments);
    if (type is InterfaceType) {
      return _getConstructorForInfo(type, info);
    }
    return null;
  }

  /**
   * Return the [ConstructorElement] corresponding to the given linked [info],
   * using the [classType] which has already been computed (e.g. by
   * [_createConstructorDefiningType]).  Both cases when [info] is a
   * [ClassElement] and [ConstructorElement] are supported.
   */
  ConstructorElement _getConstructorForInfo(
      InterfaceType classType, _ReferenceInfo info) {
    ConstructorElement element;
    Element infoElement = info.element;
    if (infoElement is ConstructorElement) {
      element = infoElement;
    } else if (infoElement is ClassElement) {
      element = infoElement.unnamedConstructor;
    }
    if (element != null && info.numTypeParameters != 0) {
      return new ConstructorMember(element, classType);
    }
    return element;
  }

  /**
   * If the given [kind] is a top-level or class member property accessor, and
   * the given [name] does not end with `=`, i.e. does not denote a setter,
   * return the getter identifier by appending `?`.
   */
  static String _getElementIdentifier(String name, ReferenceKind kind) {
    if (kind == ReferenceKind.topLevelPropertyAccessor ||
        kind == ReferenceKind.propertyAccessor) {
      if (!name.endsWith('=')) {
        return name + '?';
      }
    }
    return name;
  }
}

/**
 * This exception is thrown when we detect that the constant expression
 * being resynthesized cannot be fully resolved, so is not a valid constant
 * expression.
 */
class _UnresolvedReferenceException {
  const _UnresolvedReferenceException();
}
