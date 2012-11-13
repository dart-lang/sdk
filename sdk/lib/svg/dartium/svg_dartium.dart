library svg;

import 'dart:html';
import 'dart:nativewrappers';
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

// WARNING: Do not edit - generated code.


/// @domName SVGAElement
class SVGAElement extends SVGElement implements SVGLangSpace, SVGTests, SVGStylable, SVGURIReference, SVGExternalResourcesRequired, SVGTransformable {
  SVGAElement.internal(): super.internal();


  /** @domName SVGAElement.target */
  SVGAnimatedString get target native "SVGAElement_target_Getter";


  /** @domName SVGAElement.externalResourcesRequired */
  SVGAnimatedBoolean get externalResourcesRequired native "SVGAElement_externalResourcesRequired_Getter";


  /** @domName SVGAElement.xmllang */
  String get xmllang native "SVGAElement_xmllang_Getter";


  /** @domName SVGAElement.xmllang */
  void set xmllang(String value) native "SVGAElement_xmllang_Setter";


  /** @domName SVGAElement.xmlspace */
  String get xmlspace native "SVGAElement_xmlspace_Getter";


  /** @domName SVGAElement.xmlspace */
  void set xmlspace(String value) native "SVGAElement_xmlspace_Setter";


  /** @domName SVGAElement.farthestViewportElement */
  SVGElement get farthestViewportElement native "SVGAElement_farthestViewportElement_Getter";


  /** @domName SVGAElement.nearestViewportElement */
  SVGElement get nearestViewportElement native "SVGAElement_nearestViewportElement_Getter";


  /** @domName SVGAElement.getBBox */
  SVGRect getBBox() native "SVGAElement_getBBox_Callback";


  /** @domName SVGAElement.getCTM */
  SVGMatrix getCTM() native "SVGAElement_getCTM_Callback";


  /** @domName SVGAElement.getScreenCTM */
  SVGMatrix getScreenCTM() native "SVGAElement_getScreenCTM_Callback";


  /** @domName SVGAElement.getTransformToElement */
  SVGMatrix getTransformToElement(SVGElement element) native "SVGAElement_getTransformToElement_Callback";


  /** @domName SVGAElement.className */
  SVGAnimatedString get $dom_svgClassName native "SVGAElement_className_Getter";


  /** @domName SVGAElement.style */
  CSSStyleDeclaration get style native "SVGAElement_style_Getter";


  /** @domName SVGAElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGAElement_getPresentationAttribute_Callback";


  /** @domName SVGAElement.requiredExtensions */
  SVGStringList get requiredExtensions native "SVGAElement_requiredExtensions_Getter";


  /** @domName SVGAElement.requiredFeatures */
  SVGStringList get requiredFeatures native "SVGAElement_requiredFeatures_Getter";


  /** @domName SVGAElement.systemLanguage */
  SVGStringList get systemLanguage native "SVGAElement_systemLanguage_Getter";


  /** @domName SVGAElement.hasExtension */
  bool hasExtension(String extension) native "SVGAElement_hasExtension_Callback";


  /** @domName SVGAElement.transform */
  SVGAnimatedTransformList get transform native "SVGAElement_transform_Getter";


  /** @domName SVGAElement.href */
  SVGAnimatedString get href native "SVGAElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGAltGlyphDefElement
class SVGAltGlyphDefElement extends SVGElement {
  SVGAltGlyphDefElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGAltGlyphElement
class SVGAltGlyphElement extends SVGTextPositioningElement implements SVGURIReference {
  SVGAltGlyphElement.internal(): super.internal();


  /** @domName SVGAltGlyphElement.format */
  String get format native "SVGAltGlyphElement_format_Getter";


  /** @domName SVGAltGlyphElement.format */
  void set format(String value) native "SVGAltGlyphElement_format_Setter";


  /** @domName SVGAltGlyphElement.glyphRef */
  String get glyphRef native "SVGAltGlyphElement_glyphRef_Getter";


  /** @domName SVGAltGlyphElement.glyphRef */
  void set glyphRef(String value) native "SVGAltGlyphElement_glyphRef_Setter";


  /** @domName SVGAltGlyphElement.href */
  SVGAnimatedString get href native "SVGAltGlyphElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGAltGlyphItemElement
class SVGAltGlyphItemElement extends SVGElement {
  SVGAltGlyphItemElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGAngle
class SVGAngle extends NativeFieldWrapperClass1 {
  SVGAngle.internal();

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
class SVGAnimateColorElement extends SVGAnimationElement {
  SVGAnimateColorElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGAnimateElement
class SVGAnimateElement extends SVGAnimationElement {
  SVGAnimateElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGAnimateMotionElement
class SVGAnimateMotionElement extends SVGAnimationElement {
  SVGAnimateMotionElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGAnimateTransformElement
class SVGAnimateTransformElement extends SVGAnimationElement {
  SVGAnimateTransformElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGAnimatedAngle
class SVGAnimatedAngle extends NativeFieldWrapperClass1 {
  SVGAnimatedAngle.internal();


  /** @domName SVGAnimatedAngle.animVal */
  SVGAngle get animVal native "SVGAnimatedAngle_animVal_Getter";


  /** @domName SVGAnimatedAngle.baseVal */
  SVGAngle get baseVal native "SVGAnimatedAngle_baseVal_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGAnimatedBoolean
class SVGAnimatedBoolean extends NativeFieldWrapperClass1 {
  SVGAnimatedBoolean.internal();


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
class SVGAnimatedEnumeration extends NativeFieldWrapperClass1 {
  SVGAnimatedEnumeration.internal();


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
class SVGAnimatedInteger extends NativeFieldWrapperClass1 {
  SVGAnimatedInteger.internal();


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
class SVGAnimatedLength extends NativeFieldWrapperClass1 {
  SVGAnimatedLength.internal();


  /** @domName SVGAnimatedLength.animVal */
  SVGLength get animVal native "SVGAnimatedLength_animVal_Getter";


  /** @domName SVGAnimatedLength.baseVal */
  SVGLength get baseVal native "SVGAnimatedLength_baseVal_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGAnimatedLengthList
class SVGAnimatedLengthList extends NativeFieldWrapperClass1 implements List<SVGAnimatedLength> {
  SVGAnimatedLengthList.internal();


  /** @domName SVGAnimatedLengthList.animVal */
  SVGLengthList get animVal native "SVGAnimatedLengthList_animVal_Getter";


  /** @domName SVGAnimatedLengthList.baseVal */
  SVGLengthList get baseVal native "SVGAnimatedLengthList_baseVal_Getter";

  SVGAnimatedLength operator[](int index) native "SVGAnimatedLengthList_item_Callback";

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

// WARNING: Do not edit - generated code.


/// @domName SVGAnimatedNumber
class SVGAnimatedNumber extends NativeFieldWrapperClass1 {
  SVGAnimatedNumber.internal();


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
class SVGAnimatedNumberList extends NativeFieldWrapperClass1 implements List<SVGAnimatedNumber> {
  SVGAnimatedNumberList.internal();


  /** @domName SVGAnimatedNumberList.animVal */
  SVGNumberList get animVal native "SVGAnimatedNumberList_animVal_Getter";


  /** @domName SVGAnimatedNumberList.baseVal */
  SVGNumberList get baseVal native "SVGAnimatedNumberList_baseVal_Getter";

  SVGAnimatedNumber operator[](int index) native "SVGAnimatedNumberList_item_Callback";

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

// WARNING: Do not edit - generated code.


/// @domName SVGAnimatedPreserveAspectRatio
class SVGAnimatedPreserveAspectRatio extends NativeFieldWrapperClass1 {
  SVGAnimatedPreserveAspectRatio.internal();


  /** @domName SVGAnimatedPreserveAspectRatio.animVal */
  SVGPreserveAspectRatio get animVal native "SVGAnimatedPreserveAspectRatio_animVal_Getter";


  /** @domName SVGAnimatedPreserveAspectRatio.baseVal */
  SVGPreserveAspectRatio get baseVal native "SVGAnimatedPreserveAspectRatio_baseVal_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGAnimatedRect
class SVGAnimatedRect extends NativeFieldWrapperClass1 {
  SVGAnimatedRect.internal();


  /** @domName SVGAnimatedRect.animVal */
  SVGRect get animVal native "SVGAnimatedRect_animVal_Getter";


  /** @domName SVGAnimatedRect.baseVal */
  SVGRect get baseVal native "SVGAnimatedRect_baseVal_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGAnimatedString
class SVGAnimatedString extends NativeFieldWrapperClass1 {
  SVGAnimatedString.internal();


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
class SVGAnimatedTransformList extends NativeFieldWrapperClass1 implements List<SVGAnimateTransformElement> {
  SVGAnimatedTransformList.internal();


  /** @domName SVGAnimatedTransformList.animVal */
  SVGTransformList get animVal native "SVGAnimatedTransformList_animVal_Getter";


  /** @domName SVGAnimatedTransformList.baseVal */
  SVGTransformList get baseVal native "SVGAnimatedTransformList_baseVal_Getter";

  SVGAnimateTransformElement operator[](int index) native "SVGAnimatedTransformList_item_Callback";

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

// WARNING: Do not edit - generated code.


/// @domName SVGAnimationElement
class SVGAnimationElement extends SVGElement implements ElementTimeControl, SVGTests, SVGExternalResourcesRequired {
  SVGAnimationElement.internal(): super.internal();


  /** @domName SVGAnimationElement.targetElement */
  SVGElement get targetElement native "SVGAnimationElement_targetElement_Getter";


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
  SVGAnimatedBoolean get externalResourcesRequired native "SVGAnimationElement_externalResourcesRequired_Getter";


  /** @domName SVGAnimationElement.requiredExtensions */
  SVGStringList get requiredExtensions native "SVGAnimationElement_requiredExtensions_Getter";


  /** @domName SVGAnimationElement.requiredFeatures */
  SVGStringList get requiredFeatures native "SVGAnimationElement_requiredFeatures_Getter";


  /** @domName SVGAnimationElement.systemLanguage */
  SVGStringList get systemLanguage native "SVGAnimationElement_systemLanguage_Getter";


  /** @domName SVGAnimationElement.hasExtension */
  bool hasExtension(String extension) native "SVGAnimationElement_hasExtension_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGCircleElement
class SVGCircleElement extends SVGElement implements SVGLangSpace, SVGStylable, SVGTests, SVGTransformable, SVGExternalResourcesRequired {
  SVGCircleElement.internal(): super.internal();


  /** @domName SVGCircleElement.cx */
  SVGAnimatedLength get cx native "SVGCircleElement_cx_Getter";


  /** @domName SVGCircleElement.cy */
  SVGAnimatedLength get cy native "SVGCircleElement_cy_Getter";


  /** @domName SVGCircleElement.r */
  SVGAnimatedLength get r native "SVGCircleElement_r_Getter";


  /** @domName SVGCircleElement.externalResourcesRequired */
  SVGAnimatedBoolean get externalResourcesRequired native "SVGCircleElement_externalResourcesRequired_Getter";


  /** @domName SVGCircleElement.xmllang */
  String get xmllang native "SVGCircleElement_xmllang_Getter";


  /** @domName SVGCircleElement.xmllang */
  void set xmllang(String value) native "SVGCircleElement_xmllang_Setter";


  /** @domName SVGCircleElement.xmlspace */
  String get xmlspace native "SVGCircleElement_xmlspace_Getter";


  /** @domName SVGCircleElement.xmlspace */
  void set xmlspace(String value) native "SVGCircleElement_xmlspace_Setter";


  /** @domName SVGCircleElement.farthestViewportElement */
  SVGElement get farthestViewportElement native "SVGCircleElement_farthestViewportElement_Getter";


  /** @domName SVGCircleElement.nearestViewportElement */
  SVGElement get nearestViewportElement native "SVGCircleElement_nearestViewportElement_Getter";


  /** @domName SVGCircleElement.getBBox */
  SVGRect getBBox() native "SVGCircleElement_getBBox_Callback";


  /** @domName SVGCircleElement.getCTM */
  SVGMatrix getCTM() native "SVGCircleElement_getCTM_Callback";


  /** @domName SVGCircleElement.getScreenCTM */
  SVGMatrix getScreenCTM() native "SVGCircleElement_getScreenCTM_Callback";


  /** @domName SVGCircleElement.getTransformToElement */
  SVGMatrix getTransformToElement(SVGElement element) native "SVGCircleElement_getTransformToElement_Callback";


  /** @domName SVGCircleElement.className */
  SVGAnimatedString get $dom_svgClassName native "SVGCircleElement_className_Getter";


  /** @domName SVGCircleElement.style */
  CSSStyleDeclaration get style native "SVGCircleElement_style_Getter";


  /** @domName SVGCircleElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGCircleElement_getPresentationAttribute_Callback";


  /** @domName SVGCircleElement.requiredExtensions */
  SVGStringList get requiredExtensions native "SVGCircleElement_requiredExtensions_Getter";


  /** @domName SVGCircleElement.requiredFeatures */
  SVGStringList get requiredFeatures native "SVGCircleElement_requiredFeatures_Getter";


  /** @domName SVGCircleElement.systemLanguage */
  SVGStringList get systemLanguage native "SVGCircleElement_systemLanguage_Getter";


  /** @domName SVGCircleElement.hasExtension */
  bool hasExtension(String extension) native "SVGCircleElement_hasExtension_Callback";


  /** @domName SVGCircleElement.transform */
  SVGAnimatedTransformList get transform native "SVGCircleElement_transform_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGClipPathElement
class SVGClipPathElement extends SVGElement implements SVGLangSpace, SVGStylable, SVGTests, SVGTransformable, SVGExternalResourcesRequired {
  SVGClipPathElement.internal(): super.internal();


  /** @domName SVGClipPathElement.clipPathUnits */
  SVGAnimatedEnumeration get clipPathUnits native "SVGClipPathElement_clipPathUnits_Getter";


  /** @domName SVGClipPathElement.externalResourcesRequired */
  SVGAnimatedBoolean get externalResourcesRequired native "SVGClipPathElement_externalResourcesRequired_Getter";


  /** @domName SVGClipPathElement.xmllang */
  String get xmllang native "SVGClipPathElement_xmllang_Getter";


  /** @domName SVGClipPathElement.xmllang */
  void set xmllang(String value) native "SVGClipPathElement_xmllang_Setter";


  /** @domName SVGClipPathElement.xmlspace */
  String get xmlspace native "SVGClipPathElement_xmlspace_Getter";


  /** @domName SVGClipPathElement.xmlspace */
  void set xmlspace(String value) native "SVGClipPathElement_xmlspace_Setter";


  /** @domName SVGClipPathElement.farthestViewportElement */
  SVGElement get farthestViewportElement native "SVGClipPathElement_farthestViewportElement_Getter";


  /** @domName SVGClipPathElement.nearestViewportElement */
  SVGElement get nearestViewportElement native "SVGClipPathElement_nearestViewportElement_Getter";


  /** @domName SVGClipPathElement.getBBox */
  SVGRect getBBox() native "SVGClipPathElement_getBBox_Callback";


  /** @domName SVGClipPathElement.getCTM */
  SVGMatrix getCTM() native "SVGClipPathElement_getCTM_Callback";


  /** @domName SVGClipPathElement.getScreenCTM */
  SVGMatrix getScreenCTM() native "SVGClipPathElement_getScreenCTM_Callback";


  /** @domName SVGClipPathElement.getTransformToElement */
  SVGMatrix getTransformToElement(SVGElement element) native "SVGClipPathElement_getTransformToElement_Callback";


  /** @domName SVGClipPathElement.className */
  SVGAnimatedString get $dom_svgClassName native "SVGClipPathElement_className_Getter";


  /** @domName SVGClipPathElement.style */
  CSSStyleDeclaration get style native "SVGClipPathElement_style_Getter";


  /** @domName SVGClipPathElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGClipPathElement_getPresentationAttribute_Callback";


  /** @domName SVGClipPathElement.requiredExtensions */
  SVGStringList get requiredExtensions native "SVGClipPathElement_requiredExtensions_Getter";


  /** @domName SVGClipPathElement.requiredFeatures */
  SVGStringList get requiredFeatures native "SVGClipPathElement_requiredFeatures_Getter";


  /** @domName SVGClipPathElement.systemLanguage */
  SVGStringList get systemLanguage native "SVGClipPathElement_systemLanguage_Getter";


  /** @domName SVGClipPathElement.hasExtension */
  bool hasExtension(String extension) native "SVGClipPathElement_hasExtension_Callback";


  /** @domName SVGClipPathElement.transform */
  SVGAnimatedTransformList get transform native "SVGClipPathElement_transform_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGColor
class SVGColor extends CSSValue {
  SVGColor.internal(): super.internal();

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
  void setRGBColor(String rgbColor) native "SVGColor_setRGBColor_Callback";


  /** @domName SVGColor.setRGBColorICCColor */
  void setRGBColorICCColor(String rgbColor, String iccColor) native "SVGColor_setRGBColorICCColor_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGComponentTransferFunctionElement
class SVGComponentTransferFunctionElement extends SVGElement {
  SVGComponentTransferFunctionElement.internal(): super.internal();

  static const int SVG_FECOMPONENTTRANSFER_TYPE_DISCRETE = 3;

  static const int SVG_FECOMPONENTTRANSFER_TYPE_GAMMA = 5;

  static const int SVG_FECOMPONENTTRANSFER_TYPE_IDENTITY = 1;

  static const int SVG_FECOMPONENTTRANSFER_TYPE_LINEAR = 4;

  static const int SVG_FECOMPONENTTRANSFER_TYPE_TABLE = 2;

  static const int SVG_FECOMPONENTTRANSFER_TYPE_UNKNOWN = 0;


  /** @domName SVGComponentTransferFunctionElement.amplitude */
  SVGAnimatedNumber get amplitude native "SVGComponentTransferFunctionElement_amplitude_Getter";


  /** @domName SVGComponentTransferFunctionElement.exponent */
  SVGAnimatedNumber get exponent native "SVGComponentTransferFunctionElement_exponent_Getter";


  /** @domName SVGComponentTransferFunctionElement.intercept */
  SVGAnimatedNumber get intercept native "SVGComponentTransferFunctionElement_intercept_Getter";


  /** @domName SVGComponentTransferFunctionElement.offset */
  SVGAnimatedNumber get offset native "SVGComponentTransferFunctionElement_offset_Getter";


  /** @domName SVGComponentTransferFunctionElement.slope */
  SVGAnimatedNumber get slope native "SVGComponentTransferFunctionElement_slope_Getter";


  /** @domName SVGComponentTransferFunctionElement.tableValues */
  SVGAnimatedNumberList get tableValues native "SVGComponentTransferFunctionElement_tableValues_Getter";


  /** @domName SVGComponentTransferFunctionElement.type */
  SVGAnimatedEnumeration get type native "SVGComponentTransferFunctionElement_type_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGCursorElement
class SVGCursorElement extends SVGElement implements SVGURIReference, SVGTests, SVGExternalResourcesRequired {
  SVGCursorElement.internal(): super.internal();


  /** @domName SVGCursorElement.x */
  SVGAnimatedLength get x native "SVGCursorElement_x_Getter";


  /** @domName SVGCursorElement.y */
  SVGAnimatedLength get y native "SVGCursorElement_y_Getter";


  /** @domName SVGCursorElement.externalResourcesRequired */
  SVGAnimatedBoolean get externalResourcesRequired native "SVGCursorElement_externalResourcesRequired_Getter";


  /** @domName SVGCursorElement.requiredExtensions */
  SVGStringList get requiredExtensions native "SVGCursorElement_requiredExtensions_Getter";


  /** @domName SVGCursorElement.requiredFeatures */
  SVGStringList get requiredFeatures native "SVGCursorElement_requiredFeatures_Getter";


  /** @domName SVGCursorElement.systemLanguage */
  SVGStringList get systemLanguage native "SVGCursorElement_systemLanguage_Getter";


  /** @domName SVGCursorElement.hasExtension */
  bool hasExtension(String extension) native "SVGCursorElement_hasExtension_Callback";


  /** @domName SVGCursorElement.href */
  SVGAnimatedString get href native "SVGCursorElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGDefsElement
class SVGDefsElement extends SVGElement implements SVGLangSpace, SVGStylable, SVGTests, SVGTransformable, SVGExternalResourcesRequired {
  SVGDefsElement.internal(): super.internal();


  /** @domName SVGDefsElement.externalResourcesRequired */
  SVGAnimatedBoolean get externalResourcesRequired native "SVGDefsElement_externalResourcesRequired_Getter";


  /** @domName SVGDefsElement.xmllang */
  String get xmllang native "SVGDefsElement_xmllang_Getter";


  /** @domName SVGDefsElement.xmllang */
  void set xmllang(String value) native "SVGDefsElement_xmllang_Setter";


  /** @domName SVGDefsElement.xmlspace */
  String get xmlspace native "SVGDefsElement_xmlspace_Getter";


  /** @domName SVGDefsElement.xmlspace */
  void set xmlspace(String value) native "SVGDefsElement_xmlspace_Setter";


  /** @domName SVGDefsElement.farthestViewportElement */
  SVGElement get farthestViewportElement native "SVGDefsElement_farthestViewportElement_Getter";


  /** @domName SVGDefsElement.nearestViewportElement */
  SVGElement get nearestViewportElement native "SVGDefsElement_nearestViewportElement_Getter";


  /** @domName SVGDefsElement.getBBox */
  SVGRect getBBox() native "SVGDefsElement_getBBox_Callback";


  /** @domName SVGDefsElement.getCTM */
  SVGMatrix getCTM() native "SVGDefsElement_getCTM_Callback";


  /** @domName SVGDefsElement.getScreenCTM */
  SVGMatrix getScreenCTM() native "SVGDefsElement_getScreenCTM_Callback";


  /** @domName SVGDefsElement.getTransformToElement */
  SVGMatrix getTransformToElement(SVGElement element) native "SVGDefsElement_getTransformToElement_Callback";


  /** @domName SVGDefsElement.className */
  SVGAnimatedString get $dom_svgClassName native "SVGDefsElement_className_Getter";


  /** @domName SVGDefsElement.style */
  CSSStyleDeclaration get style native "SVGDefsElement_style_Getter";


  /** @domName SVGDefsElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGDefsElement_getPresentationAttribute_Callback";


  /** @domName SVGDefsElement.requiredExtensions */
  SVGStringList get requiredExtensions native "SVGDefsElement_requiredExtensions_Getter";


  /** @domName SVGDefsElement.requiredFeatures */
  SVGStringList get requiredFeatures native "SVGDefsElement_requiredFeatures_Getter";


  /** @domName SVGDefsElement.systemLanguage */
  SVGStringList get systemLanguage native "SVGDefsElement_systemLanguage_Getter";


  /** @domName SVGDefsElement.hasExtension */
  bool hasExtension(String extension) native "SVGDefsElement_hasExtension_Callback";


  /** @domName SVGDefsElement.transform */
  SVGAnimatedTransformList get transform native "SVGDefsElement_transform_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGDescElement
class SVGDescElement extends SVGElement implements SVGLangSpace, SVGStylable {
  SVGDescElement.internal(): super.internal();


  /** @domName SVGDescElement.xmllang */
  String get xmllang native "SVGDescElement_xmllang_Getter";


  /** @domName SVGDescElement.xmllang */
  void set xmllang(String value) native "SVGDescElement_xmllang_Setter";


  /** @domName SVGDescElement.xmlspace */
  String get xmlspace native "SVGDescElement_xmlspace_Getter";


  /** @domName SVGDescElement.xmlspace */
  void set xmlspace(String value) native "SVGDescElement_xmlspace_Setter";


  /** @domName SVGDescElement.className */
  SVGAnimatedString get $dom_svgClassName native "SVGDescElement_className_Getter";


  /** @domName SVGDescElement.style */
  CSSStyleDeclaration get style native "SVGDescElement_style_Getter";


  /** @domName SVGDescElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGDescElement_getPresentationAttribute_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGDocument
class SVGDocument extends Document {
  SVGDocument.internal(): super.internal();


  /** @domName SVGDocument.rootElement */
  SVGSVGElement get rootElement native "SVGDocument_rootElement_Getter";


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
    for (String name in classname.split(' ')) {
      String trimmed = name.trim();
      if (!trimmed.isEmpty) {
        s.add(trimmed);
      }
    }
    return s;
  }

  void writeClasses(Set s) {
    _element.attributes['class'] = _formatSet(s);
  }
}

class SVGElement extends Element {
  factory SVGElement.tag(String tag) =>
      _SVGElementFactoryProvider.createSVGElement_tag(tag);
  factory SVGElement.svg(String svg) =>
      _SVGElementFactoryProvider.createSVGElement_svg(svg);

  CssClassSet get classes {
    if (_cssClassSet == null) {
      _cssClassSet = new _AttributeClassSet(_ptr);
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

  SVGElement.internal(): super.internal();


  /** @domName SVGElement.id */
  String get id native "SVGElement_id_Getter";


  /** @domName SVGElement.id */
  void set id(String value) native "SVGElement_id_Setter";


  /** @domName SVGElement.ownerSVGElement */
  SVGSVGElement get ownerSVGElement native "SVGElement_ownerSVGElement_Getter";


  /** @domName SVGElement.viewportElement */
  SVGElement get viewportElement native "SVGElement_viewportElement_Getter";


  /** @domName SVGElement.xmlbase */
  String get xmlbase native "SVGElement_xmlbase_Getter";


  /** @domName SVGElement.xmlbase */
  void set xmlbase(String value) native "SVGElement_xmlbase_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGElementInstance
class SVGElementInstance extends EventTarget {
  SVGElementInstance.internal(): super.internal();

  /**
   * @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent
   */
  SVGElementInstanceEvents get on =>
    new SVGElementInstanceEvents(this);


  /** @domName SVGElementInstance.childNodes */
  List<SVGElementInstance> get childNodes native "SVGElementInstance_childNodes_Getter";


  /** @domName SVGElementInstance.correspondingElement */
  SVGElement get correspondingElement native "SVGElementInstance_correspondingElement_Getter";


  /** @domName SVGElementInstance.correspondingUseElement */
  SVGUseElement get correspondingUseElement native "SVGElementInstance_correspondingUseElement_Getter";


  /** @domName SVGElementInstance.firstChild */
  SVGElementInstance get firstChild native "SVGElementInstance_firstChild_Getter";


  /** @domName SVGElementInstance.lastChild */
  SVGElementInstance get lastChild native "SVGElementInstance_lastChild_Getter";


  /** @domName SVGElementInstance.nextSibling */
  SVGElementInstance get nextSibling native "SVGElementInstance_nextSibling_Getter";


  /** @domName SVGElementInstance.parentNode */
  SVGElementInstance get parentNode native "SVGElementInstance_parentNode_Getter";


  /** @domName SVGElementInstance.previousSibling */
  SVGElementInstance get previousSibling native "SVGElementInstance_previousSibling_Getter";

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

// WARNING: Do not edit - generated code.


/// @domName SVGEllipseElement
class SVGEllipseElement extends SVGElement implements SVGLangSpace, SVGStylable, SVGTests, SVGTransformable, SVGExternalResourcesRequired {
  SVGEllipseElement.internal(): super.internal();


  /** @domName SVGEllipseElement.cx */
  SVGAnimatedLength get cx native "SVGEllipseElement_cx_Getter";


  /** @domName SVGEllipseElement.cy */
  SVGAnimatedLength get cy native "SVGEllipseElement_cy_Getter";


  /** @domName SVGEllipseElement.rx */
  SVGAnimatedLength get rx native "SVGEllipseElement_rx_Getter";


  /** @domName SVGEllipseElement.ry */
  SVGAnimatedLength get ry native "SVGEllipseElement_ry_Getter";


  /** @domName SVGEllipseElement.externalResourcesRequired */
  SVGAnimatedBoolean get externalResourcesRequired native "SVGEllipseElement_externalResourcesRequired_Getter";


  /** @domName SVGEllipseElement.xmllang */
  String get xmllang native "SVGEllipseElement_xmllang_Getter";


  /** @domName SVGEllipseElement.xmllang */
  void set xmllang(String value) native "SVGEllipseElement_xmllang_Setter";


  /** @domName SVGEllipseElement.xmlspace */
  String get xmlspace native "SVGEllipseElement_xmlspace_Getter";


  /** @domName SVGEllipseElement.xmlspace */
  void set xmlspace(String value) native "SVGEllipseElement_xmlspace_Setter";


  /** @domName SVGEllipseElement.farthestViewportElement */
  SVGElement get farthestViewportElement native "SVGEllipseElement_farthestViewportElement_Getter";


  /** @domName SVGEllipseElement.nearestViewportElement */
  SVGElement get nearestViewportElement native "SVGEllipseElement_nearestViewportElement_Getter";


  /** @domName SVGEllipseElement.getBBox */
  SVGRect getBBox() native "SVGEllipseElement_getBBox_Callback";


  /** @domName SVGEllipseElement.getCTM */
  SVGMatrix getCTM() native "SVGEllipseElement_getCTM_Callback";


  /** @domName SVGEllipseElement.getScreenCTM */
  SVGMatrix getScreenCTM() native "SVGEllipseElement_getScreenCTM_Callback";


  /** @domName SVGEllipseElement.getTransformToElement */
  SVGMatrix getTransformToElement(SVGElement element) native "SVGEllipseElement_getTransformToElement_Callback";


  /** @domName SVGEllipseElement.className */
  SVGAnimatedString get $dom_svgClassName native "SVGEllipseElement_className_Getter";


  /** @domName SVGEllipseElement.style */
  CSSStyleDeclaration get style native "SVGEllipseElement_style_Getter";


  /** @domName SVGEllipseElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGEllipseElement_getPresentationAttribute_Callback";


  /** @domName SVGEllipseElement.requiredExtensions */
  SVGStringList get requiredExtensions native "SVGEllipseElement_requiredExtensions_Getter";


  /** @domName SVGEllipseElement.requiredFeatures */
  SVGStringList get requiredFeatures native "SVGEllipseElement_requiredFeatures_Getter";


  /** @domName SVGEllipseElement.systemLanguage */
  SVGStringList get systemLanguage native "SVGEllipseElement_systemLanguage_Getter";


  /** @domName SVGEllipseElement.hasExtension */
  bool hasExtension(String extension) native "SVGEllipseElement_hasExtension_Callback";


  /** @domName SVGEllipseElement.transform */
  SVGAnimatedTransformList get transform native "SVGEllipseElement_transform_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGException
class SVGException extends NativeFieldWrapperClass1 {
  SVGException.internal();

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

// WARNING: Do not edit - generated code.


/// @domName SVGExternalResourcesRequired
class SVGExternalResourcesRequired extends NativeFieldWrapperClass1 {
  SVGExternalResourcesRequired.internal();


  /** @domName SVGExternalResourcesRequired.externalResourcesRequired */
  SVGAnimatedBoolean get externalResourcesRequired native "SVGExternalResourcesRequired_externalResourcesRequired_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFEBlendElement
class SVGFEBlendElement extends SVGElement implements SVGFilterPrimitiveStandardAttributes {
  SVGFEBlendElement.internal(): super.internal();

  static const int SVG_FEBLEND_MODE_DARKEN = 4;

  static const int SVG_FEBLEND_MODE_LIGHTEN = 5;

  static const int SVG_FEBLEND_MODE_MULTIPLY = 2;

  static const int SVG_FEBLEND_MODE_NORMAL = 1;

  static const int SVG_FEBLEND_MODE_SCREEN = 3;

  static const int SVG_FEBLEND_MODE_UNKNOWN = 0;


  /** @domName SVGFEBlendElement.in1 */
  SVGAnimatedString get in1 native "SVGFEBlendElement_in1_Getter";


  /** @domName SVGFEBlendElement.in2 */
  SVGAnimatedString get in2 native "SVGFEBlendElement_in2_Getter";


  /** @domName SVGFEBlendElement.mode */
  SVGAnimatedEnumeration get mode native "SVGFEBlendElement_mode_Getter";


  /** @domName SVGFEBlendElement.height */
  SVGAnimatedLength get height native "SVGFEBlendElement_height_Getter";


  /** @domName SVGFEBlendElement.result */
  SVGAnimatedString get result native "SVGFEBlendElement_result_Getter";


  /** @domName SVGFEBlendElement.width */
  SVGAnimatedLength get width native "SVGFEBlendElement_width_Getter";


  /** @domName SVGFEBlendElement.x */
  SVGAnimatedLength get x native "SVGFEBlendElement_x_Getter";


  /** @domName SVGFEBlendElement.y */
  SVGAnimatedLength get y native "SVGFEBlendElement_y_Getter";


  /** @domName SVGFEBlendElement.className */
  SVGAnimatedString get $dom_svgClassName native "SVGFEBlendElement_className_Getter";


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
class SVGFEColorMatrixElement extends SVGElement implements SVGFilterPrimitiveStandardAttributes {
  SVGFEColorMatrixElement.internal(): super.internal();

  static const int SVG_FECOLORMATRIX_TYPE_HUEROTATE = 3;

  static const int SVG_FECOLORMATRIX_TYPE_LUMINANCETOALPHA = 4;

  static const int SVG_FECOLORMATRIX_TYPE_MATRIX = 1;

  static const int SVG_FECOLORMATRIX_TYPE_SATURATE = 2;

  static const int SVG_FECOLORMATRIX_TYPE_UNKNOWN = 0;


  /** @domName SVGFEColorMatrixElement.in1 */
  SVGAnimatedString get in1 native "SVGFEColorMatrixElement_in1_Getter";


  /** @domName SVGFEColorMatrixElement.type */
  SVGAnimatedEnumeration get type native "SVGFEColorMatrixElement_type_Getter";


  /** @domName SVGFEColorMatrixElement.values */
  SVGAnimatedNumberList get values native "SVGFEColorMatrixElement_values_Getter";


  /** @domName SVGFEColorMatrixElement.height */
  SVGAnimatedLength get height native "SVGFEColorMatrixElement_height_Getter";


  /** @domName SVGFEColorMatrixElement.result */
  SVGAnimatedString get result native "SVGFEColorMatrixElement_result_Getter";


  /** @domName SVGFEColorMatrixElement.width */
  SVGAnimatedLength get width native "SVGFEColorMatrixElement_width_Getter";


  /** @domName SVGFEColorMatrixElement.x */
  SVGAnimatedLength get x native "SVGFEColorMatrixElement_x_Getter";


  /** @domName SVGFEColorMatrixElement.y */
  SVGAnimatedLength get y native "SVGFEColorMatrixElement_y_Getter";


  /** @domName SVGFEColorMatrixElement.className */
  SVGAnimatedString get $dom_svgClassName native "SVGFEColorMatrixElement_className_Getter";


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
class SVGFEComponentTransferElement extends SVGElement implements SVGFilterPrimitiveStandardAttributes {
  SVGFEComponentTransferElement.internal(): super.internal();


  /** @domName SVGFEComponentTransferElement.in1 */
  SVGAnimatedString get in1 native "SVGFEComponentTransferElement_in1_Getter";


  /** @domName SVGFEComponentTransferElement.height */
  SVGAnimatedLength get height native "SVGFEComponentTransferElement_height_Getter";


  /** @domName SVGFEComponentTransferElement.result */
  SVGAnimatedString get result native "SVGFEComponentTransferElement_result_Getter";


  /** @domName SVGFEComponentTransferElement.width */
  SVGAnimatedLength get width native "SVGFEComponentTransferElement_width_Getter";


  /** @domName SVGFEComponentTransferElement.x */
  SVGAnimatedLength get x native "SVGFEComponentTransferElement_x_Getter";


  /** @domName SVGFEComponentTransferElement.y */
  SVGAnimatedLength get y native "SVGFEComponentTransferElement_y_Getter";


  /** @domName SVGFEComponentTransferElement.className */
  SVGAnimatedString get $dom_svgClassName native "SVGFEComponentTransferElement_className_Getter";


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
class SVGFECompositeElement extends SVGElement implements SVGFilterPrimitiveStandardAttributes {
  SVGFECompositeElement.internal(): super.internal();

  static const int SVG_FECOMPOSITE_OPERATOR_ARITHMETIC = 6;

  static const int SVG_FECOMPOSITE_OPERATOR_ATOP = 4;

  static const int SVG_FECOMPOSITE_OPERATOR_IN = 2;

  static const int SVG_FECOMPOSITE_OPERATOR_OUT = 3;

  static const int SVG_FECOMPOSITE_OPERATOR_OVER = 1;

  static const int SVG_FECOMPOSITE_OPERATOR_UNKNOWN = 0;

  static const int SVG_FECOMPOSITE_OPERATOR_XOR = 5;


  /** @domName SVGFECompositeElement.in1 */
  SVGAnimatedString get in1 native "SVGFECompositeElement_in1_Getter";


  /** @domName SVGFECompositeElement.in2 */
  SVGAnimatedString get in2 native "SVGFECompositeElement_in2_Getter";


  /** @domName SVGFECompositeElement.k1 */
  SVGAnimatedNumber get k1 native "SVGFECompositeElement_k1_Getter";


  /** @domName SVGFECompositeElement.k2 */
  SVGAnimatedNumber get k2 native "SVGFECompositeElement_k2_Getter";


  /** @domName SVGFECompositeElement.k3 */
  SVGAnimatedNumber get k3 native "SVGFECompositeElement_k3_Getter";


  /** @domName SVGFECompositeElement.k4 */
  SVGAnimatedNumber get k4 native "SVGFECompositeElement_k4_Getter";


  /** @domName SVGFECompositeElement.operator */
  SVGAnimatedEnumeration get operator native "SVGFECompositeElement_operator_Getter";


  /** @domName SVGFECompositeElement.height */
  SVGAnimatedLength get height native "SVGFECompositeElement_height_Getter";


  /** @domName SVGFECompositeElement.result */
  SVGAnimatedString get result native "SVGFECompositeElement_result_Getter";


  /** @domName SVGFECompositeElement.width */
  SVGAnimatedLength get width native "SVGFECompositeElement_width_Getter";


  /** @domName SVGFECompositeElement.x */
  SVGAnimatedLength get x native "SVGFECompositeElement_x_Getter";


  /** @domName SVGFECompositeElement.y */
  SVGAnimatedLength get y native "SVGFECompositeElement_y_Getter";


  /** @domName SVGFECompositeElement.className */
  SVGAnimatedString get $dom_svgClassName native "SVGFECompositeElement_className_Getter";


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
class SVGFEConvolveMatrixElement extends SVGElement implements SVGFilterPrimitiveStandardAttributes {
  SVGFEConvolveMatrixElement.internal(): super.internal();

  static const int SVG_EDGEMODE_DUPLICATE = 1;

  static const int SVG_EDGEMODE_NONE = 3;

  static const int SVG_EDGEMODE_UNKNOWN = 0;

  static const int SVG_EDGEMODE_WRAP = 2;


  /** @domName SVGFEConvolveMatrixElement.bias */
  SVGAnimatedNumber get bias native "SVGFEConvolveMatrixElement_bias_Getter";


  /** @domName SVGFEConvolveMatrixElement.divisor */
  SVGAnimatedNumber get divisor native "SVGFEConvolveMatrixElement_divisor_Getter";


  /** @domName SVGFEConvolveMatrixElement.edgeMode */
  SVGAnimatedEnumeration get edgeMode native "SVGFEConvolveMatrixElement_edgeMode_Getter";


  /** @domName SVGFEConvolveMatrixElement.in1 */
  SVGAnimatedString get in1 native "SVGFEConvolveMatrixElement_in1_Getter";


  /** @domName SVGFEConvolveMatrixElement.kernelMatrix */
  SVGAnimatedNumberList get kernelMatrix native "SVGFEConvolveMatrixElement_kernelMatrix_Getter";


  /** @domName SVGFEConvolveMatrixElement.kernelUnitLengthX */
  SVGAnimatedNumber get kernelUnitLengthX native "SVGFEConvolveMatrixElement_kernelUnitLengthX_Getter";


  /** @domName SVGFEConvolveMatrixElement.kernelUnitLengthY */
  SVGAnimatedNumber get kernelUnitLengthY native "SVGFEConvolveMatrixElement_kernelUnitLengthY_Getter";


  /** @domName SVGFEConvolveMatrixElement.orderX */
  SVGAnimatedInteger get orderX native "SVGFEConvolveMatrixElement_orderX_Getter";


  /** @domName SVGFEConvolveMatrixElement.orderY */
  SVGAnimatedInteger get orderY native "SVGFEConvolveMatrixElement_orderY_Getter";


  /** @domName SVGFEConvolveMatrixElement.preserveAlpha */
  SVGAnimatedBoolean get preserveAlpha native "SVGFEConvolveMatrixElement_preserveAlpha_Getter";


  /** @domName SVGFEConvolveMatrixElement.targetX */
  SVGAnimatedInteger get targetX native "SVGFEConvolveMatrixElement_targetX_Getter";


  /** @domName SVGFEConvolveMatrixElement.targetY */
  SVGAnimatedInteger get targetY native "SVGFEConvolveMatrixElement_targetY_Getter";


  /** @domName SVGFEConvolveMatrixElement.height */
  SVGAnimatedLength get height native "SVGFEConvolveMatrixElement_height_Getter";


  /** @domName SVGFEConvolveMatrixElement.result */
  SVGAnimatedString get result native "SVGFEConvolveMatrixElement_result_Getter";


  /** @domName SVGFEConvolveMatrixElement.width */
  SVGAnimatedLength get width native "SVGFEConvolveMatrixElement_width_Getter";


  /** @domName SVGFEConvolveMatrixElement.x */
  SVGAnimatedLength get x native "SVGFEConvolveMatrixElement_x_Getter";


  /** @domName SVGFEConvolveMatrixElement.y */
  SVGAnimatedLength get y native "SVGFEConvolveMatrixElement_y_Getter";


  /** @domName SVGFEConvolveMatrixElement.className */
  SVGAnimatedString get $dom_svgClassName native "SVGFEConvolveMatrixElement_className_Getter";


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
class SVGFEDiffuseLightingElement extends SVGElement implements SVGFilterPrimitiveStandardAttributes {
  SVGFEDiffuseLightingElement.internal(): super.internal();


  /** @domName SVGFEDiffuseLightingElement.diffuseConstant */
  SVGAnimatedNumber get diffuseConstant native "SVGFEDiffuseLightingElement_diffuseConstant_Getter";


  /** @domName SVGFEDiffuseLightingElement.in1 */
  SVGAnimatedString get in1 native "SVGFEDiffuseLightingElement_in1_Getter";


  /** @domName SVGFEDiffuseLightingElement.kernelUnitLengthX */
  SVGAnimatedNumber get kernelUnitLengthX native "SVGFEDiffuseLightingElement_kernelUnitLengthX_Getter";


  /** @domName SVGFEDiffuseLightingElement.kernelUnitLengthY */
  SVGAnimatedNumber get kernelUnitLengthY native "SVGFEDiffuseLightingElement_kernelUnitLengthY_Getter";


  /** @domName SVGFEDiffuseLightingElement.surfaceScale */
  SVGAnimatedNumber get surfaceScale native "SVGFEDiffuseLightingElement_surfaceScale_Getter";


  /** @domName SVGFEDiffuseLightingElement.height */
  SVGAnimatedLength get height native "SVGFEDiffuseLightingElement_height_Getter";


  /** @domName SVGFEDiffuseLightingElement.result */
  SVGAnimatedString get result native "SVGFEDiffuseLightingElement_result_Getter";


  /** @domName SVGFEDiffuseLightingElement.width */
  SVGAnimatedLength get width native "SVGFEDiffuseLightingElement_width_Getter";


  /** @domName SVGFEDiffuseLightingElement.x */
  SVGAnimatedLength get x native "SVGFEDiffuseLightingElement_x_Getter";


  /** @domName SVGFEDiffuseLightingElement.y */
  SVGAnimatedLength get y native "SVGFEDiffuseLightingElement_y_Getter";


  /** @domName SVGFEDiffuseLightingElement.className */
  SVGAnimatedString get $dom_svgClassName native "SVGFEDiffuseLightingElement_className_Getter";


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
class SVGFEDisplacementMapElement extends SVGElement implements SVGFilterPrimitiveStandardAttributes {
  SVGFEDisplacementMapElement.internal(): super.internal();

  static const int SVG_CHANNEL_A = 4;

  static const int SVG_CHANNEL_B = 3;

  static const int SVG_CHANNEL_G = 2;

  static const int SVG_CHANNEL_R = 1;

  static const int SVG_CHANNEL_UNKNOWN = 0;


  /** @domName SVGFEDisplacementMapElement.in1 */
  SVGAnimatedString get in1 native "SVGFEDisplacementMapElement_in1_Getter";


  /** @domName SVGFEDisplacementMapElement.in2 */
  SVGAnimatedString get in2 native "SVGFEDisplacementMapElement_in2_Getter";


  /** @domName SVGFEDisplacementMapElement.scale */
  SVGAnimatedNumber get scale native "SVGFEDisplacementMapElement_scale_Getter";


  /** @domName SVGFEDisplacementMapElement.xChannelSelector */
  SVGAnimatedEnumeration get xChannelSelector native "SVGFEDisplacementMapElement_xChannelSelector_Getter";


  /** @domName SVGFEDisplacementMapElement.yChannelSelector */
  SVGAnimatedEnumeration get yChannelSelector native "SVGFEDisplacementMapElement_yChannelSelector_Getter";


  /** @domName SVGFEDisplacementMapElement.height */
  SVGAnimatedLength get height native "SVGFEDisplacementMapElement_height_Getter";


  /** @domName SVGFEDisplacementMapElement.result */
  SVGAnimatedString get result native "SVGFEDisplacementMapElement_result_Getter";


  /** @domName SVGFEDisplacementMapElement.width */
  SVGAnimatedLength get width native "SVGFEDisplacementMapElement_width_Getter";


  /** @domName SVGFEDisplacementMapElement.x */
  SVGAnimatedLength get x native "SVGFEDisplacementMapElement_x_Getter";


  /** @domName SVGFEDisplacementMapElement.y */
  SVGAnimatedLength get y native "SVGFEDisplacementMapElement_y_Getter";


  /** @domName SVGFEDisplacementMapElement.className */
  SVGAnimatedString get $dom_svgClassName native "SVGFEDisplacementMapElement_className_Getter";


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
class SVGFEDistantLightElement extends SVGElement {
  SVGFEDistantLightElement.internal(): super.internal();


  /** @domName SVGFEDistantLightElement.azimuth */
  SVGAnimatedNumber get azimuth native "SVGFEDistantLightElement_azimuth_Getter";


  /** @domName SVGFEDistantLightElement.elevation */
  SVGAnimatedNumber get elevation native "SVGFEDistantLightElement_elevation_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFEDropShadowElement
class SVGFEDropShadowElement extends SVGElement implements SVGFilterPrimitiveStandardAttributes {
  SVGFEDropShadowElement.internal(): super.internal();


  /** @domName SVGFEDropShadowElement.dx */
  SVGAnimatedNumber get dx native "SVGFEDropShadowElement_dx_Getter";


  /** @domName SVGFEDropShadowElement.dy */
  SVGAnimatedNumber get dy native "SVGFEDropShadowElement_dy_Getter";


  /** @domName SVGFEDropShadowElement.in1 */
  SVGAnimatedString get in1 native "SVGFEDropShadowElement_in1_Getter";


  /** @domName SVGFEDropShadowElement.stdDeviationX */
  SVGAnimatedNumber get stdDeviationX native "SVGFEDropShadowElement_stdDeviationX_Getter";


  /** @domName SVGFEDropShadowElement.stdDeviationY */
  SVGAnimatedNumber get stdDeviationY native "SVGFEDropShadowElement_stdDeviationY_Getter";


  /** @domName SVGFEDropShadowElement.setStdDeviation */
  void setStdDeviation(num stdDeviationX, num stdDeviationY) native "SVGFEDropShadowElement_setStdDeviation_Callback";


  /** @domName SVGFEDropShadowElement.height */
  SVGAnimatedLength get height native "SVGFEDropShadowElement_height_Getter";


  /** @domName SVGFEDropShadowElement.result */
  SVGAnimatedString get result native "SVGFEDropShadowElement_result_Getter";


  /** @domName SVGFEDropShadowElement.width */
  SVGAnimatedLength get width native "SVGFEDropShadowElement_width_Getter";


  /** @domName SVGFEDropShadowElement.x */
  SVGAnimatedLength get x native "SVGFEDropShadowElement_x_Getter";


  /** @domName SVGFEDropShadowElement.y */
  SVGAnimatedLength get y native "SVGFEDropShadowElement_y_Getter";


  /** @domName SVGFEDropShadowElement.className */
  SVGAnimatedString get $dom_svgClassName native "SVGFEDropShadowElement_className_Getter";


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
class SVGFEFloodElement extends SVGElement implements SVGFilterPrimitiveStandardAttributes {
  SVGFEFloodElement.internal(): super.internal();


  /** @domName SVGFEFloodElement.height */
  SVGAnimatedLength get height native "SVGFEFloodElement_height_Getter";


  /** @domName SVGFEFloodElement.result */
  SVGAnimatedString get result native "SVGFEFloodElement_result_Getter";


  /** @domName SVGFEFloodElement.width */
  SVGAnimatedLength get width native "SVGFEFloodElement_width_Getter";


  /** @domName SVGFEFloodElement.x */
  SVGAnimatedLength get x native "SVGFEFloodElement_x_Getter";


  /** @domName SVGFEFloodElement.y */
  SVGAnimatedLength get y native "SVGFEFloodElement_y_Getter";


  /** @domName SVGFEFloodElement.className */
  SVGAnimatedString get $dom_svgClassName native "SVGFEFloodElement_className_Getter";


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
class SVGFEFuncAElement extends SVGComponentTransferFunctionElement {
  SVGFEFuncAElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFEFuncBElement
class SVGFEFuncBElement extends SVGComponentTransferFunctionElement {
  SVGFEFuncBElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFEFuncGElement
class SVGFEFuncGElement extends SVGComponentTransferFunctionElement {
  SVGFEFuncGElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFEFuncRElement
class SVGFEFuncRElement extends SVGComponentTransferFunctionElement {
  SVGFEFuncRElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFEGaussianBlurElement
class SVGFEGaussianBlurElement extends SVGElement implements SVGFilterPrimitiveStandardAttributes {
  SVGFEGaussianBlurElement.internal(): super.internal();


  /** @domName SVGFEGaussianBlurElement.in1 */
  SVGAnimatedString get in1 native "SVGFEGaussianBlurElement_in1_Getter";


  /** @domName SVGFEGaussianBlurElement.stdDeviationX */
  SVGAnimatedNumber get stdDeviationX native "SVGFEGaussianBlurElement_stdDeviationX_Getter";


  /** @domName SVGFEGaussianBlurElement.stdDeviationY */
  SVGAnimatedNumber get stdDeviationY native "SVGFEGaussianBlurElement_stdDeviationY_Getter";


  /** @domName SVGFEGaussianBlurElement.setStdDeviation */
  void setStdDeviation(num stdDeviationX, num stdDeviationY) native "SVGFEGaussianBlurElement_setStdDeviation_Callback";


  /** @domName SVGFEGaussianBlurElement.height */
  SVGAnimatedLength get height native "SVGFEGaussianBlurElement_height_Getter";


  /** @domName SVGFEGaussianBlurElement.result */
  SVGAnimatedString get result native "SVGFEGaussianBlurElement_result_Getter";


  /** @domName SVGFEGaussianBlurElement.width */
  SVGAnimatedLength get width native "SVGFEGaussianBlurElement_width_Getter";


  /** @domName SVGFEGaussianBlurElement.x */
  SVGAnimatedLength get x native "SVGFEGaussianBlurElement_x_Getter";


  /** @domName SVGFEGaussianBlurElement.y */
  SVGAnimatedLength get y native "SVGFEGaussianBlurElement_y_Getter";


  /** @domName SVGFEGaussianBlurElement.className */
  SVGAnimatedString get $dom_svgClassName native "SVGFEGaussianBlurElement_className_Getter";


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
class SVGFEImageElement extends SVGElement implements SVGURIReference, SVGLangSpace, SVGFilterPrimitiveStandardAttributes, SVGExternalResourcesRequired {
  SVGFEImageElement.internal(): super.internal();


  /** @domName SVGFEImageElement.preserveAspectRatio */
  SVGAnimatedPreserveAspectRatio get preserveAspectRatio native "SVGFEImageElement_preserveAspectRatio_Getter";


  /** @domName SVGFEImageElement.externalResourcesRequired */
  SVGAnimatedBoolean get externalResourcesRequired native "SVGFEImageElement_externalResourcesRequired_Getter";


  /** @domName SVGFEImageElement.height */
  SVGAnimatedLength get height native "SVGFEImageElement_height_Getter";


  /** @domName SVGFEImageElement.result */
  SVGAnimatedString get result native "SVGFEImageElement_result_Getter";


  /** @domName SVGFEImageElement.width */
  SVGAnimatedLength get width native "SVGFEImageElement_width_Getter";


  /** @domName SVGFEImageElement.x */
  SVGAnimatedLength get x native "SVGFEImageElement_x_Getter";


  /** @domName SVGFEImageElement.y */
  SVGAnimatedLength get y native "SVGFEImageElement_y_Getter";


  /** @domName SVGFEImageElement.xmllang */
  String get xmllang native "SVGFEImageElement_xmllang_Getter";


  /** @domName SVGFEImageElement.xmllang */
  void set xmllang(String value) native "SVGFEImageElement_xmllang_Setter";


  /** @domName SVGFEImageElement.xmlspace */
  String get xmlspace native "SVGFEImageElement_xmlspace_Getter";


  /** @domName SVGFEImageElement.xmlspace */
  void set xmlspace(String value) native "SVGFEImageElement_xmlspace_Setter";


  /** @domName SVGFEImageElement.className */
  SVGAnimatedString get $dom_svgClassName native "SVGFEImageElement_className_Getter";


  /** @domName SVGFEImageElement.style */
  CSSStyleDeclaration get style native "SVGFEImageElement_style_Getter";


  /** @domName SVGFEImageElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGFEImageElement_getPresentationAttribute_Callback";


  /** @domName SVGFEImageElement.href */
  SVGAnimatedString get href native "SVGFEImageElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFEMergeElement
class SVGFEMergeElement extends SVGElement implements SVGFilterPrimitiveStandardAttributes {
  SVGFEMergeElement.internal(): super.internal();


  /** @domName SVGFEMergeElement.height */
  SVGAnimatedLength get height native "SVGFEMergeElement_height_Getter";


  /** @domName SVGFEMergeElement.result */
  SVGAnimatedString get result native "SVGFEMergeElement_result_Getter";


  /** @domName SVGFEMergeElement.width */
  SVGAnimatedLength get width native "SVGFEMergeElement_width_Getter";


  /** @domName SVGFEMergeElement.x */
  SVGAnimatedLength get x native "SVGFEMergeElement_x_Getter";


  /** @domName SVGFEMergeElement.y */
  SVGAnimatedLength get y native "SVGFEMergeElement_y_Getter";


  /** @domName SVGFEMergeElement.className */
  SVGAnimatedString get $dom_svgClassName native "SVGFEMergeElement_className_Getter";


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
class SVGFEMergeNodeElement extends SVGElement {
  SVGFEMergeNodeElement.internal(): super.internal();


  /** @domName SVGFEMergeNodeElement.in1 */
  SVGAnimatedString get in1 native "SVGFEMergeNodeElement_in1_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFEMorphologyElement
class SVGFEMorphologyElement extends SVGElement implements SVGFilterPrimitiveStandardAttributes {
  SVGFEMorphologyElement.internal(): super.internal();

  static const int SVG_MORPHOLOGY_OPERATOR_DILATE = 2;

  static const int SVG_MORPHOLOGY_OPERATOR_ERODE = 1;

  static const int SVG_MORPHOLOGY_OPERATOR_UNKNOWN = 0;


  /** @domName SVGFEMorphologyElement.in1 */
  SVGAnimatedString get in1 native "SVGFEMorphologyElement_in1_Getter";


  /** @domName SVGFEMorphologyElement.operator */
  SVGAnimatedEnumeration get operator native "SVGFEMorphologyElement_operator_Getter";


  /** @domName SVGFEMorphologyElement.radiusX */
  SVGAnimatedNumber get radiusX native "SVGFEMorphologyElement_radiusX_Getter";


  /** @domName SVGFEMorphologyElement.radiusY */
  SVGAnimatedNumber get radiusY native "SVGFEMorphologyElement_radiusY_Getter";


  /** @domName SVGFEMorphologyElement.setRadius */
  void setRadius(num radiusX, num radiusY) native "SVGFEMorphologyElement_setRadius_Callback";


  /** @domName SVGFEMorphologyElement.height */
  SVGAnimatedLength get height native "SVGFEMorphologyElement_height_Getter";


  /** @domName SVGFEMorphologyElement.result */
  SVGAnimatedString get result native "SVGFEMorphologyElement_result_Getter";


  /** @domName SVGFEMorphologyElement.width */
  SVGAnimatedLength get width native "SVGFEMorphologyElement_width_Getter";


  /** @domName SVGFEMorphologyElement.x */
  SVGAnimatedLength get x native "SVGFEMorphologyElement_x_Getter";


  /** @domName SVGFEMorphologyElement.y */
  SVGAnimatedLength get y native "SVGFEMorphologyElement_y_Getter";


  /** @domName SVGFEMorphologyElement.className */
  SVGAnimatedString get $dom_svgClassName native "SVGFEMorphologyElement_className_Getter";


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
class SVGFEOffsetElement extends SVGElement implements SVGFilterPrimitiveStandardAttributes {
  SVGFEOffsetElement.internal(): super.internal();


  /** @domName SVGFEOffsetElement.dx */
  SVGAnimatedNumber get dx native "SVGFEOffsetElement_dx_Getter";


  /** @domName SVGFEOffsetElement.dy */
  SVGAnimatedNumber get dy native "SVGFEOffsetElement_dy_Getter";


  /** @domName SVGFEOffsetElement.in1 */
  SVGAnimatedString get in1 native "SVGFEOffsetElement_in1_Getter";


  /** @domName SVGFEOffsetElement.height */
  SVGAnimatedLength get height native "SVGFEOffsetElement_height_Getter";


  /** @domName SVGFEOffsetElement.result */
  SVGAnimatedString get result native "SVGFEOffsetElement_result_Getter";


  /** @domName SVGFEOffsetElement.width */
  SVGAnimatedLength get width native "SVGFEOffsetElement_width_Getter";


  /** @domName SVGFEOffsetElement.x */
  SVGAnimatedLength get x native "SVGFEOffsetElement_x_Getter";


  /** @domName SVGFEOffsetElement.y */
  SVGAnimatedLength get y native "SVGFEOffsetElement_y_Getter";


  /** @domName SVGFEOffsetElement.className */
  SVGAnimatedString get $dom_svgClassName native "SVGFEOffsetElement_className_Getter";


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
class SVGFEPointLightElement extends SVGElement {
  SVGFEPointLightElement.internal(): super.internal();


  /** @domName SVGFEPointLightElement.x */
  SVGAnimatedNumber get x native "SVGFEPointLightElement_x_Getter";


  /** @domName SVGFEPointLightElement.y */
  SVGAnimatedNumber get y native "SVGFEPointLightElement_y_Getter";


  /** @domName SVGFEPointLightElement.z */
  SVGAnimatedNumber get z native "SVGFEPointLightElement_z_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFESpecularLightingElement
class SVGFESpecularLightingElement extends SVGElement implements SVGFilterPrimitiveStandardAttributes {
  SVGFESpecularLightingElement.internal(): super.internal();


  /** @domName SVGFESpecularLightingElement.in1 */
  SVGAnimatedString get in1 native "SVGFESpecularLightingElement_in1_Getter";


  /** @domName SVGFESpecularLightingElement.specularConstant */
  SVGAnimatedNumber get specularConstant native "SVGFESpecularLightingElement_specularConstant_Getter";


  /** @domName SVGFESpecularLightingElement.specularExponent */
  SVGAnimatedNumber get specularExponent native "SVGFESpecularLightingElement_specularExponent_Getter";


  /** @domName SVGFESpecularLightingElement.surfaceScale */
  SVGAnimatedNumber get surfaceScale native "SVGFESpecularLightingElement_surfaceScale_Getter";


  /** @domName SVGFESpecularLightingElement.height */
  SVGAnimatedLength get height native "SVGFESpecularLightingElement_height_Getter";


  /** @domName SVGFESpecularLightingElement.result */
  SVGAnimatedString get result native "SVGFESpecularLightingElement_result_Getter";


  /** @domName SVGFESpecularLightingElement.width */
  SVGAnimatedLength get width native "SVGFESpecularLightingElement_width_Getter";


  /** @domName SVGFESpecularLightingElement.x */
  SVGAnimatedLength get x native "SVGFESpecularLightingElement_x_Getter";


  /** @domName SVGFESpecularLightingElement.y */
  SVGAnimatedLength get y native "SVGFESpecularLightingElement_y_Getter";


  /** @domName SVGFESpecularLightingElement.className */
  SVGAnimatedString get $dom_svgClassName native "SVGFESpecularLightingElement_className_Getter";


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
class SVGFESpotLightElement extends SVGElement {
  SVGFESpotLightElement.internal(): super.internal();


  /** @domName SVGFESpotLightElement.limitingConeAngle */
  SVGAnimatedNumber get limitingConeAngle native "SVGFESpotLightElement_limitingConeAngle_Getter";


  /** @domName SVGFESpotLightElement.pointsAtX */
  SVGAnimatedNumber get pointsAtX native "SVGFESpotLightElement_pointsAtX_Getter";


  /** @domName SVGFESpotLightElement.pointsAtY */
  SVGAnimatedNumber get pointsAtY native "SVGFESpotLightElement_pointsAtY_Getter";


  /** @domName SVGFESpotLightElement.pointsAtZ */
  SVGAnimatedNumber get pointsAtZ native "SVGFESpotLightElement_pointsAtZ_Getter";


  /** @domName SVGFESpotLightElement.specularExponent */
  SVGAnimatedNumber get specularExponent native "SVGFESpotLightElement_specularExponent_Getter";


  /** @domName SVGFESpotLightElement.x */
  SVGAnimatedNumber get x native "SVGFESpotLightElement_x_Getter";


  /** @domName SVGFESpotLightElement.y */
  SVGAnimatedNumber get y native "SVGFESpotLightElement_y_Getter";


  /** @domName SVGFESpotLightElement.z */
  SVGAnimatedNumber get z native "SVGFESpotLightElement_z_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFETileElement
class SVGFETileElement extends SVGElement implements SVGFilterPrimitiveStandardAttributes {
  SVGFETileElement.internal(): super.internal();


  /** @domName SVGFETileElement.in1 */
  SVGAnimatedString get in1 native "SVGFETileElement_in1_Getter";


  /** @domName SVGFETileElement.height */
  SVGAnimatedLength get height native "SVGFETileElement_height_Getter";


  /** @domName SVGFETileElement.result */
  SVGAnimatedString get result native "SVGFETileElement_result_Getter";


  /** @domName SVGFETileElement.width */
  SVGAnimatedLength get width native "SVGFETileElement_width_Getter";


  /** @domName SVGFETileElement.x */
  SVGAnimatedLength get x native "SVGFETileElement_x_Getter";


  /** @domName SVGFETileElement.y */
  SVGAnimatedLength get y native "SVGFETileElement_y_Getter";


  /** @domName SVGFETileElement.className */
  SVGAnimatedString get $dom_svgClassName native "SVGFETileElement_className_Getter";


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
class SVGFETurbulenceElement extends SVGElement implements SVGFilterPrimitiveStandardAttributes {
  SVGFETurbulenceElement.internal(): super.internal();

  static const int SVG_STITCHTYPE_NOSTITCH = 2;

  static const int SVG_STITCHTYPE_STITCH = 1;

  static const int SVG_STITCHTYPE_UNKNOWN = 0;

  static const int SVG_TURBULENCE_TYPE_FRACTALNOISE = 1;

  static const int SVG_TURBULENCE_TYPE_TURBULENCE = 2;

  static const int SVG_TURBULENCE_TYPE_UNKNOWN = 0;


  /** @domName SVGFETurbulenceElement.baseFrequencyX */
  SVGAnimatedNumber get baseFrequencyX native "SVGFETurbulenceElement_baseFrequencyX_Getter";


  /** @domName SVGFETurbulenceElement.baseFrequencyY */
  SVGAnimatedNumber get baseFrequencyY native "SVGFETurbulenceElement_baseFrequencyY_Getter";


  /** @domName SVGFETurbulenceElement.numOctaves */
  SVGAnimatedInteger get numOctaves native "SVGFETurbulenceElement_numOctaves_Getter";


  /** @domName SVGFETurbulenceElement.seed */
  SVGAnimatedNumber get seed native "SVGFETurbulenceElement_seed_Getter";


  /** @domName SVGFETurbulenceElement.stitchTiles */
  SVGAnimatedEnumeration get stitchTiles native "SVGFETurbulenceElement_stitchTiles_Getter";


  /** @domName SVGFETurbulenceElement.type */
  SVGAnimatedEnumeration get type native "SVGFETurbulenceElement_type_Getter";


  /** @domName SVGFETurbulenceElement.height */
  SVGAnimatedLength get height native "SVGFETurbulenceElement_height_Getter";


  /** @domName SVGFETurbulenceElement.result */
  SVGAnimatedString get result native "SVGFETurbulenceElement_result_Getter";


  /** @domName SVGFETurbulenceElement.width */
  SVGAnimatedLength get width native "SVGFETurbulenceElement_width_Getter";


  /** @domName SVGFETurbulenceElement.x */
  SVGAnimatedLength get x native "SVGFETurbulenceElement_x_Getter";


  /** @domName SVGFETurbulenceElement.y */
  SVGAnimatedLength get y native "SVGFETurbulenceElement_y_Getter";


  /** @domName SVGFETurbulenceElement.className */
  SVGAnimatedString get $dom_svgClassName native "SVGFETurbulenceElement_className_Getter";


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
class SVGFilterElement extends SVGElement implements SVGURIReference, SVGLangSpace, SVGExternalResourcesRequired, SVGStylable {
  SVGFilterElement.internal(): super.internal();


  /** @domName SVGFilterElement.filterResX */
  SVGAnimatedInteger get filterResX native "SVGFilterElement_filterResX_Getter";


  /** @domName SVGFilterElement.filterResY */
  SVGAnimatedInteger get filterResY native "SVGFilterElement_filterResY_Getter";


  /** @domName SVGFilterElement.filterUnits */
  SVGAnimatedEnumeration get filterUnits native "SVGFilterElement_filterUnits_Getter";


  /** @domName SVGFilterElement.height */
  SVGAnimatedLength get height native "SVGFilterElement_height_Getter";


  /** @domName SVGFilterElement.primitiveUnits */
  SVGAnimatedEnumeration get primitiveUnits native "SVGFilterElement_primitiveUnits_Getter";


  /** @domName SVGFilterElement.width */
  SVGAnimatedLength get width native "SVGFilterElement_width_Getter";


  /** @domName SVGFilterElement.x */
  SVGAnimatedLength get x native "SVGFilterElement_x_Getter";


  /** @domName SVGFilterElement.y */
  SVGAnimatedLength get y native "SVGFilterElement_y_Getter";


  /** @domName SVGFilterElement.setFilterRes */
  void setFilterRes(int filterResX, int filterResY) native "SVGFilterElement_setFilterRes_Callback";


  /** @domName SVGFilterElement.externalResourcesRequired */
  SVGAnimatedBoolean get externalResourcesRequired native "SVGFilterElement_externalResourcesRequired_Getter";


  /** @domName SVGFilterElement.xmllang */
  String get xmllang native "SVGFilterElement_xmllang_Getter";


  /** @domName SVGFilterElement.xmllang */
  void set xmllang(String value) native "SVGFilterElement_xmllang_Setter";


  /** @domName SVGFilterElement.xmlspace */
  String get xmlspace native "SVGFilterElement_xmlspace_Getter";


  /** @domName SVGFilterElement.xmlspace */
  void set xmlspace(String value) native "SVGFilterElement_xmlspace_Setter";


  /** @domName SVGFilterElement.className */
  SVGAnimatedString get $dom_svgClassName native "SVGFilterElement_className_Getter";


  /** @domName SVGFilterElement.style */
  CSSStyleDeclaration get style native "SVGFilterElement_style_Getter";


  /** @domName SVGFilterElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGFilterElement_getPresentationAttribute_Callback";


  /** @domName SVGFilterElement.href */
  SVGAnimatedString get href native "SVGFilterElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFilterPrimitiveStandardAttributes
class SVGFilterPrimitiveStandardAttributes extends NativeFieldWrapperClass1 implements SVGStylable {
  SVGFilterPrimitiveStandardAttributes.internal();


  /** @domName SVGFilterPrimitiveStandardAttributes.height */
  SVGAnimatedLength get height native "SVGFilterPrimitiveStandardAttributes_height_Getter";


  /** @domName SVGFilterPrimitiveStandardAttributes.result */
  SVGAnimatedString get result native "SVGFilterPrimitiveStandardAttributes_result_Getter";


  /** @domName SVGFilterPrimitiveStandardAttributes.width */
  SVGAnimatedLength get width native "SVGFilterPrimitiveStandardAttributes_width_Getter";


  /** @domName SVGFilterPrimitiveStandardAttributes.x */
  SVGAnimatedLength get x native "SVGFilterPrimitiveStandardAttributes_x_Getter";


  /** @domName SVGFilterPrimitiveStandardAttributes.y */
  SVGAnimatedLength get y native "SVGFilterPrimitiveStandardAttributes_y_Getter";


  /** @domName SVGFilterPrimitiveStandardAttributes.className */
  SVGAnimatedString get $dom_svgClassName native "SVGFilterPrimitiveStandardAttributes_className_Getter";


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
class SVGFitToViewBox extends NativeFieldWrapperClass1 {
  SVGFitToViewBox.internal();


  /** @domName SVGFitToViewBox.preserveAspectRatio */
  SVGAnimatedPreserveAspectRatio get preserveAspectRatio native "SVGFitToViewBox_preserveAspectRatio_Getter";


  /** @domName SVGFitToViewBox.viewBox */
  SVGAnimatedRect get viewBox native "SVGFitToViewBox_viewBox_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFontElement
class SVGFontElement extends SVGElement {
  SVGFontElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFontFaceElement
class SVGFontFaceElement extends SVGElement {
  SVGFontFaceElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFontFaceFormatElement
class SVGFontFaceFormatElement extends SVGElement {
  SVGFontFaceFormatElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFontFaceNameElement
class SVGFontFaceNameElement extends SVGElement {
  SVGFontFaceNameElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFontFaceSrcElement
class SVGFontFaceSrcElement extends SVGElement {
  SVGFontFaceSrcElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGFontFaceUriElement
class SVGFontFaceUriElement extends SVGElement {
  SVGFontFaceUriElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGForeignObjectElement
class SVGForeignObjectElement extends SVGElement implements SVGLangSpace, SVGStylable, SVGTests, SVGTransformable, SVGExternalResourcesRequired {
  SVGForeignObjectElement.internal(): super.internal();


  /** @domName SVGForeignObjectElement.height */
  SVGAnimatedLength get height native "SVGForeignObjectElement_height_Getter";


  /** @domName SVGForeignObjectElement.width */
  SVGAnimatedLength get width native "SVGForeignObjectElement_width_Getter";


  /** @domName SVGForeignObjectElement.x */
  SVGAnimatedLength get x native "SVGForeignObjectElement_x_Getter";


  /** @domName SVGForeignObjectElement.y */
  SVGAnimatedLength get y native "SVGForeignObjectElement_y_Getter";


  /** @domName SVGForeignObjectElement.externalResourcesRequired */
  SVGAnimatedBoolean get externalResourcesRequired native "SVGForeignObjectElement_externalResourcesRequired_Getter";


  /** @domName SVGForeignObjectElement.xmllang */
  String get xmllang native "SVGForeignObjectElement_xmllang_Getter";


  /** @domName SVGForeignObjectElement.xmllang */
  void set xmllang(String value) native "SVGForeignObjectElement_xmllang_Setter";


  /** @domName SVGForeignObjectElement.xmlspace */
  String get xmlspace native "SVGForeignObjectElement_xmlspace_Getter";


  /** @domName SVGForeignObjectElement.xmlspace */
  void set xmlspace(String value) native "SVGForeignObjectElement_xmlspace_Setter";


  /** @domName SVGForeignObjectElement.farthestViewportElement */
  SVGElement get farthestViewportElement native "SVGForeignObjectElement_farthestViewportElement_Getter";


  /** @domName SVGForeignObjectElement.nearestViewportElement */
  SVGElement get nearestViewportElement native "SVGForeignObjectElement_nearestViewportElement_Getter";


  /** @domName SVGForeignObjectElement.getBBox */
  SVGRect getBBox() native "SVGForeignObjectElement_getBBox_Callback";


  /** @domName SVGForeignObjectElement.getCTM */
  SVGMatrix getCTM() native "SVGForeignObjectElement_getCTM_Callback";


  /** @domName SVGForeignObjectElement.getScreenCTM */
  SVGMatrix getScreenCTM() native "SVGForeignObjectElement_getScreenCTM_Callback";


  /** @domName SVGForeignObjectElement.getTransformToElement */
  SVGMatrix getTransformToElement(SVGElement element) native "SVGForeignObjectElement_getTransformToElement_Callback";


  /** @domName SVGForeignObjectElement.className */
  SVGAnimatedString get $dom_svgClassName native "SVGForeignObjectElement_className_Getter";


  /** @domName SVGForeignObjectElement.style */
  CSSStyleDeclaration get style native "SVGForeignObjectElement_style_Getter";


  /** @domName SVGForeignObjectElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGForeignObjectElement_getPresentationAttribute_Callback";


  /** @domName SVGForeignObjectElement.requiredExtensions */
  SVGStringList get requiredExtensions native "SVGForeignObjectElement_requiredExtensions_Getter";


  /** @domName SVGForeignObjectElement.requiredFeatures */
  SVGStringList get requiredFeatures native "SVGForeignObjectElement_requiredFeatures_Getter";


  /** @domName SVGForeignObjectElement.systemLanguage */
  SVGStringList get systemLanguage native "SVGForeignObjectElement_systemLanguage_Getter";


  /** @domName SVGForeignObjectElement.hasExtension */
  bool hasExtension(String extension) native "SVGForeignObjectElement_hasExtension_Callback";


  /** @domName SVGForeignObjectElement.transform */
  SVGAnimatedTransformList get transform native "SVGForeignObjectElement_transform_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGGElement
class SVGGElement extends SVGElement implements SVGLangSpace, SVGStylable, SVGTests, SVGTransformable, SVGExternalResourcesRequired {
  SVGGElement.internal(): super.internal();


  /** @domName SVGGElement.externalResourcesRequired */
  SVGAnimatedBoolean get externalResourcesRequired native "SVGGElement_externalResourcesRequired_Getter";


  /** @domName SVGGElement.xmllang */
  String get xmllang native "SVGGElement_xmllang_Getter";


  /** @domName SVGGElement.xmllang */
  void set xmllang(String value) native "SVGGElement_xmllang_Setter";


  /** @domName SVGGElement.xmlspace */
  String get xmlspace native "SVGGElement_xmlspace_Getter";


  /** @domName SVGGElement.xmlspace */
  void set xmlspace(String value) native "SVGGElement_xmlspace_Setter";


  /** @domName SVGGElement.farthestViewportElement */
  SVGElement get farthestViewportElement native "SVGGElement_farthestViewportElement_Getter";


  /** @domName SVGGElement.nearestViewportElement */
  SVGElement get nearestViewportElement native "SVGGElement_nearestViewportElement_Getter";


  /** @domName SVGGElement.getBBox */
  SVGRect getBBox() native "SVGGElement_getBBox_Callback";


  /** @domName SVGGElement.getCTM */
  SVGMatrix getCTM() native "SVGGElement_getCTM_Callback";


  /** @domName SVGGElement.getScreenCTM */
  SVGMatrix getScreenCTM() native "SVGGElement_getScreenCTM_Callback";


  /** @domName SVGGElement.getTransformToElement */
  SVGMatrix getTransformToElement(SVGElement element) native "SVGGElement_getTransformToElement_Callback";


  /** @domName SVGGElement.className */
  SVGAnimatedString get $dom_svgClassName native "SVGGElement_className_Getter";


  /** @domName SVGGElement.style */
  CSSStyleDeclaration get style native "SVGGElement_style_Getter";


  /** @domName SVGGElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGGElement_getPresentationAttribute_Callback";


  /** @domName SVGGElement.requiredExtensions */
  SVGStringList get requiredExtensions native "SVGGElement_requiredExtensions_Getter";


  /** @domName SVGGElement.requiredFeatures */
  SVGStringList get requiredFeatures native "SVGGElement_requiredFeatures_Getter";


  /** @domName SVGGElement.systemLanguage */
  SVGStringList get systemLanguage native "SVGGElement_systemLanguage_Getter";


  /** @domName SVGGElement.hasExtension */
  bool hasExtension(String extension) native "SVGGElement_hasExtension_Callback";


  /** @domName SVGGElement.transform */
  SVGAnimatedTransformList get transform native "SVGGElement_transform_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGGlyphElement
class SVGGlyphElement extends SVGElement {
  SVGGlyphElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGGlyphRefElement
class SVGGlyphRefElement extends SVGElement implements SVGURIReference, SVGStylable {
  SVGGlyphRefElement.internal(): super.internal();


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
  SVGAnimatedString get $dom_svgClassName native "SVGGlyphRefElement_className_Getter";


  /** @domName SVGGlyphRefElement.style */
  CSSStyleDeclaration get style native "SVGGlyphRefElement_style_Getter";


  /** @domName SVGGlyphRefElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGGlyphRefElement_getPresentationAttribute_Callback";


  /** @domName SVGGlyphRefElement.href */
  SVGAnimatedString get href native "SVGGlyphRefElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGGradientElement
class SVGGradientElement extends SVGElement implements SVGURIReference, SVGExternalResourcesRequired, SVGStylable {
  SVGGradientElement.internal(): super.internal();

  static const int SVG_SPREADMETHOD_PAD = 1;

  static const int SVG_SPREADMETHOD_REFLECT = 2;

  static const int SVG_SPREADMETHOD_REPEAT = 3;

  static const int SVG_SPREADMETHOD_UNKNOWN = 0;


  /** @domName SVGGradientElement.gradientTransform */
  SVGAnimatedTransformList get gradientTransform native "SVGGradientElement_gradientTransform_Getter";


  /** @domName SVGGradientElement.gradientUnits */
  SVGAnimatedEnumeration get gradientUnits native "SVGGradientElement_gradientUnits_Getter";


  /** @domName SVGGradientElement.spreadMethod */
  SVGAnimatedEnumeration get spreadMethod native "SVGGradientElement_spreadMethod_Getter";


  /** @domName SVGGradientElement.externalResourcesRequired */
  SVGAnimatedBoolean get externalResourcesRequired native "SVGGradientElement_externalResourcesRequired_Getter";


  /** @domName SVGGradientElement.className */
  SVGAnimatedString get $dom_svgClassName native "SVGGradientElement_className_Getter";


  /** @domName SVGGradientElement.style */
  CSSStyleDeclaration get style native "SVGGradientElement_style_Getter";


  /** @domName SVGGradientElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGGradientElement_getPresentationAttribute_Callback";


  /** @domName SVGGradientElement.href */
  SVGAnimatedString get href native "SVGGradientElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGHKernElement
class SVGHKernElement extends SVGElement {
  SVGHKernElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGImageElement
class SVGImageElement extends SVGElement implements SVGLangSpace, SVGTests, SVGStylable, SVGURIReference, SVGExternalResourcesRequired, SVGTransformable {
  SVGImageElement.internal(): super.internal();


  /** @domName SVGImageElement.height */
  SVGAnimatedLength get height native "SVGImageElement_height_Getter";


  /** @domName SVGImageElement.preserveAspectRatio */
  SVGAnimatedPreserveAspectRatio get preserveAspectRatio native "SVGImageElement_preserveAspectRatio_Getter";


  /** @domName SVGImageElement.width */
  SVGAnimatedLength get width native "SVGImageElement_width_Getter";


  /** @domName SVGImageElement.x */
  SVGAnimatedLength get x native "SVGImageElement_x_Getter";


  /** @domName SVGImageElement.y */
  SVGAnimatedLength get y native "SVGImageElement_y_Getter";


  /** @domName SVGImageElement.externalResourcesRequired */
  SVGAnimatedBoolean get externalResourcesRequired native "SVGImageElement_externalResourcesRequired_Getter";


  /** @domName SVGImageElement.xmllang */
  String get xmllang native "SVGImageElement_xmllang_Getter";


  /** @domName SVGImageElement.xmllang */
  void set xmllang(String value) native "SVGImageElement_xmllang_Setter";


  /** @domName SVGImageElement.xmlspace */
  String get xmlspace native "SVGImageElement_xmlspace_Getter";


  /** @domName SVGImageElement.xmlspace */
  void set xmlspace(String value) native "SVGImageElement_xmlspace_Setter";


  /** @domName SVGImageElement.farthestViewportElement */
  SVGElement get farthestViewportElement native "SVGImageElement_farthestViewportElement_Getter";


  /** @domName SVGImageElement.nearestViewportElement */
  SVGElement get nearestViewportElement native "SVGImageElement_nearestViewportElement_Getter";


  /** @domName SVGImageElement.getBBox */
  SVGRect getBBox() native "SVGImageElement_getBBox_Callback";


  /** @domName SVGImageElement.getCTM */
  SVGMatrix getCTM() native "SVGImageElement_getCTM_Callback";


  /** @domName SVGImageElement.getScreenCTM */
  SVGMatrix getScreenCTM() native "SVGImageElement_getScreenCTM_Callback";


  /** @domName SVGImageElement.getTransformToElement */
  SVGMatrix getTransformToElement(SVGElement element) native "SVGImageElement_getTransformToElement_Callback";


  /** @domName SVGImageElement.className */
  SVGAnimatedString get $dom_svgClassName native "SVGImageElement_className_Getter";


  /** @domName SVGImageElement.style */
  CSSStyleDeclaration get style native "SVGImageElement_style_Getter";


  /** @domName SVGImageElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGImageElement_getPresentationAttribute_Callback";


  /** @domName SVGImageElement.requiredExtensions */
  SVGStringList get requiredExtensions native "SVGImageElement_requiredExtensions_Getter";


  /** @domName SVGImageElement.requiredFeatures */
  SVGStringList get requiredFeatures native "SVGImageElement_requiredFeatures_Getter";


  /** @domName SVGImageElement.systemLanguage */
  SVGStringList get systemLanguage native "SVGImageElement_systemLanguage_Getter";


  /** @domName SVGImageElement.hasExtension */
  bool hasExtension(String extension) native "SVGImageElement_hasExtension_Callback";


  /** @domName SVGImageElement.transform */
  SVGAnimatedTransformList get transform native "SVGImageElement_transform_Getter";


  /** @domName SVGImageElement.href */
  SVGAnimatedString get href native "SVGImageElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGLangSpace
class SVGLangSpace extends NativeFieldWrapperClass1 {
  SVGLangSpace.internal();


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
class SVGLength extends NativeFieldWrapperClass1 {
  SVGLength.internal();

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
class SVGLengthList extends NativeFieldWrapperClass1 implements List<SVGLength> {
  SVGLengthList.internal();


  /** @domName SVGLengthList.numberOfItems */
  int get numberOfItems native "SVGLengthList_numberOfItems_Getter";

  SVGLength operator[](int index) native "SVGLengthList_item_Callback";

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
  SVGLength appendItem(SVGLength item) native "SVGLengthList_appendItem_Callback";


  /** @domName SVGLengthList.clear */
  void clear() native "SVGLengthList_clear_Callback";


  /** @domName SVGLengthList.getItem */
  SVGLength getItem(int index) native "SVGLengthList_getItem_Callback";


  /** @domName SVGLengthList.initialize */
  SVGLength initialize(SVGLength item) native "SVGLengthList_initialize_Callback";


  /** @domName SVGLengthList.insertItemBefore */
  SVGLength insertItemBefore(SVGLength item, int index) native "SVGLengthList_insertItemBefore_Callback";


  /** @domName SVGLengthList.removeItem */
  SVGLength removeItem(int index) native "SVGLengthList_removeItem_Callback";


  /** @domName SVGLengthList.replaceItem */
  SVGLength replaceItem(SVGLength item, int index) native "SVGLengthList_replaceItem_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGLineElement
class SVGLineElement extends SVGElement implements SVGLangSpace, SVGStylable, SVGTests, SVGTransformable, SVGExternalResourcesRequired {
  SVGLineElement.internal(): super.internal();


  /** @domName SVGLineElement.x1 */
  SVGAnimatedLength get x1 native "SVGLineElement_x1_Getter";


  /** @domName SVGLineElement.x2 */
  SVGAnimatedLength get x2 native "SVGLineElement_x2_Getter";


  /** @domName SVGLineElement.y1 */
  SVGAnimatedLength get y1 native "SVGLineElement_y1_Getter";


  /** @domName SVGLineElement.y2 */
  SVGAnimatedLength get y2 native "SVGLineElement_y2_Getter";


  /** @domName SVGLineElement.externalResourcesRequired */
  SVGAnimatedBoolean get externalResourcesRequired native "SVGLineElement_externalResourcesRequired_Getter";


  /** @domName SVGLineElement.xmllang */
  String get xmllang native "SVGLineElement_xmllang_Getter";


  /** @domName SVGLineElement.xmllang */
  void set xmllang(String value) native "SVGLineElement_xmllang_Setter";


  /** @domName SVGLineElement.xmlspace */
  String get xmlspace native "SVGLineElement_xmlspace_Getter";


  /** @domName SVGLineElement.xmlspace */
  void set xmlspace(String value) native "SVGLineElement_xmlspace_Setter";


  /** @domName SVGLineElement.farthestViewportElement */
  SVGElement get farthestViewportElement native "SVGLineElement_farthestViewportElement_Getter";


  /** @domName SVGLineElement.nearestViewportElement */
  SVGElement get nearestViewportElement native "SVGLineElement_nearestViewportElement_Getter";


  /** @domName SVGLineElement.getBBox */
  SVGRect getBBox() native "SVGLineElement_getBBox_Callback";


  /** @domName SVGLineElement.getCTM */
  SVGMatrix getCTM() native "SVGLineElement_getCTM_Callback";


  /** @domName SVGLineElement.getScreenCTM */
  SVGMatrix getScreenCTM() native "SVGLineElement_getScreenCTM_Callback";


  /** @domName SVGLineElement.getTransformToElement */
  SVGMatrix getTransformToElement(SVGElement element) native "SVGLineElement_getTransformToElement_Callback";


  /** @domName SVGLineElement.className */
  SVGAnimatedString get $dom_svgClassName native "SVGLineElement_className_Getter";


  /** @domName SVGLineElement.style */
  CSSStyleDeclaration get style native "SVGLineElement_style_Getter";


  /** @domName SVGLineElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGLineElement_getPresentationAttribute_Callback";


  /** @domName SVGLineElement.requiredExtensions */
  SVGStringList get requiredExtensions native "SVGLineElement_requiredExtensions_Getter";


  /** @domName SVGLineElement.requiredFeatures */
  SVGStringList get requiredFeatures native "SVGLineElement_requiredFeatures_Getter";


  /** @domName SVGLineElement.systemLanguage */
  SVGStringList get systemLanguage native "SVGLineElement_systemLanguage_Getter";


  /** @domName SVGLineElement.hasExtension */
  bool hasExtension(String extension) native "SVGLineElement_hasExtension_Callback";


  /** @domName SVGLineElement.transform */
  SVGAnimatedTransformList get transform native "SVGLineElement_transform_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGLinearGradientElement
class SVGLinearGradientElement extends SVGGradientElement {
  SVGLinearGradientElement.internal(): super.internal();


  /** @domName SVGLinearGradientElement.x1 */
  SVGAnimatedLength get x1 native "SVGLinearGradientElement_x1_Getter";


  /** @domName SVGLinearGradientElement.x2 */
  SVGAnimatedLength get x2 native "SVGLinearGradientElement_x2_Getter";


  /** @domName SVGLinearGradientElement.y1 */
  SVGAnimatedLength get y1 native "SVGLinearGradientElement_y1_Getter";


  /** @domName SVGLinearGradientElement.y2 */
  SVGAnimatedLength get y2 native "SVGLinearGradientElement_y2_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGLocatable
class SVGLocatable extends NativeFieldWrapperClass1 {
  SVGLocatable.internal();


  /** @domName SVGLocatable.farthestViewportElement */
  SVGElement get farthestViewportElement native "SVGLocatable_farthestViewportElement_Getter";


  /** @domName SVGLocatable.nearestViewportElement */
  SVGElement get nearestViewportElement native "SVGLocatable_nearestViewportElement_Getter";


  /** @domName SVGLocatable.getBBox */
  SVGRect getBBox() native "SVGLocatable_getBBox_Callback";


  /** @domName SVGLocatable.getCTM */
  SVGMatrix getCTM() native "SVGLocatable_getCTM_Callback";


  /** @domName SVGLocatable.getScreenCTM */
  SVGMatrix getScreenCTM() native "SVGLocatable_getScreenCTM_Callback";


  /** @domName SVGLocatable.getTransformToElement */
  SVGMatrix getTransformToElement(SVGElement element) native "SVGLocatable_getTransformToElement_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGMPathElement
class SVGMPathElement extends SVGElement implements SVGURIReference, SVGExternalResourcesRequired {
  SVGMPathElement.internal(): super.internal();


  /** @domName SVGMPathElement.externalResourcesRequired */
  SVGAnimatedBoolean get externalResourcesRequired native "SVGMPathElement_externalResourcesRequired_Getter";


  /** @domName SVGMPathElement.href */
  SVGAnimatedString get href native "SVGMPathElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGMarkerElement
class SVGMarkerElement extends SVGElement implements SVGLangSpace, SVGFitToViewBox, SVGExternalResourcesRequired, SVGStylable {
  SVGMarkerElement.internal(): super.internal();

  static const int SVG_MARKERUNITS_STROKEWIDTH = 2;

  static const int SVG_MARKERUNITS_UNKNOWN = 0;

  static const int SVG_MARKERUNITS_USERSPACEONUSE = 1;

  static const int SVG_MARKER_ORIENT_ANGLE = 2;

  static const int SVG_MARKER_ORIENT_AUTO = 1;

  static const int SVG_MARKER_ORIENT_UNKNOWN = 0;


  /** @domName SVGMarkerElement.markerHeight */
  SVGAnimatedLength get markerHeight native "SVGMarkerElement_markerHeight_Getter";


  /** @domName SVGMarkerElement.markerUnits */
  SVGAnimatedEnumeration get markerUnits native "SVGMarkerElement_markerUnits_Getter";


  /** @domName SVGMarkerElement.markerWidth */
  SVGAnimatedLength get markerWidth native "SVGMarkerElement_markerWidth_Getter";


  /** @domName SVGMarkerElement.orientAngle */
  SVGAnimatedAngle get orientAngle native "SVGMarkerElement_orientAngle_Getter";


  /** @domName SVGMarkerElement.orientType */
  SVGAnimatedEnumeration get orientType native "SVGMarkerElement_orientType_Getter";


  /** @domName SVGMarkerElement.refX */
  SVGAnimatedLength get refX native "SVGMarkerElement_refX_Getter";


  /** @domName SVGMarkerElement.refY */
  SVGAnimatedLength get refY native "SVGMarkerElement_refY_Getter";


  /** @domName SVGMarkerElement.setOrientToAngle */
  void setOrientToAngle(SVGAngle angle) native "SVGMarkerElement_setOrientToAngle_Callback";


  /** @domName SVGMarkerElement.setOrientToAuto */
  void setOrientToAuto() native "SVGMarkerElement_setOrientToAuto_Callback";


  /** @domName SVGMarkerElement.externalResourcesRequired */
  SVGAnimatedBoolean get externalResourcesRequired native "SVGMarkerElement_externalResourcesRequired_Getter";


  /** @domName SVGMarkerElement.preserveAspectRatio */
  SVGAnimatedPreserveAspectRatio get preserveAspectRatio native "SVGMarkerElement_preserveAspectRatio_Getter";


  /** @domName SVGMarkerElement.viewBox */
  SVGAnimatedRect get viewBox native "SVGMarkerElement_viewBox_Getter";


  /** @domName SVGMarkerElement.xmllang */
  String get xmllang native "SVGMarkerElement_xmllang_Getter";


  /** @domName SVGMarkerElement.xmllang */
  void set xmllang(String value) native "SVGMarkerElement_xmllang_Setter";


  /** @domName SVGMarkerElement.xmlspace */
  String get xmlspace native "SVGMarkerElement_xmlspace_Getter";


  /** @domName SVGMarkerElement.xmlspace */
  void set xmlspace(String value) native "SVGMarkerElement_xmlspace_Setter";


  /** @domName SVGMarkerElement.className */
  SVGAnimatedString get $dom_svgClassName native "SVGMarkerElement_className_Getter";


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
class SVGMaskElement extends SVGElement implements SVGLangSpace, SVGStylable, SVGTests, SVGExternalResourcesRequired {
  SVGMaskElement.internal(): super.internal();


  /** @domName SVGMaskElement.height */
  SVGAnimatedLength get height native "SVGMaskElement_height_Getter";


  /** @domName SVGMaskElement.maskContentUnits */
  SVGAnimatedEnumeration get maskContentUnits native "SVGMaskElement_maskContentUnits_Getter";


  /** @domName SVGMaskElement.maskUnits */
  SVGAnimatedEnumeration get maskUnits native "SVGMaskElement_maskUnits_Getter";


  /** @domName SVGMaskElement.width */
  SVGAnimatedLength get width native "SVGMaskElement_width_Getter";


  /** @domName SVGMaskElement.x */
  SVGAnimatedLength get x native "SVGMaskElement_x_Getter";


  /** @domName SVGMaskElement.y */
  SVGAnimatedLength get y native "SVGMaskElement_y_Getter";


  /** @domName SVGMaskElement.externalResourcesRequired */
  SVGAnimatedBoolean get externalResourcesRequired native "SVGMaskElement_externalResourcesRequired_Getter";


  /** @domName SVGMaskElement.xmllang */
  String get xmllang native "SVGMaskElement_xmllang_Getter";


  /** @domName SVGMaskElement.xmllang */
  void set xmllang(String value) native "SVGMaskElement_xmllang_Setter";


  /** @domName SVGMaskElement.xmlspace */
  String get xmlspace native "SVGMaskElement_xmlspace_Getter";


  /** @domName SVGMaskElement.xmlspace */
  void set xmlspace(String value) native "SVGMaskElement_xmlspace_Setter";


  /** @domName SVGMaskElement.className */
  SVGAnimatedString get $dom_svgClassName native "SVGMaskElement_className_Getter";


  /** @domName SVGMaskElement.style */
  CSSStyleDeclaration get style native "SVGMaskElement_style_Getter";


  /** @domName SVGMaskElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGMaskElement_getPresentationAttribute_Callback";


  /** @domName SVGMaskElement.requiredExtensions */
  SVGStringList get requiredExtensions native "SVGMaskElement_requiredExtensions_Getter";


  /** @domName SVGMaskElement.requiredFeatures */
  SVGStringList get requiredFeatures native "SVGMaskElement_requiredFeatures_Getter";


  /** @domName SVGMaskElement.systemLanguage */
  SVGStringList get systemLanguage native "SVGMaskElement_systemLanguage_Getter";


  /** @domName SVGMaskElement.hasExtension */
  bool hasExtension(String extension) native "SVGMaskElement_hasExtension_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGMatrix
class SVGMatrix extends NativeFieldWrapperClass1 {
  SVGMatrix.internal();


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
  SVGMatrix flipX() native "SVGMatrix_flipX_Callback";


  /** @domName SVGMatrix.flipY */
  SVGMatrix flipY() native "SVGMatrix_flipY_Callback";


  /** @domName SVGMatrix.inverse */
  SVGMatrix inverse() native "SVGMatrix_inverse_Callback";


  /** @domName SVGMatrix.multiply */
  SVGMatrix multiply(SVGMatrix secondMatrix) native "SVGMatrix_multiply_Callback";


  /** @domName SVGMatrix.rotate */
  SVGMatrix rotate(num angle) native "SVGMatrix_rotate_Callback";


  /** @domName SVGMatrix.rotateFromVector */
  SVGMatrix rotateFromVector(num x, num y) native "SVGMatrix_rotateFromVector_Callback";


  /** @domName SVGMatrix.scale */
  SVGMatrix scale(num scaleFactor) native "SVGMatrix_scale_Callback";


  /** @domName SVGMatrix.scaleNonUniform */
  SVGMatrix scaleNonUniform(num scaleFactorX, num scaleFactorY) native "SVGMatrix_scaleNonUniform_Callback";


  /** @domName SVGMatrix.skewX */
  SVGMatrix skewX(num angle) native "SVGMatrix_skewX_Callback";


  /** @domName SVGMatrix.skewY */
  SVGMatrix skewY(num angle) native "SVGMatrix_skewY_Callback";


  /** @domName SVGMatrix.translate */
  SVGMatrix translate(num x, num y) native "SVGMatrix_translate_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGMetadataElement
class SVGMetadataElement extends SVGElement {
  SVGMetadataElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGMissingGlyphElement
class SVGMissingGlyphElement extends SVGElement {
  SVGMissingGlyphElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGNumber
class SVGNumber extends NativeFieldWrapperClass1 {
  SVGNumber.internal();


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
class SVGNumberList extends NativeFieldWrapperClass1 implements List<SVGNumber> {
  SVGNumberList.internal();


  /** @domName SVGNumberList.numberOfItems */
  int get numberOfItems native "SVGNumberList_numberOfItems_Getter";

  SVGNumber operator[](int index) native "SVGNumberList_item_Callback";

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
  SVGNumber appendItem(SVGNumber item) native "SVGNumberList_appendItem_Callback";


  /** @domName SVGNumberList.clear */
  void clear() native "SVGNumberList_clear_Callback";


  /** @domName SVGNumberList.getItem */
  SVGNumber getItem(int index) native "SVGNumberList_getItem_Callback";


  /** @domName SVGNumberList.initialize */
  SVGNumber initialize(SVGNumber item) native "SVGNumberList_initialize_Callback";


  /** @domName SVGNumberList.insertItemBefore */
  SVGNumber insertItemBefore(SVGNumber item, int index) native "SVGNumberList_insertItemBefore_Callback";


  /** @domName SVGNumberList.removeItem */
  SVGNumber removeItem(int index) native "SVGNumberList_removeItem_Callback";


  /** @domName SVGNumberList.replaceItem */
  SVGNumber replaceItem(SVGNumber item, int index) native "SVGNumberList_replaceItem_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGPaint
class SVGPaint extends SVGColor {
  SVGPaint.internal(): super.internal();

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
class SVGPathElement extends SVGElement implements SVGLangSpace, SVGStylable, SVGTests, SVGTransformable, SVGExternalResourcesRequired {
  SVGPathElement.internal(): super.internal();


  /** @domName SVGPathElement.animatedNormalizedPathSegList */
  SVGPathSegList get animatedNormalizedPathSegList native "SVGPathElement_animatedNormalizedPathSegList_Getter";


  /** @domName SVGPathElement.animatedPathSegList */
  SVGPathSegList get animatedPathSegList native "SVGPathElement_animatedPathSegList_Getter";


  /** @domName SVGPathElement.normalizedPathSegList */
  SVGPathSegList get normalizedPathSegList native "SVGPathElement_normalizedPathSegList_Getter";


  /** @domName SVGPathElement.pathLength */
  SVGAnimatedNumber get pathLength native "SVGPathElement_pathLength_Getter";


  /** @domName SVGPathElement.pathSegList */
  SVGPathSegList get pathSegList native "SVGPathElement_pathSegList_Getter";


  /** @domName SVGPathElement.createSVGPathSegArcAbs */
  SVGPathSegArcAbs createSVGPathSegArcAbs(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) native "SVGPathElement_createSVGPathSegArcAbs_Callback";


  /** @domName SVGPathElement.createSVGPathSegArcRel */
  SVGPathSegArcRel createSVGPathSegArcRel(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) native "SVGPathElement_createSVGPathSegArcRel_Callback";


  /** @domName SVGPathElement.createSVGPathSegClosePath */
  SVGPathSegClosePath createSVGPathSegClosePath() native "SVGPathElement_createSVGPathSegClosePath_Callback";


  /** @domName SVGPathElement.createSVGPathSegCurvetoCubicAbs */
  SVGPathSegCurvetoCubicAbs createSVGPathSegCurvetoCubicAbs(num x, num y, num x1, num y1, num x2, num y2) native "SVGPathElement_createSVGPathSegCurvetoCubicAbs_Callback";


  /** @domName SVGPathElement.createSVGPathSegCurvetoCubicRel */
  SVGPathSegCurvetoCubicRel createSVGPathSegCurvetoCubicRel(num x, num y, num x1, num y1, num x2, num y2) native "SVGPathElement_createSVGPathSegCurvetoCubicRel_Callback";


  /** @domName SVGPathElement.createSVGPathSegCurvetoCubicSmoothAbs */
  SVGPathSegCurvetoCubicSmoothAbs createSVGPathSegCurvetoCubicSmoothAbs(num x, num y, num x2, num y2) native "SVGPathElement_createSVGPathSegCurvetoCubicSmoothAbs_Callback";


  /** @domName SVGPathElement.createSVGPathSegCurvetoCubicSmoothRel */
  SVGPathSegCurvetoCubicSmoothRel createSVGPathSegCurvetoCubicSmoothRel(num x, num y, num x2, num y2) native "SVGPathElement_createSVGPathSegCurvetoCubicSmoothRel_Callback";


  /** @domName SVGPathElement.createSVGPathSegCurvetoQuadraticAbs */
  SVGPathSegCurvetoQuadraticAbs createSVGPathSegCurvetoQuadraticAbs(num x, num y, num x1, num y1) native "SVGPathElement_createSVGPathSegCurvetoQuadraticAbs_Callback";


  /** @domName SVGPathElement.createSVGPathSegCurvetoQuadraticRel */
  SVGPathSegCurvetoQuadraticRel createSVGPathSegCurvetoQuadraticRel(num x, num y, num x1, num y1) native "SVGPathElement_createSVGPathSegCurvetoQuadraticRel_Callback";


  /** @domName SVGPathElement.createSVGPathSegCurvetoQuadraticSmoothAbs */
  SVGPathSegCurvetoQuadraticSmoothAbs createSVGPathSegCurvetoQuadraticSmoothAbs(num x, num y) native "SVGPathElement_createSVGPathSegCurvetoQuadraticSmoothAbs_Callback";


  /** @domName SVGPathElement.createSVGPathSegCurvetoQuadraticSmoothRel */
  SVGPathSegCurvetoQuadraticSmoothRel createSVGPathSegCurvetoQuadraticSmoothRel(num x, num y) native "SVGPathElement_createSVGPathSegCurvetoQuadraticSmoothRel_Callback";


  /** @domName SVGPathElement.createSVGPathSegLinetoAbs */
  SVGPathSegLinetoAbs createSVGPathSegLinetoAbs(num x, num y) native "SVGPathElement_createSVGPathSegLinetoAbs_Callback";


  /** @domName SVGPathElement.createSVGPathSegLinetoHorizontalAbs */
  SVGPathSegLinetoHorizontalAbs createSVGPathSegLinetoHorizontalAbs(num x) native "SVGPathElement_createSVGPathSegLinetoHorizontalAbs_Callback";


  /** @domName SVGPathElement.createSVGPathSegLinetoHorizontalRel */
  SVGPathSegLinetoHorizontalRel createSVGPathSegLinetoHorizontalRel(num x) native "SVGPathElement_createSVGPathSegLinetoHorizontalRel_Callback";


  /** @domName SVGPathElement.createSVGPathSegLinetoRel */
  SVGPathSegLinetoRel createSVGPathSegLinetoRel(num x, num y) native "SVGPathElement_createSVGPathSegLinetoRel_Callback";


  /** @domName SVGPathElement.createSVGPathSegLinetoVerticalAbs */
  SVGPathSegLinetoVerticalAbs createSVGPathSegLinetoVerticalAbs(num y) native "SVGPathElement_createSVGPathSegLinetoVerticalAbs_Callback";


  /** @domName SVGPathElement.createSVGPathSegLinetoVerticalRel */
  SVGPathSegLinetoVerticalRel createSVGPathSegLinetoVerticalRel(num y) native "SVGPathElement_createSVGPathSegLinetoVerticalRel_Callback";


  /** @domName SVGPathElement.createSVGPathSegMovetoAbs */
  SVGPathSegMovetoAbs createSVGPathSegMovetoAbs(num x, num y) native "SVGPathElement_createSVGPathSegMovetoAbs_Callback";


  /** @domName SVGPathElement.createSVGPathSegMovetoRel */
  SVGPathSegMovetoRel createSVGPathSegMovetoRel(num x, num y) native "SVGPathElement_createSVGPathSegMovetoRel_Callback";


  /** @domName SVGPathElement.getPathSegAtLength */
  int getPathSegAtLength(num distance) native "SVGPathElement_getPathSegAtLength_Callback";


  /** @domName SVGPathElement.getPointAtLength */
  SVGPoint getPointAtLength(num distance) native "SVGPathElement_getPointAtLength_Callback";


  /** @domName SVGPathElement.getTotalLength */
  num getTotalLength() native "SVGPathElement_getTotalLength_Callback";


  /** @domName SVGPathElement.externalResourcesRequired */
  SVGAnimatedBoolean get externalResourcesRequired native "SVGPathElement_externalResourcesRequired_Getter";


  /** @domName SVGPathElement.xmllang */
  String get xmllang native "SVGPathElement_xmllang_Getter";


  /** @domName SVGPathElement.xmllang */
  void set xmllang(String value) native "SVGPathElement_xmllang_Setter";


  /** @domName SVGPathElement.xmlspace */
  String get xmlspace native "SVGPathElement_xmlspace_Getter";


  /** @domName SVGPathElement.xmlspace */
  void set xmlspace(String value) native "SVGPathElement_xmlspace_Setter";


  /** @domName SVGPathElement.farthestViewportElement */
  SVGElement get farthestViewportElement native "SVGPathElement_farthestViewportElement_Getter";


  /** @domName SVGPathElement.nearestViewportElement */
  SVGElement get nearestViewportElement native "SVGPathElement_nearestViewportElement_Getter";


  /** @domName SVGPathElement.getBBox */
  SVGRect getBBox() native "SVGPathElement_getBBox_Callback";


  /** @domName SVGPathElement.getCTM */
  SVGMatrix getCTM() native "SVGPathElement_getCTM_Callback";


  /** @domName SVGPathElement.getScreenCTM */
  SVGMatrix getScreenCTM() native "SVGPathElement_getScreenCTM_Callback";


  /** @domName SVGPathElement.getTransformToElement */
  SVGMatrix getTransformToElement(SVGElement element) native "SVGPathElement_getTransformToElement_Callback";


  /** @domName SVGPathElement.className */
  SVGAnimatedString get $dom_svgClassName native "SVGPathElement_className_Getter";


  /** @domName SVGPathElement.style */
  CSSStyleDeclaration get style native "SVGPathElement_style_Getter";


  /** @domName SVGPathElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGPathElement_getPresentationAttribute_Callback";


  /** @domName SVGPathElement.requiredExtensions */
  SVGStringList get requiredExtensions native "SVGPathElement_requiredExtensions_Getter";


  /** @domName SVGPathElement.requiredFeatures */
  SVGStringList get requiredFeatures native "SVGPathElement_requiredFeatures_Getter";


  /** @domName SVGPathElement.systemLanguage */
  SVGStringList get systemLanguage native "SVGPathElement_systemLanguage_Getter";


  /** @domName SVGPathElement.hasExtension */
  bool hasExtension(String extension) native "SVGPathElement_hasExtension_Callback";


  /** @domName SVGPathElement.transform */
  SVGAnimatedTransformList get transform native "SVGPathElement_transform_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGPathSeg
class SVGPathSeg extends NativeFieldWrapperClass1 {
  SVGPathSeg.internal();

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
class SVGPathSegArcAbs extends SVGPathSeg {
  SVGPathSegArcAbs.internal(): super.internal();


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
class SVGPathSegArcRel extends SVGPathSeg {
  SVGPathSegArcRel.internal(): super.internal();


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
class SVGPathSegClosePath extends SVGPathSeg {
  SVGPathSegClosePath.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGPathSegCurvetoCubicAbs
class SVGPathSegCurvetoCubicAbs extends SVGPathSeg {
  SVGPathSegCurvetoCubicAbs.internal(): super.internal();


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
class SVGPathSegCurvetoCubicRel extends SVGPathSeg {
  SVGPathSegCurvetoCubicRel.internal(): super.internal();


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
class SVGPathSegCurvetoCubicSmoothAbs extends SVGPathSeg {
  SVGPathSegCurvetoCubicSmoothAbs.internal(): super.internal();


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
class SVGPathSegCurvetoCubicSmoothRel extends SVGPathSeg {
  SVGPathSegCurvetoCubicSmoothRel.internal(): super.internal();


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
class SVGPathSegCurvetoQuadraticAbs extends SVGPathSeg {
  SVGPathSegCurvetoQuadraticAbs.internal(): super.internal();


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
class SVGPathSegCurvetoQuadraticRel extends SVGPathSeg {
  SVGPathSegCurvetoQuadraticRel.internal(): super.internal();


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
class SVGPathSegCurvetoQuadraticSmoothAbs extends SVGPathSeg {
  SVGPathSegCurvetoQuadraticSmoothAbs.internal(): super.internal();


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
class SVGPathSegCurvetoQuadraticSmoothRel extends SVGPathSeg {
  SVGPathSegCurvetoQuadraticSmoothRel.internal(): super.internal();


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
class SVGPathSegLinetoAbs extends SVGPathSeg {
  SVGPathSegLinetoAbs.internal(): super.internal();


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
class SVGPathSegLinetoHorizontalAbs extends SVGPathSeg {
  SVGPathSegLinetoHorizontalAbs.internal(): super.internal();


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
class SVGPathSegLinetoHorizontalRel extends SVGPathSeg {
  SVGPathSegLinetoHorizontalRel.internal(): super.internal();


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
class SVGPathSegLinetoRel extends SVGPathSeg {
  SVGPathSegLinetoRel.internal(): super.internal();


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
class SVGPathSegLinetoVerticalAbs extends SVGPathSeg {
  SVGPathSegLinetoVerticalAbs.internal(): super.internal();


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
class SVGPathSegLinetoVerticalRel extends SVGPathSeg {
  SVGPathSegLinetoVerticalRel.internal(): super.internal();


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
class SVGPathSegList extends NativeFieldWrapperClass1 implements List<SVGPathSeg> {
  SVGPathSegList.internal();


  /** @domName SVGPathSegList.numberOfItems */
  int get numberOfItems native "SVGPathSegList_numberOfItems_Getter";

  SVGPathSeg operator[](int index) native "SVGPathSegList_item_Callback";

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
  SVGPathSeg appendItem(SVGPathSeg newItem) native "SVGPathSegList_appendItem_Callback";


  /** @domName SVGPathSegList.clear */
  void clear() native "SVGPathSegList_clear_Callback";


  /** @domName SVGPathSegList.getItem */
  SVGPathSeg getItem(int index) native "SVGPathSegList_getItem_Callback";


  /** @domName SVGPathSegList.initialize */
  SVGPathSeg initialize(SVGPathSeg newItem) native "SVGPathSegList_initialize_Callback";


  /** @domName SVGPathSegList.insertItemBefore */
  SVGPathSeg insertItemBefore(SVGPathSeg newItem, int index) native "SVGPathSegList_insertItemBefore_Callback";


  /** @domName SVGPathSegList.removeItem */
  SVGPathSeg removeItem(int index) native "SVGPathSegList_removeItem_Callback";


  /** @domName SVGPathSegList.replaceItem */
  SVGPathSeg replaceItem(SVGPathSeg newItem, int index) native "SVGPathSegList_replaceItem_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGPathSegMovetoAbs
class SVGPathSegMovetoAbs extends SVGPathSeg {
  SVGPathSegMovetoAbs.internal(): super.internal();


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
class SVGPathSegMovetoRel extends SVGPathSeg {
  SVGPathSegMovetoRel.internal(): super.internal();


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
class SVGPatternElement extends SVGElement implements SVGLangSpace, SVGTests, SVGStylable, SVGURIReference, SVGFitToViewBox, SVGExternalResourcesRequired {
  SVGPatternElement.internal(): super.internal();


  /** @domName SVGPatternElement.height */
  SVGAnimatedLength get height native "SVGPatternElement_height_Getter";


  /** @domName SVGPatternElement.patternContentUnits */
  SVGAnimatedEnumeration get patternContentUnits native "SVGPatternElement_patternContentUnits_Getter";


  /** @domName SVGPatternElement.patternTransform */
  SVGAnimatedTransformList get patternTransform native "SVGPatternElement_patternTransform_Getter";


  /** @domName SVGPatternElement.patternUnits */
  SVGAnimatedEnumeration get patternUnits native "SVGPatternElement_patternUnits_Getter";


  /** @domName SVGPatternElement.width */
  SVGAnimatedLength get width native "SVGPatternElement_width_Getter";


  /** @domName SVGPatternElement.x */
  SVGAnimatedLength get x native "SVGPatternElement_x_Getter";


  /** @domName SVGPatternElement.y */
  SVGAnimatedLength get y native "SVGPatternElement_y_Getter";


  /** @domName SVGPatternElement.externalResourcesRequired */
  SVGAnimatedBoolean get externalResourcesRequired native "SVGPatternElement_externalResourcesRequired_Getter";


  /** @domName SVGPatternElement.preserveAspectRatio */
  SVGAnimatedPreserveAspectRatio get preserveAspectRatio native "SVGPatternElement_preserveAspectRatio_Getter";


  /** @domName SVGPatternElement.viewBox */
  SVGAnimatedRect get viewBox native "SVGPatternElement_viewBox_Getter";


  /** @domName SVGPatternElement.xmllang */
  String get xmllang native "SVGPatternElement_xmllang_Getter";


  /** @domName SVGPatternElement.xmllang */
  void set xmllang(String value) native "SVGPatternElement_xmllang_Setter";


  /** @domName SVGPatternElement.xmlspace */
  String get xmlspace native "SVGPatternElement_xmlspace_Getter";


  /** @domName SVGPatternElement.xmlspace */
  void set xmlspace(String value) native "SVGPatternElement_xmlspace_Setter";


  /** @domName SVGPatternElement.className */
  SVGAnimatedString get $dom_svgClassName native "SVGPatternElement_className_Getter";


  /** @domName SVGPatternElement.style */
  CSSStyleDeclaration get style native "SVGPatternElement_style_Getter";


  /** @domName SVGPatternElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGPatternElement_getPresentationAttribute_Callback";


  /** @domName SVGPatternElement.requiredExtensions */
  SVGStringList get requiredExtensions native "SVGPatternElement_requiredExtensions_Getter";


  /** @domName SVGPatternElement.requiredFeatures */
  SVGStringList get requiredFeatures native "SVGPatternElement_requiredFeatures_Getter";


  /** @domName SVGPatternElement.systemLanguage */
  SVGStringList get systemLanguage native "SVGPatternElement_systemLanguage_Getter";


  /** @domName SVGPatternElement.hasExtension */
  bool hasExtension(String extension) native "SVGPatternElement_hasExtension_Callback";


  /** @domName SVGPatternElement.href */
  SVGAnimatedString get href native "SVGPatternElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGPoint
class SVGPoint extends NativeFieldWrapperClass1 {
  SVGPoint.internal();


  /** @domName SVGPoint.x */
  num get x native "SVGPoint_x_Getter";


  /** @domName SVGPoint.x */
  void set x(num value) native "SVGPoint_x_Setter";


  /** @domName SVGPoint.y */
  num get y native "SVGPoint_y_Getter";


  /** @domName SVGPoint.y */
  void set y(num value) native "SVGPoint_y_Setter";


  /** @domName SVGPoint.matrixTransform */
  SVGPoint matrixTransform(SVGMatrix matrix) native "SVGPoint_matrixTransform_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGPointList
class SVGPointList extends NativeFieldWrapperClass1 {
  SVGPointList.internal();


  /** @domName SVGPointList.numberOfItems */
  int get numberOfItems native "SVGPointList_numberOfItems_Getter";


  /** @domName SVGPointList.appendItem */
  SVGPoint appendItem(SVGPoint item) native "SVGPointList_appendItem_Callback";


  /** @domName SVGPointList.clear */
  void clear() native "SVGPointList_clear_Callback";


  /** @domName SVGPointList.getItem */
  SVGPoint getItem(int index) native "SVGPointList_getItem_Callback";


  /** @domName SVGPointList.initialize */
  SVGPoint initialize(SVGPoint item) native "SVGPointList_initialize_Callback";


  /** @domName SVGPointList.insertItemBefore */
  SVGPoint insertItemBefore(SVGPoint item, int index) native "SVGPointList_insertItemBefore_Callback";


  /** @domName SVGPointList.removeItem */
  SVGPoint removeItem(int index) native "SVGPointList_removeItem_Callback";


  /** @domName SVGPointList.replaceItem */
  SVGPoint replaceItem(SVGPoint item, int index) native "SVGPointList_replaceItem_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGPolygonElement
class SVGPolygonElement extends SVGElement implements SVGLangSpace, SVGStylable, SVGTests, SVGTransformable, SVGExternalResourcesRequired {
  SVGPolygonElement.internal(): super.internal();


  /** @domName SVGPolygonElement.animatedPoints */
  SVGPointList get animatedPoints native "SVGPolygonElement_animatedPoints_Getter";


  /** @domName SVGPolygonElement.points */
  SVGPointList get points native "SVGPolygonElement_points_Getter";


  /** @domName SVGPolygonElement.externalResourcesRequired */
  SVGAnimatedBoolean get externalResourcesRequired native "SVGPolygonElement_externalResourcesRequired_Getter";


  /** @domName SVGPolygonElement.xmllang */
  String get xmllang native "SVGPolygonElement_xmllang_Getter";


  /** @domName SVGPolygonElement.xmllang */
  void set xmllang(String value) native "SVGPolygonElement_xmllang_Setter";


  /** @domName SVGPolygonElement.xmlspace */
  String get xmlspace native "SVGPolygonElement_xmlspace_Getter";


  /** @domName SVGPolygonElement.xmlspace */
  void set xmlspace(String value) native "SVGPolygonElement_xmlspace_Setter";


  /** @domName SVGPolygonElement.farthestViewportElement */
  SVGElement get farthestViewportElement native "SVGPolygonElement_farthestViewportElement_Getter";


  /** @domName SVGPolygonElement.nearestViewportElement */
  SVGElement get nearestViewportElement native "SVGPolygonElement_nearestViewportElement_Getter";


  /** @domName SVGPolygonElement.getBBox */
  SVGRect getBBox() native "SVGPolygonElement_getBBox_Callback";


  /** @domName SVGPolygonElement.getCTM */
  SVGMatrix getCTM() native "SVGPolygonElement_getCTM_Callback";


  /** @domName SVGPolygonElement.getScreenCTM */
  SVGMatrix getScreenCTM() native "SVGPolygonElement_getScreenCTM_Callback";


  /** @domName SVGPolygonElement.getTransformToElement */
  SVGMatrix getTransformToElement(SVGElement element) native "SVGPolygonElement_getTransformToElement_Callback";


  /** @domName SVGPolygonElement.className */
  SVGAnimatedString get $dom_svgClassName native "SVGPolygonElement_className_Getter";


  /** @domName SVGPolygonElement.style */
  CSSStyleDeclaration get style native "SVGPolygonElement_style_Getter";


  /** @domName SVGPolygonElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGPolygonElement_getPresentationAttribute_Callback";


  /** @domName SVGPolygonElement.requiredExtensions */
  SVGStringList get requiredExtensions native "SVGPolygonElement_requiredExtensions_Getter";


  /** @domName SVGPolygonElement.requiredFeatures */
  SVGStringList get requiredFeatures native "SVGPolygonElement_requiredFeatures_Getter";


  /** @domName SVGPolygonElement.systemLanguage */
  SVGStringList get systemLanguage native "SVGPolygonElement_systemLanguage_Getter";


  /** @domName SVGPolygonElement.hasExtension */
  bool hasExtension(String extension) native "SVGPolygonElement_hasExtension_Callback";


  /** @domName SVGPolygonElement.transform */
  SVGAnimatedTransformList get transform native "SVGPolygonElement_transform_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGPolylineElement
class SVGPolylineElement extends SVGElement implements SVGLangSpace, SVGStylable, SVGTests, SVGTransformable, SVGExternalResourcesRequired {
  SVGPolylineElement.internal(): super.internal();


  /** @domName SVGPolylineElement.animatedPoints */
  SVGPointList get animatedPoints native "SVGPolylineElement_animatedPoints_Getter";


  /** @domName SVGPolylineElement.points */
  SVGPointList get points native "SVGPolylineElement_points_Getter";


  /** @domName SVGPolylineElement.externalResourcesRequired */
  SVGAnimatedBoolean get externalResourcesRequired native "SVGPolylineElement_externalResourcesRequired_Getter";


  /** @domName SVGPolylineElement.xmllang */
  String get xmllang native "SVGPolylineElement_xmllang_Getter";


  /** @domName SVGPolylineElement.xmllang */
  void set xmllang(String value) native "SVGPolylineElement_xmllang_Setter";


  /** @domName SVGPolylineElement.xmlspace */
  String get xmlspace native "SVGPolylineElement_xmlspace_Getter";


  /** @domName SVGPolylineElement.xmlspace */
  void set xmlspace(String value) native "SVGPolylineElement_xmlspace_Setter";


  /** @domName SVGPolylineElement.farthestViewportElement */
  SVGElement get farthestViewportElement native "SVGPolylineElement_farthestViewportElement_Getter";


  /** @domName SVGPolylineElement.nearestViewportElement */
  SVGElement get nearestViewportElement native "SVGPolylineElement_nearestViewportElement_Getter";


  /** @domName SVGPolylineElement.getBBox */
  SVGRect getBBox() native "SVGPolylineElement_getBBox_Callback";


  /** @domName SVGPolylineElement.getCTM */
  SVGMatrix getCTM() native "SVGPolylineElement_getCTM_Callback";


  /** @domName SVGPolylineElement.getScreenCTM */
  SVGMatrix getScreenCTM() native "SVGPolylineElement_getScreenCTM_Callback";


  /** @domName SVGPolylineElement.getTransformToElement */
  SVGMatrix getTransformToElement(SVGElement element) native "SVGPolylineElement_getTransformToElement_Callback";


  /** @domName SVGPolylineElement.className */
  SVGAnimatedString get $dom_svgClassName native "SVGPolylineElement_className_Getter";


  /** @domName SVGPolylineElement.style */
  CSSStyleDeclaration get style native "SVGPolylineElement_style_Getter";


  /** @domName SVGPolylineElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGPolylineElement_getPresentationAttribute_Callback";


  /** @domName SVGPolylineElement.requiredExtensions */
  SVGStringList get requiredExtensions native "SVGPolylineElement_requiredExtensions_Getter";


  /** @domName SVGPolylineElement.requiredFeatures */
  SVGStringList get requiredFeatures native "SVGPolylineElement_requiredFeatures_Getter";


  /** @domName SVGPolylineElement.systemLanguage */
  SVGStringList get systemLanguage native "SVGPolylineElement_systemLanguage_Getter";


  /** @domName SVGPolylineElement.hasExtension */
  bool hasExtension(String extension) native "SVGPolylineElement_hasExtension_Callback";


  /** @domName SVGPolylineElement.transform */
  SVGAnimatedTransformList get transform native "SVGPolylineElement_transform_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGPreserveAspectRatio
class SVGPreserveAspectRatio extends NativeFieldWrapperClass1 {
  SVGPreserveAspectRatio.internal();

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
class SVGRadialGradientElement extends SVGGradientElement {
  SVGRadialGradientElement.internal(): super.internal();


  /** @domName SVGRadialGradientElement.cx */
  SVGAnimatedLength get cx native "SVGRadialGradientElement_cx_Getter";


  /** @domName SVGRadialGradientElement.cy */
  SVGAnimatedLength get cy native "SVGRadialGradientElement_cy_Getter";


  /** @domName SVGRadialGradientElement.fr */
  SVGAnimatedLength get fr native "SVGRadialGradientElement_fr_Getter";


  /** @domName SVGRadialGradientElement.fx */
  SVGAnimatedLength get fx native "SVGRadialGradientElement_fx_Getter";


  /** @domName SVGRadialGradientElement.fy */
  SVGAnimatedLength get fy native "SVGRadialGradientElement_fy_Getter";


  /** @domName SVGRadialGradientElement.r */
  SVGAnimatedLength get r native "SVGRadialGradientElement_r_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGRect
class SVGRect extends NativeFieldWrapperClass1 {
  SVGRect.internal();


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
class SVGRectElement extends SVGElement implements SVGLangSpace, SVGStylable, SVGTests, SVGTransformable, SVGExternalResourcesRequired {
  SVGRectElement.internal(): super.internal();


  /** @domName SVGRectElement.height */
  SVGAnimatedLength get height native "SVGRectElement_height_Getter";


  /** @domName SVGRectElement.rx */
  SVGAnimatedLength get rx native "SVGRectElement_rx_Getter";


  /** @domName SVGRectElement.ry */
  SVGAnimatedLength get ry native "SVGRectElement_ry_Getter";


  /** @domName SVGRectElement.width */
  SVGAnimatedLength get width native "SVGRectElement_width_Getter";


  /** @domName SVGRectElement.x */
  SVGAnimatedLength get x native "SVGRectElement_x_Getter";


  /** @domName SVGRectElement.y */
  SVGAnimatedLength get y native "SVGRectElement_y_Getter";


  /** @domName SVGRectElement.externalResourcesRequired */
  SVGAnimatedBoolean get externalResourcesRequired native "SVGRectElement_externalResourcesRequired_Getter";


  /** @domName SVGRectElement.xmllang */
  String get xmllang native "SVGRectElement_xmllang_Getter";


  /** @domName SVGRectElement.xmllang */
  void set xmllang(String value) native "SVGRectElement_xmllang_Setter";


  /** @domName SVGRectElement.xmlspace */
  String get xmlspace native "SVGRectElement_xmlspace_Getter";


  /** @domName SVGRectElement.xmlspace */
  void set xmlspace(String value) native "SVGRectElement_xmlspace_Setter";


  /** @domName SVGRectElement.farthestViewportElement */
  SVGElement get farthestViewportElement native "SVGRectElement_farthestViewportElement_Getter";


  /** @domName SVGRectElement.nearestViewportElement */
  SVGElement get nearestViewportElement native "SVGRectElement_nearestViewportElement_Getter";


  /** @domName SVGRectElement.getBBox */
  SVGRect getBBox() native "SVGRectElement_getBBox_Callback";


  /** @domName SVGRectElement.getCTM */
  SVGMatrix getCTM() native "SVGRectElement_getCTM_Callback";


  /** @domName SVGRectElement.getScreenCTM */
  SVGMatrix getScreenCTM() native "SVGRectElement_getScreenCTM_Callback";


  /** @domName SVGRectElement.getTransformToElement */
  SVGMatrix getTransformToElement(SVGElement element) native "SVGRectElement_getTransformToElement_Callback";


  /** @domName SVGRectElement.className */
  SVGAnimatedString get $dom_svgClassName native "SVGRectElement_className_Getter";


  /** @domName SVGRectElement.style */
  CSSStyleDeclaration get style native "SVGRectElement_style_Getter";


  /** @domName SVGRectElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGRectElement_getPresentationAttribute_Callback";


  /** @domName SVGRectElement.requiredExtensions */
  SVGStringList get requiredExtensions native "SVGRectElement_requiredExtensions_Getter";


  /** @domName SVGRectElement.requiredFeatures */
  SVGStringList get requiredFeatures native "SVGRectElement_requiredFeatures_Getter";


  /** @domName SVGRectElement.systemLanguage */
  SVGStringList get systemLanguage native "SVGRectElement_systemLanguage_Getter";


  /** @domName SVGRectElement.hasExtension */
  bool hasExtension(String extension) native "SVGRectElement_hasExtension_Callback";


  /** @domName SVGRectElement.transform */
  SVGAnimatedTransformList get transform native "SVGRectElement_transform_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGRenderingIntent
class SVGRenderingIntent extends NativeFieldWrapperClass1 {
  SVGRenderingIntent.internal();

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


class SVGSVGElement extends SVGElement implements SVGZoomAndPan, SVGLocatable, SVGLangSpace, SVGTests, SVGStylable, SVGFitToViewBox, SVGExternalResourcesRequired {
  factory SVGSVGElement() => _SVGSVGElementFactoryProvider.createSVGSVGElement();

  SVGSVGElement.internal(): super.internal();


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
  SVGPoint get currentTranslate native "SVGSVGElement_currentTranslate_Getter";


  /** @domName SVGSVGElement.currentView */
  SVGViewSpec get currentView native "SVGSVGElement_currentView_Getter";


  /** @domName SVGSVGElement.height */
  SVGAnimatedLength get height native "SVGSVGElement_height_Getter";


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
  SVGRect get viewport native "SVGSVGElement_viewport_Getter";


  /** @domName SVGSVGElement.width */
  SVGAnimatedLength get width native "SVGSVGElement_width_Getter";


  /** @domName SVGSVGElement.x */
  SVGAnimatedLength get x native "SVGSVGElement_x_Getter";


  /** @domName SVGSVGElement.y */
  SVGAnimatedLength get y native "SVGSVGElement_y_Getter";


  /** @domName SVGSVGElement.animationsPaused */
  bool animationsPaused() native "SVGSVGElement_animationsPaused_Callback";


  /** @domName SVGSVGElement.checkEnclosure */
  bool checkEnclosure(SVGElement element, SVGRect rect) native "SVGSVGElement_checkEnclosure_Callback";


  /** @domName SVGSVGElement.checkIntersection */
  bool checkIntersection(SVGElement element, SVGRect rect) native "SVGSVGElement_checkIntersection_Callback";


  /** @domName SVGSVGElement.createSVGAngle */
  SVGAngle createSVGAngle() native "SVGSVGElement_createSVGAngle_Callback";


  /** @domName SVGSVGElement.createSVGLength */
  SVGLength createSVGLength() native "SVGSVGElement_createSVGLength_Callback";


  /** @domName SVGSVGElement.createSVGMatrix */
  SVGMatrix createSVGMatrix() native "SVGSVGElement_createSVGMatrix_Callback";


  /** @domName SVGSVGElement.createSVGNumber */
  SVGNumber createSVGNumber() native "SVGSVGElement_createSVGNumber_Callback";


  /** @domName SVGSVGElement.createSVGPoint */
  SVGPoint createSVGPoint() native "SVGSVGElement_createSVGPoint_Callback";


  /** @domName SVGSVGElement.createSVGRect */
  SVGRect createSVGRect() native "SVGSVGElement_createSVGRect_Callback";


  /** @domName SVGSVGElement.createSVGTransform */
  SVGTransform createSVGTransform() native "SVGSVGElement_createSVGTransform_Callback";


  /** @domName SVGSVGElement.createSVGTransformFromMatrix */
  SVGTransform createSVGTransformFromMatrix(SVGMatrix matrix) native "SVGSVGElement_createSVGTransformFromMatrix_Callback";


  /** @domName SVGSVGElement.deselectAll */
  void deselectAll() native "SVGSVGElement_deselectAll_Callback";


  /** @domName SVGSVGElement.forceRedraw */
  void forceRedraw() native "SVGSVGElement_forceRedraw_Callback";


  /** @domName SVGSVGElement.getCurrentTime */
  num getCurrentTime() native "SVGSVGElement_getCurrentTime_Callback";


  /** @domName SVGSVGElement.getElementById */
  Element getElementById(String elementId) native "SVGSVGElement_getElementById_Callback";


  /** @domName SVGSVGElement.getEnclosureList */
  List<Node> getEnclosureList(SVGRect rect, SVGElement referenceElement) native "SVGSVGElement_getEnclosureList_Callback";


  /** @domName SVGSVGElement.getIntersectionList */
  List<Node> getIntersectionList(SVGRect rect, SVGElement referenceElement) native "SVGSVGElement_getIntersectionList_Callback";


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
  SVGAnimatedBoolean get externalResourcesRequired native "SVGSVGElement_externalResourcesRequired_Getter";


  /** @domName SVGSVGElement.preserveAspectRatio */
  SVGAnimatedPreserveAspectRatio get preserveAspectRatio native "SVGSVGElement_preserveAspectRatio_Getter";


  /** @domName SVGSVGElement.viewBox */
  SVGAnimatedRect get viewBox native "SVGSVGElement_viewBox_Getter";


  /** @domName SVGSVGElement.xmllang */
  String get xmllang native "SVGSVGElement_xmllang_Getter";


  /** @domName SVGSVGElement.xmllang */
  void set xmllang(String value) native "SVGSVGElement_xmllang_Setter";


  /** @domName SVGSVGElement.xmlspace */
  String get xmlspace native "SVGSVGElement_xmlspace_Getter";


  /** @domName SVGSVGElement.xmlspace */
  void set xmlspace(String value) native "SVGSVGElement_xmlspace_Setter";


  /** @domName SVGSVGElement.farthestViewportElement */
  SVGElement get farthestViewportElement native "SVGSVGElement_farthestViewportElement_Getter";


  /** @domName SVGSVGElement.nearestViewportElement */
  SVGElement get nearestViewportElement native "SVGSVGElement_nearestViewportElement_Getter";


  /** @domName SVGSVGElement.getBBox */
  SVGRect getBBox() native "SVGSVGElement_getBBox_Callback";


  /** @domName SVGSVGElement.getCTM */
  SVGMatrix getCTM() native "SVGSVGElement_getCTM_Callback";


  /** @domName SVGSVGElement.getScreenCTM */
  SVGMatrix getScreenCTM() native "SVGSVGElement_getScreenCTM_Callback";


  /** @domName SVGSVGElement.getTransformToElement */
  SVGMatrix getTransformToElement(SVGElement element) native "SVGSVGElement_getTransformToElement_Callback";


  /** @domName SVGSVGElement.className */
  SVGAnimatedString get $dom_svgClassName native "SVGSVGElement_className_Getter";


  /** @domName SVGSVGElement.style */
  CSSStyleDeclaration get style native "SVGSVGElement_style_Getter";


  /** @domName SVGSVGElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGSVGElement_getPresentationAttribute_Callback";


  /** @domName SVGSVGElement.requiredExtensions */
  SVGStringList get requiredExtensions native "SVGSVGElement_requiredExtensions_Getter";


  /** @domName SVGSVGElement.requiredFeatures */
  SVGStringList get requiredFeatures native "SVGSVGElement_requiredFeatures_Getter";


  /** @domName SVGSVGElement.systemLanguage */
  SVGStringList get systemLanguage native "SVGSVGElement_systemLanguage_Getter";


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


/// @domName SVGScriptElement
class SVGScriptElement extends SVGElement implements SVGURIReference, SVGExternalResourcesRequired {
  SVGScriptElement.internal(): super.internal();


  /** @domName SVGScriptElement.type */
  String get type native "SVGScriptElement_type_Getter";


  /** @domName SVGScriptElement.type */
  void set type(String value) native "SVGScriptElement_type_Setter";


  /** @domName SVGScriptElement.externalResourcesRequired */
  SVGAnimatedBoolean get externalResourcesRequired native "SVGScriptElement_externalResourcesRequired_Getter";


  /** @domName SVGScriptElement.href */
  SVGAnimatedString get href native "SVGScriptElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGSetElement
class SVGSetElement extends SVGAnimationElement {
  SVGSetElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGStopElement
class SVGStopElement extends SVGElement implements SVGStylable {
  SVGStopElement.internal(): super.internal();


  /** @domName SVGStopElement.offset */
  SVGAnimatedNumber get offset native "SVGStopElement_offset_Getter";


  /** @domName SVGStopElement.className */
  SVGAnimatedString get $dom_svgClassName native "SVGStopElement_className_Getter";


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
class SVGStringList extends NativeFieldWrapperClass1 implements List<String> {
  SVGStringList.internal();


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
class SVGStylable extends NativeFieldWrapperClass1 {
  SVGStylable.internal();


  /** @domName SVGStylable.className */
  SVGAnimatedString get $dom_svgClassName native "SVGStylable_className_Getter";


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
class SVGStyleElement extends SVGElement implements SVGLangSpace {
  SVGStyleElement.internal(): super.internal();


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


/// @domName SVGSwitchElement
class SVGSwitchElement extends SVGElement implements SVGLangSpace, SVGStylable, SVGTests, SVGTransformable, SVGExternalResourcesRequired {
  SVGSwitchElement.internal(): super.internal();


  /** @domName SVGSwitchElement.externalResourcesRequired */
  SVGAnimatedBoolean get externalResourcesRequired native "SVGSwitchElement_externalResourcesRequired_Getter";


  /** @domName SVGSwitchElement.xmllang */
  String get xmllang native "SVGSwitchElement_xmllang_Getter";


  /** @domName SVGSwitchElement.xmllang */
  void set xmllang(String value) native "SVGSwitchElement_xmllang_Setter";


  /** @domName SVGSwitchElement.xmlspace */
  String get xmlspace native "SVGSwitchElement_xmlspace_Getter";


  /** @domName SVGSwitchElement.xmlspace */
  void set xmlspace(String value) native "SVGSwitchElement_xmlspace_Setter";


  /** @domName SVGSwitchElement.farthestViewportElement */
  SVGElement get farthestViewportElement native "SVGSwitchElement_farthestViewportElement_Getter";


  /** @domName SVGSwitchElement.nearestViewportElement */
  SVGElement get nearestViewportElement native "SVGSwitchElement_nearestViewportElement_Getter";


  /** @domName SVGSwitchElement.getBBox */
  SVGRect getBBox() native "SVGSwitchElement_getBBox_Callback";


  /** @domName SVGSwitchElement.getCTM */
  SVGMatrix getCTM() native "SVGSwitchElement_getCTM_Callback";


  /** @domName SVGSwitchElement.getScreenCTM */
  SVGMatrix getScreenCTM() native "SVGSwitchElement_getScreenCTM_Callback";


  /** @domName SVGSwitchElement.getTransformToElement */
  SVGMatrix getTransformToElement(SVGElement element) native "SVGSwitchElement_getTransformToElement_Callback";


  /** @domName SVGSwitchElement.className */
  SVGAnimatedString get $dom_svgClassName native "SVGSwitchElement_className_Getter";


  /** @domName SVGSwitchElement.style */
  CSSStyleDeclaration get style native "SVGSwitchElement_style_Getter";


  /** @domName SVGSwitchElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGSwitchElement_getPresentationAttribute_Callback";


  /** @domName SVGSwitchElement.requiredExtensions */
  SVGStringList get requiredExtensions native "SVGSwitchElement_requiredExtensions_Getter";


  /** @domName SVGSwitchElement.requiredFeatures */
  SVGStringList get requiredFeatures native "SVGSwitchElement_requiredFeatures_Getter";


  /** @domName SVGSwitchElement.systemLanguage */
  SVGStringList get systemLanguage native "SVGSwitchElement_systemLanguage_Getter";


  /** @domName SVGSwitchElement.hasExtension */
  bool hasExtension(String extension) native "SVGSwitchElement_hasExtension_Callback";


  /** @domName SVGSwitchElement.transform */
  SVGAnimatedTransformList get transform native "SVGSwitchElement_transform_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGSymbolElement
class SVGSymbolElement extends SVGElement implements SVGLangSpace, SVGFitToViewBox, SVGExternalResourcesRequired, SVGStylable {
  SVGSymbolElement.internal(): super.internal();


  /** @domName SVGSymbolElement.externalResourcesRequired */
  SVGAnimatedBoolean get externalResourcesRequired native "SVGSymbolElement_externalResourcesRequired_Getter";


  /** @domName SVGSymbolElement.preserveAspectRatio */
  SVGAnimatedPreserveAspectRatio get preserveAspectRatio native "SVGSymbolElement_preserveAspectRatio_Getter";


  /** @domName SVGSymbolElement.viewBox */
  SVGAnimatedRect get viewBox native "SVGSymbolElement_viewBox_Getter";


  /** @domName SVGSymbolElement.xmllang */
  String get xmllang native "SVGSymbolElement_xmllang_Getter";


  /** @domName SVGSymbolElement.xmllang */
  void set xmllang(String value) native "SVGSymbolElement_xmllang_Setter";


  /** @domName SVGSymbolElement.xmlspace */
  String get xmlspace native "SVGSymbolElement_xmlspace_Getter";


  /** @domName SVGSymbolElement.xmlspace */
  void set xmlspace(String value) native "SVGSymbolElement_xmlspace_Setter";


  /** @domName SVGSymbolElement.className */
  SVGAnimatedString get $dom_svgClassName native "SVGSymbolElement_className_Getter";


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
class SVGTRefElement extends SVGTextPositioningElement implements SVGURIReference {
  SVGTRefElement.internal(): super.internal();


  /** @domName SVGTRefElement.href */
  SVGAnimatedString get href native "SVGTRefElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGTSpanElement
class SVGTSpanElement extends SVGTextPositioningElement {
  SVGTSpanElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGTests
class SVGTests extends NativeFieldWrapperClass1 {
  SVGTests.internal();


  /** @domName SVGTests.requiredExtensions */
  SVGStringList get requiredExtensions native "SVGTests_requiredExtensions_Getter";


  /** @domName SVGTests.requiredFeatures */
  SVGStringList get requiredFeatures native "SVGTests_requiredFeatures_Getter";


  /** @domName SVGTests.systemLanguage */
  SVGStringList get systemLanguage native "SVGTests_systemLanguage_Getter";


  /** @domName SVGTests.hasExtension */
  bool hasExtension(String extension) native "SVGTests_hasExtension_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGTextContentElement
class SVGTextContentElement extends SVGElement implements SVGLangSpace, SVGStylable, SVGTests, SVGExternalResourcesRequired {
  SVGTextContentElement.internal(): super.internal();

  static const int LENGTHADJUST_SPACING = 1;

  static const int LENGTHADJUST_SPACINGANDGLYPHS = 2;

  static const int LENGTHADJUST_UNKNOWN = 0;


  /** @domName SVGTextContentElement.lengthAdjust */
  SVGAnimatedEnumeration get lengthAdjust native "SVGTextContentElement_lengthAdjust_Getter";


  /** @domName SVGTextContentElement.textLength */
  SVGAnimatedLength get textLength native "SVGTextContentElement_textLength_Getter";


  /** @domName SVGTextContentElement.getCharNumAtPosition */
  int getCharNumAtPosition(SVGPoint point) native "SVGTextContentElement_getCharNumAtPosition_Callback";


  /** @domName SVGTextContentElement.getComputedTextLength */
  num getComputedTextLength() native "SVGTextContentElement_getComputedTextLength_Callback";


  /** @domName SVGTextContentElement.getEndPositionOfChar */
  SVGPoint getEndPositionOfChar(int offset) native "SVGTextContentElement_getEndPositionOfChar_Callback";


  /** @domName SVGTextContentElement.getExtentOfChar */
  SVGRect getExtentOfChar(int offset) native "SVGTextContentElement_getExtentOfChar_Callback";


  /** @domName SVGTextContentElement.getNumberOfChars */
  int getNumberOfChars() native "SVGTextContentElement_getNumberOfChars_Callback";


  /** @domName SVGTextContentElement.getRotationOfChar */
  num getRotationOfChar(int offset) native "SVGTextContentElement_getRotationOfChar_Callback";


  /** @domName SVGTextContentElement.getStartPositionOfChar */
  SVGPoint getStartPositionOfChar(int offset) native "SVGTextContentElement_getStartPositionOfChar_Callback";


  /** @domName SVGTextContentElement.getSubStringLength */
  num getSubStringLength(int offset, int length) native "SVGTextContentElement_getSubStringLength_Callback";


  /** @domName SVGTextContentElement.selectSubString */
  void selectSubString(int offset, int length) native "SVGTextContentElement_selectSubString_Callback";


  /** @domName SVGTextContentElement.externalResourcesRequired */
  SVGAnimatedBoolean get externalResourcesRequired native "SVGTextContentElement_externalResourcesRequired_Getter";


  /** @domName SVGTextContentElement.xmllang */
  String get xmllang native "SVGTextContentElement_xmllang_Getter";


  /** @domName SVGTextContentElement.xmllang */
  void set xmllang(String value) native "SVGTextContentElement_xmllang_Setter";


  /** @domName SVGTextContentElement.xmlspace */
  String get xmlspace native "SVGTextContentElement_xmlspace_Getter";


  /** @domName SVGTextContentElement.xmlspace */
  void set xmlspace(String value) native "SVGTextContentElement_xmlspace_Setter";


  /** @domName SVGTextContentElement.className */
  SVGAnimatedString get $dom_svgClassName native "SVGTextContentElement_className_Getter";


  /** @domName SVGTextContentElement.style */
  CSSStyleDeclaration get style native "SVGTextContentElement_style_Getter";


  /** @domName SVGTextContentElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGTextContentElement_getPresentationAttribute_Callback";


  /** @domName SVGTextContentElement.requiredExtensions */
  SVGStringList get requiredExtensions native "SVGTextContentElement_requiredExtensions_Getter";


  /** @domName SVGTextContentElement.requiredFeatures */
  SVGStringList get requiredFeatures native "SVGTextContentElement_requiredFeatures_Getter";


  /** @domName SVGTextContentElement.systemLanguage */
  SVGStringList get systemLanguage native "SVGTextContentElement_systemLanguage_Getter";


  /** @domName SVGTextContentElement.hasExtension */
  bool hasExtension(String extension) native "SVGTextContentElement_hasExtension_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGTextElement
class SVGTextElement extends SVGTextPositioningElement implements SVGTransformable {
  SVGTextElement.internal(): super.internal();


  /** @domName SVGTextElement.farthestViewportElement */
  SVGElement get farthestViewportElement native "SVGTextElement_farthestViewportElement_Getter";


  /** @domName SVGTextElement.nearestViewportElement */
  SVGElement get nearestViewportElement native "SVGTextElement_nearestViewportElement_Getter";


  /** @domName SVGTextElement.getBBox */
  SVGRect getBBox() native "SVGTextElement_getBBox_Callback";


  /** @domName SVGTextElement.getCTM */
  SVGMatrix getCTM() native "SVGTextElement_getCTM_Callback";


  /** @domName SVGTextElement.getScreenCTM */
  SVGMatrix getScreenCTM() native "SVGTextElement_getScreenCTM_Callback";


  /** @domName SVGTextElement.getTransformToElement */
  SVGMatrix getTransformToElement(SVGElement element) native "SVGTextElement_getTransformToElement_Callback";


  /** @domName SVGTextElement.transform */
  SVGAnimatedTransformList get transform native "SVGTextElement_transform_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGTextPathElement
class SVGTextPathElement extends SVGTextContentElement implements SVGURIReference {
  SVGTextPathElement.internal(): super.internal();

  static const int TEXTPATH_METHODTYPE_ALIGN = 1;

  static const int TEXTPATH_METHODTYPE_STRETCH = 2;

  static const int TEXTPATH_METHODTYPE_UNKNOWN = 0;

  static const int TEXTPATH_SPACINGTYPE_AUTO = 1;

  static const int TEXTPATH_SPACINGTYPE_EXACT = 2;

  static const int TEXTPATH_SPACINGTYPE_UNKNOWN = 0;


  /** @domName SVGTextPathElement.method */
  SVGAnimatedEnumeration get method native "SVGTextPathElement_method_Getter";


  /** @domName SVGTextPathElement.spacing */
  SVGAnimatedEnumeration get spacing native "SVGTextPathElement_spacing_Getter";


  /** @domName SVGTextPathElement.startOffset */
  SVGAnimatedLength get startOffset native "SVGTextPathElement_startOffset_Getter";


  /** @domName SVGTextPathElement.href */
  SVGAnimatedString get href native "SVGTextPathElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGTextPositioningElement
class SVGTextPositioningElement extends SVGTextContentElement {
  SVGTextPositioningElement.internal(): super.internal();


  /** @domName SVGTextPositioningElement.dx */
  SVGAnimatedLengthList get dx native "SVGTextPositioningElement_dx_Getter";


  /** @domName SVGTextPositioningElement.dy */
  SVGAnimatedLengthList get dy native "SVGTextPositioningElement_dy_Getter";


  /** @domName SVGTextPositioningElement.rotate */
  SVGAnimatedNumberList get rotate native "SVGTextPositioningElement_rotate_Getter";


  /** @domName SVGTextPositioningElement.x */
  SVGAnimatedLengthList get x native "SVGTextPositioningElement_x_Getter";


  /** @domName SVGTextPositioningElement.y */
  SVGAnimatedLengthList get y native "SVGTextPositioningElement_y_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGTitleElement
class SVGTitleElement extends SVGElement implements SVGLangSpace, SVGStylable {
  SVGTitleElement.internal(): super.internal();


  /** @domName SVGTitleElement.xmllang */
  String get xmllang native "SVGTitleElement_xmllang_Getter";


  /** @domName SVGTitleElement.xmllang */
  void set xmllang(String value) native "SVGTitleElement_xmllang_Setter";


  /** @domName SVGTitleElement.xmlspace */
  String get xmlspace native "SVGTitleElement_xmlspace_Getter";


  /** @domName SVGTitleElement.xmlspace */
  void set xmlspace(String value) native "SVGTitleElement_xmlspace_Setter";


  /** @domName SVGTitleElement.className */
  SVGAnimatedString get $dom_svgClassName native "SVGTitleElement_className_Getter";


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
class SVGTransform extends NativeFieldWrapperClass1 {
  SVGTransform.internal();

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
  SVGMatrix get matrix native "SVGTransform_matrix_Getter";


  /** @domName SVGTransform.type */
  int get type native "SVGTransform_type_Getter";


  /** @domName SVGTransform.setMatrix */
  void setMatrix(SVGMatrix matrix) native "SVGTransform_setMatrix_Callback";


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
class SVGTransformList extends NativeFieldWrapperClass1 implements List<SVGTransform> {
  SVGTransformList.internal();


  /** @domName SVGTransformList.numberOfItems */
  int get numberOfItems native "SVGTransformList_numberOfItems_Getter";

  SVGTransform operator[](int index) native "SVGTransformList_item_Callback";

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
  SVGTransform appendItem(SVGTransform item) native "SVGTransformList_appendItem_Callback";


  /** @domName SVGTransformList.clear */
  void clear() native "SVGTransformList_clear_Callback";


  /** @domName SVGTransformList.consolidate */
  SVGTransform consolidate() native "SVGTransformList_consolidate_Callback";


  /** @domName SVGTransformList.createSVGTransformFromMatrix */
  SVGTransform createSVGTransformFromMatrix(SVGMatrix matrix) native "SVGTransformList_createSVGTransformFromMatrix_Callback";


  /** @domName SVGTransformList.getItem */
  SVGTransform getItem(int index) native "SVGTransformList_getItem_Callback";


  /** @domName SVGTransformList.initialize */
  SVGTransform initialize(SVGTransform item) native "SVGTransformList_initialize_Callback";


  /** @domName SVGTransformList.insertItemBefore */
  SVGTransform insertItemBefore(SVGTransform item, int index) native "SVGTransformList_insertItemBefore_Callback";


  /** @domName SVGTransformList.removeItem */
  SVGTransform removeItem(int index) native "SVGTransformList_removeItem_Callback";


  /** @domName SVGTransformList.replaceItem */
  SVGTransform replaceItem(SVGTransform item, int index) native "SVGTransformList_replaceItem_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGTransformable
class SVGTransformable extends NativeFieldWrapperClass1 implements SVGLocatable {
  SVGTransformable.internal();


  /** @domName SVGTransformable.transform */
  SVGAnimatedTransformList get transform native "SVGTransformable_transform_Getter";


  /** @domName SVGTransformable.farthestViewportElement */
  SVGElement get farthestViewportElement native "SVGTransformable_farthestViewportElement_Getter";


  /** @domName SVGTransformable.nearestViewportElement */
  SVGElement get nearestViewportElement native "SVGTransformable_nearestViewportElement_Getter";


  /** @domName SVGTransformable.getBBox */
  SVGRect getBBox() native "SVGTransformable_getBBox_Callback";


  /** @domName SVGTransformable.getCTM */
  SVGMatrix getCTM() native "SVGTransformable_getCTM_Callback";


  /** @domName SVGTransformable.getScreenCTM */
  SVGMatrix getScreenCTM() native "SVGTransformable_getScreenCTM_Callback";


  /** @domName SVGTransformable.getTransformToElement */
  SVGMatrix getTransformToElement(SVGElement element) native "SVGTransformable_getTransformToElement_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGURIReference
class SVGURIReference extends NativeFieldWrapperClass1 {
  SVGURIReference.internal();


  /** @domName SVGURIReference.href */
  SVGAnimatedString get href native "SVGURIReference_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGUnitTypes
class SVGUnitTypes extends NativeFieldWrapperClass1 {
  SVGUnitTypes.internal();

  static const int SVG_UNIT_TYPE_OBJECTBOUNDINGBOX = 2;

  static const int SVG_UNIT_TYPE_UNKNOWN = 0;

  static const int SVG_UNIT_TYPE_USERSPACEONUSE = 1;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGUseElement
class SVGUseElement extends SVGElement implements SVGLangSpace, SVGTests, SVGStylable, SVGURIReference, SVGExternalResourcesRequired, SVGTransformable {
  SVGUseElement.internal(): super.internal();


  /** @domName SVGUseElement.animatedInstanceRoot */
  SVGElementInstance get animatedInstanceRoot native "SVGUseElement_animatedInstanceRoot_Getter";


  /** @domName SVGUseElement.height */
  SVGAnimatedLength get height native "SVGUseElement_height_Getter";


  /** @domName SVGUseElement.instanceRoot */
  SVGElementInstance get instanceRoot native "SVGUseElement_instanceRoot_Getter";


  /** @domName SVGUseElement.width */
  SVGAnimatedLength get width native "SVGUseElement_width_Getter";


  /** @domName SVGUseElement.x */
  SVGAnimatedLength get x native "SVGUseElement_x_Getter";


  /** @domName SVGUseElement.y */
  SVGAnimatedLength get y native "SVGUseElement_y_Getter";


  /** @domName SVGUseElement.externalResourcesRequired */
  SVGAnimatedBoolean get externalResourcesRequired native "SVGUseElement_externalResourcesRequired_Getter";


  /** @domName SVGUseElement.xmllang */
  String get xmllang native "SVGUseElement_xmllang_Getter";


  /** @domName SVGUseElement.xmllang */
  void set xmllang(String value) native "SVGUseElement_xmllang_Setter";


  /** @domName SVGUseElement.xmlspace */
  String get xmlspace native "SVGUseElement_xmlspace_Getter";


  /** @domName SVGUseElement.xmlspace */
  void set xmlspace(String value) native "SVGUseElement_xmlspace_Setter";


  /** @domName SVGUseElement.farthestViewportElement */
  SVGElement get farthestViewportElement native "SVGUseElement_farthestViewportElement_Getter";


  /** @domName SVGUseElement.nearestViewportElement */
  SVGElement get nearestViewportElement native "SVGUseElement_nearestViewportElement_Getter";


  /** @domName SVGUseElement.getBBox */
  SVGRect getBBox() native "SVGUseElement_getBBox_Callback";


  /** @domName SVGUseElement.getCTM */
  SVGMatrix getCTM() native "SVGUseElement_getCTM_Callback";


  /** @domName SVGUseElement.getScreenCTM */
  SVGMatrix getScreenCTM() native "SVGUseElement_getScreenCTM_Callback";


  /** @domName SVGUseElement.getTransformToElement */
  SVGMatrix getTransformToElement(SVGElement element) native "SVGUseElement_getTransformToElement_Callback";


  /** @domName SVGUseElement.className */
  SVGAnimatedString get $dom_svgClassName native "SVGUseElement_className_Getter";


  /** @domName SVGUseElement.style */
  CSSStyleDeclaration get style native "SVGUseElement_style_Getter";


  /** @domName SVGUseElement.getPresentationAttribute */
  CSSValue getPresentationAttribute(String name) native "SVGUseElement_getPresentationAttribute_Callback";


  /** @domName SVGUseElement.requiredExtensions */
  SVGStringList get requiredExtensions native "SVGUseElement_requiredExtensions_Getter";


  /** @domName SVGUseElement.requiredFeatures */
  SVGStringList get requiredFeatures native "SVGUseElement_requiredFeatures_Getter";


  /** @domName SVGUseElement.systemLanguage */
  SVGStringList get systemLanguage native "SVGUseElement_systemLanguage_Getter";


  /** @domName SVGUseElement.hasExtension */
  bool hasExtension(String extension) native "SVGUseElement_hasExtension_Callback";


  /** @domName SVGUseElement.transform */
  SVGAnimatedTransformList get transform native "SVGUseElement_transform_Getter";


  /** @domName SVGUseElement.href */
  SVGAnimatedString get href native "SVGUseElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGVKernElement
class SVGVKernElement extends SVGElement {
  SVGVKernElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGViewElement
class SVGViewElement extends SVGElement implements SVGFitToViewBox, SVGZoomAndPan, SVGExternalResourcesRequired {
  SVGViewElement.internal(): super.internal();


  /** @domName SVGViewElement.viewTarget */
  SVGStringList get viewTarget native "SVGViewElement_viewTarget_Getter";


  /** @domName SVGViewElement.externalResourcesRequired */
  SVGAnimatedBoolean get externalResourcesRequired native "SVGViewElement_externalResourcesRequired_Getter";


  /** @domName SVGViewElement.preserveAspectRatio */
  SVGAnimatedPreserveAspectRatio get preserveAspectRatio native "SVGViewElement_preserveAspectRatio_Getter";


  /** @domName SVGViewElement.viewBox */
  SVGAnimatedRect get viewBox native "SVGViewElement_viewBox_Getter";


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
class SVGViewSpec extends NativeFieldWrapperClass1 {
  SVGViewSpec.internal();


  /** @domName SVGViewSpec.preserveAspectRatio */
  SVGAnimatedPreserveAspectRatio get preserveAspectRatio native "SVGViewSpec_preserveAspectRatio_Getter";


  /** @domName SVGViewSpec.preserveAspectRatioString */
  String get preserveAspectRatioString native "SVGViewSpec_preserveAspectRatioString_Getter";


  /** @domName SVGViewSpec.transform */
  SVGTransformList get transform native "SVGViewSpec_transform_Getter";


  /** @domName SVGViewSpec.transformString */
  String get transformString native "SVGViewSpec_transformString_Getter";


  /** @domName SVGViewSpec.viewBox */
  SVGAnimatedRect get viewBox native "SVGViewSpec_viewBox_Getter";


  /** @domName SVGViewSpec.viewBoxString */
  String get viewBoxString native "SVGViewSpec_viewBoxString_Getter";


  /** @domName SVGViewSpec.viewTarget */
  SVGElement get viewTarget native "SVGViewSpec_viewTarget_Getter";


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
class SVGZoomAndPan extends NativeFieldWrapperClass1 {
  SVGZoomAndPan.internal();

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
class SVGZoomEvent extends UIEvent {
  SVGZoomEvent.internal(): super.internal();


  /** @domName SVGZoomEvent.newScale */
  num get newScale native "SVGZoomEvent_newScale_Getter";


  /** @domName SVGZoomEvent.newTranslate */
  SVGPoint get newTranslate native "SVGZoomEvent_newTranslate_Getter";


  /** @domName SVGZoomEvent.previousScale */
  num get previousScale native "SVGZoomEvent_previousScale_Getter";


  /** @domName SVGZoomEvent.previousTranslate */
  SVGPoint get previousTranslate native "SVGZoomEvent_previousTranslate_Getter";


  /** @domName SVGZoomEvent.zoomRectScreen */
  SVGRect get zoomRectScreen native "SVGZoomEvent_zoomRectScreen_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SVGElementInstanceList
class _SVGElementInstanceList extends NativeFieldWrapperClass1 implements List<SVGElementInstance> {
  _SVGElementInstanceList.internal();


  /** @domName SVGElementInstanceList.length */
  int get length native "SVGElementInstanceList_length_Getter";

  SVGElementInstance operator[](int index) native "SVGElementInstanceList_item_Callback";

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
  SVGElementInstance item(int index) native "SVGElementInstanceList_item_Callback";

}
