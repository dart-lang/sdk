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

    parentTag.innerHtml = svg;
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


/// @domName SVGAElement; @docsEditable true
class AElement extends SvgElement implements Transformable, Tests, UriReference, Stylable, ExternalResourcesRequired, LangSpace native "*SVGAElement" {

  factory AElement() => _SvgElementFactoryProvider.createSvgElement_tag("a");

  /// @domName SVGAElement.target; @docsEditable true
  final AnimatedString target;

  // From SVGExternalResourcesRequired

  /// @domName SVGExternalResourcesRequired.externalResourcesRequired; @docsEditable true
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /// @domName SVGLangSpace.xmllang; @docsEditable true
  String xmllang;

  /// @domName SVGLangSpace.xmlspace; @docsEditable true
  String xmlspace;

  // From SVGLocatable

  /// @domName SVGLocatable.farthestViewportElement; @docsEditable true
  final SvgElement farthestViewportElement;

  /// @domName SVGLocatable.nearestViewportElement; @docsEditable true
  final SvgElement nearestViewportElement;

  /// @domName SVGLocatable.getBBox; @docsEditable true
  Rect getBBox() native;

  /// @domName SVGLocatable.getCTM; @docsEditable true
  Matrix getCtm() native "getCTM";

  /// @domName SVGLocatable.getScreenCTM; @docsEditable true
  Matrix getScreenCtm() native "getScreenCTM";

  /// @domName SVGLocatable.getTransformToElement; @docsEditable true
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  /// @domName SVGStylable.className; @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /// @domName SVGStylable.getPresentationAttribute; @docsEditable true
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /// @domName SVGTests.requiredExtensions; @docsEditable true
  final StringList requiredExtensions;

  /// @domName SVGTests.requiredFeatures; @docsEditable true
  final StringList requiredFeatures;

  /// @domName SVGTests.systemLanguage; @docsEditable true
  final StringList systemLanguage;

  /// @domName SVGTests.hasExtension; @docsEditable true
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /// @domName SVGTransformable.transform; @docsEditable true
  final AnimatedTransformList transform;

  // From SVGURIReference

  /// @domName SVGURIReference.href; @docsEditable true
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAltGlyphDefElement; @docsEditable true
class AltGlyphDefElement extends SvgElement native "*SVGAltGlyphDefElement" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAltGlyphElement; @docsEditable true
class AltGlyphElement extends TextPositioningElement implements UriReference native "*SVGAltGlyphElement" {

  /// @domName SVGAltGlyphElement.format; @docsEditable true
  String format;

  /// @domName SVGAltGlyphElement.glyphRef; @docsEditable true
  String glyphRef;

  // From SVGURIReference

  /// @domName SVGURIReference.href; @docsEditable true
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAltGlyphItemElement; @docsEditable true
class AltGlyphItemElement extends SvgElement native "*SVGAltGlyphItemElement" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAngle; @docsEditable true
class Angle native "*SVGAngle" {

  static const int SVG_ANGLETYPE_DEG = 2;

  static const int SVG_ANGLETYPE_GRAD = 4;

  static const int SVG_ANGLETYPE_RAD = 3;

  static const int SVG_ANGLETYPE_UNKNOWN = 0;

  static const int SVG_ANGLETYPE_UNSPECIFIED = 1;

  /// @domName SVGAngle.unitType; @docsEditable true
  final int unitType;

  /// @domName SVGAngle.value; @docsEditable true
  num value;

  /// @domName SVGAngle.valueAsString; @docsEditable true
  String valueAsString;

  /// @domName SVGAngle.valueInSpecifiedUnits; @docsEditable true
  num valueInSpecifiedUnits;

  /// @domName SVGAngle.convertToSpecifiedUnits; @docsEditable true
  void convertToSpecifiedUnits(int unitType) native;

  /// @domName SVGAngle.newValueSpecifiedUnits; @docsEditable true
  void newValueSpecifiedUnits(int unitType, num valueInSpecifiedUnits) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAnimateColorElement; @docsEditable true
class AnimateColorElement extends AnimationElement native "*SVGAnimateColorElement" {

  factory AnimateColorElement() => _SvgElementFactoryProvider.createSvgElement_tag("animateColor");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAnimateElement; @docsEditable true
class AnimateElement extends AnimationElement native "*SVGAnimateElement" {

  factory AnimateElement() => _SvgElementFactoryProvider.createSvgElement_tag("animate");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAnimateMotionElement; @docsEditable true
class AnimateMotionElement extends AnimationElement native "*SVGAnimateMotionElement" {

  factory AnimateMotionElement() => _SvgElementFactoryProvider.createSvgElement_tag("animateMotion");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAnimateTransformElement; @docsEditable true
class AnimateTransformElement extends AnimationElement native "*SVGAnimateTransformElement" {

  factory AnimateTransformElement() => _SvgElementFactoryProvider.createSvgElement_tag("animateTransform");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAnimatedAngle; @docsEditable true
class AnimatedAngle native "*SVGAnimatedAngle" {

  /// @domName SVGAnimatedAngle.animVal; @docsEditable true
  final Angle animVal;

  /// @domName SVGAnimatedAngle.baseVal; @docsEditable true
  final Angle baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAnimatedBoolean; @docsEditable true
class AnimatedBoolean native "*SVGAnimatedBoolean" {

  /// @domName SVGAnimatedBoolean.animVal; @docsEditable true
  final bool animVal;

  /// @domName SVGAnimatedBoolean.baseVal; @docsEditable true
  bool baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAnimatedEnumeration; @docsEditable true
class AnimatedEnumeration native "*SVGAnimatedEnumeration" {

  /// @domName SVGAnimatedEnumeration.animVal; @docsEditable true
  final int animVal;

  /// @domName SVGAnimatedEnumeration.baseVal; @docsEditable true
  int baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAnimatedInteger; @docsEditable true
class AnimatedInteger native "*SVGAnimatedInteger" {

  /// @domName SVGAnimatedInteger.animVal; @docsEditable true
  final int animVal;

  /// @domName SVGAnimatedInteger.baseVal; @docsEditable true
  int baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAnimatedLength; @docsEditable true
class AnimatedLength native "*SVGAnimatedLength" {

  /// @domName SVGAnimatedLength.animVal; @docsEditable true
  final Length animVal;

  /// @domName SVGAnimatedLength.baseVal; @docsEditable true
  final Length baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAnimatedLengthList; @docsEditable true
class AnimatedLengthList implements JavaScriptIndexingBehavior, List<AnimatedLength> native "*SVGAnimatedLengthList" {

  /// @domName SVGAnimatedLengthList.animVal; @docsEditable true
  final LengthList animVal;

  /// @domName SVGAnimatedLengthList.baseVal; @docsEditable true
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


/// @domName SVGAnimatedNumber; @docsEditable true
class AnimatedNumber native "*SVGAnimatedNumber" {

  /// @domName SVGAnimatedNumber.animVal; @docsEditable true
  final num animVal;

  /// @domName SVGAnimatedNumber.baseVal; @docsEditable true
  num baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAnimatedNumberList; @docsEditable true
class AnimatedNumberList implements JavaScriptIndexingBehavior, List<AnimatedNumber> native "*SVGAnimatedNumberList" {

  /// @domName SVGAnimatedNumberList.animVal; @docsEditable true
  final NumberList animVal;

  /// @domName SVGAnimatedNumberList.baseVal; @docsEditable true
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


/// @domName SVGAnimatedPreserveAspectRatio; @docsEditable true
class AnimatedPreserveAspectRatio native "*SVGAnimatedPreserveAspectRatio" {

  /// @domName SVGAnimatedPreserveAspectRatio.animVal; @docsEditable true
  final PreserveAspectRatio animVal;

  /// @domName SVGAnimatedPreserveAspectRatio.baseVal; @docsEditable true
  final PreserveAspectRatio baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAnimatedRect; @docsEditable true
class AnimatedRect native "*SVGAnimatedRect" {

  /// @domName SVGAnimatedRect.animVal; @docsEditable true
  final Rect animVal;

  /// @domName SVGAnimatedRect.baseVal; @docsEditable true
  final Rect baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAnimatedString; @docsEditable true
class AnimatedString native "*SVGAnimatedString" {

  /// @domName SVGAnimatedString.animVal; @docsEditable true
  final String animVal;

  /// @domName SVGAnimatedString.baseVal; @docsEditable true
  String baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAnimatedTransformList; @docsEditable true
class AnimatedTransformList implements JavaScriptIndexingBehavior, List<AnimateTransformElement> native "*SVGAnimatedTransformList" {

  /// @domName SVGAnimatedTransformList.animVal; @docsEditable true
  final TransformList animVal;

  /// @domName SVGAnimatedTransformList.baseVal; @docsEditable true
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


/// @domName SVGAnimationElement; @docsEditable true
class AnimationElement extends SvgElement implements Tests, ElementTimeControl, ExternalResourcesRequired native "*SVGAnimationElement" {

  factory AnimationElement() => _SvgElementFactoryProvider.createSvgElement_tag("animation");

  /// @domName SVGAnimationElement.targetElement; @docsEditable true
  final SvgElement targetElement;

  /// @domName SVGAnimationElement.getCurrentTime; @docsEditable true
  num getCurrentTime() native;

  /// @domName SVGAnimationElement.getSimpleDuration; @docsEditable true
  num getSimpleDuration() native;

  /// @domName SVGAnimationElement.getStartTime; @docsEditable true
  num getStartTime() native;

  // From ElementTimeControl

  /// @domName ElementTimeControl.beginElement; @docsEditable true
  void beginElement() native;

  /// @domName ElementTimeControl.beginElementAt; @docsEditable true
  void beginElementAt(num offset) native;

  /// @domName ElementTimeControl.endElement; @docsEditable true
  void endElement() native;

  /// @domName ElementTimeControl.endElementAt; @docsEditable true
  void endElementAt(num offset) native;

  // From SVGExternalResourcesRequired

  /// @domName SVGExternalResourcesRequired.externalResourcesRequired; @docsEditable true
  final AnimatedBoolean externalResourcesRequired;

  // From SVGTests

  /// @domName SVGTests.requiredExtensions; @docsEditable true
  final StringList requiredExtensions;

  /// @domName SVGTests.requiredFeatures; @docsEditable true
  final StringList requiredFeatures;

  /// @domName SVGTests.systemLanguage; @docsEditable true
  final StringList systemLanguage;

  /// @domName SVGTests.hasExtension; @docsEditable true
  bool hasExtension(String extension) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGCircleElement; @docsEditable true
class CircleElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGCircleElement" {

  factory CircleElement() => _SvgElementFactoryProvider.createSvgElement_tag("circle");

  /// @domName SVGCircleElement.cx; @docsEditable true
  final AnimatedLength cx;

  /// @domName SVGCircleElement.cy; @docsEditable true
  final AnimatedLength cy;

  /// @domName SVGCircleElement.r; @docsEditable true
  final AnimatedLength r;

  // From SVGExternalResourcesRequired

  /// @domName SVGExternalResourcesRequired.externalResourcesRequired; @docsEditable true
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /// @domName SVGLangSpace.xmllang; @docsEditable true
  String xmllang;

  /// @domName SVGLangSpace.xmlspace; @docsEditable true
  String xmlspace;

  // From SVGLocatable

  /// @domName SVGLocatable.farthestViewportElement; @docsEditable true
  final SvgElement farthestViewportElement;

  /// @domName SVGLocatable.nearestViewportElement; @docsEditable true
  final SvgElement nearestViewportElement;

  /// @domName SVGLocatable.getBBox; @docsEditable true
  Rect getBBox() native;

  /// @domName SVGLocatable.getCTM; @docsEditable true
  Matrix getCtm() native "getCTM";

  /// @domName SVGLocatable.getScreenCTM; @docsEditable true
  Matrix getScreenCtm() native "getScreenCTM";

  /// @domName SVGLocatable.getTransformToElement; @docsEditable true
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  /// @domName SVGStylable.className; @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /// @domName SVGStylable.getPresentationAttribute; @docsEditable true
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /// @domName SVGTests.requiredExtensions; @docsEditable true
  final StringList requiredExtensions;

  /// @domName SVGTests.requiredFeatures; @docsEditable true
  final StringList requiredFeatures;

  /// @domName SVGTests.systemLanguage; @docsEditable true
  final StringList systemLanguage;

  /// @domName SVGTests.hasExtension; @docsEditable true
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /// @domName SVGTransformable.transform; @docsEditable true
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGClipPathElement; @docsEditable true
class ClipPathElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGClipPathElement" {

  factory ClipPathElement() => _SvgElementFactoryProvider.createSvgElement_tag("clipPath");

  /// @domName SVGClipPathElement.clipPathUnits; @docsEditable true
  final AnimatedEnumeration clipPathUnits;

  // From SVGExternalResourcesRequired

  /// @domName SVGExternalResourcesRequired.externalResourcesRequired; @docsEditable true
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /// @domName SVGLangSpace.xmllang; @docsEditable true
  String xmllang;

  /// @domName SVGLangSpace.xmlspace; @docsEditable true
  String xmlspace;

  // From SVGLocatable

  /// @domName SVGLocatable.farthestViewportElement; @docsEditable true
  final SvgElement farthestViewportElement;

  /// @domName SVGLocatable.nearestViewportElement; @docsEditable true
  final SvgElement nearestViewportElement;

  /// @domName SVGLocatable.getBBox; @docsEditable true
  Rect getBBox() native;

  /// @domName SVGLocatable.getCTM; @docsEditable true
  Matrix getCtm() native "getCTM";

  /// @domName SVGLocatable.getScreenCTM; @docsEditable true
  Matrix getScreenCtm() native "getScreenCTM";

  /// @domName SVGLocatable.getTransformToElement; @docsEditable true
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  /// @domName SVGStylable.className; @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /// @domName SVGStylable.getPresentationAttribute; @docsEditable true
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /// @domName SVGTests.requiredExtensions; @docsEditable true
  final StringList requiredExtensions;

  /// @domName SVGTests.requiredFeatures; @docsEditable true
  final StringList requiredFeatures;

  /// @domName SVGTests.systemLanguage; @docsEditable true
  final StringList systemLanguage;

  /// @domName SVGTests.hasExtension; @docsEditable true
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /// @domName SVGTransformable.transform; @docsEditable true
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGColor; @docsEditable true
class Color extends CSSValue native "*SVGColor" {

  static const int SVG_COLORTYPE_CURRENTCOLOR = 3;

  static const int SVG_COLORTYPE_RGBCOLOR = 1;

  static const int SVG_COLORTYPE_RGBCOLOR_ICCCOLOR = 2;

  static const int SVG_COLORTYPE_UNKNOWN = 0;

  /// @domName SVGColor.colorType; @docsEditable true
  final int colorType;

  /// @domName SVGColor.rgbColor; @docsEditable true
  final RGBColor rgbColor;

  /// @domName SVGColor.setColor; @docsEditable true
  void setColor(int colorType, String rgbColor, String iccColor) native;

  /// @domName SVGColor.setRGBColor; @docsEditable true
  void setRgbColor(String rgbColor) native "setRGBColor";

  /// @domName SVGColor.setRGBColorICCColor; @docsEditable true
  void setRgbColorIccColor(String rgbColor, String iccColor) native "setRGBColorICCColor";
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGComponentTransferFunctionElement; @docsEditable true
class ComponentTransferFunctionElement extends SvgElement native "*SVGComponentTransferFunctionElement" {

  static const int SVG_FECOMPONENTTRANSFER_TYPE_DISCRETE = 3;

  static const int SVG_FECOMPONENTTRANSFER_TYPE_GAMMA = 5;

  static const int SVG_FECOMPONENTTRANSFER_TYPE_IDENTITY = 1;

  static const int SVG_FECOMPONENTTRANSFER_TYPE_LINEAR = 4;

  static const int SVG_FECOMPONENTTRANSFER_TYPE_TABLE = 2;

  static const int SVG_FECOMPONENTTRANSFER_TYPE_UNKNOWN = 0;

  /// @domName SVGComponentTransferFunctionElement.amplitude; @docsEditable true
  final AnimatedNumber amplitude;

  /// @domName SVGComponentTransferFunctionElement.exponent; @docsEditable true
  final AnimatedNumber exponent;

  /// @domName SVGComponentTransferFunctionElement.intercept; @docsEditable true
  final AnimatedNumber intercept;

  /// @domName SVGComponentTransferFunctionElement.offset; @docsEditable true
  final AnimatedNumber offset;

  /// @domName SVGComponentTransferFunctionElement.slope; @docsEditable true
  final AnimatedNumber slope;

  /// @domName SVGComponentTransferFunctionElement.tableValues; @docsEditable true
  final AnimatedNumberList tableValues;

  /// @domName SVGComponentTransferFunctionElement.type; @docsEditable true
  final AnimatedEnumeration type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGCursorElement; @docsEditable true
class CursorElement extends SvgElement implements UriReference, Tests, ExternalResourcesRequired native "*SVGCursorElement" {

  factory CursorElement() => _SvgElementFactoryProvider.createSvgElement_tag("cursor");

  /// @domName SVGCursorElement.x; @docsEditable true
  final AnimatedLength x;

  /// @domName SVGCursorElement.y; @docsEditable true
  final AnimatedLength y;

  // From SVGExternalResourcesRequired

  /// @domName SVGExternalResourcesRequired.externalResourcesRequired; @docsEditable true
  final AnimatedBoolean externalResourcesRequired;

  // From SVGTests

  /// @domName SVGTests.requiredExtensions; @docsEditable true
  final StringList requiredExtensions;

  /// @domName SVGTests.requiredFeatures; @docsEditable true
  final StringList requiredFeatures;

  /// @domName SVGTests.systemLanguage; @docsEditable true
  final StringList systemLanguage;

  /// @domName SVGTests.hasExtension; @docsEditable true
  bool hasExtension(String extension) native;

  // From SVGURIReference

  /// @domName SVGURIReference.href; @docsEditable true
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGDefsElement; @docsEditable true
class DefsElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGDefsElement" {

  factory DefsElement() => _SvgElementFactoryProvider.createSvgElement_tag("defs");

  // From SVGExternalResourcesRequired

  /// @domName SVGExternalResourcesRequired.externalResourcesRequired; @docsEditable true
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /// @domName SVGLangSpace.xmllang; @docsEditable true
  String xmllang;

  /// @domName SVGLangSpace.xmlspace; @docsEditable true
  String xmlspace;

  // From SVGLocatable

  /// @domName SVGLocatable.farthestViewportElement; @docsEditable true
  final SvgElement farthestViewportElement;

  /// @domName SVGLocatable.nearestViewportElement; @docsEditable true
  final SvgElement nearestViewportElement;

  /// @domName SVGLocatable.getBBox; @docsEditable true
  Rect getBBox() native;

  /// @domName SVGLocatable.getCTM; @docsEditable true
  Matrix getCtm() native "getCTM";

  /// @domName SVGLocatable.getScreenCTM; @docsEditable true
  Matrix getScreenCtm() native "getScreenCTM";

  /// @domName SVGLocatable.getTransformToElement; @docsEditable true
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  /// @domName SVGStylable.className; @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /// @domName SVGStylable.getPresentationAttribute; @docsEditable true
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /// @domName SVGTests.requiredExtensions; @docsEditable true
  final StringList requiredExtensions;

  /// @domName SVGTests.requiredFeatures; @docsEditable true
  final StringList requiredFeatures;

  /// @domName SVGTests.systemLanguage; @docsEditable true
  final StringList systemLanguage;

  /// @domName SVGTests.hasExtension; @docsEditable true
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /// @domName SVGTransformable.transform; @docsEditable true
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGDescElement; @docsEditable true
class DescElement extends SvgElement implements Stylable, LangSpace native "*SVGDescElement" {

  factory DescElement() => _SvgElementFactoryProvider.createSvgElement_tag("desc");

  // From SVGLangSpace

  /// @domName SVGLangSpace.xmllang; @docsEditable true
  String xmllang;

  /// @domName SVGLangSpace.xmlspace; @docsEditable true
  String xmlspace;

  // From SVGStylable

  /// @domName SVGStylable.className; @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /// @domName SVGStylable.getPresentationAttribute; @docsEditable true
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGElementInstance; @docsEditable true
class ElementInstance extends EventTarget native "*SVGElementInstance" {

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  ElementInstanceEvents get on =>
    new ElementInstanceEvents(this);

  /// @domName SVGElementInstance.childNodes; @docsEditable true
  @Returns('_ElementInstanceList') @Creates('_ElementInstanceList')
  final List<ElementInstance> childNodes;

  /// @domName SVGElementInstance.correspondingElement; @docsEditable true
  final SvgElement correspondingElement;

  /// @domName SVGElementInstance.correspondingUseElement; @docsEditable true
  final UseElement correspondingUseElement;

  /// @domName SVGElementInstance.firstChild; @docsEditable true
  final ElementInstance firstChild;

  /// @domName SVGElementInstance.lastChild; @docsEditable true
  final ElementInstance lastChild;

  /// @domName SVGElementInstance.nextSibling; @docsEditable true
  final ElementInstance nextSibling;

  /// @domName SVGElementInstance.parentNode; @docsEditable true
  final ElementInstance parentNode;

  /// @domName SVGElementInstance.previousSibling; @docsEditable true
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


/// @domName SVGEllipseElement; @docsEditable true
class EllipseElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGEllipseElement" {

  factory EllipseElement() => _SvgElementFactoryProvider.createSvgElement_tag("ellipse");

  /// @domName SVGEllipseElement.cx; @docsEditable true
  final AnimatedLength cx;

  /// @domName SVGEllipseElement.cy; @docsEditable true
  final AnimatedLength cy;

  /// @domName SVGEllipseElement.rx; @docsEditable true
  final AnimatedLength rx;

  /// @domName SVGEllipseElement.ry; @docsEditable true
  final AnimatedLength ry;

  // From SVGExternalResourcesRequired

  /// @domName SVGExternalResourcesRequired.externalResourcesRequired; @docsEditable true
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /// @domName SVGLangSpace.xmllang; @docsEditable true
  String xmllang;

  /// @domName SVGLangSpace.xmlspace; @docsEditable true
  String xmlspace;

  // From SVGLocatable

  /// @domName SVGLocatable.farthestViewportElement; @docsEditable true
  final SvgElement farthestViewportElement;

  /// @domName SVGLocatable.nearestViewportElement; @docsEditable true
  final SvgElement nearestViewportElement;

  /// @domName SVGLocatable.getBBox; @docsEditable true
  Rect getBBox() native;

  /// @domName SVGLocatable.getCTM; @docsEditable true
  Matrix getCtm() native "getCTM";

  /// @domName SVGLocatable.getScreenCTM; @docsEditable true
  Matrix getScreenCtm() native "getScreenCTM";

  /// @domName SVGLocatable.getTransformToElement; @docsEditable true
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  /// @domName SVGStylable.className; @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /// @domName SVGStylable.getPresentationAttribute; @docsEditable true
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /// @domName SVGTests.requiredExtensions; @docsEditable true
  final StringList requiredExtensions;

  /// @domName SVGTests.requiredFeatures; @docsEditable true
  final StringList requiredFeatures;

  /// @domName SVGTests.systemLanguage; @docsEditable true
  final StringList systemLanguage;

  /// @domName SVGTests.hasExtension; @docsEditable true
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /// @domName SVGTransformable.transform; @docsEditable true
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGException; @docsEditable true
class Exception native "*SVGException" {

  static const int SVG_INVALID_VALUE_ERR = 1;

  static const int SVG_MATRIX_NOT_INVERTABLE = 2;

  static const int SVG_WRONG_TYPE_ERR = 0;

  /// @domName SVGException.code; @docsEditable true
  final int code;

  /// @domName SVGException.message; @docsEditable true
  final String message;

  /// @domName SVGException.name; @docsEditable true
  final String name;

  /// @domName SVGException.toString; @docsEditable true
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


/// @domName SVGFEBlendElement; @docsEditable true
class FEBlendElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEBlendElement" {

  static const int SVG_FEBLEND_MODE_DARKEN = 4;

  static const int SVG_FEBLEND_MODE_LIGHTEN = 5;

  static const int SVG_FEBLEND_MODE_MULTIPLY = 2;

  static const int SVG_FEBLEND_MODE_NORMAL = 1;

  static const int SVG_FEBLEND_MODE_SCREEN = 3;

  static const int SVG_FEBLEND_MODE_UNKNOWN = 0;

  /// @domName SVGFEBlendElement.in1; @docsEditable true
  final AnimatedString in1;

  /// @domName SVGFEBlendElement.in2; @docsEditable true
  final AnimatedString in2;

  /// @domName SVGFEBlendElement.mode; @docsEditable true
  final AnimatedEnumeration mode;

  // From SVGFilterPrimitiveStandardAttributes

  /// @domName SVGFilterPrimitiveStandardAttributes.height; @docsEditable true
  final AnimatedLength height;

  /// @domName SVGFilterPrimitiveStandardAttributes.result; @docsEditable true
  final AnimatedString result;

  /// @domName SVGFilterPrimitiveStandardAttributes.width; @docsEditable true
  final AnimatedLength width;

  /// @domName SVGFilterPrimitiveStandardAttributes.x; @docsEditable true
  final AnimatedLength x;

  /// @domName SVGFilterPrimitiveStandardAttributes.y; @docsEditable true
  final AnimatedLength y;

  // From SVGStylable

  /// @domName SVGStylable.className; @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /// @domName SVGStylable.getPresentationAttribute; @docsEditable true
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEColorMatrixElement; @docsEditable true
class FEColorMatrixElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEColorMatrixElement" {

  static const int SVG_FECOLORMATRIX_TYPE_HUEROTATE = 3;

  static const int SVG_FECOLORMATRIX_TYPE_LUMINANCETOALPHA = 4;

  static const int SVG_FECOLORMATRIX_TYPE_MATRIX = 1;

  static const int SVG_FECOLORMATRIX_TYPE_SATURATE = 2;

  static const int SVG_FECOLORMATRIX_TYPE_UNKNOWN = 0;

  /// @domName SVGFEColorMatrixElement.in1; @docsEditable true
  final AnimatedString in1;

  /// @domName SVGFEColorMatrixElement.type; @docsEditable true
  final AnimatedEnumeration type;

  /// @domName SVGFEColorMatrixElement.values; @docsEditable true
  final AnimatedNumberList values;

  // From SVGFilterPrimitiveStandardAttributes

  /// @domName SVGFilterPrimitiveStandardAttributes.height; @docsEditable true
  final AnimatedLength height;

  /// @domName SVGFilterPrimitiveStandardAttributes.result; @docsEditable true
  final AnimatedString result;

  /// @domName SVGFilterPrimitiveStandardAttributes.width; @docsEditable true
  final AnimatedLength width;

  /// @domName SVGFilterPrimitiveStandardAttributes.x; @docsEditable true
  final AnimatedLength x;

  /// @domName SVGFilterPrimitiveStandardAttributes.y; @docsEditable true
  final AnimatedLength y;

  // From SVGStylable

  /// @domName SVGStylable.className; @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /// @domName SVGStylable.getPresentationAttribute; @docsEditable true
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEComponentTransferElement; @docsEditable true
class FEComponentTransferElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEComponentTransferElement" {

  /// @domName SVGFEComponentTransferElement.in1; @docsEditable true
  final AnimatedString in1;

  // From SVGFilterPrimitiveStandardAttributes

  /// @domName SVGFilterPrimitiveStandardAttributes.height; @docsEditable true
  final AnimatedLength height;

  /// @domName SVGFilterPrimitiveStandardAttributes.result; @docsEditable true
  final AnimatedString result;

  /// @domName SVGFilterPrimitiveStandardAttributes.width; @docsEditable true
  final AnimatedLength width;

  /// @domName SVGFilterPrimitiveStandardAttributes.x; @docsEditable true
  final AnimatedLength x;

  /// @domName SVGFilterPrimitiveStandardAttributes.y; @docsEditable true
  final AnimatedLength y;

  // From SVGStylable

  /// @domName SVGStylable.className; @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /// @domName SVGStylable.getPresentationAttribute; @docsEditable true
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFECompositeElement; @docsEditable true
class FECompositeElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFECompositeElement" {

  static const int SVG_FECOMPOSITE_OPERATOR_ARITHMETIC = 6;

  static const int SVG_FECOMPOSITE_OPERATOR_ATOP = 4;

  static const int SVG_FECOMPOSITE_OPERATOR_IN = 2;

  static const int SVG_FECOMPOSITE_OPERATOR_OUT = 3;

  static const int SVG_FECOMPOSITE_OPERATOR_OVER = 1;

  static const int SVG_FECOMPOSITE_OPERATOR_UNKNOWN = 0;

  static const int SVG_FECOMPOSITE_OPERATOR_XOR = 5;

  /// @domName SVGFECompositeElement.in1; @docsEditable true
  final AnimatedString in1;

  /// @domName SVGFECompositeElement.in2; @docsEditable true
  final AnimatedString in2;

  /// @domName SVGFECompositeElement.k1; @docsEditable true
  final AnimatedNumber k1;

  /// @domName SVGFECompositeElement.k2; @docsEditable true
  final AnimatedNumber k2;

  /// @domName SVGFECompositeElement.k3; @docsEditable true
  final AnimatedNumber k3;

  /// @domName SVGFECompositeElement.k4; @docsEditable true
  final AnimatedNumber k4;

  /// @domName SVGFECompositeElement.operator; @docsEditable true
  final AnimatedEnumeration operator;

  // From SVGFilterPrimitiveStandardAttributes

  /// @domName SVGFilterPrimitiveStandardAttributes.height; @docsEditable true
  final AnimatedLength height;

  /// @domName SVGFilterPrimitiveStandardAttributes.result; @docsEditable true
  final AnimatedString result;

  /// @domName SVGFilterPrimitiveStandardAttributes.width; @docsEditable true
  final AnimatedLength width;

  /// @domName SVGFilterPrimitiveStandardAttributes.x; @docsEditable true
  final AnimatedLength x;

  /// @domName SVGFilterPrimitiveStandardAttributes.y; @docsEditable true
  final AnimatedLength y;

  // From SVGStylable

  /// @domName SVGStylable.className; @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /// @domName SVGStylable.getPresentationAttribute; @docsEditable true
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEConvolveMatrixElement; @docsEditable true
class FEConvolveMatrixElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEConvolveMatrixElement" {

  static const int SVG_EDGEMODE_DUPLICATE = 1;

  static const int SVG_EDGEMODE_NONE = 3;

  static const int SVG_EDGEMODE_UNKNOWN = 0;

  static const int SVG_EDGEMODE_WRAP = 2;

  /// @domName SVGFEConvolveMatrixElement.bias; @docsEditable true
  final AnimatedNumber bias;

  /// @domName SVGFEConvolveMatrixElement.divisor; @docsEditable true
  final AnimatedNumber divisor;

  /// @domName SVGFEConvolveMatrixElement.edgeMode; @docsEditable true
  final AnimatedEnumeration edgeMode;

  /// @domName SVGFEConvolveMatrixElement.in1; @docsEditable true
  final AnimatedString in1;

  /// @domName SVGFEConvolveMatrixElement.kernelMatrix; @docsEditable true
  final AnimatedNumberList kernelMatrix;

  /// @domName SVGFEConvolveMatrixElement.kernelUnitLengthX; @docsEditable true
  final AnimatedNumber kernelUnitLengthX;

  /// @domName SVGFEConvolveMatrixElement.kernelUnitLengthY; @docsEditable true
  final AnimatedNumber kernelUnitLengthY;

  /// @domName SVGFEConvolveMatrixElement.orderX; @docsEditable true
  final AnimatedInteger orderX;

  /// @domName SVGFEConvolveMatrixElement.orderY; @docsEditable true
  final AnimatedInteger orderY;

  /// @domName SVGFEConvolveMatrixElement.preserveAlpha; @docsEditable true
  final AnimatedBoolean preserveAlpha;

  /// @domName SVGFEConvolveMatrixElement.targetX; @docsEditable true
  final AnimatedInteger targetX;

  /// @domName SVGFEConvolveMatrixElement.targetY; @docsEditable true
  final AnimatedInteger targetY;

  // From SVGFilterPrimitiveStandardAttributes

  /// @domName SVGFilterPrimitiveStandardAttributes.height; @docsEditable true
  final AnimatedLength height;

  /// @domName SVGFilterPrimitiveStandardAttributes.result; @docsEditable true
  final AnimatedString result;

  /// @domName SVGFilterPrimitiveStandardAttributes.width; @docsEditable true
  final AnimatedLength width;

  /// @domName SVGFilterPrimitiveStandardAttributes.x; @docsEditable true
  final AnimatedLength x;

  /// @domName SVGFilterPrimitiveStandardAttributes.y; @docsEditable true
  final AnimatedLength y;

  // From SVGStylable

  /// @domName SVGStylable.className; @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /// @domName SVGStylable.getPresentationAttribute; @docsEditable true
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEDiffuseLightingElement; @docsEditable true
class FEDiffuseLightingElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEDiffuseLightingElement" {

  /// @domName SVGFEDiffuseLightingElement.diffuseConstant; @docsEditable true
  final AnimatedNumber diffuseConstant;

  /// @domName SVGFEDiffuseLightingElement.in1; @docsEditable true
  final AnimatedString in1;

  /// @domName SVGFEDiffuseLightingElement.kernelUnitLengthX; @docsEditable true
  final AnimatedNumber kernelUnitLengthX;

  /// @domName SVGFEDiffuseLightingElement.kernelUnitLengthY; @docsEditable true
  final AnimatedNumber kernelUnitLengthY;

  /// @domName SVGFEDiffuseLightingElement.surfaceScale; @docsEditable true
  final AnimatedNumber surfaceScale;

  // From SVGFilterPrimitiveStandardAttributes

  /// @domName SVGFilterPrimitiveStandardAttributes.height; @docsEditable true
  final AnimatedLength height;

  /// @domName SVGFilterPrimitiveStandardAttributes.result; @docsEditable true
  final AnimatedString result;

  /// @domName SVGFilterPrimitiveStandardAttributes.width; @docsEditable true
  final AnimatedLength width;

  /// @domName SVGFilterPrimitiveStandardAttributes.x; @docsEditable true
  final AnimatedLength x;

  /// @domName SVGFilterPrimitiveStandardAttributes.y; @docsEditable true
  final AnimatedLength y;

  // From SVGStylable

  /// @domName SVGStylable.className; @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /// @domName SVGStylable.getPresentationAttribute; @docsEditable true
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEDisplacementMapElement; @docsEditable true
class FEDisplacementMapElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEDisplacementMapElement" {

  static const int SVG_CHANNEL_A = 4;

  static const int SVG_CHANNEL_B = 3;

  static const int SVG_CHANNEL_G = 2;

  static const int SVG_CHANNEL_R = 1;

  static const int SVG_CHANNEL_UNKNOWN = 0;

  /// @domName SVGFEDisplacementMapElement.in1; @docsEditable true
  final AnimatedString in1;

  /// @domName SVGFEDisplacementMapElement.in2; @docsEditable true
  final AnimatedString in2;

  /// @domName SVGFEDisplacementMapElement.scale; @docsEditable true
  final AnimatedNumber scale;

  /// @domName SVGFEDisplacementMapElement.xChannelSelector; @docsEditable true
  final AnimatedEnumeration xChannelSelector;

  /// @domName SVGFEDisplacementMapElement.yChannelSelector; @docsEditable true
  final AnimatedEnumeration yChannelSelector;

  // From SVGFilterPrimitiveStandardAttributes

  /// @domName SVGFilterPrimitiveStandardAttributes.height; @docsEditable true
  final AnimatedLength height;

  /// @domName SVGFilterPrimitiveStandardAttributes.result; @docsEditable true
  final AnimatedString result;

  /// @domName SVGFilterPrimitiveStandardAttributes.width; @docsEditable true
  final AnimatedLength width;

  /// @domName SVGFilterPrimitiveStandardAttributes.x; @docsEditable true
  final AnimatedLength x;

  /// @domName SVGFilterPrimitiveStandardAttributes.y; @docsEditable true
  final AnimatedLength y;

  // From SVGStylable

  /// @domName SVGStylable.className; @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /// @domName SVGStylable.getPresentationAttribute; @docsEditable true
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEDistantLightElement; @docsEditable true
class FEDistantLightElement extends SvgElement native "*SVGFEDistantLightElement" {

  /// @domName SVGFEDistantLightElement.azimuth; @docsEditable true
  final AnimatedNumber azimuth;

  /// @domName SVGFEDistantLightElement.elevation; @docsEditable true
  final AnimatedNumber elevation;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEDropShadowElement; @docsEditable true
class FEDropShadowElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEDropShadowElement" {

  /// @domName SVGFEDropShadowElement.dx; @docsEditable true
  final AnimatedNumber dx;

  /// @domName SVGFEDropShadowElement.dy; @docsEditable true
  final AnimatedNumber dy;

  /// @domName SVGFEDropShadowElement.in1; @docsEditable true
  final AnimatedString in1;

  /// @domName SVGFEDropShadowElement.stdDeviationX; @docsEditable true
  final AnimatedNumber stdDeviationX;

  /// @domName SVGFEDropShadowElement.stdDeviationY; @docsEditable true
  final AnimatedNumber stdDeviationY;

  /// @domName SVGFEDropShadowElement.setStdDeviation; @docsEditable true
  void setStdDeviation(num stdDeviationX, num stdDeviationY) native;

  // From SVGFilterPrimitiveStandardAttributes

  /// @domName SVGFilterPrimitiveStandardAttributes.height; @docsEditable true
  final AnimatedLength height;

  /// @domName SVGFilterPrimitiveStandardAttributes.result; @docsEditable true
  final AnimatedString result;

  /// @domName SVGFilterPrimitiveStandardAttributes.width; @docsEditable true
  final AnimatedLength width;

  /// @domName SVGFilterPrimitiveStandardAttributes.x; @docsEditable true
  final AnimatedLength x;

  /// @domName SVGFilterPrimitiveStandardAttributes.y; @docsEditable true
  final AnimatedLength y;

  // From SVGStylable

  /// @domName SVGStylable.className; @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /// @domName SVGStylable.getPresentationAttribute; @docsEditable true
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEFloodElement; @docsEditable true
class FEFloodElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEFloodElement" {

  // From SVGFilterPrimitiveStandardAttributes

  /// @domName SVGFilterPrimitiveStandardAttributes.height; @docsEditable true
  final AnimatedLength height;

  /// @domName SVGFilterPrimitiveStandardAttributes.result; @docsEditable true
  final AnimatedString result;

  /// @domName SVGFilterPrimitiveStandardAttributes.width; @docsEditable true
  final AnimatedLength width;

  /// @domName SVGFilterPrimitiveStandardAttributes.x; @docsEditable true
  final AnimatedLength x;

  /// @domName SVGFilterPrimitiveStandardAttributes.y; @docsEditable true
  final AnimatedLength y;

  // From SVGStylable

  /// @domName SVGStylable.className; @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /// @domName SVGStylable.getPresentationAttribute; @docsEditable true
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEFuncAElement; @docsEditable true
class FEFuncAElement extends ComponentTransferFunctionElement native "*SVGFEFuncAElement" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEFuncBElement; @docsEditable true
class FEFuncBElement extends ComponentTransferFunctionElement native "*SVGFEFuncBElement" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEFuncGElement; @docsEditable true
class FEFuncGElement extends ComponentTransferFunctionElement native "*SVGFEFuncGElement" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEFuncRElement; @docsEditable true
class FEFuncRElement extends ComponentTransferFunctionElement native "*SVGFEFuncRElement" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEGaussianBlurElement; @docsEditable true
class FEGaussianBlurElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEGaussianBlurElement" {

  /// @domName SVGFEGaussianBlurElement.in1; @docsEditable true
  final AnimatedString in1;

  /// @domName SVGFEGaussianBlurElement.stdDeviationX; @docsEditable true
  final AnimatedNumber stdDeviationX;

  /// @domName SVGFEGaussianBlurElement.stdDeviationY; @docsEditable true
  final AnimatedNumber stdDeviationY;

  /// @domName SVGFEGaussianBlurElement.setStdDeviation; @docsEditable true
  void setStdDeviation(num stdDeviationX, num stdDeviationY) native;

  // From SVGFilterPrimitiveStandardAttributes

  /// @domName SVGFilterPrimitiveStandardAttributes.height; @docsEditable true
  final AnimatedLength height;

  /// @domName SVGFilterPrimitiveStandardAttributes.result; @docsEditable true
  final AnimatedString result;

  /// @domName SVGFilterPrimitiveStandardAttributes.width; @docsEditable true
  final AnimatedLength width;

  /// @domName SVGFilterPrimitiveStandardAttributes.x; @docsEditable true
  final AnimatedLength x;

  /// @domName SVGFilterPrimitiveStandardAttributes.y; @docsEditable true
  final AnimatedLength y;

  // From SVGStylable

  /// @domName SVGStylable.className; @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /// @domName SVGStylable.getPresentationAttribute; @docsEditable true
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEImageElement; @docsEditable true
class FEImageElement extends SvgElement implements FilterPrimitiveStandardAttributes, UriReference, ExternalResourcesRequired, LangSpace native "*SVGFEImageElement" {

  /// @domName SVGFEImageElement.preserveAspectRatio; @docsEditable true
  final AnimatedPreserveAspectRatio preserveAspectRatio;

  // From SVGExternalResourcesRequired

  /// @domName SVGExternalResourcesRequired.externalResourcesRequired; @docsEditable true
  final AnimatedBoolean externalResourcesRequired;

  // From SVGFilterPrimitiveStandardAttributes

  /// @domName SVGFilterPrimitiveStandardAttributes.height; @docsEditable true
  final AnimatedLength height;

  /// @domName SVGFilterPrimitiveStandardAttributes.result; @docsEditable true
  final AnimatedString result;

  /// @domName SVGFilterPrimitiveStandardAttributes.width; @docsEditable true
  final AnimatedLength width;

  /// @domName SVGFilterPrimitiveStandardAttributes.x; @docsEditable true
  final AnimatedLength x;

  /// @domName SVGFilterPrimitiveStandardAttributes.y; @docsEditable true
  final AnimatedLength y;

  // From SVGLangSpace

  /// @domName SVGLangSpace.xmllang; @docsEditable true
  String xmllang;

  /// @domName SVGLangSpace.xmlspace; @docsEditable true
  String xmlspace;

  // From SVGStylable

  /// @domName SVGStylable.className; @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /// @domName SVGStylable.getPresentationAttribute; @docsEditable true
  CSSValue getPresentationAttribute(String name) native;

  // From SVGURIReference

  /// @domName SVGURIReference.href; @docsEditable true
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEMergeElement; @docsEditable true
class FEMergeElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEMergeElement" {

  // From SVGFilterPrimitiveStandardAttributes

  /// @domName SVGFilterPrimitiveStandardAttributes.height; @docsEditable true
  final AnimatedLength height;

  /// @domName SVGFilterPrimitiveStandardAttributes.result; @docsEditable true
  final AnimatedString result;

  /// @domName SVGFilterPrimitiveStandardAttributes.width; @docsEditable true
  final AnimatedLength width;

  /// @domName SVGFilterPrimitiveStandardAttributes.x; @docsEditable true
  final AnimatedLength x;

  /// @domName SVGFilterPrimitiveStandardAttributes.y; @docsEditable true
  final AnimatedLength y;

  // From SVGStylable

  /// @domName SVGStylable.className; @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /// @domName SVGStylable.getPresentationAttribute; @docsEditable true
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEMergeNodeElement; @docsEditable true
class FEMergeNodeElement extends SvgElement native "*SVGFEMergeNodeElement" {

  /// @domName SVGFEMergeNodeElement.in1; @docsEditable true
  final AnimatedString in1;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEMorphologyElement; @docsEditable true
class FEMorphologyElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEMorphologyElement" {

  static const int SVG_MORPHOLOGY_OPERATOR_DILATE = 2;

  static const int SVG_MORPHOLOGY_OPERATOR_ERODE = 1;

  static const int SVG_MORPHOLOGY_OPERATOR_UNKNOWN = 0;

  /// @domName SVGFEMorphologyElement.in1; @docsEditable true
  final AnimatedString in1;

  /// @domName SVGFEMorphologyElement.operator; @docsEditable true
  final AnimatedEnumeration operator;

  /// @domName SVGFEMorphologyElement.radiusX; @docsEditable true
  final AnimatedNumber radiusX;

  /// @domName SVGFEMorphologyElement.radiusY; @docsEditable true
  final AnimatedNumber radiusY;

  /// @domName SVGFEMorphologyElement.setRadius; @docsEditable true
  void setRadius(num radiusX, num radiusY) native;

  // From SVGFilterPrimitiveStandardAttributes

  /// @domName SVGFilterPrimitiveStandardAttributes.height; @docsEditable true
  final AnimatedLength height;

  /// @domName SVGFilterPrimitiveStandardAttributes.result; @docsEditable true
  final AnimatedString result;

  /// @domName SVGFilterPrimitiveStandardAttributes.width; @docsEditable true
  final AnimatedLength width;

  /// @domName SVGFilterPrimitiveStandardAttributes.x; @docsEditable true
  final AnimatedLength x;

  /// @domName SVGFilterPrimitiveStandardAttributes.y; @docsEditable true
  final AnimatedLength y;

  // From SVGStylable

  /// @domName SVGStylable.className; @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /// @domName SVGStylable.getPresentationAttribute; @docsEditable true
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEOffsetElement; @docsEditable true
class FEOffsetElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEOffsetElement" {

  /// @domName SVGFEOffsetElement.dx; @docsEditable true
  final AnimatedNumber dx;

  /// @domName SVGFEOffsetElement.dy; @docsEditable true
  final AnimatedNumber dy;

  /// @domName SVGFEOffsetElement.in1; @docsEditable true
  final AnimatedString in1;

  // From SVGFilterPrimitiveStandardAttributes

  /// @domName SVGFilterPrimitiveStandardAttributes.height; @docsEditable true
  final AnimatedLength height;

  /// @domName SVGFilterPrimitiveStandardAttributes.result; @docsEditable true
  final AnimatedString result;

  /// @domName SVGFilterPrimitiveStandardAttributes.width; @docsEditable true
  final AnimatedLength width;

  /// @domName SVGFilterPrimitiveStandardAttributes.x; @docsEditable true
  final AnimatedLength x;

  /// @domName SVGFilterPrimitiveStandardAttributes.y; @docsEditable true
  final AnimatedLength y;

  // From SVGStylable

  /// @domName SVGStylable.className; @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /// @domName SVGStylable.getPresentationAttribute; @docsEditable true
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEPointLightElement; @docsEditable true
class FEPointLightElement extends SvgElement native "*SVGFEPointLightElement" {

  /// @domName SVGFEPointLightElement.x; @docsEditable true
  final AnimatedNumber x;

  /// @domName SVGFEPointLightElement.y; @docsEditable true
  final AnimatedNumber y;

  /// @domName SVGFEPointLightElement.z; @docsEditable true
  final AnimatedNumber z;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFESpecularLightingElement; @docsEditable true
class FESpecularLightingElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFESpecularLightingElement" {

  /// @domName SVGFESpecularLightingElement.in1; @docsEditable true
  final AnimatedString in1;

  /// @domName SVGFESpecularLightingElement.specularConstant; @docsEditable true
  final AnimatedNumber specularConstant;

  /// @domName SVGFESpecularLightingElement.specularExponent; @docsEditable true
  final AnimatedNumber specularExponent;

  /// @domName SVGFESpecularLightingElement.surfaceScale; @docsEditable true
  final AnimatedNumber surfaceScale;

  // From SVGFilterPrimitiveStandardAttributes

  /// @domName SVGFilterPrimitiveStandardAttributes.height; @docsEditable true
  final AnimatedLength height;

  /// @domName SVGFilterPrimitiveStandardAttributes.result; @docsEditable true
  final AnimatedString result;

  /// @domName SVGFilterPrimitiveStandardAttributes.width; @docsEditable true
  final AnimatedLength width;

  /// @domName SVGFilterPrimitiveStandardAttributes.x; @docsEditable true
  final AnimatedLength x;

  /// @domName SVGFilterPrimitiveStandardAttributes.y; @docsEditable true
  final AnimatedLength y;

  // From SVGStylable

  /// @domName SVGStylable.className; @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /// @domName SVGStylable.getPresentationAttribute; @docsEditable true
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFESpotLightElement; @docsEditable true
class FESpotLightElement extends SvgElement native "*SVGFESpotLightElement" {

  /// @domName SVGFESpotLightElement.limitingConeAngle; @docsEditable true
  final AnimatedNumber limitingConeAngle;

  /// @domName SVGFESpotLightElement.pointsAtX; @docsEditable true
  final AnimatedNumber pointsAtX;

  /// @domName SVGFESpotLightElement.pointsAtY; @docsEditable true
  final AnimatedNumber pointsAtY;

  /// @domName SVGFESpotLightElement.pointsAtZ; @docsEditable true
  final AnimatedNumber pointsAtZ;

  /// @domName SVGFESpotLightElement.specularExponent; @docsEditable true
  final AnimatedNumber specularExponent;

  /// @domName SVGFESpotLightElement.x; @docsEditable true
  final AnimatedNumber x;

  /// @domName SVGFESpotLightElement.y; @docsEditable true
  final AnimatedNumber y;

  /// @domName SVGFESpotLightElement.z; @docsEditable true
  final AnimatedNumber z;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFETileElement; @docsEditable true
class FETileElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFETileElement" {

  /// @domName SVGFETileElement.in1; @docsEditable true
  final AnimatedString in1;

  // From SVGFilterPrimitiveStandardAttributes

  /// @domName SVGFilterPrimitiveStandardAttributes.height; @docsEditable true
  final AnimatedLength height;

  /// @domName SVGFilterPrimitiveStandardAttributes.result; @docsEditable true
  final AnimatedString result;

  /// @domName SVGFilterPrimitiveStandardAttributes.width; @docsEditable true
  final AnimatedLength width;

  /// @domName SVGFilterPrimitiveStandardAttributes.x; @docsEditable true
  final AnimatedLength x;

  /// @domName SVGFilterPrimitiveStandardAttributes.y; @docsEditable true
  final AnimatedLength y;

  // From SVGStylable

  /// @domName SVGStylable.className; @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /// @domName SVGStylable.getPresentationAttribute; @docsEditable true
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFETurbulenceElement; @docsEditable true
class FETurbulenceElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFETurbulenceElement" {

  static const int SVG_STITCHTYPE_NOSTITCH = 2;

  static const int SVG_STITCHTYPE_STITCH = 1;

  static const int SVG_STITCHTYPE_UNKNOWN = 0;

  static const int SVG_TURBULENCE_TYPE_FRACTALNOISE = 1;

  static const int SVG_TURBULENCE_TYPE_TURBULENCE = 2;

  static const int SVG_TURBULENCE_TYPE_UNKNOWN = 0;

  /// @domName SVGFETurbulenceElement.baseFrequencyX; @docsEditable true
  final AnimatedNumber baseFrequencyX;

  /// @domName SVGFETurbulenceElement.baseFrequencyY; @docsEditable true
  final AnimatedNumber baseFrequencyY;

  /// @domName SVGFETurbulenceElement.numOctaves; @docsEditable true
  final AnimatedInteger numOctaves;

  /// @domName SVGFETurbulenceElement.seed; @docsEditable true
  final AnimatedNumber seed;

  /// @domName SVGFETurbulenceElement.stitchTiles; @docsEditable true
  final AnimatedEnumeration stitchTiles;

  /// @domName SVGFETurbulenceElement.type; @docsEditable true
  final AnimatedEnumeration type;

  // From SVGFilterPrimitiveStandardAttributes

  /// @domName SVGFilterPrimitiveStandardAttributes.height; @docsEditable true
  final AnimatedLength height;

  /// @domName SVGFilterPrimitiveStandardAttributes.result; @docsEditable true
  final AnimatedString result;

  /// @domName SVGFilterPrimitiveStandardAttributes.width; @docsEditable true
  final AnimatedLength width;

  /// @domName SVGFilterPrimitiveStandardAttributes.x; @docsEditable true
  final AnimatedLength x;

  /// @domName SVGFilterPrimitiveStandardAttributes.y; @docsEditable true
  final AnimatedLength y;

  // From SVGStylable

  /// @domName SVGStylable.className; @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /// @domName SVGStylable.getPresentationAttribute; @docsEditable true
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFilterElement; @docsEditable true
class FilterElement extends SvgElement implements UriReference, ExternalResourcesRequired, Stylable, LangSpace native "*SVGFilterElement" {

  factory FilterElement() => _SvgElementFactoryProvider.createSvgElement_tag("filter");

  /// @domName SVGFilterElement.filterResX; @docsEditable true
  final AnimatedInteger filterResX;

  /// @domName SVGFilterElement.filterResY; @docsEditable true
  final AnimatedInteger filterResY;

  /// @domName SVGFilterElement.filterUnits; @docsEditable true
  final AnimatedEnumeration filterUnits;

  /// @domName SVGFilterElement.height; @docsEditable true
  final AnimatedLength height;

  /// @domName SVGFilterElement.primitiveUnits; @docsEditable true
  final AnimatedEnumeration primitiveUnits;

  /// @domName SVGFilterElement.width; @docsEditable true
  final AnimatedLength width;

  /// @domName SVGFilterElement.x; @docsEditable true
  final AnimatedLength x;

  /// @domName SVGFilterElement.y; @docsEditable true
  final AnimatedLength y;

  /// @domName SVGFilterElement.setFilterRes; @docsEditable true
  void setFilterRes(int filterResX, int filterResY) native;

  // From SVGExternalResourcesRequired

  /// @domName SVGExternalResourcesRequired.externalResourcesRequired; @docsEditable true
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /// @domName SVGLangSpace.xmllang; @docsEditable true
  String xmllang;

  /// @domName SVGLangSpace.xmlspace; @docsEditable true
  String xmlspace;

  // From SVGStylable

  /// @domName SVGStylable.className; @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /// @domName SVGStylable.getPresentationAttribute; @docsEditable true
  CSSValue getPresentationAttribute(String name) native;

  // From SVGURIReference

  /// @domName SVGURIReference.href; @docsEditable true
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

  /// @domName SVGStylable.getPresentationAttribute; @docsEditable true
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


/// @domName SVGFontElement; @docsEditable true
class FontElement extends SvgElement native "*SVGFontElement" {

  factory FontElement() => _SvgElementFactoryProvider.createSvgElement_tag("font");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFontFaceElement; @docsEditable true
class FontFaceElement extends SvgElement native "*SVGFontFaceElement" {

  factory FontFaceElement() => _SvgElementFactoryProvider.createSvgElement_tag("font-face");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFontFaceFormatElement; @docsEditable true
class FontFaceFormatElement extends SvgElement native "*SVGFontFaceFormatElement" {

  factory FontFaceFormatElement() => _SvgElementFactoryProvider.createSvgElement_tag("font-face-format");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFontFaceNameElement; @docsEditable true
class FontFaceNameElement extends SvgElement native "*SVGFontFaceNameElement" {

  factory FontFaceNameElement() => _SvgElementFactoryProvider.createSvgElement_tag("font-face-name");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFontFaceSrcElement; @docsEditable true
class FontFaceSrcElement extends SvgElement native "*SVGFontFaceSrcElement" {

  factory FontFaceSrcElement() => _SvgElementFactoryProvider.createSvgElement_tag("font-face-src");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFontFaceUriElement; @docsEditable true
class FontFaceUriElement extends SvgElement native "*SVGFontFaceUriElement" {

  factory FontFaceUriElement() => _SvgElementFactoryProvider.createSvgElement_tag("font-face-uri");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGForeignObjectElement; @docsEditable true
class ForeignObjectElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGForeignObjectElement" {

  factory ForeignObjectElement() => _SvgElementFactoryProvider.createSvgElement_tag("foreignObject");

  /// @domName SVGForeignObjectElement.height; @docsEditable true
  final AnimatedLength height;

  /// @domName SVGForeignObjectElement.width; @docsEditable true
  final AnimatedLength width;

  /// @domName SVGForeignObjectElement.x; @docsEditable true
  final AnimatedLength x;

  /// @domName SVGForeignObjectElement.y; @docsEditable true
  final AnimatedLength y;

  // From SVGExternalResourcesRequired

  /// @domName SVGExternalResourcesRequired.externalResourcesRequired; @docsEditable true
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /// @domName SVGLangSpace.xmllang; @docsEditable true
  String xmllang;

  /// @domName SVGLangSpace.xmlspace; @docsEditable true
  String xmlspace;

  // From SVGLocatable

  /// @domName SVGLocatable.farthestViewportElement; @docsEditable true
  final SvgElement farthestViewportElement;

  /// @domName SVGLocatable.nearestViewportElement; @docsEditable true
  final SvgElement nearestViewportElement;

  /// @domName SVGLocatable.getBBox; @docsEditable true
  Rect getBBox() native;

  /// @domName SVGLocatable.getCTM; @docsEditable true
  Matrix getCtm() native "getCTM";

  /// @domName SVGLocatable.getScreenCTM; @docsEditable true
  Matrix getScreenCtm() native "getScreenCTM";

  /// @domName SVGLocatable.getTransformToElement; @docsEditable true
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  /// @domName SVGStylable.className; @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /// @domName SVGStylable.getPresentationAttribute; @docsEditable true
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /// @domName SVGTests.requiredExtensions; @docsEditable true
  final StringList requiredExtensions;

  /// @domName SVGTests.requiredFeatures; @docsEditable true
  final StringList requiredFeatures;

  /// @domName SVGTests.systemLanguage; @docsEditable true
  final StringList systemLanguage;

  /// @domName SVGTests.hasExtension; @docsEditable true
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /// @domName SVGTransformable.transform; @docsEditable true
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGGElement; @docsEditable true
class GElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGGElement" {

  factory GElement() => _SvgElementFactoryProvider.createSvgElement_tag("g");

  // From SVGExternalResourcesRequired

  /// @domName SVGExternalResourcesRequired.externalResourcesRequired; @docsEditable true
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /// @domName SVGLangSpace.xmllang; @docsEditable true
  String xmllang;

  /// @domName SVGLangSpace.xmlspace; @docsEditable true
  String xmlspace;

  // From SVGLocatable

  /// @domName SVGLocatable.farthestViewportElement; @docsEditable true
  final SvgElement farthestViewportElement;

  /// @domName SVGLocatable.nearestViewportElement; @docsEditable true
  final SvgElement nearestViewportElement;

  /// @domName SVGLocatable.getBBox; @docsEditable true
  Rect getBBox() native;

  /// @domName SVGLocatable.getCTM; @docsEditable true
  Matrix getCtm() native "getCTM";

  /// @domName SVGLocatable.getScreenCTM; @docsEditable true
  Matrix getScreenCtm() native "getScreenCTM";

  /// @domName SVGLocatable.getTransformToElement; @docsEditable true
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  /// @domName SVGStylable.className; @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /// @domName SVGStylable.getPresentationAttribute; @docsEditable true
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /// @domName SVGTests.requiredExtensions; @docsEditable true
  final StringList requiredExtensions;

  /// @domName SVGTests.requiredFeatures; @docsEditable true
  final StringList requiredFeatures;

  /// @domName SVGTests.systemLanguage; @docsEditable true
  final StringList systemLanguage;

  /// @domName SVGTests.hasExtension; @docsEditable true
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /// @domName SVGTransformable.transform; @docsEditable true
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGGlyphElement; @docsEditable true
class GlyphElement extends SvgElement native "*SVGGlyphElement" {

  factory GlyphElement() => _SvgElementFactoryProvider.createSvgElement_tag("glyph");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGGlyphRefElement; @docsEditable true
class GlyphRefElement extends SvgElement implements UriReference, Stylable native "*SVGGlyphRefElement" {

  /// @domName SVGGlyphRefElement.dx; @docsEditable true
  num dx;

  /// @domName SVGGlyphRefElement.dy; @docsEditable true
  num dy;

  /// @domName SVGGlyphRefElement.format; @docsEditable true
  String format;

  /// @domName SVGGlyphRefElement.glyphRef; @docsEditable true
  String glyphRef;

  /// @domName SVGGlyphRefElement.x; @docsEditable true
  num x;

  /// @domName SVGGlyphRefElement.y; @docsEditable true
  num y;

  // From SVGStylable

  /// @domName SVGStylable.className; @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /// @domName SVGStylable.getPresentationAttribute; @docsEditable true
  CSSValue getPresentationAttribute(String name) native;

  // From SVGURIReference

  /// @domName SVGURIReference.href; @docsEditable true
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGGradientElement; @docsEditable true
class GradientElement extends SvgElement implements UriReference, ExternalResourcesRequired, Stylable native "*SVGGradientElement" {

  static const int SVG_SPREADMETHOD_PAD = 1;

  static const int SVG_SPREADMETHOD_REFLECT = 2;

  static const int SVG_SPREADMETHOD_REPEAT = 3;

  static const int SVG_SPREADMETHOD_UNKNOWN = 0;

  /// @domName SVGGradientElement.gradientTransform; @docsEditable true
  final AnimatedTransformList gradientTransform;

  /// @domName SVGGradientElement.gradientUnits; @docsEditable true
  final AnimatedEnumeration gradientUnits;

  /// @domName SVGGradientElement.spreadMethod; @docsEditable true
  final AnimatedEnumeration spreadMethod;

  // From SVGExternalResourcesRequired

  /// @domName SVGExternalResourcesRequired.externalResourcesRequired; @docsEditable true
  final AnimatedBoolean externalResourcesRequired;

  // From SVGStylable

  /// @domName SVGStylable.className; @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /// @domName SVGStylable.getPresentationAttribute; @docsEditable true
  CSSValue getPresentationAttribute(String name) native;

  // From SVGURIReference

  /// @domName SVGURIReference.href; @docsEditable true
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGHKernElement; @docsEditable true
class HKernElement extends SvgElement native "*SVGHKernElement" {

  factory HKernElement() => _SvgElementFactoryProvider.createSvgElement_tag("hkern");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGImageElement; @docsEditable true
class ImageElement extends SvgElement implements Transformable, Tests, UriReference, Stylable, ExternalResourcesRequired, LangSpace native "*SVGImageElement" {

  factory ImageElement() => _SvgElementFactoryProvider.createSvgElement_tag("image");

  /// @domName SVGImageElement.height; @docsEditable true
  final AnimatedLength height;

  /// @domName SVGImageElement.preserveAspectRatio; @docsEditable true
  final AnimatedPreserveAspectRatio preserveAspectRatio;

  /// @domName SVGImageElement.width; @docsEditable true
  final AnimatedLength width;

  /// @domName SVGImageElement.x; @docsEditable true
  final AnimatedLength x;

  /// @domName SVGImageElement.y; @docsEditable true
  final AnimatedLength y;

  // From SVGExternalResourcesRequired

  /// @domName SVGExternalResourcesRequired.externalResourcesRequired; @docsEditable true
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /// @domName SVGLangSpace.xmllang; @docsEditable true
  String xmllang;

  /// @domName SVGLangSpace.xmlspace; @docsEditable true
  String xmlspace;

  // From SVGLocatable

  /// @domName SVGLocatable.farthestViewportElement; @docsEditable true
  final SvgElement farthestViewportElement;

  /// @domName SVGLocatable.nearestViewportElement; @docsEditable true
  final SvgElement nearestViewportElement;

  /// @domName SVGLocatable.getBBox; @docsEditable true
  Rect getBBox() native;

  /// @domName SVGLocatable.getCTM; @docsEditable true
  Matrix getCtm() native "getCTM";

  /// @domName SVGLocatable.getScreenCTM; @docsEditable true
  Matrix getScreenCtm() native "getScreenCTM";

  /// @domName SVGLocatable.getTransformToElement; @docsEditable true
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  /// @domName SVGStylable.className; @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /// @domName SVGStylable.getPresentationAttribute; @docsEditable true
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /// @domName SVGTests.requiredExtensions; @docsEditable true
  final StringList requiredExtensions;

  /// @domName SVGTests.requiredFeatures; @docsEditable true
  final StringList requiredFeatures;

  /// @domName SVGTests.systemLanguage; @docsEditable true
  final StringList systemLanguage;

  /// @domName SVGTests.hasExtension; @docsEditable true
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /// @domName SVGTransformable.transform; @docsEditable true
  final AnimatedTransformList transform;

  // From SVGURIReference

  /// @domName SVGURIReference.href; @docsEditable true
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


/// @domName SVGLength; @docsEditable true
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

  /// @domName SVGLength.unitType; @docsEditable true
  final int unitType;

  /// @domName SVGLength.value; @docsEditable true
  num value;

  /// @domName SVGLength.valueAsString; @docsEditable true
  String valueAsString;

  /// @domName SVGLength.valueInSpecifiedUnits; @docsEditable true
  num valueInSpecifiedUnits;

  /// @domName SVGLength.convertToSpecifiedUnits; @docsEditable true
  void convertToSpecifiedUnits(int unitType) native;

  /// @domName SVGLength.newValueSpecifiedUnits; @docsEditable true
  void newValueSpecifiedUnits(int unitType, num valueInSpecifiedUnits) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGLengthList; @docsEditable true
class LengthList implements JavaScriptIndexingBehavior, List<Length> native "*SVGLengthList" {

  /// @domName SVGLengthList.numberOfItems; @docsEditable true
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

  /// @domName SVGLengthList.appendItem; @docsEditable true
  Length appendItem(Length item) native;

  /// @domName SVGLengthList.clear; @docsEditable true
  void clear() native;

  /// @domName SVGLengthList.getItem; @docsEditable true
  Length getItem(int index) native;

  /// @domName SVGLengthList.initialize; @docsEditable true
  Length initialize(Length item) native;

  /// @domName SVGLengthList.insertItemBefore; @docsEditable true
  Length insertItemBefore(Length item, int index) native;

  /// @domName SVGLengthList.removeItem; @docsEditable true
  Length removeItem(int index) native;

  /// @domName SVGLengthList.replaceItem; @docsEditable true
  Length replaceItem(Length item, int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGLineElement; @docsEditable true
class LineElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGLineElement" {

  factory LineElement() => _SvgElementFactoryProvider.createSvgElement_tag("line");

  /// @domName SVGLineElement.x1; @docsEditable true
  final AnimatedLength x1;

  /// @domName SVGLineElement.x2; @docsEditable true
  final AnimatedLength x2;

  /// @domName SVGLineElement.y1; @docsEditable true
  final AnimatedLength y1;

  /// @domName SVGLineElement.y2; @docsEditable true
  final AnimatedLength y2;

  // From SVGExternalResourcesRequired

  /// @domName SVGExternalResourcesRequired.externalResourcesRequired; @docsEditable true
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /// @domName SVGLangSpace.xmllang; @docsEditable true
  String xmllang;

  /// @domName SVGLangSpace.xmlspace; @docsEditable true
  String xmlspace;

  // From SVGLocatable

  /// @domName SVGLocatable.farthestViewportElement; @docsEditable true
  final SvgElement farthestViewportElement;

  /// @domName SVGLocatable.nearestViewportElement; @docsEditable true
  final SvgElement nearestViewportElement;

  /// @domName SVGLocatable.getBBox; @docsEditable true
  Rect getBBox() native;

  /// @domName SVGLocatable.getCTM; @docsEditable true
  Matrix getCtm() native "getCTM";

  /// @domName SVGLocatable.getScreenCTM; @docsEditable true
  Matrix getScreenCtm() native "getScreenCTM";

  /// @domName SVGLocatable.getTransformToElement; @docsEditable true
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  /// @domName SVGStylable.className; @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /// @domName SVGStylable.getPresentationAttribute; @docsEditable true
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /// @domName SVGTests.requiredExtensions; @docsEditable true
  final StringList requiredExtensions;

  /// @domName SVGTests.requiredFeatures; @docsEditable true
  final StringList requiredFeatures;

  /// @domName SVGTests.systemLanguage; @docsEditable true
  final StringList systemLanguage;

  /// @domName SVGTests.hasExtension; @docsEditable true
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /// @domName SVGTransformable.transform; @docsEditable true
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGLinearGradientElement; @docsEditable true
class LinearGradientElement extends GradientElement native "*SVGLinearGradientElement" {

  factory LinearGradientElement() => _SvgElementFactoryProvider.createSvgElement_tag("linearGradient");

  /// @domName SVGLinearGradientElement.x1; @docsEditable true
  final AnimatedLength x1;

  /// @domName SVGLinearGradientElement.x2; @docsEditable true
  final AnimatedLength x2;

  /// @domName SVGLinearGradientElement.y1; @docsEditable true
  final AnimatedLength y1;

  /// @domName SVGLinearGradientElement.y2; @docsEditable true
  final AnimatedLength y2;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGLocatable
abstract class Locatable {

  SvgElement farthestViewportElement;

  SvgElement nearestViewportElement;

  /// @domName SVGLocatable.getBBox; @docsEditable true
  Rect getBBox();

  /// @domName SVGLocatable.getCTM; @docsEditable true
  Matrix getCTM();

  /// @domName SVGLocatable.getScreenCTM; @docsEditable true
  Matrix getScreenCTM();

  /// @domName SVGLocatable.getTransformToElement; @docsEditable true
  Matrix getTransformToElement(SvgElement element);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGMPathElement; @docsEditable true
class MPathElement extends SvgElement implements UriReference, ExternalResourcesRequired native "*SVGMPathElement" {

  factory MPathElement() => _SvgElementFactoryProvider.createSvgElement_tag("mpath");

  // From SVGExternalResourcesRequired

  /// @domName SVGExternalResourcesRequired.externalResourcesRequired; @docsEditable true
  final AnimatedBoolean externalResourcesRequired;

  // From SVGURIReference

  /// @domName SVGURIReference.href; @docsEditable true
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGMarkerElement; @docsEditable true
class MarkerElement extends SvgElement implements FitToViewBox, ExternalResourcesRequired, Stylable, LangSpace native "*SVGMarkerElement" {

  factory MarkerElement() => _SvgElementFactoryProvider.createSvgElement_tag("marker");

  static const int SVG_MARKERUNITS_STROKEWIDTH = 2;

  static const int SVG_MARKERUNITS_UNKNOWN = 0;

  static const int SVG_MARKERUNITS_USERSPACEONUSE = 1;

  static const int SVG_MARKER_ORIENT_ANGLE = 2;

  static const int SVG_MARKER_ORIENT_AUTO = 1;

  static const int SVG_MARKER_ORIENT_UNKNOWN = 0;

  /// @domName SVGMarkerElement.markerHeight; @docsEditable true
  final AnimatedLength markerHeight;

  /// @domName SVGMarkerElement.markerUnits; @docsEditable true
  final AnimatedEnumeration markerUnits;

  /// @domName SVGMarkerElement.markerWidth; @docsEditable true
  final AnimatedLength markerWidth;

  /// @domName SVGMarkerElement.orientAngle; @docsEditable true
  final AnimatedAngle orientAngle;

  /// @domName SVGMarkerElement.orientType; @docsEditable true
  final AnimatedEnumeration orientType;

  /// @domName SVGMarkerElement.refX; @docsEditable true
  final AnimatedLength refX;

  /// @domName SVGMarkerElement.refY; @docsEditable true
  final AnimatedLength refY;

  /// @domName SVGMarkerElement.setOrientToAngle; @docsEditable true
  void setOrientToAngle(Angle angle) native;

  /// @domName SVGMarkerElement.setOrientToAuto; @docsEditable true
  void setOrientToAuto() native;

  // From SVGExternalResourcesRequired

  /// @domName SVGExternalResourcesRequired.externalResourcesRequired; @docsEditable true
  final AnimatedBoolean externalResourcesRequired;

  // From SVGFitToViewBox

  /// @domName SVGFitToViewBox.preserveAspectRatio; @docsEditable true
  final AnimatedPreserveAspectRatio preserveAspectRatio;

  /// @domName SVGFitToViewBox.viewBox; @docsEditable true
  final AnimatedRect viewBox;

  // From SVGLangSpace

  /// @domName SVGLangSpace.xmllang; @docsEditable true
  String xmllang;

  /// @domName SVGLangSpace.xmlspace; @docsEditable true
  String xmlspace;

  // From SVGStylable

  /// @domName SVGStylable.className; @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /// @domName SVGStylable.getPresentationAttribute; @docsEditable true
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGMaskElement; @docsEditable true
class MaskElement extends SvgElement implements Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGMaskElement" {

  factory MaskElement() => _SvgElementFactoryProvider.createSvgElement_tag("mask");

  /// @domName SVGMaskElement.height; @docsEditable true
  final AnimatedLength height;

  /// @domName SVGMaskElement.maskContentUnits; @docsEditable true
  final AnimatedEnumeration maskContentUnits;

  /// @domName SVGMaskElement.maskUnits; @docsEditable true
  final AnimatedEnumeration maskUnits;

  /// @domName SVGMaskElement.width; @docsEditable true
  final AnimatedLength width;

  /// @domName SVGMaskElement.x; @docsEditable true
  final AnimatedLength x;

  /// @domName SVGMaskElement.y; @docsEditable true
  final AnimatedLength y;

  // From SVGExternalResourcesRequired

  /// @domName SVGExternalResourcesRequired.externalResourcesRequired; @docsEditable true
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /// @domName SVGLangSpace.xmllang; @docsEditable true
  String xmllang;

  /// @domName SVGLangSpace.xmlspace; @docsEditable true
  String xmlspace;

  // From SVGStylable

  /// @domName SVGStylable.className; @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /// @domName SVGStylable.getPresentationAttribute; @docsEditable true
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /// @domName SVGTests.requiredExtensions; @docsEditable true
  final StringList requiredExtensions;

  /// @domName SVGTests.requiredFeatures; @docsEditable true
  final StringList requiredFeatures;

  /// @domName SVGTests.systemLanguage; @docsEditable true
  final StringList systemLanguage;

  /// @domName SVGTests.hasExtension; @docsEditable true
  bool hasExtension(String extension) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGMatrix; @docsEditable true
class Matrix native "*SVGMatrix" {

  /// @domName SVGMatrix.a; @docsEditable true
  num a;

  /// @domName SVGMatrix.b; @docsEditable true
  num b;

  /// @domName SVGMatrix.c; @docsEditable true
  num c;

  /// @domName SVGMatrix.d; @docsEditable true
  num d;

  /// @domName SVGMatrix.e; @docsEditable true
  num e;

  /// @domName SVGMatrix.f; @docsEditable true
  num f;

  /// @domName SVGMatrix.flipX; @docsEditable true
  Matrix flipX() native;

  /// @domName SVGMatrix.flipY; @docsEditable true
  Matrix flipY() native;

  /// @domName SVGMatrix.inverse; @docsEditable true
  Matrix inverse() native;

  /// @domName SVGMatrix.multiply; @docsEditable true
  Matrix multiply(Matrix secondMatrix) native;

  /// @domName SVGMatrix.rotate; @docsEditable true
  Matrix rotate(num angle) native;

  /// @domName SVGMatrix.rotateFromVector; @docsEditable true
  Matrix rotateFromVector(num x, num y) native;

  /// @domName SVGMatrix.scale; @docsEditable true
  Matrix scale(num scaleFactor) native;

  /// @domName SVGMatrix.scaleNonUniform; @docsEditable true
  Matrix scaleNonUniform(num scaleFactorX, num scaleFactorY) native;

  /// @domName SVGMatrix.skewX; @docsEditable true
  Matrix skewX(num angle) native;

  /// @domName SVGMatrix.skewY; @docsEditable true
  Matrix skewY(num angle) native;

  /// @domName SVGMatrix.translate; @docsEditable true
  Matrix translate(num x, num y) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGMetadataElement; @docsEditable true
class MetadataElement extends SvgElement native "*SVGMetadataElement" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGMissingGlyphElement; @docsEditable true
class MissingGlyphElement extends SvgElement native "*SVGMissingGlyphElement" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGNumber; @docsEditable true
class Number native "*SVGNumber" {

  /// @domName SVGNumber.value; @docsEditable true
  num value;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGNumberList; @docsEditable true
class NumberList implements JavaScriptIndexingBehavior, List<Number> native "*SVGNumberList" {

  /// @domName SVGNumberList.numberOfItems; @docsEditable true
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

  /// @domName SVGNumberList.appendItem; @docsEditable true
  Number appendItem(Number item) native;

  /// @domName SVGNumberList.clear; @docsEditable true
  void clear() native;

  /// @domName SVGNumberList.getItem; @docsEditable true
  Number getItem(int index) native;

  /// @domName SVGNumberList.initialize; @docsEditable true
  Number initialize(Number item) native;

  /// @domName SVGNumberList.insertItemBefore; @docsEditable true
  Number insertItemBefore(Number item, int index) native;

  /// @domName SVGNumberList.removeItem; @docsEditable true
  Number removeItem(int index) native;

  /// @domName SVGNumberList.replaceItem; @docsEditable true
  Number replaceItem(Number item, int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPaint; @docsEditable true
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

  /// @domName SVGPaint.paintType; @docsEditable true
  final int paintType;

  /// @domName SVGPaint.uri; @docsEditable true
  final String uri;

  /// @domName SVGPaint.setPaint; @docsEditable true
  void setPaint(int paintType, String uri, String rgbColor, String iccColor) native;

  /// @domName SVGPaint.setUri; @docsEditable true
  void setUri(String uri) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathElement; @docsEditable true
class PathElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGPathElement" {

  factory PathElement() => _SvgElementFactoryProvider.createSvgElement_tag("path");

  /// @domName SVGPathElement.animatedNormalizedPathSegList; @docsEditable true
  final PathSegList animatedNormalizedPathSegList;

  /// @domName SVGPathElement.animatedPathSegList; @docsEditable true
  final PathSegList animatedPathSegList;

  /// @domName SVGPathElement.normalizedPathSegList; @docsEditable true
  final PathSegList normalizedPathSegList;

  /// @domName SVGPathElement.pathLength; @docsEditable true
  final AnimatedNumber pathLength;

  /// @domName SVGPathElement.pathSegList; @docsEditable true
  final PathSegList pathSegList;

  /// @domName SVGPathElement.createSVGPathSegArcAbs; @docsEditable true
  PathSegArcAbs createSvgPathSegArcAbs(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) native "createSVGPathSegArcAbs";

  /// @domName SVGPathElement.createSVGPathSegArcRel; @docsEditable true
  PathSegArcRel createSvgPathSegArcRel(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) native "createSVGPathSegArcRel";

  /// @domName SVGPathElement.createSVGPathSegClosePath; @docsEditable true
  PathSegClosePath createSvgPathSegClosePath() native "createSVGPathSegClosePath";

  /// @domName SVGPathElement.createSVGPathSegCurvetoCubicAbs; @docsEditable true
  PathSegCurvetoCubicAbs createSvgPathSegCurvetoCubicAbs(num x, num y, num x1, num y1, num x2, num y2) native "createSVGPathSegCurvetoCubicAbs";

  /// @domName SVGPathElement.createSVGPathSegCurvetoCubicRel; @docsEditable true
  PathSegCurvetoCubicRel createSvgPathSegCurvetoCubicRel(num x, num y, num x1, num y1, num x2, num y2) native "createSVGPathSegCurvetoCubicRel";

  /// @domName SVGPathElement.createSVGPathSegCurvetoCubicSmoothAbs; @docsEditable true
  PathSegCurvetoCubicSmoothAbs createSvgPathSegCurvetoCubicSmoothAbs(num x, num y, num x2, num y2) native "createSVGPathSegCurvetoCubicSmoothAbs";

  /// @domName SVGPathElement.createSVGPathSegCurvetoCubicSmoothRel; @docsEditable true
  PathSegCurvetoCubicSmoothRel createSvgPathSegCurvetoCubicSmoothRel(num x, num y, num x2, num y2) native "createSVGPathSegCurvetoCubicSmoothRel";

  /// @domName SVGPathElement.createSVGPathSegCurvetoQuadraticAbs; @docsEditable true
  PathSegCurvetoQuadraticAbs createSvgPathSegCurvetoQuadraticAbs(num x, num y, num x1, num y1) native "createSVGPathSegCurvetoQuadraticAbs";

  /// @domName SVGPathElement.createSVGPathSegCurvetoQuadraticRel; @docsEditable true
  PathSegCurvetoQuadraticRel createSvgPathSegCurvetoQuadraticRel(num x, num y, num x1, num y1) native "createSVGPathSegCurvetoQuadraticRel";

  /// @domName SVGPathElement.createSVGPathSegCurvetoQuadraticSmoothAbs; @docsEditable true
  PathSegCurvetoQuadraticSmoothAbs createSvgPathSegCurvetoQuadraticSmoothAbs(num x, num y) native "createSVGPathSegCurvetoQuadraticSmoothAbs";

  /// @domName SVGPathElement.createSVGPathSegCurvetoQuadraticSmoothRel; @docsEditable true
  PathSegCurvetoQuadraticSmoothRel createSvgPathSegCurvetoQuadraticSmoothRel(num x, num y) native "createSVGPathSegCurvetoQuadraticSmoothRel";

  /// @domName SVGPathElement.createSVGPathSegLinetoAbs; @docsEditable true
  PathSegLinetoAbs createSvgPathSegLinetoAbs(num x, num y) native "createSVGPathSegLinetoAbs";

  /// @domName SVGPathElement.createSVGPathSegLinetoHorizontalAbs; @docsEditable true
  PathSegLinetoHorizontalAbs createSvgPathSegLinetoHorizontalAbs(num x) native "createSVGPathSegLinetoHorizontalAbs";

  /// @domName SVGPathElement.createSVGPathSegLinetoHorizontalRel; @docsEditable true
  PathSegLinetoHorizontalRel createSvgPathSegLinetoHorizontalRel(num x) native "createSVGPathSegLinetoHorizontalRel";

  /// @domName SVGPathElement.createSVGPathSegLinetoRel; @docsEditable true
  PathSegLinetoRel createSvgPathSegLinetoRel(num x, num y) native "createSVGPathSegLinetoRel";

  /// @domName SVGPathElement.createSVGPathSegLinetoVerticalAbs; @docsEditable true
  PathSegLinetoVerticalAbs createSvgPathSegLinetoVerticalAbs(num y) native "createSVGPathSegLinetoVerticalAbs";

  /// @domName SVGPathElement.createSVGPathSegLinetoVerticalRel; @docsEditable true
  PathSegLinetoVerticalRel createSvgPathSegLinetoVerticalRel(num y) native "createSVGPathSegLinetoVerticalRel";

  /// @domName SVGPathElement.createSVGPathSegMovetoAbs; @docsEditable true
  PathSegMovetoAbs createSvgPathSegMovetoAbs(num x, num y) native "createSVGPathSegMovetoAbs";

  /// @domName SVGPathElement.createSVGPathSegMovetoRel; @docsEditable true
  PathSegMovetoRel createSvgPathSegMovetoRel(num x, num y) native "createSVGPathSegMovetoRel";

  /// @domName SVGPathElement.getPathSegAtLength; @docsEditable true
  int getPathSegAtLength(num distance) native;

  /// @domName SVGPathElement.getPointAtLength; @docsEditable true
  Point getPointAtLength(num distance) native;

  /// @domName SVGPathElement.getTotalLength; @docsEditable true
  num getTotalLength() native;

  // From SVGExternalResourcesRequired

  /// @domName SVGExternalResourcesRequired.externalResourcesRequired; @docsEditable true
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /// @domName SVGLangSpace.xmllang; @docsEditable true
  String xmllang;

  /// @domName SVGLangSpace.xmlspace; @docsEditable true
  String xmlspace;

  // From SVGLocatable

  /// @domName SVGLocatable.farthestViewportElement; @docsEditable true
  final SvgElement farthestViewportElement;

  /// @domName SVGLocatable.nearestViewportElement; @docsEditable true
  final SvgElement nearestViewportElement;

  /// @domName SVGLocatable.getBBox; @docsEditable true
  Rect getBBox() native;

  /// @domName SVGLocatable.getCTM; @docsEditable true
  Matrix getCtm() native "getCTM";

  /// @domName SVGLocatable.getScreenCTM; @docsEditable true
  Matrix getScreenCtm() native "getScreenCTM";

  /// @domName SVGLocatable.getTransformToElement; @docsEditable true
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  /// @domName SVGStylable.className; @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /// @domName SVGStylable.getPresentationAttribute; @docsEditable true
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /// @domName SVGTests.requiredExtensions; @docsEditable true
  final StringList requiredExtensions;

  /// @domName SVGTests.requiredFeatures; @docsEditable true
  final StringList requiredFeatures;

  /// @domName SVGTests.systemLanguage; @docsEditable true
  final StringList systemLanguage;

  /// @domName SVGTests.hasExtension; @docsEditable true
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /// @domName SVGTransformable.transform; @docsEditable true
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSeg; @docsEditable true
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

  /// @domName SVGPathSeg.pathSegType; @docsEditable true
  final int pathSegType;

  /// @domName SVGPathSeg.pathSegTypeAsLetter; @docsEditable true
  final String pathSegTypeAsLetter;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegArcAbs; @docsEditable true
class PathSegArcAbs extends PathSeg native "*SVGPathSegArcAbs" {

  /// @domName SVGPathSegArcAbs.angle; @docsEditable true
  num angle;

  /// @domName SVGPathSegArcAbs.largeArcFlag; @docsEditable true
  bool largeArcFlag;

  /// @domName SVGPathSegArcAbs.r1; @docsEditable true
  num r1;

  /// @domName SVGPathSegArcAbs.r2; @docsEditable true
  num r2;

  /// @domName SVGPathSegArcAbs.sweepFlag; @docsEditable true
  bool sweepFlag;

  /// @domName SVGPathSegArcAbs.x; @docsEditable true
  num x;

  /// @domName SVGPathSegArcAbs.y; @docsEditable true
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegArcRel; @docsEditable true
class PathSegArcRel extends PathSeg native "*SVGPathSegArcRel" {

  /// @domName SVGPathSegArcRel.angle; @docsEditable true
  num angle;

  /// @domName SVGPathSegArcRel.largeArcFlag; @docsEditable true
  bool largeArcFlag;

  /// @domName SVGPathSegArcRel.r1; @docsEditable true
  num r1;

  /// @domName SVGPathSegArcRel.r2; @docsEditable true
  num r2;

  /// @domName SVGPathSegArcRel.sweepFlag; @docsEditable true
  bool sweepFlag;

  /// @domName SVGPathSegArcRel.x; @docsEditable true
  num x;

  /// @domName SVGPathSegArcRel.y; @docsEditable true
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegClosePath; @docsEditable true
class PathSegClosePath extends PathSeg native "*SVGPathSegClosePath" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegCurvetoCubicAbs; @docsEditable true
class PathSegCurvetoCubicAbs extends PathSeg native "*SVGPathSegCurvetoCubicAbs" {

  /// @domName SVGPathSegCurvetoCubicAbs.x; @docsEditable true
  num x;

  /// @domName SVGPathSegCurvetoCubicAbs.x1; @docsEditable true
  num x1;

  /// @domName SVGPathSegCurvetoCubicAbs.x2; @docsEditable true
  num x2;

  /// @domName SVGPathSegCurvetoCubicAbs.y; @docsEditable true
  num y;

  /// @domName SVGPathSegCurvetoCubicAbs.y1; @docsEditable true
  num y1;

  /// @domName SVGPathSegCurvetoCubicAbs.y2; @docsEditable true
  num y2;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegCurvetoCubicRel; @docsEditable true
class PathSegCurvetoCubicRel extends PathSeg native "*SVGPathSegCurvetoCubicRel" {

  /// @domName SVGPathSegCurvetoCubicRel.x; @docsEditable true
  num x;

  /// @domName SVGPathSegCurvetoCubicRel.x1; @docsEditable true
  num x1;

  /// @domName SVGPathSegCurvetoCubicRel.x2; @docsEditable true
  num x2;

  /// @domName SVGPathSegCurvetoCubicRel.y; @docsEditable true
  num y;

  /// @domName SVGPathSegCurvetoCubicRel.y1; @docsEditable true
  num y1;

  /// @domName SVGPathSegCurvetoCubicRel.y2; @docsEditable true
  num y2;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegCurvetoCubicSmoothAbs; @docsEditable true
class PathSegCurvetoCubicSmoothAbs extends PathSeg native "*SVGPathSegCurvetoCubicSmoothAbs" {

  /// @domName SVGPathSegCurvetoCubicSmoothAbs.x; @docsEditable true
  num x;

  /// @domName SVGPathSegCurvetoCubicSmoothAbs.x2; @docsEditable true
  num x2;

  /// @domName SVGPathSegCurvetoCubicSmoothAbs.y; @docsEditable true
  num y;

  /// @domName SVGPathSegCurvetoCubicSmoothAbs.y2; @docsEditable true
  num y2;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegCurvetoCubicSmoothRel; @docsEditable true
class PathSegCurvetoCubicSmoothRel extends PathSeg native "*SVGPathSegCurvetoCubicSmoothRel" {

  /// @domName SVGPathSegCurvetoCubicSmoothRel.x; @docsEditable true
  num x;

  /// @domName SVGPathSegCurvetoCubicSmoothRel.x2; @docsEditable true
  num x2;

  /// @domName SVGPathSegCurvetoCubicSmoothRel.y; @docsEditable true
  num y;

  /// @domName SVGPathSegCurvetoCubicSmoothRel.y2; @docsEditable true
  num y2;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegCurvetoQuadraticAbs; @docsEditable true
class PathSegCurvetoQuadraticAbs extends PathSeg native "*SVGPathSegCurvetoQuadraticAbs" {

  /// @domName SVGPathSegCurvetoQuadraticAbs.x; @docsEditable true
  num x;

  /// @domName SVGPathSegCurvetoQuadraticAbs.x1; @docsEditable true
  num x1;

  /// @domName SVGPathSegCurvetoQuadraticAbs.y; @docsEditable true
  num y;

  /// @domName SVGPathSegCurvetoQuadraticAbs.y1; @docsEditable true
  num y1;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegCurvetoQuadraticRel; @docsEditable true
class PathSegCurvetoQuadraticRel extends PathSeg native "*SVGPathSegCurvetoQuadraticRel" {

  /// @domName SVGPathSegCurvetoQuadraticRel.x; @docsEditable true
  num x;

  /// @domName SVGPathSegCurvetoQuadraticRel.x1; @docsEditable true
  num x1;

  /// @domName SVGPathSegCurvetoQuadraticRel.y; @docsEditable true
  num y;

  /// @domName SVGPathSegCurvetoQuadraticRel.y1; @docsEditable true
  num y1;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegCurvetoQuadraticSmoothAbs; @docsEditable true
class PathSegCurvetoQuadraticSmoothAbs extends PathSeg native "*SVGPathSegCurvetoQuadraticSmoothAbs" {

  /// @domName SVGPathSegCurvetoQuadraticSmoothAbs.x; @docsEditable true
  num x;

  /// @domName SVGPathSegCurvetoQuadraticSmoothAbs.y; @docsEditable true
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegCurvetoQuadraticSmoothRel; @docsEditable true
class PathSegCurvetoQuadraticSmoothRel extends PathSeg native "*SVGPathSegCurvetoQuadraticSmoothRel" {

  /// @domName SVGPathSegCurvetoQuadraticSmoothRel.x; @docsEditable true
  num x;

  /// @domName SVGPathSegCurvetoQuadraticSmoothRel.y; @docsEditable true
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegLinetoAbs; @docsEditable true
class PathSegLinetoAbs extends PathSeg native "*SVGPathSegLinetoAbs" {

  /// @domName SVGPathSegLinetoAbs.x; @docsEditable true
  num x;

  /// @domName SVGPathSegLinetoAbs.y; @docsEditable true
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegLinetoHorizontalAbs; @docsEditable true
class PathSegLinetoHorizontalAbs extends PathSeg native "*SVGPathSegLinetoHorizontalAbs" {

  /// @domName SVGPathSegLinetoHorizontalAbs.x; @docsEditable true
  num x;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegLinetoHorizontalRel; @docsEditable true
class PathSegLinetoHorizontalRel extends PathSeg native "*SVGPathSegLinetoHorizontalRel" {

  /// @domName SVGPathSegLinetoHorizontalRel.x; @docsEditable true
  num x;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegLinetoRel; @docsEditable true
class PathSegLinetoRel extends PathSeg native "*SVGPathSegLinetoRel" {

  /// @domName SVGPathSegLinetoRel.x; @docsEditable true
  num x;

  /// @domName SVGPathSegLinetoRel.y; @docsEditable true
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegLinetoVerticalAbs; @docsEditable true
class PathSegLinetoVerticalAbs extends PathSeg native "*SVGPathSegLinetoVerticalAbs" {

  /// @domName SVGPathSegLinetoVerticalAbs.y; @docsEditable true
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegLinetoVerticalRel; @docsEditable true
class PathSegLinetoVerticalRel extends PathSeg native "*SVGPathSegLinetoVerticalRel" {

  /// @domName SVGPathSegLinetoVerticalRel.y; @docsEditable true
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegList; @docsEditable true
class PathSegList implements JavaScriptIndexingBehavior, List<PathSeg> native "*SVGPathSegList" {

  /// @domName SVGPathSegList.numberOfItems; @docsEditable true
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

  /// @domName SVGPathSegList.appendItem; @docsEditable true
  PathSeg appendItem(PathSeg newItem) native;

  /// @domName SVGPathSegList.clear; @docsEditable true
  void clear() native;

  /// @domName SVGPathSegList.getItem; @docsEditable true
  PathSeg getItem(int index) native;

  /// @domName SVGPathSegList.initialize; @docsEditable true
  PathSeg initialize(PathSeg newItem) native;

  /// @domName SVGPathSegList.insertItemBefore; @docsEditable true
  PathSeg insertItemBefore(PathSeg newItem, int index) native;

  /// @domName SVGPathSegList.removeItem; @docsEditable true
  PathSeg removeItem(int index) native;

  /// @domName SVGPathSegList.replaceItem; @docsEditable true
  PathSeg replaceItem(PathSeg newItem, int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegMovetoAbs; @docsEditable true
class PathSegMovetoAbs extends PathSeg native "*SVGPathSegMovetoAbs" {

  /// @domName SVGPathSegMovetoAbs.x; @docsEditable true
  num x;

  /// @domName SVGPathSegMovetoAbs.y; @docsEditable true
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegMovetoRel; @docsEditable true
class PathSegMovetoRel extends PathSeg native "*SVGPathSegMovetoRel" {

  /// @domName SVGPathSegMovetoRel.x; @docsEditable true
  num x;

  /// @domName SVGPathSegMovetoRel.y; @docsEditable true
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPatternElement; @docsEditable true
class PatternElement extends SvgElement implements FitToViewBox, Tests, UriReference, Stylable, ExternalResourcesRequired, LangSpace native "*SVGPatternElement" {

  factory PatternElement() => _SvgElementFactoryProvider.createSvgElement_tag("pattern");

  /// @domName SVGPatternElement.height; @docsEditable true
  final AnimatedLength height;

  /// @domName SVGPatternElement.patternContentUnits; @docsEditable true
  final AnimatedEnumeration patternContentUnits;

  /// @domName SVGPatternElement.patternTransform; @docsEditable true
  final AnimatedTransformList patternTransform;

  /// @domName SVGPatternElement.patternUnits; @docsEditable true
  final AnimatedEnumeration patternUnits;

  /// @domName SVGPatternElement.width; @docsEditable true
  final AnimatedLength width;

  /// @domName SVGPatternElement.x; @docsEditable true
  final AnimatedLength x;

  /// @domName SVGPatternElement.y; @docsEditable true
  final AnimatedLength y;

  // From SVGExternalResourcesRequired

  /// @domName SVGExternalResourcesRequired.externalResourcesRequired; @docsEditable true
  final AnimatedBoolean externalResourcesRequired;

  // From SVGFitToViewBox

  /// @domName SVGFitToViewBox.preserveAspectRatio; @docsEditable true
  final AnimatedPreserveAspectRatio preserveAspectRatio;

  /// @domName SVGFitToViewBox.viewBox; @docsEditable true
  final AnimatedRect viewBox;

  // From SVGLangSpace

  /// @domName SVGLangSpace.xmllang; @docsEditable true
  String xmllang;

  /// @domName SVGLangSpace.xmlspace; @docsEditable true
  String xmlspace;

  // From SVGStylable

  /// @domName SVGStylable.className; @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /// @domName SVGStylable.getPresentationAttribute; @docsEditable true
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /// @domName SVGTests.requiredExtensions; @docsEditable true
  final StringList requiredExtensions;

  /// @domName SVGTests.requiredFeatures; @docsEditable true
  final StringList requiredFeatures;

  /// @domName SVGTests.systemLanguage; @docsEditable true
  final StringList systemLanguage;

  /// @domName SVGTests.hasExtension; @docsEditable true
  bool hasExtension(String extension) native;

  // From SVGURIReference

  /// @domName SVGURIReference.href; @docsEditable true
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


class Point native "*SVGPoint" {
  factory Point(num x, num y) => _PointFactoryProvider.createPoint(x, y);

  /// @domName SVGPoint.x; @docsEditable true
  num x;

  /// @domName SVGPoint.y; @docsEditable true
  num y;

  /// @domName SVGPoint.matrixTransform; @docsEditable true
  Point matrixTransform(Matrix matrix) native;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPointList; @docsEditable true
class PointList native "*SVGPointList" {

  /// @domName SVGPointList.numberOfItems; @docsEditable true
  final int numberOfItems;

  /// @domName SVGPointList.appendItem; @docsEditable true
  Point appendItem(Point item) native;

  /// @domName SVGPointList.clear; @docsEditable true
  void clear() native;

  /// @domName SVGPointList.getItem; @docsEditable true
  Point getItem(int index) native;

  /// @domName SVGPointList.initialize; @docsEditable true
  Point initialize(Point item) native;

  /// @domName SVGPointList.insertItemBefore; @docsEditable true
  Point insertItemBefore(Point item, int index) native;

  /// @domName SVGPointList.removeItem; @docsEditable true
  Point removeItem(int index) native;

  /// @domName SVGPointList.replaceItem; @docsEditable true
  Point replaceItem(Point item, int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPolygonElement; @docsEditable true
class PolygonElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGPolygonElement" {

  factory PolygonElement() => _SvgElementFactoryProvider.createSvgElement_tag("polygon");

  /// @domName SVGPolygonElement.animatedPoints; @docsEditable true
  final PointList animatedPoints;

  /// @domName SVGPolygonElement.points; @docsEditable true
  final PointList points;

  // From SVGExternalResourcesRequired

  /// @domName SVGExternalResourcesRequired.externalResourcesRequired; @docsEditable true
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /// @domName SVGLangSpace.xmllang; @docsEditable true
  String xmllang;

  /// @domName SVGLangSpace.xmlspace; @docsEditable true
  String xmlspace;

  // From SVGLocatable

  /// @domName SVGLocatable.farthestViewportElement; @docsEditable true
  final SvgElement farthestViewportElement;

  /// @domName SVGLocatable.nearestViewportElement; @docsEditable true
  final SvgElement nearestViewportElement;

  /// @domName SVGLocatable.getBBox; @docsEditable true
  Rect getBBox() native;

  /// @domName SVGLocatable.getCTM; @docsEditable true
  Matrix getCtm() native "getCTM";

  /// @domName SVGLocatable.getScreenCTM; @docsEditable true
  Matrix getScreenCtm() native "getScreenCTM";

  /// @domName SVGLocatable.getTransformToElement; @docsEditable true
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  /// @domName SVGStylable.className; @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /// @domName SVGStylable.getPresentationAttribute; @docsEditable true
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /// @domName SVGTests.requiredExtensions; @docsEditable true
  final StringList requiredExtensions;

  /// @domName SVGTests.requiredFeatures; @docsEditable true
  final StringList requiredFeatures;

  /// @domName SVGTests.systemLanguage; @docsEditable true
  final StringList systemLanguage;

  /// @domName SVGTests.hasExtension; @docsEditable true
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /// @domName SVGTransformable.transform; @docsEditable true
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPolylineElement; @docsEditable true
class PolylineElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGPolylineElement" {

  factory PolylineElement() => _SvgElementFactoryProvider.createSvgElement_tag("polyline");

  /// @domName SVGPolylineElement.animatedPoints; @docsEditable true
  final PointList animatedPoints;

  /// @domName SVGPolylineElement.points; @docsEditable true
  final PointList points;

  // From SVGExternalResourcesRequired

  /// @domName SVGExternalResourcesRequired.externalResourcesRequired; @docsEditable true
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /// @domName SVGLangSpace.xmllang; @docsEditable true
  String xmllang;

  /// @domName SVGLangSpace.xmlspace; @docsEditable true
  String xmlspace;

  // From SVGLocatable

  /// @domName SVGLocatable.farthestViewportElement; @docsEditable true
  final SvgElement farthestViewportElement;

  /// @domName SVGLocatable.nearestViewportElement; @docsEditable true
  final SvgElement nearestViewportElement;

  /// @domName SVGLocatable.getBBox; @docsEditable true
  Rect getBBox() native;

  /// @domName SVGLocatable.getCTM; @docsEditable true
  Matrix getCtm() native "getCTM";

  /// @domName SVGLocatable.getScreenCTM; @docsEditable true
  Matrix getScreenCtm() native "getScreenCTM";

  /// @domName SVGLocatable.getTransformToElement; @docsEditable true
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  /// @domName SVGStylable.className; @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /// @domName SVGStylable.getPresentationAttribute; @docsEditable true
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /// @domName SVGTests.requiredExtensions; @docsEditable true
  final StringList requiredExtensions;

  /// @domName SVGTests.requiredFeatures; @docsEditable true
  final StringList requiredFeatures;

  /// @domName SVGTests.systemLanguage; @docsEditable true
  final StringList systemLanguage;

  /// @domName SVGTests.hasExtension; @docsEditable true
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /// @domName SVGTransformable.transform; @docsEditable true
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPreserveAspectRatio; @docsEditable true
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

  /// @domName SVGPreserveAspectRatio.align; @docsEditable true
  int align;

  /// @domName SVGPreserveAspectRatio.meetOrSlice; @docsEditable true
  int meetOrSlice;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGRadialGradientElement; @docsEditable true
class RadialGradientElement extends GradientElement native "*SVGRadialGradientElement" {

  factory RadialGradientElement() => _SvgElementFactoryProvider.createSvgElement_tag("radialGradient");

  /// @domName SVGRadialGradientElement.cx; @docsEditable true
  final AnimatedLength cx;

  /// @domName SVGRadialGradientElement.cy; @docsEditable true
  final AnimatedLength cy;

  /// @domName SVGRadialGradientElement.fr; @docsEditable true
  final AnimatedLength fr;

  /// @domName SVGRadialGradientElement.fx; @docsEditable true
  final AnimatedLength fx;

  /// @domName SVGRadialGradientElement.fy; @docsEditable true
  final AnimatedLength fy;

  /// @domName SVGRadialGradientElement.r; @docsEditable true
  final AnimatedLength r;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGRect; @docsEditable true
class Rect native "*SVGRect" {

  /// @domName SVGRect.height; @docsEditable true
  num height;

  /// @domName SVGRect.width; @docsEditable true
  num width;

  /// @domName SVGRect.x; @docsEditable true
  num x;

  /// @domName SVGRect.y; @docsEditable true
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGRectElement; @docsEditable true
class RectElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGRectElement" {

  factory RectElement() => _SvgElementFactoryProvider.createSvgElement_tag("rect");

  /// @domName SVGRectElement.height; @docsEditable true
  final AnimatedLength height;

  /// @domName SVGRectElement.rx; @docsEditable true
  final AnimatedLength rx;

  /// @domName SVGRectElement.ry; @docsEditable true
  final AnimatedLength ry;

  /// @domName SVGRectElement.width; @docsEditable true
  final AnimatedLength width;

  /// @domName SVGRectElement.x; @docsEditable true
  final AnimatedLength x;

  /// @domName SVGRectElement.y; @docsEditable true
  final AnimatedLength y;

  // From SVGExternalResourcesRequired

  /// @domName SVGExternalResourcesRequired.externalResourcesRequired; @docsEditable true
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /// @domName SVGLangSpace.xmllang; @docsEditable true
  String xmllang;

  /// @domName SVGLangSpace.xmlspace; @docsEditable true
  String xmlspace;

  // From SVGLocatable

  /// @domName SVGLocatable.farthestViewportElement; @docsEditable true
  final SvgElement farthestViewportElement;

  /// @domName SVGLocatable.nearestViewportElement; @docsEditable true
  final SvgElement nearestViewportElement;

  /// @domName SVGLocatable.getBBox; @docsEditable true
  Rect getBBox() native;

  /// @domName SVGLocatable.getCTM; @docsEditable true
  Matrix getCtm() native "getCTM";

  /// @domName SVGLocatable.getScreenCTM; @docsEditable true
  Matrix getScreenCtm() native "getScreenCTM";

  /// @domName SVGLocatable.getTransformToElement; @docsEditable true
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  /// @domName SVGStylable.className; @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /// @domName SVGStylable.getPresentationAttribute; @docsEditable true
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /// @domName SVGTests.requiredExtensions; @docsEditable true
  final StringList requiredExtensions;

  /// @domName SVGTests.requiredFeatures; @docsEditable true
  final StringList requiredFeatures;

  /// @domName SVGTests.systemLanguage; @docsEditable true
  final StringList systemLanguage;

  /// @domName SVGTests.hasExtension; @docsEditable true
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /// @domName SVGTransformable.transform; @docsEditable true
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGRenderingIntent; @docsEditable true
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


/// @domName SVGScriptElement; @docsEditable true
class ScriptElement extends SvgElement implements UriReference, ExternalResourcesRequired native "*SVGScriptElement" {

  factory ScriptElement() => _SvgElementFactoryProvider.createSvgElement_tag("script");

  /// @domName SVGScriptElement.type; @docsEditable true
  String type;

  // From SVGExternalResourcesRequired

  /// @domName SVGExternalResourcesRequired.externalResourcesRequired; @docsEditable true
  final AnimatedBoolean externalResourcesRequired;

  // From SVGURIReference

  /// @domName SVGURIReference.href; @docsEditable true
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGSetElement; @docsEditable true
class SetElement extends AnimationElement native "*SVGSetElement" {

  factory SetElement() => _SvgElementFactoryProvider.createSvgElement_tag("set");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGStopElement; @docsEditable true
class StopElement extends SvgElement implements Stylable native "*SVGStopElement" {

  factory StopElement() => _SvgElementFactoryProvider.createSvgElement_tag("stop");

  /// @domName SVGStopElement.offset; @docsEditable true
  final AnimatedNumber offset;

  // From SVGStylable

  /// @domName SVGStylable.className; @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /// @domName SVGStylable.getPresentationAttribute; @docsEditable true
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGStringList; @docsEditable true
class StringList implements JavaScriptIndexingBehavior, List<String> native "*SVGStringList" {

  /// @domName SVGStringList.numberOfItems; @docsEditable true
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

  /// @domName SVGStringList.appendItem; @docsEditable true
  String appendItem(String item) native;

  /// @domName SVGStringList.clear; @docsEditable true
  void clear() native;

  /// @domName SVGStringList.getItem; @docsEditable true
  String getItem(int index) native;

  /// @domName SVGStringList.initialize; @docsEditable true
  String initialize(String item) native;

  /// @domName SVGStringList.insertItemBefore; @docsEditable true
  String insertItemBefore(String item, int index) native;

  /// @domName SVGStringList.removeItem; @docsEditable true
  String removeItem(int index) native;

  /// @domName SVGStringList.replaceItem; @docsEditable true
  String replaceItem(String item, int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGStylable
abstract class Stylable {

  AnimatedString className;

  CSSStyleDeclaration style;

  /// @domName SVGStylable.getPresentationAttribute; @docsEditable true
  CSSValue getPresentationAttribute(String name);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGStyleElement; @docsEditable true
class StyleElement extends SvgElement implements LangSpace native "*SVGStyleElement" {

  factory StyleElement() => _SvgElementFactoryProvider.createSvgElement_tag("style");

  /// @domName SVGStyleElement.disabled; @docsEditable true
  bool disabled;

  /// @domName SVGStyleElement.media; @docsEditable true
  String media;

  // Shadowing definition.
  /// @domName SVGStyleElement.title; @docsEditable true
  String get title => JS("String", "#.title", this);

  /// @domName SVGStyleElement.title; @docsEditable true
  void set title(String value) {
    JS("void", "#.title = #", this, value);
  }

  /// @domName SVGStyleElement.type; @docsEditable true
  String type;

  // From SVGLangSpace

  /// @domName SVGLangSpace.xmllang; @docsEditable true
  String xmllang;

  /// @domName SVGLangSpace.xmlspace; @docsEditable true
  String xmlspace;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGDocument; @docsEditable true
class SvgDocument extends Document native "*SVGDocument" {

  /// @domName SVGDocument.rootElement; @docsEditable true
  final SvgSvgElement rootElement;

  /// @domName SVGDocument.createEvent; @docsEditable true
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

  List<Element> get children => new FilteredElementList(this);

  void set children(Collection<Element> value) {
    final children = this.children;
    children.clear();
    children.addAll(value);
  }

  String get outerHtml {
    final container = new Element.tag("div");
    final SvgElement cloned = this.clone(true);
    container.children.add(cloned);
    return container.innerHtml;
  }

  String get innerHtml {
    final container = new Element.tag("div");
    final SvgElement cloned = this.clone(true);
    container.children.addAll(cloned.children);
    return container.innerHtml;
  }

  void set innerHtml(String svg) {
    final container = new Element.tag("div");
    // Wrap the SVG string in <svg> so that SvgElements are created, rather than
    // HTMLElements.
    container.innerHtml = '<svg version="1.1">$svg</svg>';
    this.children = container.children[0].children;
  }


  // Shadowing definition.
  /// @domName SVGElement.id; @docsEditable true
  String get id => JS("String", "#.id", this);

  /// @domName SVGElement.id; @docsEditable true
  void set id(String value) {
    JS("void", "#.id = #", this, value);
  }

  /// @domName SVGElement.ownerSVGElement; @docsEditable true
  SvgSvgElement get ownerSvgElement => JS("SvgSvgElement", "#.ownerSVGElement", this);

  /// @domName SVGElement.viewportElement; @docsEditable true
  final SvgElement viewportElement;

  /// @domName SVGElement.xmlbase; @docsEditable true
  String xmlbase;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class SvgSvgElement extends SvgElement implements FitToViewBox, Tests, Stylable, Locatable, ExternalResourcesRequired, ZoomAndPan, LangSpace native "*SVGSVGElement" {
  factory SvgSvgElement() => _SvgSvgElementFactoryProvider.createSvgSvgElement();


  /// @domName SVGSVGElement.contentScriptType; @docsEditable true
  String contentScriptType;

  /// @domName SVGSVGElement.contentStyleType; @docsEditable true
  String contentStyleType;

  /// @domName SVGSVGElement.currentScale; @docsEditable true
  num currentScale;

  /// @domName SVGSVGElement.currentTranslate; @docsEditable true
  final Point currentTranslate;

  /// @domName SVGSVGElement.currentView; @docsEditable true
  final ViewSpec currentView;

  /// @domName SVGSVGElement.height; @docsEditable true
  final AnimatedLength height;

  /// @domName SVGSVGElement.pixelUnitToMillimeterX; @docsEditable true
  final num pixelUnitToMillimeterX;

  /// @domName SVGSVGElement.pixelUnitToMillimeterY; @docsEditable true
  final num pixelUnitToMillimeterY;

  /// @domName SVGSVGElement.screenPixelToMillimeterX; @docsEditable true
  final num screenPixelToMillimeterX;

  /// @domName SVGSVGElement.screenPixelToMillimeterY; @docsEditable true
  final num screenPixelToMillimeterY;

  /// @domName SVGSVGElement.useCurrentView; @docsEditable true
  final bool useCurrentView;

  /// @domName SVGSVGElement.viewport; @docsEditable true
  final Rect viewport;

  /// @domName SVGSVGElement.width; @docsEditable true
  final AnimatedLength width;

  /// @domName SVGSVGElement.x; @docsEditable true
  final AnimatedLength x;

  /// @domName SVGSVGElement.y; @docsEditable true
  final AnimatedLength y;

  /// @domName SVGSVGElement.animationsPaused; @docsEditable true
  bool animationsPaused() native;

  /// @domName SVGSVGElement.checkEnclosure; @docsEditable true
  bool checkEnclosure(SvgElement element, Rect rect) native;

  /// @domName SVGSVGElement.checkIntersection; @docsEditable true
  bool checkIntersection(SvgElement element, Rect rect) native;

  /// @domName SVGSVGElement.createSVGAngle; @docsEditable true
  Angle createSvgAngle() native "createSVGAngle";

  /// @domName SVGSVGElement.createSVGLength; @docsEditable true
  Length createSvgLength() native "createSVGLength";

  /// @domName SVGSVGElement.createSVGMatrix; @docsEditable true
  Matrix createSvgMatrix() native "createSVGMatrix";

  /// @domName SVGSVGElement.createSVGNumber; @docsEditable true
  Number createSvgNumber() native "createSVGNumber";

  /// @domName SVGSVGElement.createSVGPoint; @docsEditable true
  Point createSvgPoint() native "createSVGPoint";

  /// @domName SVGSVGElement.createSVGRect; @docsEditable true
  Rect createSvgRect() native "createSVGRect";

  /// @domName SVGSVGElement.createSVGTransform; @docsEditable true
  Transform createSvgTransform() native "createSVGTransform";

  /// @domName SVGSVGElement.createSVGTransformFromMatrix; @docsEditable true
  Transform createSvgTransformFromMatrix(Matrix matrix) native "createSVGTransformFromMatrix";

  /// @domName SVGSVGElement.deselectAll; @docsEditable true
  void deselectAll() native;

  /// @domName SVGSVGElement.forceRedraw; @docsEditable true
  void forceRedraw() native;

  /// @domName SVGSVGElement.getCurrentTime; @docsEditable true
  num getCurrentTime() native;

  /// @domName SVGSVGElement.getElementById; @docsEditable true
  Element getElementById(String elementId) native;

  /// @domName SVGSVGElement.getEnclosureList; @docsEditable true
  @Returns('_NodeList') @Creates('_NodeList')
  List<Node> getEnclosureList(Rect rect, SvgElement referenceElement) native;

  /// @domName SVGSVGElement.getIntersectionList; @docsEditable true
  @Returns('_NodeList') @Creates('_NodeList')
  List<Node> getIntersectionList(Rect rect, SvgElement referenceElement) native;

  /// @domName SVGSVGElement.pauseAnimations; @docsEditable true
  void pauseAnimations() native;

  /// @domName SVGSVGElement.setCurrentTime; @docsEditable true
  void setCurrentTime(num seconds) native;

  /// @domName SVGSVGElement.suspendRedraw; @docsEditable true
  int suspendRedraw(int maxWaitMilliseconds) native;

  /// @domName SVGSVGElement.unpauseAnimations; @docsEditable true
  void unpauseAnimations() native;

  /// @domName SVGSVGElement.unsuspendRedraw; @docsEditable true
  void unsuspendRedraw(int suspendHandleId) native;

  /// @domName SVGSVGElement.unsuspendRedrawAll; @docsEditable true
  void unsuspendRedrawAll() native;

  // From SVGExternalResourcesRequired

  /// @domName SVGExternalResourcesRequired.externalResourcesRequired; @docsEditable true
  final AnimatedBoolean externalResourcesRequired;

  // From SVGFitToViewBox

  /// @domName SVGFitToViewBox.preserveAspectRatio; @docsEditable true
  final AnimatedPreserveAspectRatio preserveAspectRatio;

  /// @domName SVGFitToViewBox.viewBox; @docsEditable true
  final AnimatedRect viewBox;

  // From SVGLangSpace

  /// @domName SVGLangSpace.xmllang; @docsEditable true
  String xmllang;

  /// @domName SVGLangSpace.xmlspace; @docsEditable true
  String xmlspace;

  // From SVGLocatable

  /// @domName SVGLocatable.farthestViewportElement; @docsEditable true
  final SvgElement farthestViewportElement;

  /// @domName SVGLocatable.nearestViewportElement; @docsEditable true
  final SvgElement nearestViewportElement;

  /// @domName SVGLocatable.getBBox; @docsEditable true
  Rect getBBox() native;

  /// @domName SVGLocatable.getCTM; @docsEditable true
  Matrix getCtm() native "getCTM";

  /// @domName SVGLocatable.getScreenCTM; @docsEditable true
  Matrix getScreenCtm() native "getScreenCTM";

  /// @domName SVGLocatable.getTransformToElement; @docsEditable true
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  /// @domName SVGStylable.className; @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /// @domName SVGStylable.getPresentationAttribute; @docsEditable true
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /// @domName SVGTests.requiredExtensions; @docsEditable true
  final StringList requiredExtensions;

  /// @domName SVGTests.requiredFeatures; @docsEditable true
  final StringList requiredFeatures;

  /// @domName SVGTests.systemLanguage; @docsEditable true
  final StringList systemLanguage;

  /// @domName SVGTests.hasExtension; @docsEditable true
  bool hasExtension(String extension) native;

  // From SVGZoomAndPan

  /// @domName SVGZoomAndPan.zoomAndPan; @docsEditable true
  int zoomAndPan;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGSwitchElement; @docsEditable true
class SwitchElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGSwitchElement" {

  factory SwitchElement() => _SvgElementFactoryProvider.createSvgElement_tag("switch");

  // From SVGExternalResourcesRequired

  /// @domName SVGExternalResourcesRequired.externalResourcesRequired; @docsEditable true
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /// @domName SVGLangSpace.xmllang; @docsEditable true
  String xmllang;

  /// @domName SVGLangSpace.xmlspace; @docsEditable true
  String xmlspace;

  // From SVGLocatable

  /// @domName SVGLocatable.farthestViewportElement; @docsEditable true
  final SvgElement farthestViewportElement;

  /// @domName SVGLocatable.nearestViewportElement; @docsEditable true
  final SvgElement nearestViewportElement;

  /// @domName SVGLocatable.getBBox; @docsEditable true
  Rect getBBox() native;

  /// @domName SVGLocatable.getCTM; @docsEditable true
  Matrix getCtm() native "getCTM";

  /// @domName SVGLocatable.getScreenCTM; @docsEditable true
  Matrix getScreenCtm() native "getScreenCTM";

  /// @domName SVGLocatable.getTransformToElement; @docsEditable true
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  /// @domName SVGStylable.className; @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /// @domName SVGStylable.getPresentationAttribute; @docsEditable true
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /// @domName SVGTests.requiredExtensions; @docsEditable true
  final StringList requiredExtensions;

  /// @domName SVGTests.requiredFeatures; @docsEditable true
  final StringList requiredFeatures;

  /// @domName SVGTests.systemLanguage; @docsEditable true
  final StringList systemLanguage;

  /// @domName SVGTests.hasExtension; @docsEditable true
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /// @domName SVGTransformable.transform; @docsEditable true
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGSymbolElement; @docsEditable true
class SymbolElement extends SvgElement implements FitToViewBox, ExternalResourcesRequired, Stylable, LangSpace native "*SVGSymbolElement" {

  factory SymbolElement() => _SvgElementFactoryProvider.createSvgElement_tag("symbol");

  // From SVGExternalResourcesRequired

  /// @domName SVGExternalResourcesRequired.externalResourcesRequired; @docsEditable true
  final AnimatedBoolean externalResourcesRequired;

  // From SVGFitToViewBox

  /// @domName SVGFitToViewBox.preserveAspectRatio; @docsEditable true
  final AnimatedPreserveAspectRatio preserveAspectRatio;

  /// @domName SVGFitToViewBox.viewBox; @docsEditable true
  final AnimatedRect viewBox;

  // From SVGLangSpace

  /// @domName SVGLangSpace.xmllang; @docsEditable true
  String xmllang;

  /// @domName SVGLangSpace.xmlspace; @docsEditable true
  String xmlspace;

  // From SVGStylable

  /// @domName SVGStylable.className; @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /// @domName SVGStylable.getPresentationAttribute; @docsEditable true
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGTRefElement; @docsEditable true
class TRefElement extends TextPositioningElement implements UriReference native "*SVGTRefElement" {

  factory TRefElement() => _SvgElementFactoryProvider.createSvgElement_tag("tref");

  // From SVGURIReference

  /// @domName SVGURIReference.href; @docsEditable true
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGTSpanElement; @docsEditable true
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

  /// @domName SVGTests.hasExtension; @docsEditable true
  bool hasExtension(String extension);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGTextContentElement; @docsEditable true
class TextContentElement extends SvgElement implements Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGTextContentElement" {

  static const int LENGTHADJUST_SPACING = 1;

  static const int LENGTHADJUST_SPACINGANDGLYPHS = 2;

  static const int LENGTHADJUST_UNKNOWN = 0;

  /// @domName SVGTextContentElement.lengthAdjust; @docsEditable true
  final AnimatedEnumeration lengthAdjust;

  /// @domName SVGTextContentElement.textLength; @docsEditable true
  final AnimatedLength textLength;

  /// @domName SVGTextContentElement.getCharNumAtPosition; @docsEditable true
  int getCharNumAtPosition(Point point) native;

  /// @domName SVGTextContentElement.getComputedTextLength; @docsEditable true
  num getComputedTextLength() native;

  /// @domName SVGTextContentElement.getEndPositionOfChar; @docsEditable true
  Point getEndPositionOfChar(int offset) native;

  /// @domName SVGTextContentElement.getExtentOfChar; @docsEditable true
  Rect getExtentOfChar(int offset) native;

  /// @domName SVGTextContentElement.getNumberOfChars; @docsEditable true
  int getNumberOfChars() native;

  /// @domName SVGTextContentElement.getRotationOfChar; @docsEditable true
  num getRotationOfChar(int offset) native;

  /// @domName SVGTextContentElement.getStartPositionOfChar; @docsEditable true
  Point getStartPositionOfChar(int offset) native;

  /// @domName SVGTextContentElement.getSubStringLength; @docsEditable true
  num getSubStringLength(int offset, int length) native;

  /// @domName SVGTextContentElement.selectSubString; @docsEditable true
  void selectSubString(int offset, int length) native;

  // From SVGExternalResourcesRequired

  /// @domName SVGExternalResourcesRequired.externalResourcesRequired; @docsEditable true
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /// @domName SVGLangSpace.xmllang; @docsEditable true
  String xmllang;

  /// @domName SVGLangSpace.xmlspace; @docsEditable true
  String xmlspace;

  // From SVGStylable

  /// @domName SVGStylable.className; @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /// @domName SVGStylable.getPresentationAttribute; @docsEditable true
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /// @domName SVGTests.requiredExtensions; @docsEditable true
  final StringList requiredExtensions;

  /// @domName SVGTests.requiredFeatures; @docsEditable true
  final StringList requiredFeatures;

  /// @domName SVGTests.systemLanguage; @docsEditable true
  final StringList systemLanguage;

  /// @domName SVGTests.hasExtension; @docsEditable true
  bool hasExtension(String extension) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGTextElement; @docsEditable true
class TextElement extends TextPositioningElement implements Transformable native "*SVGTextElement" {

  factory TextElement() => _SvgElementFactoryProvider.createSvgElement_tag("text");

  // From SVGLocatable

  /// @domName SVGLocatable.farthestViewportElement; @docsEditable true
  final SvgElement farthestViewportElement;

  /// @domName SVGLocatable.nearestViewportElement; @docsEditable true
  final SvgElement nearestViewportElement;

  /// @domName SVGLocatable.getBBox; @docsEditable true
  Rect getBBox() native;

  /// @domName SVGLocatable.getCTM; @docsEditable true
  Matrix getCtm() native "getCTM";

  /// @domName SVGLocatable.getScreenCTM; @docsEditable true
  Matrix getScreenCtm() native "getScreenCTM";

  /// @domName SVGLocatable.getTransformToElement; @docsEditable true
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGTransformable

  /// @domName SVGTransformable.transform; @docsEditable true
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGTextPathElement; @docsEditable true
class TextPathElement extends TextContentElement implements UriReference native "*SVGTextPathElement" {

  static const int TEXTPATH_METHODTYPE_ALIGN = 1;

  static const int TEXTPATH_METHODTYPE_STRETCH = 2;

  static const int TEXTPATH_METHODTYPE_UNKNOWN = 0;

  static const int TEXTPATH_SPACINGTYPE_AUTO = 1;

  static const int TEXTPATH_SPACINGTYPE_EXACT = 2;

  static const int TEXTPATH_SPACINGTYPE_UNKNOWN = 0;

  /// @domName SVGTextPathElement.method; @docsEditable true
  final AnimatedEnumeration method;

  /// @domName SVGTextPathElement.spacing; @docsEditable true
  final AnimatedEnumeration spacing;

  /// @domName SVGTextPathElement.startOffset; @docsEditable true
  final AnimatedLength startOffset;

  // From SVGURIReference

  /// @domName SVGURIReference.href; @docsEditable true
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGTextPositioningElement; @docsEditable true
class TextPositioningElement extends TextContentElement native "*SVGTextPositioningElement" {

  /// @domName SVGTextPositioningElement.dx; @docsEditable true
  final AnimatedLengthList dx;

  /// @domName SVGTextPositioningElement.dy; @docsEditable true
  final AnimatedLengthList dy;

  /// @domName SVGTextPositioningElement.rotate; @docsEditable true
  final AnimatedNumberList rotate;

  /// @domName SVGTextPositioningElement.x; @docsEditable true
  final AnimatedLengthList x;

  /// @domName SVGTextPositioningElement.y; @docsEditable true
  final AnimatedLengthList y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGTitleElement; @docsEditable true
class TitleElement extends SvgElement implements Stylable, LangSpace native "*SVGTitleElement" {

  factory TitleElement() => _SvgElementFactoryProvider.createSvgElement_tag("title");

  // From SVGLangSpace

  /// @domName SVGLangSpace.xmllang; @docsEditable true
  String xmllang;

  /// @domName SVGLangSpace.xmlspace; @docsEditable true
  String xmlspace;

  // From SVGStylable

  /// @domName SVGStylable.className; @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /// @domName SVGStylable.getPresentationAttribute; @docsEditable true
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGTransform; @docsEditable true
class Transform native "*SVGTransform" {

  static const int SVG_TRANSFORM_MATRIX = 1;

  static const int SVG_TRANSFORM_ROTATE = 4;

  static const int SVG_TRANSFORM_SCALE = 3;

  static const int SVG_TRANSFORM_SKEWX = 5;

  static const int SVG_TRANSFORM_SKEWY = 6;

  static const int SVG_TRANSFORM_TRANSLATE = 2;

  static const int SVG_TRANSFORM_UNKNOWN = 0;

  /// @domName SVGTransform.angle; @docsEditable true
  final num angle;

  /// @domName SVGTransform.matrix; @docsEditable true
  final Matrix matrix;

  /// @domName SVGTransform.type; @docsEditable true
  final int type;

  /// @domName SVGTransform.setMatrix; @docsEditable true
  void setMatrix(Matrix matrix) native;

  /// @domName SVGTransform.setRotate; @docsEditable true
  void setRotate(num angle, num cx, num cy) native;

  /// @domName SVGTransform.setScale; @docsEditable true
  void setScale(num sx, num sy) native;

  /// @domName SVGTransform.setSkewX; @docsEditable true
  void setSkewX(num angle) native;

  /// @domName SVGTransform.setSkewY; @docsEditable true
  void setSkewY(num angle) native;

  /// @domName SVGTransform.setTranslate; @docsEditable true
  void setTranslate(num tx, num ty) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGTransformList; @docsEditable true
class TransformList implements List<Transform>, JavaScriptIndexingBehavior native "*SVGTransformList" {

  /// @domName SVGTransformList.numberOfItems; @docsEditable true
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

  /// @domName SVGTransformList.appendItem; @docsEditable true
  Transform appendItem(Transform item) native;

  /// @domName SVGTransformList.clear; @docsEditable true
  void clear() native;

  /// @domName SVGTransformList.consolidate; @docsEditable true
  Transform consolidate() native;

  /// @domName SVGTransformList.createSVGTransformFromMatrix; @docsEditable true
  Transform createSvgTransformFromMatrix(Matrix matrix) native "createSVGTransformFromMatrix";

  /// @domName SVGTransformList.getItem; @docsEditable true
  Transform getItem(int index) native;

  /// @domName SVGTransformList.initialize; @docsEditable true
  Transform initialize(Transform item) native;

  /// @domName SVGTransformList.insertItemBefore; @docsEditable true
  Transform insertItemBefore(Transform item, int index) native;

  /// @domName SVGTransformList.removeItem; @docsEditable true
  Transform removeItem(int index) native;

  /// @domName SVGTransformList.replaceItem; @docsEditable true
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

  /// @domName SVGLocatable.getBBox; @docsEditable true
  Rect getBBox();

  /// @domName SVGLocatable.getCTM; @docsEditable true
  Matrix getCTM();

  /// @domName SVGLocatable.getScreenCTM; @docsEditable true
  Matrix getScreenCTM();

  /// @domName SVGLocatable.getTransformToElement; @docsEditable true
  Matrix getTransformToElement(SvgElement element);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGUnitTypes; @docsEditable true
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


/// @domName SVGUseElement; @docsEditable true
class UseElement extends SvgElement implements Transformable, Tests, UriReference, Stylable, ExternalResourcesRequired, LangSpace native "*SVGUseElement" {

  factory UseElement() => _SvgElementFactoryProvider.createSvgElement_tag("use");

  /// @domName SVGUseElement.animatedInstanceRoot; @docsEditable true
  final ElementInstance animatedInstanceRoot;

  /// @domName SVGUseElement.height; @docsEditable true
  final AnimatedLength height;

  /// @domName SVGUseElement.instanceRoot; @docsEditable true
  final ElementInstance instanceRoot;

  /// @domName SVGUseElement.width; @docsEditable true
  final AnimatedLength width;

  /// @domName SVGUseElement.x; @docsEditable true
  final AnimatedLength x;

  /// @domName SVGUseElement.y; @docsEditable true
  final AnimatedLength y;

  // From SVGExternalResourcesRequired

  /// @domName SVGExternalResourcesRequired.externalResourcesRequired; @docsEditable true
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /// @domName SVGLangSpace.xmllang; @docsEditable true
  String xmllang;

  /// @domName SVGLangSpace.xmlspace; @docsEditable true
  String xmlspace;

  // From SVGLocatable

  /// @domName SVGLocatable.farthestViewportElement; @docsEditable true
  final SvgElement farthestViewportElement;

  /// @domName SVGLocatable.nearestViewportElement; @docsEditable true
  final SvgElement nearestViewportElement;

  /// @domName SVGLocatable.getBBox; @docsEditable true
  Rect getBBox() native;

  /// @domName SVGLocatable.getCTM; @docsEditable true
  Matrix getCtm() native "getCTM";

  /// @domName SVGLocatable.getScreenCTM; @docsEditable true
  Matrix getScreenCtm() native "getScreenCTM";

  /// @domName SVGLocatable.getTransformToElement; @docsEditable true
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  /// @domName SVGStylable.className; @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /// @domName SVGStylable.getPresentationAttribute; @docsEditable true
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /// @domName SVGTests.requiredExtensions; @docsEditable true
  final StringList requiredExtensions;

  /// @domName SVGTests.requiredFeatures; @docsEditable true
  final StringList requiredFeatures;

  /// @domName SVGTests.systemLanguage; @docsEditable true
  final StringList systemLanguage;

  /// @domName SVGTests.hasExtension; @docsEditable true
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /// @domName SVGTransformable.transform; @docsEditable true
  final AnimatedTransformList transform;

  // From SVGURIReference

  /// @domName SVGURIReference.href; @docsEditable true
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGVKernElement; @docsEditable true
class VKernElement extends SvgElement native "*SVGVKernElement" {

  factory VKernElement() => _SvgElementFactoryProvider.createSvgElement_tag("vkern");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGViewElement; @docsEditable true
class ViewElement extends SvgElement implements FitToViewBox, ExternalResourcesRequired, ZoomAndPan native "*SVGViewElement" {

  factory ViewElement() => _SvgElementFactoryProvider.createSvgElement_tag("view");

  /// @domName SVGViewElement.viewTarget; @docsEditable true
  final StringList viewTarget;

  // From SVGExternalResourcesRequired

  /// @domName SVGExternalResourcesRequired.externalResourcesRequired; @docsEditable true
  final AnimatedBoolean externalResourcesRequired;

  // From SVGFitToViewBox

  /// @domName SVGFitToViewBox.preserveAspectRatio; @docsEditable true
  final AnimatedPreserveAspectRatio preserveAspectRatio;

  /// @domName SVGFitToViewBox.viewBox; @docsEditable true
  final AnimatedRect viewBox;

  // From SVGZoomAndPan

  /// @domName SVGZoomAndPan.zoomAndPan; @docsEditable true
  int zoomAndPan;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGViewSpec; @docsEditable true
class ViewSpec native "*SVGViewSpec" {

  /// @domName SVGViewSpec.preserveAspectRatio; @docsEditable true
  final AnimatedPreserveAspectRatio preserveAspectRatio;

  /// @domName SVGViewSpec.preserveAspectRatioString; @docsEditable true
  final String preserveAspectRatioString;

  /// @domName SVGViewSpec.transform; @docsEditable true
  final TransformList transform;

  /// @domName SVGViewSpec.transformString; @docsEditable true
  final String transformString;

  /// @domName SVGViewSpec.viewBox; @docsEditable true
  final AnimatedRect viewBox;

  /// @domName SVGViewSpec.viewBoxString; @docsEditable true
  final String viewBoxString;

  /// @domName SVGViewSpec.viewTarget; @docsEditable true
  final SvgElement viewTarget;

  /// @domName SVGViewSpec.viewTargetString; @docsEditable true
  final String viewTargetString;

  /// @domName SVGViewSpec.zoomAndPan; @docsEditable true
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


/// @domName SVGZoomEvent; @docsEditable true
class ZoomEvent extends UIEvent native "*SVGZoomEvent" {

  /// @domName SVGZoomEvent.newScale; @docsEditable true
  final num newScale;

  /// @domName SVGZoomEvent.newTranslate; @docsEditable true
  final Point newTranslate;

  /// @domName SVGZoomEvent.previousScale; @docsEditable true
  final num previousScale;

  /// @domName SVGZoomEvent.previousTranslate; @docsEditable true
  final Point previousTranslate;

  /// @domName SVGZoomEvent.zoomRectScreen; @docsEditable true
  final Rect zoomRectScreen;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGElementInstanceList; @docsEditable true
class _ElementInstanceList implements JavaScriptIndexingBehavior, List<ElementInstance> native "*SVGElementInstanceList" {

  /// @domName SVGElementInstanceList.length; @docsEditable true
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

  /// @domName SVGElementInstanceList.item; @docsEditable true
  ElementInstance item(int index) native;
}
