library dart.dom.svg;

import 'dart:async';
import 'dart:collection';
import 'dart:_collection-dev';
import 'dart:html';
import 'dart:html_common';
import 'dart:_js_helper' show Creates, Returns, JavaScriptIndexingBehavior, JSName;
import 'dart:_foreign_helper' show JS;
import 'dart:_interceptors' show Interceptor;
// DO NOT EDIT - unless you are editing documentation as per:
// https://code.google.com/p/dart/wiki/ContributingHTMLDocumentation
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
@Unstable
class AElement extends StyledElement implements UriReference, Tests, Transformable, ExternalResourcesRequired, LangSpace native "SVGAElement" {
  // To suppress missing implicit constructor warnings.
  factory AElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAElement.SVGAElement')
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
@DomName('SVGAltGlyphElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable
class AltGlyphElement extends TextPositioningElement implements UriReference native "SVGAltGlyphElement" {
  // To suppress missing implicit constructor warnings.
  factory AltGlyphElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAltGlyphElement.SVGAltGlyphElement')
  @DocsEditable
  factory AltGlyphElement() => _SvgElementFactoryProvider.createSvgElement_tag("altGlyph");

  /// Checks if this type is supported on the current platform.
  static bool get supported => SvgElement.isTagSupported('altGlyph') && (new SvgElement.tag('altGlyph') is AltGlyphElement);

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
@DomName('SVGAngle')
@Unstable
class Angle native "SVGAngle" {
  // To suppress missing implicit constructor warnings.
  factory Angle._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAngle.SVG_ANGLETYPE_DEG')
  @DocsEditable
  static const int SVG_ANGLETYPE_DEG = 2;

  @DomName('SVGAngle.SVG_ANGLETYPE_GRAD')
  @DocsEditable
  static const int SVG_ANGLETYPE_GRAD = 4;

  @DomName('SVGAngle.SVG_ANGLETYPE_RAD')
  @DocsEditable
  static const int SVG_ANGLETYPE_RAD = 3;

  @DomName('SVGAngle.SVG_ANGLETYPE_UNKNOWN')
  @DocsEditable
  static const int SVG_ANGLETYPE_UNKNOWN = 0;

  @DomName('SVGAngle.SVG_ANGLETYPE_UNSPECIFIED')
  @DocsEditable
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
@DomName('SVGAnimateElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable
class AnimateElement extends AnimationElement native "SVGAnimateElement" {
  // To suppress missing implicit constructor warnings.
  factory AnimateElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAnimateElement.SVGAnimateElement')
  @DocsEditable
  factory AnimateElement() => _SvgElementFactoryProvider.createSvgElement_tag("animate");

  /// Checks if this type is supported on the current platform.
  static bool get supported => SvgElement.isTagSupported('animate') && (new SvgElement.tag('animate') is AnimateElement);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGAnimateMotionElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable
class AnimateMotionElement extends AnimationElement native "SVGAnimateMotionElement" {
  // To suppress missing implicit constructor warnings.
  factory AnimateMotionElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAnimateMotionElement.SVGAnimateMotionElement')
  @DocsEditable
  factory AnimateMotionElement() => _SvgElementFactoryProvider.createSvgElement_tag("animateMotion");

  /// Checks if this type is supported on the current platform.
  static bool get supported => SvgElement.isTagSupported('animateMotion') && (new SvgElement.tag('animateMotion') is AnimateMotionElement);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGAnimateTransformElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable
class AnimateTransformElement extends AnimationElement native "SVGAnimateTransformElement" {
  // To suppress missing implicit constructor warnings.
  factory AnimateTransformElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAnimateTransformElement.SVGAnimateTransformElement')
  @DocsEditable
  factory AnimateTransformElement() => _SvgElementFactoryProvider.createSvgElement_tag("animateTransform");

  /// Checks if this type is supported on the current platform.
  static bool get supported => SvgElement.isTagSupported('animateTransform') && (new SvgElement.tag('animateTransform') is AnimateTransformElement);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGAnimatedAngle')
@Unstable
class AnimatedAngle native "SVGAnimatedAngle" {
  // To suppress missing implicit constructor warnings.
  factory AnimatedAngle._() { throw new UnsupportedError("Not supported"); }

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
@Unstable
class AnimatedBoolean native "SVGAnimatedBoolean" {
  // To suppress missing implicit constructor warnings.
  factory AnimatedBoolean._() { throw new UnsupportedError("Not supported"); }

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
@Unstable
class AnimatedEnumeration native "SVGAnimatedEnumeration" {
  // To suppress missing implicit constructor warnings.
  factory AnimatedEnumeration._() { throw new UnsupportedError("Not supported"); }

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
@Unstable
class AnimatedInteger native "SVGAnimatedInteger" {
  // To suppress missing implicit constructor warnings.
  factory AnimatedInteger._() { throw new UnsupportedError("Not supported"); }

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
@Unstable
class AnimatedLength native "SVGAnimatedLength" {
  // To suppress missing implicit constructor warnings.
  factory AnimatedLength._() { throw new UnsupportedError("Not supported"); }

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
@Unstable
class AnimatedLengthList native "SVGAnimatedLengthList" {
  // To suppress missing implicit constructor warnings.
  factory AnimatedLengthList._() { throw new UnsupportedError("Not supported"); }

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
@Unstable
class AnimatedNumber native "SVGAnimatedNumber" {
  // To suppress missing implicit constructor warnings.
  factory AnimatedNumber._() { throw new UnsupportedError("Not supported"); }

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
@Unstable
class AnimatedNumberList native "SVGAnimatedNumberList" {
  // To suppress missing implicit constructor warnings.
  factory AnimatedNumberList._() { throw new UnsupportedError("Not supported"); }

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
@Unstable
class AnimatedPreserveAspectRatio native "SVGAnimatedPreserveAspectRatio" {
  // To suppress missing implicit constructor warnings.
  factory AnimatedPreserveAspectRatio._() { throw new UnsupportedError("Not supported"); }

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
@Unstable
class AnimatedRect native "SVGAnimatedRect" {
  // To suppress missing implicit constructor warnings.
  factory AnimatedRect._() { throw new UnsupportedError("Not supported"); }

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
@Unstable
class AnimatedString native "SVGAnimatedString" {
  // To suppress missing implicit constructor warnings.
  factory AnimatedString._() { throw new UnsupportedError("Not supported"); }

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
@Unstable
class AnimatedTransformList native "SVGAnimatedTransformList" {
  // To suppress missing implicit constructor warnings.
  factory AnimatedTransformList._() { throw new UnsupportedError("Not supported"); }

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
@Unstable
class AnimationElement extends SvgElement implements Tests, ElementTimeControl, ExternalResourcesRequired native "SVGAnimationElement" {
  // To suppress missing implicit constructor warnings.
  factory AnimationElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAnimationElement.SVGAnimationElement')
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
@Unstable
class CircleElement extends StyledElement implements Transformable, Tests, ExternalResourcesRequired, LangSpace native "SVGCircleElement" {
  // To suppress missing implicit constructor warnings.
  factory CircleElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGCircleElement.SVGCircleElement')
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
@Unstable
class ClipPathElement extends StyledElement implements Transformable, Tests, ExternalResourcesRequired, LangSpace native "SVGClipPathElement" {
  // To suppress missing implicit constructor warnings.
  factory ClipPathElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGClipPathElement.SVGClipPathElement')
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
@DomName('SVGDefsElement')
@Unstable
class DefsElement extends StyledElement implements Transformable, Tests, ExternalResourcesRequired, LangSpace native "SVGDefsElement" {
  // To suppress missing implicit constructor warnings.
  factory DefsElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGDefsElement.SVGDefsElement')
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
@Unstable
class DescElement extends StyledElement implements LangSpace native "SVGDescElement" {
  // To suppress missing implicit constructor warnings.
  factory DescElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGDescElement.SVGDescElement')
  @DocsEditable
  factory DescElement() => _SvgElementFactoryProvider.createSvgElement_tag("desc");

  // From SVGLangSpace

  @DomName('SVGDescElement.xmllang')
  @DocsEditable
  String xmllang;

  @DomName('SVGDescElement.xmlspace')
  @DocsEditable
  String xmlspace;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGElementInstance')
@Unstable
class ElementInstance extends EventTarget native "SVGElementInstance" {
  // To suppress missing implicit constructor warnings.
  factory ElementInstance._() { throw new UnsupportedError("Not supported"); }

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
  // http://www.w3.org/TR/html-markup/input.search.html
  @Experimental
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
  // http://www.w3.org/TR/html-markup/input.search.html
  @Experimental
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


@DocsEditable
@DomName('SVGEllipseElement')
@Unstable
class EllipseElement extends StyledElement implements Transformable, Tests, ExternalResourcesRequired, LangSpace native "SVGEllipseElement" {
  // To suppress missing implicit constructor warnings.
  factory EllipseElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGEllipseElement.SVGEllipseElement')
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
@Unstable
abstract class ExternalResourcesRequired {
  // To suppress missing implicit constructor warnings.
  factory ExternalResourcesRequired._() { throw new UnsupportedError("Not supported"); }

  /// Checks if this type is supported on the current platform.
  static bool supported(SvgElement element) => JS('bool', '#.externalResourcesRequired !== undefined && #.externalResourcesRequired.animVal !== undefined', element, element);

  AnimatedBoolean externalResourcesRequired;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGFEBlendElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable
class FEBlendElement extends StyledElement implements FilterPrimitiveStandardAttributes native "SVGFEBlendElement" {
  // To suppress missing implicit constructor warnings.
  factory FEBlendElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEBlendElement.SVGFEBlendElement')
  @DocsEditable
  factory FEBlendElement() => _SvgElementFactoryProvider.createSvgElement_tag("feBlend");

  /// Checks if this type is supported on the current platform.
  static bool get supported => SvgElement.isTagSupported('feBlend') && (new SvgElement.tag('feBlend') is FEBlendElement);

  @DomName('SVGFEBlendElement.SVG_FEBLEND_MODE_DARKEN')
  @DocsEditable
  static const int SVG_FEBLEND_MODE_DARKEN = 4;

  @DomName('SVGFEBlendElement.SVG_FEBLEND_MODE_LIGHTEN')
  @DocsEditable
  static const int SVG_FEBLEND_MODE_LIGHTEN = 5;

  @DomName('SVGFEBlendElement.SVG_FEBLEND_MODE_MULTIPLY')
  @DocsEditable
  static const int SVG_FEBLEND_MODE_MULTIPLY = 2;

  @DomName('SVGFEBlendElement.SVG_FEBLEND_MODE_NORMAL')
  @DocsEditable
  static const int SVG_FEBLEND_MODE_NORMAL = 1;

  @DomName('SVGFEBlendElement.SVG_FEBLEND_MODE_SCREEN')
  @DocsEditable
  static const int SVG_FEBLEND_MODE_SCREEN = 3;

  @DomName('SVGFEBlendElement.SVG_FEBLEND_MODE_UNKNOWN')
  @DocsEditable
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
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGFEColorMatrixElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable
class FEColorMatrixElement extends StyledElement implements FilterPrimitiveStandardAttributes native "SVGFEColorMatrixElement" {
  // To suppress missing implicit constructor warnings.
  factory FEColorMatrixElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEColorMatrixElement.SVGFEColorMatrixElement')
  @DocsEditable
  factory FEColorMatrixElement() => _SvgElementFactoryProvider.createSvgElement_tag("feColorMatrix");

  /// Checks if this type is supported on the current platform.
  static bool get supported => SvgElement.isTagSupported('feColorMatrix') && (new SvgElement.tag('feColorMatrix') is FEColorMatrixElement);

  @DomName('SVGFEColorMatrixElement.SVG_FECOLORMATRIX_TYPE_HUEROTATE')
  @DocsEditable
  static const int SVG_FECOLORMATRIX_TYPE_HUEROTATE = 3;

  @DomName('SVGFEColorMatrixElement.SVG_FECOLORMATRIX_TYPE_LUMINANCETOALPHA')
  @DocsEditable
  static const int SVG_FECOLORMATRIX_TYPE_LUMINANCETOALPHA = 4;

  @DomName('SVGFEColorMatrixElement.SVG_FECOLORMATRIX_TYPE_MATRIX')
  @DocsEditable
  static const int SVG_FECOLORMATRIX_TYPE_MATRIX = 1;

  @DomName('SVGFEColorMatrixElement.SVG_FECOLORMATRIX_TYPE_SATURATE')
  @DocsEditable
  static const int SVG_FECOLORMATRIX_TYPE_SATURATE = 2;

  @DomName('SVGFEColorMatrixElement.SVG_FECOLORMATRIX_TYPE_UNKNOWN')
  @DocsEditable
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
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGFEComponentTransferElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable
class FEComponentTransferElement extends StyledElement implements FilterPrimitiveStandardAttributes native "SVGFEComponentTransferElement" {
  // To suppress missing implicit constructor warnings.
  factory FEComponentTransferElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEComponentTransferElement.SVGFEComponentTransferElement')
  @DocsEditable
  factory FEComponentTransferElement() => _SvgElementFactoryProvider.createSvgElement_tag("feComponentTransfer");

  /// Checks if this type is supported on the current platform.
  static bool get supported => SvgElement.isTagSupported('feComponentTransfer') && (new SvgElement.tag('feComponentTransfer') is FEComponentTransferElement);

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
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGFECompositeElement')
@Unstable
class FECompositeElement extends StyledElement implements FilterPrimitiveStandardAttributes native "SVGFECompositeElement" {
  // To suppress missing implicit constructor warnings.
  factory FECompositeElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFECompositeElement.SVG_FECOMPOSITE_OPERATOR_ARITHMETIC')
  @DocsEditable
  static const int SVG_FECOMPOSITE_OPERATOR_ARITHMETIC = 6;

  @DomName('SVGFECompositeElement.SVG_FECOMPOSITE_OPERATOR_ATOP')
  @DocsEditable
  static const int SVG_FECOMPOSITE_OPERATOR_ATOP = 4;

  @DomName('SVGFECompositeElement.SVG_FECOMPOSITE_OPERATOR_IN')
  @DocsEditable
  static const int SVG_FECOMPOSITE_OPERATOR_IN = 2;

  @DomName('SVGFECompositeElement.SVG_FECOMPOSITE_OPERATOR_OUT')
  @DocsEditable
  static const int SVG_FECOMPOSITE_OPERATOR_OUT = 3;

  @DomName('SVGFECompositeElement.SVG_FECOMPOSITE_OPERATOR_OVER')
  @DocsEditable
  static const int SVG_FECOMPOSITE_OPERATOR_OVER = 1;

  @DomName('SVGFECompositeElement.SVG_FECOMPOSITE_OPERATOR_UNKNOWN')
  @DocsEditable
  static const int SVG_FECOMPOSITE_OPERATOR_UNKNOWN = 0;

  @DomName('SVGFECompositeElement.SVG_FECOMPOSITE_OPERATOR_XOR')
  @DocsEditable
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
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGFEConvolveMatrixElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable
class FEConvolveMatrixElement extends StyledElement implements FilterPrimitiveStandardAttributes native "SVGFEConvolveMatrixElement" {
  // To suppress missing implicit constructor warnings.
  factory FEConvolveMatrixElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEConvolveMatrixElement.SVGFEConvolveMatrixElement')
  @DocsEditable
  factory FEConvolveMatrixElement() => _SvgElementFactoryProvider.createSvgElement_tag("feConvolveMatrix");

  /// Checks if this type is supported on the current platform.
  static bool get supported => SvgElement.isTagSupported('feConvolveMatrix') && (new SvgElement.tag('feConvolveMatrix') is FEConvolveMatrixElement);

  @DomName('SVGFEConvolveMatrixElement.SVG_EDGEMODE_DUPLICATE')
  @DocsEditable
  static const int SVG_EDGEMODE_DUPLICATE = 1;

  @DomName('SVGFEConvolveMatrixElement.SVG_EDGEMODE_NONE')
  @DocsEditable
  static const int SVG_EDGEMODE_NONE = 3;

  @DomName('SVGFEConvolveMatrixElement.SVG_EDGEMODE_UNKNOWN')
  @DocsEditable
  static const int SVG_EDGEMODE_UNKNOWN = 0;

  @DomName('SVGFEConvolveMatrixElement.SVG_EDGEMODE_WRAP')
  @DocsEditable
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
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGFEDiffuseLightingElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable
class FEDiffuseLightingElement extends StyledElement implements FilterPrimitiveStandardAttributes native "SVGFEDiffuseLightingElement" {
  // To suppress missing implicit constructor warnings.
  factory FEDiffuseLightingElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEDiffuseLightingElement.SVGFEDiffuseLightingElement')
  @DocsEditable
  factory FEDiffuseLightingElement() => _SvgElementFactoryProvider.createSvgElement_tag("feDiffuseLighting");

  /// Checks if this type is supported on the current platform.
  static bool get supported => SvgElement.isTagSupported('feDiffuseLighting') && (new SvgElement.tag('feDiffuseLighting') is FEDiffuseLightingElement);

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
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGFEDisplacementMapElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable
class FEDisplacementMapElement extends StyledElement implements FilterPrimitiveStandardAttributes native "SVGFEDisplacementMapElement" {
  // To suppress missing implicit constructor warnings.
  factory FEDisplacementMapElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEDisplacementMapElement.SVGFEDisplacementMapElement')
  @DocsEditable
  factory FEDisplacementMapElement() => _SvgElementFactoryProvider.createSvgElement_tag("feDisplacementMap");

  /// Checks if this type is supported on the current platform.
  static bool get supported => SvgElement.isTagSupported('feDisplacementMap') && (new SvgElement.tag('feDisplacementMap') is FEDisplacementMapElement);

  @DomName('SVGFEDisplacementMapElement.SVG_CHANNEL_A')
  @DocsEditable
  static const int SVG_CHANNEL_A = 4;

  @DomName('SVGFEDisplacementMapElement.SVG_CHANNEL_B')
  @DocsEditable
  static const int SVG_CHANNEL_B = 3;

  @DomName('SVGFEDisplacementMapElement.SVG_CHANNEL_G')
  @DocsEditable
  static const int SVG_CHANNEL_G = 2;

  @DomName('SVGFEDisplacementMapElement.SVG_CHANNEL_R')
  @DocsEditable
  static const int SVG_CHANNEL_R = 1;

  @DomName('SVGFEDisplacementMapElement.SVG_CHANNEL_UNKNOWN')
  @DocsEditable
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
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGFEDistantLightElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable
class FEDistantLightElement extends SvgElement native "SVGFEDistantLightElement" {
  // To suppress missing implicit constructor warnings.
  factory FEDistantLightElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEDistantLightElement.SVGFEDistantLightElement')
  @DocsEditable
  factory FEDistantLightElement() => _SvgElementFactoryProvider.createSvgElement_tag("feDistantLight");

  /// Checks if this type is supported on the current platform.
  static bool get supported => SvgElement.isTagSupported('feDistantLight') && (new SvgElement.tag('feDistantLight') is FEDistantLightElement);

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
@DomName('SVGFEFloodElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable
class FEFloodElement extends StyledElement implements FilterPrimitiveStandardAttributes native "SVGFEFloodElement" {
  // To suppress missing implicit constructor warnings.
  factory FEFloodElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEFloodElement.SVGFEFloodElement')
  @DocsEditable
  factory FEFloodElement() => _SvgElementFactoryProvider.createSvgElement_tag("feFlood");

  /// Checks if this type is supported on the current platform.
  static bool get supported => SvgElement.isTagSupported('feFlood') && (new SvgElement.tag('feFlood') is FEFloodElement);

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
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGFEFuncAElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable
class FEFuncAElement extends _SVGComponentTransferFunctionElement native "SVGFEFuncAElement" {
  // To suppress missing implicit constructor warnings.
  factory FEFuncAElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEFuncAElement.SVGFEFuncAElement')
  @DocsEditable
  factory FEFuncAElement() => _SvgElementFactoryProvider.createSvgElement_tag("feFuncA");

  /// Checks if this type is supported on the current platform.
  static bool get supported => SvgElement.isTagSupported('feFuncA') && (new SvgElement.tag('feFuncA') is FEFuncAElement);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGFEFuncBElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable
class FEFuncBElement extends _SVGComponentTransferFunctionElement native "SVGFEFuncBElement" {
  // To suppress missing implicit constructor warnings.
  factory FEFuncBElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEFuncBElement.SVGFEFuncBElement')
  @DocsEditable
  factory FEFuncBElement() => _SvgElementFactoryProvider.createSvgElement_tag("feFuncB");

  /// Checks if this type is supported on the current platform.
  static bool get supported => SvgElement.isTagSupported('feFuncB') && (new SvgElement.tag('feFuncB') is FEFuncBElement);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGFEFuncGElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable
class FEFuncGElement extends _SVGComponentTransferFunctionElement native "SVGFEFuncGElement" {
  // To suppress missing implicit constructor warnings.
  factory FEFuncGElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEFuncGElement.SVGFEFuncGElement')
  @DocsEditable
  factory FEFuncGElement() => _SvgElementFactoryProvider.createSvgElement_tag("feFuncG");

  /// Checks if this type is supported on the current platform.
  static bool get supported => SvgElement.isTagSupported('feFuncG') && (new SvgElement.tag('feFuncG') is FEFuncGElement);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGFEFuncRElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable
class FEFuncRElement extends _SVGComponentTransferFunctionElement native "SVGFEFuncRElement" {
  // To suppress missing implicit constructor warnings.
  factory FEFuncRElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEFuncRElement.SVGFEFuncRElement')
  @DocsEditable
  factory FEFuncRElement() => _SvgElementFactoryProvider.createSvgElement_tag("feFuncR");

  /// Checks if this type is supported on the current platform.
  static bool get supported => SvgElement.isTagSupported('feFuncR') && (new SvgElement.tag('feFuncR') is FEFuncRElement);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGFEGaussianBlurElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable
class FEGaussianBlurElement extends StyledElement implements FilterPrimitiveStandardAttributes native "SVGFEGaussianBlurElement" {
  // To suppress missing implicit constructor warnings.
  factory FEGaussianBlurElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEGaussianBlurElement.SVGFEGaussianBlurElement')
  @DocsEditable
  factory FEGaussianBlurElement() => _SvgElementFactoryProvider.createSvgElement_tag("feGaussianBlur");

  /// Checks if this type is supported on the current platform.
  static bool get supported => SvgElement.isTagSupported('feGaussianBlur') && (new SvgElement.tag('feGaussianBlur') is FEGaussianBlurElement);

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
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGFEImageElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable
class FEImageElement extends StyledElement implements FilterPrimitiveStandardAttributes, UriReference, ExternalResourcesRequired, LangSpace native "SVGFEImageElement" {
  // To suppress missing implicit constructor warnings.
  factory FEImageElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEImageElement.SVGFEImageElement')
  @DocsEditable
  factory FEImageElement() => _SvgElementFactoryProvider.createSvgElement_tag("feImage");

  /// Checks if this type is supported on the current platform.
  static bool get supported => SvgElement.isTagSupported('feImage') && (new SvgElement.tag('feImage') is FEImageElement);

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
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable
class FEMergeElement extends StyledElement implements FilterPrimitiveStandardAttributes native "SVGFEMergeElement" {
  // To suppress missing implicit constructor warnings.
  factory FEMergeElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEMergeElement.SVGFEMergeElement')
  @DocsEditable
  factory FEMergeElement() => _SvgElementFactoryProvider.createSvgElement_tag("feMerge");

  /// Checks if this type is supported on the current platform.
  static bool get supported => SvgElement.isTagSupported('feMerge') && (new SvgElement.tag('feMerge') is FEMergeElement);

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
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGFEMergeNodeElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable
class FEMergeNodeElement extends SvgElement native "SVGFEMergeNodeElement" {
  // To suppress missing implicit constructor warnings.
  factory FEMergeNodeElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEMergeNodeElement.SVGFEMergeNodeElement')
  @DocsEditable
  factory FEMergeNodeElement() => _SvgElementFactoryProvider.createSvgElement_tag("feMergeNode");

  /// Checks if this type is supported on the current platform.
  static bool get supported => SvgElement.isTagSupported('feMergeNode') && (new SvgElement.tag('feMergeNode') is FEMergeNodeElement);

  @DomName('SVGFEMergeNodeElement.in1')
  @DocsEditable
  final AnimatedString in1;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGFEMorphologyElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable
class FEMorphologyElement extends StyledElement implements FilterPrimitiveStandardAttributes native "SVGFEMorphologyElement" {
  // To suppress missing implicit constructor warnings.
  factory FEMorphologyElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEMorphologyElement.SVG_MORPHOLOGY_OPERATOR_DILATE')
  @DocsEditable
  static const int SVG_MORPHOLOGY_OPERATOR_DILATE = 2;

  @DomName('SVGFEMorphologyElement.SVG_MORPHOLOGY_OPERATOR_ERODE')
  @DocsEditable
  static const int SVG_MORPHOLOGY_OPERATOR_ERODE = 1;

  @DomName('SVGFEMorphologyElement.SVG_MORPHOLOGY_OPERATOR_UNKNOWN')
  @DocsEditable
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
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGFEOffsetElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable
class FEOffsetElement extends StyledElement implements FilterPrimitiveStandardAttributes native "SVGFEOffsetElement" {
  // To suppress missing implicit constructor warnings.
  factory FEOffsetElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEOffsetElement.SVGFEOffsetElement')
  @DocsEditable
  factory FEOffsetElement() => _SvgElementFactoryProvider.createSvgElement_tag("feOffset");

  /// Checks if this type is supported on the current platform.
  static bool get supported => SvgElement.isTagSupported('feOffset') && (new SvgElement.tag('feOffset') is FEOffsetElement);

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
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGFEPointLightElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable
class FEPointLightElement extends SvgElement native "SVGFEPointLightElement" {
  // To suppress missing implicit constructor warnings.
  factory FEPointLightElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEPointLightElement.SVGFEPointLightElement')
  @DocsEditable
  factory FEPointLightElement() => _SvgElementFactoryProvider.createSvgElement_tag("fePointLight");

  /// Checks if this type is supported on the current platform.
  static bool get supported => SvgElement.isTagSupported('fePointLight') && (new SvgElement.tag('fePointLight') is FEPointLightElement);

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
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable
class FESpecularLightingElement extends StyledElement implements FilterPrimitiveStandardAttributes native "SVGFESpecularLightingElement" {
  // To suppress missing implicit constructor warnings.
  factory FESpecularLightingElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFESpecularLightingElement.SVGFESpecularLightingElement')
  @DocsEditable
  factory FESpecularLightingElement() => _SvgElementFactoryProvider.createSvgElement_tag("feSpecularLighting");

  /// Checks if this type is supported on the current platform.
  static bool get supported => SvgElement.isTagSupported('feSpecularLighting') && (new SvgElement.tag('feSpecularLighting') is FESpecularLightingElement);

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
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGFESpotLightElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable
class FESpotLightElement extends SvgElement native "SVGFESpotLightElement" {
  // To suppress missing implicit constructor warnings.
  factory FESpotLightElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFESpotLightElement.SVGFESpotLightElement')
  @DocsEditable
  factory FESpotLightElement() => _SvgElementFactoryProvider.createSvgElement_tag("feSpotLight");

  /// Checks if this type is supported on the current platform.
  static bool get supported => SvgElement.isTagSupported('feSpotLight') && (new SvgElement.tag('feSpotLight') is FESpotLightElement);

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
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable
class FETileElement extends StyledElement implements FilterPrimitiveStandardAttributes native "SVGFETileElement" {
  // To suppress missing implicit constructor warnings.
  factory FETileElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFETileElement.SVGFETileElement')
  @DocsEditable
  factory FETileElement() => _SvgElementFactoryProvider.createSvgElement_tag("feTile");

  /// Checks if this type is supported on the current platform.
  static bool get supported => SvgElement.isTagSupported('feTile') && (new SvgElement.tag('feTile') is FETileElement);

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
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGFETurbulenceElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable
class FETurbulenceElement extends StyledElement implements FilterPrimitiveStandardAttributes native "SVGFETurbulenceElement" {
  // To suppress missing implicit constructor warnings.
  factory FETurbulenceElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFETurbulenceElement.SVGFETurbulenceElement')
  @DocsEditable
  factory FETurbulenceElement() => _SvgElementFactoryProvider.createSvgElement_tag("feTurbulence");

  /// Checks if this type is supported on the current platform.
  static bool get supported => SvgElement.isTagSupported('feTurbulence') && (new SvgElement.tag('feTurbulence') is FETurbulenceElement);

  @DomName('SVGFETurbulenceElement.SVG_STITCHTYPE_NOSTITCH')
  @DocsEditable
  static const int SVG_STITCHTYPE_NOSTITCH = 2;

  @DomName('SVGFETurbulenceElement.SVG_STITCHTYPE_STITCH')
  @DocsEditable
  static const int SVG_STITCHTYPE_STITCH = 1;

  @DomName('SVGFETurbulenceElement.SVG_STITCHTYPE_UNKNOWN')
  @DocsEditable
  static const int SVG_STITCHTYPE_UNKNOWN = 0;

  @DomName('SVGFETurbulenceElement.SVG_TURBULENCE_TYPE_FRACTALNOISE')
  @DocsEditable
  static const int SVG_TURBULENCE_TYPE_FRACTALNOISE = 1;

  @DomName('SVGFETurbulenceElement.SVG_TURBULENCE_TYPE_TURBULENCE')
  @DocsEditable
  static const int SVG_TURBULENCE_TYPE_TURBULENCE = 2;

  @DomName('SVGFETurbulenceElement.SVG_TURBULENCE_TYPE_UNKNOWN')
  @DocsEditable
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
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGFilterElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable
class FilterElement extends StyledElement implements UriReference, ExternalResourcesRequired, LangSpace native "SVGFilterElement" {
  // To suppress missing implicit constructor warnings.
  factory FilterElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFilterElement.SVGFilterElement')
  @DocsEditable
  factory FilterElement() => _SvgElementFactoryProvider.createSvgElement_tag("filter");

  /// Checks if this type is supported on the current platform.
  static bool get supported => SvgElement.isTagSupported('filter') && (new SvgElement.tag('filter') is FilterElement);

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

  // From SVGURIReference

  @DomName('SVGFilterElement.href')
  @DocsEditable
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('SVGFilterPrimitiveStandardAttributes')
@Unstable
abstract class FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory FilterPrimitiveStandardAttributes._() { throw new UnsupportedError("Not supported"); }

  AnimatedLength height;

  AnimatedString result;

  AnimatedLength width;

  AnimatedLength x;

  AnimatedLength y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('SVGFitToViewBox')
@Unstable
abstract class FitToViewBox {
  // To suppress missing implicit constructor warnings.
  factory FitToViewBox._() { throw new UnsupportedError("Not supported"); }

  AnimatedPreserveAspectRatio preserveAspectRatio;

  AnimatedRect viewBox;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGForeignObjectElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable
class ForeignObjectElement extends StyledElement implements Transformable, Tests, ExternalResourcesRequired, LangSpace native "SVGForeignObjectElement" {
  // To suppress missing implicit constructor warnings.
  factory ForeignObjectElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGForeignObjectElement.SVGForeignObjectElement')
  @DocsEditable
  factory ForeignObjectElement() => _SvgElementFactoryProvider.createSvgElement_tag("foreignObject");

  /// Checks if this type is supported on the current platform.
  static bool get supported => SvgElement.isTagSupported('foreignObject') && (new SvgElement.tag('foreignObject') is ForeignObjectElement);

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
@Unstable
class GElement extends StyledElement implements Transformable, Tests, ExternalResourcesRequired, LangSpace native "SVGGElement" {
  // To suppress missing implicit constructor warnings.
  factory GElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGGElement.SVGGElement')
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
@DomName('SVGImageElement')
@Unstable
class ImageElement extends StyledElement implements UriReference, Tests, Transformable, ExternalResourcesRequired, LangSpace native "SVGImageElement" {
  // To suppress missing implicit constructor warnings.
  factory ImageElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGImageElement.SVGImageElement')
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
@Unstable
abstract class LangSpace {
  // To suppress missing implicit constructor warnings.
  factory LangSpace._() { throw new UnsupportedError("Not supported"); }

  /// Checks if this type is supported on the current platform.
  static bool supported(SvgElement element) => JS('bool', '#.xmlspace !== undefined && #.xmllang !== undefined', element, element);

  String xmllang;

  String xmlspace;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGLength')
@Unstable
class Length native "SVGLength" {
  // To suppress missing implicit constructor warnings.
  factory Length._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGLength.SVG_LENGTHTYPE_CM')
  @DocsEditable
  static const int SVG_LENGTHTYPE_CM = 6;

  @DomName('SVGLength.SVG_LENGTHTYPE_EMS')
  @DocsEditable
  static const int SVG_LENGTHTYPE_EMS = 3;

  @DomName('SVGLength.SVG_LENGTHTYPE_EXS')
  @DocsEditable
  static const int SVG_LENGTHTYPE_EXS = 4;

  @DomName('SVGLength.SVG_LENGTHTYPE_IN')
  @DocsEditable
  static const int SVG_LENGTHTYPE_IN = 8;

  @DomName('SVGLength.SVG_LENGTHTYPE_MM')
  @DocsEditable
  static const int SVG_LENGTHTYPE_MM = 7;

  @DomName('SVGLength.SVG_LENGTHTYPE_NUMBER')
  @DocsEditable
  static const int SVG_LENGTHTYPE_NUMBER = 1;

  @DomName('SVGLength.SVG_LENGTHTYPE_PC')
  @DocsEditable
  static const int SVG_LENGTHTYPE_PC = 10;

  @DomName('SVGLength.SVG_LENGTHTYPE_PERCENTAGE')
  @DocsEditable
  static const int SVG_LENGTHTYPE_PERCENTAGE = 2;

  @DomName('SVGLength.SVG_LENGTHTYPE_PT')
  @DocsEditable
  static const int SVG_LENGTHTYPE_PT = 9;

  @DomName('SVGLength.SVG_LENGTHTYPE_PX')
  @DocsEditable
  static const int SVG_LENGTHTYPE_PX = 5;

  @DomName('SVGLength.SVG_LENGTHTYPE_UNKNOWN')
  @DocsEditable
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
@Unstable
class LengthList extends Interceptor with ListMixin<Length>, ImmutableListMixin<Length> implements JavaScriptIndexingBehavior, List<Length> native "SVGLengthList" {
  // To suppress missing implicit constructor warnings.
  factory LengthList._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGLengthList.numberOfItems')
  @DocsEditable
  final int numberOfItems;

  Length operator[](int index) {
    if (JS("bool", "# >>> 0 !== # || # >= #", index,
        index, index, length))
      throw new RangeError.range(index, 0, length);
    return this.getItem(index);
  }
  void operator[]=(int index, Length value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Length> mixins.
  // Length is the element type.

  // SVG Collections expose numberOfItems rather than length.
  int get length => numberOfItems;

  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  Length get first {
    if (this.length > 0) {
      return JS('Length', '#[0]', this);
    }
    throw new StateError("No elements");
  }

  Length get last {
    int len = this.length;
    if (len > 0) {
      return JS('Length', '#[#]', this, len - 1);
    }
    throw new StateError("No elements");
  }

  Length get single {
    int len = this.length;
    if (len == 1) {
      return JS('Length', '#[0]', this);
    }
    if (len == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  Length elementAt(int index) => this[index];
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
@Unstable
class LineElement extends StyledElement implements Transformable, Tests, ExternalResourcesRequired, LangSpace native "SVGLineElement" {
  // To suppress missing implicit constructor warnings.
  factory LineElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGLineElement.SVGLineElement')
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
@Unstable
class LinearGradientElement extends _GradientElement native "SVGLinearGradientElement" {
  // To suppress missing implicit constructor warnings.
  factory LinearGradientElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGLinearGradientElement.SVGLinearGradientElement')
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
@Unstable
abstract class Locatable {
  // To suppress missing implicit constructor warnings.
  factory Locatable._() { throw new UnsupportedError("Not supported"); }

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
@DomName('SVGMarkerElement')
@Unstable
class MarkerElement extends StyledElement implements FitToViewBox, ExternalResourcesRequired, LangSpace native "SVGMarkerElement" {
  // To suppress missing implicit constructor warnings.
  factory MarkerElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGMarkerElement.SVGMarkerElement')
  @DocsEditable
  factory MarkerElement() => _SvgElementFactoryProvider.createSvgElement_tag("marker");

  @DomName('SVGMarkerElement.SVG_MARKERUNITS_STROKEWIDTH')
  @DocsEditable
  static const int SVG_MARKERUNITS_STROKEWIDTH = 2;

  @DomName('SVGMarkerElement.SVG_MARKERUNITS_UNKNOWN')
  @DocsEditable
  static const int SVG_MARKERUNITS_UNKNOWN = 0;

  @DomName('SVGMarkerElement.SVG_MARKERUNITS_USERSPACEONUSE')
  @DocsEditable
  static const int SVG_MARKERUNITS_USERSPACEONUSE = 1;

  @DomName('SVGMarkerElement.SVG_MARKER_ORIENT_ANGLE')
  @DocsEditable
  static const int SVG_MARKER_ORIENT_ANGLE = 2;

  @DomName('SVGMarkerElement.SVG_MARKER_ORIENT_AUTO')
  @DocsEditable
  static const int SVG_MARKER_ORIENT_AUTO = 1;

  @DomName('SVGMarkerElement.SVG_MARKER_ORIENT_UNKNOWN')
  @DocsEditable
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
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGMaskElement')
@Unstable
class MaskElement extends StyledElement implements Tests, ExternalResourcesRequired, LangSpace native "SVGMaskElement" {
  // To suppress missing implicit constructor warnings.
  factory MaskElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGMaskElement.SVGMaskElement')
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
@Unstable
class Matrix native "SVGMatrix" {
  // To suppress missing implicit constructor warnings.
  factory Matrix._() { throw new UnsupportedError("Not supported"); }

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
@Unstable
class MetadataElement extends SvgElement native "SVGMetadataElement" {
  // To suppress missing implicit constructor warnings.
  factory MetadataElement._() { throw new UnsupportedError("Not supported"); }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGNumber')
@Unstable
class Number native "SVGNumber" {
  // To suppress missing implicit constructor warnings.
  factory Number._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGNumber.value')
  @DocsEditable
  num value;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGNumberList')
@Unstable
class NumberList extends Interceptor with ListMixin<Number>, ImmutableListMixin<Number> implements JavaScriptIndexingBehavior, List<Number> native "SVGNumberList" {
  // To suppress missing implicit constructor warnings.
  factory NumberList._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGNumberList.numberOfItems')
  @DocsEditable
  final int numberOfItems;

  Number operator[](int index) {
    if (JS("bool", "# >>> 0 !== # || # >= #", index,
        index, index, length))
      throw new RangeError.range(index, 0, length);
    return this.getItem(index);
  }
  void operator[]=(int index, Number value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Number> mixins.
  // Number is the element type.

  // SVG Collections expose numberOfItems rather than length.
  int get length => numberOfItems;

  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  Number get first {
    if (this.length > 0) {
      return JS('Number', '#[0]', this);
    }
    throw new StateError("No elements");
  }

  Number get last {
    int len = this.length;
    if (len > 0) {
      return JS('Number', '#[#]', this, len - 1);
    }
    throw new StateError("No elements");
  }

  Number get single {
    int len = this.length;
    if (len == 1) {
      return JS('Number', '#[0]', this);
    }
    if (len == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  Number elementAt(int index) => this[index];
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
@DomName('SVGPathElement')
@Unstable
class PathElement extends StyledElement implements Transformable, Tests, ExternalResourcesRequired, LangSpace native "SVGPathElement" {
  // To suppress missing implicit constructor warnings.
  factory PathElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathElement.SVGPathElement')
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
@Unstable
class PathSeg native "SVGPathSeg" {
  // To suppress missing implicit constructor warnings.
  factory PathSeg._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSeg.PATHSEG_ARC_ABS')
  @DocsEditable
  static const int PATHSEG_ARC_ABS = 10;

  @DomName('SVGPathSeg.PATHSEG_ARC_REL')
  @DocsEditable
  static const int PATHSEG_ARC_REL = 11;

  @DomName('SVGPathSeg.PATHSEG_CLOSEPATH')
  @DocsEditable
  static const int PATHSEG_CLOSEPATH = 1;

  @DomName('SVGPathSeg.PATHSEG_CURVETO_CUBIC_ABS')
  @DocsEditable
  static const int PATHSEG_CURVETO_CUBIC_ABS = 6;

  @DomName('SVGPathSeg.PATHSEG_CURVETO_CUBIC_REL')
  @DocsEditable
  static const int PATHSEG_CURVETO_CUBIC_REL = 7;

  @DomName('SVGPathSeg.PATHSEG_CURVETO_CUBIC_SMOOTH_ABS')
  @DocsEditable
  static const int PATHSEG_CURVETO_CUBIC_SMOOTH_ABS = 16;

  @DomName('SVGPathSeg.PATHSEG_CURVETO_CUBIC_SMOOTH_REL')
  @DocsEditable
  static const int PATHSEG_CURVETO_CUBIC_SMOOTH_REL = 17;

  @DomName('SVGPathSeg.PATHSEG_CURVETO_QUADRATIC_ABS')
  @DocsEditable
  static const int PATHSEG_CURVETO_QUADRATIC_ABS = 8;

  @DomName('SVGPathSeg.PATHSEG_CURVETO_QUADRATIC_REL')
  @DocsEditable
  static const int PATHSEG_CURVETO_QUADRATIC_REL = 9;

  @DomName('SVGPathSeg.PATHSEG_CURVETO_QUADRATIC_SMOOTH_ABS')
  @DocsEditable
  static const int PATHSEG_CURVETO_QUADRATIC_SMOOTH_ABS = 18;

  @DomName('SVGPathSeg.PATHSEG_CURVETO_QUADRATIC_SMOOTH_REL')
  @DocsEditable
  static const int PATHSEG_CURVETO_QUADRATIC_SMOOTH_REL = 19;

  @DomName('SVGPathSeg.PATHSEG_LINETO_ABS')
  @DocsEditable
  static const int PATHSEG_LINETO_ABS = 4;

  @DomName('SVGPathSeg.PATHSEG_LINETO_HORIZONTAL_ABS')
  @DocsEditable
  static const int PATHSEG_LINETO_HORIZONTAL_ABS = 12;

  @DomName('SVGPathSeg.PATHSEG_LINETO_HORIZONTAL_REL')
  @DocsEditable
  static const int PATHSEG_LINETO_HORIZONTAL_REL = 13;

  @DomName('SVGPathSeg.PATHSEG_LINETO_REL')
  @DocsEditable
  static const int PATHSEG_LINETO_REL = 5;

  @DomName('SVGPathSeg.PATHSEG_LINETO_VERTICAL_ABS')
  @DocsEditable
  static const int PATHSEG_LINETO_VERTICAL_ABS = 14;

  @DomName('SVGPathSeg.PATHSEG_LINETO_VERTICAL_REL')
  @DocsEditable
  static const int PATHSEG_LINETO_VERTICAL_REL = 15;

  @DomName('SVGPathSeg.PATHSEG_MOVETO_ABS')
  @DocsEditable
  static const int PATHSEG_MOVETO_ABS = 2;

  @DomName('SVGPathSeg.PATHSEG_MOVETO_REL')
  @DocsEditable
  static const int PATHSEG_MOVETO_REL = 3;

  @DomName('SVGPathSeg.PATHSEG_UNKNOWN')
  @DocsEditable
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
@Unstable
class PathSegArcAbs extends PathSeg native "SVGPathSegArcAbs" {
  // To suppress missing implicit constructor warnings.
  factory PathSegArcAbs._() { throw new UnsupportedError("Not supported"); }

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
@Unstable
class PathSegArcRel extends PathSeg native "SVGPathSegArcRel" {
  // To suppress missing implicit constructor warnings.
  factory PathSegArcRel._() { throw new UnsupportedError("Not supported"); }

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
@Unstable
class PathSegClosePath extends PathSeg native "SVGPathSegClosePath" {
  // To suppress missing implicit constructor warnings.
  factory PathSegClosePath._() { throw new UnsupportedError("Not supported"); }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGPathSegCurvetoCubicAbs')
@Unstable
class PathSegCurvetoCubicAbs extends PathSeg native "SVGPathSegCurvetoCubicAbs" {
  // To suppress missing implicit constructor warnings.
  factory PathSegCurvetoCubicAbs._() { throw new UnsupportedError("Not supported"); }

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
@Unstable
class PathSegCurvetoCubicRel extends PathSeg native "SVGPathSegCurvetoCubicRel" {
  // To suppress missing implicit constructor warnings.
  factory PathSegCurvetoCubicRel._() { throw new UnsupportedError("Not supported"); }

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
@Unstable
class PathSegCurvetoCubicSmoothAbs extends PathSeg native "SVGPathSegCurvetoCubicSmoothAbs" {
  // To suppress missing implicit constructor warnings.
  factory PathSegCurvetoCubicSmoothAbs._() { throw new UnsupportedError("Not supported"); }

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
@Unstable
class PathSegCurvetoCubicSmoothRel extends PathSeg native "SVGPathSegCurvetoCubicSmoothRel" {
  // To suppress missing implicit constructor warnings.
  factory PathSegCurvetoCubicSmoothRel._() { throw new UnsupportedError("Not supported"); }

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
@Unstable
class PathSegCurvetoQuadraticAbs extends PathSeg native "SVGPathSegCurvetoQuadraticAbs" {
  // To suppress missing implicit constructor warnings.
  factory PathSegCurvetoQuadraticAbs._() { throw new UnsupportedError("Not supported"); }

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
@Unstable
class PathSegCurvetoQuadraticRel extends PathSeg native "SVGPathSegCurvetoQuadraticRel" {
  // To suppress missing implicit constructor warnings.
  factory PathSegCurvetoQuadraticRel._() { throw new UnsupportedError("Not supported"); }

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
@Unstable
class PathSegCurvetoQuadraticSmoothAbs extends PathSeg native "SVGPathSegCurvetoQuadraticSmoothAbs" {
  // To suppress missing implicit constructor warnings.
  factory PathSegCurvetoQuadraticSmoothAbs._() { throw new UnsupportedError("Not supported"); }

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
@Unstable
class PathSegCurvetoQuadraticSmoothRel extends PathSeg native "SVGPathSegCurvetoQuadraticSmoothRel" {
  // To suppress missing implicit constructor warnings.
  factory PathSegCurvetoQuadraticSmoothRel._() { throw new UnsupportedError("Not supported"); }

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
@Unstable
class PathSegLinetoAbs extends PathSeg native "SVGPathSegLinetoAbs" {
  // To suppress missing implicit constructor warnings.
  factory PathSegLinetoAbs._() { throw new UnsupportedError("Not supported"); }

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
@Unstable
class PathSegLinetoHorizontalAbs extends PathSeg native "SVGPathSegLinetoHorizontalAbs" {
  // To suppress missing implicit constructor warnings.
  factory PathSegLinetoHorizontalAbs._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegLinetoHorizontalAbs.x')
  @DocsEditable
  num x;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGPathSegLinetoHorizontalRel')
@Unstable
class PathSegLinetoHorizontalRel extends PathSeg native "SVGPathSegLinetoHorizontalRel" {
  // To suppress missing implicit constructor warnings.
  factory PathSegLinetoHorizontalRel._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegLinetoHorizontalRel.x')
  @DocsEditable
  num x;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGPathSegLinetoRel')
@Unstable
class PathSegLinetoRel extends PathSeg native "SVGPathSegLinetoRel" {
  // To suppress missing implicit constructor warnings.
  factory PathSegLinetoRel._() { throw new UnsupportedError("Not supported"); }

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
@Unstable
class PathSegLinetoVerticalAbs extends PathSeg native "SVGPathSegLinetoVerticalAbs" {
  // To suppress missing implicit constructor warnings.
  factory PathSegLinetoVerticalAbs._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegLinetoVerticalAbs.y')
  @DocsEditable
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGPathSegLinetoVerticalRel')
@Unstable
class PathSegLinetoVerticalRel extends PathSeg native "SVGPathSegLinetoVerticalRel" {
  // To suppress missing implicit constructor warnings.
  factory PathSegLinetoVerticalRel._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegLinetoVerticalRel.y')
  @DocsEditable
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGPathSegList')
@Unstable
class PathSegList extends Interceptor with ListMixin<PathSeg>, ImmutableListMixin<PathSeg> implements JavaScriptIndexingBehavior, List<PathSeg> native "SVGPathSegList" {
  // To suppress missing implicit constructor warnings.
  factory PathSegList._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegList.numberOfItems')
  @DocsEditable
  final int numberOfItems;

  PathSeg operator[](int index) {
    if (JS("bool", "# >>> 0 !== # || # >= #", index,
        index, index, length))
      throw new RangeError.range(index, 0, length);
    return this.getItem(index);
  }
  void operator[]=(int index, PathSeg value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<PathSeg> mixins.
  // PathSeg is the element type.

  // SVG Collections expose numberOfItems rather than length.
  int get length => numberOfItems;

  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  PathSeg get first {
    if (this.length > 0) {
      return JS('PathSeg', '#[0]', this);
    }
    throw new StateError("No elements");
  }

  PathSeg get last {
    int len = this.length;
    if (len > 0) {
      return JS('PathSeg', '#[#]', this, len - 1);
    }
    throw new StateError("No elements");
  }

  PathSeg get single {
    int len = this.length;
    if (len == 1) {
      return JS('PathSeg', '#[0]', this);
    }
    if (len == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  PathSeg elementAt(int index) => this[index];
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
@Unstable
class PathSegMovetoAbs extends PathSeg native "SVGPathSegMovetoAbs" {
  // To suppress missing implicit constructor warnings.
  factory PathSegMovetoAbs._() { throw new UnsupportedError("Not supported"); }

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
@Unstable
class PathSegMovetoRel extends PathSeg native "SVGPathSegMovetoRel" {
  // To suppress missing implicit constructor warnings.
  factory PathSegMovetoRel._() { throw new UnsupportedError("Not supported"); }

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
@Unstable
class PatternElement extends StyledElement implements FitToViewBox, UriReference, Tests, ExternalResourcesRequired, LangSpace native "SVGPatternElement" {
  // To suppress missing implicit constructor warnings.
  factory PatternElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPatternElement.SVGPatternElement')
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
@Unstable
class Point native "SVGPoint" {
  // To suppress missing implicit constructor warnings.
  factory Point._() { throw new UnsupportedError("Not supported"); }

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
@Unstable
class PointList native "SVGPointList" {
  // To suppress missing implicit constructor warnings.
  factory PointList._() { throw new UnsupportedError("Not supported"); }

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
@Unstable
class PolygonElement extends StyledElement implements Transformable, Tests, ExternalResourcesRequired, LangSpace native "SVGPolygonElement" {
  // To suppress missing implicit constructor warnings.
  factory PolygonElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPolygonElement.SVGPolygonElement')
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
@Unstable
class PolylineElement extends StyledElement implements Transformable, Tests, ExternalResourcesRequired, LangSpace native "SVGPolylineElement" {
  // To suppress missing implicit constructor warnings.
  factory PolylineElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPolylineElement.SVGPolylineElement')
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
@Unstable
class PreserveAspectRatio native "SVGPreserveAspectRatio" {
  // To suppress missing implicit constructor warnings.
  factory PreserveAspectRatio._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPreserveAspectRatio.SVG_MEETORSLICE_MEET')
  @DocsEditable
  static const int SVG_MEETORSLICE_MEET = 1;

  @DomName('SVGPreserveAspectRatio.SVG_MEETORSLICE_SLICE')
  @DocsEditable
  static const int SVG_MEETORSLICE_SLICE = 2;

  @DomName('SVGPreserveAspectRatio.SVG_MEETORSLICE_UNKNOWN')
  @DocsEditable
  static const int SVG_MEETORSLICE_UNKNOWN = 0;

  @DomName('SVGPreserveAspectRatio.SVG_PRESERVEASPECTRATIO_NONE')
  @DocsEditable
  static const int SVG_PRESERVEASPECTRATIO_NONE = 1;

  @DomName('SVGPreserveAspectRatio.SVG_PRESERVEASPECTRATIO_UNKNOWN')
  @DocsEditable
  static const int SVG_PRESERVEASPECTRATIO_UNKNOWN = 0;

  @DomName('SVGPreserveAspectRatio.SVG_PRESERVEASPECTRATIO_XMAXYMAX')
  @DocsEditable
  static const int SVG_PRESERVEASPECTRATIO_XMAXYMAX = 10;

  @DomName('SVGPreserveAspectRatio.SVG_PRESERVEASPECTRATIO_XMAXYMID')
  @DocsEditable
  static const int SVG_PRESERVEASPECTRATIO_XMAXYMID = 7;

  @DomName('SVGPreserveAspectRatio.SVG_PRESERVEASPECTRATIO_XMAXYMIN')
  @DocsEditable
  static const int SVG_PRESERVEASPECTRATIO_XMAXYMIN = 4;

  @DomName('SVGPreserveAspectRatio.SVG_PRESERVEASPECTRATIO_XMIDYMAX')
  @DocsEditable
  static const int SVG_PRESERVEASPECTRATIO_XMIDYMAX = 9;

  @DomName('SVGPreserveAspectRatio.SVG_PRESERVEASPECTRATIO_XMIDYMID')
  @DocsEditable
  static const int SVG_PRESERVEASPECTRATIO_XMIDYMID = 6;

  @DomName('SVGPreserveAspectRatio.SVG_PRESERVEASPECTRATIO_XMIDYMIN')
  @DocsEditable
  static const int SVG_PRESERVEASPECTRATIO_XMIDYMIN = 3;

  @DomName('SVGPreserveAspectRatio.SVG_PRESERVEASPECTRATIO_XMINYMAX')
  @DocsEditable
  static const int SVG_PRESERVEASPECTRATIO_XMINYMAX = 8;

  @DomName('SVGPreserveAspectRatio.SVG_PRESERVEASPECTRATIO_XMINYMID')
  @DocsEditable
  static const int SVG_PRESERVEASPECTRATIO_XMINYMID = 5;

  @DomName('SVGPreserveAspectRatio.SVG_PRESERVEASPECTRATIO_XMINYMIN')
  @DocsEditable
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
@Unstable
class RadialGradientElement extends _GradientElement native "SVGRadialGradientElement" {
  // To suppress missing implicit constructor warnings.
  factory RadialGradientElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGRadialGradientElement.SVGRadialGradientElement')
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
@Unstable
class Rect native "SVGRect" {
  // To suppress missing implicit constructor warnings.
  factory Rect._() { throw new UnsupportedError("Not supported"); }

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
@Unstable
class RectElement extends StyledElement implements Transformable, Tests, ExternalResourcesRequired, LangSpace native "SVGRectElement" {
  // To suppress missing implicit constructor warnings.
  factory RectElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGRectElement.SVGRectElement')
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
@Unstable
class RenderingIntent native "SVGRenderingIntent" {
  // To suppress missing implicit constructor warnings.
  factory RenderingIntent._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGRenderingIntent.RENDERING_INTENT_ABSOLUTE_COLORIMETRIC')
  @DocsEditable
  static const int RENDERING_INTENT_ABSOLUTE_COLORIMETRIC = 5;

  @DomName('SVGRenderingIntent.RENDERING_INTENT_AUTO')
  @DocsEditable
  static const int RENDERING_INTENT_AUTO = 1;

  @DomName('SVGRenderingIntent.RENDERING_INTENT_PERCEPTUAL')
  @DocsEditable
  static const int RENDERING_INTENT_PERCEPTUAL = 2;

  @DomName('SVGRenderingIntent.RENDERING_INTENT_RELATIVE_COLORIMETRIC')
  @DocsEditable
  static const int RENDERING_INTENT_RELATIVE_COLORIMETRIC = 3;

  @DomName('SVGRenderingIntent.RENDERING_INTENT_SATURATION')
  @DocsEditable
  static const int RENDERING_INTENT_SATURATION = 4;

  @DomName('SVGRenderingIntent.RENDERING_INTENT_UNKNOWN')
  @DocsEditable
  static const int RENDERING_INTENT_UNKNOWN = 0;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGScriptElement')
@Unstable
class ScriptElement extends SvgElement implements UriReference, ExternalResourcesRequired native "SVGScriptElement" {
  // To suppress missing implicit constructor warnings.
  factory ScriptElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGScriptElement.SVGScriptElement')
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
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable
class SetElement extends AnimationElement native "SVGSetElement" {
  // To suppress missing implicit constructor warnings.
  factory SetElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGSetElement.SVGSetElement')
  @DocsEditable
  factory SetElement() => _SvgElementFactoryProvider.createSvgElement_tag("set");

  /// Checks if this type is supported on the current platform.
  static bool get supported => SvgElement.isTagSupported('set') && (new SvgElement.tag('set') is SetElement);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGStopElement')
@Unstable
class StopElement extends StyledElement native "SVGStopElement" {
  // To suppress missing implicit constructor warnings.
  factory StopElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGStopElement.SVGStopElement')
  @DocsEditable
  factory StopElement() => _SvgElementFactoryProvider.createSvgElement_tag("stop");

  @JSName('offset')
  @DomName('SVGStopElement.offset')
  @DocsEditable
  final AnimatedNumber gradientOffset;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGStringList')
@Unstable
class StringList extends Interceptor with ListMixin<String>, ImmutableListMixin<String> implements JavaScriptIndexingBehavior, List<String> native "SVGStringList" {
  // To suppress missing implicit constructor warnings.
  factory StringList._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGStringList.numberOfItems')
  @DocsEditable
  final int numberOfItems;

  String operator[](int index) {
    if (JS("bool", "# >>> 0 !== # || # >= #", index,
        index, index, length))
      throw new RangeError.range(index, 0, length);
    return this.getItem(index);
  }
  void operator[]=(int index, String value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<String> mixins.
  // String is the element type.

  // SVG Collections expose numberOfItems rather than length.
  int get length => numberOfItems;

  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  String get first {
    if (this.length > 0) {
      return JS('String', '#[0]', this);
    }
    throw new StateError("No elements");
  }

  String get last {
    int len = this.length;
    if (len > 0) {
      return JS('String', '#[#]', this, len - 1);
    }
    throw new StateError("No elements");
  }

  String get single {
    int len = this.length;
    if (len == 1) {
      return JS('String', '#[0]', this);
    }
    if (len == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  String elementAt(int index) => this[index];
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


@DocsEditable
@DomName('SVGStyleElement')
// http://www.w3.org/TR/SVG/types.html#InterfaceSVGStylable
@Experimental // nonstandard
class StyleElement extends SvgElement implements LangSpace native "SVGStyleElement" {
  // To suppress missing implicit constructor warnings.
  factory StyleElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGStyleElement.SVGStyleElement')
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
@DomName('SVGStyledElement')
@Unstable
class StyledElement extends SvgElement native "SVGStyledElement" {
  // To suppress missing implicit constructor warnings.
  factory StyledElement._() { throw new UnsupportedError("Not supported"); }

  // Shadowing definition.
  AnimatedString get $dom_svgClassName => JS("AnimatedString", "#.className", this);

  // Use implementation from Element.
  // final CssStyleDeclaration style;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGDocument')
@Unstable
class SvgDocument extends Document native "SVGDocument" {
  // To suppress missing implicit constructor warnings.
  factory SvgDocument._() { throw new UnsupportedError("Not supported"); }

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


class _AttributeClassSet extends CssClassSetImpl {
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
@Unstable
class SvgElement extends Element native "SVGElement" {
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

  List<Element> get children => new FilteredElementList<Element>(this);

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
  // To suppress missing implicit constructor warnings.
  factory SvgElement._() { throw new UnsupportedError("Not supported"); }

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
@Unstable
class SvgException native "SVGException" {
  // To suppress missing implicit constructor warnings.
  factory SvgException._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGException.SVG_INVALID_VALUE_ERR')
  @DocsEditable
  static const int SVG_INVALID_VALUE_ERR = 1;

  @DomName('SVGException.SVG_MATRIX_NOT_INVERTABLE')
  @DocsEditable
  static const int SVG_MATRIX_NOT_INVERTABLE = 2;

  @DomName('SVGException.SVG_WRONG_TYPE_ERR')
  @DocsEditable
  static const int SVG_WRONG_TYPE_ERR = 0;

  @DomName('SVGException.code')
  @DocsEditable
  final int code;

  @DomName('SVGException.message')
  @DocsEditable
  @Experimental // nonstandard
  final String message;

  @DomName('SVGException.name')
  @DocsEditable
  @Experimental // nonstandard
  final String name;

  @DomName('SVGException.toString')
  @DocsEditable
  String toString() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('SVGSVGElement')
@Unstable
class SvgSvgElement extends StyledElement implements FitToViewBox, Transformable, Tests, ExternalResourcesRequired, ZoomAndPan, LangSpace native "SVGSVGElement" {
  factory SvgSvgElement() => _SvgSvgElementFactoryProvider.createSvgSvgElement();

  // To suppress missing implicit constructor warnings.
  factory SvgSvgElement._() { throw new UnsupportedError("Not supported"); }

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

  // From SVGTransformable

  @DomName('SVGSVGElement.transform')
  @DocsEditable
  final AnimatedTransformList transform;

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
@Unstable
class SwitchElement extends StyledElement implements Transformable, Tests, ExternalResourcesRequired, LangSpace native "SVGSwitchElement" {
  // To suppress missing implicit constructor warnings.
  factory SwitchElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGSwitchElement.SVGSwitchElement')
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
@Unstable
class SymbolElement extends StyledElement implements FitToViewBox, ExternalResourcesRequired, LangSpace native "SVGSymbolElement" {
  // To suppress missing implicit constructor warnings.
  factory SymbolElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGSymbolElement.SVGSymbolElement')
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
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGTSpanElement')
@Unstable
class TSpanElement extends TextPositioningElement native "SVGTSpanElement" {
  // To suppress missing implicit constructor warnings.
  factory TSpanElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGTSpanElement.SVGTSpanElement')
  @DocsEditable
  factory TSpanElement() => _SvgElementFactoryProvider.createSvgElement_tag("tspan");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('SVGTests')
@Unstable
abstract class Tests {
  // To suppress missing implicit constructor warnings.
  factory Tests._() { throw new UnsupportedError("Not supported"); }

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
@Unstable
class TextContentElement extends StyledElement implements Tests, ExternalResourcesRequired, LangSpace native "SVGTextContentElement" {
  // To suppress missing implicit constructor warnings.
  factory TextContentElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGTextContentElement.LENGTHADJUST_SPACING')
  @DocsEditable
  static const int LENGTHADJUST_SPACING = 1;

  @DomName('SVGTextContentElement.LENGTHADJUST_SPACINGANDGLYPHS')
  @DocsEditable
  static const int LENGTHADJUST_SPACINGANDGLYPHS = 2;

  @DomName('SVGTextContentElement.LENGTHADJUST_UNKNOWN')
  @DocsEditable
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
@Unstable
class TextElement extends TextPositioningElement implements Transformable native "SVGTextElement" {
  // To suppress missing implicit constructor warnings.
  factory TextElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGTextElement.SVGTextElement')
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
@Unstable
class TextPathElement extends TextContentElement implements UriReference native "SVGTextPathElement" {
  // To suppress missing implicit constructor warnings.
  factory TextPathElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGTextPathElement.TEXTPATH_METHODTYPE_ALIGN')
  @DocsEditable
  static const int TEXTPATH_METHODTYPE_ALIGN = 1;

  @DomName('SVGTextPathElement.TEXTPATH_METHODTYPE_STRETCH')
  @DocsEditable
  static const int TEXTPATH_METHODTYPE_STRETCH = 2;

  @DomName('SVGTextPathElement.TEXTPATH_METHODTYPE_UNKNOWN')
  @DocsEditable
  static const int TEXTPATH_METHODTYPE_UNKNOWN = 0;

  @DomName('SVGTextPathElement.TEXTPATH_SPACINGTYPE_AUTO')
  @DocsEditable
  static const int TEXTPATH_SPACINGTYPE_AUTO = 1;

  @DomName('SVGTextPathElement.TEXTPATH_SPACINGTYPE_EXACT')
  @DocsEditable
  static const int TEXTPATH_SPACINGTYPE_EXACT = 2;

  @DomName('SVGTextPathElement.TEXTPATH_SPACINGTYPE_UNKNOWN')
  @DocsEditable
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
@Unstable
class TextPositioningElement extends TextContentElement native "SVGTextPositioningElement" {
  // To suppress missing implicit constructor warnings.
  factory TextPositioningElement._() { throw new UnsupportedError("Not supported"); }

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
@Unstable
class TitleElement extends StyledElement implements LangSpace native "SVGTitleElement" {
  // To suppress missing implicit constructor warnings.
  factory TitleElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGTitleElement.SVGTitleElement')
  @DocsEditable
  factory TitleElement() => _SvgElementFactoryProvider.createSvgElement_tag("title");

  // From SVGLangSpace

  @DomName('SVGTitleElement.xmllang')
  @DocsEditable
  String xmllang;

  @DomName('SVGTitleElement.xmlspace')
  @DocsEditable
  String xmlspace;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGTransform')
@Unstable
class Transform native "SVGTransform" {
  // To suppress missing implicit constructor warnings.
  factory Transform._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGTransform.SVG_TRANSFORM_MATRIX')
  @DocsEditable
  static const int SVG_TRANSFORM_MATRIX = 1;

  @DomName('SVGTransform.SVG_TRANSFORM_ROTATE')
  @DocsEditable
  static const int SVG_TRANSFORM_ROTATE = 4;

  @DomName('SVGTransform.SVG_TRANSFORM_SCALE')
  @DocsEditable
  static const int SVG_TRANSFORM_SCALE = 3;

  @DomName('SVGTransform.SVG_TRANSFORM_SKEWX')
  @DocsEditable
  static const int SVG_TRANSFORM_SKEWX = 5;

  @DomName('SVGTransform.SVG_TRANSFORM_SKEWY')
  @DocsEditable
  static const int SVG_TRANSFORM_SKEWY = 6;

  @DomName('SVGTransform.SVG_TRANSFORM_TRANSLATE')
  @DocsEditable
  static const int SVG_TRANSFORM_TRANSLATE = 2;

  @DomName('SVGTransform.SVG_TRANSFORM_UNKNOWN')
  @DocsEditable
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
@Unstable
class TransformList extends Interceptor with ListMixin<Transform>, ImmutableListMixin<Transform> implements List<Transform>, JavaScriptIndexingBehavior native "SVGTransformList" {
  // To suppress missing implicit constructor warnings.
  factory TransformList._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGTransformList.numberOfItems')
  @DocsEditable
  final int numberOfItems;

  Transform operator[](int index) {
    if (JS("bool", "# >>> 0 !== # || # >= #", index,
        index, index, length))
      throw new RangeError.range(index, 0, length);
    return this.getItem(index);
  }
  void operator[]=(int index, Transform value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Transform> mixins.
  // Transform is the element type.

  // SVG Collections expose numberOfItems rather than length.
  int get length => numberOfItems;

  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  Transform get first {
    if (this.length > 0) {
      return JS('Transform', '#[0]', this);
    }
    throw new StateError("No elements");
  }

  Transform get last {
    int len = this.length;
    if (len > 0) {
      return JS('Transform', '#[#]', this, len - 1);
    }
    throw new StateError("No elements");
  }

  Transform get single {
    int len = this.length;
    if (len == 1) {
      return JS('Transform', '#[0]', this);
    }
    if (len == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  Transform elementAt(int index) => this[index];
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
@Unstable
abstract class Transformable implements Locatable {
  // To suppress missing implicit constructor warnings.
  factory Transformable._() { throw new UnsupportedError("Not supported"); }

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
@Unstable
class UnitTypes native "SVGUnitTypes" {
  // To suppress missing implicit constructor warnings.
  factory UnitTypes._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGUnitTypes.SVG_UNIT_TYPE_OBJECTBOUNDINGBOX')
  @DocsEditable
  static const int SVG_UNIT_TYPE_OBJECTBOUNDINGBOX = 2;

  @DomName('SVGUnitTypes.SVG_UNIT_TYPE_UNKNOWN')
  @DocsEditable
  static const int SVG_UNIT_TYPE_UNKNOWN = 0;

  @DomName('SVGUnitTypes.SVG_UNIT_TYPE_USERSPACEONUSE')
  @DocsEditable
  static const int SVG_UNIT_TYPE_USERSPACEONUSE = 1;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('SVGURIReference')
@Unstable
abstract class UriReference {
  // To suppress missing implicit constructor warnings.
  factory UriReference._() { throw new UnsupportedError("Not supported"); }

  AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGUseElement')
@Unstable
class UseElement extends StyledElement implements UriReference, Tests, Transformable, ExternalResourcesRequired, LangSpace native "SVGUseElement" {
  // To suppress missing implicit constructor warnings.
  factory UseElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGUseElement.SVGUseElement')
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
@DomName('SVGViewElement')
@Unstable
class ViewElement extends SvgElement implements FitToViewBox, ExternalResourcesRequired, ZoomAndPan native "SVGViewElement" {
  // To suppress missing implicit constructor warnings.
  factory ViewElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGViewElement.SVGViewElement')
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
@Unstable
class ViewSpec native "SVGViewSpec" {
  // To suppress missing implicit constructor warnings.
  factory ViewSpec._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGViewSpec.preserveAspectRatio')
  @DocsEditable
  @Experimental // nonstandard
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
  @Experimental // nonstandard
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
  @Experimental // nonstandard
  int zoomAndPan;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('SVGZoomAndPan')
@Unstable
abstract class ZoomAndPan {
  // To suppress missing implicit constructor warnings.
  factory ZoomAndPan._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGZoomAndPan.SVG_ZOOMANDPAN_DISABLE')
  @DocsEditable
  static const int SVG_ZOOMANDPAN_DISABLE = 1;

  @DomName('SVGZoomAndPan.SVG_ZOOMANDPAN_MAGNIFY')
  @DocsEditable
  static const int SVG_ZOOMANDPAN_MAGNIFY = 2;

  @DomName('SVGZoomAndPan.SVG_ZOOMANDPAN_UNKNOWN')
  @DocsEditable
  static const int SVG_ZOOMANDPAN_UNKNOWN = 0;

  int zoomAndPan;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGZoomEvent')
@Unstable
class ZoomEvent extends UIEvent native "SVGZoomEvent" {
  // To suppress missing implicit constructor warnings.
  factory ZoomEvent._() { throw new UnsupportedError("Not supported"); }

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
@Unstable
class _ElementInstanceList extends Interceptor with ListMixin<ElementInstance>, ImmutableListMixin<ElementInstance> implements JavaScriptIndexingBehavior, List<ElementInstance> native "SVGElementInstanceList" {
  // To suppress missing implicit constructor warnings.
  factory _ElementInstanceList._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGElementInstanceList.length')
  @DocsEditable
  int get length => JS("int", "#.length", this);

  ElementInstance operator[](int index) {
    if (JS("bool", "# >>> 0 !== # || # >= #", index,
        index, index, length))
      throw new RangeError.range(index, 0, length);
    return this.item(index);
  }
  void operator[]=(int index, ElementInstance value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<ElementInstance> mixins.
  // ElementInstance is the element type.


  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  ElementInstance get first {
    if (this.length > 0) {
      return JS('ElementInstance', '#[0]', this);
    }
    throw new StateError("No elements");
  }

  ElementInstance get last {
    int len = this.length;
    if (len > 0) {
      return JS('ElementInstance', '#[#]', this, len - 1);
    }
    throw new StateError("No elements");
  }

  ElementInstance get single {
    int len = this.length;
    if (len == 1) {
      return JS('ElementInstance', '#[0]', this);
    }
    if (len == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  ElementInstance elementAt(int index) => this[index];
  // -- end List<ElementInstance> mixins.

  @DomName('SVGElementInstanceList.item')
  @DocsEditable
  ElementInstance item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGGradientElement')
@Unstable
class _GradientElement extends StyledElement implements UriReference, ExternalResourcesRequired native "SVGGradientElement" {
  // To suppress missing implicit constructor warnings.
  factory _GradientElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGGradientElement.SVG_SPREADMETHOD_PAD')
  @DocsEditable
  static const int SVG_SPREADMETHOD_PAD = 1;

  @DomName('SVGGradientElement.SVG_SPREADMETHOD_REFLECT')
  @DocsEditable
  static const int SVG_SPREADMETHOD_REFLECT = 2;

  @DomName('SVGGradientElement.SVG_SPREADMETHOD_REPEAT')
  @DocsEditable
  static const int SVG_SPREADMETHOD_REPEAT = 3;

  @DomName('SVGGradientElement.SVG_SPREADMETHOD_UNKNOWN')
  @DocsEditable
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

  // From SVGURIReference

  @DomName('SVGGradientElement.href')
  @DocsEditable
  final AnimatedString href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGAltGlyphDefElement')
@Unstable
abstract class _SVGAltGlyphDefElement extends SvgElement native "SVGAltGlyphDefElement" {
  // To suppress missing implicit constructor warnings.
  factory _SVGAltGlyphDefElement._() { throw new UnsupportedError("Not supported"); }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGAltGlyphItemElement')
@Unstable
abstract class _SVGAltGlyphItemElement extends SvgElement native "SVGAltGlyphItemElement" {
  // To suppress missing implicit constructor warnings.
  factory _SVGAltGlyphItemElement._() { throw new UnsupportedError("Not supported"); }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGAnimateColorElement')
@Unstable
abstract class _SVGAnimateColorElement extends AnimationElement native "SVGAnimateColorElement" {
  // To suppress missing implicit constructor warnings.
  factory _SVGAnimateColorElement._() { throw new UnsupportedError("Not supported"); }
}
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// Hack because the baseclass is private in dart:html, and we want to omit this
// type entirely but can't.
@DocsEditable
@DomName('SVGColor')
@Unstable
abstract class _SVGColor native "SVGColor" {
  _SVGColor.internal();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGComponentTransferFunctionElement')
@Unstable
abstract class _SVGComponentTransferFunctionElement extends SvgElement native "SVGComponentTransferFunctionElement" {
  // To suppress missing implicit constructor warnings.
  factory _SVGComponentTransferFunctionElement._() { throw new UnsupportedError("Not supported"); }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGCursorElement')
@Unstable
abstract class _SVGCursorElement extends SvgElement implements UriReference, Tests, ExternalResourcesRequired native "SVGCursorElement" {
  // To suppress missing implicit constructor warnings.
  factory _SVGCursorElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGCursorElement.SVGCursorElement')
  @DocsEditable
  factory _SVGCursorElement() => _SvgElementFactoryProvider.createSvgElement_tag("cursor");

  /// Checks if this type is supported on the current platform.
  static bool get supported => SvgElement.isTagSupported('cursor') && (new SvgElement.tag('cursor') is _SVGCursorElement);

  // From SVGExternalResourcesRequired

  // From SVGTests

  // From SVGURIReference
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGFEDropShadowElement')
@Experimental // nonstandard
abstract class _SVGFEDropShadowElement extends StyledElement implements FilterPrimitiveStandardAttributes native "SVGFEDropShadowElement" {
  // To suppress missing implicit constructor warnings.
  factory _SVGFEDropShadowElement._() { throw new UnsupportedError("Not supported"); }

  // From SVGFilterPrimitiveStandardAttributes
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGFontElement')
@Unstable
abstract class _SVGFontElement extends SvgElement native "SVGFontElement" {
  // To suppress missing implicit constructor warnings.
  factory _SVGFontElement._() { throw new UnsupportedError("Not supported"); }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGFontFaceElement')
@Unstable
abstract class _SVGFontFaceElement extends SvgElement native "SVGFontFaceElement" {
  // To suppress missing implicit constructor warnings.
  factory _SVGFontFaceElement._() { throw new UnsupportedError("Not supported"); }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGFontFaceFormatElement')
@Unstable
abstract class _SVGFontFaceFormatElement extends SvgElement native "SVGFontFaceFormatElement" {
  // To suppress missing implicit constructor warnings.
  factory _SVGFontFaceFormatElement._() { throw new UnsupportedError("Not supported"); }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGFontFaceNameElement')
@Unstable
abstract class _SVGFontFaceNameElement extends SvgElement native "SVGFontFaceNameElement" {
  // To suppress missing implicit constructor warnings.
  factory _SVGFontFaceNameElement._() { throw new UnsupportedError("Not supported"); }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGFontFaceSrcElement')
@Unstable
abstract class _SVGFontFaceSrcElement extends SvgElement native "SVGFontFaceSrcElement" {
  // To suppress missing implicit constructor warnings.
  factory _SVGFontFaceSrcElement._() { throw new UnsupportedError("Not supported"); }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGFontFaceUriElement')
@Unstable
abstract class _SVGFontFaceUriElement extends SvgElement native "SVGFontFaceUriElement" {
  // To suppress missing implicit constructor warnings.
  factory _SVGFontFaceUriElement._() { throw new UnsupportedError("Not supported"); }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGGlyphElement')
@Unstable
abstract class _SVGGlyphElement extends SvgElement native "SVGGlyphElement" {
  // To suppress missing implicit constructor warnings.
  factory _SVGGlyphElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGGlyphElement.SVGGlyphElement')
  @DocsEditable
  factory _SVGGlyphElement() => _SvgElementFactoryProvider.createSvgElement_tag("glyph");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGGlyphRefElement')
@Unstable
abstract class _SVGGlyphRefElement extends StyledElement implements UriReference native "SVGGlyphRefElement" {
  // To suppress missing implicit constructor warnings.
  factory _SVGGlyphRefElement._() { throw new UnsupportedError("Not supported"); }

  // From SVGURIReference
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGHKernElement')
@Unstable
abstract class _SVGHKernElement extends SvgElement native "SVGHKernElement" {
  // To suppress missing implicit constructor warnings.
  factory _SVGHKernElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGHKernElement.SVGHKernElement')
  @DocsEditable
  factory _SVGHKernElement() => _SvgElementFactoryProvider.createSvgElement_tag("hkern");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGMPathElement')
abstract class _SVGMPathElement extends SvgElement implements UriReference, ExternalResourcesRequired native "SVGMPathElement" {
  // To suppress missing implicit constructor warnings.
  factory _SVGMPathElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGMPathElement.SVGMPathElement')
  @DocsEditable
  factory _SVGMPathElement() => _SvgElementFactoryProvider.createSvgElement_tag("mpath");

  // From SVGExternalResourcesRequired

  // From SVGURIReference
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGMissingGlyphElement')
@Unstable
abstract class _SVGMissingGlyphElement extends StyledElement native "SVGMissingGlyphElement" {
  // To suppress missing implicit constructor warnings.
  factory _SVGMissingGlyphElement._() { throw new UnsupportedError("Not supported"); }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGPaint')
@Unstable
abstract class _SVGPaint extends _SVGColor native "SVGPaint" {
  // To suppress missing implicit constructor warnings.
  factory _SVGPaint._() { throw new UnsupportedError("Not supported"); }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGTRefElement')
@Unstable
abstract class _SVGTRefElement extends TextPositioningElement implements UriReference native "SVGTRefElement" {
  // To suppress missing implicit constructor warnings.
  factory _SVGTRefElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGTRefElement.SVGTRefElement')
  @DocsEditable
  factory _SVGTRefElement() => _SvgElementFactoryProvider.createSvgElement_tag("tref");

  // From SVGURIReference
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SVGVKernElement')
@Unstable
abstract class _SVGVKernElement extends SvgElement native "SVGVKernElement" {
  // To suppress missing implicit constructor warnings.
  factory _SVGVKernElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGVKernElement.SVGVKernElement')
  @DocsEditable
  factory _SVGVKernElement() => _SvgElementFactoryProvider.createSvgElement_tag("vkern");
}
