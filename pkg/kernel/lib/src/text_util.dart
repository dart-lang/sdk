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

String nameToString(Name node, {bool includeLibraryName: false}) {
  if (node == null) {
    return 'null';
  } else if (node.library != null && includeLibraryName) {
    return '${libraryNameToString(node.library)}::${node.text}';
  } else {
    return node.text;
  }
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

String qualifiedCanonicalNameToString(CanonicalName canonicalName,
    {bool includeLibraryName: false}) {
  if (canonicalName.isRoot) {
    return '<root>';
  } else if (canonicalName.parent.isRoot) {
    return canonicalName.name;
  } else if (canonicalName.parent.parent.isRoot) {
    if (!includeLibraryName) {
      return canonicalName.name;
    }
    String parentName = qualifiedCanonicalNameToString(canonicalName.parent,
        includeLibraryName: includeLibraryName);
    return '$parentName::${canonicalName.name}';
  } else {
    String parentName = qualifiedCanonicalNameToString(canonicalName.parent,
        includeLibraryName: includeLibraryName);
    return '$parentName.${canonicalName.name}';
  }
}

String qualifiedClassNameToStringByReference(Reference reference,
    {bool includeLibraryName: false}) {
  if (reference == null) {
    return '<missing-class-reference>';
  } else {
    Class node = reference.node;
    if (node != null) {
      return qualifiedClassNameToString(node,
          includeLibraryName: includeLibraryName);
    } else {
      CanonicalName canonicalName = reference.canonicalName;
      if (canonicalName != null) {
        return qualifiedCanonicalNameToString(canonicalName,
            includeLibraryName: includeLibraryName);
      } else {
        return '<unlinked-class-reference>';
      }
    }
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

String qualifiedExtensionNameToStringByReference(Reference reference,
    {bool includeLibraryName: false}) {
  if (reference == null) {
    return '<missing-extension-reference>';
  } else {
    Extension node = reference.node;
    if (node != null) {
      return qualifiedExtensionNameToString(node,
          includeLibraryName: includeLibraryName);
    } else {
      CanonicalName canonicalName = reference.canonicalName;
      if (canonicalName != null) {
        return qualifiedCanonicalNameToString(canonicalName,
            includeLibraryName: includeLibraryName);
      } else {
        return '<unlinked-extension-reference>';
      }
    }
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

String qualifiedTypedefNameToStringByReference(Reference reference,
    {bool includeLibraryName: false}) {
  if (reference == null) {
    return '<missing-typedef-reference>';
  } else {
    Typedef node = reference.node;
    if (node != null) {
      return qualifiedTypedefNameToString(node,
          includeLibraryName: includeLibraryName);
    } else {
      CanonicalName canonicalName = reference.canonicalName;
      if (canonicalName != null) {
        return qualifiedCanonicalNameToString(canonicalName,
            includeLibraryName: includeLibraryName);
      } else {
        return '<unlinked-typedef-reference>';
      }
    }
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
        '.' +
        memberNameToString(node);
  } else if (includeLibraryName) {
    return libraryNameToString(node.enclosingLibrary) +
        '::' +
        memberNameToString(node);
  } else {
    return memberNameToString(node);
  }
}

String qualifiedMemberNameToStringByReference(Reference reference,
    {bool includeLibraryName: false}) {
  if (reference == null) {
    return '<missing-member-reference>';
  } else {
    Member node = reference.node;
    if (node != null) {
      return qualifiedMemberNameToString(node,
          includeLibraryName: includeLibraryName);
    } else {
      CanonicalName canonicalName = reference.canonicalName;
      if (canonicalName != null) {
        return qualifiedCanonicalNameToString(canonicalName,
            includeLibraryName: includeLibraryName);
      } else {
        return '<unlinked-member-reference>';
      }
    }
  }
}

String memberNameToString(Member node) {
  return node.name?.text ??
      "null-named member ${node.runtimeType} ${node.hashCode}";
}

String qualifiedTypeParameterNameToString(TypeParameter node,
    {bool includeLibraryName: false}) {
  TreeNode parent = node.parent;
  if (parent is Class) {
    return qualifiedClassNameToString(parent,
            includeLibraryName: includeLibraryName) +
        '.' +
        typeParameterNameToString(node);
  } else if (parent is Extension) {
    return qualifiedExtensionNameToString(parent,
            includeLibraryName: includeLibraryName) +
        '.' +
        typeParameterNameToString(node);
  } else if (parent is Member) {
    return qualifiedMemberNameToString(parent,
            includeLibraryName: includeLibraryName) +
        '.' +
        typeParameterNameToString(node);
  }
  return typeParameterNameToString(node);
}

String typeParameterNameToString(TypeParameter node) {
  return node.name ??
      "null-named TypeParameter ${node.runtimeType} ${node.hashCode}";
}

String getEscapedCharacter(int codeUnit) {
  switch (codeUnit) {
    case 9:
      return r'\t';
    case 10:
      return r'\n';
    case 11:
      return r'\v';
    case 12:
      return r'\f';
    case 13:
      return r'\r';
    case 34:
      return r'\"';
    case 36:
      return r'\$';
    case 92:
      return r'\\';
    default:
      if (codeUnit < 32 || codeUnit > 126) {
        return r'\u' + '$codeUnit'.padLeft(4, '0');
      } else {
        return null;
      }
  }
}

String escapeString(String string) {
  StringBuffer buffer;
  for (int i = 0; i < string.length; ++i) {
    String character = getEscapedCharacter(string.codeUnitAt(i));
    if (character != null) {
      buffer ??= new StringBuffer(string.substring(0, i));
      buffer.write(character);
    } else {
      buffer?.write(string[i]);
    }
  }
  return buffer == null ? string : buffer.toString();
}
