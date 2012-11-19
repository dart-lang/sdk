library svg;

import 'dart:html';
// DO NOT EDIT
// Auto-generated dart:svg library.





// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


final _START_TAG_REGEXP = new RegExp('<(\\w+)');

class _SvgElementFactoryProvider {
  static SvgElement createSvgElement_tag(String tag) {
    final Element temp =
      document.$dom_createElementNS("http://www.w3.org/2000/svg", tag);
    return temp;
  }

  static SvgElement createSvgElement_svg(String svg) {
    Element parentTag;
    final match = _START_TAG_REGEXP.firstMatch(svg);
    if (match != null && match.group(1).toLowerCase() == 'svg') {
      parentTag = new Element.tag('div');
    } else {
      parentTag = new SvgSvgElement();
    }

    parentTag.innerHTML = svg;
    if (parentTag.elements.length == 1) return parentTag.elements.removeLast();

    throw new ArgumentError(
        'SVG had ${parentTag.elements.length} '
        'top-level elements but 1 expected');
  }
}

class _SvgSvgElementFactoryProvider {
  static SvgSvgElement createSvgSvgElement() {
    final el = new SvgElement.tag("svg");
    // The SVG spec requires the version attribute to match the spec version
    el.attributes['version'] = "1.1";
    return el;
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAElement
class AElement extends SvgElement implements Transformable, Tests, UriReference, Stylable, ExternalResourcesRequired, LangSpace native "*SVGAElement" {

  factory AElement() => _SvgElementFactoryProvider.createSvgElement_tag("a");

  /** @domName SVGAElement.target */
  final AnimatedString target;

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGLocatable

  /** @domName SVGLocatable.farthestViewportElement */
  final SvgElement farthestViewportElement;

  /** @domName SVGLocatable.nearestViewportElement */
  final SvgElement nearestViewportElement;

  /** @domName SVGLocatable.getBBox */
  Rect getBBox() native;

  /** @domName SVGLocatable.getCTM */
  Matrix getCTM() native;

  /** @domName SVGLocatable.getScreenCTM */
  Matrix getScreenCTM() native;

  /** @domName SVGLocatable.getTransformToElement */
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  /** @domName SVGStylable.className */
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /** @domName SVGTests.requiredExtensions */
  final StringList requiredExtensions;

  /** @domName SVGTests.requiredFeatures */
  final StringList requiredFeatures;

  /** @domName SVGTests.systemLanguage */
  final StringList systemLanguage;

  /** @domName SVGTests.hasExtension */
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /** @domName SVGTransformable.transform */
  final AnimatedTransformList transform;

  // From SVGURIReference

  /** @domName SVGURIReference.href */
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAltGlyphDefElement
class AltGlyphDefElement extends SvgElement native "*SVGAltGlyphDefElement" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAltGlyphElement
class AltGlyphElement extends TextPositioningElement implements UriReference native "*SVGAltGlyphElement" {

  /** @domName SVGAltGlyphElement.format */
  String format;

  /** @domName SVGAltGlyphElement.glyphRef */
  String glyphRef;

  // From SVGURIReference

  /** @domName SVGURIReference.href */
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAltGlyphItemElement
class AltGlyphItemElement extends SvgElement native "*SVGAltGlyphItemElement" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAngle
class Angle native "*SVGAngle" {

  static const int SVG_ANGLETYPE_DEG = 2;

  static const int SVG_ANGLETYPE_GRAD = 4;

  static const int SVG_ANGLETYPE_RAD = 3;

  static const int SVG_ANGLETYPE_UNKNOWN = 0;

  static const int SVG_ANGLETYPE_UNSPECIFIED = 1;

  /** @domName SVGAngle.unitType */
  final int unitType;

  /** @domName SVGAngle.value */
  num value;

  /** @domName SVGAngle.valueAsString */
  String valueAsString;

  /** @domName SVGAngle.valueInSpecifiedUnits */
  num valueInSpecifiedUnits;

  /** @domName SVGAngle.convertToSpecifiedUnits */
  void convertToSpecifiedUnits(int unitType) native;

  /** @domName SVGAngle.newValueSpecifiedUnits */
  void newValueSpecifiedUnits(int unitType, num valueInSpecifiedUnits) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAnimateColorElement
class AnimateColorElement extends AnimationElement native "*SVGAnimateColorElement" {

  factory AnimateColorElement() => _SvgElementFactoryProvider.createSvgElement_tag("animateColor");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAnimateElement
class AnimateElement extends AnimationElement native "*SVGAnimateElement" {

  factory AnimateElement() => _SvgElementFactoryProvider.createSvgElement_tag("animate");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAnimateMotionElement
class AnimateMotionElement extends AnimationElement native "*SVGAnimateMotionElement" {

  factory AnimateMotionElement() => _SvgElementFactoryProvider.createSvgElement_tag("animateMotion");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAnimateTransformElement
class AnimateTransformElement extends AnimationElement native "*SVGAnimateTransformElement" {

  factory AnimateTransformElement() => _SvgElementFactoryProvider.createSvgElement_tag("animateTransform");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAnimatedAngle
class AnimatedAngle native "*SVGAnimatedAngle" {

  /** @domName SVGAnimatedAngle.animVal */
  final Angle animVal;

  /** @domName SVGAnimatedAngle.baseVal */
  final Angle baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAnimatedBoolean
class AnimatedBoolean native "*SVGAnimatedBoolean" {

  /** @domName SVGAnimatedBoolean.animVal */
  final bool animVal;

  /** @domName SVGAnimatedBoolean.baseVal */
  bool baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAnimatedEnumeration
class AnimatedEnumeration native "*SVGAnimatedEnumeration" {

  /** @domName SVGAnimatedEnumeration.animVal */
  final int animVal;

  /** @domName SVGAnimatedEnumeration.baseVal */
  int baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAnimatedInteger
class AnimatedInteger native "*SVGAnimatedInteger" {

  /** @domName SVGAnimatedInteger.animVal */
  final int animVal;

  /** @domName SVGAnimatedInteger.baseVal */
  int baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAnimatedLength
class AnimatedLength native "*SVGAnimatedLength" {

  /** @domName SVGAnimatedLength.animVal */
  final Length animVal;

  /** @domName SVGAnimatedLength.baseVal */
  final Length baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAnimatedLengthList
class AnimatedLengthList implements JavaScriptIndexingBehavior, List<AnimatedLength> native "*SVGAnimatedLengthList" {

  /** @domName SVGAnimatedLengthList.animVal */
  final LengthList animVal;

  /** @domName SVGAnimatedLengthList.baseVal */
  final LengthList baseVal;

  AnimatedLength operator[](int index) => JS("AnimatedLength", "#[#]", this, index);

  void operator[]=(int index, AnimatedLength value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<AnimatedLength> mixins.
  // AnimatedLength is the element type.

  // From Iterable<AnimatedLength>:

  Iterator<AnimatedLength> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<AnimatedLength>(this);
  }

  // From Collection<AnimatedLength>:

  void add(AnimatedLength value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(AnimatedLength value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<AnimatedLength> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(AnimatedLength element) => _Collections.contains(this, element);

  void forEach(void f(AnimatedLength element)) => _Collections.forEach(this, f);

  Collection map(f(AnimatedLength element)) => _Collections.map(this, [], f);

  Collection<AnimatedLength> filter(bool f(AnimatedLength element)) =>
     _Collections.filter(this, <AnimatedLength>[], f);

  bool every(bool f(AnimatedLength element)) => _Collections.every(this, f);

  bool some(bool f(AnimatedLength element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<AnimatedLength>:

  void sort([Comparator<AnimatedLength> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(AnimatedLength element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(AnimatedLength element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  AnimatedLength get first => this[0];

  AnimatedLength get last => this[length - 1];

  AnimatedLength removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<AnimatedLength> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [AnimatedLength initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<AnimatedLength> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <AnimatedLength>[]);

  // -- end List<AnimatedLength> mixins.
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAnimatedNumber
class AnimatedNumber native "*SVGAnimatedNumber" {

  /** @domName SVGAnimatedNumber.animVal */
  final num animVal;

  /** @domName SVGAnimatedNumber.baseVal */
  num baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAnimatedNumberList
class AnimatedNumberList implements JavaScriptIndexingBehavior, List<AnimatedNumber> native "*SVGAnimatedNumberList" {

  /** @domName SVGAnimatedNumberList.animVal */
  final NumberList animVal;

  /** @domName SVGAnimatedNumberList.baseVal */
  final NumberList baseVal;

  AnimatedNumber operator[](int index) => JS("AnimatedNumber", "#[#]", this, index);

  void operator[]=(int index, AnimatedNumber value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<AnimatedNumber> mixins.
  // AnimatedNumber is the element type.

  // From Iterable<AnimatedNumber>:

  Iterator<AnimatedNumber> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<AnimatedNumber>(this);
  }

  // From Collection<AnimatedNumber>:

  void add(AnimatedNumber value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(AnimatedNumber value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<AnimatedNumber> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(AnimatedNumber element) => _Collections.contains(this, element);

  void forEach(void f(AnimatedNumber element)) => _Collections.forEach(this, f);

  Collection map(f(AnimatedNumber element)) => _Collections.map(this, [], f);

  Collection<AnimatedNumber> filter(bool f(AnimatedNumber element)) =>
     _Collections.filter(this, <AnimatedNumber>[], f);

  bool every(bool f(AnimatedNumber element)) => _Collections.every(this, f);

  bool some(bool f(AnimatedNumber element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<AnimatedNumber>:

  void sort([Comparator<AnimatedNumber> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(AnimatedNumber element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(AnimatedNumber element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  AnimatedNumber get first => this[0];

  AnimatedNumber get last => this[length - 1];

  AnimatedNumber removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<AnimatedNumber> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [AnimatedNumber initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<AnimatedNumber> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <AnimatedNumber>[]);

  // -- end List<AnimatedNumber> mixins.
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAnimatedPreserveAspectRatio
class AnimatedPreserveAspectRatio native "*SVGAnimatedPreserveAspectRatio" {

  /** @domName SVGAnimatedPreserveAspectRatio.animVal */
  final PreserveAspectRatio animVal;

  /** @domName SVGAnimatedPreserveAspectRatio.baseVal */
  final PreserveAspectRatio baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAnimatedRect
class AnimatedRect native "*SVGAnimatedRect" {

  /** @domName SVGAnimatedRect.animVal */
  final Rect animVal;

  /** @domName SVGAnimatedRect.baseVal */
  final Rect baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAnimatedString
class AnimatedString native "*SVGAnimatedString" {

  /** @domName SVGAnimatedString.animVal */
  final String animVal;

  /** @domName SVGAnimatedString.baseVal */
  String baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAnimatedTransformList
class AnimatedTransformList implements JavaScriptIndexingBehavior, List<AnimateTransformElement> native "*SVGAnimatedTransformList" {

  /** @domName SVGAnimatedTransformList.animVal */
  final TransformList animVal;

  /** @domName SVGAnimatedTransformList.baseVal */
  final TransformList baseVal;

  AnimateTransformElement operator[](int index) => JS("AnimateTransformElement", "#[#]", this, index);

  void operator[]=(int index, AnimateTransformElement value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<AnimateTransformElement> mixins.
  // AnimateTransformElement is the element type.

  // From Iterable<AnimateTransformElement>:

  Iterator<AnimateTransformElement> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<AnimateTransformElement>(this);
  }

  // From Collection<AnimateTransformElement>:

  void add(AnimateTransformElement value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(AnimateTransformElement value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<AnimateTransformElement> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(AnimateTransformElement element) => _Collections.contains(this, element);

  void forEach(void f(AnimateTransformElement element)) => _Collections.forEach(this, f);

  Collection map(f(AnimateTransformElement element)) => _Collections.map(this, [], f);

  Collection<AnimateTransformElement> filter(bool f(AnimateTransformElement element)) =>
     _Collections.filter(this, <AnimateTransformElement>[], f);

  bool every(bool f(AnimateTransformElement element)) => _Collections.every(this, f);

  bool some(bool f(AnimateTransformElement element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<AnimateTransformElement>:

  void sort([Comparator<AnimateTransformElement> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(AnimateTransformElement element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(AnimateTransformElement element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  AnimateTransformElement get first => this[0];

  AnimateTransformElement get last => this[length - 1];

  AnimateTransformElement removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<AnimateTransformElement> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [AnimateTransformElement initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<AnimateTransformElement> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <AnimateTransformElement>[]);

  // -- end List<AnimateTransformElement> mixins.
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAnimationElement
class AnimationElement extends SvgElement implements Tests, ElementTimeControl, ExternalResourcesRequired native "*SVGAnimationElement" {

  factory AnimationElement() => _SvgElementFactoryProvider.createSvgElement_tag("animation");

  /** @domName SVGAnimationElement.targetElement */
  final SvgElement targetElement;

  /** @domName SVGAnimationElement.getCurrentTime */
  num getCurrentTime() native;

  /** @domName SVGAnimationElement.getSimpleDuration */
  num getSimpleDuration() native;

  /** @domName SVGAnimationElement.getStartTime */
  num getStartTime() native;

  // From ElementTimeControl

  /** @domName ElementTimeControl.beginElement */
  void beginElement() native;

  /** @domName ElementTimeControl.beginElementAt */
  void beginElementAt(num offset) native;

  /** @domName ElementTimeControl.endElement */
  void endElement() native;

  /** @domName ElementTimeControl.endElementAt */
  void endElementAt(num offset) native;

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final AnimatedBoolean externalResourcesRequired;

  // From SVGTests

  /** @domName SVGTests.requiredExtensions */
  final StringList requiredExtensions;

  /** @domName SVGTests.requiredFeatures */
  final StringList requiredFeatures;

  /** @domName SVGTests.systemLanguage */
  final StringList systemLanguage;

  /** @domName SVGTests.hasExtension */
  bool hasExtension(String extension) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGCircleElement
class CircleElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGCircleElement" {

  factory CircleElement() => _SvgElementFactoryProvider.createSvgElement_tag("circle");

  /** @domName SVGCircleElement.cx */
  final AnimatedLength cx;

  /** @domName SVGCircleElement.cy */
  final AnimatedLength cy;

  /** @domName SVGCircleElement.r */
  final AnimatedLength r;

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGLocatable

  /** @domName SVGLocatable.farthestViewportElement */
  final SvgElement farthestViewportElement;

  /** @domName SVGLocatable.nearestViewportElement */
  final SvgElement nearestViewportElement;

  /** @domName SVGLocatable.getBBox */
  Rect getBBox() native;

  /** @domName SVGLocatable.getCTM */
  Matrix getCTM() native;

  /** @domName SVGLocatable.getScreenCTM */
  Matrix getScreenCTM() native;

  /** @domName SVGLocatable.getTransformToElement */
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  /** @domName SVGStylable.className */
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /** @domName SVGTests.requiredExtensions */
  final StringList requiredExtensions;

  /** @domName SVGTests.requiredFeatures */
  final StringList requiredFeatures;

  /** @domName SVGTests.systemLanguage */
  final StringList systemLanguage;

  /** @domName SVGTests.hasExtension */
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /** @domName SVGTransformable.transform */
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGClipPathElement
class ClipPathElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGClipPathElement" {

  factory ClipPathElement() => _SvgElementFactoryProvider.createSvgElement_tag("clipPath");

  /** @domName SVGClipPathElement.clipPathUnits */
  final AnimatedEnumeration clipPathUnits;

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGLocatable

  /** @domName SVGLocatable.farthestViewportElement */
  final SvgElement farthestViewportElement;

  /** @domName SVGLocatable.nearestViewportElement */
  final SvgElement nearestViewportElement;

  /** @domName SVGLocatable.getBBox */
  Rect getBBox() native;

  /** @domName SVGLocatable.getCTM */
  Matrix getCTM() native;

  /** @domName SVGLocatable.getScreenCTM */
  Matrix getScreenCTM() native;

  /** @domName SVGLocatable.getTransformToElement */
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  /** @domName SVGStylable.className */
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /** @domName SVGTests.requiredExtensions */
  final StringList requiredExtensions;

  /** @domName SVGTests.requiredFeatures */
  final StringList requiredFeatures;

  /** @domName SVGTests.systemLanguage */
  final StringList systemLanguage;

  /** @domName SVGTests.hasExtension */
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /** @domName SVGTransformable.transform */
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGColor
class Color extends CSSValue native "*SVGColor" {

  static const int SVG_COLORTYPE_CURRENTCOLOR = 3;

  static const int SVG_COLORTYPE_RGBCOLOR = 1;

  static const int SVG_COLORTYPE_RGBCOLOR_ICCCOLOR = 2;

  static const int SVG_COLORTYPE_UNKNOWN = 0;

  /** @domName SVGColor.colorType */
  final int colorType;

  /** @domName SVGColor.rgbColor */
  final RGBColor rgbColor;

  /** @domName SVGColor.setColor */
  void setColor(int colorType, String rgbColor, String iccColor) native;

  /** @domName SVGColor.setRGBColor */
  void setRGBColor(String rgbColor) native;

  /** @domName SVGColor.setRGBColorICCColor */
  void setRGBColorICCColor(String rgbColor, String iccColor) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGComponentTransferFunctionElement
class ComponentTransferFunctionElement extends SvgElement native "*SVGComponentTransferFunctionElement" {

  static const int SVG_FECOMPONENTTRANSFER_TYPE_DISCRETE = 3;

  static const int SVG_FECOMPONENTTRANSFER_TYPE_GAMMA = 5;

  static const int SVG_FECOMPONENTTRANSFER_TYPE_IDENTITY = 1;

  static const int SVG_FECOMPONENTTRANSFER_TYPE_LINEAR = 4;

  static const int SVG_FECOMPONENTTRANSFER_TYPE_TABLE = 2;

  static const int SVG_FECOMPONENTTRANSFER_TYPE_UNKNOWN = 0;

  /** @domName SVGComponentTransferFunctionElement.amplitude */
  final AnimatedNumber amplitude;

  /** @domName SVGComponentTransferFunctionElement.exponent */
  final AnimatedNumber exponent;

  /** @domName SVGComponentTransferFunctionElement.intercept */
  final AnimatedNumber intercept;

  /** @domName SVGComponentTransferFunctionElement.offset */
  final AnimatedNumber offset;

  /** @domName SVGComponentTransferFunctionElement.slope */
  final AnimatedNumber slope;

  /** @domName SVGComponentTransferFunctionElement.tableValues */
  final AnimatedNumberList tableValues;

  /** @domName SVGComponentTransferFunctionElement.type */
  final AnimatedEnumeration type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGCursorElement
class CursorElement extends SvgElement implements UriReference, Tests, ExternalResourcesRequired native "*SVGCursorElement" {

  factory CursorElement() => _SvgElementFactoryProvider.createSvgElement_tag("cursor");

  /** @domName SVGCursorElement.x */
  final AnimatedLength x;

  /** @domName SVGCursorElement.y */
  final AnimatedLength y;

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final AnimatedBoolean externalResourcesRequired;

  // From SVGTests

  /** @domName SVGTests.requiredExtensions */
  final StringList requiredExtensions;

  /** @domName SVGTests.requiredFeatures */
  final StringList requiredFeatures;

  /** @domName SVGTests.systemLanguage */
  final StringList systemLanguage;

  /** @domName SVGTests.hasExtension */
  bool hasExtension(String extension) native;

  // From SVGURIReference

  /** @domName SVGURIReference.href */
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGDefsElement
class DefsElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGDefsElement" {

  factory DefsElement() => _SvgElementFactoryProvider.createSvgElement_tag("defs");

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGLocatable

  /** @domName SVGLocatable.farthestViewportElement */
  final SvgElement farthestViewportElement;

  /** @domName SVGLocatable.nearestViewportElement */
  final SvgElement nearestViewportElement;

  /** @domName SVGLocatable.getBBox */
  Rect getBBox() native;

  /** @domName SVGLocatable.getCTM */
  Matrix getCTM() native;

  /** @domName SVGLocatable.getScreenCTM */
  Matrix getScreenCTM() native;

  /** @domName SVGLocatable.getTransformToElement */
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  /** @domName SVGStylable.className */
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /** @domName SVGTests.requiredExtensions */
  final StringList requiredExtensions;

  /** @domName SVGTests.requiredFeatures */
  final StringList requiredFeatures;

  /** @domName SVGTests.systemLanguage */
  final StringList systemLanguage;

  /** @domName SVGTests.hasExtension */
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /** @domName SVGTransformable.transform */
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGDescElement
class DescElement extends SvgElement implements Stylable, LangSpace native "*SVGDescElement" {

  factory DescElement() => _SvgElementFactoryProvider.createSvgElement_tag("desc");

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGStylable

  /** @domName SVGStylable.className */
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGElementInstance
class ElementInstance extends EventTarget native "*SVGElementInstance" {

  /**
   * @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent
   */
  ElementInstanceEvents get on =>
    new ElementInstanceEvents(this);

  /** @domName SVGElementInstance.childNodes */
  final List<ElementInstance> childNodes;

  /** @domName SVGElementInstance.correspondingElement */
  final SvgElement correspondingElement;

  /** @domName SVGElementInstance.correspondingUseElement */
  final UseElement correspondingUseElement;

  /** @domName SVGElementInstance.firstChild */
  final ElementInstance firstChild;

  /** @domName SVGElementInstance.lastChild */
  final ElementInstance lastChild;

  /** @domName SVGElementInstance.nextSibling */
  final ElementInstance nextSibling;

  /** @domName SVGElementInstance.parentNode */
  final ElementInstance parentNode;

  /** @domName SVGElementInstance.previousSibling */
  final ElementInstance previousSibling;
}

class ElementInstanceEvents extends Events {
  ElementInstanceEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get abort => this['abort'];

  EventListenerList get beforeCopy => this['beforecopy'];

  EventListenerList get beforeCut => this['beforecut'];

  EventListenerList get beforePaste => this['beforepaste'];

  EventListenerList get blur => this['blur'];

  EventListenerList get change => this['change'];

  EventListenerList get click => this['click'];

  EventListenerList get contextMenu => this['contextmenu'];

  EventListenerList get copy => this['copy'];

  EventListenerList get cut => this['cut'];

  EventListenerList get doubleClick => this['dblclick'];

  EventListenerList get drag => this['drag'];

  EventListenerList get dragEnd => this['dragend'];

  EventListenerList get dragEnter => this['dragenter'];

  EventListenerList get dragLeave => this['dragleave'];

  EventListenerList get dragOver => this['dragover'];

  EventListenerList get dragStart => this['dragstart'];

  EventListenerList get drop => this['drop'];

  EventListenerList get error => this['error'];

  EventListenerList get focus => this['focus'];

  EventListenerList get input => this['input'];

  EventListenerList get keyDown => this['keydown'];

  EventListenerList get keyPress => this['keypress'];

  EventListenerList get keyUp => this['keyup'];

  EventListenerList get load => this['load'];

  EventListenerList get mouseDown => this['mousedown'];

  EventListenerList get mouseMove => this['mousemove'];

  EventListenerList get mouseOut => this['mouseout'];

  EventListenerList get mouseOver => this['mouseover'];

  EventListenerList get mouseUp => this['mouseup'];

  EventListenerList get mouseWheel => this['mousewheel'];

  EventListenerList get paste => this['paste'];

  EventListenerList get reset => this['reset'];

  EventListenerList get resize => this['resize'];

  EventListenerList get scroll => this['scroll'];

  EventListenerList get search => this['search'];

  EventListenerList get select => this['select'];

  EventListenerList get selectStart => this['selectstart'];

  EventListenerList get submit => this['submit'];

  EventListenerList get unload => this['unload'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGEllipseElement
class EllipseElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGEllipseElement" {

  factory EllipseElement() => _SvgElementFactoryProvider.createSvgElement_tag("ellipse");

  /** @domName SVGEllipseElement.cx */
  final AnimatedLength cx;

  /** @domName SVGEllipseElement.cy */
  final AnimatedLength cy;

  /** @domName SVGEllipseElement.rx */
  final AnimatedLength rx;

  /** @domName SVGEllipseElement.ry */
  final AnimatedLength ry;

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGLocatable

  /** @domName SVGLocatable.farthestViewportElement */
  final SvgElement farthestViewportElement;

  /** @domName SVGLocatable.nearestViewportElement */
  final SvgElement nearestViewportElement;

  /** @domName SVGLocatable.getBBox */
  Rect getBBox() native;

  /** @domName SVGLocatable.getCTM */
  Matrix getCTM() native;

  /** @domName SVGLocatable.getScreenCTM */
  Matrix getScreenCTM() native;

  /** @domName SVGLocatable.getTransformToElement */
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  /** @domName SVGStylable.className */
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /** @domName SVGTests.requiredExtensions */
  final StringList requiredExtensions;

  /** @domName SVGTests.requiredFeatures */
  final StringList requiredFeatures;

  /** @domName SVGTests.systemLanguage */
  final StringList systemLanguage;

  /** @domName SVGTests.hasExtension */
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /** @domName SVGTransformable.transform */
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGException
class Exception native "*SVGException" {

  static const int SVG_INVALID_VALUE_ERR = 1;

  static const int SVG_MATRIX_NOT_INVERTABLE = 2;

  static const int SVG_WRONG_TYPE_ERR = 0;

  /** @domName SVGException.code */
  final int code;

  /** @domName SVGException.message */
  final String message;

  /** @domName SVGException.name */
  final String name;

  /** @domName SVGException.toString */
  String toString() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGExternalResourcesRequired
abstract class ExternalResourcesRequired {

  AnimatedBoolean externalResourcesRequired;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEBlendElement
class FEBlendElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEBlendElement" {

  static const int SVG_FEBLEND_MODE_DARKEN = 4;

  static const int SVG_FEBLEND_MODE_LIGHTEN = 5;

  static const int SVG_FEBLEND_MODE_MULTIPLY = 2;

  static const int SVG_FEBLEND_MODE_NORMAL = 1;

  static const int SVG_FEBLEND_MODE_SCREEN = 3;

  static const int SVG_FEBLEND_MODE_UNKNOWN = 0;

  /** @domName SVGFEBlendElement.in1 */
  final AnimatedString in1;

  /** @domName SVGFEBlendElement.in2 */
  final AnimatedString in2;

  /** @domName SVGFEBlendElement.mode */
  final AnimatedEnumeration mode;

  // From SVGFilterPrimitiveStandardAttributes

  /** @domName SVGFilterPrimitiveStandardAttributes.height */
  final AnimatedLength height;

  /** @domName SVGFilterPrimitiveStandardAttributes.result */
  final AnimatedString result;

  /** @domName SVGFilterPrimitiveStandardAttributes.width */
  final AnimatedLength width;

  /** @domName SVGFilterPrimitiveStandardAttributes.x */
  final AnimatedLength x;

  /** @domName SVGFilterPrimitiveStandardAttributes.y */
  final AnimatedLength y;

  // From SVGStylable

  /** @domName SVGStylable.className */
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEColorMatrixElement
class FEColorMatrixElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEColorMatrixElement" {

  static const int SVG_FECOLORMATRIX_TYPE_HUEROTATE = 3;

  static const int SVG_FECOLORMATRIX_TYPE_LUMINANCETOALPHA = 4;

  static const int SVG_FECOLORMATRIX_TYPE_MATRIX = 1;

  static const int SVG_FECOLORMATRIX_TYPE_SATURATE = 2;

  static const int SVG_FECOLORMATRIX_TYPE_UNKNOWN = 0;

  /** @domName SVGFEColorMatrixElement.in1 */
  final AnimatedString in1;

  /** @domName SVGFEColorMatrixElement.type */
  final AnimatedEnumeration type;

  /** @domName SVGFEColorMatrixElement.values */
  final AnimatedNumberList values;

  // From SVGFilterPrimitiveStandardAttributes

  /** @domName SVGFilterPrimitiveStandardAttributes.height */
  final AnimatedLength height;

  /** @domName SVGFilterPrimitiveStandardAttributes.result */
  final AnimatedString result;

  /** @domName SVGFilterPrimitiveStandardAttributes.width */
  final AnimatedLength width;

  /** @domName SVGFilterPrimitiveStandardAttributes.x */
  final AnimatedLength x;

  /** @domName SVGFilterPrimitiveStandardAttributes.y */
  final AnimatedLength y;

  // From SVGStylable

  /** @domName SVGStylable.className */
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEComponentTransferElement
class FEComponentTransferElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEComponentTransferElement" {

  /** @domName SVGFEComponentTransferElement.in1 */
  final AnimatedString in1;

  // From SVGFilterPrimitiveStandardAttributes

  /** @domName SVGFilterPrimitiveStandardAttributes.height */
  final AnimatedLength height;

  /** @domName SVGFilterPrimitiveStandardAttributes.result */
  final AnimatedString result;

  /** @domName SVGFilterPrimitiveStandardAttributes.width */
  final AnimatedLength width;

  /** @domName SVGFilterPrimitiveStandardAttributes.x */
  final AnimatedLength x;

  /** @domName SVGFilterPrimitiveStandardAttributes.y */
  final AnimatedLength y;

  // From SVGStylable

  /** @domName SVGStylable.className */
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFECompositeElement
class FECompositeElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFECompositeElement" {

  static const int SVG_FECOMPOSITE_OPERATOR_ARITHMETIC = 6;

  static const int SVG_FECOMPOSITE_OPERATOR_ATOP = 4;

  static const int SVG_FECOMPOSITE_OPERATOR_IN = 2;

  static const int SVG_FECOMPOSITE_OPERATOR_OUT = 3;

  static const int SVG_FECOMPOSITE_OPERATOR_OVER = 1;

  static const int SVG_FECOMPOSITE_OPERATOR_UNKNOWN = 0;

  static const int SVG_FECOMPOSITE_OPERATOR_XOR = 5;

  /** @domName SVGFECompositeElement.in1 */
  final AnimatedString in1;

  /** @domName SVGFECompositeElement.in2 */
  final AnimatedString in2;

  /** @domName SVGFECompositeElement.k1 */
  final AnimatedNumber k1;

  /** @domName SVGFECompositeElement.k2 */
  final AnimatedNumber k2;

  /** @domName SVGFECompositeElement.k3 */
  final AnimatedNumber k3;

  /** @domName SVGFECompositeElement.k4 */
  final AnimatedNumber k4;

  /** @domName SVGFECompositeElement.operator */
  final AnimatedEnumeration operator;

  // From SVGFilterPrimitiveStandardAttributes

  /** @domName SVGFilterPrimitiveStandardAttributes.height */
  final AnimatedLength height;

  /** @domName SVGFilterPrimitiveStandardAttributes.result */
  final AnimatedString result;

  /** @domName SVGFilterPrimitiveStandardAttributes.width */
  final AnimatedLength width;

  /** @domName SVGFilterPrimitiveStandardAttributes.x */
  final AnimatedLength x;

  /** @domName SVGFilterPrimitiveStandardAttributes.y */
  final AnimatedLength y;

  // From SVGStylable

  /** @domName SVGStylable.className */
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEConvolveMatrixElement
class FEConvolveMatrixElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEConvolveMatrixElement" {

  static const int SVG_EDGEMODE_DUPLICATE = 1;

  static const int SVG_EDGEMODE_NONE = 3;

  static const int SVG_EDGEMODE_UNKNOWN = 0;

  static const int SVG_EDGEMODE_WRAP = 2;

  /** @domName SVGFEConvolveMatrixElement.bias */
  final AnimatedNumber bias;

  /** @domName SVGFEConvolveMatrixElement.divisor */
  final AnimatedNumber divisor;

  /** @domName SVGFEConvolveMatrixElement.edgeMode */
  final AnimatedEnumeration edgeMode;

  /** @domName SVGFEConvolveMatrixElement.in1 */
  final AnimatedString in1;

  /** @domName SVGFEConvolveMatrixElement.kernelMatrix */
  final AnimatedNumberList kernelMatrix;

  /** @domName SVGFEConvolveMatrixElement.kernelUnitLengthX */
  final AnimatedNumber kernelUnitLengthX;

  /** @domName SVGFEConvolveMatrixElement.kernelUnitLengthY */
  final AnimatedNumber kernelUnitLengthY;

  /** @domName SVGFEConvolveMatrixElement.orderX */
  final AnimatedInteger orderX;

  /** @domName SVGFEConvolveMatrixElement.orderY */
  final AnimatedInteger orderY;

  /** @domName SVGFEConvolveMatrixElement.preserveAlpha */
  final AnimatedBoolean preserveAlpha;

  /** @domName SVGFEConvolveMatrixElement.targetX */
  final AnimatedInteger targetX;

  /** @domName SVGFEConvolveMatrixElement.targetY */
  final AnimatedInteger targetY;

  // From SVGFilterPrimitiveStandardAttributes

  /** @domName SVGFilterPrimitiveStandardAttributes.height */
  final AnimatedLength height;

  /** @domName SVGFilterPrimitiveStandardAttributes.result */
  final AnimatedString result;

  /** @domName SVGFilterPrimitiveStandardAttributes.width */
  final AnimatedLength width;

  /** @domName SVGFilterPrimitiveStandardAttributes.x */
  final AnimatedLength x;

  /** @domName SVGFilterPrimitiveStandardAttributes.y */
  final AnimatedLength y;

  // From SVGStylable

  /** @domName SVGStylable.className */
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEDiffuseLightingElement
class FEDiffuseLightingElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEDiffuseLightingElement" {

  /** @domName SVGFEDiffuseLightingElement.diffuseConstant */
  final AnimatedNumber diffuseConstant;

  /** @domName SVGFEDiffuseLightingElement.in1 */
  final AnimatedString in1;

  /** @domName SVGFEDiffuseLightingElement.kernelUnitLengthX */
  final AnimatedNumber kernelUnitLengthX;

  /** @domName SVGFEDiffuseLightingElement.kernelUnitLengthY */
  final AnimatedNumber kernelUnitLengthY;

  /** @domName SVGFEDiffuseLightingElement.surfaceScale */
  final AnimatedNumber surfaceScale;

  // From SVGFilterPrimitiveStandardAttributes

  /** @domName SVGFilterPrimitiveStandardAttributes.height */
  final AnimatedLength height;

  /** @domName SVGFilterPrimitiveStandardAttributes.result */
  final AnimatedString result;

  /** @domName SVGFilterPrimitiveStandardAttributes.width */
  final AnimatedLength width;

  /** @domName SVGFilterPrimitiveStandardAttributes.x */
  final AnimatedLength x;

  /** @domName SVGFilterPrimitiveStandardAttributes.y */
  final AnimatedLength y;

  // From SVGStylable

  /** @domName SVGStylable.className */
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEDisplacementMapElement
class FEDisplacementMapElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEDisplacementMapElement" {

  static const int SVG_CHANNEL_A = 4;

  static const int SVG_CHANNEL_B = 3;

  static const int SVG_CHANNEL_G = 2;

  static const int SVG_CHANNEL_R = 1;

  static const int SVG_CHANNEL_UNKNOWN = 0;

  /** @domName SVGFEDisplacementMapElement.in1 */
  final AnimatedString in1;

  /** @domName SVGFEDisplacementMapElement.in2 */
  final AnimatedString in2;

  /** @domName SVGFEDisplacementMapElement.scale */
  final AnimatedNumber scale;

  /** @domName SVGFEDisplacementMapElement.xChannelSelector */
  final AnimatedEnumeration xChannelSelector;

  /** @domName SVGFEDisplacementMapElement.yChannelSelector */
  final AnimatedEnumeration yChannelSelector;

  // From SVGFilterPrimitiveStandardAttributes

  /** @domName SVGFilterPrimitiveStandardAttributes.height */
  final AnimatedLength height;

  /** @domName SVGFilterPrimitiveStandardAttributes.result */
  final AnimatedString result;

  /** @domName SVGFilterPrimitiveStandardAttributes.width */
  final AnimatedLength width;

  /** @domName SVGFilterPrimitiveStandardAttributes.x */
  final AnimatedLength x;

  /** @domName SVGFilterPrimitiveStandardAttributes.y */
  final AnimatedLength y;

  // From SVGStylable

  /** @domName SVGStylable.className */
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEDistantLightElement
class FEDistantLightElement extends SvgElement native "*SVGFEDistantLightElement" {

  /** @domName SVGFEDistantLightElement.azimuth */
  final AnimatedNumber azimuth;

  /** @domName SVGFEDistantLightElement.elevation */
  final AnimatedNumber elevation;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEDropShadowElement
class FEDropShadowElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEDropShadowElement" {

  /** @domName SVGFEDropShadowElement.dx */
  final AnimatedNumber dx;

  /** @domName SVGFEDropShadowElement.dy */
  final AnimatedNumber dy;

  /** @domName SVGFEDropShadowElement.in1 */
  final AnimatedString in1;

  /** @domName SVGFEDropShadowElement.stdDeviationX */
  final AnimatedNumber stdDeviationX;

  /** @domName SVGFEDropShadowElement.stdDeviationY */
  final AnimatedNumber stdDeviationY;

  /** @domName SVGFEDropShadowElement.setStdDeviation */
  void setStdDeviation(num stdDeviationX, num stdDeviationY) native;

  // From SVGFilterPrimitiveStandardAttributes

  /** @domName SVGFilterPrimitiveStandardAttributes.height */
  final AnimatedLength height;

  /** @domName SVGFilterPrimitiveStandardAttributes.result */
  final AnimatedString result;

  /** @domName SVGFilterPrimitiveStandardAttributes.width */
  final AnimatedLength width;

  /** @domName SVGFilterPrimitiveStandardAttributes.x */
  final AnimatedLength x;

  /** @domName SVGFilterPrimitiveStandardAttributes.y */
  final AnimatedLength y;

  // From SVGStylable

  /** @domName SVGStylable.className */
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEFloodElement
class FEFloodElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEFloodElement" {

  // From SVGFilterPrimitiveStandardAttributes

  /** @domName SVGFilterPrimitiveStandardAttributes.height */
  final AnimatedLength height;

  /** @domName SVGFilterPrimitiveStandardAttributes.result */
  final AnimatedString result;

  /** @domName SVGFilterPrimitiveStandardAttributes.width */
  final AnimatedLength width;

  /** @domName SVGFilterPrimitiveStandardAttributes.x */
  final AnimatedLength x;

  /** @domName SVGFilterPrimitiveStandardAttributes.y */
  final AnimatedLength y;

  // From SVGStylable

  /** @domName SVGStylable.className */
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEFuncAElement
class FEFuncAElement extends ComponentTransferFunctionElement native "*SVGFEFuncAElement" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEFuncBElement
class FEFuncBElement extends ComponentTransferFunctionElement native "*SVGFEFuncBElement" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEFuncGElement
class FEFuncGElement extends ComponentTransferFunctionElement native "*SVGFEFuncGElement" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEFuncRElement
class FEFuncRElement extends ComponentTransferFunctionElement native "*SVGFEFuncRElement" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEGaussianBlurElement
class FEGaussianBlurElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEGaussianBlurElement" {

  /** @domName SVGFEGaussianBlurElement.in1 */
  final AnimatedString in1;

  /** @domName SVGFEGaussianBlurElement.stdDeviationX */
  final AnimatedNumber stdDeviationX;

  /** @domName SVGFEGaussianBlurElement.stdDeviationY */
  final AnimatedNumber stdDeviationY;

  /** @domName SVGFEGaussianBlurElement.setStdDeviation */
  void setStdDeviation(num stdDeviationX, num stdDeviationY) native;

  // From SVGFilterPrimitiveStandardAttributes

  /** @domName SVGFilterPrimitiveStandardAttributes.height */
  final AnimatedLength height;

  /** @domName SVGFilterPrimitiveStandardAttributes.result */
  final AnimatedString result;

  /** @domName SVGFilterPrimitiveStandardAttributes.width */
  final AnimatedLength width;

  /** @domName SVGFilterPrimitiveStandardAttributes.x */
  final AnimatedLength x;

  /** @domName SVGFilterPrimitiveStandardAttributes.y */
  final AnimatedLength y;

  // From SVGStylable

  /** @domName SVGStylable.className */
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEImageElement
class FEImageElement extends SvgElement implements FilterPrimitiveStandardAttributes, UriReference, ExternalResourcesRequired, LangSpace native "*SVGFEImageElement" {

  /** @domName SVGFEImageElement.preserveAspectRatio */
  final AnimatedPreserveAspectRatio preserveAspectRatio;

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final AnimatedBoolean externalResourcesRequired;

  // From SVGFilterPrimitiveStandardAttributes

  /** @domName SVGFilterPrimitiveStandardAttributes.height */
  final AnimatedLength height;

  /** @domName SVGFilterPrimitiveStandardAttributes.result */
  final AnimatedString result;

  /** @domName SVGFilterPrimitiveStandardAttributes.width */
  final AnimatedLength width;

  /** @domName SVGFilterPrimitiveStandardAttributes.x */
  final AnimatedLength x;

  /** @domName SVGFilterPrimitiveStandardAttributes.y */
  final AnimatedLength y;

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGStylable

  /** @domName SVGStylable.className */
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;

  // From SVGURIReference

  /** @domName SVGURIReference.href */
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEMergeElement
class FEMergeElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEMergeElement" {

  // From SVGFilterPrimitiveStandardAttributes

  /** @domName SVGFilterPrimitiveStandardAttributes.height */
  final AnimatedLength height;

  /** @domName SVGFilterPrimitiveStandardAttributes.result */
  final AnimatedString result;

  /** @domName SVGFilterPrimitiveStandardAttributes.width */
  final AnimatedLength width;

  /** @domName SVGFilterPrimitiveStandardAttributes.x */
  final AnimatedLength x;

  /** @domName SVGFilterPrimitiveStandardAttributes.y */
  final AnimatedLength y;

  // From SVGStylable

  /** @domName SVGStylable.className */
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEMergeNodeElement
class FEMergeNodeElement extends SvgElement native "*SVGFEMergeNodeElement" {

  /** @domName SVGFEMergeNodeElement.in1 */
  final AnimatedString in1;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEMorphologyElement
class FEMorphologyElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEMorphologyElement" {

  static const int SVG_MORPHOLOGY_OPERATOR_DILATE = 2;

  static const int SVG_MORPHOLOGY_OPERATOR_ERODE = 1;

  static const int SVG_MORPHOLOGY_OPERATOR_UNKNOWN = 0;

  /** @domName SVGFEMorphologyElement.in1 */
  final AnimatedString in1;

  /** @domName SVGFEMorphologyElement.operator */
  final AnimatedEnumeration operator;

  /** @domName SVGFEMorphologyElement.radiusX */
  final AnimatedNumber radiusX;

  /** @domName SVGFEMorphologyElement.radiusY */
  final AnimatedNumber radiusY;

  /** @domName SVGFEMorphologyElement.setRadius */
  void setRadius(num radiusX, num radiusY) native;

  // From SVGFilterPrimitiveStandardAttributes

  /** @domName SVGFilterPrimitiveStandardAttributes.height */
  final AnimatedLength height;

  /** @domName SVGFilterPrimitiveStandardAttributes.result */
  final AnimatedString result;

  /** @domName SVGFilterPrimitiveStandardAttributes.width */
  final AnimatedLength width;

  /** @domName SVGFilterPrimitiveStandardAttributes.x */
  final AnimatedLength x;

  /** @domName SVGFilterPrimitiveStandardAttributes.y */
  final AnimatedLength y;

  // From SVGStylable

  /** @domName SVGStylable.className */
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEOffsetElement
class FEOffsetElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEOffsetElement" {

  /** @domName SVGFEOffsetElement.dx */
  final AnimatedNumber dx;

  /** @domName SVGFEOffsetElement.dy */
  final AnimatedNumber dy;

  /** @domName SVGFEOffsetElement.in1 */
  final AnimatedString in1;

  // From SVGFilterPrimitiveStandardAttributes

  /** @domName SVGFilterPrimitiveStandardAttributes.height */
  final AnimatedLength height;

  /** @domName SVGFilterPrimitiveStandardAttributes.result */
  final AnimatedString result;

  /** @domName SVGFilterPrimitiveStandardAttributes.width */
  final AnimatedLength width;

  /** @domName SVGFilterPrimitiveStandardAttributes.x */
  final AnimatedLength x;

  /** @domName SVGFilterPrimitiveStandardAttributes.y */
  final AnimatedLength y;

  // From SVGStylable

  /** @domName SVGStylable.className */
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEPointLightElement
class FEPointLightElement extends SvgElement native "*SVGFEPointLightElement" {

  /** @domName SVGFEPointLightElement.x */
  final AnimatedNumber x;

  /** @domName SVGFEPointLightElement.y */
  final AnimatedNumber y;

  /** @domName SVGFEPointLightElement.z */
  final AnimatedNumber z;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFESpecularLightingElement
class FESpecularLightingElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFESpecularLightingElement" {

  /** @domName SVGFESpecularLightingElement.in1 */
  final AnimatedString in1;

  /** @domName SVGFESpecularLightingElement.specularConstant */
  final AnimatedNumber specularConstant;

  /** @domName SVGFESpecularLightingElement.specularExponent */
  final AnimatedNumber specularExponent;

  /** @domName SVGFESpecularLightingElement.surfaceScale */
  final AnimatedNumber surfaceScale;

  // From SVGFilterPrimitiveStandardAttributes

  /** @domName SVGFilterPrimitiveStandardAttributes.height */
  final AnimatedLength height;

  /** @domName SVGFilterPrimitiveStandardAttributes.result */
  final AnimatedString result;

  /** @domName SVGFilterPrimitiveStandardAttributes.width */
  final AnimatedLength width;

  /** @domName SVGFilterPrimitiveStandardAttributes.x */
  final AnimatedLength x;

  /** @domName SVGFilterPrimitiveStandardAttributes.y */
  final AnimatedLength y;

  // From SVGStylable

  /** @domName SVGStylable.className */
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFESpotLightElement
class FESpotLightElement extends SvgElement native "*SVGFESpotLightElement" {

  /** @domName SVGFESpotLightElement.limitingConeAngle */
  final AnimatedNumber limitingConeAngle;

  /** @domName SVGFESpotLightElement.pointsAtX */
  final AnimatedNumber pointsAtX;

  /** @domName SVGFESpotLightElement.pointsAtY */
  final AnimatedNumber pointsAtY;

  /** @domName SVGFESpotLightElement.pointsAtZ */
  final AnimatedNumber pointsAtZ;

  /** @domName SVGFESpotLightElement.specularExponent */
  final AnimatedNumber specularExponent;

  /** @domName SVGFESpotLightElement.x */
  final AnimatedNumber x;

  /** @domName SVGFESpotLightElement.y */
  final AnimatedNumber y;

  /** @domName SVGFESpotLightElement.z */
  final AnimatedNumber z;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFETileElement
class FETileElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFETileElement" {

  /** @domName SVGFETileElement.in1 */
  final AnimatedString in1;

  // From SVGFilterPrimitiveStandardAttributes

  /** @domName SVGFilterPrimitiveStandardAttributes.height */
  final AnimatedLength height;

  /** @domName SVGFilterPrimitiveStandardAttributes.result */
  final AnimatedString result;

  /** @domName SVGFilterPrimitiveStandardAttributes.width */
  final AnimatedLength width;

  /** @domName SVGFilterPrimitiveStandardAttributes.x */
  final AnimatedLength x;

  /** @domName SVGFilterPrimitiveStandardAttributes.y */
  final AnimatedLength y;

  // From SVGStylable

  /** @domName SVGStylable.className */
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFETurbulenceElement
class FETurbulenceElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFETurbulenceElement" {

  static const int SVG_STITCHTYPE_NOSTITCH = 2;

  static const int SVG_STITCHTYPE_STITCH = 1;

  static const int SVG_STITCHTYPE_UNKNOWN = 0;

  static const int SVG_TURBULENCE_TYPE_FRACTALNOISE = 1;

  static const int SVG_TURBULENCE_TYPE_TURBULENCE = 2;

  static const int SVG_TURBULENCE_TYPE_UNKNOWN = 0;

  /** @domName SVGFETurbulenceElement.baseFrequencyX */
  final AnimatedNumber baseFrequencyX;

  /** @domName SVGFETurbulenceElement.baseFrequencyY */
  final AnimatedNumber baseFrequencyY;

  /** @domName SVGFETurbulenceElement.numOctaves */
  final AnimatedInteger numOctaves;

  /** @domName SVGFETurbulenceElement.seed */
  final AnimatedNumber seed;

  /** @domName SVGFETurbulenceElement.stitchTiles */
  final AnimatedEnumeration stitchTiles;

  /** @domName SVGFETurbulenceElement.type */
  final AnimatedEnumeration type;

  // From SVGFilterPrimitiveStandardAttributes

  /** @domName SVGFilterPrimitiveStandardAttributes.height */
  final AnimatedLength height;

  /** @domName SVGFilterPrimitiveStandardAttributes.result */
  final AnimatedString result;

  /** @domName SVGFilterPrimitiveStandardAttributes.width */
  final AnimatedLength width;

  /** @domName SVGFilterPrimitiveStandardAttributes.x */
  final AnimatedLength x;

  /** @domName SVGFilterPrimitiveStandardAttributes.y */
  final AnimatedLength y;

  // From SVGStylable

  /** @domName SVGStylable.className */
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFilterElement
class FilterElement extends SvgElement implements UriReference, ExternalResourcesRequired, Stylable, LangSpace native "*SVGFilterElement" {

  factory FilterElement() => _SvgElementFactoryProvider.createSvgElement_tag("filter");

  /** @domName SVGFilterElement.filterResX */
  final AnimatedInteger filterResX;

  /** @domName SVGFilterElement.filterResY */
  final AnimatedInteger filterResY;

  /** @domName SVGFilterElement.filterUnits */
  final AnimatedEnumeration filterUnits;

  /** @domName SVGFilterElement.height */
  final AnimatedLength height;

  /** @domName SVGFilterElement.primitiveUnits */
  final AnimatedEnumeration primitiveUnits;

  /** @domName SVGFilterElement.width */
  final AnimatedLength width;

  /** @domName SVGFilterElement.x */
  final AnimatedLength x;

  /** @domName SVGFilterElement.y */
  final AnimatedLength y;

  /** @domName SVGFilterElement.setFilterRes */
  void setFilterRes(int filterResX, int filterResY) native;

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGStylable

  /** @domName SVGStylable.className */
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;

  // From SVGURIReference

  /** @domName SVGURIReference.href */
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFilterPrimitiveStandardAttributes
abstract class FilterPrimitiveStandardAttributes implements Stylable {

  AnimatedLength height;

  AnimatedString result;

  AnimatedLength width;

  AnimatedLength x;

  AnimatedLength y;

  // From SVGStylable

  AnimatedString className;

  CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFitToViewBox
abstract class FitToViewBox {

  AnimatedPreserveAspectRatio preserveAspectRatio;

  AnimatedRect viewBox;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFontElement
class FontElement extends SvgElement native "*SVGFontElement" {

  factory FontElement() => _SvgElementFactoryProvider.createSvgElement_tag("font");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFontFaceElement
class FontFaceElement extends SvgElement native "*SVGFontFaceElement" {

  factory FontFaceElement() => _SvgElementFactoryProvider.createSvgElement_tag("font-face");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFontFaceFormatElement
class FontFaceFormatElement extends SvgElement native "*SVGFontFaceFormatElement" {

  factory FontFaceFormatElement() => _SvgElementFactoryProvider.createSvgElement_tag("font-face-format");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFontFaceNameElement
class FontFaceNameElement extends SvgElement native "*SVGFontFaceNameElement" {

  factory FontFaceNameElement() => _SvgElementFactoryProvider.createSvgElement_tag("font-face-name");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFontFaceSrcElement
class FontFaceSrcElement extends SvgElement native "*SVGFontFaceSrcElement" {

  factory FontFaceSrcElement() => _SvgElementFactoryProvider.createSvgElement_tag("font-face-src");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFontFaceUriElement
class FontFaceUriElement extends SvgElement native "*SVGFontFaceUriElement" {

  factory FontFaceUriElement() => _SvgElementFactoryProvider.createSvgElement_tag("font-face-uri");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGForeignObjectElement
class ForeignObjectElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGForeignObjectElement" {

  factory ForeignObjectElement() => _SvgElementFactoryProvider.createSvgElement_tag("foreignObject");

  /** @domName SVGForeignObjectElement.height */
  final AnimatedLength height;

  /** @domName SVGForeignObjectElement.width */
  final AnimatedLength width;

  /** @domName SVGForeignObjectElement.x */
  final AnimatedLength x;

  /** @domName SVGForeignObjectElement.y */
  final AnimatedLength y;

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGLocatable

  /** @domName SVGLocatable.farthestViewportElement */
  final SvgElement farthestViewportElement;

  /** @domName SVGLocatable.nearestViewportElement */
  final SvgElement nearestViewportElement;

  /** @domName SVGLocatable.getBBox */
  Rect getBBox() native;

  /** @domName SVGLocatable.getCTM */
  Matrix getCTM() native;

  /** @domName SVGLocatable.getScreenCTM */
  Matrix getScreenCTM() native;

  /** @domName SVGLocatable.getTransformToElement */
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  /** @domName SVGStylable.className */
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /** @domName SVGTests.requiredExtensions */
  final StringList requiredExtensions;

  /** @domName SVGTests.requiredFeatures */
  final StringList requiredFeatures;

  /** @domName SVGTests.systemLanguage */
  final StringList systemLanguage;

  /** @domName SVGTests.hasExtension */
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /** @domName SVGTransformable.transform */
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGGElement
class GElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGGElement" {

  factory GElement() => _SvgElementFactoryProvider.createSvgElement_tag("g");

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGLocatable

  /** @domName SVGLocatable.farthestViewportElement */
  final SvgElement farthestViewportElement;

  /** @domName SVGLocatable.nearestViewportElement */
  final SvgElement nearestViewportElement;

  /** @domName SVGLocatable.getBBox */
  Rect getBBox() native;

  /** @domName SVGLocatable.getCTM */
  Matrix getCTM() native;

  /** @domName SVGLocatable.getScreenCTM */
  Matrix getScreenCTM() native;

  /** @domName SVGLocatable.getTransformToElement */
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  /** @domName SVGStylable.className */
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /** @domName SVGTests.requiredExtensions */
  final StringList requiredExtensions;

  /** @domName SVGTests.requiredFeatures */
  final StringList requiredFeatures;

  /** @domName SVGTests.systemLanguage */
  final StringList systemLanguage;

  /** @domName SVGTests.hasExtension */
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /** @domName SVGTransformable.transform */
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGGlyphElement
class GlyphElement extends SvgElement native "*SVGGlyphElement" {

  factory GlyphElement() => _SvgElementFactoryProvider.createSvgElement_tag("glyph");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGGlyphRefElement
class GlyphRefElement extends SvgElement implements UriReference, Stylable native "*SVGGlyphRefElement" {

  /** @domName SVGGlyphRefElement.dx */
  num dx;

  /** @domName SVGGlyphRefElement.dy */
  num dy;

  /** @domName SVGGlyphRefElement.format */
  String format;

  /** @domName SVGGlyphRefElement.glyphRef */
  String glyphRef;

  /** @domName SVGGlyphRefElement.x */
  num x;

  /** @domName SVGGlyphRefElement.y */
  num y;

  // From SVGStylable

  /** @domName SVGStylable.className */
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;

  // From SVGURIReference

  /** @domName SVGURIReference.href */
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGGradientElement
class GradientElement extends SvgElement implements UriReference, ExternalResourcesRequired, Stylable native "*SVGGradientElement" {

  static const int SVG_SPREADMETHOD_PAD = 1;

  static const int SVG_SPREADMETHOD_REFLECT = 2;

  static const int SVG_SPREADMETHOD_REPEAT = 3;

  static const int SVG_SPREADMETHOD_UNKNOWN = 0;

  /** @domName SVGGradientElement.gradientTransform */
  final AnimatedTransformList gradientTransform;

  /** @domName SVGGradientElement.gradientUnits */
  final AnimatedEnumeration gradientUnits;

  /** @domName SVGGradientElement.spreadMethod */
  final AnimatedEnumeration spreadMethod;

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final AnimatedBoolean externalResourcesRequired;

  // From SVGStylable

  /** @domName SVGStylable.className */
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;

  // From SVGURIReference

  /** @domName SVGURIReference.href */
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGHKernElement
class HKernElement extends SvgElement native "*SVGHKernElement" {

  factory HKernElement() => _SvgElementFactoryProvider.createSvgElement_tag("hkern");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGImageElement
class ImageElement extends SvgElement implements Transformable, Tests, UriReference, Stylable, ExternalResourcesRequired, LangSpace native "*SVGImageElement" {

  factory ImageElement() => _SvgElementFactoryProvider.createSvgElement_tag("image");

  /** @domName SVGImageElement.height */
  final AnimatedLength height;

  /** @domName SVGImageElement.preserveAspectRatio */
  final AnimatedPreserveAspectRatio preserveAspectRatio;

  /** @domName SVGImageElement.width */
  final AnimatedLength width;

  /** @domName SVGImageElement.x */
  final AnimatedLength x;

  /** @domName SVGImageElement.y */
  final AnimatedLength y;

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGLocatable

  /** @domName SVGLocatable.farthestViewportElement */
  final SvgElement farthestViewportElement;

  /** @domName SVGLocatable.nearestViewportElement */
  final SvgElement nearestViewportElement;

  /** @domName SVGLocatable.getBBox */
  Rect getBBox() native;

  /** @domName SVGLocatable.getCTM */
  Matrix getCTM() native;

  /** @domName SVGLocatable.getScreenCTM */
  Matrix getScreenCTM() native;

  /** @domName SVGLocatable.getTransformToElement */
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  /** @domName SVGStylable.className */
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /** @domName SVGTests.requiredExtensions */
  final StringList requiredExtensions;

  /** @domName SVGTests.requiredFeatures */
  final StringList requiredFeatures;

  /** @domName SVGTests.systemLanguage */
  final StringList systemLanguage;

  /** @domName SVGTests.hasExtension */
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /** @domName SVGTransformable.transform */
  final AnimatedTransformList transform;

  // From SVGURIReference

  /** @domName SVGURIReference.href */
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGLangSpace
abstract class LangSpace {

  String xmllang;

  String xmlspace;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGLength
class Length native "*SVGLength" {

  static const int SVG_LENGTHTYPE_CM = 6;

  static const int SVG_LENGTHTYPE_EMS = 3;

  static const int SVG_LENGTHTYPE_EXS = 4;

  static const int SVG_LENGTHTYPE_IN = 8;

  static const int SVG_LENGTHTYPE_MM = 7;

  static const int SVG_LENGTHTYPE_NUMBER = 1;

  static const int SVG_LENGTHTYPE_PC = 10;

  static const int SVG_LENGTHTYPE_PERCENTAGE = 2;

  static const int SVG_LENGTHTYPE_PT = 9;

  static const int SVG_LENGTHTYPE_PX = 5;

  static const int SVG_LENGTHTYPE_UNKNOWN = 0;

  /** @domName SVGLength.unitType */
  final int unitType;

  /** @domName SVGLength.value */
  num value;

  /** @domName SVGLength.valueAsString */
  String valueAsString;

  /** @domName SVGLength.valueInSpecifiedUnits */
  num valueInSpecifiedUnits;

  /** @domName SVGLength.convertToSpecifiedUnits */
  void convertToSpecifiedUnits(int unitType) native;

  /** @domName SVGLength.newValueSpecifiedUnits */
  void newValueSpecifiedUnits(int unitType, num valueInSpecifiedUnits) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGLengthList
class LengthList implements JavaScriptIndexingBehavior, List<Length> native "*SVGLengthList" {

  /** @domName SVGLengthList.numberOfItems */
  final int numberOfItems;

  Length operator[](int index) => JS("Length", "#[#]", this, index);

  void operator[]=(int index, Length value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Length> mixins.
  // Length is the element type.

  // From Iterable<Length>:

  Iterator<Length> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<Length>(this);
  }

  // From Collection<Length>:

  void add(Length value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(Length value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<Length> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(Length element) => _Collections.contains(this, element);

  void forEach(void f(Length element)) => _Collections.forEach(this, f);

  Collection map(f(Length element)) => _Collections.map(this, [], f);

  Collection<Length> filter(bool f(Length element)) =>
     _Collections.filter(this, <Length>[], f);

  bool every(bool f(Length element)) => _Collections.every(this, f);

  bool some(bool f(Length element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<Length>:

  void sort([Comparator<Length> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(Length element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(Length element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  Length get first => this[0];

  Length get last => this[length - 1];

  Length removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<Length> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [Length initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<Length> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <Length>[]);

  // -- end List<Length> mixins.

  /** @domName SVGLengthList.appendItem */
  Length appendItem(Length item) native;

  /** @domName SVGLengthList.clear */
  void clear() native;

  /** @domName SVGLengthList.getItem */
  Length getItem(int index) native;

  /** @domName SVGLengthList.initialize */
  Length initialize(Length item) native;

  /** @domName SVGLengthList.insertItemBefore */
  Length insertItemBefore(Length item, int index) native;

  /** @domName SVGLengthList.removeItem */
  Length removeItem(int index) native;

  /** @domName SVGLengthList.replaceItem */
  Length replaceItem(Length item, int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGLineElement
class LineElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGLineElement" {

  factory LineElement() => _SvgElementFactoryProvider.createSvgElement_tag("line");

  /** @domName SVGLineElement.x1 */
  final AnimatedLength x1;

  /** @domName SVGLineElement.x2 */
  final AnimatedLength x2;

  /** @domName SVGLineElement.y1 */
  final AnimatedLength y1;

  /** @domName SVGLineElement.y2 */
  final AnimatedLength y2;

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGLocatable

  /** @domName SVGLocatable.farthestViewportElement */
  final SvgElement farthestViewportElement;

  /** @domName SVGLocatable.nearestViewportElement */
  final SvgElement nearestViewportElement;

  /** @domName SVGLocatable.getBBox */
  Rect getBBox() native;

  /** @domName SVGLocatable.getCTM */
  Matrix getCTM() native;

  /** @domName SVGLocatable.getScreenCTM */
  Matrix getScreenCTM() native;

  /** @domName SVGLocatable.getTransformToElement */
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  /** @domName SVGStylable.className */
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /** @domName SVGTests.requiredExtensions */
  final StringList requiredExtensions;

  /** @domName SVGTests.requiredFeatures */
  final StringList requiredFeatures;

  /** @domName SVGTests.systemLanguage */
  final StringList systemLanguage;

  /** @domName SVGTests.hasExtension */
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /** @domName SVGTransformable.transform */
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGLinearGradientElement
class LinearGradientElement extends GradientElement native "*SVGLinearGradientElement" {

  factory LinearGradientElement() => _SvgElementFactoryProvider.createSvgElement_tag("linearGradient");

  /** @domName SVGLinearGradientElement.x1 */
  final AnimatedLength x1;

  /** @domName SVGLinearGradientElement.x2 */
  final AnimatedLength x2;

  /** @domName SVGLinearGradientElement.y1 */
  final AnimatedLength y1;

  /** @domName SVGLinearGradientElement.y2 */
  final AnimatedLength y2;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGLocatable
abstract class Locatable {

  SvgElement farthestViewportElement;

  SvgElement nearestViewportElement;

  /** @domName SVGLocatable.getBBox */
  Rect getBBox();

  /** @domName SVGLocatable.getCTM */
  Matrix getCTM();

  /** @domName SVGLocatable.getScreenCTM */
  Matrix getScreenCTM();

  /** @domName SVGLocatable.getTransformToElement */
  Matrix getTransformToElement(SvgElement element);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGMPathElement
class MPathElement extends SvgElement implements UriReference, ExternalResourcesRequired native "*SVGMPathElement" {

  factory MPathElement() => _SvgElementFactoryProvider.createSvgElement_tag("mpath");

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final AnimatedBoolean externalResourcesRequired;

  // From SVGURIReference

  /** @domName SVGURIReference.href */
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGMarkerElement
class MarkerElement extends SvgElement implements FitToViewBox, ExternalResourcesRequired, Stylable, LangSpace native "*SVGMarkerElement" {

  factory MarkerElement() => _SvgElementFactoryProvider.createSvgElement_tag("marker");

  static const int SVG_MARKERUNITS_STROKEWIDTH = 2;

  static const int SVG_MARKERUNITS_UNKNOWN = 0;

  static const int SVG_MARKERUNITS_USERSPACEONUSE = 1;

  static const int SVG_MARKER_ORIENT_ANGLE = 2;

  static const int SVG_MARKER_ORIENT_AUTO = 1;

  static const int SVG_MARKER_ORIENT_UNKNOWN = 0;

  /** @domName SVGMarkerElement.markerHeight */
  final AnimatedLength markerHeight;

  /** @domName SVGMarkerElement.markerUnits */
  final AnimatedEnumeration markerUnits;

  /** @domName SVGMarkerElement.markerWidth */
  final AnimatedLength markerWidth;

  /** @domName SVGMarkerElement.orientAngle */
  final AnimatedAngle orientAngle;

  /** @domName SVGMarkerElement.orientType */
  final AnimatedEnumeration orientType;

  /** @domName SVGMarkerElement.refX */
  final AnimatedLength refX;

  /** @domName SVGMarkerElement.refY */
  final AnimatedLength refY;

  /** @domName SVGMarkerElement.setOrientToAngle */
  void setOrientToAngle(Angle angle) native;

  /** @domName SVGMarkerElement.setOrientToAuto */
  void setOrientToAuto() native;

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final AnimatedBoolean externalResourcesRequired;

  // From SVGFitToViewBox

  /** @domName SVGFitToViewBox.preserveAspectRatio */
  final AnimatedPreserveAspectRatio preserveAspectRatio;

  /** @domName SVGFitToViewBox.viewBox */
  final AnimatedRect viewBox;

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGStylable

  /** @domName SVGStylable.className */
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGMaskElement
class MaskElement extends SvgElement implements Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGMaskElement" {

  factory MaskElement() => _SvgElementFactoryProvider.createSvgElement_tag("mask");

  /** @domName SVGMaskElement.height */
  final AnimatedLength height;

  /** @domName SVGMaskElement.maskContentUnits */
  final AnimatedEnumeration maskContentUnits;

  /** @domName SVGMaskElement.maskUnits */
  final AnimatedEnumeration maskUnits;

  /** @domName SVGMaskElement.width */
  final AnimatedLength width;

  /** @domName SVGMaskElement.x */
  final AnimatedLength x;

  /** @domName SVGMaskElement.y */
  final AnimatedLength y;

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGStylable

  /** @domName SVGStylable.className */
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /** @domName SVGTests.requiredExtensions */
  final StringList requiredExtensions;

  /** @domName SVGTests.requiredFeatures */
  final StringList requiredFeatures;

  /** @domName SVGTests.systemLanguage */
  final StringList systemLanguage;

  /** @domName SVGTests.hasExtension */
  bool hasExtension(String extension) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGMatrix
class Matrix native "*SVGMatrix" {

  /** @domName SVGMatrix.a */
  num a;

  /** @domName SVGMatrix.b */
  num b;

  /** @domName SVGMatrix.c */
  num c;

  /** @domName SVGMatrix.d */
  num d;

  /** @domName SVGMatrix.e */
  num e;

  /** @domName SVGMatrix.f */
  num f;

  /** @domName SVGMatrix.flipX */
  Matrix flipX() native;

  /** @domName SVGMatrix.flipY */
  Matrix flipY() native;

  /** @domName SVGMatrix.inverse */
  Matrix inverse() native;

  /** @domName SVGMatrix.multiply */
  Matrix multiply(Matrix secondMatrix) native;

  /** @domName SVGMatrix.rotate */
  Matrix rotate(num angle) native;

  /** @domName SVGMatrix.rotateFromVector */
  Matrix rotateFromVector(num x, num y) native;

  /** @domName SVGMatrix.scale */
  Matrix scale(num scaleFactor) native;

  /** @domName SVGMatrix.scaleNonUniform */
  Matrix scaleNonUniform(num scaleFactorX, num scaleFactorY) native;

  /** @domName SVGMatrix.skewX */
  Matrix skewX(num angle) native;

  /** @domName SVGMatrix.skewY */
  Matrix skewY(num angle) native;

  /** @domName SVGMatrix.translate */
  Matrix translate(num x, num y) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGMetadataElement
class MetadataElement extends SvgElement native "*SVGMetadataElement" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGMissingGlyphElement
class MissingGlyphElement extends SvgElement native "*SVGMissingGlyphElement" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGNumber
class Number native "*SVGNumber" {

  /** @domName SVGNumber.value */
  num value;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGNumberList
class NumberList implements JavaScriptIndexingBehavior, List<Number> native "*SVGNumberList" {

  /** @domName SVGNumberList.numberOfItems */
  final int numberOfItems;

  Number operator[](int index) => JS("Number", "#[#]", this, index);

  void operator[]=(int index, Number value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Number> mixins.
  // Number is the element type.

  // From Iterable<Number>:

  Iterator<Number> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<Number>(this);
  }

  // From Collection<Number>:

  void add(Number value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(Number value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<Number> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(Number element) => _Collections.contains(this, element);

  void forEach(void f(Number element)) => _Collections.forEach(this, f);

  Collection map(f(Number element)) => _Collections.map(this, [], f);

  Collection<Number> filter(bool f(Number element)) =>
     _Collections.filter(this, <Number>[], f);

  bool every(bool f(Number element)) => _Collections.every(this, f);

  bool some(bool f(Number element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<Number>:

  void sort([Comparator<Number> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(Number element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(Number element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  Number get first => this[0];

  Number get last => this[length - 1];

  Number removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<Number> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [Number initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<Number> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <Number>[]);

  // -- end List<Number> mixins.

  /** @domName SVGNumberList.appendItem */
  Number appendItem(Number item) native;

  /** @domName SVGNumberList.clear */
  void clear() native;

  /** @domName SVGNumberList.getItem */
  Number getItem(int index) native;

  /** @domName SVGNumberList.initialize */
  Number initialize(Number item) native;

  /** @domName SVGNumberList.insertItemBefore */
  Number insertItemBefore(Number item, int index) native;

  /** @domName SVGNumberList.removeItem */
  Number removeItem(int index) native;

  /** @domName SVGNumberList.replaceItem */
  Number replaceItem(Number item, int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPaint
class Paint extends Color native "*SVGPaint" {

  static const int SVG_PAINTTYPE_CURRENTCOLOR = 102;

  static const int SVG_PAINTTYPE_NONE = 101;

  static const int SVG_PAINTTYPE_RGBCOLOR = 1;

  static const int SVG_PAINTTYPE_RGBCOLOR_ICCCOLOR = 2;

  static const int SVG_PAINTTYPE_UNKNOWN = 0;

  static const int SVG_PAINTTYPE_URI = 107;

  static const int SVG_PAINTTYPE_URI_CURRENTCOLOR = 104;

  static const int SVG_PAINTTYPE_URI_NONE = 103;

  static const int SVG_PAINTTYPE_URI_RGBCOLOR = 105;

  static const int SVG_PAINTTYPE_URI_RGBCOLOR_ICCCOLOR = 106;

  /** @domName SVGPaint.paintType */
  final int paintType;

  /** @domName SVGPaint.uri */
  final String uri;

  /** @domName SVGPaint.setPaint */
  void setPaint(int paintType, String uri, String rgbColor, String iccColor) native;

  /** @domName SVGPaint.setUri */
  void setUri(String uri) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathElement
class PathElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGPathElement" {

  factory PathElement() => _SvgElementFactoryProvider.createSvgElement_tag("path");

  /** @domName SVGPathElement.animatedNormalizedPathSegList */
  final PathSegList animatedNormalizedPathSegList;

  /** @domName SVGPathElement.animatedPathSegList */
  final PathSegList animatedPathSegList;

  /** @domName SVGPathElement.normalizedPathSegList */
  final PathSegList normalizedPathSegList;

  /** @domName SVGPathElement.pathLength */
  final AnimatedNumber pathLength;

  /** @domName SVGPathElement.pathSegList */
  final PathSegList pathSegList;

  /** @domName SVGPathElement.createSVGPathSegArcAbs */
  PathSegArcAbs createSVGPathSegArcAbs(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) native;

  /** @domName SVGPathElement.createSVGPathSegArcRel */
  PathSegArcRel createSVGPathSegArcRel(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) native;

  /** @domName SVGPathElement.createSVGPathSegClosePath */
  PathSegClosePath createSVGPathSegClosePath() native;

  /** @domName SVGPathElement.createSVGPathSegCurvetoCubicAbs */
  PathSegCurvetoCubicAbs createSVGPathSegCurvetoCubicAbs(num x, num y, num x1, num y1, num x2, num y2) native;

  /** @domName SVGPathElement.createSVGPathSegCurvetoCubicRel */
  PathSegCurvetoCubicRel createSVGPathSegCurvetoCubicRel(num x, num y, num x1, num y1, num x2, num y2) native;

  /** @domName SVGPathElement.createSVGPathSegCurvetoCubicSmoothAbs */
  PathSegCurvetoCubicSmoothAbs createSVGPathSegCurvetoCubicSmoothAbs(num x, num y, num x2, num y2) native;

  /** @domName SVGPathElement.createSVGPathSegCurvetoCubicSmoothRel */
  PathSegCurvetoCubicSmoothRel createSVGPathSegCurvetoCubicSmoothRel(num x, num y, num x2, num y2) native;

  /** @domName SVGPathElement.createSVGPathSegCurvetoQuadraticAbs */
  PathSegCurvetoQuadraticAbs createSVGPathSegCurvetoQuadraticAbs(num x, num y, num x1, num y1) native;

  /** @domName SVGPathElement.createSVGPathSegCurvetoQuadraticRel */
  PathSegCurvetoQuadraticRel createSVGPathSegCurvetoQuadraticRel(num x, num y, num x1, num y1) native;

  /** @domName SVGPathElement.createSVGPathSegCurvetoQuadraticSmoothAbs */
  PathSegCurvetoQuadraticSmoothAbs createSVGPathSegCurvetoQuadraticSmoothAbs(num x, num y) native;

  /** @domName SVGPathElement.createSVGPathSegCurvetoQuadraticSmoothRel */
  PathSegCurvetoQuadraticSmoothRel createSVGPathSegCurvetoQuadraticSmoothRel(num x, num y) native;

  /** @domName SVGPathElement.createSVGPathSegLinetoAbs */
  PathSegLinetoAbs createSVGPathSegLinetoAbs(num x, num y) native;

  /** @domName SVGPathElement.createSVGPathSegLinetoHorizontalAbs */
  PathSegLinetoHorizontalAbs createSVGPathSegLinetoHorizontalAbs(num x) native;

  /** @domName SVGPathElement.createSVGPathSegLinetoHorizontalRel */
  PathSegLinetoHorizontalRel createSVGPathSegLinetoHorizontalRel(num x) native;

  /** @domName SVGPathElement.createSVGPathSegLinetoRel */
  PathSegLinetoRel createSVGPathSegLinetoRel(num x, num y) native;

  /** @domName SVGPathElement.createSVGPathSegLinetoVerticalAbs */
  PathSegLinetoVerticalAbs createSVGPathSegLinetoVerticalAbs(num y) native;

  /** @domName SVGPathElement.createSVGPathSegLinetoVerticalRel */
  PathSegLinetoVerticalRel createSVGPathSegLinetoVerticalRel(num y) native;

  /** @domName SVGPathElement.createSVGPathSegMovetoAbs */
  PathSegMovetoAbs createSVGPathSegMovetoAbs(num x, num y) native;

  /** @domName SVGPathElement.createSVGPathSegMovetoRel */
  PathSegMovetoRel createSVGPathSegMovetoRel(num x, num y) native;

  /** @domName SVGPathElement.getPathSegAtLength */
  int getPathSegAtLength(num distance) native;

  /** @domName SVGPathElement.getPointAtLength */
  Point getPointAtLength(num distance) native;

  /** @domName SVGPathElement.getTotalLength */
  num getTotalLength() native;

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGLocatable

  /** @domName SVGLocatable.farthestViewportElement */
  final SvgElement farthestViewportElement;

  /** @domName SVGLocatable.nearestViewportElement */
  final SvgElement nearestViewportElement;

  /** @domName SVGLocatable.getBBox */
  Rect getBBox() native;

  /** @domName SVGLocatable.getCTM */
  Matrix getCTM() native;

  /** @domName SVGLocatable.getScreenCTM */
  Matrix getScreenCTM() native;

  /** @domName SVGLocatable.getTransformToElement */
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  /** @domName SVGStylable.className */
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /** @domName SVGTests.requiredExtensions */
  final StringList requiredExtensions;

  /** @domName SVGTests.requiredFeatures */
  final StringList requiredFeatures;

  /** @domName SVGTests.systemLanguage */
  final StringList systemLanguage;

  /** @domName SVGTests.hasExtension */
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /** @domName SVGTransformable.transform */
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSeg
class PathSeg native "*SVGPathSeg" {

  static const int PATHSEG_ARC_ABS = 10;

  static const int PATHSEG_ARC_REL = 11;

  static const int PATHSEG_CLOSEPATH = 1;

  static const int PATHSEG_CURVETO_CUBIC_ABS = 6;

  static const int PATHSEG_CURVETO_CUBIC_REL = 7;

  static const int PATHSEG_CURVETO_CUBIC_SMOOTH_ABS = 16;

  static const int PATHSEG_CURVETO_CUBIC_SMOOTH_REL = 17;

  static const int PATHSEG_CURVETO_QUADRATIC_ABS = 8;

  static const int PATHSEG_CURVETO_QUADRATIC_REL = 9;

  static const int PATHSEG_CURVETO_QUADRATIC_SMOOTH_ABS = 18;

  static const int PATHSEG_CURVETO_QUADRATIC_SMOOTH_REL = 19;

  static const int PATHSEG_LINETO_ABS = 4;

  static const int PATHSEG_LINETO_HORIZONTAL_ABS = 12;

  static const int PATHSEG_LINETO_HORIZONTAL_REL = 13;

  static const int PATHSEG_LINETO_REL = 5;

  static const int PATHSEG_LINETO_VERTICAL_ABS = 14;

  static const int PATHSEG_LINETO_VERTICAL_REL = 15;

  static const int PATHSEG_MOVETO_ABS = 2;

  static const int PATHSEG_MOVETO_REL = 3;

  static const int PATHSEG_UNKNOWN = 0;

  /** @domName SVGPathSeg.pathSegType */
  final int pathSegType;

  /** @domName SVGPathSeg.pathSegTypeAsLetter */
  final String pathSegTypeAsLetter;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegArcAbs
class PathSegArcAbs extends PathSeg native "*SVGPathSegArcAbs" {

  /** @domName SVGPathSegArcAbs.angle */
  num angle;

  /** @domName SVGPathSegArcAbs.largeArcFlag */
  bool largeArcFlag;

  /** @domName SVGPathSegArcAbs.r1 */
  num r1;

  /** @domName SVGPathSegArcAbs.r2 */
  num r2;

  /** @domName SVGPathSegArcAbs.sweepFlag */
  bool sweepFlag;

  /** @domName SVGPathSegArcAbs.x */
  num x;

  /** @domName SVGPathSegArcAbs.y */
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegArcRel
class PathSegArcRel extends PathSeg native "*SVGPathSegArcRel" {

  /** @domName SVGPathSegArcRel.angle */
  num angle;

  /** @domName SVGPathSegArcRel.largeArcFlag */
  bool largeArcFlag;

  /** @domName SVGPathSegArcRel.r1 */
  num r1;

  /** @domName SVGPathSegArcRel.r2 */
  num r2;

  /** @domName SVGPathSegArcRel.sweepFlag */
  bool sweepFlag;

  /** @domName SVGPathSegArcRel.x */
  num x;

  /** @domName SVGPathSegArcRel.y */
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegClosePath
class PathSegClosePath extends PathSeg native "*SVGPathSegClosePath" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegCurvetoCubicAbs
class PathSegCurvetoCubicAbs extends PathSeg native "*SVGPathSegCurvetoCubicAbs" {

  /** @domName SVGPathSegCurvetoCubicAbs.x */
  num x;

  /** @domName SVGPathSegCurvetoCubicAbs.x1 */
  num x1;

  /** @domName SVGPathSegCurvetoCubicAbs.x2 */
  num x2;

  /** @domName SVGPathSegCurvetoCubicAbs.y */
  num y;

  /** @domName SVGPathSegCurvetoCubicAbs.y1 */
  num y1;

  /** @domName SVGPathSegCurvetoCubicAbs.y2 */
  num y2;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegCurvetoCubicRel
class PathSegCurvetoCubicRel extends PathSeg native "*SVGPathSegCurvetoCubicRel" {

  /** @domName SVGPathSegCurvetoCubicRel.x */
  num x;

  /** @domName SVGPathSegCurvetoCubicRel.x1 */
  num x1;

  /** @domName SVGPathSegCurvetoCubicRel.x2 */
  num x2;

  /** @domName SVGPathSegCurvetoCubicRel.y */
  num y;

  /** @domName SVGPathSegCurvetoCubicRel.y1 */
  num y1;

  /** @domName SVGPathSegCurvetoCubicRel.y2 */
  num y2;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegCurvetoCubicSmoothAbs
class PathSegCurvetoCubicSmoothAbs extends PathSeg native "*SVGPathSegCurvetoCubicSmoothAbs" {

  /** @domName SVGPathSegCurvetoCubicSmoothAbs.x */
  num x;

  /** @domName SVGPathSegCurvetoCubicSmoothAbs.x2 */
  num x2;

  /** @domName SVGPathSegCurvetoCubicSmoothAbs.y */
  num y;

  /** @domName SVGPathSegCurvetoCubicSmoothAbs.y2 */
  num y2;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegCurvetoCubicSmoothRel
class PathSegCurvetoCubicSmoothRel extends PathSeg native "*SVGPathSegCurvetoCubicSmoothRel" {

  /** @domName SVGPathSegCurvetoCubicSmoothRel.x */
  num x;

  /** @domName SVGPathSegCurvetoCubicSmoothRel.x2 */
  num x2;

  /** @domName SVGPathSegCurvetoCubicSmoothRel.y */
  num y;

  /** @domName SVGPathSegCurvetoCubicSmoothRel.y2 */
  num y2;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegCurvetoQuadraticAbs
class PathSegCurvetoQuadraticAbs extends PathSeg native "*SVGPathSegCurvetoQuadraticAbs" {

  /** @domName SVGPathSegCurvetoQuadraticAbs.x */
  num x;

  /** @domName SVGPathSegCurvetoQuadraticAbs.x1 */
  num x1;

  /** @domName SVGPathSegCurvetoQuadraticAbs.y */
  num y;

  /** @domName SVGPathSegCurvetoQuadraticAbs.y1 */
  num y1;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegCurvetoQuadraticRel
class PathSegCurvetoQuadraticRel extends PathSeg native "*SVGPathSegCurvetoQuadraticRel" {

  /** @domName SVGPathSegCurvetoQuadraticRel.x */
  num x;

  /** @domName SVGPathSegCurvetoQuadraticRel.x1 */
  num x1;

  /** @domName SVGPathSegCurvetoQuadraticRel.y */
  num y;

  /** @domName SVGPathSegCurvetoQuadraticRel.y1 */
  num y1;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegCurvetoQuadraticSmoothAbs
class PathSegCurvetoQuadraticSmoothAbs extends PathSeg native "*SVGPathSegCurvetoQuadraticSmoothAbs" {

  /** @domName SVGPathSegCurvetoQuadraticSmoothAbs.x */
  num x;

  /** @domName SVGPathSegCurvetoQuadraticSmoothAbs.y */
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegCurvetoQuadraticSmoothRel
class PathSegCurvetoQuadraticSmoothRel extends PathSeg native "*SVGPathSegCurvetoQuadraticSmoothRel" {

  /** @domName SVGPathSegCurvetoQuadraticSmoothRel.x */
  num x;

  /** @domName SVGPathSegCurvetoQuadraticSmoothRel.y */
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegLinetoAbs
class PathSegLinetoAbs extends PathSeg native "*SVGPathSegLinetoAbs" {

  /** @domName SVGPathSegLinetoAbs.x */
  num x;

  /** @domName SVGPathSegLinetoAbs.y */
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegLinetoHorizontalAbs
class PathSegLinetoHorizontalAbs extends PathSeg native "*SVGPathSegLinetoHorizontalAbs" {

  /** @domName SVGPathSegLinetoHorizontalAbs.x */
  num x;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegLinetoHorizontalRel
class PathSegLinetoHorizontalRel extends PathSeg native "*SVGPathSegLinetoHorizontalRel" {

  /** @domName SVGPathSegLinetoHorizontalRel.x */
  num x;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegLinetoRel
class PathSegLinetoRel extends PathSeg native "*SVGPathSegLinetoRel" {

  /** @domName SVGPathSegLinetoRel.x */
  num x;

  /** @domName SVGPathSegLinetoRel.y */
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegLinetoVerticalAbs
class PathSegLinetoVerticalAbs extends PathSeg native "*SVGPathSegLinetoVerticalAbs" {

  /** @domName SVGPathSegLinetoVerticalAbs.y */
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegLinetoVerticalRel
class PathSegLinetoVerticalRel extends PathSeg native "*SVGPathSegLinetoVerticalRel" {

  /** @domName SVGPathSegLinetoVerticalRel.y */
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegList
class PathSegList implements JavaScriptIndexingBehavior, List<PathSeg> native "*SVGPathSegList" {

  /** @domName SVGPathSegList.numberOfItems */
  final int numberOfItems;

  PathSeg operator[](int index) => JS("PathSeg", "#[#]", this, index);

  void operator[]=(int index, PathSeg value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<PathSeg> mixins.
  // PathSeg is the element type.

  // From Iterable<PathSeg>:

  Iterator<PathSeg> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<PathSeg>(this);
  }

  // From Collection<PathSeg>:

  void add(PathSeg value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(PathSeg value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<PathSeg> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(PathSeg element) => _Collections.contains(this, element);

  void forEach(void f(PathSeg element)) => _Collections.forEach(this, f);

  Collection map(f(PathSeg element)) => _Collections.map(this, [], f);

  Collection<PathSeg> filter(bool f(PathSeg element)) =>
     _Collections.filter(this, <PathSeg>[], f);

  bool every(bool f(PathSeg element)) => _Collections.every(this, f);

  bool some(bool f(PathSeg element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<PathSeg>:

  void sort([Comparator<PathSeg> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(PathSeg element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(PathSeg element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  PathSeg get first => this[0];

  PathSeg get last => this[length - 1];

  PathSeg removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<PathSeg> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [PathSeg initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<PathSeg> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <PathSeg>[]);

  // -- end List<PathSeg> mixins.

  /** @domName SVGPathSegList.appendItem */
  PathSeg appendItem(PathSeg newItem) native;

  /** @domName SVGPathSegList.clear */
  void clear() native;

  /** @domName SVGPathSegList.getItem */
  PathSeg getItem(int index) native;

  /** @domName SVGPathSegList.initialize */
  PathSeg initialize(PathSeg newItem) native;

  /** @domName SVGPathSegList.insertItemBefore */
  PathSeg insertItemBefore(PathSeg newItem, int index) native;

  /** @domName SVGPathSegList.removeItem */
  PathSeg removeItem(int index) native;

  /** @domName SVGPathSegList.replaceItem */
  PathSeg replaceItem(PathSeg newItem, int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegMovetoAbs
class PathSegMovetoAbs extends PathSeg native "*SVGPathSegMovetoAbs" {

  /** @domName SVGPathSegMovetoAbs.x */
  num x;

  /** @domName SVGPathSegMovetoAbs.y */
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegMovetoRel
class PathSegMovetoRel extends PathSeg native "*SVGPathSegMovetoRel" {

  /** @domName SVGPathSegMovetoRel.x */
  num x;

  /** @domName SVGPathSegMovetoRel.y */
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPatternElement
class PatternElement extends SvgElement implements FitToViewBox, Tests, UriReference, Stylable, ExternalResourcesRequired, LangSpace native "*SVGPatternElement" {

  factory PatternElement() => _SvgElementFactoryProvider.createSvgElement_tag("pattern");

  /** @domName SVGPatternElement.height */
  final AnimatedLength height;

  /** @domName SVGPatternElement.patternContentUnits */
  final AnimatedEnumeration patternContentUnits;

  /** @domName SVGPatternElement.patternTransform */
  final AnimatedTransformList patternTransform;

  /** @domName SVGPatternElement.patternUnits */
  final AnimatedEnumeration patternUnits;

  /** @domName SVGPatternElement.width */
  final AnimatedLength width;

  /** @domName SVGPatternElement.x */
  final AnimatedLength x;

  /** @domName SVGPatternElement.y */
  final AnimatedLength y;

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final AnimatedBoolean externalResourcesRequired;

  // From SVGFitToViewBox

  /** @domName SVGFitToViewBox.preserveAspectRatio */
  final AnimatedPreserveAspectRatio preserveAspectRatio;

  /** @domName SVGFitToViewBox.viewBox */
  final AnimatedRect viewBox;

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGStylable

  /** @domName SVGStylable.className */
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /** @domName SVGTests.requiredExtensions */
  final StringList requiredExtensions;

  /** @domName SVGTests.requiredFeatures */
  final StringList requiredFeatures;

  /** @domName SVGTests.systemLanguage */
  final StringList systemLanguage;

  /** @domName SVGTests.hasExtension */
  bool hasExtension(String extension) native;

  // From SVGURIReference

  /** @domName SVGURIReference.href */
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


class Point native "*SVGPoint" {
  factory Point(num x, num y) => _PointFactoryProvider.createPoint(x, y);

  /** @domName SVGPoint.x */
  num x;

  /** @domName SVGPoint.y */
  num y;

  /** @domName SVGPoint.matrixTransform */
  Point matrixTransform(Matrix matrix) native;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPointList
class PointList native "*SVGPointList" {

  /** @domName SVGPointList.numberOfItems */
  final int numberOfItems;

  /** @domName SVGPointList.appendItem */
  Point appendItem(Point item) native;

  /** @domName SVGPointList.clear */
  void clear() native;

  /** @domName SVGPointList.getItem */
  Point getItem(int index) native;

  /** @domName SVGPointList.initialize */
  Point initialize(Point item) native;

  /** @domName SVGPointList.insertItemBefore */
  Point insertItemBefore(Point item, int index) native;

  /** @domName SVGPointList.removeItem */
  Point removeItem(int index) native;

  /** @domName SVGPointList.replaceItem */
  Point replaceItem(Point item, int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPolygonElement
class PolygonElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGPolygonElement" {

  factory PolygonElement() => _SvgElementFactoryProvider.createSvgElement_tag("polygon");

  /** @domName SVGPolygonElement.animatedPoints */
  final PointList animatedPoints;

  /** @domName SVGPolygonElement.points */
  final PointList points;

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGLocatable

  /** @domName SVGLocatable.farthestViewportElement */
  final SvgElement farthestViewportElement;

  /** @domName SVGLocatable.nearestViewportElement */
  final SvgElement nearestViewportElement;

  /** @domName SVGLocatable.getBBox */
  Rect getBBox() native;

  /** @domName SVGLocatable.getCTM */
  Matrix getCTM() native;

  /** @domName SVGLocatable.getScreenCTM */
  Matrix getScreenCTM() native;

  /** @domName SVGLocatable.getTransformToElement */
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  /** @domName SVGStylable.className */
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /** @domName SVGTests.requiredExtensions */
  final StringList requiredExtensions;

  /** @domName SVGTests.requiredFeatures */
  final StringList requiredFeatures;

  /** @domName SVGTests.systemLanguage */
  final StringList systemLanguage;

  /** @domName SVGTests.hasExtension */
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /** @domName SVGTransformable.transform */
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPolylineElement
class PolylineElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGPolylineElement" {

  factory PolylineElement() => _SvgElementFactoryProvider.createSvgElement_tag("polyline");

  /** @domName SVGPolylineElement.animatedPoints */
  final PointList animatedPoints;

  /** @domName SVGPolylineElement.points */
  final PointList points;

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGLocatable

  /** @domName SVGLocatable.farthestViewportElement */
  final SvgElement farthestViewportElement;

  /** @domName SVGLocatable.nearestViewportElement */
  final SvgElement nearestViewportElement;

  /** @domName SVGLocatable.getBBox */
  Rect getBBox() native;

  /** @domName SVGLocatable.getCTM */
  Matrix getCTM() native;

  /** @domName SVGLocatable.getScreenCTM */
  Matrix getScreenCTM() native;

  /** @domName SVGLocatable.getTransformToElement */
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  /** @domName SVGStylable.className */
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /** @domName SVGTests.requiredExtensions */
  final StringList requiredExtensions;

  /** @domName SVGTests.requiredFeatures */
  final StringList requiredFeatures;

  /** @domName SVGTests.systemLanguage */
  final StringList systemLanguage;

  /** @domName SVGTests.hasExtension */
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /** @domName SVGTransformable.transform */
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPreserveAspectRatio
class PreserveAspectRatio native "*SVGPreserveAspectRatio" {

  static const int SVG_MEETORSLICE_MEET = 1;

  static const int SVG_MEETORSLICE_SLICE = 2;

  static const int SVG_MEETORSLICE_UNKNOWN = 0;

  static const int SVG_PRESERVEASPECTRATIO_NONE = 1;

  static const int SVG_PRESERVEASPECTRATIO_UNKNOWN = 0;

  static const int SVG_PRESERVEASPECTRATIO_XMAXYMAX = 10;

  static const int SVG_PRESERVEASPECTRATIO_XMAXYMID = 7;

  static const int SVG_PRESERVEASPECTRATIO_XMAXYMIN = 4;

  static const int SVG_PRESERVEASPECTRATIO_XMIDYMAX = 9;

  static const int SVG_PRESERVEASPECTRATIO_XMIDYMID = 6;

  static const int SVG_PRESERVEASPECTRATIO_XMIDYMIN = 3;

  static const int SVG_PRESERVEASPECTRATIO_XMINYMAX = 8;

  static const int SVG_PRESERVEASPECTRATIO_XMINYMID = 5;

  static const int SVG_PRESERVEASPECTRATIO_XMINYMIN = 2;

  /** @domName SVGPreserveAspectRatio.align */
  int align;

  /** @domName SVGPreserveAspectRatio.meetOrSlice */
  int meetOrSlice;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGRadialGradientElement
class RadialGradientElement extends GradientElement native "*SVGRadialGradientElement" {

  factory RadialGradientElement() => _SvgElementFactoryProvider.createSvgElement_tag("radialGradient");

  /** @domName SVGRadialGradientElement.cx */
  final AnimatedLength cx;

  /** @domName SVGRadialGradientElement.cy */
  final AnimatedLength cy;

  /** @domName SVGRadialGradientElement.fr */
  final AnimatedLength fr;

  /** @domName SVGRadialGradientElement.fx */
  final AnimatedLength fx;

  /** @domName SVGRadialGradientElement.fy */
  final AnimatedLength fy;

  /** @domName SVGRadialGradientElement.r */
  final AnimatedLength r;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGRect
class Rect native "*SVGRect" {

  /** @domName SVGRect.height */
  num height;

  /** @domName SVGRect.width */
  num width;

  /** @domName SVGRect.x */
  num x;

  /** @domName SVGRect.y */
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGRectElement
class RectElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGRectElement" {

  factory RectElement() => _SvgElementFactoryProvider.createSvgElement_tag("rect");

  /** @domName SVGRectElement.height */
  final AnimatedLength height;

  /** @domName SVGRectElement.rx */
  final AnimatedLength rx;

  /** @domName SVGRectElement.ry */
  final AnimatedLength ry;

  /** @domName SVGRectElement.width */
  final AnimatedLength width;

  /** @domName SVGRectElement.x */
  final AnimatedLength x;

  /** @domName SVGRectElement.y */
  final AnimatedLength y;

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGLocatable

  /** @domName SVGLocatable.farthestViewportElement */
  final SvgElement farthestViewportElement;

  /** @domName SVGLocatable.nearestViewportElement */
  final SvgElement nearestViewportElement;

  /** @domName SVGLocatable.getBBox */
  Rect getBBox() native;

  /** @domName SVGLocatable.getCTM */
  Matrix getCTM() native;

  /** @domName SVGLocatable.getScreenCTM */
  Matrix getScreenCTM() native;

  /** @domName SVGLocatable.getTransformToElement */
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  /** @domName SVGStylable.className */
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /** @domName SVGTests.requiredExtensions */
  final StringList requiredExtensions;

  /** @domName SVGTests.requiredFeatures */
  final StringList requiredFeatures;

  /** @domName SVGTests.systemLanguage */
  final StringList systemLanguage;

  /** @domName SVGTests.hasExtension */
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /** @domName SVGTransformable.transform */
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGRenderingIntent
class RenderingIntent native "*SVGRenderingIntent" {

  static const int RENDERING_INTENT_ABSOLUTE_COLORIMETRIC = 5;

  static const int RENDERING_INTENT_AUTO = 1;

  static const int RENDERING_INTENT_PERCEPTUAL = 2;

  static const int RENDERING_INTENT_RELATIVE_COLORIMETRIC = 3;

  static const int RENDERING_INTENT_SATURATION = 4;

  static const int RENDERING_INTENT_UNKNOWN = 0;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGScriptElement
class ScriptElement extends SvgElement implements UriReference, ExternalResourcesRequired native "*SVGScriptElement" {

  factory ScriptElement() => _SvgElementFactoryProvider.createSvgElement_tag("script");

  /** @domName SVGScriptElement.type */
  String type;

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final AnimatedBoolean externalResourcesRequired;

  // From SVGURIReference

  /** @domName SVGURIReference.href */
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGSetElement
class SetElement extends AnimationElement native "*SVGSetElement" {

  factory SetElement() => _SvgElementFactoryProvider.createSvgElement_tag("set");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGStopElement
class StopElement extends SvgElement implements Stylable native "*SVGStopElement" {

  factory StopElement() => _SvgElementFactoryProvider.createSvgElement_tag("stop");

  /** @domName SVGStopElement.offset */
  final AnimatedNumber offset;

  // From SVGStylable

  /** @domName SVGStylable.className */
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGStringList
class StringList implements JavaScriptIndexingBehavior, List<String> native "*SVGStringList" {

  /** @domName SVGStringList.numberOfItems */
  final int numberOfItems;

  String operator[](int index) => JS("String", "#[#]", this, index);

  void operator[]=(int index, String value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<String> mixins.
  // String is the element type.

  // From Iterable<String>:

  Iterator<String> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<String>(this);
  }

  // From Collection<String>:

  void add(String value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(String value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<String> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(String element) => _Collections.contains(this, element);

  void forEach(void f(String element)) => _Collections.forEach(this, f);

  Collection map(f(String element)) => _Collections.map(this, [], f);

  Collection<String> filter(bool f(String element)) =>
     _Collections.filter(this, <String>[], f);

  bool every(bool f(String element)) => _Collections.every(this, f);

  bool some(bool f(String element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<String>:

  void sort([Comparator<String> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(String element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(String element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  String get first => this[0];

  String get last => this[length - 1];

  String removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<String> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [String initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<String> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <String>[]);

  // -- end List<String> mixins.

  /** @domName SVGStringList.appendItem */
  String appendItem(String item) native;

  /** @domName SVGStringList.clear */
  void clear() native;

  /** @domName SVGStringList.getItem */
  String getItem(int index) native;

  /** @domName SVGStringList.initialize */
  String initialize(String item) native;

  /** @domName SVGStringList.insertItemBefore */
  String insertItemBefore(String item, int index) native;

  /** @domName SVGStringList.removeItem */
  String removeItem(int index) native;

  /** @domName SVGStringList.replaceItem */
  String replaceItem(String item, int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGStylable
abstract class Stylable {

  AnimatedString className;

  CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGStyleElement
class StyleElement extends SvgElement implements LangSpace native "*SVGStyleElement" {

  factory StyleElement() => _SvgElementFactoryProvider.createSvgElement_tag("style");

  /** @domName SVGStyleElement.disabled */
  bool disabled;

  /** @domName SVGStyleElement.media */
  String media;

  // Shadowing definition.
  /** @domName SVGStyleElement.title */
  String get title => JS("String", "#.title", this);

  /** @domName SVGStyleElement.title */
  void set title(String value) {
    JS("void", "#.title = #", this, value);
  }

  /** @domName SVGStyleElement.type */
  String type;

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGDocument
class SvgDocument extends Document native "*SVGDocument" {

  /** @domName SVGDocument.rootElement */
  final SvgSvgElement rootElement;

  /** @domName SVGDocument.createEvent */
  Event $dom_createEvent(String eventType) native "createEvent";
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _AttributeClassSet extends CssClassSet {
  final Element _element;

  _AttributeClassSet(this._element);

  Set<String> readClasses() {
    var classname = _element.attributes['class'];

    Set<String> s = new Set<String>();
    if (classname == null) {
      return s;
    }
    for (String name in classname.split(' ')) {
      String trimmed = name.trim();
      if (!trimmed.isEmpty) {
        s.add(trimmed);
      }
    }
    return s;
  }

  void writeClasses(Set s) {
    List list = new List.from(s);
    _element.attributes['class'] = Strings.join(list, ' ');
  }
}

class SvgElement extends Element native "*SVGElement" {
  factory SvgElement.tag(String tag) =>
      _SvgElementFactoryProvider.createSvgElement_tag(tag);
  factory SvgElement.svg(String svg) =>
      _SvgElementFactoryProvider.createSvgElement_svg(svg);

  _AttributeClassSet _cssClassSet;
  CssClassSet get classes {
    if (_cssClassSet == null) {
      _cssClassSet = new _AttributeClassSet(this);
    }
    return _cssClassSet;
  }

  List<Element> get elements => new FilteredElementList(this);

  void set elements(Collection<Element> value) {
    final elements = this.elements;
    elements.clear();
    elements.addAll(value);
  }

  String get outerHTML {
    final container = new Element.tag("div");
    final SvgElement cloned = this.clone(true);
    container.elements.add(cloned);
    return container.innerHTML;
  }

  String get innerHTML {
    final container = new Element.tag("div");
    final SvgElement cloned = this.clone(true);
    container.elements.addAll(cloned.elements);
    return container.innerHTML;
  }

  void set innerHTML(String svg) {
    final container = new Element.tag("div");
    // Wrap the SVG string in <svg> so that SvgElements are created, rather than
    // HTMLElements.
    container.innerHTML = '<svg version="1.1">$svg</svg>';
    this.elements = container.elements[0].elements;
  }


  // Shadowing definition.
  /** @domName SVGElement.id */
  String get id => JS("String", "#.id", this);

  /** @domName SVGElement.id */
  void set id(String value) {
    JS("void", "#.id = #", this, value);
  }

  /** @domName SVGElement.ownerSVGElement */
  final SvgSvgElement ownerSVGElement;

  /** @domName SVGElement.viewportElement */
  final SvgElement viewportElement;

  /** @domName SVGElement.xmlbase */
  String xmlbase;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class SvgSvgElement extends SvgElement implements FitToViewBox, Tests, Stylable, Locatable, ExternalResourcesRequired, ZoomAndPan, LangSpace native "*SVGSVGElement" {
  factory SvgSvgElement() => _SvgSvgElementFactoryProvider.createSvgSvgElement();


  /** @domName SVGSVGElement.contentScriptType */
  String contentScriptType;

  /** @domName SVGSVGElement.contentStyleType */
  String contentStyleType;

  /** @domName SVGSVGElement.currentScale */
  num currentScale;

  /** @domName SVGSVGElement.currentTranslate */
  final Point currentTranslate;

  /** @domName SVGSVGElement.currentView */
  final ViewSpec currentView;

  /** @domName SVGSVGElement.height */
  final AnimatedLength height;

  /** @domName SVGSVGElement.pixelUnitToMillimeterX */
  final num pixelUnitToMillimeterX;

  /** @domName SVGSVGElement.pixelUnitToMillimeterY */
  final num pixelUnitToMillimeterY;

  /** @domName SVGSVGElement.screenPixelToMillimeterX */
  final num screenPixelToMillimeterX;

  /** @domName SVGSVGElement.screenPixelToMillimeterY */
  final num screenPixelToMillimeterY;

  /** @domName SVGSVGElement.useCurrentView */
  final bool useCurrentView;

  /** @domName SVGSVGElement.viewport */
  final Rect viewport;

  /** @domName SVGSVGElement.width */
  final AnimatedLength width;

  /** @domName SVGSVGElement.x */
  final AnimatedLength x;

  /** @domName SVGSVGElement.y */
  final AnimatedLength y;

  /** @domName SVGSVGElement.animationsPaused */
  bool animationsPaused() native;

  /** @domName SVGSVGElement.checkEnclosure */
  bool checkEnclosure(SvgElement element, Rect rect) native;

  /** @domName SVGSVGElement.checkIntersection */
  bool checkIntersection(SvgElement element, Rect rect) native;

  /** @domName SVGSVGElement.createSVGAngle */
  Angle createSVGAngle() native;

  /** @domName SVGSVGElement.createSVGLength */
  Length createSVGLength() native;

  /** @domName SVGSVGElement.createSVGMatrix */
  Matrix createSVGMatrix() native;

  /** @domName SVGSVGElement.createSVGNumber */
  Number createSVGNumber() native;

  /** @domName SVGSVGElement.createSVGPoint */
  Point createSVGPoint() native;

  /** @domName SVGSVGElement.createSVGRect */
  Rect createSVGRect() native;

  /** @domName SVGSVGElement.createSVGTransform */
  Transform createSVGTransform() native;

  /** @domName SVGSVGElement.createSVGTransformFromMatrix */
  Transform createSVGTransformFromMatrix(Matrix matrix) native;

  /** @domName SVGSVGElement.deselectAll */
  void deselectAll() native;

  /** @domName SVGSVGElement.forceRedraw */
  void forceRedraw() native;

  /** @domName SVGSVGElement.getCurrentTime */
  num getCurrentTime() native;

  /** @domName SVGSVGElement.getElementById */
  Element getElementById(String elementId) native;

  /** @domName SVGSVGElement.getEnclosureList */
  List<Node> getEnclosureList(Rect rect, SvgElement referenceElement) native;

  /** @domName SVGSVGElement.getIntersectionList */
  List<Node> getIntersectionList(Rect rect, SvgElement referenceElement) native;

  /** @domName SVGSVGElement.pauseAnimations */
  void pauseAnimations() native;

  /** @domName SVGSVGElement.setCurrentTime */
  void setCurrentTime(num seconds) native;

  /** @domName SVGSVGElement.suspendRedraw */
  int suspendRedraw(int maxWaitMilliseconds) native;

  /** @domName SVGSVGElement.unpauseAnimations */
  void unpauseAnimations() native;

  /** @domName SVGSVGElement.unsuspendRedraw */
  void unsuspendRedraw(int suspendHandleId) native;

  /** @domName SVGSVGElement.unsuspendRedrawAll */
  void unsuspendRedrawAll() native;

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final AnimatedBoolean externalResourcesRequired;

  // From SVGFitToViewBox

  /** @domName SVGFitToViewBox.preserveAspectRatio */
  final AnimatedPreserveAspectRatio preserveAspectRatio;

  /** @domName SVGFitToViewBox.viewBox */
  final AnimatedRect viewBox;

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGLocatable

  /** @domName SVGLocatable.farthestViewportElement */
  final SvgElement farthestViewportElement;

  /** @domName SVGLocatable.nearestViewportElement */
  final SvgElement nearestViewportElement;

  /** @domName SVGLocatable.getBBox */
  Rect getBBox() native;

  /** @domName SVGLocatable.getCTM */
  Matrix getCTM() native;

  /** @domName SVGLocatable.getScreenCTM */
  Matrix getScreenCTM() native;

  /** @domName SVGLocatable.getTransformToElement */
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  /** @domName SVGStylable.className */
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /** @domName SVGTests.requiredExtensions */
  final StringList requiredExtensions;

  /** @domName SVGTests.requiredFeatures */
  final StringList requiredFeatures;

  /** @domName SVGTests.systemLanguage */
  final StringList systemLanguage;

  /** @domName SVGTests.hasExtension */
  bool hasExtension(String extension) native;

  // From SVGZoomAndPan

  /** @domName SVGZoomAndPan.zoomAndPan */
  int zoomAndPan;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGSwitchElement
class SwitchElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGSwitchElement" {

  factory SwitchElement() => _SvgElementFactoryProvider.createSvgElement_tag("switch");

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGLocatable

  /** @domName SVGLocatable.farthestViewportElement */
  final SvgElement farthestViewportElement;

  /** @domName SVGLocatable.nearestViewportElement */
  final SvgElement nearestViewportElement;

  /** @domName SVGLocatable.getBBox */
  Rect getBBox() native;

  /** @domName SVGLocatable.getCTM */
  Matrix getCTM() native;

  /** @domName SVGLocatable.getScreenCTM */
  Matrix getScreenCTM() native;

  /** @domName SVGLocatable.getTransformToElement */
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  /** @domName SVGStylable.className */
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /** @domName SVGTests.requiredExtensions */
  final StringList requiredExtensions;

  /** @domName SVGTests.requiredFeatures */
  final StringList requiredFeatures;

  /** @domName SVGTests.systemLanguage */
  final StringList systemLanguage;

  /** @domName SVGTests.hasExtension */
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /** @domName SVGTransformable.transform */
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGSymbolElement
class SymbolElement extends SvgElement implements FitToViewBox, ExternalResourcesRequired, Stylable, LangSpace native "*SVGSymbolElement" {

  factory SymbolElement() => _SvgElementFactoryProvider.createSvgElement_tag("symbol");

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final AnimatedBoolean externalResourcesRequired;

  // From SVGFitToViewBox

  /** @domName SVGFitToViewBox.preserveAspectRatio */
  final AnimatedPreserveAspectRatio preserveAspectRatio;

  /** @domName SVGFitToViewBox.viewBox */
  final AnimatedRect viewBox;

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGStylable

  /** @domName SVGStylable.className */
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGTRefElement
class TRefElement extends TextPositioningElement implements UriReference native "*SVGTRefElement" {

  factory TRefElement() => _SvgElementFactoryProvider.createSvgElement_tag("tref");

  // From SVGURIReference

  /** @domName SVGURIReference.href */
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGTSpanElement
class TSpanElement extends TextPositioningElement native "*SVGTSpanElement" {

  factory TSpanElement() => _SvgElementFactoryProvider.createSvgElement_tag("tspan");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGTests
abstract class Tests {

  StringList requiredExtensions;

  StringList requiredFeatures;

  StringList systemLanguage;

  /** @domName SVGTests.hasExtension */
  bool hasExtension(String extension);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGTextContentElement
class TextContentElement extends SvgElement implements Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGTextContentElement" {

  static const int LENGTHADJUST_SPACING = 1;

  static const int LENGTHADJUST_SPACINGANDGLYPHS = 2;

  static const int LENGTHADJUST_UNKNOWN = 0;

  /** @domName SVGTextContentElement.lengthAdjust */
  final AnimatedEnumeration lengthAdjust;

  /** @domName SVGTextContentElement.textLength */
  final AnimatedLength textLength;

  /** @domName SVGTextContentElement.getCharNumAtPosition */
  int getCharNumAtPosition(Point point) native;

  /** @domName SVGTextContentElement.getComputedTextLength */
  num getComputedTextLength() native;

  /** @domName SVGTextContentElement.getEndPositionOfChar */
  Point getEndPositionOfChar(int offset) native;

  /** @domName SVGTextContentElement.getExtentOfChar */
  Rect getExtentOfChar(int offset) native;

  /** @domName SVGTextContentElement.getNumberOfChars */
  int getNumberOfChars() native;

  /** @domName SVGTextContentElement.getRotationOfChar */
  num getRotationOfChar(int offset) native;

  /** @domName SVGTextContentElement.getStartPositionOfChar */
  Point getStartPositionOfChar(int offset) native;

  /** @domName SVGTextContentElement.getSubStringLength */
  num getSubStringLength(int offset, int length) native;

  /** @domName SVGTextContentElement.selectSubString */
  void selectSubString(int offset, int length) native;

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGStylable

  /** @domName SVGStylable.className */
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /** @domName SVGTests.requiredExtensions */
  final StringList requiredExtensions;

  /** @domName SVGTests.requiredFeatures */
  final StringList requiredFeatures;

  /** @domName SVGTests.systemLanguage */
  final StringList systemLanguage;

  /** @domName SVGTests.hasExtension */
  bool hasExtension(String extension) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGTextElement
class TextElement extends TextPositioningElement implements Transformable native "*SVGTextElement" {

  factory TextElement() => _SvgElementFactoryProvider.createSvgElement_tag("text");

  // From SVGLocatable

  /** @domName SVGLocatable.farthestViewportElement */
  final SvgElement farthestViewportElement;

  /** @domName SVGLocatable.nearestViewportElement */
  final SvgElement nearestViewportElement;

  /** @domName SVGLocatable.getBBox */
  Rect getBBox() native;

  /** @domName SVGLocatable.getCTM */
  Matrix getCTM() native;

  /** @domName SVGLocatable.getScreenCTM */
  Matrix getScreenCTM() native;

  /** @domName SVGLocatable.getTransformToElement */
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGTransformable

  /** @domName SVGTransformable.transform */
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGTextPathElement
class TextPathElement extends TextContentElement implements UriReference native "*SVGTextPathElement" {

  static const int TEXTPATH_METHODTYPE_ALIGN = 1;

  static const int TEXTPATH_METHODTYPE_STRETCH = 2;

  static const int TEXTPATH_METHODTYPE_UNKNOWN = 0;

  static const int TEXTPATH_SPACINGTYPE_AUTO = 1;

  static const int TEXTPATH_SPACINGTYPE_EXACT = 2;

  static const int TEXTPATH_SPACINGTYPE_UNKNOWN = 0;

  /** @domName SVGTextPathElement.method */
  final AnimatedEnumeration method;

  /** @domName SVGTextPathElement.spacing */
  final AnimatedEnumeration spacing;

  /** @domName SVGTextPathElement.startOffset */
  final AnimatedLength startOffset;

  // From SVGURIReference

  /** @domName SVGURIReference.href */
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGTextPositioningElement
class TextPositioningElement extends TextContentElement native "*SVGTextPositioningElement" {

  /** @domName SVGTextPositioningElement.dx */
  final AnimatedLengthList dx;

  /** @domName SVGTextPositioningElement.dy */
  final AnimatedLengthList dy;

  /** @domName SVGTextPositioningElement.rotate */
  final AnimatedNumberList rotate;

  /** @domName SVGTextPositioningElement.x */
  final AnimatedLengthList x;

  /** @domName SVGTextPositioningElement.y */
  final AnimatedLengthList y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGTitleElement
class TitleElement extends SvgElement implements Stylable, LangSpace native "*SVGTitleElement" {

  factory TitleElement() => _SvgElementFactoryProvider.createSvgElement_tag("title");

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGStylable

  /** @domName SVGStylable.className */
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGTransform
class Transform native "*SVGTransform" {

  static const int SVG_TRANSFORM_MATRIX = 1;

  static const int SVG_TRANSFORM_ROTATE = 4;

  static const int SVG_TRANSFORM_SCALE = 3;

  static const int SVG_TRANSFORM_SKEWX = 5;

  static const int SVG_TRANSFORM_SKEWY = 6;

  static const int SVG_TRANSFORM_TRANSLATE = 2;

  static const int SVG_TRANSFORM_UNKNOWN = 0;

  /** @domName SVGTransform.angle */
  final num angle;

  /** @domName SVGTransform.matrix */
  final Matrix matrix;

  /** @domName SVGTransform.type */
  final int type;

  /** @domName SVGTransform.setMatrix */
  void setMatrix(Matrix matrix) native;

  /** @domName SVGTransform.setRotate */
  void setRotate(num angle, num cx, num cy) native;

  /** @domName SVGTransform.setScale */
  void setScale(num sx, num sy) native;

  /** @domName SVGTransform.setSkewX */
  void setSkewX(num angle) native;

  /** @domName SVGTransform.setSkewY */
  void setSkewY(num angle) native;

  /** @domName SVGTransform.setTranslate */
  void setTranslate(num tx, num ty) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGTransformList
class TransformList implements List<Transform>, JavaScriptIndexingBehavior native "*SVGTransformList" {

  /** @domName SVGTransformList.numberOfItems */
  final int numberOfItems;

  Transform operator[](int index) => JS("Transform", "#[#]", this, index);

  void operator[]=(int index, Transform value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Transform> mixins.
  // Transform is the element type.

  // From Iterable<Transform>:

  Iterator<Transform> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<Transform>(this);
  }

  // From Collection<Transform>:

  void add(Transform value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(Transform value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<Transform> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(Transform element) => _Collections.contains(this, element);

  void forEach(void f(Transform element)) => _Collections.forEach(this, f);

  Collection map(f(Transform element)) => _Collections.map(this, [], f);

  Collection<Transform> filter(bool f(Transform element)) =>
     _Collections.filter(this, <Transform>[], f);

  bool every(bool f(Transform element)) => _Collections.every(this, f);

  bool some(bool f(Transform element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<Transform>:

  void sort([Comparator<Transform> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(Transform element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(Transform element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  Transform get first => this[0];

  Transform get last => this[length - 1];

  Transform removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<Transform> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [Transform initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<Transform> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <Transform>[]);

  // -- end List<Transform> mixins.

  /** @domName SVGTransformList.appendItem */
  Transform appendItem(Transform item) native;

  /** @domName SVGTransformList.clear */
  void clear() native;

  /** @domName SVGTransformList.consolidate */
  Transform consolidate() native;

  /** @domName SVGTransformList.createSVGTransformFromMatrix */
  Transform createSVGTransformFromMatrix(Matrix matrix) native;

  /** @domName SVGTransformList.getItem */
  Transform getItem(int index) native;

  /** @domName SVGTransformList.initialize */
  Transform initialize(Transform item) native;

  /** @domName SVGTransformList.insertItemBefore */
  Transform insertItemBefore(Transform item, int index) native;

  /** @domName SVGTransformList.removeItem */
  Transform removeItem(int index) native;

  /** @domName SVGTransformList.replaceItem */
  Transform replaceItem(Transform item, int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGTransformable
abstract class Transformable implements Locatable {

  AnimatedTransformList transform;

  // From SVGLocatable

  SvgElement farthestViewportElement;

  SvgElement nearestViewportElement;

  /** @domName SVGLocatable.getBBox */
  Rect getBBox();

  /** @domName SVGLocatable.getCTM */
  Matrix getCTM();

  /** @domName SVGLocatable.getScreenCTM */
  Matrix getScreenCTM();

  /** @domName SVGLocatable.getTransformToElement */
  Matrix getTransformToElement(SvgElement element);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGUnitTypes
class UnitTypes native "*SVGUnitTypes" {

  static const int SVG_UNIT_TYPE_OBJECTBOUNDINGBOX = 2;

  static const int SVG_UNIT_TYPE_UNKNOWN = 0;

  static const int SVG_UNIT_TYPE_USERSPACEONUSE = 1;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGURIReference
abstract class UriReference {

  AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGUseElement
class UseElement extends SvgElement implements Transformable, Tests, UriReference, Stylable, ExternalResourcesRequired, LangSpace native "*SVGUseElement" {

  factory UseElement() => _SvgElementFactoryProvider.createSvgElement_tag("use");

  /** @domName SVGUseElement.animatedInstanceRoot */
  final ElementInstance animatedInstanceRoot;

  /** @domName SVGUseElement.height */
  final AnimatedLength height;

  /** @domName SVGUseElement.instanceRoot */
  final ElementInstance instanceRoot;

  /** @domName SVGUseElement.width */
  final AnimatedLength width;

  /** @domName SVGUseElement.x */
  final AnimatedLength x;

  /** @domName SVGUseElement.y */
  final AnimatedLength y;

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGLocatable

  /** @domName SVGLocatable.farthestViewportElement */
  final SvgElement farthestViewportElement;

  /** @domName SVGLocatable.nearestViewportElement */
  final SvgElement nearestViewportElement;

  /** @domName SVGLocatable.getBBox */
  Rect getBBox() native;

  /** @domName SVGLocatable.getCTM */
  Matrix getCTM() native;

  /** @domName SVGLocatable.getScreenCTM */
  Matrix getScreenCTM() native;

  /** @domName SVGLocatable.getTransformToElement */
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  /** @domName SVGStylable.className */
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /** @domName SVGTests.requiredExtensions */
  final StringList requiredExtensions;

  /** @domName SVGTests.requiredFeatures */
  final StringList requiredFeatures;

  /** @domName SVGTests.systemLanguage */
  final StringList systemLanguage;

  /** @domName SVGTests.hasExtension */
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /** @domName SVGTransformable.transform */
  final AnimatedTransformList transform;

  // From SVGURIReference

  /** @domName SVGURIReference.href */
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGVKernElement
class VKernElement extends SvgElement native "*SVGVKernElement" {

  factory VKernElement() => _SvgElementFactoryProvider.createSvgElement_tag("vkern");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGViewElement
class ViewElement extends SvgElement implements FitToViewBox, ExternalResourcesRequired, ZoomAndPan native "*SVGViewElement" {

  factory ViewElement() => _SvgElementFactoryProvider.createSvgElement_tag("view");

  /** @domName SVGViewElement.viewTarget */
  final StringList viewTarget;

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final AnimatedBoolean externalResourcesRequired;

  // From SVGFitToViewBox

  /** @domName SVGFitToViewBox.preserveAspectRatio */
  final AnimatedPreserveAspectRatio preserveAspectRatio;

  /** @domName SVGFitToViewBox.viewBox */
  final AnimatedRect viewBox;

  // From SVGZoomAndPan

  /** @domName SVGZoomAndPan.zoomAndPan */
  int zoomAndPan;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGViewSpec
class ViewSpec native "*SVGViewSpec" {

  /** @domName SVGViewSpec.preserveAspectRatio */
  final AnimatedPreserveAspectRatio preserveAspectRatio;

  /** @domName SVGViewSpec.preserveAspectRatioString */
  final String preserveAspectRatioString;

  /** @domName SVGViewSpec.transform */
  final TransformList transform;

  /** @domName SVGViewSpec.transformString */
  final String transformString;

  /** @domName SVGViewSpec.viewBox */
  final AnimatedRect viewBox;

  /** @domName SVGViewSpec.viewBoxString */
  final String viewBoxString;

  /** @domName SVGViewSpec.viewTarget */
  final SvgElement viewTarget;

  /** @domName SVGViewSpec.viewTargetString */
  final String viewTargetString;

  /** @domName SVGViewSpec.zoomAndPan */
  int zoomAndPan;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGZoomAndPan
abstract class ZoomAndPan {

  static const int SVG_ZOOMANDPAN_DISABLE = 1;

  static const int SVG_ZOOMANDPAN_MAGNIFY = 2;

  static const int SVG_ZOOMANDPAN_UNKNOWN = 0;

  int zoomAndPan;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGZoomEvent
class ZoomEvent extends UIEvent native "*SVGZoomEvent" {

  /** @domName SVGZoomEvent.newScale */
  final num newScale;

  /** @domName SVGZoomEvent.newTranslate */
  final Point newTranslate;

  /** @domName SVGZoomEvent.previousScale */
  final num previousScale;

  /** @domName SVGZoomEvent.previousTranslate */
  final Point previousTranslate;

  /** @domName SVGZoomEvent.zoomRectScreen */
  final Rect zoomRectScreen;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGElementInstanceList
class _ElementInstanceList implements JavaScriptIndexingBehavior, List<ElementInstance> native "*SVGElementInstanceList" {

  /** @domName SVGElementInstanceList.length */
  final int length;

  ElementInstance operator[](int index) => JS("ElementInstance", "#[#]", this, index);

  void operator[]=(int index, ElementInstance value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<ElementInstance> mixins.
  // ElementInstance is the element type.

  // From Iterable<ElementInstance>:

  Iterator<ElementInstance> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<ElementInstance>(this);
  }

  // From Collection<ElementInstance>:

  void add(ElementInstance value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(ElementInstance value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<ElementInstance> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(ElementInstance element) => _Collections.contains(this, element);

  void forEach(void f(ElementInstance element)) => _Collections.forEach(this, f);

  Collection map(f(ElementInstance element)) => _Collections.map(this, [], f);

  Collection<ElementInstance> filter(bool f(ElementInstance element)) =>
     _Collections.filter(this, <ElementInstance>[], f);

  bool every(bool f(ElementInstance element)) => _Collections.every(this, f);

  bool some(bool f(ElementInstance element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<ElementInstance>:

  void sort([Comparator<ElementInstance> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(ElementInstance element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(ElementInstance element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  ElementInstance get first => this[0];

  ElementInstance get last => this[length - 1];

  ElementInstance removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<ElementInstance> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [ElementInstance initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<ElementInstance> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <ElementInstance>[]);

  // -- end List<ElementInstance> mixins.

  /** @domName SVGElementInstanceList.item */
  ElementInstance item(int index) native;
}
