library svg;

import 'dart:html';
import 'dart:nativewrappers';
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

// WARNING: Do not edit - generated code.


/// @domName SVGAElement
class AElement extends SvgElement implements Transformable, Tests, UriReference, Stylable, ExternalResourcesRequired, LangSpace {

  factory AElement() => _SvgElementFactoryProvider.createSvgElement_tag("a");
  AElement.internal(): super.internal();


  /** @domName SVGAElement.target */
  AnimatedString get target native "SVGAElement_target_Getter";


  /** @domName SVGAElement.externalResourcesRequired */
  AnimatedBoolean get externalResourcesRequired native "SVGAElement_externalResourcesRequired_Getter";


  /** @domName SVGAElement.xmllang */
  String get xmllang native "SVGAElement_xmllang_Getter";


  /** @domName SVGAElement.xmllang */
  void set xmllang(String value) native "SVGAElement_xmllang_Setter";


  /** @domName SVGAElement.xmlspace */
  String get xmlspace native "SVGAElement_xmlspace_Getter";


  /** @domName SVGAElement.xmlspace */
  void set xmlspace(String value) native "SVGAElement_xmlspace_Setter";


  /** @domName SVGAElement.farthestViewportElement */
  SvgElement get farthestViewportElement native "SVGAElement_farthestViewportElement_Getter";


  /** @domName SVGAElement.nearestViewportElement */
  SvgElement get nearestViewportElement native "SVGAElement_nearestViewportElement_Getter";


  /** @domName SVGAElement.getBBox */
  Rect getBBox() native "SVGAElement_getBBox_Callback";


  /** @domName SVGAElement.getCTM */
  Matrix getCtm() native "SVGAElement_getCTM_Callback";


  /** @domName SVGAElement.getScreenCTM */
  Matrix getScreenCtm() native "SVGAElement_getScreenCTM_Callback";


  /** @domName SVGAElement.getTransformToElement */
  Matrix getTransformToElement(SvgElement element) native "SVGAElement_getTransformToElement_Callback";


  /** @domName SVGAElement.className */
  AnimatedString get $dom_svgClassName native "SVGAElement_className_Getter";


  /** @domName SVGAElement.style */
  CSSStyleDeclaration get style native "SVGAElement_style_Getter";


  /** @domName SVGAElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGAElement_getPresentationAttribute_Callback";


  /** @domName SVGAElement.requiredExtensions */
  StringList get requiredExtensions native "SVGAElement_requiredExtensions_Getter";


  /** @domName SVGAElement.requiredFeatures */
  StringList get requiredFeatures native "SVGAElement_requiredFeatures_Getter";


  /** @domName SVGAElement.systemLanguage */
  StringList get systemLanguage native "SVGAElement_systemLanguage_Getter";


  /** @domName SVGAElement.hasExtension */
  bool hasExtension(String extension) native "SVGAElement_hasExtension_Callback";


  /** @domName SVGAElement.transform */
  AnimatedTransformList get transform native "SVGAElement_transform_Getter";


  /** @domName SVGAElement.href */
  AnimatedString get href native "SVGAElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGAltGlyphDefElement
class AltGlyphDefElement extends SvgElement {
  AltGlyphDefElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGAltGlyphElement
class AltGlyphElement extends TextPositioningElement implements UriReference {
  AltGlyphElement.internal(): super.internal();


  /** @domName SVGAltGlyphElement.format */
  String get format native "SVGAltGlyphElement_format_Getter";


  /** @domName SVGAltGlyphElement.format */
  void set format(String value) native "SVGAltGlyphElement_format_Setter";


  /** @domName SVGAltGlyphElement.glyphRef */
  String get glyphRef native "SVGAltGlyphElement_glyphRef_Getter";


  /** @domName SVGAltGlyphElement.glyphRef */
  void set glyphRef(String value) native "SVGAltGlyphElement_glyphRef_Setter";


  /** @domName SVGAltGlyphElement.href */
  AnimatedString get href native "SVGAltGlyphElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGAltGlyphItemElement
class AltGlyphItemElement extends SvgElement {
  AltGlyphItemElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGAngle
class Angle extends NativeFieldWrapperClass1 {
  Angle.internal();

  static const int SVG_ANGLETYPE_DEG = 2;

  static const int SVG_ANGLETYPE_GRAD = 4;

  static const int SVG_ANGLETYPE_RAD = 3;

  static const int SVG_ANGLETYPE_UNKNOWN = 0;

  static const int SVG_ANGLETYPE_UNSPECIFIED = 1;


  /** @domName SVGAngle.unitType */
  int get unitType native "SVGAngle_unitType_Getter";


  /** @domName SVGAngle.value */
  num get value native "SVGAngle_value_Getter";


  /** @domName SVGAngle.value */
  void set value(num value) native "SVGAngle_value_Setter";


  /** @domName SVGAngle.valueAsString */
  String get valueAsString native "SVGAngle_valueAsString_Getter";


  /** @domName SVGAngle.valueAsString */
  void set valueAsString(String value) native "SVGAngle_valueAsString_Setter";


  /** @domName SVGAngle.valueInSpecifiedUnits */
  num get valueInSpecifiedUnits native "SVGAngle_valueInSpecifiedUnits_Getter";


  /** @domName SVGAngle.valueInSpecifiedUnits */
  void set valueInSpecifiedUnits(num value) native "SVGAngle_valueInSpecifiedUnits_Setter";


  /** @domName SVGAngle.convertToSpecifiedUnits */
  void convertToSpecifiedUnits(int unitType) native "SVGAngle_convertToSpecifiedUnits_Callback";


  /** @domName SVGAngle.newValueSpecifiedUnits */
  void newValueSpecifiedUnits(int unitType, num valueInSpecifiedUnits) native "SVGAngle_newValueSpecifiedUnits_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGAnimateColorElement
class AnimateColorElement extends AnimationElement {

  factory AnimateColorElement() => _SvgElementFactoryProvider.createSvgElement_tag("animateColor");
  AnimateColorElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGAnimateElement
class AnimateElement extends AnimationElement {

  factory AnimateElement() => _SvgElementFactoryProvider.createSvgElement_tag("animate");
  AnimateElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGAnimateMotionElement
class AnimateMotionElement extends AnimationElement {

  factory AnimateMotionElement() => _SvgElementFactoryProvider.createSvgElement_tag("animateMotion");
  AnimateMotionElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGAnimateTransformElement
class AnimateTransformElement extends AnimationElement {

  factory AnimateTransformElement() => _SvgElementFactoryProvider.createSvgElement_tag("animateTransform");
  AnimateTransformElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGAnimatedAngle
class AnimatedAngle extends NativeFieldWrapperClass1 {
  AnimatedAngle.internal();


  /** @domName SVGAnimatedAngle.animVal */
  Angle get animVal native "SVGAnimatedAngle_animVal_Getter";


  /** @domName SVGAnimatedAngle.baseVal */
  Angle get baseVal native "SVGAnimatedAngle_baseVal_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGAnimatedBoolean
class AnimatedBoolean extends NativeFieldWrapperClass1 {
  AnimatedBoolean.internal();


  /** @domName SVGAnimatedBoolean.animVal */
  bool get animVal native "SVGAnimatedBoolean_animVal_Getter";


  /** @domName SVGAnimatedBoolean.baseVal */
  bool get baseVal native "SVGAnimatedBoolean_baseVal_Getter";


  /** @domName SVGAnimatedBoolean.baseVal */
  void set baseVal(bool value) native "SVGAnimatedBoolean_baseVal_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGAnimatedEnumeration
class AnimatedEnumeration extends NativeFieldWrapperClass1 {
  AnimatedEnumeration.internal();


  /** @domName SVGAnimatedEnumeration.animVal */
  int get animVal native "SVGAnimatedEnumeration_animVal_Getter";


  /** @domName SVGAnimatedEnumeration.baseVal */
  int get baseVal native "SVGAnimatedEnumeration_baseVal_Getter";


  /** @domName SVGAnimatedEnumeration.baseVal */
  void set baseVal(int value) native "SVGAnimatedEnumeration_baseVal_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGAnimatedInteger
class AnimatedInteger extends NativeFieldWrapperClass1 {
  AnimatedInteger.internal();


  /** @domName SVGAnimatedInteger.animVal */
  int get animVal native "SVGAnimatedInteger_animVal_Getter";


  /** @domName SVGAnimatedInteger.baseVal */
  int get baseVal native "SVGAnimatedInteger_baseVal_Getter";


  /** @domName SVGAnimatedInteger.baseVal */
  void set baseVal(int value) native "SVGAnimatedInteger_baseVal_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGAnimatedLength
class AnimatedLength extends NativeFieldWrapperClass1 {
  AnimatedLength.internal();


  /** @domName SVGAnimatedLength.animVal */
  Length get animVal native "SVGAnimatedLength_animVal_Getter";


  /** @domName SVGAnimatedLength.baseVal */
  Length get baseVal native "SVGAnimatedLength_baseVal_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGAnimatedLengthList
class AnimatedLengthList extends NativeFieldWrapperClass1 implements List<AnimatedLength> {
  AnimatedLengthList.internal();


  /** @domName SVGAnimatedLengthList.animVal */
  LengthList get animVal native "SVGAnimatedLengthList_animVal_Getter";


  /** @domName SVGAnimatedLengthList.baseVal */
  LengthList get baseVal native "SVGAnimatedLengthList_baseVal_Getter";

  AnimatedLength operator[](int index) native "SVGAnimatedLengthList_item_Callback";

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

  bool contains(AnimatedLength element) => Collections.contains(this, element);

  void forEach(void f(AnimatedLength element)) => Collections.forEach(this, f);

  Collection map(f(AnimatedLength element)) => Collections.map(this, [], f);

  Collection<AnimatedLength> filter(bool f(AnimatedLength element)) =>
     Collections.filter(this, <AnimatedLength>[], f);

  bool every(bool f(AnimatedLength element)) => Collections.every(this, f);

  bool some(bool f(AnimatedLength element)) => Collections.some(this, f);

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

// WARNING: Do not edit - generated code.


/// @domName SVGAnimatedNumber
class AnimatedNumber extends NativeFieldWrapperClass1 {
  AnimatedNumber.internal();


  /** @domName SVGAnimatedNumber.animVal */
  num get animVal native "SVGAnimatedNumber_animVal_Getter";


  /** @domName SVGAnimatedNumber.baseVal */
  num get baseVal native "SVGAnimatedNumber_baseVal_Getter";


  /** @domName SVGAnimatedNumber.baseVal */
  void set baseVal(num value) native "SVGAnimatedNumber_baseVal_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGAnimatedNumberList
class AnimatedNumberList extends NativeFieldWrapperClass1 implements List<AnimatedNumber> {
  AnimatedNumberList.internal();


  /** @domName SVGAnimatedNumberList.animVal */
  NumberList get animVal native "SVGAnimatedNumberList_animVal_Getter";


  /** @domName SVGAnimatedNumberList.baseVal */
  NumberList get baseVal native "SVGAnimatedNumberList_baseVal_Getter";

  AnimatedNumber operator[](int index) native "SVGAnimatedNumberList_item_Callback";

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

  bool contains(AnimatedNumber element) => Collections.contains(this, element);

  void forEach(void f(AnimatedNumber element)) => Collections.forEach(this, f);

  Collection map(f(AnimatedNumber element)) => Collections.map(this, [], f);

  Collection<AnimatedNumber> filter(bool f(AnimatedNumber element)) =>
     Collections.filter(this, <AnimatedNumber>[], f);

  bool every(bool f(AnimatedNumber element)) => Collections.every(this, f);

  bool some(bool f(AnimatedNumber element)) => Collections.some(this, f);

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

// WARNING: Do not edit - generated code.


/// @domName SVGAnimatedPreserveAspectRatio
class AnimatedPreserveAspectRatio extends NativeFieldWrapperClass1 {
  AnimatedPreserveAspectRatio.internal();


  /** @domName SVGAnimatedPreserveAspectRatio.animVal */
  PreserveAspectRatio get animVal native "SVGAnimatedPreserveAspectRatio_animVal_Getter";


  /** @domName SVGAnimatedPreserveAspectRatio.baseVal */
  PreserveAspectRatio get baseVal native "SVGAnimatedPreserveAspectRatio_baseVal_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGAnimatedRect
class AnimatedRect extends NativeFieldWrapperClass1 {
  AnimatedRect.internal();


  /** @domName SVGAnimatedRect.animVal */
  Rect get animVal native "SVGAnimatedRect_animVal_Getter";


  /** @domName SVGAnimatedRect.baseVal */
  Rect get baseVal native "SVGAnimatedRect_baseVal_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGAnimatedString
class AnimatedString extends NativeFieldWrapperClass1 {
  AnimatedString.internal();


  /** @domName SVGAnimatedString.animVal */
  String get animVal native "SVGAnimatedString_animVal_Getter";


  /** @domName SVGAnimatedString.baseVal */
  String get baseVal native "SVGAnimatedString_baseVal_Getter";


  /** @domName SVGAnimatedString.baseVal */
  void set baseVal(String value) native "SVGAnimatedString_baseVal_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGAnimatedTransformList
class AnimatedTransformList extends NativeFieldWrapperClass1 implements List<AnimateTransformElement> {
  AnimatedTransformList.internal();


  /** @domName SVGAnimatedTransformList.animVal */
  TransformList get animVal native "SVGAnimatedTransformList_animVal_Getter";


  /** @domName SVGAnimatedTransformList.baseVal */
  TransformList get baseVal native "SVGAnimatedTransformList_baseVal_Getter";

  AnimateTransformElement operator[](int index) native "SVGAnimatedTransformList_item_Callback";

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

  bool contains(AnimateTransformElement element) => Collections.contains(this, element);

  void forEach(void f(AnimateTransformElement element)) => Collections.forEach(this, f);

  Collection map(f(AnimateTransformElement element)) => Collections.map(this, [], f);

  Collection<AnimateTransformElement> filter(bool f(AnimateTransformElement element)) =>
     Collections.filter(this, <AnimateTransformElement>[], f);

  bool every(bool f(AnimateTransformElement element)) => Collections.every(this, f);

  bool some(bool f(AnimateTransformElement element)) => Collections.some(this, f);

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

// WARNING: Do not edit - generated code.


/// @domName SVGAnimationElement
class AnimationElement extends SvgElement implements Tests, ElementTimeControl, ExternalResourcesRequired {

  factory AnimationElement() => _SvgElementFactoryProvider.createSvgElement_tag("animation");
  AnimationElement.internal(): super.internal();


  /** @domName SVGAnimationElement.targetElement */
  SvgElement get targetElement native "SVGAnimationElement_targetElement_Getter";


  /** @domName SVGAnimationElement.getCurrentTime */
  num getCurrentTime() native "SVGAnimationElement_getCurrentTime_Callback";


  /** @domName SVGAnimationElement.getSimpleDuration */
  num getSimpleDuration() native "SVGAnimationElement_getSimpleDuration_Callback";


  /** @domName SVGAnimationElement.getStartTime */
  num getStartTime() native "SVGAnimationElement_getStartTime_Callback";


  /** @domName SVGAnimationElement.beginElement */
  void beginElement() native "SVGAnimationElement_beginElement_Callback";


  /** @domName SVGAnimationElement.beginElementAt */
  void beginElementAt(num offset) native "SVGAnimationElement_beginElementAt_Callback";


  /** @domName SVGAnimationElement.endElement */
  void endElement() native "SVGAnimationElement_endElement_Callback";


  /** @domName SVGAnimationElement.endElementAt */
  void endElementAt(num offset) native "SVGAnimationElement_endElementAt_Callback";


  /** @domName SVGAnimationElement.externalResourcesRequired */
  AnimatedBoolean get externalResourcesRequired native "SVGAnimationElement_externalResourcesRequired_Getter";


  /** @domName SVGAnimationElement.requiredExtensions */
  StringList get requiredExtensions native "SVGAnimationElement_requiredExtensions_Getter";


  /** @domName SVGAnimationElement.requiredFeatures */
  StringList get requiredFeatures native "SVGAnimationElement_requiredFeatures_Getter";


  /** @domName SVGAnimationElement.systemLanguage */
  StringList get systemLanguage native "SVGAnimationElement_systemLanguage_Getter";


  /** @domName SVGAnimationElement.hasExtension */
  bool hasExtension(String extension) native "SVGAnimationElement_hasExtension_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGCircleElement
class CircleElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace {

  factory CircleElement() => _SvgElementFactoryProvider.createSvgElement_tag("circle");
  CircleElement.internal(): super.internal();


  /** @domName SVGCircleElement.cx */
  AnimatedLength get cx native "SVGCircleElement_cx_Getter";


  /** @domName SVGCircleElement.cy */
  AnimatedLength get cy native "SVGCircleElement_cy_Getter";


  /** @domName SVGCircleElement.r */
  AnimatedLength get r native "SVGCircleElement_r_Getter";


  /** @domName SVGCircleElement.externalResourcesRequired */
  AnimatedBoolean get externalResourcesRequired native "SVGCircleElement_externalResourcesRequired_Getter";


  /** @domName SVGCircleElement.xmllang */
  String get xmllang native "SVGCircleElement_xmllang_Getter";


  /** @domName SVGCircleElement.xmllang */
  void set xmllang(String value) native "SVGCircleElement_xmllang_Setter";


  /** @domName SVGCircleElement.xmlspace */
  String get xmlspace native "SVGCircleElement_xmlspace_Getter";


  /** @domName SVGCircleElement.xmlspace */
  void set xmlspace(String value) native "SVGCircleElement_xmlspace_Setter";


  /** @domName SVGCircleElement.farthestViewportElement */
  SvgElement get farthestViewportElement native "SVGCircleElement_farthestViewportElement_Getter";


  /** @domName SVGCircleElement.nearestViewportElement */
  SvgElement get nearestViewportElement native "SVGCircleElement_nearestViewportElement_Getter";


  /** @domName SVGCircleElement.getBBox */
  Rect getBBox() native "SVGCircleElement_getBBox_Callback";


  /** @domName SVGCircleElement.getCTM */
  Matrix getCtm() native "SVGCircleElement_getCTM_Callback";


  /** @domName SVGCircleElement.getScreenCTM */
  Matrix getScreenCtm() native "SVGCircleElement_getScreenCTM_Callback";


  /** @domName SVGCircleElement.getTransformToElement */
  Matrix getTransformToElement(SvgElement element) native "SVGCircleElement_getTransformToElement_Callback";


  /** @domName SVGCircleElement.className */
  AnimatedString get $dom_svgClassName native "SVGCircleElement_className_Getter";


  /** @domName SVGCircleElement.style */
  CSSStyleDeclaration get style native "SVGCircleElement_style_Getter";


  /** @domName SVGCircleElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGCircleElement_getPresentationAttribute_Callback";


  /** @domName SVGCircleElement.requiredExtensions */
  StringList get requiredExtensions native "SVGCircleElement_requiredExtensions_Getter";


  /** @domName SVGCircleElement.requiredFeatures */
  StringList get requiredFeatures native "SVGCircleElement_requiredFeatures_Getter";


  /** @domName SVGCircleElement.systemLanguage */
  StringList get systemLanguage native "SVGCircleElement_systemLanguage_Getter";


  /** @domName SVGCircleElement.hasExtension */
  bool hasExtension(String extension) native "SVGCircleElement_hasExtension_Callback";


  /** @domName SVGCircleElement.transform */
  AnimatedTransformList get transform native "SVGCircleElement_transform_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGClipPathElement
class ClipPathElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace {

  factory ClipPathElement() => _SvgElementFactoryProvider.createSvgElement_tag("clipPath");
  ClipPathElement.internal(): super.internal();


  /** @domName SVGClipPathElement.clipPathUnits */
  AnimatedEnumeration get clipPathUnits native "SVGClipPathElement_clipPathUnits_Getter";


  /** @domName SVGClipPathElement.externalResourcesRequired */
  AnimatedBoolean get externalResourcesRequired native "SVGClipPathElement_externalResourcesRequired_Getter";


  /** @domName SVGClipPathElement.xmllang */
  String get xmllang native "SVGClipPathElement_xmllang_Getter";


  /** @domName SVGClipPathElement.xmllang */
  void set xmllang(String value) native "SVGClipPathElement_xmllang_Setter";


  /** @domName SVGClipPathElement.xmlspace */
  String get xmlspace native "SVGClipPathElement_xmlspace_Getter";


  /** @domName SVGClipPathElement.xmlspace */
  void set xmlspace(String value) native "SVGClipPathElement_xmlspace_Setter";


  /** @domName SVGClipPathElement.farthestViewportElement */
  SvgElement get farthestViewportElement native "SVGClipPathElement_farthestViewportElement_Getter";


  /** @domName SVGClipPathElement.nearestViewportElement */
  SvgElement get nearestViewportElement native "SVGClipPathElement_nearestViewportElement_Getter";


  /** @domName SVGClipPathElement.getBBox */
  Rect getBBox() native "SVGClipPathElement_getBBox_Callback";


  /** @domName SVGClipPathElement.getCTM */
  Matrix getCtm() native "SVGClipPathElement_getCTM_Callback";


  /** @domName SVGClipPathElement.getScreenCTM */
  Matrix getScreenCtm() native "SVGClipPathElement_getScreenCTM_Callback";


  /** @domName SVGClipPathElement.getTransformToElement */
  Matrix getTransformToElement(SvgElement element) native "SVGClipPathElement_getTransformToElement_Callback";


  /** @domName SVGClipPathElement.className */
  AnimatedString get $dom_svgClassName native "SVGClipPathElement_className_Getter";


  /** @domName SVGClipPathElement.style */
  CSSStyleDeclaration get style native "SVGClipPathElement_style_Getter";


  /** @domName SVGClipPathElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGClipPathElement_getPresentationAttribute_Callback";


  /** @domName SVGClipPathElement.requiredExtensions */
  StringList get requiredExtensions native "SVGClipPathElement_requiredExtensions_Getter";


  /** @domName SVGClipPathElement.requiredFeatures */
  StringList get requiredFeatures native "SVGClipPathElement_requiredFeatures_Getter";


  /** @domName SVGClipPathElement.systemLanguage */
  StringList get systemLanguage native "SVGClipPathElement_systemLanguage_Getter";


  /** @domName SVGClipPathElement.hasExtension */
  bool hasExtension(String extension) native "SVGClipPathElement_hasExtension_Callback";


  /** @domName SVGClipPathElement.transform */
  AnimatedTransformList get transform native "SVGClipPathElement_transform_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGColor
class Color extends CSSValue {
  Color.internal(): super.internal();

  static const int SVG_COLORTYPE_CURRENTCOLOR = 3;

  static const int SVG_COLORTYPE_RGBCOLOR = 1;

  static const int SVG_COLORTYPE_RGBCOLOR_ICCCOLOR = 2;

  static const int SVG_COLORTYPE_UNKNOWN = 0;


  /** @domName SVGColor.colorType */
  int get colorType native "SVGColor_colorType_Getter";


  /** @domName SVGColor.rgbColor */
  RGBColor get rgbColor native "SVGColor_rgbColor_Getter";


  /** @domName SVGColor.setColor */
  void setColor(int colorType, String rgbColor, String iccColor) native "SVGColor_setColor_Callback";


  /** @domName SVGColor.setRGBColor */
  void setRgbColor(String rgbColor) native "SVGColor_setRGBColor_Callback";


  /** @domName SVGColor.setRGBColorICCColor */
  void setRgbColorIccColor(String rgbColor, String iccColor) native "SVGColor_setRGBColorICCColor_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGComponentTransferFunctionElement
class ComponentTransferFunctionElement extends SvgElement {
  ComponentTransferFunctionElement.internal(): super.internal();

  static const int SVG_FECOMPONENTTRANSFER_TYPE_DISCRETE = 3;

  static const int SVG_FECOMPONENTTRANSFER_TYPE_GAMMA = 5;

  static const int SVG_FECOMPONENTTRANSFER_TYPE_IDENTITY = 1;

  static const int SVG_FECOMPONENTTRANSFER_TYPE_LINEAR = 4;

  static const int SVG_FECOMPONENTTRANSFER_TYPE_TABLE = 2;

  static const int SVG_FECOMPONENTTRANSFER_TYPE_UNKNOWN = 0;


  /** @domName SVGComponentTransferFunctionElement.amplitude */
  AnimatedNumber get amplitude native "SVGComponentTransferFunctionElement_amplitude_Getter";


  /** @domName SVGComponentTransferFunctionElement.exponent */
  AnimatedNumber get exponent native "SVGComponentTransferFunctionElement_exponent_Getter";


  /** @domName SVGComponentTransferFunctionElement.intercept */
  AnimatedNumber get intercept native "SVGComponentTransferFunctionElement_intercept_Getter";


  /** @domName SVGComponentTransferFunctionElement.offset */
  AnimatedNumber get offset native "SVGComponentTransferFunctionElement_offset_Getter";


  /** @domName SVGComponentTransferFunctionElement.slope */
  AnimatedNumber get slope native "SVGComponentTransferFunctionElement_slope_Getter";


  /** @domName SVGComponentTransferFunctionElement.tableValues */
  AnimatedNumberList get tableValues native "SVGComponentTransferFunctionElement_tableValues_Getter";


  /** @domName SVGComponentTransferFunctionElement.type */
  AnimatedEnumeration get type native "SVGComponentTransferFunctionElement_type_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGCursorElement
class CursorElement extends SvgElement implements UriReference, Tests, ExternalResourcesRequired {

  factory CursorElement() => _SvgElementFactoryProvider.createSvgElement_tag("cursor");
  CursorElement.internal(): super.internal();


  /** @domName SVGCursorElement.x */
  AnimatedLength get x native "SVGCursorElement_x_Getter";


  /** @domName SVGCursorElement.y */
  AnimatedLength get y native "SVGCursorElement_y_Getter";


  /** @domName SVGCursorElement.externalResourcesRequired */
  AnimatedBoolean get externalResourcesRequired native "SVGCursorElement_externalResourcesRequired_Getter";


  /** @domName SVGCursorElement.requiredExtensions */
  StringList get requiredExtensions native "SVGCursorElement_requiredExtensions_Getter";


  /** @domName SVGCursorElement.requiredFeatures */
  StringList get requiredFeatures native "SVGCursorElement_requiredFeatures_Getter";


  /** @domName SVGCursorElement.systemLanguage */
  StringList get systemLanguage native "SVGCursorElement_systemLanguage_Getter";


  /** @domName SVGCursorElement.hasExtension */
  bool hasExtension(String extension) native "SVGCursorElement_hasExtension_Callback";


  /** @domName SVGCursorElement.href */
  AnimatedString get href native "SVGCursorElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGDefsElement
class DefsElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace {

  factory DefsElement() => _SvgElementFactoryProvider.createSvgElement_tag("defs");
  DefsElement.internal(): super.internal();


  /** @domName SVGDefsElement.externalResourcesRequired */
  AnimatedBoolean get externalResourcesRequired native "SVGDefsElement_externalResourcesRequired_Getter";


  /** @domName SVGDefsElement.xmllang */
  String get xmllang native "SVGDefsElement_xmllang_Getter";


  /** @domName SVGDefsElement.xmllang */
  void set xmllang(String value) native "SVGDefsElement_xmllang_Setter";


  /** @domName SVGDefsElement.xmlspace */
  String get xmlspace native "SVGDefsElement_xmlspace_Getter";


  /** @domName SVGDefsElement.xmlspace */
  void set xmlspace(String value) native "SVGDefsElement_xmlspace_Setter";


  /** @domName SVGDefsElement.farthestViewportElement */
  SvgElement get farthestViewportElement native "SVGDefsElement_farthestViewportElement_Getter";


  /** @domName SVGDefsElement.nearestViewportElement */
  SvgElement get nearestViewportElement native "SVGDefsElement_nearestViewportElement_Getter";


  /** @domName SVGDefsElement.getBBox */
  Rect getBBox() native "SVGDefsElement_getBBox_Callback";


  /** @domName SVGDefsElement.getCTM */
  Matrix getCtm() native "SVGDefsElement_getCTM_Callback";


  /** @domName SVGDefsElement.getScreenCTM */
  Matrix getScreenCtm() native "SVGDefsElement_getScreenCTM_Callback";


  /** @domName SVGDefsElement.getTransformToElement */
  Matrix getTransformToElement(SvgElement element) native "SVGDefsElement_getTransformToElement_Callback";


  /** @domName SVGDefsElement.className */
  AnimatedString get $dom_svgClassName native "SVGDefsElement_className_Getter";


  /** @domName SVGDefsElement.style */
  CSSStyleDeclaration get style native "SVGDefsElement_style_Getter";


  /** @domName SVGDefsElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGDefsElement_getPresentationAttribute_Callback";


  /** @domName SVGDefsElement.requiredExtensions */
  StringList get requiredExtensions native "SVGDefsElement_requiredExtensions_Getter";


  /** @domName SVGDefsElement.requiredFeatures */
  StringList get requiredFeatures native "SVGDefsElement_requiredFeatures_Getter";


  /** @domName SVGDefsElement.systemLanguage */
  StringList get systemLanguage native "SVGDefsElement_systemLanguage_Getter";


  /** @domName SVGDefsElement.hasExtension */
  bool hasExtension(String extension) native "SVGDefsElement_hasExtension_Callback";


  /** @domName SVGDefsElement.transform */
  AnimatedTransformList get transform native "SVGDefsElement_transform_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGDescElement
class DescElement extends SvgElement implements Stylable, LangSpace {

  factory DescElement() => _SvgElementFactoryProvider.createSvgElement_tag("desc");
  DescElement.internal(): super.internal();


  /** @domName SVGDescElement.xmllang */
  String get xmllang native "SVGDescElement_xmllang_Getter";


  /** @domName SVGDescElement.xmllang */
  void set xmllang(String value) native "SVGDescElement_xmllang_Setter";


  /** @domName SVGDescElement.xmlspace */
  String get xmlspace native "SVGDescElement_xmlspace_Getter";


  /** @domName SVGDescElement.xmlspace */
  void set xmlspace(String value) native "SVGDescElement_xmlspace_Setter";


  /** @domName SVGDescElement.className */
  AnimatedString get $dom_svgClassName native "SVGDescElement_className_Getter";


  /** @domName SVGDescElement.style */
  CSSStyleDeclaration get style native "SVGDescElement_style_Getter";


  /** @domName SVGDescElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGDescElement_getPresentationAttribute_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGElementInstance
class ElementInstance extends EventTarget {
  ElementInstance.internal(): super.internal();

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  ElementInstanceEvents get on =>
    new ElementInstanceEvents(this);


  /** @domName SVGElementInstance.childNodes */
  List<ElementInstance> get childNodes native "SVGElementInstance_childNodes_Getter";


  /** @domName SVGElementInstance.correspondingElement */
  SvgElement get correspondingElement native "SVGElementInstance_correspondingElement_Getter";


  /** @domName SVGElementInstance.correspondingUseElement */
  UseElement get correspondingUseElement native "SVGElementInstance_correspondingUseElement_Getter";


  /** @domName SVGElementInstance.firstChild */
  ElementInstance get firstChild native "SVGElementInstance_firstChild_Getter";


  /** @domName SVGElementInstance.lastChild */
  ElementInstance get lastChild native "SVGElementInstance_lastChild_Getter";


  /** @domName SVGElementInstance.nextSibling */
  ElementInstance get nextSibling native "SVGElementInstance_nextSibling_Getter";


  /** @domName SVGElementInstance.parentNode */
  ElementInstance get parentNode native "SVGElementInstance_parentNode_Getter";


  /** @domName SVGElementInstance.previousSibling */
  ElementInstance get previousSibling native "SVGElementInstance_previousSibling_Getter";

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

// WARNING: Do not edit - generated code.


/// @domName SVGEllipseElement
class EllipseElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace {

  factory EllipseElement() => _SvgElementFactoryProvider.createSvgElement_tag("ellipse");
  EllipseElement.internal(): super.internal();


  /** @domName SVGEllipseElement.cx */
  AnimatedLength get cx native "SVGEllipseElement_cx_Getter";


  /** @domName SVGEllipseElement.cy */
  AnimatedLength get cy native "SVGEllipseElement_cy_Getter";


  /** @domName SVGEllipseElement.rx */
  AnimatedLength get rx native "SVGEllipseElement_rx_Getter";


  /** @domName SVGEllipseElement.ry */
  AnimatedLength get ry native "SVGEllipseElement_ry_Getter";


  /** @domName SVGEllipseElement.externalResourcesRequired */
  AnimatedBoolean get externalResourcesRequired native "SVGEllipseElement_externalResourcesRequired_Getter";


  /** @domName SVGEllipseElement.xmllang */
  String get xmllang native "SVGEllipseElement_xmllang_Getter";


  /** @domName SVGEllipseElement.xmllang */
  void set xmllang(String value) native "SVGEllipseElement_xmllang_Setter";


  /** @domName SVGEllipseElement.xmlspace */
  String get xmlspace native "SVGEllipseElement_xmlspace_Getter";


  /** @domName SVGEllipseElement.xmlspace */
  void set xmlspace(String value) native "SVGEllipseElement_xmlspace_Setter";


  /** @domName SVGEllipseElement.farthestViewportElement */
  SvgElement get farthestViewportElement native "SVGEllipseElement_farthestViewportElement_Getter";


  /** @domName SVGEllipseElement.nearestViewportElement */
  SvgElement get nearestViewportElement native "SVGEllipseElement_nearestViewportElement_Getter";


  /** @domName SVGEllipseElement.getBBox */
  Rect getBBox() native "SVGEllipseElement_getBBox_Callback";


  /** @domName SVGEllipseElement.getCTM */
  Matrix getCtm() native "SVGEllipseElement_getCTM_Callback";


  /** @domName SVGEllipseElement.getScreenCTM */
  Matrix getScreenCtm() native "SVGEllipseElement_getScreenCTM_Callback";


  /** @domName SVGEllipseElement.getTransformToElement */
  Matrix getTransformToElement(SvgElement element) native "SVGEllipseElement_getTransformToElement_Callback";


  /** @domName SVGEllipseElement.className */
  AnimatedString get $dom_svgClassName native "SVGEllipseElement_className_Getter";


  /** @domName SVGEllipseElement.style */
  CSSStyleDeclaration get style native "SVGEllipseElement_style_Getter";


  /** @domName SVGEllipseElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGEllipseElement_getPresentationAttribute_Callback";


  /** @domName SVGEllipseElement.requiredExtensions */
  StringList get requiredExtensions native "SVGEllipseElement_requiredExtensions_Getter";


  /** @domName SVGEllipseElement.requiredFeatures */
  StringList get requiredFeatures native "SVGEllipseElement_requiredFeatures_Getter";


  /** @domName SVGEllipseElement.systemLanguage */
  StringList get systemLanguage native "SVGEllipseElement_systemLanguage_Getter";


  /** @domName SVGEllipseElement.hasExtension */
  bool hasExtension(String extension) native "SVGEllipseElement_hasExtension_Callback";


  /** @domName SVGEllipseElement.transform */
  AnimatedTransformList get transform native "SVGEllipseElement_transform_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGExternalResourcesRequired
class ExternalResourcesRequired extends NativeFieldWrapperClass1 {
  ExternalResourcesRequired.internal();


  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  AnimatedBoolean get externalResourcesRequired native "SVGExternalResourcesRequired_externalResourcesRequired_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFEBlendElement
class FEBlendElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  FEBlendElement.internal(): super.internal();

  static const int SVG_FEBLEND_MODE_DARKEN = 4;

  static const int SVG_FEBLEND_MODE_LIGHTEN = 5;

  static const int SVG_FEBLEND_MODE_MULTIPLY = 2;

  static const int SVG_FEBLEND_MODE_NORMAL = 1;

  static const int SVG_FEBLEND_MODE_SCREEN = 3;

  static const int SVG_FEBLEND_MODE_UNKNOWN = 0;


  /** @domName SVGFEBlendElement.in1 */
  AnimatedString get in1 native "SVGFEBlendElement_in1_Getter";


  /** @domName SVGFEBlendElement.in2 */
  AnimatedString get in2 native "SVGFEBlendElement_in2_Getter";


  /** @domName SVGFEBlendElement.mode */
  AnimatedEnumeration get mode native "SVGFEBlendElement_mode_Getter";


  /** @domName SVGFEBlendElement.height */
  AnimatedLength get height native "SVGFEBlendElement_height_Getter";


  /** @domName SVGFEBlendElement.result */
  AnimatedString get result native "SVGFEBlendElement_result_Getter";


  /** @domName SVGFEBlendElement.width */
  AnimatedLength get width native "SVGFEBlendElement_width_Getter";


  /** @domName SVGFEBlendElement.x */
  AnimatedLength get x native "SVGFEBlendElement_x_Getter";


  /** @domName SVGFEBlendElement.y */
  AnimatedLength get y native "SVGFEBlendElement_y_Getter";


  /** @domName SVGFEBlendElement.className */
  AnimatedString get $dom_svgClassName native "SVGFEBlendElement_className_Getter";


  /** @domName SVGFEBlendElement.style */
  CSSStyleDeclaration get style native "SVGFEBlendElement_style_Getter";


  /** @domName SVGFEBlendElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGFEBlendElement_getPresentationAttribute_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFEColorMatrixElement
class FEColorMatrixElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  FEColorMatrixElement.internal(): super.internal();

  static const int SVG_FECOLORMATRIX_TYPE_HUEROTATE = 3;

  static const int SVG_FECOLORMATRIX_TYPE_LUMINANCETOALPHA = 4;

  static const int SVG_FECOLORMATRIX_TYPE_MATRIX = 1;

  static const int SVG_FECOLORMATRIX_TYPE_SATURATE = 2;

  static const int SVG_FECOLORMATRIX_TYPE_UNKNOWN = 0;


  /** @domName SVGFEColorMatrixElement.in1 */
  AnimatedString get in1 native "SVGFEColorMatrixElement_in1_Getter";


  /** @domName SVGFEColorMatrixElement.type */
  AnimatedEnumeration get type native "SVGFEColorMatrixElement_type_Getter";


  /** @domName SVGFEColorMatrixElement.values */
  AnimatedNumberList get values native "SVGFEColorMatrixElement_values_Getter";


  /** @domName SVGFEColorMatrixElement.height */
  AnimatedLength get height native "SVGFEColorMatrixElement_height_Getter";


  /** @domName SVGFEColorMatrixElement.result */
  AnimatedString get result native "SVGFEColorMatrixElement_result_Getter";


  /** @domName SVGFEColorMatrixElement.width */
  AnimatedLength get width native "SVGFEColorMatrixElement_width_Getter";


  /** @domName SVGFEColorMatrixElement.x */
  AnimatedLength get x native "SVGFEColorMatrixElement_x_Getter";


  /** @domName SVGFEColorMatrixElement.y */
  AnimatedLength get y native "SVGFEColorMatrixElement_y_Getter";


  /** @domName SVGFEColorMatrixElement.className */
  AnimatedString get $dom_svgClassName native "SVGFEColorMatrixElement_className_Getter";


  /** @domName SVGFEColorMatrixElement.style */
  CSSStyleDeclaration get style native "SVGFEColorMatrixElement_style_Getter";


  /** @domName SVGFEColorMatrixElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGFEColorMatrixElement_getPresentationAttribute_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFEComponentTransferElement
class FEComponentTransferElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  FEComponentTransferElement.internal(): super.internal();


  /** @domName SVGFEComponentTransferElement.in1 */
  AnimatedString get in1 native "SVGFEComponentTransferElement_in1_Getter";


  /** @domName SVGFEComponentTransferElement.height */
  AnimatedLength get height native "SVGFEComponentTransferElement_height_Getter";


  /** @domName SVGFEComponentTransferElement.result */
  AnimatedString get result native "SVGFEComponentTransferElement_result_Getter";


  /** @domName SVGFEComponentTransferElement.width */
  AnimatedLength get width native "SVGFEComponentTransferElement_width_Getter";


  /** @domName SVGFEComponentTransferElement.x */
  AnimatedLength get x native "SVGFEComponentTransferElement_x_Getter";


  /** @domName SVGFEComponentTransferElement.y */
  AnimatedLength get y native "SVGFEComponentTransferElement_y_Getter";


  /** @domName SVGFEComponentTransferElement.className */
  AnimatedString get $dom_svgClassName native "SVGFEComponentTransferElement_className_Getter";


  /** @domName SVGFEComponentTransferElement.style */
  CSSStyleDeclaration get style native "SVGFEComponentTransferElement_style_Getter";


  /** @domName SVGFEComponentTransferElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGFEComponentTransferElement_getPresentationAttribute_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFECompositeElement
class FECompositeElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  FECompositeElement.internal(): super.internal();

  static const int SVG_FECOMPOSITE_OPERATOR_ARITHMETIC = 6;

  static const int SVG_FECOMPOSITE_OPERATOR_ATOP = 4;

  static const int SVG_FECOMPOSITE_OPERATOR_IN = 2;

  static const int SVG_FECOMPOSITE_OPERATOR_OUT = 3;

  static const int SVG_FECOMPOSITE_OPERATOR_OVER = 1;

  static const int SVG_FECOMPOSITE_OPERATOR_UNKNOWN = 0;

  static const int SVG_FECOMPOSITE_OPERATOR_XOR = 5;


  /** @domName SVGFECompositeElement.in1 */
  AnimatedString get in1 native "SVGFECompositeElement_in1_Getter";


  /** @domName SVGFECompositeElement.in2 */
  AnimatedString get in2 native "SVGFECompositeElement_in2_Getter";


  /** @domName SVGFECompositeElement.k1 */
  AnimatedNumber get k1 native "SVGFECompositeElement_k1_Getter";


  /** @domName SVGFECompositeElement.k2 */
  AnimatedNumber get k2 native "SVGFECompositeElement_k2_Getter";


  /** @domName SVGFECompositeElement.k3 */
  AnimatedNumber get k3 native "SVGFECompositeElement_k3_Getter";


  /** @domName SVGFECompositeElement.k4 */
  AnimatedNumber get k4 native "SVGFECompositeElement_k4_Getter";


  /** @domName SVGFECompositeElement.operator */
  AnimatedEnumeration get operator native "SVGFECompositeElement_operator_Getter";


  /** @domName SVGFECompositeElement.height */
  AnimatedLength get height native "SVGFECompositeElement_height_Getter";


  /** @domName SVGFECompositeElement.result */
  AnimatedString get result native "SVGFECompositeElement_result_Getter";


  /** @domName SVGFECompositeElement.width */
  AnimatedLength get width native "SVGFECompositeElement_width_Getter";


  /** @domName SVGFECompositeElement.x */
  AnimatedLength get x native "SVGFECompositeElement_x_Getter";


  /** @domName SVGFECompositeElement.y */
  AnimatedLength get y native "SVGFECompositeElement_y_Getter";


  /** @domName SVGFECompositeElement.className */
  AnimatedString get $dom_svgClassName native "SVGFECompositeElement_className_Getter";


  /** @domName SVGFECompositeElement.style */
  CSSStyleDeclaration get style native "SVGFECompositeElement_style_Getter";


  /** @domName SVGFECompositeElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGFECompositeElement_getPresentationAttribute_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFEConvolveMatrixElement
class FEConvolveMatrixElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  FEConvolveMatrixElement.internal(): super.internal();

  static const int SVG_EDGEMODE_DUPLICATE = 1;

  static const int SVG_EDGEMODE_NONE = 3;

  static const int SVG_EDGEMODE_UNKNOWN = 0;

  static const int SVG_EDGEMODE_WRAP = 2;


  /** @domName SVGFEConvolveMatrixElement.bias */
  AnimatedNumber get bias native "SVGFEConvolveMatrixElement_bias_Getter";


  /** @domName SVGFEConvolveMatrixElement.divisor */
  AnimatedNumber get divisor native "SVGFEConvolveMatrixElement_divisor_Getter";


  /** @domName SVGFEConvolveMatrixElement.edgeMode */
  AnimatedEnumeration get edgeMode native "SVGFEConvolveMatrixElement_edgeMode_Getter";


  /** @domName SVGFEConvolveMatrixElement.in1 */
  AnimatedString get in1 native "SVGFEConvolveMatrixElement_in1_Getter";


  /** @domName SVGFEConvolveMatrixElement.kernelMatrix */
  AnimatedNumberList get kernelMatrix native "SVGFEConvolveMatrixElement_kernelMatrix_Getter";


  /** @domName SVGFEConvolveMatrixElement.kernelUnitLengthX */
  AnimatedNumber get kernelUnitLengthX native "SVGFEConvolveMatrixElement_kernelUnitLengthX_Getter";


  /** @domName SVGFEConvolveMatrixElement.kernelUnitLengthY */
  AnimatedNumber get kernelUnitLengthY native "SVGFEConvolveMatrixElement_kernelUnitLengthY_Getter";


  /** @domName SVGFEConvolveMatrixElement.orderX */
  AnimatedInteger get orderX native "SVGFEConvolveMatrixElement_orderX_Getter";


  /** @domName SVGFEConvolveMatrixElement.orderY */
  AnimatedInteger get orderY native "SVGFEConvolveMatrixElement_orderY_Getter";


  /** @domName SVGFEConvolveMatrixElement.preserveAlpha */
  AnimatedBoolean get preserveAlpha native "SVGFEConvolveMatrixElement_preserveAlpha_Getter";


  /** @domName SVGFEConvolveMatrixElement.targetX */
  AnimatedInteger get targetX native "SVGFEConvolveMatrixElement_targetX_Getter";


  /** @domName SVGFEConvolveMatrixElement.targetY */
  AnimatedInteger get targetY native "SVGFEConvolveMatrixElement_targetY_Getter";


  /** @domName SVGFEConvolveMatrixElement.height */
  AnimatedLength get height native "SVGFEConvolveMatrixElement_height_Getter";


  /** @domName SVGFEConvolveMatrixElement.result */
  AnimatedString get result native "SVGFEConvolveMatrixElement_result_Getter";


  /** @domName SVGFEConvolveMatrixElement.width */
  AnimatedLength get width native "SVGFEConvolveMatrixElement_width_Getter";


  /** @domName SVGFEConvolveMatrixElement.x */
  AnimatedLength get x native "SVGFEConvolveMatrixElement_x_Getter";


  /** @domName SVGFEConvolveMatrixElement.y */
  AnimatedLength get y native "SVGFEConvolveMatrixElement_y_Getter";


  /** @domName SVGFEConvolveMatrixElement.className */
  AnimatedString get $dom_svgClassName native "SVGFEConvolveMatrixElement_className_Getter";


  /** @domName SVGFEConvolveMatrixElement.style */
  CSSStyleDeclaration get style native "SVGFEConvolveMatrixElement_style_Getter";


  /** @domName SVGFEConvolveMatrixElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGFEConvolveMatrixElement_getPresentationAttribute_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFEDiffuseLightingElement
class FEDiffuseLightingElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  FEDiffuseLightingElement.internal(): super.internal();


  /** @domName SVGFEDiffuseLightingElement.diffuseConstant */
  AnimatedNumber get diffuseConstant native "SVGFEDiffuseLightingElement_diffuseConstant_Getter";


  /** @domName SVGFEDiffuseLightingElement.in1 */
  AnimatedString get in1 native "SVGFEDiffuseLightingElement_in1_Getter";


  /** @domName SVGFEDiffuseLightingElement.kernelUnitLengthX */
  AnimatedNumber get kernelUnitLengthX native "SVGFEDiffuseLightingElement_kernelUnitLengthX_Getter";


  /** @domName SVGFEDiffuseLightingElement.kernelUnitLengthY */
  AnimatedNumber get kernelUnitLengthY native "SVGFEDiffuseLightingElement_kernelUnitLengthY_Getter";


  /** @domName SVGFEDiffuseLightingElement.surfaceScale */
  AnimatedNumber get surfaceScale native "SVGFEDiffuseLightingElement_surfaceScale_Getter";


  /** @domName SVGFEDiffuseLightingElement.height */
  AnimatedLength get height native "SVGFEDiffuseLightingElement_height_Getter";


  /** @domName SVGFEDiffuseLightingElement.result */
  AnimatedString get result native "SVGFEDiffuseLightingElement_result_Getter";


  /** @domName SVGFEDiffuseLightingElement.width */
  AnimatedLength get width native "SVGFEDiffuseLightingElement_width_Getter";


  /** @domName SVGFEDiffuseLightingElement.x */
  AnimatedLength get x native "SVGFEDiffuseLightingElement_x_Getter";


  /** @domName SVGFEDiffuseLightingElement.y */
  AnimatedLength get y native "SVGFEDiffuseLightingElement_y_Getter";


  /** @domName SVGFEDiffuseLightingElement.className */
  AnimatedString get $dom_svgClassName native "SVGFEDiffuseLightingElement_className_Getter";


  /** @domName SVGFEDiffuseLightingElement.style */
  CSSStyleDeclaration get style native "SVGFEDiffuseLightingElement_style_Getter";


  /** @domName SVGFEDiffuseLightingElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGFEDiffuseLightingElement_getPresentationAttribute_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFEDisplacementMapElement
class FEDisplacementMapElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  FEDisplacementMapElement.internal(): super.internal();

  static const int SVG_CHANNEL_A = 4;

  static const int SVG_CHANNEL_B = 3;

  static const int SVG_CHANNEL_G = 2;

  static const int SVG_CHANNEL_R = 1;

  static const int SVG_CHANNEL_UNKNOWN = 0;


  /** @domName SVGFEDisplacementMapElement.in1 */
  AnimatedString get in1 native "SVGFEDisplacementMapElement_in1_Getter";


  /** @domName SVGFEDisplacementMapElement.in2 */
  AnimatedString get in2 native "SVGFEDisplacementMapElement_in2_Getter";


  /** @domName SVGFEDisplacementMapElement.scale */
  AnimatedNumber get scale native "SVGFEDisplacementMapElement_scale_Getter";


  /** @domName SVGFEDisplacementMapElement.xChannelSelector */
  AnimatedEnumeration get xChannelSelector native "SVGFEDisplacementMapElement_xChannelSelector_Getter";


  /** @domName SVGFEDisplacementMapElement.yChannelSelector */
  AnimatedEnumeration get yChannelSelector native "SVGFEDisplacementMapElement_yChannelSelector_Getter";


  /** @domName SVGFEDisplacementMapElement.height */
  AnimatedLength get height native "SVGFEDisplacementMapElement_height_Getter";


  /** @domName SVGFEDisplacementMapElement.result */
  AnimatedString get result native "SVGFEDisplacementMapElement_result_Getter";


  /** @domName SVGFEDisplacementMapElement.width */
  AnimatedLength get width native "SVGFEDisplacementMapElement_width_Getter";


  /** @domName SVGFEDisplacementMapElement.x */
  AnimatedLength get x native "SVGFEDisplacementMapElement_x_Getter";


  /** @domName SVGFEDisplacementMapElement.y */
  AnimatedLength get y native "SVGFEDisplacementMapElement_y_Getter";


  /** @domName SVGFEDisplacementMapElement.className */
  AnimatedString get $dom_svgClassName native "SVGFEDisplacementMapElement_className_Getter";


  /** @domName SVGFEDisplacementMapElement.style */
  CSSStyleDeclaration get style native "SVGFEDisplacementMapElement_style_Getter";


  /** @domName SVGFEDisplacementMapElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGFEDisplacementMapElement_getPresentationAttribute_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFEDistantLightElement
class FEDistantLightElement extends SvgElement {
  FEDistantLightElement.internal(): super.internal();


  /** @domName SVGFEDistantLightElement.azimuth */
  AnimatedNumber get azimuth native "SVGFEDistantLightElement_azimuth_Getter";


  /** @domName SVGFEDistantLightElement.elevation */
  AnimatedNumber get elevation native "SVGFEDistantLightElement_elevation_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFEDropShadowElement
class FEDropShadowElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  FEDropShadowElement.internal(): super.internal();


  /** @domName SVGFEDropShadowElement.dx */
  AnimatedNumber get dx native "SVGFEDropShadowElement_dx_Getter";


  /** @domName SVGFEDropShadowElement.dy */
  AnimatedNumber get dy native "SVGFEDropShadowElement_dy_Getter";


  /** @domName SVGFEDropShadowElement.in1 */
  AnimatedString get in1 native "SVGFEDropShadowElement_in1_Getter";


  /** @domName SVGFEDropShadowElement.stdDeviationX */
  AnimatedNumber get stdDeviationX native "SVGFEDropShadowElement_stdDeviationX_Getter";


  /** @domName SVGFEDropShadowElement.stdDeviationY */
  AnimatedNumber get stdDeviationY native "SVGFEDropShadowElement_stdDeviationY_Getter";


  /** @domName SVGFEDropShadowElement.setStdDeviation */
  void setStdDeviation(num stdDeviationX, num stdDeviationY) native "SVGFEDropShadowElement_setStdDeviation_Callback";


  /** @domName SVGFEDropShadowElement.height */
  AnimatedLength get height native "SVGFEDropShadowElement_height_Getter";


  /** @domName SVGFEDropShadowElement.result */
  AnimatedString get result native "SVGFEDropShadowElement_result_Getter";


  /** @domName SVGFEDropShadowElement.width */
  AnimatedLength get width native "SVGFEDropShadowElement_width_Getter";


  /** @domName SVGFEDropShadowElement.x */
  AnimatedLength get x native "SVGFEDropShadowElement_x_Getter";


  /** @domName SVGFEDropShadowElement.y */
  AnimatedLength get y native "SVGFEDropShadowElement_y_Getter";


  /** @domName SVGFEDropShadowElement.className */
  AnimatedString get $dom_svgClassName native "SVGFEDropShadowElement_className_Getter";


  /** @domName SVGFEDropShadowElement.style */
  CSSStyleDeclaration get style native "SVGFEDropShadowElement_style_Getter";


  /** @domName SVGFEDropShadowElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGFEDropShadowElement_getPresentationAttribute_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFEFloodElement
class FEFloodElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  FEFloodElement.internal(): super.internal();


  /** @domName SVGFEFloodElement.height */
  AnimatedLength get height native "SVGFEFloodElement_height_Getter";


  /** @domName SVGFEFloodElement.result */
  AnimatedString get result native "SVGFEFloodElement_result_Getter";


  /** @domName SVGFEFloodElement.width */
  AnimatedLength get width native "SVGFEFloodElement_width_Getter";


  /** @domName SVGFEFloodElement.x */
  AnimatedLength get x native "SVGFEFloodElement_x_Getter";


  /** @domName SVGFEFloodElement.y */
  AnimatedLength get y native "SVGFEFloodElement_y_Getter";


  /** @domName SVGFEFloodElement.className */
  AnimatedString get $dom_svgClassName native "SVGFEFloodElement_className_Getter";


  /** @domName SVGFEFloodElement.style */
  CSSStyleDeclaration get style native "SVGFEFloodElement_style_Getter";


  /** @domName SVGFEFloodElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGFEFloodElement_getPresentationAttribute_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFEFuncAElement
class FEFuncAElement extends ComponentTransferFunctionElement {
  FEFuncAElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFEFuncBElement
class FEFuncBElement extends ComponentTransferFunctionElement {
  FEFuncBElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFEFuncGElement
class FEFuncGElement extends ComponentTransferFunctionElement {
  FEFuncGElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFEFuncRElement
class FEFuncRElement extends ComponentTransferFunctionElement {
  FEFuncRElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFEGaussianBlurElement
class FEGaussianBlurElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  FEGaussianBlurElement.internal(): super.internal();


  /** @domName SVGFEGaussianBlurElement.in1 */
  AnimatedString get in1 native "SVGFEGaussianBlurElement_in1_Getter";


  /** @domName SVGFEGaussianBlurElement.stdDeviationX */
  AnimatedNumber get stdDeviationX native "SVGFEGaussianBlurElement_stdDeviationX_Getter";


  /** @domName SVGFEGaussianBlurElement.stdDeviationY */
  AnimatedNumber get stdDeviationY native "SVGFEGaussianBlurElement_stdDeviationY_Getter";


  /** @domName SVGFEGaussianBlurElement.setStdDeviation */
  void setStdDeviation(num stdDeviationX, num stdDeviationY) native "SVGFEGaussianBlurElement_setStdDeviation_Callback";


  /** @domName SVGFEGaussianBlurElement.height */
  AnimatedLength get height native "SVGFEGaussianBlurElement_height_Getter";


  /** @domName SVGFEGaussianBlurElement.result */
  AnimatedString get result native "SVGFEGaussianBlurElement_result_Getter";


  /** @domName SVGFEGaussianBlurElement.width */
  AnimatedLength get width native "SVGFEGaussianBlurElement_width_Getter";


  /** @domName SVGFEGaussianBlurElement.x */
  AnimatedLength get x native "SVGFEGaussianBlurElement_x_Getter";


  /** @domName SVGFEGaussianBlurElement.y */
  AnimatedLength get y native "SVGFEGaussianBlurElement_y_Getter";


  /** @domName SVGFEGaussianBlurElement.className */
  AnimatedString get $dom_svgClassName native "SVGFEGaussianBlurElement_className_Getter";


  /** @domName SVGFEGaussianBlurElement.style */
  CSSStyleDeclaration get style native "SVGFEGaussianBlurElement_style_Getter";


  /** @domName SVGFEGaussianBlurElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGFEGaussianBlurElement_getPresentationAttribute_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFEImageElement
class FEImageElement extends SvgElement implements FilterPrimitiveStandardAttributes, UriReference, ExternalResourcesRequired, LangSpace {
  FEImageElement.internal(): super.internal();


  /** @domName SVGFEImageElement.preserveAspectRatio */
  AnimatedPreserveAspectRatio get preserveAspectRatio native "SVGFEImageElement_preserveAspectRatio_Getter";


  /** @domName SVGFEImageElement.externalResourcesRequired */
  AnimatedBoolean get externalResourcesRequired native "SVGFEImageElement_externalResourcesRequired_Getter";


  /** @domName SVGFEImageElement.height */
  AnimatedLength get height native "SVGFEImageElement_height_Getter";


  /** @domName SVGFEImageElement.result */
  AnimatedString get result native "SVGFEImageElement_result_Getter";


  /** @domName SVGFEImageElement.width */
  AnimatedLength get width native "SVGFEImageElement_width_Getter";


  /** @domName SVGFEImageElement.x */
  AnimatedLength get x native "SVGFEImageElement_x_Getter";


  /** @domName SVGFEImageElement.y */
  AnimatedLength get y native "SVGFEImageElement_y_Getter";


  /** @domName SVGFEImageElement.xmllang */
  String get xmllang native "SVGFEImageElement_xmllang_Getter";


  /** @domName SVGFEImageElement.xmllang */
  void set xmllang(String value) native "SVGFEImageElement_xmllang_Setter";


  /** @domName SVGFEImageElement.xmlspace */
  String get xmlspace native "SVGFEImageElement_xmlspace_Getter";


  /** @domName SVGFEImageElement.xmlspace */
  void set xmlspace(String value) native "SVGFEImageElement_xmlspace_Setter";


  /** @domName SVGFEImageElement.className */
  AnimatedString get $dom_svgClassName native "SVGFEImageElement_className_Getter";


  /** @domName SVGFEImageElement.style */
  CSSStyleDeclaration get style native "SVGFEImageElement_style_Getter";


  /** @domName SVGFEImageElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGFEImageElement_getPresentationAttribute_Callback";


  /** @domName SVGFEImageElement.href */
  AnimatedString get href native "SVGFEImageElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFEMergeElement
class FEMergeElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  FEMergeElement.internal(): super.internal();


  /** @domName SVGFEMergeElement.height */
  AnimatedLength get height native "SVGFEMergeElement_height_Getter";


  /** @domName SVGFEMergeElement.result */
  AnimatedString get result native "SVGFEMergeElement_result_Getter";


  /** @domName SVGFEMergeElement.width */
  AnimatedLength get width native "SVGFEMergeElement_width_Getter";


  /** @domName SVGFEMergeElement.x */
  AnimatedLength get x native "SVGFEMergeElement_x_Getter";


  /** @domName SVGFEMergeElement.y */
  AnimatedLength get y native "SVGFEMergeElement_y_Getter";


  /** @domName SVGFEMergeElement.className */
  AnimatedString get $dom_svgClassName native "SVGFEMergeElement_className_Getter";


  /** @domName SVGFEMergeElement.style */
  CSSStyleDeclaration get style native "SVGFEMergeElement_style_Getter";


  /** @domName SVGFEMergeElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGFEMergeElement_getPresentationAttribute_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFEMergeNodeElement
class FEMergeNodeElement extends SvgElement {
  FEMergeNodeElement.internal(): super.internal();


  /** @domName SVGFEMergeNodeElement.in1 */
  AnimatedString get in1 native "SVGFEMergeNodeElement_in1_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFEMorphologyElement
class FEMorphologyElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  FEMorphologyElement.internal(): super.internal();

  static const int SVG_MORPHOLOGY_OPERATOR_DILATE = 2;

  static const int SVG_MORPHOLOGY_OPERATOR_ERODE = 1;

  static const int SVG_MORPHOLOGY_OPERATOR_UNKNOWN = 0;


  /** @domName SVGFEMorphologyElement.in1 */
  AnimatedString get in1 native "SVGFEMorphologyElement_in1_Getter";


  /** @domName SVGFEMorphologyElement.operator */
  AnimatedEnumeration get operator native "SVGFEMorphologyElement_operator_Getter";


  /** @domName SVGFEMorphologyElement.radiusX */
  AnimatedNumber get radiusX native "SVGFEMorphologyElement_radiusX_Getter";


  /** @domName SVGFEMorphologyElement.radiusY */
  AnimatedNumber get radiusY native "SVGFEMorphologyElement_radiusY_Getter";


  /** @domName SVGFEMorphologyElement.setRadius */
  void setRadius(num radiusX, num radiusY) native "SVGFEMorphologyElement_setRadius_Callback";


  /** @domName SVGFEMorphologyElement.height */
  AnimatedLength get height native "SVGFEMorphologyElement_height_Getter";


  /** @domName SVGFEMorphologyElement.result */
  AnimatedString get result native "SVGFEMorphologyElement_result_Getter";


  /** @domName SVGFEMorphologyElement.width */
  AnimatedLength get width native "SVGFEMorphologyElement_width_Getter";


  /** @domName SVGFEMorphologyElement.x */
  AnimatedLength get x native "SVGFEMorphologyElement_x_Getter";


  /** @domName SVGFEMorphologyElement.y */
  AnimatedLength get y native "SVGFEMorphologyElement_y_Getter";


  /** @domName SVGFEMorphologyElement.className */
  AnimatedString get $dom_svgClassName native "SVGFEMorphologyElement_className_Getter";


  /** @domName SVGFEMorphologyElement.style */
  CSSStyleDeclaration get style native "SVGFEMorphologyElement_style_Getter";


  /** @domName SVGFEMorphologyElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGFEMorphologyElement_getPresentationAttribute_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFEOffsetElement
class FEOffsetElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  FEOffsetElement.internal(): super.internal();


  /** @domName SVGFEOffsetElement.dx */
  AnimatedNumber get dx native "SVGFEOffsetElement_dx_Getter";


  /** @domName SVGFEOffsetElement.dy */
  AnimatedNumber get dy native "SVGFEOffsetElement_dy_Getter";


  /** @domName SVGFEOffsetElement.in1 */
  AnimatedString get in1 native "SVGFEOffsetElement_in1_Getter";


  /** @domName SVGFEOffsetElement.height */
  AnimatedLength get height native "SVGFEOffsetElement_height_Getter";


  /** @domName SVGFEOffsetElement.result */
  AnimatedString get result native "SVGFEOffsetElement_result_Getter";


  /** @domName SVGFEOffsetElement.width */
  AnimatedLength get width native "SVGFEOffsetElement_width_Getter";


  /** @domName SVGFEOffsetElement.x */
  AnimatedLength get x native "SVGFEOffsetElement_x_Getter";


  /** @domName SVGFEOffsetElement.y */
  AnimatedLength get y native "SVGFEOffsetElement_y_Getter";


  /** @domName SVGFEOffsetElement.className */
  AnimatedString get $dom_svgClassName native "SVGFEOffsetElement_className_Getter";


  /** @domName SVGFEOffsetElement.style */
  CSSStyleDeclaration get style native "SVGFEOffsetElement_style_Getter";


  /** @domName SVGFEOffsetElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGFEOffsetElement_getPresentationAttribute_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFEPointLightElement
class FEPointLightElement extends SvgElement {
  FEPointLightElement.internal(): super.internal();


  /** @domName SVGFEPointLightElement.x */
  AnimatedNumber get x native "SVGFEPointLightElement_x_Getter";


  /** @domName SVGFEPointLightElement.y */
  AnimatedNumber get y native "SVGFEPointLightElement_y_Getter";


  /** @domName SVGFEPointLightElement.z */
  AnimatedNumber get z native "SVGFEPointLightElement_z_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFESpecularLightingElement
class FESpecularLightingElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  FESpecularLightingElement.internal(): super.internal();


  /** @domName SVGFESpecularLightingElement.in1 */
  AnimatedString get in1 native "SVGFESpecularLightingElement_in1_Getter";


  /** @domName SVGFESpecularLightingElement.specularConstant */
  AnimatedNumber get specularConstant native "SVGFESpecularLightingElement_specularConstant_Getter";


  /** @domName SVGFESpecularLightingElement.specularExponent */
  AnimatedNumber get specularExponent native "SVGFESpecularLightingElement_specularExponent_Getter";


  /** @domName SVGFESpecularLightingElement.surfaceScale */
  AnimatedNumber get surfaceScale native "SVGFESpecularLightingElement_surfaceScale_Getter";


  /** @domName SVGFESpecularLightingElement.height */
  AnimatedLength get height native "SVGFESpecularLightingElement_height_Getter";


  /** @domName SVGFESpecularLightingElement.result */
  AnimatedString get result native "SVGFESpecularLightingElement_result_Getter";


  /** @domName SVGFESpecularLightingElement.width */
  AnimatedLength get width native "SVGFESpecularLightingElement_width_Getter";


  /** @domName SVGFESpecularLightingElement.x */
  AnimatedLength get x native "SVGFESpecularLightingElement_x_Getter";


  /** @domName SVGFESpecularLightingElement.y */
  AnimatedLength get y native "SVGFESpecularLightingElement_y_Getter";


  /** @domName SVGFESpecularLightingElement.className */
  AnimatedString get $dom_svgClassName native "SVGFESpecularLightingElement_className_Getter";


  /** @domName SVGFESpecularLightingElement.style */
  CSSStyleDeclaration get style native "SVGFESpecularLightingElement_style_Getter";


  /** @domName SVGFESpecularLightingElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGFESpecularLightingElement_getPresentationAttribute_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFESpotLightElement
class FESpotLightElement extends SvgElement {
  FESpotLightElement.internal(): super.internal();


  /** @domName SVGFESpotLightElement.limitingConeAngle */
  AnimatedNumber get limitingConeAngle native "SVGFESpotLightElement_limitingConeAngle_Getter";


  /** @domName SVGFESpotLightElement.pointsAtX */
  AnimatedNumber get pointsAtX native "SVGFESpotLightElement_pointsAtX_Getter";


  /** @domName SVGFESpotLightElement.pointsAtY */
  AnimatedNumber get pointsAtY native "SVGFESpotLightElement_pointsAtY_Getter";


  /** @domName SVGFESpotLightElement.pointsAtZ */
  AnimatedNumber get pointsAtZ native "SVGFESpotLightElement_pointsAtZ_Getter";


  /** @domName SVGFESpotLightElement.specularExponent */
  AnimatedNumber get specularExponent native "SVGFESpotLightElement_specularExponent_Getter";


  /** @domName SVGFESpotLightElement.x */
  AnimatedNumber get x native "SVGFESpotLightElement_x_Getter";


  /** @domName SVGFESpotLightElement.y */
  AnimatedNumber get y native "SVGFESpotLightElement_y_Getter";


  /** @domName SVGFESpotLightElement.z */
  AnimatedNumber get z native "SVGFESpotLightElement_z_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFETileElement
class FETileElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  FETileElement.internal(): super.internal();


  /** @domName SVGFETileElement.in1 */
  AnimatedString get in1 native "SVGFETileElement_in1_Getter";


  /** @domName SVGFETileElement.height */
  AnimatedLength get height native "SVGFETileElement_height_Getter";


  /** @domName SVGFETileElement.result */
  AnimatedString get result native "SVGFETileElement_result_Getter";


  /** @domName SVGFETileElement.width */
  AnimatedLength get width native "SVGFETileElement_width_Getter";


  /** @domName SVGFETileElement.x */
  AnimatedLength get x native "SVGFETileElement_x_Getter";


  /** @domName SVGFETileElement.y */
  AnimatedLength get y native "SVGFETileElement_y_Getter";


  /** @domName SVGFETileElement.className */
  AnimatedString get $dom_svgClassName native "SVGFETileElement_className_Getter";


  /** @domName SVGFETileElement.style */
  CSSStyleDeclaration get style native "SVGFETileElement_style_Getter";


  /** @domName SVGFETileElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGFETileElement_getPresentationAttribute_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFETurbulenceElement
class FETurbulenceElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  FETurbulenceElement.internal(): super.internal();

  static const int SVG_STITCHTYPE_NOSTITCH = 2;

  static const int SVG_STITCHTYPE_STITCH = 1;

  static const int SVG_STITCHTYPE_UNKNOWN = 0;

  static const int SVG_TURBULENCE_TYPE_FRACTALNOISE = 1;

  static const int SVG_TURBULENCE_TYPE_TURBULENCE = 2;

  static const int SVG_TURBULENCE_TYPE_UNKNOWN = 0;


  /** @domName SVGFETurbulenceElement.baseFrequencyX */
  AnimatedNumber get baseFrequencyX native "SVGFETurbulenceElement_baseFrequencyX_Getter";


  /** @domName SVGFETurbulenceElement.baseFrequencyY */
  AnimatedNumber get baseFrequencyY native "SVGFETurbulenceElement_baseFrequencyY_Getter";


  /** @domName SVGFETurbulenceElement.numOctaves */
  AnimatedInteger get numOctaves native "SVGFETurbulenceElement_numOctaves_Getter";


  /** @domName SVGFETurbulenceElement.seed */
  AnimatedNumber get seed native "SVGFETurbulenceElement_seed_Getter";


  /** @domName SVGFETurbulenceElement.stitchTiles */
  AnimatedEnumeration get stitchTiles native "SVGFETurbulenceElement_stitchTiles_Getter";


  /** @domName SVGFETurbulenceElement.type */
  AnimatedEnumeration get type native "SVGFETurbulenceElement_type_Getter";


  /** @domName SVGFETurbulenceElement.height */
  AnimatedLength get height native "SVGFETurbulenceElement_height_Getter";


  /** @domName SVGFETurbulenceElement.result */
  AnimatedString get result native "SVGFETurbulenceElement_result_Getter";


  /** @domName SVGFETurbulenceElement.width */
  AnimatedLength get width native "SVGFETurbulenceElement_width_Getter";


  /** @domName SVGFETurbulenceElement.x */
  AnimatedLength get x native "SVGFETurbulenceElement_x_Getter";


  /** @domName SVGFETurbulenceElement.y */
  AnimatedLength get y native "SVGFETurbulenceElement_y_Getter";


  /** @domName SVGFETurbulenceElement.className */
  AnimatedString get $dom_svgClassName native "SVGFETurbulenceElement_className_Getter";


  /** @domName SVGFETurbulenceElement.style */
  CSSStyleDeclaration get style native "SVGFETurbulenceElement_style_Getter";


  /** @domName SVGFETurbulenceElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGFETurbulenceElement_getPresentationAttribute_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFilterElement
class FilterElement extends SvgElement implements UriReference, ExternalResourcesRequired, Stylable, LangSpace {

  factory FilterElement() => _SvgElementFactoryProvider.createSvgElement_tag("filter");
  FilterElement.internal(): super.internal();


  /** @domName SVGFilterElement.filterResX */
  AnimatedInteger get filterResX native "SVGFilterElement_filterResX_Getter";


  /** @domName SVGFilterElement.filterResY */
  AnimatedInteger get filterResY native "SVGFilterElement_filterResY_Getter";


  /** @domName SVGFilterElement.filterUnits */
  AnimatedEnumeration get filterUnits native "SVGFilterElement_filterUnits_Getter";


  /** @domName SVGFilterElement.height */
  AnimatedLength get height native "SVGFilterElement_height_Getter";


  /** @domName SVGFilterElement.primitiveUnits */
  AnimatedEnumeration get primitiveUnits native "SVGFilterElement_primitiveUnits_Getter";


  /** @domName SVGFilterElement.width */
  AnimatedLength get width native "SVGFilterElement_width_Getter";


  /** @domName SVGFilterElement.x */
  AnimatedLength get x native "SVGFilterElement_x_Getter";


  /** @domName SVGFilterElement.y */
  AnimatedLength get y native "SVGFilterElement_y_Getter";


  /** @domName SVGFilterElement.setFilterRes */
  void setFilterRes(int filterResX, int filterResY) native "SVGFilterElement_setFilterRes_Callback";


  /** @domName SVGFilterElement.externalResourcesRequired */
  AnimatedBoolean get externalResourcesRequired native "SVGFilterElement_externalResourcesRequired_Getter";


  /** @domName SVGFilterElement.xmllang */
  String get xmllang native "SVGFilterElement_xmllang_Getter";


  /** @domName SVGFilterElement.xmllang */
  void set xmllang(String value) native "SVGFilterElement_xmllang_Setter";


  /** @domName SVGFilterElement.xmlspace */
  String get xmlspace native "SVGFilterElement_xmlspace_Getter";


  /** @domName SVGFilterElement.xmlspace */
  void set xmlspace(String value) native "SVGFilterElement_xmlspace_Setter";


  /** @domName SVGFilterElement.className */
  AnimatedString get $dom_svgClassName native "SVGFilterElement_className_Getter";


  /** @domName SVGFilterElement.style */
  CSSStyleDeclaration get style native "SVGFilterElement_style_Getter";


  /** @domName SVGFilterElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGFilterElement_getPresentationAttribute_Callback";


  /** @domName SVGFilterElement.href */
  AnimatedString get href native "SVGFilterElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFilterPrimitiveStandardAttributes
class FilterPrimitiveStandardAttributes extends NativeFieldWrapperClass1 implements Stylable {
  FilterPrimitiveStandardAttributes.internal();


  /** @domName SVGFilterPrimitiveStandardAttributes.height */
  AnimatedLength get height native "SVGFilterPrimitiveStandardAttributes_height_Getter";


  /** @domName SVGFilterPrimitiveStandardAttributes.result */
  AnimatedString get result native "SVGFilterPrimitiveStandardAttributes_result_Getter";


  /** @domName SVGFilterPrimitiveStandardAttributes.width */
  AnimatedLength get width native "SVGFilterPrimitiveStandardAttributes_width_Getter";


  /** @domName SVGFilterPrimitiveStandardAttributes.x */
  AnimatedLength get x native "SVGFilterPrimitiveStandardAttributes_x_Getter";


  /** @domName SVGFilterPrimitiveStandardAttributes.y */
  AnimatedLength get y native "SVGFilterPrimitiveStandardAttributes_y_Getter";


  /** @domName SVGFilterPrimitiveStandardAttributes.className */
  AnimatedString get $dom_svgClassName native "SVGFilterPrimitiveStandardAttributes_className_Getter";


  /** @domName SVGFilterPrimitiveStandardAttributes.style */
  CSSStyleDeclaration get style native "SVGFilterPrimitiveStandardAttributes_style_Getter";


  /** @domName SVGFilterPrimitiveStandardAttributes.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGFilterPrimitiveStandardAttributes_getPresentationAttribute_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFitToViewBox
class FitToViewBox extends NativeFieldWrapperClass1 {
  FitToViewBox.internal();


  /** @domName SVGFitToViewBox.preserveAspectRatio */
  AnimatedPreserveAspectRatio get preserveAspectRatio native "SVGFitToViewBox_preserveAspectRatio_Getter";


  /** @domName SVGFitToViewBox.viewBox */
  AnimatedRect get viewBox native "SVGFitToViewBox_viewBox_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFontElement
class FontElement extends SvgElement {

  factory FontElement() => _SvgElementFactoryProvider.createSvgElement_tag("font");
  FontElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFontFaceElement
class FontFaceElement extends SvgElement {

  factory FontFaceElement() => _SvgElementFactoryProvider.createSvgElement_tag("font-face");
  FontFaceElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFontFaceFormatElement
class FontFaceFormatElement extends SvgElement {

  factory FontFaceFormatElement() => _SvgElementFactoryProvider.createSvgElement_tag("font-face-format");
  FontFaceFormatElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFontFaceNameElement
class FontFaceNameElement extends SvgElement {

  factory FontFaceNameElement() => _SvgElementFactoryProvider.createSvgElement_tag("font-face-name");
  FontFaceNameElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFontFaceSrcElement
class FontFaceSrcElement extends SvgElement {

  factory FontFaceSrcElement() => _SvgElementFactoryProvider.createSvgElement_tag("font-face-src");
  FontFaceSrcElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFontFaceUriElement
class FontFaceUriElement extends SvgElement {

  factory FontFaceUriElement() => _SvgElementFactoryProvider.createSvgElement_tag("font-face-uri");
  FontFaceUriElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGForeignObjectElement
class ForeignObjectElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace {

  factory ForeignObjectElement() => _SvgElementFactoryProvider.createSvgElement_tag("foreignObject");
  ForeignObjectElement.internal(): super.internal();


  /** @domName SVGForeignObjectElement.height */
  AnimatedLength get height native "SVGForeignObjectElement_height_Getter";


  /** @domName SVGForeignObjectElement.width */
  AnimatedLength get width native "SVGForeignObjectElement_width_Getter";


  /** @domName SVGForeignObjectElement.x */
  AnimatedLength get x native "SVGForeignObjectElement_x_Getter";


  /** @domName SVGForeignObjectElement.y */
  AnimatedLength get y native "SVGForeignObjectElement_y_Getter";


  /** @domName SVGForeignObjectElement.externalResourcesRequired */
  AnimatedBoolean get externalResourcesRequired native "SVGForeignObjectElement_externalResourcesRequired_Getter";


  /** @domName SVGForeignObjectElement.xmllang */
  String get xmllang native "SVGForeignObjectElement_xmllang_Getter";


  /** @domName SVGForeignObjectElement.xmllang */
  void set xmllang(String value) native "SVGForeignObjectElement_xmllang_Setter";


  /** @domName SVGForeignObjectElement.xmlspace */
  String get xmlspace native "SVGForeignObjectElement_xmlspace_Getter";


  /** @domName SVGForeignObjectElement.xmlspace */
  void set xmlspace(String value) native "SVGForeignObjectElement_xmlspace_Setter";


  /** @domName SVGForeignObjectElement.farthestViewportElement */
  SvgElement get farthestViewportElement native "SVGForeignObjectElement_farthestViewportElement_Getter";


  /** @domName SVGForeignObjectElement.nearestViewportElement */
  SvgElement get nearestViewportElement native "SVGForeignObjectElement_nearestViewportElement_Getter";


  /** @domName SVGForeignObjectElement.getBBox */
  Rect getBBox() native "SVGForeignObjectElement_getBBox_Callback";


  /** @domName SVGForeignObjectElement.getCTM */
  Matrix getCtm() native "SVGForeignObjectElement_getCTM_Callback";


  /** @domName SVGForeignObjectElement.getScreenCTM */
  Matrix getScreenCtm() native "SVGForeignObjectElement_getScreenCTM_Callback";


  /** @domName SVGForeignObjectElement.getTransformToElement */
  Matrix getTransformToElement(SvgElement element) native "SVGForeignObjectElement_getTransformToElement_Callback";


  /** @domName SVGForeignObjectElement.className */
  AnimatedString get $dom_svgClassName native "SVGForeignObjectElement_className_Getter";


  /** @domName SVGForeignObjectElement.style */
  CSSStyleDeclaration get style native "SVGForeignObjectElement_style_Getter";


  /** @domName SVGForeignObjectElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGForeignObjectElement_getPresentationAttribute_Callback";


  /** @domName SVGForeignObjectElement.requiredExtensions */
  StringList get requiredExtensions native "SVGForeignObjectElement_requiredExtensions_Getter";


  /** @domName SVGForeignObjectElement.requiredFeatures */
  StringList get requiredFeatures native "SVGForeignObjectElement_requiredFeatures_Getter";


  /** @domName SVGForeignObjectElement.systemLanguage */
  StringList get systemLanguage native "SVGForeignObjectElement_systemLanguage_Getter";


  /** @domName SVGForeignObjectElement.hasExtension */
  bool hasExtension(String extension) native "SVGForeignObjectElement_hasExtension_Callback";


  /** @domName SVGForeignObjectElement.transform */
  AnimatedTransformList get transform native "SVGForeignObjectElement_transform_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGGElement
class GElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace {

  factory GElement() => _SvgElementFactoryProvider.createSvgElement_tag("g");
  GElement.internal(): super.internal();


  /** @domName SVGGElement.externalResourcesRequired */
  AnimatedBoolean get externalResourcesRequired native "SVGGElement_externalResourcesRequired_Getter";


  /** @domName SVGGElement.xmllang */
  String get xmllang native "SVGGElement_xmllang_Getter";


  /** @domName SVGGElement.xmllang */
  void set xmllang(String value) native "SVGGElement_xmllang_Setter";


  /** @domName SVGGElement.xmlspace */
  String get xmlspace native "SVGGElement_xmlspace_Getter";


  /** @domName SVGGElement.xmlspace */
  void set xmlspace(String value) native "SVGGElement_xmlspace_Setter";


  /** @domName SVGGElement.farthestViewportElement */
  SvgElement get farthestViewportElement native "SVGGElement_farthestViewportElement_Getter";


  /** @domName SVGGElement.nearestViewportElement */
  SvgElement get nearestViewportElement native "SVGGElement_nearestViewportElement_Getter";


  /** @domName SVGGElement.getBBox */
  Rect getBBox() native "SVGGElement_getBBox_Callback";


  /** @domName SVGGElement.getCTM */
  Matrix getCtm() native "SVGGElement_getCTM_Callback";


  /** @domName SVGGElement.getScreenCTM */
  Matrix getScreenCtm() native "SVGGElement_getScreenCTM_Callback";


  /** @domName SVGGElement.getTransformToElement */
  Matrix getTransformToElement(SvgElement element) native "SVGGElement_getTransformToElement_Callback";


  /** @domName SVGGElement.className */
  AnimatedString get $dom_svgClassName native "SVGGElement_className_Getter";


  /** @domName SVGGElement.style */
  CSSStyleDeclaration get style native "SVGGElement_style_Getter";


  /** @domName SVGGElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGGElement_getPresentationAttribute_Callback";


  /** @domName SVGGElement.requiredExtensions */
  StringList get requiredExtensions native "SVGGElement_requiredExtensions_Getter";


  /** @domName SVGGElement.requiredFeatures */
  StringList get requiredFeatures native "SVGGElement_requiredFeatures_Getter";


  /** @domName SVGGElement.systemLanguage */
  StringList get systemLanguage native "SVGGElement_systemLanguage_Getter";


  /** @domName SVGGElement.hasExtension */
  bool hasExtension(String extension) native "SVGGElement_hasExtension_Callback";


  /** @domName SVGGElement.transform */
  AnimatedTransformList get transform native "SVGGElement_transform_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGGlyphElement
class GlyphElement extends SvgElement {

  factory GlyphElement() => _SvgElementFactoryProvider.createSvgElement_tag("glyph");
  GlyphElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGGlyphRefElement
class GlyphRefElement extends SvgElement implements UriReference, Stylable {
  GlyphRefElement.internal(): super.internal();


  /** @domName SVGGlyphRefElement.dx */
  num get dx native "SVGGlyphRefElement_dx_Getter";


  /** @domName SVGGlyphRefElement.dx */
  void set dx(num value) native "SVGGlyphRefElement_dx_Setter";


  /** @domName SVGGlyphRefElement.dy */
  num get dy native "SVGGlyphRefElement_dy_Getter";


  /** @domName SVGGlyphRefElement.dy */
  void set dy(num value) native "SVGGlyphRefElement_dy_Setter";


  /** @domName SVGGlyphRefElement.format */
  String get format native "SVGGlyphRefElement_format_Getter";


  /** @domName SVGGlyphRefElement.format */
  void set format(String value) native "SVGGlyphRefElement_format_Setter";


  /** @domName SVGGlyphRefElement.glyphRef */
  String get glyphRef native "SVGGlyphRefElement_glyphRef_Getter";


  /** @domName SVGGlyphRefElement.glyphRef */
  void set glyphRef(String value) native "SVGGlyphRefElement_glyphRef_Setter";


  /** @domName SVGGlyphRefElement.x */
  num get x native "SVGGlyphRefElement_x_Getter";


  /** @domName SVGGlyphRefElement.x */
  void set x(num value) native "SVGGlyphRefElement_x_Setter";


  /** @domName SVGGlyphRefElement.y */
  num get y native "SVGGlyphRefElement_y_Getter";


  /** @domName SVGGlyphRefElement.y */
  void set y(num value) native "SVGGlyphRefElement_y_Setter";


  /** @domName SVGGlyphRefElement.className */
  AnimatedString get $dom_svgClassName native "SVGGlyphRefElement_className_Getter";


  /** @domName SVGGlyphRefElement.style */
  CSSStyleDeclaration get style native "SVGGlyphRefElement_style_Getter";


  /** @domName SVGGlyphRefElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGGlyphRefElement_getPresentationAttribute_Callback";


  /** @domName SVGGlyphRefElement.href */
  AnimatedString get href native "SVGGlyphRefElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGGradientElement
class GradientElement extends SvgElement implements UriReference, ExternalResourcesRequired, Stylable {
  GradientElement.internal(): super.internal();

  static const int SVG_SPREADMETHOD_PAD = 1;

  static const int SVG_SPREADMETHOD_REFLECT = 2;

  static const int SVG_SPREADMETHOD_REPEAT = 3;

  static const int SVG_SPREADMETHOD_UNKNOWN = 0;


  /** @domName SVGGradientElement.gradientTransform */
  AnimatedTransformList get gradientTransform native "SVGGradientElement_gradientTransform_Getter";


  /** @domName SVGGradientElement.gradientUnits */
  AnimatedEnumeration get gradientUnits native "SVGGradientElement_gradientUnits_Getter";


  /** @domName SVGGradientElement.spreadMethod */
  AnimatedEnumeration get spreadMethod native "SVGGradientElement_spreadMethod_Getter";


  /** @domName SVGGradientElement.externalResourcesRequired */
  AnimatedBoolean get externalResourcesRequired native "SVGGradientElement_externalResourcesRequired_Getter";


  /** @domName SVGGradientElement.className */
  AnimatedString get $dom_svgClassName native "SVGGradientElement_className_Getter";


  /** @domName SVGGradientElement.style */
  CSSStyleDeclaration get style native "SVGGradientElement_style_Getter";


  /** @domName SVGGradientElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGGradientElement_getPresentationAttribute_Callback";


  /** @domName SVGGradientElement.href */
  AnimatedString get href native "SVGGradientElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGHKernElement
class HKernElement extends SvgElement {

  factory HKernElement() => _SvgElementFactoryProvider.createSvgElement_tag("hkern");
  HKernElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGImageElement
class ImageElement extends SvgElement implements Transformable, Tests, UriReference, Stylable, ExternalResourcesRequired, LangSpace {

  factory ImageElement() => _SvgElementFactoryProvider.createSvgElement_tag("image");
  ImageElement.internal(): super.internal();


  /** @domName SVGImageElement.height */
  AnimatedLength get height native "SVGImageElement_height_Getter";


  /** @domName SVGImageElement.preserveAspectRatio */
  AnimatedPreserveAspectRatio get preserveAspectRatio native "SVGImageElement_preserveAspectRatio_Getter";


  /** @domName SVGImageElement.width */
  AnimatedLength get width native "SVGImageElement_width_Getter";


  /** @domName SVGImageElement.x */
  AnimatedLength get x native "SVGImageElement_x_Getter";


  /** @domName SVGImageElement.y */
  AnimatedLength get y native "SVGImageElement_y_Getter";


  /** @domName SVGImageElement.externalResourcesRequired */
  AnimatedBoolean get externalResourcesRequired native "SVGImageElement_externalResourcesRequired_Getter";


  /** @domName SVGImageElement.xmllang */
  String get xmllang native "SVGImageElement_xmllang_Getter";


  /** @domName SVGImageElement.xmllang */
  void set xmllang(String value) native "SVGImageElement_xmllang_Setter";


  /** @domName SVGImageElement.xmlspace */
  String get xmlspace native "SVGImageElement_xmlspace_Getter";


  /** @domName SVGImageElement.xmlspace */
  void set xmlspace(String value) native "SVGImageElement_xmlspace_Setter";


  /** @domName SVGImageElement.farthestViewportElement */
  SvgElement get farthestViewportElement native "SVGImageElement_farthestViewportElement_Getter";


  /** @domName SVGImageElement.nearestViewportElement */
  SvgElement get nearestViewportElement native "SVGImageElement_nearestViewportElement_Getter";


  /** @domName SVGImageElement.getBBox */
  Rect getBBox() native "SVGImageElement_getBBox_Callback";


  /** @domName SVGImageElement.getCTM */
  Matrix getCtm() native "SVGImageElement_getCTM_Callback";


  /** @domName SVGImageElement.getScreenCTM */
  Matrix getScreenCtm() native "SVGImageElement_getScreenCTM_Callback";


  /** @domName SVGImageElement.getTransformToElement */
  Matrix getTransformToElement(SvgElement element) native "SVGImageElement_getTransformToElement_Callback";


  /** @domName SVGImageElement.className */
  AnimatedString get $dom_svgClassName native "SVGImageElement_className_Getter";


  /** @domName SVGImageElement.style */
  CSSStyleDeclaration get style native "SVGImageElement_style_Getter";


  /** @domName SVGImageElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGImageElement_getPresentationAttribute_Callback";


  /** @domName SVGImageElement.requiredExtensions */
  StringList get requiredExtensions native "SVGImageElement_requiredExtensions_Getter";


  /** @domName SVGImageElement.requiredFeatures */
  StringList get requiredFeatures native "SVGImageElement_requiredFeatures_Getter";


  /** @domName SVGImageElement.systemLanguage */
  StringList get systemLanguage native "SVGImageElement_systemLanguage_Getter";


  /** @domName SVGImageElement.hasExtension */
  bool hasExtension(String extension) native "SVGImageElement_hasExtension_Callback";


  /** @domName SVGImageElement.transform */
  AnimatedTransformList get transform native "SVGImageElement_transform_Getter";


  /** @domName SVGImageElement.href */
  AnimatedString get href native "SVGImageElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGLangSpace
class LangSpace extends NativeFieldWrapperClass1 {
  LangSpace.internal();


  /** @domName SVGLangSpace.xmllang */
  String get xmllang native "SVGLangSpace_xmllang_Getter";


  /** @domName SVGLangSpace.xmllang */
  void set xmllang(String value) native "SVGLangSpace_xmllang_Setter";


  /** @domName SVGLangSpace.xmlspace */
  String get xmlspace native "SVGLangSpace_xmlspace_Getter";


  /** @domName SVGLangSpace.xmlspace */
  void set xmlspace(String value) native "SVGLangSpace_xmlspace_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGLength
class Length extends NativeFieldWrapperClass1 {
  Length.internal();

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
  int get unitType native "SVGLength_unitType_Getter";


  /** @domName SVGLength.value */
  num get value native "SVGLength_value_Getter";


  /** @domName SVGLength.value */
  void set value(num value) native "SVGLength_value_Setter";


  /** @domName SVGLength.valueAsString */
  String get valueAsString native "SVGLength_valueAsString_Getter";


  /** @domName SVGLength.valueAsString */
  void set valueAsString(String value) native "SVGLength_valueAsString_Setter";


  /** @domName SVGLength.valueInSpecifiedUnits */
  num get valueInSpecifiedUnits native "SVGLength_valueInSpecifiedUnits_Getter";


  /** @domName SVGLength.valueInSpecifiedUnits */
  void set valueInSpecifiedUnits(num value) native "SVGLength_valueInSpecifiedUnits_Setter";


  /** @domName SVGLength.convertToSpecifiedUnits */
  void convertToSpecifiedUnits(int unitType) native "SVGLength_convertToSpecifiedUnits_Callback";


  /** @domName SVGLength.newValueSpecifiedUnits */
  void newValueSpecifiedUnits(int unitType, num valueInSpecifiedUnits) native "SVGLength_newValueSpecifiedUnits_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGLengthList
class LengthList extends NativeFieldWrapperClass1 implements List<Length> {
  LengthList.internal();


  /** @domName SVGLengthList.numberOfItems */
  int get numberOfItems native "SVGLengthList_numberOfItems_Getter";

  Length operator[](int index) native "SVGLengthList_item_Callback";

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

  bool contains(Length element) => Collections.contains(this, element);

  void forEach(void f(Length element)) => Collections.forEach(this, f);

  Collection map(f(Length element)) => Collections.map(this, [], f);

  Collection<Length> filter(bool f(Length element)) =>
     Collections.filter(this, <Length>[], f);

  bool every(bool f(Length element)) => Collections.every(this, f);

  bool some(bool f(Length element)) => Collections.some(this, f);

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
  Length appendItem(Length item) native "SVGLengthList_appendItem_Callback";


  /** @domName SVGLengthList.clear */
  void clear() native "SVGLengthList_clear_Callback";


  /** @domName SVGLengthList.getItem */
  Length getItem(int index) native "SVGLengthList_getItem_Callback";


  /** @domName SVGLengthList.initialize */
  Length initialize(Length item) native "SVGLengthList_initialize_Callback";


  /** @domName SVGLengthList.insertItemBefore */
  Length insertItemBefore(Length item, int index) native "SVGLengthList_insertItemBefore_Callback";


  /** @domName SVGLengthList.removeItem */
  Length removeItem(int index) native "SVGLengthList_removeItem_Callback";


  /** @domName SVGLengthList.replaceItem */
  Length replaceItem(Length item, int index) native "SVGLengthList_replaceItem_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGLineElement
class LineElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace {

  factory LineElement() => _SvgElementFactoryProvider.createSvgElement_tag("line");
  LineElement.internal(): super.internal();


  /** @domName SVGLineElement.x1 */
  AnimatedLength get x1 native "SVGLineElement_x1_Getter";


  /** @domName SVGLineElement.x2 */
  AnimatedLength get x2 native "SVGLineElement_x2_Getter";


  /** @domName SVGLineElement.y1 */
  AnimatedLength get y1 native "SVGLineElement_y1_Getter";


  /** @domName SVGLineElement.y2 */
  AnimatedLength get y2 native "SVGLineElement_y2_Getter";


  /** @domName SVGLineElement.externalResourcesRequired */
  AnimatedBoolean get externalResourcesRequired native "SVGLineElement_externalResourcesRequired_Getter";


  /** @domName SVGLineElement.xmllang */
  String get xmllang native "SVGLineElement_xmllang_Getter";


  /** @domName SVGLineElement.xmllang */
  void set xmllang(String value) native "SVGLineElement_xmllang_Setter";


  /** @domName SVGLineElement.xmlspace */
  String get xmlspace native "SVGLineElement_xmlspace_Getter";


  /** @domName SVGLineElement.xmlspace */
  void set xmlspace(String value) native "SVGLineElement_xmlspace_Setter";


  /** @domName SVGLineElement.farthestViewportElement */
  SvgElement get farthestViewportElement native "SVGLineElement_farthestViewportElement_Getter";


  /** @domName SVGLineElement.nearestViewportElement */
  SvgElement get nearestViewportElement native "SVGLineElement_nearestViewportElement_Getter";


  /** @domName SVGLineElement.getBBox */
  Rect getBBox() native "SVGLineElement_getBBox_Callback";


  /** @domName SVGLineElement.getCTM */
  Matrix getCtm() native "SVGLineElement_getCTM_Callback";


  /** @domName SVGLineElement.getScreenCTM */
  Matrix getScreenCtm() native "SVGLineElement_getScreenCTM_Callback";


  /** @domName SVGLineElement.getTransformToElement */
  Matrix getTransformToElement(SvgElement element) native "SVGLineElement_getTransformToElement_Callback";


  /** @domName SVGLineElement.className */
  AnimatedString get $dom_svgClassName native "SVGLineElement_className_Getter";


  /** @domName SVGLineElement.style */
  CSSStyleDeclaration get style native "SVGLineElement_style_Getter";


  /** @domName SVGLineElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGLineElement_getPresentationAttribute_Callback";


  /** @domName SVGLineElement.requiredExtensions */
  StringList get requiredExtensions native "SVGLineElement_requiredExtensions_Getter";


  /** @domName SVGLineElement.requiredFeatures */
  StringList get requiredFeatures native "SVGLineElement_requiredFeatures_Getter";


  /** @domName SVGLineElement.systemLanguage */
  StringList get systemLanguage native "SVGLineElement_systemLanguage_Getter";


  /** @domName SVGLineElement.hasExtension */
  bool hasExtension(String extension) native "SVGLineElement_hasExtension_Callback";


  /** @domName SVGLineElement.transform */
  AnimatedTransformList get transform native "SVGLineElement_transform_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGLinearGradientElement
class LinearGradientElement extends GradientElement {

  factory LinearGradientElement() => _SvgElementFactoryProvider.createSvgElement_tag("linearGradient");
  LinearGradientElement.internal(): super.internal();


  /** @domName SVGLinearGradientElement.x1 */
  AnimatedLength get x1 native "SVGLinearGradientElement_x1_Getter";


  /** @domName SVGLinearGradientElement.x2 */
  AnimatedLength get x2 native "SVGLinearGradientElement_x2_Getter";


  /** @domName SVGLinearGradientElement.y1 */
  AnimatedLength get y1 native "SVGLinearGradientElement_y1_Getter";


  /** @domName SVGLinearGradientElement.y2 */
  AnimatedLength get y2 native "SVGLinearGradientElement_y2_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGLocatable
class Locatable extends NativeFieldWrapperClass1 {
  Locatable.internal();


  /** @domName SVGLocatable.farthestViewportElement */
  SvgElement get farthestViewportElement native "SVGLocatable_farthestViewportElement_Getter";


  /** @domName SVGLocatable.nearestViewportElement */
  SvgElement get nearestViewportElement native "SVGLocatable_nearestViewportElement_Getter";


  /** @domName SVGLocatable.getBBox */
  Rect getBBox() native "SVGLocatable_getBBox_Callback";


  /** @domName SVGLocatable.getCTM */
  Matrix getCtm() native "SVGLocatable_getCTM_Callback";


  /** @domName SVGLocatable.getScreenCTM */
  Matrix getScreenCtm() native "SVGLocatable_getScreenCTM_Callback";


  /** @domName SVGLocatable.getTransformToElement */
  Matrix getTransformToElement(SvgElement element) native "SVGLocatable_getTransformToElement_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGMPathElement
class MPathElement extends SvgElement implements UriReference, ExternalResourcesRequired {

  factory MPathElement() => _SvgElementFactoryProvider.createSvgElement_tag("mpath");
  MPathElement.internal(): super.internal();


  /** @domName SVGMPathElement.externalResourcesRequired */
  AnimatedBoolean get externalResourcesRequired native "SVGMPathElement_externalResourcesRequired_Getter";


  /** @domName SVGMPathElement.href */
  AnimatedString get href native "SVGMPathElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGMarkerElement
class MarkerElement extends SvgElement implements FitToViewBox, ExternalResourcesRequired, Stylable, LangSpace {

  factory MarkerElement() => _SvgElementFactoryProvider.createSvgElement_tag("marker");
  MarkerElement.internal(): super.internal();

  static const int SVG_MARKERUNITS_STROKEWIDTH = 2;

  static const int SVG_MARKERUNITS_UNKNOWN = 0;

  static const int SVG_MARKERUNITS_USERSPACEONUSE = 1;

  static const int SVG_MARKER_ORIENT_ANGLE = 2;

  static const int SVG_MARKER_ORIENT_AUTO = 1;

  static const int SVG_MARKER_ORIENT_UNKNOWN = 0;


  /** @domName SVGMarkerElement.markerHeight */
  AnimatedLength get markerHeight native "SVGMarkerElement_markerHeight_Getter";


  /** @domName SVGMarkerElement.markerUnits */
  AnimatedEnumeration get markerUnits native "SVGMarkerElement_markerUnits_Getter";


  /** @domName SVGMarkerElement.markerWidth */
  AnimatedLength get markerWidth native "SVGMarkerElement_markerWidth_Getter";


  /** @domName SVGMarkerElement.orientAngle */
  AnimatedAngle get orientAngle native "SVGMarkerElement_orientAngle_Getter";


  /** @domName SVGMarkerElement.orientType */
  AnimatedEnumeration get orientType native "SVGMarkerElement_orientType_Getter";


  /** @domName SVGMarkerElement.refX */
  AnimatedLength get refX native "SVGMarkerElement_refX_Getter";


  /** @domName SVGMarkerElement.refY */
  AnimatedLength get refY native "SVGMarkerElement_refY_Getter";


  /** @domName SVGMarkerElement.setOrientToAngle */
  void setOrientToAngle(Angle angle) native "SVGMarkerElement_setOrientToAngle_Callback";


  /** @domName SVGMarkerElement.setOrientToAuto */
  void setOrientToAuto() native "SVGMarkerElement_setOrientToAuto_Callback";


  /** @domName SVGMarkerElement.externalResourcesRequired */
  AnimatedBoolean get externalResourcesRequired native "SVGMarkerElement_externalResourcesRequired_Getter";


  /** @domName SVGMarkerElement.preserveAspectRatio */
  AnimatedPreserveAspectRatio get preserveAspectRatio native "SVGMarkerElement_preserveAspectRatio_Getter";


  /** @domName SVGMarkerElement.viewBox */
  AnimatedRect get viewBox native "SVGMarkerElement_viewBox_Getter";


  /** @domName SVGMarkerElement.xmllang */
  String get xmllang native "SVGMarkerElement_xmllang_Getter";


  /** @domName SVGMarkerElement.xmllang */
  void set xmllang(String value) native "SVGMarkerElement_xmllang_Setter";


  /** @domName SVGMarkerElement.xmlspace */
  String get xmlspace native "SVGMarkerElement_xmlspace_Getter";


  /** @domName SVGMarkerElement.xmlspace */
  void set xmlspace(String value) native "SVGMarkerElement_xmlspace_Setter";


  /** @domName SVGMarkerElement.className */
  AnimatedString get $dom_svgClassName native "SVGMarkerElement_className_Getter";


  /** @domName SVGMarkerElement.style */
  CSSStyleDeclaration get style native "SVGMarkerElement_style_Getter";


  /** @domName SVGMarkerElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGMarkerElement_getPresentationAttribute_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGMaskElement
class MaskElement extends SvgElement implements Tests, Stylable, ExternalResourcesRequired, LangSpace {

  factory MaskElement() => _SvgElementFactoryProvider.createSvgElement_tag("mask");
  MaskElement.internal(): super.internal();


  /** @domName SVGMaskElement.height */
  AnimatedLength get height native "SVGMaskElement_height_Getter";


  /** @domName SVGMaskElement.maskContentUnits */
  AnimatedEnumeration get maskContentUnits native "SVGMaskElement_maskContentUnits_Getter";


  /** @domName SVGMaskElement.maskUnits */
  AnimatedEnumeration get maskUnits native "SVGMaskElement_maskUnits_Getter";


  /** @domName SVGMaskElement.width */
  AnimatedLength get width native "SVGMaskElement_width_Getter";


  /** @domName SVGMaskElement.x */
  AnimatedLength get x native "SVGMaskElement_x_Getter";


  /** @domName SVGMaskElement.y */
  AnimatedLength get y native "SVGMaskElement_y_Getter";


  /** @domName SVGMaskElement.externalResourcesRequired */
  AnimatedBoolean get externalResourcesRequired native "SVGMaskElement_externalResourcesRequired_Getter";


  /** @domName SVGMaskElement.xmllang */
  String get xmllang native "SVGMaskElement_xmllang_Getter";


  /** @domName SVGMaskElement.xmllang */
  void set xmllang(String value) native "SVGMaskElement_xmllang_Setter";


  /** @domName SVGMaskElement.xmlspace */
  String get xmlspace native "SVGMaskElement_xmlspace_Getter";


  /** @domName SVGMaskElement.xmlspace */
  void set xmlspace(String value) native "SVGMaskElement_xmlspace_Setter";


  /** @domName SVGMaskElement.className */
  AnimatedString get $dom_svgClassName native "SVGMaskElement_className_Getter";


  /** @domName SVGMaskElement.style */
  CSSStyleDeclaration get style native "SVGMaskElement_style_Getter";


  /** @domName SVGMaskElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGMaskElement_getPresentationAttribute_Callback";


  /** @domName SVGMaskElement.requiredExtensions */
  StringList get requiredExtensions native "SVGMaskElement_requiredExtensions_Getter";


  /** @domName SVGMaskElement.requiredFeatures */
  StringList get requiredFeatures native "SVGMaskElement_requiredFeatures_Getter";


  /** @domName SVGMaskElement.systemLanguage */
  StringList get systemLanguage native "SVGMaskElement_systemLanguage_Getter";


  /** @domName SVGMaskElement.hasExtension */
  bool hasExtension(String extension) native "SVGMaskElement_hasExtension_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGMatrix
class Matrix extends NativeFieldWrapperClass1 {
  Matrix.internal();


  /** @domName SVGMatrix.a */
  num get a native "SVGMatrix_a_Getter";


  /** @domName SVGMatrix.a */
  void set a(num value) native "SVGMatrix_a_Setter";


  /** @domName SVGMatrix.b */
  num get b native "SVGMatrix_b_Getter";


  /** @domName SVGMatrix.b */
  void set b(num value) native "SVGMatrix_b_Setter";


  /** @domName SVGMatrix.c */
  num get c native "SVGMatrix_c_Getter";


  /** @domName SVGMatrix.c */
  void set c(num value) native "SVGMatrix_c_Setter";


  /** @domName SVGMatrix.d */
  num get d native "SVGMatrix_d_Getter";


  /** @domName SVGMatrix.d */
  void set d(num value) native "SVGMatrix_d_Setter";


  /** @domName SVGMatrix.e */
  num get e native "SVGMatrix_e_Getter";


  /** @domName SVGMatrix.e */
  void set e(num value) native "SVGMatrix_e_Setter";


  /** @domName SVGMatrix.f */
  num get f native "SVGMatrix_f_Getter";


  /** @domName SVGMatrix.f */
  void set f(num value) native "SVGMatrix_f_Setter";


  /** @domName SVGMatrix.flipX */
  Matrix flipX() native "SVGMatrix_flipX_Callback";


  /** @domName SVGMatrix.flipY */
  Matrix flipY() native "SVGMatrix_flipY_Callback";


  /** @domName SVGMatrix.inverse */
  Matrix inverse() native "SVGMatrix_inverse_Callback";


  /** @domName SVGMatrix.multiply */
  Matrix multiply(Matrix secondMatrix) native "SVGMatrix_multiply_Callback";


  /** @domName SVGMatrix.rotate */
  Matrix rotate(num angle) native "SVGMatrix_rotate_Callback";


  /** @domName SVGMatrix.rotateFromVector */
  Matrix rotateFromVector(num x, num y) native "SVGMatrix_rotateFromVector_Callback";


  /** @domName SVGMatrix.scale */
  Matrix scale(num scaleFactor) native "SVGMatrix_scale_Callback";


  /** @domName SVGMatrix.scaleNonUniform */
  Matrix scaleNonUniform(num scaleFactorX, num scaleFactorY) native "SVGMatrix_scaleNonUniform_Callback";


  /** @domName SVGMatrix.skewX */
  Matrix skewX(num angle) native "SVGMatrix_skewX_Callback";


  /** @domName SVGMatrix.skewY */
  Matrix skewY(num angle) native "SVGMatrix_skewY_Callback";


  /** @domName SVGMatrix.translate */
  Matrix translate(num x, num y) native "SVGMatrix_translate_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGMetadataElement
class MetadataElement extends SvgElement {
  MetadataElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGMissingGlyphElement
class MissingGlyphElement extends SvgElement {
  MissingGlyphElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGNumber
class Number extends NativeFieldWrapperClass1 {
  Number.internal();


  /** @domName SVGNumber.value */
  num get value native "SVGNumber_value_Getter";


  /** @domName SVGNumber.value */
  void set value(num value) native "SVGNumber_value_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGNumberList
class NumberList extends NativeFieldWrapperClass1 implements List<Number> {
  NumberList.internal();


  /** @domName SVGNumberList.numberOfItems */
  int get numberOfItems native "SVGNumberList_numberOfItems_Getter";

  Number operator[](int index) native "SVGNumberList_item_Callback";

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

  bool contains(Number element) => Collections.contains(this, element);

  void forEach(void f(Number element)) => Collections.forEach(this, f);

  Collection map(f(Number element)) => Collections.map(this, [], f);

  Collection<Number> filter(bool f(Number element)) =>
     Collections.filter(this, <Number>[], f);

  bool every(bool f(Number element)) => Collections.every(this, f);

  bool some(bool f(Number element)) => Collections.some(this, f);

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
  Number appendItem(Number item) native "SVGNumberList_appendItem_Callback";


  /** @domName SVGNumberList.clear */
  void clear() native "SVGNumberList_clear_Callback";


  /** @domName SVGNumberList.getItem */
  Number getItem(int index) native "SVGNumberList_getItem_Callback";


  /** @domName SVGNumberList.initialize */
  Number initialize(Number item) native "SVGNumberList_initialize_Callback";


  /** @domName SVGNumberList.insertItemBefore */
  Number insertItemBefore(Number item, int index) native "SVGNumberList_insertItemBefore_Callback";


  /** @domName SVGNumberList.removeItem */
  Number removeItem(int index) native "SVGNumberList_removeItem_Callback";


  /** @domName SVGNumberList.replaceItem */
  Number replaceItem(Number item, int index) native "SVGNumberList_replaceItem_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGPaint
class Paint extends Color {
  Paint.internal(): super.internal();

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
  int get paintType native "SVGPaint_paintType_Getter";


  /** @domName SVGPaint.uri */
  String get uri native "SVGPaint_uri_Getter";


  /** @domName SVGPaint.setPaint */
  void setPaint(int paintType, String uri, String rgbColor, String iccColor) native "SVGPaint_setPaint_Callback";


  /** @domName SVGPaint.setUri */
  void setUri(String uri) native "SVGPaint_setUri_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGPathElement
class PathElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace {

  factory PathElement() => _SvgElementFactoryProvider.createSvgElement_tag("path");
  PathElement.internal(): super.internal();


  /** @domName SVGPathElement.animatedNormalizedPathSegList */
  PathSegList get animatedNormalizedPathSegList native "SVGPathElement_animatedNormalizedPathSegList_Getter";


  /** @domName SVGPathElement.animatedPathSegList */
  PathSegList get animatedPathSegList native "SVGPathElement_animatedPathSegList_Getter";


  /** @domName SVGPathElement.normalizedPathSegList */
  PathSegList get normalizedPathSegList native "SVGPathElement_normalizedPathSegList_Getter";


  /** @domName SVGPathElement.pathLength */
  AnimatedNumber get pathLength native "SVGPathElement_pathLength_Getter";


  /** @domName SVGPathElement.pathSegList */
  PathSegList get pathSegList native "SVGPathElement_pathSegList_Getter";


  /** @domName SVGPathElement.createSVGPathSegArcAbs */
  PathSegArcAbs createSvgPathSegArcAbs(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) native "SVGPathElement_createSVGPathSegArcAbs_Callback";


  /** @domName SVGPathElement.createSVGPathSegArcRel */
  PathSegArcRel createSvgPathSegArcRel(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) native "SVGPathElement_createSVGPathSegArcRel_Callback";


  /** @domName SVGPathElement.createSVGPathSegClosePath */
  PathSegClosePath createSvgPathSegClosePath() native "SVGPathElement_createSVGPathSegClosePath_Callback";


  /** @domName SVGPathElement.createSVGPathSegCurvetoCubicAbs */
  PathSegCurvetoCubicAbs createSvgPathSegCurvetoCubicAbs(num x, num y, num x1, num y1, num x2, num y2) native "SVGPathElement_createSVGPathSegCurvetoCubicAbs_Callback";


  /** @domName SVGPathElement.createSVGPathSegCurvetoCubicRel */
  PathSegCurvetoCubicRel createSvgPathSegCurvetoCubicRel(num x, num y, num x1, num y1, num x2, num y2) native "SVGPathElement_createSVGPathSegCurvetoCubicRel_Callback";


  /** @domName SVGPathElement.createSVGPathSegCurvetoCubicSmoothAbs */
  PathSegCurvetoCubicSmoothAbs createSvgPathSegCurvetoCubicSmoothAbs(num x, num y, num x2, num y2) native "SVGPathElement_createSVGPathSegCurvetoCubicSmoothAbs_Callback";


  /** @domName SVGPathElement.createSVGPathSegCurvetoCubicSmoothRel */
  PathSegCurvetoCubicSmoothRel createSvgPathSegCurvetoCubicSmoothRel(num x, num y, num x2, num y2) native "SVGPathElement_createSVGPathSegCurvetoCubicSmoothRel_Callback";


  /** @domName SVGPathElement.createSVGPathSegCurvetoQuadraticAbs */
  PathSegCurvetoQuadraticAbs createSvgPathSegCurvetoQuadraticAbs(num x, num y, num x1, num y1) native "SVGPathElement_createSVGPathSegCurvetoQuadraticAbs_Callback";


  /** @domName SVGPathElement.createSVGPathSegCurvetoQuadraticRel */
  PathSegCurvetoQuadraticRel createSvgPathSegCurvetoQuadraticRel(num x, num y, num x1, num y1) native "SVGPathElement_createSVGPathSegCurvetoQuadraticRel_Callback";


  /** @domName SVGPathElement.createSVGPathSegCurvetoQuadraticSmoothAbs */
  PathSegCurvetoQuadraticSmoothAbs createSvgPathSegCurvetoQuadraticSmoothAbs(num x, num y) native "SVGPathElement_createSVGPathSegCurvetoQuadraticSmoothAbs_Callback";


  /** @domName SVGPathElement.createSVGPathSegCurvetoQuadraticSmoothRel */
  PathSegCurvetoQuadraticSmoothRel createSvgPathSegCurvetoQuadraticSmoothRel(num x, num y) native "SVGPathElement_createSVGPathSegCurvetoQuadraticSmoothRel_Callback";


  /** @domName SVGPathElement.createSVGPathSegLinetoAbs */
  PathSegLinetoAbs createSvgPathSegLinetoAbs(num x, num y) native "SVGPathElement_createSVGPathSegLinetoAbs_Callback";


  /** @domName SVGPathElement.createSVGPathSegLinetoHorizontalAbs */
  PathSegLinetoHorizontalAbs createSvgPathSegLinetoHorizontalAbs(num x) native "SVGPathElement_createSVGPathSegLinetoHorizontalAbs_Callback";


  /** @domName SVGPathElement.createSVGPathSegLinetoHorizontalRel */
  PathSegLinetoHorizontalRel createSvgPathSegLinetoHorizontalRel(num x) native "SVGPathElement_createSVGPathSegLinetoHorizontalRel_Callback";


  /** @domName SVGPathElement.createSVGPathSegLinetoRel */
  PathSegLinetoRel createSvgPathSegLinetoRel(num x, num y) native "SVGPathElement_createSVGPathSegLinetoRel_Callback";


  /** @domName SVGPathElement.createSVGPathSegLinetoVerticalAbs */
  PathSegLinetoVerticalAbs createSvgPathSegLinetoVerticalAbs(num y) native "SVGPathElement_createSVGPathSegLinetoVerticalAbs_Callback";


  /** @domName SVGPathElement.createSVGPathSegLinetoVerticalRel */
  PathSegLinetoVerticalRel createSvgPathSegLinetoVerticalRel(num y) native "SVGPathElement_createSVGPathSegLinetoVerticalRel_Callback";


  /** @domName SVGPathElement.createSVGPathSegMovetoAbs */
  PathSegMovetoAbs createSvgPathSegMovetoAbs(num x, num y) native "SVGPathElement_createSVGPathSegMovetoAbs_Callback";


  /** @domName SVGPathElement.createSVGPathSegMovetoRel */
  PathSegMovetoRel createSvgPathSegMovetoRel(num x, num y) native "SVGPathElement_createSVGPathSegMovetoRel_Callback";


  /** @domName SVGPathElement.getPathSegAtLength */
  int getPathSegAtLength(num distance) native "SVGPathElement_getPathSegAtLength_Callback";


  /** @domName SVGPathElement.getPointAtLength */
  Point getPointAtLength(num distance) native "SVGPathElement_getPointAtLength_Callback";


  /** @domName SVGPathElement.getTotalLength */
  num getTotalLength() native "SVGPathElement_getTotalLength_Callback";


  /** @domName SVGPathElement.externalResourcesRequired */
  AnimatedBoolean get externalResourcesRequired native "SVGPathElement_externalResourcesRequired_Getter";


  /** @domName SVGPathElement.xmllang */
  String get xmllang native "SVGPathElement_xmllang_Getter";


  /** @domName SVGPathElement.xmllang */
  void set xmllang(String value) native "SVGPathElement_xmllang_Setter";


  /** @domName SVGPathElement.xmlspace */
  String get xmlspace native "SVGPathElement_xmlspace_Getter";


  /** @domName SVGPathElement.xmlspace */
  void set xmlspace(String value) native "SVGPathElement_xmlspace_Setter";


  /** @domName SVGPathElement.farthestViewportElement */
  SvgElement get farthestViewportElement native "SVGPathElement_farthestViewportElement_Getter";


  /** @domName SVGPathElement.nearestViewportElement */
  SvgElement get nearestViewportElement native "SVGPathElement_nearestViewportElement_Getter";


  /** @domName SVGPathElement.getBBox */
  Rect getBBox() native "SVGPathElement_getBBox_Callback";


  /** @domName SVGPathElement.getCTM */
  Matrix getCtm() native "SVGPathElement_getCTM_Callback";


  /** @domName SVGPathElement.getScreenCTM */
  Matrix getScreenCtm() native "SVGPathElement_getScreenCTM_Callback";


  /** @domName SVGPathElement.getTransformToElement */
  Matrix getTransformToElement(SvgElement element) native "SVGPathElement_getTransformToElement_Callback";


  /** @domName SVGPathElement.className */
  AnimatedString get $dom_svgClassName native "SVGPathElement_className_Getter";


  /** @domName SVGPathElement.style */
  CSSStyleDeclaration get style native "SVGPathElement_style_Getter";


  /** @domName SVGPathElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGPathElement_getPresentationAttribute_Callback";


  /** @domName SVGPathElement.requiredExtensions */
  StringList get requiredExtensions native "SVGPathElement_requiredExtensions_Getter";


  /** @domName SVGPathElement.requiredFeatures */
  StringList get requiredFeatures native "SVGPathElement_requiredFeatures_Getter";


  /** @domName SVGPathElement.systemLanguage */
  StringList get systemLanguage native "SVGPathElement_systemLanguage_Getter";


  /** @domName SVGPathElement.hasExtension */
  bool hasExtension(String extension) native "SVGPathElement_hasExtension_Callback";


  /** @domName SVGPathElement.transform */
  AnimatedTransformList get transform native "SVGPathElement_transform_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGPathSeg
class PathSeg extends NativeFieldWrapperClass1 {
  PathSeg.internal();

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
  int get pathSegType native "SVGPathSeg_pathSegType_Getter";


  /** @domName SVGPathSeg.pathSegTypeAsLetter */
  String get pathSegTypeAsLetter native "SVGPathSeg_pathSegTypeAsLetter_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGPathSegArcAbs
class PathSegArcAbs extends PathSeg {
  PathSegArcAbs.internal(): super.internal();


  /** @domName SVGPathSegArcAbs.angle */
  num get angle native "SVGPathSegArcAbs_angle_Getter";


  /** @domName SVGPathSegArcAbs.angle */
  void set angle(num value) native "SVGPathSegArcAbs_angle_Setter";


  /** @domName SVGPathSegArcAbs.largeArcFlag */
  bool get largeArcFlag native "SVGPathSegArcAbs_largeArcFlag_Getter";


  /** @domName SVGPathSegArcAbs.largeArcFlag */
  void set largeArcFlag(bool value) native "SVGPathSegArcAbs_largeArcFlag_Setter";


  /** @domName SVGPathSegArcAbs.r1 */
  num get r1 native "SVGPathSegArcAbs_r1_Getter";


  /** @domName SVGPathSegArcAbs.r1 */
  void set r1(num value) native "SVGPathSegArcAbs_r1_Setter";


  /** @domName SVGPathSegArcAbs.r2 */
  num get r2 native "SVGPathSegArcAbs_r2_Getter";


  /** @domName SVGPathSegArcAbs.r2 */
  void set r2(num value) native "SVGPathSegArcAbs_r2_Setter";


  /** @domName SVGPathSegArcAbs.sweepFlag */
  bool get sweepFlag native "SVGPathSegArcAbs_sweepFlag_Getter";


  /** @domName SVGPathSegArcAbs.sweepFlag */
  void set sweepFlag(bool value) native "SVGPathSegArcAbs_sweepFlag_Setter";


  /** @domName SVGPathSegArcAbs.x */
  num get x native "SVGPathSegArcAbs_x_Getter";


  /** @domName SVGPathSegArcAbs.x */
  void set x(num value) native "SVGPathSegArcAbs_x_Setter";


  /** @domName SVGPathSegArcAbs.y */
  num get y native "SVGPathSegArcAbs_y_Getter";


  /** @domName SVGPathSegArcAbs.y */
  void set y(num value) native "SVGPathSegArcAbs_y_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGPathSegArcRel
class PathSegArcRel extends PathSeg {
  PathSegArcRel.internal(): super.internal();


  /** @domName SVGPathSegArcRel.angle */
  num get angle native "SVGPathSegArcRel_angle_Getter";


  /** @domName SVGPathSegArcRel.angle */
  void set angle(num value) native "SVGPathSegArcRel_angle_Setter";


  /** @domName SVGPathSegArcRel.largeArcFlag */
  bool get largeArcFlag native "SVGPathSegArcRel_largeArcFlag_Getter";


  /** @domName SVGPathSegArcRel.largeArcFlag */
  void set largeArcFlag(bool value) native "SVGPathSegArcRel_largeArcFlag_Setter";


  /** @domName SVGPathSegArcRel.r1 */
  num get r1 native "SVGPathSegArcRel_r1_Getter";


  /** @domName SVGPathSegArcRel.r1 */
  void set r1(num value) native "SVGPathSegArcRel_r1_Setter";


  /** @domName SVGPathSegArcRel.r2 */
  num get r2 native "SVGPathSegArcRel_r2_Getter";


  /** @domName SVGPathSegArcRel.r2 */
  void set r2(num value) native "SVGPathSegArcRel_r2_Setter";


  /** @domName SVGPathSegArcRel.sweepFlag */
  bool get sweepFlag native "SVGPathSegArcRel_sweepFlag_Getter";


  /** @domName SVGPathSegArcRel.sweepFlag */
  void set sweepFlag(bool value) native "SVGPathSegArcRel_sweepFlag_Setter";


  /** @domName SVGPathSegArcRel.x */
  num get x native "SVGPathSegArcRel_x_Getter";


  /** @domName SVGPathSegArcRel.x */
  void set x(num value) native "SVGPathSegArcRel_x_Setter";


  /** @domName SVGPathSegArcRel.y */
  num get y native "SVGPathSegArcRel_y_Getter";


  /** @domName SVGPathSegArcRel.y */
  void set y(num value) native "SVGPathSegArcRel_y_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGPathSegClosePath
class PathSegClosePath extends PathSeg {
  PathSegClosePath.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGPathSegCurvetoCubicAbs
class PathSegCurvetoCubicAbs extends PathSeg {
  PathSegCurvetoCubicAbs.internal(): super.internal();


  /** @domName SVGPathSegCurvetoCubicAbs.x */
  num get x native "SVGPathSegCurvetoCubicAbs_x_Getter";


  /** @domName SVGPathSegCurvetoCubicAbs.x */
  void set x(num value) native "SVGPathSegCurvetoCubicAbs_x_Setter";


  /** @domName SVGPathSegCurvetoCubicAbs.x1 */
  num get x1 native "SVGPathSegCurvetoCubicAbs_x1_Getter";


  /** @domName SVGPathSegCurvetoCubicAbs.x1 */
  void set x1(num value) native "SVGPathSegCurvetoCubicAbs_x1_Setter";


  /** @domName SVGPathSegCurvetoCubicAbs.x2 */
  num get x2 native "SVGPathSegCurvetoCubicAbs_x2_Getter";


  /** @domName SVGPathSegCurvetoCubicAbs.x2 */
  void set x2(num value) native "SVGPathSegCurvetoCubicAbs_x2_Setter";


  /** @domName SVGPathSegCurvetoCubicAbs.y */
  num get y native "SVGPathSegCurvetoCubicAbs_y_Getter";


  /** @domName SVGPathSegCurvetoCubicAbs.y */
  void set y(num value) native "SVGPathSegCurvetoCubicAbs_y_Setter";


  /** @domName SVGPathSegCurvetoCubicAbs.y1 */
  num get y1 native "SVGPathSegCurvetoCubicAbs_y1_Getter";


  /** @domName SVGPathSegCurvetoCubicAbs.y1 */
  void set y1(num value) native "SVGPathSegCurvetoCubicAbs_y1_Setter";


  /** @domName SVGPathSegCurvetoCubicAbs.y2 */
  num get y2 native "SVGPathSegCurvetoCubicAbs_y2_Getter";


  /** @domName SVGPathSegCurvetoCubicAbs.y2 */
  void set y2(num value) native "SVGPathSegCurvetoCubicAbs_y2_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGPathSegCurvetoCubicRel
class PathSegCurvetoCubicRel extends PathSeg {
  PathSegCurvetoCubicRel.internal(): super.internal();


  /** @domName SVGPathSegCurvetoCubicRel.x */
  num get x native "SVGPathSegCurvetoCubicRel_x_Getter";


  /** @domName SVGPathSegCurvetoCubicRel.x */
  void set x(num value) native "SVGPathSegCurvetoCubicRel_x_Setter";


  /** @domName SVGPathSegCurvetoCubicRel.x1 */
  num get x1 native "SVGPathSegCurvetoCubicRel_x1_Getter";


  /** @domName SVGPathSegCurvetoCubicRel.x1 */
  void set x1(num value) native "SVGPathSegCurvetoCubicRel_x1_Setter";


  /** @domName SVGPathSegCurvetoCubicRel.x2 */
  num get x2 native "SVGPathSegCurvetoCubicRel_x2_Getter";


  /** @domName SVGPathSegCurvetoCubicRel.x2 */
  void set x2(num value) native "SVGPathSegCurvetoCubicRel_x2_Setter";


  /** @domName SVGPathSegCurvetoCubicRel.y */
  num get y native "SVGPathSegCurvetoCubicRel_y_Getter";


  /** @domName SVGPathSegCurvetoCubicRel.y */
  void set y(num value) native "SVGPathSegCurvetoCubicRel_y_Setter";


  /** @domName SVGPathSegCurvetoCubicRel.y1 */
  num get y1 native "SVGPathSegCurvetoCubicRel_y1_Getter";


  /** @domName SVGPathSegCurvetoCubicRel.y1 */
  void set y1(num value) native "SVGPathSegCurvetoCubicRel_y1_Setter";


  /** @domName SVGPathSegCurvetoCubicRel.y2 */
  num get y2 native "SVGPathSegCurvetoCubicRel_y2_Getter";


  /** @domName SVGPathSegCurvetoCubicRel.y2 */
  void set y2(num value) native "SVGPathSegCurvetoCubicRel_y2_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGPathSegCurvetoCubicSmoothAbs
class PathSegCurvetoCubicSmoothAbs extends PathSeg {
  PathSegCurvetoCubicSmoothAbs.internal(): super.internal();


  /** @domName SVGPathSegCurvetoCubicSmoothAbs.x */
  num get x native "SVGPathSegCurvetoCubicSmoothAbs_x_Getter";


  /** @domName SVGPathSegCurvetoCubicSmoothAbs.x */
  void set x(num value) native "SVGPathSegCurvetoCubicSmoothAbs_x_Setter";


  /** @domName SVGPathSegCurvetoCubicSmoothAbs.x2 */
  num get x2 native "SVGPathSegCurvetoCubicSmoothAbs_x2_Getter";


  /** @domName SVGPathSegCurvetoCubicSmoothAbs.x2 */
  void set x2(num value) native "SVGPathSegCurvetoCubicSmoothAbs_x2_Setter";


  /** @domName SVGPathSegCurvetoCubicSmoothAbs.y */
  num get y native "SVGPathSegCurvetoCubicSmoothAbs_y_Getter";


  /** @domName SVGPathSegCurvetoCubicSmoothAbs.y */
  void set y(num value) native "SVGPathSegCurvetoCubicSmoothAbs_y_Setter";


  /** @domName SVGPathSegCurvetoCubicSmoothAbs.y2 */
  num get y2 native "SVGPathSegCurvetoCubicSmoothAbs_y2_Getter";


  /** @domName SVGPathSegCurvetoCubicSmoothAbs.y2 */
  void set y2(num value) native "SVGPathSegCurvetoCubicSmoothAbs_y2_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGPathSegCurvetoCubicSmoothRel
class PathSegCurvetoCubicSmoothRel extends PathSeg {
  PathSegCurvetoCubicSmoothRel.internal(): super.internal();


  /** @domName SVGPathSegCurvetoCubicSmoothRel.x */
  num get x native "SVGPathSegCurvetoCubicSmoothRel_x_Getter";


  /** @domName SVGPathSegCurvetoCubicSmoothRel.x */
  void set x(num value) native "SVGPathSegCurvetoCubicSmoothRel_x_Setter";


  /** @domName SVGPathSegCurvetoCubicSmoothRel.x2 */
  num get x2 native "SVGPathSegCurvetoCubicSmoothRel_x2_Getter";


  /** @domName SVGPathSegCurvetoCubicSmoothRel.x2 */
  void set x2(num value) native "SVGPathSegCurvetoCubicSmoothRel_x2_Setter";


  /** @domName SVGPathSegCurvetoCubicSmoothRel.y */
  num get y native "SVGPathSegCurvetoCubicSmoothRel_y_Getter";


  /** @domName SVGPathSegCurvetoCubicSmoothRel.y */
  void set y(num value) native "SVGPathSegCurvetoCubicSmoothRel_y_Setter";


  /** @domName SVGPathSegCurvetoCubicSmoothRel.y2 */
  num get y2 native "SVGPathSegCurvetoCubicSmoothRel_y2_Getter";


  /** @domName SVGPathSegCurvetoCubicSmoothRel.y2 */
  void set y2(num value) native "SVGPathSegCurvetoCubicSmoothRel_y2_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGPathSegCurvetoQuadraticAbs
class PathSegCurvetoQuadraticAbs extends PathSeg {
  PathSegCurvetoQuadraticAbs.internal(): super.internal();


  /** @domName SVGPathSegCurvetoQuadraticAbs.x */
  num get x native "SVGPathSegCurvetoQuadraticAbs_x_Getter";


  /** @domName SVGPathSegCurvetoQuadraticAbs.x */
  void set x(num value) native "SVGPathSegCurvetoQuadraticAbs_x_Setter";


  /** @domName SVGPathSegCurvetoQuadraticAbs.x1 */
  num get x1 native "SVGPathSegCurvetoQuadraticAbs_x1_Getter";


  /** @domName SVGPathSegCurvetoQuadraticAbs.x1 */
  void set x1(num value) native "SVGPathSegCurvetoQuadraticAbs_x1_Setter";


  /** @domName SVGPathSegCurvetoQuadraticAbs.y */
  num get y native "SVGPathSegCurvetoQuadraticAbs_y_Getter";


  /** @domName SVGPathSegCurvetoQuadraticAbs.y */
  void set y(num value) native "SVGPathSegCurvetoQuadraticAbs_y_Setter";


  /** @domName SVGPathSegCurvetoQuadraticAbs.y1 */
  num get y1 native "SVGPathSegCurvetoQuadraticAbs_y1_Getter";


  /** @domName SVGPathSegCurvetoQuadraticAbs.y1 */
  void set y1(num value) native "SVGPathSegCurvetoQuadraticAbs_y1_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGPathSegCurvetoQuadraticRel
class PathSegCurvetoQuadraticRel extends PathSeg {
  PathSegCurvetoQuadraticRel.internal(): super.internal();


  /** @domName SVGPathSegCurvetoQuadraticRel.x */
  num get x native "SVGPathSegCurvetoQuadraticRel_x_Getter";


  /** @domName SVGPathSegCurvetoQuadraticRel.x */
  void set x(num value) native "SVGPathSegCurvetoQuadraticRel_x_Setter";


  /** @domName SVGPathSegCurvetoQuadraticRel.x1 */
  num get x1 native "SVGPathSegCurvetoQuadraticRel_x1_Getter";


  /** @domName SVGPathSegCurvetoQuadraticRel.x1 */
  void set x1(num value) native "SVGPathSegCurvetoQuadraticRel_x1_Setter";


  /** @domName SVGPathSegCurvetoQuadraticRel.y */
  num get y native "SVGPathSegCurvetoQuadraticRel_y_Getter";


  /** @domName SVGPathSegCurvetoQuadraticRel.y */
  void set y(num value) native "SVGPathSegCurvetoQuadraticRel_y_Setter";


  /** @domName SVGPathSegCurvetoQuadraticRel.y1 */
  num get y1 native "SVGPathSegCurvetoQuadraticRel_y1_Getter";


  /** @domName SVGPathSegCurvetoQuadraticRel.y1 */
  void set y1(num value) native "SVGPathSegCurvetoQuadraticRel_y1_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGPathSegCurvetoQuadraticSmoothAbs
class PathSegCurvetoQuadraticSmoothAbs extends PathSeg {
  PathSegCurvetoQuadraticSmoothAbs.internal(): super.internal();


  /** @domName SVGPathSegCurvetoQuadraticSmoothAbs.x */
  num get x native "SVGPathSegCurvetoQuadraticSmoothAbs_x_Getter";


  /** @domName SVGPathSegCurvetoQuadraticSmoothAbs.x */
  void set x(num value) native "SVGPathSegCurvetoQuadraticSmoothAbs_x_Setter";


  /** @domName SVGPathSegCurvetoQuadraticSmoothAbs.y */
  num get y native "SVGPathSegCurvetoQuadraticSmoothAbs_y_Getter";


  /** @domName SVGPathSegCurvetoQuadraticSmoothAbs.y */
  void set y(num value) native "SVGPathSegCurvetoQuadraticSmoothAbs_y_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGPathSegCurvetoQuadraticSmoothRel
class PathSegCurvetoQuadraticSmoothRel extends PathSeg {
  PathSegCurvetoQuadraticSmoothRel.internal(): super.internal();


  /** @domName SVGPathSegCurvetoQuadraticSmoothRel.x */
  num get x native "SVGPathSegCurvetoQuadraticSmoothRel_x_Getter";


  /** @domName SVGPathSegCurvetoQuadraticSmoothRel.x */
  void set x(num value) native "SVGPathSegCurvetoQuadraticSmoothRel_x_Setter";


  /** @domName SVGPathSegCurvetoQuadraticSmoothRel.y */
  num get y native "SVGPathSegCurvetoQuadraticSmoothRel_y_Getter";


  /** @domName SVGPathSegCurvetoQuadraticSmoothRel.y */
  void set y(num value) native "SVGPathSegCurvetoQuadraticSmoothRel_y_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGPathSegLinetoAbs
class PathSegLinetoAbs extends PathSeg {
  PathSegLinetoAbs.internal(): super.internal();


  /** @domName SVGPathSegLinetoAbs.x */
  num get x native "SVGPathSegLinetoAbs_x_Getter";


  /** @domName SVGPathSegLinetoAbs.x */
  void set x(num value) native "SVGPathSegLinetoAbs_x_Setter";


  /** @domName SVGPathSegLinetoAbs.y */
  num get y native "SVGPathSegLinetoAbs_y_Getter";


  /** @domName SVGPathSegLinetoAbs.y */
  void set y(num value) native "SVGPathSegLinetoAbs_y_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGPathSegLinetoHorizontalAbs
class PathSegLinetoHorizontalAbs extends PathSeg {
  PathSegLinetoHorizontalAbs.internal(): super.internal();


  /** @domName SVGPathSegLinetoHorizontalAbs.x */
  num get x native "SVGPathSegLinetoHorizontalAbs_x_Getter";


  /** @domName SVGPathSegLinetoHorizontalAbs.x */
  void set x(num value) native "SVGPathSegLinetoHorizontalAbs_x_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGPathSegLinetoHorizontalRel
class PathSegLinetoHorizontalRel extends PathSeg {
  PathSegLinetoHorizontalRel.internal(): super.internal();


  /** @domName SVGPathSegLinetoHorizontalRel.x */
  num get x native "SVGPathSegLinetoHorizontalRel_x_Getter";


  /** @domName SVGPathSegLinetoHorizontalRel.x */
  void set x(num value) native "SVGPathSegLinetoHorizontalRel_x_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGPathSegLinetoRel
class PathSegLinetoRel extends PathSeg {
  PathSegLinetoRel.internal(): super.internal();


  /** @domName SVGPathSegLinetoRel.x */
  num get x native "SVGPathSegLinetoRel_x_Getter";


  /** @domName SVGPathSegLinetoRel.x */
  void set x(num value) native "SVGPathSegLinetoRel_x_Setter";


  /** @domName SVGPathSegLinetoRel.y */
  num get y native "SVGPathSegLinetoRel_y_Getter";


  /** @domName SVGPathSegLinetoRel.y */
  void set y(num value) native "SVGPathSegLinetoRel_y_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGPathSegLinetoVerticalAbs
class PathSegLinetoVerticalAbs extends PathSeg {
  PathSegLinetoVerticalAbs.internal(): super.internal();


  /** @domName SVGPathSegLinetoVerticalAbs.y */
  num get y native "SVGPathSegLinetoVerticalAbs_y_Getter";


  /** @domName SVGPathSegLinetoVerticalAbs.y */
  void set y(num value) native "SVGPathSegLinetoVerticalAbs_y_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGPathSegLinetoVerticalRel
class PathSegLinetoVerticalRel extends PathSeg {
  PathSegLinetoVerticalRel.internal(): super.internal();


  /** @domName SVGPathSegLinetoVerticalRel.y */
  num get y native "SVGPathSegLinetoVerticalRel_y_Getter";


  /** @domName SVGPathSegLinetoVerticalRel.y */
  void set y(num value) native "SVGPathSegLinetoVerticalRel_y_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGPathSegList
class PathSegList extends NativeFieldWrapperClass1 implements List<PathSeg> {
  PathSegList.internal();


  /** @domName SVGPathSegList.numberOfItems */
  int get numberOfItems native "SVGPathSegList_numberOfItems_Getter";

  PathSeg operator[](int index) native "SVGPathSegList_item_Callback";

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

  bool contains(PathSeg element) => Collections.contains(this, element);

  void forEach(void f(PathSeg element)) => Collections.forEach(this, f);

  Collection map(f(PathSeg element)) => Collections.map(this, [], f);

  Collection<PathSeg> filter(bool f(PathSeg element)) =>
     Collections.filter(this, <PathSeg>[], f);

  bool every(bool f(PathSeg element)) => Collections.every(this, f);

  bool some(bool f(PathSeg element)) => Collections.some(this, f);

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
  PathSeg appendItem(PathSeg newItem) native "SVGPathSegList_appendItem_Callback";


  /** @domName SVGPathSegList.clear */
  void clear() native "SVGPathSegList_clear_Callback";


  /** @domName SVGPathSegList.getItem */
  PathSeg getItem(int index) native "SVGPathSegList_getItem_Callback";


  /** @domName SVGPathSegList.initialize */
  PathSeg initialize(PathSeg newItem) native "SVGPathSegList_initialize_Callback";


  /** @domName SVGPathSegList.insertItemBefore */
  PathSeg insertItemBefore(PathSeg newItem, int index) native "SVGPathSegList_insertItemBefore_Callback";


  /** @domName SVGPathSegList.removeItem */
  PathSeg removeItem(int index) native "SVGPathSegList_removeItem_Callback";


  /** @domName SVGPathSegList.replaceItem */
  PathSeg replaceItem(PathSeg newItem, int index) native "SVGPathSegList_replaceItem_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGPathSegMovetoAbs
class PathSegMovetoAbs extends PathSeg {
  PathSegMovetoAbs.internal(): super.internal();


  /** @domName SVGPathSegMovetoAbs.x */
  num get x native "SVGPathSegMovetoAbs_x_Getter";


  /** @domName SVGPathSegMovetoAbs.x */
  void set x(num value) native "SVGPathSegMovetoAbs_x_Setter";


  /** @domName SVGPathSegMovetoAbs.y */
  num get y native "SVGPathSegMovetoAbs_y_Getter";


  /** @domName SVGPathSegMovetoAbs.y */
  void set y(num value) native "SVGPathSegMovetoAbs_y_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGPathSegMovetoRel
class PathSegMovetoRel extends PathSeg {
  PathSegMovetoRel.internal(): super.internal();


  /** @domName SVGPathSegMovetoRel.x */
  num get x native "SVGPathSegMovetoRel_x_Getter";


  /** @domName SVGPathSegMovetoRel.x */
  void set x(num value) native "SVGPathSegMovetoRel_x_Setter";


  /** @domName SVGPathSegMovetoRel.y */
  num get y native "SVGPathSegMovetoRel_y_Getter";


  /** @domName SVGPathSegMovetoRel.y */
  void set y(num value) native "SVGPathSegMovetoRel_y_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGPatternElement
class PatternElement extends SvgElement implements FitToViewBox, Tests, UriReference, Stylable, ExternalResourcesRequired, LangSpace {

  factory PatternElement() => _SvgElementFactoryProvider.createSvgElement_tag("pattern");
  PatternElement.internal(): super.internal();


  /** @domName SVGPatternElement.height */
  AnimatedLength get height native "SVGPatternElement_height_Getter";


  /** @domName SVGPatternElement.patternContentUnits */
  AnimatedEnumeration get patternContentUnits native "SVGPatternElement_patternContentUnits_Getter";


  /** @domName SVGPatternElement.patternTransform */
  AnimatedTransformList get patternTransform native "SVGPatternElement_patternTransform_Getter";


  /** @domName SVGPatternElement.patternUnits */
  AnimatedEnumeration get patternUnits native "SVGPatternElement_patternUnits_Getter";


  /** @domName SVGPatternElement.width */
  AnimatedLength get width native "SVGPatternElement_width_Getter";


  /** @domName SVGPatternElement.x */
  AnimatedLength get x native "SVGPatternElement_x_Getter";


  /** @domName SVGPatternElement.y */
  AnimatedLength get y native "SVGPatternElement_y_Getter";


  /** @domName SVGPatternElement.externalResourcesRequired */
  AnimatedBoolean get externalResourcesRequired native "SVGPatternElement_externalResourcesRequired_Getter";


  /** @domName SVGPatternElement.preserveAspectRatio */
  AnimatedPreserveAspectRatio get preserveAspectRatio native "SVGPatternElement_preserveAspectRatio_Getter";


  /** @domName SVGPatternElement.viewBox */
  AnimatedRect get viewBox native "SVGPatternElement_viewBox_Getter";


  /** @domName SVGPatternElement.xmllang */
  String get xmllang native "SVGPatternElement_xmllang_Getter";


  /** @domName SVGPatternElement.xmllang */
  void set xmllang(String value) native "SVGPatternElement_xmllang_Setter";


  /** @domName SVGPatternElement.xmlspace */
  String get xmlspace native "SVGPatternElement_xmlspace_Getter";


  /** @domName SVGPatternElement.xmlspace */
  void set xmlspace(String value) native "SVGPatternElement_xmlspace_Setter";


  /** @domName SVGPatternElement.className */
  AnimatedString get $dom_svgClassName native "SVGPatternElement_className_Getter";


  /** @domName SVGPatternElement.style */
  CSSStyleDeclaration get style native "SVGPatternElement_style_Getter";


  /** @domName SVGPatternElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGPatternElement_getPresentationAttribute_Callback";


  /** @domName SVGPatternElement.requiredExtensions */
  StringList get requiredExtensions native "SVGPatternElement_requiredExtensions_Getter";


  /** @domName SVGPatternElement.requiredFeatures */
  StringList get requiredFeatures native "SVGPatternElement_requiredFeatures_Getter";


  /** @domName SVGPatternElement.systemLanguage */
  StringList get systemLanguage native "SVGPatternElement_systemLanguage_Getter";


  /** @domName SVGPatternElement.hasExtension */
  bool hasExtension(String extension) native "SVGPatternElement_hasExtension_Callback";


  /** @domName SVGPatternElement.href */
  AnimatedString get href native "SVGPatternElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGPoint
class Point extends NativeFieldWrapperClass1 {
  factory Point(num x, num y) => _PointFactoryProvider.createPoint(x, y);
  Point.internal();


  /** @domName SVGPoint.x */
  num get x native "SVGPoint_x_Getter";


  /** @domName SVGPoint.x */
  void set x(num value) native "SVGPoint_x_Setter";


  /** @domName SVGPoint.y */
  num get y native "SVGPoint_y_Getter";


  /** @domName SVGPoint.y */
  void set y(num value) native "SVGPoint_y_Setter";


  /** @domName SVGPoint.matrixTransform */
  Point matrixTransform(Matrix matrix) native "SVGPoint_matrixTransform_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGPointList
class PointList extends NativeFieldWrapperClass1 {
  PointList.internal();


  /** @domName SVGPointList.numberOfItems */
  int get numberOfItems native "SVGPointList_numberOfItems_Getter";


  /** @domName SVGPointList.appendItem */
  Point appendItem(Point item) native "SVGPointList_appendItem_Callback";


  /** @domName SVGPointList.clear */
  void clear() native "SVGPointList_clear_Callback";


  /** @domName SVGPointList.getItem */
  Point getItem(int index) native "SVGPointList_getItem_Callback";


  /** @domName SVGPointList.initialize */
  Point initialize(Point item) native "SVGPointList_initialize_Callback";


  /** @domName SVGPointList.insertItemBefore */
  Point insertItemBefore(Point item, int index) native "SVGPointList_insertItemBefore_Callback";


  /** @domName SVGPointList.removeItem */
  Point removeItem(int index) native "SVGPointList_removeItem_Callback";


  /** @domName SVGPointList.replaceItem */
  Point replaceItem(Point item, int index) native "SVGPointList_replaceItem_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGPolygonElement
class PolygonElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace {

  factory PolygonElement() => _SvgElementFactoryProvider.createSvgElement_tag("polygon");
  PolygonElement.internal(): super.internal();


  /** @domName SVGPolygonElement.animatedPoints */
  PointList get animatedPoints native "SVGPolygonElement_animatedPoints_Getter";


  /** @domName SVGPolygonElement.points */
  PointList get points native "SVGPolygonElement_points_Getter";


  /** @domName SVGPolygonElement.externalResourcesRequired */
  AnimatedBoolean get externalResourcesRequired native "SVGPolygonElement_externalResourcesRequired_Getter";


  /** @domName SVGPolygonElement.xmllang */
  String get xmllang native "SVGPolygonElement_xmllang_Getter";


  /** @domName SVGPolygonElement.xmllang */
  void set xmllang(String value) native "SVGPolygonElement_xmllang_Setter";


  /** @domName SVGPolygonElement.xmlspace */
  String get xmlspace native "SVGPolygonElement_xmlspace_Getter";


  /** @domName SVGPolygonElement.xmlspace */
  void set xmlspace(String value) native "SVGPolygonElement_xmlspace_Setter";


  /** @domName SVGPolygonElement.farthestViewportElement */
  SvgElement get farthestViewportElement native "SVGPolygonElement_farthestViewportElement_Getter";


  /** @domName SVGPolygonElement.nearestViewportElement */
  SvgElement get nearestViewportElement native "SVGPolygonElement_nearestViewportElement_Getter";


  /** @domName SVGPolygonElement.getBBox */
  Rect getBBox() native "SVGPolygonElement_getBBox_Callback";


  /** @domName SVGPolygonElement.getCTM */
  Matrix getCtm() native "SVGPolygonElement_getCTM_Callback";


  /** @domName SVGPolygonElement.getScreenCTM */
  Matrix getScreenCtm() native "SVGPolygonElement_getScreenCTM_Callback";


  /** @domName SVGPolygonElement.getTransformToElement */
  Matrix getTransformToElement(SvgElement element) native "SVGPolygonElement_getTransformToElement_Callback";


  /** @domName SVGPolygonElement.className */
  AnimatedString get $dom_svgClassName native "SVGPolygonElement_className_Getter";


  /** @domName SVGPolygonElement.style */
  CSSStyleDeclaration get style native "SVGPolygonElement_style_Getter";


  /** @domName SVGPolygonElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGPolygonElement_getPresentationAttribute_Callback";


  /** @domName SVGPolygonElement.requiredExtensions */
  StringList get requiredExtensions native "SVGPolygonElement_requiredExtensions_Getter";


  /** @domName SVGPolygonElement.requiredFeatures */
  StringList get requiredFeatures native "SVGPolygonElement_requiredFeatures_Getter";


  /** @domName SVGPolygonElement.systemLanguage */
  StringList get systemLanguage native "SVGPolygonElement_systemLanguage_Getter";


  /** @domName SVGPolygonElement.hasExtension */
  bool hasExtension(String extension) native "SVGPolygonElement_hasExtension_Callback";


  /** @domName SVGPolygonElement.transform */
  AnimatedTransformList get transform native "SVGPolygonElement_transform_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGPolylineElement
class PolylineElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace {

  factory PolylineElement() => _SvgElementFactoryProvider.createSvgElement_tag("polyline");
  PolylineElement.internal(): super.internal();


  /** @domName SVGPolylineElement.animatedPoints */
  PointList get animatedPoints native "SVGPolylineElement_animatedPoints_Getter";


  /** @domName SVGPolylineElement.points */
  PointList get points native "SVGPolylineElement_points_Getter";


  /** @domName SVGPolylineElement.externalResourcesRequired */
  AnimatedBoolean get externalResourcesRequired native "SVGPolylineElement_externalResourcesRequired_Getter";


  /** @domName SVGPolylineElement.xmllang */
  String get xmllang native "SVGPolylineElement_xmllang_Getter";


  /** @domName SVGPolylineElement.xmllang */
  void set xmllang(String value) native "SVGPolylineElement_xmllang_Setter";


  /** @domName SVGPolylineElement.xmlspace */
  String get xmlspace native "SVGPolylineElement_xmlspace_Getter";


  /** @domName SVGPolylineElement.xmlspace */
  void set xmlspace(String value) native "SVGPolylineElement_xmlspace_Setter";


  /** @domName SVGPolylineElement.farthestViewportElement */
  SvgElement get farthestViewportElement native "SVGPolylineElement_farthestViewportElement_Getter";


  /** @domName SVGPolylineElement.nearestViewportElement */
  SvgElement get nearestViewportElement native "SVGPolylineElement_nearestViewportElement_Getter";


  /** @domName SVGPolylineElement.getBBox */
  Rect getBBox() native "SVGPolylineElement_getBBox_Callback";


  /** @domName SVGPolylineElement.getCTM */
  Matrix getCtm() native "SVGPolylineElement_getCTM_Callback";


  /** @domName SVGPolylineElement.getScreenCTM */
  Matrix getScreenCtm() native "SVGPolylineElement_getScreenCTM_Callback";


  /** @domName SVGPolylineElement.getTransformToElement */
  Matrix getTransformToElement(SvgElement element) native "SVGPolylineElement_getTransformToElement_Callback";


  /** @domName SVGPolylineElement.className */
  AnimatedString get $dom_svgClassName native "SVGPolylineElement_className_Getter";


  /** @domName SVGPolylineElement.style */
  CSSStyleDeclaration get style native "SVGPolylineElement_style_Getter";


  /** @domName SVGPolylineElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGPolylineElement_getPresentationAttribute_Callback";


  /** @domName SVGPolylineElement.requiredExtensions */
  StringList get requiredExtensions native "SVGPolylineElement_requiredExtensions_Getter";


  /** @domName SVGPolylineElement.requiredFeatures */
  StringList get requiredFeatures native "SVGPolylineElement_requiredFeatures_Getter";


  /** @domName SVGPolylineElement.systemLanguage */
  StringList get systemLanguage native "SVGPolylineElement_systemLanguage_Getter";


  /** @domName SVGPolylineElement.hasExtension */
  bool hasExtension(String extension) native "SVGPolylineElement_hasExtension_Callback";


  /** @domName SVGPolylineElement.transform */
  AnimatedTransformList get transform native "SVGPolylineElement_transform_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGPreserveAspectRatio
class PreserveAspectRatio extends NativeFieldWrapperClass1 {
  PreserveAspectRatio.internal();

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
  int get align native "SVGPreserveAspectRatio_align_Getter";


  /** @domName SVGPreserveAspectRatio.align */
  void set align(int value) native "SVGPreserveAspectRatio_align_Setter";


  /** @domName SVGPreserveAspectRatio.meetOrSlice */
  int get meetOrSlice native "SVGPreserveAspectRatio_meetOrSlice_Getter";


  /** @domName SVGPreserveAspectRatio.meetOrSlice */
  void set meetOrSlice(int value) native "SVGPreserveAspectRatio_meetOrSlice_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGRadialGradientElement
class RadialGradientElement extends GradientElement {

  factory RadialGradientElement() => _SvgElementFactoryProvider.createSvgElement_tag("radialGradient");
  RadialGradientElement.internal(): super.internal();


  /** @domName SVGRadialGradientElement.cx */
  AnimatedLength get cx native "SVGRadialGradientElement_cx_Getter";


  /** @domName SVGRadialGradientElement.cy */
  AnimatedLength get cy native "SVGRadialGradientElement_cy_Getter";


  /** @domName SVGRadialGradientElement.fr */
  AnimatedLength get fr native "SVGRadialGradientElement_fr_Getter";


  /** @domName SVGRadialGradientElement.fx */
  AnimatedLength get fx native "SVGRadialGradientElement_fx_Getter";


  /** @domName SVGRadialGradientElement.fy */
  AnimatedLength get fy native "SVGRadialGradientElement_fy_Getter";


  /** @domName SVGRadialGradientElement.r */
  AnimatedLength get r native "SVGRadialGradientElement_r_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGRect
class Rect extends NativeFieldWrapperClass1 {
  Rect.internal();


  /** @domName SVGRect.height */
  num get height native "SVGRect_height_Getter";


  /** @domName SVGRect.height */
  void set height(num value) native "SVGRect_height_Setter";


  /** @domName SVGRect.width */
  num get width native "SVGRect_width_Getter";


  /** @domName SVGRect.width */
  void set width(num value) native "SVGRect_width_Setter";


  /** @domName SVGRect.x */
  num get x native "SVGRect_x_Getter";


  /** @domName SVGRect.x */
  void set x(num value) native "SVGRect_x_Setter";


  /** @domName SVGRect.y */
  num get y native "SVGRect_y_Getter";


  /** @domName SVGRect.y */
  void set y(num value) native "SVGRect_y_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGRectElement
class RectElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace {

  factory RectElement() => _SvgElementFactoryProvider.createSvgElement_tag("rect");
  RectElement.internal(): super.internal();


  /** @domName SVGRectElement.height */
  AnimatedLength get height native "SVGRectElement_height_Getter";


  /** @domName SVGRectElement.rx */
  AnimatedLength get rx native "SVGRectElement_rx_Getter";


  /** @domName SVGRectElement.ry */
  AnimatedLength get ry native "SVGRectElement_ry_Getter";


  /** @domName SVGRectElement.width */
  AnimatedLength get width native "SVGRectElement_width_Getter";


  /** @domName SVGRectElement.x */
  AnimatedLength get x native "SVGRectElement_x_Getter";


  /** @domName SVGRectElement.y */
  AnimatedLength get y native "SVGRectElement_y_Getter";


  /** @domName SVGRectElement.externalResourcesRequired */
  AnimatedBoolean get externalResourcesRequired native "SVGRectElement_externalResourcesRequired_Getter";


  /** @domName SVGRectElement.xmllang */
  String get xmllang native "SVGRectElement_xmllang_Getter";


  /** @domName SVGRectElement.xmllang */
  void set xmllang(String value) native "SVGRectElement_xmllang_Setter";


  /** @domName SVGRectElement.xmlspace */
  String get xmlspace native "SVGRectElement_xmlspace_Getter";


  /** @domName SVGRectElement.xmlspace */
  void set xmlspace(String value) native "SVGRectElement_xmlspace_Setter";


  /** @domName SVGRectElement.farthestViewportElement */
  SvgElement get farthestViewportElement native "SVGRectElement_farthestViewportElement_Getter";


  /** @domName SVGRectElement.nearestViewportElement */
  SvgElement get nearestViewportElement native "SVGRectElement_nearestViewportElement_Getter";


  /** @domName SVGRectElement.getBBox */
  Rect getBBox() native "SVGRectElement_getBBox_Callback";


  /** @domName SVGRectElement.getCTM */
  Matrix getCtm() native "SVGRectElement_getCTM_Callback";


  /** @domName SVGRectElement.getScreenCTM */
  Matrix getScreenCtm() native "SVGRectElement_getScreenCTM_Callback";


  /** @domName SVGRectElement.getTransformToElement */
  Matrix getTransformToElement(SvgElement element) native "SVGRectElement_getTransformToElement_Callback";


  /** @domName SVGRectElement.className */
  AnimatedString get $dom_svgClassName native "SVGRectElement_className_Getter";


  /** @domName SVGRectElement.style */
  CSSStyleDeclaration get style native "SVGRectElement_style_Getter";


  /** @domName SVGRectElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGRectElement_getPresentationAttribute_Callback";


  /** @domName SVGRectElement.requiredExtensions */
  StringList get requiredExtensions native "SVGRectElement_requiredExtensions_Getter";


  /** @domName SVGRectElement.requiredFeatures */
  StringList get requiredFeatures native "SVGRectElement_requiredFeatures_Getter";


  /** @domName SVGRectElement.systemLanguage */
  StringList get systemLanguage native "SVGRectElement_systemLanguage_Getter";


  /** @domName SVGRectElement.hasExtension */
  bool hasExtension(String extension) native "SVGRectElement_hasExtension_Callback";


  /** @domName SVGRectElement.transform */
  AnimatedTransformList get transform native "SVGRectElement_transform_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGRenderingIntent
class RenderingIntent extends NativeFieldWrapperClass1 {
  RenderingIntent.internal();

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

// WARNING: Do not edit - generated code.


/// @domName SVGScriptElement
class ScriptElement extends SvgElement implements UriReference, ExternalResourcesRequired {

  factory ScriptElement() => _SvgElementFactoryProvider.createSvgElement_tag("script");
  ScriptElement.internal(): super.internal();


  /** @domName SVGScriptElement.type */
  String get type native "SVGScriptElement_type_Getter";


  /** @domName SVGScriptElement.type */
  void set type(String value) native "SVGScriptElement_type_Setter";


  /** @domName SVGScriptElement.externalResourcesRequired */
  AnimatedBoolean get externalResourcesRequired native "SVGScriptElement_externalResourcesRequired_Getter";


  /** @domName SVGScriptElement.href */
  AnimatedString get href native "SVGScriptElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGSetElement
class SetElement extends AnimationElement {

  factory SetElement() => _SvgElementFactoryProvider.createSvgElement_tag("set");
  SetElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGStopElement
class StopElement extends SvgElement implements Stylable {

  factory StopElement() => _SvgElementFactoryProvider.createSvgElement_tag("stop");
  StopElement.internal(): super.internal();


  /** @domName SVGStopElement.offset */
  AnimatedNumber get offset native "SVGStopElement_offset_Getter";


  /** @domName SVGStopElement.className */
  AnimatedString get $dom_svgClassName native "SVGStopElement_className_Getter";


  /** @domName SVGStopElement.style */
  CSSStyleDeclaration get style native "SVGStopElement_style_Getter";


  /** @domName SVGStopElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGStopElement_getPresentationAttribute_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGStringList
class StringList extends NativeFieldWrapperClass1 implements List<String> {
  StringList.internal();


  /** @domName SVGStringList.numberOfItems */
  int get numberOfItems native "SVGStringList_numberOfItems_Getter";

  String operator[](int index) native "SVGStringList_item_Callback";

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

  bool contains(String element) => Collections.contains(this, element);

  void forEach(void f(String element)) => Collections.forEach(this, f);

  Collection map(f(String element)) => Collections.map(this, [], f);

  Collection<String> filter(bool f(String element)) =>
     Collections.filter(this, <String>[], f);

  bool every(bool f(String element)) => Collections.every(this, f);

  bool some(bool f(String element)) => Collections.some(this, f);

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
  String appendItem(String item) native "SVGStringList_appendItem_Callback";


  /** @domName SVGStringList.clear */
  void clear() native "SVGStringList_clear_Callback";


  /** @domName SVGStringList.getItem */
  String getItem(int index) native "SVGStringList_getItem_Callback";


  /** @domName SVGStringList.initialize */
  String initialize(String item) native "SVGStringList_initialize_Callback";


  /** @domName SVGStringList.insertItemBefore */
  String insertItemBefore(String item, int index) native "SVGStringList_insertItemBefore_Callback";


  /** @domName SVGStringList.removeItem */
  String removeItem(int index) native "SVGStringList_removeItem_Callback";


  /** @domName SVGStringList.replaceItem */
  String replaceItem(String item, int index) native "SVGStringList_replaceItem_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGStylable
class Stylable extends NativeFieldWrapperClass1 {
  Stylable.internal();


  /** @domName SVGStylable.className */
  AnimatedString get $dom_svgClassName native "SVGStylable_className_Getter";


  /** @domName SVGStylable.style */
  CSSStyleDeclaration get style native "SVGStylable_style_Getter";


  /** @domName SVGStylable.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGStylable_getPresentationAttribute_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGStyleElement
class StyleElement extends SvgElement implements LangSpace {

  factory StyleElement() => _SvgElementFactoryProvider.createSvgElement_tag("style");
  StyleElement.internal(): super.internal();


  /** @domName SVGStyleElement.disabled */
  bool get disabled native "SVGStyleElement_disabled_Getter";


  /** @domName SVGStyleElement.disabled */
  void set disabled(bool value) native "SVGStyleElement_disabled_Setter";


  /** @domName SVGStyleElement.media */
  String get media native "SVGStyleElement_media_Getter";


  /** @domName SVGStyleElement.media */
  void set media(String value) native "SVGStyleElement_media_Setter";


  /** @domName SVGStyleElement.title */
  String get title native "SVGStyleElement_title_Getter";


  /** @domName SVGStyleElement.title */
  void set title(String value) native "SVGStyleElement_title_Setter";


  /** @domName SVGStyleElement.type */
  String get type native "SVGStyleElement_type_Getter";


  /** @domName SVGStyleElement.type */
  void set type(String value) native "SVGStyleElement_type_Setter";


  /** @domName SVGStyleElement.xmllang */
  String get xmllang native "SVGStyleElement_xmllang_Getter";


  /** @domName SVGStyleElement.xmllang */
  void set xmllang(String value) native "SVGStyleElement_xmllang_Setter";


  /** @domName SVGStyleElement.xmlspace */
  String get xmlspace native "SVGStyleElement_xmlspace_Getter";


  /** @domName SVGStyleElement.xmlspace */
  void set xmlspace(String value) native "SVGStyleElement_xmlspace_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGDocument
class SvgDocument extends Document {
  SvgDocument.internal(): super.internal();


  /** @domName SVGDocument.rootElement */
  SvgSvgElement get rootElement native "SVGDocument_rootElement_Getter";


  /** @domName SVGDocument.createEvent */
  Event $dom_createEvent(String eventType) native "SVGDocument_createEvent_Callback";

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

/// @domName SVGElement
class SvgElement extends Element {
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

  SvgElement.internal(): super.internal();


  /** @domName SVGElement.id */
  String get id native "SVGElement_id_Getter";


  /** @domName SVGElement.id */
  void set id(String value) native "SVGElement_id_Setter";


  /** @domName SVGElement.ownerSVGElement */
  SvgSvgElement get ownerSvgElement native "SVGElement_ownerSVGElement_Getter";


  /** @domName SVGElement.viewportElement */
  SvgElement get viewportElement native "SVGElement_viewportElement_Getter";


  /** @domName SVGElement.xmlbase */
  String get xmlbase native "SVGElement_xmlbase_Getter";


  /** @domName SVGElement.xmlbase */
  void set xmlbase(String value) native "SVGElement_xmlbase_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGException
class SvgException extends NativeFieldWrapperClass1 {
  SvgException.internal();

  static const int SVG_INVALID_VALUE_ERR = 1;

  static const int SVG_MATRIX_NOT_INVERTABLE = 2;

  static const int SVG_WRONG_TYPE_ERR = 0;


  /** @domName SVGException.code */
  int get code native "SVGException_code_Getter";


  /** @domName SVGException.message */
  String get message native "SVGException_message_Getter";


  /** @domName SVGException.name */
  String get name native "SVGException_name_Getter";


  /** @domName SVGException.toString */
  String toString() native "SVGException_toString_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SVGSVGElement
class SvgSvgElement extends SvgElement implements FitToViewBox, Tests, Stylable, Locatable, ExternalResourcesRequired, ZoomAndPan, LangSpace {
  factory SvgSvgElement() => _SvgSvgElementFactoryProvider.createSvgSvgElement();

  SvgSvgElement.internal(): super.internal();


  /** @domName SVGSVGElement.contentScriptType */
  String get contentScriptType native "SVGSVGElement_contentScriptType_Getter";


  /** @domName SVGSVGElement.contentScriptType */
  void set contentScriptType(String value) native "SVGSVGElement_contentScriptType_Setter";


  /** @domName SVGSVGElement.contentStyleType */
  String get contentStyleType native "SVGSVGElement_contentStyleType_Getter";


  /** @domName SVGSVGElement.contentStyleType */
  void set contentStyleType(String value) native "SVGSVGElement_contentStyleType_Setter";


  /** @domName SVGSVGElement.currentScale */
  num get currentScale native "SVGSVGElement_currentScale_Getter";


  /** @domName SVGSVGElement.currentScale */
  void set currentScale(num value) native "SVGSVGElement_currentScale_Setter";


  /** @domName SVGSVGElement.currentTranslate */
  Point get currentTranslate native "SVGSVGElement_currentTranslate_Getter";


  /** @domName SVGSVGElement.currentView */
  ViewSpec get currentView native "SVGSVGElement_currentView_Getter";


  /** @domName SVGSVGElement.height */
  AnimatedLength get height native "SVGSVGElement_height_Getter";


  /** @domName SVGSVGElement.pixelUnitToMillimeterX */
  num get pixelUnitToMillimeterX native "SVGSVGElement_pixelUnitToMillimeterX_Getter";


  /** @domName SVGSVGElement.pixelUnitToMillimeterY */
  num get pixelUnitToMillimeterY native "SVGSVGElement_pixelUnitToMillimeterY_Getter";


  /** @domName SVGSVGElement.screenPixelToMillimeterX */
  num get screenPixelToMillimeterX native "SVGSVGElement_screenPixelToMillimeterX_Getter";


  /** @domName SVGSVGElement.screenPixelToMillimeterY */
  num get screenPixelToMillimeterY native "SVGSVGElement_screenPixelToMillimeterY_Getter";


  /** @domName SVGSVGElement.useCurrentView */
  bool get useCurrentView native "SVGSVGElement_useCurrentView_Getter";


  /** @domName SVGSVGElement.viewport */
  Rect get viewport native "SVGSVGElement_viewport_Getter";


  /** @domName SVGSVGElement.width */
  AnimatedLength get width native "SVGSVGElement_width_Getter";


  /** @domName SVGSVGElement.x */
  AnimatedLength get x native "SVGSVGElement_x_Getter";


  /** @domName SVGSVGElement.y */
  AnimatedLength get y native "SVGSVGElement_y_Getter";


  /** @domName SVGSVGElement.animationsPaused */
  bool animationsPaused() native "SVGSVGElement_animationsPaused_Callback";


  /** @domName SVGSVGElement.checkEnclosure */
  bool checkEnclosure(SvgElement element, Rect rect) native "SVGSVGElement_checkEnclosure_Callback";


  /** @domName SVGSVGElement.checkIntersection */
  bool checkIntersection(SvgElement element, Rect rect) native "SVGSVGElement_checkIntersection_Callback";


  /** @domName SVGSVGElement.createSVGAngle */
  Angle createSvgAngle() native "SVGSVGElement_createSVGAngle_Callback";


  /** @domName SVGSVGElement.createSVGLength */
  Length createSvgLength() native "SVGSVGElement_createSVGLength_Callback";


  /** @domName SVGSVGElement.createSVGMatrix */
  Matrix createSvgMatrix() native "SVGSVGElement_createSVGMatrix_Callback";


  /** @domName SVGSVGElement.createSVGNumber */
  Number createSvgNumber() native "SVGSVGElement_createSVGNumber_Callback";


  /** @domName SVGSVGElement.createSVGPoint */
  Point createSvgPoint() native "SVGSVGElement_createSVGPoint_Callback";


  /** @domName SVGSVGElement.createSVGRect */
  Rect createSvgRect() native "SVGSVGElement_createSVGRect_Callback";


  /** @domName SVGSVGElement.createSVGTransform */
  Transform createSvgTransform() native "SVGSVGElement_createSVGTransform_Callback";


  /** @domName SVGSVGElement.createSVGTransformFromMatrix */
  Transform createSvgTransformFromMatrix(Matrix matrix) native "SVGSVGElement_createSVGTransformFromMatrix_Callback";


  /** @domName SVGSVGElement.deselectAll */
  void deselectAll() native "SVGSVGElement_deselectAll_Callback";


  /** @domName SVGSVGElement.forceRedraw */
  void forceRedraw() native "SVGSVGElement_forceRedraw_Callback";


  /** @domName SVGSVGElement.getCurrentTime */
  num getCurrentTime() native "SVGSVGElement_getCurrentTime_Callback";


  /** @domName SVGSVGElement.getElementById */
  Element getElementById(String elementId) native "SVGSVGElement_getElementById_Callback";


  /** @domName SVGSVGElement.getEnclosureList */
  List<Node> getEnclosureList(Rect rect, SvgElement referenceElement) native "SVGSVGElement_getEnclosureList_Callback";


  /** @domName SVGSVGElement.getIntersectionList */
  List<Node> getIntersectionList(Rect rect, SvgElement referenceElement) native "SVGSVGElement_getIntersectionList_Callback";


  /** @domName SVGSVGElement.pauseAnimations */
  void pauseAnimations() native "SVGSVGElement_pauseAnimations_Callback";


  /** @domName SVGSVGElement.setCurrentTime */
  void setCurrentTime(num seconds) native "SVGSVGElement_setCurrentTime_Callback";


  /** @domName SVGSVGElement.suspendRedraw */
  int suspendRedraw(int maxWaitMilliseconds) native "SVGSVGElement_suspendRedraw_Callback";


  /** @domName SVGSVGElement.unpauseAnimations */
  void unpauseAnimations() native "SVGSVGElement_unpauseAnimations_Callback";


  /** @domName SVGSVGElement.unsuspendRedraw */
  void unsuspendRedraw(int suspendHandleId) native "SVGSVGElement_unsuspendRedraw_Callback";


  /** @domName SVGSVGElement.unsuspendRedrawAll */
  void unsuspendRedrawAll() native "SVGSVGElement_unsuspendRedrawAll_Callback";


  /** @domName SVGSVGElement.externalResourcesRequired */
  AnimatedBoolean get externalResourcesRequired native "SVGSVGElement_externalResourcesRequired_Getter";


  /** @domName SVGSVGElement.preserveAspectRatio */
  AnimatedPreserveAspectRatio get preserveAspectRatio native "SVGSVGElement_preserveAspectRatio_Getter";


  /** @domName SVGSVGElement.viewBox */
  AnimatedRect get viewBox native "SVGSVGElement_viewBox_Getter";


  /** @domName SVGSVGElement.xmllang */
  String get xmllang native "SVGSVGElement_xmllang_Getter";


  /** @domName SVGSVGElement.xmllang */
  void set xmllang(String value) native "SVGSVGElement_xmllang_Setter";


  /** @domName SVGSVGElement.xmlspace */
  String get xmlspace native "SVGSVGElement_xmlspace_Getter";


  /** @domName SVGSVGElement.xmlspace */
  void set xmlspace(String value) native "SVGSVGElement_xmlspace_Setter";


  /** @domName SVGSVGElement.farthestViewportElement */
  SvgElement get farthestViewportElement native "SVGSVGElement_farthestViewportElement_Getter";


  /** @domName SVGSVGElement.nearestViewportElement */
  SvgElement get nearestViewportElement native "SVGSVGElement_nearestViewportElement_Getter";


  /** @domName SVGSVGElement.getBBox */
  Rect getBBox() native "SVGSVGElement_getBBox_Callback";


  /** @domName SVGSVGElement.getCTM */
  Matrix getCtm() native "SVGSVGElement_getCTM_Callback";


  /** @domName SVGSVGElement.getScreenCTM */
  Matrix getScreenCtm() native "SVGSVGElement_getScreenCTM_Callback";


  /** @domName SVGSVGElement.getTransformToElement */
  Matrix getTransformToElement(SvgElement element) native "SVGSVGElement_getTransformToElement_Callback";


  /** @domName SVGSVGElement.className */
  AnimatedString get $dom_svgClassName native "SVGSVGElement_className_Getter";


  /** @domName SVGSVGElement.style */
  CSSStyleDeclaration get style native "SVGSVGElement_style_Getter";


  /** @domName SVGSVGElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGSVGElement_getPresentationAttribute_Callback";


  /** @domName SVGSVGElement.requiredExtensions */
  StringList get requiredExtensions native "SVGSVGElement_requiredExtensions_Getter";


  /** @domName SVGSVGElement.requiredFeatures */
  StringList get requiredFeatures native "SVGSVGElement_requiredFeatures_Getter";


  /** @domName SVGSVGElement.systemLanguage */
  StringList get systemLanguage native "SVGSVGElement_systemLanguage_Getter";


  /** @domName SVGSVGElement.hasExtension */
  bool hasExtension(String extension) native "SVGSVGElement_hasExtension_Callback";


  /** @domName SVGSVGElement.zoomAndPan */
  int get zoomAndPan native "SVGSVGElement_zoomAndPan_Getter";


  /** @domName SVGSVGElement.zoomAndPan */
  void set zoomAndPan(int value) native "SVGSVGElement_zoomAndPan_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGSwitchElement
class SwitchElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace {

  factory SwitchElement() => _SvgElementFactoryProvider.createSvgElement_tag("switch");
  SwitchElement.internal(): super.internal();


  /** @domName SVGSwitchElement.externalResourcesRequired */
  AnimatedBoolean get externalResourcesRequired native "SVGSwitchElement_externalResourcesRequired_Getter";


  /** @domName SVGSwitchElement.xmllang */
  String get xmllang native "SVGSwitchElement_xmllang_Getter";


  /** @domName SVGSwitchElement.xmllang */
  void set xmllang(String value) native "SVGSwitchElement_xmllang_Setter";


  /** @domName SVGSwitchElement.xmlspace */
  String get xmlspace native "SVGSwitchElement_xmlspace_Getter";


  /** @domName SVGSwitchElement.xmlspace */
  void set xmlspace(String value) native "SVGSwitchElement_xmlspace_Setter";


  /** @domName SVGSwitchElement.farthestViewportElement */
  SvgElement get farthestViewportElement native "SVGSwitchElement_farthestViewportElement_Getter";


  /** @domName SVGSwitchElement.nearestViewportElement */
  SvgElement get nearestViewportElement native "SVGSwitchElement_nearestViewportElement_Getter";


  /** @domName SVGSwitchElement.getBBox */
  Rect getBBox() native "SVGSwitchElement_getBBox_Callback";


  /** @domName SVGSwitchElement.getCTM */
  Matrix getCtm() native "SVGSwitchElement_getCTM_Callback";


  /** @domName SVGSwitchElement.getScreenCTM */
  Matrix getScreenCtm() native "SVGSwitchElement_getScreenCTM_Callback";


  /** @domName SVGSwitchElement.getTransformToElement */
  Matrix getTransformToElement(SvgElement element) native "SVGSwitchElement_getTransformToElement_Callback";


  /** @domName SVGSwitchElement.className */
  AnimatedString get $dom_svgClassName native "SVGSwitchElement_className_Getter";


  /** @domName SVGSwitchElement.style */
  CSSStyleDeclaration get style native "SVGSwitchElement_style_Getter";


  /** @domName SVGSwitchElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGSwitchElement_getPresentationAttribute_Callback";


  /** @domName SVGSwitchElement.requiredExtensions */
  StringList get requiredExtensions native "SVGSwitchElement_requiredExtensions_Getter";


  /** @domName SVGSwitchElement.requiredFeatures */
  StringList get requiredFeatures native "SVGSwitchElement_requiredFeatures_Getter";


  /** @domName SVGSwitchElement.systemLanguage */
  StringList get systemLanguage native "SVGSwitchElement_systemLanguage_Getter";


  /** @domName SVGSwitchElement.hasExtension */
  bool hasExtension(String extension) native "SVGSwitchElement_hasExtension_Callback";


  /** @domName SVGSwitchElement.transform */
  AnimatedTransformList get transform native "SVGSwitchElement_transform_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGSymbolElement
class SymbolElement extends SvgElement implements FitToViewBox, ExternalResourcesRequired, Stylable, LangSpace {

  factory SymbolElement() => _SvgElementFactoryProvider.createSvgElement_tag("symbol");
  SymbolElement.internal(): super.internal();


  /** @domName SVGSymbolElement.externalResourcesRequired */
  AnimatedBoolean get externalResourcesRequired native "SVGSymbolElement_externalResourcesRequired_Getter";


  /** @domName SVGSymbolElement.preserveAspectRatio */
  AnimatedPreserveAspectRatio get preserveAspectRatio native "SVGSymbolElement_preserveAspectRatio_Getter";


  /** @domName SVGSymbolElement.viewBox */
  AnimatedRect get viewBox native "SVGSymbolElement_viewBox_Getter";


  /** @domName SVGSymbolElement.xmllang */
  String get xmllang native "SVGSymbolElement_xmllang_Getter";


  /** @domName SVGSymbolElement.xmllang */
  void set xmllang(String value) native "SVGSymbolElement_xmllang_Setter";


  /** @domName SVGSymbolElement.xmlspace */
  String get xmlspace native "SVGSymbolElement_xmlspace_Getter";


  /** @domName SVGSymbolElement.xmlspace */
  void set xmlspace(String value) native "SVGSymbolElement_xmlspace_Setter";


  /** @domName SVGSymbolElement.className */
  AnimatedString get $dom_svgClassName native "SVGSymbolElement_className_Getter";


  /** @domName SVGSymbolElement.style */
  CSSStyleDeclaration get style native "SVGSymbolElement_style_Getter";


  /** @domName SVGSymbolElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGSymbolElement_getPresentationAttribute_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGTRefElement
class TRefElement extends TextPositioningElement implements UriReference {

  factory TRefElement() => _SvgElementFactoryProvider.createSvgElement_tag("tref");
  TRefElement.internal(): super.internal();


  /** @domName SVGTRefElement.href */
  AnimatedString get href native "SVGTRefElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGTSpanElement
class TSpanElement extends TextPositioningElement {

  factory TSpanElement() => _SvgElementFactoryProvider.createSvgElement_tag("tspan");
  TSpanElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGTests
class Tests extends NativeFieldWrapperClass1 {
  Tests.internal();


  /** @domName SVGTests.requiredExtensions */
  StringList get requiredExtensions native "SVGTests_requiredExtensions_Getter";


  /** @domName SVGTests.requiredFeatures */
  StringList get requiredFeatures native "SVGTests_requiredFeatures_Getter";


  /** @domName SVGTests.systemLanguage */
  StringList get systemLanguage native "SVGTests_systemLanguage_Getter";


  /** @domName SVGTests.hasExtension */
  bool hasExtension(String extension) native "SVGTests_hasExtension_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGTextContentElement
class TextContentElement extends SvgElement implements Tests, Stylable, ExternalResourcesRequired, LangSpace {
  TextContentElement.internal(): super.internal();

  static const int LENGTHADJUST_SPACING = 1;

  static const int LENGTHADJUST_SPACINGANDGLYPHS = 2;

  static const int LENGTHADJUST_UNKNOWN = 0;


  /** @domName SVGTextContentElement.lengthAdjust */
  AnimatedEnumeration get lengthAdjust native "SVGTextContentElement_lengthAdjust_Getter";


  /** @domName SVGTextContentElement.textLength */
  AnimatedLength get textLength native "SVGTextContentElement_textLength_Getter";


  /** @domName SVGTextContentElement.getCharNumAtPosition */
  int getCharNumAtPosition(Point point) native "SVGTextContentElement_getCharNumAtPosition_Callback";


  /** @domName SVGTextContentElement.getComputedTextLength */
  num getComputedTextLength() native "SVGTextContentElement_getComputedTextLength_Callback";


  /** @domName SVGTextContentElement.getEndPositionOfChar */
  Point getEndPositionOfChar(int offset) native "SVGTextContentElement_getEndPositionOfChar_Callback";


  /** @domName SVGTextContentElement.getExtentOfChar */
  Rect getExtentOfChar(int offset) native "SVGTextContentElement_getExtentOfChar_Callback";


  /** @domName SVGTextContentElement.getNumberOfChars */
  int getNumberOfChars() native "SVGTextContentElement_getNumberOfChars_Callback";


  /** @domName SVGTextContentElement.getRotationOfChar */
  num getRotationOfChar(int offset) native "SVGTextContentElement_getRotationOfChar_Callback";


  /** @domName SVGTextContentElement.getStartPositionOfChar */
  Point getStartPositionOfChar(int offset) native "SVGTextContentElement_getStartPositionOfChar_Callback";


  /** @domName SVGTextContentElement.getSubStringLength */
  num getSubStringLength(int offset, int length) native "SVGTextContentElement_getSubStringLength_Callback";


  /** @domName SVGTextContentElement.selectSubString */
  void selectSubString(int offset, int length) native "SVGTextContentElement_selectSubString_Callback";


  /** @domName SVGTextContentElement.externalResourcesRequired */
  AnimatedBoolean get externalResourcesRequired native "SVGTextContentElement_externalResourcesRequired_Getter";


  /** @domName SVGTextContentElement.xmllang */
  String get xmllang native "SVGTextContentElement_xmllang_Getter";


  /** @domName SVGTextContentElement.xmllang */
  void set xmllang(String value) native "SVGTextContentElement_xmllang_Setter";


  /** @domName SVGTextContentElement.xmlspace */
  String get xmlspace native "SVGTextContentElement_xmlspace_Getter";


  /** @domName SVGTextContentElement.xmlspace */
  void set xmlspace(String value) native "SVGTextContentElement_xmlspace_Setter";


  /** @domName SVGTextContentElement.className */
  AnimatedString get $dom_svgClassName native "SVGTextContentElement_className_Getter";


  /** @domName SVGTextContentElement.style */
  CSSStyleDeclaration get style native "SVGTextContentElement_style_Getter";


  /** @domName SVGTextContentElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGTextContentElement_getPresentationAttribute_Callback";


  /** @domName SVGTextContentElement.requiredExtensions */
  StringList get requiredExtensions native "SVGTextContentElement_requiredExtensions_Getter";


  /** @domName SVGTextContentElement.requiredFeatures */
  StringList get requiredFeatures native "SVGTextContentElement_requiredFeatures_Getter";


  /** @domName SVGTextContentElement.systemLanguage */
  StringList get systemLanguage native "SVGTextContentElement_systemLanguage_Getter";


  /** @domName SVGTextContentElement.hasExtension */
  bool hasExtension(String extension) native "SVGTextContentElement_hasExtension_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGTextElement
class TextElement extends TextPositioningElement implements Transformable {

  factory TextElement() => _SvgElementFactoryProvider.createSvgElement_tag("text");
  TextElement.internal(): super.internal();


  /** @domName SVGTextElement.farthestViewportElement */
  SvgElement get farthestViewportElement native "SVGTextElement_farthestViewportElement_Getter";


  /** @domName SVGTextElement.nearestViewportElement */
  SvgElement get nearestViewportElement native "SVGTextElement_nearestViewportElement_Getter";


  /** @domName SVGTextElement.getBBox */
  Rect getBBox() native "SVGTextElement_getBBox_Callback";


  /** @domName SVGTextElement.getCTM */
  Matrix getCtm() native "SVGTextElement_getCTM_Callback";


  /** @domName SVGTextElement.getScreenCTM */
  Matrix getScreenCtm() native "SVGTextElement_getScreenCTM_Callback";


  /** @domName SVGTextElement.getTransformToElement */
  Matrix getTransformToElement(SvgElement element) native "SVGTextElement_getTransformToElement_Callback";


  /** @domName SVGTextElement.transform */
  AnimatedTransformList get transform native "SVGTextElement_transform_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGTextPathElement
class TextPathElement extends TextContentElement implements UriReference {
  TextPathElement.internal(): super.internal();

  static const int TEXTPATH_METHODTYPE_ALIGN = 1;

  static const int TEXTPATH_METHODTYPE_STRETCH = 2;

  static const int TEXTPATH_METHODTYPE_UNKNOWN = 0;

  static const int TEXTPATH_SPACINGTYPE_AUTO = 1;

  static const int TEXTPATH_SPACINGTYPE_EXACT = 2;

  static const int TEXTPATH_SPACINGTYPE_UNKNOWN = 0;


  /** @domName SVGTextPathElement.method */
  AnimatedEnumeration get method native "SVGTextPathElement_method_Getter";


  /** @domName SVGTextPathElement.spacing */
  AnimatedEnumeration get spacing native "SVGTextPathElement_spacing_Getter";


  /** @domName SVGTextPathElement.startOffset */
  AnimatedLength get startOffset native "SVGTextPathElement_startOffset_Getter";


  /** @domName SVGTextPathElement.href */
  AnimatedString get href native "SVGTextPathElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGTextPositioningElement
class TextPositioningElement extends TextContentElement {
  TextPositioningElement.internal(): super.internal();


  /** @domName SVGTextPositioningElement.dx */
  AnimatedLengthList get dx native "SVGTextPositioningElement_dx_Getter";


  /** @domName SVGTextPositioningElement.dy */
  AnimatedLengthList get dy native "SVGTextPositioningElement_dy_Getter";


  /** @domName SVGTextPositioningElement.rotate */
  AnimatedNumberList get rotate native "SVGTextPositioningElement_rotate_Getter";


  /** @domName SVGTextPositioningElement.x */
  AnimatedLengthList get x native "SVGTextPositioningElement_x_Getter";


  /** @domName SVGTextPositioningElement.y */
  AnimatedLengthList get y native "SVGTextPositioningElement_y_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGTitleElement
class TitleElement extends SvgElement implements Stylable, LangSpace {

  factory TitleElement() => _SvgElementFactoryProvider.createSvgElement_tag("title");
  TitleElement.internal(): super.internal();


  /** @domName SVGTitleElement.xmllang */
  String get xmllang native "SVGTitleElement_xmllang_Getter";


  /** @domName SVGTitleElement.xmllang */
  void set xmllang(String value) native "SVGTitleElement_xmllang_Setter";


  /** @domName SVGTitleElement.xmlspace */
  String get xmlspace native "SVGTitleElement_xmlspace_Getter";


  /** @domName SVGTitleElement.xmlspace */
  void set xmlspace(String value) native "SVGTitleElement_xmlspace_Setter";


  /** @domName SVGTitleElement.className */
  AnimatedString get $dom_svgClassName native "SVGTitleElement_className_Getter";


  /** @domName SVGTitleElement.style */
  CSSStyleDeclaration get style native "SVGTitleElement_style_Getter";


  /** @domName SVGTitleElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGTitleElement_getPresentationAttribute_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGTransform
class Transform extends NativeFieldWrapperClass1 {
  Transform.internal();

  static const int SVG_TRANSFORM_MATRIX = 1;

  static const int SVG_TRANSFORM_ROTATE = 4;

  static const int SVG_TRANSFORM_SCALE = 3;

  static const int SVG_TRANSFORM_SKEWX = 5;

  static const int SVG_TRANSFORM_SKEWY = 6;

  static const int SVG_TRANSFORM_TRANSLATE = 2;

  static const int SVG_TRANSFORM_UNKNOWN = 0;


  /** @domName SVGTransform.angle */
  num get angle native "SVGTransform_angle_Getter";


  /** @domName SVGTransform.matrix */
  Matrix get matrix native "SVGTransform_matrix_Getter";


  /** @domName SVGTransform.type */
  int get type native "SVGTransform_type_Getter";


  /** @domName SVGTransform.setMatrix */
  void setMatrix(Matrix matrix) native "SVGTransform_setMatrix_Callback";


  /** @domName SVGTransform.setRotate */
  void setRotate(num angle, num cx, num cy) native "SVGTransform_setRotate_Callback";


  /** @domName SVGTransform.setScale */
  void setScale(num sx, num sy) native "SVGTransform_setScale_Callback";


  /** @domName SVGTransform.setSkewX */
  void setSkewX(num angle) native "SVGTransform_setSkewX_Callback";


  /** @domName SVGTransform.setSkewY */
  void setSkewY(num angle) native "SVGTransform_setSkewY_Callback";


  /** @domName SVGTransform.setTranslate */
  void setTranslate(num tx, num ty) native "SVGTransform_setTranslate_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGTransformList
class TransformList extends NativeFieldWrapperClass1 implements List<Transform> {
  TransformList.internal();


  /** @domName SVGTransformList.numberOfItems */
  int get numberOfItems native "SVGTransformList_numberOfItems_Getter";

  Transform operator[](int index) native "SVGTransformList_item_Callback";

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

  bool contains(Transform element) => Collections.contains(this, element);

  void forEach(void f(Transform element)) => Collections.forEach(this, f);

  Collection map(f(Transform element)) => Collections.map(this, [], f);

  Collection<Transform> filter(bool f(Transform element)) =>
     Collections.filter(this, <Transform>[], f);

  bool every(bool f(Transform element)) => Collections.every(this, f);

  bool some(bool f(Transform element)) => Collections.some(this, f);

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
  Transform appendItem(Transform item) native "SVGTransformList_appendItem_Callback";


  /** @domName SVGTransformList.clear */
  void clear() native "SVGTransformList_clear_Callback";


  /** @domName SVGTransformList.consolidate */
  Transform consolidate() native "SVGTransformList_consolidate_Callback";


  /** @domName SVGTransformList.createSVGTransformFromMatrix */
  Transform createSvgTransformFromMatrix(Matrix matrix) native "SVGTransformList_createSVGTransformFromMatrix_Callback";


  /** @domName SVGTransformList.getItem */
  Transform getItem(int index) native "SVGTransformList_getItem_Callback";


  /** @domName SVGTransformList.initialize */
  Transform initialize(Transform item) native "SVGTransformList_initialize_Callback";


  /** @domName SVGTransformList.insertItemBefore */
  Transform insertItemBefore(Transform item, int index) native "SVGTransformList_insertItemBefore_Callback";


  /** @domName SVGTransformList.removeItem */
  Transform removeItem(int index) native "SVGTransformList_removeItem_Callback";


  /** @domName SVGTransformList.replaceItem */
  Transform replaceItem(Transform item, int index) native "SVGTransformList_replaceItem_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGTransformable
class Transformable extends NativeFieldWrapperClass1 implements Locatable {
  Transformable.internal();


  /** @domName SVGTransformable.transform */
  AnimatedTransformList get transform native "SVGTransformable_transform_Getter";


  /** @domName SVGTransformable.farthestViewportElement */
  SvgElement get farthestViewportElement native "SVGTransformable_farthestViewportElement_Getter";


  /** @domName SVGTransformable.nearestViewportElement */
  SvgElement get nearestViewportElement native "SVGTransformable_nearestViewportElement_Getter";


  /** @domName SVGTransformable.getBBox */
  Rect getBBox() native "SVGTransformable_getBBox_Callback";


  /** @domName SVGTransformable.getCTM */
  Matrix getCtm() native "SVGTransformable_getCTM_Callback";


  /** @domName SVGTransformable.getScreenCTM */
  Matrix getScreenCtm() native "SVGTransformable_getScreenCTM_Callback";


  /** @domName SVGTransformable.getTransformToElement */
  Matrix getTransformToElement(SvgElement element) native "SVGTransformable_getTransformToElement_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGUnitTypes
class UnitTypes extends NativeFieldWrapperClass1 {
  UnitTypes.internal();

  static const int SVG_UNIT_TYPE_OBJECTBOUNDINGBOX = 2;

  static const int SVG_UNIT_TYPE_UNKNOWN = 0;

  static const int SVG_UNIT_TYPE_USERSPACEONUSE = 1;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGURIReference
class UriReference extends NativeFieldWrapperClass1 {
  UriReference.internal();


  /** @domName SVGURIReference.href */
  AnimatedString get href native "SVGURIReference_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGUseElement
class UseElement extends SvgElement implements Transformable, Tests, UriReference, Stylable, ExternalResourcesRequired, LangSpace {

  factory UseElement() => _SvgElementFactoryProvider.createSvgElement_tag("use");
  UseElement.internal(): super.internal();


  /** @domName SVGUseElement.animatedInstanceRoot */
  ElementInstance get animatedInstanceRoot native "SVGUseElement_animatedInstanceRoot_Getter";


  /** @domName SVGUseElement.height */
  AnimatedLength get height native "SVGUseElement_height_Getter";


  /** @domName SVGUseElement.instanceRoot */
  ElementInstance get instanceRoot native "SVGUseElement_instanceRoot_Getter";


  /** @domName SVGUseElement.width */
  AnimatedLength get width native "SVGUseElement_width_Getter";


  /** @domName SVGUseElement.x */
  AnimatedLength get x native "SVGUseElement_x_Getter";


  /** @domName SVGUseElement.y */
  AnimatedLength get y native "SVGUseElement_y_Getter";


  /** @domName SVGUseElement.externalResourcesRequired */
  AnimatedBoolean get externalResourcesRequired native "SVGUseElement_externalResourcesRequired_Getter";


  /** @domName SVGUseElement.xmllang */
  String get xmllang native "SVGUseElement_xmllang_Getter";


  /** @domName SVGUseElement.xmllang */
  void set xmllang(String value) native "SVGUseElement_xmllang_Setter";


  /** @domName SVGUseElement.xmlspace */
  String get xmlspace native "SVGUseElement_xmlspace_Getter";


  /** @domName SVGUseElement.xmlspace */
  void set xmlspace(String value) native "SVGUseElement_xmlspace_Setter";


  /** @domName SVGUseElement.farthestViewportElement */
  SvgElement get farthestViewportElement native "SVGUseElement_farthestViewportElement_Getter";


  /** @domName SVGUseElement.nearestViewportElement */
  SvgElement get nearestViewportElement native "SVGUseElement_nearestViewportElement_Getter";


  /** @domName SVGUseElement.getBBox */
  Rect getBBox() native "SVGUseElement_getBBox_Callback";


  /** @domName SVGUseElement.getCTM */
  Matrix getCtm() native "SVGUseElement_getCTM_Callback";


  /** @domName SVGUseElement.getScreenCTM */
  Matrix getScreenCtm() native "SVGUseElement_getScreenCTM_Callback";


  /** @domName SVGUseElement.getTransformToElement */
  Matrix getTransformToElement(SvgElement element) native "SVGUseElement_getTransformToElement_Callback";


  /** @domName SVGUseElement.className */
  AnimatedString get $dom_svgClassName native "SVGUseElement_className_Getter";


  /** @domName SVGUseElement.style */
  CSSStyleDeclaration get style native "SVGUseElement_style_Getter";


  /** @domName SVGUseElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGUseElement_getPresentationAttribute_Callback";


  /** @domName SVGUseElement.requiredExtensions */
  StringList get requiredExtensions native "SVGUseElement_requiredExtensions_Getter";


  /** @domName SVGUseElement.requiredFeatures */
  StringList get requiredFeatures native "SVGUseElement_requiredFeatures_Getter";


  /** @domName SVGUseElement.systemLanguage */
  StringList get systemLanguage native "SVGUseElement_systemLanguage_Getter";


  /** @domName SVGUseElement.hasExtension */
  bool hasExtension(String extension) native "SVGUseElement_hasExtension_Callback";


  /** @domName SVGUseElement.transform */
  AnimatedTransformList get transform native "SVGUseElement_transform_Getter";


  /** @domName SVGUseElement.href */
  AnimatedString get href native "SVGUseElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGVKernElement
class VKernElement extends SvgElement {

  factory VKernElement() => _SvgElementFactoryProvider.createSvgElement_tag("vkern");
  VKernElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGViewElement
class ViewElement extends SvgElement implements FitToViewBox, ExternalResourcesRequired, ZoomAndPan {

  factory ViewElement() => _SvgElementFactoryProvider.createSvgElement_tag("view");
  ViewElement.internal(): super.internal();


  /** @domName SVGViewElement.viewTarget */
  StringList get viewTarget native "SVGViewElement_viewTarget_Getter";


  /** @domName SVGViewElement.externalResourcesRequired */
  AnimatedBoolean get externalResourcesRequired native "SVGViewElement_externalResourcesRequired_Getter";


  /** @domName SVGViewElement.preserveAspectRatio */
  AnimatedPreserveAspectRatio get preserveAspectRatio native "SVGViewElement_preserveAspectRatio_Getter";


  /** @domName SVGViewElement.viewBox */
  AnimatedRect get viewBox native "SVGViewElement_viewBox_Getter";


  /** @domName SVGViewElement.zoomAndPan */
  int get zoomAndPan native "SVGViewElement_zoomAndPan_Getter";


  /** @domName SVGViewElement.zoomAndPan */
  void set zoomAndPan(int value) native "SVGViewElement_zoomAndPan_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGViewSpec
class ViewSpec extends NativeFieldWrapperClass1 {
  ViewSpec.internal();


  /** @domName SVGViewSpec.preserveAspectRatio */
  AnimatedPreserveAspectRatio get preserveAspectRatio native "SVGViewSpec_preserveAspectRatio_Getter";


  /** @domName SVGViewSpec.preserveAspectRatioString */
  String get preserveAspectRatioString native "SVGViewSpec_preserveAspectRatioString_Getter";


  /** @domName SVGViewSpec.transform */
  TransformList get transform native "SVGViewSpec_transform_Getter";


  /** @domName SVGViewSpec.transformString */
  String get transformString native "SVGViewSpec_transformString_Getter";


  /** @domName SVGViewSpec.viewBox */
  AnimatedRect get viewBox native "SVGViewSpec_viewBox_Getter";


  /** @domName SVGViewSpec.viewBoxString */
  String get viewBoxString native "SVGViewSpec_viewBoxString_Getter";


  /** @domName SVGViewSpec.viewTarget */
  SvgElement get viewTarget native "SVGViewSpec_viewTarget_Getter";


  /** @domName SVGViewSpec.viewTargetString */
  String get viewTargetString native "SVGViewSpec_viewTargetString_Getter";


  /** @domName SVGViewSpec.zoomAndPan */
  int get zoomAndPan native "SVGViewSpec_zoomAndPan_Getter";


  /** @domName SVGViewSpec.zoomAndPan */
  void set zoomAndPan(int value) native "SVGViewSpec_zoomAndPan_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGZoomAndPan
class ZoomAndPan extends NativeFieldWrapperClass1 {
  ZoomAndPan.internal();

  static const int SVG_ZOOMANDPAN_DISABLE = 1;

  static const int SVG_ZOOMANDPAN_MAGNIFY = 2;

  static const int SVG_ZOOMANDPAN_UNKNOWN = 0;


  /** @domName SVGZoomAndPan.zoomAndPan */
  int get zoomAndPan native "SVGZoomAndPan_zoomAndPan_Getter";


  /** @domName SVGZoomAndPan.zoomAndPan */
  void set zoomAndPan(int value) native "SVGZoomAndPan_zoomAndPan_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGZoomEvent
class ZoomEvent extends UIEvent {
  ZoomEvent.internal(): super.internal();


  /** @domName SVGZoomEvent.newScale */
  num get newScale native "SVGZoomEvent_newScale_Getter";


  /** @domName SVGZoomEvent.newTranslate */
  Point get newTranslate native "SVGZoomEvent_newTranslate_Getter";


  /** @domName SVGZoomEvent.previousScale */
  num get previousScale native "SVGZoomEvent_previousScale_Getter";


  /** @domName SVGZoomEvent.previousTranslate */
  Point get previousTranslate native "SVGZoomEvent_previousTranslate_Getter";


  /** @domName SVGZoomEvent.zoomRectScreen */
  Rect get zoomRectScreen native "SVGZoomEvent_zoomRectScreen_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGElementInstanceList
class _ElementInstanceList extends NativeFieldWrapperClass1 implements List<ElementInstance> {
  _ElementInstanceList.internal();


  /** @domName SVGElementInstanceList.length */
  int get length native "SVGElementInstanceList_length_Getter";

  ElementInstance operator[](int index) native "SVGElementInstanceList_item_Callback";

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

  bool contains(ElementInstance element) => Collections.contains(this, element);

  void forEach(void f(ElementInstance element)) => Collections.forEach(this, f);

  Collection map(f(ElementInstance element)) => Collections.map(this, [], f);

  Collection<ElementInstance> filter(bool f(ElementInstance element)) =>
     Collections.filter(this, <ElementInstance>[], f);

  bool every(bool f(ElementInstance element)) => Collections.every(this, f);

  bool some(bool f(ElementInstance element)) => Collections.some(this, f);

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
  ElementInstance item(int index) native "SVGElementInstanceList_item_Callback";

}
