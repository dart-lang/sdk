// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "ast.dart"
    show
        Class,
        Constructor,
        Extension,
        ExtensionMemberDescriptor,
        Field,
        Library,
        Member,
        Name,
        Procedure,
        ProcedureKind,
        Reference,
        Typedef,
        ExtensionTypeDeclaration;

class ReferenceFromIndex {
  Map<Library, IndexedLibrary> _indexedLibraries =
      new Map<Library, IndexedLibrary>.identity();

  /// Add an entry mapping from *new* [library] to an index of the old library.
  void addIndexedLibrary(Library library, IndexedLibrary indexedLibrary) {
    assert(!_indexedLibraries.containsKey(library));
    _indexedLibraries[library] = indexedLibrary;
  }

  /// Lookup the new library and get an index of the old library.
  IndexedLibrary? lookupLibrary(Library library) => _indexedLibraries[library];
}

abstract class IndexedContainer {
  Library get library;

  /// Reference to this container node.
  Reference get reference;

  Reference? lookupConstructorReference(Name name);
  Reference? lookupFieldReference(Name name);
  Reference? lookupGetterReference(Name name);
  Reference? lookupSetterReference(Name name);
}

mixin _IndexedProceduresMixin {
  final Map<Name, Reference> _getterReferences = new Map<Name, Reference>();
  final Map<Name, Reference> _setterReferences = new Map<Name, Reference>();

  void _addProcedures(List<Procedure> procedures) {
    for (int i = 0; i < procedures.length; i++) {
      _addProcedure(procedures[i]);
    }
  }

  void _addProcedure(Procedure procedure) {
    Name name = procedure.name;
    if (procedure.isSetter) {
      assert(_setterReferences[name] == null);
      _setterReferences[name] = procedure.reference;
    } else {
      assert(_getterReferences[name] == null);
      assert(procedure.kind == ProcedureKind.Method ||
          procedure.kind == ProcedureKind.Getter ||
          procedure.kind == ProcedureKind.Operator);
      _getterReferences[name] = procedure.reference;
    }
  }
}

abstract class IndexedContainerImpl
    with _IndexedProceduresMixin
    implements IndexedContainer {
  final Map<Name, Reference> _fieldReferences = new Map<Name, Reference>();

  @override
  Reference? lookupFieldReference(Name name) => _fieldReferences[name];
  @override
  Reference? lookupGetterReference(Name name) => _getterReferences[name];
  @override
  Reference? lookupSetterReference(Name name) => _setterReferences[name];

  @override
  Library get library;

  void _addFields(List<Field> fields) {
    for (int i = 0; i < fields.length; i++) {
      Field field = fields[i];
      Name name = field.name;
      assert(_fieldReferences[name] == null);
      _fieldReferences[name] = field.fieldReference;
      assert(_getterReferences[name] == null);
      _getterReferences[name] = field.getterReference;
      if (field.hasSetter) {
        assert(_setterReferences[name] == null);
        _setterReferences[name] = field.setterReference!;
      }
    }
  }
}

class IndexedLibrary extends IndexedContainerImpl {
  final Map<String, Typedef> _typedefs = {};
  final Map<String, IndexedClass> _indexedClasses = {};
  final Map<String, IndexedExtensionTypeDeclaration>
      _indexedExtensionTypeDeclarations = {};
  final Map<String, Extension> _extensions = {};
  @override
  final Library library;

  IndexedLibrary(this.library) {
    for (int i = 0; i < library.typedefs.length; i++) {
      Typedef typedef = library.typedefs[i];
      assert(_typedefs[typedef.name] == null);
      _typedefs[typedef.name] = typedef;
    }
    for (int i = 0; i < library.classes.length; i++) {
      Class c = library.classes[i];
      assert(_indexedClasses[c.name] == null);
      _indexedClasses[c.name] = new IndexedClass._(c, library);
    }
    List<Extension> unnamedExtensions = [];
    for (int i = 0; i < library.extensions.length; i++) {
      Extension extension = library.extensions[i];
      if (extension.isUnnamedExtension) {
        unnamedExtensions.add(extension);
      } else {
        assert(_extensions[extension.name] == null);
        _extensions[extension.name] = extension;
      }
    }
    for (int i = 0; i < library.extensionTypeDeclarations.length; i++) {
      ExtensionTypeDeclaration extensionTypeDeclaration =
          library.extensionTypeDeclarations[i];
      assert(_indexedExtensionTypeDeclarations[extensionTypeDeclaration.name] ==
          null);
      _indexedExtensionTypeDeclarations[extensionTypeDeclaration.name] =
          new IndexedExtensionTypeDeclaration(this, extensionTypeDeclaration);
    }
    _addProcedures(library.procedures);
    _addFields(library.fields);

    // Unnamed extensions and their members cannot be looked up and reused and
    // their references should not therefore not be bound to the canonical names
    // as it would otherwise prevent (new) unnamed extensions and member from
    // repurposing these canonical names.
    for (Extension extension in unnamedExtensions) {
      extension.reference.canonicalName?.unbind();
      for (ExtensionMemberDescriptor descriptor
          in extension.memberDescriptors) {
        Reference reference = descriptor.memberReference;
        Member member = reference.asMember;
        if (member is Field) {
          member.fieldReference.canonicalName?.unbind();
          member.getterReference.canonicalName?.unbind();
          member.setterReference?.canonicalName?.unbind();
        } else {
          member.reference.canonicalName?.unbind();
        }
        descriptor.tearOffReference?.canonicalName?.unbind();
      }
    }
  }

  @override
  Reference get reference => library.reference;

  Typedef? lookupTypedef(String name) => _typedefs[name];
  Class? lookupClass(String name) => _indexedClasses[name]?.cls;
  IndexedClass? lookupIndexedClass(String name) => _indexedClasses[name];

  Extension? lookupExtension(String name) => _extensions[name];

  IndexedExtensionTypeDeclaration? lookupIndexedExtensionTypeDeclaration(
          String name) =>
      _indexedExtensionTypeDeclarations[name];
  ExtensionTypeDeclaration? lookupExtensionTypeDeclaration(String name) =>
      _indexedExtensionTypeDeclarations[name]?.extensionTypeDeclaration;

  @override
  Reference? lookupConstructorReference(Name name) {
    throw new UnsupportedError("$runtimeType.lookupConstructorReference");
  }
}

class IndexedClass extends IndexedContainerImpl {
  final Class cls;
  final Map<Name, Reference> _constructors = {};
  @override
  final Library library;

  IndexedClass._(this.cls, this.library) {
    for (int i = 0; i < cls.constructors.length; i++) {
      Constructor constructor = cls.constructors[i];
      _constructors[constructor.name] = constructor.reference;
    }
    for (int i = 0; i < cls.procedures.length; i++) {
      Procedure procedure = cls.procedures[i];
      if (procedure.isFactory) {
        _constructors[procedure.name] = procedure.reference;
      } else {
        _addProcedure(procedure);
      }
    }
    _addFields(cls.fields);
  }

  @override
  Reference get reference => cls.reference;

  @override
  Reference? lookupConstructorReference(Name name) => _constructors[name];
}

class IndexedExtensionTypeDeclaration
    with _IndexedProceduresMixin
    implements IndexedContainer {
  final IndexedLibrary _indexedLibrary;
  final ExtensionTypeDeclaration extensionTypeDeclaration;

  IndexedExtensionTypeDeclaration(
      this._indexedLibrary, this.extensionTypeDeclaration) {
    _addProcedures(extensionTypeDeclaration.procedures);
  }

  @override
  Library get library => _indexedLibrary.library;

  @override
  Reference get reference => extensionTypeDeclaration.reference;

  @override
  Reference? lookupConstructorReference(Name name) =>
      // Constructors are stored as methods in the library.
      _indexedLibrary.lookupGetterReference(name);

  @override
  Reference? lookupFieldReference(Name name) =>
      // Static fields are stored in the library.
      _indexedLibrary.lookupFieldReference(name);

  @override
  Reference? lookupGetterReference(Name name) {
    return _getterReferences[name] ??
        _indexedLibrary.lookupGetterReference(name);
  }

  @override
  Reference? lookupSetterReference(Name name) {
    return _setterReferences[name] ??
        _indexedLibrary.lookupSetterReference(name);
  }
}
