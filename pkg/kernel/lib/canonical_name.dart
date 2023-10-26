// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.canonical_name;

import 'ast.dart';
import 'src/printer.dart' show AstPrinter, AstTextStrategy;

/// A string sequence that identifies a library, class, or member.
///
/// Canonical names are organized in a prefix tree.  Each node knows its
/// parent, children, and the AST node it is currently bound to.
///
/// The following schema specifies how the canonical name of a given object
/// is defined:
///
///      Library:
///         URI of library
///
///      Class:
///         Canonical name of enclosing library
///         Name of class
///
///      Extension:
///         Canonical name of enclosing library
///         Name of extension
///
///      Constructor:
///         Canonical name of enclosing class or library
///         "@constructors"
///         Qualified name
///
///      Field:
///         Canonical name of enclosing class or library
///         "@fields"
///         Qualified name
///
///      Implicit getter of a field:
///         Canonical name of enclosing class or library
///         "@getters"
///         Qualified name
///
///      Implicit setter of a field:
///         Canonical name of enclosing class or library
///         "@setters"
///         Qualified name
///
///      Typedef:
///         Canonical name of enclosing class
///         "@typedefs"
///         Name text
///
///      Procedure that is not an accessor or factory:
///         Canonical name of enclosing class or library
///         "@methods"
///         Qualified name
///
///      Procedure that is a getter:
///         Canonical name of enclosing class or library
///         "@getters"
///         Qualified name
///
///      Procedure that is a setter:
///         Canonical name of enclosing class or library
///         "@setters"
///         Qualified name
///
///      Procedure that is a factory:
///         Canonical name of enclosing class
///         "@factories"
///         Qualified name
///
///      Qualified name:
///         if private: URI of library
///         Name text
///
/// The "qualified name" allows a member to have a name that is private to
/// a library other than the one containing that member.
class CanonicalName implements Comparable<CanonicalName?> {
  CanonicalName? _parent;

  CanonicalName? get parent => _parent;

  final String name;
  CanonicalName? _nonRootTop;

  Map<String, CanonicalName>? _children;

  /// The library, class, or member bound to this name.
  Reference? _reference;

  /// Temporary index used during serialization.
  int index = -1;

  CanonicalName._(CanonicalName parent, this.name) : _parent = parent {
    _nonRootTop = parent.isRoot ? this : parent._nonRootTop;
  }

  CanonicalName.root()
      : _parent = null,
        _nonRootTop = null,
        name = '';

  bool get isRoot => _parent == null;

  CanonicalName? get nonRootTop => _nonRootTop;

  Iterable<CanonicalName> get children =>
      _children?.values ?? const <CanonicalName>[];

  Iterable<CanonicalName>? get childrenOrNull => _children?.values;

  bool hasChild(String name) {
    return _children != null && _children!.containsKey(name);
  }

  CanonicalName getChild(String name) {
    Map<String, CanonicalName> map = _children ??= <String, CanonicalName>{};
    return map[name] ??= new CanonicalName._(this, name);
  }

  CanonicalName getChildFromUri(Uri uri) {
    // Note that the Uri class caches its string representation, and all library
    // URIs will be stringified for serialization anyway, so there is no
    // significant cost for converting the Uri to a string here.
    return getChild('$uri');
  }

  CanonicalName getChildFromQualifiedName(Name name) {
    return name.isPrivate
        ? getChildFromUri(name.library!.importUri).getChild(name.text)
        : getChild(name.text);
  }

  CanonicalName getChildFromProcedure(Procedure procedure) {
    return getChild(getProcedureQualifier(procedure))
        .getChildFromQualifiedName(procedure.name);
  }

  CanonicalName getChildFromField(Field field) {
    return getChild(fieldsName).getChildFromQualifiedName(field.name);
  }

  CanonicalName getChildFromFieldGetter(Field field) {
    return getChild(gettersName).getChildFromQualifiedName(field.name);
  }

  CanonicalName getChildFromFieldSetter(Field field) {
    return getChild(settersName).getChildFromQualifiedName(field.name);
  }

  CanonicalName getChildFromConstructor(Constructor constructor) {
    return getChild(constructorsName)
        .getChildFromQualifiedName(constructor.name);
  }

  CanonicalName getChildFromFieldWithName(Name name) {
    return getChild(fieldsName).getChildFromQualifiedName(name);
  }

  CanonicalName getChildFromFieldGetterWithName(Name name) {
    return getChild(gettersName).getChildFromQualifiedName(name);
  }

  CanonicalName getChildFromFieldSetterWithName(Name name) {
    return getChild(settersName).getChildFromQualifiedName(name);
  }

  CanonicalName getChildFromTypedef(Typedef typedef_) {
    return getChild(typedefsName).getChild(typedef_.name);
  }

  /// Take ownership of a child canonical name and its subtree.
  ///
  /// The child name is removed as a child of its current parent and this name
  /// becomes the new parent.  Note that this moves the entire subtree rooted at
  /// the child.
  ///
  /// This method can be used to move subtrees within a canonical name tree or
  /// else move them between trees.  It is safe to call this method if the child
  /// name is already a child of this name.
  ///
  /// The precondition is that this name cannot have a (different) child with
  /// the same name.
  void adoptChild(CanonicalName child) {
    if (child._parent == this) return;
    if (_children != null && _children!.containsKey(child.name)) {
      throw 'Cannot add a child to $this because this name already has a '
          'child named ${child.name}';
    }
    child._parent?.removeChild(child.name);
    child._parent = this;
    _children ??= <String, CanonicalName>{};
    _children![child.name] = child;
  }

  void removeChild(String name) {
    if (_children != null) {
      _children!.remove(name);
      if (_children!.isEmpty) {
        _children = null;
      }
    }
  }

  void bindTo(Reference target) {
    if (_reference == target) return;
    if (_reference != null) {
      StringBuffer sb = new StringBuffer();
      sb.write('$this is already bound to ${_reference}');
      if (_reference?._node != null) {
        sb.write(' with node ${_reference?._node}'
            ' (${_reference?._node.runtimeType}'
            ':${_reference?._node.hashCode})');
      }
      sb.write(', trying to bind to ${target}');
      if (target._node != null) {
        sb.write(' with node ${target._node}'
            ' (${target._node.runtimeType}'
            ':${target._node.hashCode})');
      }
      throw sb.toString();
    }
    if (target.canonicalName != null) {
      throw 'Cannot bind $this to ${target.node}, target is already bound to '
          '${target.canonicalName}';
    }
    target.canonicalName = this;
    this._reference = target;
  }

  void unbind() {
    _unbindInternal();
    // TODO(johnniwinther): To support replacement of fields with getters and
    // setters (and the reverse) we need to remove canonical names from the
    // canonical name tree. We need to establish better invariants about the
    // state of the canonical name tree, since for instance [unbindAll] doesn't
    // remove unneeded leaf nodes.
    _parent?.removeChild(name);
  }

  void _unbindInternal() {
    if (_reference == null) return;
    assert(_reference!.canonicalName == this);
    if (_reference!.node is Class) {
      // TODO(jensj): Get rid of this. This is only needed because pkg:vm does
      // weird stuff in transformations. `unbind` should probably be private.
      Class c = _reference!.asClass;
      c.ensureLoaded();
    }
    _reference!.canonicalName = null;
    _reference = null;
  }

  void unbindAll() {
    _unbindInternal();
    Iterable<CanonicalName>? children_ = childrenOrNull;
    if (children_ != null) {
      for (CanonicalName child in children_) {
        child.unbindAll();
      }
    }
  }

  @override
  String toString() => _parent == null ? 'root' : '$parent::$name';
  String toStringInternal() {
    if (isRoot) return "";
    if (parent!.isRoot) return "$name";
    return "${parent!.toStringInternal()}::$name";
  }

  String toText(AstTextStrategy strategy) {
    AstPrinter printer = new AstPrinter(strategy);
    toTextInternal(printer);
    return printer.getText();
  }

  void toTextInternal(AstPrinter printer) {
    printer.writeQualifiedCanonicalNameToString(this);
  }

  Reference get reference {
    return _reference ??= (new Reference()..canonicalName = this);
  }

  void checkCanonicalNameChildren() {
    CanonicalName parent = this;
    Iterable<CanonicalName>? parentChildren = parent.childrenOrNull;
    if (parentChildren != null) {
      for (CanonicalName child in parentChildren) {
        if (!isSymbolicName(child.name)) {
          bool checkReferenceNode = true;
          if (child._reference == null) {
            // OK for "if private: URI of library" part of "Qualified name"...
            // TODO(johnniwinther): This wrongfully skips checking of variable
            // synthesized by the VM transformations. The kind of canonical
            // name types maybe should be directly available.
            if (parent.parent != null && child.name.contains(':')) {
              // OK then.
              checkReferenceNode = false;
            } else {
              throw buildCanonicalNameError(
                  "Null reference (${child.name}) ($child).", child);
            }
          }
          if (checkReferenceNode) {
            if (child._reference!.canonicalName != child) {
              throw buildCanonicalNameError(
                  "Canonical name and reference doesn't agree.", child);
            }
            if (child._reference!.node == null) {
              throw buildCanonicalNameError(
                  "Reference is null (${child.name}) ($child).", child);
            }
          }
        }
        child.checkCanonicalNameChildren();
      }
    }
  }

  bool get isConsistent {
    if (_reference != null && !_reference!.isConsistent) {
      return false;
    }
    return true;
  }

  String getInconsistency() {
    StringBuffer sb = new StringBuffer();
    sb.write('CanonicalName ${this} (${hashCode}):');
    if (_reference != null) {
      sb.write(' ${_reference!.getInconsistency()}');
    }
    return sb.toString();
  }

  /// Symbolic name used for the [CanonicalName] node that holds all
  /// constructors within a class.
  static const String constructorsName = '@constructors';

  /// Symbolic name used for the [CanonicalName] node that holds all factories
  /// within a class.
  static const String factoriesName = '@factories';

  /// Symbolic name used for the [CanonicalName] node that holds all methods
  /// within a library or a class.
  static const String methodsName = '@methods';

  /// Symbolic name used for the [CanonicalName] node that holds all fields
  /// within a library or class.
  static const String fieldsName = '@fields';

  /// Symbolic name used for the [CanonicalName] node that holds all getters and
  /// readable fields within a library or class.
  static const String gettersName = '@getters';

  /// Symbolic name used for the [CanonicalName] node that holds all setters and
  /// writable fields within a library or class.
  static const String settersName = '@setters';

  /// Symbolic name used for the [CanonicalName] node that holds all typedefs
  /// within a library.
  static const String typedefsName = '@typedefs';

  static const Set<String> symbolicNames = {
    constructorsName,
    factoriesName,
    methodsName,
    fieldsName,
    gettersName,
    settersName,
    typedefsName,
  };

  static bool isSymbolicName(String name) => symbolicNames.contains(name);

  static String getProcedureQualifier(Procedure procedure) {
    if (procedure.isGetter) return gettersName;
    if (procedure.isSetter) return settersName;
    if (procedure.isFactory) return factoriesName;
    return methodsName;
  }

  /// Returns `true` if [node] is orphaned through its [reference].
  ///
  /// A [NamedNode] is orphaned if the canonical name of its reference doesn't
  /// point back to the node itself. This can occur if the [reference] is
  /// repurposed for a new [NamedNode]. In this case, the reference will be
  /// updated to point the new node.
  ///
  /// This method assumes that `reference.canonicalName` is this canonical name.
  bool isOrphaned(NamedNode node, Reference reference) {
    assert(reference.canonicalName == this);
    return _reference?._node != node;
  }

  /// Returns a description of the orphancy, if [node] is orphaned through its
  /// [reference]. Otherwise `null`.
  ///
  /// A [NamedNode] is orphaned if the canonical name of its reference doesn't
  /// point back to the node itself. This can occur if the [reference] is
  /// repurposed for a new [NamedNode]. In this case, the reference will be
  /// updated to point the new node.
  ///
  /// This method assumes that `reference.canonicalName` is this canonical name.
  String? getOrphancyDescription(NamedNode node, Reference reference) {
    assert(reference.canonicalName == this);
    if (_reference?._node != node) {
      return _reference!.getOrphancyDescription(node);
    }
    return null;
  }

  @override
  int compareTo(CanonicalName? other) {
    if (identical(this, other)) return 0;
    if (other == null) return -1;
    int result = name.compareTo(other.name);
    if (result != 0) return result;
    if (parent == null) {
      if (other.parent == null) return 0;
      return -1;
    }
    return parent!.compareTo(other.parent);
  }
}

/// Indirection between a reference and its definition.
///
/// There is only one reference object per [NamedNode].
class Reference implements Comparable<Reference> {
  CanonicalName? canonicalName;

  NamedNode? _node;

  NamedNode? get node {
    return _node ?? _tryLoadNode();
  }

  /// If the node belongs to a lazy-loaded class load the class.
  ///
  /// Should only be called if [_node] is null, meaning that either this
  /// is an unbound reference or it belongs to a lazy-loaded
  /// (and not yet loaded) class. If it belongs to a lazy-loaded class this call
  /// will load the class and set [_node].
  NamedNode? _tryLoadNode() {
    CanonicalName? canonicalNameParent = canonicalName?.parent;
    while (canonicalNameParent != null) {
      if (canonicalNameParent.name.startsWith("@")) {
        break;
      }
      canonicalNameParent = canonicalNameParent.parent;
    }
    if (canonicalNameParent != null) {
      NamedNode? parentNamedNode = canonicalNameParent.parent?.reference._node;
      if (parentNamedNode is Class) {
        Class parentClass = parentNamedNode;
        if (parentClass.lazyBuilder != null) {
          parentClass.ensureLoaded();
        }
      }
    }
    return _node;
  }

  void set node(NamedNode? node) {
    _node = node;
  }

  @override
  String toString() {
    return "Reference to ${toStringInternal()}";
  }

  String toText(AstTextStrategy strategy) {
    AstPrinter printer = new AstPrinter(strategy);
    toTextInternal(printer);
    return printer.getText();
  }

  void toTextInternal(AstPrinter printer) {
    if (node != null) {
      return node!.toTextInternal(printer);
    }
    if (canonicalName != null) {
      return canonicalName!.toTextInternal(printer);
    }
  }

  String toStringInternal() {
    if (canonicalName != null) {
      return '${canonicalName!.toStringInternal()}';
    }
    if (node != null) {
      return node!.toStringInternal();
    }
    return 'Unbound reference';
  }

  Library get asLibrary {
    NamedNode? node = this.node;
    if (node == null) {
      throw '$this is not bound to an AST node. A library was expected';
    }
    return node as Library;
  }

  TypeDeclaration get asTypeDeclaration {
    NamedNode? node = this.node;
    if (node == null) {
      throw '$this is not bound to an AST node. '
          'A type declaration was expected';
    }
    return node as TypeDeclaration;
  }

  Class get asClass {
    NamedNode? node = this.node;
    if (node == null) {
      throw '$this is not bound to an AST node. A class was expected';
    }
    return node as Class;
  }

  Member get asMember {
    NamedNode? node = this.node;
    if (node == null) {
      throw '$this is not bound to an AST node. A member was expected';
    }
    return node as Member;
  }

  Field get asField {
    NamedNode? node = this.node;
    if (node == null) {
      throw '$this is not bound to an AST node. A field was expected';
    }
    return node as Field;
  }

  Constructor get asConstructor {
    NamedNode? node = this.node;
    if (node == null) {
      throw '$this is not bound to an AST node. A constructor was expected';
    }
    return node as Constructor;
  }

  Procedure get asProcedure {
    NamedNode? node = this.node;
    if (node == null) {
      throw '$this is not bound to an AST node. A procedure was expected';
    }
    return node as Procedure;
  }

  Typedef get asTypedef {
    NamedNode? node = this.node;
    if (node == null) {
      throw '$this is not bound to an AST node. A typedef was expected';
    }
    return node as Typedef;
  }

  Extension get asExtension {
    NamedNode? node = this.node;
    if (node == null) {
      throw '$this is not bound to an AST node. An extension was expected';
    }
    return node as Extension;
  }

  ExtensionTypeDeclaration get asExtensionTypeDeclaration {
    NamedNode? node = this.node;
    if (node == null) {
      throw '$this is not bound to an AST node. An extension type declaration '
          'was expected';
    }
    return node as ExtensionTypeDeclaration;
  }

  bool get isConsistent {
    NamedNode? node = _node;
    if (node != null) {
      if (node is Field) {
        // The field, getter or setter reference of the [Field] must point to
        // this reference.
        return node.fieldReference == this ||
            node.getterReference == this ||
            node.setterReference == this;
      } else {
        // The reference of the [NamedNode] must point to this reference.
        return node.reference == this;
      }
    }
    if (canonicalName != null && canonicalName!._reference != this) {
      return false;
    }
    return true;
  }

  String getInconsistency() {
    StringBuffer sb = new StringBuffer();
    sb.write('Reference ${toStringInternal()} (${hashCode}):');
    NamedNode? node = _node;
    if (node != null) {
      if (node is Field) {
        if (node.fieldReference != this &&
            node.getterReference != this &&
            node.setterReference != this) {
          sb.write(' _node=${node} (${node.runtimeType}:${node.hashCode})');
          sb.write(' _node.fieldReference='
              '${node.fieldReference} (${node.fieldReference.hashCode})');
          sb.write(' _node.getterReference='
              '${node.getterReference} (${node.getterReference.hashCode})');
          sb.write(' _node.setterReference='
              '${node.setterReference} (${node.setterReference.hashCode})');
        }
      } else {
        if (node.reference != this) {
          sb.write(' _node=${node} (${node.runtimeType}:${node.hashCode})');
          sb.write(' _node.reference='
              '${node.reference} (${node.reference.hashCode})');
        }
      }
    }
    if (canonicalName != null && canonicalName!._reference != this) {
      sb.write(' canonicalName=${canonicalName} (${canonicalName.hashCode})');
      sb.write(' canonicalName.reference='
          '${canonicalName!._reference} '
          '(${canonicalName!._reference.hashCode})');
    }
    return sb.toString();
  }

  /// Returns `true` if [node] is orphaned through this reference.
  ///
  /// A [NamedNode] is orphaned if its reference doesn't point back to the node
  /// itself. This can occur if the [reference] is repurposed for a new
  /// [NamedNode]. In this case, the reference will be updated to point the new
  /// node.
  ///
  /// This method assumes that this reference is the reference, possibly
  /// getter or setter reference for a field, of [node].
  bool isOrphaned(NamedNode node) {
    return _node != node;
  }

  /// Returns a description of the orphancy, if [node] is orphaned through this
  /// reference. Otherwise `null`.
  ///
  /// A [NamedNode] is orphaned if its reference doesn't point back to the node
  /// itself. This can occur if the [reference] is repurposed for a new
  /// [NamedNode]. In this case, the reference will be updated to point the new
  /// node.
  ///
  /// This method assumes that this reference is the reference, possibly
  /// getter or setter reference for a field, of [node].
  String? getOrphancyDescription(NamedNode node) {
    if (_node != node) {
      StringBuffer sb = new StringBuffer();
      sb.write('Orphaned named node ${node} ');
      sb.write('(${node.runtimeType}:${node.hashCode})\n');
      sb.write('Linked node ${_node} ');
      sb.write('(${_node.runtimeType}:');
      sb.write('${_node.hashCode})');
      return sb.toString();
    }
    return null;
  }

  @override
  int compareTo(Reference other) {
    final CanonicalName? thisCanonicalName = canonicalName;
    final CanonicalName? otherCanonicalName = other.canonicalName;
    if (thisCanonicalName == null && otherCanonicalName == null) return 0;
    if (thisCanonicalName == null) return -1;
    if (otherCanonicalName == null) return 1;
    return thisCanonicalName.compareTo(otherCanonicalName);
  }
}

class CanonicalNameError {
  final String message;

  CanonicalNameError(this.message);

  @override
  String toString() => 'CanonicalNameError: $message';
}

class CanonicalNameSdkError extends CanonicalNameError {
  CanonicalNameSdkError(String message) : super(message);

  @override
  String toString() => 'CanonicalNameSdkError: $message';
}

CanonicalNameError buildCanonicalNameError(
    String message, CanonicalName problemNode) {
  // Special-case missing sdk entries as that is probably a change to the
  // platform - that's something we might want to react differently to.
  String libraryUri = problemNode.nonRootTop?.name ?? "";
  if (libraryUri.startsWith("dart:")) {
    return new CanonicalNameSdkError(message);
  }
  return new CanonicalNameError(message);
}
