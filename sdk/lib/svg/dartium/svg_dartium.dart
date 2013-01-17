library svg;

import 'dart:async';
import 'dart:collection';
import 'dart:html';
import 'dart:html_common';
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
    if (parentTag.children.length == 1) return parentTag.children.removeLast();

    throw new ArgumentError(
        'SVG had ${parentTag.children.length} '
        'top-level children but 1 expected');
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


@DocsEditable
@DomName('SVGAElement')
class AElement extends SvgElement implements Transformable, Tests, UriReference, Stylable, ExternalResourcesRequired, LangSpace {
  AElement.internal() : super.internal();

  @DocsEditable
  factory AElement() => _SvgElementFactoryProvider.createSvgElement_tag("a");

  @DocsEditable
  @DomName('SVGAElement.target')
  AnimatedString get target native "SVGAElement_target_Getter";

  @DocsEditable
  @DomName('SVGAElement.externalResourcesRequired')
  AnimatedBoolean get externalResourcesRequired native "SVGAElement_externalResourcesRequired_Getter";

  @DocsEditable
  @DomName('SVGAElement.xmllang')
  String get xmllang native "SVGAElement_xmllang_Getter";

  @DocsEditable
  @DomName('SVGAElement.xmllang')
  void set xmllang(String value) native "SVGAElement_xmllang_Setter";

  @DocsEditable
  @DomName('SVGAElement.xmlspace')
  String get xmlspace native "SVGAElement_xmlspace_Getter";

  @DocsEditable
  @DomName('SVGAElement.xmlspace')
  void set xmlspace(String value) native "SVGAElement_xmlspace_Setter";

  @DocsEditable
  @DomName('SVGAElement.farthestViewportElement')
  SvgElement get farthestViewportElement native "SVGAElement_farthestViewportElement_Getter";

  @DocsEditable
  @DomName('SVGAElement.nearestViewportElement')
  SvgElement get nearestViewportElement native "SVGAElement_nearestViewportElement_Getter";

  @DocsEditable
  @DomName('SVGAElement.getBBox')
  Rect getBBox() native "SVGAElement_getBBox_Callback";

  @DocsEditable
  @DomName('SVGAElement.getCTM')
  Matrix getCtm() native "SVGAElement_getCTM_Callback";

  @DocsEditable
  @DomName('SVGAElement.getScreenCTM')
  Matrix getScreenCtm() native "SVGAElement_getScreenCTM_Callback";

  @DocsEditable
  @DomName('SVGAElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native "SVGAElement_getTransformToElement_Callback";

  @DocsEditable
  @DomName('SVGAElement.className')
  AnimatedString get $dom_svgClassName native "SVGAElement_className_Getter";

  @DocsEditable
  @DomName('SVGAElement.style')
  CssStyleDeclaration get style native "SVGAElement_style_Getter";

  @DocsEditable
  @DomName('SVGAElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native "SVGAElement_getPresentationAttribute_Callback";

  @DocsEditable
  @DomName('SVGAElement.requiredExtensions')
  StringList get requiredExtensions native "SVGAElement_requiredExtensions_Getter";

  @DocsEditable
  @DomName('SVGAElement.requiredFeatures')
  StringList get requiredFeatures native "SVGAElement_requiredFeatures_Getter";

  @DocsEditable
  @DomName('SVGAElement.systemLanguage')
  StringList get systemLanguage native "SVGAElement_systemLanguage_Getter";

  @DocsEditable
  @DomName('SVGAElement.hasExtension')
  bool hasExtension(String extension) native "SVGAElement_hasExtension_Callback";

  @DocsEditable
  @DomName('SVGAElement.transform')
  AnimatedTransformList get transform native "SVGAElement_transform_Getter";

  @DocsEditable
  @DomName('SVGAElement.href')
  AnimatedString get href native "SVGAElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGAltGlyphDefElement')
class AltGlyphDefElement extends SvgElement {
  AltGlyphDefElement.internal() : super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGAltGlyphElement')
class AltGlyphElement extends TextPositioningElement implements UriReference {
  AltGlyphElement.internal() : super.internal();

  @DocsEditable
  @DomName('SVGAltGlyphElement.format')
  String get format native "SVGAltGlyphElement_format_Getter";

  @DocsEditable
  @DomName('SVGAltGlyphElement.format')
  void set format(String value) native "SVGAltGlyphElement_format_Setter";

  @DocsEditable
  @DomName('SVGAltGlyphElement.glyphRef')
  String get glyphRef native "SVGAltGlyphElement_glyphRef_Getter";

  @DocsEditable
  @DomName('SVGAltGlyphElement.glyphRef')
  void set glyphRef(String value) native "SVGAltGlyphElement_glyphRef_Setter";

  @DocsEditable
  @DomName('SVGAltGlyphElement.href')
  AnimatedString get href native "SVGAltGlyphElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGAltGlyphItemElement')
class AltGlyphItemElement extends SvgElement {
  AltGlyphItemElement.internal() : super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGAngle')
class Angle extends NativeFieldWrapperClass1 {
  Angle.internal();

  static const int SVG_ANGLETYPE_DEG = 2;

  static const int SVG_ANGLETYPE_GRAD = 4;

  static const int SVG_ANGLETYPE_RAD = 3;

  static const int SVG_ANGLETYPE_UNKNOWN = 0;

  static const int SVG_ANGLETYPE_UNSPECIFIED = 1;

  @DocsEditable
  @DomName('SVGAngle.unitType')
  int get unitType native "SVGAngle_unitType_Getter";

  @DocsEditable
  @DomName('SVGAngle.value')
  num get value native "SVGAngle_value_Getter";

  @DocsEditable
  @DomName('SVGAngle.value')
  void set value(num value) native "SVGAngle_value_Setter";

  @DocsEditable
  @DomName('SVGAngle.valueAsString')
  String get valueAsString native "SVGAngle_valueAsString_Getter";

  @DocsEditable
  @DomName('SVGAngle.valueAsString')
  void set valueAsString(String value) native "SVGAngle_valueAsString_Setter";

  @DocsEditable
  @DomName('SVGAngle.valueInSpecifiedUnits')
  num get valueInSpecifiedUnits native "SVGAngle_valueInSpecifiedUnits_Getter";

  @DocsEditable
  @DomName('SVGAngle.valueInSpecifiedUnits')
  void set valueInSpecifiedUnits(num value) native "SVGAngle_valueInSpecifiedUnits_Setter";

  @DocsEditable
  @DomName('SVGAngle.convertToSpecifiedUnits')
  void convertToSpecifiedUnits(int unitType) native "SVGAngle_convertToSpecifiedUnits_Callback";

  @DocsEditable
  @DomName('SVGAngle.newValueSpecifiedUnits')
  void newValueSpecifiedUnits(int unitType, num valueInSpecifiedUnits) native "SVGAngle_newValueSpecifiedUnits_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGAnimateColorElement')
class AnimateColorElement extends AnimationElement {
  AnimateColorElement.internal() : super.internal();

  @DocsEditable
  factory AnimateColorElement() => _SvgElementFactoryProvider.createSvgElement_tag("animateColor");

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGAnimateElement')
class AnimateElement extends AnimationElement {
  AnimateElement.internal() : super.internal();

  @DocsEditable
  factory AnimateElement() => _SvgElementFactoryProvider.createSvgElement_tag("animate");

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGAnimateMotionElement')
class AnimateMotionElement extends AnimationElement {
  AnimateMotionElement.internal() : super.internal();

  @DocsEditable
  factory AnimateMotionElement() => _SvgElementFactoryProvider.createSvgElement_tag("animateMotion");

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGAnimateTransformElement')
class AnimateTransformElement extends AnimationElement {
  AnimateTransformElement.internal() : super.internal();

  @DocsEditable
  factory AnimateTransformElement() => _SvgElementFactoryProvider.createSvgElement_tag("animateTransform");

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGAnimatedAngle')
class AnimatedAngle extends NativeFieldWrapperClass1 {
  AnimatedAngle.internal();

  @DocsEditable
  @DomName('SVGAnimatedAngle.animVal')
  Angle get animVal native "SVGAnimatedAngle_animVal_Getter";

  @DocsEditable
  @DomName('SVGAnimatedAngle.baseVal')
  Angle get baseVal native "SVGAnimatedAngle_baseVal_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGAnimatedBoolean')
class AnimatedBoolean extends NativeFieldWrapperClass1 {
  AnimatedBoolean.internal();

  @DocsEditable
  @DomName('SVGAnimatedBoolean.animVal')
  bool get animVal native "SVGAnimatedBoolean_animVal_Getter";

  @DocsEditable
  @DomName('SVGAnimatedBoolean.baseVal')
  bool get baseVal native "SVGAnimatedBoolean_baseVal_Getter";

  @DocsEditable
  @DomName('SVGAnimatedBoolean.baseVal')
  void set baseVal(bool value) native "SVGAnimatedBoolean_baseVal_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGAnimatedEnumeration')
class AnimatedEnumeration extends NativeFieldWrapperClass1 {
  AnimatedEnumeration.internal();

  @DocsEditable
  @DomName('SVGAnimatedEnumeration.animVal')
  int get animVal native "SVGAnimatedEnumeration_animVal_Getter";

  @DocsEditable
  @DomName('SVGAnimatedEnumeration.baseVal')
  int get baseVal native "SVGAnimatedEnumeration_baseVal_Getter";

  @DocsEditable
  @DomName('SVGAnimatedEnumeration.baseVal')
  void set baseVal(int value) native "SVGAnimatedEnumeration_baseVal_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGAnimatedInteger')
class AnimatedInteger extends NativeFieldWrapperClass1 {
  AnimatedInteger.internal();

  @DocsEditable
  @DomName('SVGAnimatedInteger.animVal')
  int get animVal native "SVGAnimatedInteger_animVal_Getter";

  @DocsEditable
  @DomName('SVGAnimatedInteger.baseVal')
  int get baseVal native "SVGAnimatedInteger_baseVal_Getter";

  @DocsEditable
  @DomName('SVGAnimatedInteger.baseVal')
  void set baseVal(int value) native "SVGAnimatedInteger_baseVal_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGAnimatedLength')
class AnimatedLength extends NativeFieldWrapperClass1 {
  AnimatedLength.internal();

  @DocsEditable
  @DomName('SVGAnimatedLength.animVal')
  Length get animVal native "SVGAnimatedLength_animVal_Getter";

  @DocsEditable
  @DomName('SVGAnimatedLength.baseVal')
  Length get baseVal native "SVGAnimatedLength_baseVal_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGAnimatedLengthList')
class AnimatedLengthList extends NativeFieldWrapperClass1 {
  AnimatedLengthList.internal();

  @DocsEditable
  @DomName('SVGAnimatedLengthList.animVal')
  LengthList get animVal native "SVGAnimatedLengthList_animVal_Getter";

  @DocsEditable
  @DomName('SVGAnimatedLengthList.baseVal')
  LengthList get baseVal native "SVGAnimatedLengthList_baseVal_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGAnimatedNumber')
class AnimatedNumber extends NativeFieldWrapperClass1 {
  AnimatedNumber.internal();

  @DocsEditable
  @DomName('SVGAnimatedNumber.animVal')
  num get animVal native "SVGAnimatedNumber_animVal_Getter";

  @DocsEditable
  @DomName('SVGAnimatedNumber.baseVal')
  num get baseVal native "SVGAnimatedNumber_baseVal_Getter";

  @DocsEditable
  @DomName('SVGAnimatedNumber.baseVal')
  void set baseVal(num value) native "SVGAnimatedNumber_baseVal_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGAnimatedNumberList')
class AnimatedNumberList extends NativeFieldWrapperClass1 {
  AnimatedNumberList.internal();

  @DocsEditable
  @DomName('SVGAnimatedNumberList.animVal')
  NumberList get animVal native "SVGAnimatedNumberList_animVal_Getter";

  @DocsEditable
  @DomName('SVGAnimatedNumberList.baseVal')
  NumberList get baseVal native "SVGAnimatedNumberList_baseVal_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGAnimatedPreserveAspectRatio')
class AnimatedPreserveAspectRatio extends NativeFieldWrapperClass1 {
  AnimatedPreserveAspectRatio.internal();

  @DocsEditable
  @DomName('SVGAnimatedPreserveAspectRatio.animVal')
  PreserveAspectRatio get animVal native "SVGAnimatedPreserveAspectRatio_animVal_Getter";

  @DocsEditable
  @DomName('SVGAnimatedPreserveAspectRatio.baseVal')
  PreserveAspectRatio get baseVal native "SVGAnimatedPreserveAspectRatio_baseVal_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGAnimatedRect')
class AnimatedRect extends NativeFieldWrapperClass1 {
  AnimatedRect.internal();

  @DocsEditable
  @DomName('SVGAnimatedRect.animVal')
  Rect get animVal native "SVGAnimatedRect_animVal_Getter";

  @DocsEditable
  @DomName('SVGAnimatedRect.baseVal')
  Rect get baseVal native "SVGAnimatedRect_baseVal_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGAnimatedString')
class AnimatedString extends NativeFieldWrapperClass1 {
  AnimatedString.internal();

  @DocsEditable
  @DomName('SVGAnimatedString.animVal')
  String get animVal native "SVGAnimatedString_animVal_Getter";

  @DocsEditable
  @DomName('SVGAnimatedString.baseVal')
  String get baseVal native "SVGAnimatedString_baseVal_Getter";

  @DocsEditable
  @DomName('SVGAnimatedString.baseVal')
  void set baseVal(String value) native "SVGAnimatedString_baseVal_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGAnimatedTransformList')
class AnimatedTransformList extends NativeFieldWrapperClass1 {
  AnimatedTransformList.internal();

  @DocsEditable
  @DomName('SVGAnimatedTransformList.animVal')
  TransformList get animVal native "SVGAnimatedTransformList_animVal_Getter";

  @DocsEditable
  @DomName('SVGAnimatedTransformList.baseVal')
  TransformList get baseVal native "SVGAnimatedTransformList_baseVal_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGAnimationElement')
class AnimationElement extends SvgElement implements Tests, ElementTimeControl, ExternalResourcesRequired {
  AnimationElement.internal() : super.internal();

  @DocsEditable
  factory AnimationElement() => _SvgElementFactoryProvider.createSvgElement_tag("animation");

  @DocsEditable
  @DomName('SVGAnimationElement.targetElement')
  SvgElement get targetElement native "SVGAnimationElement_targetElement_Getter";

  @DocsEditable
  @DomName('SVGAnimationElement.getCurrentTime')
  num getCurrentTime() native "SVGAnimationElement_getCurrentTime_Callback";

  @DocsEditable
  @DomName('SVGAnimationElement.getSimpleDuration')
  num getSimpleDuration() native "SVGAnimationElement_getSimpleDuration_Callback";

  @DocsEditable
  @DomName('SVGAnimationElement.getStartTime')
  num getStartTime() native "SVGAnimationElement_getStartTime_Callback";

  @DocsEditable
  @DomName('SVGAnimationElement.beginElement')
  void beginElement() native "SVGAnimationElement_beginElement_Callback";

  @DocsEditable
  @DomName('SVGAnimationElement.beginElementAt')
  void beginElementAt(num offset) native "SVGAnimationElement_beginElementAt_Callback";

  @DocsEditable
  @DomName('SVGAnimationElement.endElement')
  void endElement() native "SVGAnimationElement_endElement_Callback";

  @DocsEditable
  @DomName('SVGAnimationElement.endElementAt')
  void endElementAt(num offset) native "SVGAnimationElement_endElementAt_Callback";

  @DocsEditable
  @DomName('SVGAnimationElement.externalResourcesRequired')
  AnimatedBoolean get externalResourcesRequired native "SVGAnimationElement_externalResourcesRequired_Getter";

  @DocsEditable
  @DomName('SVGAnimationElement.requiredExtensions')
  StringList get requiredExtensions native "SVGAnimationElement_requiredExtensions_Getter";

  @DocsEditable
  @DomName('SVGAnimationElement.requiredFeatures')
  StringList get requiredFeatures native "SVGAnimationElement_requiredFeatures_Getter";

  @DocsEditable
  @DomName('SVGAnimationElement.systemLanguage')
  StringList get systemLanguage native "SVGAnimationElement_systemLanguage_Getter";

  @DocsEditable
  @DomName('SVGAnimationElement.hasExtension')
  bool hasExtension(String extension) native "SVGAnimationElement_hasExtension_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGCircleElement')
class CircleElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace {
  CircleElement.internal() : super.internal();

  @DocsEditable
  factory CircleElement() => _SvgElementFactoryProvider.createSvgElement_tag("circle");

  @DocsEditable
  @DomName('SVGCircleElement.cx')
  AnimatedLength get cx native "SVGCircleElement_cx_Getter";

  @DocsEditable
  @DomName('SVGCircleElement.cy')
  AnimatedLength get cy native "SVGCircleElement_cy_Getter";

  @DocsEditable
  @DomName('SVGCircleElement.r')
  AnimatedLength get r native "SVGCircleElement_r_Getter";

  @DocsEditable
  @DomName('SVGCircleElement.externalResourcesRequired')
  AnimatedBoolean get externalResourcesRequired native "SVGCircleElement_externalResourcesRequired_Getter";

  @DocsEditable
  @DomName('SVGCircleElement.xmllang')
  String get xmllang native "SVGCircleElement_xmllang_Getter";

  @DocsEditable
  @DomName('SVGCircleElement.xmllang')
  void set xmllang(String value) native "SVGCircleElement_xmllang_Setter";

  @DocsEditable
  @DomName('SVGCircleElement.xmlspace')
  String get xmlspace native "SVGCircleElement_xmlspace_Getter";

  @DocsEditable
  @DomName('SVGCircleElement.xmlspace')
  void set xmlspace(String value) native "SVGCircleElement_xmlspace_Setter";

  @DocsEditable
  @DomName('SVGCircleElement.farthestViewportElement')
  SvgElement get farthestViewportElement native "SVGCircleElement_farthestViewportElement_Getter";

  @DocsEditable
  @DomName('SVGCircleElement.nearestViewportElement')
  SvgElement get nearestViewportElement native "SVGCircleElement_nearestViewportElement_Getter";

  @DocsEditable
  @DomName('SVGCircleElement.getBBox')
  Rect getBBox() native "SVGCircleElement_getBBox_Callback";

  @DocsEditable
  @DomName('SVGCircleElement.getCTM')
  Matrix getCtm() native "SVGCircleElement_getCTM_Callback";

  @DocsEditable
  @DomName('SVGCircleElement.getScreenCTM')
  Matrix getScreenCtm() native "SVGCircleElement_getScreenCTM_Callback";

  @DocsEditable
  @DomName('SVGCircleElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native "SVGCircleElement_getTransformToElement_Callback";

  @DocsEditable
  @DomName('SVGCircleElement.className')
  AnimatedString get $dom_svgClassName native "SVGCircleElement_className_Getter";

  @DocsEditable
  @DomName('SVGCircleElement.style')
  CssStyleDeclaration get style native "SVGCircleElement_style_Getter";

  @DocsEditable
  @DomName('SVGCircleElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native "SVGCircleElement_getPresentationAttribute_Callback";

  @DocsEditable
  @DomName('SVGCircleElement.requiredExtensions')
  StringList get requiredExtensions native "SVGCircleElement_requiredExtensions_Getter";

  @DocsEditable
  @DomName('SVGCircleElement.requiredFeatures')
  StringList get requiredFeatures native "SVGCircleElement_requiredFeatures_Getter";

  @DocsEditable
  @DomName('SVGCircleElement.systemLanguage')
  StringList get systemLanguage native "SVGCircleElement_systemLanguage_Getter";

  @DocsEditable
  @DomName('SVGCircleElement.hasExtension')
  bool hasExtension(String extension) native "SVGCircleElement_hasExtension_Callback";

  @DocsEditable
  @DomName('SVGCircleElement.transform')
  AnimatedTransformList get transform native "SVGCircleElement_transform_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGClipPathElement')
class ClipPathElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace {
  ClipPathElement.internal() : super.internal();

  @DocsEditable
  factory ClipPathElement() => _SvgElementFactoryProvider.createSvgElement_tag("clipPath");

  @DocsEditable
  @DomName('SVGClipPathElement.clipPathUnits')
  AnimatedEnumeration get clipPathUnits native "SVGClipPathElement_clipPathUnits_Getter";

  @DocsEditable
  @DomName('SVGClipPathElement.externalResourcesRequired')
  AnimatedBoolean get externalResourcesRequired native "SVGClipPathElement_externalResourcesRequired_Getter";

  @DocsEditable
  @DomName('SVGClipPathElement.xmllang')
  String get xmllang native "SVGClipPathElement_xmllang_Getter";

  @DocsEditable
  @DomName('SVGClipPathElement.xmllang')
  void set xmllang(String value) native "SVGClipPathElement_xmllang_Setter";

  @DocsEditable
  @DomName('SVGClipPathElement.xmlspace')
  String get xmlspace native "SVGClipPathElement_xmlspace_Getter";

  @DocsEditable
  @DomName('SVGClipPathElement.xmlspace')
  void set xmlspace(String value) native "SVGClipPathElement_xmlspace_Setter";

  @DocsEditable
  @DomName('SVGClipPathElement.farthestViewportElement')
  SvgElement get farthestViewportElement native "SVGClipPathElement_farthestViewportElement_Getter";

  @DocsEditable
  @DomName('SVGClipPathElement.nearestViewportElement')
  SvgElement get nearestViewportElement native "SVGClipPathElement_nearestViewportElement_Getter";

  @DocsEditable
  @DomName('SVGClipPathElement.getBBox')
  Rect getBBox() native "SVGClipPathElement_getBBox_Callback";

  @DocsEditable
  @DomName('SVGClipPathElement.getCTM')
  Matrix getCtm() native "SVGClipPathElement_getCTM_Callback";

  @DocsEditable
  @DomName('SVGClipPathElement.getScreenCTM')
  Matrix getScreenCtm() native "SVGClipPathElement_getScreenCTM_Callback";

  @DocsEditable
  @DomName('SVGClipPathElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native "SVGClipPathElement_getTransformToElement_Callback";

  @DocsEditable
  @DomName('SVGClipPathElement.className')
  AnimatedString get $dom_svgClassName native "SVGClipPathElement_className_Getter";

  @DocsEditable
  @DomName('SVGClipPathElement.style')
  CssStyleDeclaration get style native "SVGClipPathElement_style_Getter";

  @DocsEditable
  @DomName('SVGClipPathElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native "SVGClipPathElement_getPresentationAttribute_Callback";

  @DocsEditable
  @DomName('SVGClipPathElement.requiredExtensions')
  StringList get requiredExtensions native "SVGClipPathElement_requiredExtensions_Getter";

  @DocsEditable
  @DomName('SVGClipPathElement.requiredFeatures')
  StringList get requiredFeatures native "SVGClipPathElement_requiredFeatures_Getter";

  @DocsEditable
  @DomName('SVGClipPathElement.systemLanguage')
  StringList get systemLanguage native "SVGClipPathElement_systemLanguage_Getter";

  @DocsEditable
  @DomName('SVGClipPathElement.hasExtension')
  bool hasExtension(String extension) native "SVGClipPathElement_hasExtension_Callback";

  @DocsEditable
  @DomName('SVGClipPathElement.transform')
  AnimatedTransformList get transform native "SVGClipPathElement_transform_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGColor')
class Color extends CssValue {
  Color.internal() : super.internal();

  static const int SVG_COLORTYPE_CURRENTCOLOR = 3;

  static const int SVG_COLORTYPE_RGBCOLOR = 1;

  static const int SVG_COLORTYPE_RGBCOLOR_ICCCOLOR = 2;

  static const int SVG_COLORTYPE_UNKNOWN = 0;

  @DocsEditable
  @DomName('SVGColor.colorType')
  int get colorType native "SVGColor_colorType_Getter";

  @DocsEditable
  @DomName('SVGColor.rgbColor')
  RgbColor get rgbColor native "SVGColor_rgbColor_Getter";

  @DocsEditable
  @DomName('SVGColor.setColor')
  void setColor(int colorType, String rgbColor, String iccColor) native "SVGColor_setColor_Callback";

  @DocsEditable
  @DomName('SVGColor.setRGBColor')
  void setRgbColor(String rgbColor) native "SVGColor_setRGBColor_Callback";

  @DocsEditable
  @DomName('SVGColor.setRGBColorICCColor')
  void setRgbColorIccColor(String rgbColor, String iccColor) native "SVGColor_setRGBColorICCColor_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGComponentTransferFunctionElement')
class ComponentTransferFunctionElement extends SvgElement {
  ComponentTransferFunctionElement.internal() : super.internal();

  static const int SVG_FECOMPONENTTRANSFER_TYPE_DISCRETE = 3;

  static const int SVG_FECOMPONENTTRANSFER_TYPE_GAMMA = 5;

  static const int SVG_FECOMPONENTTRANSFER_TYPE_IDENTITY = 1;

  static const int SVG_FECOMPONENTTRANSFER_TYPE_LINEAR = 4;

  static const int SVG_FECOMPONENTTRANSFER_TYPE_TABLE = 2;

  static const int SVG_FECOMPONENTTRANSFER_TYPE_UNKNOWN = 0;

  @DocsEditable
  @DomName('SVGComponentTransferFunctionElement.amplitude')
  AnimatedNumber get amplitude native "SVGComponentTransferFunctionElement_amplitude_Getter";

  @DocsEditable
  @DomName('SVGComponentTransferFunctionElement.exponent')
  AnimatedNumber get exponent native "SVGComponentTransferFunctionElement_exponent_Getter";

  @DocsEditable
  @DomName('SVGComponentTransferFunctionElement.intercept')
  AnimatedNumber get intercept native "SVGComponentTransferFunctionElement_intercept_Getter";

  @DocsEditable
  @DomName('SVGComponentTransferFunctionElement.offset')
  AnimatedNumber get offset native "SVGComponentTransferFunctionElement_offset_Getter";

  @DocsEditable
  @DomName('SVGComponentTransferFunctionElement.slope')
  AnimatedNumber get slope native "SVGComponentTransferFunctionElement_slope_Getter";

  @DocsEditable
  @DomName('SVGComponentTransferFunctionElement.tableValues')
  AnimatedNumberList get tableValues native "SVGComponentTransferFunctionElement_tableValues_Getter";

  @DocsEditable
  @DomName('SVGComponentTransferFunctionElement.type')
  AnimatedEnumeration get type native "SVGComponentTransferFunctionElement_type_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGCursorElement')
class CursorElement extends SvgElement implements UriReference, Tests, ExternalResourcesRequired {
  CursorElement.internal() : super.internal();

  @DocsEditable
  factory CursorElement() => _SvgElementFactoryProvider.createSvgElement_tag("cursor");

  @DocsEditable
  @DomName('SVGCursorElement.x')
  AnimatedLength get x native "SVGCursorElement_x_Getter";

  @DocsEditable
  @DomName('SVGCursorElement.y')
  AnimatedLength get y native "SVGCursorElement_y_Getter";

  @DocsEditable
  @DomName('SVGCursorElement.externalResourcesRequired')
  AnimatedBoolean get externalResourcesRequired native "SVGCursorElement_externalResourcesRequired_Getter";

  @DocsEditable
  @DomName('SVGCursorElement.requiredExtensions')
  StringList get requiredExtensions native "SVGCursorElement_requiredExtensions_Getter";

  @DocsEditable
  @DomName('SVGCursorElement.requiredFeatures')
  StringList get requiredFeatures native "SVGCursorElement_requiredFeatures_Getter";

  @DocsEditable
  @DomName('SVGCursorElement.systemLanguage')
  StringList get systemLanguage native "SVGCursorElement_systemLanguage_Getter";

  @DocsEditable
  @DomName('SVGCursorElement.hasExtension')
  bool hasExtension(String extension) native "SVGCursorElement_hasExtension_Callback";

  @DocsEditable
  @DomName('SVGCursorElement.href')
  AnimatedString get href native "SVGCursorElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGDefsElement')
class DefsElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace {
  DefsElement.internal() : super.internal();

  @DocsEditable
  factory DefsElement() => _SvgElementFactoryProvider.createSvgElement_tag("defs");

  @DocsEditable
  @DomName('SVGDefsElement.externalResourcesRequired')
  AnimatedBoolean get externalResourcesRequired native "SVGDefsElement_externalResourcesRequired_Getter";

  @DocsEditable
  @DomName('SVGDefsElement.xmllang')
  String get xmllang native "SVGDefsElement_xmllang_Getter";

  @DocsEditable
  @DomName('SVGDefsElement.xmllang')
  void set xmllang(String value) native "SVGDefsElement_xmllang_Setter";

  @DocsEditable
  @DomName('SVGDefsElement.xmlspace')
  String get xmlspace native "SVGDefsElement_xmlspace_Getter";

  @DocsEditable
  @DomName('SVGDefsElement.xmlspace')
  void set xmlspace(String value) native "SVGDefsElement_xmlspace_Setter";

  @DocsEditable
  @DomName('SVGDefsElement.farthestViewportElement')
  SvgElement get farthestViewportElement native "SVGDefsElement_farthestViewportElement_Getter";

  @DocsEditable
  @DomName('SVGDefsElement.nearestViewportElement')
  SvgElement get nearestViewportElement native "SVGDefsElement_nearestViewportElement_Getter";

  @DocsEditable
  @DomName('SVGDefsElement.getBBox')
  Rect getBBox() native "SVGDefsElement_getBBox_Callback";

  @DocsEditable
  @DomName('SVGDefsElement.getCTM')
  Matrix getCtm() native "SVGDefsElement_getCTM_Callback";

  @DocsEditable
  @DomName('SVGDefsElement.getScreenCTM')
  Matrix getScreenCtm() native "SVGDefsElement_getScreenCTM_Callback";

  @DocsEditable
  @DomName('SVGDefsElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native "SVGDefsElement_getTransformToElement_Callback";

  @DocsEditable
  @DomName('SVGDefsElement.className')
  AnimatedString get $dom_svgClassName native "SVGDefsElement_className_Getter";

  @DocsEditable
  @DomName('SVGDefsElement.style')
  CssStyleDeclaration get style native "SVGDefsElement_style_Getter";

  @DocsEditable
  @DomName('SVGDefsElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native "SVGDefsElement_getPresentationAttribute_Callback";

  @DocsEditable
  @DomName('SVGDefsElement.requiredExtensions')
  StringList get requiredExtensions native "SVGDefsElement_requiredExtensions_Getter";

  @DocsEditable
  @DomName('SVGDefsElement.requiredFeatures')
  StringList get requiredFeatures native "SVGDefsElement_requiredFeatures_Getter";

  @DocsEditable
  @DomName('SVGDefsElement.systemLanguage')
  StringList get systemLanguage native "SVGDefsElement_systemLanguage_Getter";

  @DocsEditable
  @DomName('SVGDefsElement.hasExtension')
  bool hasExtension(String extension) native "SVGDefsElement_hasExtension_Callback";

  @DocsEditable
  @DomName('SVGDefsElement.transform')
  AnimatedTransformList get transform native "SVGDefsElement_transform_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGDescElement')
class DescElement extends SvgElement implements Stylable, LangSpace {
  DescElement.internal() : super.internal();

  @DocsEditable
  factory DescElement() => _SvgElementFactoryProvider.createSvgElement_tag("desc");

  @DocsEditable
  @DomName('SVGDescElement.xmllang')
  String get xmllang native "SVGDescElement_xmllang_Getter";

  @DocsEditable
  @DomName('SVGDescElement.xmllang')
  void set xmllang(String value) native "SVGDescElement_xmllang_Setter";

  @DocsEditable
  @DomName('SVGDescElement.xmlspace')
  String get xmlspace native "SVGDescElement_xmlspace_Getter";

  @DocsEditable
  @DomName('SVGDescElement.xmlspace')
  void set xmlspace(String value) native "SVGDescElement_xmlspace_Setter";

  @DocsEditable
  @DomName('SVGDescElement.className')
  AnimatedString get $dom_svgClassName native "SVGDescElement_className_Getter";

  @DocsEditable
  @DomName('SVGDescElement.style')
  CssStyleDeclaration get style native "SVGDescElement_style_Getter";

  @DocsEditable
  @DomName('SVGDescElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native "SVGDescElement_getPresentationAttribute_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGElementInstance')
class ElementInstance extends EventTarget {
  ElementInstance.internal() : super.internal();

  static const EventStreamProvider<Event> abortEvent = const EventStreamProvider<Event>('abort');

  static const EventStreamProvider<Event> beforeCopyEvent = const EventStreamProvider<Event>('beforecopy');

  static const EventStreamProvider<Event> beforeCutEvent = const EventStreamProvider<Event>('beforecut');

  static const EventStreamProvider<Event> beforePasteEvent = const EventStreamProvider<Event>('beforepaste');

  static const EventStreamProvider<Event> blurEvent = const EventStreamProvider<Event>('blur');

  static const EventStreamProvider<Event> changeEvent = const EventStreamProvider<Event>('change');

  static const EventStreamProvider<MouseEvent> clickEvent = const EventStreamProvider<MouseEvent>('click');

  static const EventStreamProvider<MouseEvent> contextMenuEvent = const EventStreamProvider<MouseEvent>('contextmenu');

  static const EventStreamProvider<Event> copyEvent = const EventStreamProvider<Event>('copy');

  static const EventStreamProvider<Event> cutEvent = const EventStreamProvider<Event>('cut');

  static const EventStreamProvider<Event> doubleClickEvent = const EventStreamProvider<Event>('dblclick');

  static const EventStreamProvider<MouseEvent> dragEvent = const EventStreamProvider<MouseEvent>('drag');

  static const EventStreamProvider<MouseEvent> dragEndEvent = const EventStreamProvider<MouseEvent>('dragend');

  static const EventStreamProvider<MouseEvent> dragEnterEvent = const EventStreamProvider<MouseEvent>('dragenter');

  static const EventStreamProvider<MouseEvent> dragLeaveEvent = const EventStreamProvider<MouseEvent>('dragleave');

  static const EventStreamProvider<MouseEvent> dragOverEvent = const EventStreamProvider<MouseEvent>('dragover');

  static const EventStreamProvider<MouseEvent> dragStartEvent = const EventStreamProvider<MouseEvent>('dragstart');

  static const EventStreamProvider<MouseEvent> dropEvent = const EventStreamProvider<MouseEvent>('drop');

  static const EventStreamProvider<Event> errorEvent = const EventStreamProvider<Event>('error');

  static const EventStreamProvider<Event> focusEvent = const EventStreamProvider<Event>('focus');

  static const EventStreamProvider<Event> inputEvent = const EventStreamProvider<Event>('input');

  static const EventStreamProvider<KeyboardEvent> keyDownEvent = const EventStreamProvider<KeyboardEvent>('keydown');

  static const EventStreamProvider<KeyboardEvent> keyPressEvent = const EventStreamProvider<KeyboardEvent>('keypress');

  static const EventStreamProvider<KeyboardEvent> keyUpEvent = const EventStreamProvider<KeyboardEvent>('keyup');

  static const EventStreamProvider<Event> loadEvent = const EventStreamProvider<Event>('load');

  static const EventStreamProvider<MouseEvent> mouseDownEvent = const EventStreamProvider<MouseEvent>('mousedown');

  static const EventStreamProvider<MouseEvent> mouseMoveEvent = const EventStreamProvider<MouseEvent>('mousemove');

  static const EventStreamProvider<MouseEvent> mouseOutEvent = const EventStreamProvider<MouseEvent>('mouseout');

  static const EventStreamProvider<MouseEvent> mouseOverEvent = const EventStreamProvider<MouseEvent>('mouseover');

  static const EventStreamProvider<MouseEvent> mouseUpEvent = const EventStreamProvider<MouseEvent>('mouseup');

  static const EventStreamProvider<WheelEvent> mouseWheelEvent = const EventStreamProvider<WheelEvent>('mousewheel');

  static const EventStreamProvider<Event> pasteEvent = const EventStreamProvider<Event>('paste');

  static const EventStreamProvider<Event> resetEvent = const EventStreamProvider<Event>('reset');

  static const EventStreamProvider<Event> resizeEvent = const EventStreamProvider<Event>('resize');

  static const EventStreamProvider<Event> scrollEvent = const EventStreamProvider<Event>('scroll');

  static const EventStreamProvider<Event> searchEvent = const EventStreamProvider<Event>('search');

  static const EventStreamProvider<Event> selectEvent = const EventStreamProvider<Event>('select');

  static const EventStreamProvider<Event> selectStartEvent = const EventStreamProvider<Event>('selectstart');

  static const EventStreamProvider<Event> submitEvent = const EventStreamProvider<Event>('submit');

  static const EventStreamProvider<Event> unloadEvent = const EventStreamProvider<Event>('unload');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  ElementInstanceEvents get on =>
    new ElementInstanceEvents(this);

  @DocsEditable
  @DomName('SVGElementInstance.childNodes')
  List<ElementInstance> get childNodes native "SVGElementInstance_childNodes_Getter";

  @DocsEditable
  @DomName('SVGElementInstance.correspondingElement')
  SvgElement get correspondingElement native "SVGElementInstance_correspondingElement_Getter";

  @DocsEditable
  @DomName('SVGElementInstance.correspondingUseElement')
  UseElement get correspondingUseElement native "SVGElementInstance_correspondingUseElement_Getter";

  @DocsEditable
  @DomName('SVGElementInstance.firstChild')
  ElementInstance get firstChild native "SVGElementInstance_firstChild_Getter";

  @DocsEditable
  @DomName('SVGElementInstance.lastChild')
  ElementInstance get lastChild native "SVGElementInstance_lastChild_Getter";

  @DocsEditable
  @DomName('SVGElementInstance.nextSibling')
  ElementInstance get nextSibling native "SVGElementInstance_nextSibling_Getter";

  @DocsEditable
  @DomName('SVGElementInstance.parentNode')
  ElementInstance get parentNode native "SVGElementInstance_parentNode_Getter";

  @DocsEditable
  @DomName('SVGElementInstance.previousSibling')
  ElementInstance get previousSibling native "SVGElementInstance_previousSibling_Getter";

  Stream<Event> get onAbort => abortEvent.forTarget(this);

  Stream<Event> get onBeforeCopy => beforeCopyEvent.forTarget(this);

  Stream<Event> get onBeforeCut => beforeCutEvent.forTarget(this);

  Stream<Event> get onBeforePaste => beforePasteEvent.forTarget(this);

  Stream<Event> get onBlur => blurEvent.forTarget(this);

  Stream<Event> get onChange => changeEvent.forTarget(this);

  Stream<MouseEvent> get onClick => clickEvent.forTarget(this);

  Stream<MouseEvent> get onContextMenu => contextMenuEvent.forTarget(this);

  Stream<Event> get onCopy => copyEvent.forTarget(this);

  Stream<Event> get onCut => cutEvent.forTarget(this);

  Stream<Event> get onDoubleClick => doubleClickEvent.forTarget(this);

  Stream<MouseEvent> get onDrag => dragEvent.forTarget(this);

  Stream<MouseEvent> get onDragEnd => dragEndEvent.forTarget(this);

  Stream<MouseEvent> get onDragEnter => dragEnterEvent.forTarget(this);

  Stream<MouseEvent> get onDragLeave => dragLeaveEvent.forTarget(this);

  Stream<MouseEvent> get onDragOver => dragOverEvent.forTarget(this);

  Stream<MouseEvent> get onDragStart => dragStartEvent.forTarget(this);

  Stream<MouseEvent> get onDrop => dropEvent.forTarget(this);

  Stream<Event> get onError => errorEvent.forTarget(this);

  Stream<Event> get onFocus => focusEvent.forTarget(this);

  Stream<Event> get onInput => inputEvent.forTarget(this);

  Stream<KeyboardEvent> get onKeyDown => keyDownEvent.forTarget(this);

  Stream<KeyboardEvent> get onKeyPress => keyPressEvent.forTarget(this);

  Stream<KeyboardEvent> get onKeyUp => keyUpEvent.forTarget(this);

  Stream<Event> get onLoad => loadEvent.forTarget(this);

  Stream<MouseEvent> get onMouseDown => mouseDownEvent.forTarget(this);

  Stream<MouseEvent> get onMouseMove => mouseMoveEvent.forTarget(this);

  Stream<MouseEvent> get onMouseOut => mouseOutEvent.forTarget(this);

  Stream<MouseEvent> get onMouseOver => mouseOverEvent.forTarget(this);

  Stream<MouseEvent> get onMouseUp => mouseUpEvent.forTarget(this);

  Stream<WheelEvent> get onMouseWheel => mouseWheelEvent.forTarget(this);

  Stream<Event> get onPaste => pasteEvent.forTarget(this);

  Stream<Event> get onReset => resetEvent.forTarget(this);

  Stream<Event> get onResize => resizeEvent.forTarget(this);

  Stream<Event> get onScroll => scrollEvent.forTarget(this);

  Stream<Event> get onSearch => searchEvent.forTarget(this);

  Stream<Event> get onSelect => selectEvent.forTarget(this);

  Stream<Event> get onSelectStart => selectStartEvent.forTarget(this);

  Stream<Event> get onSubmit => submitEvent.forTarget(this);

  Stream<Event> get onUnload => unloadEvent.forTarget(this);

}

@DocsEditable
class ElementInstanceEvents extends Events {
  @DocsEditable
  ElementInstanceEvents(EventTarget _ptr) : super(_ptr);

  @DocsEditable
  EventListenerList get abort => this['abort'];

  @DocsEditable
  EventListenerList get beforeCopy => this['beforecopy'];

  @DocsEditable
  EventListenerList get beforeCut => this['beforecut'];

  @DocsEditable
  EventListenerList get beforePaste => this['beforepaste'];

  @DocsEditable
  EventListenerList get blur => this['blur'];

  @DocsEditable
  EventListenerList get change => this['change'];

  @DocsEditable
  EventListenerList get click => this['click'];

  @DocsEditable
  EventListenerList get contextMenu => this['contextmenu'];

  @DocsEditable
  EventListenerList get copy => this['copy'];

  @DocsEditable
  EventListenerList get cut => this['cut'];

  @DocsEditable
  EventListenerList get doubleClick => this['dblclick'];

  @DocsEditable
  EventListenerList get drag => this['drag'];

  @DocsEditable
  EventListenerList get dragEnd => this['dragend'];

  @DocsEditable
  EventListenerList get dragEnter => this['dragenter'];

  @DocsEditable
  EventListenerList get dragLeave => this['dragleave'];

  @DocsEditable
  EventListenerList get dragOver => this['dragover'];

  @DocsEditable
  EventListenerList get dragStart => this['dragstart'];

  @DocsEditable
  EventListenerList get drop => this['drop'];

  @DocsEditable
  EventListenerList get error => this['error'];

  @DocsEditable
  EventListenerList get focus => this['focus'];

  @DocsEditable
  EventListenerList get input => this['input'];

  @DocsEditable
  EventListenerList get keyDown => this['keydown'];

  @DocsEditable
  EventListenerList get keyPress => this['keypress'];

  @DocsEditable
  EventListenerList get keyUp => this['keyup'];

  @DocsEditable
  EventListenerList get load => this['load'];

  @DocsEditable
  EventListenerList get mouseDown => this['mousedown'];

  @DocsEditable
  EventListenerList get mouseMove => this['mousemove'];

  @DocsEditable
  EventListenerList get mouseOut => this['mouseout'];

  @DocsEditable
  EventListenerList get mouseOver => this['mouseover'];

  @DocsEditable
  EventListenerList get mouseUp => this['mouseup'];

  @DocsEditable
  EventListenerList get mouseWheel => this['mousewheel'];

  @DocsEditable
  EventListenerList get paste => this['paste'];

  @DocsEditable
  EventListenerList get reset => this['reset'];

  @DocsEditable
  EventListenerList get resize => this['resize'];

  @DocsEditable
  EventListenerList get scroll => this['scroll'];

  @DocsEditable
  EventListenerList get search => this['search'];

  @DocsEditable
  EventListenerList get select => this['select'];

  @DocsEditable
  EventListenerList get selectStart => this['selectstart'];

  @DocsEditable
  EventListenerList get submit => this['submit'];

  @DocsEditable
  EventListenerList get unload => this['unload'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('ElementTimeControl')
class ElementTimeControl extends NativeFieldWrapperClass1 {
  ElementTimeControl.internal();

  @DocsEditable
  @DomName('ElementTimeControl.beginElement')
  void beginElement() native "ElementTimeControl_beginElement_Callback";

  @DocsEditable
  @DomName('ElementTimeControl.beginElementAt')
  void beginElementAt(num offset) native "ElementTimeControl_beginElementAt_Callback";

  @DocsEditable
  @DomName('ElementTimeControl.endElement')
  void endElement() native "ElementTimeControl_endElement_Callback";

  @DocsEditable
  @DomName('ElementTimeControl.endElementAt')
  void endElementAt(num offset) native "ElementTimeControl_endElementAt_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGEllipseElement')
class EllipseElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace {
  EllipseElement.internal() : super.internal();

  @DocsEditable
  factory EllipseElement() => _SvgElementFactoryProvider.createSvgElement_tag("ellipse");

  @DocsEditable
  @DomName('SVGEllipseElement.cx')
  AnimatedLength get cx native "SVGEllipseElement_cx_Getter";

  @DocsEditable
  @DomName('SVGEllipseElement.cy')
  AnimatedLength get cy native "SVGEllipseElement_cy_Getter";

  @DocsEditable
  @DomName('SVGEllipseElement.rx')
  AnimatedLength get rx native "SVGEllipseElement_rx_Getter";

  @DocsEditable
  @DomName('SVGEllipseElement.ry')
  AnimatedLength get ry native "SVGEllipseElement_ry_Getter";

  @DocsEditable
  @DomName('SVGEllipseElement.externalResourcesRequired')
  AnimatedBoolean get externalResourcesRequired native "SVGEllipseElement_externalResourcesRequired_Getter";

  @DocsEditable
  @DomName('SVGEllipseElement.xmllang')
  String get xmllang native "SVGEllipseElement_xmllang_Getter";

  @DocsEditable
  @DomName('SVGEllipseElement.xmllang')
  void set xmllang(String value) native "SVGEllipseElement_xmllang_Setter";

  @DocsEditable
  @DomName('SVGEllipseElement.xmlspace')
  String get xmlspace native "SVGEllipseElement_xmlspace_Getter";

  @DocsEditable
  @DomName('SVGEllipseElement.xmlspace')
  void set xmlspace(String value) native "SVGEllipseElement_xmlspace_Setter";

  @DocsEditable
  @DomName('SVGEllipseElement.farthestViewportElement')
  SvgElement get farthestViewportElement native "SVGEllipseElement_farthestViewportElement_Getter";

  @DocsEditable
  @DomName('SVGEllipseElement.nearestViewportElement')
  SvgElement get nearestViewportElement native "SVGEllipseElement_nearestViewportElement_Getter";

  @DocsEditable
  @DomName('SVGEllipseElement.getBBox')
  Rect getBBox() native "SVGEllipseElement_getBBox_Callback";

  @DocsEditable
  @DomName('SVGEllipseElement.getCTM')
  Matrix getCtm() native "SVGEllipseElement_getCTM_Callback";

  @DocsEditable
  @DomName('SVGEllipseElement.getScreenCTM')
  Matrix getScreenCtm() native "SVGEllipseElement_getScreenCTM_Callback";

  @DocsEditable
  @DomName('SVGEllipseElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native "SVGEllipseElement_getTransformToElement_Callback";

  @DocsEditable
  @DomName('SVGEllipseElement.className')
  AnimatedString get $dom_svgClassName native "SVGEllipseElement_className_Getter";

  @DocsEditable
  @DomName('SVGEllipseElement.style')
  CssStyleDeclaration get style native "SVGEllipseElement_style_Getter";

  @DocsEditable
  @DomName('SVGEllipseElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native "SVGEllipseElement_getPresentationAttribute_Callback";

  @DocsEditable
  @DomName('SVGEllipseElement.requiredExtensions')
  StringList get requiredExtensions native "SVGEllipseElement_requiredExtensions_Getter";

  @DocsEditable
  @DomName('SVGEllipseElement.requiredFeatures')
  StringList get requiredFeatures native "SVGEllipseElement_requiredFeatures_Getter";

  @DocsEditable
  @DomName('SVGEllipseElement.systemLanguage')
  StringList get systemLanguage native "SVGEllipseElement_systemLanguage_Getter";

  @DocsEditable
  @DomName('SVGEllipseElement.hasExtension')
  bool hasExtension(String extension) native "SVGEllipseElement_hasExtension_Callback";

  @DocsEditable
  @DomName('SVGEllipseElement.transform')
  AnimatedTransformList get transform native "SVGEllipseElement_transform_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGExternalResourcesRequired')
class ExternalResourcesRequired extends NativeFieldWrapperClass1 {
  ExternalResourcesRequired.internal();

  @DocsEditable
  @DomName('SVGExternalResourcesRequired.externalResourcesRequired')
  AnimatedBoolean get externalResourcesRequired native "SVGExternalResourcesRequired_externalResourcesRequired_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFEBlendElement')
class FEBlendElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  FEBlendElement.internal() : super.internal();

  static const int SVG_FEBLEND_MODE_DARKEN = 4;

  static const int SVG_FEBLEND_MODE_LIGHTEN = 5;

  static const int SVG_FEBLEND_MODE_MULTIPLY = 2;

  static const int SVG_FEBLEND_MODE_NORMAL = 1;

  static const int SVG_FEBLEND_MODE_SCREEN = 3;

  static const int SVG_FEBLEND_MODE_UNKNOWN = 0;

  @DocsEditable
  @DomName('SVGFEBlendElement.in1')
  AnimatedString get in1 native "SVGFEBlendElement_in1_Getter";

  @DocsEditable
  @DomName('SVGFEBlendElement.in2')
  AnimatedString get in2 native "SVGFEBlendElement_in2_Getter";

  @DocsEditable
  @DomName('SVGFEBlendElement.mode')
  AnimatedEnumeration get mode native "SVGFEBlendElement_mode_Getter";

  @DocsEditable
  @DomName('SVGFEBlendElement.height')
  AnimatedLength get height native "SVGFEBlendElement_height_Getter";

  @DocsEditable
  @DomName('SVGFEBlendElement.result')
  AnimatedString get result native "SVGFEBlendElement_result_Getter";

  @DocsEditable
  @DomName('SVGFEBlendElement.width')
  AnimatedLength get width native "SVGFEBlendElement_width_Getter";

  @DocsEditable
  @DomName('SVGFEBlendElement.x')
  AnimatedLength get x native "SVGFEBlendElement_x_Getter";

  @DocsEditable
  @DomName('SVGFEBlendElement.y')
  AnimatedLength get y native "SVGFEBlendElement_y_Getter";

  @DocsEditable
  @DomName('SVGFEBlendElement.className')
  AnimatedString get $dom_svgClassName native "SVGFEBlendElement_className_Getter";

  @DocsEditable
  @DomName('SVGFEBlendElement.style')
  CssStyleDeclaration get style native "SVGFEBlendElement_style_Getter";

  @DocsEditable
  @DomName('SVGFEBlendElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native "SVGFEBlendElement_getPresentationAttribute_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFEColorMatrixElement')
class FEColorMatrixElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  FEColorMatrixElement.internal() : super.internal();

  static const int SVG_FECOLORMATRIX_TYPE_HUEROTATE = 3;

  static const int SVG_FECOLORMATRIX_TYPE_LUMINANCETOALPHA = 4;

  static const int SVG_FECOLORMATRIX_TYPE_MATRIX = 1;

  static const int SVG_FECOLORMATRIX_TYPE_SATURATE = 2;

  static const int SVG_FECOLORMATRIX_TYPE_UNKNOWN = 0;

  @DocsEditable
  @DomName('SVGFEColorMatrixElement.in1')
  AnimatedString get in1 native "SVGFEColorMatrixElement_in1_Getter";

  @DocsEditable
  @DomName('SVGFEColorMatrixElement.type')
  AnimatedEnumeration get type native "SVGFEColorMatrixElement_type_Getter";

  @DocsEditable
  @DomName('SVGFEColorMatrixElement.values')
  AnimatedNumberList get values native "SVGFEColorMatrixElement_values_Getter";

  @DocsEditable
  @DomName('SVGFEColorMatrixElement.height')
  AnimatedLength get height native "SVGFEColorMatrixElement_height_Getter";

  @DocsEditable
  @DomName('SVGFEColorMatrixElement.result')
  AnimatedString get result native "SVGFEColorMatrixElement_result_Getter";

  @DocsEditable
  @DomName('SVGFEColorMatrixElement.width')
  AnimatedLength get width native "SVGFEColorMatrixElement_width_Getter";

  @DocsEditable
  @DomName('SVGFEColorMatrixElement.x')
  AnimatedLength get x native "SVGFEColorMatrixElement_x_Getter";

  @DocsEditable
  @DomName('SVGFEColorMatrixElement.y')
  AnimatedLength get y native "SVGFEColorMatrixElement_y_Getter";

  @DocsEditable
  @DomName('SVGFEColorMatrixElement.className')
  AnimatedString get $dom_svgClassName native "SVGFEColorMatrixElement_className_Getter";

  @DocsEditable
  @DomName('SVGFEColorMatrixElement.style')
  CssStyleDeclaration get style native "SVGFEColorMatrixElement_style_Getter";

  @DocsEditable
  @DomName('SVGFEColorMatrixElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native "SVGFEColorMatrixElement_getPresentationAttribute_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFEComponentTransferElement')
class FEComponentTransferElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  FEComponentTransferElement.internal() : super.internal();

  @DocsEditable
  @DomName('SVGFEComponentTransferElement.in1')
  AnimatedString get in1 native "SVGFEComponentTransferElement_in1_Getter";

  @DocsEditable
  @DomName('SVGFEComponentTransferElement.height')
  AnimatedLength get height native "SVGFEComponentTransferElement_height_Getter";

  @DocsEditable
  @DomName('SVGFEComponentTransferElement.result')
  AnimatedString get result native "SVGFEComponentTransferElement_result_Getter";

  @DocsEditable
  @DomName('SVGFEComponentTransferElement.width')
  AnimatedLength get width native "SVGFEComponentTransferElement_width_Getter";

  @DocsEditable
  @DomName('SVGFEComponentTransferElement.x')
  AnimatedLength get x native "SVGFEComponentTransferElement_x_Getter";

  @DocsEditable
  @DomName('SVGFEComponentTransferElement.y')
  AnimatedLength get y native "SVGFEComponentTransferElement_y_Getter";

  @DocsEditable
  @DomName('SVGFEComponentTransferElement.className')
  AnimatedString get $dom_svgClassName native "SVGFEComponentTransferElement_className_Getter";

  @DocsEditable
  @DomName('SVGFEComponentTransferElement.style')
  CssStyleDeclaration get style native "SVGFEComponentTransferElement_style_Getter";

  @DocsEditable
  @DomName('SVGFEComponentTransferElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native "SVGFEComponentTransferElement_getPresentationAttribute_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFECompositeElement')
class FECompositeElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  FECompositeElement.internal() : super.internal();

  static const int SVG_FECOMPOSITE_OPERATOR_ARITHMETIC = 6;

  static const int SVG_FECOMPOSITE_OPERATOR_ATOP = 4;

  static const int SVG_FECOMPOSITE_OPERATOR_IN = 2;

  static const int SVG_FECOMPOSITE_OPERATOR_OUT = 3;

  static const int SVG_FECOMPOSITE_OPERATOR_OVER = 1;

  static const int SVG_FECOMPOSITE_OPERATOR_UNKNOWN = 0;

  static const int SVG_FECOMPOSITE_OPERATOR_XOR = 5;

  @DocsEditable
  @DomName('SVGFECompositeElement.in1')
  AnimatedString get in1 native "SVGFECompositeElement_in1_Getter";

  @DocsEditable
  @DomName('SVGFECompositeElement.in2')
  AnimatedString get in2 native "SVGFECompositeElement_in2_Getter";

  @DocsEditable
  @DomName('SVGFECompositeElement.k1')
  AnimatedNumber get k1 native "SVGFECompositeElement_k1_Getter";

  @DocsEditable
  @DomName('SVGFECompositeElement.k2')
  AnimatedNumber get k2 native "SVGFECompositeElement_k2_Getter";

  @DocsEditable
  @DomName('SVGFECompositeElement.k3')
  AnimatedNumber get k3 native "SVGFECompositeElement_k3_Getter";

  @DocsEditable
  @DomName('SVGFECompositeElement.k4')
  AnimatedNumber get k4 native "SVGFECompositeElement_k4_Getter";

  @DocsEditable
  @DomName('SVGFECompositeElement.operator')
  AnimatedEnumeration get operator native "SVGFECompositeElement_operator_Getter";

  @DocsEditable
  @DomName('SVGFECompositeElement.height')
  AnimatedLength get height native "SVGFECompositeElement_height_Getter";

  @DocsEditable
  @DomName('SVGFECompositeElement.result')
  AnimatedString get result native "SVGFECompositeElement_result_Getter";

  @DocsEditable
  @DomName('SVGFECompositeElement.width')
  AnimatedLength get width native "SVGFECompositeElement_width_Getter";

  @DocsEditable
  @DomName('SVGFECompositeElement.x')
  AnimatedLength get x native "SVGFECompositeElement_x_Getter";

  @DocsEditable
  @DomName('SVGFECompositeElement.y')
  AnimatedLength get y native "SVGFECompositeElement_y_Getter";

  @DocsEditable
  @DomName('SVGFECompositeElement.className')
  AnimatedString get $dom_svgClassName native "SVGFECompositeElement_className_Getter";

  @DocsEditable
  @DomName('SVGFECompositeElement.style')
  CssStyleDeclaration get style native "SVGFECompositeElement_style_Getter";

  @DocsEditable
  @DomName('SVGFECompositeElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native "SVGFECompositeElement_getPresentationAttribute_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFEConvolveMatrixElement')
class FEConvolveMatrixElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  FEConvolveMatrixElement.internal() : super.internal();

  static const int SVG_EDGEMODE_DUPLICATE = 1;

  static const int SVG_EDGEMODE_NONE = 3;

  static const int SVG_EDGEMODE_UNKNOWN = 0;

  static const int SVG_EDGEMODE_WRAP = 2;

  @DocsEditable
  @DomName('SVGFEConvolveMatrixElement.bias')
  AnimatedNumber get bias native "SVGFEConvolveMatrixElement_bias_Getter";

  @DocsEditable
  @DomName('SVGFEConvolveMatrixElement.divisor')
  AnimatedNumber get divisor native "SVGFEConvolveMatrixElement_divisor_Getter";

  @DocsEditable
  @DomName('SVGFEConvolveMatrixElement.edgeMode')
  AnimatedEnumeration get edgeMode native "SVGFEConvolveMatrixElement_edgeMode_Getter";

  @DocsEditable
  @DomName('SVGFEConvolveMatrixElement.in1')
  AnimatedString get in1 native "SVGFEConvolveMatrixElement_in1_Getter";

  @DocsEditable
  @DomName('SVGFEConvolveMatrixElement.kernelMatrix')
  AnimatedNumberList get kernelMatrix native "SVGFEConvolveMatrixElement_kernelMatrix_Getter";

  @DocsEditable
  @DomName('SVGFEConvolveMatrixElement.kernelUnitLengthX')
  AnimatedNumber get kernelUnitLengthX native "SVGFEConvolveMatrixElement_kernelUnitLengthX_Getter";

  @DocsEditable
  @DomName('SVGFEConvolveMatrixElement.kernelUnitLengthY')
  AnimatedNumber get kernelUnitLengthY native "SVGFEConvolveMatrixElement_kernelUnitLengthY_Getter";

  @DocsEditable
  @DomName('SVGFEConvolveMatrixElement.orderX')
  AnimatedInteger get orderX native "SVGFEConvolveMatrixElement_orderX_Getter";

  @DocsEditable
  @DomName('SVGFEConvolveMatrixElement.orderY')
  AnimatedInteger get orderY native "SVGFEConvolveMatrixElement_orderY_Getter";

  @DocsEditable
  @DomName('SVGFEConvolveMatrixElement.preserveAlpha')
  AnimatedBoolean get preserveAlpha native "SVGFEConvolveMatrixElement_preserveAlpha_Getter";

  @DocsEditable
  @DomName('SVGFEConvolveMatrixElement.targetX')
  AnimatedInteger get targetX native "SVGFEConvolveMatrixElement_targetX_Getter";

  @DocsEditable
  @DomName('SVGFEConvolveMatrixElement.targetY')
  AnimatedInteger get targetY native "SVGFEConvolveMatrixElement_targetY_Getter";

  @DocsEditable
  @DomName('SVGFEConvolveMatrixElement.height')
  AnimatedLength get height native "SVGFEConvolveMatrixElement_height_Getter";

  @DocsEditable
  @DomName('SVGFEConvolveMatrixElement.result')
  AnimatedString get result native "SVGFEConvolveMatrixElement_result_Getter";

  @DocsEditable
  @DomName('SVGFEConvolveMatrixElement.width')
  AnimatedLength get width native "SVGFEConvolveMatrixElement_width_Getter";

  @DocsEditable
  @DomName('SVGFEConvolveMatrixElement.x')
  AnimatedLength get x native "SVGFEConvolveMatrixElement_x_Getter";

  @DocsEditable
  @DomName('SVGFEConvolveMatrixElement.y')
  AnimatedLength get y native "SVGFEConvolveMatrixElement_y_Getter";

  @DocsEditable
  @DomName('SVGFEConvolveMatrixElement.className')
  AnimatedString get $dom_svgClassName native "SVGFEConvolveMatrixElement_className_Getter";

  @DocsEditable
  @DomName('SVGFEConvolveMatrixElement.style')
  CssStyleDeclaration get style native "SVGFEConvolveMatrixElement_style_Getter";

  @DocsEditable
  @DomName('SVGFEConvolveMatrixElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native "SVGFEConvolveMatrixElement_getPresentationAttribute_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFEDiffuseLightingElement')
class FEDiffuseLightingElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  FEDiffuseLightingElement.internal() : super.internal();

  @DocsEditable
  @DomName('SVGFEDiffuseLightingElement.diffuseConstant')
  AnimatedNumber get diffuseConstant native "SVGFEDiffuseLightingElement_diffuseConstant_Getter";

  @DocsEditable
  @DomName('SVGFEDiffuseLightingElement.in1')
  AnimatedString get in1 native "SVGFEDiffuseLightingElement_in1_Getter";

  @DocsEditable
  @DomName('SVGFEDiffuseLightingElement.kernelUnitLengthX')
  AnimatedNumber get kernelUnitLengthX native "SVGFEDiffuseLightingElement_kernelUnitLengthX_Getter";

  @DocsEditable
  @DomName('SVGFEDiffuseLightingElement.kernelUnitLengthY')
  AnimatedNumber get kernelUnitLengthY native "SVGFEDiffuseLightingElement_kernelUnitLengthY_Getter";

  @DocsEditable
  @DomName('SVGFEDiffuseLightingElement.surfaceScale')
  AnimatedNumber get surfaceScale native "SVGFEDiffuseLightingElement_surfaceScale_Getter";

  @DocsEditable
  @DomName('SVGFEDiffuseLightingElement.height')
  AnimatedLength get height native "SVGFEDiffuseLightingElement_height_Getter";

  @DocsEditable
  @DomName('SVGFEDiffuseLightingElement.result')
  AnimatedString get result native "SVGFEDiffuseLightingElement_result_Getter";

  @DocsEditable
  @DomName('SVGFEDiffuseLightingElement.width')
  AnimatedLength get width native "SVGFEDiffuseLightingElement_width_Getter";

  @DocsEditable
  @DomName('SVGFEDiffuseLightingElement.x')
  AnimatedLength get x native "SVGFEDiffuseLightingElement_x_Getter";

  @DocsEditable
  @DomName('SVGFEDiffuseLightingElement.y')
  AnimatedLength get y native "SVGFEDiffuseLightingElement_y_Getter";

  @DocsEditable
  @DomName('SVGFEDiffuseLightingElement.className')
  AnimatedString get $dom_svgClassName native "SVGFEDiffuseLightingElement_className_Getter";

  @DocsEditable
  @DomName('SVGFEDiffuseLightingElement.style')
  CssStyleDeclaration get style native "SVGFEDiffuseLightingElement_style_Getter";

  @DocsEditable
  @DomName('SVGFEDiffuseLightingElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native "SVGFEDiffuseLightingElement_getPresentationAttribute_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFEDisplacementMapElement')
class FEDisplacementMapElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  FEDisplacementMapElement.internal() : super.internal();

  static const int SVG_CHANNEL_A = 4;

  static const int SVG_CHANNEL_B = 3;

  static const int SVG_CHANNEL_G = 2;

  static const int SVG_CHANNEL_R = 1;

  static const int SVG_CHANNEL_UNKNOWN = 0;

  @DocsEditable
  @DomName('SVGFEDisplacementMapElement.in1')
  AnimatedString get in1 native "SVGFEDisplacementMapElement_in1_Getter";

  @DocsEditable
  @DomName('SVGFEDisplacementMapElement.in2')
  AnimatedString get in2 native "SVGFEDisplacementMapElement_in2_Getter";

  @DocsEditable
  @DomName('SVGFEDisplacementMapElement.scale')
  AnimatedNumber get scale native "SVGFEDisplacementMapElement_scale_Getter";

  @DocsEditable
  @DomName('SVGFEDisplacementMapElement.xChannelSelector')
  AnimatedEnumeration get xChannelSelector native "SVGFEDisplacementMapElement_xChannelSelector_Getter";

  @DocsEditable
  @DomName('SVGFEDisplacementMapElement.yChannelSelector')
  AnimatedEnumeration get yChannelSelector native "SVGFEDisplacementMapElement_yChannelSelector_Getter";

  @DocsEditable
  @DomName('SVGFEDisplacementMapElement.height')
  AnimatedLength get height native "SVGFEDisplacementMapElement_height_Getter";

  @DocsEditable
  @DomName('SVGFEDisplacementMapElement.result')
  AnimatedString get result native "SVGFEDisplacementMapElement_result_Getter";

  @DocsEditable
  @DomName('SVGFEDisplacementMapElement.width')
  AnimatedLength get width native "SVGFEDisplacementMapElement_width_Getter";

  @DocsEditable
  @DomName('SVGFEDisplacementMapElement.x')
  AnimatedLength get x native "SVGFEDisplacementMapElement_x_Getter";

  @DocsEditable
  @DomName('SVGFEDisplacementMapElement.y')
  AnimatedLength get y native "SVGFEDisplacementMapElement_y_Getter";

  @DocsEditable
  @DomName('SVGFEDisplacementMapElement.className')
  AnimatedString get $dom_svgClassName native "SVGFEDisplacementMapElement_className_Getter";

  @DocsEditable
  @DomName('SVGFEDisplacementMapElement.style')
  CssStyleDeclaration get style native "SVGFEDisplacementMapElement_style_Getter";

  @DocsEditable
  @DomName('SVGFEDisplacementMapElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native "SVGFEDisplacementMapElement_getPresentationAttribute_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFEDistantLightElement')
class FEDistantLightElement extends SvgElement {
  FEDistantLightElement.internal() : super.internal();

  @DocsEditable
  @DomName('SVGFEDistantLightElement.azimuth')
  AnimatedNumber get azimuth native "SVGFEDistantLightElement_azimuth_Getter";

  @DocsEditable
  @DomName('SVGFEDistantLightElement.elevation')
  AnimatedNumber get elevation native "SVGFEDistantLightElement_elevation_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFEDropShadowElement')
class FEDropShadowElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  FEDropShadowElement.internal() : super.internal();

  @DocsEditable
  @DomName('SVGFEDropShadowElement.dx')
  AnimatedNumber get dx native "SVGFEDropShadowElement_dx_Getter";

  @DocsEditable
  @DomName('SVGFEDropShadowElement.dy')
  AnimatedNumber get dy native "SVGFEDropShadowElement_dy_Getter";

  @DocsEditable
  @DomName('SVGFEDropShadowElement.in1')
  AnimatedString get in1 native "SVGFEDropShadowElement_in1_Getter";

  @DocsEditable
  @DomName('SVGFEDropShadowElement.stdDeviationX')
  AnimatedNumber get stdDeviationX native "SVGFEDropShadowElement_stdDeviationX_Getter";

  @DocsEditable
  @DomName('SVGFEDropShadowElement.stdDeviationY')
  AnimatedNumber get stdDeviationY native "SVGFEDropShadowElement_stdDeviationY_Getter";

  @DocsEditable
  @DomName('SVGFEDropShadowElement.setStdDeviation')
  void setStdDeviation(num stdDeviationX, num stdDeviationY) native "SVGFEDropShadowElement_setStdDeviation_Callback";

  @DocsEditable
  @DomName('SVGFEDropShadowElement.height')
  AnimatedLength get height native "SVGFEDropShadowElement_height_Getter";

  @DocsEditable
  @DomName('SVGFEDropShadowElement.result')
  AnimatedString get result native "SVGFEDropShadowElement_result_Getter";

  @DocsEditable
  @DomName('SVGFEDropShadowElement.width')
  AnimatedLength get width native "SVGFEDropShadowElement_width_Getter";

  @DocsEditable
  @DomName('SVGFEDropShadowElement.x')
  AnimatedLength get x native "SVGFEDropShadowElement_x_Getter";

  @DocsEditable
  @DomName('SVGFEDropShadowElement.y')
  AnimatedLength get y native "SVGFEDropShadowElement_y_Getter";

  @DocsEditable
  @DomName('SVGFEDropShadowElement.className')
  AnimatedString get $dom_svgClassName native "SVGFEDropShadowElement_className_Getter";

  @DocsEditable
  @DomName('SVGFEDropShadowElement.style')
  CssStyleDeclaration get style native "SVGFEDropShadowElement_style_Getter";

  @DocsEditable
  @DomName('SVGFEDropShadowElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native "SVGFEDropShadowElement_getPresentationAttribute_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFEFloodElement')
class FEFloodElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  FEFloodElement.internal() : super.internal();

  @DocsEditable
  @DomName('SVGFEFloodElement.height')
  AnimatedLength get height native "SVGFEFloodElement_height_Getter";

  @DocsEditable
  @DomName('SVGFEFloodElement.result')
  AnimatedString get result native "SVGFEFloodElement_result_Getter";

  @DocsEditable
  @DomName('SVGFEFloodElement.width')
  AnimatedLength get width native "SVGFEFloodElement_width_Getter";

  @DocsEditable
  @DomName('SVGFEFloodElement.x')
  AnimatedLength get x native "SVGFEFloodElement_x_Getter";

  @DocsEditable
  @DomName('SVGFEFloodElement.y')
  AnimatedLength get y native "SVGFEFloodElement_y_Getter";

  @DocsEditable
  @DomName('SVGFEFloodElement.className')
  AnimatedString get $dom_svgClassName native "SVGFEFloodElement_className_Getter";

  @DocsEditable
  @DomName('SVGFEFloodElement.style')
  CssStyleDeclaration get style native "SVGFEFloodElement_style_Getter";

  @DocsEditable
  @DomName('SVGFEFloodElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native "SVGFEFloodElement_getPresentationAttribute_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFEFuncAElement')
class FEFuncAElement extends ComponentTransferFunctionElement {
  FEFuncAElement.internal() : super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFEFuncBElement')
class FEFuncBElement extends ComponentTransferFunctionElement {
  FEFuncBElement.internal() : super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFEFuncGElement')
class FEFuncGElement extends ComponentTransferFunctionElement {
  FEFuncGElement.internal() : super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFEFuncRElement')
class FEFuncRElement extends ComponentTransferFunctionElement {
  FEFuncRElement.internal() : super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFEGaussianBlurElement')
class FEGaussianBlurElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  FEGaussianBlurElement.internal() : super.internal();

  @DocsEditable
  @DomName('SVGFEGaussianBlurElement.in1')
  AnimatedString get in1 native "SVGFEGaussianBlurElement_in1_Getter";

  @DocsEditable
  @DomName('SVGFEGaussianBlurElement.stdDeviationX')
  AnimatedNumber get stdDeviationX native "SVGFEGaussianBlurElement_stdDeviationX_Getter";

  @DocsEditable
  @DomName('SVGFEGaussianBlurElement.stdDeviationY')
  AnimatedNumber get stdDeviationY native "SVGFEGaussianBlurElement_stdDeviationY_Getter";

  @DocsEditable
  @DomName('SVGFEGaussianBlurElement.setStdDeviation')
  void setStdDeviation(num stdDeviationX, num stdDeviationY) native "SVGFEGaussianBlurElement_setStdDeviation_Callback";

  @DocsEditable
  @DomName('SVGFEGaussianBlurElement.height')
  AnimatedLength get height native "SVGFEGaussianBlurElement_height_Getter";

  @DocsEditable
  @DomName('SVGFEGaussianBlurElement.result')
  AnimatedString get result native "SVGFEGaussianBlurElement_result_Getter";

  @DocsEditable
  @DomName('SVGFEGaussianBlurElement.width')
  AnimatedLength get width native "SVGFEGaussianBlurElement_width_Getter";

  @DocsEditable
  @DomName('SVGFEGaussianBlurElement.x')
  AnimatedLength get x native "SVGFEGaussianBlurElement_x_Getter";

  @DocsEditable
  @DomName('SVGFEGaussianBlurElement.y')
  AnimatedLength get y native "SVGFEGaussianBlurElement_y_Getter";

  @DocsEditable
  @DomName('SVGFEGaussianBlurElement.className')
  AnimatedString get $dom_svgClassName native "SVGFEGaussianBlurElement_className_Getter";

  @DocsEditable
  @DomName('SVGFEGaussianBlurElement.style')
  CssStyleDeclaration get style native "SVGFEGaussianBlurElement_style_Getter";

  @DocsEditable
  @DomName('SVGFEGaussianBlurElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native "SVGFEGaussianBlurElement_getPresentationAttribute_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFEImageElement')
class FEImageElement extends SvgElement implements FilterPrimitiveStandardAttributes, UriReference, ExternalResourcesRequired, LangSpace {
  FEImageElement.internal() : super.internal();

  @DocsEditable
  @DomName('SVGFEImageElement.preserveAspectRatio')
  AnimatedPreserveAspectRatio get preserveAspectRatio native "SVGFEImageElement_preserveAspectRatio_Getter";

  @DocsEditable
  @DomName('SVGFEImageElement.externalResourcesRequired')
  AnimatedBoolean get externalResourcesRequired native "SVGFEImageElement_externalResourcesRequired_Getter";

  @DocsEditable
  @DomName('SVGFEImageElement.height')
  AnimatedLength get height native "SVGFEImageElement_height_Getter";

  @DocsEditable
  @DomName('SVGFEImageElement.result')
  AnimatedString get result native "SVGFEImageElement_result_Getter";

  @DocsEditable
  @DomName('SVGFEImageElement.width')
  AnimatedLength get width native "SVGFEImageElement_width_Getter";

  @DocsEditable
  @DomName('SVGFEImageElement.x')
  AnimatedLength get x native "SVGFEImageElement_x_Getter";

  @DocsEditable
  @DomName('SVGFEImageElement.y')
  AnimatedLength get y native "SVGFEImageElement_y_Getter";

  @DocsEditable
  @DomName('SVGFEImageElement.xmllang')
  String get xmllang native "SVGFEImageElement_xmllang_Getter";

  @DocsEditable
  @DomName('SVGFEImageElement.xmllang')
  void set xmllang(String value) native "SVGFEImageElement_xmllang_Setter";

  @DocsEditable
  @DomName('SVGFEImageElement.xmlspace')
  String get xmlspace native "SVGFEImageElement_xmlspace_Getter";

  @DocsEditable
  @DomName('SVGFEImageElement.xmlspace')
  void set xmlspace(String value) native "SVGFEImageElement_xmlspace_Setter";

  @DocsEditable
  @DomName('SVGFEImageElement.className')
  AnimatedString get $dom_svgClassName native "SVGFEImageElement_className_Getter";

  @DocsEditable
  @DomName('SVGFEImageElement.style')
  CssStyleDeclaration get style native "SVGFEImageElement_style_Getter";

  @DocsEditable
  @DomName('SVGFEImageElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native "SVGFEImageElement_getPresentationAttribute_Callback";

  @DocsEditable
  @DomName('SVGFEImageElement.href')
  AnimatedString get href native "SVGFEImageElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFEMergeElement')
class FEMergeElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  FEMergeElement.internal() : super.internal();

  @DocsEditable
  @DomName('SVGFEMergeElement.height')
  AnimatedLength get height native "SVGFEMergeElement_height_Getter";

  @DocsEditable
  @DomName('SVGFEMergeElement.result')
  AnimatedString get result native "SVGFEMergeElement_result_Getter";

  @DocsEditable
  @DomName('SVGFEMergeElement.width')
  AnimatedLength get width native "SVGFEMergeElement_width_Getter";

  @DocsEditable
  @DomName('SVGFEMergeElement.x')
  AnimatedLength get x native "SVGFEMergeElement_x_Getter";

  @DocsEditable
  @DomName('SVGFEMergeElement.y')
  AnimatedLength get y native "SVGFEMergeElement_y_Getter";

  @DocsEditable
  @DomName('SVGFEMergeElement.className')
  AnimatedString get $dom_svgClassName native "SVGFEMergeElement_className_Getter";

  @DocsEditable
  @DomName('SVGFEMergeElement.style')
  CssStyleDeclaration get style native "SVGFEMergeElement_style_Getter";

  @DocsEditable
  @DomName('SVGFEMergeElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native "SVGFEMergeElement_getPresentationAttribute_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFEMergeNodeElement')
class FEMergeNodeElement extends SvgElement {
  FEMergeNodeElement.internal() : super.internal();

  @DocsEditable
  @DomName('SVGFEMergeNodeElement.in1')
  AnimatedString get in1 native "SVGFEMergeNodeElement_in1_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFEMorphologyElement')
class FEMorphologyElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  FEMorphologyElement.internal() : super.internal();

  static const int SVG_MORPHOLOGY_OPERATOR_DILATE = 2;

  static const int SVG_MORPHOLOGY_OPERATOR_ERODE = 1;

  static const int SVG_MORPHOLOGY_OPERATOR_UNKNOWN = 0;

  @DocsEditable
  @DomName('SVGFEMorphologyElement.in1')
  AnimatedString get in1 native "SVGFEMorphologyElement_in1_Getter";

  @DocsEditable
  @DomName('SVGFEMorphologyElement.operator')
  AnimatedEnumeration get operator native "SVGFEMorphologyElement_operator_Getter";

  @DocsEditable
  @DomName('SVGFEMorphologyElement.radiusX')
  AnimatedNumber get radiusX native "SVGFEMorphologyElement_radiusX_Getter";

  @DocsEditable
  @DomName('SVGFEMorphologyElement.radiusY')
  AnimatedNumber get radiusY native "SVGFEMorphologyElement_radiusY_Getter";

  @DocsEditable
  @DomName('SVGFEMorphologyElement.setRadius')
  void setRadius(num radiusX, num radiusY) native "SVGFEMorphologyElement_setRadius_Callback";

  @DocsEditable
  @DomName('SVGFEMorphologyElement.height')
  AnimatedLength get height native "SVGFEMorphologyElement_height_Getter";

  @DocsEditable
  @DomName('SVGFEMorphologyElement.result')
  AnimatedString get result native "SVGFEMorphologyElement_result_Getter";

  @DocsEditable
  @DomName('SVGFEMorphologyElement.width')
  AnimatedLength get width native "SVGFEMorphologyElement_width_Getter";

  @DocsEditable
  @DomName('SVGFEMorphologyElement.x')
  AnimatedLength get x native "SVGFEMorphologyElement_x_Getter";

  @DocsEditable
  @DomName('SVGFEMorphologyElement.y')
  AnimatedLength get y native "SVGFEMorphologyElement_y_Getter";

  @DocsEditable
  @DomName('SVGFEMorphologyElement.className')
  AnimatedString get $dom_svgClassName native "SVGFEMorphologyElement_className_Getter";

  @DocsEditable
  @DomName('SVGFEMorphologyElement.style')
  CssStyleDeclaration get style native "SVGFEMorphologyElement_style_Getter";

  @DocsEditable
  @DomName('SVGFEMorphologyElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native "SVGFEMorphologyElement_getPresentationAttribute_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFEOffsetElement')
class FEOffsetElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  FEOffsetElement.internal() : super.internal();

  @DocsEditable
  @DomName('SVGFEOffsetElement.dx')
  AnimatedNumber get dx native "SVGFEOffsetElement_dx_Getter";

  @DocsEditable
  @DomName('SVGFEOffsetElement.dy')
  AnimatedNumber get dy native "SVGFEOffsetElement_dy_Getter";

  @DocsEditable
  @DomName('SVGFEOffsetElement.in1')
  AnimatedString get in1 native "SVGFEOffsetElement_in1_Getter";

  @DocsEditable
  @DomName('SVGFEOffsetElement.height')
  AnimatedLength get height native "SVGFEOffsetElement_height_Getter";

  @DocsEditable
  @DomName('SVGFEOffsetElement.result')
  AnimatedString get result native "SVGFEOffsetElement_result_Getter";

  @DocsEditable
  @DomName('SVGFEOffsetElement.width')
  AnimatedLength get width native "SVGFEOffsetElement_width_Getter";

  @DocsEditable
  @DomName('SVGFEOffsetElement.x')
  AnimatedLength get x native "SVGFEOffsetElement_x_Getter";

  @DocsEditable
  @DomName('SVGFEOffsetElement.y')
  AnimatedLength get y native "SVGFEOffsetElement_y_Getter";

  @DocsEditable
  @DomName('SVGFEOffsetElement.className')
  AnimatedString get $dom_svgClassName native "SVGFEOffsetElement_className_Getter";

  @DocsEditable
  @DomName('SVGFEOffsetElement.style')
  CssStyleDeclaration get style native "SVGFEOffsetElement_style_Getter";

  @DocsEditable
  @DomName('SVGFEOffsetElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native "SVGFEOffsetElement_getPresentationAttribute_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFEPointLightElement')
class FEPointLightElement extends SvgElement {
  FEPointLightElement.internal() : super.internal();

  @DocsEditable
  @DomName('SVGFEPointLightElement.x')
  AnimatedNumber get x native "SVGFEPointLightElement_x_Getter";

  @DocsEditable
  @DomName('SVGFEPointLightElement.y')
  AnimatedNumber get y native "SVGFEPointLightElement_y_Getter";

  @DocsEditable
  @DomName('SVGFEPointLightElement.z')
  AnimatedNumber get z native "SVGFEPointLightElement_z_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFESpecularLightingElement')
class FESpecularLightingElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  FESpecularLightingElement.internal() : super.internal();

  @DocsEditable
  @DomName('SVGFESpecularLightingElement.in1')
  AnimatedString get in1 native "SVGFESpecularLightingElement_in1_Getter";

  @DocsEditable
  @DomName('SVGFESpecularLightingElement.specularConstant')
  AnimatedNumber get specularConstant native "SVGFESpecularLightingElement_specularConstant_Getter";

  @DocsEditable
  @DomName('SVGFESpecularLightingElement.specularExponent')
  AnimatedNumber get specularExponent native "SVGFESpecularLightingElement_specularExponent_Getter";

  @DocsEditable
  @DomName('SVGFESpecularLightingElement.surfaceScale')
  AnimatedNumber get surfaceScale native "SVGFESpecularLightingElement_surfaceScale_Getter";

  @DocsEditable
  @DomName('SVGFESpecularLightingElement.height')
  AnimatedLength get height native "SVGFESpecularLightingElement_height_Getter";

  @DocsEditable
  @DomName('SVGFESpecularLightingElement.result')
  AnimatedString get result native "SVGFESpecularLightingElement_result_Getter";

  @DocsEditable
  @DomName('SVGFESpecularLightingElement.width')
  AnimatedLength get width native "SVGFESpecularLightingElement_width_Getter";

  @DocsEditable
  @DomName('SVGFESpecularLightingElement.x')
  AnimatedLength get x native "SVGFESpecularLightingElement_x_Getter";

  @DocsEditable
  @DomName('SVGFESpecularLightingElement.y')
  AnimatedLength get y native "SVGFESpecularLightingElement_y_Getter";

  @DocsEditable
  @DomName('SVGFESpecularLightingElement.className')
  AnimatedString get $dom_svgClassName native "SVGFESpecularLightingElement_className_Getter";

  @DocsEditable
  @DomName('SVGFESpecularLightingElement.style')
  CssStyleDeclaration get style native "SVGFESpecularLightingElement_style_Getter";

  @DocsEditable
  @DomName('SVGFESpecularLightingElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native "SVGFESpecularLightingElement_getPresentationAttribute_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFESpotLightElement')
class FESpotLightElement extends SvgElement {
  FESpotLightElement.internal() : super.internal();

  @DocsEditable
  @DomName('SVGFESpotLightElement.limitingConeAngle')
  AnimatedNumber get limitingConeAngle native "SVGFESpotLightElement_limitingConeAngle_Getter";

  @DocsEditable
  @DomName('SVGFESpotLightElement.pointsAtX')
  AnimatedNumber get pointsAtX native "SVGFESpotLightElement_pointsAtX_Getter";

  @DocsEditable
  @DomName('SVGFESpotLightElement.pointsAtY')
  AnimatedNumber get pointsAtY native "SVGFESpotLightElement_pointsAtY_Getter";

  @DocsEditable
  @DomName('SVGFESpotLightElement.pointsAtZ')
  AnimatedNumber get pointsAtZ native "SVGFESpotLightElement_pointsAtZ_Getter";

  @DocsEditable
  @DomName('SVGFESpotLightElement.specularExponent')
  AnimatedNumber get specularExponent native "SVGFESpotLightElement_specularExponent_Getter";

  @DocsEditable
  @DomName('SVGFESpotLightElement.x')
  AnimatedNumber get x native "SVGFESpotLightElement_x_Getter";

  @DocsEditable
  @DomName('SVGFESpotLightElement.y')
  AnimatedNumber get y native "SVGFESpotLightElement_y_Getter";

  @DocsEditable
  @DomName('SVGFESpotLightElement.z')
  AnimatedNumber get z native "SVGFESpotLightElement_z_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFETileElement')
class FETileElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  FETileElement.internal() : super.internal();

  @DocsEditable
  @DomName('SVGFETileElement.in1')
  AnimatedString get in1 native "SVGFETileElement_in1_Getter";

  @DocsEditable
  @DomName('SVGFETileElement.height')
  AnimatedLength get height native "SVGFETileElement_height_Getter";

  @DocsEditable
  @DomName('SVGFETileElement.result')
  AnimatedString get result native "SVGFETileElement_result_Getter";

  @DocsEditable
  @DomName('SVGFETileElement.width')
  AnimatedLength get width native "SVGFETileElement_width_Getter";

  @DocsEditable
  @DomName('SVGFETileElement.x')
  AnimatedLength get x native "SVGFETileElement_x_Getter";

  @DocsEditable
  @DomName('SVGFETileElement.y')
  AnimatedLength get y native "SVGFETileElement_y_Getter";

  @DocsEditable
  @DomName('SVGFETileElement.className')
  AnimatedString get $dom_svgClassName native "SVGFETileElement_className_Getter";

  @DocsEditable
  @DomName('SVGFETileElement.style')
  CssStyleDeclaration get style native "SVGFETileElement_style_Getter";

  @DocsEditable
  @DomName('SVGFETileElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native "SVGFETileElement_getPresentationAttribute_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFETurbulenceElement')
class FETurbulenceElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  FETurbulenceElement.internal() : super.internal();

  static const int SVG_STITCHTYPE_NOSTITCH = 2;

  static const int SVG_STITCHTYPE_STITCH = 1;

  static const int SVG_STITCHTYPE_UNKNOWN = 0;

  static const int SVG_TURBULENCE_TYPE_FRACTALNOISE = 1;

  static const int SVG_TURBULENCE_TYPE_TURBULENCE = 2;

  static const int SVG_TURBULENCE_TYPE_UNKNOWN = 0;

  @DocsEditable
  @DomName('SVGFETurbulenceElement.baseFrequencyX')
  AnimatedNumber get baseFrequencyX native "SVGFETurbulenceElement_baseFrequencyX_Getter";

  @DocsEditable
  @DomName('SVGFETurbulenceElement.baseFrequencyY')
  AnimatedNumber get baseFrequencyY native "SVGFETurbulenceElement_baseFrequencyY_Getter";

  @DocsEditable
  @DomName('SVGFETurbulenceElement.numOctaves')
  AnimatedInteger get numOctaves native "SVGFETurbulenceElement_numOctaves_Getter";

  @DocsEditable
  @DomName('SVGFETurbulenceElement.seed')
  AnimatedNumber get seed native "SVGFETurbulenceElement_seed_Getter";

  @DocsEditable
  @DomName('SVGFETurbulenceElement.stitchTiles')
  AnimatedEnumeration get stitchTiles native "SVGFETurbulenceElement_stitchTiles_Getter";

  @DocsEditable
  @DomName('SVGFETurbulenceElement.type')
  AnimatedEnumeration get type native "SVGFETurbulenceElement_type_Getter";

  @DocsEditable
  @DomName('SVGFETurbulenceElement.height')
  AnimatedLength get height native "SVGFETurbulenceElement_height_Getter";

  @DocsEditable
  @DomName('SVGFETurbulenceElement.result')
  AnimatedString get result native "SVGFETurbulenceElement_result_Getter";

  @DocsEditable
  @DomName('SVGFETurbulenceElement.width')
  AnimatedLength get width native "SVGFETurbulenceElement_width_Getter";

  @DocsEditable
  @DomName('SVGFETurbulenceElement.x')
  AnimatedLength get x native "SVGFETurbulenceElement_x_Getter";

  @DocsEditable
  @DomName('SVGFETurbulenceElement.y')
  AnimatedLength get y native "SVGFETurbulenceElement_y_Getter";

  @DocsEditable
  @DomName('SVGFETurbulenceElement.className')
  AnimatedString get $dom_svgClassName native "SVGFETurbulenceElement_className_Getter";

  @DocsEditable
  @DomName('SVGFETurbulenceElement.style')
  CssStyleDeclaration get style native "SVGFETurbulenceElement_style_Getter";

  @DocsEditable
  @DomName('SVGFETurbulenceElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native "SVGFETurbulenceElement_getPresentationAttribute_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFilterElement')
class FilterElement extends SvgElement implements UriReference, ExternalResourcesRequired, Stylable, LangSpace {
  FilterElement.internal() : super.internal();

  @DocsEditable
  factory FilterElement() => _SvgElementFactoryProvider.createSvgElement_tag("filter");

  @DocsEditable
  @DomName('SVGFilterElement.filterResX')
  AnimatedInteger get filterResX native "SVGFilterElement_filterResX_Getter";

  @DocsEditable
  @DomName('SVGFilterElement.filterResY')
  AnimatedInteger get filterResY native "SVGFilterElement_filterResY_Getter";

  @DocsEditable
  @DomName('SVGFilterElement.filterUnits')
  AnimatedEnumeration get filterUnits native "SVGFilterElement_filterUnits_Getter";

  @DocsEditable
  @DomName('SVGFilterElement.height')
  AnimatedLength get height native "SVGFilterElement_height_Getter";

  @DocsEditable
  @DomName('SVGFilterElement.primitiveUnits')
  AnimatedEnumeration get primitiveUnits native "SVGFilterElement_primitiveUnits_Getter";

  @DocsEditable
  @DomName('SVGFilterElement.width')
  AnimatedLength get width native "SVGFilterElement_width_Getter";

  @DocsEditable
  @DomName('SVGFilterElement.x')
  AnimatedLength get x native "SVGFilterElement_x_Getter";

  @DocsEditable
  @DomName('SVGFilterElement.y')
  AnimatedLength get y native "SVGFilterElement_y_Getter";

  @DocsEditable
  @DomName('SVGFilterElement.setFilterRes')
  void setFilterRes(int filterResX, int filterResY) native "SVGFilterElement_setFilterRes_Callback";

  @DocsEditable
  @DomName('SVGFilterElement.externalResourcesRequired')
  AnimatedBoolean get externalResourcesRequired native "SVGFilterElement_externalResourcesRequired_Getter";

  @DocsEditable
  @DomName('SVGFilterElement.xmllang')
  String get xmllang native "SVGFilterElement_xmllang_Getter";

  @DocsEditable
  @DomName('SVGFilterElement.xmllang')
  void set xmllang(String value) native "SVGFilterElement_xmllang_Setter";

  @DocsEditable
  @DomName('SVGFilterElement.xmlspace')
  String get xmlspace native "SVGFilterElement_xmlspace_Getter";

  @DocsEditable
  @DomName('SVGFilterElement.xmlspace')
  void set xmlspace(String value) native "SVGFilterElement_xmlspace_Setter";

  @DocsEditable
  @DomName('SVGFilterElement.className')
  AnimatedString get $dom_svgClassName native "SVGFilterElement_className_Getter";

  @DocsEditable
  @DomName('SVGFilterElement.style')
  CssStyleDeclaration get style native "SVGFilterElement_style_Getter";

  @DocsEditable
  @DomName('SVGFilterElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native "SVGFilterElement_getPresentationAttribute_Callback";

  @DocsEditable
  @DomName('SVGFilterElement.href')
  AnimatedString get href native "SVGFilterElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFilterPrimitiveStandardAttributes')
class FilterPrimitiveStandardAttributes extends NativeFieldWrapperClass1 implements Stylable {
  FilterPrimitiveStandardAttributes.internal();

  @DocsEditable
  @DomName('SVGFilterPrimitiveStandardAttributes.height')
  AnimatedLength get height native "SVGFilterPrimitiveStandardAttributes_height_Getter";

  @DocsEditable
  @DomName('SVGFilterPrimitiveStandardAttributes.result')
  AnimatedString get result native "SVGFilterPrimitiveStandardAttributes_result_Getter";

  @DocsEditable
  @DomName('SVGFilterPrimitiveStandardAttributes.width')
  AnimatedLength get width native "SVGFilterPrimitiveStandardAttributes_width_Getter";

  @DocsEditable
  @DomName('SVGFilterPrimitiveStandardAttributes.x')
  AnimatedLength get x native "SVGFilterPrimitiveStandardAttributes_x_Getter";

  @DocsEditable
  @DomName('SVGFilterPrimitiveStandardAttributes.y')
  AnimatedLength get y native "SVGFilterPrimitiveStandardAttributes_y_Getter";

  @DocsEditable
  @DomName('SVGFilterPrimitiveStandardAttributes.className')
  AnimatedString get $dom_svgClassName native "SVGFilterPrimitiveStandardAttributes_className_Getter";

  @DocsEditable
  @DomName('SVGFilterPrimitiveStandardAttributes.style')
  CssStyleDeclaration get style native "SVGFilterPrimitiveStandardAttributes_style_Getter";

  @DocsEditable
  @DomName('SVGFilterPrimitiveStandardAttributes.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native "SVGFilterPrimitiveStandardAttributes_getPresentationAttribute_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFitToViewBox')
class FitToViewBox extends NativeFieldWrapperClass1 {
  FitToViewBox.internal();

  @DocsEditable
  @DomName('SVGFitToViewBox.preserveAspectRatio')
  AnimatedPreserveAspectRatio get preserveAspectRatio native "SVGFitToViewBox_preserveAspectRatio_Getter";

  @DocsEditable
  @DomName('SVGFitToViewBox.viewBox')
  AnimatedRect get viewBox native "SVGFitToViewBox_viewBox_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFontElement')
class FontElement extends SvgElement {
  FontElement.internal() : super.internal();

  @DocsEditable
  factory FontElement() => _SvgElementFactoryProvider.createSvgElement_tag("font");

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFontFaceElement')
class FontFaceElement extends SvgElement {
  FontFaceElement.internal() : super.internal();

  @DocsEditable
  factory FontFaceElement() => _SvgElementFactoryProvider.createSvgElement_tag("font-face");

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFontFaceFormatElement')
class FontFaceFormatElement extends SvgElement {
  FontFaceFormatElement.internal() : super.internal();

  @DocsEditable
  factory FontFaceFormatElement() => _SvgElementFactoryProvider.createSvgElement_tag("font-face-format");

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFontFaceNameElement')
class FontFaceNameElement extends SvgElement {
  FontFaceNameElement.internal() : super.internal();

  @DocsEditable
  factory FontFaceNameElement() => _SvgElementFactoryProvider.createSvgElement_tag("font-face-name");

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFontFaceSrcElement')
class FontFaceSrcElement extends SvgElement {
  FontFaceSrcElement.internal() : super.internal();

  @DocsEditable
  factory FontFaceSrcElement() => _SvgElementFactoryProvider.createSvgElement_tag("font-face-src");

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFontFaceUriElement')
class FontFaceUriElement extends SvgElement {
  FontFaceUriElement.internal() : super.internal();

  @DocsEditable
  factory FontFaceUriElement() => _SvgElementFactoryProvider.createSvgElement_tag("font-face-uri");

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGForeignObjectElement')
class ForeignObjectElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace {
  ForeignObjectElement.internal() : super.internal();

  @DocsEditable
  factory ForeignObjectElement() => _SvgElementFactoryProvider.createSvgElement_tag("foreignObject");

  @DocsEditable
  @DomName('SVGForeignObjectElement.height')
  AnimatedLength get height native "SVGForeignObjectElement_height_Getter";

  @DocsEditable
  @DomName('SVGForeignObjectElement.width')
  AnimatedLength get width native "SVGForeignObjectElement_width_Getter";

  @DocsEditable
  @DomName('SVGForeignObjectElement.x')
  AnimatedLength get x native "SVGForeignObjectElement_x_Getter";

  @DocsEditable
  @DomName('SVGForeignObjectElement.y')
  AnimatedLength get y native "SVGForeignObjectElement_y_Getter";

  @DocsEditable
  @DomName('SVGForeignObjectElement.externalResourcesRequired')
  AnimatedBoolean get externalResourcesRequired native "SVGForeignObjectElement_externalResourcesRequired_Getter";

  @DocsEditable
  @DomName('SVGForeignObjectElement.xmllang')
  String get xmllang native "SVGForeignObjectElement_xmllang_Getter";

  @DocsEditable
  @DomName('SVGForeignObjectElement.xmllang')
  void set xmllang(String value) native "SVGForeignObjectElement_xmllang_Setter";

  @DocsEditable
  @DomName('SVGForeignObjectElement.xmlspace')
  String get xmlspace native "SVGForeignObjectElement_xmlspace_Getter";

  @DocsEditable
  @DomName('SVGForeignObjectElement.xmlspace')
  void set xmlspace(String value) native "SVGForeignObjectElement_xmlspace_Setter";

  @DocsEditable
  @DomName('SVGForeignObjectElement.farthestViewportElement')
  SvgElement get farthestViewportElement native "SVGForeignObjectElement_farthestViewportElement_Getter";

  @DocsEditable
  @DomName('SVGForeignObjectElement.nearestViewportElement')
  SvgElement get nearestViewportElement native "SVGForeignObjectElement_nearestViewportElement_Getter";

  @DocsEditable
  @DomName('SVGForeignObjectElement.getBBox')
  Rect getBBox() native "SVGForeignObjectElement_getBBox_Callback";

  @DocsEditable
  @DomName('SVGForeignObjectElement.getCTM')
  Matrix getCtm() native "SVGForeignObjectElement_getCTM_Callback";

  @DocsEditable
  @DomName('SVGForeignObjectElement.getScreenCTM')
  Matrix getScreenCtm() native "SVGForeignObjectElement_getScreenCTM_Callback";

  @DocsEditable
  @DomName('SVGForeignObjectElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native "SVGForeignObjectElement_getTransformToElement_Callback";

  @DocsEditable
  @DomName('SVGForeignObjectElement.className')
  AnimatedString get $dom_svgClassName native "SVGForeignObjectElement_className_Getter";

  @DocsEditable
  @DomName('SVGForeignObjectElement.style')
  CssStyleDeclaration get style native "SVGForeignObjectElement_style_Getter";

  @DocsEditable
  @DomName('SVGForeignObjectElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native "SVGForeignObjectElement_getPresentationAttribute_Callback";

  @DocsEditable
  @DomName('SVGForeignObjectElement.requiredExtensions')
  StringList get requiredExtensions native "SVGForeignObjectElement_requiredExtensions_Getter";

  @DocsEditable
  @DomName('SVGForeignObjectElement.requiredFeatures')
  StringList get requiredFeatures native "SVGForeignObjectElement_requiredFeatures_Getter";

  @DocsEditable
  @DomName('SVGForeignObjectElement.systemLanguage')
  StringList get systemLanguage native "SVGForeignObjectElement_systemLanguage_Getter";

  @DocsEditable
  @DomName('SVGForeignObjectElement.hasExtension')
  bool hasExtension(String extension) native "SVGForeignObjectElement_hasExtension_Callback";

  @DocsEditable
  @DomName('SVGForeignObjectElement.transform')
  AnimatedTransformList get transform native "SVGForeignObjectElement_transform_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGGElement')
class GElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace {
  GElement.internal() : super.internal();

  @DocsEditable
  factory GElement() => _SvgElementFactoryProvider.createSvgElement_tag("g");

  @DocsEditable
  @DomName('SVGGElement.externalResourcesRequired')
  AnimatedBoolean get externalResourcesRequired native "SVGGElement_externalResourcesRequired_Getter";

  @DocsEditable
  @DomName('SVGGElement.xmllang')
  String get xmllang native "SVGGElement_xmllang_Getter";

  @DocsEditable
  @DomName('SVGGElement.xmllang')
  void set xmllang(String value) native "SVGGElement_xmllang_Setter";

  @DocsEditable
  @DomName('SVGGElement.xmlspace')
  String get xmlspace native "SVGGElement_xmlspace_Getter";

  @DocsEditable
  @DomName('SVGGElement.xmlspace')
  void set xmlspace(String value) native "SVGGElement_xmlspace_Setter";

  @DocsEditable
  @DomName('SVGGElement.farthestViewportElement')
  SvgElement get farthestViewportElement native "SVGGElement_farthestViewportElement_Getter";

  @DocsEditable
  @DomName('SVGGElement.nearestViewportElement')
  SvgElement get nearestViewportElement native "SVGGElement_nearestViewportElement_Getter";

  @DocsEditable
  @DomName('SVGGElement.getBBox')
  Rect getBBox() native "SVGGElement_getBBox_Callback";

  @DocsEditable
  @DomName('SVGGElement.getCTM')
  Matrix getCtm() native "SVGGElement_getCTM_Callback";

  @DocsEditable
  @DomName('SVGGElement.getScreenCTM')
  Matrix getScreenCtm() native "SVGGElement_getScreenCTM_Callback";

  @DocsEditable
  @DomName('SVGGElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native "SVGGElement_getTransformToElement_Callback";

  @DocsEditable
  @DomName('SVGGElement.className')
  AnimatedString get $dom_svgClassName native "SVGGElement_className_Getter";

  @DocsEditable
  @DomName('SVGGElement.style')
  CssStyleDeclaration get style native "SVGGElement_style_Getter";

  @DocsEditable
  @DomName('SVGGElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native "SVGGElement_getPresentationAttribute_Callback";

  @DocsEditable
  @DomName('SVGGElement.requiredExtensions')
  StringList get requiredExtensions native "SVGGElement_requiredExtensions_Getter";

  @DocsEditable
  @DomName('SVGGElement.requiredFeatures')
  StringList get requiredFeatures native "SVGGElement_requiredFeatures_Getter";

  @DocsEditable
  @DomName('SVGGElement.systemLanguage')
  StringList get systemLanguage native "SVGGElement_systemLanguage_Getter";

  @DocsEditable
  @DomName('SVGGElement.hasExtension')
  bool hasExtension(String extension) native "SVGGElement_hasExtension_Callback";

  @DocsEditable
  @DomName('SVGGElement.transform')
  AnimatedTransformList get transform native "SVGGElement_transform_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGGlyphElement')
class GlyphElement extends SvgElement {
  GlyphElement.internal() : super.internal();

  @DocsEditable
  factory GlyphElement() => _SvgElementFactoryProvider.createSvgElement_tag("glyph");

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGGlyphRefElement')
class GlyphRefElement extends SvgElement implements UriReference, Stylable {
  GlyphRefElement.internal() : super.internal();

  @DocsEditable
  @DomName('SVGGlyphRefElement.dx')
  num get dx native "SVGGlyphRefElement_dx_Getter";

  @DocsEditable
  @DomName('SVGGlyphRefElement.dx')
  void set dx(num value) native "SVGGlyphRefElement_dx_Setter";

  @DocsEditable
  @DomName('SVGGlyphRefElement.dy')
  num get dy native "SVGGlyphRefElement_dy_Getter";

  @DocsEditable
  @DomName('SVGGlyphRefElement.dy')
  void set dy(num value) native "SVGGlyphRefElement_dy_Setter";

  @DocsEditable
  @DomName('SVGGlyphRefElement.format')
  String get format native "SVGGlyphRefElement_format_Getter";

  @DocsEditable
  @DomName('SVGGlyphRefElement.format')
  void set format(String value) native "SVGGlyphRefElement_format_Setter";

  @DocsEditable
  @DomName('SVGGlyphRefElement.glyphRef')
  String get glyphRef native "SVGGlyphRefElement_glyphRef_Getter";

  @DocsEditable
  @DomName('SVGGlyphRefElement.glyphRef')
  void set glyphRef(String value) native "SVGGlyphRefElement_glyphRef_Setter";

  @DocsEditable
  @DomName('SVGGlyphRefElement.x')
  num get x native "SVGGlyphRefElement_x_Getter";

  @DocsEditable
  @DomName('SVGGlyphRefElement.x')
  void set x(num value) native "SVGGlyphRefElement_x_Setter";

  @DocsEditable
  @DomName('SVGGlyphRefElement.y')
  num get y native "SVGGlyphRefElement_y_Getter";

  @DocsEditable
  @DomName('SVGGlyphRefElement.y')
  void set y(num value) native "SVGGlyphRefElement_y_Setter";

  @DocsEditable
  @DomName('SVGGlyphRefElement.className')
  AnimatedString get $dom_svgClassName native "SVGGlyphRefElement_className_Getter";

  @DocsEditable
  @DomName('SVGGlyphRefElement.style')
  CssStyleDeclaration get style native "SVGGlyphRefElement_style_Getter";

  @DocsEditable
  @DomName('SVGGlyphRefElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native "SVGGlyphRefElement_getPresentationAttribute_Callback";

  @DocsEditable
  @DomName('SVGGlyphRefElement.href')
  AnimatedString get href native "SVGGlyphRefElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGGradientElement')
class GradientElement extends SvgElement implements UriReference, ExternalResourcesRequired, Stylable {
  GradientElement.internal() : super.internal();

  static const int SVG_SPREADMETHOD_PAD = 1;

  static const int SVG_SPREADMETHOD_REFLECT = 2;

  static const int SVG_SPREADMETHOD_REPEAT = 3;

  static const int SVG_SPREADMETHOD_UNKNOWN = 0;

  @DocsEditable
  @DomName('SVGGradientElement.gradientTransform')
  AnimatedTransformList get gradientTransform native "SVGGradientElement_gradientTransform_Getter";

  @DocsEditable
  @DomName('SVGGradientElement.gradientUnits')
  AnimatedEnumeration get gradientUnits native "SVGGradientElement_gradientUnits_Getter";

  @DocsEditable
  @DomName('SVGGradientElement.spreadMethod')
  AnimatedEnumeration get spreadMethod native "SVGGradientElement_spreadMethod_Getter";

  @DocsEditable
  @DomName('SVGGradientElement.externalResourcesRequired')
  AnimatedBoolean get externalResourcesRequired native "SVGGradientElement_externalResourcesRequired_Getter";

  @DocsEditable
  @DomName('SVGGradientElement.className')
  AnimatedString get $dom_svgClassName native "SVGGradientElement_className_Getter";

  @DocsEditable
  @DomName('SVGGradientElement.style')
  CssStyleDeclaration get style native "SVGGradientElement_style_Getter";

  @DocsEditable
  @DomName('SVGGradientElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native "SVGGradientElement_getPresentationAttribute_Callback";

  @DocsEditable
  @DomName('SVGGradientElement.href')
  AnimatedString get href native "SVGGradientElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGHKernElement')
class HKernElement extends SvgElement {
  HKernElement.internal() : super.internal();

  @DocsEditable
  factory HKernElement() => _SvgElementFactoryProvider.createSvgElement_tag("hkern");

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGImageElement')
class ImageElement extends SvgElement implements Transformable, Tests, UriReference, Stylable, ExternalResourcesRequired, LangSpace {
  ImageElement.internal() : super.internal();

  @DocsEditable
  factory ImageElement() => _SvgElementFactoryProvider.createSvgElement_tag("image");

  @DocsEditable
  @DomName('SVGImageElement.height')
  AnimatedLength get height native "SVGImageElement_height_Getter";

  @DocsEditable
  @DomName('SVGImageElement.preserveAspectRatio')
  AnimatedPreserveAspectRatio get preserveAspectRatio native "SVGImageElement_preserveAspectRatio_Getter";

  @DocsEditable
  @DomName('SVGImageElement.width')
  AnimatedLength get width native "SVGImageElement_width_Getter";

  @DocsEditable
  @DomName('SVGImageElement.x')
  AnimatedLength get x native "SVGImageElement_x_Getter";

  @DocsEditable
  @DomName('SVGImageElement.y')
  AnimatedLength get y native "SVGImageElement_y_Getter";

  @DocsEditable
  @DomName('SVGImageElement.externalResourcesRequired')
  AnimatedBoolean get externalResourcesRequired native "SVGImageElement_externalResourcesRequired_Getter";

  @DocsEditable
  @DomName('SVGImageElement.xmllang')
  String get xmllang native "SVGImageElement_xmllang_Getter";

  @DocsEditable
  @DomName('SVGImageElement.xmllang')
  void set xmllang(String value) native "SVGImageElement_xmllang_Setter";

  @DocsEditable
  @DomName('SVGImageElement.xmlspace')
  String get xmlspace native "SVGImageElement_xmlspace_Getter";

  @DocsEditable
  @DomName('SVGImageElement.xmlspace')
  void set xmlspace(String value) native "SVGImageElement_xmlspace_Setter";

  @DocsEditable
  @DomName('SVGImageElement.farthestViewportElement')
  SvgElement get farthestViewportElement native "SVGImageElement_farthestViewportElement_Getter";

  @DocsEditable
  @DomName('SVGImageElement.nearestViewportElement')
  SvgElement get nearestViewportElement native "SVGImageElement_nearestViewportElement_Getter";

  @DocsEditable
  @DomName('SVGImageElement.getBBox')
  Rect getBBox() native "SVGImageElement_getBBox_Callback";

  @DocsEditable
  @DomName('SVGImageElement.getCTM')
  Matrix getCtm() native "SVGImageElement_getCTM_Callback";

  @DocsEditable
  @DomName('SVGImageElement.getScreenCTM')
  Matrix getScreenCtm() native "SVGImageElement_getScreenCTM_Callback";

  @DocsEditable
  @DomName('SVGImageElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native "SVGImageElement_getTransformToElement_Callback";

  @DocsEditable
  @DomName('SVGImageElement.className')
  AnimatedString get $dom_svgClassName native "SVGImageElement_className_Getter";

  @DocsEditable
  @DomName('SVGImageElement.style')
  CssStyleDeclaration get style native "SVGImageElement_style_Getter";

  @DocsEditable
  @DomName('SVGImageElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native "SVGImageElement_getPresentationAttribute_Callback";

  @DocsEditable
  @DomName('SVGImageElement.requiredExtensions')
  StringList get requiredExtensions native "SVGImageElement_requiredExtensions_Getter";

  @DocsEditable
  @DomName('SVGImageElement.requiredFeatures')
  StringList get requiredFeatures native "SVGImageElement_requiredFeatures_Getter";

  @DocsEditable
  @DomName('SVGImageElement.systemLanguage')
  StringList get systemLanguage native "SVGImageElement_systemLanguage_Getter";

  @DocsEditable
  @DomName('SVGImageElement.hasExtension')
  bool hasExtension(String extension) native "SVGImageElement_hasExtension_Callback";

  @DocsEditable
  @DomName('SVGImageElement.transform')
  AnimatedTransformList get transform native "SVGImageElement_transform_Getter";

  @DocsEditable
  @DomName('SVGImageElement.href')
  AnimatedString get href native "SVGImageElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGLangSpace')
class LangSpace extends NativeFieldWrapperClass1 {
  LangSpace.internal();

  @DocsEditable
  @DomName('SVGLangSpace.xmllang')
  String get xmllang native "SVGLangSpace_xmllang_Getter";

  @DocsEditable
  @DomName('SVGLangSpace.xmllang')
  void set xmllang(String value) native "SVGLangSpace_xmllang_Setter";

  @DocsEditable
  @DomName('SVGLangSpace.xmlspace')
  String get xmlspace native "SVGLangSpace_xmlspace_Getter";

  @DocsEditable
  @DomName('SVGLangSpace.xmlspace')
  void set xmlspace(String value) native "SVGLangSpace_xmlspace_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGLength')
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

  @DocsEditable
  @DomName('SVGLength.unitType')
  int get unitType native "SVGLength_unitType_Getter";

  @DocsEditable
  @DomName('SVGLength.value')
  num get value native "SVGLength_value_Getter";

  @DocsEditable
  @DomName('SVGLength.value')
  void set value(num value) native "SVGLength_value_Setter";

  @DocsEditable
  @DomName('SVGLength.valueAsString')
  String get valueAsString native "SVGLength_valueAsString_Getter";

  @DocsEditable
  @DomName('SVGLength.valueAsString')
  void set valueAsString(String value) native "SVGLength_valueAsString_Setter";

  @DocsEditable
  @DomName('SVGLength.valueInSpecifiedUnits')
  num get valueInSpecifiedUnits native "SVGLength_valueInSpecifiedUnits_Getter";

  @DocsEditable
  @DomName('SVGLength.valueInSpecifiedUnits')
  void set valueInSpecifiedUnits(num value) native "SVGLength_valueInSpecifiedUnits_Setter";

  @DocsEditable
  @DomName('SVGLength.convertToSpecifiedUnits')
  void convertToSpecifiedUnits(int unitType) native "SVGLength_convertToSpecifiedUnits_Callback";

  @DocsEditable
  @DomName('SVGLength.newValueSpecifiedUnits')
  void newValueSpecifiedUnits(int unitType, num valueInSpecifiedUnits) native "SVGLength_newValueSpecifiedUnits_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGLengthList')
class LengthList extends NativeFieldWrapperClass1 implements List<Length> {
  LengthList.internal();

  @DocsEditable
  @DomName('SVGLengthList.numberOfItems')
  int get numberOfItems native "SVGLengthList_numberOfItems_Getter";

  Length operator[](int index) native "SVGLengthList_item_Callback";

  void operator[]=(int index, Length value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Length> mixins.
  // Length is the element type.

  // From Iterable<Length>:

  Iterator<Length> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<Length>(this);
  }

  // SVG Collections expose numberOfItems rather than length.
  int get length => numberOfItems;
  dynamic reduce(dynamic initialValue, dynamic combine(dynamic, Length)) {
    return Collections.reduce(this, initialValue, combine);
  }

  bool contains(Length element) => Collections.contains(this, element);

  void forEach(void f(Length element)) => Collections.forEach(this, f);

  String join([String separator]) => Collections.joinList(this, separator);

  List mappedBy(f(Length element)) => new MappedList<Length, dynamic>(this, f);

  Iterable<Length> where(bool f(Length element)) => new WhereIterable<Length>(this, f);

  bool every(bool f(Length element)) => Collections.every(this, f);

  bool any(bool f(Length element)) => Collections.any(this, f);

  List<Length> toList() => new List<Length>.from(this);
  Set<Length> toSet() => new Set<Length>.from(this);

  bool get isEmpty => this.length == 0;

  List<Length> take(int n) => new ListView<Length>(this, 0, n);

  Iterable<Length> takeWhile(bool test(Length value)) {
    return new TakeWhileIterable<Length>(this, test);
  }

  List<Length> skip(int n) => new ListView<Length>(this, n, null);

  Iterable<Length> skipWhile(bool test(Length value)) {
    return new SkipWhileIterable<Length>(this, test);
  }

  Length firstMatching(bool test(Length value), { Length orElse() }) {
    return Collections.firstMatching(this, test, orElse);
  }

  Length lastMatching(bool test(Length value), {Length orElse()}) {
    return Collections.lastMatchingInList(this, test, orElse);
  }

  Length singleMatching(bool test(Length value)) {
    return Collections.singleMatching(this, test);
  }

  Length elementAt(int index) {
    return this[index];
  }

  // From Collection<Length>:

  void add(Length value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(Length value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<Length> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<Length>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  // contains() defined by IDL.

  void sort([int compare(Length a, Length b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(Length element, [int start = 0]) =>
      Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(Length element, [int start]) {
    if (start == null) start = length - 1;
    return Lists.lastIndexOf(this, element, start);
  }

  Length get first {
    if (this.length > 0) return this[0];
    throw new StateError("No elements");
  }

  Length get last {
    if (this.length > 0) return this[this.length - 1];
    throw new StateError("No elements");
  }

  Length get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  Length min([int compare(Length a, Length b)]) => Collections.min(this, compare);

  Length max([int compare(Length a, Length b)]) => Collections.max(this, compare);

  Length removeAt(int pos) {
    throw new UnsupportedError("Cannot removeAt on immutable List.");
  }

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
      Lists.getRange(this, start, rangeLength, <Length>[]);

  // -- end List<Length> mixins.

  @DocsEditable
  @DomName('SVGLengthList.appendItem')
  Length appendItem(Length item) native "SVGLengthList_appendItem_Callback";

  @DocsEditable
  @DomName('SVGLengthList.clear')
  void clear() native "SVGLengthList_clear_Callback";

  @DocsEditable
  @DomName('SVGLengthList.getItem')
  Length getItem(int index) native "SVGLengthList_getItem_Callback";

  @DocsEditable
  @DomName('SVGLengthList.initialize')
  Length initialize(Length item) native "SVGLengthList_initialize_Callback";

  @DocsEditable
  @DomName('SVGLengthList.insertItemBefore')
  Length insertItemBefore(Length item, int index) native "SVGLengthList_insertItemBefore_Callback";

  @DocsEditable
  @DomName('SVGLengthList.removeItem')
  Length removeItem(int index) native "SVGLengthList_removeItem_Callback";

  @DocsEditable
  @DomName('SVGLengthList.replaceItem')
  Length replaceItem(Length item, int index) native "SVGLengthList_replaceItem_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGLineElement')
class LineElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace {
  LineElement.internal() : super.internal();

  @DocsEditable
  factory LineElement() => _SvgElementFactoryProvider.createSvgElement_tag("line");

  @DocsEditable
  @DomName('SVGLineElement.x1')
  AnimatedLength get x1 native "SVGLineElement_x1_Getter";

  @DocsEditable
  @DomName('SVGLineElement.x2')
  AnimatedLength get x2 native "SVGLineElement_x2_Getter";

  @DocsEditable
  @DomName('SVGLineElement.y1')
  AnimatedLength get y1 native "SVGLineElement_y1_Getter";

  @DocsEditable
  @DomName('SVGLineElement.y2')
  AnimatedLength get y2 native "SVGLineElement_y2_Getter";

  @DocsEditable
  @DomName('SVGLineElement.externalResourcesRequired')
  AnimatedBoolean get externalResourcesRequired native "SVGLineElement_externalResourcesRequired_Getter";

  @DocsEditable
  @DomName('SVGLineElement.xmllang')
  String get xmllang native "SVGLineElement_xmllang_Getter";

  @DocsEditable
  @DomName('SVGLineElement.xmllang')
  void set xmllang(String value) native "SVGLineElement_xmllang_Setter";

  @DocsEditable
  @DomName('SVGLineElement.xmlspace')
  String get xmlspace native "SVGLineElement_xmlspace_Getter";

  @DocsEditable
  @DomName('SVGLineElement.xmlspace')
  void set xmlspace(String value) native "SVGLineElement_xmlspace_Setter";

  @DocsEditable
  @DomName('SVGLineElement.farthestViewportElement')
  SvgElement get farthestViewportElement native "SVGLineElement_farthestViewportElement_Getter";

  @DocsEditable
  @DomName('SVGLineElement.nearestViewportElement')
  SvgElement get nearestViewportElement native "SVGLineElement_nearestViewportElement_Getter";

  @DocsEditable
  @DomName('SVGLineElement.getBBox')
  Rect getBBox() native "SVGLineElement_getBBox_Callback";

  @DocsEditable
  @DomName('SVGLineElement.getCTM')
  Matrix getCtm() native "SVGLineElement_getCTM_Callback";

  @DocsEditable
  @DomName('SVGLineElement.getScreenCTM')
  Matrix getScreenCtm() native "SVGLineElement_getScreenCTM_Callback";

  @DocsEditable
  @DomName('SVGLineElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native "SVGLineElement_getTransformToElement_Callback";

  @DocsEditable
  @DomName('SVGLineElement.className')
  AnimatedString get $dom_svgClassName native "SVGLineElement_className_Getter";

  @DocsEditable
  @DomName('SVGLineElement.style')
  CssStyleDeclaration get style native "SVGLineElement_style_Getter";

  @DocsEditable
  @DomName('SVGLineElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native "SVGLineElement_getPresentationAttribute_Callback";

  @DocsEditable
  @DomName('SVGLineElement.requiredExtensions')
  StringList get requiredExtensions native "SVGLineElement_requiredExtensions_Getter";

  @DocsEditable
  @DomName('SVGLineElement.requiredFeatures')
  StringList get requiredFeatures native "SVGLineElement_requiredFeatures_Getter";

  @DocsEditable
  @DomName('SVGLineElement.systemLanguage')
  StringList get systemLanguage native "SVGLineElement_systemLanguage_Getter";

  @DocsEditable
  @DomName('SVGLineElement.hasExtension')
  bool hasExtension(String extension) native "SVGLineElement_hasExtension_Callback";

  @DocsEditable
  @DomName('SVGLineElement.transform')
  AnimatedTransformList get transform native "SVGLineElement_transform_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGLinearGradientElement')
class LinearGradientElement extends GradientElement {
  LinearGradientElement.internal() : super.internal();

  @DocsEditable
  factory LinearGradientElement() => _SvgElementFactoryProvider.createSvgElement_tag("linearGradient");

  @DocsEditable
  @DomName('SVGLinearGradientElement.x1')
  AnimatedLength get x1 native "SVGLinearGradientElement_x1_Getter";

  @DocsEditable
  @DomName('SVGLinearGradientElement.x2')
  AnimatedLength get x2 native "SVGLinearGradientElement_x2_Getter";

  @DocsEditable
  @DomName('SVGLinearGradientElement.y1')
  AnimatedLength get y1 native "SVGLinearGradientElement_y1_Getter";

  @DocsEditable
  @DomName('SVGLinearGradientElement.y2')
  AnimatedLength get y2 native "SVGLinearGradientElement_y2_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGLocatable')
class Locatable extends NativeFieldWrapperClass1 {
  Locatable.internal();

  @DocsEditable
  @DomName('SVGLocatable.farthestViewportElement')
  SvgElement get farthestViewportElement native "SVGLocatable_farthestViewportElement_Getter";

  @DocsEditable
  @DomName('SVGLocatable.nearestViewportElement')
  SvgElement get nearestViewportElement native "SVGLocatable_nearestViewportElement_Getter";

  @DocsEditable
  @DomName('SVGLocatable.getBBox')
  Rect getBBox() native "SVGLocatable_getBBox_Callback";

  @DocsEditable
  @DomName('SVGLocatable.getCTM')
  Matrix getCtm() native "SVGLocatable_getCTM_Callback";

  @DocsEditable
  @DomName('SVGLocatable.getScreenCTM')
  Matrix getScreenCtm() native "SVGLocatable_getScreenCTM_Callback";

  @DocsEditable
  @DomName('SVGLocatable.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native "SVGLocatable_getTransformToElement_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGMPathElement')
class MPathElement extends SvgElement implements UriReference, ExternalResourcesRequired {
  MPathElement.internal() : super.internal();

  @DocsEditable
  factory MPathElement() => _SvgElementFactoryProvider.createSvgElement_tag("mpath");

  @DocsEditable
  @DomName('SVGMPathElement.externalResourcesRequired')
  AnimatedBoolean get externalResourcesRequired native "SVGMPathElement_externalResourcesRequired_Getter";

  @DocsEditable
  @DomName('SVGMPathElement.href')
  AnimatedString get href native "SVGMPathElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGMarkerElement')
class MarkerElement extends SvgElement implements FitToViewBox, ExternalResourcesRequired, Stylable, LangSpace {
  MarkerElement.internal() : super.internal();

  @DocsEditable
  factory MarkerElement() => _SvgElementFactoryProvider.createSvgElement_tag("marker");

  static const int SVG_MARKERUNITS_STROKEWIDTH = 2;

  static const int SVG_MARKERUNITS_UNKNOWN = 0;

  static const int SVG_MARKERUNITS_USERSPACEONUSE = 1;

  static const int SVG_MARKER_ORIENT_ANGLE = 2;

  static const int SVG_MARKER_ORIENT_AUTO = 1;

  static const int SVG_MARKER_ORIENT_UNKNOWN = 0;

  @DocsEditable
  @DomName('SVGMarkerElement.markerHeight')
  AnimatedLength get markerHeight native "SVGMarkerElement_markerHeight_Getter";

  @DocsEditable
  @DomName('SVGMarkerElement.markerUnits')
  AnimatedEnumeration get markerUnits native "SVGMarkerElement_markerUnits_Getter";

  @DocsEditable
  @DomName('SVGMarkerElement.markerWidth')
  AnimatedLength get markerWidth native "SVGMarkerElement_markerWidth_Getter";

  @DocsEditable
  @DomName('SVGMarkerElement.orientAngle')
  AnimatedAngle get orientAngle native "SVGMarkerElement_orientAngle_Getter";

  @DocsEditable
  @DomName('SVGMarkerElement.orientType')
  AnimatedEnumeration get orientType native "SVGMarkerElement_orientType_Getter";

  @DocsEditable
  @DomName('SVGMarkerElement.refX')
  AnimatedLength get refX native "SVGMarkerElement_refX_Getter";

  @DocsEditable
  @DomName('SVGMarkerElement.refY')
  AnimatedLength get refY native "SVGMarkerElement_refY_Getter";

  @DocsEditable
  @DomName('SVGMarkerElement.setOrientToAngle')
  void setOrientToAngle(Angle angle) native "SVGMarkerElement_setOrientToAngle_Callback";

  @DocsEditable
  @DomName('SVGMarkerElement.setOrientToAuto')
  void setOrientToAuto() native "SVGMarkerElement_setOrientToAuto_Callback";

  @DocsEditable
  @DomName('SVGMarkerElement.externalResourcesRequired')
  AnimatedBoolean get externalResourcesRequired native "SVGMarkerElement_externalResourcesRequired_Getter";

  @DocsEditable
  @DomName('SVGMarkerElement.preserveAspectRatio')
  AnimatedPreserveAspectRatio get preserveAspectRatio native "SVGMarkerElement_preserveAspectRatio_Getter";

  @DocsEditable
  @DomName('SVGMarkerElement.viewBox')
  AnimatedRect get viewBox native "SVGMarkerElement_viewBox_Getter";

  @DocsEditable
  @DomName('SVGMarkerElement.xmllang')
  String get xmllang native "SVGMarkerElement_xmllang_Getter";

  @DocsEditable
  @DomName('SVGMarkerElement.xmllang')
  void set xmllang(String value) native "SVGMarkerElement_xmllang_Setter";

  @DocsEditable
  @DomName('SVGMarkerElement.xmlspace')
  String get xmlspace native "SVGMarkerElement_xmlspace_Getter";

  @DocsEditable
  @DomName('SVGMarkerElement.xmlspace')
  void set xmlspace(String value) native "SVGMarkerElement_xmlspace_Setter";

  @DocsEditable
  @DomName('SVGMarkerElement.className')
  AnimatedString get $dom_svgClassName native "SVGMarkerElement_className_Getter";

  @DocsEditable
  @DomName('SVGMarkerElement.style')
  CssStyleDeclaration get style native "SVGMarkerElement_style_Getter";

  @DocsEditable
  @DomName('SVGMarkerElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native "SVGMarkerElement_getPresentationAttribute_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGMaskElement')
class MaskElement extends SvgElement implements Tests, Stylable, ExternalResourcesRequired, LangSpace {
  MaskElement.internal() : super.internal();

  @DocsEditable
  factory MaskElement() => _SvgElementFactoryProvider.createSvgElement_tag("mask");

  @DocsEditable
  @DomName('SVGMaskElement.height')
  AnimatedLength get height native "SVGMaskElement_height_Getter";

  @DocsEditable
  @DomName('SVGMaskElement.maskContentUnits')
  AnimatedEnumeration get maskContentUnits native "SVGMaskElement_maskContentUnits_Getter";

  @DocsEditable
  @DomName('SVGMaskElement.maskUnits')
  AnimatedEnumeration get maskUnits native "SVGMaskElement_maskUnits_Getter";

  @DocsEditable
  @DomName('SVGMaskElement.width')
  AnimatedLength get width native "SVGMaskElement_width_Getter";

  @DocsEditable
  @DomName('SVGMaskElement.x')
  AnimatedLength get x native "SVGMaskElement_x_Getter";

  @DocsEditable
  @DomName('SVGMaskElement.y')
  AnimatedLength get y native "SVGMaskElement_y_Getter";

  @DocsEditable
  @DomName('SVGMaskElement.externalResourcesRequired')
  AnimatedBoolean get externalResourcesRequired native "SVGMaskElement_externalResourcesRequired_Getter";

  @DocsEditable
  @DomName('SVGMaskElement.xmllang')
  String get xmllang native "SVGMaskElement_xmllang_Getter";

  @DocsEditable
  @DomName('SVGMaskElement.xmllang')
  void set xmllang(String value) native "SVGMaskElement_xmllang_Setter";

  @DocsEditable
  @DomName('SVGMaskElement.xmlspace')
  String get xmlspace native "SVGMaskElement_xmlspace_Getter";

  @DocsEditable
  @DomName('SVGMaskElement.xmlspace')
  void set xmlspace(String value) native "SVGMaskElement_xmlspace_Setter";

  @DocsEditable
  @DomName('SVGMaskElement.className')
  AnimatedString get $dom_svgClassName native "SVGMaskElement_className_Getter";

  @DocsEditable
  @DomName('SVGMaskElement.style')
  CssStyleDeclaration get style native "SVGMaskElement_style_Getter";

  @DocsEditable
  @DomName('SVGMaskElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native "SVGMaskElement_getPresentationAttribute_Callback";

  @DocsEditable
  @DomName('SVGMaskElement.requiredExtensions')
  StringList get requiredExtensions native "SVGMaskElement_requiredExtensions_Getter";

  @DocsEditable
  @DomName('SVGMaskElement.requiredFeatures')
  StringList get requiredFeatures native "SVGMaskElement_requiredFeatures_Getter";

  @DocsEditable
  @DomName('SVGMaskElement.systemLanguage')
  StringList get systemLanguage native "SVGMaskElement_systemLanguage_Getter";

  @DocsEditable
  @DomName('SVGMaskElement.hasExtension')
  bool hasExtension(String extension) native "SVGMaskElement_hasExtension_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGMatrix')
class Matrix extends NativeFieldWrapperClass1 {
  Matrix.internal();

  @DocsEditable
  @DomName('SVGMatrix.a')
  num get a native "SVGMatrix_a_Getter";

  @DocsEditable
  @DomName('SVGMatrix.a')
  void set a(num value) native "SVGMatrix_a_Setter";

  @DocsEditable
  @DomName('SVGMatrix.b')
  num get b native "SVGMatrix_b_Getter";

  @DocsEditable
  @DomName('SVGMatrix.b')
  void set b(num value) native "SVGMatrix_b_Setter";

  @DocsEditable
  @DomName('SVGMatrix.c')
  num get c native "SVGMatrix_c_Getter";

  @DocsEditable
  @DomName('SVGMatrix.c')
  void set c(num value) native "SVGMatrix_c_Setter";

  @DocsEditable
  @DomName('SVGMatrix.d')
  num get d native "SVGMatrix_d_Getter";

  @DocsEditable
  @DomName('SVGMatrix.d')
  void set d(num value) native "SVGMatrix_d_Setter";

  @DocsEditable
  @DomName('SVGMatrix.e')
  num get e native "SVGMatrix_e_Getter";

  @DocsEditable
  @DomName('SVGMatrix.e')
  void set e(num value) native "SVGMatrix_e_Setter";

  @DocsEditable
  @DomName('SVGMatrix.f')
  num get f native "SVGMatrix_f_Getter";

  @DocsEditable
  @DomName('SVGMatrix.f')
  void set f(num value) native "SVGMatrix_f_Setter";

  @DocsEditable
  @DomName('SVGMatrix.flipX')
  Matrix flipX() native "SVGMatrix_flipX_Callback";

  @DocsEditable
  @DomName('SVGMatrix.flipY')
  Matrix flipY() native "SVGMatrix_flipY_Callback";

  @DocsEditable
  @DomName('SVGMatrix.inverse')
  Matrix inverse() native "SVGMatrix_inverse_Callback";

  @DocsEditable
  @DomName('SVGMatrix.multiply')
  Matrix multiply(Matrix secondMatrix) native "SVGMatrix_multiply_Callback";

  @DocsEditable
  @DomName('SVGMatrix.rotate')
  Matrix rotate(num angle) native "SVGMatrix_rotate_Callback";

  @DocsEditable
  @DomName('SVGMatrix.rotateFromVector')
  Matrix rotateFromVector(num x, num y) native "SVGMatrix_rotateFromVector_Callback";

  @DocsEditable
  @DomName('SVGMatrix.scale')
  Matrix scale(num scaleFactor) native "SVGMatrix_scale_Callback";

  @DocsEditable
  @DomName('SVGMatrix.scaleNonUniform')
  Matrix scaleNonUniform(num scaleFactorX, num scaleFactorY) native "SVGMatrix_scaleNonUniform_Callback";

  @DocsEditable
  @DomName('SVGMatrix.skewX')
  Matrix skewX(num angle) native "SVGMatrix_skewX_Callback";

  @DocsEditable
  @DomName('SVGMatrix.skewY')
  Matrix skewY(num angle) native "SVGMatrix_skewY_Callback";

  @DocsEditable
  @DomName('SVGMatrix.translate')
  Matrix translate(num x, num y) native "SVGMatrix_translate_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGMetadataElement')
class MetadataElement extends SvgElement {
  MetadataElement.internal() : super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGMissingGlyphElement')
class MissingGlyphElement extends SvgElement {
  MissingGlyphElement.internal() : super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGNumber')
class Number extends NativeFieldWrapperClass1 {
  Number.internal();

  @DocsEditable
  @DomName('SVGNumber.value')
  num get value native "SVGNumber_value_Getter";

  @DocsEditable
  @DomName('SVGNumber.value')
  void set value(num value) native "SVGNumber_value_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGNumberList')
class NumberList extends NativeFieldWrapperClass1 implements List<Number> {
  NumberList.internal();

  @DocsEditable
  @DomName('SVGNumberList.numberOfItems')
  int get numberOfItems native "SVGNumberList_numberOfItems_Getter";

  Number operator[](int index) native "SVGNumberList_item_Callback";

  void operator[]=(int index, Number value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Number> mixins.
  // Number is the element type.

  // From Iterable<Number>:

  Iterator<Number> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<Number>(this);
  }

  // SVG Collections expose numberOfItems rather than length.
  int get length => numberOfItems;
  dynamic reduce(dynamic initialValue, dynamic combine(dynamic, Number)) {
    return Collections.reduce(this, initialValue, combine);
  }

  bool contains(Number element) => Collections.contains(this, element);

  void forEach(void f(Number element)) => Collections.forEach(this, f);

  String join([String separator]) => Collections.joinList(this, separator);

  List mappedBy(f(Number element)) => new MappedList<Number, dynamic>(this, f);

  Iterable<Number> where(bool f(Number element)) => new WhereIterable<Number>(this, f);

  bool every(bool f(Number element)) => Collections.every(this, f);

  bool any(bool f(Number element)) => Collections.any(this, f);

  List<Number> toList() => new List<Number>.from(this);
  Set<Number> toSet() => new Set<Number>.from(this);

  bool get isEmpty => this.length == 0;

  List<Number> take(int n) => new ListView<Number>(this, 0, n);

  Iterable<Number> takeWhile(bool test(Number value)) {
    return new TakeWhileIterable<Number>(this, test);
  }

  List<Number> skip(int n) => new ListView<Number>(this, n, null);

  Iterable<Number> skipWhile(bool test(Number value)) {
    return new SkipWhileIterable<Number>(this, test);
  }

  Number firstMatching(bool test(Number value), { Number orElse() }) {
    return Collections.firstMatching(this, test, orElse);
  }

  Number lastMatching(bool test(Number value), {Number orElse()}) {
    return Collections.lastMatchingInList(this, test, orElse);
  }

  Number singleMatching(bool test(Number value)) {
    return Collections.singleMatching(this, test);
  }

  Number elementAt(int index) {
    return this[index];
  }

  // From Collection<Number>:

  void add(Number value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(Number value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<Number> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<Number>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  // contains() defined by IDL.

  void sort([int compare(Number a, Number b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(Number element, [int start = 0]) =>
      Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(Number element, [int start]) {
    if (start == null) start = length - 1;
    return Lists.lastIndexOf(this, element, start);
  }

  Number get first {
    if (this.length > 0) return this[0];
    throw new StateError("No elements");
  }

  Number get last {
    if (this.length > 0) return this[this.length - 1];
    throw new StateError("No elements");
  }

  Number get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  Number min([int compare(Number a, Number b)]) => Collections.min(this, compare);

  Number max([int compare(Number a, Number b)]) => Collections.max(this, compare);

  Number removeAt(int pos) {
    throw new UnsupportedError("Cannot removeAt on immutable List.");
  }

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
      Lists.getRange(this, start, rangeLength, <Number>[]);

  // -- end List<Number> mixins.

  @DocsEditable
  @DomName('SVGNumberList.appendItem')
  Number appendItem(Number item) native "SVGNumberList_appendItem_Callback";

  @DocsEditable
  @DomName('SVGNumberList.clear')
  void clear() native "SVGNumberList_clear_Callback";

  @DocsEditable
  @DomName('SVGNumberList.getItem')
  Number getItem(int index) native "SVGNumberList_getItem_Callback";

  @DocsEditable
  @DomName('SVGNumberList.initialize')
  Number initialize(Number item) native "SVGNumberList_initialize_Callback";

  @DocsEditable
  @DomName('SVGNumberList.insertItemBefore')
  Number insertItemBefore(Number item, int index) native "SVGNumberList_insertItemBefore_Callback";

  @DocsEditable
  @DomName('SVGNumberList.removeItem')
  Number removeItem(int index) native "SVGNumberList_removeItem_Callback";

  @DocsEditable
  @DomName('SVGNumberList.replaceItem')
  Number replaceItem(Number item, int index) native "SVGNumberList_replaceItem_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGPaint')
class Paint extends Color {
  Paint.internal() : super.internal();

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

  @DocsEditable
  @DomName('SVGPaint.paintType')
  int get paintType native "SVGPaint_paintType_Getter";

  @DocsEditable
  @DomName('SVGPaint.uri')
  String get uri native "SVGPaint_uri_Getter";

  @DocsEditable
  @DomName('SVGPaint.setPaint')
  void setPaint(int paintType, String uri, String rgbColor, String iccColor) native "SVGPaint_setPaint_Callback";

  @DocsEditable
  @DomName('SVGPaint.setUri')
  void setUri(String uri) native "SVGPaint_setUri_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGPathElement')
class PathElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace {
  PathElement.internal() : super.internal();

  @DocsEditable
  factory PathElement() => _SvgElementFactoryProvider.createSvgElement_tag("path");

  @DocsEditable
  @DomName('SVGPathElement.animatedNormalizedPathSegList')
  PathSegList get animatedNormalizedPathSegList native "SVGPathElement_animatedNormalizedPathSegList_Getter";

  @DocsEditable
  @DomName('SVGPathElement.animatedPathSegList')
  PathSegList get animatedPathSegList native "SVGPathElement_animatedPathSegList_Getter";

  @DocsEditable
  @DomName('SVGPathElement.normalizedPathSegList')
  PathSegList get normalizedPathSegList native "SVGPathElement_normalizedPathSegList_Getter";

  @DocsEditable
  @DomName('SVGPathElement.pathLength')
  AnimatedNumber get pathLength native "SVGPathElement_pathLength_Getter";

  @DocsEditable
  @DomName('SVGPathElement.pathSegList')
  PathSegList get pathSegList native "SVGPathElement_pathSegList_Getter";

  @DocsEditable
  @DomName('SVGPathElement.createSVGPathSegArcAbs')
  PathSegArcAbs createSvgPathSegArcAbs(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) native "SVGPathElement_createSVGPathSegArcAbs_Callback";

  @DocsEditable
  @DomName('SVGPathElement.createSVGPathSegArcRel')
  PathSegArcRel createSvgPathSegArcRel(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) native "SVGPathElement_createSVGPathSegArcRel_Callback";

  @DocsEditable
  @DomName('SVGPathElement.createSVGPathSegClosePath')
  PathSegClosePath createSvgPathSegClosePath() native "SVGPathElement_createSVGPathSegClosePath_Callback";

  @DocsEditable
  @DomName('SVGPathElement.createSVGPathSegCurvetoCubicAbs')
  PathSegCurvetoCubicAbs createSvgPathSegCurvetoCubicAbs(num x, num y, num x1, num y1, num x2, num y2) native "SVGPathElement_createSVGPathSegCurvetoCubicAbs_Callback";

  @DocsEditable
  @DomName('SVGPathElement.createSVGPathSegCurvetoCubicRel')
  PathSegCurvetoCubicRel createSvgPathSegCurvetoCubicRel(num x, num y, num x1, num y1, num x2, num y2) native "SVGPathElement_createSVGPathSegCurvetoCubicRel_Callback";

  @DocsEditable
  @DomName('SVGPathElement.createSVGPathSegCurvetoCubicSmoothAbs')
  PathSegCurvetoCubicSmoothAbs createSvgPathSegCurvetoCubicSmoothAbs(num x, num y, num x2, num y2) native "SVGPathElement_createSVGPathSegCurvetoCubicSmoothAbs_Callback";

  @DocsEditable
  @DomName('SVGPathElement.createSVGPathSegCurvetoCubicSmoothRel')
  PathSegCurvetoCubicSmoothRel createSvgPathSegCurvetoCubicSmoothRel(num x, num y, num x2, num y2) native "SVGPathElement_createSVGPathSegCurvetoCubicSmoothRel_Callback";

  @DocsEditable
  @DomName('SVGPathElement.createSVGPathSegCurvetoQuadraticAbs')
  PathSegCurvetoQuadraticAbs createSvgPathSegCurvetoQuadraticAbs(num x, num y, num x1, num y1) native "SVGPathElement_createSVGPathSegCurvetoQuadraticAbs_Callback";

  @DocsEditable
  @DomName('SVGPathElement.createSVGPathSegCurvetoQuadraticRel')
  PathSegCurvetoQuadraticRel createSvgPathSegCurvetoQuadraticRel(num x, num y, num x1, num y1) native "SVGPathElement_createSVGPathSegCurvetoQuadraticRel_Callback";

  @DocsEditable
  @DomName('SVGPathElement.createSVGPathSegCurvetoQuadraticSmoothAbs')
  PathSegCurvetoQuadraticSmoothAbs createSvgPathSegCurvetoQuadraticSmoothAbs(num x, num y) native "SVGPathElement_createSVGPathSegCurvetoQuadraticSmoothAbs_Callback";

  @DocsEditable
  @DomName('SVGPathElement.createSVGPathSegCurvetoQuadraticSmoothRel')
  PathSegCurvetoQuadraticSmoothRel createSvgPathSegCurvetoQuadraticSmoothRel(num x, num y) native "SVGPathElement_createSVGPathSegCurvetoQuadraticSmoothRel_Callback";

  @DocsEditable
  @DomName('SVGPathElement.createSVGPathSegLinetoAbs')
  PathSegLinetoAbs createSvgPathSegLinetoAbs(num x, num y) native "SVGPathElement_createSVGPathSegLinetoAbs_Callback";

  @DocsEditable
  @DomName('SVGPathElement.createSVGPathSegLinetoHorizontalAbs')
  PathSegLinetoHorizontalAbs createSvgPathSegLinetoHorizontalAbs(num x) native "SVGPathElement_createSVGPathSegLinetoHorizontalAbs_Callback";

  @DocsEditable
  @DomName('SVGPathElement.createSVGPathSegLinetoHorizontalRel')
  PathSegLinetoHorizontalRel createSvgPathSegLinetoHorizontalRel(num x) native "SVGPathElement_createSVGPathSegLinetoHorizontalRel_Callback";

  @DocsEditable
  @DomName('SVGPathElement.createSVGPathSegLinetoRel')
  PathSegLinetoRel createSvgPathSegLinetoRel(num x, num y) native "SVGPathElement_createSVGPathSegLinetoRel_Callback";

  @DocsEditable
  @DomName('SVGPathElement.createSVGPathSegLinetoVerticalAbs')
  PathSegLinetoVerticalAbs createSvgPathSegLinetoVerticalAbs(num y) native "SVGPathElement_createSVGPathSegLinetoVerticalAbs_Callback";

  @DocsEditable
  @DomName('SVGPathElement.createSVGPathSegLinetoVerticalRel')
  PathSegLinetoVerticalRel createSvgPathSegLinetoVerticalRel(num y) native "SVGPathElement_createSVGPathSegLinetoVerticalRel_Callback";

  @DocsEditable
  @DomName('SVGPathElement.createSVGPathSegMovetoAbs')
  PathSegMovetoAbs createSvgPathSegMovetoAbs(num x, num y) native "SVGPathElement_createSVGPathSegMovetoAbs_Callback";

  @DocsEditable
  @DomName('SVGPathElement.createSVGPathSegMovetoRel')
  PathSegMovetoRel createSvgPathSegMovetoRel(num x, num y) native "SVGPathElement_createSVGPathSegMovetoRel_Callback";

  @DocsEditable
  @DomName('SVGPathElement.getPathSegAtLength')
  int getPathSegAtLength(num distance) native "SVGPathElement_getPathSegAtLength_Callback";

  @DocsEditable
  @DomName('SVGPathElement.getPointAtLength')
  Point getPointAtLength(num distance) native "SVGPathElement_getPointAtLength_Callback";

  @DocsEditable
  @DomName('SVGPathElement.getTotalLength')
  num getTotalLength() native "SVGPathElement_getTotalLength_Callback";

  @DocsEditable
  @DomName('SVGPathElement.externalResourcesRequired')
  AnimatedBoolean get externalResourcesRequired native "SVGPathElement_externalResourcesRequired_Getter";

  @DocsEditable
  @DomName('SVGPathElement.xmllang')
  String get xmllang native "SVGPathElement_xmllang_Getter";

  @DocsEditable
  @DomName('SVGPathElement.xmllang')
  void set xmllang(String value) native "SVGPathElement_xmllang_Setter";

  @DocsEditable
  @DomName('SVGPathElement.xmlspace')
  String get xmlspace native "SVGPathElement_xmlspace_Getter";

  @DocsEditable
  @DomName('SVGPathElement.xmlspace')
  void set xmlspace(String value) native "SVGPathElement_xmlspace_Setter";

  @DocsEditable
  @DomName('SVGPathElement.farthestViewportElement')
  SvgElement get farthestViewportElement native "SVGPathElement_farthestViewportElement_Getter";

  @DocsEditable
  @DomName('SVGPathElement.nearestViewportElement')
  SvgElement get nearestViewportElement native "SVGPathElement_nearestViewportElement_Getter";

  @DocsEditable
  @DomName('SVGPathElement.getBBox')
  Rect getBBox() native "SVGPathElement_getBBox_Callback";

  @DocsEditable
  @DomName('SVGPathElement.getCTM')
  Matrix getCtm() native "SVGPathElement_getCTM_Callback";

  @DocsEditable
  @DomName('SVGPathElement.getScreenCTM')
  Matrix getScreenCtm() native "SVGPathElement_getScreenCTM_Callback";

  @DocsEditable
  @DomName('SVGPathElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native "SVGPathElement_getTransformToElement_Callback";

  @DocsEditable
  @DomName('SVGPathElement.className')
  AnimatedString get $dom_svgClassName native "SVGPathElement_className_Getter";

  @DocsEditable
  @DomName('SVGPathElement.style')
  CssStyleDeclaration get style native "SVGPathElement_style_Getter";

  @DocsEditable
  @DomName('SVGPathElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native "SVGPathElement_getPresentationAttribute_Callback";

  @DocsEditable
  @DomName('SVGPathElement.requiredExtensions')
  StringList get requiredExtensions native "SVGPathElement_requiredExtensions_Getter";

  @DocsEditable
  @DomName('SVGPathElement.requiredFeatures')
  StringList get requiredFeatures native "SVGPathElement_requiredFeatures_Getter";

  @DocsEditable
  @DomName('SVGPathElement.systemLanguage')
  StringList get systemLanguage native "SVGPathElement_systemLanguage_Getter";

  @DocsEditable
  @DomName('SVGPathElement.hasExtension')
  bool hasExtension(String extension) native "SVGPathElement_hasExtension_Callback";

  @DocsEditable
  @DomName('SVGPathElement.transform')
  AnimatedTransformList get transform native "SVGPathElement_transform_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGPathSeg')
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

  @DocsEditable
  @DomName('SVGPathSeg.pathSegType')
  int get pathSegType native "SVGPathSeg_pathSegType_Getter";

  @DocsEditable
  @DomName('SVGPathSeg.pathSegTypeAsLetter')
  String get pathSegTypeAsLetter native "SVGPathSeg_pathSegTypeAsLetter_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGPathSegArcAbs')
class PathSegArcAbs extends PathSeg {
  PathSegArcAbs.internal() : super.internal();

  @DocsEditable
  @DomName('SVGPathSegArcAbs.angle')
  num get angle native "SVGPathSegArcAbs_angle_Getter";

  @DocsEditable
  @DomName('SVGPathSegArcAbs.angle')
  void set angle(num value) native "SVGPathSegArcAbs_angle_Setter";

  @DocsEditable
  @DomName('SVGPathSegArcAbs.largeArcFlag')
  bool get largeArcFlag native "SVGPathSegArcAbs_largeArcFlag_Getter";

  @DocsEditable
  @DomName('SVGPathSegArcAbs.largeArcFlag')
  void set largeArcFlag(bool value) native "SVGPathSegArcAbs_largeArcFlag_Setter";

  @DocsEditable
  @DomName('SVGPathSegArcAbs.r1')
  num get r1 native "SVGPathSegArcAbs_r1_Getter";

  @DocsEditable
  @DomName('SVGPathSegArcAbs.r1')
  void set r1(num value) native "SVGPathSegArcAbs_r1_Setter";

  @DocsEditable
  @DomName('SVGPathSegArcAbs.r2')
  num get r2 native "SVGPathSegArcAbs_r2_Getter";

  @DocsEditable
  @DomName('SVGPathSegArcAbs.r2')
  void set r2(num value) native "SVGPathSegArcAbs_r2_Setter";

  @DocsEditable
  @DomName('SVGPathSegArcAbs.sweepFlag')
  bool get sweepFlag native "SVGPathSegArcAbs_sweepFlag_Getter";

  @DocsEditable
  @DomName('SVGPathSegArcAbs.sweepFlag')
  void set sweepFlag(bool value) native "SVGPathSegArcAbs_sweepFlag_Setter";

  @DocsEditable
  @DomName('SVGPathSegArcAbs.x')
  num get x native "SVGPathSegArcAbs_x_Getter";

  @DocsEditable
  @DomName('SVGPathSegArcAbs.x')
  void set x(num value) native "SVGPathSegArcAbs_x_Setter";

  @DocsEditable
  @DomName('SVGPathSegArcAbs.y')
  num get y native "SVGPathSegArcAbs_y_Getter";

  @DocsEditable
  @DomName('SVGPathSegArcAbs.y')
  void set y(num value) native "SVGPathSegArcAbs_y_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGPathSegArcRel')
class PathSegArcRel extends PathSeg {
  PathSegArcRel.internal() : super.internal();

  @DocsEditable
  @DomName('SVGPathSegArcRel.angle')
  num get angle native "SVGPathSegArcRel_angle_Getter";

  @DocsEditable
  @DomName('SVGPathSegArcRel.angle')
  void set angle(num value) native "SVGPathSegArcRel_angle_Setter";

  @DocsEditable
  @DomName('SVGPathSegArcRel.largeArcFlag')
  bool get largeArcFlag native "SVGPathSegArcRel_largeArcFlag_Getter";

  @DocsEditable
  @DomName('SVGPathSegArcRel.largeArcFlag')
  void set largeArcFlag(bool value) native "SVGPathSegArcRel_largeArcFlag_Setter";

  @DocsEditable
  @DomName('SVGPathSegArcRel.r1')
  num get r1 native "SVGPathSegArcRel_r1_Getter";

  @DocsEditable
  @DomName('SVGPathSegArcRel.r1')
  void set r1(num value) native "SVGPathSegArcRel_r1_Setter";

  @DocsEditable
  @DomName('SVGPathSegArcRel.r2')
  num get r2 native "SVGPathSegArcRel_r2_Getter";

  @DocsEditable
  @DomName('SVGPathSegArcRel.r2')
  void set r2(num value) native "SVGPathSegArcRel_r2_Setter";

  @DocsEditable
  @DomName('SVGPathSegArcRel.sweepFlag')
  bool get sweepFlag native "SVGPathSegArcRel_sweepFlag_Getter";

  @DocsEditable
  @DomName('SVGPathSegArcRel.sweepFlag')
  void set sweepFlag(bool value) native "SVGPathSegArcRel_sweepFlag_Setter";

  @DocsEditable
  @DomName('SVGPathSegArcRel.x')
  num get x native "SVGPathSegArcRel_x_Getter";

  @DocsEditable
  @DomName('SVGPathSegArcRel.x')
  void set x(num value) native "SVGPathSegArcRel_x_Setter";

  @DocsEditable
  @DomName('SVGPathSegArcRel.y')
  num get y native "SVGPathSegArcRel_y_Getter";

  @DocsEditable
  @DomName('SVGPathSegArcRel.y')
  void set y(num value) native "SVGPathSegArcRel_y_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGPathSegClosePath')
class PathSegClosePath extends PathSeg {
  PathSegClosePath.internal() : super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGPathSegCurvetoCubicAbs')
class PathSegCurvetoCubicAbs extends PathSeg {
  PathSegCurvetoCubicAbs.internal() : super.internal();

  @DocsEditable
  @DomName('SVGPathSegCurvetoCubicAbs.x')
  num get x native "SVGPathSegCurvetoCubicAbs_x_Getter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoCubicAbs.x')
  void set x(num value) native "SVGPathSegCurvetoCubicAbs_x_Setter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoCubicAbs.x1')
  num get x1 native "SVGPathSegCurvetoCubicAbs_x1_Getter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoCubicAbs.x1')
  void set x1(num value) native "SVGPathSegCurvetoCubicAbs_x1_Setter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoCubicAbs.x2')
  num get x2 native "SVGPathSegCurvetoCubicAbs_x2_Getter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoCubicAbs.x2')
  void set x2(num value) native "SVGPathSegCurvetoCubicAbs_x2_Setter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoCubicAbs.y')
  num get y native "SVGPathSegCurvetoCubicAbs_y_Getter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoCubicAbs.y')
  void set y(num value) native "SVGPathSegCurvetoCubicAbs_y_Setter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoCubicAbs.y1')
  num get y1 native "SVGPathSegCurvetoCubicAbs_y1_Getter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoCubicAbs.y1')
  void set y1(num value) native "SVGPathSegCurvetoCubicAbs_y1_Setter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoCubicAbs.y2')
  num get y2 native "SVGPathSegCurvetoCubicAbs_y2_Getter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoCubicAbs.y2')
  void set y2(num value) native "SVGPathSegCurvetoCubicAbs_y2_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGPathSegCurvetoCubicRel')
class PathSegCurvetoCubicRel extends PathSeg {
  PathSegCurvetoCubicRel.internal() : super.internal();

  @DocsEditable
  @DomName('SVGPathSegCurvetoCubicRel.x')
  num get x native "SVGPathSegCurvetoCubicRel_x_Getter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoCubicRel.x')
  void set x(num value) native "SVGPathSegCurvetoCubicRel_x_Setter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoCubicRel.x1')
  num get x1 native "SVGPathSegCurvetoCubicRel_x1_Getter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoCubicRel.x1')
  void set x1(num value) native "SVGPathSegCurvetoCubicRel_x1_Setter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoCubicRel.x2')
  num get x2 native "SVGPathSegCurvetoCubicRel_x2_Getter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoCubicRel.x2')
  void set x2(num value) native "SVGPathSegCurvetoCubicRel_x2_Setter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoCubicRel.y')
  num get y native "SVGPathSegCurvetoCubicRel_y_Getter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoCubicRel.y')
  void set y(num value) native "SVGPathSegCurvetoCubicRel_y_Setter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoCubicRel.y1')
  num get y1 native "SVGPathSegCurvetoCubicRel_y1_Getter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoCubicRel.y1')
  void set y1(num value) native "SVGPathSegCurvetoCubicRel_y1_Setter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoCubicRel.y2')
  num get y2 native "SVGPathSegCurvetoCubicRel_y2_Getter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoCubicRel.y2')
  void set y2(num value) native "SVGPathSegCurvetoCubicRel_y2_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGPathSegCurvetoCubicSmoothAbs')
class PathSegCurvetoCubicSmoothAbs extends PathSeg {
  PathSegCurvetoCubicSmoothAbs.internal() : super.internal();

  @DocsEditable
  @DomName('SVGPathSegCurvetoCubicSmoothAbs.x')
  num get x native "SVGPathSegCurvetoCubicSmoothAbs_x_Getter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoCubicSmoothAbs.x')
  void set x(num value) native "SVGPathSegCurvetoCubicSmoothAbs_x_Setter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoCubicSmoothAbs.x2')
  num get x2 native "SVGPathSegCurvetoCubicSmoothAbs_x2_Getter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoCubicSmoothAbs.x2')
  void set x2(num value) native "SVGPathSegCurvetoCubicSmoothAbs_x2_Setter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoCubicSmoothAbs.y')
  num get y native "SVGPathSegCurvetoCubicSmoothAbs_y_Getter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoCubicSmoothAbs.y')
  void set y(num value) native "SVGPathSegCurvetoCubicSmoothAbs_y_Setter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoCubicSmoothAbs.y2')
  num get y2 native "SVGPathSegCurvetoCubicSmoothAbs_y2_Getter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoCubicSmoothAbs.y2')
  void set y2(num value) native "SVGPathSegCurvetoCubicSmoothAbs_y2_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGPathSegCurvetoCubicSmoothRel')
class PathSegCurvetoCubicSmoothRel extends PathSeg {
  PathSegCurvetoCubicSmoothRel.internal() : super.internal();

  @DocsEditable
  @DomName('SVGPathSegCurvetoCubicSmoothRel.x')
  num get x native "SVGPathSegCurvetoCubicSmoothRel_x_Getter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoCubicSmoothRel.x')
  void set x(num value) native "SVGPathSegCurvetoCubicSmoothRel_x_Setter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoCubicSmoothRel.x2')
  num get x2 native "SVGPathSegCurvetoCubicSmoothRel_x2_Getter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoCubicSmoothRel.x2')
  void set x2(num value) native "SVGPathSegCurvetoCubicSmoothRel_x2_Setter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoCubicSmoothRel.y')
  num get y native "SVGPathSegCurvetoCubicSmoothRel_y_Getter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoCubicSmoothRel.y')
  void set y(num value) native "SVGPathSegCurvetoCubicSmoothRel_y_Setter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoCubicSmoothRel.y2')
  num get y2 native "SVGPathSegCurvetoCubicSmoothRel_y2_Getter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoCubicSmoothRel.y2')
  void set y2(num value) native "SVGPathSegCurvetoCubicSmoothRel_y2_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGPathSegCurvetoQuadraticAbs')
class PathSegCurvetoQuadraticAbs extends PathSeg {
  PathSegCurvetoQuadraticAbs.internal() : super.internal();

  @DocsEditable
  @DomName('SVGPathSegCurvetoQuadraticAbs.x')
  num get x native "SVGPathSegCurvetoQuadraticAbs_x_Getter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoQuadraticAbs.x')
  void set x(num value) native "SVGPathSegCurvetoQuadraticAbs_x_Setter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoQuadraticAbs.x1')
  num get x1 native "SVGPathSegCurvetoQuadraticAbs_x1_Getter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoQuadraticAbs.x1')
  void set x1(num value) native "SVGPathSegCurvetoQuadraticAbs_x1_Setter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoQuadraticAbs.y')
  num get y native "SVGPathSegCurvetoQuadraticAbs_y_Getter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoQuadraticAbs.y')
  void set y(num value) native "SVGPathSegCurvetoQuadraticAbs_y_Setter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoQuadraticAbs.y1')
  num get y1 native "SVGPathSegCurvetoQuadraticAbs_y1_Getter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoQuadraticAbs.y1')
  void set y1(num value) native "SVGPathSegCurvetoQuadraticAbs_y1_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGPathSegCurvetoQuadraticRel')
class PathSegCurvetoQuadraticRel extends PathSeg {
  PathSegCurvetoQuadraticRel.internal() : super.internal();

  @DocsEditable
  @DomName('SVGPathSegCurvetoQuadraticRel.x')
  num get x native "SVGPathSegCurvetoQuadraticRel_x_Getter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoQuadraticRel.x')
  void set x(num value) native "SVGPathSegCurvetoQuadraticRel_x_Setter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoQuadraticRel.x1')
  num get x1 native "SVGPathSegCurvetoQuadraticRel_x1_Getter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoQuadraticRel.x1')
  void set x1(num value) native "SVGPathSegCurvetoQuadraticRel_x1_Setter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoQuadraticRel.y')
  num get y native "SVGPathSegCurvetoQuadraticRel_y_Getter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoQuadraticRel.y')
  void set y(num value) native "SVGPathSegCurvetoQuadraticRel_y_Setter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoQuadraticRel.y1')
  num get y1 native "SVGPathSegCurvetoQuadraticRel_y1_Getter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoQuadraticRel.y1')
  void set y1(num value) native "SVGPathSegCurvetoQuadraticRel_y1_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGPathSegCurvetoQuadraticSmoothAbs')
class PathSegCurvetoQuadraticSmoothAbs extends PathSeg {
  PathSegCurvetoQuadraticSmoothAbs.internal() : super.internal();

  @DocsEditable
  @DomName('SVGPathSegCurvetoQuadraticSmoothAbs.x')
  num get x native "SVGPathSegCurvetoQuadraticSmoothAbs_x_Getter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoQuadraticSmoothAbs.x')
  void set x(num value) native "SVGPathSegCurvetoQuadraticSmoothAbs_x_Setter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoQuadraticSmoothAbs.y')
  num get y native "SVGPathSegCurvetoQuadraticSmoothAbs_y_Getter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoQuadraticSmoothAbs.y')
  void set y(num value) native "SVGPathSegCurvetoQuadraticSmoothAbs_y_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGPathSegCurvetoQuadraticSmoothRel')
class PathSegCurvetoQuadraticSmoothRel extends PathSeg {
  PathSegCurvetoQuadraticSmoothRel.internal() : super.internal();

  @DocsEditable
  @DomName('SVGPathSegCurvetoQuadraticSmoothRel.x')
  num get x native "SVGPathSegCurvetoQuadraticSmoothRel_x_Getter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoQuadraticSmoothRel.x')
  void set x(num value) native "SVGPathSegCurvetoQuadraticSmoothRel_x_Setter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoQuadraticSmoothRel.y')
  num get y native "SVGPathSegCurvetoQuadraticSmoothRel_y_Getter";

  @DocsEditable
  @DomName('SVGPathSegCurvetoQuadraticSmoothRel.y')
  void set y(num value) native "SVGPathSegCurvetoQuadraticSmoothRel_y_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGPathSegLinetoAbs')
class PathSegLinetoAbs extends PathSeg {
  PathSegLinetoAbs.internal() : super.internal();

  @DocsEditable
  @DomName('SVGPathSegLinetoAbs.x')
  num get x native "SVGPathSegLinetoAbs_x_Getter";

  @DocsEditable
  @DomName('SVGPathSegLinetoAbs.x')
  void set x(num value) native "SVGPathSegLinetoAbs_x_Setter";

  @DocsEditable
  @DomName('SVGPathSegLinetoAbs.y')
  num get y native "SVGPathSegLinetoAbs_y_Getter";

  @DocsEditable
  @DomName('SVGPathSegLinetoAbs.y')
  void set y(num value) native "SVGPathSegLinetoAbs_y_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGPathSegLinetoHorizontalAbs')
class PathSegLinetoHorizontalAbs extends PathSeg {
  PathSegLinetoHorizontalAbs.internal() : super.internal();

  @DocsEditable
  @DomName('SVGPathSegLinetoHorizontalAbs.x')
  num get x native "SVGPathSegLinetoHorizontalAbs_x_Getter";

  @DocsEditable
  @DomName('SVGPathSegLinetoHorizontalAbs.x')
  void set x(num value) native "SVGPathSegLinetoHorizontalAbs_x_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGPathSegLinetoHorizontalRel')
class PathSegLinetoHorizontalRel extends PathSeg {
  PathSegLinetoHorizontalRel.internal() : super.internal();

  @DocsEditable
  @DomName('SVGPathSegLinetoHorizontalRel.x')
  num get x native "SVGPathSegLinetoHorizontalRel_x_Getter";

  @DocsEditable
  @DomName('SVGPathSegLinetoHorizontalRel.x')
  void set x(num value) native "SVGPathSegLinetoHorizontalRel_x_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGPathSegLinetoRel')
class PathSegLinetoRel extends PathSeg {
  PathSegLinetoRel.internal() : super.internal();

  @DocsEditable
  @DomName('SVGPathSegLinetoRel.x')
  num get x native "SVGPathSegLinetoRel_x_Getter";

  @DocsEditable
  @DomName('SVGPathSegLinetoRel.x')
  void set x(num value) native "SVGPathSegLinetoRel_x_Setter";

  @DocsEditable
  @DomName('SVGPathSegLinetoRel.y')
  num get y native "SVGPathSegLinetoRel_y_Getter";

  @DocsEditable
  @DomName('SVGPathSegLinetoRel.y')
  void set y(num value) native "SVGPathSegLinetoRel_y_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGPathSegLinetoVerticalAbs')
class PathSegLinetoVerticalAbs extends PathSeg {
  PathSegLinetoVerticalAbs.internal() : super.internal();

  @DocsEditable
  @DomName('SVGPathSegLinetoVerticalAbs.y')
  num get y native "SVGPathSegLinetoVerticalAbs_y_Getter";

  @DocsEditable
  @DomName('SVGPathSegLinetoVerticalAbs.y')
  void set y(num value) native "SVGPathSegLinetoVerticalAbs_y_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGPathSegLinetoVerticalRel')
class PathSegLinetoVerticalRel extends PathSeg {
  PathSegLinetoVerticalRel.internal() : super.internal();

  @DocsEditable
  @DomName('SVGPathSegLinetoVerticalRel.y')
  num get y native "SVGPathSegLinetoVerticalRel_y_Getter";

  @DocsEditable
  @DomName('SVGPathSegLinetoVerticalRel.y')
  void set y(num value) native "SVGPathSegLinetoVerticalRel_y_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGPathSegList')
class PathSegList extends NativeFieldWrapperClass1 implements List<PathSeg> {
  PathSegList.internal();

  @DocsEditable
  @DomName('SVGPathSegList.numberOfItems')
  int get numberOfItems native "SVGPathSegList_numberOfItems_Getter";

  PathSeg operator[](int index) native "SVGPathSegList_item_Callback";

  void operator[]=(int index, PathSeg value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<PathSeg> mixins.
  // PathSeg is the element type.

  // From Iterable<PathSeg>:

  Iterator<PathSeg> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<PathSeg>(this);
  }

  // SVG Collections expose numberOfItems rather than length.
  int get length => numberOfItems;
  dynamic reduce(dynamic initialValue, dynamic combine(dynamic, PathSeg)) {
    return Collections.reduce(this, initialValue, combine);
  }

  bool contains(PathSeg element) => Collections.contains(this, element);

  void forEach(void f(PathSeg element)) => Collections.forEach(this, f);

  String join([String separator]) => Collections.joinList(this, separator);

  List mappedBy(f(PathSeg element)) => new MappedList<PathSeg, dynamic>(this, f);

  Iterable<PathSeg> where(bool f(PathSeg element)) => new WhereIterable<PathSeg>(this, f);

  bool every(bool f(PathSeg element)) => Collections.every(this, f);

  bool any(bool f(PathSeg element)) => Collections.any(this, f);

  List<PathSeg> toList() => new List<PathSeg>.from(this);
  Set<PathSeg> toSet() => new Set<PathSeg>.from(this);

  bool get isEmpty => this.length == 0;

  List<PathSeg> take(int n) => new ListView<PathSeg>(this, 0, n);

  Iterable<PathSeg> takeWhile(bool test(PathSeg value)) {
    return new TakeWhileIterable<PathSeg>(this, test);
  }

  List<PathSeg> skip(int n) => new ListView<PathSeg>(this, n, null);

  Iterable<PathSeg> skipWhile(bool test(PathSeg value)) {
    return new SkipWhileIterable<PathSeg>(this, test);
  }

  PathSeg firstMatching(bool test(PathSeg value), { PathSeg orElse() }) {
    return Collections.firstMatching(this, test, orElse);
  }

  PathSeg lastMatching(bool test(PathSeg value), {PathSeg orElse()}) {
    return Collections.lastMatchingInList(this, test, orElse);
  }

  PathSeg singleMatching(bool test(PathSeg value)) {
    return Collections.singleMatching(this, test);
  }

  PathSeg elementAt(int index) {
    return this[index];
  }

  // From Collection<PathSeg>:

  void add(PathSeg value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(PathSeg value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<PathSeg> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<PathSeg>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  // contains() defined by IDL.

  void sort([int compare(PathSeg a, PathSeg b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(PathSeg element, [int start = 0]) =>
      Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(PathSeg element, [int start]) {
    if (start == null) start = length - 1;
    return Lists.lastIndexOf(this, element, start);
  }

  PathSeg get first {
    if (this.length > 0) return this[0];
    throw new StateError("No elements");
  }

  PathSeg get last {
    if (this.length > 0) return this[this.length - 1];
    throw new StateError("No elements");
  }

  PathSeg get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  PathSeg min([int compare(PathSeg a, PathSeg b)]) => Collections.min(this, compare);

  PathSeg max([int compare(PathSeg a, PathSeg b)]) => Collections.max(this, compare);

  PathSeg removeAt(int pos) {
    throw new UnsupportedError("Cannot removeAt on immutable List.");
  }

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
      Lists.getRange(this, start, rangeLength, <PathSeg>[]);

  // -- end List<PathSeg> mixins.

  @DocsEditable
  @DomName('SVGPathSegList.appendItem')
  PathSeg appendItem(PathSeg newItem) native "SVGPathSegList_appendItem_Callback";

  @DocsEditable
  @DomName('SVGPathSegList.clear')
  void clear() native "SVGPathSegList_clear_Callback";

  @DocsEditable
  @DomName('SVGPathSegList.getItem')
  PathSeg getItem(int index) native "SVGPathSegList_getItem_Callback";

  @DocsEditable
  @DomName('SVGPathSegList.initialize')
  PathSeg initialize(PathSeg newItem) native "SVGPathSegList_initialize_Callback";

  @DocsEditable
  @DomName('SVGPathSegList.insertItemBefore')
  PathSeg insertItemBefore(PathSeg newItem, int index) native "SVGPathSegList_insertItemBefore_Callback";

  @DocsEditable
  @DomName('SVGPathSegList.removeItem')
  PathSeg removeItem(int index) native "SVGPathSegList_removeItem_Callback";

  @DocsEditable
  @DomName('SVGPathSegList.replaceItem')
  PathSeg replaceItem(PathSeg newItem, int index) native "SVGPathSegList_replaceItem_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGPathSegMovetoAbs')
class PathSegMovetoAbs extends PathSeg {
  PathSegMovetoAbs.internal() : super.internal();

  @DocsEditable
  @DomName('SVGPathSegMovetoAbs.x')
  num get x native "SVGPathSegMovetoAbs_x_Getter";

  @DocsEditable
  @DomName('SVGPathSegMovetoAbs.x')
  void set x(num value) native "SVGPathSegMovetoAbs_x_Setter";

  @DocsEditable
  @DomName('SVGPathSegMovetoAbs.y')
  num get y native "SVGPathSegMovetoAbs_y_Getter";

  @DocsEditable
  @DomName('SVGPathSegMovetoAbs.y')
  void set y(num value) native "SVGPathSegMovetoAbs_y_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGPathSegMovetoRel')
class PathSegMovetoRel extends PathSeg {
  PathSegMovetoRel.internal() : super.internal();

  @DocsEditable
  @DomName('SVGPathSegMovetoRel.x')
  num get x native "SVGPathSegMovetoRel_x_Getter";

  @DocsEditable
  @DomName('SVGPathSegMovetoRel.x')
  void set x(num value) native "SVGPathSegMovetoRel_x_Setter";

  @DocsEditable
  @DomName('SVGPathSegMovetoRel.y')
  num get y native "SVGPathSegMovetoRel_y_Getter";

  @DocsEditable
  @DomName('SVGPathSegMovetoRel.y')
  void set y(num value) native "SVGPathSegMovetoRel_y_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGPatternElement')
class PatternElement extends SvgElement implements FitToViewBox, Tests, UriReference, Stylable, ExternalResourcesRequired, LangSpace {
  PatternElement.internal() : super.internal();

  @DocsEditable
  factory PatternElement() => _SvgElementFactoryProvider.createSvgElement_tag("pattern");

  @DocsEditable
  @DomName('SVGPatternElement.height')
  AnimatedLength get height native "SVGPatternElement_height_Getter";

  @DocsEditable
  @DomName('SVGPatternElement.patternContentUnits')
  AnimatedEnumeration get patternContentUnits native "SVGPatternElement_patternContentUnits_Getter";

  @DocsEditable
  @DomName('SVGPatternElement.patternTransform')
  AnimatedTransformList get patternTransform native "SVGPatternElement_patternTransform_Getter";

  @DocsEditable
  @DomName('SVGPatternElement.patternUnits')
  AnimatedEnumeration get patternUnits native "SVGPatternElement_patternUnits_Getter";

  @DocsEditable
  @DomName('SVGPatternElement.width')
  AnimatedLength get width native "SVGPatternElement_width_Getter";

  @DocsEditable
  @DomName('SVGPatternElement.x')
  AnimatedLength get x native "SVGPatternElement_x_Getter";

  @DocsEditable
  @DomName('SVGPatternElement.y')
  AnimatedLength get y native "SVGPatternElement_y_Getter";

  @DocsEditable
  @DomName('SVGPatternElement.externalResourcesRequired')
  AnimatedBoolean get externalResourcesRequired native "SVGPatternElement_externalResourcesRequired_Getter";

  @DocsEditable
  @DomName('SVGPatternElement.preserveAspectRatio')
  AnimatedPreserveAspectRatio get preserveAspectRatio native "SVGPatternElement_preserveAspectRatio_Getter";

  @DocsEditable
  @DomName('SVGPatternElement.viewBox')
  AnimatedRect get viewBox native "SVGPatternElement_viewBox_Getter";

  @DocsEditable
  @DomName('SVGPatternElement.xmllang')
  String get xmllang native "SVGPatternElement_xmllang_Getter";

  @DocsEditable
  @DomName('SVGPatternElement.xmllang')
  void set xmllang(String value) native "SVGPatternElement_xmllang_Setter";

  @DocsEditable
  @DomName('SVGPatternElement.xmlspace')
  String get xmlspace native "SVGPatternElement_xmlspace_Getter";

  @DocsEditable
  @DomName('SVGPatternElement.xmlspace')
  void set xmlspace(String value) native "SVGPatternElement_xmlspace_Setter";

  @DocsEditable
  @DomName('SVGPatternElement.className')
  AnimatedString get $dom_svgClassName native "SVGPatternElement_className_Getter";

  @DocsEditable
  @DomName('SVGPatternElement.style')
  CssStyleDeclaration get style native "SVGPatternElement_style_Getter";

  @DocsEditable
  @DomName('SVGPatternElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native "SVGPatternElement_getPresentationAttribute_Callback";

  @DocsEditable
  @DomName('SVGPatternElement.requiredExtensions')
  StringList get requiredExtensions native "SVGPatternElement_requiredExtensions_Getter";

  @DocsEditable
  @DomName('SVGPatternElement.requiredFeatures')
  StringList get requiredFeatures native "SVGPatternElement_requiredFeatures_Getter";

  @DocsEditable
  @DomName('SVGPatternElement.systemLanguage')
  StringList get systemLanguage native "SVGPatternElement_systemLanguage_Getter";

  @DocsEditable
  @DomName('SVGPatternElement.hasExtension')
  bool hasExtension(String extension) native "SVGPatternElement_hasExtension_Callback";

  @DocsEditable
  @DomName('SVGPatternElement.href')
  AnimatedString get href native "SVGPatternElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGPoint')
class Point extends NativeFieldWrapperClass1 {
  Point.internal();

  @DocsEditable
  @DomName('SVGPoint.x')
  num get x native "SVGPoint_x_Getter";

  @DocsEditable
  @DomName('SVGPoint.x')
  void set x(num value) native "SVGPoint_x_Setter";

  @DocsEditable
  @DomName('SVGPoint.y')
  num get y native "SVGPoint_y_Getter";

  @DocsEditable
  @DomName('SVGPoint.y')
  void set y(num value) native "SVGPoint_y_Setter";

  @DocsEditable
  @DomName('SVGPoint.matrixTransform')
  Point matrixTransform(Matrix matrix) native "SVGPoint_matrixTransform_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGPointList')
class PointList extends NativeFieldWrapperClass1 {
  PointList.internal();

  @DocsEditable
  @DomName('SVGPointList.numberOfItems')
  int get numberOfItems native "SVGPointList_numberOfItems_Getter";

  @DocsEditable
  @DomName('SVGPointList.appendItem')
  Point appendItem(Point item) native "SVGPointList_appendItem_Callback";

  @DocsEditable
  @DomName('SVGPointList.clear')
  void clear() native "SVGPointList_clear_Callback";

  @DocsEditable
  @DomName('SVGPointList.getItem')
  Point getItem(int index) native "SVGPointList_getItem_Callback";

  @DocsEditable
  @DomName('SVGPointList.initialize')
  Point initialize(Point item) native "SVGPointList_initialize_Callback";

  @DocsEditable
  @DomName('SVGPointList.insertItemBefore')
  Point insertItemBefore(Point item, int index) native "SVGPointList_insertItemBefore_Callback";

  @DocsEditable
  @DomName('SVGPointList.removeItem')
  Point removeItem(int index) native "SVGPointList_removeItem_Callback";

  @DocsEditable
  @DomName('SVGPointList.replaceItem')
  Point replaceItem(Point item, int index) native "SVGPointList_replaceItem_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGPolygonElement')
class PolygonElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace {
  PolygonElement.internal() : super.internal();

  @DocsEditable
  factory PolygonElement() => _SvgElementFactoryProvider.createSvgElement_tag("polygon");

  @DocsEditable
  @DomName('SVGPolygonElement.animatedPoints')
  PointList get animatedPoints native "SVGPolygonElement_animatedPoints_Getter";

  @DocsEditable
  @DomName('SVGPolygonElement.points')
  PointList get points native "SVGPolygonElement_points_Getter";

  @DocsEditable
  @DomName('SVGPolygonElement.externalResourcesRequired')
  AnimatedBoolean get externalResourcesRequired native "SVGPolygonElement_externalResourcesRequired_Getter";

  @DocsEditable
  @DomName('SVGPolygonElement.xmllang')
  String get xmllang native "SVGPolygonElement_xmllang_Getter";

  @DocsEditable
  @DomName('SVGPolygonElement.xmllang')
  void set xmllang(String value) native "SVGPolygonElement_xmllang_Setter";

  @DocsEditable
  @DomName('SVGPolygonElement.xmlspace')
  String get xmlspace native "SVGPolygonElement_xmlspace_Getter";

  @DocsEditable
  @DomName('SVGPolygonElement.xmlspace')
  void set xmlspace(String value) native "SVGPolygonElement_xmlspace_Setter";

  @DocsEditable
  @DomName('SVGPolygonElement.farthestViewportElement')
  SvgElement get farthestViewportElement native "SVGPolygonElement_farthestViewportElement_Getter";

  @DocsEditable
  @DomName('SVGPolygonElement.nearestViewportElement')
  SvgElement get nearestViewportElement native "SVGPolygonElement_nearestViewportElement_Getter";

  @DocsEditable
  @DomName('SVGPolygonElement.getBBox')
  Rect getBBox() native "SVGPolygonElement_getBBox_Callback";

  @DocsEditable
  @DomName('SVGPolygonElement.getCTM')
  Matrix getCtm() native "SVGPolygonElement_getCTM_Callback";

  @DocsEditable
  @DomName('SVGPolygonElement.getScreenCTM')
  Matrix getScreenCtm() native "SVGPolygonElement_getScreenCTM_Callback";

  @DocsEditable
  @DomName('SVGPolygonElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native "SVGPolygonElement_getTransformToElement_Callback";

  @DocsEditable
  @DomName('SVGPolygonElement.className')
  AnimatedString get $dom_svgClassName native "SVGPolygonElement_className_Getter";

  @DocsEditable
  @DomName('SVGPolygonElement.style')
  CssStyleDeclaration get style native "SVGPolygonElement_style_Getter";

  @DocsEditable
  @DomName('SVGPolygonElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native "SVGPolygonElement_getPresentationAttribute_Callback";

  @DocsEditable
  @DomName('SVGPolygonElement.requiredExtensions')
  StringList get requiredExtensions native "SVGPolygonElement_requiredExtensions_Getter";

  @DocsEditable
  @DomName('SVGPolygonElement.requiredFeatures')
  StringList get requiredFeatures native "SVGPolygonElement_requiredFeatures_Getter";

  @DocsEditable
  @DomName('SVGPolygonElement.systemLanguage')
  StringList get systemLanguage native "SVGPolygonElement_systemLanguage_Getter";

  @DocsEditable
  @DomName('SVGPolygonElement.hasExtension')
  bool hasExtension(String extension) native "SVGPolygonElement_hasExtension_Callback";

  @DocsEditable
  @DomName('SVGPolygonElement.transform')
  AnimatedTransformList get transform native "SVGPolygonElement_transform_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGPolylineElement')
class PolylineElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace {
  PolylineElement.internal() : super.internal();

  @DocsEditable
  factory PolylineElement() => _SvgElementFactoryProvider.createSvgElement_tag("polyline");

  @DocsEditable
  @DomName('SVGPolylineElement.animatedPoints')
  PointList get animatedPoints native "SVGPolylineElement_animatedPoints_Getter";

  @DocsEditable
  @DomName('SVGPolylineElement.points')
  PointList get points native "SVGPolylineElement_points_Getter";

  @DocsEditable
  @DomName('SVGPolylineElement.externalResourcesRequired')
  AnimatedBoolean get externalResourcesRequired native "SVGPolylineElement_externalResourcesRequired_Getter";

  @DocsEditable
  @DomName('SVGPolylineElement.xmllang')
  String get xmllang native "SVGPolylineElement_xmllang_Getter";

  @DocsEditable
  @DomName('SVGPolylineElement.xmllang')
  void set xmllang(String value) native "SVGPolylineElement_xmllang_Setter";

  @DocsEditable
  @DomName('SVGPolylineElement.xmlspace')
  String get xmlspace native "SVGPolylineElement_xmlspace_Getter";

  @DocsEditable
  @DomName('SVGPolylineElement.xmlspace')
  void set xmlspace(String value) native "SVGPolylineElement_xmlspace_Setter";

  @DocsEditable
  @DomName('SVGPolylineElement.farthestViewportElement')
  SvgElement get farthestViewportElement native "SVGPolylineElement_farthestViewportElement_Getter";

  @DocsEditable
  @DomName('SVGPolylineElement.nearestViewportElement')
  SvgElement get nearestViewportElement native "SVGPolylineElement_nearestViewportElement_Getter";

  @DocsEditable
  @DomName('SVGPolylineElement.getBBox')
  Rect getBBox() native "SVGPolylineElement_getBBox_Callback";

  @DocsEditable
  @DomName('SVGPolylineElement.getCTM')
  Matrix getCtm() native "SVGPolylineElement_getCTM_Callback";

  @DocsEditable
  @DomName('SVGPolylineElement.getScreenCTM')
  Matrix getScreenCtm() native "SVGPolylineElement_getScreenCTM_Callback";

  @DocsEditable
  @DomName('SVGPolylineElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native "SVGPolylineElement_getTransformToElement_Callback";

  @DocsEditable
  @DomName('SVGPolylineElement.className')
  AnimatedString get $dom_svgClassName native "SVGPolylineElement_className_Getter";

  @DocsEditable
  @DomName('SVGPolylineElement.style')
  CssStyleDeclaration get style native "SVGPolylineElement_style_Getter";

  @DocsEditable
  @DomName('SVGPolylineElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native "SVGPolylineElement_getPresentationAttribute_Callback";

  @DocsEditable
  @DomName('SVGPolylineElement.requiredExtensions')
  StringList get requiredExtensions native "SVGPolylineElement_requiredExtensions_Getter";

  @DocsEditable
  @DomName('SVGPolylineElement.requiredFeatures')
  StringList get requiredFeatures native "SVGPolylineElement_requiredFeatures_Getter";

  @DocsEditable
  @DomName('SVGPolylineElement.systemLanguage')
  StringList get systemLanguage native "SVGPolylineElement_systemLanguage_Getter";

  @DocsEditable
  @DomName('SVGPolylineElement.hasExtension')
  bool hasExtension(String extension) native "SVGPolylineElement_hasExtension_Callback";

  @DocsEditable
  @DomName('SVGPolylineElement.transform')
  AnimatedTransformList get transform native "SVGPolylineElement_transform_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGPreserveAspectRatio')
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

  @DocsEditable
  @DomName('SVGPreserveAspectRatio.align')
  int get align native "SVGPreserveAspectRatio_align_Getter";

  @DocsEditable
  @DomName('SVGPreserveAspectRatio.align')
  void set align(int value) native "SVGPreserveAspectRatio_align_Setter";

  @DocsEditable
  @DomName('SVGPreserveAspectRatio.meetOrSlice')
  int get meetOrSlice native "SVGPreserveAspectRatio_meetOrSlice_Getter";

  @DocsEditable
  @DomName('SVGPreserveAspectRatio.meetOrSlice')
  void set meetOrSlice(int value) native "SVGPreserveAspectRatio_meetOrSlice_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGRadialGradientElement')
class RadialGradientElement extends GradientElement {
  RadialGradientElement.internal() : super.internal();

  @DocsEditable
  factory RadialGradientElement() => _SvgElementFactoryProvider.createSvgElement_tag("radialGradient");

  @DocsEditable
  @DomName('SVGRadialGradientElement.cx')
  AnimatedLength get cx native "SVGRadialGradientElement_cx_Getter";

  @DocsEditable
  @DomName('SVGRadialGradientElement.cy')
  AnimatedLength get cy native "SVGRadialGradientElement_cy_Getter";

  @DocsEditable
  @DomName('SVGRadialGradientElement.fr')
  AnimatedLength get fr native "SVGRadialGradientElement_fr_Getter";

  @DocsEditable
  @DomName('SVGRadialGradientElement.fx')
  AnimatedLength get fx native "SVGRadialGradientElement_fx_Getter";

  @DocsEditable
  @DomName('SVGRadialGradientElement.fy')
  AnimatedLength get fy native "SVGRadialGradientElement_fy_Getter";

  @DocsEditable
  @DomName('SVGRadialGradientElement.r')
  AnimatedLength get r native "SVGRadialGradientElement_r_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGRect')
class Rect extends NativeFieldWrapperClass1 {
  Rect.internal();

  @DocsEditable
  @DomName('SVGRect.height')
  num get height native "SVGRect_height_Getter";

  @DocsEditable
  @DomName('SVGRect.height')
  void set height(num value) native "SVGRect_height_Setter";

  @DocsEditable
  @DomName('SVGRect.width')
  num get width native "SVGRect_width_Getter";

  @DocsEditable
  @DomName('SVGRect.width')
  void set width(num value) native "SVGRect_width_Setter";

  @DocsEditable
  @DomName('SVGRect.x')
  num get x native "SVGRect_x_Getter";

  @DocsEditable
  @DomName('SVGRect.x')
  void set x(num value) native "SVGRect_x_Setter";

  @DocsEditable
  @DomName('SVGRect.y')
  num get y native "SVGRect_y_Getter";

  @DocsEditable
  @DomName('SVGRect.y')
  void set y(num value) native "SVGRect_y_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGRectElement')
class RectElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace {
  RectElement.internal() : super.internal();

  @DocsEditable
  factory RectElement() => _SvgElementFactoryProvider.createSvgElement_tag("rect");

  @DocsEditable
  @DomName('SVGRectElement.height')
  AnimatedLength get height native "SVGRectElement_height_Getter";

  @DocsEditable
  @DomName('SVGRectElement.rx')
  AnimatedLength get rx native "SVGRectElement_rx_Getter";

  @DocsEditable
  @DomName('SVGRectElement.ry')
  AnimatedLength get ry native "SVGRectElement_ry_Getter";

  @DocsEditable
  @DomName('SVGRectElement.width')
  AnimatedLength get width native "SVGRectElement_width_Getter";

  @DocsEditable
  @DomName('SVGRectElement.x')
  AnimatedLength get x native "SVGRectElement_x_Getter";

  @DocsEditable
  @DomName('SVGRectElement.y')
  AnimatedLength get y native "SVGRectElement_y_Getter";

  @DocsEditable
  @DomName('SVGRectElement.externalResourcesRequired')
  AnimatedBoolean get externalResourcesRequired native "SVGRectElement_externalResourcesRequired_Getter";

  @DocsEditable
  @DomName('SVGRectElement.xmllang')
  String get xmllang native "SVGRectElement_xmllang_Getter";

  @DocsEditable
  @DomName('SVGRectElement.xmllang')
  void set xmllang(String value) native "SVGRectElement_xmllang_Setter";

  @DocsEditable
  @DomName('SVGRectElement.xmlspace')
  String get xmlspace native "SVGRectElement_xmlspace_Getter";

  @DocsEditable
  @DomName('SVGRectElement.xmlspace')
  void set xmlspace(String value) native "SVGRectElement_xmlspace_Setter";

  @DocsEditable
  @DomName('SVGRectElement.farthestViewportElement')
  SvgElement get farthestViewportElement native "SVGRectElement_farthestViewportElement_Getter";

  @DocsEditable
  @DomName('SVGRectElement.nearestViewportElement')
  SvgElement get nearestViewportElement native "SVGRectElement_nearestViewportElement_Getter";

  @DocsEditable
  @DomName('SVGRectElement.getBBox')
  Rect getBBox() native "SVGRectElement_getBBox_Callback";

  @DocsEditable
  @DomName('SVGRectElement.getCTM')
  Matrix getCtm() native "SVGRectElement_getCTM_Callback";

  @DocsEditable
  @DomName('SVGRectElement.getScreenCTM')
  Matrix getScreenCtm() native "SVGRectElement_getScreenCTM_Callback";

  @DocsEditable
  @DomName('SVGRectElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native "SVGRectElement_getTransformToElement_Callback";

  @DocsEditable
  @DomName('SVGRectElement.className')
  AnimatedString get $dom_svgClassName native "SVGRectElement_className_Getter";

  @DocsEditable
  @DomName('SVGRectElement.style')
  CssStyleDeclaration get style native "SVGRectElement_style_Getter";

  @DocsEditable
  @DomName('SVGRectElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native "SVGRectElement_getPresentationAttribute_Callback";

  @DocsEditable
  @DomName('SVGRectElement.requiredExtensions')
  StringList get requiredExtensions native "SVGRectElement_requiredExtensions_Getter";

  @DocsEditable
  @DomName('SVGRectElement.requiredFeatures')
  StringList get requiredFeatures native "SVGRectElement_requiredFeatures_Getter";

  @DocsEditable
  @DomName('SVGRectElement.systemLanguage')
  StringList get systemLanguage native "SVGRectElement_systemLanguage_Getter";

  @DocsEditable
  @DomName('SVGRectElement.hasExtension')
  bool hasExtension(String extension) native "SVGRectElement_hasExtension_Callback";

  @DocsEditable
  @DomName('SVGRectElement.transform')
  AnimatedTransformList get transform native "SVGRectElement_transform_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGRenderingIntent')
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


@DocsEditable
@DomName('SVGScriptElement')
class ScriptElement extends SvgElement implements UriReference, ExternalResourcesRequired {
  ScriptElement.internal() : super.internal();

  @DocsEditable
  factory ScriptElement() => _SvgElementFactoryProvider.createSvgElement_tag("script");

  @DocsEditable
  @DomName('SVGScriptElement.type')
  String get type native "SVGScriptElement_type_Getter";

  @DocsEditable
  @DomName('SVGScriptElement.type')
  void set type(String value) native "SVGScriptElement_type_Setter";

  @DocsEditable
  @DomName('SVGScriptElement.externalResourcesRequired')
  AnimatedBoolean get externalResourcesRequired native "SVGScriptElement_externalResourcesRequired_Getter";

  @DocsEditable
  @DomName('SVGScriptElement.href')
  AnimatedString get href native "SVGScriptElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGSetElement')
class SetElement extends AnimationElement {
  SetElement.internal() : super.internal();

  @DocsEditable
  factory SetElement() => _SvgElementFactoryProvider.createSvgElement_tag("set");

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGStopElement')
class StopElement extends SvgElement implements Stylable {
  StopElement.internal() : super.internal();

  @DocsEditable
  factory StopElement() => _SvgElementFactoryProvider.createSvgElement_tag("stop");

  @DocsEditable
  @DomName('SVGStopElement.offset')
  AnimatedNumber get offset native "SVGStopElement_offset_Getter";

  @DocsEditable
  @DomName('SVGStopElement.className')
  AnimatedString get $dom_svgClassName native "SVGStopElement_className_Getter";

  @DocsEditable
  @DomName('SVGStopElement.style')
  CssStyleDeclaration get style native "SVGStopElement_style_Getter";

  @DocsEditable
  @DomName('SVGStopElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native "SVGStopElement_getPresentationAttribute_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGStringList')
class StringList extends NativeFieldWrapperClass1 implements List<String> {
  StringList.internal();

  @DocsEditable
  @DomName('SVGStringList.numberOfItems')
  int get numberOfItems native "SVGStringList_numberOfItems_Getter";

  String operator[](int index) native "SVGStringList_item_Callback";

  void operator[]=(int index, String value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<String> mixins.
  // String is the element type.

  // From Iterable<String>:

  Iterator<String> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<String>(this);
  }

  // SVG Collections expose numberOfItems rather than length.
  int get length => numberOfItems;
  dynamic reduce(dynamic initialValue, dynamic combine(dynamic, String)) {
    return Collections.reduce(this, initialValue, combine);
  }

  bool contains(String element) => Collections.contains(this, element);

  void forEach(void f(String element)) => Collections.forEach(this, f);

  String join([String separator]) => Collections.joinList(this, separator);

  List mappedBy(f(String element)) => new MappedList<String, dynamic>(this, f);

  Iterable<String> where(bool f(String element)) => new WhereIterable<String>(this, f);

  bool every(bool f(String element)) => Collections.every(this, f);

  bool any(bool f(String element)) => Collections.any(this, f);

  List<String> toList() => new List<String>.from(this);
  Set<String> toSet() => new Set<String>.from(this);

  bool get isEmpty => this.length == 0;

  List<String> take(int n) => new ListView<String>(this, 0, n);

  Iterable<String> takeWhile(bool test(String value)) {
    return new TakeWhileIterable<String>(this, test);
  }

  List<String> skip(int n) => new ListView<String>(this, n, null);

  Iterable<String> skipWhile(bool test(String value)) {
    return new SkipWhileIterable<String>(this, test);
  }

  String firstMatching(bool test(String value), { String orElse() }) {
    return Collections.firstMatching(this, test, orElse);
  }

  String lastMatching(bool test(String value), {String orElse()}) {
    return Collections.lastMatchingInList(this, test, orElse);
  }

  String singleMatching(bool test(String value)) {
    return Collections.singleMatching(this, test);
  }

  String elementAt(int index) {
    return this[index];
  }

  // From Collection<String>:

  void add(String value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(String value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<String> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<String>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  // contains() defined by IDL.

  void sort([int compare(String a, String b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(String element, [int start = 0]) =>
      Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(String element, [int start]) {
    if (start == null) start = length - 1;
    return Lists.lastIndexOf(this, element, start);
  }

  String get first {
    if (this.length > 0) return this[0];
    throw new StateError("No elements");
  }

  String get last {
    if (this.length > 0) return this[this.length - 1];
    throw new StateError("No elements");
  }

  String get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  String min([int compare(String a, String b)]) => Collections.min(this, compare);

  String max([int compare(String a, String b)]) => Collections.max(this, compare);

  String removeAt(int pos) {
    throw new UnsupportedError("Cannot removeAt on immutable List.");
  }

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
      Lists.getRange(this, start, rangeLength, <String>[]);

  // -- end List<String> mixins.

  @DocsEditable
  @DomName('SVGStringList.appendItem')
  String appendItem(String item) native "SVGStringList_appendItem_Callback";

  @DocsEditable
  @DomName('SVGStringList.clear')
  void clear() native "SVGStringList_clear_Callback";

  @DocsEditable
  @DomName('SVGStringList.getItem')
  String getItem(int index) native "SVGStringList_getItem_Callback";

  @DocsEditable
  @DomName('SVGStringList.initialize')
  String initialize(String item) native "SVGStringList_initialize_Callback";

  @DocsEditable
  @DomName('SVGStringList.insertItemBefore')
  String insertItemBefore(String item, int index) native "SVGStringList_insertItemBefore_Callback";

  @DocsEditable
  @DomName('SVGStringList.removeItem')
  String removeItem(int index) native "SVGStringList_removeItem_Callback";

  @DocsEditable
  @DomName('SVGStringList.replaceItem')
  String replaceItem(String item, int index) native "SVGStringList_replaceItem_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGStylable')
class Stylable extends NativeFieldWrapperClass1 {
  Stylable.internal();

  @DocsEditable
  @DomName('SVGStylable.className')
  AnimatedString get $dom_svgClassName native "SVGStylable_className_Getter";

  @DocsEditable
  @DomName('SVGStylable.style')
  CssStyleDeclaration get style native "SVGStylable_style_Getter";

  @DocsEditable
  @DomName('SVGStylable.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native "SVGStylable_getPresentationAttribute_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGStyleElement')
class StyleElement extends SvgElement implements LangSpace {
  StyleElement.internal() : super.internal();

  @DocsEditable
  factory StyleElement() => _SvgElementFactoryProvider.createSvgElement_tag("style");

  @DocsEditable
  @DomName('SVGStyleElement.disabled')
  bool get disabled native "SVGStyleElement_disabled_Getter";

  @DocsEditable
  @DomName('SVGStyleElement.disabled')
  void set disabled(bool value) native "SVGStyleElement_disabled_Setter";

  @DocsEditable
  @DomName('SVGStyleElement.media')
  String get media native "SVGStyleElement_media_Getter";

  @DocsEditable
  @DomName('SVGStyleElement.media')
  void set media(String value) native "SVGStyleElement_media_Setter";

  @DocsEditable
  @DomName('SVGStyleElement.title')
  String get title native "SVGStyleElement_title_Getter";

  @DocsEditable
  @DomName('SVGStyleElement.title')
  void set title(String value) native "SVGStyleElement_title_Setter";

  @DocsEditable
  @DomName('SVGStyleElement.type')
  String get type native "SVGStyleElement_type_Getter";

  @DocsEditable
  @DomName('SVGStyleElement.type')
  void set type(String value) native "SVGStyleElement_type_Setter";

  @DocsEditable
  @DomName('SVGStyleElement.xmllang')
  String get xmllang native "SVGStyleElement_xmllang_Getter";

  @DocsEditable
  @DomName('SVGStyleElement.xmllang')
  void set xmllang(String value) native "SVGStyleElement_xmllang_Setter";

  @DocsEditable
  @DomName('SVGStyleElement.xmlspace')
  String get xmlspace native "SVGStyleElement_xmlspace_Getter";

  @DocsEditable
  @DomName('SVGStyleElement.xmlspace')
  void set xmlspace(String value) native "SVGStyleElement_xmlspace_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGDocument')
class SvgDocument extends Document {
  SvgDocument.internal() : super.internal();

  @DocsEditable
  @DomName('SVGDocument.rootElement')
  SvgSvgElement get rootElement native "SVGDocument_rootElement_Getter";

  @DocsEditable
  @DomName('SVGDocument.createEvent')
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

@DocsEditable
@DomName('SVGElement')
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

  @deprecated
  List<Element> get elements => new FilteredElementList(this);

  @deprecated
  void set elements(Collection<Element> value) {
    final elements = this.elements;
    elements.clear();
    elements.addAll(value);
  }

  List<Element> get children => new FilteredElementList(this);

  void set children(List<Element> value) {
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

  // Unsupported methods inherited from Element.

  @DomName('Element.insertAdjacentText')
  void insertAdjacentText(String where, String text) {
    throw new UnsupportedError("Cannot invoke insertAdjacentText on SVG.");
  }

  @DomName('Element.insertAdjacentHTML')
  void insertAdjacentHtml(String where, String text) {
    throw new UnsupportedError("Cannot invoke insertAdjacentHtml on SVG.");
  }

  @DomName('Element.insertAdjacentHTML')
  Element insertAdjacentElement(String where, Element element) {
    throw new UnsupportedError("Cannot invoke insertAdjacentElement on SVG.");
  }

  HtmlCollection get $dom_children {
    throw new UnsupportedError("Cannot get dom_children on SVG.");
  }

  bool get isContentEditable => false;
  void click() {
    throw new UnsupportedError("Cannot invoke click SVG.");
  }

  SvgElement.internal() : super.internal();

  @DocsEditable
  @DomName('SVGElement.id')
  String get id native "SVGElement_id_Getter";

  @DocsEditable
  @DomName('SVGElement.id')
  void set id(String value) native "SVGElement_id_Setter";

  @DocsEditable
  @DomName('SVGElement.ownerSVGElement')
  SvgSvgElement get ownerSvgElement native "SVGElement_ownerSVGElement_Getter";

  @DocsEditable
  @DomName('SVGElement.viewportElement')
  SvgElement get viewportElement native "SVGElement_viewportElement_Getter";

  @DocsEditable
  @DomName('SVGElement.xmlbase')
  String get xmlbase native "SVGElement_xmlbase_Getter";

  @DocsEditable
  @DomName('SVGElement.xmlbase')
  void set xmlbase(String value) native "SVGElement_xmlbase_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGException')
class SvgException extends NativeFieldWrapperClass1 {
  SvgException.internal();

  static const int SVG_INVALID_VALUE_ERR = 1;

  static const int SVG_MATRIX_NOT_INVERTABLE = 2;

  static const int SVG_WRONG_TYPE_ERR = 0;

  @DocsEditable
  @DomName('SVGException.code')
  int get code native "SVGException_code_Getter";

  @DocsEditable
  @DomName('SVGException.message')
  String get message native "SVGException_message_Getter";

  @DocsEditable
  @DomName('SVGException.name')
  String get name native "SVGException_name_Getter";

  @DocsEditable
  @DomName('SVGException.toString')
  String toString() native "SVGException_toString_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGSVGElement')
class SvgSvgElement extends SvgElement implements FitToViewBox, Tests, Stylable, Locatable, ExternalResourcesRequired, ZoomAndPan, LangSpace {
  factory SvgSvgElement() => _SvgSvgElementFactoryProvider.createSvgSvgElement();

  SvgSvgElement.internal() : super.internal();

  @DocsEditable
  @DomName('SVGSVGElement.contentScriptType')
  String get contentScriptType native "SVGSVGElement_contentScriptType_Getter";

  @DocsEditable
  @DomName('SVGSVGElement.contentScriptType')
  void set contentScriptType(String value) native "SVGSVGElement_contentScriptType_Setter";

  @DocsEditable
  @DomName('SVGSVGElement.contentStyleType')
  String get contentStyleType native "SVGSVGElement_contentStyleType_Getter";

  @DocsEditable
  @DomName('SVGSVGElement.contentStyleType')
  void set contentStyleType(String value) native "SVGSVGElement_contentStyleType_Setter";

  @DocsEditable
  @DomName('SVGSVGElement.currentScale')
  num get currentScale native "SVGSVGElement_currentScale_Getter";

  @DocsEditable
  @DomName('SVGSVGElement.currentScale')
  void set currentScale(num value) native "SVGSVGElement_currentScale_Setter";

  @DocsEditable
  @DomName('SVGSVGElement.currentTranslate')
  Point get currentTranslate native "SVGSVGElement_currentTranslate_Getter";

  @DocsEditable
  @DomName('SVGSVGElement.currentView')
  ViewSpec get currentView native "SVGSVGElement_currentView_Getter";

  @DocsEditable
  @DomName('SVGSVGElement.height')
  AnimatedLength get height native "SVGSVGElement_height_Getter";

  @DocsEditable
  @DomName('SVGSVGElement.pixelUnitToMillimeterX')
  num get pixelUnitToMillimeterX native "SVGSVGElement_pixelUnitToMillimeterX_Getter";

  @DocsEditable
  @DomName('SVGSVGElement.pixelUnitToMillimeterY')
  num get pixelUnitToMillimeterY native "SVGSVGElement_pixelUnitToMillimeterY_Getter";

  @DocsEditable
  @DomName('SVGSVGElement.screenPixelToMillimeterX')
  num get screenPixelToMillimeterX native "SVGSVGElement_screenPixelToMillimeterX_Getter";

  @DocsEditable
  @DomName('SVGSVGElement.screenPixelToMillimeterY')
  num get screenPixelToMillimeterY native "SVGSVGElement_screenPixelToMillimeterY_Getter";

  @DocsEditable
  @DomName('SVGSVGElement.useCurrentView')
  bool get useCurrentView native "SVGSVGElement_useCurrentView_Getter";

  @DocsEditable
  @DomName('SVGSVGElement.viewport')
  Rect get viewport native "SVGSVGElement_viewport_Getter";

  @DocsEditable
  @DomName('SVGSVGElement.width')
  AnimatedLength get width native "SVGSVGElement_width_Getter";

  @DocsEditable
  @DomName('SVGSVGElement.x')
  AnimatedLength get x native "SVGSVGElement_x_Getter";

  @DocsEditable
  @DomName('SVGSVGElement.y')
  AnimatedLength get y native "SVGSVGElement_y_Getter";

  @DocsEditable
  @DomName('SVGSVGElement.animationsPaused')
  bool animationsPaused() native "SVGSVGElement_animationsPaused_Callback";

  @DocsEditable
  @DomName('SVGSVGElement.checkEnclosure')
  bool checkEnclosure(SvgElement element, Rect rect) native "SVGSVGElement_checkEnclosure_Callback";

  @DocsEditable
  @DomName('SVGSVGElement.checkIntersection')
  bool checkIntersection(SvgElement element, Rect rect) native "SVGSVGElement_checkIntersection_Callback";

  @DocsEditable
  @DomName('SVGSVGElement.createSVGAngle')
  Angle createSvgAngle() native "SVGSVGElement_createSVGAngle_Callback";

  @DocsEditable
  @DomName('SVGSVGElement.createSVGLength')
  Length createSvgLength() native "SVGSVGElement_createSVGLength_Callback";

  @DocsEditable
  @DomName('SVGSVGElement.createSVGMatrix')
  Matrix createSvgMatrix() native "SVGSVGElement_createSVGMatrix_Callback";

  @DocsEditable
  @DomName('SVGSVGElement.createSVGNumber')
  Number createSvgNumber() native "SVGSVGElement_createSVGNumber_Callback";

  @DocsEditable
  @DomName('SVGSVGElement.createSVGPoint')
  Point createSvgPoint() native "SVGSVGElement_createSVGPoint_Callback";

  @DocsEditable
  @DomName('SVGSVGElement.createSVGRect')
  Rect createSvgRect() native "SVGSVGElement_createSVGRect_Callback";

  @DocsEditable
  @DomName('SVGSVGElement.createSVGTransform')
  Transform createSvgTransform() native "SVGSVGElement_createSVGTransform_Callback";

  @DocsEditable
  @DomName('SVGSVGElement.createSVGTransformFromMatrix')
  Transform createSvgTransformFromMatrix(Matrix matrix) native "SVGSVGElement_createSVGTransformFromMatrix_Callback";

  @DocsEditable
  @DomName('SVGSVGElement.deselectAll')
  void deselectAll() native "SVGSVGElement_deselectAll_Callback";

  @DocsEditable
  @DomName('SVGSVGElement.forceRedraw')
  void forceRedraw() native "SVGSVGElement_forceRedraw_Callback";

  @DocsEditable
  @DomName('SVGSVGElement.getCurrentTime')
  num getCurrentTime() native "SVGSVGElement_getCurrentTime_Callback";

  @DocsEditable
  @DomName('SVGSVGElement.getElementById')
  Element getElementById(String elementId) native "SVGSVGElement_getElementById_Callback";

  @DocsEditable
  @DomName('SVGSVGElement.getEnclosureList')
  List<Node> getEnclosureList(Rect rect, SvgElement referenceElement) native "SVGSVGElement_getEnclosureList_Callback";

  @DocsEditable
  @DomName('SVGSVGElement.getIntersectionList')
  List<Node> getIntersectionList(Rect rect, SvgElement referenceElement) native "SVGSVGElement_getIntersectionList_Callback";

  @DocsEditable
  @DomName('SVGSVGElement.pauseAnimations')
  void pauseAnimations() native "SVGSVGElement_pauseAnimations_Callback";

  @DocsEditable
  @DomName('SVGSVGElement.setCurrentTime')
  void setCurrentTime(num seconds) native "SVGSVGElement_setCurrentTime_Callback";

  @DocsEditable
  @DomName('SVGSVGElement.suspendRedraw')
  int suspendRedraw(int maxWaitMilliseconds) native "SVGSVGElement_suspendRedraw_Callback";

  @DocsEditable
  @DomName('SVGSVGElement.unpauseAnimations')
  void unpauseAnimations() native "SVGSVGElement_unpauseAnimations_Callback";

  @DocsEditable
  @DomName('SVGSVGElement.unsuspendRedraw')
  void unsuspendRedraw(int suspendHandleId) native "SVGSVGElement_unsuspendRedraw_Callback";

  @DocsEditable
  @DomName('SVGSVGElement.unsuspendRedrawAll')
  void unsuspendRedrawAll() native "SVGSVGElement_unsuspendRedrawAll_Callback";

  @DocsEditable
  @DomName('SVGSVGElement.externalResourcesRequired')
  AnimatedBoolean get externalResourcesRequired native "SVGSVGElement_externalResourcesRequired_Getter";

  @DocsEditable
  @DomName('SVGSVGElement.preserveAspectRatio')
  AnimatedPreserveAspectRatio get preserveAspectRatio native "SVGSVGElement_preserveAspectRatio_Getter";

  @DocsEditable
  @DomName('SVGSVGElement.viewBox')
  AnimatedRect get viewBox native "SVGSVGElement_viewBox_Getter";

  @DocsEditable
  @DomName('SVGSVGElement.xmllang')
  String get xmllang native "SVGSVGElement_xmllang_Getter";

  @DocsEditable
  @DomName('SVGSVGElement.xmllang')
  void set xmllang(String value) native "SVGSVGElement_xmllang_Setter";

  @DocsEditable
  @DomName('SVGSVGElement.xmlspace')
  String get xmlspace native "SVGSVGElement_xmlspace_Getter";

  @DocsEditable
  @DomName('SVGSVGElement.xmlspace')
  void set xmlspace(String value) native "SVGSVGElement_xmlspace_Setter";

  @DocsEditable
  @DomName('SVGSVGElement.farthestViewportElement')
  SvgElement get farthestViewportElement native "SVGSVGElement_farthestViewportElement_Getter";

  @DocsEditable
  @DomName('SVGSVGElement.nearestViewportElement')
  SvgElement get nearestViewportElement native "SVGSVGElement_nearestViewportElement_Getter";

  @DocsEditable
  @DomName('SVGSVGElement.getBBox')
  Rect getBBox() native "SVGSVGElement_getBBox_Callback";

  @DocsEditable
  @DomName('SVGSVGElement.getCTM')
  Matrix getCtm() native "SVGSVGElement_getCTM_Callback";

  @DocsEditable
  @DomName('SVGSVGElement.getScreenCTM')
  Matrix getScreenCtm() native "SVGSVGElement_getScreenCTM_Callback";

  @DocsEditable
  @DomName('SVGSVGElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native "SVGSVGElement_getTransformToElement_Callback";

  @DocsEditable
  @DomName('SVGSVGElement.className')
  AnimatedString get $dom_svgClassName native "SVGSVGElement_className_Getter";

  @DocsEditable
  @DomName('SVGSVGElement.style')
  CssStyleDeclaration get style native "SVGSVGElement_style_Getter";

  @DocsEditable
  @DomName('SVGSVGElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native "SVGSVGElement_getPresentationAttribute_Callback";

  @DocsEditable
  @DomName('SVGSVGElement.requiredExtensions')
  StringList get requiredExtensions native "SVGSVGElement_requiredExtensions_Getter";

  @DocsEditable
  @DomName('SVGSVGElement.requiredFeatures')
  StringList get requiredFeatures native "SVGSVGElement_requiredFeatures_Getter";

  @DocsEditable
  @DomName('SVGSVGElement.systemLanguage')
  StringList get systemLanguage native "SVGSVGElement_systemLanguage_Getter";

  @DocsEditable
  @DomName('SVGSVGElement.hasExtension')
  bool hasExtension(String extension) native "SVGSVGElement_hasExtension_Callback";

  @DocsEditable
  @DomName('SVGSVGElement.zoomAndPan')
  int get zoomAndPan native "SVGSVGElement_zoomAndPan_Getter";

  @DocsEditable
  @DomName('SVGSVGElement.zoomAndPan')
  void set zoomAndPan(int value) native "SVGSVGElement_zoomAndPan_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGSwitchElement')
class SwitchElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace {
  SwitchElement.internal() : super.internal();

  @DocsEditable
  factory SwitchElement() => _SvgElementFactoryProvider.createSvgElement_tag("switch");

  @DocsEditable
  @DomName('SVGSwitchElement.externalResourcesRequired')
  AnimatedBoolean get externalResourcesRequired native "SVGSwitchElement_externalResourcesRequired_Getter";

  @DocsEditable
  @DomName('SVGSwitchElement.xmllang')
  String get xmllang native "SVGSwitchElement_xmllang_Getter";

  @DocsEditable
  @DomName('SVGSwitchElement.xmllang')
  void set xmllang(String value) native "SVGSwitchElement_xmllang_Setter";

  @DocsEditable
  @DomName('SVGSwitchElement.xmlspace')
  String get xmlspace native "SVGSwitchElement_xmlspace_Getter";

  @DocsEditable
  @DomName('SVGSwitchElement.xmlspace')
  void set xmlspace(String value) native "SVGSwitchElement_xmlspace_Setter";

  @DocsEditable
  @DomName('SVGSwitchElement.farthestViewportElement')
  SvgElement get farthestViewportElement native "SVGSwitchElement_farthestViewportElement_Getter";

  @DocsEditable
  @DomName('SVGSwitchElement.nearestViewportElement')
  SvgElement get nearestViewportElement native "SVGSwitchElement_nearestViewportElement_Getter";

  @DocsEditable
  @DomName('SVGSwitchElement.getBBox')
  Rect getBBox() native "SVGSwitchElement_getBBox_Callback";

  @DocsEditable
  @DomName('SVGSwitchElement.getCTM')
  Matrix getCtm() native "SVGSwitchElement_getCTM_Callback";

  @DocsEditable
  @DomName('SVGSwitchElement.getScreenCTM')
  Matrix getScreenCtm() native "SVGSwitchElement_getScreenCTM_Callback";

  @DocsEditable
  @DomName('SVGSwitchElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native "SVGSwitchElement_getTransformToElement_Callback";

  @DocsEditable
  @DomName('SVGSwitchElement.className')
  AnimatedString get $dom_svgClassName native "SVGSwitchElement_className_Getter";

  @DocsEditable
  @DomName('SVGSwitchElement.style')
  CssStyleDeclaration get style native "SVGSwitchElement_style_Getter";

  @DocsEditable
  @DomName('SVGSwitchElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native "SVGSwitchElement_getPresentationAttribute_Callback";

  @DocsEditable
  @DomName('SVGSwitchElement.requiredExtensions')
  StringList get requiredExtensions native "SVGSwitchElement_requiredExtensions_Getter";

  @DocsEditable
  @DomName('SVGSwitchElement.requiredFeatures')
  StringList get requiredFeatures native "SVGSwitchElement_requiredFeatures_Getter";

  @DocsEditable
  @DomName('SVGSwitchElement.systemLanguage')
  StringList get systemLanguage native "SVGSwitchElement_systemLanguage_Getter";

  @DocsEditable
  @DomName('SVGSwitchElement.hasExtension')
  bool hasExtension(String extension) native "SVGSwitchElement_hasExtension_Callback";

  @DocsEditable
  @DomName('SVGSwitchElement.transform')
  AnimatedTransformList get transform native "SVGSwitchElement_transform_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGSymbolElement')
class SymbolElement extends SvgElement implements FitToViewBox, ExternalResourcesRequired, Stylable, LangSpace {
  SymbolElement.internal() : super.internal();

  @DocsEditable
  factory SymbolElement() => _SvgElementFactoryProvider.createSvgElement_tag("symbol");

  @DocsEditable
  @DomName('SVGSymbolElement.externalResourcesRequired')
  AnimatedBoolean get externalResourcesRequired native "SVGSymbolElement_externalResourcesRequired_Getter";

  @DocsEditable
  @DomName('SVGSymbolElement.preserveAspectRatio')
  AnimatedPreserveAspectRatio get preserveAspectRatio native "SVGSymbolElement_preserveAspectRatio_Getter";

  @DocsEditable
  @DomName('SVGSymbolElement.viewBox')
  AnimatedRect get viewBox native "SVGSymbolElement_viewBox_Getter";

  @DocsEditable
  @DomName('SVGSymbolElement.xmllang')
  String get xmllang native "SVGSymbolElement_xmllang_Getter";

  @DocsEditable
  @DomName('SVGSymbolElement.xmllang')
  void set xmllang(String value) native "SVGSymbolElement_xmllang_Setter";

  @DocsEditable
  @DomName('SVGSymbolElement.xmlspace')
  String get xmlspace native "SVGSymbolElement_xmlspace_Getter";

  @DocsEditable
  @DomName('SVGSymbolElement.xmlspace')
  void set xmlspace(String value) native "SVGSymbolElement_xmlspace_Setter";

  @DocsEditable
  @DomName('SVGSymbolElement.className')
  AnimatedString get $dom_svgClassName native "SVGSymbolElement_className_Getter";

  @DocsEditable
  @DomName('SVGSymbolElement.style')
  CssStyleDeclaration get style native "SVGSymbolElement_style_Getter";

  @DocsEditable
  @DomName('SVGSymbolElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native "SVGSymbolElement_getPresentationAttribute_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGTRefElement')
class TRefElement extends TextPositioningElement implements UriReference {
  TRefElement.internal() : super.internal();

  @DocsEditable
  factory TRefElement() => _SvgElementFactoryProvider.createSvgElement_tag("tref");

  @DocsEditable
  @DomName('SVGTRefElement.href')
  AnimatedString get href native "SVGTRefElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGTSpanElement')
class TSpanElement extends TextPositioningElement {
  TSpanElement.internal() : super.internal();

  @DocsEditable
  factory TSpanElement() => _SvgElementFactoryProvider.createSvgElement_tag("tspan");

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGTests')
class Tests extends NativeFieldWrapperClass1 {
  Tests.internal();

  @DocsEditable
  @DomName('SVGTests.requiredExtensions')
  StringList get requiredExtensions native "SVGTests_requiredExtensions_Getter";

  @DocsEditable
  @DomName('SVGTests.requiredFeatures')
  StringList get requiredFeatures native "SVGTests_requiredFeatures_Getter";

  @DocsEditable
  @DomName('SVGTests.systemLanguage')
  StringList get systemLanguage native "SVGTests_systemLanguage_Getter";

  @DocsEditable
  @DomName('SVGTests.hasExtension')
  bool hasExtension(String extension) native "SVGTests_hasExtension_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGTextContentElement')
class TextContentElement extends SvgElement implements Tests, Stylable, ExternalResourcesRequired, LangSpace {
  TextContentElement.internal() : super.internal();

  static const int LENGTHADJUST_SPACING = 1;

  static const int LENGTHADJUST_SPACINGANDGLYPHS = 2;

  static const int LENGTHADJUST_UNKNOWN = 0;

  @DocsEditable
  @DomName('SVGTextContentElement.lengthAdjust')
  AnimatedEnumeration get lengthAdjust native "SVGTextContentElement_lengthAdjust_Getter";

  @DocsEditable
  @DomName('SVGTextContentElement.textLength')
  AnimatedLength get textLength native "SVGTextContentElement_textLength_Getter";

  @DocsEditable
  @DomName('SVGTextContentElement.getCharNumAtPosition')
  int getCharNumAtPosition(Point point) native "SVGTextContentElement_getCharNumAtPosition_Callback";

  @DocsEditable
  @DomName('SVGTextContentElement.getComputedTextLength')
  num getComputedTextLength() native "SVGTextContentElement_getComputedTextLength_Callback";

  @DocsEditable
  @DomName('SVGTextContentElement.getEndPositionOfChar')
  Point getEndPositionOfChar(int offset) native "SVGTextContentElement_getEndPositionOfChar_Callback";

  @DocsEditable
  @DomName('SVGTextContentElement.getExtentOfChar')
  Rect getExtentOfChar(int offset) native "SVGTextContentElement_getExtentOfChar_Callback";

  @DocsEditable
  @DomName('SVGTextContentElement.getNumberOfChars')
  int getNumberOfChars() native "SVGTextContentElement_getNumberOfChars_Callback";

  @DocsEditable
  @DomName('SVGTextContentElement.getRotationOfChar')
  num getRotationOfChar(int offset) native "SVGTextContentElement_getRotationOfChar_Callback";

  @DocsEditable
  @DomName('SVGTextContentElement.getStartPositionOfChar')
  Point getStartPositionOfChar(int offset) native "SVGTextContentElement_getStartPositionOfChar_Callback";

  @DocsEditable
  @DomName('SVGTextContentElement.getSubStringLength')
  num getSubStringLength(int offset, int length) native "SVGTextContentElement_getSubStringLength_Callback";

  @DocsEditable
  @DomName('SVGTextContentElement.selectSubString')
  void selectSubString(int offset, int length) native "SVGTextContentElement_selectSubString_Callback";

  @DocsEditable
  @DomName('SVGTextContentElement.externalResourcesRequired')
  AnimatedBoolean get externalResourcesRequired native "SVGTextContentElement_externalResourcesRequired_Getter";

  @DocsEditable
  @DomName('SVGTextContentElement.xmllang')
  String get xmllang native "SVGTextContentElement_xmllang_Getter";

  @DocsEditable
  @DomName('SVGTextContentElement.xmllang')
  void set xmllang(String value) native "SVGTextContentElement_xmllang_Setter";

  @DocsEditable
  @DomName('SVGTextContentElement.xmlspace')
  String get xmlspace native "SVGTextContentElement_xmlspace_Getter";

  @DocsEditable
  @DomName('SVGTextContentElement.xmlspace')
  void set xmlspace(String value) native "SVGTextContentElement_xmlspace_Setter";

  @DocsEditable
  @DomName('SVGTextContentElement.className')
  AnimatedString get $dom_svgClassName native "SVGTextContentElement_className_Getter";

  @DocsEditable
  @DomName('SVGTextContentElement.style')
  CssStyleDeclaration get style native "SVGTextContentElement_style_Getter";

  @DocsEditable
  @DomName('SVGTextContentElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native "SVGTextContentElement_getPresentationAttribute_Callback";

  @DocsEditable
  @DomName('SVGTextContentElement.requiredExtensions')
  StringList get requiredExtensions native "SVGTextContentElement_requiredExtensions_Getter";

  @DocsEditable
  @DomName('SVGTextContentElement.requiredFeatures')
  StringList get requiredFeatures native "SVGTextContentElement_requiredFeatures_Getter";

  @DocsEditable
  @DomName('SVGTextContentElement.systemLanguage')
  StringList get systemLanguage native "SVGTextContentElement_systemLanguage_Getter";

  @DocsEditable
  @DomName('SVGTextContentElement.hasExtension')
  bool hasExtension(String extension) native "SVGTextContentElement_hasExtension_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGTextElement')
class TextElement extends TextPositioningElement implements Transformable {
  TextElement.internal() : super.internal();

  @DocsEditable
  factory TextElement() => _SvgElementFactoryProvider.createSvgElement_tag("text");

  @DocsEditable
  @DomName('SVGTextElement.farthestViewportElement')
  SvgElement get farthestViewportElement native "SVGTextElement_farthestViewportElement_Getter";

  @DocsEditable
  @DomName('SVGTextElement.nearestViewportElement')
  SvgElement get nearestViewportElement native "SVGTextElement_nearestViewportElement_Getter";

  @DocsEditable
  @DomName('SVGTextElement.getBBox')
  Rect getBBox() native "SVGTextElement_getBBox_Callback";

  @DocsEditable
  @DomName('SVGTextElement.getCTM')
  Matrix getCtm() native "SVGTextElement_getCTM_Callback";

  @DocsEditable
  @DomName('SVGTextElement.getScreenCTM')
  Matrix getScreenCtm() native "SVGTextElement_getScreenCTM_Callback";

  @DocsEditable
  @DomName('SVGTextElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native "SVGTextElement_getTransformToElement_Callback";

  @DocsEditable
  @DomName('SVGTextElement.transform')
  AnimatedTransformList get transform native "SVGTextElement_transform_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGTextPathElement')
class TextPathElement extends TextContentElement implements UriReference {
  TextPathElement.internal() : super.internal();

  static const int TEXTPATH_METHODTYPE_ALIGN = 1;

  static const int TEXTPATH_METHODTYPE_STRETCH = 2;

  static const int TEXTPATH_METHODTYPE_UNKNOWN = 0;

  static const int TEXTPATH_SPACINGTYPE_AUTO = 1;

  static const int TEXTPATH_SPACINGTYPE_EXACT = 2;

  static const int TEXTPATH_SPACINGTYPE_UNKNOWN = 0;

  @DocsEditable
  @DomName('SVGTextPathElement.method')
  AnimatedEnumeration get method native "SVGTextPathElement_method_Getter";

  @DocsEditable
  @DomName('SVGTextPathElement.spacing')
  AnimatedEnumeration get spacing native "SVGTextPathElement_spacing_Getter";

  @DocsEditable
  @DomName('SVGTextPathElement.startOffset')
  AnimatedLength get startOffset native "SVGTextPathElement_startOffset_Getter";

  @DocsEditable
  @DomName('SVGTextPathElement.href')
  AnimatedString get href native "SVGTextPathElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGTextPositioningElement')
class TextPositioningElement extends TextContentElement {
  TextPositioningElement.internal() : super.internal();

  @DocsEditable
  @DomName('SVGTextPositioningElement.dx')
  AnimatedLengthList get dx native "SVGTextPositioningElement_dx_Getter";

  @DocsEditable
  @DomName('SVGTextPositioningElement.dy')
  AnimatedLengthList get dy native "SVGTextPositioningElement_dy_Getter";

  @DocsEditable
  @DomName('SVGTextPositioningElement.rotate')
  AnimatedNumberList get rotate native "SVGTextPositioningElement_rotate_Getter";

  @DocsEditable
  @DomName('SVGTextPositioningElement.x')
  AnimatedLengthList get x native "SVGTextPositioningElement_x_Getter";

  @DocsEditable
  @DomName('SVGTextPositioningElement.y')
  AnimatedLengthList get y native "SVGTextPositioningElement_y_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGTitleElement')
class TitleElement extends SvgElement implements Stylable, LangSpace {
  TitleElement.internal() : super.internal();

  @DocsEditable
  factory TitleElement() => _SvgElementFactoryProvider.createSvgElement_tag("title");

  @DocsEditable
  @DomName('SVGTitleElement.xmllang')
  String get xmllang native "SVGTitleElement_xmllang_Getter";

  @DocsEditable
  @DomName('SVGTitleElement.xmllang')
  void set xmllang(String value) native "SVGTitleElement_xmllang_Setter";

  @DocsEditable
  @DomName('SVGTitleElement.xmlspace')
  String get xmlspace native "SVGTitleElement_xmlspace_Getter";

  @DocsEditable
  @DomName('SVGTitleElement.xmlspace')
  void set xmlspace(String value) native "SVGTitleElement_xmlspace_Setter";

  @DocsEditable
  @DomName('SVGTitleElement.className')
  AnimatedString get $dom_svgClassName native "SVGTitleElement_className_Getter";

  @DocsEditable
  @DomName('SVGTitleElement.style')
  CssStyleDeclaration get style native "SVGTitleElement_style_Getter";

  @DocsEditable
  @DomName('SVGTitleElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native "SVGTitleElement_getPresentationAttribute_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGTransform')
class Transform extends NativeFieldWrapperClass1 {
  Transform.internal();

  static const int SVG_TRANSFORM_MATRIX = 1;

  static const int SVG_TRANSFORM_ROTATE = 4;

  static const int SVG_TRANSFORM_SCALE = 3;

  static const int SVG_TRANSFORM_SKEWX = 5;

  static const int SVG_TRANSFORM_SKEWY = 6;

  static const int SVG_TRANSFORM_TRANSLATE = 2;

  static const int SVG_TRANSFORM_UNKNOWN = 0;

  @DocsEditable
  @DomName('SVGTransform.angle')
  num get angle native "SVGTransform_angle_Getter";

  @DocsEditable
  @DomName('SVGTransform.matrix')
  Matrix get matrix native "SVGTransform_matrix_Getter";

  @DocsEditable
  @DomName('SVGTransform.type')
  int get type native "SVGTransform_type_Getter";

  @DocsEditable
  @DomName('SVGTransform.setMatrix')
  void setMatrix(Matrix matrix) native "SVGTransform_setMatrix_Callback";

  @DocsEditable
  @DomName('SVGTransform.setRotate')
  void setRotate(num angle, num cx, num cy) native "SVGTransform_setRotate_Callback";

  @DocsEditable
  @DomName('SVGTransform.setScale')
  void setScale(num sx, num sy) native "SVGTransform_setScale_Callback";

  @DocsEditable
  @DomName('SVGTransform.setSkewX')
  void setSkewX(num angle) native "SVGTransform_setSkewX_Callback";

  @DocsEditable
  @DomName('SVGTransform.setSkewY')
  void setSkewY(num angle) native "SVGTransform_setSkewY_Callback";

  @DocsEditable
  @DomName('SVGTransform.setTranslate')
  void setTranslate(num tx, num ty) native "SVGTransform_setTranslate_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGTransformList')
class TransformList extends NativeFieldWrapperClass1 implements List<Transform> {
  TransformList.internal();

  @DocsEditable
  @DomName('SVGTransformList.numberOfItems')
  int get numberOfItems native "SVGTransformList_numberOfItems_Getter";

  Transform operator[](int index) native "SVGTransformList_item_Callback";

  void operator[]=(int index, Transform value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Transform> mixins.
  // Transform is the element type.

  // From Iterable<Transform>:

  Iterator<Transform> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<Transform>(this);
  }

  // SVG Collections expose numberOfItems rather than length.
  int get length => numberOfItems;
  dynamic reduce(dynamic initialValue, dynamic combine(dynamic, Transform)) {
    return Collections.reduce(this, initialValue, combine);
  }

  bool contains(Transform element) => Collections.contains(this, element);

  void forEach(void f(Transform element)) => Collections.forEach(this, f);

  String join([String separator]) => Collections.joinList(this, separator);

  List mappedBy(f(Transform element)) => new MappedList<Transform, dynamic>(this, f);

  Iterable<Transform> where(bool f(Transform element)) => new WhereIterable<Transform>(this, f);

  bool every(bool f(Transform element)) => Collections.every(this, f);

  bool any(bool f(Transform element)) => Collections.any(this, f);

  List<Transform> toList() => new List<Transform>.from(this);
  Set<Transform> toSet() => new Set<Transform>.from(this);

  bool get isEmpty => this.length == 0;

  List<Transform> take(int n) => new ListView<Transform>(this, 0, n);

  Iterable<Transform> takeWhile(bool test(Transform value)) {
    return new TakeWhileIterable<Transform>(this, test);
  }

  List<Transform> skip(int n) => new ListView<Transform>(this, n, null);

  Iterable<Transform> skipWhile(bool test(Transform value)) {
    return new SkipWhileIterable<Transform>(this, test);
  }

  Transform firstMatching(bool test(Transform value), { Transform orElse() }) {
    return Collections.firstMatching(this, test, orElse);
  }

  Transform lastMatching(bool test(Transform value), {Transform orElse()}) {
    return Collections.lastMatchingInList(this, test, orElse);
  }

  Transform singleMatching(bool test(Transform value)) {
    return Collections.singleMatching(this, test);
  }

  Transform elementAt(int index) {
    return this[index];
  }

  // From Collection<Transform>:

  void add(Transform value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(Transform value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<Transform> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<Transform>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  // contains() defined by IDL.

  void sort([int compare(Transform a, Transform b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(Transform element, [int start = 0]) =>
      Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(Transform element, [int start]) {
    if (start == null) start = length - 1;
    return Lists.lastIndexOf(this, element, start);
  }

  Transform get first {
    if (this.length > 0) return this[0];
    throw new StateError("No elements");
  }

  Transform get last {
    if (this.length > 0) return this[this.length - 1];
    throw new StateError("No elements");
  }

  Transform get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  Transform min([int compare(Transform a, Transform b)]) => Collections.min(this, compare);

  Transform max([int compare(Transform a, Transform b)]) => Collections.max(this, compare);

  Transform removeAt(int pos) {
    throw new UnsupportedError("Cannot removeAt on immutable List.");
  }

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
      Lists.getRange(this, start, rangeLength, <Transform>[]);

  // -- end List<Transform> mixins.

  @DocsEditable
  @DomName('SVGTransformList.appendItem')
  Transform appendItem(Transform item) native "SVGTransformList_appendItem_Callback";

  @DocsEditable
  @DomName('SVGTransformList.clear')
  void clear() native "SVGTransformList_clear_Callback";

  @DocsEditable
  @DomName('SVGTransformList.consolidate')
  Transform consolidate() native "SVGTransformList_consolidate_Callback";

  @DocsEditable
  @DomName('SVGTransformList.createSVGTransformFromMatrix')
  Transform createSvgTransformFromMatrix(Matrix matrix) native "SVGTransformList_createSVGTransformFromMatrix_Callback";

  @DocsEditable
  @DomName('SVGTransformList.getItem')
  Transform getItem(int index) native "SVGTransformList_getItem_Callback";

  @DocsEditable
  @DomName('SVGTransformList.initialize')
  Transform initialize(Transform item) native "SVGTransformList_initialize_Callback";

  @DocsEditable
  @DomName('SVGTransformList.insertItemBefore')
  Transform insertItemBefore(Transform item, int index) native "SVGTransformList_insertItemBefore_Callback";

  @DocsEditable
  @DomName('SVGTransformList.removeItem')
  Transform removeItem(int index) native "SVGTransformList_removeItem_Callback";

  @DocsEditable
  @DomName('SVGTransformList.replaceItem')
  Transform replaceItem(Transform item, int index) native "SVGTransformList_replaceItem_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGTransformable')
class Transformable extends NativeFieldWrapperClass1 implements Locatable {
  Transformable.internal();

  @DocsEditable
  @DomName('SVGTransformable.transform')
  AnimatedTransformList get transform native "SVGTransformable_transform_Getter";

  @DocsEditable
  @DomName('SVGTransformable.farthestViewportElement')
  SvgElement get farthestViewportElement native "SVGTransformable_farthestViewportElement_Getter";

  @DocsEditable
  @DomName('SVGTransformable.nearestViewportElement')
  SvgElement get nearestViewportElement native "SVGTransformable_nearestViewportElement_Getter";

  @DocsEditable
  @DomName('SVGTransformable.getBBox')
  Rect getBBox() native "SVGTransformable_getBBox_Callback";

  @DocsEditable
  @DomName('SVGTransformable.getCTM')
  Matrix getCtm() native "SVGTransformable_getCTM_Callback";

  @DocsEditable
  @DomName('SVGTransformable.getScreenCTM')
  Matrix getScreenCtm() native "SVGTransformable_getScreenCTM_Callback";

  @DocsEditable
  @DomName('SVGTransformable.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native "SVGTransformable_getTransformToElement_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGUnitTypes')
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


@DocsEditable
@DomName('SVGURIReference')
class UriReference extends NativeFieldWrapperClass1 {
  UriReference.internal();

  @DocsEditable
  @DomName('SVGURIReference.href')
  AnimatedString get href native "SVGURIReference_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGUseElement')
class UseElement extends SvgElement implements Transformable, Tests, UriReference, Stylable, ExternalResourcesRequired, LangSpace {
  UseElement.internal() : super.internal();

  @DocsEditable
  factory UseElement() => _SvgElementFactoryProvider.createSvgElement_tag("use");

  @DocsEditable
  @DomName('SVGUseElement.animatedInstanceRoot')
  ElementInstance get animatedInstanceRoot native "SVGUseElement_animatedInstanceRoot_Getter";

  @DocsEditable
  @DomName('SVGUseElement.height')
  AnimatedLength get height native "SVGUseElement_height_Getter";

  @DocsEditable
  @DomName('SVGUseElement.instanceRoot')
  ElementInstance get instanceRoot native "SVGUseElement_instanceRoot_Getter";

  @DocsEditable
  @DomName('SVGUseElement.width')
  AnimatedLength get width native "SVGUseElement_width_Getter";

  @DocsEditable
  @DomName('SVGUseElement.x')
  AnimatedLength get x native "SVGUseElement_x_Getter";

  @DocsEditable
  @DomName('SVGUseElement.y')
  AnimatedLength get y native "SVGUseElement_y_Getter";

  @DocsEditable
  @DomName('SVGUseElement.externalResourcesRequired')
  AnimatedBoolean get externalResourcesRequired native "SVGUseElement_externalResourcesRequired_Getter";

  @DocsEditable
  @DomName('SVGUseElement.xmllang')
  String get xmllang native "SVGUseElement_xmllang_Getter";

  @DocsEditable
  @DomName('SVGUseElement.xmllang')
  void set xmllang(String value) native "SVGUseElement_xmllang_Setter";

  @DocsEditable
  @DomName('SVGUseElement.xmlspace')
  String get xmlspace native "SVGUseElement_xmlspace_Getter";

  @DocsEditable
  @DomName('SVGUseElement.xmlspace')
  void set xmlspace(String value) native "SVGUseElement_xmlspace_Setter";

  @DocsEditable
  @DomName('SVGUseElement.farthestViewportElement')
  SvgElement get farthestViewportElement native "SVGUseElement_farthestViewportElement_Getter";

  @DocsEditable
  @DomName('SVGUseElement.nearestViewportElement')
  SvgElement get nearestViewportElement native "SVGUseElement_nearestViewportElement_Getter";

  @DocsEditable
  @DomName('SVGUseElement.getBBox')
  Rect getBBox() native "SVGUseElement_getBBox_Callback";

  @DocsEditable
  @DomName('SVGUseElement.getCTM')
  Matrix getCtm() native "SVGUseElement_getCTM_Callback";

  @DocsEditable
  @DomName('SVGUseElement.getScreenCTM')
  Matrix getScreenCtm() native "SVGUseElement_getScreenCTM_Callback";

  @DocsEditable
  @DomName('SVGUseElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native "SVGUseElement_getTransformToElement_Callback";

  @DocsEditable
  @DomName('SVGUseElement.className')
  AnimatedString get $dom_svgClassName native "SVGUseElement_className_Getter";

  @DocsEditable
  @DomName('SVGUseElement.style')
  CssStyleDeclaration get style native "SVGUseElement_style_Getter";

  @DocsEditable
  @DomName('SVGUseElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native "SVGUseElement_getPresentationAttribute_Callback";

  @DocsEditable
  @DomName('SVGUseElement.requiredExtensions')
  StringList get requiredExtensions native "SVGUseElement_requiredExtensions_Getter";

  @DocsEditable
  @DomName('SVGUseElement.requiredFeatures')
  StringList get requiredFeatures native "SVGUseElement_requiredFeatures_Getter";

  @DocsEditable
  @DomName('SVGUseElement.systemLanguage')
  StringList get systemLanguage native "SVGUseElement_systemLanguage_Getter";

  @DocsEditable
  @DomName('SVGUseElement.hasExtension')
  bool hasExtension(String extension) native "SVGUseElement_hasExtension_Callback";

  @DocsEditable
  @DomName('SVGUseElement.transform')
  AnimatedTransformList get transform native "SVGUseElement_transform_Getter";

  @DocsEditable
  @DomName('SVGUseElement.href')
  AnimatedString get href native "SVGUseElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGVKernElement')
class VKernElement extends SvgElement {
  VKernElement.internal() : super.internal();

  @DocsEditable
  factory VKernElement() => _SvgElementFactoryProvider.createSvgElement_tag("vkern");

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGViewElement')
class ViewElement extends SvgElement implements FitToViewBox, ExternalResourcesRequired, ZoomAndPan {
  ViewElement.internal() : super.internal();

  @DocsEditable
  factory ViewElement() => _SvgElementFactoryProvider.createSvgElement_tag("view");

  @DocsEditable
  @DomName('SVGViewElement.viewTarget')
  StringList get viewTarget native "SVGViewElement_viewTarget_Getter";

  @DocsEditable
  @DomName('SVGViewElement.externalResourcesRequired')
  AnimatedBoolean get externalResourcesRequired native "SVGViewElement_externalResourcesRequired_Getter";

  @DocsEditable
  @DomName('SVGViewElement.preserveAspectRatio')
  AnimatedPreserveAspectRatio get preserveAspectRatio native "SVGViewElement_preserveAspectRatio_Getter";

  @DocsEditable
  @DomName('SVGViewElement.viewBox')
  AnimatedRect get viewBox native "SVGViewElement_viewBox_Getter";

  @DocsEditable
  @DomName('SVGViewElement.zoomAndPan')
  int get zoomAndPan native "SVGViewElement_zoomAndPan_Getter";

  @DocsEditable
  @DomName('SVGViewElement.zoomAndPan')
  void set zoomAndPan(int value) native "SVGViewElement_zoomAndPan_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGViewSpec')
class ViewSpec extends NativeFieldWrapperClass1 {
  ViewSpec.internal();

  @DocsEditable
  @DomName('SVGViewSpec.preserveAspectRatio')
  AnimatedPreserveAspectRatio get preserveAspectRatio native "SVGViewSpec_preserveAspectRatio_Getter";

  @DocsEditable
  @DomName('SVGViewSpec.preserveAspectRatioString')
  String get preserveAspectRatioString native "SVGViewSpec_preserveAspectRatioString_Getter";

  @DocsEditable
  @DomName('SVGViewSpec.transform')
  TransformList get transform native "SVGViewSpec_transform_Getter";

  @DocsEditable
  @DomName('SVGViewSpec.transformString')
  String get transformString native "SVGViewSpec_transformString_Getter";

  @DocsEditable
  @DomName('SVGViewSpec.viewBox')
  AnimatedRect get viewBox native "SVGViewSpec_viewBox_Getter";

  @DocsEditable
  @DomName('SVGViewSpec.viewBoxString')
  String get viewBoxString native "SVGViewSpec_viewBoxString_Getter";

  @DocsEditable
  @DomName('SVGViewSpec.viewTarget')
  SvgElement get viewTarget native "SVGViewSpec_viewTarget_Getter";

  @DocsEditable
  @DomName('SVGViewSpec.viewTargetString')
  String get viewTargetString native "SVGViewSpec_viewTargetString_Getter";

  @DocsEditable
  @DomName('SVGViewSpec.zoomAndPan')
  int get zoomAndPan native "SVGViewSpec_zoomAndPan_Getter";

  @DocsEditable
  @DomName('SVGViewSpec.zoomAndPan')
  void set zoomAndPan(int value) native "SVGViewSpec_zoomAndPan_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGZoomAndPan')
class ZoomAndPan extends NativeFieldWrapperClass1 {
  ZoomAndPan.internal();

  static const int SVG_ZOOMANDPAN_DISABLE = 1;

  static const int SVG_ZOOMANDPAN_MAGNIFY = 2;

  static const int SVG_ZOOMANDPAN_UNKNOWN = 0;

  @DocsEditable
  @DomName('SVGZoomAndPan.zoomAndPan')
  int get zoomAndPan native "SVGZoomAndPan_zoomAndPan_Getter";

  @DocsEditable
  @DomName('SVGZoomAndPan.zoomAndPan')
  void set zoomAndPan(int value) native "SVGZoomAndPan_zoomAndPan_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGZoomEvent')
class ZoomEvent extends UIEvent {
  ZoomEvent.internal() : super.internal();

  @DocsEditable
  @DomName('SVGZoomEvent.newScale')
  num get newScale native "SVGZoomEvent_newScale_Getter";

  @DocsEditable
  @DomName('SVGZoomEvent.newTranslate')
  Point get newTranslate native "SVGZoomEvent_newTranslate_Getter";

  @DocsEditable
  @DomName('SVGZoomEvent.previousScale')
  num get previousScale native "SVGZoomEvent_previousScale_Getter";

  @DocsEditable
  @DomName('SVGZoomEvent.previousTranslate')
  Point get previousTranslate native "SVGZoomEvent_previousTranslate_Getter";

  @DocsEditable
  @DomName('SVGZoomEvent.zoomRectScreen')
  Rect get zoomRectScreen native "SVGZoomEvent_zoomRectScreen_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGElementInstanceList')
class _ElementInstanceList extends NativeFieldWrapperClass1 implements List<ElementInstance> {
  _ElementInstanceList.internal();

  @DocsEditable
  @DomName('SVGElementInstanceList.length')
  int get length native "SVGElementInstanceList_length_Getter";

  ElementInstance operator[](int index) native "SVGElementInstanceList_item_Callback";

  void operator[]=(int index, ElementInstance value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<ElementInstance> mixins.
  // ElementInstance is the element type.

  // From Iterable<ElementInstance>:

  Iterator<ElementInstance> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<ElementInstance>(this);
  }

  dynamic reduce(dynamic initialValue, dynamic combine(dynamic, ElementInstance)) {
    return Collections.reduce(this, initialValue, combine);
  }

  bool contains(ElementInstance element) => Collections.contains(this, element);

  void forEach(void f(ElementInstance element)) => Collections.forEach(this, f);

  String join([String separator]) => Collections.joinList(this, separator);

  List mappedBy(f(ElementInstance element)) => new MappedList<ElementInstance, dynamic>(this, f);

  Iterable<ElementInstance> where(bool f(ElementInstance element)) => new WhereIterable<ElementInstance>(this, f);

  bool every(bool f(ElementInstance element)) => Collections.every(this, f);

  bool any(bool f(ElementInstance element)) => Collections.any(this, f);

  List<ElementInstance> toList() => new List<ElementInstance>.from(this);
  Set<ElementInstance> toSet() => new Set<ElementInstance>.from(this);

  bool get isEmpty => this.length == 0;

  List<ElementInstance> take(int n) => new ListView<ElementInstance>(this, 0, n);

  Iterable<ElementInstance> takeWhile(bool test(ElementInstance value)) {
    return new TakeWhileIterable<ElementInstance>(this, test);
  }

  List<ElementInstance> skip(int n) => new ListView<ElementInstance>(this, n, null);

  Iterable<ElementInstance> skipWhile(bool test(ElementInstance value)) {
    return new SkipWhileIterable<ElementInstance>(this, test);
  }

  ElementInstance firstMatching(bool test(ElementInstance value), { ElementInstance orElse() }) {
    return Collections.firstMatching(this, test, orElse);
  }

  ElementInstance lastMatching(bool test(ElementInstance value), {ElementInstance orElse()}) {
    return Collections.lastMatchingInList(this, test, orElse);
  }

  ElementInstance singleMatching(bool test(ElementInstance value)) {
    return Collections.singleMatching(this, test);
  }

  ElementInstance elementAt(int index) {
    return this[index];
  }

  // From Collection<ElementInstance>:

  void add(ElementInstance value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(ElementInstance value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<ElementInstance> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<ElementInstance>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  void clear() {
    throw new UnsupportedError("Cannot clear immutable List.");
  }

  void sort([int compare(ElementInstance a, ElementInstance b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(ElementInstance element, [int start = 0]) =>
      Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(ElementInstance element, [int start]) {
    if (start == null) start = length - 1;
    return Lists.lastIndexOf(this, element, start);
  }

  ElementInstance get first {
    if (this.length > 0) return this[0];
    throw new StateError("No elements");
  }

  ElementInstance get last {
    if (this.length > 0) return this[this.length - 1];
    throw new StateError("No elements");
  }

  ElementInstance get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  ElementInstance min([int compare(ElementInstance a, ElementInstance b)]) => Collections.min(this, compare);

  ElementInstance max([int compare(ElementInstance a, ElementInstance b)]) => Collections.max(this, compare);

  ElementInstance removeAt(int pos) {
    throw new UnsupportedError("Cannot removeAt on immutable List.");
  }

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
      Lists.getRange(this, start, rangeLength, <ElementInstance>[]);

  // -- end List<ElementInstance> mixins.

  @DocsEditable
  @DomName('SVGElementInstanceList.item')
  ElementInstance item(int index) native "SVGElementInstanceList_item_Callback";

}
