// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'dart:collection' show Queue;

import 'package:kernel/ast.dart' as ir;
import 'package:kernel/verifier.dart' show CheckParentPointers;

import '../common.dart';
import '../common/names.dart';
import '../compiler.dart' show Compiler;
import '../constants/expressions.dart'
    show ConstantExpression, TypeConstantExpression;
import '../elements/resolution_types.dart'
    show
        ResolutionDartType,
        ResolutionFunctionType,
        ResolutionInterfaceType,
        ResolutionTypeKind,
        ResolutionTypeVariableType;
import '../diagnostics/messages.dart' show MessageKind;
import '../diagnostics/spannable.dart' show Spannable;
import '../elements/elements.dart'
    show
        ClassElement,
        ConstructorElement,
        Element,
        ExportElement,
        FieldElement,
        FunctionElement,
        ImportElement,
        LibraryElement,
        LocalFunctionElement,
        MetadataAnnotation,
        MixinApplicationElement,
        TypeVariableElement;
import '../elements/entities.dart' show LibraryEntity;
import '../elements/modelx.dart' show ErroneousFieldElementX;
import '../tree/tree.dart' show FunctionExpression, Node;
import 'constant_visitor.dart';
import 'kernel_visitor.dart' show IrFunction, KernelVisitor;

typedef void WorkAction();

class WorkItem {
  final Element element;
  final WorkAction action;

  WorkItem(this.element, this.action);
}

class Kernel {
  final Compiler compiler;

  final Map<LibraryElement, ir.Library> libraries =
      <LibraryElement, ir.Library>{};

  final Map<ClassElement, ir.Class> classes = <ClassElement, ir.Class>{};

  final Map<FunctionElement, ir.Member> functions =
      <FunctionElement, ir.Member>{};

  final Map<LocalFunctionElement, ir.Node> localFunctions =
      <LocalFunctionElement, ir.Node>{};

  final Map<FieldElement, ir.Field> fields = <FieldElement, ir.Field>{};

  final Map<TypeVariableElement, ir.TypeParameter> typeParameters =
      <TypeVariableElement, ir.TypeParameter>{};

  final Map<TypeVariableElement, ir.TypeParameter> factoryTypeParameters =
      <TypeVariableElement, ir.TypeParameter>{};

  final Set<ir.TreeNode> checkedNodes = new Set<ir.TreeNode>();

  final Map<LibraryElement, Map<String, int>> mixinApplicationNamesByLibrary =
      <LibraryElement, Map<String, int>>{};

  final Map<ir.Node, Element> nodeToElement = <ir.Node, Element>{};
  final Map<ir.Node, Node> nodeToAst = <ir.Node, Node>{};
  final Map<ir.Node, Node> nodeToAstOperator = <ir.Node, Node>{};
  // Synthetic nodes are nodes we generated that do not correspond to
  // [ast.Node]s. A node should be in one of nodeToAst or syntheticNodes but not
  // both.
  final Set<ir.Node> syntheticNodes = new Set<ir.Node>();

  final Map<ir.Node, ConstantExpression> parameterInitializerNodeToConstant =
      <ir.Node, ConstantExpression>{};

  /// FIFO queue of work that needs to be completed before the returned AST
  /// nodes are correct.
  final Queue<WorkItem> workQueue = new Queue<WorkItem>();

  Kernel(this.compiler);

  void addWork(Element element, WorkAction action) {
    workQueue.addLast(new WorkItem(element, action));
  }

  void checkMember(Element key, ir.TreeNode value) {
    if (!checkedNodes.add(value)) return;
    if (value.parent == null) {
      internalError(key, "Missing parent on IR node.");
    }
    try {
      CheckParentPointers.check(value);
    } catch (e, s) {
      internalError(key, "$e\n$s");
    }
  }

  void checkLibrary(Element key, ir.Library library) {
    if (!checkedNodes.add(library)) return;
    CheckParentPointers.check(library);
  }

  void processWorkQueue() {
    while (workQueue.isNotEmpty) {
      WorkItem work = workQueue.removeFirst();
      work.action();
    }
    assert(() {
      libraries.forEach(checkLibrary);
      classes.forEach(checkMember);
      functions.forEach(checkMember);
      fields.forEach(checkMember);
      return true;
    });
  }

  ir.Name irName(String name, Element element) {
    ir.Library irLibrary = null;
    if (name.startsWith("_")) {
      ClassElement cls = element.enclosingClass;
      if (cls != null && cls.isMixinApplication) {
        MixinApplicationElement mixinApplication = cls;
        element = mixinApplication.mixin;
      }
      irLibrary = libraryToIr(element.library);
    }
    return new ir.Name(name, irLibrary);
  }

  ir.Library libraryToIr(LibraryElement library) {
    library = library.declaration;
    return libraries.putIfAbsent(library, () {
      String name = library.hasLibraryName ? library.libraryName : null;
      ir.Library libraryNode = new ir.Library(library.canonicalUri,
          name: name, classes: null, procedures: null, fields: null);
      addWork(library, () {
        Queue<ir.Class> classes = new Queue<ir.Class>();
        Queue<ir.Member> members = new Queue<ir.Member>();
        library.implementation.forEachLocalMember((Element e) {
          if (e.isClass) {
            ClassElement cls = e;
            if (!cls.isResolved) return;
            classes.addFirst(classToIr(cls));
          } else if (e.isFunction || e.isAccessor) {
            if (!compiler.resolution.hasBeenResolved(e) && !e.isMalformed) {
              return;
            }
            members.addFirst(functionToIr(e));
          } else if (e.isField) {
            if (!compiler.resolution.hasBeenResolved(e) && !e.isMalformed) {
              return;
            }
            members.addFirst(fieldToIr(e));
          } else if (e.isTypedef) {
            // Ignored, typedefs are unaliased on use.
          } else {
            internalError(e, "Unhandled library member: $e");
          }
        });
        // The elements were inserted in reverse order as forEachLocalMember
        // above gives them in reversed order.
        classes.forEach(libraryNode.addClass);
        members.forEach(libraryNode.addMember);
        // TODO(sigmund): include combinators, etc.
        library.imports.forEach((ImportElement import) {
          libraryNode.addDependency(new ir.LibraryDependency.import(
              libraryToIr(import.importedLibrary)));
        });
        library.exports.forEach((ExportElement export) {
          libraryNode.addDependency(new ir.LibraryDependency.export(
              libraryToIr(export.exportedLibrary)));
        });
      });
      return libraryNode;
    });
  }

  /// Compute a name for [cls]. We want to have unique names in a library, but
  /// mixin applications can lead to multiple classes with the same name. So
  /// for those we append `#` and a number.
  String computeName(ClassElement cls) {
    String name = cls.name;
    if (!cls.isUnnamedMixinApplication) return name;
    Map<String, int> mixinApplicationNames = mixinApplicationNamesByLibrary
        .putIfAbsent(cls.library.implementation, () => <String, int>{});
    int count = mixinApplicationNames.putIfAbsent(name, () => 0);
    mixinApplicationNames[name] = count + 1;
    return "$name#$count";
  }

  ir.Class classToIr(ClassElement cls) {
    cls = cls.declaration;
    return classes.putIfAbsent(cls, () {
      assert(cls.isResolved);
      String name = computeName(cls);
      ir.Class classNode = new ir.Class(
          name: name,
          isAbstract: cls.isAbstract,
          typeParameters: null,
          implementedTypes: null,
          constructors: null,
          procedures: null,
          fields: null);
      addWork(cls, () {
        if (cls.supertype != null) {
          classNode.supertype = supertypeToIr(cls.supertype);
        }
        if (cls.isMixinApplication) {
          MixinApplicationElement mixinApplication = cls;
          classNode.mixedInType = supertypeToIr(mixinApplication.mixinType);
        }
        classNode.parent = libraryToIr(cls.library);
        if (cls.isUnnamedMixinApplication) {
          classNode.enclosingLibrary.addClass(classNode);
        }
        cls.implementation
            .forEachMember((ClassElement enclosingClass, Element member) {
          if (!compiler.resolution.hasBeenResolved(member) &&
              !member.isMalformed) {
            return;
          }
          if (member.enclosingClass.declaration != cls) {
            // TODO(het): figure out why impact_test triggers this
            //internalError(cls, "`$member` isn't mine.");
          } else if (member.isConstructor) {
            ConstructorElement constructor = member;
            ir.Member memberNode = functionToIr(member);
            if (!constructor.isRedirectingFactory) {
              classNode.addMember(memberNode);
            }
          } else if (member.isFunction || member.isAccessor) {
            classNode.addMember(functionToIr(member));
          } else if (member.isField) {
            classNode.addMember(fieldToIr(member));
          } else {
            internalError(member, "Unhandled class member: $member");
          }
        });
        classNode.typeParameters.addAll(typeVariablesToIr(cls.typeVariables));
        for (ir.Supertype supertype
            in supertypesToIr(cls.interfaces.reverse().toList())) {
          if (supertype != classNode.mixedInType) {
            classNode.implementedTypes.add(supertype);
          }
        }
        addWork(cls, () {
          addDefaultInstanceFieldInitializers(classNode);
        });
      });
      addWork(cls.declaration, () {
        for (MetadataAnnotation metadata in cls.implementation.metadata) {
          classNode.addAnnotation(
              const ConstantVisitor().visit(metadata.constant, this));
        }
      });
      return classNode;
    });
  }

  /// Adds initializers to instance fields that are have no initializer and are
  /// not initialized by all constructors in the class.
  ///
  /// This is more or less copied directly from `ast_from_analyzer.dart` in
  /// dartk.
  void addDefaultInstanceFieldInitializers(ir.Class node) {
    List<ir.Field> uninitializedFields = new List<ir.Field>();
    for (ir.Field field in node.fields) {
      if (field.initializer != null || field.isStatic) continue;
      uninitializedFields.add(field);
    }
    if (uninitializedFields.isEmpty) return;
    constructorLoop:
    for (ir.Constructor constructor in node.constructors) {
      Set<ir.Field> remainingFields = uninitializedFields.toSet();
      for (ir.Initializer initializer in constructor.initializers) {
        if (initializer is ir.FieldInitializer) {
          remainingFields.remove(initializer.field);
        } else if (initializer is ir.RedirectingInitializer) {
          // The target constructor will be checked in another iteration.
          continue constructorLoop;
        }
      }
      for (ir.Field field in remainingFields) {
        if (field.initializer == null) {
          field.initializer = new ir.NullLiteral()..parent = field;
        }
      }
    }
  }

  bool hasHierarchyProblem(ClassElement cls) => cls.hasIncompleteHierarchy;

  ir.InterfaceType interfaceTypeToIr(ResolutionInterfaceType type) {
    ir.Class cls = classToIr(type.element);
    if (type.typeArguments.isEmpty) {
      return cls.rawType;
    } else {
      return new ir.InterfaceType(cls, typesToIr(type.typeArguments));
    }
  }

  ir.Supertype supertypeToIr(ResolutionInterfaceType type) {
    ir.Class cls = classToIr(type.element);
    if (type.typeArguments.isEmpty) {
      return cls.asRawSupertype;
    } else {
      return new ir.Supertype(cls, typesToIr(type.typeArguments));
    }
  }

  ir.FunctionType functionTypeToIr(ResolutionFunctionType type) {
    List<ir.TypeParameter> typeParameters = <ir.TypeParameter>[];
    int requiredParameterCount = type.parameterTypes.length;
    List<ir.DartType> positionalParameters =
        new List<ir.DartType>.from(typesToIr(type.parameterTypes))
          ..addAll(typesToIr(type.optionalParameterTypes));
    List<ir.NamedType> namedParameters = new List<ir.NamedType>.generate(
        type.namedParameters.length,
        (i) => new ir.NamedType(
            type.namedParameters[i], typeToIr(type.namedParameterTypes[i])));
    ir.DartType returnType = typeToIr(type.returnType);

    return new ir.FunctionType(positionalParameters, returnType,
        namedParameters: namedParameters,
        typeParameters: typeParameters,
        requiredParameterCount: requiredParameterCount);
  }

  ir.TypeParameterType typeVariableTypeToIr(ResolutionTypeVariableType type) {
    return new ir.TypeParameterType(typeVariableToIr(type.element));
  }

  List<ir.DartType> typesToIr(List<ResolutionDartType> types) {
    List<ir.DartType> result = new List<ir.DartType>(types.length);
    for (int i = 0; i < types.length; i++) {
      result[i] = typeToIr(types[i]);
    }
    return result;
  }

  List<ir.Supertype> supertypesToIr(List<ResolutionDartType> types) {
    List<ir.Supertype> result = new List<ir.Supertype>(types.length);
    for (int i = 0; i < types.length; i++) {
      result[i] = supertypeToIr(types[i]);
    }
    return result;
  }

  // ignore: MISSING_RETURN
  ir.DartType typeToIr(ResolutionDartType type) {
    switch (type.kind) {
      case ResolutionTypeKind.FUNCTION:
        return functionTypeToIr(type);

      case ResolutionTypeKind.INTERFACE:
        return interfaceTypeToIr(type);

      case ResolutionTypeKind.TYPEDEF:
        type.computeUnaliased(compiler.resolution);
        return typeToIr(type.unaliased);

      case ResolutionTypeKind.TYPE_VARIABLE:
        return typeVariableTypeToIr(type);

      case ResolutionTypeKind.MALFORMED_TYPE:
        return const ir.InvalidType();

      case ResolutionTypeKind.DYNAMIC:
        return const ir.DynamicType();

      case ResolutionTypeKind.VOID:
        return const ir.VoidType();
    }
  }

  ir.DartType typeLiteralToIr(TypeConstantExpression constant) {
    return typeToIr(constant.type);
  }

  void setParent(ir.Member member, Element element) {
    if (element.isLocal) {
      member.parent = elementToIr(element.enclosingElement);
    } else if (element.isTopLevel) {
      member.parent = elementToIr(element.library);
    } else if (element.isClassMember) {
      member.parent = elementToIr(element.enclosingClass);
    } else {
      member.parent = elementToIr(element.enclosingElement);
    }
  }

  bool isNativeMethod(FunctionElement element) {
    // This method is a (modified) copy of the same method in
    // `pkg/compiler/lib/src/native/enqueue.dart`.
    if (!compiler.backend.canLibraryUseNative(element.library)) return false;
    return compiler.reporter.withCurrentElement(element, () {
      FunctionExpression functionExpression =
          element.node?.asFunctionExpression();
      if (functionExpression == null) return false;
      Node body = functionExpression.body;
      if (body == null) return false;
      if (identical(body.getBeginToken().stringValue, 'native')) return true;
      return false;
    });
  }

  ir.Member functionToIr(FunctionElement function) {
    if (function.isDeferredLoaderGetter) {
      internalError(function, "Deferred loader.");
    }
    if (function.isLocal) {
      internalError(function, "Local function.");
    }
    if (isSyntheticError(function)) {
      internalError(function, "Synthetic error function: $function.");
    }
    function = function.declaration;
    return functions.putIfAbsent(function, () {
      assert(compiler.resolution.hasBeenResolved(function) ||
          function.isMalformed);
      function = function.implementation;
      ir.Member member;
      ir.Constructor constructor;
      ir.Procedure procedure;
      ir.Name name = irName(function.name, function);
      bool isNative = isNativeMethod(function);
      if (function.isGenerativeConstructor) {
        ConstructorElement constructorElement = function;
        member = constructor = new ir.Constructor(null,
            name: name,
            isConst: constructorElement.isConst,
            isExternal: isNative || constructorElement.isExternal,
            initializers: null,
            isSyntheticDefault: constructorElement.isDefaultConstructor);
      } else {
        member = procedure = new ir.Procedure(name, null, null,
            isAbstract: function.isAbstract,
            isStatic: function.isStatic ||
                function.isTopLevel ||
                function.isFactoryConstructor,
            isExternal: isNative || function.isExternal,
            isConst: false); // TODO(ahe): When is this true?
      }
      addWork(function, () {
        setParent(member, function);
        KernelVisitor visitor =
            new KernelVisitor(function, function.treeElements, this);
        beginFactoryScope(function);
        IrFunction irFunction = visitor.buildFunction();
        // TODO(ahe): Add addFunction/set function to [ir.Procedure].
        irFunction.node.parent = member;
        if (irFunction.isConstructor) {
          assert(irFunction.kind == null);
          constructor.function = irFunction.node;
          constructor.initializers = irFunction.initializers;
          // TODO(ahe): Add setInitializers to [ir.Constructor].
          for (ir.Initializer initializer in irFunction.initializers) {
            initializer.parent = constructor;
          }
        } else {
          assert(irFunction.kind != null);
          procedure.function = irFunction.node;
          procedure.kind = irFunction.kind;
        }
        endFactoryScope(function);
        irFunction.node.typeParameters
            .addAll(typeVariablesToIr(function.typeVariables));
        member.transformerFlags = visitor.transformerFlags;
        assert(() {
          visitor.locals.forEach(checkMember);
          return true;
        });
      });
      addWork(function.declaration, () {
        for (MetadataAnnotation metadata in function.implementation.metadata) {
          member.addAnnotation(
              const ConstantVisitor().visit(metadata.constant, this));
        }
      });
      return member;
    });
  }

  /// Adds the type parameters of the enclosing class of [function] to
  /// [factoryTypeParameters]. This serves as a local scope for type variables
  /// resolved inside the factory.
  ///
  /// This method solves the problem that a factory method really is a generic
  /// method that has its own type parameters, one for each type parameter in
  /// the enclosing class.
  void beginFactoryScope(FunctionElement function) {
    assert(factoryTypeParameters.isEmpty);
    if (!function.isFactoryConstructor) return;
    ClassElement cls = function.enclosingClass;
    for (ResolutionDartType type in cls.typeVariables) {
      if (type.isTypeVariable) {
        TypeVariableElement variable = type.element;
        factoryTypeParameters[variable] =
            new ir.TypeParameter(variable.name, null);
      }
    }
    for (ResolutionDartType type in cls.typeVariables) {
      if (type.isTypeVariable) {
        TypeVariableElement variable = type.element;
        factoryTypeParameters[variable].bound = typeToIr(variable.bound);
      }
    }
  }

  /// Ends the local scope started by [beginFactoryScope].
  void endFactoryScope(FunctionElement function) {
    factoryTypeParameters.clear();
  }

  ir.Field fieldToIr(FieldElement field) {
    if (isSyntheticError(field)) {
      internalError(field, "Synthetic error field: $field.");
    }
    field = field.declaration;
    return fields.putIfAbsent(field, () {
      // TODO(sigmund): remove `ensureResolved` here.  It appears we hit this
      // case only in metadata: when a constant has a field that is never read,
      // but it is initialized in the constant constructor.
      compiler.resolution.ensureResolved(field);
      compiler.enqueuer.resolution.emptyDeferredQueueForTesting();
      assert(compiler.resolution.hasBeenResolved(field) || field.isMalformed);

      field = field.implementation;
      ir.DartType type =
          field.isMalformed ? const ir.InvalidType() : typeToIr(field.type);
      ir.Field fieldNode = new ir.Field(irName(field.memberName.text, field),
          type: type,
          initializer: null,
          isFinal: field.isFinal,
          isStatic: field.isStatic || field.isTopLevel,
          isConst: field.isConst);
      addWork(field, () {
        setParent(fieldNode, field);
        if (!field.isMalformed) {
          if (field.initializer != null) {
            KernelVisitor visitor =
                new KernelVisitor(field, field.treeElements, this);
            fieldNode.initializer = visitor.buildInitializer()
              ..parent = fieldNode;
          } else if (!field.isInstanceMember) {
            fieldNode.initializer = new ir.NullLiteral()..parent = fieldNode;
          }
        }
      });
      addWork(field.declaration, () {
        for (MetadataAnnotation metadata in field.implementation.metadata) {
          fieldNode.addAnnotation(
              const ConstantVisitor().visit(metadata.constant, this));
        }
      });
      return fieldNode;
    });
  }

  ir.TypeParameter typeVariableToIr(TypeVariableElement variable) {
    variable = variable.declaration;
    ir.TypeParameter parameter = factoryTypeParameters[variable];
    if (parameter != null) return parameter;
    return typeParameters.putIfAbsent(variable, () {
      ir.TypeParameter parameter = new ir.TypeParameter(variable.name, null);
      addWork(variable, () {
        if (variable.typeDeclaration.isClass) {
          ClassElement cls = variable.typeDeclaration;
          assert(cls.isResolved);
          parameter.parent = classToIr(cls);
        } else {
          FunctionElement method = variable.typeDeclaration;
          parameter.parent = functionToIr(method).function;
        }
        parameter.bound = typeToIr(variable.bound);
      });
      return parameter;
    });
  }

  List<ir.TypeParameter> typeVariablesToIr(List<ResolutionDartType> variables) {
    List<ir.TypeParameter> result =
        new List<ir.TypeParameter>(variables.length);
    for (int i = 0; i < variables.length; i++) {
      ResolutionTypeVariableType type = variables[i];
      result[i] = typeVariableToIr(type.element);
    }
    return result;
  }

  ir.TreeNode elementToIr(Element element) {
    if (element.isLibrary) return libraryToIr(element);
    if (element.isClass) return classToIr(element);
    if (element.isFunction || element.isAccessor) return functionToIr(element);
    if (element.isField) return fieldToIr(element);
    throw "unhandled element: $element";
  }

  void debugMessage(Spannable spannable, String message) {
    compiler.reporter
        .reportHintMessage(spannable, MessageKind.GENERIC, {'text': message});
  }

  void internalError(Spannable spannable, String message) {
    compiler.reporter.internalError(spannable, message);
    throw message;
  }

  forEachLibraryElement(f(LibraryEntity library)) {
    return compiler.libraryLoader.libraries.forEach(f);
  }

  ConstructorTarget computeEffectiveTarget(
      ConstructorElement constructor, ResolutionDartType type) {
    constructor = constructor.implementation;
    Set<ConstructorElement> seen = new Set<ConstructorElement>();
    functionToIr(constructor);
    while (constructor != constructor.effectiveTarget) {
      type = constructor.computeEffectiveTargetType(type);
      if (constructor.isGenerativeConstructor) break;
      if (!seen.add(constructor)) break;
      constructor = constructor.effectiveTarget.implementation;
      if (isSyntheticError(constructor)) break;
      functionToIr(constructor);
    }
    return new ConstructorTarget(constructor, type);
  }

  /// Compute all the dependencies on the library with [uri] (including the
  /// library itself). This is useful for creating a Kernel IR `Program`.
  List<ir.Library> libraryDependencies(Uri uri) {
    List<ir.Library> result = <ir.Library>[];
    Queue<LibraryElement> notProcessed = new Queue<LibraryElement>();
    Set<LibraryElement> seen = new Set<LibraryElement>();
    LibraryElement library = compiler.libraryLoader.lookupLibrary(uri);
    void processLater(LibraryElement library) {
      if (library != null) {
        notProcessed.addLast(library);
      }
    }

    processLater(library);
    seen.add(library);
    LibraryElement core =
        compiler.libraryLoader.lookupLibrary(Uri.parse("dart:core"));
    if (seen.add(core)) {
      // `dart:core` is implicitly imported by most libraries, and for some
      // reason not included in `library.imports` below.
      processLater(core);
    }
    while (notProcessed.isNotEmpty) {
      LibraryElement library = notProcessed.removeFirst();
      ir.Library irLibrary = libraryToIr(library);
      for (ImportElement import in library.imports) {
        if (seen.add(import.importedLibrary)) {
          processLater(import.importedLibrary);
        }
      }
      for (ExportElement export in library.exports) {
        if (seen.add(export.exportedLibrary)) {
          processLater(export.exportedLibrary);
        }
      }
      for (ImportElement import in library.implementation.imports) {
        if (seen.add(import.importedLibrary)) {
          processLater(import.importedLibrary);
        }
      }
      for (ExportElement export in library.implementation.exports) {
        if (seen.add(export.exportedLibrary)) {
          processLater(export.exportedLibrary);
        }
      }
      if (irLibrary != null) {
        result.add(irLibrary);
      }
    }
    processWorkQueue();
    return result;
  }

  /// Returns true if [element] is synthesized to recover or represent a
  /// semantic error, for example, missing, duplicated, or ambiguous elements.
  /// However, returns false for elements that have an unrecoverable syntax
  /// error. Both kinds of element will return true from [Element.isMalformed],
  /// but they must be handled differently. For example, a static call to
  /// synthetic error element should be compiled to [ir.InvalidExpression],
  /// whereas a static call to a method which has a syntax error should be
  /// compiled to a static call to the method. The method itself will have a
  /// method body that is [ir.InvalidStatement].
  bool isSyntheticError(Element element) {
    if (element.isAmbiguous) return true;
    if (element.isError) return true;
    if (element.isField && element is ErroneousFieldElementX) {
      return true;
    }
    return false;
  }

  ir.Constructor getDartCoreConstructor(
      String className, String constructorName) {
    LibraryElement library =
        compiler.libraryLoader.lookupLibrary(Uris.dart_core);
    ClassElement cls = library.implementation.localLookup(className);
    cls.ensureResolved(compiler.resolution);
    assert(
        cls != null,
        failedAt(CURRENT_ELEMENT_SPANNABLE,
            'dart:core class $className not found.'));
    ConstructorElement constructor = cls.lookupConstructor(constructorName);
    assert(
        constructor != null,
        failedAt(CURRENT_ELEMENT_SPANNABLE,
            "Constructor '$constructorName' not found in class '$className'."));
    compiler.resolution.ensureResolved(constructor);
    return functionToIr(constructor);
  }

  ir.Procedure getDartCoreMethod(String name) {
    LibraryElement library =
        compiler.libraryLoader.lookupLibrary(Uris.dart_core);
    Element function = library.implementation.localLookup(name);
    assert(
        function != null,
        failedAt(
            CURRENT_ELEMENT_SPANNABLE, "dart:core method '$name' not found."));
    compiler.resolution.ensureResolved(function);
    return functionToIr(function);
  }

  ir.Procedure getMalformedTypeErrorBuilder() {
    return getDartCoreMethod('_malformedTypeError');
  }

  ir.Procedure getUnresolvedConstructorBuilder() {
    return getDartCoreMethod('_unresolvedConstructorError');
  }

  ir.Procedure getUnresolvedStaticGetterBuilder() {
    return getDartCoreMethod('_unresolvedStaticGetterError');
  }

  ir.Procedure getUnresolvedStaticSetterBuilder() {
    return getDartCoreMethod('_unresolvedStaticSetterError');
  }

  ir.Procedure getUnresolvedStaticMethodBuilder() {
    return getDartCoreMethod('_unresolvedStaticMethodError');
  }

  ir.Procedure getUnresolvedTopLevelGetterBuilder() {
    return getDartCoreMethod('_unresolvedTopLevelGetterError');
  }

  ir.Procedure getUnresolvedTopLevelSetterBuilder() {
    return getDartCoreMethod('_unresolvedTopLevelSetterError');
  }

  ir.Procedure getUnresolvedTopLevelMethodBuilder() {
    return getDartCoreMethod('_unresolvedTopLevelMethodError');
  }

  ir.Procedure getUnresolvedSuperGetterBuilder() {
    return getDartCoreMethod('_unresolvedSuperGetterError');
  }

  ir.Procedure getUnresolvedSuperSetterBuilder() {
    return getDartCoreMethod('_unresolvedSuperSetterError');
  }

  ir.Procedure getUnresolvedSuperMethodBuilder() {
    return getDartCoreMethod('_unresolvedSuperMethodError');
  }

  ir.Procedure getGenericNoSuchMethodBuilder() {
    return getDartCoreMethod('_genericNoSuchMethod');
  }

  ir.Constructor getFallThroughErrorConstructor() {
    return getDartCoreConstructor('FallThroughError', '');
  }
}

class ConstructorTarget {
  final ConstructorElement element;
  final ResolutionDartType type;

  ConstructorTarget(this.element, this.type);

  String toString() => "ConstructorTarget($element, $type)";
}
