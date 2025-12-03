// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/import_table.dart';
import 'package:kernel/target/targets.dart' show Target;
import 'package:kernel/type_algebra.dart';

import 'pragma.dart';

const String _dedupLibraryName = 'dart:mixin_deduplication';

/// De-duplication of identical mixin applications.
///
/// Moves all canonicalized mixin application into a new library so that the
/// users of the mixin application can import that library without importing
/// everything else from the canonical mixin's source library.
///
/// If [useUniqueDeduplicationLibrary] is true, each deduplicated mixin
/// application will be moved into its own library. This reduces the number of
/// libraries that need to be imported by the users of the mixin application.
void transformLibraries(
  List<Library> libraries,
  CoreTypes coreTypes,
  Target target, {
  bool useUniqueDeduplicationLibrary = false,
}) {
  if (libraries.isEmpty) return;
  final deduplicateMixins = new _DeduplicateMixinsTransformer(
    coreTypes,
    target,
  );

  final Map<Library, Set<Library>> addedImports = {};

  final relocator = _DeduplicateRelocator(
    libraries.first.enclosingComponent!,
    addedImports,
    useUniqueDeduplicationLibrary,
  );

  final referenceUpdater = _ReferenceUpdater(deduplicateMixins, addedImports);

  // Deduplicate mixins and re-resolve super initializers.
  // (this is a shallow transformation)
  libraries.forEach((library) => deduplicateMixins.visitLibrary(library, null));

  relocator.relocateCanonicalClasses(
    deduplicateMixins._canonicalMixins.values,
    deduplicateMixins._superRemapped,
  );

  // Do a deep transformation to update references to the removed mixin
  // application classes in the interface targets and types.
  //
  // Interface targets pointing to members of removed mixin application
  // classes are re-resolved at the remaining mixin applications.
  // This is necessary iff the component was assembled from individual modular
  // kernel compilations:
  //
  //   * if the CFE reads in the entire program as source, interface targets
  //     will point to the original mixin class
  //
  //   * if the CFE reads in dependencies as kernel, interface targets will
  //     point to the already existing mixin application classes.
  //
  // TODO(dartbug.com/39375): Remove this extra O(N) pass over the AST if the
  // CFE decides to consistently let the interface target point to the mixin
  // class (instead of mixin application).
  libraries.forEach(referenceUpdater.visitLibrary);

  // Add imports to the new mixin deduplication library(-ies).
  for (final library in relocator.newLibraries) {
    final importTable = LibraryImportTable(library);
    for (final importedLibrary in importTable.importedLibraries) {
      if (library != importedLibrary &&
          (addedImports[library] ??= {}).add(importedLibrary)) {
        library.addDependency(LibraryDependency.import(importedLibrary));
      }
    }
  }
}

/// De-duplication of identical mixin applications.
///
/// Moves all canonicalized mixin application into a new library so that the
/// users of the mixin application can import that library without importing
/// everything else from the canonical mixin's source library.
///
/// If [useUniqueDeduplicationLibrary] is true, each deduplicated mixin
/// application will be moved into its own library. This reduces the number of
/// libraries that need to be imported by the users of the mixin application.
void transformComponent(
  Component component,
  CoreTypes coreTypes,
  Target target, {
  bool useUniqueDeduplicationLibrary = false,
}) {
  transformLibraries(
    component.libraries,
    coreTypes,
    target,
    useUniqueDeduplicationLibrary: useUniqueDeduplicationLibrary,
  );
}

class _DeduplicateMixinKey {
  final Class _class;
  _DeduplicateMixinKey(this._class) {
    // Mixins applications were lowered to anonymous mixin application classes.
    assert(_class.mixedInType == null);
    assert(_class.isAnonymousMixin);
  }

  @override
  bool operator ==(Object other) {
    if (other is! _DeduplicateMixinKey) return false;

    final thisClass = _class;
    final otherClass = other._class;
    if (identical(thisClass, otherClass)) {
      return true;
    }

    // If the shape of the two mixin application classes don't match, return
    // `false` quickly.
    final thisSupertype = thisClass.supertype!;
    final otherSupertype = otherClass.supertype!;
    if (thisSupertype.classNode != otherSupertype.classNode) return false;

    // Treat 'dart:*' libraries as distinct from libraries not in 'dart:*'.
    if (thisClass.enclosingLibrary.importUri.isScheme('dart') !=
        otherClass.enclosingLibrary.importUri.isScheme('dart')) {
      return false;
    }

    final thisParameters = thisClass.typeParameters;
    final otherParameters = otherClass.typeParameters;
    if (thisParameters.length != otherParameters.length) return false;

    final thisImplemented = thisClass.implementedTypes;
    final otherImplemented = otherClass.implementedTypes;
    if (thisImplemented.length != otherImplemented.length) return false;

    // Non generic classes can use equalty compares of supertypes.
    if (thisParameters.isEmpty) {
      if (thisSupertype != otherSupertype) return false;
      if (!listEquals(thisImplemented, otherImplemented)) return false;
    }

    // Generic classes must translate type parameter usages from one class to
    // the other.
    final substitution = Substitution.fromMap({
      for (int i = 0; i < otherParameters.length; ++i)
        otherParameters[i]: TypeParameterType(
          thisParameters[i],
          otherParameters[i].bound.nullability == Nullability.nonNullable
              ? Nullability.nonNullable
              : Nullability.undetermined,
        ),
    });
    if (thisSupertype != substitution.substituteSupertype(otherSupertype)) {
      return false;
    }
    for (int i = 0; i < thisImplemented.length; ++i) {
      if (thisImplemented[i] !=
          substitution.substituteSupertype(otherImplemented[i])) {
        return false;
      }
    }
    for (int i = 0; i < thisParameters.length; ++i) {
      if (thisParameters[i].bound !=
          substitution.substituteType(otherParameters[i].bound)) {
        return false;
      }
    }

    return true;
  }

  @override
  int get hashCode {
    int hash = 31;
    hash = 0x3fffffff & (hash * 31 + _class.supertype!.classNode.hashCode);
    for (var i in _class.implementedTypes) {
      hash = 0x3fffffff & (hash * 31 + i.classNode.hashCode);
    }
    hash = 0x3fffffff & (hash * 31 + _class.typeParameters.length.hashCode);
    return hash;
  }
}

class _DeduplicateMixinsTransformer extends RemovingTransformer {
  final ConstantPragmaAnnotationParser pragmaParser;
  final _canonicalMixins = new Map<_DeduplicateMixinKey, Class>();
  final _duplicatedMixins = new Map<Class, Class>();
  final _superRemapped = new Map<Class, Set<Class>>();
  final CoreTypes coreTypes;

  _DeduplicateMixinsTransformer(this.coreTypes, Target target)
    : pragmaParser = ConstantPragmaAnnotationParser(coreTypes, target) {}

  @override
  TreeNode visitLibrary(Library node, TreeNode? removalSentinel) {
    transformClassList(node.classes, node);
    return node;
  }

  @override
  TreeNode visitClass(Class c, TreeNode? removalSentinel) {
    if (_duplicatedMixins.containsKey(c)) {
      // Class was de-duplicated already, just remove it.
      return removalSentinel!;
    }

    if (c.supertype != null) {
      c.supertype = _transformSupertype(c.supertype!, c, true);
    }
    if (c.mixedInType != null) {
      throw 'All mixins should be transformed already.';
    }
    transformSupertypeList(c.implementedTypes);

    if (!c.isAnonymousMixin) {
      return c;
    }

    if (!_canBeEliminated(c)) {
      return c;
    }

    Class canonical = _canonicalMixins.putIfAbsent(
      new _DeduplicateMixinKey(c),
      () => c,
    );

    if (canonical != c) {
      // Ensure that kernel file writer will not be able to
      // write a dangling reference to the deleted class.
      c.reference.canonicalName = null;
      _duplicatedMixins[c] = canonical;
      // Remove class.
      return removalSentinel!;
    }

    return c;
  }

  bool _canBeEliminated(Class c) {
    bool isEntryPoint(Annotatable node) =>
        pragmaParser
            .parsedPragmas<ParsedEntryPointPragma>(node.annotations)
            .isNotEmpty;
    // Cannot eliminate mixin applications which is exported
    // through a dynamic interface (or one of its members is exported).
    if (isEntryPoint(c) || c.members.any(isEntryPoint)) {
      return false;
    }
    return true;
  }

  @override
  Supertype visitSupertype(Supertype node, Supertype? removalSentinel) {
    return _transformSupertype(node, null, false);
  }

  Supertype _transformSupertype(
    Supertype supertype,
    Class? cls,
    bool isSuperclass,
  ) {
    Class oldSuper = supertype.classNode;
    Class newSuper = visitClass(oldSuper, dummyClass) as Class;
    if (identical(newSuper, dummyClass)) {
      Class canonicalSuper = _duplicatedMixins[oldSuper]!;
      supertype = new Supertype(canonicalSuper, supertype.typeArguments);
      if (isSuperclass) {
        _correctForwardingConstructors(cls!, oldSuper, canonicalSuper);
      }
    }
    return supertype;
  }

  @override
  TreeNode defaultTreeNode(TreeNode node, TreeNode? removalSentinel) =>
      throw 'Unexpected node ${node.runtimeType}: $node';

  /// Corrects forwarding constructors inserted by mixin resolution after
  /// replacing superclass.
  void _correctForwardingConstructors(Class c, Class oldSuper, Class newSuper) {
    for (var constructor in c.constructors) {
      for (var initializer in constructor.initializers) {
        if ((initializer is SuperInitializer) &&
            initializer.target.enclosingClass == oldSuper) {
          Constructor? replacement = null;
          for (var c in newSuper.constructors) {
            if (c.name == initializer.target.name) {
              replacement = c;
              break;
            }
          }
          if (replacement == null) {
            throw 'Unable to find a replacement for $c in $newSuper';
          }
          (_superRemapped[c] ??= {}).add(newSuper);
          initializer.target = replacement;
        }
      }
    }
  }
}

class _DeduplicateRelocator {
  int deduplicatedMixinCount = 0;
  Library? sharedDedupLibrary;
  final Component component;
  final bool useUniqueDeduplicationLibrary;
  final Map<Library, Set<Library>> addedImports;
  final List<Library> newLibraries = [];
  final Uri placeholderFileUri = Uri();

  _DeduplicateRelocator(
    this.component,
    this.addedImports,
    this.useUniqueDeduplicationLibrary,
  );

  Library getLibraryForClass(int mixinIndex) {
    if (useUniqueDeduplicationLibrary) {
      final library = new Library(
        Uri.parse('$_dedupLibraryName$mixinIndex'),
        fileUri: placeholderFileUri,
      )..parent = component;
      component.libraries.add(library);
      newLibraries.add(library);
      return library;
    }
    return sharedDedupLibrary ??=
        (() {
          final library = new Library(
            Uri.parse(_dedupLibraryName),
            fileUri: placeholderFileUri,
          )..parent = component;
          component.libraries.add(library);
          newLibraries.add(library);
          return library;
        })();
  }

  void relocateCanonicalClasses(
    Iterable<Class> classes,
    Map<Class, Set<Class>> remappedSupers,
  ) {
    for (final cls in classes) {
      // Leave 'dart:*' libraries in their own libraries as these might be
      // referenced in VM bootstrapping.
      if (cls.enclosingLibrary.importUri.isScheme('dart')) continue;

      // Move class to shared library.
      final oldLibrary = cls.enclosingLibrary;
      final mixinIndex = deduplicatedMixinCount++;
      final newLibrary = getLibraryForClass(mixinIndex);
      oldLibrary.classes.remove(cls);
      newLibrary.addClass(cls);
      cls.name =
          '_MixinApplication$mixinIndex'
          '${cls.name.substring(cls.name.indexOf('&'))}';
      cls.clearCanonicalNames();
      if ((addedImports[oldLibrary] ??= {}).add(newLibrary)) {
        oldLibrary.addDependency(LibraryDependency.import(newLibrary));
      }
      for (final member in cls.constructors) {
        if (member.name.isPrivate) {
          // Private constructors belong to the mixin application itself and
          // should be rescoped to the new library. Other members are copied
          // from the mixin body and are therefore scoped to the mixin's
          // library.
          member.name = Name(member.name.text, newLibrary);
        }
      }
    }

    remappedSupers.forEach((cls, newSupers) {
      final clsLibrary = cls.enclosingLibrary;
      for (final newSuper in newSupers) {
        final newSuperLibrary = newSuper.enclosingLibrary;
        if ((addedImports[clsLibrary] ??= {}).add(newSuperLibrary)) {
          clsLibrary.addDependency(LibraryDependency.import(newSuperLibrary));
        }
      }
    });
  }
}

/// Rewrites references to the deduplicated mixin application
/// classes. Updates interface targets and types.
class _ReferenceUpdater extends RecursiveVisitor {
  final _DeduplicateMixinsTransformer transformer;
  final Map<Library, Set<Library>> _addedImports;

  _ReferenceUpdater(this.transformer, this._addedImports);

  @override
  void visitProcedure(Procedure node) {
    super.visitProcedure(node);
    node.stubTarget = _resolveNewInterfaceTarget(node.stubTarget);
  }

  @override
  visitInstanceGet(InstanceGet node) {
    node.interfaceTarget = _resolveNewInterfaceTarget(node.interfaceTarget)!;
    super.visitInstanceGet(node);
  }

  @override
  visitInstanceTearOff(InstanceTearOff node) {
    node.interfaceTarget =
        _resolveNewInterfaceTarget(node.interfaceTarget) as Procedure;
    super.visitInstanceTearOff(node);
  }

  @override
  visitInstanceSet(InstanceSet node) {
    node.interfaceTarget = _resolveNewInterfaceTarget(node.interfaceTarget)!;
    super.visitInstanceSet(node);
  }

  @override
  visitInstanceInvocation(InstanceInvocation node) {
    node.interfaceTarget =
        _resolveNewInterfaceTarget(node.interfaceTarget) as Procedure;
    super.visitInstanceInvocation(node);
  }

  @override
  visitEqualsCall(EqualsCall node) {
    node.interfaceTarget =
        _resolveNewInterfaceTarget(node.interfaceTarget) as Procedure;
    super.visitEqualsCall(node);
  }

  @override
  visitSuperPropertyGet(SuperPropertyGet node) {
    node.interfaceTarget = _resolveNewInterfaceTarget(node.interfaceTarget)!;
    super.visitSuperPropertyGet(node);
  }

  @override
  visitSuperPropertySet(SuperPropertySet node) {
    node.interfaceTarget = _resolveNewInterfaceTarget(node.interfaceTarget)!;
    super.visitSuperPropertySet(node);
  }

  @override
  visitSuperMethodInvocation(SuperMethodInvocation node) {
    node.interfaceTarget =
        _resolveNewInterfaceTarget(node.interfaceTarget) as Procedure;
    super.visitSuperMethodInvocation(node);
  }

  Member? _resolveNewInterfaceTarget(Member? m) {
    final Class? c = m?.enclosingClass;
    if (c != null && c.isAnonymousMixin) {
      final Class? replacement = transformer._duplicatedMixins[c];
      if (replacement != null) {
        final replacementLibrary = replacement.enclosingLibrary;
        final cLibrary = c.enclosingLibrary;
        if (replacementLibrary != cLibrary &&
            (_addedImports[cLibrary] ??= {}).add(replacementLibrary)) {
          c.enclosingLibrary.addDependency(
            LibraryDependency.import(replacementLibrary),
          );
        }
        // The class got removed, so we need to re-resolve the interface target.
        return _findMember(replacement, m!);
      }
    }
    return m;
  }

  Member _findMember(Class klass, Member m) {
    if (m is Field) {
      return klass.members.where((other) => other.name == m.name).single;
    } else if (m is Procedure) {
      return klass.procedures
          .where((other) => other.kind == m.kind && other.name == m.name)
          .single;
    } else {
      throw 'Hit unexpected interface target which is not a Field/Procedure';
    }
  }

  @override
  visitClassReference(Class node) {
    // Safeguard against any possible leaked uses of anonymous mixin
    // applications which are not updated.
    if (node.isAnonymousMixin && transformer._duplicatedMixins[node] != null) {
      throw 'Unexpected reference to removed mixin application $node';
    }
    super.visitClassReference(node);
  }
}
