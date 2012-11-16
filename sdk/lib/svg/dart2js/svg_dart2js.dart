library svg;

import 'dart:html';
// DO NOT EDIT
// Auto-generated dart:svg library.





// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


final _START_TAG_REGEXP = new RegExp('<(\\w+)');

class _SVGElementFactoryProvider {
  static SVGElement createSVGElement_tag(String tag) {
    final Element temp =
      document.$dom_createElementNS("http://www.w3.org/2000/svg", tag);
    return temp;
  }

  static SVGElement createSVGElement_svg(String svg) {
    Element parentTag;
    final match = _START_TAG_REGEXP.firstMatch(svg);
    if (match != null && match.group(1).toLowerCase() == 'svg') {
      parentTag = new Element.tag('div');
    } else {
      parentTag = new SVGSVGElement();
    }

    parentTag.innerHTML = svg;
    if (parentTag.elements.length == 1) return parentTag.elements.removeLast();

    throw new ArgumentError(
        'SVG had ${parentTag.elements.length} '
        'top-level elements but 1 expected');
  }
}

class _SVGSVGElementFactoryProvider {
  static SVGSVGElement createSVGSVGElement() {
    final el = new SVGElement.tag("svg");
    // The SVG spec requires the version attribute to match the spec version
    el.attributes['version'] = "1.1";
    return el;
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAElement
class SVGAElement extends SVGElement implements SVGLangSpace, SVGTests, SVGStylable, SVGURIReference, SVGExternalResourcesRequired, SVGTransformable native "*SVGAElement" {

  factory SVGAElement() => _SvgElementFactoryProvider.createSVGElement_tag("a");

  /** @domName SVGAElement.target */
  final SVGAnimatedString target;

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final SVGAnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGLocatable

  /** @domName SVGLocatable.farthestViewportElement */
  final SVGElement farthestViewportElement;

  /** @domName SVGLocatable.nearestViewportElement */
  final SVGElement nearestViewportElement;

  /** @domName SVGLocatable.getBBox */
  SVGRect getBBox() native;

  /** @domName SVGLocatable.getCTM */
  SVGMatrix getCTM() native;

  /** @domName SVGLocatable.getScreenCTM */
  SVGMatrix getScreenCTM() native;

  /** @domName SVGLocatable.getTransformToElement */
  SVGMatrix getTransformToElement(SVGElement element) native;

  // From SVGStylable

  /** @domName SVGStylable.className */
  SVGAnimatedString get $dom_svgClassName => JS("SVGAnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /** @domName SVGTests.requiredExtensions */
  final SVGStringList requiredExtensions;

  /** @domName SVGTests.requiredFeatures */
  final SVGStringList requiredFeatures;

  /** @domName SVGTests.systemLanguage */
  final SVGStringList systemLanguage;

  /** @domName SVGTests.hasExtension */
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /** @domName SVGTransformable.transform */
  final SVGAnimatedTransformList transform;

  // From SVGURIReference

  /** @domName SVGURIReference.href */
  final SVGAnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAltGlyphDefElement
class SVGAltGlyphDefElement extends SVGElement native "*SVGAltGlyphDefElement" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAltGlyphElement
class SVGAltGlyphElement extends SVGTextPositioningElement implements SVGURIReference native "*SVGAltGlyphElement" {

  /** @domName SVGAltGlyphElement.format */
  String format;

  /** @domName SVGAltGlyphElement.glyphRef */
  String glyphRef;

  // From SVGURIReference

  /** @domName SVGURIReference.href */
  final SVGAnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAltGlyphItemElement
class SVGAltGlyphItemElement extends SVGElement native "*SVGAltGlyphItemElement" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAngle
class SVGAngle native "*SVGAngle" {

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
class SVGAnimateColorElement extends SVGAnimationElement native "*SVGAnimateColorElement" {

  factory SVGAnimateColorElement() => _SvgElementFactoryProvider.createSVGElement_tag("animateColor");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAnimateElement
class SVGAnimateElement extends SVGAnimationElement native "*SVGAnimateElement" {

  factory SVGAnimateElement() => _SvgElementFactoryProvider.createSVGElement_tag("animate");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAnimateMotionElement
class SVGAnimateMotionElement extends SVGAnimationElement native "*SVGAnimateMotionElement" {

  factory SVGAnimateMotionElement() => _SvgElementFactoryProvider.createSVGElement_tag("animateMotion");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAnimateTransformElement
class SVGAnimateTransformElement extends SVGAnimationElement native "*SVGAnimateTransformElement" {

  factory SVGAnimateTransformElement() => _SvgElementFactoryProvider.createSVGElement_tag("animateTransform");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAnimatedAngle
class SVGAnimatedAngle native "*SVGAnimatedAngle" {

  /** @domName SVGAnimatedAngle.animVal */
  final SVGAngle animVal;

  /** @domName SVGAnimatedAngle.baseVal */
  final SVGAngle baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAnimatedBoolean
class SVGAnimatedBoolean native "*SVGAnimatedBoolean" {

  /** @domName SVGAnimatedBoolean.animVal */
  final bool animVal;

  /** @domName SVGAnimatedBoolean.baseVal */
  bool baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAnimatedEnumeration
class SVGAnimatedEnumeration native "*SVGAnimatedEnumeration" {

  /** @domName SVGAnimatedEnumeration.animVal */
  final int animVal;

  /** @domName SVGAnimatedEnumeration.baseVal */
  int baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAnimatedInteger
class SVGAnimatedInteger native "*SVGAnimatedInteger" {

  /** @domName SVGAnimatedInteger.animVal */
  final int animVal;

  /** @domName SVGAnimatedInteger.baseVal */
  int baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAnimatedLength
class SVGAnimatedLength native "*SVGAnimatedLength" {

  /** @domName SVGAnimatedLength.animVal */
  final SVGLength animVal;

  /** @domName SVGAnimatedLength.baseVal */
  final SVGLength baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAnimatedLengthList
class SVGAnimatedLengthList implements JavaScriptIndexingBehavior, List<SVGAnimatedLength> native "*SVGAnimatedLengthList" {

  /** @domName SVGAnimatedLengthList.animVal */
  final SVGLengthList animVal;

  /** @domName SVGAnimatedLengthList.baseVal */
  final SVGLengthList baseVal;

  SVGAnimatedLength operator[](int index) => JS("SVGAnimatedLength", "#[#]", this, index);

  void operator[]=(int index, SVGAnimatedLength value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<SVGAnimatedLength> mixins.
  // SVGAnimatedLength is the element type.

  // From Iterable<SVGAnimatedLength>:

  Iterator<SVGAnimatedLength> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<SVGAnimatedLength>(this);
  }

  // From Collection<SVGAnimatedLength>:

  void add(SVGAnimatedLength value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(SVGAnimatedLength value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<SVGAnimatedLength> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(SVGAnimatedLength element) => _Collections.contains(this, element);

  void forEach(void f(SVGAnimatedLength element)) => _Collections.forEach(this, f);

  Collection map(f(SVGAnimatedLength element)) => _Collections.map(this, [], f);

  Collection<SVGAnimatedLength> filter(bool f(SVGAnimatedLength element)) =>
     _Collections.filter(this, <SVGAnimatedLength>[], f);

  bool every(bool f(SVGAnimatedLength element)) => _Collections.every(this, f);

  bool some(bool f(SVGAnimatedLength element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<SVGAnimatedLength>:

  void sort([Comparator<SVGAnimatedLength> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(SVGAnimatedLength element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(SVGAnimatedLength element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  SVGAnimatedLength get last => this[length - 1];

  SVGAnimatedLength removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<SVGAnimatedLength> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [SVGAnimatedLength initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<SVGAnimatedLength> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <SVGAnimatedLength>[]);

  // -- end List<SVGAnimatedLength> mixins.
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAnimatedNumber
class SVGAnimatedNumber native "*SVGAnimatedNumber" {

  /** @domName SVGAnimatedNumber.animVal */
  final num animVal;

  /** @domName SVGAnimatedNumber.baseVal */
  num baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAnimatedNumberList
class SVGAnimatedNumberList implements JavaScriptIndexingBehavior, List<SVGAnimatedNumber> native "*SVGAnimatedNumberList" {

  /** @domName SVGAnimatedNumberList.animVal */
  final SVGNumberList animVal;

  /** @domName SVGAnimatedNumberList.baseVal */
  final SVGNumberList baseVal;

  SVGAnimatedNumber operator[](int index) => JS("SVGAnimatedNumber", "#[#]", this, index);

  void operator[]=(int index, SVGAnimatedNumber value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<SVGAnimatedNumber> mixins.
  // SVGAnimatedNumber is the element type.

  // From Iterable<SVGAnimatedNumber>:

  Iterator<SVGAnimatedNumber> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<SVGAnimatedNumber>(this);
  }

  // From Collection<SVGAnimatedNumber>:

  void add(SVGAnimatedNumber value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(SVGAnimatedNumber value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<SVGAnimatedNumber> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(SVGAnimatedNumber element) => _Collections.contains(this, element);

  void forEach(void f(SVGAnimatedNumber element)) => _Collections.forEach(this, f);

  Collection map(f(SVGAnimatedNumber element)) => _Collections.map(this, [], f);

  Collection<SVGAnimatedNumber> filter(bool f(SVGAnimatedNumber element)) =>
     _Collections.filter(this, <SVGAnimatedNumber>[], f);

  bool every(bool f(SVGAnimatedNumber element)) => _Collections.every(this, f);

  bool some(bool f(SVGAnimatedNumber element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<SVGAnimatedNumber>:

  void sort([Comparator<SVGAnimatedNumber> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(SVGAnimatedNumber element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(SVGAnimatedNumber element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  SVGAnimatedNumber get last => this[length - 1];

  SVGAnimatedNumber removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<SVGAnimatedNumber> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [SVGAnimatedNumber initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<SVGAnimatedNumber> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <SVGAnimatedNumber>[]);

  // -- end List<SVGAnimatedNumber> mixins.
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAnimatedPreserveAspectRatio
class SVGAnimatedPreserveAspectRatio native "*SVGAnimatedPreserveAspectRatio" {

  /** @domName SVGAnimatedPreserveAspectRatio.animVal */
  final SVGPreserveAspectRatio animVal;

  /** @domName SVGAnimatedPreserveAspectRatio.baseVal */
  final SVGPreserveAspectRatio baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAnimatedRect
class SVGAnimatedRect native "*SVGAnimatedRect" {

  /** @domName SVGAnimatedRect.animVal */
  final SVGRect animVal;

  /** @domName SVGAnimatedRect.baseVal */
  final SVGRect baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAnimatedString
class SVGAnimatedString native "*SVGAnimatedString" {

  /** @domName SVGAnimatedString.animVal */
  final String animVal;

  /** @domName SVGAnimatedString.baseVal */
  String baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAnimatedTransformList
class SVGAnimatedTransformList implements JavaScriptIndexingBehavior, List<SVGAnimateTransformElement> native "*SVGAnimatedTransformList" {

  /** @domName SVGAnimatedTransformList.animVal */
  final SVGTransformList animVal;

  /** @domName SVGAnimatedTransformList.baseVal */
  final SVGTransformList baseVal;

  SVGAnimateTransformElement operator[](int index) => JS("SVGAnimateTransformElement", "#[#]", this, index);

  void operator[]=(int index, SVGAnimateTransformElement value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<SVGAnimateTransformElement> mixins.
  // SVGAnimateTransformElement is the element type.

  // From Iterable<SVGAnimateTransformElement>:

  Iterator<SVGAnimateTransformElement> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<SVGAnimateTransformElement>(this);
  }

  // From Collection<SVGAnimateTransformElement>:

  void add(SVGAnimateTransformElement value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(SVGAnimateTransformElement value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<SVGAnimateTransformElement> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(SVGAnimateTransformElement element) => _Collections.contains(this, element);

  void forEach(void f(SVGAnimateTransformElement element)) => _Collections.forEach(this, f);

  Collection map(f(SVGAnimateTransformElement element)) => _Collections.map(this, [], f);

  Collection<SVGAnimateTransformElement> filter(bool f(SVGAnimateTransformElement element)) =>
     _Collections.filter(this, <SVGAnimateTransformElement>[], f);

  bool every(bool f(SVGAnimateTransformElement element)) => _Collections.every(this, f);

  bool some(bool f(SVGAnimateTransformElement element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<SVGAnimateTransformElement>:

  void sort([Comparator<SVGAnimateTransformElement> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(SVGAnimateTransformElement element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(SVGAnimateTransformElement element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  SVGAnimateTransformElement get last => this[length - 1];

  SVGAnimateTransformElement removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<SVGAnimateTransformElement> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [SVGAnimateTransformElement initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<SVGAnimateTransformElement> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <SVGAnimateTransformElement>[]);

  // -- end List<SVGAnimateTransformElement> mixins.
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGAnimationElement
class SVGAnimationElement extends SVGElement implements ElementTimeControl, SVGTests, SVGExternalResourcesRequired native "*SVGAnimationElement" {

  factory SVGAnimationElement() => _SvgElementFactoryProvider.createSVGElement_tag("animation");

  /** @domName SVGAnimationElement.targetElement */
  final SVGElement targetElement;

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
  final SVGAnimatedBoolean externalResourcesRequired;

  // From SVGTests

  /** @domName SVGTests.requiredExtensions */
  final SVGStringList requiredExtensions;

  /** @domName SVGTests.requiredFeatures */
  final SVGStringList requiredFeatures;

  /** @domName SVGTests.systemLanguage */
  final SVGStringList systemLanguage;

  /** @domName SVGTests.hasExtension */
  bool hasExtension(String extension) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGCircleElement
class SVGCircleElement extends SVGElement implements SVGLangSpace, SVGStylable, SVGTests, SVGTransformable, SVGExternalResourcesRequired native "*SVGCircleElement" {

  factory SVGCircleElement() => _SvgElementFactoryProvider.createSVGElement_tag("circle");

  /** @domName SVGCircleElement.cx */
  final SVGAnimatedLength cx;

  /** @domName SVGCircleElement.cy */
  final SVGAnimatedLength cy;

  /** @domName SVGCircleElement.r */
  final SVGAnimatedLength r;

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final SVGAnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGLocatable

  /** @domName SVGLocatable.farthestViewportElement */
  final SVGElement farthestViewportElement;

  /** @domName SVGLocatable.nearestViewportElement */
  final SVGElement nearestViewportElement;

  /** @domName SVGLocatable.getBBox */
  SVGRect getBBox() native;

  /** @domName SVGLocatable.getCTM */
  SVGMatrix getCTM() native;

  /** @domName SVGLocatable.getScreenCTM */
  SVGMatrix getScreenCTM() native;

  /** @domName SVGLocatable.getTransformToElement */
  SVGMatrix getTransformToElement(SVGElement element) native;

  // From SVGStylable

  /** @domName SVGStylable.className */
  SVGAnimatedString get $dom_svgClassName => JS("SVGAnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /** @domName SVGTests.requiredExtensions */
  final SVGStringList requiredExtensions;

  /** @domName SVGTests.requiredFeatures */
  final SVGStringList requiredFeatures;

  /** @domName SVGTests.systemLanguage */
  final SVGStringList systemLanguage;

  /** @domName SVGTests.hasExtension */
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /** @domName SVGTransformable.transform */
  final SVGAnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGClipPathElement
class SVGClipPathElement extends SVGElement implements SVGLangSpace, SVGStylable, SVGTests, SVGTransformable, SVGExternalResourcesRequired native "*SVGClipPathElement" {

  factory SVGClipPathElement() => _SvgElementFactoryProvider.createSVGElement_tag("clipPath");

  /** @domName SVGClipPathElement.clipPathUnits */
  final SVGAnimatedEnumeration clipPathUnits;

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final SVGAnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGLocatable

  /** @domName SVGLocatable.farthestViewportElement */
  final SVGElement farthestViewportElement;

  /** @domName SVGLocatable.nearestViewportElement */
  final SVGElement nearestViewportElement;

  /** @domName SVGLocatable.getBBox */
  SVGRect getBBox() native;

  /** @domName SVGLocatable.getCTM */
  SVGMatrix getCTM() native;

  /** @domName SVGLocatable.getScreenCTM */
  SVGMatrix getScreenCTM() native;

  /** @domName SVGLocatable.getTransformToElement */
  SVGMatrix getTransformToElement(SVGElement element) native;

  // From SVGStylable

  /** @domName SVGStylable.className */
  SVGAnimatedString get $dom_svgClassName => JS("SVGAnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /** @domName SVGTests.requiredExtensions */
  final SVGStringList requiredExtensions;

  /** @domName SVGTests.requiredFeatures */
  final SVGStringList requiredFeatures;

  /** @domName SVGTests.systemLanguage */
  final SVGStringList systemLanguage;

  /** @domName SVGTests.hasExtension */
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /** @domName SVGTransformable.transform */
  final SVGAnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGColor
class SVGColor extends CSSValue native "*SVGColor" {

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
class SVGComponentTransferFunctionElement extends SVGElement native "*SVGComponentTransferFunctionElement" {

  static const int SVG_FECOMPONENTTRANSFER_TYPE_DISCRETE = 3;

  static const int SVG_FECOMPONENTTRANSFER_TYPE_GAMMA = 5;

  static const int SVG_FECOMPONENTTRANSFER_TYPE_IDENTITY = 1;

  static const int SVG_FECOMPONENTTRANSFER_TYPE_LINEAR = 4;

  static const int SVG_FECOMPONENTTRANSFER_TYPE_TABLE = 2;

  static const int SVG_FECOMPONENTTRANSFER_TYPE_UNKNOWN = 0;

  /** @domName SVGComponentTransferFunctionElement.amplitude */
  final SVGAnimatedNumber amplitude;

  /** @domName SVGComponentTransferFunctionElement.exponent */
  final SVGAnimatedNumber exponent;

  /** @domName SVGComponentTransferFunctionElement.intercept */
  final SVGAnimatedNumber intercept;

  /** @domName SVGComponentTransferFunctionElement.offset */
  final SVGAnimatedNumber offset;

  /** @domName SVGComponentTransferFunctionElement.slope */
  final SVGAnimatedNumber slope;

  /** @domName SVGComponentTransferFunctionElement.tableValues */
  final SVGAnimatedNumberList tableValues;

  /** @domName SVGComponentTransferFunctionElement.type */
  final SVGAnimatedEnumeration type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGCursorElement
class SVGCursorElement extends SVGElement implements SVGURIReference, SVGTests, SVGExternalResourcesRequired native "*SVGCursorElement" {

  factory SVGCursorElement() => _SvgElementFactoryProvider.createSVGElement_tag("cursor");

  /** @domName SVGCursorElement.x */
  final SVGAnimatedLength x;

  /** @domName SVGCursorElement.y */
  final SVGAnimatedLength y;

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final SVGAnimatedBoolean externalResourcesRequired;

  // From SVGTests

  /** @domName SVGTests.requiredExtensions */
  final SVGStringList requiredExtensions;

  /** @domName SVGTests.requiredFeatures */
  final SVGStringList requiredFeatures;

  /** @domName SVGTests.systemLanguage */
  final SVGStringList systemLanguage;

  /** @domName SVGTests.hasExtension */
  bool hasExtension(String extension) native;

  // From SVGURIReference

  /** @domName SVGURIReference.href */
  final SVGAnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGDefsElement
class SVGDefsElement extends SVGElement implements SVGLangSpace, SVGStylable, SVGTests, SVGTransformable, SVGExternalResourcesRequired native "*SVGDefsElement" {

  factory SVGDefsElement() => _SvgElementFactoryProvider.createSVGElement_tag("defs");

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final SVGAnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGLocatable

  /** @domName SVGLocatable.farthestViewportElement */
  final SVGElement farthestViewportElement;

  /** @domName SVGLocatable.nearestViewportElement */
  final SVGElement nearestViewportElement;

  /** @domName SVGLocatable.getBBox */
  SVGRect getBBox() native;

  /** @domName SVGLocatable.getCTM */
  SVGMatrix getCTM() native;

  /** @domName SVGLocatable.getScreenCTM */
  SVGMatrix getScreenCTM() native;

  /** @domName SVGLocatable.getTransformToElement */
  SVGMatrix getTransformToElement(SVGElement element) native;

  // From SVGStylable

  /** @domName SVGStylable.className */
  SVGAnimatedString get $dom_svgClassName => JS("SVGAnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /** @domName SVGTests.requiredExtensions */
  final SVGStringList requiredExtensions;

  /** @domName SVGTests.requiredFeatures */
  final SVGStringList requiredFeatures;

  /** @domName SVGTests.systemLanguage */
  final SVGStringList systemLanguage;

  /** @domName SVGTests.hasExtension */
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /** @domName SVGTransformable.transform */
  final SVGAnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGDescElement
class SVGDescElement extends SVGElement implements SVGLangSpace, SVGStylable native "*SVGDescElement" {

  factory SVGDescElement() => _SvgElementFactoryProvider.createSVGElement_tag("desc");

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGStylable

  /** @domName SVGStylable.className */
  SVGAnimatedString get $dom_svgClassName => JS("SVGAnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGDocument
class SVGDocument extends Document native "*SVGDocument" {

  /** @domName SVGDocument.rootElement */
  final SVGSVGElement rootElement;

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

class SVGElement extends Element native "*SVGElement" {
  factory SVGElement.tag(String tag) =>
      _SVGElementFactoryProvider.createSVGElement_tag(tag);
  factory SVGElement.svg(String svg) =>
      _SVGElementFactoryProvider.createSVGElement_svg(svg);

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
    final SVGElement cloned = this.clone(true);
    container.elements.add(cloned);
    return container.innerHTML;
  }

  String get innerHTML {
    final container = new Element.tag("div");
    final SVGElement cloned = this.clone(true);
    container.elements.addAll(cloned.elements);
    return container.innerHTML;
  }

  void set innerHTML(String svg) {
    final container = new Element.tag("div");
    // Wrap the SVG string in <svg> so that SVGElements are created, rather than
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
  final SVGSVGElement ownerSVGElement;

  /** @domName SVGElement.viewportElement */
  final SVGElement viewportElement;

  /** @domName SVGElement.xmlbase */
  String xmlbase;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGElementInstance
class SVGElementInstance extends EventTarget native "*SVGElementInstance" {

  /**
   * @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent
   */
  SVGElementInstanceEvents get on =>
    new SVGElementInstanceEvents(this);

  /** @domName SVGElementInstance.childNodes */
  final List<SVGElementInstance> childNodes;

  /** @domName SVGElementInstance.correspondingElement */
  final SVGElement correspondingElement;

  /** @domName SVGElementInstance.correspondingUseElement */
  final SVGUseElement correspondingUseElement;

  /** @domName SVGElementInstance.firstChild */
  final SVGElementInstance firstChild;

  /** @domName SVGElementInstance.lastChild */
  final SVGElementInstance lastChild;

  /** @domName SVGElementInstance.nextSibling */
  final SVGElementInstance nextSibling;

  /** @domName SVGElementInstance.parentNode */
  final SVGElementInstance parentNode;

  /** @domName SVGElementInstance.previousSibling */
  final SVGElementInstance previousSibling;
}

class SVGElementInstanceEvents extends Events {
  SVGElementInstanceEvents(EventTarget _ptr) : super(_ptr);

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
class SVGEllipseElement extends SVGElement implements SVGLangSpace, SVGStylable, SVGTests, SVGTransformable, SVGExternalResourcesRequired native "*SVGEllipseElement" {

  factory SVGEllipseElement() => _SvgElementFactoryProvider.createSVGElement_tag("ellipse");

  /** @domName SVGEllipseElement.cx */
  final SVGAnimatedLength cx;

  /** @domName SVGEllipseElement.cy */
  final SVGAnimatedLength cy;

  /** @domName SVGEllipseElement.rx */
  final SVGAnimatedLength rx;

  /** @domName SVGEllipseElement.ry */
  final SVGAnimatedLength ry;

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final SVGAnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGLocatable

  /** @domName SVGLocatable.farthestViewportElement */
  final SVGElement farthestViewportElement;

  /** @domName SVGLocatable.nearestViewportElement */
  final SVGElement nearestViewportElement;

  /** @domName SVGLocatable.getBBox */
  SVGRect getBBox() native;

  /** @domName SVGLocatable.getCTM */
  SVGMatrix getCTM() native;

  /** @domName SVGLocatable.getScreenCTM */
  SVGMatrix getScreenCTM() native;

  /** @domName SVGLocatable.getTransformToElement */
  SVGMatrix getTransformToElement(SVGElement element) native;

  // From SVGStylable

  /** @domName SVGStylable.className */
  SVGAnimatedString get $dom_svgClassName => JS("SVGAnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /** @domName SVGTests.requiredExtensions */
  final SVGStringList requiredExtensions;

  /** @domName SVGTests.requiredFeatures */
  final SVGStringList requiredFeatures;

  /** @domName SVGTests.systemLanguage */
  final SVGStringList systemLanguage;

  /** @domName SVGTests.hasExtension */
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /** @domName SVGTransformable.transform */
  final SVGAnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGException
class SVGException native "*SVGException" {

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
abstract class SVGExternalResourcesRequired {

  SVGAnimatedBoolean externalResourcesRequired;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEBlendElement
class SVGFEBlendElement extends SVGElement implements SVGFilterPrimitiveStandardAttributes native "*SVGFEBlendElement" {

  static const int SVG_FEBLEND_MODE_DARKEN = 4;

  static const int SVG_FEBLEND_MODE_LIGHTEN = 5;

  static const int SVG_FEBLEND_MODE_MULTIPLY = 2;

  static const int SVG_FEBLEND_MODE_NORMAL = 1;

  static const int SVG_FEBLEND_MODE_SCREEN = 3;

  static const int SVG_FEBLEND_MODE_UNKNOWN = 0;

  /** @domName SVGFEBlendElement.in1 */
  final SVGAnimatedString in1;

  /** @domName SVGFEBlendElement.in2 */
  final SVGAnimatedString in2;

  /** @domName SVGFEBlendElement.mode */
  final SVGAnimatedEnumeration mode;

  // From SVGFilterPrimitiveStandardAttributes

  /** @domName SVGFilterPrimitiveStandardAttributes.height */
  final SVGAnimatedLength height;

  /** @domName SVGFilterPrimitiveStandardAttributes.result */
  final SVGAnimatedString result;

  /** @domName SVGFilterPrimitiveStandardAttributes.width */
  final SVGAnimatedLength width;

  /** @domName SVGFilterPrimitiveStandardAttributes.x */
  final SVGAnimatedLength x;

  /** @domName SVGFilterPrimitiveStandardAttributes.y */
  final SVGAnimatedLength y;

  // From SVGStylable

  /** @domName SVGStylable.className */
  SVGAnimatedString get $dom_svgClassName => JS("SVGAnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEColorMatrixElement
class SVGFEColorMatrixElement extends SVGElement implements SVGFilterPrimitiveStandardAttributes native "*SVGFEColorMatrixElement" {

  static const int SVG_FECOLORMATRIX_TYPE_HUEROTATE = 3;

  static const int SVG_FECOLORMATRIX_TYPE_LUMINANCETOALPHA = 4;

  static const int SVG_FECOLORMATRIX_TYPE_MATRIX = 1;

  static const int SVG_FECOLORMATRIX_TYPE_SATURATE = 2;

  static const int SVG_FECOLORMATRIX_TYPE_UNKNOWN = 0;

  /** @domName SVGFEColorMatrixElement.in1 */
  final SVGAnimatedString in1;

  /** @domName SVGFEColorMatrixElement.type */
  final SVGAnimatedEnumeration type;

  /** @domName SVGFEColorMatrixElement.values */
  final SVGAnimatedNumberList values;

  // From SVGFilterPrimitiveStandardAttributes

  /** @domName SVGFilterPrimitiveStandardAttributes.height */
  final SVGAnimatedLength height;

  /** @domName SVGFilterPrimitiveStandardAttributes.result */
  final SVGAnimatedString result;

  /** @domName SVGFilterPrimitiveStandardAttributes.width */
  final SVGAnimatedLength width;

  /** @domName SVGFilterPrimitiveStandardAttributes.x */
  final SVGAnimatedLength x;

  /** @domName SVGFilterPrimitiveStandardAttributes.y */
  final SVGAnimatedLength y;

  // From SVGStylable

  /** @domName SVGStylable.className */
  SVGAnimatedString get $dom_svgClassName => JS("SVGAnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEComponentTransferElement
class SVGFEComponentTransferElement extends SVGElement implements SVGFilterPrimitiveStandardAttributes native "*SVGFEComponentTransferElement" {

  /** @domName SVGFEComponentTransferElement.in1 */
  final SVGAnimatedString in1;

  // From SVGFilterPrimitiveStandardAttributes

  /** @domName SVGFilterPrimitiveStandardAttributes.height */
  final SVGAnimatedLength height;

  /** @domName SVGFilterPrimitiveStandardAttributes.result */
  final SVGAnimatedString result;

  /** @domName SVGFilterPrimitiveStandardAttributes.width */
  final SVGAnimatedLength width;

  /** @domName SVGFilterPrimitiveStandardAttributes.x */
  final SVGAnimatedLength x;

  /** @domName SVGFilterPrimitiveStandardAttributes.y */
  final SVGAnimatedLength y;

  // From SVGStylable

  /** @domName SVGStylable.className */
  SVGAnimatedString get $dom_svgClassName => JS("SVGAnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFECompositeElement
class SVGFECompositeElement extends SVGElement implements SVGFilterPrimitiveStandardAttributes native "*SVGFECompositeElement" {

  static const int SVG_FECOMPOSITE_OPERATOR_ARITHMETIC = 6;

  static const int SVG_FECOMPOSITE_OPERATOR_ATOP = 4;

  static const int SVG_FECOMPOSITE_OPERATOR_IN = 2;

  static const int SVG_FECOMPOSITE_OPERATOR_OUT = 3;

  static const int SVG_FECOMPOSITE_OPERATOR_OVER = 1;

  static const int SVG_FECOMPOSITE_OPERATOR_UNKNOWN = 0;

  static const int SVG_FECOMPOSITE_OPERATOR_XOR = 5;

  /** @domName SVGFECompositeElement.in1 */
  final SVGAnimatedString in1;

  /** @domName SVGFECompositeElement.in2 */
  final SVGAnimatedString in2;

  /** @domName SVGFECompositeElement.k1 */
  final SVGAnimatedNumber k1;

  /** @domName SVGFECompositeElement.k2 */
  final SVGAnimatedNumber k2;

  /** @domName SVGFECompositeElement.k3 */
  final SVGAnimatedNumber k3;

  /** @domName SVGFECompositeElement.k4 */
  final SVGAnimatedNumber k4;

  /** @domName SVGFECompositeElement.operator */
  final SVGAnimatedEnumeration operator;

  // From SVGFilterPrimitiveStandardAttributes

  /** @domName SVGFilterPrimitiveStandardAttributes.height */
  final SVGAnimatedLength height;

  /** @domName SVGFilterPrimitiveStandardAttributes.result */
  final SVGAnimatedString result;

  /** @domName SVGFilterPrimitiveStandardAttributes.width */
  final SVGAnimatedLength width;

  /** @domName SVGFilterPrimitiveStandardAttributes.x */
  final SVGAnimatedLength x;

  /** @domName SVGFilterPrimitiveStandardAttributes.y */
  final SVGAnimatedLength y;

  // From SVGStylable

  /** @domName SVGStylable.className */
  SVGAnimatedString get $dom_svgClassName => JS("SVGAnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEConvolveMatrixElement
class SVGFEConvolveMatrixElement extends SVGElement implements SVGFilterPrimitiveStandardAttributes native "*SVGFEConvolveMatrixElement" {

  static const int SVG_EDGEMODE_DUPLICATE = 1;

  static const int SVG_EDGEMODE_NONE = 3;

  static const int SVG_EDGEMODE_UNKNOWN = 0;

  static const int SVG_EDGEMODE_WRAP = 2;

  /** @domName SVGFEConvolveMatrixElement.bias */
  final SVGAnimatedNumber bias;

  /** @domName SVGFEConvolveMatrixElement.divisor */
  final SVGAnimatedNumber divisor;

  /** @domName SVGFEConvolveMatrixElement.edgeMode */
  final SVGAnimatedEnumeration edgeMode;

  /** @domName SVGFEConvolveMatrixElement.in1 */
  final SVGAnimatedString in1;

  /** @domName SVGFEConvolveMatrixElement.kernelMatrix */
  final SVGAnimatedNumberList kernelMatrix;

  /** @domName SVGFEConvolveMatrixElement.kernelUnitLengthX */
  final SVGAnimatedNumber kernelUnitLengthX;

  /** @domName SVGFEConvolveMatrixElement.kernelUnitLengthY */
  final SVGAnimatedNumber kernelUnitLengthY;

  /** @domName SVGFEConvolveMatrixElement.orderX */
  final SVGAnimatedInteger orderX;

  /** @domName SVGFEConvolveMatrixElement.orderY */
  final SVGAnimatedInteger orderY;

  /** @domName SVGFEConvolveMatrixElement.preserveAlpha */
  final SVGAnimatedBoolean preserveAlpha;

  /** @domName SVGFEConvolveMatrixElement.targetX */
  final SVGAnimatedInteger targetX;

  /** @domName SVGFEConvolveMatrixElement.targetY */
  final SVGAnimatedInteger targetY;

  // From SVGFilterPrimitiveStandardAttributes

  /** @domName SVGFilterPrimitiveStandardAttributes.height */
  final SVGAnimatedLength height;

  /** @domName SVGFilterPrimitiveStandardAttributes.result */
  final SVGAnimatedString result;

  /** @domName SVGFilterPrimitiveStandardAttributes.width */
  final SVGAnimatedLength width;

  /** @domName SVGFilterPrimitiveStandardAttributes.x */
  final SVGAnimatedLength x;

  /** @domName SVGFilterPrimitiveStandardAttributes.y */
  final SVGAnimatedLength y;

  // From SVGStylable

  /** @domName SVGStylable.className */
  SVGAnimatedString get $dom_svgClassName => JS("SVGAnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEDiffuseLightingElement
class SVGFEDiffuseLightingElement extends SVGElement implements SVGFilterPrimitiveStandardAttributes native "*SVGFEDiffuseLightingElement" {

  /** @domName SVGFEDiffuseLightingElement.diffuseConstant */
  final SVGAnimatedNumber diffuseConstant;

  /** @domName SVGFEDiffuseLightingElement.in1 */
  final SVGAnimatedString in1;

  /** @domName SVGFEDiffuseLightingElement.kernelUnitLengthX */
  final SVGAnimatedNumber kernelUnitLengthX;

  /** @domName SVGFEDiffuseLightingElement.kernelUnitLengthY */
  final SVGAnimatedNumber kernelUnitLengthY;

  /** @domName SVGFEDiffuseLightingElement.surfaceScale */
  final SVGAnimatedNumber surfaceScale;

  // From SVGFilterPrimitiveStandardAttributes

  /** @domName SVGFilterPrimitiveStandardAttributes.height */
  final SVGAnimatedLength height;

  /** @domName SVGFilterPrimitiveStandardAttributes.result */
  final SVGAnimatedString result;

  /** @domName SVGFilterPrimitiveStandardAttributes.width */
  final SVGAnimatedLength width;

  /** @domName SVGFilterPrimitiveStandardAttributes.x */
  final SVGAnimatedLength x;

  /** @domName SVGFilterPrimitiveStandardAttributes.y */
  final SVGAnimatedLength y;

  // From SVGStylable

  /** @domName SVGStylable.className */
  SVGAnimatedString get $dom_svgClassName => JS("SVGAnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEDisplacementMapElement
class SVGFEDisplacementMapElement extends SVGElement implements SVGFilterPrimitiveStandardAttributes native "*SVGFEDisplacementMapElement" {

  static const int SVG_CHANNEL_A = 4;

  static const int SVG_CHANNEL_B = 3;

  static const int SVG_CHANNEL_G = 2;

  static const int SVG_CHANNEL_R = 1;

  static const int SVG_CHANNEL_UNKNOWN = 0;

  /** @domName SVGFEDisplacementMapElement.in1 */
  final SVGAnimatedString in1;

  /** @domName SVGFEDisplacementMapElement.in2 */
  final SVGAnimatedString in2;

  /** @domName SVGFEDisplacementMapElement.scale */
  final SVGAnimatedNumber scale;

  /** @domName SVGFEDisplacementMapElement.xChannelSelector */
  final SVGAnimatedEnumeration xChannelSelector;

  /** @domName SVGFEDisplacementMapElement.yChannelSelector */
  final SVGAnimatedEnumeration yChannelSelector;

  // From SVGFilterPrimitiveStandardAttributes

  /** @domName SVGFilterPrimitiveStandardAttributes.height */
  final SVGAnimatedLength height;

  /** @domName SVGFilterPrimitiveStandardAttributes.result */
  final SVGAnimatedString result;

  /** @domName SVGFilterPrimitiveStandardAttributes.width */
  final SVGAnimatedLength width;

  /** @domName SVGFilterPrimitiveStandardAttributes.x */
  final SVGAnimatedLength x;

  /** @domName SVGFilterPrimitiveStandardAttributes.y */
  final SVGAnimatedLength y;

  // From SVGStylable

  /** @domName SVGStylable.className */
  SVGAnimatedString get $dom_svgClassName => JS("SVGAnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEDistantLightElement
class SVGFEDistantLightElement extends SVGElement native "*SVGFEDistantLightElement" {

  /** @domName SVGFEDistantLightElement.azimuth */
  final SVGAnimatedNumber azimuth;

  /** @domName SVGFEDistantLightElement.elevation */
  final SVGAnimatedNumber elevation;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEDropShadowElement
class SVGFEDropShadowElement extends SVGElement implements SVGFilterPrimitiveStandardAttributes native "*SVGFEDropShadowElement" {

  /** @domName SVGFEDropShadowElement.dx */
  final SVGAnimatedNumber dx;

  /** @domName SVGFEDropShadowElement.dy */
  final SVGAnimatedNumber dy;

  /** @domName SVGFEDropShadowElement.in1 */
  final SVGAnimatedString in1;

  /** @domName SVGFEDropShadowElement.stdDeviationX */
  final SVGAnimatedNumber stdDeviationX;

  /** @domName SVGFEDropShadowElement.stdDeviationY */
  final SVGAnimatedNumber stdDeviationY;

  /** @domName SVGFEDropShadowElement.setStdDeviation */
  void setStdDeviation(num stdDeviationX, num stdDeviationY) native;

  // From SVGFilterPrimitiveStandardAttributes

  /** @domName SVGFilterPrimitiveStandardAttributes.height */
  final SVGAnimatedLength height;

  /** @domName SVGFilterPrimitiveStandardAttributes.result */
  final SVGAnimatedString result;

  /** @domName SVGFilterPrimitiveStandardAttributes.width */
  final SVGAnimatedLength width;

  /** @domName SVGFilterPrimitiveStandardAttributes.x */
  final SVGAnimatedLength x;

  /** @domName SVGFilterPrimitiveStandardAttributes.y */
  final SVGAnimatedLength y;

  // From SVGStylable

  /** @domName SVGStylable.className */
  SVGAnimatedString get $dom_svgClassName => JS("SVGAnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEFloodElement
class SVGFEFloodElement extends SVGElement implements SVGFilterPrimitiveStandardAttributes native "*SVGFEFloodElement" {

  // From SVGFilterPrimitiveStandardAttributes

  /** @domName SVGFilterPrimitiveStandardAttributes.height */
  final SVGAnimatedLength height;

  /** @domName SVGFilterPrimitiveStandardAttributes.result */
  final SVGAnimatedString result;

  /** @domName SVGFilterPrimitiveStandardAttributes.width */
  final SVGAnimatedLength width;

  /** @domName SVGFilterPrimitiveStandardAttributes.x */
  final SVGAnimatedLength x;

  /** @domName SVGFilterPrimitiveStandardAttributes.y */
  final SVGAnimatedLength y;

  // From SVGStylable

  /** @domName SVGStylable.className */
  SVGAnimatedString get $dom_svgClassName => JS("SVGAnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEFuncAElement
class SVGFEFuncAElement extends SVGComponentTransferFunctionElement native "*SVGFEFuncAElement" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEFuncBElement
class SVGFEFuncBElement extends SVGComponentTransferFunctionElement native "*SVGFEFuncBElement" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEFuncGElement
class SVGFEFuncGElement extends SVGComponentTransferFunctionElement native "*SVGFEFuncGElement" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEFuncRElement
class SVGFEFuncRElement extends SVGComponentTransferFunctionElement native "*SVGFEFuncRElement" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEGaussianBlurElement
class SVGFEGaussianBlurElement extends SVGElement implements SVGFilterPrimitiveStandardAttributes native "*SVGFEGaussianBlurElement" {

  /** @domName SVGFEGaussianBlurElement.in1 */
  final SVGAnimatedString in1;

  /** @domName SVGFEGaussianBlurElement.stdDeviationX */
  final SVGAnimatedNumber stdDeviationX;

  /** @domName SVGFEGaussianBlurElement.stdDeviationY */
  final SVGAnimatedNumber stdDeviationY;

  /** @domName SVGFEGaussianBlurElement.setStdDeviation */
  void setStdDeviation(num stdDeviationX, num stdDeviationY) native;

  // From SVGFilterPrimitiveStandardAttributes

  /** @domName SVGFilterPrimitiveStandardAttributes.height */
  final SVGAnimatedLength height;

  /** @domName SVGFilterPrimitiveStandardAttributes.result */
  final SVGAnimatedString result;

  /** @domName SVGFilterPrimitiveStandardAttributes.width */
  final SVGAnimatedLength width;

  /** @domName SVGFilterPrimitiveStandardAttributes.x */
  final SVGAnimatedLength x;

  /** @domName SVGFilterPrimitiveStandardAttributes.y */
  final SVGAnimatedLength y;

  // From SVGStylable

  /** @domName SVGStylable.className */
  SVGAnimatedString get $dom_svgClassName => JS("SVGAnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEImageElement
class SVGFEImageElement extends SVGElement implements SVGURIReference, SVGLangSpace, SVGFilterPrimitiveStandardAttributes, SVGExternalResourcesRequired native "*SVGFEImageElement" {

  /** @domName SVGFEImageElement.preserveAspectRatio */
  final SVGAnimatedPreserveAspectRatio preserveAspectRatio;

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final SVGAnimatedBoolean externalResourcesRequired;

  // From SVGFilterPrimitiveStandardAttributes

  /** @domName SVGFilterPrimitiveStandardAttributes.height */
  final SVGAnimatedLength height;

  /** @domName SVGFilterPrimitiveStandardAttributes.result */
  final SVGAnimatedString result;

  /** @domName SVGFilterPrimitiveStandardAttributes.width */
  final SVGAnimatedLength width;

  /** @domName SVGFilterPrimitiveStandardAttributes.x */
  final SVGAnimatedLength x;

  /** @domName SVGFilterPrimitiveStandardAttributes.y */
  final SVGAnimatedLength y;

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGStylable

  /** @domName SVGStylable.className */
  SVGAnimatedString get $dom_svgClassName => JS("SVGAnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;

  // From SVGURIReference

  /** @domName SVGURIReference.href */
  final SVGAnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEMergeElement
class SVGFEMergeElement extends SVGElement implements SVGFilterPrimitiveStandardAttributes native "*SVGFEMergeElement" {

  // From SVGFilterPrimitiveStandardAttributes

  /** @domName SVGFilterPrimitiveStandardAttributes.height */
  final SVGAnimatedLength height;

  /** @domName SVGFilterPrimitiveStandardAttributes.result */
  final SVGAnimatedString result;

  /** @domName SVGFilterPrimitiveStandardAttributes.width */
  final SVGAnimatedLength width;

  /** @domName SVGFilterPrimitiveStandardAttributes.x */
  final SVGAnimatedLength x;

  /** @domName SVGFilterPrimitiveStandardAttributes.y */
  final SVGAnimatedLength y;

  // From SVGStylable

  /** @domName SVGStylable.className */
  SVGAnimatedString get $dom_svgClassName => JS("SVGAnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEMergeNodeElement
class SVGFEMergeNodeElement extends SVGElement native "*SVGFEMergeNodeElement" {

  /** @domName SVGFEMergeNodeElement.in1 */
  final SVGAnimatedString in1;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEMorphologyElement
class SVGFEMorphologyElement extends SVGElement implements SVGFilterPrimitiveStandardAttributes native "*SVGFEMorphologyElement" {

  static const int SVG_MORPHOLOGY_OPERATOR_DILATE = 2;

  static const int SVG_MORPHOLOGY_OPERATOR_ERODE = 1;

  static const int SVG_MORPHOLOGY_OPERATOR_UNKNOWN = 0;

  /** @domName SVGFEMorphologyElement.in1 */
  final SVGAnimatedString in1;

  /** @domName SVGFEMorphologyElement.operator */
  final SVGAnimatedEnumeration operator;

  /** @domName SVGFEMorphologyElement.radiusX */
  final SVGAnimatedNumber radiusX;

  /** @domName SVGFEMorphologyElement.radiusY */
  final SVGAnimatedNumber radiusY;

  /** @domName SVGFEMorphologyElement.setRadius */
  void setRadius(num radiusX, num radiusY) native;

  // From SVGFilterPrimitiveStandardAttributes

  /** @domName SVGFilterPrimitiveStandardAttributes.height */
  final SVGAnimatedLength height;

  /** @domName SVGFilterPrimitiveStandardAttributes.result */
  final SVGAnimatedString result;

  /** @domName SVGFilterPrimitiveStandardAttributes.width */
  final SVGAnimatedLength width;

  /** @domName SVGFilterPrimitiveStandardAttributes.x */
  final SVGAnimatedLength x;

  /** @domName SVGFilterPrimitiveStandardAttributes.y */
  final SVGAnimatedLength y;

  // From SVGStylable

  /** @domName SVGStylable.className */
  SVGAnimatedString get $dom_svgClassName => JS("SVGAnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEOffsetElement
class SVGFEOffsetElement extends SVGElement implements SVGFilterPrimitiveStandardAttributes native "*SVGFEOffsetElement" {

  /** @domName SVGFEOffsetElement.dx */
  final SVGAnimatedNumber dx;

  /** @domName SVGFEOffsetElement.dy */
  final SVGAnimatedNumber dy;

  /** @domName SVGFEOffsetElement.in1 */
  final SVGAnimatedString in1;

  // From SVGFilterPrimitiveStandardAttributes

  /** @domName SVGFilterPrimitiveStandardAttributes.height */
  final SVGAnimatedLength height;

  /** @domName SVGFilterPrimitiveStandardAttributes.result */
  final SVGAnimatedString result;

  /** @domName SVGFilterPrimitiveStandardAttributes.width */
  final SVGAnimatedLength width;

  /** @domName SVGFilterPrimitiveStandardAttributes.x */
  final SVGAnimatedLength x;

  /** @domName SVGFilterPrimitiveStandardAttributes.y */
  final SVGAnimatedLength y;

  // From SVGStylable

  /** @domName SVGStylable.className */
  SVGAnimatedString get $dom_svgClassName => JS("SVGAnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFEPointLightElement
class SVGFEPointLightElement extends SVGElement native "*SVGFEPointLightElement" {

  /** @domName SVGFEPointLightElement.x */
  final SVGAnimatedNumber x;

  /** @domName SVGFEPointLightElement.y */
  final SVGAnimatedNumber y;

  /** @domName SVGFEPointLightElement.z */
  final SVGAnimatedNumber z;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFESpecularLightingElement
class SVGFESpecularLightingElement extends SVGElement implements SVGFilterPrimitiveStandardAttributes native "*SVGFESpecularLightingElement" {

  /** @domName SVGFESpecularLightingElement.in1 */
  final SVGAnimatedString in1;

  /** @domName SVGFESpecularLightingElement.specularConstant */
  final SVGAnimatedNumber specularConstant;

  /** @domName SVGFESpecularLightingElement.specularExponent */
  final SVGAnimatedNumber specularExponent;

  /** @domName SVGFESpecularLightingElement.surfaceScale */
  final SVGAnimatedNumber surfaceScale;

  // From SVGFilterPrimitiveStandardAttributes

  /** @domName SVGFilterPrimitiveStandardAttributes.height */
  final SVGAnimatedLength height;

  /** @domName SVGFilterPrimitiveStandardAttributes.result */
  final SVGAnimatedString result;

  /** @domName SVGFilterPrimitiveStandardAttributes.width */
  final SVGAnimatedLength width;

  /** @domName SVGFilterPrimitiveStandardAttributes.x */
  final SVGAnimatedLength x;

  /** @domName SVGFilterPrimitiveStandardAttributes.y */
  final SVGAnimatedLength y;

  // From SVGStylable

  /** @domName SVGStylable.className */
  SVGAnimatedString get $dom_svgClassName => JS("SVGAnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFESpotLightElement
class SVGFESpotLightElement extends SVGElement native "*SVGFESpotLightElement" {

  /** @domName SVGFESpotLightElement.limitingConeAngle */
  final SVGAnimatedNumber limitingConeAngle;

  /** @domName SVGFESpotLightElement.pointsAtX */
  final SVGAnimatedNumber pointsAtX;

  /** @domName SVGFESpotLightElement.pointsAtY */
  final SVGAnimatedNumber pointsAtY;

  /** @domName SVGFESpotLightElement.pointsAtZ */
  final SVGAnimatedNumber pointsAtZ;

  /** @domName SVGFESpotLightElement.specularExponent */
  final SVGAnimatedNumber specularExponent;

  /** @domName SVGFESpotLightElement.x */
  final SVGAnimatedNumber x;

  /** @domName SVGFESpotLightElement.y */
  final SVGAnimatedNumber y;

  /** @domName SVGFESpotLightElement.z */
  final SVGAnimatedNumber z;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFETileElement
class SVGFETileElement extends SVGElement implements SVGFilterPrimitiveStandardAttributes native "*SVGFETileElement" {

  /** @domName SVGFETileElement.in1 */
  final SVGAnimatedString in1;

  // From SVGFilterPrimitiveStandardAttributes

  /** @domName SVGFilterPrimitiveStandardAttributes.height */
  final SVGAnimatedLength height;

  /** @domName SVGFilterPrimitiveStandardAttributes.result */
  final SVGAnimatedString result;

  /** @domName SVGFilterPrimitiveStandardAttributes.width */
  final SVGAnimatedLength width;

  /** @domName SVGFilterPrimitiveStandardAttributes.x */
  final SVGAnimatedLength x;

  /** @domName SVGFilterPrimitiveStandardAttributes.y */
  final SVGAnimatedLength y;

  // From SVGStylable

  /** @domName SVGStylable.className */
  SVGAnimatedString get $dom_svgClassName => JS("SVGAnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFETurbulenceElement
class SVGFETurbulenceElement extends SVGElement implements SVGFilterPrimitiveStandardAttributes native "*SVGFETurbulenceElement" {

  static const int SVG_STITCHTYPE_NOSTITCH = 2;

  static const int SVG_STITCHTYPE_STITCH = 1;

  static const int SVG_STITCHTYPE_UNKNOWN = 0;

  static const int SVG_TURBULENCE_TYPE_FRACTALNOISE = 1;

  static const int SVG_TURBULENCE_TYPE_TURBULENCE = 2;

  static const int SVG_TURBULENCE_TYPE_UNKNOWN = 0;

  /** @domName SVGFETurbulenceElement.baseFrequencyX */
  final SVGAnimatedNumber baseFrequencyX;

  /** @domName SVGFETurbulenceElement.baseFrequencyY */
  final SVGAnimatedNumber baseFrequencyY;

  /** @domName SVGFETurbulenceElement.numOctaves */
  final SVGAnimatedInteger numOctaves;

  /** @domName SVGFETurbulenceElement.seed */
  final SVGAnimatedNumber seed;

  /** @domName SVGFETurbulenceElement.stitchTiles */
  final SVGAnimatedEnumeration stitchTiles;

  /** @domName SVGFETurbulenceElement.type */
  final SVGAnimatedEnumeration type;

  // From SVGFilterPrimitiveStandardAttributes

  /** @domName SVGFilterPrimitiveStandardAttributes.height */
  final SVGAnimatedLength height;

  /** @domName SVGFilterPrimitiveStandardAttributes.result */
  final SVGAnimatedString result;

  /** @domName SVGFilterPrimitiveStandardAttributes.width */
  final SVGAnimatedLength width;

  /** @domName SVGFilterPrimitiveStandardAttributes.x */
  final SVGAnimatedLength x;

  /** @domName SVGFilterPrimitiveStandardAttributes.y */
  final SVGAnimatedLength y;

  // From SVGStylable

  /** @domName SVGStylable.className */
  SVGAnimatedString get $dom_svgClassName => JS("SVGAnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFilterElement
class SVGFilterElement extends SVGElement implements SVGURIReference, SVGLangSpace, SVGExternalResourcesRequired, SVGStylable native "*SVGFilterElement" {

  factory SVGFilterElement() => _SvgElementFactoryProvider.createSVGElement_tag("filter");

  /** @domName SVGFilterElement.filterResX */
  final SVGAnimatedInteger filterResX;

  /** @domName SVGFilterElement.filterResY */
  final SVGAnimatedInteger filterResY;

  /** @domName SVGFilterElement.filterUnits */
  final SVGAnimatedEnumeration filterUnits;

  /** @domName SVGFilterElement.height */
  final SVGAnimatedLength height;

  /** @domName SVGFilterElement.primitiveUnits */
  final SVGAnimatedEnumeration primitiveUnits;

  /** @domName SVGFilterElement.width */
  final SVGAnimatedLength width;

  /** @domName SVGFilterElement.x */
  final SVGAnimatedLength x;

  /** @domName SVGFilterElement.y */
  final SVGAnimatedLength y;

  /** @domName SVGFilterElement.setFilterRes */
  void setFilterRes(int filterResX, int filterResY) native;

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final SVGAnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGStylable

  /** @domName SVGStylable.className */
  SVGAnimatedString get $dom_svgClassName => JS("SVGAnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;

  // From SVGURIReference

  /** @domName SVGURIReference.href */
  final SVGAnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFilterPrimitiveStandardAttributes
abstract class SVGFilterPrimitiveStandardAttributes implements SVGStylable {

  SVGAnimatedLength height;

  SVGAnimatedString result;

  SVGAnimatedLength width;

  SVGAnimatedLength x;

  SVGAnimatedLength y;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFitToViewBox
abstract class SVGFitToViewBox {

  SVGAnimatedPreserveAspectRatio preserveAspectRatio;

  SVGAnimatedRect viewBox;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFontElement
class SVGFontElement extends SVGElement native "*SVGFontElement" {

  factory SVGFontElement() => _SvgElementFactoryProvider.createSVGElement_tag("font");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFontFaceElement
class SVGFontFaceElement extends SVGElement native "*SVGFontFaceElement" {

  factory SVGFontFaceElement() => _SvgElementFactoryProvider.createSVGElement_tag("font-face");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFontFaceFormatElement
class SVGFontFaceFormatElement extends SVGElement native "*SVGFontFaceFormatElement" {

  factory SVGFontFaceFormatElement() => _SvgElementFactoryProvider.createSVGElement_tag("font-face-format");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFontFaceNameElement
class SVGFontFaceNameElement extends SVGElement native "*SVGFontFaceNameElement" {

  factory SVGFontFaceNameElement() => _SvgElementFactoryProvider.createSVGElement_tag("font-face-name");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFontFaceSrcElement
class SVGFontFaceSrcElement extends SVGElement native "*SVGFontFaceSrcElement" {

  factory SVGFontFaceSrcElement() => _SvgElementFactoryProvider.createSVGElement_tag("font-face-src");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGFontFaceUriElement
class SVGFontFaceUriElement extends SVGElement native "*SVGFontFaceUriElement" {

  factory SVGFontFaceUriElement() => _SvgElementFactoryProvider.createSVGElement_tag("font-face-uri");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGForeignObjectElement
class SVGForeignObjectElement extends SVGElement implements SVGLangSpace, SVGStylable, SVGTests, SVGTransformable, SVGExternalResourcesRequired native "*SVGForeignObjectElement" {

  factory SVGForeignObjectElement() => _SvgElementFactoryProvider.createSVGElement_tag("foreignObject");

  /** @domName SVGForeignObjectElement.height */
  final SVGAnimatedLength height;

  /** @domName SVGForeignObjectElement.width */
  final SVGAnimatedLength width;

  /** @domName SVGForeignObjectElement.x */
  final SVGAnimatedLength x;

  /** @domName SVGForeignObjectElement.y */
  final SVGAnimatedLength y;

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final SVGAnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGLocatable

  /** @domName SVGLocatable.farthestViewportElement */
  final SVGElement farthestViewportElement;

  /** @domName SVGLocatable.nearestViewportElement */
  final SVGElement nearestViewportElement;

  /** @domName SVGLocatable.getBBox */
  SVGRect getBBox() native;

  /** @domName SVGLocatable.getCTM */
  SVGMatrix getCTM() native;

  /** @domName SVGLocatable.getScreenCTM */
  SVGMatrix getScreenCTM() native;

  /** @domName SVGLocatable.getTransformToElement */
  SVGMatrix getTransformToElement(SVGElement element) native;

  // From SVGStylable

  /** @domName SVGStylable.className */
  SVGAnimatedString get $dom_svgClassName => JS("SVGAnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /** @domName SVGTests.requiredExtensions */
  final SVGStringList requiredExtensions;

  /** @domName SVGTests.requiredFeatures */
  final SVGStringList requiredFeatures;

  /** @domName SVGTests.systemLanguage */
  final SVGStringList systemLanguage;

  /** @domName SVGTests.hasExtension */
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /** @domName SVGTransformable.transform */
  final SVGAnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGGElement
class SVGGElement extends SVGElement implements SVGLangSpace, SVGStylable, SVGTests, SVGTransformable, SVGExternalResourcesRequired native "*SVGGElement" {

  factory SVGGElement() => _SvgElementFactoryProvider.createSVGElement_tag("g");

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final SVGAnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGLocatable

  /** @domName SVGLocatable.farthestViewportElement */
  final SVGElement farthestViewportElement;

  /** @domName SVGLocatable.nearestViewportElement */
  final SVGElement nearestViewportElement;

  /** @domName SVGLocatable.getBBox */
  SVGRect getBBox() native;

  /** @domName SVGLocatable.getCTM */
  SVGMatrix getCTM() native;

  /** @domName SVGLocatable.getScreenCTM */
  SVGMatrix getScreenCTM() native;

  /** @domName SVGLocatable.getTransformToElement */
  SVGMatrix getTransformToElement(SVGElement element) native;

  // From SVGStylable

  /** @domName SVGStylable.className */
  SVGAnimatedString get $dom_svgClassName => JS("SVGAnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /** @domName SVGTests.requiredExtensions */
  final SVGStringList requiredExtensions;

  /** @domName SVGTests.requiredFeatures */
  final SVGStringList requiredFeatures;

  /** @domName SVGTests.systemLanguage */
  final SVGStringList systemLanguage;

  /** @domName SVGTests.hasExtension */
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /** @domName SVGTransformable.transform */
  final SVGAnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGGlyphElement
class SVGGlyphElement extends SVGElement native "*SVGGlyphElement" {

  factory SVGGlyphElement() => _SvgElementFactoryProvider.createSVGElement_tag("glyph");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGGlyphRefElement
class SVGGlyphRefElement extends SVGElement implements SVGURIReference, SVGStylable native "*SVGGlyphRefElement" {

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
  SVGAnimatedString get $dom_svgClassName => JS("SVGAnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;

  // From SVGURIReference

  /** @domName SVGURIReference.href */
  final SVGAnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGGradientElement
class SVGGradientElement extends SVGElement implements SVGURIReference, SVGExternalResourcesRequired, SVGStylable native "*SVGGradientElement" {

  static const int SVG_SPREADMETHOD_PAD = 1;

  static const int SVG_SPREADMETHOD_REFLECT = 2;

  static const int SVG_SPREADMETHOD_REPEAT = 3;

  static const int SVG_SPREADMETHOD_UNKNOWN = 0;

  /** @domName SVGGradientElement.gradientTransform */
  final SVGAnimatedTransformList gradientTransform;

  /** @domName SVGGradientElement.gradientUnits */
  final SVGAnimatedEnumeration gradientUnits;

  /** @domName SVGGradientElement.spreadMethod */
  final SVGAnimatedEnumeration spreadMethod;

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final SVGAnimatedBoolean externalResourcesRequired;

  // From SVGStylable

  /** @domName SVGStylable.className */
  SVGAnimatedString get $dom_svgClassName => JS("SVGAnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;

  // From SVGURIReference

  /** @domName SVGURIReference.href */
  final SVGAnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGHKernElement
class SVGHKernElement extends SVGElement native "*SVGHKernElement" {

  factory SVGHKernElement() => _SvgElementFactoryProvider.createSVGElement_tag("hkern");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGImageElement
class SVGImageElement extends SVGElement implements SVGLangSpace, SVGTests, SVGStylable, SVGURIReference, SVGExternalResourcesRequired, SVGTransformable native "*SVGImageElement" {

  factory SVGImageElement() => _SvgElementFactoryProvider.createSVGElement_tag("image");

  /** @domName SVGImageElement.height */
  final SVGAnimatedLength height;

  /** @domName SVGImageElement.preserveAspectRatio */
  final SVGAnimatedPreserveAspectRatio preserveAspectRatio;

  /** @domName SVGImageElement.width */
  final SVGAnimatedLength width;

  /** @domName SVGImageElement.x */
  final SVGAnimatedLength x;

  /** @domName SVGImageElement.y */
  final SVGAnimatedLength y;

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final SVGAnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGLocatable

  /** @domName SVGLocatable.farthestViewportElement */
  final SVGElement farthestViewportElement;

  /** @domName SVGLocatable.nearestViewportElement */
  final SVGElement nearestViewportElement;

  /** @domName SVGLocatable.getBBox */
  SVGRect getBBox() native;

  /** @domName SVGLocatable.getCTM */
  SVGMatrix getCTM() native;

  /** @domName SVGLocatable.getScreenCTM */
  SVGMatrix getScreenCTM() native;

  /** @domName SVGLocatable.getTransformToElement */
  SVGMatrix getTransformToElement(SVGElement element) native;

  // From SVGStylable

  /** @domName SVGStylable.className */
  SVGAnimatedString get $dom_svgClassName => JS("SVGAnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /** @domName SVGTests.requiredExtensions */
  final SVGStringList requiredExtensions;

  /** @domName SVGTests.requiredFeatures */
  final SVGStringList requiredFeatures;

  /** @domName SVGTests.systemLanguage */
  final SVGStringList systemLanguage;

  /** @domName SVGTests.hasExtension */
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /** @domName SVGTransformable.transform */
  final SVGAnimatedTransformList transform;

  // From SVGURIReference

  /** @domName SVGURIReference.href */
  final SVGAnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGLangSpace
abstract class SVGLangSpace {

  String xmllang;

  String xmlspace;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGLength
class SVGLength native "*SVGLength" {

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
class SVGLengthList implements JavaScriptIndexingBehavior, List<SVGLength> native "*SVGLengthList" {

  /** @domName SVGLengthList.numberOfItems */
  final int numberOfItems;

  SVGLength operator[](int index) => JS("SVGLength", "#[#]", this, index);

  void operator[]=(int index, SVGLength value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<SVGLength> mixins.
  // SVGLength is the element type.

  // From Iterable<SVGLength>:

  Iterator<SVGLength> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<SVGLength>(this);
  }

  // From Collection<SVGLength>:

  void add(SVGLength value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(SVGLength value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<SVGLength> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(SVGLength element) => _Collections.contains(this, element);

  void forEach(void f(SVGLength element)) => _Collections.forEach(this, f);

  Collection map(f(SVGLength element)) => _Collections.map(this, [], f);

  Collection<SVGLength> filter(bool f(SVGLength element)) =>
     _Collections.filter(this, <SVGLength>[], f);

  bool every(bool f(SVGLength element)) => _Collections.every(this, f);

  bool some(bool f(SVGLength element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<SVGLength>:

  void sort([Comparator<SVGLength> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(SVGLength element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(SVGLength element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  SVGLength get last => this[length - 1];

  SVGLength removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<SVGLength> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [SVGLength initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<SVGLength> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <SVGLength>[]);

  // -- end List<SVGLength> mixins.

  /** @domName SVGLengthList.appendItem */
  SVGLength appendItem(SVGLength item) native;

  /** @domName SVGLengthList.clear */
  void clear() native;

  /** @domName SVGLengthList.getItem */
  SVGLength getItem(int index) native;

  /** @domName SVGLengthList.initialize */
  SVGLength initialize(SVGLength item) native;

  /** @domName SVGLengthList.insertItemBefore */
  SVGLength insertItemBefore(SVGLength item, int index) native;

  /** @domName SVGLengthList.removeItem */
  SVGLength removeItem(int index) native;

  /** @domName SVGLengthList.replaceItem */
  SVGLength replaceItem(SVGLength item, int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGLineElement
class SVGLineElement extends SVGElement implements SVGLangSpace, SVGStylable, SVGTests, SVGTransformable, SVGExternalResourcesRequired native "*SVGLineElement" {

  factory SVGLineElement() => _SvgElementFactoryProvider.createSVGElement_tag("line");

  /** @domName SVGLineElement.x1 */
  final SVGAnimatedLength x1;

  /** @domName SVGLineElement.x2 */
  final SVGAnimatedLength x2;

  /** @domName SVGLineElement.y1 */
  final SVGAnimatedLength y1;

  /** @domName SVGLineElement.y2 */
  final SVGAnimatedLength y2;

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final SVGAnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGLocatable

  /** @domName SVGLocatable.farthestViewportElement */
  final SVGElement farthestViewportElement;

  /** @domName SVGLocatable.nearestViewportElement */
  final SVGElement nearestViewportElement;

  /** @domName SVGLocatable.getBBox */
  SVGRect getBBox() native;

  /** @domName SVGLocatable.getCTM */
  SVGMatrix getCTM() native;

  /** @domName SVGLocatable.getScreenCTM */
  SVGMatrix getScreenCTM() native;

  /** @domName SVGLocatable.getTransformToElement */
  SVGMatrix getTransformToElement(SVGElement element) native;

  // From SVGStylable

  /** @domName SVGStylable.className */
  SVGAnimatedString get $dom_svgClassName => JS("SVGAnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /** @domName SVGTests.requiredExtensions */
  final SVGStringList requiredExtensions;

  /** @domName SVGTests.requiredFeatures */
  final SVGStringList requiredFeatures;

  /** @domName SVGTests.systemLanguage */
  final SVGStringList systemLanguage;

  /** @domName SVGTests.hasExtension */
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /** @domName SVGTransformable.transform */
  final SVGAnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGLinearGradientElement
class SVGLinearGradientElement extends SVGGradientElement native "*SVGLinearGradientElement" {

  factory SVGLinearGradientElement() => _SvgElementFactoryProvider.createSVGElement_tag("linearGradient");

  /** @domName SVGLinearGradientElement.x1 */
  final SVGAnimatedLength x1;

  /** @domName SVGLinearGradientElement.x2 */
  final SVGAnimatedLength x2;

  /** @domName SVGLinearGradientElement.y1 */
  final SVGAnimatedLength y1;

  /** @domName SVGLinearGradientElement.y2 */
  final SVGAnimatedLength y2;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGLocatable
abstract class SVGLocatable {

  SVGElement farthestViewportElement;

  SVGElement nearestViewportElement;

  /** @domName SVGLocatable.getBBox */
  SVGRect getBBox();

  /** @domName SVGLocatable.getCTM */
  SVGMatrix getCTM();

  /** @domName SVGLocatable.getScreenCTM */
  SVGMatrix getScreenCTM();

  /** @domName SVGLocatable.getTransformToElement */
  SVGMatrix getTransformToElement(SVGElement element);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGMPathElement
class SVGMPathElement extends SVGElement implements SVGURIReference, SVGExternalResourcesRequired native "*SVGMPathElement" {

  factory SVGMPathElement() => _SvgElementFactoryProvider.createSVGElement_tag("mpath");

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final SVGAnimatedBoolean externalResourcesRequired;

  // From SVGURIReference

  /** @domName SVGURIReference.href */
  final SVGAnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGMarkerElement
class SVGMarkerElement extends SVGElement implements SVGLangSpace, SVGFitToViewBox, SVGExternalResourcesRequired, SVGStylable native "*SVGMarkerElement" {

  factory SVGMarkerElement() => _SvgElementFactoryProvider.createSVGElement_tag("marker");

  static const int SVG_MARKERUNITS_STROKEWIDTH = 2;

  static const int SVG_MARKERUNITS_UNKNOWN = 0;

  static const int SVG_MARKERUNITS_USERSPACEONUSE = 1;

  static const int SVG_MARKER_ORIENT_ANGLE = 2;

  static const int SVG_MARKER_ORIENT_AUTO = 1;

  static const int SVG_MARKER_ORIENT_UNKNOWN = 0;

  /** @domName SVGMarkerElement.markerHeight */
  final SVGAnimatedLength markerHeight;

  /** @domName SVGMarkerElement.markerUnits */
  final SVGAnimatedEnumeration markerUnits;

  /** @domName SVGMarkerElement.markerWidth */
  final SVGAnimatedLength markerWidth;

  /** @domName SVGMarkerElement.orientAngle */
  final SVGAnimatedAngle orientAngle;

  /** @domName SVGMarkerElement.orientType */
  final SVGAnimatedEnumeration orientType;

  /** @domName SVGMarkerElement.refX */
  final SVGAnimatedLength refX;

  /** @domName SVGMarkerElement.refY */
  final SVGAnimatedLength refY;

  /** @domName SVGMarkerElement.setOrientToAngle */
  void setOrientToAngle(SVGAngle angle) native;

  /** @domName SVGMarkerElement.setOrientToAuto */
  void setOrientToAuto() native;

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final SVGAnimatedBoolean externalResourcesRequired;

  // From SVGFitToViewBox

  /** @domName SVGFitToViewBox.preserveAspectRatio */
  final SVGAnimatedPreserveAspectRatio preserveAspectRatio;

  /** @domName SVGFitToViewBox.viewBox */
  final SVGAnimatedRect viewBox;

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGStylable

  /** @domName SVGStylable.className */
  SVGAnimatedString get $dom_svgClassName => JS("SVGAnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGMaskElement
class SVGMaskElement extends SVGElement implements SVGLangSpace, SVGStylable, SVGTests, SVGExternalResourcesRequired native "*SVGMaskElement" {

  factory SVGMaskElement() => _SvgElementFactoryProvider.createSVGElement_tag("mask");

  /** @domName SVGMaskElement.height */
  final SVGAnimatedLength height;

  /** @domName SVGMaskElement.maskContentUnits */
  final SVGAnimatedEnumeration maskContentUnits;

  /** @domName SVGMaskElement.maskUnits */
  final SVGAnimatedEnumeration maskUnits;

  /** @domName SVGMaskElement.width */
  final SVGAnimatedLength width;

  /** @domName SVGMaskElement.x */
  final SVGAnimatedLength x;

  /** @domName SVGMaskElement.y */
  final SVGAnimatedLength y;

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final SVGAnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGStylable

  /** @domName SVGStylable.className */
  SVGAnimatedString get $dom_svgClassName => JS("SVGAnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /** @domName SVGTests.requiredExtensions */
  final SVGStringList requiredExtensions;

  /** @domName SVGTests.requiredFeatures */
  final SVGStringList requiredFeatures;

  /** @domName SVGTests.systemLanguage */
  final SVGStringList systemLanguage;

  /** @domName SVGTests.hasExtension */
  bool hasExtension(String extension) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGMatrix
class SVGMatrix native "*SVGMatrix" {

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
  SVGMatrix flipX() native;

  /** @domName SVGMatrix.flipY */
  SVGMatrix flipY() native;

  /** @domName SVGMatrix.inverse */
  SVGMatrix inverse() native;

  /** @domName SVGMatrix.multiply */
  SVGMatrix multiply(SVGMatrix secondMatrix) native;

  /** @domName SVGMatrix.rotate */
  SVGMatrix rotate(num angle) native;

  /** @domName SVGMatrix.rotateFromVector */
  SVGMatrix rotateFromVector(num x, num y) native;

  /** @domName SVGMatrix.scale */
  SVGMatrix scale(num scaleFactor) native;

  /** @domName SVGMatrix.scaleNonUniform */
  SVGMatrix scaleNonUniform(num scaleFactorX, num scaleFactorY) native;

  /** @domName SVGMatrix.skewX */
  SVGMatrix skewX(num angle) native;

  /** @domName SVGMatrix.skewY */
  SVGMatrix skewY(num angle) native;

  /** @domName SVGMatrix.translate */
  SVGMatrix translate(num x, num y) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGMetadataElement
class SVGMetadataElement extends SVGElement native "*SVGMetadataElement" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGMissingGlyphElement
class SVGMissingGlyphElement extends SVGElement native "*SVGMissingGlyphElement" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGNumber
class SVGNumber native "*SVGNumber" {

  /** @domName SVGNumber.value */
  num value;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGNumberList
class SVGNumberList implements JavaScriptIndexingBehavior, List<SVGNumber> native "*SVGNumberList" {

  /** @domName SVGNumberList.numberOfItems */
  final int numberOfItems;

  SVGNumber operator[](int index) => JS("SVGNumber", "#[#]", this, index);

  void operator[]=(int index, SVGNumber value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<SVGNumber> mixins.
  // SVGNumber is the element type.

  // From Iterable<SVGNumber>:

  Iterator<SVGNumber> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<SVGNumber>(this);
  }

  // From Collection<SVGNumber>:

  void add(SVGNumber value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(SVGNumber value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<SVGNumber> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(SVGNumber element) => _Collections.contains(this, element);

  void forEach(void f(SVGNumber element)) => _Collections.forEach(this, f);

  Collection map(f(SVGNumber element)) => _Collections.map(this, [], f);

  Collection<SVGNumber> filter(bool f(SVGNumber element)) =>
     _Collections.filter(this, <SVGNumber>[], f);

  bool every(bool f(SVGNumber element)) => _Collections.every(this, f);

  bool some(bool f(SVGNumber element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<SVGNumber>:

  void sort([Comparator<SVGNumber> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(SVGNumber element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(SVGNumber element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  SVGNumber get last => this[length - 1];

  SVGNumber removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<SVGNumber> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [SVGNumber initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<SVGNumber> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <SVGNumber>[]);

  // -- end List<SVGNumber> mixins.

  /** @domName SVGNumberList.appendItem */
  SVGNumber appendItem(SVGNumber item) native;

  /** @domName SVGNumberList.clear */
  void clear() native;

  /** @domName SVGNumberList.getItem */
  SVGNumber getItem(int index) native;

  /** @domName SVGNumberList.initialize */
  SVGNumber initialize(SVGNumber item) native;

  /** @domName SVGNumberList.insertItemBefore */
  SVGNumber insertItemBefore(SVGNumber item, int index) native;

  /** @domName SVGNumberList.removeItem */
  SVGNumber removeItem(int index) native;

  /** @domName SVGNumberList.replaceItem */
  SVGNumber replaceItem(SVGNumber item, int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPaint
class SVGPaint extends SVGColor native "*SVGPaint" {

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
class SVGPathElement extends SVGElement implements SVGLangSpace, SVGStylable, SVGTests, SVGTransformable, SVGExternalResourcesRequired native "*SVGPathElement" {

  factory SVGPathElement() => _SvgElementFactoryProvider.createSVGElement_tag("path");

  /** @domName SVGPathElement.animatedNormalizedPathSegList */
  final SVGPathSegList animatedNormalizedPathSegList;

  /** @domName SVGPathElement.animatedPathSegList */
  final SVGPathSegList animatedPathSegList;

  /** @domName SVGPathElement.normalizedPathSegList */
  final SVGPathSegList normalizedPathSegList;

  /** @domName SVGPathElement.pathLength */
  final SVGAnimatedNumber pathLength;

  /** @domName SVGPathElement.pathSegList */
  final SVGPathSegList pathSegList;

  /** @domName SVGPathElement.createSVGPathSegArcAbs */
  SVGPathSegArcAbs createSVGPathSegArcAbs(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) native;

  /** @domName SVGPathElement.createSVGPathSegArcRel */
  SVGPathSegArcRel createSVGPathSegArcRel(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) native;

  /** @domName SVGPathElement.createSVGPathSegClosePath */
  SVGPathSegClosePath createSVGPathSegClosePath() native;

  /** @domName SVGPathElement.createSVGPathSegCurvetoCubicAbs */
  SVGPathSegCurvetoCubicAbs createSVGPathSegCurvetoCubicAbs(num x, num y, num x1, num y1, num x2, num y2) native;

  /** @domName SVGPathElement.createSVGPathSegCurvetoCubicRel */
  SVGPathSegCurvetoCubicRel createSVGPathSegCurvetoCubicRel(num x, num y, num x1, num y1, num x2, num y2) native;

  /** @domName SVGPathElement.createSVGPathSegCurvetoCubicSmoothAbs */
  SVGPathSegCurvetoCubicSmoothAbs createSVGPathSegCurvetoCubicSmoothAbs(num x, num y, num x2, num y2) native;

  /** @domName SVGPathElement.createSVGPathSegCurvetoCubicSmoothRel */
  SVGPathSegCurvetoCubicSmoothRel createSVGPathSegCurvetoCubicSmoothRel(num x, num y, num x2, num y2) native;

  /** @domName SVGPathElement.createSVGPathSegCurvetoQuadraticAbs */
  SVGPathSegCurvetoQuadraticAbs createSVGPathSegCurvetoQuadraticAbs(num x, num y, num x1, num y1) native;

  /** @domName SVGPathElement.createSVGPathSegCurvetoQuadraticRel */
  SVGPathSegCurvetoQuadraticRel createSVGPathSegCurvetoQuadraticRel(num x, num y, num x1, num y1) native;

  /** @domName SVGPathElement.createSVGPathSegCurvetoQuadraticSmoothAbs */
  SVGPathSegCurvetoQuadraticSmoothAbs createSVGPathSegCurvetoQuadraticSmoothAbs(num x, num y) native;

  /** @domName SVGPathElement.createSVGPathSegCurvetoQuadraticSmoothRel */
  SVGPathSegCurvetoQuadraticSmoothRel createSVGPathSegCurvetoQuadraticSmoothRel(num x, num y) native;

  /** @domName SVGPathElement.createSVGPathSegLinetoAbs */
  SVGPathSegLinetoAbs createSVGPathSegLinetoAbs(num x, num y) native;

  /** @domName SVGPathElement.createSVGPathSegLinetoHorizontalAbs */
  SVGPathSegLinetoHorizontalAbs createSVGPathSegLinetoHorizontalAbs(num x) native;

  /** @domName SVGPathElement.createSVGPathSegLinetoHorizontalRel */
  SVGPathSegLinetoHorizontalRel createSVGPathSegLinetoHorizontalRel(num x) native;

  /** @domName SVGPathElement.createSVGPathSegLinetoRel */
  SVGPathSegLinetoRel createSVGPathSegLinetoRel(num x, num y) native;

  /** @domName SVGPathElement.createSVGPathSegLinetoVerticalAbs */
  SVGPathSegLinetoVerticalAbs createSVGPathSegLinetoVerticalAbs(num y) native;

  /** @domName SVGPathElement.createSVGPathSegLinetoVerticalRel */
  SVGPathSegLinetoVerticalRel createSVGPathSegLinetoVerticalRel(num y) native;

  /** @domName SVGPathElement.createSVGPathSegMovetoAbs */
  SVGPathSegMovetoAbs createSVGPathSegMovetoAbs(num x, num y) native;

  /** @domName SVGPathElement.createSVGPathSegMovetoRel */
  SVGPathSegMovetoRel createSVGPathSegMovetoRel(num x, num y) native;

  /** @domName SVGPathElement.getPathSegAtLength */
  int getPathSegAtLength(num distance) native;

  /** @domName SVGPathElement.getPointAtLength */
  SVGPoint getPointAtLength(num distance) native;

  /** @domName SVGPathElement.getTotalLength */
  num getTotalLength() native;

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final SVGAnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGLocatable

  /** @domName SVGLocatable.farthestViewportElement */
  final SVGElement farthestViewportElement;

  /** @domName SVGLocatable.nearestViewportElement */
  final SVGElement nearestViewportElement;

  /** @domName SVGLocatable.getBBox */
  SVGRect getBBox() native;

  /** @domName SVGLocatable.getCTM */
  SVGMatrix getCTM() native;

  /** @domName SVGLocatable.getScreenCTM */
  SVGMatrix getScreenCTM() native;

  /** @domName SVGLocatable.getTransformToElement */
  SVGMatrix getTransformToElement(SVGElement element) native;

  // From SVGStylable

  /** @domName SVGStylable.className */
  SVGAnimatedString get $dom_svgClassName => JS("SVGAnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /** @domName SVGTests.requiredExtensions */
  final SVGStringList requiredExtensions;

  /** @domName SVGTests.requiredFeatures */
  final SVGStringList requiredFeatures;

  /** @domName SVGTests.systemLanguage */
  final SVGStringList systemLanguage;

  /** @domName SVGTests.hasExtension */
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /** @domName SVGTransformable.transform */
  final SVGAnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSeg
class SVGPathSeg native "*SVGPathSeg" {

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
class SVGPathSegArcAbs extends SVGPathSeg native "*SVGPathSegArcAbs" {

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
class SVGPathSegArcRel extends SVGPathSeg native "*SVGPathSegArcRel" {

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
class SVGPathSegClosePath extends SVGPathSeg native "*SVGPathSegClosePath" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegCurvetoCubicAbs
class SVGPathSegCurvetoCubicAbs extends SVGPathSeg native "*SVGPathSegCurvetoCubicAbs" {

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
class SVGPathSegCurvetoCubicRel extends SVGPathSeg native "*SVGPathSegCurvetoCubicRel" {

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
class SVGPathSegCurvetoCubicSmoothAbs extends SVGPathSeg native "*SVGPathSegCurvetoCubicSmoothAbs" {

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
class SVGPathSegCurvetoCubicSmoothRel extends SVGPathSeg native "*SVGPathSegCurvetoCubicSmoothRel" {

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
class SVGPathSegCurvetoQuadraticAbs extends SVGPathSeg native "*SVGPathSegCurvetoQuadraticAbs" {

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
class SVGPathSegCurvetoQuadraticRel extends SVGPathSeg native "*SVGPathSegCurvetoQuadraticRel" {

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
class SVGPathSegCurvetoQuadraticSmoothAbs extends SVGPathSeg native "*SVGPathSegCurvetoQuadraticSmoothAbs" {

  /** @domName SVGPathSegCurvetoQuadraticSmoothAbs.x */
  num x;

  /** @domName SVGPathSegCurvetoQuadraticSmoothAbs.y */
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegCurvetoQuadraticSmoothRel
class SVGPathSegCurvetoQuadraticSmoothRel extends SVGPathSeg native "*SVGPathSegCurvetoQuadraticSmoothRel" {

  /** @domName SVGPathSegCurvetoQuadraticSmoothRel.x */
  num x;

  /** @domName SVGPathSegCurvetoQuadraticSmoothRel.y */
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegLinetoAbs
class SVGPathSegLinetoAbs extends SVGPathSeg native "*SVGPathSegLinetoAbs" {

  /** @domName SVGPathSegLinetoAbs.x */
  num x;

  /** @domName SVGPathSegLinetoAbs.y */
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegLinetoHorizontalAbs
class SVGPathSegLinetoHorizontalAbs extends SVGPathSeg native "*SVGPathSegLinetoHorizontalAbs" {

  /** @domName SVGPathSegLinetoHorizontalAbs.x */
  num x;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegLinetoHorizontalRel
class SVGPathSegLinetoHorizontalRel extends SVGPathSeg native "*SVGPathSegLinetoHorizontalRel" {

  /** @domName SVGPathSegLinetoHorizontalRel.x */
  num x;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegLinetoRel
class SVGPathSegLinetoRel extends SVGPathSeg native "*SVGPathSegLinetoRel" {

  /** @domName SVGPathSegLinetoRel.x */
  num x;

  /** @domName SVGPathSegLinetoRel.y */
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegLinetoVerticalAbs
class SVGPathSegLinetoVerticalAbs extends SVGPathSeg native "*SVGPathSegLinetoVerticalAbs" {

  /** @domName SVGPathSegLinetoVerticalAbs.y */
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegLinetoVerticalRel
class SVGPathSegLinetoVerticalRel extends SVGPathSeg native "*SVGPathSegLinetoVerticalRel" {

  /** @domName SVGPathSegLinetoVerticalRel.y */
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegList
class SVGPathSegList implements JavaScriptIndexingBehavior, List<SVGPathSeg> native "*SVGPathSegList" {

  /** @domName SVGPathSegList.numberOfItems */
  final int numberOfItems;

  SVGPathSeg operator[](int index) => JS("SVGPathSeg", "#[#]", this, index);

  void operator[]=(int index, SVGPathSeg value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<SVGPathSeg> mixins.
  // SVGPathSeg is the element type.

  // From Iterable<SVGPathSeg>:

  Iterator<SVGPathSeg> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<SVGPathSeg>(this);
  }

  // From Collection<SVGPathSeg>:

  void add(SVGPathSeg value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(SVGPathSeg value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<SVGPathSeg> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(SVGPathSeg element) => _Collections.contains(this, element);

  void forEach(void f(SVGPathSeg element)) => _Collections.forEach(this, f);

  Collection map(f(SVGPathSeg element)) => _Collections.map(this, [], f);

  Collection<SVGPathSeg> filter(bool f(SVGPathSeg element)) =>
     _Collections.filter(this, <SVGPathSeg>[], f);

  bool every(bool f(SVGPathSeg element)) => _Collections.every(this, f);

  bool some(bool f(SVGPathSeg element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<SVGPathSeg>:

  void sort([Comparator<SVGPathSeg> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(SVGPathSeg element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(SVGPathSeg element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  SVGPathSeg get last => this[length - 1];

  SVGPathSeg removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<SVGPathSeg> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [SVGPathSeg initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<SVGPathSeg> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <SVGPathSeg>[]);

  // -- end List<SVGPathSeg> mixins.

  /** @domName SVGPathSegList.appendItem */
  SVGPathSeg appendItem(SVGPathSeg newItem) native;

  /** @domName SVGPathSegList.clear */
  void clear() native;

  /** @domName SVGPathSegList.getItem */
  SVGPathSeg getItem(int index) native;

  /** @domName SVGPathSegList.initialize */
  SVGPathSeg initialize(SVGPathSeg newItem) native;

  /** @domName SVGPathSegList.insertItemBefore */
  SVGPathSeg insertItemBefore(SVGPathSeg newItem, int index) native;

  /** @domName SVGPathSegList.removeItem */
  SVGPathSeg removeItem(int index) native;

  /** @domName SVGPathSegList.replaceItem */
  SVGPathSeg replaceItem(SVGPathSeg newItem, int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegMovetoAbs
class SVGPathSegMovetoAbs extends SVGPathSeg native "*SVGPathSegMovetoAbs" {

  /** @domName SVGPathSegMovetoAbs.x */
  num x;

  /** @domName SVGPathSegMovetoAbs.y */
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPathSegMovetoRel
class SVGPathSegMovetoRel extends SVGPathSeg native "*SVGPathSegMovetoRel" {

  /** @domName SVGPathSegMovetoRel.x */
  num x;

  /** @domName SVGPathSegMovetoRel.y */
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPatternElement
class SVGPatternElement extends SVGElement implements SVGLangSpace, SVGTests, SVGStylable, SVGURIReference, SVGFitToViewBox, SVGExternalResourcesRequired native "*SVGPatternElement" {

  factory SVGPatternElement() => _SvgElementFactoryProvider.createSVGElement_tag("pattern");

  /** @domName SVGPatternElement.height */
  final SVGAnimatedLength height;

  /** @domName SVGPatternElement.patternContentUnits */
  final SVGAnimatedEnumeration patternContentUnits;

  /** @domName SVGPatternElement.patternTransform */
  final SVGAnimatedTransformList patternTransform;

  /** @domName SVGPatternElement.patternUnits */
  final SVGAnimatedEnumeration patternUnits;

  /** @domName SVGPatternElement.width */
  final SVGAnimatedLength width;

  /** @domName SVGPatternElement.x */
  final SVGAnimatedLength x;

  /** @domName SVGPatternElement.y */
  final SVGAnimatedLength y;

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final SVGAnimatedBoolean externalResourcesRequired;

  // From SVGFitToViewBox

  /** @domName SVGFitToViewBox.preserveAspectRatio */
  final SVGAnimatedPreserveAspectRatio preserveAspectRatio;

  /** @domName SVGFitToViewBox.viewBox */
  final SVGAnimatedRect viewBox;

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGStylable

  /** @domName SVGStylable.className */
  SVGAnimatedString get $dom_svgClassName => JS("SVGAnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /** @domName SVGTests.requiredExtensions */
  final SVGStringList requiredExtensions;

  /** @domName SVGTests.requiredFeatures */
  final SVGStringList requiredFeatures;

  /** @domName SVGTests.systemLanguage */
  final SVGStringList systemLanguage;

  /** @domName SVGTests.hasExtension */
  bool hasExtension(String extension) native;

  // From SVGURIReference

  /** @domName SVGURIReference.href */
  final SVGAnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPoint
class SVGPoint native "*SVGPoint" {

  /** @domName SVGPoint.x */
  num x;

  /** @domName SVGPoint.y */
  num y;

  /** @domName SVGPoint.matrixTransform */
  SVGPoint matrixTransform(SVGMatrix matrix) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPointList
class SVGPointList native "*SVGPointList" {

  /** @domName SVGPointList.numberOfItems */
  final int numberOfItems;

  /** @domName SVGPointList.appendItem */
  SVGPoint appendItem(SVGPoint item) native;

  /** @domName SVGPointList.clear */
  void clear() native;

  /** @domName SVGPointList.getItem */
  SVGPoint getItem(int index) native;

  /** @domName SVGPointList.initialize */
  SVGPoint initialize(SVGPoint item) native;

  /** @domName SVGPointList.insertItemBefore */
  SVGPoint insertItemBefore(SVGPoint item, int index) native;

  /** @domName SVGPointList.removeItem */
  SVGPoint removeItem(int index) native;

  /** @domName SVGPointList.replaceItem */
  SVGPoint replaceItem(SVGPoint item, int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPolygonElement
class SVGPolygonElement extends SVGElement implements SVGLangSpace, SVGStylable, SVGTests, SVGTransformable, SVGExternalResourcesRequired native "*SVGPolygonElement" {

  factory SVGPolygonElement() => _SvgElementFactoryProvider.createSVGElement_tag("polygon");

  /** @domName SVGPolygonElement.animatedPoints */
  final SVGPointList animatedPoints;

  /** @domName SVGPolygonElement.points */
  final SVGPointList points;

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final SVGAnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGLocatable

  /** @domName SVGLocatable.farthestViewportElement */
  final SVGElement farthestViewportElement;

  /** @domName SVGLocatable.nearestViewportElement */
  final SVGElement nearestViewportElement;

  /** @domName SVGLocatable.getBBox */
  SVGRect getBBox() native;

  /** @domName SVGLocatable.getCTM */
  SVGMatrix getCTM() native;

  /** @domName SVGLocatable.getScreenCTM */
  SVGMatrix getScreenCTM() native;

  /** @domName SVGLocatable.getTransformToElement */
  SVGMatrix getTransformToElement(SVGElement element) native;

  // From SVGStylable

  /** @domName SVGStylable.className */
  SVGAnimatedString get $dom_svgClassName => JS("SVGAnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /** @domName SVGTests.requiredExtensions */
  final SVGStringList requiredExtensions;

  /** @domName SVGTests.requiredFeatures */
  final SVGStringList requiredFeatures;

  /** @domName SVGTests.systemLanguage */
  final SVGStringList systemLanguage;

  /** @domName SVGTests.hasExtension */
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /** @domName SVGTransformable.transform */
  final SVGAnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPolylineElement
class SVGPolylineElement extends SVGElement implements SVGLangSpace, SVGStylable, SVGTests, SVGTransformable, SVGExternalResourcesRequired native "*SVGPolylineElement" {

  factory SVGPolylineElement() => _SvgElementFactoryProvider.createSVGElement_tag("polyline");

  /** @domName SVGPolylineElement.animatedPoints */
  final SVGPointList animatedPoints;

  /** @domName SVGPolylineElement.points */
  final SVGPointList points;

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final SVGAnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGLocatable

  /** @domName SVGLocatable.farthestViewportElement */
  final SVGElement farthestViewportElement;

  /** @domName SVGLocatable.nearestViewportElement */
  final SVGElement nearestViewportElement;

  /** @domName SVGLocatable.getBBox */
  SVGRect getBBox() native;

  /** @domName SVGLocatable.getCTM */
  SVGMatrix getCTM() native;

  /** @domName SVGLocatable.getScreenCTM */
  SVGMatrix getScreenCTM() native;

  /** @domName SVGLocatable.getTransformToElement */
  SVGMatrix getTransformToElement(SVGElement element) native;

  // From SVGStylable

  /** @domName SVGStylable.className */
  SVGAnimatedString get $dom_svgClassName => JS("SVGAnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /** @domName SVGTests.requiredExtensions */
  final SVGStringList requiredExtensions;

  /** @domName SVGTests.requiredFeatures */
  final SVGStringList requiredFeatures;

  /** @domName SVGTests.systemLanguage */
  final SVGStringList systemLanguage;

  /** @domName SVGTests.hasExtension */
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /** @domName SVGTransformable.transform */
  final SVGAnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGPreserveAspectRatio
class SVGPreserveAspectRatio native "*SVGPreserveAspectRatio" {

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
class SVGRadialGradientElement extends SVGGradientElement native "*SVGRadialGradientElement" {

  factory SVGRadialGradientElement() => _SvgElementFactoryProvider.createSVGElement_tag("radialGradient");

  /** @domName SVGRadialGradientElement.cx */
  final SVGAnimatedLength cx;

  /** @domName SVGRadialGradientElement.cy */
  final SVGAnimatedLength cy;

  /** @domName SVGRadialGradientElement.fr */
  final SVGAnimatedLength fr;

  /** @domName SVGRadialGradientElement.fx */
  final SVGAnimatedLength fx;

  /** @domName SVGRadialGradientElement.fy */
  final SVGAnimatedLength fy;

  /** @domName SVGRadialGradientElement.r */
  final SVGAnimatedLength r;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGRect
class SVGRect native "*SVGRect" {

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
class SVGRectElement extends SVGElement implements SVGLangSpace, SVGStylable, SVGTests, SVGTransformable, SVGExternalResourcesRequired native "*SVGRectElement" {

  factory SVGRectElement() => _SvgElementFactoryProvider.createSVGElement_tag("rect");

  /** @domName SVGRectElement.height */
  final SVGAnimatedLength height;

  /** @domName SVGRectElement.rx */
  final SVGAnimatedLength rx;

  /** @domName SVGRectElement.ry */
  final SVGAnimatedLength ry;

  /** @domName SVGRectElement.width */
  final SVGAnimatedLength width;

  /** @domName SVGRectElement.x */
  final SVGAnimatedLength x;

  /** @domName SVGRectElement.y */
  final SVGAnimatedLength y;

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final SVGAnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGLocatable

  /** @domName SVGLocatable.farthestViewportElement */
  final SVGElement farthestViewportElement;

  /** @domName SVGLocatable.nearestViewportElement */
  final SVGElement nearestViewportElement;

  /** @domName SVGLocatable.getBBox */
  SVGRect getBBox() native;

  /** @domName SVGLocatable.getCTM */
  SVGMatrix getCTM() native;

  /** @domName SVGLocatable.getScreenCTM */
  SVGMatrix getScreenCTM() native;

  /** @domName SVGLocatable.getTransformToElement */
  SVGMatrix getTransformToElement(SVGElement element) native;

  // From SVGStylable

  /** @domName SVGStylable.className */
  SVGAnimatedString get $dom_svgClassName => JS("SVGAnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /** @domName SVGTests.requiredExtensions */
  final SVGStringList requiredExtensions;

  /** @domName SVGTests.requiredFeatures */
  final SVGStringList requiredFeatures;

  /** @domName SVGTests.systemLanguage */
  final SVGStringList systemLanguage;

  /** @domName SVGTests.hasExtension */
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /** @domName SVGTransformable.transform */
  final SVGAnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGRenderingIntent
class SVGRenderingIntent native "*SVGRenderingIntent" {

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


class SVGSVGElement extends SVGElement implements SVGZoomAndPan, SVGLocatable, SVGLangSpace, SVGTests, SVGStylable, SVGFitToViewBox, SVGExternalResourcesRequired native "*SVGSVGElement" {
  factory SVGSVGElement() => _SVGSVGElementFactoryProvider.createSVGSVGElement();


  /** @domName SVGSVGElement.contentScriptType */
  String contentScriptType;

  /** @domName SVGSVGElement.contentStyleType */
  String contentStyleType;

  /** @domName SVGSVGElement.currentScale */
  num currentScale;

  /** @domName SVGSVGElement.currentTranslate */
  final SVGPoint currentTranslate;

  /** @domName SVGSVGElement.currentView */
  final SVGViewSpec currentView;

  /** @domName SVGSVGElement.height */
  final SVGAnimatedLength height;

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
  final SVGRect viewport;

  /** @domName SVGSVGElement.width */
  final SVGAnimatedLength width;

  /** @domName SVGSVGElement.x */
  final SVGAnimatedLength x;

  /** @domName SVGSVGElement.y */
  final SVGAnimatedLength y;

  /** @domName SVGSVGElement.animationsPaused */
  bool animationsPaused() native;

  /** @domName SVGSVGElement.checkEnclosure */
  bool checkEnclosure(SVGElement element, SVGRect rect) native;

  /** @domName SVGSVGElement.checkIntersection */
  bool checkIntersection(SVGElement element, SVGRect rect) native;

  /** @domName SVGSVGElement.createSVGAngle */
  SVGAngle createSVGAngle() native;

  /** @domName SVGSVGElement.createSVGLength */
  SVGLength createSVGLength() native;

  /** @domName SVGSVGElement.createSVGMatrix */
  SVGMatrix createSVGMatrix() native;

  /** @domName SVGSVGElement.createSVGNumber */
  SVGNumber createSVGNumber() native;

  /** @domName SVGSVGElement.createSVGPoint */
  SVGPoint createSVGPoint() native;

  /** @domName SVGSVGElement.createSVGRect */
  SVGRect createSVGRect() native;

  /** @domName SVGSVGElement.createSVGTransform */
  SVGTransform createSVGTransform() native;

  /** @domName SVGSVGElement.createSVGTransformFromMatrix */
  SVGTransform createSVGTransformFromMatrix(SVGMatrix matrix) native;

  /** @domName SVGSVGElement.deselectAll */
  void deselectAll() native;

  /** @domName SVGSVGElement.forceRedraw */
  void forceRedraw() native;

  /** @domName SVGSVGElement.getCurrentTime */
  num getCurrentTime() native;

  /** @domName SVGSVGElement.getElementById */
  Element getElementById(String elementId) native;

  /** @domName SVGSVGElement.getEnclosureList */
  List<Node> getEnclosureList(SVGRect rect, SVGElement referenceElement) native;

  /** @domName SVGSVGElement.getIntersectionList */
  List<Node> getIntersectionList(SVGRect rect, SVGElement referenceElement) native;

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
  final SVGAnimatedBoolean externalResourcesRequired;

  // From SVGFitToViewBox

  /** @domName SVGFitToViewBox.preserveAspectRatio */
  final SVGAnimatedPreserveAspectRatio preserveAspectRatio;

  /** @domName SVGFitToViewBox.viewBox */
  final SVGAnimatedRect viewBox;

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGLocatable

  /** @domName SVGLocatable.farthestViewportElement */
  final SVGElement farthestViewportElement;

  /** @domName SVGLocatable.nearestViewportElement */
  final SVGElement nearestViewportElement;

  /** @domName SVGLocatable.getBBox */
  SVGRect getBBox() native;

  /** @domName SVGLocatable.getCTM */
  SVGMatrix getCTM() native;

  /** @domName SVGLocatable.getScreenCTM */
  SVGMatrix getScreenCTM() native;

  /** @domName SVGLocatable.getTransformToElement */
  SVGMatrix getTransformToElement(SVGElement element) native;

  // From SVGStylable

  /** @domName SVGStylable.className */
  SVGAnimatedString get $dom_svgClassName => JS("SVGAnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /** @domName SVGTests.requiredExtensions */
  final SVGStringList requiredExtensions;

  /** @domName SVGTests.requiredFeatures */
  final SVGStringList requiredFeatures;

  /** @domName SVGTests.systemLanguage */
  final SVGStringList systemLanguage;

  /** @domName SVGTests.hasExtension */
  bool hasExtension(String extension) native;

  // From SVGZoomAndPan

  /** @domName SVGZoomAndPan.zoomAndPan */
  int zoomAndPan;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGScriptElement
class SVGScriptElement extends SVGElement implements SVGURIReference, SVGExternalResourcesRequired native "*SVGScriptElement" {

  factory SVGScriptElement() => _SvgElementFactoryProvider.createSVGElement_tag("script");

  /** @domName SVGScriptElement.type */
  String type;

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final SVGAnimatedBoolean externalResourcesRequired;

  // From SVGURIReference

  /** @domName SVGURIReference.href */
  final SVGAnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGSetElement
class SVGSetElement extends SVGAnimationElement native "*SVGSetElement" {

  factory SVGSetElement() => _SvgElementFactoryProvider.createSVGElement_tag("set");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGStopElement
class SVGStopElement extends SVGElement implements SVGStylable native "*SVGStopElement" {

  factory SVGStopElement() => _SvgElementFactoryProvider.createSVGElement_tag("stop");

  /** @domName SVGStopElement.offset */
  final SVGAnimatedNumber offset;

  // From SVGStylable

  /** @domName SVGStylable.className */
  SVGAnimatedString get $dom_svgClassName => JS("SVGAnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGStringList
class SVGStringList implements JavaScriptIndexingBehavior, List<String> native "*SVGStringList" {

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
abstract class SVGStylable {

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGStyleElement
class SVGStyleElement extends SVGElement implements SVGLangSpace native "*SVGStyleElement" {

  factory SVGStyleElement() => _SvgElementFactoryProvider.createSVGElement_tag("style");

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


/// @domName SVGSwitchElement
class SVGSwitchElement extends SVGElement implements SVGLangSpace, SVGStylable, SVGTests, SVGTransformable, SVGExternalResourcesRequired native "*SVGSwitchElement" {

  factory SVGSwitchElement() => _SvgElementFactoryProvider.createSVGElement_tag("switch");

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final SVGAnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGLocatable

  /** @domName SVGLocatable.farthestViewportElement */
  final SVGElement farthestViewportElement;

  /** @domName SVGLocatable.nearestViewportElement */
  final SVGElement nearestViewportElement;

  /** @domName SVGLocatable.getBBox */
  SVGRect getBBox() native;

  /** @domName SVGLocatable.getCTM */
  SVGMatrix getCTM() native;

  /** @domName SVGLocatable.getScreenCTM */
  SVGMatrix getScreenCTM() native;

  /** @domName SVGLocatable.getTransformToElement */
  SVGMatrix getTransformToElement(SVGElement element) native;

  // From SVGStylable

  /** @domName SVGStylable.className */
  SVGAnimatedString get $dom_svgClassName => JS("SVGAnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /** @domName SVGTests.requiredExtensions */
  final SVGStringList requiredExtensions;

  /** @domName SVGTests.requiredFeatures */
  final SVGStringList requiredFeatures;

  /** @domName SVGTests.systemLanguage */
  final SVGStringList systemLanguage;

  /** @domName SVGTests.hasExtension */
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /** @domName SVGTransformable.transform */
  final SVGAnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGSymbolElement
class SVGSymbolElement extends SVGElement implements SVGLangSpace, SVGFitToViewBox, SVGExternalResourcesRequired, SVGStylable native "*SVGSymbolElement" {

  factory SVGSymbolElement() => _SvgElementFactoryProvider.createSVGElement_tag("symbol");

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final SVGAnimatedBoolean externalResourcesRequired;

  // From SVGFitToViewBox

  /** @domName SVGFitToViewBox.preserveAspectRatio */
  final SVGAnimatedPreserveAspectRatio preserveAspectRatio;

  /** @domName SVGFitToViewBox.viewBox */
  final SVGAnimatedRect viewBox;

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGStylable

  /** @domName SVGStylable.className */
  SVGAnimatedString get $dom_svgClassName => JS("SVGAnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGTRefElement
class SVGTRefElement extends SVGTextPositioningElement implements SVGURIReference native "*SVGTRefElement" {

  factory SVGTRefElement() => _SvgElementFactoryProvider.createSVGElement_tag("tref");

  // From SVGURIReference

  /** @domName SVGURIReference.href */
  final SVGAnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGTSpanElement
class SVGTSpanElement extends SVGTextPositioningElement native "*SVGTSpanElement" {

  factory SVGTSpanElement() => _SvgElementFactoryProvider.createSVGElement_tag("tspan");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGTests
abstract class SVGTests {

  SVGStringList requiredExtensions;

  SVGStringList requiredFeatures;

  SVGStringList systemLanguage;

  /** @domName SVGTests.hasExtension */
  bool hasExtension(String extension);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGTextContentElement
class SVGTextContentElement extends SVGElement implements SVGLangSpace, SVGStylable, SVGTests, SVGExternalResourcesRequired native "*SVGTextContentElement" {

  static const int LENGTHADJUST_SPACING = 1;

  static const int LENGTHADJUST_SPACINGANDGLYPHS = 2;

  static const int LENGTHADJUST_UNKNOWN = 0;

  /** @domName SVGTextContentElement.lengthAdjust */
  final SVGAnimatedEnumeration lengthAdjust;

  /** @domName SVGTextContentElement.textLength */
  final SVGAnimatedLength textLength;

  /** @domName SVGTextContentElement.getCharNumAtPosition */
  int getCharNumAtPosition(SVGPoint point) native;

  /** @domName SVGTextContentElement.getComputedTextLength */
  num getComputedTextLength() native;

  /** @domName SVGTextContentElement.getEndPositionOfChar */
  SVGPoint getEndPositionOfChar(int offset) native;

  /** @domName SVGTextContentElement.getExtentOfChar */
  SVGRect getExtentOfChar(int offset) native;

  /** @domName SVGTextContentElement.getNumberOfChars */
  int getNumberOfChars() native;

  /** @domName SVGTextContentElement.getRotationOfChar */
  num getRotationOfChar(int offset) native;

  /** @domName SVGTextContentElement.getStartPositionOfChar */
  SVGPoint getStartPositionOfChar(int offset) native;

  /** @domName SVGTextContentElement.getSubStringLength */
  num getSubStringLength(int offset, int length) native;

  /** @domName SVGTextContentElement.selectSubString */
  void selectSubString(int offset, int length) native;

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final SVGAnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGStylable

  /** @domName SVGStylable.className */
  SVGAnimatedString get $dom_svgClassName => JS("SVGAnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /** @domName SVGTests.requiredExtensions */
  final SVGStringList requiredExtensions;

  /** @domName SVGTests.requiredFeatures */
  final SVGStringList requiredFeatures;

  /** @domName SVGTests.systemLanguage */
  final SVGStringList systemLanguage;

  /** @domName SVGTests.hasExtension */
  bool hasExtension(String extension) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGTextElement
class SVGTextElement extends SVGTextPositioningElement implements SVGTransformable native "*SVGTextElement" {

  factory SVGTextElement() => _SvgElementFactoryProvider.createSVGElement_tag("text");

  // From SVGLocatable

  /** @domName SVGLocatable.farthestViewportElement */
  final SVGElement farthestViewportElement;

  /** @domName SVGLocatable.nearestViewportElement */
  final SVGElement nearestViewportElement;

  /** @domName SVGLocatable.getBBox */
  SVGRect getBBox() native;

  /** @domName SVGLocatable.getCTM */
  SVGMatrix getCTM() native;

  /** @domName SVGLocatable.getScreenCTM */
  SVGMatrix getScreenCTM() native;

  /** @domName SVGLocatable.getTransformToElement */
  SVGMatrix getTransformToElement(SVGElement element) native;

  // From SVGTransformable

  /** @domName SVGTransformable.transform */
  final SVGAnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGTextPathElement
class SVGTextPathElement extends SVGTextContentElement implements SVGURIReference native "*SVGTextPathElement" {

  static const int TEXTPATH_METHODTYPE_ALIGN = 1;

  static const int TEXTPATH_METHODTYPE_STRETCH = 2;

  static const int TEXTPATH_METHODTYPE_UNKNOWN = 0;

  static const int TEXTPATH_SPACINGTYPE_AUTO = 1;

  static const int TEXTPATH_SPACINGTYPE_EXACT = 2;

  static const int TEXTPATH_SPACINGTYPE_UNKNOWN = 0;

  /** @domName SVGTextPathElement.method */
  final SVGAnimatedEnumeration method;

  /** @domName SVGTextPathElement.spacing */
  final SVGAnimatedEnumeration spacing;

  /** @domName SVGTextPathElement.startOffset */
  final SVGAnimatedLength startOffset;

  // From SVGURIReference

  /** @domName SVGURIReference.href */
  final SVGAnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGTextPositioningElement
class SVGTextPositioningElement extends SVGTextContentElement native "*SVGTextPositioningElement" {

  /** @domName SVGTextPositioningElement.dx */
  final SVGAnimatedLengthList dx;

  /** @domName SVGTextPositioningElement.dy */
  final SVGAnimatedLengthList dy;

  /** @domName SVGTextPositioningElement.rotate */
  final SVGAnimatedNumberList rotate;

  /** @domName SVGTextPositioningElement.x */
  final SVGAnimatedLengthList x;

  /** @domName SVGTextPositioningElement.y */
  final SVGAnimatedLengthList y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGTitleElement
class SVGTitleElement extends SVGElement implements SVGLangSpace, SVGStylable native "*SVGTitleElement" {

  factory SVGTitleElement() => _SvgElementFactoryProvider.createSVGElement_tag("title");

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGStylable

  /** @domName SVGStylable.className */
  SVGAnimatedString get $dom_svgClassName => JS("SVGAnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGTransform
class SVGTransform native "*SVGTransform" {

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
  final SVGMatrix matrix;

  /** @domName SVGTransform.type */
  final int type;

  /** @domName SVGTransform.setMatrix */
  void setMatrix(SVGMatrix matrix) native;

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
class SVGTransformList implements JavaScriptIndexingBehavior, List<SVGTransform> native "*SVGTransformList" {

  /** @domName SVGTransformList.numberOfItems */
  final int numberOfItems;

  SVGTransform operator[](int index) => JS("SVGTransform", "#[#]", this, index);

  void operator[]=(int index, SVGTransform value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<SVGTransform> mixins.
  // SVGTransform is the element type.

  // From Iterable<SVGTransform>:

  Iterator<SVGTransform> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<SVGTransform>(this);
  }

  // From Collection<SVGTransform>:

  void add(SVGTransform value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(SVGTransform value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<SVGTransform> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(SVGTransform element) => _Collections.contains(this, element);

  void forEach(void f(SVGTransform element)) => _Collections.forEach(this, f);

  Collection map(f(SVGTransform element)) => _Collections.map(this, [], f);

  Collection<SVGTransform> filter(bool f(SVGTransform element)) =>
     _Collections.filter(this, <SVGTransform>[], f);

  bool every(bool f(SVGTransform element)) => _Collections.every(this, f);

  bool some(bool f(SVGTransform element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<SVGTransform>:

  void sort([Comparator<SVGTransform> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(SVGTransform element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(SVGTransform element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  SVGTransform get last => this[length - 1];

  SVGTransform removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<SVGTransform> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [SVGTransform initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<SVGTransform> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <SVGTransform>[]);

  // -- end List<SVGTransform> mixins.

  /** @domName SVGTransformList.appendItem */
  SVGTransform appendItem(SVGTransform item) native;

  /** @domName SVGTransformList.clear */
  void clear() native;

  /** @domName SVGTransformList.consolidate */
  SVGTransform consolidate() native;

  /** @domName SVGTransformList.createSVGTransformFromMatrix */
  SVGTransform createSVGTransformFromMatrix(SVGMatrix matrix) native;

  /** @domName SVGTransformList.getItem */
  SVGTransform getItem(int index) native;

  /** @domName SVGTransformList.initialize */
  SVGTransform initialize(SVGTransform item) native;

  /** @domName SVGTransformList.insertItemBefore */
  SVGTransform insertItemBefore(SVGTransform item, int index) native;

  /** @domName SVGTransformList.removeItem */
  SVGTransform removeItem(int index) native;

  /** @domName SVGTransformList.replaceItem */
  SVGTransform replaceItem(SVGTransform item, int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGTransformable
abstract class SVGTransformable implements SVGLocatable {

  SVGAnimatedTransformList transform;

  // From SVGLocatable

  SVGElement farthestViewportElement;

  SVGElement nearestViewportElement;

  /** @domName SVGLocatable.getBBox */
  SVGRect getBBox();

  /** @domName SVGLocatable.getCTM */
  SVGMatrix getCTM();

  /** @domName SVGLocatable.getScreenCTM */
  SVGMatrix getScreenCTM();

  /** @domName SVGLocatable.getTransformToElement */
  SVGMatrix getTransformToElement(SVGElement element);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGURIReference
abstract class SVGURIReference {

  SVGAnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGUnitTypes
class SVGUnitTypes native "*SVGUnitTypes" {

  static const int SVG_UNIT_TYPE_OBJECTBOUNDINGBOX = 2;

  static const int SVG_UNIT_TYPE_UNKNOWN = 0;

  static const int SVG_UNIT_TYPE_USERSPACEONUSE = 1;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGUseElement
class SVGUseElement extends SVGElement implements SVGLangSpace, SVGTests, SVGStylable, SVGURIReference, SVGExternalResourcesRequired, SVGTransformable native "*SVGUseElement" {

  factory SVGUseElement() => _SvgElementFactoryProvider.createSVGElement_tag("use");

  /** @domName SVGUseElement.animatedInstanceRoot */
  final SVGElementInstance animatedInstanceRoot;

  /** @domName SVGUseElement.height */
  final SVGAnimatedLength height;

  /** @domName SVGUseElement.instanceRoot */
  final SVGElementInstance instanceRoot;

  /** @domName SVGUseElement.width */
  final SVGAnimatedLength width;

  /** @domName SVGUseElement.x */
  final SVGAnimatedLength x;

  /** @domName SVGUseElement.y */
  final SVGAnimatedLength y;

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final SVGAnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /** @domName SVGLangSpace.xmllang */
  String xmllang;

  /** @domName SVGLangSpace.xmlspace */
  String xmlspace;

  // From SVGLocatable

  /** @domName SVGLocatable.farthestViewportElement */
  final SVGElement farthestViewportElement;

  /** @domName SVGLocatable.nearestViewportElement */
  final SVGElement nearestViewportElement;

  /** @domName SVGLocatable.getBBox */
  SVGRect getBBox() native;

  /** @domName SVGLocatable.getCTM */
  SVGMatrix getCTM() native;

  /** @domName SVGLocatable.getScreenCTM */
  SVGMatrix getScreenCTM() native;

  /** @domName SVGLocatable.getTransformToElement */
  SVGMatrix getTransformToElement(SVGElement element) native;

  // From SVGStylable

  /** @domName SVGStylable.className */
  SVGAnimatedString get $dom_svgClassName => JS("SVGAnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CSSStyleDeclaration style;

  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native;

  // From SVGTests

  /** @domName SVGTests.requiredExtensions */
  final SVGStringList requiredExtensions;

  /** @domName SVGTests.requiredFeatures */
  final SVGStringList requiredFeatures;

  /** @domName SVGTests.systemLanguage */
  final SVGStringList systemLanguage;

  /** @domName SVGTests.hasExtension */
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /** @domName SVGTransformable.transform */
  final SVGAnimatedTransformList transform;

  // From SVGURIReference

  /** @domName SVGURIReference.href */
  final SVGAnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGVKernElement
class SVGVKernElement extends SVGElement native "*SVGVKernElement" {

  factory SVGVKernElement() => _SvgElementFactoryProvider.createSVGElement_tag("vkern");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGViewElement
class SVGViewElement extends SVGElement implements SVGFitToViewBox, SVGZoomAndPan, SVGExternalResourcesRequired native "*SVGViewElement" {

  factory SVGViewElement() => _SvgElementFactoryProvider.createSVGElement_tag("view");

  /** @domName SVGViewElement.viewTarget */
  final SVGStringList viewTarget;

  // From SVGExternalResourcesRequired

  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  final SVGAnimatedBoolean externalResourcesRequired;

  // From SVGFitToViewBox

  /** @domName SVGFitToViewBox.preserveAspectRatio */
  final SVGAnimatedPreserveAspectRatio preserveAspectRatio;

  /** @domName SVGFitToViewBox.viewBox */
  final SVGAnimatedRect viewBox;

  // From SVGZoomAndPan

  /** @domName SVGZoomAndPan.zoomAndPan */
  int zoomAndPan;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGViewSpec
class SVGViewSpec native "*SVGViewSpec" {

  /** @domName SVGViewSpec.preserveAspectRatio */
  final SVGAnimatedPreserveAspectRatio preserveAspectRatio;

  /** @domName SVGViewSpec.preserveAspectRatioString */
  final String preserveAspectRatioString;

  /** @domName SVGViewSpec.transform */
  final SVGTransformList transform;

  /** @domName SVGViewSpec.transformString */
  final String transformString;

  /** @domName SVGViewSpec.viewBox */
  final SVGAnimatedRect viewBox;

  /** @domName SVGViewSpec.viewBoxString */
  final String viewBoxString;

  /** @domName SVGViewSpec.viewTarget */
  final SVGElement viewTarget;

  /** @domName SVGViewSpec.viewTargetString */
  final String viewTargetString;

  /** @domName SVGViewSpec.zoomAndPan */
  int zoomAndPan;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGZoomAndPan
abstract class SVGZoomAndPan {

  static const int SVG_ZOOMANDPAN_DISABLE = 1;

  static const int SVG_ZOOMANDPAN_MAGNIFY = 2;

  static const int SVG_ZOOMANDPAN_UNKNOWN = 0;

  int zoomAndPan;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGZoomEvent
class SVGZoomEvent extends UIEvent native "*SVGZoomEvent" {

  /** @domName SVGZoomEvent.newScale */
  final num newScale;

  /** @domName SVGZoomEvent.newTranslate */
  final SVGPoint newTranslate;

  /** @domName SVGZoomEvent.previousScale */
  final num previousScale;

  /** @domName SVGZoomEvent.previousTranslate */
  final SVGPoint previousTranslate;

  /** @domName SVGZoomEvent.zoomRectScreen */
  final SVGRect zoomRectScreen;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGElementInstanceList
class _SVGElementInstanceList implements JavaScriptIndexingBehavior, List<SVGElementInstance> native "*SVGElementInstanceList" {

  /** @domName SVGElementInstanceList.length */
  final int length;

  SVGElementInstance operator[](int index) => JS("SVGElementInstance", "#[#]", this, index);

  void operator[]=(int index, SVGElementInstance value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<SVGElementInstance> mixins.
  // SVGElementInstance is the element type.

  // From Iterable<SVGElementInstance>:

  Iterator<SVGElementInstance> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<SVGElementInstance>(this);
  }

  // From Collection<SVGElementInstance>:

  void add(SVGElementInstance value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(SVGElementInstance value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<SVGElementInstance> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(SVGElementInstance element) => _Collections.contains(this, element);

  void forEach(void f(SVGElementInstance element)) => _Collections.forEach(this, f);

  Collection map(f(SVGElementInstance element)) => _Collections.map(this, [], f);

  Collection<SVGElementInstance> filter(bool f(SVGElementInstance element)) =>
     _Collections.filter(this, <SVGElementInstance>[], f);

  bool every(bool f(SVGElementInstance element)) => _Collections.every(this, f);

  bool some(bool f(SVGElementInstance element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<SVGElementInstance>:

  void sort([Comparator<SVGElementInstance> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(SVGElementInstance element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(SVGElementInstance element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  SVGElementInstance get last => this[length - 1];

  SVGElementInstance removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<SVGElementInstance> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [SVGElementInstance initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<SVGElementInstance> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <SVGElementInstance>[]);

  // -- end List<SVGElementInstance> mixins.

  /** @domName SVGElementInstanceList.item */
  SVGElementInstance item(int index) native;
}
