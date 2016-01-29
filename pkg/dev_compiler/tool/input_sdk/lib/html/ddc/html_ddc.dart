/**
 * HTML elements and other resources for web-based applications that need to
 * interact with the browser and the DOM (Document Object Model).
 *
 * This library includes DOM element types, CSS styling, local storage,
 * media, speech, events, and more.
 * To get started,
 * check out the [Element] class, the base class for many of the HTML
 * DOM types.
 *
 * ## Other resources
 *
 * * If you've never written a web app before, try our
 * tutorials&mdash;[A Game of Darts](http://dartlang.org/docs/tutorials).
 *
 * * To see some web-based Dart apps in action and to play with the code,
 * download
 * [Dart Editor](http://www.dartlang.org/#get-started)
 * and run its built-in examples.
 *
 * * For even more examples, see
 * [Dart HTML5 Samples](https://github.com/dart-lang/dart-html5-samples)
 * on Github.
 */
library dart.dom.html;

import 'dart:_runtime' show global_;
import 'dart:async';
import 'dart:collection';
import 'dart:_internal' hide Symbol;
import 'dart:html_common';
import 'dart:isolate';
import "dart:convert";
import 'dart:math';
import 'dart:_native_typed_data';
import 'dart:typed_data';
import 'dart:_isolate_helper' show IsolateNatives;
import 'dart:_foreign_helper' show JS, JS_INTERCEPTOR_CONSTANT, JS_CONST;
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('HTMLAnchorElement')
@Native("HTMLAnchorElement")
class AnchorElement extends HtmlElement implements UrlUtils {
  // To suppress missing implicit constructor warnings.
  factory AnchorElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('HTMLAnchorElement.HTMLAnchorElement')
  @DocsEditable()
  factory AnchorElement({String href}) {
    AnchorElement e = document.createElement("a");
    if (href != null) e.href = href;
    return e;
  }


  @Deprecated("Internal Use Only")
  static AnchorElement internalCreateAnchorElement() {
    return new AnchorElement.internal_();
  }

  @Deprecated("Internal Use Only")
  AnchorElement.internal_() : super.internal_();


  @DomName('HTMLAnchorElement.download')
  @DocsEditable()
  String get download => wrap_jso(JS("String", "#.download", this.raw));
  @DomName('HTMLAnchorElement.download')
  @DocsEditable()
  void set download(String val) => JS("void", "#.download = #", this.raw, unwrap_jso(val));

  @DomName('HTMLAnchorElement.hreflang')
  @DocsEditable()
  String get hreflang => wrap_jso(JS("String", "#.hreflang", this.raw));
  @DomName('HTMLAnchorElement.hreflang')
  @DocsEditable()
  void set hreflang(String val) => JS("void", "#.hreflang = #", this.raw, unwrap_jso(val));

  @DomName('HTMLAnchorElement.integrity')
  @DocsEditable()
  @Experimental() // untriaged
  String get integrity => wrap_jso(JS("String", "#.integrity", this.raw));
  @DomName('HTMLAnchorElement.integrity')
  @DocsEditable()
  @Experimental() // untriaged
  void set integrity(String val) => JS("void", "#.integrity = #", this.raw, unwrap_jso(val));

  @DomName('HTMLAnchorElement.rel')
  @DocsEditable()
  String get rel => wrap_jso(JS("String", "#.rel", this.raw));
  @DomName('HTMLAnchorElement.rel')
  @DocsEditable()
  void set rel(String val) => JS("void", "#.rel = #", this.raw, unwrap_jso(val));

  @DomName('HTMLAnchorElement.target')
  @DocsEditable()
  String get target => wrap_jso(JS("String", "#.target", this.raw));
  @DomName('HTMLAnchorElement.target')
  @DocsEditable()
  void set target(String val) => JS("void", "#.target = #", this.raw, unwrap_jso(val));

  @DomName('HTMLAnchorElement.type')
  @DocsEditable()
  String get type => wrap_jso(JS("String", "#.type", this.raw));
  @DomName('HTMLAnchorElement.type')
  @DocsEditable()
  void set type(String val) => JS("void", "#.type = #", this.raw, unwrap_jso(val));

  // From URLUtils

  @DomName('HTMLAnchorElement.hash')
  @DocsEditable()
  String get hash => wrap_jso(JS("String", "#.hash", this.raw));
  @DomName('HTMLAnchorElement.hash')
  @DocsEditable()
  void set hash(String val) => JS("void", "#.hash = #", this.raw, unwrap_jso(val));

  @DomName('HTMLAnchorElement.host')
  @DocsEditable()
  String get host => wrap_jso(JS("String", "#.host", this.raw));
  @DomName('HTMLAnchorElement.host')
  @DocsEditable()
  void set host(String val) => JS("void", "#.host = #", this.raw, unwrap_jso(val));

  @DomName('HTMLAnchorElement.hostname')
  @DocsEditable()
  String get hostname => wrap_jso(JS("String", "#.hostname", this.raw));
  @DomName('HTMLAnchorElement.hostname')
  @DocsEditable()
  void set hostname(String val) => JS("void", "#.hostname = #", this.raw, unwrap_jso(val));

  @DomName('HTMLAnchorElement.href')
  @DocsEditable()
  String get href => wrap_jso(JS("String", "#.href", this.raw));
  @DomName('HTMLAnchorElement.href')
  @DocsEditable()
  void set href(String val) => JS("void", "#.href = #", this.raw, unwrap_jso(val));

  @DomName('HTMLAnchorElement.origin')
  @DocsEditable()
  // WebKit only
  @Experimental() // non-standard
  String get origin => wrap_jso(JS("String", "#.origin", this.raw));

  @DomName('HTMLAnchorElement.password')
  @DocsEditable()
  @Experimental() // untriaged
  String get password => wrap_jso(JS("String", "#.password", this.raw));
  @DomName('HTMLAnchorElement.password')
  @DocsEditable()
  @Experimental() // untriaged
  void set password(String val) => JS("void", "#.password = #", this.raw, unwrap_jso(val));

  @DomName('HTMLAnchorElement.pathname')
  @DocsEditable()
  String get pathname => wrap_jso(JS("String", "#.pathname", this.raw));
  @DomName('HTMLAnchorElement.pathname')
  @DocsEditable()
  void set pathname(String val) => JS("void", "#.pathname = #", this.raw, unwrap_jso(val));

  @DomName('HTMLAnchorElement.port')
  @DocsEditable()
  String get port => wrap_jso(JS("String", "#.port", this.raw));
  @DomName('HTMLAnchorElement.port')
  @DocsEditable()
  void set port(String val) => JS("void", "#.port = #", this.raw, unwrap_jso(val));

  @DomName('HTMLAnchorElement.protocol')
  @DocsEditable()
  String get protocol => wrap_jso(JS("String", "#.protocol", this.raw));
  @DomName('HTMLAnchorElement.protocol')
  @DocsEditable()
  void set protocol(String val) => JS("void", "#.protocol = #", this.raw, unwrap_jso(val));

  @DomName('HTMLAnchorElement.search')
  @DocsEditable()
  String get search => wrap_jso(JS("String", "#.search", this.raw));
  @DomName('HTMLAnchorElement.search')
  @DocsEditable()
  void set search(String val) => JS("void", "#.search = #", this.raw, unwrap_jso(val));

  @DomName('HTMLAnchorElement.username')
  @DocsEditable()
  @Experimental() // untriaged
  String get username => wrap_jso(JS("String", "#.username", this.raw));
  @DomName('HTMLAnchorElement.username')
  @DocsEditable()
  @Experimental() // untriaged
  void set username(String val) => JS("void", "#.username = #", this.raw, unwrap_jso(val));
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('HTMLBaseElement')
@Native("HTMLBaseElement")
class BaseElement extends HtmlElement {
  // To suppress missing implicit constructor warnings.
  factory BaseElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('HTMLBaseElement.HTMLBaseElement')
  @DocsEditable()
  factory BaseElement() => document.createElement("base");


  @Deprecated("Internal Use Only")
  static BaseElement internalCreateBaseElement() {
    return new BaseElement.internal_();
  }

  @Deprecated("Internal Use Only")
  BaseElement.internal_() : super.internal_();


  @DomName('HTMLBaseElement.href')
  @DocsEditable()
  String get href => wrap_jso(JS("String", "#.href", this.raw));
  @DomName('HTMLBaseElement.href')
  @DocsEditable()
  void set href(String val) => JS("void", "#.href = #", this.raw, unwrap_jso(val));

  @DomName('HTMLBaseElement.target')
  @DocsEditable()
  String get target => wrap_jso(JS("String", "#.target", this.raw));
  @DomName('HTMLBaseElement.target')
  @DocsEditable()
  void set target(String val) => JS("void", "#.target = #", this.raw, unwrap_jso(val));
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('HTMLBodyElement')
@Native("HTMLBodyElement")
class BodyElement extends HtmlElement {
  // To suppress missing implicit constructor warnings.
  factory BodyElement._() { throw new UnsupportedError("Not supported"); }

  /**
   * Static factory designed to expose `blur` events to event
   * handlers that are not necessarily instances of [BodyElement].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('HTMLBodyElement.blurEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> blurEvent = const EventStreamProvider<Event>('blur');

  /**
   * Static factory designed to expose `error` events to event
   * handlers that are not necessarily instances of [BodyElement].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('HTMLBodyElement.errorEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> errorEvent = const EventStreamProvider<Event>('error');

  /**
   * Static factory designed to expose `focus` events to event
   * handlers that are not necessarily instances of [BodyElement].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('HTMLBodyElement.focusEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> focusEvent = const EventStreamProvider<Event>('focus');

  /**
   * Static factory designed to expose `load` events to event
   * handlers that are not necessarily instances of [BodyElement].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('HTMLBodyElement.loadEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> loadEvent = const EventStreamProvider<Event>('load');

  /**
   * Static factory designed to expose `resize` events to event
   * handlers that are not necessarily instances of [BodyElement].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('HTMLBodyElement.resizeEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> resizeEvent = const EventStreamProvider<Event>('resize');

  @DomName('HTMLBodyElement.scrollEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> scrollEvent = const EventStreamProvider<Event>('scroll');

  @DomName('HTMLBodyElement.HTMLBodyElement')
  @DocsEditable()
  factory BodyElement() => document.createElement("body");


  @Deprecated("Internal Use Only")
  static BodyElement internalCreateBodyElement() {
    return new BodyElement.internal_();
  }

  @Deprecated("Internal Use Only")
  BodyElement.internal_() : super.internal_();


  /// Stream of `blur` events handled by this [BodyElement].
  @DomName('HTMLBodyElement.onblur')
  @DocsEditable()
  ElementStream<Event> get onBlur => blurEvent.forElement(this);

  /// Stream of `error` events handled by this [BodyElement].
  @DomName('HTMLBodyElement.onerror')
  @DocsEditable()
  ElementStream<Event> get onError => errorEvent.forElement(this);

  /// Stream of `focus` events handled by this [BodyElement].
  @DomName('HTMLBodyElement.onfocus')
  @DocsEditable()
  ElementStream<Event> get onFocus => focusEvent.forElement(this);

  /// Stream of `load` events handled by this [BodyElement].
  @DomName('HTMLBodyElement.onload')
  @DocsEditable()
  ElementStream<Event> get onLoad => loadEvent.forElement(this);

  /// Stream of `resize` events handled by this [BodyElement].
  @DomName('HTMLBodyElement.onresize')
  @DocsEditable()
  ElementStream<Event> get onResize => resizeEvent.forElement(this);

  @DomName('HTMLBodyElement.onscroll')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onScroll => scrollEvent.forElement(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('CharacterData')
@Native("CharacterData")
class CharacterData extends Node implements ChildNode {
  // To suppress missing implicit constructor warnings.
  factory CharacterData._() { throw new UnsupportedError("Not supported"); }


  @Deprecated("Internal Use Only")
  static CharacterData internalCreateCharacterData() {
    return new CharacterData.internal_();
  }

  @Deprecated("Internal Use Only")
  CharacterData.internal_() : super.internal_();


  @DomName('CharacterData.data')
  @DocsEditable()
  String get data => wrap_jso(JS("String", "#.data", this.raw));
  @DomName('CharacterData.data')
  @DocsEditable()
  void set data(String val) => JS("void", "#.data = #", this.raw, unwrap_jso(val));

  @DomName('CharacterData.length')
  @DocsEditable()
  int get length => wrap_jso(JS("int", "#.length", this.raw));

  @DomName('CharacterData.appendData')
  @DocsEditable()
  void appendData(String data) {
    _appendData_1(data);
    return;
  }
  @JSName('appendData')
  @DomName('CharacterData.appendData')
  @DocsEditable()
  void _appendData_1(data) => wrap_jso(JS("void ", "#.raw.appendData(#)", this, unwrap_jso(data)));

  @DomName('CharacterData.deleteData')
  @DocsEditable()
  void deleteData(int offset, int length) {
    _deleteData_1(offset, length);
    return;
  }
  @JSName('deleteData')
  @DomName('CharacterData.deleteData')
  @DocsEditable()
  void _deleteData_1(offset, length) => wrap_jso(JS("void ", "#.raw.deleteData(#, #)", this, unwrap_jso(offset), unwrap_jso(length)));

  @DomName('CharacterData.insertData')
  @DocsEditable()
  void insertData(int offset, String data) {
    _insertData_1(offset, data);
    return;
  }
  @JSName('insertData')
  @DomName('CharacterData.insertData')
  @DocsEditable()
  void _insertData_1(offset, data) => wrap_jso(JS("void ", "#.raw.insertData(#, #)", this, unwrap_jso(offset), unwrap_jso(data)));

  @DomName('CharacterData.replaceData')
  @DocsEditable()
  void replaceData(int offset, int length, String data) {
    _replaceData_1(offset, length, data);
    return;
  }
  @JSName('replaceData')
  @DomName('CharacterData.replaceData')
  @DocsEditable()
  void _replaceData_1(offset, length, data) => wrap_jso(JS("void ", "#.raw.replaceData(#, #, #)", this, unwrap_jso(offset), unwrap_jso(length), unwrap_jso(data)));

  @DomName('CharacterData.substringData')
  @DocsEditable()
  String substringData(int offset, int length) {
    return _substringData_1(offset, length);
  }
  @JSName('substringData')
  @DomName('CharacterData.substringData')
  @DocsEditable()
  String _substringData_1(offset, length) => wrap_jso(JS("String ", "#.raw.substringData(#, #)", this, unwrap_jso(offset), unwrap_jso(length)));

  // From ChildNode

  @DomName('CharacterData.nextElementSibling')
  @DocsEditable()
  Element get nextElementSibling => wrap_jso(JS("Element", "#.nextElementSibling", this.raw));

  @DomName('CharacterData.previousElementSibling')
  @DocsEditable()
  Element get previousElementSibling => wrap_jso(JS("Element", "#.previousElementSibling", this.raw));
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('ChildNode')
@Experimental() // untriaged
abstract class ChildNode extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory ChildNode._() { throw new UnsupportedError("Not supported"); }

  Element get nextElementSibling => wrap_jso(JS("Element", "#.nextElementSibling", this.raw));

  Element get previousElementSibling => wrap_jso(JS("Element", "#.previousElementSibling", this.raw));

  void remove() => wrap_jso(JS("void", "#.raw.remove()", this));
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('Comment')
@Native("Comment")
class Comment extends CharacterData {
  factory Comment([String data]) {
    if (data != null) {
      return wrap_jso(JS('Comment', '#.createComment(#)', document.raw, data));
    }
    return wrap_jso(JS('Comment', '#.createComment("")', document.raw));
  }
  // To suppress missing implicit constructor warnings.
  factory Comment._() { throw new UnsupportedError("Not supported"); }


  @Deprecated("Internal Use Only")
  static Comment internalCreateComment() {
    return new Comment.internal_();
  }

  @Deprecated("Internal Use Only")
  Comment.internal_() : super.internal_();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('Console')
class Console extends DartHtmlDomObject {

  Console._safe();

  static final Console _safeConsole = new Console._safe();

  bool get _isConsoleDefined => JS('bool', 'typeof console != "undefined"');

  @DomName('Console.assertCondition')
  void assertCondition(bool condition, Object arg) => _isConsoleDefined ?
      JS('void', 'console.assertCondition(#, #)', condition, arg) : null;

  @DomName('Console.clear')
  void clear(Object arg) => _isConsoleDefined ?
      JS('void', 'console.clear(#)', arg) : null;

  @DomName('Console.count')
  void count(Object arg) => _isConsoleDefined ?
      JS('void', 'console.count(#)', arg) : null;

  @DomName('Console.debug')
  void debug(Object arg) => _isConsoleDefined ?
      JS('void', 'console.debug(#)', arg) : null;

  @DomName('Console.dir')
  void dir(Object arg) => _isConsoleDefined ?
      JS('void', 'console.dir(#)', arg) : null;

  @DomName('Console.dirxml')
  void dirxml(Object arg) => _isConsoleDefined ?
      JS('void', 'console.dirxml(#)', arg) : null;

  @DomName('Console.error')
  void error(Object arg) => _isConsoleDefined ?
      JS('void', 'console.error(#)', arg) : null;

  @DomName('Console.group')
  void group(Object arg) => _isConsoleDefined ?
      JS('void', 'console.group(#)', arg) : null;

  @DomName('Console.groupCollapsed')
  void groupCollapsed(Object arg) => _isConsoleDefined ?
      JS('void', 'console.groupCollapsed(#)', arg) : null;

  @DomName('Console.groupEnd')
  void groupEnd() => _isConsoleDefined ?
      JS('void', 'console.groupEnd()') : null;

  @DomName('Console.info')
  void info(Object arg) => _isConsoleDefined ?
      JS('void', 'console.info(#)', arg) : null;

  @DomName('Console.log')
  void log(Object arg) => _isConsoleDefined ?
      JS('void', 'console.log(#)', arg) : null;

  @DomName('Console.markTimeline')
  void markTimeline(Object arg) => _isConsoleDefined ?
      JS('void', 'console.markTimeline(#)', arg) : null;

  @DomName('Console.profile')
  void profile(String title) => _isConsoleDefined ?
      JS('void', 'console.profile(#)', title) : null;

  @DomName('Console.profileEnd')
  void profileEnd(String title) => _isConsoleDefined ?
      JS('void', 'console.profileEnd(#)', title) : null;

  @DomName('Console.table')
  void table(Object arg) => _isConsoleDefined ?
      JS('void', 'console.table(#)', arg) : null;

  @DomName('Console.time')
  void time(String title) => _isConsoleDefined ?
      JS('void', 'console.time(#)', title) : null;

  @DomName('Console.timeEnd')
  void timeEnd(String title) => _isConsoleDefined ?
      JS('void', 'console.timeEnd(#)', title) : null;

  @DomName('Console.timeStamp')
  void timeStamp(Object arg) => _isConsoleDefined ?
      JS('void', 'console.timeStamp(#)', arg) : null;

  @DomName('Console.trace')
  void trace(Object arg) => _isConsoleDefined ?
      JS('void', 'console.trace(#)', arg) : null;

  @DomName('Console.warn')
  void warn(Object arg) => _isConsoleDefined ?
      JS('void', 'console.warn(#)', arg) : null;
  // To suppress missing implicit constructor warnings.
  factory Console._() { throw new UnsupportedError("Not supported"); }


  @Deprecated("Internal Use Only")
  static Console internalCreateConsole() {
    return new Console.internal_();
  }

  @Deprecated("Internal Use Only")
  Console.internal_() : super.internal_();


}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('ConsoleBase')
@Experimental() // untriaged
@Native("ConsoleBase")
class ConsoleBase extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory ConsoleBase._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static ConsoleBase internalCreateConsoleBase() {
    return new ConsoleBase.internal_();
  }

  @Deprecated("Internal Use Only")
  ConsoleBase.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

  @DomName('ConsoleBase.timeline')
  @DocsEditable()
  @Experimental() // untriaged
  void timeline(String title) {
    _timeline_1(title);
    return;
  }
  @JSName('timeline')
  @DomName('ConsoleBase.timeline')
  @DocsEditable()
  @Experimental() // untriaged
  void _timeline_1(title) => wrap_jso(JS("void ", "#.raw.timeline(#)", this, unwrap_jso(title)));

  @DomName('ConsoleBase.timelineEnd')
  @DocsEditable()
  @Experimental() // untriaged
  void timelineEnd(String title) {
    _timelineEnd_1(title);
    return;
  }
  @JSName('timelineEnd')
  @DomName('ConsoleBase.timelineEnd')
  @DocsEditable()
  @Experimental() // untriaged
  void _timelineEnd_1(title) => wrap_jso(JS("void ", "#.raw.timelineEnd(#)", this, unwrap_jso(title)));
}

// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: DO NOT EDIT THIS TEMPLATE FILE.
// The template file was generated by scripts/css_code_generator.py

// Source of CSS properties:
//   CSSPropertyNames.in


@DomName('CSSStyleDeclaration')
@Native("CSSStyleDeclaration,MSStyleCSSProperties,CSS2Properties")
class CssStyleDeclaration  extends DartHtmlDomObject with
    CssStyleDeclarationBase  {
  factory CssStyleDeclaration() => new CssStyleDeclaration.css('');

  factory CssStyleDeclaration.css(String css) {
    final style = new Element.tag('div').style;
    style.cssText = css;
    return style;
  }

  String getPropertyValue(String propertyName) {
    var propValue = _getPropertyValueHelper(propertyName);
    return propValue != null ? propValue : '';
  }

  String _getPropertyValueHelper(String propertyName) {
    if (_supportsProperty(_camelCase(propertyName))) {
      return _getPropertyValue(propertyName);
    } else {
      return _getPropertyValue(Device.cssPrefix + propertyName);
    }
  }

  /**
   * Returns true if the provided *CSS* property name is supported on this
   * element.
   *
   * Please note the property name camelCase, not-hyphens. This
   * method returns true if the property is accessible via an unprefixed _or_
   * prefixed property.
   */
  bool supportsProperty(String propertyName) {
    return _supportsProperty(propertyName) ||
        _supportsProperty(_camelCase(Device.cssPrefix + propertyName));
  }

  bool _supportsProperty(String propertyName) {
    return JS('bool', '# in #', propertyName, this.raw);
  }


  @DomName('CSSStyleDeclaration.setProperty')
  void setProperty(String propertyName, String value, [String priority]) {
    return _setPropertyHelper(_browserPropertyName(propertyName),
      value, priority);
  }

  String _browserPropertyName(String propertyName) {
    String name = _readCache(propertyName);
    if (name is String) return name;
    if (_supportsProperty(_camelCase(propertyName))) {
      name = propertyName;
    } else {
      name = Device.cssPrefix + propertyName;
    }
    _writeCache(propertyName, name);
    return name;
  }

  static String _readCache(String key) => null;
  static void _writeCache(String key, value) {}

  static String _camelCase(String hyphenated) {
    // The "ms" prefix is always lowercased.
    return hyphenated.replaceFirst(new RegExp('^-ms-'), 'ms-').replaceAllMapped(
        new RegExp('-([a-z]+)', caseSensitive: false),
        (match) => match[0][1].toUpperCase() + match[0].substring(2));
  }

  void _setPropertyHelper(String propertyName, String value, [String priority]) {
    if (value == null) value = '';
    if (priority == null) priority = '';
    JS('void', '#.setProperty(#, #, #)', this.raw, propertyName, value, priority);
  }

  /**
   * Checks to see if CSS Transitions are supported.
   */
  static bool get supportsTransitions {
    return document.body.style.supportsProperty('transition');
  }
  // To suppress missing implicit constructor warnings.
  factory CssStyleDeclaration._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static CssStyleDeclaration internalCreateCssStyleDeclaration() {
    return new CssStyleDeclaration.internal_();
  }

  @Deprecated("Internal Use Only")
  CssStyleDeclaration.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

  @DomName('CSSStyleDeclaration.cssText')
  @DocsEditable()
  String get cssText => wrap_jso(JS("String", "#.cssText", this.raw));
  @DomName('CSSStyleDeclaration.cssText')
  @DocsEditable()
  void set cssText(String val) => JS("void", "#.cssText = #", this.raw, unwrap_jso(val));

  @DomName('CSSStyleDeclaration.length')
  @DocsEditable()
  int get length => wrap_jso(JS("int", "#.length", this.raw));

  @DomName('CSSStyleDeclaration.__getter__')
  @DocsEditable()
  @Experimental() // untriaged
  Object __getter__(String name) {
    return __getter___1(name);
  }
  @JSName('__getter__')
  @DomName('CSSStyleDeclaration.__getter__')
  @DocsEditable()
  @Experimental() // untriaged
  Object __getter___1(name) => wrap_jso(JS("Object ", "#.raw.__getter__(#)", this, unwrap_jso(name)));

  @DomName('CSSStyleDeclaration.__setter__')
  @DocsEditable()
  void __setter__(String propertyName, String propertyValue) {
    __setter___1(propertyName, propertyValue);
    return;
  }
  @JSName('__setter__')
  @DomName('CSSStyleDeclaration.__setter__')
  @DocsEditable()
  void __setter___1(propertyName, propertyValue) => wrap_jso(JS("void ", "#.raw.__setter__(#, #)", this, unwrap_jso(propertyName), unwrap_jso(propertyValue)));

  @DomName('CSSStyleDeclaration.getPropertyPriority')
  @DocsEditable()
  String getPropertyPriority(String propertyName) {
    return _getPropertyPriority_1(propertyName);
  }
  @JSName('getPropertyPriority')
  @DomName('CSSStyleDeclaration.getPropertyPriority')
  @DocsEditable()
  String _getPropertyPriority_1(propertyName) => wrap_jso(JS("String ", "#.raw.getPropertyPriority(#)", this, unwrap_jso(propertyName)));

  @DomName('CSSStyleDeclaration.getPropertyValue')
  @DocsEditable()
  String _getPropertyValue(String propertyName) {
    return _getPropertyValue_1(propertyName);
  }
  @JSName('getPropertyValue')
  @DomName('CSSStyleDeclaration.getPropertyValue')
  @DocsEditable()
  String _getPropertyValue_1(propertyName) => wrap_jso(JS("String ", "#.raw.getPropertyValue(#)", this, unwrap_jso(propertyName)));

  @DomName('CSSStyleDeclaration.item')
  @DocsEditable()
  String item(int index) {
    return _item_1(index);
  }
  @JSName('item')
  @DomName('CSSStyleDeclaration.item')
  @DocsEditable()
  String _item_1(index) => wrap_jso(JS("String ", "#.raw.item(#)", this, unwrap_jso(index)));

  @DomName('CSSStyleDeclaration.removeProperty')
  @DocsEditable()
  String removeProperty(String propertyName) {
    return _removeProperty_1(propertyName);
  }
  @JSName('removeProperty')
  @DomName('CSSStyleDeclaration.removeProperty')
  @DocsEditable()
  String _removeProperty_1(propertyName) => wrap_jso(JS("String ", "#.raw.removeProperty(#)", this, unwrap_jso(propertyName)));

}

class _CssStyleDeclarationSet extends Object with CssStyleDeclarationBase {
  final Iterable<Element> _elementIterable;
  Iterable<CssStyleDeclaration> _elementCssStyleDeclarationSetIterable;

  _CssStyleDeclarationSet(this._elementIterable) {
    _elementCssStyleDeclarationSetIterable = new List.from(
        _elementIterable).map((e) => e.style);
  }

  String getPropertyValue(String propertyName) =>
      _elementCssStyleDeclarationSetIterable.first.getPropertyValue(
          propertyName);

  void setProperty(String propertyName, String value, [String priority]) {
    _elementCssStyleDeclarationSetIterable.forEach((e) =>
        e.setProperty(propertyName, value, priority));
  }



  // Important note: CssStyleDeclarationSet does NOT implement every method
  // available in CssStyleDeclaration. Some of the methods don't make so much
  // sense in terms of having a resonable value to return when you're
  // considering a list of Elements. You will need to manually add any of the
  // items in the MEMBERS set if you want that functionality.
}

class CssStyleDeclarationBase {
  String getPropertyValue(String propertyName) =>
    throw new StateError('getProperty not overridden in dart:html');
  void setProperty(String propertyName, String value, [String priority]) =>
    throw new StateError('setProperty not overridden in dart:html');

  /** Gets the value of "align-content" */
  String get alignContent =>
    getPropertyValue('align-content');

  /** Sets the value of "align-content" */
  set alignContent(String value) {
    setProperty('align-content', value, '');
  }

  /** Gets the value of "align-items" */
  String get alignItems =>
    getPropertyValue('align-items');

  /** Sets the value of "align-items" */
  set alignItems(String value) {
    setProperty('align-items', value, '');
  }

  /** Gets the value of "align-self" */
  String get alignSelf =>
    getPropertyValue('align-self');

  /** Sets the value of "align-self" */
  set alignSelf(String value) {
    setProperty('align-self', value, '');
  }

  /** Gets the value of "animation" */
  String get animation =>
    getPropertyValue('animation');

  /** Sets the value of "animation" */
  set animation(String value) {
    setProperty('animation', value, '');
  }

  /** Gets the value of "animation-delay" */
  String get animationDelay =>
    getPropertyValue('animation-delay');

  /** Sets the value of "animation-delay" */
  set animationDelay(String value) {
    setProperty('animation-delay', value, '');
  }

  /** Gets the value of "animation-direction" */
  String get animationDirection =>
    getPropertyValue('animation-direction');

  /** Sets the value of "animation-direction" */
  set animationDirection(String value) {
    setProperty('animation-direction', value, '');
  }

  /** Gets the value of "animation-duration" */
  String get animationDuration =>
    getPropertyValue('animation-duration');

  /** Sets the value of "animation-duration" */
  set animationDuration(String value) {
    setProperty('animation-duration', value, '');
  }

  /** Gets the value of "animation-fill-mode" */
  String get animationFillMode =>
    getPropertyValue('animation-fill-mode');

  /** Sets the value of "animation-fill-mode" */
  set animationFillMode(String value) {
    setProperty('animation-fill-mode', value, '');
  }

  /** Gets the value of "animation-iteration-count" */
  String get animationIterationCount =>
    getPropertyValue('animation-iteration-count');

  /** Sets the value of "animation-iteration-count" */
  set animationIterationCount(String value) {
    setProperty('animation-iteration-count', value, '');
  }

  /** Gets the value of "animation-name" */
  String get animationName =>
    getPropertyValue('animation-name');

  /** Sets the value of "animation-name" */
  set animationName(String value) {
    setProperty('animation-name', value, '');
  }

  /** Gets the value of "animation-play-state" */
  String get animationPlayState =>
    getPropertyValue('animation-play-state');

  /** Sets the value of "animation-play-state" */
  set animationPlayState(String value) {
    setProperty('animation-play-state', value, '');
  }

  /** Gets the value of "animation-timing-function" */
  String get animationTimingFunction =>
    getPropertyValue('animation-timing-function');

  /** Sets the value of "animation-timing-function" */
  set animationTimingFunction(String value) {
    setProperty('animation-timing-function', value, '');
  }

  /** Gets the value of "app-region" */
  String get appRegion =>
    getPropertyValue('app-region');

  /** Sets the value of "app-region" */
  set appRegion(String value) {
    setProperty('app-region', value, '');
  }

  /** Gets the value of "appearance" */
  String get appearance =>
    getPropertyValue('appearance');

  /** Sets the value of "appearance" */
  set appearance(String value) {
    setProperty('appearance', value, '');
  }

  /** Gets the value of "aspect-ratio" */
  String get aspectRatio =>
    getPropertyValue('aspect-ratio');

  /** Sets the value of "aspect-ratio" */
  set aspectRatio(String value) {
    setProperty('aspect-ratio', value, '');
  }

  /** Gets the value of "backface-visibility" */
  String get backfaceVisibility =>
    getPropertyValue('backface-visibility');

  /** Sets the value of "backface-visibility" */
  set backfaceVisibility(String value) {
    setProperty('backface-visibility', value, '');
  }

  /** Gets the value of "background" */
  String get background =>
    getPropertyValue('background');

  /** Sets the value of "background" */
  set background(String value) {
    setProperty('background', value, '');
  }

  /** Gets the value of "background-attachment" */
  String get backgroundAttachment =>
    getPropertyValue('background-attachment');

  /** Sets the value of "background-attachment" */
  set backgroundAttachment(String value) {
    setProperty('background-attachment', value, '');
  }

  /** Gets the value of "background-blend-mode" */
  String get backgroundBlendMode =>
    getPropertyValue('background-blend-mode');

  /** Sets the value of "background-blend-mode" */
  set backgroundBlendMode(String value) {
    setProperty('background-blend-mode', value, '');
  }

  /** Gets the value of "background-clip" */
  String get backgroundClip =>
    getPropertyValue('background-clip');

  /** Sets the value of "background-clip" */
  set backgroundClip(String value) {
    setProperty('background-clip', value, '');
  }

  /** Gets the value of "background-color" */
  String get backgroundColor =>
    getPropertyValue('background-color');

  /** Sets the value of "background-color" */
  set backgroundColor(String value) {
    setProperty('background-color', value, '');
  }

  /** Gets the value of "background-composite" */
  String get backgroundComposite =>
    getPropertyValue('background-composite');

  /** Sets the value of "background-composite" */
  set backgroundComposite(String value) {
    setProperty('background-composite', value, '');
  }

  /** Gets the value of "background-image" */
  String get backgroundImage =>
    getPropertyValue('background-image');

  /** Sets the value of "background-image" */
  set backgroundImage(String value) {
    setProperty('background-image', value, '');
  }

  /** Gets the value of "background-origin" */
  String get backgroundOrigin =>
    getPropertyValue('background-origin');

  /** Sets the value of "background-origin" */
  set backgroundOrigin(String value) {
    setProperty('background-origin', value, '');
  }

  /** Gets the value of "background-position" */
  String get backgroundPosition =>
    getPropertyValue('background-position');

  /** Sets the value of "background-position" */
  set backgroundPosition(String value) {
    setProperty('background-position', value, '');
  }

  /** Gets the value of "background-position-x" */
  String get backgroundPositionX =>
    getPropertyValue('background-position-x');

  /** Sets the value of "background-position-x" */
  set backgroundPositionX(String value) {
    setProperty('background-position-x', value, '');
  }

  /** Gets the value of "background-position-y" */
  String get backgroundPositionY =>
    getPropertyValue('background-position-y');

  /** Sets the value of "background-position-y" */
  set backgroundPositionY(String value) {
    setProperty('background-position-y', value, '');
  }

  /** Gets the value of "background-repeat" */
  String get backgroundRepeat =>
    getPropertyValue('background-repeat');

  /** Sets the value of "background-repeat" */
  set backgroundRepeat(String value) {
    setProperty('background-repeat', value, '');
  }

  /** Gets the value of "background-repeat-x" */
  String get backgroundRepeatX =>
    getPropertyValue('background-repeat-x');

  /** Sets the value of "background-repeat-x" */
  set backgroundRepeatX(String value) {
    setProperty('background-repeat-x', value, '');
  }

  /** Gets the value of "background-repeat-y" */
  String get backgroundRepeatY =>
    getPropertyValue('background-repeat-y');

  /** Sets the value of "background-repeat-y" */
  set backgroundRepeatY(String value) {
    setProperty('background-repeat-y', value, '');
  }

  /** Gets the value of "background-size" */
  String get backgroundSize =>
    getPropertyValue('background-size');

  /** Sets the value of "background-size" */
  set backgroundSize(String value) {
    setProperty('background-size', value, '');
  }

  /** Gets the value of "border" */
  String get border =>
    getPropertyValue('border');

  /** Sets the value of "border" */
  set border(String value) {
    setProperty('border', value, '');
  }

  /** Gets the value of "border-after" */
  String get borderAfter =>
    getPropertyValue('border-after');

  /** Sets the value of "border-after" */
  set borderAfter(String value) {
    setProperty('border-after', value, '');
  }

  /** Gets the value of "border-after-color" */
  String get borderAfterColor =>
    getPropertyValue('border-after-color');

  /** Sets the value of "border-after-color" */
  set borderAfterColor(String value) {
    setProperty('border-after-color', value, '');
  }

  /** Gets the value of "border-after-style" */
  String get borderAfterStyle =>
    getPropertyValue('border-after-style');

  /** Sets the value of "border-after-style" */
  set borderAfterStyle(String value) {
    setProperty('border-after-style', value, '');
  }

  /** Gets the value of "border-after-width" */
  String get borderAfterWidth =>
    getPropertyValue('border-after-width');

  /** Sets the value of "border-after-width" */
  set borderAfterWidth(String value) {
    setProperty('border-after-width', value, '');
  }

  /** Gets the value of "border-before" */
  String get borderBefore =>
    getPropertyValue('border-before');

  /** Sets the value of "border-before" */
  set borderBefore(String value) {
    setProperty('border-before', value, '');
  }

  /** Gets the value of "border-before-color" */
  String get borderBeforeColor =>
    getPropertyValue('border-before-color');

  /** Sets the value of "border-before-color" */
  set borderBeforeColor(String value) {
    setProperty('border-before-color', value, '');
  }

  /** Gets the value of "border-before-style" */
  String get borderBeforeStyle =>
    getPropertyValue('border-before-style');

  /** Sets the value of "border-before-style" */
  set borderBeforeStyle(String value) {
    setProperty('border-before-style', value, '');
  }

  /** Gets the value of "border-before-width" */
  String get borderBeforeWidth =>
    getPropertyValue('border-before-width');

  /** Sets the value of "border-before-width" */
  set borderBeforeWidth(String value) {
    setProperty('border-before-width', value, '');
  }

  /** Gets the value of "border-bottom" */
  String get borderBottom =>
    getPropertyValue('border-bottom');

  /** Sets the value of "border-bottom" */
  set borderBottom(String value) {
    setProperty('border-bottom', value, '');
  }

  /** Gets the value of "border-bottom-color" */
  String get borderBottomColor =>
    getPropertyValue('border-bottom-color');

  /** Sets the value of "border-bottom-color" */
  set borderBottomColor(String value) {
    setProperty('border-bottom-color', value, '');
  }

  /** Gets the value of "border-bottom-left-radius" */
  String get borderBottomLeftRadius =>
    getPropertyValue('border-bottom-left-radius');

  /** Sets the value of "border-bottom-left-radius" */
  set borderBottomLeftRadius(String value) {
    setProperty('border-bottom-left-radius', value, '');
  }

  /** Gets the value of "border-bottom-right-radius" */
  String get borderBottomRightRadius =>
    getPropertyValue('border-bottom-right-radius');

  /** Sets the value of "border-bottom-right-radius" */
  set borderBottomRightRadius(String value) {
    setProperty('border-bottom-right-radius', value, '');
  }

  /** Gets the value of "border-bottom-style" */
  String get borderBottomStyle =>
    getPropertyValue('border-bottom-style');

  /** Sets the value of "border-bottom-style" */
  set borderBottomStyle(String value) {
    setProperty('border-bottom-style', value, '');
  }

  /** Gets the value of "border-bottom-width" */
  String get borderBottomWidth =>
    getPropertyValue('border-bottom-width');

  /** Sets the value of "border-bottom-width" */
  set borderBottomWidth(String value) {
    setProperty('border-bottom-width', value, '');
  }

  /** Gets the value of "border-collapse" */
  String get borderCollapse =>
    getPropertyValue('border-collapse');

  /** Sets the value of "border-collapse" */
  set borderCollapse(String value) {
    setProperty('border-collapse', value, '');
  }

  /** Gets the value of "border-color" */
  String get borderColor =>
    getPropertyValue('border-color');

  /** Sets the value of "border-color" */
  set borderColor(String value) {
    setProperty('border-color', value, '');
  }

  /** Gets the value of "border-end" */
  String get borderEnd =>
    getPropertyValue('border-end');

  /** Sets the value of "border-end" */
  set borderEnd(String value) {
    setProperty('border-end', value, '');
  }

  /** Gets the value of "border-end-color" */
  String get borderEndColor =>
    getPropertyValue('border-end-color');

  /** Sets the value of "border-end-color" */
  set borderEndColor(String value) {
    setProperty('border-end-color', value, '');
  }

  /** Gets the value of "border-end-style" */
  String get borderEndStyle =>
    getPropertyValue('border-end-style');

  /** Sets the value of "border-end-style" */
  set borderEndStyle(String value) {
    setProperty('border-end-style', value, '');
  }

  /** Gets the value of "border-end-width" */
  String get borderEndWidth =>
    getPropertyValue('border-end-width');

  /** Sets the value of "border-end-width" */
  set borderEndWidth(String value) {
    setProperty('border-end-width', value, '');
  }

  /** Gets the value of "border-fit" */
  String get borderFit =>
    getPropertyValue('border-fit');

  /** Sets the value of "border-fit" */
  set borderFit(String value) {
    setProperty('border-fit', value, '');
  }

  /** Gets the value of "border-horizontal-spacing" */
  String get borderHorizontalSpacing =>
    getPropertyValue('border-horizontal-spacing');

  /** Sets the value of "border-horizontal-spacing" */
  set borderHorizontalSpacing(String value) {
    setProperty('border-horizontal-spacing', value, '');
  }

  /** Gets the value of "border-image" */
  String get borderImage =>
    getPropertyValue('border-image');

  /** Sets the value of "border-image" */
  set borderImage(String value) {
    setProperty('border-image', value, '');
  }

  /** Gets the value of "border-image-outset" */
  String get borderImageOutset =>
    getPropertyValue('border-image-outset');

  /** Sets the value of "border-image-outset" */
  set borderImageOutset(String value) {
    setProperty('border-image-outset', value, '');
  }

  /** Gets the value of "border-image-repeat" */
  String get borderImageRepeat =>
    getPropertyValue('border-image-repeat');

  /** Sets the value of "border-image-repeat" */
  set borderImageRepeat(String value) {
    setProperty('border-image-repeat', value, '');
  }

  /** Gets the value of "border-image-slice" */
  String get borderImageSlice =>
    getPropertyValue('border-image-slice');

  /** Sets the value of "border-image-slice" */
  set borderImageSlice(String value) {
    setProperty('border-image-slice', value, '');
  }

  /** Gets the value of "border-image-source" */
  String get borderImageSource =>
    getPropertyValue('border-image-source');

  /** Sets the value of "border-image-source" */
  set borderImageSource(String value) {
    setProperty('border-image-source', value, '');
  }

  /** Gets the value of "border-image-width" */
  String get borderImageWidth =>
    getPropertyValue('border-image-width');

  /** Sets the value of "border-image-width" */
  set borderImageWidth(String value) {
    setProperty('border-image-width', value, '');
  }

  /** Gets the value of "border-left" */
  String get borderLeft =>
    getPropertyValue('border-left');

  /** Sets the value of "border-left" */
  set borderLeft(String value) {
    setProperty('border-left', value, '');
  }

  /** Gets the value of "border-left-color" */
  String get borderLeftColor =>
    getPropertyValue('border-left-color');

  /** Sets the value of "border-left-color" */
  set borderLeftColor(String value) {
    setProperty('border-left-color', value, '');
  }

  /** Gets the value of "border-left-style" */
  String get borderLeftStyle =>
    getPropertyValue('border-left-style');

  /** Sets the value of "border-left-style" */
  set borderLeftStyle(String value) {
    setProperty('border-left-style', value, '');
  }

  /** Gets the value of "border-left-width" */
  String get borderLeftWidth =>
    getPropertyValue('border-left-width');

  /** Sets the value of "border-left-width" */
  set borderLeftWidth(String value) {
    setProperty('border-left-width', value, '');
  }

  /** Gets the value of "border-radius" */
  String get borderRadius =>
    getPropertyValue('border-radius');

  /** Sets the value of "border-radius" */
  set borderRadius(String value) {
    setProperty('border-radius', value, '');
  }

  /** Gets the value of "border-right" */
  String get borderRight =>
    getPropertyValue('border-right');

  /** Sets the value of "border-right" */
  set borderRight(String value) {
    setProperty('border-right', value, '');
  }

  /** Gets the value of "border-right-color" */
  String get borderRightColor =>
    getPropertyValue('border-right-color');

  /** Sets the value of "border-right-color" */
  set borderRightColor(String value) {
    setProperty('border-right-color', value, '');
  }

  /** Gets the value of "border-right-style" */
  String get borderRightStyle =>
    getPropertyValue('border-right-style');

  /** Sets the value of "border-right-style" */
  set borderRightStyle(String value) {
    setProperty('border-right-style', value, '');
  }

  /** Gets the value of "border-right-width" */
  String get borderRightWidth =>
    getPropertyValue('border-right-width');

  /** Sets the value of "border-right-width" */
  set borderRightWidth(String value) {
    setProperty('border-right-width', value, '');
  }

  /** Gets the value of "border-spacing" */
  String get borderSpacing =>
    getPropertyValue('border-spacing');

  /** Sets the value of "border-spacing" */
  set borderSpacing(String value) {
    setProperty('border-spacing', value, '');
  }

  /** Gets the value of "border-start" */
  String get borderStart =>
    getPropertyValue('border-start');

  /** Sets the value of "border-start" */
  set borderStart(String value) {
    setProperty('border-start', value, '');
  }

  /** Gets the value of "border-start-color" */
  String get borderStartColor =>
    getPropertyValue('border-start-color');

  /** Sets the value of "border-start-color" */
  set borderStartColor(String value) {
    setProperty('border-start-color', value, '');
  }

  /** Gets the value of "border-start-style" */
  String get borderStartStyle =>
    getPropertyValue('border-start-style');

  /** Sets the value of "border-start-style" */
  set borderStartStyle(String value) {
    setProperty('border-start-style', value, '');
  }

  /** Gets the value of "border-start-width" */
  String get borderStartWidth =>
    getPropertyValue('border-start-width');

  /** Sets the value of "border-start-width" */
  set borderStartWidth(String value) {
    setProperty('border-start-width', value, '');
  }

  /** Gets the value of "border-style" */
  String get borderStyle =>
    getPropertyValue('border-style');

  /** Sets the value of "border-style" */
  set borderStyle(String value) {
    setProperty('border-style', value, '');
  }

  /** Gets the value of "border-top" */
  String get borderTop =>
    getPropertyValue('border-top');

  /** Sets the value of "border-top" */
  set borderTop(String value) {
    setProperty('border-top', value, '');
  }

  /** Gets the value of "border-top-color" */
  String get borderTopColor =>
    getPropertyValue('border-top-color');

  /** Sets the value of "border-top-color" */
  set borderTopColor(String value) {
    setProperty('border-top-color', value, '');
  }

  /** Gets the value of "border-top-left-radius" */
  String get borderTopLeftRadius =>
    getPropertyValue('border-top-left-radius');

  /** Sets the value of "border-top-left-radius" */
  set borderTopLeftRadius(String value) {
    setProperty('border-top-left-radius', value, '');
  }

  /** Gets the value of "border-top-right-radius" */
  String get borderTopRightRadius =>
    getPropertyValue('border-top-right-radius');

  /** Sets the value of "border-top-right-radius" */
  set borderTopRightRadius(String value) {
    setProperty('border-top-right-radius', value, '');
  }

  /** Gets the value of "border-top-style" */
  String get borderTopStyle =>
    getPropertyValue('border-top-style');

  /** Sets the value of "border-top-style" */
  set borderTopStyle(String value) {
    setProperty('border-top-style', value, '');
  }

  /** Gets the value of "border-top-width" */
  String get borderTopWidth =>
    getPropertyValue('border-top-width');

  /** Sets the value of "border-top-width" */
  set borderTopWidth(String value) {
    setProperty('border-top-width', value, '');
  }

  /** Gets the value of "border-vertical-spacing" */
  String get borderVerticalSpacing =>
    getPropertyValue('border-vertical-spacing');

  /** Sets the value of "border-vertical-spacing" */
  set borderVerticalSpacing(String value) {
    setProperty('border-vertical-spacing', value, '');
  }

  /** Gets the value of "border-width" */
  String get borderWidth =>
    getPropertyValue('border-width');

  /** Sets the value of "border-width" */
  set borderWidth(String value) {
    setProperty('border-width', value, '');
  }

  /** Gets the value of "bottom" */
  String get bottom =>
    getPropertyValue('bottom');

  /** Sets the value of "bottom" */
  set bottom(String value) {
    setProperty('bottom', value, '');
  }

  /** Gets the value of "box-align" */
  String get boxAlign =>
    getPropertyValue('box-align');

  /** Sets the value of "box-align" */
  set boxAlign(String value) {
    setProperty('box-align', value, '');
  }

  /** Gets the value of "box-decoration-break" */
  String get boxDecorationBreak =>
    getPropertyValue('box-decoration-break');

  /** Sets the value of "box-decoration-break" */
  set boxDecorationBreak(String value) {
    setProperty('box-decoration-break', value, '');
  }

  /** Gets the value of "box-direction" */
  String get boxDirection =>
    getPropertyValue('box-direction');

  /** Sets the value of "box-direction" */
  set boxDirection(String value) {
    setProperty('box-direction', value, '');
  }

  /** Gets the value of "box-flex" */
  String get boxFlex =>
    getPropertyValue('box-flex');

  /** Sets the value of "box-flex" */
  set boxFlex(String value) {
    setProperty('box-flex', value, '');
  }

  /** Gets the value of "box-flex-group" */
  String get boxFlexGroup =>
    getPropertyValue('box-flex-group');

  /** Sets the value of "box-flex-group" */
  set boxFlexGroup(String value) {
    setProperty('box-flex-group', value, '');
  }

  /** Gets the value of "box-lines" */
  String get boxLines =>
    getPropertyValue('box-lines');

  /** Sets the value of "box-lines" */
  set boxLines(String value) {
    setProperty('box-lines', value, '');
  }

  /** Gets the value of "box-ordinal-group" */
  String get boxOrdinalGroup =>
    getPropertyValue('box-ordinal-group');

  /** Sets the value of "box-ordinal-group" */
  set boxOrdinalGroup(String value) {
    setProperty('box-ordinal-group', value, '');
  }

  /** Gets the value of "box-orient" */
  String get boxOrient =>
    getPropertyValue('box-orient');

  /** Sets the value of "box-orient" */
  set boxOrient(String value) {
    setProperty('box-orient', value, '');
  }

  /** Gets the value of "box-pack" */
  String get boxPack =>
    getPropertyValue('box-pack');

  /** Sets the value of "box-pack" */
  set boxPack(String value) {
    setProperty('box-pack', value, '');
  }

  /** Gets the value of "box-reflect" */
  String get boxReflect =>
    getPropertyValue('box-reflect');

  /** Sets the value of "box-reflect" */
  set boxReflect(String value) {
    setProperty('box-reflect', value, '');
  }

  /** Gets the value of "box-shadow" */
  String get boxShadow =>
    getPropertyValue('box-shadow');

  /** Sets the value of "box-shadow" */
  set boxShadow(String value) {
    setProperty('box-shadow', value, '');
  }

  /** Gets the value of "box-sizing" */
  String get boxSizing =>
    getPropertyValue('box-sizing');

  /** Sets the value of "box-sizing" */
  set boxSizing(String value) {
    setProperty('box-sizing', value, '');
  }

  /** Gets the value of "caption-side" */
  String get captionSide =>
    getPropertyValue('caption-side');

  /** Sets the value of "caption-side" */
  set captionSide(String value) {
    setProperty('caption-side', value, '');
  }

  /** Gets the value of "clear" */
  String get clear =>
    getPropertyValue('clear');

  /** Sets the value of "clear" */
  set clear(String value) {
    setProperty('clear', value, '');
  }

  /** Gets the value of "clip" */
  String get clip =>
    getPropertyValue('clip');

  /** Sets the value of "clip" */
  set clip(String value) {
    setProperty('clip', value, '');
  }

  /** Gets the value of "clip-path" */
  String get clipPath =>
    getPropertyValue('clip-path');

  /** Sets the value of "clip-path" */
  set clipPath(String value) {
    setProperty('clip-path', value, '');
  }

  /** Gets the value of "color" */
  String get color =>
    getPropertyValue('color');

  /** Sets the value of "color" */
  set color(String value) {
    setProperty('color', value, '');
  }

  /** Gets the value of "column-break-after" */
  String get columnBreakAfter =>
    getPropertyValue('column-break-after');

  /** Sets the value of "column-break-after" */
  set columnBreakAfter(String value) {
    setProperty('column-break-after', value, '');
  }

  /** Gets the value of "column-break-before" */
  String get columnBreakBefore =>
    getPropertyValue('column-break-before');

  /** Sets the value of "column-break-before" */
  set columnBreakBefore(String value) {
    setProperty('column-break-before', value, '');
  }

  /** Gets the value of "column-break-inside" */
  String get columnBreakInside =>
    getPropertyValue('column-break-inside');

  /** Sets the value of "column-break-inside" */
  set columnBreakInside(String value) {
    setProperty('column-break-inside', value, '');
  }

  /** Gets the value of "column-count" */
  String get columnCount =>
    getPropertyValue('column-count');

  /** Sets the value of "column-count" */
  set columnCount(String value) {
    setProperty('column-count', value, '');
  }

  /** Gets the value of "column-fill" */
  String get columnFill =>
    getPropertyValue('column-fill');

  /** Sets the value of "column-fill" */
  set columnFill(String value) {
    setProperty('column-fill', value, '');
  }

  /** Gets the value of "column-gap" */
  String get columnGap =>
    getPropertyValue('column-gap');

  /** Sets the value of "column-gap" */
  set columnGap(String value) {
    setProperty('column-gap', value, '');
  }

  /** Gets the value of "column-rule" */
  String get columnRule =>
    getPropertyValue('column-rule');

  /** Sets the value of "column-rule" */
  set columnRule(String value) {
    setProperty('column-rule', value, '');
  }

  /** Gets the value of "column-rule-color" */
  String get columnRuleColor =>
    getPropertyValue('column-rule-color');

  /** Sets the value of "column-rule-color" */
  set columnRuleColor(String value) {
    setProperty('column-rule-color', value, '');
  }

  /** Gets the value of "column-rule-style" */
  String get columnRuleStyle =>
    getPropertyValue('column-rule-style');

  /** Sets the value of "column-rule-style" */
  set columnRuleStyle(String value) {
    setProperty('column-rule-style', value, '');
  }

  /** Gets the value of "column-rule-width" */
  String get columnRuleWidth =>
    getPropertyValue('column-rule-width');

  /** Sets the value of "column-rule-width" */
  set columnRuleWidth(String value) {
    setProperty('column-rule-width', value, '');
  }

  /** Gets the value of "column-span" */
  String get columnSpan =>
    getPropertyValue('column-span');

  /** Sets the value of "column-span" */
  set columnSpan(String value) {
    setProperty('column-span', value, '');
  }

  /** Gets the value of "column-width" */
  String get columnWidth =>
    getPropertyValue('column-width');

  /** Sets the value of "column-width" */
  set columnWidth(String value) {
    setProperty('column-width', value, '');
  }

  /** Gets the value of "columns" */
  String get columns =>
    getPropertyValue('columns');

  /** Sets the value of "columns" */
  set columns(String value) {
    setProperty('columns', value, '');
  }

  /** Gets the value of "content" */
  String get content =>
    getPropertyValue('content');

  /** Sets the value of "content" */
  set content(String value) {
    setProperty('content', value, '');
  }

  /** Gets the value of "counter-increment" */
  String get counterIncrement =>
    getPropertyValue('counter-increment');

  /** Sets the value of "counter-increment" */
  set counterIncrement(String value) {
    setProperty('counter-increment', value, '');
  }

  /** Gets the value of "counter-reset" */
  String get counterReset =>
    getPropertyValue('counter-reset');

  /** Sets the value of "counter-reset" */
  set counterReset(String value) {
    setProperty('counter-reset', value, '');
  }

  /** Gets the value of "cursor" */
  String get cursor =>
    getPropertyValue('cursor');

  /** Sets the value of "cursor" */
  set cursor(String value) {
    setProperty('cursor', value, '');
  }

  /** Gets the value of "direction" */
  String get direction =>
    getPropertyValue('direction');

  /** Sets the value of "direction" */
  set direction(String value) {
    setProperty('direction', value, '');
  }

  /** Gets the value of "display" */
  String get display =>
    getPropertyValue('display');

  /** Sets the value of "display" */
  set display(String value) {
    setProperty('display', value, '');
  }

  /** Gets the value of "empty-cells" */
  String get emptyCells =>
    getPropertyValue('empty-cells');

  /** Sets the value of "empty-cells" */
  set emptyCells(String value) {
    setProperty('empty-cells', value, '');
  }

  /** Gets the value of "filter" */
  String get filter =>
    getPropertyValue('filter');

  /** Sets the value of "filter" */
  set filter(String value) {
    setProperty('filter', value, '');
  }

  /** Gets the value of "flex" */
  String get flex =>
    getPropertyValue('flex');

  /** Sets the value of "flex" */
  set flex(String value) {
    setProperty('flex', value, '');
  }

  /** Gets the value of "flex-basis" */
  String get flexBasis =>
    getPropertyValue('flex-basis');

  /** Sets the value of "flex-basis" */
  set flexBasis(String value) {
    setProperty('flex-basis', value, '');
  }

  /** Gets the value of "flex-direction" */
  String get flexDirection =>
    getPropertyValue('flex-direction');

  /** Sets the value of "flex-direction" */
  set flexDirection(String value) {
    setProperty('flex-direction', value, '');
  }

  /** Gets the value of "flex-flow" */
  String get flexFlow =>
    getPropertyValue('flex-flow');

  /** Sets the value of "flex-flow" */
  set flexFlow(String value) {
    setProperty('flex-flow', value, '');
  }

  /** Gets the value of "flex-grow" */
  String get flexGrow =>
    getPropertyValue('flex-grow');

  /** Sets the value of "flex-grow" */
  set flexGrow(String value) {
    setProperty('flex-grow', value, '');
  }

  /** Gets the value of "flex-shrink" */
  String get flexShrink =>
    getPropertyValue('flex-shrink');

  /** Sets the value of "flex-shrink" */
  set flexShrink(String value) {
    setProperty('flex-shrink', value, '');
  }

  /** Gets the value of "flex-wrap" */
  String get flexWrap =>
    getPropertyValue('flex-wrap');

  /** Sets the value of "flex-wrap" */
  set flexWrap(String value) {
    setProperty('flex-wrap', value, '');
  }

  /** Gets the value of "float" */
  String get float =>
    getPropertyValue('float');

  /** Sets the value of "float" */
  set float(String value) {
    setProperty('float', value, '');
  }

  /** Gets the value of "font" */
  String get font =>
    getPropertyValue('font');

  /** Sets the value of "font" */
  set font(String value) {
    setProperty('font', value, '');
  }

  /** Gets the value of "font-family" */
  String get fontFamily =>
    getPropertyValue('font-family');

  /** Sets the value of "font-family" */
  set fontFamily(String value) {
    setProperty('font-family', value, '');
  }

  /** Gets the value of "font-feature-settings" */
  String get fontFeatureSettings =>
    getPropertyValue('font-feature-settings');

  /** Sets the value of "font-feature-settings" */
  set fontFeatureSettings(String value) {
    setProperty('font-feature-settings', value, '');
  }

  /** Gets the value of "font-kerning" */
  String get fontKerning =>
    getPropertyValue('font-kerning');

  /** Sets the value of "font-kerning" */
  set fontKerning(String value) {
    setProperty('font-kerning', value, '');
  }

  /** Gets the value of "font-size" */
  String get fontSize =>
    getPropertyValue('font-size');

  /** Sets the value of "font-size" */
  set fontSize(String value) {
    setProperty('font-size', value, '');
  }

  /** Gets the value of "font-size-delta" */
  String get fontSizeDelta =>
    getPropertyValue('font-size-delta');

  /** Sets the value of "font-size-delta" */
  set fontSizeDelta(String value) {
    setProperty('font-size-delta', value, '');
  }

  /** Gets the value of "font-smoothing" */
  String get fontSmoothing =>
    getPropertyValue('font-smoothing');

  /** Sets the value of "font-smoothing" */
  set fontSmoothing(String value) {
    setProperty('font-smoothing', value, '');
  }

  /** Gets the value of "font-stretch" */
  String get fontStretch =>
    getPropertyValue('font-stretch');

  /** Sets the value of "font-stretch" */
  set fontStretch(String value) {
    setProperty('font-stretch', value, '');
  }

  /** Gets the value of "font-style" */
  String get fontStyle =>
    getPropertyValue('font-style');

  /** Sets the value of "font-style" */
  set fontStyle(String value) {
    setProperty('font-style', value, '');
  }

  /** Gets the value of "font-variant" */
  String get fontVariant =>
    getPropertyValue('font-variant');

  /** Sets the value of "font-variant" */
  set fontVariant(String value) {
    setProperty('font-variant', value, '');
  }

  /** Gets the value of "font-variant-ligatures" */
  String get fontVariantLigatures =>
    getPropertyValue('font-variant-ligatures');

  /** Sets the value of "font-variant-ligatures" */
  set fontVariantLigatures(String value) {
    setProperty('font-variant-ligatures', value, '');
  }

  /** Gets the value of "font-weight" */
  String get fontWeight =>
    getPropertyValue('font-weight');

  /** Sets the value of "font-weight" */
  set fontWeight(String value) {
    setProperty('font-weight', value, '');
  }

  /** Gets the value of "grid" */
  String get grid =>
    getPropertyValue('grid');

  /** Sets the value of "grid" */
  set grid(String value) {
    setProperty('grid', value, '');
  }

  /** Gets the value of "grid-area" */
  String get gridArea =>
    getPropertyValue('grid-area');

  /** Sets the value of "grid-area" */
  set gridArea(String value) {
    setProperty('grid-area', value, '');
  }

  /** Gets the value of "grid-auto-columns" */
  String get gridAutoColumns =>
    getPropertyValue('grid-auto-columns');

  /** Sets the value of "grid-auto-columns" */
  set gridAutoColumns(String value) {
    setProperty('grid-auto-columns', value, '');
  }

  /** Gets the value of "grid-auto-flow" */
  String get gridAutoFlow =>
    getPropertyValue('grid-auto-flow');

  /** Sets the value of "grid-auto-flow" */
  set gridAutoFlow(String value) {
    setProperty('grid-auto-flow', value, '');
  }

  /** Gets the value of "grid-auto-rows" */
  String get gridAutoRows =>
    getPropertyValue('grid-auto-rows');

  /** Sets the value of "grid-auto-rows" */
  set gridAutoRows(String value) {
    setProperty('grid-auto-rows', value, '');
  }

  /** Gets the value of "grid-column" */
  String get gridColumn =>
    getPropertyValue('grid-column');

  /** Sets the value of "grid-column" */
  set gridColumn(String value) {
    setProperty('grid-column', value, '');
  }

  /** Gets the value of "grid-column-end" */
  String get gridColumnEnd =>
    getPropertyValue('grid-column-end');

  /** Sets the value of "grid-column-end" */
  set gridColumnEnd(String value) {
    setProperty('grid-column-end', value, '');
  }

  /** Gets the value of "grid-column-start" */
  String get gridColumnStart =>
    getPropertyValue('grid-column-start');

  /** Sets the value of "grid-column-start" */
  set gridColumnStart(String value) {
    setProperty('grid-column-start', value, '');
  }

  /** Gets the value of "grid-row" */
  String get gridRow =>
    getPropertyValue('grid-row');

  /** Sets the value of "grid-row" */
  set gridRow(String value) {
    setProperty('grid-row', value, '');
  }

  /** Gets the value of "grid-row-end" */
  String get gridRowEnd =>
    getPropertyValue('grid-row-end');

  /** Sets the value of "grid-row-end" */
  set gridRowEnd(String value) {
    setProperty('grid-row-end', value, '');
  }

  /** Gets the value of "grid-row-start" */
  String get gridRowStart =>
    getPropertyValue('grid-row-start');

  /** Sets the value of "grid-row-start" */
  set gridRowStart(String value) {
    setProperty('grid-row-start', value, '');
  }

  /** Gets the value of "grid-template" */
  String get gridTemplate =>
    getPropertyValue('grid-template');

  /** Sets the value of "grid-template" */
  set gridTemplate(String value) {
    setProperty('grid-template', value, '');
  }

  /** Gets the value of "grid-template-areas" */
  String get gridTemplateAreas =>
    getPropertyValue('grid-template-areas');

  /** Sets the value of "grid-template-areas" */
  set gridTemplateAreas(String value) {
    setProperty('grid-template-areas', value, '');
  }

  /** Gets the value of "grid-template-columns" */
  String get gridTemplateColumns =>
    getPropertyValue('grid-template-columns');

  /** Sets the value of "grid-template-columns" */
  set gridTemplateColumns(String value) {
    setProperty('grid-template-columns', value, '');
  }

  /** Gets the value of "grid-template-rows" */
  String get gridTemplateRows =>
    getPropertyValue('grid-template-rows');

  /** Sets the value of "grid-template-rows" */
  set gridTemplateRows(String value) {
    setProperty('grid-template-rows', value, '');
  }

  /** Gets the value of "height" */
  String get height =>
    getPropertyValue('height');

  /** Sets the value of "height" */
  set height(String value) {
    setProperty('height', value, '');
  }

  /** Gets the value of "highlight" */
  String get highlight =>
    getPropertyValue('highlight');

  /** Sets the value of "highlight" */
  set highlight(String value) {
    setProperty('highlight', value, '');
  }

  /** Gets the value of "hyphenate-character" */
  String get hyphenateCharacter =>
    getPropertyValue('hyphenate-character');

  /** Sets the value of "hyphenate-character" */
  set hyphenateCharacter(String value) {
    setProperty('hyphenate-character', value, '');
  }

  /** Gets the value of "image-rendering" */
  String get imageRendering =>
    getPropertyValue('image-rendering');

  /** Sets the value of "image-rendering" */
  set imageRendering(String value) {
    setProperty('image-rendering', value, '');
  }

  /** Gets the value of "isolation" */
  String get isolation =>
    getPropertyValue('isolation');

  /** Sets the value of "isolation" */
  set isolation(String value) {
    setProperty('isolation', value, '');
  }

  /** Gets the value of "justify-content" */
  String get justifyContent =>
    getPropertyValue('justify-content');

  /** Sets the value of "justify-content" */
  set justifyContent(String value) {
    setProperty('justify-content', value, '');
  }

  /** Gets the value of "justify-self" */
  String get justifySelf =>
    getPropertyValue('justify-self');

  /** Sets the value of "justify-self" */
  set justifySelf(String value) {
    setProperty('justify-self', value, '');
  }

  /** Gets the value of "left" */
  String get left =>
    getPropertyValue('left');

  /** Sets the value of "left" */
  set left(String value) {
    setProperty('left', value, '');
  }

  /** Gets the value of "letter-spacing" */
  String get letterSpacing =>
    getPropertyValue('letter-spacing');

  /** Sets the value of "letter-spacing" */
  set letterSpacing(String value) {
    setProperty('letter-spacing', value, '');
  }

  /** Gets the value of "line-box-contain" */
  String get lineBoxContain =>
    getPropertyValue('line-box-contain');

  /** Sets the value of "line-box-contain" */
  set lineBoxContain(String value) {
    setProperty('line-box-contain', value, '');
  }

  /** Gets the value of "line-break" */
  String get lineBreak =>
    getPropertyValue('line-break');

  /** Sets the value of "line-break" */
  set lineBreak(String value) {
    setProperty('line-break', value, '');
  }

  /** Gets the value of "line-clamp" */
  String get lineClamp =>
    getPropertyValue('line-clamp');

  /** Sets the value of "line-clamp" */
  set lineClamp(String value) {
    setProperty('line-clamp', value, '');
  }

  /** Gets the value of "line-height" */
  String get lineHeight =>
    getPropertyValue('line-height');

  /** Sets the value of "line-height" */
  set lineHeight(String value) {
    setProperty('line-height', value, '');
  }

  /** Gets the value of "list-style" */
  String get listStyle =>
    getPropertyValue('list-style');

  /** Sets the value of "list-style" */
  set listStyle(String value) {
    setProperty('list-style', value, '');
  }

  /** Gets the value of "list-style-image" */
  String get listStyleImage =>
    getPropertyValue('list-style-image');

  /** Sets the value of "list-style-image" */
  set listStyleImage(String value) {
    setProperty('list-style-image', value, '');
  }

  /** Gets the value of "list-style-position" */
  String get listStylePosition =>
    getPropertyValue('list-style-position');

  /** Sets the value of "list-style-position" */
  set listStylePosition(String value) {
    setProperty('list-style-position', value, '');
  }

  /** Gets the value of "list-style-type" */
  String get listStyleType =>
    getPropertyValue('list-style-type');

  /** Sets the value of "list-style-type" */
  set listStyleType(String value) {
    setProperty('list-style-type', value, '');
  }

  /** Gets the value of "locale" */
  String get locale =>
    getPropertyValue('locale');

  /** Sets the value of "locale" */
  set locale(String value) {
    setProperty('locale', value, '');
  }

  /** Gets the value of "logical-height" */
  String get logicalHeight =>
    getPropertyValue('logical-height');

  /** Sets the value of "logical-height" */
  set logicalHeight(String value) {
    setProperty('logical-height', value, '');
  }

  /** Gets the value of "logical-width" */
  String get logicalWidth =>
    getPropertyValue('logical-width');

  /** Sets the value of "logical-width" */
  set logicalWidth(String value) {
    setProperty('logical-width', value, '');
  }

  /** Gets the value of "margin" */
  String get margin =>
    getPropertyValue('margin');

  /** Sets the value of "margin" */
  set margin(String value) {
    setProperty('margin', value, '');
  }

  /** Gets the value of "margin-after" */
  String get marginAfter =>
    getPropertyValue('margin-after');

  /** Sets the value of "margin-after" */
  set marginAfter(String value) {
    setProperty('margin-after', value, '');
  }

  /** Gets the value of "margin-after-collapse" */
  String get marginAfterCollapse =>
    getPropertyValue('margin-after-collapse');

  /** Sets the value of "margin-after-collapse" */
  set marginAfterCollapse(String value) {
    setProperty('margin-after-collapse', value, '');
  }

  /** Gets the value of "margin-before" */
  String get marginBefore =>
    getPropertyValue('margin-before');

  /** Sets the value of "margin-before" */
  set marginBefore(String value) {
    setProperty('margin-before', value, '');
  }

  /** Gets the value of "margin-before-collapse" */
  String get marginBeforeCollapse =>
    getPropertyValue('margin-before-collapse');

  /** Sets the value of "margin-before-collapse" */
  set marginBeforeCollapse(String value) {
    setProperty('margin-before-collapse', value, '');
  }

  /** Gets the value of "margin-bottom" */
  String get marginBottom =>
    getPropertyValue('margin-bottom');

  /** Sets the value of "margin-bottom" */
  set marginBottom(String value) {
    setProperty('margin-bottom', value, '');
  }

  /** Gets the value of "margin-bottom-collapse" */
  String get marginBottomCollapse =>
    getPropertyValue('margin-bottom-collapse');

  /** Sets the value of "margin-bottom-collapse" */
  set marginBottomCollapse(String value) {
    setProperty('margin-bottom-collapse', value, '');
  }

  /** Gets the value of "margin-collapse" */
  String get marginCollapse =>
    getPropertyValue('margin-collapse');

  /** Sets the value of "margin-collapse" */
  set marginCollapse(String value) {
    setProperty('margin-collapse', value, '');
  }

  /** Gets the value of "margin-end" */
  String get marginEnd =>
    getPropertyValue('margin-end');

  /** Sets the value of "margin-end" */
  set marginEnd(String value) {
    setProperty('margin-end', value, '');
  }

  /** Gets the value of "margin-left" */
  String get marginLeft =>
    getPropertyValue('margin-left');

  /** Sets the value of "margin-left" */
  set marginLeft(String value) {
    setProperty('margin-left', value, '');
  }

  /** Gets the value of "margin-right" */
  String get marginRight =>
    getPropertyValue('margin-right');

  /** Sets the value of "margin-right" */
  set marginRight(String value) {
    setProperty('margin-right', value, '');
  }

  /** Gets the value of "margin-start" */
  String get marginStart =>
    getPropertyValue('margin-start');

  /** Sets the value of "margin-start" */
  set marginStart(String value) {
    setProperty('margin-start', value, '');
  }

  /** Gets the value of "margin-top" */
  String get marginTop =>
    getPropertyValue('margin-top');

  /** Sets the value of "margin-top" */
  set marginTop(String value) {
    setProperty('margin-top', value, '');
  }

  /** Gets the value of "margin-top-collapse" */
  String get marginTopCollapse =>
    getPropertyValue('margin-top-collapse');

  /** Sets the value of "margin-top-collapse" */
  set marginTopCollapse(String value) {
    setProperty('margin-top-collapse', value, '');
  }

  /** Gets the value of "mask" */
  String get mask =>
    getPropertyValue('mask');

  /** Sets the value of "mask" */
  set mask(String value) {
    setProperty('mask', value, '');
  }

  /** Gets the value of "mask-box-image" */
  String get maskBoxImage =>
    getPropertyValue('mask-box-image');

  /** Sets the value of "mask-box-image" */
  set maskBoxImage(String value) {
    setProperty('mask-box-image', value, '');
  }

  /** Gets the value of "mask-box-image-outset" */
  String get maskBoxImageOutset =>
    getPropertyValue('mask-box-image-outset');

  /** Sets the value of "mask-box-image-outset" */
  set maskBoxImageOutset(String value) {
    setProperty('mask-box-image-outset', value, '');
  }

  /** Gets the value of "mask-box-image-repeat" */
  String get maskBoxImageRepeat =>
    getPropertyValue('mask-box-image-repeat');

  /** Sets the value of "mask-box-image-repeat" */
  set maskBoxImageRepeat(String value) {
    setProperty('mask-box-image-repeat', value, '');
  }

  /** Gets the value of "mask-box-image-slice" */
  String get maskBoxImageSlice =>
    getPropertyValue('mask-box-image-slice');

  /** Sets the value of "mask-box-image-slice" */
  set maskBoxImageSlice(String value) {
    setProperty('mask-box-image-slice', value, '');
  }

  /** Gets the value of "mask-box-image-source" */
  String get maskBoxImageSource =>
    getPropertyValue('mask-box-image-source');

  /** Sets the value of "mask-box-image-source" */
  set maskBoxImageSource(String value) {
    setProperty('mask-box-image-source', value, '');
  }

  /** Gets the value of "mask-box-image-width" */
  String get maskBoxImageWidth =>
    getPropertyValue('mask-box-image-width');

  /** Sets the value of "mask-box-image-width" */
  set maskBoxImageWidth(String value) {
    setProperty('mask-box-image-width', value, '');
  }

  /** Gets the value of "mask-clip" */
  String get maskClip =>
    getPropertyValue('mask-clip');

  /** Sets the value of "mask-clip" */
  set maskClip(String value) {
    setProperty('mask-clip', value, '');
  }

  /** Gets the value of "mask-composite" */
  String get maskComposite =>
    getPropertyValue('mask-composite');

  /** Sets the value of "mask-composite" */
  set maskComposite(String value) {
    setProperty('mask-composite', value, '');
  }

  /** Gets the value of "mask-image" */
  String get maskImage =>
    getPropertyValue('mask-image');

  /** Sets the value of "mask-image" */
  set maskImage(String value) {
    setProperty('mask-image', value, '');
  }

  /** Gets the value of "mask-origin" */
  String get maskOrigin =>
    getPropertyValue('mask-origin');

  /** Sets the value of "mask-origin" */
  set maskOrigin(String value) {
    setProperty('mask-origin', value, '');
  }

  /** Gets the value of "mask-position" */
  String get maskPosition =>
    getPropertyValue('mask-position');

  /** Sets the value of "mask-position" */
  set maskPosition(String value) {
    setProperty('mask-position', value, '');
  }

  /** Gets the value of "mask-position-x" */
  String get maskPositionX =>
    getPropertyValue('mask-position-x');

  /** Sets the value of "mask-position-x" */
  set maskPositionX(String value) {
    setProperty('mask-position-x', value, '');
  }

  /** Gets the value of "mask-position-y" */
  String get maskPositionY =>
    getPropertyValue('mask-position-y');

  /** Sets the value of "mask-position-y" */
  set maskPositionY(String value) {
    setProperty('mask-position-y', value, '');
  }

  /** Gets the value of "mask-repeat" */
  String get maskRepeat =>
    getPropertyValue('mask-repeat');

  /** Sets the value of "mask-repeat" */
  set maskRepeat(String value) {
    setProperty('mask-repeat', value, '');
  }

  /** Gets the value of "mask-repeat-x" */
  String get maskRepeatX =>
    getPropertyValue('mask-repeat-x');

  /** Sets the value of "mask-repeat-x" */
  set maskRepeatX(String value) {
    setProperty('mask-repeat-x', value, '');
  }

  /** Gets the value of "mask-repeat-y" */
  String get maskRepeatY =>
    getPropertyValue('mask-repeat-y');

  /** Sets the value of "mask-repeat-y" */
  set maskRepeatY(String value) {
    setProperty('mask-repeat-y', value, '');
  }

  /** Gets the value of "mask-size" */
  String get maskSize =>
    getPropertyValue('mask-size');

  /** Sets the value of "mask-size" */
  set maskSize(String value) {
    setProperty('mask-size', value, '');
  }

  /** Gets the value of "mask-source-type" */
  String get maskSourceType =>
    getPropertyValue('mask-source-type');

  /** Sets the value of "mask-source-type" */
  set maskSourceType(String value) {
    setProperty('mask-source-type', value, '');
  }

  /** Gets the value of "max-height" */
  String get maxHeight =>
    getPropertyValue('max-height');

  /** Sets the value of "max-height" */
  set maxHeight(String value) {
    setProperty('max-height', value, '');
  }

  /** Gets the value of "max-logical-height" */
  String get maxLogicalHeight =>
    getPropertyValue('max-logical-height');

  /** Sets the value of "max-logical-height" */
  set maxLogicalHeight(String value) {
    setProperty('max-logical-height', value, '');
  }

  /** Gets the value of "max-logical-width" */
  String get maxLogicalWidth =>
    getPropertyValue('max-logical-width');

  /** Sets the value of "max-logical-width" */
  set maxLogicalWidth(String value) {
    setProperty('max-logical-width', value, '');
  }

  /** Gets the value of "max-width" */
  String get maxWidth =>
    getPropertyValue('max-width');

  /** Sets the value of "max-width" */
  set maxWidth(String value) {
    setProperty('max-width', value, '');
  }

  /** Gets the value of "max-zoom" */
  String get maxZoom =>
    getPropertyValue('max-zoom');

  /** Sets the value of "max-zoom" */
  set maxZoom(String value) {
    setProperty('max-zoom', value, '');
  }

  /** Gets the value of "min-height" */
  String get minHeight =>
    getPropertyValue('min-height');

  /** Sets the value of "min-height" */
  set minHeight(String value) {
    setProperty('min-height', value, '');
  }

  /** Gets the value of "min-logical-height" */
  String get minLogicalHeight =>
    getPropertyValue('min-logical-height');

  /** Sets the value of "min-logical-height" */
  set minLogicalHeight(String value) {
    setProperty('min-logical-height', value, '');
  }

  /** Gets the value of "min-logical-width" */
  String get minLogicalWidth =>
    getPropertyValue('min-logical-width');

  /** Sets the value of "min-logical-width" */
  set minLogicalWidth(String value) {
    setProperty('min-logical-width', value, '');
  }

  /** Gets the value of "min-width" */
  String get minWidth =>
    getPropertyValue('min-width');

  /** Sets the value of "min-width" */
  set minWidth(String value) {
    setProperty('min-width', value, '');
  }

  /** Gets the value of "min-zoom" */
  String get minZoom =>
    getPropertyValue('min-zoom');

  /** Sets the value of "min-zoom" */
  set minZoom(String value) {
    setProperty('min-zoom', value, '');
  }

  /** Gets the value of "mix-blend-mode" */
  String get mixBlendMode =>
    getPropertyValue('mix-blend-mode');

  /** Sets the value of "mix-blend-mode" */
  set mixBlendMode(String value) {
    setProperty('mix-blend-mode', value, '');
  }

  /** Gets the value of "object-fit" */
  String get objectFit =>
    getPropertyValue('object-fit');

  /** Sets the value of "object-fit" */
  set objectFit(String value) {
    setProperty('object-fit', value, '');
  }

  /** Gets the value of "object-position" */
  String get objectPosition =>
    getPropertyValue('object-position');

  /** Sets the value of "object-position" */
  set objectPosition(String value) {
    setProperty('object-position', value, '');
  }

  /** Gets the value of "opacity" */
  String get opacity =>
    getPropertyValue('opacity');

  /** Sets the value of "opacity" */
  set opacity(String value) {
    setProperty('opacity', value, '');
  }

  /** Gets the value of "order" */
  String get order =>
    getPropertyValue('order');

  /** Sets the value of "order" */
  set order(String value) {
    setProperty('order', value, '');
  }

  /** Gets the value of "orientation" */
  String get orientation =>
    getPropertyValue('orientation');

  /** Sets the value of "orientation" */
  set orientation(String value) {
    setProperty('orientation', value, '');
  }

  /** Gets the value of "orphans" */
  String get orphans =>
    getPropertyValue('orphans');

  /** Sets the value of "orphans" */
  set orphans(String value) {
    setProperty('orphans', value, '');
  }

  /** Gets the value of "outline" */
  String get outline =>
    getPropertyValue('outline');

  /** Sets the value of "outline" */
  set outline(String value) {
    setProperty('outline', value, '');
  }

  /** Gets the value of "outline-color" */
  String get outlineColor =>
    getPropertyValue('outline-color');

  /** Sets the value of "outline-color" */
  set outlineColor(String value) {
    setProperty('outline-color', value, '');
  }

  /** Gets the value of "outline-offset" */
  String get outlineOffset =>
    getPropertyValue('outline-offset');

  /** Sets the value of "outline-offset" */
  set outlineOffset(String value) {
    setProperty('outline-offset', value, '');
  }

  /** Gets the value of "outline-style" */
  String get outlineStyle =>
    getPropertyValue('outline-style');

  /** Sets the value of "outline-style" */
  set outlineStyle(String value) {
    setProperty('outline-style', value, '');
  }

  /** Gets the value of "outline-width" */
  String get outlineWidth =>
    getPropertyValue('outline-width');

  /** Sets the value of "outline-width" */
  set outlineWidth(String value) {
    setProperty('outline-width', value, '');
  }

  /** Gets the value of "overflow" */
  String get overflow =>
    getPropertyValue('overflow');

  /** Sets the value of "overflow" */
  set overflow(String value) {
    setProperty('overflow', value, '');
  }

  /** Gets the value of "overflow-wrap" */
  String get overflowWrap =>
    getPropertyValue('overflow-wrap');

  /** Sets the value of "overflow-wrap" */
  set overflowWrap(String value) {
    setProperty('overflow-wrap', value, '');
  }

  /** Gets the value of "overflow-x" */
  String get overflowX =>
    getPropertyValue('overflow-x');

  /** Sets the value of "overflow-x" */
  set overflowX(String value) {
    setProperty('overflow-x', value, '');
  }

  /** Gets the value of "overflow-y" */
  String get overflowY =>
    getPropertyValue('overflow-y');

  /** Sets the value of "overflow-y" */
  set overflowY(String value) {
    setProperty('overflow-y', value, '');
  }

  /** Gets the value of "padding" */
  String get padding =>
    getPropertyValue('padding');

  /** Sets the value of "padding" */
  set padding(String value) {
    setProperty('padding', value, '');
  }

  /** Gets the value of "padding-after" */
  String get paddingAfter =>
    getPropertyValue('padding-after');

  /** Sets the value of "padding-after" */
  set paddingAfter(String value) {
    setProperty('padding-after', value, '');
  }

  /** Gets the value of "padding-before" */
  String get paddingBefore =>
    getPropertyValue('padding-before');

  /** Sets the value of "padding-before" */
  set paddingBefore(String value) {
    setProperty('padding-before', value, '');
  }

  /** Gets the value of "padding-bottom" */
  String get paddingBottom =>
    getPropertyValue('padding-bottom');

  /** Sets the value of "padding-bottom" */
  set paddingBottom(String value) {
    setProperty('padding-bottom', value, '');
  }

  /** Gets the value of "padding-end" */
  String get paddingEnd =>
    getPropertyValue('padding-end');

  /** Sets the value of "padding-end" */
  set paddingEnd(String value) {
    setProperty('padding-end', value, '');
  }

  /** Gets the value of "padding-left" */
  String get paddingLeft =>
    getPropertyValue('padding-left');

  /** Sets the value of "padding-left" */
  set paddingLeft(String value) {
    setProperty('padding-left', value, '');
  }

  /** Gets the value of "padding-right" */
  String get paddingRight =>
    getPropertyValue('padding-right');

  /** Sets the value of "padding-right" */
  set paddingRight(String value) {
    setProperty('padding-right', value, '');
  }

  /** Gets the value of "padding-start" */
  String get paddingStart =>
    getPropertyValue('padding-start');

  /** Sets the value of "padding-start" */
  set paddingStart(String value) {
    setProperty('padding-start', value, '');
  }

  /** Gets the value of "padding-top" */
  String get paddingTop =>
    getPropertyValue('padding-top');

  /** Sets the value of "padding-top" */
  set paddingTop(String value) {
    setProperty('padding-top', value, '');
  }

  /** Gets the value of "page" */
  String get page =>
    getPropertyValue('page');

  /** Sets the value of "page" */
  set page(String value) {
    setProperty('page', value, '');
  }

  /** Gets the value of "page-break-after" */
  String get pageBreakAfter =>
    getPropertyValue('page-break-after');

  /** Sets the value of "page-break-after" */
  set pageBreakAfter(String value) {
    setProperty('page-break-after', value, '');
  }

  /** Gets the value of "page-break-before" */
  String get pageBreakBefore =>
    getPropertyValue('page-break-before');

  /** Sets the value of "page-break-before" */
  set pageBreakBefore(String value) {
    setProperty('page-break-before', value, '');
  }

  /** Gets the value of "page-break-inside" */
  String get pageBreakInside =>
    getPropertyValue('page-break-inside');

  /** Sets the value of "page-break-inside" */
  set pageBreakInside(String value) {
    setProperty('page-break-inside', value, '');
  }

  /** Gets the value of "perspective" */
  String get perspective =>
    getPropertyValue('perspective');

  /** Sets the value of "perspective" */
  set perspective(String value) {
    setProperty('perspective', value, '');
  }

  /** Gets the value of "perspective-origin" */
  String get perspectiveOrigin =>
    getPropertyValue('perspective-origin');

  /** Sets the value of "perspective-origin" */
  set perspectiveOrigin(String value) {
    setProperty('perspective-origin', value, '');
  }

  /** Gets the value of "perspective-origin-x" */
  String get perspectiveOriginX =>
    getPropertyValue('perspective-origin-x');

  /** Sets the value of "perspective-origin-x" */
  set perspectiveOriginX(String value) {
    setProperty('perspective-origin-x', value, '');
  }

  /** Gets the value of "perspective-origin-y" */
  String get perspectiveOriginY =>
    getPropertyValue('perspective-origin-y');

  /** Sets the value of "perspective-origin-y" */
  set perspectiveOriginY(String value) {
    setProperty('perspective-origin-y', value, '');
  }

  /** Gets the value of "pointer-events" */
  String get pointerEvents =>
    getPropertyValue('pointer-events');

  /** Sets the value of "pointer-events" */
  set pointerEvents(String value) {
    setProperty('pointer-events', value, '');
  }

  /** Gets the value of "position" */
  String get position =>
    getPropertyValue('position');

  /** Sets the value of "position" */
  set position(String value) {
    setProperty('position', value, '');
  }

  /** Gets the value of "print-color-adjust" */
  String get printColorAdjust =>
    getPropertyValue('print-color-adjust');

  /** Sets the value of "print-color-adjust" */
  set printColorAdjust(String value) {
    setProperty('print-color-adjust', value, '');
  }

  /** Gets the value of "quotes" */
  String get quotes =>
    getPropertyValue('quotes');

  /** Sets the value of "quotes" */
  set quotes(String value) {
    setProperty('quotes', value, '');
  }

  /** Gets the value of "resize" */
  String get resize =>
    getPropertyValue('resize');

  /** Sets the value of "resize" */
  set resize(String value) {
    setProperty('resize', value, '');
  }

  /** Gets the value of "right" */
  String get right =>
    getPropertyValue('right');

  /** Sets the value of "right" */
  set right(String value) {
    setProperty('right', value, '');
  }

  /** Gets the value of "rtl-ordering" */
  String get rtlOrdering =>
    getPropertyValue('rtl-ordering');

  /** Sets the value of "rtl-ordering" */
  set rtlOrdering(String value) {
    setProperty('rtl-ordering', value, '');
  }

  /** Gets the value of "ruby-position" */
  String get rubyPosition =>
    getPropertyValue('ruby-position');

  /** Sets the value of "ruby-position" */
  set rubyPosition(String value) {
    setProperty('ruby-position', value, '');
  }

  /** Gets the value of "scroll-behavior" */
  String get scrollBehavior =>
    getPropertyValue('scroll-behavior');

  /** Sets the value of "scroll-behavior" */
  set scrollBehavior(String value) {
    setProperty('scroll-behavior', value, '');
  }

  /** Gets the value of "shape-image-threshold" */
  String get shapeImageThreshold =>
    getPropertyValue('shape-image-threshold');

  /** Sets the value of "shape-image-threshold" */
  set shapeImageThreshold(String value) {
    setProperty('shape-image-threshold', value, '');
  }

  /** Gets the value of "shape-margin" */
  String get shapeMargin =>
    getPropertyValue('shape-margin');

  /** Sets the value of "shape-margin" */
  set shapeMargin(String value) {
    setProperty('shape-margin', value, '');
  }

  /** Gets the value of "shape-outside" */
  String get shapeOutside =>
    getPropertyValue('shape-outside');

  /** Sets the value of "shape-outside" */
  set shapeOutside(String value) {
    setProperty('shape-outside', value, '');
  }

  /** Gets the value of "size" */
  String get size =>
    getPropertyValue('size');

  /** Sets the value of "size" */
  set size(String value) {
    setProperty('size', value, '');
  }

  /** Gets the value of "speak" */
  String get speak =>
    getPropertyValue('speak');

  /** Sets the value of "speak" */
  set speak(String value) {
    setProperty('speak', value, '');
  }

  /** Gets the value of "src" */
  String get src =>
    getPropertyValue('src');

  /** Sets the value of "src" */
  set src(String value) {
    setProperty('src', value, '');
  }

  /** Gets the value of "tab-size" */
  String get tabSize =>
    getPropertyValue('tab-size');

  /** Sets the value of "tab-size" */
  set tabSize(String value) {
    setProperty('tab-size', value, '');
  }

  /** Gets the value of "table-layout" */
  String get tableLayout =>
    getPropertyValue('table-layout');

  /** Sets the value of "table-layout" */
  set tableLayout(String value) {
    setProperty('table-layout', value, '');
  }

  /** Gets the value of "tap-highlight-color" */
  String get tapHighlightColor =>
    getPropertyValue('tap-highlight-color');

  /** Sets the value of "tap-highlight-color" */
  set tapHighlightColor(String value) {
    setProperty('tap-highlight-color', value, '');
  }

  /** Gets the value of "text-align" */
  String get textAlign =>
    getPropertyValue('text-align');

  /** Sets the value of "text-align" */
  set textAlign(String value) {
    setProperty('text-align', value, '');
  }

  /** Gets the value of "text-align-last" */
  String get textAlignLast =>
    getPropertyValue('text-align-last');

  /** Sets the value of "text-align-last" */
  set textAlignLast(String value) {
    setProperty('text-align-last', value, '');
  }

  /** Gets the value of "text-combine" */
  String get textCombine =>
    getPropertyValue('text-combine');

  /** Sets the value of "text-combine" */
  set textCombine(String value) {
    setProperty('text-combine', value, '');
  }

  /** Gets the value of "text-decoration" */
  String get textDecoration =>
    getPropertyValue('text-decoration');

  /** Sets the value of "text-decoration" */
  set textDecoration(String value) {
    setProperty('text-decoration', value, '');
  }

  /** Gets the value of "text-decoration-color" */
  String get textDecorationColor =>
    getPropertyValue('text-decoration-color');

  /** Sets the value of "text-decoration-color" */
  set textDecorationColor(String value) {
    setProperty('text-decoration-color', value, '');
  }

  /** Gets the value of "text-decoration-line" */
  String get textDecorationLine =>
    getPropertyValue('text-decoration-line');

  /** Sets the value of "text-decoration-line" */
  set textDecorationLine(String value) {
    setProperty('text-decoration-line', value, '');
  }

  /** Gets the value of "text-decoration-style" */
  String get textDecorationStyle =>
    getPropertyValue('text-decoration-style');

  /** Sets the value of "text-decoration-style" */
  set textDecorationStyle(String value) {
    setProperty('text-decoration-style', value, '');
  }

  /** Gets the value of "text-decorations-in-effect" */
  String get textDecorationsInEffect =>
    getPropertyValue('text-decorations-in-effect');

  /** Sets the value of "text-decorations-in-effect" */
  set textDecorationsInEffect(String value) {
    setProperty('text-decorations-in-effect', value, '');
  }

  /** Gets the value of "text-emphasis" */
  String get textEmphasis =>
    getPropertyValue('text-emphasis');

  /** Sets the value of "text-emphasis" */
  set textEmphasis(String value) {
    setProperty('text-emphasis', value, '');
  }

  /** Gets the value of "text-emphasis-color" */
  String get textEmphasisColor =>
    getPropertyValue('text-emphasis-color');

  /** Sets the value of "text-emphasis-color" */
  set textEmphasisColor(String value) {
    setProperty('text-emphasis-color', value, '');
  }

  /** Gets the value of "text-emphasis-position" */
  String get textEmphasisPosition =>
    getPropertyValue('text-emphasis-position');

  /** Sets the value of "text-emphasis-position" */
  set textEmphasisPosition(String value) {
    setProperty('text-emphasis-position', value, '');
  }

  /** Gets the value of "text-emphasis-style" */
  String get textEmphasisStyle =>
    getPropertyValue('text-emphasis-style');

  /** Sets the value of "text-emphasis-style" */
  set textEmphasisStyle(String value) {
    setProperty('text-emphasis-style', value, '');
  }

  /** Gets the value of "text-fill-color" */
  String get textFillColor =>
    getPropertyValue('text-fill-color');

  /** Sets the value of "text-fill-color" */
  set textFillColor(String value) {
    setProperty('text-fill-color', value, '');
  }

  /** Gets the value of "text-indent" */
  String get textIndent =>
    getPropertyValue('text-indent');

  /** Sets the value of "text-indent" */
  set textIndent(String value) {
    setProperty('text-indent', value, '');
  }

  /** Gets the value of "text-justify" */
  String get textJustify =>
    getPropertyValue('text-justify');

  /** Sets the value of "text-justify" */
  set textJustify(String value) {
    setProperty('text-justify', value, '');
  }

  /** Gets the value of "text-line-through-color" */
  String get textLineThroughColor =>
    getPropertyValue('text-line-through-color');

  /** Sets the value of "text-line-through-color" */
  set textLineThroughColor(String value) {
    setProperty('text-line-through-color', value, '');
  }

  /** Gets the value of "text-line-through-mode" */
  String get textLineThroughMode =>
    getPropertyValue('text-line-through-mode');

  /** Sets the value of "text-line-through-mode" */
  set textLineThroughMode(String value) {
    setProperty('text-line-through-mode', value, '');
  }

  /** Gets the value of "text-line-through-style" */
  String get textLineThroughStyle =>
    getPropertyValue('text-line-through-style');

  /** Sets the value of "text-line-through-style" */
  set textLineThroughStyle(String value) {
    setProperty('text-line-through-style', value, '');
  }

  /** Gets the value of "text-line-through-width" */
  String get textLineThroughWidth =>
    getPropertyValue('text-line-through-width');

  /** Sets the value of "text-line-through-width" */
  set textLineThroughWidth(String value) {
    setProperty('text-line-through-width', value, '');
  }

  /** Gets the value of "text-orientation" */
  String get textOrientation =>
    getPropertyValue('text-orientation');

  /** Sets the value of "text-orientation" */
  set textOrientation(String value) {
    setProperty('text-orientation', value, '');
  }

  /** Gets the value of "text-overflow" */
  String get textOverflow =>
    getPropertyValue('text-overflow');

  /** Sets the value of "text-overflow" */
  set textOverflow(String value) {
    setProperty('text-overflow', value, '');
  }

  /** Gets the value of "text-overline-color" */
  String get textOverlineColor =>
    getPropertyValue('text-overline-color');

  /** Sets the value of "text-overline-color" */
  set textOverlineColor(String value) {
    setProperty('text-overline-color', value, '');
  }

  /** Gets the value of "text-overline-mode" */
  String get textOverlineMode =>
    getPropertyValue('text-overline-mode');

  /** Sets the value of "text-overline-mode" */
  set textOverlineMode(String value) {
    setProperty('text-overline-mode', value, '');
  }

  /** Gets the value of "text-overline-style" */
  String get textOverlineStyle =>
    getPropertyValue('text-overline-style');

  /** Sets the value of "text-overline-style" */
  set textOverlineStyle(String value) {
    setProperty('text-overline-style', value, '');
  }

  /** Gets the value of "text-overline-width" */
  String get textOverlineWidth =>
    getPropertyValue('text-overline-width');

  /** Sets the value of "text-overline-width" */
  set textOverlineWidth(String value) {
    setProperty('text-overline-width', value, '');
  }

  /** Gets the value of "text-rendering" */
  String get textRendering =>
    getPropertyValue('text-rendering');

  /** Sets the value of "text-rendering" */
  set textRendering(String value) {
    setProperty('text-rendering', value, '');
  }

  /** Gets the value of "text-security" */
  String get textSecurity =>
    getPropertyValue('text-security');

  /** Sets the value of "text-security" */
  set textSecurity(String value) {
    setProperty('text-security', value, '');
  }

  /** Gets the value of "text-shadow" */
  String get textShadow =>
    getPropertyValue('text-shadow');

  /** Sets the value of "text-shadow" */
  set textShadow(String value) {
    setProperty('text-shadow', value, '');
  }

  /** Gets the value of "text-stroke" */
  String get textStroke =>
    getPropertyValue('text-stroke');

  /** Sets the value of "text-stroke" */
  set textStroke(String value) {
    setProperty('text-stroke', value, '');
  }

  /** Gets the value of "text-stroke-color" */
  String get textStrokeColor =>
    getPropertyValue('text-stroke-color');

  /** Sets the value of "text-stroke-color" */
  set textStrokeColor(String value) {
    setProperty('text-stroke-color', value, '');
  }

  /** Gets the value of "text-stroke-width" */
  String get textStrokeWidth =>
    getPropertyValue('text-stroke-width');

  /** Sets the value of "text-stroke-width" */
  set textStrokeWidth(String value) {
    setProperty('text-stroke-width', value, '');
  }

  /** Gets the value of "text-transform" */
  String get textTransform =>
    getPropertyValue('text-transform');

  /** Sets the value of "text-transform" */
  set textTransform(String value) {
    setProperty('text-transform', value, '');
  }

  /** Gets the value of "text-underline-color" */
  String get textUnderlineColor =>
    getPropertyValue('text-underline-color');

  /** Sets the value of "text-underline-color" */
  set textUnderlineColor(String value) {
    setProperty('text-underline-color', value, '');
  }

  /** Gets the value of "text-underline-mode" */
  String get textUnderlineMode =>
    getPropertyValue('text-underline-mode');

  /** Sets the value of "text-underline-mode" */
  set textUnderlineMode(String value) {
    setProperty('text-underline-mode', value, '');
  }

  /** Gets the value of "text-underline-position" */
  String get textUnderlinePosition =>
    getPropertyValue('text-underline-position');

  /** Sets the value of "text-underline-position" */
  set textUnderlinePosition(String value) {
    setProperty('text-underline-position', value, '');
  }

  /** Gets the value of "text-underline-style" */
  String get textUnderlineStyle =>
    getPropertyValue('text-underline-style');

  /** Sets the value of "text-underline-style" */
  set textUnderlineStyle(String value) {
    setProperty('text-underline-style', value, '');
  }

  /** Gets the value of "text-underline-width" */
  String get textUnderlineWidth =>
    getPropertyValue('text-underline-width');

  /** Sets the value of "text-underline-width" */
  set textUnderlineWidth(String value) {
    setProperty('text-underline-width', value, '');
  }

  /** Gets the value of "top" */
  String get top =>
    getPropertyValue('top');

  /** Sets the value of "top" */
  set top(String value) {
    setProperty('top', value, '');
  }

  /** Gets the value of "touch-action" */
  String get touchAction =>
    getPropertyValue('touch-action');

  /** Sets the value of "touch-action" */
  set touchAction(String value) {
    setProperty('touch-action', value, '');
  }

  /** Gets the value of "touch-action-delay" */
  String get touchActionDelay =>
    getPropertyValue('touch-action-delay');

  /** Sets the value of "touch-action-delay" */
  set touchActionDelay(String value) {
    setProperty('touch-action-delay', value, '');
  }

  /** Gets the value of "transform" */
  String get transform =>
    getPropertyValue('transform');

  /** Sets the value of "transform" */
  set transform(String value) {
    setProperty('transform', value, '');
  }

  /** Gets the value of "transform-origin" */
  String get transformOrigin =>
    getPropertyValue('transform-origin');

  /** Sets the value of "transform-origin" */
  set transformOrigin(String value) {
    setProperty('transform-origin', value, '');
  }

  /** Gets the value of "transform-origin-x" */
  String get transformOriginX =>
    getPropertyValue('transform-origin-x');

  /** Sets the value of "transform-origin-x" */
  set transformOriginX(String value) {
    setProperty('transform-origin-x', value, '');
  }

  /** Gets the value of "transform-origin-y" */
  String get transformOriginY =>
    getPropertyValue('transform-origin-y');

  /** Sets the value of "transform-origin-y" */
  set transformOriginY(String value) {
    setProperty('transform-origin-y', value, '');
  }

  /** Gets the value of "transform-origin-z" */
  String get transformOriginZ =>
    getPropertyValue('transform-origin-z');

  /** Sets the value of "transform-origin-z" */
  set transformOriginZ(String value) {
    setProperty('transform-origin-z', value, '');
  }

  /** Gets the value of "transform-style" */
  String get transformStyle =>
    getPropertyValue('transform-style');

  /** Sets the value of "transform-style" */
  set transformStyle(String value) {
    setProperty('transform-style', value, '');
  }

  /** Gets the value of "transition" */@SupportedBrowser(SupportedBrowser.CHROME)
  @SupportedBrowser(SupportedBrowser.FIREFOX)
  @SupportedBrowser(SupportedBrowser.IE, '10')
  @SupportedBrowser(SupportedBrowser.SAFARI)
  String get transition =>
    getPropertyValue('transition');

  /** Sets the value of "transition" */@SupportedBrowser(SupportedBrowser.CHROME)
  @SupportedBrowser(SupportedBrowser.FIREFOX)
  @SupportedBrowser(SupportedBrowser.IE, '10')
  @SupportedBrowser(SupportedBrowser.SAFARI)
  set transition(String value) {
    setProperty('transition', value, '');
  }

  /** Gets the value of "transition-delay" */
  String get transitionDelay =>
    getPropertyValue('transition-delay');

  /** Sets the value of "transition-delay" */
  set transitionDelay(String value) {
    setProperty('transition-delay', value, '');
  }

  /** Gets the value of "transition-duration" */
  String get transitionDuration =>
    getPropertyValue('transition-duration');

  /** Sets the value of "transition-duration" */
  set transitionDuration(String value) {
    setProperty('transition-duration', value, '');
  }

  /** Gets the value of "transition-property" */
  String get transitionProperty =>
    getPropertyValue('transition-property');

  /** Sets the value of "transition-property" */
  set transitionProperty(String value) {
    setProperty('transition-property', value, '');
  }

  /** Gets the value of "transition-timing-function" */
  String get transitionTimingFunction =>
    getPropertyValue('transition-timing-function');

  /** Sets the value of "transition-timing-function" */
  set transitionTimingFunction(String value) {
    setProperty('transition-timing-function', value, '');
  }

  /** Gets the value of "unicode-bidi" */
  String get unicodeBidi =>
    getPropertyValue('unicode-bidi');

  /** Sets the value of "unicode-bidi" */
  set unicodeBidi(String value) {
    setProperty('unicode-bidi', value, '');
  }

  /** Gets the value of "unicode-range" */
  String get unicodeRange =>
    getPropertyValue('unicode-range');

  /** Sets the value of "unicode-range" */
  set unicodeRange(String value) {
    setProperty('unicode-range', value, '');
  }

  /** Gets the value of "user-drag" */
  String get userDrag =>
    getPropertyValue('user-drag');

  /** Sets the value of "user-drag" */
  set userDrag(String value) {
    setProperty('user-drag', value, '');
  }

  /** Gets the value of "user-modify" */
  String get userModify =>
    getPropertyValue('user-modify');

  /** Sets the value of "user-modify" */
  set userModify(String value) {
    setProperty('user-modify', value, '');
  }

  /** Gets the value of "user-select" */
  String get userSelect =>
    getPropertyValue('user-select');

  /** Sets the value of "user-select" */
  set userSelect(String value) {
    setProperty('user-select', value, '');
  }

  /** Gets the value of "user-zoom" */
  String get userZoom =>
    getPropertyValue('user-zoom');

  /** Sets the value of "user-zoom" */
  set userZoom(String value) {
    setProperty('user-zoom', value, '');
  }

  /** Gets the value of "vertical-align" */
  String get verticalAlign =>
    getPropertyValue('vertical-align');

  /** Sets the value of "vertical-align" */
  set verticalAlign(String value) {
    setProperty('vertical-align', value, '');
  }

  /** Gets the value of "visibility" */
  String get visibility =>
    getPropertyValue('visibility');

  /** Sets the value of "visibility" */
  set visibility(String value) {
    setProperty('visibility', value, '');
  }

  /** Gets the value of "white-space" */
  String get whiteSpace =>
    getPropertyValue('white-space');

  /** Sets the value of "white-space" */
  set whiteSpace(String value) {
    setProperty('white-space', value, '');
  }

  /** Gets the value of "widows" */
  String get widows =>
    getPropertyValue('widows');

  /** Sets the value of "widows" */
  set widows(String value) {
    setProperty('widows', value, '');
  }

  /** Gets the value of "width" */
  String get width =>
    getPropertyValue('width');

  /** Sets the value of "width" */
  set width(String value) {
    setProperty('width', value, '');
  }

  /** Gets the value of "will-change" */
  String get willChange =>
    getPropertyValue('will-change');

  /** Sets the value of "will-change" */
  set willChange(String value) {
    setProperty('will-change', value, '');
  }

  /** Gets the value of "word-break" */
  String get wordBreak =>
    getPropertyValue('word-break');

  /** Sets the value of "word-break" */
  set wordBreak(String value) {
    setProperty('word-break', value, '');
  }

  /** Gets the value of "word-spacing" */
  String get wordSpacing =>
    getPropertyValue('word-spacing');

  /** Sets the value of "word-spacing" */
  set wordSpacing(String value) {
    setProperty('word-spacing', value, '');
  }

  /** Gets the value of "word-wrap" */
  String get wordWrap =>
    getPropertyValue('word-wrap');

  /** Sets the value of "word-wrap" */
  set wordWrap(String value) {
    setProperty('word-wrap', value, '');
  }

  /** Gets the value of "wrap-flow" */
  String get wrapFlow =>
    getPropertyValue('wrap-flow');

  /** Sets the value of "wrap-flow" */
  set wrapFlow(String value) {
    setProperty('wrap-flow', value, '');
  }

  /** Gets the value of "wrap-through" */
  String get wrapThrough =>
    getPropertyValue('wrap-through');

  /** Sets the value of "wrap-through" */
  set wrapThrough(String value) {
    setProperty('wrap-through', value, '');
  }

  /** Gets the value of "writing-mode" */
  String get writingMode =>
    getPropertyValue('writing-mode');

  /** Sets the value of "writing-mode" */
  set writingMode(String value) {
    setProperty('writing-mode', value, '');
  }

  /** Gets the value of "z-index" */
  String get zIndex =>
    getPropertyValue('z-index');

  /** Sets the value of "z-index" */
  set zIndex(String value) {
    setProperty('z-index', value, '');
  }

  /** Gets the value of "zoom" */
  String get zoom =>
    getPropertyValue('zoom');

  /** Sets the value of "zoom" */
  set zoom(String value) {
    setProperty('zoom', value, '');
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DomName('CustomEvent')
@Native("CustomEvent")
class CustomEvent extends Event {
  var _dartDetail;

  factory CustomEvent(String type,
      {bool canBubble: true, bool cancelable: true, Object detail}) {

    final CustomEvent e = document._createEvent('CustomEvent');

    e._dartDetail = detail;

    // Only try setting the detail if it's one of these types to avoid
    // first-chance exceptions. Can expand this list in the future as needed.
    if (detail is List || detail is Map || detail is String || detail is num) {
      try {
        e._initCustomEvent(type, canBubble, cancelable, detail);
      } catch(_) {
        e._initCustomEvent(type, canBubble, cancelable, null);
      }
    } else {
      e._initCustomEvent(type, canBubble, cancelable, null);
    }

    return e;
  }

  @DomName('CustomEvent.detail')
  get detail {
    if (_dartDetail != null) {
      return _dartDetail;
    }
    return _detail;
  }
  // To suppress missing implicit constructor warnings.
  factory CustomEvent._() { throw new UnsupportedError("Not supported"); }


  @Deprecated("Internal Use Only")
  static CustomEvent internalCreateCustomEvent() {
    return new CustomEvent.internal_();
  }

  @Deprecated("Internal Use Only")
  CustomEvent.internal_() : super.internal_();


  @DomName('CustomEvent._detail')
  @DocsEditable()
  @Experimental() // untriaged
  dynamic get _detail => convertNativeToDart_SerializedScriptValue(this._get__detail);
  @JSName('detail')
  @DomName('CustomEvent._detail')
  @DocsEditable()
  @Experimental() // untriaged
  @Creates('Null')
  dynamic get _get__detail => wrap_jso(JS("dynamic", "#.detail", this.raw));

  @DomName('CustomEvent.initCustomEvent')
  @DocsEditable()
  void _initCustomEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Object detailArg) {
    _initCustomEvent_1(typeArg, canBubbleArg, cancelableArg, detailArg);
    return;
  }
  @JSName('initCustomEvent')
  @DomName('CustomEvent.initCustomEvent')
  @DocsEditable()
  void _initCustomEvent_1(typeArg, canBubbleArg, cancelableArg, detailArg) => wrap_jso(JS("void ", "#.raw.initCustomEvent(#, #, #, #)", this, unwrap_jso(typeArg), unwrap_jso(canBubbleArg), unwrap_jso(cancelableArg), unwrap_jso(detailArg)));

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
/**
 * A generic container for content on an HTML page;
 * corresponds to the &lt;div&gt; tag.
 *
 * The [DivElement] is a generic container and does not have any semantic
 * significance. It is functionally similar to [SpanElement].
 *
 * The [DivElement] is a block-level element, as opposed to [SpanElement],
 * which is an inline-level element.
 *
 * Example usage:
 *
 *     DivElement div = new DivElement();
 *     div.text = 'Here's my new DivElem
 *     document.body.elements.add(elem);
 *
 * See also:
 *
 * * [HTML <div> element](http://www.w3.org/TR/html-markup/div.html) from W3C.
 * * [Block-level element](http://www.w3.org/TR/CSS2/visuren.html#block-boxes) from W3C.
 * * [Inline-level element](http://www.w3.org/TR/CSS2/visuren.html#inline-boxes) from W3C.
 */
@DomName('HTMLDivElement')
@Native("HTMLDivElement")
class DivElement extends HtmlElement {
  // To suppress missing implicit constructor warnings.
  factory DivElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('HTMLDivElement.HTMLDivElement')
  @DocsEditable()
  factory DivElement() => document.createElement("div");


  @Deprecated("Internal Use Only")
  static DivElement internalCreateDivElement() {
    return new DivElement.internal_();
  }

  @Deprecated("Internal Use Only")
  DivElement.internal_() : super.internal_();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
/**
 * The base class for all documents.
 *
 * Each web page loaded in the browser has its own [Document] object, which is
 * typically an [HtmlDocument].
 *
 * If you aren't comfortable with DOM concepts, see the Dart tutorial
 * [Target 2: Connect Dart & HTML](http://www.dartlang.org/docs/tutorials/connect-dart-html/).
 */
@DomName('Document')
@Native("Document")
class Document extends Node
{

  // To suppress missing implicit constructor warnings.
  factory Document._() { throw new UnsupportedError("Not supported"); }

  @DomName('Document.pointerlockchangeEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> pointerLockChangeEvent = const EventStreamProvider<Event>('pointerlockchange');

  @DomName('Document.pointerlockerrorEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> pointerLockErrorEvent = const EventStreamProvider<Event>('pointerlockerror');

  /**
   * Static factory designed to expose `readystatechange` events to event
   * handlers that are not necessarily instances of [Document].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('Document.readystatechangeEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> readyStateChangeEvent = const EventStreamProvider<Event>('readystatechange');

  /**
   * Static factory designed to expose `selectionchange` events to event
   * handlers that are not necessarily instances of [Document].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('Document.selectionchangeEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> selectionChangeEvent = const EventStreamProvider<Event>('selectionchange');


  @Deprecated("Internal Use Only")
  static Document internalCreateDocument() {
    return new Document.internal_();
  }

  @Deprecated("Internal Use Only")
  Document.internal_() : super.internal_();


  @DomName('Document.activeElement')
  @DocsEditable()
  @Experimental() // untriaged
  Element get activeElement => wrap_jso(JS("Element", "#.activeElement", this.raw));

  @JSName('body')
  @DomName('Document.body')
  @DocsEditable()
  HtmlElement get _body => wrap_jso(JS("HtmlElement", "#.body", this.raw));
  @JSName('body')
  @DomName('Document.body')
  @DocsEditable()
  void set _body(HtmlElement val) => JS("void", "#.body = #", this.raw, unwrap_jso(val));

  @DomName('Document.contentType')
  @DocsEditable()
  @Experimental() // untriaged
  String get contentType => wrap_jso(JS("String", "#.contentType", this.raw));

  @DomName('Document.cookie')
  @DocsEditable()
  String get cookie => wrap_jso(JS("String", "#.cookie", this.raw));
  @DomName('Document.cookie')
  @DocsEditable()
  void set cookie(String val) => JS("void", "#.cookie = #", this.raw, unwrap_jso(val));

  @DomName('Document.currentScript')
  @DocsEditable()
  @Experimental() // untriaged
  HtmlElement get currentScript => wrap_jso(JS("HtmlElement", "#.currentScript", this.raw));

  @DomName('Document.window')
  @DocsEditable()
  @Experimental() // untriaged
  WindowBase get window => _convertNativeToDart_Window(this._get_window);
  @JSName('defaultView')
  @DomName('Document.window')
  @DocsEditable()
  @Experimental() // untriaged
  @Creates('Window|=Object')
  @Returns('Window|=Object')
  @Creates('Window|=Object|Null')
  @Returns('Window|=Object|Null')
  dynamic get _get_window => wrap_jso(JS("dynamic", "#.defaultView", this.raw));

  @DomName('Document.documentElement')
  @DocsEditable()
  Element get documentElement => wrap_jso(JS("Element", "#.documentElement", this.raw));

  @DomName('Document.domain')
  @DocsEditable()
  String get domain => wrap_jso(JS("String", "#.domain", this.raw));

  @DomName('Document.fullscreenElement')
  @DocsEditable()
  @Experimental() // untriaged
  Element get fullscreenElement => wrap_jso(JS("Element", "#.fullscreenElement", this.raw));

  @DomName('Document.fullscreenEnabled')
  @DocsEditable()
  @Experimental() // untriaged
  bool get fullscreenEnabled => wrap_jso(JS("bool", "#.fullscreenEnabled", this.raw));

  @JSName('head')
  @DomName('Document.head')
  @DocsEditable()
  HeadElement get _head => wrap_jso(JS("HeadElement", "#.head", this.raw));

  @DomName('Document.hidden')
  @DocsEditable()
  @Experimental() // untriaged
  bool get hidden => wrap_jso(JS("bool", "#.hidden", this.raw));

  @DomName('Document.implementation')
  @DocsEditable()
  DomImplementation get implementation => wrap_jso(JS("DomImplementation", "#.implementation", this.raw));

  @JSName('lastModified')
  @DomName('Document.lastModified')
  @DocsEditable()
  String get _lastModified => wrap_jso(JS("String", "#.lastModified", this.raw));

  @DomName('Document.pointerLockElement')
  @DocsEditable()
  @Experimental() // untriaged
  Element get pointerLockElement => wrap_jso(JS("Element", "#.pointerLockElement", this.raw));

  @JSName('preferredStylesheetSet')
  @DomName('Document.preferredStylesheetSet')
  @DocsEditable()
  String get _preferredStylesheetSet => wrap_jso(JS("String", "#.preferredStylesheetSet", this.raw));

  @DomName('Document.readyState')
  @DocsEditable()
  String get readyState => wrap_jso(JS("String", "#.readyState", this.raw));

  @JSName('referrer')
  @DomName('Document.referrer')
  @DocsEditable()
  String get _referrer => wrap_jso(JS("String", "#.referrer", this.raw));

  @DomName('Document.rootElement')
  @DocsEditable()
  @Experimental() // untriaged
  Element get rootElement => wrap_jso(JS("Element", "#.rootElement", this.raw));

  @JSName('selectedStylesheetSet')
  @DomName('Document.selectedStylesheetSet')
  @DocsEditable()
  String get _selectedStylesheetSet => wrap_jso(JS("String", "#.selectedStylesheetSet", this.raw));
  @JSName('selectedStylesheetSet')
  @DomName('Document.selectedStylesheetSet')
  @DocsEditable()
  void set _selectedStylesheetSet(String val) => JS("void", "#.selectedStylesheetSet = #", this.raw, unwrap_jso(val));

  @JSName('title')
  @DomName('Document.title')
  @DocsEditable()
  String get _title => wrap_jso(JS("String", "#.title", this.raw));
  @JSName('title')
  @DomName('Document.title')
  @DocsEditable()
  void set _title(String val) => JS("void", "#.title = #", this.raw, unwrap_jso(val));

  @DomName('Document.visibilityState')
  @DocsEditable()
  @Experimental() // untriaged
  String get visibilityState => wrap_jso(JS("String", "#.visibilityState", this.raw));

  @JSName('webkitFullscreenElement')
  @DomName('Document.webkitFullscreenElement')
  @DocsEditable()
  @SupportedBrowser(SupportedBrowser.CHROME)
  @SupportedBrowser(SupportedBrowser.SAFARI)
  @Experimental()
  // https://dvcs.w3.org/hg/fullscreen/raw-file/tip/Overview.html#dom-document-fullscreenelement
  Element get _webkitFullscreenElement => wrap_jso(JS("Element", "#.webkitFullscreenElement", this.raw));

  @JSName('webkitFullscreenEnabled')
  @DomName('Document.webkitFullscreenEnabled')
  @DocsEditable()
  @SupportedBrowser(SupportedBrowser.CHROME)
  @SupportedBrowser(SupportedBrowser.SAFARI)
  @Experimental()
  // https://dvcs.w3.org/hg/fullscreen/raw-file/tip/Overview.html#dom-document-fullscreenenabled
  bool get _webkitFullscreenEnabled => wrap_jso(JS("bool", "#.webkitFullscreenEnabled", this.raw));

  @JSName('webkitHidden')
  @DomName('Document.webkitHidden')
  @DocsEditable()
  @SupportedBrowser(SupportedBrowser.CHROME)
  @SupportedBrowser(SupportedBrowser.SAFARI)
  @Experimental()
  // https://dvcs.w3.org/hg/webperf/raw-file/tip/specs/PageVisibility/Overview.html#document
  bool get _webkitHidden => wrap_jso(JS("bool", "#.webkitHidden", this.raw));

  @JSName('webkitVisibilityState')
  @DomName('Document.webkitVisibilityState')
  @DocsEditable()
  @SupportedBrowser(SupportedBrowser.CHROME)
  @SupportedBrowser(SupportedBrowser.SAFARI)
  @Experimental()
  // https://dvcs.w3.org/hg/webperf/raw-file/tip/specs/PageVisibility/Overview.html#dom-document-visibilitystate
  String get _webkitVisibilityState => wrap_jso(JS("String", "#.webkitVisibilityState", this.raw));

  @DomName('Document.adoptNode')
  @DocsEditable()
  Node adoptNode(Node node) {
    return _adoptNode_1(node);
  }
  @JSName('adoptNode')
  @DomName('Document.adoptNode')
  @DocsEditable()
  Node _adoptNode_1(Node node) => wrap_jso(JS("Node ", "#.raw.adoptNode(#)", this, unwrap_jso(node)));

  @DomName('Document.caretRangeFromPoint')
  @DocsEditable()
  // http://www.w3.org/TR/2009/WD-cssom-view-20090804/#dom-documentview-caretrangefrompoint
  @Experimental()
  Range _caretRangeFromPoint(int x, int y) {
    return _caretRangeFromPoint_1(x, y);
  }
  @JSName('caretRangeFromPoint')
  @DomName('Document.caretRangeFromPoint')
  @DocsEditable()
  // http://www.w3.org/TR/2009/WD-cssom-view-20090804/#dom-documentview-caretrangefrompoint
  @Experimental()
  Range _caretRangeFromPoint_1(x, y) => wrap_jso(JS("Range ", "#.raw.caretRangeFromPoint(#, #)", this, unwrap_jso(x), unwrap_jso(y)));

  @DomName('Document.createDocumentFragment')
  @DocsEditable()
  DocumentFragment createDocumentFragment() {
    return _createDocumentFragment_1();
  }
  @JSName('createDocumentFragment')
  @DomName('Document.createDocumentFragment')
  @DocsEditable()
  DocumentFragment _createDocumentFragment_1() => wrap_jso(JS("DocumentFragment ", "#.raw.createDocumentFragment()", this));

  @DomName('Document.createElement')
  @DocsEditable()
  Element _createElement(String localName_OR_tagName, [String typeExtension]) {
    if (typeExtension == null) {
      return _createElement_1(localName_OR_tagName);
    }
    if (typeExtension != null) {
      return _createElement_2(localName_OR_tagName, typeExtension);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }
  @JSName('createElement')
  @DomName('Document.createElement')
  @DocsEditable()
  Element _createElement_1(tagName) => wrap_jso(JS("Element ", "#.raw.createElement(#)", this, unwrap_jso(tagName)));
  @JSName('createElement')
  @DomName('Document.createElement')
  @DocsEditable()
  Element _createElement_2(localName, typeExtension) => wrap_jso(JS("Element ", "#.raw.createElement(#, #)", this, unwrap_jso(localName), unwrap_jso(typeExtension)));

  @DomName('Document.createElementNS')
  @DocsEditable()
  Element _createElementNS(String namespaceURI, String qualifiedName, [String typeExtension]) {
    if (typeExtension == null) {
      return _createElementNS_1(namespaceURI, qualifiedName);
    }
    if (typeExtension != null) {
      return _createElementNS_2(namespaceURI, qualifiedName, typeExtension);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }
  @JSName('createElementNS')
  @DomName('Document.createElementNS')
  @DocsEditable()
  Element _createElementNS_1(namespaceURI, qualifiedName) => wrap_jso(JS("Element ", "#.raw.createElementNS(#, #)", this, unwrap_jso(namespaceURI), unwrap_jso(qualifiedName)));
  @JSName('createElementNS')
  @DomName('Document.createElementNS')
  @DocsEditable()
  Element _createElementNS_2(namespaceURI, qualifiedName, typeExtension) => wrap_jso(JS("Element ", "#.raw.createElementNS(#, #, #)", this, unwrap_jso(namespaceURI), unwrap_jso(qualifiedName), unwrap_jso(typeExtension)));

  @DomName('Document.createEvent')
  @DocsEditable()
  Event _createEvent(String eventType) {
    return _createEvent_1(eventType);
  }
  @JSName('createEvent')
  @DomName('Document.createEvent')
  @DocsEditable()
  Event _createEvent_1(eventType) => wrap_jso(JS("Event ", "#.raw.createEvent(#)", this, unwrap_jso(eventType)));

  @DomName('Document.createRange')
  @DocsEditable()
  Range createRange() {
    return _createRange_1();
  }
  @JSName('createRange')
  @DomName('Document.createRange')
  @DocsEditable()
  Range _createRange_1() => wrap_jso(JS("Range ", "#.raw.createRange()", this));

  @DomName('Document.createTextNode')
  @DocsEditable()
  Text _createTextNode(String data) {
    return _createTextNode_1(data);
  }
  @JSName('createTextNode')
  @DomName('Document.createTextNode')
  @DocsEditable()
  Text _createTextNode_1(data) => wrap_jso(JS("Text ", "#.raw.createTextNode(#)", this, unwrap_jso(data)));

  @DomName('Document.elementFromPoint')
  @DocsEditable()
  Element _elementFromPoint(int x, int y) {
    return _elementFromPoint_1(x, y);
  }
  @JSName('elementFromPoint')
  @DomName('Document.elementFromPoint')
  @DocsEditable()
  Element _elementFromPoint_1(x, y) => wrap_jso(JS("Element ", "#.raw.elementFromPoint(#, #)", this, unwrap_jso(x), unwrap_jso(y)));

  @DomName('Document.execCommand')
  @DocsEditable()
  bool execCommand(String command, bool userInterface, String value) {
    return _execCommand_1(command, userInterface, value);
  }
  @JSName('execCommand')
  @DomName('Document.execCommand')
  @DocsEditable()
  bool _execCommand_1(command, userInterface, value) => wrap_jso(JS("bool ", "#.raw.execCommand(#, #, #)", this, unwrap_jso(command), unwrap_jso(userInterface), unwrap_jso(value)));

  @DomName('Document.exitFullscreen')
  @DocsEditable()
  @Experimental() // untriaged
  void exitFullscreen() {
    _exitFullscreen_1();
    return;
  }
  @JSName('exitFullscreen')
  @DomName('Document.exitFullscreen')
  @DocsEditable()
  @Experimental() // untriaged
  void _exitFullscreen_1() => wrap_jso(JS("void ", "#.raw.exitFullscreen()", this));

  @DomName('Document.exitPointerLock')
  @DocsEditable()
  @Experimental() // untriaged
  void exitPointerLock() {
    _exitPointerLock_1();
    return;
  }
  @JSName('exitPointerLock')
  @DomName('Document.exitPointerLock')
  @DocsEditable()
  @Experimental() // untriaged
  void _exitPointerLock_1() => wrap_jso(JS("void ", "#.raw.exitPointerLock()", this));

  @DomName('Document.getCSSCanvasContext')
  @DocsEditable()
  // https://developer.apple.com/library/safari/#documentation/AppleApplications/Reference/SafariCSSRef/Articles/Functions.html
  @Experimental() // non-standard
  Object _getCssCanvasContext(String contextId, String name, int width, int height) {
    return _getCssCanvasContext_1(contextId, name, width, height);
  }
  @JSName('getCSSCanvasContext')
  @DomName('Document.getCSSCanvasContext')
  @DocsEditable()
  // https://developer.apple.com/library/safari/#documentation/AppleApplications/Reference/SafariCSSRef/Articles/Functions.html
  @Experimental() // non-standard
  Object _getCssCanvasContext_1(contextId, name, width, height) => wrap_jso(JS("Object ", "#.raw.getCSSCanvasContext(#, #, #, #)", this, unwrap_jso(contextId), unwrap_jso(name), unwrap_jso(width), unwrap_jso(height)));

  @DomName('Document.getElementById')
  @DocsEditable()
  Element getElementById(String elementId) {
    return _getElementById_1(elementId);
  }
  @JSName('getElementById')
  @DomName('Document.getElementById')
  @DocsEditable()
  Element _getElementById_1(elementId) => wrap_jso(JS("Element ", "#.raw.getElementById(#)", this, unwrap_jso(elementId)));

  @DomName('Document.getElementsByClassName')
  @DocsEditable()
  @Creates('NodeList|HtmlCollection')
  @Returns('NodeList|HtmlCollection')
  HtmlCollection getElementsByClassName(String classNames) {
    return _getElementsByClassName_1(classNames);
  }
  @JSName('getElementsByClassName')
  @DomName('Document.getElementsByClassName')
  @DocsEditable()
  @Creates('NodeList|HtmlCollection')
  @Returns('NodeList|HtmlCollection')
  HtmlCollection _getElementsByClassName_1(classNames) => wrap_jso(JS("HtmlCollection ", "#.raw.getElementsByClassName(#)", this, unwrap_jso(classNames)));

  @DomName('Document.getElementsByName')
  @DocsEditable()
  @Creates('NodeList|HtmlCollection')
  @Returns('NodeList|HtmlCollection')
  NodeList getElementsByName(String elementName) {
    return _getElementsByName_1(elementName);
  }
  @JSName('getElementsByName')
  @DomName('Document.getElementsByName')
  @DocsEditable()
  @Creates('NodeList|HtmlCollection')
  @Returns('NodeList|HtmlCollection')
  NodeList _getElementsByName_1(elementName) => wrap_jso(JS("NodeList ", "#.raw.getElementsByName(#)", this, unwrap_jso(elementName)));

  @DomName('Document.getElementsByTagName')
  @DocsEditable()
  @Creates('NodeList|HtmlCollection')
  @Returns('NodeList|HtmlCollection')
  HtmlCollection getElementsByTagName(String localName) {
    return _getElementsByTagName_1(localName);
  }
  @JSName('getElementsByTagName')
  @DomName('Document.getElementsByTagName')
  @DocsEditable()
  @Creates('NodeList|HtmlCollection')
  @Returns('NodeList|HtmlCollection')
  HtmlCollection _getElementsByTagName_1(localName) => wrap_jso(JS("HtmlCollection ", "#.raw.getElementsByTagName(#)", this, unwrap_jso(localName)));

  @DomName('Document.importNode')
  @DocsEditable()
  Node importNode(Node node, [bool deep]) {
    if (deep != null) {
      return _importNode_1(node, deep);
    }
    return _importNode_2(node);
  }
  @JSName('importNode')
  @DomName('Document.importNode')
  @DocsEditable()
  Node _importNode_1(Node node, deep) => wrap_jso(JS("Node ", "#.raw.importNode(#, #)", this, unwrap_jso(node), unwrap_jso(deep)));
  @JSName('importNode')
  @DomName('Document.importNode')
  @DocsEditable()
  Node _importNode_2(Node node) => wrap_jso(JS("Node ", "#.raw.importNode(#)", this, unwrap_jso(node)));

  @DomName('Document.queryCommandEnabled')
  @DocsEditable()
  bool queryCommandEnabled(String command) {
    return _queryCommandEnabled_1(command);
  }
  @JSName('queryCommandEnabled')
  @DomName('Document.queryCommandEnabled')
  @DocsEditable()
  bool _queryCommandEnabled_1(command) => wrap_jso(JS("bool ", "#.raw.queryCommandEnabled(#)", this, unwrap_jso(command)));

  @DomName('Document.queryCommandIndeterm')
  @DocsEditable()
  bool queryCommandIndeterm(String command) {
    return _queryCommandIndeterm_1(command);
  }
  @JSName('queryCommandIndeterm')
  @DomName('Document.queryCommandIndeterm')
  @DocsEditable()
  bool _queryCommandIndeterm_1(command) => wrap_jso(JS("bool ", "#.raw.queryCommandIndeterm(#)", this, unwrap_jso(command)));

  @DomName('Document.queryCommandState')
  @DocsEditable()
  bool queryCommandState(String command) {
    return _queryCommandState_1(command);
  }
  @JSName('queryCommandState')
  @DomName('Document.queryCommandState')
  @DocsEditable()
  bool _queryCommandState_1(command) => wrap_jso(JS("bool ", "#.raw.queryCommandState(#)", this, unwrap_jso(command)));

  @DomName('Document.queryCommandSupported')
  @DocsEditable()
  bool queryCommandSupported(String command) {
    return _queryCommandSupported_1(command);
  }
  @JSName('queryCommandSupported')
  @DomName('Document.queryCommandSupported')
  @DocsEditable()
  bool _queryCommandSupported_1(command) => wrap_jso(JS("bool ", "#.raw.queryCommandSupported(#)", this, unwrap_jso(command)));

  @DomName('Document.queryCommandValue')
  @DocsEditable()
  String queryCommandValue(String command) {
    return _queryCommandValue_1(command);
  }
  @JSName('queryCommandValue')
  @DomName('Document.queryCommandValue')
  @DocsEditable()
  String _queryCommandValue_1(command) => wrap_jso(JS("String ", "#.raw.queryCommandValue(#)", this, unwrap_jso(command)));

  @DomName('Document.transformDocumentToTreeView')
  @DocsEditable()
  @Experimental() // untriaged
  void transformDocumentToTreeView(String noStyleMessage) {
    _transformDocumentToTreeView_1(noStyleMessage);
    return;
  }
  @JSName('transformDocumentToTreeView')
  @DomName('Document.transformDocumentToTreeView')
  @DocsEditable()
  @Experimental() // untriaged
  void _transformDocumentToTreeView_1(noStyleMessage) => wrap_jso(JS("void ", "#.raw.transformDocumentToTreeView(#)", this, unwrap_jso(noStyleMessage)));

  @DomName('Document.webkitExitFullscreen')
  @DocsEditable()
  @SupportedBrowser(SupportedBrowser.CHROME)
  @SupportedBrowser(SupportedBrowser.SAFARI)
  @Experimental()
  // https://dvcs.w3.org/hg/fullscreen/raw-file/tip/Overview.html#dom-document-exitfullscreen
  void _webkitExitFullscreen() {
    _webkitExitFullscreen_1();
    return;
  }
  @JSName('webkitExitFullscreen')
  @DomName('Document.webkitExitFullscreen')
  @DocsEditable()
  @SupportedBrowser(SupportedBrowser.CHROME)
  @SupportedBrowser(SupportedBrowser.SAFARI)
  @Experimental()
  // https://dvcs.w3.org/hg/fullscreen/raw-file/tip/Overview.html#dom-document-exitfullscreen
  void _webkitExitFullscreen_1() => wrap_jso(JS("void ", "#.raw.webkitExitFullscreen()", this));

  // From ParentNode

  @JSName('childElementCount')
  @DomName('Document.childElementCount')
  @DocsEditable()
  int get _childElementCount => wrap_jso(JS("int", "#.childElementCount", this.raw));

  @JSName('children')
  @DomName('Document.children')
  @DocsEditable()
  @Returns('HtmlCollection')
  @Creates('HtmlCollection')
  List<Node> get _children => wrap_jso(JS("List<Node>", "#.children", this.raw));

  @JSName('firstElementChild')
  @DomName('Document.firstElementChild')
  @DocsEditable()
  Element get _firstElementChild => wrap_jso(JS("Element", "#.firstElementChild", this.raw));

  @JSName('lastElementChild')
  @DomName('Document.lastElementChild')
  @DocsEditable()
  Element get _lastElementChild => wrap_jso(JS("Element", "#.lastElementChild", this.raw));

  /**
   * Finds the first descendant element of this document that matches the
   * specified group of selectors.
   *
   * Unless your webpage contains multiple documents, the top-level
   * [querySelector]
   * method behaves the same as this method, so you should use it instead to
   * save typing a few characters.
   *
   * [selectors] should be a string using CSS selector syntax.
   *
   *     var element1 = document.querySelector('.className');
   *     var element2 = document.querySelector('#id');
   *
   * For details about CSS selector syntax, see the
   * [CSS selector specification](http://www.w3.org/TR/css3-selectors/).
   */
  @DomName('Document.querySelector')
  @DocsEditable()
  Element querySelector(String selectors) {
    return _querySelector_1(selectors);
  }
  @JSName('querySelector')
  /**
   * Finds the first descendant element of this document that matches the
   * specified group of selectors.
   *
   * Unless your webpage contains multiple documents, the top-level
   * [querySelector]
   * method behaves the same as this method, so you should use it instead to
   * save typing a few characters.
   *
   * [selectors] should be a string using CSS selector syntax.
   *
   *     var element1 = document.querySelector('.className');
   *     var element2 = document.querySelector('#id');
   *
   * For details about CSS selector syntax, see the
   * [CSS selector specification](http://www.w3.org/TR/css3-selectors/).
   */
  @DomName('Document.querySelector')
  @DocsEditable()
  Element _querySelector_1(selectors) => wrap_jso(JS("Element ", "#.raw.querySelector(#)", this, unwrap_jso(selectors)));

  @DomName('Document.querySelectorAll')
  @DocsEditable()
  @Returns('NodeList')
  @Creates('NodeList')
  NodeList _querySelectorAll(String selectors) {
    return _querySelectorAll_1(selectors);
  }
  @JSName('querySelectorAll')
  @DomName('Document.querySelectorAll')
  @DocsEditable()
  @Returns('NodeList')
  @Creates('NodeList')
  NodeList _querySelectorAll_1(selectors) => wrap_jso(JS("NodeList ", "#.raw.querySelectorAll(#)", this, unwrap_jso(selectors)));

  /// Stream of `beforecopy` events handled by this [Document].
  @DomName('Document.onbeforecopy')
  @DocsEditable()
  Stream<Event> get onBeforeCopy => Element.beforeCopyEvent.forTarget(this);

  /// Stream of `beforecut` events handled by this [Document].
  @DomName('Document.onbeforecut')
  @DocsEditable()
  Stream<Event> get onBeforeCut => Element.beforeCutEvent.forTarget(this);

  /// Stream of `beforepaste` events handled by this [Document].
  @DomName('Document.onbeforepaste')
  @DocsEditable()
  Stream<Event> get onBeforePaste => Element.beforePasteEvent.forTarget(this);

  /// Stream of `copy` events handled by this [Document].
  @DomName('Document.oncopy')
  @DocsEditable()
  Stream<Event> get onCopy => Element.copyEvent.forTarget(this);

  /// Stream of `cut` events handled by this [Document].
  @DomName('Document.oncut')
  @DocsEditable()
  Stream<Event> get onCut => Element.cutEvent.forTarget(this);

  /// Stream of `paste` events handled by this [Document].
  @DomName('Document.onpaste')
  @DocsEditable()
  Stream<Event> get onPaste => Element.pasteEvent.forTarget(this);

  @DomName('Document.onpointerlockchange')
  @DocsEditable()
  @Experimental() // untriaged
  Stream<Event> get onPointerLockChange => pointerLockChangeEvent.forTarget(this);

  @DomName('Document.onpointerlockerror')
  @DocsEditable()
  @Experimental() // untriaged
  Stream<Event> get onPointerLockError => pointerLockErrorEvent.forTarget(this);

  /// Stream of `readystatechange` events handled by this [Document].
  @DomName('Document.onreadystatechange')
  @DocsEditable()
  Stream<Event> get onReadyStateChange => readyStateChangeEvent.forTarget(this);

  /// Stream of `search` events handled by this [Document].
  @DomName('Document.onsearch')
  @DocsEditable()
  // http://www.w3.org/TR/html-markup/input.search.html
  @Experimental()
  Stream<Event> get onSearch => Element.searchEvent.forTarget(this);

  /// Stream of `selectionchange` events handled by this [Document].
  @DomName('Document.onselectionchange')
  @DocsEditable()
  Stream<Event> get onSelectionChange => selectionChangeEvent.forTarget(this);

  /// Stream of `selectstart` events handled by this [Document].
  @DomName('Document.onselectstart')
  @DocsEditable()
  Stream<Event> get onSelectStart => Element.selectStartEvent.forTarget(this);

  /// Stream of `fullscreenchange` events handled by this [Document].
  @DomName('Document.onwebkitfullscreenchange')
  @DocsEditable()
  // https://dvcs.w3.org/hg/fullscreen/raw-file/tip/Overview.html
  @Experimental()
  Stream<Event> get onFullscreenChange => Element.fullscreenChangeEvent.forTarget(this);

  /// Stream of `fullscreenerror` events handled by this [Document].
  @DomName('Document.onwebkitfullscreenerror')
  @DocsEditable()
  // https://dvcs.w3.org/hg/fullscreen/raw-file/tip/Overview.html
  @Experimental()
  Stream<Event> get onFullscreenError => Element.fullscreenErrorEvent.forTarget(this);

  /**
   * Finds all descendant elements of this document that match the specified
   * group of selectors.
   *
   * Unless your webpage contains multiple documents, the top-level
   * [querySelectorAll]
   * method behaves the same as this method, so you should use it instead to
   * save typing a few characters.
   *
   * [selectors] should be a string using CSS selector syntax.
   *
   *     var items = document.querySelectorAll('.itemClassName');
   *
   * For details about CSS selector syntax, see the
   * [CSS selector specification](http://www.w3.org/TR/css3-selectors/).
   */
  ElementList<Element> querySelectorAll(String selectors) {
    return new _FrozenElementList._wrap(_querySelectorAll(selectors));
  }

  /**
   * Alias for [querySelector]. Note this function is deprecated because its
   * semantics will be changing in the future.
   */
  @deprecated
  @Experimental()
  @DomName('Document.querySelector')
  Element query(String relativeSelectors) => querySelector(relativeSelectors);

  /**
   * Alias for [querySelectorAll]. Note this function is deprecated because its
   * semantics will be changing in the future.
   */
  @deprecated
  @Experimental()
  @DomName('Document.querySelectorAll')
  ElementList<Element> queryAll(String relativeSelectors) =>
      querySelectorAll(relativeSelectors);

  /// Checks if [registerElement] is supported on the current platform.
  bool get supportsRegisterElement {
    return true;
  }

  /// *Deprecated*: use [supportsRegisterElement] instead.
  @deprecated
  bool get supportsRegister => supportsRegisterElement;

  @DomName('Document.createElement')
  Element createElement(String tagName, [String typeExtension]) {
    return _createElement(tagName, typeExtension);
  }

  @DomName('Document.createElementNS')
  @DocsEditable()
  Element createElementNS(String namespaceURI, String qualifiedName, [String typeExtension]) {
    return _createElementNS(namespaceURI, qualifiedName, typeExtension);
  }

}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('DocumentFragment')
@Native("DocumentFragment")
class DocumentFragment extends Node implements ParentNode {
  factory DocumentFragment() => document.createDocumentFragment();

  factory DocumentFragment.html(String html,
      {NodeValidator validator, NodeTreeSanitizer treeSanitizer}) {

    return document.body.createFragment(html,
      validator: validator, treeSanitizer: treeSanitizer);
  }

  factory DocumentFragment.svg(String svgContent,
      {NodeValidator validator, NodeTreeSanitizer treeSanitizer}) {
    throw 'SVG not supported in DDC';
  }

  HtmlCollection get _children => throw new UnimplementedError(
      'Use _docChildren instead');

  List<Element> _docChildren;

  List<Element> get children {
    if (_docChildren == null) {
      _docChildren = new FilteredElementList(this);
    }
    return _docChildren;
  }

  set children(List<Element> value) {
    // Copy list first since we don't want liveness during iteration.
    List copy = new List.from(value);
    var children = this.children;
    children.clear();
    children.addAll(copy);
  }

  /**
   * Finds all descendant elements of this document fragment that match the
   * specified group of selectors.
   *
   * [selectors] should be a string using CSS selector syntax.
   *
   *     var items = document.querySelectorAll('.itemClassName');
   *
   * For details about CSS selector syntax, see the
   * [CSS selector specification](http://www.w3.org/TR/css3-selectors/).
   */
  ElementList<Element> querySelectorAll(String selectors) =>
    new _FrozenElementList._wrap(_querySelectorAll(selectors));

  String get innerHtml {
    final e = new Element.tag("div");
    e.append(this.clone(true));
    return e.innerHtml;
  }

  set innerHtml(String value) {
    this.setInnerHtml(value);
  }

  void setInnerHtml(String html,
    {NodeValidator validator, NodeTreeSanitizer treeSanitizer}) {

    this.nodes.clear();
    append(document.body.createFragment(
        html, validator: validator, treeSanitizer: treeSanitizer));
  }

  /**
   * Adds the specified text as a text node after the last child of this
   * document fragment.
   */
  void appendText(String text) {
    this.append(new Text(text));
  }


  /**
   * Parses the specified text as HTML and adds the resulting node after the
   * last child of this document fragment.
   */
  void appendHtml(String text, {NodeValidator validator,
      NodeTreeSanitizer, treeSanitizer}) {
    this.append(new DocumentFragment.html(text, validator: validator,
        treeSanitizer: treeSanitizer));
  }

  /**
   * Alias for [querySelector]. Note this function is deprecated because its
   * semantics will be changing in the future.
   */
  @deprecated
  @Experimental()
  @DomName('DocumentFragment.querySelector')
  Element query(String relativeSelectors) {
    return querySelector(relativeSelectors);
  }

  /**
   * Alias for [querySelectorAll]. Note this function is deprecated because its
   * semantics will be changing in the future.
   */
  @deprecated
  @Experimental()
  @DomName('DocumentFragment.querySelectorAll')
  ElementList<Element> queryAll(String relativeSelectors) {
    return querySelectorAll(relativeSelectors);
  }
  // To suppress missing implicit constructor warnings.
  factory DocumentFragment._() { throw new UnsupportedError("Not supported"); }


  @Deprecated("Internal Use Only")
  static DocumentFragment internalCreateDocumentFragment() {
    return new DocumentFragment.internal_();
  }

  @Deprecated("Internal Use Only")
  DocumentFragment.internal_() : super.internal_();


  @DomName('DocumentFragment.getElementById')
  @DocsEditable()
  @Experimental() // untriaged
  Element getElementById(String elementId) {
    return _getElementById_1(elementId);
  }
  @JSName('getElementById')
  @DomName('DocumentFragment.getElementById')
  @DocsEditable()
  @Experimental() // untriaged
  Element _getElementById_1(elementId) => wrap_jso(JS("Element ", "#.raw.getElementById(#)", this, unwrap_jso(elementId)));

  // From ParentNode

  @JSName('childElementCount')
  @DomName('DocumentFragment.childElementCount')
  @DocsEditable()
  int get _childElementCount => wrap_jso(JS("int", "#.childElementCount", this.raw));

  @JSName('firstElementChild')
  @DomName('DocumentFragment.firstElementChild')
  @DocsEditable()
  Element get _firstElementChild => wrap_jso(JS("Element", "#.firstElementChild", this.raw));

  @JSName('lastElementChild')
  @DomName('DocumentFragment.lastElementChild')
  @DocsEditable()
  Element get _lastElementChild => wrap_jso(JS("Element", "#.lastElementChild", this.raw));

  /**
   * Finds the first descendant element of this document fragment that matches
   * the specified group of selectors.
   *
   * [selectors] should be a string using CSS selector syntax.
   *
   *     var element1 = fragment.querySelector('.className');
   *     var element2 = fragment.querySelector('#id');
   *
   * For details about CSS selector syntax, see the
   * [CSS selector specification](http://www.w3.org/TR/css3-selectors/).
   */
  @DomName('DocumentFragment.querySelector')
  @DocsEditable()
  Element querySelector(String selectors) {
    return _querySelector_1(selectors);
  }
  @JSName('querySelector')
  /**
   * Finds the first descendant element of this document fragment that matches
   * the specified group of selectors.
   *
   * [selectors] should be a string using CSS selector syntax.
   *
   *     var element1 = fragment.querySelector('.className');
   *     var element2 = fragment.querySelector('#id');
   *
   * For details about CSS selector syntax, see the
   * [CSS selector specification](http://www.w3.org/TR/css3-selectors/).
   */
  @DomName('DocumentFragment.querySelector')
  @DocsEditable()
  Element _querySelector_1(selectors) => wrap_jso(JS("Element ", "#.raw.querySelector(#)", this, unwrap_jso(selectors)));

  @DomName('DocumentFragment.querySelectorAll')
  @DocsEditable()
  @Returns('NodeList')
  @Creates('NodeList')
  NodeList _querySelectorAll(String selectors) {
    return _querySelectorAll_1(selectors);
  }
  @JSName('querySelectorAll')
  @DomName('DocumentFragment.querySelectorAll')
  @DocsEditable()
  @Returns('NodeList')
  @Creates('NodeList')
  NodeList _querySelectorAll_1(selectors) => wrap_jso(JS("NodeList ", "#.raw.querySelectorAll(#)", this, unwrap_jso(selectors)));

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('DOMImplementation')
@Native("DOMImplementation")
class DomImplementation extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory DomImplementation._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static DomImplementation internalCreateDomImplementation() {
    return new DomImplementation.internal_();
  }

  @Deprecated("Internal Use Only")
  DomImplementation.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

  @DomName('DOMImplementation.createDocument')
  @DocsEditable()
  Document createDocument(String namespaceURI, String qualifiedName, Node doctype) {
    return _createDocument_1(namespaceURI, qualifiedName, doctype);
  }
  @JSName('createDocument')
  @DomName('DOMImplementation.createDocument')
  @DocsEditable()
  Document _createDocument_1(namespaceURI, qualifiedName, Node doctype) => wrap_jso(JS("Document ", "#.raw.createDocument(#, #, #)", this, unwrap_jso(namespaceURI), unwrap_jso(qualifiedName), unwrap_jso(doctype)));

  @DomName('DOMImplementation.createDocumentType')
  @DocsEditable()
  Node createDocumentType(String qualifiedName, String publicId, String systemId) {
    return _createDocumentType_1(qualifiedName, publicId, systemId);
  }
  @JSName('createDocumentType')
  @DomName('DOMImplementation.createDocumentType')
  @DocsEditable()
  Node _createDocumentType_1(qualifiedName, publicId, systemId) => wrap_jso(JS("Node ", "#.raw.createDocumentType(#, #, #)", this, unwrap_jso(qualifiedName), unwrap_jso(publicId), unwrap_jso(systemId)));

  @DomName('DOMImplementation.createHTMLDocument')
  @DocsEditable()
  HtmlDocument createHtmlDocument(String title) {
    return _createHtmlDocument_1(title);
  }
  @JSName('createHTMLDocument')
  @DomName('DOMImplementation.createHTMLDocument')
  @DocsEditable()
  HtmlDocument _createHtmlDocument_1(title) => wrap_jso(JS("HtmlDocument ", "#.raw.createHTMLDocument(#)", this, unwrap_jso(title)));

  @DomName('DOMImplementation.hasFeature')
  @DocsEditable()
  bool hasFeature(String feature, String version) {
    return _hasFeature_1(feature, version);
  }
  @JSName('hasFeature')
  @DomName('DOMImplementation.hasFeature')
  @DocsEditable()
  bool _hasFeature_1(feature, version) => wrap_jso(JS("bool ", "#.raw.hasFeature(#, #)", this, unwrap_jso(feature), unwrap_jso(version)));
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('DOMTokenList')
@Native("DOMTokenList")
class DomTokenList extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory DomTokenList._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static DomTokenList internalCreateDomTokenList() {
    return new DomTokenList.internal_();
  }

  @Deprecated("Internal Use Only")
  DomTokenList.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

  @DomName('DOMTokenList.length')
  @DocsEditable()
  int get length => wrap_jso(JS("int", "#.length", this.raw));

  @DomName('DOMTokenList.add')
  @DocsEditable()
  @Experimental() // untriaged
  void add(String tokens) {
    _add_1(tokens);
    return;
  }
  @JSName('add')
  @DomName('DOMTokenList.add')
  @DocsEditable()
  @Experimental() // untriaged
  void _add_1(tokens) => wrap_jso(JS("void ", "#.raw.add(#)", this, unwrap_jso(tokens)));

  @DomName('DOMTokenList.contains')
  @DocsEditable()
  bool contains(String token) {
    return _contains_1(token);
  }
  @JSName('contains')
  @DomName('DOMTokenList.contains')
  @DocsEditable()
  bool _contains_1(token) => wrap_jso(JS("bool ", "#.raw.contains(#)", this, unwrap_jso(token)));

  @DomName('DOMTokenList.item')
  @DocsEditable()
  String item(int index) {
    return _item_1(index);
  }
  @JSName('item')
  @DomName('DOMTokenList.item')
  @DocsEditable()
  String _item_1(index) => wrap_jso(JS("String ", "#.raw.item(#)", this, unwrap_jso(index)));

  @DomName('DOMTokenList.remove')
  @DocsEditable()
  @Experimental() // untriaged
  void remove(String tokens) {
    _remove_1(tokens);
    return;
  }
  @JSName('remove')
  @DomName('DOMTokenList.remove')
  @DocsEditable()
  @Experimental() // untriaged
  void _remove_1(tokens) => wrap_jso(JS("void ", "#.raw.remove(#)", this, unwrap_jso(tokens)));

  @DomName('DOMTokenList.toggle')
  @DocsEditable()
  bool toggle(String token, [bool force]) {
    if (force != null) {
      return _toggle_1(token, force);
    }
    return _toggle_2(token);
  }
  @JSName('toggle')
  @DomName('DOMTokenList.toggle')
  @DocsEditable()
  bool _toggle_1(token, force) => wrap_jso(JS("bool ", "#.raw.toggle(#, #)", this, unwrap_jso(token), unwrap_jso(force)));
  @JSName('toggle')
  @DomName('DOMTokenList.toggle')
  @DocsEditable()
  bool _toggle_2(token) => wrap_jso(JS("bool ", "#.raw.toggle(#)", this, unwrap_jso(token)));
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _ChildrenElementList extends ListBase<Element>
    implements NodeListWrapper {
  // Raw Element.
  final Element _element;
  final HtmlCollection _childElements;

  _ChildrenElementList._wrap(Element element)
    : _childElements = element._children,
      _element = element;

  bool contains(Object element) => _childElements.contains(element);


  bool get isEmpty {
    return _element._firstElementChild == null;
  }

  int get length {
    return _childElements.length;
  }

  Element operator [](int index) {
    return _childElements[index];
  }

  void operator []=(int index, Element value) {
    _element._replaceChild(value, _childElements[index]);
  }

  set length(int newLength) {
    // TODO(jacobr): remove children when length is reduced.
    throw new UnsupportedError('Cannot resize element lists');
  }

  Element add(Element value) {
    _element.append(value);
    return value;
  }

  Iterator<Element> get iterator => toList().iterator;

  void addAll(Iterable<Element> iterable) {
    if (iterable is _ChildNodeListLazy) {
      iterable = new List.from(iterable);
    }

    for (Element element in iterable) {
      _element.append(element);
    }
  }

  void sort([int compare(Element a, Element b)]) {
    throw new UnsupportedError('Cannot sort element lists');
  }

  void shuffle([Random random]) {
    throw new UnsupportedError('Cannot shuffle element lists');
  }

  void removeWhere(bool test(Element element)) {
    _filter(test, false);
  }

  void retainWhere(bool test(Element element)) {
    _filter(test, true);
  }

  void _filter(bool test(var element), bool retainMatching) {
    var removed;
    if (retainMatching) {
      removed = _element.children.where((e) => !test(e));
    } else {
      removed = _element.children.where(test);
    }
    for (var e in removed) e.remove();
  }

  void setRange(int start, int end, Iterable<Element> iterable,
                [int skipCount = 0]) {
    throw new UnimplementedError();
  }

  void replaceRange(int start, int end, Iterable<Element> iterable) {
    throw new UnimplementedError();
  }

  void fillRange(int start, int end, [Element fillValue]) {
    throw new UnimplementedError();
  }

  bool remove(Object object) {
    if (object is Element) {
      Element element = object;
      // We aren't preserving identity of nodes in JSINTEROP mode
      if (element.parentNode == _element) {
        _element._removeChild(element);
        return true;
      }
    }
    return false;
  }

  void insert(int index, Element element) {
    if (index < 0 || index > length) {
      throw new RangeError.range(index, 0, length);
    }
    if (index == length) {
      _element.append(element);
    } else {
      _element.insertBefore(element, this[index]);
    }
  }

  void setAll(int index, Iterable<Element> iterable) {
    throw new UnimplementedError();
  }

  void clear() {
    _element._clearChildren();
  }

  Element removeAt(int index) {
    final result = this[index];
    if (result != null) {
      _element._removeChild(result);
    }
    return result;
  }

  Element removeLast() {
    final result = this.last;
    if (result != null) {
      _element._removeChild(result);
    }
    return result;
  }

  Element get first {
    Element result = _element._firstElementChild;
    if (result == null) throw new StateError("No elements");
    return result;
  }


  Element get last {
    Element result = _element._lastElementChild;
    if (result == null) throw new StateError("No elements");
    return result;
  }

  Element get single {
    if (length > 1) throw new StateError("More than one element");
    return first;
  }

  List<Node> get rawList => _childElements;
}

/**
 * An immutable list containing HTML elements. This list contains some
 * additional methods when compared to regular lists for ease of CSS
 * manipulation on a group of elements.
 */
abstract class ElementList<T extends Element> extends ListBase<T> {
  /**
   * The union of all CSS classes applied to the elements in this list.
   *
   * This set makes it easy to add, remove or toggle (add if not present, remove
   * if present) the classes applied to a collection of elements.
   *
   *     htmlList.classes.add('selected');
   *     htmlList.classes.toggle('isOnline');
   *     htmlList.classes.remove('selected');
   */
  CssClassSet get classes;

  /** Replace the classes with `value` for every element in this list. */
  set classes(Iterable<String> value);

  /**
   * Access the union of all [CssStyleDeclaration]s that are associated with an
   * [ElementList].
   *
   * Grouping the style objects all together provides easy editing of specific
   * properties of a collection of elements. Setting a specific property value
   * will set that property in all [Element]s in the [ElementList]. Getting a
   * specific property value will return the value of the property of the first
   * element in the [ElementList].
   */
  CssStyleDeclarationBase get style;

  /**
   * Access dimensions and position of the Elements in this list.
   *
   * Setting the height or width properties will set the height or width
   * property for all elements in the list. This returns a rectangle with the
   * dimenions actually available for content
   * in this element, in pixels, regardless of this element's box-sizing
   * property. Getting the height or width returns the height or width of the
   * first Element in this list.
   *
   * Unlike [getBoundingClientRect], the dimensions of this rectangle
   * will return the same numerical height if the element is hidden or not.
   */
  @Experimental()
  CssRect get contentEdge;

  /**
   * Access dimensions and position of the first Element's content + padding box
   * in this list.
   *
   * This returns a rectangle with the dimenions actually available for content
   * in this element, in pixels, regardless of this element's box-sizing
   * property. Unlike [getBoundingClientRect], the dimensions of this rectangle
   * will return the same numerical height if the element is hidden or not. This
   * can be used to retrieve jQuery's `innerHeight` value for an element. This
   * is also a rectangle equalling the dimensions of clientHeight and
   * clientWidth.
   */
  @Experimental()
  CssRect get paddingEdge;

  /**
   * Access dimensions and position of the first Element's content + padding +
   * border box in this list.
   *
   * This returns a rectangle with the dimenions actually available for content
   * in this element, in pixels, regardless of this element's box-sizing
   * property. Unlike [getBoundingClientRect], the dimensions of this rectangle
   * will return the same numerical height if the element is hidden or not. This
   * can be used to retrieve jQuery's `outerHeight` value for an element.
   */
  @Experimental()
  CssRect get borderEdge;

  /**
   * Access dimensions and position of the first Element's content + padding +
   * border + margin box in this list.
   *
   * This returns a rectangle with the dimenions actually available for content
   * in this element, in pixels, regardless of this element's box-sizing
   * property. Unlike [getBoundingClientRect], the dimensions of this rectangle
   * will return the same numerical height if the element is hidden or not. This
   * can be used to retrieve jQuery's `outerHeight` value for an element.
   */
  @Experimental()
  CssRect get marginEdge;

  /// Stream of `beforecopy` events handled by this [Element].
  @DomName('Element.onbeforecopy')
  @DocsEditable()
  ElementStream<Event> get onBeforeCopy;

  /// Stream of `beforecut` events handled by this [Element].
  @DomName('Element.onbeforecut')
  @DocsEditable()
  ElementStream<Event> get onBeforeCut;

  /// Stream of `beforepaste` events handled by this [Element].
  @DomName('Element.onbeforepaste')
  @DocsEditable()
  ElementStream<Event> get onBeforePaste;

  /// Stream of `copy` events handled by this [Element].
  @DomName('Element.oncopy')
  @DocsEditable()
  ElementStream<Event> get onCopy;

  /// Stream of `cut` events handled by this [Element].
  @DomName('Element.oncut')
  @DocsEditable()
  ElementStream<Event> get onCut;

  /// Stream of `paste` events handled by this [Element].
  @DomName('Element.onpaste')
  @DocsEditable()
  ElementStream<Event> get onPaste;

  /// Stream of `search` events handled by this [Element].
  @DomName('Element.onsearch')
  @DocsEditable()
  // http://www.w3.org/TR/html-markup/input.search.html
  @Experimental()
  ElementStream<Event> get onSearch;

  /// Stream of `selectstart` events handled by this [Element].
  @DomName('Element.onselectstart')
  @DocsEditable()
  @Experimental() // nonstandard
  ElementStream<Event> get onSelectStart;

  /// Stream of `fullscreenchange` events handled by this [Element].
  @DomName('Element.onwebkitfullscreenchange')
  @DocsEditable()
  // https://dvcs.w3.org/hg/fullscreen/raw-file/tip/Overview.html
  @Experimental()
  ElementStream<Event> get onFullscreenChange;

  /// Stream of `fullscreenerror` events handled by this [Element].
  @DomName('Element.onwebkitfullscreenerror')
  @DocsEditable()
  // https://dvcs.w3.org/hg/fullscreen/raw-file/tip/Overview.html
  @Experimental()
  ElementStream<Event> get onFullscreenError;

}

// Wrapper over an immutable NodeList to make it implement ElementList.
//
// Clients are {`Document`, `DocumentFragment`}.`querySelectorAll` which are
// declared to return `ElementList`.  This provides all the static analysis
// benefit so there is no need for this class have a constrained type parameter.
//
class _FrozenElementList extends ListBase<Element>
    implements ElementList<Element>, NodeListWrapper {
  final List<Node> _nodeList;

  var dartClass_instance;

  _FrozenElementList._wrap(this._nodeList) {
      this.dartClass_instance = this._nodeList;
  }

  int get length => _nodeList.length;

  Element operator [](int index) => _nodeList[index];

  void operator []=(int index, Element value) {
    throw new UnsupportedError('Cannot modify list');
  }

  set length(int newLength) {
    throw new UnsupportedError('Cannot modify list');
  }

  void sort([Comparator<Element> compare]) {
    throw new UnsupportedError('Cannot sort list');
  }

  void shuffle([Random random]) {
    throw new UnsupportedError('Cannot shuffle list');
  }

  Element get first => _nodeList.first;

  Element get last => _nodeList.last;

  Element get single => _nodeList.single;

  CssClassSet get classes => new _MultiElementCssClassSet(this);

  CssStyleDeclarationBase get style =>
      new _CssStyleDeclarationSet(this);

  set classes(Iterable<String> value) {
    // TODO(sra): This might be faster for Sets:
    //
    //     new _MultiElementCssClassSet(this).writeClasses(value)
    //
    // as the code below converts the Iterable[value] to a string multiple
    // times.  Maybe compute the string and set className here.
    _nodeList.forEach((e) => e.classes = value);
  }

  CssRect get contentEdge => new _ContentCssListRect(this);

  CssRect get paddingEdge => this.first.paddingEdge;

  CssRect get borderEdge => this.first.borderEdge;

  CssRect get marginEdge => this.first.marginEdge;

  List<Node> get rawList => _nodeList;


  /// Stream of `beforecopy` events handled by this [Element].
  @DomName('Element.onbeforecopy')
  @DocsEditable()
  ElementStream<Event> get onBeforeCopy => Element.beforeCopyEvent._forElementList(this);

  /// Stream of `beforecut` events handled by this [Element].
  @DomName('Element.onbeforecut')
  @DocsEditable()
  ElementStream<Event> get onBeforeCut => Element.beforeCutEvent._forElementList(this);

  /// Stream of `beforepaste` events handled by this [Element].
  @DomName('Element.onbeforepaste')
  @DocsEditable()
  ElementStream<Event> get onBeforePaste => Element.beforePasteEvent._forElementList(this);

  /// Stream of `copy` events handled by this [Element].
  @DomName('Element.oncopy')
  @DocsEditable()
  ElementStream<Event> get onCopy => Element.copyEvent._forElementList(this);

  /// Stream of `cut` events handled by this [Element].
  @DomName('Element.oncut')
  @DocsEditable()
  ElementStream<Event> get onCut => Element.cutEvent._forElementList(this);

  /// Stream of `paste` events handled by this [Element].
  @DomName('Element.onpaste')
  @DocsEditable()
  ElementStream<Event> get onPaste => Element.pasteEvent._forElementList(this);

  /// Stream of `search` events handled by this [Element].
  @DomName('Element.onsearch')
  @DocsEditable()
  // http://www.w3.org/TR/html-markup/input.search.html
  @Experimental()
  ElementStream<Event> get onSearch => Element.searchEvent._forElementList(this);

  /// Stream of `selectstart` events handled by this [Element].
  @DomName('Element.onselectstart')
  @DocsEditable()
  @Experimental() // nonstandard
  ElementStream<Event> get onSelectStart => Element.selectStartEvent._forElementList(this);

  /// Stream of `fullscreenchange` events handled by this [Element].
  @DomName('Element.onwebkitfullscreenchange')
  @DocsEditable()
  // https://dvcs.w3.org/hg/fullscreen/raw-file/tip/Overview.html
  @Experimental()
  ElementStream<Event> get onFullscreenChange => Element.fullscreenChangeEvent._forElementList(this);

  /// Stream of `fullscreenerror` events handled by this [Element].
  @DomName('Element.onwebkitfullscreenerror')
  @DocsEditable()
  // https://dvcs.w3.org/hg/fullscreen/raw-file/tip/Overview.html
  @Experimental()
  ElementStream<Event> get onFullscreenError => Element.fullscreenErrorEvent._forElementList(this);

}

@DocsEditable()
/**
 * An abstract class, which all HTML elements extend.
 */
@DomName('Element')
@Native("Element")
class Element extends Node implements ParentNode, ChildNode {

  /**
   * Creates an HTML element from a valid fragment of HTML.
   *
   *     var element = new Element.html('<div class="foo">content</div>');
   *
   * The HTML fragment should contain only one single root element, any
   * leading or trailing text nodes will be removed.
   *
   * The HTML fragment is parsed as if it occurred within the context of a
   * `<body>` tag, this means that special elements such as `<caption>` which
   * must be parsed within the scope of a `<table>` element will be dropped. Use
   * [createFragment] to parse contextual HTML fragments.
   *
   * Unless a validator is provided this will perform the default validation
   * and remove all scriptable elements and attributes.
   *
   * See also:
   *
   * * [NodeValidator]
   *
   */
  factory Element.html(String html,
      {NodeValidator validator, NodeTreeSanitizer treeSanitizer}) {
    var fragment = document.body.createFragment(html, validator: validator,
        treeSanitizer: treeSanitizer);

    return fragment.nodes.where((e) => e is Element).single;
  }

  /**
   * Custom element creation constructor.
   *
   * This constructor is used by the DOM when a custom element has been
   * created. It can only be invoked by subclasses of Element from
   * that classes created constructor.
   *
   *     class CustomElement extends Element {
   *       factory CustomElement() => new Element.tag('x-custom');
   *
   *       CustomElement.created() : super.created() {
   *          // Perform any element initialization.
   *       }
   *     }
   *     document.registerElement('x-custom', CustomElement);
   */
  Element.created() : super._created();

  /**
   * Creates the HTML element specified by the tag name.
   *
   * This is similar to [Document.createElement].
   * [tag] should be a valid HTML tag name. If [tag] is an unknown tag then
   * this will create an [UnknownElement].
   *
   *     var divElement = new Element.tag('div');
   *     print(divElement is DivElement); // 'true'
   *     var myElement = new Element.tag('unknownTag');
   *     print(myElement is UnknownElement); // 'true'
   *
   * For standard elements it is more preferable to use the type constructors:
   *     var element = new DivElement();
   *
   * See also:
   *
   * * [isTagSupported]
   */
  factory Element.tag(String tag, [String typeExtention]) =>
      _ElementFactoryProvider.createElement_tag(tag, typeExtention);

  /// Creates a new `<a>` element.
  ///
  /// This is identical to calling `new Element.tag('a')`.
  factory Element.a() => new Element.tag('a');

  /// Creates a new `<article>` element.
  ///
  /// This is identical to calling `new Element.tag('article')`.
  factory Element.article() => new Element.tag('article');

  /// Creates a new `<aside>` element.
  ///
  /// This is identical to calling `new Element.tag('aside')`.
  factory Element.aside() => new Element.tag('aside');

  /// Creates a new `<audio>` element.
  ///
  /// This is identical to calling `new Element.tag('audio')`.
  factory Element.audio() => new Element.tag('audio');

  /// Creates a new `<br>` element.
  ///
  /// This is identical to calling `new Element.tag('br')`.
  factory Element.br() => new Element.tag('br');

  /// Creates a new `<canvas>` element.
  ///
  /// This is identical to calling `new Element.tag('canvas')`.
  factory Element.canvas() => new Element.tag('canvas');

  /// Creates a new `<div>` element.
  ///
  /// This is identical to calling `new Element.tag('div')`.
  factory Element.div() => new Element.tag('div');

  /// Creates a new `<footer>` element.
  ///
  /// This is identical to calling `new Element.tag('footer')`.
  factory Element.footer() => new Element.tag('footer');

  /// Creates a new `<header>` element.
  ///
  /// This is identical to calling `new Element.tag('header')`.
  factory Element.header() => new Element.tag('header');

  /// Creates a new `<hr>` element.
  ///
  /// This is identical to calling `new Element.tag('hr')`.
  factory Element.hr() => new Element.tag('hr');

  /// Creates a new `<iframe>` element.
  ///
  /// This is identical to calling `new Element.tag('iframe')`.
  factory Element.iframe() => new Element.tag('iframe');

  /// Creates a new `<img>` element.
  ///
  /// This is identical to calling `new Element.tag('img')`.
  factory Element.img() => new Element.tag('img');

  /// Creates a new `<li>` element.
  ///
  /// This is identical to calling `new Element.tag('li')`.
  factory Element.li() => new Element.tag('li');

  /// Creates a new `<nav>` element.
  ///
  /// This is identical to calling `new Element.tag('nav')`.
  factory Element.nav() => new Element.tag('nav');

  /// Creates a new `<ol>` element.
  ///
  /// This is identical to calling `new Element.tag('ol')`.
  factory Element.ol() => new Element.tag('ol');

  /// Creates a new `<option>` element.
  ///
  /// This is identical to calling `new Element.tag('option')`.
  factory Element.option() => new Element.tag('option');

  /// Creates a new `<p>` element.
  ///
  /// This is identical to calling `new Element.tag('p')`.
  factory Element.p() => new Element.tag('p');

  /// Creates a new `<pre>` element.
  ///
  /// This is identical to calling `new Element.tag('pre')`.
  factory Element.pre() => new Element.tag('pre');

  /// Creates a new `<section>` element.
  ///
  /// This is identical to calling `new Element.tag('section')`.
  factory Element.section() => new Element.tag('section');

  /// Creates a new `<select>` element.
  ///
  /// This is identical to calling `new Element.tag('select')`.
  factory Element.select() => new Element.tag('select');

  /// Creates a new `<span>` element.
  ///
  /// This is identical to calling `new Element.tag('span')`.
  factory Element.span() => new Element.tag('span');

  /// Creates a new `<svg>` element.
  ///
  /// This is identical to calling `new Element.tag('svg')`.
  factory Element.svg() => new Element.tag('svg');

  /// Creates a new `<table>` element.
  ///
  /// This is identical to calling `new Element.tag('table')`.
  factory Element.table() => new Element.tag('table');

  /// Creates a new `<td>` element.
  ///
  /// This is identical to calling `new Element.tag('td')`.
  factory Element.td() => new Element.tag('td');

  /// Creates a new `<textarea>` element.
  ///
  /// This is identical to calling `new Element.tag('textarea')`.
  factory Element.textarea() => new Element.tag('textarea');

  /// Creates a new `<th>` element.
  ///
  /// This is identical to calling `new Element.tag('th')`.
  factory Element.th() => new Element.tag('th');

  /// Creates a new `<tr>` element.
  ///
  /// This is identical to calling `new Element.tag('tr')`.
  factory Element.tr() => new Element.tag('tr');

  /// Creates a new `<ul>` element.
  ///
  /// This is identical to calling `new Element.tag('ul')`.
  factory Element.ul() => new Element.tag('ul');

  /// Creates a new `<video>` element.
  ///
  /// This is identical to calling `new Element.tag('video')`.
  factory Element.video() => new Element.tag('video');

  /**
   * All attributes on this element.
   *
   * Any modifications to the attribute map will automatically be applied to
   * this element.
   *
   * This only includes attributes which are not in a namespace
   * (such as 'xlink:href'), additional attributes can be accessed via
   * [getNamespacedAttributes].
   */
  Map<String, String> get attributes => new _ElementAttributeMap(this);

  set attributes(Map<String, String> value) {
    Map<String, String> attributes = this.attributes;
    attributes.clear();
    for (String key in value.keys) {
      attributes[key] = value[key];
    }
  }

  /**
   * List of the direct children of this element.
   *
   * This collection can be used to add and remove elements from the document.
   *
   *     var item = new DivElement();
   *     item.text = 'Something';
   *     document.body.children.add(item) // Item is now displayed on the page.
   *     for (var element in document.body.children) {
   *       element.style.background = 'red'; // Turns every child of body red.
   *     }
   */
  List<Element> get children => new _ChildrenElementList._wrap(this);

  set children(List<Element> value) {
    // Copy list first since we don't want liveness during iteration.
    List copy = new List.from(value);
    var children = this.children;
    children.clear();
    children.addAll(copy);
  }

  /**
   * Finds all descendent elements of this element that match the specified
   * group of selectors.
   *
   * [selectors] should be a string using CSS selector syntax.
   *
   *     var items = element.querySelectorAll('.itemClassName');
   *
   * For details about CSS selector syntax, see the
   * [CSS selector specification](http://www.w3.org/TR/css3-selectors/).
   */
  @DomName('Element.querySelectorAll')
  ElementList<Element> querySelectorAll(String selectors) =>
    new _FrozenElementList._wrap(_querySelectorAll(selectors));

  /**
   * Alias for [querySelector]. Note this function is deprecated because its
   * semantics will be changing in the future.
   */
  @deprecated
  @DomName('Element.querySelector')
  @Experimental()
  Element query(String relativeSelectors) => querySelector(relativeSelectors);

  /**
   * Alias for [querySelectorAll]. Note this function is deprecated because its
   * semantics will be changing in the future.
   */
  @deprecated
  @DomName('Element.querySelectorAll')
  @Experimental()
  ElementList<Element> queryAll(String relativeSelectors) =>
      querySelectorAll(relativeSelectors);

  /**
   * The set of CSS classes applied to this element.
   *
   * This set makes it easy to add, remove or toggle the classes applied to
   * this element.
   *
   *     element.classes.add('selected');
   *     element.classes.toggle('isOnline');
   *     element.classes.remove('selected');
   */
  CssClassSet get classes => new _ElementCssClassSet(this);

  set classes(Iterable<String> value) {
    // TODO(sra): Do this without reading the classes in clear() and addAll(),
    // or writing the classes in clear().
    CssClassSet classSet = classes;
    classSet.clear();
    classSet.addAll(value);
  }

  /**
   * Allows access to all custom data attributes (data-*) set on this element.
   *
   * The keys for the map must follow these rules:
   *
   * * The name must not begin with 'xml'.
   * * The name cannot contain a semi-colon (';').
   * * The name cannot contain any capital letters.
   *
   * Any keys from markup will be converted to camel-cased keys in the map.
   *
   * For example, HTML specified as:
   *
   *     <div data-my-random-value='value'></div>
   *
   * Would be accessed in Dart as:
   *
   *     var value = element.dataset['myRandomValue'];
   *
   * See also:
   *
   * * [Custom data attributes](http://www.w3.org/TR/html5/global-attributes.html#custom-data-attribute)
   */
  Map<String, String> get dataset =>
    new _DataAttributeMap(attributes);

  set dataset(Map<String, String> value) {
    final data = this.dataset;
    data.clear();
    for (String key in value.keys) {
      data[key] = value[key];
    }
  }

  /**
   * Gets a map for manipulating the attributes of a particular namespace.
   *
   * This is primarily useful for SVG attributes such as xref:link.
   */
  Map<String, String> getNamespacedAttributes(String namespace) {
    return new _NamespacedAttributeMap(this, namespace);
  }

  /**
   * The set of all CSS values applied to this element, including inherited
   * and default values.
   *
   * The computedStyle contains values that are inherited from other
   * sources, such as parent elements or stylesheets. This differs from the
   * [style] property, which contains only the values specified directly on this
   * element.
   *
   * PseudoElement can be values such as `::after`, `::before`, `::marker`,
   * `::line-marker`.
   *
   * See also:
   *
   * * [CSS Inheritance and Cascade](http://docs.webplatform.org/wiki/tutorials/inheritance_and_cascade)
   * * [Pseudo-elements](http://docs.webplatform.org/wiki/css/selectors/pseudo-elements)
   */
  CssStyleDeclaration getComputedStyle([String pseudoElement]) {
    if (pseudoElement == null) {
      pseudoElement = '';
    }
    // TODO(jacobr): last param should be null, see b/5045788
    return window._getComputedStyle(this, pseudoElement);
  }

  /**
   * Gets the position of this element relative to the client area of the page.
   */
  Rectangle get client => new Rectangle(clientLeft, clientTop, clientWidth,
      clientHeight);

  /**
   * Gets the offset of this element relative to its offsetParent.
   */
  Rectangle get offset => new Rectangle(offsetLeft, offsetTop, offsetWidth,
      offsetHeight);

  /**
   * Adds the specified text after the last child of this element.
   */
  void appendText(String text) {
    this.append(new Text(text));
  }

  /**
   * Parses the specified text as HTML and adds the resulting node after the
   * last child of this element.
   */
  void appendHtml(String text, {NodeValidator validator,
      NodeTreeSanitizer treeSanitizer}) {
    this.insertAdjacentHtml('beforeend', text, validator: validator,
        treeSanitizer: treeSanitizer);
  }

  /**
   * Checks to see if the tag name is supported by the current platform.
   *
   * The tag should be a valid HTML tag name.
   */
  static bool isTagSupported(String tag) {
    var e = _ElementFactoryProvider.createElement_tag(tag, null);
    return e is Element && !(JS('bool', '#.constructor.name == "HTMLUnknownElement"', e));
  }

  /**
   * Called by the DOM when this element has been inserted into the live
   * document.
   *
   * More information can be found in the
   * [Custom Elements](http://w3c.github.io/webcomponents/spec/custom/#dfn-attached-callback)
   * draft specification.
   */
  @Experimental()
  void attached() {
    // For the deprecation period, call the old callback.
    enteredView();
  }

  /**
   * Called by the DOM when this element has been removed from the live
   * document.
   *
   * More information can be found in the
   * [Custom Elements](http://w3c.github.io/webcomponents/spec/custom/#dfn-detached-callback)
   * draft specification.
   */
  @Experimental()
  void detached() {
    // For the deprecation period, call the old callback.
    leftView();
  }

  /** *Deprecated*: override [attached] instead. */
  @Experimental()
  @deprecated
  void enteredView() {}

  /** *Deprecated*: override [detached] instead. */
  @Experimental()
  @deprecated
  void leftView() {}


  /**
   * Called by the DOM whenever an attribute on this has been changed.
   */
  void attributeChanged(String name, String oldValue, String newValue) {}

  // Hooks to support custom WebComponents.

  Element _xtag;

  /**
   * Experimental support for [web components][wc]. This field stores a
   * reference to the component implementation. It was inspired by Mozilla's
   * [x-tags][] project. Please note: in the future it may be possible to
   * `extend Element` from your class, in which case this field will be
   * deprecated.
   *
   * If xtag has not been set, it will simply return `this` [Element].
   *
   * [wc]: http://dvcs.w3.org/hg/webcomponents/raw-file/tip/explainer/index.html
   * [x-tags]: http://x-tags.org/
   */
  // Note: return type is `dynamic` for convenience to suppress warnings when
  // members of the component are used. The actual type is a subtype of Element.
  get xtag => _xtag != null ? _xtag : this;

  set xtag(Element value) {
    _xtag = value;
  }

  @DomName('Element.localName')
  @DocsEditable()
  String get localName => _localName;

  /**
   * A URI that identifies the XML namespace of this element.
   *
   * `null` if no namespace URI is specified.
   *
   * ## Other resources
   *
   * * [Node.namespaceURI]
   * (http://www.w3.org/TR/DOM-Level-3-Core/core.html#ID-NodeNSname) from W3C.
   */
  @DomName('Element.namespaceUri')
  String get namespaceUri => _namespaceUri;

  /**
   * The string representation of this element.
   *
   * This is equivalent to reading the [localName] property.
   */
  String toString() => localName;

  /**
   * Scrolls this element into view.
   *
   * Only one of of the alignment options may be specified at a time.
   *
   * If no options are specified then this will attempt to scroll the minimum
   * amount needed to bring the element into view.
   *
   * Note that alignCenter is currently only supported on WebKit platforms. If
   * alignCenter is specified but not supported then this will fall back to
   * alignTop.
   *
   * See also:
   *
   * * [scrollIntoView](http://docs.webplatform.org/wiki/dom/methods/scrollIntoView)
   * * [scrollIntoViewIfNeeded](http://docs.webplatform.org/wiki/dom/methods/scrollIntoViewIfNeeded)
   */
  void scrollIntoView([ScrollAlignment alignment]) {
    var hasScrollIntoViewIfNeeded = true;
    if (alignment == ScrollAlignment.TOP) {
      this._scrollIntoView(true);
    } else if (alignment == ScrollAlignment.BOTTOM) {
      this._scrollIntoView(false);
    } else if (hasScrollIntoViewIfNeeded) {
      if (alignment == ScrollAlignment.CENTER) {
        this._scrollIntoViewIfNeeded(true);
      } else {
        this._scrollIntoViewIfNeeded();
      }
    } else {
      this._scrollIntoView();
    }
  }


  /**
   * Parses text as an HTML fragment and inserts it into the DOM at the
   * specified location.
   *
   * The [where] parameter indicates where to insert the HTML fragment:
   *
   * * 'beforeBegin': Immediately before this element.
   * * 'afterBegin': As the first child of this element.
   * * 'beforeEnd': As the last child of this element.
   * * 'afterEnd': Immediately after this element.
   *
   *     var html = '<div class="something">content</div>';
   *     // Inserts as the first child
   *     document.body.insertAdjacentHtml('afterBegin', html);
   *     var createdElement = document.body.children[0];
   *     print(createdElement.classes[0]); // Prints 'something'
   *
   * See also:
   *
   * * [insertAdjacentText]
   * * [insertAdjacentElement]
   */
  void insertAdjacentHtml(String where, String html, {NodeValidator validator,
      NodeTreeSanitizer treeSanitizer}) {
      if (treeSanitizer is _TrustedHtmlTreeSanitizer) {
        _insertAdjacentHtml(where, html);
      } else {
        _insertAdjacentNode(where, createFragment(html,
            validator: validator, treeSanitizer: treeSanitizer));
      }
  }

  @JSName('insertAdjacentHTML')
  void _insertAdjacentHtml(String where, String text) => JS('void', '#.insertAdjacentHTML(#,#)', this.raw, where, text);


  void _insertAdjacentNode(String where, Node node) {
    switch (where.toLowerCase()) {
      case 'beforebegin':
        this.parentNode.insertBefore(node, this);
        break;
      case 'afterbegin':
        var first = this.nodes.length > 0 ? this.nodes[0] : null;
        this.insertBefore(node, first);
        break;
      case 'beforeend':
        this.append(node);
        break;
      case 'afterend':
        this.parentNode.insertBefore(node, this.nextNode);
        break;
      default:
        throw new ArgumentError("Invalid position ${where}");
    }
  }

  bool matches(String selectors) => JS('bool', '#.matches(#)', this.raw, selectors);

  /** Checks if this element or any of its parents match the CSS selectors. */
  @Experimental()
  bool matchesWithAncestors(String selectors) {
    var elem = this;
    do {
      if (elem.matches(selectors)) return true;
      elem = elem.parent;
    } while(elem != null);
    return false;
  }


  /**
   * Access this element's content position.
   *
   * This returns a rectangle with the dimenions actually available for content
   * in this element, in pixels, regardless of this element's box-sizing
   * property. Unlike [getBoundingClientRect], the dimensions of this rectangle
   * will return the same numerical height if the element is hidden or not.
   *
   * _Important_ _note_: use of this method _will_ perform CSS calculations that
   * can trigger a browser reflow. Therefore, use of this property _during_ an
   * animation frame is discouraged. See also:
   * [Browser Reflow](https://developers.google.com/speed/articles/reflow)
   */
  @Experimental()
  CssRect get contentEdge => new _ContentCssRect(this);

  /**
   * Access the dimensions and position of this element's content + padding box.
   *
   * This returns a rectangle with the dimenions actually available for content
   * in this element, in pixels, regardless of this element's box-sizing
   * property. Unlike [getBoundingClientRect], the dimensions of this rectangle
   * will return the same numerical height if the element is hidden or not. This
   * can be used to retrieve jQuery's
   * [innerHeight](http://api.jquery.com/innerHeight/) value for an element.
   * This is also a rectangle equalling the dimensions of clientHeight and
   * clientWidth.
   *
   * _Important_ _note_: use of this method _will_ perform CSS calculations that
   * can trigger a browser reflow. Therefore, use of this property _during_ an
   * animation frame is discouraged. See also:
   * [Browser Reflow](https://developers.google.com/speed/articles/reflow)
   */
  @Experimental()
  CssRect get paddingEdge => new _PaddingCssRect(this);

  /**
   * Access the dimensions and position of this element's content + padding +
   * border box.
   *
   * This returns a rectangle with the dimenions actually available for content
   * in this element, in pixels, regardless of this element's box-sizing
   * property. Unlike [getBoundingClientRect], the dimensions of this rectangle
   * will return the same numerical height if the element is hidden or not. This
   * can be used to retrieve jQuery's
   * [outerHeight](http://api.jquery.com/outerHeight/) value for an element.
   *
   * _Important_ _note_: use of this method _will_ perform CSS calculations that
   * can trigger a browser reflow. Therefore, use of this property _during_ an
   * animation frame is discouraged. See also:
   * [Browser Reflow](https://developers.google.com/speed/articles/reflow)
   */
  @Experimental()
  CssRect get borderEdge => new _BorderCssRect(this);

  /**
   * Access the dimensions and position of this element's content + padding +
   * border + margin box.
   *
   * This returns a rectangle with the dimenions actually available for content
   * in this element, in pixels, regardless of this element's box-sizing
   * property. Unlike [getBoundingClientRect], the dimensions of this rectangle
   * will return the same numerical height if the element is hidden or not. This
   * can be used to retrieve jQuery's
   * [outerHeight](http://api.jquery.com/outerHeight/) value for an element.
   *
   * _Important_ _note_: use of this method will perform CSS calculations that
   * can trigger a browser reflow. Therefore, use of this property _during_ an
   * animation frame is discouraged. See also:
   * [Browser Reflow](https://developers.google.com/speed/articles/reflow)
   */
  @Experimental()
  CssRect get marginEdge => new _MarginCssRect(this);

  /**
   * Provides the coordinates of the element relative to the top of the
   * document.
   *
   * This method is the Dart equivalent to jQuery's
   * [offset](http://api.jquery.com/offset/) method.
   */
  @Experimental()
  Point get documentOffset => offsetTo(document.documentElement);

  /**
   * Provides the offset of this element's [borderEdge] relative to the
   * specified [parent].
   *
   * This is the Dart equivalent of jQuery's
   * [position](http://api.jquery.com/position/) method. Unlike jQuery's
   * position, however, [parent] can be any parent element of `this`,
   * rather than only `this`'s immediate [offsetParent]. If the specified
   * element is _not_ an offset parent or transitive offset parent to this
   * element, an [ArgumentError] is thrown.
   */
  @Experimental()
  Point offsetTo(Element parent) {
    return Element._offsetToHelper(this, parent);
  }

  static Point _offsetToHelper(Element current, Element parent) {
    // We're hopping from _offsetParent_ to offsetParent (not just parent), so
    // offsetParent, "tops out" at BODY. But people could conceivably pass in
    // the document.documentElement and I want it to return an absolute offset,
    // so we have the special case checking for HTML.
    bool sameAsParent = current == parent;
    bool foundAsParent = sameAsParent || parent.tagName == 'HTML';
    if (current == null || sameAsParent) {
      if (foundAsParent) return new Point(0, 0);
      throw new ArgumentError("Specified element is not a transitive offset "
          "parent of this element.");
    }
    Element parentOffset = current.offsetParent;
    Point p = Element._offsetToHelper(parentOffset, parent);
    return new Point(p.x + current.offsetLeft, p.y + current.offsetTop);
  }

  static HtmlDocument _parseDocument;
  static Range _parseRange;
  static NodeValidatorBuilder _defaultValidator;
  static _ValidatingTreeSanitizer _defaultSanitizer;

  /**
   * Create a DocumentFragment from the HTML fragment and ensure that it follows
   * the sanitization rules specified by the validator or treeSanitizer.
   *
   * If the default validation behavior is too restrictive then a new
   * NodeValidator should be created, either extending or wrapping a default
   * validator and overriding the validation APIs.
   *
   * The treeSanitizer is used to walk the generated node tree and sanitize it.
   * A custom treeSanitizer can also be provided to perform special validation
   * rules but since the API is more complex to implement this is discouraged.
   *
   * The returned tree is guaranteed to only contain nodes and attributes which
   * are allowed by the provided validator.
   *
   * See also:
   *
   * * [NodeValidator]
   * * [NodeTreeSanitizer]
   */
  DocumentFragment createFragment(String html,
      {NodeValidator validator, NodeTreeSanitizer treeSanitizer}) {
    if (treeSanitizer == null) {
      if (validator == null) {
        if (_defaultValidator == null) {
          _defaultValidator = new NodeValidatorBuilder.common();
        }
        validator = _defaultValidator;
      }
      if (_defaultSanitizer == null) {
        _defaultSanitizer = new _ValidatingTreeSanitizer(validator);
      } else {
        _defaultSanitizer.validator = validator;
      }
      treeSanitizer = _defaultSanitizer;
    } else if (validator != null) {
      throw new ArgumentError(
          'validator can only be passed if treeSanitizer is null');
    }

    if (_parseDocument == null) {
      _parseDocument = document.implementation.createHtmlDocument('');
      _parseRange = _parseDocument.createRange();

      // Workaround for Safari bug. Was also previously Chrome bug 229142
      // - URIs are not resolved in new doc.
      BaseElement base = _parseDocument.createElement('base');
      base.href = document.baseUri;
      _parseDocument.head.append(base);
    }
    var contextElement;
    if (this is BodyElement) {
      contextElement = _parseDocument.body;
    } else {
      contextElement = _parseDocument.createElement(tagName);
      _parseDocument.body.append(contextElement);
    }
    var fragment;
    if (Range.supportsCreateContextualFragment &&
        _canBeUsedToCreateContextualFragment) {
      _parseRange.selectNodeContents(contextElement);
      fragment = _parseRange.createContextualFragment(html);
    } else {
      contextElement._innerHtml = html;

      fragment = _parseDocument.createDocumentFragment();
      while (contextElement.firstChild != null) {
        fragment.append(contextElement.firstChild);
      }
    }
    if (contextElement != _parseDocument.body) {
      contextElement.remove();
    }

    treeSanitizer.sanitizeTree(fragment);
    // Copy the fragment over to the main document (fix for 14184)
    document.adoptNode(fragment);

    return fragment;
  }

  /** Test if createContextualFragment is supported for this element type */
  bool get _canBeUsedToCreateContextualFragment =>
      !_cannotBeUsedToCreateContextualFragment;

  /** Test if createContextualFragment is NOT supported for this element type */
  bool get _cannotBeUsedToCreateContextualFragment =>
      _tagsForWhichCreateContextualFragmentIsNotSupported.contains(tagName);

  /**
   * A hard-coded list of the tag names for which createContextualFragment
   * isn't supported.
   */
  static const _tagsForWhichCreateContextualFragmentIsNotSupported =
      const ['HEAD', 'AREA',
      'BASE', 'BASEFONT', 'BR', 'COL', 'COLGROUP', 'EMBED', 'FRAME', 'FRAMESET',
      'HR', 'IMAGE', 'IMG', 'INPUT', 'ISINDEX', 'LINK', 'META', 'PARAM',
      'SOURCE', 'STYLE', 'TITLE', 'WBR'];

  /**
   * Parses the HTML fragment and sets it as the contents of this element.
   *
   * This uses the default sanitization behavior to sanitize the HTML fragment,
   * use [setInnerHtml] to override the default behavior.
   */
  set innerHtml(String html) {
    this.setInnerHtml(html);
  }

  /**
   * Parses the HTML fragment and sets it as the contents of this element.
   * This ensures that the generated content follows the sanitization rules
   * specified by the validator or treeSanitizer.
   *
   * If the default validation behavior is too restrictive then a new
   * NodeValidator should be created, either extending or wrapping a default
   * validator and overriding the validation APIs.
   *
   * The treeSanitizer is used to walk the generated node tree and sanitize it.
   * A custom treeSanitizer can also be provided to perform special validation
   * rules but since the API is more complex to implement this is discouraged.
   *
   * The resulting tree is guaranteed to only contain nodes and attributes which
   * are allowed by the provided validator.
   *
   * See also:
   *
   * * [NodeValidator]
   * * [NodeTreeSanitizer]
   */
  void setInnerHtml(String html,
    {NodeValidator validator, NodeTreeSanitizer treeSanitizer}) {
    text = null;
    if (treeSanitizer is _TrustedHtmlTreeSanitizer) {
      _innerHtml = html;
    } else {
      append(createFragment(
          html, validator: validator, treeSanitizer: treeSanitizer));
    }
  }
  String get innerHtml => _innerHtml;

  /**
   * This is an ease-of-use accessor for event streams which should only be
   * used when an explicit accessor is not available.
   */
  ElementEvents get on => new ElementEvents(this);

  /**
   * Verify if any of the attributes that we use in the sanitizer look unexpected,
   * possibly indicating DOM clobbering attacks.
   *
   * Those attributes are: attributes, lastChild, children, previousNode and tagName.
   */
  static bool _hasCorruptedAttributes(Element element) {
     return JS('bool', r'''
       (function(element) {
         if (!(element.attributes instanceof NamedNodeMap)) {
	   return true;
	 }
	 var childNodes = element.childNodes;
	 if (element.lastChild &&
	     element.lastChild !== childNodes[childNodes.length -1]) {
	   return true;
	 }
	 if (element.children) { // On Safari, children can apparently be null.
  	   if (!((element.children instanceof HTMLCollection) ||
               (element.children instanceof NodeList))) {
	     return true;
	   }
	 }
         var length = 0;
         if (element.children) {
           length = element.children.length;
         }
         for (var i = 0; i < length; i++) {
           var child = element.children[i];
           // On IE it seems like we sometimes don't see the clobbered attribute,
           // perhaps as a result of an over-optimization. Also use another route
           // to check of attributes, children, or lastChild are clobbered. It may
           // seem silly to check children as we rely on children to do this iteration,
           // but it seems possible that the access to children might see the real thing,
           // allowing us to check for clobbering that may show up in other accesses.
           if (child["id"] == 'attributes' || child["name"] == 'attributes' ||
               child["id"] == 'lastChild'  || child["name"] == 'lastChild' ||
               child["id"] == 'children' || child["name"] == 'children') {
             return true;
           }
         }
	 return false;
          })(#)''',
       element.raw
);
  }

  /// A secondary check for corruption, needed on IE
  static bool _hasCorruptedAttributesAdditionalCheck(Element element) {
    return JS('bool', r'!(#.attributes instanceof NamedNodeMap)',
       element.raw
);
  }

  static String _safeTagName(element) {
    String result = 'element tag unavailable';
    try {
      if (element.tagName is String) {
        result = element.tagName;
      }
    } catch (e) {}
    return result;
  }

  @DomName('Element.offsetHeight')
  @DocsEditable()
  int get offsetHeight => JS('num', '#.offsetHeight', this.raw).round();

  @DomName('Element.offsetLeft')
  @DocsEditable()
  int get offsetLeft => JS('num', '#.offsetLeft', this.raw).round();

  @DomName('Element.offsetTop')
  @DocsEditable()
  int get offsetTop => JS('num', '#.offsetTop', this.raw).round();

  @DomName('Element.offsetWidth')
  @DocsEditable()
  int get offsetWidth => JS('num', '#.offsetWidth', this.raw).round();

  @DomName('Element.clientHeight')
  @DocsEditable()
  int get clientHeight => JS('num', '#.clientHeight', this.raw).round();

  @DomName('Element.clientLeft')
  @DocsEditable()
  int get clientLeft => JS('num', '#.clientLeft', this.raw).round();

  @DomName('Element.clientTop')
  @DocsEditable()
  int get clientTop => JS('num', '#.clientTop', this.raw).round();

  @DomName('Element.clientWidth')
  @DocsEditable()
  int get clientWidth => JS('num', '#.clientWidth', this.raw).round();

  @DomName('Element.scrollHeight')
  @DocsEditable()
  int get scrollHeight => JS('num', '#.scrollHeight', this.raw).round();

  @DomName('Element.scrollLeft')
  @DocsEditable()
  int get scrollLeft => JS('num', '#.scrollLeft', this.raw).round();

  @DomName('Element.scrollLeft')
  @DocsEditable()
  set scrollLeft(int value) {
    JS("void", "#.scrollLeft = #", this.raw, value.round());
  }

  @DomName('Element.scrollTop')
  @DocsEditable()
  int get scrollTop => JS('num', '#.scrollTop', this.raw).round();

  @DomName('Element.scrollTop')
  @DocsEditable()
  set scrollTop(int value) {
    JS("void", "#.scrollTop = #", this.raw, value.round());
  }

  @DomName('Element.scrollWidth')
  @DocsEditable()
  int get scrollWidth => JS('num', '#.scrollWidth', this.raw).round();

  // To suppress missing implicit constructor warnings.
  factory Element._() { throw new UnsupportedError("Not supported"); }

  /**
   * Static factory designed to expose `beforecopy` events to event
   * handlers that are not necessarily instances of [Element].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('Element.beforecopyEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> beforeCopyEvent = const EventStreamProvider<Event>('beforecopy');

  /**
   * Static factory designed to expose `beforecut` events to event
   * handlers that are not necessarily instances of [Element].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('Element.beforecutEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> beforeCutEvent = const EventStreamProvider<Event>('beforecut');

  /**
   * Static factory designed to expose `beforepaste` events to event
   * handlers that are not necessarily instances of [Element].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('Element.beforepasteEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> beforePasteEvent = const EventStreamProvider<Event>('beforepaste');

  /**
   * Static factory designed to expose `copy` events to event
   * handlers that are not necessarily instances of [Element].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('Element.copyEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> copyEvent = const EventStreamProvider<Event>('copy');

  /**
   * Static factory designed to expose `cut` events to event
   * handlers that are not necessarily instances of [Element].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('Element.cutEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> cutEvent = const EventStreamProvider<Event>('cut');

  /**
   * Static factory designed to expose `paste` events to event
   * handlers that are not necessarily instances of [Element].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('Element.pasteEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> pasteEvent = const EventStreamProvider<Event>('paste');

  /**
   * Static factory designed to expose `search` events to event
   * handlers that are not necessarily instances of [Element].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('Element.searchEvent')
  @DocsEditable()
  // http://www.w3.org/TR/html-markup/input.search.html
  @Experimental()
  static const EventStreamProvider<Event> searchEvent = const EventStreamProvider<Event>('search');

  /**
   * Static factory designed to expose `selectstart` events to event
   * handlers that are not necessarily instances of [Element].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('Element.selectstartEvent')
  @DocsEditable()
  @Experimental() // nonstandard
  static const EventStreamProvider<Event> selectStartEvent = const EventStreamProvider<Event>('selectstart');

  /**
   * Static factory designed to expose `fullscreenchange` events to event
   * handlers that are not necessarily instances of [Element].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('Element.webkitfullscreenchangeEvent')
  @DocsEditable()
  @SupportedBrowser(SupportedBrowser.CHROME)
  @SupportedBrowser(SupportedBrowser.SAFARI)
  @Experimental()
  // https://dvcs.w3.org/hg/fullscreen/raw-file/tip/Overview.html
  static const EventStreamProvider<Event> fullscreenChangeEvent = const EventStreamProvider<Event>('webkitfullscreenchange');

  /**
   * Static factory designed to expose `fullscreenerror` events to event
   * handlers that are not necessarily instances of [Element].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('Element.webkitfullscreenerrorEvent')
  @DocsEditable()
  @SupportedBrowser(SupportedBrowser.CHROME)
  @SupportedBrowser(SupportedBrowser.SAFARI)
  @Experimental()
  // https://dvcs.w3.org/hg/fullscreen/raw-file/tip/Overview.html
  static const EventStreamProvider<Event> fullscreenErrorEvent = const EventStreamProvider<Event>('webkitfullscreenerror');


  @Deprecated("Internal Use Only")
  static Element internalCreateElement() {
    return new Element.internal_();
  }

  @Deprecated("Internal Use Only")
  Element.internal_() : super.internal_();


  @DomName('Element.contentEditable')
  @DocsEditable()
  String get contentEditable => wrap_jso(JS("String", "#.contentEditable", this.raw));
  @DomName('Element.contentEditable')
  @DocsEditable()
  void set contentEditable(String val) => JS("void", "#.contentEditable = #", this.raw, unwrap_jso(val));

  @DomName('Element.contextMenu')
  @DocsEditable()
  @Experimental() // untriaged
  HtmlElement get contextMenu => wrap_jso(JS("HtmlElement", "#.contextMenu", this.raw));
  @DomName('Element.contextMenu')
  @DocsEditable()
  @Experimental() // untriaged
  void set contextMenu(HtmlElement val) => JS("void", "#.contextMenu = #", this.raw, unwrap_jso(val));

  @DomName('Element.dir')
  @DocsEditable()
  String get dir => wrap_jso(JS("String", "#.dir", this.raw));
  @DomName('Element.dir')
  @DocsEditable()
  void set dir(String val) => JS("void", "#.dir = #", this.raw, unwrap_jso(val));

  /**
   * Indicates whether the element can be dragged and dropped.
   *
   * ## Other resources
   *
   * * [Drag and drop sample]
   * (https://github.com/dart-lang/dart-samples/tree/master/web/html5/dnd/basics)
   * based on [the tutorial](http://www.html5rocks.com/en/tutorials/dnd/basics/)
   * from HTML5Rocks.
   * * [Drag and drop specification]
   * (http://www.whatwg.org/specs/web-apps/current-work/multipage/dnd.html#dnd)
   * from WHATWG.
   */
  @DomName('Element.draggable')
  @DocsEditable()
  bool get draggable => wrap_jso(JS("bool", "#.draggable", this.raw));
  /**
   * Indicates whether the element can be dragged and dropped.
   *
   * ## Other resources
   *
   * * [Drag and drop sample]
   * (https://github.com/dart-lang/dart-samples/tree/master/web/html5/dnd/basics)
   * based on [the tutorial](http://www.html5rocks.com/en/tutorials/dnd/basics/)
   * from HTML5Rocks.
   * * [Drag and drop specification]
   * (http://www.whatwg.org/specs/web-apps/current-work/multipage/dnd.html#dnd)
   * from WHATWG.
   */
  @DomName('Element.draggable')
  @DocsEditable()
  void set draggable(bool val) => JS("void", "#.draggable = #", this.raw, unwrap_jso(val));

  /**
   * Indicates whether the element is not relevant to the page's current state.
   *
   * ## Other resources
   *
   * * [Hidden attribute specification]
   * (http://www.whatwg.org/specs/web-apps/current-work/multipage/editing.html#the-hidden-attribute)
   * from WHATWG.
   */
  @DomName('Element.hidden')
  @DocsEditable()
  bool get hidden => wrap_jso(JS("bool", "#.hidden", this.raw));
  /**
   * Indicates whether the element is not relevant to the page's current state.
   *
   * ## Other resources
   *
   * * [Hidden attribute specification]
   * (http://www.whatwg.org/specs/web-apps/current-work/multipage/editing.html#the-hidden-attribute)
   * from WHATWG.
   */
  @DomName('Element.hidden')
  @DocsEditable()
  void set hidden(bool val) => JS("void", "#.hidden = #", this.raw, unwrap_jso(val));

  @DomName('Element.isContentEditable')
  @DocsEditable()
  bool get isContentEditable => wrap_jso(JS("bool", "#.isContentEditable", this.raw));

  @DomName('Element.lang')
  @DocsEditable()
  String get lang => wrap_jso(JS("String", "#.lang", this.raw));
  @DomName('Element.lang')
  @DocsEditable()
  void set lang(String val) => JS("void", "#.lang = #", this.raw, unwrap_jso(val));

  @DomName('Element.spellcheck')
  @DocsEditable()
  // http://blog.whatwg.org/the-road-to-html-5-spellchecking
  @Experimental() // nonstandard
  bool get spellcheck => wrap_jso(JS("bool", "#.spellcheck", this.raw));
  @DomName('Element.spellcheck')
  @DocsEditable()
  // http://blog.whatwg.org/the-road-to-html-5-spellchecking
  @Experimental() // nonstandard
  void set spellcheck(bool val) => JS("void", "#.spellcheck = #", this.raw, unwrap_jso(val));

  @DomName('Element.tabIndex')
  @DocsEditable()
  int get tabIndex => wrap_jso(JS("int", "#.tabIndex", this.raw));
  @DomName('Element.tabIndex')
  @DocsEditable()
  void set tabIndex(int val) => JS("void", "#.tabIndex = #", this.raw, unwrap_jso(val));

  @DomName('Element.title')
  @DocsEditable()
  String get title => wrap_jso(JS("String", "#.title", this.raw));
  @DomName('Element.title')
  @DocsEditable()
  void set title(String val) => JS("void", "#.title = #", this.raw, unwrap_jso(val));

  /**
   * Specifies whether this element's text content changes when the page is
   * localized.
   *
   * ## Other resources
   *
   * * [The translate attribute]
   * (http://www.whatwg.org/specs/web-apps/current-work/multipage/elements.html#the-translate-attribute)
   * from WHATWG.
   */
  @DomName('Element.translate')
  @DocsEditable()
  // http://www.whatwg.org/specs/web-apps/current-work/multipage/elements.html#the-translate-attribute
  @Experimental()
  bool get translate => wrap_jso(JS("bool", "#.translate", this.raw));
  /**
   * Specifies whether this element's text content changes when the page is
   * localized.
   *
   * ## Other resources
   *
   * * [The translate attribute]
   * (http://www.whatwg.org/specs/web-apps/current-work/multipage/elements.html#the-translate-attribute)
   * from WHATWG.
   */
  @DomName('Element.translate')
  @DocsEditable()
  // http://www.whatwg.org/specs/web-apps/current-work/multipage/elements.html#the-translate-attribute
  @Experimental()
  void set translate(bool val) => JS("void", "#.translate = #", this.raw, unwrap_jso(val));

  @JSName('webkitdropzone')
  /**
   * A set of space-separated keywords that specify what kind of data this
   * Element accepts on drop and what to do with that data.
   *
   * ## Other resources
   *
   * * [Drag and drop sample]
   * (https://github.com/dart-lang/dart-samples/tree/master/web/html5/dnd/basics)
   * based on [the tutorial](http://www.html5rocks.com/en/tutorials/dnd/basics/)
   * from HTML5Rocks.
   * * [Drag and drop specification]
   * (http://www.whatwg.org/specs/web-apps/current-work/multipage/dnd.html#dnd)
   * from WHATWG.
   */
  @DomName('Element.webkitdropzone')
  @DocsEditable()
  @SupportedBrowser(SupportedBrowser.CHROME)
  @SupportedBrowser(SupportedBrowser.SAFARI)
  @Experimental()
  // http://www.whatwg.org/specs/web-apps/current-work/multipage/dnd.html#the-dropzone-attribute
  String get dropzone => wrap_jso(JS("String", "#.webkitdropzone", this.raw));
  @JSName('webkitdropzone')
  /**
   * A set of space-separated keywords that specify what kind of data this
   * Element accepts on drop and what to do with that data.
   *
   * ## Other resources
   *
   * * [Drag and drop sample]
   * (https://github.com/dart-lang/dart-samples/tree/master/web/html5/dnd/basics)
   * based on [the tutorial](http://www.html5rocks.com/en/tutorials/dnd/basics/)
   * from HTML5Rocks.
   * * [Drag and drop specification]
   * (http://www.whatwg.org/specs/web-apps/current-work/multipage/dnd.html#dnd)
   * from WHATWG.
   */
  @DomName('Element.webkitdropzone')
  @DocsEditable()
  @SupportedBrowser(SupportedBrowser.CHROME)
  @SupportedBrowser(SupportedBrowser.SAFARI)
  @Experimental()
  // http://www.whatwg.org/specs/web-apps/current-work/multipage/dnd.html#the-dropzone-attribute
  void set dropzone(String val) => JS("void", "#.webkitdropzone = #", this.raw, unwrap_jso(val));

  @DomName('Element.click')
  @DocsEditable()
  void click() {
    _click_1();
    return;
  }
  @JSName('click')
  @DomName('Element.click')
  @DocsEditable()
  void _click_1() => wrap_jso(JS("void ", "#.raw.click()", this));

  @JSName('attributes')
  @DomName('Element.attributes')
  @DocsEditable()
  _NamedNodeMap get _attributes => wrap_jso(JS("_NamedNodeMap", "#.attributes", this.raw));

  @DomName('Element.className')
  @DocsEditable()
  String get className => wrap_jso(JS("String", "#.className", this.raw));
  @DomName('Element.className')
  @DocsEditable()
  void set className(String val) => JS("void", "#.className = #", this.raw, unwrap_jso(val));

  @JSName('clientHeight')
  @DomName('Element.clientHeight')
  @DocsEditable()
  int get _clientHeight => wrap_jso(JS("int", "#.clientHeight", this.raw));

  @JSName('clientLeft')
  @DomName('Element.clientLeft')
  @DocsEditable()
  int get _clientLeft => wrap_jso(JS("int", "#.clientLeft", this.raw));

  @JSName('clientTop')
  @DomName('Element.clientTop')
  @DocsEditable()
  int get _clientTop => wrap_jso(JS("int", "#.clientTop", this.raw));

  @JSName('clientWidth')
  @DomName('Element.clientWidth')
  @DocsEditable()
  int get _clientWidth => wrap_jso(JS("int", "#.clientWidth", this.raw));

  @DomName('Element.id')
  @DocsEditable()
  String get id => wrap_jso(JS("String", "#.id", this.raw));
  @DomName('Element.id')
  @DocsEditable()
  void set id(String val) => JS("void", "#.id = #", this.raw, unwrap_jso(val));

  @JSName('innerHTML')
  @DomName('Element.innerHTML')
  @DocsEditable()
  String get _innerHtml => wrap_jso(JS("String", "#.innerHTML", this.raw));
  @JSName('innerHTML')
  @DomName('Element.innerHTML')
  @DocsEditable()
  void set _innerHtml(String val) => JS("void", "#.innerHTML = #", this.raw, unwrap_jso(val));

  // Use implementation from Node.
  // final String _localName;

  // Use implementation from Node.
  // final String _namespaceUri;

  @JSName('offsetHeight')
  @DomName('Element.offsetHeight')
  @DocsEditable()
  int get _offsetHeight => wrap_jso(JS("int", "#.offsetHeight", this.raw));

  @JSName('offsetLeft')
  @DomName('Element.offsetLeft')
  @DocsEditable()
  int get _offsetLeft => wrap_jso(JS("int", "#.offsetLeft", this.raw));

  @DomName('Element.offsetParent')
  @DocsEditable()
  Element get offsetParent => wrap_jso(JS("Element", "#.offsetParent", this.raw));

  @JSName('offsetTop')
  @DomName('Element.offsetTop')
  @DocsEditable()
  int get _offsetTop => wrap_jso(JS("int", "#.offsetTop", this.raw));

  @JSName('offsetWidth')
  @DomName('Element.offsetWidth')
  @DocsEditable()
  int get _offsetWidth => wrap_jso(JS("int", "#.offsetWidth", this.raw));

  @JSName('outerHTML')
  @DomName('Element.outerHTML')
  @DocsEditable()
  String get outerHtml => wrap_jso(JS("String", "#.outerHTML", this.raw));

  @JSName('scrollHeight')
  @DomName('Element.scrollHeight')
  @DocsEditable()
  int get _scrollHeight => wrap_jso(JS("int", "#.scrollHeight", this.raw));

  @JSName('scrollLeft')
  @DomName('Element.scrollLeft')
  @DocsEditable()
  num get _scrollLeft => wrap_jso(JS("num", "#.scrollLeft", this.raw));
  @JSName('scrollLeft')
  @DomName('Element.scrollLeft')
  @DocsEditable()
  void set _scrollLeft(num val) => JS("void", "#.scrollLeft = #", this.raw, unwrap_jso(val));

  @JSName('scrollTop')
  @DomName('Element.scrollTop')
  @DocsEditable()
  num get _scrollTop => wrap_jso(JS("num", "#.scrollTop", this.raw));
  @JSName('scrollTop')
  @DomName('Element.scrollTop')
  @DocsEditable()
  void set _scrollTop(num val) => JS("void", "#.scrollTop = #", this.raw, unwrap_jso(val));

  @JSName('scrollWidth')
  @DomName('Element.scrollWidth')
  @DocsEditable()
  int get _scrollWidth => wrap_jso(JS("int", "#.scrollWidth", this.raw));

  @DomName('Element.style')
  @DocsEditable()
  CssStyleDeclaration get style => wrap_jso(JS("CssStyleDeclaration", "#.style", this.raw));

  @DomName('Element.tagName')
  @DocsEditable()
  String get tagName => wrap_jso(JS("String", "#.tagName", this.raw));

  @DomName('Element.blur')
  @DocsEditable()
  void blur() {
    _blur_1();
    return;
  }
  @JSName('blur')
  @DomName('Element.blur')
  @DocsEditable()
  void _blur_1() => wrap_jso(JS("void ", "#.raw.blur()", this));

  @DomName('Element.focus')
  @DocsEditable()
  void focus() {
    _focus_1();
    return;
  }
  @JSName('focus')
  @DomName('Element.focus')
  @DocsEditable()
  void _focus_1() => wrap_jso(JS("void ", "#.raw.focus()", this));

  @DomName('Element.getAttribute')
  @DocsEditable()
  @Experimental() // untriaged
  String getAttribute(String name) {
    return _getAttribute_1(name);
  }
  @JSName('getAttribute')
  @DomName('Element.getAttribute')
  @DocsEditable()
  @Experimental() // untriaged
  String _getAttribute_1(name) => wrap_jso(JS("String ", "#.raw.getAttribute(#)", this, unwrap_jso(name)));

  @DomName('Element.getAttributeNS')
  @DocsEditable()
  @Experimental() // untriaged
  String getAttributeNS(String namespaceURI, String localName) {
    return _getAttributeNS_1(namespaceURI, localName);
  }
  @JSName('getAttributeNS')
  @DomName('Element.getAttributeNS')
  @DocsEditable()
  @Experimental() // untriaged
  String _getAttributeNS_1(namespaceURI, localName) => wrap_jso(JS("String ", "#.raw.getAttributeNS(#, #)", this, unwrap_jso(namespaceURI), unwrap_jso(localName)));

  /**
   * Returns the smallest bounding rectangle that encompasses this element's
   * padding, scrollbar, and border.
   *
   * ## Other resources
   *
   * * [Element.getBoundingClientRect]
   * (https://developer.mozilla.org/en-US/docs/Web/API/Element.getBoundingClientRect)
   * from MDN.
   * * [The getBoundingClientRect() method]
   * (http://www.w3.org/TR/cssom-view/#the-getclientrects-and-getboundingclientrect-methods)
   * from W3C.
   */
  @DomName('Element.getBoundingClientRect')
  @DocsEditable()
  Rectangle getBoundingClientRect() {
    return _getBoundingClientRect_1();
  }
  @JSName('getBoundingClientRect')
  /**
   * Returns the smallest bounding rectangle that encompasses this element's
   * padding, scrollbar, and border.
   *
   * ## Other resources
   *
   * * [Element.getBoundingClientRect]
   * (https://developer.mozilla.org/en-US/docs/Web/API/Element.getBoundingClientRect)
   * from MDN.
   * * [The getBoundingClientRect() method]
   * (http://www.w3.org/TR/cssom-view/#the-getclientrects-and-getboundingclientrect-methods)
   * from W3C.
   */
  @DomName('Element.getBoundingClientRect')
  @DocsEditable()
  Rectangle _getBoundingClientRect_1() => wrap_jso(JS("Rectangle ", "#.raw.getBoundingClientRect()", this));

  /**
   * Returns a list of shadow DOM insertion points to which this element is
   * distributed.
   *
   * ## Other resources
   *
   * * [Shadow DOM specification]
   * (https://dvcs.w3.org/hg/webcomponents/raw-file/tip/spec/shadow/index.html)
   * from W3C.
   */
  @DomName('Element.getDestinationInsertionPoints')
  @DocsEditable()
  @Experimental() // untriaged
  @Returns('NodeList')
  @Creates('NodeList')
  NodeList getDestinationInsertionPoints() {
    return _getDestinationInsertionPoints_1();
  }
  @JSName('getDestinationInsertionPoints')
  /**
   * Returns a list of shadow DOM insertion points to which this element is
   * distributed.
   *
   * ## Other resources
   *
   * * [Shadow DOM specification]
   * (https://dvcs.w3.org/hg/webcomponents/raw-file/tip/spec/shadow/index.html)
   * from W3C.
   */
  @DomName('Element.getDestinationInsertionPoints')
  @DocsEditable()
  @Experimental() // untriaged
  @Returns('NodeList')
  @Creates('NodeList')
  NodeList _getDestinationInsertionPoints_1() => wrap_jso(JS("NodeList ", "#.raw.getDestinationInsertionPoints()", this));

  /**
   * Returns a list of nodes with the given class name inside this element.
   *
   * ## Other resources
   *
   * * [getElementsByClassName]
   * (https://developer.mozilla.org/en-US/docs/Web/API/document.getElementsByClassName)
   * from MDN.
   * * [DOM specification]
   * (http://www.w3.org/TR/domcore/) from W3C.
   */
  @DomName('Element.getElementsByClassName')
  @DocsEditable()
  @Creates('NodeList|HtmlCollection')
  @Returns('NodeList|HtmlCollection')
  HtmlCollection getElementsByClassName(String classNames) {
    return _getElementsByClassName_1(classNames);
  }
  @JSName('getElementsByClassName')
  /**
   * Returns a list of nodes with the given class name inside this element.
   *
   * ## Other resources
   *
   * * [getElementsByClassName]
   * (https://developer.mozilla.org/en-US/docs/Web/API/document.getElementsByClassName)
   * from MDN.
   * * [DOM specification]
   * (http://www.w3.org/TR/domcore/) from W3C.
   */
  @DomName('Element.getElementsByClassName')
  @DocsEditable()
  @Creates('NodeList|HtmlCollection')
  @Returns('NodeList|HtmlCollection')
  HtmlCollection _getElementsByClassName_1(classNames) => wrap_jso(JS("HtmlCollection ", "#.raw.getElementsByClassName(#)", this, unwrap_jso(classNames)));

  @DomName('Element.getElementsByTagName')
  @DocsEditable()
  @Creates('NodeList|HtmlCollection')
  @Returns('NodeList|HtmlCollection')
  HtmlCollection _getElementsByTagName(String name) {
    return _getElementsByTagName_1(name);
  }
  @JSName('getElementsByTagName')
  @DomName('Element.getElementsByTagName')
  @DocsEditable()
  @Creates('NodeList|HtmlCollection')
  @Returns('NodeList|HtmlCollection')
  HtmlCollection _getElementsByTagName_1(name) => wrap_jso(JS("HtmlCollection ", "#.raw.getElementsByTagName(#)", this, unwrap_jso(name)));

  @DomName('Element.hasAttribute')
  @DocsEditable()
  bool _hasAttribute(String name) {
    return _hasAttribute_1(name);
  }
  @JSName('hasAttribute')
  @DomName('Element.hasAttribute')
  @DocsEditable()
  bool _hasAttribute_1(name) => wrap_jso(JS("bool ", "#.raw.hasAttribute(#)", this, unwrap_jso(name)));

  @DomName('Element.hasAttributeNS')
  @DocsEditable()
  bool _hasAttributeNS(String namespaceURI, String localName) {
    return _hasAttributeNS_1(namespaceURI, localName);
  }
  @JSName('hasAttributeNS')
  @DomName('Element.hasAttributeNS')
  @DocsEditable()
  bool _hasAttributeNS_1(namespaceURI, localName) => wrap_jso(JS("bool ", "#.raw.hasAttributeNS(#, #)", this, unwrap_jso(namespaceURI), unwrap_jso(localName)));

  @DomName('Element.removeAttribute')
  @DocsEditable()
  void _removeAttribute(String name) {
    _removeAttribute_1(name);
    return;
  }
  @JSName('removeAttribute')
  @DomName('Element.removeAttribute')
  @DocsEditable()
  void _removeAttribute_1(name) => wrap_jso(JS("void ", "#.raw.removeAttribute(#)", this, unwrap_jso(name)));

  @DomName('Element.removeAttributeNS')
  @DocsEditable()
  void _removeAttributeNS(String namespaceURI, String localName) {
    _removeAttributeNS_1(namespaceURI, localName);
    return;
  }
  @JSName('removeAttributeNS')
  @DomName('Element.removeAttributeNS')
  @DocsEditable()
  void _removeAttributeNS_1(namespaceURI, localName) => wrap_jso(JS("void ", "#.raw.removeAttributeNS(#, #)", this, unwrap_jso(namespaceURI), unwrap_jso(localName)));

  @DomName('Element.requestFullscreen')
  @DocsEditable()
  @Experimental() // untriaged
  void requestFullscreen() {
    _requestFullscreen_1();
    return;
  }
  @JSName('requestFullscreen')
  @DomName('Element.requestFullscreen')
  @DocsEditable()
  @Experimental() // untriaged
  void _requestFullscreen_1() => wrap_jso(JS("void ", "#.raw.requestFullscreen()", this));

  @DomName('Element.requestPointerLock')
  @DocsEditable()
  @Experimental() // untriaged
  void requestPointerLock() {
    _requestPointerLock_1();
    return;
  }
  @JSName('requestPointerLock')
  @DomName('Element.requestPointerLock')
  @DocsEditable()
  @Experimental() // untriaged
  void _requestPointerLock_1() => wrap_jso(JS("void ", "#.raw.requestPointerLock()", this));

  @DomName('Element.scrollIntoView')
  @DocsEditable()
  void _scrollIntoView([bool alignWithTop]) {
    if (alignWithTop != null) {
      _scrollIntoView_1(alignWithTop);
      return;
    }
    _scrollIntoView_2();
    return;
  }
  @JSName('scrollIntoView')
  @DomName('Element.scrollIntoView')
  @DocsEditable()
  void _scrollIntoView_1(alignWithTop) => wrap_jso(JS("void ", "#.raw.scrollIntoView(#)", this, unwrap_jso(alignWithTop)));
  @JSName('scrollIntoView')
  @DomName('Element.scrollIntoView')
  @DocsEditable()
  void _scrollIntoView_2() => wrap_jso(JS("void ", "#.raw.scrollIntoView()", this));

  @DomName('Element.scrollIntoViewIfNeeded')
  @DocsEditable()
  // http://docs.webplatform.org/wiki/dom/methods/scrollIntoViewIfNeeded
  @Experimental() // non-standard
  void _scrollIntoViewIfNeeded([bool centerIfNeeded]) {
    if (centerIfNeeded != null) {
      _scrollIntoViewIfNeeded_1(centerIfNeeded);
      return;
    }
    _scrollIntoViewIfNeeded_2();
    return;
  }
  @JSName('scrollIntoViewIfNeeded')
  @DomName('Element.scrollIntoViewIfNeeded')
  @DocsEditable()
  // http://docs.webplatform.org/wiki/dom/methods/scrollIntoViewIfNeeded
  @Experimental() // non-standard
  void _scrollIntoViewIfNeeded_1(centerIfNeeded) => wrap_jso(JS("void ", "#.raw.scrollIntoViewIfNeeded(#)", this, unwrap_jso(centerIfNeeded)));
  @JSName('scrollIntoViewIfNeeded')
  @DomName('Element.scrollIntoViewIfNeeded')
  @DocsEditable()
  // http://docs.webplatform.org/wiki/dom/methods/scrollIntoViewIfNeeded
  @Experimental() // non-standard
  void _scrollIntoViewIfNeeded_2() => wrap_jso(JS("void ", "#.raw.scrollIntoViewIfNeeded()", this));

  @DomName('Element.setAttribute')
  @DocsEditable()
  void setAttribute(String name, String value) {
    _setAttribute_1(name, value);
    return;
  }
  @JSName('setAttribute')
  @DomName('Element.setAttribute')
  @DocsEditable()
  void _setAttribute_1(name, value) => wrap_jso(JS("void ", "#.raw.setAttribute(#, #)", this, unwrap_jso(name), unwrap_jso(value)));

  @DomName('Element.setAttributeNS')
  @DocsEditable()
  void setAttributeNS(String namespaceURI, String qualifiedName, String value) {
    _setAttributeNS_1(namespaceURI, qualifiedName, value);
    return;
  }
  @JSName('setAttributeNS')
  @DomName('Element.setAttributeNS')
  @DocsEditable()
  void _setAttributeNS_1(namespaceURI, qualifiedName, value) => wrap_jso(JS("void ", "#.raw.setAttributeNS(#, #, #)", this, unwrap_jso(namespaceURI), unwrap_jso(qualifiedName), unwrap_jso(value)));

  // From ChildNode

  @DomName('Element.nextElementSibling')
  @DocsEditable()
  Element get nextElementSibling => wrap_jso(JS("Element", "#.nextElementSibling", this.raw));

  @DomName('Element.previousElementSibling')
  @DocsEditable()
  Element get previousElementSibling => wrap_jso(JS("Element", "#.previousElementSibling", this.raw));

  // From ParentNode

  @JSName('childElementCount')
  @DomName('Element.childElementCount')
  @DocsEditable()
  int get _childElementCount => wrap_jso(JS("int", "#.childElementCount", this.raw));

  @JSName('children')
  @DomName('Element.children')
  @DocsEditable()
  @Returns('HtmlCollection')
  @Creates('HtmlCollection')
  List<Node> get _children => wrap_jso(JS("List<Node>", "#.children", this.raw));

  @JSName('firstElementChild')
  @DomName('Element.firstElementChild')
  @DocsEditable()
  Element get _firstElementChild => wrap_jso(JS("Element", "#.firstElementChild", this.raw));

  @JSName('lastElementChild')
  @DomName('Element.lastElementChild')
  @DocsEditable()
  Element get _lastElementChild => wrap_jso(JS("Element", "#.lastElementChild", this.raw));

  /**
   * Finds the first descendant element of this element that matches the
   * specified group of selectors.
   *
   * [selectors] should be a string using CSS selector syntax.
   *
   *     // Gets the first descendant with the class 'classname'
   *     var element = element.querySelector('.className');
   *     // Gets the element with id 'id'
   *     var element = element.querySelector('#id');
   *     // Gets the first descendant [ImageElement]
   *     var img = element.querySelector('img');
   *
   * For details about CSS selector syntax, see the
   * [CSS selector specification](http://www.w3.org/TR/css3-selectors/).
   */
  @DomName('Element.querySelector')
  @DocsEditable()
  Element querySelector(String selectors) {
    return _querySelector_1(selectors);
  }
  @JSName('querySelector')
  /**
   * Finds the first descendant element of this element that matches the
   * specified group of selectors.
   *
   * [selectors] should be a string using CSS selector syntax.
   *
   *     // Gets the first descendant with the class 'classname'
   *     var element = element.querySelector('.className');
   *     // Gets the element with id 'id'
   *     var element = element.querySelector('#id');
   *     // Gets the first descendant [ImageElement]
   *     var img = element.querySelector('img');
   *
   * For details about CSS selector syntax, see the
   * [CSS selector specification](http://www.w3.org/TR/css3-selectors/).
   */
  @DomName('Element.querySelector')
  @DocsEditable()
  Element _querySelector_1(selectors) => wrap_jso(JS("Element ", "#.raw.querySelector(#)", this, unwrap_jso(selectors)));

  @DomName('Element.querySelectorAll')
  @DocsEditable()
  @Returns('NodeList')
  @Creates('NodeList')
  NodeList _querySelectorAll(String selectors) {
    return _querySelectorAll_1(selectors);
  }
  @JSName('querySelectorAll')
  @DomName('Element.querySelectorAll')
  @DocsEditable()
  @Returns('NodeList')
  @Creates('NodeList')
  NodeList _querySelectorAll_1(selectors) => wrap_jso(JS("NodeList ", "#.raw.querySelectorAll(#)", this, unwrap_jso(selectors)));

  /// Stream of `beforecopy` events handled by this [Element].
  @DomName('Element.onbeforecopy')
  @DocsEditable()
  ElementStream<Event> get onBeforeCopy => beforeCopyEvent.forElement(this);

  /// Stream of `beforecut` events handled by this [Element].
  @DomName('Element.onbeforecut')
  @DocsEditable()
  ElementStream<Event> get onBeforeCut => beforeCutEvent.forElement(this);

  /// Stream of `beforepaste` events handled by this [Element].
  @DomName('Element.onbeforepaste')
  @DocsEditable()
  ElementStream<Event> get onBeforePaste => beforePasteEvent.forElement(this);

  /// Stream of `copy` events handled by this [Element].
  @DomName('Element.oncopy')
  @DocsEditable()
  ElementStream<Event> get onCopy => copyEvent.forElement(this);

  /// Stream of `cut` events handled by this [Element].
  @DomName('Element.oncut')
  @DocsEditable()
  ElementStream<Event> get onCut => cutEvent.forElement(this);

  /// Stream of `paste` events handled by this [Element].
  @DomName('Element.onpaste')
  @DocsEditable()
  ElementStream<Event> get onPaste => pasteEvent.forElement(this);

  /// Stream of `search` events handled by this [Element].
  @DomName('Element.onsearch')
  @DocsEditable()
  // http://www.w3.org/TR/html-markup/input.search.html
  @Experimental()
  ElementStream<Event> get onSearch => searchEvent.forElement(this);

  /// Stream of `selectstart` events handled by this [Element].
  @DomName('Element.onselectstart')
  @DocsEditable()
  @Experimental() // nonstandard
  ElementStream<Event> get onSelectStart => selectStartEvent.forElement(this);

  /// Stream of `fullscreenchange` events handled by this [Element].
  @DomName('Element.onwebkitfullscreenchange')
  @DocsEditable()
  // https://dvcs.w3.org/hg/fullscreen/raw-file/tip/Overview.html
  @Experimental()
  ElementStream<Event> get onFullscreenChange => fullscreenChangeEvent.forElement(this);

  /// Stream of `fullscreenerror` events handled by this [Element].
  @DomName('Element.onwebkitfullscreenerror')
  @DocsEditable()
  // https://dvcs.w3.org/hg/fullscreen/raw-file/tip/Overview.html
  @Experimental()
  ElementStream<Event> get onFullscreenError => fullscreenErrorEvent.forElement(this);

}


class _ElementFactoryProvider {

  @DomName('Document.createElement')
  static Element createElement_tag(String tag, String typeExtension) =>
      document.createElement(tag, typeExtension);
}


/**
 * Options for Element.scrollIntoView.
 */
class ScrollAlignment {
  final _value;
  const ScrollAlignment._internal(this._value);
  toString() => 'ScrollAlignment.$_value';

  /// Attempt to align the element to the top of the scrollable area.
  static const TOP = const ScrollAlignment._internal('TOP');
  /// Attempt to center the element in the scrollable area.
  static const CENTER = const ScrollAlignment._internal('CENTER');
  /// Attempt to align the element to the bottom of the scrollable area.
  static const BOTTOM = const ScrollAlignment._internal('BOTTOM');
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DomName('Event')
@Native("Event,InputEvent,ClipboardEvent")
class Event extends DartHtmlDomObject {
  // In JS, canBubble and cancelable are technically required parameters to
  // init*Event. In practice, though, if they aren't provided they simply
  // default to false (since that's Boolean(undefined)).
  //
  // Contrary to JS, we default canBubble and cancelable to true, since that's
  // what people want most of the time anyway.
  factory Event(String type,
      {bool canBubble: true, bool cancelable: true}) {
    return new Event.eventType('Event', type, canBubble: canBubble,
        cancelable: cancelable);
  }

  /**
   * Creates a new Event object of the specified type.
   *
   * This is analogous to document.createEvent.
   * Normally events should be created via their constructors, if available.
   *
   *     var e = new Event.type('MouseEvent', 'mousedown', true, true);
   */
  factory Event.eventType(String type, String name, {bool canBubble: true,
      bool cancelable: true}) {
    final Event e = document._createEvent(type);
    e._initEvent(name, canBubble, cancelable);
    return e;
  }

  /** The CSS selector involved with event delegation. */
  String _selector;

  /**
   * A pointer to the element whose CSS selector matched within which an event
   * was fired. If this Event was not associated with any Event delegation,
   * accessing this value will throw an [UnsupportedError].
   */
  Element get matchingTarget {
    if (_selector == null) {
      throw new UnsupportedError('Cannot call matchingTarget if this Event did'
          ' not arise as a result of event delegation.');
    }
    Element currentTarget = this.currentTarget;
    Element target = this.target;
    var matchedTarget;
    do {
      if (target.matches(_selector)) return target;
      target = target.parent;
    } while (target != null && target != currentTarget.parent);
    throw new StateError('No selector matched for populating matchedTarget.');
  }
  // To suppress missing implicit constructor warnings.
  factory Event._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static Event internalCreateEvent() {
    return new Event.internal_();
  }

  @Deprecated("Internal Use Only")
  Event.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

  /**
   * This event is being handled by the event target.
   *
   * ## Other resources
   *
   * * [Target phase] (http://www.w3.org/TR/DOM-Level-3-Events/#target-phase)
   * from W3C.
   */
  @DomName('Event.AT_TARGET')
  @DocsEditable()
  static const int AT_TARGET = 2;

  /**
   * This event is bubbling up through the target's ancestors.
   *
   * ## Other resources
   *
   * * [Bubble phase] (http://www.w3.org/TR/DOM-Level-3-Events/#bubble-phase)
   * from W3C.
   */
  @DomName('Event.BUBBLING_PHASE')
  @DocsEditable()
  static const int BUBBLING_PHASE = 3;

  /**
   * This event is propagating through the target's ancestors, starting from the
   * document.
   *
   * ## Other resources
   *
   * * [Bubble phase] (http://www.w3.org/TR/DOM-Level-3-Events/#bubble-phase)
   * from W3C.
   */
  @DomName('Event.CAPTURING_PHASE')
  @DocsEditable()
  static const int CAPTURING_PHASE = 1;

  @DomName('Event.bubbles')
  @DocsEditable()
  bool get bubbles => wrap_jso(JS("bool", "#.bubbles", this.raw));

  @DomName('Event.cancelable')
  @DocsEditable()
  bool get cancelable => wrap_jso(JS("bool", "#.cancelable", this.raw));

  @DomName('Event.currentTarget')
  @DocsEditable()
  EventTarget get currentTarget => _convertNativeToDart_EventTarget(this._get_currentTarget);
  @JSName('currentTarget')
  @DomName('Event.currentTarget')
  @DocsEditable()
  @Creates('Null')
  @Returns('EventTarget|=Object')
  dynamic get _get_currentTarget => wrap_jso(JS("dynamic", "#.currentTarget", this.raw));

  @DomName('Event.defaultPrevented')
  @DocsEditable()
  bool get defaultPrevented => wrap_jso(JS("bool", "#.defaultPrevented", this.raw));

  @DomName('Event.eventPhase')
  @DocsEditable()
  int get eventPhase => wrap_jso(JS("int", "#.eventPhase", this.raw));

  /**
   * This event's path, taking into account shadow DOM.
   *
   * ## Other resources
   *
   * * [Shadow DOM extensions to Event]
   * (http://w3c.github.io/webcomponents/spec/shadow/#extensions-to-event) from
   * W3C.
   */
  @DomName('Event.path')
  @DocsEditable()
  // https://dvcs.w3.org/hg/webcomponents/raw-file/tip/spec/shadow/index.html#extensions-to-event
  @Experimental()
  @Returns('NodeList')
  @Creates('NodeList')
  List<Node> get path => wrap_jso(JS("List<Node>", "#.path", this.raw));

  @DomName('Event.target')
  @DocsEditable()
  EventTarget get target => _convertNativeToDart_EventTarget(this._get_target);
  @JSName('target')
  @DomName('Event.target')
  @DocsEditable()
  @Creates('Node')
  @Returns('EventTarget|=Object')
  dynamic get _get_target => wrap_jso(JS("dynamic", "#.target", this.raw));

  @DomName('Event.timeStamp')
  @DocsEditable()
  int get timeStamp => wrap_jso(JS("int", "#.timeStamp", this.raw));

  @DomName('Event.type')
  @DocsEditable()
  String get type => wrap_jso(JS("String", "#.type", this.raw));

  @DomName('Event.initEvent')
  @DocsEditable()
  void _initEvent(String eventTypeArg, bool canBubbleArg, bool cancelableArg) {
    _initEvent_1(eventTypeArg, canBubbleArg, cancelableArg);
    return;
  }
  @JSName('initEvent')
  @DomName('Event.initEvent')
  @DocsEditable()
  void _initEvent_1(eventTypeArg, canBubbleArg, cancelableArg) => wrap_jso(JS("void ", "#.raw.initEvent(#, #, #)", this, unwrap_jso(eventTypeArg), unwrap_jso(canBubbleArg), unwrap_jso(cancelableArg)));

  @DomName('Event.preventDefault')
  @DocsEditable()
  void preventDefault() {
    _preventDefault_1();
    return;
  }
  @JSName('preventDefault')
  @DomName('Event.preventDefault')
  @DocsEditable()
  void _preventDefault_1() => wrap_jso(JS("void ", "#.raw.preventDefault()", this));

  @DomName('Event.stopImmediatePropagation')
  @DocsEditable()
  void stopImmediatePropagation() {
    _stopImmediatePropagation_1();
    return;
  }
  @JSName('stopImmediatePropagation')
  @DomName('Event.stopImmediatePropagation')
  @DocsEditable()
  void _stopImmediatePropagation_1() => wrap_jso(JS("void ", "#.raw.stopImmediatePropagation()", this));

  @DomName('Event.stopPropagation')
  @DocsEditable()
  void stopPropagation() {
    _stopPropagation_1();
    return;
  }
  @JSName('stopPropagation')
  @DomName('Event.stopPropagation')
  @DocsEditable()
  void _stopPropagation_1() => wrap_jso(JS("void ", "#.raw.stopPropagation()", this));

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * Base class that supports listening for and dispatching browser events.
 *
 * Normally events are accessed via the Stream getter:
 *
 *     element.onMouseOver.listen((e) => print('Mouse over!'));
 *
 * To access bubbling events which are declared on one element, but may bubble
 * up to another element type (common for MediaElement events):
 *
 *     MediaElement.pauseEvent.forTarget(document.body).listen(...);
 *
 * To useCapture on events:
 *
 *     Element.keyDownEvent.forTarget(element, useCapture: true).listen(...);
 *
 * Custom events can be declared as:
 *
 *     class DataGenerator {
 *       static EventStreamProvider<Event> dataEvent =
 *           new EventStreamProvider('data');
 *     }
 *
 * Then listeners should access the event with:
 *
 *     DataGenerator.dataEvent.forTarget(element).listen(...);
 *
 * Custom events can also be accessed as:
 *
 *     element.on['some_event'].listen(...);
 *
 * This approach is generally discouraged as it loses the event typing and
 * some DOM events may have multiple platform-dependent event names under the
 * covers. By using the standard Stream getters you will get the platform
 * specific event name automatically.
 */
class Events {
  /* Raw event target. */
  final EventTarget _ptr;

  Events(this._ptr);

  Stream operator [](String type) {
    return new _EventStream(_ptr, type, false);
  }
}

class ElementEvents extends Events {
  /* Raw event target. */
  static final webkitEvents = {
    'animationend' : 'webkitAnimationEnd',
    'animationiteration' : 'webkitAnimationIteration',
    'animationstart' : 'webkitAnimationStart',
    'fullscreenchange' : 'webkitfullscreenchange',
    'fullscreenerror' : 'webkitfullscreenerror',
    'keyadded' : 'webkitkeyadded',
    'keyerror' : 'webkitkeyerror',
    'keymessage' : 'webkitkeymessage',
    'needkey' : 'webkitneedkey',
    'pointerlockchange' : 'webkitpointerlockchange',
    'pointerlockerror' : 'webkitpointerlockerror',
    'resourcetimingbufferfull' : 'webkitresourcetimingbufferfull',
    'transitionend': 'webkitTransitionEnd',
    'speechchange' : 'webkitSpeechChange'
  };

  ElementEvents(Element ptr) : super(ptr);

  Stream operator [](String type) {
    if (webkitEvents.keys.contains(type.toLowerCase())) {
      if (Device.isWebKit) {
        return new _ElementEventStreamImpl(
            _ptr, webkitEvents[type.toLowerCase()], false);
      }
    }
    return new _ElementEventStreamImpl(_ptr, type, false);
  }
}

/**
 * Base class for all browser objects that support events.
 *
 * Use the [on] property to add, and remove events
 * for compile-time type checks and a more concise API.
 */
@DomName('EventTarget')
@Native("EventTarget")
class EventTarget extends DartHtmlDomObject {

  // Custom element created callback.
  EventTarget._created();

  /**
   * This is an ease-of-use accessor for event streams which should only be
   * used when an explicit accessor is not available.
   */
  Events get on => new Events(this);

  void addEventListener(String type, EventListener listener, [bool useCapture]) {
    // TODO(leafp): This check is avoid a bug in our dispatch code when
    // listener is null.  The browser treats this call as a no-op in this
    // case, so it's fine to short-circuit it, but we should not have to.
    if (listener != null) {
      _addEventListener(type, listener, useCapture);
    }
  }

  void removeEventListener(String type, EventListener listener, [bool useCapture]) {
    // TODO(leafp): This check is avoid a bug in our dispatch code when
    // listener is null.  The browser treats this call as a no-op in this
    // case, so it's fine to short-circuit it, but we should not have to.
    if (listener != null) {
      _removeEventListener(type, listener, useCapture);
    }
  }

  // To suppress missing implicit constructor warnings.
  factory EventTarget._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static EventTarget internalCreateEventTarget() {
    return new EventTarget.internal_();
  }

  @Deprecated("Internal Use Only")
  EventTarget.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

  @DomName('EventTarget.addEventListener')
  @DocsEditable()
  void _addEventListener([String type, EventListener listener, bool useCapture]) {
    if (useCapture != null) {
      _addEventListener_1(type, listener, useCapture);
      return;
    }
    if (listener != null) {
      _addEventListener_2(type, listener);
      return;
    }
    if (type != null) {
      _addEventListener_3(type);
      return;
    }
    _addEventListener_4();
    return;
  }
  @JSName('addEventListener')
  @DomName('EventTarget.addEventListener')
  @DocsEditable()
  void _addEventListener_1(type, EventListener listener, useCapture) => wrap_jso(JS("void ", "#.raw.addEventListener(#, #, #)", this, unwrap_jso(type), unwrap_jso(listener), unwrap_jso(useCapture)));
  @JSName('addEventListener')
  @DomName('EventTarget.addEventListener')
  @DocsEditable()
  void _addEventListener_2(type, EventListener listener) => wrap_jso(JS("void ", "#.raw.addEventListener(#, #)", this, unwrap_jso(type), unwrap_jso(listener)));
  @JSName('addEventListener')
  @DomName('EventTarget.addEventListener')
  @DocsEditable()
  void _addEventListener_3(type) => wrap_jso(JS("void ", "#.raw.addEventListener(#)", this, unwrap_jso(type)));
  @JSName('addEventListener')
  @DomName('EventTarget.addEventListener')
  @DocsEditable()
  void _addEventListener_4() => wrap_jso(JS("void ", "#.raw.addEventListener()", this));

  @DomName('EventTarget.dispatchEvent')
  @DocsEditable()
  bool dispatchEvent(Event event) {
    return _dispatchEvent_1(event);
  }
  @JSName('dispatchEvent')
  @DomName('EventTarget.dispatchEvent')
  @DocsEditable()
  bool _dispatchEvent_1(Event event) => wrap_jso(JS("bool ", "#.raw.dispatchEvent(#)", this, unwrap_jso(event)));

  @DomName('EventTarget.removeEventListener')
  @DocsEditable()
  void _removeEventListener([String type, EventListener listener, bool useCapture]) {
    if (useCapture != null) {
      _removeEventListener_1(type, listener, useCapture);
      return;
    }
    if (listener != null) {
      _removeEventListener_2(type, listener);
      return;
    }
    if (type != null) {
      _removeEventListener_3(type);
      return;
    }
    _removeEventListener_4();
    return;
  }
  @JSName('removeEventListener')
  @DomName('EventTarget.removeEventListener')
  @DocsEditable()
  void _removeEventListener_1(type, EventListener listener, useCapture) => wrap_jso(JS("void ", "#.raw.removeEventListener(#, #, #)", this, unwrap_jso(type), unwrap_jso(listener), unwrap_jso(useCapture)));
  @JSName('removeEventListener')
  @DomName('EventTarget.removeEventListener')
  @DocsEditable()
  void _removeEventListener_2(type, EventListener listener) => wrap_jso(JS("void ", "#.raw.removeEventListener(#, #)", this, unwrap_jso(type), unwrap_jso(listener)));
  @JSName('removeEventListener')
  @DomName('EventTarget.removeEventListener')
  @DocsEditable()
  void _removeEventListener_3(type) => wrap_jso(JS("void ", "#.raw.removeEventListener(#)", this, unwrap_jso(type)));
  @JSName('removeEventListener')
  @DomName('EventTarget.removeEventListener')
  @DocsEditable()
  void _removeEventListener_4() => wrap_jso(JS("void ", "#.raw.removeEventListener()", this));

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('HTMLHeadElement')
@Native("HTMLHeadElement")
class HeadElement extends HtmlElement {
  // To suppress missing implicit constructor warnings.
  factory HeadElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('HTMLHeadElement.HTMLHeadElement')
  @DocsEditable()
  factory HeadElement() => document.createElement("head");


  @Deprecated("Internal Use Only")
  static HeadElement internalCreateHeadElement() {
    return new HeadElement.internal_();
  }

  @Deprecated("Internal Use Only")
  HeadElement.internal_() : super.internal_();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('History')
@Native("History")
class History extends DartHtmlDomObject implements HistoryBase {

  /**
   * Checks if the State APIs are supported on the current platform.
   *
   * See also:
   *
   * * [pushState]
   * * [replaceState]
   * * [state]
   */
  static bool get supportsState => true;
  // To suppress missing implicit constructor warnings.
  factory History._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static History internalCreateHistory() {
    return new History.internal_();
  }

  @Deprecated("Internal Use Only")
  History.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

  @DomName('History.length')
  @DocsEditable()
  int get length => wrap_jso(JS("int", "#.length", this.raw));

  @DomName('History.state')
  @DocsEditable()
  dynamic get state => convertNativeToDart_SerializedScriptValue(this._get_state);
  @JSName('state')
  @DomName('History.state')
  @DocsEditable()
  @annotation_Creates_SerializedScriptValue
  @annotation_Returns_SerializedScriptValue
  dynamic get _get_state => wrap_jso(JS("dynamic", "#.state", this.raw));

  @DomName('History.back')
  @DocsEditable()
  void back() {
    _back_1();
    return;
  }
  @JSName('back')
  @DomName('History.back')
  @DocsEditable()
  void _back_1() => wrap_jso(JS("void ", "#.raw.back()", this));

  @DomName('History.forward')
  @DocsEditable()
  void forward() {
    _forward_1();
    return;
  }
  @JSName('forward')
  @DomName('History.forward')
  @DocsEditable()
  void _forward_1() => wrap_jso(JS("void ", "#.raw.forward()", this));

  @DomName('History.go')
  @DocsEditable()
  void go(int distance) {
    _go_1(distance);
    return;
  }
  @JSName('go')
  @DomName('History.go')
  @DocsEditable()
  void _go_1(distance) => wrap_jso(JS("void ", "#.raw.go(#)", this, unwrap_jso(distance)));

  @DomName('History.pushState')
  @DocsEditable()
  @SupportedBrowser(SupportedBrowser.CHROME)
  @SupportedBrowser(SupportedBrowser.FIREFOX)
  @SupportedBrowser(SupportedBrowser.IE, '10')
  @SupportedBrowser(SupportedBrowser.SAFARI)
  void pushState(/*any*/ data, String title, [String url]) {
    if (url != null) {
      var data_1 = convertDartToNative_SerializedScriptValue(data);
      _pushState_1(data_1, title, url);
      return;
    }
    var data_1 = convertDartToNative_SerializedScriptValue(data);
    _pushState_2(data_1, title);
    return;
  }
  @JSName('pushState')
  @DomName('History.pushState')
  @DocsEditable()
  @SupportedBrowser(SupportedBrowser.CHROME)
  @SupportedBrowser(SupportedBrowser.FIREFOX)
  @SupportedBrowser(SupportedBrowser.IE, '10')
  @SupportedBrowser(SupportedBrowser.SAFARI)
  void _pushState_1(data, title, url) => wrap_jso(JS("void ", "#.raw.pushState(#, #, #)", this, unwrap_jso(data), unwrap_jso(title), unwrap_jso(url)));
  @JSName('pushState')
  @DomName('History.pushState')
  @DocsEditable()
  @SupportedBrowser(SupportedBrowser.CHROME)
  @SupportedBrowser(SupportedBrowser.FIREFOX)
  @SupportedBrowser(SupportedBrowser.IE, '10')
  @SupportedBrowser(SupportedBrowser.SAFARI)
  void _pushState_2(data, title) => wrap_jso(JS("void ", "#.raw.pushState(#, #)", this, unwrap_jso(data), unwrap_jso(title)));

  @DomName('History.replaceState')
  @DocsEditable()
  @SupportedBrowser(SupportedBrowser.CHROME)
  @SupportedBrowser(SupportedBrowser.FIREFOX)
  @SupportedBrowser(SupportedBrowser.IE, '10')
  @SupportedBrowser(SupportedBrowser.SAFARI)
  void replaceState(/*any*/ data, String title, [String url]) {
    if (url != null) {
      var data_1 = convertDartToNative_SerializedScriptValue(data);
      _replaceState_1(data_1, title, url);
      return;
    }
    var data_1 = convertDartToNative_SerializedScriptValue(data);
    _replaceState_2(data_1, title);
    return;
  }
  @JSName('replaceState')
  @DomName('History.replaceState')
  @DocsEditable()
  @SupportedBrowser(SupportedBrowser.CHROME)
  @SupportedBrowser(SupportedBrowser.FIREFOX)
  @SupportedBrowser(SupportedBrowser.IE, '10')
  @SupportedBrowser(SupportedBrowser.SAFARI)
  void _replaceState_1(data, title, url) => wrap_jso(JS("void ", "#.raw.replaceState(#, #, #)", this, unwrap_jso(data), unwrap_jso(title), unwrap_jso(url)));
  @JSName('replaceState')
  @DomName('History.replaceState')
  @DocsEditable()
  @SupportedBrowser(SupportedBrowser.CHROME)
  @SupportedBrowser(SupportedBrowser.FIREFOX)
  @SupportedBrowser(SupportedBrowser.IE, '10')
  @SupportedBrowser(SupportedBrowser.SAFARI)
  void _replaceState_2(data, title) => wrap_jso(JS("void ", "#.raw.replaceState(#, #)", this, unwrap_jso(data), unwrap_jso(title)));
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('HTMLCollection')
@Native("HTMLCollection")
class HtmlCollection extends DartHtmlDomObject with ListMixin<Node>, ImmutableListMixin<Node> implements JavaScriptIndexingBehavior, List<Node> {
  // To suppress missing implicit constructor warnings.
  factory HtmlCollection._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static HtmlCollection internalCreateHtmlCollection() {
    return new HtmlCollection.internal_();
  }

  @Deprecated("Internal Use Only")
  HtmlCollection.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

  @DomName('HTMLCollection.length')
  @DocsEditable()
  int get length => wrap_jso(JS("int", "#.length", this.raw));

  Node operator[](int index) {
    if (JS("bool", "# >>> 0 !== # || # >= #", index,
        index, index, length))
      throw new RangeError.index(index, this);
    return wrap_jso(JS("Node", "#[#]", this.raw, index));
  }
  void operator[]=(int index, Node value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Node> mixins.
  // Node is the element type.


  set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  Node get first {
    if (this.length > 0) {
      return wrap_jso(JS('Node', '#[0]', this.raw));
    }
    throw new StateError("No elements");
  }

  Node get last {
    int len = this.length;
    if (len > 0) {
      return wrap_jso(JS('Node', '#[#]', this.raw, len - 1));
    }
    throw new StateError("No elements");
  }

  Node get single {
    int len = this.length;
    if (len == 1) {
      return wrap_jso(JS('Node', '#[0]', this.raw));
    }
    if (len == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  Node elementAt(int index) => this[index];
  // -- end List<Node> mixins.

  @DomName('HTMLCollection.item')
  @DocsEditable()
  Element item(int index) {
    return _item_1(index);
  }
  @JSName('item')
  @DomName('HTMLCollection.item')
  @DocsEditable()
  Element _item_1(index) => wrap_jso(JS("Element ", "#.raw.item(#)", this, unwrap_jso(index)));

  @DomName('HTMLCollection.namedItem')
  @DocsEditable()
  Element namedItem(String name) {
    return _namedItem_1(name);
  }
  @JSName('namedItem')
  @DomName('HTMLCollection.namedItem')
  @DocsEditable()
  Element _namedItem_1(name) => wrap_jso(JS("Element ", "#.raw.namedItem(#)", this, unwrap_jso(name)));
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DomName('HTMLDocument')
@Native("HTMLDocument")
class HtmlDocument extends Document {
  // To suppress missing implicit constructor warnings.
  factory HtmlDocument._() { throw new UnsupportedError("Not supported"); }


  @Deprecated("Internal Use Only")
  static HtmlDocument internalCreateHtmlDocument() {
    return new HtmlDocument.internal_();
  }

  @Deprecated("Internal Use Only")
  HtmlDocument.internal_() : super.internal_();



  @DomName('Document.body')
  BodyElement get body => _body;

  @DomName('Document.body')
  set body(BodyElement value) {
    _body = value;
  }

  @DomName('Document.caretRangeFromPoint')
  Range caretRangeFromPoint(int x, int y) {
    return _caretRangeFromPoint(x, y);
  }

  @DomName('Document.elementFromPoint')
  Element elementFromPoint(int x, int y) {
    return _elementFromPoint(x, y);
  }

  /**
   * Checks if the getCssCanvasContext API is supported on the current platform.
   *
   * See also:
   *
   * * [getCssCanvasContext]
   */
  static bool get supportsCssCanvasContext =>
      JS('bool', '!!(document.getCSSCanvasContext)');


  @DomName('Document.head')
  HeadElement get head => _head;

  @DomName('Document.lastModified')
  String get lastModified => _lastModified;

  @DomName('Document.preferredStylesheetSet')
  String get preferredStylesheetSet => _preferredStylesheetSet;

  @DomName('Document.referrer')
  String get referrer => _referrer;

  @DomName('Document.selectedStylesheetSet')
  String get selectedStylesheetSet => _selectedStylesheetSet;
  set selectedStylesheetSet(String value) {
    _selectedStylesheetSet = value;
  }


  @DomName('Document.title')
  String get title => _title;

  @DomName('Document.title')
  set title(String value) {
    _title = value;
  }

  /**
   * Returns page to standard layout.
   *
   * Has no effect if the page is not in fullscreen mode.
   *
   * ## Other resources
   *
   * * [Using the fullscreen API]
   * (http://docs.webplatform.org/wiki/tutorials/using_the_full-screen_api) from
   * WebPlatform.org.
   * * [Fullscreen specification]
   * (http://www.w3.org/TR/fullscreen/) from W3C.
   */
  @DomName('Document.webkitExitFullscreen')
  @SupportedBrowser(SupportedBrowser.CHROME)
  @SupportedBrowser(SupportedBrowser.SAFARI)
  @Experimental()
  void exitFullscreen() {
    _webkitExitFullscreen();
  }

  /**
   * Returns the element, if any, that is currently displayed in fullscreen.
   *
   * Returns null if there is currently no fullscreen element. You can use
   * this to determine if the page is in fullscreen mode.
   *
   *     myVideo = new VideoElement();
   *     if (document.fullscreenElement == null) {
   *       myVideo.requestFullscreen();
   *       print(document.fullscreenElement == myVideo); // true
   *     }
   *
   * ## Other resources
   *
   * * [Using the fullscreen API]
   * (http://docs.webplatform.org/wiki/tutorials/using_the_full-screen_api) from
   * WebPlatform.org.
   * * [Fullscreen specification]
   * (http://www.w3.org/TR/fullscreen/) from W3C.
   */
  @DomName('Document.webkitFullscreenElement')
  @SupportedBrowser(SupportedBrowser.CHROME)
  @SupportedBrowser(SupportedBrowser.SAFARI)
  @Experimental()
  Element get fullscreenElement => _webkitFullscreenElement;

  /**
   * Returns true if this document can display elements in fullscreen mode.
   *
   * ## Other resources
   *
   * * [Using the fullscreen API]
   * (http://docs.webplatform.org/wiki/tutorials/using_the_full-screen_api) from
   * WebPlatform.org.
   * * [Fullscreen specification]
   * (http://www.w3.org/TR/fullscreen/) from W3C.
   */
  @DomName('Document.webkitFullscreenEnabled')
  @SupportedBrowser(SupportedBrowser.CHROME)
  @SupportedBrowser(SupportedBrowser.SAFARI)
  @Experimental()
  bool get fullscreenEnabled => _webkitFullscreenEnabled;

  @DomName('Document.webkitHidden')
  @SupportedBrowser(SupportedBrowser.CHROME)
  @SupportedBrowser(SupportedBrowser.SAFARI)
  @Experimental()
  bool get hidden => _webkitHidden;

  @DomName('Document.visibilityState')
  @SupportedBrowser(SupportedBrowser.CHROME)
  @SupportedBrowser(SupportedBrowser.FIREFOX)
  @SupportedBrowser(SupportedBrowser.IE, '10')
  @Experimental()
  String get visibilityState => _webkitVisibilityState;

  @Experimental()
  /**
   * Register a custom subclass of Element to be instantiatable by the DOM.
   *
   * This is necessary to allow the construction of any custom elements.
   *
   * The class being registered must either subclass HtmlElement or SvgElement.
   * If they subclass these directly then they can be used as:
   *
   *     class FooElement extends HtmlElement{
   *        void created() {
   *          print('FooElement created!');
   *        }
   *     }
   *
   *     main() {
   *       document.registerElement('x-foo', FooElement);
   *       var myFoo = new Element.tag('x-foo');
   *       // prints 'FooElement created!' to the console.
   *     }
   *
   * The custom element can also be instantiated via HTML using the syntax
   * `<x-foo></x-foo>`
   *
   * Other elements can be subclassed as well:
   *
   *     class BarElement extends InputElement{
   *        void created() {
   *          print('BarElement created!');
   *        }
   *     }
   *
   *     main() {
   *       document.registerElement('x-bar', BarElement);
   *       var myBar = new Element.tag('input', 'x-bar');
   *       // prints 'BarElement created!' to the console.
   *     }
   *
   * This custom element can also be instantiated via HTML using the syntax
   * `<input is="x-bar"></input>`
   *
   */
  void registerElement(String tag, Type customElementClass,
      {String extendsTag}) {
    _registerCustomElement(JS('', 'window'), this, tag, customElementClass,
        extendsTag);
  }

  /** *Deprecated*: use [registerElement] instead. */
  @deprecated
  @Experimental()
  void register(String tag, Type customElementClass, {String extendsTag}) {
    return registerElement(tag, customElementClass, extendsTag: extendsTag);
  }

  /**
   * Static factory designed to expose `visibilitychange` events to event
   * handlers that are not necessarily instances of [Document].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('Document.visibilityChange')
  @SupportedBrowser(SupportedBrowser.CHROME)
  @SupportedBrowser(SupportedBrowser.FIREFOX)
  @SupportedBrowser(SupportedBrowser.IE, '10')
  @Experimental()
  static const EventStreamProvider<Event> visibilityChangeEvent =
      const _CustomEventStreamProvider<Event>(
        _determineVisibilityChangeEventType);

  static String _determineVisibilityChangeEventType(EventTarget e) {
    return 'webkitvisibilitychange';
  }

  @SupportedBrowser(SupportedBrowser.CHROME)
  @SupportedBrowser(SupportedBrowser.FIREFOX)
  @SupportedBrowser(SupportedBrowser.IE, '10')
  @Experimental()
  Stream<Event> get onVisibilityChange =>
      visibilityChangeEvent.forTarget(this);

  /// Creates an element upgrader which can be used to change the Dart wrapper
  /// type for elements.
  ///
  /// The type specified must be a subclass of HtmlElement, when an element is
  /// upgraded then the created constructor will be invoked on that element.
  ///
  /// If the type is not a direct subclass of HtmlElement then the extendsTag
  /// parameter must be provided.
  @Experimental()
  ElementUpgrader createElementUpgrader(Type type, {String extendsTag}) {
    throw 'ElementUpgrader not yet supported on DDC';
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('HTMLHtmlElement')
@Native("HTMLHtmlElement")
class HtmlHtmlElement extends HtmlElement {
  // To suppress missing implicit constructor warnings.
  factory HtmlHtmlElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('HTMLHtmlElement.HTMLHtmlElement')
  @DocsEditable()
  factory HtmlHtmlElement() => document.createElement("html");


  @Deprecated("Internal Use Only")
  static HtmlHtmlElement internalCreateHtmlHtmlElement() {
    return new HtmlHtmlElement.internal_();
  }

  @Deprecated("Internal Use Only")
  HtmlHtmlElement.internal_() : super.internal_();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


 /**
  * A client-side XHR request for getting data from a URL,
  * formally known as XMLHttpRequest.
  *
  * HttpRequest can be used to obtain data from HTTP and FTP protocols,
  * and is useful for AJAX-style page updates.
  *
  * The simplest way to get the contents of a text file, such as a
  * JSON-formatted file, is with [getString].
  * For example, the following code gets the contents of a JSON file
  * and prints its length:
  *
  *     var path = 'myData.json';
  *     HttpRequest.getString(path)
  *         .then((String fileContents) {
  *           print(fileContents.length);
  *         })
  *         .catchError((Error error) {
  *           print(error.toString());
  *         });
  *
  * ## Fetching data from other servers
  *
  * For security reasons, browsers impose restrictions on requests
  * made by embedded apps.
  * With the default behavior of this class,
  * the code making the request must be served from the same origin
  * (domain name, port, and application layer protocol)
  * as the requested resource.
  * In the example above, the myData.json file must be co-located with the
  * app that uses it.
  * You might be able to
  * [get around this restriction](http://www.dartlang.org/articles/json-web-service/#a-note-on-cors-and-httprequest)
  * by using CORS headers or JSONP.
  *
  * ## Other resources
  *
  * * [Fetch Data Dynamically](https://www.dartlang.org/docs/tutorials/fetchdata/),
  * a tutorial from _A Game of Darts_,
  * shows two different ways to use HttpRequest to get a JSON file.
  * * [Get Input from a Form](https://www.dartlang.org/docs/tutorials/forms/),
  * another tutorial from _A Game of Darts_,
  * shows using HttpRequest with a custom server.
  * * [Dart article on using HttpRequests](http://www.dartlang.org/articles/json-web-service/#getting-data)
  * * [JS XMLHttpRequest](https://developer.mozilla.org/en-US/docs/DOM/XMLHttpRequest)
  * * [Using XMLHttpRequest](https://developer.mozilla.org/en-US/docs/DOM/XMLHttpRequest/Using_XMLHttpRequest)
 */
@DomName('XMLHttpRequest')
@Native("XMLHttpRequest")
class HttpRequest extends HttpRequestEventTarget {

  /**
   * Creates a GET request for the specified [url].
   *
   * The server response must be a `text/` mime type for this request to
   * succeed.
   *
   * This is similar to [request] but specialized for HTTP GET requests which
   * return text content.
   *
   * To add query parameters, append them to the [url] following a `?`,
   * joining each key to its value with `=` and separating key-value pairs with
   * `&`.
   *
   *     var name = Uri.encodeQueryComponent('John');
   *     var id = Uri.encodeQueryComponent('42');
   *     HttpRequest.getString('users.json?name=$name&id=$id')
   *       .then((HttpRequest resp) {
   *         // Do something with the response.
   *     });
   *
   * See also:
   *
   * * [request]
   */
  static Future<String> getString(String url,
      {bool withCredentials, void onProgress(ProgressEvent e)}) {
    return request(url, withCredentials: withCredentials,
        onProgress: onProgress).then((HttpRequest xhr) => xhr.responseText);
  }

  /**
   * Makes a server POST request with the specified data encoded as form data.
   *
   * This is roughly the POST equivalent of getString. This method is similar
   * to sending a FormData object with broader browser support but limited to
   * String values.
   *
   * If [data] is supplied, the key/value pairs are URI encoded with
   * [Uri.encodeQueryComponent] and converted into an HTTP query string.
   *
   * Unless otherwise specified, this method appends the following header:
   *
   *     Content-Type: application/x-www-form-urlencoded; charset=UTF-8
   *
   * Here's an example of using this method:
   *
   *     var data = { 'firstName' : 'John', 'lastName' : 'Doe' };
   *     HttpRequest.postFormData('/send', data).then((HttpRequest resp) {
   *       // Do something with the response.
   *     });
   *
   * See also:
   *
   * * [request]
   */
  static Future<HttpRequest> postFormData(String url, Map<String, String> data,
      {bool withCredentials, String responseType,
      Map<String, String> requestHeaders,
      void onProgress(ProgressEvent e)}) {

    var parts = [];
    data.forEach((key, value) {
      parts.add('${Uri.encodeQueryComponent(key)}='
          '${Uri.encodeQueryComponent(value)}');
    });
    var formData = parts.join('&');

    if (requestHeaders == null) {
      requestHeaders = <String, String>{};
    }
    requestHeaders.putIfAbsent('Content-Type',
        () => 'application/x-www-form-urlencoded; charset=UTF-8');

    return request(url, method: 'POST', withCredentials: withCredentials,
        responseType: responseType,
        requestHeaders: requestHeaders, sendData: formData,
        onProgress: onProgress);
  }

  /**
   * Creates and sends a URL request for the specified [url].
   *
   * By default `request` will perform an HTTP GET request, but a different
   * method (`POST`, `PUT`, `DELETE`, etc) can be used by specifying the
   * [method] parameter. (See also [HttpRequest.postFormData] for `POST`
   * requests only.
   *
   * The Future is completed when the response is available.
   *
   * If specified, `sendData` will send data in the form of a [ByteBuffer],
   * [Blob], [Document], [String], or [FormData] along with the HttpRequest.
   *
   * If specified, [responseType] sets the desired response format for the
   * request. By default it is [String], but can also be 'arraybuffer', 'blob',
   * 'document', 'json', or 'text'. See also [HttpRequest.responseType]
   * for more information.
   *
   * The [withCredentials] parameter specified that credentials such as a cookie
   * (already) set in the header or
   * [authorization headers](http://tools.ietf.org/html/rfc1945#section-10.2)
   * should be specified for the request. Details to keep in mind when using
   * credentials:
   *
   * * Using credentials is only useful for cross-origin requests.
   * * The `Access-Control-Allow-Origin` header of `url` cannot contain a wildcard (*).
   * * The `Access-Control-Allow-Credentials` header of `url` must be set to true.
   * * If `Access-Control-Expose-Headers` has not been set to true, only a subset of all the response headers will be returned when calling [getAllRequestHeaders].
   *
   * The following is equivalent to the [getString] sample above:
   *
   *     var name = Uri.encodeQueryComponent('John');
   *     var id = Uri.encodeQueryComponent('42');
   *     HttpRequest.request('users.json?name=$name&id=$id')
   *       .then((HttpRequest resp) {
   *         // Do something with the response.
   *     });
   *
   * Here's an example of submitting an entire form with [FormData].
   *
   *     var myForm = querySelector('form#myForm');
   *     var data = new FormData(myForm);
   *     HttpRequest.request('/submit', method: 'POST', sendData: data)
   *       .then((HttpRequest resp) {
   *         // Do something with the response.
   *     });
   *
   * Note that requests for file:// URIs are only supported by Chrome extensions
   * with appropriate permissions in their manifest. Requests to file:// URIs
   * will also never fail- the Future will always complete successfully, even
   * when the file cannot be found.
   *
   * See also: [authorization headers](http://en.wikipedia.org/wiki/Basic_access_authentication).
   */
  static Future<HttpRequest> request(String url,
      {String method, bool withCredentials, String responseType,
      String mimeType, Map<String, String> requestHeaders, sendData,
      void onProgress(ProgressEvent e)}) {
    var completer = new Completer<HttpRequest>();

    var xhr = new HttpRequest();
    if (method == null) {
      method = 'GET';
    }
    xhr.open(method, url, async: true);

    if (withCredentials != null) {
      xhr.withCredentials = withCredentials;
    }

    if (responseType != null) {
      xhr.responseType = responseType;
    }

    if (mimeType != null) {
      xhr.overrideMimeType(mimeType);
    }

    if (requestHeaders != null) {
      requestHeaders.forEach((header, value) {
        xhr.setRequestHeader(header, value);
      });
    }

    if (onProgress != null) {
      xhr.onProgress.listen(onProgress);
    }

    xhr.onLoad.listen((e) {
      var accepted = xhr.status >= 200 && xhr.status < 300;
      var fileUri = xhr.status == 0; // file:// URIs have status of 0.
      var notModified = xhr.status == 304;
      // Redirect status is specified up to 307, but others have been used in
      // practice. Notably Google Drive uses 308 Resume Incomplete for
      // resumable uploads, and it's also been used as a redirect. The
      // redirect case will be handled by the browser before it gets to us,
      // so if we see it we should pass it through to the user.
      var unknownRedirect = xhr.status > 307 && xhr.status < 400;

      if (accepted || fileUri || notModified || unknownRedirect) {
        completer.complete(xhr);
      } else {
        completer.completeError(e);
      }
    });

    xhr.onError.listen(completer.completeError);

    if (sendData != null) {
      xhr.send(sendData);
    } else {
      xhr.send();
    }

    return completer.future;
  }

  /**
   * Checks to see if the Progress event is supported on the current platform.
   */
  static bool get supportsProgressEvent {
    return true;
  }

  /**
   * Checks to see if the current platform supports making cross origin
   * requests.
   *
   * Note that even if cross origin requests are supported, they still may fail
   * if the destination server does not support CORS requests.
   */
  static bool get supportsCrossOrigin {
    return true;
  }

  /**
   * Checks to see if the LoadEnd event is supported on the current platform.
   */
  static bool get supportsLoadEndEvent {
    return true;
  }

  /**
   * Checks to see if the overrideMimeType method is supported on the current
   * platform.
   */
  static bool get supportsOverrideMimeType {
    return true;
  }

  /**
   * Makes a cross-origin request to the specified URL.
   *
   * This API provides a subset of [request] which works on IE9. If IE9
   * cross-origin support is not required then [request] should be used instead.
   */
  @Experimental()
  static Future<String> requestCrossOrigin(String url,
      {String method, String sendData}) {
    if (supportsCrossOrigin) {
      return request(url, method: method, sendData: sendData).then((xhr) {
        return xhr.responseText;
      });
    }
  }

  /**
   * Returns all response headers as a key-value map.
   *
   * Multiple values for the same header key can be combined into one,
   * separated by a comma and a space.
   *
   * See: http://www.w3.org/TR/XMLHttpRequest/#the-getresponseheader()-method
   */
  Map<String, String> get responseHeaders {
    // from Closure's goog.net.Xhrio.getResponseHeaders.
    var headers = <String, String>{};
    var headersString = this.getAllResponseHeaders();
    if (headersString == null) {
      return headers;
    }
    var headersList = headersString.split('\r\n');
    for (var header in headersList) {
      if (header.isEmpty) {
        continue;
      }

      var splitIdx = header.indexOf(': ');
      if (splitIdx == -1) {
        continue;
      }
      var key = header.substring(0, splitIdx).toLowerCase();
      var value = header.substring(splitIdx + 2);
      if (headers.containsKey(key)) {
        headers[key] = '${headers[key]}, $value';
      } else {
        headers[key] = value;
      }
    }
    return headers;
  }

  /**
   * Specify the desired `url`, and `method` to use in making the request.
   *
   * By default the request is done asyncronously, with no user or password
   * authentication information. If `async` is false, the request will be send
   * synchronously.
   *
   * Calling `open` again on a currently active request is equivalent to
   * calling `abort`.
   *
   * Note: Most simple HTTP requests can be accomplished using the [getString],
   * [request], [requestCrossOrigin], or [postFormData] methods. Use of this
   * `open` method is intended only for more complext HTTP requests where
   * finer-grained control is needed.
   */
  @DomName('XMLHttpRequest.open')
  @DocsEditable()
  void open(String method, String url, {bool async, String user, String password}) {
    if (async == null && user == null && password == null) {
       JS('void', '#.open(#, #)', this.raw, method, url);
    } else {
       JS('void', '#.open(#, #, #, #, #)', this.raw, method, url, async, user, password);
    }
  }

  String get responseType => JS('String', '#.responseType', this.raw);
  void set responseType(String value) { JS('void', '#.responseType = #', this.raw, value); }

  // To suppress missing implicit constructor warnings.
  factory HttpRequest._() { throw new UnsupportedError("Not supported"); }

  /**
   * Static factory designed to expose `readystatechange` events to event
   * handlers that are not necessarily instances of [HttpRequest].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('XMLHttpRequest.readystatechangeEvent')
  @DocsEditable()
  static const EventStreamProvider<ProgressEvent> readyStateChangeEvent = const EventStreamProvider<ProgressEvent>('readystatechange');

  /**
   * General constructor for any type of request (GET, POST, etc).
   *
   * This call is used in conjunction with [open]:
   *
   *     var request = new HttpRequest();
   *     request.open('GET', 'http://dartlang.org');
   *     request.onLoad.listen((event) => print(
   *         'Request complete ${event.target.reponseText}'));
   *     request.send();
   *
   * is the (more verbose) equivalent of
   *
   *     HttpRequest.getString('http://dartlang.org').then(
   *         (result) => print('Request complete: $result'));
   */
  @DomName('XMLHttpRequest.XMLHttpRequest')
  @DocsEditable()
  factory HttpRequest() {
    return HttpRequest._create_1();
  }
  static HttpRequest _create_1() => wrap_jso(JS('HttpRequest', 'new XMLHttpRequest()'));


  @Deprecated("Internal Use Only")
  static HttpRequest internalCreateHttpRequest() {
    return new HttpRequest.internal_();
  }

  @Deprecated("Internal Use Only")
  HttpRequest.internal_() : super.internal_();


  @DomName('XMLHttpRequest.DONE')
  @DocsEditable()
  static const int DONE = 4;

  @DomName('XMLHttpRequest.HEADERS_RECEIVED')
  @DocsEditable()
  static const int HEADERS_RECEIVED = 2;

  @DomName('XMLHttpRequest.LOADING')
  @DocsEditable()
  static const int LOADING = 3;

  @DomName('XMLHttpRequest.OPENED')
  @DocsEditable()
  static const int OPENED = 1;

  @DomName('XMLHttpRequest.UNSENT')
  @DocsEditable()
  static const int UNSENT = 0;

  /**
   * Indicator of the current state of the request:
   *
   * <table>
   *   <tr>
   *     <td>Value</td>
   *     <td>State</td>
   *     <td>Meaning</td>
   *   </tr>
   *   <tr>
   *     <td>0</td>
   *     <td>unsent</td>
   *     <td><code>open()</code> has not yet been called</td>
   *   </tr>
   *   <tr>
   *     <td>1</td>
   *     <td>opened</td>
   *     <td><code>send()</code> has not yet been called</td>
   *   </tr>
   *   <tr>
   *     <td>2</td>
   *     <td>headers received</td>
   *     <td><code>sent()</code> has been called; response headers and <code>status</code> are available</td>
   *   </tr>
   *   <tr>
   *     <td>3</td> <td>loading</td> <td><code>responseText</code> holds some data</td>
   *   </tr>
   *   <tr>
   *     <td>4</td> <td>done</td> <td>request is complete</td>
   *   </tr>
   * </table>
   */
  @DomName('XMLHttpRequest.readyState')
  @DocsEditable()
  int get readyState => wrap_jso(JS("int", "#.readyState", this.raw));

  /**
   * The data received as a reponse from the request.
   *
   * The data could be in the
   * form of a [String], [ByteBuffer], [Document], [Blob], or json (also a
   * [String]). `null` indicates request failure.
   */
  @DomName('XMLHttpRequest.response')
  @DocsEditable()
  @SupportedBrowser(SupportedBrowser.CHROME)
  @SupportedBrowser(SupportedBrowser.FIREFOX)
  @SupportedBrowser(SupportedBrowser.IE, '10')
  @SupportedBrowser(SupportedBrowser.SAFARI)
  dynamic get response => _convertNativeToDart_XHR_Response(this._get_response);
  @JSName('response')
  /**
   * The data received as a reponse from the request.
   *
   * The data could be in the
   * form of a [String], [ByteBuffer], [Document], [Blob], or json (also a
   * [String]). `null` indicates request failure.
   */
  @DomName('XMLHttpRequest.response')
  @DocsEditable()
  @SupportedBrowser(SupportedBrowser.CHROME)
  @SupportedBrowser(SupportedBrowser.FIREFOX)
  @SupportedBrowser(SupportedBrowser.IE, '10')
  @SupportedBrowser(SupportedBrowser.SAFARI)
  @Creates('NativeByteBuffer|Blob|Document|=Object|JSExtendableArray|String|num')
  dynamic get _get_response => wrap_jso(JS("dynamic", "#.response", this.raw));

  /**
   * The response in String form or empty String on failure.
   */
  @DomName('XMLHttpRequest.responseText')
  @DocsEditable()
  String get responseText => wrap_jso(JS("String", "#.responseText", this.raw));

  @JSName('responseURL')
  @DomName('XMLHttpRequest.responseURL')
  @DocsEditable()
  @Experimental() // untriaged
  String get responseUrl => wrap_jso(JS("String", "#.responseURL", this.raw));

  @JSName('responseXML')
  /**
   * The request response, or null on failure.
   *
   * The response is processed as
   * `text/xml` stream, unless responseType = 'document' and the request is
   * synchronous.
   */
  @DomName('XMLHttpRequest.responseXML')
  @DocsEditable()
  Document get responseXml => wrap_jso(JS("Document", "#.responseXML", this.raw));

  /**
   * The http result code from the request (200, 404, etc).
   * See also: [Http Status Codes](http://en.wikipedia.org/wiki/List_of_HTTP_status_codes)
   */
  @DomName('XMLHttpRequest.status')
  @DocsEditable()
  int get status => wrap_jso(JS("int", "#.status", this.raw));

  /**
   * The request response string (such as \"200 OK\").
   * See also: [Http Status Codes](http://en.wikipedia.org/wiki/List_of_HTTP_status_codes)
   */
  @DomName('XMLHttpRequest.statusText')
  @DocsEditable()
  String get statusText => wrap_jso(JS("String", "#.statusText", this.raw));

  /**
   * Length of time before a request is automatically terminated.
   *
   * When the time has passed, a [TimeoutEvent] is dispatched.
   *
   * If [timeout] is set to 0, then the request will not time out.
   *
   * ## Other resources
   *
   * * [XMLHttpRequest.timeout]
   * (https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest#timeout)
   * from MDN.
   * * [The timeout attribute]
   * (http://www.w3.org/TR/XMLHttpRequest/#the-timeout-attribute)
   * from W3C.
   */
  @DomName('XMLHttpRequest.timeout')
  @DocsEditable()
  @Experimental() // untriaged
  int get timeout => wrap_jso(JS("int", "#.timeout", this.raw));
  /**
   * Length of time before a request is automatically terminated.
   *
   * When the time has passed, a [TimeoutEvent] is dispatched.
   *
   * If [timeout] is set to 0, then the request will not time out.
   *
   * ## Other resources
   *
   * * [XMLHttpRequest.timeout]
   * (https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest#timeout)
   * from MDN.
   * * [The timeout attribute]
   * (http://www.w3.org/TR/XMLHttpRequest/#the-timeout-attribute)
   * from W3C.
   */
  @DomName('XMLHttpRequest.timeout')
  @DocsEditable()
  @Experimental() // untriaged
  void set timeout(int val) => JS("void", "#.timeout = #", this.raw, unwrap_jso(val));

  /**
   * [EventTarget] that can hold listeners to track the progress of the request.
   * The events fired will be members of [HttpRequestUploadEvents].
   */
  @DomName('XMLHttpRequest.upload')
  @DocsEditable()
  @Unstable()
  HttpRequestEventTarget get upload => wrap_jso(JS("HttpRequestEventTarget", "#.upload", this.raw));

  /**
   * True if cross-site requests should use credentials such as cookies
   * or authorization headers; false otherwise.
   *
   * This value is ignored for same-site requests.
   */
  @DomName('XMLHttpRequest.withCredentials')
  @DocsEditable()
  bool get withCredentials => wrap_jso(JS("bool", "#.withCredentials", this.raw));
  /**
   * True if cross-site requests should use credentials such as cookies
   * or authorization headers; false otherwise.
   *
   * This value is ignored for same-site requests.
   */
  @DomName('XMLHttpRequest.withCredentials')
  @DocsEditable()
  void set withCredentials(bool val) => JS("void", "#.withCredentials = #", this.raw, unwrap_jso(val));

  /**
   * Stop the current request.
   *
   * The request can only be stopped if readyState is `HEADERS_RECIEVED` or
   * `LOADING`. If this method is not in the process of being sent, the method
   * has no effect.
   */
  @DomName('XMLHttpRequest.abort')
  @DocsEditable()
  void abort() {
    _abort_1();
    return;
  }
  @JSName('abort')
  /**
   * Stop the current request.
   *
   * The request can only be stopped if readyState is `HEADERS_RECIEVED` or
   * `LOADING`. If this method is not in the process of being sent, the method
   * has no effect.
   */
  @DomName('XMLHttpRequest.abort')
  @DocsEditable()
  void _abort_1() => wrap_jso(JS("void ", "#.raw.abort()", this));

  /**
   * Retrieve all the response headers from a request.
   *
   * `null` if no headers have been received. For multipart requests,
   * `getAllResponseHeaders` will return the response headers for the current
   * part of the request.
   *
   * See also [HTTP response headers](http://en.wikipedia.org/wiki/List_of_HTTP_header_fields#Responses)
   * for a list of common response headers.
   */
  @DomName('XMLHttpRequest.getAllResponseHeaders')
  @DocsEditable()
  @Unstable()
  String getAllResponseHeaders() {
    return _getAllResponseHeaders_1();
  }
  @JSName('getAllResponseHeaders')
  /**
   * Retrieve all the response headers from a request.
   *
   * `null` if no headers have been received. For multipart requests,
   * `getAllResponseHeaders` will return the response headers for the current
   * part of the request.
   *
   * See also [HTTP response headers](http://en.wikipedia.org/wiki/List_of_HTTP_header_fields#Responses)
   * for a list of common response headers.
   */
  @DomName('XMLHttpRequest.getAllResponseHeaders')
  @DocsEditable()
  @Unstable()
  String _getAllResponseHeaders_1() => wrap_jso(JS("String ", "#.raw.getAllResponseHeaders()", this));

  /**
   * Return the response header named `header`, or null if not found.
   *
   * See also [HTTP response headers](http://en.wikipedia.org/wiki/List_of_HTTP_header_fields#Responses)
   * for a list of common response headers.
   */
  @DomName('XMLHttpRequest.getResponseHeader')
  @DocsEditable()
  @Unstable()
  String getResponseHeader(String header) {
    return _getResponseHeader_1(header);
  }
  @JSName('getResponseHeader')
  /**
   * Return the response header named `header`, or null if not found.
   *
   * See also [HTTP response headers](http://en.wikipedia.org/wiki/List_of_HTTP_header_fields#Responses)
   * for a list of common response headers.
   */
  @DomName('XMLHttpRequest.getResponseHeader')
  @DocsEditable()
  @Unstable()
  String _getResponseHeader_1(header) => wrap_jso(JS("String ", "#.raw.getResponseHeader(#)", this, unwrap_jso(header)));

  /**
   * Specify a particular MIME type (such as `text/xml`) desired for the
   * response.
   *
   * This value must be set before the request has been sent. See also the list
   * of [common MIME types](http://en.wikipedia.org/wiki/Internet_media_type#List_of_common_media_types)
   */
  @DomName('XMLHttpRequest.overrideMimeType')
  @DocsEditable()
  @SupportedBrowser(SupportedBrowser.CHROME)
  @SupportedBrowser(SupportedBrowser.FIREFOX)
  @SupportedBrowser(SupportedBrowser.SAFARI)
  void overrideMimeType(String override) {
    _overrideMimeType_1(override);
    return;
  }
  @JSName('overrideMimeType')
  /**
   * Specify a particular MIME type (such as `text/xml`) desired for the
   * response.
   *
   * This value must be set before the request has been sent. See also the list
   * of [common MIME types](http://en.wikipedia.org/wiki/Internet_media_type#List_of_common_media_types)
   */
  @DomName('XMLHttpRequest.overrideMimeType')
  @DocsEditable()
  @SupportedBrowser(SupportedBrowser.CHROME)
  @SupportedBrowser(SupportedBrowser.FIREFOX)
  @SupportedBrowser(SupportedBrowser.SAFARI)
  void _overrideMimeType_1(override) => wrap_jso(JS("void ", "#.raw.overrideMimeType(#)", this, unwrap_jso(override)));

  /**
   * Send the request with any given `data`.
   *
   * Note: Most simple HTTP requests can be accomplished using the [getString],
   * [request], [requestCrossOrigin], or [postFormData] methods. Use of this
   * `send` method is intended only for more complext HTTP requests where
   * finer-grained control is needed.
   *
   * ## Other resources
   *
   * * [XMLHttpRequest.send]
   * (https://developer.mozilla.org/en-US/docs/DOM/XMLHttpRequest#send%28%29)
   * from MDN.
   */
  @DomName('XMLHttpRequest.send')
  @DocsEditable()
  void send([data]) {
    if (data == null) {
      _send_1();
      return;
    }
    if ((data is Document || data == null)) {
      _send_2(data);
      return;
    }
    if ((data is String || data == null)) {
      _send_3(data);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }
  @JSName('send')
  /**
   * Send the request with any given `data`.
   *
   * Note: Most simple HTTP requests can be accomplished using the [getString],
   * [request], [requestCrossOrigin], or [postFormData] methods. Use of this
   * `send` method is intended only for more complext HTTP requests where
   * finer-grained control is needed.
   *
   * ## Other resources
   *
   * * [XMLHttpRequest.send]
   * (https://developer.mozilla.org/en-US/docs/DOM/XMLHttpRequest#send%28%29)
   * from MDN.
   */
  @DomName('XMLHttpRequest.send')
  @DocsEditable()
  void _send_1() => wrap_jso(JS("void ", "#.raw.send()", this));
  @JSName('send')
  /**
   * Send the request with any given `data`.
   *
   * Note: Most simple HTTP requests can be accomplished using the [getString],
   * [request], [requestCrossOrigin], or [postFormData] methods. Use of this
   * `send` method is intended only for more complext HTTP requests where
   * finer-grained control is needed.
   *
   * ## Other resources
   *
   * * [XMLHttpRequest.send]
   * (https://developer.mozilla.org/en-US/docs/DOM/XMLHttpRequest#send%28%29)
   * from MDN.
   */
  @DomName('XMLHttpRequest.send')
  @DocsEditable()
  void _send_2(Document data) => wrap_jso(JS("void ", "#.raw.send(#)", this, unwrap_jso(data)));
  @JSName('send')
  /**
   * Send the request with any given `data`.
   *
   * Note: Most simple HTTP requests can be accomplished using the [getString],
   * [request], [requestCrossOrigin], or [postFormData] methods. Use of this
   * `send` method is intended only for more complext HTTP requests where
   * finer-grained control is needed.
   *
   * ## Other resources
   *
   * * [XMLHttpRequest.send]
   * (https://developer.mozilla.org/en-US/docs/DOM/XMLHttpRequest#send%28%29)
   * from MDN.
   */
  @DomName('XMLHttpRequest.send')
  @DocsEditable()
  void _send_3(String data) => wrap_jso(JS("void ", "#.raw.send(#)", this, unwrap_jso(data)));

  /**
   * Sets the value of an HTTP requst header.
   *
   * This method should be called after the request is opened, but before
   * the request is sent.
   *
   * Multiple calls with the same header will combine all their values into a
   * single header.
   *
   * ## Other resources
   *
   * * [XMLHttpRequest.setRequestHeader]
   * (https://developer.mozilla.org/en-US/docs/DOM/XMLHttpRequest#send%28%29)
   * from MDN.
   * * [The setRequestHeader() method]
   * (http://www.w3.org/TR/XMLHttpRequest/#the-setrequestheader()-method) from
   * W3C.
   */
  @DomName('XMLHttpRequest.setRequestHeader')
  @DocsEditable()
  void setRequestHeader(String header, String value) {
    _setRequestHeader_1(header, value);
    return;
  }
  @JSName('setRequestHeader')
  /**
   * Sets the value of an HTTP requst header.
   *
   * This method should be called after the request is opened, but before
   * the request is sent.
   *
   * Multiple calls with the same header will combine all their values into a
   * single header.
   *
   * ## Other resources
   *
   * * [XMLHttpRequest.setRequestHeader]
   * (https://developer.mozilla.org/en-US/docs/DOM/XMLHttpRequest#send%28%29)
   * from MDN.
   * * [The setRequestHeader() method]
   * (http://www.w3.org/TR/XMLHttpRequest/#the-setrequestheader()-method) from
   * W3C.
   */
  @DomName('XMLHttpRequest.setRequestHeader')
  @DocsEditable()
  void _setRequestHeader_1(header, value) => wrap_jso(JS("void ", "#.raw.setRequestHeader(#, #)", this, unwrap_jso(header), unwrap_jso(value)));

  /// Stream of `readystatechange` events handled by this [HttpRequest].
/**
   * Event listeners to be notified every time the [HttpRequest]
   * object's `readyState` changes values.
   */
  @DomName('XMLHttpRequest.onreadystatechange')
  @DocsEditable()
  Stream<ProgressEvent> get onReadyStateChange => readyStateChangeEvent.forTarget(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('XMLHttpRequestEventTarget')
@Experimental() // untriaged
@Native("XMLHttpRequestEventTarget")
class HttpRequestEventTarget extends EventTarget {
  // To suppress missing implicit constructor warnings.
  factory HttpRequestEventTarget._() { throw new UnsupportedError("Not supported"); }

  /**
   * Static factory designed to expose `abort` events to event
   * handlers that are not necessarily instances of [HttpRequestEventTarget].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('XMLHttpRequestEventTarget.abortEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<ProgressEvent> abortEvent = const EventStreamProvider<ProgressEvent>('abort');

  /**
   * Static factory designed to expose `error` events to event
   * handlers that are not necessarily instances of [HttpRequestEventTarget].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('XMLHttpRequestEventTarget.errorEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<ProgressEvent> errorEvent = const EventStreamProvider<ProgressEvent>('error');

  /**
   * Static factory designed to expose `load` events to event
   * handlers that are not necessarily instances of [HttpRequestEventTarget].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('XMLHttpRequestEventTarget.loadEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<ProgressEvent> loadEvent = const EventStreamProvider<ProgressEvent>('load');

  /**
   * Static factory designed to expose `loadend` events to event
   * handlers that are not necessarily instances of [HttpRequestEventTarget].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('XMLHttpRequestEventTarget.loadendEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<ProgressEvent> loadEndEvent = const EventStreamProvider<ProgressEvent>('loadend');

  /**
   * Static factory designed to expose `loadstart` events to event
   * handlers that are not necessarily instances of [HttpRequestEventTarget].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('XMLHttpRequestEventTarget.loadstartEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<ProgressEvent> loadStartEvent = const EventStreamProvider<ProgressEvent>('loadstart');

  /**
   * Static factory designed to expose `progress` events to event
   * handlers that are not necessarily instances of [HttpRequestEventTarget].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('XMLHttpRequestEventTarget.progressEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<ProgressEvent> progressEvent = const EventStreamProvider<ProgressEvent>('progress');

  /**
   * Static factory designed to expose `timeout` events to event
   * handlers that are not necessarily instances of [HttpRequestEventTarget].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('XMLHttpRequestEventTarget.timeoutEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<ProgressEvent> timeoutEvent = const EventStreamProvider<ProgressEvent>('timeout');


  @Deprecated("Internal Use Only")
  static HttpRequestEventTarget internalCreateHttpRequestEventTarget() {
    return new HttpRequestEventTarget.internal_();
  }

  @Deprecated("Internal Use Only")
  HttpRequestEventTarget.internal_() : super.internal_();


  /// Stream of `abort` events handled by this [HttpRequestEventTarget].
  @DomName('XMLHttpRequestEventTarget.onabort')
  @DocsEditable()
  @Experimental() // untriaged
  Stream<ProgressEvent> get onAbort => abortEvent.forTarget(this);

  /// Stream of `error` events handled by this [HttpRequestEventTarget].
  @DomName('XMLHttpRequestEventTarget.onerror')
  @DocsEditable()
  @Experimental() // untriaged
  Stream<ProgressEvent> get onError => errorEvent.forTarget(this);

  /// Stream of `load` events handled by this [HttpRequestEventTarget].
  @DomName('XMLHttpRequestEventTarget.onload')
  @DocsEditable()
  @Experimental() // untriaged
  Stream<ProgressEvent> get onLoad => loadEvent.forTarget(this);

  /// Stream of `loadend` events handled by this [HttpRequestEventTarget].
  @DomName('XMLHttpRequestEventTarget.onloadend')
  @DocsEditable()
  @SupportedBrowser(SupportedBrowser.CHROME)
  @SupportedBrowser(SupportedBrowser.FIREFOX)
  @SupportedBrowser(SupportedBrowser.IE, '10')
  @SupportedBrowser(SupportedBrowser.SAFARI)
  @Experimental() // untriaged
  Stream<ProgressEvent> get onLoadEnd => loadEndEvent.forTarget(this);

  /// Stream of `loadstart` events handled by this [HttpRequestEventTarget].
  @DomName('XMLHttpRequestEventTarget.onloadstart')
  @DocsEditable()
  @Experimental() // untriaged
  Stream<ProgressEvent> get onLoadStart => loadStartEvent.forTarget(this);

  /// Stream of `progress` events handled by this [HttpRequestEventTarget].
  @DomName('XMLHttpRequestEventTarget.onprogress')
  @DocsEditable()
  @SupportedBrowser(SupportedBrowser.CHROME)
  @SupportedBrowser(SupportedBrowser.FIREFOX)
  @SupportedBrowser(SupportedBrowser.IE, '10')
  @SupportedBrowser(SupportedBrowser.SAFARI)
  @Experimental() // untriaged
  Stream<ProgressEvent> get onProgress => progressEvent.forTarget(this);

  /// Stream of `timeout` events handled by this [HttpRequestEventTarget].
  @DomName('XMLHttpRequestEventTarget.ontimeout')
  @DocsEditable()
  @Experimental() // untriaged
  Stream<ProgressEvent> get onTimeout => timeoutEvent.forTarget(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('HTMLInputElement')
@Native("HTMLInputElement")
class InputElement extends HtmlElement implements
    HiddenInputElement,
    SearchInputElement,
    TextInputElement,
    UrlInputElement,
    TelephoneInputElement,
    EmailInputElement,
    PasswordInputElement,
    DateInputElement,
    MonthInputElement,
    WeekInputElement,
    TimeInputElement,
    LocalDateTimeInputElement,
    NumberInputElement,
    RangeInputElement,
    CheckboxInputElement,
    RadioButtonInputElement,
    FileUploadInputElement,
    SubmitButtonInputElement,
    ImageButtonInputElement,
    ResetButtonInputElement,
    ButtonInputElement {

  factory InputElement({String type}) {
    InputElement e = document.createElement("input");
    if (type != null) {
      try {
        // IE throws an exception for unknown types.
        e.type = type;
      } catch(_) {}
    }
    return e;
  }

  // To suppress missing implicit constructor warnings.
  factory InputElement._() { throw new UnsupportedError("Not supported"); }


  @Deprecated("Internal Use Only")
  static InputElement internalCreateInputElement() {
    return new InputElement.internal_();
  }

  @Deprecated("Internal Use Only")
  InputElement.internal_() : super.internal_();


  @DomName('HTMLInputElement.accept')
  @DocsEditable()
  String get accept => wrap_jso(JS("String", "#.accept", this.raw));
  @DomName('HTMLInputElement.accept')
  @DocsEditable()
  void set accept(String val) => JS("void", "#.accept = #", this.raw, unwrap_jso(val));

  @DomName('HTMLInputElement.alt')
  @DocsEditable()
  String get alt => wrap_jso(JS("String", "#.alt", this.raw));
  @DomName('HTMLInputElement.alt')
  @DocsEditable()
  void set alt(String val) => JS("void", "#.alt = #", this.raw, unwrap_jso(val));

  @DomName('HTMLInputElement.autocomplete')
  @DocsEditable()
  String get autocomplete => wrap_jso(JS("String", "#.autocomplete", this.raw));
  @DomName('HTMLInputElement.autocomplete')
  @DocsEditable()
  void set autocomplete(String val) => JS("void", "#.autocomplete = #", this.raw, unwrap_jso(val));

  @DomName('HTMLInputElement.autofocus')
  @DocsEditable()
  bool get autofocus => wrap_jso(JS("bool", "#.autofocus", this.raw));
  @DomName('HTMLInputElement.autofocus')
  @DocsEditable()
  void set autofocus(bool val) => JS("void", "#.autofocus = #", this.raw, unwrap_jso(val));

  @DomName('HTMLInputElement.capture')
  @DocsEditable()
  @Experimental() // untriaged
  bool get capture => wrap_jso(JS("bool", "#.capture", this.raw));
  @DomName('HTMLInputElement.capture')
  @DocsEditable()
  @Experimental() // untriaged
  void set capture(bool val) => JS("void", "#.capture = #", this.raw, unwrap_jso(val));

  @DomName('HTMLInputElement.checked')
  @DocsEditable()
  bool get checked => wrap_jso(JS("bool", "#.checked", this.raw));
  @DomName('HTMLInputElement.checked')
  @DocsEditable()
  void set checked(bool val) => JS("void", "#.checked = #", this.raw, unwrap_jso(val));

  @DomName('HTMLInputElement.defaultChecked')
  @DocsEditable()
  bool get defaultChecked => wrap_jso(JS("bool", "#.defaultChecked", this.raw));
  @DomName('HTMLInputElement.defaultChecked')
  @DocsEditable()
  void set defaultChecked(bool val) => JS("void", "#.defaultChecked = #", this.raw, unwrap_jso(val));

  @DomName('HTMLInputElement.defaultValue')
  @DocsEditable()
  String get defaultValue => wrap_jso(JS("String", "#.defaultValue", this.raw));
  @DomName('HTMLInputElement.defaultValue')
  @DocsEditable()
  void set defaultValue(String val) => JS("void", "#.defaultValue = #", this.raw, unwrap_jso(val));

  @DomName('HTMLInputElement.dirName')
  @DocsEditable()
  String get dirName => wrap_jso(JS("String", "#.dirName", this.raw));
  @DomName('HTMLInputElement.dirName')
  @DocsEditable()
  void set dirName(String val) => JS("void", "#.dirName = #", this.raw, unwrap_jso(val));

  @DomName('HTMLInputElement.disabled')
  @DocsEditable()
  bool get disabled => wrap_jso(JS("bool", "#.disabled", this.raw));
  @DomName('HTMLInputElement.disabled')
  @DocsEditable()
  void set disabled(bool val) => JS("void", "#.disabled = #", this.raw, unwrap_jso(val));

  @DomName('HTMLInputElement.form')
  @DocsEditable()
  HtmlElement get form => wrap_jso(JS("HtmlElement", "#.form", this.raw));

  @DomName('HTMLInputElement.formAction')
  @DocsEditable()
  String get formAction => wrap_jso(JS("String", "#.formAction", this.raw));
  @DomName('HTMLInputElement.formAction')
  @DocsEditable()
  void set formAction(String val) => JS("void", "#.formAction = #", this.raw, unwrap_jso(val));

  @DomName('HTMLInputElement.formEnctype')
  @DocsEditable()
  String get formEnctype => wrap_jso(JS("String", "#.formEnctype", this.raw));
  @DomName('HTMLInputElement.formEnctype')
  @DocsEditable()
  void set formEnctype(String val) => JS("void", "#.formEnctype = #", this.raw, unwrap_jso(val));

  @DomName('HTMLInputElement.formMethod')
  @DocsEditable()
  String get formMethod => wrap_jso(JS("String", "#.formMethod", this.raw));
  @DomName('HTMLInputElement.formMethod')
  @DocsEditable()
  void set formMethod(String val) => JS("void", "#.formMethod = #", this.raw, unwrap_jso(val));

  @DomName('HTMLInputElement.formNoValidate')
  @DocsEditable()
  bool get formNoValidate => wrap_jso(JS("bool", "#.formNoValidate", this.raw));
  @DomName('HTMLInputElement.formNoValidate')
  @DocsEditable()
  void set formNoValidate(bool val) => JS("void", "#.formNoValidate = #", this.raw, unwrap_jso(val));

  @DomName('HTMLInputElement.formTarget')
  @DocsEditable()
  String get formTarget => wrap_jso(JS("String", "#.formTarget", this.raw));
  @DomName('HTMLInputElement.formTarget')
  @DocsEditable()
  void set formTarget(String val) => JS("void", "#.formTarget = #", this.raw, unwrap_jso(val));

  @DomName('HTMLInputElement.height')
  @DocsEditable()
  int get height => wrap_jso(JS("int", "#.height", this.raw));
  @DomName('HTMLInputElement.height')
  @DocsEditable()
  void set height(int val) => JS("void", "#.height = #", this.raw, unwrap_jso(val));

  @DomName('HTMLInputElement.incremental')
  @DocsEditable()
  // http://www.w3.org/TR/html-markup/input.search.html
  @Experimental()
  bool get incremental => wrap_jso(JS("bool", "#.incremental", this.raw));
  @DomName('HTMLInputElement.incremental')
  @DocsEditable()
  // http://www.w3.org/TR/html-markup/input.search.html
  @Experimental()
  void set incremental(bool val) => JS("void", "#.incremental = #", this.raw, unwrap_jso(val));

  @DomName('HTMLInputElement.indeterminate')
  @DocsEditable()
  bool get indeterminate => wrap_jso(JS("bool", "#.indeterminate", this.raw));
  @DomName('HTMLInputElement.indeterminate')
  @DocsEditable()
  void set indeterminate(bool val) => JS("void", "#.indeterminate = #", this.raw, unwrap_jso(val));

  @DomName('HTMLInputElement.inputMode')
  @DocsEditable()
  @Experimental() // untriaged
  String get inputMode => wrap_jso(JS("String", "#.inputMode", this.raw));
  @DomName('HTMLInputElement.inputMode')
  @DocsEditable()
  @Experimental() // untriaged
  void set inputMode(String val) => JS("void", "#.inputMode = #", this.raw, unwrap_jso(val));

  @DomName('HTMLInputElement.labels')
  @DocsEditable()
  @Returns('NodeList')
  @Creates('NodeList')
  List<Node> get labels => wrap_jso(JS("List<Node>", "#.labels", this.raw));

  @DomName('HTMLInputElement.list')
  @DocsEditable()
  HtmlElement get list => wrap_jso(JS("HtmlElement", "#.list", this.raw));

  @DomName('HTMLInputElement.max')
  @DocsEditable()
  String get max => wrap_jso(JS("String", "#.max", this.raw));
  @DomName('HTMLInputElement.max')
  @DocsEditable()
  void set max(String val) => JS("void", "#.max = #", this.raw, unwrap_jso(val));

  @DomName('HTMLInputElement.maxLength')
  @DocsEditable()
  int get maxLength => wrap_jso(JS("int", "#.maxLength", this.raw));
  @DomName('HTMLInputElement.maxLength')
  @DocsEditable()
  void set maxLength(int val) => JS("void", "#.maxLength = #", this.raw, unwrap_jso(val));

  @DomName('HTMLInputElement.min')
  @DocsEditable()
  String get min => wrap_jso(JS("String", "#.min", this.raw));
  @DomName('HTMLInputElement.min')
  @DocsEditable()
  void set min(String val) => JS("void", "#.min = #", this.raw, unwrap_jso(val));

  @DomName('HTMLInputElement.multiple')
  @DocsEditable()
  bool get multiple => wrap_jso(JS("bool", "#.multiple", this.raw));
  @DomName('HTMLInputElement.multiple')
  @DocsEditable()
  void set multiple(bool val) => JS("void", "#.multiple = #", this.raw, unwrap_jso(val));

  @DomName('HTMLInputElement.name')
  @DocsEditable()
  String get name => wrap_jso(JS("String", "#.name", this.raw));
  @DomName('HTMLInputElement.name')
  @DocsEditable()
  void set name(String val) => JS("void", "#.name = #", this.raw, unwrap_jso(val));

  @DomName('HTMLInputElement.pattern')
  @DocsEditable()
  String get pattern => wrap_jso(JS("String", "#.pattern", this.raw));
  @DomName('HTMLInputElement.pattern')
  @DocsEditable()
  void set pattern(String val) => JS("void", "#.pattern = #", this.raw, unwrap_jso(val));

  @DomName('HTMLInputElement.placeholder')
  @DocsEditable()
  String get placeholder => wrap_jso(JS("String", "#.placeholder", this.raw));
  @DomName('HTMLInputElement.placeholder')
  @DocsEditable()
  void set placeholder(String val) => JS("void", "#.placeholder = #", this.raw, unwrap_jso(val));

  @DomName('HTMLInputElement.readOnly')
  @DocsEditable()
  bool get readOnly => wrap_jso(JS("bool", "#.readOnly", this.raw));
  @DomName('HTMLInputElement.readOnly')
  @DocsEditable()
  void set readOnly(bool val) => JS("void", "#.readOnly = #", this.raw, unwrap_jso(val));

  @DomName('HTMLInputElement.required')
  @DocsEditable()
  bool get required => wrap_jso(JS("bool", "#.required", this.raw));
  @DomName('HTMLInputElement.required')
  @DocsEditable()
  void set required(bool val) => JS("void", "#.required = #", this.raw, unwrap_jso(val));

  @DomName('HTMLInputElement.selectionDirection')
  @DocsEditable()
  String get selectionDirection => wrap_jso(JS("String", "#.selectionDirection", this.raw));
  @DomName('HTMLInputElement.selectionDirection')
  @DocsEditable()
  void set selectionDirection(String val) => JS("void", "#.selectionDirection = #", this.raw, unwrap_jso(val));

  @DomName('HTMLInputElement.selectionEnd')
  @DocsEditable()
  int get selectionEnd => wrap_jso(JS("int", "#.selectionEnd", this.raw));
  @DomName('HTMLInputElement.selectionEnd')
  @DocsEditable()
  void set selectionEnd(int val) => JS("void", "#.selectionEnd = #", this.raw, unwrap_jso(val));

  @DomName('HTMLInputElement.selectionStart')
  @DocsEditable()
  int get selectionStart => wrap_jso(JS("int", "#.selectionStart", this.raw));
  @DomName('HTMLInputElement.selectionStart')
  @DocsEditable()
  void set selectionStart(int val) => JS("void", "#.selectionStart = #", this.raw, unwrap_jso(val));

  @DomName('HTMLInputElement.size')
  @DocsEditable()
  int get size => wrap_jso(JS("int", "#.size", this.raw));
  @DomName('HTMLInputElement.size')
  @DocsEditable()
  void set size(int val) => JS("void", "#.size = #", this.raw, unwrap_jso(val));

  @DomName('HTMLInputElement.src')
  @DocsEditable()
  String get src => wrap_jso(JS("String", "#.src", this.raw));
  @DomName('HTMLInputElement.src')
  @DocsEditable()
  void set src(String val) => JS("void", "#.src = #", this.raw, unwrap_jso(val));

  @DomName('HTMLInputElement.step')
  @DocsEditable()
  String get step => wrap_jso(JS("String", "#.step", this.raw));
  @DomName('HTMLInputElement.step')
  @DocsEditable()
  void set step(String val) => JS("void", "#.step = #", this.raw, unwrap_jso(val));

  @DomName('HTMLInputElement.type')
  @DocsEditable()
  String get type => wrap_jso(JS("String", "#.type", this.raw));
  @DomName('HTMLInputElement.type')
  @DocsEditable()
  void set type(String val) => JS("void", "#.type = #", this.raw, unwrap_jso(val));

  @DomName('HTMLInputElement.validationMessage')
  @DocsEditable()
  String get validationMessage => wrap_jso(JS("String", "#.validationMessage", this.raw));

  @DomName('HTMLInputElement.value')
  @DocsEditable()
  String get value => wrap_jso(JS("String", "#.value", this.raw));
  @DomName('HTMLInputElement.value')
  @DocsEditable()
  void set value(String val) => JS("void", "#.value = #", this.raw, unwrap_jso(val));

  @DomName('HTMLInputElement.valueAsDate')
  @DocsEditable()
  DateTime get valueAsDate => convertNativeToDart_DateTime(this._get_valueAsDate);
  @JSName('valueAsDate')
  @DomName('HTMLInputElement.valueAsDate')
  @DocsEditable()
  @Creates('Null')
  dynamic get _get_valueAsDate => wrap_jso(JS("dynamic", "#.valueAsDate", this.raw));

  set valueAsDate(DateTime value) {
    this._set_valueAsDate = convertDartToNative_DateTime(value);
  }
  set _set_valueAsDate(/*dynamic*/ value) {
    JS("void", "#.raw.valueAsDate = #", this, unwrap_jso(value));
  }

  @DomName('HTMLInputElement.valueAsNumber')
  @DocsEditable()
  num get valueAsNumber => wrap_jso(JS("num", "#.valueAsNumber", this.raw));
  @DomName('HTMLInputElement.valueAsNumber')
  @DocsEditable()
  void set valueAsNumber(num val) => JS("void", "#.valueAsNumber = #", this.raw, unwrap_jso(val));

  @JSName('webkitdirectory')
  @DomName('HTMLInputElement.webkitdirectory')
  @DocsEditable()
  @SupportedBrowser(SupportedBrowser.CHROME)
  @SupportedBrowser(SupportedBrowser.SAFARI)
  @Experimental()
  // https://plus.sandbox.google.com/+AddyOsmani/posts/Dk5UhZ6zfF3
  bool get directory => wrap_jso(JS("bool", "#.webkitdirectory", this.raw));
  @JSName('webkitdirectory')
  @DomName('HTMLInputElement.webkitdirectory')
  @DocsEditable()
  @SupportedBrowser(SupportedBrowser.CHROME)
  @SupportedBrowser(SupportedBrowser.SAFARI)
  @Experimental()
  // https://plus.sandbox.google.com/+AddyOsmani/posts/Dk5UhZ6zfF3
  void set directory(bool val) => JS("void", "#.webkitdirectory = #", this.raw, unwrap_jso(val));

  @DomName('HTMLInputElement.width')
  @DocsEditable()
  int get width => wrap_jso(JS("int", "#.width", this.raw));
  @DomName('HTMLInputElement.width')
  @DocsEditable()
  void set width(int val) => JS("void", "#.width = #", this.raw, unwrap_jso(val));

  @DomName('HTMLInputElement.willValidate')
  @DocsEditable()
  bool get willValidate => wrap_jso(JS("bool", "#.willValidate", this.raw));

  @DomName('HTMLInputElement.checkValidity')
  @DocsEditable()
  bool checkValidity() {
    return _checkValidity_1();
  }
  @JSName('checkValidity')
  @DomName('HTMLInputElement.checkValidity')
  @DocsEditable()
  bool _checkValidity_1() => wrap_jso(JS("bool ", "#.raw.checkValidity()", this));

  @DomName('HTMLInputElement.select')
  @DocsEditable()
  void select() {
    _select_1();
    return;
  }
  @JSName('select')
  @DomName('HTMLInputElement.select')
  @DocsEditable()
  void _select_1() => wrap_jso(JS("void ", "#.raw.select()", this));

  @DomName('HTMLInputElement.setCustomValidity')
  @DocsEditable()
  void setCustomValidity(String error) {
    _setCustomValidity_1(error);
    return;
  }
  @JSName('setCustomValidity')
  @DomName('HTMLInputElement.setCustomValidity')
  @DocsEditable()
  void _setCustomValidity_1(error) => wrap_jso(JS("void ", "#.raw.setCustomValidity(#)", this, unwrap_jso(error)));

  @DomName('HTMLInputElement.setRangeText')
  @DocsEditable()
  // http://www.whatwg.org/specs/web-apps/current-work/multipage/association-of-controls-and-forms.html#dom-textarea/input-setrangetext
  @Experimental() // experimental
  void setRangeText(String replacement, {int start, int end, String selectionMode}) {
    if (start == null && end == null && selectionMode == null) {
      _setRangeText_1(replacement);
      return;
    }
    if (end != null && start != null && selectionMode == null) {
      _setRangeText_2(replacement, start, end);
      return;
    }
    if (selectionMode != null && end != null && start != null) {
      _setRangeText_3(replacement, start, end, selectionMode);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }
  @JSName('setRangeText')
  @DomName('HTMLInputElement.setRangeText')
  @DocsEditable()
  // http://www.whatwg.org/specs/web-apps/current-work/multipage/association-of-controls-and-forms.html#dom-textarea/input-setrangetext
  @Experimental() // experimental
  void _setRangeText_1(replacement) => wrap_jso(JS("void ", "#.raw.setRangeText(#)", this, unwrap_jso(replacement)));
  @JSName('setRangeText')
  @DomName('HTMLInputElement.setRangeText')
  @DocsEditable()
  // http://www.whatwg.org/specs/web-apps/current-work/multipage/association-of-controls-and-forms.html#dom-textarea/input-setrangetext
  @Experimental() // experimental
  void _setRangeText_2(replacement, start, end) => wrap_jso(JS("void ", "#.raw.setRangeText(#, #, #)", this, unwrap_jso(replacement), unwrap_jso(start), unwrap_jso(end)));
  @JSName('setRangeText')
  @DomName('HTMLInputElement.setRangeText')
  @DocsEditable()
  // http://www.whatwg.org/specs/web-apps/current-work/multipage/association-of-controls-and-forms.html#dom-textarea/input-setrangetext
  @Experimental() // experimental
  void _setRangeText_3(replacement, start, end, selectionMode) => wrap_jso(JS("void ", "#.raw.setRangeText(#, #, #, #)", this, unwrap_jso(replacement), unwrap_jso(start), unwrap_jso(end), unwrap_jso(selectionMode)));

  @DomName('HTMLInputElement.setSelectionRange')
  @DocsEditable()
  void setSelectionRange(int start, int end, [String direction]) {
    if (direction != null) {
      _setSelectionRange_1(start, end, direction);
      return;
    }
    _setSelectionRange_2(start, end);
    return;
  }
  @JSName('setSelectionRange')
  @DomName('HTMLInputElement.setSelectionRange')
  @DocsEditable()
  void _setSelectionRange_1(start, end, direction) => wrap_jso(JS("void ", "#.raw.setSelectionRange(#, #, #)", this, unwrap_jso(start), unwrap_jso(end), unwrap_jso(direction)));
  @JSName('setSelectionRange')
  @DomName('HTMLInputElement.setSelectionRange')
  @DocsEditable()
  void _setSelectionRange_2(start, end) => wrap_jso(JS("void ", "#.raw.setSelectionRange(#, #)", this, unwrap_jso(start), unwrap_jso(end)));

  @DomName('HTMLInputElement.stepDown')
  @DocsEditable()
  void stepDown([int n]) {
    if (n != null) {
      _stepDown_1(n);
      return;
    }
    _stepDown_2();
    return;
  }
  @JSName('stepDown')
  @DomName('HTMLInputElement.stepDown')
  @DocsEditable()
  void _stepDown_1(n) => wrap_jso(JS("void ", "#.raw.stepDown(#)", this, unwrap_jso(n)));
  @JSName('stepDown')
  @DomName('HTMLInputElement.stepDown')
  @DocsEditable()
  void _stepDown_2() => wrap_jso(JS("void ", "#.raw.stepDown()", this));

  @DomName('HTMLInputElement.stepUp')
  @DocsEditable()
  void stepUp([int n]) {
    if (n != null) {
      _stepUp_1(n);
      return;
    }
    _stepUp_2();
    return;
  }
  @JSName('stepUp')
  @DomName('HTMLInputElement.stepUp')
  @DocsEditable()
  void _stepUp_1(n) => wrap_jso(JS("void ", "#.raw.stepUp(#)", this, unwrap_jso(n)));
  @JSName('stepUp')
  @DomName('HTMLInputElement.stepUp')
  @DocsEditable()
  void _stepUp_2() => wrap_jso(JS("void ", "#.raw.stepUp()", this));

}


// Interfaces representing the InputElement APIs which are supported
// for the various types of InputElement. From:
// http://www.w3.org/html/wg/drafts/html/master/forms.html#the-input-element.

/**
 * Exposes the functionality common between all InputElement types.
 */
abstract class InputElementBase implements Element {
  @DomName('HTMLInputElement.autofocus')
  bool autofocus;

  @DomName('HTMLInputElement.disabled')
  bool disabled;

  @DomName('HTMLInputElement.incremental')
  bool incremental;

  @DomName('HTMLInputElement.indeterminate')
  bool indeterminate;

  @DomName('HTMLInputElement.labels')
  List<Node> get labels;

  @DomName('HTMLInputElement.name')
  String name;

  @DomName('HTMLInputElement.validationMessage')
  String get validationMessage;


  @DomName('HTMLInputElement.value')
  String value;

  @DomName('HTMLInputElement.willValidate')
  bool get willValidate;

  @DomName('HTMLInputElement.checkValidity')
  bool checkValidity();

  @DomName('HTMLInputElement.setCustomValidity')
  void setCustomValidity(String error);
}

/**
 * Hidden input which is not intended to be seen or edited by the user.
 */
abstract class HiddenInputElement implements InputElementBase {
  factory HiddenInputElement() => new InputElement(type: 'hidden');
}


/**
 * Base interface for all inputs which involve text editing.
 */
abstract class TextInputElementBase implements InputElementBase {
  @DomName('HTMLInputElement.autocomplete')
  String autocomplete;

  @DomName('HTMLInputElement.maxLength')
  int maxLength;

  @DomName('HTMLInputElement.pattern')
  String pattern;

  @DomName('HTMLInputElement.placeholder')
  String placeholder;

  @DomName('HTMLInputElement.readOnly')
  bool readOnly;

  @DomName('HTMLInputElement.required')
  bool required;

  @DomName('HTMLInputElement.size')
  int size;

  @DomName('HTMLInputElement.select')
  void select();

  @DomName('HTMLInputElement.selectionDirection')
  String selectionDirection;

  @DomName('HTMLInputElement.selectionEnd')
  int selectionEnd;

  @DomName('HTMLInputElement.selectionStart')
  int selectionStart;

  @DomName('HTMLInputElement.setSelectionRange')
  void setSelectionRange(int start, int end, [String direction]);
}

/**
 * Similar to [TextInputElement], but on platforms where search is styled
 * differently this will get the search style.
 *
 * Use [supported] to check if this is supported on the current platform.
 */
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
abstract class SearchInputElement implements TextInputElementBase {
  factory SearchInputElement() => new InputElement(type: 'search');

  @DomName('HTMLInputElement.dirName')
  String dirName;

  @DomName('HTMLInputElement.list')
  Element get list;

  /// Returns true if this input type is supported on the current platform.
  static bool get supported {
    return (new InputElement(type: 'search')).type == 'search';
  }
}

/**
 * A basic text input editor control.
 */
abstract class TextInputElement implements TextInputElementBase {
  factory TextInputElement() => new InputElement(type: 'text');

  @DomName('HTMLInputElement.dirName')
  String dirName;

  @DomName('HTMLInputElement.list')
  Element get list;
}

/**
 * A control for editing an absolute URL.
 *
 * Use [supported] to check if this is supported on the current platform.
 */
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
abstract class UrlInputElement implements TextInputElementBase {
  factory UrlInputElement() => new InputElement(type: 'url');

  @DomName('HTMLInputElement.list')
  Element get list;

  /// Returns true if this input type is supported on the current platform.
  static bool get supported {
    return (new InputElement(type: 'url')).type == 'url';
  }
}

/**
 * Represents a control for editing a telephone number.
 *
 * This provides a single line of text with minimal formatting help since
 * there is a wide variety of telephone numbers.
 *
 * Use [supported] to check if this is supported on the current platform.
 */
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
abstract class TelephoneInputElement implements TextInputElementBase {
  factory TelephoneInputElement() => new InputElement(type: 'tel');

  @DomName('HTMLInputElement.list')
  Element get list;

  /// Returns true if this input type is supported on the current platform.
  static bool get supported {
    return (new InputElement(type: 'tel')).type == 'tel';
  }
}

/**
 * An e-mail address or list of e-mail addresses.
 *
 * Use [supported] to check if this is supported on the current platform.
 */
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
abstract class EmailInputElement implements TextInputElementBase {
  factory EmailInputElement() => new InputElement(type: 'email');

  @DomName('HTMLInputElement.autocomplete')
  String autocomplete;

  @DomName('HTMLInputElement.autofocus')
  bool autofocus;

  @DomName('HTMLInputElement.list')
  Element get list;

  @DomName('HTMLInputElement.maxLength')
  int maxLength;

  @DomName('HTMLInputElement.multiple')
  bool multiple;

  @DomName('HTMLInputElement.pattern')
  String pattern;

  @DomName('HTMLInputElement.placeholder')
  String placeholder;

  @DomName('HTMLInputElement.readOnly')
  bool readOnly;

  @DomName('HTMLInputElement.required')
  bool required;

  @DomName('HTMLInputElement.size')
  int size;

  /// Returns true if this input type is supported on the current platform.
  static bool get supported {
    return (new InputElement(type: 'email')).type == 'email';
  }
}

/**
 * Text with no line breaks (sensitive information).
 */
abstract class PasswordInputElement implements TextInputElementBase {
  factory PasswordInputElement() => new InputElement(type: 'password');
}

/**
 * Base interface for all input element types which involve ranges.
 */
abstract class RangeInputElementBase implements InputElementBase {

  @DomName('HTMLInputElement.list')
  Element get list;

  @DomName('HTMLInputElement.max')
  String max;

  @DomName('HTMLInputElement.min')
  String min;

  @DomName('HTMLInputElement.step')
  String step;

  @DomName('HTMLInputElement.valueAsNumber')
  num valueAsNumber;

  @DomName('HTMLInputElement.stepDown')
  void stepDown([int n]);

  @DomName('HTMLInputElement.stepUp')
  void stepUp([int n]);
}

/**
 * A date (year, month, day) with no time zone.
 *
 * Use [supported] to check if this is supported on the current platform.
 */
@SupportedBrowser(SupportedBrowser.CHROME, '25')
@Experimental()
abstract class DateInputElement implements RangeInputElementBase {
  factory DateInputElement() => new InputElement(type: 'date');

  @DomName('HTMLInputElement.valueAsDate')
  DateTime valueAsDate;

  @DomName('HTMLInputElement.readOnly')
  bool readOnly;

  @DomName('HTMLInputElement.required')
  bool required;

  /// Returns true if this input type is supported on the current platform.
  static bool get supported {
    return (new InputElement(type: 'date')).type == 'date';
  }
}

/**
 * A date consisting of a year and a month with no time zone.
 *
 * Use [supported] to check if this is supported on the current platform.
 */
@SupportedBrowser(SupportedBrowser.CHROME, '25')
@Experimental()
abstract class MonthInputElement implements RangeInputElementBase {
  factory MonthInputElement() => new InputElement(type: 'month');

  @DomName('HTMLInputElement.valueAsDate')
  DateTime valueAsDate;

  @DomName('HTMLInputElement.readOnly')
  bool readOnly;

  @DomName('HTMLInputElement.required')
  bool required;

  /// Returns true if this input type is supported on the current platform.
  static bool get supported {
    return (new InputElement(type: 'month')).type == 'month';
  }
}

/**
 * A date consisting of a week-year number and a week number with no time zone.
 *
 * Use [supported] to check if this is supported on the current platform.
 */
@SupportedBrowser(SupportedBrowser.CHROME, '25')
@Experimental()
abstract class WeekInputElement implements RangeInputElementBase {
  factory WeekInputElement() => new InputElement(type: 'week');

  @DomName('HTMLInputElement.valueAsDate')
  DateTime valueAsDate;

  @DomName('HTMLInputElement.readOnly')
  bool readOnly;

  @DomName('HTMLInputElement.required')
  bool required;

  /// Returns true if this input type is supported on the current platform.
  static bool get supported {
    return (new InputElement(type: 'week')).type == 'week';
  }
}

/**
 * A time (hour, minute, seconds, fractional seconds) with no time zone.
 *
 * Use [supported] to check if this is supported on the current platform.
 */
@SupportedBrowser(SupportedBrowser.CHROME)
@Experimental()
abstract class TimeInputElement implements RangeInputElementBase {
  factory TimeInputElement() => new InputElement(type: 'time');

  @DomName('HTMLInputElement.valueAsDate')
  DateTime valueAsDate;

  @DomName('HTMLInputElement.readOnly')
  bool readOnly;

  @DomName('HTMLInputElement.required')
  bool required;

  /// Returns true if this input type is supported on the current platform.
  static bool get supported {
    return (new InputElement(type: 'time')).type == 'time';
  }
}

/**
 * A date and time (year, month, day, hour, minute, second, fraction of a
 * second) with no time zone.
 *
 * Use [supported] to check if this is supported on the current platform.
 */
@SupportedBrowser(SupportedBrowser.CHROME, '25')
@Experimental()
abstract class LocalDateTimeInputElement implements RangeInputElementBase {
  factory LocalDateTimeInputElement() =>
      new InputElement(type: 'datetime-local');

  @DomName('HTMLInputElement.readOnly')
  bool readOnly;

  @DomName('HTMLInputElement.required')
  bool required;

  /// Returns true if this input type is supported on the current platform.
  static bool get supported {
    return (new InputElement(type: 'datetime-local')).type == 'datetime-local';
  }
}

/**
 * A numeric editor control.
 */
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.IE)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Experimental()
abstract class NumberInputElement implements RangeInputElementBase {
  factory NumberInputElement() => new InputElement(type: 'number');

  @DomName('HTMLInputElement.placeholder')
  String placeholder;

  @DomName('HTMLInputElement.readOnly')
  bool readOnly;

  @DomName('HTMLInputElement.required')
  bool required;

  /// Returns true if this input type is supported on the current platform.
  static bool get supported {
    return (new InputElement(type: 'number')).type == 'number';
  }
}

/**
 * Similar to [NumberInputElement] but the browser may provide more optimal
 * styling (such as a slider control).
 *
 * Use [supported] to check if this is supported on the current platform.
 */
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.IE, '10')
@Experimental()
abstract class RangeInputElement implements RangeInputElementBase {
  factory RangeInputElement() => new InputElement(type: 'range');

  /// Returns true if this input type is supported on the current platform.
  static bool get supported {
    return (new InputElement(type: 'range')).type == 'range';
  }
}

/**
 * A boolean editor control.
 *
 * Note that if [indeterminate] is set then this control is in a third
 * indeterminate state.
 */
abstract class CheckboxInputElement implements InputElementBase {
  factory CheckboxInputElement() => new InputElement(type: 'checkbox');

  @DomName('HTMLInputElement.checked')
  bool checked;

  @DomName('HTMLInputElement.required')
  bool required;
}


/**
 * A control that when used with other [ReadioButtonInputElement] controls
 * forms a radio button group in which only one control can be checked at a
 * time.
 *
 * Radio buttons are considered to be in the same radio button group if:
 *
 * * They are all of type 'radio'.
 * * They all have either the same [FormElement] owner, or no owner.
 * * Their name attributes contain the same name.
 */
abstract class RadioButtonInputElement implements InputElementBase {
  factory RadioButtonInputElement() => new InputElement(type: 'radio');

  @DomName('HTMLInputElement.checked')
  bool checked;

  @DomName('HTMLInputElement.required')
  bool required;
}

/**
 * A control for picking files from the user's computer.
 */
abstract class FileUploadInputElement implements InputElementBase {
  factory FileUploadInputElement() => new InputElement(type: 'file');

  @DomName('HTMLInputElement.accept')
  String accept;

  @DomName('HTMLInputElement.multiple')
  bool multiple;

  @DomName('HTMLInputElement.required')
  bool required;

}

/**
 * A button, which when clicked, submits the form.
 */
abstract class SubmitButtonInputElement implements InputElementBase {
  factory SubmitButtonInputElement() => new InputElement(type: 'submit');

  @DomName('HTMLInputElement.formAction')
  String formAction;

  @DomName('HTMLInputElement.formEnctype')
  String formEnctype;

  @DomName('HTMLInputElement.formMethod')
  String formMethod;

  @DomName('HTMLInputElement.formNoValidate')
  bool formNoValidate;

  @DomName('HTMLInputElement.formTarget')
  String formTarget;
}

/**
 * Either an image which the user can select a coordinate to or a form
 * submit button.
 */
abstract class ImageButtonInputElement implements InputElementBase {
  factory ImageButtonInputElement() => new InputElement(type: 'image');

  @DomName('HTMLInputElement.alt')
  String alt;

  @DomName('HTMLInputElement.formAction')
  String formAction;

  @DomName('HTMLInputElement.formEnctype')
  String formEnctype;

  @DomName('HTMLInputElement.formMethod')
  String formMethod;

  @DomName('HTMLInputElement.formNoValidate')
  bool formNoValidate;

  @DomName('HTMLInputElement.formTarget')
  String formTarget;

  @DomName('HTMLInputElement.height')
  int height;

  @DomName('HTMLInputElement.src')
  String src;

  @DomName('HTMLInputElement.width')
  int width;
}

/**
 * A button, which when clicked, resets the form.
 */
abstract class ResetButtonInputElement implements InputElementBase {
  factory ResetButtonInputElement() => new InputElement(type: 'reset');
}

/**
 * A button, with no default behavior.
 */
abstract class ButtonInputElement implements InputElementBase {
  factory ButtonInputElement() => new InputElement(type: 'button');
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * An event that describes user interaction with the keyboard.
 *
 * The [type] of the event identifies what kind of interaction occurred.
 *
 * See also:
 *
 * * [KeyboardEvent](https://developer.mozilla.org/en/DOM/KeyboardEvent) at MDN.
 */
@DomName('KeyboardEvent')
@Native("KeyboardEvent")
class KeyboardEvent extends UIEvent {

  /**
   * Programmatically create a KeyboardEvent.
   *
   * Due to browser differences, keyCode, charCode, or keyIdentifier values
   * cannot be specified in this base level constructor. This constructor
   * enables the user to programmatically create and dispatch a [KeyboardEvent],
   * but it will not contain any particular key content. For programmatically
   * creating keyboard events with specific key value contents, see the custom
   * Event [KeyEvent].
   */
  factory KeyboardEvent(String type,
      {Window view, bool canBubble: true, bool cancelable: true,
      int keyLocation: 1, bool ctrlKey: false,
      bool altKey: false, bool shiftKey: false, bool metaKey: false}) {
    if (view == null) {
      view = window;
    }
    KeyboardEvent e = document._createEvent("KeyboardEvent");
    e._initKeyboardEvent(type, canBubble, cancelable, view, "",
        keyLocation, ctrlKey, altKey, shiftKey, metaKey);
    return e;
  }

  @DomName('KeyboardEvent.initKeyboardEvent')
  void _initKeyboardEvent(String type, bool canBubble, bool cancelable,
      Window view, String keyIdentifier, int keyLocation, bool ctrlKey,
      bool altKey, bool shiftKey, bool metaKey) {
    if (JS('bool', 'typeof(#.initKeyEvent) == "function"', this.raw)) {
      // initKeyEvent is only in Firefox (instead of initKeyboardEvent). It has
      // a slightly different signature, and allows you to specify keyCode and
      // charCode as the last two arguments, but we just set them as the default
      // since they can't be specified in other browsers.
      JS('void', '#.initKeyEvent(#, #, #, #, #, #, #, #, 0, 0)', this.raw,
          type, canBubble, cancelable, unwrap_jso(view),
          ctrlKey, altKey, shiftKey, metaKey);
    } else {
      // initKeyboardEvent is for all other browsers.
      JS('void', '#.initKeyboardEvent(#, #, #, #, #, #, #, #, #, #)', this.raw,
          type, canBubble, cancelable, unwrap_jso(view), keyIdentifier, keyLocation,
          ctrlKey, altKey, shiftKey, metaKey);
    }
  }

  @DomName('KeyboardEvent.keyCode')
  int get keyCode => _keyCode;

  @DomName('KeyboardEvent.charCode')
  int get charCode => _charCode;
  // To suppress missing implicit constructor warnings.
  factory KeyboardEvent._() { throw new UnsupportedError("Not supported"); }


  @Deprecated("Internal Use Only")
  static KeyboardEvent internalCreateKeyboardEvent() {
    return new KeyboardEvent.internal_();
  }

  @Deprecated("Internal Use Only")
  KeyboardEvent.internal_() : super.internal_();


  @DomName('KeyboardEvent.DOM_KEY_LOCATION_LEFT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DOM_KEY_LOCATION_LEFT = 0x01;

  @DomName('KeyboardEvent.DOM_KEY_LOCATION_NUMPAD')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DOM_KEY_LOCATION_NUMPAD = 0x03;

  @DomName('KeyboardEvent.DOM_KEY_LOCATION_RIGHT')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DOM_KEY_LOCATION_RIGHT = 0x02;

  @DomName('KeyboardEvent.DOM_KEY_LOCATION_STANDARD')
  @DocsEditable()
  @Experimental() // untriaged
  static const int DOM_KEY_LOCATION_STANDARD = 0x00;

  @DomName('KeyboardEvent.altKey')
  @DocsEditable()
  bool get altKey => wrap_jso(JS("bool", "#.altKey", this.raw));

  @DomName('KeyboardEvent.ctrlKey')
  @DocsEditable()
  bool get ctrlKey => wrap_jso(JS("bool", "#.ctrlKey", this.raw));

  @JSName('keyIdentifier')
  @DomName('KeyboardEvent.keyIdentifier')
  @DocsEditable()
  @Experimental() // nonstandard
  String get _keyIdentifier => wrap_jso(JS("String", "#.keyIdentifier", this.raw));

  @DomName('KeyboardEvent.keyLocation')
  @DocsEditable()
  @Experimental() // nonstandard
  int get keyLocation => wrap_jso(JS("int", "#.keyLocation", this.raw));

  @DomName('KeyboardEvent.location')
  @DocsEditable()
  @Experimental() // untriaged
  int get location => wrap_jso(JS("int", "#.location", this.raw));

  @DomName('KeyboardEvent.metaKey')
  @DocsEditable()
  bool get metaKey => wrap_jso(JS("bool", "#.metaKey", this.raw));

  @DomName('KeyboardEvent.repeat')
  @DocsEditable()
  @Experimental() // untriaged
  bool get repeat => wrap_jso(JS("bool", "#.repeat", this.raw));

  @DomName('KeyboardEvent.shiftKey')
  @DocsEditable()
  bool get shiftKey => wrap_jso(JS("bool", "#.shiftKey", this.raw));

  @DomName('KeyboardEvent.getModifierState')
  @DocsEditable()
  @Experimental() // untriaged
  bool getModifierState(String keyArgument) {
    return _getModifierState_1(keyArgument);
  }
  @JSName('getModifierState')
  @DomName('KeyboardEvent.getModifierState')
  @DocsEditable()
  @Experimental() // untriaged
  bool _getModifierState_1(keyArgument) => wrap_jso(JS("bool ", "#.raw.getModifierState(#)", this, unwrap_jso(keyArgument)));

}
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('Location')
@Native("Location")
class Location extends DartHtmlDomObject implements LocationBase {
  // To suppress missing implicit constructor warnings.
  factory Location._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static Location internalCreateLocation() {
    return new Location.internal_();
  }

  @Deprecated("Internal Use Only")
  Location.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

  @DomName('Location.hash')
  @DocsEditable()
  String get hash => wrap_jso(JS("String", "#.hash", this.raw));
  @DomName('Location.hash')
  @DocsEditable()
  void set hash(String val) => JS("void", "#.hash = #", this.raw, unwrap_jso(val));

  @DomName('Location.host')
  @DocsEditable()
  String get host => wrap_jso(JS("String", "#.host", this.raw));
  @DomName('Location.host')
  @DocsEditable()
  void set host(String val) => JS("void", "#.host = #", this.raw, unwrap_jso(val));

  @DomName('Location.hostname')
  @DocsEditable()
  String get hostname => wrap_jso(JS("String", "#.hostname", this.raw));
  @DomName('Location.hostname')
  @DocsEditable()
  void set hostname(String val) => JS("void", "#.hostname = #", this.raw, unwrap_jso(val));

  @DomName('Location.href')
  @DocsEditable()
  String get href => wrap_jso(JS("String", "#.href", this.raw));
  @DomName('Location.href')
  @DocsEditable()
  void set href(String val) => JS("void", "#.href = #", this.raw, unwrap_jso(val));

  @DomName('Location.pathname')
  @DocsEditable()
  String get pathname => wrap_jso(JS("String", "#.pathname", this.raw));
  @DomName('Location.pathname')
  @DocsEditable()
  void set pathname(String val) => JS("void", "#.pathname = #", this.raw, unwrap_jso(val));

  @DomName('Location.port')
  @DocsEditable()
  String get port => wrap_jso(JS("String", "#.port", this.raw));
  @DomName('Location.port')
  @DocsEditable()
  void set port(String val) => JS("void", "#.port = #", this.raw, unwrap_jso(val));

  @DomName('Location.protocol')
  @DocsEditable()
  String get protocol => wrap_jso(JS("String", "#.protocol", this.raw));
  @DomName('Location.protocol')
  @DocsEditable()
  void set protocol(String val) => JS("void", "#.protocol = #", this.raw, unwrap_jso(val));

  @DomName('Location.search')
  @DocsEditable()
  String get search => wrap_jso(JS("String", "#.search", this.raw));
  @DomName('Location.search')
  @DocsEditable()
  void set search(String val) => JS("void", "#.search = #", this.raw, unwrap_jso(val));

  @DomName('Location.assign')
  @DocsEditable()
  void assign([String url]) {
    if (url != null) {
      _assign_1(url);
      return;
    }
    _assign_2();
    return;
  }
  @JSName('assign')
  @DomName('Location.assign')
  @DocsEditable()
  void _assign_1(url) => wrap_jso(JS("void ", "#.raw.assign(#)", this, unwrap_jso(url)));
  @JSName('assign')
  @DomName('Location.assign')
  @DocsEditable()
  void _assign_2() => wrap_jso(JS("void ", "#.raw.assign()", this));

  @DomName('Location.reload')
  @DocsEditable()
  void reload() {
    _reload_1();
    return;
  }
  @JSName('reload')
  @DomName('Location.reload')
  @DocsEditable()
  void _reload_1() => wrap_jso(JS("void ", "#.raw.reload()", this));

  @DomName('Location.replace')
  @DocsEditable()
  void replace(String url) {
    _replace_1(url);
    return;
  }
  @JSName('replace')
  @DomName('Location.replace')
  @DocsEditable()
  void _replace_1(url) => wrap_jso(JS("void ", "#.raw.replace(#)", this, unwrap_jso(url)));



}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('MouseEvent')
@Native("MouseEvent,DragEvent,PointerEvent,MSPointerEvent")
class MouseEvent extends UIEvent {
  // To suppress missing implicit constructor warnings.
  factory MouseEvent._() { throw new UnsupportedError("Not supported"); }


  @Deprecated("Internal Use Only")
  static MouseEvent internalCreateMouseEvent() {
    return new MouseEvent.internal_();
  }

  @Deprecated("Internal Use Only")
  MouseEvent.internal_() : super.internal_();


  @DomName('MouseEvent.altKey')
  @DocsEditable()
  bool get altKey => wrap_jso(JS("bool", "#.altKey", this.raw));

  @DomName('MouseEvent.button')
  @DocsEditable()
  int get button => wrap_jso(JS("int", "#.button", this.raw));

  @JSName('clientX')
  @DomName('MouseEvent.clientX')
  @DocsEditable()
  int get _clientX => wrap_jso(JS("int", "#.clientX", this.raw));

  @JSName('clientY')
  @DomName('MouseEvent.clientY')
  @DocsEditable()
  int get _clientY => wrap_jso(JS("int", "#.clientY", this.raw));

  @DomName('MouseEvent.ctrlKey')
  @DocsEditable()
  bool get ctrlKey => wrap_jso(JS("bool", "#.ctrlKey", this.raw));

  /**
   * The nonstandard way to access the element that the mouse comes
   * from in the case of a `mouseover` event.
   *
   * This member is deprecated and not cross-browser compatible; use
   * relatedTarget to get the same information in the standard way.
   */
  @DomName('MouseEvent.fromElement')
  @DocsEditable()
  @deprecated
  Node get fromElement => wrap_jso(JS("Node", "#.fromElement", this.raw));

  @DomName('MouseEvent.metaKey')
  @DocsEditable()
  bool get metaKey => wrap_jso(JS("bool", "#.metaKey", this.raw));

  @JSName('movementX')
  @DomName('MouseEvent.movementX')
  @DocsEditable()
  @Experimental() // untriaged
  int get _movementX => wrap_jso(JS("int", "#.movementX", this.raw));

  @JSName('movementY')
  @DomName('MouseEvent.movementY')
  @DocsEditable()
  @Experimental() // untriaged
  int get _movementY => wrap_jso(JS("int", "#.movementY", this.raw));

  @DomName('MouseEvent.region')
  @DocsEditable()
  @Experimental() // untriaged
  String get region => wrap_jso(JS("String", "#.region", this.raw));

  @DomName('MouseEvent.relatedTarget')
  @DocsEditable()
  EventTarget get relatedTarget => _convertNativeToDart_EventTarget(this._get_relatedTarget);
  @JSName('relatedTarget')
  @DomName('MouseEvent.relatedTarget')
  @DocsEditable()
  @Creates('Node')
  @Returns('EventTarget|=Object')
  dynamic get _get_relatedTarget => wrap_jso(JS("dynamic", "#.relatedTarget", this.raw));

  @JSName('screenX')
  @DomName('MouseEvent.screenX')
  @DocsEditable()
  int get _screenX => wrap_jso(JS("int", "#.screenX", this.raw));

  @JSName('screenY')
  @DomName('MouseEvent.screenY')
  @DocsEditable()
  int get _screenY => wrap_jso(JS("int", "#.screenY", this.raw));

  @DomName('MouseEvent.shiftKey')
  @DocsEditable()
  bool get shiftKey => wrap_jso(JS("bool", "#.shiftKey", this.raw));

  /**
   * The nonstandard way to access the element that the mouse goes
   * to in the case of a `mouseout` event.
   *
   * This member is deprecated and not cross-browser compatible; use
   * relatedTarget to get the same information in the standard way.
   */
  @DomName('MouseEvent.toElement')
  @DocsEditable()
  @deprecated
  Node get toElement => wrap_jso(JS("Node", "#.toElement", this.raw));

  @JSName('webkitMovementX')
  @DomName('MouseEvent.webkitMovementX')
  @DocsEditable()
  @SupportedBrowser(SupportedBrowser.CHROME)
  @SupportedBrowser(SupportedBrowser.SAFARI)
  @Experimental()
  int get _webkitMovementX => wrap_jso(JS("int", "#.webkitMovementX", this.raw));

  @JSName('webkitMovementY')
  @DomName('MouseEvent.webkitMovementY')
  @DocsEditable()
  @SupportedBrowser(SupportedBrowser.CHROME)
  @SupportedBrowser(SupportedBrowser.SAFARI)
  @Experimental()
  int get _webkitMovementY => wrap_jso(JS("int", "#.webkitMovementY", this.raw));

  @DomName('MouseEvent.initMouseEvent')
  @DocsEditable()
  void _initMouseEvent(String type, bool canBubble, bool cancelable, Window view, int detail, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey, int button, EventTarget relatedTarget) {
    var relatedTarget_1 = _convertDartToNative_EventTarget(relatedTarget);
    _initMouseEvent_1(type, canBubble, cancelable, view, detail, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey, button, relatedTarget_1);
    return;
  }
  @JSName('initMouseEvent')
  @DomName('MouseEvent.initMouseEvent')
  @DocsEditable()
  void _initMouseEvent_1(type, canBubble, cancelable, Window view, detail, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey, button, relatedTarget) => wrap_jso(JS("void ", "#.raw.initMouseEvent(#, #, #, #, #, #, #, #, #, #, #, #, #, #, #)", this, unwrap_jso(type), unwrap_jso(canBubble), unwrap_jso(cancelable), unwrap_jso(view), unwrap_jso(detail), unwrap_jso(screenX), unwrap_jso(screenY), unwrap_jso(clientX), unwrap_jso(clientY), unwrap_jso(ctrlKey), unwrap_jso(altKey), unwrap_jso(shiftKey), unwrap_jso(metaKey), unwrap_jso(button), unwrap_jso(relatedTarget)));
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('Navigator')
@Native("Navigator")
class Navigator extends DartHtmlDomObject implements NavigatorCpu {


  @DomName('Navigator.language')
  String get language => JS('String', '#.language || #.userLanguage', this.raw,
      this.raw);


  // To suppress missing implicit constructor warnings.
  factory Navigator._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static Navigator internalCreateNavigator() {
    return new Navigator.internal_();
  }

  @Deprecated("Internal Use Only")
  Navigator.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

  @DomName('Navigator.cookieEnabled')
  @DocsEditable()
  @Unstable()
  bool get cookieEnabled => wrap_jso(JS("bool", "#.cookieEnabled", this.raw));

  @DomName('Navigator.doNotTrack')
  @DocsEditable()
  // http://www.w3.org/2011/tracking-protection/drafts/tracking-dnt.html#js-dom
  @Experimental() // experimental
  String get doNotTrack => wrap_jso(JS("String", "#.doNotTrack", this.raw));

  @DomName('Navigator.maxTouchPoints')
  @DocsEditable()
  @Experimental() // untriaged
  int get maxTouchPoints => wrap_jso(JS("int", "#.maxTouchPoints", this.raw));

  @DomName('Navigator.productSub')
  @DocsEditable()
  @Unstable()
  String get productSub => wrap_jso(JS("String", "#.productSub", this.raw));

  @DomName('Navigator.vendor')
  @DocsEditable()
  @Unstable()
  String get vendor => wrap_jso(JS("String", "#.vendor", this.raw));

  @DomName('Navigator.vendorSub')
  @DocsEditable()
  @Unstable()
  String get vendorSub => wrap_jso(JS("String", "#.vendorSub", this.raw));

  @DomName('Navigator.getBattery')
  @DocsEditable()
  @Experimental() // untriaged
  Future getBattery() {
    return _getBattery_1();
  }
  @JSName('getBattery')
  @DomName('Navigator.getBattery')
  @DocsEditable()
  @Experimental() // untriaged
  Future _getBattery_1() => wrap_jso(JS("Future ", "#.raw.getBattery()", this));

  @DomName('Navigator.getStorageUpdates')
  @DocsEditable()
  // http://www.whatwg.org/specs/web-apps/current-work/multipage/timers.html#navigatorstorageutils
  @Experimental()
  void getStorageUpdates() {
    _getStorageUpdates_1();
    return;
  }
  @JSName('getStorageUpdates')
  @DomName('Navigator.getStorageUpdates')
  @DocsEditable()
  // http://www.whatwg.org/specs/web-apps/current-work/multipage/timers.html#navigatorstorageutils
  @Experimental()
  void _getStorageUpdates_1() => wrap_jso(JS("void ", "#.raw.getStorageUpdates()", this));

  @DomName('Navigator.registerProtocolHandler')
  @DocsEditable()
  @Unstable()
  void registerProtocolHandler(String scheme, String url, String title) {
    _registerProtocolHandler_1(scheme, url, title);
    return;
  }
  @JSName('registerProtocolHandler')
  @DomName('Navigator.registerProtocolHandler')
  @DocsEditable()
  @Unstable()
  void _registerProtocolHandler_1(scheme, url, title) => wrap_jso(JS("void ", "#.raw.registerProtocolHandler(#, #, #)", this, unwrap_jso(scheme), unwrap_jso(url), unwrap_jso(title)));

  @DomName('Navigator.sendBeacon')
  @DocsEditable()
  @Experimental() // untriaged
  bool sendBeacon(String url, String data) {
    return _sendBeacon_1(url, data);
  }
  @JSName('sendBeacon')
  @DomName('Navigator.sendBeacon')
  @DocsEditable()
  @Experimental() // untriaged
  bool _sendBeacon_1(url, data) => wrap_jso(JS("bool ", "#.raw.sendBeacon(#, #)", this, unwrap_jso(url), unwrap_jso(data)));

  // From NavigatorCPU

  @DomName('Navigator.hardwareConcurrency')
  @DocsEditable()
  @Experimental() // untriaged
  int get hardwareConcurrency => wrap_jso(JS("int", "#.hardwareConcurrency", this.raw));

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('NavigatorCPU')
@Experimental() // untriaged
abstract class NavigatorCpu extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory NavigatorCpu._() { throw new UnsupportedError("Not supported"); }

  int get hardwareConcurrency => wrap_jso(JS("int", "#.hardwareConcurrency", this.raw));
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * Lazy implementation of the child nodes of an element that does not request
 * the actual child nodes of an element until strictly necessary greatly
 * improving performance for the typical cases where it is not required.
 */
class _ChildNodeListLazy extends ListBase<Node> implements NodeListWrapper {
  final Node _this;

  _ChildNodeListLazy(this._this);


  Node get first {
    Node result = _this.firstChild;
    if (result == null) throw new StateError("No elements");
    return result;
  }
  Node get last {
    Node result = _this.lastChild;
    if (result == null) throw new StateError("No elements");
    return result;
  }
  Node get single {
    int l = this.length;
    if (l == 0) throw new StateError("No elements");
    if (l > 1) throw new StateError("More than one element");
    return _this.firstChild;
  }

  void add(Node value) {
    _this.append(value);
  }

  void addAll(Iterable<Node> iterable) {
    if (iterable is _ChildNodeListLazy) {
      _ChildNodeListLazy otherList = iterable;
      if (!identical(otherList._this, _this)) {
        // Optimized route for copying between nodes.
        for (var i = 0, len = otherList.length; i < len; ++i) {
          _this.append(otherList._this.firstChild);
        }
      }
      return;
    }
    for (Node node in iterable) {
      _this.append(node);
    }
  }

  void insert(int index, Node node) {
    if (index < 0 || index > length) {
      throw new RangeError.range(index, 0, length);
    }
    if (index == length) {
      _this.append(node);
    } else {
      _this.insertBefore(node, this[index]);
    }
  }

  void insertAll(int index, Iterable<Node> iterable) {
    if (index == length) {
      addAll(iterable);
    } else {
      var item = this[index];
      _this.insertAllBefore(iterable, item);
    }
  }

  void setAll(int index, Iterable<Node> iterable) {
    throw new UnsupportedError("Cannot setAll on Node list");
  }

  Node removeLast() {
    final result = last;
    if (result != null) {
      _this._removeChild(result);
    }
    return result;
  }

  Node removeAt(int index) {
    var result = this[index];
    if (result != null) {
      _this._removeChild(result);
    }
    return result;
  }

  bool remove(Object object) {
    if (object is! Node) return false;
    Node node = object;
    // We aren't preserving identity of nodes in JSINTEROP mode
    if (_this != node.parentNode) return false;
    _this._removeChild(node);
    return true;
  }

  void _filter(bool test(Node node), bool removeMatching) {
    // This implementation of removeWhere/retainWhere is more efficient
    // than the default in ListBase. Child nodes can be removed in constant
    // time.
    Node child = _this.firstChild;
    while (child != null) {
      Node nextChild = child.nextNode;
      if (test(child) == removeMatching) {
        _this._removeChild(child);
      }
      child = nextChild;
    }
  }

  void removeWhere(bool test(Node node)) {
    _filter(test, true);
  }

  void retainWhere(bool test(Node node)) {
    _filter(test, false);
  }

  void clear() {
    _this._clearChildren();
  }

  void operator []=(int index, Node value) {
    _this._replaceChild(value, this[index]);
  }

  Iterator<Node> get iterator => _this.childNodes.iterator;

  // From List<Node>:

  // TODO(jacobr): this could be implemented for child node lists.
  // The exception we throw here is misleading.
  void sort([Comparator<Node> compare]) {
    throw new UnsupportedError("Cannot sort Node list");
  }

  void shuffle([Random random]) {
    throw new UnsupportedError("Cannot shuffle Node list");
  }

  // FIXME: implement these.
  void setRange(int start, int end, Iterable<Node> iterable,
                [int skipCount = 0]) {
    throw new UnsupportedError("Cannot setRange on Node list");
  }

  void fillRange(int start, int end, [Node fill]) {
    throw new UnsupportedError("Cannot fillRange on Node list");
  }
  // -- end List<Node> mixins.

  // TODO(jacobr): benchmark whether this is more efficient or whether caching
  // a local copy of childNodes is more efficient.
  int get length => _this.childNodes.length;

  set length(int value) {
    throw new UnsupportedError(
        "Cannot set length on immutable List.");
  }

  Node operator[](int index) => _this.childNodes[index];

  List<Node> get rawList => _this.childNodes;
}


@DomName('Node')
@Native("Node")
class Node extends EventTarget {

  // Custom element created callback.
  Node._created() : super._created();

  /**
   * A modifiable list of this node's children.
   */
  List<Node> get nodes {
    return new _ChildNodeListLazy(this);
  }

  set nodes(Iterable<Node> value) {
    // Copy list first since we don't want liveness during iteration.
    // TODO(jacobr): there is a better way to do this.
    List copy = new List.from(value);
    text = '';
    for (Node node in copy) {
      append(node);
    }
  }

  /**
   * Removes this node from the DOM.
   */
  @DomName('Node.removeChild')
  void remove() {
    // TODO(jacobr): should we throw an exception if parent is already null?
    // TODO(vsm): Use the native remove when available.
    if (this.parentNode != null) {
      final Node parent = this.parentNode;
      parentNode._removeChild(this);
    }
  }

  /**
   * Replaces this node with another node.
   */
  @DomName('Node.replaceChild')
  Node replaceWith(Node otherNode) {
    try {
      final Node parent = this.parentNode;
      parent._replaceChild(otherNode, this);
    } catch (e) {

    };
    return this;
  }

  /**
   * Inserts all of the nodes into this node directly before refChild.
   *
   * See also:
   *
   * * [insertBefore]
   */
  Node insertAllBefore(Iterable<Node> newNodes, Node refChild) {
    if (newNodes is _ChildNodeListLazy) {
      _ChildNodeListLazy otherList = newNodes;
      if (identical(otherList._this, this)) {
        throw new ArgumentError(newNodes);
      }

      // Optimized route for copying between nodes.
      for (var i = 0, len = otherList.length; i < len; ++i) {
        this.insertBefore(otherList._this.firstChild, refChild);
      }
    } else {
      for (var node in newNodes) {
        this.insertBefore(node, refChild);
      }
    }
  }

  void _clearChildren() {
    while (firstChild != null) {
      _removeChild(firstChild);
    }
  }

  /**
   * Print out a String representation of this Node.
   */
  String toString() {
    String value = nodeValue;  // Fetch DOM Node property once.
    return value == null ? super.toString() : value;
  }

  /**
   * A list of this node's children.
   *
   * ## Other resources
   *
   * * [Node.childNodes]
   * (https://developer.mozilla.org/en-US/docs/Web/API/Node.childNodes)
   * from MDN.
   */
  @DomName('Node.childNodes')
  @DocsEditable()
  List<Node> get childNodes => wrap_jso(JS('List', '#.childNodes', this.raw));
  // To suppress missing implicit constructor warnings.
  factory Node._() { throw new UnsupportedError("Not supported"); }


  @Deprecated("Internal Use Only")
  static Node internalCreateNode() {
    return new Node.internal_();
  }

  @Deprecated("Internal Use Only")
  Node.internal_() : super.internal_();


  @DomName('Node.ATTRIBUTE_NODE')
  @DocsEditable()
  static const int ATTRIBUTE_NODE = 2;

  @DomName('Node.CDATA_SECTION_NODE')
  @DocsEditable()
  static const int CDATA_SECTION_NODE = 4;

  @DomName('Node.COMMENT_NODE')
  @DocsEditable()
  static const int COMMENT_NODE = 8;

  @DomName('Node.DOCUMENT_FRAGMENT_NODE')
  @DocsEditable()
  static const int DOCUMENT_FRAGMENT_NODE = 11;

  @DomName('Node.DOCUMENT_NODE')
  @DocsEditable()
  static const int DOCUMENT_NODE = 9;

  @DomName('Node.DOCUMENT_TYPE_NODE')
  @DocsEditable()
  static const int DOCUMENT_TYPE_NODE = 10;

  @DomName('Node.ELEMENT_NODE')
  @DocsEditable()
  static const int ELEMENT_NODE = 1;

  @DomName('Node.ENTITY_NODE')
  @DocsEditable()
  static const int ENTITY_NODE = 6;

  @DomName('Node.ENTITY_REFERENCE_NODE')
  @DocsEditable()
  static const int ENTITY_REFERENCE_NODE = 5;

  @DomName('Node.NOTATION_NODE')
  @DocsEditable()
  static const int NOTATION_NODE = 12;

  @DomName('Node.PROCESSING_INSTRUCTION_NODE')
  @DocsEditable()
  static const int PROCESSING_INSTRUCTION_NODE = 7;

  @DomName('Node.TEXT_NODE')
  @DocsEditable()
  static const int TEXT_NODE = 3;

  @JSName('baseURI')
  @DomName('Node.baseURI')
  @DocsEditable()
  String get baseUri => wrap_jso(JS("String", "#.baseURI", this.raw));

  /**
   * The first child of this node.
   *
   * ## Other resources
   *
   * * [Node.firstChild]
   * (https://developer.mozilla.org/en-US/docs/Web/API/Node.firstChild)
   * from MDN.
   */
  @DomName('Node.firstChild')
  @DocsEditable()
  Node get firstChild => wrap_jso(JS("Node", "#.firstChild", this.raw));

  /**
   * The last child of this node.
   *
   * ## Other resources
   *
   * * [Node.lastChild]
   * (https://developer.mozilla.org/en-US/docs/Web/API/Node.lastChild)
   * from MDN.
   */
  @DomName('Node.lastChild')
  @DocsEditable()
  Node get lastChild => wrap_jso(JS("Node", "#.lastChild", this.raw));

  @JSName('localName')
  @DomName('Node.localName')
  @DocsEditable()
  String get _localName => wrap_jso(JS("String", "#.localName", this.raw));

  @JSName('namespaceURI')
  @DomName('Node.namespaceURI')
  @DocsEditable()
  String get _namespaceUri => wrap_jso(JS("String", "#.namespaceURI", this.raw));

  @JSName('nextSibling')
  /**
   * The next sibling node.
   *
   * ## Other resources
   *
   * * [Node.nextSibling]
   * (https://developer.mozilla.org/en-US/docs/Web/API/Node.nextSibling)
   * from MDN.
   */
  @DomName('Node.nextSibling')
  @DocsEditable()
  Node get nextNode => wrap_jso(JS("Node", "#.nextSibling", this.raw));

  /**
   * The name of this node.
   *
   * This varies by this node's [nodeType].
   *
   * ## Other resources
   *
   * * [Node.nodeName]
   * (https://developer.mozilla.org/en-US/docs/Web/API/Node.nodeName)
   * from MDN. This page contains a table of [nodeName] values for each
   * [nodeType].
   */
  @DomName('Node.nodeName')
  @DocsEditable()
  String get nodeName => wrap_jso(JS("String", "#.nodeName", this.raw));

  /**
   * The type of node.
   *
   * This value is one of:
   *
   * * [ATTRIBUTE_NODE] if this node is an attribute.
   * * [CDATA_SECTION_NODE] if this node is a [CDataSection].
   * * [COMMENT_NODE] if this node is a [Comment].
   * * [DOCUMENT_FRAGMENT_NODE] if this node is a [DocumentFragment].
   * * [DOCUMENT_NODE] if this node is a [Document].
   * * [DOCUMENT_TYPE_NODE] if this node is a [DocumentType] node.
   * * [ELEMENT_NODE] if this node is an [Element].
   * * [ENTITY_NODE] if this node is an entity.
   * * [ENTITY_REFERENCE_NODE] if this node is an entity reference.
   * * [NOTATION_NODE] if this node is a notation.
   * * [PROCESSING_INSTRUCTION_NODE] if this node is a [ProcessingInstruction].
   * * [TEXT_NODE] if this node is a [Text] node.
   *
   * ## Other resources
   *
   * * [Node.nodeType]
   * (https://developer.mozilla.org/en-US/docs/Web/API/Node.nodeType) from MDN.
   */
  @DomName('Node.nodeType')
  @DocsEditable()
  int get nodeType => wrap_jso(JS("int", "#.nodeType", this.raw));

  /**
   * The value of this node.
   *
   * This varies by this type's [nodeType].
   *
   * ## Other resources
   *
   * * [Node.nodeValue]
   * (https://developer.mozilla.org/en-US/docs/Web/API/Node.nodeValue)
   * from MDN. This page contains a table of [nodeValue] values for each
   * [nodeType].
   */
  @DomName('Node.nodeValue')
  @DocsEditable()
  String get nodeValue => wrap_jso(JS("String", "#.nodeValue", this.raw));

  /**
   * The document this node belongs to.
   *
   * Returns null if this node does not belong to any document.
   *
   * ## Other resources
   *
   * * [Node.ownerDocument]
   * (https://developer.mozilla.org/en-US/docs/Web/API/Node.ownerDocument) from
   * MDN.
   */
  @DomName('Node.ownerDocument')
  @DocsEditable()
  Document get ownerDocument => wrap_jso(JS("Document", "#.ownerDocument", this.raw));

  @JSName('parentElement')
  /**
   * The parent element of this node.
   *
   * Returns null if this node either does not have a parent or its parent is
   * not an element.
   *
   * ## Other resources
   *
   * * [Node.parentElement]
   * (https://developer.mozilla.org/en-US/docs/Web/API/Node.parentElement) from
   * W3C.
   */
  @DomName('Node.parentElement')
  @DocsEditable()
  Element get parent => wrap_jso(JS("Element", "#.parentElement", this.raw));

  /**
   * The parent node of this node.
   *
   * ## Other resources
   *
   * * [Node.parentNode]
   * (https://developer.mozilla.org/en-US/docs/Web/API/Node.parentNode) from
   * MDN.
   */
  @DomName('Node.parentNode')
  @DocsEditable()
  Node get parentNode => wrap_jso(JS("Node", "#.parentNode", this.raw));

  @JSName('previousSibling')
  /**
   * The previous sibling node.
   *
   * ## Other resources
   *
   * * [Node.previousSibling]
   * (https://developer.mozilla.org/en-US/docs/Web/API/Node.previousSibling)
   * from MDN.
   */
  @DomName('Node.previousSibling')
  @DocsEditable()
  Node get previousNode => wrap_jso(JS("Node", "#.previousSibling", this.raw));

  @JSName('textContent')
  /**
   * All text within this node and its decendents.
   *
   * ## Other resources
   *
   * * [Node.textContent]
   * (https://developer.mozilla.org/en-US/docs/Web/API/Node.textContent) from
   * MDN.
   */
  @DomName('Node.textContent')
  @DocsEditable()
  String get text => wrap_jso(JS("String", "#.textContent", this.raw));
  @JSName('textContent')
  /**
   * All text within this node and its decendents.
   *
   * ## Other resources
   *
   * * [Node.textContent]
   * (https://developer.mozilla.org/en-US/docs/Web/API/Node.textContent) from
   * MDN.
   */
  @DomName('Node.textContent')
  @DocsEditable()
  void set text(String val) => JS("void", "#.textContent = #", this.raw, unwrap_jso(val));

  /**
   * Adds a node to the end of the child [nodes] list of this node.
   *
   * If the node already exists in this document, it will be removed from its
   * current parent node, then added to this node.
   *
   * This method is more efficient than `nodes.add`, and is the preferred
   * way of appending a child node.
   */
  @DomName('Node.appendChild')
  @DocsEditable()
  Node append(Node newChild) {
    return _append_1(newChild);
  }
  @JSName('appendChild')
  /**
   * Adds a node to the end of the child [nodes] list of this node.
   *
   * If the node already exists in this document, it will be removed from its
   * current parent node, then added to this node.
   *
   * This method is more efficient than `nodes.add`, and is the preferred
   * way of appending a child node.
   */
  @DomName('Node.appendChild')
  @DocsEditable()
  Node _append_1(Node newChild) => wrap_jso(JS("Node ", "#.raw.appendChild(#)", this, unwrap_jso(newChild)));

  /**
   * Returns a copy of this node.
   *
   * If [deep] is `true`, then all of this node's children and decendents are
   * copied as well. If [deep] is `false`, then only this node is copied.
   *
   * ## Other resources
   *
   * * [Node.cloneNode]
   * (https://developer.mozilla.org/en-US/docs/Web/API/Node.cloneNode) from
   * MDN.
   */
  @DomName('Node.cloneNode')
  @DocsEditable()
  Node clone(bool deep) {
    return _clone_1(deep);
  }
  @JSName('cloneNode')
  /**
   * Returns a copy of this node.
   *
   * If [deep] is `true`, then all of this node's children and decendents are
   * copied as well. If [deep] is `false`, then only this node is copied.
   *
   * ## Other resources
   *
   * * [Node.cloneNode]
   * (https://developer.mozilla.org/en-US/docs/Web/API/Node.cloneNode) from
   * MDN.
   */
  @DomName('Node.cloneNode')
  @DocsEditable()
  Node _clone_1(deep) => wrap_jso(JS("Node ", "#.raw.cloneNode(#)", this, unwrap_jso(deep)));

  /**
   * Returns true if this node contains the specified node.
   *
   * ## Other resources
   *
   * * [Node.contains]
   * (https://developer.mozilla.org/en-US/docs/Web/API/Node.contains) from MDN.
   */
  @DomName('Node.contains')
  @DocsEditable()
  bool contains(Node other) {
    return _contains_1(other);
  }
  @JSName('contains')
  /**
   * Returns true if this node contains the specified node.
   *
   * ## Other resources
   *
   * * [Node.contains]
   * (https://developer.mozilla.org/en-US/docs/Web/API/Node.contains) from MDN.
   */
  @DomName('Node.contains')
  @DocsEditable()
  bool _contains_1(Node other) => wrap_jso(JS("bool ", "#.raw.contains(#)", this, unwrap_jso(other)));

  /**
   * Returns true if this node has any children.
   *
   * ## Other resources
   *
   * * [Node.hasChildNodes]
   * (https://developer.mozilla.org/en-US/docs/Web/API/Node.hasChildNodes) from
   * MDN.
   */
  @DomName('Node.hasChildNodes')
  @DocsEditable()
  bool hasChildNodes() {
    return _hasChildNodes_1();
  }
  @JSName('hasChildNodes')
  /**
   * Returns true if this node has any children.
   *
   * ## Other resources
   *
   * * [Node.hasChildNodes]
   * (https://developer.mozilla.org/en-US/docs/Web/API/Node.hasChildNodes) from
   * MDN.
   */
  @DomName('Node.hasChildNodes')
  @DocsEditable()
  bool _hasChildNodes_1() => wrap_jso(JS("bool ", "#.raw.hasChildNodes()", this));

  /**
   * Inserts all of the nodes into this node directly before refChild.
   *
   * ## Other resources
   *
   * * [Node.insertBefore]
   * (https://developer.mozilla.org/en-US/docs/Web/API/Node.insertBefore) from
   * MDN.
   */
  @DomName('Node.insertBefore')
  @DocsEditable()
  Node insertBefore(Node newChild, Node refChild) {
    return _insertBefore_1(newChild, refChild);
  }
  @JSName('insertBefore')
  /**
   * Inserts all of the nodes into this node directly before refChild.
   *
   * ## Other resources
   *
   * * [Node.insertBefore]
   * (https://developer.mozilla.org/en-US/docs/Web/API/Node.insertBefore) from
   * MDN.
   */
  @DomName('Node.insertBefore')
  @DocsEditable()
  Node _insertBefore_1(Node newChild, Node refChild) => wrap_jso(JS("Node ", "#.raw.insertBefore(#, #)", this, unwrap_jso(newChild), unwrap_jso(refChild)));

  @DomName('Node.removeChild')
  @DocsEditable()
  Node _removeChild(Node oldChild) {
    return _removeChild_1(oldChild);
  }
  @JSName('removeChild')
  @DomName('Node.removeChild')
  @DocsEditable()
  Node _removeChild_1(Node oldChild) => wrap_jso(JS("Node ", "#.raw.removeChild(#)", this, unwrap_jso(oldChild)));

  @DomName('Node.replaceChild')
  @DocsEditable()
  Node _replaceChild(Node newChild, Node oldChild) {
    return _replaceChild_1(newChild, oldChild);
  }
  @JSName('replaceChild')
  @DomName('Node.replaceChild')
  @DocsEditable()
  Node _replaceChild_1(Node newChild, Node oldChild) => wrap_jso(JS("Node ", "#.raw.replaceChild(#, #)", this, unwrap_jso(newChild), unwrap_jso(oldChild)));

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('NodeList')
@Native("NodeList,RadioNodeList")
class NodeList extends DartHtmlDomObject with ListMixin<Node>, ImmutableListMixin<Node> implements JavaScriptIndexingBehavior, List<Node> {
  // To suppress missing implicit constructor warnings.
  factory NodeList._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static NodeList internalCreateNodeList() {
    return new NodeList.internal_();
  }

  @Deprecated("Internal Use Only")
  NodeList.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

  @DomName('NodeList.length')
  @DocsEditable()
  int get length => wrap_jso(JS("int", "#.length", this.raw));

  Node operator[](int index) {
    if (JS("bool", "# >>> 0 !== # || # >= #", index,
        index, index, length))
      throw new RangeError.index(index, this);
    return wrap_jso(JS("Node", "#[#]", this.raw, index));
  }
  void operator[]=(int index, Node value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Node> mixins.
  // Node is the element type.


  set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  Node get first {
    if (this.length > 0) {
      return wrap_jso(JS('Node', '#[0]', this.raw));
    }
    throw new StateError("No elements");
  }

  Node get last {
    int len = this.length;
    if (len > 0) {
      return wrap_jso(JS('Node', '#[#]', this.raw, len - 1));
    }
    throw new StateError("No elements");
  }

  Node get single {
    int len = this.length;
    if (len == 1) {
      return wrap_jso(JS('Node', '#[0]', this.raw));
    }
    if (len == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  Node elementAt(int index) => this[index];
  // -- end List<Node> mixins.

  @DomName('NodeList.item')
  @DocsEditable()
  Node _item(int index) {
    return _item_1(index);
  }
  @JSName('item')
  @DomName('NodeList.item')
  @DocsEditable()
  Node _item_1(index) => wrap_jso(JS("Node ", "#.raw.item(#)", this, unwrap_jso(index)));
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('ParentNode')
@Experimental() // untriaged
abstract class ParentNode extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory ParentNode._() { throw new UnsupportedError("Not supported"); }

  int get _childElementCount => wrap_jso(JS("int", "#.childElementCount", this.raw));

  List<Node> get _children => wrap_jso(JS("List<Node>", "#.children", this.raw));

  Element get _firstElementChild => wrap_jso(JS("Element", "#.firstElementChild", this.raw));

  Element get _lastElementChild => wrap_jso(JS("Element", "#.lastElementChild", this.raw));

  Element querySelector(String selectors) => wrap_jso(JS("Element", "#.raw.querySelector(#)", this, unwrap_jso(selectors)));

  List<Node> _querySelectorAll(String selectors) => wrap_jso(JS("List<Node>", "#.raw.querySelectorAll(#)", this, unwrap_jso(selectors)));
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('ProgressEvent')
@Native("ProgressEvent")
class ProgressEvent extends Event {
  // To suppress missing implicit constructor warnings.
  factory ProgressEvent._() { throw new UnsupportedError("Not supported"); }


  @Deprecated("Internal Use Only")
  static ProgressEvent internalCreateProgressEvent() {
    return new ProgressEvent.internal_();
  }

  @Deprecated("Internal Use Only")
  ProgressEvent.internal_() : super.internal_();


  @DomName('ProgressEvent.lengthComputable')
  @DocsEditable()
  bool get lengthComputable => wrap_jso(JS("bool", "#.lengthComputable", this.raw));

  @DomName('ProgressEvent.loaded')
  @DocsEditable()
  int get loaded => wrap_jso(JS("int", "#.loaded", this.raw));

  @DomName('ProgressEvent.total')
  @DocsEditable()
  int get total => wrap_jso(JS("int", "#.total", this.raw));
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DomName('Range')
@Unstable()
@Native("Range")
class Range extends DartHtmlDomObject {
  factory Range() => document.createRange();

  factory Range.fromPoint(Point point) =>
      document._caretRangeFromPoint(point.x, point.y);
  // To suppress missing implicit constructor warnings.
  factory Range._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static Range internalCreateRange() {
    return new Range.internal_();
  }

  @Deprecated("Internal Use Only")
  Range.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

  @DomName('Range.END_TO_END')
  @DocsEditable()
  static const int END_TO_END = 2;

  @DomName('Range.END_TO_START')
  @DocsEditable()
  static const int END_TO_START = 3;

  @DomName('Range.NODE_AFTER')
  @DocsEditable()
  @Experimental() // nonstandard
  static const int NODE_AFTER = 1;

  @DomName('Range.NODE_BEFORE')
  @DocsEditable()
  @Experimental() // nonstandard
  static const int NODE_BEFORE = 0;

  @DomName('Range.NODE_BEFORE_AND_AFTER')
  @DocsEditable()
  @Experimental() // nonstandard
  static const int NODE_BEFORE_AND_AFTER = 2;

  @DomName('Range.NODE_INSIDE')
  @DocsEditable()
  @Experimental() // nonstandard
  static const int NODE_INSIDE = 3;

  @DomName('Range.START_TO_END')
  @DocsEditable()
  static const int START_TO_END = 1;

  @DomName('Range.START_TO_START')
  @DocsEditable()
  static const int START_TO_START = 0;

  @DomName('Range.collapsed')
  @DocsEditable()
  bool get collapsed => wrap_jso(JS("bool", "#.collapsed", this.raw));

  @DomName('Range.commonAncestorContainer')
  @DocsEditable()
  Node get commonAncestorContainer => wrap_jso(JS("Node", "#.commonAncestorContainer", this.raw));

  @DomName('Range.endContainer')
  @DocsEditable()
  Node get endContainer => wrap_jso(JS("Node", "#.endContainer", this.raw));

  @DomName('Range.endOffset')
  @DocsEditable()
  int get endOffset => wrap_jso(JS("int", "#.endOffset", this.raw));

  @DomName('Range.startContainer')
  @DocsEditable()
  Node get startContainer => wrap_jso(JS("Node", "#.startContainer", this.raw));

  @DomName('Range.startOffset')
  @DocsEditable()
  int get startOffset => wrap_jso(JS("int", "#.startOffset", this.raw));

  @DomName('Range.cloneContents')
  @DocsEditable()
  DocumentFragment cloneContents() {
    return _cloneContents_1();
  }
  @JSName('cloneContents')
  @DomName('Range.cloneContents')
  @DocsEditable()
  DocumentFragment _cloneContents_1() => wrap_jso(JS("DocumentFragment ", "#.raw.cloneContents()", this));

  @DomName('Range.cloneRange')
  @DocsEditable()
  Range cloneRange() {
    return _cloneRange_1();
  }
  @JSName('cloneRange')
  @DomName('Range.cloneRange')
  @DocsEditable()
  Range _cloneRange_1() => wrap_jso(JS("Range ", "#.raw.cloneRange()", this));

  @DomName('Range.collapse')
  @DocsEditable()
  void collapse([bool toStart]) {
    if (toStart != null) {
      _collapse_1(toStart);
      return;
    }
    _collapse_2();
    return;
  }
  @JSName('collapse')
  @DomName('Range.collapse')
  @DocsEditable()
  void _collapse_1(toStart) => wrap_jso(JS("void ", "#.raw.collapse(#)", this, unwrap_jso(toStart)));
  @JSName('collapse')
  @DomName('Range.collapse')
  @DocsEditable()
  void _collapse_2() => wrap_jso(JS("void ", "#.raw.collapse()", this));

  @DomName('Range.compareBoundaryPoints')
  @DocsEditable()
  @Experimental() // untriaged
  int compareBoundaryPoints(int how, Range sourceRange) {
    return _compareBoundaryPoints_1(how, sourceRange);
  }
  @JSName('compareBoundaryPoints')
  @DomName('Range.compareBoundaryPoints')
  @DocsEditable()
  @Experimental() // untriaged
  int _compareBoundaryPoints_1(how, Range sourceRange) => wrap_jso(JS("int ", "#.raw.compareBoundaryPoints(#, #)", this, unwrap_jso(how), unwrap_jso(sourceRange)));

  @DomName('Range.comparePoint')
  @DocsEditable()
  int comparePoint(Node refNode, int offset) {
    return _comparePoint_1(refNode, offset);
  }
  @JSName('comparePoint')
  @DomName('Range.comparePoint')
  @DocsEditable()
  int _comparePoint_1(Node refNode, offset) => wrap_jso(JS("int ", "#.raw.comparePoint(#, #)", this, unwrap_jso(refNode), unwrap_jso(offset)));

  @DomName('Range.createContextualFragment')
  @DocsEditable()
  DocumentFragment createContextualFragment(String html) {
    return _createContextualFragment_1(html);
  }
  @JSName('createContextualFragment')
  @DomName('Range.createContextualFragment')
  @DocsEditable()
  DocumentFragment _createContextualFragment_1(html) => wrap_jso(JS("DocumentFragment ", "#.raw.createContextualFragment(#)", this, unwrap_jso(html)));

  @DomName('Range.deleteContents')
  @DocsEditable()
  void deleteContents() {
    _deleteContents_1();
    return;
  }
  @JSName('deleteContents')
  @DomName('Range.deleteContents')
  @DocsEditable()
  void _deleteContents_1() => wrap_jso(JS("void ", "#.raw.deleteContents()", this));

  @DomName('Range.detach')
  @DocsEditable()
  void detach() {
    _detach_1();
    return;
  }
  @JSName('detach')
  @DomName('Range.detach')
  @DocsEditable()
  void _detach_1() => wrap_jso(JS("void ", "#.raw.detach()", this));

  @DomName('Range.expand')
  @DocsEditable()
  @Experimental() // non-standard
  void expand(String unit) {
    _expand_1(unit);
    return;
  }
  @JSName('expand')
  @DomName('Range.expand')
  @DocsEditable()
  @Experimental() // non-standard
  void _expand_1(unit) => wrap_jso(JS("void ", "#.raw.expand(#)", this, unwrap_jso(unit)));

  @DomName('Range.extractContents')
  @DocsEditable()
  DocumentFragment extractContents() {
    return _extractContents_1();
  }
  @JSName('extractContents')
  @DomName('Range.extractContents')
  @DocsEditable()
  DocumentFragment _extractContents_1() => wrap_jso(JS("DocumentFragment ", "#.raw.extractContents()", this));

  @DomName('Range.getBoundingClientRect')
  @DocsEditable()
  Rectangle getBoundingClientRect() {
    return _getBoundingClientRect_1();
  }
  @JSName('getBoundingClientRect')
  @DomName('Range.getBoundingClientRect')
  @DocsEditable()
  Rectangle _getBoundingClientRect_1() => wrap_jso(JS("Rectangle ", "#.raw.getBoundingClientRect()", this));

  @DomName('Range.insertNode')
  @DocsEditable()
  void insertNode(Node newNode) {
    _insertNode_1(newNode);
    return;
  }
  @JSName('insertNode')
  @DomName('Range.insertNode')
  @DocsEditable()
  void _insertNode_1(Node newNode) => wrap_jso(JS("void ", "#.raw.insertNode(#)", this, unwrap_jso(newNode)));

  @DomName('Range.isPointInRange')
  @DocsEditable()
  bool isPointInRange(Node refNode, int offset) {
    return _isPointInRange_1(refNode, offset);
  }
  @JSName('isPointInRange')
  @DomName('Range.isPointInRange')
  @DocsEditable()
  bool _isPointInRange_1(Node refNode, offset) => wrap_jso(JS("bool ", "#.raw.isPointInRange(#, #)", this, unwrap_jso(refNode), unwrap_jso(offset)));

  @DomName('Range.selectNode')
  @DocsEditable()
  void selectNode(Node refNode) {
    _selectNode_1(refNode);
    return;
  }
  @JSName('selectNode')
  @DomName('Range.selectNode')
  @DocsEditable()
  void _selectNode_1(Node refNode) => wrap_jso(JS("void ", "#.raw.selectNode(#)", this, unwrap_jso(refNode)));

  @DomName('Range.selectNodeContents')
  @DocsEditable()
  void selectNodeContents(Node refNode) {
    _selectNodeContents_1(refNode);
    return;
  }
  @JSName('selectNodeContents')
  @DomName('Range.selectNodeContents')
  @DocsEditable()
  void _selectNodeContents_1(Node refNode) => wrap_jso(JS("void ", "#.raw.selectNodeContents(#)", this, unwrap_jso(refNode)));

  @DomName('Range.setEnd')
  @DocsEditable()
  void setEnd(Node refNode, int offset) {
    _setEnd_1(refNode, offset);
    return;
  }
  @JSName('setEnd')
  @DomName('Range.setEnd')
  @DocsEditable()
  void _setEnd_1(Node refNode, offset) => wrap_jso(JS("void ", "#.raw.setEnd(#, #)", this, unwrap_jso(refNode), unwrap_jso(offset)));

  @DomName('Range.setEndAfter')
  @DocsEditable()
  void setEndAfter(Node refNode) {
    _setEndAfter_1(refNode);
    return;
  }
  @JSName('setEndAfter')
  @DomName('Range.setEndAfter')
  @DocsEditable()
  void _setEndAfter_1(Node refNode) => wrap_jso(JS("void ", "#.raw.setEndAfter(#)", this, unwrap_jso(refNode)));

  @DomName('Range.setEndBefore')
  @DocsEditable()
  void setEndBefore(Node refNode) {
    _setEndBefore_1(refNode);
    return;
  }
  @JSName('setEndBefore')
  @DomName('Range.setEndBefore')
  @DocsEditable()
  void _setEndBefore_1(Node refNode) => wrap_jso(JS("void ", "#.raw.setEndBefore(#)", this, unwrap_jso(refNode)));

  @DomName('Range.setStart')
  @DocsEditable()
  void setStart(Node refNode, int offset) {
    _setStart_1(refNode, offset);
    return;
  }
  @JSName('setStart')
  @DomName('Range.setStart')
  @DocsEditable()
  void _setStart_1(Node refNode, offset) => wrap_jso(JS("void ", "#.raw.setStart(#, #)", this, unwrap_jso(refNode), unwrap_jso(offset)));

  @DomName('Range.setStartAfter')
  @DocsEditable()
  void setStartAfter(Node refNode) {
    _setStartAfter_1(refNode);
    return;
  }
  @JSName('setStartAfter')
  @DomName('Range.setStartAfter')
  @DocsEditable()
  void _setStartAfter_1(Node refNode) => wrap_jso(JS("void ", "#.raw.setStartAfter(#)", this, unwrap_jso(refNode)));

  @DomName('Range.setStartBefore')
  @DocsEditable()
  void setStartBefore(Node refNode) {
    _setStartBefore_1(refNode);
    return;
  }
  @JSName('setStartBefore')
  @DomName('Range.setStartBefore')
  @DocsEditable()
  void _setStartBefore_1(Node refNode) => wrap_jso(JS("void ", "#.raw.setStartBefore(#)", this, unwrap_jso(refNode)));

  @DomName('Range.surroundContents')
  @DocsEditable()
  void surroundContents(Node newParent) {
    _surroundContents_1(newParent);
    return;
  }
  @JSName('surroundContents')
  @DomName('Range.surroundContents')
  @DocsEditable()
  void _surroundContents_1(Node newParent) => wrap_jso(JS("void ", "#.raw.surroundContents(#)", this, unwrap_jso(newParent)));


  /**
   * Checks if createContextualFragment is supported.
   *
   * See also:
   *
   * * [createContextualFragment]
   */
  static bool get supportsCreateContextualFragment => true;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DomName('RequestAnimationFrameCallback')
typedef void RequestAnimationFrameCallback(num highResTime);
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('Screen')
@Native("Screen")
class Screen extends DartHtmlDomObject {

  @DomName('Screen.availHeight')
  @DomName('Screen.availLeft')
  @DomName('Screen.availTop')
  @DomName('Screen.availWidth')
  Rectangle get available => new Rectangle(_availLeft, _availTop, _availWidth,
      _availHeight);
  // To suppress missing implicit constructor warnings.
  factory Screen._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static Screen internalCreateScreen() {
    return new Screen.internal_();
  }

  @Deprecated("Internal Use Only")
  Screen.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

  @JSName('availHeight')
  @DomName('Screen.availHeight')
  @DocsEditable()
  int get _availHeight => wrap_jso(JS("int", "#.availHeight", this.raw));

  @JSName('availLeft')
  @DomName('Screen.availLeft')
  @DocsEditable()
  @Experimental() // nonstandard
  int get _availLeft => wrap_jso(JS("int", "#.availLeft", this.raw));

  @JSName('availTop')
  @DomName('Screen.availTop')
  @DocsEditable()
  @Experimental() // nonstandard
  int get _availTop => wrap_jso(JS("int", "#.availTop", this.raw));

  @JSName('availWidth')
  @DomName('Screen.availWidth')
  @DocsEditable()
  int get _availWidth => wrap_jso(JS("int", "#.availWidth", this.raw));

  @DomName('Screen.colorDepth')
  @DocsEditable()
  int get colorDepth => wrap_jso(JS("int", "#.colorDepth", this.raw));

  @DomName('Screen.height')
  @DocsEditable()
  int get height => wrap_jso(JS("int", "#.height", this.raw));

  @DomName('Screen.pixelDepth')
  @DocsEditable()
  int get pixelDepth => wrap_jso(JS("int", "#.pixelDepth", this.raw));

  @DomName('Screen.width')
  @DocsEditable()
  int get width => wrap_jso(JS("int", "#.width", this.raw));
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DomName('ShadowRoot')
@SupportedBrowser(SupportedBrowser.CHROME, '26')
@Experimental()
// https://dvcs.w3.org/hg/webcomponents/raw-file/tip/spec/shadow/index.html#api-shadow-root
@Native("ShadowRoot")
class ShadowRoot extends DocumentFragment {
  // To suppress missing implicit constructor warnings.
  factory ShadowRoot._() { throw new UnsupportedError("Not supported"); }


  @Deprecated("Internal Use Only")
  static ShadowRoot internalCreateShadowRoot() {
    return new ShadowRoot.internal_();
  }

  @Deprecated("Internal Use Only")
  ShadowRoot.internal_() : super.internal_();


  @DomName('ShadowRoot.activeElement')
  @DocsEditable()
  Element get activeElement => wrap_jso(JS("Element", "#.activeElement", this.raw));

  @DomName('ShadowRoot.host')
  @DocsEditable()
  @Experimental() // untriaged
  Element get host => wrap_jso(JS("Element", "#.host", this.raw));

  @JSName('innerHTML')
  @DomName('ShadowRoot.innerHTML')
  @DocsEditable()
  String get innerHtml => wrap_jso(JS("String", "#.innerHTML", this.raw));
  @JSName('innerHTML')
  @DomName('ShadowRoot.innerHTML')
  @DocsEditable()
  void set innerHtml(String val) => JS("void", "#.innerHTML = #", this.raw, unwrap_jso(val));

  @DomName('ShadowRoot.olderShadowRoot')
  @DocsEditable()
  @Experimental() // untriaged
  ShadowRoot get olderShadowRoot => wrap_jso(JS("ShadowRoot", "#.olderShadowRoot", this.raw));

  @DomName('ShadowRoot.cloneNode')
  @DocsEditable()
  Node clone(bool deep) {
    return _clone_1(deep);
  }
  @JSName('cloneNode')
  @DomName('ShadowRoot.cloneNode')
  @DocsEditable()
  Node _clone_1(deep) => wrap_jso(JS("Node ", "#.raw.cloneNode(#)", this, unwrap_jso(deep)));

  @DomName('ShadowRoot.elementFromPoint')
  @DocsEditable()
  Element elementFromPoint(int x, int y) {
    return _elementFromPoint_1(x, y);
  }
  @JSName('elementFromPoint')
  @DomName('ShadowRoot.elementFromPoint')
  @DocsEditable()
  Element _elementFromPoint_1(x, y) => wrap_jso(JS("Element ", "#.raw.elementFromPoint(#, #)", this, unwrap_jso(x), unwrap_jso(y)));

  @DomName('ShadowRoot.getElementsByClassName')
  @DocsEditable()
  @Creates('NodeList|HtmlCollection')
  @Returns('NodeList|HtmlCollection')
  HtmlCollection getElementsByClassName(String className) {
    return _getElementsByClassName_1(className);
  }
  @JSName('getElementsByClassName')
  @DomName('ShadowRoot.getElementsByClassName')
  @DocsEditable()
  @Creates('NodeList|HtmlCollection')
  @Returns('NodeList|HtmlCollection')
  HtmlCollection _getElementsByClassName_1(className) => wrap_jso(JS("HtmlCollection ", "#.raw.getElementsByClassName(#)", this, unwrap_jso(className)));

  @DomName('ShadowRoot.getElementsByTagName')
  @DocsEditable()
  @Creates('NodeList|HtmlCollection')
  @Returns('NodeList|HtmlCollection')
  HtmlCollection getElementsByTagName(String tagName) {
    return _getElementsByTagName_1(tagName);
  }
  @JSName('getElementsByTagName')
  @DomName('ShadowRoot.getElementsByTagName')
  @DocsEditable()
  @Creates('NodeList|HtmlCollection')
  @Returns('NodeList|HtmlCollection')
  HtmlCollection _getElementsByTagName_1(tagName) => wrap_jso(JS("HtmlCollection ", "#.raw.getElementsByTagName(#)", this, unwrap_jso(tagName)));

  static final bool supported = true;

  static bool _shadowRootDeprecationReported = false;
  static void _shadowRootDeprecationReport() {
    if (!_shadowRootDeprecationReported) {
      window.console.warn('''
ShadowRoot.resetStyleInheritance and ShadowRoot.applyAuthorStyles now deprecated in dart:html.
Please remove them from your code.
''');
      _shadowRootDeprecationReported = true;
    }
  }

  @deprecated
  bool get resetStyleInheritance {
    _shadowRootDeprecationReport();
    // Default value from when it was specified.
    return false;
  }

  @deprecated
  set resetStyleInheritance(bool value) {
    _shadowRootDeprecationReport();
  }

  @deprecated
  bool get applyAuthorStyles {
    _shadowRootDeprecationReport();
    // Default value from when it was specified.
    return false;
  }

  @deprecated
  set applyAuthorStyles(bool value) {
    _shadowRootDeprecationReport();
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('HTMLStyleElement')
@Native("HTMLStyleElement")
class StyleElement extends HtmlElement {
  // To suppress missing implicit constructor warnings.
  factory StyleElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('HTMLStyleElement.HTMLStyleElement')
  @DocsEditable()
  factory StyleElement() => document.createElement("style");


  @Deprecated("Internal Use Only")
  static StyleElement internalCreateStyleElement() {
    return new StyleElement.internal_();
  }

  @Deprecated("Internal Use Only")
  StyleElement.internal_() : super.internal_();


  @DomName('HTMLStyleElement.disabled')
  @DocsEditable()
  bool get disabled => wrap_jso(JS("bool", "#.disabled", this.raw));
  @DomName('HTMLStyleElement.disabled')
  @DocsEditable()
  void set disabled(bool val) => JS("void", "#.disabled = #", this.raw, unwrap_jso(val));

  @DomName('HTMLStyleElement.media')
  @DocsEditable()
  String get media => wrap_jso(JS("String", "#.media", this.raw));
  @DomName('HTMLStyleElement.media')
  @DocsEditable()
  void set media(String val) => JS("void", "#.media = #", this.raw, unwrap_jso(val));

  @DomName('HTMLStyleElement.type')
  @DocsEditable()
  String get type => wrap_jso(JS("String", "#.type", this.raw));
  @DomName('HTMLStyleElement.type')
  @DocsEditable()
  void set type(String val) => JS("void", "#.type = #", this.raw, unwrap_jso(val));
}
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@Experimental()
@DomName('HTMLTemplateElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@Experimental()
// https://dvcs.w3.org/hg/webcomponents/raw-file/tip/spec/templates/index.html#template-element
@Native("HTMLTemplateElement")
class TemplateElement extends HtmlElement {
  // To suppress missing implicit constructor warnings.
  factory TemplateElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('HTMLTemplateElement.HTMLTemplateElement')
  @DocsEditable()
  factory TemplateElement() => document.createElement("template");


  @Deprecated("Internal Use Only")
  static TemplateElement internalCreateTemplateElement() {
    return new TemplateElement.internal_();
  }

  @Deprecated("Internal Use Only")
  TemplateElement.internal_() : super.internal_();


  /// Checks if this type is supported on the current platform.
  static bool get supported => Element.isTagSupported('template');

  @DomName('HTMLTemplateElement.content')
  @DocsEditable()
  DocumentFragment get content => wrap_jso(JS("DocumentFragment", "#.content", this.raw));


  /**
   * An override to place the contents into content rather than as child nodes.
   *
   * See also:
   *
   * * <https://dvcs.w3.org/hg/webcomponents/raw-file/tip/spec/templates/index.html#innerhtml-on-templates>
   */
  void setInnerHtml(String html,
    {NodeValidator validator, NodeTreeSanitizer treeSanitizer}) {
    text = null;
    var fragment = createFragment(
        html, validator: validator, treeSanitizer: treeSanitizer);

    content.append(fragment);
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DomName('Text')
@Native("Text")
class Text extends CharacterData {
  factory Text(String data) => document._createTextNode(data);
  // To suppress missing implicit constructor warnings.
  factory Text._() { throw new UnsupportedError("Not supported"); }


  @Deprecated("Internal Use Only")
  static Text internalCreateText() {
    return new Text.internal_();
  }

  @Deprecated("Internal Use Only")
  Text.internal_() : super.internal_();


  @DomName('Text.wholeText')
  @DocsEditable()
  String get wholeText => wrap_jso(JS("String", "#.wholeText", this.raw));

  @DomName('Text.getDestinationInsertionPoints')
  @DocsEditable()
  @Experimental() // untriaged
  @Returns('NodeList')
  @Creates('NodeList')
  NodeList getDestinationInsertionPoints() {
    return _getDestinationInsertionPoints_1();
  }
  @JSName('getDestinationInsertionPoints')
  @DomName('Text.getDestinationInsertionPoints')
  @DocsEditable()
  @Experimental() // untriaged
  @Returns('NodeList')
  @Creates('NodeList')
  NodeList _getDestinationInsertionPoints_1() => wrap_jso(JS("NodeList ", "#.raw.getDestinationInsertionPoints()", this));

  @DomName('Text.splitText')
  @DocsEditable()
  Text splitText(int offset) {
    return _splitText_1(offset);
  }
  @JSName('splitText')
  @DomName('Text.splitText')
  @DocsEditable()
  Text _splitText_1(offset) => wrap_jso(JS("Text ", "#.raw.splitText(#)", this, unwrap_jso(offset)));

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DomName('UIEvent')
@Native("UIEvent")
class UIEvent extends Event {
  // In JS, canBubble and cancelable are technically required parameters to
  // init*Event. In practice, though, if they aren't provided they simply
  // default to false (since that's Boolean(undefined)).
  //
  // Contrary to JS, we default canBubble and cancelable to true, since that's
  // what people want most of the time anyway.
  factory UIEvent(String type,
      {Window view, int detail: 0, bool canBubble: true,
      bool cancelable: true}) {
    if (view == null) {
      view = window;
    }
    UIEvent e = document._createEvent("UIEvent");
    e._initUIEvent(type, canBubble, cancelable, view, detail);
    return e;
  }
  // To suppress missing implicit constructor warnings.
  factory UIEvent._() { throw new UnsupportedError("Not supported"); }


  @Deprecated("Internal Use Only")
  static UIEvent internalCreateUIEvent() {
    return new UIEvent.internal_();
  }

  @Deprecated("Internal Use Only")
  UIEvent.internal_() : super.internal_();


  @JSName('charCode')
  @DomName('UIEvent.charCode')
  @DocsEditable()
  @Unstable()
  int get _charCode => wrap_jso(JS("int", "#.charCode", this.raw));

  @DomName('UIEvent.detail')
  @DocsEditable()
  int get detail => wrap_jso(JS("int", "#.detail", this.raw));

  @JSName('keyCode')
  @DomName('UIEvent.keyCode')
  @DocsEditable()
  @Unstable()
  int get _keyCode => wrap_jso(JS("int", "#.keyCode", this.raw));

  @JSName('layerX')
  @DomName('UIEvent.layerX')
  @DocsEditable()
  // http://dev.w3.org/2006/webapi/DOM-Level-3-Events/html/DOM3-Events.html#events-mouseevents
  @Experimental() // nonstandard
  int get _layerX => wrap_jso(JS("int", "#.layerX", this.raw));

  @JSName('layerY')
  @DomName('UIEvent.layerY')
  @DocsEditable()
  // http://dev.w3.org/2006/webapi/DOM-Level-3-Events/html/DOM3-Events.html#events-mouseevents
  @Experimental() // nonstandard
  int get _layerY => wrap_jso(JS("int", "#.layerY", this.raw));

  @JSName('pageX')
  @DomName('UIEvent.pageX')
  @DocsEditable()
  // http://dev.w3.org/2006/webapi/DOM-Level-3-Events/html/DOM3-Events.html#events-mouseevents
  @Experimental() // nonstandard
  int get _pageX => wrap_jso(JS("int", "#.pageX", this.raw));

  @JSName('pageY')
  @DomName('UIEvent.pageY')
  @DocsEditable()
  // http://dev.w3.org/2006/webapi/DOM-Level-3-Events/html/DOM3-Events.html#events-mouseevents
  @Experimental() // nonstandard
  int get _pageY => wrap_jso(JS("int", "#.pageY", this.raw));

  @DomName('UIEvent.view')
  @DocsEditable()
  WindowBase get view => _convertNativeToDart_Window(this._get_view);
  @JSName('view')
  @DomName('UIEvent.view')
  @DocsEditable()
  @Creates('Window|=Object')
  @Returns('Window|=Object')
  dynamic get _get_view => wrap_jso(JS("dynamic", "#.view", this.raw));

  @DomName('UIEvent.which')
  @DocsEditable()
  @Unstable()
  int get which => wrap_jso(JS("int", "#.which", this.raw));

  @DomName('UIEvent.initUIEvent')
  @DocsEditable()
  void _initUIEvent(String type, bool canBubble, bool cancelable, Window view, int detail) {
    _initUIEvent_1(type, canBubble, cancelable, view, detail);
    return;
  }
  @JSName('initUIEvent')
  @DomName('UIEvent.initUIEvent')
  @DocsEditable()
  void _initUIEvent_1(type, canBubble, cancelable, Window view, detail) => wrap_jso(JS("void ", "#.raw.initUIEvent(#, #, #, #, #)", this, unwrap_jso(type), unwrap_jso(canBubble), unwrap_jso(cancelable), unwrap_jso(view), unwrap_jso(detail)));


  @DomName('UIEvent.layerX')
  @DomName('UIEvent.layerY')
  Point get layer => new Point(_layerX, _layerY);

  @DomName('UIEvent.pageX')
  @DomName('UIEvent.pageY')
  Point get page => new Point(_pageX, _pageY);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('URLUtils')
@Experimental() // untriaged
abstract class UrlUtils extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory UrlUtils._() { throw new UnsupportedError("Not supported"); }

  String get hash => wrap_jso(JS("String", "#.hash", this.raw));
  void set hash(String val) => JS("void", "#.hash = #", this.raw, unwrap_jso(val));

  String get host => wrap_jso(JS("String", "#.host", this.raw));
  void set host(String val) => JS("void", "#.host = #", this.raw, unwrap_jso(val));

  String get hostname => wrap_jso(JS("String", "#.hostname", this.raw));
  void set hostname(String val) => JS("void", "#.hostname = #", this.raw, unwrap_jso(val));

  String get href => wrap_jso(JS("String", "#.href", this.raw));
  void set href(String val) => JS("void", "#.href = #", this.raw, unwrap_jso(val));

  String get origin => wrap_jso(JS("String", "#.origin", this.raw));

  String get password => wrap_jso(JS("String", "#.password", this.raw));
  void set password(String val) => JS("void", "#.password = #", this.raw, unwrap_jso(val));

  String get pathname => wrap_jso(JS("String", "#.pathname", this.raw));
  void set pathname(String val) => JS("void", "#.pathname = #", this.raw, unwrap_jso(val));

  String get port => wrap_jso(JS("String", "#.port", this.raw));
  void set port(String val) => JS("void", "#.port = #", this.raw, unwrap_jso(val));

  String get protocol => wrap_jso(JS("String", "#.protocol", this.raw));
  void set protocol(String val) => JS("void", "#.protocol = #", this.raw, unwrap_jso(val));

  String get search => wrap_jso(JS("String", "#.search", this.raw));
  void set search(String val) => JS("void", "#.search = #", this.raw, unwrap_jso(val));

  String get username => wrap_jso(JS("String", "#.username", this.raw));
  void set username(String val) => JS("void", "#.username = #", this.raw, unwrap_jso(val));

  String toString() => wrap_jso(JS("String", "#.raw.toString()", this));
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
/**
 * Top-level container for the current browser tab or window.
 *
 * In a web browser, each window has a [Window] object, but within the context
 * of a script, this object represents only the current window.
 * Each other window, tab, and iframe has its own [Window] object.
 *
 * Each window contains a [Document] object, which contains all of the window's
 * content.
 *
 * Use the top-level `window` object to access the current window.
 * For example:
 *
 *     // Draw a scene when the window repaints.
 *     drawScene(num delta) {...}
 *     window.animationFrame.then(drawScene);.
 *
 *     // Write to the console.
 *     window.console.log('Jinkies!');
 *     window.console.error('Jeepers!');
 *
 * **Note:** This class represents only the current window, while [WindowBase]
 * is a representation of any window, including other tabs, windows, and frames.
 *
 * ## See also
 *
 * * [WindowBase]
 *
 * ## Other resources
 *
 * * [DOM Window](https://developer.mozilla.org/en-US/docs/DOM/window) from MDN.
 * * [Window](http://www.w3.org/TR/Window/) from the W3C.
 */
@DomName('Window')
@Native("Window")
class Window extends EventTarget implements WindowBase {

  /**
   * Returns a Future that completes just before the window is about to
   * repaint so the user can draw an animation frame.
   *
   * If you need to later cancel this animation, use [requestAnimationFrame]
   * instead.
   *
   * The [Future] completes to a timestamp that represents a floating
   * point value of the number of milliseconds that have elapsed since the page
   * started to load (which is also the timestamp at this call to
   * animationFrame).
   *
   * Note: The code that runs when the future completes should call
   * [animationFrame] again for the animation to continue.
   */
  Future<num> get animationFrame {
    var completer = new Completer<num>.sync();
    requestAnimationFrame((time) {
      completer.complete(time);
    });
    return completer.future;
  }

  /**
   * The newest document in this window.
   *
   * ## Other resources
   *
   * * [Loading web pages]
   * (http://www.whatwg.org/specs/web-apps/current-work/multipage/browsers.html)
   * from WHATWG.
   */
  Document get document => wrap_jso(JS('Document', '#.document', this.raw));

  WindowBase _open2(url, name) => wrap_jso(JS('Window', '#.open(#,#)', this.raw, url, name));

  WindowBase _open3(url, name, options) =>
      wrap_jso(JS('Window', '#.open(#,#,#)', this.raw, url, name, options));

  /**
   * Opens a new window.
   *
   * ## Other resources
   *
   * * [Window.open]
   * (https://developer.mozilla.org/en-US/docs/Web/API/Window.open) from MDN.
   * * [Window open]
   * (http://docs.webplatform.org/wiki/dom/methods/open) from WebPlatform.org.
   */
  WindowBase open(String url, String name, [String options]) {
    if (options == null) {
      return _DOMWindowCrossFrame._createSafe(_open2(url, name));
    } else {
      return _DOMWindowCrossFrame._createSafe(_open3(url, name, options));
    }
  }

  // API level getter and setter for Location.
  // TODO: The cross domain safe wrapper can be inserted here.
  /**
   * The current location of this window.
   *
   *     Location currentLocation = window.location;
   *     print(currentLocation.href); // 'http://www.example.com:80/'
   */
  Location get location => _location;

  // TODO: consider forcing users to do: window.location.assign('string').
  /**
   * Sets the window's location, which causes the browser to navigate to the new
   * location. [value] may be a Location object or a String.
   */
  set location(value) {
    _location = value;
  }

  // Native getter and setter to access raw Location object.
  dynamic get _location => wrap_jso(JS('Location|Null', '#.location', this.raw));
  set _location(value) {
    JS('void', '#.location = #', this.raw, unwrap_jso(value));
  }

  /**
   * Called to draw an animation frame and then request the window to repaint
   * after [callback] has finished (creating the animation).
   *
   * Use this method only if you need to later call [cancelAnimationFrame]. If
   * not, the preferred Dart idiom is to set animation frames by calling
   * [animationFrame], which returns a Future.
   *
   * Returns a non-zero valued integer to represent the request id for this
   * request. This value only needs to be saved if you intend to call
   * [cancelAnimationFrame] so you can specify the particular animation to
   * cancel.
   *
   * Note: The supplied [callback] needs to call [requestAnimationFrame] again
   * for the animation to continue.
   */
  @DomName('Window.requestAnimationFrame')
  int requestAnimationFrame(RequestAnimationFrameCallback callback) {
    _ensureRequestAnimationFrame();
    return _requestAnimationFrame(_wrapZone(callback));
  }

  /**
   * Cancels an animation frame request.
   *
   * ## Other resources
   *
   * * [Window.cancelAnimationFrame]
   * (https://developer.mozilla.org/en-US/docs/Web/API/Window.cancelAnimationFrame) from MDN.
   */
  void cancelAnimationFrame(int id) {
    _ensureRequestAnimationFrame();
    _cancelAnimationFrame(id);
  }

  @JSName('requestAnimationFrame')
  int _requestAnimationFrame(RequestAnimationFrameCallback callback)
    => JS('int', '#.requestAnimationFrame', this.raw);

  @JSName('cancelAnimationFrame')
  void _cancelAnimationFrame(int id)
    { JS('void', '#.cancelAnimationFrame(#)', this.raw, id); }

  _ensureRequestAnimationFrame() {
    if (JS('bool',
           '!!(#.requestAnimationFrame && #.cancelAnimationFrame)', this.raw, this.raw))
      return;

    JS('void',
       r"""
  (function($this) {
   var vendors = ['ms', 'moz', 'webkit', 'o'];
   for (var i = 0; i < vendors.length && !$this.requestAnimationFrame; ++i) {
     $this.requestAnimationFrame = $this[vendors[i] + 'RequestAnimationFrame'];
     $this.cancelAnimationFrame =
         $this[vendors[i]+'CancelAnimationFrame'] ||
         $this[vendors[i]+'CancelRequestAnimationFrame'];
   }
   if ($this.requestAnimationFrame && $this.cancelAnimationFrame) return;
   $this.requestAnimationFrame = function(callback) {
      return window.setTimeout(function() {
        callback(Date.now());
      }, 16 /* 16ms ~= 60fps */);
   };
   $this.cancelAnimationFrame = function(id) { clearTimeout(id); }
  })(#)""",
       this.raw);
  }

  /// The debugging console for this window.
  @DomName('Window.console')
  Console get console => Console._safeConsole;

  // To suppress missing implicit constructor warnings.
  factory Window._() { throw new UnsupportedError("Not supported"); }

  /**
   * Static factory designed to expose `contentloaded` events to event
   * handlers that are not necessarily instances of [Window].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('Window.DOMContentLoadedEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> contentLoadedEvent = const EventStreamProvider<Event>('DOMContentLoaded');


  @Deprecated("Internal Use Only")
  static Window internalCreateWindow() {
    return new Window.internal_();
  }

  @Deprecated("Internal Use Only")
  Window.internal_() : super.internal_();


  /**
   * Indicates that file system data cannot be cleared unless given user
   * permission.
   *
   * ## Other resources
   *
   * * [Exploring the FileSystem APIs]
   * (http://www.html5rocks.com/en/tutorials/file/filesystem/) from HTML5Rocks.
   * * [File API]
   * (http://www.w3.org/TR/file-system-api/#idl-def-LocalFileSystem) from W3C.
   */
  @DomName('Window.PERSISTENT')
  @DocsEditable()
  // http://www.w3.org/TR/file-system-api/#idl-def-LocalFileSystem
  @Experimental()
  static const int PERSISTENT = 1;

  /**
   * Indicates that file system data can be cleared at any time.
   *
   * ## Other resources
   *
   * * [Exploring the FileSystem APIs]
   * (http://www.html5rocks.com/en/tutorials/file/filesystem/) from HTML5Rocks.
   * * [File API]
   * (http://www.w3.org/TR/file-system-api/#idl-def-LocalFileSystem) from W3C.
   */
  @DomName('Window.TEMPORARY')
  @DocsEditable()
  // http://www.w3.org/TR/file-system-api/#idl-def-LocalFileSystem
  @Experimental()
  static const int TEMPORARY = 0;

  @DomName('Window.closed')
  @DocsEditable()
  bool get closed => wrap_jso(JS("bool", "#.closed", this.raw));

  /// *Deprecated*.
  @DomName('Window.defaultStatus')
  @DocsEditable()
  @Experimental() // non-standard
  String get defaultStatus => wrap_jso(JS("String", "#.defaultStatus", this.raw));
  /// *Deprecated*.
  @DomName('Window.defaultStatus')
  @DocsEditable()
  @Experimental() // non-standard
  void set defaultStatus(String val) => JS("void", "#.defaultStatus = #", this.raw, unwrap_jso(val));

  /// *Deprecated*.
  @DomName('Window.defaultstatus')
  @DocsEditable()
  @Experimental() // non-standard
  String get defaultstatus => wrap_jso(JS("String", "#.defaultstatus", this.raw));
  /// *Deprecated*.
  @DomName('Window.defaultstatus')
  @DocsEditable()
  @Experimental() // non-standard
  void set defaultstatus(String val) => JS("void", "#.defaultstatus = #", this.raw, unwrap_jso(val));

  /**
   * The ratio between physical pixels and logical CSS pixels.
   *
   * ## Other resources
   *
   * * [devicePixelRatio]
   * (http://www.quirksmode.org/blog/archives/2012/06/devicepixelrati.html) from
   * quirksmode.
   * * [More about devicePixelRatio]
   * (http://www.quirksmode.org/blog/archives/2012/07/more_about_devi.html) from
   * quirksmode.
   */
  @DomName('Window.devicePixelRatio')
  @DocsEditable()
  // http://www.quirksmode.org/blog/archives/2012/06/devicepixelrati.html
  @Experimental() // non-standard
  double get devicePixelRatio => wrap_jso(JS("double", "#.devicePixelRatio", this.raw));

  /**
   * The current session history for this window's newest document.
   *
   * ## Other resources
   *
   * * [Loading web pages]
   * (http://www.whatwg.org/specs/web-apps/current-work/multipage/browsers.html)
   * from WHATWG.
   */
  @DomName('Window.history')
  @DocsEditable()
  History get history => wrap_jso(JS("History", "#.history", this.raw));

  /**
   * The height of the viewport including scrollbars.
   *
   * ## Other resources
   *
   * * [innerHeight]
   * (http://docs.webplatform.org/wiki/css/cssom/properties/innerHeight) from
   * WebPlatform.org.
   */
  @DomName('Window.innerHeight')
  @DocsEditable()
  int get innerHeight => wrap_jso(JS("int", "#.innerHeight", this.raw));

  /**
   * The width of the viewport including scrollbars.
   *
   * ## Other resources
   *
   * * [innerWidth]
   * (http://docs.webplatform.org/wiki/css/cssom/properties/innerWidth) from
   * WebPlatform.org.
   */
  @DomName('Window.innerWidth')
  @DocsEditable()
  int get innerWidth => wrap_jso(JS("int", "#.innerWidth", this.raw));

  /**
   * The name of this window.
   *
   * ## Other resources
   *
   * * [Window name]
   * (http://docs.webplatform.org/wiki/html/attributes/name_(window)) from
   * WebPlatform.org.
   */
  @DomName('Window.name')
  @DocsEditable()
  String get name => wrap_jso(JS("String", "#.name", this.raw));
  /**
   * The name of this window.
   *
   * ## Other resources
   *
   * * [Window name]
   * (http://docs.webplatform.org/wiki/html/attributes/name_(window)) from
   * WebPlatform.org.
   */
  @DomName('Window.name')
  @DocsEditable()
  void set name(String val) => JS("void", "#.name = #", this.raw, unwrap_jso(val));

  /**
   * The user agent accessing this window.
   *
   * ## Other resources
   *
   * * [The navigator object]
   * (http://www.whatwg.org/specs/web-apps/current-work/multipage/timers.html#the-navigator-object)
   * from WHATWG.
   */
  @DomName('Window.navigator')
  @DocsEditable()
  Navigator get navigator => wrap_jso(JS("Navigator", "#.navigator", this.raw));

  /**
   * Whether objects are drawn offscreen before being displayed.
   *
   * ## Other resources
   *
   * * [offscreenBuffering]
   * (http://docs.webplatform.org/wiki/dom/properties/offscreenBuffering) from
   * WebPlatform.org.
   */
  @DomName('Window.offscreenBuffering')
  @DocsEditable()
  @Experimental() // non-standard
  bool get offscreenBuffering => wrap_jso(JS("bool", "#.offscreenBuffering", this.raw));

  @DomName('Window.opener')
  @DocsEditable()
  WindowBase get opener => _convertNativeToDart_Window(this._get_opener);
  @JSName('opener')
  @DomName('Window.opener')
  @DocsEditable()
  @Creates('Window|=Object')
  @Returns('Window|=Object')
  dynamic get _get_opener => wrap_jso(JS("dynamic", "#.opener", this.raw));

  set opener(Window value) {
    JS("void", "#.raw.opener = #", this, unwrap_jso(value));
  }

  @DomName('Window.orientation')
  @DocsEditable()
  @Experimental() // untriaged
  int get orientation => wrap_jso(JS("int", "#.orientation", this.raw));

  /**
   * The height of this window including all user interface elements.
   *
   * ## Other resources
   *
   * * [outerHeight]
   * (http://docs.webplatform.org/wiki/css/cssom/properties/outerHeight) from
   * WebPlatform.org.
   */
  @DomName('Window.outerHeight')
  @DocsEditable()
  int get outerHeight => wrap_jso(JS("int", "#.outerHeight", this.raw));

  /**
   * The width of the window including all user interface elements.
   *
   * ## Other resources
   *
   * * [outerWidth]
   * (http://docs.webplatform.org/wiki/css/cssom/properties/outerWidth) from
   * WebPlatform.org.
   */
  @DomName('Window.outerWidth')
  @DocsEditable()
  int get outerWidth => wrap_jso(JS("int", "#.outerWidth", this.raw));

  @JSName('pageXOffset')
  /**
   * The distance this window has been scrolled horizontally.
   *
   * This attribute is an alias for [scrollX].
   *
   * ## Other resources
   *
   * * [The Screen interface specification]
   * (http://www.w3.org/TR/cssom-view/#screen) from W3C.
   * * [scrollX and pageXOffset]
   * (https://developer.mozilla.org/en-US/docs/Web/API/Window.scrollX) from MDN.
   */
  @DomName('Window.pageXOffset')
  @DocsEditable()
  double get _pageXOffset => wrap_jso(JS("double", "#.pageXOffset", this.raw));

  @JSName('pageYOffset')
  /**
   * The distance this window has been scrolled vertically.
   *
   * This attribute is an alias for [scrollY].
   *
   * ## Other resources
   *
   * * [The Screen interface specification]
   * (http://www.w3.org/TR/cssom-view/#screen) from W3C.
   * * [scrollY and pageYOffset]
   * (https://developer.mozilla.org/en-US/docs/Web/API/Window.scrollY) from MDN.
   */
  @DomName('Window.pageYOffset')
  @DocsEditable()
  double get _pageYOffset => wrap_jso(JS("double", "#.pageYOffset", this.raw));

  @DomName('Window.parent')
  @DocsEditable()
  WindowBase get parent => _convertNativeToDart_Window(this._get_parent);
  @JSName('parent')
  @DomName('Window.parent')
  @DocsEditable()
  @Creates('Window|=Object')
  @Returns('Window|=Object')
  dynamic get _get_parent => wrap_jso(JS("dynamic", "#.parent", this.raw));

  /**
   * Information about the screen displaying this window.
   *
   * ## Other resources
   *
   * * [The Screen interface specification]
   * (http://www.w3.org/TR/cssom-view/#screen) from W3C.
   */
  @DomName('Window.screen')
  @DocsEditable()
  Screen get screen => wrap_jso(JS("Screen", "#.screen", this.raw));

  /**
   * The distance from the left side of the screen to the left side of this
   * window.
   *
   * ## Other resources
   *
   * * [The Screen interface specification]
   * (http://www.w3.org/TR/cssom-view/#screen) from W3C.
   */
  @DomName('Window.screenLeft')
  @DocsEditable()
  int get screenLeft => wrap_jso(JS("int", "#.screenLeft", this.raw));

  /**
   * The distance from the top of the screen to the top of this window.
   *
   * ## Other resources
   *
   * * [The Screen interface specification]
   * (http://www.w3.org/TR/cssom-view/#screen) from W3C.
   */
  @DomName('Window.screenTop')
  @DocsEditable()
  int get screenTop => wrap_jso(JS("int", "#.screenTop", this.raw));

  /**
   * The distance from the left side of the screen to the mouse pointer.
   *
   * ## Other resources
   *
   * * [The Screen interface specification]
   * (http://www.w3.org/TR/cssom-view/#screen) from W3C.
   */
  @DomName('Window.screenX')
  @DocsEditable()
  int get screenX => wrap_jso(JS("int", "#.screenX", this.raw));

  /**
   * The distance from the top of the screen to the mouse pointer.
   *
   * ## Other resources
   *
   * * [The Screen interface specification]
   * (http://www.w3.org/TR/cssom-view/#screen) from W3C.
   */
  @DomName('Window.screenY')
  @DocsEditable()
  int get screenY => wrap_jso(JS("int", "#.screenY", this.raw));

  /**
   * The current window.
   *
   * ## Other resources
   *
   * * [Window.self]
   * (https://developer.mozilla.org/en-US/docs/Web/API/Window.self) from MDN.
   */
  @DomName('Window.self')
  @DocsEditable()
  WindowBase get self => _convertNativeToDart_Window(this._get_self);
  @JSName('self')
  /**
   * The current window.
   *
   * ## Other resources
   *
   * * [Window.self]
   * (https://developer.mozilla.org/en-US/docs/Web/API/Window.self) from MDN.
   */
  @DomName('Window.self')
  @DocsEditable()
  @Creates('Window|=Object')
  @Returns('Window|=Object')
  dynamic get _get_self => wrap_jso(JS("dynamic", "#.self", this.raw));

  /// *Deprecated*.
  @DomName('Window.status')
  @DocsEditable()
  String get status => wrap_jso(JS("String", "#.status", this.raw));
  /// *Deprecated*.
  @DomName('Window.status')
  @DocsEditable()
  void set status(String val) => JS("void", "#.status = #", this.raw, unwrap_jso(val));

  @DomName('Window.top')
  @DocsEditable()
  WindowBase get top => _convertNativeToDart_Window(this._get_top);
  @JSName('top')
  @DomName('Window.top')
  @DocsEditable()
  @Creates('Window|=Object')
  @Returns('Window|=Object')
  dynamic get _get_top => wrap_jso(JS("dynamic", "#.top", this.raw));

  /**
   * The current window.
   *
   * ## Other resources
   *
   * * [Window.window]
   * (https://developer.mozilla.org/en-US/docs/Web/API/Window.window) from MDN.
   */
  @DomName('Window.window')
  @DocsEditable()
  WindowBase get window => _convertNativeToDart_Window(this._get_window);
  @JSName('window')
  /**
   * The current window.
   *
   * ## Other resources
   *
   * * [Window.window]
   * (https://developer.mozilla.org/en-US/docs/Web/API/Window.window) from MDN.
   */
  @DomName('Window.window')
  @DocsEditable()
  @Creates('Window|=Object')
  @Returns('Window|=Object')
  dynamic get _get_window => wrap_jso(JS("dynamic", "#.window", this.raw));

  @DomName('Window.__getter__')
  @DocsEditable()
  @Creates('Window|=Object')
  @Returns('Window|=Object')
  WindowBase __getter__(index_OR_name) {
    if ((index_OR_name is int)) {
      return _convertNativeToDart_Window(__getter___1(index_OR_name));
    }
    if ((index_OR_name is String)) {
      return _convertNativeToDart_Window(__getter___2(index_OR_name));
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }
  @JSName('__getter__')
  @DomName('Window.__getter__')
  @DocsEditable()
  @Creates('Window|=Object')
  @Returns('Window|=Object')
  __getter___1(int index) => wrap_jso(JS("", "#.raw.__getter__(#)", this, unwrap_jso(index)));
  @JSName('__getter__')
  @DomName('Window.__getter__')
  @DocsEditable()
  @Creates('Window|=Object')
  @Returns('Window|=Object')
  __getter___2(String name) => wrap_jso(JS("", "#.raw.__getter__(#)", this, unwrap_jso(name)));

  /**
   * Displays a modal alert to the user.
   *
   * ## Other resources
   *
   * * [User prompts]
   * (http://www.whatwg.org/specs/web-apps/current-work/multipage/timers.html#user-prompts)
   * from WHATWG.
   */
  @DomName('Window.alert')
  @DocsEditable()
  void alert([String message]) {
    if (message != null) {
      _alert_1(message);
      return;
    }
    _alert_2();
    return;
  }
  @JSName('alert')
  /**
   * Displays a modal alert to the user.
   *
   * ## Other resources
   *
   * * [User prompts]
   * (http://www.whatwg.org/specs/web-apps/current-work/multipage/timers.html#user-prompts)
   * from WHATWG.
   */
  @DomName('Window.alert')
  @DocsEditable()
  void _alert_1(message) => wrap_jso(JS("void ", "#.raw.alert(#)", this, unwrap_jso(message)));
  @JSName('alert')
  /**
   * Displays a modal alert to the user.
   *
   * ## Other resources
   *
   * * [User prompts]
   * (http://www.whatwg.org/specs/web-apps/current-work/multipage/timers.html#user-prompts)
   * from WHATWG.
   */
  @DomName('Window.alert')
  @DocsEditable()
  void _alert_2() => wrap_jso(JS("void ", "#.raw.alert()", this));

  @DomName('Window.close')
  @DocsEditable()
  void close() {
    _close_1();
    return;
  }
  @JSName('close')
  @DomName('Window.close')
  @DocsEditable()
  void _close_1() => wrap_jso(JS("void ", "#.raw.close()", this));

  /**
   * Displays a modal OK/Cancel prompt to the user.
   *
   * ## Other resources
   *
   * * [User prompts]
   * (http://www.whatwg.org/specs/web-apps/current-work/multipage/timers.html#user-prompts)
   * from WHATWG.
   */
  @DomName('Window.confirm')
  @DocsEditable()
  bool confirm([String message]) {
    if (message != null) {
      return _confirm_1(message);
    }
    return _confirm_2();
  }
  @JSName('confirm')
  /**
   * Displays a modal OK/Cancel prompt to the user.
   *
   * ## Other resources
   *
   * * [User prompts]
   * (http://www.whatwg.org/specs/web-apps/current-work/multipage/timers.html#user-prompts)
   * from WHATWG.
   */
  @DomName('Window.confirm')
  @DocsEditable()
  bool _confirm_1(message) => wrap_jso(JS("bool ", "#.raw.confirm(#)", this, unwrap_jso(message)));
  @JSName('confirm')
  /**
   * Displays a modal OK/Cancel prompt to the user.
   *
   * ## Other resources
   *
   * * [User prompts]
   * (http://www.whatwg.org/specs/web-apps/current-work/multipage/timers.html#user-prompts)
   * from WHATWG.
   */
  @DomName('Window.confirm')
  @DocsEditable()
  bool _confirm_2() => wrap_jso(JS("bool ", "#.raw.confirm()", this));

  /**
   * Finds text in this window.
   *
   * ## Other resources
   *
   * * [Window.find]
   * (https://developer.mozilla.org/en-US/docs/Web/API/Window.find) from MDN.
   */
  @DomName('Window.find')
  @DocsEditable()
  @Experimental() // non-standard
  bool find(String string, bool caseSensitive, bool backwards, bool wrap, bool wholeWord, bool searchInFrames, bool showDialog) {
    return _find_1(string, caseSensitive, backwards, wrap, wholeWord, searchInFrames, showDialog);
  }
  @JSName('find')
  /**
   * Finds text in this window.
   *
   * ## Other resources
   *
   * * [Window.find]
   * (https://developer.mozilla.org/en-US/docs/Web/API/Window.find) from MDN.
   */
  @DomName('Window.find')
  @DocsEditable()
  @Experimental() // non-standard
  bool _find_1(string, caseSensitive, backwards, wrap, wholeWord, searchInFrames, showDialog) => wrap_jso(JS("bool ", "#.raw.find(#, #, #, #, #, #, #)", this, unwrap_jso(string), unwrap_jso(caseSensitive), unwrap_jso(backwards), unwrap_jso(wrap), unwrap_jso(wholeWord), unwrap_jso(searchInFrames), unwrap_jso(showDialog)));

  @DomName('Window.getComputedStyle')
  @DocsEditable()
  CssStyleDeclaration _getComputedStyle(Element element, String pseudoElement) {
    return _getComputedStyle_1(element, pseudoElement);
  }
  @JSName('getComputedStyle')
  @DomName('Window.getComputedStyle')
  @DocsEditable()
  CssStyleDeclaration _getComputedStyle_1(Element element, pseudoElement) => wrap_jso(JS("CssStyleDeclaration ", "#.raw.getComputedStyle(#, #)", this, unwrap_jso(element), unwrap_jso(pseudoElement)));

  /**
   * Moves this window.
   *
   * x and y can be negative.
   *
   * ## Other resources
   *
   * * [Window.moveBy]
   * (https://developer.mozilla.org/en-US/docs/Web/API/Window.moveBy) from MDN.
   * * [Window.moveBy]
   * (http://dev.w3.org/csswg/cssom-view/#dom-window-moveby) from W3C.
   */
  @DomName('Window.moveBy')
  @DocsEditable()
  void moveBy(num x, num y) {
    _moveBy_1(x, y);
    return;
  }
  @JSName('moveBy')
  /**
   * Moves this window.
   *
   * x and y can be negative.
   *
   * ## Other resources
   *
   * * [Window.moveBy]
   * (https://developer.mozilla.org/en-US/docs/Web/API/Window.moveBy) from MDN.
   * * [Window.moveBy]
   * (http://dev.w3.org/csswg/cssom-view/#dom-window-moveby) from W3C.
   */
  @DomName('Window.moveBy')
  @DocsEditable()
  void _moveBy_1(x, y) => wrap_jso(JS("void ", "#.raw.moveBy(#, #)", this, unwrap_jso(x), unwrap_jso(y)));

  @DomName('Window.moveTo')
  @DocsEditable()
  void _moveTo(num x, num y) {
    _moveTo_1(x, y);
    return;
  }
  @JSName('moveTo')
  @DomName('Window.moveTo')
  @DocsEditable()
  void _moveTo_1(x, y) => wrap_jso(JS("void ", "#.raw.moveTo(#, #)", this, unwrap_jso(x), unwrap_jso(y)));

  /**
   * Opens the print dialog for this window.
   *
   * ## Other resources
   *
   * * [Window.print]
   * (https://developer.mozilla.org/en-US/docs/Web/API/Window.print) from MDN.
   */
  @DomName('Window.print')
  @DocsEditable()
  void print() {
    _print_1();
    return;
  }
  @JSName('print')
  /**
   * Opens the print dialog for this window.
   *
   * ## Other resources
   *
   * * [Window.print]
   * (https://developer.mozilla.org/en-US/docs/Web/API/Window.print) from MDN.
   */
  @DomName('Window.print')
  @DocsEditable()
  void _print_1() => wrap_jso(JS("void ", "#.raw.print()", this));

  /**
   * Resizes this window by an offset.
   *
   * ## Other resources
   *
   * * [Window resizeBy] (http://docs.webplatform.org/wiki/dom/methods/resizeBy)
   * from WebPlatform.org.
   */
  @DomName('Window.resizeBy')
  @DocsEditable()
  void resizeBy(num x, num y) {
    _resizeBy_1(x, y);
    return;
  }
  @JSName('resizeBy')
  /**
   * Resizes this window by an offset.
   *
   * ## Other resources
   *
   * * [Window resizeBy] (http://docs.webplatform.org/wiki/dom/methods/resizeBy)
   * from WebPlatform.org.
   */
  @DomName('Window.resizeBy')
  @DocsEditable()
  void _resizeBy_1(x, y) => wrap_jso(JS("void ", "#.raw.resizeBy(#, #)", this, unwrap_jso(x), unwrap_jso(y)));

  /**
   * Resizes this window to a specific width and height.
   *
   * ## Other resources
   *
   * * [Window resizeTo] (http://docs.webplatform.org/wiki/dom/methods/resizeTo)
   * from WebPlatform.org.
   */
  @DomName('Window.resizeTo')
  @DocsEditable()
  void resizeTo(num width, num height) {
    _resizeTo_1(width, height);
    return;
  }
  @JSName('resizeTo')
  /**
   * Resizes this window to a specific width and height.
   *
   * ## Other resources
   *
   * * [Window resizeTo] (http://docs.webplatform.org/wiki/dom/methods/resizeTo)
   * from WebPlatform.org.
   */
  @DomName('Window.resizeTo')
  @DocsEditable()
  void _resizeTo_1(width, height) => wrap_jso(JS("void ", "#.raw.resizeTo(#, #)", this, unwrap_jso(width), unwrap_jso(height)));

  /**
   * Scrolls the page horizontally and vertically to a specific point.
   *
   * This method is identical to [scrollTo].
   *
   * ## Other resources
   *
   * * [Window scroll] (http://docs.webplatform.org/wiki/dom/methods/scroll)
   * from WebPlatform.org.
   */
  @DomName('Window.scroll')
  @DocsEditable()
  void scroll(x, y, [Map scrollOptions]) {
    if ((y is num) && (x is num) && scrollOptions == null) {
      _scroll_1(x, y);
      return;
    }
    if (scrollOptions != null && (y is num) && (x is num)) {
      var scrollOptions_1 = convertDartToNative_Dictionary(scrollOptions);
      _scroll_2(x, y, scrollOptions_1);
      return;
    }
    if ((y is int) && (x is int) && scrollOptions == null) {
      _scroll_3(x, y);
      return;
    }
    if (scrollOptions != null && (y is int) && (x is int)) {
      var scrollOptions_1 = convertDartToNative_Dictionary(scrollOptions);
      _scroll_4(x, y, scrollOptions_1);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }
  @JSName('scroll')
  /**
   * Scrolls the page horizontally and vertically to a specific point.
   *
   * This method is identical to [scrollTo].
   *
   * ## Other resources
   *
   * * [Window scroll] (http://docs.webplatform.org/wiki/dom/methods/scroll)
   * from WebPlatform.org.
   */
  @DomName('Window.scroll')
  @DocsEditable()
  void _scroll_1(num x, num y) => wrap_jso(JS("void ", "#.raw.scroll(#, #)", this, unwrap_jso(x), unwrap_jso(y)));
  @JSName('scroll')
  /**
   * Scrolls the page horizontally and vertically to a specific point.
   *
   * This method is identical to [scrollTo].
   *
   * ## Other resources
   *
   * * [Window scroll] (http://docs.webplatform.org/wiki/dom/methods/scroll)
   * from WebPlatform.org.
   */
  @DomName('Window.scroll')
  @DocsEditable()
  void _scroll_2(num x, num y, scrollOptions) => wrap_jso(JS("void ", "#.raw.scroll(#, #, #)", this, unwrap_jso(x), unwrap_jso(y), unwrap_jso(scrollOptions)));
  @JSName('scroll')
  /**
   * Scrolls the page horizontally and vertically to a specific point.
   *
   * This method is identical to [scrollTo].
   *
   * ## Other resources
   *
   * * [Window scroll] (http://docs.webplatform.org/wiki/dom/methods/scroll)
   * from WebPlatform.org.
   */
  @DomName('Window.scroll')
  @DocsEditable()
  void _scroll_3(int x, int y) => wrap_jso(JS("void ", "#.raw.scroll(#, #)", this, unwrap_jso(x), unwrap_jso(y)));
  @JSName('scroll')
  /**
   * Scrolls the page horizontally and vertically to a specific point.
   *
   * This method is identical to [scrollTo].
   *
   * ## Other resources
   *
   * * [Window scroll] (http://docs.webplatform.org/wiki/dom/methods/scroll)
   * from WebPlatform.org.
   */
  @DomName('Window.scroll')
  @DocsEditable()
  void _scroll_4(int x, int y, scrollOptions) => wrap_jso(JS("void ", "#.raw.scroll(#, #, #)", this, unwrap_jso(x), unwrap_jso(y), unwrap_jso(scrollOptions)));

  /**
   * Scrolls the page horizontally and vertically by an offset.
   *
   * ## Other resources
   *
   * * [Window scrollBy] (http://docs.webplatform.org/wiki/dom/methods/scrollBy)
   * from WebPlatform.org.
   */
  @DomName('Window.scrollBy')
  @DocsEditable()
  void scrollBy(x, y, [Map scrollOptions]) {
    if ((y is num) && (x is num) && scrollOptions == null) {
      _scrollBy_1(x, y);
      return;
    }
    if (scrollOptions != null && (y is num) && (x is num)) {
      var scrollOptions_1 = convertDartToNative_Dictionary(scrollOptions);
      _scrollBy_2(x, y, scrollOptions_1);
      return;
    }
    if ((y is int) && (x is int) && scrollOptions == null) {
      _scrollBy_3(x, y);
      return;
    }
    if (scrollOptions != null && (y is int) && (x is int)) {
      var scrollOptions_1 = convertDartToNative_Dictionary(scrollOptions);
      _scrollBy_4(x, y, scrollOptions_1);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }
  @JSName('scrollBy')
  /**
   * Scrolls the page horizontally and vertically by an offset.
   *
   * ## Other resources
   *
   * * [Window scrollBy] (http://docs.webplatform.org/wiki/dom/methods/scrollBy)
   * from WebPlatform.org.
   */
  @DomName('Window.scrollBy')
  @DocsEditable()
  void _scrollBy_1(num x, num y) => wrap_jso(JS("void ", "#.raw.scrollBy(#, #)", this, unwrap_jso(x), unwrap_jso(y)));
  @JSName('scrollBy')
  /**
   * Scrolls the page horizontally and vertically by an offset.
   *
   * ## Other resources
   *
   * * [Window scrollBy] (http://docs.webplatform.org/wiki/dom/methods/scrollBy)
   * from WebPlatform.org.
   */
  @DomName('Window.scrollBy')
  @DocsEditable()
  void _scrollBy_2(num x, num y, scrollOptions) => wrap_jso(JS("void ", "#.raw.scrollBy(#, #, #)", this, unwrap_jso(x), unwrap_jso(y), unwrap_jso(scrollOptions)));
  @JSName('scrollBy')
  /**
   * Scrolls the page horizontally and vertically by an offset.
   *
   * ## Other resources
   *
   * * [Window scrollBy] (http://docs.webplatform.org/wiki/dom/methods/scrollBy)
   * from WebPlatform.org.
   */
  @DomName('Window.scrollBy')
  @DocsEditable()
  void _scrollBy_3(int x, int y) => wrap_jso(JS("void ", "#.raw.scrollBy(#, #)", this, unwrap_jso(x), unwrap_jso(y)));
  @JSName('scrollBy')
  /**
   * Scrolls the page horizontally and vertically by an offset.
   *
   * ## Other resources
   *
   * * [Window scrollBy] (http://docs.webplatform.org/wiki/dom/methods/scrollBy)
   * from WebPlatform.org.
   */
  @DomName('Window.scrollBy')
  @DocsEditable()
  void _scrollBy_4(int x, int y, scrollOptions) => wrap_jso(JS("void ", "#.raw.scrollBy(#, #, #)", this, unwrap_jso(x), unwrap_jso(y), unwrap_jso(scrollOptions)));

  /**
   * Scrolls the page horizontally and vertically to a specific point.
   *
   * This method is identical to [scroll].
   *
   * ## Other resources
   *
   * * [Window scrollTo] (http://docs.webplatform.org/wiki/dom/methods/scrollTo)
   * from WebPlatform.org.
   */
  @DomName('Window.scrollTo')
  @DocsEditable()
  void scrollTo(x, y, [Map scrollOptions]) {
    if ((y is num) && (x is num) && scrollOptions == null) {
      _scrollTo_1(x, y);
      return;
    }
    if (scrollOptions != null && (y is num) && (x is num)) {
      var scrollOptions_1 = convertDartToNative_Dictionary(scrollOptions);
      _scrollTo_2(x, y, scrollOptions_1);
      return;
    }
    if ((y is int) && (x is int) && scrollOptions == null) {
      _scrollTo_3(x, y);
      return;
    }
    if (scrollOptions != null && (y is int) && (x is int)) {
      var scrollOptions_1 = convertDartToNative_Dictionary(scrollOptions);
      _scrollTo_4(x, y, scrollOptions_1);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }
  @JSName('scrollTo')
  /**
   * Scrolls the page horizontally and vertically to a specific point.
   *
   * This method is identical to [scroll].
   *
   * ## Other resources
   *
   * * [Window scrollTo] (http://docs.webplatform.org/wiki/dom/methods/scrollTo)
   * from WebPlatform.org.
   */
  @DomName('Window.scrollTo')
  @DocsEditable()
  void _scrollTo_1(num x, num y) => wrap_jso(JS("void ", "#.raw.scrollTo(#, #)", this, unwrap_jso(x), unwrap_jso(y)));
  @JSName('scrollTo')
  /**
   * Scrolls the page horizontally and vertically to a specific point.
   *
   * This method is identical to [scroll].
   *
   * ## Other resources
   *
   * * [Window scrollTo] (http://docs.webplatform.org/wiki/dom/methods/scrollTo)
   * from WebPlatform.org.
   */
  @DomName('Window.scrollTo')
  @DocsEditable()
  void _scrollTo_2(num x, num y, scrollOptions) => wrap_jso(JS("void ", "#.raw.scrollTo(#, #, #)", this, unwrap_jso(x), unwrap_jso(y), unwrap_jso(scrollOptions)));
  @JSName('scrollTo')
  /**
   * Scrolls the page horizontally and vertically to a specific point.
   *
   * This method is identical to [scroll].
   *
   * ## Other resources
   *
   * * [Window scrollTo] (http://docs.webplatform.org/wiki/dom/methods/scrollTo)
   * from WebPlatform.org.
   */
  @DomName('Window.scrollTo')
  @DocsEditable()
  void _scrollTo_3(int x, int y) => wrap_jso(JS("void ", "#.raw.scrollTo(#, #)", this, unwrap_jso(x), unwrap_jso(y)));
  @JSName('scrollTo')
  /**
   * Scrolls the page horizontally and vertically to a specific point.
   *
   * This method is identical to [scroll].
   *
   * ## Other resources
   *
   * * [Window scrollTo] (http://docs.webplatform.org/wiki/dom/methods/scrollTo)
   * from WebPlatform.org.
   */
  @DomName('Window.scrollTo')
  @DocsEditable()
  void _scrollTo_4(int x, int y, scrollOptions) => wrap_jso(JS("void ", "#.raw.scrollTo(#, #, #)", this, unwrap_jso(x), unwrap_jso(y), unwrap_jso(scrollOptions)));

  /**
   * Opens a new page as a modal dialog.
   *
   * ## Other resources
   *
   * * [Dialogs implemented using separate documents]
   * (http://www.w3.org/html/wg/drafts/html/master/webappapis.html#dialogs-implemented-using-separate-documents)
   * from W3C.
   */
  @DomName('Window.showModalDialog')
  @DocsEditable()
  @Creates('Null')
  Object showModalDialog(String url, [Object dialogArgs, String featureArgs]) {
    if (featureArgs != null) {
      return _showModalDialog_1(url, dialogArgs, featureArgs);
    }
    if (dialogArgs != null) {
      return _showModalDialog_2(url, dialogArgs);
    }
    return _showModalDialog_3(url);
  }
  @JSName('showModalDialog')
  /**
   * Opens a new page as a modal dialog.
   *
   * ## Other resources
   *
   * * [Dialogs implemented using separate documents]
   * (http://www.w3.org/html/wg/drafts/html/master/webappapis.html#dialogs-implemented-using-separate-documents)
   * from W3C.
   */
  @DomName('Window.showModalDialog')
  @DocsEditable()
  @Creates('Null')
  Object _showModalDialog_1(url, dialogArgs, featureArgs) => wrap_jso(JS("Object ", "#.raw.showModalDialog(#, #, #)", this, unwrap_jso(url), unwrap_jso(dialogArgs), unwrap_jso(featureArgs)));
  @JSName('showModalDialog')
  /**
   * Opens a new page as a modal dialog.
   *
   * ## Other resources
   *
   * * [Dialogs implemented using separate documents]
   * (http://www.w3.org/html/wg/drafts/html/master/webappapis.html#dialogs-implemented-using-separate-documents)
   * from W3C.
   */
  @DomName('Window.showModalDialog')
  @DocsEditable()
  @Creates('Null')
  Object _showModalDialog_2(url, dialogArgs) => wrap_jso(JS("Object ", "#.raw.showModalDialog(#, #)", this, unwrap_jso(url), unwrap_jso(dialogArgs)));
  @JSName('showModalDialog')
  /**
   * Opens a new page as a modal dialog.
   *
   * ## Other resources
   *
   * * [Dialogs implemented using separate documents]
   * (http://www.w3.org/html/wg/drafts/html/master/webappapis.html#dialogs-implemented-using-separate-documents)
   * from W3C.
   */
  @DomName('Window.showModalDialog')
  @DocsEditable()
  @Creates('Null')
  Object _showModalDialog_3(url) => wrap_jso(JS("Object ", "#.raw.showModalDialog(#)", this, unwrap_jso(url)));

  /**
   * Stops the window from loading.
   *
   * ## Other resources
   *
   * * [The Window object]
   * (http://www.w3.org/html/wg/drafts/html/master/browsers.html#the-window-object)
   * from W3C.
   */
  @DomName('Window.stop')
  @DocsEditable()
  void stop() {
    _stop_1();
    return;
  }
  @JSName('stop')
  /**
   * Stops the window from loading.
   *
   * ## Other resources
   *
   * * [The Window object]
   * (http://www.w3.org/html/wg/drafts/html/master/browsers.html#the-window-object)
   * from W3C.
   */
  @DomName('Window.stop')
  @DocsEditable()
  void _stop_1() => wrap_jso(JS("void ", "#.raw.stop()", this));

  /// Stream of `contentloaded` events handled by this [Window].
  @DomName('Window.onDOMContentLoaded')
  @DocsEditable()
  Stream<Event> get onContentLoaded => contentLoadedEvent.forTarget(this);

  /// Stream of `search` events handled by this [Window].
  @DomName('Window.onsearch')
  @DocsEditable()
  // http://www.w3.org/TR/html-markup/input.search.html
  @Experimental()
  Stream<Event> get onSearch => Element.searchEvent.forTarget(this);



  /**
   * Moves this window to a specific position.
   *
   * x and y can be negative.
   *
   * ## Other resources
   *
   * * [Window.moveTo]
   * (https://developer.mozilla.org/en-US/docs/Web/API/Window.moveTo) from MDN.
   * * [Window.moveTo]
   * (http://dev.w3.org/csswg/cssom-view/#dom-window-moveto) from W3C.
   */
  void moveTo(Point p) {
    _moveTo(p.x, p.y);
  }

  @DomName('Window.pageXOffset')
  @DocsEditable()
  int get pageXOffset => JS('num', '#.pageXOffset', this.raw).round();

  @DomName('Window.pageYOffset')
  @DocsEditable()
  int get pageYOffset => JS('num', '#.pageYOffset', this.raw).round();

  /**
   * The distance this window has been scrolled horizontally.
   *
   * ## Other resources
   *
   * * [The Screen interface specification]
   * (http://www.w3.org/TR/cssom-view/#screen) from W3C.
   * * [scrollX]
   * (https://developer.mozilla.org/en-US/docs/Web/API/Window.scrollX) from MDN.
   */
  @DomName('Window.scrollX')
  @DocsEditable()
  int get scrollX => JS('bool', '("scrollX" in #)', this.raw) ?
      JS('num', '#.scrollX', this.raw).round() :
      document.documentElement.scrollLeft;

  /**
   * The distance this window has been scrolled vertically.
   *
   * ## Other resources
   *
   * * [The Screen interface specification]
   * (http://www.w3.org/TR/cssom-view/#screen) from W3C.
   * * [scrollY]
   * (https://developer.mozilla.org/en-US/docs/Web/API/Window.scrollY) from MDN.
   */
  @DomName('Window.scrollY')
  @DocsEditable()
  int get scrollY => JS('bool', '("scrollY" in #)', this.raw) ?
      JS('num', '#.scrollY', this.raw).round() :
      document.documentElement.scrollTop;

  void postMessage(var message, String targetOrigin, [List messagePorts]) {
    if (messagePorts != null) {
      throw 'postMessage unsupported';
    }
    JS('void', '#.postMessage(#, #)', this.raw, message, targetOrigin);
  }
}


// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('Attr')
@Native("Attr")
class _Attr extends Node {
  // To suppress missing implicit constructor warnings.
  factory _Attr._() { throw new UnsupportedError("Not supported"); }


  @Deprecated("Internal Use Only")
  static _Attr internalCreate_Attr() {
    return new _Attr.internal_();
  }

  @Deprecated("Internal Use Only")
  _Attr.internal_() : super.internal_();


  // Use implementation from Node.
  // final String _localName;

  @DomName('Attr.name')
  @DocsEditable()
  String get name => wrap_jso(JS("String", "#.name", this.raw));

  // Use implementation from Node.
  // final String _namespaceUri;

  // Use implementation from Node.
  // final String nodeValue;

  // Shadowing definition.
  String get text => wrap_jso(JS("String", "#.raw.textContent", this));

  set text(String value) {
    JS("void", "#.raw.textContent = #", this, unwrap_jso(value));
  }

  @DomName('Attr.value')
  @DocsEditable()
  String get value => wrap_jso(JS("String", "#.value", this.raw));
  @DomName('Attr.value')
  @DocsEditable()
  void set value(String val) => JS("void", "#.value = #", this.raw, unwrap_jso(val));
}
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('ClientRect')
@Native("ClientRect")
class _ClientRect extends DartHtmlDomObject implements Rectangle {

  // NOTE! All code below should be common with RectangleBase.
   String toString() {
    return 'Rectangle ($left, $top) $width x $height';
  }

  bool operator ==(other) {
    if (other is !Rectangle) return false;
    return left == other.left && top == other.top && width == other.width &&
        height == other.height;
  }

  int get hashCode => _JenkinsSmiHash.hash4(left.hashCode, top.hashCode,
      width.hashCode, height.hashCode);

  /**
   * Computes the intersection of `this` and [other].
   *
   * The intersection of two axis-aligned rectangles, if any, is always another
   * axis-aligned rectangle.
   *
   * Returns the intersection of this and `other`, or null if they don't
   * intersect.
   */
  Rectangle intersection(Rectangle other) {
    var x0 = max(left, other.left);
    var x1 = min(left + width, other.left + other.width);

    if (x0 <= x1) {
      var y0 = max(top, other.top);
      var y1 = min(top + height, other.top + other.height);

      if (y0 <= y1) {
        return new Rectangle(x0, y0, x1 - x0, y1 - y0);
      }
    }
    return null;
  }


  /**
   * Returns true if `this` intersects [other].
   */
  bool intersects(Rectangle<num> other) {
    return (left <= other.left + other.width &&
        other.left <= left + width &&
        top <= other.top + other.height &&
        other.top <= top + height);
  }

  /**
   * Returns a new rectangle which completely contains `this` and [other].
   */
  Rectangle boundingBox(Rectangle other) {
    var right = max(this.left + this.width, other.left + other.width);
    var bottom = max(this.top + this.height, other.top + other.height);

    var left = min(this.left, other.left);
    var top = min(this.top, other.top);

    return new Rectangle(left, top, right - left, bottom - top);
  }

  /**
   * Tests whether `this` entirely contains [another].
   */
  bool containsRectangle(Rectangle<num> another) {
    return left <= another.left &&
           left + width >= another.left + another.width &&
           top <= another.top &&
           top + height >= another.top + another.height;
  }

  /**
   * Tests whether [another] is inside or along the edges of `this`.
   */
  bool containsPoint(Point<num> another) {
    return another.x >= left &&
           another.x <= left + width &&
           another.y >= top &&
           another.y <= top + height;
  }

  Point get topLeft => new Point(this.left, this.top);
  Point get topRight => new Point(this.left + this.width, this.top);
  Point get bottomRight => new Point(this.left + this.width,
      this.top + this.height);
  Point get bottomLeft => new Point(this.left,
      this.top + this.height);

    // To suppress missing implicit constructor warnings.
  factory _ClientRect._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static _ClientRect internalCreate_ClientRect() {
    return new _ClientRect.internal_();
  }

  @Deprecated("Internal Use Only")
  _ClientRect.internal_() { }


  @DomName('ClientRect.bottom')
  @DocsEditable()
  double get bottom => wrap_jso(JS("double", "#.bottom", this.raw));

  @DomName('ClientRect.height')
  @DocsEditable()
  double get height => wrap_jso(JS("double", "#.height", this.raw));

  @DomName('ClientRect.left')
  @DocsEditable()
  double get left => wrap_jso(JS("double", "#.left", this.raw));

  @DomName('ClientRect.right')
  @DocsEditable()
  double get right => wrap_jso(JS("double", "#.right", this.raw));

  @DomName('ClientRect.top')
  @DocsEditable()
  double get top => wrap_jso(JS("double", "#.top", this.raw));

  @DomName('ClientRect.width')
  @DocsEditable()
  double get width => wrap_jso(JS("double", "#.width", this.raw));
}

/**
 * This is the [Jenkins hash function][1] but using masking to keep
 * values in SMI range.
 *
 * [1]: http://en.wikipedia.org/wiki/Jenkins_hash_function
 *
 * Use:
 * Hash each value with the hash of the previous value, then get the final
 * hash by calling finish.
 *
 *     var hash = 0;
 *     for (var value in values) {
 *       hash = JenkinsSmiHash.combine(hash, value.hashCode);
 *     }
 *     hash = JenkinsSmiHash.finish(hash);
 */
class _JenkinsSmiHash {
  // TODO(11617): This class should be optimized and standardized elsewhere.

  static int combine(int hash, int value) {
    hash = 0x1fffffff & (hash + value);
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) <<  3));
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }

  static int hash2(a, b) => finish(combine(combine(0, a), b));

  static int hash4(a, b, c, d) =>
      finish(combine(combine(combine(combine(0, a), b), c), d));
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('NamedNodeMap')
// http://dom.spec.whatwg.org/#namednodemap
@deprecated // deprecated
@Native("NamedNodeMap,MozNamedAttrMap")
class _NamedNodeMap extends DartHtmlDomObject with ListMixin<Node>, ImmutableListMixin<Node> implements JavaScriptIndexingBehavior, List<Node> {
  // To suppress missing implicit constructor warnings.
  factory _NamedNodeMap._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static _NamedNodeMap internalCreate_NamedNodeMap() {
    return new _NamedNodeMap.internal_();
  }

  @Deprecated("Internal Use Only")
  _NamedNodeMap.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

  @DomName('NamedNodeMap.length')
  @DocsEditable()
  int get length => wrap_jso(JS("int", "#.length", this.raw));

  Node operator[](int index) {
    if (JS("bool", "# >>> 0 !== # || # >= #", index,
        index, index, length))
      throw new RangeError.index(index, this);
    return wrap_jso(JS("Node", "#[#]", this.raw, index));
  }
  void operator[]=(int index, Node value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Node> mixins.
  // Node is the element type.


  set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  Node get first {
    if (this.length > 0) {
      return wrap_jso(JS('Node', '#[0]', this.raw));
    }
    throw new StateError("No elements");
  }

  Node get last {
    int len = this.length;
    if (len > 0) {
      return wrap_jso(JS('Node', '#[#]', this.raw, len - 1));
    }
    throw new StateError("No elements");
  }

  Node get single {
    int len = this.length;
    if (len == 1) {
      return wrap_jso(JS('Node', '#[0]', this.raw));
    }
    if (len == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  Node elementAt(int index) => this[index];
  // -- end List<Node> mixins.

  @DomName('NamedNodeMap.__getter__')
  @DocsEditable()
  Node __getter__(String name) {
    return __getter___1(name);
  }
  @JSName('__getter__')
  @DomName('NamedNodeMap.__getter__')
  @DocsEditable()
  Node __getter___1(name) => wrap_jso(JS("Node ", "#.raw.__getter__(#)", this, unwrap_jso(name)));

  @DomName('NamedNodeMap.getNamedItem')
  @DocsEditable()
  Node getNamedItem(String name) {
    return _getNamedItem_1(name);
  }
  @JSName('getNamedItem')
  @DomName('NamedNodeMap.getNamedItem')
  @DocsEditable()
  Node _getNamedItem_1(name) => wrap_jso(JS("Node ", "#.raw.getNamedItem(#)", this, unwrap_jso(name)));

  @DomName('NamedNodeMap.getNamedItemNS')
  @DocsEditable()
  Node getNamedItemNS(String namespaceURI, String localName) {
    return _getNamedItemNS_1(namespaceURI, localName);
  }
  @JSName('getNamedItemNS')
  @DomName('NamedNodeMap.getNamedItemNS')
  @DocsEditable()
  Node _getNamedItemNS_1(namespaceURI, localName) => wrap_jso(JS("Node ", "#.raw.getNamedItemNS(#, #)", this, unwrap_jso(namespaceURI), unwrap_jso(localName)));

  @DomName('NamedNodeMap.item')
  @DocsEditable()
  Node item(int index) {
    return _item_1(index);
  }
  @JSName('item')
  @DomName('NamedNodeMap.item')
  @DocsEditable()
  Node _item_1(index) => wrap_jso(JS("Node ", "#.raw.item(#)", this, unwrap_jso(index)));

  @DomName('NamedNodeMap.removeNamedItem')
  @DocsEditable()
  Node removeNamedItem(String name) {
    return _removeNamedItem_1(name);
  }
  @JSName('removeNamedItem')
  @DomName('NamedNodeMap.removeNamedItem')
  @DocsEditable()
  Node _removeNamedItem_1(name) => wrap_jso(JS("Node ", "#.raw.removeNamedItem(#)", this, unwrap_jso(name)));

  @DomName('NamedNodeMap.removeNamedItemNS')
  @DocsEditable()
  Node removeNamedItemNS(String namespaceURI, String localName) {
    return _removeNamedItemNS_1(namespaceURI, localName);
  }
  @JSName('removeNamedItemNS')
  @DomName('NamedNodeMap.removeNamedItemNS')
  @DocsEditable()
  Node _removeNamedItemNS_1(namespaceURI, localName) => wrap_jso(JS("Node ", "#.raw.removeNamedItemNS(#, #)", this, unwrap_jso(namespaceURI), unwrap_jso(localName)));

  @DomName('NamedNodeMap.setNamedItem')
  @DocsEditable()
  Node setNamedItem(Node node) {
    return _setNamedItem_1(node);
  }
  @JSName('setNamedItem')
  @DomName('NamedNodeMap.setNamedItem')
  @DocsEditable()
  Node _setNamedItem_1(Node node) => wrap_jso(JS("Node ", "#.raw.setNamedItem(#)", this, unwrap_jso(node)));

  @DomName('NamedNodeMap.setNamedItemNS')
  @DocsEditable()
  Node setNamedItemNS(Node node) {
    return _setNamedItemNS_1(node);
  }
  @JSName('setNamedItemNS')
  @DomName('NamedNodeMap.setNamedItemNS')
  @DocsEditable()
  Node _setNamedItemNS_1(Node node) => wrap_jso(JS("Node ", "#.raw.setNamedItemNS(#)", this, unwrap_jso(node)));
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('XMLHttpRequestProgressEvent')
@Experimental() // nonstandard
@Native("XMLHttpRequestProgressEvent")
class _XMLHttpRequestProgressEvent extends ProgressEvent {
  // To suppress missing implicit constructor warnings.
  factory _XMLHttpRequestProgressEvent._() { throw new UnsupportedError("Not supported"); }


  @Deprecated("Internal Use Only")
  static _XMLHttpRequestProgressEvent internalCreate_XMLHttpRequestProgressEvent() {
    return new _XMLHttpRequestProgressEvent.internal_();
  }

  @Deprecated("Internal Use Only")
  _XMLHttpRequestProgressEvent.internal_() : super.internal_();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


abstract class _AttributeMap implements Map<String, String> {
  final Element _element;

  _AttributeMap(this._element);

  void addAll(Map<String, String> other) {
    other.forEach((k, v) { this[k] = v; });
  }

  bool containsValue(Object value) {
    for (var v in this.values) {
      if (value == v) {
        return true;
      }
    }
    return false;
  }

  String putIfAbsent(String key, String ifAbsent()) {
    if (!containsKey(key)) {
      this[key] = ifAbsent();
    }
    return this[key];
  }

  void clear() {
    for (var key in keys) {
      remove(key);
    }
  }

  void forEach(void f(String key, String value)) {
    for (var key in keys) {
      var value = this[key];
      f(key, value);
    }
  }

  Iterable<String> get keys {
    // TODO: generate a lazy collection instead.
    var attributes = _element._attributes;
    var keys = new List<String>();
    for (int i = 0, len = attributes.length; i < len; i++) {
      if (_matches(attributes[i])) {
        keys.add(attributes[i].name);
      }
    }
    return keys;
  }

  Iterable<String> get values {
    // TODO: generate a lazy collection instead.
    var attributes = _element._attributes;
    var values = new List<String>();
    for (int i = 0, len = attributes.length; i < len; i++) {
      if (_matches(attributes[i])) {
        values.add(attributes[i].value);
      }
    }
    return values;
  }

  /**
   * Returns true if there is no {key, value} pair in the map.
   */
  bool get isEmpty {
    return length == 0;
  }

  /**
   * Returns true if there is at least one {key, value} pair in the map.
   */
  bool get isNotEmpty => !isEmpty;

  /**
   * Checks to see if the node should be included in this map.
   */
  bool _matches(Node node);
}

/**
 * Wrapper to expose [Element.attributes] as a typed map.
 */
class _ElementAttributeMap extends _AttributeMap {

  _ElementAttributeMap(Element element): super(element);

  bool containsKey(Object key) {
    return _element._hasAttribute(key);
  }

  String operator [](Object key) {
    return _element.getAttribute(key);
  }

  void operator []=(String key, String value) {
    _element.setAttribute(key, value);
  }

  String remove(Object key) {
    String value = _element.getAttribute(key);
    _element._removeAttribute(key);
    return value;
  }

  /**
   * The number of {key, value} pairs in the map.
   */
  int get length {
    return keys.length;
  }

  bool _matches(Node node) => node._namespaceUri == null;
}

/**
 * Wrapper to expose namespaced attributes as a typed map.
 */
class _NamespacedAttributeMap extends _AttributeMap {

  final String _namespace;

  _NamespacedAttributeMap(Element element, this._namespace): super(element);

  bool containsKey(Object key) {
    return _element._hasAttributeNS(_namespace, key);
  }

  String operator [](Object key) {
    return _element.getAttributeNS(_namespace, key);
  }

  void operator []=(String key, String value) {
    _element.setAttributeNS(_namespace, key, value);
  }

  String remove(Object key) {
    String value = this[key];
    _element._removeAttributeNS(_namespace, key);
    return value;
  }

  /**
   * The number of {key, value} pairs in the map.
   */
  int get length {
    return keys.length;
  }

  bool _matches(Node node) => node._namespaceUri == _namespace;
}


/**
 * Provides a Map abstraction on top of data-* attributes, similar to the
 * dataSet in the old DOM.
 */
class _DataAttributeMap implements Map<String, String> {

  final Map<String, String> _attributes;

  _DataAttributeMap(this._attributes);

  // interface Map

  void addAll(Map<String, String> other) {
    other.forEach((k, v) { this[k] = v; });
  }

  // TODO: Use lazy iterator when it is available on Map.
  bool containsValue(Object value) => values.any((v) => v == value);

  bool containsKey(Object key) => _attributes.containsKey(_attr(key));

  String operator [](Object key) => _attributes[_attr(key)];

  void operator []=(String key, String value) {
    _attributes[_attr(key)] = value;
  }

  String putIfAbsent(String key, String ifAbsent()) =>
    _attributes.putIfAbsent(_attr(key), ifAbsent);

  String remove(Object key) => _attributes.remove(_attr(key));

  void clear() {
    // Needs to operate on a snapshot since we are mutating the collection.
    for (String key in keys) {
      remove(key);
    }
  }

  void forEach(void f(String key, String value)) {
    _attributes.forEach((String key, String value) {
      if (_matches(key)) {
        f(_strip(key), value);
      }
    });
  }

  Iterable<String> get keys {
    final keys = new List<String>();
    _attributes.forEach((String key, String value) {
      if (_matches(key)) {
        keys.add(_strip(key));
      }
    });
    return keys;
  }

  Iterable<String> get values {
    final values = new List<String>();
    _attributes.forEach((String key, String value) {
      if (_matches(key)) {
        values.add(value);
      }
    });
    return values;
  }

  int get length => keys.length;

  // TODO: Use lazy iterator when it is available on Map.
  bool get isEmpty => length == 0;

  bool get isNotEmpty => !isEmpty;

  // Helpers.
  String _attr(String key) => 'data-${_toHyphenedName(key)}';
  bool _matches(String key) => key.startsWith('data-');
  String _strip(String key) => _toCamelCase(key.substring(5));

  /**
   * Converts a string name with hyphens into an identifier, by removing hyphens
   * and capitalizing the following letter. Optionally [startUppercase] to
   * captialize the first letter.
   */
  String _toCamelCase(String hyphenedName, {bool startUppercase: false}) {
    var segments = hyphenedName.split('-');
    int start = startUppercase ? 0 : 1;
    for (int i = start; i < segments.length; i++) {
      var segment = segments[i];
      if (segment.length > 0) {
        // Character between 'a'..'z' mapped to 'A'..'Z'
        segments[i] = '${segment[0].toUpperCase()}${segment.substring(1)}';
      }
    }
    return segments.join('');
  }

  /** Reverse of [toCamelCase]. */
  String _toHyphenedName(String word) {
    var sb = new StringBuffer();
    for (int i = 0; i < word.length; i++) {
      var lower = word[i].toLowerCase();
      if (word[i] != lower && i > 0) sb.write('-');
      sb.write(lower);
    }
    return sb.toString();
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * An object that can be drawn to a 2D canvas rendering context.
 *
 * The image drawn to the canvas depends on the type of this object:
 *
 * * If this object is an [ImageElement], then this element's image is
 * drawn to the canvas. If this element is an animated image, then this
 * element's poster frame is drawn. If this element has no poster frame, then
 * the first frame of animation is drawn.
 *
 * * If this object is a [VideoElement], then the frame at this element's current
 * playback position is drawn to the canvas.
 *
 * * If this object is a [CanvasElement], then this element's bitmap is drawn to
 * the canvas.
 *
 * **Note:** Currently all versions of Internet Explorer do not support
 * drawing a video element to a canvas. You may also encounter problems drawing
 * a video to a canvas in Firefox if the source of the video is a data URL.
 *
 * ## See also
 *
 * * [CanvasRenderingContext2D.drawImage]
 * * [CanvasRenderingContext2D.drawImageToRect]
 * * [CanvasRenderingContext2D.drawImageScaled]
 * * [CanvasRenderingContext2D.drawImageScaledFromSource]
 *
 * ## Other resources
 *
 * * [Image sources for 2D rendering contexts]
 * (http://www.whatwg.org/specs/web-apps/current-work/multipage/the-canvas-element.html#image-sources-for-2d-rendering-contexts)
 * from WHATWG.
 * * [Drawing images]
 * (http://www.whatwg.org/specs/web-apps/current-work/multipage/the-canvas-element.html#dom-context-2d-drawimage)
 * from WHATWG.
 */
abstract class CanvasImageSource {}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * Top-level container for a browser tab or window.
 *
 * In a web browser, a [WindowBase] object represents any browser window. This
 * object contains the window's state and its relation to other
 * windows, such as which window opened this window.
 *
 * **Note:** This class represents any window, while [Window] is
 * used to access the properties and content of the current window or tab.
 *
 * ## See also
 *
 * * [Window]
 *
 * ## Other resources
 *
 * * [DOM Window](https://developer.mozilla.org/en-US/docs/DOM/window) from MDN.
 * * [Window](http://www.w3.org/TR/Window/) from the W3C.
 */
abstract class WindowBase implements EventTarget {
  // Fields.

  /**
   * The current location of this window.
   *
   *     Location currentLocation = window.location;
   *     print(currentLocation.href); // 'http://www.example.com:80/'
   */
  LocationBase get location;

  /**
   * The current session history for this window.
   *
   * ## Other resources
   *
   * * [Session history and navigation specification]
   * (http://www.whatwg.org/specs/web-apps/current-work/multipage/history.html)
   * from WHATWG.
   */
  HistoryBase get history;

  /**
   * Indicates whether this window has been closed.
   *
   *     print(window.closed); // 'false'
   *     window.close();
   *     print(window.closed); // 'true'
   */
  bool get closed;

  /**
   * A reference to the window that opened this one.
   *
   *     Window thisWindow = window;
   *     WindowBase otherWindow = thisWindow.open('http://www.example.com/', 'foo');
   *     print(otherWindow.opener == thisWindow); // 'true'
   */
  WindowBase get opener;

  /**
   * A reference to the parent of this window.
   *
   * If this [WindowBase] has no parent, [parent] will return a reference to
   * the [WindowBase] itself.
   *
   *     IFrameElement myIFrame = new IFrameElement();
   *     window.document.body.elements.add(myIFrame);
   *     print(myIframe.contentWindow.parent == window) // 'true'
   *
   *     print(window.parent == window) // 'true'
   */
  WindowBase get parent;

  /**
   * A reference to the topmost window in the window hierarchy.
   *
   * If this [WindowBase] is the topmost [WindowBase], [top] will return a
   * reference to the [WindowBase] itself.
   *
   *     // Add an IFrame to the current window.
   *     IFrameElement myIFrame = new IFrameElement();
   *     window.document.body.elements.add(myIFrame);
   *
   *     // Add an IFrame inside of the other IFrame.
   *     IFrameElement innerIFrame = new IFrameElement();
   *     myIFrame.elements.add(innerIFrame);
   *
   *     print(myIframe.contentWindow.top == window) // 'true'
   *     print(innerIFrame.contentWindow.top == window) // 'true'
   *
   *     print(window.top == window) // 'true'
   */
  WindowBase get top;

  // Methods.
  /**
   * Closes the window.
   *
   * This method should only succeed if the [WindowBase] object is
   * **script-closeable** and the window calling [close] is allowed to navigate
   * the window.
   *
   * A window is script-closeable if it is either a window
   * that was opened by another window, or if it is a window with only one
   * document in its history.
   *
   * A window might not be allowed to navigate, and therefore close, another
   * window due to browser security features.
   *
   *     var other = window.open('http://www.example.com', 'foo');
   *     // Closes other window, as it is script-closeable.
   *     other.close();
   *     print(other.closed()); // 'true'
   *
   *     window.location('http://www.mysite.com', 'foo');
   *     // Does not close this window, as the history has changed.
   *     window.close();
   *     print(window.closed()); // 'false'
   *
   * See also:
   *
   * * [Window close discussion](http://www.w3.org/TR/html5/browsers.html#dom-window-close) from the W3C
   */
  void close();

  /**
   * Sends a cross-origin message.
   *
   * ## Other resources
   *
   * * [window.postMessage]
   * (https://developer.mozilla.org/en-US/docs/Web/API/Window.postMessage) from
   * MDN.
   * * [Cross-document messaging]
   * (http://www.whatwg.org/specs/web-apps/current-work/multipage/web-messaging.html)
   * from WHATWG.
   */
  void postMessage(var message, String targetOrigin, [List messagePorts]);
}

abstract class LocationBase {
  void set href(String val);
}

abstract class HistoryBase {
  void back();
  void forward();
  void go(int distance);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/** A Set that stores the CSS class names for an element. */
abstract class CssClassSet implements Set<String> {

  /**
   * Adds the class [value] to the element if it is not on it, removes it if it
   * is.
   *
   * If [shouldAdd] is true, then we always add that [value] to the element. If
   * [shouldAdd] is false then we always remove [value] from the element.
   *
   * If this corresponds to one element, returns `true` if [value] is present
   * after the operation, and returns `false` if [value] is absent after the
   * operation.
   *
   * If this corresponds to many elements, `null` is always returned.
   *
   * [value] must be a valid 'token' representing a single class, i.e. a
   * non-empty string containing no whitespace.  To toggle multiple classes, use
   * [toggleAll].
   */
  bool toggle(String value, [bool shouldAdd]);

  /**
   * Returns [:true:] if classes cannot be added or removed from this
   * [:CssClassSet:].
   */
  bool get frozen;

  /**
   * Determine if this element contains the class [value].
   *
   * This is the Dart equivalent of jQuery's
   * [hasClass](http://api.jquery.com/hasClass/).
   *
   * [value] must be a valid 'token' representing a single class, i.e. a
   * non-empty string containing no whitespace.
   */
  bool contains(Object value);

  /**
   * Add the class [value] to element.
   *
   * [add] and [addAll] are the Dart equivalent of jQuery's
   * [addClass](http://api.jquery.com/addClass/).
   *
   * If this CssClassSet corresponds to one element. Returns true if [value] was
   * added to the set, otherwise false.
   *
   * If this corresponds to many elements, `null` is always returned.
   *
   * [value] must be a valid 'token' representing a single class, i.e. a
   * non-empty string containing no whitespace.  To add multiple classes use
   * [addAll].
   */
  bool add(String value);

  /**
   * Remove the class [value] from element, and return true on successful
   * removal.
   *
   * [remove] and [removeAll] are the Dart equivalent of jQuery's
   * [removeClass](http://api.jquery.com/removeClass/).
   *
   * [value] must be a valid 'token' representing a single class, i.e. a
   * non-empty string containing no whitespace.  To remove multiple classes, use
   * [removeAll].
   */
  bool remove(Object value);

  /**
   * Add all classes specified in [iterable] to element.
   *
   * [add] and [addAll] are the Dart equivalent of jQuery's
   * [addClass](http://api.jquery.com/addClass/).
   *
   * Each element of [iterable] must be a valid 'token' representing a single
   * class, i.e. a non-empty string containing no whitespace.
   */
  void addAll(Iterable<String> iterable);

  /**
   * Remove all classes specified in [iterable] from element.
   *
   * [remove] and [removeAll] are the Dart equivalent of jQuery's
   * [removeClass](http://api.jquery.com/removeClass/).
   *
   * Each element of [iterable] must be a valid 'token' representing a single
   * class, i.e. a non-empty string containing no whitespace.
   */
  void removeAll(Iterable<Object> iterable);

  /**
   * Toggles all classes specified in [iterable] on element.
   *
   * Iterate through [iterable]'s items, and add it if it is not on it, or
   * remove it if it is. This is the Dart equivalent of jQuery's
   * [toggleClass](http://api.jquery.com/toggleClass/).
   * If [shouldAdd] is true, then we always add all the classes in [iterable]
   * element. If [shouldAdd] is false then we always remove all the classes in
   * [iterable] from the element.
   *
   * Each element of [iterable] must be a valid 'token' representing a single
   * class, i.e. a non-empty string containing no whitespace.
   */
  void toggleAll(Iterable<String> iterable, [bool shouldAdd]);
}
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * A rectangle representing all the content of the element in the
 * [box model](http://www.w3.org/TR/CSS2/box.html).
 */
class _ContentCssRect extends CssRect {

  _ContentCssRect(element) : super(element);

  num get height => _element.offsetHeight +
      _addOrSubtractToBoxModel(_HEIGHT, _CONTENT);

  num get width => _element.offsetWidth +
      _addOrSubtractToBoxModel(_WIDTH, _CONTENT);

  /**
   * Set the height to `newHeight`.
   *
   * newHeight can be either a [num] representing the height in pixels or a
   * [Dimension] object. Values of newHeight that are less than zero are
   * converted to effectively setting the height to 0. This is equivalent to the
   * `height` function in jQuery and the calculated `height` CSS value,
   * converted to a num in pixels.
   */
  set height(Object newHeight) {
    if (newHeight is Dimension) {
      var result = (newHeight.value < 0) ? new Dimension.px(0) : newHeight;
      _element.style.height = result.toString();
    } else {
      var result =  ((newHeight as int) < 0) ? 0 : newHeight;
      _element.style.height = '${result}px';
    }
  }

  /**
   * Set the current computed width in pixels of this element.
   *
   * newWidth can be either a [num] representing the width in pixels or a
   * [Dimension] object. This is equivalent to the `width` function in jQuery
   * and the calculated
   * `width` CSS value, converted to a dimensionless num in pixels.
   */
  set width(Object newWidth) {
    if (newWidth is Dimension) {
      var result = (newWidth.value < 0) ? new Dimension.px(0) : newWidth;
      _element.style.width = result.toString();
    } else {
      var result =  ((newWidth as int) < 0) ? 0 : newWidth;
      _element.style.width = '${result}px';
    }
  }

  num get left => _element.getBoundingClientRect().left -
      _addOrSubtractToBoxModel(['left'], _CONTENT);
  num get top => _element.getBoundingClientRect().top -
      _addOrSubtractToBoxModel(['top'], _CONTENT);
}

/**
 * A list of element content rectangles in the
 * [box model](http://www.w3.org/TR/CSS2/box.html).
 */
class _ContentCssListRect extends _ContentCssRect {
  List<Element> _elementList;

  _ContentCssListRect(elementList) : super(elementList.first) {
    _elementList = elementList;
  }

  /**
   * Set the height to `newHeight`.
   *
   * Values of newHeight that are less than zero are converted to effectively
   * setting the height to 0. This is equivalent to the `height`
   * function in jQuery and the calculated `height` CSS value, converted to a
   * num in pixels.
   */
  set height(newHeight) {
    _elementList.forEach((e) => e.contentEdge.height = newHeight);
  }

  /**
   * Set the current computed width in pixels of this element.
   *
   * This is equivalent to the `width` function in jQuery and the calculated
   * `width` CSS value, converted to a dimensionless num in pixels.
   */
  set width(newWidth) {
    _elementList.forEach((e) => e.contentEdge.width = newWidth);
  }
}

/**
 * A rectangle representing the dimensions of the space occupied by the
 * element's content + padding in the
 * [box model](http://www.w3.org/TR/CSS2/box.html).
 */
class _PaddingCssRect extends CssRect {
  _PaddingCssRect(element) : super(element);
  num get height => _element.offsetHeight +
      _addOrSubtractToBoxModel(_HEIGHT, _PADDING);
  num get width => _element.offsetWidth +
      _addOrSubtractToBoxModel(_WIDTH, _PADDING);

  num get left => _element.getBoundingClientRect().left -
      _addOrSubtractToBoxModel(['left'], _PADDING);
  num get top => _element.getBoundingClientRect().top -
      _addOrSubtractToBoxModel(['top'], _PADDING);
}

/**
 * A rectangle representing the dimensions of the space occupied by the
 * element's content + padding + border in the
 * [box model](http://www.w3.org/TR/CSS2/box.html).
 */
class _BorderCssRect extends CssRect {
  _BorderCssRect(element) : super(element);
  num get height => _element.offsetHeight;
  num get width => _element.offsetWidth;

  num get left => _element.getBoundingClientRect().left;
  num get top => _element.getBoundingClientRect().top;
}

/**
 * A rectangle representing the dimensions of the space occupied by the
 * element's content + padding + border + margin in the
 * [box model](http://www.w3.org/TR/CSS2/box.html).
 */
class _MarginCssRect extends CssRect {
  _MarginCssRect(element) : super(element);
  num get height => _element.offsetHeight +
      _addOrSubtractToBoxModel(_HEIGHT, _MARGIN);
  num get width =>
      _element.offsetWidth + _addOrSubtractToBoxModel(_WIDTH, _MARGIN);

  num get left => _element.getBoundingClientRect().left -
      _addOrSubtractToBoxModel(['left'], _MARGIN);
  num get top => _element.getBoundingClientRect().top -
      _addOrSubtractToBoxModel(['top'], _MARGIN);
}

/**
 * A class for representing CSS dimensions.
 *
 * In contrast to the more general purpose [Rectangle] class, this class's
 * values are mutable, so one can change the height of an element
 * programmatically.
 *
 * _Important_ _note_: use of these methods will perform CSS calculations that
 * can trigger a browser reflow. Therefore, use of these properties _during_ an
 * animation frame is discouraged. See also:
 * [Browser Reflow](https://developers.google.com/speed/articles/reflow)
 */
abstract class CssRect extends MutableRectangle<num> {
  Element _element;

  CssRect(this._element) : super(0, 0, 0, 0);

  num get left;

  num get top;

  /**
   * The height of this rectangle.
   *
   * This is equivalent to the `height` function in jQuery and the calculated
   * `height` CSS value, converted to a dimensionless num in pixels. Unlike
   * [getBoundingClientRect], `height` will return the same numerical width if
   * the element is hidden or not.
   */
  num get height;

  /**
   * The width of this rectangle.
   *
   * This is equivalent to the `width` function in jQuery and the calculated
   * `width` CSS value, converted to a dimensionless num in pixels. Unlike
   * [getBoundingClientRect], `width` will return the same numerical width if
   * the element is hidden or not.
   */
  num get width;

  /**
   * Set the height to `newHeight`.
   *
   * newHeight can be either a [num] representing the height in pixels or a
   * [Dimension] object. Values of newHeight that are less than zero are
   * converted to effectively setting the height to 0. This is equivalent to the
   * `height` function in jQuery and the calculated `height` CSS value,
   * converted to a num in pixels.
   *
   * Note that only the content height can actually be set via this method.
   */
  set height(newHeight) {
    throw new UnsupportedError("Can only set height for content rect.");
  }

  /**
   * Set the current computed width in pixels of this element.
   *
   * newWidth can be either a [num] representing the width in pixels or a
   * [Dimension] object. This is equivalent to the `width` function in jQuery
   * and the calculated
   * `width` CSS value, converted to a dimensionless num in pixels.
   *
   * Note that only the content width can be set via this method.
   */
  set width(newWidth) {
    throw new UnsupportedError("Can only set width for content rect.");
  }

  /**
   * Return a value that is used to modify the initial height or width
   * measurement of an element. Depending on the value (ideally an enum) passed
   * to augmentingMeasurement, we may need to add or subtract margin, padding,
   * or border values, depending on the measurement we're trying to obtain.
   */
  num _addOrSubtractToBoxModel(List<String> dimensions,
      String augmentingMeasurement) {
    // getComputedStyle always returns pixel values (hence, computed), so we're
    // always dealing with pixels in this method.
    var styles = _element.getComputedStyle();

    var val = 0;

    for (String measurement in dimensions) {
      // The border-box and default box model both exclude margin in the regular
      // height/width calculation, so add it if we want it for this measurement.
      if (augmentingMeasurement == _MARGIN) {
        val += new Dimension.css(styles.getPropertyValue(
            '$augmentingMeasurement-$measurement')).value;
      }

      // The border-box includes padding and border, so remove it if we want
      // just the content itself.
      if (augmentingMeasurement == _CONTENT) {
      	val -= new Dimension.css(
            styles.getPropertyValue('${_PADDING}-$measurement')).value;
      }

      // At this point, we don't wan't to augment with border or margin,
      // so remove border.
      if (augmentingMeasurement != _MARGIN) {
	      val -= new Dimension.css(styles.getPropertyValue(
            'border-${measurement}-width')).value;
      }
    }
    return val;
  }
}

final _HEIGHT = ['top', 'bottom'];
final _WIDTH = ['right', 'left'];
final _CONTENT = 'content';
final _PADDING = 'padding';
final _MARGIN = 'margin';
// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * A set (union) of the CSS classes that are present in a set of elements.
 * Implemented separately from _ElementCssClassSet for performance.
 */
class _MultiElementCssClassSet extends CssClassSetImpl {
  final Iterable<Element> _elementIterable;

  // TODO(sra): Perhaps we should store the DomTokenList instead.
  final List<CssClassSetImpl> _sets;

  factory _MultiElementCssClassSet(Iterable<Element> elements) {
    return new _MultiElementCssClassSet._(elements,
        elements.map((Element e) => e.classes).toList());
  }

  _MultiElementCssClassSet._(this._elementIterable, this._sets);

  Set<String> readClasses() {
    var s = new LinkedHashSet<String>();
    _sets.forEach((CssClassSetImpl e) => s.addAll(e.readClasses()));
    return s;
  }

  void writeClasses(Set<String> s) {
    var classes = s.join(' ');
    for (Element e in _elementIterable) {
      e.className = classes;
    }
  }

  /**
   * Helper method used to modify the set of css classes on this element.
   *
   *   f - callback with:
   *   s - a Set of all the css class name currently on this element.
   *
   *   After f returns, the modified set is written to the
   *       className property of this element.
   */
  modify( f(Set<String> s)) {
    _sets.forEach((CssClassSetImpl e) => e.modify(f));
  }

  /**
   * Adds the class [value] to the element if it is not on it, removes it if it
   * is.
   *
   * TODO(sra): It seems wrong to collect a 'changed' flag like this when the
   * underlying toggle returns an 'is set' flag.
   */
  bool toggle(String value, [bool shouldAdd]) =>
      _sets.fold(false,
          (bool changed, CssClassSetImpl e) =>
              e.toggle(value, shouldAdd) || changed);

  /**
   * Remove the class [value] from element, and return true on successful
   * removal.
   *
   * This is the Dart equivalent of jQuery's
   * [removeClass](http://api.jquery.com/removeClass/).
   */
  bool remove(Object value) => _sets.fold(false,
      (bool changed, CssClassSetImpl e) => e.remove(value) || changed);
}

class _ElementCssClassSet extends CssClassSetImpl {
  final Element _element;

  _ElementCssClassSet(this._element);

  Set<String> readClasses() {
    var s = new LinkedHashSet<String>();
    var classname = _element.className;

    for (String name in classname.split(' ')) {
      String trimmed = name.trim();
      if (!trimmed.isEmpty) {
        s.add(trimmed);
      }
    }
    return s;
  }

  void writeClasses(Set<String> s) {
    _element.className = s.join(' ');
  }

  int get length => _classListLength(_classListOf(_element));
  bool get isEmpty => length == 0;
  bool get isNotEmpty => length != 0;

  void clear() {
    _element.className = '';
  }

  bool contains(Object value) {
    return _contains(_element, value);
  }

  bool add(String value) {
    return _add(_element, value);
  }

  bool remove(Object value) {
    return value is String && _remove(_element, value);
  }

  bool toggle(String value, [bool shouldAdd]) {
    return _toggle(_element, value, shouldAdd);
  }

  void addAll(Iterable<String> iterable) {
    _addAll(_element, iterable);
  }

  void removeAll(Iterable<Object> iterable) {
    _removeAll(_element, iterable);
  }

  void retainAll(Iterable<Object> iterable) {
    _removeWhere(_element, iterable.toSet().contains, false);
  }

  void removeWhere(bool test(String name)) {
    _removeWhere(_element, test, true);
  }

  void retainWhere(bool test(String name)) {
    _removeWhere(_element, test, false);
  }

  static bool _contains(Element _element, Object value) {
    return value is String && _classListContains(_classListOf(_element), value);
  }

  static bool _add(Element _element, String value) {
    DomTokenList list = _classListOf(_element);
    // Compute returned result independently of action upon the set.
    bool added = !_classListContainsBeforeAddOrRemove(list, value);
    _classListAdd(list, value);
    return added;
  }

  static bool _remove(Element _element, String value) {
    DomTokenList list = _classListOf(_element);
    bool removed = _classListContainsBeforeAddOrRemove(list, value);
    _classListRemove(list, value);
    return removed;
  }

  static bool _toggle(Element _element, String value, bool shouldAdd) {
    // There is no value that can be passed as the second argument of
    // DomTokenList.toggle that behaves the same as passing one argument.
    // `null` is seen as false, meaning 'remove'.
    return shouldAdd == null
        ? _toggleDefault(_element, value)
        : _toggleOnOff(_element, value, shouldAdd);
  }

  static bool _toggleDefault(Element _element, String value) {
    DomTokenList list = _classListOf(_element);
    return _classListToggle1(list, value);
  }

  static bool _toggleOnOff(Element _element, String value, bool shouldAdd) {
    DomTokenList list = _classListOf(_element);
    // IE's toggle does not take a second parameter. We would prefer:
    //
    //    return _classListToggle2(list, value, shouldAdd);
    //
    if (shouldAdd) {
      _classListAdd(list, value);
      return true;
    } else {
      _classListRemove(list, value);
      return false;
    }
  }

  static void _addAll(Element _element, Iterable<String> iterable) {
    DomTokenList list = _classListOf(_element);
    for (String value in iterable) {
      _classListAdd(list, value);
    }
  }

  static void _removeAll(Element _element, Iterable<String> iterable) {
    DomTokenList list = _classListOf(_element);
    for (var value in iterable) {
      _classListRemove(list, value);
    }
  }

  static void _removeWhere(
      Element _element, bool test(String name), bool doRemove) {
    DomTokenList list = _classListOf(_element);
    int i = 0;
    while (i < _classListLength(list)) {
      String item = list.item(i);
      if (doRemove == test(item)) {
        _classListRemove(list, item);
      } else {
        ++i;
      }
    }
  }

  // A collection of static methods for DomTokenList. These methods are a
  // work-around for the lack of annotations to express the full behaviour of
  // the DomTokenList methods.

  static DomTokenList _classListOf(Element e) =>
    wrap_jso(JS('returns:DomTokenList;creates:DomTokenList;effects:none;depends:all;',
            '#.classList', e.raw));

  static int _classListLength(DomTokenList list) =>
      JS('returns:JSUInt31;effects:none;depends:all;', '#.length', list.raw);

  static bool _classListContains(DomTokenList list, String value) =>
      JS('returns:bool;effects:none;depends:all',
          '#.contains(#)', list.raw, value);

  static bool _classListContainsBeforeAddOrRemove(
      DomTokenList list, String value) =>
      // 'throws:never' is a lie, since 'contains' will throw on an illegal
      // token.  However, we always call this function immediately prior to
      // add/remove/toggle with the same token.  Often the result of 'contains'
      // is unused and the lie makes it possible for the 'contains' instruction
      // to be removed.
      JS('returns:bool;effects:none;depends:all;throws:null(1)',
          '#.contains(#)', list.raw, value);

  static void _classListAdd(DomTokenList list, String value) {
    // list.add(value);
    JS('', '#.add(#)', list.raw, value);
  }

  static void _classListRemove(DomTokenList list, String value) {
    // list.remove(value);
    JS('', '#.remove(#)', list.raw, value);
  }

  static bool _classListToggle1(DomTokenList list, String value) {
    return JS('bool', '#.toggle(#)', list.raw, value);
  }

  static bool _classListToggle2(
      DomTokenList list, String value, bool shouldAdd) {
    return JS('bool', '#.toggle(#, #)', list.raw, value, shouldAdd);
  }
}

/**
 * Class representing a
 * [length measurement](https://developer.mozilla.org/en-US/docs/Web/CSS/length)
 * in CSS.
 */
@Experimental()
class Dimension {
  num _value;
  String _unit;

  /** Set this CSS Dimension to a percentage `value`. */
  Dimension.percent(this._value) : _unit = '%';

  /** Set this CSS Dimension to a pixel `value`. */
  Dimension.px(this._value) : _unit = 'px';

  /** Set this CSS Dimension to a pica `value`. */
  Dimension.pc(this._value) : _unit = 'pc';

  /** Set this CSS Dimension to a point `value`. */
  Dimension.pt(this._value) : _unit = 'pt';

  /** Set this CSS Dimension to an inch `value`. */
  Dimension.inch(this._value) : _unit = 'in';

  /** Set this CSS Dimension to a centimeter `value`. */
  Dimension.cm(this._value) : _unit = 'cm';

  /** Set this CSS Dimension to a millimeter `value`. */
  Dimension.mm(this._value) : _unit = 'mm';

  /**
   * Set this CSS Dimension to the specified number of ems.
   *
   * 1em is equal to the current font size. (So 2ems is equal to double the font
   * size). This is useful for producing website layouts that scale nicely with
   * the user's desired font size.
   */
  Dimension.em(this._value) : _unit = 'em';

  /**
   * Set this CSS Dimension to the specified number of x-heights.
   *
   * One ex is equal to the the x-height of a font's baseline to its mean line,
   * generally the height of the letter "x" in the font, which is usually about
   * half the font-size.
   */
  Dimension.ex(this._value) : _unit = 'ex';

  /**
   * Construct a Dimension object from the valid, simple CSS string `cssValue`
   * that represents a distance measurement.
   *
   * This constructor is intended as a convenience method for working with
   * simplistic CSS length measurements. Non-numeric values such as `auto` or
   * `inherit` or invalid CSS will cause this constructor to throw a
   * FormatError.
   */
  Dimension.css(String cssValue) {
    if (cssValue == '') cssValue = '0px';
    if (cssValue.endsWith('%')) {
      _unit = '%';
    } else {
      _unit = cssValue.substring(cssValue.length - 2);
    }
    if (cssValue.contains('.')) {
      _value = double.parse(cssValue.substring(0,
          cssValue.length - _unit.length));
    } else {
      _value = int.parse(cssValue.substring(0, cssValue.length - _unit.length));
    }
  }

  /** Print out the CSS String representation of this value. */
  String toString() {
    return '${_value}${_unit}';
  }

  /** Return a unitless, numerical value of this CSS value. */
  num get value => this._value;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


typedef EventListener(Event event);
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * A factory to expose DOM events as Streams.
 */
class EventStreamProvider<T extends Event> {
  final String _eventType;

  const EventStreamProvider(this._eventType);

  /**
   * Gets a [Stream] for this event type, on the specified target.
   *
   * This will always return a broadcast stream so multiple listeners can be
   * used simultaneously.
   *
   * This may be used to capture DOM events:
   *
   *     Element.keyDownEvent.forTarget(element, useCapture: true).listen(...);
   *
   *     // Alternate method:
   *     Element.keyDownEvent.forTarget(element).capture(...);
   *
   * Or for listening to an event which will bubble through the DOM tree:
   *
   *     MediaElement.pauseEvent.forTarget(document.body).listen(...);
   *
   * See also:
   *
   * [addEventListener](http://docs.webplatform.org/wiki/dom/methods/addEventListener)
   */
  Stream<T> forTarget(EventTarget e, {bool useCapture: false}) =>
    new _EventStream(e, _eventType, useCapture);

  /**
   * Gets an [ElementEventStream] for this event type, on the specified element.
   *
   * This will always return a broadcast stream so multiple listeners can be
   * used simultaneously.
   *
   * This may be used to capture DOM events:
   *
   *     Element.keyDownEvent.forElement(element, useCapture: true).listen(...);
   *
   *     // Alternate method:
   *     Element.keyDownEvent.forElement(element).capture(...);
   *
   * Or for listening to an event which will bubble through the DOM tree:
   *
   *     MediaElement.pauseEvent.forElement(document.body).listen(...);
   *
   * See also:
   *
   * [addEventListener](http://docs.webplatform.org/wiki/dom/methods/addEventListener)
   */
  ElementStream<T> forElement(Element e, {bool useCapture: false}) {
    return new _ElementEventStreamImpl(e, _eventType, useCapture);
  }

  /**
   * Gets an [ElementEventStream] for this event type, on the list of elements.
   *
   * This will always return a broadcast stream so multiple listeners can be
   * used simultaneously.
   *
   * This may be used to capture DOM events:
   *
   *     Element.keyDownEvent._forElementList(element, useCapture: true).listen(...);
   *
   * See also:
   *
   * [addEventListener](http://docs.webplatform.org/wiki/dom/methods/addEventListener)
   */
  ElementStream<T> _forElementList(ElementList e, {bool useCapture: false}) {
    return new _ElementListEventStreamImpl(e, _eventType, useCapture);
  }

  /**
   * Gets the type of the event which this would listen for on the specified
   * event target.
   *
   * The target is necessary because some browsers may use different event names
   * for the same purpose and the target allows differentiating browser support.
   */
  String getEventType(EventTarget target) {
    return _eventType;
  }
}

/** A specialized Stream available to [Element]s to enable event delegation. */
abstract class ElementStream<T extends Event> implements Stream<T> {
  /**
   * Return a stream that only fires when the particular event fires for
   * elements matching the specified CSS selector.
   *
   * This is the Dart equivalent to jQuery's
   * [delegate](http://api.jquery.com/delegate/).
   */
  Stream<T> matches(String selector);

  /**
   * Adds a capturing subscription to this stream.
   *
   * If the target of the event is a descendant of the element from which this
   * stream derives then [onData] is called before the event propagates down to
   * the target. This is the opposite of bubbling behavior, where the event
   * is first processed for the event target and then bubbles upward.
   *
   * ## Other resources
   *
   * * [Event Capture]
   * (http://www.w3.org/TR/DOM-Level-2-Events/events.html#Events-flow-capture)
   * from the W3C DOM Events specification.
   */
  StreamSubscription<T> capture(void onData(T event));
}

/**
 * Adapter for exposing DOM events as Dart streams.
 */
class _EventStream<T extends Event> extends Stream<T> {
  final EventTarget _target;
  final String _eventType;
  final bool _useCapture;

  _EventStream(this._target, this._eventType, this._useCapture);

  // DOM events are inherently multi-subscribers.
  Stream<T> asBroadcastStream({void onListen(StreamSubscription<T> subscription),
                               void onCancel(StreamSubscription<T> subscription)})
      => this;
  bool get isBroadcast => true;

  StreamSubscription<T> listen(void onData(T event),
      { Function onError,
        void onDone(),
        bool cancelOnError}) {

    return new _EventStreamSubscription<T>(
        this._target, this._eventType, onData, this._useCapture);
  }
}

/**
 * Adapter for exposing DOM Element events as streams, while also allowing
 * event delegation.
 */
class _ElementEventStreamImpl<T extends Event> extends _EventStream<T>
    implements ElementStream<T> {
  _ElementEventStreamImpl(target, eventType, useCapture) :
      super(target, eventType, useCapture);

  Stream<T> matches(String selector) => this.where(
      (event) => event.target.matchesWithAncestors(selector)).map((e) {
        e._selector = selector;
        return e;
      });

  StreamSubscription<T> capture(void onData(T event)) =>
    new _EventStreamSubscription<T>(
        this._target, this._eventType, onData, true);
}

/**
 * Adapter for exposing events on a collection of DOM Elements as streams,
 * while also allowing event delegation.
 */
class _ElementListEventStreamImpl<T extends Event> extends Stream<T>
    implements ElementStream<T> {
  final Iterable<Element> _targetList;
  final bool _useCapture;
  final String _eventType;

  _ElementListEventStreamImpl(
      this._targetList, this._eventType, this._useCapture);

  Stream<T> matches(String selector) => this.where(
      (event) => event.target.matchesWithAncestors(selector)).map((e) {
        e._selector = selector;
        return e;
      });

  // Delegate all regular Stream behavior to a wrapped Stream.
  StreamSubscription<T> listen(void onData(T event),
      { Function onError,
        void onDone(),
        bool cancelOnError}) {
    var pool = new _StreamPool.broadcast();
    for (var target in _targetList) {
      pool.add(new _EventStream(target, _eventType, _useCapture));
    }
    return pool.stream.listen(onData, onError: onError, onDone: onDone,
          cancelOnError: cancelOnError);
  }

  StreamSubscription<T> capture(void onData(T event)) {
    var pool = new _StreamPool.broadcast();
    for (var target in _targetList) {
      pool.add(new _EventStream(target, _eventType, true));
    }
    return pool.stream.listen(onData);
  }

  Stream<T> asBroadcastStream({void onListen(StreamSubscription<T> subscription),
                               void onCancel(StreamSubscription<T> subscription)})
      => this;
  bool get isBroadcast => true;
}

class _EventStreamSubscription<T extends Event> extends StreamSubscription<T> {
  int _pauseCount = 0;
  EventTarget _target;
  final String _eventType;
  var _onData;
  final bool _useCapture;

  _EventStreamSubscription(this._target, this._eventType, onData,
      this._useCapture) : _onData = _wrapZone(onData) {
    _tryResume();
  }

  Future cancel() {
    if (_canceled) return null;

    _unlisten();
    // Clear out the target to indicate this is complete.
    _target = null;
    _onData = null;
    return null;
  }

  bool get _canceled => _target == null;

  void onData(void handleData(T event)) {
    if (_canceled) {
      throw new StateError("Subscription has been canceled.");
    }
    // Remove current event listener.
    _unlisten();

    _onData = _wrapZone(handleData);
    _tryResume();
  }

  /// Has no effect.
  void onError(Function handleError) {}

  /// Has no effect.
  void onDone(void handleDone()) {}

  void pause([Future resumeSignal]) {
    if (_canceled) return;
    ++_pauseCount;
    _unlisten();

    if (resumeSignal != null) {
      resumeSignal.whenComplete(resume);
    }
  }

  bool get isPaused => _pauseCount > 0;

  void resume() {
    if (_canceled || !isPaused) return;
    --_pauseCount;
    _tryResume();
  }

  void _tryResume() {
    if (_onData != null && !isPaused) {
      _target.addEventListener(_eventType, _onData, _useCapture);
    }
  }

  void _unlisten() {
    if (_onData != null) {
      _target.removeEventListener(_eventType, _onData, _useCapture);
    }
  }

  Future asFuture([var futureValue]) {
    // We just need a future that will never succeed or fail.
    Completer completer = new Completer();
    return completer.future;
  }
}

/**
 * A stream of custom events, which enables the user to "fire" (add) their own
 * custom events to a stream.
 */
abstract class CustomStream<T extends Event> implements Stream<T> {
  /**
   * Add the following custom event to the stream for dispatching to interested
   * listeners.
   */
  void add(T event);
}

class _CustomEventStreamImpl<T extends Event> extends Stream<T>
    implements CustomStream<T> {
  StreamController<T> _streamController;
  /** The type of event this stream is providing (e.g. "keydown"). */
  String _type;

  _CustomEventStreamImpl(String type) {
    _type = type;
    _streamController = new StreamController.broadcast(sync: true);
  }

  // Delegate all regular Stream behavior to our wrapped Stream.
  StreamSubscription<T> listen(void onData(T event),
      { Function onError,
        void onDone(),
        bool cancelOnError}) {
    return _streamController.stream.listen(onData, onError: onError,
        onDone: onDone, cancelOnError: cancelOnError);
  }

  Stream<T> asBroadcastStream({void onListen(StreamSubscription<T> subscription),
                               void onCancel(StreamSubscription<T> subscription)})
      => _streamController.stream;

  bool get isBroadcast => true;

  void add(T event) {
    if (event.type == _type) _streamController.add(event);
  }
}

class _CustomKeyEventStreamImpl extends _CustomEventStreamImpl<KeyEvent>
    implements CustomStream<KeyEvent> {
  _CustomKeyEventStreamImpl(String type) : super(type);

  void add(KeyEvent event) {
    if (event.type == _type) {
      event.currentTarget.dispatchEvent(event._parent);
      _streamController.add(event);
    }
  }
}

/**
 * A pool of streams whose events are unified and emitted through a central
 * stream.
 */
// TODO (efortuna): Remove this when Issue 12218 is addressed.
class _StreamPool<T> {
  StreamController<T> _controller;

  /// Subscriptions to the streams that make up the pool.
  var _subscriptions = new Map<Stream<T>, StreamSubscription<T>>();

  /**
   * Creates a new stream pool where [stream] can be listened to more than
   * once.
   *
   * Any events from buffered streams in the pool will be emitted immediately,
   * regardless of whether [stream] has any subscribers.
   */
  _StreamPool.broadcast() {
    _controller = new StreamController<T>.broadcast(sync: true,
        onCancel: close);
  }

  /**
   * The stream through which all events from streams in the pool are emitted.
   */
  Stream<T> get stream => _controller.stream;

  /**
   * Adds [stream] as a member of this pool.
   *
   * Any events from [stream] will be emitted through [this.stream]. If
   * [stream] is sync, they'll be emitted synchronously; if [stream] is async,
   * they'll be emitted asynchronously.
   */
  void add(Stream<T> stream) {
    if (_subscriptions.containsKey(stream)) return;
    _subscriptions[stream] = stream.listen(_controller.add,
        onError: _controller.addError,
        onDone: () => remove(stream));
  }

  /** Removes [stream] as a member of this pool. */
  void remove(Stream<T> stream) {
    var subscription = _subscriptions.remove(stream);
    if (subscription != null) subscription.cancel();
  }

  /** Removes all streams from this pool and closes [stream]. */
  void close() {
    for (var subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _controller.close();
  }
}

/**
 * A factory to expose DOM events as streams, where the DOM event name has to
 * be determined on the fly (for example, mouse wheel events).
 */
class _CustomEventStreamProvider<T extends Event>
    implements EventStreamProvider<T> {

  final _eventTypeGetter;
  const _CustomEventStreamProvider(this._eventTypeGetter);

  Stream<T> forTarget(EventTarget e, {bool useCapture: false}) {
    return new _EventStream(e, _eventTypeGetter(e), useCapture);
  }

  ElementStream<T> forElement(Element e, {bool useCapture: false}) {
    return new _ElementEventStreamImpl(e, _eventTypeGetter(e), useCapture);
  }

  ElementStream<T> _forElementList(ElementList e,
      {bool useCapture: false}) {
    return new _ElementListEventStreamImpl(e, _eventTypeGetter(e), useCapture);
  }

  String getEventType(EventTarget target) {
    return _eventTypeGetter(target);
  }

  String get _eventType =>
      throw new UnsupportedError('Access type through getEventType method.');
}
// DO NOT EDIT- this file is generated from running tool/generator.sh.

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * A Dart DOM validator generated from Caja whitelists.
 *
 * This contains a whitelist of known HTML tagNames and attributes and will only
 * accept known good values.
 *
 * See also:
 *
 * * <https://code.google.com/p/google-caja/wiki/CajaWhitelists>
 */
class _Html5NodeValidator implements NodeValidator {

  static final Set<String> _allowedElements = new Set.from([
    'A',
    'ABBR',
    'ACRONYM',
    'ADDRESS',
    'AREA',
    'ARTICLE',
    'ASIDE',
    'AUDIO',
    'B',
    'BDI',
    'BDO',
    'BIG',
    'BLOCKQUOTE',
    'BR',
    'BUTTON',
    'CANVAS',
    'CAPTION',
    'CENTER',
    'CITE',
    'CODE',
    'COL',
    'COLGROUP',
    'COMMAND',
    'DATA',
    'DATALIST',
    'DD',
    'DEL',
    'DETAILS',
    'DFN',
    'DIR',
    'DIV',
    'DL',
    'DT',
    'EM',
    'FIELDSET',
    'FIGCAPTION',
    'FIGURE',
    'FONT',
    'FOOTER',
    'FORM',
    'H1',
    'H2',
    'H3',
    'H4',
    'H5',
    'H6',
    'HEADER',
    'HGROUP',
    'HR',
    'I',
    'IFRAME',
    'IMG',
    'INPUT',
    'INS',
    'KBD',
    'LABEL',
    'LEGEND',
    'LI',
    'MAP',
    'MARK',
    'MENU',
    'METER',
    'NAV',
    'NOBR',
    'OL',
    'OPTGROUP',
    'OPTION',
    'OUTPUT',
    'P',
    'PRE',
    'PROGRESS',
    'Q',
    'S',
    'SAMP',
    'SECTION',
    'SELECT',
    'SMALL',
    'SOURCE',
    'SPAN',
    'STRIKE',
    'STRONG',
    'SUB',
    'SUMMARY',
    'SUP',
    'TABLE',
    'TBODY',
    'TD',
    'TEXTAREA',
    'TFOOT',
    'TH',
    'THEAD',
    'TIME',
    'TR',
    'TRACK',
    'TT',
    'U',
    'UL',
    'VAR',
    'VIDEO',
    'WBR',
  ]);

  static const _standardAttributes = const <String>[
    '*::class',
    '*::dir',
    '*::draggable',
    '*::hidden',
    '*::id',
    '*::inert',
    '*::itemprop',
    '*::itemref',
    '*::itemscope',
    '*::lang',
    '*::spellcheck',
    '*::title',
    '*::translate',
    'A::accesskey',
    'A::coords',
    'A::hreflang',
    'A::name',
    'A::shape',
    'A::tabindex',
    'A::target',
    'A::type',
    'AREA::accesskey',
    'AREA::alt',
    'AREA::coords',
    'AREA::nohref',
    'AREA::shape',
    'AREA::tabindex',
    'AREA::target',
    'AUDIO::controls',
    'AUDIO::loop',
    'AUDIO::mediagroup',
    'AUDIO::muted',
    'AUDIO::preload',
    'BDO::dir',
    'BODY::alink',
    'BODY::bgcolor',
    'BODY::link',
    'BODY::text',
    'BODY::vlink',
    'BR::clear',
    'BUTTON::accesskey',
    'BUTTON::disabled',
    'BUTTON::name',
    'BUTTON::tabindex',
    'BUTTON::type',
    'BUTTON::value',
    'CANVAS::height',
    'CANVAS::width',
    'CAPTION::align',
    'COL::align',
    'COL::char',
    'COL::charoff',
    'COL::span',
    'COL::valign',
    'COL::width',
    'COLGROUP::align',
    'COLGROUP::char',
    'COLGROUP::charoff',
    'COLGROUP::span',
    'COLGROUP::valign',
    'COLGROUP::width',
    'COMMAND::checked',
    'COMMAND::command',
    'COMMAND::disabled',
    'COMMAND::label',
    'COMMAND::radiogroup',
    'COMMAND::type',
    'DATA::value',
    'DEL::datetime',
    'DETAILS::open',
    'DIR::compact',
    'DIV::align',
    'DL::compact',
    'FIELDSET::disabled',
    'FONT::color',
    'FONT::face',
    'FONT::size',
    'FORM::accept',
    'FORM::autocomplete',
    'FORM::enctype',
    'FORM::method',
    'FORM::name',
    'FORM::novalidate',
    'FORM::target',
    'FRAME::name',
    'H1::align',
    'H2::align',
    'H3::align',
    'H4::align',
    'H5::align',
    'H6::align',
    'HR::align',
    'HR::noshade',
    'HR::size',
    'HR::width',
    'HTML::version',
    'IFRAME::align',
    'IFRAME::frameborder',
    'IFRAME::height',
    'IFRAME::marginheight',
    'IFRAME::marginwidth',
    'IFRAME::width',
    'IMG::align',
    'IMG::alt',
    'IMG::border',
    'IMG::height',
    'IMG::hspace',
    'IMG::ismap',
    'IMG::name',
    'IMG::usemap',
    'IMG::vspace',
    'IMG::width',
    'INPUT::accept',
    'INPUT::accesskey',
    'INPUT::align',
    'INPUT::alt',
    'INPUT::autocomplete',
    'INPUT::checked',
    'INPUT::disabled',
    'INPUT::inputmode',
    'INPUT::ismap',
    'INPUT::list',
    'INPUT::max',
    'INPUT::maxlength',
    'INPUT::min',
    'INPUT::multiple',
    'INPUT::name',
    'INPUT::placeholder',
    'INPUT::readonly',
    'INPUT::required',
    'INPUT::size',
    'INPUT::step',
    'INPUT::tabindex',
    'INPUT::type',
    'INPUT::usemap',
    'INPUT::value',
    'INS::datetime',
    'KEYGEN::disabled',
    'KEYGEN::keytype',
    'KEYGEN::name',
    'LABEL::accesskey',
    'LABEL::for',
    'LEGEND::accesskey',
    'LEGEND::align',
    'LI::type',
    'LI::value',
    'LINK::sizes',
    'MAP::name',
    'MENU::compact',
    'MENU::label',
    'MENU::type',
    'METER::high',
    'METER::low',
    'METER::max',
    'METER::min',
    'METER::value',
    'OBJECT::typemustmatch',
    'OL::compact',
    'OL::reversed',
    'OL::start',
    'OL::type',
    'OPTGROUP::disabled',
    'OPTGROUP::label',
    'OPTION::disabled',
    'OPTION::label',
    'OPTION::selected',
    'OPTION::value',
    'OUTPUT::for',
    'OUTPUT::name',
    'P::align',
    'PRE::width',
    'PROGRESS::max',
    'PROGRESS::min',
    'PROGRESS::value',
    'SELECT::autocomplete',
    'SELECT::disabled',
    'SELECT::multiple',
    'SELECT::name',
    'SELECT::required',
    'SELECT::size',
    'SELECT::tabindex',
    'SOURCE::type',
    'TABLE::align',
    'TABLE::bgcolor',
    'TABLE::border',
    'TABLE::cellpadding',
    'TABLE::cellspacing',
    'TABLE::frame',
    'TABLE::rules',
    'TABLE::summary',
    'TABLE::width',
    'TBODY::align',
    'TBODY::char',
    'TBODY::charoff',
    'TBODY::valign',
    'TD::abbr',
    'TD::align',
    'TD::axis',
    'TD::bgcolor',
    'TD::char',
    'TD::charoff',
    'TD::colspan',
    'TD::headers',
    'TD::height',
    'TD::nowrap',
    'TD::rowspan',
    'TD::scope',
    'TD::valign',
    'TD::width',
    'TEXTAREA::accesskey',
    'TEXTAREA::autocomplete',
    'TEXTAREA::cols',
    'TEXTAREA::disabled',
    'TEXTAREA::inputmode',
    'TEXTAREA::name',
    'TEXTAREA::placeholder',
    'TEXTAREA::readonly',
    'TEXTAREA::required',
    'TEXTAREA::rows',
    'TEXTAREA::tabindex',
    'TEXTAREA::wrap',
    'TFOOT::align',
    'TFOOT::char',
    'TFOOT::charoff',
    'TFOOT::valign',
    'TH::abbr',
    'TH::align',
    'TH::axis',
    'TH::bgcolor',
    'TH::char',
    'TH::charoff',
    'TH::colspan',
    'TH::headers',
    'TH::height',
    'TH::nowrap',
    'TH::rowspan',
    'TH::scope',
    'TH::valign',
    'TH::width',
    'THEAD::align',
    'THEAD::char',
    'THEAD::charoff',
    'THEAD::valign',
    'TR::align',
    'TR::bgcolor',
    'TR::char',
    'TR::charoff',
    'TR::valign',
    'TRACK::default',
    'TRACK::kind',
    'TRACK::label',
    'TRACK::srclang',
    'UL::compact',
    'UL::type',
    'VIDEO::controls',
    'VIDEO::height',
    'VIDEO::loop',
    'VIDEO::mediagroup',
    'VIDEO::muted',
    'VIDEO::preload',
    'VIDEO::width',
  ];

  static const _uriAttributes = const <String>[
    'A::href',
    'AREA::href',
    'BLOCKQUOTE::cite',
    'BODY::background',
    'COMMAND::icon',
    'DEL::cite',
    'FORM::action',
    'IMG::src',
    'INPUT::src',
    'INS::cite',
    'Q::cite',
    'VIDEO::poster',
  ];

  final UriPolicy uriPolicy;

  static final Map<String, Function> _attributeValidators = {};

  /**
   * All known URI attributes will be validated against the UriPolicy, if
   * [uriPolicy] is null then a default UriPolicy will be used.
   */
  _Html5NodeValidator({UriPolicy uriPolicy})
      :uriPolicy = uriPolicy != null ? uriPolicy : new UriPolicy() {

    if (_attributeValidators.isEmpty) {
      for (var attr in _standardAttributes) {
        _attributeValidators[attr] = _standardAttributeValidator;
      }

      for (var attr in _uriAttributes) {
        _attributeValidators[attr] = _uriAttributeValidator;
      }
    }
  }

  bool allowsElement(Element element) {
    return _allowedElements.contains(Element._safeTagName(element));
  }

  bool allowsAttribute(Element element, String attributeName, String value) {
    var tagName = Element._safeTagName(element);
    var validator = _attributeValidators['$tagName::$attributeName'];
    if (validator == null) {
      validator = _attributeValidators['*::$attributeName'];
    }
    if (validator == null) {
      return false;
    }
    return validator(element, attributeName, value, this);
  }

  static bool _standardAttributeValidator(Element element, String attributeName,
      String value, _Html5NodeValidator context) {
    return true;
  }

  static bool _uriAttributeValidator(Element element, String attributeName,
      String value, _Html5NodeValidator context) {
    return context.uriPolicy.allowsUri(value);
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


abstract class ImmutableListMixin<E> implements List<E> {
  // From Iterable<$E>:
  Iterator<E> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<E>(this);
  }

  // From Collection<E>:
  void add(E value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<E> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<E>:
  void sort([int compare(E a, E b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  void shuffle([Random random]) {
    throw new UnsupportedError("Cannot shuffle immutable List.");
  }

  void insert(int index, E element) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void insertAll(int index, Iterable<E> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void setAll(int index, Iterable<E> iterable) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }

  E removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  E removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  bool remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeWhere(bool test(E element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainWhere(bool test(E element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int end) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void replaceRange(int start, int end, Iterable<E> iterable) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }

  void fillRange(int start, int end, [E fillValue]) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * Defines the keycode values for keys that are returned by
 * KeyboardEvent.keyCode.
 *
 * Important note: There is substantial divergence in how different browsers
 * handle keycodes and their variants in different locales/keyboard layouts. We
 * provide these constants to help make code processing keys more readable.
 */
abstract class KeyCode {
  // These constant names were borrowed from Closure's Keycode enumeration
  // class.
  // http://closure-library.googlecode.com/svn/docs/closure_goog_events_keycodes.js.source.html
  static const int WIN_KEY_FF_LINUX = 0;
  static const int MAC_ENTER = 3;
  static const int BACKSPACE = 8;
  static const int TAB = 9;
  /** NUM_CENTER is also NUMLOCK for FF and Safari on Mac. */
  static const int NUM_CENTER = 12;
  static const int ENTER = 13;
  static const int SHIFT = 16;
  static const int CTRL = 17;
  static const int ALT = 18;
  static const int PAUSE = 19;
  static const int CAPS_LOCK = 20;
  static const int ESC = 27;
  static const int SPACE = 32;
  static const int PAGE_UP = 33;
  static const int PAGE_DOWN = 34;
  static const int END = 35;
  static const int HOME = 36;
  static const int LEFT = 37;
  static const int UP = 38;
  static const int RIGHT = 39;
  static const int DOWN = 40;
  static const int NUM_NORTH_EAST = 33;
  static const int NUM_SOUTH_EAST = 34;
  static const int NUM_SOUTH_WEST = 35;
  static const int NUM_NORTH_WEST = 36;
  static const int NUM_WEST = 37;
  static const int NUM_NORTH = 38;
  static const int NUM_EAST = 39;
  static const int NUM_SOUTH = 40;
  static const int PRINT_SCREEN = 44;
  static const int INSERT = 45;
  static const int NUM_INSERT = 45;
  static const int DELETE = 46;
  static const int NUM_DELETE = 46;
  static const int ZERO = 48;
  static const int ONE = 49;
  static const int TWO = 50;
  static const int THREE = 51;
  static const int FOUR = 52;
  static const int FIVE = 53;
  static const int SIX = 54;
  static const int SEVEN = 55;
  static const int EIGHT = 56;
  static const int NINE = 57;
  static const int FF_SEMICOLON = 59;
  static const int FF_EQUALS = 61;
  /**
   * CAUTION: The question mark is for US-keyboard layouts. It varies
   * for other locales and keyboard layouts.
   */
  static const int QUESTION_MARK = 63;
  static const int A = 65;
  static const int B = 66;
  static const int C = 67;
  static const int D = 68;
  static const int E = 69;
  static const int F = 70;
  static const int G = 71;
  static const int H = 72;
  static const int I = 73;
  static const int J = 74;
  static const int K = 75;
  static const int L = 76;
  static const int M = 77;
  static const int N = 78;
  static const int O = 79;
  static const int P = 80;
  static const int Q = 81;
  static const int R = 82;
  static const int S = 83;
  static const int T = 84;
  static const int U = 85;
  static const int V = 86;
  static const int W = 87;
  static const int X = 88;
  static const int Y = 89;
  static const int Z = 90;
  static const int META = 91;
  static const int WIN_KEY_LEFT = 91;
  static const int WIN_KEY_RIGHT = 92;
  static const int CONTEXT_MENU = 93;
  static const int NUM_ZERO = 96;
  static const int NUM_ONE = 97;
  static const int NUM_TWO = 98;
  static const int NUM_THREE = 99;
  static const int NUM_FOUR = 100;
  static const int NUM_FIVE = 101;
  static const int NUM_SIX = 102;
  static const int NUM_SEVEN = 103;
  static const int NUM_EIGHT = 104;
  static const int NUM_NINE = 105;
  static const int NUM_MULTIPLY = 106;
  static const int NUM_PLUS = 107;
  static const int NUM_MINUS = 109;
  static const int NUM_PERIOD = 110;
  static const int NUM_DIVISION = 111;
  static const int F1 = 112;
  static const int F2 = 113;
  static const int F3 = 114;
  static const int F4 = 115;
  static const int F5 = 116;
  static const int F6 = 117;
  static const int F7 = 118;
  static const int F8 = 119;
  static const int F9 = 120;
  static const int F10 = 121;
  static const int F11 = 122;
  static const int F12 = 123;
  static const int NUMLOCK = 144;
  static const int SCROLL_LOCK = 145;

  // OS-specific media keys like volume controls and browser controls.
  static const int FIRST_MEDIA_KEY = 166;
  static const int LAST_MEDIA_KEY = 183;

  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int SEMICOLON = 186;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int DASH = 189;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int EQUALS = 187;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int COMMA = 188;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int PERIOD = 190;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int SLASH = 191;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int APOSTROPHE = 192;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int TILDE = 192;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int SINGLE_QUOTE = 222;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int OPEN_SQUARE_BRACKET = 219;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int BACKSLASH = 220;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int CLOSE_SQUARE_BRACKET = 221;
  static const int WIN_KEY = 224;
  static const int MAC_FF_META = 224;
  static const int WIN_IME = 229;

  /** A sentinel value if the keycode could not be determined. */
  static const int UNKNOWN = -1;

  /**
   * Returns true if the keyCode produces a (US keyboard) character.
   * Note: This does not (yet) cover characters on non-US keyboards (Russian,
   * Hebrew, etc.).
   */
  static bool isCharacterKey(int keyCode) {
    if ((keyCode >= ZERO && keyCode <= NINE) ||
        (keyCode >= NUM_ZERO && keyCode <= NUM_MULTIPLY) ||
        (keyCode >= A && keyCode <= Z)) {
      return true;
    }

    // Safari sends zero key code for non-latin characters.
    if (Device.isWebKit && keyCode == 0) {
      return true;
    }

    return (keyCode == SPACE || keyCode == QUESTION_MARK || keyCode == NUM_PLUS
        || keyCode == NUM_MINUS || keyCode == NUM_PERIOD ||
        keyCode == NUM_DIVISION || keyCode == SEMICOLON ||
        keyCode == FF_SEMICOLON || keyCode == DASH || keyCode == EQUALS ||
        keyCode == FF_EQUALS || keyCode == COMMA || keyCode == PERIOD ||
        keyCode == SLASH || keyCode == APOSTROPHE || keyCode == SINGLE_QUOTE ||
        keyCode == OPEN_SQUARE_BRACKET || keyCode == BACKSLASH ||
        keyCode == CLOSE_SQUARE_BRACKET);
  }

  /**
   * Experimental helper function for converting keyCodes to keyNames for the
   * keyIdentifier attribute still used in browsers not updated with current
   * spec. This is an imperfect conversion! It will need to be refined, but
   * hopefully it can just completely go away once all the browsers update to
   * follow the DOM3 spec.
   */
  static String _convertKeyCodeToKeyName(int keyCode) {
    switch(keyCode) {
      case KeyCode.ALT: return _KeyName.ALT;
      case KeyCode.BACKSPACE: return _KeyName.BACKSPACE;
      case KeyCode.CAPS_LOCK: return _KeyName.CAPS_LOCK;
      case KeyCode.CTRL: return _KeyName.CONTROL;
      case KeyCode.DELETE: return _KeyName.DEL;
      case KeyCode.DOWN: return _KeyName.DOWN;
      case KeyCode.END: return _KeyName.END;
      case KeyCode.ENTER: return _KeyName.ENTER;
      case KeyCode.ESC: return _KeyName.ESC;
      case KeyCode.F1: return _KeyName.F1;
      case KeyCode.F2: return _KeyName.F2;
      case KeyCode.F3: return _KeyName.F3;
      case KeyCode.F4: return _KeyName.F4;
      case KeyCode.F5: return _KeyName.F5;
      case KeyCode.F6: return _KeyName.F6;
      case KeyCode.F7: return _KeyName.F7;
      case KeyCode.F8: return _KeyName.F8;
      case KeyCode.F9: return _KeyName.F9;
      case KeyCode.F10: return _KeyName.F10;
      case KeyCode.F11: return _KeyName.F11;
      case KeyCode.F12: return _KeyName.F12;
      case KeyCode.HOME: return _KeyName.HOME;
      case KeyCode.INSERT: return _KeyName.INSERT;
      case KeyCode.LEFT: return _KeyName.LEFT;
      case KeyCode.META: return _KeyName.META;
      case KeyCode.NUMLOCK: return _KeyName.NUM_LOCK;
      case KeyCode.PAGE_DOWN: return _KeyName.PAGE_DOWN;
      case KeyCode.PAGE_UP: return _KeyName.PAGE_UP;
      case KeyCode.PAUSE: return _KeyName.PAUSE;
      case KeyCode.PRINT_SCREEN: return _KeyName.PRINT_SCREEN;
      case KeyCode.RIGHT: return _KeyName.RIGHT;
      case KeyCode.SCROLL_LOCK: return _KeyName.SCROLL;
      case KeyCode.SHIFT: return _KeyName.SHIFT;
      case KeyCode.SPACE: return _KeyName.SPACEBAR;
      case KeyCode.TAB: return _KeyName.TAB;
      case KeyCode.UP: return _KeyName.UP;
      case KeyCode.WIN_IME:
      case KeyCode.WIN_KEY:
      case KeyCode.WIN_KEY_LEFT:
      case KeyCode.WIN_KEY_RIGHT:
        return _KeyName.WIN;
      default: return _KeyName.UNIDENTIFIED;
    }
    return _KeyName.UNIDENTIFIED;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * Defines the standard key locations returned by
 * KeyboardEvent.getKeyLocation.
 */
abstract class KeyLocation {

  /**
   * The event key is not distinguished as the left or right version
   * of the key, and did not originate from the numeric keypad (or did not
   * originate with a virtual key corresponding to the numeric keypad).
   */
  static const int STANDARD = 0;

  /**
   * The event key is in the left key location.
   */
  static const int LEFT = 1;

  /**
   * The event key is in the right key location.
   */
  static const int RIGHT = 2;

  /**
   * The event key originated on the numeric keypad or with a virtual key
   * corresponding to the numeric keypad.
   */
  static const int NUMPAD = 3;

  /**
   * The event key originated on a mobile device, either on a physical
   * keypad or a virtual keyboard.
   */
  static const int MOBILE = 4;

  /**
   * The event key originated on a game controller or a joystick on a mobile
   * device.
   */
  static const int JOYSTICK = 5;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * Defines the standard keyboard identifier names for keys that are returned
 * by KeyboardEvent.getKeyboardIdentifier when the key does not have a direct
 * unicode mapping.
 */
abstract class _KeyName {

  /** The Accept (Commit, OK) key */
  static const String ACCEPT = "Accept";

  /** The Add key */
  static const String ADD = "Add";

  /** The Again key */
  static const String AGAIN = "Again";

  /** The All Candidates key */
  static const String ALL_CANDIDATES = "AllCandidates";

  /** The Alphanumeric key */
  static const String ALPHANUMERIC = "Alphanumeric";

  /** The Alt (Menu) key */
  static const String ALT = "Alt";

  /** The Alt-Graph key */
  static const String ALT_GRAPH = "AltGraph";

  /** The Application key */
  static const String APPS = "Apps";

  /** The ATTN key */
  static const String ATTN = "Attn";

  /** The Browser Back key */
  static const String BROWSER_BACK = "BrowserBack";

  /** The Browser Favorites key */
  static const String BROWSER_FAVORTIES = "BrowserFavorites";

  /** The Browser Forward key */
  static const String BROWSER_FORWARD = "BrowserForward";

  /** The Browser Home key */
  static const String BROWSER_NAME = "BrowserHome";

  /** The Browser Refresh key */
  static const String BROWSER_REFRESH = "BrowserRefresh";

  /** The Browser Search key */
  static const String BROWSER_SEARCH = "BrowserSearch";

  /** The Browser Stop key */
  static const String BROWSER_STOP = "BrowserStop";

  /** The Camera key */
  static const String CAMERA = "Camera";

  /** The Caps Lock (Capital) key */
  static const String CAPS_LOCK = "CapsLock";

  /** The Clear key */
  static const String CLEAR = "Clear";

  /** The Code Input key */
  static const String CODE_INPUT = "CodeInput";

  /** The Compose key */
  static const String COMPOSE = "Compose";

  /** The Control (Ctrl) key */
  static const String CONTROL = "Control";

  /** The Crsel key */
  static const String CRSEL = "Crsel";

  /** The Convert key */
  static const String CONVERT = "Convert";

  /** The Copy key */
  static const String COPY = "Copy";

  /** The Cut key */
  static const String CUT = "Cut";

  /** The Decimal key */
  static const String DECIMAL = "Decimal";

  /** The Divide key */
  static const String DIVIDE = "Divide";

  /** The Down Arrow key */
  static const String DOWN = "Down";

  /** The diagonal Down-Left Arrow key */
  static const String DOWN_LEFT = "DownLeft";

  /** The diagonal Down-Right Arrow key */
  static const String DOWN_RIGHT = "DownRight";

  /** The Eject key */
  static const String EJECT = "Eject";

  /** The End key */
  static const String END = "End";

  /**
   * The Enter key. Note: This key value must also be used for the Return
   *  (Macintosh numpad) key
   */
  static const String ENTER = "Enter";

  /** The Erase EOF key */
  static const String ERASE_EOF= "EraseEof";

  /** The Execute key */
  static const String EXECUTE = "Execute";

  /** The Exsel key */
  static const String EXSEL = "Exsel";

  /** The Function switch key */
  static const String FN = "Fn";

  /** The F1 key */
  static const String F1 = "F1";

  /** The F2 key */
  static const String F2 = "F2";

  /** The F3 key */
  static const String F3 = "F3";

  /** The F4 key */
  static const String F4 = "F4";

  /** The F5 key */
  static const String F5 = "F5";

  /** The F6 key */
  static const String F6 = "F6";

  /** The F7 key */
  static const String F7 = "F7";

  /** The F8 key */
  static const String F8 = "F8";

  /** The F9 key */
  static const String F9 = "F9";

  /** The F10 key */
  static const String F10 = "F10";

  /** The F11 key */
  static const String F11 = "F11";

  /** The F12 key */
  static const String F12 = "F12";

  /** The F13 key */
  static const String F13 = "F13";

  /** The F14 key */
  static const String F14 = "F14";

  /** The F15 key */
  static const String F15 = "F15";

  /** The F16 key */
  static const String F16 = "F16";

  /** The F17 key */
  static const String F17 = "F17";

  /** The F18 key */
  static const String F18 = "F18";

  /** The F19 key */
  static const String F19 = "F19";

  /** The F20 key */
  static const String F20 = "F20";

  /** The F21 key */
  static const String F21 = "F21";

  /** The F22 key */
  static const String F22 = "F22";

  /** The F23 key */
  static const String F23 = "F23";

  /** The F24 key */
  static const String F24 = "F24";

  /** The Final Mode (Final) key used on some asian keyboards */
  static const String FINAL_MODE = "FinalMode";

  /** The Find key */
  static const String FIND = "Find";

  /** The Full-Width Characters key */
  static const String FULL_WIDTH = "FullWidth";

  /** The Half-Width Characters key */
  static const String HALF_WIDTH = "HalfWidth";

  /** The Hangul (Korean characters) Mode key */
  static const String HANGUL_MODE = "HangulMode";

  /** The Hanja (Korean characters) Mode key */
  static const String HANJA_MODE = "HanjaMode";

  /** The Help key */
  static const String HELP = "Help";

  /** The Hiragana (Japanese Kana characters) key */
  static const String HIRAGANA = "Hiragana";

  /** The Home key */
  static const String HOME = "Home";

  /** The Insert (Ins) key */
  static const String INSERT = "Insert";

  /** The Japanese-Hiragana key */
  static const String JAPANESE_HIRAGANA = "JapaneseHiragana";

  /** The Japanese-Katakana key */
  static const String JAPANESE_KATAKANA = "JapaneseKatakana";

  /** The Japanese-Romaji key */
  static const String JAPANESE_ROMAJI = "JapaneseRomaji";

  /** The Junja Mode key */
  static const String JUNJA_MODE = "JunjaMode";

  /** The Kana Mode (Kana Lock) key */
  static const String KANA_MODE = "KanaMode";

  /**
   * The Kanji (Japanese name for ideographic characters of Chinese origin)
   * Mode key
   */
  static const String KANJI_MODE = "KanjiMode";

  /** The Katakana (Japanese Kana characters) key */
  static const String KATAKANA = "Katakana";

  /** The Start Application One key */
  static const String LAUNCH_APPLICATION_1 = "LaunchApplication1";

  /** The Start Application Two key */
  static const String LAUNCH_APPLICATION_2 = "LaunchApplication2";

  /** The Start Mail key */
  static const String LAUNCH_MAIL = "LaunchMail";

  /** The Left Arrow key */
  static const String LEFT = "Left";

  /** The Menu key */
  static const String MENU = "Menu";

  /**
   * The Meta key. Note: This key value shall be also used for the Apple
   * Command key
   */
  static const String META = "Meta";

  /** The Media Next Track key */
  static const String MEDIA_NEXT_TRACK = "MediaNextTrack";

  /** The Media Play Pause key */
  static const String MEDIA_PAUSE_PLAY = "MediaPlayPause";

  /** The Media Previous Track key */
  static const String MEDIA_PREVIOUS_TRACK = "MediaPreviousTrack";

  /** The Media Stop key */
  static const String MEDIA_STOP = "MediaStop";

  /** The Mode Change key */
  static const String MODE_CHANGE = "ModeChange";

  /** The Next Candidate function key */
  static const String NEXT_CANDIDATE = "NextCandidate";

  /** The Nonconvert (Don't Convert) key */
  static const String NON_CONVERT = "Nonconvert";

  /** The Number Lock key */
  static const String NUM_LOCK = "NumLock";

  /** The Page Down (Next) key */
  static const String PAGE_DOWN = "PageDown";

  /** The Page Up key */
  static const String PAGE_UP = "PageUp";

  /** The Paste key */
  static const String PASTE = "Paste";

  /** The Pause key */
  static const String PAUSE = "Pause";

  /** The Play key */
  static const String PLAY = "Play";

  /**
   * The Power key. Note: Some devices may not expose this key to the
   * operating environment
   */
  static const String POWER = "Power";

  /** The Previous Candidate function key */
  static const String PREVIOUS_CANDIDATE = "PreviousCandidate";

  /** The Print Screen (PrintScrn, SnapShot) key */
  static const String PRINT_SCREEN = "PrintScreen";

  /** The Process key */
  static const String PROCESS = "Process";

  /** The Props key */
  static const String PROPS = "Props";

  /** The Right Arrow key */
  static const String RIGHT = "Right";

  /** The Roman Characters function key */
  static const String ROMAN_CHARACTERS = "RomanCharacters";

  /** The Scroll Lock key */
  static const String SCROLL = "Scroll";

  /** The Select key */
  static const String SELECT = "Select";

  /** The Select Media key */
  static const String SELECT_MEDIA = "SelectMedia";

  /** The Separator key */
  static const String SEPARATOR = "Separator";

  /** The Shift key */
  static const String SHIFT = "Shift";

  /** The Soft1 key */
  static const String SOFT_1 = "Soft1";

  /** The Soft2 key */
  static const String SOFT_2 = "Soft2";

  /** The Soft3 key */
  static const String SOFT_3 = "Soft3";

  /** The Soft4 key */
  static const String SOFT_4 = "Soft4";

  /** The Stop key */
  static const String STOP = "Stop";

  /** The Subtract key */
  static const String SUBTRACT = "Subtract";

  /** The Symbol Lock key */
  static const String SYMBOL_LOCK = "SymbolLock";

  /** The Up Arrow key */
  static const String UP = "Up";

  /** The diagonal Up-Left Arrow key */
  static const String UP_LEFT = "UpLeft";

  /** The diagonal Up-Right Arrow key */
  static const String UP_RIGHT = "UpRight";

  /** The Undo key */
  static const String UNDO = "Undo";

  /** The Volume Down key */
  static const String VOLUME_DOWN = "VolumeDown";

  /** The Volume Mute key */
  static const String VOLUMN_MUTE = "VolumeMute";

  /** The Volume Up key */
  static const String VOLUMN_UP = "VolumeUp";

  /** The Windows Logo key */
  static const String WIN = "Win";

  /** The Zoom key */
  static const String ZOOM = "Zoom";

  /**
   * The Backspace (Back) key. Note: This key value shall be also used for the
   * key labeled 'delete' MacOS keyboards when not modified by the 'Fn' key
   */
  static const String BACKSPACE = "Backspace";

  /** The Horizontal Tabulation (Tab) key */
  static const String TAB = "Tab";

  /** The Cancel key */
  static const String CANCEL = "Cancel";

  /** The Escape (Esc) key */
  static const String ESC = "Esc";

  /** The Space (Spacebar) key:   */
  static const String SPACEBAR = "Spacebar";

  /**
   * The Delete (Del) Key. Note: This key value shall be also used for the key
   * labeled 'delete' MacOS keyboards when modified by the 'Fn' key
   */
  static const String DEL = "Del";

  /** The Combining Grave Accent (Greek Varia, Dead Grave) key */
  static const String DEAD_GRAVE = "DeadGrave";

  /**
   * The Combining Acute Accent (Stress Mark, Greek Oxia, Tonos, Dead Eacute)
   * key
   */
  static const String DEAD_EACUTE = "DeadEacute";

  /** The Combining Circumflex Accent (Hat, Dead Circumflex) key */
  static const String DEAD_CIRCUMFLEX = "DeadCircumflex";

  /** The Combining Tilde (Dead Tilde) key */
  static const String DEAD_TILDE = "DeadTilde";

  /** The Combining Macron (Long, Dead Macron) key */
  static const String DEAD_MACRON = "DeadMacron";

  /** The Combining Breve (Short, Dead Breve) key */
  static const String DEAD_BREVE = "DeadBreve";

  /** The Combining Dot Above (Derivative, Dead Above Dot) key */
  static const String DEAD_ABOVE_DOT = "DeadAboveDot";

  /**
   * The Combining Diaeresis (Double Dot Abode, Umlaut, Greek Dialytika,
   * Double Derivative, Dead Diaeresis) key
   */
  static const String DEAD_UMLAUT = "DeadUmlaut";

  /** The Combining Ring Above (Dead Above Ring) key */
  static const String DEAD_ABOVE_RING = "DeadAboveRing";

  /** The Combining Double Acute Accent (Dead Doubleacute) key */
  static const String DEAD_DOUBLEACUTE = "DeadDoubleacute";

  /** The Combining Caron (Hacek, V Above, Dead Caron) key */
  static const String DEAD_CARON = "DeadCaron";

  /** The Combining Cedilla (Dead Cedilla) key */
  static const String DEAD_CEDILLA = "DeadCedilla";

  /** The Combining Ogonek (Nasal Hook, Dead Ogonek) key */
  static const String DEAD_OGONEK = "DeadOgonek";

  /**
   * The Combining Greek Ypogegrammeni (Greek Non-Spacing Iota Below, Iota
   * Subscript, Dead Iota) key
   */
  static const String DEAD_IOTA = "DeadIota";

  /**
   * The Combining Katakana-Hiragana Voiced Sound Mark (Dead Voiced Sound) key
   */
  static const String DEAD_VOICED_SOUND = "DeadVoicedSound";

  /**
   * The Combining Katakana-Hiragana Semi-Voiced Sound Mark (Dead Semivoiced
   * Sound) key
   */
  static const String DEC_SEMIVOICED_SOUND= "DeadSemivoicedSound";

  /**
   * Key value used when an implementation is unable to identify another key
   * value, due to either hardware, platform, or software constraints
   */
  static const String UNIDENTIFIED = "Unidentified";
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * Internal class that does the actual calculations to determine keyCode and
 * charCode for keydown, keypress, and keyup events for all browsers.
 */
class _KeyboardEventHandler extends EventStreamProvider<KeyEvent> {
  // This code inspired by Closure's KeyHandling library.
  // http://closure-library.googlecode.com/svn/docs/closure_goog_events_keyhandler.js.source.html

  /**
   * The set of keys that have been pressed down without seeing their
   * corresponding keyup event.
   */
  final List<KeyEvent> _keyDownList = <KeyEvent>[];

  /** The type of KeyEvent we are tracking (keyup, keydown, keypress). */
  final String _type;

  /** The element we are watching for events to happen on. */
  final EventTarget _target;

  // The distance to shift from upper case alphabet Roman letters to lower case.
  static final int _ROMAN_ALPHABET_OFFSET = "a".codeUnits[0] - "A".codeUnits[0];

  /** Custom Stream (Controller) to produce KeyEvents for the stream. */
  _CustomKeyEventStreamImpl _stream;

  static const _EVENT_TYPE = 'KeyEvent';

  /**
   * An enumeration of key identifiers currently part of the W3C draft for DOM3
   * and their mappings to keyCodes.
   * http://www.w3.org/TR/DOM-Level-3-Events/keyset.html#KeySet-Set
   */
  static const Map<String, int> _keyIdentifier = const {
    'Up': KeyCode.UP,
    'Down': KeyCode.DOWN,
    'Left': KeyCode.LEFT,
    'Right': KeyCode.RIGHT,
    'Enter': KeyCode.ENTER,
    'F1': KeyCode.F1,
    'F2': KeyCode.F2,
    'F3': KeyCode.F3,
    'F4': KeyCode.F4,
    'F5': KeyCode.F5,
    'F6': KeyCode.F6,
    'F7': KeyCode.F7,
    'F8': KeyCode.F8,
    'F9': KeyCode.F9,
    'F10': KeyCode.F10,
    'F11': KeyCode.F11,
    'F12': KeyCode.F12,
    'U+007F': KeyCode.DELETE,
    'Home': KeyCode.HOME,
    'End': KeyCode.END,
    'PageUp': KeyCode.PAGE_UP,
    'PageDown': KeyCode.PAGE_DOWN,
    'Insert': KeyCode.INSERT
  };

  /** Return a stream for KeyEvents for the specified target. */
  // Note: this actually functions like a factory constructor.
  CustomStream<KeyEvent> forTarget(EventTarget e, {bool useCapture: false}) {
    var handler = new _KeyboardEventHandler.initializeAllEventListeners(
        _type, e);
    return handler._stream;
  }

  /**
   * General constructor, performs basic initialization for our improved
   * KeyboardEvent controller.
   */
  _KeyboardEventHandler(this._type):
    _stream = new _CustomKeyEventStreamImpl('event'), _target = null,
    super(_EVENT_TYPE);

  /**
   * Hook up all event listeners under the covers so we can estimate keycodes
   * and charcodes when they are not provided.
   */
  _KeyboardEventHandler.initializeAllEventListeners(this._type, this._target) :
      super(_EVENT_TYPE) {
    throw 'Key event handling not supported in DDC';
    /*
    Element.keyDownEvent.forTarget(_target, useCapture: true).listen(
        processKeyDown);
    Element.keyPressEvent.forTarget(_target, useCapture: true).listen(
        processKeyPress);
    Element.keyUpEvent.forTarget(_target, useCapture: true).listen(
        processKeyUp);
    _stream = new _CustomKeyEventStreamImpl(_type);
    */
  }

  /** Determine if caps lock is one of the currently depressed keys. */
  bool get _capsLockOn =>
      _keyDownList.any((var element) => element.keyCode == KeyCode.CAPS_LOCK);

  /**
   * Given the previously recorded keydown key codes, see if we can determine
   * the keycode of this keypress [event]. (Generally browsers only provide
   * charCode information for keypress events, but with a little
   * reverse-engineering, we can also determine the keyCode.) Returns
   * KeyCode.UNKNOWN if the keycode could not be determined.
   */
  int _determineKeyCodeForKeypress(KeyboardEvent event) {
    // Note: This function is a work in progress. We'll expand this function
    // once we get more information about other keyboards.
    for (var prevEvent in _keyDownList) {
      if (prevEvent._shadowCharCode == event.charCode) {
        return prevEvent.keyCode;
      }
      if ((event.shiftKey || _capsLockOn) && event.charCode >= "A".codeUnits[0]
          && event.charCode <= "Z".codeUnits[0] && event.charCode +
          _ROMAN_ALPHABET_OFFSET == prevEvent._shadowCharCode) {
        return prevEvent.keyCode;
      }
    }
    return KeyCode.UNKNOWN;
  }

  /**
   * Given the charater code returned from a keyDown [event], try to ascertain
   * and return the corresponding charCode for the character that was pressed.
   * This information is not shown to the user, but used to help polyfill
   * keypress events.
   */
  int _findCharCodeKeyDown(KeyboardEvent event) {
    if (event.keyLocation == 3) { // Numpad keys.
      switch (event.keyCode) {
        case KeyCode.NUM_ZERO:
          // Even though this function returns _charCodes_, for some cases the
          // KeyCode == the charCode we want, in which case we use the keycode
          // constant for readability.
          return KeyCode.ZERO;
        case KeyCode.NUM_ONE:
          return KeyCode.ONE;
        case KeyCode.NUM_TWO:
          return KeyCode.TWO;
        case KeyCode.NUM_THREE:
          return KeyCode.THREE;
        case KeyCode.NUM_FOUR:
          return KeyCode.FOUR;
        case KeyCode.NUM_FIVE:
          return KeyCode.FIVE;
        case KeyCode.NUM_SIX:
          return KeyCode.SIX;
        case KeyCode.NUM_SEVEN:
          return KeyCode.SEVEN;
        case KeyCode.NUM_EIGHT:
          return KeyCode.EIGHT;
        case KeyCode.NUM_NINE:
          return KeyCode.NINE;
        case KeyCode.NUM_MULTIPLY:
          return 42; // Char code for *
        case KeyCode.NUM_PLUS:
          return 43; // +
        case KeyCode.NUM_MINUS:
          return 45; // -
        case KeyCode.NUM_PERIOD:
          return 46; // .
        case KeyCode.NUM_DIVISION:
          return 47; // /
      }
    } else if (event.keyCode >= 65 && event.keyCode <= 90) {
      // Set the "char code" for key down as the lower case letter. Again, this
      // will not show up for the user, but will be helpful in estimating
      // keyCode locations and other information during the keyPress event.
      return event.keyCode + _ROMAN_ALPHABET_OFFSET;
    }
    switch(event.keyCode) {
      case KeyCode.SEMICOLON:
        return KeyCode.FF_SEMICOLON;
      case KeyCode.EQUALS:
        return KeyCode.FF_EQUALS;
      case KeyCode.COMMA:
        return 44; // Ascii value for ,
      case KeyCode.DASH:
        return 45; // -
      case KeyCode.PERIOD:
        return 46; // .
      case KeyCode.SLASH:
        return 47; // /
      case KeyCode.APOSTROPHE:
        return 96; // `
      case KeyCode.OPEN_SQUARE_BRACKET:
        return 91; // [
      case KeyCode.BACKSLASH:
        return 92; // \
      case KeyCode.CLOSE_SQUARE_BRACKET:
        return 93; // ]
      case KeyCode.SINGLE_QUOTE:
        return 39; // '
    }
    return event.keyCode;
  }

  /**
   * Returns true if the key fires a keypress event in the current browser.
   */
  bool _firesKeyPressEvent(KeyEvent event) {
    if (!Device.isIE && !Device.isWebKit) {
      return true;
    }

    if (Device.userAgent.contains('Mac') && event.altKey) {
      return KeyCode.isCharacterKey(event.keyCode);
    }

    // Alt but not AltGr which is represented as Alt+Ctrl.
    if (event.altKey && !event.ctrlKey) {
      return false;
    }

    // Saves Ctrl or Alt + key for IE and WebKit, which won't fire keypress.
    if (!event.shiftKey &&
        (_keyDownList.last.keyCode == KeyCode.CTRL ||
         _keyDownList.last.keyCode == KeyCode.ALT ||
         Device.userAgent.contains('Mac') &&
         _keyDownList.last.keyCode == KeyCode.META)) {
      return false;
    }

    // Some keys with Ctrl/Shift do not issue keypress in WebKit.
    if (Device.isWebKit && event.ctrlKey && event.shiftKey && (
        event.keyCode == KeyCode.BACKSLASH ||
        event.keyCode == KeyCode.OPEN_SQUARE_BRACKET ||
        event.keyCode == KeyCode.CLOSE_SQUARE_BRACKET ||
        event.keyCode == KeyCode.TILDE ||
        event.keyCode == KeyCode.SEMICOLON || event.keyCode == KeyCode.DASH ||
        event.keyCode == KeyCode.EQUALS || event.keyCode == KeyCode.COMMA ||
        event.keyCode == KeyCode.PERIOD || event.keyCode == KeyCode.SLASH ||
        event.keyCode == KeyCode.APOSTROPHE ||
        event.keyCode == KeyCode.SINGLE_QUOTE)) {
      return false;
    }

    switch (event.keyCode) {
      case KeyCode.ENTER:
        // IE9 does not fire keypress on ENTER.
        return !Device.isIE;
      case KeyCode.ESC:
        return !Device.isWebKit;
    }

    return KeyCode.isCharacterKey(event.keyCode);
  }

  /**
   * Normalize the keycodes to the IE KeyCodes (this is what Chrome, IE, and
   * Opera all use).
   */
  int _normalizeKeyCodes(KeyboardEvent event) {
    // Note: This may change once we get input about non-US keyboards.
    if (Device.isFirefox) {
      switch(event.keyCode) {
        case KeyCode.FF_EQUALS:
          return KeyCode.EQUALS;
        case KeyCode.FF_SEMICOLON:
          return KeyCode.SEMICOLON;
        case KeyCode.MAC_FF_META:
          return KeyCode.META;
        case KeyCode.WIN_KEY_FF_LINUX:
          return KeyCode.WIN_KEY;
      }
    }
    return event.keyCode;
  }

  /** Handle keydown events. */
  void processKeyDown(KeyboardEvent e) {
    // Ctrl-Tab and Alt-Tab can cause the focus to be moved to another window
    // before we've caught a key-up event.  If the last-key was one of these
    // we reset the state.
    if (_keyDownList.length > 0 &&
        (_keyDownList.last.keyCode == KeyCode.CTRL && !e.ctrlKey ||
         _keyDownList.last.keyCode == KeyCode.ALT && !e.altKey ||
         Device.userAgent.contains('Mac') &&
         _keyDownList.last.keyCode == KeyCode.META && !e.metaKey)) {
      _keyDownList.clear();
    }

    var event = new KeyEvent.wrap(e);
    event._shadowKeyCode = _normalizeKeyCodes(event);
    // Technically a "keydown" event doesn't have a charCode. This is
    // calculated nonetheless to provide us with more information in giving
    // as much information as possible on keypress about keycode and also
    // charCode.
    event._shadowCharCode = _findCharCodeKeyDown(event);
    if (_keyDownList.length > 0 && event.keyCode != _keyDownList.last.keyCode &&
        !_firesKeyPressEvent(event)) {
      // Some browsers have quirks not firing keypress events where all other
      // browsers do. This makes them more consistent.
      processKeyPress(e);
    }
    _keyDownList.add(event);
    _stream.add(event);
  }

  /** Handle keypress events. */
  void processKeyPress(KeyboardEvent event) {
    var e = new KeyEvent.wrap(event);
    // IE reports the character code in the keyCode field for keypress events.
    // There are two exceptions however, Enter and Escape.
    if (Device.isIE) {
      if (e.keyCode == KeyCode.ENTER || e.keyCode == KeyCode.ESC) {
        e._shadowCharCode = 0;
      } else {
        e._shadowCharCode = e.keyCode;
      }
    } else if (Device.isOpera) {
      // Opera reports the character code in the keyCode field.
      e._shadowCharCode = KeyCode.isCharacterKey(e.keyCode) ? e.keyCode : 0;
    }
    // Now we guestimate about what the keycode is that was actually
    // pressed, given previous keydown information.
    e._shadowKeyCode = _determineKeyCodeForKeypress(e);

    // Correct the key value for certain browser-specific quirks.
    if (e._shadowKeyIdentifier != null &&
        _keyIdentifier.containsKey(e._shadowKeyIdentifier)) {
      // This is needed for Safari Windows because it currently doesn't give a
      // keyCode/which for non printable keys.
      e._shadowKeyCode = _keyIdentifier[e._shadowKeyIdentifier];
    }
    e._shadowAltKey = _keyDownList.any((var element) => element.altKey);
    _stream.add(e);
  }

  /** Handle keyup events. */
  void processKeyUp(KeyboardEvent event) {
    var e = new KeyEvent.wrap(event);
    KeyboardEvent toRemove = null;
    for (var key in _keyDownList) {
      if (key.keyCode == e.keyCode) {
        toRemove = key;
      }
    }
    if (toRemove != null) {
      _keyDownList.removeWhere((element) => element == toRemove);
    } else if (_keyDownList.length > 0) {
      // This happens when we've reached some international keyboard case we
      // haven't accounted for or we haven't correctly eliminated all browser
      // inconsistencies. Filing bugs on when this is reached is welcome!
      _keyDownList.removeLast();
    }
    _stream.add(e);
  }
}


/**
 * Records KeyboardEvents that occur on a particular element, and provides a
 * stream of outgoing KeyEvents with cross-browser consistent keyCode and
 * charCode values despite the fact that a multitude of browsers that have
 * varying keyboard default behavior.
 *
 * Example usage:
 *
 *     KeyboardEventStream.onKeyDown(document.body).listen(
 *         keydownHandlerTest);
 *
 * This class is very much a work in progress, and we'd love to get information
 * on how we can make this class work with as many international keyboards as
 * possible. Bugs welcome!
 */
class KeyboardEventStream {

  /** Named constructor to produce a stream for onKeyPress events. */
  static CustomStream<KeyEvent> onKeyPress(EventTarget target) =>
      new _KeyboardEventHandler('keypress').forTarget(target);

  /** Named constructor to produce a stream for onKeyUp events. */
  static CustomStream<KeyEvent> onKeyUp(EventTarget target) =>
      new _KeyboardEventHandler('keyup').forTarget(target);

  /** Named constructor to produce a stream for onKeyDown events. */
  static CustomStream<KeyEvent> onKeyDown(EventTarget target) =>
      new _KeyboardEventHandler('keydown').forTarget(target);
}
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



/**
 * Class which helps construct standard node validation policies.
 *
 * By default this will not accept anything, but the 'allow*' functions can be
 * used to expand what types of elements or attributes are allowed.
 *
 * All allow functions are additive- elements will be accepted if they are
 * accepted by any specific rule.
 *
 * It is important to remember that sanitization is not just intended to prevent
 * cross-site scripting attacks, but also to prevent information from being
 * displayed in unexpected ways. For example something displaying basic
 * formatted text may not expect `<video>` tags to appear. In this case an
 * empty NodeValidatorBuilder with just [allowTextElements] might be
 * appropriate.
 */
class NodeValidatorBuilder implements NodeValidator {

  final List<NodeValidator> _validators = <NodeValidator>[];

  NodeValidatorBuilder() {
  }

  /**
   * Creates a new NodeValidatorBuilder which accepts common constructs.
   *
   * By default this will accept HTML5 elements and attributes with the default
   * [UriPolicy] and templating elements.
   *
   * Notable syntax which is filtered:
   *
   * * Only known-good HTML5 elements and attributes are allowed.
   * * All URLs must be same-origin, use [allowNavigation] and [allowImages] to
   * specify additional URI policies.
   * * Inline-styles are not allowed.
   * * Custom element tags are disallowed, use [allowCustomElement].
   * * Custom tags extensions are disallowed, use [allowTagExtension].
   * * SVG Elements are not allowed, use [allowSvg].
   *
   * For scenarios where the HTML should only contain formatted text
   * [allowTextElements] is more appropriate.
   *
   * Use [allowSvg] to allow SVG elements.
   */
  NodeValidatorBuilder.common() {
    allowHtml5();
    allowTemplating();
  }

  /**
   * Allows navigation elements- Form and Anchor tags, along with common
   * attributes.
   *
   * The UriPolicy can be used to restrict the locations the navigation elements
   * are allowed to direct to. By default this will use the default [UriPolicy].
   */
  void allowNavigation([UriPolicy uriPolicy]) {
    if (uriPolicy == null) {
      uriPolicy = new UriPolicy();
    }
    add(new _SimpleNodeValidator.allowNavigation(uriPolicy));
  }

  /**
   * Allows image elements.
   *
   * The UriPolicy can be used to restrict the locations the images may be
   * loaded from. By default this will use the default [UriPolicy].
   */
  void allowImages([UriPolicy uriPolicy]) {
    if (uriPolicy == null) {
      uriPolicy = new UriPolicy();
    }
    add(new _SimpleNodeValidator.allowImages(uriPolicy));
  }

  /**
   * Allow basic text elements.
   *
   * This allows a subset of HTML5 elements, specifically just these tags and
   * no attributes.
   *
   * * B
   * * BLOCKQUOTE
   * * BR
   * * EM
   * * H1
   * * H2
   * * H3
   * * H4
   * * H5
   * * H6
   * * HR
   * * I
   * * LI
   * * OL
   * * P
   * * SPAN
   * * UL
   */
  void allowTextElements() {
    add(new _SimpleNodeValidator.allowTextElements());
  }

  /**
   * Allow inline styles on elements.
   *
   * If [tagName] is not specified then this allows inline styles on all
   * elements. Otherwise tagName limits the styles to the specified elements.
   */
  void allowInlineStyles({String tagName}) {
    if (tagName == null) {
      tagName = '*';
    } else {
      tagName = tagName.toUpperCase();
    }
    add(new _SimpleNodeValidator(null, allowedAttributes: ['$tagName::style']));
  }

  /**
   * Allow common safe HTML5 elements and attributes.
   *
   * This list is based off of the Caja whitelists at:
   * https://code.google.com/p/google-caja/wiki/CajaWhitelists.
   *
   * Common things which are not allowed are script elements, style attributes
   * and any script handlers.
   */
  void allowHtml5({UriPolicy uriPolicy}) {
    add(new _Html5NodeValidator(uriPolicy: uriPolicy));
  }

  /**
   * Allow SVG elements and attributes except for known bad ones.
   */
  void allowSvg() {
    throw 'SVG not supported with DDC';
    // add(new _SvgNodeValidator());
  }

  /**
   * Allow custom elements with the specified tag name and specified attributes.
   *
   * This will allow the elements as custom tags (such as <x-foo></x-foo>),
   * but will not allow tag extensions. Use [allowTagExtension] to allow
   * tag extensions.
   */
  void allowCustomElement(String tagName,
      {UriPolicy uriPolicy,
      Iterable<String> attributes,
      Iterable<String> uriAttributes}) {

    var tagNameUpper = tagName.toUpperCase();
    var attrs;
    if (attributes != null) {
      attrs =
          attributes.map((name) => '$tagNameUpper::${name.toLowerCase()}');
    }
    var uriAttrs;
    if (uriAttributes != null) {
      uriAttrs =
          uriAttributes.map((name) => '$tagNameUpper::${name.toLowerCase()}');
    }
    if (uriPolicy == null) {
      uriPolicy = new UriPolicy();
    }

    add(new _CustomElementNodeValidator(
        uriPolicy,
        [tagNameUpper],
        attrs,
        uriAttrs,
        false,
        true));
  }

  /**
   * Allow custom tag extensions with the specified type name and specified
   * attributes.
   *
   * This will allow tag extensions (such as <div is="x-foo"></div>),
   * but will not allow custom tags. Use [allowCustomElement] to allow
   * custom tags.
   */
  void allowTagExtension(String tagName, String baseName,
      {UriPolicy uriPolicy,
      Iterable<String> attributes,
      Iterable<String> uriAttributes}) {

    var baseNameUpper = baseName.toUpperCase();
    var tagNameUpper = tagName.toUpperCase();
    var attrs;
    if (attributes != null) {
      attrs =
          attributes.map((name) => '$baseNameUpper::${name.toLowerCase()}');
    }
    var uriAttrs;
    if (uriAttributes != null) {
      uriAttrs =
          uriAttributes.map((name) => '$baseNameUpper::${name.toLowerCase()}');
    }
    if (uriPolicy == null) {
      uriPolicy = new UriPolicy();
    }

    add(new _CustomElementNodeValidator(
        uriPolicy,
        [tagNameUpper, baseNameUpper],
        attrs,
        uriAttrs,
        true,
        false));
  }

  void allowElement(String tagName, {UriPolicy uriPolicy,
    Iterable<String> attributes,
    Iterable<String> uriAttributes}) {

    allowCustomElement(tagName, uriPolicy: uriPolicy,
        attributes: attributes,
        uriAttributes: uriAttributes);
  }

  /**
   * Allow templating elements (such as <template> and template-related
   * attributes.
   *
   * This still requires other validators to allow regular attributes to be
   * bound (such as [allowHtml5]).
   */
  void allowTemplating() {
    add(new _TemplatingNodeValidator());
  }

  /**
   * Add an additional validator to the current list of validators.
   *
   * Elements and attributes will be accepted if they are accepted by any
   * validators.
   */
  void add(NodeValidator validator) {
    _validators.add(validator);
  }

  bool allowsElement(Element element) {
    return _validators.any((v) => v.allowsElement(element));
  }

  bool allowsAttribute(Element element, String attributeName, String value) {
    return _validators.any(
        (v) => v.allowsAttribute(element, attributeName, value));
  }
}

class _SimpleNodeValidator implements NodeValidator {
  final Set<String> allowedElements = new Set<String>();
  final Set<String> allowedAttributes = new Set<String>();
  final Set<String> allowedUriAttributes = new Set<String>();
  final UriPolicy uriPolicy;

  factory _SimpleNodeValidator.allowNavigation(UriPolicy uriPolicy) {
    return new _SimpleNodeValidator(uriPolicy,
      allowedElements: const [
        'A',
        'FORM'],
      allowedAttributes: const [
        'A::accesskey',
        'A::coords',
        'A::hreflang',
        'A::name',
        'A::shape',
        'A::tabindex',
        'A::target',
        'A::type',
        'FORM::accept',
        'FORM::autocomplete',
        'FORM::enctype',
        'FORM::method',
        'FORM::name',
        'FORM::novalidate',
        'FORM::target',
      ],
      allowedUriAttributes: const [
        'A::href',
        'FORM::action',
      ]);
  }

  factory _SimpleNodeValidator.allowImages(UriPolicy uriPolicy) {
    return new _SimpleNodeValidator(uriPolicy,
      allowedElements: const [
        'IMG'
      ],
      allowedAttributes: const [
        'IMG::align',
        'IMG::alt',
        'IMG::border',
        'IMG::height',
        'IMG::hspace',
        'IMG::ismap',
        'IMG::name',
        'IMG::usemap',
        'IMG::vspace',
        'IMG::width',
      ],
      allowedUriAttributes: const [
        'IMG::src',
      ]);
  }

  factory _SimpleNodeValidator.allowTextElements() {
    return new _SimpleNodeValidator(null,
      allowedElements: const [
        'B',
        'BLOCKQUOTE',
        'BR',
        'EM',
        'H1',
        'H2',
        'H3',
        'H4',
        'H5',
        'H6',
        'HR',
        'I',
        'LI',
        'OL',
        'P',
        'SPAN',
        'UL',
      ]);
  }

  /**
   * Elements must be uppercased tag names. For example `'IMG'`.
   * Attributes must be uppercased tag name followed by :: followed by
   * lowercase attribute name. For example `'IMG:src'`.
   */
  _SimpleNodeValidator(this.uriPolicy,
      {Iterable<String> allowedElements, Iterable<String> allowedAttributes,
        Iterable<String> allowedUriAttributes}) {
    this.allowedElements.addAll(allowedElements ?? const []);
    allowedAttributes = allowedAttributes ?? const [];
    allowedUriAttributes = allowedUriAttributes ?? const [];
    var legalAttributes = allowedAttributes.where(
        (x) => !_Html5NodeValidator._uriAttributes.contains(x));
    var extraUriAttributes = allowedAttributes.where(
        (x) => _Html5NodeValidator._uriAttributes.contains(x));
    this.allowedAttributes.addAll(legalAttributes);
    this.allowedUriAttributes.addAll(allowedUriAttributes);
    this.allowedUriAttributes.addAll(extraUriAttributes);
  }

  bool allowsElement(Element element) {
    return allowedElements.contains(Element._safeTagName(element));
  }

  bool allowsAttribute(Element element, String attributeName, String value) {
    var tagName = Element._safeTagName(element);
    if (allowedUriAttributes.contains('$tagName::$attributeName')) {
      return uriPolicy.allowsUri(value);
    } else if (allowedUriAttributes.contains('*::$attributeName')) {
      return uriPolicy.allowsUri(value);
    } else if (allowedAttributes.contains('$tagName::$attributeName')) {
      return true;
    } else if (allowedAttributes.contains('*::$attributeName')) {
      return true;
    } else if (allowedAttributes.contains('$tagName::*')) {
      return true;
    } else if (allowedAttributes.contains('*::*')) {
      return true;
    }
    return false;
  }
}

class _CustomElementNodeValidator extends _SimpleNodeValidator {
  final bool allowTypeExtension;
  final bool allowCustomTag;

  _CustomElementNodeValidator(UriPolicy uriPolicy,
      Iterable<String> allowedElements,
      Iterable<String> allowedAttributes,
      Iterable<String> allowedUriAttributes,
      bool allowTypeExtension,
      bool allowCustomTag):

      this.allowTypeExtension = allowTypeExtension == true,
      this.allowCustomTag = allowCustomTag == true,
      super(uriPolicy,
          allowedElements: allowedElements,
          allowedAttributes: allowedAttributes,
          allowedUriAttributes: allowedUriAttributes);

  bool allowsElement(Element element) {
    if (allowTypeExtension) {
      var isAttr = element.attributes['is'];
      if (isAttr != null) {
        return allowedElements.contains(isAttr.toUpperCase()) &&
            allowedElements.contains(Element._safeTagName(element));
      }
    }
    return allowCustomTag && allowedElements.contains(Element._safeTagName(element));
  }

  bool allowsAttribute(Element element, String attributeName, String value) {
   if (allowsElement(element)) {
      if (allowTypeExtension && attributeName == 'is' &&
          allowedElements.contains(value.toUpperCase())) {
        return true;
      }
      return super.allowsAttribute(element, attributeName, value);
    }
    return false;
  }
}

class _TemplatingNodeValidator extends _SimpleNodeValidator {
  static const _TEMPLATE_ATTRS =
      const <String>['bind', 'if', 'ref', 'repeat', 'syntax'];

  final Set<String> _templateAttrs;

  _TemplatingNodeValidator():
      _templateAttrs = new Set<String>.from(_TEMPLATE_ATTRS),
      super(null,
          allowedElements: [
            'TEMPLATE'
          ],
          allowedAttributes: _TEMPLATE_ATTRS.map((attr) => 'TEMPLATE::$attr'));

  bool allowsAttribute(Element element, String attributeName, String value) {
    if (super.allowsAttribute(element, attributeName, value)) {
      return true;
    }

    if (attributeName == 'template' && value == "") {
      return true;
    }

    if (element.attributes['template'] == "" ) {
      return _templateAttrs.contains(attributeName);
    }
    return false;
  }
}

/*
class _SvgNodeValidator implements NodeValidator {
  bool allowsElement(Element element) {
    if (element is svg.ScriptElement) {
      return false;
    }
    // Firefox 37 has issues with creating foreign elements inside a
    // foreignobject tag as SvgElement. We don't want foreignobject contents
    // anyway, so just remove the whole tree outright. And we can't rely
    // on IE recognizing the SvgForeignObject type, so go by tagName. Bug 23144
    if (element is svg.SvgElement && Element._safeTagName(element) == 'foreignObject') {
      return false;
    }
    if (element is svg.SvgElement) {
      return true;
    }
    return false;
  }

  bool allowsAttribute(Element element, String attributeName, String value) {
    if (attributeName == 'is' || attributeName.startsWith('on')) {
      return false;
    }
    return allowsElement(element);
  }
}
*/// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * Contains the set of standard values returned by HTMLDocument.getReadyState.
 */
abstract class ReadyState {
  /**
   * Indicates the document is still loading and parsing.
   */
  static const String LOADING = "loading";

  /**
   * Indicates the document is finished parsing but is still loading
   * subresources.
   */
  static const String INTERACTIVE = "interactive";

  /**
   * Indicates the document and all subresources have been loaded.
   */
  static const String COMPLETE = "complete";
}
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * A list which just wraps another list, for either intercepting list calls or
 * retyping the list (for example, from List<A> to List<B> where B extends A).
 */
class _WrappedList<E extends Node> extends ListBase<E>
    implements NodeListWrapper {
  final List _list;

  _WrappedList(this._list);

  // Iterable APIs

  Iterator<E> get iterator => new _WrappedIterator(_list.iterator);

  int get length => _list.length;

  // Collection APIs

  void add(E element) { _list.add(element); }

  bool remove(Object element) => _list.remove(element);

  void clear() { _list.clear(); }

  // List APIs

  E operator [](int index) => _list[index];

  void operator []=(int index, E value) { _list[index] = value; }

  set length(int newLength) { _list.length = newLength; }

  void sort([int compare(E a, E b)]) { _list.sort(compare); }

  int indexOf(Object element, [int start = 0]) => _list.indexOf(element, start);

  int lastIndexOf(Object element, [int start]) => _list.lastIndexOf(element, start);

  void insert(int index, E element) => _list.insert(index, element);

  E removeAt(int index) => _list.removeAt(index);

  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    _list.setRange(start, end, iterable, skipCount);
  }

  void removeRange(int start, int end) { _list.removeRange(start, end); }

  void replaceRange(int start, int end, Iterable<E> iterable) {
    _list.replaceRange(start, end, iterable);
  }

  void fillRange(int start, int end, [E fillValue]) {
    _list.fillRange(start, end, fillValue);
  }

  List<Node> get rawList => _list;
}

/**
 * Iterator wrapper for _WrappedList.
 */
class _WrappedIterator<E> implements Iterator<E> {
  Iterator _iterator;

  _WrappedIterator(this._iterator);

  bool moveNext() {
    return _iterator.moveNext();
  }

  E get current => _iterator.current;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _HttpRequestUtils {

  // Helper for factory HttpRequest.get
  static HttpRequest get(String url,
                            onComplete(HttpRequest request),
                            bool withCredentials) {
    final request = new HttpRequest();
    request.open('GET', url, async: true);

    request.withCredentials = withCredentials;

    request.onReadyStateChange.listen((e) {
      if (request.readyState == HttpRequest.DONE) {
        onComplete(request);
      }
    });

    request.send();

    return request;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// Iterator for arrays with fixed size.
class FixedSizeListIterator<T> implements Iterator<T> {
  final List<T> _array;
  final int _length;  // Cache array length for faster access.
  int _position;
  T _current;

  FixedSizeListIterator(List<T> array)
      : _array = array,
        _position = -1,
        _length = array.length;

  bool moveNext() {
    int nextPosition = _position + 1;
    if (nextPosition < _length) {
      _current = _array[nextPosition];
      _position = nextPosition;
      return true;
    }
    _current = null;
    _position = _length;
    return false;
  }

  T get current => _current;
}

// Iterator for arrays with variable size.
class _VariableSizeListIterator<T> implements Iterator<T> {
  final List<T> _array;
  int _position;
  T _current;

  _VariableSizeListIterator(List<T> array)
      : _array = array,
        _position = -1;

  bool moveNext() {
    int nextPosition = _position + 1;
    if (nextPosition < _array.length) {
      _current = _array[nextPosition];
      _position = nextPosition;
      return true;
    }
    _current = null;
    _position = _array.length;
    return false;
  }

  T get current => _current;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// Conversions for Window.  These check if the window is the local
// window, and if it's not, wraps or unwraps it with a secure wrapper.
// We need to test for EventTarget here as well as it's a base type.
// We omit an unwrapper for Window as no methods take a non-local
// window as a parameter.


WindowBase _convertNativeToDart_Window(win) {
  if (win == null) return null;
  return _DOMWindowCrossFrame._createSafe(win);
}

EventTarget _convertNativeToDart_EventTarget(e) {
  if (e == null) {
    return null;
  }
  // Assume it's a Window if it contains the postMessage property.  It may be
  // from a different frame - without a patched prototype - so we cannot
  // rely on Dart type checking.
  if (JS('bool', r'"postMessage" in #', e)) {
    var window = _DOMWindowCrossFrame._createSafe(e);
    // If it's a native window.
    if (window is EventTarget) {
      return window;
    }
    return null;
  }
  else
    return e;
}

EventTarget _convertDartToNative_EventTarget(e) {
  if (e is _DOMWindowCrossFrame) {
    return e._window;
  } else {
    return e;
  }
}

_convertNativeToDart_XHR_Response(o) {
  if (o is Document) {
    return o;
  }
  return convertNativeToDart_SerializedScriptValue(o);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// TODO(vsm): Unify with Dartium version.
class _DOMWindowCrossFrame implements WindowBase {
  // Private window.  Note, this is a window in another frame, so it
  // cannot be typed as "Window" as its prototype is not patched
  // properly.  Its fields and methods can only be accessed via JavaScript.
  final _window;

  // Fields.
  HistoryBase get history =>
    _HistoryCrossFrame._createSafe(JS('HistoryBase', '#.history', _window));
  LocationBase get location =>
    _LocationCrossFrame._createSafe(JS('LocationBase', '#.location', _window));

  // TODO(vsm): Add frames to navigate subframes.  See 2312.

  bool get closed => JS('bool', '#.closed', _window);

  WindowBase get opener => _createSafe(JS('WindowBase', '#.opener', _window));

  WindowBase get parent => _createSafe(JS('WindowBase', '#.parent', _window));

  WindowBase get top => _createSafe(JS('WindowBase', '#.top', _window));

  // Methods.
  void close() => JS('void', '#.close()', _window);

  void postMessage(var message, String targetOrigin, [List messagePorts = null]) {
    if (messagePorts == null) {
      JS('void', '#.postMessage(#,#)', _window,
          convertDartToNative_SerializedScriptValue(message), targetOrigin);
    } else {
      JS('void', '#.postMessage(#,#,#)', _window,
          convertDartToNative_SerializedScriptValue(message), targetOrigin,
          messagePorts);
    }
  }

  // Implementation support.
  _DOMWindowCrossFrame(this._window);

  static WindowBase _createSafe(w) {
    if (identical(w, window)) {
      return w;
    } else {
      // TODO(vsm): Cache or implement equality.
      return new _DOMWindowCrossFrame(w);
    }
  }

  // TODO(efortuna): Remove this method. dartbug.com/16814
  Events get on => throw new UnsupportedError(
    'You can only attach EventListeners to your own window.');
  // TODO(efortuna): Remove this method. dartbug.com/16814
  void _addEventListener([String type, EventListener listener, bool useCapture])
      => throw new UnsupportedError(
    'You can only attach EventListeners to your own window.');
  // TODO(efortuna): Remove this method. dartbug.com/16814
  void addEventListener(String type, EventListener listener, [bool useCapture])
      => throw new UnsupportedError(
        'You can only attach EventListeners to your own window.');
  // TODO(efortuna): Remove this method. dartbug.com/16814
  bool dispatchEvent(Event event) => throw new UnsupportedError(
    'You can only attach EventListeners to your own window.');
  // TODO(efortuna): Remove this method. dartbug.com/16814
  void _removeEventListener([String type, EventListener listener,
      bool useCapture]) => throw new UnsupportedError(
    'You can only attach EventListeners to your own window.');
  // TODO(efortuna): Remove this method. dartbug.com/16814
  void removeEventListener(String type, EventListener listener,
      [bool useCapture]) => throw new UnsupportedError(
          'You can only attach EventListeners to your own window.');
}

class _LocationCrossFrame implements LocationBase {
  // Private location.  Note, this is a location object in another frame, so it
  // cannot be typed as "Location" as its prototype is not patched
  // properly.  Its fields and methods can only be accessed via JavaScript.
  var _location;

  set href(String val) => _setHref(_location, val);
  static void _setHref(location, val) {
    JS('void', '#.href = #', location, val);
  }

  // Implementation support.
  _LocationCrossFrame(this._location);

  static LocationBase _createSafe(location) {
    if (identical(location, window.location)) {
      return location;
    } else {
      // TODO(vsm): Cache or implement equality.
      return new _LocationCrossFrame(location);
    }
  }
}

class _HistoryCrossFrame implements HistoryBase {
  // Private history.  Note, this is a history object in another frame, so it
  // cannot be typed as "History" as its prototype is not patched
  // properly.  Its fields and methods can only be accessed via JavaScript.
  var _history;

  void back() => JS('void', '#.back()', _history);

  void forward() => JS('void', '#.forward()', _history);

  void go(int distance) => JS('void', '#.go(#)', _history, distance);

  // Implementation support.
  _HistoryCrossFrame(this._history);

  static HistoryBase _createSafe(h) {
    if (identical(h, window.history)) {
      return h;
    } else {
      // TODO(vsm): Cache or implement equality.
      return new _HistoryCrossFrame(h);
    }
  }
}
/**
 * A custom KeyboardEvent that attempts to eliminate cross-browser
 * inconsistencies, and also provide both keyCode and charCode information
 * for all key events (when such information can be determined).
 *
 * KeyEvent tries to provide a higher level, more polished keyboard event
 * information on top of the "raw" [KeyboardEvent].
 *
 * The mechanics of using KeyEvents is a little different from the underlying
 * [KeyboardEvent]. To use KeyEvents, you need to create a stream and then add
 * KeyEvents to the stream, rather than using the [EventTarget.dispatchEvent].
 * Here's an example usage:
 *
 *     // Initialize a stream for the KeyEvents:
 *     var stream = KeyEvent.keyPressEvent.forTarget(document.body);
 *     // Start listening to the stream of KeyEvents.
 *     stream.listen((keyEvent) =>
 *         window.console.log('KeyPress event detected ${keyEvent.charCode}'));
 *     ...
 *     // Add a new KeyEvent of someone pressing the 'A' key to the stream so
 *     // listeners can know a KeyEvent happened.
 *     stream.add(new KeyEvent('keypress', keyCode: 65, charCode: 97));
 *
 * This class is very much a work in progress, and we'd love to get information
 * on how we can make this class work with as many international keyboards as
 * possible. Bugs welcome!
 */
@Experimental()
class KeyEvent extends _WrappedEvent implements KeyboardEvent {
  /** The parent KeyboardEvent that this KeyEvent is wrapping and "fixing". */
  KeyboardEvent _parent;

  /** The "fixed" value of whether the alt key is being pressed. */
  bool _shadowAltKey;

  /** Caculated value of what the estimated charCode is for this event. */
  int _shadowCharCode;

  /** Caculated value of what the estimated keyCode is for this event. */
  int _shadowKeyCode;

  /** Caculated value of what the estimated keyCode is for this event. */
  int get keyCode => _shadowKeyCode;

  /** Caculated value of what the estimated charCode is for this event. */
  int get charCode => this.type == 'keypress' ? _shadowCharCode : 0;

  /** Caculated value of whether the alt key is pressed is for this event. */
  bool get altKey => _shadowAltKey;

  /** Caculated value of what the estimated keyCode is for this event. */
  int get which => keyCode;

  /** Accessor to the underlying keyCode value is the parent event. */
  int get _realKeyCode => JS('int', '#.keyCode', _parent);

  /** Accessor to the underlying charCode value is the parent event. */
  int get _realCharCode => JS('int', '#.charCode', _parent);

  /** Accessor to the underlying altKey value is the parent event. */
  bool get _realAltKey => JS('bool', '#.altKey', _parent);

  /** Shadows on top of the parent's currentTarget. */
  EventTarget _currentTarget;

  /**
   * The value we want to use for this object's dispatch. Created here so it is
   * only invoked once.
   */
  static final _keyboardEventDispatchRecord = _makeRecord();

  /** Helper to statically create the dispatch record. */
  static _makeRecord() {
    var interceptor = JS_INTERCEPTOR_CONSTANT(KeyboardEvent);
    return makeLeafDispatchRecord(interceptor);
  }

  /** Construct a KeyEvent with [parent] as the event we're emulating. */
  KeyEvent.wrap(KeyboardEvent parent): super(parent) {
    _parent = parent;
    _shadowAltKey = _realAltKey;
    _shadowCharCode = _realCharCode;
    _shadowKeyCode = _realKeyCode;
    _currentTarget = _parent.currentTarget;
  }

  /** Programmatically create a new KeyEvent (and KeyboardEvent). */
  factory KeyEvent(String type,
      {Window view, bool canBubble: true, bool cancelable: true, int keyCode: 0,
      int charCode: 0, int keyLocation: 1, bool ctrlKey: false,
      bool altKey: false, bool shiftKey: false, bool metaKey: false,
      EventTarget currentTarget}) {
    if (view == null) {
      view = window;
    }

    var eventObj;
    // In these two branches we create an underlying native KeyboardEvent, but
    // we set it with our specified values. Because we are doing custom setting
    // of certain values (charCode/keyCode, etc) only in this class (as opposed
    // to KeyboardEvent) and the way we set these custom values depends on the
    // type of underlying JS object, we do all the contruction for the
    // underlying KeyboardEvent here.
    if (canUseDispatchEvent) {
      // Currently works in everything but Internet Explorer.
      eventObj = new Event.eventType('Event', type,
          canBubble: canBubble, cancelable: cancelable);

      JS('void', '#.keyCode = #', eventObj, keyCode);
      JS('void', '#.which = #', eventObj, keyCode);
      JS('void', '#.charCode = #', eventObj, charCode);

      JS('void', '#.keyLocation = #', eventObj, keyLocation);
      JS('void', '#.ctrlKey = #', eventObj, ctrlKey);
      JS('void', '#.altKey = #', eventObj, altKey);
      JS('void', '#.shiftKey = #', eventObj, shiftKey);
      JS('void', '#.metaKey = #', eventObj, metaKey);
    } else {
      // Currently this works on everything but Safari. Safari throws an
      // "Attempting to change access mechanism for an unconfigurable property"
      // TypeError when trying to do the Object.defineProperty hack, so we avoid
      // this branch if possible.
      // Also, if we want this branch to work in FF, we also need to modify
      // _initKeyboardEvent to also take charCode and keyCode values to
      // initialize initKeyEvent.

      eventObj = new Event.eventType('KeyboardEvent', type,
          canBubble: canBubble, cancelable: cancelable);

      // Chromium Hack
      JS('void', "Object.defineProperty(#, 'keyCode', {"
          "  get : function() { return this.keyCodeVal; } })",  eventObj);
      JS('void', "Object.defineProperty(#, 'which', {"
          "  get : function() { return this.keyCodeVal; } })",  eventObj);
      JS('void', "Object.defineProperty(#, 'charCode', {"
          "  get : function() { return this.charCodeVal; } })",  eventObj);

      var keyIdentifier = _convertToHexString(charCode, keyCode);
      eventObj._initKeyboardEvent(type, canBubble, cancelable, view,
          keyIdentifier, keyLocation, ctrlKey, altKey, shiftKey, metaKey);
      JS('void', '#.keyCodeVal = #', eventObj, keyCode);
      JS('void', '#.charCodeVal = #', eventObj, charCode);
    }
    // Tell dart2js that it smells like a KeyboardEvent!
    setDispatchProperty(eventObj, _keyboardEventDispatchRecord);

    var keyEvent = new KeyEvent.wrap(eventObj);
    if (keyEvent._currentTarget == null) {
      keyEvent._currentTarget = currentTarget == null ? window : currentTarget;
    }
    return keyEvent;
  }

  // Currently known to work on all browsers but IE.
  static bool get canUseDispatchEvent =>
      JS('bool',
         '(typeof document.body.dispatchEvent == "function")'
         '&& document.body.dispatchEvent.length > 0');

  /** The currently registered target for this event. */
  EventTarget get currentTarget => _currentTarget;

  // This is an experimental method to be sure.
  static String _convertToHexString(int charCode, int keyCode) {
    if (charCode != -1) {
      var hex = charCode.toRadixString(16); // Convert to hexadecimal.
      StringBuffer sb = new StringBuffer('U+');
      for (int i = 0; i < 4 - hex.length; i++) sb.write('0');
      sb.write(hex);
      return sb.toString();
    } else {
      return KeyCode._convertKeyCodeToKeyName(keyCode);
    }
  }

  // TODO(efortuna): If KeyEvent is sufficiently successful that we want to make
  // it the default keyboard event handling, move these methods over to Element.
  /** Accessor to provide a stream of KeyEvents on the desired target. */
  static EventStreamProvider<KeyEvent> keyDownEvent =
      new _KeyboardEventHandler('keydown');
  /** Accessor to provide a stream of KeyEvents on the desired target. */
  static EventStreamProvider<KeyEvent> keyUpEvent =
      new _KeyboardEventHandler('keyup');
  /** Accessor to provide a stream of KeyEvents on the desired target. */
  static EventStreamProvider<KeyEvent> keyPressEvent =
      new _KeyboardEventHandler('keypress');

  /** Accessor to the clipboardData available for this event. */
  DataTransfer get clipboardData => _parent.clipboardData;
  /** True if the ctrl key is pressed during this event. */
  bool get ctrlKey => _parent.ctrlKey;
  int get detail => _parent.detail;
  /**
   * Accessor to the part of the keyboard that the key was pressed from (one of
   * KeyLocation.STANDARD, KeyLocation.RIGHT, KeyLocation.LEFT,
   * KeyLocation.NUMPAD, KeyLocation.MOBILE, KeyLocation.JOYSTICK).
   */
  int get keyLocation => _parent.keyLocation;
  Point get layer => _parent.layer;
  /** True if the Meta (or Mac command) key is pressed during this event. */
  bool get metaKey => _parent.metaKey;
  Point get page => _parent.page;
  /** True if the shift key was pressed during this event. */
  bool get shiftKey => _parent.shiftKey;
  Window get view => _parent.view;
  void _initUIEvent(String type, bool canBubble, bool cancelable,
      Window view, int detail) {
    throw new UnsupportedError("Cannot initialize a UI Event from a KeyEvent.");
  }
  String get _shadowKeyIdentifier => JS('String', '#.keyIdentifier', _parent);

  int get _charCode => charCode;
  int get _keyCode => keyCode;
  String get _keyIdentifier {
    throw new UnsupportedError("keyIdentifier is unsupported.");
  }
  void _initKeyboardEvent(String type, bool canBubble, bool cancelable,
      Window view, String keyIdentifier, int keyLocation, bool ctrlKey,
      bool altKey, bool shiftKey, bool metaKey) {
    throw new UnsupportedError(
        "Cannot initialize a KeyboardEvent from a KeyEvent.");
  }
  int get _layerX => throw new UnsupportedError('Not applicable to KeyEvent');
  int get _layerY => throw new UnsupportedError('Not applicable to KeyEvent');
  int get _pageX => throw new UnsupportedError('Not applicable to KeyEvent');
  int get _pageY => throw new UnsupportedError('Not applicable to KeyEvent');
  @Experimental() // untriaged
  bool getModifierState(String keyArgument) => throw new UnimplementedError();
  @Experimental() // untriaged
  int get location => throw new UnimplementedError();
  @Experimental() // untriaged
  bool get repeat => throw new UnimplementedError();
  dynamic get _get_view => throw new UnimplementedError();
}
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Platform {
  /**
   * Returns true if dart:typed_data types are supported on this
   * browser.  If false, using these types will generate a runtime
   * error.
   */
  static final supportsTypedData = JS('bool', '!!($global_.ArrayBuffer)');

  /**
   * Returns true if SIMD types in dart:typed_data types are supported
   * on this browser.  If false, using these types will generate a runtime
   * error.
   */
  static final supportsSimd = false;
}
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * Helper class to implement custom events which wrap DOM events.
 */
class _WrappedEvent implements Event {
  final Event wrapped;

  /** The CSS selector involved with event delegation. */
  String _selector;

  _WrappedEvent(this.wrapped);

  bool get bubbles => wrapped.bubbles;

  bool get cancelable => wrapped.cancelable;

  DataTransfer get clipboardData => wrapped.clipboardData;

  EventTarget get currentTarget => wrapped.currentTarget;

  bool get defaultPrevented => wrapped.defaultPrevented;

  int get eventPhase => wrapped.eventPhase;

  EventTarget get target => wrapped.target;

  int get timeStamp => wrapped.timeStamp;

  String get type => wrapped.type;

  void _initEvent(String eventTypeArg, bool canBubbleArg,
      bool cancelableArg) {
    throw new UnsupportedError(
        'Cannot initialize this Event.');
  }

  void preventDefault() {
    wrapped.preventDefault();
  }

  void stopImmediatePropagation() {
    wrapped.stopImmediatePropagation();
  }

  void stopPropagation() {
    wrapped.stopPropagation();
  }

  /**
   * A pointer to the element whose CSS selector matched within which an event
   * was fired. If this Event was not associated with any Event delegation,
   * accessing this value will throw an [UnsupportedError].
   */
  Element get matchingTarget {
    if (_selector == null) {
      throw new UnsupportedError('Cannot call matchingTarget if this Event did'
          ' not arise as a result of event delegation.');
    }
    var currentTarget = this.currentTarget;
    var target = this.target;
    var matchedTarget;
    do {
      if (target.matches(_selector)) return target;
      target = target.parent;
    } while (target != null && target != currentTarget.parent);
    throw new StateError('No selector matched for populating matchedTarget.');
  }

  /**
   * This event's path, taking into account shadow DOM.
   *
   * ## Other resources
   *
   * * [Shadow DOM extensions to Event]
   * (http://w3c.github.io/webcomponents/spec/shadow/#extensions-to-event) from
   * W3C.
   */
  // https://dvcs.w3.org/hg/webcomponents/raw-file/tip/spec/shadow/index.html#extensions-to-event
  @Experimental()
  List<Node> get path => wrapped.path;

  dynamic get _get_currentTarget => wrapped._get_currentTarget;

  dynamic get _get_target => wrapped._get_target;
}
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


_wrapZone(callback(arg)) {
  // For performance reasons avoid wrapping if we are in the root zone.
  if (Zone.current == Zone.ROOT) return callback;
  if (callback == null) return null;
  return Zone.current.bindUnaryCallback(callback, runGuarded: true);
}

_wrapBinaryZone(callback(arg1, arg2)) {
  if (Zone.current == Zone.ROOT) return callback;
  if (callback == null) return null;
  return Zone.current.bindBinaryCallback(callback, runGuarded: true);
}

/**
 * Alias for [querySelector]. Note this function is deprecated because its
 * semantics will be changing in the future.
 */
@deprecated
@Experimental()
Element query(String relativeSelectors) => document.query(relativeSelectors);
/**
 * Alias for [querySelectorAll]. Note this function is deprecated because its
 * semantics will be changing in the future.
 */
@deprecated
@Experimental()
ElementList<Element> queryAll(String relativeSelectors) => document.queryAll(relativeSelectors);

/**
 * Finds the first descendant element of this document that matches the
 * specified group of selectors.
 *
 * Unless your webpage contains multiple documents, the top-level
 * [querySelector]
 * method behaves the same as this method, so you should use it instead to
 * save typing a few characters.
 *
 * [selectors] should be a string using CSS selector syntax.
 *
 *     var element1 = document.querySelector('.className');
 *     var element2 = document.querySelector('#id');
 *
 * For details about CSS selector syntax, see the
 * [CSS selector specification](http://www.w3.org/TR/css3-selectors/).
 */
Element querySelector(String selectors) => document.querySelector(selectors);

/**
 * Finds all descendant elements of this document that match the specified
 * group of selectors.
 *
 * Unless your webpage contains multiple documents, the top-level
 * [querySelectorAll]
 * method behaves the same as this method, so you should use it instead to
 * save typing a few characters.
 *
 * [selectors] should be a string using CSS selector syntax.
 *
 *     var items = document.querySelectorAll('.itemClassName');
 *
 * For details about CSS selector syntax, see the
 * [CSS selector specification](http://www.w3.org/TR/css3-selectors/).
 */
ElementList<Element> querySelectorAll(String selectors) => document.querySelectorAll(selectors);

/// A utility for changing the Dart wrapper type for elements.
abstract class ElementUpgrader {
  /// Upgrade the specified element to be of the Dart type this was created for.
  ///
  /// After upgrading the element passed in is invalid and the returned value
  /// should be used instead.
  Element upgrade(Element element);
}
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



/**
 * Interface used to validate that only accepted elements and attributes are
 * allowed while parsing HTML strings into DOM nodes.
 *
 * In general, customization of validation behavior should be done via the
 * [NodeValidatorBuilder] class to mitigate the chances of incorrectly
 * implementing validation rules.
 */
abstract class NodeValidator {

  /**
   * Construct a default NodeValidator which only accepts whitelisted HTML5
   * elements and attributes.
   *
   * If a uriPolicy is not specified then the default uriPolicy will be used.
   */
  factory NodeValidator({UriPolicy uriPolicy}) =>
      new _Html5NodeValidator(uriPolicy: uriPolicy);

  factory NodeValidator.throws(NodeValidator base) =>
      new _ThrowsNodeValidator(base);

  /**
   * Returns true if the tagName is an accepted type.
   */
  bool allowsElement(Element element);

  /**
   * Returns true if the attribute is allowed.
   *
   * The attributeName parameter will always be in lowercase.
   *
   * See [allowsElement] for format of tagName.
   */
  bool allowsAttribute(Element element, String attributeName, String value);
}

/**
 * Performs sanitization of a node tree after construction to ensure that it
 * does not contain any disallowed elements or attributes.
 *
 * In general custom implementations of this class should not be necessary and
 * all validation customization should be done in custom NodeValidators, but
 * custom implementations of this class can be created to perform more complex
 * tree sanitization.
 */
abstract class NodeTreeSanitizer {

  /**
   * Constructs a default tree sanitizer which will remove all elements and
   * attributes which are not allowed by the provided validator.
   */
  factory NodeTreeSanitizer(NodeValidator validator) =>
      new _ValidatingTreeSanitizer(validator);

  /**
   * Called with the root of the tree which is to be sanitized.
   *
   * This method needs to walk the entire tree and either remove elements and
   * attributes which are not recognized as safe or throw an exception which
   * will mark the entire tree as unsafe.
   */
  void sanitizeTree(Node node);

  /**
   * A sanitizer for trees that we trust. It does no validation and allows
   * any elements. It is also more efficient, since it can pass the text
   * directly through to the underlying APIs without creating a document
   * fragment to be sanitized.
   */
  static const trusted = const _TrustedHtmlTreeSanitizer();
}

/**
 * A sanitizer for trees that we trust. It does no validation and allows
 * any elements.
 */
class _TrustedHtmlTreeSanitizer implements NodeTreeSanitizer {
  const _TrustedHtmlTreeSanitizer();

  sanitizeTree(Node node) {}
}

/**
 * Defines the policy for what types of uris are allowed for particular
 * attribute values.
 *
 * This can be used to provide custom rules such as allowing all http:// URIs
 * for image attributes but only same-origin URIs for anchor tags.
 */
abstract class UriPolicy {
  /**
   * Constructs the default UriPolicy which is to only allow Uris to the same
   * origin as the application was launched from.
   *
   * This will block all ftp: mailto: URIs. It will also block accessing
   * https://example.com if the app is running from http://example.com.
   */
  factory UriPolicy() => new _SameOriginUriPolicy();

  /**
   * Checks if the uri is allowed on the specified attribute.
   *
   * The uri provided may or may not be a relative path.
   */
  bool allowsUri(String uri);
}

/**
 * Allows URIs to the same origin as the current application was loaded from
 * (such as https://example.com:80).
 */
class _SameOriginUriPolicy implements UriPolicy {
  final AnchorElement _hiddenAnchor = new AnchorElement();
  final Location _loc = window.location;

  bool allowsUri(String uri) {
    _hiddenAnchor.href = uri;
    // IE leaves an empty hostname for same-origin URIs.
    return (_hiddenAnchor.hostname == _loc.hostname &&
        _hiddenAnchor.port == _loc.port &&
        _hiddenAnchor.protocol == _loc.protocol) ||
        (_hiddenAnchor.hostname == '' &&
        _hiddenAnchor.port == '' &&
        (_hiddenAnchor.protocol == ':' || _hiddenAnchor.protocol == ''));
  }
}


class _ThrowsNodeValidator implements NodeValidator {
  final NodeValidator validator;

  _ThrowsNodeValidator(this.validator) {}

  bool allowsElement(Element element) {
    if (!validator.allowsElement(element)) {
      throw new ArgumentError(Element._safeTagName(element));
    }
    return true;
  }

  bool allowsAttribute(Element element, String attributeName, String value) {
    if (!validator.allowsAttribute(element, attributeName, value)) {
      throw new ArgumentError('${Element._safeTagName(element)}[$attributeName="$value"]');
    }
  }
}


/**
 * Standard tree sanitizer which validates a node tree against the provided
 * validator and removes any nodes or attributes which are not allowed.
 */
class _ValidatingTreeSanitizer implements NodeTreeSanitizer {
  NodeValidator validator;
  _ValidatingTreeSanitizer(this.validator) {}

  void sanitizeTree(Node node) {
    void walk(Node node, Node parent) {
      sanitizeNode(node, parent);

      var child = node.lastChild;
      while (child != null) {
        // Child may be removed during the walk.
        var nextChild = child.previousNode;
        walk(child, node);
        child = nextChild;
      }
    }
    walk(node, null);
  }

  /// Aggressively try to remove node.
  void _removeNode(Node node, Node parent) {
    // If we have the parent, it's presumably already passed more sanitization
    // or is the fragment, so ask it to remove the child. And if that fails
    // try to set the outer html.
    if (parent == null) {
      node.remove();
    } else {
      parent._removeChild(node);
    }
  }

  /// Sanitize the element, assuming we can't trust anything about it.
  void _sanitizeUntrustedElement(/* Element */ element, Node parent) {
    // If the _hasCorruptedAttributes does not successfully return false,
    // then we consider it corrupted and remove.
    // TODO(alanknight): This is a workaround because on Firefox
    // embed/object
    // tags typeof is "function", not "object". We don't recognize them, and
    // can't call methods. This does mean that you can't explicitly allow an
    // embed tag. The only thing that will let it through is a null
    // sanitizer that doesn't traverse the tree at all. But sanitizing while
    // allowing embeds seems quite unlikely. This is also the reason that we
    // can't declare the type of element, as an embed won't pass any type
    // check in dart2js.
    var corrupted = true;
    var attrs;
    var isAttr;
    try {
      // If getting/indexing attributes throws, count that as corrupt.
      attrs = element.attributes;
      isAttr = attrs['is'];
      var corruptedTest1 = Element._hasCorruptedAttributes(element);

      // On IE, erratically, the hasCorruptedAttributes test can return false,
      // even though it clearly is corrupted. A separate copy of the test
      // inlining just the basic check seems to help.
      corrupted = corruptedTest1 ? true : Element._hasCorruptedAttributesAdditionalCheck(element);
    } catch(e) {}
    var elementText = 'element unprintable';
    try {
      elementText = element.toString();
    } catch(e) {}
    try {
      var elementTagName = Element._safeTagName(element);
      _sanitizeElement(element, parent, corrupted, elementText, elementTagName,
          attrs, isAttr);
    } on ArgumentError { // Thrown by _ThrowsNodeValidator
      rethrow;
    } catch(e) {  // Unexpected exception sanitizing -> remove
      _removeNode(element, parent);
      window.console.warn('Removing corrupted element $elementText');
    }
  }

  /// Having done basic sanity checking on the element, and computed the
  /// important attributes we want to check, remove it if it's not valid
  /// or not allowed, either as a whole or particular attributes.
  void _sanitizeElement(Element element, Node parent, bool corrupted,
      String text, String tag, Map attrs, String isAttr) {
    if (false != corrupted) {
       _removeNode(element, parent);
      window.console.warn(
          'Removing element due to corrupted attributes on <$text>');
       return;
    }
    if (!validator.allowsElement(element)) {
      _removeNode(element, parent);
      window.console.warn(
          'Removing disallowed element <$tag> from $parent');
      return;
    }

    if (isAttr != null) {
      if (!validator.allowsAttribute(element, 'is', isAttr)) {
        _removeNode(element, parent);
        window.console.warn('Removing disallowed type extension '
            '<$tag is="$isAttr">');
        return;
      }
    }

    // TODO(blois): Need to be able to get all attributes, irrespective of
    // XMLNS.
    var keys = attrs.keys.toList();
    for (var i = attrs.length - 1; i >= 0; --i) {
      var name = keys[i];
      if (!validator.allowsAttribute(element, name.toLowerCase(),
          attrs[name])) {
        window.console.warn('Removing disallowed attribute '
            '<$tag $name="${attrs[name]}">');
        attrs.remove(name);
      }
    }

    if (element is TemplateElement) {
      TemplateElement template = element;
      sanitizeTree(template.content);
     }
  }

  /// Sanitize the node and its children recursively.
  void sanitizeNode(Node node, Node parent) {
    switch (node.nodeType) {
      case Node.ELEMENT_NODE:
        _sanitizeUntrustedElement(node, parent);
        break;
      case Node.COMMENT_NODE:
      case Node.DOCUMENT_FRAGMENT_NODE:
      case Node.TEXT_NODE:
      case Node.CDATA_SECTION_NODE:
        break;
      default:
        _removeNode(node, parent);
    }
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// DO NOT EDIT - unless you are editing documentation as per:
// https://code.google.com/p/dart/wiki/ContributingHTMLDocumentation
// Auto-generated dart:html library.


import 'dart:_js_helper' show
    convertDartClosureToJS, Creates, JavaScriptIndexingBehavior,
    JSName, Native, Returns, ForceInline,
    findDispatchTagForInterceptorClass, setNativeSubclassDispatchRecord,
    makeLeafDispatchRecord;
import 'dart:_interceptors' show
    Interceptor, JSExtendableArray, JSUInt31,
    findInterceptorConstructorForType,
    findConstructorForNativeSubclassType,
    getNativeInterceptor,
    setDispatchProperty;

export 'dart:math' show Rectangle, Point;



//part '../../../dom/src/dart2js_CustomElementSupport.dart';


/**
 * Top-level container for a web page, which is usually a browser tab or window.
 *
 * Each web page loaded in the browser has its own [Window], which is a
 * container for the web page.
 *
 * If the web page has any `<iframe>` elements, then each `<iframe>` has its own
 * [Window] object, which is accessible only to that `<iframe>`.
 *
 * See also:
 *
 *   * [Window](https://developer.mozilla.org/en-US/docs/Web/API/window) from MDN.
 */

final Window window = wrap_jso(JS('', '$global_'));

/**
 * Root node for all content in a web page.
 */
HtmlDocument get document => wrap_jso(JS('HtmlDocument', 'document'));

// Workaround for tags like <cite> that lack their own Element subclass --
// Dart issue 1990.
@Native("HTMLElement")
class HtmlElement extends Element {
  factory HtmlElement() { throw new UnsupportedError("Not supported"); }

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  HtmlElement.created() : super.created();
  HtmlElement.internal_() : super.internal_();

  static HtmlElement internalCreateHtmlElement() {
    return new HtmlElement._internalWrap();
  }

  factory HtmlElement._internalWrap() {
    return new HtmlElement.internal_();
  }
}

// EntryArray type was removed, so explicitly adding it to allow support for
// older Chrome versions.
// Issue #12573.
@Native("EntryArray")
abstract class _EntryArray implements List<Entry> {}

/**
 * Spawn a DOM isolate using the given URI in the same window.
 * This isolate is not concurrent.  It runs on the browser thread
 * with full access to the DOM.
 * Note: this API is still evolving and may move to dart:isolate.
 */
@Experimental()
Future<Isolate> spawnDomUri(Uri uri, List<String> args, message) {
  // TODO(17738): Implement this.
  throw new UnimplementedError();
}


class DartHtmlDomObject {
  // FIXME(vsm): Make this final at least.  Private?
  dynamic raw;

  DartHtmlDomObject();
  DartHtmlDomObject.internal_();
}

typedef _F1(x);

final _wrapper = JS('', 'Symbol("dart_wrapper")');

/// Dartium functions that are a NOOP in dart2js.
unwrap_jso(wrapped) {
  if (wrapped is DartHtmlDomObject) {
    return wrapped.raw;
  }
  if (wrapped is _F1) {
    if (JS('bool', '#.hasOwnProperty(#)', wrapped, _wrapper)) {
      return JS('', '#[#]', wrapped, _wrapper);
    }
    var f = (e) => wrapped(wrap_jso(e));
    JS('', '#[#] = #', wrapped, _wrapper, f);
    return f;
  }
  return wrapped;
}


wrap_jso(jso) {
  if (jso == null || jso is bool || jso is num || jso is String) {
    return jso;
  }
  if (JS('bool', '#.hasOwnProperty(#)', jso, _wrapper)) {
     return JS('', '#[#]', jso, _wrapper);
  }
  var constructor = JS('', '#.constructor', jso)
  var f = null;
  String name;
  String skip = null;
  while (f == null) {
    name = JS('String', '#.name', constructor);
    f = getHtmlCreateFunction(name);
    if (f == null) {
      if (skip == null) {
        skip = name;
      }
      constructor = JS('', '#.__proto__', constructor);
    }
  }
  if (skip != null) {
    console.warn('Instantiated $name instead of $skip');
  }
  var wrapped = f();
  wrapped.raw = jso;
  JS('', '#[#] = #', jso, _wrapper, wrapped);
  return wrapped;
}

createCustomUpgrader(Type customElementClass, $this) => $this;

// FIXME: Can we make this private?
final htmlBlinkMap = {
  '_HistoryCrossFrame': () => _HistoryCrossFrame,
  '_LocationCrossFrame': () => _LocationCrossFrame,
  '_DOMWindowCrossFrame': () => _DOMWindowCrossFrame,
  // FIXME: Move these to better locations.
  'DateTime': () => DateTime,
  'JsObject': () => js.JsObjectImpl,
  'JsFunction': () => js.JsFunctionImpl,
  'JsArray': () => js.JsArrayImpl,
  'Attr': () => _Attr,
  'CSSStyleDeclaration': () => CssStyleDeclaration,
  'CharacterData': () => CharacterData,
  'ChildNode': () => ChildNode,
  'ClientRect': () => _ClientRect,
  'Comment': () => Comment,
  'Console': () => Console,
  'ConsoleBase': () => ConsoleBase,
  'CustomEvent': () => CustomEvent,
  'DOMImplementation': () => DomImplementation,
  'DOMTokenList': () => DomTokenList,
  'Document': () => Document,
  'DocumentFragment': () => DocumentFragment,
  'Element': () => Element,
  'Event': () => Event,
  'EventTarget': () => EventTarget,
  'HTMLAnchorElement': () => AnchorElement,
  'HTMLBaseElement': () => BaseElement,
  'HTMLBodyElement': () => BodyElement,
  'HTMLCollection': () => HtmlCollection,
  'HTMLDivElement': () => DivElement,
  'HTMLDocument': () => HtmlDocument,
  'HTMLElement': () => HtmlElement,
  'HTMLHeadElement': () => HeadElement,
  'HTMLHtmlElement': () => HtmlHtmlElement,
  'HTMLInputElement': () => InputElement,
  'HTMLStyleElement': () => StyleElement,
  'HTMLTemplateElement': () => TemplateElement,
  'History': () => History,
  'KeyboardEvent': () => KeyboardEvent,
  'Location': () => Location,
  'MouseEvent': () => MouseEvent,
  'NamedNodeMap': () => _NamedNodeMap,
  'Navigator': () => Navigator,
  'NavigatorCPU': () => NavigatorCpu,
  'Node': () => Node,
  'NodeList': () => NodeList,
  'ParentNode': () => ParentNode,
  'ProgressEvent': () => ProgressEvent,
  'Range': () => Range,
  'Screen': () => Screen,
  'ShadowRoot': () => ShadowRoot,
  'Text': () => Text,
  'UIEvent': () => UIEvent,
  'URLUtils': () => UrlUtils,
  'Window': () => Window,
  'XMLHttpRequest': () => HttpRequest,
  'XMLHttpRequestEventTarget': () => HttpRequestEventTarget,
  'XMLHttpRequestProgressEvent': () => _XMLHttpRequestProgressEvent,

};

// FIXME: Can we make this private?
final htmlBlinkFunctionMap = {
  'Attr': () => _Attr.internalCreate_Attr,
  'CSSStyleDeclaration': () => CssStyleDeclaration.internalCreateCssStyleDeclaration,
  'CharacterData': () => CharacterData.internalCreateCharacterData,
  'ClientRect': () => _ClientRect.internalCreate_ClientRect,
  'Comment': () => Comment.internalCreateComment,
  'Console': () => Console.internalCreateConsole,
  'ConsoleBase': () => ConsoleBase.internalCreateConsoleBase,
  'CustomEvent': () => CustomEvent.internalCreateCustomEvent,
  'DOMImplementation': () => DomImplementation.internalCreateDomImplementation,
  'DOMTokenList': () => DomTokenList.internalCreateDomTokenList,
  'Document': () => Document.internalCreateDocument,
  'DocumentFragment': () => DocumentFragment.internalCreateDocumentFragment,
  'Element': () => Element.internalCreateElement,
  'Event': () => Event.internalCreateEvent,
  'EventTarget': () => EventTarget.internalCreateEventTarget,
  'HTMLAnchorElement': () => AnchorElement.internalCreateAnchorElement,
  'HTMLBaseElement': () => BaseElement.internalCreateBaseElement,
  'HTMLBodyElement': () => BodyElement.internalCreateBodyElement,
  'HTMLCollection': () => HtmlCollection.internalCreateHtmlCollection,
  'HTMLDivElement': () => DivElement.internalCreateDivElement,
  'HTMLDocument': () => HtmlDocument.internalCreateHtmlDocument,
  'HTMLElement': () => HtmlElement.internalCreateHtmlElement,
  'HTMLHeadElement': () => HeadElement.internalCreateHeadElement,
  'HTMLHtmlElement': () => HtmlHtmlElement.internalCreateHtmlHtmlElement,
  'HTMLInputElement': () => InputElement.internalCreateInputElement,
  'HTMLStyleElement': () => StyleElement.internalCreateStyleElement,
  'HTMLTemplateElement': () => TemplateElement.internalCreateTemplateElement,
  'History': () => History.internalCreateHistory,
  'KeyboardEvent': () => KeyboardEvent.internalCreateKeyboardEvent,
  'Location': () => Location.internalCreateLocation,
  'MouseEvent': () => MouseEvent.internalCreateMouseEvent,
  'NamedNodeMap': () => _NamedNodeMap.internalCreate_NamedNodeMap,
  'Navigator': () => Navigator.internalCreateNavigator,
  'Node': () => Node.internalCreateNode,
  'NodeList': () => NodeList.internalCreateNodeList,
  'ProgressEvent': () => ProgressEvent.internalCreateProgressEvent,
  'Range': () => Range.internalCreateRange,
  'Screen': () => Screen.internalCreateScreen,
  'ShadowRoot': () => ShadowRoot.internalCreateShadowRoot,
  'Text': () => Text.internalCreateText,
  'UIEvent': () => UIEvent.internalCreateUIEvent,
  'Window': () => Window.internalCreateWindow,
  'XMLHttpRequest': () => HttpRequest.internalCreateHttpRequest,
  'XMLHttpRequestEventTarget': () => HttpRequestEventTarget.internalCreateHttpRequestEventTarget,
  'XMLHttpRequestProgressEvent': () => _XMLHttpRequestProgressEvent.internalCreate_XMLHttpRequestProgressEvent,

};

// TODO(terry): We may want to move this elsewhere if html becomes
// a package to avoid dartium depending on pkg:html.
getHtmlCreateFunction(String key) {
  var result;

  // TODO(vsm): Add Cross Frame and JS types here as well.

  // Check the html library.
  result = _getHtmlFunction(key);
  if (result != null) {
    return result;
  }
  return null;
}

Function _getHtmlFunction(String key) {
  if (htmlBlinkFunctionMap.containsKey(key)) {
    return htmlBlinkFunctionMap[key]();
  }
  return null;
}
