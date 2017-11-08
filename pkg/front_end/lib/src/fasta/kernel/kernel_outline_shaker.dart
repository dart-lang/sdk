// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A transformation to create a self-contained modular kernel without
/// unnecessary references to other libraries.
library fasta.kernel.kernel_outline_shaker;

import 'package:kernel/ast.dart';
import 'package:kernel/binary/ast_to_binary.dart';
import 'package:kernel/core_types.dart';

import '../problems.dart' show unimplemented, unsupported;

/// Serialize outlines of the nodes in libraries whose URI match [isIncluded],
/// and outlines of members and classes which are transitively referenced from
/// the included libraries. Only outlines are serialized, even for included
/// libraries, all function bodies are ignored.
void serializeTrimmedOutline(
    Sink<List<int>> sink, Program program, bool isIncluded(Uri uri)) {
  var data = new _RetainedDataBuilder();
  data._markRequired(program);

  for (var library in program.libraries) {
    if (!isIncluded(library.importUri)) continue;
    data.markAdditionalExports(library);
    for (var clazz in library.classes) {
      if (clazz.name.startsWith('_')) continue;
      data.markClassForExport(clazz);
    }
    for (var field in library.fields) {
      if (field.name.isPrivate) continue;
      data.markMember(field);
    }
    for (var procedure in library.procedures) {
      if (procedure.name.isPrivate) continue;
      data.markMember(procedure);
    }
    for (var typedef in library.typedefs) {
      if (typedef.name.startsWith('_')) continue;
      data.markTypedef(typedef);
    }
  }

  new _TrimmedBinaryPrinter(sink, isIncluded, data).writeProgramFile(program);
}

/// Removes unnecessary libraries, classes, and members from [program].
///
/// This applies a simple "tree-shaking" technique: the full body of libraries
/// whose URI match [isIncluded] is preserved, and so is the outline of the
/// members and classes which are transitively visible from the
/// included libraries.
///
/// The intent is that the resulting program has the entire code that is meant
/// to be included and the minimum required to prevent dangling references and
/// allow modular program transformations.
///
/// Note that the resulting program may include libraries not in [isIncluded],
/// but those will be marked as external. There should be no method bodies for
/// any members of those libraries.
void trimProgram(Program program, bool isIncluded(Uri uri)) {
  var data = new _RetainedDataBuilder();
  data._markRequired(program);

  data.markMember(program.mainMethod);
  for (var library in program.libraries) {
    if (isIncluded(library.importUri)) {
      library.accept(data);
    }
  }

  new _KernelOutlineShaker(isIncluded, data).transform(program);
}

/// Transformer that trims everything in the excluded libraries that is not
/// marked as preserved by the given [_RetainedData]. For every member in these
/// excluded libraries, this transformer also removes function bodies and
/// initializers.
class _KernelOutlineShaker extends Transformer {
  final bool Function(Uri uri) isIncluded;
  final _RetainedData data;

  _KernelOutlineShaker(this.isIncluded, this.data);

  @override
  Member defaultMember(Member node) {
    if (!data.isMemberUsed(node)) {
      node.canonicalName?.unbind();
      return null;
    } else {
      if (node is Procedure) {
        _clearParameterInitializers(node.function);
        node.function.body = null;
      } else if (node is Field) {
        if (node.name.name == '_exports#') return null;
        node.initializer = null;
      } else if (node is Constructor) {
        if (!node.isConst) {
          _clearParameterInitializers(node.function);
        }
        node.initializers.clear();
        node.function.body = null;
      }
      return node;
    }
  }

  @override
  TreeNode defaultTreeNode(TreeNode node) => node;

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

  @override
  Class visitClass(Class node) {
    if (!data.isClassUsed(node)) {
      node.canonicalName?.unbind();
      return null; // Remove the class.
    } else {
      node.transformChildren(this);
      return node;
    }
  }

  @override
  Typedef visitTypedef(Typedef node) {
    if (!data.isTypedefUsed(node)) {
      node.canonicalName?.unbind();
      return null; // Remove the typedef.
    } else {
      node.transformChildren(this);
      return node;
    }
  }

  static void _clearParameterInitializers(FunctionNode function) {
    for (var parameter in function.positionalParameters) {
      parameter.initializer = null;
    }
    for (var parameter in function.namedParameters) {
      parameter.initializer = null;
    }
  }
}

/// Informs about which libraries, classes, and members should be retained by
/// the [_KernelOutlineShaker] when tree-shaking.
abstract class _RetainedData {
  /// Whether a class should be preserved. If a class is preserved, its
  /// supertypes will be preserved too, but some of it members may not be
  /// included.
  bool isClassUsed(Class cls);

  /// Whether the field initializer should be preserved.
  bool isFieldInitializerUsed(Field node);

  /// Whether a library should be preserved and mark as external.
  bool isLibraryUsed(Library library);

  /// Whether a member should be preserved. If so, its enclosing class/library
  /// will be preserved too.
  bool isMemberUsed(Member member);

  /// Whether the parameter initializer should be preserved.
  bool isParameterInitializerUsed(VariableDeclaration node);

  /// Whether a typedef should be preserved. If a typedef is preserved, its
  /// return type and types of parameters will be preserved too.
  bool isTypedefUsed(Typedef node);
}

/// A builder of [_RetainedData] that recursively marks transitive dependencies.
///
/// When it is used as a [RecursiveVisitor], it recursively marks nodes that
/// are references by visited nodes.
class _RetainedDataBuilder extends RecursiveVisitor implements _RetainedData {
  /// Libraries that contained code that is transitively reachable from the
  /// included libraries.
  final Set<Library> libraries = new Set<Library>();

  /// Classes that are transitively reachable from the included libraries.
  final Set<Class> classes = new Set<Class>();

  /// Typedefs that are transitively reachable from the included libraries.
  final Set<Typedef> typedefs = new Set<Typedef>();

  /// Members that are transitively reachable from the included libraries.
  final Set<Member> members = new Set<Member>();

  /// Fields for which initializers should be kept because they are constants,
  /// or are final fields of classes with constant constructors.
  final Set<Field> fieldsWithInitializers = new Set<Field>();

  /// Parameters for which initializers should be kept because they are
  /// parameters of a constant constructors.
  final Set<VariableDeclaration> parametersWithInitializers =
      new Set<VariableDeclaration>();

  _TypeMarker typeMarker;

  _RetainedDataBuilder() {
    typeMarker = new _TypeMarker(this);
  }

  @override
  bool isClassUsed(Class cls) => classes.contains(cls);

  @override
  bool isFieldInitializerUsed(Field node) {
    return fieldsWithInitializers.contains(node);
  }

  @override
  bool isLibraryUsed(Library library) => libraries.contains(library);

  @override
  bool isMemberUsed(Member m) => members.contains(m);

  @override
  bool isParameterInitializerUsed(VariableDeclaration node) {
    return parametersWithInitializers.contains(node);
  }

  @override
  bool isTypedefUsed(Typedef node) => typedefs.contains(node);

  void markAdditionalExports(Library node) {
    for (var reference in node.additionalExports) {
      var node = reference.node;
      if (node is Class) {
        markClassForExport(node);
      } else if (node is Member) {
        markMember(node);
      } else if (node is Typedef) {
        markTypedef(node);
      } else {
        unimplemented('export ${node.runtimeType}', -1, null);
      }
    }
  }

  void markAnnotations(List<Expression> annotations) {
    for (var annotation in annotations) {
      annotation.accept(this);
    }
  }

  /// Mark a class and it's supertypes as used.
  void markClass(Class cls) {
    if (cls == null || !classes.add(cls)) return;
    markLibrary(cls.parent);
    markAnnotations(cls.annotations);
    cls.typeParameters.forEach((t) => t.bound.accept(typeMarker));
    markSupertype(cls.supertype);
    markSupertype(cls.mixedInType);
    cls.implementedTypes.forEach(markSupertype);

    for (var field in cls.fields) {
      if (!field.isStatic && !field.name.isPrivate) {
        markMember(field);
      }
    }
    for (var method in cls.procedures) {
      if (!method.isStatic && !method.name.isPrivate) {
        markMember(method);
      }
    }
  }

  /// Mark the given class as exported, so mark all its public members.
  void markClassForExport(Class node) {
    markClass(node);
    for (var field in node.fields) {
      if (!field.name.isPrivate) {
        markMember(field);
      }
    }
    for (var constructor in node.constructors) {
      if (!constructor.name.isPrivate) {
        markMember(constructor);
      }
    }
    for (var method in node.procedures) {
      if (!method.name.isPrivate) {
        markMember(method);
      }
    }
  }

  /// Mark a library as used.
  void markLibrary(Library lib) {
    libraries.add(lib);
  }

  /// Mark a member and types mentioned on its interface.
  void markMember(Member node) {
    if (node == null || !members.add(node)) return;

    var parent = node.parent;
    if (parent is Library) {
      markLibrary(parent);
    } else if (parent is Class) {
      markClass(parent);
    }

    markAnnotations(node.annotations);
    markMemberInterface(node);

    if (node is Field) {
      if (_shouldKeepFieldInitializer(node)) {
        fieldsWithInitializers.add(node);
        node.initializer?.accept(this);
      }
    }
  }

  void markMemberInterface(Member node) {
    if (node is Field) {
      node.type.accept(typeMarker);
    } else if (node is Constructor) {
      var function = node.function;
      for (var parameter in function.positionalParameters) {
        markParameterType(parameter);
        if (node.isConst) {
          markParameterInitializer(parameter);
        }
      }
      for (var parameter in function.namedParameters) {
        markParameterType(parameter);
        if (node.isConst) {
          markParameterInitializer(parameter);
        }
      }
      // We don't mark automatically all constructors of classes.
      // So, we need transitively mark super/redirect initializers.
      for (var initializer in node.initializers) {
        if (initializer is SuperInitializer) {
          markMember(initializer.target);
        } else if (initializer is RedirectingInitializer) {
          markMember(initializer.target);
        }
      }
    } else if (node is Procedure) {
      var function = node.function;
      function.typeParameters.forEach((p) => p.bound.accept(typeMarker));
      function.positionalParameters.forEach(markParameterType);
      function.namedParameters.forEach(markParameterType);
      function.returnType.accept(typeMarker);
    }
  }

  void markParameterInitializer(VariableDeclaration parameter) {
    parametersWithInitializers.add(parameter);
    parameter.initializer?.accept(this);
  }

  void markParameterType(VariableDeclaration parameter) {
    return parameter.type.accept(typeMarker);
  }

  /// Mark the class and type arguments of [node].
  void markSupertype(Supertype node) {
    if (node == null) return;
    markClass(node.classNode);
    node.typeArguments.forEach((t) => t.accept(typeMarker));
  }

  /// Mark the typedef.
  void markTypedef(Typedef node) {
    if (node == null || !typedefs.add(node)) return;
    markLibrary(node.parent);
    markAnnotations(node.annotations);

    DartType type = node.type;
    if (type is FunctionType) {
      type.returnType?.accept(typeMarker);
      for (var positionalType in type.positionalParameters) {
        positionalType.accept(typeMarker);
      }
      for (var namedType in type.namedParameters) {
        namedType.type.accept(typeMarker);
      }
    }
  }

  @override
  visitConstructor(Constructor node) {
    if (!node.initializers.any((i) => i is SuperInitializer)) {
      // super() is currently implicit.
      var supertype = node.enclosingClass.supertype;
      if (supertype != null) {
        for (var constructor in supertype.classNode.constructors) {
          if (constructor.name.name == '') markMember(constructor);
        }
      }
    }
    node.visitChildren(this);
  }

  @override
  visitConstructorInvocation(ConstructorInvocation node) {
    markMember(node.target);
    node.visitChildren(this);
  }

  @override
  visitDirectMethodInvocation(DirectMethodInvocation node) {
    if (node.receiver is! ThisExpression) {
      return unsupported("direct call not on this", node.fileOffset, null);
    }
    markMember(node.target);
    node.visitChildren(this);
  }

  @override
  visitDirectPropertyGet(DirectPropertyGet node) {
    markMember(node.target);
    node.visitChildren(this);
  }

  @override
  visitDirectPropertySet(DirectPropertySet node) {
    markMember(node.target);
    node.visitChildren(this);
  }

  @override
  visitFunctionType(FunctionType node) {
    markTypedef(node.typedefReference?.asTypedef);
    super.visitFunctionType(node);
  }

  @override
  visitInterfaceType(InterfaceType node) {
    markClass(node.classNode);
    node.visitChildren(this);
  }

  @override
  visitLibrary(Library node) {
    markAdditionalExports(node);
    node.visitChildren(this);
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    markMember(node.interfaceTarget);
    node.visitChildren(this);
  }

  @override
  visitPropertyGet(PropertyGet node) {
    markMember(node.interfaceTarget);
    node.visitChildren(this);
  }

  @override
  visitPropertySet(PropertySet node) {
    markMember(node.interfaceTarget);
    node.visitChildren(this);
  }

  @override
  visitRedirectingInitializer(RedirectingInitializer node) {
    markMember(node.target);
    node.visitChildren(this);
  }

  @override
  visitStaticGet(StaticGet node) {
    markMember(node.target);
    node.visitChildren(this);
  }

  @override
  visitStaticInvocation(StaticInvocation node) {
    markMember(node.target);
    node.visitChildren(this);
  }

  @override
  visitStaticSet(StaticSet node) {
    markMember(node.target);
    node.visitChildren(this);
  }

  @override
  visitSuperInitializer(SuperInitializer node) {
    markMember(node.target);
    node.visitChildren(this);
  }

  @override
  visitSuperPropertyGet(SuperPropertyGet node) {
    markMember(node.interfaceTarget);
    node.visitChildren(this);
  }

  @override
  visitSuperPropertySet(SuperPropertySet node) {
    markMember(node.interfaceTarget);
    node.visitChildren(this);
  }

  @override
  visitSupertype(Supertype node) {
    markClass(node.classNode);
    node.visitChildren(this);
  }

  @override
  visitTypedefReference(Typedef node) {
    return unimplemented("visitTypedefReference", -1, null);
  }

  /// Marks classes and members that are assumed to exist by fasta or by
  /// transformers.
  // TODO(sigmund): consider being more fine-grained and only marking what is
  // seen and used.
  void _markRequired(Program program) {
    var coreTypes = new CoreTypes(program);
    coreTypes.objectClass.members.forEach(markMember);

    // These are assumed to be available by fasta:
    markClass(coreTypes.objectClass);
    markClass(coreTypes.nullClass);
    markClass(coreTypes.boolClass);
    markClass(coreTypes.intClass);
    markClass(coreTypes.numClass);
    markClass(coreTypes.doubleClass);
    markClass(coreTypes.stringClass);
    markClass(coreTypes.listClass);
    markClass(coreTypes.mapClass);
    markClass(coreTypes.iterableClass);
    markClass(coreTypes.iteratorClass);
    markClass(coreTypes.futureClass);
    markClass(coreTypes.streamClass);
    markClass(coreTypes.symbolClass);
    markClass(coreTypes.internalSymbolClass);
    markClass(coreTypes.typeClass);
    markClass(coreTypes.functionClass);
    markClass(coreTypes.invocationClass);
    markMember(coreTypes.compileTimeErrorDefaultConstructor);
    markMember(coreTypes.constantExpressionErrorDefaultConstructor);
    markMember(coreTypes.duplicatedFieldInitializerErrorDefaultConstructor);
    markMember(coreTypes.externalNameDefaultConstructor);

    // These are needed by the continuation (async/await) transformer:
    markClass(coreTypes.iteratorClass);
    markClass(coreTypes.futureClass);
    markClass(coreTypes.futureOrClass);
    markClass(coreTypes.completerClass);
    markMember(coreTypes.completerSyncConstructor);
    markMember(coreTypes.syncIterableDefaultConstructor);
    markMember(coreTypes.streamIteratorDefaultConstructor);
    markMember(coreTypes.futureMicrotaskConstructor);
    markMember(coreTypes.asyncStarStreamControllerDefaultConstructor);
    markMember(coreTypes.printProcedure);
    markMember(coreTypes.asyncThenWrapperHelperProcedure);
    markMember(coreTypes.asyncErrorWrapperHelperProcedure);
    markMember(coreTypes.awaitHelperProcedure);

    // These are needed by the mixin transformer
    markMember(coreTypes.invocationMirrorWithoutTypeConstructor);
    markMember(coreTypes.listFromConstructor);
  }

  static bool _shouldKeepFieldInitializer(Field node) {
    if (node.isConst) return true;
    if (node.isFinal && !node.isStatic) {
      var parent = node.parent;
      if (parent is Class) {
        for (var constructor in parent.constructors) {
          if (constructor.isConst) return true;
        }
      }
    }
    return false;
  }
}

/// [BinaryPrinter] that serializes outlines of all nodes in included
/// libraries, and outlines of nodes that are marked in the [_RetainedData].
class _TrimmedBinaryPrinter extends BinaryPrinter {
  final bool Function(Uri uri) isIncluded;
  final _RetainedData data;
  final List<Library> librariesToWrite = <Library>[];
  bool insideIncludedLibrary = false;

  _TrimmedBinaryPrinter(Sink<List<int>> sink, this.isIncluded, this.data)
      : super(sink);

  @override
  visitClass(Class node) {
    var level = node.level;
    node.level = ClassLevel.Hierarchy;
    super.visitClass(node);
    node.level = level;
  }

  @override
  visitField(Field node) {
    if (data.isFieldInitializerUsed(node)) {
      super.visitField(node);
    } else {
      var initializer = node.initializer;
      node.initializer = null;
      super.visitField(node);
      node.initializer = initializer;
    }
  }

  @override
  visitFunctionNode(FunctionNode node) {
    var body = node.body;
    node.body = null;
    super.visitFunctionNode(node);
    node.body = body;
  }

  @override
  visitLibrary(Library node) {
    insideIncludedLibrary = isIncluded(node.importUri);
    if (insideIncludedLibrary) {
      super.visitLibrary(node);
    } else {
      var isExternal = node.isExternal;
      var dependencies = node.dependencies.toList();
      var parts = node.parts.toList();

      node.isExternal = true;
      node.dependencies.clear();
      node.parts.clear();
      super.visitLibrary(node);

      node.isExternal = isExternal;
      node.dependencies.addAll(dependencies);
      node.parts.addAll(parts);
    }
  }

  @override
  void writeAdditionalExports(List<Reference> additionalExports) {
    super.writeAdditionalExports(
        insideIncludedLibrary ? additionalExports : const <Reference>[]);
  }

  @override
  void writeLibraries(Program program) {
    for (var library in program.libraries) {
      if (isIncluded(library.importUri) || data.isLibraryUsed(library)) {
        librariesToWrite.add(library);
      }
    }
    writeList(librariesToWrite, writeNode);
  }

  @override
  void writeNodeList(List<Node> nodes) {
    if (nodes.isEmpty) {
      super.writeNodeList(nodes);
    } else {
      var newNodes = <Node>[];
      for (var node in nodes) {
        if (node is Class) {
          if (data.isClassUsed(node)) {
            newNodes.add(node);
          }
        } else if (node is Member) {
          if (data.isMemberUsed(node)) {
            newNodes.add(node);
          }
        } else if (node is Typedef) {
          if (data.isTypedefUsed(node)) {
            newNodes.add(node);
          }
        } else {
          newNodes.add(node);
        }
      }
      super.writeNodeList(newNodes);
    }
  }

  @override
  void writeProgramIndex(Program program, List<Library> libraries) {
    super.writeProgramIndex(program, librariesToWrite);
  }

  @override
  writeVariableDeclaration(VariableDeclaration node) {
    if (data.isParameterInitializerUsed(node)) {
      super.writeVariableDeclaration(node);
    } else {
      var initializer = node.initializer;
      node.initializer = null;
      super.writeVariableDeclaration(node);
      node.initializer = initializer;
    }
  }
}

/// A helper visitor used to mark transitive types by the [_RetainedDataBuilder].
class _TypeMarker extends DartTypeVisitor {
  _RetainedDataBuilder data;

  _TypeMarker(this.data);

  visitFunctionType(FunctionType node) {
    node.typeParameters.forEach((t) => t.bound.accept(this));
    node.positionalParameters.forEach((t) => t.accept(this));
    node.namedParameters.forEach((t) => t.type.accept(this));
    node.returnType.accept(this);
    data.markTypedef(node.typedefReference?.asTypedef);
  }

  visitInterfaceType(InterfaceType node) {
    data.markClass(node.classNode);
    node.typeArguments.forEach((t) => t.accept(this));
  }

  visitTypedefType(TypedefType node) {
    node.typeArguments.forEach((t) => t.accept(this));
  }

  visitTypeParameterType(TypeParameterType node) {
    // Note: node.parameter is marked by marking the enclosing element.
  }
}
