// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';

/**
 * Object that gathers information about the whole package index and then uses
 * it to assemble a new [PackageIndexBuilder].  Call [index] on each compilation
 * unit to be indexed, then call [assemble] to retrieve the complete index for
 * the package.
 */
class PackageIndexAssembler {
  /**
   * Map associating referenced elements with their [_ElementInfo]s.
   */
  final Map<Element, _ElementInfo> _elementMap = <Element, _ElementInfo>{};

  /**
   * Map associating [CompilationUnitElement]s with their identifiers, which
   * are indices into [_unitLibraryUris] and [_unitUnitUris].
   */
  final Map<CompilationUnitElement, int> _unitMap =
      <CompilationUnitElement, int>{};

  /**
   * Each item of this list corresponds to the library URI of a unique
   * [CompilationUnitElement].  It is an index into [_strings].
   */
  final List<int> _unitLibraryUris = <int>[];

  /**
   * Each item of this list corresponds to the unit URI of a unique
   * [CompilationUnitElement].  It is an index into [_strings].
   */
  final List<int> _unitUnitUris = <int>[];

  /**
   * Map associating strings with their identifiers, which are indices
   * into [_strings].
   */
  final Map<String, int> _stringMap = <String, int>{};

  /**
   * List of unique strings used in this index.
   */
  final List<String> _strings = <String>[];

  /**
   * List of information about each unit indexed in this index.
   */
  final List<_UnitIndexAssembler> _units = <_UnitIndexAssembler>[];

  /**
   * Assemble a new [PackageIndexBuilder] using the information gathered by
   * [index].
   */
  PackageIndexBuilder assemble() {
    List<_ElementInfo> elementInfoList = _elementMap.values.toList();
    elementInfoList.sort((a, b) {
      return a.offset - b.offset;
    });
    for (int i = 0; i < elementInfoList.length; i++) {
      elementInfoList[i].id = i;
    }
    return new PackageIndexBuilder(
        unitLibraryUris: _unitLibraryUris,
        unitUnitUris: _unitUnitUris,
        elementUnits: elementInfoList.map((e) => e.unitId).toList(),
        elementOffsets: elementInfoList.map((e) => e.offset).toList(),
        elementKinds: elementInfoList.map((e) => e.kind).toList(),
        strings: _strings,
        units: _units.map((unit) => unit.assemble()).toList());
  }

  /**
   * Index the given fully resolved [unit].
   */
  void index(CompilationUnit unit) {
    int unitId = _getUnitId(unit.element);
    _UnitIndexAssembler assembler = new _UnitIndexAssembler(this, unitId);
    _units.add(assembler);
    unit.accept(new _IndexContributor(assembler));
  }

  /**
   * Return the unique [_ElementInfo] corresponding the [element].  The field
   * [_ElementInfo.id] is filled by [assemble] during final sorting.
   */
  _ElementInfo _getElementInfo(Element element) {
    if (element is Member) {
      element = (element as Member).baseElement;
    }
    return _elementMap.putIfAbsent(element, () {
      CompilationUnitElement unitElement = getUnitElement(element);
      int unitId = _getUnitId(unitElement);
      int offset = element.nameOffset;
      if (element is LibraryElement || element is CompilationUnitElement) {
        offset = 0;
      }
      IndexSyntheticElementKind kind = getIndexElementKind(element);
      return new _ElementInfo(unitId, offset, kind);
    });
  }

  /**
   * Add information about [str] to [_strings] if necessary, and return the
   * location in this array representing [str].
   */
  int _getStringId(String str) {
    return _stringMap.putIfAbsent(str, () {
      int id = _strings.length;
      _strings.add(str);
      return id;
    });
  }

  /**
   * Add information about [unitElement] to [_unitUnitUris] and
   * [_unitLibraryUris] if necessary, and return the location in those
   * arrays representing [unitElement].
   */
  int _getUnitId(CompilationUnitElement unitElement) {
    return _unitMap.putIfAbsent(unitElement, () {
      assert(_unitLibraryUris.length == _unitUnitUris.length);
      int id = _unitUnitUris.length;
      _unitLibraryUris.add(_getUriId(unitElement.library.source.uri));
      _unitUnitUris.add(_getUriId(unitElement.source.uri));
      return id;
    });
  }

  /**
   * Return the identifier corresponding to [uri].
   */
  int _getUriId(Uri uri) {
    String str = uri.toString();
    return _getStringId(str);
  }

  /**
   * Return the kind of the given [element].
   */
  static IndexSyntheticElementKind getIndexElementKind(Element element) {
    if (element.isSynthetic) {
      if (element is ConstructorElement) {
        return IndexSyntheticElementKind.constructor;
      }
      if (element is PropertyAccessorElement) {
        return element.isGetter
            ? IndexSyntheticElementKind.getter
            : IndexSyntheticElementKind.setter;
      }
    }
    return IndexSyntheticElementKind.notSynthetic;
  }

  /**
   * Return the [CompilationUnitElement] that should be used for [element].
   * Throw [StateError] if the [element] is not linked into a unit.
   */
  static CompilationUnitElement getUnitElement(Element element) {
    for (Element e = element; e != null; e = e.enclosingElement) {
      if (e is CompilationUnitElement) {
        return e;
      }
      if (e is LibraryElement) {
        return e.definingCompilationUnit;
      }
    }
    throw new StateError(element.toString());
  }
}

/**
 * Information about a single defined name.  Any [_DefinedNameInfo] is always
 * part of a [_UnitIndexAssembler], so [offset] should be understood within the
 * context of the compilation unit pointed to by the [_UnitIndexAssembler].
 */
class _DefinedNameInfo {
  /**
   * The identifier of the name returned [PackageIndexAssembler._getStringId].
   */
  final int nameId;

  /**
   * The coarse-grained kind of the defined name.
   */
  final IndexNameKind kind;

  /**
   * The name offset of the defined element.
   */
  final int offset;

  _DefinedNameInfo(this.nameId, this.kind, this.offset);
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
   * The name offset of the element.
   */
  final int offset;

  /**
   * The kind of the element.
   */
  final IndexSyntheticElementKind kind;

  /**
   * The unique id of the element.  It is set after indexing of the whole
   * package is done and we are assembling the full package index.
   */
  int id;

  _ElementInfo(this.unitId, this.offset, this.kind);
}

/**
 * Information about a single relation.  Any [_ElementRelationInfo] is always
 * part of a [_UnitIndexAssembler], so [offset] and [length] should be
 * understood within the context of the compilation unit pointed to by the
 * [_UnitIndexAssembler].
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
 * Visits a resolved AST and adds relationships into [_UnitIndexAssembler].
 */
class _IndexContributor extends GeneralizingAstVisitor {
  final _UnitIndexAssembler assembler;

  _IndexContributor(this.assembler);

  /**
   * Record definition of the given [element].
   */
  void recordDefinedElement(Element element) {
    if (element != null) {
      String name = element.displayName;
      int offset = element.nameOffset;
      Element enclosing = element.enclosingElement;
      if (enclosing is CompilationUnitElement) {
        assembler.defineName(name, IndexNameKind.topLevel, offset);
      } else if (enclosing is ClassElement) {
        assembler.defineName(name, IndexNameKind.classMember, offset);
      }
    }
  }

  /**
   * Record that the name [node] has a relation of the given [kind].
   */
  void recordNameRelation(SimpleIdentifier node, IndexRelationKind kind) {
    if (node != null) {
      assembler.addNameRelation(node.name, kind, node.offset);
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
    if (element == null ||
        element is FunctionElement &&
            element.enclosingElement is ExecutableElement ||
        element is LabelElement ||
        element is LocalVariableElement ||
        element is ParameterElement &&
            element.parameterKind != ParameterKind.NAMED ||
        element is PrefixElement ||
        element is TypeParameterElement) {
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
      SimpleIdentifier relNode =
          name is PrefixedIdentifier ? name.identifier : name;
      recordRelation(element, kind, relNode, true);
      recordRelation(
          element, IndexRelationKind.IS_REFERENCED_BY, relNode, true);
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
      ClassElement objectElement = node.element.supertype?.element;
      recordRelationOffset(objectElement, IndexRelationKind.IS_EXTENDED_BY,
          node.name.offset, 0, true);
    }
    super.visitClassDeclaration(node);
  }

  @override
  visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    SimpleIdentifier fieldName = node.fieldName;
    if (fieldName != null) {
      Element element = fieldName.staticElement;
      recordRelation(
          element, IndexRelationKind.IS_REFERENCED_BY, fieldName, true);
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
  visitMethodInvocation(MethodInvocation node) {
    SimpleIdentifier name = node.methodName;
    Element element = name.bestElement;
    // qualified unresolved name invocation
    bool isQualified = node.realTarget != null;
    if (isQualified && element == null) {
      recordNameRelation(name, IndexRelationKind.IS_INVOKED_BY);
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
    Element element = node.element;
    recordUriReference(element, node);
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
    Element element = node.bestElement;
    // name in declaration
    if (node.inDeclarationContext()) {
      recordDefinedElement(element);
      return;
    }
    // record qualified unresolved name reference
    bool isQualified = _isQualified(node);
    if (isQualified && element == null) {
      recordNameRelation(node, IndexRelationKind.IS_REFERENCED_BY);
    }
    // this.field parameter
    if (element is FieldFormalParameterElement) {
      recordRelation(
          element.field, IndexRelationKind.IS_REFERENCED_BY, node, true);
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
    super.visitSuperConstructorInvocation(node);
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
}

/**
 * Information about a single name relation.  Any [_NameRelationInfo] is always
 * part of a [_UnitIndexAssembler], so [offset] should be understood within the
 * context of the compilation unit pointed to by the [_UnitIndexAssembler].
 */
class _NameRelationInfo {
  /**
   * The identifier of the name returned [PackageIndexAssembler._getStringId].
   */
  final int nameId;
  final IndexRelationKind kind;
  final int offset;

  _NameRelationInfo(this.nameId, this.kind, this.offset);
}

/**
 * Assembler of a single [CompilationUnit] index.  The intended usage sequence:
 *
 *  - Call [defineName] for each name defined in the compilation unit.
 *  - Call [addElementRelation] for each element relation found in the
 *    compilation unit.
 *  - Call [addNameRelation] for each name relation found in the
 *    compilation unit.
 *  - Assign ids to all the [_ElementInfo] objects reachable from
 *    [elementRelations].
 *  - Call [assemble] to produce the final unit index.
 */
class _UnitIndexAssembler {
  final PackageIndexAssembler pkg;
  final int unitId;
  final List<_DefinedNameInfo> definedNames = <_DefinedNameInfo>[];
  final List<_ElementRelationInfo> elementRelations = <_ElementRelationInfo>[];
  final List<_NameRelationInfo> nameRelations = <_NameRelationInfo>[];

  _UnitIndexAssembler(this.pkg, this.unitId);

  void addElementRelation(Element element, IndexRelationKind kind, int offset,
      int length, bool isQualified) {
    try {
      _ElementInfo elementInfo = pkg._getElementInfo(element);
      elementRelations.add(new _ElementRelationInfo(
          elementInfo, kind, offset, length, isQualified));
    } on StateError {}
  }

  void addNameRelation(String name, IndexRelationKind kind, int offset) {
    int nameId = pkg._getStringId(name);
    nameRelations.add(new _NameRelationInfo(nameId, kind, offset));
  }

  /**
   * Assemble a new [UnitIndexBuilder] using the information gathered
   * by [addElementRelation] and [defineName].
   */
  UnitIndexBuilder assemble() {
    definedNames.sort((a, b) {
      return a.nameId - b.nameId;
    });
    elementRelations.sort((a, b) {
      return a.elementInfo.id - b.elementInfo.id;
    });
    nameRelations.sort((a, b) {
      return a.nameId - b.nameId;
    });
    return new UnitIndexBuilder(
        unit: unitId,
        definedNames: definedNames.map((n) => n.nameId).toList(),
        definedNameKinds: definedNames.map((n) => n.kind).toList(),
        definedNameOffsets: definedNames.map((n) => n.offset).toList(),
        usedElements: elementRelations.map((r) => r.elementInfo.id).toList(),
        usedElementKinds: elementRelations.map((r) => r.kind).toList(),
        usedElementOffsets: elementRelations.map((r) => r.offset).toList(),
        usedElementLengths: elementRelations.map((r) => r.length).toList(),
        usedElementIsQualifiedFlags:
            elementRelations.map((r) => r.isQualified).toList(),
        usedNames: nameRelations.map((r) => r.nameId).toList(),
        usedNameKinds: nameRelations.map((r) => r.kind).toList(),
        usedNameOffsets: nameRelations.map((r) => r.offset).toList());
  }

  void defineName(String name, IndexNameKind kind, int offset) {
    int nameId = pkg._getStringId(name);
    definedNames.add(new _DefinedNameInfo(nameId, kind, offset));
  }
}
