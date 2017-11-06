// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/kernel.dart';

/// Given the list of full and partial [outlines] of libraries, combine them
/// into a new [Program].  Different outlines can define the same node multiple
/// times, just one is kept, and all references to synonyms are replaced with
/// the reference to the kept version.  Call [CombineResult.undo] after
/// finishing using the combined [Program] to restore [outlines] into their
/// original state.
CombineResult combine(List<Program> outlines) {
  var combiner = new _Combiner(outlines);
  combiner.perform();
  return combiner.result;
}

/// The result of outlines combining; call [undo] after using to restore
/// partial outlines into their original state.
class CombineResult {
  final Program program;

  final Map<Library, Program> _undoLibraryToProgram = {};

  final Map<Class, Library> _undoClassToLibrary = {};
  final Map<Field, Library> _undoFieldToLibrary = {};
  final Map<Procedure, Library> _undoProcedureToLibrary = {};

  final Map<Member, Class> _undoMemberToClass = {};

  final Map<Library, int> _undoLibraryToClasses = {};
  final Map<Library, int> _undoLibraryToFields = {};
  final Map<Library, int> _undoLibraryToProcedures = {};

  final Map<Class, int> _undoClassToConstructors = {};
  final Map<Class, int> _undoClassToFields = {};
  final Map<Class, int> _undoClassToProcedures = {};

  final Map<Program, _ReplacementMap> _undoReplacementMap = {};

  bool _undone = false;

  CombineResult(this.program);

  /// Undo changes applied to partial outlines by [combine].
  void undo() {
    if (_undone) {
      throw new StateError('This result has already been undone.');
    }
    _undone = true;

    _undoLibraryToProgram.forEach((library, program) {
      program.root.adoptChild(library.canonicalName);
      library.parent = program;
    });

    _undoClassToLibrary.forEach((child, parent) {
      parent.canonicalName.adoptChild(child.canonicalName);
      child.parent = parent;
    });
    _undoFieldToLibrary.forEach((child, parent) {
      var parentName = parent.canonicalName.getChild('@fields');
      parentName.adoptChild(child.canonicalName);
      child.parent = parent;
    });
    _undoProcedureToLibrary.forEach((child, parent) {
      var qualifier = CanonicalName.getMemberQualifier(child);
      var parentName = parent.canonicalName.getChild(qualifier);
      parentName.adoptChild(child.canonicalName);
      child.parent = parent;
    });

    _undoMemberToClass.forEach((child, parent) {
      var qualifier = CanonicalName.getMemberQualifier(child);
      var parentName = parent.canonicalName.getChild(qualifier);
      parentName.adoptChild(child.canonicalName);
      child.parent = parent;
    });

    _undoLibraryToClasses.forEach((library, length) {
      library.classes.length = length;
    });
    _undoLibraryToFields.forEach((library, length) {
      library.fields.length = length;
    });
    _undoLibraryToProcedures.forEach((library, length) {
      library.procedures.length = length;
    });

    _undoClassToConstructors.forEach((class_, length) {
      class_.constructors.length = length;
    });
    _undoClassToFields.forEach((class_, length) {
      class_.fields.length = length;
    });
    _undoClassToProcedures.forEach((class_, length) {
      class_.procedures.length = length;
    });

    _undoReplacementMap.forEach((outline, map) {
      outline.accept(new _ReplaceReferencesVisitor(map, null));
    });
  }
}

/// Keeps the state during combining and contains the result.
class _Combiner {
  final List<Program> outlines;
  final CombineResult result = new CombineResult(new Program());

  /// We record here during [_combineOutline], which keys should be replaced
  /// with which values.
  _ReplacementMap replacementMap;

  _Combiner(this.outlines);

  /// Combine the [outlines] into a new [Program].
  void perform() {
    for (var outline in outlines) {
      _combineOutline(outline);
    }
  }

  /// If the [target] does not have a child with the same name as the [source],
  /// adopt the [source] and return `null`.  Otherwise return the existing
  /// name.
  CanonicalName _adoptMemberName(NamedNode target, Member source) {
    String qualifier = CanonicalName.getMemberQualifier(source);
    CanonicalName parentName = target.canonicalName.getChild(qualifier);
    if (source.name.isPrivate) {
      Uri libraryUri = source.name.library.importUri;
      parentName = parentName.getChildFromUri(libraryUri);
    }
    String sourceName = source.canonicalName.name;
    if (parentName.hasChild(sourceName)) {
      return parentName.getChild(sourceName);
    }
    parentName.adoptChild(source.canonicalName);
    return null;
  }

  /// If [source] is the first node with a particular name, we remember its
  /// original parent into [CombineResult._undoClassToLibrary], and add it
  /// into the [target].
  ///
  /// If [source] is not the first node with this name, we don't add it,
  /// instead we remember that references to this node should be replaced
  /// with the reference to the first node.
  void _combineClass(Library target, Class source) {
    String name = source.name;
    if (target.canonicalName.hasChild(name)) {
      var existingReference = target.canonicalName.getChild(name).reference;
      replacementMap.references[source.reference] = existingReference;
      Class existingNode = existingReference.node;

      var numberOfTypeParameters = source.typeParameters.length;
      assert(numberOfTypeParameters == existingNode.typeParameters.length);
      for (var i = 0; i < numberOfTypeParameters; i++) {
        replacementMap.typeParameters[source.typeParameters[i]] =
            existingNode.typeParameters[i];
      }

      for (var constructor in source.constructors) {
        _combineClassMember(existingNode, constructor);
      }
      for (var field in source.fields) {
        _combineClassMember(existingNode, field);
      }
      for (var procedure in source.procedures) {
        _combineClassMember(existingNode, procedure);
      }
    } else {
      result._undoClassToLibrary[source] = source.parent;
      _putUndoForClassMembers(source);
      target.canonicalName.adoptChild(source.canonicalName);
      target.addClass(source);
    }
  }

  /// If [source] is the first node with a particular name, we remember its
  /// original parent into [CombineResult._undoMemberToClass], and add it
  /// into the [target].
  ///
  /// If [source] is not the first node with this name, we don't add it,
  /// instead we remember that references to this node should be replaced
  /// with the reference to the first node.
  void _combineClassMember(Class target, Member source) {
    CanonicalName existing = _adoptMemberName(target, source);
    if (existing == null) {
      result._undoMemberToClass[source] = source.parent;
      target.addMember(source);
    } else {
      replacementMap.references[source.reference] = existing.reference;
    }
  }

  /// If [source] is the first node with a particular name, we remember its
  /// original parent into [CombineResult._undoFieldToLibrary], and add it
  /// into the [target].
  ///
  /// If [source] is not the first node with this name, we don't add it,
  /// instead we remember that references to this node should be replaced
  /// with the reference to the first node.
  void _combineField(Library target, Field source) {
    CanonicalName existing = _adoptMemberName(target, source);
    if (existing == null) {
      result._undoFieldToLibrary[source] = source.parent;
      target.addField(source);
    } else {
      replacementMap.references[source.reference] = existing.reference;
    }
  }

  /// If [source] is the first node with a particular name, we remember its
  /// original parent into [CombineResult._undoFieldToLibrary], and add it
  /// into the [target].
  ///
  /// If [source] is not the first node with this name, we don't add it,
  /// instead we remember that references to this node should be replaced
  /// with the reference to the first node.  Then we continue merging children
  /// of the node into the first node.
  ///
  /// The first nodes are updated by adding more children into them.  We
  /// remember the original lengths of their [Library.classes],
  /// [Library.fields], and [Library.procedures] lists.  So, to undo the
  /// changes and get rid of added children it is enough to set their lengths.
  void _combineLibrary(Program target, Library source) {
    String name = source.importUri.toString();
    if (target.root.hasChild(name)) {
      var existingReference = target.root.getChild(name).reference;
      replacementMap.references[source.reference] = existingReference;
      Library existingNode = existingReference.node;
      for (var class_ in source.classes) {
        _combineClass(existingNode, class_);
      }
      for (var field in source.fields) {
        _combineField(existingNode, field);
      }
      for (var procedure in source.procedures) {
        _combineProcedure(existingNode, procedure);
      }
    } else {
      result._undoLibraryToProgram[source] = source.parent;
      result._undoLibraryToClasses[source] = source.classes.length;
      result._undoLibraryToFields[source] = source.fields.length;
      result._undoLibraryToProcedures[source] = source.procedures.length;
      source.classes.forEach(_putUndoForClassMembers);
      target.root.adoptChild(source.canonicalName);
      source.parent = target;
      target.libraries.add(source);
    }
  }

  void _combineOutline(Program outline) {
    replacementMap = new _ReplacementMap();
    for (var library in outline.libraries) {
      _combineLibrary(result.program, library);
    }
    var undoMap = new _ReplacementMap();
    result._undoReplacementMap[outline] = undoMap;
    outline.accept(new _ReplaceReferencesVisitor(replacementMap, undoMap));
    replacementMap = null;
  }

  /// If [source] is the first node with a particular name, we remember its
  /// original parent into [CombineResult._undoProcedureToLibrary], and add it
  /// into the [target].
  ///
  /// If [source] is not the first node with this name, we don't add it,
  /// instead we remember that references to this node should be replaced
  /// with the reference to the first node.
  void _combineProcedure(Library target, Procedure source) {
    CanonicalName existing = _adoptMemberName(target, source);
    if (existing == null) {
      result._undoProcedureToLibrary[source] = source.parent;
      target.addProcedure(source);
    } else {
      replacementMap.references[source.reference] = existing.reference;
    }
  }

  void _putUndoForClassMembers(Class source) {
    result._undoClassToConstructors[source] = source.constructors.length;
    result._undoClassToFields[source] = source.fields.length;
    result._undoClassToProcedures[source] = source.procedures.length;
  }
}

/// [_Combiner] fills the maps with information which [Reference]s and
/// [TypeParameter]s should be replaced.
class _ReplacementMap {
  Map<Reference, Reference> references = {};
  Map<TypeParameter, TypeParameter> typeParameters = {};
}

class _ReplaceReferencesVisitor extends RecursiveVisitor {
  final _ReplacementMap map;
  final _ReplacementMap undoMap;

  _ReplaceReferencesVisitor(this.map, this.undoMap);

  @override
  void visitConstructorInvocation(ConstructorInvocation node) {
    node.targetReference = _newReferenceFor(node.targetReference);
  }

  @override
  void visitDirectMethodInvocation(DirectMethodInvocation node) {
    node.targetReference = _newReferenceFor(node.targetReference);
  }

  @override
  void visitDirectPropertyGet(DirectPropertyGet node) {
    node.targetReference = _newReferenceFor(node.targetReference);
  }

  @override
  void visitDirectPropertySet(DirectPropertySet node) {
    node.targetReference = _newReferenceFor(node.targetReference);
  }

  @override
  void visitInterfaceType(InterfaceType node) {
    node.className = _newReferenceFor(node.className);
  }

  @override
  void visitLibraryDependency(LibraryDependency node) {
    node.importedLibraryReference =
        _newReferenceFor(node.importedLibraryReference);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    node.interfaceTargetReference =
        _newReferenceFor(node.interfaceTargetReference);
  }

  @override
  void visitPropertyGet(PropertyGet node) {
    node.interfaceTargetReference =
        _newReferenceFor(node.interfaceTargetReference);
  }

  @override
  void visitPropertySet(PropertySet node) {
    node.interfaceTargetReference =
        _newReferenceFor(node.interfaceTargetReference);
  }

  @override
  void visitRedirectingInitializer(RedirectingInitializer node) {
    node.targetReference = _newReferenceFor(node.targetReference);
  }

  @override
  void visitStaticGet(StaticGet node) {
    node.targetReference = _newReferenceFor(node.targetReference);
  }

  @override
  void visitStaticInvocation(StaticInvocation node) {
    node.targetReference = _newReferenceFor(node.targetReference);
  }

  @override
  void visitStaticSet(StaticSet node) {
    node.targetReference = _newReferenceFor(node.targetReference);
  }

  @override
  void visitSuperInitializer(SuperInitializer node) {
    node.targetReference = _newReferenceFor(node.targetReference);
  }

  @override
  void visitSuperMethodInvocation(SuperMethodInvocation node) {
    node.interfaceTargetReference =
        _newReferenceFor(node.interfaceTargetReference);
  }

  @override
  void visitSuperPropertyGet(SuperPropertyGet node) {
    node.interfaceTargetReference =
        _newReferenceFor(node.interfaceTargetReference);
  }

  @override
  void visitSuperPropertySet(SuperPropertySet node) {
    node.interfaceTargetReference =
        _newReferenceFor(node.interfaceTargetReference);
  }

  @override
  void visitSupertype(Supertype node) {
    node.className = _newReferenceFor(node.className);
  }

  @override
  void visitTypeParameterType(TypeParameterType node) {
    TypeParameter parameter = node.parameter;
    TypeParameter newParameter = map.typeParameters[parameter];
    if (newParameter != null) {
      if (undoMap != null) {
        undoMap.typeParameters[newParameter] = parameter;
      }
      node.parameter = newParameter;
    }
  }

  Reference _newReferenceFor(Reference reference) {
    var newReference = map.references[reference];
    if (newReference == null) return reference;
    if (undoMap != null) undoMap.references[newReference] = reference;
    return newReference;
  }
}
