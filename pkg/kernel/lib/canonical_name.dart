// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.canonical_name;

import 'ast.dart';

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
class CanonicalName {
  CanonicalName _parent;

  CanonicalName get parent => _parent;

  final String name;
  CanonicalName _nonRootTop;

  Map<String, CanonicalName> _children;

  /// The library, class, or member bound to this name.
  Reference reference;

  /// Temporary index used during serialization.
  int index = -1;

  CanonicalName._(this._parent, this.name) {
    assert(name != null);
    assert(parent != null);
    _nonRootTop = _parent.isRoot ? this : _parent._nonRootTop;
  }

  CanonicalName.root()
      : _parent = null,
        _nonRootTop = null,
        name = '';

  bool get isRoot => _parent == null;
  CanonicalName get nonRootTop => _nonRootTop;

  Iterable<CanonicalName> get children =>
      _children?.values ?? const <CanonicalName>[];

  bool hasChild(String name) {
    return _children != null && _children.containsKey(name);
  }

  CanonicalName getChild(String name) {
    var map = _children ??= <String, CanonicalName>{};
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
        ? getChildFromUri(name.library.importUri).getChild(name.name)
        : getChild(name.name);
  }

  CanonicalName getChildFromMember(Member member) {
    return getChild(getMemberQualifier(member))
        .getChildFromQualifiedName(member.name);
  }

  CanonicalName getChildFromTypedef(Typedef typedef_) {
    return getChild('@typedefs').getChild(typedef_.name);
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
    if (_children != null && _children.containsKey(child.name)) {
      throw 'Cannot add a child to $this because this name already has a '
          'child named ${child.name}';
    }
    child._parent.removeChild(child.name);
    child._parent = this;
    if (_children == null) _children = <String, CanonicalName>{};
    _children[child.name] = child;
  }

  void removeChild(String name) {
    _children?.remove(name);
  }

  void bindTo(Reference target) {
    if (reference == target) return;
    if (reference != null) {
      throw '$this is already bound';
    }
    if (target.canonicalName != null) {
      throw 'Cannot bind $this to ${target.node}, target is already bound to '
          '${target.canonicalName}';
    }
    target.canonicalName = this;
    this.reference = target;
  }

  void unbind() {
    if (reference == null) return;
    assert(reference.canonicalName == this);
    reference.canonicalName = null;
    reference = null;
  }

  void unbindAll() {
    unbind();
    for (var child in children) {
      child.unbindAll();
    }
  }

  String toString() => _parent == null ? 'root' : '$parent::$name';

  Reference getReference() {
    return reference ??= (new Reference()..canonicalName = this);
  }

  static String getMemberQualifier(Member member) {
    if (member is Procedure) {
      if (member.isGetter) return '@getters';
      if (member.isSetter) return '@setters';
      if (member.isFactory) return '@factories';
      return '@methods';
    }
    if (member is Field) {
      return '@fields';
    }
    if (member is Constructor) {
      return '@constructors';
    }
    if (member is RedirectingFactoryConstructor) {
      return '@factories';
    }
    throw 'Unexpected member: $member';
  }
}
