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
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/element_handle.dart';
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
  final Map<String, Map<String, CompilationUnitElement>> _resynthesizedUnits =
      <String, Map<String, CompilationUnitElement>>{};

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
      Map<String, Map<String, Element>> libraryMap =
          _resynthesizedElements[libraryUri];
      if (libraryMap == null) {
        getLibraryElement(libraryUri);
        libraryMap = _resynthesizedElements[libraryUri];
        assert(libraryMap != null);
      }
      Map<String, Element> compilationUnitElements = libraryMap[components[1]];
      Element element;
      if (compilationUnitElements != null) {
        element = compilationUnitElements[components[2]];
      }
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
      _resynthesizedElements[uri] = libraryResynthesizer.resynthesizedElements;
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
  final _LibraryResynthesizer resynthesizer;
  final UnlinkedConst uc;

  int intPtr = 0;
  int doublePtr = 0;
  int stringPtr = 0;
  int refPtr = 0;
  final List<Expression> stack = <Expression>[];

  _ConstExprBuilder(this.resynthesizer, this.uc);

  Expression get expr => stack.single;

  Expression build() {
    if (uc.isInvalid) {
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
        // identical
        case UnlinkedConstOperation.identical:
          Expression second = _pop();
          Expression first = _pop();
          _push(AstFactory.methodInvocation(
              null, 'identical', <Expression>[first, second]));
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
          EntityRef ref = uc.references[refPtr++];
          _ReferenceInfo info = resynthesizer.referenceInfos[ref.reference];
          if (info.enclosing != null &&
              info.enclosing.element != null &&
              info.enclosing.element is! ClassElement) {
            SimpleIdentifier prefix = AstFactory.identifier3(
                info.enclosing.name)..staticElement = info.enclosing.element;
            SimpleIdentifier name = AstFactory.identifier3(info.name)
              ..staticElement = info.element;
            PrefixedIdentifier node = AstFactory.identifier(prefix, name);
            _push(node);
          } else {
            SimpleIdentifier node = AstFactory.identifier3(info.name);
            node.staticElement = info.element;
            _push(node);
          }
          break;
        case UnlinkedConstOperation.invokeConstructor:
          _pushInstanceCreation();
          break;
        case UnlinkedConstOperation.length:
          Expression target = _pop();
          SimpleIdentifier property = AstFactory.identifier3('length');
          property.staticElement =
              resynthesizer._buildStringLengthPropertyAccessorElement();
          _push(AstFactory.propertyAccess(target, property));
          break;
        case UnlinkedConstOperation.pushConstructorParameter:
          String name = uc.strings[stringPtr++];
          SimpleIdentifier identifier = AstFactory.identifier3(name);
          identifier.staticElement = resynthesizer.currentConstructor.parameters
              .firstWhere((parameter) => parameter.name == name,
                  orElse: () => throw new StateError(
                      'Unable to resolve constructor parameter: $name'));
          _push(identifier);
          break;
      }
    }
    return stack.single;
  }

  TypeName _buildTypeAst(DartType type) {
    if (type is DynamicTypeImpl) {
      TypeName node = AstFactory.typeName4('dynamic');
      node.type = type;
      (node.name as SimpleIdentifier).staticElement = type.element;
      return node;
    } else if (type is InterfaceType) {
      List<DartType> typeArguments = type.typeArguments;
      List<TypeName> argumentNodes = typeArguments.every((a) => a.isDynamic)
          ? null
          : typeArguments.map(_buildTypeAst).toList();
      TypeName node = AstFactory.typeName4(type.name, argumentNodes);
      node.type = type;
      (node.name as SimpleIdentifier).staticElement = type.element;
      return node;
    }
    throw new StateError('Unsupported type $type');
  }

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
    DartType type = resynthesizer.buildType(typeRef);
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

  void _pushInstanceCreation() {
    EntityRef ref = uc.references[refPtr++];
    _ReferenceInfo info = resynthesizer.referenceInfos[ref.reference];
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
      InterfaceType definingType =
          resynthesizer._createConstructorDefiningType(info, ref.typeArguments);
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

  List<Expression> _removeTopItems(int count) {
    int start = stack.length - count;
    int end = stack.length;
    List<Expression> items = stack.getRange(start, end).toList();
    stack.removeRange(start, end);
    return items;
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
  Element get actualElement => enclosingElement.getNamedConstructor(name);

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
 * Local function element representing the intializer for a variable that has
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
   * Indicates whether [librarySource] is the `dart:core` library.
   */
  bool isCoreLibrary;

  /**
   * Classes which should have their supertype set to "object" once
   * resynthesis is complete.  Only used if [isCoreLibrary] is `true`.
   */
  List<ClassElementImpl> delayedObjectSubclasses = <ClassElementImpl>[];

  /**
   * [ElementHolder] into which resynthesized elements should be placed.  This
   * object is recreated afresh for each unit in the library, and is used to
   * populate the [CompilationUnitElement].
   */
  ElementHolder unitHolder;

  /**
   * The [LinkedUnit] from which elements are currently being resynthesized.
   */
  LinkedUnit linkedUnit;

  /**
   * The [UnlinkedUnit] from which elements are currently being resynthesized.
   */
  UnlinkedUnit unlinkedUnit;

  /**
   * Map from slot id to the corresponding [EntityRef] object for linked types
   * (i.e. propagated and inferred types).
   */
  Map<int, EntityRef> linkedTypeMap;

  /**
   * Set of slot ids corresponding to const constructors that are part of
   * cycles.
   */
  Set<int> constCycles;

  /**
   * The [CompilationUnitElementImpl] for the compilation unit currently being
   * resynthesized.
   */
  CompilationUnitElementImpl currentCompilationUnit;

  /**
   * The [ConstructorElementImpl] for the constructor currently being
   * resynthesized.
   */
  ConstructorElementImpl currentConstructor;

  /**
   * Map of compilation unit elements that have been resynthesized so far.  The
   * key is the URI of the compilation unit.
   */
  final Map<String, CompilationUnitElement> resynthesizedUnits =
      <String, CompilationUnitElement>{};

  /**
   * Map of top level elements that have been resynthesized so far.  The first
   * key is the URI of the compilation unit; the second is the name of the top
   * level element.
   */
  final Map<String, Map<String, Element>> resynthesizedElements =
      <String, Map<String, Element>>{};

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

  /**
   * List of [_ReferenceInfo] objects describing the references in the current
   * compilation unit.
   */
  List<_ReferenceInfo> referenceInfos;

  _LibraryResynthesizer(this.summaryResynthesizer, this.linkedLibrary,
      this.unlinkedUnits, this.librarySource) {
    isCoreLibrary = librarySource.uri.toString() == 'dart:core';
  }

  /**
   * Build the annotations for the given [element].
   */
  void buildAnnotations(
      ElementImpl element, List<UnlinkedConst> serializedAnnotations) {
    if (serializedAnnotations.isNotEmpty) {
      element.metadata = serializedAnnotations.map((UnlinkedConst a) {
        ElementAnnotationImpl elementAnnotation =
            new ElementAnnotationImpl(this.currentCompilationUnit);
        Expression constExpr = _buildConstExpression(a);
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
      }).toList();
    }
  }

  /**
   * Resynthesize a [ClassElement] and place it in [unitHolder].
   */
  void buildClass(UnlinkedClass serializedClass) {
    ClassElementImpl classElement =
        new ClassElementImpl(serializedClass.name, serializedClass.nameOffset);
    classElement.hasBeenInferred = summaryResynthesizer.strongMode;
    classElement.typeParameters =
        buildTypeParameters(serializedClass.typeParameters);
    classElement.abstract = serializedClass.isAbstract;
    classElement.mixinApplication = serializedClass.isMixinApplication;
    InterfaceTypeImpl correspondingType = new InterfaceTypeImpl(classElement);
    if (serializedClass.supertype != null) {
      classElement.supertype = buildType(serializedClass.supertype);
    } else if (!serializedClass.hasNoSupertype) {
      if (isCoreLibrary) {
        delayedObjectSubclasses.add(classElement);
      } else {
        classElement.supertype = summaryResynthesizer.typeProvider.objectType;
      }
    }
    classElement.interfaces =
        serializedClass.interfaces.map(buildType).toList();
    classElement.mixins = serializedClass.mixins.map(buildType).toList();
    ElementHolder memberHolder = new ElementHolder();
    fields = <String, FieldElementImpl>{};
    for (UnlinkedVariable serializedVariable in serializedClass.fields) {
      buildVariable(serializedVariable, memberHolder);
    }
    bool constructorFound = false;
    constructors = <String, ConstructorElementImpl>{};
    for (UnlinkedExecutable serializedExecutable
        in serializedClass.executables) {
      switch (serializedExecutable.kind) {
        case UnlinkedExecutableKind.constructor:
          constructorFound = true;
          buildConstructor(
              serializedExecutable, memberHolder, correspondingType);
          break;
        case UnlinkedExecutableKind.functionOrMethod:
        case UnlinkedExecutableKind.getter:
        case UnlinkedExecutableKind.setter:
          if (serializedExecutable.isStatic) {
            currentTypeParameters.removeLast();
          }
          buildExecutable(serializedExecutable, memberHolder);
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
        constructor.returnType = correspondingType;
        constructor.type = new FunctionTypeImpl.elementWithNameAndArgs(
            constructor, null, getCurrentTypeArguments(), false);
        memberHolder.addConstructor(constructor);
      }
      classElement.constructors = memberHolder.constructors;
    }
    classElement.accessors = memberHolder.accessors;
    classElement.fields = memberHolder.fields;
    classElement.methods = memberHolder.methods;
    correspondingType.typeArguments = getCurrentTypeArguments();
    classElement.type = correspondingType;
    buildDocumentation(classElement, serializedClass.documentationComment);
    buildAnnotations(classElement, serializedClass.annotations);
    buildCodeRange(classElement, serializedClass.codeRange);
    resolveConstructorInitializers(classElement);
    unitHolder.addType(classElement);
    currentTypeParameters.removeLast();
    assert(currentTypeParameters.isEmpty);
    fields = null;
    constructors = null;
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
   * Resynthesize the [ConstructorInitializer] in context of
   * [currentConstructor], which is used to resolve constructor parameter names.
   */
  ConstructorInitializer buildConstantInitializer(
      UnlinkedConstructorInitializer serialized) {
    UnlinkedConstructorInitializerKind kind = serialized.kind;
    String name = serialized.name;
    List<Expression> arguments =
        serialized.arguments.map(_buildConstExpression).toList();
    switch (kind) {
      case UnlinkedConstructorInitializerKind.field:
        return AstFactory.constructorFieldInitializer(
            false, name, _buildConstExpression(serialized.expression));
      case UnlinkedConstructorInitializerKind.superInvocation:
        return AstFactory.superConstructorInvocation2(
            name.isNotEmpty ? name : null, arguments);
      case UnlinkedConstructorInitializerKind.thisInvocation:
        return AstFactory.redirectingConstructorInvocation2(
            name.isNotEmpty ? name : null, arguments);
    }
  }

  /**
   * Resynthesize a [ConstructorElement] and place it in the given [holder].
   * [classType] is the type of the class for which this element is a
   * constructor.
   */
  void buildConstructor(UnlinkedExecutable serializedExecutable,
      ElementHolder holder, InterfaceType classType) {
    assert(serializedExecutable.kind == UnlinkedExecutableKind.constructor);
    currentConstructor = new ConstructorElementImpl(
        serializedExecutable.name, serializedExecutable.nameOffset);
    currentConstructor.isCycleFree = serializedExecutable.isConst &&
        !constCycles.contains(serializedExecutable.constCycleSlot);
    if (serializedExecutable.name.isEmpty) {
      currentConstructor.nameEnd =
          serializedExecutable.nameOffset + classType.name.length;
    } else {
      currentConstructor.nameEnd = serializedExecutable.nameEnd;
      currentConstructor.periodOffset = serializedExecutable.periodOffset;
    }
    constructors[serializedExecutable.name] = currentConstructor;
    currentConstructor.returnType = classType;
    buildExecutableCommonParts(currentConstructor, serializedExecutable);
    currentConstructor.factory = serializedExecutable.isFactory;
    currentConstructor.const2 = serializedExecutable.isConst;
    currentConstructor.constantInitializers = serializedExecutable
        .constantInitializers
        .map(buildConstantInitializer)
        .toList();
    if (serializedExecutable.isRedirectedConstructor) {
      if (serializedExecutable.isFactory) {
        EntityRef redirectedConstructor =
            serializedExecutable.redirectedConstructor;
        _ReferenceInfo info = referenceInfos[redirectedConstructor.reference];
        List<EntityRef> typeArguments = redirectedConstructor.typeArguments;
        currentConstructor.redirectedConstructor = _createConstructorElement(
            _createConstructorDefiningType(info, typeArguments), info);
      } else {
        List<String> locationComponents =
            currentCompilationUnit.location.components.toList();
        locationComponents.add(classType.name);
        locationComponents.add(serializedExecutable.redirectedConstructorName);
        currentConstructor.redirectedConstructor =
            new _DeferredConstructorElement._(
                classType,
                serializedExecutable.redirectedConstructorName,
                new ElementLocationImpl.con3(locationComponents));
      }
    }
    holder.addConstructor(currentConstructor);
    currentConstructor = null;
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
    assert(!isCoreLibrary);
    ClassElementImpl classElement =
        new ClassElementImpl(serializedEnum.name, serializedEnum.nameOffset);
    classElement.enum2 = true;
    InterfaceType enumType = new InterfaceTypeImpl(classElement);
    classElement.type = enumType;
    classElement.supertype = summaryResynthesizer.typeProvider.objectType;
    buildDocumentation(classElement, serializedEnum.documentationComment);
    buildAnnotations(classElement, serializedEnum.annotations);
    buildCodeRange(classElement, serializedEnum.codeRange);
    ElementHolder memberHolder = new ElementHolder();
    // Build the 'index' field.
    FieldElementImpl indexField = new FieldElementImpl('index', -1);
    indexField.final2 = true;
    indexField.synthetic = true;
    indexField.type = summaryResynthesizer.typeProvider.intType;
    memberHolder.addField(indexField);
    buildImplicitAccessors(indexField, memberHolder);
    // Build the 'values' field.
    FieldElementImpl valuesField = new ConstFieldElementImpl('values', -1);
    valuesField.synthetic = true;
    valuesField.const3 = true;
    valuesField.static = true;
    valuesField.type = summaryResynthesizer.typeProvider.listType
        .instantiate(<DartType>[enumType]);
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
        fieldName: new DartObjectImpl(
            summaryResynthesizer.typeProvider.intType, new IntState(i))
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
  void buildExecutable(UnlinkedExecutable serializedExecutable,
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
          FunctionElementImpl executableElement =
              new FunctionElementImpl(name, serializedExecutable.nameOffset);
          buildExecutableCommonParts(executableElement, serializedExecutable);
          holder.addFunction(executableElement);
        } else {
          MethodElementImpl executableElement =
              new MethodElementImpl(name, serializedExecutable.nameOffset);
          executableElement.abstract = serializedExecutable.isAbstract;
          buildExecutableCommonParts(executableElement, serializedExecutable);
          executableElement.static = serializedExecutable.isStatic;
          holder.addMethod(executableElement);
        }
        break;
      case UnlinkedExecutableKind.getter:
      case UnlinkedExecutableKind.setter:
        PropertyAccessorElementImpl executableElement =
            new PropertyAccessorElementImpl(
                name, serializedExecutable.nameOffset);
        if (isTopLevel) {
          executableElement.static = true;
        } else {
          executableElement.static = serializedExecutable.isStatic;
          executableElement.abstract = serializedExecutable.isAbstract;
        }
        buildExecutableCommonParts(executableElement, serializedExecutable);
        DartType type;
        if (kind == UnlinkedExecutableKind.getter) {
          executableElement.getter = true;
          type = executableElement.returnType;
        } else {
          executableElement.setter = true;
          type = executableElement.parameters[0].type;
        }
        holder.addAccessor(executableElement);
        PropertyInducingElementImpl implicitVariable;
        if (isTopLevel) {
          implicitVariable = buildImplicitTopLevelVariable(name, kind, holder);
        } else {
          FieldElementImpl field = buildImplicitField(name, type, kind, holder);
          field.static = serializedExecutable.isStatic;
          implicitVariable = field;
        }
        executableElement.variable = implicitVariable;
        if (kind == UnlinkedExecutableKind.getter) {
          implicitVariable.getter = executableElement;
        } else {
          implicitVariable.setter = executableElement;
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
    executableElement.parameters =
        serializedExecutable.parameters.map(buildParameter).toList();
    if (serializedExecutable.kind == UnlinkedExecutableKind.constructor) {
      // Caller handles setting the return type.
      assert(serializedExecutable.returnType == null);
    } else {
      bool isSetter =
          serializedExecutable.kind == UnlinkedExecutableKind.setter;
      executableElement.returnType =
          buildLinkedType(serializedExecutable.inferredReturnTypeSlot) ??
              buildType(serializedExecutable.returnType,
                  defaultVoid: isSetter && summaryResynthesizer.strongMode);
      executableElement.hasImplicitReturnType =
          serializedExecutable.returnType == null;
    }
    executableElement.type = new FunctionTypeImpl.elementWithNameAndArgs(
        executableElement, null, getCurrentTypeArguments(skipLevels: 1), false);
    executableElement.external = serializedExecutable.isExternal;
    buildDocumentation(
        executableElement, serializedExecutable.documentationComment);
    buildAnnotations(executableElement, serializedExecutable.annotations);
    buildCodeRange(executableElement, serializedExecutable.codeRange);
    executableElement.functions =
        serializedExecutable.localFunctions.map(buildLocalFunction).toList();
    executableElement.labels =
        serializedExecutable.localLabels.map(buildLocalLabel).toList();
    executableElement.localVariables =
        serializedExecutable.localVariables.map(buildLocalVariable).toList();
    currentTypeParameters.removeLast();
  }

  /**
   * Resynthesize an [ExportElement],
   */
  ExportElement buildExport(UnlinkedExportPublic serializedExportPublic,
      UnlinkedExportNonPublic serializedExportNonPublic) {
    ExportElementImpl exportElement =
        new ExportElementImpl(serializedExportNonPublic.offset);
    String exportedLibraryUri = summaryResynthesizer.sourceFactory
        .resolveUri(librarySource, serializedExportPublic.uri)
        .uri
        .toString();
    exportElement.exportedLibrary = new LibraryElementHandle(
        summaryResynthesizer,
        new ElementLocationImpl.con3(<String>[exportedLibraryUri]));
    exportElement.uri = serializedExportPublic.uri;
    exportElement.combinators =
        serializedExportPublic.combinators.map(buildCombinator).toList();
    exportElement.uriOffset = serializedExportNonPublic.uriOffset;
    exportElement.uriEnd = serializedExportNonPublic.uriEnd;
    buildAnnotations(exportElement, serializedExportNonPublic.annotations);
    return exportElement;
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
      case ReferenceKind.length:
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
   * Build the implicit getter and setter associated with [element], and place
   * them in [holder].
   */
  void buildImplicitAccessors(
      PropertyInducingElementImpl element, ElementHolder holder) {
    String name = element.name;
    DartType type = element.type;
    PropertyAccessorElementImpl getter =
        new PropertyAccessorElementImpl(name, element.nameOffset);
    getter.getter = true;
    getter.static = element.isStatic;
    getter.synthetic = true;
    getter.returnType = type;
    getter.type = new FunctionTypeImpl(getter);
    getter.variable = element;
    getter.hasImplicitReturnType = element.hasImplicitType;
    holder.addAccessor(getter);
    element.getter = getter;
    if (!(element.isConst || element.isFinal)) {
      PropertyAccessorElementImpl setter =
          new PropertyAccessorElementImpl(name, element.nameOffset);
      setter.setter = true;
      setter.static = element.isStatic;
      setter.synthetic = true;
      setter.parameters = <ParameterElement>[
        new ParameterElementImpl('_$name', element.nameOffset)
          ..synthetic = true
          ..type = type
          ..parameterKind = ParameterKind.REQUIRED
      ];
      setter.returnType = VoidTypeImpl.instance;
      setter.type = new FunctionTypeImpl(setter);
      setter.variable = element;
      holder.addAccessor(setter);
      element.setter = setter;
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
   * Build the implicit top level variable associated with a getter or setter,
   * and place it in [holder].
   */
  PropertyInducingElementImpl buildImplicitTopLevelVariable(
      String name, UnlinkedExecutableKind kind, ElementHolder holder) {
    TopLevelVariableElementImpl variable = holder.getTopLevelVariable(name);
    if (variable == null) {
      variable = new TopLevelVariableElementImpl(name, -1);
      variable.synthetic = true;
      variable.final2 = kind == UnlinkedExecutableKind.getter;
      holder.addTopLevelVariable(variable);
      return variable;
    } else {
      // TODO(paulberry): what if the getter and setter have a type mismatch?
      variable.final2 = false;
      return variable;
    }
  }

  /**
   * Resynthesize an [ImportElement].
   */
  ImportElement buildImport(UnlinkedImport serializedImport, int dependency) {
    bool isSynthetic = serializedImport.isImplicit;
    ImportElementImpl importElement =
        new ImportElementImpl(isSynthetic ? -1 : serializedImport.offset);
    String absoluteUri = summaryResynthesizer.sourceFactory
        .resolveUri(librarySource, linkedLibrary.dependencies[dependency].uri)
        .uri
        .toString();
    importElement.importedLibrary = new LibraryElementHandle(
        summaryResynthesizer,
        new ElementLocationImpl.con3(<String>[absoluteUri]));
    if (isSynthetic) {
      importElement.synthetic = true;
    } else {
      importElement.uri = serializedImport.uri;
      importElement.uriOffset = serializedImport.uriOffset;
      importElement.uriEnd = serializedImport.uriEnd;
      importElement.deferred = serializedImport.isDeferred;
      buildAnnotations(importElement, serializedImport.annotations);
    }
    importElement.prefixOffset = serializedImport.prefixOffset;
    if (serializedImport.prefixReference != 0) {
      UnlinkedReference serializedPrefix =
          unlinkedUnits[0].references[serializedImport.prefixReference];
      importElement.prefix = new PrefixElementImpl(
          serializedPrefix.name, serializedImport.prefixOffset);
    }
    importElement.combinators =
        serializedImport.combinators.map(buildCombinator).toList();
    return importElement;
  }

  /**
   * Main entry point.  Resynthesize the [LibraryElement] and return it.
   */
  LibraryElement buildLibrary() {
    CompilationUnitElementImpl definingCompilationUnit =
        new CompilationUnitElementImpl(librarySource.shortName);
    prepareUnit(definingCompilationUnit, 0);
    bool hasName = unlinkedUnits[0].libraryName.isNotEmpty;
    LibraryElementImpl library = new LibraryElementImpl(
        summaryResynthesizer.context,
        unlinkedUnits[0].libraryName,
        hasName ? unlinkedUnits[0].libraryNameOffset : -1,
        unlinkedUnits[0].libraryNameLength);
    buildDocumentation(library, unlinkedUnits[0].libraryDocumentationComment);
    buildAnnotations(library, unlinkedUnits[0].libraryAnnotations);
    library.definingCompilationUnit = definingCompilationUnit;
    definingCompilationUnit.source = librarySource;
    definingCompilationUnit.librarySource = librarySource;
    List<CompilationUnitElement> parts = <CompilationUnitElement>[];
    UnlinkedUnit unlinkedDefiningUnit = unlinkedUnits[0];
    assert(unlinkedDefiningUnit.publicNamespace.parts.length + 1 ==
        linkedLibrary.units.length);
    for (int i = 1; i < linkedLibrary.units.length; i++) {
      CompilationUnitElementImpl part = buildPart(
          unlinkedDefiningUnit.publicNamespace.parts[i - 1],
          unlinkedDefiningUnit.parts[i - 1],
          unlinkedUnits[i]);
      parts.add(part);
    }
    library.parts = parts;
    List<ImportElement> imports = <ImportElement>[];
    for (int i = 0; i < unlinkedDefiningUnit.imports.length; i++) {
      imports.add(buildImport(unlinkedDefiningUnit.imports[i],
          linkedLibrary.importDependencies[i]));
    }
    library.imports = imports;
    List<ExportElement> exports = <ExportElement>[];
    assert(unlinkedDefiningUnit.exports.length ==
        unlinkedDefiningUnit.publicNamespace.exports.length);
    for (int i = 0; i < unlinkedDefiningUnit.exports.length; i++) {
      exports.add(buildExport(unlinkedDefiningUnit.publicNamespace.exports[i],
          unlinkedDefiningUnit.exports[i]));
    }
    library.exports = exports;
    populateUnit(definingCompilationUnit, 0);
    finishUnit();
    for (int i = 0; i < parts.length; i++) {
      prepareUnit(parts[i], i + 1);
      populateUnit(parts[i], i + 1);
      finishUnit();
    }
    BuildLibraryElementUtils.patchTopLevelAccessors(library);
    // Update delayed Object class references.
    if (isCoreLibrary) {
      ClassElement objectElement = library.getType('Object');
      assert(objectElement != null);
      for (ClassElementImpl classElement in delayedObjectSubclasses) {
        classElement.supertype = objectElement.type;
      }
    }
    // Compute namespaces.
    library.publicNamespace =
        new NamespaceBuilder().createPublicNamespaceForLibrary(library);
    library.exportNamespace = buildExportNamespace(
        library.publicNamespace, linkedLibrary.exportNames);
    // Find the entry point.  Note: we can't use element.isEntryPoint because
    // that will trigger resynthesis of exported libraries.
    Element entryPoint =
        library.exportNamespace.get(FunctionElement.MAIN_FUNCTION_NAME);
    if (entryPoint is FunctionElement) {
      library.entryPoint = entryPoint;
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
   * Build the appropriate [DartType] object corresponding to a slot id in the
   * [LinkedUnit.types] table.
   */
  DartType buildLinkedType(int slot) {
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
    return buildType(type);
  }

  /**
   * Resynthesize a local [FunctionElement].
   */
  FunctionElementImpl buildLocalFunction(
      UnlinkedExecutable serializedExecutable) {
    FunctionElementImpl element = new FunctionElementImpl(
        serializedExecutable.name, serializedExecutable.nameOffset);
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
  LocalVariableElement buildLocalVariable(UnlinkedVariable serializedVariable) {
    LocalVariableElementImpl element;
    if (serializedVariable.constExpr != null) {
      ConstLocalVariableElementImpl constElement =
          new ConstLocalVariableElementImpl(
              serializedVariable.name, serializedVariable.nameOffset);
      element = constElement;
      constElement.constantInitializer =
          _buildConstExpression(serializedVariable.constExpr);
    } else {
      element = new LocalVariableElementImpl(
          serializedVariable.name, serializedVariable.nameOffset);
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
  ParameterElement buildParameter(UnlinkedParam serializedParameter,
      {bool synthetic: false}) {
    ParameterElementImpl parameterElement;
    int nameOffset = synthetic ? -1 : serializedParameter.nameOffset;
    if (serializedParameter.isInitializingFormal) {
      FieldFormalParameterElementImpl initializingParameter;
      if (serializedParameter.kind == UnlinkedParamKind.required) {
        initializingParameter = new FieldFormalParameterElementImpl(
            serializedParameter.name, nameOffset);
      } else {
        DefaultFieldFormalParameterElementImpl defaultParameter =
            new DefaultFieldFormalParameterElementImpl(
                serializedParameter.name, nameOffset);
        initializingParameter = defaultParameter;
        if (serializedParameter.defaultValue != null) {
          defaultParameter.constantInitializer =
              _buildConstExpression(serializedParameter.defaultValue);
          defaultParameter.defaultValueCode =
              serializedParameter.defaultValueCode;
        }
      }
      parameterElement = initializingParameter;
      initializingParameter.field = fields[serializedParameter.name];
    } else {
      if (serializedParameter.kind == UnlinkedParamKind.required) {
        parameterElement =
            new ParameterElementImpl(serializedParameter.name, nameOffset);
      } else {
        DefaultParameterElementImpl defaultParameter =
            new DefaultParameterElementImpl(
                serializedParameter.name, nameOffset);
        parameterElement = defaultParameter;
        if (serializedParameter.defaultValue != null) {
          defaultParameter.constantInitializer =
              _buildConstExpression(serializedParameter.defaultValue);
          defaultParameter.defaultValueCode =
              serializedParameter.defaultValueCode;
        }
      }
    }
    parameterElement.synthetic = synthetic;
    buildAnnotations(parameterElement, serializedParameter.annotations);
    buildCodeRange(parameterElement, serializedParameter.codeRange);
    if (serializedParameter.isFunctionTyped) {
      FunctionElementImpl parameterTypeElement =
          new FunctionElementImpl('', -1);
      parameterTypeElement.synthetic = true;
      parameterElement.parameters =
          serializedParameter.parameters.map(buildParameter).toList();
      parameterTypeElement.enclosingElement = parameterElement;
      parameterTypeElement.shareParameters(parameterElement.parameters);
      parameterTypeElement.returnType = buildType(serializedParameter.type);
      parameterElement.type = new FunctionTypeImpl.elementWithNameAndArgs(
          parameterTypeElement, null, getCurrentTypeArguments(), false);
    } else {
      if (serializedParameter.isInitializingFormal &&
          serializedParameter.type == null) {
        // The type is inherited from the matching field.
        parameterElement.type = fields[serializedParameter.name]?.type ??
            summaryResynthesizer.typeProvider.dynamicType;
      } else {
        parameterElement.type =
            buildLinkedType(serializedParameter.inferredTypeSlot) ??
                buildType(serializedParameter.type);
      }
      parameterElement.hasImplicitType = serializedParameter.type == null;
    }
    buildVariableInitializer(parameterElement, serializedParameter.initializer);
    switch (serializedParameter.kind) {
      case UnlinkedParamKind.named:
        parameterElement.parameterKind = ParameterKind.NAMED;
        break;
      case UnlinkedParamKind.positional:
        parameterElement.parameterKind = ParameterKind.POSITIONAL;
        break;
      case UnlinkedParamKind.required:
        parameterElement.parameterKind = ParameterKind.REQUIRED;
        break;
    }
    if (serializedParameter.visibleOffset != 0) {
      parameterElement.setVisibleRange(
          serializedParameter.visibleOffset, serializedParameter.visibleLength);
    }
    return parameterElement;
  }

  /**
   * Create, but do not populate, the [CompilationUnitElement] for a part other
   * than the defining compilation unit.
   */
  CompilationUnitElementImpl buildPart(
      String uri, UnlinkedPart partDecl, UnlinkedUnit serializedPart) {
    Source unitSource =
        summaryResynthesizer.sourceFactory.resolveUri(librarySource, uri);
    CompilationUnitElementImpl partUnit =
        new CompilationUnitElementImpl(unitSource.shortName);
    partUnit.uriOffset = partDecl.uriOffset;
    partUnit.uriEnd = partDecl.uriEnd;
    partUnit.source = unitSource;
    partUnit.librarySource = librarySource;
    partUnit.uri = uri;
    buildAnnotations(partUnit, partDecl.annotations);
    return partUnit;
  }

  /**
   * Handle the parts that are common to top level variables and fields.
   */
  void buildPropertyIntroducingElementCommonParts(
      PropertyInducingElementImpl element,
      UnlinkedVariable serializedVariable) {
    buildVariableCommonParts(element, serializedVariable);
    element.propagatedType =
        buildLinkedType(serializedVariable.propagatedTypeSlot);
  }

  /**
   * Build a [DartType] object based on a [EntityRef].  This [DartType]
   * may refer to elements in other libraries than the library being
   * deserialized, so handles are used to avoid having to deserialize other
   * libraries in the process.
   */
  DartType buildType(EntityRef type, {bool defaultVoid: false}) {
    if (type == null) {
      if (defaultVoid) {
        return VoidTypeImpl.instance;
      } else {
        return summaryResynthesizer.typeProvider.dynamicType;
      }
    }
    if (type.paramReference != 0) {
      return getTypeParameterFromScope(type.paramReference);
    } else if (type.syntheticReturnType != null) {
      FunctionElementImpl element = new FunctionElementImpl('', -1);
      element.synthetic = true;
      element.parameters = type.syntheticParams
          .map((UnlinkedParam param) => buildParameter(param, synthetic: true))
          .toList();
      element.returnType = buildType(type.syntheticReturnType);
      FunctionTypeImpl result = new FunctionTypeImpl.elementWithNameAndArgs(
          element, null, null, false);
      element.type = result;
      return result;
    } else {
      DartType getTypeArgument(int i) {
        if (i < type.typeArguments.length) {
          return buildType(type.typeArguments[i]);
        } else {
          return summaryResynthesizer.typeProvider.dynamicType;
        }
      }
      _ReferenceInfo referenceInfo = referenceInfos[type.reference];
      return referenceInfo.buildType(
          getTypeArgument, type.implicitFunctionTypeIndices);
    }
  }

  /**
   * Resynthesize a [FunctionTypeAliasElement] and place it in the
   * [unitHolder].
   */
  void buildTypedef(UnlinkedTypedef serializedTypedef) {
    FunctionTypeAliasElementImpl functionTypeAliasElement =
        new FunctionTypeAliasElementImpl(
            serializedTypedef.name, serializedTypedef.nameOffset);
    functionTypeAliasElement.typeParameters =
        buildTypeParameters(serializedTypedef.typeParameters);
    functionTypeAliasElement.parameters =
        serializedTypedef.parameters.map(buildParameter).toList();
    functionTypeAliasElement.returnType =
        buildType(serializedTypedef.returnType);
    functionTypeAliasElement.type =
        new FunctionTypeImpl.forTypedef(functionTypeAliasElement);
    buildDocumentation(
        functionTypeAliasElement, serializedTypedef.documentationComment);
    buildAnnotations(functionTypeAliasElement, serializedTypedef.annotations);
    buildCodeRange(functionTypeAliasElement, serializedTypedef.codeRange);
    unitHolder.addTypeAlias(functionTypeAliasElement);
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
    List<TypeParameterElement> typeParameters =
        serializedTypeParameters.map(buildTypeParameter).toList();
    currentTypeParameters.add(typeParameters);
    for (int i = 0; i < serializedTypeParameters.length; i++) {
      finishTypeParameter(serializedTypeParameters[i], typeParameters[i]);
    }
    return typeParameters;
  }

  /**
   * Resynthesize a [TopLevelVariableElement] or [FieldElement].
   */
  void buildVariable(UnlinkedVariable serializedVariable,
      [ElementHolder holder]) {
    if (holder == null) {
      TopLevelVariableElementImpl element;
      if (serializedVariable.constExpr != null) {
        ConstTopLevelVariableElementImpl constElement =
            new ConstTopLevelVariableElementImpl(
                serializedVariable.name, serializedVariable.nameOffset);
        element = constElement;
        constElement.constantInitializer =
            _buildConstExpression(serializedVariable.constExpr);
      } else {
        element = new TopLevelVariableElementImpl(
            serializedVariable.name, serializedVariable.nameOffset);
      }
      buildPropertyIntroducingElementCommonParts(element, serializedVariable);
      unitHolder.addTopLevelVariable(element);
      buildImplicitAccessors(element, unitHolder);
    } else {
      FieldElementImpl element;
      if (serializedVariable.constExpr != null) {
        ConstFieldElementImpl constElement = new ConstFieldElementImpl(
            serializedVariable.name, serializedVariable.nameOffset);
        element = constElement;
        constElement.constantInitializer =
            _buildConstExpression(serializedVariable.constExpr);
      } else {
        element = new FieldElementImpl(
            serializedVariable.name, serializedVariable.nameOffset);
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
    element.type = buildLinkedType(serializedVariable.inferredTypeSlot) ??
        buildType(serializedVariable.type);
    element.const3 = serializedVariable.isConst;
    element.final2 = serializedVariable.isFinal;
    element.hasImplicitType = serializedVariable.type == null;
    buildVariableInitializer(element, serializedVariable.initializer);
    buildDocumentation(element, serializedVariable.documentationComment);
    buildAnnotations(element, serializedVariable.annotations);
    buildCodeRange(element, serializedVariable.codeRange);
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
        buildLocalFunction(serializedInitializer);
    initializerElement.synthetic = true;
    initializerElement.setCodeRange(null, null);
    variable.initializer = initializerElement;
  }

  /**
   * Finish creating a [TypeParameterElement] by deserializing its bound.
   */
  void finishTypeParameter(UnlinkedTypeParam serializedTypeParameter,
      TypeParameterElementImpl typeParameterElement) {
    if (serializedTypeParameter.bound != null) {
      typeParameterElement.bound = buildType(serializedTypeParameter.bound);
    }
  }

  /**
   * Tear down data structures used during deserialization of a compilation
   * unit.
   */
  void finishUnit() {
    unitHolder = null;
    linkedUnit = null;
    unlinkedUnit = null;
    linkedTypeMap = null;
    constCycles = null;
    referenceInfos = null;
    currentCompilationUnit = null;
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
   * Build the components of an [ElementLocationImpl] for the entity in the
   * given [unit] of the dependency located at [dependencyIndex], and having
   * the given [name].
   */
  List<String> getReferencedLocationComponents(
      int dependencyIndex, int unit, String name) {
    if (dependencyIndex == 0) {
      String referencedLibraryUri = librarySource.uri.toString();
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
      Source partSource = summaryResynthesizer.sourceFactory
          .resolveUri(referencedLibrarySource, uri);
      partUri = partSource.uri.toString();
    } else {
      partUri = referencedLibraryUri;
    }
    return <String>[referencedLibraryUri, partUri, name];
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
   * Populate [referenceInfos] with the correct information for the current
   * compilation unit.
   */
  void populateReferenceInfos() {
    int numLinkedReferences = linkedUnit.references.length;
    int numUnlinkedReferences = unlinkedUnit.references.length;
    referenceInfos = new List<_ReferenceInfo>(numLinkedReferences);
    for (int i = 0; i < numLinkedReferences; i++) {
      LinkedReference linkedReference = linkedUnit.references[i];
      String name;
      int containingReference;
      if (i < numUnlinkedReferences) {
        name = unlinkedUnit.references[i].name;
        containingReference = unlinkedUnit.references[i].prefixReference;
      } else {
        name = linkedUnit.references[i].name;
        containingReference = linkedUnit.references[i].containingReference;
      }
      _ReferenceInfo enclosingInfo =
          containingReference != 0 ? referenceInfos[containingReference] : null;
      Element element;
      DartType type;
      int numTypeParameters = linkedReference.numTypeParameters;
      if (linkedReference.kind == ReferenceKind.unresolved) {
        type = summaryResynthesizer.typeProvider.undefinedType;
        element = null;
      } else if (name == 'dynamic') {
        type = summaryResynthesizer.typeProvider.dynamicType;
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
          locationComponents = getReferencedLocationComponents(
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
          case ReferenceKind.length:
            element = _buildStringLengthPropertyAccessorElement();
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
      referenceInfos[i] = new _ReferenceInfo(
          enclosingInfo, name, element, type, numTypeParameters);
    }
  }

  /**
   * Populate a [CompilationUnitElement] by deserializing all the elements
   * contained in it.
   */
  void populateUnit(CompilationUnitElementImpl unit, int unitNum) {
    unlinkedUnit.classes.forEach(buildClass);
    unlinkedUnit.enums.forEach(buildEnum);
    unlinkedUnit.executables.forEach(buildExecutable);
    unlinkedUnit.typedefs.forEach(buildTypedef);
    unlinkedUnit.variables.forEach(buildVariable);
    String absoluteUri = unit.source.uri.toString();
    unit.accessors = unitHolder.accessors;
    unit.enums = unitHolder.enums;
    unit.functions = unitHolder.functions;
    List<FunctionTypeAliasElement> typeAliases = unitHolder.typeAliases;
    for (FunctionTypeAliasElementImpl typeAlias in typeAliases) {
      if (typeAlias.isSynthetic) {
        typeAlias.enclosingElement = unit;
      }
    }
    unit.typeAliases = typeAliases.where((e) => !e.isSynthetic).toList();
    unit.types = unitHolder.types;
    unit.topLevelVariables = unitHolder.topLevelVariables;
    Map<String, Element> elementMap = <String, Element>{};
    for (ClassElement cls in unit.types) {
      elementMap[cls.name] = cls;
    }
    for (ClassElement cls in unit.enums) {
      elementMap[cls.name] = cls;
    }
    for (FunctionTypeAliasElement typeAlias in unit.functionTypeAliases) {
      elementMap[typeAlias.name] = typeAlias;
    }
    for (FunctionElement function in unit.functions) {
      elementMap[function.name] = function;
    }
    for (PropertyAccessorElementImpl accessor in unit.accessors) {
      elementMap[accessor.identifier] = accessor;
    }
    buildCodeRange(unit, unlinkedUnit.codeRange);
    resynthesizedUnits[absoluteUri] = unit;
    resynthesizedElements[absoluteUri] = elementMap;
    assert(currentTypeParameters.isEmpty);
  }

  /**
   * Set up data structures for deserializing a compilation unit.
   */
  void prepareUnit(CompilationUnitElementImpl unit, int unitNum) {
    linkedUnit = linkedLibrary.units[unitNum];
    unlinkedUnit = unlinkedUnits[unitNum];
    linkedTypeMap = <int, EntityRef>{};
    currentCompilationUnit = unit;
    for (EntityRef t in linkedUnit.types) {
      linkedTypeMap[t.slot] = t;
    }
    constCycles = linkedUnit.constCycles.toSet();
    populateReferenceInfos();
    unitHolder = new ElementHolder();
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

  Expression _buildConstExpression(UnlinkedConst uc) {
    return new _ConstExprBuilder(this, uc).build();
  }

  /**
   * Return the new handle of the `String.length` getter element.
   */
  PropertyAccessorElementHandle _buildStringLengthPropertyAccessorElement() =>
      new PropertyAccessorElementHandle(
          summaryResynthesizer,
          new ElementLocationImpl.con3(
              <String>['dart:core', 'dart:core', 'String', 'length?']));

  /**
   * Return the defining type for a [ConstructorElement] by applying
   * [typeArgumentRefs] to the given linked [info].
   */
  InterfaceType _createConstructorDefiningType(
      _ReferenceInfo info, List<EntityRef> typeArgumentRefs) {
    bool isClass = info.element is ClassElement;
    _ReferenceInfo classInfo = isClass ? info : info.enclosing;
    List<DartType> typeArguments = typeArgumentRefs.map(buildType).toList();
    return classInfo.buildType((i) {
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

/**
 * Data structure used during resynthesis to record all the information that is
 * known about how to resynthesize a single entry in [LinkedUnit.references]
 * (and its associated entry in [UnlinkedUnit.references], if it exists).
 */
class _ReferenceInfo {
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
  _ReferenceInfo(this.enclosing, this.name, this.element, DartType specialType,
      this.numTypeParameters) {
    if (specialType != null) {
      type = specialType;
    } else {
      type = _buildType((_) => DynamicTypeImpl.instance, const []);
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
  DartType buildType(
      DartType getTypeArgument(int i), List<int> implicitFunctionTypeIndices) {
    DartType result =
        (numTypeParameters == 0 && implicitFunctionTypeIndices.isEmpty)
            ? type
            : _buildType(getTypeArgument, implicitFunctionTypeIndices);
    if (result == null) {
      // TODO(paulberry): figure out how to handle this case (which should
      // only occur in the event of erroneous code).
      throw new UnimplementedError();
    }
    return result;
  }

  /**
   * If this reference refers to a type, build a [DartType] which instantiates
   * it with type arguments returned by [getTypeArgument].  Otherwise return
   * `null`.
   *
   * If [implicitFunctionTypeIndices] is not null, a [DartType] should be
   * created which refers to a function type implicitly defined by one of the
   * element's parameters.  [implicitFunctionTypeIndices] is interpreted as in
   * [EntityRef.implicitFunctionTypeIndices].
   */
  DartType _buildType(
      DartType getTypeArgument(int i), List<int> implicitFunctionTypeIndices) {
    ElementHandle element = this.element; // To allow type promotion
    if (element is ClassElementHandle) {
      return new InterfaceTypeImpl.elementWithNameAndArgs(element, name,
          _buildTypeArguments(numTypeParameters, getTypeArgument));
    } else if (element is FunctionTypeAliasElementHandle) {
      return new FunctionTypeImpl.elementWithNameAndArgs(
          element,
          name,
          _buildTypeArguments(numTypeParameters, getTypeArgument),
          numTypeParameters != 0);
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
      } else {
        // For a type that refers to a generic executable, the type arguments are
        // not supposed to include the arguments to the executable itself.
        numTypeArguments = enclosing == null ? 0 : enclosing.numTypeParameters;
        computer = () => this.element;
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
