// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of js_backend;

/**
 * Support for Custom Elements.
 *
 * The support for custom elements the compiler builds a table that maps the
 * custom element class's [Type] to the interceptor for the class and the
 * constructor(s) for the class.
 *
 * We want the table to contain only the custom element classes used, and we
 * want to avoid resolving and compiling constructors that are not used since
 * that may bring in unused code.  This class controls the resolution and code
 * generation to restrict the impact.
 *
 * The following line of code requires the generation of the generative
 * constructor factory function(s) for FancyButton, and their insertion into the
 * table:
 *
 *     document.register(FancyButton, 'x-fancy-button');
 *
 * We detect this by 'joining' the classes that are referenced as type literals
 * with the classes that are custom elements, enabled by detecting the presence
 * of the table access code used by document.register.
 *
 * We have to be more conservative when the type is unknown, e.g.
 *
 *     document.register(classMirror.reflectedType, tagFromMetadata);
 *
 * and
 *
 *     class Component<T> {
 *       final tag;
 *       Component(this.tag);
 *       void register() => document.register(T, tag);
 *     }
 *     const Component<FancyButton>('x-fancy-button').register();
 *
 * In these cases we conservatively generate all viable entries in the table.
 */
class CustomElementsAnalysis {
  final JavaScriptBackend backend;
  final Compiler compiler;
  final CustomElementsAnalysisJoin resolutionJoin;
  final CustomElementsAnalysisJoin codegenJoin;
  bool fetchedTableAccessorMethod = false;
  Element tableAccessorMethod;

  CustomElementsAnalysis(JavaScriptBackend backend)
      : this.backend = backend,
        this.compiler = backend.compiler,
        resolutionJoin = new CustomElementsAnalysisJoin(backend),
        codegenJoin = new CustomElementsAnalysisJoin(backend) {
    // TODO(sra): Remove this work-around.  We should mark allClassesSelected in
    // both joins only when we see a construct generating an unknown [Type] but
    // we can't currently recognize all cases.  In particular, the work-around
    // for the unimplemented `ClassMirror.reflectedType` is not recognizable.
    // TODO(12607): Match on [ClassMirror.reflectedType]
    resolutionJoin.allClassesSelected = true;
    codegenJoin.allClassesSelected = true;
  }

  CustomElementsAnalysisJoin joinFor(Enqueuer enqueuer) =>
      enqueuer.isResolutionQueue ? resolutionJoin : codegenJoin;

  void registerInstantiatedClass(ClassElement classElement, Enqueuer enqueuer) {
    classElement.ensureResolved(compiler);
    if (!Elements.isNativeOrExtendsNative(classElement)) return;
    if (classElement.isMixinApplication) return;
    joinFor(enqueuer).instantiatedClasses.add(classElement);
  }

  void registerTypeLiteral(DartType type, Registry registry) {
    assert(registry.isForResolution);
    // In codegen we see the TypeConstants instead.
    if (!registry.isForResolution) return;

    if (type.isInterfaceType) {
      // TODO(sra): If we had a flow query from the type literal expression to
      // the Type argument of the metadata lookup, we could tell if this type
      // literal is really a demand for the metadata.
      resolutionJoin.selectedClasses.add(type.element);
    } else if (type.isTypeVariable) {
      // This is a type parameter of a parameterized class.
      // TODO(sra): Is there a way to determine which types are bound to the
      // parameter?
      resolutionJoin.allClassesSelected = true;
    }
  }

  void registerTypeConstant(Element element, Enqueuer enqueuer) {
    assert(element.isClass);
    assert(!enqueuer.isResolutionQueue);
    codegenJoin.selectedClasses.add(element);
  }

  void registerStaticUse(Element element, Enqueuer enqueuer) {
    assert(element != null);
    if (!fetchedTableAccessorMethod) {
      fetchedTableAccessorMethod = true;
      tableAccessorMethod = backend.findInterceptor(
          'findIndexForNativeSubclassType');
    }
    if (element == tableAccessorMethod) {
      joinFor(enqueuer).demanded = true;
    }
  }

  void onQueueEmpty(Enqueuer enqueuer) {
    joinFor(enqueuer).flush(enqueuer);
  }

  bool get needsTable => codegenJoin.demanded;

  bool needsClass(ClassElement classElement) =>
      codegenJoin.activeClasses.contains(classElement);

  List<Element> constructors(ClassElement classElement) =>
      codegenJoin.escapingConstructors(classElement);
}


class CustomElementsAnalysisJoin {
  final JavaScriptBackend backend;
  Compiler get compiler => backend.compiler;

  // Classes that are candidates for needing constructors.  Classes are moved to
  // [activeClasses] when we know they need constructors.
  final instantiatedClasses = new Set<ClassElement>();

  // Classes explicitly named.
  final selectedClasses = new Set<ClassElement>();

  // True if we must conservatively include all extension classes.
  bool allClassesSelected = false;

  // Did we see a demand for the data?
  bool demanded = false;

  // ClassesOutput: classes requiring metadata.
  final activeClasses = new Set<ClassElement>();

  CustomElementsAnalysisJoin(this.backend);

  void flush(Enqueuer enqueuer) {
    if (!demanded) return;
    var newActiveClasses = new Set<ClassElement>();
    for (ClassElement classElement in instantiatedClasses) {
      bool isNative = classElement.isNative;
      bool isExtension =
          !isNative && Elements.isNativeOrExtendsNative(classElement);
      // Generate table entries for native classes that are explicitly named and
      // extensions that fix our criteria.
      if ((isNative && selectedClasses.contains(classElement)) ||
          (isExtension &&
              (allClassesSelected || selectedClasses.contains(classElement)))) {
        newActiveClasses.add(classElement);
        escapingConstructors(classElement).forEach(enqueuer.registerStaticUse);
        // Force the generaton of the type constant that is the key to an entry
        // in the generated table.
        Constant constant = makeTypeConstant(classElement);
        backend.registerCompileTimeConstant(
            constant, compiler.globalDependencies);
        backend.constants.addCompileTimeConstantForEmission(constant);
      }
    }
    activeClasses.addAll(newActiveClasses);
    instantiatedClasses.removeAll(newActiveClasses);
  }

  TypeConstant makeTypeConstant(ClassElement element) {
    DartType elementType = element.rawType;
    DartType constantType = backend.typeImplementation.rawType;
    return new TypeConstant(elementType, constantType);
  }

  List<Element> escapingConstructors(ClassElement classElement) {
    List<Element> result = <Element>[];
    // Only classes that extend native classes have constructors in the table.
    // We could refine this to classes that extend Element, but that would break
    // the tests and there is no sane reason to subclass other native classes.
    if (classElement.isNative) return result;

    selectGenerativeConstructors(ClassElement enclosing, Element member) {
      if (member.isGenerativeConstructor) {
        // Ignore constructors that cannot be called with zero arguments.
        FunctionElement constructor = member;
        FunctionSignature parameters = constructor.functionSignature;
        if (parameters.requiredParameterCount == 0) {
          result.add(member);
        }
      }
    }
    classElement.forEachMember(selectGenerativeConstructors,
        includeBackendMembers: false,
        includeSuperAndInjectedMembers: false);
    return result;
  }
}
