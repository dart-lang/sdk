// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Collects several code emitters for the template tool. */
library emitters;

import 'package:html5lib/dom.dart';
import 'package:html5lib/dom_parsing.dart' show TreeVisitor;
import 'package:html5lib/parser.dart' show parseFragment;
import 'package:source_maps/printer.dart';
import 'package:source_maps/refactor.dart';

import 'compiler_options.dart';
import 'css_emitters.dart' show emitStyleSheet, emitOriginalCss;
import 'html5_utils.dart';
import 'info.dart' show ComponentInfo, FileInfo, GlobalInfo;
import 'messages.dart';
import 'paths.dart' show PathMapper;
import 'utils.dart' show escapeDartString, path;

/** Generates the class corresponding to a single web component. */
NestedPrinter emitPolymerElement(ComponentInfo info, PathMapper pathMapper,
    TextEditTransaction transaction, CompilerOptions options) {
  if (info.classDeclaration == null) return null;

  var codeInfo = info.userCode;
  if (transaction == null) {
    // TODO(sigmund): avoid emitting this file if we don't need to do any
    // modifications (e.g. no @observable and not adding the libraryName).
    transaction = new TextEditTransaction(codeInfo.code, codeInfo.sourceFile);
  }
  if (codeInfo.libraryName == null) {
    // For deploy, we need to import the library associated with the component,
    // so we need to ensure there is a library directive.
    var libraryName = info.tagName.replaceAll(new RegExp('[-./]'), '_');
    transaction.edit(0, 0, 'library $libraryName;');
  }
  return transaction.commit();
}

/** The code that will be used to bootstrap the application. */
NestedPrinter generateBootstrapCode(
    FileInfo info, FileInfo userMainInfo, GlobalInfo global,
    PathMapper pathMapper, CompilerOptions options) {

  var printer = new NestedPrinter(0)
      ..addLine('library app_bootstrap;')
      ..addLine('')
      ..addLine("import 'package:polymer/polymer.dart';")
      ..addLine("import 'dart:mirrors' show currentMirrorSystem;");

  int i = 0;
  for (var c in global.components.values) {
    if (c.hasConflict) continue;
    printer.addLine("import '${pathMapper.importUrlFor(info, c)}' as i$i;");
    i++;
  }
  if (userMainInfo.userCode != null) {
    printer..addLine("import '${pathMapper.importUrlFor(info, userMainInfo)}' "
        "as i$i;\n");
  }

  printer..addLine('')
      ..addLine('void main() {')
      ..indent += 1
      ..addLine("initPolymer([")
      ..indent += 2;

  for (var c in global.components.values) {
    if (c.hasConflict) continue;
    printer.addLine("'${pathMapper.importUrlFor(info, c)}',");
  }

  if (userMainInfo.userCode != null) {
    printer.addLine("'${pathMapper.importUrlFor(info, userMainInfo)}',");
  }

  return printer
      ..indent -= 1
      ..addLine('],')
      ..addLine(
          "currentMirrorSystem().findLibrary(const Symbol('app_bootstrap'))")
      ..indent += 2
      ..addLine(".first.uri.toString());")
      ..indent -= 4
      ..addLine('}');
}


/**
 * Rewrites attributes that contain relative URL (excluding src urls in script
 * and link tags which are already rewritten by other parts of the compiler).
*/
class _AttributeUrlTransform extends TreeVisitor {
  final String filePath;
  final PathMapper pathMapper;

  _AttributeUrlTransform(this.filePath, this.pathMapper);

  visitElement(Element node) {
    if (node.tagName == 'script') return;
    if (node.tagName == 'link') return;

    for (var key in node.attributes.keys) {
      if (urlAttributes.contains(key)) {
        node.attributes[key] =
            pathMapper.transformUrl(filePath, node.attributes[key]);
      }
    }
    super.visitElement(node);
  }
}

final _shadowDomJS = new RegExp(r'shadowdom\..*\.js', caseSensitive: false);
final _bootJS = new RegExp(r'.*/polymer/boot.js', caseSensitive: false);

/** Trim down the html for the main html page. */
void transformMainHtml(Document document, FileInfo fileInfo,
    PathMapper pathMapper, bool hasCss, bool rewriteUrls,
    Messages messages, GlobalInfo global, String bootstrapOutName) {
  var filePath = fileInfo.inputUrl.resolvedPath;

  var dartLoaderTag = null;
  bool shadowDomFound = false;
  for (var tag in document.queryAll('script')) {
    var src = tag.attributes['src'];
    if (src != null) {
      var last = src.split('/').last;
      if (last == 'dart.js' || last == 'testing.js') {
        dartLoaderTag = tag;
      } else if (_shadowDomJS.hasMatch(last)) {
        shadowDomFound = true;
      }
    }
    if (tag.attributes['type'] == 'application/dart') {
      tag.remove();
    } else if (src != null) {
      if (_bootJS.hasMatch(src)) {
        tag.remove();
      } else if (rewriteUrls) {
        tag.attributes["src"] = pathMapper.transformUrl(filePath, src);
      }
    }
  }

  for (var tag in document.queryAll('link')) {
    var href = tag.attributes['href'];
    var rel = tag.attributes['rel'];
    if (rel == 'component' || rel == 'components' || rel == 'import') {
      tag.remove();
    } else if (href != null && rewriteUrls && !hasCss) {
      // Only rewrite URL if rewrite on and we're not CSS polyfilling.
      tag.attributes['href'] = pathMapper.transformUrl(filePath, href);
    }
  }

  if (rewriteUrls) {
    // Transform any element's attribute which is a relative URL.
    new _AttributeUrlTransform(filePath, pathMapper).visit(document);
  }

  if (hasCss) {
    var newCss = pathMapper.mangle(path.basename(filePath), '.css', true);
    var linkElem = new Element.html(
        '<link rel="stylesheet" type="text/css" href="$newCss">');
    document.head.insertBefore(linkElem, null);
  }

  var styles = document.queryAll('style');
  if (styles.length > 0) {
    var allCss = new StringBuffer();
    fileInfo.styleSheets.forEach((styleSheet) =>
        allCss.write(emitStyleSheet(styleSheet, fileInfo)));
    styles[0].nodes.clear();
    styles[0].nodes.add(new Text(allCss.toString()));
    for (var i = styles.length - 1; i > 0 ; i--) {
      styles[i].remove();
    }
  }

  // TODO(jmesserly): put this in the global CSS file?
  // http://dvcs.w3.org/hg/webcomponents/raw-file/tip/spec/templates/index.html#css-additions
  document.head.nodes.insert(0, parseFragment(
      '<style>template { display: none; }</style>'));

  // Move all <element> declarations to the main HTML file
  // TODO(sigmund): remove this once we have HTMLImports implemented.
  for (var c in global.components.values) {
    document.body.nodes.insert(0, new Text('\n'));
    var fragment = c.element;
    for (var tag in fragment.queryAll('script')) {
      // TODO(sigmund): leave script tags around when we start using "boot.js"
      if (tag.attributes['type'] == 'application/dart') {
        tag.remove();
      }
    }
    document.body.nodes.insert(0, fragment);
  }

  if (!shadowDomFound) {
    // TODO(jmesserly): we probably shouldn't add this automatically.
    document.body.nodes.add(parseFragment('<script type="text/javascript" '
        'src="packages/shadow_dom/shadow_dom.debug.js"></script>\n'));

    // JS interop code required for Polymer CSS shimming.
    document.body.nodes.add(parseFragment('<script type="text/javascript" '
        'src="packages/browser/interop.js"></script>\n'));
  }

  var bootstrapScript = parseFragment(
        '<script type="application/dart" src="$bootstrapOutName"></script>');
  if (dartLoaderTag == null) {
    document.body.nodes.add(bootstrapScript);
    // TODO(jmesserly): turn this warning on.
    //messages.warning('Missing script to load Dart. '
    //    'Please add this line to your HTML file: $dartLoader',
    //    document.body.sourceSpan);
    // TODO(sigmund): switch to 'boot.js'
    document.body.nodes.add(parseFragment('<script type="text/javascript" '
        'src="packages/browser/dart.js"></script>\n'));
  } else if (dartLoaderTag.parent != document.body) {
    document.body.nodes.add(bootstrapScript);
  } else {
    document.body.insertBefore(bootstrapScript, dartLoaderTag);
  }

  // Insert the "auto-generated" comment after the doctype, otherwise IE will
  // go into quirks mode.
  int commentIndex = 0;
  DocumentType doctype =
      document.nodes.firstWhere((n) => n is DocumentType, orElse: () => null);
  if (doctype != null) {
    commentIndex = document.nodes.indexOf(doctype) + 1;
    // TODO(jmesserly): the html5lib parser emits a warning for missing
    // doctype, but it allows you to put it after comments. Presumably they do
    // this because some comments won't force IE into quirks mode (sigh). See
    // this link for more info:
    //     http://bugzilla.validator.nu/show_bug.cgi?id=836
    // For simplicity we emit the warning always, like validator.nu does.
    if (doctype.tagName != 'html' || commentIndex != 1) {
      messages.warning('file should start with <!DOCTYPE html> '
          'to avoid the possibility of it being parsed in quirks mode in IE. '
          'See http://www.w3.org/TR/html5-diff/#doctype', doctype.sourceSpan);
    }
  }
  document.nodes.insert(commentIndex, parseFragment(
      '\n<!-- This file was auto-generated from $filePath. -->\n'));
}
