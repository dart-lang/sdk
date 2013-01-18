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



@DocsEditable
@DomName('SVGAElement')
class AElement extends SvgElement implements Transformable, Tests, UriReference, Stylable, ExternalResourcesRequired, LangSpace native "*SVGAElement" {

  @DocsEditable
  factory AElement() => _SvgElementFactoryProvider.createSvgElement_tag("a");

  @DocsEditable @DomName('SVGAElement.target')
  final AnimatedString target;

  // From SVGExternalResourcesRequired

  @DocsEditable @DomName('SVGAElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  @DocsEditable @DomName('SVGAElement.xmllang')
  String xmllang;

  @DocsEditable @DomName('SVGAElement.xmlspace')
  String xmlspace;

  // From SVGLocatable

  @DocsEditable @DomName('SVGAElement.farthestViewportElement')
  final SvgElement farthestViewportElement;

  @DocsEditable @DomName('SVGAElement.nearestViewportElement')
  final SvgElement nearestViewportElement;

  @DocsEditable @DomName('SVGAElement.getBBox')
  Rect getBBox() native;

  @JSName('getCTM')
  @DocsEditable @DomName('SVGAElement.getCTM')
  Matrix getCtm() native;

  @JSName('getScreenCTM')
  @DocsEditable @DomName('SVGAElement.getScreenCTM')
  Matrix getScreenCtm() native;

  @DocsEditable @DomName('SVGAElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DocsEditable @DomName('SVGAElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  @DocsEditable @DomName('SVGAElement.requiredExtensions')
  final StringList requiredExtensions;

  @DocsEditable @DomName('SVGAElement.requiredFeatures')
  final StringList requiredFeatures;

  @DocsEditable @DomName('SVGAElement.systemLanguage')
  final StringList systemLanguage;

  @DocsEditable @DomName('SVGAElement.hasExtension')
  bool hasExtension(String extension) native;

  // From SVGTransformable

  @DocsEditable @DomName('SVGAElement.transform')
  final AnimatedTransformList transform;

  // From SVGURIReference

  @DocsEditable @DomName('SVGAElement.href')
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGAltGlyphDefElement')
class AltGlyphDefElement extends SvgElement native "*SVGAltGlyphDefElement" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGAltGlyphElement')
class AltGlyphElement extends TextPositioningElement implements UriReference native "*SVGAltGlyphElement" {

  @DocsEditable @DomName('SVGAltGlyphElement.format')
  String format;

  @DocsEditable @DomName('SVGAltGlyphElement.glyphRef')
  String glyphRef;

  // From SVGURIReference

  @DocsEditable @DomName('SVGAltGlyphElement.href')
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGAltGlyphItemElement')
class AltGlyphItemElement extends SvgElement native "*SVGAltGlyphItemElement" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGAngle')
class Angle native "*SVGAngle" {

  static const int SVG_ANGLETYPE_DEG = 2;

  static const int SVG_ANGLETYPE_GRAD = 4;

  static const int SVG_ANGLETYPE_RAD = 3;

  static const int SVG_ANGLETYPE_UNKNOWN = 0;

  static const int SVG_ANGLETYPE_UNSPECIFIED = 1;

  @DocsEditable @DomName('SVGAngle.unitType')
  final int unitType;

  @DocsEditable @DomName('SVGAngle.value')
  num value;

  @DocsEditable @DomName('SVGAngle.valueAsString')
  String valueAsString;

  @DocsEditable @DomName('SVGAngle.valueInSpecifiedUnits')
  num valueInSpecifiedUnits;

  @DocsEditable @DomName('SVGAngle.convertToSpecifiedUnits')
  void convertToSpecifiedUnits(int unitType) native;

  @DocsEditable @DomName('SVGAngle.newValueSpecifiedUnits')
  void newValueSpecifiedUnits(int unitType, num valueInSpecifiedUnits) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGAnimateColorElement')
class AnimateColorElement extends AnimationElement native "*SVGAnimateColorElement" {

  @DocsEditable
  factory AnimateColorElement() => _SvgElementFactoryProvider.createSvgElement_tag("animateColor");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGAnimateElement')
class AnimateElement extends AnimationElement native "*SVGAnimateElement" {

  @DocsEditable
  factory AnimateElement() => _SvgElementFactoryProvider.createSvgElement_tag("animate");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGAnimateMotionElement')
class AnimateMotionElement extends AnimationElement native "*SVGAnimateMotionElement" {

  @DocsEditable
  factory AnimateMotionElement() => _SvgElementFactoryProvider.createSvgElement_tag("animateMotion");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGAnimateTransformElement')
class AnimateTransformElement extends AnimationElement native "*SVGAnimateTransformElement" {

  @DocsEditable
  factory AnimateTransformElement() => _SvgElementFactoryProvider.createSvgElement_tag("animateTransform");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGAnimatedAngle')
class AnimatedAngle native "*SVGAnimatedAngle" {

  @DocsEditable @DomName('SVGAnimatedAngle.animVal')
  final Angle animVal;

  @DocsEditable @DomName('SVGAnimatedAngle.baseVal')
  final Angle baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGAnimatedBoolean')
class AnimatedBoolean native "*SVGAnimatedBoolean" {

  @DocsEditable @DomName('SVGAnimatedBoolean.animVal')
  final bool animVal;

  @DocsEditable @DomName('SVGAnimatedBoolean.baseVal')
  bool baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGAnimatedEnumeration')
class AnimatedEnumeration native "*SVGAnimatedEnumeration" {

  @DocsEditable @DomName('SVGAnimatedEnumeration.animVal')
  final int animVal;

  @DocsEditable @DomName('SVGAnimatedEnumeration.baseVal')
  int baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGAnimatedInteger')
class AnimatedInteger native "*SVGAnimatedInteger" {

  @DocsEditable @DomName('SVGAnimatedInteger.animVal')
  final int animVal;

  @DocsEditable @DomName('SVGAnimatedInteger.baseVal')
  int baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGAnimatedLength')
class AnimatedLength native "*SVGAnimatedLength" {

  @DocsEditable @DomName('SVGAnimatedLength.animVal')
  final Length animVal;

  @DocsEditable @DomName('SVGAnimatedLength.baseVal')
  final Length baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGAnimatedLengthList')
class AnimatedLengthList native "*SVGAnimatedLengthList" {

  @DocsEditable @DomName('SVGAnimatedLengthList.animVal')
  final LengthList animVal;

  @DocsEditable @DomName('SVGAnimatedLengthList.baseVal')
  final LengthList baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGAnimatedNumber')
class AnimatedNumber native "*SVGAnimatedNumber" {

  @DocsEditable @DomName('SVGAnimatedNumber.animVal')
  final num animVal;

  @DocsEditable @DomName('SVGAnimatedNumber.baseVal')
  num baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGAnimatedNumberList')
class AnimatedNumberList native "*SVGAnimatedNumberList" {

  @DocsEditable @DomName('SVGAnimatedNumberList.animVal')
  final NumberList animVal;

  @DocsEditable @DomName('SVGAnimatedNumberList.baseVal')
  final NumberList baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGAnimatedPreserveAspectRatio')
class AnimatedPreserveAspectRatio native "*SVGAnimatedPreserveAspectRatio" {

  @DocsEditable @DomName('SVGAnimatedPreserveAspectRatio.animVal')
  final PreserveAspectRatio animVal;

  @DocsEditable @DomName('SVGAnimatedPreserveAspectRatio.baseVal')
  final PreserveAspectRatio baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGAnimatedRect')
class AnimatedRect native "*SVGAnimatedRect" {

  @DocsEditable @DomName('SVGAnimatedRect.animVal')
  final Rect animVal;

  @DocsEditable @DomName('SVGAnimatedRect.baseVal')
  final Rect baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGAnimatedString')
class AnimatedString native "*SVGAnimatedString" {

  @DocsEditable @DomName('SVGAnimatedString.animVal')
  final String animVal;

  @DocsEditable @DomName('SVGAnimatedString.baseVal')
  String baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGAnimatedTransformList')
class AnimatedTransformList native "*SVGAnimatedTransformList" {

  @DocsEditable @DomName('SVGAnimatedTransformList.animVal')
  final TransformList animVal;

  @DocsEditable @DomName('SVGAnimatedTransformList.baseVal')
  final TransformList baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGAnimationElement')
class AnimationElement extends SvgElement implements Tests, ElementTimeControl, ExternalResourcesRequired native "*SVGAnimationElement" {

  @DocsEditable
  factory AnimationElement() => _SvgElementFactoryProvider.createSvgElement_tag("animation");

  @DocsEditable @DomName('SVGAnimationElement.targetElement')
  final SvgElement targetElement;

  @DocsEditable @DomName('SVGAnimationElement.getCurrentTime')
  num getCurrentTime() native;

  @DocsEditable @DomName('SVGAnimationElement.getSimpleDuration')
  num getSimpleDuration() native;

  @DocsEditable @DomName('SVGAnimationElement.getStartTime')
  num getStartTime() native;

  // From ElementTimeControl

  @DocsEditable @DomName('SVGAnimationElement.beginElement')
  void beginElement() native;

  @DocsEditable @DomName('SVGAnimationElement.beginElementAt')
  void beginElementAt(num offset) native;

  @DocsEditable @DomName('SVGAnimationElement.endElement')
  void endElement() native;

  @DocsEditable @DomName('SVGAnimationElement.endElementAt')
  void endElementAt(num offset) native;

  // From SVGExternalResourcesRequired

  @DocsEditable @DomName('SVGAnimationElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGTests

  @DocsEditable @DomName('SVGAnimationElement.requiredExtensions')
  final StringList requiredExtensions;

  @DocsEditable @DomName('SVGAnimationElement.requiredFeatures')
  final StringList requiredFeatures;

  @DocsEditable @DomName('SVGAnimationElement.systemLanguage')
  final StringList systemLanguage;

  @DocsEditable @DomName('SVGAnimationElement.hasExtension')
  bool hasExtension(String extension) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGCircleElement')
class CircleElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGCircleElement" {

  @DocsEditable
  factory CircleElement() => _SvgElementFactoryProvider.createSvgElement_tag("circle");

  @DocsEditable @DomName('SVGCircleElement.cx')
  final AnimatedLength cx;

  @DocsEditable @DomName('SVGCircleElement.cy')
  final AnimatedLength cy;

  @DocsEditable @DomName('SVGCircleElement.r')
  final AnimatedLength r;

  // From SVGExternalResourcesRequired

  @DocsEditable @DomName('SVGCircleElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  @DocsEditable @DomName('SVGCircleElement.xmllang')
  String xmllang;

  @DocsEditable @DomName('SVGCircleElement.xmlspace')
  String xmlspace;

  // From SVGLocatable

  @DocsEditable @DomName('SVGCircleElement.farthestViewportElement')
  final SvgElement farthestViewportElement;

  @DocsEditable @DomName('SVGCircleElement.nearestViewportElement')
  final SvgElement nearestViewportElement;

  @DocsEditable @DomName('SVGCircleElement.getBBox')
  Rect getBBox() native;

  @JSName('getCTM')
  @DocsEditable @DomName('SVGCircleElement.getCTM')
  Matrix getCtm() native;

  @JSName('getScreenCTM')
  @DocsEditable @DomName('SVGCircleElement.getScreenCTM')
  Matrix getScreenCtm() native;

  @DocsEditable @DomName('SVGCircleElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DocsEditable @DomName('SVGCircleElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  @DocsEditable @DomName('SVGCircleElement.requiredExtensions')
  final StringList requiredExtensions;

  @DocsEditable @DomName('SVGCircleElement.requiredFeatures')
  final StringList requiredFeatures;

  @DocsEditable @DomName('SVGCircleElement.systemLanguage')
  final StringList systemLanguage;

  @DocsEditable @DomName('SVGCircleElement.hasExtension')
  bool hasExtension(String extension) native;

  // From SVGTransformable

  @DocsEditable @DomName('SVGCircleElement.transform')
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGClipPathElement')
class ClipPathElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGClipPathElement" {

  @DocsEditable
  factory ClipPathElement() => _SvgElementFactoryProvider.createSvgElement_tag("clipPath");

  @DocsEditable @DomName('SVGClipPathElement.clipPathUnits')
  final AnimatedEnumeration clipPathUnits;

  // From SVGExternalResourcesRequired

  @DocsEditable @DomName('SVGClipPathElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  @DocsEditable @DomName('SVGClipPathElement.xmllang')
  String xmllang;

  @DocsEditable @DomName('SVGClipPathElement.xmlspace')
  String xmlspace;

  // From SVGLocatable

  @DocsEditable @DomName('SVGClipPathElement.farthestViewportElement')
  final SvgElement farthestViewportElement;

  @DocsEditable @DomName('SVGClipPathElement.nearestViewportElement')
  final SvgElement nearestViewportElement;

  @DocsEditable @DomName('SVGClipPathElement.getBBox')
  Rect getBBox() native;

  @JSName('getCTM')
  @DocsEditable @DomName('SVGClipPathElement.getCTM')
  Matrix getCtm() native;

  @JSName('getScreenCTM')
  @DocsEditable @DomName('SVGClipPathElement.getScreenCTM')
  Matrix getScreenCtm() native;

  @DocsEditable @DomName('SVGClipPathElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DocsEditable @DomName('SVGClipPathElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  @DocsEditable @DomName('SVGClipPathElement.requiredExtensions')
  final StringList requiredExtensions;

  @DocsEditable @DomName('SVGClipPathElement.requiredFeatures')
  final StringList requiredFeatures;

  @DocsEditable @DomName('SVGClipPathElement.systemLanguage')
  final StringList systemLanguage;

  @DocsEditable @DomName('SVGClipPathElement.hasExtension')
  bool hasExtension(String extension) native;

  // From SVGTransformable

  @DocsEditable @DomName('SVGClipPathElement.transform')
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGColor')
class Color extends CssValue native "*SVGColor" {

  static const int SVG_COLORTYPE_CURRENTCOLOR = 3;

  static const int SVG_COLORTYPE_RGBCOLOR = 1;

  static const int SVG_COLORTYPE_RGBCOLOR_ICCCOLOR = 2;

  static const int SVG_COLORTYPE_UNKNOWN = 0;

  @DocsEditable @DomName('SVGColor.colorType')
  final int colorType;

  @DocsEditable @DomName('SVGColor.rgbColor')
  final RgbColor rgbColor;

  @DocsEditable @DomName('SVGColor.setColor')
  void setColor(int colorType, String rgbColor, String iccColor) native;

  @JSName('setRGBColor')
  @DocsEditable @DomName('SVGColor.setRGBColor')
  void setRgbColor(String rgbColor) native;

  @JSName('setRGBColorICCColor')
  @DocsEditable @DomName('SVGColor.setRGBColorICCColor')
  void setRgbColorIccColor(String rgbColor, String iccColor) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGComponentTransferFunctionElement')
class ComponentTransferFunctionElement extends SvgElement native "*SVGComponentTransferFunctionElement" {

  static const int SVG_FECOMPONENTTRANSFER_TYPE_DISCRETE = 3;

  static const int SVG_FECOMPONENTTRANSFER_TYPE_GAMMA = 5;

  static const int SVG_FECOMPONENTTRANSFER_TYPE_IDENTITY = 1;

  static const int SVG_FECOMPONENTTRANSFER_TYPE_LINEAR = 4;

  static const int SVG_FECOMPONENTTRANSFER_TYPE_TABLE = 2;

  static const int SVG_FECOMPONENTTRANSFER_TYPE_UNKNOWN = 0;

  @DocsEditable @DomName('SVGComponentTransferFunctionElement.amplitude')
  final AnimatedNumber amplitude;

  @DocsEditable @DomName('SVGComponentTransferFunctionElement.exponent')
  final AnimatedNumber exponent;

  @DocsEditable @DomName('SVGComponentTransferFunctionElement.intercept')
  final AnimatedNumber intercept;

  @DocsEditable @DomName('SVGComponentTransferFunctionElement.offset')
  final AnimatedNumber offset;

  @DocsEditable @DomName('SVGComponentTransferFunctionElement.slope')
  final AnimatedNumber slope;

  @DocsEditable @DomName('SVGComponentTransferFunctionElement.tableValues')
  final AnimatedNumberList tableValues;

  @DocsEditable @DomName('SVGComponentTransferFunctionElement.type')
  final AnimatedEnumeration type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGCursorElement')
class CursorElement extends SvgElement implements UriReference, Tests, ExternalResourcesRequired native "*SVGCursorElement" {

  @DocsEditable
  factory CursorElement() => _SvgElementFactoryProvider.createSvgElement_tag("cursor");

  @DocsEditable @DomName('SVGCursorElement.x')
  final AnimatedLength x;

  @DocsEditable @DomName('SVGCursorElement.y')
  final AnimatedLength y;

  // From SVGExternalResourcesRequired

  @DocsEditable @DomName('SVGCursorElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGTests

  @DocsEditable @DomName('SVGCursorElement.requiredExtensions')
  final StringList requiredExtensions;

  @DocsEditable @DomName('SVGCursorElement.requiredFeatures')
  final StringList requiredFeatures;

  @DocsEditable @DomName('SVGCursorElement.systemLanguage')
  final StringList systemLanguage;

  @DocsEditable @DomName('SVGCursorElement.hasExtension')
  bool hasExtension(String extension) native;

  // From SVGURIReference

  @DocsEditable @DomName('SVGCursorElement.href')
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGDefsElement')
class DefsElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGDefsElement" {

  @DocsEditable
  factory DefsElement() => _SvgElementFactoryProvider.createSvgElement_tag("defs");

  // From SVGExternalResourcesRequired

  @DocsEditable @DomName('SVGDefsElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  @DocsEditable @DomName('SVGDefsElement.xmllang')
  String xmllang;

  @DocsEditable @DomName('SVGDefsElement.xmlspace')
  String xmlspace;

  // From SVGLocatable

  @DocsEditable @DomName('SVGDefsElement.farthestViewportElement')
  final SvgElement farthestViewportElement;

  @DocsEditable @DomName('SVGDefsElement.nearestViewportElement')
  final SvgElement nearestViewportElement;

  @DocsEditable @DomName('SVGDefsElement.getBBox')
  Rect getBBox() native;

  @JSName('getCTM')
  @DocsEditable @DomName('SVGDefsElement.getCTM')
  Matrix getCtm() native;

  @JSName('getScreenCTM')
  @DocsEditable @DomName('SVGDefsElement.getScreenCTM')
  Matrix getScreenCtm() native;

  @DocsEditable @DomName('SVGDefsElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DocsEditable @DomName('SVGDefsElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  @DocsEditable @DomName('SVGDefsElement.requiredExtensions')
  final StringList requiredExtensions;

  @DocsEditable @DomName('SVGDefsElement.requiredFeatures')
  final StringList requiredFeatures;

  @DocsEditable @DomName('SVGDefsElement.systemLanguage')
  final StringList systemLanguage;

  @DocsEditable @DomName('SVGDefsElement.hasExtension')
  bool hasExtension(String extension) native;

  // From SVGTransformable

  @DocsEditable @DomName('SVGDefsElement.transform')
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGDescElement')
class DescElement extends SvgElement implements Stylable, LangSpace native "*SVGDescElement" {

  @DocsEditable
  factory DescElement() => _SvgElementFactoryProvider.createSvgElement_tag("desc");

  // From SVGLangSpace

  @DocsEditable @DomName('SVGDescElement.xmllang')
  String xmllang;

  @DocsEditable @DomName('SVGDescElement.xmlspace')
  String xmlspace;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DocsEditable @DomName('SVGDescElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
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

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  ElementInstanceEvents get on =>
    new ElementInstanceEvents(this);

  @DocsEditable @DomName('SVGElementInstance.childNodes')
  @Returns('_ElementInstanceList') @Creates('_ElementInstanceList')
  final List<ElementInstance> childNodes;

  @DocsEditable @DomName('SVGElementInstance.correspondingElement')
  final SvgElement correspondingElement;

  @DocsEditable @DomName('SVGElementInstance.correspondingUseElement')
  final UseElement correspondingUseElement;

  @DocsEditable @DomName('SVGElementInstance.firstChild')
  final ElementInstance firstChild;

  @DocsEditable @DomName('SVGElementInstance.lastChild')
  final ElementInstance lastChild;

  @DocsEditable @DomName('SVGElementInstance.nextSibling')
  final ElementInstance nextSibling;

  @DocsEditable @DomName('SVGElementInstance.parentNode')
  final ElementInstance parentNode;

  @DocsEditable @DomName('SVGElementInstance.previousSibling')
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


@DocsEditable
@DomName('ElementTimeControl')
abstract class ElementTimeControl {

  void beginElement();

  void beginElementAt(num offset);

  void endElement();

  void endElementAt(num offset);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGEllipseElement')
class EllipseElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGEllipseElement" {

  @DocsEditable
  factory EllipseElement() => _SvgElementFactoryProvider.createSvgElement_tag("ellipse");

  @DocsEditable @DomName('SVGEllipseElement.cx')
  final AnimatedLength cx;

  @DocsEditable @DomName('SVGEllipseElement.cy')
  final AnimatedLength cy;

  @DocsEditable @DomName('SVGEllipseElement.rx')
  final AnimatedLength rx;

  @DocsEditable @DomName('SVGEllipseElement.ry')
  final AnimatedLength ry;

  // From SVGExternalResourcesRequired

  @DocsEditable @DomName('SVGEllipseElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  @DocsEditable @DomName('SVGEllipseElement.xmllang')
  String xmllang;

  @DocsEditable @DomName('SVGEllipseElement.xmlspace')
  String xmlspace;

  // From SVGLocatable

  @DocsEditable @DomName('SVGEllipseElement.farthestViewportElement')
  final SvgElement farthestViewportElement;

  @DocsEditable @DomName('SVGEllipseElement.nearestViewportElement')
  final SvgElement nearestViewportElement;

  @DocsEditable @DomName('SVGEllipseElement.getBBox')
  Rect getBBox() native;

  @JSName('getCTM')
  @DocsEditable @DomName('SVGEllipseElement.getCTM')
  Matrix getCtm() native;

  @JSName('getScreenCTM')
  @DocsEditable @DomName('SVGEllipseElement.getScreenCTM')
  Matrix getScreenCtm() native;

  @DocsEditable @DomName('SVGEllipseElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DocsEditable @DomName('SVGEllipseElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  @DocsEditable @DomName('SVGEllipseElement.requiredExtensions')
  final StringList requiredExtensions;

  @DocsEditable @DomName('SVGEllipseElement.requiredFeatures')
  final StringList requiredFeatures;

  @DocsEditable @DomName('SVGEllipseElement.systemLanguage')
  final StringList systemLanguage;

  @DocsEditable @DomName('SVGEllipseElement.hasExtension')
  bool hasExtension(String extension) native;

  // From SVGTransformable

  @DocsEditable @DomName('SVGEllipseElement.transform')
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGExternalResourcesRequired')
abstract class ExternalResourcesRequired {

  AnimatedBoolean externalResourcesRequired;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGFEBlendElement')
class FEBlendElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEBlendElement" {

  static const int SVG_FEBLEND_MODE_DARKEN = 4;

  static const int SVG_FEBLEND_MODE_LIGHTEN = 5;

  static const int SVG_FEBLEND_MODE_MULTIPLY = 2;

  static const int SVG_FEBLEND_MODE_NORMAL = 1;

  static const int SVG_FEBLEND_MODE_SCREEN = 3;

  static const int SVG_FEBLEND_MODE_UNKNOWN = 0;

  @DocsEditable @DomName('SVGFEBlendElement.in1')
  final AnimatedString in1;

  @DocsEditable @DomName('SVGFEBlendElement.in2')
  final AnimatedString in2;

  @DocsEditable @DomName('SVGFEBlendElement.mode')
  final AnimatedEnumeration mode;

  // From SVGFilterPrimitiveStandardAttributes

  @DocsEditable @DomName('SVGFEBlendElement.height')
  final AnimatedLength height;

  @DocsEditable @DomName('SVGFEBlendElement.result')
  final AnimatedString result;

  @DocsEditable @DomName('SVGFEBlendElement.width')
  final AnimatedLength width;

  @DocsEditable @DomName('SVGFEBlendElement.x')
  final AnimatedLength x;

  @DocsEditable @DomName('SVGFEBlendElement.y')
  final AnimatedLength y;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DocsEditable @DomName('SVGFEBlendElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGFEColorMatrixElement')
class FEColorMatrixElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEColorMatrixElement" {

  static const int SVG_FECOLORMATRIX_TYPE_HUEROTATE = 3;

  static const int SVG_FECOLORMATRIX_TYPE_LUMINANCETOALPHA = 4;

  static const int SVG_FECOLORMATRIX_TYPE_MATRIX = 1;

  static const int SVG_FECOLORMATRIX_TYPE_SATURATE = 2;

  static const int SVG_FECOLORMATRIX_TYPE_UNKNOWN = 0;

  @DocsEditable @DomName('SVGFEColorMatrixElement.in1')
  final AnimatedString in1;

  @DocsEditable @DomName('SVGFEColorMatrixElement.type')
  final AnimatedEnumeration type;

  @DocsEditable @DomName('SVGFEColorMatrixElement.values')
  final AnimatedNumberList values;

  // From SVGFilterPrimitiveStandardAttributes

  @DocsEditable @DomName('SVGFEColorMatrixElement.height')
  final AnimatedLength height;

  @DocsEditable @DomName('SVGFEColorMatrixElement.result')
  final AnimatedString result;

  @DocsEditable @DomName('SVGFEColorMatrixElement.width')
  final AnimatedLength width;

  @DocsEditable @DomName('SVGFEColorMatrixElement.x')
  final AnimatedLength x;

  @DocsEditable @DomName('SVGFEColorMatrixElement.y')
  final AnimatedLength y;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DocsEditable @DomName('SVGFEColorMatrixElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGFEComponentTransferElement')
class FEComponentTransferElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEComponentTransferElement" {

  @DocsEditable @DomName('SVGFEComponentTransferElement.in1')
  final AnimatedString in1;

  // From SVGFilterPrimitiveStandardAttributes

  @DocsEditable @DomName('SVGFEComponentTransferElement.height')
  final AnimatedLength height;

  @DocsEditable @DomName('SVGFEComponentTransferElement.result')
  final AnimatedString result;

  @DocsEditable @DomName('SVGFEComponentTransferElement.width')
  final AnimatedLength width;

  @DocsEditable @DomName('SVGFEComponentTransferElement.x')
  final AnimatedLength x;

  @DocsEditable @DomName('SVGFEComponentTransferElement.y')
  final AnimatedLength y;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DocsEditable @DomName('SVGFEComponentTransferElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGFECompositeElement')
class FECompositeElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFECompositeElement" {

  static const int SVG_FECOMPOSITE_OPERATOR_ARITHMETIC = 6;

  static const int SVG_FECOMPOSITE_OPERATOR_ATOP = 4;

  static const int SVG_FECOMPOSITE_OPERATOR_IN = 2;

  static const int SVG_FECOMPOSITE_OPERATOR_OUT = 3;

  static const int SVG_FECOMPOSITE_OPERATOR_OVER = 1;

  static const int SVG_FECOMPOSITE_OPERATOR_UNKNOWN = 0;

  static const int SVG_FECOMPOSITE_OPERATOR_XOR = 5;

  @DocsEditable @DomName('SVGFECompositeElement.in1')
  final AnimatedString in1;

  @DocsEditable @DomName('SVGFECompositeElement.in2')
  final AnimatedString in2;

  @DocsEditable @DomName('SVGFECompositeElement.k1')
  final AnimatedNumber k1;

  @DocsEditable @DomName('SVGFECompositeElement.k2')
  final AnimatedNumber k2;

  @DocsEditable @DomName('SVGFECompositeElement.k3')
  final AnimatedNumber k3;

  @DocsEditable @DomName('SVGFECompositeElement.k4')
  final AnimatedNumber k4;

  @DocsEditable @DomName('SVGFECompositeElement.operator')
  final AnimatedEnumeration operator;

  // From SVGFilterPrimitiveStandardAttributes

  @DocsEditable @DomName('SVGFECompositeElement.height')
  final AnimatedLength height;

  @DocsEditable @DomName('SVGFECompositeElement.result')
  final AnimatedString result;

  @DocsEditable @DomName('SVGFECompositeElement.width')
  final AnimatedLength width;

  @DocsEditable @DomName('SVGFECompositeElement.x')
  final AnimatedLength x;

  @DocsEditable @DomName('SVGFECompositeElement.y')
  final AnimatedLength y;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DocsEditable @DomName('SVGFECompositeElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGFEConvolveMatrixElement')
class FEConvolveMatrixElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEConvolveMatrixElement" {

  static const int SVG_EDGEMODE_DUPLICATE = 1;

  static const int SVG_EDGEMODE_NONE = 3;

  static const int SVG_EDGEMODE_UNKNOWN = 0;

  static const int SVG_EDGEMODE_WRAP = 2;

  @DocsEditable @DomName('SVGFEConvolveMatrixElement.bias')
  final AnimatedNumber bias;

  @DocsEditable @DomName('SVGFEConvolveMatrixElement.divisor')
  final AnimatedNumber divisor;

  @DocsEditable @DomName('SVGFEConvolveMatrixElement.edgeMode')
  final AnimatedEnumeration edgeMode;

  @DocsEditable @DomName('SVGFEConvolveMatrixElement.in1')
  final AnimatedString in1;

  @DocsEditable @DomName('SVGFEConvolveMatrixElement.kernelMatrix')
  final AnimatedNumberList kernelMatrix;

  @DocsEditable @DomName('SVGFEConvolveMatrixElement.kernelUnitLengthX')
  final AnimatedNumber kernelUnitLengthX;

  @DocsEditable @DomName('SVGFEConvolveMatrixElement.kernelUnitLengthY')
  final AnimatedNumber kernelUnitLengthY;

  @DocsEditable @DomName('SVGFEConvolveMatrixElement.orderX')
  final AnimatedInteger orderX;

  @DocsEditable @DomName('SVGFEConvolveMatrixElement.orderY')
  final AnimatedInteger orderY;

  @DocsEditable @DomName('SVGFEConvolveMatrixElement.preserveAlpha')
  final AnimatedBoolean preserveAlpha;

  @DocsEditable @DomName('SVGFEConvolveMatrixElement.targetX')
  final AnimatedInteger targetX;

  @DocsEditable @DomName('SVGFEConvolveMatrixElement.targetY')
  final AnimatedInteger targetY;

  // From SVGFilterPrimitiveStandardAttributes

  @DocsEditable @DomName('SVGFEConvolveMatrixElement.height')
  final AnimatedLength height;

  @DocsEditable @DomName('SVGFEConvolveMatrixElement.result')
  final AnimatedString result;

  @DocsEditable @DomName('SVGFEConvolveMatrixElement.width')
  final AnimatedLength width;

  @DocsEditable @DomName('SVGFEConvolveMatrixElement.x')
  final AnimatedLength x;

  @DocsEditable @DomName('SVGFEConvolveMatrixElement.y')
  final AnimatedLength y;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DocsEditable @DomName('SVGFEConvolveMatrixElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGFEDiffuseLightingElement')
class FEDiffuseLightingElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEDiffuseLightingElement" {

  @DocsEditable @DomName('SVGFEDiffuseLightingElement.diffuseConstant')
  final AnimatedNumber diffuseConstant;

  @DocsEditable @DomName('SVGFEDiffuseLightingElement.in1')
  final AnimatedString in1;

  @DocsEditable @DomName('SVGFEDiffuseLightingElement.kernelUnitLengthX')
  final AnimatedNumber kernelUnitLengthX;

  @DocsEditable @DomName('SVGFEDiffuseLightingElement.kernelUnitLengthY')
  final AnimatedNumber kernelUnitLengthY;

  @DocsEditable @DomName('SVGFEDiffuseLightingElement.surfaceScale')
  final AnimatedNumber surfaceScale;

  // From SVGFilterPrimitiveStandardAttributes

  @DocsEditable @DomName('SVGFEDiffuseLightingElement.height')
  final AnimatedLength height;

  @DocsEditable @DomName('SVGFEDiffuseLightingElement.result')
  final AnimatedString result;

  @DocsEditable @DomName('SVGFEDiffuseLightingElement.width')
  final AnimatedLength width;

  @DocsEditable @DomName('SVGFEDiffuseLightingElement.x')
  final AnimatedLength x;

  @DocsEditable @DomName('SVGFEDiffuseLightingElement.y')
  final AnimatedLength y;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DocsEditable @DomName('SVGFEDiffuseLightingElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGFEDisplacementMapElement')
class FEDisplacementMapElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEDisplacementMapElement" {

  static const int SVG_CHANNEL_A = 4;

  static const int SVG_CHANNEL_B = 3;

  static const int SVG_CHANNEL_G = 2;

  static const int SVG_CHANNEL_R = 1;

  static const int SVG_CHANNEL_UNKNOWN = 0;

  @DocsEditable @DomName('SVGFEDisplacementMapElement.in1')
  final AnimatedString in1;

  @DocsEditable @DomName('SVGFEDisplacementMapElement.in2')
  final AnimatedString in2;

  @DocsEditable @DomName('SVGFEDisplacementMapElement.scale')
  final AnimatedNumber scale;

  @DocsEditable @DomName('SVGFEDisplacementMapElement.xChannelSelector')
  final AnimatedEnumeration xChannelSelector;

  @DocsEditable @DomName('SVGFEDisplacementMapElement.yChannelSelector')
  final AnimatedEnumeration yChannelSelector;

  // From SVGFilterPrimitiveStandardAttributes

  @DocsEditable @DomName('SVGFEDisplacementMapElement.height')
  final AnimatedLength height;

  @DocsEditable @DomName('SVGFEDisplacementMapElement.result')
  final AnimatedString result;

  @DocsEditable @DomName('SVGFEDisplacementMapElement.width')
  final AnimatedLength width;

  @DocsEditable @DomName('SVGFEDisplacementMapElement.x')
  final AnimatedLength x;

  @DocsEditable @DomName('SVGFEDisplacementMapElement.y')
  final AnimatedLength y;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DocsEditable @DomName('SVGFEDisplacementMapElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGFEDistantLightElement')
class FEDistantLightElement extends SvgElement native "*SVGFEDistantLightElement" {

  @DocsEditable @DomName('SVGFEDistantLightElement.azimuth')
  final AnimatedNumber azimuth;

  @DocsEditable @DomName('SVGFEDistantLightElement.elevation')
  final AnimatedNumber elevation;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGFEDropShadowElement')
class FEDropShadowElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEDropShadowElement" {

  @DocsEditable @DomName('SVGFEDropShadowElement.dx')
  final AnimatedNumber dx;

  @DocsEditable @DomName('SVGFEDropShadowElement.dy')
  final AnimatedNumber dy;

  @DocsEditable @DomName('SVGFEDropShadowElement.in1')
  final AnimatedString in1;

  @DocsEditable @DomName('SVGFEDropShadowElement.stdDeviationX')
  final AnimatedNumber stdDeviationX;

  @DocsEditable @DomName('SVGFEDropShadowElement.stdDeviationY')
  final AnimatedNumber stdDeviationY;

  @DocsEditable @DomName('SVGFEDropShadowElement.setStdDeviation')
  void setStdDeviation(num stdDeviationX, num stdDeviationY) native;

  // From SVGFilterPrimitiveStandardAttributes

  @DocsEditable @DomName('SVGFEDropShadowElement.height')
  final AnimatedLength height;

  @DocsEditable @DomName('SVGFEDropShadowElement.result')
  final AnimatedString result;

  @DocsEditable @DomName('SVGFEDropShadowElement.width')
  final AnimatedLength width;

  @DocsEditable @DomName('SVGFEDropShadowElement.x')
  final AnimatedLength x;

  @DocsEditable @DomName('SVGFEDropShadowElement.y')
  final AnimatedLength y;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DocsEditable @DomName('SVGFEDropShadowElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGFEFloodElement')
class FEFloodElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEFloodElement" {

  // From SVGFilterPrimitiveStandardAttributes

  @DocsEditable @DomName('SVGFEFloodElement.height')
  final AnimatedLength height;

  @DocsEditable @DomName('SVGFEFloodElement.result')
  final AnimatedString result;

  @DocsEditable @DomName('SVGFEFloodElement.width')
  final AnimatedLength width;

  @DocsEditable @DomName('SVGFEFloodElement.x')
  final AnimatedLength x;

  @DocsEditable @DomName('SVGFEFloodElement.y')
  final AnimatedLength y;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DocsEditable @DomName('SVGFEFloodElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGFEFuncAElement')
class FEFuncAElement extends ComponentTransferFunctionElement native "*SVGFEFuncAElement" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGFEFuncBElement')
class FEFuncBElement extends ComponentTransferFunctionElement native "*SVGFEFuncBElement" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGFEFuncGElement')
class FEFuncGElement extends ComponentTransferFunctionElement native "*SVGFEFuncGElement" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGFEFuncRElement')
class FEFuncRElement extends ComponentTransferFunctionElement native "*SVGFEFuncRElement" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGFEGaussianBlurElement')
class FEGaussianBlurElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEGaussianBlurElement" {

  @DocsEditable @DomName('SVGFEGaussianBlurElement.in1')
  final AnimatedString in1;

  @DocsEditable @DomName('SVGFEGaussianBlurElement.stdDeviationX')
  final AnimatedNumber stdDeviationX;

  @DocsEditable @DomName('SVGFEGaussianBlurElement.stdDeviationY')
  final AnimatedNumber stdDeviationY;

  @DocsEditable @DomName('SVGFEGaussianBlurElement.setStdDeviation')
  void setStdDeviation(num stdDeviationX, num stdDeviationY) native;

  // From SVGFilterPrimitiveStandardAttributes

  @DocsEditable @DomName('SVGFEGaussianBlurElement.height')
  final AnimatedLength height;

  @DocsEditable @DomName('SVGFEGaussianBlurElement.result')
  final AnimatedString result;

  @DocsEditable @DomName('SVGFEGaussianBlurElement.width')
  final AnimatedLength width;

  @DocsEditable @DomName('SVGFEGaussianBlurElement.x')
  final AnimatedLength x;

  @DocsEditable @DomName('SVGFEGaussianBlurElement.y')
  final AnimatedLength y;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DocsEditable @DomName('SVGFEGaussianBlurElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGFEImageElement')
class FEImageElement extends SvgElement implements FilterPrimitiveStandardAttributes, UriReference, ExternalResourcesRequired, LangSpace native "*SVGFEImageElement" {

  @DocsEditable @DomName('SVGFEImageElement.preserveAspectRatio')
  final AnimatedPreserveAspectRatio preserveAspectRatio;

  // From SVGExternalResourcesRequired

  @DocsEditable @DomName('SVGFEImageElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGFilterPrimitiveStandardAttributes

  @DocsEditable @DomName('SVGFEImageElement.height')
  final AnimatedLength height;

  @DocsEditable @DomName('SVGFEImageElement.result')
  final AnimatedString result;

  @DocsEditable @DomName('SVGFEImageElement.width')
  final AnimatedLength width;

  @DocsEditable @DomName('SVGFEImageElement.x')
  final AnimatedLength x;

  @DocsEditable @DomName('SVGFEImageElement.y')
  final AnimatedLength y;

  // From SVGLangSpace

  @DocsEditable @DomName('SVGFEImageElement.xmllang')
  String xmllang;

  @DocsEditable @DomName('SVGFEImageElement.xmlspace')
  String xmlspace;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DocsEditable @DomName('SVGFEImageElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;

  // From SVGURIReference

  @DocsEditable @DomName('SVGFEImageElement.href')
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGFEMergeElement')
class FEMergeElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEMergeElement" {

  // From SVGFilterPrimitiveStandardAttributes

  @DocsEditable @DomName('SVGFEMergeElement.height')
  final AnimatedLength height;

  @DocsEditable @DomName('SVGFEMergeElement.result')
  final AnimatedString result;

  @DocsEditable @DomName('SVGFEMergeElement.width')
  final AnimatedLength width;

  @DocsEditable @DomName('SVGFEMergeElement.x')
  final AnimatedLength x;

  @DocsEditable @DomName('SVGFEMergeElement.y')
  final AnimatedLength y;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DocsEditable @DomName('SVGFEMergeElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGFEMergeNodeElement')
class FEMergeNodeElement extends SvgElement native "*SVGFEMergeNodeElement" {

  @DocsEditable @DomName('SVGFEMergeNodeElement.in1')
  final AnimatedString in1;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGFEMorphologyElement')
class FEMorphologyElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEMorphologyElement" {

  static const int SVG_MORPHOLOGY_OPERATOR_DILATE = 2;

  static const int SVG_MORPHOLOGY_OPERATOR_ERODE = 1;

  static const int SVG_MORPHOLOGY_OPERATOR_UNKNOWN = 0;

  @DocsEditable @DomName('SVGFEMorphologyElement.in1')
  final AnimatedString in1;

  @DocsEditable @DomName('SVGFEMorphologyElement.operator')
  final AnimatedEnumeration operator;

  @DocsEditable @DomName('SVGFEMorphologyElement.radiusX')
  final AnimatedNumber radiusX;

  @DocsEditable @DomName('SVGFEMorphologyElement.radiusY')
  final AnimatedNumber radiusY;

  @DocsEditable @DomName('SVGFEMorphologyElement.setRadius')
  void setRadius(num radiusX, num radiusY) native;

  // From SVGFilterPrimitiveStandardAttributes

  @DocsEditable @DomName('SVGFEMorphologyElement.height')
  final AnimatedLength height;

  @DocsEditable @DomName('SVGFEMorphologyElement.result')
  final AnimatedString result;

  @DocsEditable @DomName('SVGFEMorphologyElement.width')
  final AnimatedLength width;

  @DocsEditable @DomName('SVGFEMorphologyElement.x')
  final AnimatedLength x;

  @DocsEditable @DomName('SVGFEMorphologyElement.y')
  final AnimatedLength y;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DocsEditable @DomName('SVGFEMorphologyElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGFEOffsetElement')
class FEOffsetElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEOffsetElement" {

  @DocsEditable @DomName('SVGFEOffsetElement.dx')
  final AnimatedNumber dx;

  @DocsEditable @DomName('SVGFEOffsetElement.dy')
  final AnimatedNumber dy;

  @DocsEditable @DomName('SVGFEOffsetElement.in1')
  final AnimatedString in1;

  // From SVGFilterPrimitiveStandardAttributes

  @DocsEditable @DomName('SVGFEOffsetElement.height')
  final AnimatedLength height;

  @DocsEditable @DomName('SVGFEOffsetElement.result')
  final AnimatedString result;

  @DocsEditable @DomName('SVGFEOffsetElement.width')
  final AnimatedLength width;

  @DocsEditable @DomName('SVGFEOffsetElement.x')
  final AnimatedLength x;

  @DocsEditable @DomName('SVGFEOffsetElement.y')
  final AnimatedLength y;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DocsEditable @DomName('SVGFEOffsetElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGFEPointLightElement')
class FEPointLightElement extends SvgElement native "*SVGFEPointLightElement" {

  @DocsEditable @DomName('SVGFEPointLightElement.x')
  final AnimatedNumber x;

  @DocsEditable @DomName('SVGFEPointLightElement.y')
  final AnimatedNumber y;

  @DocsEditable @DomName('SVGFEPointLightElement.z')
  final AnimatedNumber z;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGFESpecularLightingElement')
class FESpecularLightingElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFESpecularLightingElement" {

  @DocsEditable @DomName('SVGFESpecularLightingElement.in1')
  final AnimatedString in1;

  @DocsEditable @DomName('SVGFESpecularLightingElement.specularConstant')
  final AnimatedNumber specularConstant;

  @DocsEditable @DomName('SVGFESpecularLightingElement.specularExponent')
  final AnimatedNumber specularExponent;

  @DocsEditable @DomName('SVGFESpecularLightingElement.surfaceScale')
  final AnimatedNumber surfaceScale;

  // From SVGFilterPrimitiveStandardAttributes

  @DocsEditable @DomName('SVGFESpecularLightingElement.height')
  final AnimatedLength height;

  @DocsEditable @DomName('SVGFESpecularLightingElement.result')
  final AnimatedString result;

  @DocsEditable @DomName('SVGFESpecularLightingElement.width')
  final AnimatedLength width;

  @DocsEditable @DomName('SVGFESpecularLightingElement.x')
  final AnimatedLength x;

  @DocsEditable @DomName('SVGFESpecularLightingElement.y')
  final AnimatedLength y;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DocsEditable @DomName('SVGFESpecularLightingElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGFESpotLightElement')
class FESpotLightElement extends SvgElement native "*SVGFESpotLightElement" {

  @DocsEditable @DomName('SVGFESpotLightElement.limitingConeAngle')
  final AnimatedNumber limitingConeAngle;

  @DocsEditable @DomName('SVGFESpotLightElement.pointsAtX')
  final AnimatedNumber pointsAtX;

  @DocsEditable @DomName('SVGFESpotLightElement.pointsAtY')
  final AnimatedNumber pointsAtY;

  @DocsEditable @DomName('SVGFESpotLightElement.pointsAtZ')
  final AnimatedNumber pointsAtZ;

  @DocsEditable @DomName('SVGFESpotLightElement.specularExponent')
  final AnimatedNumber specularExponent;

  @DocsEditable @DomName('SVGFESpotLightElement.x')
  final AnimatedNumber x;

  @DocsEditable @DomName('SVGFESpotLightElement.y')
  final AnimatedNumber y;

  @DocsEditable @DomName('SVGFESpotLightElement.z')
  final AnimatedNumber z;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGFETileElement')
class FETileElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFETileElement" {

  @DocsEditable @DomName('SVGFETileElement.in1')
  final AnimatedString in1;

  // From SVGFilterPrimitiveStandardAttributes

  @DocsEditable @DomName('SVGFETileElement.height')
  final AnimatedLength height;

  @DocsEditable @DomName('SVGFETileElement.result')
  final AnimatedString result;

  @DocsEditable @DomName('SVGFETileElement.width')
  final AnimatedLength width;

  @DocsEditable @DomName('SVGFETileElement.x')
  final AnimatedLength x;

  @DocsEditable @DomName('SVGFETileElement.y')
  final AnimatedLength y;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DocsEditable @DomName('SVGFETileElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGFETurbulenceElement')
class FETurbulenceElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFETurbulenceElement" {

  static const int SVG_STITCHTYPE_NOSTITCH = 2;

  static const int SVG_STITCHTYPE_STITCH = 1;

  static const int SVG_STITCHTYPE_UNKNOWN = 0;

  static const int SVG_TURBULENCE_TYPE_FRACTALNOISE = 1;

  static const int SVG_TURBULENCE_TYPE_TURBULENCE = 2;

  static const int SVG_TURBULENCE_TYPE_UNKNOWN = 0;

  @DocsEditable @DomName('SVGFETurbulenceElement.baseFrequencyX')
  final AnimatedNumber baseFrequencyX;

  @DocsEditable @DomName('SVGFETurbulenceElement.baseFrequencyY')
  final AnimatedNumber baseFrequencyY;

  @DocsEditable @DomName('SVGFETurbulenceElement.numOctaves')
  final AnimatedInteger numOctaves;

  @DocsEditable @DomName('SVGFETurbulenceElement.seed')
  final AnimatedNumber seed;

  @DocsEditable @DomName('SVGFETurbulenceElement.stitchTiles')
  final AnimatedEnumeration stitchTiles;

  @DocsEditable @DomName('SVGFETurbulenceElement.type')
  final AnimatedEnumeration type;

  // From SVGFilterPrimitiveStandardAttributes

  @DocsEditable @DomName('SVGFETurbulenceElement.height')
  final AnimatedLength height;

  @DocsEditable @DomName('SVGFETurbulenceElement.result')
  final AnimatedString result;

  @DocsEditable @DomName('SVGFETurbulenceElement.width')
  final AnimatedLength width;

  @DocsEditable @DomName('SVGFETurbulenceElement.x')
  final AnimatedLength x;

  @DocsEditable @DomName('SVGFETurbulenceElement.y')
  final AnimatedLength y;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DocsEditable @DomName('SVGFETurbulenceElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGFilterElement')
class FilterElement extends SvgElement implements UriReference, ExternalResourcesRequired, Stylable, LangSpace native "*SVGFilterElement" {

  @DocsEditable
  factory FilterElement() => _SvgElementFactoryProvider.createSvgElement_tag("filter");

  @DocsEditable @DomName('SVGFilterElement.filterResX')
  final AnimatedInteger filterResX;

  @DocsEditable @DomName('SVGFilterElement.filterResY')
  final AnimatedInteger filterResY;

  @DocsEditable @DomName('SVGFilterElement.filterUnits')
  final AnimatedEnumeration filterUnits;

  @DocsEditable @DomName('SVGFilterElement.height')
  final AnimatedLength height;

  @DocsEditable @DomName('SVGFilterElement.primitiveUnits')
  final AnimatedEnumeration primitiveUnits;

  @DocsEditable @DomName('SVGFilterElement.width')
  final AnimatedLength width;

  @DocsEditable @DomName('SVGFilterElement.x')
  final AnimatedLength x;

  @DocsEditable @DomName('SVGFilterElement.y')
  final AnimatedLength y;

  @DocsEditable @DomName('SVGFilterElement.setFilterRes')
  void setFilterRes(int filterResX, int filterResY) native;

  // From SVGExternalResourcesRequired

  @DocsEditable @DomName('SVGFilterElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  @DocsEditable @DomName('SVGFilterElement.xmllang')
  String xmllang;

  @DocsEditable @DomName('SVGFilterElement.xmlspace')
  String xmlspace;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DocsEditable @DomName('SVGFilterElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;

  // From SVGURIReference

  @DocsEditable @DomName('SVGFilterElement.href')
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
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

  CssValue getPresentationAttribute(String name);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGFitToViewBox')
abstract class FitToViewBox {

  AnimatedPreserveAspectRatio preserveAspectRatio;

  AnimatedRect viewBox;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGFontElement')
class FontElement extends SvgElement native "*SVGFontElement" {

  @DocsEditable
  factory FontElement() => _SvgElementFactoryProvider.createSvgElement_tag("font");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGFontFaceElement')
class FontFaceElement extends SvgElement native "*SVGFontFaceElement" {

  @DocsEditable
  factory FontFaceElement() => _SvgElementFactoryProvider.createSvgElement_tag("font-face");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGFontFaceFormatElement')
class FontFaceFormatElement extends SvgElement native "*SVGFontFaceFormatElement" {

  @DocsEditable
  factory FontFaceFormatElement() => _SvgElementFactoryProvider.createSvgElement_tag("font-face-format");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGFontFaceNameElement')
class FontFaceNameElement extends SvgElement native "*SVGFontFaceNameElement" {

  @DocsEditable
  factory FontFaceNameElement() => _SvgElementFactoryProvider.createSvgElement_tag("font-face-name");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGFontFaceSrcElement')
class FontFaceSrcElement extends SvgElement native "*SVGFontFaceSrcElement" {

  @DocsEditable
  factory FontFaceSrcElement() => _SvgElementFactoryProvider.createSvgElement_tag("font-face-src");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGFontFaceUriElement')
class FontFaceUriElement extends SvgElement native "*SVGFontFaceUriElement" {

  @DocsEditable
  factory FontFaceUriElement() => _SvgElementFactoryProvider.createSvgElement_tag("font-face-uri");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGForeignObjectElement')
class ForeignObjectElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGForeignObjectElement" {

  @DocsEditable
  factory ForeignObjectElement() => _SvgElementFactoryProvider.createSvgElement_tag("foreignObject");

  @DocsEditable @DomName('SVGForeignObjectElement.height')
  final AnimatedLength height;

  @DocsEditable @DomName('SVGForeignObjectElement.width')
  final AnimatedLength width;

  @DocsEditable @DomName('SVGForeignObjectElement.x')
  final AnimatedLength x;

  @DocsEditable @DomName('SVGForeignObjectElement.y')
  final AnimatedLength y;

  // From SVGExternalResourcesRequired

  @DocsEditable @DomName('SVGForeignObjectElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  @DocsEditable @DomName('SVGForeignObjectElement.xmllang')
  String xmllang;

  @DocsEditable @DomName('SVGForeignObjectElement.xmlspace')
  String xmlspace;

  // From SVGLocatable

  @DocsEditable @DomName('SVGForeignObjectElement.farthestViewportElement')
  final SvgElement farthestViewportElement;

  @DocsEditable @DomName('SVGForeignObjectElement.nearestViewportElement')
  final SvgElement nearestViewportElement;

  @DocsEditable @DomName('SVGForeignObjectElement.getBBox')
  Rect getBBox() native;

  @JSName('getCTM')
  @DocsEditable @DomName('SVGForeignObjectElement.getCTM')
  Matrix getCtm() native;

  @JSName('getScreenCTM')
  @DocsEditable @DomName('SVGForeignObjectElement.getScreenCTM')
  Matrix getScreenCtm() native;

  @DocsEditable @DomName('SVGForeignObjectElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DocsEditable @DomName('SVGForeignObjectElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  @DocsEditable @DomName('SVGForeignObjectElement.requiredExtensions')
  final StringList requiredExtensions;

  @DocsEditable @DomName('SVGForeignObjectElement.requiredFeatures')
  final StringList requiredFeatures;

  @DocsEditable @DomName('SVGForeignObjectElement.systemLanguage')
  final StringList systemLanguage;

  @DocsEditable @DomName('SVGForeignObjectElement.hasExtension')
  bool hasExtension(String extension) native;

  // From SVGTransformable

  @DocsEditable @DomName('SVGForeignObjectElement.transform')
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGGElement')
class GElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGGElement" {

  @DocsEditable
  factory GElement() => _SvgElementFactoryProvider.createSvgElement_tag("g");

  // From SVGExternalResourcesRequired

  @DocsEditable @DomName('SVGGElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  @DocsEditable @DomName('SVGGElement.xmllang')
  String xmllang;

  @DocsEditable @DomName('SVGGElement.xmlspace')
  String xmlspace;

  // From SVGLocatable

  @DocsEditable @DomName('SVGGElement.farthestViewportElement')
  final SvgElement farthestViewportElement;

  @DocsEditable @DomName('SVGGElement.nearestViewportElement')
  final SvgElement nearestViewportElement;

  @DocsEditable @DomName('SVGGElement.getBBox')
  Rect getBBox() native;

  @JSName('getCTM')
  @DocsEditable @DomName('SVGGElement.getCTM')
  Matrix getCtm() native;

  @JSName('getScreenCTM')
  @DocsEditable @DomName('SVGGElement.getScreenCTM')
  Matrix getScreenCtm() native;

  @DocsEditable @DomName('SVGGElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DocsEditable @DomName('SVGGElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  @DocsEditable @DomName('SVGGElement.requiredExtensions')
  final StringList requiredExtensions;

  @DocsEditable @DomName('SVGGElement.requiredFeatures')
  final StringList requiredFeatures;

  @DocsEditable @DomName('SVGGElement.systemLanguage')
  final StringList systemLanguage;

  @DocsEditable @DomName('SVGGElement.hasExtension')
  bool hasExtension(String extension) native;

  // From SVGTransformable

  @DocsEditable @DomName('SVGGElement.transform')
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGGlyphElement')
class GlyphElement extends SvgElement native "*SVGGlyphElement" {

  @DocsEditable
  factory GlyphElement() => _SvgElementFactoryProvider.createSvgElement_tag("glyph");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGGlyphRefElement')
class GlyphRefElement extends SvgElement implements UriReference, Stylable native "*SVGGlyphRefElement" {

  @DocsEditable @DomName('SVGGlyphRefElement.dx')
  num dx;

  @DocsEditable @DomName('SVGGlyphRefElement.dy')
  num dy;

  @DocsEditable @DomName('SVGGlyphRefElement.format')
  String format;

  @DocsEditable @DomName('SVGGlyphRefElement.glyphRef')
  String glyphRef;

  @DocsEditable @DomName('SVGGlyphRefElement.x')
  num x;

  @DocsEditable @DomName('SVGGlyphRefElement.y')
  num y;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DocsEditable @DomName('SVGGlyphRefElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;

  // From SVGURIReference

  @DocsEditable @DomName('SVGGlyphRefElement.href')
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGGradientElement')
class GradientElement extends SvgElement implements UriReference, ExternalResourcesRequired, Stylable native "*SVGGradientElement" {

  static const int SVG_SPREADMETHOD_PAD = 1;

  static const int SVG_SPREADMETHOD_REFLECT = 2;

  static const int SVG_SPREADMETHOD_REPEAT = 3;

  static const int SVG_SPREADMETHOD_UNKNOWN = 0;

  @DocsEditable @DomName('SVGGradientElement.gradientTransform')
  final AnimatedTransformList gradientTransform;

  @DocsEditable @DomName('SVGGradientElement.gradientUnits')
  final AnimatedEnumeration gradientUnits;

  @DocsEditable @DomName('SVGGradientElement.spreadMethod')
  final AnimatedEnumeration spreadMethod;

  // From SVGExternalResourcesRequired

  @DocsEditable @DomName('SVGGradientElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DocsEditable @DomName('SVGGradientElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;

  // From SVGURIReference

  @DocsEditable @DomName('SVGGradientElement.href')
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGHKernElement')
class HKernElement extends SvgElement native "*SVGHKernElement" {

  @DocsEditable
  factory HKernElement() => _SvgElementFactoryProvider.createSvgElement_tag("hkern");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGImageElement')
class ImageElement extends SvgElement implements Transformable, Tests, UriReference, Stylable, ExternalResourcesRequired, LangSpace native "*SVGImageElement" {

  @DocsEditable
  factory ImageElement() => _SvgElementFactoryProvider.createSvgElement_tag("image");

  @DocsEditable @DomName('SVGImageElement.height')
  final AnimatedLength height;

  @DocsEditable @DomName('SVGImageElement.preserveAspectRatio')
  final AnimatedPreserveAspectRatio preserveAspectRatio;

  @DocsEditable @DomName('SVGImageElement.width')
  final AnimatedLength width;

  @DocsEditable @DomName('SVGImageElement.x')
  final AnimatedLength x;

  @DocsEditable @DomName('SVGImageElement.y')
  final AnimatedLength y;

  // From SVGExternalResourcesRequired

  @DocsEditable @DomName('SVGImageElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  @DocsEditable @DomName('SVGImageElement.xmllang')
  String xmllang;

  @DocsEditable @DomName('SVGImageElement.xmlspace')
  String xmlspace;

  // From SVGLocatable

  @DocsEditable @DomName('SVGImageElement.farthestViewportElement')
  final SvgElement farthestViewportElement;

  @DocsEditable @DomName('SVGImageElement.nearestViewportElement')
  final SvgElement nearestViewportElement;

  @DocsEditable @DomName('SVGImageElement.getBBox')
  Rect getBBox() native;

  @JSName('getCTM')
  @DocsEditable @DomName('SVGImageElement.getCTM')
  Matrix getCtm() native;

  @JSName('getScreenCTM')
  @DocsEditable @DomName('SVGImageElement.getScreenCTM')
  Matrix getScreenCtm() native;

  @DocsEditable @DomName('SVGImageElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DocsEditable @DomName('SVGImageElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  @DocsEditable @DomName('SVGImageElement.requiredExtensions')
  final StringList requiredExtensions;

  @DocsEditable @DomName('SVGImageElement.requiredFeatures')
  final StringList requiredFeatures;

  @DocsEditable @DomName('SVGImageElement.systemLanguage')
  final StringList systemLanguage;

  @DocsEditable @DomName('SVGImageElement.hasExtension')
  bool hasExtension(String extension) native;

  // From SVGTransformable

  @DocsEditable @DomName('SVGImageElement.transform')
  final AnimatedTransformList transform;

  // From SVGURIReference

  @DocsEditable @DomName('SVGImageElement.href')
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGLangSpace')
abstract class LangSpace {

  String xmllang;

  String xmlspace;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
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

  @DocsEditable @DomName('SVGLength.unitType')
  final int unitType;

  @DocsEditable @DomName('SVGLength.value')
  num value;

  @DocsEditable @DomName('SVGLength.valueAsString')
  String valueAsString;

  @DocsEditable @DomName('SVGLength.valueInSpecifiedUnits')
  num valueInSpecifiedUnits;

  @DocsEditable @DomName('SVGLength.convertToSpecifiedUnits')
  void convertToSpecifiedUnits(int unitType) native;

  @DocsEditable @DomName('SVGLength.newValueSpecifiedUnits')
  void newValueSpecifiedUnits(int unitType, num valueInSpecifiedUnits) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGLengthList')
class LengthList implements JavaScriptIndexingBehavior, List<Length> native "*SVGLengthList" {

  @DocsEditable @DomName('SVGLengthList.numberOfItems')
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
    return IterableMixinWorkaround.reduce(this, initialValue, combine);
  }

  bool contains(Length element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(Length element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator]) => IterableMixinWorkaround.joinList(this, separator);

  List mappedBy(f(Length element)) => IterableMixinWorkaround.mappedByList(this, f);

  Iterable<Length> where(bool f(Length element)) => IterableMixinWorkaround.where(this, f);

  bool every(bool f(Length element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(Length element)) => IterableMixinWorkaround.any(this, f);

  List<Length> toList() => new List<Length>.from(this);
  Set<Length> toSet() => new Set<Length>.from(this);

  bool get isEmpty => this.length == 0;

  List<Length> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<Length> takeWhile(bool test(Length value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  List<Length> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<Length> skipWhile(bool test(Length value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  Length firstMatching(bool test(Length value), { Length orElse() }) {
    return IterableMixinWorkaround.firstMatching(this, test, orElse);
  }

  Length lastMatching(bool test(Length value), {Length orElse()}) {
    return IterableMixinWorkaround.lastMatchingInList(this, test, orElse);
  }

  Length singleMatching(bool test(Length value)) {
    return IterableMixinWorkaround.singleMatching(this, test);
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

  // clear() defined by IDL.

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

  Length min([int compare(Length a, Length b)]) => IterableMixinWorkaround.min(this, compare);

  Length max([int compare(Length a, Length b)]) => IterableMixinWorkaround.max(this, compare);

  Length removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  Length removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeMatching(bool test(Length element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainMatching(bool test(Length element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
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

  @DocsEditable @DomName('SVGLengthList.appendItem')
  Length appendItem(Length item) native;

  @DocsEditable @DomName('SVGLengthList.clear')
  void clear() native;

  @DocsEditable @DomName('SVGLengthList.getItem')
  Length getItem(int index) native;

  @DocsEditable @DomName('SVGLengthList.initialize')
  Length initialize(Length item) native;

  @DocsEditable @DomName('SVGLengthList.insertItemBefore')
  Length insertItemBefore(Length item, int index) native;

  @DocsEditable @DomName('SVGLengthList.removeItem')
  Length removeItem(int index) native;

  @DocsEditable @DomName('SVGLengthList.replaceItem')
  Length replaceItem(Length item, int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGLineElement')
class LineElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGLineElement" {

  @DocsEditable
  factory LineElement() => _SvgElementFactoryProvider.createSvgElement_tag("line");

  @DocsEditable @DomName('SVGLineElement.x1')
  final AnimatedLength x1;

  @DocsEditable @DomName('SVGLineElement.x2')
  final AnimatedLength x2;

  @DocsEditable @DomName('SVGLineElement.y1')
  final AnimatedLength y1;

  @DocsEditable @DomName('SVGLineElement.y2')
  final AnimatedLength y2;

  // From SVGExternalResourcesRequired

  @DocsEditable @DomName('SVGLineElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  @DocsEditable @DomName('SVGLineElement.xmllang')
  String xmllang;

  @DocsEditable @DomName('SVGLineElement.xmlspace')
  String xmlspace;

  // From SVGLocatable

  @DocsEditable @DomName('SVGLineElement.farthestViewportElement')
  final SvgElement farthestViewportElement;

  @DocsEditable @DomName('SVGLineElement.nearestViewportElement')
  final SvgElement nearestViewportElement;

  @DocsEditable @DomName('SVGLineElement.getBBox')
  Rect getBBox() native;

  @JSName('getCTM')
  @DocsEditable @DomName('SVGLineElement.getCTM')
  Matrix getCtm() native;

  @JSName('getScreenCTM')
  @DocsEditable @DomName('SVGLineElement.getScreenCTM')
  Matrix getScreenCtm() native;

  @DocsEditable @DomName('SVGLineElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DocsEditable @DomName('SVGLineElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  @DocsEditable @DomName('SVGLineElement.requiredExtensions')
  final StringList requiredExtensions;

  @DocsEditable @DomName('SVGLineElement.requiredFeatures')
  final StringList requiredFeatures;

  @DocsEditable @DomName('SVGLineElement.systemLanguage')
  final StringList systemLanguage;

  @DocsEditable @DomName('SVGLineElement.hasExtension')
  bool hasExtension(String extension) native;

  // From SVGTransformable

  @DocsEditable @DomName('SVGLineElement.transform')
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGLinearGradientElement')
class LinearGradientElement extends GradientElement native "*SVGLinearGradientElement" {

  @DocsEditable
  factory LinearGradientElement() => _SvgElementFactoryProvider.createSvgElement_tag("linearGradient");

  @DocsEditable @DomName('SVGLinearGradientElement.x1')
  final AnimatedLength x1;

  @DocsEditable @DomName('SVGLinearGradientElement.x2')
  final AnimatedLength x2;

  @DocsEditable @DomName('SVGLinearGradientElement.y1')
  final AnimatedLength y1;

  @DocsEditable @DomName('SVGLinearGradientElement.y2')
  final AnimatedLength y2;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGLocatable')
abstract class Locatable {

  SvgElement farthestViewportElement;

  SvgElement nearestViewportElement;

  Rect getBBox();

  Matrix getCTM();

  Matrix getScreenCTM();

  Matrix getTransformToElement(SvgElement element);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGMPathElement')
class MPathElement extends SvgElement implements UriReference, ExternalResourcesRequired native "*SVGMPathElement" {

  @DocsEditable
  factory MPathElement() => _SvgElementFactoryProvider.createSvgElement_tag("mpath");

  // From SVGExternalResourcesRequired

  @DocsEditable @DomName('SVGMPathElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGURIReference

  @DocsEditable @DomName('SVGMPathElement.href')
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGMarkerElement')
class MarkerElement extends SvgElement implements FitToViewBox, ExternalResourcesRequired, Stylable, LangSpace native "*SVGMarkerElement" {

  @DocsEditable
  factory MarkerElement() => _SvgElementFactoryProvider.createSvgElement_tag("marker");

  static const int SVG_MARKERUNITS_STROKEWIDTH = 2;

  static const int SVG_MARKERUNITS_UNKNOWN = 0;

  static const int SVG_MARKERUNITS_USERSPACEONUSE = 1;

  static const int SVG_MARKER_ORIENT_ANGLE = 2;

  static const int SVG_MARKER_ORIENT_AUTO = 1;

  static const int SVG_MARKER_ORIENT_UNKNOWN = 0;

  @DocsEditable @DomName('SVGMarkerElement.markerHeight')
  final AnimatedLength markerHeight;

  @DocsEditable @DomName('SVGMarkerElement.markerUnits')
  final AnimatedEnumeration markerUnits;

  @DocsEditable @DomName('SVGMarkerElement.markerWidth')
  final AnimatedLength markerWidth;

  @DocsEditable @DomName('SVGMarkerElement.orientAngle')
  final AnimatedAngle orientAngle;

  @DocsEditable @DomName('SVGMarkerElement.orientType')
  final AnimatedEnumeration orientType;

  @DocsEditable @DomName('SVGMarkerElement.refX')
  final AnimatedLength refX;

  @DocsEditable @DomName('SVGMarkerElement.refY')
  final AnimatedLength refY;

  @DocsEditable @DomName('SVGMarkerElement.setOrientToAngle')
  void setOrientToAngle(Angle angle) native;

  @DocsEditable @DomName('SVGMarkerElement.setOrientToAuto')
  void setOrientToAuto() native;

  // From SVGExternalResourcesRequired

  @DocsEditable @DomName('SVGMarkerElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGFitToViewBox

  @DocsEditable @DomName('SVGMarkerElement.preserveAspectRatio')
  final AnimatedPreserveAspectRatio preserveAspectRatio;

  @DocsEditable @DomName('SVGMarkerElement.viewBox')
  final AnimatedRect viewBox;

  // From SVGLangSpace

  @DocsEditable @DomName('SVGMarkerElement.xmllang')
  String xmllang;

  @DocsEditable @DomName('SVGMarkerElement.xmlspace')
  String xmlspace;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DocsEditable @DomName('SVGMarkerElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGMaskElement')
class MaskElement extends SvgElement implements Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGMaskElement" {

  @DocsEditable
  factory MaskElement() => _SvgElementFactoryProvider.createSvgElement_tag("mask");

  @DocsEditable @DomName('SVGMaskElement.height')
  final AnimatedLength height;

  @DocsEditable @DomName('SVGMaskElement.maskContentUnits')
  final AnimatedEnumeration maskContentUnits;

  @DocsEditable @DomName('SVGMaskElement.maskUnits')
  final AnimatedEnumeration maskUnits;

  @DocsEditable @DomName('SVGMaskElement.width')
  final AnimatedLength width;

  @DocsEditable @DomName('SVGMaskElement.x')
  final AnimatedLength x;

  @DocsEditable @DomName('SVGMaskElement.y')
  final AnimatedLength y;

  // From SVGExternalResourcesRequired

  @DocsEditable @DomName('SVGMaskElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  @DocsEditable @DomName('SVGMaskElement.xmllang')
  String xmllang;

  @DocsEditable @DomName('SVGMaskElement.xmlspace')
  String xmlspace;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DocsEditable @DomName('SVGMaskElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  @DocsEditable @DomName('SVGMaskElement.requiredExtensions')
  final StringList requiredExtensions;

  @DocsEditable @DomName('SVGMaskElement.requiredFeatures')
  final StringList requiredFeatures;

  @DocsEditable @DomName('SVGMaskElement.systemLanguage')
  final StringList systemLanguage;

  @DocsEditable @DomName('SVGMaskElement.hasExtension')
  bool hasExtension(String extension) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGMatrix')
class Matrix native "*SVGMatrix" {

  @DocsEditable @DomName('SVGMatrix.a')
  num a;

  @DocsEditable @DomName('SVGMatrix.b')
  num b;

  @DocsEditable @DomName('SVGMatrix.c')
  num c;

  @DocsEditable @DomName('SVGMatrix.d')
  num d;

  @DocsEditable @DomName('SVGMatrix.e')
  num e;

  @DocsEditable @DomName('SVGMatrix.f')
  num f;

  @DocsEditable @DomName('SVGMatrix.flipX')
  Matrix flipX() native;

  @DocsEditable @DomName('SVGMatrix.flipY')
  Matrix flipY() native;

  @DocsEditable @DomName('SVGMatrix.inverse')
  Matrix inverse() native;

  @DocsEditable @DomName('SVGMatrix.multiply')
  Matrix multiply(Matrix secondMatrix) native;

  @DocsEditable @DomName('SVGMatrix.rotate')
  Matrix rotate(num angle) native;

  @DocsEditable @DomName('SVGMatrix.rotateFromVector')
  Matrix rotateFromVector(num x, num y) native;

  @DocsEditable @DomName('SVGMatrix.scale')
  Matrix scale(num scaleFactor) native;

  @DocsEditable @DomName('SVGMatrix.scaleNonUniform')
  Matrix scaleNonUniform(num scaleFactorX, num scaleFactorY) native;

  @DocsEditable @DomName('SVGMatrix.skewX')
  Matrix skewX(num angle) native;

  @DocsEditable @DomName('SVGMatrix.skewY')
  Matrix skewY(num angle) native;

  @DocsEditable @DomName('SVGMatrix.translate')
  Matrix translate(num x, num y) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGMetadataElement')
class MetadataElement extends SvgElement native "*SVGMetadataElement" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGMissingGlyphElement')
class MissingGlyphElement extends SvgElement native "*SVGMissingGlyphElement" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGNumber')
class Number native "*SVGNumber" {

  @DocsEditable @DomName('SVGNumber.value')
  num value;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGNumberList')
class NumberList implements JavaScriptIndexingBehavior, List<Number> native "*SVGNumberList" {

  @DocsEditable @DomName('SVGNumberList.numberOfItems')
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
    return IterableMixinWorkaround.reduce(this, initialValue, combine);
  }

  bool contains(Number element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(Number element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator]) => IterableMixinWorkaround.joinList(this, separator);

  List mappedBy(f(Number element)) => IterableMixinWorkaround.mappedByList(this, f);

  Iterable<Number> where(bool f(Number element)) => IterableMixinWorkaround.where(this, f);

  bool every(bool f(Number element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(Number element)) => IterableMixinWorkaround.any(this, f);

  List<Number> toList() => new List<Number>.from(this);
  Set<Number> toSet() => new Set<Number>.from(this);

  bool get isEmpty => this.length == 0;

  List<Number> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<Number> takeWhile(bool test(Number value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  List<Number> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<Number> skipWhile(bool test(Number value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  Number firstMatching(bool test(Number value), { Number orElse() }) {
    return IterableMixinWorkaround.firstMatching(this, test, orElse);
  }

  Number lastMatching(bool test(Number value), {Number orElse()}) {
    return IterableMixinWorkaround.lastMatchingInList(this, test, orElse);
  }

  Number singleMatching(bool test(Number value)) {
    return IterableMixinWorkaround.singleMatching(this, test);
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

  // clear() defined by IDL.

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

  Number min([int compare(Number a, Number b)]) => IterableMixinWorkaround.min(this, compare);

  Number max([int compare(Number a, Number b)]) => IterableMixinWorkaround.max(this, compare);

  Number removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  Number removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeMatching(bool test(Number element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainMatching(bool test(Number element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
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

  @DocsEditable @DomName('SVGNumberList.appendItem')
  Number appendItem(Number item) native;

  @DocsEditable @DomName('SVGNumberList.clear')
  void clear() native;

  @DocsEditable @DomName('SVGNumberList.getItem')
  Number getItem(int index) native;

  @DocsEditable @DomName('SVGNumberList.initialize')
  Number initialize(Number item) native;

  @DocsEditable @DomName('SVGNumberList.insertItemBefore')
  Number insertItemBefore(Number item, int index) native;

  @DocsEditable @DomName('SVGNumberList.removeItem')
  Number removeItem(int index) native;

  @DocsEditable @DomName('SVGNumberList.replaceItem')
  Number replaceItem(Number item, int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
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

  @DocsEditable @DomName('SVGPaint.paintType')
  final int paintType;

  @DocsEditable @DomName('SVGPaint.uri')
  final String uri;

  @DocsEditable @DomName('SVGPaint.setPaint')
  void setPaint(int paintType, String uri, String rgbColor, String iccColor) native;

  @DocsEditable @DomName('SVGPaint.setUri')
  void setUri(String uri) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGPathElement')
class PathElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGPathElement" {

  @DocsEditable
  factory PathElement() => _SvgElementFactoryProvider.createSvgElement_tag("path");

  @DocsEditable @DomName('SVGPathElement.animatedNormalizedPathSegList')
  final PathSegList animatedNormalizedPathSegList;

  @DocsEditable @DomName('SVGPathElement.animatedPathSegList')
  final PathSegList animatedPathSegList;

  @DocsEditable @DomName('SVGPathElement.normalizedPathSegList')
  final PathSegList normalizedPathSegList;

  @DocsEditable @DomName('SVGPathElement.pathLength')
  final AnimatedNumber pathLength;

  @DocsEditable @DomName('SVGPathElement.pathSegList')
  final PathSegList pathSegList;

  @JSName('createSVGPathSegArcAbs')
  @DocsEditable @DomName('SVGPathElement.createSVGPathSegArcAbs')
  PathSegArcAbs createSvgPathSegArcAbs(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) native;

  @JSName('createSVGPathSegArcRel')
  @DocsEditable @DomName('SVGPathElement.createSVGPathSegArcRel')
  PathSegArcRel createSvgPathSegArcRel(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) native;

  @JSName('createSVGPathSegClosePath')
  @DocsEditable @DomName('SVGPathElement.createSVGPathSegClosePath')
  PathSegClosePath createSvgPathSegClosePath() native;

  @JSName('createSVGPathSegCurvetoCubicAbs')
  @DocsEditable @DomName('SVGPathElement.createSVGPathSegCurvetoCubicAbs')
  PathSegCurvetoCubicAbs createSvgPathSegCurvetoCubicAbs(num x, num y, num x1, num y1, num x2, num y2) native;

  @JSName('createSVGPathSegCurvetoCubicRel')
  @DocsEditable @DomName('SVGPathElement.createSVGPathSegCurvetoCubicRel')
  PathSegCurvetoCubicRel createSvgPathSegCurvetoCubicRel(num x, num y, num x1, num y1, num x2, num y2) native;

  @JSName('createSVGPathSegCurvetoCubicSmoothAbs')
  @DocsEditable @DomName('SVGPathElement.createSVGPathSegCurvetoCubicSmoothAbs')
  PathSegCurvetoCubicSmoothAbs createSvgPathSegCurvetoCubicSmoothAbs(num x, num y, num x2, num y2) native;

  @JSName('createSVGPathSegCurvetoCubicSmoothRel')
  @DocsEditable @DomName('SVGPathElement.createSVGPathSegCurvetoCubicSmoothRel')
  PathSegCurvetoCubicSmoothRel createSvgPathSegCurvetoCubicSmoothRel(num x, num y, num x2, num y2) native;

  @JSName('createSVGPathSegCurvetoQuadraticAbs')
  @DocsEditable @DomName('SVGPathElement.createSVGPathSegCurvetoQuadraticAbs')
  PathSegCurvetoQuadraticAbs createSvgPathSegCurvetoQuadraticAbs(num x, num y, num x1, num y1) native;

  @JSName('createSVGPathSegCurvetoQuadraticRel')
  @DocsEditable @DomName('SVGPathElement.createSVGPathSegCurvetoQuadraticRel')
  PathSegCurvetoQuadraticRel createSvgPathSegCurvetoQuadraticRel(num x, num y, num x1, num y1) native;

  @JSName('createSVGPathSegCurvetoQuadraticSmoothAbs')
  @DocsEditable @DomName('SVGPathElement.createSVGPathSegCurvetoQuadraticSmoothAbs')
  PathSegCurvetoQuadraticSmoothAbs createSvgPathSegCurvetoQuadraticSmoothAbs(num x, num y) native;

  @JSName('createSVGPathSegCurvetoQuadraticSmoothRel')
  @DocsEditable @DomName('SVGPathElement.createSVGPathSegCurvetoQuadraticSmoothRel')
  PathSegCurvetoQuadraticSmoothRel createSvgPathSegCurvetoQuadraticSmoothRel(num x, num y) native;

  @JSName('createSVGPathSegLinetoAbs')
  @DocsEditable @DomName('SVGPathElement.createSVGPathSegLinetoAbs')
  PathSegLinetoAbs createSvgPathSegLinetoAbs(num x, num y) native;

  @JSName('createSVGPathSegLinetoHorizontalAbs')
  @DocsEditable @DomName('SVGPathElement.createSVGPathSegLinetoHorizontalAbs')
  PathSegLinetoHorizontalAbs createSvgPathSegLinetoHorizontalAbs(num x) native;

  @JSName('createSVGPathSegLinetoHorizontalRel')
  @DocsEditable @DomName('SVGPathElement.createSVGPathSegLinetoHorizontalRel')
  PathSegLinetoHorizontalRel createSvgPathSegLinetoHorizontalRel(num x) native;

  @JSName('createSVGPathSegLinetoRel')
  @DocsEditable @DomName('SVGPathElement.createSVGPathSegLinetoRel')
  PathSegLinetoRel createSvgPathSegLinetoRel(num x, num y) native;

  @JSName('createSVGPathSegLinetoVerticalAbs')
  @DocsEditable @DomName('SVGPathElement.createSVGPathSegLinetoVerticalAbs')
  PathSegLinetoVerticalAbs createSvgPathSegLinetoVerticalAbs(num y) native;

  @JSName('createSVGPathSegLinetoVerticalRel')
  @DocsEditable @DomName('SVGPathElement.createSVGPathSegLinetoVerticalRel')
  PathSegLinetoVerticalRel createSvgPathSegLinetoVerticalRel(num y) native;

  @JSName('createSVGPathSegMovetoAbs')
  @DocsEditable @DomName('SVGPathElement.createSVGPathSegMovetoAbs')
  PathSegMovetoAbs createSvgPathSegMovetoAbs(num x, num y) native;

  @JSName('createSVGPathSegMovetoRel')
  @DocsEditable @DomName('SVGPathElement.createSVGPathSegMovetoRel')
  PathSegMovetoRel createSvgPathSegMovetoRel(num x, num y) native;

  @DocsEditable @DomName('SVGPathElement.getPathSegAtLength')
  int getPathSegAtLength(num distance) native;

  @DocsEditable @DomName('SVGPathElement.getPointAtLength')
  Point getPointAtLength(num distance) native;

  @DocsEditable @DomName('SVGPathElement.getTotalLength')
  num getTotalLength() native;

  // From SVGExternalResourcesRequired

  @DocsEditable @DomName('SVGPathElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  @DocsEditable @DomName('SVGPathElement.xmllang')
  String xmllang;

  @DocsEditable @DomName('SVGPathElement.xmlspace')
  String xmlspace;

  // From SVGLocatable

  @DocsEditable @DomName('SVGPathElement.farthestViewportElement')
  final SvgElement farthestViewportElement;

  @DocsEditable @DomName('SVGPathElement.nearestViewportElement')
  final SvgElement nearestViewportElement;

  @DocsEditable @DomName('SVGPathElement.getBBox')
  Rect getBBox() native;

  @JSName('getCTM')
  @DocsEditable @DomName('SVGPathElement.getCTM')
  Matrix getCtm() native;

  @JSName('getScreenCTM')
  @DocsEditable @DomName('SVGPathElement.getScreenCTM')
  Matrix getScreenCtm() native;

  @DocsEditable @DomName('SVGPathElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DocsEditable @DomName('SVGPathElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  @DocsEditable @DomName('SVGPathElement.requiredExtensions')
  final StringList requiredExtensions;

  @DocsEditable @DomName('SVGPathElement.requiredFeatures')
  final StringList requiredFeatures;

  @DocsEditable @DomName('SVGPathElement.systemLanguage')
  final StringList systemLanguage;

  @DocsEditable @DomName('SVGPathElement.hasExtension')
  bool hasExtension(String extension) native;

  // From SVGTransformable

  @DocsEditable @DomName('SVGPathElement.transform')
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
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

  @DocsEditable @DomName('SVGPathSeg.pathSegType')
  final int pathSegType;

  @DocsEditable @DomName('SVGPathSeg.pathSegTypeAsLetter')
  final String pathSegTypeAsLetter;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGPathSegArcAbs')
class PathSegArcAbs extends PathSeg native "*SVGPathSegArcAbs" {

  @DocsEditable @DomName('SVGPathSegArcAbs.angle')
  num angle;

  @DocsEditable @DomName('SVGPathSegArcAbs.largeArcFlag')
  bool largeArcFlag;

  @DocsEditable @DomName('SVGPathSegArcAbs.r1')
  num r1;

  @DocsEditable @DomName('SVGPathSegArcAbs.r2')
  num r2;

  @DocsEditable @DomName('SVGPathSegArcAbs.sweepFlag')
  bool sweepFlag;

  @DocsEditable @DomName('SVGPathSegArcAbs.x')
  num x;

  @DocsEditable @DomName('SVGPathSegArcAbs.y')
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGPathSegArcRel')
class PathSegArcRel extends PathSeg native "*SVGPathSegArcRel" {

  @DocsEditable @DomName('SVGPathSegArcRel.angle')
  num angle;

  @DocsEditable @DomName('SVGPathSegArcRel.largeArcFlag')
  bool largeArcFlag;

  @DocsEditable @DomName('SVGPathSegArcRel.r1')
  num r1;

  @DocsEditable @DomName('SVGPathSegArcRel.r2')
  num r2;

  @DocsEditable @DomName('SVGPathSegArcRel.sweepFlag')
  bool sweepFlag;

  @DocsEditable @DomName('SVGPathSegArcRel.x')
  num x;

  @DocsEditable @DomName('SVGPathSegArcRel.y')
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGPathSegClosePath')
class PathSegClosePath extends PathSeg native "*SVGPathSegClosePath" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGPathSegCurvetoCubicAbs')
class PathSegCurvetoCubicAbs extends PathSeg native "*SVGPathSegCurvetoCubicAbs" {

  @DocsEditable @DomName('SVGPathSegCurvetoCubicAbs.x')
  num x;

  @DocsEditable @DomName('SVGPathSegCurvetoCubicAbs.x1')
  num x1;

  @DocsEditable @DomName('SVGPathSegCurvetoCubicAbs.x2')
  num x2;

  @DocsEditable @DomName('SVGPathSegCurvetoCubicAbs.y')
  num y;

  @DocsEditable @DomName('SVGPathSegCurvetoCubicAbs.y1')
  num y1;

  @DocsEditable @DomName('SVGPathSegCurvetoCubicAbs.y2')
  num y2;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGPathSegCurvetoCubicRel')
class PathSegCurvetoCubicRel extends PathSeg native "*SVGPathSegCurvetoCubicRel" {

  @DocsEditable @DomName('SVGPathSegCurvetoCubicRel.x')
  num x;

  @DocsEditable @DomName('SVGPathSegCurvetoCubicRel.x1')
  num x1;

  @DocsEditable @DomName('SVGPathSegCurvetoCubicRel.x2')
  num x2;

  @DocsEditable @DomName('SVGPathSegCurvetoCubicRel.y')
  num y;

  @DocsEditable @DomName('SVGPathSegCurvetoCubicRel.y1')
  num y1;

  @DocsEditable @DomName('SVGPathSegCurvetoCubicRel.y2')
  num y2;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGPathSegCurvetoCubicSmoothAbs')
class PathSegCurvetoCubicSmoothAbs extends PathSeg native "*SVGPathSegCurvetoCubicSmoothAbs" {

  @DocsEditable @DomName('SVGPathSegCurvetoCubicSmoothAbs.x')
  num x;

  @DocsEditable @DomName('SVGPathSegCurvetoCubicSmoothAbs.x2')
  num x2;

  @DocsEditable @DomName('SVGPathSegCurvetoCubicSmoothAbs.y')
  num y;

  @DocsEditable @DomName('SVGPathSegCurvetoCubicSmoothAbs.y2')
  num y2;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGPathSegCurvetoCubicSmoothRel')
class PathSegCurvetoCubicSmoothRel extends PathSeg native "*SVGPathSegCurvetoCubicSmoothRel" {

  @DocsEditable @DomName('SVGPathSegCurvetoCubicSmoothRel.x')
  num x;

  @DocsEditable @DomName('SVGPathSegCurvetoCubicSmoothRel.x2')
  num x2;

  @DocsEditable @DomName('SVGPathSegCurvetoCubicSmoothRel.y')
  num y;

  @DocsEditable @DomName('SVGPathSegCurvetoCubicSmoothRel.y2')
  num y2;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGPathSegCurvetoQuadraticAbs')
class PathSegCurvetoQuadraticAbs extends PathSeg native "*SVGPathSegCurvetoQuadraticAbs" {

  @DocsEditable @DomName('SVGPathSegCurvetoQuadraticAbs.x')
  num x;

  @DocsEditable @DomName('SVGPathSegCurvetoQuadraticAbs.x1')
  num x1;

  @DocsEditable @DomName('SVGPathSegCurvetoQuadraticAbs.y')
  num y;

  @DocsEditable @DomName('SVGPathSegCurvetoQuadraticAbs.y1')
  num y1;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGPathSegCurvetoQuadraticRel')
class PathSegCurvetoQuadraticRel extends PathSeg native "*SVGPathSegCurvetoQuadraticRel" {

  @DocsEditable @DomName('SVGPathSegCurvetoQuadraticRel.x')
  num x;

  @DocsEditable @DomName('SVGPathSegCurvetoQuadraticRel.x1')
  num x1;

  @DocsEditable @DomName('SVGPathSegCurvetoQuadraticRel.y')
  num y;

  @DocsEditable @DomName('SVGPathSegCurvetoQuadraticRel.y1')
  num y1;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGPathSegCurvetoQuadraticSmoothAbs')
class PathSegCurvetoQuadraticSmoothAbs extends PathSeg native "*SVGPathSegCurvetoQuadraticSmoothAbs" {

  @DocsEditable @DomName('SVGPathSegCurvetoQuadraticSmoothAbs.x')
  num x;

  @DocsEditable @DomName('SVGPathSegCurvetoQuadraticSmoothAbs.y')
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGPathSegCurvetoQuadraticSmoothRel')
class PathSegCurvetoQuadraticSmoothRel extends PathSeg native "*SVGPathSegCurvetoQuadraticSmoothRel" {

  @DocsEditable @DomName('SVGPathSegCurvetoQuadraticSmoothRel.x')
  num x;

  @DocsEditable @DomName('SVGPathSegCurvetoQuadraticSmoothRel.y')
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGPathSegLinetoAbs')
class PathSegLinetoAbs extends PathSeg native "*SVGPathSegLinetoAbs" {

  @DocsEditable @DomName('SVGPathSegLinetoAbs.x')
  num x;

  @DocsEditable @DomName('SVGPathSegLinetoAbs.y')
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGPathSegLinetoHorizontalAbs')
class PathSegLinetoHorizontalAbs extends PathSeg native "*SVGPathSegLinetoHorizontalAbs" {

  @DocsEditable @DomName('SVGPathSegLinetoHorizontalAbs.x')
  num x;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGPathSegLinetoHorizontalRel')
class PathSegLinetoHorizontalRel extends PathSeg native "*SVGPathSegLinetoHorizontalRel" {

  @DocsEditable @DomName('SVGPathSegLinetoHorizontalRel.x')
  num x;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGPathSegLinetoRel')
class PathSegLinetoRel extends PathSeg native "*SVGPathSegLinetoRel" {

  @DocsEditable @DomName('SVGPathSegLinetoRel.x')
  num x;

  @DocsEditable @DomName('SVGPathSegLinetoRel.y')
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGPathSegLinetoVerticalAbs')
class PathSegLinetoVerticalAbs extends PathSeg native "*SVGPathSegLinetoVerticalAbs" {

  @DocsEditable @DomName('SVGPathSegLinetoVerticalAbs.y')
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGPathSegLinetoVerticalRel')
class PathSegLinetoVerticalRel extends PathSeg native "*SVGPathSegLinetoVerticalRel" {

  @DocsEditable @DomName('SVGPathSegLinetoVerticalRel.y')
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGPathSegList')
class PathSegList implements JavaScriptIndexingBehavior, List<PathSeg> native "*SVGPathSegList" {

  @DocsEditable @DomName('SVGPathSegList.numberOfItems')
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
    return IterableMixinWorkaround.reduce(this, initialValue, combine);
  }

  bool contains(PathSeg element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(PathSeg element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator]) => IterableMixinWorkaround.joinList(this, separator);

  List mappedBy(f(PathSeg element)) => IterableMixinWorkaround.mappedByList(this, f);

  Iterable<PathSeg> where(bool f(PathSeg element)) => IterableMixinWorkaround.where(this, f);

  bool every(bool f(PathSeg element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(PathSeg element)) => IterableMixinWorkaround.any(this, f);

  List<PathSeg> toList() => new List<PathSeg>.from(this);
  Set<PathSeg> toSet() => new Set<PathSeg>.from(this);

  bool get isEmpty => this.length == 0;

  List<PathSeg> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<PathSeg> takeWhile(bool test(PathSeg value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  List<PathSeg> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<PathSeg> skipWhile(bool test(PathSeg value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  PathSeg firstMatching(bool test(PathSeg value), { PathSeg orElse() }) {
    return IterableMixinWorkaround.firstMatching(this, test, orElse);
  }

  PathSeg lastMatching(bool test(PathSeg value), {PathSeg orElse()}) {
    return IterableMixinWorkaround.lastMatchingInList(this, test, orElse);
  }

  PathSeg singleMatching(bool test(PathSeg value)) {
    return IterableMixinWorkaround.singleMatching(this, test);
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

  // clear() defined by IDL.

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

  PathSeg min([int compare(PathSeg a, PathSeg b)]) => IterableMixinWorkaround.min(this, compare);

  PathSeg max([int compare(PathSeg a, PathSeg b)]) => IterableMixinWorkaround.max(this, compare);

  PathSeg removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  PathSeg removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeMatching(bool test(PathSeg element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainMatching(bool test(PathSeg element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
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

  @DocsEditable @DomName('SVGPathSegList.appendItem')
  PathSeg appendItem(PathSeg newItem) native;

  @DocsEditable @DomName('SVGPathSegList.clear')
  void clear() native;

  @DocsEditable @DomName('SVGPathSegList.getItem')
  PathSeg getItem(int index) native;

  @DocsEditable @DomName('SVGPathSegList.initialize')
  PathSeg initialize(PathSeg newItem) native;

  @DocsEditable @DomName('SVGPathSegList.insertItemBefore')
  PathSeg insertItemBefore(PathSeg newItem, int index) native;

  @DocsEditable @DomName('SVGPathSegList.removeItem')
  PathSeg removeItem(int index) native;

  @DocsEditable @DomName('SVGPathSegList.replaceItem')
  PathSeg replaceItem(PathSeg newItem, int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGPathSegMovetoAbs')
class PathSegMovetoAbs extends PathSeg native "*SVGPathSegMovetoAbs" {

  @DocsEditable @DomName('SVGPathSegMovetoAbs.x')
  num x;

  @DocsEditable @DomName('SVGPathSegMovetoAbs.y')
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGPathSegMovetoRel')
class PathSegMovetoRel extends PathSeg native "*SVGPathSegMovetoRel" {

  @DocsEditable @DomName('SVGPathSegMovetoRel.x')
  num x;

  @DocsEditable @DomName('SVGPathSegMovetoRel.y')
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGPatternElement')
class PatternElement extends SvgElement implements FitToViewBox, Tests, UriReference, Stylable, ExternalResourcesRequired, LangSpace native "*SVGPatternElement" {

  @DocsEditable
  factory PatternElement() => _SvgElementFactoryProvider.createSvgElement_tag("pattern");

  @DocsEditable @DomName('SVGPatternElement.height')
  final AnimatedLength height;

  @DocsEditable @DomName('SVGPatternElement.patternContentUnits')
  final AnimatedEnumeration patternContentUnits;

  @DocsEditable @DomName('SVGPatternElement.patternTransform')
  final AnimatedTransformList patternTransform;

  @DocsEditable @DomName('SVGPatternElement.patternUnits')
  final AnimatedEnumeration patternUnits;

  @DocsEditable @DomName('SVGPatternElement.width')
  final AnimatedLength width;

  @DocsEditable @DomName('SVGPatternElement.x')
  final AnimatedLength x;

  @DocsEditable @DomName('SVGPatternElement.y')
  final AnimatedLength y;

  // From SVGExternalResourcesRequired

  @DocsEditable @DomName('SVGPatternElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGFitToViewBox

  @DocsEditable @DomName('SVGPatternElement.preserveAspectRatio')
  final AnimatedPreserveAspectRatio preserveAspectRatio;

  @DocsEditable @DomName('SVGPatternElement.viewBox')
  final AnimatedRect viewBox;

  // From SVGLangSpace

  @DocsEditable @DomName('SVGPatternElement.xmllang')
  String xmllang;

  @DocsEditable @DomName('SVGPatternElement.xmlspace')
  String xmlspace;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DocsEditable @DomName('SVGPatternElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  @DocsEditable @DomName('SVGPatternElement.requiredExtensions')
  final StringList requiredExtensions;

  @DocsEditable @DomName('SVGPatternElement.requiredFeatures')
  final StringList requiredFeatures;

  @DocsEditable @DomName('SVGPatternElement.systemLanguage')
  final StringList systemLanguage;

  @DocsEditable @DomName('SVGPatternElement.hasExtension')
  bool hasExtension(String extension) native;

  // From SVGURIReference

  @DocsEditable @DomName('SVGPatternElement.href')
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGPoint')
class Point native "*SVGPoint" {

  @DocsEditable @DomName('SVGPoint.x')
  num x;

  @DocsEditable @DomName('SVGPoint.y')
  num y;

  @DocsEditable @DomName('SVGPoint.matrixTransform')
  Point matrixTransform(Matrix matrix) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGPointList')
class PointList native "*SVGPointList" {

  @DocsEditable @DomName('SVGPointList.numberOfItems')
  final int numberOfItems;

  @DocsEditable @DomName('SVGPointList.appendItem')
  Point appendItem(Point item) native;

  @DocsEditable @DomName('SVGPointList.clear')
  void clear() native;

  @DocsEditable @DomName('SVGPointList.getItem')
  Point getItem(int index) native;

  @DocsEditable @DomName('SVGPointList.initialize')
  Point initialize(Point item) native;

  @DocsEditable @DomName('SVGPointList.insertItemBefore')
  Point insertItemBefore(Point item, int index) native;

  @DocsEditable @DomName('SVGPointList.removeItem')
  Point removeItem(int index) native;

  @DocsEditable @DomName('SVGPointList.replaceItem')
  Point replaceItem(Point item, int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGPolygonElement')
class PolygonElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGPolygonElement" {

  @DocsEditable
  factory PolygonElement() => _SvgElementFactoryProvider.createSvgElement_tag("polygon");

  @DocsEditable @DomName('SVGPolygonElement.animatedPoints')
  final PointList animatedPoints;

  @DocsEditable @DomName('SVGPolygonElement.points')
  final PointList points;

  // From SVGExternalResourcesRequired

  @DocsEditable @DomName('SVGPolygonElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  @DocsEditable @DomName('SVGPolygonElement.xmllang')
  String xmllang;

  @DocsEditable @DomName('SVGPolygonElement.xmlspace')
  String xmlspace;

  // From SVGLocatable

  @DocsEditable @DomName('SVGPolygonElement.farthestViewportElement')
  final SvgElement farthestViewportElement;

  @DocsEditable @DomName('SVGPolygonElement.nearestViewportElement')
  final SvgElement nearestViewportElement;

  @DocsEditable @DomName('SVGPolygonElement.getBBox')
  Rect getBBox() native;

  @JSName('getCTM')
  @DocsEditable @DomName('SVGPolygonElement.getCTM')
  Matrix getCtm() native;

  @JSName('getScreenCTM')
  @DocsEditable @DomName('SVGPolygonElement.getScreenCTM')
  Matrix getScreenCtm() native;

  @DocsEditable @DomName('SVGPolygonElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DocsEditable @DomName('SVGPolygonElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  @DocsEditable @DomName('SVGPolygonElement.requiredExtensions')
  final StringList requiredExtensions;

  @DocsEditable @DomName('SVGPolygonElement.requiredFeatures')
  final StringList requiredFeatures;

  @DocsEditable @DomName('SVGPolygonElement.systemLanguage')
  final StringList systemLanguage;

  @DocsEditable @DomName('SVGPolygonElement.hasExtension')
  bool hasExtension(String extension) native;

  // From SVGTransformable

  @DocsEditable @DomName('SVGPolygonElement.transform')
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGPolylineElement')
class PolylineElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGPolylineElement" {

  @DocsEditable
  factory PolylineElement() => _SvgElementFactoryProvider.createSvgElement_tag("polyline");

  @DocsEditable @DomName('SVGPolylineElement.animatedPoints')
  final PointList animatedPoints;

  @DocsEditable @DomName('SVGPolylineElement.points')
  final PointList points;

  // From SVGExternalResourcesRequired

  @DocsEditable @DomName('SVGPolylineElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  @DocsEditable @DomName('SVGPolylineElement.xmllang')
  String xmllang;

  @DocsEditable @DomName('SVGPolylineElement.xmlspace')
  String xmlspace;

  // From SVGLocatable

  @DocsEditable @DomName('SVGPolylineElement.farthestViewportElement')
  final SvgElement farthestViewportElement;

  @DocsEditable @DomName('SVGPolylineElement.nearestViewportElement')
  final SvgElement nearestViewportElement;

  @DocsEditable @DomName('SVGPolylineElement.getBBox')
  Rect getBBox() native;

  @JSName('getCTM')
  @DocsEditable @DomName('SVGPolylineElement.getCTM')
  Matrix getCtm() native;

  @JSName('getScreenCTM')
  @DocsEditable @DomName('SVGPolylineElement.getScreenCTM')
  Matrix getScreenCtm() native;

  @DocsEditable @DomName('SVGPolylineElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DocsEditable @DomName('SVGPolylineElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  @DocsEditable @DomName('SVGPolylineElement.requiredExtensions')
  final StringList requiredExtensions;

  @DocsEditable @DomName('SVGPolylineElement.requiredFeatures')
  final StringList requiredFeatures;

  @DocsEditable @DomName('SVGPolylineElement.systemLanguage')
  final StringList systemLanguage;

  @DocsEditable @DomName('SVGPolylineElement.hasExtension')
  bool hasExtension(String extension) native;

  // From SVGTransformable

  @DocsEditable @DomName('SVGPolylineElement.transform')
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
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

  @DocsEditable @DomName('SVGPreserveAspectRatio.align')
  int align;

  @DocsEditable @DomName('SVGPreserveAspectRatio.meetOrSlice')
  int meetOrSlice;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGRadialGradientElement')
class RadialGradientElement extends GradientElement native "*SVGRadialGradientElement" {

  @DocsEditable
  factory RadialGradientElement() => _SvgElementFactoryProvider.createSvgElement_tag("radialGradient");

  @DocsEditable @DomName('SVGRadialGradientElement.cx')
  final AnimatedLength cx;

  @DocsEditable @DomName('SVGRadialGradientElement.cy')
  final AnimatedLength cy;

  @DocsEditable @DomName('SVGRadialGradientElement.fr')
  final AnimatedLength fr;

  @DocsEditable @DomName('SVGRadialGradientElement.fx')
  final AnimatedLength fx;

  @DocsEditable @DomName('SVGRadialGradientElement.fy')
  final AnimatedLength fy;

  @DocsEditable @DomName('SVGRadialGradientElement.r')
  final AnimatedLength r;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGRect')
class Rect native "*SVGRect" {

  @DocsEditable @DomName('SVGRect.height')
  num height;

  @DocsEditable @DomName('SVGRect.width')
  num width;

  @DocsEditable @DomName('SVGRect.x')
  num x;

  @DocsEditable @DomName('SVGRect.y')
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGRectElement')
class RectElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGRectElement" {

  @DocsEditable
  factory RectElement() => _SvgElementFactoryProvider.createSvgElement_tag("rect");

  @DocsEditable @DomName('SVGRectElement.height')
  final AnimatedLength height;

  @DocsEditable @DomName('SVGRectElement.rx')
  final AnimatedLength rx;

  @DocsEditable @DomName('SVGRectElement.ry')
  final AnimatedLength ry;

  @DocsEditable @DomName('SVGRectElement.width')
  final AnimatedLength width;

  @DocsEditable @DomName('SVGRectElement.x')
  final AnimatedLength x;

  @DocsEditable @DomName('SVGRectElement.y')
  final AnimatedLength y;

  // From SVGExternalResourcesRequired

  @DocsEditable @DomName('SVGRectElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  @DocsEditable @DomName('SVGRectElement.xmllang')
  String xmllang;

  @DocsEditable @DomName('SVGRectElement.xmlspace')
  String xmlspace;

  // From SVGLocatable

  @DocsEditable @DomName('SVGRectElement.farthestViewportElement')
  final SvgElement farthestViewportElement;

  @DocsEditable @DomName('SVGRectElement.nearestViewportElement')
  final SvgElement nearestViewportElement;

  @DocsEditable @DomName('SVGRectElement.getBBox')
  Rect getBBox() native;

  @JSName('getCTM')
  @DocsEditable @DomName('SVGRectElement.getCTM')
  Matrix getCtm() native;

  @JSName('getScreenCTM')
  @DocsEditable @DomName('SVGRectElement.getScreenCTM')
  Matrix getScreenCtm() native;

  @DocsEditable @DomName('SVGRectElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DocsEditable @DomName('SVGRectElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  @DocsEditable @DomName('SVGRectElement.requiredExtensions')
  final StringList requiredExtensions;

  @DocsEditable @DomName('SVGRectElement.requiredFeatures')
  final StringList requiredFeatures;

  @DocsEditable @DomName('SVGRectElement.systemLanguage')
  final StringList systemLanguage;

  @DocsEditable @DomName('SVGRectElement.hasExtension')
  bool hasExtension(String extension) native;

  // From SVGTransformable

  @DocsEditable @DomName('SVGRectElement.transform')
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
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



@DocsEditable
@DomName('SVGScriptElement')
class ScriptElement extends SvgElement implements UriReference, ExternalResourcesRequired native "*SVGScriptElement" {

  @DocsEditable
  factory ScriptElement() => _SvgElementFactoryProvider.createSvgElement_tag("script");

  @DocsEditable @DomName('SVGScriptElement.type')
  String type;

  // From SVGExternalResourcesRequired

  @DocsEditable @DomName('SVGScriptElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGURIReference

  @DocsEditable @DomName('SVGScriptElement.href')
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGSetElement')
class SetElement extends AnimationElement native "*SVGSetElement" {

  @DocsEditable
  factory SetElement() => _SvgElementFactoryProvider.createSvgElement_tag("set");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGStopElement')
class StopElement extends SvgElement implements Stylable native "*SVGStopElement" {

  @DocsEditable
  factory StopElement() => _SvgElementFactoryProvider.createSvgElement_tag("stop");

  @DocsEditable @DomName('SVGStopElement.offset')
  final AnimatedNumber offset;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DocsEditable @DomName('SVGStopElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGStringList')
class StringList implements JavaScriptIndexingBehavior, List<String> native "*SVGStringList" {

  @DocsEditable @DomName('SVGStringList.numberOfItems')
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
    return IterableMixinWorkaround.reduce(this, initialValue, combine);
  }

  bool contains(String element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(String element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator]) => IterableMixinWorkaround.joinList(this, separator);

  List mappedBy(f(String element)) => IterableMixinWorkaround.mappedByList(this, f);

  Iterable<String> where(bool f(String element)) => IterableMixinWorkaround.where(this, f);

  bool every(bool f(String element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(String element)) => IterableMixinWorkaround.any(this, f);

  List<String> toList() => new List<String>.from(this);
  Set<String> toSet() => new Set<String>.from(this);

  bool get isEmpty => this.length == 0;

  List<String> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<String> takeWhile(bool test(String value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  List<String> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<String> skipWhile(bool test(String value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  String firstMatching(bool test(String value), { String orElse() }) {
    return IterableMixinWorkaround.firstMatching(this, test, orElse);
  }

  String lastMatching(bool test(String value), {String orElse()}) {
    return IterableMixinWorkaround.lastMatchingInList(this, test, orElse);
  }

  String singleMatching(bool test(String value)) {
    return IterableMixinWorkaround.singleMatching(this, test);
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

  // clear() defined by IDL.

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

  String min([int compare(String a, String b)]) => IterableMixinWorkaround.min(this, compare);

  String max([int compare(String a, String b)]) => IterableMixinWorkaround.max(this, compare);

  String removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  String removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeMatching(bool test(String element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainMatching(bool test(String element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
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

  @DocsEditable @DomName('SVGStringList.appendItem')
  String appendItem(String item) native;

  @DocsEditable @DomName('SVGStringList.clear')
  void clear() native;

  @DocsEditable @DomName('SVGStringList.getItem')
  String getItem(int index) native;

  @DocsEditable @DomName('SVGStringList.initialize')
  String initialize(String item) native;

  @DocsEditable @DomName('SVGStringList.insertItemBefore')
  String insertItemBefore(String item, int index) native;

  @DocsEditable @DomName('SVGStringList.removeItem')
  String removeItem(int index) native;

  @DocsEditable @DomName('SVGStringList.replaceItem')
  String replaceItem(String item, int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGStylable')
abstract class Stylable {

  AnimatedString $dom_svgClassName;

  CssStyleDeclaration style;

  CssValue getPresentationAttribute(String name);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGStyleElement')
class StyleElement extends SvgElement implements LangSpace native "*SVGStyleElement" {

  @DocsEditable
  factory StyleElement() => _SvgElementFactoryProvider.createSvgElement_tag("style");

  @DocsEditable @DomName('SVGStyleElement.disabled')
  bool disabled;

  @DocsEditable @DomName('SVGStyleElement.media')
  String media;

  // Shadowing definition.
  String get title => JS("String", "#.title", this);

  void set title(String value) {
    JS("void", "#.title = #", this, value);
  }

  @DocsEditable @DomName('SVGStyleElement.type')
  String type;

  // From SVGLangSpace

  @DocsEditable @DomName('SVGStyleElement.xmllang')
  String xmllang;

  @DocsEditable @DomName('SVGStyleElement.xmlspace')
  String xmlspace;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGDocument')
class SvgDocument extends Document native "*SVGDocument" {

  @DocsEditable @DomName('SVGDocument.rootElement')
  final SvgSvgElement rootElement;

  @JSName('createEvent')
  @DocsEditable @DomName('SVGDocument.createEvent')
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

@DocsEditable
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
  String get id => JS("String", "#.id", this);

  void set id(String value) {
    JS("void", "#.id = #", this, value);
  }

  @JSName('ownerSVGElement')
  @DocsEditable @DomName('SVGElement.ownerSVGElement')
  final SvgSvgElement ownerSvgElement;

  @DocsEditable @DomName('SVGElement.viewportElement')
  final SvgElement viewportElement;

  @DocsEditable @DomName('SVGElement.xmlbase')
  String xmlbase;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGException')
class SvgException native "*SVGException" {

  static const int SVG_INVALID_VALUE_ERR = 1;

  static const int SVG_MATRIX_NOT_INVERTABLE = 2;

  static const int SVG_WRONG_TYPE_ERR = 0;

  @DocsEditable @DomName('SVGException.code')
  final int code;

  @DocsEditable @DomName('SVGException.message')
  final String message;

  @DocsEditable @DomName('SVGException.name')
  final String name;

  @DocsEditable @DomName('SVGException.toString')
  String toString() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGSVGElement')
class SvgSvgElement extends SvgElement implements FitToViewBox, Tests, Stylable, Locatable, ExternalResourcesRequired, ZoomAndPan, LangSpace native "*SVGSVGElement" {
  factory SvgSvgElement() => _SvgSvgElementFactoryProvider.createSvgSvgElement();


  @DocsEditable @DomName('SVGSVGElement.contentScriptType')
  String contentScriptType;

  @DocsEditable @DomName('SVGSVGElement.contentStyleType')
  String contentStyleType;

  @DocsEditable @DomName('SVGSVGElement.currentScale')
  num currentScale;

  @DocsEditable @DomName('SVGSVGElement.currentTranslate')
  final Point currentTranslate;

  @DocsEditable @DomName('SVGSVGElement.currentView')
  final ViewSpec currentView;

  @DocsEditable @DomName('SVGSVGElement.height')
  final AnimatedLength height;

  @DocsEditable @DomName('SVGSVGElement.pixelUnitToMillimeterX')
  final num pixelUnitToMillimeterX;

  @DocsEditable @DomName('SVGSVGElement.pixelUnitToMillimeterY')
  final num pixelUnitToMillimeterY;

  @DocsEditable @DomName('SVGSVGElement.screenPixelToMillimeterX')
  final num screenPixelToMillimeterX;

  @DocsEditable @DomName('SVGSVGElement.screenPixelToMillimeterY')
  final num screenPixelToMillimeterY;

  @DocsEditable @DomName('SVGSVGElement.useCurrentView')
  final bool useCurrentView;

  @DocsEditable @DomName('SVGSVGElement.viewport')
  final Rect viewport;

  @DocsEditable @DomName('SVGSVGElement.width')
  final AnimatedLength width;

  @DocsEditable @DomName('SVGSVGElement.x')
  final AnimatedLength x;

  @DocsEditable @DomName('SVGSVGElement.y')
  final AnimatedLength y;

  @DocsEditable @DomName('SVGSVGElement.animationsPaused')
  bool animationsPaused() native;

  @DocsEditable @DomName('SVGSVGElement.checkEnclosure')
  bool checkEnclosure(SvgElement element, Rect rect) native;

  @DocsEditable @DomName('SVGSVGElement.checkIntersection')
  bool checkIntersection(SvgElement element, Rect rect) native;

  @JSName('createSVGAngle')
  @DocsEditable @DomName('SVGSVGElement.createSVGAngle')
  Angle createSvgAngle() native;

  @JSName('createSVGLength')
  @DocsEditable @DomName('SVGSVGElement.createSVGLength')
  Length createSvgLength() native;

  @JSName('createSVGMatrix')
  @DocsEditable @DomName('SVGSVGElement.createSVGMatrix')
  Matrix createSvgMatrix() native;

  @JSName('createSVGNumber')
  @DocsEditable @DomName('SVGSVGElement.createSVGNumber')
  Number createSvgNumber() native;

  @JSName('createSVGPoint')
  @DocsEditable @DomName('SVGSVGElement.createSVGPoint')
  Point createSvgPoint() native;

  @JSName('createSVGRect')
  @DocsEditable @DomName('SVGSVGElement.createSVGRect')
  Rect createSvgRect() native;

  @JSName('createSVGTransform')
  @DocsEditable @DomName('SVGSVGElement.createSVGTransform')
  Transform createSvgTransform() native;

  @JSName('createSVGTransformFromMatrix')
  @DocsEditable @DomName('SVGSVGElement.createSVGTransformFromMatrix')
  Transform createSvgTransformFromMatrix(Matrix matrix) native;

  @DocsEditable @DomName('SVGSVGElement.deselectAll')
  void deselectAll() native;

  @DocsEditable @DomName('SVGSVGElement.forceRedraw')
  void forceRedraw() native;

  @DocsEditable @DomName('SVGSVGElement.getCurrentTime')
  num getCurrentTime() native;

  @DocsEditable @DomName('SVGSVGElement.getElementById')
  Element getElementById(String elementId) native;

  @DocsEditable @DomName('SVGSVGElement.getEnclosureList')
  @Returns('NodeList') @Creates('NodeList')
  List<Node> getEnclosureList(Rect rect, SvgElement referenceElement) native;

  @DocsEditable @DomName('SVGSVGElement.getIntersectionList')
  @Returns('NodeList') @Creates('NodeList')
  List<Node> getIntersectionList(Rect rect, SvgElement referenceElement) native;

  @DocsEditable @DomName('SVGSVGElement.pauseAnimations')
  void pauseAnimations() native;

  @DocsEditable @DomName('SVGSVGElement.setCurrentTime')
  void setCurrentTime(num seconds) native;

  @DocsEditable @DomName('SVGSVGElement.suspendRedraw')
  int suspendRedraw(int maxWaitMilliseconds) native;

  @DocsEditable @DomName('SVGSVGElement.unpauseAnimations')
  void unpauseAnimations() native;

  @DocsEditable @DomName('SVGSVGElement.unsuspendRedraw')
  void unsuspendRedraw(int suspendHandleId) native;

  @DocsEditable @DomName('SVGSVGElement.unsuspendRedrawAll')
  void unsuspendRedrawAll() native;

  // From SVGExternalResourcesRequired

  @DocsEditable @DomName('SVGSVGElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGFitToViewBox

  @DocsEditable @DomName('SVGSVGElement.preserveAspectRatio')
  final AnimatedPreserveAspectRatio preserveAspectRatio;

  @DocsEditable @DomName('SVGSVGElement.viewBox')
  final AnimatedRect viewBox;

  // From SVGLangSpace

  @DocsEditable @DomName('SVGSVGElement.xmllang')
  String xmllang;

  @DocsEditable @DomName('SVGSVGElement.xmlspace')
  String xmlspace;

  // From SVGLocatable

  @DocsEditable @DomName('SVGSVGElement.farthestViewportElement')
  final SvgElement farthestViewportElement;

  @DocsEditable @DomName('SVGSVGElement.nearestViewportElement')
  final SvgElement nearestViewportElement;

  @DocsEditable @DomName('SVGSVGElement.getBBox')
  Rect getBBox() native;

  @JSName('getCTM')
  @DocsEditable @DomName('SVGSVGElement.getCTM')
  Matrix getCtm() native;

  @JSName('getScreenCTM')
  @DocsEditable @DomName('SVGSVGElement.getScreenCTM')
  Matrix getScreenCtm() native;

  @DocsEditable @DomName('SVGSVGElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DocsEditable @DomName('SVGSVGElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  @DocsEditable @DomName('SVGSVGElement.requiredExtensions')
  final StringList requiredExtensions;

  @DocsEditable @DomName('SVGSVGElement.requiredFeatures')
  final StringList requiredFeatures;

  @DocsEditable @DomName('SVGSVGElement.systemLanguage')
  final StringList systemLanguage;

  @DocsEditable @DomName('SVGSVGElement.hasExtension')
  bool hasExtension(String extension) native;

  // From SVGZoomAndPan

  @DocsEditable @DomName('SVGSVGElement.zoomAndPan')
  int zoomAndPan;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGSwitchElement')
class SwitchElement extends SvgElement implements Transformable, Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGSwitchElement" {

  @DocsEditable
  factory SwitchElement() => _SvgElementFactoryProvider.createSvgElement_tag("switch");

  // From SVGExternalResourcesRequired

  @DocsEditable @DomName('SVGSwitchElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  @DocsEditable @DomName('SVGSwitchElement.xmllang')
  String xmllang;

  @DocsEditable @DomName('SVGSwitchElement.xmlspace')
  String xmlspace;

  // From SVGLocatable

  @DocsEditable @DomName('SVGSwitchElement.farthestViewportElement')
  final SvgElement farthestViewportElement;

  @DocsEditable @DomName('SVGSwitchElement.nearestViewportElement')
  final SvgElement nearestViewportElement;

  @DocsEditable @DomName('SVGSwitchElement.getBBox')
  Rect getBBox() native;

  @JSName('getCTM')
  @DocsEditable @DomName('SVGSwitchElement.getCTM')
  Matrix getCtm() native;

  @JSName('getScreenCTM')
  @DocsEditable @DomName('SVGSwitchElement.getScreenCTM')
  Matrix getScreenCtm() native;

  @DocsEditable @DomName('SVGSwitchElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DocsEditable @DomName('SVGSwitchElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  @DocsEditable @DomName('SVGSwitchElement.requiredExtensions')
  final StringList requiredExtensions;

  @DocsEditable @DomName('SVGSwitchElement.requiredFeatures')
  final StringList requiredFeatures;

  @DocsEditable @DomName('SVGSwitchElement.systemLanguage')
  final StringList systemLanguage;

  @DocsEditable @DomName('SVGSwitchElement.hasExtension')
  bool hasExtension(String extension) native;

  // From SVGTransformable

  @DocsEditable @DomName('SVGSwitchElement.transform')
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGSymbolElement')
class SymbolElement extends SvgElement implements FitToViewBox, ExternalResourcesRequired, Stylable, LangSpace native "*SVGSymbolElement" {

  @DocsEditable
  factory SymbolElement() => _SvgElementFactoryProvider.createSvgElement_tag("symbol");

  // From SVGExternalResourcesRequired

  @DocsEditable @DomName('SVGSymbolElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGFitToViewBox

  @DocsEditable @DomName('SVGSymbolElement.preserveAspectRatio')
  final AnimatedPreserveAspectRatio preserveAspectRatio;

  @DocsEditable @DomName('SVGSymbolElement.viewBox')
  final AnimatedRect viewBox;

  // From SVGLangSpace

  @DocsEditable @DomName('SVGSymbolElement.xmllang')
  String xmllang;

  @DocsEditable @DomName('SVGSymbolElement.xmlspace')
  String xmlspace;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DocsEditable @DomName('SVGSymbolElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGTRefElement')
class TRefElement extends TextPositioningElement implements UriReference native "*SVGTRefElement" {

  @DocsEditable
  factory TRefElement() => _SvgElementFactoryProvider.createSvgElement_tag("tref");

  // From SVGURIReference

  @DocsEditable @DomName('SVGTRefElement.href')
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGTSpanElement')
class TSpanElement extends TextPositioningElement native "*SVGTSpanElement" {

  @DocsEditable
  factory TSpanElement() => _SvgElementFactoryProvider.createSvgElement_tag("tspan");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGTests')
abstract class Tests {

  StringList requiredExtensions;

  StringList requiredFeatures;

  StringList systemLanguage;

  bool hasExtension(String extension);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGTextContentElement')
class TextContentElement extends SvgElement implements Tests, Stylable, ExternalResourcesRequired, LangSpace native "*SVGTextContentElement" {

  static const int LENGTHADJUST_SPACING = 1;

  static const int LENGTHADJUST_SPACINGANDGLYPHS = 2;

  static const int LENGTHADJUST_UNKNOWN = 0;

  @DocsEditable @DomName('SVGTextContentElement.lengthAdjust')
  final AnimatedEnumeration lengthAdjust;

  @DocsEditable @DomName('SVGTextContentElement.textLength')
  final AnimatedLength textLength;

  @DocsEditable @DomName('SVGTextContentElement.getCharNumAtPosition')
  int getCharNumAtPosition(Point point) native;

  @DocsEditable @DomName('SVGTextContentElement.getComputedTextLength')
  num getComputedTextLength() native;

  @DocsEditable @DomName('SVGTextContentElement.getEndPositionOfChar')
  Point getEndPositionOfChar(int offset) native;

  @DocsEditable @DomName('SVGTextContentElement.getExtentOfChar')
  Rect getExtentOfChar(int offset) native;

  @DocsEditable @DomName('SVGTextContentElement.getNumberOfChars')
  int getNumberOfChars() native;

  @DocsEditable @DomName('SVGTextContentElement.getRotationOfChar')
  num getRotationOfChar(int offset) native;

  @DocsEditable @DomName('SVGTextContentElement.getStartPositionOfChar')
  Point getStartPositionOfChar(int offset) native;

  @DocsEditable @DomName('SVGTextContentElement.getSubStringLength')
  num getSubStringLength(int offset, int length) native;

  @DocsEditable @DomName('SVGTextContentElement.selectSubString')
  void selectSubString(int offset, int length) native;

  // From SVGExternalResourcesRequired

  @DocsEditable @DomName('SVGTextContentElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  @DocsEditable @DomName('SVGTextContentElement.xmllang')
  String xmllang;

  @DocsEditable @DomName('SVGTextContentElement.xmlspace')
  String xmlspace;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DocsEditable @DomName('SVGTextContentElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  @DocsEditable @DomName('SVGTextContentElement.requiredExtensions')
  final StringList requiredExtensions;

  @DocsEditable @DomName('SVGTextContentElement.requiredFeatures')
  final StringList requiredFeatures;

  @DocsEditable @DomName('SVGTextContentElement.systemLanguage')
  final StringList systemLanguage;

  @DocsEditable @DomName('SVGTextContentElement.hasExtension')
  bool hasExtension(String extension) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGTextElement')
class TextElement extends TextPositioningElement implements Transformable native "*SVGTextElement" {

  @DocsEditable
  factory TextElement() => _SvgElementFactoryProvider.createSvgElement_tag("text");

  // From SVGLocatable

  @DocsEditable @DomName('SVGTextElement.farthestViewportElement')
  final SvgElement farthestViewportElement;

  @DocsEditable @DomName('SVGTextElement.nearestViewportElement')
  final SvgElement nearestViewportElement;

  @DocsEditable @DomName('SVGTextElement.getBBox')
  Rect getBBox() native;

  @JSName('getCTM')
  @DocsEditable @DomName('SVGTextElement.getCTM')
  Matrix getCtm() native;

  @JSName('getScreenCTM')
  @DocsEditable @DomName('SVGTextElement.getScreenCTM')
  Matrix getScreenCtm() native;

  @DocsEditable @DomName('SVGTextElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGTransformable

  @DocsEditable @DomName('SVGTextElement.transform')
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGTextPathElement')
class TextPathElement extends TextContentElement implements UriReference native "*SVGTextPathElement" {

  static const int TEXTPATH_METHODTYPE_ALIGN = 1;

  static const int TEXTPATH_METHODTYPE_STRETCH = 2;

  static const int TEXTPATH_METHODTYPE_UNKNOWN = 0;

  static const int TEXTPATH_SPACINGTYPE_AUTO = 1;

  static const int TEXTPATH_SPACINGTYPE_EXACT = 2;

  static const int TEXTPATH_SPACINGTYPE_UNKNOWN = 0;

  @DocsEditable @DomName('SVGTextPathElement.method')
  final AnimatedEnumeration method;

  @DocsEditable @DomName('SVGTextPathElement.spacing')
  final AnimatedEnumeration spacing;

  @DocsEditable @DomName('SVGTextPathElement.startOffset')
  final AnimatedLength startOffset;

  // From SVGURIReference

  @DocsEditable @DomName('SVGTextPathElement.href')
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGTextPositioningElement')
class TextPositioningElement extends TextContentElement native "*SVGTextPositioningElement" {

  @DocsEditable @DomName('SVGTextPositioningElement.dx')
  final AnimatedLengthList dx;

  @DocsEditable @DomName('SVGTextPositioningElement.dy')
  final AnimatedLengthList dy;

  @DocsEditable @DomName('SVGTextPositioningElement.rotate')
  final AnimatedNumberList rotate;

  @DocsEditable @DomName('SVGTextPositioningElement.x')
  final AnimatedLengthList x;

  @DocsEditable @DomName('SVGTextPositioningElement.y')
  final AnimatedLengthList y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGTitleElement')
class TitleElement extends SvgElement implements Stylable, LangSpace native "*SVGTitleElement" {

  @DocsEditable
  factory TitleElement() => _SvgElementFactoryProvider.createSvgElement_tag("title");

  // From SVGLangSpace

  @DocsEditable @DomName('SVGTitleElement.xmllang')
  String xmllang;

  @DocsEditable @DomName('SVGTitleElement.xmlspace')
  String xmlspace;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DocsEditable @DomName('SVGTitleElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGTransform')
class Transform native "*SVGTransform" {

  static const int SVG_TRANSFORM_MATRIX = 1;

  static const int SVG_TRANSFORM_ROTATE = 4;

  static const int SVG_TRANSFORM_SCALE = 3;

  static const int SVG_TRANSFORM_SKEWX = 5;

  static const int SVG_TRANSFORM_SKEWY = 6;

  static const int SVG_TRANSFORM_TRANSLATE = 2;

  static const int SVG_TRANSFORM_UNKNOWN = 0;

  @DocsEditable @DomName('SVGTransform.angle')
  final num angle;

  @DocsEditable @DomName('SVGTransform.matrix')
  final Matrix matrix;

  @DocsEditable @DomName('SVGTransform.type')
  final int type;

  @DocsEditable @DomName('SVGTransform.setMatrix')
  void setMatrix(Matrix matrix) native;

  @DocsEditable @DomName('SVGTransform.setRotate')
  void setRotate(num angle, num cx, num cy) native;

  @DocsEditable @DomName('SVGTransform.setScale')
  void setScale(num sx, num sy) native;

  @DocsEditable @DomName('SVGTransform.setSkewX')
  void setSkewX(num angle) native;

  @DocsEditable @DomName('SVGTransform.setSkewY')
  void setSkewY(num angle) native;

  @DocsEditable @DomName('SVGTransform.setTranslate')
  void setTranslate(num tx, num ty) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGTransformList')
class TransformList implements List<Transform>, JavaScriptIndexingBehavior native "*SVGTransformList" {

  @DocsEditable @DomName('SVGTransformList.numberOfItems')
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
    return IterableMixinWorkaround.reduce(this, initialValue, combine);
  }

  bool contains(Transform element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(Transform element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator]) => IterableMixinWorkaround.joinList(this, separator);

  List mappedBy(f(Transform element)) => IterableMixinWorkaround.mappedByList(this, f);

  Iterable<Transform> where(bool f(Transform element)) => IterableMixinWorkaround.where(this, f);

  bool every(bool f(Transform element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(Transform element)) => IterableMixinWorkaround.any(this, f);

  List<Transform> toList() => new List<Transform>.from(this);
  Set<Transform> toSet() => new Set<Transform>.from(this);

  bool get isEmpty => this.length == 0;

  List<Transform> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<Transform> takeWhile(bool test(Transform value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  List<Transform> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<Transform> skipWhile(bool test(Transform value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  Transform firstMatching(bool test(Transform value), { Transform orElse() }) {
    return IterableMixinWorkaround.firstMatching(this, test, orElse);
  }

  Transform lastMatching(bool test(Transform value), {Transform orElse()}) {
    return IterableMixinWorkaround.lastMatchingInList(this, test, orElse);
  }

  Transform singleMatching(bool test(Transform value)) {
    return IterableMixinWorkaround.singleMatching(this, test);
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

  // clear() defined by IDL.

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

  Transform min([int compare(Transform a, Transform b)]) => IterableMixinWorkaround.min(this, compare);

  Transform max([int compare(Transform a, Transform b)]) => IterableMixinWorkaround.max(this, compare);

  Transform removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  Transform removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeMatching(bool test(Transform element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainMatching(bool test(Transform element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
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

  @DocsEditable @DomName('SVGTransformList.appendItem')
  Transform appendItem(Transform item) native;

  @DocsEditable @DomName('SVGTransformList.clear')
  void clear() native;

  @DocsEditable @DomName('SVGTransformList.consolidate')
  Transform consolidate() native;

  @JSName('createSVGTransformFromMatrix')
  @DocsEditable @DomName('SVGTransformList.createSVGTransformFromMatrix')
  Transform createSvgTransformFromMatrix(Matrix matrix) native;

  @DocsEditable @DomName('SVGTransformList.getItem')
  Transform getItem(int index) native;

  @DocsEditable @DomName('SVGTransformList.initialize')
  Transform initialize(Transform item) native;

  @DocsEditable @DomName('SVGTransformList.insertItemBefore')
  Transform insertItemBefore(Transform item, int index) native;

  @DocsEditable @DomName('SVGTransformList.removeItem')
  Transform removeItem(int index) native;

  @DocsEditable @DomName('SVGTransformList.replaceItem')
  Transform replaceItem(Transform item, int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGTransformable')
abstract class Transformable implements Locatable {

  AnimatedTransformList transform;

  // From SVGLocatable

  SvgElement farthestViewportElement;

  SvgElement nearestViewportElement;

  Rect getBBox();

  Matrix getCTM();

  Matrix getScreenCTM();

  Matrix getTransformToElement(SvgElement element);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGUnitTypes')
class UnitTypes native "*SVGUnitTypes" {

  static const int SVG_UNIT_TYPE_OBJECTBOUNDINGBOX = 2;

  static const int SVG_UNIT_TYPE_UNKNOWN = 0;

  static const int SVG_UNIT_TYPE_USERSPACEONUSE = 1;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGURIReference')
abstract class UriReference {

  AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGUseElement')
class UseElement extends SvgElement implements Transformable, Tests, UriReference, Stylable, ExternalResourcesRequired, LangSpace native "*SVGUseElement" {

  @DocsEditable
  factory UseElement() => _SvgElementFactoryProvider.createSvgElement_tag("use");

  @DocsEditable @DomName('SVGUseElement.animatedInstanceRoot')
  final ElementInstance animatedInstanceRoot;

  @DocsEditable @DomName('SVGUseElement.height')
  final AnimatedLength height;

  @DocsEditable @DomName('SVGUseElement.instanceRoot')
  final ElementInstance instanceRoot;

  @DocsEditable @DomName('SVGUseElement.width')
  final AnimatedLength width;

  @DocsEditable @DomName('SVGUseElement.x')
  final AnimatedLength x;

  @DocsEditable @DomName('SVGUseElement.y')
  final AnimatedLength y;

  // From SVGExternalResourcesRequired

  @DocsEditable @DomName('SVGUseElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  @DocsEditable @DomName('SVGUseElement.xmllang')
  String xmllang;

  @DocsEditable @DomName('SVGUseElement.xmlspace')
  String xmlspace;

  // From SVGLocatable

  @DocsEditable @DomName('SVGUseElement.farthestViewportElement')
  final SvgElement farthestViewportElement;

  @DocsEditable @DomName('SVGUseElement.nearestViewportElement')
  final SvgElement nearestViewportElement;

  @DocsEditable @DomName('SVGUseElement.getBBox')
  Rect getBBox() native;

  @JSName('getCTM')
  @DocsEditable @DomName('SVGUseElement.getCTM')
  Matrix getCtm() native;

  @JSName('getScreenCTM')
  @DocsEditable @DomName('SVGUseElement.getScreenCTM')
  Matrix getScreenCtm() native;

  @DocsEditable @DomName('SVGUseElement.getTransformToElement')
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DocsEditable @DomName('SVGUseElement.getPresentationAttribute')
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  @DocsEditable @DomName('SVGUseElement.requiredExtensions')
  final StringList requiredExtensions;

  @DocsEditable @DomName('SVGUseElement.requiredFeatures')
  final StringList requiredFeatures;

  @DocsEditable @DomName('SVGUseElement.systemLanguage')
  final StringList systemLanguage;

  @DocsEditable @DomName('SVGUseElement.hasExtension')
  bool hasExtension(String extension) native;

  // From SVGTransformable

  @DocsEditable @DomName('SVGUseElement.transform')
  final AnimatedTransformList transform;

  // From SVGURIReference

  @DocsEditable @DomName('SVGUseElement.href')
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGVKernElement')
class VKernElement extends SvgElement native "*SVGVKernElement" {

  @DocsEditable
  factory VKernElement() => _SvgElementFactoryProvider.createSvgElement_tag("vkern");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGViewElement')
class ViewElement extends SvgElement implements FitToViewBox, ExternalResourcesRequired, ZoomAndPan native "*SVGViewElement" {

  @DocsEditable
  factory ViewElement() => _SvgElementFactoryProvider.createSvgElement_tag("view");

  @DocsEditable @DomName('SVGViewElement.viewTarget')
  final StringList viewTarget;

  // From SVGExternalResourcesRequired

  @DocsEditable @DomName('SVGViewElement.externalResourcesRequired')
  final AnimatedBoolean externalResourcesRequired;

  // From SVGFitToViewBox

  @DocsEditable @DomName('SVGViewElement.preserveAspectRatio')
  final AnimatedPreserveAspectRatio preserveAspectRatio;

  @DocsEditable @DomName('SVGViewElement.viewBox')
  final AnimatedRect viewBox;

  // From SVGZoomAndPan

  @DocsEditable @DomName('SVGViewElement.zoomAndPan')
  int zoomAndPan;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGViewSpec')
class ViewSpec native "*SVGViewSpec" {

  @DocsEditable @DomName('SVGViewSpec.preserveAspectRatio')
  final AnimatedPreserveAspectRatio preserveAspectRatio;

  @DocsEditable @DomName('SVGViewSpec.preserveAspectRatioString')
  final String preserveAspectRatioString;

  @DocsEditable @DomName('SVGViewSpec.transform')
  final TransformList transform;

  @DocsEditable @DomName('SVGViewSpec.transformString')
  final String transformString;

  @DocsEditable @DomName('SVGViewSpec.viewBox')
  final AnimatedRect viewBox;

  @DocsEditable @DomName('SVGViewSpec.viewBoxString')
  final String viewBoxString;

  @DocsEditable @DomName('SVGViewSpec.viewTarget')
  final SvgElement viewTarget;

  @DocsEditable @DomName('SVGViewSpec.viewTargetString')
  final String viewTargetString;

  @DocsEditable @DomName('SVGViewSpec.zoomAndPan')
  int zoomAndPan;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
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



@DocsEditable
@DomName('SVGZoomEvent')
class ZoomEvent extends UIEvent native "*SVGZoomEvent" {

  @DocsEditable @DomName('SVGZoomEvent.newScale')
  final num newScale;

  @DocsEditable @DomName('SVGZoomEvent.newTranslate')
  final Point newTranslate;

  @DocsEditable @DomName('SVGZoomEvent.previousScale')
  final num previousScale;

  @DocsEditable @DomName('SVGZoomEvent.previousTranslate')
  final Point previousTranslate;

  @DocsEditable @DomName('SVGZoomEvent.zoomRectScreen')
  final Rect zoomRectScreen;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SVGElementInstanceList')
class _ElementInstanceList implements JavaScriptIndexingBehavior, List<ElementInstance> native "*SVGElementInstanceList" {

  @DocsEditable @DomName('SVGElementInstanceList.length')
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
    return IterableMixinWorkaround.reduce(this, initialValue, combine);
  }

  bool contains(ElementInstance element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(ElementInstance element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator]) => IterableMixinWorkaround.joinList(this, separator);

  List mappedBy(f(ElementInstance element)) => IterableMixinWorkaround.mappedByList(this, f);

  Iterable<ElementInstance> where(bool f(ElementInstance element)) => IterableMixinWorkaround.where(this, f);

  bool every(bool f(ElementInstance element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(ElementInstance element)) => IterableMixinWorkaround.any(this, f);

  List<ElementInstance> toList() => new List<ElementInstance>.from(this);
  Set<ElementInstance> toSet() => new Set<ElementInstance>.from(this);

  bool get isEmpty => this.length == 0;

  List<ElementInstance> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<ElementInstance> takeWhile(bool test(ElementInstance value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  List<ElementInstance> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<ElementInstance> skipWhile(bool test(ElementInstance value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  ElementInstance firstMatching(bool test(ElementInstance value), { ElementInstance orElse() }) {
    return IterableMixinWorkaround.firstMatching(this, test, orElse);
  }

  ElementInstance lastMatching(bool test(ElementInstance value), {ElementInstance orElse()}) {
    return IterableMixinWorkaround.lastMatchingInList(this, test, orElse);
  }

  ElementInstance singleMatching(bool test(ElementInstance value)) {
    return IterableMixinWorkaround.singleMatching(this, test);
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

  ElementInstance min([int compare(ElementInstance a, ElementInstance b)]) => IterableMixinWorkaround.min(this, compare);

  ElementInstance max([int compare(ElementInstance a, ElementInstance b)]) => IterableMixinWorkaround.max(this, compare);

  ElementInstance removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  ElementInstance removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeMatching(bool test(ElementInstance element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainMatching(bool test(ElementInstance element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
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

  @DocsEditable @DomName('SVGElementInstanceList.item')
  ElementInstance item(int index) native;
}
