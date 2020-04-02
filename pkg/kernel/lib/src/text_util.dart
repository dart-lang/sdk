// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ast.dart';

String nullabilityToString(Nullability nullability) {
  switch (nullability) {
    case Nullability.legacy:
      return '*';
    case Nullability.nullable:
      return '?';
    case Nullability.undetermined:
      return '%';
    case Nullability.nonNullable:
      return '';
  }
  throw "Unknown Nullability: $nullability";
}

String libraryNameToString(Library node) {
  return node == null ? 'null' : node.name ?? 'library ${node.importUri}';
}

String qualifiedClassNameToString(Class node,
    {bool includeLibraryName: false}) {
  if (includeLibraryName) {
    return libraryNameToString(node.enclosingLibrary) +
        '::' +
        classNameToString(node);
  } else {
    return classNameToString(node);
  }
}

String classNameToString(Class node) {
  return node == null
      ? 'null'
      : node.name ?? 'null-named class ${node.runtimeType} ${node.hashCode}';
}

String qualifiedExtensionNameToString(Extension node,
    {bool includeLibraryName: false}) {
  if (includeLibraryName) {
    return libraryNameToString(node.enclosingLibrary) +
        '::' +
        extensionNameToString(node);
  } else {
    return extensionNameToString(node);
  }
}

String extensionNameToString(Extension node) {
  return node == null
      ? 'null'
      : node.name ??
          'null-named extension ${node.runtimeType} ${node.hashCode}';
}

String qualifiedTypedefNameToString(Typedef node,
    {bool includeLibraryName: false}) {
  if (includeLibraryName) {
    return libraryNameToString(node.enclosingLibrary) +
        '::' +
        typedefNameToString(node);
  } else {
    return typedefNameToString(node);
  }
}

String typedefNameToString(Typedef node) {
  return node == null
      ? 'null'
      : node.name ?? 'null-named typedef ${node.runtimeType} ${node.hashCode}';
}

String qualifiedMemberNameToString(Member node,
    {bool includeLibraryName: false}) {
  if (node.enclosingClass != null) {
    return qualifiedClassNameToString(node.enclosingClass,
            includeLibraryName: includeLibraryName) +
        '::' +
        memberNameToString(node);
  } else if (includeLibraryName) {
    return libraryNameToString(node.enclosingLibrary) +
        '::' +
        memberNameToString(node);
  } else {
    return memberNameToString(node);
  }
}

String memberNameToString(Member node) {
  return node.name?.name ??
      "null-named member ${node.runtimeType} ${node.hashCode}";
}

String qualifiedTypeParameterNameToString(TypeParameter node,
    {bool includeLibraryName: false}) {
  TreeNode parent = node.parent;
  if (parent is Class) {
    return qualifiedClassNameToString(parent,
            includeLibraryName: includeLibraryName) +
        '::' +
        typeParameterNameToString(node);
  } else if (parent is Extension) {
    return qualifiedExtensionNameToString(parent,
            includeLibraryName: includeLibraryName) +
        '::' +
        typeParameterNameToString(node);
  } else if (parent is Member) {
    return qualifiedMemberNameToString(parent,
            includeLibraryName: includeLibraryName) +
        '::' +
        typeParameterNameToString(node);
  }
  return typeParameterNameToString(node);
}

String typeParameterNameToString(TypeParameter node) {
  return node.name ??
      "null-named TypeParameter ${node.runtimeType} ${node.hashCode}";
}
