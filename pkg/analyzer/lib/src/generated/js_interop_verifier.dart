// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/error/listener.dart';

/// A verifier used to find problems with the way the `dart:js_interop` (or
/// `package:js`) APIs are being used.
///
/// The CFE reports the same problems from `pkg/_js_interop_checks`, so this
/// verifier deliberately stays at or inside the CFE's boundary: reporting a
/// diagnostic the CFE does not report would make the analyzer reject code that
/// compiles and runs, which is worse than missing a diagnostic.
class JsInteropVerifier {
  /// The URI of the library declaring the `JS*` types that make an extension
  /// type an interop extension type.
  static const String _jsInteropLibraryUri = 'dart:js_interop';

  final DiagnosticReporter _diagnosticReporter;

  JsInteropVerifier(this._diagnosticReporter);

  void verifyCompilationUnit(CompilationUnit node) {
    for (var declaration in node.declarations) {
      if (declaration is ExtensionTypeDeclaration) {
        _checkExtensionTypeDeclaration(declaration);
      }
    }
  }

  /// Reports `@JS` annotations on the constructors and factories of an interop
  /// extension type, where the annotation has no effect.
  ///
  /// The CFE reaches the equivalent check
  /// (`JsInteropChecks.visitProcedure` in `pkg/_js_interop_checks`) only for
  /// members that pass `_isJSInteropMember`, which imposes two preconditions
  /// that are replicated here.
  void _checkExtensionTypeDeclaration(ExtensionTypeDeclaration declaration) {
    // Precondition 1: for extension type members `_isJSInteropMember` consults
    // `ExtensionIndex`, which only indexes declarations satisfying
    // `isInteropExtensionType`. An extension type over a non-interop
    // representation type, such as `extension type Foo(int _)`, is invisible to
    // the CFE's interop checks.
    var element = declaration.declaredFragment?.element;
    if (element == null || !_isInteropExtensionType(element)) {
      return;
    }

    for (var member in declaration.body.members) {
      if (member is ConstructorDeclaration) {
        // Precondition 2: `_isJSInteropMember` returns `false` for any member
        // that is not `external`, so the CFE never reports a non-external
        // constructor.
        if (member.externalKeyword == null) {
          continue;
        }

        for (var annotation in member.metadata) {
          // `isJS` recognizes `JS` from `dart:js_interop`,
          // `dart:_js_annotations`, and therefore `package:js`, matching the
          // CFE's `hasJSInteropAnnotation`. It resolves the annotation's
          // element, so import prefixes are handled.
          if (annotation.elementAnnotation?.isJS ?? false) {
            _diagnosticReporter.report(
              diag.jsInteropExtensionConstructorJsAnnotationHasNoEffect.at(
                annotation.name,
              ),
            );
          }
        }
      }
    }
  }

  /// Whether [element] is a `dart:js_interop` `JS` type, or an extension type
  /// whose representation type transitively resolves to one.
  ///
  /// This is a deliberately narrower version of the CFE's
  /// `ExtensionIndex.isInteropExtensionType`, which additionally treats
  /// `@staticInterop` classes and `@Native` classes that are subtypes of
  /// `JavaScriptObject` as interop representation types. Those two cases are
  /// legacy, pre-`dart:js_interop` shapes, so omitting them only costs missed
  /// diagnostics on legacy code rather than risking reports the CFE would not
  /// make. See https://github.com/dart-lang/sdk/issues/54366.
  static bool _isInteropExtensionType(ExtensionTypeElement element) {
    var current = element;
    while (true) {
      if (_isJSType(current)) {
        return true;
      }
      // Unwrap one layer: an extension type over an interop extension type is
      // itself an interop extension type. Representation type cycles are
      // already broken during summary2 linking (`InvalidType`), so this loop
      // is guaranteed to terminate.
      var representationType = current.representation.type;
      if (representationType is! InterfaceType) {
        return false;
      }
      var representationElement = representationType.element;
      if (representationElement is! ExtensionTypeElement) {
        return false;
      }
      current = representationElement;
    }
  }

  /// Whether [element] is one of the `JS` types declared in `dart:js_interop`,
  /// such as `JSAny` or `JSObject`.
  ///
  /// This mirrors `ExtensionIndex.isJSType` in `pkg/_js_interop_checks`, which
  /// identifies these types by library and name prefix rather than by identity.
  static bool _isJSType(ExtensionTypeElement element) {
    var name = element.name;
    return name != null &&
        name.startsWith('JS') &&
        element.library.uri.toString() == _jsInteropLibraryUri;
  }
}
