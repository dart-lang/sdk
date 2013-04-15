library dart.dom.svg;

import 'dart:async';
import 'dart:collection';
import 'dart:_collection-dev';
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
class AElement extends StyledElement implements UriReference, Tests, Transformable, ExternalResourcesRequired, LangSpace {
  AElement.internal() : super.internal();

  @DomName('SVGAElement.SVGAElement')
  @DocsEditable
  factory AElement() => _SvgElementFactoryProvider.createSvgElement_tag("a");

  @DomName('SVGAElement.target')
  @DocsEditable
  AnimatedString get target native "SVGAElement_target_Getter";

  @DomName('SVGAElement.externalResourcesRequired')
  @DocsEditable
  AnimatedBoolean get externalResourcesRequired native "SVGAElement_externalResourcesRequired_Getter";

  @DomName('SVGAElement.xmllang')
  @DocsEditable
  String get xmllang native "SVGAElement_xmllang_Getter";

  @DomName('SVGAElement.xmllang')
  @DocsEditable
  void set xmllang(String value) native "SVGAElement_xmllang_Setter";

  @DomName('SVGAElement.xmlspace')
  @DocsEditable
  String get xmlspace native "SVGAElement_xmlspace_Getter";

  @DomName('SVGAElement.xmlspace')
  @DocsEditable
  void set xmlspace(String value) native "SVGAElement_xmlspace_Setter";

  @DomName('SVGAElement.farthestViewportElement')
  @DocsEditable
  SvgElement get farthestViewportElement native "SVGAElement_farthestViewportElement_Getter";

  @DomName('SVGAElement.nearestViewportElement')
  @DocsEditable
  SvgElement get nearestViewportElement native "SVGAElement_nearestViewportElement_Getter";

  @DomName('SVGAElement.getBBox')
  @DocsEditable
  Rect getBBox() native "SVGAElement_getBBox_Callback";

  @DomName('SVGAElement.getCTM')
  @DocsEditable
  Matrix getCtm() native "SVGAElement_getCTM_Callback";

  @DomName('SVGAElement.getScreenCTM')
  @DocsEditable
  Matrix getScreenCtm() native "SVGAElement_getScreenCTM_Callback";

  @DomName('SVGAElement.getTransformToElement')
  @DocsEditable
  Matrix getTransformToElement(SvgElement element) native "SVGAElement_getTransformToElement_Callback";

  @DomName('SVGAElement.requiredExtensions')
  @DocsEditable
  StringList get requiredExtensions native "SVGAElement_requiredExtensions_Getter";

  @DomName('SVGAElement.requiredFeatures')
  @DocsEditable
  StringList get requiredFeatures native "SVGAElement_requiredFeatures_Getter";

  @DomName('SVGAElement.systemLanguage')
  @DocsEditable
  StringList get systemLanguage native "SVGAElement_systemLanguage_Getter";

  @DomName('SVGAElement.hasExtension')
  @DocsEditable
  bool hasExtension(String extension) native "SVGAElement_hasExtension_Callback";

  @DomName('SVGAElement.transform')
  @DocsEditable
  AnimatedTransformList get transform native "SVGAElement_transform_Getter";

  @DomName('SVGAElement.href')
  @DocsEditable
  AnimatedString get href native "SVGAElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGAltGlyphElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.SAFARI)
class AltGlyphElement extends TextPositioningElement implements UriReference {
  AltGlyphElement.internal() : super.internal();

  @DomName('SVGAltGlyphElement.SVGAltGlyphElement')
  @DocsEditable
  factory AltGlyphElement() => _SvgElementFactoryProvider.createSvgElement_tag("altGlyph");

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGAltGlyphElement.format')
  @DocsEditable
  String get format native "SVGAltGlyphElement_format_Getter";

  @DomName('SVGAltGlyphElement.format')
  @DocsEditable
  void set format(String value) native "SVGAltGlyphElement_format_Setter";

  @DomName('SVGAltGlyphElement.glyphRef')
  @DocsEditable
  String get glyphRef native "SVGAltGlyphElement_glyphRef_Getter";

  @DomName('SVGAltGlyphElement.glyphRef')
  @DocsEditable
  void set glyphRef(String value) native "SVGAltGlyphElement_glyphRef_Setter";

  @DomName('SVGAltGlyphElement.href')
  @DocsEditable
  AnimatedString get href native "SVGAltGlyphElement_href_Getter";

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

  @DomName('SVGAngle.unitType')
  @DocsEditable
  int get unitType native "SVGAngle_unitType_Getter";

  @DomName('SVGAngle.value')
  @DocsEditable
  num get value native "SVGAngle_value_Getter";

  @DomName('SVGAngle.value')
  @DocsEditable
  void set value(num value) native "SVGAngle_value_Setter";

  @DomName('SVGAngle.valueAsString')
  @DocsEditable
  String get valueAsString native "SVGAngle_valueAsString_Getter";

  @DomName('SVGAngle.valueAsString')
  @DocsEditable
  void set valueAsString(String value) native "SVGAngle_valueAsString_Setter";

  @DomName('SVGAngle.valueInSpecifiedUnits')
  @DocsEditable
  num get valueInSpecifiedUnits native "SVGAngle_valueInSpecifiedUnits_Getter";

  @DomName('SVGAngle.valueInSpecifiedUnits')
  @DocsEditable
  void set valueInSpecifiedUnits(num value) native "SVGAngle_valueInSpecifiedUnits_Setter";

  @DomName('SVGAngle.convertToSpecifiedUnits')
  @DocsEditable
  void convertToSpecifiedUnits(int unitType) native "SVGAngle_convertToSpecifiedUnits_Callback";

  @DomName('SVGAngle.newValueSpecifiedUnits')
  @DocsEditable
  void newValueSpecifiedUnits(int unitType, num valueInSpecifiedUnits) native "SVGAngle_newValueSpecifiedUnits_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGAnimateElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.SAFARI)
class AnimateElement extends AnimationElement {
  AnimateElement.internal() : super.internal();

  @DomName('SVGAnimateElement.SVGAnimateElement')
  @DocsEditable
  factory AnimateElement() => _SvgElementFactoryProvider.createSvgElement_tag("animate");

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGAnimateMotionElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.SAFARI)
class AnimateMotionElement extends AnimationElement {
  AnimateMotionElement.internal() : super.internal();

  @DomName('SVGAnimateMotionElement.SVGAnimateMotionElement')
  @DocsEditable
  factory AnimateMotionElement() => _SvgElementFactoryProvider.createSvgElement_tag("animateMotion");

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGAnimateTransformElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.SAFARI)
class AnimateTransformElement extends AnimationElement {
  AnimateTransformElement.internal() : super.internal();

  @DomName('SVGAnimateTransformElement.SVGAnimateTransformElement')
  @DocsEditable
  factory AnimateTransformElement() => _SvgElementFactoryProvider.createSvgElement_tag("animateTransform");

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGAnimatedAngle')
class AnimatedAngle extends NativeFieldWrapperClass1 {
  AnimatedAngle.internal();

  @DomName('SVGAnimatedAngle.animVal')
  @DocsEditable
  Angle get animVal native "SVGAnimatedAngle_animVal_Getter";

  @DomName('SVGAnimatedAngle.baseVal')
  @DocsEditable
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

  @DomName('SVGAnimatedBoolean.animVal')
  @DocsEditable
  bool get animVal native "SVGAnimatedBoolean_animVal_Getter";

  @DomName('SVGAnimatedBoolean.baseVal')
  @DocsEditable
  bool get baseVal native "SVGAnimatedBoolean_baseVal_Getter";

  @DomName('SVGAnimatedBoolean.baseVal')
  @DocsEditable
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

  @DomName('SVGAnimatedEnumeration.animVal')
  @DocsEditable
  int get animVal native "SVGAnimatedEnumeration_animVal_Getter";

  @DomName('SVGAnimatedEnumeration.baseVal')
  @DocsEditable
  int get baseVal native "SVGAnimatedEnumeration_baseVal_Getter";

  @DomName('SVGAnimatedEnumeration.baseVal')
  @DocsEditable
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

  @DomName('SVGAnimatedInteger.animVal')
  @DocsEditable
  int get animVal native "SVGAnimatedInteger_animVal_Getter";

  @DomName('SVGAnimatedInteger.baseVal')
  @DocsEditable
  int get baseVal native "SVGAnimatedInteger_baseVal_Getter";

  @DomName('SVGAnimatedInteger.baseVal')
  @DocsEditable
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

  @DomName('SVGAnimatedLength.animVal')
  @DocsEditable
  Length get animVal native "SVGAnimatedLength_animVal_Getter";

  @DomName('SVGAnimatedLength.baseVal')
  @DocsEditable
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

  @DomName('SVGAnimatedLengthList.animVal')
  @DocsEditable
  LengthList get animVal native "SVGAnimatedLengthList_animVal_Getter";

  @DomName('SVGAnimatedLengthList.baseVal')
  @DocsEditable
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

  @DomName('SVGAnimatedNumber.animVal')
  @DocsEditable
  num get animVal native "SVGAnimatedNumber_animVal_Getter";

  @DomName('SVGAnimatedNumber.baseVal')
  @DocsEditable
  num get baseVal native "SVGAnimatedNumber_baseVal_Getter";

  @DomName('SVGAnimatedNumber.baseVal')
  @DocsEditable
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

  @DomName('SVGAnimatedNumberList.animVal')
  @DocsEditable
  NumberList get animVal native "SVGAnimatedNumberList_animVal_Getter";

  @DomName('SVGAnimatedNumberList.baseVal')
  @DocsEditable
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

  @DomName('SVGAnimatedPreserveAspectRatio.animVal')
  @DocsEditable
  PreserveAspectRatio get animVal native "SVGAnimatedPreserveAspectRatio_animVal_Getter";

  @DomName('SVGAnimatedPreserveAspectRatio.baseVal')
  @DocsEditable
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

  @DomName('SVGAnimatedRect.animVal')
  @DocsEditable
  Rect get animVal native "SVGAnimatedRect_animVal_Getter";

  @DomName('SVGAnimatedRect.baseVal')
  @DocsEditable
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

  @DomName('SVGAnimatedString.animVal')
  @DocsEditable
  String get animVal native "SVGAnimatedString_animVal_Getter";

  @DomName('SVGAnimatedString.baseVal')
  @DocsEditable
  String get baseVal native "SVGAnimatedString_baseVal_Getter";

  @DomName('SVGAnimatedString.baseVal')
  @DocsEditable
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

  @DomName('SVGAnimatedTransformList.animVal')
  @DocsEditable
  TransformList get animVal native "SVGAnimatedTransformList_animVal_Getter";

  @DomName('SVGAnimatedTransformList.baseVal')
  @DocsEditable
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

  @DomName('SVGAnimationElement.SVGAnimationElement')
  @DocsEditable
  factory AnimationElement() => _SvgElementFactoryProvider.createSvgElement_tag("animation");

  @DomName('SVGAnimationElement.targetElement')
  @DocsEditable
  SvgElement get targetElement native "SVGAnimationElement_targetElement_Getter";

  @DomName('SVGAnimationElement.getCurrentTime')
  @DocsEditable
  num getCurrentTime() native "SVGAnimationElement_getCurrentTime_Callback";

  @DomName('SVGAnimationElement.getSimpleDuration')
  @DocsEditable
  num getSimpleDuration() native "SVGAnimationElement_getSimpleDuration_Callback";

  @DomName('SVGAnimationElement.getStartTime')
  @DocsEditable
  num getStartTime() native "SVGAnimationElement_getStartTime_Callback";

  @DomName('SVGAnimationElement.beginElement')
  @DocsEditable
  void beginElement() native "SVGAnimationElement_beginElement_Callback";

  @DomName('SVGAnimationElement.beginElementAt')
  @DocsEditable
  void beginElementAt(num offset) native "SVGAnimationElement_beginElementAt_Callback";

  @DomName('SVGAnimationElement.endElement')
  @DocsEditable
  void endElement() native "SVGAnimationElement_endElement_Callback";

  @DomName('SVGAnimationElement.endElementAt')
  @DocsEditable
  void endElementAt(num offset) native "SVGAnimationElement_endElementAt_Callback";

  @DomName('SVGAnimationElement.externalResourcesRequired')
  @DocsEditable
  AnimatedBoolean get externalResourcesRequired native "SVGAnimationElement_externalResourcesRequired_Getter";

  @DomName('SVGAnimationElement.requiredExtensions')
  @DocsEditable
  StringList get requiredExtensions native "SVGAnimationElement_requiredExtensions_Getter";

  @DomName('SVGAnimationElement.requiredFeatures')
  @DocsEditable
  StringList get requiredFeatures native "SVGAnimationElement_requiredFeatures_Getter";

  @DomName('SVGAnimationElement.systemLanguage')
  @DocsEditable
  StringList get systemLanguage native "SVGAnimationElement_systemLanguage_Getter";

  @DomName('SVGAnimationElement.hasExtension')
  @DocsEditable
  bool hasExtension(String extension) native "SVGAnimationElement_hasExtension_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGCircleElement')
class CircleElement extends StyledElement implements Transformable, Tests, ExternalResourcesRequired, LangSpace {
  CircleElement.internal() : super.internal();

  @DomName('SVGCircleElement.SVGCircleElement')
  @DocsEditable
  factory CircleElement() => _SvgElementFactoryProvider.createSvgElement_tag("circle");

  @DomName('SVGCircleElement.cx')
  @DocsEditable
  AnimatedLength get cx native "SVGCircleElement_cx_Getter";

  @DomName('SVGCircleElement.cy')
  @DocsEditable
  AnimatedLength get cy native "SVGCircleElement_cy_Getter";

  @DomName('SVGCircleElement.r')
  @DocsEditable
  AnimatedLength get r native "SVGCircleElement_r_Getter";

  @DomName('SVGCircleElement.externalResourcesRequired')
  @DocsEditable
  AnimatedBoolean get externalResourcesRequired native "SVGCircleElement_externalResourcesRequired_Getter";

  @DomName('SVGCircleElement.xmllang')
  @DocsEditable
  String get xmllang native "SVGCircleElement_xmllang_Getter";

  @DomName('SVGCircleElement.xmllang')
  @DocsEditable
  void set xmllang(String value) native "SVGCircleElement_xmllang_Setter";

  @DomName('SVGCircleElement.xmlspace')
  @DocsEditable
  String get xmlspace native "SVGCircleElement_xmlspace_Getter";

  @DomName('SVGCircleElement.xmlspace')
  @DocsEditable
  void set xmlspace(String value) native "SVGCircleElement_xmlspace_Setter";

  @DomName('SVGCircleElement.farthestViewportElement')
  @DocsEditable
  SvgElement get farthestViewportElement native "SVGCircleElement_farthestViewportElement_Getter";

  @DomName('SVGCircleElement.nearestViewportElement')
  @DocsEditable
  SvgElement get nearestViewportElement native "SVGCircleElement_nearestViewportElement_Getter";

  @DomName('SVGCircleElement.getBBox')
  @DocsEditable
  Rect getBBox() native "SVGCircleElement_getBBox_Callback";

  @DomName('SVGCircleElement.getCTM')
  @DocsEditable
  Matrix getCtm() native "SVGCircleElement_getCTM_Callback";

  @DomName('SVGCircleElement.getScreenCTM')
  @DocsEditable
  Matrix getScreenCtm() native "SVGCircleElement_getScreenCTM_Callback";

  @DomName('SVGCircleElement.getTransformToElement')
  @DocsEditable
  Matrix getTransformToElement(SvgElement element) native "SVGCircleElement_getTransformToElement_Callback";

  @DomName('SVGCircleElement.requiredExtensions')
  @DocsEditable
  StringList get requiredExtensions native "SVGCircleElement_requiredExtensions_Getter";

  @DomName('SVGCircleElement.requiredFeatures')
  @DocsEditable
  StringList get requiredFeatures native "SVGCircleElement_requiredFeatures_Getter";

  @DomName('SVGCircleElement.systemLanguage')
  @DocsEditable
  StringList get systemLanguage native "SVGCircleElement_systemLanguage_Getter";

  @DomName('SVGCircleElement.hasExtension')
  @DocsEditable
  bool hasExtension(String extension) native "SVGCircleElement_hasExtension_Callback";

  @DomName('SVGCircleElement.transform')
  @DocsEditable
  AnimatedTransformList get transform native "SVGCircleElement_transform_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGClipPathElement')
class ClipPathElement extends StyledElement implements Transformable, Tests, ExternalResourcesRequired, LangSpace {
  ClipPathElement.internal() : super.internal();

  @DomName('SVGClipPathElement.SVGClipPathElement')
  @DocsEditable
  factory ClipPathElement() => _SvgElementFactoryProvider.createSvgElement_tag("clipPath");

  @DomName('SVGClipPathElement.clipPathUnits')
  @DocsEditable
  AnimatedEnumeration get clipPathUnits native "SVGClipPathElement_clipPathUnits_Getter";

  @DomName('SVGClipPathElement.externalResourcesRequired')
  @DocsEditable
  AnimatedBoolean get externalResourcesRequired native "SVGClipPathElement_externalResourcesRequired_Getter";

  @DomName('SVGClipPathElement.xmllang')
  @DocsEditable
  String get xmllang native "SVGClipPathElement_xmllang_Getter";

  @DomName('SVGClipPathElement.xmllang')
  @DocsEditable
  void set xmllang(String value) native "SVGClipPathElement_xmllang_Setter";

  @DomName('SVGClipPathElement.xmlspace')
  @DocsEditable
  String get xmlspace native "SVGClipPathElement_xmlspace_Getter";

  @DomName('SVGClipPathElement.xmlspace')
  @DocsEditable
  void set xmlspace(String value) native "SVGClipPathElement_xmlspace_Setter";

  @DomName('SVGClipPathElement.farthestViewportElement')
  @DocsEditable
  SvgElement get farthestViewportElement native "SVGClipPathElement_farthestViewportElement_Getter";

  @DomName('SVGClipPathElement.nearestViewportElement')
  @DocsEditable
  SvgElement get nearestViewportElement native "SVGClipPathElement_nearestViewportElement_Getter";

  @DomName('SVGClipPathElement.getBBox')
  @DocsEditable
  Rect getBBox() native "SVGClipPathElement_getBBox_Callback";

  @DomName('SVGClipPathElement.getCTM')
  @DocsEditable
  Matrix getCtm() native "SVGClipPathElement_getCTM_Callback";

  @DomName('SVGClipPathElement.getScreenCTM')
  @DocsEditable
  Matrix getScreenCtm() native "SVGClipPathElement_getScreenCTM_Callback";

  @DomName('SVGClipPathElement.getTransformToElement')
  @DocsEditable
  Matrix getTransformToElement(SvgElement element) native "SVGClipPathElement_getTransformToElement_Callback";

  @DomName('SVGClipPathElement.requiredExtensions')
  @DocsEditable
  StringList get requiredExtensions native "SVGClipPathElement_requiredExtensions_Getter";

  @DomName('SVGClipPathElement.requiredFeatures')
  @DocsEditable
  StringList get requiredFeatures native "SVGClipPathElement_requiredFeatures_Getter";

  @DomName('SVGClipPathElement.systemLanguage')
  @DocsEditable
  StringList get systemLanguage native "SVGClipPathElement_systemLanguage_Getter";

  @DomName('SVGClipPathElement.hasExtension')
  @DocsEditable
  bool hasExtension(String extension) native "SVGClipPathElement_hasExtension_Callback";

  @DomName('SVGClipPathElement.transform')
  @DocsEditable
  AnimatedTransformList get transform native "SVGClipPathElement_transform_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGDefsElement')
class DefsElement extends StyledElement implements Transformable, Tests, ExternalResourcesRequired, LangSpace {
  DefsElement.internal() : super.internal();

  @DomName('SVGDefsElement.SVGDefsElement')
  @DocsEditable
  factory DefsElement() => _SvgElementFactoryProvider.createSvgElement_tag("defs");

  @DomName('SVGDefsElement.externalResourcesRequired')
  @DocsEditable
  AnimatedBoolean get externalResourcesRequired native "SVGDefsElement_externalResourcesRequired_Getter";

  @DomName('SVGDefsElement.xmllang')
  @DocsEditable
  String get xmllang native "SVGDefsElement_xmllang_Getter";

  @DomName('SVGDefsElement.xmllang')
  @DocsEditable
  void set xmllang(String value) native "SVGDefsElement_xmllang_Setter";

  @DomName('SVGDefsElement.xmlspace')
  @DocsEditable
  String get xmlspace native "SVGDefsElement_xmlspace_Getter";

  @DomName('SVGDefsElement.xmlspace')
  @DocsEditable
  void set xmlspace(String value) native "SVGDefsElement_xmlspace_Setter";

  @DomName('SVGDefsElement.farthestViewportElement')
  @DocsEditable
  SvgElement get farthestViewportElement native "SVGDefsElement_farthestViewportElement_Getter";

  @DomName('SVGDefsElement.nearestViewportElement')
  @DocsEditable
  SvgElement get nearestViewportElement native "SVGDefsElement_nearestViewportElement_Getter";

  @DomName('SVGDefsElement.getBBox')
  @DocsEditable
  Rect getBBox() native "SVGDefsElement_getBBox_Callback";

  @DomName('SVGDefsElement.getCTM')
  @DocsEditable
  Matrix getCtm() native "SVGDefsElement_getCTM_Callback";

  @DomName('SVGDefsElement.getScreenCTM')
  @DocsEditable
  Matrix getScreenCtm() native "SVGDefsElement_getScreenCTM_Callback";

  @DomName('SVGDefsElement.getTransformToElement')
  @DocsEditable
  Matrix getTransformToElement(SvgElement element) native "SVGDefsElement_getTransformToElement_Callback";

  @DomName('SVGDefsElement.requiredExtensions')
  @DocsEditable
  StringList get requiredExtensions native "SVGDefsElement_requiredExtensions_Getter";

  @DomName('SVGDefsElement.requiredFeatures')
  @DocsEditable
  StringList get requiredFeatures native "SVGDefsElement_requiredFeatures_Getter";

  @DomName('SVGDefsElement.systemLanguage')
  @DocsEditable
  StringList get systemLanguage native "SVGDefsElement_systemLanguage_Getter";

  @DomName('SVGDefsElement.hasExtension')
  @DocsEditable
  bool hasExtension(String extension) native "SVGDefsElement_hasExtension_Callback";

  @DomName('SVGDefsElement.transform')
  @DocsEditable
  AnimatedTransformList get transform native "SVGDefsElement_transform_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGDescElement')
class DescElement extends StyledElement implements LangSpace {
  DescElement.internal() : super.internal();

  @DomName('SVGDescElement.SVGDescElement')
  @DocsEditable
  factory DescElement() => _SvgElementFactoryProvider.createSvgElement_tag("desc");

  @DomName('SVGDescElement.xmllang')
  @DocsEditable
  String get xmllang native "SVGDescElement_xmllang_Getter";

  @DomName('SVGDescElement.xmllang')
  @DocsEditable
  void set xmllang(String value) native "SVGDescElement_xmllang_Setter";

  @DomName('SVGDescElement.xmlspace')
  @DocsEditable
  String get xmlspace native "SVGDescElement_xmlspace_Getter";

  @DomName('SVGDescElement.xmlspace')
  @DocsEditable
  void set xmlspace(String value) native "SVGDescElement_xmlspace_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGElementInstance')
class ElementInstance extends EventTarget {
  ElementInstance.internal() : super.internal();

  @DomName('SVGElementInstance.abortEvent')
  @DocsEditable
  static const EventStreamProvider<Event> abortEvent = const EventStreamProvider<Event>('abort');

  @DomName('SVGElementInstance.beforecopyEvent')
  @DocsEditable
  static const EventStreamProvider<Event> beforeCopyEvent = const EventStreamProvider<Event>('beforecopy');

  @DomName('SVGElementInstance.beforecutEvent')
  @DocsEditable
  static const EventStreamProvider<Event> beforeCutEvent = const EventStreamProvider<Event>('beforecut');

  @DomName('SVGElementInstance.beforepasteEvent')
  @DocsEditable
  static const EventStreamProvider<Event> beforePasteEvent = const EventStreamProvider<Event>('beforepaste');

  @DomName('SVGElementInstance.blurEvent')
  @DocsEditable
  static const EventStreamProvider<Event> blurEvent = const EventStreamProvider<Event>('blur');

  @DomName('SVGElementInstance.changeEvent')
  @DocsEditable
  static const EventStreamProvider<Event> changeEvent = const EventStreamProvider<Event>('change');

  @DomName('SVGElementInstance.clickEvent')
  @DocsEditable
  static const EventStreamProvider<MouseEvent> clickEvent = const EventStreamProvider<MouseEvent>('click');

  @DomName('SVGElementInstance.contextmenuEvent')
  @DocsEditable
  static const EventStreamProvider<MouseEvent> contextMenuEvent = const EventStreamProvider<MouseEvent>('contextmenu');

  @DomName('SVGElementInstance.copyEvent')
  @DocsEditable
  static const EventStreamProvider<Event> copyEvent = const EventStreamProvider<Event>('copy');

  @DomName('SVGElementInstance.cutEvent')
  @DocsEditable
  static const EventStreamProvider<Event> cutEvent = const EventStreamProvider<Event>('cut');

  @DomName('SVGElementInstance.dblclickEvent')
  @DocsEditable
  static const EventStreamProvider<Event> doubleClickEvent = const EventStreamProvider<Event>('dblclick');

  @DomName('SVGElementInstance.dragEvent')
  @DocsEditable
  static const EventStreamProvider<MouseEvent> dragEvent = const EventStreamProvider<MouseEvent>('drag');

  @DomName('SVGElementInstance.dragendEvent')
  @DocsEditable
  static const EventStreamProvider<MouseEvent> dragEndEvent = const EventStreamProvider<MouseEvent>('dragend');

  @DomName('SVGElementInstance.dragenterEvent')
  @DocsEditable
  static const EventStreamProvider<MouseEvent> dragEnterEvent = const EventStreamProvider<MouseEvent>('dragenter');

  @DomName('SVGElementInstance.dragleaveEvent')
  @DocsEditable
  static const EventStreamProvider<MouseEvent> dragLeaveEvent = const EventStreamProvider<MouseEvent>('dragleave');

  @DomName('SVGElementInstance.dragoverEvent')
  @DocsEditable
  static const EventStreamProvider<MouseEvent> dragOverEvent = const EventStreamProvider<MouseEvent>('dragover');

  @DomName('SVGElementInstance.dragstartEvent')
  @DocsEditable
  static const EventStreamProvider<MouseEvent> dragStartEvent = const EventStreamProvider<MouseEvent>('dragstart');

  @DomName('SVGElementInstance.dropEvent')
  @DocsEditable
  static const EventStreamProvider<MouseEvent> dropEvent = const EventStreamProvider<MouseEvent>('drop');

  @DomName('SVGElementInstance.errorEvent')
  @DocsEditable
  static const EventStreamProvider<Event> errorEvent = const EventStreamProvider<Event>('error');

  @DomName('SVGElementInstance.focusEvent')
  @DocsEditable
  static const EventStreamProvider<Event> focusEvent = const EventStreamProvider<Event>('focus');

  @DomName('SVGElementInstance.inputEvent')
  @DocsEditable
  static const EventStreamProvider<Event> inputEvent = const EventStreamProvider<Event>('input');

  @DomName('SVGElementInstance.keydownEvent')
  @DocsEditable
  static const EventStreamProvider<KeyboardEvent> keyDownEvent = const EventStreamProvider<KeyboardEvent>('keydown');

  @DomName('SVGElementInstance.keypressEvent')
  @DocsEditable
  static const EventStreamProvider<KeyboardEvent> keyPressEvent = const EventStreamProvider<KeyboardEvent>('keypress');

  @DomName('SVGElementInstance.keyupEvent')
  @DocsEditable
  static const EventStreamProvider<KeyboardEvent> keyUpEvent = const EventStreamProvider<KeyboardEvent>('keyup');

  @DomName('SVGElementInstance.loadEvent')
  @DocsEditable
  static const EventStreamProvider<Event> loadEvent = const EventStreamProvider<Event>('load');

  @DomName('SVGElementInstance.mousedownEvent')
  @DocsEditable
  static const EventStreamProvider<MouseEvent> mouseDownEvent = const EventStreamProvider<MouseEvent>('mousedown');

  @DomName('SVGElementInstance.mousemoveEvent')
  @DocsEditable
  static const EventStreamProvider<MouseEvent> mouseMoveEvent = const EventStreamProvider<MouseEvent>('mousemove');

  @DomName('SVGElementInstance.mouseoutEvent')
  @DocsEditable
  static const EventStreamProvider<MouseEvent> mouseOutEvent = const EventStreamProvider<MouseEvent>('mouseout');

  @DomName('SVGElementInstance.mouseoverEvent')
  @DocsEditable
  static const EventStreamProvider<MouseEvent> mouseOverEvent = const EventStreamProvider<MouseEvent>('mouseover');

  @DomName('SVGElementInstance.mouseupEvent')
  @DocsEditable
  static const EventStreamProvider<MouseEvent> mouseUpEvent = const EventStreamProvider<MouseEvent>('mouseup');

  @DomName('SVGElementInstance.mousewheelEvent')
  @DocsEditable
  static const EventStreamProvider<WheelEvent> mouseWheelEvent = const EventStreamProvider<WheelEvent>('mousewheel');

  @DomName('SVGElementInstance.pasteEvent')
  @DocsEditable
  static const EventStreamProvider<Event> pasteEvent = const EventStreamProvider<Event>('paste');

  @DomName('SVGElementInstance.resetEvent')
  @DocsEditable
  static const EventStreamProvider<Event> resetEvent = const EventStreamProvider<Event>('reset');

  @DomName('SVGElementInstance.resizeEvent')
  @DocsEditable
  static const EventStreamProvider<Event> resizeEvent = const EventStreamProvider<Event>('resize');

  @DomName('SVGElementInstance.scrollEvent')
  @DocsEditable
  static const EventStreamProvider<Event> scrollEvent = const EventStreamProvider<Event>('scroll');

  @DomName('SVGElementInstance.searchEvent')
  @DocsEditable
  static const EventStreamProvider<Event> searchEvent = const EventStreamProvider<Event>('search');

  @DomName('SVGElementInstance.selectEvent')
  @DocsEditable
  static const EventStreamProvider<Event> selectEvent = const EventStreamProvider<Event>('select');

  @DomName('SVGElementInstance.selectstartEvent')
  @DocsEditable
  static const EventStreamProvider<Event> selectStartEvent = const EventStreamProvider<Event>('selectstart');

  @DomName('SVGElementInstance.submitEvent')
  @DocsEditable
  static const EventStreamProvider<Event> submitEvent = const EventStreamProvider<Event>('submit');

  @DomName('SVGElementInstance.unloadEvent')
  @DocsEditable
  static const EventStreamProvider<Event> unloadEvent = const EventStreamProvider<Event>('unload');

  @DomName('SVGElementInstance.childNodes')
  @DocsEditable
  List<ElementInstance> get childNodes native "SVGElementInstance_childNodes_Getter";

  @DomName('SVGElementInstance.correspondingElement')
  @DocsEditable
  SvgElement get correspondingElement native "SVGElementInstance_correspondingElement_Getter";

  @DomName('SVGElementInstance.correspondingUseElement')
  @DocsEditable
  UseElement get correspondingUseElement native "SVGElementInstance_correspondingUseElement_Getter";

  @DomName('SVGElementInstance.firstChild')
  @DocsEditable
  ElementInstance get firstChild native "SVGElementInstance_firstChild_Getter";

  @DomName('SVGElementInstance.lastChild')
  @DocsEditable
  ElementInstance get lastChild native "SVGElementInstance_lastChild_Getter";

  @DomName('SVGElementInstance.nextSibling')
  @DocsEditable
  ElementInstance get nextSibling native "SVGElementInstance_nextSibling_Getter";

  @DomName('SVGElementInstance.parentNode')
  @DocsEditable
  ElementInstance get parentNode native "SVGElementInstance_parentNode_Getter";

  @DomName('SVGElementInstance.previousSibling')
  @DocsEditable
  ElementInstance get previousSibling native "SVGElementInstance_previousSibling_Getter";

  @DomName('SVGElementInstance.onabort')
  @DocsEditable
  Stream<Event> get onAbort => abortEvent.forTarget(this);

  @DomName('SVGElementInstance.onbeforecopy')
  @DocsEditable
  Stream<Event> get onBeforeCopy => beforeCopyEvent.forTarget(this);

  @DomName('SVGElementInstance.onbeforecut')
  @DocsEditable
  Stream<Event> get onBeforeCut => beforeCutEvent.forTarget(this);

  @DomName('SVGElementInstance.onbeforepaste')
  @DocsEditable
  Stream<Event> get onBeforePaste => beforePasteEvent.forTarget(this);

  @DomName('SVGElementInstance.onblur')
  @DocsEditable
  Stream<Event> get onBlur => blurEvent.forTarget(this);

  @DomName('SVGElementInstance.onchange')
  @DocsEditable
  Stream<Event> get onChange => changeEvent.forTarget(this);

  @DomName('SVGElementInstance.onclick')
  @DocsEditable
  Stream<MouseEvent> get onClick => clickEvent.forTarget(this);

  @DomName('SVGElementInstance.oncontextmenu')
  @DocsEditable
  Stream<MouseEvent> get onContextMenu => contextMenuEvent.forTarget(this);

  @DomName('SVGElementInstance.oncopy')
  @DocsEditable
  Stream<Event> get onCopy => copyEvent.forTarget(this);

  @DomName('SVGElementInstance.oncut')
  @DocsEditable
  Stream<Event> get onCut => cutEvent.forTarget(this);

  @DomName('SVGElementInstance.ondblclick')
  @DocsEditable
  Stream<Event> get onDoubleClick => doubleClickEvent.forTarget(this);

  @DomName('SVGElementInstance.ondrag')
  @DocsEditable
  Stream<MouseEvent> get onDrag => dragEvent.forTarget(this);

  @DomName('SVGElementInstance.ondragend')
  @DocsEditable
  Stream<MouseEvent> get onDragEnd => dragEndEvent.forTarget(this);

  @DomName('SVGElementInstance.ondragenter')
  @DocsEditable
  Stream<MouseEvent> get onDragEnter => dragEnterEvent.forTarget(this);

  @DomName('SVGElementInstance.ondragleave')
  @DocsEditable
  Stream<MouseEvent> get onDragLeave => dragLeaveEvent.forTarget(this);

  @DomName('SVGElementInstance.ondragover')
  @DocsEditable
  Stream<MouseEvent> get onDragOver => dragOverEvent.forTarget(this);

  @DomName('SVGElementInstance.ondragstart')
  @DocsEditable
  Stream<MouseEvent> get onDragStart => dragStartEvent.forTarget(this);

  @DomName('SVGElementInstance.ondrop')
  @DocsEditable
  Stream<MouseEvent> get onDrop => dropEvent.forTarget(this);

  @DomName('SVGElementInstance.onerror')
  @DocsEditable
  Stream<Event> get onError => errorEvent.forTarget(this);

  @DomName('SVGElementInstance.onfocus')
  @DocsEditable
  Stream<Event> get onFocus => focusEvent.forTarget(this);

  @DomName('SVGElementInstance.oninput')
  @DocsEditable
  Stream<Event> get onInput => inputEvent.forTarget(this);

  @DomName('SVGElementInstance.onkeydown')
  @DocsEditable
  Stream<KeyboardEvent> get onKeyDown => keyDownEvent.forTarget(this);

  @DomName('SVGElementInstance.onkeypress')
  @DocsEditable
  Stream<KeyboardEvent> get onKeyPress => keyPressEvent.forTarget(this);

  @DomName('SVGElementInstance.onkeyup')
  @DocsEditable
  Stream<KeyboardEvent> get onKeyUp => keyUpEvent.forTarget(this);

  @DomName('SVGElementInstance.onload')
  @DocsEditable
  Stream<Event> get onLoad => loadEvent.forTarget(this);

  @DomName('SVGElementInstance.onmousedown')
  @DocsEditable
  Stream<MouseEvent> get onMouseDown => mouseDownEvent.forTarget(this);

  @DomName('SVGElementInstance.onmousemove')
  @DocsEditable
  Stream<MouseEvent> get onMouseMove => mouseMoveEvent.forTarget(this);

  @DomName('SVGElementInstance.onmouseout')
  @DocsEditable
  Stream<MouseEvent> get onMouseOut => mouseOutEvent.forTarget(this);

  @DomName('SVGElementInstance.onmouseover')
  @DocsEditable
  Stream<MouseEvent> get onMouseOver => mouseOverEvent.forTarget(this);

  @DomName('SVGElementInstance.onmouseup')
  @DocsEditable
  Stream<MouseEvent> get onMouseUp => mouseUpEvent.forTarget(this);

  @DomName('SVGElementInstance.onmousewheel')
  @DocsEditable
  Stream<WheelEvent> get onMouseWheel => mouseWheelEvent.forTarget(this);

  @DomName('SVGElementInstance.onpaste')
  @DocsEditable
  Stream<Event> get onPaste => pasteEvent.forTarget(this);

  @DomName('SVGElementInstance.onreset')
  @DocsEditable
  Stream<Event> get onReset => resetEvent.forTarget(this);

  @DomName('SVGElementInstance.onresize')
  @DocsEditable
  Stream<Event> get onResize => resizeEvent.forTarget(this);

  @DomName('SVGElementInstance.onscroll')
  @DocsEditable
  Stream<Event> get onScroll => scrollEvent.forTarget(this);

  @DomName('SVGElementInstance.onsearch')
  @DocsEditable
  Stream<Event> get onSearch => searchEvent.forTarget(this);

  @DomName('SVGElementInstance.onselect')
  @DocsEditable
  Stream<Event> get onSelect => selectEvent.forTarget(this);

  @DomName('SVGElementInstance.onselectstart')
  @DocsEditable
  Stream<Event> get onSelectStart => selectStartEvent.forTarget(this);

  @DomName('SVGElementInstance.onsubmit')
  @DocsEditable
  Stream<Event> get onSubmit => submitEvent.forTarget(this);

  @DomName('SVGElementInstance.onunload')
  @DocsEditable
  Stream<Event> get onUnload => unloadEvent.forTarget(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('ElementTimeControl')
class ElementTimeControl extends NativeFieldWrapperClass1 {
  ElementTimeControl.internal();

  @DomName('ElementTimeControl.beginElement')
  @DocsEditable
  void beginElement() native "ElementTimeControl_beginElement_Callback";

  @DomName('ElementTimeControl.beginElementAt')
  @DocsEditable
  void beginElementAt(num offset) native "ElementTimeControl_beginElementAt_Callback";

  @DomName('ElementTimeControl.endElement')
  @DocsEditable
  void endElement() native "ElementTimeControl_endElement_Callback";

  @DomName('ElementTimeControl.endElementAt')
  @DocsEditable
  void endElementAt(num offset) native "ElementTimeControl_endElementAt_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGEllipseElement')
class EllipseElement extends StyledElement implements Transformable, Tests, ExternalResourcesRequired, LangSpace {
  EllipseElement.internal() : super.internal();

  @DomName('SVGEllipseElement.SVGEllipseElement')
  @DocsEditable
  factory EllipseElement() => _SvgElementFactoryProvider.createSvgElement_tag("ellipse");

  @DomName('SVGEllipseElement.cx')
  @DocsEditable
  AnimatedLength get cx native "SVGEllipseElement_cx_Getter";

  @DomName('SVGEllipseElement.cy')
  @DocsEditable
  AnimatedLength get cy native "SVGEllipseElement_cy_Getter";

  @DomName('SVGEllipseElement.rx')
  @DocsEditable
  AnimatedLength get rx native "SVGEllipseElement_rx_Getter";

  @DomName('SVGEllipseElement.ry')
  @DocsEditable
  AnimatedLength get ry native "SVGEllipseElement_ry_Getter";

  @DomName('SVGEllipseElement.externalResourcesRequired')
  @DocsEditable
  AnimatedBoolean get externalResourcesRequired native "SVGEllipseElement_externalResourcesRequired_Getter";

  @DomName('SVGEllipseElement.xmllang')
  @DocsEditable
  String get xmllang native "SVGEllipseElement_xmllang_Getter";

  @DomName('SVGEllipseElement.xmllang')
  @DocsEditable
  void set xmllang(String value) native "SVGEllipseElement_xmllang_Setter";

  @DomName('SVGEllipseElement.xmlspace')
  @DocsEditable
  String get xmlspace native "SVGEllipseElement_xmlspace_Getter";

  @DomName('SVGEllipseElement.xmlspace')
  @DocsEditable
  void set xmlspace(String value) native "SVGEllipseElement_xmlspace_Setter";

  @DomName('SVGEllipseElement.farthestViewportElement')
  @DocsEditable
  SvgElement get farthestViewportElement native "SVGEllipseElement_farthestViewportElement_Getter";

  @DomName('SVGEllipseElement.nearestViewportElement')
  @DocsEditable
  SvgElement get nearestViewportElement native "SVGEllipseElement_nearestViewportElement_Getter";

  @DomName('SVGEllipseElement.getBBox')
  @DocsEditable
  Rect getBBox() native "SVGEllipseElement_getBBox_Callback";

  @DomName('SVGEllipseElement.getCTM')
  @DocsEditable
  Matrix getCtm() native "SVGEllipseElement_getCTM_Callback";

  @DomName('SVGEllipseElement.getScreenCTM')
  @DocsEditable
  Matrix getScreenCtm() native "SVGEllipseElement_getScreenCTM_Callback";

  @DomName('SVGEllipseElement.getTransformToElement')
  @DocsEditable
  Matrix getTransformToElement(SvgElement element) native "SVGEllipseElement_getTransformToElement_Callback";

  @DomName('SVGEllipseElement.requiredExtensions')
  @DocsEditable
  StringList get requiredExtensions native "SVGEllipseElement_requiredExtensions_Getter";

  @DomName('SVGEllipseElement.requiredFeatures')
  @DocsEditable
  StringList get requiredFeatures native "SVGEllipseElement_requiredFeatures_Getter";

  @DomName('SVGEllipseElement.systemLanguage')
  @DocsEditable
  StringList get systemLanguage native "SVGEllipseElement_systemLanguage_Getter";

  @DomName('SVGEllipseElement.hasExtension')
  @DocsEditable
  bool hasExtension(String extension) native "SVGEllipseElement_hasExtension_Callback";

  @DomName('SVGEllipseElement.transform')
  @DocsEditable
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

  /// Checks if this type is supported on the current platform.
  static bool supported(SvgElement element) => true;

  @DomName('SVGExternalResourcesRequired.externalResourcesRequired')
  @DocsEditable
  AnimatedBoolean get externalResourcesRequired native "SVGExternalResourcesRequired_externalResourcesRequired_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFEBlendElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
class FEBlendElement extends StyledElement implements FilterPrimitiveStandardAttributes {
  FEBlendElement.internal() : super.internal();

  @DomName('SVGFEBlendElement.SVGFEBlendElement')
  @DocsEditable
  factory FEBlendElement() => _SvgElementFactoryProvider.createSvgElement_tag("feBlend");

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  static const int SVG_FEBLEND_MODE_DARKEN = 4;

  static const int SVG_FEBLEND_MODE_LIGHTEN = 5;

  static const int SVG_FEBLEND_MODE_MULTIPLY = 2;

  static const int SVG_FEBLEND_MODE_NORMAL = 1;

  static const int SVG_FEBLEND_MODE_SCREEN = 3;

  static const int SVG_FEBLEND_MODE_UNKNOWN = 0;

  @DomName('SVGFEBlendElement.in1')
  @DocsEditable
  AnimatedString get in1 native "SVGFEBlendElement_in1_Getter";

  @DomName('SVGFEBlendElement.in2')
  @DocsEditable
  AnimatedString get in2 native "SVGFEBlendElement_in2_Getter";

  @DomName('SVGFEBlendElement.mode')
  @DocsEditable
  AnimatedEnumeration get mode native "SVGFEBlendElement_mode_Getter";

  @DomName('SVGFEBlendElement.height')
  @DocsEditable
  AnimatedLength get height native "SVGFEBlendElement_height_Getter";

  @DomName('SVGFEBlendElement.result')
  @DocsEditable
  AnimatedString get result native "SVGFEBlendElement_result_Getter";

  @DomName('SVGFEBlendElement.width')
  @DocsEditable
  AnimatedLength get width native "SVGFEBlendElement_width_Getter";

  @DomName('SVGFEBlendElement.x')
  @DocsEditable
  AnimatedLength get x native "SVGFEBlendElement_x_Getter";

  @DomName('SVGFEBlendElement.y')
  @DocsEditable
  AnimatedLength get y native "SVGFEBlendElement_y_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFEColorMatrixElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
class FEColorMatrixElement extends StyledElement implements FilterPrimitiveStandardAttributes {
  FEColorMatrixElement.internal() : super.internal();

  @DomName('SVGFEColorMatrixElement.SVGFEColorMatrixElement')
  @DocsEditable
  factory FEColorMatrixElement() => _SvgElementFactoryProvider.createSvgElement_tag("feColorMatrix");

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  static const int SVG_FECOLORMATRIX_TYPE_HUEROTATE = 3;

  static const int SVG_FECOLORMATRIX_TYPE_LUMINANCETOALPHA = 4;

  static const int SVG_FECOLORMATRIX_TYPE_MATRIX = 1;

  static const int SVG_FECOLORMATRIX_TYPE_SATURATE = 2;

  static const int SVG_FECOLORMATRIX_TYPE_UNKNOWN = 0;

  @DomName('SVGFEColorMatrixElement.in1')
  @DocsEditable
  AnimatedString get in1 native "SVGFEColorMatrixElement_in1_Getter";

  @DomName('SVGFEColorMatrixElement.type')
  @DocsEditable
  AnimatedEnumeration get type native "SVGFEColorMatrixElement_type_Getter";

  @DomName('SVGFEColorMatrixElement.values')
  @DocsEditable
  AnimatedNumberList get values native "SVGFEColorMatrixElement_values_Getter";

  @DomName('SVGFEColorMatrixElement.height')
  @DocsEditable
  AnimatedLength get height native "SVGFEColorMatrixElement_height_Getter";

  @DomName('SVGFEColorMatrixElement.result')
  @DocsEditable
  AnimatedString get result native "SVGFEColorMatrixElement_result_Getter";

  @DomName('SVGFEColorMatrixElement.width')
  @DocsEditable
  AnimatedLength get width native "SVGFEColorMatrixElement_width_Getter";

  @DomName('SVGFEColorMatrixElement.x')
  @DocsEditable
  AnimatedLength get x native "SVGFEColorMatrixElement_x_Getter";

  @DomName('SVGFEColorMatrixElement.y')
  @DocsEditable
  AnimatedLength get y native "SVGFEColorMatrixElement_y_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFEComponentTransferElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
class FEComponentTransferElement extends StyledElement implements FilterPrimitiveStandardAttributes {
  FEComponentTransferElement.internal() : super.internal();

  @DomName('SVGFEComponentTransferElement.SVGFEComponentTransferElement')
  @DocsEditable
  factory FEComponentTransferElement() => _SvgElementFactoryProvider.createSvgElement_tag("feComponentTransfer");

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFEComponentTransferElement.in1')
  @DocsEditable
  AnimatedString get in1 native "SVGFEComponentTransferElement_in1_Getter";

  @DomName('SVGFEComponentTransferElement.height')
  @DocsEditable
  AnimatedLength get height native "SVGFEComponentTransferElement_height_Getter";

  @DomName('SVGFEComponentTransferElement.result')
  @DocsEditable
  AnimatedString get result native "SVGFEComponentTransferElement_result_Getter";

  @DomName('SVGFEComponentTransferElement.width')
  @DocsEditable
  AnimatedLength get width native "SVGFEComponentTransferElement_width_Getter";

  @DomName('SVGFEComponentTransferElement.x')
  @DocsEditable
  AnimatedLength get x native "SVGFEComponentTransferElement_x_Getter";

  @DomName('SVGFEComponentTransferElement.y')
  @DocsEditable
  AnimatedLength get y native "SVGFEComponentTransferElement_y_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFECompositeElement')
class FECompositeElement extends StyledElement implements FilterPrimitiveStandardAttributes {
  FECompositeElement.internal() : super.internal();

  static const int SVG_FECOMPOSITE_OPERATOR_ARITHMETIC = 6;

  static const int SVG_FECOMPOSITE_OPERATOR_ATOP = 4;

  static const int SVG_FECOMPOSITE_OPERATOR_IN = 2;

  static const int SVG_FECOMPOSITE_OPERATOR_OUT = 3;

  static const int SVG_FECOMPOSITE_OPERATOR_OVER = 1;

  static const int SVG_FECOMPOSITE_OPERATOR_UNKNOWN = 0;

  static const int SVG_FECOMPOSITE_OPERATOR_XOR = 5;

  @DomName('SVGFECompositeElement.in1')
  @DocsEditable
  AnimatedString get in1 native "SVGFECompositeElement_in1_Getter";

  @DomName('SVGFECompositeElement.in2')
  @DocsEditable
  AnimatedString get in2 native "SVGFECompositeElement_in2_Getter";

  @DomName('SVGFECompositeElement.k1')
  @DocsEditable
  AnimatedNumber get k1 native "SVGFECompositeElement_k1_Getter";

  @DomName('SVGFECompositeElement.k2')
  @DocsEditable
  AnimatedNumber get k2 native "SVGFECompositeElement_k2_Getter";

  @DomName('SVGFECompositeElement.k3')
  @DocsEditable
  AnimatedNumber get k3 native "SVGFECompositeElement_k3_Getter";

  @DomName('SVGFECompositeElement.k4')
  @DocsEditable
  AnimatedNumber get k4 native "SVGFECompositeElement_k4_Getter";

  @DomName('SVGFECompositeElement.operator')
  @DocsEditable
  AnimatedEnumeration get operator native "SVGFECompositeElement_operator_Getter";

  @DomName('SVGFECompositeElement.height')
  @DocsEditable
  AnimatedLength get height native "SVGFECompositeElement_height_Getter";

  @DomName('SVGFECompositeElement.result')
  @DocsEditable
  AnimatedString get result native "SVGFECompositeElement_result_Getter";

  @DomName('SVGFECompositeElement.width')
  @DocsEditable
  AnimatedLength get width native "SVGFECompositeElement_width_Getter";

  @DomName('SVGFECompositeElement.x')
  @DocsEditable
  AnimatedLength get x native "SVGFECompositeElement_x_Getter";

  @DomName('SVGFECompositeElement.y')
  @DocsEditable
  AnimatedLength get y native "SVGFECompositeElement_y_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFEConvolveMatrixElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
class FEConvolveMatrixElement extends StyledElement implements FilterPrimitiveStandardAttributes {
  FEConvolveMatrixElement.internal() : super.internal();

  @DomName('SVGFEConvolveMatrixElement.SVGFEConvolveMatrixElement')
  @DocsEditable
  factory FEConvolveMatrixElement() => _SvgElementFactoryProvider.createSvgElement_tag("feConvolveMatrix");

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  static const int SVG_EDGEMODE_DUPLICATE = 1;

  static const int SVG_EDGEMODE_NONE = 3;

  static const int SVG_EDGEMODE_UNKNOWN = 0;

  static const int SVG_EDGEMODE_WRAP = 2;

  @DomName('SVGFEConvolveMatrixElement.bias')
  @DocsEditable
  AnimatedNumber get bias native "SVGFEConvolveMatrixElement_bias_Getter";

  @DomName('SVGFEConvolveMatrixElement.divisor')
  @DocsEditable
  AnimatedNumber get divisor native "SVGFEConvolveMatrixElement_divisor_Getter";

  @DomName('SVGFEConvolveMatrixElement.edgeMode')
  @DocsEditable
  AnimatedEnumeration get edgeMode native "SVGFEConvolveMatrixElement_edgeMode_Getter";

  @DomName('SVGFEConvolveMatrixElement.in1')
  @DocsEditable
  AnimatedString get in1 native "SVGFEConvolveMatrixElement_in1_Getter";

  @DomName('SVGFEConvolveMatrixElement.kernelMatrix')
  @DocsEditable
  AnimatedNumberList get kernelMatrix native "SVGFEConvolveMatrixElement_kernelMatrix_Getter";

  @DomName('SVGFEConvolveMatrixElement.kernelUnitLengthX')
  @DocsEditable
  AnimatedNumber get kernelUnitLengthX native "SVGFEConvolveMatrixElement_kernelUnitLengthX_Getter";

  @DomName('SVGFEConvolveMatrixElement.kernelUnitLengthY')
  @DocsEditable
  AnimatedNumber get kernelUnitLengthY native "SVGFEConvolveMatrixElement_kernelUnitLengthY_Getter";

  @DomName('SVGFEConvolveMatrixElement.orderX')
  @DocsEditable
  AnimatedInteger get orderX native "SVGFEConvolveMatrixElement_orderX_Getter";

  @DomName('SVGFEConvolveMatrixElement.orderY')
  @DocsEditable
  AnimatedInteger get orderY native "SVGFEConvolveMatrixElement_orderY_Getter";

  @DomName('SVGFEConvolveMatrixElement.preserveAlpha')
  @DocsEditable
  AnimatedBoolean get preserveAlpha native "SVGFEConvolveMatrixElement_preserveAlpha_Getter";

  @DomName('SVGFEConvolveMatrixElement.targetX')
  @DocsEditable
  AnimatedInteger get targetX native "SVGFEConvolveMatrixElement_targetX_Getter";

  @DomName('SVGFEConvolveMatrixElement.targetY')
  @DocsEditable
  AnimatedInteger get targetY native "SVGFEConvolveMatrixElement_targetY_Getter";

  @DomName('SVGFEConvolveMatrixElement.height')
  @DocsEditable
  AnimatedLength get height native "SVGFEConvolveMatrixElement_height_Getter";

  @DomName('SVGFEConvolveMatrixElement.result')
  @DocsEditable
  AnimatedString get result native "SVGFEConvolveMatrixElement_result_Getter";

  @DomName('SVGFEConvolveMatrixElement.width')
  @DocsEditable
  AnimatedLength get width native "SVGFEConvolveMatrixElement_width_Getter";

  @DomName('SVGFEConvolveMatrixElement.x')
  @DocsEditable
  AnimatedLength get x native "SVGFEConvolveMatrixElement_x_Getter";

  @DomName('SVGFEConvolveMatrixElement.y')
  @DocsEditable
  AnimatedLength get y native "SVGFEConvolveMatrixElement_y_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFEDiffuseLightingElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
class FEDiffuseLightingElement extends StyledElement implements FilterPrimitiveStandardAttributes {
  FEDiffuseLightingElement.internal() : super.internal();

  @DomName('SVGFEDiffuseLightingElement.SVGFEDiffuseLightingElement')
  @DocsEditable
  factory FEDiffuseLightingElement() => _SvgElementFactoryProvider.createSvgElement_tag("feDiffuseLighting");

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFEDiffuseLightingElement.diffuseConstant')
  @DocsEditable
  AnimatedNumber get diffuseConstant native "SVGFEDiffuseLightingElement_diffuseConstant_Getter";

  @DomName('SVGFEDiffuseLightingElement.in1')
  @DocsEditable
  AnimatedString get in1 native "SVGFEDiffuseLightingElement_in1_Getter";

  @DomName('SVGFEDiffuseLightingElement.kernelUnitLengthX')
  @DocsEditable
  AnimatedNumber get kernelUnitLengthX native "SVGFEDiffuseLightingElement_kernelUnitLengthX_Getter";

  @DomName('SVGFEDiffuseLightingElement.kernelUnitLengthY')
  @DocsEditable
  AnimatedNumber get kernelUnitLengthY native "SVGFEDiffuseLightingElement_kernelUnitLengthY_Getter";

  @DomName('SVGFEDiffuseLightingElement.surfaceScale')
  @DocsEditable
  AnimatedNumber get surfaceScale native "SVGFEDiffuseLightingElement_surfaceScale_Getter";

  @DomName('SVGFEDiffuseLightingElement.height')
  @DocsEditable
  AnimatedLength get height native "SVGFEDiffuseLightingElement_height_Getter";

  @DomName('SVGFEDiffuseLightingElement.result')
  @DocsEditable
  AnimatedString get result native "SVGFEDiffuseLightingElement_result_Getter";

  @DomName('SVGFEDiffuseLightingElement.width')
  @DocsEditable
  AnimatedLength get width native "SVGFEDiffuseLightingElement_width_Getter";

  @DomName('SVGFEDiffuseLightingElement.x')
  @DocsEditable
  AnimatedLength get x native "SVGFEDiffuseLightingElement_x_Getter";

  @DomName('SVGFEDiffuseLightingElement.y')
  @DocsEditable
  AnimatedLength get y native "SVGFEDiffuseLightingElement_y_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFEDisplacementMapElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
class FEDisplacementMapElement extends StyledElement implements FilterPrimitiveStandardAttributes {
  FEDisplacementMapElement.internal() : super.internal();

  @DomName('SVGFEDisplacementMapElement.SVGFEDisplacementMapElement')
  @DocsEditable
  factory FEDisplacementMapElement() => _SvgElementFactoryProvider.createSvgElement_tag("feDisplacementMap");

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  static const int SVG_CHANNEL_A = 4;

  static const int SVG_CHANNEL_B = 3;

  static const int SVG_CHANNEL_G = 2;

  static const int SVG_CHANNEL_R = 1;

  static const int SVG_CHANNEL_UNKNOWN = 0;

  @DomName('SVGFEDisplacementMapElement.in1')
  @DocsEditable
  AnimatedString get in1 native "SVGFEDisplacementMapElement_in1_Getter";

  @DomName('SVGFEDisplacementMapElement.in2')
  @DocsEditable
  AnimatedString get in2 native "SVGFEDisplacementMapElement_in2_Getter";

  @DomName('SVGFEDisplacementMapElement.scale')
  @DocsEditable
  AnimatedNumber get scale native "SVGFEDisplacementMapElement_scale_Getter";

  @DomName('SVGFEDisplacementMapElement.xChannelSelector')
  @DocsEditable
  AnimatedEnumeration get xChannelSelector native "SVGFEDisplacementMapElement_xChannelSelector_Getter";

  @DomName('SVGFEDisplacementMapElement.yChannelSelector')
  @DocsEditable
  AnimatedEnumeration get yChannelSelector native "SVGFEDisplacementMapElement_yChannelSelector_Getter";

  @DomName('SVGFEDisplacementMapElement.height')
  @DocsEditable
  AnimatedLength get height native "SVGFEDisplacementMapElement_height_Getter";

  @DomName('SVGFEDisplacementMapElement.result')
  @DocsEditable
  AnimatedString get result native "SVGFEDisplacementMapElement_result_Getter";

  @DomName('SVGFEDisplacementMapElement.width')
  @DocsEditable
  AnimatedLength get width native "SVGFEDisplacementMapElement_width_Getter";

  @DomName('SVGFEDisplacementMapElement.x')
  @DocsEditable
  AnimatedLength get x native "SVGFEDisplacementMapElement_x_Getter";

  @DomName('SVGFEDisplacementMapElement.y')
  @DocsEditable
  AnimatedLength get y native "SVGFEDisplacementMapElement_y_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFEDistantLightElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
class FEDistantLightElement extends SvgElement {
  FEDistantLightElement.internal() : super.internal();

  @DomName('SVGFEDistantLightElement.SVGFEDistantLightElement')
  @DocsEditable
  factory FEDistantLightElement() => _SvgElementFactoryProvider.createSvgElement_tag("feDistantLight");

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFEDistantLightElement.azimuth')
  @DocsEditable
  AnimatedNumber get azimuth native "SVGFEDistantLightElement_azimuth_Getter";

  @DomName('SVGFEDistantLightElement.elevation')
  @DocsEditable
  AnimatedNumber get elevation native "SVGFEDistantLightElement_elevation_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFEFloodElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
class FEFloodElement extends StyledElement implements FilterPrimitiveStandardAttributes {
  FEFloodElement.internal() : super.internal();

  @DomName('SVGFEFloodElement.SVGFEFloodElement')
  @DocsEditable
  factory FEFloodElement() => _SvgElementFactoryProvider.createSvgElement_tag("feFlood");

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFEFloodElement.height')
  @DocsEditable
  AnimatedLength get height native "SVGFEFloodElement_height_Getter";

  @DomName('SVGFEFloodElement.result')
  @DocsEditable
  AnimatedString get result native "SVGFEFloodElement_result_Getter";

  @DomName('SVGFEFloodElement.width')
  @DocsEditable
  AnimatedLength get width native "SVGFEFloodElement_width_Getter";

  @DomName('SVGFEFloodElement.x')
  @DocsEditable
  AnimatedLength get x native "SVGFEFloodElement_x_Getter";

  @DomName('SVGFEFloodElement.y')
  @DocsEditable
  AnimatedLength get y native "SVGFEFloodElement_y_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFEFuncAElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
class FEFuncAElement extends _SVGComponentTransferFunctionElement {
  FEFuncAElement.internal() : super.internal();

  @DomName('SVGFEFuncAElement.SVGFEFuncAElement')
  @DocsEditable
  factory FEFuncAElement() => _SvgElementFactoryProvider.createSvgElement_tag("feFuncA");

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFEFuncBElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
class FEFuncBElement extends _SVGComponentTransferFunctionElement {
  FEFuncBElement.internal() : super.internal();

  @DomName('SVGFEFuncBElement.SVGFEFuncBElement')
  @DocsEditable
  factory FEFuncBElement() => _SvgElementFactoryProvider.createSvgElement_tag("feFuncB");

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFEFuncGElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
class FEFuncGElement extends _SVGComponentTransferFunctionElement {
  FEFuncGElement.internal() : super.internal();

  @DomName('SVGFEFuncGElement.SVGFEFuncGElement')
  @DocsEditable
  factory FEFuncGElement() => _SvgElementFactoryProvider.createSvgElement_tag("feFuncG");

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFEFuncRElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
class FEFuncRElement extends _SVGComponentTransferFunctionElement {
  FEFuncRElement.internal() : super.internal();

  @DomName('SVGFEFuncRElement.SVGFEFuncRElement')
  @DocsEditable
  factory FEFuncRElement() => _SvgElementFactoryProvider.createSvgElement_tag("feFuncR");

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFEGaussianBlurElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
class FEGaussianBlurElement extends StyledElement implements FilterPrimitiveStandardAttributes {
  FEGaussianBlurElement.internal() : super.internal();

  @DomName('SVGFEGaussianBlurElement.SVGFEGaussianBlurElement')
  @DocsEditable
  factory FEGaussianBlurElement() => _SvgElementFactoryProvider.createSvgElement_tag("feGaussianBlur");

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFEGaussianBlurElement.in1')
  @DocsEditable
  AnimatedString get in1 native "SVGFEGaussianBlurElement_in1_Getter";

  @DomName('SVGFEGaussianBlurElement.stdDeviationX')
  @DocsEditable
  AnimatedNumber get stdDeviationX native "SVGFEGaussianBlurElement_stdDeviationX_Getter";

  @DomName('SVGFEGaussianBlurElement.stdDeviationY')
  @DocsEditable
  AnimatedNumber get stdDeviationY native "SVGFEGaussianBlurElement_stdDeviationY_Getter";

  @DomName('SVGFEGaussianBlurElement.setStdDeviation')
  @DocsEditable
  void setStdDeviation(num stdDeviationX, num stdDeviationY) native "SVGFEGaussianBlurElement_setStdDeviation_Callback";

  @DomName('SVGFEGaussianBlurElement.height')
  @DocsEditable
  AnimatedLength get height native "SVGFEGaussianBlurElement_height_Getter";

  @DomName('SVGFEGaussianBlurElement.result')
  @DocsEditable
  AnimatedString get result native "SVGFEGaussianBlurElement_result_Getter";

  @DomName('SVGFEGaussianBlurElement.width')
  @DocsEditable
  AnimatedLength get width native "SVGFEGaussianBlurElement_width_Getter";

  @DomName('SVGFEGaussianBlurElement.x')
  @DocsEditable
  AnimatedLength get x native "SVGFEGaussianBlurElement_x_Getter";

  @DomName('SVGFEGaussianBlurElement.y')
  @DocsEditable
  AnimatedLength get y native "SVGFEGaussianBlurElement_y_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFEImageElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
class FEImageElement extends StyledElement implements FilterPrimitiveStandardAttributes, UriReference, ExternalResourcesRequired, LangSpace {
  FEImageElement.internal() : super.internal();

  @DomName('SVGFEImageElement.SVGFEImageElement')
  @DocsEditable
  factory FEImageElement() => _SvgElementFactoryProvider.createSvgElement_tag("feImage");

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFEImageElement.preserveAspectRatio')
  @DocsEditable
  AnimatedPreserveAspectRatio get preserveAspectRatio native "SVGFEImageElement_preserveAspectRatio_Getter";

  @DomName('SVGFEImageElement.externalResourcesRequired')
  @DocsEditable
  AnimatedBoolean get externalResourcesRequired native "SVGFEImageElement_externalResourcesRequired_Getter";

  @DomName('SVGFEImageElement.height')
  @DocsEditable
  AnimatedLength get height native "SVGFEImageElement_height_Getter";

  @DomName('SVGFEImageElement.result')
  @DocsEditable
  AnimatedString get result native "SVGFEImageElement_result_Getter";

  @DomName('SVGFEImageElement.width')
  @DocsEditable
  AnimatedLength get width native "SVGFEImageElement_width_Getter";

  @DomName('SVGFEImageElement.x')
  @DocsEditable
  AnimatedLength get x native "SVGFEImageElement_x_Getter";

  @DomName('SVGFEImageElement.y')
  @DocsEditable
  AnimatedLength get y native "SVGFEImageElement_y_Getter";

  @DomName('SVGFEImageElement.xmllang')
  @DocsEditable
  String get xmllang native "SVGFEImageElement_xmllang_Getter";

  @DomName('SVGFEImageElement.xmllang')
  @DocsEditable
  void set xmllang(String value) native "SVGFEImageElement_xmllang_Setter";

  @DomName('SVGFEImageElement.xmlspace')
  @DocsEditable
  String get xmlspace native "SVGFEImageElement_xmlspace_Getter";

  @DomName('SVGFEImageElement.xmlspace')
  @DocsEditable
  void set xmlspace(String value) native "SVGFEImageElement_xmlspace_Setter";

  @DomName('SVGFEImageElement.href')
  @DocsEditable
  AnimatedString get href native "SVGFEImageElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFEMergeElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
class FEMergeElement extends StyledElement implements FilterPrimitiveStandardAttributes {
  FEMergeElement.internal() : super.internal();

  @DomName('SVGFEMergeElement.SVGFEMergeElement')
  @DocsEditable
  factory FEMergeElement() => _SvgElementFactoryProvider.createSvgElement_tag("feMerge");

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFEMergeElement.height')
  @DocsEditable
  AnimatedLength get height native "SVGFEMergeElement_height_Getter";

  @DomName('SVGFEMergeElement.result')
  @DocsEditable
  AnimatedString get result native "SVGFEMergeElement_result_Getter";

  @DomName('SVGFEMergeElement.width')
  @DocsEditable
  AnimatedLength get width native "SVGFEMergeElement_width_Getter";

  @DomName('SVGFEMergeElement.x')
  @DocsEditable
  AnimatedLength get x native "SVGFEMergeElement_x_Getter";

  @DomName('SVGFEMergeElement.y')
  @DocsEditable
  AnimatedLength get y native "SVGFEMergeElement_y_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFEMergeNodeElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
class FEMergeNodeElement extends SvgElement {
  FEMergeNodeElement.internal() : super.internal();

  @DomName('SVGFEMergeNodeElement.SVGFEMergeNodeElement')
  @DocsEditable
  factory FEMergeNodeElement() => _SvgElementFactoryProvider.createSvgElement_tag("feMergeNode");

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFEMergeNodeElement.in1')
  @DocsEditable
  AnimatedString get in1 native "SVGFEMergeNodeElement_in1_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFEMorphologyElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
class FEMorphologyElement extends StyledElement implements FilterPrimitiveStandardAttributes {
  FEMorphologyElement.internal() : super.internal();

  static const int SVG_MORPHOLOGY_OPERATOR_DILATE = 2;

  static const int SVG_MORPHOLOGY_OPERATOR_ERODE = 1;

  static const int SVG_MORPHOLOGY_OPERATOR_UNKNOWN = 0;

  @DomName('SVGFEMorphologyElement.in1')
  @DocsEditable
  AnimatedString get in1 native "SVGFEMorphologyElement_in1_Getter";

  @DomName('SVGFEMorphologyElement.operator')
  @DocsEditable
  AnimatedEnumeration get operator native "SVGFEMorphologyElement_operator_Getter";

  @DomName('SVGFEMorphologyElement.radiusX')
  @DocsEditable
  AnimatedNumber get radiusX native "SVGFEMorphologyElement_radiusX_Getter";

  @DomName('SVGFEMorphologyElement.radiusY')
  @DocsEditable
  AnimatedNumber get radiusY native "SVGFEMorphologyElement_radiusY_Getter";

  @DomName('SVGFEMorphologyElement.setRadius')
  @DocsEditable
  void setRadius(num radiusX, num radiusY) native "SVGFEMorphologyElement_setRadius_Callback";

  @DomName('SVGFEMorphologyElement.height')
  @DocsEditable
  AnimatedLength get height native "SVGFEMorphologyElement_height_Getter";

  @DomName('SVGFEMorphologyElement.result')
  @DocsEditable
  AnimatedString get result native "SVGFEMorphologyElement_result_Getter";

  @DomName('SVGFEMorphologyElement.width')
  @DocsEditable
  AnimatedLength get width native "SVGFEMorphologyElement_width_Getter";

  @DomName('SVGFEMorphologyElement.x')
  @DocsEditable
  AnimatedLength get x native "SVGFEMorphologyElement_x_Getter";

  @DomName('SVGFEMorphologyElement.y')
  @DocsEditable
  AnimatedLength get y native "SVGFEMorphologyElement_y_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFEOffsetElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
class FEOffsetElement extends StyledElement implements FilterPrimitiveStandardAttributes {
  FEOffsetElement.internal() : super.internal();

  @DomName('SVGFEOffsetElement.SVGFEOffsetElement')
  @DocsEditable
  factory FEOffsetElement() => _SvgElementFactoryProvider.createSvgElement_tag("feOffset");

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFEOffsetElement.dx')
  @DocsEditable
  AnimatedNumber get dx native "SVGFEOffsetElement_dx_Getter";

  @DomName('SVGFEOffsetElement.dy')
  @DocsEditable
  AnimatedNumber get dy native "SVGFEOffsetElement_dy_Getter";

  @DomName('SVGFEOffsetElement.in1')
  @DocsEditable
  AnimatedString get in1 native "SVGFEOffsetElement_in1_Getter";

  @DomName('SVGFEOffsetElement.height')
  @DocsEditable
  AnimatedLength get height native "SVGFEOffsetElement_height_Getter";

  @DomName('SVGFEOffsetElement.result')
  @DocsEditable
  AnimatedString get result native "SVGFEOffsetElement_result_Getter";

  @DomName('SVGFEOffsetElement.width')
  @DocsEditable
  AnimatedLength get width native "SVGFEOffsetElement_width_Getter";

  @DomName('SVGFEOffsetElement.x')
  @DocsEditable
  AnimatedLength get x native "SVGFEOffsetElement_x_Getter";

  @DomName('SVGFEOffsetElement.y')
  @DocsEditable
  AnimatedLength get y native "SVGFEOffsetElement_y_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFEPointLightElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
class FEPointLightElement extends SvgElement {
  FEPointLightElement.internal() : super.internal();

  @DomName('SVGFEPointLightElement.SVGFEPointLightElement')
  @DocsEditable
  factory FEPointLightElement() => _SvgElementFactoryProvider.createSvgElement_tag("fePointLight");

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFEPointLightElement.x')
  @DocsEditable
  AnimatedNumber get x native "SVGFEPointLightElement_x_Getter";

  @DomName('SVGFEPointLightElement.y')
  @DocsEditable
  AnimatedNumber get y native "SVGFEPointLightElement_y_Getter";

  @DomName('SVGFEPointLightElement.z')
  @DocsEditable
  AnimatedNumber get z native "SVGFEPointLightElement_z_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFESpecularLightingElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
class FESpecularLightingElement extends StyledElement implements FilterPrimitiveStandardAttributes {
  FESpecularLightingElement.internal() : super.internal();

  @DomName('SVGFESpecularLightingElement.SVGFESpecularLightingElement')
  @DocsEditable
  factory FESpecularLightingElement() => _SvgElementFactoryProvider.createSvgElement_tag("feSpecularLighting");

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFESpecularLightingElement.in1')
  @DocsEditable
  AnimatedString get in1 native "SVGFESpecularLightingElement_in1_Getter";

  @DomName('SVGFESpecularLightingElement.specularConstant')
  @DocsEditable
  AnimatedNumber get specularConstant native "SVGFESpecularLightingElement_specularConstant_Getter";

  @DomName('SVGFESpecularLightingElement.specularExponent')
  @DocsEditable
  AnimatedNumber get specularExponent native "SVGFESpecularLightingElement_specularExponent_Getter";

  @DomName('SVGFESpecularLightingElement.surfaceScale')
  @DocsEditable
  AnimatedNumber get surfaceScale native "SVGFESpecularLightingElement_surfaceScale_Getter";

  @DomName('SVGFESpecularLightingElement.height')
  @DocsEditable
  AnimatedLength get height native "SVGFESpecularLightingElement_height_Getter";

  @DomName('SVGFESpecularLightingElement.result')
  @DocsEditable
  AnimatedString get result native "SVGFESpecularLightingElement_result_Getter";

  @DomName('SVGFESpecularLightingElement.width')
  @DocsEditable
  AnimatedLength get width native "SVGFESpecularLightingElement_width_Getter";

  @DomName('SVGFESpecularLightingElement.x')
  @DocsEditable
  AnimatedLength get x native "SVGFESpecularLightingElement_x_Getter";

  @DomName('SVGFESpecularLightingElement.y')
  @DocsEditable
  AnimatedLength get y native "SVGFESpecularLightingElement_y_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFESpotLightElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
class FESpotLightElement extends SvgElement {
  FESpotLightElement.internal() : super.internal();

  @DomName('SVGFESpotLightElement.SVGFESpotLightElement')
  @DocsEditable
  factory FESpotLightElement() => _SvgElementFactoryProvider.createSvgElement_tag("feSpotLight");

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFESpotLightElement.limitingConeAngle')
  @DocsEditable
  AnimatedNumber get limitingConeAngle native "SVGFESpotLightElement_limitingConeAngle_Getter";

  @DomName('SVGFESpotLightElement.pointsAtX')
  @DocsEditable
  AnimatedNumber get pointsAtX native "SVGFESpotLightElement_pointsAtX_Getter";

  @DomName('SVGFESpotLightElement.pointsAtY')
  @DocsEditable
  AnimatedNumber get pointsAtY native "SVGFESpotLightElement_pointsAtY_Getter";

  @DomName('SVGFESpotLightElement.pointsAtZ')
  @DocsEditable
  AnimatedNumber get pointsAtZ native "SVGFESpotLightElement_pointsAtZ_Getter";

  @DomName('SVGFESpotLightElement.specularExponent')
  @DocsEditable
  AnimatedNumber get specularExponent native "SVGFESpotLightElement_specularExponent_Getter";

  @DomName('SVGFESpotLightElement.x')
  @DocsEditable
  AnimatedNumber get x native "SVGFESpotLightElement_x_Getter";

  @DomName('SVGFESpotLightElement.y')
  @DocsEditable
  AnimatedNumber get y native "SVGFESpotLightElement_y_Getter";

  @DomName('SVGFESpotLightElement.z')
  @DocsEditable
  AnimatedNumber get z native "SVGFESpotLightElement_z_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFETileElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
class FETileElement extends StyledElement implements FilterPrimitiveStandardAttributes {
  FETileElement.internal() : super.internal();

  @DomName('SVGFETileElement.SVGFETileElement')
  @DocsEditable
  factory FETileElement() => _SvgElementFactoryProvider.createSvgElement_tag("feTile");

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFETileElement.in1')
  @DocsEditable
  AnimatedString get in1 native "SVGFETileElement_in1_Getter";

  @DomName('SVGFETileElement.height')
  @DocsEditable
  AnimatedLength get height native "SVGFETileElement_height_Getter";

  @DomName('SVGFETileElement.result')
  @DocsEditable
  AnimatedString get result native "SVGFETileElement_result_Getter";

  @DomName('SVGFETileElement.width')
  @DocsEditable
  AnimatedLength get width native "SVGFETileElement_width_Getter";

  @DomName('SVGFETileElement.x')
  @DocsEditable
  AnimatedLength get x native "SVGFETileElement_x_Getter";

  @DomName('SVGFETileElement.y')
  @DocsEditable
  AnimatedLength get y native "SVGFETileElement_y_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFETurbulenceElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
class FETurbulenceElement extends StyledElement implements FilterPrimitiveStandardAttributes {
  FETurbulenceElement.internal() : super.internal();

  @DomName('SVGFETurbulenceElement.SVGFETurbulenceElement')
  @DocsEditable
  factory FETurbulenceElement() => _SvgElementFactoryProvider.createSvgElement_tag("feTurbulence");

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  static const int SVG_STITCHTYPE_NOSTITCH = 2;

  static const int SVG_STITCHTYPE_STITCH = 1;

  static const int SVG_STITCHTYPE_UNKNOWN = 0;

  static const int SVG_TURBULENCE_TYPE_FRACTALNOISE = 1;

  static const int SVG_TURBULENCE_TYPE_TURBULENCE = 2;

  static const int SVG_TURBULENCE_TYPE_UNKNOWN = 0;

  @DomName('SVGFETurbulenceElement.baseFrequencyX')
  @DocsEditable
  AnimatedNumber get baseFrequencyX native "SVGFETurbulenceElement_baseFrequencyX_Getter";

  @DomName('SVGFETurbulenceElement.baseFrequencyY')
  @DocsEditable
  AnimatedNumber get baseFrequencyY native "SVGFETurbulenceElement_baseFrequencyY_Getter";

  @DomName('SVGFETurbulenceElement.numOctaves')
  @DocsEditable
  AnimatedInteger get numOctaves native "SVGFETurbulenceElement_numOctaves_Getter";

  @DomName('SVGFETurbulenceElement.seed')
  @DocsEditable
  AnimatedNumber get seed native "SVGFETurbulenceElement_seed_Getter";

  @DomName('SVGFETurbulenceElement.stitchTiles')
  @DocsEditable
  AnimatedEnumeration get stitchTiles native "SVGFETurbulenceElement_stitchTiles_Getter";

  @DomName('SVGFETurbulenceElement.type')
  @DocsEditable
  AnimatedEnumeration get type native "SVGFETurbulenceElement_type_Getter";

  @DomName('SVGFETurbulenceElement.height')
  @DocsEditable
  AnimatedLength get height native "SVGFETurbulenceElement_height_Getter";

  @DomName('SVGFETurbulenceElement.result')
  @DocsEditable
  AnimatedString get result native "SVGFETurbulenceElement_result_Getter";

  @DomName('SVGFETurbulenceElement.width')
  @DocsEditable
  AnimatedLength get width native "SVGFETurbulenceElement_width_Getter";

  @DomName('SVGFETurbulenceElement.x')
  @DocsEditable
  AnimatedLength get x native "SVGFETurbulenceElement_x_Getter";

  @DomName('SVGFETurbulenceElement.y')
  @DocsEditable
  AnimatedLength get y native "SVGFETurbulenceElement_y_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFilterElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
class FilterElement extends StyledElement implements UriReference, ExternalResourcesRequired, LangSpace {
  FilterElement.internal() : super.internal();

  @DomName('SVGFilterElement.SVGFilterElement')
  @DocsEditable
  factory FilterElement() => _SvgElementFactoryProvider.createSvgElement_tag("filter");

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFilterElement.filterResX')
  @DocsEditable
  AnimatedInteger get filterResX native "SVGFilterElement_filterResX_Getter";

  @DomName('SVGFilterElement.filterResY')
  @DocsEditable
  AnimatedInteger get filterResY native "SVGFilterElement_filterResY_Getter";

  @DomName('SVGFilterElement.filterUnits')
  @DocsEditable
  AnimatedEnumeration get filterUnits native "SVGFilterElement_filterUnits_Getter";

  @DomName('SVGFilterElement.height')
  @DocsEditable
  AnimatedLength get height native "SVGFilterElement_height_Getter";

  @DomName('SVGFilterElement.primitiveUnits')
  @DocsEditable
  AnimatedEnumeration get primitiveUnits native "SVGFilterElement_primitiveUnits_Getter";

  @DomName('SVGFilterElement.width')
  @DocsEditable
  AnimatedLength get width native "SVGFilterElement_width_Getter";

  @DomName('SVGFilterElement.x')
  @DocsEditable
  AnimatedLength get x native "SVGFilterElement_x_Getter";

  @DomName('SVGFilterElement.y')
  @DocsEditable
  AnimatedLength get y native "SVGFilterElement_y_Getter";

  @DomName('SVGFilterElement.setFilterRes')
  @DocsEditable
  void setFilterRes(int filterResX, int filterResY) native "SVGFilterElement_setFilterRes_Callback";

  @DomName('SVGFilterElement.externalResourcesRequired')
  @DocsEditable
  AnimatedBoolean get externalResourcesRequired native "SVGFilterElement_externalResourcesRequired_Getter";

  @DomName('SVGFilterElement.xmllang')
  @DocsEditable
  String get xmllang native "SVGFilterElement_xmllang_Getter";

  @DomName('SVGFilterElement.xmllang')
  @DocsEditable
  void set xmllang(String value) native "SVGFilterElement_xmllang_Setter";

  @DomName('SVGFilterElement.xmlspace')
  @DocsEditable
  String get xmlspace native "SVGFilterElement_xmlspace_Getter";

  @DomName('SVGFilterElement.xmlspace')
  @DocsEditable
  void set xmlspace(String value) native "SVGFilterElement_xmlspace_Setter";

  @DomName('SVGFilterElement.href')
  @DocsEditable
  AnimatedString get href native "SVGFilterElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFilterPrimitiveStandardAttributes')
class FilterPrimitiveStandardAttributes extends NativeFieldWrapperClass1 {
  FilterPrimitiveStandardAttributes.internal();

  @DomName('SVGFilterPrimitiveStandardAttributes.height')
  @DocsEditable
  AnimatedLength get height native "SVGFilterPrimitiveStandardAttributes_height_Getter";

  @DomName('SVGFilterPrimitiveStandardAttributes.result')
  @DocsEditable
  AnimatedString get result native "SVGFilterPrimitiveStandardAttributes_result_Getter";

  @DomName('SVGFilterPrimitiveStandardAttributes.width')
  @DocsEditable
  AnimatedLength get width native "SVGFilterPrimitiveStandardAttributes_width_Getter";

  @DomName('SVGFilterPrimitiveStandardAttributes.x')
  @DocsEditable
  AnimatedLength get x native "SVGFilterPrimitiveStandardAttributes_x_Getter";

  @DomName('SVGFilterPrimitiveStandardAttributes.y')
  @DocsEditable
  AnimatedLength get y native "SVGFilterPrimitiveStandardAttributes_y_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFitToViewBox')
class FitToViewBox extends NativeFieldWrapperClass1 {
  FitToViewBox.internal();

  @DomName('SVGFitToViewBox.preserveAspectRatio')
  @DocsEditable
  AnimatedPreserveAspectRatio get preserveAspectRatio native "SVGFitToViewBox_preserveAspectRatio_Getter";

  @DomName('SVGFitToViewBox.viewBox')
  @DocsEditable
  AnimatedRect get viewBox native "SVGFitToViewBox_viewBox_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGForeignObjectElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.SAFARI)
class ForeignObjectElement extends StyledElement implements Transformable, Tests, ExternalResourcesRequired, LangSpace {
  ForeignObjectElement.internal() : super.internal();

  @DomName('SVGForeignObjectElement.SVGForeignObjectElement')
  @DocsEditable
  factory ForeignObjectElement() => _SvgElementFactoryProvider.createSvgElement_tag("foreignObject");

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGForeignObjectElement.height')
  @DocsEditable
  AnimatedLength get height native "SVGForeignObjectElement_height_Getter";

  @DomName('SVGForeignObjectElement.width')
  @DocsEditable
  AnimatedLength get width native "SVGForeignObjectElement_width_Getter";

  @DomName('SVGForeignObjectElement.x')
  @DocsEditable
  AnimatedLength get x native "SVGForeignObjectElement_x_Getter";

  @DomName('SVGForeignObjectElement.y')
  @DocsEditable
  AnimatedLength get y native "SVGForeignObjectElement_y_Getter";

  @DomName('SVGForeignObjectElement.externalResourcesRequired')
  @DocsEditable
  AnimatedBoolean get externalResourcesRequired native "SVGForeignObjectElement_externalResourcesRequired_Getter";

  @DomName('SVGForeignObjectElement.xmllang')
  @DocsEditable
  String get xmllang native "SVGForeignObjectElement_xmllang_Getter";

  @DomName('SVGForeignObjectElement.xmllang')
  @DocsEditable
  void set xmllang(String value) native "SVGForeignObjectElement_xmllang_Setter";

  @DomName('SVGForeignObjectElement.xmlspace')
  @DocsEditable
  String get xmlspace native "SVGForeignObjectElement_xmlspace_Getter";

  @DomName('SVGForeignObjectElement.xmlspace')
  @DocsEditable
  void set xmlspace(String value) native "SVGForeignObjectElement_xmlspace_Setter";

  @DomName('SVGForeignObjectElement.farthestViewportElement')
  @DocsEditable
  SvgElement get farthestViewportElement native "SVGForeignObjectElement_farthestViewportElement_Getter";

  @DomName('SVGForeignObjectElement.nearestViewportElement')
  @DocsEditable
  SvgElement get nearestViewportElement native "SVGForeignObjectElement_nearestViewportElement_Getter";

  @DomName('SVGForeignObjectElement.getBBox')
  @DocsEditable
  Rect getBBox() native "SVGForeignObjectElement_getBBox_Callback";

  @DomName('SVGForeignObjectElement.getCTM')
  @DocsEditable
  Matrix getCtm() native "SVGForeignObjectElement_getCTM_Callback";

  @DomName('SVGForeignObjectElement.getScreenCTM')
  @DocsEditable
  Matrix getScreenCtm() native "SVGForeignObjectElement_getScreenCTM_Callback";

  @DomName('SVGForeignObjectElement.getTransformToElement')
  @DocsEditable
  Matrix getTransformToElement(SvgElement element) native "SVGForeignObjectElement_getTransformToElement_Callback";

  @DomName('SVGForeignObjectElement.requiredExtensions')
  @DocsEditable
  StringList get requiredExtensions native "SVGForeignObjectElement_requiredExtensions_Getter";

  @DomName('SVGForeignObjectElement.requiredFeatures')
  @DocsEditable
  StringList get requiredFeatures native "SVGForeignObjectElement_requiredFeatures_Getter";

  @DomName('SVGForeignObjectElement.systemLanguage')
  @DocsEditable
  StringList get systemLanguage native "SVGForeignObjectElement_systemLanguage_Getter";

  @DomName('SVGForeignObjectElement.hasExtension')
  @DocsEditable
  bool hasExtension(String extension) native "SVGForeignObjectElement_hasExtension_Callback";

  @DomName('SVGForeignObjectElement.transform')
  @DocsEditable
  AnimatedTransformList get transform native "SVGForeignObjectElement_transform_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGGElement')
class GElement extends StyledElement implements Transformable, Tests, ExternalResourcesRequired, LangSpace {
  GElement.internal() : super.internal();

  @DomName('SVGGElement.SVGGElement')
  @DocsEditable
  factory GElement() => _SvgElementFactoryProvider.createSvgElement_tag("g");

  @DomName('SVGGElement.externalResourcesRequired')
  @DocsEditable
  AnimatedBoolean get externalResourcesRequired native "SVGGElement_externalResourcesRequired_Getter";

  @DomName('SVGGElement.xmllang')
  @DocsEditable
  String get xmllang native "SVGGElement_xmllang_Getter";

  @DomName('SVGGElement.xmllang')
  @DocsEditable
  void set xmllang(String value) native "SVGGElement_xmllang_Setter";

  @DomName('SVGGElement.xmlspace')
  @DocsEditable
  String get xmlspace native "SVGGElement_xmlspace_Getter";

  @DomName('SVGGElement.xmlspace')
  @DocsEditable
  void set xmlspace(String value) native "SVGGElement_xmlspace_Setter";

  @DomName('SVGGElement.farthestViewportElement')
  @DocsEditable
  SvgElement get farthestViewportElement native "SVGGElement_farthestViewportElement_Getter";

  @DomName('SVGGElement.nearestViewportElement')
  @DocsEditable
  SvgElement get nearestViewportElement native "SVGGElement_nearestViewportElement_Getter";

  @DomName('SVGGElement.getBBox')
  @DocsEditable
  Rect getBBox() native "SVGGElement_getBBox_Callback";

  @DomName('SVGGElement.getCTM')
  @DocsEditable
  Matrix getCtm() native "SVGGElement_getCTM_Callback";

  @DomName('SVGGElement.getScreenCTM')
  @DocsEditable
  Matrix getScreenCtm() native "SVGGElement_getScreenCTM_Callback";

  @DomName('SVGGElement.getTransformToElement')
  @DocsEditable
  Matrix getTransformToElement(SvgElement element) native "SVGGElement_getTransformToElement_Callback";

  @DomName('SVGGElement.requiredExtensions')
  @DocsEditable
  StringList get requiredExtensions native "SVGGElement_requiredExtensions_Getter";

  @DomName('SVGGElement.requiredFeatures')
  @DocsEditable
  StringList get requiredFeatures native "SVGGElement_requiredFeatures_Getter";

  @DomName('SVGGElement.systemLanguage')
  @DocsEditable
  StringList get systemLanguage native "SVGGElement_systemLanguage_Getter";

  @DomName('SVGGElement.hasExtension')
  @DocsEditable
  bool hasExtension(String extension) native "SVGGElement_hasExtension_Callback";

  @DomName('SVGGElement.transform')
  @DocsEditable
  AnimatedTransformList get transform native "SVGGElement_transform_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGImageElement')
class ImageElement extends StyledElement implements UriReference, Tests, Transformable, ExternalResourcesRequired, LangSpace {
  ImageElement.internal() : super.internal();

  @DomName('SVGImageElement.SVGImageElement')
  @DocsEditable
  factory ImageElement() => _SvgElementFactoryProvider.createSvgElement_tag("image");

  @DomName('SVGImageElement.height')
  @DocsEditable
  AnimatedLength get height native "SVGImageElement_height_Getter";

  @DomName('SVGImageElement.preserveAspectRatio')
  @DocsEditable
  AnimatedPreserveAspectRatio get preserveAspectRatio native "SVGImageElement_preserveAspectRatio_Getter";

  @DomName('SVGImageElement.width')
  @DocsEditable
  AnimatedLength get width native "SVGImageElement_width_Getter";

  @DomName('SVGImageElement.x')
  @DocsEditable
  AnimatedLength get x native "SVGImageElement_x_Getter";

  @DomName('SVGImageElement.y')
  @DocsEditable
  AnimatedLength get y native "SVGImageElement_y_Getter";

  @DomName('SVGImageElement.externalResourcesRequired')
  @DocsEditable
  AnimatedBoolean get externalResourcesRequired native "SVGImageElement_externalResourcesRequired_Getter";

  @DomName('SVGImageElement.xmllang')
  @DocsEditable
  String get xmllang native "SVGImageElement_xmllang_Getter";

  @DomName('SVGImageElement.xmllang')
  @DocsEditable
  void set xmllang(String value) native "SVGImageElement_xmllang_Setter";

  @DomName('SVGImageElement.xmlspace')
  @DocsEditable
  String get xmlspace native "SVGImageElement_xmlspace_Getter";

  @DomName('SVGImageElement.xmlspace')
  @DocsEditable
  void set xmlspace(String value) native "SVGImageElement_xmlspace_Setter";

  @DomName('SVGImageElement.farthestViewportElement')
  @DocsEditable
  SvgElement get farthestViewportElement native "SVGImageElement_farthestViewportElement_Getter";

  @DomName('SVGImageElement.nearestViewportElement')
  @DocsEditable
  SvgElement get nearestViewportElement native "SVGImageElement_nearestViewportElement_Getter";

  @DomName('SVGImageElement.getBBox')
  @DocsEditable
  Rect getBBox() native "SVGImageElement_getBBox_Callback";

  @DomName('SVGImageElement.getCTM')
  @DocsEditable
  Matrix getCtm() native "SVGImageElement_getCTM_Callback";

  @DomName('SVGImageElement.getScreenCTM')
  @DocsEditable
  Matrix getScreenCtm() native "SVGImageElement_getScreenCTM_Callback";

  @DomName('SVGImageElement.getTransformToElement')
  @DocsEditable
  Matrix getTransformToElement(SvgElement element) native "SVGImageElement_getTransformToElement_Callback";

  @DomName('SVGImageElement.requiredExtensions')
  @DocsEditable
  StringList get requiredExtensions native "SVGImageElement_requiredExtensions_Getter";

  @DomName('SVGImageElement.requiredFeatures')
  @DocsEditable
  StringList get requiredFeatures native "SVGImageElement_requiredFeatures_Getter";

  @DomName('SVGImageElement.systemLanguage')
  @DocsEditable
  StringList get systemLanguage native "SVGImageElement_systemLanguage_Getter";

  @DomName('SVGImageElement.hasExtension')
  @DocsEditable
  bool hasExtension(String extension) native "SVGImageElement_hasExtension_Callback";

  @DomName('SVGImageElement.transform')
  @DocsEditable
  AnimatedTransformList get transform native "SVGImageElement_transform_Getter";

  @DomName('SVGImageElement.href')
  @DocsEditable
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

  /// Checks if this type is supported on the current platform.
  static bool supported(SvgElement element) => true;

  @DomName('SVGLangSpace.xmllang')
  @DocsEditable
  String get xmllang native "SVGLangSpace_xmllang_Getter";

  @DomName('SVGLangSpace.xmllang')
  @DocsEditable
  void set xmllang(String value) native "SVGLangSpace_xmllang_Setter";

  @DomName('SVGLangSpace.xmlspace')
  @DocsEditable
  String get xmlspace native "SVGLangSpace_xmlspace_Getter";

  @DomName('SVGLangSpace.xmlspace')
  @DocsEditable
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

  @DomName('SVGLength.unitType')
  @DocsEditable
  int get unitType native "SVGLength_unitType_Getter";

  @DomName('SVGLength.value')
  @DocsEditable
  num get value native "SVGLength_value_Getter";

  @DomName('SVGLength.value')
  @DocsEditable
  void set value(num value) native "SVGLength_value_Setter";

  @DomName('SVGLength.valueAsString')
  @DocsEditable
  String get valueAsString native "SVGLength_valueAsString_Getter";

  @DomName('SVGLength.valueAsString')
  @DocsEditable
  void set valueAsString(String value) native "SVGLength_valueAsString_Setter";

  @DomName('SVGLength.valueInSpecifiedUnits')
  @DocsEditable
  num get valueInSpecifiedUnits native "SVGLength_valueInSpecifiedUnits_Getter";

  @DomName('SVGLength.valueInSpecifiedUnits')
  @DocsEditable
  void set valueInSpecifiedUnits(num value) native "SVGLength_valueInSpecifiedUnits_Setter";

  @DomName('SVGLength.convertToSpecifiedUnits')
  @DocsEditable
  void convertToSpecifiedUnits(int unitType) native "SVGLength_convertToSpecifiedUnits_Callback";

  @DomName('SVGLength.newValueSpecifiedUnits')
  @DocsEditable
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

  @DomName('SVGLengthList.numberOfItems')
  @DocsEditable
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
  Length reduce(Length combine(Length value, Length element)) {
    return IterableMixinWorkaround.reduce(this, combine);
  }

  dynamic fold(dynamic initialValue,
               dynamic combine(dynamic previousValue, Length element)) {
    return IterableMixinWorkaround.fold(this, initialValue, combine);
  }

  bool contains(Length element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(Length element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator = ""]) =>
      IterableMixinWorkaround.joinList(this, separator);

  Iterable map(f(Length element)) =>
      IterableMixinWorkaround.mapList(this, f);

  Iterable<Length> where(bool f(Length element)) =>
      IterableMixinWorkaround.where(this, f);

  Iterable expand(Iterable f(Length element)) =>
      IterableMixinWorkaround.expand(this, f);

  bool every(bool f(Length element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(Length element)) => IterableMixinWorkaround.any(this, f);

  List<Length> toList({ bool growable: true }) =>
      new List<Length>.from(this, growable: growable);

  Set<Length> toSet() => new Set<Length>.from(this);

  bool get isEmpty => this.length == 0;

  Iterable<Length> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<Length> takeWhile(bool test(Length value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  Iterable<Length> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<Length> skipWhile(bool test(Length value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  Length firstWhere(bool test(Length value), { Length orElse() }) {
    return IterableMixinWorkaround.firstWhere(this, test, orElse);
  }

  Length lastWhere(bool test(Length value), {Length orElse()}) {
    return IterableMixinWorkaround.lastWhereList(this, test, orElse);
  }

  Length singleWhere(bool test(Length value)) {
    return IterableMixinWorkaround.singleWhere(this, test);
  }

  Length elementAt(int index) {
    return this[index];
  }

  // From Collection<Length>:

  void add(Length value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<Length> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<Length>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  // clear() defined by IDL.

  Iterable<Length> get reversed {
    return IterableMixinWorkaround.reversedList(this);
  }

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

  void insert(int index, Length element) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void insertAll(int index, Iterable<Length> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void setAll(int index, Iterable<Length> iterable) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }

  Length removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  Length removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeWhere(bool test(Length element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainWhere(bool test(Length element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int end, Iterable<Length> iterable, [int skipCount]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int end) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void replaceRange(int start, int end, Iterable<Length> iterable) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }

  void fillRange(int start, int end, [Length fillValue]) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }

  Iterable<Length> getRange(int start, int end) =>
    IterableMixinWorkaround.getRangeList(this, start, end);

  List<Length> sublist(int start, [int end]) {
    if (end == null) end = length;
    return Lists.getRange(this, start, end, <Length>[]);
  }

  Map<int, Length> asMap() =>
    IterableMixinWorkaround.asMapList(this);

  String toString() {
    StringBuffer buffer = new StringBuffer('[');
    buffer.writeAll(this, ', ');
    buffer.write(']');
    return buffer.toString();
  }

  // -- end List<Length> mixins.

  @DomName('SVGLengthList.appendItem')
  @DocsEditable
  Length appendItem(Length item) native "SVGLengthList_appendItem_Callback";

  @DomName('SVGLengthList.clear')
  @DocsEditable
  void clear() native "SVGLengthList_clear_Callback";

  @DomName('SVGLengthList.getItem')
  @DocsEditable
  Length getItem(int index) native "SVGLengthList_getItem_Callback";

  @DomName('SVGLengthList.initialize')
  @DocsEditable
  Length initialize(Length item) native "SVGLengthList_initialize_Callback";

  @DomName('SVGLengthList.insertItemBefore')
  @DocsEditable
  Length insertItemBefore(Length item, int index) native "SVGLengthList_insertItemBefore_Callback";

  @DomName('SVGLengthList.removeItem')
  @DocsEditable
  Length removeItem(int index) native "SVGLengthList_removeItem_Callback";

  @DomName('SVGLengthList.replaceItem')
  @DocsEditable
  Length replaceItem(Length item, int index) native "SVGLengthList_replaceItem_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGLineElement')
class LineElement extends StyledElement implements Transformable, Tests, ExternalResourcesRequired, LangSpace {
  LineElement.internal() : super.internal();

  @DomName('SVGLineElement.SVGLineElement')
  @DocsEditable
  factory LineElement() => _SvgElementFactoryProvider.createSvgElement_tag("line");

  @DomName('SVGLineElement.x1')
  @DocsEditable
  AnimatedLength get x1 native "SVGLineElement_x1_Getter";

  @DomName('SVGLineElement.x2')
  @DocsEditable
  AnimatedLength get x2 native "SVGLineElement_x2_Getter";

  @DomName('SVGLineElement.y1')
  @DocsEditable
  AnimatedLength get y1 native "SVGLineElement_y1_Getter";

  @DomName('SVGLineElement.y2')
  @DocsEditable
  AnimatedLength get y2 native "SVGLineElement_y2_Getter";

  @DomName('SVGLineElement.externalResourcesRequired')
  @DocsEditable
  AnimatedBoolean get externalResourcesRequired native "SVGLineElement_externalResourcesRequired_Getter";

  @DomName('SVGLineElement.xmllang')
  @DocsEditable
  String get xmllang native "SVGLineElement_xmllang_Getter";

  @DomName('SVGLineElement.xmllang')
  @DocsEditable
  void set xmllang(String value) native "SVGLineElement_xmllang_Setter";

  @DomName('SVGLineElement.xmlspace')
  @DocsEditable
  String get xmlspace native "SVGLineElement_xmlspace_Getter";

  @DomName('SVGLineElement.xmlspace')
  @DocsEditable
  void set xmlspace(String value) native "SVGLineElement_xmlspace_Setter";

  @DomName('SVGLineElement.farthestViewportElement')
  @DocsEditable
  SvgElement get farthestViewportElement native "SVGLineElement_farthestViewportElement_Getter";

  @DomName('SVGLineElement.nearestViewportElement')
  @DocsEditable
  SvgElement get nearestViewportElement native "SVGLineElement_nearestViewportElement_Getter";

  @DomName('SVGLineElement.getBBox')
  @DocsEditable
  Rect getBBox() native "SVGLineElement_getBBox_Callback";

  @DomName('SVGLineElement.getCTM')
  @DocsEditable
  Matrix getCtm() native "SVGLineElement_getCTM_Callback";

  @DomName('SVGLineElement.getScreenCTM')
  @DocsEditable
  Matrix getScreenCtm() native "SVGLineElement_getScreenCTM_Callback";

  @DomName('SVGLineElement.getTransformToElement')
  @DocsEditable
  Matrix getTransformToElement(SvgElement element) native "SVGLineElement_getTransformToElement_Callback";

  @DomName('SVGLineElement.requiredExtensions')
  @DocsEditable
  StringList get requiredExtensions native "SVGLineElement_requiredExtensions_Getter";

  @DomName('SVGLineElement.requiredFeatures')
  @DocsEditable
  StringList get requiredFeatures native "SVGLineElement_requiredFeatures_Getter";

  @DomName('SVGLineElement.systemLanguage')
  @DocsEditable
  StringList get systemLanguage native "SVGLineElement_systemLanguage_Getter";

  @DomName('SVGLineElement.hasExtension')
  @DocsEditable
  bool hasExtension(String extension) native "SVGLineElement_hasExtension_Callback";

  @DomName('SVGLineElement.transform')
  @DocsEditable
  AnimatedTransformList get transform native "SVGLineElement_transform_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGLinearGradientElement')
class LinearGradientElement extends _GradientElement {
  LinearGradientElement.internal() : super.internal();

  @DomName('SVGLinearGradientElement.SVGLinearGradientElement')
  @DocsEditable
  factory LinearGradientElement() => _SvgElementFactoryProvider.createSvgElement_tag("linearGradient");

  @DomName('SVGLinearGradientElement.x1')
  @DocsEditable
  AnimatedLength get x1 native "SVGLinearGradientElement_x1_Getter";

  @DomName('SVGLinearGradientElement.x2')
  @DocsEditable
  AnimatedLength get x2 native "SVGLinearGradientElement_x2_Getter";

  @DomName('SVGLinearGradientElement.y1')
  @DocsEditable
  AnimatedLength get y1 native "SVGLinearGradientElement_y1_Getter";

  @DomName('SVGLinearGradientElement.y2')
  @DocsEditable
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

  @DomName('SVGLocatable.farthestViewportElement')
  @DocsEditable
  SvgElement get farthestViewportElement native "SVGLocatable_farthestViewportElement_Getter";

  @DomName('SVGLocatable.nearestViewportElement')
  @DocsEditable
  SvgElement get nearestViewportElement native "SVGLocatable_nearestViewportElement_Getter";

  @DomName('SVGLocatable.getBBox')
  @DocsEditable
  Rect getBBox() native "SVGLocatable_getBBox_Callback";

  @DomName('SVGLocatable.getCTM')
  @DocsEditable
  Matrix getCtm() native "SVGLocatable_getCTM_Callback";

  @DomName('SVGLocatable.getScreenCTM')
  @DocsEditable
  Matrix getScreenCtm() native "SVGLocatable_getScreenCTM_Callback";

  @DomName('SVGLocatable.getTransformToElement')
  @DocsEditable
  Matrix getTransformToElement(SvgElement element) native "SVGLocatable_getTransformToElement_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGMarkerElement')
class MarkerElement extends StyledElement implements FitToViewBox, ExternalResourcesRequired, LangSpace {
  MarkerElement.internal() : super.internal();

  @DomName('SVGMarkerElement.SVGMarkerElement')
  @DocsEditable
  factory MarkerElement() => _SvgElementFactoryProvider.createSvgElement_tag("marker");

  static const int SVG_MARKERUNITS_STROKEWIDTH = 2;

  static const int SVG_MARKERUNITS_UNKNOWN = 0;

  static const int SVG_MARKERUNITS_USERSPACEONUSE = 1;

  static const int SVG_MARKER_ORIENT_ANGLE = 2;

  static const int SVG_MARKER_ORIENT_AUTO = 1;

  static const int SVG_MARKER_ORIENT_UNKNOWN = 0;

  @DomName('SVGMarkerElement.markerHeight')
  @DocsEditable
  AnimatedLength get markerHeight native "SVGMarkerElement_markerHeight_Getter";

  @DomName('SVGMarkerElement.markerUnits')
  @DocsEditable
  AnimatedEnumeration get markerUnits native "SVGMarkerElement_markerUnits_Getter";

  @DomName('SVGMarkerElement.markerWidth')
  @DocsEditable
  AnimatedLength get markerWidth native "SVGMarkerElement_markerWidth_Getter";

  @DomName('SVGMarkerElement.orientAngle')
  @DocsEditable
  AnimatedAngle get orientAngle native "SVGMarkerElement_orientAngle_Getter";

  @DomName('SVGMarkerElement.orientType')
  @DocsEditable
  AnimatedEnumeration get orientType native "SVGMarkerElement_orientType_Getter";

  @DomName('SVGMarkerElement.refX')
  @DocsEditable
  AnimatedLength get refX native "SVGMarkerElement_refX_Getter";

  @DomName('SVGMarkerElement.refY')
  @DocsEditable
  AnimatedLength get refY native "SVGMarkerElement_refY_Getter";

  @DomName('SVGMarkerElement.setOrientToAngle')
  @DocsEditable
  void setOrientToAngle(Angle angle) native "SVGMarkerElement_setOrientToAngle_Callback";

  @DomName('SVGMarkerElement.setOrientToAuto')
  @DocsEditable
  void setOrientToAuto() native "SVGMarkerElement_setOrientToAuto_Callback";

  @DomName('SVGMarkerElement.externalResourcesRequired')
  @DocsEditable
  AnimatedBoolean get externalResourcesRequired native "SVGMarkerElement_externalResourcesRequired_Getter";

  @DomName('SVGMarkerElement.preserveAspectRatio')
  @DocsEditable
  AnimatedPreserveAspectRatio get preserveAspectRatio native "SVGMarkerElement_preserveAspectRatio_Getter";

  @DomName('SVGMarkerElement.viewBox')
  @DocsEditable
  AnimatedRect get viewBox native "SVGMarkerElement_viewBox_Getter";

  @DomName('SVGMarkerElement.xmllang')
  @DocsEditable
  String get xmllang native "SVGMarkerElement_xmllang_Getter";

  @DomName('SVGMarkerElement.xmllang')
  @DocsEditable
  void set xmllang(String value) native "SVGMarkerElement_xmllang_Setter";

  @DomName('SVGMarkerElement.xmlspace')
  @DocsEditable
  String get xmlspace native "SVGMarkerElement_xmlspace_Getter";

  @DomName('SVGMarkerElement.xmlspace')
  @DocsEditable
  void set xmlspace(String value) native "SVGMarkerElement_xmlspace_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGMaskElement')
class MaskElement extends StyledElement implements Tests, ExternalResourcesRequired, LangSpace {
  MaskElement.internal() : super.internal();

  @DomName('SVGMaskElement.SVGMaskElement')
  @DocsEditable
  factory MaskElement() => _SvgElementFactoryProvider.createSvgElement_tag("mask");

  @DomName('SVGMaskElement.height')
  @DocsEditable
  AnimatedLength get height native "SVGMaskElement_height_Getter";

  @DomName('SVGMaskElement.maskContentUnits')
  @DocsEditable
  AnimatedEnumeration get maskContentUnits native "SVGMaskElement_maskContentUnits_Getter";

  @DomName('SVGMaskElement.maskUnits')
  @DocsEditable
  AnimatedEnumeration get maskUnits native "SVGMaskElement_maskUnits_Getter";

  @DomName('SVGMaskElement.width')
  @DocsEditable
  AnimatedLength get width native "SVGMaskElement_width_Getter";

  @DomName('SVGMaskElement.x')
  @DocsEditable
  AnimatedLength get x native "SVGMaskElement_x_Getter";

  @DomName('SVGMaskElement.y')
  @DocsEditable
  AnimatedLength get y native "SVGMaskElement_y_Getter";

  @DomName('SVGMaskElement.externalResourcesRequired')
  @DocsEditable
  AnimatedBoolean get externalResourcesRequired native "SVGMaskElement_externalResourcesRequired_Getter";

  @DomName('SVGMaskElement.xmllang')
  @DocsEditable
  String get xmllang native "SVGMaskElement_xmllang_Getter";

  @DomName('SVGMaskElement.xmllang')
  @DocsEditable
  void set xmllang(String value) native "SVGMaskElement_xmllang_Setter";

  @DomName('SVGMaskElement.xmlspace')
  @DocsEditable
  String get xmlspace native "SVGMaskElement_xmlspace_Getter";

  @DomName('SVGMaskElement.xmlspace')
  @DocsEditable
  void set xmlspace(String value) native "SVGMaskElement_xmlspace_Setter";

  @DomName('SVGMaskElement.requiredExtensions')
  @DocsEditable
  StringList get requiredExtensions native "SVGMaskElement_requiredExtensions_Getter";

  @DomName('SVGMaskElement.requiredFeatures')
  @DocsEditable
  StringList get requiredFeatures native "SVGMaskElement_requiredFeatures_Getter";

  @DomName('SVGMaskElement.systemLanguage')
  @DocsEditable
  StringList get systemLanguage native "SVGMaskElement_systemLanguage_Getter";

  @DomName('SVGMaskElement.hasExtension')
  @DocsEditable
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

  @DomName('SVGMatrix.a')
  @DocsEditable
  num get a native "SVGMatrix_a_Getter";

  @DomName('SVGMatrix.a')
  @DocsEditable
  void set a(num value) native "SVGMatrix_a_Setter";

  @DomName('SVGMatrix.b')
  @DocsEditable
  num get b native "SVGMatrix_b_Getter";

  @DomName('SVGMatrix.b')
  @DocsEditable
  void set b(num value) native "SVGMatrix_b_Setter";

  @DomName('SVGMatrix.c')
  @DocsEditable
  num get c native "SVGMatrix_c_Getter";

  @DomName('SVGMatrix.c')
  @DocsEditable
  void set c(num value) native "SVGMatrix_c_Setter";

  @DomName('SVGMatrix.d')
  @DocsEditable
  num get d native "SVGMatrix_d_Getter";

  @DomName('SVGMatrix.d')
  @DocsEditable
  void set d(num value) native "SVGMatrix_d_Setter";

  @DomName('SVGMatrix.e')
  @DocsEditable
  num get e native "SVGMatrix_e_Getter";

  @DomName('SVGMatrix.e')
  @DocsEditable
  void set e(num value) native "SVGMatrix_e_Setter";

  @DomName('SVGMatrix.f')
  @DocsEditable
  num get f native "SVGMatrix_f_Getter";

  @DomName('SVGMatrix.f')
  @DocsEditable
  void set f(num value) native "SVGMatrix_f_Setter";

  @DomName('SVGMatrix.flipX')
  @DocsEditable
  Matrix flipX() native "SVGMatrix_flipX_Callback";

  @DomName('SVGMatrix.flipY')
  @DocsEditable
  Matrix flipY() native "SVGMatrix_flipY_Callback";

  @DomName('SVGMatrix.inverse')
  @DocsEditable
  Matrix inverse() native "SVGMatrix_inverse_Callback";

  @DomName('SVGMatrix.multiply')
  @DocsEditable
  Matrix multiply(Matrix secondMatrix) native "SVGMatrix_multiply_Callback";

  @DomName('SVGMatrix.rotate')
  @DocsEditable
  Matrix rotate(num angle) native "SVGMatrix_rotate_Callback";

  @DomName('SVGMatrix.rotateFromVector')
  @DocsEditable
  Matrix rotateFromVector(num x, num y) native "SVGMatrix_rotateFromVector_Callback";

  @DomName('SVGMatrix.scale')
  @DocsEditable
  Matrix scale(num scaleFactor) native "SVGMatrix_scale_Callback";

  @DomName('SVGMatrix.scaleNonUniform')
  @DocsEditable
  Matrix scaleNonUniform(num scaleFactorX, num scaleFactorY) native "SVGMatrix_scaleNonUniform_Callback";

  @DomName('SVGMatrix.skewX')
  @DocsEditable
  Matrix skewX(num angle) native "SVGMatrix_skewX_Callback";

  @DomName('SVGMatrix.skewY')
  @DocsEditable
  Matrix skewY(num angle) native "SVGMatrix_skewY_Callback";

  @DomName('SVGMatrix.translate')
  @DocsEditable
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
@DomName('SVGNumber')
class Number extends NativeFieldWrapperClass1 {
  Number.internal();

  @DomName('SVGNumber.value')
  @DocsEditable
  num get value native "SVGNumber_value_Getter";

  @DomName('SVGNumber.value')
  @DocsEditable
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

  @DomName('SVGNumberList.numberOfItems')
  @DocsEditable
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
  Number reduce(Number combine(Number value, Number element)) {
    return IterableMixinWorkaround.reduce(this, combine);
  }

  dynamic fold(dynamic initialValue,
               dynamic combine(dynamic previousValue, Number element)) {
    return IterableMixinWorkaround.fold(this, initialValue, combine);
  }

  bool contains(Number element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(Number element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator = ""]) =>
      IterableMixinWorkaround.joinList(this, separator);

  Iterable map(f(Number element)) =>
      IterableMixinWorkaround.mapList(this, f);

  Iterable<Number> where(bool f(Number element)) =>
      IterableMixinWorkaround.where(this, f);

  Iterable expand(Iterable f(Number element)) =>
      IterableMixinWorkaround.expand(this, f);

  bool every(bool f(Number element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(Number element)) => IterableMixinWorkaround.any(this, f);

  List<Number> toList({ bool growable: true }) =>
      new List<Number>.from(this, growable: growable);

  Set<Number> toSet() => new Set<Number>.from(this);

  bool get isEmpty => this.length == 0;

  Iterable<Number> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<Number> takeWhile(bool test(Number value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  Iterable<Number> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<Number> skipWhile(bool test(Number value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  Number firstWhere(bool test(Number value), { Number orElse() }) {
    return IterableMixinWorkaround.firstWhere(this, test, orElse);
  }

  Number lastWhere(bool test(Number value), {Number orElse()}) {
    return IterableMixinWorkaround.lastWhereList(this, test, orElse);
  }

  Number singleWhere(bool test(Number value)) {
    return IterableMixinWorkaround.singleWhere(this, test);
  }

  Number elementAt(int index) {
    return this[index];
  }

  // From Collection<Number>:

  void add(Number value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<Number> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<Number>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  // clear() defined by IDL.

  Iterable<Number> get reversed {
    return IterableMixinWorkaround.reversedList(this);
  }

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

  void insert(int index, Number element) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void insertAll(int index, Iterable<Number> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void setAll(int index, Iterable<Number> iterable) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }

  Number removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  Number removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeWhere(bool test(Number element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainWhere(bool test(Number element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int end, Iterable<Number> iterable, [int skipCount]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int end) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void replaceRange(int start, int end, Iterable<Number> iterable) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }

  void fillRange(int start, int end, [Number fillValue]) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }

  Iterable<Number> getRange(int start, int end) =>
    IterableMixinWorkaround.getRangeList(this, start, end);

  List<Number> sublist(int start, [int end]) {
    if (end == null) end = length;
    return Lists.getRange(this, start, end, <Number>[]);
  }

  Map<int, Number> asMap() =>
    IterableMixinWorkaround.asMapList(this);

  String toString() {
    StringBuffer buffer = new StringBuffer('[');
    buffer.writeAll(this, ', ');
    buffer.write(']');
    return buffer.toString();
  }

  // -- end List<Number> mixins.

  @DomName('SVGNumberList.appendItem')
  @DocsEditable
  Number appendItem(Number item) native "SVGNumberList_appendItem_Callback";

  @DomName('SVGNumberList.clear')
  @DocsEditable
  void clear() native "SVGNumberList_clear_Callback";

  @DomName('SVGNumberList.getItem')
  @DocsEditable
  Number getItem(int index) native "SVGNumberList_getItem_Callback";

  @DomName('SVGNumberList.initialize')
  @DocsEditable
  Number initialize(Number item) native "SVGNumberList_initialize_Callback";

  @DomName('SVGNumberList.insertItemBefore')
  @DocsEditable
  Number insertItemBefore(Number item, int index) native "SVGNumberList_insertItemBefore_Callback";

  @DomName('SVGNumberList.removeItem')
  @DocsEditable
  Number removeItem(int index) native "SVGNumberList_removeItem_Callback";

  @DomName('SVGNumberList.replaceItem')
  @DocsEditable
  Number replaceItem(Number item, int index) native "SVGNumberList_replaceItem_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGPathElement')
class PathElement extends StyledElement implements Transformable, Tests, ExternalResourcesRequired, LangSpace {
  PathElement.internal() : super.internal();

  @DomName('SVGPathElement.SVGPathElement')
  @DocsEditable
  factory PathElement() => _SvgElementFactoryProvider.createSvgElement_tag("path");

  @DomName('SVGPathElement.animatedNormalizedPathSegList')
  @DocsEditable
  PathSegList get animatedNormalizedPathSegList native "SVGPathElement_animatedNormalizedPathSegList_Getter";

  @DomName('SVGPathElement.animatedPathSegList')
  @DocsEditable
  PathSegList get animatedPathSegList native "SVGPathElement_animatedPathSegList_Getter";

  @DomName('SVGPathElement.normalizedPathSegList')
  @DocsEditable
  PathSegList get normalizedPathSegList native "SVGPathElement_normalizedPathSegList_Getter";

  @DomName('SVGPathElement.pathLength')
  @DocsEditable
  AnimatedNumber get pathLength native "SVGPathElement_pathLength_Getter";

  @DomName('SVGPathElement.pathSegList')
  @DocsEditable
  PathSegList get pathSegList native "SVGPathElement_pathSegList_Getter";

  @DomName('SVGPathElement.createSVGPathSegArcAbs')
  @DocsEditable
  PathSegArcAbs createSvgPathSegArcAbs(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) native "SVGPathElement_createSVGPathSegArcAbs_Callback";

  @DomName('SVGPathElement.createSVGPathSegArcRel')
  @DocsEditable
  PathSegArcRel createSvgPathSegArcRel(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) native "SVGPathElement_createSVGPathSegArcRel_Callback";

  @DomName('SVGPathElement.createSVGPathSegClosePath')
  @DocsEditable
  PathSegClosePath createSvgPathSegClosePath() native "SVGPathElement_createSVGPathSegClosePath_Callback";

  @DomName('SVGPathElement.createSVGPathSegCurvetoCubicAbs')
  @DocsEditable
  PathSegCurvetoCubicAbs createSvgPathSegCurvetoCubicAbs(num x, num y, num x1, num y1, num x2, num y2) native "SVGPathElement_createSVGPathSegCurvetoCubicAbs_Callback";

  @DomName('SVGPathElement.createSVGPathSegCurvetoCubicRel')
  @DocsEditable
  PathSegCurvetoCubicRel createSvgPathSegCurvetoCubicRel(num x, num y, num x1, num y1, num x2, num y2) native "SVGPathElement_createSVGPathSegCurvetoCubicRel_Callback";

  @DomName('SVGPathElement.createSVGPathSegCurvetoCubicSmoothAbs')
  @DocsEditable
  PathSegCurvetoCubicSmoothAbs createSvgPathSegCurvetoCubicSmoothAbs(num x, num y, num x2, num y2) native "SVGPathElement_createSVGPathSegCurvetoCubicSmoothAbs_Callback";

  @DomName('SVGPathElement.createSVGPathSegCurvetoCubicSmoothRel')
  @DocsEditable
  PathSegCurvetoCubicSmoothRel createSvgPathSegCurvetoCubicSmoothRel(num x, num y, num x2, num y2) native "SVGPathElement_createSVGPathSegCurvetoCubicSmoothRel_Callback";

  @DomName('SVGPathElement.createSVGPathSegCurvetoQuadraticAbs')
  @DocsEditable
  PathSegCurvetoQuadraticAbs createSvgPathSegCurvetoQuadraticAbs(num x, num y, num x1, num y1) native "SVGPathElement_createSVGPathSegCurvetoQuadraticAbs_Callback";

  @DomName('SVGPathElement.createSVGPathSegCurvetoQuadraticRel')
  @DocsEditable
  PathSegCurvetoQuadraticRel createSvgPathSegCurvetoQuadraticRel(num x, num y, num x1, num y1) native "SVGPathElement_createSVGPathSegCurvetoQuadraticRel_Callback";

  @DomName('SVGPathElement.createSVGPathSegCurvetoQuadraticSmoothAbs')
  @DocsEditable
  PathSegCurvetoQuadraticSmoothAbs createSvgPathSegCurvetoQuadraticSmoothAbs(num x, num y) native "SVGPathElement_createSVGPathSegCurvetoQuadraticSmoothAbs_Callback";

  @DomName('SVGPathElement.createSVGPathSegCurvetoQuadraticSmoothRel')
  @DocsEditable
  PathSegCurvetoQuadraticSmoothRel createSvgPathSegCurvetoQuadraticSmoothRel(num x, num y) native "SVGPathElement_createSVGPathSegCurvetoQuadraticSmoothRel_Callback";

  @DomName('SVGPathElement.createSVGPathSegLinetoAbs')
  @DocsEditable
  PathSegLinetoAbs createSvgPathSegLinetoAbs(num x, num y) native "SVGPathElement_createSVGPathSegLinetoAbs_Callback";

  @DomName('SVGPathElement.createSVGPathSegLinetoHorizontalAbs')
  @DocsEditable
  PathSegLinetoHorizontalAbs createSvgPathSegLinetoHorizontalAbs(num x) native "SVGPathElement_createSVGPathSegLinetoHorizontalAbs_Callback";

  @DomName('SVGPathElement.createSVGPathSegLinetoHorizontalRel')
  @DocsEditable
  PathSegLinetoHorizontalRel createSvgPathSegLinetoHorizontalRel(num x) native "SVGPathElement_createSVGPathSegLinetoHorizontalRel_Callback";

  @DomName('SVGPathElement.createSVGPathSegLinetoRel')
  @DocsEditable
  PathSegLinetoRel createSvgPathSegLinetoRel(num x, num y) native "SVGPathElement_createSVGPathSegLinetoRel_Callback";

  @DomName('SVGPathElement.createSVGPathSegLinetoVerticalAbs')
  @DocsEditable
  PathSegLinetoVerticalAbs createSvgPathSegLinetoVerticalAbs(num y) native "SVGPathElement_createSVGPathSegLinetoVerticalAbs_Callback";

  @DomName('SVGPathElement.createSVGPathSegLinetoVerticalRel')
  @DocsEditable
  PathSegLinetoVerticalRel createSvgPathSegLinetoVerticalRel(num y) native "SVGPathElement_createSVGPathSegLinetoVerticalRel_Callback";

  @DomName('SVGPathElement.createSVGPathSegMovetoAbs')
  @DocsEditable
  PathSegMovetoAbs createSvgPathSegMovetoAbs(num x, num y) native "SVGPathElement_createSVGPathSegMovetoAbs_Callback";

  @DomName('SVGPathElement.createSVGPathSegMovetoRel')
  @DocsEditable
  PathSegMovetoRel createSvgPathSegMovetoRel(num x, num y) native "SVGPathElement_createSVGPathSegMovetoRel_Callback";

  @DomName('SVGPathElement.getPathSegAtLength')
  @DocsEditable
  int getPathSegAtLength(num distance) native "SVGPathElement_getPathSegAtLength_Callback";

  @DomName('SVGPathElement.getPointAtLength')
  @DocsEditable
  Point getPointAtLength(num distance) native "SVGPathElement_getPointAtLength_Callback";

  @DomName('SVGPathElement.getTotalLength')
  @DocsEditable
  num getTotalLength() native "SVGPathElement_getTotalLength_Callback";

  @DomName('SVGPathElement.externalResourcesRequired')
  @DocsEditable
  AnimatedBoolean get externalResourcesRequired native "SVGPathElement_externalResourcesRequired_Getter";

  @DomName('SVGPathElement.xmllang')
  @DocsEditable
  String get xmllang native "SVGPathElement_xmllang_Getter";

  @DomName('SVGPathElement.xmllang')
  @DocsEditable
  void set xmllang(String value) native "SVGPathElement_xmllang_Setter";

  @DomName('SVGPathElement.xmlspace')
  @DocsEditable
  String get xmlspace native "SVGPathElement_xmlspace_Getter";

  @DomName('SVGPathElement.xmlspace')
  @DocsEditable
  void set xmlspace(String value) native "SVGPathElement_xmlspace_Setter";

  @DomName('SVGPathElement.farthestViewportElement')
  @DocsEditable
  SvgElement get farthestViewportElement native "SVGPathElement_farthestViewportElement_Getter";

  @DomName('SVGPathElement.nearestViewportElement')
  @DocsEditable
  SvgElement get nearestViewportElement native "SVGPathElement_nearestViewportElement_Getter";

  @DomName('SVGPathElement.getBBox')
  @DocsEditable
  Rect getBBox() native "SVGPathElement_getBBox_Callback";

  @DomName('SVGPathElement.getCTM')
  @DocsEditable
  Matrix getCtm() native "SVGPathElement_getCTM_Callback";

  @DomName('SVGPathElement.getScreenCTM')
  @DocsEditable
  Matrix getScreenCtm() native "SVGPathElement_getScreenCTM_Callback";

  @DomName('SVGPathElement.getTransformToElement')
  @DocsEditable
  Matrix getTransformToElement(SvgElement element) native "SVGPathElement_getTransformToElement_Callback";

  @DomName('SVGPathElement.requiredExtensions')
  @DocsEditable
  StringList get requiredExtensions native "SVGPathElement_requiredExtensions_Getter";

  @DomName('SVGPathElement.requiredFeatures')
  @DocsEditable
  StringList get requiredFeatures native "SVGPathElement_requiredFeatures_Getter";

  @DomName('SVGPathElement.systemLanguage')
  @DocsEditable
  StringList get systemLanguage native "SVGPathElement_systemLanguage_Getter";

  @DomName('SVGPathElement.hasExtension')
  @DocsEditable
  bool hasExtension(String extension) native "SVGPathElement_hasExtension_Callback";

  @DomName('SVGPathElement.transform')
  @DocsEditable
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

  @DomName('SVGPathSeg.pathSegType')
  @DocsEditable
  int get pathSegType native "SVGPathSeg_pathSegType_Getter";

  @DomName('SVGPathSeg.pathSegTypeAsLetter')
  @DocsEditable
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

  @DomName('SVGPathSegArcAbs.angle')
  @DocsEditable
  num get angle native "SVGPathSegArcAbs_angle_Getter";

  @DomName('SVGPathSegArcAbs.angle')
  @DocsEditable
  void set angle(num value) native "SVGPathSegArcAbs_angle_Setter";

  @DomName('SVGPathSegArcAbs.largeArcFlag')
  @DocsEditable
  bool get largeArcFlag native "SVGPathSegArcAbs_largeArcFlag_Getter";

  @DomName('SVGPathSegArcAbs.largeArcFlag')
  @DocsEditable
  void set largeArcFlag(bool value) native "SVGPathSegArcAbs_largeArcFlag_Setter";

  @DomName('SVGPathSegArcAbs.r1')
  @DocsEditable
  num get r1 native "SVGPathSegArcAbs_r1_Getter";

  @DomName('SVGPathSegArcAbs.r1')
  @DocsEditable
  void set r1(num value) native "SVGPathSegArcAbs_r1_Setter";

  @DomName('SVGPathSegArcAbs.r2')
  @DocsEditable
  num get r2 native "SVGPathSegArcAbs_r2_Getter";

  @DomName('SVGPathSegArcAbs.r2')
  @DocsEditable
  void set r2(num value) native "SVGPathSegArcAbs_r2_Setter";

  @DomName('SVGPathSegArcAbs.sweepFlag')
  @DocsEditable
  bool get sweepFlag native "SVGPathSegArcAbs_sweepFlag_Getter";

  @DomName('SVGPathSegArcAbs.sweepFlag')
  @DocsEditable
  void set sweepFlag(bool value) native "SVGPathSegArcAbs_sweepFlag_Setter";

  @DomName('SVGPathSegArcAbs.x')
  @DocsEditable
  num get x native "SVGPathSegArcAbs_x_Getter";

  @DomName('SVGPathSegArcAbs.x')
  @DocsEditable
  void set x(num value) native "SVGPathSegArcAbs_x_Setter";

  @DomName('SVGPathSegArcAbs.y')
  @DocsEditable
  num get y native "SVGPathSegArcAbs_y_Getter";

  @DomName('SVGPathSegArcAbs.y')
  @DocsEditable
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

  @DomName('SVGPathSegArcRel.angle')
  @DocsEditable
  num get angle native "SVGPathSegArcRel_angle_Getter";

  @DomName('SVGPathSegArcRel.angle')
  @DocsEditable
  void set angle(num value) native "SVGPathSegArcRel_angle_Setter";

  @DomName('SVGPathSegArcRel.largeArcFlag')
  @DocsEditable
  bool get largeArcFlag native "SVGPathSegArcRel_largeArcFlag_Getter";

  @DomName('SVGPathSegArcRel.largeArcFlag')
  @DocsEditable
  void set largeArcFlag(bool value) native "SVGPathSegArcRel_largeArcFlag_Setter";

  @DomName('SVGPathSegArcRel.r1')
  @DocsEditable
  num get r1 native "SVGPathSegArcRel_r1_Getter";

  @DomName('SVGPathSegArcRel.r1')
  @DocsEditable
  void set r1(num value) native "SVGPathSegArcRel_r1_Setter";

  @DomName('SVGPathSegArcRel.r2')
  @DocsEditable
  num get r2 native "SVGPathSegArcRel_r2_Getter";

  @DomName('SVGPathSegArcRel.r2')
  @DocsEditable
  void set r2(num value) native "SVGPathSegArcRel_r2_Setter";

  @DomName('SVGPathSegArcRel.sweepFlag')
  @DocsEditable
  bool get sweepFlag native "SVGPathSegArcRel_sweepFlag_Getter";

  @DomName('SVGPathSegArcRel.sweepFlag')
  @DocsEditable
  void set sweepFlag(bool value) native "SVGPathSegArcRel_sweepFlag_Setter";

  @DomName('SVGPathSegArcRel.x')
  @DocsEditable
  num get x native "SVGPathSegArcRel_x_Getter";

  @DomName('SVGPathSegArcRel.x')
  @DocsEditable
  void set x(num value) native "SVGPathSegArcRel_x_Setter";

  @DomName('SVGPathSegArcRel.y')
  @DocsEditable
  num get y native "SVGPathSegArcRel_y_Getter";

  @DomName('SVGPathSegArcRel.y')
  @DocsEditable
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

  @DomName('SVGPathSegCurvetoCubicAbs.x')
  @DocsEditable
  num get x native "SVGPathSegCurvetoCubicAbs_x_Getter";

  @DomName('SVGPathSegCurvetoCubicAbs.x')
  @DocsEditable
  void set x(num value) native "SVGPathSegCurvetoCubicAbs_x_Setter";

  @DomName('SVGPathSegCurvetoCubicAbs.x1')
  @DocsEditable
  num get x1 native "SVGPathSegCurvetoCubicAbs_x1_Getter";

  @DomName('SVGPathSegCurvetoCubicAbs.x1')
  @DocsEditable
  void set x1(num value) native "SVGPathSegCurvetoCubicAbs_x1_Setter";

  @DomName('SVGPathSegCurvetoCubicAbs.x2')
  @DocsEditable
  num get x2 native "SVGPathSegCurvetoCubicAbs_x2_Getter";

  @DomName('SVGPathSegCurvetoCubicAbs.x2')
  @DocsEditable
  void set x2(num value) native "SVGPathSegCurvetoCubicAbs_x2_Setter";

  @DomName('SVGPathSegCurvetoCubicAbs.y')
  @DocsEditable
  num get y native "SVGPathSegCurvetoCubicAbs_y_Getter";

  @DomName('SVGPathSegCurvetoCubicAbs.y')
  @DocsEditable
  void set y(num value) native "SVGPathSegCurvetoCubicAbs_y_Setter";

  @DomName('SVGPathSegCurvetoCubicAbs.y1')
  @DocsEditable
  num get y1 native "SVGPathSegCurvetoCubicAbs_y1_Getter";

  @DomName('SVGPathSegCurvetoCubicAbs.y1')
  @DocsEditable
  void set y1(num value) native "SVGPathSegCurvetoCubicAbs_y1_Setter";

  @DomName('SVGPathSegCurvetoCubicAbs.y2')
  @DocsEditable
  num get y2 native "SVGPathSegCurvetoCubicAbs_y2_Getter";

  @DomName('SVGPathSegCurvetoCubicAbs.y2')
  @DocsEditable
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

  @DomName('SVGPathSegCurvetoCubicRel.x')
  @DocsEditable
  num get x native "SVGPathSegCurvetoCubicRel_x_Getter";

  @DomName('SVGPathSegCurvetoCubicRel.x')
  @DocsEditable
  void set x(num value) native "SVGPathSegCurvetoCubicRel_x_Setter";

  @DomName('SVGPathSegCurvetoCubicRel.x1')
  @DocsEditable
  num get x1 native "SVGPathSegCurvetoCubicRel_x1_Getter";

  @DomName('SVGPathSegCurvetoCubicRel.x1')
  @DocsEditable
  void set x1(num value) native "SVGPathSegCurvetoCubicRel_x1_Setter";

  @DomName('SVGPathSegCurvetoCubicRel.x2')
  @DocsEditable
  num get x2 native "SVGPathSegCurvetoCubicRel_x2_Getter";

  @DomName('SVGPathSegCurvetoCubicRel.x2')
  @DocsEditable
  void set x2(num value) native "SVGPathSegCurvetoCubicRel_x2_Setter";

  @DomName('SVGPathSegCurvetoCubicRel.y')
  @DocsEditable
  num get y native "SVGPathSegCurvetoCubicRel_y_Getter";

  @DomName('SVGPathSegCurvetoCubicRel.y')
  @DocsEditable
  void set y(num value) native "SVGPathSegCurvetoCubicRel_y_Setter";

  @DomName('SVGPathSegCurvetoCubicRel.y1')
  @DocsEditable
  num get y1 native "SVGPathSegCurvetoCubicRel_y1_Getter";

  @DomName('SVGPathSegCurvetoCubicRel.y1')
  @DocsEditable
  void set y1(num value) native "SVGPathSegCurvetoCubicRel_y1_Setter";

  @DomName('SVGPathSegCurvetoCubicRel.y2')
  @DocsEditable
  num get y2 native "SVGPathSegCurvetoCubicRel_y2_Getter";

  @DomName('SVGPathSegCurvetoCubicRel.y2')
  @DocsEditable
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

  @DomName('SVGPathSegCurvetoCubicSmoothAbs.x')
  @DocsEditable
  num get x native "SVGPathSegCurvetoCubicSmoothAbs_x_Getter";

  @DomName('SVGPathSegCurvetoCubicSmoothAbs.x')
  @DocsEditable
  void set x(num value) native "SVGPathSegCurvetoCubicSmoothAbs_x_Setter";

  @DomName('SVGPathSegCurvetoCubicSmoothAbs.x2')
  @DocsEditable
  num get x2 native "SVGPathSegCurvetoCubicSmoothAbs_x2_Getter";

  @DomName('SVGPathSegCurvetoCubicSmoothAbs.x2')
  @DocsEditable
  void set x2(num value) native "SVGPathSegCurvetoCubicSmoothAbs_x2_Setter";

  @DomName('SVGPathSegCurvetoCubicSmoothAbs.y')
  @DocsEditable
  num get y native "SVGPathSegCurvetoCubicSmoothAbs_y_Getter";

  @DomName('SVGPathSegCurvetoCubicSmoothAbs.y')
  @DocsEditable
  void set y(num value) native "SVGPathSegCurvetoCubicSmoothAbs_y_Setter";

  @DomName('SVGPathSegCurvetoCubicSmoothAbs.y2')
  @DocsEditable
  num get y2 native "SVGPathSegCurvetoCubicSmoothAbs_y2_Getter";

  @DomName('SVGPathSegCurvetoCubicSmoothAbs.y2')
  @DocsEditable
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

  @DomName('SVGPathSegCurvetoCubicSmoothRel.x')
  @DocsEditable
  num get x native "SVGPathSegCurvetoCubicSmoothRel_x_Getter";

  @DomName('SVGPathSegCurvetoCubicSmoothRel.x')
  @DocsEditable
  void set x(num value) native "SVGPathSegCurvetoCubicSmoothRel_x_Setter";

  @DomName('SVGPathSegCurvetoCubicSmoothRel.x2')
  @DocsEditable
  num get x2 native "SVGPathSegCurvetoCubicSmoothRel_x2_Getter";

  @DomName('SVGPathSegCurvetoCubicSmoothRel.x2')
  @DocsEditable
  void set x2(num value) native "SVGPathSegCurvetoCubicSmoothRel_x2_Setter";

  @DomName('SVGPathSegCurvetoCubicSmoothRel.y')
  @DocsEditable
  num get y native "SVGPathSegCurvetoCubicSmoothRel_y_Getter";

  @DomName('SVGPathSegCurvetoCubicSmoothRel.y')
  @DocsEditable
  void set y(num value) native "SVGPathSegCurvetoCubicSmoothRel_y_Setter";

  @DomName('SVGPathSegCurvetoCubicSmoothRel.y2')
  @DocsEditable
  num get y2 native "SVGPathSegCurvetoCubicSmoothRel_y2_Getter";

  @DomName('SVGPathSegCurvetoCubicSmoothRel.y2')
  @DocsEditable
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

  @DomName('SVGPathSegCurvetoQuadraticAbs.x')
  @DocsEditable
  num get x native "SVGPathSegCurvetoQuadraticAbs_x_Getter";

  @DomName('SVGPathSegCurvetoQuadraticAbs.x')
  @DocsEditable
  void set x(num value) native "SVGPathSegCurvetoQuadraticAbs_x_Setter";

  @DomName('SVGPathSegCurvetoQuadraticAbs.x1')
  @DocsEditable
  num get x1 native "SVGPathSegCurvetoQuadraticAbs_x1_Getter";

  @DomName('SVGPathSegCurvetoQuadraticAbs.x1')
  @DocsEditable
  void set x1(num value) native "SVGPathSegCurvetoQuadraticAbs_x1_Setter";

  @DomName('SVGPathSegCurvetoQuadraticAbs.y')
  @DocsEditable
  num get y native "SVGPathSegCurvetoQuadraticAbs_y_Getter";

  @DomName('SVGPathSegCurvetoQuadraticAbs.y')
  @DocsEditable
  void set y(num value) native "SVGPathSegCurvetoQuadraticAbs_y_Setter";

  @DomName('SVGPathSegCurvetoQuadraticAbs.y1')
  @DocsEditable
  num get y1 native "SVGPathSegCurvetoQuadraticAbs_y1_Getter";

  @DomName('SVGPathSegCurvetoQuadraticAbs.y1')
  @DocsEditable
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

  @DomName('SVGPathSegCurvetoQuadraticRel.x')
  @DocsEditable
  num get x native "SVGPathSegCurvetoQuadraticRel_x_Getter";

  @DomName('SVGPathSegCurvetoQuadraticRel.x')
  @DocsEditable
  void set x(num value) native "SVGPathSegCurvetoQuadraticRel_x_Setter";

  @DomName('SVGPathSegCurvetoQuadraticRel.x1')
  @DocsEditable
  num get x1 native "SVGPathSegCurvetoQuadraticRel_x1_Getter";

  @DomName('SVGPathSegCurvetoQuadraticRel.x1')
  @DocsEditable
  void set x1(num value) native "SVGPathSegCurvetoQuadraticRel_x1_Setter";

  @DomName('SVGPathSegCurvetoQuadraticRel.y')
  @DocsEditable
  num get y native "SVGPathSegCurvetoQuadraticRel_y_Getter";

  @DomName('SVGPathSegCurvetoQuadraticRel.y')
  @DocsEditable
  void set y(num value) native "SVGPathSegCurvetoQuadraticRel_y_Setter";

  @DomName('SVGPathSegCurvetoQuadraticRel.y1')
  @DocsEditable
  num get y1 native "SVGPathSegCurvetoQuadraticRel_y1_Getter";

  @DomName('SVGPathSegCurvetoQuadraticRel.y1')
  @DocsEditable
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

  @DomName('SVGPathSegCurvetoQuadraticSmoothAbs.x')
  @DocsEditable
  num get x native "SVGPathSegCurvetoQuadraticSmoothAbs_x_Getter";

  @DomName('SVGPathSegCurvetoQuadraticSmoothAbs.x')
  @DocsEditable
  void set x(num value) native "SVGPathSegCurvetoQuadraticSmoothAbs_x_Setter";

  @DomName('SVGPathSegCurvetoQuadraticSmoothAbs.y')
  @DocsEditable
  num get y native "SVGPathSegCurvetoQuadraticSmoothAbs_y_Getter";

  @DomName('SVGPathSegCurvetoQuadraticSmoothAbs.y')
  @DocsEditable
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

  @DomName('SVGPathSegCurvetoQuadraticSmoothRel.x')
  @DocsEditable
  num get x native "SVGPathSegCurvetoQuadraticSmoothRel_x_Getter";

  @DomName('SVGPathSegCurvetoQuadraticSmoothRel.x')
  @DocsEditable
  void set x(num value) native "SVGPathSegCurvetoQuadraticSmoothRel_x_Setter";

  @DomName('SVGPathSegCurvetoQuadraticSmoothRel.y')
  @DocsEditable
  num get y native "SVGPathSegCurvetoQuadraticSmoothRel_y_Getter";

  @DomName('SVGPathSegCurvetoQuadraticSmoothRel.y')
  @DocsEditable
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

  @DomName('SVGPathSegLinetoAbs.x')
  @DocsEditable
  num get x native "SVGPathSegLinetoAbs_x_Getter";

  @DomName('SVGPathSegLinetoAbs.x')
  @DocsEditable
  void set x(num value) native "SVGPathSegLinetoAbs_x_Setter";

  @DomName('SVGPathSegLinetoAbs.y')
  @DocsEditable
  num get y native "SVGPathSegLinetoAbs_y_Getter";

  @DomName('SVGPathSegLinetoAbs.y')
  @DocsEditable
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

  @DomName('SVGPathSegLinetoHorizontalAbs.x')
  @DocsEditable
  num get x native "SVGPathSegLinetoHorizontalAbs_x_Getter";

  @DomName('SVGPathSegLinetoHorizontalAbs.x')
  @DocsEditable
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

  @DomName('SVGPathSegLinetoHorizontalRel.x')
  @DocsEditable
  num get x native "SVGPathSegLinetoHorizontalRel_x_Getter";

  @DomName('SVGPathSegLinetoHorizontalRel.x')
  @DocsEditable
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

  @DomName('SVGPathSegLinetoRel.x')
  @DocsEditable
  num get x native "SVGPathSegLinetoRel_x_Getter";

  @DomName('SVGPathSegLinetoRel.x')
  @DocsEditable
  void set x(num value) native "SVGPathSegLinetoRel_x_Setter";

  @DomName('SVGPathSegLinetoRel.y')
  @DocsEditable
  num get y native "SVGPathSegLinetoRel_y_Getter";

  @DomName('SVGPathSegLinetoRel.y')
  @DocsEditable
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

  @DomName('SVGPathSegLinetoVerticalAbs.y')
  @DocsEditable
  num get y native "SVGPathSegLinetoVerticalAbs_y_Getter";

  @DomName('SVGPathSegLinetoVerticalAbs.y')
  @DocsEditable
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

  @DomName('SVGPathSegLinetoVerticalRel.y')
  @DocsEditable
  num get y native "SVGPathSegLinetoVerticalRel_y_Getter";

  @DomName('SVGPathSegLinetoVerticalRel.y')
  @DocsEditable
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

  @DomName('SVGPathSegList.numberOfItems')
  @DocsEditable
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
  PathSeg reduce(PathSeg combine(PathSeg value, PathSeg element)) {
    return IterableMixinWorkaround.reduce(this, combine);
  }

  dynamic fold(dynamic initialValue,
               dynamic combine(dynamic previousValue, PathSeg element)) {
    return IterableMixinWorkaround.fold(this, initialValue, combine);
  }

  bool contains(PathSeg element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(PathSeg element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator = ""]) =>
      IterableMixinWorkaround.joinList(this, separator);

  Iterable map(f(PathSeg element)) =>
      IterableMixinWorkaround.mapList(this, f);

  Iterable<PathSeg> where(bool f(PathSeg element)) =>
      IterableMixinWorkaround.where(this, f);

  Iterable expand(Iterable f(PathSeg element)) =>
      IterableMixinWorkaround.expand(this, f);

  bool every(bool f(PathSeg element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(PathSeg element)) => IterableMixinWorkaround.any(this, f);

  List<PathSeg> toList({ bool growable: true }) =>
      new List<PathSeg>.from(this, growable: growable);

  Set<PathSeg> toSet() => new Set<PathSeg>.from(this);

  bool get isEmpty => this.length == 0;

  Iterable<PathSeg> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<PathSeg> takeWhile(bool test(PathSeg value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  Iterable<PathSeg> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<PathSeg> skipWhile(bool test(PathSeg value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  PathSeg firstWhere(bool test(PathSeg value), { PathSeg orElse() }) {
    return IterableMixinWorkaround.firstWhere(this, test, orElse);
  }

  PathSeg lastWhere(bool test(PathSeg value), {PathSeg orElse()}) {
    return IterableMixinWorkaround.lastWhereList(this, test, orElse);
  }

  PathSeg singleWhere(bool test(PathSeg value)) {
    return IterableMixinWorkaround.singleWhere(this, test);
  }

  PathSeg elementAt(int index) {
    return this[index];
  }

  // From Collection<PathSeg>:

  void add(PathSeg value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<PathSeg> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<PathSeg>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  // clear() defined by IDL.

  Iterable<PathSeg> get reversed {
    return IterableMixinWorkaround.reversedList(this);
  }

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

  void insert(int index, PathSeg element) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void insertAll(int index, Iterable<PathSeg> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void setAll(int index, Iterable<PathSeg> iterable) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }

  PathSeg removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  PathSeg removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeWhere(bool test(PathSeg element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainWhere(bool test(PathSeg element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int end, Iterable<PathSeg> iterable, [int skipCount]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int end) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void replaceRange(int start, int end, Iterable<PathSeg> iterable) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }

  void fillRange(int start, int end, [PathSeg fillValue]) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }

  Iterable<PathSeg> getRange(int start, int end) =>
    IterableMixinWorkaround.getRangeList(this, start, end);

  List<PathSeg> sublist(int start, [int end]) {
    if (end == null) end = length;
    return Lists.getRange(this, start, end, <PathSeg>[]);
  }

  Map<int, PathSeg> asMap() =>
    IterableMixinWorkaround.asMapList(this);

  String toString() {
    StringBuffer buffer = new StringBuffer('[');
    buffer.writeAll(this, ', ');
    buffer.write(']');
    return buffer.toString();
  }

  // -- end List<PathSeg> mixins.

  @DomName('SVGPathSegList.appendItem')
  @DocsEditable
  PathSeg appendItem(PathSeg newItem) native "SVGPathSegList_appendItem_Callback";

  @DomName('SVGPathSegList.clear')
  @DocsEditable
  void clear() native "SVGPathSegList_clear_Callback";

  @DomName('SVGPathSegList.getItem')
  @DocsEditable
  PathSeg getItem(int index) native "SVGPathSegList_getItem_Callback";

  @DomName('SVGPathSegList.initialize')
  @DocsEditable
  PathSeg initialize(PathSeg newItem) native "SVGPathSegList_initialize_Callback";

  @DomName('SVGPathSegList.insertItemBefore')
  @DocsEditable
  PathSeg insertItemBefore(PathSeg newItem, int index) native "SVGPathSegList_insertItemBefore_Callback";

  @DomName('SVGPathSegList.removeItem')
  @DocsEditable
  PathSeg removeItem(int index) native "SVGPathSegList_removeItem_Callback";

  @DomName('SVGPathSegList.replaceItem')
  @DocsEditable
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

  @DomName('SVGPathSegMovetoAbs.x')
  @DocsEditable
  num get x native "SVGPathSegMovetoAbs_x_Getter";

  @DomName('SVGPathSegMovetoAbs.x')
  @DocsEditable
  void set x(num value) native "SVGPathSegMovetoAbs_x_Setter";

  @DomName('SVGPathSegMovetoAbs.y')
  @DocsEditable
  num get y native "SVGPathSegMovetoAbs_y_Getter";

  @DomName('SVGPathSegMovetoAbs.y')
  @DocsEditable
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

  @DomName('SVGPathSegMovetoRel.x')
  @DocsEditable
  num get x native "SVGPathSegMovetoRel_x_Getter";

  @DomName('SVGPathSegMovetoRel.x')
  @DocsEditable
  void set x(num value) native "SVGPathSegMovetoRel_x_Setter";

  @DomName('SVGPathSegMovetoRel.y')
  @DocsEditable
  num get y native "SVGPathSegMovetoRel_y_Getter";

  @DomName('SVGPathSegMovetoRel.y')
  @DocsEditable
  void set y(num value) native "SVGPathSegMovetoRel_y_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGPatternElement')
class PatternElement extends StyledElement implements FitToViewBox, UriReference, Tests, ExternalResourcesRequired, LangSpace {
  PatternElement.internal() : super.internal();

  @DomName('SVGPatternElement.SVGPatternElement')
  @DocsEditable
  factory PatternElement() => _SvgElementFactoryProvider.createSvgElement_tag("pattern");

  @DomName('SVGPatternElement.height')
  @DocsEditable
  AnimatedLength get height native "SVGPatternElement_height_Getter";

  @DomName('SVGPatternElement.patternContentUnits')
  @DocsEditable
  AnimatedEnumeration get patternContentUnits native "SVGPatternElement_patternContentUnits_Getter";

  @DomName('SVGPatternElement.patternTransform')
  @DocsEditable
  AnimatedTransformList get patternTransform native "SVGPatternElement_patternTransform_Getter";

  @DomName('SVGPatternElement.patternUnits')
  @DocsEditable
  AnimatedEnumeration get patternUnits native "SVGPatternElement_patternUnits_Getter";

  @DomName('SVGPatternElement.width')
  @DocsEditable
  AnimatedLength get width native "SVGPatternElement_width_Getter";

  @DomName('SVGPatternElement.x')
  @DocsEditable
  AnimatedLength get x native "SVGPatternElement_x_Getter";

  @DomName('SVGPatternElement.y')
  @DocsEditable
  AnimatedLength get y native "SVGPatternElement_y_Getter";

  @DomName('SVGPatternElement.externalResourcesRequired')
  @DocsEditable
  AnimatedBoolean get externalResourcesRequired native "SVGPatternElement_externalResourcesRequired_Getter";

  @DomName('SVGPatternElement.preserveAspectRatio')
  @DocsEditable
  AnimatedPreserveAspectRatio get preserveAspectRatio native "SVGPatternElement_preserveAspectRatio_Getter";

  @DomName('SVGPatternElement.viewBox')
  @DocsEditable
  AnimatedRect get viewBox native "SVGPatternElement_viewBox_Getter";

  @DomName('SVGPatternElement.xmllang')
  @DocsEditable
  String get xmllang native "SVGPatternElement_xmllang_Getter";

  @DomName('SVGPatternElement.xmllang')
  @DocsEditable
  void set xmllang(String value) native "SVGPatternElement_xmllang_Setter";

  @DomName('SVGPatternElement.xmlspace')
  @DocsEditable
  String get xmlspace native "SVGPatternElement_xmlspace_Getter";

  @DomName('SVGPatternElement.xmlspace')
  @DocsEditable
  void set xmlspace(String value) native "SVGPatternElement_xmlspace_Setter";

  @DomName('SVGPatternElement.requiredExtensions')
  @DocsEditable
  StringList get requiredExtensions native "SVGPatternElement_requiredExtensions_Getter";

  @DomName('SVGPatternElement.requiredFeatures')
  @DocsEditable
  StringList get requiredFeatures native "SVGPatternElement_requiredFeatures_Getter";

  @DomName('SVGPatternElement.systemLanguage')
  @DocsEditable
  StringList get systemLanguage native "SVGPatternElement_systemLanguage_Getter";

  @DomName('SVGPatternElement.hasExtension')
  @DocsEditable
  bool hasExtension(String extension) native "SVGPatternElement_hasExtension_Callback";

  @DomName('SVGPatternElement.href')
  @DocsEditable
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

  @DomName('SVGPoint.x')
  @DocsEditable
  num get x native "SVGPoint_x_Getter";

  @DomName('SVGPoint.x')
  @DocsEditable
  void set x(num value) native "SVGPoint_x_Setter";

  @DomName('SVGPoint.y')
  @DocsEditable
  num get y native "SVGPoint_y_Getter";

  @DomName('SVGPoint.y')
  @DocsEditable
  void set y(num value) native "SVGPoint_y_Setter";

  @DomName('SVGPoint.matrixTransform')
  @DocsEditable
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

  @DomName('SVGPointList.numberOfItems')
  @DocsEditable
  int get numberOfItems native "SVGPointList_numberOfItems_Getter";

  @DomName('SVGPointList.appendItem')
  @DocsEditable
  Point appendItem(Point item) native "SVGPointList_appendItem_Callback";

  @DomName('SVGPointList.clear')
  @DocsEditable
  void clear() native "SVGPointList_clear_Callback";

  @DomName('SVGPointList.getItem')
  @DocsEditable
  Point getItem(int index) native "SVGPointList_getItem_Callback";

  @DomName('SVGPointList.initialize')
  @DocsEditable
  Point initialize(Point item) native "SVGPointList_initialize_Callback";

  @DomName('SVGPointList.insertItemBefore')
  @DocsEditable
  Point insertItemBefore(Point item, int index) native "SVGPointList_insertItemBefore_Callback";

  @DomName('SVGPointList.removeItem')
  @DocsEditable
  Point removeItem(int index) native "SVGPointList_removeItem_Callback";

  @DomName('SVGPointList.replaceItem')
  @DocsEditable
  Point replaceItem(Point item, int index) native "SVGPointList_replaceItem_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGPolygonElement')
class PolygonElement extends StyledElement implements Transformable, Tests, ExternalResourcesRequired, LangSpace {
  PolygonElement.internal() : super.internal();

  @DomName('SVGPolygonElement.SVGPolygonElement')
  @DocsEditable
  factory PolygonElement() => _SvgElementFactoryProvider.createSvgElement_tag("polygon");

  @DomName('SVGPolygonElement.animatedPoints')
  @DocsEditable
  PointList get animatedPoints native "SVGPolygonElement_animatedPoints_Getter";

  @DomName('SVGPolygonElement.points')
  @DocsEditable
  PointList get points native "SVGPolygonElement_points_Getter";

  @DomName('SVGPolygonElement.externalResourcesRequired')
  @DocsEditable
  AnimatedBoolean get externalResourcesRequired native "SVGPolygonElement_externalResourcesRequired_Getter";

  @DomName('SVGPolygonElement.xmllang')
  @DocsEditable
  String get xmllang native "SVGPolygonElement_xmllang_Getter";

  @DomName('SVGPolygonElement.xmllang')
  @DocsEditable
  void set xmllang(String value) native "SVGPolygonElement_xmllang_Setter";

  @DomName('SVGPolygonElement.xmlspace')
  @DocsEditable
  String get xmlspace native "SVGPolygonElement_xmlspace_Getter";

  @DomName('SVGPolygonElement.xmlspace')
  @DocsEditable
  void set xmlspace(String value) native "SVGPolygonElement_xmlspace_Setter";

  @DomName('SVGPolygonElement.farthestViewportElement')
  @DocsEditable
  SvgElement get farthestViewportElement native "SVGPolygonElement_farthestViewportElement_Getter";

  @DomName('SVGPolygonElement.nearestViewportElement')
  @DocsEditable
  SvgElement get nearestViewportElement native "SVGPolygonElement_nearestViewportElement_Getter";

  @DomName('SVGPolygonElement.getBBox')
  @DocsEditable
  Rect getBBox() native "SVGPolygonElement_getBBox_Callback";

  @DomName('SVGPolygonElement.getCTM')
  @DocsEditable
  Matrix getCtm() native "SVGPolygonElement_getCTM_Callback";

  @DomName('SVGPolygonElement.getScreenCTM')
  @DocsEditable
  Matrix getScreenCtm() native "SVGPolygonElement_getScreenCTM_Callback";

  @DomName('SVGPolygonElement.getTransformToElement')
  @DocsEditable
  Matrix getTransformToElement(SvgElement element) native "SVGPolygonElement_getTransformToElement_Callback";

  @DomName('SVGPolygonElement.requiredExtensions')
  @DocsEditable
  StringList get requiredExtensions native "SVGPolygonElement_requiredExtensions_Getter";

  @DomName('SVGPolygonElement.requiredFeatures')
  @DocsEditable
  StringList get requiredFeatures native "SVGPolygonElement_requiredFeatures_Getter";

  @DomName('SVGPolygonElement.systemLanguage')
  @DocsEditable
  StringList get systemLanguage native "SVGPolygonElement_systemLanguage_Getter";

  @DomName('SVGPolygonElement.hasExtension')
  @DocsEditable
  bool hasExtension(String extension) native "SVGPolygonElement_hasExtension_Callback";

  @DomName('SVGPolygonElement.transform')
  @DocsEditable
  AnimatedTransformList get transform native "SVGPolygonElement_transform_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGPolylineElement')
class PolylineElement extends StyledElement implements Transformable, Tests, ExternalResourcesRequired, LangSpace {
  PolylineElement.internal() : super.internal();

  @DomName('SVGPolylineElement.SVGPolylineElement')
  @DocsEditable
  factory PolylineElement() => _SvgElementFactoryProvider.createSvgElement_tag("polyline");

  @DomName('SVGPolylineElement.animatedPoints')
  @DocsEditable
  PointList get animatedPoints native "SVGPolylineElement_animatedPoints_Getter";

  @DomName('SVGPolylineElement.points')
  @DocsEditable
  PointList get points native "SVGPolylineElement_points_Getter";

  @DomName('SVGPolylineElement.externalResourcesRequired')
  @DocsEditable
  AnimatedBoolean get externalResourcesRequired native "SVGPolylineElement_externalResourcesRequired_Getter";

  @DomName('SVGPolylineElement.xmllang')
  @DocsEditable
  String get xmllang native "SVGPolylineElement_xmllang_Getter";

  @DomName('SVGPolylineElement.xmllang')
  @DocsEditable
  void set xmllang(String value) native "SVGPolylineElement_xmllang_Setter";

  @DomName('SVGPolylineElement.xmlspace')
  @DocsEditable
  String get xmlspace native "SVGPolylineElement_xmlspace_Getter";

  @DomName('SVGPolylineElement.xmlspace')
  @DocsEditable
  void set xmlspace(String value) native "SVGPolylineElement_xmlspace_Setter";

  @DomName('SVGPolylineElement.farthestViewportElement')
  @DocsEditable
  SvgElement get farthestViewportElement native "SVGPolylineElement_farthestViewportElement_Getter";

  @DomName('SVGPolylineElement.nearestViewportElement')
  @DocsEditable
  SvgElement get nearestViewportElement native "SVGPolylineElement_nearestViewportElement_Getter";

  @DomName('SVGPolylineElement.getBBox')
  @DocsEditable
  Rect getBBox() native "SVGPolylineElement_getBBox_Callback";

  @DomName('SVGPolylineElement.getCTM')
  @DocsEditable
  Matrix getCtm() native "SVGPolylineElement_getCTM_Callback";

  @DomName('SVGPolylineElement.getScreenCTM')
  @DocsEditable
  Matrix getScreenCtm() native "SVGPolylineElement_getScreenCTM_Callback";

  @DomName('SVGPolylineElement.getTransformToElement')
  @DocsEditable
  Matrix getTransformToElement(SvgElement element) native "SVGPolylineElement_getTransformToElement_Callback";

  @DomName('SVGPolylineElement.requiredExtensions')
  @DocsEditable
  StringList get requiredExtensions native "SVGPolylineElement_requiredExtensions_Getter";

  @DomName('SVGPolylineElement.requiredFeatures')
  @DocsEditable
  StringList get requiredFeatures native "SVGPolylineElement_requiredFeatures_Getter";

  @DomName('SVGPolylineElement.systemLanguage')
  @DocsEditable
  StringList get systemLanguage native "SVGPolylineElement_systemLanguage_Getter";

  @DomName('SVGPolylineElement.hasExtension')
  @DocsEditable
  bool hasExtension(String extension) native "SVGPolylineElement_hasExtension_Callback";

  @DomName('SVGPolylineElement.transform')
  @DocsEditable
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

  @DomName('SVGPreserveAspectRatio.align')
  @DocsEditable
  int get align native "SVGPreserveAspectRatio_align_Getter";

  @DomName('SVGPreserveAspectRatio.align')
  @DocsEditable
  void set align(int value) native "SVGPreserveAspectRatio_align_Setter";

  @DomName('SVGPreserveAspectRatio.meetOrSlice')
  @DocsEditable
  int get meetOrSlice native "SVGPreserveAspectRatio_meetOrSlice_Getter";

  @DomName('SVGPreserveAspectRatio.meetOrSlice')
  @DocsEditable
  void set meetOrSlice(int value) native "SVGPreserveAspectRatio_meetOrSlice_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGRadialGradientElement')
class RadialGradientElement extends _GradientElement {
  RadialGradientElement.internal() : super.internal();

  @DomName('SVGRadialGradientElement.SVGRadialGradientElement')
  @DocsEditable
  factory RadialGradientElement() => _SvgElementFactoryProvider.createSvgElement_tag("radialGradient");

  @DomName('SVGRadialGradientElement.cx')
  @DocsEditable
  AnimatedLength get cx native "SVGRadialGradientElement_cx_Getter";

  @DomName('SVGRadialGradientElement.cy')
  @DocsEditable
  AnimatedLength get cy native "SVGRadialGradientElement_cy_Getter";

  @DomName('SVGRadialGradientElement.fr')
  @DocsEditable
  AnimatedLength get fr native "SVGRadialGradientElement_fr_Getter";

  @DomName('SVGRadialGradientElement.fx')
  @DocsEditable
  AnimatedLength get fx native "SVGRadialGradientElement_fx_Getter";

  @DomName('SVGRadialGradientElement.fy')
  @DocsEditable
  AnimatedLength get fy native "SVGRadialGradientElement_fy_Getter";

  @DomName('SVGRadialGradientElement.r')
  @DocsEditable
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

  @DomName('SVGRect.height')
  @DocsEditable
  num get height native "SVGRect_height_Getter";

  @DomName('SVGRect.height')
  @DocsEditable
  void set height(num value) native "SVGRect_height_Setter";

  @DomName('SVGRect.width')
  @DocsEditable
  num get width native "SVGRect_width_Getter";

  @DomName('SVGRect.width')
  @DocsEditable
  void set width(num value) native "SVGRect_width_Setter";

  @DomName('SVGRect.x')
  @DocsEditable
  num get x native "SVGRect_x_Getter";

  @DomName('SVGRect.x')
  @DocsEditable
  void set x(num value) native "SVGRect_x_Setter";

  @DomName('SVGRect.y')
  @DocsEditable
  num get y native "SVGRect_y_Getter";

  @DomName('SVGRect.y')
  @DocsEditable
  void set y(num value) native "SVGRect_y_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGRectElement')
class RectElement extends StyledElement implements Transformable, Tests, ExternalResourcesRequired, LangSpace {
  RectElement.internal() : super.internal();

  @DomName('SVGRectElement.SVGRectElement')
  @DocsEditable
  factory RectElement() => _SvgElementFactoryProvider.createSvgElement_tag("rect");

  @DomName('SVGRectElement.height')
  @DocsEditable
  AnimatedLength get height native "SVGRectElement_height_Getter";

  @DomName('SVGRectElement.rx')
  @DocsEditable
  AnimatedLength get rx native "SVGRectElement_rx_Getter";

  @DomName('SVGRectElement.ry')
  @DocsEditable
  AnimatedLength get ry native "SVGRectElement_ry_Getter";

  @DomName('SVGRectElement.width')
  @DocsEditable
  AnimatedLength get width native "SVGRectElement_width_Getter";

  @DomName('SVGRectElement.x')
  @DocsEditable
  AnimatedLength get x native "SVGRectElement_x_Getter";

  @DomName('SVGRectElement.y')
  @DocsEditable
  AnimatedLength get y native "SVGRectElement_y_Getter";

  @DomName('SVGRectElement.externalResourcesRequired')
  @DocsEditable
  AnimatedBoolean get externalResourcesRequired native "SVGRectElement_externalResourcesRequired_Getter";

  @DomName('SVGRectElement.xmllang')
  @DocsEditable
  String get xmllang native "SVGRectElement_xmllang_Getter";

  @DomName('SVGRectElement.xmllang')
  @DocsEditable
  void set xmllang(String value) native "SVGRectElement_xmllang_Setter";

  @DomName('SVGRectElement.xmlspace')
  @DocsEditable
  String get xmlspace native "SVGRectElement_xmlspace_Getter";

  @DomName('SVGRectElement.xmlspace')
  @DocsEditable
  void set xmlspace(String value) native "SVGRectElement_xmlspace_Setter";

  @DomName('SVGRectElement.farthestViewportElement')
  @DocsEditable
  SvgElement get farthestViewportElement native "SVGRectElement_farthestViewportElement_Getter";

  @DomName('SVGRectElement.nearestViewportElement')
  @DocsEditable
  SvgElement get nearestViewportElement native "SVGRectElement_nearestViewportElement_Getter";

  @DomName('SVGRectElement.getBBox')
  @DocsEditable
  Rect getBBox() native "SVGRectElement_getBBox_Callback";

  @DomName('SVGRectElement.getCTM')
  @DocsEditable
  Matrix getCtm() native "SVGRectElement_getCTM_Callback";

  @DomName('SVGRectElement.getScreenCTM')
  @DocsEditable
  Matrix getScreenCtm() native "SVGRectElement_getScreenCTM_Callback";

  @DomName('SVGRectElement.getTransformToElement')
  @DocsEditable
  Matrix getTransformToElement(SvgElement element) native "SVGRectElement_getTransformToElement_Callback";

  @DomName('SVGRectElement.requiredExtensions')
  @DocsEditable
  StringList get requiredExtensions native "SVGRectElement_requiredExtensions_Getter";

  @DomName('SVGRectElement.requiredFeatures')
  @DocsEditable
  StringList get requiredFeatures native "SVGRectElement_requiredFeatures_Getter";

  @DomName('SVGRectElement.systemLanguage')
  @DocsEditable
  StringList get systemLanguage native "SVGRectElement_systemLanguage_Getter";

  @DomName('SVGRectElement.hasExtension')
  @DocsEditable
  bool hasExtension(String extension) native "SVGRectElement_hasExtension_Callback";

  @DomName('SVGRectElement.transform')
  @DocsEditable
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

  @DomName('SVGScriptElement.SVGScriptElement')
  @DocsEditable
  factory ScriptElement() => _SvgElementFactoryProvider.createSvgElement_tag("script");

  @DomName('SVGScriptElement.type')
  @DocsEditable
  String get type native "SVGScriptElement_type_Getter";

  @DomName('SVGScriptElement.type')
  @DocsEditable
  void set type(String value) native "SVGScriptElement_type_Setter";

  @DomName('SVGScriptElement.externalResourcesRequired')
  @DocsEditable
  AnimatedBoolean get externalResourcesRequired native "SVGScriptElement_externalResourcesRequired_Getter";

  @DomName('SVGScriptElement.href')
  @DocsEditable
  AnimatedString get href native "SVGScriptElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGSetElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.SAFARI)
class SetElement extends AnimationElement {
  SetElement.internal() : super.internal();

  @DomName('SVGSetElement.SVGSetElement')
  @DocsEditable
  factory SetElement() => _SvgElementFactoryProvider.createSvgElement_tag("set");

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGStopElement')
class StopElement extends StyledElement {
  StopElement.internal() : super.internal();

  @DomName('SVGStopElement.SVGStopElement')
  @DocsEditable
  factory StopElement() => _SvgElementFactoryProvider.createSvgElement_tag("stop");

  @DomName('SVGStopElement.offset')
  @DocsEditable
  AnimatedNumber get gradientOffset native "SVGStopElement_offset_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGStringList')
class StringList extends NativeFieldWrapperClass1 implements List<String> {
  StringList.internal();

  @DomName('SVGStringList.numberOfItems')
  @DocsEditable
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
  String reduce(String combine(String value, String element)) {
    return IterableMixinWorkaround.reduce(this, combine);
  }

  dynamic fold(dynamic initialValue,
               dynamic combine(dynamic previousValue, String element)) {
    return IterableMixinWorkaround.fold(this, initialValue, combine);
  }

  bool contains(String element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(String element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator = ""]) =>
      IterableMixinWorkaround.joinList(this, separator);

  Iterable map(f(String element)) =>
      IterableMixinWorkaround.mapList(this, f);

  Iterable<String> where(bool f(String element)) =>
      IterableMixinWorkaround.where(this, f);

  Iterable expand(Iterable f(String element)) =>
      IterableMixinWorkaround.expand(this, f);

  bool every(bool f(String element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(String element)) => IterableMixinWorkaround.any(this, f);

  List<String> toList({ bool growable: true }) =>
      new List<String>.from(this, growable: growable);

  Set<String> toSet() => new Set<String>.from(this);

  bool get isEmpty => this.length == 0;

  Iterable<String> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<String> takeWhile(bool test(String value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  Iterable<String> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<String> skipWhile(bool test(String value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  String firstWhere(bool test(String value), { String orElse() }) {
    return IterableMixinWorkaround.firstWhere(this, test, orElse);
  }

  String lastWhere(bool test(String value), {String orElse()}) {
    return IterableMixinWorkaround.lastWhereList(this, test, orElse);
  }

  String singleWhere(bool test(String value)) {
    return IterableMixinWorkaround.singleWhere(this, test);
  }

  String elementAt(int index) {
    return this[index];
  }

  // From Collection<String>:

  void add(String value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<String> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<String>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  // clear() defined by IDL.

  Iterable<String> get reversed {
    return IterableMixinWorkaround.reversedList(this);
  }

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

  void insert(int index, String element) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void insertAll(int index, Iterable<String> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void setAll(int index, Iterable<String> iterable) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }

  String removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  String removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeWhere(bool test(String element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainWhere(bool test(String element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int end, Iterable<String> iterable, [int skipCount]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int end) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void replaceRange(int start, int end, Iterable<String> iterable) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }

  void fillRange(int start, int end, [String fillValue]) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }

  Iterable<String> getRange(int start, int end) =>
    IterableMixinWorkaround.getRangeList(this, start, end);

  List<String> sublist(int start, [int end]) {
    if (end == null) end = length;
    return Lists.getRange(this, start, end, <String>[]);
  }

  Map<int, String> asMap() =>
    IterableMixinWorkaround.asMapList(this);

  String toString() {
    StringBuffer buffer = new StringBuffer('[');
    buffer.writeAll(this, ', ');
    buffer.write(']');
    return buffer.toString();
  }

  // -- end List<String> mixins.

  @DomName('SVGStringList.appendItem')
  @DocsEditable
  String appendItem(String item) native "SVGStringList_appendItem_Callback";

  @DomName('SVGStringList.clear')
  @DocsEditable
  void clear() native "SVGStringList_clear_Callback";

  @DomName('SVGStringList.getItem')
  @DocsEditable
  String getItem(int index) native "SVGStringList_getItem_Callback";

  @DomName('SVGStringList.initialize')
  @DocsEditable
  String initialize(String item) native "SVGStringList_initialize_Callback";

  @DomName('SVGStringList.insertItemBefore')
  @DocsEditable
  String insertItemBefore(String item, int index) native "SVGStringList_insertItemBefore_Callback";

  @DomName('SVGStringList.removeItem')
  @DocsEditable
  String removeItem(int index) native "SVGStringList_removeItem_Callback";

  @DomName('SVGStringList.replaceItem')
  @DocsEditable
  String replaceItem(String item, int index) native "SVGStringList_replaceItem_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGStyleElement')
class StyleElement extends SvgElement implements LangSpace {
  StyleElement.internal() : super.internal();

  @DomName('SVGStyleElement.SVGStyleElement')
  @DocsEditable
  factory StyleElement() => _SvgElementFactoryProvider.createSvgElement_tag("style");

  @DomName('SVGStyleElement.disabled')
  @DocsEditable
  bool get disabled native "SVGStyleElement_disabled_Getter";

  @DomName('SVGStyleElement.disabled')
  @DocsEditable
  void set disabled(bool value) native "SVGStyleElement_disabled_Setter";

  @DomName('SVGStyleElement.media')
  @DocsEditable
  String get media native "SVGStyleElement_media_Getter";

  @DomName('SVGStyleElement.media')
  @DocsEditable
  void set media(String value) native "SVGStyleElement_media_Setter";

  @DomName('SVGStyleElement.title')
  @DocsEditable
  String get title native "SVGStyleElement_title_Getter";

  @DomName('SVGStyleElement.title')
  @DocsEditable
  void set title(String value) native "SVGStyleElement_title_Setter";

  @DomName('SVGStyleElement.type')
  @DocsEditable
  String get type native "SVGStyleElement_type_Getter";

  @DomName('SVGStyleElement.type')
  @DocsEditable
  void set type(String value) native "SVGStyleElement_type_Setter";

  @DomName('SVGStyleElement.xmllang')
  @DocsEditable
  String get xmllang native "SVGStyleElement_xmllang_Getter";

  @DomName('SVGStyleElement.xmllang')
  @DocsEditable
  void set xmllang(String value) native "SVGStyleElement_xmllang_Setter";

  @DomName('SVGStyleElement.xmlspace')
  @DocsEditable
  String get xmlspace native "SVGStyleElement_xmlspace_Getter";

  @DomName('SVGStyleElement.xmlspace')
  @DocsEditable
  void set xmlspace(String value) native "SVGStyleElement_xmlspace_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGStyledElement')
class StyledElement extends SvgElement {
  StyledElement.internal() : super.internal();

  @DomName('SVGStyledElement.className')
  @DocsEditable
  AnimatedString get $dom_svgClassName native "SVGStyledElement_className_Getter";

  @DomName('SVGStyledElement.style')
  @DocsEditable
  CssStyleDeclaration get style native "SVGStyledElement_style_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGDocument')
class SvgDocument extends Document {
  SvgDocument.internal() : super.internal();

  @DomName('SVGDocument.rootElement')
  @DocsEditable
  SvgSvgElement get rootElement native "SVGDocument_rootElement_Getter";

  @DomName('SVGDocument.createEvent')
  @DocsEditable
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

    Set<String> s = new LinkedHashSet<String>();
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
    _element.attributes['class'] = s.join(' ');
  }
}

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

  /**
   * Checks to see if the SVG element type is supported by the current platform.
   *
   * The tag should be a valid SVG element tag name.
   */
  static bool isTagSupported(String tag) {
    var e = new SvgElement.tag(tag);
    return e is SvgElement && !(e is UnknownElement);
  }
  SvgElement.internal() : super.internal();

  @DomName('SVGElement.id')
  @DocsEditable
  String get id native "SVGElement_id_Getter";

  @DomName('SVGElement.id')
  @DocsEditable
  void set id(String value) native "SVGElement_id_Setter";

  @DomName('SVGElement.ownerSVGElement')
  @DocsEditable
  SvgSvgElement get ownerSvgElement native "SVGElement_ownerSVGElement_Getter";

  @DomName('SVGElement.viewportElement')
  @DocsEditable
  SvgElement get viewportElement native "SVGElement_viewportElement_Getter";

  @DomName('SVGElement.xmlbase')
  @DocsEditable
  String get xmlbase native "SVGElement_xmlbase_Getter";

  @DomName('SVGElement.xmlbase')
  @DocsEditable
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

  @DomName('SVGException.code')
  @DocsEditable
  int get code native "SVGException_code_Getter";

  @DomName('SVGException.message')
  @DocsEditable
  String get message native "SVGException_message_Getter";

  @DomName('SVGException.name')
  @DocsEditable
  String get name native "SVGException_name_Getter";

  @DomName('SVGException.toString')
  @DocsEditable
  String toString() native "SVGException_toString_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('SVGSVGElement')
class SvgSvgElement extends StyledElement implements FitToViewBox, Transformable, Tests, ExternalResourcesRequired, ZoomAndPan, LangSpace {
  factory SvgSvgElement() => _SvgSvgElementFactoryProvider.createSvgSvgElement();

  SvgSvgElement.internal() : super.internal();

  @DomName('SVGSVGElement.contentScriptType')
  @DocsEditable
  String get contentScriptType native "SVGSVGElement_contentScriptType_Getter";

  @DomName('SVGSVGElement.contentScriptType')
  @DocsEditable
  void set contentScriptType(String value) native "SVGSVGElement_contentScriptType_Setter";

  @DomName('SVGSVGElement.contentStyleType')
  @DocsEditable
  String get contentStyleType native "SVGSVGElement_contentStyleType_Getter";

  @DomName('SVGSVGElement.contentStyleType')
  @DocsEditable
  void set contentStyleType(String value) native "SVGSVGElement_contentStyleType_Setter";

  @DomName('SVGSVGElement.currentScale')
  @DocsEditable
  num get currentScale native "SVGSVGElement_currentScale_Getter";

  @DomName('SVGSVGElement.currentScale')
  @DocsEditable
  void set currentScale(num value) native "SVGSVGElement_currentScale_Setter";

  @DomName('SVGSVGElement.currentTranslate')
  @DocsEditable
  Point get currentTranslate native "SVGSVGElement_currentTranslate_Getter";

  @DomName('SVGSVGElement.currentView')
  @DocsEditable
  ViewSpec get currentView native "SVGSVGElement_currentView_Getter";

  @DomName('SVGSVGElement.height')
  @DocsEditable
  AnimatedLength get height native "SVGSVGElement_height_Getter";

  @DomName('SVGSVGElement.pixelUnitToMillimeterX')
  @DocsEditable
  num get pixelUnitToMillimeterX native "SVGSVGElement_pixelUnitToMillimeterX_Getter";

  @DomName('SVGSVGElement.pixelUnitToMillimeterY')
  @DocsEditable
  num get pixelUnitToMillimeterY native "SVGSVGElement_pixelUnitToMillimeterY_Getter";

  @DomName('SVGSVGElement.screenPixelToMillimeterX')
  @DocsEditable
  num get screenPixelToMillimeterX native "SVGSVGElement_screenPixelToMillimeterX_Getter";

  @DomName('SVGSVGElement.screenPixelToMillimeterY')
  @DocsEditable
  num get screenPixelToMillimeterY native "SVGSVGElement_screenPixelToMillimeterY_Getter";

  @DomName('SVGSVGElement.useCurrentView')
  @DocsEditable
  bool get useCurrentView native "SVGSVGElement_useCurrentView_Getter";

  @DomName('SVGSVGElement.viewport')
  @DocsEditable
  Rect get viewport native "SVGSVGElement_viewport_Getter";

  @DomName('SVGSVGElement.width')
  @DocsEditable
  AnimatedLength get width native "SVGSVGElement_width_Getter";

  @DomName('SVGSVGElement.x')
  @DocsEditable
  AnimatedLength get x native "SVGSVGElement_x_Getter";

  @DomName('SVGSVGElement.y')
  @DocsEditable
  AnimatedLength get y native "SVGSVGElement_y_Getter";

  @DomName('SVGSVGElement.animationsPaused')
  @DocsEditable
  bool animationsPaused() native "SVGSVGElement_animationsPaused_Callback";

  @DomName('SVGSVGElement.checkEnclosure')
  @DocsEditable
  bool checkEnclosure(SvgElement element, Rect rect) native "SVGSVGElement_checkEnclosure_Callback";

  @DomName('SVGSVGElement.checkIntersection')
  @DocsEditable
  bool checkIntersection(SvgElement element, Rect rect) native "SVGSVGElement_checkIntersection_Callback";

  @DomName('SVGSVGElement.createSVGAngle')
  @DocsEditable
  Angle createSvgAngle() native "SVGSVGElement_createSVGAngle_Callback";

  @DomName('SVGSVGElement.createSVGLength')
  @DocsEditable
  Length createSvgLength() native "SVGSVGElement_createSVGLength_Callback";

  @DomName('SVGSVGElement.createSVGMatrix')
  @DocsEditable
  Matrix createSvgMatrix() native "SVGSVGElement_createSVGMatrix_Callback";

  @DomName('SVGSVGElement.createSVGNumber')
  @DocsEditable
  Number createSvgNumber() native "SVGSVGElement_createSVGNumber_Callback";

  @DomName('SVGSVGElement.createSVGPoint')
  @DocsEditable
  Point createSvgPoint() native "SVGSVGElement_createSVGPoint_Callback";

  @DomName('SVGSVGElement.createSVGRect')
  @DocsEditable
  Rect createSvgRect() native "SVGSVGElement_createSVGRect_Callback";

  @DomName('SVGSVGElement.createSVGTransform')
  @DocsEditable
  Transform createSvgTransform() native "SVGSVGElement_createSVGTransform_Callback";

  @DomName('SVGSVGElement.createSVGTransformFromMatrix')
  @DocsEditable
  Transform createSvgTransformFromMatrix(Matrix matrix) native "SVGSVGElement_createSVGTransformFromMatrix_Callback";

  @DomName('SVGSVGElement.deselectAll')
  @DocsEditable
  void deselectAll() native "SVGSVGElement_deselectAll_Callback";

  @DomName('SVGSVGElement.forceRedraw')
  @DocsEditable
  void forceRedraw() native "SVGSVGElement_forceRedraw_Callback";

  @DomName('SVGSVGElement.getCurrentTime')
  @DocsEditable
  num getCurrentTime() native "SVGSVGElement_getCurrentTime_Callback";

  @DomName('SVGSVGElement.getElementById')
  @DocsEditable
  Element getElementById(String elementId) native "SVGSVGElement_getElementById_Callback";

  @DomName('SVGSVGElement.getEnclosureList')
  @DocsEditable
  List<Node> getEnclosureList(Rect rect, SvgElement referenceElement) native "SVGSVGElement_getEnclosureList_Callback";

  @DomName('SVGSVGElement.getIntersectionList')
  @DocsEditable
  List<Node> getIntersectionList(Rect rect, SvgElement referenceElement) native "SVGSVGElement_getIntersectionList_Callback";

  @DomName('SVGSVGElement.pauseAnimations')
  @DocsEditable
  void pauseAnimations() native "SVGSVGElement_pauseAnimations_Callback";

  @DomName('SVGSVGElement.setCurrentTime')
  @DocsEditable
  void setCurrentTime(num seconds) native "SVGSVGElement_setCurrentTime_Callback";

  @DomName('SVGSVGElement.suspendRedraw')
  @DocsEditable
  int suspendRedraw(int maxWaitMilliseconds) native "SVGSVGElement_suspendRedraw_Callback";

  @DomName('SVGSVGElement.unpauseAnimations')
  @DocsEditable
  void unpauseAnimations() native "SVGSVGElement_unpauseAnimations_Callback";

  @DomName('SVGSVGElement.unsuspendRedraw')
  @DocsEditable
  void unsuspendRedraw(int suspendHandleId) native "SVGSVGElement_unsuspendRedraw_Callback";

  @DomName('SVGSVGElement.unsuspendRedrawAll')
  @DocsEditable
  void unsuspendRedrawAll() native "SVGSVGElement_unsuspendRedrawAll_Callback";

  @DomName('SVGSVGElement.externalResourcesRequired')
  @DocsEditable
  AnimatedBoolean get externalResourcesRequired native "SVGSVGElement_externalResourcesRequired_Getter";

  @DomName('SVGSVGElement.preserveAspectRatio')
  @DocsEditable
  AnimatedPreserveAspectRatio get preserveAspectRatio native "SVGSVGElement_preserveAspectRatio_Getter";

  @DomName('SVGSVGElement.viewBox')
  @DocsEditable
  AnimatedRect get viewBox native "SVGSVGElement_viewBox_Getter";

  @DomName('SVGSVGElement.xmllang')
  @DocsEditable
  String get xmllang native "SVGSVGElement_xmllang_Getter";

  @DomName('SVGSVGElement.xmllang')
  @DocsEditable
  void set xmllang(String value) native "SVGSVGElement_xmllang_Setter";

  @DomName('SVGSVGElement.xmlspace')
  @DocsEditable
  String get xmlspace native "SVGSVGElement_xmlspace_Getter";

  @DomName('SVGSVGElement.xmlspace')
  @DocsEditable
  void set xmlspace(String value) native "SVGSVGElement_xmlspace_Setter";

  @DomName('SVGSVGElement.farthestViewportElement')
  @DocsEditable
  SvgElement get farthestViewportElement native "SVGSVGElement_farthestViewportElement_Getter";

  @DomName('SVGSVGElement.nearestViewportElement')
  @DocsEditable
  SvgElement get nearestViewportElement native "SVGSVGElement_nearestViewportElement_Getter";

  @DomName('SVGSVGElement.getBBox')
  @DocsEditable
  Rect getBBox() native "SVGSVGElement_getBBox_Callback";

  @DomName('SVGSVGElement.getCTM')
  @DocsEditable
  Matrix getCtm() native "SVGSVGElement_getCTM_Callback";

  @DomName('SVGSVGElement.getScreenCTM')
  @DocsEditable
  Matrix getScreenCtm() native "SVGSVGElement_getScreenCTM_Callback";

  @DomName('SVGSVGElement.getTransformToElement')
  @DocsEditable
  Matrix getTransformToElement(SvgElement element) native "SVGSVGElement_getTransformToElement_Callback";

  @DomName('SVGSVGElement.requiredExtensions')
  @DocsEditable
  StringList get requiredExtensions native "SVGSVGElement_requiredExtensions_Getter";

  @DomName('SVGSVGElement.requiredFeatures')
  @DocsEditable
  StringList get requiredFeatures native "SVGSVGElement_requiredFeatures_Getter";

  @DomName('SVGSVGElement.systemLanguage')
  @DocsEditable
  StringList get systemLanguage native "SVGSVGElement_systemLanguage_Getter";

  @DomName('SVGSVGElement.hasExtension')
  @DocsEditable
  bool hasExtension(String extension) native "SVGSVGElement_hasExtension_Callback";

  @DomName('SVGSVGElement.transform')
  @DocsEditable
  AnimatedTransformList get transform native "SVGSVGElement_transform_Getter";

  @DomName('SVGSVGElement.zoomAndPan')
  @DocsEditable
  int get zoomAndPan native "SVGSVGElement_zoomAndPan_Getter";

  @DomName('SVGSVGElement.zoomAndPan')
  @DocsEditable
  void set zoomAndPan(int value) native "SVGSVGElement_zoomAndPan_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGSwitchElement')
class SwitchElement extends StyledElement implements Transformable, Tests, ExternalResourcesRequired, LangSpace {
  SwitchElement.internal() : super.internal();

  @DomName('SVGSwitchElement.SVGSwitchElement')
  @DocsEditable
  factory SwitchElement() => _SvgElementFactoryProvider.createSvgElement_tag("switch");

  @DomName('SVGSwitchElement.externalResourcesRequired')
  @DocsEditable
  AnimatedBoolean get externalResourcesRequired native "SVGSwitchElement_externalResourcesRequired_Getter";

  @DomName('SVGSwitchElement.xmllang')
  @DocsEditable
  String get xmllang native "SVGSwitchElement_xmllang_Getter";

  @DomName('SVGSwitchElement.xmllang')
  @DocsEditable
  void set xmllang(String value) native "SVGSwitchElement_xmllang_Setter";

  @DomName('SVGSwitchElement.xmlspace')
  @DocsEditable
  String get xmlspace native "SVGSwitchElement_xmlspace_Getter";

  @DomName('SVGSwitchElement.xmlspace')
  @DocsEditable
  void set xmlspace(String value) native "SVGSwitchElement_xmlspace_Setter";

  @DomName('SVGSwitchElement.farthestViewportElement')
  @DocsEditable
  SvgElement get farthestViewportElement native "SVGSwitchElement_farthestViewportElement_Getter";

  @DomName('SVGSwitchElement.nearestViewportElement')
  @DocsEditable
  SvgElement get nearestViewportElement native "SVGSwitchElement_nearestViewportElement_Getter";

  @DomName('SVGSwitchElement.getBBox')
  @DocsEditable
  Rect getBBox() native "SVGSwitchElement_getBBox_Callback";

  @DomName('SVGSwitchElement.getCTM')
  @DocsEditable
  Matrix getCtm() native "SVGSwitchElement_getCTM_Callback";

  @DomName('SVGSwitchElement.getScreenCTM')
  @DocsEditable
  Matrix getScreenCtm() native "SVGSwitchElement_getScreenCTM_Callback";

  @DomName('SVGSwitchElement.getTransformToElement')
  @DocsEditable
  Matrix getTransformToElement(SvgElement element) native "SVGSwitchElement_getTransformToElement_Callback";

  @DomName('SVGSwitchElement.requiredExtensions')
  @DocsEditable
  StringList get requiredExtensions native "SVGSwitchElement_requiredExtensions_Getter";

  @DomName('SVGSwitchElement.requiredFeatures')
  @DocsEditable
  StringList get requiredFeatures native "SVGSwitchElement_requiredFeatures_Getter";

  @DomName('SVGSwitchElement.systemLanguage')
  @DocsEditable
  StringList get systemLanguage native "SVGSwitchElement_systemLanguage_Getter";

  @DomName('SVGSwitchElement.hasExtension')
  @DocsEditable
  bool hasExtension(String extension) native "SVGSwitchElement_hasExtension_Callback";

  @DomName('SVGSwitchElement.transform')
  @DocsEditable
  AnimatedTransformList get transform native "SVGSwitchElement_transform_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGSymbolElement')
class SymbolElement extends StyledElement implements FitToViewBox, ExternalResourcesRequired, LangSpace {
  SymbolElement.internal() : super.internal();

  @DomName('SVGSymbolElement.SVGSymbolElement')
  @DocsEditable
  factory SymbolElement() => _SvgElementFactoryProvider.createSvgElement_tag("symbol");

  @DomName('SVGSymbolElement.externalResourcesRequired')
  @DocsEditable
  AnimatedBoolean get externalResourcesRequired native "SVGSymbolElement_externalResourcesRequired_Getter";

  @DomName('SVGSymbolElement.preserveAspectRatio')
  @DocsEditable
  AnimatedPreserveAspectRatio get preserveAspectRatio native "SVGSymbolElement_preserveAspectRatio_Getter";

  @DomName('SVGSymbolElement.viewBox')
  @DocsEditable
  AnimatedRect get viewBox native "SVGSymbolElement_viewBox_Getter";

  @DomName('SVGSymbolElement.xmllang')
  @DocsEditable
  String get xmllang native "SVGSymbolElement_xmllang_Getter";

  @DomName('SVGSymbolElement.xmllang')
  @DocsEditable
  void set xmllang(String value) native "SVGSymbolElement_xmllang_Setter";

  @DomName('SVGSymbolElement.xmlspace')
  @DocsEditable
  String get xmlspace native "SVGSymbolElement_xmlspace_Getter";

  @DomName('SVGSymbolElement.xmlspace')
  @DocsEditable
  void set xmlspace(String value) native "SVGSymbolElement_xmlspace_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGTSpanElement')
class TSpanElement extends TextPositioningElement {
  TSpanElement.internal() : super.internal();

  @DomName('SVGTSpanElement.SVGTSpanElement')
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

  @DomName('SVGTests.requiredExtensions')
  @DocsEditable
  StringList get requiredExtensions native "SVGTests_requiredExtensions_Getter";

  @DomName('SVGTests.requiredFeatures')
  @DocsEditable
  StringList get requiredFeatures native "SVGTests_requiredFeatures_Getter";

  @DomName('SVGTests.systemLanguage')
  @DocsEditable
  StringList get systemLanguage native "SVGTests_systemLanguage_Getter";

  @DomName('SVGTests.hasExtension')
  @DocsEditable
  bool hasExtension(String extension) native "SVGTests_hasExtension_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGTextContentElement')
class TextContentElement extends StyledElement implements Tests, ExternalResourcesRequired, LangSpace {
  TextContentElement.internal() : super.internal();

  static const int LENGTHADJUST_SPACING = 1;

  static const int LENGTHADJUST_SPACINGANDGLYPHS = 2;

  static const int LENGTHADJUST_UNKNOWN = 0;

  @DomName('SVGTextContentElement.lengthAdjust')
  @DocsEditable
  AnimatedEnumeration get lengthAdjust native "SVGTextContentElement_lengthAdjust_Getter";

  @DomName('SVGTextContentElement.textLength')
  @DocsEditable
  AnimatedLength get textLength native "SVGTextContentElement_textLength_Getter";

  @DomName('SVGTextContentElement.getCharNumAtPosition')
  @DocsEditable
  int getCharNumAtPosition(Point point) native "SVGTextContentElement_getCharNumAtPosition_Callback";

  @DomName('SVGTextContentElement.getComputedTextLength')
  @DocsEditable
  num getComputedTextLength() native "SVGTextContentElement_getComputedTextLength_Callback";

  @DomName('SVGTextContentElement.getEndPositionOfChar')
  @DocsEditable
  Point getEndPositionOfChar(int offset) native "SVGTextContentElement_getEndPositionOfChar_Callback";

  @DomName('SVGTextContentElement.getExtentOfChar')
  @DocsEditable
  Rect getExtentOfChar(int offset) native "SVGTextContentElement_getExtentOfChar_Callback";

  @DomName('SVGTextContentElement.getNumberOfChars')
  @DocsEditable
  int getNumberOfChars() native "SVGTextContentElement_getNumberOfChars_Callback";

  @DomName('SVGTextContentElement.getRotationOfChar')
  @DocsEditable
  num getRotationOfChar(int offset) native "SVGTextContentElement_getRotationOfChar_Callback";

  @DomName('SVGTextContentElement.getStartPositionOfChar')
  @DocsEditable
  Point getStartPositionOfChar(int offset) native "SVGTextContentElement_getStartPositionOfChar_Callback";

  @DomName('SVGTextContentElement.getSubStringLength')
  @DocsEditable
  num getSubStringLength(int offset, int length) native "SVGTextContentElement_getSubStringLength_Callback";

  @DomName('SVGTextContentElement.selectSubString')
  @DocsEditable
  void selectSubString(int offset, int length) native "SVGTextContentElement_selectSubString_Callback";

  @DomName('SVGTextContentElement.externalResourcesRequired')
  @DocsEditable
  AnimatedBoolean get externalResourcesRequired native "SVGTextContentElement_externalResourcesRequired_Getter";

  @DomName('SVGTextContentElement.xmllang')
  @DocsEditable
  String get xmllang native "SVGTextContentElement_xmllang_Getter";

  @DomName('SVGTextContentElement.xmllang')
  @DocsEditable
  void set xmllang(String value) native "SVGTextContentElement_xmllang_Setter";

  @DomName('SVGTextContentElement.xmlspace')
  @DocsEditable
  String get xmlspace native "SVGTextContentElement_xmlspace_Getter";

  @DomName('SVGTextContentElement.xmlspace')
  @DocsEditable
  void set xmlspace(String value) native "SVGTextContentElement_xmlspace_Setter";

  @DomName('SVGTextContentElement.requiredExtensions')
  @DocsEditable
  StringList get requiredExtensions native "SVGTextContentElement_requiredExtensions_Getter";

  @DomName('SVGTextContentElement.requiredFeatures')
  @DocsEditable
  StringList get requiredFeatures native "SVGTextContentElement_requiredFeatures_Getter";

  @DomName('SVGTextContentElement.systemLanguage')
  @DocsEditable
  StringList get systemLanguage native "SVGTextContentElement_systemLanguage_Getter";

  @DomName('SVGTextContentElement.hasExtension')
  @DocsEditable
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

  @DomName('SVGTextElement.SVGTextElement')
  @DocsEditable
  factory TextElement() => _SvgElementFactoryProvider.createSvgElement_tag("text");

  @DomName('SVGTextElement.farthestViewportElement')
  @DocsEditable
  SvgElement get farthestViewportElement native "SVGTextElement_farthestViewportElement_Getter";

  @DomName('SVGTextElement.nearestViewportElement')
  @DocsEditable
  SvgElement get nearestViewportElement native "SVGTextElement_nearestViewportElement_Getter";

  @DomName('SVGTextElement.getBBox')
  @DocsEditable
  Rect getBBox() native "SVGTextElement_getBBox_Callback";

  @DomName('SVGTextElement.getCTM')
  @DocsEditable
  Matrix getCtm() native "SVGTextElement_getCTM_Callback";

  @DomName('SVGTextElement.getScreenCTM')
  @DocsEditable
  Matrix getScreenCtm() native "SVGTextElement_getScreenCTM_Callback";

  @DomName('SVGTextElement.getTransformToElement')
  @DocsEditable
  Matrix getTransformToElement(SvgElement element) native "SVGTextElement_getTransformToElement_Callback";

  @DomName('SVGTextElement.transform')
  @DocsEditable
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

  @DomName('SVGTextPathElement.method')
  @DocsEditable
  AnimatedEnumeration get method native "SVGTextPathElement_method_Getter";

  @DomName('SVGTextPathElement.spacing')
  @DocsEditable
  AnimatedEnumeration get spacing native "SVGTextPathElement_spacing_Getter";

  @DomName('SVGTextPathElement.startOffset')
  @DocsEditable
  AnimatedLength get startOffset native "SVGTextPathElement_startOffset_Getter";

  @DomName('SVGTextPathElement.href')
  @DocsEditable
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

  @DomName('SVGTextPositioningElement.dx')
  @DocsEditable
  AnimatedLengthList get dx native "SVGTextPositioningElement_dx_Getter";

  @DomName('SVGTextPositioningElement.dy')
  @DocsEditable
  AnimatedLengthList get dy native "SVGTextPositioningElement_dy_Getter";

  @DomName('SVGTextPositioningElement.rotate')
  @DocsEditable
  AnimatedNumberList get rotate native "SVGTextPositioningElement_rotate_Getter";

  @DomName('SVGTextPositioningElement.x')
  @DocsEditable
  AnimatedLengthList get x native "SVGTextPositioningElement_x_Getter";

  @DomName('SVGTextPositioningElement.y')
  @DocsEditable
  AnimatedLengthList get y native "SVGTextPositioningElement_y_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGTitleElement')
class TitleElement extends StyledElement implements LangSpace {
  TitleElement.internal() : super.internal();

  @DomName('SVGTitleElement.SVGTitleElement')
  @DocsEditable
  factory TitleElement() => _SvgElementFactoryProvider.createSvgElement_tag("title");

  @DomName('SVGTitleElement.xmllang')
  @DocsEditable
  String get xmllang native "SVGTitleElement_xmllang_Getter";

  @DomName('SVGTitleElement.xmllang')
  @DocsEditable
  void set xmllang(String value) native "SVGTitleElement_xmllang_Setter";

  @DomName('SVGTitleElement.xmlspace')
  @DocsEditable
  String get xmlspace native "SVGTitleElement_xmlspace_Getter";

  @DomName('SVGTitleElement.xmlspace')
  @DocsEditable
  void set xmlspace(String value) native "SVGTitleElement_xmlspace_Setter";

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

  @DomName('SVGTransform.angle')
  @DocsEditable
  num get angle native "SVGTransform_angle_Getter";

  @DomName('SVGTransform.matrix')
  @DocsEditable
  Matrix get matrix native "SVGTransform_matrix_Getter";

  @DomName('SVGTransform.type')
  @DocsEditable
  int get type native "SVGTransform_type_Getter";

  @DomName('SVGTransform.setMatrix')
  @DocsEditable
  void setMatrix(Matrix matrix) native "SVGTransform_setMatrix_Callback";

  @DomName('SVGTransform.setRotate')
  @DocsEditable
  void setRotate(num angle, num cx, num cy) native "SVGTransform_setRotate_Callback";

  @DomName('SVGTransform.setScale')
  @DocsEditable
  void setScale(num sx, num sy) native "SVGTransform_setScale_Callback";

  @DomName('SVGTransform.setSkewX')
  @DocsEditable
  void setSkewX(num angle) native "SVGTransform_setSkewX_Callback";

  @DomName('SVGTransform.setSkewY')
  @DocsEditable
  void setSkewY(num angle) native "SVGTransform_setSkewY_Callback";

  @DomName('SVGTransform.setTranslate')
  @DocsEditable
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

  @DomName('SVGTransformList.numberOfItems')
  @DocsEditable
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
  Transform reduce(Transform combine(Transform value, Transform element)) {
    return IterableMixinWorkaround.reduce(this, combine);
  }

  dynamic fold(dynamic initialValue,
               dynamic combine(dynamic previousValue, Transform element)) {
    return IterableMixinWorkaround.fold(this, initialValue, combine);
  }

  bool contains(Transform element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(Transform element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator = ""]) =>
      IterableMixinWorkaround.joinList(this, separator);

  Iterable map(f(Transform element)) =>
      IterableMixinWorkaround.mapList(this, f);

  Iterable<Transform> where(bool f(Transform element)) =>
      IterableMixinWorkaround.where(this, f);

  Iterable expand(Iterable f(Transform element)) =>
      IterableMixinWorkaround.expand(this, f);

  bool every(bool f(Transform element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(Transform element)) => IterableMixinWorkaround.any(this, f);

  List<Transform> toList({ bool growable: true }) =>
      new List<Transform>.from(this, growable: growable);

  Set<Transform> toSet() => new Set<Transform>.from(this);

  bool get isEmpty => this.length == 0;

  Iterable<Transform> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<Transform> takeWhile(bool test(Transform value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  Iterable<Transform> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<Transform> skipWhile(bool test(Transform value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  Transform firstWhere(bool test(Transform value), { Transform orElse() }) {
    return IterableMixinWorkaround.firstWhere(this, test, orElse);
  }

  Transform lastWhere(bool test(Transform value), {Transform orElse()}) {
    return IterableMixinWorkaround.lastWhereList(this, test, orElse);
  }

  Transform singleWhere(bool test(Transform value)) {
    return IterableMixinWorkaround.singleWhere(this, test);
  }

  Transform elementAt(int index) {
    return this[index];
  }

  // From Collection<Transform>:

  void add(Transform value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<Transform> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<Transform>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  // clear() defined by IDL.

  Iterable<Transform> get reversed {
    return IterableMixinWorkaround.reversedList(this);
  }

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

  void insert(int index, Transform element) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void insertAll(int index, Iterable<Transform> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void setAll(int index, Iterable<Transform> iterable) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }

  Transform removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  Transform removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeWhere(bool test(Transform element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainWhere(bool test(Transform element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int end, Iterable<Transform> iterable, [int skipCount]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int end) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void replaceRange(int start, int end, Iterable<Transform> iterable) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }

  void fillRange(int start, int end, [Transform fillValue]) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }

  Iterable<Transform> getRange(int start, int end) =>
    IterableMixinWorkaround.getRangeList(this, start, end);

  List<Transform> sublist(int start, [int end]) {
    if (end == null) end = length;
    return Lists.getRange(this, start, end, <Transform>[]);
  }

  Map<int, Transform> asMap() =>
    IterableMixinWorkaround.asMapList(this);

  String toString() {
    StringBuffer buffer = new StringBuffer('[');
    buffer.writeAll(this, ', ');
    buffer.write(']');
    return buffer.toString();
  }

  // -- end List<Transform> mixins.

  @DomName('SVGTransformList.appendItem')
  @DocsEditable
  Transform appendItem(Transform item) native "SVGTransformList_appendItem_Callback";

  @DomName('SVGTransformList.clear')
  @DocsEditable
  void clear() native "SVGTransformList_clear_Callback";

  @DomName('SVGTransformList.consolidate')
  @DocsEditable
  Transform consolidate() native "SVGTransformList_consolidate_Callback";

  @DomName('SVGTransformList.createSVGTransformFromMatrix')
  @DocsEditable
  Transform createSvgTransformFromMatrix(Matrix matrix) native "SVGTransformList_createSVGTransformFromMatrix_Callback";

  @DomName('SVGTransformList.getItem')
  @DocsEditable
  Transform getItem(int index) native "SVGTransformList_getItem_Callback";

  @DomName('SVGTransformList.initialize')
  @DocsEditable
  Transform initialize(Transform item) native "SVGTransformList_initialize_Callback";

  @DomName('SVGTransformList.insertItemBefore')
  @DocsEditable
  Transform insertItemBefore(Transform item, int index) native "SVGTransformList_insertItemBefore_Callback";

  @DomName('SVGTransformList.removeItem')
  @DocsEditable
  Transform removeItem(int index) native "SVGTransformList_removeItem_Callback";

  @DomName('SVGTransformList.replaceItem')
  @DocsEditable
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

  @DomName('SVGTransformable.transform')
  @DocsEditable
  AnimatedTransformList get transform native "SVGTransformable_transform_Getter";

  @DomName('SVGTransformable.farthestViewportElement')
  @DocsEditable
  SvgElement get farthestViewportElement native "SVGTransformable_farthestViewportElement_Getter";

  @DomName('SVGTransformable.nearestViewportElement')
  @DocsEditable
  SvgElement get nearestViewportElement native "SVGTransformable_nearestViewportElement_Getter";

  @DomName('SVGTransformable.getBBox')
  @DocsEditable
  Rect getBBox() native "SVGTransformable_getBBox_Callback";

  @DomName('SVGTransformable.getCTM')
  @DocsEditable
  Matrix getCtm() native "SVGTransformable_getCTM_Callback";

  @DomName('SVGTransformable.getScreenCTM')
  @DocsEditable
  Matrix getScreenCtm() native "SVGTransformable_getScreenCTM_Callback";

  @DomName('SVGTransformable.getTransformToElement')
  @DocsEditable
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

  @DomName('SVGURIReference.href')
  @DocsEditable
  AnimatedString get href native "SVGURIReference_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGUseElement')
class UseElement extends StyledElement implements UriReference, Tests, Transformable, ExternalResourcesRequired, LangSpace {
  UseElement.internal() : super.internal();

  @DomName('SVGUseElement.SVGUseElement')
  @DocsEditable
  factory UseElement() => _SvgElementFactoryProvider.createSvgElement_tag("use");

  @DomName('SVGUseElement.animatedInstanceRoot')
  @DocsEditable
  ElementInstance get animatedInstanceRoot native "SVGUseElement_animatedInstanceRoot_Getter";

  @DomName('SVGUseElement.height')
  @DocsEditable
  AnimatedLength get height native "SVGUseElement_height_Getter";

  @DomName('SVGUseElement.instanceRoot')
  @DocsEditable
  ElementInstance get instanceRoot native "SVGUseElement_instanceRoot_Getter";

  @DomName('SVGUseElement.width')
  @DocsEditable
  AnimatedLength get width native "SVGUseElement_width_Getter";

  @DomName('SVGUseElement.x')
  @DocsEditable
  AnimatedLength get x native "SVGUseElement_x_Getter";

  @DomName('SVGUseElement.y')
  @DocsEditable
  AnimatedLength get y native "SVGUseElement_y_Getter";

  @DomName('SVGUseElement.externalResourcesRequired')
  @DocsEditable
  AnimatedBoolean get externalResourcesRequired native "SVGUseElement_externalResourcesRequired_Getter";

  @DomName('SVGUseElement.xmllang')
  @DocsEditable
  String get xmllang native "SVGUseElement_xmllang_Getter";

  @DomName('SVGUseElement.xmllang')
  @DocsEditable
  void set xmllang(String value) native "SVGUseElement_xmllang_Setter";

  @DomName('SVGUseElement.xmlspace')
  @DocsEditable
  String get xmlspace native "SVGUseElement_xmlspace_Getter";

  @DomName('SVGUseElement.xmlspace')
  @DocsEditable
  void set xmlspace(String value) native "SVGUseElement_xmlspace_Setter";

  @DomName('SVGUseElement.farthestViewportElement')
  @DocsEditable
  SvgElement get farthestViewportElement native "SVGUseElement_farthestViewportElement_Getter";

  @DomName('SVGUseElement.nearestViewportElement')
  @DocsEditable
  SvgElement get nearestViewportElement native "SVGUseElement_nearestViewportElement_Getter";

  @DomName('SVGUseElement.getBBox')
  @DocsEditable
  Rect getBBox() native "SVGUseElement_getBBox_Callback";

  @DomName('SVGUseElement.getCTM')
  @DocsEditable
  Matrix getCtm() native "SVGUseElement_getCTM_Callback";

  @DomName('SVGUseElement.getScreenCTM')
  @DocsEditable
  Matrix getScreenCtm() native "SVGUseElement_getScreenCTM_Callback";

  @DomName('SVGUseElement.getTransformToElement')
  @DocsEditable
  Matrix getTransformToElement(SvgElement element) native "SVGUseElement_getTransformToElement_Callback";

  @DomName('SVGUseElement.requiredExtensions')
  @DocsEditable
  StringList get requiredExtensions native "SVGUseElement_requiredExtensions_Getter";

  @DomName('SVGUseElement.requiredFeatures')
  @DocsEditable
  StringList get requiredFeatures native "SVGUseElement_requiredFeatures_Getter";

  @DomName('SVGUseElement.systemLanguage')
  @DocsEditable
  StringList get systemLanguage native "SVGUseElement_systemLanguage_Getter";

  @DomName('SVGUseElement.hasExtension')
  @DocsEditable
  bool hasExtension(String extension) native "SVGUseElement_hasExtension_Callback";

  @DomName('SVGUseElement.transform')
  @DocsEditable
  AnimatedTransformList get transform native "SVGUseElement_transform_Getter";

  @DomName('SVGUseElement.href')
  @DocsEditable
  AnimatedString get href native "SVGUseElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGViewElement')
class ViewElement extends SvgElement implements FitToViewBox, ExternalResourcesRequired, ZoomAndPan {
  ViewElement.internal() : super.internal();

  @DomName('SVGViewElement.SVGViewElement')
  @DocsEditable
  factory ViewElement() => _SvgElementFactoryProvider.createSvgElement_tag("view");

  @DomName('SVGViewElement.viewTarget')
  @DocsEditable
  StringList get viewTarget native "SVGViewElement_viewTarget_Getter";

  @DomName('SVGViewElement.externalResourcesRequired')
  @DocsEditable
  AnimatedBoolean get externalResourcesRequired native "SVGViewElement_externalResourcesRequired_Getter";

  @DomName('SVGViewElement.preserveAspectRatio')
  @DocsEditable
  AnimatedPreserveAspectRatio get preserveAspectRatio native "SVGViewElement_preserveAspectRatio_Getter";

  @DomName('SVGViewElement.viewBox')
  @DocsEditable
  AnimatedRect get viewBox native "SVGViewElement_viewBox_Getter";

  @DomName('SVGViewElement.zoomAndPan')
  @DocsEditable
  int get zoomAndPan native "SVGViewElement_zoomAndPan_Getter";

  @DomName('SVGViewElement.zoomAndPan')
  @DocsEditable
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

  @DomName('SVGViewSpec.preserveAspectRatio')
  @DocsEditable
  AnimatedPreserveAspectRatio get preserveAspectRatio native "SVGViewSpec_preserveAspectRatio_Getter";

  @DomName('SVGViewSpec.preserveAspectRatioString')
  @DocsEditable
  String get preserveAspectRatioString native "SVGViewSpec_preserveAspectRatioString_Getter";

  @DomName('SVGViewSpec.transform')
  @DocsEditable
  TransformList get transform native "SVGViewSpec_transform_Getter";

  @DomName('SVGViewSpec.transformString')
  @DocsEditable
  String get transformString native "SVGViewSpec_transformString_Getter";

  @DomName('SVGViewSpec.viewBox')
  @DocsEditable
  AnimatedRect get viewBox native "SVGViewSpec_viewBox_Getter";

  @DomName('SVGViewSpec.viewBoxString')
  @DocsEditable
  String get viewBoxString native "SVGViewSpec_viewBoxString_Getter";

  @DomName('SVGViewSpec.viewTarget')
  @DocsEditable
  SvgElement get viewTarget native "SVGViewSpec_viewTarget_Getter";

  @DomName('SVGViewSpec.viewTargetString')
  @DocsEditable
  String get viewTargetString native "SVGViewSpec_viewTargetString_Getter";

  @DomName('SVGViewSpec.zoomAndPan')
  @DocsEditable
  int get zoomAndPan native "SVGViewSpec_zoomAndPan_Getter";

  @DomName('SVGViewSpec.zoomAndPan')
  @DocsEditable
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

  @DomName('SVGZoomAndPan.zoomAndPan')
  @DocsEditable
  int get zoomAndPan native "SVGZoomAndPan_zoomAndPan_Getter";

  @DomName('SVGZoomAndPan.zoomAndPan')
  @DocsEditable
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

  @DomName('SVGZoomEvent.newScale')
  @DocsEditable
  num get newScale native "SVGZoomEvent_newScale_Getter";

  @DomName('SVGZoomEvent.newTranslate')
  @DocsEditable
  Point get newTranslate native "SVGZoomEvent_newTranslate_Getter";

  @DomName('SVGZoomEvent.previousScale')
  @DocsEditable
  num get previousScale native "SVGZoomEvent_previousScale_Getter";

  @DomName('SVGZoomEvent.previousTranslate')
  @DocsEditable
  Point get previousTranslate native "SVGZoomEvent_previousTranslate_Getter";

  @DomName('SVGZoomEvent.zoomRectScreen')
  @DocsEditable
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

  @DomName('SVGElementInstanceList.length')
  @DocsEditable
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

  ElementInstance reduce(ElementInstance combine(ElementInstance value, ElementInstance element)) {
    return IterableMixinWorkaround.reduce(this, combine);
  }

  dynamic fold(dynamic initialValue,
               dynamic combine(dynamic previousValue, ElementInstance element)) {
    return IterableMixinWorkaround.fold(this, initialValue, combine);
  }

  bool contains(ElementInstance element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(ElementInstance element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator = ""]) =>
      IterableMixinWorkaround.joinList(this, separator);

  Iterable map(f(ElementInstance element)) =>
      IterableMixinWorkaround.mapList(this, f);

  Iterable<ElementInstance> where(bool f(ElementInstance element)) =>
      IterableMixinWorkaround.where(this, f);

  Iterable expand(Iterable f(ElementInstance element)) =>
      IterableMixinWorkaround.expand(this, f);

  bool every(bool f(ElementInstance element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(ElementInstance element)) => IterableMixinWorkaround.any(this, f);

  List<ElementInstance> toList({ bool growable: true }) =>
      new List<ElementInstance>.from(this, growable: growable);

  Set<ElementInstance> toSet() => new Set<ElementInstance>.from(this);

  bool get isEmpty => this.length == 0;

  Iterable<ElementInstance> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<ElementInstance> takeWhile(bool test(ElementInstance value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  Iterable<ElementInstance> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<ElementInstance> skipWhile(bool test(ElementInstance value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  ElementInstance firstWhere(bool test(ElementInstance value), { ElementInstance orElse() }) {
    return IterableMixinWorkaround.firstWhere(this, test, orElse);
  }

  ElementInstance lastWhere(bool test(ElementInstance value), {ElementInstance orElse()}) {
    return IterableMixinWorkaround.lastWhereList(this, test, orElse);
  }

  ElementInstance singleWhere(bool test(ElementInstance value)) {
    return IterableMixinWorkaround.singleWhere(this, test);
  }

  ElementInstance elementAt(int index) {
    return this[index];
  }

  // From Collection<ElementInstance>:

  void add(ElementInstance value) {
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

  Iterable<ElementInstance> get reversed {
    return IterableMixinWorkaround.reversedList(this);
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

  void insert(int index, ElementInstance element) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void insertAll(int index, Iterable<ElementInstance> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void setAll(int index, Iterable<ElementInstance> iterable) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }

  ElementInstance removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  ElementInstance removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeWhere(bool test(ElementInstance element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainWhere(bool test(ElementInstance element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int end, Iterable<ElementInstance> iterable, [int skipCount]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int end) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void replaceRange(int start, int end, Iterable<ElementInstance> iterable) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }

  void fillRange(int start, int end, [ElementInstance fillValue]) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }

  Iterable<ElementInstance> getRange(int start, int end) =>
    IterableMixinWorkaround.getRangeList(this, start, end);

  List<ElementInstance> sublist(int start, [int end]) {
    if (end == null) end = length;
    return Lists.getRange(this, start, end, <ElementInstance>[]);
  }

  Map<int, ElementInstance> asMap() =>
    IterableMixinWorkaround.asMapList(this);

  String toString() {
    StringBuffer buffer = new StringBuffer('[');
    buffer.writeAll(this, ', ');
    buffer.write(']');
    return buffer.toString();
  }

  // -- end List<ElementInstance> mixins.

  @DomName('SVGElementInstanceList.item')
  @DocsEditable
  ElementInstance item(int index) native "SVGElementInstanceList_item_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGGradientElement')
class _GradientElement extends StyledElement implements UriReference, ExternalResourcesRequired {
  _GradientElement.internal() : super.internal();

  static const int SVG_SPREADMETHOD_PAD = 1;

  static const int SVG_SPREADMETHOD_REFLECT = 2;

  static const int SVG_SPREADMETHOD_REPEAT = 3;

  static const int SVG_SPREADMETHOD_UNKNOWN = 0;

  @DomName('SVGGradientElement.gradientTransform')
  @DocsEditable
  AnimatedTransformList get gradientTransform native "SVGGradientElement_gradientTransform_Getter";

  @DomName('SVGGradientElement.gradientUnits')
  @DocsEditable
  AnimatedEnumeration get gradientUnits native "SVGGradientElement_gradientUnits_Getter";

  @DomName('SVGGradientElement.spreadMethod')
  @DocsEditable
  AnimatedEnumeration get spreadMethod native "SVGGradientElement_spreadMethod_Getter";

  @DomName('SVGGradientElement.externalResourcesRequired')
  @DocsEditable
  AnimatedBoolean get externalResourcesRequired native "SVGGradientElement_externalResourcesRequired_Getter";

  @DomName('SVGGradientElement.href')
  @DocsEditable
  AnimatedString get href native "SVGGradientElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGAltGlyphDefElement')
abstract class _SVGAltGlyphDefElement extends SvgElement {
  _SVGAltGlyphDefElement.internal() : super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGAltGlyphItemElement')
abstract class _SVGAltGlyphItemElement extends SvgElement {
  _SVGAltGlyphItemElement.internal() : super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGAnimateColorElement')
abstract class _SVGAnimateColorElement extends AnimationElement {
  _SVGAnimateColorElement.internal() : super.internal();

}
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// Hack because the baseclass is private in dart:html, and we want to omit this
// type entirely but can't.
@DocsEditable
@DomName('SVGColor')
class _SVGColor {
  _SVGColor.internal();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGComponentTransferFunctionElement')
abstract class _SVGComponentTransferFunctionElement extends SvgElement {
  _SVGComponentTransferFunctionElement.internal() : super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGCursorElement')
abstract class _SVGCursorElement extends SvgElement implements UriReference, Tests, ExternalResourcesRequired {
  _SVGCursorElement.internal() : super.internal();

  @DomName('SVGCursorElement.SVGCursorElement')
  @DocsEditable
  factory _SVGCursorElement() => _SvgElementFactoryProvider.createSvgElement_tag("cursor");

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFEDropShadowElement')
abstract class _SVGFEDropShadowElement extends StyledElement implements FilterPrimitiveStandardAttributes {
  _SVGFEDropShadowElement.internal() : super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFontElement')
abstract class _SVGFontElement extends SvgElement {
  _SVGFontElement.internal() : super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFontFaceElement')
abstract class _SVGFontFaceElement extends SvgElement {
  _SVGFontFaceElement.internal() : super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFontFaceFormatElement')
abstract class _SVGFontFaceFormatElement extends SvgElement {
  _SVGFontFaceFormatElement.internal() : super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFontFaceNameElement')
abstract class _SVGFontFaceNameElement extends SvgElement {
  _SVGFontFaceNameElement.internal() : super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFontFaceSrcElement')
abstract class _SVGFontFaceSrcElement extends SvgElement {
  _SVGFontFaceSrcElement.internal() : super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGFontFaceUriElement')
abstract class _SVGFontFaceUriElement extends SvgElement {
  _SVGFontFaceUriElement.internal() : super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGGlyphElement')
abstract class _SVGGlyphElement extends SvgElement {
  _SVGGlyphElement.internal() : super.internal();

  @DomName('SVGGlyphElement.SVGGlyphElement')
  @DocsEditable
  factory _SVGGlyphElement() => _SvgElementFactoryProvider.createSvgElement_tag("glyph");

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGGlyphRefElement')
abstract class _SVGGlyphRefElement extends StyledElement implements UriReference {
  _SVGGlyphRefElement.internal() : super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGHKernElement')
abstract class _SVGHKernElement extends SvgElement {
  _SVGHKernElement.internal() : super.internal();

  @DomName('SVGHKernElement.SVGHKernElement')
  @DocsEditable
  factory _SVGHKernElement() => _SvgElementFactoryProvider.createSvgElement_tag("hkern");

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGMPathElement')
abstract class _SVGMPathElement extends SvgElement implements UriReference, ExternalResourcesRequired {
  _SVGMPathElement.internal() : super.internal();

  @DomName('SVGMPathElement.SVGMPathElement')
  @DocsEditable
  factory _SVGMPathElement() => _SvgElementFactoryProvider.createSvgElement_tag("mpath");

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGMissingGlyphElement')
abstract class _SVGMissingGlyphElement extends StyledElement {
  _SVGMissingGlyphElement.internal() : super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGPaint')
abstract class _SVGPaint extends _SVGColor {
  _SVGPaint.internal() : super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGTRefElement')
abstract class _SVGTRefElement extends TextPositioningElement implements UriReference {
  _SVGTRefElement.internal() : super.internal();

  @DomName('SVGTRefElement.SVGTRefElement')
  @DocsEditable
  factory _SVGTRefElement() => _SvgElementFactoryProvider.createSvgElement_tag("tref");

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SVGVKernElement')
abstract class _SVGVKernElement extends SvgElement {
  _SVGVKernElement.internal() : super.internal();

  @DomName('SVGVKernElement.SVGVKernElement')
  @DocsEditable
  factory _SVGVKernElement() => _SvgElementFactoryProvider.createSvgElement_tag("vkern");

}
