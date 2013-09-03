// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Datatypes holding information extracted by the analyzer and used by later
 * phases of the compiler.
 */
library polymer.src.info;

import 'dart:collection' show SplayTreeMap, LinkedHashMap;

import 'package:csslib/visitor.dart';
import 'package:html5lib/dom.dart';
import 'package:source_maps/span.dart' show Span;

import 'messages.dart';
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
abstract class LibraryInfo {
  /** Parsed cssSource. */
  List<StyleSheet> styleSheets = [];
}

/** Information extracted at the file-level. */
class FileInfo extends LibraryInfo {
  /** Relative path to this file from the compiler's base directory. */
  final UrlInfo inputUrl;

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
  final Map<String, ComponentInfo> components =
      new SplayTreeMap<String, ComponentInfo>();

  /** Files imported with `<link rel="import">` */
  final List<UrlInfo> componentLinks = <UrlInfo>[];

  /** Files imported with `<link rel="stylesheet">` */
  final List<UrlInfo> styleSheetHrefs = <UrlInfo>[];

  FileInfo(this.inputUrl);
}


/** Information about a web component definition declared locally. */
class ComponentInfo extends LibraryInfo {

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
  ComponentInfo extendsComponent;

  /** The declaring `<element>` tag. */
  final Node element;

  /**
   * True if [tagName] was defined by more than one component. If this happened
   * we will skip over the component.
   */
  bool hasConflict = false;

  ComponentInfo(this.element, this.tagName, this.extendsTag);

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

  String toString() => '#<ComponentInfo $tagName>';
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
