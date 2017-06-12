// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary/format.dart'
    show AnalysisDriverUnitIndexBuilder;
import 'package:analyzer/src/summary/idl.dart';

/**
 * Return the [CompilationUnitElement] that should be used for [element].
 * Throw [StateError] if the [element] is not linked into a unit.
 */
CompilationUnitElement getUnitElement(Element element) {
  for (Element e = element; e != null; e = e.enclosingElement) {
    if (e is CompilationUnitElement) {
      return e;
    }
    if (e is LibraryElement) {
      return e.definingCompilationUnit;
    }
  }
  throw new StateError('Element not contained in compilation unit: $element');
}

/**
 * Index the [unit] into a new [AnalysisDriverUnitIndexBuilder].
 */
AnalysisDriverUnitIndexBuilder indexUnit(CompilationUnit unit) {
  return new _IndexAssembler().assemble(unit);
}

/**
 * Information about an element that is actually put into index for some other
 * related element. For example for a synthetic getter this is the corresponding
 * non-synthetic field and [IndexSyntheticElementKind.getter] as the [kind].
 */
class IndexElementInfo {
  final Element element;
  final IndexSyntheticElementKind kind;

  factory IndexElementInfo(Element element) {
    IndexSyntheticElementKind kind = IndexSyntheticElementKind.notSynthetic;
    ElementKind elementKind = element.kind;
    if (elementKind == ElementKind.LIBRARY ||
        elementKind == ElementKind.COMPILATION_UNIT) {
      kind = IndexSyntheticElementKind.unit;
    } else if (element.isSynthetic) {
      if (elementKind == ElementKind.CONSTRUCTOR) {
        kind = IndexSyntheticElementKind.constructor;
        element = element.enclosingElement;
      } else if (elementKind == ElementKind.FUNCTION &&
          element.name == 'loadLibrary') {
        kind = IndexSyntheticElementKind.loadLibrary;
        element = element.library;
      } else if (elementKind == ElementKind.FIELD) {
        FieldElement field = element;
        kind = IndexSyntheticElementKind.field;
        element = field.getter ?? field.setter;
      } else if (elementKind == ElementKind.GETTER ||
          elementKind == ElementKind.SETTER) {
        PropertyAccessorElement accessor = element;
        Element enclosing = element.enclosingElement;
        bool isEnumGetter = enclosing is ClassElement && enclosing.isEnum;
        if (isEnumGetter && accessor.name == 'index') {
          kind = IndexSyntheticElementKind.enumIndex;
          element = enclosing;
        } else if (isEnumGetter && accessor.name == 'values') {
          kind = IndexSyntheticElementKind.enumValues;
          element = enclosing;
        } else {
          kind = accessor.isGetter
              ? IndexSyntheticElementKind.getter
              : IndexSyntheticElementKind.setter;
          element = accessor.variable;
        }
      } else if (elementKind == ElementKind.TOP_LEVEL_VARIABLE) {
        TopLevelVariableElement property = element;
        kind = IndexSyntheticElementKind.topLevelVariable;
        element = property.getter ?? property.setter;
      } else {
        throw new ArgumentError(
            'Unsupported synthetic element ${element.runtimeType}');
      }
    }
    return new IndexElementInfo._(element, kind);
  }

  IndexElementInfo._(this.element, this.kind);
}

/**
 * Information about an element referenced in index.
 */
class _ElementInfo {
  /**
   * The identifier of the [CompilationUnitElement] containing this element.
   */
  final int unitId;

  /**
   * The identifier of the top-level name, or `null` if the element is a
   * reference to the unit.
   */
  final _StringInfo nameIdUnitMember;

  /**
   * The identifier of the class member name, or `null` if the element is not a
   * class member or a named parameter of a class member.
   */
  final _StringInfo nameIdClassMember;

  /**
   * The identifier of the named parameter name, or `null` if the element is not
   * a named parameter.
   */
  final _StringInfo nameIdParameter;

  /**
   * The kind of the element.
   */
  final IndexSyntheticElementKind kind;

  /**
   * The unique id of the element.  It is set after indexing of the whole
   * package is done and we are assembling the full package index.
   */
  int id;

  _ElementInfo(this.unitId, this.nameIdUnitMember, this.nameIdClassMember,
      this.nameIdParameter, this.kind);
}

/**
 * Information about a single relation in a single compilation unit.
 */
class _ElementRelationInfo {
  final _ElementInfo elementInfo;
  final IndexRelationKind kind;
  final int offset;
  final int length;
  final bool isQualified;

  _ElementRelationInfo(
      this.elementInfo, this.kind, this.offset, this.length, this.isQualified);
}

/**
 * Assembler of a single [CompilationUnit] index.
 *
 * The intended usage sequence:
 *
 *  - Call [addElementRelation] for each element relation found in the unit.
 *  - Call [addNameRelation] for each name relation found in the unit.
 *  - Assign ids to all the [_ElementInfo] in [elementRelations].
 *  - Call [assemble] to produce the final unit index.
 */
class _IndexAssembler {
  /**
   * The string to use in place of the `null` string.
   */
  static const NULL_STRING = '--nullString--';

  /**
   * Map associating referenced elements with their [_ElementInfo]s.
   */
  final Map<Element, _ElementInfo> elementMap = {};

  /**
   * Map associating [CompilationUnitElement]s with their identifiers, which
   * are indices into [unitLibraryUris] and [unitUnitUris].
   */
  final Map<CompilationUnitElement, int> unitMap = {};

  /**
   * The fields [unitLibraryUris] and [unitUnitUris] are used together to
   * describe each unique [CompilationUnitElement].
   *
   * This field contains the library URI of a unit.
   */
  final List<_StringInfo> unitLibraryUris = [];

  /**
   * The fields [unitLibraryUris] and [unitUnitUris] are used together to
   * describe each unique [CompilationUnitElement].
   *
   * This field contains the unit URI of a unit, which might be the same as
   * the library URI for the defining unit, or a different one for a part.
   */
  final List<_StringInfo> unitUnitUris = [];

  /**
   * Map associating strings with their [_StringInfo]s.
   */
  final Map<String, _StringInfo> stringMap = {};

  /**
   * All element relations.
   */
  final List<_ElementRelationInfo> elementRelations = [];

  /**
   * All unresolved name relations.
   */
  final List<_NameRelationInfo> nameRelations = [];

  /**
   * The [_StringInfo] to use for `null` strings.
   */
  _StringInfo nullString;

  _IndexAssembler() {
    nullString = _getStringInfo(NULL_STRING);
  }

  void addElementRelation(Element element, IndexRelationKind kind, int offset,
      int length, bool isQualified) {
    _ElementInfo elementInfo = _getElementInfo(element);
    elementRelations.add(new _ElementRelationInfo(
        elementInfo, kind, offset, length, isQualified));
  }

  void addNameRelation(
      String name, IndexRelationKind kind, int offset, bool isQualified) {
    _StringInfo nameId = _getStringInfo(name);
    nameRelations.add(new _NameRelationInfo(nameId, kind, offset, isQualified));
  }

  /**
   * Index the [unit] and assemble a new [AnalysisDriverUnitIndexBuilder].
   */
  AnalysisDriverUnitIndexBuilder assemble(CompilationUnit unit) {
    unit.accept(new _IndexContributor(this));
    // sort strings end set IDs
    List<_StringInfo> stringInfoList = stringMap.values.toList();
    stringInfoList.sort((a, b) {
      return a.value.compareTo(b.value);
    });
    for (int i = 0; i < stringInfoList.length; i++) {
      stringInfoList[i].id = i;
    }
    // sort elements and set IDs
    List<_ElementInfo> elementInfoList = elementMap.values.toList();
    elementInfoList.sort((a, b) {
      int delta;
      delta = a.nameIdUnitMember.id - b.nameIdUnitMember.id;
      if (delta != null) {
        return delta;
      }
      delta = a.nameIdClassMember.id - b.nameIdClassMember.id;
      if (delta != null) {
        return delta;
      }
      return a.nameIdParameter.id - b.nameIdParameter.id;
    });
    for (int i = 0; i < elementInfoList.length; i++) {
      elementInfoList[i].id = i;
    }
    // Sort element and name relations.
    elementRelations.sort((a, b) {
      return a.elementInfo.id - b.elementInfo.id;
    });
    nameRelations.sort((a, b) {
      return a.nameInfo.id - b.nameInfo.id;
    });
    return new AnalysisDriverUnitIndexBuilder(
        strings: stringInfoList.map((s) => s.value).toList(),
        nullStringId: nullString.id,
        unitLibraryUris: unitLibraryUris.map((s) => s.id).toList(),
        unitUnitUris: unitUnitUris.map((s) => s.id).toList(),
        elementKinds: elementInfoList.map((e) => e.kind).toList(),
        elementUnits: elementInfoList.map((e) => e.unitId).toList(),
        elementNameUnitMemberIds:
            elementInfoList.map((e) => e.nameIdUnitMember.id).toList(),
        elementNameClassMemberIds:
            elementInfoList.map((e) => e.nameIdClassMember.id).toList(),
        elementNameParameterIds:
            elementInfoList.map((e) => e.nameIdParameter.id).toList(),
        usedElements: elementRelations.map((r) => r.elementInfo.id).toList(),
        usedElementKinds: elementRelations.map((r) => r.kind).toList(),
        usedElementOffsets: elementRelations.map((r) => r.offset).toList(),
        usedElementLengths: elementRelations.map((r) => r.length).toList(),
        usedElementIsQualifiedFlags:
            elementRelations.map((r) => r.isQualified).toList(),
        usedNames: nameRelations.map((r) => r.nameInfo.id).toList(),
        usedNameKinds: nameRelations.map((r) => r.kind).toList(),
        usedNameOffsets: nameRelations.map((r) => r.offset).toList(),
        usedNameIsQualifiedFlags:
            nameRelations.map((r) => r.isQualified).toList());
  }

  /**
   * Return the unique [_ElementInfo] corresponding the [element].  The field
   * [_ElementInfo.id] is filled by [assemble] during final sorting.
   */
  _ElementInfo _getElementInfo(Element element) {
    if (element is Member) {
      element = (element as Member).baseElement;
    }
    return elementMap.putIfAbsent(element, () {
      CompilationUnitElement unitElement = getUnitElement(element);
      int unitId = _getUnitId(unitElement);
      return _newElementInfo(unitId, element);
    });
  }

  /**
   * Return the unique [_StringInfo] corresponding the given [string].  The
   * field [_StringInfo.id] is filled by [assemble] during final sorting.
   */
  _StringInfo _getStringInfo(String string) {
    return stringMap.putIfAbsent(string, () {
      return new _StringInfo(string);
    });
  }

  /**
   * Add information about [unitElement] to [unitUnitUris] and
   * [unitLibraryUris] if necessary, and return the location in those
   * arrays representing [unitElement].
   */
  int _getUnitId(CompilationUnitElement unitElement) {
    return unitMap.putIfAbsent(unitElement, () {
      assert(unitLibraryUris.length == unitUnitUris.length);
      int id = unitUnitUris.length;
      unitLibraryUris.add(_getUriInfo(unitElement.library.source.uri));
      unitUnitUris.add(_getUriInfo(unitElement.source.uri));
      return id;
    });
  }

  /**
   * Return the unique [_StringInfo] corresponding [uri].  The field
   * [_StringInfo.id] is filled by [assemble] during final sorting.
   */
  _StringInfo _getUriInfo(Uri uri) {
    String str = uri.toString();
    return _getStringInfo(str);
  }

  /**
   * Return a new [_ElementInfo] for the given [element] in the given [unitId].
   * This method is static, so it cannot add any information to the index.
   */
  _ElementInfo _newElementInfo(int unitId, Element element) {
    IndexElementInfo info = new IndexElementInfo(element);
    element = info.element;
    // Prepare name identifiers.
    _StringInfo nameIdParameter = nullString;
    _StringInfo nameIdClassMember = nullString;
    _StringInfo nameIdUnitMember = nullString;
    if (element is ParameterElement) {
      nameIdParameter = _getStringInfo(element.name);
      element = element.enclosingElement;
    }
    if (element?.enclosingElement is ClassElement) {
      nameIdClassMember = _getStringInfo(element.name);
      element = element.enclosingElement;
    }
    if (element?.enclosingElement is CompilationUnitElement) {
      nameIdUnitMember = _getStringInfo(element.name);
    }
    return new _ElementInfo(unitId, nameIdUnitMember, nameIdClassMember,
        nameIdParameter, info.kind);
  }
}

/**
 * Visits a resolved AST and adds relationships into the [assembler].
 */
class _IndexContributor extends GeneralizingAstVisitor {
  final _IndexAssembler assembler;

  _IndexContributor(this.assembler);

  void recordIsAncestorOf(Element descendant) {
    _recordIsAncestorOf(descendant, descendant, false, <ClassElement>[]);
  }

  /**
   * Record that the name [node] has a relation of the given [kind].
   */
  void recordNameRelation(
      SimpleIdentifier node, IndexRelationKind kind, bool isQualified) {
    if (node != null) {
      assembler.addNameRelation(node.name, kind, node.offset, isQualified);
    }
  }

  /**
   * Record reference to the given operator [Element].
   */
  void recordOperatorReference(Token operator, Element element) {
    recordRelationToken(element, IndexRelationKind.IS_INVOKED_BY, operator);
  }

  /**
   * Record that [element] has a relation of the given [kind] at the location
   * of the given [node].  The flag [isQualified] is `true` if [node] has an
   * explicit or implicit qualifier, so cannot be shadowed by a local
   * declaration.
   */
  void recordRelation(
      Element element, IndexRelationKind kind, AstNode node, bool isQualified) {
    if (element != null && node != null) {
      recordRelationOffset(
          element, kind, node.offset, node.length, isQualified);
    }
  }

  /**
   * Record that [element] has a relation of the given [kind] at the given
   * [offset] and [length].  The flag [isQualified] is `true` if the relation
   * has an explicit or implicit qualifier, so [element] cannot be shadowed by
   * a local declaration.
   */
  void recordRelationOffset(Element element, IndexRelationKind kind, int offset,
      int length, bool isQualified) {
    // Ignore elements that can't be referenced outside of the unit.
    ElementKind elementKind = element?.kind;
    if (elementKind == null ||
        elementKind == ElementKind.DYNAMIC ||
        elementKind == ElementKind.ERROR ||
        elementKind == ElementKind.LABEL ||
        elementKind == ElementKind.LOCAL_VARIABLE ||
        elementKind == ElementKind.PREFIX ||
        elementKind == ElementKind.TYPE_PARAMETER ||
        elementKind == ElementKind.FUNCTION &&
            element is FunctionElement &&
            element.enclosingElement is ExecutableElement ||
        elementKind == ElementKind.PARAMETER &&
            element is ParameterElement &&
            element.parameterKind != ParameterKind.NAMED ||
        false) {
      return;
    }
    // Ignore named parameters of synthetic functions, e.g. created for LUB.
    // These functions are not bound to a source, we cannot index them.
    if (elementKind == ElementKind.PARAMETER &&
        element is ParameterElement &&
        element.enclosingElement.isSynthetic) {
      return;
    }
    // Add the relation.
    assembler.addElementRelation(element, kind, offset, length, isQualified);
  }

  /**
   * Record that [element] has a relation of the given [kind] at the location
   * of the given [token].
   */
  void recordRelationToken(
      Element element, IndexRelationKind kind, Token token) {
    if (element != null && token != null) {
      recordRelationOffset(element, kind, token.offset, token.length, true);
    }
  }

  /**
   * Record a relation between a super [typeName] and its [Element].
   */
  void recordSuperType(TypeName typeName, IndexRelationKind kind) {
    Identifier name = typeName?.name;
    if (name != null) {
      Element element = name.staticElement;
      bool isQualified;
      SimpleIdentifier relNode;
      if (name is PrefixedIdentifier) {
        isQualified = true;
        relNode = name.identifier;
      } else {
        isQualified = false;
        relNode = name;
      }
      recordRelation(element, kind, relNode, isQualified);
      recordRelation(
          element, IndexRelationKind.IS_REFERENCED_BY, relNode, isQualified);
      typeName.typeArguments?.accept(this);
    }
  }

  void recordUriReference(Element element, UriBasedDirective directive) {
    recordRelation(
        element, IndexRelationKind.IS_REFERENCED_BY, directive.uri, true);
  }

  @override
  visitAssignmentExpression(AssignmentExpression node) {
    recordOperatorReference(node.operator, node.bestElement);
    super.visitAssignmentExpression(node);
  }

  @override
  visitBinaryExpression(BinaryExpression node) {
    recordOperatorReference(node.operator, node.bestElement);
    super.visitBinaryExpression(node);
  }

  @override
  visitClassDeclaration(ClassDeclaration node) {
    if (node.extendsClause == null) {
      ClassElement objectElement = resolutionMap
          .elementDeclaredByClassDeclaration(node)
          .supertype
          ?.element;
      recordRelationOffset(objectElement, IndexRelationKind.IS_EXTENDED_BY,
          node.name.offset, 0, true);
    }
    recordIsAncestorOf(node.element);
    super.visitClassDeclaration(node);
  }

  @override
  visitClassTypeAlias(ClassTypeAlias node) {
    recordIsAncestorOf(node.element);
    super.visitClassTypeAlias(node);
  }

  @override
  visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    SimpleIdentifier fieldName = node.fieldName;
    if (fieldName != null) {
      Element element = fieldName.staticElement;
      recordRelation(element, IndexRelationKind.IS_WRITTEN_BY, fieldName, true);
    }
    node.expression?.accept(this);
  }

  @override
  visitConstructorName(ConstructorName node) {
    ConstructorElement element = node.staticElement;
    element = _getActualConstructorElement(element);
    // record relation
    if (node.name != null) {
      int offset = node.period.offset;
      int length = node.name.end - offset;
      recordRelationOffset(
          element, IndexRelationKind.IS_REFERENCED_BY, offset, length, true);
    } else {
      int offset = node.type.end;
      recordRelationOffset(
          element, IndexRelationKind.IS_REFERENCED_BY, offset, 0, true);
    }
    node.type.accept(this);
  }

  @override
  visitExportDirective(ExportDirective node) {
    ExportElement element = node.element;
    recordUriReference(element?.exportedLibrary, node);
    super.visitExportDirective(node);
  }

  @override
  visitExtendsClause(ExtendsClause node) {
    recordSuperType(node.superclass, IndexRelationKind.IS_EXTENDED_BY);
  }

  @override
  visitImplementsClause(ImplementsClause node) {
    for (TypeName typeName in node.interfaces) {
      recordSuperType(typeName, IndexRelationKind.IS_IMPLEMENTED_BY);
    }
  }

  @override
  visitImportDirective(ImportDirective node) {
    ImportElement element = node.element;
    recordUriReference(element?.importedLibrary, node);
    super.visitImportDirective(node);
  }

  @override
  visitIndexExpression(IndexExpression node) {
    MethodElement element = node.bestElement;
    if (element is MethodElement) {
      Token operator = node.leftBracket;
      recordRelationToken(element, IndexRelationKind.IS_INVOKED_BY, operator);
    }
    super.visitIndexExpression(node);
  }

  @override
  visitLibraryIdentifier(LibraryIdentifier node) {}

  @override
  visitMethodInvocation(MethodInvocation node) {
    SimpleIdentifier name = node.methodName;
    Element element = name.bestElement;
    // unresolved name invocation
    bool isQualified = node.realTarget != null;
    if (element == null) {
      recordNameRelation(name, IndexRelationKind.IS_INVOKED_BY, isQualified);
    }
    // element invocation
    IndexRelationKind kind = element is ClassElement
        ? IndexRelationKind.IS_REFERENCED_BY
        : IndexRelationKind.IS_INVOKED_BY;
    recordRelation(element, kind, name, isQualified);
    node.target?.accept(this);
    node.argumentList?.accept(this);
  }

  @override
  visitPartDirective(PartDirective node) {
    CompilationUnitElement element = node.element;
    if (element?.source != null) {
      recordUriReference(element, node);
    }
    super.visitPartDirective(node);
  }

  @override
  visitPostfixExpression(PostfixExpression node) {
    recordOperatorReference(node.operator, node.bestElement);
    super.visitPostfixExpression(node);
  }

  @override
  visitPrefixExpression(PrefixExpression node) {
    recordOperatorReference(node.operator, node.bestElement);
    super.visitPrefixExpression(node);
  }

  @override
  visitRedirectingConstructorInvocation(RedirectingConstructorInvocation node) {
    ConstructorElement element = node.staticElement;
    if (node.constructorName != null) {
      int offset = node.period.offset;
      int length = node.constructorName.end - offset;
      recordRelationOffset(
          element, IndexRelationKind.IS_REFERENCED_BY, offset, length, true);
    } else {
      int offset = node.thisKeyword.end;
      recordRelationOffset(
          element, IndexRelationKind.IS_REFERENCED_BY, offset, 0, true);
    }
    super.visitRedirectingConstructorInvocation(node);
  }

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    // name in declaration
    if (node.inDeclarationContext()) {
      return;
    }
    Element element = node.bestElement;
    // record unresolved name reference
    bool isQualified = _isQualified(node);
    if (element == null) {
      bool inGetterContext = node.inGetterContext();
      bool inSetterContext = node.inSetterContext();
      IndexRelationKind kind;
      if (inGetterContext && inSetterContext) {
        kind = IndexRelationKind.IS_READ_WRITTEN_BY;
      } else if (inGetterContext) {
        kind = IndexRelationKind.IS_READ_BY;
      } else {
        kind = IndexRelationKind.IS_WRITTEN_BY;
      }
      recordNameRelation(node, kind, isQualified);
    }
    // this.field parameter
    if (element is FieldFormalParameterElement) {
      AstNode parent = node.parent;
      IndexRelationKind kind =
          parent is FieldFormalParameter && parent.identifier == node
              ? IndexRelationKind.IS_WRITTEN_BY
              : IndexRelationKind.IS_REFERENCED_BY;
      recordRelation(element.field, kind, node, true);
      return;
    }
    // ignore a local reference to a parameter
    if (element is ParameterElement && node.parent is! Label) {
      return;
    }
    // record specific relations
    recordRelation(
        element, IndexRelationKind.IS_REFERENCED_BY, node, isQualified);
  }

  @override
  visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    ConstructorElement element = node.staticElement;
    if (node.constructorName != null) {
      int offset = node.period.offset;
      int length = node.constructorName.end - offset;
      recordRelationOffset(
          element, IndexRelationKind.IS_REFERENCED_BY, offset, length, true);
    } else {
      int offset = node.superKeyword.end;
      recordRelationOffset(
          element, IndexRelationKind.IS_REFERENCED_BY, offset, 0, true);
    }
    node.argumentList?.accept(this);
  }

  @override
  visitTypeName(TypeName node) {
    AstNode parent = node.parent;
    if (parent is ClassTypeAlias && parent.superclass == node) {
      recordSuperType(node, IndexRelationKind.IS_EXTENDED_BY);
    } else {
      super.visitTypeName(node);
    }
  }

  @override
  visitWithClause(WithClause node) {
    for (TypeName typeName in node.mixinTypes) {
      recordSuperType(typeName, IndexRelationKind.IS_MIXED_IN_BY);
    }
  }

  /**
   * If the given [constructor] is a synthetic constructor created for a
   * [ClassTypeAlias], return the actual constructor of a [ClassDeclaration]
   * which is invoked.  Return `null` if a redirection cycle is detected.
   */
  ConstructorElement _getActualConstructorElement(
      ConstructorElement constructor) {
    Set<ConstructorElement> seenConstructors = new Set<ConstructorElement>();
    while (constructor != null &&
        constructor.isSynthetic &&
        constructor.redirectedConstructor != null) {
      constructor = constructor.redirectedConstructor;
      // fail if a cycle is detected
      if (!seenConstructors.add(constructor)) {
        return null;
      }
    }
    return constructor;
  }

  /**
   * Return `true` if [node] has an explicit or implicit qualifier, so that it
   * cannot be shadowed by a local declaration.
   */
  bool _isQualified(SimpleIdentifier node) {
    if (node.isQualified) {
      return true;
    }
    AstNode parent = node.parent;
    return parent is Combinator || parent is Label;
  }

  void _recordIsAncestorOf(Element descendant, ClassElement ancestor,
      bool includeThis, List<ClassElement> visitedElements) {
    if (ancestor == null) {
      return;
    }
    if (visitedElements.contains(ancestor)) {
      return;
    }
    visitedElements.add(ancestor);
    if (includeThis) {
      int offset = descendant.nameOffset;
      int length = descendant.nameLength;
      assembler.addElementRelation(
          ancestor, IndexRelationKind.IS_ANCESTOR_OF, offset, length, false);
    }
    {
      InterfaceType superType = ancestor.supertype;
      if (superType != null) {
        _recordIsAncestorOf(
            descendant, superType.element, true, visitedElements);
      }
    }
    for (InterfaceType mixinType in ancestor.mixins) {
      _recordIsAncestorOf(descendant, mixinType.element, true, visitedElements);
    }
    for (InterfaceType implementedType in ancestor.interfaces) {
      _recordIsAncestorOf(
          descendant, implementedType.element, true, visitedElements);
    }
  }
}

/**
 * Information about a single name relation in single compilation unit.
 */
class _NameRelationInfo {
  final _StringInfo nameInfo;
  final IndexRelationKind kind;
  final int offset;
  final bool isQualified;

  _NameRelationInfo(this.nameInfo, this.kind, this.offset, this.isQualified);
}

/**
 * Information about a string referenced in the index.
 */
class _StringInfo {
  /**
   * The value of the string.
   */
  final String value;

  /**
   * The unique id of the string.  It is set after indexing of the whole
   * package is done and we are assembling the full package index.
   */
  int id;

  _StringInfo(this.value);
}
