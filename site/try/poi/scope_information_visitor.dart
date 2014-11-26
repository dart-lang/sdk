// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trydart.poi.scope_information_visitor;

import 'package:compiler/src/elements/modelx.dart' as modelx;

import 'package:compiler/src/elements/modelx.dart' show
    CompilationUnitElementX,
    FieldElementX;

import 'package:compiler/src/elements/visitor.dart' show
    ElementVisitor;

import 'package:compiler/src/dart2jslib.dart' show
    Compiler;

import 'package:compiler/src/elements/elements.dart' show
    AbstractFieldElement,
    ClassElement,
    CompilationUnitElement,
    Element,
    ElementCategory,
    FunctionElement,
    LibraryElement,
    ScopeContainerElement;

import 'package:compiler/src/dart_types.dart' show
    DartType;

/**
 * Serializes scope information about an element. This is accomplished by
 * calling the [serialize] method on each element. Some elements need special
 * treatment, as their enclosing scope must also be serialized.
 */
class ScopeInformationVisitor extends ElementVisitor/* <void> */ {
  // TODO(ahe): Include function parameters and local variables.

  final Compiler compiler;
  final Element currentElement;
  final int position;
  final StringBuffer buffer = new StringBuffer();
  int indentationLevel = 0;
  ClassElement currentClass;

  bool sortMembers = false;

  bool ignoreImports = false;

  ScopeInformationVisitor(this.compiler, this.currentElement, this.position);

  String get indentation => '  ' * indentationLevel;

  StringBuffer get indented => buffer..write(indentation);

  void visitElement(Element e) {
    serialize(e, omitEnclosing: false);
  }

  void visitLibraryElement(LibraryElement e) {
    bool isFirst = true;
    forEach(Element member) {
      if (!isFirst) {
        buffer.write(',');
      }
      buffer.write('\n');
      indented;
      serialize(member);
      isFirst = false;
    }
    serialize(
        e,
        // TODO(ahe): We omit the import scope if there is no current
        // class. That's wrong.
        omitEnclosing: ignoreImports || currentClass == null,
        name: e.getLibraryName(),
        serializeEnclosing: () {
          // The enclosing scope of a library is a scope which contains all the
          // imported names.
          isFirst = true;
          buffer.write('{\n');
          indentationLevel++;
          indented.write('"kind": "imports",\n');
          indented.write('"members": [');
          indentationLevel++;
          sortElements(importScope(e).importScope.values).forEach(forEach);
          indentationLevel--;
          buffer.write('\n');
          indented.write('],\n');
          // The enclosing scope of the imported names scope is the superclass
          // scope of the current class.
          indented.write('"enclosing": ');
          serializeClassSide(
              currentClass.superclass, isStatic: false, includeSuper: true);
          buffer.write('\n');
          indentationLevel--;
          indented.write('}');
        },
        serializeMembers: () {
          isFirst = true;
          sortElements(localScope(e).values).forEach(forEach);
        });
  }

  void visitClassElement(ClassElement e) {
    currentClass = e;
    serializeClassSide(e, isStatic: true);
  }

  /// Serializes one of the "sides" a class. The sides of a class are "instance
  /// side" and "class side". These terms are from Smalltalk. The instance side
  /// is all the local instance members of the class (the members of the
  /// mixin), and the class side is the equivalent for static members and
  /// constructors.
  /// The scope chain is ordered so that the "class side" is searched before
  /// the "instance side".
  void serializeClassSide(
      ClassElement e,
      {bool isStatic: false,
       bool omitEnclosing: false,
       bool includeSuper: false}) {
    e.ensureResolved(compiler);
    bool isFirst = true;
    var serializeEnclosing;
    String kind;
    if (isStatic) {
      kind = 'class side';
      serializeEnclosing = () {
        serializeClassSide(e, isStatic: false, omitEnclosing: omitEnclosing);
      };
    } else {
      kind = 'instance side';
    }
    if (includeSuper) {
      assert(!omitEnclosing && !isStatic);
      if (e.superclass == null) {
        omitEnclosing = true;
      } else {
        // Members of the superclass are represented as a separate scope.
        serializeEnclosing = () {
          serializeClassSide(
              e.superclass, isStatic: false, omitEnclosing: false,
              includeSuper: true);
        };
      }
    }
    serialize(
        e, omitEnclosing: omitEnclosing, serializeEnclosing: serializeEnclosing,
        kind: kind, serializeMembers: () {
      localMembersSorted(e).forEach((Element member) {
        // Filter out members that don't belong to this "side".
        if (member.isConstructor) {
          // In dart2js, some constructors aren't static, but that isn't
          // convenient here.
          if (!isStatic) return;
        } else if (member.isStatic != isStatic) {
          return;
        }
        if (!isFirst) {
          buffer.write(',');
        }
        buffer.write('\n');
        indented;
        serialize(member);
        isFirst = false;
      });
    });
  }

  void visitScopeContainerElement(ScopeContainerElement e) {
    bool isFirst = true;
    serialize(e, omitEnclosing: false, serializeMembers: () {
      localMembersSorted(e).forEach((Element member) {
        if (!isFirst) {
          buffer.write(',');
        }
        buffer.write('\n');
        indented;
        serialize(member);
        isFirst = false;
      });
    });
  }

  void visitCompilationUnitElement(CompilationUnitElement e) {
    e.enclosingElement.accept(this);
  }

  void visitAbstractFieldElement(AbstractFieldElement e) {
    throw new UnsupportedError('AbstractFieldElement cannot be serialized.');
  }

  void serialize(
      Element element,
      {bool omitEnclosing: true,
       void serializeMembers(),
       void serializeEnclosing(),
       String kind,
       String name}) {
    if (element.isAbstractField) {
      AbstractFieldElement field = element;
      FunctionElement getter = field.getter;
      FunctionElement setter = field.setter;
      if (getter != null) {
        serialize(
            getter,
            omitEnclosing: omitEnclosing,
            serializeMembers: serializeMembers,
            serializeEnclosing: serializeEnclosing,
            kind: kind,
            name: name);
      }
      if (setter != null) {
        if (getter != null) {
          buffer.write(',\n');
          indented;
        }
        serialize(
            getter,
            omitEnclosing: omitEnclosing,
            serializeMembers: serializeMembers,
            serializeEnclosing: serializeEnclosing,
            kind: kind,
            name: name);
      }
      return;
    }
    DartType type;
    int category = element.kind.category;
    if (category == ElementCategory.FUNCTION ||
        category == ElementCategory.VARIABLE ||
        element.isConstructor) {
      type = element.computeType(compiler);
    }
    if (name == null) {
      name = element.name;
    }
    if (kind == null) {
      kind = '${element.kind}';
    }
    buffer.write('{\n');
    indentationLevel++;
    if (name != '') {
      indented
          ..write('"name": "')
          ..write(name)
          ..write('",\n');
    }
    indented
        ..write('"kind": "')
        ..write(kind)
        ..write('"');
    if (type != null) {
      buffer.write(',\n');
      indented
          ..write('"type": "')
          ..write(type)
          ..write('"');
    }
    if (serializeMembers != null) {
      buffer.write(',\n');
      indented.write('"members": [');
      indentationLevel++;
      serializeMembers();
      indentationLevel--;
      buffer.write('\n');
      indented.write(']');
    }
    if (!omitEnclosing) {
      buffer.write(',\n');
      indented.write('"enclosing": ');
      if (serializeEnclosing != null) {
        serializeEnclosing();
      } else {
        element.enclosingElement.accept(this);
      }
    }
    indentationLevel--;
    buffer.write('\n');
    indented.write('}');
  }

  List<Element> localMembersSorted(ScopeContainerElement element) {
    List<Element> result = <Element>[];
    element.forEachLocalMember((Element member) {
      result.add(member);
    });
    return sortElements(result);
  }

  List<Element> sortElements(Iterable<Element> elements) {
    List<Element> result = new List<Element>.from(elements);
    if (sortMembers) {
      result.sort((Element a, Element b) => a.name.compareTo(b.name));
    }
    return result;
  }
}

modelx.ScopeX localScope(modelx.LibraryElementX element) => element.localScope;

modelx.ImportScope importScope(modelx.LibraryElementX element) {
  return element.importScope;
}
