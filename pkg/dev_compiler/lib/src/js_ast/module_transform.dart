// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of js_ast;

/**
 * Transforms EcmaScript 6 modules to an ES 5 file using a module pattern.
 *
 * There are various module patterns in JavaScript, see
 * <http://babeljs.io/docs/usage/modules/> for some examples.
 *
 * At the moment, we only support our "custom Dart" conversion, roughly similar
 * to Asynchronous Module Definition (AMD), see also
 * <http://requirejs.org/docs/whyamd.html>. Like AMD, module files can
 * be loaded directly in the browser with no further transformation (e.g.
 * browserify, webpack).
 */
// TODO(jmesserly): deprecate the "custom dart" form in favor of AMD.
class CustomDartModuleTransform extends BaseVisitor {
  // TODO(jmesserly): implement these. Module should transform to Program.
  visitImportDeclaration(ImportDeclaration node) {}
  visitExportDeclaration(ExportDeclaration node) {}
  visitModule(Module node) {}
}
