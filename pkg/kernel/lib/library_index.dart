// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.library_index;

import 'ast.dart';

/// Provides name-based access to library, type declaration, and member AST
/// nodes.
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

  final Map<String, _ContainerTable> _libraries = <String, _ContainerTable>{};

  /// Indexes the libraries with the URIs given in [libraryUris].
  LibraryIndex(Component component, Iterable<String> libraryUris)
      : this.fromLibraries(component.libraries, libraryUris);

  /// Indexes the libraries with the URIs given in [libraryUris].
  LibraryIndex.fromLibraries(
      Iterable<Library> libraries, Iterable<String> libraryUris) {
    Set<String> libraryUriSet = libraryUris.toSet();
    for (Library library in libraries) {
      String uri = '${library.importUri}';
      if (libraryUriSet.contains(uri)) {
        _libraries[uri] = new _ContainerTable(library);
      }
    }
  }

  /// Indexes `dart:` libraries.
  LibraryIndex.coreLibraries(Component component) {
    for (Library library in component.libraries) {
      if (library.importUri.isScheme('dart')) {
        _libraries['${library.importUri}'] = new _ContainerTable(library);
      }
    }
  }

  /// Indexes the entire component.
  ///
  /// Consider using another constructor to only index the libraries that
  /// are needed.
  LibraryIndex.all(Component component) {
    for (Library library in component.libraries) {
      _libraries['${library.importUri}'] = new _ContainerTable(library);
    }
  }

  _ContainerTable _getLibraryIndex(String uri) {
    _ContainerTable? libraryIndex = _libraries[uri];
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
  Library? tryGetLibrary(String uri) => _libraries[uri]?.library;

  /// True if the library with the given URI exists and was indexed.
  bool containsLibrary(String uri) => _libraries.containsKey(uri);

  /// Returns the class with the given name in the given library.
  ///
  /// An error is thrown if the class is not found.
  Class getClass(String library, String className) {
    return _getLibraryIndex(library).getClass(className);
  }

  /// Like [getClass] but returns `null` if not found.
  Class? tryGetClass(String library, String className) {
    return _libraries[library]?.tryGetClass(className);
  }

  /// Returns the extension type with the given name in the given library.
  ///
  /// An error is thrown if the extension type is not found.
  ExtensionTypeDeclaration getExtensionType(
      String library, String extensionTypeName) {
    return _getLibraryIndex(library).getExtensionType(extensionTypeName);
  }

  /// Returns the member with the given name, in the given container
  /// declaration, in the given library.
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
  Member getMember(String library, String containerName, String memberName) {
    return _getLibraryIndex(library).getMember(containerName, memberName);
  }

  Constructor getConstructor(
      String library, String containerName, String memberName) {
    return _getLibraryIndex(library).getConstructor(containerName, memberName);
  }

  Procedure getProcedure(
      String library, String containerName, String memberName) {
    return _getLibraryIndex(library).getProcedure(containerName, memberName);
  }

  Procedure? tryGetProcedure(
      String library, String containerName, String memberName) {
    return _getLibraryIndex(library).tryGetProcedure(containerName, memberName);
  }

  Field getField(String library, String containerName, String memberName) {
    return _getLibraryIndex(library).getField(containerName, memberName);
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

  Procedure getTopLevelProcedure(String library, String memberName) {
    return getProcedure(library, topLevel, memberName);
  }

  Field getTopLevelField(String library, String memberName) {
    return getField(library, topLevel, memberName);
  }
}

class _ContainerTable {
  final Library library;

  Map<String, _MemberTable>? _containers;

  _ContainerTable(this.library);

  Map<String, _MemberTable> get containers {
    if (_containers == null) {
      _containers = <String, _MemberTable>{};
      _containers![LibraryIndex.topLevel] = new _MemberTable.topLevel(this);
      for (Class class_ in library.classes) {
        _containers![class_.name] = new _MemberTable.fromClass(this, class_);
      }
      for (ExtensionTypeDeclaration extensionTypeDeclaration
          in library.extensionTypeDeclarations) {
        _containers![extensionTypeDeclaration.name] =
            new _MemberTable.fromExtensionTypeDeclaration(
                this, extensionTypeDeclaration);
      }
      for (Extension extension_ in library.extensions) {
        _containers![extension_.name] =
            new _MemberTable.fromExtension(this, extension_);
      }
      for (Reference reference in library.additionalExports) {
        NamedNode? node = reference.node;
        if (node is Class) {
          _containers![node.name] = new _MemberTable.fromClass(this, node);
        } else if (node is ExtensionTypeDeclaration) {
          _containers![node.name] =
              new _MemberTable.fromExtensionTypeDeclaration(this, node);
        } else if (node is Extension) {
          _containers![node.name] = new _MemberTable.fromExtension(this, node);
        }
      }
    }
    return _containers!;
  }

  String get containerName {
    return "library '${library.importUri}'";
  }

  _MemberTable _getContainerIndex(String name) {
    _MemberTable? indexer = containers[name];
    if (indexer == null) {
      throw "Container '$name' not found in $containerName";
    }
    return indexer;
  }

  Class getClass(String name) {
    return _getContainerIndex(name).class_!;
  }

  Class? tryGetClass(String name) {
    return containers[name]?.class_;
  }

  ExtensionTypeDeclaration getExtensionType(String name) {
    return _getContainerIndex(name).extensionTypeDeclaration!;
  }

  Member getMember(String className, String memberName) {
    return _getContainerIndex(className).getMember(memberName);
  }

  Constructor getConstructor(String className, String memberName) {
    return _getContainerIndex(className).getConstructor(memberName);
  }

  Procedure getProcedure(String className, String memberName) {
    return _getContainerIndex(className).getProcedure(memberName);
  }

  Procedure? tryGetProcedure(String className, String memberName) {
    return _getContainerIndex(className).tryGetProcedure(memberName);
  }

  Field getField(String className, String memberName) {
    return _getContainerIndex(className).getField(memberName);
  }
}

class _MemberTable {
  final _ContainerTable parent;
  // Null for top-level, extension type declaration, or extension.
  final Class? class_;
  // Null for top-level, class, or extension.
  final ExtensionTypeDeclaration? extensionTypeDeclaration;
  // Null for top-level, class, or extension type declaration.
  final Extension? extension_;
  Map<String, Member>? _members;

  Library get library => parent.library;

  _MemberTable.fromClass(this.parent, this.class_)
      : extensionTypeDeclaration = null,
        extension_ = null;
  _MemberTable.fromExtensionTypeDeclaration(
      this.parent, this.extensionTypeDeclaration)
      : class_ = null,
        extension_ = null;
  _MemberTable.fromExtension(this.parent, this.extension_)
      : class_ = null,
        extensionTypeDeclaration = null;
  _MemberTable.topLevel(this.parent)
      : class_ = null,
        extensionTypeDeclaration = null,
        extension_ = null;

  Map<String, Member> get members {
    if (_members == null) {
      _members = <String, Member>{};
      if (class_ != null) {
        class_!.procedures.forEach(_addClassMember);
        class_!.fields.forEach(_addClassMember);
        class_!.constructors.forEach(_addClassMember);
      } else if (extensionTypeDeclaration != null) {
        // Note that this doesn't include `ExtensionTypeDeclaration.procedures`.
        extensionTypeDeclaration!.memberDescriptors
            .forEach(_addExtensionTypeMember);
      } else if (extension_ != null) {
        extension_!.memberDescriptors.forEach(_addExtensionMember);
      } else {
        library.procedures.forEach(_addClassMember);
        library.fields.forEach(_addClassMember);
      }
    }
    return _members!;
  }

  String getDisambiguatedName(Member member) {
    if (member is Procedure) {
      if (member.isGetter) return LibraryIndex.getterPrefix + member.name.text;
      if (member.isSetter) return LibraryIndex.setterPrefix + member.name.text;
    }
    return member.name.text;
  }

  void _addMember(Member member, String memberIndexName) {
    if (member.name.isPrivate && member.name.library != library) {
      // Members whose name is private to other libraries cannot currently
      // be found with the LibraryIndex class.
      return;
    }
    // TODO(johnniwinther): Constructors and methods/fields can have the same
    // name in a class or extension type. The disambiguation methods should
    // handle this.
    _members![memberIndexName] = member;
  }

  void _addClassMember(Member member) =>
      _addMember(member, getDisambiguatedName(member));

  void _addReference(Reference? reference, String memberIndexName) {
    final NamedNode? replacement = reference?.node;
    if (replacement is! Member) return;
    _addMember(replacement, memberIndexName);
  }

  String _getDisambiguatedExtensionName(
      ExtensionMemberDescriptor extensionMember,
      {required bool forTearOff}) {
    if (forTearOff) {
      return LibraryIndex.tearoffPrefix + extensionMember.name.text;
    }
    switch (extensionMember.kind) {
      case ExtensionMemberKind.Getter:
        return LibraryIndex.getterPrefix + extensionMember.name.text;
      case ExtensionMemberKind.Setter:
        return LibraryIndex.setterPrefix + extensionMember.name.text;
      case ExtensionMemberKind.Field:
      case ExtensionMemberKind.Method:
      case ExtensionMemberKind.Operator:
        return extensionMember.name.text;
    }
  }

  void _addExtensionMember(ExtensionMemberDescriptor extensionMember) {
    _addReference(extensionMember.memberReference,
        _getDisambiguatedExtensionName(extensionMember, forTearOff: false));
    _addReference(extensionMember.tearOffReference,
        _getDisambiguatedExtensionName(extensionMember, forTearOff: true));
  }

  String _getDisambiguatedExtensionTypeName(
      ExtensionTypeMemberDescriptor extensionTypeMember,
      {required bool forTearOff}) {
    if (forTearOff) {
      return LibraryIndex.tearoffPrefix + extensionTypeMember.name.text;
    }
    switch (extensionTypeMember.kind) {
      case ExtensionTypeMemberKind.Getter:
        return LibraryIndex.getterPrefix + extensionTypeMember.name.text;
      case ExtensionTypeMemberKind.Setter:
        return LibraryIndex.setterPrefix + extensionTypeMember.name.text;
      case ExtensionTypeMemberKind.Constructor:
      case ExtensionTypeMemberKind.Factory:
      case ExtensionTypeMemberKind.Field:
      case ExtensionTypeMemberKind.Method:
      case ExtensionTypeMemberKind.Operator:
      case ExtensionTypeMemberKind.RedirectingFactory:
        return extensionTypeMember.name.text;
    }
  }

  void _addExtensionTypeMember(
      ExtensionTypeMemberDescriptor extensionTypeMember) {
    _addReference(
        extensionTypeMember.memberReference,
        _getDisambiguatedExtensionTypeName(extensionTypeMember,
            forTearOff: false));
    _addReference(
        extensionTypeMember.tearOffReference,
        _getDisambiguatedExtensionTypeName(extensionTypeMember,
            forTearOff: true));
  }

  String get containerName {
    if (class_ != null) {
      return "class '${class_!.name}' in ${parent.containerName}";
    } else if (extensionTypeDeclaration != null) {
      return "extension type '${extensionTypeDeclaration!.name}' in "
          "${parent.containerName}";
    } else if (extension_ != null) {
      return "extension '${extension_!.name}' in ${parent.containerName}";
    } else {
      return "top-level of ${parent.containerName}";
    }
  }

  Member getMember(String name) {
    Member? member = members[name];
    if (member == null) {
      String message = "A member with disambiguated name '$name' was not found "
          "in $containerName: ${members.keys}";
      String getter = LibraryIndex.getterPrefix + name;
      String setter = LibraryIndex.setterPrefix + name;
      if (members[getter] != null || members[setter] != null) {
        throw "$message. Did you mean '$getter' or '$setter'?";
      }
      throw message;
    }
    return member;
  }

  Constructor getConstructor(String name) {
    Member member = getMember(name);
    if (member is! Constructor) {
      throw "Member '$name' in $containerName is not a Constructor: "
          "${member} (${member.runtimeType}).";
    }
    return member;
  }

  Procedure getProcedure(String name) {
    Member member = getMember(name);
    if (member is! Procedure) {
      throw "Member '$name' in $containerName is not a Procedure: "
          "${member} (${member.runtimeType}).";
    }
    return member;
  }

  Procedure? tryGetProcedure(String name) {
    Member? member = members[name];
    if (member == null) return null;
    if (member is! Procedure) {
      throw "Member '$name' in $containerName is not a Procedure: "
          "${member} (${member.runtimeType}).";
    }
    return member;
  }

  Field getField(String name) {
    Member member = getMember(name);
    if (member is! Field) {
      throw "Member '$name' in $containerName is not a Field: "
          "${member} (${member.runtimeType}).";
    }
    return member;
  }
}
