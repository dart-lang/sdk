library svg;

import 'dart:async';
import 'dart:collection';
import 'dart:html';
import 'dart:html_common';
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


/// @docsEditable true
@DomName('SVGAElement')
class AElement extends SvgElement implements Transformable, Tests, UriReference, Stylable, ExternalResourcesRequired, LangSpace native "*SVGAElement" {

  /// @docsEditable true
  factory AElement() => _SvgElementFactoryProvider.createSvgElement_tag("a");

  /// @docsEditable true
  @DomName('SVGAElement.target')
  final AnimatedString target;

  // From SVGExternalResourcesRequired

  /// @docsEditable true
  @DomName('SVGAElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /// @docsEditable true
  @DomName('SVGAElement.xmllang')
  String xmllang;

  /// @docsEditable true
  @DomName('SVGAElement.xmlspace')
  String xmlspace;

  // From SVGLocatable

  /// @docsEditable true
  @DomName('SVGAElement.farthestViewportElement')
  final SvgElement farthestViewportElement;

  /// @docsEditable true
  @DomName('SVGAElement.nearestViewportElement')
  final SvgElement nearestViewportElement;

  /// @docsEditable true
  @DomName('SVGAElement.getBBox')
  Rect getBBox() native;

  /// @docsEditable true
  @JSName('getCTM')
  @DomName('SVGAElement.getCTM')
  Matrix getCtm() native;

  /// @docsEditable true
  @JSName('getScreenCTM')
  @DomName('SVGAElement.getScreenCTM')
  Matrix getScreenCtm() native;

  /// @docsEditable true
  @DomName('SVGAElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  // Shadowing definition.
  /// @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  /// @docsEditable true
  @DomName('SVGAElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  /// @docsEditable true
  @DomName('SVGAElement.requiredExtensions')
  final StringList requiredExtensions;

  /// @docsEditable true
  @DomName('SVGAElement.requiredFeatures')
  final StringList requiredFeatures;

  /// @docsEditable true
  @DomName('SVGAElement.systemLanguage')
  final StringList systemLanguage;

  /// @docsEditable true
  @DomName('SVGAElement.hasExtension')
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /// @docsEditable true
  @DomName('SVGAElement.transform')
  final AnimatedTransformList transform;

  // From SVGURIReference

  /// @docsEditable true
  @DomName('SVGAElement.href')
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGAltGlyphDefElement')
class AltGlyphDefElement extends SvgElement native "*SVGAltGlyphDefElement" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGAltGlyphElement')
class AltGlyphElement extends TextPositioningElement implements UriReference native "*SVGAltGlyphElement" {

  /// @docsEditable true
  @DomName('SVGAltGlyphElement.format')
  String format;

  /// @docsEditable true
  @DomName('SVGAltGlyphElement.glyphRef')
  String glyphRef;

  // From SVGURIReference

  /// @docsEditable true
  @DomName('SVGAltGlyphElement.href')
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGAltGlyphItemElement')
class AltGlyphItemElement extends SvgElement native "*SVGAltGlyphItemElement" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGAngle')
class Angle native "*SVGAngle" {

  static const int SVG_ANGLETYPE_DEG = 2;

  static const int SVG_ANGLETYPE_GRAD = 4;

  static const int SVG_ANGLETYPE_RAD = 3;

  static const int SVG_ANGLETYPE_UNKNOWN = 0;

  static const int SVG_ANGLETYPE_UNSPECIFIED = 1;

  /// @docsEditable true
  @DomName('SVGAngle.unitType')
  final int unitType;

  /// @docsEditable true
  @DomName('SVGAngle.value')
  num value;

  /// @docsEditable true
  @DomName('SVGAngle.valueAsString')
  String valueAsString;

  /// @docsEditable true
  @DomName('SVGAngle.valueInSpecifiedUnits')
  num valueInSpecifiedUnits;

  /// @docsEditable true
  @DomName('SVGAngle.convertToSpecifiedUnits')
  void convertToSpecifiedUnits(int unitType) native;

  /// @docsEditable true
  @DomName('SVGAngle.newValueSpecifiedUnits')
  void newValueSpecifiedUnits(int unitType, num valueInSpecifiedUnits) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGAnimateColorElement')
class AnimateColorElement extends AnimationElement native "*SVGAnimateColorElement" {

  /// @docsEditable true
  factory AnimateColorElement() => _SvgElementFactoryProvider.createSvgElement_tag("animateColor");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGAnimateElement')
class AnimateElement extends AnimationElement native "*SVGAnimateElement" {

  /// @docsEditable true
  factory AnimateElement() => _SvgElementFactoryProvider.createSvgElement_tag("animate");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGAnimateMotionElement')
class AnimateMotionElement extends AnimationElement native "*SVGAnimateMotionElement" {

  /// @docsEditable true
  factory AnimateMotionElement() => _SvgElementFactoryProvider.createSvgElement_tag("animateMotion");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGAnimateTransformElement')
class AnimateTransformElement extends AnimationElement native "*SVGAnimateTransformElement" {

  /// @docsEditable true
  factory AnimateTransformElement() => _SvgElementFactoryProvider.createSvgElement_tag("animateTransform");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGAnimatedAngle')
class AnimatedAngle native "*SVGAnimatedAngle" {

  /// @docsEditable true
  @DomName('SVGAnimatedAngle.animVal')
  final Angle animVal;

  /// @docsEditable true
  @DomName('SVGAnimatedAngle.baseVal')
  final Angle baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGAnimatedBoolean')
class AnimatedBoolean native "*SVGAnimatedBoolean" {

  /// @docsEditable true
  @DomName('SVGAnimatedBoolean.animVal')
  final bool animVal;

  /// @docsEditable true
  @DomName('SVGAnimatedBoolean.baseVal')
  bool baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGAnimatedEnumeration')
class AnimatedEnumeration native "*SVGAnimatedEnumeration" {

  /// @docsEditable true
  @DomName('SVGAnimatedEnumeration.animVal')
  final int animVal;

  /// @docsEditable true
  @DomName('SVGAnimatedEnumeration.baseVal')
  int baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGAnimatedInteger')
class AnimatedInteger native "*SVGAnimatedInteger" {

  /// @docsEditable true
  @DomName('SVGAnimatedInteger.animVal')
  final int animVal;

  /// @docsEditable true
  @DomName('SVGAnimatedInteger.baseVal')
  int baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGAnimatedLength')
class AnimatedLength native "*SVGAnimatedLength" {

  /// @docsEditable true
  @DomName('SVGAnimatedLength.animVal')
  final Length animVal;

  /// @docsEditable true
  @DomName('SVGAnimatedLength.baseVal')
  final Length baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGAnimatedLengthList')
class AnimatedLengthList native "*SVGAnimatedLengthList" {

  /// @docsEditable true
  @DomName('SVGAnimatedLengthList.animVal')
  final LengthList animVal;

  /// @docsEditable true
  @DomName('SVGAnimatedLengthList.baseVal')
  final LengthList baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGAnimatedNumber')
class AnimatedNumber native "*SVGAnimatedNumber" {

  /// @docsEditable true
  @DomName('SVGAnimatedNumber.animVal')
  final num animVal;

  /// @docsEditable true
  @DomName('SVGAnimatedNumber.baseVal')
  num baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGAnimatedNumberList')
class AnimatedNumberList native "*SVGAnimatedNumberList" {

  /// @docsEditable true
  @DomName('SVGAnimatedNumberList.animVal')
  final NumberList animVal;

  /// @docsEditable true
  @DomName('SVGAnimatedNumberList.baseVal')
  final NumberList baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGAnimatedPreserveAspectRatio')
class AnimatedPreserveAspectRatio native "*SVGAnimatedPreserveAspectRatio" {

  /// @docsEditable true
  @DomName('SVGAnimatedPreserveAspectRatio.animVal')
  final PreserveAspectRatio animVal;

  /// @docsEditable true
  @DomName('SVGAnimatedPreserveAspectRatio.baseVal')
  final PreserveAspectRatio baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGAnimatedRect')
class AnimatedRect native "*SVGAnimatedRect" {

  /// @docsEditable true
  @DomName('SVGAnimatedRect.animVal')
  final Rect animVal;

  /// @docsEditable true
  @DomName('SVGAnimatedRect.baseVal')
  final Rect baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGAnimatedString')
class AnimatedString native "*SVGAnimatedString" {

  /// @docsEditable true
  @DomName('SVGAnimatedString.animVal')
  final String animVal;

  /// @docsEditable true
  @DomName('SVGAnimatedString.baseVal')
  String baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGAnimatedTransformList')
class AnimatedTransformList native "*SVGAnimatedTransformList" {

  /// @docsEditable true
  @DomName('SVGAnimatedTransformList.animVal')
  final TransformList animVal;

  /// @docsEditable true
  @DomName('SVGAnimatedTransformList.baseVal')
  final TransformList baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGAnimationElement')
class AnimationElement extends SvgElement implements Tests, ElementTimeControl, ExternalResourcesRequired native "*SVGAnimationElement" {

  /// @docsEditable true
  factory AnimationElement() => _SvgElementFactoryProvider.createSvgElement_tag("animation");

  /// @docsEditable true
  @DomName('SVGAnimationElement.targetElement')
  final SvgElement targetElement;

  /// @docsEditable true
  @DomName('SVGAnimationElement.getCurrentTime')
  num getCurrentTime() native;

  /// @docsEditable true
  @DomName('SVGAnimationElement.getSimpleDuration')
  num getSimpleDuration() native;

  /// @docsEditable true
  @DomName('SVGAnimationElement.getStartTime')
  num getStartTime() native;

  // From ElementTimeControl

  /// @docsEditable true
  @DomName('SVGAnimationElement.beginElement')
  void beginElement() native;

  /// @docsEditable true
  @DomName('SVGAnimationElement.beginElementAt')
  void beginElementAt(num offset) native;

  /// @docsEditable true
  @DomName('SVGAnimationElement.endElement')
  void endElement() native;

  /// @docsEditable true
  @DomName('SVGAnimationElement.endElementAt')
  void endElementAt(num offset) native;

  // From SVGExternalResourcesRequired

  /// @docsEditable true
  @DomName('SVGAnimationElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGTests

  /// @docsEditable true
  @DomName('SVGAnimationElement.requiredExtensions')
  final StringList requiredExtensions;

  /// @docsEditable true
  @DomName('SVGAnimationElement.requiredFeatures')
  final StringList requiredFeatures;

  /// @docsEditable true
  @DomName('SVGAnimationElement.systemLanguage')
  final StringList systemLanguage;

  /// @docsEditable true
  @DomName('SVGAnimationElement.hasExtension')
  bool hasExtension(String extension) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGCircleElement')
class CircleElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGCircleElement" {

  /// @docsEditable true
  factory CircleElement() => _SvgElementFactoryProvider.createSvgElement_tag("circle");

  /// @docsEditable true
  @DomName('SVGCircleElement.cx')
  final AnimatedLength cx;

  /// @docsEditable true
  @DomName('SVGCircleElement.cy')
  final AnimatedLength cy;

  /// @docsEditable true
  @DomName('SVGCircleElement.r')
  final AnimatedLength r;

  // From SVGExternalResourcesRequired

  /// @docsEditable true
  @DomName('SVGCircleElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /// @docsEditable true
  @DomName('SVGCircleElement.xmllang')
  String xmllang;

  /// @docsEditable true
  @DomName('SVGCircleElement.xmlspace')
  String xmlspace;

  // From SVGLocatable

  /// @docsEditable true
  @DomName('SVGCircleElement.farthestViewportElement')
  final SvgElement farthestViewportElement;

  /// @docsEditable true
  @DomName('SVGCircleElement.nearestViewportElement')
  final SvgElement nearestViewportElement;

  /// @docsEditable true
  @DomName('SVGCircleElement.getBBox')
  Rect getBBox() native;

  /// @docsEditable true
  @JSName('getCTM')
  @DomName('SVGCircleElement.getCTM')
  Matrix getCtm() native;

  /// @docsEditable true
  @JSName('getScreenCTM')
  @DomName('SVGCircleElement.getScreenCTM')
  Matrix getScreenCtm() native;

  /// @docsEditable true
  @DomName('SVGCircleElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  // Shadowing definition.
  /// @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  /// @docsEditable true
  @DomName('SVGCircleElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  /// @docsEditable true
  @DomName('SVGCircleElement.requiredExtensions')
  final StringList requiredExtensions;

  /// @docsEditable true
  @DomName('SVGCircleElement.requiredFeatures')
  final StringList requiredFeatures;

  /// @docsEditable true
  @DomName('SVGCircleElement.systemLanguage')
  final StringList systemLanguage;

  /// @docsEditable true
  @DomName('SVGCircleElement.hasExtension')
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /// @docsEditable true
  @DomName('SVGCircleElement.transform')
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGClipPathElement')
class ClipPathElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGClipPathElement" {

  /// @docsEditable true
  factory ClipPathElement() => _SvgElementFactoryProvider.createSvgElement_tag("clipPath");

  /// @docsEditable true
  @DomName('SVGClipPathElement.clipPathUnits')
  final AnimatedEnumeration clipPathUnits;

  // From SVGExternalResourcesRequired

  /// @docsEditable true
  @DomName('SVGClipPathElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /// @docsEditable true
  @DomName('SVGClipPathElement.xmllang')
  String xmllang;

  /// @docsEditable true
  @DomName('SVGClipPathElement.xmlspace')
  String xmlspace;

  // From SVGLocatable

  /// @docsEditable true
  @DomName('SVGClipPathElement.farthestViewportElement')
  final SvgElement farthestViewportElement;

  /// @docsEditable true
  @DomName('SVGClipPathElement.nearestViewportElement')
  final SvgElement nearestViewportElement;

  /// @docsEditable true
  @DomName('SVGClipPathElement.getBBox')
  Rect getBBox() native;

  /// @docsEditable true
  @JSName('getCTM')
  @DomName('SVGClipPathElement.getCTM')
  Matrix getCtm() native;

  /// @docsEditable true
  @JSName('getScreenCTM')
  @DomName('SVGClipPathElement.getScreenCTM')
  Matrix getScreenCtm() native;

  /// @docsEditable true
  @DomName('SVGClipPathElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  // Shadowing definition.
  /// @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  /// @docsEditable true
  @DomName('SVGClipPathElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  /// @docsEditable true
  @DomName('SVGClipPathElement.requiredExtensions')
  final StringList requiredExtensions;

  /// @docsEditable true
  @DomName('SVGClipPathElement.requiredFeatures')
  final StringList requiredFeatures;

  /// @docsEditable true
  @DomName('SVGClipPathElement.systemLanguage')
  final StringList systemLanguage;

  /// @docsEditable true
  @DomName('SVGClipPathElement.hasExtension')
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /// @docsEditable true
  @DomName('SVGClipPathElement.transform')
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGColor')
class Color extends CssValue native "*SVGColor" {

  static const int SVG_COLORTYPE_CURRENTCOLOR = 3;

  static const int SVG_COLORTYPE_RGBCOLOR = 1;

  static const int SVG_COLORTYPE_RGBCOLOR_ICCCOLOR = 2;

  static const int SVG_COLORTYPE_UNKNOWN = 0;

  /// @docsEditable true
  @DomName('SVGColor.colorType')
  final int colorType;

  /// @docsEditable true
  @DomName('SVGColor.rgbColor')
  final RgbColor rgbColor;

  /// @docsEditable true
  @DomName('SVGColor.setColor')
  void setColor(int colorType, String rgbColor, String iccColor) native;

  /// @docsEditable true
  @JSName('setRGBColor')
  @DomName('SVGColor.setRGBColor')
  void setRgbColor(String rgbColor) native;

  /// @docsEditable true
  @JSName('setRGBColorICCColor')
  @DomName('SVGColor.setRGBColorICCColor')
  void setRgbColorIccColor(String rgbColor, String iccColor) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGComponentTransferFunctionElement')
class ComponentTransferFunctionElement extends SvgElement native "*SVGComponentTransferFunctionElement" {

  static const int SVG_FECOMPONENTTRANSFER_TYPE_DISCRETE = 3;

  static const int SVG_FECOMPONENTTRANSFER_TYPE_GAMMA = 5;

  static const int SVG_FECOMPONENTTRANSFER_TYPE_IDENTITY = 1;

  static const int SVG_FECOMPONENTTRANSFER_TYPE_LINEAR = 4;

  static const int SVG_FECOMPONENTTRANSFER_TYPE_TABLE = 2;

  static const int SVG_FECOMPONENTTRANSFER_TYPE_UNKNOWN = 0;

  /// @docsEditable true
  @DomName('SVGComponentTransferFunctionElement.amplitude')
  final AnimatedNumber amplitude;

  /// @docsEditable true
  @DomName('SVGComponentTransferFunctionElement.exponent')
  final AnimatedNumber exponent;

  /// @docsEditable true
  @DomName('SVGComponentTransferFunctionElement.intercept')
  final AnimatedNumber intercept;

  /// @docsEditable true
  @DomName('SVGComponentTransferFunctionElement.offset')
  final AnimatedNumber offset;

  /// @docsEditable true
  @DomName('SVGComponentTransferFunctionElement.slope')
  final AnimatedNumber slope;

  /// @docsEditable true
  @DomName('SVGComponentTransferFunctionElement.tableValues')
  final AnimatedNumberList tableValues;

  /// @docsEditable true
  @DomName('SVGComponentTransferFunctionElement.type')
  final AnimatedEnumeration type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGCursorElement')
class CursorElement extends SvgElement implements UriReference, Tests, ExternalResourcesRequired native "*SVGCursorElement" {

  /// @docsEditable true
  factory CursorElement() => _SvgElementFactoryProvider.createSvgElement_tag("cursor");

  /// @docsEditable true
  @DomName('SVGCursorElement.x')
  final AnimatedLength x;

  /// @docsEditable true
  @DomName('SVGCursorElement.y')
  final AnimatedLength y;

  // From SVGExternalResourcesRequired

  /// @docsEditable true
  @DomName('SVGCursorElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGTests

  /// @docsEditable true
  @DomName('SVGCursorElement.requiredExtensions')
  final StringList requiredExtensions;

  /// @docsEditable true
  @DomName('SVGCursorElement.requiredFeatures')
  final StringList requiredFeatures;

  /// @docsEditable true
  @DomName('SVGCursorElement.systemLanguage')
  final StringList systemLanguage;

  /// @docsEditable true
  @DomName('SVGCursorElement.hasExtension')
  bool hasExtension(String extension) native;

  // From SVGURIReference

  /// @docsEditable true
  @DomName('SVGCursorElement.href')
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGDefsElement')
class DefsElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGDefsElement" {

  /// @docsEditable true
  factory DefsElement() => _SvgElementFactoryProvider.createSvgElement_tag("defs");

  // From SVGExternalResourcesRequired

  /// @docsEditable true
  @DomName('SVGDefsElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /// @docsEditable true
  @DomName('SVGDefsElement.xmllang')
  String xmllang;

  /// @docsEditable true
  @DomName('SVGDefsElement.xmlspace')
  String xmlspace;

  // From SVGLocatable

  /// @docsEditable true
  @DomName('SVGDefsElement.farthestViewportElement')
  final SvgElement farthestViewportElement;

  /// @docsEditable true
  @DomName('SVGDefsElement.nearestViewportElement')
  final SvgElement nearestViewportElement;

  /// @docsEditable true
  @DomName('SVGDefsElement.getBBox')
  Rect getBBox() native;

  /// @docsEditable true
  @JSName('getCTM')
  @DomName('SVGDefsElement.getCTM')
  Matrix getCtm() native;

  /// @docsEditable true
  @JSName('getScreenCTM')
  @DomName('SVGDefsElement.getScreenCTM')
  Matrix getScreenCtm() native;

  /// @docsEditable true
  @DomName('SVGDefsElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  // Shadowing definition.
  /// @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  /// @docsEditable true
  @DomName('SVGDefsElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  /// @docsEditable true
  @DomName('SVGDefsElement.requiredExtensions')
  final StringList requiredExtensions;

  /// @docsEditable true
  @DomName('SVGDefsElement.requiredFeatures')
  final StringList requiredFeatures;

  /// @docsEditable true
  @DomName('SVGDefsElement.systemLanguage')
  final StringList systemLanguage;

  /// @docsEditable true
  @DomName('SVGDefsElement.hasExtension')
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /// @docsEditable true
  @DomName('SVGDefsElement.transform')
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGDescElement')
class DescElement extends SvgElement implements Stylable, LangSpace native "*SVGDescElement" {

  /// @docsEditable true
  factory DescElement() => _SvgElementFactoryProvider.createSvgElement_tag("desc");

  // From SVGLangSpace

  /// @docsEditable true
  @DomName('SVGDescElement.xmllang')
  String xmllang;

  /// @docsEditable true
  @DomName('SVGDescElement.xmlspace')
  String xmlspace;

  // From SVGStylable

  // Shadowing definition.
  /// @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  /// @docsEditable true
  @DomName('SVGDescElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGElementInstance')
class ElementInstance extends EventTarget native "*SVGElementInstance" {

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

  /// @docsEditable true
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  ElementInstanceEvents get on =>
    new ElementInstanceEvents(this);

  /// @docsEditable true
  @DomName('SVGElementInstance.childNodes')
  @Returns('_ElementInstanceList') @Creates('_ElementInstanceList')
  final List<ElementInstance> childNodes;

  /// @docsEditable true
  @DomName('SVGElementInstance.correspondingElement')
  final SvgElement correspondingElement;

  /// @docsEditable true
  @DomName('SVGElementInstance.correspondingUseElement')
  final UseElement correspondingUseElement;

  /// @docsEditable true
  @DomName('SVGElementInstance.firstChild')
  final ElementInstance firstChild;

  /// @docsEditable true
  @DomName('SVGElementInstance.lastChild')
  final ElementInstance lastChild;

  /// @docsEditable true
  @DomName('SVGElementInstance.nextSibling')
  final ElementInstance nextSibling;

  /// @docsEditable true
  @DomName('SVGElementInstance.parentNode')
  final ElementInstance parentNode;

  /// @docsEditable true
  @DomName('SVGElementInstance.previousSibling')
  final ElementInstance previousSibling;

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

/// @docsEditable true
class ElementInstanceEvents extends Events {
  /// @docsEditable true
  ElementInstanceEvents(EventTarget _ptr) : super(_ptr);

  /// @docsEditable true
  EventListenerList get abort => this['abort'];

  /// @docsEditable true
  EventListenerList get beforeCopy => this['beforecopy'];

  /// @docsEditable true
  EventListenerList get beforeCut => this['beforecut'];

  /// @docsEditable true
  EventListenerList get beforePaste => this['beforepaste'];

  /// @docsEditable true
  EventListenerList get blur => this['blur'];

  /// @docsEditable true
  EventListenerList get change => this['change'];

  /// @docsEditable true
  EventListenerList get click => this['click'];

  /// @docsEditable true
  EventListenerList get contextMenu => this['contextmenu'];

  /// @docsEditable true
  EventListenerList get copy => this['copy'];

  /// @docsEditable true
  EventListenerList get cut => this['cut'];

  /// @docsEditable true
  EventListenerList get doubleClick => this['dblclick'];

  /// @docsEditable true
  EventListenerList get drag => this['drag'];

  /// @docsEditable true
  EventListenerList get dragEnd => this['dragend'];

  /// @docsEditable true
  EventListenerList get dragEnter => this['dragenter'];

  /// @docsEditable true
  EventListenerList get dragLeave => this['dragleave'];

  /// @docsEditable true
  EventListenerList get dragOver => this['dragover'];

  /// @docsEditable true
  EventListenerList get dragStart => this['dragstart'];

  /// @docsEditable true
  EventListenerList get drop => this['drop'];

  /// @docsEditable true
  EventListenerList get error => this['error'];

  /// @docsEditable true
  EventListenerList get focus => this['focus'];

  /// @docsEditable true
  EventListenerList get input => this['input'];

  /// @docsEditable true
  EventListenerList get keyDown => this['keydown'];

  /// @docsEditable true
  EventListenerList get keyPress => this['keypress'];

  /// @docsEditable true
  EventListenerList get keyUp => this['keyup'];

  /// @docsEditable true
  EventListenerList get load => this['load'];

  /// @docsEditable true
  EventListenerList get mouseDown => this['mousedown'];

  /// @docsEditable true
  EventListenerList get mouseMove => this['mousemove'];

  /// @docsEditable true
  EventListenerList get mouseOut => this['mouseout'];

  /// @docsEditable true
  EventListenerList get mouseOver => this['mouseover'];

  /// @docsEditable true
  EventListenerList get mouseUp => this['mouseup'];

  /// @docsEditable true
  EventListenerList get mouseWheel => this['mousewheel'];

  /// @docsEditable true
  EventListenerList get paste => this['paste'];

  /// @docsEditable true
  EventListenerList get reset => this['reset'];

  /// @docsEditable true
  EventListenerList get resize => this['resize'];

  /// @docsEditable true
  EventListenerList get scroll => this['scroll'];

  /// @docsEditable true
  EventListenerList get search => this['search'];

  /// @docsEditable true
  EventListenerList get select => this['select'];

  /// @docsEditable true
  EventListenerList get selectStart => this['selectstart'];

  /// @docsEditable true
  EventListenerList get submit => this['submit'];

  /// @docsEditable true
  EventListenerList get unload => this['unload'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('ElementTimeControl')
abstract class ElementTimeControl {

  /// @docsEditable true
  void beginElement();

  /// @docsEditable true
  void beginElementAt(num offset);

  /// @docsEditable true
  void endElement();

  /// @docsEditable true
  void endElementAt(num offset);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGEllipseElement')
class EllipseElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGEllipseElement" {

  /// @docsEditable true
  factory EllipseElement() => _SvgElementFactoryProvider.createSvgElement_tag("ellipse");

  /// @docsEditable true
  @DomName('SVGEllipseElement.cx')
  final AnimatedLength cx;

  /// @docsEditable true
  @DomName('SVGEllipseElement.cy')
  final AnimatedLength cy;

  /// @docsEditable true
  @DomName('SVGEllipseElement.rx')
  final AnimatedLength rx;

  /// @docsEditable true
  @DomName('SVGEllipseElement.ry')
  final AnimatedLength ry;

  // From SVGExternalResourcesRequired

  /// @docsEditable true
  @DomName('SVGEllipseElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /// @docsEditable true
  @DomName('SVGEllipseElement.xmllang')
  String xmllang;

  /// @docsEditable true
  @DomName('SVGEllipseElement.xmlspace')
  String xmlspace;

  // From SVGLocatable

  /// @docsEditable true
  @DomName('SVGEllipseElement.farthestViewportElement')
  final SvgElement farthestViewportElement;

  /// @docsEditable true
  @DomName('SVGEllipseElement.nearestViewportElement')
  final SvgElement nearestViewportElement;

  /// @docsEditable true
  @DomName('SVGEllipseElement.getBBox')
  Rect getBBox() native;

  /// @docsEditable true
  @JSName('getCTM')
  @DomName('SVGEllipseElement.getCTM')
  Matrix getCtm() native;

  /// @docsEditable true
  @JSName('getScreenCTM')
  @DomName('SVGEllipseElement.getScreenCTM')
  Matrix getScreenCtm() native;

  /// @docsEditable true
  @DomName('SVGEllipseElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  // Shadowing definition.
  /// @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  /// @docsEditable true
  @DomName('SVGEllipseElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  /// @docsEditable true
  @DomName('SVGEllipseElement.requiredExtensions')
  final StringList requiredExtensions;

  /// @docsEditable true
  @DomName('SVGEllipseElement.requiredFeatures')
  final StringList requiredFeatures;

  /// @docsEditable true
  @DomName('SVGEllipseElement.systemLanguage')
  final StringList systemLanguage;

  /// @docsEditable true
  @DomName('SVGEllipseElement.hasExtension')
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /// @docsEditable true
  @DomName('SVGEllipseElement.transform')
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGExternalResourcesRequired')
abstract class ExternalResourcesRequired {

  AnimatedBoolean externalResourcesRequired;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGFEBlendElement')
class FEBlendElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEBlendElement" {

  static const int SVG_FEBLEND_MODE_DARKEN = 4;

  static const int SVG_FEBLEND_MODE_LIGHTEN = 5;

  static const int SVG_FEBLEND_MODE_MULTIPLY = 2;

  static const int SVG_FEBLEND_MODE_NORMAL = 1;

  static const int SVG_FEBLEND_MODE_SCREEN = 3;

  static const int SVG_FEBLEND_MODE_UNKNOWN = 0;

  /// @docsEditable true
  @DomName('SVGFEBlendElement.in1')
  final AnimatedString in1;

  /// @docsEditable true
  @DomName('SVGFEBlendElement.in2')
  final AnimatedString in2;

  /// @docsEditable true
  @DomName('SVGFEBlendElement.mode')
  final AnimatedEnumeration mode;

  // From SVGFilterPrimitiveStandardAttributes

  /// @docsEditable true
  @DomName('SVGFEBlendElement.height')
  final AnimatedLength height;

  /// @docsEditable true
  @DomName('SVGFEBlendElement.result')
  final AnimatedString result;

  /// @docsEditable true
  @DomName('SVGFEBlendElement.width')
  final AnimatedLength width;

  /// @docsEditable true
  @DomName('SVGFEBlendElement.x')
  final AnimatedLength x;

  /// @docsEditable true
  @DomName('SVGFEBlendElement.y')
  final AnimatedLength y;

  // From SVGStylable

  // Shadowing definition.
  /// @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  /// @docsEditable true
  @DomName('SVGFEBlendElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGFEColorMatrixElement')
class FEColorMatrixElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEColorMatrixElement" {

  static const int SVG_FECOLORMATRIX_TYPE_HUEROTATE = 3;

  static const int SVG_FECOLORMATRIX_TYPE_LUMINANCETOALPHA = 4;

  static const int SVG_FECOLORMATRIX_TYPE_MATRIX = 1;

  static const int SVG_FECOLORMATRIX_TYPE_SATURATE = 2;

  static const int SVG_FECOLORMATRIX_TYPE_UNKNOWN = 0;

  /// @docsEditable true
  @DomName('SVGFEColorMatrixElement.in1')
  final AnimatedString in1;

  /// @docsEditable true
  @DomName('SVGFEColorMatrixElement.type')
  final AnimatedEnumeration type;

  /// @docsEditable true
  @DomName('SVGFEColorMatrixElement.values')
  final AnimatedNumberList values;

  // From SVGFilterPrimitiveStandardAttributes

  /// @docsEditable true
  @DomName('SVGFEColorMatrixElement.height')
  final AnimatedLength height;

  /// @docsEditable true
  @DomName('SVGFEColorMatrixElement.result')
  final AnimatedString result;

  /// @docsEditable true
  @DomName('SVGFEColorMatrixElement.width')
  final AnimatedLength width;

  /// @docsEditable true
  @DomName('SVGFEColorMatrixElement.x')
  final AnimatedLength x;

  /// @docsEditable true
  @DomName('SVGFEColorMatrixElement.y')
  final AnimatedLength y;

  // From SVGStylable

  // Shadowing definition.
  /// @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  /// @docsEditable true
  @DomName('SVGFEColorMatrixElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGFEComponentTransferElement')
class FEComponentTransferElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEComponentTransferElement" {

  /// @docsEditable true
  @DomName('SVGFEComponentTransferElement.in1')
  final AnimatedString in1;

  // From SVGFilterPrimitiveStandardAttributes

  /// @docsEditable true
  @DomName('SVGFEComponentTransferElement.height')
  final AnimatedLength height;

  /// @docsEditable true
  @DomName('SVGFEComponentTransferElement.result')
  final AnimatedString result;

  /// @docsEditable true
  @DomName('SVGFEComponentTransferElement.width')
  final AnimatedLength width;

  /// @docsEditable true
  @DomName('SVGFEComponentTransferElement.x')
  final AnimatedLength x;

  /// @docsEditable true
  @DomName('SVGFEComponentTransferElement.y')
  final AnimatedLength y;

  // From SVGStylable

  // Shadowing definition.
  /// @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  /// @docsEditable true
  @DomName('SVGFEComponentTransferElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGFECompositeElement')
class FECompositeElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFECompositeElement" {

  static const int SVG_FECOMPOSITE_OPERATOR_ARITHMETIC = 6;

  static const int SVG_FECOMPOSITE_OPERATOR_ATOP = 4;

  static const int SVG_FECOMPOSITE_OPERATOR_IN = 2;

  static const int SVG_FECOMPOSITE_OPERATOR_OUT = 3;

  static const int SVG_FECOMPOSITE_OPERATOR_OVER = 1;

  static const int SVG_FECOMPOSITE_OPERATOR_UNKNOWN = 0;

  static const int SVG_FECOMPOSITE_OPERATOR_XOR = 5;

  /// @docsEditable true
  @DomName('SVGFECompositeElement.in1')
  final AnimatedString in1;

  /// @docsEditable true
  @DomName('SVGFECompositeElement.in2')
  final AnimatedString in2;

  /// @docsEditable true
  @DomName('SVGFECompositeElement.k1')
  final AnimatedNumber k1;

  /// @docsEditable true
  @DomName('SVGFECompositeElement.k2')
  final AnimatedNumber k2;

  /// @docsEditable true
  @DomName('SVGFECompositeElement.k3')
  final AnimatedNumber k3;

  /// @docsEditable true
  @DomName('SVGFECompositeElement.k4')
  final AnimatedNumber k4;

  /// @docsEditable true
  @DomName('SVGFECompositeElement.operator')
  final AnimatedEnumeration operator;

  // From SVGFilterPrimitiveStandardAttributes

  /// @docsEditable true
  @DomName('SVGFECompositeElement.height')
  final AnimatedLength height;

  /// @docsEditable true
  @DomName('SVGFECompositeElement.result')
  final AnimatedString result;

  /// @docsEditable true
  @DomName('SVGFECompositeElement.width')
  final AnimatedLength width;

  /// @docsEditable true
  @DomName('SVGFECompositeElement.x')
  final AnimatedLength x;

  /// @docsEditable true
  @DomName('SVGFECompositeElement.y')
  final AnimatedLength y;

  // From SVGStylable

  // Shadowing definition.
  /// @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  /// @docsEditable true
  @DomName('SVGFECompositeElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGFEConvolveMatrixElement')
class FEConvolveMatrixElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEConvolveMatrixElement" {

  static const int SVG_EDGEMODE_DUPLICATE = 1;

  static const int SVG_EDGEMODE_NONE = 3;

  static const int SVG_EDGEMODE_UNKNOWN = 0;

  static const int SVG_EDGEMODE_WRAP = 2;

  /// @docsEditable true
  @DomName('SVGFEConvolveMatrixElement.bias')
  final AnimatedNumber bias;

  /// @docsEditable true
  @DomName('SVGFEConvolveMatrixElement.divisor')
  final AnimatedNumber divisor;

  /// @docsEditable true
  @DomName('SVGFEConvolveMatrixElement.edgeMode')
  final AnimatedEnumeration edgeMode;

  /// @docsEditable true
  @DomName('SVGFEConvolveMatrixElement.in1')
  final AnimatedString in1;

  /// @docsEditable true
  @DomName('SVGFEConvolveMatrixElement.kernelMatrix')
  final AnimatedNumberList kernelMatrix;

  /// @docsEditable true
  @DomName('SVGFEConvolveMatrixElement.kernelUnitLengthX')
  final AnimatedNumber kernelUnitLengthX;

  /// @docsEditable true
  @DomName('SVGFEConvolveMatrixElement.kernelUnitLengthY')
  final AnimatedNumber kernelUnitLengthY;

  /// @docsEditable true
  @DomName('SVGFEConvolveMatrixElement.orderX')
  final AnimatedInteger orderX;

  /// @docsEditable true
  @DomName('SVGFEConvolveMatrixElement.orderY')
  final AnimatedInteger orderY;

  /// @docsEditable true
  @DomName('SVGFEConvolveMatrixElement.preserveAlpha')
  final AnimatedBoolean preserveAlpha;

  /// @docsEditable true
  @DomName('SVGFEConvolveMatrixElement.targetX')
  final AnimatedInteger targetX;

  /// @docsEditable true
  @DomName('SVGFEConvolveMatrixElement.targetY')
  final AnimatedInteger targetY;

  // From SVGFilterPrimitiveStandardAttributes

  /// @docsEditable true
  @DomName('SVGFEConvolveMatrixElement.height')
  final AnimatedLength height;

  /// @docsEditable true
  @DomName('SVGFEConvolveMatrixElement.result')
  final AnimatedString result;

  /// @docsEditable true
  @DomName('SVGFEConvolveMatrixElement.width')
  final AnimatedLength width;

  /// @docsEditable true
  @DomName('SVGFEConvolveMatrixElement.x')
  final AnimatedLength x;

  /// @docsEditable true
  @DomName('SVGFEConvolveMatrixElement.y')
  final AnimatedLength y;

  // From SVGStylable

  // Shadowing definition.
  /// @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  /// @docsEditable true
  @DomName('SVGFEConvolveMatrixElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGFEDiffuseLightingElement')
class FEDiffuseLightingElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEDiffuseLightingElement" {

  /// @docsEditable true
  @DomName('SVGFEDiffuseLightingElement.diffuseConstant')
  final AnimatedNumber diffuseConstant;

  /// @docsEditable true
  @DomName('SVGFEDiffuseLightingElement.in1')
  final AnimatedString in1;

  /// @docsEditable true
  @DomName('SVGFEDiffuseLightingElement.kernelUnitLengthX')
  final AnimatedNumber kernelUnitLengthX;

  /// @docsEditable true
  @DomName('SVGFEDiffuseLightingElement.kernelUnitLengthY')
  final AnimatedNumber kernelUnitLengthY;

  /// @docsEditable true
  @DomName('SVGFEDiffuseLightingElement.surfaceScale')
  final AnimatedNumber surfaceScale;

  // From SVGFilterPrimitiveStandardAttributes

  /// @docsEditable true
  @DomName('SVGFEDiffuseLightingElement.height')
  final AnimatedLength height;

  /// @docsEditable true
  @DomName('SVGFEDiffuseLightingElement.result')
  final AnimatedString result;

  /// @docsEditable true
  @DomName('SVGFEDiffuseLightingElement.width')
  final AnimatedLength width;

  /// @docsEditable true
  @DomName('SVGFEDiffuseLightingElement.x')
  final AnimatedLength x;

  /// @docsEditable true
  @DomName('SVGFEDiffuseLightingElement.y')
  final AnimatedLength y;

  // From SVGStylable

  // Shadowing definition.
  /// @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  /// @docsEditable true
  @DomName('SVGFEDiffuseLightingElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGFEDisplacementMapElement')
class FEDisplacementMapElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEDisplacementMapElement" {

  static const int SVG_CHANNEL_A = 4;

  static const int SVG_CHANNEL_B = 3;

  static const int SVG_CHANNEL_G = 2;

  static const int SVG_CHANNEL_R = 1;

  static const int SVG_CHANNEL_UNKNOWN = 0;

  /// @docsEditable true
  @DomName('SVGFEDisplacementMapElement.in1')
  final AnimatedString in1;

  /// @docsEditable true
  @DomName('SVGFEDisplacementMapElement.in2')
  final AnimatedString in2;

  /// @docsEditable true
  @DomName('SVGFEDisplacementMapElement.scale')
  final AnimatedNumber scale;

  /// @docsEditable true
  @DomName('SVGFEDisplacementMapElement.xChannelSelector')
  final AnimatedEnumeration xChannelSelector;

  /// @docsEditable true
  @DomName('SVGFEDisplacementMapElement.yChannelSelector')
  final AnimatedEnumeration yChannelSelector;

  // From SVGFilterPrimitiveStandardAttributes

  /// @docsEditable true
  @DomName('SVGFEDisplacementMapElement.height')
  final AnimatedLength height;

  /// @docsEditable true
  @DomName('SVGFEDisplacementMapElement.result')
  final AnimatedString result;

  /// @docsEditable true
  @DomName('SVGFEDisplacementMapElement.width')
  final AnimatedLength width;

  /// @docsEditable true
  @DomName('SVGFEDisplacementMapElement.x')
  final AnimatedLength x;

  /// @docsEditable true
  @DomName('SVGFEDisplacementMapElement.y')
  final AnimatedLength y;

  // From SVGStylable

  // Shadowing definition.
  /// @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  /// @docsEditable true
  @DomName('SVGFEDisplacementMapElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGFEDistantLightElement')
class FEDistantLightElement extends SvgElement native "*SVGFEDistantLightElement" {

  /// @docsEditable true
  @DomName('SVGFEDistantLightElement.azimuth')
  final AnimatedNumber azimuth;

  /// @docsEditable true
  @DomName('SVGFEDistantLightElement.elevation')
  final AnimatedNumber elevation;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGFEDropShadowElement')
class FEDropShadowElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEDropShadowElement" {

  /// @docsEditable true
  @DomName('SVGFEDropShadowElement.dx')
  final AnimatedNumber dx;

  /// @docsEditable true
  @DomName('SVGFEDropShadowElement.dy')
  final AnimatedNumber dy;

  /// @docsEditable true
  @DomName('SVGFEDropShadowElement.in1')
  final AnimatedString in1;

  /// @docsEditable true
  @DomName('SVGFEDropShadowElement.stdDeviationX')
  final AnimatedNumber stdDeviationX;

  /// @docsEditable true
  @DomName('SVGFEDropShadowElement.stdDeviationY')
  final AnimatedNumber stdDeviationY;

  /// @docsEditable true
  @DomName('SVGFEDropShadowElement.setStdDeviation')
  void setStdDeviation(num stdDeviationX, num stdDeviationY) native;

  // From SVGFilterPrimitiveStandardAttributes

  /// @docsEditable true
  @DomName('SVGFEDropShadowElement.height')
  final AnimatedLength height;

  /// @docsEditable true
  @DomName('SVGFEDropShadowElement.result')
  final AnimatedString result;

  /// @docsEditable true
  @DomName('SVGFEDropShadowElement.width')
  final AnimatedLength width;

  /// @docsEditable true
  @DomName('SVGFEDropShadowElement.x')
  final AnimatedLength x;

  /// @docsEditable true
  @DomName('SVGFEDropShadowElement.y')
  final AnimatedLength y;

  // From SVGStylable

  // Shadowing definition.
  /// @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  /// @docsEditable true
  @DomName('SVGFEDropShadowElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGFEFloodElement')
class FEFloodElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEFloodElement" {

  // From SVGFilterPrimitiveStandardAttributes

  /// @docsEditable true
  @DomName('SVGFEFloodElement.height')
  final AnimatedLength height;

  /// @docsEditable true
  @DomName('SVGFEFloodElement.result')
  final AnimatedString result;

  /// @docsEditable true
  @DomName('SVGFEFloodElement.width')
  final AnimatedLength width;

  /// @docsEditable true
  @DomName('SVGFEFloodElement.x')
  final AnimatedLength x;

  /// @docsEditable true
  @DomName('SVGFEFloodElement.y')
  final AnimatedLength y;

  // From SVGStylable

  // Shadowing definition.
  /// @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  /// @docsEditable true
  @DomName('SVGFEFloodElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGFEFuncAElement')
class FEFuncAElement extends ComponentTransferFunctionElement native "*SVGFEFuncAElement" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGFEFuncBElement')
class FEFuncBElement extends ComponentTransferFunctionElement native "*SVGFEFuncBElement" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGFEFuncGElement')
class FEFuncGElement extends ComponentTransferFunctionElement native "*SVGFEFuncGElement" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGFEFuncRElement')
class FEFuncRElement extends ComponentTransferFunctionElement native "*SVGFEFuncRElement" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGFEGaussianBlurElement')
class FEGaussianBlurElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEGaussianBlurElement" {

  /// @docsEditable true
  @DomName('SVGFEGaussianBlurElement.in1')
  final AnimatedString in1;

  /// @docsEditable true
  @DomName('SVGFEGaussianBlurElement.stdDeviationX')
  final AnimatedNumber stdDeviationX;

  /// @docsEditable true
  @DomName('SVGFEGaussianBlurElement.stdDeviationY')
  final AnimatedNumber stdDeviationY;

  /// @docsEditable true
  @DomName('SVGFEGaussianBlurElement.setStdDeviation')
  void setStdDeviation(num stdDeviationX, num stdDeviationY) native;

  // From SVGFilterPrimitiveStandardAttributes

  /// @docsEditable true
  @DomName('SVGFEGaussianBlurElement.height')
  final AnimatedLength height;

  /// @docsEditable true
  @DomName('SVGFEGaussianBlurElement.result')
  final AnimatedString result;

  /// @docsEditable true
  @DomName('SVGFEGaussianBlurElement.width')
  final AnimatedLength width;

  /// @docsEditable true
  @DomName('SVGFEGaussianBlurElement.x')
  final AnimatedLength x;

  /// @docsEditable true
  @DomName('SVGFEGaussianBlurElement.y')
  final AnimatedLength y;

  // From SVGStylable

  // Shadowing definition.
  /// @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  /// @docsEditable true
  @DomName('SVGFEGaussianBlurElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGFEImageElement')
class FEImageElement extends SvgElement implements FilterPrimitiveStandardAttributes, UriReference, ExternalResourcesRequired, LangSpace native "*SVGFEImageElement" {

  /// @docsEditable true
  @DomName('SVGFEImageElement.preserveAspectRatio')
  final AnimatedPreserveAspectRatio preserveAspectRatio;

  // From SVGExternalResourcesRequired

  /// @docsEditable true
  @DomName('SVGFEImageElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGFilterPrimitiveStandardAttributes

  /// @docsEditable true
  @DomName('SVGFEImageElement.height')
  final AnimatedLength height;

  /// @docsEditable true
  @DomName('SVGFEImageElement.result')
  final AnimatedString result;

  /// @docsEditable true
  @DomName('SVGFEImageElement.width')
  final AnimatedLength width;

  /// @docsEditable true
  @DomName('SVGFEImageElement.x')
  final AnimatedLength x;

  /// @docsEditable true
  @DomName('SVGFEImageElement.y')
  final AnimatedLength y;

  // From SVGLangSpace

  /// @docsEditable true
  @DomName('SVGFEImageElement.xmllang')
  String xmllang;

  /// @docsEditable true
  @DomName('SVGFEImageElement.xmlspace')
  String xmlspace;

  // From SVGStylable

  // Shadowing definition.
  /// @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  /// @docsEditable true
  @DomName('SVGFEImageElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;

  // From SVGURIReference

  /// @docsEditable true
  @DomName('SVGFEImageElement.href')
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGFEMergeElement')
class FEMergeElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEMergeElement" {

  // From SVGFilterPrimitiveStandardAttributes

  /// @docsEditable true
  @DomName('SVGFEMergeElement.height')
  final AnimatedLength height;

  /// @docsEditable true
  @DomName('SVGFEMergeElement.result')
  final AnimatedString result;

  /// @docsEditable true
  @DomName('SVGFEMergeElement.width')
  final AnimatedLength width;

  /// @docsEditable true
  @DomName('SVGFEMergeElement.x')
  final AnimatedLength x;

  /// @docsEditable true
  @DomName('SVGFEMergeElement.y')
  final AnimatedLength y;

  // From SVGStylable

  // Shadowing definition.
  /// @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  /// @docsEditable true
  @DomName('SVGFEMergeElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGFEMergeNodeElement')
class FEMergeNodeElement extends SvgElement native "*SVGFEMergeNodeElement" {

  /// @docsEditable true
  @DomName('SVGFEMergeNodeElement.in1')
  final AnimatedString in1;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGFEMorphologyElement')
class FEMorphologyElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEMorphologyElement" {

  static const int SVG_MORPHOLOGY_OPERATOR_DILATE = 2;

  static const int SVG_MORPHOLOGY_OPERATOR_ERODE = 1;

  static const int SVG_MORPHOLOGY_OPERATOR_UNKNOWN = 0;

  /// @docsEditable true
  @DomName('SVGFEMorphologyElement.in1')
  final AnimatedString in1;

  /// @docsEditable true
  @DomName('SVGFEMorphologyElement.operator')
  final AnimatedEnumeration operator;

  /// @docsEditable true
  @DomName('SVGFEMorphologyElement.radiusX')
  final AnimatedNumber radiusX;

  /// @docsEditable true
  @DomName('SVGFEMorphologyElement.radiusY')
  final AnimatedNumber radiusY;

  /// @docsEditable true
  @DomName('SVGFEMorphologyElement.setRadius')
  void setRadius(num radiusX, num radiusY) native;

  // From SVGFilterPrimitiveStandardAttributes

  /// @docsEditable true
  @DomName('SVGFEMorphologyElement.height')
  final AnimatedLength height;

  /// @docsEditable true
  @DomName('SVGFEMorphologyElement.result')
  final AnimatedString result;

  /// @docsEditable true
  @DomName('SVGFEMorphologyElement.width')
  final AnimatedLength width;

  /// @docsEditable true
  @DomName('SVGFEMorphologyElement.x')
  final AnimatedLength x;

  /// @docsEditable true
  @DomName('SVGFEMorphologyElement.y')
  final AnimatedLength y;

  // From SVGStylable

  // Shadowing definition.
  /// @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  /// @docsEditable true
  @DomName('SVGFEMorphologyElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGFEOffsetElement')
class FEOffsetElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEOffsetElement" {

  /// @docsEditable true
  @DomName('SVGFEOffsetElement.dx')
  final AnimatedNumber dx;

  /// @docsEditable true
  @DomName('SVGFEOffsetElement.dy')
  final AnimatedNumber dy;

  /// @docsEditable true
  @DomName('SVGFEOffsetElement.in1')
  final AnimatedString in1;

  // From SVGFilterPrimitiveStandardAttributes

  /// @docsEditable true
  @DomName('SVGFEOffsetElement.height')
  final AnimatedLength height;

  /// @docsEditable true
  @DomName('SVGFEOffsetElement.result')
  final AnimatedString result;

  /// @docsEditable true
  @DomName('SVGFEOffsetElement.width')
  final AnimatedLength width;

  /// @docsEditable true
  @DomName('SVGFEOffsetElement.x')
  final AnimatedLength x;

  /// @docsEditable true
  @DomName('SVGFEOffsetElement.y')
  final AnimatedLength y;

  // From SVGStylable

  // Shadowing definition.
  /// @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  /// @docsEditable true
  @DomName('SVGFEOffsetElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGFEPointLightElement')
class FEPointLightElement extends SvgElement native "*SVGFEPointLightElement" {

  /// @docsEditable true
  @DomName('SVGFEPointLightElement.x')
  final AnimatedNumber x;

  /// @docsEditable true
  @DomName('SVGFEPointLightElement.y')
  final AnimatedNumber y;

  /// @docsEditable true
  @DomName('SVGFEPointLightElement.z')
  final AnimatedNumber z;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGFESpecularLightingElement')
class FESpecularLightingElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFESpecularLightingElement" {

  /// @docsEditable true
  @DomName('SVGFESpecularLightingElement.in1')
  final AnimatedString in1;

  /// @docsEditable true
  @DomName('SVGFESpecularLightingElement.specularConstant')
  final AnimatedNumber specularConstant;

  /// @docsEditable true
  @DomName('SVGFESpecularLightingElement.specularExponent')
  final AnimatedNumber specularExponent;

  /// @docsEditable true
  @DomName('SVGFESpecularLightingElement.surfaceScale')
  final AnimatedNumber surfaceScale;

  // From SVGFilterPrimitiveStandardAttributes

  /// @docsEditable true
  @DomName('SVGFESpecularLightingElement.height')
  final AnimatedLength height;

  /// @docsEditable true
  @DomName('SVGFESpecularLightingElement.result')
  final AnimatedString result;

  /// @docsEditable true
  @DomName('SVGFESpecularLightingElement.width')
  final AnimatedLength width;

  /// @docsEditable true
  @DomName('SVGFESpecularLightingElement.x')
  final AnimatedLength x;

  /// @docsEditable true
  @DomName('SVGFESpecularLightingElement.y')
  final AnimatedLength y;

  // From SVGStylable

  // Shadowing definition.
  /// @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  /// @docsEditable true
  @DomName('SVGFESpecularLightingElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGFESpotLightElement')
class FESpotLightElement extends SvgElement native "*SVGFESpotLightElement" {

  /// @docsEditable true
  @DomName('SVGFESpotLightElement.limitingConeAngle')
  final AnimatedNumber limitingConeAngle;

  /// @docsEditable true
  @DomName('SVGFESpotLightElement.pointsAtX')
  final AnimatedNumber pointsAtX;

  /// @docsEditable true
  @DomName('SVGFESpotLightElement.pointsAtY')
  final AnimatedNumber pointsAtY;

  /// @docsEditable true
  @DomName('SVGFESpotLightElement.pointsAtZ')
  final AnimatedNumber pointsAtZ;

  /// @docsEditable true
  @DomName('SVGFESpotLightElement.specularExponent')
  final AnimatedNumber specularExponent;

  /// @docsEditable true
  @DomName('SVGFESpotLightElement.x')
  final AnimatedNumber x;

  /// @docsEditable true
  @DomName('SVGFESpotLightElement.y')
  final AnimatedNumber y;

  /// @docsEditable true
  @DomName('SVGFESpotLightElement.z')
  final AnimatedNumber z;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGFETileElement')
class FETileElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFETileElement" {

  /// @docsEditable true
  @DomName('SVGFETileElement.in1')
  final AnimatedString in1;

  // From SVGFilterPrimitiveStandardAttributes

  /// @docsEditable true
  @DomName('SVGFETileElement.height')
  final AnimatedLength height;

  /// @docsEditable true
  @DomName('SVGFETileElement.result')
  final AnimatedString result;

  /// @docsEditable true
  @DomName('SVGFETileElement.width')
  final AnimatedLength width;

  /// @docsEditable true
  @DomName('SVGFETileElement.x')
  final AnimatedLength x;

  /// @docsEditable true
  @DomName('SVGFETileElement.y')
  final AnimatedLength y;

  // From SVGStylable

  // Shadowing definition.
  /// @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  /// @docsEditable true
  @DomName('SVGFETileElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGFETurbulenceElement')
class FETurbulenceElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFETurbulenceElement" {

  static const int SVG_STITCHTYPE_NOSTITCH = 2;

  static const int SVG_STITCHTYPE_STITCH = 1;

  static const int SVG_STITCHTYPE_UNKNOWN = 0;

  static const int SVG_TURBULENCE_TYPE_FRACTALNOISE = 1;

  static const int SVG_TURBULENCE_TYPE_TURBULENCE = 2;

  static const int SVG_TURBULENCE_TYPE_UNKNOWN = 0;

  /// @docsEditable true
  @DomName('SVGFETurbulenceElement.baseFrequencyX')
  final AnimatedNumber baseFrequencyX;

  /// @docsEditable true
  @DomName('SVGFETurbulenceElement.baseFrequencyY')
  final AnimatedNumber baseFrequencyY;

  /// @docsEditable true
  @DomName('SVGFETurbulenceElement.numOctaves')
  final AnimatedInteger numOctaves;

  /// @docsEditable true
  @DomName('SVGFETurbulenceElement.seed')
  final AnimatedNumber seed;

  /// @docsEditable true
  @DomName('SVGFETurbulenceElement.stitchTiles')
  final AnimatedEnumeration stitchTiles;

  /// @docsEditable true
  @DomName('SVGFETurbulenceElement.type')
  final AnimatedEnumeration type;

  // From SVGFilterPrimitiveStandardAttributes

  /// @docsEditable true
  @DomName('SVGFETurbulenceElement.height')
  final AnimatedLength height;

  /// @docsEditable true
  @DomName('SVGFETurbulenceElement.result')
  final AnimatedString result;

  /// @docsEditable true
  @DomName('SVGFETurbulenceElement.width')
  final AnimatedLength width;

  /// @docsEditable true
  @DomName('SVGFETurbulenceElement.x')
  final AnimatedLength x;

  /// @docsEditable true
  @DomName('SVGFETurbulenceElement.y')
  final AnimatedLength y;

  // From SVGStylable

  // Shadowing definition.
  /// @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  /// @docsEditable true
  @DomName('SVGFETurbulenceElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGFilterElement')
class FilterElement extends SvgElement implements UriReference, ExternalResourcesRequired, Stylable, LangSpace native "*SVGFilterElement" {

  /// @docsEditable true
  factory FilterElement() => _SvgElementFactoryProvider.createSvgElement_tag("filter");

  /// @docsEditable true
  @DomName('SVGFilterElement.filterResX')
  final AnimatedInteger filterResX;

  /// @docsEditable true
  @DomName('SVGFilterElement.filterResY')
  final AnimatedInteger filterResY;

  /// @docsEditable true
  @DomName('SVGFilterElement.filterUnits')
  final AnimatedEnumeration filterUnits;

  /// @docsEditable true
  @DomName('SVGFilterElement.height')
  final AnimatedLength height;

  /// @docsEditable true
  @DomName('SVGFilterElement.primitiveUnits')
  final AnimatedEnumeration primitiveUnits;

  /// @docsEditable true
  @DomName('SVGFilterElement.width')
  final AnimatedLength width;

  /// @docsEditable true
  @DomName('SVGFilterElement.x')
  final AnimatedLength x;

  /// @docsEditable true
  @DomName('SVGFilterElement.y')
  final AnimatedLength y;

  /// @docsEditable true
  @DomName('SVGFilterElement.setFilterRes')
  void setFilterRes(int filterResX, int filterResY) native;

  // From SVGExternalResourcesRequired

  /// @docsEditable true
  @DomName('SVGFilterElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /// @docsEditable true
  @DomName('SVGFilterElement.xmllang')
  String xmllang;

  /// @docsEditable true
  @DomName('SVGFilterElement.xmlspace')
  String xmlspace;

  // From SVGStylable

  // Shadowing definition.
  /// @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  /// @docsEditable true
  @DomName('SVGFilterElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;

  // From SVGURIReference

  /// @docsEditable true
  @DomName('SVGFilterElement.href')
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGFilterPrimitiveStandardAttributes')
abstract class FilterPrimitiveStandardAttributes implements Stylable {

  AnimatedLength height;

  AnimatedString result;

  AnimatedLength width;

  AnimatedLength x;

  AnimatedLength y;

  // From SVGStylable

  AnimatedString $dom_svgClassName;

  CssStyleDeclaration style;

  /// @docsEditable true
  CssValue getPresentationAttribute(String name);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGFitToViewBox')
abstract class FitToViewBox {

  AnimatedPreserveAspectRatio preserveAspectRatio;

  AnimatedRect viewBox;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGFontElement')
class FontElement extends SvgElement native "*SVGFontElement" {

  /// @docsEditable true
  factory FontElement() => _SvgElementFactoryProvider.createSvgElement_tag("font");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGFontFaceElement')
class FontFaceElement extends SvgElement native "*SVGFontFaceElement" {

  /// @docsEditable true
  factory FontFaceElement() => _SvgElementFactoryProvider.createSvgElement_tag("font-face");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGFontFaceFormatElement')
class FontFaceFormatElement extends SvgElement native "*SVGFontFaceFormatElement" {

  /// @docsEditable true
  factory FontFaceFormatElement() => _SvgElementFactoryProvider.createSvgElement_tag("font-face-format");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGFontFaceNameElement')
class FontFaceNameElement extends SvgElement native "*SVGFontFaceNameElement" {

  /// @docsEditable true
  factory FontFaceNameElement() => _SvgElementFactoryProvider.createSvgElement_tag("font-face-name");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGFontFaceSrcElement')
class FontFaceSrcElement extends SvgElement native "*SVGFontFaceSrcElement" {

  /// @docsEditable true
  factory FontFaceSrcElement() => _SvgElementFactoryProvider.createSvgElement_tag("font-face-src");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGFontFaceUriElement')
class FontFaceUriElement extends SvgElement native "*SVGFontFaceUriElement" {

  /// @docsEditable true
  factory FontFaceUriElement() => _SvgElementFactoryProvider.createSvgElement_tag("font-face-uri");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGForeignObjectElement')
class ForeignObjectElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGForeignObjectElement" {

  /// @docsEditable true
  factory ForeignObjectElement() => _SvgElementFactoryProvider.createSvgElement_tag("foreignObject");

  /// @docsEditable true
  @DomName('SVGForeignObjectElement.height')
  final AnimatedLength height;

  /// @docsEditable true
  @DomName('SVGForeignObjectElement.width')
  final AnimatedLength width;

  /// @docsEditable true
  @DomName('SVGForeignObjectElement.x')
  final AnimatedLength x;

  /// @docsEditable true
  @DomName('SVGForeignObjectElement.y')
  final AnimatedLength y;

  // From SVGExternalResourcesRequired

  /// @docsEditable true
  @DomName('SVGForeignObjectElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /// @docsEditable true
  @DomName('SVGForeignObjectElement.xmllang')
  String xmllang;

  /// @docsEditable true
  @DomName('SVGForeignObjectElement.xmlspace')
  String xmlspace;

  // From SVGLocatable

  /// @docsEditable true
  @DomName('SVGForeignObjectElement.farthestViewportElement')
  final SvgElement farthestViewportElement;

  /// @docsEditable true
  @DomName('SVGForeignObjectElement.nearestViewportElement')
  final SvgElement nearestViewportElement;

  /// @docsEditable true
  @DomName('SVGForeignObjectElement.getBBox')
  Rect getBBox() native;

  /// @docsEditable true
  @JSName('getCTM')
  @DomName('SVGForeignObjectElement.getCTM')
  Matrix getCtm() native;

  /// @docsEditable true
  @JSName('getScreenCTM')
  @DomName('SVGForeignObjectElement.getScreenCTM')
  Matrix getScreenCtm() native;

  /// @docsEditable true
  @DomName('SVGForeignObjectElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  // Shadowing definition.
  /// @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  /// @docsEditable true
  @DomName('SVGForeignObjectElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  /// @docsEditable true
  @DomName('SVGForeignObjectElement.requiredExtensions')
  final StringList requiredExtensions;

  /// @docsEditable true
  @DomName('SVGForeignObjectElement.requiredFeatures')
  final StringList requiredFeatures;

  /// @docsEditable true
  @DomName('SVGForeignObjectElement.systemLanguage')
  final StringList systemLanguage;

  /// @docsEditable true
  @DomName('SVGForeignObjectElement.hasExtension')
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /// @docsEditable true
  @DomName('SVGForeignObjectElement.transform')
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGGElement')
class GElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGGElement" {

  /// @docsEditable true
  factory GElement() => _SvgElementFactoryProvider.createSvgElement_tag("g");

  // From SVGExternalResourcesRequired

  /// @docsEditable true
  @DomName('SVGGElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /// @docsEditable true
  @DomName('SVGGElement.xmllang')
  String xmllang;

  /// @docsEditable true
  @DomName('SVGGElement.xmlspace')
  String xmlspace;

  // From SVGLocatable

  /// @docsEditable true
  @DomName('SVGGElement.farthestViewportElement')
  final SvgElement farthestViewportElement;

  /// @docsEditable true
  @DomName('SVGGElement.nearestViewportElement')
  final SvgElement nearestViewportElement;

  /// @docsEditable true
  @DomName('SVGGElement.getBBox')
  Rect getBBox() native;

  /// @docsEditable true
  @JSName('getCTM')
  @DomName('SVGGElement.getCTM')
  Matrix getCtm() native;

  /// @docsEditable true
  @JSName('getScreenCTM')
  @DomName('SVGGElement.getScreenCTM')
  Matrix getScreenCtm() native;

  /// @docsEditable true
  @DomName('SVGGElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  // Shadowing definition.
  /// @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  /// @docsEditable true
  @DomName('SVGGElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  /// @docsEditable true
  @DomName('SVGGElement.requiredExtensions')
  final StringList requiredExtensions;

  /// @docsEditable true
  @DomName('SVGGElement.requiredFeatures')
  final StringList requiredFeatures;

  /// @docsEditable true
  @DomName('SVGGElement.systemLanguage')
  final StringList systemLanguage;

  /// @docsEditable true
  @DomName('SVGGElement.hasExtension')
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /// @docsEditable true
  @DomName('SVGGElement.transform')
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGGlyphElement')
class GlyphElement extends SvgElement native "*SVGGlyphElement" {

  /// @docsEditable true
  factory GlyphElement() => _SvgElementFactoryProvider.createSvgElement_tag("glyph");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGGlyphRefElement')
class GlyphRefElement extends SvgElement implements UriReference, Stylable native "*SVGGlyphRefElement" {

  /// @docsEditable true
  @DomName('SVGGlyphRefElement.dx')
  num dx;

  /// @docsEditable true
  @DomName('SVGGlyphRefElement.dy')
  num dy;

  /// @docsEditable true
  @DomName('SVGGlyphRefElement.format')
  String format;

  /// @docsEditable true
  @DomName('SVGGlyphRefElement.glyphRef')
  String glyphRef;

  /// @docsEditable true
  @DomName('SVGGlyphRefElement.x')
  num x;

  /// @docsEditable true
  @DomName('SVGGlyphRefElement.y')
  num y;

  // From SVGStylable

  // Shadowing definition.
  /// @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  /// @docsEditable true
  @DomName('SVGGlyphRefElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;

  // From SVGURIReference

  /// @docsEditable true
  @DomName('SVGGlyphRefElement.href')
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGGradientElement')
class GradientElement extends SvgElement implements UriReference, ExternalResourcesRequired, Stylable native "*SVGGradientElement" {

  static const int SVG_SPREADMETHOD_PAD = 1;

  static const int SVG_SPREADMETHOD_REFLECT = 2;

  static const int SVG_SPREADMETHOD_REPEAT = 3;

  static const int SVG_SPREADMETHOD_UNKNOWN = 0;

  /// @docsEditable true
  @DomName('SVGGradientElement.gradientTransform')
  final AnimatedTransformList gradientTransform;

  /// @docsEditable true
  @DomName('SVGGradientElement.gradientUnits')
  final AnimatedEnumeration gradientUnits;

  /// @docsEditable true
  @DomName('SVGGradientElement.spreadMethod')
  final AnimatedEnumeration spreadMethod;

  // From SVGExternalResourcesRequired

  /// @docsEditable true
  @DomName('SVGGradientElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGStylable

  // Shadowing definition.
  /// @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  /// @docsEditable true
  @DomName('SVGGradientElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;

  // From SVGURIReference

  /// @docsEditable true
  @DomName('SVGGradientElement.href')
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGHKernElement')
class HKernElement extends SvgElement native "*SVGHKernElement" {

  /// @docsEditable true
  factory HKernElement() => _SvgElementFactoryProvider.createSvgElement_tag("hkern");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGImageElement')
class ImageElement extends SvgElement implements Transformable, Tests, UriReference, Stylable, ExternalResourcesRequired, LangSpace native "*SVGImageElement" {

  /// @docsEditable true
  factory ImageElement() => _SvgElementFactoryProvider.createSvgElement_tag("image");

  /// @docsEditable true
  @DomName('SVGImageElement.height')
  final AnimatedLength height;

  /// @docsEditable true
  @DomName('SVGImageElement.preserveAspectRatio')
  final AnimatedPreserveAspectRatio preserveAspectRatio;

  /// @docsEditable true
  @DomName('SVGImageElement.width')
  final AnimatedLength width;

  /// @docsEditable true
  @DomName('SVGImageElement.x')
  final AnimatedLength x;

  /// @docsEditable true
  @DomName('SVGImageElement.y')
  final AnimatedLength y;

  // From SVGExternalResourcesRequired

  /// @docsEditable true
  @DomName('SVGImageElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /// @docsEditable true
  @DomName('SVGImageElement.xmllang')
  String xmllang;

  /// @docsEditable true
  @DomName('SVGImageElement.xmlspace')
  String xmlspace;

  // From SVGLocatable

  /// @docsEditable true
  @DomName('SVGImageElement.farthestViewportElement')
  final SvgElement farthestViewportElement;

  /// @docsEditable true
  @DomName('SVGImageElement.nearestViewportElement')
  final SvgElement nearestViewportElement;

  /// @docsEditable true
  @DomName('SVGImageElement.getBBox')
  Rect getBBox() native;

  /// @docsEditable true
  @JSName('getCTM')
  @DomName('SVGImageElement.getCTM')
  Matrix getCtm() native;

  /// @docsEditable true
  @JSName('getScreenCTM')
  @DomName('SVGImageElement.getScreenCTM')
  Matrix getScreenCtm() native;

  /// @docsEditable true
  @DomName('SVGImageElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  // Shadowing definition.
  /// @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  /// @docsEditable true
  @DomName('SVGImageElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  /// @docsEditable true
  @DomName('SVGImageElement.requiredExtensions')
  final StringList requiredExtensions;

  /// @docsEditable true
  @DomName('SVGImageElement.requiredFeatures')
  final StringList requiredFeatures;

  /// @docsEditable true
  @DomName('SVGImageElement.systemLanguage')
  final StringList systemLanguage;

  /// @docsEditable true
  @DomName('SVGImageElement.hasExtension')
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /// @docsEditable true
  @DomName('SVGImageElement.transform')
  final AnimatedTransformList transform;

  // From SVGURIReference

  /// @docsEditable true
  @DomName('SVGImageElement.href')
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGLangSpace')
abstract class LangSpace {

  String xmllang;

  String xmlspace;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGLength')
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

  /// @docsEditable true
  @DomName('SVGLength.unitType')
  final int unitType;

  /// @docsEditable true
  @DomName('SVGLength.value')
  num value;

  /// @docsEditable true
  @DomName('SVGLength.valueAsString')
  String valueAsString;

  /// @docsEditable true
  @DomName('SVGLength.valueInSpecifiedUnits')
  num valueInSpecifiedUnits;

  /// @docsEditable true
  @DomName('SVGLength.convertToSpecifiedUnits')
  void convertToSpecifiedUnits(int unitType) native;

  /// @docsEditable true
  @DomName('SVGLength.newValueSpecifiedUnits')
  void newValueSpecifiedUnits(int unitType, num valueInSpecifiedUnits) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGLengthList')
class LengthList implements JavaScriptIndexingBehavior, List<Length> native "*SVGLengthList" {

  /// @docsEditable true
  @DomName('SVGLengthList.numberOfItems')
  final int numberOfItems;

  Length operator[](int index) => JS("Length", "#[#]", this, index);

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

  /// @docsEditable true
  @DomName('SVGLengthList.appendItem')
  Length appendItem(Length item) native;

  /// @docsEditable true
  @DomName('SVGLengthList.clear')
  void clear() native;

  /// @docsEditable true
  @DomName('SVGLengthList.getItem')
  Length getItem(int index) native;

  /// @docsEditable true
  @DomName('SVGLengthList.initialize')
  Length initialize(Length item) native;

  /// @docsEditable true
  @DomName('SVGLengthList.insertItemBefore')
  Length insertItemBefore(Length item, int index) native;

  /// @docsEditable true
  @DomName('SVGLengthList.removeItem')
  Length removeItem(int index) native;

  /// @docsEditable true
  @DomName('SVGLengthList.replaceItem')
  Length replaceItem(Length item, int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGLineElement')
class LineElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGLineElement" {

  /// @docsEditable true
  factory LineElement() => _SvgElementFactoryProvider.createSvgElement_tag("line");

  /// @docsEditable true
  @DomName('SVGLineElement.x1')
  final AnimatedLength x1;

  /// @docsEditable true
  @DomName('SVGLineElement.x2')
  final AnimatedLength x2;

  /// @docsEditable true
  @DomName('SVGLineElement.y1')
  final AnimatedLength y1;

  /// @docsEditable true
  @DomName('SVGLineElement.y2')
  final AnimatedLength y2;

  // From SVGExternalResourcesRequired

  /// @docsEditable true
  @DomName('SVGLineElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /// @docsEditable true
  @DomName('SVGLineElement.xmllang')
  String xmllang;

  /// @docsEditable true
  @DomName('SVGLineElement.xmlspace')
  String xmlspace;

  // From SVGLocatable

  /// @docsEditable true
  @DomName('SVGLineElement.farthestViewportElement')
  final SvgElement farthestViewportElement;

  /// @docsEditable true
  @DomName('SVGLineElement.nearestViewportElement')
  final SvgElement nearestViewportElement;

  /// @docsEditable true
  @DomName('SVGLineElement.getBBox')
  Rect getBBox() native;

  /// @docsEditable true
  @JSName('getCTM')
  @DomName('SVGLineElement.getCTM')
  Matrix getCtm() native;

  /// @docsEditable true
  @JSName('getScreenCTM')
  @DomName('SVGLineElement.getScreenCTM')
  Matrix getScreenCtm() native;

  /// @docsEditable true
  @DomName('SVGLineElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  // Shadowing definition.
  /// @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  /// @docsEditable true
  @DomName('SVGLineElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  /// @docsEditable true
  @DomName('SVGLineElement.requiredExtensions')
  final StringList requiredExtensions;

  /// @docsEditable true
  @DomName('SVGLineElement.requiredFeatures')
  final StringList requiredFeatures;

  /// @docsEditable true
  @DomName('SVGLineElement.systemLanguage')
  final StringList systemLanguage;

  /// @docsEditable true
  @DomName('SVGLineElement.hasExtension')
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /// @docsEditable true
  @DomName('SVGLineElement.transform')
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGLinearGradientElement')
class LinearGradientElement extends GradientElement native "*SVGLinearGradientElement" {

  /// @docsEditable true
  factory LinearGradientElement() => _SvgElementFactoryProvider.createSvgElement_tag("linearGradient");

  /// @docsEditable true
  @DomName('SVGLinearGradientElement.x1')
  final AnimatedLength x1;

  /// @docsEditable true
  @DomName('SVGLinearGradientElement.x2')
  final AnimatedLength x2;

  /// @docsEditable true
  @DomName('SVGLinearGradientElement.y1')
  final AnimatedLength y1;

  /// @docsEditable true
  @DomName('SVGLinearGradientElement.y2')
  final AnimatedLength y2;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGLocatable')
abstract class Locatable {

  SvgElement farthestViewportElement;

  SvgElement nearestViewportElement;

  /// @docsEditable true
  Rect getBBox();

  /// @docsEditable true
  Matrix getCTM();

  /// @docsEditable true
  Matrix getScreenCTM();

  /// @docsEditable true
  Matrix getTransformToElement(SvgElement element);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGMPathElement')
class MPathElement extends SvgElement implements UriReference, ExternalResourcesRequired native "*SVGMPathElement" {

  /// @docsEditable true
  factory MPathElement() => _SvgElementFactoryProvider.createSvgElement_tag("mpath");

  // From SVGExternalResourcesRequired

  /// @docsEditable true
  @DomName('SVGMPathElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGURIReference

  /// @docsEditable true
  @DomName('SVGMPathElement.href')
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGMarkerElement')
class MarkerElement extends SvgElement implements FitToViewBox, ExternalResourcesRequired, Stylable, LangSpace native "*SVGMarkerElement" {

  /// @docsEditable true
  factory MarkerElement() => _SvgElementFactoryProvider.createSvgElement_tag("marker");

  static const int SVG_MARKERUNITS_STROKEWIDTH = 2;

  static const int SVG_MARKERUNITS_UNKNOWN = 0;

  static const int SVG_MARKERUNITS_USERSPACEONUSE = 1;

  static const int SVG_MARKER_ORIENT_ANGLE = 2;

  static const int SVG_MARKER_ORIENT_AUTO = 1;

  static const int SVG_MARKER_ORIENT_UNKNOWN = 0;

  /// @docsEditable true
  @DomName('SVGMarkerElement.markerHeight')
  final AnimatedLength markerHeight;

  /// @docsEditable true
  @DomName('SVGMarkerElement.markerUnits')
  final AnimatedEnumeration markerUnits;

  /// @docsEditable true
  @DomName('SVGMarkerElement.markerWidth')
  final AnimatedLength markerWidth;

  /// @docsEditable true
  @DomName('SVGMarkerElement.orientAngle')
  final AnimatedAngle orientAngle;

  /// @docsEditable true
  @DomName('SVGMarkerElement.orientType')
  final AnimatedEnumeration orientType;

  /// @docsEditable true
  @DomName('SVGMarkerElement.refX')
  final AnimatedLength refX;

  /// @docsEditable true
  @DomName('SVGMarkerElement.refY')
  final AnimatedLength refY;

  /// @docsEditable true
  @DomName('SVGMarkerElement.setOrientToAngle')
  void setOrientToAngle(Angle angle) native;

  /// @docsEditable true
  @DomName('SVGMarkerElement.setOrientToAuto')
  void setOrientToAuto() native;

  // From SVGExternalResourcesRequired

  /// @docsEditable true
  @DomName('SVGMarkerElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGFitToViewBox

  /// @docsEditable true
  @DomName('SVGMarkerElement.preserveAspectRatio')
  final AnimatedPreserveAspectRatio preserveAspectRatio;

  /// @docsEditable true
  @DomName('SVGMarkerElement.viewBox')
  final AnimatedRect viewBox;

  // From SVGLangSpace

  /// @docsEditable true
  @DomName('SVGMarkerElement.xmllang')
  String xmllang;

  /// @docsEditable true
  @DomName('SVGMarkerElement.xmlspace')
  String xmlspace;

  // From SVGStylable

  // Shadowing definition.
  /// @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  /// @docsEditable true
  @DomName('SVGMarkerElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGMaskElement')
class MaskElement extends SvgElement implements Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGMaskElement" {

  /// @docsEditable true
  factory MaskElement() => _SvgElementFactoryProvider.createSvgElement_tag("mask");

  /// @docsEditable true
  @DomName('SVGMaskElement.height')
  final AnimatedLength height;

  /// @docsEditable true
  @DomName('SVGMaskElement.maskContentUnits')
  final AnimatedEnumeration maskContentUnits;

  /// @docsEditable true
  @DomName('SVGMaskElement.maskUnits')
  final AnimatedEnumeration maskUnits;

  /// @docsEditable true
  @DomName('SVGMaskElement.width')
  final AnimatedLength width;

  /// @docsEditable true
  @DomName('SVGMaskElement.x')
  final AnimatedLength x;

  /// @docsEditable true
  @DomName('SVGMaskElement.y')
  final AnimatedLength y;

  // From SVGExternalResourcesRequired

  /// @docsEditable true
  @DomName('SVGMaskElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /// @docsEditable true
  @DomName('SVGMaskElement.xmllang')
  String xmllang;

  /// @docsEditable true
  @DomName('SVGMaskElement.xmlspace')
  String xmlspace;

  // From SVGStylable

  // Shadowing definition.
  /// @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  /// @docsEditable true
  @DomName('SVGMaskElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  /// @docsEditable true
  @DomName('SVGMaskElement.requiredExtensions')
  final StringList requiredExtensions;

  /// @docsEditable true
  @DomName('SVGMaskElement.requiredFeatures')
  final StringList requiredFeatures;

  /// @docsEditable true
  @DomName('SVGMaskElement.systemLanguage')
  final StringList systemLanguage;

  /// @docsEditable true
  @DomName('SVGMaskElement.hasExtension')
  bool hasExtension(String extension) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGMatrix')
class Matrix native "*SVGMatrix" {

  /// @docsEditable true
  @DomName('SVGMatrix.a')
  num a;

  /// @docsEditable true
  @DomName('SVGMatrix.b')
  num b;

  /// @docsEditable true
  @DomName('SVGMatrix.c')
  num c;

  /// @docsEditable true
  @DomName('SVGMatrix.d')
  num d;

  /// @docsEditable true
  @DomName('SVGMatrix.e')
  num e;

  /// @docsEditable true
  @DomName('SVGMatrix.f')
  num f;

  /// @docsEditable true
  @DomName('SVGMatrix.flipX')
  Matrix flipX() native;

  /// @docsEditable true
  @DomName('SVGMatrix.flipY')
  Matrix flipY() native;

  /// @docsEditable true
  @DomName('SVGMatrix.inverse')
  Matrix inverse() native;

  /// @docsEditable true
  @DomName('SVGMatrix.multiply')
  Matrix multiply(Matrix secondMatrix) native;

  /// @docsEditable true
  @DomName('SVGMatrix.rotate')
  Matrix rotate(num angle) native;

  /// @docsEditable true
  @DomName('SVGMatrix.rotateFromVector')
  Matrix rotateFromVector(num x, num y) native;

  /// @docsEditable true
  @DomName('SVGMatrix.scale')
  Matrix scale(num scaleFactor) native;

  /// @docsEditable true
  @DomName('SVGMatrix.scaleNonUniform')
  Matrix scaleNonUniform(num scaleFactorX, num scaleFactorY) native;

  /// @docsEditable true
  @DomName('SVGMatrix.skewX')
  Matrix skewX(num angle) native;

  /// @docsEditable true
  @DomName('SVGMatrix.skewY')
  Matrix skewY(num angle) native;

  /// @docsEditable true
  @DomName('SVGMatrix.translate')
  Matrix translate(num x, num y) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGMetadataElement')
class MetadataElement extends SvgElement native "*SVGMetadataElement" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGMissingGlyphElement')
class MissingGlyphElement extends SvgElement native "*SVGMissingGlyphElement" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGNumber')
class Number native "*SVGNumber" {

  /// @docsEditable true
  @DomName('SVGNumber.value')
  num value;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGNumberList')
class NumberList implements JavaScriptIndexingBehavior, List<Number> native "*SVGNumberList" {

  /// @docsEditable true
  @DomName('SVGNumberList.numberOfItems')
  final int numberOfItems;

  Number operator[](int index) => JS("Number", "#[#]", this, index);

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

  /// @docsEditable true
  @DomName('SVGNumberList.appendItem')
  Number appendItem(Number item) native;

  /// @docsEditable true
  @DomName('SVGNumberList.clear')
  void clear() native;

  /// @docsEditable true
  @DomName('SVGNumberList.getItem')
  Number getItem(int index) native;

  /// @docsEditable true
  @DomName('SVGNumberList.initialize')
  Number initialize(Number item) native;

  /// @docsEditable true
  @DomName('SVGNumberList.insertItemBefore')
  Number insertItemBefore(Number item, int index) native;

  /// @docsEditable true
  @DomName('SVGNumberList.removeItem')
  Number removeItem(int index) native;

  /// @docsEditable true
  @DomName('SVGNumberList.replaceItem')
  Number replaceItem(Number item, int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGPaint')
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

  /// @docsEditable true
  @DomName('SVGPaint.paintType')
  final int paintType;

  /// @docsEditable true
  @DomName('SVGPaint.uri')
  final String uri;

  /// @docsEditable true
  @DomName('SVGPaint.setPaint')
  void setPaint(int paintType, String uri, String rgbColor, String iccColor) native;

  /// @docsEditable true
  @DomName('SVGPaint.setUri')
  void setUri(String uri) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGPathElement')
class PathElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGPathElement" {

  /// @docsEditable true
  factory PathElement() => _SvgElementFactoryProvider.createSvgElement_tag("path");

  /// @docsEditable true
  @DomName('SVGPathElement.animatedNormalizedPathSegList')
  final PathSegList animatedNormalizedPathSegList;

  /// @docsEditable true
  @DomName('SVGPathElement.animatedPathSegList')
  final PathSegList animatedPathSegList;

  /// @docsEditable true
  @DomName('SVGPathElement.normalizedPathSegList')
  final PathSegList normalizedPathSegList;

  /// @docsEditable true
  @DomName('SVGPathElement.pathLength')
  final AnimatedNumber pathLength;

  /// @docsEditable true
  @DomName('SVGPathElement.pathSegList')
  final PathSegList pathSegList;

  /// @docsEditable true
  @JSName('createSVGPathSegArcAbs')
  @DomName('SVGPathElement.createSVGPathSegArcAbs')
  PathSegArcAbs createSvgPathSegArcAbs(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) native;

  /// @docsEditable true
  @JSName('createSVGPathSegArcRel')
  @DomName('SVGPathElement.createSVGPathSegArcRel')
  PathSegArcRel createSvgPathSegArcRel(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) native;

  /// @docsEditable true
  @JSName('createSVGPathSegClosePath')
  @DomName('SVGPathElement.createSVGPathSegClosePath')
  PathSegClosePath createSvgPathSegClosePath() native;

  /// @docsEditable true
  @JSName('createSVGPathSegCurvetoCubicAbs')
  @DomName('SVGPathElement.createSVGPathSegCurvetoCubicAbs')
  PathSegCurvetoCubicAbs createSvgPathSegCurvetoCubicAbs(num x, num y, num x1, num y1, num x2, num y2) native;

  /// @docsEditable true
  @JSName('createSVGPathSegCurvetoCubicRel')
  @DomName('SVGPathElement.createSVGPathSegCurvetoCubicRel')
  PathSegCurvetoCubicRel createSvgPathSegCurvetoCubicRel(num x, num y, num x1, num y1, num x2, num y2) native;

  /// @docsEditable true
  @JSName('createSVGPathSegCurvetoCubicSmoothAbs')
  @DomName('SVGPathElement.createSVGPathSegCurvetoCubicSmoothAbs')
  PathSegCurvetoCubicSmoothAbs createSvgPathSegCurvetoCubicSmoothAbs(num x, num y, num x2, num y2) native;

  /// @docsEditable true
  @JSName('createSVGPathSegCurvetoCubicSmoothRel')
  @DomName('SVGPathElement.createSVGPathSegCurvetoCubicSmoothRel')
  PathSegCurvetoCubicSmoothRel createSvgPathSegCurvetoCubicSmoothRel(num x, num y, num x2, num y2) native;

  /// @docsEditable true
  @JSName('createSVGPathSegCurvetoQuadraticAbs')
  @DomName('SVGPathElement.createSVGPathSegCurvetoQuadraticAbs')
  PathSegCurvetoQuadraticAbs createSvgPathSegCurvetoQuadraticAbs(num x, num y, num x1, num y1) native;

  /// @docsEditable true
  @JSName('createSVGPathSegCurvetoQuadraticRel')
  @DomName('SVGPathElement.createSVGPathSegCurvetoQuadraticRel')
  PathSegCurvetoQuadraticRel createSvgPathSegCurvetoQuadraticRel(num x, num y, num x1, num y1) native;

  /// @docsEditable true
  @JSName('createSVGPathSegCurvetoQuadraticSmoothAbs')
  @DomName('SVGPathElement.createSVGPathSegCurvetoQuadraticSmoothAbs')
  PathSegCurvetoQuadraticSmoothAbs createSvgPathSegCurvetoQuadraticSmoothAbs(num x, num y) native;

  /// @docsEditable true
  @JSName('createSVGPathSegCurvetoQuadraticSmoothRel')
  @DomName('SVGPathElement.createSVGPathSegCurvetoQuadraticSmoothRel')
  PathSegCurvetoQuadraticSmoothRel createSvgPathSegCurvetoQuadraticSmoothRel(num x, num y) native;

  /// @docsEditable true
  @JSName('createSVGPathSegLinetoAbs')
  @DomName('SVGPathElement.createSVGPathSegLinetoAbs')
  PathSegLinetoAbs createSvgPathSegLinetoAbs(num x, num y) native;

  /// @docsEditable true
  @JSName('createSVGPathSegLinetoHorizontalAbs')
  @DomName('SVGPathElement.createSVGPathSegLinetoHorizontalAbs')
  PathSegLinetoHorizontalAbs createSvgPathSegLinetoHorizontalAbs(num x) native;

  /// @docsEditable true
  @JSName('createSVGPathSegLinetoHorizontalRel')
  @DomName('SVGPathElement.createSVGPathSegLinetoHorizontalRel')
  PathSegLinetoHorizontalRel createSvgPathSegLinetoHorizontalRel(num x) native;

  /// @docsEditable true
  @JSName('createSVGPathSegLinetoRel')
  @DomName('SVGPathElement.createSVGPathSegLinetoRel')
  PathSegLinetoRel createSvgPathSegLinetoRel(num x, num y) native;

  /// @docsEditable true
  @JSName('createSVGPathSegLinetoVerticalAbs')
  @DomName('SVGPathElement.createSVGPathSegLinetoVerticalAbs')
  PathSegLinetoVerticalAbs createSvgPathSegLinetoVerticalAbs(num y) native;

  /// @docsEditable true
  @JSName('createSVGPathSegLinetoVerticalRel')
  @DomName('SVGPathElement.createSVGPathSegLinetoVerticalRel')
  PathSegLinetoVerticalRel createSvgPathSegLinetoVerticalRel(num y) native;

  /// @docsEditable true
  @JSName('createSVGPathSegMovetoAbs')
  @DomName('SVGPathElement.createSVGPathSegMovetoAbs')
  PathSegMovetoAbs createSvgPathSegMovetoAbs(num x, num y) native;

  /// @docsEditable true
  @JSName('createSVGPathSegMovetoRel')
  @DomName('SVGPathElement.createSVGPathSegMovetoRel')
  PathSegMovetoRel createSvgPathSegMovetoRel(num x, num y) native;

  /// @docsEditable true
  @DomName('SVGPathElement.getPathSegAtLength')
  int getPathSegAtLength(num distance) native;

  /// @docsEditable true
  @DomName('SVGPathElement.getPointAtLength')
  Point getPointAtLength(num distance) native;

  /// @docsEditable true
  @DomName('SVGPathElement.getTotalLength')
  num getTotalLength() native;

  // From SVGExternalResourcesRequired

  /// @docsEditable true
  @DomName('SVGPathElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /// @docsEditable true
  @DomName('SVGPathElement.xmllang')
  String xmllang;

  /// @docsEditable true
  @DomName('SVGPathElement.xmlspace')
  String xmlspace;

  // From SVGLocatable

  /// @docsEditable true
  @DomName('SVGPathElement.farthestViewportElement')
  final SvgElement farthestViewportElement;

  /// @docsEditable true
  @DomName('SVGPathElement.nearestViewportElement')
  final SvgElement nearestViewportElement;

  /// @docsEditable true
  @DomName('SVGPathElement.getBBox')
  Rect getBBox() native;

  /// @docsEditable true
  @JSName('getCTM')
  @DomName('SVGPathElement.getCTM')
  Matrix getCtm() native;

  /// @docsEditable true
  @JSName('getScreenCTM')
  @DomName('SVGPathElement.getScreenCTM')
  Matrix getScreenCtm() native;

  /// @docsEditable true
  @DomName('SVGPathElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  // Shadowing definition.
  /// @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  /// @docsEditable true
  @DomName('SVGPathElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  /// @docsEditable true
  @DomName('SVGPathElement.requiredExtensions')
  final StringList requiredExtensions;

  /// @docsEditable true
  @DomName('SVGPathElement.requiredFeatures')
  final StringList requiredFeatures;

  /// @docsEditable true
  @DomName('SVGPathElement.systemLanguage')
  final StringList systemLanguage;

  /// @docsEditable true
  @DomName('SVGPathElement.hasExtension')
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /// @docsEditable true
  @DomName('SVGPathElement.transform')
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGPathSeg')
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

  /// @docsEditable true
  @DomName('SVGPathSeg.pathSegType')
  final int pathSegType;

  /// @docsEditable true
  @DomName('SVGPathSeg.pathSegTypeAsLetter')
  final String pathSegTypeAsLetter;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGPathSegArcAbs')
class PathSegArcAbs extends PathSeg native "*SVGPathSegArcAbs" {

  /// @docsEditable true
  @DomName('SVGPathSegArcAbs.angle')
  num angle;

  /// @docsEditable true
  @DomName('SVGPathSegArcAbs.largeArcFlag')
  bool largeArcFlag;

  /// @docsEditable true
  @DomName('SVGPathSegArcAbs.r1')
  num r1;

  /// @docsEditable true
  @DomName('SVGPathSegArcAbs.r2')
  num r2;

  /// @docsEditable true
  @DomName('SVGPathSegArcAbs.sweepFlag')
  bool sweepFlag;

  /// @docsEditable true
  @DomName('SVGPathSegArcAbs.x')
  num x;

  /// @docsEditable true
  @DomName('SVGPathSegArcAbs.y')
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGPathSegArcRel')
class PathSegArcRel extends PathSeg native "*SVGPathSegArcRel" {

  /// @docsEditable true
  @DomName('SVGPathSegArcRel.angle')
  num angle;

  /// @docsEditable true
  @DomName('SVGPathSegArcRel.largeArcFlag')
  bool largeArcFlag;

  /// @docsEditable true
  @DomName('SVGPathSegArcRel.r1')
  num r1;

  /// @docsEditable true
  @DomName('SVGPathSegArcRel.r2')
  num r2;

  /// @docsEditable true
  @DomName('SVGPathSegArcRel.sweepFlag')
  bool sweepFlag;

  /// @docsEditable true
  @DomName('SVGPathSegArcRel.x')
  num x;

  /// @docsEditable true
  @DomName('SVGPathSegArcRel.y')
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGPathSegClosePath')
class PathSegClosePath extends PathSeg native "*SVGPathSegClosePath" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGPathSegCurvetoCubicAbs')
class PathSegCurvetoCubicAbs extends PathSeg native "*SVGPathSegCurvetoCubicAbs" {

  /// @docsEditable true
  @DomName('SVGPathSegCurvetoCubicAbs.x')
  num x;

  /// @docsEditable true
  @DomName('SVGPathSegCurvetoCubicAbs.x1')
  num x1;

  /// @docsEditable true
  @DomName('SVGPathSegCurvetoCubicAbs.x2')
  num x2;

  /// @docsEditable true
  @DomName('SVGPathSegCurvetoCubicAbs.y')
  num y;

  /// @docsEditable true
  @DomName('SVGPathSegCurvetoCubicAbs.y1')
  num y1;

  /// @docsEditable true
  @DomName('SVGPathSegCurvetoCubicAbs.y2')
  num y2;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGPathSegCurvetoCubicRel')
class PathSegCurvetoCubicRel extends PathSeg native "*SVGPathSegCurvetoCubicRel" {

  /// @docsEditable true
  @DomName('SVGPathSegCurvetoCubicRel.x')
  num x;

  /// @docsEditable true
  @DomName('SVGPathSegCurvetoCubicRel.x1')
  num x1;

  /// @docsEditable true
  @DomName('SVGPathSegCurvetoCubicRel.x2')
  num x2;

  /// @docsEditable true
  @DomName('SVGPathSegCurvetoCubicRel.y')
  num y;

  /// @docsEditable true
  @DomName('SVGPathSegCurvetoCubicRel.y1')
  num y1;

  /// @docsEditable true
  @DomName('SVGPathSegCurvetoCubicRel.y2')
  num y2;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGPathSegCurvetoCubicSmoothAbs')
class PathSegCurvetoCubicSmoothAbs extends PathSeg native "*SVGPathSegCurvetoCubicSmoothAbs" {

  /// @docsEditable true
  @DomName('SVGPathSegCurvetoCubicSmoothAbs.x')
  num x;

  /// @docsEditable true
  @DomName('SVGPathSegCurvetoCubicSmoothAbs.x2')
  num x2;

  /// @docsEditable true
  @DomName('SVGPathSegCurvetoCubicSmoothAbs.y')
  num y;

  /// @docsEditable true
  @DomName('SVGPathSegCurvetoCubicSmoothAbs.y2')
  num y2;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGPathSegCurvetoCubicSmoothRel')
class PathSegCurvetoCubicSmoothRel extends PathSeg native "*SVGPathSegCurvetoCubicSmoothRel" {

  /// @docsEditable true
  @DomName('SVGPathSegCurvetoCubicSmoothRel.x')
  num x;

  /// @docsEditable true
  @DomName('SVGPathSegCurvetoCubicSmoothRel.x2')
  num x2;

  /// @docsEditable true
  @DomName('SVGPathSegCurvetoCubicSmoothRel.y')
  num y;

  /// @docsEditable true
  @DomName('SVGPathSegCurvetoCubicSmoothRel.y2')
  num y2;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGPathSegCurvetoQuadraticAbs')
class PathSegCurvetoQuadraticAbs extends PathSeg native "*SVGPathSegCurvetoQuadraticAbs" {

  /// @docsEditable true
  @DomName('SVGPathSegCurvetoQuadraticAbs.x')
  num x;

  /// @docsEditable true
  @DomName('SVGPathSegCurvetoQuadraticAbs.x1')
  num x1;

  /// @docsEditable true
  @DomName('SVGPathSegCurvetoQuadraticAbs.y')
  num y;

  /// @docsEditable true
  @DomName('SVGPathSegCurvetoQuadraticAbs.y1')
  num y1;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGPathSegCurvetoQuadraticRel')
class PathSegCurvetoQuadraticRel extends PathSeg native "*SVGPathSegCurvetoQuadraticRel" {

  /// @docsEditable true
  @DomName('SVGPathSegCurvetoQuadraticRel.x')
  num x;

  /// @docsEditable true
  @DomName('SVGPathSegCurvetoQuadraticRel.x1')
  num x1;

  /// @docsEditable true
  @DomName('SVGPathSegCurvetoQuadraticRel.y')
  num y;

  /// @docsEditable true
  @DomName('SVGPathSegCurvetoQuadraticRel.y1')
  num y1;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGPathSegCurvetoQuadraticSmoothAbs')
class PathSegCurvetoQuadraticSmoothAbs extends PathSeg native "*SVGPathSegCurvetoQuadraticSmoothAbs" {

  /// @docsEditable true
  @DomName('SVGPathSegCurvetoQuadraticSmoothAbs.x')
  num x;

  /// @docsEditable true
  @DomName('SVGPathSegCurvetoQuadraticSmoothAbs.y')
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGPathSegCurvetoQuadraticSmoothRel')
class PathSegCurvetoQuadraticSmoothRel extends PathSeg native "*SVGPathSegCurvetoQuadraticSmoothRel" {

  /// @docsEditable true
  @DomName('SVGPathSegCurvetoQuadraticSmoothRel.x')
  num x;

  /// @docsEditable true
  @DomName('SVGPathSegCurvetoQuadraticSmoothRel.y')
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGPathSegLinetoAbs')
class PathSegLinetoAbs extends PathSeg native "*SVGPathSegLinetoAbs" {

  /// @docsEditable true
  @DomName('SVGPathSegLinetoAbs.x')
  num x;

  /// @docsEditable true
  @DomName('SVGPathSegLinetoAbs.y')
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGPathSegLinetoHorizontalAbs')
class PathSegLinetoHorizontalAbs extends PathSeg native "*SVGPathSegLinetoHorizontalAbs" {

  /// @docsEditable true
  @DomName('SVGPathSegLinetoHorizontalAbs.x')
  num x;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGPathSegLinetoHorizontalRel')
class PathSegLinetoHorizontalRel extends PathSeg native "*SVGPathSegLinetoHorizontalRel" {

  /// @docsEditable true
  @DomName('SVGPathSegLinetoHorizontalRel.x')
  num x;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGPathSegLinetoRel')
class PathSegLinetoRel extends PathSeg native "*SVGPathSegLinetoRel" {

  /// @docsEditable true
  @DomName('SVGPathSegLinetoRel.x')
  num x;

  /// @docsEditable true
  @DomName('SVGPathSegLinetoRel.y')
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGPathSegLinetoVerticalAbs')
class PathSegLinetoVerticalAbs extends PathSeg native "*SVGPathSegLinetoVerticalAbs" {

  /// @docsEditable true
  @DomName('SVGPathSegLinetoVerticalAbs.y')
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGPathSegLinetoVerticalRel')
class PathSegLinetoVerticalRel extends PathSeg native "*SVGPathSegLinetoVerticalRel" {

  /// @docsEditable true
  @DomName('SVGPathSegLinetoVerticalRel.y')
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGPathSegList')
class PathSegList implements JavaScriptIndexingBehavior, List<PathSeg> native "*SVGPathSegList" {

  /// @docsEditable true
  @DomName('SVGPathSegList.numberOfItems')
  final int numberOfItems;

  PathSeg operator[](int index) => JS("PathSeg", "#[#]", this, index);

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

  /// @docsEditable true
  @DomName('SVGPathSegList.appendItem')
  PathSeg appendItem(PathSeg newItem) native;

  /// @docsEditable true
  @DomName('SVGPathSegList.clear')
  void clear() native;

  /// @docsEditable true
  @DomName('SVGPathSegList.getItem')
  PathSeg getItem(int index) native;

  /// @docsEditable true
  @DomName('SVGPathSegList.initialize')
  PathSeg initialize(PathSeg newItem) native;

  /// @docsEditable true
  @DomName('SVGPathSegList.insertItemBefore')
  PathSeg insertItemBefore(PathSeg newItem, int index) native;

  /// @docsEditable true
  @DomName('SVGPathSegList.removeItem')
  PathSeg removeItem(int index) native;

  /// @docsEditable true
  @DomName('SVGPathSegList.replaceItem')
  PathSeg replaceItem(PathSeg newItem, int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGPathSegMovetoAbs')
class PathSegMovetoAbs extends PathSeg native "*SVGPathSegMovetoAbs" {

  /// @docsEditable true
  @DomName('SVGPathSegMovetoAbs.x')
  num x;

  /// @docsEditable true
  @DomName('SVGPathSegMovetoAbs.y')
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGPathSegMovetoRel')
class PathSegMovetoRel extends PathSeg native "*SVGPathSegMovetoRel" {

  /// @docsEditable true
  @DomName('SVGPathSegMovetoRel.x')
  num x;

  /// @docsEditable true
  @DomName('SVGPathSegMovetoRel.y')
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGPatternElement')
class PatternElement extends SvgElement implements FitToViewBox, Tests, UriReference, Stylable, ExternalResourcesRequired, LangSpace native "*SVGPatternElement" {

  /// @docsEditable true
  factory PatternElement() => _SvgElementFactoryProvider.createSvgElement_tag("pattern");

  /// @docsEditable true
  @DomName('SVGPatternElement.height')
  final AnimatedLength height;

  /// @docsEditable true
  @DomName('SVGPatternElement.patternContentUnits')
  final AnimatedEnumeration patternContentUnits;

  /// @docsEditable true
  @DomName('SVGPatternElement.patternTransform')
  final AnimatedTransformList patternTransform;

  /// @docsEditable true
  @DomName('SVGPatternElement.patternUnits')
  final AnimatedEnumeration patternUnits;

  /// @docsEditable true
  @DomName('SVGPatternElement.width')
  final AnimatedLength width;

  /// @docsEditable true
  @DomName('SVGPatternElement.x')
  final AnimatedLength x;

  /// @docsEditable true
  @DomName('SVGPatternElement.y')
  final AnimatedLength y;

  // From SVGExternalResourcesRequired

  /// @docsEditable true
  @DomName('SVGPatternElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGFitToViewBox

  /// @docsEditable true
  @DomName('SVGPatternElement.preserveAspectRatio')
  final AnimatedPreserveAspectRatio preserveAspectRatio;

  /// @docsEditable true
  @DomName('SVGPatternElement.viewBox')
  final AnimatedRect viewBox;

  // From SVGLangSpace

  /// @docsEditable true
  @DomName('SVGPatternElement.xmllang')
  String xmllang;

  /// @docsEditable true
  @DomName('SVGPatternElement.xmlspace')
  String xmlspace;

  // From SVGStylable

  // Shadowing definition.
  /// @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  /// @docsEditable true
  @DomName('SVGPatternElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  /// @docsEditable true
  @DomName('SVGPatternElement.requiredExtensions')
  final StringList requiredExtensions;

  /// @docsEditable true
  @DomName('SVGPatternElement.requiredFeatures')
  final StringList requiredFeatures;

  /// @docsEditable true
  @DomName('SVGPatternElement.systemLanguage')
  final StringList systemLanguage;

  /// @docsEditable true
  @DomName('SVGPatternElement.hasExtension')
  bool hasExtension(String extension) native;

  // From SVGURIReference

  /// @docsEditable true
  @DomName('SVGPatternElement.href')
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGPoint')
class Point native "*SVGPoint" {

  /// @docsEditable true
  @DomName('SVGPoint.x')
  num x;

  /// @docsEditable true
  @DomName('SVGPoint.y')
  num y;

  /// @docsEditable true
  @DomName('SVGPoint.matrixTransform')
  Point matrixTransform(Matrix matrix) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGPointList')
class PointList native "*SVGPointList" {

  /// @docsEditable true
  @DomName('SVGPointList.numberOfItems')
  final int numberOfItems;

  /// @docsEditable true
  @DomName('SVGPointList.appendItem')
  Point appendItem(Point item) native;

  /// @docsEditable true
  @DomName('SVGPointList.clear')
  void clear() native;

  /// @docsEditable true
  @DomName('SVGPointList.getItem')
  Point getItem(int index) native;

  /// @docsEditable true
  @DomName('SVGPointList.initialize')
  Point initialize(Point item) native;

  /// @docsEditable true
  @DomName('SVGPointList.insertItemBefore')
  Point insertItemBefore(Point item, int index) native;

  /// @docsEditable true
  @DomName('SVGPointList.removeItem')
  Point removeItem(int index) native;

  /// @docsEditable true
  @DomName('SVGPointList.replaceItem')
  Point replaceItem(Point item, int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGPolygonElement')
class PolygonElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGPolygonElement" {

  /// @docsEditable true
  factory PolygonElement() => _SvgElementFactoryProvider.createSvgElement_tag("polygon");

  /// @docsEditable true
  @DomName('SVGPolygonElement.animatedPoints')
  final PointList animatedPoints;

  /// @docsEditable true
  @DomName('SVGPolygonElement.points')
  final PointList points;

  // From SVGExternalResourcesRequired

  /// @docsEditable true
  @DomName('SVGPolygonElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /// @docsEditable true
  @DomName('SVGPolygonElement.xmllang')
  String xmllang;

  /// @docsEditable true
  @DomName('SVGPolygonElement.xmlspace')
  String xmlspace;

  // From SVGLocatable

  /// @docsEditable true
  @DomName('SVGPolygonElement.farthestViewportElement')
  final SvgElement farthestViewportElement;

  /// @docsEditable true
  @DomName('SVGPolygonElement.nearestViewportElement')
  final SvgElement nearestViewportElement;

  /// @docsEditable true
  @DomName('SVGPolygonElement.getBBox')
  Rect getBBox() native;

  /// @docsEditable true
  @JSName('getCTM')
  @DomName('SVGPolygonElement.getCTM')
  Matrix getCtm() native;

  /// @docsEditable true
  @JSName('getScreenCTM')
  @DomName('SVGPolygonElement.getScreenCTM')
  Matrix getScreenCtm() native;

  /// @docsEditable true
  @DomName('SVGPolygonElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  // Shadowing definition.
  /// @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  /// @docsEditable true
  @DomName('SVGPolygonElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  /// @docsEditable true
  @DomName('SVGPolygonElement.requiredExtensions')
  final StringList requiredExtensions;

  /// @docsEditable true
  @DomName('SVGPolygonElement.requiredFeatures')
  final StringList requiredFeatures;

  /// @docsEditable true
  @DomName('SVGPolygonElement.systemLanguage')
  final StringList systemLanguage;

  /// @docsEditable true
  @DomName('SVGPolygonElement.hasExtension')
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /// @docsEditable true
  @DomName('SVGPolygonElement.transform')
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGPolylineElement')
class PolylineElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGPolylineElement" {

  /// @docsEditable true
  factory PolylineElement() => _SvgElementFactoryProvider.createSvgElement_tag("polyline");

  /// @docsEditable true
  @DomName('SVGPolylineElement.animatedPoints')
  final PointList animatedPoints;

  /// @docsEditable true
  @DomName('SVGPolylineElement.points')
  final PointList points;

  // From SVGExternalResourcesRequired

  /// @docsEditable true
  @DomName('SVGPolylineElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /// @docsEditable true
  @DomName('SVGPolylineElement.xmllang')
  String xmllang;

  /// @docsEditable true
  @DomName('SVGPolylineElement.xmlspace')
  String xmlspace;

  // From SVGLocatable

  /// @docsEditable true
  @DomName('SVGPolylineElement.farthestViewportElement')
  final SvgElement farthestViewportElement;

  /// @docsEditable true
  @DomName('SVGPolylineElement.nearestViewportElement')
  final SvgElement nearestViewportElement;

  /// @docsEditable true
  @DomName('SVGPolylineElement.getBBox')
  Rect getBBox() native;

  /// @docsEditable true
  @JSName('getCTM')
  @DomName('SVGPolylineElement.getCTM')
  Matrix getCtm() native;

  /// @docsEditable true
  @JSName('getScreenCTM')
  @DomName('SVGPolylineElement.getScreenCTM')
  Matrix getScreenCtm() native;

  /// @docsEditable true
  @DomName('SVGPolylineElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  // Shadowing definition.
  /// @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  /// @docsEditable true
  @DomName('SVGPolylineElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  /// @docsEditable true
  @DomName('SVGPolylineElement.requiredExtensions')
  final StringList requiredExtensions;

  /// @docsEditable true
  @DomName('SVGPolylineElement.requiredFeatures')
  final StringList requiredFeatures;

  /// @docsEditable true
  @DomName('SVGPolylineElement.systemLanguage')
  final StringList systemLanguage;

  /// @docsEditable true
  @DomName('SVGPolylineElement.hasExtension')
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /// @docsEditable true
  @DomName('SVGPolylineElement.transform')
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGPreserveAspectRatio')
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

  /// @docsEditable true
  @DomName('SVGPreserveAspectRatio.align')
  int align;

  /// @docsEditable true
  @DomName('SVGPreserveAspectRatio.meetOrSlice')
  int meetOrSlice;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGRadialGradientElement')
class RadialGradientElement extends GradientElement native "*SVGRadialGradientElement" {

  /// @docsEditable true
  factory RadialGradientElement() => _SvgElementFactoryProvider.createSvgElement_tag("radialGradient");

  /// @docsEditable true
  @DomName('SVGRadialGradientElement.cx')
  final AnimatedLength cx;

  /// @docsEditable true
  @DomName('SVGRadialGradientElement.cy')
  final AnimatedLength cy;

  /// @docsEditable true
  @DomName('SVGRadialGradientElement.fr')
  final AnimatedLength fr;

  /// @docsEditable true
  @DomName('SVGRadialGradientElement.fx')
  final AnimatedLength fx;

  /// @docsEditable true
  @DomName('SVGRadialGradientElement.fy')
  final AnimatedLength fy;

  /// @docsEditable true
  @DomName('SVGRadialGradientElement.r')
  final AnimatedLength r;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGRect')
class Rect native "*SVGRect" {

  /// @docsEditable true
  @DomName('SVGRect.height')
  num height;

  /// @docsEditable true
  @DomName('SVGRect.width')
  num width;

  /// @docsEditable true
  @DomName('SVGRect.x')
  num x;

  /// @docsEditable true
  @DomName('SVGRect.y')
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGRectElement')
class RectElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGRectElement" {

  /// @docsEditable true
  factory RectElement() => _SvgElementFactoryProvider.createSvgElement_tag("rect");

  /// @docsEditable true
  @DomName('SVGRectElement.height')
  final AnimatedLength height;

  /// @docsEditable true
  @DomName('SVGRectElement.rx')
  final AnimatedLength rx;

  /// @docsEditable true
  @DomName('SVGRectElement.ry')
  final AnimatedLength ry;

  /// @docsEditable true
  @DomName('SVGRectElement.width')
  final AnimatedLength width;

  /// @docsEditable true
  @DomName('SVGRectElement.x')
  final AnimatedLength x;

  /// @docsEditable true
  @DomName('SVGRectElement.y')
  final AnimatedLength y;

  // From SVGExternalResourcesRequired

  /// @docsEditable true
  @DomName('SVGRectElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /// @docsEditable true
  @DomName('SVGRectElement.xmllang')
  String xmllang;

  /// @docsEditable true
  @DomName('SVGRectElement.xmlspace')
  String xmlspace;

  // From SVGLocatable

  /// @docsEditable true
  @DomName('SVGRectElement.farthestViewportElement')
  final SvgElement farthestViewportElement;

  /// @docsEditable true
  @DomName('SVGRectElement.nearestViewportElement')
  final SvgElement nearestViewportElement;

  /// @docsEditable true
  @DomName('SVGRectElement.getBBox')
  Rect getBBox() native;

  /// @docsEditable true
  @JSName('getCTM')
  @DomName('SVGRectElement.getCTM')
  Matrix getCtm() native;

  /// @docsEditable true
  @JSName('getScreenCTM')
  @DomName('SVGRectElement.getScreenCTM')
  Matrix getScreenCtm() native;

  /// @docsEditable true
  @DomName('SVGRectElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  // Shadowing definition.
  /// @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  /// @docsEditable true
  @DomName('SVGRectElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  /// @docsEditable true
  @DomName('SVGRectElement.requiredExtensions')
  final StringList requiredExtensions;

  /// @docsEditable true
  @DomName('SVGRectElement.requiredFeatures')
  final StringList requiredFeatures;

  /// @docsEditable true
  @DomName('SVGRectElement.systemLanguage')
  final StringList systemLanguage;

  /// @docsEditable true
  @DomName('SVGRectElement.hasExtension')
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /// @docsEditable true
  @DomName('SVGRectElement.transform')
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGRenderingIntent')
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


/// @docsEditable true
@DomName('SVGScriptElement')
class ScriptElement extends SvgElement implements UriReference, ExternalResourcesRequired native "*SVGScriptElement" {

  /// @docsEditable true
  factory ScriptElement() => _SvgElementFactoryProvider.createSvgElement_tag("script");

  /// @docsEditable true
  @DomName('SVGScriptElement.type')
  String type;

  // From SVGExternalResourcesRequired

  /// @docsEditable true
  @DomName('SVGScriptElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGURIReference

  /// @docsEditable true
  @DomName('SVGScriptElement.href')
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGSetElement')
class SetElement extends AnimationElement native "*SVGSetElement" {

  /// @docsEditable true
  factory SetElement() => _SvgElementFactoryProvider.createSvgElement_tag("set");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGStopElement')
class StopElement extends SvgElement implements Stylable native "*SVGStopElement" {

  /// @docsEditable true
  factory StopElement() => _SvgElementFactoryProvider.createSvgElement_tag("stop");

  /// @docsEditable true
  @DomName('SVGStopElement.offset')
  final AnimatedNumber offset;

  // From SVGStylable

  // Shadowing definition.
  /// @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  /// @docsEditable true
  @DomName('SVGStopElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGStringList')
class StringList implements JavaScriptIndexingBehavior, List<String> native "*SVGStringList" {

  /// @docsEditable true
  @DomName('SVGStringList.numberOfItems')
  final int numberOfItems;

  String operator[](int index) => JS("String", "#[#]", this, index);

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

  /// @docsEditable true
  @DomName('SVGStringList.appendItem')
  String appendItem(String item) native;

  /// @docsEditable true
  @DomName('SVGStringList.clear')
  void clear() native;

  /// @docsEditable true
  @DomName('SVGStringList.getItem')
  String getItem(int index) native;

  /// @docsEditable true
  @DomName('SVGStringList.initialize')
  String initialize(String item) native;

  /// @docsEditable true
  @DomName('SVGStringList.insertItemBefore')
  String insertItemBefore(String item, int index) native;

  /// @docsEditable true
  @DomName('SVGStringList.removeItem')
  String removeItem(int index) native;

  /// @docsEditable true
  @DomName('SVGStringList.replaceItem')
  String replaceItem(String item, int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGStylable')
abstract class Stylable {

  AnimatedString $dom_svgClassName;

  CssStyleDeclaration style;

  /// @docsEditable true
  CssValue getPresentationAttribute(String name);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGStyleElement')
class StyleElement extends SvgElement implements LangSpace native "*SVGStyleElement" {

  /// @docsEditable true
  factory StyleElement() => _SvgElementFactoryProvider.createSvgElement_tag("style");

  /// @docsEditable true
  @DomName('SVGStyleElement.disabled')
  bool disabled;

  /// @docsEditable true
  @DomName('SVGStyleElement.media')
  String media;

  // Shadowing definition.
  /// @docsEditable true
  String get title => JS("String", "#.title", this);

  /// @docsEditable true
  void set title(String value) {
    JS("void", "#.title = #", this, value);
  }

  /// @docsEditable true
  @DomName('SVGStyleElement.type')
  String type;

  // From SVGLangSpace

  /// @docsEditable true
  @DomName('SVGStyleElement.xmllang')
  String xmllang;

  /// @docsEditable true
  @DomName('SVGStyleElement.xmlspace')
  String xmlspace;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGDocument')
class SvgDocument extends Document native "*SVGDocument" {

  /// @docsEditable true
  @DomName('SVGDocument.rootElement')
  final SvgSvgElement rootElement;

  /// @docsEditable true
  @JSName('createEvent')
  @DomName('SVGDocument.createEvent')
  Event $dom_createEvent(String eventType) native;
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

@DomName('SVGElement')
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


  // Shadowing definition.
  /// @docsEditable true
  String get id => JS("String", "#.id", this);

  /// @docsEditable true
  void set id(String value) {
    JS("void", "#.id = #", this, value);
  }

  /// @docsEditable true
  @JSName('ownerSVGElement')
  @DomName('SVGElement.ownerSVGElement')
  final SvgSvgElement ownerSvgElement;

  /// @docsEditable true
  @DomName('SVGElement.viewportElement')
  final SvgElement viewportElement;

  /// @docsEditable true
  @DomName('SVGElement.xmlbase')
  String xmlbase;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGException')
class SvgException native "*SVGException" {

  static const int SVG_INVALID_VALUE_ERR = 1;

  static const int SVG_MATRIX_NOT_INVERTABLE = 2;

  static const int SVG_WRONG_TYPE_ERR = 0;

  /// @docsEditable true
  @DomName('SVGException.code')
  final int code;

  /// @docsEditable true
  @DomName('SVGException.message')
  final String message;

  /// @docsEditable true
  @DomName('SVGException.name')
  final String name;

  /// @docsEditable true
  @DomName('SVGException.toString')
  String toString() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('SVGSVGElement')
class SvgSvgElement extends SvgElement implements FitToViewBox, Tests, Stylable, Locatable, ExternalResourcesRequired, ZoomAndPan, LangSpace native "*SVGSVGElement" {
  factory SvgSvgElement() => _SvgSvgElementFactoryProvider.createSvgSvgElement();


  /// @docsEditable true
  @DomName('SVGSVGElement.contentScriptType')
  String contentScriptType;

  /// @docsEditable true
  @DomName('SVGSVGElement.contentStyleType')
  String contentStyleType;

  /// @docsEditable true
  @DomName('SVGSVGElement.currentScale')
  num currentScale;

  /// @docsEditable true
  @DomName('SVGSVGElement.currentTranslate')
  final Point currentTranslate;

  /// @docsEditable true
  @DomName('SVGSVGElement.currentView')
  final ViewSpec currentView;

  /// @docsEditable true
  @DomName('SVGSVGElement.height')
  final AnimatedLength height;

  /// @docsEditable true
  @DomName('SVGSVGElement.pixelUnitToMillimeterX')
  final num pixelUnitToMillimeterX;

  /// @docsEditable true
  @DomName('SVGSVGElement.pixelUnitToMillimeterY')
  final num pixelUnitToMillimeterY;

  /// @docsEditable true
  @DomName('SVGSVGElement.screenPixelToMillimeterX')
  final num screenPixelToMillimeterX;

  /// @docsEditable true
  @DomName('SVGSVGElement.screenPixelToMillimeterY')
  final num screenPixelToMillimeterY;

  /// @docsEditable true
  @DomName('SVGSVGElement.useCurrentView')
  final bool useCurrentView;

  /// @docsEditable true
  @DomName('SVGSVGElement.viewport')
  final Rect viewport;

  /// @docsEditable true
  @DomName('SVGSVGElement.width')
  final AnimatedLength width;

  /// @docsEditable true
  @DomName('SVGSVGElement.x')
  final AnimatedLength x;

  /// @docsEditable true
  @DomName('SVGSVGElement.y')
  final AnimatedLength y;

  /// @docsEditable true
  @DomName('SVGSVGElement.animationsPaused')
  bool animationsPaused() native;

  /// @docsEditable true
  @DomName('SVGSVGElement.checkEnclosure')
  bool checkEnclosure(SvgElement element, Rect rect) native;

  /// @docsEditable true
  @DomName('SVGSVGElement.checkIntersection')
  bool checkIntersection(SvgElement element, Rect rect) native;

  /// @docsEditable true
  @JSName('createSVGAngle')
  @DomName('SVGSVGElement.createSVGAngle')
  Angle createSvgAngle() native;

  /// @docsEditable true
  @JSName('createSVGLength')
  @DomName('SVGSVGElement.createSVGLength')
  Length createSvgLength() native;

  /// @docsEditable true
  @JSName('createSVGMatrix')
  @DomName('SVGSVGElement.createSVGMatrix')
  Matrix createSvgMatrix() native;

  /// @docsEditable true
  @JSName('createSVGNumber')
  @DomName('SVGSVGElement.createSVGNumber')
  Number createSvgNumber() native;

  /// @docsEditable true
  @JSName('createSVGPoint')
  @DomName('SVGSVGElement.createSVGPoint')
  Point createSvgPoint() native;

  /// @docsEditable true
  @JSName('createSVGRect')
  @DomName('SVGSVGElement.createSVGRect')
  Rect createSvgRect() native;

  /// @docsEditable true
  @JSName('createSVGTransform')
  @DomName('SVGSVGElement.createSVGTransform')
  Transform createSvgTransform() native;

  /// @docsEditable true
  @JSName('createSVGTransformFromMatrix')
  @DomName('SVGSVGElement.createSVGTransformFromMatrix')
  Transform createSvgTransformFromMatrix(Matrix matrix) native;

  /// @docsEditable true
  @DomName('SVGSVGElement.deselectAll')
  void deselectAll() native;

  /// @docsEditable true
  @DomName('SVGSVGElement.forceRedraw')
  void forceRedraw() native;

  /// @docsEditable true
  @DomName('SVGSVGElement.getCurrentTime')
  num getCurrentTime() native;

  /// @docsEditable true
  @DomName('SVGSVGElement.getElementById')
  Element getElementById(String elementId) native;

  /// @docsEditable true
  @DomName('SVGSVGElement.getEnclosureList')
  @Returns('NodeList') @Creates('NodeList')
  List<Node> getEnclosureList(Rect rect, SvgElement referenceElement) native;

  /// @docsEditable true
  @DomName('SVGSVGElement.getIntersectionList')
  @Returns('NodeList') @Creates('NodeList')
  List<Node> getIntersectionList(Rect rect, SvgElement referenceElement) native;

  /// @docsEditable true
  @DomName('SVGSVGElement.pauseAnimations')
  void pauseAnimations() native;

  /// @docsEditable true
  @DomName('SVGSVGElement.setCurrentTime')
  void setCurrentTime(num seconds) native;

  /// @docsEditable true
  @DomName('SVGSVGElement.suspendRedraw')
  int suspendRedraw(int maxWaitMilliseconds) native;

  /// @docsEditable true
  @DomName('SVGSVGElement.unpauseAnimations')
  void unpauseAnimations() native;

  /// @docsEditable true
  @DomName('SVGSVGElement.unsuspendRedraw')
  void unsuspendRedraw(int suspendHandleId) native;

  /// @docsEditable true
  @DomName('SVGSVGElement.unsuspendRedrawAll')
  void unsuspendRedrawAll() native;

  // From SVGExternalResourcesRequired

  /// @docsEditable true
  @DomName('SVGSVGElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGFitToViewBox

  /// @docsEditable true
  @DomName('SVGSVGElement.preserveAspectRatio')
  final AnimatedPreserveAspectRatio preserveAspectRatio;

  /// @docsEditable true
  @DomName('SVGSVGElement.viewBox')
  final AnimatedRect viewBox;

  // From SVGLangSpace

  /// @docsEditable true
  @DomName('SVGSVGElement.xmllang')
  String xmllang;

  /// @docsEditable true
  @DomName('SVGSVGElement.xmlspace')
  String xmlspace;

  // From SVGLocatable

  /// @docsEditable true
  @DomName('SVGSVGElement.farthestViewportElement')
  final SvgElement farthestViewportElement;

  /// @docsEditable true
  @DomName('SVGSVGElement.nearestViewportElement')
  final SvgElement nearestViewportElement;

  /// @docsEditable true
  @DomName('SVGSVGElement.getBBox')
  Rect getBBox() native;

  /// @docsEditable true
  @JSName('getCTM')
  @DomName('SVGSVGElement.getCTM')
  Matrix getCtm() native;

  /// @docsEditable true
  @JSName('getScreenCTM')
  @DomName('SVGSVGElement.getScreenCTM')
  Matrix getScreenCtm() native;

  /// @docsEditable true
  @DomName('SVGSVGElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  // Shadowing definition.
  /// @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  /// @docsEditable true
  @DomName('SVGSVGElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  /// @docsEditable true
  @DomName('SVGSVGElement.requiredExtensions')
  final StringList requiredExtensions;

  /// @docsEditable true
  @DomName('SVGSVGElement.requiredFeatures')
  final StringList requiredFeatures;

  /// @docsEditable true
  @DomName('SVGSVGElement.systemLanguage')
  final StringList systemLanguage;

  /// @docsEditable true
  @DomName('SVGSVGElement.hasExtension')
  bool hasExtension(String extension) native;

  // From SVGZoomAndPan

  /// @docsEditable true
  @DomName('SVGSVGElement.zoomAndPan')
  int zoomAndPan;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGSwitchElement')
class SwitchElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGSwitchElement" {

  /// @docsEditable true
  factory SwitchElement() => _SvgElementFactoryProvider.createSvgElement_tag("switch");

  // From SVGExternalResourcesRequired

  /// @docsEditable true
  @DomName('SVGSwitchElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /// @docsEditable true
  @DomName('SVGSwitchElement.xmllang')
  String xmllang;

  /// @docsEditable true
  @DomName('SVGSwitchElement.xmlspace')
  String xmlspace;

  // From SVGLocatable

  /// @docsEditable true
  @DomName('SVGSwitchElement.farthestViewportElement')
  final SvgElement farthestViewportElement;

  /// @docsEditable true
  @DomName('SVGSwitchElement.nearestViewportElement')
  final SvgElement nearestViewportElement;

  /// @docsEditable true
  @DomName('SVGSwitchElement.getBBox')
  Rect getBBox() native;

  /// @docsEditable true
  @JSName('getCTM')
  @DomName('SVGSwitchElement.getCTM')
  Matrix getCtm() native;

  /// @docsEditable true
  @JSName('getScreenCTM')
  @DomName('SVGSwitchElement.getScreenCTM')
  Matrix getScreenCtm() native;

  /// @docsEditable true
  @DomName('SVGSwitchElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  // Shadowing definition.
  /// @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  /// @docsEditable true
  @DomName('SVGSwitchElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  /// @docsEditable true
  @DomName('SVGSwitchElement.requiredExtensions')
  final StringList requiredExtensions;

  /// @docsEditable true
  @DomName('SVGSwitchElement.requiredFeatures')
  final StringList requiredFeatures;

  /// @docsEditable true
  @DomName('SVGSwitchElement.systemLanguage')
  final StringList systemLanguage;

  /// @docsEditable true
  @DomName('SVGSwitchElement.hasExtension')
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /// @docsEditable true
  @DomName('SVGSwitchElement.transform')
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGSymbolElement')
class SymbolElement extends SvgElement implements FitToViewBox, ExternalResourcesRequired, Stylable, LangSpace native "*SVGSymbolElement" {

  /// @docsEditable true
  factory SymbolElement() => _SvgElementFactoryProvider.createSvgElement_tag("symbol");

  // From SVGExternalResourcesRequired

  /// @docsEditable true
  @DomName('SVGSymbolElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGFitToViewBox

  /// @docsEditable true
  @DomName('SVGSymbolElement.preserveAspectRatio')
  final AnimatedPreserveAspectRatio preserveAspectRatio;

  /// @docsEditable true
  @DomName('SVGSymbolElement.viewBox')
  final AnimatedRect viewBox;

  // From SVGLangSpace

  /// @docsEditable true
  @DomName('SVGSymbolElement.xmllang')
  String xmllang;

  /// @docsEditable true
  @DomName('SVGSymbolElement.xmlspace')
  String xmlspace;

  // From SVGStylable

  // Shadowing definition.
  /// @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  /// @docsEditable true
  @DomName('SVGSymbolElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGTRefElement')
class TRefElement extends TextPositioningElement implements UriReference native "*SVGTRefElement" {

  /// @docsEditable true
  factory TRefElement() => _SvgElementFactoryProvider.createSvgElement_tag("tref");

  // From SVGURIReference

  /// @docsEditable true
  @DomName('SVGTRefElement.href')
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGTSpanElement')
class TSpanElement extends TextPositioningElement native "*SVGTSpanElement" {

  /// @docsEditable true
  factory TSpanElement() => _SvgElementFactoryProvider.createSvgElement_tag("tspan");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGTests')
abstract class Tests {

  StringList requiredExtensions;

  StringList requiredFeatures;

  StringList systemLanguage;

  /// @docsEditable true
  bool hasExtension(String extension);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGTextContentElement')
class TextContentElement extends SvgElement implements Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGTextContentElement" {

  static const int LENGTHADJUST_SPACING = 1;

  static const int LENGTHADJUST_SPACINGANDGLYPHS = 2;

  static const int LENGTHADJUST_UNKNOWN = 0;

  /// @docsEditable true
  @DomName('SVGTextContentElement.lengthAdjust')
  final AnimatedEnumeration lengthAdjust;

  /// @docsEditable true
  @DomName('SVGTextContentElement.textLength')
  final AnimatedLength textLength;

  /// @docsEditable true
  @DomName('SVGTextContentElement.getCharNumAtPosition')
  int getCharNumAtPosition(Point point) native;

  /// @docsEditable true
  @DomName('SVGTextContentElement.getComputedTextLength')
  num getComputedTextLength() native;

  /// @docsEditable true
  @DomName('SVGTextContentElement.getEndPositionOfChar')
  Point getEndPositionOfChar(int offset) native;

  /// @docsEditable true
  @DomName('SVGTextContentElement.getExtentOfChar')
  Rect getExtentOfChar(int offset) native;

  /// @docsEditable true
  @DomName('SVGTextContentElement.getNumberOfChars')
  int getNumberOfChars() native;

  /// @docsEditable true
  @DomName('SVGTextContentElement.getRotationOfChar')
  num getRotationOfChar(int offset) native;

  /// @docsEditable true
  @DomName('SVGTextContentElement.getStartPositionOfChar')
  Point getStartPositionOfChar(int offset) native;

  /// @docsEditable true
  @DomName('SVGTextContentElement.getSubStringLength')
  num getSubStringLength(int offset, int length) native;

  /// @docsEditable true
  @DomName('SVGTextContentElement.selectSubString')
  void selectSubString(int offset, int length) native;

  // From SVGExternalResourcesRequired

  /// @docsEditable true
  @DomName('SVGTextContentElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /// @docsEditable true
  @DomName('SVGTextContentElement.xmllang')
  String xmllang;

  /// @docsEditable true
  @DomName('SVGTextContentElement.xmlspace')
  String xmlspace;

  // From SVGStylable

  // Shadowing definition.
  /// @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  /// @docsEditable true
  @DomName('SVGTextContentElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  /// @docsEditable true
  @DomName('SVGTextContentElement.requiredExtensions')
  final StringList requiredExtensions;

  /// @docsEditable true
  @DomName('SVGTextContentElement.requiredFeatures')
  final StringList requiredFeatures;

  /// @docsEditable true
  @DomName('SVGTextContentElement.systemLanguage')
  final StringList systemLanguage;

  /// @docsEditable true
  @DomName('SVGTextContentElement.hasExtension')
  bool hasExtension(String extension) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGTextElement')
class TextElement extends TextPositioningElement implements Transformable native "*SVGTextElement" {

  /// @docsEditable true
  factory TextElement() => _SvgElementFactoryProvider.createSvgElement_tag("text");

  // From SVGLocatable

  /// @docsEditable true
  @DomName('SVGTextElement.farthestViewportElement')
  final SvgElement farthestViewportElement;

  /// @docsEditable true
  @DomName('SVGTextElement.nearestViewportElement')
  final SvgElement nearestViewportElement;

  /// @docsEditable true
  @DomName('SVGTextElement.getBBox')
  Rect getBBox() native;

  /// @docsEditable true
  @JSName('getCTM')
  @DomName('SVGTextElement.getCTM')
  Matrix getCtm() native;

  /// @docsEditable true
  @JSName('getScreenCTM')
  @DomName('SVGTextElement.getScreenCTM')
  Matrix getScreenCtm() native;

  /// @docsEditable true
  @DomName('SVGTextElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGTransformable

  /// @docsEditable true
  @DomName('SVGTextElement.transform')
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGTextPathElement')
class TextPathElement extends TextContentElement implements UriReference native "*SVGTextPathElement" {

  static const int TEXTPATH_METHODTYPE_ALIGN = 1;

  static const int TEXTPATH_METHODTYPE_STRETCH = 2;

  static const int TEXTPATH_METHODTYPE_UNKNOWN = 0;

  static const int TEXTPATH_SPACINGTYPE_AUTO = 1;

  static const int TEXTPATH_SPACINGTYPE_EXACT = 2;

  static const int TEXTPATH_SPACINGTYPE_UNKNOWN = 0;

  /// @docsEditable true
  @DomName('SVGTextPathElement.method')
  final AnimatedEnumeration method;

  /// @docsEditable true
  @DomName('SVGTextPathElement.spacing')
  final AnimatedEnumeration spacing;

  /// @docsEditable true
  @DomName('SVGTextPathElement.startOffset')
  final AnimatedLength startOffset;

  // From SVGURIReference

  /// @docsEditable true
  @DomName('SVGTextPathElement.href')
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGTextPositioningElement')
class TextPositioningElement extends TextContentElement native "*SVGTextPositioningElement" {

  /// @docsEditable true
  @DomName('SVGTextPositioningElement.dx')
  final AnimatedLengthList dx;

  /// @docsEditable true
  @DomName('SVGTextPositioningElement.dy')
  final AnimatedLengthList dy;

  /// @docsEditable true
  @DomName('SVGTextPositioningElement.rotate')
  final AnimatedNumberList rotate;

  /// @docsEditable true
  @DomName('SVGTextPositioningElement.x')
  final AnimatedLengthList x;

  /// @docsEditable true
  @DomName('SVGTextPositioningElement.y')
  final AnimatedLengthList y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGTitleElement')
class TitleElement extends SvgElement implements Stylable, LangSpace native "*SVGTitleElement" {

  /// @docsEditable true
  factory TitleElement() => _SvgElementFactoryProvider.createSvgElement_tag("title");

  // From SVGLangSpace

  /// @docsEditable true
  @DomName('SVGTitleElement.xmllang')
  String xmllang;

  /// @docsEditable true
  @DomName('SVGTitleElement.xmlspace')
  String xmlspace;

  // From SVGStylable

  // Shadowing definition.
  /// @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  /// @docsEditable true
  @DomName('SVGTitleElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGTransform')
class Transform native "*SVGTransform" {

  static const int SVG_TRANSFORM_MATRIX = 1;

  static const int SVG_TRANSFORM_ROTATE = 4;

  static const int SVG_TRANSFORM_SCALE = 3;

  static const int SVG_TRANSFORM_SKEWX = 5;

  static const int SVG_TRANSFORM_SKEWY = 6;

  static const int SVG_TRANSFORM_TRANSLATE = 2;

  static const int SVG_TRANSFORM_UNKNOWN = 0;

  /// @docsEditable true
  @DomName('SVGTransform.angle')
  final num angle;

  /// @docsEditable true
  @DomName('SVGTransform.matrix')
  final Matrix matrix;

  /// @docsEditable true
  @DomName('SVGTransform.type')
  final int type;

  /// @docsEditable true
  @DomName('SVGTransform.setMatrix')
  void setMatrix(Matrix matrix) native;

  /// @docsEditable true
  @DomName('SVGTransform.setRotate')
  void setRotate(num angle, num cx, num cy) native;

  /// @docsEditable true
  @DomName('SVGTransform.setScale')
  void setScale(num sx, num sy) native;

  /// @docsEditable true
  @DomName('SVGTransform.setSkewX')
  void setSkewX(num angle) native;

  /// @docsEditable true
  @DomName('SVGTransform.setSkewY')
  void setSkewY(num angle) native;

  /// @docsEditable true
  @DomName('SVGTransform.setTranslate')
  void setTranslate(num tx, num ty) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGTransformList')
class TransformList implements List<Transform>, JavaScriptIndexingBehavior native "*SVGTransformList" {

  /// @docsEditable true
  @DomName('SVGTransformList.numberOfItems')
  final int numberOfItems;

  Transform operator[](int index) => JS("Transform", "#[#]", this, index);

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

  /// @docsEditable true
  @DomName('SVGTransformList.appendItem')
  Transform appendItem(Transform item) native;

  /// @docsEditable true
  @DomName('SVGTransformList.clear')
  void clear() native;

  /// @docsEditable true
  @DomName('SVGTransformList.consolidate')
  Transform consolidate() native;

  /// @docsEditable true
  @JSName('createSVGTransformFromMatrix')
  @DomName('SVGTransformList.createSVGTransformFromMatrix')
  Transform createSvgTransformFromMatrix(Matrix matrix) native;

  /// @docsEditable true
  @DomName('SVGTransformList.getItem')
  Transform getItem(int index) native;

  /// @docsEditable true
  @DomName('SVGTransformList.initialize')
  Transform initialize(Transform item) native;

  /// @docsEditable true
  @DomName('SVGTransformList.insertItemBefore')
  Transform insertItemBefore(Transform item, int index) native;

  /// @docsEditable true
  @DomName('SVGTransformList.removeItem')
  Transform removeItem(int index) native;

  /// @docsEditable true
  @DomName('SVGTransformList.replaceItem')
  Transform replaceItem(Transform item, int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGTransformable')
abstract class Transformable implements Locatable {

  AnimatedTransformList transform;

  // From SVGLocatable

  SvgElement farthestViewportElement;

  SvgElement nearestViewportElement;

  /// @docsEditable true
  Rect getBBox();

  /// @docsEditable true
  Matrix getCTM();

  /// @docsEditable true
  Matrix getScreenCTM();

  /// @docsEditable true
  Matrix getTransformToElement(SvgElement element);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGUnitTypes')
class UnitTypes native "*SVGUnitTypes" {

  static const int SVG_UNIT_TYPE_OBJECTBOUNDINGBOX = 2;

  static const int SVG_UNIT_TYPE_UNKNOWN = 0;

  static const int SVG_UNIT_TYPE_USERSPACEONUSE = 1;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGURIReference')
abstract class UriReference {

  AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGUseElement')
class UseElement extends SvgElement implements Transformable, Tests, UriReference, Stylable, ExternalResourcesRequired, LangSpace native "*SVGUseElement" {

  /// @docsEditable true
  factory UseElement() => _SvgElementFactoryProvider.createSvgElement_tag("use");

  /// @docsEditable true
  @DomName('SVGUseElement.animatedInstanceRoot')
  final ElementInstance animatedInstanceRoot;

  /// @docsEditable true
  @DomName('SVGUseElement.height')
  final AnimatedLength height;

  /// @docsEditable true
  @DomName('SVGUseElement.instanceRoot')
  final ElementInstance instanceRoot;

  /// @docsEditable true
  @DomName('SVGUseElement.width')
  final AnimatedLength width;

  /// @docsEditable true
  @DomName('SVGUseElement.x')
  final AnimatedLength x;

  /// @docsEditable true
  @DomName('SVGUseElement.y')
  final AnimatedLength y;

  // From SVGExternalResourcesRequired

  /// @docsEditable true
  @DomName('SVGUseElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  /// @docsEditable true
  @DomName('SVGUseElement.xmllang')
  String xmllang;

  /// @docsEditable true
  @DomName('SVGUseElement.xmlspace')
  String xmlspace;

  // From SVGLocatable

  /// @docsEditable true
  @DomName('SVGUseElement.farthestViewportElement')
  final SvgElement farthestViewportElement;

  /// @docsEditable true
  @DomName('SVGUseElement.nearestViewportElement')
  final SvgElement nearestViewportElement;

  /// @docsEditable true
  @DomName('SVGUseElement.getBBox')
  Rect getBBox() native;

  /// @docsEditable true
  @JSName('getCTM')
  @DomName('SVGUseElement.getCTM')
  Matrix getCtm() native;

  /// @docsEditable true
  @JSName('getScreenCTM')
  @DomName('SVGUseElement.getScreenCTM')
  Matrix getScreenCtm() native;

  /// @docsEditable true
  @DomName('SVGUseElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  // Shadowing definition.
  /// @docsEditable true
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  /// @docsEditable true
  @DomName('SVGUseElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  /// @docsEditable true
  @DomName('SVGUseElement.requiredExtensions')
  final StringList requiredExtensions;

  /// @docsEditable true
  @DomName('SVGUseElement.requiredFeatures')
  final StringList requiredFeatures;

  /// @docsEditable true
  @DomName('SVGUseElement.systemLanguage')
  final StringList systemLanguage;

  /// @docsEditable true
  @DomName('SVGUseElement.hasExtension')
  bool hasExtension(String extension) native;

  // From SVGTransformable

  /// @docsEditable true
  @DomName('SVGUseElement.transform')
  final AnimatedTransformList transform;

  // From SVGURIReference

  /// @docsEditable true
  @DomName('SVGUseElement.href')
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGVKernElement')
class VKernElement extends SvgElement native "*SVGVKernElement" {

  /// @docsEditable true
  factory VKernElement() => _SvgElementFactoryProvider.createSvgElement_tag("vkern");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGViewElement')
class ViewElement extends SvgElement implements FitToViewBox, ExternalResourcesRequired, ZoomAndPan native "*SVGViewElement" {

  /// @docsEditable true
  factory ViewElement() => _SvgElementFactoryProvider.createSvgElement_tag("view");

  /// @docsEditable true
  @DomName('SVGViewElement.viewTarget')
  final StringList viewTarget;

  // From SVGExternalResourcesRequired

  /// @docsEditable true
  @DomName('SVGViewElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGFitToViewBox

  /// @docsEditable true
  @DomName('SVGViewElement.preserveAspectRatio')
  final AnimatedPreserveAspectRatio preserveAspectRatio;

  /// @docsEditable true
  @DomName('SVGViewElement.viewBox')
  final AnimatedRect viewBox;

  // From SVGZoomAndPan

  /// @docsEditable true
  @DomName('SVGViewElement.zoomAndPan')
  int zoomAndPan;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGViewSpec')
class ViewSpec native "*SVGViewSpec" {

  /// @docsEditable true
  @DomName('SVGViewSpec.preserveAspectRatio')
  final AnimatedPreserveAspectRatio preserveAspectRatio;

  /// @docsEditable true
  @DomName('SVGViewSpec.preserveAspectRatioString')
  final String preserveAspectRatioString;

  /// @docsEditable true
  @DomName('SVGViewSpec.transform')
  final TransformList transform;

  /// @docsEditable true
  @DomName('SVGViewSpec.transformString')
  final String transformString;

  /// @docsEditable true
  @DomName('SVGViewSpec.viewBox')
  final AnimatedRect viewBox;

  /// @docsEditable true
  @DomName('SVGViewSpec.viewBoxString')
  final String viewBoxString;

  /// @docsEditable true
  @DomName('SVGViewSpec.viewTarget')
  final SvgElement viewTarget;

  /// @docsEditable true
  @DomName('SVGViewSpec.viewTargetString')
  final String viewTargetString;

  /// @docsEditable true
  @DomName('SVGViewSpec.zoomAndPan')
  int zoomAndPan;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGZoomAndPan')
abstract class ZoomAndPan {

  static const int SVG_ZOOMANDPAN_DISABLE = 1;

  static const int SVG_ZOOMANDPAN_MAGNIFY = 2;

  static const int SVG_ZOOMANDPAN_UNKNOWN = 0;

  int zoomAndPan;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGZoomEvent')
class ZoomEvent extends UIEvent native "*SVGZoomEvent" {

  /// @docsEditable true
  @DomName('SVGZoomEvent.newScale')
  final num newScale;

  /// @docsEditable true
  @DomName('SVGZoomEvent.newTranslate')
  final Point newTranslate;

  /// @docsEditable true
  @DomName('SVGZoomEvent.previousScale')
  final num previousScale;

  /// @docsEditable true
  @DomName('SVGZoomEvent.previousTranslate')
  final Point previousTranslate;

  /// @docsEditable true
  @DomName('SVGZoomEvent.zoomRectScreen')
  final Rect zoomRectScreen;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('SVGElementInstanceList')
class _ElementInstanceList implements JavaScriptIndexingBehavior, List<ElementInstance> native "*SVGElementInstanceList" {

  /// @docsEditable true
  @DomName('SVGElementInstanceList.length')
  int get length => JS("int", "#.length", this);

  ElementInstance operator[](int index) => JS("ElementInstance", "#[#]", this, index);

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

  /// @docsEditable true
  @DomName('SVGElementInstanceList.item')
  ElementInstance item(int index) native;
}
