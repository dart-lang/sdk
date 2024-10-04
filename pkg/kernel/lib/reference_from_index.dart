// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "ast.dart"
    show
        Class,
        Constructor,
        Extension,
        ExtensionTypeDeclaration,
        Field,
        Library,
        Name,
        Procedure,
        ProcedureKind,
        Reference,
        Typedef;

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
    procedure.reference.canonicalName = null;
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

  void _addFields(List<Field> fields) {
    for (int i = 0; i < fields.length; i++) {
      Field field = fields[i];
      field.fieldReference.canonicalName = null;
      field.getterReference.canonicalName = null;
      field.setterReference?.canonicalName = null;
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

  /// Index [library], and clear all canonical names in references in this
  /// library and its containing classes, procedures etc.
  /// TODO(jensj): Should this class be renamed to make it more immediately
  /// clear that it also clears canonical names? And should the class be moved
  /// as it is more tightly bound with the incremental compiler?
  IndexedLibrary(this.library) {
    library.reference.canonicalName = null;
    for (int i = 0; i < library.typedefs.length; i++) {
      Typedef typedef = library.typedefs[i];
      typedef.reference.canonicalName = null;
      assert(_typedefs[typedef.name] == null);
      _typedefs[typedef.name] = typedef;
    }
    for (int i = 0; i < library.classes.length; i++) {
      Class c = library.classes[i];
      c.reference.canonicalName = null;
      assert(_indexedClasses[c.name] == null);
      _indexedClasses[c.name] = new IndexedClass._(c, library);
    }
    List<Extension> unnamedExtensions = [];
    for (int i = 0; i < library.extensions.length; i++) {
      Extension extension = library.extensions[i];
      extension.reference.canonicalName = null;
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
      extensionTypeDeclaration.reference.canonicalName = null;
      assert(_indexedExtensionTypeDeclarations[extensionTypeDeclaration.name] ==
          null);
      _indexedExtensionTypeDeclarations[extensionTypeDeclaration.name] =
          new IndexedExtensionTypeDeclaration(this, extensionTypeDeclaration);
    }
    _addProcedures(library.procedures);
    _addFields(library.fields);
  }

  @override
  Reference get reference => library.reference;

  Reference? lookupTypedef(String name) => _typedefs[name]?.reference;
  IndexedClass? lookupIndexedClass(String name) => _indexedClasses[name];

  Reference? lookupExtension(String name) => _extensions[name]?.reference;

  IndexedExtensionTypeDeclaration? lookupIndexedExtensionTypeDeclaration(
          String name) =>
      _indexedExtensionTypeDeclarations[name];

  @override
  Reference? lookupConstructorReference(Name name) {
    throw new UnsupportedError("$runtimeType.lookupConstructorReference");
  }
}

class IndexedClass extends IndexedContainerImpl {
  final Class _cls;
  final Map<Name, Reference> _constructors = {};
  @override
  final Library library;

  IndexedClass._(this._cls, this.library) {
    for (int i = 0; i < _cls.constructors.length; i++) {
      Constructor constructor = _cls.constructors[i];
      constructor.reference.canonicalName = null;
      _constructors[constructor.name] = constructor.reference;
    }
    for (int i = 0; i < _cls.procedures.length; i++) {
      Procedure procedure = _cls.procedures[i];
      if (procedure.isFactory) {
        procedure.reference.canonicalName = null;
        _constructors[procedure.name] = procedure.reference;
      } else {
        _addProcedure(procedure);
      }
    }
    _addFields(_cls.fields);
  }

  @override
  Reference get reference => _cls.reference;

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
