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

import 'compiler.dart' show Compiler;
import 'constants/values.dart' show ConstantValue;
import 'elements/elements.dart';
import 'enqueue.dart' show DeferredAction;

/// Abstract interface for pre-resolution detection of metadata.
///
/// The detection is handled in two steps:
/// - match the annotation syntactically and assume that the annotation is valid
///   if it looks correct,
/// - setup a deferred action to check that the annotation has a valid constant
///   value and report an internal error if not.
abstract class EagerAnnotationHandler<T> {
  const EagerAnnotationHandler();

  /// Checks that [annotation] looks like a matching annotation and optionally
  /// applies actions on [element]. Returns a non-null annotation marker if the
  /// annotation matched and should be validated.
  T apply(Compiler compiler, Element element, MetadataAnnotation annotation);

  /// Checks that the annotation value is valid.
  void validate(Compiler compiler, Element element,
      MetadataAnnotation annotation, ConstantValue constant);

  /// Checks [element] for metadata matching the [handler]. Return a non-null
  /// annotation marker matching metadata was found.
  static T checkAnnotation<T>(
      Compiler compiler, Element element, EagerAnnotationHandler<T> handler) {
    for (MetadataAnnotation annotation in element.implementation.metadata) {
      T result = handler.apply(compiler, element, annotation);
      if (result != handler.defaultResult) {
        // TODO(johnniwinther): Perform this check in
        // [Compiler.processLoadedLibraries].
        compiler.libraryLoader
            .registerDeferredAction(new DeferredAction(element, () {
          annotation.ensureResolved(compiler.resolution);
          handler.validate(compiler, element, annotation,
              compiler.constants.getConstantValue(annotation.constant));
        }));
        return result;
      }
    }
    return handler.defaultResult;
  }

  /// Result that signals the absence of annotations.
  T get defaultResult => null;
}
