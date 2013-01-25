library svg;

import 'dart:async';
import 'dart:collection';
import 'dart:collection-dev';
import 'dart:html';
import 'dart:html_common';
import 'dart:_js_helper' show Creates, Returns, JavaScriptIndexingBehavior, JSName;
import 'dart:_foreign_helper' show JS;
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

  @DomName('SVGAElement.target')
  @DocsEditable
  final AnimatedString target;

  // From SVGExternalResourcesRequired

  @DomName('SVGAElement.externalResourcesRequired')
  @DocsEditable
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  @DomName('SVGAElement.xmllang')
  @DocsEditable
  String xmllang;

  @DomName('SVGAElement.xmlspace')
  @DocsEditable
  String xmlspace;

  // From SVGLocatable

  @DomName('SVGAElement.farthestViewportElement')
  @DocsEditable
  final SvgElement farthestViewportElement;

  @DomName('SVGAElement.nearestViewportElement')
  @DocsEditable
  final SvgElement nearestViewportElement;

  @DomName('SVGAElement.getBBox')
  @DocsEditable
  Rect getBBox() native;

  @JSName('getCTM')
  @DomName('SVGAElement.getCTM')
  @DocsEditable
  Matrix getCtm() native;

  @JSName('getScreenCTM')
  @DomName('SVGAElement.getScreenCTM')
  @DocsEditable
  Matrix getScreenCtm() native;

  @DomName('SVGAElement.getTransformToElement')
  @DocsEditable
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DomName('SVGAElement.getPresentationAttribute')
  @DocsEditable
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  @DomName('SVGAElement.requiredExtensions')
  @DocsEditable
  final StringList requiredExtensions;

  @DomName('SVGAElement.requiredFeatures')
  @DocsEditable
  final StringList requiredFeatures;

  @DomName('SVGAElement.systemLanguage')
  @DocsEditable
  final StringList systemLanguage;

  @DomName('SVGAElement.hasExtension')
  @DocsEditable
  bool hasExtension(String extension) native;

  // From SVGTransformable

  @DomName('SVGAElement.transform')
  @DocsEditable
  final AnimatedTransformList transform;

  // From SVGURIReference

  @DomName('SVGAElement.href')
  @DocsEditable
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

  @DomName('SVGAltGlyphElement.format')
  @DocsEditable
  String format;

  @DomName('SVGAltGlyphElement.glyphRef')
  @DocsEditable
  String glyphRef;

  // From SVGURIReference

  @DomName('SVGAltGlyphElement.href')
  @DocsEditable
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

  @DomName('SVGAngle.unitType')
  @DocsEditable
  final int unitType;

  @DomName('SVGAngle.value')
  @DocsEditable
  num value;

  @DomName('SVGAngle.valueAsString')
  @DocsEditable
  String valueAsString;

  @DomName('SVGAngle.valueInSpecifiedUnits')
  @DocsEditable
  num valueInSpecifiedUnits;

  @DomName('SVGAngle.convertToSpecifiedUnits')
  @DocsEditable
  void convertToSpecifiedUnits(int unitType) native;

  @DomName('SVGAngle.newValueSpecifiedUnits')
  @DocsEditable
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

  @DomName('SVGAnimatedAngle.animVal')
  @DocsEditable
  final Angle animVal;

  @DomName('SVGAnimatedAngle.baseVal')
  @DocsEditable
  final Angle baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGAnimatedBoolean')
class AnimatedBoolean native "*SVGAnimatedBoolean" {

  @DomName('SVGAnimatedBoolean.animVal')
  @DocsEditable
  final bool animVal;

  @DomName('SVGAnimatedBoolean.baseVal')
  @DocsEditable
  bool baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGAnimatedEnumeration')
class AnimatedEnumeration native "*SVGAnimatedEnumeration" {

  @DomName('SVGAnimatedEnumeration.animVal')
  @DocsEditable
  final int animVal;

  @DomName('SVGAnimatedEnumeration.baseVal')
  @DocsEditable
  int baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGAnimatedInteger')
class AnimatedInteger native "*SVGAnimatedInteger" {

  @DomName('SVGAnimatedInteger.animVal')
  @DocsEditable
  final int animVal;

  @DomName('SVGAnimatedInteger.baseVal')
  @DocsEditable
  int baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGAnimatedLength')
class AnimatedLength native "*SVGAnimatedLength" {

  @DomName('SVGAnimatedLength.animVal')
  @DocsEditable
  final Length animVal;

  @DomName('SVGAnimatedLength.baseVal')
  @DocsEditable
  final Length baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGAnimatedLengthList')
class AnimatedLengthList native "*SVGAnimatedLengthList" {

  @DomName('SVGAnimatedLengthList.animVal')
  @DocsEditable
  final LengthList animVal;

  @DomName('SVGAnimatedLengthList.baseVal')
  @DocsEditable
  final LengthList baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGAnimatedNumber')
class AnimatedNumber native "*SVGAnimatedNumber" {

  @DomName('SVGAnimatedNumber.animVal')
  @DocsEditable
  final num animVal;

  @DomName('SVGAnimatedNumber.baseVal')
  @DocsEditable
  num baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGAnimatedNumberList')
class AnimatedNumberList native "*SVGAnimatedNumberList" {

  @DomName('SVGAnimatedNumberList.animVal')
  @DocsEditable
  final NumberList animVal;

  @DomName('SVGAnimatedNumberList.baseVal')
  @DocsEditable
  final NumberList baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGAnimatedPreserveAspectRatio')
class AnimatedPreserveAspectRatio native "*SVGAnimatedPreserveAspectRatio" {

  @DomName('SVGAnimatedPreserveAspectRatio.animVal')
  @DocsEditable
  final PreserveAspectRatio animVal;

  @DomName('SVGAnimatedPreserveAspectRatio.baseVal')
  @DocsEditable
  final PreserveAspectRatio baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGAnimatedRect')
class AnimatedRect native "*SVGAnimatedRect" {

  @DomName('SVGAnimatedRect.animVal')
  @DocsEditable
  final Rect animVal;

  @DomName('SVGAnimatedRect.baseVal')
  @DocsEditable
  final Rect baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGAnimatedString')
class AnimatedString native "*SVGAnimatedString" {

  @DomName('SVGAnimatedString.animVal')
  @DocsEditable
  final String animVal;

  @DomName('SVGAnimatedString.baseVal')
  @DocsEditable
  String baseVal;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGAnimatedTransformList')
class AnimatedTransformList native "*SVGAnimatedTransformList" {

  @DomName('SVGAnimatedTransformList.animVal')
  @DocsEditable
  final TransformList animVal;

  @DomName('SVGAnimatedTransformList.baseVal')
  @DocsEditable
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

  @DomName('SVGAnimationElement.targetElement')
  @DocsEditable
  final SvgElement targetElement;

  @DomName('SVGAnimationElement.getCurrentTime')
  @DocsEditable
  num getCurrentTime() native;

  @DomName('SVGAnimationElement.getSimpleDuration')
  @DocsEditable
  num getSimpleDuration() native;

  @DomName('SVGAnimationElement.getStartTime')
  @DocsEditable
  num getStartTime() native;

  // From ElementTimeControl

  @DomName('SVGAnimationElement.beginElement')
  @DocsEditable
  void beginElement() native;

  @DomName('SVGAnimationElement.beginElementAt')
  @DocsEditable
  void beginElementAt(num offset) native;

  @DomName('SVGAnimationElement.endElement')
  @DocsEditable
  void endElement() native;

  @DomName('SVGAnimationElement.endElementAt')
  @DocsEditable
  void endElementAt(num offset) native;

  // From SVGExternalResourcesRequired

  @DomName('SVGAnimationElement.externalResourcesRequired')
  @DocsEditable
  final AnimatedBoolean externalResourcesRequired;

  // From SVGTests

  @DomName('SVGAnimationElement.requiredExtensions')
  @DocsEditable
  final StringList requiredExtensions;

  @DomName('SVGAnimationElement.requiredFeatures')
  @DocsEditable
  final StringList requiredFeatures;

  @DomName('SVGAnimationElement.systemLanguage')
  @DocsEditable
  final StringList systemLanguage;

  @DomName('SVGAnimationElement.hasExtension')
  @DocsEditable
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

  @DomName('SVGCircleElement.cx')
  @DocsEditable
  final AnimatedLength cx;

  @DomName('SVGCircleElement.cy')
  @DocsEditable
  final AnimatedLength cy;

  @DomName('SVGCircleElement.r')
  @DocsEditable
  final AnimatedLength r;

  // From SVGExternalResourcesRequired

  @DomName('SVGCircleElement.externalResourcesRequired')
  @DocsEditable
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  @DomName('SVGCircleElement.xmllang')
  @DocsEditable
  String xmllang;

  @DomName('SVGCircleElement.xmlspace')
  @DocsEditable
  String xmlspace;

  // From SVGLocatable

  @DomName('SVGCircleElement.farthestViewportElement')
  @DocsEditable
  final SvgElement farthestViewportElement;

  @DomName('SVGCircleElement.nearestViewportElement')
  @DocsEditable
  final SvgElement nearestViewportElement;

  @DomName('SVGCircleElement.getBBox')
  @DocsEditable
  Rect getBBox() native;

  @JSName('getCTM')
  @DomName('SVGCircleElement.getCTM')
  @DocsEditable
  Matrix getCtm() native;

  @JSName('getScreenCTM')
  @DomName('SVGCircleElement.getScreenCTM')
  @DocsEditable
  Matrix getScreenCtm() native;

  @DomName('SVGCircleElement.getTransformToElement')
  @DocsEditable
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DomName('SVGCircleElement.getPresentationAttribute')
  @DocsEditable
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  @DomName('SVGCircleElement.requiredExtensions')
  @DocsEditable
  final StringList requiredExtensions;

  @DomName('SVGCircleElement.requiredFeatures')
  @DocsEditable
  final StringList requiredFeatures;

  @DomName('SVGCircleElement.systemLanguage')
  @DocsEditable
  final StringList systemLanguage;

  @DomName('SVGCircleElement.hasExtension')
  @DocsEditable
  bool hasExtension(String extension) native;

  // From SVGTransformable

  @DomName('SVGCircleElement.transform')
  @DocsEditable
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

  @DomName('SVGClipPathElement.clipPathUnits')
  @DocsEditable
  final AnimatedEnumeration clipPathUnits;

  // From SVGExternalResourcesRequired

  @DomName('SVGClipPathElement.externalResourcesRequired')
  @DocsEditable
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  @DomName('SVGClipPathElement.xmllang')
  @DocsEditable
  String xmllang;

  @DomName('SVGClipPathElement.xmlspace')
  @DocsEditable
  String xmlspace;

  // From SVGLocatable

  @DomName('SVGClipPathElement.farthestViewportElement')
  @DocsEditable
  final SvgElement farthestViewportElement;

  @DomName('SVGClipPathElement.nearestViewportElement')
  @DocsEditable
  final SvgElement nearestViewportElement;

  @DomName('SVGClipPathElement.getBBox')
  @DocsEditable
  Rect getBBox() native;

  @JSName('getCTM')
  @DomName('SVGClipPathElement.getCTM')
  @DocsEditable
  Matrix getCtm() native;

  @JSName('getScreenCTM')
  @DomName('SVGClipPathElement.getScreenCTM')
  @DocsEditable
  Matrix getScreenCtm() native;

  @DomName('SVGClipPathElement.getTransformToElement')
  @DocsEditable
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DomName('SVGClipPathElement.getPresentationAttribute')
  @DocsEditable
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  @DomName('SVGClipPathElement.requiredExtensions')
  @DocsEditable
  final StringList requiredExtensions;

  @DomName('SVGClipPathElement.requiredFeatures')
  @DocsEditable
  final StringList requiredFeatures;

  @DomName('SVGClipPathElement.systemLanguage')
  @DocsEditable
  final StringList systemLanguage;

  @DomName('SVGClipPathElement.hasExtension')
  @DocsEditable
  bool hasExtension(String extension) native;

  // From SVGTransformable

  @DomName('SVGClipPathElement.transform')
  @DocsEditable
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

  @DomName('SVGColor.colorType')
  @DocsEditable
  final int colorType;

  @DomName('SVGColor.rgbColor')
  @DocsEditable
  final RgbColor rgbColor;

  @DomName('SVGColor.setColor')
  @DocsEditable
  void setColor(int colorType, String rgbColor, String iccColor) native;

  @JSName('setRGBColor')
  @DomName('SVGColor.setRGBColor')
  @DocsEditable
  void setRgbColor(String rgbColor) native;

  @JSName('setRGBColorICCColor')
  @DomName('SVGColor.setRGBColorICCColor')
  @DocsEditable
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

  @DomName('SVGComponentTransferFunctionElement.amplitude')
  @DocsEditable
  final AnimatedNumber amplitude;

  @DomName('SVGComponentTransferFunctionElement.exponent')
  @DocsEditable
  final AnimatedNumber exponent;

  @DomName('SVGComponentTransferFunctionElement.intercept')
  @DocsEditable
  final AnimatedNumber intercept;

  @DomName('SVGComponentTransferFunctionElement.offset')
  @DocsEditable
  final AnimatedNumber offset;

  @DomName('SVGComponentTransferFunctionElement.slope')
  @DocsEditable
  final AnimatedNumber slope;

  @DomName('SVGComponentTransferFunctionElement.tableValues')
  @DocsEditable
  final AnimatedNumberList tableValues;

  @DomName('SVGComponentTransferFunctionElement.type')
  @DocsEditable
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

  @DomName('SVGCursorElement.x')
  @DocsEditable
  final AnimatedLength x;

  @DomName('SVGCursorElement.y')
  @DocsEditable
  final AnimatedLength y;

  // From SVGExternalResourcesRequired

  @DomName('SVGCursorElement.externalResourcesRequired')
  @DocsEditable
  final AnimatedBoolean externalResourcesRequired;

  // From SVGTests

  @DomName('SVGCursorElement.requiredExtensions')
  @DocsEditable
  final StringList requiredExtensions;

  @DomName('SVGCursorElement.requiredFeatures')
  @DocsEditable
  final StringList requiredFeatures;

  @DomName('SVGCursorElement.systemLanguage')
  @DocsEditable
  final StringList systemLanguage;

  @DomName('SVGCursorElement.hasExtension')
  @DocsEditable
  bool hasExtension(String extension) native;

  // From SVGURIReference

  @DomName('SVGCursorElement.href')
  @DocsEditable
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

  @DomName('SVGDefsElement.externalResourcesRequired')
  @DocsEditable
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  @DomName('SVGDefsElement.xmllang')
  @DocsEditable
  String xmllang;

  @DomName('SVGDefsElement.xmlspace')
  @DocsEditable
  String xmlspace;

  // From SVGLocatable

  @DomName('SVGDefsElement.farthestViewportElement')
  @DocsEditable
  final SvgElement farthestViewportElement;

  @DomName('SVGDefsElement.nearestViewportElement')
  @DocsEditable
  final SvgElement nearestViewportElement;

  @DomName('SVGDefsElement.getBBox')
  @DocsEditable
  Rect getBBox() native;

  @JSName('getCTM')
  @DomName('SVGDefsElement.getCTM')
  @DocsEditable
  Matrix getCtm() native;

  @JSName('getScreenCTM')
  @DomName('SVGDefsElement.getScreenCTM')
  @DocsEditable
  Matrix getScreenCtm() native;

  @DomName('SVGDefsElement.getTransformToElement')
  @DocsEditable
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DomName('SVGDefsElement.getPresentationAttribute')
  @DocsEditable
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  @DomName('SVGDefsElement.requiredExtensions')
  @DocsEditable
  final StringList requiredExtensions;

  @DomName('SVGDefsElement.requiredFeatures')
  @DocsEditable
  final StringList requiredFeatures;

  @DomName('SVGDefsElement.systemLanguage')
  @DocsEditable
  final StringList systemLanguage;

  @DomName('SVGDefsElement.hasExtension')
  @DocsEditable
  bool hasExtension(String extension) native;

  // From SVGTransformable

  @DomName('SVGDefsElement.transform')
  @DocsEditable
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

  @DomName('SVGDescElement.xmllang')
  @DocsEditable
  String xmllang;

  @DomName('SVGDescElement.xmlspace')
  @DocsEditable
  String xmlspace;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DomName('SVGDescElement.getPresentationAttribute')
  @DocsEditable
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGElementInstance')
class ElementInstance extends EventTarget native "*SVGElementInstance" {

  @DomName('SVGElementInstance.abort')
  @DocsEditable
  static const EventStreamProvider<Event> abortEvent = const EventStreamProvider<Event>('abort');

  @DomName('SVGElementInstance.beforecopy')
  @DocsEditable
  static const EventStreamProvider<Event> beforeCopyEvent = const EventStreamProvider<Event>('beforecopy');

  @DomName('SVGElementInstance.beforecut')
  @DocsEditable
  static const EventStreamProvider<Event> beforeCutEvent = const EventStreamProvider<Event>('beforecut');

  @DomName('SVGElementInstance.beforepaste')
  @DocsEditable
  static const EventStreamProvider<Event> beforePasteEvent = const EventStreamProvider<Event>('beforepaste');

  @DomName('SVGElementInstance.blur')
  @DocsEditable
  static const EventStreamProvider<Event> blurEvent = const EventStreamProvider<Event>('blur');

  @DomName('SVGElementInstance.change')
  @DocsEditable
  static const EventStreamProvider<Event> changeEvent = const EventStreamProvider<Event>('change');

  @DomName('SVGElementInstance.click')
  @DocsEditable
  static const EventStreamProvider<MouseEvent> clickEvent = const EventStreamProvider<MouseEvent>('click');

  @DomName('SVGElementInstance.contextmenu')
  @DocsEditable
  static const EventStreamProvider<MouseEvent> contextMenuEvent = const EventStreamProvider<MouseEvent>('contextmenu');

  @DomName('SVGElementInstance.copy')
  @DocsEditable
  static const EventStreamProvider<Event> copyEvent = const EventStreamProvider<Event>('copy');

  @DomName('SVGElementInstance.cut')
  @DocsEditable
  static const EventStreamProvider<Event> cutEvent = const EventStreamProvider<Event>('cut');

  @DomName('SVGElementInstance.dblclick')
  @DocsEditable
  static const EventStreamProvider<Event> doubleClickEvent = const EventStreamProvider<Event>('dblclick');

  @DomName('SVGElementInstance.drag')
  @DocsEditable
  static const EventStreamProvider<MouseEvent> dragEvent = const EventStreamProvider<MouseEvent>('drag');

  @DomName('SVGElementInstance.dragend')
  @DocsEditable
  static const EventStreamProvider<MouseEvent> dragEndEvent = const EventStreamProvider<MouseEvent>('dragend');

  @DomName('SVGElementInstance.dragenter')
  @DocsEditable
  static const EventStreamProvider<MouseEvent> dragEnterEvent = const EventStreamProvider<MouseEvent>('dragenter');

  @DomName('SVGElementInstance.dragleave')
  @DocsEditable
  static const EventStreamProvider<MouseEvent> dragLeaveEvent = const EventStreamProvider<MouseEvent>('dragleave');

  @DomName('SVGElementInstance.dragover')
  @DocsEditable
  static const EventStreamProvider<MouseEvent> dragOverEvent = const EventStreamProvider<MouseEvent>('dragover');

  @DomName('SVGElementInstance.dragstart')
  @DocsEditable
  static const EventStreamProvider<MouseEvent> dragStartEvent = const EventStreamProvider<MouseEvent>('dragstart');

  @DomName('SVGElementInstance.drop')
  @DocsEditable
  static const EventStreamProvider<MouseEvent> dropEvent = const EventStreamProvider<MouseEvent>('drop');

  @DomName('SVGElementInstance.error')
  @DocsEditable
  static const EventStreamProvider<Event> errorEvent = const EventStreamProvider<Event>('error');

  @DomName('SVGElementInstance.focus')
  @DocsEditable
  static const EventStreamProvider<Event> focusEvent = const EventStreamProvider<Event>('focus');

  @DomName('SVGElementInstance.input')
  @DocsEditable
  static const EventStreamProvider<Event> inputEvent = const EventStreamProvider<Event>('input');

  @DomName('SVGElementInstance.keydown')
  @DocsEditable
  static const EventStreamProvider<KeyboardEvent> keyDownEvent = const EventStreamProvider<KeyboardEvent>('keydown');

  @DomName('SVGElementInstance.keypress')
  @DocsEditable
  static const EventStreamProvider<KeyboardEvent> keyPressEvent = const EventStreamProvider<KeyboardEvent>('keypress');

  @DomName('SVGElementInstance.keyup')
  @DocsEditable
  static const EventStreamProvider<KeyboardEvent> keyUpEvent = const EventStreamProvider<KeyboardEvent>('keyup');

  @DomName('SVGElementInstance.load')
  @DocsEditable
  static const EventStreamProvider<Event> loadEvent = const EventStreamProvider<Event>('load');

  @DomName('SVGElementInstance.mousedown')
  @DocsEditable
  static const EventStreamProvider<MouseEvent> mouseDownEvent = const EventStreamProvider<MouseEvent>('mousedown');

  @DomName('SVGElementInstance.mousemove')
  @DocsEditable
  static const EventStreamProvider<MouseEvent> mouseMoveEvent = const EventStreamProvider<MouseEvent>('mousemove');

  @DomName('SVGElementInstance.mouseout')
  @DocsEditable
  static const EventStreamProvider<MouseEvent> mouseOutEvent = const EventStreamProvider<MouseEvent>('mouseout');

  @DomName('SVGElementInstance.mouseover')
  @DocsEditable
  static const EventStreamProvider<MouseEvent> mouseOverEvent = const EventStreamProvider<MouseEvent>('mouseover');

  @DomName('SVGElementInstance.mouseup')
  @DocsEditable
  static const EventStreamProvider<MouseEvent> mouseUpEvent = const EventStreamProvider<MouseEvent>('mouseup');

  @DomName('SVGElementInstance.mousewheel')
  @DocsEditable
  static const EventStreamProvider<WheelEvent> mouseWheelEvent = const EventStreamProvider<WheelEvent>('mousewheel');

  @DomName('SVGElementInstance.paste')
  @DocsEditable
  static const EventStreamProvider<Event> pasteEvent = const EventStreamProvider<Event>('paste');

  @DomName('SVGElementInstance.reset')
  @DocsEditable
  static const EventStreamProvider<Event> resetEvent = const EventStreamProvider<Event>('reset');

  @DomName('SVGElementInstance.resize')
  @DocsEditable
  static const EventStreamProvider<Event> resizeEvent = const EventStreamProvider<Event>('resize');

  @DomName('SVGElementInstance.scroll')
  @DocsEditable
  static const EventStreamProvider<Event> scrollEvent = const EventStreamProvider<Event>('scroll');

  @DomName('SVGElementInstance.search')
  @DocsEditable
  static const EventStreamProvider<Event> searchEvent = const EventStreamProvider<Event>('search');

  @DomName('SVGElementInstance.select')
  @DocsEditable
  static const EventStreamProvider<Event> selectEvent = const EventStreamProvider<Event>('select');

  @DomName('SVGElementInstance.selectstart')
  @DocsEditable
  static const EventStreamProvider<Event> selectStartEvent = const EventStreamProvider<Event>('selectstart');

  @DomName('SVGElementInstance.submit')
  @DocsEditable
  static const EventStreamProvider<Event> submitEvent = const EventStreamProvider<Event>('submit');

  @DomName('SVGElementInstance.unload')
  @DocsEditable
  static const EventStreamProvider<Event> unloadEvent = const EventStreamProvider<Event>('unload');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  @deprecated
  ElementInstanceEvents get on =>
    new ElementInstanceEvents(this);

  @DomName('SVGElementInstance.childNodes')
  @DocsEditable
  @Returns('_ElementInstanceList')
  @Creates('_ElementInstanceList')
  final List<ElementInstance> childNodes;

  @DomName('SVGElementInstance.correspondingElement')
  @DocsEditable
  final SvgElement correspondingElement;

  @DomName('SVGElementInstance.correspondingUseElement')
  @DocsEditable
  final UseElement correspondingUseElement;

  @DomName('SVGElementInstance.firstChild')
  @DocsEditable
  final ElementInstance firstChild;

  @DomName('SVGElementInstance.lastChild')
  @DocsEditable
  final ElementInstance lastChild;

  @DomName('SVGElementInstance.nextSibling')
  @DocsEditable
  final ElementInstance nextSibling;

  @DomName('SVGElementInstance.parentNode')
  @DocsEditable
  final ElementInstance parentNode;

  @DomName('SVGElementInstance.previousSibling')
  @DocsEditable
  final ElementInstance previousSibling;

  @DomName('SVGElementInstance.abort')
  @DocsEditable
  Stream<Event> get onAbort => abortEvent.forTarget(this);

  @DomName('SVGElementInstance.beforecopy')
  @DocsEditable
  Stream<Event> get onBeforeCopy => beforeCopyEvent.forTarget(this);

  @DomName('SVGElementInstance.beforecut')
  @DocsEditable
  Stream<Event> get onBeforeCut => beforeCutEvent.forTarget(this);

  @DomName('SVGElementInstance.beforepaste')
  @DocsEditable
  Stream<Event> get onBeforePaste => beforePasteEvent.forTarget(this);

  @DomName('SVGElementInstance.blur')
  @DocsEditable
  Stream<Event> get onBlur => blurEvent.forTarget(this);

  @DomName('SVGElementInstance.change')
  @DocsEditable
  Stream<Event> get onChange => changeEvent.forTarget(this);

  @DomName('SVGElementInstance.click')
  @DocsEditable
  Stream<MouseEvent> get onClick => clickEvent.forTarget(this);

  @DomName('SVGElementInstance.contextmenu')
  @DocsEditable
  Stream<MouseEvent> get onContextMenu => contextMenuEvent.forTarget(this);

  @DomName('SVGElementInstance.copy')
  @DocsEditable
  Stream<Event> get onCopy => copyEvent.forTarget(this);

  @DomName('SVGElementInstance.cut')
  @DocsEditable
  Stream<Event> get onCut => cutEvent.forTarget(this);

  @DomName('SVGElementInstance.dblclick')
  @DocsEditable
  Stream<Event> get onDoubleClick => doubleClickEvent.forTarget(this);

  @DomName('SVGElementInstance.drag')
  @DocsEditable
  Stream<MouseEvent> get onDrag => dragEvent.forTarget(this);

  @DomName('SVGElementInstance.dragend')
  @DocsEditable
  Stream<MouseEvent> get onDragEnd => dragEndEvent.forTarget(this);

  @DomName('SVGElementInstance.dragenter')
  @DocsEditable
  Stream<MouseEvent> get onDragEnter => dragEnterEvent.forTarget(this);

  @DomName('SVGElementInstance.dragleave')
  @DocsEditable
  Stream<MouseEvent> get onDragLeave => dragLeaveEvent.forTarget(this);

  @DomName('SVGElementInstance.dragover')
  @DocsEditable
  Stream<MouseEvent> get onDragOver => dragOverEvent.forTarget(this);

  @DomName('SVGElementInstance.dragstart')
  @DocsEditable
  Stream<MouseEvent> get onDragStart => dragStartEvent.forTarget(this);

  @DomName('SVGElementInstance.drop')
  @DocsEditable
  Stream<MouseEvent> get onDrop => dropEvent.forTarget(this);

  @DomName('SVGElementInstance.error')
  @DocsEditable
  Stream<Event> get onError => errorEvent.forTarget(this);

  @DomName('SVGElementInstance.focus')
  @DocsEditable
  Stream<Event> get onFocus => focusEvent.forTarget(this);

  @DomName('SVGElementInstance.input')
  @DocsEditable
  Stream<Event> get onInput => inputEvent.forTarget(this);

  @DomName('SVGElementInstance.keydown')
  @DocsEditable
  Stream<KeyboardEvent> get onKeyDown => keyDownEvent.forTarget(this);

  @DomName('SVGElementInstance.keypress')
  @DocsEditable
  Stream<KeyboardEvent> get onKeyPress => keyPressEvent.forTarget(this);

  @DomName('SVGElementInstance.keyup')
  @DocsEditable
  Stream<KeyboardEvent> get onKeyUp => keyUpEvent.forTarget(this);

  @DomName('SVGElementInstance.load')
  @DocsEditable
  Stream<Event> get onLoad => loadEvent.forTarget(this);

  @DomName('SVGElementInstance.mousedown')
  @DocsEditable
  Stream<MouseEvent> get onMouseDown => mouseDownEvent.forTarget(this);

  @DomName('SVGElementInstance.mousemove')
  @DocsEditable
  Stream<MouseEvent> get onMouseMove => mouseMoveEvent.forTarget(this);

  @DomName('SVGElementInstance.mouseout')
  @DocsEditable
  Stream<MouseEvent> get onMouseOut => mouseOutEvent.forTarget(this);

  @DomName('SVGElementInstance.mouseover')
  @DocsEditable
  Stream<MouseEvent> get onMouseOver => mouseOverEvent.forTarget(this);

  @DomName('SVGElementInstance.mouseup')
  @DocsEditable
  Stream<MouseEvent> get onMouseUp => mouseUpEvent.forTarget(this);

  @DomName('SVGElementInstance.mousewheel')
  @DocsEditable
  Stream<WheelEvent> get onMouseWheel => mouseWheelEvent.forTarget(this);

  @DomName('SVGElementInstance.paste')
  @DocsEditable
  Stream<Event> get onPaste => pasteEvent.forTarget(this);

  @DomName('SVGElementInstance.reset')
  @DocsEditable
  Stream<Event> get onReset => resetEvent.forTarget(this);

  @DomName('SVGElementInstance.resize')
  @DocsEditable
  Stream<Event> get onResize => resizeEvent.forTarget(this);

  @DomName('SVGElementInstance.scroll')
  @DocsEditable
  Stream<Event> get onScroll => scrollEvent.forTarget(this);

  @DomName('SVGElementInstance.search')
  @DocsEditable
  Stream<Event> get onSearch => searchEvent.forTarget(this);

  @DomName('SVGElementInstance.select')
  @DocsEditable
  Stream<Event> get onSelect => selectEvent.forTarget(this);

  @DomName('SVGElementInstance.selectstart')
  @DocsEditable
  Stream<Event> get onSelectStart => selectStartEvent.forTarget(this);

  @DomName('SVGElementInstance.submit')
  @DocsEditable
  Stream<Event> get onSubmit => submitEvent.forTarget(this);

  @DomName('SVGElementInstance.unload')
  @DocsEditable
  Stream<Event> get onUnload => unloadEvent.forTarget(this);
}

@DocsEditable
@deprecated
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

  @DomName('SVGEllipseElement.cx')
  @DocsEditable
  final AnimatedLength cx;

  @DomName('SVGEllipseElement.cy')
  @DocsEditable
  final AnimatedLength cy;

  @DomName('SVGEllipseElement.rx')
  @DocsEditable
  final AnimatedLength rx;

  @DomName('SVGEllipseElement.ry')
  @DocsEditable
  final AnimatedLength ry;

  // From SVGExternalResourcesRequired

  @DomName('SVGEllipseElement.externalResourcesRequired')
  @DocsEditable
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  @DomName('SVGEllipseElement.xmllang')
  @DocsEditable
  String xmllang;

  @DomName('SVGEllipseElement.xmlspace')
  @DocsEditable
  String xmlspace;

  // From SVGLocatable

  @DomName('SVGEllipseElement.farthestViewportElement')
  @DocsEditable
  final SvgElement farthestViewportElement;

  @DomName('SVGEllipseElement.nearestViewportElement')
  @DocsEditable
  final SvgElement nearestViewportElement;

  @DomName('SVGEllipseElement.getBBox')
  @DocsEditable
  Rect getBBox() native;

  @JSName('getCTM')
  @DomName('SVGEllipseElement.getCTM')
  @DocsEditable
  Matrix getCtm() native;

  @JSName('getScreenCTM')
  @DomName('SVGEllipseElement.getScreenCTM')
  @DocsEditable
  Matrix getScreenCtm() native;

  @DomName('SVGEllipseElement.getTransformToElement')
  @DocsEditable
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DomName('SVGEllipseElement.getPresentationAttribute')
  @DocsEditable
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  @DomName('SVGEllipseElement.requiredExtensions')
  @DocsEditable
  final StringList requiredExtensions;

  @DomName('SVGEllipseElement.requiredFeatures')
  @DocsEditable
  final StringList requiredFeatures;

  @DomName('SVGEllipseElement.systemLanguage')
  @DocsEditable
  final StringList systemLanguage;

  @DomName('SVGEllipseElement.hasExtension')
  @DocsEditable
  bool hasExtension(String extension) native;

  // From SVGTransformable

  @DomName('SVGEllipseElement.transform')
  @DocsEditable
  final AnimatedTransformList transform;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


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

  @DomName('SVGFEBlendElement.in1')
  @DocsEditable
  final AnimatedString in1;

  @DomName('SVGFEBlendElement.in2')
  @DocsEditable
  final AnimatedString in2;

  @DomName('SVGFEBlendElement.mode')
  @DocsEditable
  final AnimatedEnumeration mode;

  // From SVGFilterPrimitiveStandardAttributes

  @DomName('SVGFEBlendElement.height')
  @DocsEditable
  final AnimatedLength height;

  @DomName('SVGFEBlendElement.result')
  @DocsEditable
  final AnimatedString result;

  @DomName('SVGFEBlendElement.width')
  @DocsEditable
  final AnimatedLength width;

  @DomName('SVGFEBlendElement.x')
  @DocsEditable
  final AnimatedLength x;

  @DomName('SVGFEBlendElement.y')
  @DocsEditable
  final AnimatedLength y;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DomName('SVGFEBlendElement.getPresentationAttribute')
  @DocsEditable
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

  @DomName('SVGFEColorMatrixElement.in1')
  @DocsEditable
  final AnimatedString in1;

  @DomName('SVGFEColorMatrixElement.type')
  @DocsEditable
  final AnimatedEnumeration type;

  @DomName('SVGFEColorMatrixElement.values')
  @DocsEditable
  final AnimatedNumberList values;

  // From SVGFilterPrimitiveStandardAttributes

  @DomName('SVGFEColorMatrixElement.height')
  @DocsEditable
  final AnimatedLength height;

  @DomName('SVGFEColorMatrixElement.result')
  @DocsEditable
  final AnimatedString result;

  @DomName('SVGFEColorMatrixElement.width')
  @DocsEditable
  final AnimatedLength width;

  @DomName('SVGFEColorMatrixElement.x')
  @DocsEditable
  final AnimatedLength x;

  @DomName('SVGFEColorMatrixElement.y')
  @DocsEditable
  final AnimatedLength y;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DomName('SVGFEColorMatrixElement.getPresentationAttribute')
  @DocsEditable
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGFEComponentTransferElement')
class FEComponentTransferElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEComponentTransferElement" {

  @DomName('SVGFEComponentTransferElement.in1')
  @DocsEditable
  final AnimatedString in1;

  // From SVGFilterPrimitiveStandardAttributes

  @DomName('SVGFEComponentTransferElement.height')
  @DocsEditable
  final AnimatedLength height;

  @DomName('SVGFEComponentTransferElement.result')
  @DocsEditable
  final AnimatedString result;

  @DomName('SVGFEComponentTransferElement.width')
  @DocsEditable
  final AnimatedLength width;

  @DomName('SVGFEComponentTransferElement.x')
  @DocsEditable
  final AnimatedLength x;

  @DomName('SVGFEComponentTransferElement.y')
  @DocsEditable
  final AnimatedLength y;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DomName('SVGFEComponentTransferElement.getPresentationAttribute')
  @DocsEditable
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

  @DomName('SVGFECompositeElement.in1')
  @DocsEditable
  final AnimatedString in1;

  @DomName('SVGFECompositeElement.in2')
  @DocsEditable
  final AnimatedString in2;

  @DomName('SVGFECompositeElement.k1')
  @DocsEditable
  final AnimatedNumber k1;

  @DomName('SVGFECompositeElement.k2')
  @DocsEditable
  final AnimatedNumber k2;

  @DomName('SVGFECompositeElement.k3')
  @DocsEditable
  final AnimatedNumber k3;

  @DomName('SVGFECompositeElement.k4')
  @DocsEditable
  final AnimatedNumber k4;

  @DomName('SVGFECompositeElement.operator')
  @DocsEditable
  final AnimatedEnumeration operator;

  // From SVGFilterPrimitiveStandardAttributes

  @DomName('SVGFECompositeElement.height')
  @DocsEditable
  final AnimatedLength height;

  @DomName('SVGFECompositeElement.result')
  @DocsEditable
  final AnimatedString result;

  @DomName('SVGFECompositeElement.width')
  @DocsEditable
  final AnimatedLength width;

  @DomName('SVGFECompositeElement.x')
  @DocsEditable
  final AnimatedLength x;

  @DomName('SVGFECompositeElement.y')
  @DocsEditable
  final AnimatedLength y;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DomName('SVGFECompositeElement.getPresentationAttribute')
  @DocsEditable
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

  @DomName('SVGFEConvolveMatrixElement.bias')
  @DocsEditable
  final AnimatedNumber bias;

  @DomName('SVGFEConvolveMatrixElement.divisor')
  @DocsEditable
  final AnimatedNumber divisor;

  @DomName('SVGFEConvolveMatrixElement.edgeMode')
  @DocsEditable
  final AnimatedEnumeration edgeMode;

  @DomName('SVGFEConvolveMatrixElement.in1')
  @DocsEditable
  final AnimatedString in1;

  @DomName('SVGFEConvolveMatrixElement.kernelMatrix')
  @DocsEditable
  final AnimatedNumberList kernelMatrix;

  @DomName('SVGFEConvolveMatrixElement.kernelUnitLengthX')
  @DocsEditable
  final AnimatedNumber kernelUnitLengthX;

  @DomName('SVGFEConvolveMatrixElement.kernelUnitLengthY')
  @DocsEditable
  final AnimatedNumber kernelUnitLengthY;

  @DomName('SVGFEConvolveMatrixElement.orderX')
  @DocsEditable
  final AnimatedInteger orderX;

  @DomName('SVGFEConvolveMatrixElement.orderY')
  @DocsEditable
  final AnimatedInteger orderY;

  @DomName('SVGFEConvolveMatrixElement.preserveAlpha')
  @DocsEditable
  final AnimatedBoolean preserveAlpha;

  @DomName('SVGFEConvolveMatrixElement.targetX')
  @DocsEditable
  final AnimatedInteger targetX;

  @DomName('SVGFEConvolveMatrixElement.targetY')
  @DocsEditable
  final AnimatedInteger targetY;

  // From SVGFilterPrimitiveStandardAttributes

  @DomName('SVGFEConvolveMatrixElement.height')
  @DocsEditable
  final AnimatedLength height;

  @DomName('SVGFEConvolveMatrixElement.result')
  @DocsEditable
  final AnimatedString result;

  @DomName('SVGFEConvolveMatrixElement.width')
  @DocsEditable
  final AnimatedLength width;

  @DomName('SVGFEConvolveMatrixElement.x')
  @DocsEditable
  final AnimatedLength x;

  @DomName('SVGFEConvolveMatrixElement.y')
  @DocsEditable
  final AnimatedLength y;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DomName('SVGFEConvolveMatrixElement.getPresentationAttribute')
  @DocsEditable
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGFEDiffuseLightingElement')
class FEDiffuseLightingElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEDiffuseLightingElement" {

  @DomName('SVGFEDiffuseLightingElement.diffuseConstant')
  @DocsEditable
  final AnimatedNumber diffuseConstant;

  @DomName('SVGFEDiffuseLightingElement.in1')
  @DocsEditable
  final AnimatedString in1;

  @DomName('SVGFEDiffuseLightingElement.kernelUnitLengthX')
  @DocsEditable
  final AnimatedNumber kernelUnitLengthX;

  @DomName('SVGFEDiffuseLightingElement.kernelUnitLengthY')
  @DocsEditable
  final AnimatedNumber kernelUnitLengthY;

  @DomName('SVGFEDiffuseLightingElement.surfaceScale')
  @DocsEditable
  final AnimatedNumber surfaceScale;

  // From SVGFilterPrimitiveStandardAttributes

  @DomName('SVGFEDiffuseLightingElement.height')
  @DocsEditable
  final AnimatedLength height;

  @DomName('SVGFEDiffuseLightingElement.result')
  @DocsEditable
  final AnimatedString result;

  @DomName('SVGFEDiffuseLightingElement.width')
  @DocsEditable
  final AnimatedLength width;

  @DomName('SVGFEDiffuseLightingElement.x')
  @DocsEditable
  final AnimatedLength x;

  @DomName('SVGFEDiffuseLightingElement.y')
  @DocsEditable
  final AnimatedLength y;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DomName('SVGFEDiffuseLightingElement.getPresentationAttribute')
  @DocsEditable
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

  @DomName('SVGFEDisplacementMapElement.in1')
  @DocsEditable
  final AnimatedString in1;

  @DomName('SVGFEDisplacementMapElement.in2')
  @DocsEditable
  final AnimatedString in2;

  @DomName('SVGFEDisplacementMapElement.scale')
  @DocsEditable
  final AnimatedNumber scale;

  @DomName('SVGFEDisplacementMapElement.xChannelSelector')
  @DocsEditable
  final AnimatedEnumeration xChannelSelector;

  @DomName('SVGFEDisplacementMapElement.yChannelSelector')
  @DocsEditable
  final AnimatedEnumeration yChannelSelector;

  // From SVGFilterPrimitiveStandardAttributes

  @DomName('SVGFEDisplacementMapElement.height')
  @DocsEditable
  final AnimatedLength height;

  @DomName('SVGFEDisplacementMapElement.result')
  @DocsEditable
  final AnimatedString result;

  @DomName('SVGFEDisplacementMapElement.width')
  @DocsEditable
  final AnimatedLength width;

  @DomName('SVGFEDisplacementMapElement.x')
  @DocsEditable
  final AnimatedLength x;

  @DomName('SVGFEDisplacementMapElement.y')
  @DocsEditable
  final AnimatedLength y;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DomName('SVGFEDisplacementMapElement.getPresentationAttribute')
  @DocsEditable
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGFEDistantLightElement')
class FEDistantLightElement extends SvgElement native "*SVGFEDistantLightElement" {

  @DomName('SVGFEDistantLightElement.azimuth')
  @DocsEditable
  final AnimatedNumber azimuth;

  @DomName('SVGFEDistantLightElement.elevation')
  @DocsEditable
  final AnimatedNumber elevation;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGFEDropShadowElement')
class FEDropShadowElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEDropShadowElement" {

  @DomName('SVGFEDropShadowElement.dx')
  @DocsEditable
  final AnimatedNumber dx;

  @DomName('SVGFEDropShadowElement.dy')
  @DocsEditable
  final AnimatedNumber dy;

  @DomName('SVGFEDropShadowElement.in1')
  @DocsEditable
  final AnimatedString in1;

  @DomName('SVGFEDropShadowElement.stdDeviationX')
  @DocsEditable
  final AnimatedNumber stdDeviationX;

  @DomName('SVGFEDropShadowElement.stdDeviationY')
  @DocsEditable
  final AnimatedNumber stdDeviationY;

  @DomName('SVGFEDropShadowElement.setStdDeviation')
  @DocsEditable
  void setStdDeviation(num stdDeviationX, num stdDeviationY) native;

  // From SVGFilterPrimitiveStandardAttributes

  @DomName('SVGFEDropShadowElement.height')
  @DocsEditable
  final AnimatedLength height;

  @DomName('SVGFEDropShadowElement.result')
  @DocsEditable
  final AnimatedString result;

  @DomName('SVGFEDropShadowElement.width')
  @DocsEditable
  final AnimatedLength width;

  @DomName('SVGFEDropShadowElement.x')
  @DocsEditable
  final AnimatedLength x;

  @DomName('SVGFEDropShadowElement.y')
  @DocsEditable
  final AnimatedLength y;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DomName('SVGFEDropShadowElement.getPresentationAttribute')
  @DocsEditable
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGFEFloodElement')
class FEFloodElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEFloodElement" {

  // From SVGFilterPrimitiveStandardAttributes

  @DomName('SVGFEFloodElement.height')
  @DocsEditable
  final AnimatedLength height;

  @DomName('SVGFEFloodElement.result')
  @DocsEditable
  final AnimatedString result;

  @DomName('SVGFEFloodElement.width')
  @DocsEditable
  final AnimatedLength width;

  @DomName('SVGFEFloodElement.x')
  @DocsEditable
  final AnimatedLength x;

  @DomName('SVGFEFloodElement.y')
  @DocsEditable
  final AnimatedLength y;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DomName('SVGFEFloodElement.getPresentationAttribute')
  @DocsEditable
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

  @DomName('SVGFEGaussianBlurElement.in1')
  @DocsEditable
  final AnimatedString in1;

  @DomName('SVGFEGaussianBlurElement.stdDeviationX')
  @DocsEditable
  final AnimatedNumber stdDeviationX;

  @DomName('SVGFEGaussianBlurElement.stdDeviationY')
  @DocsEditable
  final AnimatedNumber stdDeviationY;

  @DomName('SVGFEGaussianBlurElement.setStdDeviation')
  @DocsEditable
  void setStdDeviation(num stdDeviationX, num stdDeviationY) native;

  // From SVGFilterPrimitiveStandardAttributes

  @DomName('SVGFEGaussianBlurElement.height')
  @DocsEditable
  final AnimatedLength height;

  @DomName('SVGFEGaussianBlurElement.result')
  @DocsEditable
  final AnimatedString result;

  @DomName('SVGFEGaussianBlurElement.width')
  @DocsEditable
  final AnimatedLength width;

  @DomName('SVGFEGaussianBlurElement.x')
  @DocsEditable
  final AnimatedLength x;

  @DomName('SVGFEGaussianBlurElement.y')
  @DocsEditable
  final AnimatedLength y;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DomName('SVGFEGaussianBlurElement.getPresentationAttribute')
  @DocsEditable
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGFEImageElement')
class FEImageElement extends SvgElement implements FilterPrimitiveStandardAttributes, UriReference, ExternalResourcesRequired, LangSpace native "*SVGFEImageElement" {

  @DomName('SVGFEImageElement.preserveAspectRatio')
  @DocsEditable
  final AnimatedPreserveAspectRatio preserveAspectRatio;

  // From SVGExternalResourcesRequired

  @DomName('SVGFEImageElement.externalResourcesRequired')
  @DocsEditable
  final AnimatedBoolean externalResourcesRequired;

  // From SVGFilterPrimitiveStandardAttributes

  @DomName('SVGFEImageElement.height')
  @DocsEditable
  final AnimatedLength height;

  @DomName('SVGFEImageElement.result')
  @DocsEditable
  final AnimatedString result;

  @DomName('SVGFEImageElement.width')
  @DocsEditable
  final AnimatedLength width;

  @DomName('SVGFEImageElement.x')
  @DocsEditable
  final AnimatedLength x;

  @DomName('SVGFEImageElement.y')
  @DocsEditable
  final AnimatedLength y;

  // From SVGLangSpace

  @DomName('SVGFEImageElement.xmllang')
  @DocsEditable
  String xmllang;

  @DomName('SVGFEImageElement.xmlspace')
  @DocsEditable
  String xmlspace;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DomName('SVGFEImageElement.getPresentationAttribute')
  @DocsEditable
  CssValue getPresentationAttribute(String name) native;

  // From SVGURIReference

  @DomName('SVGFEImageElement.href')
  @DocsEditable
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGFEMergeElement')
class FEMergeElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEMergeElement" {

  // From SVGFilterPrimitiveStandardAttributes

  @DomName('SVGFEMergeElement.height')
  @DocsEditable
  final AnimatedLength height;

  @DomName('SVGFEMergeElement.result')
  @DocsEditable
  final AnimatedString result;

  @DomName('SVGFEMergeElement.width')
  @DocsEditable
  final AnimatedLength width;

  @DomName('SVGFEMergeElement.x')
  @DocsEditable
  final AnimatedLength x;

  @DomName('SVGFEMergeElement.y')
  @DocsEditable
  final AnimatedLength y;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DomName('SVGFEMergeElement.getPresentationAttribute')
  @DocsEditable
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGFEMergeNodeElement')
class FEMergeNodeElement extends SvgElement native "*SVGFEMergeNodeElement" {

  @DomName('SVGFEMergeNodeElement.in1')
  @DocsEditable
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

  @DomName('SVGFEMorphologyElement.in1')
  @DocsEditable
  final AnimatedString in1;

  @DomName('SVGFEMorphologyElement.operator')
  @DocsEditable
  final AnimatedEnumeration operator;

  @DomName('SVGFEMorphologyElement.radiusX')
  @DocsEditable
  final AnimatedNumber radiusX;

  @DomName('SVGFEMorphologyElement.radiusY')
  @DocsEditable
  final AnimatedNumber radiusY;

  @DomName('SVGFEMorphologyElement.setRadius')
  @DocsEditable
  void setRadius(num radiusX, num radiusY) native;

  // From SVGFilterPrimitiveStandardAttributes

  @DomName('SVGFEMorphologyElement.height')
  @DocsEditable
  final AnimatedLength height;

  @DomName('SVGFEMorphologyElement.result')
  @DocsEditable
  final AnimatedString result;

  @DomName('SVGFEMorphologyElement.width')
  @DocsEditable
  final AnimatedLength width;

  @DomName('SVGFEMorphologyElement.x')
  @DocsEditable
  final AnimatedLength x;

  @DomName('SVGFEMorphologyElement.y')
  @DocsEditable
  final AnimatedLength y;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DomName('SVGFEMorphologyElement.getPresentationAttribute')
  @DocsEditable
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGFEOffsetElement')
class FEOffsetElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFEOffsetElement" {

  @DomName('SVGFEOffsetElement.dx')
  @DocsEditable
  final AnimatedNumber dx;

  @DomName('SVGFEOffsetElement.dy')
  @DocsEditable
  final AnimatedNumber dy;

  @DomName('SVGFEOffsetElement.in1')
  @DocsEditable
  final AnimatedString in1;

  // From SVGFilterPrimitiveStandardAttributes

  @DomName('SVGFEOffsetElement.height')
  @DocsEditable
  final AnimatedLength height;

  @DomName('SVGFEOffsetElement.result')
  @DocsEditable
  final AnimatedString result;

  @DomName('SVGFEOffsetElement.width')
  @DocsEditable
  final AnimatedLength width;

  @DomName('SVGFEOffsetElement.x')
  @DocsEditable
  final AnimatedLength x;

  @DomName('SVGFEOffsetElement.y')
  @DocsEditable
  final AnimatedLength y;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DomName('SVGFEOffsetElement.getPresentationAttribute')
  @DocsEditable
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGFEPointLightElement')
class FEPointLightElement extends SvgElement native "*SVGFEPointLightElement" {

  @DomName('SVGFEPointLightElement.x')
  @DocsEditable
  final AnimatedNumber x;

  @DomName('SVGFEPointLightElement.y')
  @DocsEditable
  final AnimatedNumber y;

  @DomName('SVGFEPointLightElement.z')
  @DocsEditable
  final AnimatedNumber z;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGFESpecularLightingElement')
class FESpecularLightingElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFESpecularLightingElement" {

  @DomName('SVGFESpecularLightingElement.in1')
  @DocsEditable
  final AnimatedString in1;

  @DomName('SVGFESpecularLightingElement.specularConstant')
  @DocsEditable
  final AnimatedNumber specularConstant;

  @DomName('SVGFESpecularLightingElement.specularExponent')
  @DocsEditable
  final AnimatedNumber specularExponent;

  @DomName('SVGFESpecularLightingElement.surfaceScale')
  @DocsEditable
  final AnimatedNumber surfaceScale;

  // From SVGFilterPrimitiveStandardAttributes

  @DomName('SVGFESpecularLightingElement.height')
  @DocsEditable
  final AnimatedLength height;

  @DomName('SVGFESpecularLightingElement.result')
  @DocsEditable
  final AnimatedString result;

  @DomName('SVGFESpecularLightingElement.width')
  @DocsEditable
  final AnimatedLength width;

  @DomName('SVGFESpecularLightingElement.x')
  @DocsEditable
  final AnimatedLength x;

  @DomName('SVGFESpecularLightingElement.y')
  @DocsEditable
  final AnimatedLength y;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DomName('SVGFESpecularLightingElement.getPresentationAttribute')
  @DocsEditable
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGFESpotLightElement')
class FESpotLightElement extends SvgElement native "*SVGFESpotLightElement" {

  @DomName('SVGFESpotLightElement.limitingConeAngle')
  @DocsEditable
  final AnimatedNumber limitingConeAngle;

  @DomName('SVGFESpotLightElement.pointsAtX')
  @DocsEditable
  final AnimatedNumber pointsAtX;

  @DomName('SVGFESpotLightElement.pointsAtY')
  @DocsEditable
  final AnimatedNumber pointsAtY;

  @DomName('SVGFESpotLightElement.pointsAtZ')
  @DocsEditable
  final AnimatedNumber pointsAtZ;

  @DomName('SVGFESpotLightElement.specularExponent')
  @DocsEditable
  final AnimatedNumber specularExponent;

  @DomName('SVGFESpotLightElement.x')
  @DocsEditable
  final AnimatedNumber x;

  @DomName('SVGFESpotLightElement.y')
  @DocsEditable
  final AnimatedNumber y;

  @DomName('SVGFESpotLightElement.z')
  @DocsEditable
  final AnimatedNumber z;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGFETileElement')
class FETileElement extends SvgElement implements FilterPrimitiveStandardAttributes native "*SVGFETileElement" {

  @DomName('SVGFETileElement.in1')
  @DocsEditable
  final AnimatedString in1;

  // From SVGFilterPrimitiveStandardAttributes

  @DomName('SVGFETileElement.height')
  @DocsEditable
  final AnimatedLength height;

  @DomName('SVGFETileElement.result')
  @DocsEditable
  final AnimatedString result;

  @DomName('SVGFETileElement.width')
  @DocsEditable
  final AnimatedLength width;

  @DomName('SVGFETileElement.x')
  @DocsEditable
  final AnimatedLength x;

  @DomName('SVGFETileElement.y')
  @DocsEditable
  final AnimatedLength y;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DomName('SVGFETileElement.getPresentationAttribute')
  @DocsEditable
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

  @DomName('SVGFETurbulenceElement.baseFrequencyX')
  @DocsEditable
  final AnimatedNumber baseFrequencyX;

  @DomName('SVGFETurbulenceElement.baseFrequencyY')
  @DocsEditable
  final AnimatedNumber baseFrequencyY;

  @DomName('SVGFETurbulenceElement.numOctaves')
  @DocsEditable
  final AnimatedInteger numOctaves;

  @DomName('SVGFETurbulenceElement.seed')
  @DocsEditable
  final AnimatedNumber seed;

  @DomName('SVGFETurbulenceElement.stitchTiles')
  @DocsEditable
  final AnimatedEnumeration stitchTiles;

  @DomName('SVGFETurbulenceElement.type')
  @DocsEditable
  final AnimatedEnumeration type;

  // From SVGFilterPrimitiveStandardAttributes

  @DomName('SVGFETurbulenceElement.height')
  @DocsEditable
  final AnimatedLength height;

  @DomName('SVGFETurbulenceElement.result')
  @DocsEditable
  final AnimatedString result;

  @DomName('SVGFETurbulenceElement.width')
  @DocsEditable
  final AnimatedLength width;

  @DomName('SVGFETurbulenceElement.x')
  @DocsEditable
  final AnimatedLength x;

  @DomName('SVGFETurbulenceElement.y')
  @DocsEditable
  final AnimatedLength y;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DomName('SVGFETurbulenceElement.getPresentationAttribute')
  @DocsEditable
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

  @DomName('SVGFilterElement.filterResX')
  @DocsEditable
  final AnimatedInteger filterResX;

  @DomName('SVGFilterElement.filterResY')
  @DocsEditable
  final AnimatedInteger filterResY;

  @DomName('SVGFilterElement.filterUnits')
  @DocsEditable
  final AnimatedEnumeration filterUnits;

  @DomName('SVGFilterElement.height')
  @DocsEditable
  final AnimatedLength height;

  @DomName('SVGFilterElement.primitiveUnits')
  @DocsEditable
  final AnimatedEnumeration primitiveUnits;

  @DomName('SVGFilterElement.width')
  @DocsEditable
  final AnimatedLength width;

  @DomName('SVGFilterElement.x')
  @DocsEditable
  final AnimatedLength x;

  @DomName('SVGFilterElement.y')
  @DocsEditable
  final AnimatedLength y;

  @DomName('SVGFilterElement.setFilterRes')
  @DocsEditable
  void setFilterRes(int filterResX, int filterResY) native;

  // From SVGExternalResourcesRequired

  @DomName('SVGFilterElement.externalResourcesRequired')
  @DocsEditable
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  @DomName('SVGFilterElement.xmllang')
  @DocsEditable
  String xmllang;

  @DomName('SVGFilterElement.xmlspace')
  @DocsEditable
  String xmlspace;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DomName('SVGFilterElement.getPresentationAttribute')
  @DocsEditable
  CssValue getPresentationAttribute(String name) native;

  // From SVGURIReference

  @DomName('SVGFilterElement.href')
  @DocsEditable
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


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

  @DomName('SVGForeignObjectElement.height')
  @DocsEditable
  final AnimatedLength height;

  @DomName('SVGForeignObjectElement.width')
  @DocsEditable
  final AnimatedLength width;

  @DomName('SVGForeignObjectElement.x')
  @DocsEditable
  final AnimatedLength x;

  @DomName('SVGForeignObjectElement.y')
  @DocsEditable
  final AnimatedLength y;

  // From SVGExternalResourcesRequired

  @DomName('SVGForeignObjectElement.externalResourcesRequired')
  @DocsEditable
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  @DomName('SVGForeignObjectElement.xmllang')
  @DocsEditable
  String xmllang;

  @DomName('SVGForeignObjectElement.xmlspace')
  @DocsEditable
  String xmlspace;

  // From SVGLocatable

  @DomName('SVGForeignObjectElement.farthestViewportElement')
  @DocsEditable
  final SvgElement farthestViewportElement;

  @DomName('SVGForeignObjectElement.nearestViewportElement')
  @DocsEditable
  final SvgElement nearestViewportElement;

  @DomName('SVGForeignObjectElement.getBBox')
  @DocsEditable
  Rect getBBox() native;

  @JSName('getCTM')
  @DomName('SVGForeignObjectElement.getCTM')
  @DocsEditable
  Matrix getCtm() native;

  @JSName('getScreenCTM')
  @DomName('SVGForeignObjectElement.getScreenCTM')
  @DocsEditable
  Matrix getScreenCtm() native;

  @DomName('SVGForeignObjectElement.getTransformToElement')
  @DocsEditable
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DomName('SVGForeignObjectElement.getPresentationAttribute')
  @DocsEditable
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  @DomName('SVGForeignObjectElement.requiredExtensions')
  @DocsEditable
  final StringList requiredExtensions;

  @DomName('SVGForeignObjectElement.requiredFeatures')
  @DocsEditable
  final StringList requiredFeatures;

  @DomName('SVGForeignObjectElement.systemLanguage')
  @DocsEditable
  final StringList systemLanguage;

  @DomName('SVGForeignObjectElement.hasExtension')
  @DocsEditable
  bool hasExtension(String extension) native;

  // From SVGTransformable

  @DomName('SVGForeignObjectElement.transform')
  @DocsEditable
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

  @DomName('SVGGElement.externalResourcesRequired')
  @DocsEditable
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  @DomName('SVGGElement.xmllang')
  @DocsEditable
  String xmllang;

  @DomName('SVGGElement.xmlspace')
  @DocsEditable
  String xmlspace;

  // From SVGLocatable

  @DomName('SVGGElement.farthestViewportElement')
  @DocsEditable
  final SvgElement farthestViewportElement;

  @DomName('SVGGElement.nearestViewportElement')
  @DocsEditable
  final SvgElement nearestViewportElement;

  @DomName('SVGGElement.getBBox')
  @DocsEditable
  Rect getBBox() native;

  @JSName('getCTM')
  @DomName('SVGGElement.getCTM')
  @DocsEditable
  Matrix getCtm() native;

  @JSName('getScreenCTM')
  @DomName('SVGGElement.getScreenCTM')
  @DocsEditable
  Matrix getScreenCtm() native;

  @DomName('SVGGElement.getTransformToElement')
  @DocsEditable
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DomName('SVGGElement.getPresentationAttribute')
  @DocsEditable
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  @DomName('SVGGElement.requiredExtensions')
  @DocsEditable
  final StringList requiredExtensions;

  @DomName('SVGGElement.requiredFeatures')
  @DocsEditable
  final StringList requiredFeatures;

  @DomName('SVGGElement.systemLanguage')
  @DocsEditable
  final StringList systemLanguage;

  @DomName('SVGGElement.hasExtension')
  @DocsEditable
  bool hasExtension(String extension) native;

  // From SVGTransformable

  @DomName('SVGGElement.transform')
  @DocsEditable
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

  @DomName('SVGGlyphRefElement.dx')
  @DocsEditable
  num dx;

  @DomName('SVGGlyphRefElement.dy')
  @DocsEditable
  num dy;

  @DomName('SVGGlyphRefElement.format')
  @DocsEditable
  String format;

  @DomName('SVGGlyphRefElement.glyphRef')
  @DocsEditable
  String glyphRef;

  @DomName('SVGGlyphRefElement.x')
  @DocsEditable
  num x;

  @DomName('SVGGlyphRefElement.y')
  @DocsEditable
  num y;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DomName('SVGGlyphRefElement.getPresentationAttribute')
  @DocsEditable
  CssValue getPresentationAttribute(String name) native;

  // From SVGURIReference

  @DomName('SVGGlyphRefElement.href')
  @DocsEditable
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

  @DomName('SVGGradientElement.gradientTransform')
  @DocsEditable
  final AnimatedTransformList gradientTransform;

  @DomName('SVGGradientElement.gradientUnits')
  @DocsEditable
  final AnimatedEnumeration gradientUnits;

  @DomName('SVGGradientElement.spreadMethod')
  @DocsEditable
  final AnimatedEnumeration spreadMethod;

  // From SVGExternalResourcesRequired

  @DomName('SVGGradientElement.externalResourcesRequired')
  @DocsEditable
  final AnimatedBoolean externalResourcesRequired;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DomName('SVGGradientElement.getPresentationAttribute')
  @DocsEditable
  CssValue getPresentationAttribute(String name) native;

  // From SVGURIReference

  @DomName('SVGGradientElement.href')
  @DocsEditable
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

  @DomName('SVGImageElement.height')
  @DocsEditable
  final AnimatedLength height;

  @DomName('SVGImageElement.preserveAspectRatio')
  @DocsEditable
  final AnimatedPreserveAspectRatio preserveAspectRatio;

  @DomName('SVGImageElement.width')
  @DocsEditable
  final AnimatedLength width;

  @DomName('SVGImageElement.x')
  @DocsEditable
  final AnimatedLength x;

  @DomName('SVGImageElement.y')
  @DocsEditable
  final AnimatedLength y;

  // From SVGExternalResourcesRequired

  @DomName('SVGImageElement.externalResourcesRequired')
  @DocsEditable
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  @DomName('SVGImageElement.xmllang')
  @DocsEditable
  String xmllang;

  @DomName('SVGImageElement.xmlspace')
  @DocsEditable
  String xmlspace;

  // From SVGLocatable

  @DomName('SVGImageElement.farthestViewportElement')
  @DocsEditable
  final SvgElement farthestViewportElement;

  @DomName('SVGImageElement.nearestViewportElement')
  @DocsEditable
  final SvgElement nearestViewportElement;

  @DomName('SVGImageElement.getBBox')
  @DocsEditable
  Rect getBBox() native;

  @JSName('getCTM')
  @DomName('SVGImageElement.getCTM')
  @DocsEditable
  Matrix getCtm() native;

  @JSName('getScreenCTM')
  @DomName('SVGImageElement.getScreenCTM')
  @DocsEditable
  Matrix getScreenCtm() native;

  @DomName('SVGImageElement.getTransformToElement')
  @DocsEditable
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DomName('SVGImageElement.getPresentationAttribute')
  @DocsEditable
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  @DomName('SVGImageElement.requiredExtensions')
  @DocsEditable
  final StringList requiredExtensions;

  @DomName('SVGImageElement.requiredFeatures')
  @DocsEditable
  final StringList requiredFeatures;

  @DomName('SVGImageElement.systemLanguage')
  @DocsEditable
  final StringList systemLanguage;

  @DomName('SVGImageElement.hasExtension')
  @DocsEditable
  bool hasExtension(String extension) native;

  // From SVGTransformable

  @DomName('SVGImageElement.transform')
  @DocsEditable
  final AnimatedTransformList transform;

  // From SVGURIReference

  @DomName('SVGImageElement.href')
  @DocsEditable
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


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

  @DomName('SVGLength.unitType')
  @DocsEditable
  final int unitType;

  @DomName('SVGLength.value')
  @DocsEditable
  num value;

  @DomName('SVGLength.valueAsString')
  @DocsEditable
  String valueAsString;

  @DomName('SVGLength.valueInSpecifiedUnits')
  @DocsEditable
  num valueInSpecifiedUnits;

  @DomName('SVGLength.convertToSpecifiedUnits')
  @DocsEditable
  void convertToSpecifiedUnits(int unitType) native;

  @DomName('SVGLength.newValueSpecifiedUnits')
  @DocsEditable
  void newValueSpecifiedUnits(int unitType, num valueInSpecifiedUnits) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGLengthList')
class LengthList implements JavaScriptIndexingBehavior, List<Length> native "*SVGLengthList" {

  @DomName('SVGLengthList.numberOfItems')
  @DocsEditable
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

  String join([String separator]) =>
      IterableMixinWorkaround.joinList(this, separator);

  List mappedBy(f(Length element)) => IterableMixinWorkaround.mappedByList(this, f);

  Iterable<Length> where(bool f(Length element)) =>
      IterableMixinWorkaround.where(this, f);

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

  List<Length> get reversed =>
      new ReversedListView<Length>(this, 0, null);

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

  Length min([int compare(Length a, Length b)]) =>
      IterableMixinWorkaround.min(this, compare);

  Length max([int compare(Length a, Length b)]) =>
      IterableMixinWorkaround.max(this, compare);

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

  @DomName('SVGLengthList.appendItem')
  @DocsEditable
  Length appendItem(Length item) native;

  @DomName('SVGLengthList.clear')
  @DocsEditable
  void clear() native;

  @DomName('SVGLengthList.getItem')
  @DocsEditable
  Length getItem(int index) native;

  @DomName('SVGLengthList.initialize')
  @DocsEditable
  Length initialize(Length item) native;

  @DomName('SVGLengthList.insertItemBefore')
  @DocsEditable
  Length insertItemBefore(Length item, int index) native;

  @DomName('SVGLengthList.removeItem')
  @DocsEditable
  Length removeItem(int index) native;

  @DomName('SVGLengthList.replaceItem')
  @DocsEditable
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

  @DomName('SVGLineElement.x1')
  @DocsEditable
  final AnimatedLength x1;

  @DomName('SVGLineElement.x2')
  @DocsEditable
  final AnimatedLength x2;

  @DomName('SVGLineElement.y1')
  @DocsEditable
  final AnimatedLength y1;

  @DomName('SVGLineElement.y2')
  @DocsEditable
  final AnimatedLength y2;

  // From SVGExternalResourcesRequired

  @DomName('SVGLineElement.externalResourcesRequired')
  @DocsEditable
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  @DomName('SVGLineElement.xmllang')
  @DocsEditable
  String xmllang;

  @DomName('SVGLineElement.xmlspace')
  @DocsEditable
  String xmlspace;

  // From SVGLocatable

  @DomName('SVGLineElement.farthestViewportElement')
  @DocsEditable
  final SvgElement farthestViewportElement;

  @DomName('SVGLineElement.nearestViewportElement')
  @DocsEditable
  final SvgElement nearestViewportElement;

  @DomName('SVGLineElement.getBBox')
  @DocsEditable
  Rect getBBox() native;

  @JSName('getCTM')
  @DomName('SVGLineElement.getCTM')
  @DocsEditable
  Matrix getCtm() native;

  @JSName('getScreenCTM')
  @DomName('SVGLineElement.getScreenCTM')
  @DocsEditable
  Matrix getScreenCtm() native;

  @DomName('SVGLineElement.getTransformToElement')
  @DocsEditable
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DomName('SVGLineElement.getPresentationAttribute')
  @DocsEditable
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  @DomName('SVGLineElement.requiredExtensions')
  @DocsEditable
  final StringList requiredExtensions;

  @DomName('SVGLineElement.requiredFeatures')
  @DocsEditable
  final StringList requiredFeatures;

  @DomName('SVGLineElement.systemLanguage')
  @DocsEditable
  final StringList systemLanguage;

  @DomName('SVGLineElement.hasExtension')
  @DocsEditable
  bool hasExtension(String extension) native;

  // From SVGTransformable

  @DomName('SVGLineElement.transform')
  @DocsEditable
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

  @DomName('SVGLinearGradientElement.x1')
  @DocsEditable
  final AnimatedLength x1;

  @DomName('SVGLinearGradientElement.x2')
  @DocsEditable
  final AnimatedLength x2;

  @DomName('SVGLinearGradientElement.y1')
  @DocsEditable
  final AnimatedLength y1;

  @DomName('SVGLinearGradientElement.y2')
  @DocsEditable
  final AnimatedLength y2;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


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

  @DomName('SVGMPathElement.externalResourcesRequired')
  @DocsEditable
  final AnimatedBoolean externalResourcesRequired;

  // From SVGURIReference

  @DomName('SVGMPathElement.href')
  @DocsEditable
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

  @DomName('SVGMarkerElement.markerHeight')
  @DocsEditable
  final AnimatedLength markerHeight;

  @DomName('SVGMarkerElement.markerUnits')
  @DocsEditable
  final AnimatedEnumeration markerUnits;

  @DomName('SVGMarkerElement.markerWidth')
  @DocsEditable
  final AnimatedLength markerWidth;

  @DomName('SVGMarkerElement.orientAngle')
  @DocsEditable
  final AnimatedAngle orientAngle;

  @DomName('SVGMarkerElement.orientType')
  @DocsEditable
  final AnimatedEnumeration orientType;

  @DomName('SVGMarkerElement.refX')
  @DocsEditable
  final AnimatedLength refX;

  @DomName('SVGMarkerElement.refY')
  @DocsEditable
  final AnimatedLength refY;

  @DomName('SVGMarkerElement.setOrientToAngle')
  @DocsEditable
  void setOrientToAngle(Angle angle) native;

  @DomName('SVGMarkerElement.setOrientToAuto')
  @DocsEditable
  void setOrientToAuto() native;

  // From SVGExternalResourcesRequired

  @DomName('SVGMarkerElement.externalResourcesRequired')
  @DocsEditable
  final AnimatedBoolean externalResourcesRequired;

  // From SVGFitToViewBox

  @DomName('SVGMarkerElement.preserveAspectRatio')
  @DocsEditable
  final AnimatedPreserveAspectRatio preserveAspectRatio;

  @DomName('SVGMarkerElement.viewBox')
  @DocsEditable
  final AnimatedRect viewBox;

  // From SVGLangSpace

  @DomName('SVGMarkerElement.xmllang')
  @DocsEditable
  String xmllang;

  @DomName('SVGMarkerElement.xmlspace')
  @DocsEditable
  String xmlspace;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DomName('SVGMarkerElement.getPresentationAttribute')
  @DocsEditable
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

  @DomName('SVGMaskElement.height')
  @DocsEditable
  final AnimatedLength height;

  @DomName('SVGMaskElement.maskContentUnits')
  @DocsEditable
  final AnimatedEnumeration maskContentUnits;

  @DomName('SVGMaskElement.maskUnits')
  @DocsEditable
  final AnimatedEnumeration maskUnits;

  @DomName('SVGMaskElement.width')
  @DocsEditable
  final AnimatedLength width;

  @DomName('SVGMaskElement.x')
  @DocsEditable
  final AnimatedLength x;

  @DomName('SVGMaskElement.y')
  @DocsEditable
  final AnimatedLength y;

  // From SVGExternalResourcesRequired

  @DomName('SVGMaskElement.externalResourcesRequired')
  @DocsEditable
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  @DomName('SVGMaskElement.xmllang')
  @DocsEditable
  String xmllang;

  @DomName('SVGMaskElement.xmlspace')
  @DocsEditable
  String xmlspace;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DomName('SVGMaskElement.getPresentationAttribute')
  @DocsEditable
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  @DomName('SVGMaskElement.requiredExtensions')
  @DocsEditable
  final StringList requiredExtensions;

  @DomName('SVGMaskElement.requiredFeatures')
  @DocsEditable
  final StringList requiredFeatures;

  @DomName('SVGMaskElement.systemLanguage')
  @DocsEditable
  final StringList systemLanguage;

  @DomName('SVGMaskElement.hasExtension')
  @DocsEditable
  bool hasExtension(String extension) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGMatrix')
class Matrix native "*SVGMatrix" {

  @DomName('SVGMatrix.a')
  @DocsEditable
  num a;

  @DomName('SVGMatrix.b')
  @DocsEditable
  num b;

  @DomName('SVGMatrix.c')
  @DocsEditable
  num c;

  @DomName('SVGMatrix.d')
  @DocsEditable
  num d;

  @DomName('SVGMatrix.e')
  @DocsEditable
  num e;

  @DomName('SVGMatrix.f')
  @DocsEditable
  num f;

  @DomName('SVGMatrix.flipX')
  @DocsEditable
  Matrix flipX() native;

  @DomName('SVGMatrix.flipY')
  @DocsEditable
  Matrix flipY() native;

  @DomName('SVGMatrix.inverse')
  @DocsEditable
  Matrix inverse() native;

  @DomName('SVGMatrix.multiply')
  @DocsEditable
  Matrix multiply(Matrix secondMatrix) native;

  @DomName('SVGMatrix.rotate')
  @DocsEditable
  Matrix rotate(num angle) native;

  @DomName('SVGMatrix.rotateFromVector')
  @DocsEditable
  Matrix rotateFromVector(num x, num y) native;

  @DomName('SVGMatrix.scale')
  @DocsEditable
  Matrix scale(num scaleFactor) native;

  @DomName('SVGMatrix.scaleNonUniform')
  @DocsEditable
  Matrix scaleNonUniform(num scaleFactorX, num scaleFactorY) native;

  @DomName('SVGMatrix.skewX')
  @DocsEditable
  Matrix skewX(num angle) native;

  @DomName('SVGMatrix.skewY')
  @DocsEditable
  Matrix skewY(num angle) native;

  @DomName('SVGMatrix.translate')
  @DocsEditable
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

  @DomName('SVGNumber.value')
  @DocsEditable
  num value;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGNumberList')
class NumberList implements JavaScriptIndexingBehavior, List<Number> native "*SVGNumberList" {

  @DomName('SVGNumberList.numberOfItems')
  @DocsEditable
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

  String join([String separator]) =>
      IterableMixinWorkaround.joinList(this, separator);

  List mappedBy(f(Number element)) => IterableMixinWorkaround.mappedByList(this, f);

  Iterable<Number> where(bool f(Number element)) =>
      IterableMixinWorkaround.where(this, f);

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

  List<Number> get reversed =>
      new ReversedListView<Number>(this, 0, null);

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

  Number min([int compare(Number a, Number b)]) =>
      IterableMixinWorkaround.min(this, compare);

  Number max([int compare(Number a, Number b)]) =>
      IterableMixinWorkaround.max(this, compare);

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

  @DomName('SVGNumberList.appendItem')
  @DocsEditable
  Number appendItem(Number item) native;

  @DomName('SVGNumberList.clear')
  @DocsEditable
  void clear() native;

  @DomName('SVGNumberList.getItem')
  @DocsEditable
  Number getItem(int index) native;

  @DomName('SVGNumberList.initialize')
  @DocsEditable
  Number initialize(Number item) native;

  @DomName('SVGNumberList.insertItemBefore')
  @DocsEditable
  Number insertItemBefore(Number item, int index) native;

  @DomName('SVGNumberList.removeItem')
  @DocsEditable
  Number removeItem(int index) native;

  @DomName('SVGNumberList.replaceItem')
  @DocsEditable
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

  @DomName('SVGPaint.paintType')
  @DocsEditable
  final int paintType;

  @DomName('SVGPaint.uri')
  @DocsEditable
  final String uri;

  @DomName('SVGPaint.setPaint')
  @DocsEditable
  void setPaint(int paintType, String uri, String rgbColor, String iccColor) native;

  @DomName('SVGPaint.setUri')
  @DocsEditable
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

  @DomName('SVGPathElement.animatedNormalizedPathSegList')
  @DocsEditable
  final PathSegList animatedNormalizedPathSegList;

  @DomName('SVGPathElement.animatedPathSegList')
  @DocsEditable
  final PathSegList animatedPathSegList;

  @DomName('SVGPathElement.normalizedPathSegList')
  @DocsEditable
  final PathSegList normalizedPathSegList;

  @DomName('SVGPathElement.pathLength')
  @DocsEditable
  final AnimatedNumber pathLength;

  @DomName('SVGPathElement.pathSegList')
  @DocsEditable
  final PathSegList pathSegList;

  @JSName('createSVGPathSegArcAbs')
  @DomName('SVGPathElement.createSVGPathSegArcAbs')
  @DocsEditable
  PathSegArcAbs createSvgPathSegArcAbs(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) native;

  @JSName('createSVGPathSegArcRel')
  @DomName('SVGPathElement.createSVGPathSegArcRel')
  @DocsEditable
  PathSegArcRel createSvgPathSegArcRel(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) native;

  @JSName('createSVGPathSegClosePath')
  @DomName('SVGPathElement.createSVGPathSegClosePath')
  @DocsEditable
  PathSegClosePath createSvgPathSegClosePath() native;

  @JSName('createSVGPathSegCurvetoCubicAbs')
  @DomName('SVGPathElement.createSVGPathSegCurvetoCubicAbs')
  @DocsEditable
  PathSegCurvetoCubicAbs createSvgPathSegCurvetoCubicAbs(num x, num y, num x1, num y1, num x2, num y2) native;

  @JSName('createSVGPathSegCurvetoCubicRel')
  @DomName('SVGPathElement.createSVGPathSegCurvetoCubicRel')
  @DocsEditable
  PathSegCurvetoCubicRel createSvgPathSegCurvetoCubicRel(num x, num y, num x1, num y1, num x2, num y2) native;

  @JSName('createSVGPathSegCurvetoCubicSmoothAbs')
  @DomName('SVGPathElement.createSVGPathSegCurvetoCubicSmoothAbs')
  @DocsEditable
  PathSegCurvetoCubicSmoothAbs createSvgPathSegCurvetoCubicSmoothAbs(num x, num y, num x2, num y2) native;

  @JSName('createSVGPathSegCurvetoCubicSmoothRel')
  @DomName('SVGPathElement.createSVGPathSegCurvetoCubicSmoothRel')
  @DocsEditable
  PathSegCurvetoCubicSmoothRel createSvgPathSegCurvetoCubicSmoothRel(num x, num y, num x2, num y2) native;

  @JSName('createSVGPathSegCurvetoQuadraticAbs')
  @DomName('SVGPathElement.createSVGPathSegCurvetoQuadraticAbs')
  @DocsEditable
  PathSegCurvetoQuadraticAbs createSvgPathSegCurvetoQuadraticAbs(num x, num y, num x1, num y1) native;

  @JSName('createSVGPathSegCurvetoQuadraticRel')
  @DomName('SVGPathElement.createSVGPathSegCurvetoQuadraticRel')
  @DocsEditable
  PathSegCurvetoQuadraticRel createSvgPathSegCurvetoQuadraticRel(num x, num y, num x1, num y1) native;

  @JSName('createSVGPathSegCurvetoQuadraticSmoothAbs')
  @DomName('SVGPathElement.createSVGPathSegCurvetoQuadraticSmoothAbs')
  @DocsEditable
  PathSegCurvetoQuadraticSmoothAbs createSvgPathSegCurvetoQuadraticSmoothAbs(num x, num y) native;

  @JSName('createSVGPathSegCurvetoQuadraticSmoothRel')
  @DomName('SVGPathElement.createSVGPathSegCurvetoQuadraticSmoothRel')
  @DocsEditable
  PathSegCurvetoQuadraticSmoothRel createSvgPathSegCurvetoQuadraticSmoothRel(num x, num y) native;

  @JSName('createSVGPathSegLinetoAbs')
  @DomName('SVGPathElement.createSVGPathSegLinetoAbs')
  @DocsEditable
  PathSegLinetoAbs createSvgPathSegLinetoAbs(num x, num y) native;

  @JSName('createSVGPathSegLinetoHorizontalAbs')
  @DomName('SVGPathElement.createSVGPathSegLinetoHorizontalAbs')
  @DocsEditable
  PathSegLinetoHorizontalAbs createSvgPathSegLinetoHorizontalAbs(num x) native;

  @JSName('createSVGPathSegLinetoHorizontalRel')
  @DomName('SVGPathElement.createSVGPathSegLinetoHorizontalRel')
  @DocsEditable
  PathSegLinetoHorizontalRel createSvgPathSegLinetoHorizontalRel(num x) native;

  @JSName('createSVGPathSegLinetoRel')
  @DomName('SVGPathElement.createSVGPathSegLinetoRel')
  @DocsEditable
  PathSegLinetoRel createSvgPathSegLinetoRel(num x, num y) native;

  @JSName('createSVGPathSegLinetoVerticalAbs')
  @DomName('SVGPathElement.createSVGPathSegLinetoVerticalAbs')
  @DocsEditable
  PathSegLinetoVerticalAbs createSvgPathSegLinetoVerticalAbs(num y) native;

  @JSName('createSVGPathSegLinetoVerticalRel')
  @DomName('SVGPathElement.createSVGPathSegLinetoVerticalRel')
  @DocsEditable
  PathSegLinetoVerticalRel createSvgPathSegLinetoVerticalRel(num y) native;

  @JSName('createSVGPathSegMovetoAbs')
  @DomName('SVGPathElement.createSVGPathSegMovetoAbs')
  @DocsEditable
  PathSegMovetoAbs createSvgPathSegMovetoAbs(num x, num y) native;

  @JSName('createSVGPathSegMovetoRel')
  @DomName('SVGPathElement.createSVGPathSegMovetoRel')
  @DocsEditable
  PathSegMovetoRel createSvgPathSegMovetoRel(num x, num y) native;

  @DomName('SVGPathElement.getPathSegAtLength')
  @DocsEditable
  int getPathSegAtLength(num distance) native;

  @DomName('SVGPathElement.getPointAtLength')
  @DocsEditable
  Point getPointAtLength(num distance) native;

  @DomName('SVGPathElement.getTotalLength')
  @DocsEditable
  num getTotalLength() native;

  // From SVGExternalResourcesRequired

  @DomName('SVGPathElement.externalResourcesRequired')
  @DocsEditable
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  @DomName('SVGPathElement.xmllang')
  @DocsEditable
  String xmllang;

  @DomName('SVGPathElement.xmlspace')
  @DocsEditable
  String xmlspace;

  // From SVGLocatable

  @DomName('SVGPathElement.farthestViewportElement')
  @DocsEditable
  final SvgElement farthestViewportElement;

  @DomName('SVGPathElement.nearestViewportElement')
  @DocsEditable
  final SvgElement nearestViewportElement;

  @DomName('SVGPathElement.getBBox')
  @DocsEditable
  Rect getBBox() native;

  @JSName('getCTM')
  @DomName('SVGPathElement.getCTM')
  @DocsEditable
  Matrix getCtm() native;

  @JSName('getScreenCTM')
  @DomName('SVGPathElement.getScreenCTM')
  @DocsEditable
  Matrix getScreenCtm() native;

  @DomName('SVGPathElement.getTransformToElement')
  @DocsEditable
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DomName('SVGPathElement.getPresentationAttribute')
  @DocsEditable
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  @DomName('SVGPathElement.requiredExtensions')
  @DocsEditable
  final StringList requiredExtensions;

  @DomName('SVGPathElement.requiredFeatures')
  @DocsEditable
  final StringList requiredFeatures;

  @DomName('SVGPathElement.systemLanguage')
  @DocsEditable
  final StringList systemLanguage;

  @DomName('SVGPathElement.hasExtension')
  @DocsEditable
  bool hasExtension(String extension) native;

  // From SVGTransformable

  @DomName('SVGPathElement.transform')
  @DocsEditable
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

  @DomName('SVGPathSeg.pathSegType')
  @DocsEditable
  final int pathSegType;

  @DomName('SVGPathSeg.pathSegTypeAsLetter')
  @DocsEditable
  final String pathSegTypeAsLetter;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGPathSegArcAbs')
class PathSegArcAbs extends PathSeg native "*SVGPathSegArcAbs" {

  @DomName('SVGPathSegArcAbs.angle')
  @DocsEditable
  num angle;

  @DomName('SVGPathSegArcAbs.largeArcFlag')
  @DocsEditable
  bool largeArcFlag;

  @DomName('SVGPathSegArcAbs.r1')
  @DocsEditable
  num r1;

  @DomName('SVGPathSegArcAbs.r2')
  @DocsEditable
  num r2;

  @DomName('SVGPathSegArcAbs.sweepFlag')
  @DocsEditable
  bool sweepFlag;

  @DomName('SVGPathSegArcAbs.x')
  @DocsEditable
  num x;

  @DomName('SVGPathSegArcAbs.y')
  @DocsEditable
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGPathSegArcRel')
class PathSegArcRel extends PathSeg native "*SVGPathSegArcRel" {

  @DomName('SVGPathSegArcRel.angle')
  @DocsEditable
  num angle;

  @DomName('SVGPathSegArcRel.largeArcFlag')
  @DocsEditable
  bool largeArcFlag;

  @DomName('SVGPathSegArcRel.r1')
  @DocsEditable
  num r1;

  @DomName('SVGPathSegArcRel.r2')
  @DocsEditable
  num r2;

  @DomName('SVGPathSegArcRel.sweepFlag')
  @DocsEditable
  bool sweepFlag;

  @DomName('SVGPathSegArcRel.x')
  @DocsEditable
  num x;

  @DomName('SVGPathSegArcRel.y')
  @DocsEditable
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

  @DomName('SVGPathSegCurvetoCubicAbs.x')
  @DocsEditable
  num x;

  @DomName('SVGPathSegCurvetoCubicAbs.x1')
  @DocsEditable
  num x1;

  @DomName('SVGPathSegCurvetoCubicAbs.x2')
  @DocsEditable
  num x2;

  @DomName('SVGPathSegCurvetoCubicAbs.y')
  @DocsEditable
  num y;

  @DomName('SVGPathSegCurvetoCubicAbs.y1')
  @DocsEditable
  num y1;

  @DomName('SVGPathSegCurvetoCubicAbs.y2')
  @DocsEditable
  num y2;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGPathSegCurvetoCubicRel')
class PathSegCurvetoCubicRel extends PathSeg native "*SVGPathSegCurvetoCubicRel" {

  @DomName('SVGPathSegCurvetoCubicRel.x')
  @DocsEditable
  num x;

  @DomName('SVGPathSegCurvetoCubicRel.x1')
  @DocsEditable
  num x1;

  @DomName('SVGPathSegCurvetoCubicRel.x2')
  @DocsEditable
  num x2;

  @DomName('SVGPathSegCurvetoCubicRel.y')
  @DocsEditable
  num y;

  @DomName('SVGPathSegCurvetoCubicRel.y1')
  @DocsEditable
  num y1;

  @DomName('SVGPathSegCurvetoCubicRel.y2')
  @DocsEditable
  num y2;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGPathSegCurvetoCubicSmoothAbs')
class PathSegCurvetoCubicSmoothAbs extends PathSeg native "*SVGPathSegCurvetoCubicSmoothAbs" {

  @DomName('SVGPathSegCurvetoCubicSmoothAbs.x')
  @DocsEditable
  num x;

  @DomName('SVGPathSegCurvetoCubicSmoothAbs.x2')
  @DocsEditable
  num x2;

  @DomName('SVGPathSegCurvetoCubicSmoothAbs.y')
  @DocsEditable
  num y;

  @DomName('SVGPathSegCurvetoCubicSmoothAbs.y2')
  @DocsEditable
  num y2;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGPathSegCurvetoCubicSmoothRel')
class PathSegCurvetoCubicSmoothRel extends PathSeg native "*SVGPathSegCurvetoCubicSmoothRel" {

  @DomName('SVGPathSegCurvetoCubicSmoothRel.x')
  @DocsEditable
  num x;

  @DomName('SVGPathSegCurvetoCubicSmoothRel.x2')
  @DocsEditable
  num x2;

  @DomName('SVGPathSegCurvetoCubicSmoothRel.y')
  @DocsEditable
  num y;

  @DomName('SVGPathSegCurvetoCubicSmoothRel.y2')
  @DocsEditable
  num y2;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGPathSegCurvetoQuadraticAbs')
class PathSegCurvetoQuadraticAbs extends PathSeg native "*SVGPathSegCurvetoQuadraticAbs" {

  @DomName('SVGPathSegCurvetoQuadraticAbs.x')
  @DocsEditable
  num x;

  @DomName('SVGPathSegCurvetoQuadraticAbs.x1')
  @DocsEditable
  num x1;

  @DomName('SVGPathSegCurvetoQuadraticAbs.y')
  @DocsEditable
  num y;

  @DomName('SVGPathSegCurvetoQuadraticAbs.y1')
  @DocsEditable
  num y1;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGPathSegCurvetoQuadraticRel')
class PathSegCurvetoQuadraticRel extends PathSeg native "*SVGPathSegCurvetoQuadraticRel" {

  @DomName('SVGPathSegCurvetoQuadraticRel.x')
  @DocsEditable
  num x;

  @DomName('SVGPathSegCurvetoQuadraticRel.x1')
  @DocsEditable
  num x1;

  @DomName('SVGPathSegCurvetoQuadraticRel.y')
  @DocsEditable
  num y;

  @DomName('SVGPathSegCurvetoQuadraticRel.y1')
  @DocsEditable
  num y1;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGPathSegCurvetoQuadraticSmoothAbs')
class PathSegCurvetoQuadraticSmoothAbs extends PathSeg native "*SVGPathSegCurvetoQuadraticSmoothAbs" {

  @DomName('SVGPathSegCurvetoQuadraticSmoothAbs.x')
  @DocsEditable
  num x;

  @DomName('SVGPathSegCurvetoQuadraticSmoothAbs.y')
  @DocsEditable
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGPathSegCurvetoQuadraticSmoothRel')
class PathSegCurvetoQuadraticSmoothRel extends PathSeg native "*SVGPathSegCurvetoQuadraticSmoothRel" {

  @DomName('SVGPathSegCurvetoQuadraticSmoothRel.x')
  @DocsEditable
  num x;

  @DomName('SVGPathSegCurvetoQuadraticSmoothRel.y')
  @DocsEditable
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGPathSegLinetoAbs')
class PathSegLinetoAbs extends PathSeg native "*SVGPathSegLinetoAbs" {

  @DomName('SVGPathSegLinetoAbs.x')
  @DocsEditable
  num x;

  @DomName('SVGPathSegLinetoAbs.y')
  @DocsEditable
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGPathSegLinetoHorizontalAbs')
class PathSegLinetoHorizontalAbs extends PathSeg native "*SVGPathSegLinetoHorizontalAbs" {

  @DomName('SVGPathSegLinetoHorizontalAbs.x')
  @DocsEditable
  num x;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGPathSegLinetoHorizontalRel')
class PathSegLinetoHorizontalRel extends PathSeg native "*SVGPathSegLinetoHorizontalRel" {

  @DomName('SVGPathSegLinetoHorizontalRel.x')
  @DocsEditable
  num x;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGPathSegLinetoRel')
class PathSegLinetoRel extends PathSeg native "*SVGPathSegLinetoRel" {

  @DomName('SVGPathSegLinetoRel.x')
  @DocsEditable
  num x;

  @DomName('SVGPathSegLinetoRel.y')
  @DocsEditable
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGPathSegLinetoVerticalAbs')
class PathSegLinetoVerticalAbs extends PathSeg native "*SVGPathSegLinetoVerticalAbs" {

  @DomName('SVGPathSegLinetoVerticalAbs.y')
  @DocsEditable
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGPathSegLinetoVerticalRel')
class PathSegLinetoVerticalRel extends PathSeg native "*SVGPathSegLinetoVerticalRel" {

  @DomName('SVGPathSegLinetoVerticalRel.y')
  @DocsEditable
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGPathSegList')
class PathSegList implements JavaScriptIndexingBehavior, List<PathSeg> native "*SVGPathSegList" {

  @DomName('SVGPathSegList.numberOfItems')
  @DocsEditable
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

  String join([String separator]) =>
      IterableMixinWorkaround.joinList(this, separator);

  List mappedBy(f(PathSeg element)) => IterableMixinWorkaround.mappedByList(this, f);

  Iterable<PathSeg> where(bool f(PathSeg element)) =>
      IterableMixinWorkaround.where(this, f);

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

  List<PathSeg> get reversed =>
      new ReversedListView<PathSeg>(this, 0, null);

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

  PathSeg min([int compare(PathSeg a, PathSeg b)]) =>
      IterableMixinWorkaround.min(this, compare);

  PathSeg max([int compare(PathSeg a, PathSeg b)]) =>
      IterableMixinWorkaround.max(this, compare);

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

  @DomName('SVGPathSegList.appendItem')
  @DocsEditable
  PathSeg appendItem(PathSeg newItem) native;

  @DomName('SVGPathSegList.clear')
  @DocsEditable
  void clear() native;

  @DomName('SVGPathSegList.getItem')
  @DocsEditable
  PathSeg getItem(int index) native;

  @DomName('SVGPathSegList.initialize')
  @DocsEditable
  PathSeg initialize(PathSeg newItem) native;

  @DomName('SVGPathSegList.insertItemBefore')
  @DocsEditable
  PathSeg insertItemBefore(PathSeg newItem, int index) native;

  @DomName('SVGPathSegList.removeItem')
  @DocsEditable
  PathSeg removeItem(int index) native;

  @DomName('SVGPathSegList.replaceItem')
  @DocsEditable
  PathSeg replaceItem(PathSeg newItem, int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGPathSegMovetoAbs')
class PathSegMovetoAbs extends PathSeg native "*SVGPathSegMovetoAbs" {

  @DomName('SVGPathSegMovetoAbs.x')
  @DocsEditable
  num x;

  @DomName('SVGPathSegMovetoAbs.y')
  @DocsEditable
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGPathSegMovetoRel')
class PathSegMovetoRel extends PathSeg native "*SVGPathSegMovetoRel" {

  @DomName('SVGPathSegMovetoRel.x')
  @DocsEditable
  num x;

  @DomName('SVGPathSegMovetoRel.y')
  @DocsEditable
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

  @DomName('SVGPatternElement.height')
  @DocsEditable
  final AnimatedLength height;

  @DomName('SVGPatternElement.patternContentUnits')
  @DocsEditable
  final AnimatedEnumeration patternContentUnits;

  @DomName('SVGPatternElement.patternTransform')
  @DocsEditable
  final AnimatedTransformList patternTransform;

  @DomName('SVGPatternElement.patternUnits')
  @DocsEditable
  final AnimatedEnumeration patternUnits;

  @DomName('SVGPatternElement.width')
  @DocsEditable
  final AnimatedLength width;

  @DomName('SVGPatternElement.x')
  @DocsEditable
  final AnimatedLength x;

  @DomName('SVGPatternElement.y')
  @DocsEditable
  final AnimatedLength y;

  // From SVGExternalResourcesRequired

  @DomName('SVGPatternElement.externalResourcesRequired')
  @DocsEditable
  final AnimatedBoolean externalResourcesRequired;

  // From SVGFitToViewBox

  @DomName('SVGPatternElement.preserveAspectRatio')
  @DocsEditable
  final AnimatedPreserveAspectRatio preserveAspectRatio;

  @DomName('SVGPatternElement.viewBox')
  @DocsEditable
  final AnimatedRect viewBox;

  // From SVGLangSpace

  @DomName('SVGPatternElement.xmllang')
  @DocsEditable
  String xmllang;

  @DomName('SVGPatternElement.xmlspace')
  @DocsEditable
  String xmlspace;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DomName('SVGPatternElement.getPresentationAttribute')
  @DocsEditable
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  @DomName('SVGPatternElement.requiredExtensions')
  @DocsEditable
  final StringList requiredExtensions;

  @DomName('SVGPatternElement.requiredFeatures')
  @DocsEditable
  final StringList requiredFeatures;

  @DomName('SVGPatternElement.systemLanguage')
  @DocsEditable
  final StringList systemLanguage;

  @DomName('SVGPatternElement.hasExtension')
  @DocsEditable
  bool hasExtension(String extension) native;

  // From SVGURIReference

  @DomName('SVGPatternElement.href')
  @DocsEditable
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGPoint')
class Point native "*SVGPoint" {

  @DomName('SVGPoint.x')
  @DocsEditable
  num x;

  @DomName('SVGPoint.y')
  @DocsEditable
  num y;

  @DomName('SVGPoint.matrixTransform')
  @DocsEditable
  Point matrixTransform(Matrix matrix) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGPointList')
class PointList native "*SVGPointList" {

  @DomName('SVGPointList.numberOfItems')
  @DocsEditable
  final int numberOfItems;

  @DomName('SVGPointList.appendItem')
  @DocsEditable
  Point appendItem(Point item) native;

  @DomName('SVGPointList.clear')
  @DocsEditable
  void clear() native;

  @DomName('SVGPointList.getItem')
  @DocsEditable
  Point getItem(int index) native;

  @DomName('SVGPointList.initialize')
  @DocsEditable
  Point initialize(Point item) native;

  @DomName('SVGPointList.insertItemBefore')
  @DocsEditable
  Point insertItemBefore(Point item, int index) native;

  @DomName('SVGPointList.removeItem')
  @DocsEditable
  Point removeItem(int index) native;

  @DomName('SVGPointList.replaceItem')
  @DocsEditable
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

  @DomName('SVGPolygonElement.animatedPoints')
  @DocsEditable
  final PointList animatedPoints;

  @DomName('SVGPolygonElement.points')
  @DocsEditable
  final PointList points;

  // From SVGExternalResourcesRequired

  @DomName('SVGPolygonElement.externalResourcesRequired')
  @DocsEditable
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  @DomName('SVGPolygonElement.xmllang')
  @DocsEditable
  String xmllang;

  @DomName('SVGPolygonElement.xmlspace')
  @DocsEditable
  String xmlspace;

  // From SVGLocatable

  @DomName('SVGPolygonElement.farthestViewportElement')
  @DocsEditable
  final SvgElement farthestViewportElement;

  @DomName('SVGPolygonElement.nearestViewportElement')
  @DocsEditable
  final SvgElement nearestViewportElement;

  @DomName('SVGPolygonElement.getBBox')
  @DocsEditable
  Rect getBBox() native;

  @JSName('getCTM')
  @DomName('SVGPolygonElement.getCTM')
  @DocsEditable
  Matrix getCtm() native;

  @JSName('getScreenCTM')
  @DomName('SVGPolygonElement.getScreenCTM')
  @DocsEditable
  Matrix getScreenCtm() native;

  @DomName('SVGPolygonElement.getTransformToElement')
  @DocsEditable
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DomName('SVGPolygonElement.getPresentationAttribute')
  @DocsEditable
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  @DomName('SVGPolygonElement.requiredExtensions')
  @DocsEditable
  final StringList requiredExtensions;

  @DomName('SVGPolygonElement.requiredFeatures')
  @DocsEditable
  final StringList requiredFeatures;

  @DomName('SVGPolygonElement.systemLanguage')
  @DocsEditable
  final StringList systemLanguage;

  @DomName('SVGPolygonElement.hasExtension')
  @DocsEditable
  bool hasExtension(String extension) native;

  // From SVGTransformable

  @DomName('SVGPolygonElement.transform')
  @DocsEditable
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

  @DomName('SVGPolylineElement.animatedPoints')
  @DocsEditable
  final PointList animatedPoints;

  @DomName('SVGPolylineElement.points')
  @DocsEditable
  final PointList points;

  // From SVGExternalResourcesRequired

  @DomName('SVGPolylineElement.externalResourcesRequired')
  @DocsEditable
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  @DomName('SVGPolylineElement.xmllang')
  @DocsEditable
  String xmllang;

  @DomName('SVGPolylineElement.xmlspace')
  @DocsEditable
  String xmlspace;

  // From SVGLocatable

  @DomName('SVGPolylineElement.farthestViewportElement')
  @DocsEditable
  final SvgElement farthestViewportElement;

  @DomName('SVGPolylineElement.nearestViewportElement')
  @DocsEditable
  final SvgElement nearestViewportElement;

  @DomName('SVGPolylineElement.getBBox')
  @DocsEditable
  Rect getBBox() native;

  @JSName('getCTM')
  @DomName('SVGPolylineElement.getCTM')
  @DocsEditable
  Matrix getCtm() native;

  @JSName('getScreenCTM')
  @DomName('SVGPolylineElement.getScreenCTM')
  @DocsEditable
  Matrix getScreenCtm() native;

  @DomName('SVGPolylineElement.getTransformToElement')
  @DocsEditable
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DomName('SVGPolylineElement.getPresentationAttribute')
  @DocsEditable
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  @DomName('SVGPolylineElement.requiredExtensions')
  @DocsEditable
  final StringList requiredExtensions;

  @DomName('SVGPolylineElement.requiredFeatures')
  @DocsEditable
  final StringList requiredFeatures;

  @DomName('SVGPolylineElement.systemLanguage')
  @DocsEditable
  final StringList systemLanguage;

  @DomName('SVGPolylineElement.hasExtension')
  @DocsEditable
  bool hasExtension(String extension) native;

  // From SVGTransformable

  @DomName('SVGPolylineElement.transform')
  @DocsEditable
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

  @DomName('SVGPreserveAspectRatio.align')
  @DocsEditable
  int align;

  @DomName('SVGPreserveAspectRatio.meetOrSlice')
  @DocsEditable
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

  @DomName('SVGRadialGradientElement.cx')
  @DocsEditable
  final AnimatedLength cx;

  @DomName('SVGRadialGradientElement.cy')
  @DocsEditable
  final AnimatedLength cy;

  @DomName('SVGRadialGradientElement.fr')
  @DocsEditable
  final AnimatedLength fr;

  @DomName('SVGRadialGradientElement.fx')
  @DocsEditable
  final AnimatedLength fx;

  @DomName('SVGRadialGradientElement.fy')
  @DocsEditable
  final AnimatedLength fy;

  @DomName('SVGRadialGradientElement.r')
  @DocsEditable
  final AnimatedLength r;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGRect')
class Rect native "*SVGRect" {

  @DomName('SVGRect.height')
  @DocsEditable
  num height;

  @DomName('SVGRect.width')
  @DocsEditable
  num width;

  @DomName('SVGRect.x')
  @DocsEditable
  num x;

  @DomName('SVGRect.y')
  @DocsEditable
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

  @DomName('SVGRectElement.height')
  @DocsEditable
  final AnimatedLength height;

  @DomName('SVGRectElement.rx')
  @DocsEditable
  final AnimatedLength rx;

  @DomName('SVGRectElement.ry')
  @DocsEditable
  final AnimatedLength ry;

  @DomName('SVGRectElement.width')
  @DocsEditable
  final AnimatedLength width;

  @DomName('SVGRectElement.x')
  @DocsEditable
  final AnimatedLength x;

  @DomName('SVGRectElement.y')
  @DocsEditable
  final AnimatedLength y;

  // From SVGExternalResourcesRequired

  @DomName('SVGRectElement.externalResourcesRequired')
  @DocsEditable
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  @DomName('SVGRectElement.xmllang')
  @DocsEditable
  String xmllang;

  @DomName('SVGRectElement.xmlspace')
  @DocsEditable
  String xmlspace;

  // From SVGLocatable

  @DomName('SVGRectElement.farthestViewportElement')
  @DocsEditable
  final SvgElement farthestViewportElement;

  @DomName('SVGRectElement.nearestViewportElement')
  @DocsEditable
  final SvgElement nearestViewportElement;

  @DomName('SVGRectElement.getBBox')
  @DocsEditable
  Rect getBBox() native;

  @JSName('getCTM')
  @DomName('SVGRectElement.getCTM')
  @DocsEditable
  Matrix getCtm() native;

  @JSName('getScreenCTM')
  @DomName('SVGRectElement.getScreenCTM')
  @DocsEditable
  Matrix getScreenCtm() native;

  @DomName('SVGRectElement.getTransformToElement')
  @DocsEditable
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DomName('SVGRectElement.getPresentationAttribute')
  @DocsEditable
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  @DomName('SVGRectElement.requiredExtensions')
  @DocsEditable
  final StringList requiredExtensions;

  @DomName('SVGRectElement.requiredFeatures')
  @DocsEditable
  final StringList requiredFeatures;

  @DomName('SVGRectElement.systemLanguage')
  @DocsEditable
  final StringList systemLanguage;

  @DomName('SVGRectElement.hasExtension')
  @DocsEditable
  bool hasExtension(String extension) native;

  // From SVGTransformable

  @DomName('SVGRectElement.transform')
  @DocsEditable
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

  @DomName('SVGScriptElement.type')
  @DocsEditable
  String type;

  // From SVGExternalResourcesRequired

  @DomName('SVGScriptElement.externalResourcesRequired')
  @DocsEditable
  final AnimatedBoolean externalResourcesRequired;

  // From SVGURIReference

  @DomName('SVGScriptElement.href')
  @DocsEditable
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

  @DomName('SVGStopElement.offset')
  @DocsEditable
  final AnimatedNumber offset;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DomName('SVGStopElement.getPresentationAttribute')
  @DocsEditable
  CssValue getPresentationAttribute(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGStringList')
class StringList implements JavaScriptIndexingBehavior, List<String> native "*SVGStringList" {

  @DomName('SVGStringList.numberOfItems')
  @DocsEditable
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

  String join([String separator]) =>
      IterableMixinWorkaround.joinList(this, separator);

  List mappedBy(f(String element)) => IterableMixinWorkaround.mappedByList(this, f);

  Iterable<String> where(bool f(String element)) =>
      IterableMixinWorkaround.where(this, f);

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

  List<String> get reversed =>
      new ReversedListView<String>(this, 0, null);

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

  String min([int compare(String a, String b)]) =>
      IterableMixinWorkaround.min(this, compare);

  String max([int compare(String a, String b)]) =>
      IterableMixinWorkaround.max(this, compare);

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

  @DomName('SVGStringList.appendItem')
  @DocsEditable
  String appendItem(String item) native;

  @DomName('SVGStringList.clear')
  @DocsEditable
  void clear() native;

  @DomName('SVGStringList.getItem')
  @DocsEditable
  String getItem(int index) native;

  @DomName('SVGStringList.initialize')
  @DocsEditable
  String initialize(String item) native;

  @DomName('SVGStringList.insertItemBefore')
  @DocsEditable
  String insertItemBefore(String item, int index) native;

  @DomName('SVGStringList.removeItem')
  @DocsEditable
  String removeItem(int index) native;

  @DomName('SVGStringList.replaceItem')
  @DocsEditable
  String replaceItem(String item, int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


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

  @DomName('SVGStyleElement.disabled')
  @DocsEditable
  bool disabled;

  @DomName('SVGStyleElement.media')
  @DocsEditable
  String media;

  // Shadowing definition.
  String get title => JS("String", "#.title", this);

  void set title(String value) {
    JS("void", "#.title = #", this, value);
  }

  @DomName('SVGStyleElement.type')
  @DocsEditable
  String type;

  // From SVGLangSpace

  @DomName('SVGStyleElement.xmllang')
  @DocsEditable
  String xmllang;

  @DomName('SVGStyleElement.xmlspace')
  @DocsEditable
  String xmlspace;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGDocument')
class SvgDocument extends Document native "*SVGDocument" {

  @DomName('SVGDocument.rootElement')
  @DocsEditable
  final SvgSvgElement rootElement;

  @JSName('createEvent')
  @DomName('SVGDocument.createEvent')
  @DocsEditable
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
  String get id => JS("String", "#.id", this);

  void set id(String value) {
    JS("void", "#.id = #", this, value);
  }

  @JSName('ownerSVGElement')
  @DomName('SVGElement.ownerSVGElement')
  @DocsEditable
  final SvgSvgElement ownerSvgElement;

  @DomName('SVGElement.viewportElement')
  @DocsEditable
  final SvgElement viewportElement;

  @DomName('SVGElement.xmlbase')
  @DocsEditable
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

  @DomName('SVGException.code')
  @DocsEditable
  final int code;

  @DomName('SVGException.message')
  @DocsEditable
  final String message;

  @DomName('SVGException.name')
  @DocsEditable
  final String name;

  @DomName('SVGException.toString')
  @DocsEditable
  String toString() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('SVGSVGElement')
class SvgSvgElement extends SvgElement implements FitToViewBox, Tests, Stylable, Locatable, ExternalResourcesRequired, ZoomAndPan, LangSpace native "*SVGSVGElement" {
  factory SvgSvgElement() => _SvgSvgElementFactoryProvider.createSvgSvgElement();


  @DomName('SVGSVGElement.contentScriptType')
  @DocsEditable
  String contentScriptType;

  @DomName('SVGSVGElement.contentStyleType')
  @DocsEditable
  String contentStyleType;

  @DomName('SVGSVGElement.currentScale')
  @DocsEditable
  num currentScale;

  @DomName('SVGSVGElement.currentTranslate')
  @DocsEditable
  final Point currentTranslate;

  @DomName('SVGSVGElement.currentView')
  @DocsEditable
  final ViewSpec currentView;

  @DomName('SVGSVGElement.height')
  @DocsEditable
  final AnimatedLength height;

  @DomName('SVGSVGElement.pixelUnitToMillimeterX')
  @DocsEditable
  final num pixelUnitToMillimeterX;

  @DomName('SVGSVGElement.pixelUnitToMillimeterY')
  @DocsEditable
  final num pixelUnitToMillimeterY;

  @DomName('SVGSVGElement.screenPixelToMillimeterX')
  @DocsEditable
  final num screenPixelToMillimeterX;

  @DomName('SVGSVGElement.screenPixelToMillimeterY')
  @DocsEditable
  final num screenPixelToMillimeterY;

  @DomName('SVGSVGElement.useCurrentView')
  @DocsEditable
  final bool useCurrentView;

  @DomName('SVGSVGElement.viewport')
  @DocsEditable
  final Rect viewport;

  @DomName('SVGSVGElement.width')
  @DocsEditable
  final AnimatedLength width;

  @DomName('SVGSVGElement.x')
  @DocsEditable
  final AnimatedLength x;

  @DomName('SVGSVGElement.y')
  @DocsEditable
  final AnimatedLength y;

  @DomName('SVGSVGElement.animationsPaused')
  @DocsEditable
  bool animationsPaused() native;

  @DomName('SVGSVGElement.checkEnclosure')
  @DocsEditable
  bool checkEnclosure(SvgElement element, Rect rect) native;

  @DomName('SVGSVGElement.checkIntersection')
  @DocsEditable
  bool checkIntersection(SvgElement element, Rect rect) native;

  @JSName('createSVGAngle')
  @DomName('SVGSVGElement.createSVGAngle')
  @DocsEditable
  Angle createSvgAngle() native;

  @JSName('createSVGLength')
  @DomName('SVGSVGElement.createSVGLength')
  @DocsEditable
  Length createSvgLength() native;

  @JSName('createSVGMatrix')
  @DomName('SVGSVGElement.createSVGMatrix')
  @DocsEditable
  Matrix createSvgMatrix() native;

  @JSName('createSVGNumber')
  @DomName('SVGSVGElement.createSVGNumber')
  @DocsEditable
  Number createSvgNumber() native;

  @JSName('createSVGPoint')
  @DomName('SVGSVGElement.createSVGPoint')
  @DocsEditable
  Point createSvgPoint() native;

  @JSName('createSVGRect')
  @DomName('SVGSVGElement.createSVGRect')
  @DocsEditable
  Rect createSvgRect() native;

  @JSName('createSVGTransform')
  @DomName('SVGSVGElement.createSVGTransform')
  @DocsEditable
  Transform createSvgTransform() native;

  @JSName('createSVGTransformFromMatrix')
  @DomName('SVGSVGElement.createSVGTransformFromMatrix')
  @DocsEditable
  Transform createSvgTransformFromMatrix(Matrix matrix) native;

  @DomName('SVGSVGElement.deselectAll')
  @DocsEditable
  void deselectAll() native;

  @DomName('SVGSVGElement.forceRedraw')
  @DocsEditable
  void forceRedraw() native;

  @DomName('SVGSVGElement.getCurrentTime')
  @DocsEditable
  num getCurrentTime() native;

  @DomName('SVGSVGElement.getElementById')
  @DocsEditable
  Element getElementById(String elementId) native;

  @DomName('SVGSVGElement.getEnclosureList')
  @DocsEditable
  @Returns('NodeList')
  @Creates('NodeList')
  List<Node> getEnclosureList(Rect rect, SvgElement referenceElement) native;

  @DomName('SVGSVGElement.getIntersectionList')
  @DocsEditable
  @Returns('NodeList')
  @Creates('NodeList')
  List<Node> getIntersectionList(Rect rect, SvgElement referenceElement) native;

  @DomName('SVGSVGElement.pauseAnimations')
  @DocsEditable
  void pauseAnimations() native;

  @DomName('SVGSVGElement.setCurrentTime')
  @DocsEditable
  void setCurrentTime(num seconds) native;

  @DomName('SVGSVGElement.suspendRedraw')
  @DocsEditable
  int suspendRedraw(int maxWaitMilliseconds) native;

  @DomName('SVGSVGElement.unpauseAnimations')
  @DocsEditable
  void unpauseAnimations() native;

  @DomName('SVGSVGElement.unsuspendRedraw')
  @DocsEditable
  void unsuspendRedraw(int suspendHandleId) native;

  @DomName('SVGSVGElement.unsuspendRedrawAll')
  @DocsEditable
  void unsuspendRedrawAll() native;

  // From SVGExternalResourcesRequired

  @DomName('SVGSVGElement.externalResourcesRequired')
  @DocsEditable
  final AnimatedBoolean externalResourcesRequired;

  // From SVGFitToViewBox

  @DomName('SVGSVGElement.preserveAspectRatio')
  @DocsEditable
  final AnimatedPreserveAspectRatio preserveAspectRatio;

  @DomName('SVGSVGElement.viewBox')
  @DocsEditable
  final AnimatedRect viewBox;

  // From SVGLangSpace

  @DomName('SVGSVGElement.xmllang')
  @DocsEditable
  String xmllang;

  @DomName('SVGSVGElement.xmlspace')
  @DocsEditable
  String xmlspace;

  // From SVGLocatable

  @DomName('SVGSVGElement.farthestViewportElement')
  @DocsEditable
  final SvgElement farthestViewportElement;

  @DomName('SVGSVGElement.nearestViewportElement')
  @DocsEditable
  final SvgElement nearestViewportElement;

  @DomName('SVGSVGElement.getBBox')
  @DocsEditable
  Rect getBBox() native;

  @JSName('getCTM')
  @DomName('SVGSVGElement.getCTM')
  @DocsEditable
  Matrix getCtm() native;

  @JSName('getScreenCTM')
  @DomName('SVGSVGElement.getScreenCTM')
  @DocsEditable
  Matrix getScreenCtm() native;

  @DomName('SVGSVGElement.getTransformToElement')
  @DocsEditable
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DomName('SVGSVGElement.getPresentationAttribute')
  @DocsEditable
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  @DomName('SVGSVGElement.requiredExtensions')
  @DocsEditable
  final StringList requiredExtensions;

  @DomName('SVGSVGElement.requiredFeatures')
  @DocsEditable
  final StringList requiredFeatures;

  @DomName('SVGSVGElement.systemLanguage')
  @DocsEditable
  final StringList systemLanguage;

  @DomName('SVGSVGElement.hasExtension')
  @DocsEditable
  bool hasExtension(String extension) native;

  // From SVGZoomAndPan

  @DomName('SVGSVGElement.zoomAndPan')
  @DocsEditable
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

  @DomName('SVGSwitchElement.externalResourcesRequired')
  @DocsEditable
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  @DomName('SVGSwitchElement.xmllang')
  @DocsEditable
  String xmllang;

  @DomName('SVGSwitchElement.xmlspace')
  @DocsEditable
  String xmlspace;

  // From SVGLocatable

  @DomName('SVGSwitchElement.farthestViewportElement')
  @DocsEditable
  final SvgElement farthestViewportElement;

  @DomName('SVGSwitchElement.nearestViewportElement')
  @DocsEditable
  final SvgElement nearestViewportElement;

  @DomName('SVGSwitchElement.getBBox')
  @DocsEditable
  Rect getBBox() native;

  @JSName('getCTM')
  @DomName('SVGSwitchElement.getCTM')
  @DocsEditable
  Matrix getCtm() native;

  @JSName('getScreenCTM')
  @DomName('SVGSwitchElement.getScreenCTM')
  @DocsEditable
  Matrix getScreenCtm() native;

  @DomName('SVGSwitchElement.getTransformToElement')
  @DocsEditable
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DomName('SVGSwitchElement.getPresentationAttribute')
  @DocsEditable
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  @DomName('SVGSwitchElement.requiredExtensions')
  @DocsEditable
  final StringList requiredExtensions;

  @DomName('SVGSwitchElement.requiredFeatures')
  @DocsEditable
  final StringList requiredFeatures;

  @DomName('SVGSwitchElement.systemLanguage')
  @DocsEditable
  final StringList systemLanguage;

  @DomName('SVGSwitchElement.hasExtension')
  @DocsEditable
  bool hasExtension(String extension) native;

  // From SVGTransformable

  @DomName('SVGSwitchElement.transform')
  @DocsEditable
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

  @DomName('SVGSymbolElement.externalResourcesRequired')
  @DocsEditable
  final AnimatedBoolean externalResourcesRequired;

  // From SVGFitToViewBox

  @DomName('SVGSymbolElement.preserveAspectRatio')
  @DocsEditable
  final AnimatedPreserveAspectRatio preserveAspectRatio;

  @DomName('SVGSymbolElement.viewBox')
  @DocsEditable
  final AnimatedRect viewBox;

  // From SVGLangSpace

  @DomName('SVGSymbolElement.xmllang')
  @DocsEditable
  String xmllang;

  @DomName('SVGSymbolElement.xmlspace')
  @DocsEditable
  String xmlspace;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DomName('SVGSymbolElement.getPresentationAttribute')
  @DocsEditable
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

  @DomName('SVGTRefElement.href')
  @DocsEditable
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

  @DomName('SVGTextContentElement.lengthAdjust')
  @DocsEditable
  final AnimatedEnumeration lengthAdjust;

  @DomName('SVGTextContentElement.textLength')
  @DocsEditable
  final AnimatedLength textLength;

  @DomName('SVGTextContentElement.getCharNumAtPosition')
  @DocsEditable
  int getCharNumAtPosition(Point point) native;

  @DomName('SVGTextContentElement.getComputedTextLength')
  @DocsEditable
  num getComputedTextLength() native;

  @DomName('SVGTextContentElement.getEndPositionOfChar')
  @DocsEditable
  Point getEndPositionOfChar(int offset) native;

  @DomName('SVGTextContentElement.getExtentOfChar')
  @DocsEditable
  Rect getExtentOfChar(int offset) native;

  @DomName('SVGTextContentElement.getNumberOfChars')
  @DocsEditable
  int getNumberOfChars() native;

  @DomName('SVGTextContentElement.getRotationOfChar')
  @DocsEditable
  num getRotationOfChar(int offset) native;

  @DomName('SVGTextContentElement.getStartPositionOfChar')
  @DocsEditable
  Point getStartPositionOfChar(int offset) native;

  @DomName('SVGTextContentElement.getSubStringLength')
  @DocsEditable
  num getSubStringLength(int offset, int length) native;

  @DomName('SVGTextContentElement.selectSubString')
  @DocsEditable
  void selectSubString(int offset, int length) native;

  // From SVGExternalResourcesRequired

  @DomName('SVGTextContentElement.externalResourcesRequired')
  @DocsEditable
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  @DomName('SVGTextContentElement.xmllang')
  @DocsEditable
  String xmllang;

  @DomName('SVGTextContentElement.xmlspace')
  @DocsEditable
  String xmlspace;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DomName('SVGTextContentElement.getPresentationAttribute')
  @DocsEditable
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  @DomName('SVGTextContentElement.requiredExtensions')
  @DocsEditable
  final StringList requiredExtensions;

  @DomName('SVGTextContentElement.requiredFeatures')
  @DocsEditable
  final StringList requiredFeatures;

  @DomName('SVGTextContentElement.systemLanguage')
  @DocsEditable
  final StringList systemLanguage;

  @DomName('SVGTextContentElement.hasExtension')
  @DocsEditable
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

  @DomName('SVGTextElement.farthestViewportElement')
  @DocsEditable
  final SvgElement farthestViewportElement;

  @DomName('SVGTextElement.nearestViewportElement')
  @DocsEditable
  final SvgElement nearestViewportElement;

  @DomName('SVGTextElement.getBBox')
  @DocsEditable
  Rect getBBox() native;

  @JSName('getCTM')
  @DomName('SVGTextElement.getCTM')
  @DocsEditable
  Matrix getCtm() native;

  @JSName('getScreenCTM')
  @DomName('SVGTextElement.getScreenCTM')
  @DocsEditable
  Matrix getScreenCtm() native;

  @DomName('SVGTextElement.getTransformToElement')
  @DocsEditable
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGTransformable

  @DomName('SVGTextElement.transform')
  @DocsEditable
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

  @DomName('SVGTextPathElement.method')
  @DocsEditable
  final AnimatedEnumeration method;

  @DomName('SVGTextPathElement.spacing')
  @DocsEditable
  final AnimatedEnumeration spacing;

  @DomName('SVGTextPathElement.startOffset')
  @DocsEditable
  final AnimatedLength startOffset;

  // From SVGURIReference

  @DomName('SVGTextPathElement.href')
  @DocsEditable
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGTextPositioningElement')
class TextPositioningElement extends TextContentElement native "*SVGTextPositioningElement" {

  @DomName('SVGTextPositioningElement.dx')
  @DocsEditable
  final AnimatedLengthList dx;

  @DomName('SVGTextPositioningElement.dy')
  @DocsEditable
  final AnimatedLengthList dy;

  @DomName('SVGTextPositioningElement.rotate')
  @DocsEditable
  final AnimatedNumberList rotate;

  @DomName('SVGTextPositioningElement.x')
  @DocsEditable
  final AnimatedLengthList x;

  @DomName('SVGTextPositioningElement.y')
  @DocsEditable
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

  @DomName('SVGTitleElement.xmllang')
  @DocsEditable
  String xmllang;

  @DomName('SVGTitleElement.xmlspace')
  @DocsEditable
  String xmlspace;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DomName('SVGTitleElement.getPresentationAttribute')
  @DocsEditable
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

  @DomName('SVGTransform.angle')
  @DocsEditable
  final num angle;

  @DomName('SVGTransform.matrix')
  @DocsEditable
  final Matrix matrix;

  @DomName('SVGTransform.type')
  @DocsEditable
  final int type;

  @DomName('SVGTransform.setMatrix')
  @DocsEditable
  void setMatrix(Matrix matrix) native;

  @DomName('SVGTransform.setRotate')
  @DocsEditable
  void setRotate(num angle, num cx, num cy) native;

  @DomName('SVGTransform.setScale')
  @DocsEditable
  void setScale(num sx, num sy) native;

  @DomName('SVGTransform.setSkewX')
  @DocsEditable
  void setSkewX(num angle) native;

  @DomName('SVGTransform.setSkewY')
  @DocsEditable
  void setSkewY(num angle) native;

  @DomName('SVGTransform.setTranslate')
  @DocsEditable
  void setTranslate(num tx, num ty) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGTransformList')
class TransformList implements List<Transform>, JavaScriptIndexingBehavior native "*SVGTransformList" {

  @DomName('SVGTransformList.numberOfItems')
  @DocsEditable
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

  String join([String separator]) =>
      IterableMixinWorkaround.joinList(this, separator);

  List mappedBy(f(Transform element)) => IterableMixinWorkaround.mappedByList(this, f);

  Iterable<Transform> where(bool f(Transform element)) =>
      IterableMixinWorkaround.where(this, f);

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

  List<Transform> get reversed =>
      new ReversedListView<Transform>(this, 0, null);

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

  Transform min([int compare(Transform a, Transform b)]) =>
      IterableMixinWorkaround.min(this, compare);

  Transform max([int compare(Transform a, Transform b)]) =>
      IterableMixinWorkaround.max(this, compare);

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

  @DomName('SVGTransformList.appendItem')
  @DocsEditable
  Transform appendItem(Transform item) native;

  @DomName('SVGTransformList.clear')
  @DocsEditable
  void clear() native;

  @DomName('SVGTransformList.consolidate')
  @DocsEditable
  Transform consolidate() native;

  @JSName('createSVGTransformFromMatrix')
  @DomName('SVGTransformList.createSVGTransformFromMatrix')
  @DocsEditable
  Transform createSvgTransformFromMatrix(Matrix matrix) native;

  @DomName('SVGTransformList.getItem')
  @DocsEditable
  Transform getItem(int index) native;

  @DomName('SVGTransformList.initialize')
  @DocsEditable
  Transform initialize(Transform item) native;

  @DomName('SVGTransformList.insertItemBefore')
  @DocsEditable
  Transform insertItemBefore(Transform item, int index) native;

  @DomName('SVGTransformList.removeItem')
  @DocsEditable
  Transform removeItem(int index) native;

  @DomName('SVGTransformList.replaceItem')
  @DocsEditable
  Transform replaceItem(Transform item, int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


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

  @DomName('SVGUseElement.animatedInstanceRoot')
  @DocsEditable
  final ElementInstance animatedInstanceRoot;

  @DomName('SVGUseElement.height')
  @DocsEditable
  final AnimatedLength height;

  @DomName('SVGUseElement.instanceRoot')
  @DocsEditable
  final ElementInstance instanceRoot;

  @DomName('SVGUseElement.width')
  @DocsEditable
  final AnimatedLength width;

  @DomName('SVGUseElement.x')
  @DocsEditable
  final AnimatedLength x;

  @DomName('SVGUseElement.y')
  @DocsEditable
  final AnimatedLength y;

  // From SVGExternalResourcesRequired

  @DomName('SVGUseElement.externalResourcesRequired')
  @DocsEditable
  final AnimatedBoolean externalResourcesRequired;

  // From SVGLangSpace

  @DomName('SVGUseElement.xmllang')
  @DocsEditable
  String xmllang;

  @DomName('SVGUseElement.xmlspace')
  @DocsEditable
  String xmlspace;

  // From SVGLocatable

  @DomName('SVGUseElement.farthestViewportElement')
  @DocsEditable
  final SvgElement farthestViewportElement;

  @DomName('SVGUseElement.nearestViewportElement')
  @DocsEditable
  final SvgElement nearestViewportElement;

  @DomName('SVGUseElement.getBBox')
  @DocsEditable
  Rect getBBox() native;

  @JSName('getCTM')
  @DomName('SVGUseElement.getCTM')
  @DocsEditable
  Matrix getCtm() native;

  @JSName('getScreenCTM')
  @DomName('SVGUseElement.getScreenCTM')
  @DocsEditable
  Matrix getScreenCtm() native;

  @DomName('SVGUseElement.getTransformToElement')
  @DocsEditable
  Matrix getTransformToElement(SvgElement element) native;

  // From SVGStylable

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;

  @DomName('SVGUseElement.getPresentationAttribute')
  @DocsEditable
  CssValue getPresentationAttribute(String name) native;

  // From SVGTests

  @DomName('SVGUseElement.requiredExtensions')
  @DocsEditable
  final StringList requiredExtensions;

  @DomName('SVGUseElement.requiredFeatures')
  @DocsEditable
  final StringList requiredFeatures;

  @DomName('SVGUseElement.systemLanguage')
  @DocsEditable
  final StringList systemLanguage;

  @DomName('SVGUseElement.hasExtension')
  @DocsEditable
  bool hasExtension(String extension) native;

  // From SVGTransformable

  @DomName('SVGUseElement.transform')
  @DocsEditable
  final AnimatedTransformList transform;

  // From SVGURIReference

  @DomName('SVGUseElement.href')
  @DocsEditable
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

  @DomName('SVGViewElement.viewTarget')
  @DocsEditable
  final StringList viewTarget;

  // From SVGExternalResourcesRequired

  @DomName('SVGViewElement.externalResourcesRequired')
  @DocsEditable
  final AnimatedBoolean externalResourcesRequired;

  // From SVGFitToViewBox

  @DomName('SVGViewElement.preserveAspectRatio')
  @DocsEditable
  final AnimatedPreserveAspectRatio preserveAspectRatio;

  @DomName('SVGViewElement.viewBox')
  @DocsEditable
  final AnimatedRect viewBox;

  // From SVGZoomAndPan

  @DomName('SVGViewElement.zoomAndPan')
  @DocsEditable
  int zoomAndPan;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGViewSpec')
class ViewSpec native "*SVGViewSpec" {

  @DomName('SVGViewSpec.preserveAspectRatio')
  @DocsEditable
  final AnimatedPreserveAspectRatio preserveAspectRatio;

  @DomName('SVGViewSpec.preserveAspectRatioString')
  @DocsEditable
  final String preserveAspectRatioString;

  @DomName('SVGViewSpec.transform')
  @DocsEditable
  final TransformList transform;

  @DomName('SVGViewSpec.transformString')
  @DocsEditable
  final String transformString;

  @DomName('SVGViewSpec.viewBox')
  @DocsEditable
  final AnimatedRect viewBox;

  @DomName('SVGViewSpec.viewBoxString')
  @DocsEditable
  final String viewBoxString;

  @DomName('SVGViewSpec.viewTarget')
  @DocsEditable
  final SvgElement viewTarget;

  @DomName('SVGViewSpec.viewTargetString')
  @DocsEditable
  final String viewTargetString;

  @DomName('SVGViewSpec.zoomAndPan')
  @DocsEditable
  int zoomAndPan;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


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

  @DomName('SVGZoomEvent.newScale')
  @DocsEditable
  final num newScale;

  @DomName('SVGZoomEvent.newTranslate')
  @DocsEditable
  final Point newTranslate;

  @DomName('SVGZoomEvent.previousScale')
  @DocsEditable
  final num previousScale;

  @DomName('SVGZoomEvent.previousTranslate')
  @DocsEditable
  final Point previousTranslate;

  @DomName('SVGZoomEvent.zoomRectScreen')
  @DocsEditable
  final Rect zoomRectScreen;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGElementInstanceList')
class _ElementInstanceList implements JavaScriptIndexingBehavior, List<ElementInstance> native "*SVGElementInstanceList" {

  @DomName('SVGElementInstanceList.length')
  @DocsEditable
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

  String join([String separator]) =>
      IterableMixinWorkaround.joinList(this, separator);

  List mappedBy(f(ElementInstance element)) => IterableMixinWorkaround.mappedByList(this, f);

  Iterable<ElementInstance> where(bool f(ElementInstance element)) =>
      IterableMixinWorkaround.where(this, f);

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

  List<ElementInstance> get reversed =>
      new ReversedListView<ElementInstance>(this, 0, null);

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

  ElementInstance min([int compare(ElementInstance a, ElementInstance b)]) =>
      IterableMixinWorkaround.min(this, compare);

  ElementInstance max([int compare(ElementInstance a, ElementInstance b)]) =>
      IterableMixinWorkaround.max(this, compare);

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

  @DomName('SVGElementInstanceList.item')
  @DocsEditable
  ElementInstance item(int index) native;
}
