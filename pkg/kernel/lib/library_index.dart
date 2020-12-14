// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.library_index;

import 'ast.dart';

/// Provides name-based access to library, class, and member AST nodes.
///
/// When constructed, a given set of libraries are indexed immediately, and
/// will not be up-to-date with changes made after it was created.
class LibraryIndex {
  static const String getterPrefix = 'get:';
  static const String setterPrefix = 'set:';
  static const String tearoffPrefix = 'get#';

  /// A special class name that can be used to access the top-level members
  /// of a library.
  static const String topLevel = '::';

  final Map<String, _ClassTable> _libraries = <String, _ClassTable>{};

  /// Indexes the libraries with the URIs given in [libraryUris].
  LibraryIndex(Component component, Iterable<String> libraryUris) {
    Set<String> libraryUriSet = libraryUris.toSet();
    for (Library library in component.libraries) {
      String uri = '${library.importUri}';
      if (libraryUriSet.contains(uri)) {
        _libraries[uri] = new _ClassTable(library);
      }
    }
  }

  /// Indexes the libraries with the URIs given in [libraryUris].
  LibraryIndex.byUri(Component component, Iterable<Uri> libraryUris)
      : this(component, libraryUris.map((uri) => '$uri'));

  /// Indexes `dart:` libraries.
  LibraryIndex.coreLibraries(Component component) {
    for (Library library in component.libraries) {
      if (library.importUri.scheme == 'dart') {
        _libraries['${library.importUri}'] = new _ClassTable(library);
      }
    }
  }

  /// Indexes the entire component.
  ///
  /// Consider using another constructor to only index the libraries that
  /// are needed.
  LibraryIndex.all(Component component) {
    for (Library library in component.libraries) {
      _libraries['${library.importUri}'] = new _ClassTable(library);
    }
  }

  _ClassTable _getLibraryIndex(String uri) {
    _ClassTable libraryIndex = _libraries[uri];
    if (libraryIndex == null) {
      throw "The library '$uri' has not been indexed";
    }
    return libraryIndex;
  }

  /// Returns the library with the given URI.
  ///
  /// Throws an error if it does not exist.
  Library getLibrary(String uri) => _getLibraryIndex(uri).library;

  /// Like [getLibrary] but returns `null` if not found.
  Library tryGetLibrary(String uri) => _libraries[uri]?.library;

  /// True if the library with the given URI exists and was indexed.
  bool containsLibrary(String uri) => _libraries.containsKey(uri);

  /// Returns the class with the given name in the given library.
  ///
  /// An error is thrown if the class is not found.
  Class getClass(String library, String className) {
    return _getLibraryIndex(library).getClass(className);
  }

  /// Like [getClass] but returns `null` if not found.
  Class tryGetClass(String library, String className) {
    return _libraries[library]?.tryGetClass(className);
  }

  /// Returns the member with the given name, in the given class, in the
  /// given library.
  ///
  /// If a getter or setter is wanted, the `get:` or `set:` prefix must be
  /// added in front of the member name.
  ///
  /// The special class name `::` can be used to access top-level members.
  ///
  /// If the member name is private it is considered private to [library].
  /// It is not possible with this class to lookup members whose name is private
  /// to a library other than the one containing it.
  ///
  /// An error is thrown if the member is not found.
  Member getMember(String library, String className, String memberName) {
    return _getLibraryIndex(library).getMember(className, memberName);
  }

  /// Like [getMember] but returns `null` if not found.
  Member tryGetMember(String library, String className, String memberName) {
    return _libraries[library]?.tryGetMember(className, memberName);
  }

  /// Returns the top-level member with the given name, in the given library.
  ///
  /// If a getter or setter is wanted, the `get:` or `set:` prefix must be
  /// added in front of the member name.
  ///
  /// If the member name is private it is considered private to [library].
  /// It is not possible with this class to lookup members whose name is private
  /// to a library other than the one containing it.
  ///
  /// An error is thrown if the member is not found.
  Member getTopLevelMember(String library, String memberName) {
    return getMember(library, topLevel, memberName);
  }

  /// Like [getTopLevelMember] but returns `null` if not found.
  Member tryGetTopLevelMember(
      String library, String className, String memberName) {
    return tryGetMember(library, topLevel, memberName);
  }
}

class _ClassTable {
  final Library library;

  Map<String, _MemberTable> _classes;

  _ClassTable(this.library);

  Map<String, _MemberTable> get classes {
    if (_classes == null) {
      _classes = <String, _MemberTable>{};
      _classes[LibraryIndex.topLevel] = new _MemberTable.topLevel(this);
      for (Class class_ in library.classes) {
        _classes[class_.name] = new _MemberTable.fromClass(this, class_);
      }
      for (Extension extension_ in library.extensions) {
        _classes[extension_.name] =
            new _MemberTable.fromExtension(this, extension_);
      }
      for (Reference reference in library.additionalExports) {
        NamedNode node = reference.node;
        if (node is Class) {
          _classes[node.name] = new _MemberTable.fromClass(this, node);
        } else if (node is Extension) {
          _classes[node.name] = new _MemberTable.fromExtension(this, node);
        }
      }
    }
    return _classes;
  }

  String get containerName {
    return "library '${library.importUri}'";
  }

  _MemberTable _getClassIndex(String name) {
    _MemberTable indexer = classes[name];
    if (indexer == null) {
      throw "Class '$name' not found in $containerName";
    }
    return indexer;
  }

  Class getClass(String name) {
    return _getClassIndex(name).class_;
  }

  Class tryGetClass(String name) {
    return classes[name]?.class_;
  }

  Member getMember(String className, String memberName) {
    return _getClassIndex(className).getMember(memberName);
  }

  Member tryGetMember(String className, String memberName) {
    return classes[className]?.tryGetMember(memberName);
  }
}

class _MemberTable {
  final _ClassTable parent;
  final Class class_; // Null for top-level or extension.
  final Extension extension_; // Null for top-level or class.
  Map<String, Member> _members;

  Library get library => parent.library;

  _MemberTable.fromClass(this.parent, this.class_) : extension_ = null;
  _MemberTable.fromExtension(this.parent, this.extension_) : class_ = null;
  _MemberTable.topLevel(this.parent)
      : class_ = null,
        extension_ = null;

  Map<String, Member> get members {
    if (_members == null) {
      _members = <String, Member>{};
      if (class_ != null) {
        class_.procedures.forEach(addMember);
        class_.fields.forEach(addMember);
        class_.constructors.forEach(addMember);
      } else if (extension_ != null) {
        extension_.members.forEach(addExtensionMember);
      } else {
        library.procedures.forEach(addMember);
        library.fields.forEach(addMember);
      }
    }
    return _members;
  }

  String getDisambiguatedName(Member member) {
    if (member is Procedure) {
      if (member.isGetter) return LibraryIndex.getterPrefix + member.name.text;
      if (member.isSetter) return LibraryIndex.setterPrefix + member.name.text;
    }
    return member.name.text;
  }

  void addMember(Member member) {
    if (member.name.isPrivate && member.name.library != library) {
      // Members whose name is private to other libraries cannot currently
      // be found with the LibraryIndex class.
      return;
    }
    _members[getDisambiguatedName(member)] = member;
  }

  String getDisambiguatedExtensionName(
      ExtensionMemberDescriptor extensionMember) {
    if (extensionMember.kind == ExtensionMemberKind.TearOff) {
      return LibraryIndex.tearoffPrefix + extensionMember.name.text;
    }
    if (extensionMember.kind == ExtensionMemberKind.Getter) {
      return LibraryIndex.getterPrefix + extensionMember.name.text;
    }
    if (extensionMember.kind == ExtensionMemberKind.Setter) {
      return LibraryIndex.setterPrefix + extensionMember.name.text;
    }
    return extensionMember.name.text;
  }

  void addExtensionMember(ExtensionMemberDescriptor extensionMember) {
    final NamedNode replacement = extensionMember.member.node;
    if (replacement is! Member) return;
    Member member = replacement;
    if (member.name.isPrivate && member.name.library != library) {
      // Members whose name is private to other libraries cannot currently
      // be found with the LibraryIndex class.
      return;
    }

    final String name = getDisambiguatedExtensionName(extensionMember);
    _members[name] = replacement;
  }

  String get containerName {
    if (class_ != null) {
      return "class '${class_.name}' in ${parent.containerName}";
    } else if (extension_ != null) {
      return "extension '${extension_.name}' in ${parent.containerName}";
    } else {
      return "top-level of ${parent.containerName}";
    }
  }

  Member getMember(String name) {
    Member member = members[name];
    if (member == null) {
      String message = "A member with disambiguated name '$name' was not found "
          "in $containerName";
      String getter = LibraryIndex.getterPrefix + name;
      String setter = LibraryIndex.setterPrefix + name;
      if (members[getter] != null || members[setter] != null) {
        throw "$message. Did you mean '$getter' or '$setter'?";
      }
      throw message;
    }
    return member;
  }

  Member tryGetMember(String name) => members[name];
}
