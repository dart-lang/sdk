// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This library contains the infrastructure to parse and integrate patch files.
 *
 * Three types of elements can be patched: [LibraryElement], [ClassElement],
 * [FunctionElement]. Patches are introduced in patch libraries which are loaded
 * together with the corresponding origin library. Which libraries that are
 * patched is determined by the dart2jsPatchPath field of LibraryInfo found
 * in [:lib/_internal/sdk_library_metadata/lib/libraries.dart:].
 *
 * Patch libraries are parsed like regular library and thus provided with their
 * own elements. These elements which are distinct from the elements from the
 * patched library and the relation between patched and patch elements is
 * established through the [:patch:] and [:origin:] fields found on
 * [LibraryElement], [ClassElement] and [FunctionElement]. The [:patch:] fields
 * are set on the patched elements to point to their corresponding patch
 * element, and the [:origin:] elements are set on the patch elements to point
 * their corresponding patched elements.
 *
 * The fields [Element.isPatched] and [Element.isPatch] can be used to determine
 * whether the [:patch:] or [:origin:] field, respectively, has been set on an
 * element, regardless of whether the element is one of the three patchable
 * element types or not.
 *
 * ## Variants of classes and functions ##
 *
 * With patches there are four variants of classes and function:
 *
 * Regular: A class or function which is not declared in a patch library and
 *   which has no corresponding patch.
 * Origin: A class or function which is not declared in a patch library and
 *   which has a corresponding patch. Origin functions must use the [:external:]
 *   modifier and can have no body. Origin classes and functions are also
 *   called 'patched'.
 * Patch: A class or function which is declared in a patch library and which
 *   has a corresponding origin. Both patch classes and patch functions must use
 *   the [:patch:] modifier.
 * Injected: A class or function (or even field) which is declared in a
 *   patch library and which has no corresponding origin. An injected element
 *   cannot use the [:patch:] modifier. Injected elements are never visible from
 *   outside the patch library in which they have been declared. For this
 *   reason, injected elements are often declared private and therefore called
 *   also called 'patch private'.
 *
 * Examples of the variants is shown in the code below:
 *
 *     // In the origin library:
 *     class RegularClass { // A regular class.
 *       void regularMethod() {} // A regular method.
 *     }
 *     class PatchedClass { // An origin class.
 *       int regularField; // A regular field.
 *       void regularMethod() {} // A regular method.
 *       external void patchedMethod(); // An origin method.
 *     }
 *
 *     // In the patch library:
 *     class _InjectedClass { // An injected class.
 *       void _injectedMethod() {} // An injected method.
 *     }
 *     @patch class PatchedClass { // A patch class.
 *       int _injectedField; { // An injected field.
 *       @patch void patchedMethod() {} // A patch method.
 *     }
 *
 *
 * ## Declaration and implementation ##
 *
 * With patches we have two views on elements: as the 'declaration' which
 * introduces the entity and defines its interface, and as the 'implementation'
 * which defines the actual implementation of the entity.
 *
 * Every element has a 'declaration' and an 'implementation' element. For
 * regular and injected elements these are the same. For origin elements the
 * declaration is the element itself and the implementation is the patch element
 * found through its [:patch:] field. For patch elements the implementation is
 * the element itself and the declaration is the origin element found through
 * its [:origin:] field. The declaration and implementation of any element is
 * conveniently available through the [Element.declaration] and
 * [Element.implementation] getters.
 *
 * Most patch-related invariants enforced through-out the compiler are defined
 * in terms of 'declaration' and 'implementation', and tested through the
 * predicate getters [Element.isDeclaration] and [Element.isImplementation].
 * Patch invariants are stated both in comments and as assertions.
 *
 *
 * ## General invariant guidelines ##
 *
 * For [LibraryElement] we always use declarations. This means the
 * [Element.getLibrary] method will only return library declarations. Patch
 * library implementations are only accessed through calls to
 * [Element.getImplementationLibrary] which is used to setup the correct
 * [Element.enclosingElement] relation between patch/injected elements and the
 * patch library.
 *
 * For [ClassElement] and [FunctionElement] we use declarations for determining
 * identity and implementations for work based on the AST nodes, such as
 * resolution, type-checking, type inference, building SSA graphs, etc.
 * - Worklist only contain declaration elements.
 * - Most maps and sets use declarations exclusively, and their individual
 *   invariants are stated in the field comments.
 * - [tree.TreeElements] only map to patch elements from inside a patch library.
 *   TODO(johnniwinther): Simplify this invariant to use only declarations in
 *   [tree.TreeElements].
 * - Builders shift between declaration and implementation depending on usages.
 * - Compile-time constants use constructor implementation exclusively.
 * - Work on function parameters is performed on the declaration of the function
 *   element.
 */

library dart2js.patchparser;

import 'dart:async';

import 'common/tasks.dart' show CompilerTask;
import 'common.dart';
import 'compiler.dart' show Compiler;
import 'constants/values.dart' show ConstantValue;
import 'dart_types.dart' show DartType;
import 'elements/elements.dart';
import 'elements/modelx.dart'
    show
        BaseFunctionElementX,
        ClassElementX,
        GetterElementX,
        LibraryElementX,
        MetadataAnnotationX,
        SetterElementX;
import 'id_generator.dart';
import 'js_backend/js_backend.dart' show JavaScriptBackend;
import 'library_loader.dart' show LibraryLoader;
import 'parser/element_listener.dart' show ElementListener;
import 'parser/listener.dart' show Listener, ParserError;
import 'parser/member_listener.dart' show MemberListener;
import 'parser/parser.dart' show Parser;
import 'parser/partial_elements.dart' show PartialClassElement;
import 'parser/partial_parser.dart' show PartialParser;
import 'scanner/scanner.dart' show Scanner;
import 'script.dart';
import 'tokens/token.dart' show StringToken, Token;

class PatchParserTask extends CompilerTask {
  final String name = "Patching Parser";
  final Compiler compiler;
  DiagnosticReporter get reporter => compiler.reporter;

  PatchParserTask(Compiler compiler)
      : compiler = compiler, super(compiler.measurer);

  /**
   * Scans a library patch file, applies the method patches and
   * injections to the library, and returns a list of class
   * patches.
   */
  Future patchLibrary(
      LibraryLoader loader, Uri patchUri, LibraryElement originLibrary) {
    return compiler.readScript(patchUri, originLibrary).then((Script script) {
      var patchLibrary = new LibraryElementX(script, null, originLibrary);
      return reporter.withCurrentElement(patchLibrary, () {
        loader.registerNewLibrary(patchLibrary);
        reporter.withCurrentElement(patchLibrary.entryCompilationUnit, () {
          // This patches the elements of the patch library into [library].
          // Injected elements are added directly under the compilation unit.
          // Patch elements are stored on the patched functions or classes.
          scanLibraryElements(patchLibrary.entryCompilationUnit);
        });
        return loader.processLibraryTags(patchLibrary);
      });
    });
  }

  void scanLibraryElements(CompilationUnitElement compilationUnit) {
    measure(() {
      // TODO(johnniwinther): Test that parts and exports are handled correctly.
      Script script = compilationUnit.script;
      Token tokens = new Scanner(script.file).tokenize();
      Listener patchListener = new PatchElementListener(
          compiler, compilationUnit, compiler.idGenerator);
      try {
        new PartialParser(patchListener).parseUnit(tokens);
      } on ParserError catch (e) {
        // No need to recover from a parser error in platform libraries, user
        // will never see this if the libraries are tested correctly.
        reporter.internalError(
            compilationUnit, "Parser error in patch file: $e");
      }
    });
  }

  void parsePatchClassNode(PartialClassElement cls) {
    // Parse [PartialClassElement] using a "patch"-aware parser instead
    // of calling its [parseNode] method.
    if (cls.cachedNode != null) return;

    measure(() => reporter.withCurrentElement(cls, () {
          MemberListener listener = new PatchMemberListener(compiler, cls);
          Parser parser = new PatchClassElementParser(listener);
          try {
            Token token = parser.parseTopLevelDeclaration(cls.beginToken);
            assert(identical(token, cls.endToken.next));
          } on ParserError catch (e) {
            // No need to recover from a parser error in platform libraries, user
            // will never see this if the libraries are tested correctly.
            reporter.internalError(cls, "Parser error in patch file: $e");
          }
          cls.cachedNode = listener.popNode();
          assert(listener.nodes.isEmpty);
        }));
  }
}

class PatchMemberListener extends MemberListener {
  final Compiler compiler;

  PatchMemberListener(Compiler compiler, ClassElement enclosingClass)
      : this.compiler = compiler,
        super(compiler.parsingContext.getScannerOptionsFor(enclosingClass),
            compiler.reporter, enclosingClass);

  @override
  void addMember(Element patch) {
    addMetadata(patch);

    PatchVersion patchVersion = getPatchVersion(compiler, patch);
    if (patchVersion != null) {
      if (patchVersion.isActive(compiler.patchVersion)) {
        Element origin = enclosingClass.origin.localLookup(patch.name);
        patchElement(compiler, reporter, origin, patch);
        enclosingClass.addMember(patch, reporter);
      } else {
        // Skip this element.
      }
    } else {
      if (Name.isPublicName(patch.name)) {
        reporter.reportErrorMessage(patch, MessageKind.INJECTED_PUBLIC_MEMBER);
      }
      enclosingClass.addMember(patch, reporter);
    }
  }
}

/**
 * Partial parser for patch files that also handles the members of class
 * declarations.
 */
class PatchClassElementParser extends PartialParser {
  PatchClassElementParser(Listener listener): super(listener);

  Token parseClassBody(Token token) => fullParseClassBody(token);
}

/**
 * Extension of [ElementListener] for parsing patch files.
 */
class PatchElementListener extends ElementListener implements Listener {
  final Compiler compiler;

  PatchElementListener(Compiler compiler, CompilationUnitElement patchElement,
      IdGenerator idGenerator)
      : this.compiler = compiler,
        super(compiler.parsingContext.getScannerOptionsFor(patchElement),
            compiler.reporter, patchElement, idGenerator);

  @override
  void pushElement(Element patch) {
    popMetadata(patch);

    PatchVersion patchVersion = getPatchVersion(compiler, patch);
    if (patchVersion != null) {
      if (patchVersion.isActive(compiler.patchVersion)) {
        LibraryElement originLibrary = compilationUnitElement.library;
        assert(originLibrary.isPatched);
        Element origin = originLibrary.localLookup(patch.name);
        patchElement(compiler, reporter, origin, patch);
        compilationUnitElement.addMember(patch, reporter);
      } else {
        // Skip this element.
      }
    } else {
      if (Name.isPublicName(patch.name)) {
        reporter.reportErrorMessage(patch, MessageKind.INJECTED_PUBLIC_MEMBER);
      }
      compilationUnitElement.addMember(patch, reporter);
    }
  }
}

void patchElement(Compiler compiler, DiagnosticReporter reporter,
    Element origin, Element patch) {
  if (origin == null) {
    reporter.reportErrorMessage(
        patch, MessageKind.PATCH_NON_EXISTING, {'name': patch.name});
    return;
  }

  if (!(origin.isClass ||
      origin.isConstructor ||
      origin.isFunction ||
      origin.isAbstractField)) {
    // TODO(ahe): Remove this error when the parser rejects all bad modifiers.
    reporter.reportErrorMessage(origin, MessageKind.PATCH_NONPATCHABLE);
    return;
  }
  if (patch.isClass) {
    tryPatchClass(compiler, reporter, origin, patch);
  } else if (patch.isGetter) {
    tryPatchGetter(reporter, origin, patch);
  } else if (patch.isSetter) {
    tryPatchSetter(reporter, origin, patch);
  } else if (patch.isConstructor) {
    tryPatchConstructor(reporter, origin, patch);
  } else if (patch.isFunction) {
    tryPatchFunction(reporter, origin, patch);
  } else {
    // TODO(ahe): Remove this error when the parser rejects all bad modifiers.
    reporter.reportErrorMessage(patch, MessageKind.PATCH_NONPATCHABLE);
  }
}

void tryPatchClass(Compiler compiler, DiagnosticReporter reporter,
    Element origin, ClassElement patch) {
  if (!origin.isClass) {
    reporter.reportError(
        reporter.createMessage(
            origin, MessageKind.PATCH_NON_CLASS, {'className': patch.name}),
        <DiagnosticMessage>[
          reporter.createMessage(patch, MessageKind.PATCH_POINT_TO_CLASS,
              {'className': patch.name}),
        ]);
    return;
  }
  patchClass(compiler, reporter, origin, patch);
}

void patchClass(Compiler compiler, DiagnosticReporter reporter,
    ClassElementX origin, ClassElementX patch) {
  if (origin.isPatched) {
    reporter.internalError(origin, "Patching the same class more than once.");
  }
  origin.applyPatch(patch);
  checkNativeAnnotation(compiler, patch);
}

/// Check whether [cls] has a `@Native(...)` annotation, and if so, set its
/// native name from the annotation.
checkNativeAnnotation(Compiler compiler, ClassElement cls) {
  EagerAnnotationHandler.checkAnnotation(
      compiler, cls, const NativeAnnotationHandler());
}

checkJsInteropAnnotation(Compiler compiler, element) {
  EagerAnnotationHandler.checkAnnotation(
      compiler, element, const JsInteropAnnotationHandler());
}

/// Abstract interface for pre-resolution detection of metadata.
///
/// The detection is handled in two steps:
/// - match the annotation syntactically and assume that the annotation is valid
///   if it looks correct,
/// - setup a deferred action to check that the annotation has a valid constant
///   value and report an internal error if not.
abstract class EagerAnnotationHandler<T> {
  /// Checks that [annotation] looks like a matching annotation and optionally
  /// applies actions on [element]. Returns a non-null annotation marker if the
  /// annotation matched and should be validated.
  T apply(Compiler compiler, Element element, MetadataAnnotation annotation);

  /// Checks that the annotation value is valid.
  void validate(Compiler compiler, Element element,
      MetadataAnnotation annotation, ConstantValue constant);

  /// Checks [element] for metadata matching the [handler]. Return a non-null
  /// annotation marker matching metadata was found.
  static checkAnnotation(
      Compiler compiler, Element element, EagerAnnotationHandler handler) {
    for (MetadataAnnotation annotation in element.implementation.metadata) {
      var result = handler.apply(compiler, element, annotation);
      if (result != null) {
        // TODO(johnniwinther): Perform this check in
        // [Compiler.onLibrariesLoaded].
        compiler.enqueuer.resolution.addDeferredAction(element, () {
          annotation.ensureResolved(compiler.resolution);
          handler.validate(compiler, element, annotation,
              compiler.constants.getConstantValue(annotation.constant));
        });
        return result;
      }
    }
    return null;
  }
}

/// Annotation handler for pre-resolution detection of `@Native(...)`
/// annotations.
class NativeAnnotationHandler implements EagerAnnotationHandler<String> {
  const NativeAnnotationHandler();

  String getNativeAnnotation(MetadataAnnotationX annotation) {
    if (annotation.beginToken != null &&
        annotation.beginToken.next.value == 'Native') {
      // Skipping '@', 'Native', and '('.
      Token argument = annotation.beginToken.next.next.next;
      if (argument is StringToken) {
        return argument.value;
      }
    }
    return null;
  }

  String apply(
      Compiler compiler, Element element, MetadataAnnotation annotation) {
    if (element.isClass) {
      String native = getNativeAnnotation(annotation);
      if (native != null) {
        JavaScriptBackend backend = compiler.backend;
        backend.nativeData.setNativeClassTagInfo(element, native);
        return native;
      }
    }
    return null;
  }

  void validate(Compiler compiler, Element element,
      MetadataAnnotation annotation, ConstantValue constant) {
    DartType annotationType = constant.getType(compiler.coreTypes);
    if (annotationType.element !=
        compiler.commonElements.nativeAnnotationClass) {
      DiagnosticReporter reporter = compiler.reporter;
      reporter.internalError(annotation, 'Invalid @Native(...) annotation.');
    }
  }
}

/// Annotation handler for pre-resolution detection of `@JS(...)`
/// annotations.
class JsInteropAnnotationHandler implements EagerAnnotationHandler<bool> {
  const JsInteropAnnotationHandler();

  bool hasJsNameAnnotation(MetadataAnnotationX annotation) =>
      annotation.beginToken != null && annotation.beginToken.next.value == 'JS';

  bool apply(
      Compiler compiler, Element element, MetadataAnnotation annotation) {
    bool hasJsInterop = hasJsNameAnnotation(annotation);
    if (hasJsInterop) {
      JavaScriptBackend backend = compiler.backend;
      backend.nativeData.markAsJsInterop(element);
    }
    // Due to semantics of apply in the baseclass we have to return null to
    // indicate that no match was found.
    return hasJsInterop ? true : null;
  }

  @override
  void validate(Compiler compiler, Element element,
      MetadataAnnotation annotation, ConstantValue constant) {
    JavaScriptBackend backend = compiler.backend;
    if (constant.getType(compiler.coreTypes).element !=
        backend.helpers.jsAnnotationClass) {
      compiler.reporter
          .internalError(annotation, 'Invalid @JS(...) annotation.');
    }
  }
}

/// Annotation handler for pre-resolution detection of `@patch` annotations.
class PatchAnnotationHandler implements EagerAnnotationHandler<PatchVersion> {
  const PatchAnnotationHandler();

  PatchVersion getPatchVersion(MetadataAnnotationX annotation) {
    if (annotation.beginToken != null) {
      if (annotation.beginToken.next.value == 'patch') {
        return const PatchVersion(null);
      } else if (annotation.beginToken.next.value == 'patch_full') {
        return const PatchVersion('full');
      } else if (annotation.beginToken.next.value == 'patch_lazy') {
        return const PatchVersion('lazy');
      } else if (annotation.beginToken.next.value == 'patch_startup') {
        return const PatchVersion('startup');
      }
    }
    return null;
  }

  @override
  PatchVersion apply(
      Compiler compiler, Element element, MetadataAnnotation annotation) {
    return getPatchVersion(annotation);
  }

  @override
  void validate(Compiler compiler, Element element,
      MetadataAnnotation annotation, ConstantValue constant) {
    DartType annotationType = constant.getType(compiler.coreTypes);
    if (annotationType.element !=
        compiler.commonElements.patchAnnotationClass) {
      DiagnosticReporter reporter = compiler.reporter;
      reporter.internalError(annotation, 'Invalid patch annotation.');
    }
  }
}

void tryPatchGetter(
    DiagnosticReporter reporter, Element origin, FunctionElement patch) {
  if (!origin.isAbstractField) {
    reporter.reportError(
        reporter.createMessage(
            origin, MessageKind.PATCH_NON_GETTER, {'name': origin.name}),
        <DiagnosticMessage>[
          reporter.createMessage(patch, MessageKind.PATCH_POINT_TO_GETTER,
              {'getterName': patch.name}),
        ]);
    return;
  }
  AbstractFieldElement originField = origin;
  if (originField.getter == null) {
    reporter.reportError(
        reporter.createMessage(
            origin, MessageKind.PATCH_NO_GETTER, {'getterName': patch.name}),
        <DiagnosticMessage>[
          reporter.createMessage(patch, MessageKind.PATCH_POINT_TO_GETTER,
              {'getterName': patch.name}),
        ]);
    return;
  }
  GetterElementX getter = originField.getter;
  patchFunction(reporter, getter, patch);
}

void tryPatchSetter(
    DiagnosticReporter reporter, Element origin, FunctionElement patch) {
  if (!origin.isAbstractField) {
    reporter.reportError(
        reporter.createMessage(
            origin, MessageKind.PATCH_NON_SETTER, {'name': origin.name}),
        <DiagnosticMessage>[
          reporter.createMessage(patch, MessageKind.PATCH_POINT_TO_SETTER,
              {'setterName': patch.name}),
        ]);
    return;
  }
  AbstractFieldElement originField = origin;
  if (originField.setter == null) {
    reporter.reportError(
        reporter.createMessage(
            origin, MessageKind.PATCH_NO_SETTER, {'setterName': patch.name}),
        <DiagnosticMessage>[
          reporter.createMessage(patch, MessageKind.PATCH_POINT_TO_SETTER,
              {'setterName': patch.name}),
        ]);
    return;
  }
  SetterElementX setter = originField.setter;
  patchFunction(reporter, setter, patch);
}

void tryPatchConstructor(
    DiagnosticReporter reporter, Element origin, FunctionElement patch) {
  if (!origin.isConstructor) {
    reporter.reportError(
        reporter.createMessage(origin, MessageKind.PATCH_NON_CONSTRUCTOR,
            {'constructorName': patch.name}),
        <DiagnosticMessage>[
          reporter.createMessage(patch, MessageKind.PATCH_POINT_TO_CONSTRUCTOR,
              {'constructorName': patch.name}),
        ]);
    return;
  }
  patchFunction(reporter, origin, patch);
}

void tryPatchFunction(
    DiagnosticReporter reporter, Element origin, FunctionElement patch) {
  if (!origin.isFunction) {
    reporter.reportError(
        reporter.createMessage(origin, MessageKind.PATCH_NON_FUNCTION,
            {'functionName': patch.name}),
        <DiagnosticMessage>[
          reporter.createMessage(patch, MessageKind.PATCH_POINT_TO_FUNCTION,
              {'functionName': patch.name}),
        ]);
    return;
  }
  patchFunction(reporter, origin, patch);
}

void patchFunction(DiagnosticReporter reporter, BaseFunctionElementX origin,
    BaseFunctionElementX patch) {
  if (!origin.modifiers.isExternal) {
    reporter.reportError(
        reporter.createMessage(origin, MessageKind.PATCH_NON_EXTERNAL),
        <DiagnosticMessage>[
          reporter.createMessage(patch, MessageKind.PATCH_POINT_TO_FUNCTION,
              {'functionName': patch.name}),
        ]);
    return;
  }
  if (origin.isPatched) {
    reporter.internalError(
        origin, "Trying to patch a function more than once.");
  }
  origin.applyPatch(patch);
}

PatchVersion getPatchVersion(Compiler compiler, Element element) {
  return EagerAnnotationHandler.checkAnnotation(
      compiler, element, const PatchAnnotationHandler());
}

class PatchVersion {
  final String tag;

  const PatchVersion(this.tag);

  bool isActive(String patchTag) => tag == null || tag == patchTag;

  String toString() => 'PatchVersion($tag)';
}
