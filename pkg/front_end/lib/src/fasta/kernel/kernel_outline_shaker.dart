// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A transformation to create a self-contained modular kernel without
/// unnecessary references to other libraries.
library fasta.kernel.kernel_outline_shaker;

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';

import '../errors.dart' show internalError;

/// Removes from [program] unnecessary libraries, classes, and members.
///
/// This applies a simple "tree-shaking" technique: the full body of libraries
/// whose URI match [isIncluded] is preserved, and so is the outline of the
/// members and classes which are indicated by [data] (which should
/// practically include all members and classes transitively visible from the
/// included libraries).
///
/// The intent is that the resulting program has the entire code that is meant
/// to be included and the minimum required to prevent dangling references and
/// allow modular program transformations.
///
/// Note that the resulting program may include libraries not in [isIncluded],
/// but those will be marked as external. There should be no method bodies for
/// any members of those libraries.
void trimProgram(Program program, RetainedData data, bool isIncluded(Uri uri)) {
  new KernelOutlineShaker(data, isIncluded).transform(program);
}

/// Informs about which libraries, classes, and members should be retained by
/// the [KernelOutlineShaker] when tree-shaking.
abstract class RetainedData {
  /// Whether a library should be preserved and mark as external.
  bool isLibraryUsed(Library library);

  /// Whether a class should be preserved. If a class is preserved, its
  /// supertypes will be preserved too, but some of it members may not be
  /// included.
  bool isClassUsed(Class cls);

  /// Whether a member should be preserved. If so, its enclosing class/library
  /// will be preserved too.
  bool isMemberUsed(Member member);
}

/// A builder of [RetainedData] that recursively marks transitive dependencies.
///
/// This builder contains APIs to mark the roots that are needed (e.g.
/// [markClass] and [markMember]). Note this builder does not determine what
/// roots to keep, that is done either directly by fasta while it is parsing, or
/// by using a visitor like the [RootsMarker] below.
class RetainedDataBuilder extends RetainedData {
  /// Libraries that contained code that is transitively reachable from the
  /// included libraries.
  final Set<Library> libraries = new Set<Library>();

  /// Classes that are transitively reachable from the included libraries.
  final Set<Class> classes = new Set<Class>();

  /// Members that are transitively reachable from the included libraries.
  final Set<Member> members = new Set<Member>();

  TypeMarker typeMarker;

  @override
  bool isLibraryUsed(Library library) => libraries.contains(library);

  @override
  bool isClassUsed(Class cls) => classes.contains(cls);

  @override
  bool isMemberUsed(Member m) => members.contains(m);

  RetainedDataBuilder() {
    typeMarker = new TypeMarker(this);
  }

  /// Mark a library as used.
  void markLibrary(Library lib) {
    libraries.add(lib);
  }

  /// Mark a class and it's supertypes as used.
  void markClass(Class cls) {
    if (cls == null || !classes.add(cls)) return;
    markLibrary(cls.parent);
    // TODO(sigmund): retain annotations?
    // visitList(cls.annotations, this);
    markSupertype(cls.supertype);
    markSupertype(cls.mixedInType);
    cls.implementedTypes.forEach(markSupertype);
    cls.typeParameters.forEach((t) => t.bound.accept(typeMarker));
  }

  /// Mark the class and type arguments of [node].
  void markSupertype(Supertype node) {
    if (node == null) return;
    markClass(node.classNode);
    node.typeArguments.forEach((t) => t.accept(typeMarker));
  }

  /// Mark a member and types mentioned on its interface.
  void markMember(Member m) {
    if (m == null || !members.add(m)) return;
    markMemberInterface(m);
    var parent = m.parent;
    if (parent is Library) {
      markLibrary(parent);
    } else if (parent is Class) {
      markClass(parent);
    }
  }

  void markMemberInterface(Member node) {
    if (node is Field) {
      node.type.accept(typeMarker);
    } else if (node is Procedure) {
      var function = node.function;
      function.typeParameters.forEach((p) => p.bound.accept(typeMarker));
      function.positionalParameters.forEach((p) => p.type.accept(typeMarker));
      function.namedParameters.forEach((p) => p.type.accept(typeMarker));
      function.returnType.accept(typeMarker);
    }
  }
}

/// A helper visitor used to mark transitive types by the [RetainedDataBuilder].
class TypeMarker extends DartTypeVisitor {
  RetainedDataBuilder data;

  TypeMarker(this.data);

  visitInterfaceType(InterfaceType node) {
    data.markClass(node.classNode);
    node.typeArguments.forEach((t) => t.accept(this));
  }

  visitFunctionType(FunctionType node) {
    node.typeParameters.forEach((t) => t.bound.accept(this));
    node.positionalParameters.forEach((t) => t.accept(this));
    node.namedParameters.forEach((t) => t.type.accept(this));
    node.returnType.accept(this);
  }

  visitTypeParameterType(TypeParameterType node) {
    // Note: node.parameter is marked by marking the enclosing element.
  }

  visitTypedefType(TypedefType node) {
    node.typeArguments.forEach((t) => t.accept(this));
  }
}

/// Determines the root APIs that need to be retained before running the
/// tree-shaker.
///
/// This is implemented using a visitor that walks through the sources that are
/// intended to be part of the kernel output.
// TODO(sigmund): delete. We should collect this information while
// building kernel without having to run a visitor afterwards.
class RootsMarker extends RecursiveVisitor {
  final RetainedDataBuilder data;
  RootsMarker(this.data);

  void run(Program program, bool isIncluded(Uri uri)) {
    markRequired(program);
    data.markMember(program.mainMethod);
    for (var library in program.libraries) {
      if (isIncluded(library.importUri)) {
        library.accept(this);
      }
    }
  }

  /// Marks classes and members that are assumed to exist by fasta or by
  /// transformers.
  // TODO(sigmund): consider being more fine-grained and only marking what is
  // seen and used.
  void markRequired(Program program) {
    var coreTypes = new CoreTypes(program);
    coreTypes.objectClass.members.forEach(data.markMember);

    // These are assumed to be available by fasta:
    data.markClass(coreTypes.objectClass);
    data.markClass(coreTypes.nullClass);
    data.markClass(coreTypes.boolClass);
    data.markClass(coreTypes.intClass);
    data.markClass(coreTypes.numClass);
    data.markClass(coreTypes.doubleClass);
    data.markClass(coreTypes.stringClass);
    data.markClass(coreTypes.listClass);
    data.markClass(coreTypes.mapClass);
    data.markClass(coreTypes.iterableClass);
    data.markClass(coreTypes.iteratorClass);
    data.markClass(coreTypes.futureClass);
    data.markClass(coreTypes.streamClass);
    data.markClass(coreTypes.symbolClass);
    data.markClass(coreTypes.internalSymbolClass);
    data.markClass(coreTypes.typeClass);
    data.markClass(coreTypes.functionClass);
    data.markClass(coreTypes.invocationClass);
    data.markMember(coreTypes.externalNameDefaultConstructor);

    // These are needed by the continuation (async/await) transformer:
    data.markClass(coreTypes.iteratorClass);
    data.markClass(coreTypes.futureClass);
    data.markClass(coreTypes.futureOrClass);
    data.markClass(coreTypes.completerClass);
    data.markMember(coreTypes.completerSyncConstructor);
    data.markMember(coreTypes.syncIterableDefaultConstructor);
    data.markMember(coreTypes.streamIteratorDefaultConstructor);
    data.markMember(coreTypes.futureMicrotaskConstructor);
    data.markMember(coreTypes.asyncStarStreamControllerDefaultConstructor);
    data.markMember(coreTypes.printProcedure);
    data.markMember(coreTypes.asyncThenWrapperHelperProcedure);
    data.markMember(coreTypes.asyncErrorWrapperHelperProcedure);
    data.markMember(coreTypes.awaitHelperProcedure);

    // These are needed by the mixin transformer
    data.markMember(coreTypes.invocationMirrorDefaultConstructor);
    data.markMember(coreTypes.listFromConstructor);
  }

  visitConstructor(Constructor node) {
    if (!node.initializers.any((i) => i is SuperInitializer)) {
      // super() is currently implicit.
      for (var ctor in node.enclosingClass.supertype.classNode.constructors) {
        if (ctor.name.name == '') data.markMember(ctor);
      }
    }
    node.visitChildren(this);
  }

  @override
  visitSuperInitializer(SuperInitializer node) {
    data.markMember(node.target);
    node.visitChildren(this);
  }

  @override
  visitRedirectingInitializer(RedirectingInitializer node) {
    data.markMember(node.target);
    node.visitChildren(this);
  }

  @override
  visitConstructorInvocation(ConstructorInvocation node) {
    data.markMember(node.target);
    node.visitChildren(this);
  }

  @override
  visitStaticInvocation(StaticInvocation node) {
    data.markMember(node.target);
    node.visitChildren(this);
  }

  @override
  visitDirectMethodInvocation(DirectMethodInvocation node) {
    if (node.receiver is! ThisExpression) {
      return internalError('Direct calls are only supported on "this"');
    }
    data.markMember(node.target);
    node.visitChildren(this);
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    data.markMember(node.interfaceTarget);
    node.visitChildren(this);
  }

  @override
  visitStaticGet(StaticGet node) {
    data.markMember(node.target);
    node.visitChildren(this);
  }

  @override
  visitStaticSet(StaticSet node) {
    data.markMember(node.target);
    node.visitChildren(this);
  }

  @override
  visitDirectPropertyGet(DirectPropertyGet node) {
    data.markMember(node.target);
    node.visitChildren(this);
  }

  @override
  visitDirectPropertySet(DirectPropertySet node) {
    data.markMember(node.target);
    node.visitChildren(this);
  }

  @override
  visitSuperPropertyGet(SuperPropertyGet node) {
    data.markMember(node.interfaceTarget);
    node.visitChildren(this);
  }

  @override
  visitSuperPropertySet(SuperPropertySet node) {
    data.markMember(node.interfaceTarget);
    node.visitChildren(this);
  }

  @override
  visitPropertyGet(PropertyGet node) {
    data.markMember(node.interfaceTarget);
    node.visitChildren(this);
  }

  @override
  visitPropertySet(PropertySet node) {
    data.markMember(node.interfaceTarget);
    node.visitChildren(this);
  }

  @override
  visitInterfaceType(InterfaceType node) {
    data.markClass(node.classNode);
    node.visitChildren(this);
  }

  @override
  visitSupertype(Supertype node) {
    data.markClass(node.classNode);
    node.visitChildren(this);
  }

  @override
  visitTypedefReference(Typedef node) {
    return internalError('not implemented');
  }
}

/// Transformer that trims everything in the excluded libraries that is not
/// marked as preserved by the given [RetainedData]. For every member in these
/// excluded libraries, this transformer also removes function bodies and
/// initializers.
class KernelOutlineShaker extends Transformer {
  final RetainedData data;
  final Filter isIncluded;

  KernelOutlineShaker(this.data, this.isIncluded);

  void transform(Program program) {
    var toRemove = new Set<Library>();
    for (var library in program.libraries) {
      if (!isIncluded(library.importUri)) {
        if (!data.isLibraryUsed(library)) {
          toRemove.add(library);
        } else {
          library.isExternal = true;
          library.transformChildren(this);
        }
      }
    }
    program.libraries.removeWhere(toRemove.contains);
  }

  Class visitClass(Class node) {
    if (!data.isClassUsed(node)) {
      node.canonicalName?.unbind();
      return null; // Remove the class.
    } else {
      node.transformChildren(this);
      return node;
    }
  }

  Member defaultMember(Member node) {
    if (!data.isMemberUsed(node)) {
      node.canonicalName?.unbind();
      return null;
    } else {
      if (node is Procedure) {
        node.function.body = null;
      } else if (node is Field) {
        node.initializer = null;
      } else if (node is Constructor) {
        node.initializers.clear();
        node.function.body = null;
      }
      return node;
    }
  }

  /// Types appear to be encoded directly, so we have no need to preserve
  /// typedefs.
  // TODO(sigmund): revisit if this is not the case, the `inputError` in
  // [RootsMarker] is meant to detect this.
  Typedef visitTypedef(Typedef node) => null;

  TreeNode defaultTreeNode(TreeNode node) => node;
}

typedef bool Filter(Uri uri);
