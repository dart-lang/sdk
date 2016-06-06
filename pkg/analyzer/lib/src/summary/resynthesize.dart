// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library summary_resynthesizer;

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/handle.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/testing/ast_factory.dart';
import 'package:analyzer/src/generated/testing/token_factory.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary/idl.dart';

/**
 * Implementation of [ElementResynthesizer] used when resynthesizing an element
 * model from summaries.
 */
abstract class SummaryResynthesizer extends ElementResynthesizer {
  /**
   * The parent [SummaryResynthesizer] which is asked to resynthesize elements
   * and get summaries before this resynthesizer attempts to do this.
   * Can be `null`.
   */
  final SummaryResynthesizer parent;

  /**
   * Source factory used to convert URIs to [Source] objects.
   */
  final SourceFactory sourceFactory;

  /**
   * Cache of [Source] objects that have already been converted from URIs.
   */
  final Map<String, Source> _sources = <String, Source>{};

  /**
   * The [TypeProvider] used to obtain core types (such as Object, int, List,
   * and dynamic) during resynthesis.
   */
  final TypeProvider typeProvider;

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

  SummaryResynthesizer(this.parent, AnalysisContext context, this.typeProvider,
      this.sourceFactory, this.strongMode)
      : super(context);

  /**
   * Number of libraries that have been resynthesized so far.
   */
  int get resynthesisCount => _resynthesizedLibraries.length;

  /**
   * Perform delayed finalization of the `dart:core` and `dart:async` libraries.
   */
  void finalizeCoreAsyncLibraries() {
    (_resynthesizedLibraries['dart:core'] as LibraryElementImpl)
        .createLoadLibraryFunction(typeProvider);
    (_resynthesizedLibraries['dart:async'] as LibraryElementImpl)
        .createLoadLibraryFunction(typeProvider);
  }

  @override
  Element getElement(ElementLocation location) {
    List<String> components = location.components;
    String libraryUri = components[0];
    // Ask the parent resynthesizer.
    if (parent != null && parent._hasLibrarySummary(libraryUri)) {
      return parent.getElement(location);
    }
    // Resynthesize locally.
    if (components.length == 1) {
      return getLibraryElement(libraryUri);
    } else if (components.length == 2) {
      Map<String, CompilationUnitElement> libraryMap =
          _resynthesizedUnits[libraryUri];
      if (libraryMap == null) {
        getLibraryElement(libraryUri);
        libraryMap = _resynthesizedUnits[libraryUri];
        assert(libraryMap != null);
      }
      String unitUri = components[1];
      CompilationUnitElement element = libraryMap[unitUri];
      if (element == null) {
        throw new Exception('Unit element not found in summary: $location');
      }
      return element;
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
    if (parent != null && parent._hasLibrarySummary(uri)) {
      return parent.getLibraryElement(uri);
    }
    return _resynthesizedLibraries.putIfAbsent(uri, () {
      LinkedLibrary serializedLibrary = _getLinkedSummaryOrThrow(uri);
      List<UnlinkedUnit> serializedUnits = <UnlinkedUnit>[
        _getUnlinkedSummaryOrThrow(uri)
      ];
      Source librarySource = _getSource(uri);
      for (String part in serializedUnits[0].publicNamespace.parts) {
        Source partSource = sourceFactory.resolveUri(librarySource, part);
        String partAbsUri = partSource.uri.toString();
        serializedUnits.add(_getUnlinkedSummaryOrThrow(partAbsUri));
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

  /**
   * Return the [LinkedLibrary] for the given [uri] or throw [StateError] if it
   * could not be found.
   */
  LinkedLibrary _getLinkedSummaryOrThrow(String uri) {
    if (parent != null && parent._hasLibrarySummary(uri)) {
      return parent._getLinkedSummaryOrThrow(uri);
    }
    LinkedLibrary summary = getLinkedSummary(uri);
    if (summary != null) {
      return summary;
    }
    throw new StateError('Unable to find linked summary: $uri');
  }

  /**
   * Get the [Source] object for the given [uri].
   */
  Source _getSource(String uri) {
    return _sources.putIfAbsent(uri, () => sourceFactory.forUri(uri));
  }

  /**
   * Return the [UnlinkedUnit] for the given [uri] or throw [StateError] if it
   * could not be found.
   */
  UnlinkedUnit _getUnlinkedSummaryOrThrow(String uri) {
    if (parent != null && parent._hasLibrarySummary(uri)) {
      return parent._getUnlinkedSummaryOrThrow(uri);
    }
    UnlinkedUnit summary = getUnlinkedSummary(uri);
    if (summary != null) {
      return summary;
    }
    throw new StateError('Unable to find unlinked summary: $uri');
  }

  /**
   * Return `true` if this resynthesizer can provide summaries of the libraries
   * with the given [uri].
   */
  bool _hasLibrarySummary(String uri) {
    if (parent != null && parent._hasLibrarySummary(uri)) {
      return true;
    }
    return hasLibrarySummary(uri);
  }
}

/**
 * Builder of [Expression]s from [UnlinkedConst]s.
 */
class _ConstExprBuilder {
  final _UnitResynthesizer resynthesizer;
  final ElementImpl context;
  final UnlinkedConst uc;

  int intPtr = 0;
  int doublePtr = 0;
  int stringPtr = 0;
  int refPtr = 0;
  final List<Expression> stack = <Expression>[];

  _ConstExprBuilder(this.resynthesizer, this.context, this.uc);

  Expression build() {
    if (!uc.isValidConst) {
      return AstFactory.identifier3(r'$$invalidConstExpr$$');
    }
    for (UnlinkedConstOperation operation in uc.operations) {
      switch (operation) {
        case UnlinkedConstOperation.pushNull:
          _push(AstFactory.nullLiteral());
          break;
        // bool
        case UnlinkedConstOperation.pushFalse:
          _push(AstFactory.booleanLiteral(false));
          break;
        case UnlinkedConstOperation.pushTrue:
          _push(AstFactory.booleanLiteral(true));
          break;
        // literals
        case UnlinkedConstOperation.pushInt:
          int value = uc.ints[intPtr++];
          _push(AstFactory.integer(value));
          break;
        case UnlinkedConstOperation.pushLongInt:
          int value = 0;
          int count = uc.ints[intPtr++];
          for (int i = 0; i < count; i++) {
            int next = uc.ints[intPtr++];
            value = value << 32 | next;
          }
          _push(AstFactory.integer(value));
          break;
        case UnlinkedConstOperation.pushDouble:
          double value = uc.doubles[doublePtr++];
          _push(AstFactory.doubleLiteral(value));
          break;
        case UnlinkedConstOperation.makeSymbol:
          String component = uc.strings[stringPtr++];
          _push(AstFactory.symbolLiteral([component]));
          break;
        // String
        case UnlinkedConstOperation.pushString:
          String value = uc.strings[stringPtr++];
          _push(AstFactory.string2(value));
          break;
        case UnlinkedConstOperation.concatenate:
          int count = uc.ints[intPtr++];
          List<InterpolationElement> elements = <InterpolationElement>[];
          for (int i = 0; i < count; i++) {
            Expression expr = _pop();
            InterpolationElement element = _newInterpolationElement(expr);
            elements.insert(0, element);
          }
          _push(AstFactory.string(elements));
          break;
        // binary
        case UnlinkedConstOperation.equal:
          _pushBinary(TokenType.EQ_EQ);
          break;
        case UnlinkedConstOperation.notEqual:
          _pushBinary(TokenType.BANG_EQ);
          break;
        case UnlinkedConstOperation.and:
          _pushBinary(TokenType.AMPERSAND_AMPERSAND);
          break;
        case UnlinkedConstOperation.or:
          _pushBinary(TokenType.BAR_BAR);
          break;
        case UnlinkedConstOperation.bitXor:
          _pushBinary(TokenType.CARET);
          break;
        case UnlinkedConstOperation.bitAnd:
          _pushBinary(TokenType.AMPERSAND);
          break;
        case UnlinkedConstOperation.bitOr:
          _pushBinary(TokenType.BAR);
          break;
        case UnlinkedConstOperation.bitShiftLeft:
          _pushBinary(TokenType.LT_LT);
          break;
        case UnlinkedConstOperation.bitShiftRight:
          _pushBinary(TokenType.GT_GT);
          break;
        case UnlinkedConstOperation.add:
          _pushBinary(TokenType.PLUS);
          break;
        case UnlinkedConstOperation.subtract:
          _pushBinary(TokenType.MINUS);
          break;
        case UnlinkedConstOperation.multiply:
          _pushBinary(TokenType.STAR);
          break;
        case UnlinkedConstOperation.divide:
          _pushBinary(TokenType.SLASH);
          break;
        case UnlinkedConstOperation.floorDivide:
          _pushBinary(TokenType.TILDE_SLASH);
          break;
        case UnlinkedConstOperation.modulo:
          _pushBinary(TokenType.PERCENT);
          break;
        case UnlinkedConstOperation.greater:
          _pushBinary(TokenType.GT);
          break;
        case UnlinkedConstOperation.greaterEqual:
          _pushBinary(TokenType.GT_EQ);
          break;
        case UnlinkedConstOperation.less:
          _pushBinary(TokenType.LT);
          break;
        case UnlinkedConstOperation.lessEqual:
          _pushBinary(TokenType.LT_EQ);
          break;
        // prefix
        case UnlinkedConstOperation.complement:
          _pushPrefix(TokenType.TILDE);
          break;
        case UnlinkedConstOperation.negate:
          _pushPrefix(TokenType.MINUS);
          break;
        case UnlinkedConstOperation.not:
          _pushPrefix(TokenType.BANG);
          break;
        // conditional
        case UnlinkedConstOperation.conditional:
          Expression elseExpr = _pop();
          Expression thenExpr = _pop();
          Expression condition = _pop();
          _push(
              AstFactory.conditionalExpression(condition, thenExpr, elseExpr));
          break;
        // invokeMethodRef
        case UnlinkedConstOperation.invokeMethodRef:
          _pushInvokeMethodRef();
          break;
        // containers
        case UnlinkedConstOperation.makeUntypedList:
          _pushList(null);
          break;
        case UnlinkedConstOperation.makeTypedList:
          TypeName itemType = _newTypeName();
          _pushList(AstFactory.typeArgumentList(<TypeName>[itemType]));
          break;
        case UnlinkedConstOperation.makeUntypedMap:
          _pushMap(null);
          break;
        case UnlinkedConstOperation.makeTypedMap:
          TypeName keyType = _newTypeName();
          TypeName valueType = _newTypeName();
          _pushMap(AstFactory.typeArgumentList(<TypeName>[keyType, valueType]));
          break;
        case UnlinkedConstOperation.pushReference:
          _pushReference();
          break;
        case UnlinkedConstOperation.extractProperty:
          _pushExtractProperty();
          break;
        case UnlinkedConstOperation.invokeConstructor:
          _pushInstanceCreation();
          break;
        case UnlinkedConstOperation.pushParameter:
          String name = uc.strings[stringPtr++];
          SimpleIdentifier identifier = AstFactory.identifier3(name);
          identifier.staticElement = resynthesizer.currentConstructor.parameters
              .firstWhere((parameter) => parameter.name == name,
                  orElse: () => throw new StateError(
                      'Unable to resolve constructor parameter: $name'));
          _push(identifier);
          break;
        case UnlinkedConstOperation.assignToRef:
        case UnlinkedConstOperation.assignToProperty:
        case UnlinkedConstOperation.assignToIndex:
        case UnlinkedConstOperation.extractIndex:
        case UnlinkedConstOperation.invokeMethod:
        case UnlinkedConstOperation.cascadeSectionBegin:
        case UnlinkedConstOperation.cascadeSectionEnd:
        case UnlinkedConstOperation.typeCast:
        case UnlinkedConstOperation.typeCheck:
        case UnlinkedConstOperation.throwException:
        case UnlinkedConstOperation.pushLocalFunctionReference:
          throw new UnimplementedError(
              'Unexpected $operation in a constant expression.');
      }
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
        arguments[index] = AstFactory.namedExpression2(name, arguments[index]);
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
      return AstFactory.identifier3(info.name)..staticElement = element;
    }
    if (enclosing is SimpleIdentifier) {
      SimpleIdentifier identifier = AstFactory.identifier3(info.name)
        ..staticElement = element;
      return AstFactory.identifier(enclosing, identifier);
    }
    SimpleIdentifier property = AstFactory.identifier3(info.name)
      ..staticElement = element;
    return AstFactory.propertyAccess(enclosing, property);
  }

  TypeName _buildTypeAst(DartType type) {
    List<TypeName> argumentNodes;
    if (type is ParameterizedType) {
      if (!resynthesizer.libraryResynthesizer.typesWithImplicitTypeArguments
          .contains(type)) {
        List<DartType> typeArguments = type.typeArguments;
        argumentNodes = typeArguments.every((a) => a.isDynamic)
            ? null
            : typeArguments.map(_buildTypeAst).toList();
      }
    }
    TypeName node = AstFactory.typeName4(type.name, argumentNodes);
    node.type = type;
    (node.name as SimpleIdentifier).staticElement = type.element;
    return node;
  }

  PropertyAccessorElement _getStringLengthElement() =>
      resynthesizer.typeProvider.stringType.getGetter('length');

  InterpolationElement _newInterpolationElement(Expression expr) {
    if (expr is SimpleStringLiteral) {
      return new InterpolationString(expr.literal, expr.value);
    } else {
      return new InterpolationExpression(
          TokenFactory.tokenFromType(TokenType.STRING_INTERPOLATION_EXPRESSION),
          expr,
          TokenFactory.tokenFromType(TokenType.CLOSE_CURLY_BRACKET));
    }
  }

  /**
   * Convert the next reference to the [DartType] and return the AST
   * corresponding to this type.
   */
  TypeName _newTypeName() {
    EntityRef typeRef = uc.references[refPtr++];
    DartType type = resynthesizer.buildType(
        typeRef, resynthesizer._currentTypeParameterizedElement);
    return _buildTypeAst(type);
  }

  Expression _pop() => stack.removeLast();

  void _push(Expression expr) {
    stack.add(expr);
  }

  void _pushBinary(TokenType operator) {
    Expression right = _pop();
    Expression left = _pop();
    _push(AstFactory.binaryExpression(left, operator, right));
  }

  void _pushExtractProperty() {
    Expression target = _pop();
    String name = uc.strings[stringPtr++];
    SimpleIdentifier propertyNode = AstFactory.identifier3(name);
    // Only String.length property access can be potentially resolved.
    if (name == 'length') {
      propertyNode.staticElement = _getStringLengthElement();
    }
    _push(AstFactory.propertyAccess(target, propertyNode));
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
        throw new StateError('Unsupported element for invokeConstructor '
            '${info.element?.runtimeType}');
      }
      InterfaceType definingType = resynthesizer._createConstructorDefiningType(
          context?.typeParameterContext, info, ref.typeArguments);
      constructorElement =
          resynthesizer._createConstructorElement(definingType, info);
      typeNode = _buildTypeAst(definingType);
    } else {
      if (info.enclosing != null) {
        if (info.enclosing.enclosing != null) {
          PrefixedIdentifier typeName = AstFactory.identifier5(
              info.enclosing.enclosing.name, info.enclosing.name);
          typeName.prefix.staticElement = info.enclosing.enclosing.element;
          typeName.identifier.staticElement = info.enclosing.element;
          typeName.identifier.staticType = info.enclosing.type;
          typeNode = AstFactory.typeName3(typeName);
          typeNode.type = info.enclosing.type;
          constructorName = info.name;
        } else if (info.enclosing.element != null) {
          SimpleIdentifier typeName =
              AstFactory.identifier3(info.enclosing.name);
          typeName.staticElement = info.enclosing.element;
          typeName.staticType = info.enclosing.type;
          typeNode = AstFactory.typeName3(typeName);
          typeNode.type = info.enclosing.type;
          constructorName = info.name;
        } else {
          typeNode = AstFactory.typeName3(
              AstFactory.identifier5(info.enclosing.name, info.name));
          constructorName = null;
        }
      } else {
        typeNode = AstFactory.typeName4(info.name);
      }
    }
    // prepare arguments
    List<Expression> arguments = _buildArguments();
    // create ConstructorName
    ConstructorName constructorNode;
    if (constructorName != null) {
      constructorNode = AstFactory.constructorName(typeNode, constructorName);
      constructorNode.name.staticElement = constructorElement;
    } else {
      constructorNode = AstFactory.constructorName(typeNode, null);
    }
    constructorNode.staticElement = constructorElement;
    // create InstanceCreationExpression
    InstanceCreationExpression instanceCreation = AstFactory
        .instanceCreationExpression(Keyword.CONST, constructorNode, arguments);
    instanceCreation.staticElement = constructorElement;
    _push(instanceCreation);
  }

  void _pushInvokeMethodRef() {
    List<Expression> arguments = _buildArguments();
    EntityRef ref = uc.references[refPtr++];
    _ReferenceInfo info = resynthesizer.getReferenceInfo(ref.reference);
    Expression node = _buildIdentifierSequence(info);
    if (node is SimpleIdentifier) {
      _push(new MethodInvocation(
          null,
          TokenFactory.tokenFromType(TokenType.PERIOD),
          node,
          null,
          AstFactory.argumentList(arguments)));
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
    _push(AstFactory.listLiteral2(Keyword.CONST, typeArguments, elements));
  }

  void _pushMap(TypeArgumentList typeArguments) {
    int count = uc.ints[intPtr++];
    List<MapLiteralEntry> entries = <MapLiteralEntry>[];
    for (int i = 0; i < count; i++) {
      Expression value = _pop();
      Expression key = _pop();
      entries.insert(0, AstFactory.mapLiteralEntry2(key, value));
    }
    _push(AstFactory.mapLiteral(Keyword.CONST, typeArguments, entries));
  }

  void _pushPrefix(TokenType operator) {
    Expression operand = _pop();
    _push(AstFactory.prefixExpression(operator, operand));
  }

  void _pushReference() {
    EntityRef ref = uc.references[refPtr++];
    _ReferenceInfo info = resynthesizer.getReferenceInfo(ref.reference);
    Expression node = _buildIdentifierSequence(info);
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
 * Temporary [TypeParameterizedElementMixin] implementation.
 *
 * TODO(scheglov) remove after moving resynthesize logic to Impl.
 */
class _CurrentTypeParameterizedElement
    implements TypeParameterizedElementMixin {
  final _UnitResynthesizer unitResynthesizer;

  _CurrentTypeParameterizedElement(this.unitResynthesizer);

  @override
  TypeParameterType getTypeParameterType(int index) {
    return unitResynthesizer.getTypeParameterFromScope(index);
  }

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/**
 * A class element that has been resynthesized from a summary.  The actual
 * element won't be constructed until it is requested.  But properties
 * [context],  [displayName], [enclosingElement] and [name] can be used without
 * creating the actual element.  This allows to put these elements into
 * namespaces without creating actual elements until they are really needed.
 */
class _DeferredClassElement extends ClassElementHandle {
  final _UnitResynthesizer unitResynthesizer;
  final CompilationUnitElement unitElement;
  final UnlinkedClass serializedClass;

  ClassElementImpl _actualElement;

  /**
   * We don't resynthesize executables of classes until they are requested.
   * TODO(scheglov) Check whether we need separate flags for separate kinds.
   */
  bool _executablesResynthesized = false;

  @override
  final String name;

  factory _DeferredClassElement(_UnitResynthesizer unitResynthesizer,
      CompilationUnitElement unitElement, UnlinkedClass serializedClass) {
    String name = serializedClass.name;
    List<String> components =
        unitResynthesizer.unit.location.components.toList();
    components.add(name);
    ElementLocationImpl location = new ElementLocationImpl.con3(components);
    return new _DeferredClassElement._(
        unitResynthesizer, unitElement, serializedClass, name, location);
  }

  _DeferredClassElement._(this.unitResynthesizer, this.unitElement,
      this.serializedClass, this.name, ElementLocation location)
      : super(null, location);

  @override
  List<PropertyAccessorElement> get accessors {
    _ensureExecutables();
    return actualElement.accessors;
  }

  @override
  ClassElementImpl get actualElement {
    if (_actualElement == null) {
      _actualElement = unitResynthesizer.buildClassImpl(serializedClass, this);
      _actualElement.enclosingElement = unitElement;
    }
    return _actualElement;
  }

  @override
  List<ConstructorElement> get constructors {
    _ensureExecutables();
    return actualElement.constructors;
  }

  @override
  AnalysisContext get context => unitElement.context;

  @override
  String get displayName => name;

  @override
  CompilationUnitElement get enclosingElement {
    return unitElement;
  }

  @override
  List<FieldElement> get fields {
    _ensureExecutables();
    return actualElement.fields;
  }

  @override
  List<MethodElement> get methods {
    _ensureExecutables();
    return actualElement.methods;
  }

  @override
  void ensureAccessorsReady() {
    _ensureExecutables();
  }

  @override
  void ensureActualElementComplete() {
    _ensureExecutables();
  }

  @override
  void ensureConstructorsReady() {
    _ensureExecutables();
  }

  @override
  void ensureMethodsReady() {
    _ensureExecutables();
  }

  /**
   * Ensure that we have [actualElement], and it has all executables.
   */
  void _ensureExecutables() {
    if (!_executablesResynthesized) {
      _executablesResynthesized = true;
      unitResynthesizer.buildClassExecutables(actualElement, serializedClass);
    }
  }
}

/**
 * The constructor element that has been resynthesized from a summary.  The
 * actual element won't be constructed until it is requested.  But properties
 * [displayName], [enclosingElement] and [name] can be used without creating
 * the actual element.
 */
class _DeferredConstructorElement extends ConstructorElementHandle {
  /**
   * The type defining this constructor element.  If [_isMember] is `false`,
   * then the type parameters of [_definingType] are not guaranteed to be
   * valid.
   */
  final InterfaceType _definingType;

  /**
   * The constructor name.
   */
  final String name;

  factory _DeferredConstructorElement(InterfaceType definingType, String name) {
    List<String> components = definingType.element.location.components.toList();
    components.add(name);
    ElementLocationImpl location = new ElementLocationImpl.con3(components);
    return new _DeferredConstructorElement._(definingType, name, location);
  }

  _DeferredConstructorElement._(
      this._definingType, this.name, ElementLocation location)
      : super(null, location);

  @override
  ConstructorElement get actualElement =>
      enclosingElement.getNamedConstructor(name);

  @override
  AnalysisContext get context => _definingType.element.context;

  @override
  String get displayName => name;

  @override
  ClassElement get enclosingElement {
    return _definingType.element;
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
 * Local function element that has been resynthesized from a summary.  The
 * actual element won't be constructed until it is requested.  But properties
 * [context] and [enclosingElement] can be used without creating the actual
 * element.
 */
class _DeferredLocalFunctionElement extends FunctionElementHandle {
  /**
   * The executable element containing this element.
   */
  @override
  final ExecutableElement enclosingElement;

  /**
   * The index of this function within [ExecutableElement.functions].
   */
  final int _localIndex;

  _DeferredLocalFunctionElement(this.enclosingElement, this._localIndex)
      : super(null, null);

  @override
  FunctionElement get actualElement {
    ExecutableElement enclosingElement = this.enclosingElement;
    if (enclosingElement is PropertyAccessorElement &&
        enclosingElement.isSynthetic) {
      return enclosingElement.variable.initializer;
    } else {
      return enclosingElement.functions[_localIndex];
    }
  }

  @override
  AnalysisContext get context => enclosingElement.context;

  @override
  ElementLocation get location => actualElement.location;
}

/**
 * Local variable element that has been resynthesized from a summary.  The
 * actual element won't be constructed until it is requested.  But properties
 * [context] and [enclosingElement] can be used without creating the actual
 * element.
 */
class _DeferredLocalVariableElement extends LocalVariableElementHandle {
  /**
   * The executable element containing this element.
   */
  @override
  final ExecutableElement enclosingElement;

  /**
   * The index of this variable within [ExecutableElement.localVariables].
   */
  final int _localIndex;

  _DeferredLocalVariableElement(this.enclosingElement, this._localIndex)
      : super(null, null);

  @override
  LocalVariableElement get actualElement =>
      enclosingElement.localVariables[_localIndex];

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
   * Classes which should have their supertype set to "object" once
   * resynthesis is complete.  Only used if [isCoreLibrary] is `true`.
   */
  List<ClassElementImpl> delayedObjectSubclasses = <ClassElementImpl>[];

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
      partResynthesizers.add(partResynthesizer);
    }
    library.parts = partResynthesizers.map((r) => r.unit).toList();
    // Populate units.
    populateUnit(definingUnitResynthesizer);
    for (_UnitResynthesizer partResynthesizer in partResynthesizers) {
      populateUnit(partResynthesizer);
    }
    // Update delayed Object class references.
    if (isCoreLibrary) {
      ClassElement objectElement = library.getType('Object');
      assert(objectElement != null);
      for (ClassElementImpl classElement in delayedObjectSubclasses) {
        classElement.supertype = objectElement.type;
      }
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
   * Create, but do not populate, the [CompilationUnitElement] for a part other
   * than the defining compilation unit.
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
   * Populate a [CompilationUnitElement] by deserializing all the elements
   * contained in it.
   */
  void populateUnit(_UnitResynthesizer unitResynthesized) {
    unitResynthesized.populateUnit();
    String absoluteUri = unitResynthesized.unit.source.uri.toString();
    resynthesizedUnits[absoluteUri] = unitResynthesized.unit;
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
    String absoluteUri = resynthesizer.summaryResynthesizer.sourceFactory
        .resolveUri(resynthesizer.librarySource, depUri)
        .uri
        .toString();
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
   * The element referred to by this reference, or `null` if there is no
   * associated element (e.g. because it is a reference to an undefined
   * entity).
   */
  final Element element;

  /**
   * If this reference refers to a non-generic type, the type it refers to.
   * Otherwise `null`.
   */
  DartType type;

  /**
   * The number of type parameters accepted by the entity referred to by this
   * reference, or zero if it doesn't accept any type parameters.
   */
  final int numTypeParameters;

  /**
   * Create a new [_ReferenceInfo] object referring to an element called [name]
   * via the element handle [element], and having [numTypeParameters] type
   * parameters.
   *
   * For the special types `dynamic` and `void`, [specialType] should point to
   * the type itself.  Otherwise, pass `null` and the type will be computed
   * when appropriate.
   */
  _ReferenceInfo(this.libraryResynthesizer, this.enclosing, this.name,
      this.element, DartType specialType, this.numTypeParameters) {
    if (specialType != null) {
      type = specialType;
    } else {
      type = _buildType(true, 0, (_) => DynamicTypeImpl.instance, const []);
    }
  }

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
      // TODO(paulberry): figure out how to handle this case (which should
      // only occur in the event of erroneous code).
      throw new UnimplementedError();
    }
    return result;
  }

  /**
   * If this reference refers to a type, build a [DartType].  Otherwise return
   * `null`.  If [numTypeArguments] is the same as the [numTypeParameters],
   * the type in instantiated with type arguments returned by [getTypeArgument],
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
        typeArguments = const <DartType>[];
      } else if (numTypeArguments == numTypeParameters) {
        typeArguments = new List<DartType>(numTypeParameters);
        for (int i = 0; i < numTypeParameters; i++) {
          typeArguments[i] = getTypeArgument(i);
        }
      }
      InterfaceTypeImpl type =
          new InterfaceTypeImpl.elementWithNameAndArgs(element, name, () {
        if (typeArguments == null) {
          typeArguments = element.typeParameters.map((typeParameter) {
            DartType bound = typeParameter.bound;
            return libraryResynthesizer.summaryResynthesizer.strongMode &&
                instantiateToBoundsAllowed &&
                bound != null ? bound : DynamicTypeImpl.instance;
          }).toList();
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
    } else if (element is FunctionTypedElement) {
      int numTypeArguments;
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
      } else if (element is FunctionTypeAliasElementHandle) {
        return new FunctionTypeImpl.elementWithNameAndArgs(
            element,
            name,
            _buildTypeArguments(numTypeParameters, getTypeArgument),
            numTypeParameters != 0);
      } else {
        // For a type that refers to a generic executable, the type arguments are
        // not supposed to include the arguments to the executable itself.
        numTypeArguments = enclosing == null ? 0 : enclosing.numTypeParameters;
        computer = () => this.element as FunctionTypedElement;
      }
      // TODO(paulberry): Is it a bug that we have to pass `false` for
      // isInstantiated?
      return new DeferredFunctionTypeImpl(computer, null,
          _buildTypeArguments(numTypeArguments, getTypeArgument), false);
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
      typeArguments = <DartType>[];
      for (int i = 0; i < numTypeArguments; i++) {
        typeArguments.add(getTypeArgument(i));
      }
    }
    return typeArguments;
  }
}

class _ResynthesizerContext implements ResynthesizerContext {
  final _UnitResynthesizer _unitResynthesizer;

  _ResynthesizerContext(this._unitResynthesizer);

  @override
  ElementAnnotationImpl buildAnnotation(ElementImpl context, UnlinkedConst uc) {
    return _unitResynthesizer.buildAnnotation(context, uc);
  }

  @override
  Expression buildExpression(ElementImpl context, UnlinkedConst uc) {
    return _unitResynthesizer._buildConstExpression(context, uc);
  }

  @override
  UnitExplicitTopLevelAccessors buildTopLevelAccessors() {
    return _unitResynthesizer.buildUnitExplicitTopLevelAccessors();
  }

  @override
  List<FunctionElementImpl> buildTopLevelFunctions() {
    return _unitResynthesizer.buildTopLevelFunctions();
  }

  @override
  UnitExplicitTopLevelVariables buildTopLevelVariables() {
    return _unitResynthesizer.buildUnitExplicitTopLevelVariables();
  }

  @override
  DartType resolveLinkedType(
      int slot, TypeParameterizedElementMixin typeParameterContext) {
    return _unitResynthesizer.buildLinkedType(slot, typeParameterContext);
  }

  @override
  DartType resolveTypeRef(
      EntityRef type, TypeParameterizedElementMixin typeParameterContext,
      {bool defaultVoid: false, bool instantiateToBoundsAllowed: true}) {
    return _unitResynthesizer.buildType(type, typeParameterContext,
        defaultVoid: defaultVoid,
        instantiateToBoundsAllowed: instantiateToBoundsAllowed);
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
   * [ElementHolder] into which resynthesized elements should be placed.  This
   * object is recreated afresh for each unit in the library, and is used to
   * populate the [CompilationUnitElement].
   */
  final ElementHolder unitHolder = new ElementHolder();

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
   * The [ConstructorElementImpl] for the constructor currently being
   * resynthesized.
   */
  ConstructorElementImpl currentConstructor;

  /**
   * Type parameters for the generic class, typedef, or executable currently
   * being resynthesized, if any.  This is a list of lists; if multiple
   * entities with type parameters are nested (e.g. a generic executable inside
   * a generic class), then the zeroth element of [currentTypeParameters]
   * contains the type parameters for the outermost nested entity, and further
   * elements contain the type parameters for entities that are more deeply
   * nested.  If we are not currently resynthesizing a class, typedef, or
   * executable, then this is an empty list.
   */
  final List<List<TypeParameterElement>> currentTypeParameters =
      <List<TypeParameterElement>>[];

  /**
   * If a class is currently being resynthesized, map from field name to the
   * corresponding field element.  This is used when resynthesizing
   * initializing formal parameters.
   */
  Map<String, FieldElementImpl> fields;

  /**
   * If a class is currently being resynthesized, map from constructor name to
   * the corresponding constructor element.  This is used when resynthesizing
   * constructor initializers.
   */
  Map<String, ConstructorElementImpl> constructors;

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

  /**
   * TODO(scheglov) clean up after moving resynthesize logic to Impl.
   */
  TypeParameterizedElementMixin _currentTypeParameterizedElement;

  _UnitResynthesizer(this.libraryResynthesizer, this.unlinkedUnit,
      this.linkedUnit, Source unitSource, UnlinkedPart unlinkedPart) {
    _resynthesizerContext = new _ResynthesizerContext(this);
    unit = new CompilationUnitElementImpl.forSerialized(
        libraryResynthesizer.library,
        _resynthesizerContext,
        unlinkedUnit,
        unlinkedPart,
        unitSource.shortName);
    for (EntityRef t in linkedUnit.types) {
      linkedTypeMap[t.slot] = t;
    }
    constCycles = linkedUnit.constCycles.toSet();
    numLinkedReferences = linkedUnit.references.length;
    numUnlinkedReferences = unlinkedUnit.references.length;
    referenceInfos = new List<_ReferenceInfo>(numLinkedReferences);
    _currentTypeParameterizedElement =
        new _CurrentTypeParameterizedElement(this);
  }

  SummaryResynthesizer get summaryResynthesizer =>
      libraryResynthesizer.summaryResynthesizer;

  TypeProvider get typeProvider => summaryResynthesizer.typeProvider;

  /**
   * Build [ElementAnnotationImpl] for the given [UnlinkedConst].
   */
  ElementAnnotationImpl buildAnnotation(ElementImpl context, UnlinkedConst uc) {
    ElementAnnotationImpl elementAnnotation = new ElementAnnotationImpl(unit);
    Expression constExpr = _buildConstExpression(context, uc);
    if (constExpr is Identifier) {
      elementAnnotation.element = constExpr.staticElement;
      elementAnnotation.annotationAst = AstFactory.annotation(constExpr);
    } else if (constExpr is InstanceCreationExpression) {
      elementAnnotation.element = constExpr.staticElement;
      Identifier typeName = constExpr.constructorName.type.name;
      SimpleIdentifier constructorName = constExpr.constructorName.name;
      if (typeName is SimpleIdentifier && constructorName != null) {
        // E.g. `@cls.ctor()`.  Since `cls.ctor` would have been parsed as
        // a PrefixedIdentifier, we need to resynthesize it as one.
        typeName = AstFactory.identifier(typeName, constructorName);
        constructorName = null;
      }
      elementAnnotation.annotationAst = AstFactory.annotation2(
          typeName, constructorName, constExpr.argumentList);
    } else {
      throw new StateError(
          'Unexpected annotation type: ${constExpr.runtimeType}');
    }
    return elementAnnotation;
  }

  /**
   * Build the annotations for the given [element].
   */
  void buildAnnotations(
      ElementImpl element, List<UnlinkedConst> serializedAnnotations) {
    if (serializedAnnotations.isNotEmpty) {
      element.metadata = serializedAnnotations
          .map((a) => buildAnnotation(element, a))
          .toList();
    }
  }

  /**
   * Resynthesize a [ClassElement] and place it in [unitHolder].
   */
  void buildClass(UnlinkedClass serializedClass) {
    ClassElement classElement;
    if (libraryResynthesizer.isCoreLibrary &&
        serializedClass.supertype == null) {
      classElement = buildClassImpl(serializedClass, null);
      if (!serializedClass.hasNoSupertype) {
        libraryResynthesizer.delayedObjectSubclasses.add(classElement);
      }
    } else {
      classElement = new _DeferredClassElement(this, unit, serializedClass);
    }
    unitHolder.addType(classElement);
  }

  /**
   * Fill the given [ClassElementImpl] with executable elements and fields.
   */
  void buildClassExecutables(
      ClassElementImpl classElement, UnlinkedClass serializedClass) {
    currentTypeParameters.add(classElement.typeParameters);
    ElementHolder memberHolder = new ElementHolder();
    fields = <String, FieldElementImpl>{};
    for (UnlinkedVariable serializedVariable in serializedClass.fields) {
      buildVariable(classElement, serializedVariable, memberHolder);
    }
    bool constructorFound = false;
    constructors = <String, ConstructorElementImpl>{};
    for (UnlinkedExecutable serializedExecutable
        in serializedClass.executables) {
      switch (serializedExecutable.kind) {
        case UnlinkedExecutableKind.constructor:
          constructorFound = true;
          buildConstructor(serializedExecutable, classElement, memberHolder);
          break;
        case UnlinkedExecutableKind.functionOrMethod:
        case UnlinkedExecutableKind.getter:
        case UnlinkedExecutableKind.setter:
          if (serializedExecutable.isStatic) {
            currentTypeParameters.removeLast();
          }
          buildExecutable(serializedExecutable, classElement, memberHolder);
          if (serializedExecutable.isStatic) {
            currentTypeParameters.add(classElement.typeParameters);
          }
          break;
      }
    }
    if (!serializedClass.isMixinApplication) {
      if (!constructorFound) {
        // Synthesize implicit constructors.
        ConstructorElementImpl constructor = new ConstructorElementImpl('', -1);
        constructor.synthetic = true;
        constructor.returnType = classElement.type;
        constructor.type = new FunctionTypeImpl.elementWithNameAndArgs(
            constructor, null, getCurrentTypeArguments(), false);
        memberHolder.addConstructor(constructor);
      }
      classElement.constructors = memberHolder.constructors;
    }
    classElement.accessors = memberHolder.accessors;
    classElement.fields = memberHolder.fields;
    classElement.methods = memberHolder.methods;
    resolveConstructorInitializers(classElement);
    currentTypeParameters.removeLast();
    assert(currentTypeParameters.isEmpty);
  }

  /**
   * Resynthesize a [ClassElementImpl].  If [handle] is not `null`, then
   * executables are not resynthesized, and [InterfaceTypeImpl] is created
   * around the [handle], so that executables are resynthesized lazily.
   */
  ClassElementImpl buildClassImpl(
      UnlinkedClass serializedClass, ClassElementHandle handle) {
    ClassElementImpl classElement =
        new ClassElementImpl.forSerialized(serializedClass, unit);
    classElement.hasBeenInferred = summaryResynthesizer.strongMode;
    InterfaceTypeImpl correspondingType =
        new InterfaceTypeImpl(handle ?? classElement);
    if (serializedClass.supertype != null) {
      classElement.supertype =
          buildType(serializedClass.supertype, classElement);
    } else if (!libraryResynthesizer.isCoreLibrary) {
      classElement.supertype = typeProvider.objectType;
    }
    classElement.interfaces = serializedClass.interfaces
        .map((EntityRef t) => buildType(t, classElement))
        .toList();
    classElement.mixins = serializedClass.mixins
        .map((EntityRef t) => buildType(t, classElement))
        .toList();
    // TODO(scheglov) move to ClassElementImpl
    correspondingType.typeArguments = classElement.typeParameterTypes;
    classElement.type = correspondingType;
    assert(currentTypeParameters.isEmpty);
    // TODO(scheglov) Somehow Observatory shows too much time spent here
    // during DDC run on the large codebase. I would expect only Object here.
    if (handle == null) {
      buildClassExecutables(classElement, serializedClass);
    }
    fields = null;
    constructors = null;
    return classElement;
  }

  void buildCodeRange(ElementImpl element, CodeRange codeRange) {
    if (codeRange != null) {
      element.setCodeRange(codeRange.offset, codeRange.length);
    }
  }

  /**
   * Resynthesize a [NamespaceCombinator].
   */
  NamespaceCombinator buildCombinator(UnlinkedCombinator serializedCombinator) {
    if (serializedCombinator.shows.isNotEmpty) {
      ShowElementCombinatorImpl combinator = new ShowElementCombinatorImpl();
      // Note: we call toList() so that we don't retain a reference to the
      // deserialized data structure.
      combinator.shownNames = serializedCombinator.shows.toList();
      combinator.offset = serializedCombinator.offset;
      combinator.end = serializedCombinator.end;
      return combinator;
    } else {
      HideElementCombinatorImpl combinator = new HideElementCombinatorImpl();
      // Note: we call toList() so that we don't retain a reference to the
      // deserialized data structure.
      combinator.hiddenNames = serializedCombinator.hides.toList();
      return combinator;
    }
  }

  /**
   * Resynthesize a [ConstructorElement] and place it in the given [holder].
   * [classElement] is the element of the class for which this element is a
   * constructor.
   */
  void buildConstructor(UnlinkedExecutable serializedExecutable,
      ClassElementImpl classElement, ElementHolder holder) {
    assert(serializedExecutable.kind == UnlinkedExecutableKind.constructor);
    currentConstructor = new ConstructorElementImpl.forSerialized(
        serializedExecutable, classElement);
    currentConstructor.isCycleFree = serializedExecutable.isConst &&
        !constCycles.contains(serializedExecutable.constCycleSlot);
    if (serializedExecutable.name.isEmpty) {
      currentConstructor.nameEnd =
          serializedExecutable.nameOffset + classElement.name.length;
    } else {
      currentConstructor.nameEnd = serializedExecutable.nameEnd;
      currentConstructor.periodOffset = serializedExecutable.periodOffset;
    }
    constructors[serializedExecutable.name] = currentConstructor;
    buildExecutableCommonParts(currentConstructor, serializedExecutable);
    currentConstructor.constantInitializers = serializedExecutable
        .constantInitializers
        .map((i) => buildConstructorInitializer(currentConstructor, i))
        .toList();
    if (serializedExecutable.isRedirectedConstructor) {
      if (serializedExecutable.isFactory) {
        EntityRef redirectedConstructor =
            serializedExecutable.redirectedConstructor;
        _ReferenceInfo info = getReferenceInfo(redirectedConstructor.reference);
        List<EntityRef> typeArguments = redirectedConstructor.typeArguments;
        currentConstructor.redirectedConstructor = _createConstructorElement(
            _createConstructorDefiningType(classElement, info, typeArguments),
            info);
      } else {
        List<String> locationComponents = unit.location.components.toList();
        locationComponents.add(classElement.name);
        locationComponents.add(serializedExecutable.redirectedConstructorName);
        currentConstructor.redirectedConstructor =
            new _DeferredConstructorElement._(
                classElement.type,
                serializedExecutable.redirectedConstructorName,
                new ElementLocationImpl.con3(locationComponents));
      }
    }
    holder.addConstructor(currentConstructor);
    currentConstructor = null;
  }

  /**
   * Resynthesize the [ConstructorInitializer] in context of
   * [currentConstructor], which is used to resolve constructor parameter names.
   */
  ConstructorInitializer buildConstructorInitializer(
      ConstructorElementImpl enclosingConstructor,
      UnlinkedConstructorInitializer serialized) {
    UnlinkedConstructorInitializerKind kind = serialized.kind;
    String name = serialized.name;
    List<Expression> arguments = <Expression>[];
    {
      int numArguments = serialized.arguments.length;
      int numNames = serialized.argumentNames.length;
      for (int i = 0; i < numArguments; i++) {
        Expression expression = _buildConstExpression(
            enclosingConstructor, serialized.arguments[i]);
        int nameIndex = numNames + i - numArguments;
        if (nameIndex >= 0) {
          expression = AstFactory.namedExpression2(
              serialized.argumentNames[nameIndex], expression);
        }
        arguments.add(expression);
      }
    }
    switch (kind) {
      case UnlinkedConstructorInitializerKind.field:
        return AstFactory.constructorFieldInitializer(false, name,
            _buildConstExpression(enclosingConstructor, serialized.expression));
      case UnlinkedConstructorInitializerKind.superInvocation:
        return AstFactory.superConstructorInvocation2(
            name.isNotEmpty ? name : null, arguments);
      case UnlinkedConstructorInitializerKind.thisInvocation:
        return AstFactory.redirectingConstructorInvocation2(
            name.isNotEmpty ? name : null, arguments);
    }
  }

  /**
   * Build the documentation for the given [element].  Does nothing if
   * [serializedDocumentationComment] is `null`.
   */
  void buildDocumentation(ElementImpl element,
      UnlinkedDocumentationComment serializedDocumentationComment) {
    if (serializedDocumentationComment != null) {
      element.documentationComment = serializedDocumentationComment.text;
      element.setDocRange(serializedDocumentationComment.offset,
          serializedDocumentationComment.length);
    }
  }

  /**
   * Resynthesize the [ClassElement] corresponding to an enum, along with the
   * associated fields and implicit accessors.
   */
  void buildEnum(UnlinkedEnum serializedEnum) {
    assert(!libraryResynthesizer.isCoreLibrary);
    ClassElementImpl classElement =
        new ClassElementImpl(serializedEnum.name, serializedEnum.nameOffset);
    classElement.enum2 = true;
    InterfaceType enumType = new InterfaceTypeImpl(classElement);
    classElement.type = enumType;
    classElement.supertype = typeProvider.objectType;
    buildDocumentation(classElement, serializedEnum.documentationComment);
    buildAnnotations(classElement, serializedEnum.annotations);
    buildCodeRange(classElement, serializedEnum.codeRange);
    ElementHolder memberHolder = new ElementHolder();
    // Build the 'index' field.
    FieldElementImpl indexField = new FieldElementImpl('index', -1);
    indexField.final2 = true;
    indexField.synthetic = true;
    indexField.type = typeProvider.intType;
    memberHolder.addField(indexField);
    buildImplicitAccessors(indexField, memberHolder);
    // Build the 'values' field.
    FieldElementImpl valuesField = new ConstFieldElementImpl('values', -1);
    valuesField.synthetic = true;
    valuesField.const3 = true;
    valuesField.static = true;
    valuesField.type = typeProvider.listType.instantiate(<DartType>[enumType]);
    memberHolder.addField(valuesField);
    buildImplicitAccessors(valuesField, memberHolder);
    // Build fields for all enum constants.
    List<DartObjectImpl> constantValues = <DartObjectImpl>[];
    for (int i = 0; i < serializedEnum.values.length; i++) {
      UnlinkedEnumValue serializedEnumValue = serializedEnum.values[i];
      String fieldName = serializedEnumValue.name;
      ConstFieldElementImpl field =
          new ConstFieldElementImpl(fieldName, serializedEnumValue.nameOffset);
      buildDocumentation(field, serializedEnumValue.documentationComment);
      field.const3 = true;
      field.static = true;
      field.type = enumType;
      // Create a value for the constant.
      Map<String, DartObjectImpl> fieldMap = <String, DartObjectImpl>{
        fieldName: new DartObjectImpl(typeProvider.intType, new IntState(i))
      };
      DartObjectImpl value =
          new DartObjectImpl(enumType, new GenericState(fieldMap));
      constantValues.add(value);
      field.evaluationResult = new EvaluationResultImpl(value);
      // Add the field.
      memberHolder.addField(field);
      buildImplicitAccessors(field, memberHolder);
    }
    // Build the value of the 'values' field.
    valuesField.evaluationResult = new EvaluationResultImpl(
        new DartObjectImpl(valuesField.type, new ListState(constantValues)));
    // done
    classElement.fields = memberHolder.fields;
    classElement.accessors = memberHolder.accessors;
    classElement.constructors = <ConstructorElement>[];
    unitHolder.addEnum(classElement);
  }

  /**
   * Resynthesize an [ExecutableElement] and place it in the given [holder].
   */
  void buildExecutable(
      UnlinkedExecutable serializedExecutable, ElementImpl enclosingElement,
      [ElementHolder holder]) {
    bool isTopLevel = holder == null;
    if (holder == null) {
      holder = unitHolder;
    }
    UnlinkedExecutableKind kind = serializedExecutable.kind;
    String name = serializedExecutable.name;
    if (kind == UnlinkedExecutableKind.setter) {
      assert(name.endsWith('='));
      name = name.substring(0, name.length - 1);
    }
    switch (kind) {
      case UnlinkedExecutableKind.functionOrMethod:
        if (isTopLevel) {
          // Created lazily.
        } else {
          MethodElementImpl executableElement =
              new MethodElementImpl.forSerialized(
                  serializedExecutable, enclosingElement);
          buildExecutableCommonParts(executableElement, serializedExecutable);
          holder.addMethod(executableElement);
        }
        break;
      case UnlinkedExecutableKind.getter:
      case UnlinkedExecutableKind.setter:
        // Top-level accessors are created lazily.
        if (isTopLevel) {
          break;
        }
        // Class member accessors.
        PropertyAccessorElementImpl executableElement =
            new PropertyAccessorElementImpl.forSerialized(
                serializedExecutable, enclosingElement);
        buildExecutableCommonParts(executableElement, serializedExecutable);
        DartType type;
        if (kind == UnlinkedExecutableKind.getter) {
          type = executableElement.returnType;
        } else {
          type = executableElement.parameters[0].type;
        }
        holder.addAccessor(executableElement);
        FieldElementImpl field = buildImplicitField(name, type, kind, holder);
        field.static = serializedExecutable.isStatic;
        executableElement.variable = field;
        if (kind == UnlinkedExecutableKind.getter) {
          field.getter = executableElement;
        } else {
          field.setter = executableElement;
        }
        break;
      default:
        // The only other executable type is a constructor, and that is handled
        // separately (in [buildConstructor].  So this code should be
        // unreachable.
        assert(false);
    }
  }

  /**
   * Handle the parts of an executable element that are common to constructors,
   * functions, methods, getters, and setters.
   */
  void buildExecutableCommonParts(ExecutableElementImpl executableElement,
      UnlinkedExecutable serializedExecutable) {
    executableElement.typeParameters =
        buildTypeParameters(serializedExecutable.typeParameters);
    {
      List<UnlinkedParam> unlinkedParameters = serializedExecutable.parameters;
      int length = unlinkedParameters.length;
      if (length != 0) {
        List<ParameterElementImpl> parameters =
            new List<ParameterElementImpl>(length);
        for (int i = 0; i < length; i++) {
          parameters[i] =
              buildParameter(unlinkedParameters[i], executableElement);
        }
        executableElement.parameters = parameters;
      }
    }
    executableElement.type = new FunctionTypeImpl.elementWithNameAndArgs(
        executableElement, null, getCurrentTypeArguments(skipLevels: 1), false);
    {
      List<UnlinkedExecutable> unlinkedFunctions =
          serializedExecutable.localFunctions;
      int length = unlinkedFunctions.length;
      if (length != 0) {
        List<FunctionElementImpl> localFunctions =
            new List<FunctionElementImpl>(length);
        for (int i = 0; i < length; i++) {
          localFunctions[i] =
              buildLocalFunction(unlinkedFunctions[i], executableElement);
        }
        executableElement.functions = localFunctions;
      }
    }
    {
      List<UnlinkedLabel> unlinkedLabels = serializedExecutable.localLabels;
      int length = unlinkedLabels.length;
      if (length != 0) {
        List<LabelElementImpl> localLabels = new List<LabelElementImpl>(length);
        for (int i = 0; i < length; i++) {
          localLabels[i] = buildLocalLabel(unlinkedLabels[i]);
        }
        executableElement.labels = localLabels;
      }
    }
    {
      List<UnlinkedVariable> unlinkedVariables =
          serializedExecutable.localVariables;
      int length = unlinkedVariables.length;
      if (length != 0) {
        List<LocalVariableElementImpl> localVariables =
            new List<LocalVariableElementImpl>(length);
        for (int i = 0; i < length; i++) {
          localVariables[i] =
              buildLocalVariable(unlinkedVariables[i], executableElement);
        }
        executableElement.localVariables = localVariables;
      }
    }
    currentTypeParameters.removeLast();
  }

  /**
   * Build the implicit getter and setter associated with [element], and place
   * them in [holder].
   */
  void buildImplicitAccessors(
      PropertyInducingElementImpl element, ElementHolder holder) {
    String name = element.name;
    DartType type = element.type;
    PropertyAccessorElementImpl getter =
        buildImplicitGetter(element, name, type);
    holder?.addAccessor(getter);
    if (!(element.isConst || element.isFinal)) {
      PropertyAccessorElementImpl setter =
          buildImplicitSetter(element, name, type);
      holder?.addAccessor(setter);
    }
  }

  /**
   * Build the implicit field associated with a getter or setter, and place it
   * in [holder].
   */
  FieldElementImpl buildImplicitField(String name, DartType type,
      UnlinkedExecutableKind kind, ElementHolder holder) {
    FieldElementImpl field = holder.getField(name);
    if (field == null) {
      field = new FieldElementImpl(name, -1);
      field.synthetic = true;
      field.final2 = kind == UnlinkedExecutableKind.getter;
      field.type = type;
      holder.addField(field);
      return field;
    } else {
      // TODO(paulberry): what if the getter and setter have a type mismatch?
      field.final2 = false;
      return field;
    }
  }

  /**
   * Build an implicit getter for the given [property] and bind it to the
   * [property] and to its enclosing element.
   */
  PropertyAccessorElementImpl buildImplicitGetter(
      PropertyInducingElementImpl property, String name, DartType type) {
    PropertyAccessorElementImpl getter =
        new PropertyAccessorElementImpl(name, property.nameOffset);
    getter.enclosingElement = property.enclosingElement;
    getter.getter = true;
    getter.static = property.isStatic;
    getter.synthetic = true;
    getter.returnType = type;
    getter.type = new FunctionTypeImpl(getter);
    getter.variable = property;
    getter.hasImplicitReturnType = property.hasImplicitType;
    property.getter = getter;
    return getter;
  }

  /**
   * Build an implicit setter for the given [property] and bind it to the
   * [property] and to its enclosing element.
   */
  PropertyAccessorElementImpl buildImplicitSetter(
      PropertyInducingElementImpl property, String name, DartType type) {
    PropertyAccessorElementImpl setter =
        new PropertyAccessorElementImpl(name, property.nameOffset);
    setter.enclosingElement = property.enclosingElement;
    setter.setter = true;
    setter.static = property.isStatic;
    setter.synthetic = true;
    setter.parameters = <ParameterElement>[
      new ParameterElementImpl('_$name', property.nameOffset)
        ..synthetic = true
        ..type = type
        ..parameterKind = ParameterKind.REQUIRED
    ];
    setter.returnType = VoidTypeImpl.instance;
    setter.type = new FunctionTypeImpl(setter);
    setter.variable = property;
    property.setter = setter;
    return setter;
  }

  /**
   * Build the appropriate [DartType] object corresponding to a slot id in the
   * [LinkedUnit.types] table.
   */
  DartType buildLinkedType(
      int slot, TypeParameterizedElementMixin typeParameterContext) {
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
    return buildType(type, typeParameterContext);
  }

  /**
   * Resynthesize a local [FunctionElement].
   */
  FunctionElementImpl buildLocalFunction(
      UnlinkedExecutable serializedExecutable, ElementImpl enclosingElement) {
    FunctionElementImpl element = new FunctionElementImpl.forSerialized(
        serializedExecutable, enclosingElement);
    if (serializedExecutable.visibleOffset != 0) {
      element.setVisibleRange(serializedExecutable.visibleOffset,
          serializedExecutable.visibleLength);
    }
    buildExecutableCommonParts(element, serializedExecutable);
    return element;
  }

  /**
   * Resynthesize a [LabelElement].
   */
  LabelElement buildLocalLabel(UnlinkedLabel serializedLabel) {
    return new LabelElementImpl(
        serializedLabel.name,
        serializedLabel.nameOffset,
        serializedLabel.isOnSwitchStatement,
        serializedLabel.isOnSwitchMember);
  }

  /**
   * Resynthesize a [LocalVariableElement].
   */
  LocalVariableElement buildLocalVariable(UnlinkedVariable serializedVariable,
      ExecutableElementImpl enclosingExecutable) {
    LocalVariableElementImpl element;
    if (serializedVariable.initializer?.bodyExpr != null &&
        serializedVariable.isConst) {
      ConstLocalVariableElementImpl constElement =
          new ConstLocalVariableElementImpl.forSerialized(
              serializedVariable, enclosingExecutable);
      element = constElement;
      constElement.constantInitializer = _buildConstExpression(
          enclosingExecutable, serializedVariable.initializer.bodyExpr);
    } else {
      element = new LocalVariableElementImpl.forSerialized(
          serializedVariable, enclosingExecutable);
    }
    if (serializedVariable.visibleOffset != 0) {
      element.setVisibleRange(
          serializedVariable.visibleOffset, serializedVariable.visibleLength);
    }
    buildVariableCommonParts(element, serializedVariable);
    return element;
  }

  /**
   * Resynthesize a [ParameterElement].
   */
  ParameterElement buildParameter(
      UnlinkedParam serializedParameter, ElementImpl enclosingElement,
      {bool synthetic: false}) {
    ParameterElementImpl parameterElement;
    if (serializedParameter.isInitializingFormal) {
      if (serializedParameter.kind == UnlinkedParamKind.required) {
        parameterElement = new FieldFormalParameterElementImpl.forSerialized(
            serializedParameter, enclosingElement);
      } else {
        parameterElement =
            new DefaultFieldFormalParameterElementImpl.forSerialized(
                serializedParameter, enclosingElement);
      }
    } else {
      if (serializedParameter.kind == UnlinkedParamKind.required) {
        parameterElement = new ParameterElementImpl.forSerialized(
            serializedParameter, enclosingElement);
      } else {
        parameterElement = new DefaultParameterElementImpl.forSerialized(
            serializedParameter, enclosingElement);
      }
    }
    parameterElement.synthetic = synthetic;
    if (serializedParameter.isFunctionTyped) {
      FunctionElementImpl parameterTypeElement =
          new FunctionElementImpl_forFunctionTypedParameter(
              unit, parameterElement);
      if (!synthetic) {
        parameterTypeElement.enclosingElement = parameterElement;
      }
      List<ParameterElement> subParameters = serializedParameter.parameters
          .map((UnlinkedParam p) =>
              buildParameter(p, parameterTypeElement, synthetic: synthetic))
          .toList();
      if (synthetic) {
        parameterTypeElement.parameters = subParameters;
      } else {
        parameterElement.parameters = subParameters;
        parameterTypeElement.shareParameters(subParameters);
      }
      parameterTypeElement.returnType =
          buildType(serializedParameter.type, _currentTypeParameterizedElement);
      parameterElement.type = new FunctionTypeImpl.elementWithNameAndArgs(
          parameterTypeElement, null, getCurrentTypeArguments(), false);
      parameterTypeElement.type = parameterElement.type;
    }
    buildVariableInitializer(parameterElement, serializedParameter.initializer);
    return parameterElement;
  }

  /**
   * Handle the parts that are common to top level variables and fields.
   */
  void buildPropertyIntroducingElementCommonParts(
      PropertyInducingElementImpl element,
      UnlinkedVariable serializedVariable) {
    buildVariableCommonParts(element, serializedVariable);
    element.propagatedType = buildLinkedType(
        serializedVariable.propagatedTypeSlot,
        _currentTypeParameterizedElement);
  }

  List<FunctionElementImpl> buildTopLevelFunctions() {
    List<FunctionElementImpl> functions = <FunctionElementImpl>[];
    List<UnlinkedExecutable> executables = unlinkedUnit.executables;
    for (UnlinkedExecutable unlinkedExecutable in executables) {
      if (unlinkedExecutable.kind == UnlinkedExecutableKind.functionOrMethod) {
        FunctionElementImpl function =
            new FunctionElementImpl.forSerialized(unlinkedExecutable, unit);
        buildExecutableCommonParts(function, unlinkedExecutable);
        functions.add(function);
      }
    }
    return functions;
  }

  /**
   * Build a [DartType] object based on a [EntityRef].  This [DartType]
   * may refer to elements in other libraries than the library being
   * deserialized, so handles are used to avoid having to deserialize other
   * libraries in the process.
   */
  DartType buildType(
      EntityRef type, TypeParameterizedElementMixin typeParameterContext,
      {bool defaultVoid: false, bool instantiateToBoundsAllowed: true}) {
    if (type == null) {
      if (defaultVoid) {
        return VoidTypeImpl.instance;
      } else {
        return DynamicTypeImpl.instance;
      }
    }
    if (type.paramReference != 0) {
      return typeParameterContext.getTypeParameterType(type.paramReference);
    } else if (type.syntheticReturnType != null) {
      FunctionElementImpl element =
          new FunctionElementImpl_forLUB(unit, typeParameterContext);
      element.parameters = type.syntheticParams
          .map((UnlinkedParam param) =>
              buildParameter(param, element, synthetic: true))
          .toList();
      element.returnType =
          buildType(type.syntheticReturnType, typeParameterContext);
      FunctionTypeImpl result = new FunctionTypeImpl.elementWithNameAndArgs(
          element, null, null, false);
      element.type = result;
      return result;
    } else {
      DartType getTypeArgument(int i) {
        if (i < type.typeArguments.length) {
          return buildType(type.typeArguments[i], typeParameterContext);
        } else {
          return DynamicTypeImpl.instance;
        }
      }
      _ReferenceInfo referenceInfo = getReferenceInfo(type.reference);
      return referenceInfo.buildType(
          instantiateToBoundsAllowed,
          type.typeArguments.length,
          getTypeArgument,
          type.implicitFunctionTypeIndices);
    }
  }

  /**
   * Resynthesize a [FunctionTypeAliasElement] and place it in the
   * [unitHolder].
   */
  void buildTypedef(UnlinkedTypedef serializedTypedef) {
    FunctionTypeAliasElementImpl functionTypeAliasElement =
        new FunctionTypeAliasElementImpl.forSerialized(serializedTypedef, unit);
    // TODO(scheglov) remove this after delaying parameters and their types
    currentTypeParameters.add(functionTypeAliasElement.typeParameters);
    functionTypeAliasElement.parameters = serializedTypedef.parameters
        .map((p) => buildParameter(p, functionTypeAliasElement))
        .toList();
    functionTypeAliasElement.type =
        new FunctionTypeImpl.forTypedef(functionTypeAliasElement);
    unitHolder.addTypeAlias(functionTypeAliasElement);
    // TODO(scheglov) remove this after delaying parameters and their types
    currentTypeParameters.removeLast();
    assert(currentTypeParameters.isEmpty);
  }

  /**
   * Resynthesize a [TypeParameterElement], handling all parts of its except
   * its bound.
   *
   * The bound is deferred until later since it may refer to other type
   * parameters that have not been resynthesized yet.  To handle the bound,
   * call [finishTypeParameter].
   */
  TypeParameterElement buildTypeParameter(
      UnlinkedTypeParam serializedTypeParameter) {
    TypeParameterElementImpl typeParameterElement =
        new TypeParameterElementImpl(
            serializedTypeParameter.name, serializedTypeParameter.nameOffset);
    typeParameterElement.type = new TypeParameterTypeImpl(typeParameterElement);
    buildAnnotations(typeParameterElement, serializedTypeParameter.annotations);
    buildCodeRange(typeParameterElement, serializedTypeParameter.codeRange);
    return typeParameterElement;
  }

  /**
   * Build [TypeParameterElement]s corresponding to the type parameters in
   * [serializedTypeParameters] and store them in [currentTypeParameters].
   * Also return them.
   */
  List<TypeParameterElement> buildTypeParameters(
      List<UnlinkedTypeParam> serializedTypeParameters) {
    int length = serializedTypeParameters.length;
    if (length != 0) {
      List<TypeParameterElement> typeParameters =
          new List<TypeParameterElement>(length);
      for (int i = 0; i < length; i++) {
        typeParameters[i] = buildTypeParameter(serializedTypeParameters[i]);
      }
      currentTypeParameters.add(typeParameters);
      for (int i = 0; i < length; i++) {
        finishTypeParameter(serializedTypeParameters[i], typeParameters[i]);
      }
      return typeParameters;
    } else {
      List<TypeParameterElement> typeParameters =
          const <TypeParameterElement>[];
      currentTypeParameters.add(typeParameters);
      return typeParameters;
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
        buildExecutableCommonParts(accessor, unlinkedExecutable);
        // implicit variable
        TopLevelVariableElementImpl variable = implicitVariables[name];
        if (variable == null) {
          variable = new TopLevelVariableElementImpl(name, -1);
          variable.enclosingElement = unit;
          implicitVariables[name] = variable;
          accessorsData.implicitVariables.add(variable);
          variable.synthetic = true;
          variable.final2 = kind == UnlinkedExecutableKind.getter;
        } else {
          variable.final2 = false;
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
        ConstTopLevelVariableElementImpl constElement =
            new ConstTopLevelVariableElementImpl.forSerialized(
                unlinkedVariable, unit);
        element = constElement;
        constElement.constantInitializer =
            _buildConstExpression(null, unlinkedVariable.initializer.bodyExpr);
      } else {
        element = new TopLevelVariableElementImpl.forSerialized(
            unlinkedVariable, unit);
      }
      buildPropertyIntroducingElementCommonParts(element, unlinkedVariable);
      variablesData.variables[i] = element;
      // implicit accessors
      String name = element.name;
      DartType type = element.type;
      variablesData.implicitAccessors
          .add(buildImplicitGetter(element, name, type));
      if (!(element.isConst || element.isFinal)) {
        variablesData.implicitAccessors
            .add(buildImplicitSetter(element, name, type));
      }
    }
    return variablesData;
  }

  /**
   * Resynthesize a [TopLevelVariableElement] or [FieldElement].
   */
  void buildVariable(
      ClassElementImpl enclosingClass, UnlinkedVariable serializedVariable,
      [ElementHolder holder]) {
    if (holder == null) {
      throw new UnimplementedError('Must be lazy');
    } else {
      FieldElementImpl element;
      if (serializedVariable.initializer?.bodyExpr != null &&
          (serializedVariable.isConst ||
              serializedVariable.isFinal && !serializedVariable.isStatic)) {
        ConstFieldElementImpl constElement =
            new ConstFieldElementImpl.forSerialized(
                serializedVariable, enclosingClass);
        element = constElement;
        constElement.constantInitializer = _buildConstExpression(
            enclosingClass, serializedVariable.initializer.bodyExpr);
      } else {
        element = new FieldElementImpl.forSerialized(
            serializedVariable, enclosingClass);
      }
      buildPropertyIntroducingElementCommonParts(element, serializedVariable);
      element.static = serializedVariable.isStatic;
      holder.addField(element);
      buildImplicitAccessors(element, holder);
      fields[element.name] = element;
    }
  }

  /**
   * Handle the parts that are common to variables.
   */
  void buildVariableCommonParts(
      VariableElementImpl element, UnlinkedVariable serializedVariable) {
    element.type = buildLinkedType(serializedVariable.inferredTypeSlot,
            element.typeParameterContext) ??
        buildType(serializedVariable.type, element.typeParameterContext);
    buildVariableInitializer(element, serializedVariable.initializer);
  }

  /**
   * If the given [serializedInitializer] is not `null`, create the
   * corresponding [FunctionElementImpl] and set it for the [variable].
   */
  void buildVariableInitializer(
      VariableElementImpl variable, UnlinkedExecutable serializedInitializer) {
    if (serializedInitializer == null) {
      return null;
    }
    FunctionElementImpl initializerElement =
        buildLocalFunction(serializedInitializer, variable);
    initializerElement.synthetic = true;
    variable.initializer = initializerElement;
  }

  /**
   * Finish creating a [TypeParameterElement] by deserializing its bound.
   */
  void finishTypeParameter(UnlinkedTypeParam serializedTypeParameter,
      TypeParameterElementImpl typeParameterElement) {
    if (serializedTypeParameter.bound != null) {
      typeParameterElement.bound = buildType(
          serializedTypeParameter.bound, _currentTypeParameterizedElement,
          instantiateToBoundsAllowed: false);
    }
  }

  /**
   * Return a list of type arguments corresponding to [currentTypeParameters],
   * skipping the innermost [skipLevels] nesting levels.
   *
   * Type parameters are listed in nesting order from innermost to outermost,
   * and then in declaration order.  So for instance if we are resynthesizing a
   * method declared as `class C<T, U> { void m<V, W>() { ... } }`, then the
   * type parameters will be returned in the order `[V, W, T, U]`.
   */
  List<DartType> getCurrentTypeArguments({int skipLevels: 0}) {
    assert(currentTypeParameters.length >= skipLevels);
    List<DartType> result = <DartType>[];
    for (int i = currentTypeParameters.length - 1 - skipLevels; i >= 0; i--) {
      result.addAll(currentTypeParameters[i]
          .map((TypeParameterElement param) => param.type));
    }
    return result;
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
      int numTypeParameters = linkedReference.numTypeParameters;
      if (linkedReference.kind == ReferenceKind.unresolved) {
        type = UndefinedTypeImpl.instance;
        element = null;
      } else if (name == 'dynamic') {
        type = DynamicTypeImpl.instance;
        element = type.element;
      } else if (name == 'void') {
        type = VoidTypeImpl.instance;
        element = type.element;
      } else if (name == '*bottom*') {
        type = BottomTypeImpl.instance;
        element = null;
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
        }
        ElementLocation location =
            new ElementLocationImpl.con3(locationComponents);
        if (enclosingInfo != null) {
          numTypeParameters += enclosingInfo.numTypeParameters;
        }
        switch (linkedReference.kind) {
          case ReferenceKind.classOrEnum:
            element = new ClassElementHandle(summaryResynthesizer, location);
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
            element = new FunctionTypeAliasElementHandle(
                summaryResynthesizer, location);
            break;
          case ReferenceKind.variable:
            Element enclosingElement = enclosingInfo.element;
            if (enclosingElement is ExecutableElement) {
              element = new _DeferredLocalVariableElement(
                  enclosingElement, linkedReference.localIndex);
            } else {
              throw new StateError('Unexpected element enclosing variable:'
                  ' ${enclosingElement.runtimeType}');
            }
            break;
          case ReferenceKind.function:
            Element enclosingElement = enclosingInfo.element;
            if (enclosingElement is VariableElement) {
              element = new _DeferredInitializerElement(enclosingElement);
            } else if (enclosingElement is ExecutableElement) {
              element = new _DeferredLocalFunctionElement(
                  enclosingElement, linkedReference.localIndex);
            } else {
              throw new StateError('Unexpected element enclosing function:'
                  ' ${enclosingElement.runtimeType}');
            }
            break;
          case ReferenceKind.prefix:
          case ReferenceKind.unresolved:
            break;
        }
      }
      result = new _ReferenceInfo(libraryResynthesizer, enclosingInfo, name,
          element, type, numTypeParameters);
      referenceInfos[index] = result;
    }
    return result;
  }

  /**
   * Get the type parameter from the surrounding scope whose De Bruijn index is
   * [index].
   */
  DartType getTypeParameterFromScope(int index) {
    for (int i = currentTypeParameters.length - 1; i >= 0; i--) {
      List<TypeParameterElement> paramsAtThisNestingLevel =
          currentTypeParameters[i];
      int numParamsAtThisNestingLevel = paramsAtThisNestingLevel.length;
      if (index <= numParamsAtThisNestingLevel) {
        return paramsAtThisNestingLevel[numParamsAtThisNestingLevel - index]
            .type;
      }
      index -= numParamsAtThisNestingLevel;
    }
    throw new StateError('Type parameter not found');
  }

  /**
   * Populate a [CompilationUnitElement] by deserializing all the elements
   * contained in it.
   */
  void populateUnit() {
    unlinkedUnit.classes.forEach(buildClass);
    unlinkedUnit.enums.forEach(buildEnum);
    unlinkedUnit.typedefs.forEach(buildTypedef);
    unit.enums = unitHolder.enums;
    List<FunctionTypeAliasElement> typeAliases = unitHolder.typeAliases;
    for (FunctionTypeAliasElementImpl typeAlias in typeAliases) {
      if (typeAlias.isSynthetic) {
        typeAlias.enclosingElement = unit;
      }
    }
    unit.typeAliases = typeAliases.where((e) => !e.isSynthetic).toList();
    unit.types = unitHolder.types;
    assert(currentTypeParameters.isEmpty);
  }

  /**
   * Constructor initializers can reference fields and other constructors of
   * the same class, including forward references. So, we need to delay
   * resolution until after class elements are built.
   */
  void resolveConstructorInitializers(ClassElementImpl classElement) {
    for (ConstructorElementImpl constructor in constructors.values) {
      for (ConstructorInitializer initializer
          in constructor.constantInitializers) {
        if (initializer is ConstructorFieldInitializer) {
          SimpleIdentifier nameNode = initializer.fieldName;
          nameNode.staticElement = fields[nameNode.name];
        } else if (initializer is SuperConstructorInvocation) {
          SimpleIdentifier nameNode = initializer.constructorName;
          ConstructorElement element = new _DeferredConstructorElement(
              classElement.supertype, nameNode?.name ?? '');
          initializer.staticElement = element;
          nameNode?.staticElement = element;
        } else if (initializer is RedirectingConstructorInvocation) {
          SimpleIdentifier nameNode = initializer.constructorName;
          ConstructorElement element = constructors[nameNode?.name ?? ''];
          initializer.staticElement = element;
          nameNode?.staticElement = element;
        }
      }
    }
  }

  Expression _buildConstExpression(ElementImpl context, UnlinkedConst uc) {
    return new _ConstExprBuilder(this, context, uc).build();
  }

  /**
   * Return the defining type for a [ConstructorElement] by applying
   * [typeArgumentRefs] to the given linked [info].
   */
  InterfaceType _createConstructorDefiningType(
      TypeParameterizedElementMixin typeParameterContext,
      _ReferenceInfo info,
      List<EntityRef> typeArgumentRefs) {
    bool isClass = info.element is ClassElement;
    _ReferenceInfo classInfo = isClass ? info : info.enclosing;
    List<DartType> typeArguments = typeArgumentRefs
        .map((t) => buildType(t, typeParameterContext))
        .toList();
    return classInfo.buildType(true, typeArguments.length, (i) {
      if (i < typeArguments.length) {
        return typeArguments[i];
      } else {
        return DynamicTypeImpl.instance;
      }
    }, const <int>[]);
  }

  /**
   * Return the [ConstructorElement] corresponding to the given linked [info],
   * using the [classType] which has already been computed (e.g. by
   * [_createConstructorDefiningType]).  Both cases when [info] is a
   * [ClassElement] and [ConstructorElement] are supported.
   */
  ConstructorElement _createConstructorElement(
      InterfaceType classType, _ReferenceInfo info) {
    bool isClass = info.element is ClassElement;
    String name = isClass ? '' : info.name;
    _DeferredConstructorElement element =
        new _DeferredConstructorElement(classType, name);
    if (info.numTypeParameters != 0) {
      return new ConstructorMember(element, classType);
    } else {
      return element;
    }
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
