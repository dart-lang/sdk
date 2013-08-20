// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Datatypes holding information extracted by the analyzer and used by later
 * phases of the compiler.
 */
library polymer.src.info;

import 'dart:collection' show SplayTreeMap, LinkedHashMap;

import 'package:analyzer_experimental/src/generated/ast.dart';
import 'package:csslib/visitor.dart';
import 'package:html5lib/dom.dart';
import 'package:source_maps/span.dart' show Span;

import 'dart_parser.dart' show DartCodeInfo;
import 'messages.dart';
import 'summary.dart';
import 'utils.dart';

/**
 * Information that is global. Roughly corresponds to `window` and `document`.
 */
class GlobalInfo {
  /**
   * Pseudo-element names exposed in a component via a pseudo attribute.
   * The name is only available from CSS (not Dart code) so they're mangled.
   * The same pseudo-element in different components maps to the same
   * mangled name (as the pseudo-element is scoped inside of the component).
   */
  final Map<String, String> pseudoElements = <String, String>{};

  /** All components declared in the application. */
  final Map<String, ComponentInfo> components = new SplayTreeMap();
}

/**
 * Information for any library-like input. We consider each HTML file a library,
 * and each component declaration a library as well. Hence we use this as a base
 * class for both [FileInfo] and [ComponentInfo]. Both HTML files and components
 * can have .dart code provided by the user for top-level user scripts and
 * component-level behavior code. This code can either be inlined in the HTML
 * file or included in a script tag with the "src" attribute.
 */
abstract class LibraryInfo implements LibrarySummary {

  /** Whether there is any code associated with the page/component. */
  bool get codeAttached => inlinedCode != null || externalFile != null;

  /**
   * The actual inlined code. Use [userCode] if you want the code from this file
   * or from an external file.
   */
  DartCodeInfo inlinedCode;

  /**
   * If this library's code was loaded using a script tag (e.g. in a component),
   * [externalFile] has the path to such Dart file relative from the compiler's
   * base directory.
   */
  UrlInfo externalFile;

  /** Info asscociated with [externalFile], if any. */
  FileInfo externalCode;

  /**
   * The inverse of [externalCode]. If this .dart file was imported via a script
   * tag, this refers to the HTML file that imported it.
   */
  LibraryInfo htmlFile;

  /** File where the top-level code was defined. */
  UrlInfo get dartCodeUrl;

  /**
   * Name of the file that will hold any generated Dart code for this library
   * unit. Note this is initialized after parsing.
   */
  String outputFilename;

  /** Parsed cssSource. */
  List<StyleSheet> styleSheets = [];

  /** This is used in transforming Dart code to track modified files. */
  bool modified = false;

  /**
   * This is used in transforming Dart code to compute files that reference
   * [modified] files.
   */
  List<FileInfo> referencedBy = [];

  /**
   * Components used within this library unit. For [FileInfo] these are
   * components used directly in the page. For [ComponentInfo] these are
   * components used within their shadowed template.
   */
  final Map<ComponentSummary, bool> usedComponents =
      new LinkedHashMap<ComponentSummary, bool>();

  /**
   * The actual code, either inlined or from an external file, or `null` if none
   * was defined.
   */
  DartCodeInfo get userCode =>
      externalCode != null ? externalCode.inlinedCode : inlinedCode;
}

/** Information extracted at the file-level. */
class FileInfo extends LibraryInfo implements HtmlFileSummary {
  /** Relative path to this file from the compiler's base directory. */
  final UrlInfo inputUrl;

  /**
   * Whether this file should be treated as the entry point of the web app, i.e.
   * the file users navigate to in their browser. This will be true if this file
   * was passed in the command line to the dwc compiler, and the
   * `--components_only` flag was omitted.
   */
  final bool isEntryPoint;

  // TODO(terry): Ensure that that the libraryName is a valid identifier:
  //              a..z || A..Z || _ [a..z || A..Z || 0..9 || _]*
  String get libraryName =>
      path.basename(inputUrl.resolvedPath).replaceAll('.', '_');

  /** File where the top-level code was defined. */
  UrlInfo get dartCodeUrl => externalFile != null ? externalFile : inputUrl;

  /**
   * All custom element definitions in this file. This may contain duplicates.
   * Normally you should use [components] for lookup.
   */
  final List<ComponentInfo> declaredComponents = new List<ComponentInfo>();

  /**
   * All custom element definitions defined in this file or imported via
   *`<link rel='components'>` tag. Maps from the tag name to the component
   * information. This map is sorted by the tag name.
   */
  final Map<String, ComponentSummary> components =
      new SplayTreeMap<String, ComponentSummary>();

  /** Files imported with `<link rel="import">` */
  final List<UrlInfo> componentLinks = <UrlInfo>[];

  /** Files imported with `<link rel="stylesheet">` */
  final List<UrlInfo> styleSheetHrefs = <UrlInfo>[];

  /** Root is associated with the body node. */
  Element body;

  FileInfo(this.inputUrl, [this.isEntryPoint = false]);

  /**
   * Query for an [Element] matching the provided [tag], starting from the
   * [body].
   */
  Element query(String tag) => body.query(tag);
}


/** Information about a web component definition declared locally. */
// TODO(sigmund): use a mixin to pull in ComponentSummary.
class ComponentInfo extends LibraryInfo implements ComponentSummary {
  /** The file that declares this component. */
  final FileInfo declaringFile;

  /** The component tag name, defined with the `name` attribute on `element`. */
  final String tagName;

  /**
   * The tag name that this component extends, defined with the `extends`
   * attribute on `element`.
   */
  final String extendsTag;

  /**
   * The component info associated with the [extendsTag] name, if any.
   * This will be `null` if the component extends a built-in HTML tag, or
   * if the analyzer has not run yet.
   */
  ComponentSummary extendsComponent;

  /** The Dart class containing the component's behavior. */
  String className;

  /** The Dart class declaration. */
  ClassDeclaration get classDeclaration => _classDeclaration;
  ClassDeclaration _classDeclaration;

  /** The declaring `<element>` tag. */
  final Node element;

  /** File where this component was defined. */
  UrlInfo get dartCodeUrl => externalFile != null
      ? externalFile : declaringFile.inputUrl;

  /**
   * True if [tagName] was defined by more than one component. If this happened
   * we will skip over the component.
   */
  bool hasConflict = false;

  ComponentInfo(this.element, this.declaringFile, this.tagName,
      this.extendsTag);

  /**
   * Gets the HTML tag extended by the base of the component hierarchy.
   * Equivalent to [extendsTag] if this inherits directly from an HTML element,
   * in other words, if [extendsComponent] is null.
   */
  String get baseExtendsTag =>
      extendsComponent == null ? extendsTag : extendsComponent.baseExtendsTag;

  Span get sourceSpan => element.sourceSpan;

  /** Is apply-author-styles enabled. */
  bool get hasAuthorStyles =>
      element.attributes.containsKey('apply-author-styles');

  /**
   * Finds the declaring class, and initializes [className] and
   * [classDeclaration]. Also [userCode] is generated if there was no script.
   */
  void findClassDeclaration(Messages messages) {
    var constructor = element.attributes['constructor'];
    className = constructor != null ? constructor :
        toCamelCase(tagName, startUppercase: true);

    // If we don't have any code, generate a small class definition, and
    // pretend the user wrote it as inlined code.
    if (userCode == null) {
      var superclass = extendsComponent != null ? extendsComponent.className
          : 'autogenerated.PolymerElement';
      inlinedCode = new DartCodeInfo(null, null, [],
          'class $className extends $superclass {\n}', null);
    }

    var code = userCode.code;
    _classDeclaration = userCode.findClass(className);
    if (_classDeclaration == null) {
      // Check for deprecated x-tags implied constructor.
      if (tagName.startsWith('x-') && constructor == null) {
        var oldCtor = toCamelCase(tagName.substring(2), startUppercase: true);
        _classDeclaration = userCode.findClass(oldCtor);
        if (_classDeclaration != null) {
          messages.warning('Implied constructor name for x-tags has changed to '
              '"$className". You should rename your class or add a '
              'constructor="$oldCtor" attribute to the element declaration. '
              'Also custom tags are not required to start with "x-" if their '
              'name has at least one dash.',
              element.sourceSpan);
          className = oldCtor;
        }
      }

      if (_classDeclaration == null) {
        messages.error('please provide a class definition '
            'for $className:\n $code', element.sourceSpan);
        return;
      }
    }
  }

  String toString() => '#<ComponentInfo $tagName '
      '${inlinedCode != null ? "inline" : "from ${dartCodeUrl.resolvedPath}"}>';
}


/**
 * Information extracted about a URL that refers to another file. This is
 * mainly introduced to be able to trace back where URLs come from when
 * reporting errors.
 */
class UrlInfo {
  /** Original url. */
  final String url;

  /** Path that the URL points to. */
  final String resolvedPath;

  /** Original source location where the URL was extracted from. */
  final Span sourceSpan;

  UrlInfo(this.url, this.resolvedPath, this.sourceSpan);

  /**
   * Resolve a path from an [url] found in a file located at [inputUrl].
   * Returns null for absolute [url]. Unless [ignoreAbsolute] is true, reports
   * an error message if the url is an absolute url.
   */
  static UrlInfo resolve(String url, UrlInfo inputUrl, Span span,
      String packageRoot, Messages messages, {bool ignoreAbsolute: false}) {

    var uri = Uri.parse(url);
    if (uri.host != '' || (uri.scheme != '' && uri.scheme != 'package')) {
      if (!ignoreAbsolute) {
        messages.error('absolute paths not allowed here: "$url"', span);
      }
      return null;
    }

    var target;
    if (url.startsWith('package:')) {
      target = path.join(packageRoot, url.substring(8));
    } else if (path.isAbsolute(url)) {
      if (!ignoreAbsolute) {
        messages.error('absolute paths not allowed here: "$url"', span);
      }
      return null;
    } else {
      target = path.join(path.dirname(inputUrl.resolvedPath), url);
      url = pathToUrl(path.normalize(path.join(
          path.dirname(inputUrl.url), url)));
    }
    target = path.normalize(target);

    return new UrlInfo(url, target, span);
  }

  bool operator ==(UrlInfo other) =>
      url == other.url && resolvedPath == other.resolvedPath;

  int get hashCode => resolvedPath.hashCode;

  String toString() => "#<UrlInfo url: $url, resolvedPath: $resolvedPath>";
}
