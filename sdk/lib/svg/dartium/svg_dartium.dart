library dart.dom.svg;

import 'dart:async';
import 'dart:collection';
import 'dart:_internal' hide deprecated;
import 'dart:html';
import 'dart:html_common';
import 'dart:nativewrappers';
import 'dart:_blink' as _blink;
// DO NOT EDIT
// Auto-generated dart:svg library.





// FIXME: Can we make this private?
const svgBlinkMap = const {
  'SVGAElement': AElement,
  'SVGAltGlyphDefElement': _SVGAltGlyphDefElement,
  'SVGAltGlyphElement': AltGlyphElement,
  'SVGAltGlyphItemElement': _SVGAltGlyphItemElement,
  'SVGAngle': Angle,
  'SVGAnimateElement': AnimateElement,
  'SVGAnimateMotionElement': AnimateMotionElement,
  'SVGAnimateTransformElement': AnimateTransformElement,
  'SVGAnimatedAngle': AnimatedAngle,
  'SVGAnimatedBoolean': AnimatedBoolean,
  'SVGAnimatedEnumeration': AnimatedEnumeration,
  'SVGAnimatedInteger': AnimatedInteger,
  'SVGAnimatedLength': AnimatedLength,
  'SVGAnimatedLengthList': AnimatedLengthList,
  'SVGAnimatedNumber': AnimatedNumber,
  'SVGAnimatedNumberList': AnimatedNumberList,
  'SVGAnimatedPreserveAspectRatio': AnimatedPreserveAspectRatio,
  'SVGAnimatedRect': AnimatedRect,
  'SVGAnimatedString': AnimatedString,
  'SVGAnimatedTransformList': AnimatedTransformList,
  'SVGAnimationElement': AnimationElement,
  'SVGCircleElement': CircleElement,
  'SVGClipPathElement': ClipPathElement,
  'SVGComponentTransferFunctionElement': _SVGComponentTransferFunctionElement,
  'SVGCursorElement': _SVGCursorElement,
  'SVGDefsElement': DefsElement,
  'SVGDescElement': DescElement,
  'SVGDiscardElement': DiscardElement,
  'SVGElement': SvgElement,
  'SVGElementInstance': ElementInstance,
  'SVGElementInstanceList': _ElementInstanceList,
  'SVGEllipseElement': EllipseElement,
  'SVGFEBlendElement': FEBlendElement,
  'SVGFEColorMatrixElement': FEColorMatrixElement,
  'SVGFEComponentTransferElement': FEComponentTransferElement,
  'SVGFECompositeElement': FECompositeElement,
  'SVGFEConvolveMatrixElement': FEConvolveMatrixElement,
  'SVGFEDiffuseLightingElement': FEDiffuseLightingElement,
  'SVGFEDisplacementMapElement': FEDisplacementMapElement,
  'SVGFEDistantLightElement': FEDistantLightElement,
  'SVGFEDropShadowElement': _SVGFEDropShadowElement,
  'SVGFEFloodElement': FEFloodElement,
  'SVGFEFuncAElement': FEFuncAElement,
  'SVGFEFuncBElement': FEFuncBElement,
  'SVGFEFuncGElement': FEFuncGElement,
  'SVGFEFuncRElement': FEFuncRElement,
  'SVGFEGaussianBlurElement': FEGaussianBlurElement,
  'SVGFEImageElement': FEImageElement,
  'SVGFEMergeElement': FEMergeElement,
  'SVGFEMergeNodeElement': FEMergeNodeElement,
  'SVGFEMorphologyElement': FEMorphologyElement,
  'SVGFEOffsetElement': FEOffsetElement,
  'SVGFEPointLightElement': FEPointLightElement,
  'SVGFESpecularLightingElement': FESpecularLightingElement,
  'SVGFESpotLightElement': FESpotLightElement,
  'SVGFETileElement': FETileElement,
  'SVGFETurbulenceElement': FETurbulenceElement,
  'SVGFilterElement': FilterElement,
  'SVGFilterPrimitiveStandardAttributes': FilterPrimitiveStandardAttributes,
  'SVGFitToViewBox': FitToViewBox,
  'SVGFontElement': _SVGFontElement,
  'SVGFontFaceElement': _SVGFontFaceElement,
  'SVGFontFaceFormatElement': _SVGFontFaceFormatElement,
  'SVGFontFaceNameElement': _SVGFontFaceNameElement,
  'SVGFontFaceSrcElement': _SVGFontFaceSrcElement,
  'SVGFontFaceUriElement': _SVGFontFaceUriElement,
  'SVGForeignObjectElement': ForeignObjectElement,
  'SVGGElement': GElement,
  'SVGGeometryElement': GeometryElement,
  'SVGGlyphElement': _SVGGlyphElement,
  'SVGGlyphRefElement': _SVGGlyphRefElement,
  'SVGGradientElement': _GradientElement,
  'SVGGraphicsElement': GraphicsElement,
  'SVGHKernElement': _SVGHKernElement,
  'SVGImageElement': ImageElement,
  'SVGLength': Length,
  'SVGLengthList': LengthList,
  'SVGLineElement': LineElement,
  'SVGLinearGradientElement': LinearGradientElement,
  'SVGMPathElement': _SVGMPathElement,
  'SVGMarkerElement': MarkerElement,
  'SVGMaskElement': MaskElement,
  'SVGMatrix': Matrix,
  'SVGMetadataElement': MetadataElement,
  'SVGMissingGlyphElement': _SVGMissingGlyphElement,
  'SVGNumber': Number,
  'SVGNumberList': NumberList,
  'SVGPathElement': PathElement,
  'SVGPathSeg': PathSeg,
  'SVGPathSegArcAbs': PathSegArcAbs,
  'SVGPathSegArcRel': PathSegArcRel,
  'SVGPathSegClosePath': PathSegClosePath,
  'SVGPathSegCurvetoCubicAbs': PathSegCurvetoCubicAbs,
  'SVGPathSegCurvetoCubicRel': PathSegCurvetoCubicRel,
  'SVGPathSegCurvetoCubicSmoothAbs': PathSegCurvetoCubicSmoothAbs,
  'SVGPathSegCurvetoCubicSmoothRel': PathSegCurvetoCubicSmoothRel,
  'SVGPathSegCurvetoQuadraticAbs': PathSegCurvetoQuadraticAbs,
  'SVGPathSegCurvetoQuadraticRel': PathSegCurvetoQuadraticRel,
  'SVGPathSegCurvetoQuadraticSmoothAbs': PathSegCurvetoQuadraticSmoothAbs,
  'SVGPathSegCurvetoQuadraticSmoothRel': PathSegCurvetoQuadraticSmoothRel,
  'SVGPathSegLinetoAbs': PathSegLinetoAbs,
  'SVGPathSegLinetoHorizontalAbs': PathSegLinetoHorizontalAbs,
  'SVGPathSegLinetoHorizontalRel': PathSegLinetoHorizontalRel,
  'SVGPathSegLinetoRel': PathSegLinetoRel,
  'SVGPathSegLinetoVerticalAbs': PathSegLinetoVerticalAbs,
  'SVGPathSegLinetoVerticalRel': PathSegLinetoVerticalRel,
  'SVGPathSegList': PathSegList,
  'SVGPathSegMovetoAbs': PathSegMovetoAbs,
  'SVGPathSegMovetoRel': PathSegMovetoRel,
  'SVGPatternElement': PatternElement,
  'SVGPoint': Point,
  'SVGPointList': PointList,
  'SVGPolygonElement': PolygonElement,
  'SVGPolylineElement': PolylineElement,
  'SVGPreserveAspectRatio': PreserveAspectRatio,
  'SVGRadialGradientElement': RadialGradientElement,
  'SVGRect': Rect,
  'SVGRectElement': RectElement,
  'SVGRenderingIntent': RenderingIntent,
  'SVGSVGElement': SvgSvgElement,
  'SVGScriptElement': ScriptElement,
  'SVGSetElement': SetElement,
  'SVGStopElement': StopElement,
  'SVGStringList': StringList,
  'SVGStyleElement': StyleElement,
  'SVGSwitchElement': SwitchElement,
  'SVGSymbolElement': SymbolElement,
  'SVGTSpanElement': TSpanElement,
  'SVGTests': Tests,
  'SVGTextContentElement': TextContentElement,
  'SVGTextElement': TextElement,
  'SVGTextPathElement': TextPathElement,
  'SVGTextPositioningElement': TextPositioningElement,
  'SVGTitleElement': TitleElement,
  'SVGTransform': Transform,
  'SVGTransformList': TransformList,
  'SVGURIReference': UriReference,
  'SVGUnitTypes': UnitTypes,
  'SVGUseElement': UseElement,
  'SVGVKernElement': _SVGVKernElement,
  'SVGViewElement': ViewElement,
  'SVGViewSpec': ViewSpec,
  'SVGZoomAndPan': ZoomAndPan,
  'SVGZoomEvent': ZoomEvent,

};
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _SvgElementFactoryProvider {
  static SvgElement createSvgElement_tag(String tag) {
    final Element temp =
      document.createElementNS("http://www.w3.org/2000/svg", tag);
    return temp;
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAElement')
@Unstable()
class AElement extends GraphicsElement implements UriReference {
  // To suppress missing implicit constructor warnings.
  factory AElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAElement.SVGAElement')
  @DocsEditable()
  factory AElement() => _SvgElementFactoryProvider.createSvgElement_tag("a");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  AElement.created() : super.created();

  @DomName('SVGAElement.target')
  @DocsEditable()
  AnimatedString get target => _blink.Native_SVGAElement_target_Getter(this);

  @DomName('SVGAElement.href')
  @DocsEditable()
  AnimatedString get href => _blink.Native_SVGAElement_href_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAltGlyphElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class AltGlyphElement extends TextPositioningElement implements UriReference {
  // To suppress missing implicit constructor warnings.
  factory AltGlyphElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAltGlyphElement.SVGAltGlyphElement')
  @DocsEditable()
  factory AltGlyphElement() => _SvgElementFactoryProvider.createSvgElement_tag("altGlyph");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  AltGlyphElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGAltGlyphElement.format')
  @DocsEditable()
  String get format => _blink.Native_SVGAltGlyphElement_format_Getter(this);

  @DomName('SVGAltGlyphElement.format')
  @DocsEditable()
  void set format(String value) => _blink.Native_SVGAltGlyphElement_format_Setter(this, value);

  @DomName('SVGAltGlyphElement.glyphRef')
  @DocsEditable()
  String get glyphRef => _blink.Native_SVGAltGlyphElement_glyphRef_Getter(this);

  @DomName('SVGAltGlyphElement.glyphRef')
  @DocsEditable()
  void set glyphRef(String value) => _blink.Native_SVGAltGlyphElement_glyphRef_Setter(this, value);

  @DomName('SVGAltGlyphElement.href')
  @DocsEditable()
  AnimatedString get href => _blink.Native_SVGAltGlyphElement_href_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAngle')
@Unstable()
class Angle extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory Angle._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAngle.SVG_ANGLETYPE_DEG')
  @DocsEditable()
  static const int SVG_ANGLETYPE_DEG = 2;

  @DomName('SVGAngle.SVG_ANGLETYPE_GRAD')
  @DocsEditable()
  static const int SVG_ANGLETYPE_GRAD = 4;

  @DomName('SVGAngle.SVG_ANGLETYPE_RAD')
  @DocsEditable()
  static const int SVG_ANGLETYPE_RAD = 3;

  @DomName('SVGAngle.SVG_ANGLETYPE_UNKNOWN')
  @DocsEditable()
  static const int SVG_ANGLETYPE_UNKNOWN = 0;

  @DomName('SVGAngle.SVG_ANGLETYPE_UNSPECIFIED')
  @DocsEditable()
  static const int SVG_ANGLETYPE_UNSPECIFIED = 1;

  @DomName('SVGAngle.unitType')
  @DocsEditable()
  int get unitType => _blink.Native_SVGAngle_unitType_Getter(this);

  @DomName('SVGAngle.value')
  @DocsEditable()
  num get value => _blink.Native_SVGAngle_value_Getter(this);

  @DomName('SVGAngle.value')
  @DocsEditable()
  void set value(num value) => _blink.Native_SVGAngle_value_Setter(this, value);

  @DomName('SVGAngle.valueAsString')
  @DocsEditable()
  String get valueAsString => _blink.Native_SVGAngle_valueAsString_Getter(this);

  @DomName('SVGAngle.valueAsString')
  @DocsEditable()
  void set valueAsString(String value) => _blink.Native_SVGAngle_valueAsString_Setter(this, value);

  @DomName('SVGAngle.valueInSpecifiedUnits')
  @DocsEditable()
  num get valueInSpecifiedUnits => _blink.Native_SVGAngle_valueInSpecifiedUnits_Getter(this);

  @DomName('SVGAngle.valueInSpecifiedUnits')
  @DocsEditable()
  void set valueInSpecifiedUnits(num value) => _blink.Native_SVGAngle_valueInSpecifiedUnits_Setter(this, value);

  @DomName('SVGAngle.convertToSpecifiedUnits')
  @DocsEditable()
  void convertToSpecifiedUnits(int unitType) => _blink.Native_SVGAngle_convertToSpecifiedUnits_Callback(this, unitType);

  @DomName('SVGAngle.newValueSpecifiedUnits')
  @DocsEditable()
  void newValueSpecifiedUnits(int unitType, num valueInSpecifiedUnits) => _blink.Native_SVGAngle_newValueSpecifiedUnits_Callback(this, unitType, valueInSpecifiedUnits);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAnimateElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class AnimateElement extends AnimationElement {
  // To suppress missing implicit constructor warnings.
  factory AnimateElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAnimateElement.SVGAnimateElement')
  @DocsEditable()
  factory AnimateElement() => _SvgElementFactoryProvider.createSvgElement_tag("animate");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  AnimateElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAnimateMotionElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class AnimateMotionElement extends AnimationElement {
  // To suppress missing implicit constructor warnings.
  factory AnimateMotionElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAnimateMotionElement.SVGAnimateMotionElement')
  @DocsEditable()
  factory AnimateMotionElement() => _SvgElementFactoryProvider.createSvgElement_tag("animateMotion");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  AnimateMotionElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAnimateTransformElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class AnimateTransformElement extends AnimationElement {
  // To suppress missing implicit constructor warnings.
  factory AnimateTransformElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAnimateTransformElement.SVGAnimateTransformElement')
  @DocsEditable()
  factory AnimateTransformElement() => _SvgElementFactoryProvider.createSvgElement_tag("animateTransform");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  AnimateTransformElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAnimatedAngle')
@Unstable()
class AnimatedAngle extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory AnimatedAngle._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAnimatedAngle.animVal')
  @DocsEditable()
  Angle get animVal => _blink.Native_SVGAnimatedAngle_animVal_Getter(this);

  @DomName('SVGAnimatedAngle.baseVal')
  @DocsEditable()
  Angle get baseVal => _blink.Native_SVGAnimatedAngle_baseVal_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAnimatedBoolean')
@Unstable()
class AnimatedBoolean extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory AnimatedBoolean._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAnimatedBoolean.animVal')
  @DocsEditable()
  bool get animVal => _blink.Native_SVGAnimatedBoolean_animVal_Getter(this);

  @DomName('SVGAnimatedBoolean.baseVal')
  @DocsEditable()
  bool get baseVal => _blink.Native_SVGAnimatedBoolean_baseVal_Getter(this);

  @DomName('SVGAnimatedBoolean.baseVal')
  @DocsEditable()
  void set baseVal(bool value) => _blink.Native_SVGAnimatedBoolean_baseVal_Setter(this, value);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAnimatedEnumeration')
@Unstable()
class AnimatedEnumeration extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory AnimatedEnumeration._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAnimatedEnumeration.animVal')
  @DocsEditable()
  int get animVal => _blink.Native_SVGAnimatedEnumeration_animVal_Getter(this);

  @DomName('SVGAnimatedEnumeration.baseVal')
  @DocsEditable()
  int get baseVal => _blink.Native_SVGAnimatedEnumeration_baseVal_Getter(this);

  @DomName('SVGAnimatedEnumeration.baseVal')
  @DocsEditable()
  void set baseVal(int value) => _blink.Native_SVGAnimatedEnumeration_baseVal_Setter(this, value);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAnimatedInteger')
@Unstable()
class AnimatedInteger extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory AnimatedInteger._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAnimatedInteger.animVal')
  @DocsEditable()
  int get animVal => _blink.Native_SVGAnimatedInteger_animVal_Getter(this);

  @DomName('SVGAnimatedInteger.baseVal')
  @DocsEditable()
  int get baseVal => _blink.Native_SVGAnimatedInteger_baseVal_Getter(this);

  @DomName('SVGAnimatedInteger.baseVal')
  @DocsEditable()
  void set baseVal(int value) => _blink.Native_SVGAnimatedInteger_baseVal_Setter(this, value);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAnimatedLength')
@Unstable()
class AnimatedLength extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory AnimatedLength._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAnimatedLength.animVal')
  @DocsEditable()
  Length get animVal => _blink.Native_SVGAnimatedLength_animVal_Getter(this);

  @DomName('SVGAnimatedLength.baseVal')
  @DocsEditable()
  Length get baseVal => _blink.Native_SVGAnimatedLength_baseVal_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAnimatedLengthList')
@Unstable()
class AnimatedLengthList extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory AnimatedLengthList._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAnimatedLengthList.animVal')
  @DocsEditable()
  LengthList get animVal => _blink.Native_SVGAnimatedLengthList_animVal_Getter(this);

  @DomName('SVGAnimatedLengthList.baseVal')
  @DocsEditable()
  LengthList get baseVal => _blink.Native_SVGAnimatedLengthList_baseVal_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAnimatedNumber')
@Unstable()
class AnimatedNumber extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory AnimatedNumber._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAnimatedNumber.animVal')
  @DocsEditable()
  double get animVal => _blink.Native_SVGAnimatedNumber_animVal_Getter(this);

  @DomName('SVGAnimatedNumber.baseVal')
  @DocsEditable()
  num get baseVal => _blink.Native_SVGAnimatedNumber_baseVal_Getter(this);

  @DomName('SVGAnimatedNumber.baseVal')
  @DocsEditable()
  void set baseVal(num value) => _blink.Native_SVGAnimatedNumber_baseVal_Setter(this, value);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAnimatedNumberList')
@Unstable()
class AnimatedNumberList extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory AnimatedNumberList._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAnimatedNumberList.animVal')
  @DocsEditable()
  NumberList get animVal => _blink.Native_SVGAnimatedNumberList_animVal_Getter(this);

  @DomName('SVGAnimatedNumberList.baseVal')
  @DocsEditable()
  NumberList get baseVal => _blink.Native_SVGAnimatedNumberList_baseVal_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAnimatedPreserveAspectRatio')
@Unstable()
class AnimatedPreserveAspectRatio extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory AnimatedPreserveAspectRatio._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAnimatedPreserveAspectRatio.animVal')
  @DocsEditable()
  PreserveAspectRatio get animVal => _blink.Native_SVGAnimatedPreserveAspectRatio_animVal_Getter(this);

  @DomName('SVGAnimatedPreserveAspectRatio.baseVal')
  @DocsEditable()
  PreserveAspectRatio get baseVal => _blink.Native_SVGAnimatedPreserveAspectRatio_baseVal_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAnimatedRect')
@Unstable()
class AnimatedRect extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory AnimatedRect._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAnimatedRect.animVal')
  @DocsEditable()
  Rect get animVal => _blink.Native_SVGAnimatedRect_animVal_Getter(this);

  @DomName('SVGAnimatedRect.baseVal')
  @DocsEditable()
  Rect get baseVal => _blink.Native_SVGAnimatedRect_baseVal_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAnimatedString')
@Unstable()
class AnimatedString extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory AnimatedString._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAnimatedString.animVal')
  @DocsEditable()
  String get animVal => _blink.Native_SVGAnimatedString_animVal_Getter(this);

  @DomName('SVGAnimatedString.baseVal')
  @DocsEditable()
  String get baseVal => _blink.Native_SVGAnimatedString_baseVal_Getter(this);

  @DomName('SVGAnimatedString.baseVal')
  @DocsEditable()
  void set baseVal(String value) => _blink.Native_SVGAnimatedString_baseVal_Setter(this, value);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAnimatedTransformList')
@Unstable()
class AnimatedTransformList extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory AnimatedTransformList._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAnimatedTransformList.animVal')
  @DocsEditable()
  TransformList get animVal => _blink.Native_SVGAnimatedTransformList_animVal_Getter(this);

  @DomName('SVGAnimatedTransformList.baseVal')
  @DocsEditable()
  TransformList get baseVal => _blink.Native_SVGAnimatedTransformList_baseVal_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAnimationElement')
@Unstable()
class AnimationElement extends SvgElement implements Tests {
  // To suppress missing implicit constructor warnings.
  factory AnimationElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAnimationElement.SVGAnimationElement')
  @DocsEditable()
  factory AnimationElement() => _SvgElementFactoryProvider.createSvgElement_tag("animation");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  AnimationElement.created() : super.created();

  @DomName('SVGAnimationElement.targetElement')
  @DocsEditable()
  SvgElement get targetElement => _blink.Native_SVGAnimationElement_targetElement_Getter(this);

  @DomName('SVGAnimationElement.beginElement')
  @DocsEditable()
  void beginElement() => _blink.Native_SVGAnimationElement_beginElement_Callback(this);

  @DomName('SVGAnimationElement.beginElementAt')
  @DocsEditable()
  void beginElementAt(num offset) => _blink.Native_SVGAnimationElement_beginElementAt_Callback(this, offset);

  @DomName('SVGAnimationElement.endElement')
  @DocsEditable()
  void endElement() => _blink.Native_SVGAnimationElement_endElement_Callback(this);

  @DomName('SVGAnimationElement.endElementAt')
  @DocsEditable()
  void endElementAt(num offset) => _blink.Native_SVGAnimationElement_endElementAt_Callback(this, offset);

  @DomName('SVGAnimationElement.getCurrentTime')
  @DocsEditable()
  double getCurrentTime() => _blink.Native_SVGAnimationElement_getCurrentTime_Callback(this);

  @DomName('SVGAnimationElement.getSimpleDuration')
  @DocsEditable()
  double getSimpleDuration() => _blink.Native_SVGAnimationElement_getSimpleDuration_Callback(this);

  @DomName('SVGAnimationElement.getStartTime')
  @DocsEditable()
  double getStartTime() => _blink.Native_SVGAnimationElement_getStartTime_Callback(this);

  @DomName('SVGAnimationElement.requiredExtensions')
  @DocsEditable()
  StringList get requiredExtensions => _blink.Native_SVGAnimationElement_requiredExtensions_Getter(this);

  @DomName('SVGAnimationElement.requiredFeatures')
  @DocsEditable()
  StringList get requiredFeatures => _blink.Native_SVGAnimationElement_requiredFeatures_Getter(this);

  @DomName('SVGAnimationElement.systemLanguage')
  @DocsEditable()
  StringList get systemLanguage => _blink.Native_SVGAnimationElement_systemLanguage_Getter(this);

  @DomName('SVGAnimationElement.hasExtension')
  @DocsEditable()
  bool hasExtension(String extension) => _blink.Native_SVGAnimationElement_hasExtension_Callback(this, extension);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGCircleElement')
@Unstable()
class CircleElement extends GeometryElement {
  // To suppress missing implicit constructor warnings.
  factory CircleElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGCircleElement.SVGCircleElement')
  @DocsEditable()
  factory CircleElement() => _SvgElementFactoryProvider.createSvgElement_tag("circle");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  CircleElement.created() : super.created();

  @DomName('SVGCircleElement.cx')
  @DocsEditable()
  AnimatedLength get cx => _blink.Native_SVGCircleElement_cx_Getter(this);

  @DomName('SVGCircleElement.cy')
  @DocsEditable()
  AnimatedLength get cy => _blink.Native_SVGCircleElement_cy_Getter(this);

  @DomName('SVGCircleElement.r')
  @DocsEditable()
  AnimatedLength get r => _blink.Native_SVGCircleElement_r_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGClipPathElement')
@Unstable()
class ClipPathElement extends GraphicsElement {
  // To suppress missing implicit constructor warnings.
  factory ClipPathElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGClipPathElement.SVGClipPathElement')
  @DocsEditable()
  factory ClipPathElement() => _SvgElementFactoryProvider.createSvgElement_tag("clipPath");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  ClipPathElement.created() : super.created();

  @DomName('SVGClipPathElement.clipPathUnits')
  @DocsEditable()
  AnimatedEnumeration get clipPathUnits => _blink.Native_SVGClipPathElement_clipPathUnits_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGDefsElement')
@Unstable()
class DefsElement extends GraphicsElement {
  // To suppress missing implicit constructor warnings.
  factory DefsElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGDefsElement.SVGDefsElement')
  @DocsEditable()
  factory DefsElement() => _SvgElementFactoryProvider.createSvgElement_tag("defs");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  DefsElement.created() : super.created();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGDescElement')
@Unstable()
class DescElement extends SvgElement {
  // To suppress missing implicit constructor warnings.
  factory DescElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGDescElement.SVGDescElement')
  @DocsEditable()
  factory DescElement() => _SvgElementFactoryProvider.createSvgElement_tag("desc");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  DescElement.created() : super.created();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGDiscardElement')
@Experimental() // untriaged
class DiscardElement extends SvgElement {
  // To suppress missing implicit constructor warnings.
  factory DiscardElement._() { throw new UnsupportedError("Not supported"); }
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  DiscardElement.created() : super.created();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGElementInstance')
@Unstable()
class ElementInstance extends EventTarget {
  // To suppress missing implicit constructor warnings.
  factory ElementInstance._() { throw new UnsupportedError("Not supported"); }

  /**
   * Static factory designed to expose `abort` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.abortEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> abortEvent = const EventStreamProvider<Event>('abort');

  /**
   * Static factory designed to expose `beforecopy` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.beforecopyEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> beforeCopyEvent = const EventStreamProvider<Event>('beforecopy');

  /**
   * Static factory designed to expose `beforecut` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.beforecutEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> beforeCutEvent = const EventStreamProvider<Event>('beforecut');

  /**
   * Static factory designed to expose `beforepaste` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.beforepasteEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> beforePasteEvent = const EventStreamProvider<Event>('beforepaste');

  /**
   * Static factory designed to expose `blur` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.blurEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> blurEvent = const EventStreamProvider<Event>('blur');

  /**
   * Static factory designed to expose `change` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.changeEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> changeEvent = const EventStreamProvider<Event>('change');

  /**
   * Static factory designed to expose `click` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.clickEvent')
  @DocsEditable()
  static const EventStreamProvider<MouseEvent> clickEvent = const EventStreamProvider<MouseEvent>('click');

  /**
   * Static factory designed to expose `contextmenu` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.contextmenuEvent')
  @DocsEditable()
  static const EventStreamProvider<MouseEvent> contextMenuEvent = const EventStreamProvider<MouseEvent>('contextmenu');

  /**
   * Static factory designed to expose `copy` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.copyEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> copyEvent = const EventStreamProvider<Event>('copy');

  /**
   * Static factory designed to expose `cut` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.cutEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> cutEvent = const EventStreamProvider<Event>('cut');

  /**
   * Static factory designed to expose `doubleclick` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.dblclickEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> doubleClickEvent = const EventStreamProvider<Event>('dblclick');

  /**
   * Static factory designed to expose `drag` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.dragEvent')
  @DocsEditable()
  static const EventStreamProvider<MouseEvent> dragEvent = const EventStreamProvider<MouseEvent>('drag');

  /**
   * Static factory designed to expose `dragend` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.dragendEvent')
  @DocsEditable()
  static const EventStreamProvider<MouseEvent> dragEndEvent = const EventStreamProvider<MouseEvent>('dragend');

  /**
   * Static factory designed to expose `dragenter` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.dragenterEvent')
  @DocsEditable()
  static const EventStreamProvider<MouseEvent> dragEnterEvent = const EventStreamProvider<MouseEvent>('dragenter');

  /**
   * Static factory designed to expose `dragleave` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.dragleaveEvent')
  @DocsEditable()
  static const EventStreamProvider<MouseEvent> dragLeaveEvent = const EventStreamProvider<MouseEvent>('dragleave');

  /**
   * Static factory designed to expose `dragover` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.dragoverEvent')
  @DocsEditable()
  static const EventStreamProvider<MouseEvent> dragOverEvent = const EventStreamProvider<MouseEvent>('dragover');

  /**
   * Static factory designed to expose `dragstart` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.dragstartEvent')
  @DocsEditable()
  static const EventStreamProvider<MouseEvent> dragStartEvent = const EventStreamProvider<MouseEvent>('dragstart');

  /**
   * Static factory designed to expose `drop` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.dropEvent')
  @DocsEditable()
  static const EventStreamProvider<MouseEvent> dropEvent = const EventStreamProvider<MouseEvent>('drop');

  /**
   * Static factory designed to expose `error` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.errorEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> errorEvent = const EventStreamProvider<Event>('error');

  /**
   * Static factory designed to expose `focus` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.focusEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> focusEvent = const EventStreamProvider<Event>('focus');

  /**
   * Static factory designed to expose `input` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.inputEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> inputEvent = const EventStreamProvider<Event>('input');

  /**
   * Static factory designed to expose `keydown` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.keydownEvent')
  @DocsEditable()
  static const EventStreamProvider<KeyboardEvent> keyDownEvent = const EventStreamProvider<KeyboardEvent>('keydown');

  /**
   * Static factory designed to expose `keypress` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.keypressEvent')
  @DocsEditable()
  static const EventStreamProvider<KeyboardEvent> keyPressEvent = const EventStreamProvider<KeyboardEvent>('keypress');

  /**
   * Static factory designed to expose `keyup` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.keyupEvent')
  @DocsEditable()
  static const EventStreamProvider<KeyboardEvent> keyUpEvent = const EventStreamProvider<KeyboardEvent>('keyup');

  /**
   * Static factory designed to expose `load` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.loadEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> loadEvent = const EventStreamProvider<Event>('load');

  /**
   * Static factory designed to expose `mousedown` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.mousedownEvent')
  @DocsEditable()
  static const EventStreamProvider<MouseEvent> mouseDownEvent = const EventStreamProvider<MouseEvent>('mousedown');

  /**
   * Static factory designed to expose `mouseenter` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.mouseenterEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<MouseEvent> mouseEnterEvent = const EventStreamProvider<MouseEvent>('mouseenter');

  /**
   * Static factory designed to expose `mouseleave` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.mouseleaveEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<MouseEvent> mouseLeaveEvent = const EventStreamProvider<MouseEvent>('mouseleave');

  /**
   * Static factory designed to expose `mousemove` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.mousemoveEvent')
  @DocsEditable()
  static const EventStreamProvider<MouseEvent> mouseMoveEvent = const EventStreamProvider<MouseEvent>('mousemove');

  /**
   * Static factory designed to expose `mouseout` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.mouseoutEvent')
  @DocsEditable()
  static const EventStreamProvider<MouseEvent> mouseOutEvent = const EventStreamProvider<MouseEvent>('mouseout');

  /**
   * Static factory designed to expose `mouseover` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.mouseoverEvent')
  @DocsEditable()
  static const EventStreamProvider<MouseEvent> mouseOverEvent = const EventStreamProvider<MouseEvent>('mouseover');

  /**
   * Static factory designed to expose `mouseup` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.mouseupEvent')
  @DocsEditable()
  static const EventStreamProvider<MouseEvent> mouseUpEvent = const EventStreamProvider<MouseEvent>('mouseup');

  /**
   * Static factory designed to expose `mousewheel` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.mousewheelEvent')
  @DocsEditable()
  static const EventStreamProvider<WheelEvent> mouseWheelEvent = const EventStreamProvider<WheelEvent>('mousewheel');

  /**
   * Static factory designed to expose `paste` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.pasteEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> pasteEvent = const EventStreamProvider<Event>('paste');

  /**
   * Static factory designed to expose `reset` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.resetEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> resetEvent = const EventStreamProvider<Event>('reset');

  /**
   * Static factory designed to expose `resize` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.resizeEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> resizeEvent = const EventStreamProvider<Event>('resize');

  /**
   * Static factory designed to expose `scroll` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.scrollEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> scrollEvent = const EventStreamProvider<Event>('scroll');

  /**
   * Static factory designed to expose `search` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.searchEvent')
  @DocsEditable()
  // http://www.w3.org/TR/html-markup/input.search.html
  @Experimental()
  static const EventStreamProvider<Event> searchEvent = const EventStreamProvider<Event>('search');

  /**
   * Static factory designed to expose `select` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.selectEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> selectEvent = const EventStreamProvider<Event>('select');

  /**
   * Static factory designed to expose `selectstart` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.selectstartEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> selectStartEvent = const EventStreamProvider<Event>('selectstart');

  /**
   * Static factory designed to expose `submit` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.submitEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> submitEvent = const EventStreamProvider<Event>('submit');

  /**
   * Static factory designed to expose `unload` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.unloadEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> unloadEvent = const EventStreamProvider<Event>('unload');

  @DomName('SVGElementInstance.correspondingElement')
  @DocsEditable()
  SvgElement get correspondingElement => _blink.Native_SVGElementInstance_correspondingElement_Getter(this);

  @DomName('SVGElementInstance.correspondingUseElement')
  @DocsEditable()
  UseElement get correspondingUseElement => _blink.Native_SVGElementInstance_correspondingUseElement_Getter(this);

  @DomName('SVGElementInstance.firstChild')
  @DocsEditable()
  ElementInstance get firstChild => _blink.Native_SVGElementInstance_firstChild_Getter(this);

  @DomName('SVGElementInstance.lastChild')
  @DocsEditable()
  ElementInstance get lastChild => _blink.Native_SVGElementInstance_lastChild_Getter(this);

  @DomName('SVGElementInstance.nextSibling')
  @DocsEditable()
  ElementInstance get nextSibling => _blink.Native_SVGElementInstance_nextSibling_Getter(this);

  @DomName('SVGElementInstance.parentNode')
  @DocsEditable()
  ElementInstance get parentNode => _blink.Native_SVGElementInstance_parentNode_Getter(this);

  @DomName('SVGElementInstance.previousSibling')
  @DocsEditable()
  ElementInstance get previousSibling => _blink.Native_SVGElementInstance_previousSibling_Getter(this);

  /// Stream of `abort` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onabort')
  @DocsEditable()
  Stream<Event> get onAbort => abortEvent.forTarget(this);

  /// Stream of `beforecopy` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onbeforecopy')
  @DocsEditable()
  Stream<Event> get onBeforeCopy => beforeCopyEvent.forTarget(this);

  /// Stream of `beforecut` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onbeforecut')
  @DocsEditable()
  Stream<Event> get onBeforeCut => beforeCutEvent.forTarget(this);

  /// Stream of `beforepaste` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onbeforepaste')
  @DocsEditable()
  Stream<Event> get onBeforePaste => beforePasteEvent.forTarget(this);

  /// Stream of `blur` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onblur')
  @DocsEditable()
  Stream<Event> get onBlur => blurEvent.forTarget(this);

  /// Stream of `change` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onchange')
  @DocsEditable()
  Stream<Event> get onChange => changeEvent.forTarget(this);

  /// Stream of `click` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onclick')
  @DocsEditable()
  Stream<MouseEvent> get onClick => clickEvent.forTarget(this);

  /// Stream of `contextmenu` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.oncontextmenu')
  @DocsEditable()
  Stream<MouseEvent> get onContextMenu => contextMenuEvent.forTarget(this);

  /// Stream of `copy` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.oncopy')
  @DocsEditable()
  Stream<Event> get onCopy => copyEvent.forTarget(this);

  /// Stream of `cut` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.oncut')
  @DocsEditable()
  Stream<Event> get onCut => cutEvent.forTarget(this);

  /// Stream of `doubleclick` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.ondblclick')
  @DocsEditable()
  Stream<Event> get onDoubleClick => doubleClickEvent.forTarget(this);

  /// Stream of `drag` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.ondrag')
  @DocsEditable()
  Stream<MouseEvent> get onDrag => dragEvent.forTarget(this);

  /// Stream of `dragend` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.ondragend')
  @DocsEditable()
  Stream<MouseEvent> get onDragEnd => dragEndEvent.forTarget(this);

  /// Stream of `dragenter` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.ondragenter')
  @DocsEditable()
  Stream<MouseEvent> get onDragEnter => dragEnterEvent.forTarget(this);

  /// Stream of `dragleave` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.ondragleave')
  @DocsEditable()
  Stream<MouseEvent> get onDragLeave => dragLeaveEvent.forTarget(this);

  /// Stream of `dragover` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.ondragover')
  @DocsEditable()
  Stream<MouseEvent> get onDragOver => dragOverEvent.forTarget(this);

  /// Stream of `dragstart` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.ondragstart')
  @DocsEditable()
  Stream<MouseEvent> get onDragStart => dragStartEvent.forTarget(this);

  /// Stream of `drop` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.ondrop')
  @DocsEditable()
  Stream<MouseEvent> get onDrop => dropEvent.forTarget(this);

  /// Stream of `error` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onerror')
  @DocsEditable()
  Stream<Event> get onError => errorEvent.forTarget(this);

  /// Stream of `focus` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onfocus')
  @DocsEditable()
  Stream<Event> get onFocus => focusEvent.forTarget(this);

  /// Stream of `input` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.oninput')
  @DocsEditable()
  Stream<Event> get onInput => inputEvent.forTarget(this);

  /// Stream of `keydown` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onkeydown')
  @DocsEditable()
  Stream<KeyboardEvent> get onKeyDown => keyDownEvent.forTarget(this);

  /// Stream of `keypress` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onkeypress')
  @DocsEditable()
  Stream<KeyboardEvent> get onKeyPress => keyPressEvent.forTarget(this);

  /// Stream of `keyup` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onkeyup')
  @DocsEditable()
  Stream<KeyboardEvent> get onKeyUp => keyUpEvent.forTarget(this);

  /// Stream of `load` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onload')
  @DocsEditable()
  Stream<Event> get onLoad => loadEvent.forTarget(this);

  /// Stream of `mousedown` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onmousedown')
  @DocsEditable()
  Stream<MouseEvent> get onMouseDown => mouseDownEvent.forTarget(this);

  /// Stream of `mouseenter` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onmouseenter')
  @DocsEditable()
  @Experimental() // untriaged
  Stream<MouseEvent> get onMouseEnter => mouseEnterEvent.forTarget(this);

  /// Stream of `mouseleave` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onmouseleave')
  @DocsEditable()
  @Experimental() // untriaged
  Stream<MouseEvent> get onMouseLeave => mouseLeaveEvent.forTarget(this);

  /// Stream of `mousemove` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onmousemove')
  @DocsEditable()
  Stream<MouseEvent> get onMouseMove => mouseMoveEvent.forTarget(this);

  /// Stream of `mouseout` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onmouseout')
  @DocsEditable()
  Stream<MouseEvent> get onMouseOut => mouseOutEvent.forTarget(this);

  /// Stream of `mouseover` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onmouseover')
  @DocsEditable()
  Stream<MouseEvent> get onMouseOver => mouseOverEvent.forTarget(this);

  /// Stream of `mouseup` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onmouseup')
  @DocsEditable()
  Stream<MouseEvent> get onMouseUp => mouseUpEvent.forTarget(this);

  /// Stream of `mousewheel` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onmousewheel')
  @DocsEditable()
  Stream<WheelEvent> get onMouseWheel => mouseWheelEvent.forTarget(this);

  /// Stream of `paste` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onpaste')
  @DocsEditable()
  Stream<Event> get onPaste => pasteEvent.forTarget(this);

  /// Stream of `reset` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onreset')
  @DocsEditable()
  Stream<Event> get onReset => resetEvent.forTarget(this);

  /// Stream of `resize` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onresize')
  @DocsEditable()
  Stream<Event> get onResize => resizeEvent.forTarget(this);

  /// Stream of `scroll` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onscroll')
  @DocsEditable()
  Stream<Event> get onScroll => scrollEvent.forTarget(this);

  /// Stream of `search` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onsearch')
  @DocsEditable()
  // http://www.w3.org/TR/html-markup/input.search.html
  @Experimental()
  Stream<Event> get onSearch => searchEvent.forTarget(this);

  /// Stream of `select` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onselect')
  @DocsEditable()
  Stream<Event> get onSelect => selectEvent.forTarget(this);

  /// Stream of `selectstart` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onselectstart')
  @DocsEditable()
  Stream<Event> get onSelectStart => selectStartEvent.forTarget(this);

  /// Stream of `submit` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onsubmit')
  @DocsEditable()
  Stream<Event> get onSubmit => submitEvent.forTarget(this);

  /// Stream of `unload` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onunload')
  @DocsEditable()
  Stream<Event> get onUnload => unloadEvent.forTarget(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGEllipseElement')
@Unstable()
class EllipseElement extends GeometryElement {
  // To suppress missing implicit constructor warnings.
  factory EllipseElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGEllipseElement.SVGEllipseElement')
  @DocsEditable()
  factory EllipseElement() => _SvgElementFactoryProvider.createSvgElement_tag("ellipse");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  EllipseElement.created() : super.created();

  @DomName('SVGEllipseElement.cx')
  @DocsEditable()
  AnimatedLength get cx => _blink.Native_SVGEllipseElement_cx_Getter(this);

  @DomName('SVGEllipseElement.cy')
  @DocsEditable()
  AnimatedLength get cy => _blink.Native_SVGEllipseElement_cy_Getter(this);

  @DomName('SVGEllipseElement.rx')
  @DocsEditable()
  AnimatedLength get rx => _blink.Native_SVGEllipseElement_rx_Getter(this);

  @DomName('SVGEllipseElement.ry')
  @DocsEditable()
  AnimatedLength get ry => _blink.Native_SVGEllipseElement_ry_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGFEBlendElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class FEBlendElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory FEBlendElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEBlendElement.SVGFEBlendElement')
  @DocsEditable()
  factory FEBlendElement() => _SvgElementFactoryProvider.createSvgElement_tag("feBlend");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FEBlendElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFEBlendElement.SVG_FEBLEND_MODE_DARKEN')
  @DocsEditable()
  static const int SVG_FEBLEND_MODE_DARKEN = 4;

  @DomName('SVGFEBlendElement.SVG_FEBLEND_MODE_LIGHTEN')
  @DocsEditable()
  static const int SVG_FEBLEND_MODE_LIGHTEN = 5;

  @DomName('SVGFEBlendElement.SVG_FEBLEND_MODE_MULTIPLY')
  @DocsEditable()
  static const int SVG_FEBLEND_MODE_MULTIPLY = 2;

  @DomName('SVGFEBlendElement.SVG_FEBLEND_MODE_NORMAL')
  @DocsEditable()
  static const int SVG_FEBLEND_MODE_NORMAL = 1;

  @DomName('SVGFEBlendElement.SVG_FEBLEND_MODE_SCREEN')
  @DocsEditable()
  static const int SVG_FEBLEND_MODE_SCREEN = 3;

  @DomName('SVGFEBlendElement.SVG_FEBLEND_MODE_UNKNOWN')
  @DocsEditable()
  static const int SVG_FEBLEND_MODE_UNKNOWN = 0;

  @DomName('SVGFEBlendElement.in1')
  @DocsEditable()
  AnimatedString get in1 => _blink.Native_SVGFEBlendElement_in1_Getter(this);

  @DomName('SVGFEBlendElement.in2')
  @DocsEditable()
  AnimatedString get in2 => _blink.Native_SVGFEBlendElement_in2_Getter(this);

  @DomName('SVGFEBlendElement.mode')
  @DocsEditable()
  AnimatedEnumeration get mode => _blink.Native_SVGFEBlendElement_mode_Getter(this);

  @DomName('SVGFEBlendElement.height')
  @DocsEditable()
  AnimatedLength get height => _blink.Native_SVGFEBlendElement_height_Getter(this);

  @DomName('SVGFEBlendElement.result')
  @DocsEditable()
  AnimatedString get result => _blink.Native_SVGFEBlendElement_result_Getter(this);

  @DomName('SVGFEBlendElement.width')
  @DocsEditable()
  AnimatedLength get width => _blink.Native_SVGFEBlendElement_width_Getter(this);

  @DomName('SVGFEBlendElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.Native_SVGFEBlendElement_x_Getter(this);

  @DomName('SVGFEBlendElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.Native_SVGFEBlendElement_y_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGFEColorMatrixElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class FEColorMatrixElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory FEColorMatrixElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEColorMatrixElement.SVGFEColorMatrixElement')
  @DocsEditable()
  factory FEColorMatrixElement() => _SvgElementFactoryProvider.createSvgElement_tag("feColorMatrix");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FEColorMatrixElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFEColorMatrixElement.SVG_FECOLORMATRIX_TYPE_HUEROTATE')
  @DocsEditable()
  static const int SVG_FECOLORMATRIX_TYPE_HUEROTATE = 3;

  @DomName('SVGFEColorMatrixElement.SVG_FECOLORMATRIX_TYPE_LUMINANCETOALPHA')
  @DocsEditable()
  static const int SVG_FECOLORMATRIX_TYPE_LUMINANCETOALPHA = 4;

  @DomName('SVGFEColorMatrixElement.SVG_FECOLORMATRIX_TYPE_MATRIX')
  @DocsEditable()
  static const int SVG_FECOLORMATRIX_TYPE_MATRIX = 1;

  @DomName('SVGFEColorMatrixElement.SVG_FECOLORMATRIX_TYPE_SATURATE')
  @DocsEditable()
  static const int SVG_FECOLORMATRIX_TYPE_SATURATE = 2;

  @DomName('SVGFEColorMatrixElement.SVG_FECOLORMATRIX_TYPE_UNKNOWN')
  @DocsEditable()
  static const int SVG_FECOLORMATRIX_TYPE_UNKNOWN = 0;

  @DomName('SVGFEColorMatrixElement.in1')
  @DocsEditable()
  AnimatedString get in1 => _blink.Native_SVGFEColorMatrixElement_in1_Getter(this);

  @DomName('SVGFEColorMatrixElement.type')
  @DocsEditable()
  AnimatedEnumeration get type => _blink.Native_SVGFEColorMatrixElement_type_Getter(this);

  @DomName('SVGFEColorMatrixElement.values')
  @DocsEditable()
  AnimatedNumberList get values => _blink.Native_SVGFEColorMatrixElement_values_Getter(this);

  @DomName('SVGFEColorMatrixElement.height')
  @DocsEditable()
  AnimatedLength get height => _blink.Native_SVGFEColorMatrixElement_height_Getter(this);

  @DomName('SVGFEColorMatrixElement.result')
  @DocsEditable()
  AnimatedString get result => _blink.Native_SVGFEColorMatrixElement_result_Getter(this);

  @DomName('SVGFEColorMatrixElement.width')
  @DocsEditable()
  AnimatedLength get width => _blink.Native_SVGFEColorMatrixElement_width_Getter(this);

  @DomName('SVGFEColorMatrixElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.Native_SVGFEColorMatrixElement_x_Getter(this);

  @DomName('SVGFEColorMatrixElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.Native_SVGFEColorMatrixElement_y_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGFEComponentTransferElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class FEComponentTransferElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory FEComponentTransferElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEComponentTransferElement.SVGFEComponentTransferElement')
  @DocsEditable()
  factory FEComponentTransferElement() => _SvgElementFactoryProvider.createSvgElement_tag("feComponentTransfer");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FEComponentTransferElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFEComponentTransferElement.in1')
  @DocsEditable()
  AnimatedString get in1 => _blink.Native_SVGFEComponentTransferElement_in1_Getter(this);

  @DomName('SVGFEComponentTransferElement.height')
  @DocsEditable()
  AnimatedLength get height => _blink.Native_SVGFEComponentTransferElement_height_Getter(this);

  @DomName('SVGFEComponentTransferElement.result')
  @DocsEditable()
  AnimatedString get result => _blink.Native_SVGFEComponentTransferElement_result_Getter(this);

  @DomName('SVGFEComponentTransferElement.width')
  @DocsEditable()
  AnimatedLength get width => _blink.Native_SVGFEComponentTransferElement_width_Getter(this);

  @DomName('SVGFEComponentTransferElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.Native_SVGFEComponentTransferElement_x_Getter(this);

  @DomName('SVGFEComponentTransferElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.Native_SVGFEComponentTransferElement_y_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGFECompositeElement')
@Unstable()
class FECompositeElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory FECompositeElement._() { throw new UnsupportedError("Not supported"); }
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FECompositeElement.created() : super.created();

  @DomName('SVGFECompositeElement.SVG_FECOMPOSITE_OPERATOR_ARITHMETIC')
  @DocsEditable()
  static const int SVG_FECOMPOSITE_OPERATOR_ARITHMETIC = 6;

  @DomName('SVGFECompositeElement.SVG_FECOMPOSITE_OPERATOR_ATOP')
  @DocsEditable()
  static const int SVG_FECOMPOSITE_OPERATOR_ATOP = 4;

  @DomName('SVGFECompositeElement.SVG_FECOMPOSITE_OPERATOR_IN')
  @DocsEditable()
  static const int SVG_FECOMPOSITE_OPERATOR_IN = 2;

  @DomName('SVGFECompositeElement.SVG_FECOMPOSITE_OPERATOR_OUT')
  @DocsEditable()
  static const int SVG_FECOMPOSITE_OPERATOR_OUT = 3;

  @DomName('SVGFECompositeElement.SVG_FECOMPOSITE_OPERATOR_OVER')
  @DocsEditable()
  static const int SVG_FECOMPOSITE_OPERATOR_OVER = 1;

  @DomName('SVGFECompositeElement.SVG_FECOMPOSITE_OPERATOR_UNKNOWN')
  @DocsEditable()
  static const int SVG_FECOMPOSITE_OPERATOR_UNKNOWN = 0;

  @DomName('SVGFECompositeElement.SVG_FECOMPOSITE_OPERATOR_XOR')
  @DocsEditable()
  static const int SVG_FECOMPOSITE_OPERATOR_XOR = 5;

  @DomName('SVGFECompositeElement.in1')
  @DocsEditable()
  AnimatedString get in1 => _blink.Native_SVGFECompositeElement_in1_Getter(this);

  @DomName('SVGFECompositeElement.in2')
  @DocsEditable()
  AnimatedString get in2 => _blink.Native_SVGFECompositeElement_in2_Getter(this);

  @DomName('SVGFECompositeElement.k1')
  @DocsEditable()
  AnimatedNumber get k1 => _blink.Native_SVGFECompositeElement_k1_Getter(this);

  @DomName('SVGFECompositeElement.k2')
  @DocsEditable()
  AnimatedNumber get k2 => _blink.Native_SVGFECompositeElement_k2_Getter(this);

  @DomName('SVGFECompositeElement.k3')
  @DocsEditable()
  AnimatedNumber get k3 => _blink.Native_SVGFECompositeElement_k3_Getter(this);

  @DomName('SVGFECompositeElement.k4')
  @DocsEditable()
  AnimatedNumber get k4 => _blink.Native_SVGFECompositeElement_k4_Getter(this);

  @DomName('SVGFECompositeElement.operator')
  @DocsEditable()
  AnimatedEnumeration get operator => _blink.Native_SVGFECompositeElement_operator_Getter(this);

  @DomName('SVGFECompositeElement.height')
  @DocsEditable()
  AnimatedLength get height => _blink.Native_SVGFECompositeElement_height_Getter(this);

  @DomName('SVGFECompositeElement.result')
  @DocsEditable()
  AnimatedString get result => _blink.Native_SVGFECompositeElement_result_Getter(this);

  @DomName('SVGFECompositeElement.width')
  @DocsEditable()
  AnimatedLength get width => _blink.Native_SVGFECompositeElement_width_Getter(this);

  @DomName('SVGFECompositeElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.Native_SVGFECompositeElement_x_Getter(this);

  @DomName('SVGFECompositeElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.Native_SVGFECompositeElement_y_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGFEConvolveMatrixElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class FEConvolveMatrixElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory FEConvolveMatrixElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEConvolveMatrixElement.SVGFEConvolveMatrixElement')
  @DocsEditable()
  factory FEConvolveMatrixElement() => _SvgElementFactoryProvider.createSvgElement_tag("feConvolveMatrix");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FEConvolveMatrixElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFEConvolveMatrixElement.SVG_EDGEMODE_DUPLICATE')
  @DocsEditable()
  static const int SVG_EDGEMODE_DUPLICATE = 1;

  @DomName('SVGFEConvolveMatrixElement.SVG_EDGEMODE_NONE')
  @DocsEditable()
  static const int SVG_EDGEMODE_NONE = 3;

  @DomName('SVGFEConvolveMatrixElement.SVG_EDGEMODE_UNKNOWN')
  @DocsEditable()
  static const int SVG_EDGEMODE_UNKNOWN = 0;

  @DomName('SVGFEConvolveMatrixElement.SVG_EDGEMODE_WRAP')
  @DocsEditable()
  static const int SVG_EDGEMODE_WRAP = 2;

  @DomName('SVGFEConvolveMatrixElement.bias')
  @DocsEditable()
  AnimatedNumber get bias => _blink.Native_SVGFEConvolveMatrixElement_bias_Getter(this);

  @DomName('SVGFEConvolveMatrixElement.divisor')
  @DocsEditable()
  AnimatedNumber get divisor => _blink.Native_SVGFEConvolveMatrixElement_divisor_Getter(this);

  @DomName('SVGFEConvolveMatrixElement.edgeMode')
  @DocsEditable()
  AnimatedEnumeration get edgeMode => _blink.Native_SVGFEConvolveMatrixElement_edgeMode_Getter(this);

  @DomName('SVGFEConvolveMatrixElement.in1')
  @DocsEditable()
  AnimatedString get in1 => _blink.Native_SVGFEConvolveMatrixElement_in1_Getter(this);

  @DomName('SVGFEConvolveMatrixElement.kernelMatrix')
  @DocsEditable()
  AnimatedNumberList get kernelMatrix => _blink.Native_SVGFEConvolveMatrixElement_kernelMatrix_Getter(this);

  @DomName('SVGFEConvolveMatrixElement.kernelUnitLengthX')
  @DocsEditable()
  AnimatedNumber get kernelUnitLengthX => _blink.Native_SVGFEConvolveMatrixElement_kernelUnitLengthX_Getter(this);

  @DomName('SVGFEConvolveMatrixElement.kernelUnitLengthY')
  @DocsEditable()
  AnimatedNumber get kernelUnitLengthY => _blink.Native_SVGFEConvolveMatrixElement_kernelUnitLengthY_Getter(this);

  @DomName('SVGFEConvolveMatrixElement.orderX')
  @DocsEditable()
  AnimatedInteger get orderX => _blink.Native_SVGFEConvolveMatrixElement_orderX_Getter(this);

  @DomName('SVGFEConvolveMatrixElement.orderY')
  @DocsEditable()
  AnimatedInteger get orderY => _blink.Native_SVGFEConvolveMatrixElement_orderY_Getter(this);

  @DomName('SVGFEConvolveMatrixElement.preserveAlpha')
  @DocsEditable()
  AnimatedBoolean get preserveAlpha => _blink.Native_SVGFEConvolveMatrixElement_preserveAlpha_Getter(this);

  @DomName('SVGFEConvolveMatrixElement.targetX')
  @DocsEditable()
  AnimatedInteger get targetX => _blink.Native_SVGFEConvolveMatrixElement_targetX_Getter(this);

  @DomName('SVGFEConvolveMatrixElement.targetY')
  @DocsEditable()
  AnimatedInteger get targetY => _blink.Native_SVGFEConvolveMatrixElement_targetY_Getter(this);

  @DomName('SVGFEConvolveMatrixElement.height')
  @DocsEditable()
  AnimatedLength get height => _blink.Native_SVGFEConvolveMatrixElement_height_Getter(this);

  @DomName('SVGFEConvolveMatrixElement.result')
  @DocsEditable()
  AnimatedString get result => _blink.Native_SVGFEConvolveMatrixElement_result_Getter(this);

  @DomName('SVGFEConvolveMatrixElement.width')
  @DocsEditable()
  AnimatedLength get width => _blink.Native_SVGFEConvolveMatrixElement_width_Getter(this);

  @DomName('SVGFEConvolveMatrixElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.Native_SVGFEConvolveMatrixElement_x_Getter(this);

  @DomName('SVGFEConvolveMatrixElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.Native_SVGFEConvolveMatrixElement_y_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGFEDiffuseLightingElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class FEDiffuseLightingElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory FEDiffuseLightingElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEDiffuseLightingElement.SVGFEDiffuseLightingElement')
  @DocsEditable()
  factory FEDiffuseLightingElement() => _SvgElementFactoryProvider.createSvgElement_tag("feDiffuseLighting");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FEDiffuseLightingElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFEDiffuseLightingElement.diffuseConstant')
  @DocsEditable()
  AnimatedNumber get diffuseConstant => _blink.Native_SVGFEDiffuseLightingElement_diffuseConstant_Getter(this);

  @DomName('SVGFEDiffuseLightingElement.in1')
  @DocsEditable()
  AnimatedString get in1 => _blink.Native_SVGFEDiffuseLightingElement_in1_Getter(this);

  @DomName('SVGFEDiffuseLightingElement.kernelUnitLengthX')
  @DocsEditable()
  AnimatedNumber get kernelUnitLengthX => _blink.Native_SVGFEDiffuseLightingElement_kernelUnitLengthX_Getter(this);

  @DomName('SVGFEDiffuseLightingElement.kernelUnitLengthY')
  @DocsEditable()
  AnimatedNumber get kernelUnitLengthY => _blink.Native_SVGFEDiffuseLightingElement_kernelUnitLengthY_Getter(this);

  @DomName('SVGFEDiffuseLightingElement.surfaceScale')
  @DocsEditable()
  AnimatedNumber get surfaceScale => _blink.Native_SVGFEDiffuseLightingElement_surfaceScale_Getter(this);

  @DomName('SVGFEDiffuseLightingElement.height')
  @DocsEditable()
  AnimatedLength get height => _blink.Native_SVGFEDiffuseLightingElement_height_Getter(this);

  @DomName('SVGFEDiffuseLightingElement.result')
  @DocsEditable()
  AnimatedString get result => _blink.Native_SVGFEDiffuseLightingElement_result_Getter(this);

  @DomName('SVGFEDiffuseLightingElement.width')
  @DocsEditable()
  AnimatedLength get width => _blink.Native_SVGFEDiffuseLightingElement_width_Getter(this);

  @DomName('SVGFEDiffuseLightingElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.Native_SVGFEDiffuseLightingElement_x_Getter(this);

  @DomName('SVGFEDiffuseLightingElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.Native_SVGFEDiffuseLightingElement_y_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGFEDisplacementMapElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class FEDisplacementMapElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory FEDisplacementMapElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEDisplacementMapElement.SVGFEDisplacementMapElement')
  @DocsEditable()
  factory FEDisplacementMapElement() => _SvgElementFactoryProvider.createSvgElement_tag("feDisplacementMap");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FEDisplacementMapElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFEDisplacementMapElement.SVG_CHANNEL_A')
  @DocsEditable()
  static const int SVG_CHANNEL_A = 4;

  @DomName('SVGFEDisplacementMapElement.SVG_CHANNEL_B')
  @DocsEditable()
  static const int SVG_CHANNEL_B = 3;

  @DomName('SVGFEDisplacementMapElement.SVG_CHANNEL_G')
  @DocsEditable()
  static const int SVG_CHANNEL_G = 2;

  @DomName('SVGFEDisplacementMapElement.SVG_CHANNEL_R')
  @DocsEditable()
  static const int SVG_CHANNEL_R = 1;

  @DomName('SVGFEDisplacementMapElement.SVG_CHANNEL_UNKNOWN')
  @DocsEditable()
  static const int SVG_CHANNEL_UNKNOWN = 0;

  @DomName('SVGFEDisplacementMapElement.in1')
  @DocsEditable()
  AnimatedString get in1 => _blink.Native_SVGFEDisplacementMapElement_in1_Getter(this);

  @DomName('SVGFEDisplacementMapElement.in2')
  @DocsEditable()
  AnimatedString get in2 => _blink.Native_SVGFEDisplacementMapElement_in2_Getter(this);

  @DomName('SVGFEDisplacementMapElement.scale')
  @DocsEditable()
  AnimatedNumber get scale => _blink.Native_SVGFEDisplacementMapElement_scale_Getter(this);

  @DomName('SVGFEDisplacementMapElement.xChannelSelector')
  @DocsEditable()
  AnimatedEnumeration get xChannelSelector => _blink.Native_SVGFEDisplacementMapElement_xChannelSelector_Getter(this);

  @DomName('SVGFEDisplacementMapElement.yChannelSelector')
  @DocsEditable()
  AnimatedEnumeration get yChannelSelector => _blink.Native_SVGFEDisplacementMapElement_yChannelSelector_Getter(this);

  @DomName('SVGFEDisplacementMapElement.height')
  @DocsEditable()
  AnimatedLength get height => _blink.Native_SVGFEDisplacementMapElement_height_Getter(this);

  @DomName('SVGFEDisplacementMapElement.result')
  @DocsEditable()
  AnimatedString get result => _blink.Native_SVGFEDisplacementMapElement_result_Getter(this);

  @DomName('SVGFEDisplacementMapElement.width')
  @DocsEditable()
  AnimatedLength get width => _blink.Native_SVGFEDisplacementMapElement_width_Getter(this);

  @DomName('SVGFEDisplacementMapElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.Native_SVGFEDisplacementMapElement_x_Getter(this);

  @DomName('SVGFEDisplacementMapElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.Native_SVGFEDisplacementMapElement_y_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGFEDistantLightElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class FEDistantLightElement extends SvgElement {
  // To suppress missing implicit constructor warnings.
  factory FEDistantLightElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEDistantLightElement.SVGFEDistantLightElement')
  @DocsEditable()
  factory FEDistantLightElement() => _SvgElementFactoryProvider.createSvgElement_tag("feDistantLight");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FEDistantLightElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFEDistantLightElement.azimuth')
  @DocsEditable()
  AnimatedNumber get azimuth => _blink.Native_SVGFEDistantLightElement_azimuth_Getter(this);

  @DomName('SVGFEDistantLightElement.elevation')
  @DocsEditable()
  AnimatedNumber get elevation => _blink.Native_SVGFEDistantLightElement_elevation_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGFEFloodElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class FEFloodElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory FEFloodElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEFloodElement.SVGFEFloodElement')
  @DocsEditable()
  factory FEFloodElement() => _SvgElementFactoryProvider.createSvgElement_tag("feFlood");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FEFloodElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFEFloodElement.height')
  @DocsEditable()
  AnimatedLength get height => _blink.Native_SVGFEFloodElement_height_Getter(this);

  @DomName('SVGFEFloodElement.result')
  @DocsEditable()
  AnimatedString get result => _blink.Native_SVGFEFloodElement_result_Getter(this);

  @DomName('SVGFEFloodElement.width')
  @DocsEditable()
  AnimatedLength get width => _blink.Native_SVGFEFloodElement_width_Getter(this);

  @DomName('SVGFEFloodElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.Native_SVGFEFloodElement_x_Getter(this);

  @DomName('SVGFEFloodElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.Native_SVGFEFloodElement_y_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGFEFuncAElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class FEFuncAElement extends _SVGComponentTransferFunctionElement {
  // To suppress missing implicit constructor warnings.
  factory FEFuncAElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEFuncAElement.SVGFEFuncAElement')
  @DocsEditable()
  factory FEFuncAElement() => _SvgElementFactoryProvider.createSvgElement_tag("feFuncA");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FEFuncAElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGFEFuncBElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class FEFuncBElement extends _SVGComponentTransferFunctionElement {
  // To suppress missing implicit constructor warnings.
  factory FEFuncBElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEFuncBElement.SVGFEFuncBElement')
  @DocsEditable()
  factory FEFuncBElement() => _SvgElementFactoryProvider.createSvgElement_tag("feFuncB");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FEFuncBElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGFEFuncGElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class FEFuncGElement extends _SVGComponentTransferFunctionElement {
  // To suppress missing implicit constructor warnings.
  factory FEFuncGElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEFuncGElement.SVGFEFuncGElement')
  @DocsEditable()
  factory FEFuncGElement() => _SvgElementFactoryProvider.createSvgElement_tag("feFuncG");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FEFuncGElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGFEFuncRElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class FEFuncRElement extends _SVGComponentTransferFunctionElement {
  // To suppress missing implicit constructor warnings.
  factory FEFuncRElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEFuncRElement.SVGFEFuncRElement')
  @DocsEditable()
  factory FEFuncRElement() => _SvgElementFactoryProvider.createSvgElement_tag("feFuncR");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FEFuncRElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGFEGaussianBlurElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class FEGaussianBlurElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory FEGaussianBlurElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEGaussianBlurElement.SVGFEGaussianBlurElement')
  @DocsEditable()
  factory FEGaussianBlurElement() => _SvgElementFactoryProvider.createSvgElement_tag("feGaussianBlur");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FEGaussianBlurElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFEGaussianBlurElement.in1')
  @DocsEditable()
  AnimatedString get in1 => _blink.Native_SVGFEGaussianBlurElement_in1_Getter(this);

  @DomName('SVGFEGaussianBlurElement.stdDeviationX')
  @DocsEditable()
  AnimatedNumber get stdDeviationX => _blink.Native_SVGFEGaussianBlurElement_stdDeviationX_Getter(this);

  @DomName('SVGFEGaussianBlurElement.stdDeviationY')
  @DocsEditable()
  AnimatedNumber get stdDeviationY => _blink.Native_SVGFEGaussianBlurElement_stdDeviationY_Getter(this);

  @DomName('SVGFEGaussianBlurElement.setStdDeviation')
  @DocsEditable()
  void setStdDeviation(num stdDeviationX, num stdDeviationY) => _blink.Native_SVGFEGaussianBlurElement_setStdDeviation_Callback(this, stdDeviationX, stdDeviationY);

  @DomName('SVGFEGaussianBlurElement.height')
  @DocsEditable()
  AnimatedLength get height => _blink.Native_SVGFEGaussianBlurElement_height_Getter(this);

  @DomName('SVGFEGaussianBlurElement.result')
  @DocsEditable()
  AnimatedString get result => _blink.Native_SVGFEGaussianBlurElement_result_Getter(this);

  @DomName('SVGFEGaussianBlurElement.width')
  @DocsEditable()
  AnimatedLength get width => _blink.Native_SVGFEGaussianBlurElement_width_Getter(this);

  @DomName('SVGFEGaussianBlurElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.Native_SVGFEGaussianBlurElement_x_Getter(this);

  @DomName('SVGFEGaussianBlurElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.Native_SVGFEGaussianBlurElement_y_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGFEImageElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class FEImageElement extends SvgElement implements FilterPrimitiveStandardAttributes, UriReference {
  // To suppress missing implicit constructor warnings.
  factory FEImageElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEImageElement.SVGFEImageElement')
  @DocsEditable()
  factory FEImageElement() => _SvgElementFactoryProvider.createSvgElement_tag("feImage");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FEImageElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFEImageElement.preserveAspectRatio')
  @DocsEditable()
  AnimatedPreserveAspectRatio get preserveAspectRatio => _blink.Native_SVGFEImageElement_preserveAspectRatio_Getter(this);

  @DomName('SVGFEImageElement.height')
  @DocsEditable()
  AnimatedLength get height => _blink.Native_SVGFEImageElement_height_Getter(this);

  @DomName('SVGFEImageElement.result')
  @DocsEditable()
  AnimatedString get result => _blink.Native_SVGFEImageElement_result_Getter(this);

  @DomName('SVGFEImageElement.width')
  @DocsEditable()
  AnimatedLength get width => _blink.Native_SVGFEImageElement_width_Getter(this);

  @DomName('SVGFEImageElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.Native_SVGFEImageElement_x_Getter(this);

  @DomName('SVGFEImageElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.Native_SVGFEImageElement_y_Getter(this);

  @DomName('SVGFEImageElement.href')
  @DocsEditable()
  AnimatedString get href => _blink.Native_SVGFEImageElement_href_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGFEMergeElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class FEMergeElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory FEMergeElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEMergeElement.SVGFEMergeElement')
  @DocsEditable()
  factory FEMergeElement() => _SvgElementFactoryProvider.createSvgElement_tag("feMerge");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FEMergeElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFEMergeElement.height')
  @DocsEditable()
  AnimatedLength get height => _blink.Native_SVGFEMergeElement_height_Getter(this);

  @DomName('SVGFEMergeElement.result')
  @DocsEditable()
  AnimatedString get result => _blink.Native_SVGFEMergeElement_result_Getter(this);

  @DomName('SVGFEMergeElement.width')
  @DocsEditable()
  AnimatedLength get width => _blink.Native_SVGFEMergeElement_width_Getter(this);

  @DomName('SVGFEMergeElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.Native_SVGFEMergeElement_x_Getter(this);

  @DomName('SVGFEMergeElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.Native_SVGFEMergeElement_y_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGFEMergeNodeElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class FEMergeNodeElement extends SvgElement {
  // To suppress missing implicit constructor warnings.
  factory FEMergeNodeElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEMergeNodeElement.SVGFEMergeNodeElement')
  @DocsEditable()
  factory FEMergeNodeElement() => _SvgElementFactoryProvider.createSvgElement_tag("feMergeNode");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FEMergeNodeElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFEMergeNodeElement.in1')
  @DocsEditable()
  AnimatedString get in1 => _blink.Native_SVGFEMergeNodeElement_in1_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGFEMorphologyElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class FEMorphologyElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory FEMorphologyElement._() { throw new UnsupportedError("Not supported"); }
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FEMorphologyElement.created() : super.created();

  @DomName('SVGFEMorphologyElement.SVG_MORPHOLOGY_OPERATOR_DILATE')
  @DocsEditable()
  static const int SVG_MORPHOLOGY_OPERATOR_DILATE = 2;

  @DomName('SVGFEMorphologyElement.SVG_MORPHOLOGY_OPERATOR_ERODE')
  @DocsEditable()
  static const int SVG_MORPHOLOGY_OPERATOR_ERODE = 1;

  @DomName('SVGFEMorphologyElement.SVG_MORPHOLOGY_OPERATOR_UNKNOWN')
  @DocsEditable()
  static const int SVG_MORPHOLOGY_OPERATOR_UNKNOWN = 0;

  @DomName('SVGFEMorphologyElement.in1')
  @DocsEditable()
  AnimatedString get in1 => _blink.Native_SVGFEMorphologyElement_in1_Getter(this);

  @DomName('SVGFEMorphologyElement.operator')
  @DocsEditable()
  AnimatedEnumeration get operator => _blink.Native_SVGFEMorphologyElement_operator_Getter(this);

  @DomName('SVGFEMorphologyElement.radiusX')
  @DocsEditable()
  AnimatedNumber get radiusX => _blink.Native_SVGFEMorphologyElement_radiusX_Getter(this);

  @DomName('SVGFEMorphologyElement.radiusY')
  @DocsEditable()
  AnimatedNumber get radiusY => _blink.Native_SVGFEMorphologyElement_radiusY_Getter(this);

  @DomName('SVGFEMorphologyElement.setRadius')
  @DocsEditable()
  void setRadius(num radiusX, num radiusY) => _blink.Native_SVGFEMorphologyElement_setRadius_Callback(this, radiusX, radiusY);

  @DomName('SVGFEMorphologyElement.height')
  @DocsEditable()
  AnimatedLength get height => _blink.Native_SVGFEMorphologyElement_height_Getter(this);

  @DomName('SVGFEMorphologyElement.result')
  @DocsEditable()
  AnimatedString get result => _blink.Native_SVGFEMorphologyElement_result_Getter(this);

  @DomName('SVGFEMorphologyElement.width')
  @DocsEditable()
  AnimatedLength get width => _blink.Native_SVGFEMorphologyElement_width_Getter(this);

  @DomName('SVGFEMorphologyElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.Native_SVGFEMorphologyElement_x_Getter(this);

  @DomName('SVGFEMorphologyElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.Native_SVGFEMorphologyElement_y_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGFEOffsetElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class FEOffsetElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory FEOffsetElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEOffsetElement.SVGFEOffsetElement')
  @DocsEditable()
  factory FEOffsetElement() => _SvgElementFactoryProvider.createSvgElement_tag("feOffset");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FEOffsetElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFEOffsetElement.dx')
  @DocsEditable()
  AnimatedNumber get dx => _blink.Native_SVGFEOffsetElement_dx_Getter(this);

  @DomName('SVGFEOffsetElement.dy')
  @DocsEditable()
  AnimatedNumber get dy => _blink.Native_SVGFEOffsetElement_dy_Getter(this);

  @DomName('SVGFEOffsetElement.in1')
  @DocsEditable()
  AnimatedString get in1 => _blink.Native_SVGFEOffsetElement_in1_Getter(this);

  @DomName('SVGFEOffsetElement.height')
  @DocsEditable()
  AnimatedLength get height => _blink.Native_SVGFEOffsetElement_height_Getter(this);

  @DomName('SVGFEOffsetElement.result')
  @DocsEditable()
  AnimatedString get result => _blink.Native_SVGFEOffsetElement_result_Getter(this);

  @DomName('SVGFEOffsetElement.width')
  @DocsEditable()
  AnimatedLength get width => _blink.Native_SVGFEOffsetElement_width_Getter(this);

  @DomName('SVGFEOffsetElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.Native_SVGFEOffsetElement_x_Getter(this);

  @DomName('SVGFEOffsetElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.Native_SVGFEOffsetElement_y_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGFEPointLightElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class FEPointLightElement extends SvgElement {
  // To suppress missing implicit constructor warnings.
  factory FEPointLightElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEPointLightElement.SVGFEPointLightElement')
  @DocsEditable()
  factory FEPointLightElement() => _SvgElementFactoryProvider.createSvgElement_tag("fePointLight");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FEPointLightElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFEPointLightElement.x')
  @DocsEditable()
  AnimatedNumber get x => _blink.Native_SVGFEPointLightElement_x_Getter(this);

  @DomName('SVGFEPointLightElement.y')
  @DocsEditable()
  AnimatedNumber get y => _blink.Native_SVGFEPointLightElement_y_Getter(this);

  @DomName('SVGFEPointLightElement.z')
  @DocsEditable()
  AnimatedNumber get z => _blink.Native_SVGFEPointLightElement_z_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGFESpecularLightingElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class FESpecularLightingElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory FESpecularLightingElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFESpecularLightingElement.SVGFESpecularLightingElement')
  @DocsEditable()
  factory FESpecularLightingElement() => _SvgElementFactoryProvider.createSvgElement_tag("feSpecularLighting");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FESpecularLightingElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFESpecularLightingElement.in1')
  @DocsEditable()
  AnimatedString get in1 => _blink.Native_SVGFESpecularLightingElement_in1_Getter(this);

  @DomName('SVGFESpecularLightingElement.specularConstant')
  @DocsEditable()
  AnimatedNumber get specularConstant => _blink.Native_SVGFESpecularLightingElement_specularConstant_Getter(this);

  @DomName('SVGFESpecularLightingElement.specularExponent')
  @DocsEditable()
  AnimatedNumber get specularExponent => _blink.Native_SVGFESpecularLightingElement_specularExponent_Getter(this);

  @DomName('SVGFESpecularLightingElement.surfaceScale')
  @DocsEditable()
  AnimatedNumber get surfaceScale => _blink.Native_SVGFESpecularLightingElement_surfaceScale_Getter(this);

  @DomName('SVGFESpecularLightingElement.height')
  @DocsEditable()
  AnimatedLength get height => _blink.Native_SVGFESpecularLightingElement_height_Getter(this);

  @DomName('SVGFESpecularLightingElement.result')
  @DocsEditable()
  AnimatedString get result => _blink.Native_SVGFESpecularLightingElement_result_Getter(this);

  @DomName('SVGFESpecularLightingElement.width')
  @DocsEditable()
  AnimatedLength get width => _blink.Native_SVGFESpecularLightingElement_width_Getter(this);

  @DomName('SVGFESpecularLightingElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.Native_SVGFESpecularLightingElement_x_Getter(this);

  @DomName('SVGFESpecularLightingElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.Native_SVGFESpecularLightingElement_y_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGFESpotLightElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class FESpotLightElement extends SvgElement {
  // To suppress missing implicit constructor warnings.
  factory FESpotLightElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFESpotLightElement.SVGFESpotLightElement')
  @DocsEditable()
  factory FESpotLightElement() => _SvgElementFactoryProvider.createSvgElement_tag("feSpotLight");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FESpotLightElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFESpotLightElement.limitingConeAngle')
  @DocsEditable()
  AnimatedNumber get limitingConeAngle => _blink.Native_SVGFESpotLightElement_limitingConeAngle_Getter(this);

  @DomName('SVGFESpotLightElement.pointsAtX')
  @DocsEditable()
  AnimatedNumber get pointsAtX => _blink.Native_SVGFESpotLightElement_pointsAtX_Getter(this);

  @DomName('SVGFESpotLightElement.pointsAtY')
  @DocsEditable()
  AnimatedNumber get pointsAtY => _blink.Native_SVGFESpotLightElement_pointsAtY_Getter(this);

  @DomName('SVGFESpotLightElement.pointsAtZ')
  @DocsEditable()
  AnimatedNumber get pointsAtZ => _blink.Native_SVGFESpotLightElement_pointsAtZ_Getter(this);

  @DomName('SVGFESpotLightElement.specularExponent')
  @DocsEditable()
  AnimatedNumber get specularExponent => _blink.Native_SVGFESpotLightElement_specularExponent_Getter(this);

  @DomName('SVGFESpotLightElement.x')
  @DocsEditable()
  AnimatedNumber get x => _blink.Native_SVGFESpotLightElement_x_Getter(this);

  @DomName('SVGFESpotLightElement.y')
  @DocsEditable()
  AnimatedNumber get y => _blink.Native_SVGFESpotLightElement_y_Getter(this);

  @DomName('SVGFESpotLightElement.z')
  @DocsEditable()
  AnimatedNumber get z => _blink.Native_SVGFESpotLightElement_z_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGFETileElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class FETileElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory FETileElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFETileElement.SVGFETileElement')
  @DocsEditable()
  factory FETileElement() => _SvgElementFactoryProvider.createSvgElement_tag("feTile");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FETileElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFETileElement.in1')
  @DocsEditable()
  AnimatedString get in1 => _blink.Native_SVGFETileElement_in1_Getter(this);

  @DomName('SVGFETileElement.height')
  @DocsEditable()
  AnimatedLength get height => _blink.Native_SVGFETileElement_height_Getter(this);

  @DomName('SVGFETileElement.result')
  @DocsEditable()
  AnimatedString get result => _blink.Native_SVGFETileElement_result_Getter(this);

  @DomName('SVGFETileElement.width')
  @DocsEditable()
  AnimatedLength get width => _blink.Native_SVGFETileElement_width_Getter(this);

  @DomName('SVGFETileElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.Native_SVGFETileElement_x_Getter(this);

  @DomName('SVGFETileElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.Native_SVGFETileElement_y_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGFETurbulenceElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class FETurbulenceElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory FETurbulenceElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFETurbulenceElement.SVGFETurbulenceElement')
  @DocsEditable()
  factory FETurbulenceElement() => _SvgElementFactoryProvider.createSvgElement_tag("feTurbulence");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FETurbulenceElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFETurbulenceElement.SVG_STITCHTYPE_NOSTITCH')
  @DocsEditable()
  static const int SVG_STITCHTYPE_NOSTITCH = 2;

  @DomName('SVGFETurbulenceElement.SVG_STITCHTYPE_STITCH')
  @DocsEditable()
  static const int SVG_STITCHTYPE_STITCH = 1;

  @DomName('SVGFETurbulenceElement.SVG_STITCHTYPE_UNKNOWN')
  @DocsEditable()
  static const int SVG_STITCHTYPE_UNKNOWN = 0;

  @DomName('SVGFETurbulenceElement.SVG_TURBULENCE_TYPE_FRACTALNOISE')
  @DocsEditable()
  static const int SVG_TURBULENCE_TYPE_FRACTALNOISE = 1;

  @DomName('SVGFETurbulenceElement.SVG_TURBULENCE_TYPE_TURBULENCE')
  @DocsEditable()
  static const int SVG_TURBULENCE_TYPE_TURBULENCE = 2;

  @DomName('SVGFETurbulenceElement.SVG_TURBULENCE_TYPE_UNKNOWN')
  @DocsEditable()
  static const int SVG_TURBULENCE_TYPE_UNKNOWN = 0;

  @DomName('SVGFETurbulenceElement.baseFrequencyX')
  @DocsEditable()
  AnimatedNumber get baseFrequencyX => _blink.Native_SVGFETurbulenceElement_baseFrequencyX_Getter(this);

  @DomName('SVGFETurbulenceElement.baseFrequencyY')
  @DocsEditable()
  AnimatedNumber get baseFrequencyY => _blink.Native_SVGFETurbulenceElement_baseFrequencyY_Getter(this);

  @DomName('SVGFETurbulenceElement.numOctaves')
  @DocsEditable()
  AnimatedInteger get numOctaves => _blink.Native_SVGFETurbulenceElement_numOctaves_Getter(this);

  @DomName('SVGFETurbulenceElement.seed')
  @DocsEditable()
  AnimatedNumber get seed => _blink.Native_SVGFETurbulenceElement_seed_Getter(this);

  @DomName('SVGFETurbulenceElement.stitchTiles')
  @DocsEditable()
  AnimatedEnumeration get stitchTiles => _blink.Native_SVGFETurbulenceElement_stitchTiles_Getter(this);

  @DomName('SVGFETurbulenceElement.type')
  @DocsEditable()
  AnimatedEnumeration get type => _blink.Native_SVGFETurbulenceElement_type_Getter(this);

  @DomName('SVGFETurbulenceElement.height')
  @DocsEditable()
  AnimatedLength get height => _blink.Native_SVGFETurbulenceElement_height_Getter(this);

  @DomName('SVGFETurbulenceElement.result')
  @DocsEditable()
  AnimatedString get result => _blink.Native_SVGFETurbulenceElement_result_Getter(this);

  @DomName('SVGFETurbulenceElement.width')
  @DocsEditable()
  AnimatedLength get width => _blink.Native_SVGFETurbulenceElement_width_Getter(this);

  @DomName('SVGFETurbulenceElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.Native_SVGFETurbulenceElement_x_Getter(this);

  @DomName('SVGFETurbulenceElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.Native_SVGFETurbulenceElement_y_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGFilterElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class FilterElement extends SvgElement implements UriReference {
  // To suppress missing implicit constructor warnings.
  factory FilterElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFilterElement.SVGFilterElement')
  @DocsEditable()
  factory FilterElement() => _SvgElementFactoryProvider.createSvgElement_tag("filter");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FilterElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFilterElement.filterResX')
  @DocsEditable()
  AnimatedInteger get filterResX => _blink.Native_SVGFilterElement_filterResX_Getter(this);

  @DomName('SVGFilterElement.filterResY')
  @DocsEditable()
  AnimatedInteger get filterResY => _blink.Native_SVGFilterElement_filterResY_Getter(this);

  @DomName('SVGFilterElement.filterUnits')
  @DocsEditable()
  AnimatedEnumeration get filterUnits => _blink.Native_SVGFilterElement_filterUnits_Getter(this);

  @DomName('SVGFilterElement.height')
  @DocsEditable()
  AnimatedLength get height => _blink.Native_SVGFilterElement_height_Getter(this);

  @DomName('SVGFilterElement.primitiveUnits')
  @DocsEditable()
  AnimatedEnumeration get primitiveUnits => _blink.Native_SVGFilterElement_primitiveUnits_Getter(this);

  @DomName('SVGFilterElement.width')
  @DocsEditable()
  AnimatedLength get width => _blink.Native_SVGFilterElement_width_Getter(this);

  @DomName('SVGFilterElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.Native_SVGFilterElement_x_Getter(this);

  @DomName('SVGFilterElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.Native_SVGFilterElement_y_Getter(this);

  @DomName('SVGFilterElement.setFilterRes')
  @DocsEditable()
  void setFilterRes(int filterResX, int filterResY) => _blink.Native_SVGFilterElement_setFilterRes_Callback(this, filterResX, filterResY);

  @DomName('SVGFilterElement.href')
  @DocsEditable()
  AnimatedString get href => _blink.Native_SVGFilterElement_href_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGFilterPrimitiveStandardAttributes')
@Unstable()
abstract class FilterPrimitiveStandardAttributes extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory FilterPrimitiveStandardAttributes._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFilterPrimitiveStandardAttributes.height')
  @DocsEditable()
  AnimatedLength get height => _blink.Native_SVGFilterPrimitiveStandardAttributes_height_Getter(this);

  @DomName('SVGFilterPrimitiveStandardAttributes.result')
  @DocsEditable()
  AnimatedString get result => _blink.Native_SVGFilterPrimitiveStandardAttributes_result_Getter(this);

  @DomName('SVGFilterPrimitiveStandardAttributes.width')
  @DocsEditable()
  AnimatedLength get width => _blink.Native_SVGFilterPrimitiveStandardAttributes_width_Getter(this);

  @DomName('SVGFilterPrimitiveStandardAttributes.x')
  @DocsEditable()
  AnimatedLength get x => _blink.Native_SVGFilterPrimitiveStandardAttributes_x_Getter(this);

  @DomName('SVGFilterPrimitiveStandardAttributes.y')
  @DocsEditable()
  AnimatedLength get y => _blink.Native_SVGFilterPrimitiveStandardAttributes_y_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGFitToViewBox')
@Unstable()
abstract class FitToViewBox extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory FitToViewBox._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFitToViewBox.preserveAspectRatio')
  @DocsEditable()
  AnimatedPreserveAspectRatio get preserveAspectRatio => _blink.Native_SVGFitToViewBox_preserveAspectRatio_Getter(this);

  @DomName('SVGFitToViewBox.viewBox')
  @DocsEditable()
  AnimatedRect get viewBox => _blink.Native_SVGFitToViewBox_viewBox_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGForeignObjectElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class ForeignObjectElement extends GraphicsElement {
  // To suppress missing implicit constructor warnings.
  factory ForeignObjectElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGForeignObjectElement.SVGForeignObjectElement')
  @DocsEditable()
  factory ForeignObjectElement() => _SvgElementFactoryProvider.createSvgElement_tag("foreignObject");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  ForeignObjectElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGForeignObjectElement.height')
  @DocsEditable()
  AnimatedLength get height => _blink.Native_SVGForeignObjectElement_height_Getter(this);

  @DomName('SVGForeignObjectElement.width')
  @DocsEditable()
  AnimatedLength get width => _blink.Native_SVGForeignObjectElement_width_Getter(this);

  @DomName('SVGForeignObjectElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.Native_SVGForeignObjectElement_x_Getter(this);

  @DomName('SVGForeignObjectElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.Native_SVGForeignObjectElement_y_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGGElement')
@Unstable()
class GElement extends GraphicsElement {
  // To suppress missing implicit constructor warnings.
  factory GElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGGElement.SVGGElement')
  @DocsEditable()
  factory GElement() => _SvgElementFactoryProvider.createSvgElement_tag("g");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  GElement.created() : super.created();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGGeometryElement')
@Experimental() // untriaged
class GeometryElement extends GraphicsElement {
  // To suppress missing implicit constructor warnings.
  factory GeometryElement._() { throw new UnsupportedError("Not supported"); }
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  GeometryElement.created() : super.created();

  @DomName('SVGGeometryElement.isPointInFill')
  @DocsEditable()
  @Experimental() // untriaged
  bool isPointInFill(Point point) => _blink.Native_SVGGeometryElement_isPointInFill_Callback(this, point);

  @DomName('SVGGeometryElement.isPointInStroke')
  @DocsEditable()
  @Experimental() // untriaged
  bool isPointInStroke(Point point) => _blink.Native_SVGGeometryElement_isPointInStroke_Callback(this, point);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGGraphicsElement')
@Experimental() // untriaged
class GraphicsElement extends SvgElement implements Tests {
  // To suppress missing implicit constructor warnings.
  factory GraphicsElement._() { throw new UnsupportedError("Not supported"); }
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  GraphicsElement.created() : super.created();

  @DomName('SVGGraphicsElement.farthestViewportElement')
  @DocsEditable()
  @Experimental() // untriaged
  SvgElement get farthestViewportElement => _blink.Native_SVGGraphicsElement_farthestViewportElement_Getter(this);

  @DomName('SVGGraphicsElement.nearestViewportElement')
  @DocsEditable()
  @Experimental() // untriaged
  SvgElement get nearestViewportElement => _blink.Native_SVGGraphicsElement_nearestViewportElement_Getter(this);

  @DomName('SVGGraphicsElement.transform')
  @DocsEditable()
  @Experimental() // untriaged
  AnimatedTransformList get transform => _blink.Native_SVGGraphicsElement_transform_Getter(this);

  @DomName('SVGGraphicsElement.getBBox')
  @DocsEditable()
  @Experimental() // untriaged
  Rect getBBox() => _blink.Native_SVGGraphicsElement_getBBox_Callback(this);

  @DomName('SVGGraphicsElement.getCTM')
  @DocsEditable()
  @Experimental() // untriaged
  Matrix getCtm() => _blink.Native_SVGGraphicsElement_getCTM_Callback(this);

  @DomName('SVGGraphicsElement.getScreenCTM')
  @DocsEditable()
  @Experimental() // untriaged
  Matrix getScreenCtm() => _blink.Native_SVGGraphicsElement_getScreenCTM_Callback(this);

  @DomName('SVGGraphicsElement.getTransformToElement')
  @DocsEditable()
  @Experimental() // untriaged
  Matrix getTransformToElement(SvgElement element) => _blink.Native_SVGGraphicsElement_getTransformToElement_Callback(this, element);

  @DomName('SVGGraphicsElement.requiredExtensions')
  @DocsEditable()
  @Experimental() // untriaged
  StringList get requiredExtensions => _blink.Native_SVGGraphicsElement_requiredExtensions_Getter(this);

  @DomName('SVGGraphicsElement.requiredFeatures')
  @DocsEditable()
  @Experimental() // untriaged
  StringList get requiredFeatures => _blink.Native_SVGGraphicsElement_requiredFeatures_Getter(this);

  @DomName('SVGGraphicsElement.systemLanguage')
  @DocsEditable()
  @Experimental() // untriaged
  StringList get systemLanguage => _blink.Native_SVGGraphicsElement_systemLanguage_Getter(this);

  @DomName('SVGGraphicsElement.hasExtension')
  @DocsEditable()
  @Experimental() // untriaged
  bool hasExtension(String extension) => _blink.Native_SVGGraphicsElement_hasExtension_Callback(this, extension);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGImageElement')
@Unstable()
class ImageElement extends GraphicsElement implements UriReference {
  // To suppress missing implicit constructor warnings.
  factory ImageElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGImageElement.SVGImageElement')
  @DocsEditable()
  factory ImageElement() => _SvgElementFactoryProvider.createSvgElement_tag("image");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  ImageElement.created() : super.created();

  @DomName('SVGImageElement.height')
  @DocsEditable()
  AnimatedLength get height => _blink.Native_SVGImageElement_height_Getter(this);

  @DomName('SVGImageElement.preserveAspectRatio')
  @DocsEditable()
  AnimatedPreserveAspectRatio get preserveAspectRatio => _blink.Native_SVGImageElement_preserveAspectRatio_Getter(this);

  @DomName('SVGImageElement.width')
  @DocsEditable()
  AnimatedLength get width => _blink.Native_SVGImageElement_width_Getter(this);

  @DomName('SVGImageElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.Native_SVGImageElement_x_Getter(this);

  @DomName('SVGImageElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.Native_SVGImageElement_y_Getter(this);

  @DomName('SVGImageElement.href')
  @DocsEditable()
  AnimatedString get href => _blink.Native_SVGImageElement_href_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGLength')
@Unstable()
class Length extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory Length._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGLength.SVG_LENGTHTYPE_CM')
  @DocsEditable()
  static const int SVG_LENGTHTYPE_CM = 6;

  @DomName('SVGLength.SVG_LENGTHTYPE_EMS')
  @DocsEditable()
  static const int SVG_LENGTHTYPE_EMS = 3;

  @DomName('SVGLength.SVG_LENGTHTYPE_EXS')
  @DocsEditable()
  static const int SVG_LENGTHTYPE_EXS = 4;

  @DomName('SVGLength.SVG_LENGTHTYPE_IN')
  @DocsEditable()
  static const int SVG_LENGTHTYPE_IN = 8;

  @DomName('SVGLength.SVG_LENGTHTYPE_MM')
  @DocsEditable()
  static const int SVG_LENGTHTYPE_MM = 7;

  @DomName('SVGLength.SVG_LENGTHTYPE_NUMBER')
  @DocsEditable()
  static const int SVG_LENGTHTYPE_NUMBER = 1;

  @DomName('SVGLength.SVG_LENGTHTYPE_PC')
  @DocsEditable()
  static const int SVG_LENGTHTYPE_PC = 10;

  @DomName('SVGLength.SVG_LENGTHTYPE_PERCENTAGE')
  @DocsEditable()
  static const int SVG_LENGTHTYPE_PERCENTAGE = 2;

  @DomName('SVGLength.SVG_LENGTHTYPE_PT')
  @DocsEditable()
  static const int SVG_LENGTHTYPE_PT = 9;

  @DomName('SVGLength.SVG_LENGTHTYPE_PX')
  @DocsEditable()
  static const int SVG_LENGTHTYPE_PX = 5;

  @DomName('SVGLength.SVG_LENGTHTYPE_UNKNOWN')
  @DocsEditable()
  static const int SVG_LENGTHTYPE_UNKNOWN = 0;

  @DomName('SVGLength.unitType')
  @DocsEditable()
  int get unitType => _blink.Native_SVGLength_unitType_Getter(this);

  @DomName('SVGLength.value')
  @DocsEditable()
  num get value => _blink.Native_SVGLength_value_Getter(this);

  @DomName('SVGLength.value')
  @DocsEditable()
  void set value(num value) => _blink.Native_SVGLength_value_Setter(this, value);

  @DomName('SVGLength.valueAsString')
  @DocsEditable()
  String get valueAsString => _blink.Native_SVGLength_valueAsString_Getter(this);

  @DomName('SVGLength.valueAsString')
  @DocsEditable()
  void set valueAsString(String value) => _blink.Native_SVGLength_valueAsString_Setter(this, value);

  @DomName('SVGLength.valueInSpecifiedUnits')
  @DocsEditable()
  num get valueInSpecifiedUnits => _blink.Native_SVGLength_valueInSpecifiedUnits_Getter(this);

  @DomName('SVGLength.valueInSpecifiedUnits')
  @DocsEditable()
  void set valueInSpecifiedUnits(num value) => _blink.Native_SVGLength_valueInSpecifiedUnits_Setter(this, value);

  @DomName('SVGLength.convertToSpecifiedUnits')
  @DocsEditable()
  void convertToSpecifiedUnits(int unitType) => _blink.Native_SVGLength_convertToSpecifiedUnits_Callback(this, unitType);

  @DomName('SVGLength.newValueSpecifiedUnits')
  @DocsEditable()
  void newValueSpecifiedUnits(int unitType, num valueInSpecifiedUnits) => _blink.Native_SVGLength_newValueSpecifiedUnits_Callback(this, unitType, valueInSpecifiedUnits);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGLengthList')
@Unstable()
class LengthList extends NativeFieldWrapperClass2 with ListMixin<Length>, ImmutableListMixin<Length> implements List<Length> {
  // To suppress missing implicit constructor warnings.
  factory LengthList._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGLengthList.numberOfItems')
  @DocsEditable()
  int get numberOfItems => _blink.Native_SVGLengthList_numberOfItems_Getter(this);

  Length operator[](int index) {
    if (index < 0 || index >= length)
      throw new RangeError.range(index, 0, length);
    return getItem(index);
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
      return getItem(0);
    }
    throw new StateError("No elements");
  }

  Length get last {
    int len = this.length;
    if (len > 0) {
      return getItem(len - 1);
    }
    throw new StateError("No elements");
  }

  Length get single {
    int len = this.length;
    if (len == 1) {
      return getItem(0);
    }
    if (len == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  Length elementAt(int index) => this[index];
  // -- end List<Length> mixins.

  @DomName('SVGLengthList.appendItem')
  @DocsEditable()
  Length appendItem(Length item) => _blink.Native_SVGLengthList_appendItem_Callback(this, item);

  @DomName('SVGLengthList.clear')
  @DocsEditable()
  void clear() => _blink.Native_SVGLengthList_clear_Callback(this);

  @DomName('SVGLengthList.getItem')
  @DocsEditable()
  Length getItem(int index) => _blink.Native_SVGLengthList_getItem_Callback(this, index);

  @DomName('SVGLengthList.initialize')
  @DocsEditable()
  Length initialize(Length item) => _blink.Native_SVGLengthList_initialize_Callback(this, item);

  @DomName('SVGLengthList.insertItemBefore')
  @DocsEditable()
  Length insertItemBefore(Length item, int index) => _blink.Native_SVGLengthList_insertItemBefore_Callback(this, item, index);

  @DomName('SVGLengthList.removeItem')
  @DocsEditable()
  Length removeItem(int index) => _blink.Native_SVGLengthList_removeItem_Callback(this, index);

  @DomName('SVGLengthList.replaceItem')
  @DocsEditable()
  Length replaceItem(Length item, int index) => _blink.Native_SVGLengthList_replaceItem_Callback(this, item, index);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGLineElement')
@Unstable()
class LineElement extends GeometryElement {
  // To suppress missing implicit constructor warnings.
  factory LineElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGLineElement.SVGLineElement')
  @DocsEditable()
  factory LineElement() => _SvgElementFactoryProvider.createSvgElement_tag("line");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  LineElement.created() : super.created();

  @DomName('SVGLineElement.x1')
  @DocsEditable()
  AnimatedLength get x1 => _blink.Native_SVGLineElement_x1_Getter(this);

  @DomName('SVGLineElement.x2')
  @DocsEditable()
  AnimatedLength get x2 => _blink.Native_SVGLineElement_x2_Getter(this);

  @DomName('SVGLineElement.y1')
  @DocsEditable()
  AnimatedLength get y1 => _blink.Native_SVGLineElement_y1_Getter(this);

  @DomName('SVGLineElement.y2')
  @DocsEditable()
  AnimatedLength get y2 => _blink.Native_SVGLineElement_y2_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGLinearGradientElement')
@Unstable()
class LinearGradientElement extends _GradientElement {
  // To suppress missing implicit constructor warnings.
  factory LinearGradientElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGLinearGradientElement.SVGLinearGradientElement')
  @DocsEditable()
  factory LinearGradientElement() => _SvgElementFactoryProvider.createSvgElement_tag("linearGradient");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  LinearGradientElement.created() : super.created();

  @DomName('SVGLinearGradientElement.x1')
  @DocsEditable()
  AnimatedLength get x1 => _blink.Native_SVGLinearGradientElement_x1_Getter(this);

  @DomName('SVGLinearGradientElement.x2')
  @DocsEditable()
  AnimatedLength get x2 => _blink.Native_SVGLinearGradientElement_x2_Getter(this);

  @DomName('SVGLinearGradientElement.y1')
  @DocsEditable()
  AnimatedLength get y1 => _blink.Native_SVGLinearGradientElement_y1_Getter(this);

  @DomName('SVGLinearGradientElement.y2')
  @DocsEditable()
  AnimatedLength get y2 => _blink.Native_SVGLinearGradientElement_y2_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGMarkerElement')
@Unstable()
class MarkerElement extends SvgElement implements FitToViewBox {
  // To suppress missing implicit constructor warnings.
  factory MarkerElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGMarkerElement.SVGMarkerElement')
  @DocsEditable()
  factory MarkerElement() => _SvgElementFactoryProvider.createSvgElement_tag("marker");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  MarkerElement.created() : super.created();

  @DomName('SVGMarkerElement.SVG_MARKERUNITS_STROKEWIDTH')
  @DocsEditable()
  static const int SVG_MARKERUNITS_STROKEWIDTH = 2;

  @DomName('SVGMarkerElement.SVG_MARKERUNITS_UNKNOWN')
  @DocsEditable()
  static const int SVG_MARKERUNITS_UNKNOWN = 0;

  @DomName('SVGMarkerElement.SVG_MARKERUNITS_USERSPACEONUSE')
  @DocsEditable()
  static const int SVG_MARKERUNITS_USERSPACEONUSE = 1;

  @DomName('SVGMarkerElement.SVG_MARKER_ORIENT_ANGLE')
  @DocsEditable()
  static const int SVG_MARKER_ORIENT_ANGLE = 2;

  @DomName('SVGMarkerElement.SVG_MARKER_ORIENT_AUTO')
  @DocsEditable()
  static const int SVG_MARKER_ORIENT_AUTO = 1;

  @DomName('SVGMarkerElement.SVG_MARKER_ORIENT_UNKNOWN')
  @DocsEditable()
  static const int SVG_MARKER_ORIENT_UNKNOWN = 0;

  @DomName('SVGMarkerElement.markerHeight')
  @DocsEditable()
  AnimatedLength get markerHeight => _blink.Native_SVGMarkerElement_markerHeight_Getter(this);

  @DomName('SVGMarkerElement.markerUnits')
  @DocsEditable()
  AnimatedEnumeration get markerUnits => _blink.Native_SVGMarkerElement_markerUnits_Getter(this);

  @DomName('SVGMarkerElement.markerWidth')
  @DocsEditable()
  AnimatedLength get markerWidth => _blink.Native_SVGMarkerElement_markerWidth_Getter(this);

  @DomName('SVGMarkerElement.orientAngle')
  @DocsEditable()
  AnimatedAngle get orientAngle => _blink.Native_SVGMarkerElement_orientAngle_Getter(this);

  @DomName('SVGMarkerElement.orientType')
  @DocsEditable()
  AnimatedEnumeration get orientType => _blink.Native_SVGMarkerElement_orientType_Getter(this);

  @DomName('SVGMarkerElement.refX')
  @DocsEditable()
  AnimatedLength get refX => _blink.Native_SVGMarkerElement_refX_Getter(this);

  @DomName('SVGMarkerElement.refY')
  @DocsEditable()
  AnimatedLength get refY => _blink.Native_SVGMarkerElement_refY_Getter(this);

  @DomName('SVGMarkerElement.setOrientToAngle')
  @DocsEditable()
  void setOrientToAngle(Angle angle) => _blink.Native_SVGMarkerElement_setOrientToAngle_Callback(this, angle);

  @DomName('SVGMarkerElement.setOrientToAuto')
  @DocsEditable()
  void setOrientToAuto() => _blink.Native_SVGMarkerElement_setOrientToAuto_Callback(this);

  @DomName('SVGMarkerElement.preserveAspectRatio')
  @DocsEditable()
  AnimatedPreserveAspectRatio get preserveAspectRatio => _blink.Native_SVGMarkerElement_preserveAspectRatio_Getter(this);

  @DomName('SVGMarkerElement.viewBox')
  @DocsEditable()
  AnimatedRect get viewBox => _blink.Native_SVGMarkerElement_viewBox_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGMaskElement')
@Unstable()
class MaskElement extends SvgElement implements Tests {
  // To suppress missing implicit constructor warnings.
  factory MaskElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGMaskElement.SVGMaskElement')
  @DocsEditable()
  factory MaskElement() => _SvgElementFactoryProvider.createSvgElement_tag("mask");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  MaskElement.created() : super.created();

  @DomName('SVGMaskElement.height')
  @DocsEditable()
  AnimatedLength get height => _blink.Native_SVGMaskElement_height_Getter(this);

  @DomName('SVGMaskElement.maskContentUnits')
  @DocsEditable()
  AnimatedEnumeration get maskContentUnits => _blink.Native_SVGMaskElement_maskContentUnits_Getter(this);

  @DomName('SVGMaskElement.maskUnits')
  @DocsEditable()
  AnimatedEnumeration get maskUnits => _blink.Native_SVGMaskElement_maskUnits_Getter(this);

  @DomName('SVGMaskElement.width')
  @DocsEditable()
  AnimatedLength get width => _blink.Native_SVGMaskElement_width_Getter(this);

  @DomName('SVGMaskElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.Native_SVGMaskElement_x_Getter(this);

  @DomName('SVGMaskElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.Native_SVGMaskElement_y_Getter(this);

  @DomName('SVGMaskElement.requiredExtensions')
  @DocsEditable()
  StringList get requiredExtensions => _blink.Native_SVGMaskElement_requiredExtensions_Getter(this);

  @DomName('SVGMaskElement.requiredFeatures')
  @DocsEditable()
  StringList get requiredFeatures => _blink.Native_SVGMaskElement_requiredFeatures_Getter(this);

  @DomName('SVGMaskElement.systemLanguage')
  @DocsEditable()
  StringList get systemLanguage => _blink.Native_SVGMaskElement_systemLanguage_Getter(this);

  @DomName('SVGMaskElement.hasExtension')
  @DocsEditable()
  bool hasExtension(String extension) => _blink.Native_SVGMaskElement_hasExtension_Callback(this, extension);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGMatrix')
@Unstable()
class Matrix extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory Matrix._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGMatrix.a')
  @DocsEditable()
  num get a => _blink.Native_SVGMatrix_a_Getter(this);

  @DomName('SVGMatrix.a')
  @DocsEditable()
  void set a(num value) => _blink.Native_SVGMatrix_a_Setter(this, value);

  @DomName('SVGMatrix.b')
  @DocsEditable()
  num get b => _blink.Native_SVGMatrix_b_Getter(this);

  @DomName('SVGMatrix.b')
  @DocsEditable()
  void set b(num value) => _blink.Native_SVGMatrix_b_Setter(this, value);

  @DomName('SVGMatrix.c')
  @DocsEditable()
  num get c => _blink.Native_SVGMatrix_c_Getter(this);

  @DomName('SVGMatrix.c')
  @DocsEditable()
  void set c(num value) => _blink.Native_SVGMatrix_c_Setter(this, value);

  @DomName('SVGMatrix.d')
  @DocsEditable()
  num get d => _blink.Native_SVGMatrix_d_Getter(this);

  @DomName('SVGMatrix.d')
  @DocsEditable()
  void set d(num value) => _blink.Native_SVGMatrix_d_Setter(this, value);

  @DomName('SVGMatrix.e')
  @DocsEditable()
  num get e => _blink.Native_SVGMatrix_e_Getter(this);

  @DomName('SVGMatrix.e')
  @DocsEditable()
  void set e(num value) => _blink.Native_SVGMatrix_e_Setter(this, value);

  @DomName('SVGMatrix.f')
  @DocsEditable()
  num get f => _blink.Native_SVGMatrix_f_Getter(this);

  @DomName('SVGMatrix.f')
  @DocsEditable()
  void set f(num value) => _blink.Native_SVGMatrix_f_Setter(this, value);

  @DomName('SVGMatrix.flipX')
  @DocsEditable()
  Matrix flipX() => _blink.Native_SVGMatrix_flipX_Callback(this);

  @DomName('SVGMatrix.flipY')
  @DocsEditable()
  Matrix flipY() => _blink.Native_SVGMatrix_flipY_Callback(this);

  @DomName('SVGMatrix.inverse')
  @DocsEditable()
  Matrix inverse() => _blink.Native_SVGMatrix_inverse_Callback(this);

  @DomName('SVGMatrix.multiply')
  @DocsEditable()
  Matrix multiply(Matrix secondMatrix) => _blink.Native_SVGMatrix_multiply_Callback(this, secondMatrix);

  @DomName('SVGMatrix.rotate')
  @DocsEditable()
  Matrix rotate(num angle) => _blink.Native_SVGMatrix_rotate_Callback(this, angle);

  @DomName('SVGMatrix.rotateFromVector')
  @DocsEditable()
  Matrix rotateFromVector(num x, num y) => _blink.Native_SVGMatrix_rotateFromVector_Callback(this, x, y);

  @DomName('SVGMatrix.scale')
  @DocsEditable()
  Matrix scale(num scaleFactor) => _blink.Native_SVGMatrix_scale_Callback(this, scaleFactor);

  @DomName('SVGMatrix.scaleNonUniform')
  @DocsEditable()
  Matrix scaleNonUniform(num scaleFactorX, num scaleFactorY) => _blink.Native_SVGMatrix_scaleNonUniform_Callback(this, scaleFactorX, scaleFactorY);

  @DomName('SVGMatrix.skewX')
  @DocsEditable()
  Matrix skewX(num angle) => _blink.Native_SVGMatrix_skewX_Callback(this, angle);

  @DomName('SVGMatrix.skewY')
  @DocsEditable()
  Matrix skewY(num angle) => _blink.Native_SVGMatrix_skewY_Callback(this, angle);

  @DomName('SVGMatrix.translate')
  @DocsEditable()
  Matrix translate(num x, num y) => _blink.Native_SVGMatrix_translate_Callback(this, x, y);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGMetadataElement')
@Unstable()
class MetadataElement extends SvgElement {
  // To suppress missing implicit constructor warnings.
  factory MetadataElement._() { throw new UnsupportedError("Not supported"); }
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  MetadataElement.created() : super.created();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGNumber')
@Unstable()
class Number extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory Number._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGNumber.value')
  @DocsEditable()
  num get value => _blink.Native_SVGNumber_value_Getter(this);

  @DomName('SVGNumber.value')
  @DocsEditable()
  void set value(num value) => _blink.Native_SVGNumber_value_Setter(this, value);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGNumberList')
@Unstable()
class NumberList extends NativeFieldWrapperClass2 with ListMixin<Number>, ImmutableListMixin<Number> implements List<Number> {
  // To suppress missing implicit constructor warnings.
  factory NumberList._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGNumberList.numberOfItems')
  @DocsEditable()
  int get numberOfItems => _blink.Native_SVGNumberList_numberOfItems_Getter(this);

  Number operator[](int index) {
    if (index < 0 || index >= length)
      throw new RangeError.range(index, 0, length);
    return getItem(index);
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
      return getItem(0);
    }
    throw new StateError("No elements");
  }

  Number get last {
    int len = this.length;
    if (len > 0) {
      return getItem(len - 1);
    }
    throw new StateError("No elements");
  }

  Number get single {
    int len = this.length;
    if (len == 1) {
      return getItem(0);
    }
    if (len == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  Number elementAt(int index) => this[index];
  // -- end List<Number> mixins.

  @DomName('SVGNumberList.appendItem')
  @DocsEditable()
  Number appendItem(Number item) => _blink.Native_SVGNumberList_appendItem_Callback(this, item);

  @DomName('SVGNumberList.clear')
  @DocsEditable()
  void clear() => _blink.Native_SVGNumberList_clear_Callback(this);

  @DomName('SVGNumberList.getItem')
  @DocsEditable()
  Number getItem(int index) => _blink.Native_SVGNumberList_getItem_Callback(this, index);

  @DomName('SVGNumberList.initialize')
  @DocsEditable()
  Number initialize(Number item) => _blink.Native_SVGNumberList_initialize_Callback(this, item);

  @DomName('SVGNumberList.insertItemBefore')
  @DocsEditable()
  Number insertItemBefore(Number item, int index) => _blink.Native_SVGNumberList_insertItemBefore_Callback(this, item, index);

  @DomName('SVGNumberList.removeItem')
  @DocsEditable()
  Number removeItem(int index) => _blink.Native_SVGNumberList_removeItem_Callback(this, index);

  @DomName('SVGNumberList.replaceItem')
  @DocsEditable()
  Number replaceItem(Number item, int index) => _blink.Native_SVGNumberList_replaceItem_Callback(this, item, index);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGPathElement')
@Unstable()
class PathElement extends GeometryElement {
  // To suppress missing implicit constructor warnings.
  factory PathElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathElement.SVGPathElement')
  @DocsEditable()
  factory PathElement() => _SvgElementFactoryProvider.createSvgElement_tag("path");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  PathElement.created() : super.created();

  @DomName('SVGPathElement.animatedNormalizedPathSegList')
  @DocsEditable()
  PathSegList get animatedNormalizedPathSegList => _blink.Native_SVGPathElement_animatedNormalizedPathSegList_Getter(this);

  @DomName('SVGPathElement.animatedPathSegList')
  @DocsEditable()
  PathSegList get animatedPathSegList => _blink.Native_SVGPathElement_animatedPathSegList_Getter(this);

  @DomName('SVGPathElement.normalizedPathSegList')
  @DocsEditable()
  PathSegList get normalizedPathSegList => _blink.Native_SVGPathElement_normalizedPathSegList_Getter(this);

  @DomName('SVGPathElement.pathLength')
  @DocsEditable()
  AnimatedNumber get pathLength => _blink.Native_SVGPathElement_pathLength_Getter(this);

  @DomName('SVGPathElement.pathSegList')
  @DocsEditable()
  PathSegList get pathSegList => _blink.Native_SVGPathElement_pathSegList_Getter(this);

  @DomName('SVGPathElement.createSVGPathSegArcAbs')
  @DocsEditable()
  PathSegArcAbs createSvgPathSegArcAbs(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) => _blink.Native_SVGPathElement_createSVGPathSegArcAbs_Callback(this, x, y, r1, r2, angle, largeArcFlag, sweepFlag);

  @DomName('SVGPathElement.createSVGPathSegArcRel')
  @DocsEditable()
  PathSegArcRel createSvgPathSegArcRel(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) => _blink.Native_SVGPathElement_createSVGPathSegArcRel_Callback(this, x, y, r1, r2, angle, largeArcFlag, sweepFlag);

  @DomName('SVGPathElement.createSVGPathSegClosePath')
  @DocsEditable()
  PathSegClosePath createSvgPathSegClosePath() => _blink.Native_SVGPathElement_createSVGPathSegClosePath_Callback(this);

  @DomName('SVGPathElement.createSVGPathSegCurvetoCubicAbs')
  @DocsEditable()
  PathSegCurvetoCubicAbs createSvgPathSegCurvetoCubicAbs(num x, num y, num x1, num y1, num x2, num y2) => _blink.Native_SVGPathElement_createSVGPathSegCurvetoCubicAbs_Callback(this, x, y, x1, y1, x2, y2);

  @DomName('SVGPathElement.createSVGPathSegCurvetoCubicRel')
  @DocsEditable()
  PathSegCurvetoCubicRel createSvgPathSegCurvetoCubicRel(num x, num y, num x1, num y1, num x2, num y2) => _blink.Native_SVGPathElement_createSVGPathSegCurvetoCubicRel_Callback(this, x, y, x1, y1, x2, y2);

  @DomName('SVGPathElement.createSVGPathSegCurvetoCubicSmoothAbs')
  @DocsEditable()
  PathSegCurvetoCubicSmoothAbs createSvgPathSegCurvetoCubicSmoothAbs(num x, num y, num x2, num y2) => _blink.Native_SVGPathElement_createSVGPathSegCurvetoCubicSmoothAbs_Callback(this, x, y, x2, y2);

  @DomName('SVGPathElement.createSVGPathSegCurvetoCubicSmoothRel')
  @DocsEditable()
  PathSegCurvetoCubicSmoothRel createSvgPathSegCurvetoCubicSmoothRel(num x, num y, num x2, num y2) => _blink.Native_SVGPathElement_createSVGPathSegCurvetoCubicSmoothRel_Callback(this, x, y, x2, y2);

  @DomName('SVGPathElement.createSVGPathSegCurvetoQuadraticAbs')
  @DocsEditable()
  PathSegCurvetoQuadraticAbs createSvgPathSegCurvetoQuadraticAbs(num x, num y, num x1, num y1) => _blink.Native_SVGPathElement_createSVGPathSegCurvetoQuadraticAbs_Callback(this, x, y, x1, y1);

  @DomName('SVGPathElement.createSVGPathSegCurvetoQuadraticRel')
  @DocsEditable()
  PathSegCurvetoQuadraticRel createSvgPathSegCurvetoQuadraticRel(num x, num y, num x1, num y1) => _blink.Native_SVGPathElement_createSVGPathSegCurvetoQuadraticRel_Callback(this, x, y, x1, y1);

  @DomName('SVGPathElement.createSVGPathSegCurvetoQuadraticSmoothAbs')
  @DocsEditable()
  PathSegCurvetoQuadraticSmoothAbs createSvgPathSegCurvetoQuadraticSmoothAbs(num x, num y) => _blink.Native_SVGPathElement_createSVGPathSegCurvetoQuadraticSmoothAbs_Callback(this, x, y);

  @DomName('SVGPathElement.createSVGPathSegCurvetoQuadraticSmoothRel')
  @DocsEditable()
  PathSegCurvetoQuadraticSmoothRel createSvgPathSegCurvetoQuadraticSmoothRel(num x, num y) => _blink.Native_SVGPathElement_createSVGPathSegCurvetoQuadraticSmoothRel_Callback(this, x, y);

  @DomName('SVGPathElement.createSVGPathSegLinetoAbs')
  @DocsEditable()
  PathSegLinetoAbs createSvgPathSegLinetoAbs(num x, num y) => _blink.Native_SVGPathElement_createSVGPathSegLinetoAbs_Callback(this, x, y);

  @DomName('SVGPathElement.createSVGPathSegLinetoHorizontalAbs')
  @DocsEditable()
  PathSegLinetoHorizontalAbs createSvgPathSegLinetoHorizontalAbs(num x) => _blink.Native_SVGPathElement_createSVGPathSegLinetoHorizontalAbs_Callback(this, x);

  @DomName('SVGPathElement.createSVGPathSegLinetoHorizontalRel')
  @DocsEditable()
  PathSegLinetoHorizontalRel createSvgPathSegLinetoHorizontalRel(num x) => _blink.Native_SVGPathElement_createSVGPathSegLinetoHorizontalRel_Callback(this, x);

  @DomName('SVGPathElement.createSVGPathSegLinetoRel')
  @DocsEditable()
  PathSegLinetoRel createSvgPathSegLinetoRel(num x, num y) => _blink.Native_SVGPathElement_createSVGPathSegLinetoRel_Callback(this, x, y);

  @DomName('SVGPathElement.createSVGPathSegLinetoVerticalAbs')
  @DocsEditable()
  PathSegLinetoVerticalAbs createSvgPathSegLinetoVerticalAbs(num y) => _blink.Native_SVGPathElement_createSVGPathSegLinetoVerticalAbs_Callback(this, y);

  @DomName('SVGPathElement.createSVGPathSegLinetoVerticalRel')
  @DocsEditable()
  PathSegLinetoVerticalRel createSvgPathSegLinetoVerticalRel(num y) => _blink.Native_SVGPathElement_createSVGPathSegLinetoVerticalRel_Callback(this, y);

  @DomName('SVGPathElement.createSVGPathSegMovetoAbs')
  @DocsEditable()
  PathSegMovetoAbs createSvgPathSegMovetoAbs(num x, num y) => _blink.Native_SVGPathElement_createSVGPathSegMovetoAbs_Callback(this, x, y);

  @DomName('SVGPathElement.createSVGPathSegMovetoRel')
  @DocsEditable()
  PathSegMovetoRel createSvgPathSegMovetoRel(num x, num y) => _blink.Native_SVGPathElement_createSVGPathSegMovetoRel_Callback(this, x, y);

  @DomName('SVGPathElement.getPathSegAtLength')
  @DocsEditable()
  int getPathSegAtLength(num distance) => _blink.Native_SVGPathElement_getPathSegAtLength_Callback(this, distance);

  @DomName('SVGPathElement.getPointAtLength')
  @DocsEditable()
  Point getPointAtLength(num distance) => _blink.Native_SVGPathElement_getPointAtLength_Callback(this, distance);

  @DomName('SVGPathElement.getTotalLength')
  @DocsEditable()
  double getTotalLength() => _blink.Native_SVGPathElement_getTotalLength_Callback(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGPathSeg')
@Unstable()
class PathSeg extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory PathSeg._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSeg.PATHSEG_ARC_ABS')
  @DocsEditable()
  static const int PATHSEG_ARC_ABS = 10;

  @DomName('SVGPathSeg.PATHSEG_ARC_REL')
  @DocsEditable()
  static const int PATHSEG_ARC_REL = 11;

  @DomName('SVGPathSeg.PATHSEG_CLOSEPATH')
  @DocsEditable()
  static const int PATHSEG_CLOSEPATH = 1;

  @DomName('SVGPathSeg.PATHSEG_CURVETO_CUBIC_ABS')
  @DocsEditable()
  static const int PATHSEG_CURVETO_CUBIC_ABS = 6;

  @DomName('SVGPathSeg.PATHSEG_CURVETO_CUBIC_REL')
  @DocsEditable()
  static const int PATHSEG_CURVETO_CUBIC_REL = 7;

  @DomName('SVGPathSeg.PATHSEG_CURVETO_CUBIC_SMOOTH_ABS')
  @DocsEditable()
  static const int PATHSEG_CURVETO_CUBIC_SMOOTH_ABS = 16;

  @DomName('SVGPathSeg.PATHSEG_CURVETO_CUBIC_SMOOTH_REL')
  @DocsEditable()
  static const int PATHSEG_CURVETO_CUBIC_SMOOTH_REL = 17;

  @DomName('SVGPathSeg.PATHSEG_CURVETO_QUADRATIC_ABS')
  @DocsEditable()
  static const int PATHSEG_CURVETO_QUADRATIC_ABS = 8;

  @DomName('SVGPathSeg.PATHSEG_CURVETO_QUADRATIC_REL')
  @DocsEditable()
  static const int PATHSEG_CURVETO_QUADRATIC_REL = 9;

  @DomName('SVGPathSeg.PATHSEG_CURVETO_QUADRATIC_SMOOTH_ABS')
  @DocsEditable()
  static const int PATHSEG_CURVETO_QUADRATIC_SMOOTH_ABS = 18;

  @DomName('SVGPathSeg.PATHSEG_CURVETO_QUADRATIC_SMOOTH_REL')
  @DocsEditable()
  static const int PATHSEG_CURVETO_QUADRATIC_SMOOTH_REL = 19;

  @DomName('SVGPathSeg.PATHSEG_LINETO_ABS')
  @DocsEditable()
  static const int PATHSEG_LINETO_ABS = 4;

  @DomName('SVGPathSeg.PATHSEG_LINETO_HORIZONTAL_ABS')
  @DocsEditable()
  static const int PATHSEG_LINETO_HORIZONTAL_ABS = 12;

  @DomName('SVGPathSeg.PATHSEG_LINETO_HORIZONTAL_REL')
  @DocsEditable()
  static const int PATHSEG_LINETO_HORIZONTAL_REL = 13;

  @DomName('SVGPathSeg.PATHSEG_LINETO_REL')
  @DocsEditable()
  static const int PATHSEG_LINETO_REL = 5;

  @DomName('SVGPathSeg.PATHSEG_LINETO_VERTICAL_ABS')
  @DocsEditable()
  static const int PATHSEG_LINETO_VERTICAL_ABS = 14;

  @DomName('SVGPathSeg.PATHSEG_LINETO_VERTICAL_REL')
  @DocsEditable()
  static const int PATHSEG_LINETO_VERTICAL_REL = 15;

  @DomName('SVGPathSeg.PATHSEG_MOVETO_ABS')
  @DocsEditable()
  static const int PATHSEG_MOVETO_ABS = 2;

  @DomName('SVGPathSeg.PATHSEG_MOVETO_REL')
  @DocsEditable()
  static const int PATHSEG_MOVETO_REL = 3;

  @DomName('SVGPathSeg.PATHSEG_UNKNOWN')
  @DocsEditable()
  static const int PATHSEG_UNKNOWN = 0;

  @DomName('SVGPathSeg.pathSegType')
  @DocsEditable()
  int get pathSegType => _blink.Native_SVGPathSeg_pathSegType_Getter(this);

  @DomName('SVGPathSeg.pathSegTypeAsLetter')
  @DocsEditable()
  String get pathSegTypeAsLetter => _blink.Native_SVGPathSeg_pathSegTypeAsLetter_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGPathSegArcAbs')
@Unstable()
class PathSegArcAbs extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegArcAbs._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegArcAbs.angle')
  @DocsEditable()
  num get angle => _blink.Native_SVGPathSegArcAbs_angle_Getter(this);

  @DomName('SVGPathSegArcAbs.angle')
  @DocsEditable()
  void set angle(num value) => _blink.Native_SVGPathSegArcAbs_angle_Setter(this, value);

  @DomName('SVGPathSegArcAbs.largeArcFlag')
  @DocsEditable()
  bool get largeArcFlag => _blink.Native_SVGPathSegArcAbs_largeArcFlag_Getter(this);

  @DomName('SVGPathSegArcAbs.largeArcFlag')
  @DocsEditable()
  void set largeArcFlag(bool value) => _blink.Native_SVGPathSegArcAbs_largeArcFlag_Setter(this, value);

  @DomName('SVGPathSegArcAbs.r1')
  @DocsEditable()
  num get r1 => _blink.Native_SVGPathSegArcAbs_r1_Getter(this);

  @DomName('SVGPathSegArcAbs.r1')
  @DocsEditable()
  void set r1(num value) => _blink.Native_SVGPathSegArcAbs_r1_Setter(this, value);

  @DomName('SVGPathSegArcAbs.r2')
  @DocsEditable()
  num get r2 => _blink.Native_SVGPathSegArcAbs_r2_Getter(this);

  @DomName('SVGPathSegArcAbs.r2')
  @DocsEditable()
  void set r2(num value) => _blink.Native_SVGPathSegArcAbs_r2_Setter(this, value);

  @DomName('SVGPathSegArcAbs.sweepFlag')
  @DocsEditable()
  bool get sweepFlag => _blink.Native_SVGPathSegArcAbs_sweepFlag_Getter(this);

  @DomName('SVGPathSegArcAbs.sweepFlag')
  @DocsEditable()
  void set sweepFlag(bool value) => _blink.Native_SVGPathSegArcAbs_sweepFlag_Setter(this, value);

  @DomName('SVGPathSegArcAbs.x')
  @DocsEditable()
  num get x => _blink.Native_SVGPathSegArcAbs_x_Getter(this);

  @DomName('SVGPathSegArcAbs.x')
  @DocsEditable()
  void set x(num value) => _blink.Native_SVGPathSegArcAbs_x_Setter(this, value);

  @DomName('SVGPathSegArcAbs.y')
  @DocsEditable()
  num get y => _blink.Native_SVGPathSegArcAbs_y_Getter(this);

  @DomName('SVGPathSegArcAbs.y')
  @DocsEditable()
  void set y(num value) => _blink.Native_SVGPathSegArcAbs_y_Setter(this, value);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGPathSegArcRel')
@Unstable()
class PathSegArcRel extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegArcRel._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegArcRel.angle')
  @DocsEditable()
  num get angle => _blink.Native_SVGPathSegArcRel_angle_Getter(this);

  @DomName('SVGPathSegArcRel.angle')
  @DocsEditable()
  void set angle(num value) => _blink.Native_SVGPathSegArcRel_angle_Setter(this, value);

  @DomName('SVGPathSegArcRel.largeArcFlag')
  @DocsEditable()
  bool get largeArcFlag => _blink.Native_SVGPathSegArcRel_largeArcFlag_Getter(this);

  @DomName('SVGPathSegArcRel.largeArcFlag')
  @DocsEditable()
  void set largeArcFlag(bool value) => _blink.Native_SVGPathSegArcRel_largeArcFlag_Setter(this, value);

  @DomName('SVGPathSegArcRel.r1')
  @DocsEditable()
  num get r1 => _blink.Native_SVGPathSegArcRel_r1_Getter(this);

  @DomName('SVGPathSegArcRel.r1')
  @DocsEditable()
  void set r1(num value) => _blink.Native_SVGPathSegArcRel_r1_Setter(this, value);

  @DomName('SVGPathSegArcRel.r2')
  @DocsEditable()
  num get r2 => _blink.Native_SVGPathSegArcRel_r2_Getter(this);

  @DomName('SVGPathSegArcRel.r2')
  @DocsEditable()
  void set r2(num value) => _blink.Native_SVGPathSegArcRel_r2_Setter(this, value);

  @DomName('SVGPathSegArcRel.sweepFlag')
  @DocsEditable()
  bool get sweepFlag => _blink.Native_SVGPathSegArcRel_sweepFlag_Getter(this);

  @DomName('SVGPathSegArcRel.sweepFlag')
  @DocsEditable()
  void set sweepFlag(bool value) => _blink.Native_SVGPathSegArcRel_sweepFlag_Setter(this, value);

  @DomName('SVGPathSegArcRel.x')
  @DocsEditable()
  num get x => _blink.Native_SVGPathSegArcRel_x_Getter(this);

  @DomName('SVGPathSegArcRel.x')
  @DocsEditable()
  void set x(num value) => _blink.Native_SVGPathSegArcRel_x_Setter(this, value);

  @DomName('SVGPathSegArcRel.y')
  @DocsEditable()
  num get y => _blink.Native_SVGPathSegArcRel_y_Getter(this);

  @DomName('SVGPathSegArcRel.y')
  @DocsEditable()
  void set y(num value) => _blink.Native_SVGPathSegArcRel_y_Setter(this, value);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGPathSegClosePath')
@Unstable()
class PathSegClosePath extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegClosePath._() { throw new UnsupportedError("Not supported"); }

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGPathSegCurvetoCubicAbs')
@Unstable()
class PathSegCurvetoCubicAbs extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegCurvetoCubicAbs._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegCurvetoCubicAbs.x')
  @DocsEditable()
  num get x => _blink.Native_SVGPathSegCurvetoCubicAbs_x_Getter(this);

  @DomName('SVGPathSegCurvetoCubicAbs.x')
  @DocsEditable()
  void set x(num value) => _blink.Native_SVGPathSegCurvetoCubicAbs_x_Setter(this, value);

  @DomName('SVGPathSegCurvetoCubicAbs.x1')
  @DocsEditable()
  num get x1 => _blink.Native_SVGPathSegCurvetoCubicAbs_x1_Getter(this);

  @DomName('SVGPathSegCurvetoCubicAbs.x1')
  @DocsEditable()
  void set x1(num value) => _blink.Native_SVGPathSegCurvetoCubicAbs_x1_Setter(this, value);

  @DomName('SVGPathSegCurvetoCubicAbs.x2')
  @DocsEditable()
  num get x2 => _blink.Native_SVGPathSegCurvetoCubicAbs_x2_Getter(this);

  @DomName('SVGPathSegCurvetoCubicAbs.x2')
  @DocsEditable()
  void set x2(num value) => _blink.Native_SVGPathSegCurvetoCubicAbs_x2_Setter(this, value);

  @DomName('SVGPathSegCurvetoCubicAbs.y')
  @DocsEditable()
  num get y => _blink.Native_SVGPathSegCurvetoCubicAbs_y_Getter(this);

  @DomName('SVGPathSegCurvetoCubicAbs.y')
  @DocsEditable()
  void set y(num value) => _blink.Native_SVGPathSegCurvetoCubicAbs_y_Setter(this, value);

  @DomName('SVGPathSegCurvetoCubicAbs.y1')
  @DocsEditable()
  num get y1 => _blink.Native_SVGPathSegCurvetoCubicAbs_y1_Getter(this);

  @DomName('SVGPathSegCurvetoCubicAbs.y1')
  @DocsEditable()
  void set y1(num value) => _blink.Native_SVGPathSegCurvetoCubicAbs_y1_Setter(this, value);

  @DomName('SVGPathSegCurvetoCubicAbs.y2')
  @DocsEditable()
  num get y2 => _blink.Native_SVGPathSegCurvetoCubicAbs_y2_Getter(this);

  @DomName('SVGPathSegCurvetoCubicAbs.y2')
  @DocsEditable()
  void set y2(num value) => _blink.Native_SVGPathSegCurvetoCubicAbs_y2_Setter(this, value);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGPathSegCurvetoCubicRel')
@Unstable()
class PathSegCurvetoCubicRel extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegCurvetoCubicRel._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegCurvetoCubicRel.x')
  @DocsEditable()
  num get x => _blink.Native_SVGPathSegCurvetoCubicRel_x_Getter(this);

  @DomName('SVGPathSegCurvetoCubicRel.x')
  @DocsEditable()
  void set x(num value) => _blink.Native_SVGPathSegCurvetoCubicRel_x_Setter(this, value);

  @DomName('SVGPathSegCurvetoCubicRel.x1')
  @DocsEditable()
  num get x1 => _blink.Native_SVGPathSegCurvetoCubicRel_x1_Getter(this);

  @DomName('SVGPathSegCurvetoCubicRel.x1')
  @DocsEditable()
  void set x1(num value) => _blink.Native_SVGPathSegCurvetoCubicRel_x1_Setter(this, value);

  @DomName('SVGPathSegCurvetoCubicRel.x2')
  @DocsEditable()
  num get x2 => _blink.Native_SVGPathSegCurvetoCubicRel_x2_Getter(this);

  @DomName('SVGPathSegCurvetoCubicRel.x2')
  @DocsEditable()
  void set x2(num value) => _blink.Native_SVGPathSegCurvetoCubicRel_x2_Setter(this, value);

  @DomName('SVGPathSegCurvetoCubicRel.y')
  @DocsEditable()
  num get y => _blink.Native_SVGPathSegCurvetoCubicRel_y_Getter(this);

  @DomName('SVGPathSegCurvetoCubicRel.y')
  @DocsEditable()
  void set y(num value) => _blink.Native_SVGPathSegCurvetoCubicRel_y_Setter(this, value);

  @DomName('SVGPathSegCurvetoCubicRel.y1')
  @DocsEditable()
  num get y1 => _blink.Native_SVGPathSegCurvetoCubicRel_y1_Getter(this);

  @DomName('SVGPathSegCurvetoCubicRel.y1')
  @DocsEditable()
  void set y1(num value) => _blink.Native_SVGPathSegCurvetoCubicRel_y1_Setter(this, value);

  @DomName('SVGPathSegCurvetoCubicRel.y2')
  @DocsEditable()
  num get y2 => _blink.Native_SVGPathSegCurvetoCubicRel_y2_Getter(this);

  @DomName('SVGPathSegCurvetoCubicRel.y2')
  @DocsEditable()
  void set y2(num value) => _blink.Native_SVGPathSegCurvetoCubicRel_y2_Setter(this, value);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGPathSegCurvetoCubicSmoothAbs')
@Unstable()
class PathSegCurvetoCubicSmoothAbs extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegCurvetoCubicSmoothAbs._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegCurvetoCubicSmoothAbs.x')
  @DocsEditable()
  num get x => _blink.Native_SVGPathSegCurvetoCubicSmoothAbs_x_Getter(this);

  @DomName('SVGPathSegCurvetoCubicSmoothAbs.x')
  @DocsEditable()
  void set x(num value) => _blink.Native_SVGPathSegCurvetoCubicSmoothAbs_x_Setter(this, value);

  @DomName('SVGPathSegCurvetoCubicSmoothAbs.x2')
  @DocsEditable()
  num get x2 => _blink.Native_SVGPathSegCurvetoCubicSmoothAbs_x2_Getter(this);

  @DomName('SVGPathSegCurvetoCubicSmoothAbs.x2')
  @DocsEditable()
  void set x2(num value) => _blink.Native_SVGPathSegCurvetoCubicSmoothAbs_x2_Setter(this, value);

  @DomName('SVGPathSegCurvetoCubicSmoothAbs.y')
  @DocsEditable()
  num get y => _blink.Native_SVGPathSegCurvetoCubicSmoothAbs_y_Getter(this);

  @DomName('SVGPathSegCurvetoCubicSmoothAbs.y')
  @DocsEditable()
  void set y(num value) => _blink.Native_SVGPathSegCurvetoCubicSmoothAbs_y_Setter(this, value);

  @DomName('SVGPathSegCurvetoCubicSmoothAbs.y2')
  @DocsEditable()
  num get y2 => _blink.Native_SVGPathSegCurvetoCubicSmoothAbs_y2_Getter(this);

  @DomName('SVGPathSegCurvetoCubicSmoothAbs.y2')
  @DocsEditable()
  void set y2(num value) => _blink.Native_SVGPathSegCurvetoCubicSmoothAbs_y2_Setter(this, value);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGPathSegCurvetoCubicSmoothRel')
@Unstable()
class PathSegCurvetoCubicSmoothRel extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegCurvetoCubicSmoothRel._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegCurvetoCubicSmoothRel.x')
  @DocsEditable()
  num get x => _blink.Native_SVGPathSegCurvetoCubicSmoothRel_x_Getter(this);

  @DomName('SVGPathSegCurvetoCubicSmoothRel.x')
  @DocsEditable()
  void set x(num value) => _blink.Native_SVGPathSegCurvetoCubicSmoothRel_x_Setter(this, value);

  @DomName('SVGPathSegCurvetoCubicSmoothRel.x2')
  @DocsEditable()
  num get x2 => _blink.Native_SVGPathSegCurvetoCubicSmoothRel_x2_Getter(this);

  @DomName('SVGPathSegCurvetoCubicSmoothRel.x2')
  @DocsEditable()
  void set x2(num value) => _blink.Native_SVGPathSegCurvetoCubicSmoothRel_x2_Setter(this, value);

  @DomName('SVGPathSegCurvetoCubicSmoothRel.y')
  @DocsEditable()
  num get y => _blink.Native_SVGPathSegCurvetoCubicSmoothRel_y_Getter(this);

  @DomName('SVGPathSegCurvetoCubicSmoothRel.y')
  @DocsEditable()
  void set y(num value) => _blink.Native_SVGPathSegCurvetoCubicSmoothRel_y_Setter(this, value);

  @DomName('SVGPathSegCurvetoCubicSmoothRel.y2')
  @DocsEditable()
  num get y2 => _blink.Native_SVGPathSegCurvetoCubicSmoothRel_y2_Getter(this);

  @DomName('SVGPathSegCurvetoCubicSmoothRel.y2')
  @DocsEditable()
  void set y2(num value) => _blink.Native_SVGPathSegCurvetoCubicSmoothRel_y2_Setter(this, value);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGPathSegCurvetoQuadraticAbs')
@Unstable()
class PathSegCurvetoQuadraticAbs extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegCurvetoQuadraticAbs._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegCurvetoQuadraticAbs.x')
  @DocsEditable()
  num get x => _blink.Native_SVGPathSegCurvetoQuadraticAbs_x_Getter(this);

  @DomName('SVGPathSegCurvetoQuadraticAbs.x')
  @DocsEditable()
  void set x(num value) => _blink.Native_SVGPathSegCurvetoQuadraticAbs_x_Setter(this, value);

  @DomName('SVGPathSegCurvetoQuadraticAbs.x1')
  @DocsEditable()
  num get x1 => _blink.Native_SVGPathSegCurvetoQuadraticAbs_x1_Getter(this);

  @DomName('SVGPathSegCurvetoQuadraticAbs.x1')
  @DocsEditable()
  void set x1(num value) => _blink.Native_SVGPathSegCurvetoQuadraticAbs_x1_Setter(this, value);

  @DomName('SVGPathSegCurvetoQuadraticAbs.y')
  @DocsEditable()
  num get y => _blink.Native_SVGPathSegCurvetoQuadraticAbs_y_Getter(this);

  @DomName('SVGPathSegCurvetoQuadraticAbs.y')
  @DocsEditable()
  void set y(num value) => _blink.Native_SVGPathSegCurvetoQuadraticAbs_y_Setter(this, value);

  @DomName('SVGPathSegCurvetoQuadraticAbs.y1')
  @DocsEditable()
  num get y1 => _blink.Native_SVGPathSegCurvetoQuadraticAbs_y1_Getter(this);

  @DomName('SVGPathSegCurvetoQuadraticAbs.y1')
  @DocsEditable()
  void set y1(num value) => _blink.Native_SVGPathSegCurvetoQuadraticAbs_y1_Setter(this, value);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGPathSegCurvetoQuadraticRel')
@Unstable()
class PathSegCurvetoQuadraticRel extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegCurvetoQuadraticRel._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegCurvetoQuadraticRel.x')
  @DocsEditable()
  num get x => _blink.Native_SVGPathSegCurvetoQuadraticRel_x_Getter(this);

  @DomName('SVGPathSegCurvetoQuadraticRel.x')
  @DocsEditable()
  void set x(num value) => _blink.Native_SVGPathSegCurvetoQuadraticRel_x_Setter(this, value);

  @DomName('SVGPathSegCurvetoQuadraticRel.x1')
  @DocsEditable()
  num get x1 => _blink.Native_SVGPathSegCurvetoQuadraticRel_x1_Getter(this);

  @DomName('SVGPathSegCurvetoQuadraticRel.x1')
  @DocsEditable()
  void set x1(num value) => _blink.Native_SVGPathSegCurvetoQuadraticRel_x1_Setter(this, value);

  @DomName('SVGPathSegCurvetoQuadraticRel.y')
  @DocsEditable()
  num get y => _blink.Native_SVGPathSegCurvetoQuadraticRel_y_Getter(this);

  @DomName('SVGPathSegCurvetoQuadraticRel.y')
  @DocsEditable()
  void set y(num value) => _blink.Native_SVGPathSegCurvetoQuadraticRel_y_Setter(this, value);

  @DomName('SVGPathSegCurvetoQuadraticRel.y1')
  @DocsEditable()
  num get y1 => _blink.Native_SVGPathSegCurvetoQuadraticRel_y1_Getter(this);

  @DomName('SVGPathSegCurvetoQuadraticRel.y1')
  @DocsEditable()
  void set y1(num value) => _blink.Native_SVGPathSegCurvetoQuadraticRel_y1_Setter(this, value);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGPathSegCurvetoQuadraticSmoothAbs')
@Unstable()
class PathSegCurvetoQuadraticSmoothAbs extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegCurvetoQuadraticSmoothAbs._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegCurvetoQuadraticSmoothAbs.x')
  @DocsEditable()
  num get x => _blink.Native_SVGPathSegCurvetoQuadraticSmoothAbs_x_Getter(this);

  @DomName('SVGPathSegCurvetoQuadraticSmoothAbs.x')
  @DocsEditable()
  void set x(num value) => _blink.Native_SVGPathSegCurvetoQuadraticSmoothAbs_x_Setter(this, value);

  @DomName('SVGPathSegCurvetoQuadraticSmoothAbs.y')
  @DocsEditable()
  num get y => _blink.Native_SVGPathSegCurvetoQuadraticSmoothAbs_y_Getter(this);

  @DomName('SVGPathSegCurvetoQuadraticSmoothAbs.y')
  @DocsEditable()
  void set y(num value) => _blink.Native_SVGPathSegCurvetoQuadraticSmoothAbs_y_Setter(this, value);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGPathSegCurvetoQuadraticSmoothRel')
@Unstable()
class PathSegCurvetoQuadraticSmoothRel extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegCurvetoQuadraticSmoothRel._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegCurvetoQuadraticSmoothRel.x')
  @DocsEditable()
  num get x => _blink.Native_SVGPathSegCurvetoQuadraticSmoothRel_x_Getter(this);

  @DomName('SVGPathSegCurvetoQuadraticSmoothRel.x')
  @DocsEditable()
  void set x(num value) => _blink.Native_SVGPathSegCurvetoQuadraticSmoothRel_x_Setter(this, value);

  @DomName('SVGPathSegCurvetoQuadraticSmoothRel.y')
  @DocsEditable()
  num get y => _blink.Native_SVGPathSegCurvetoQuadraticSmoothRel_y_Getter(this);

  @DomName('SVGPathSegCurvetoQuadraticSmoothRel.y')
  @DocsEditable()
  void set y(num value) => _blink.Native_SVGPathSegCurvetoQuadraticSmoothRel_y_Setter(this, value);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGPathSegLinetoAbs')
@Unstable()
class PathSegLinetoAbs extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegLinetoAbs._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegLinetoAbs.x')
  @DocsEditable()
  num get x => _blink.Native_SVGPathSegLinetoAbs_x_Getter(this);

  @DomName('SVGPathSegLinetoAbs.x')
  @DocsEditable()
  void set x(num value) => _blink.Native_SVGPathSegLinetoAbs_x_Setter(this, value);

  @DomName('SVGPathSegLinetoAbs.y')
  @DocsEditable()
  num get y => _blink.Native_SVGPathSegLinetoAbs_y_Getter(this);

  @DomName('SVGPathSegLinetoAbs.y')
  @DocsEditable()
  void set y(num value) => _blink.Native_SVGPathSegLinetoAbs_y_Setter(this, value);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGPathSegLinetoHorizontalAbs')
@Unstable()
class PathSegLinetoHorizontalAbs extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegLinetoHorizontalAbs._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegLinetoHorizontalAbs.x')
  @DocsEditable()
  num get x => _blink.Native_SVGPathSegLinetoHorizontalAbs_x_Getter(this);

  @DomName('SVGPathSegLinetoHorizontalAbs.x')
  @DocsEditable()
  void set x(num value) => _blink.Native_SVGPathSegLinetoHorizontalAbs_x_Setter(this, value);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGPathSegLinetoHorizontalRel')
@Unstable()
class PathSegLinetoHorizontalRel extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegLinetoHorizontalRel._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegLinetoHorizontalRel.x')
  @DocsEditable()
  num get x => _blink.Native_SVGPathSegLinetoHorizontalRel_x_Getter(this);

  @DomName('SVGPathSegLinetoHorizontalRel.x')
  @DocsEditable()
  void set x(num value) => _blink.Native_SVGPathSegLinetoHorizontalRel_x_Setter(this, value);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGPathSegLinetoRel')
@Unstable()
class PathSegLinetoRel extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegLinetoRel._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegLinetoRel.x')
  @DocsEditable()
  num get x => _blink.Native_SVGPathSegLinetoRel_x_Getter(this);

  @DomName('SVGPathSegLinetoRel.x')
  @DocsEditable()
  void set x(num value) => _blink.Native_SVGPathSegLinetoRel_x_Setter(this, value);

  @DomName('SVGPathSegLinetoRel.y')
  @DocsEditable()
  num get y => _blink.Native_SVGPathSegLinetoRel_y_Getter(this);

  @DomName('SVGPathSegLinetoRel.y')
  @DocsEditable()
  void set y(num value) => _blink.Native_SVGPathSegLinetoRel_y_Setter(this, value);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGPathSegLinetoVerticalAbs')
@Unstable()
class PathSegLinetoVerticalAbs extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegLinetoVerticalAbs._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegLinetoVerticalAbs.y')
  @DocsEditable()
  num get y => _blink.Native_SVGPathSegLinetoVerticalAbs_y_Getter(this);

  @DomName('SVGPathSegLinetoVerticalAbs.y')
  @DocsEditable()
  void set y(num value) => _blink.Native_SVGPathSegLinetoVerticalAbs_y_Setter(this, value);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGPathSegLinetoVerticalRel')
@Unstable()
class PathSegLinetoVerticalRel extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegLinetoVerticalRel._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegLinetoVerticalRel.y')
  @DocsEditable()
  num get y => _blink.Native_SVGPathSegLinetoVerticalRel_y_Getter(this);

  @DomName('SVGPathSegLinetoVerticalRel.y')
  @DocsEditable()
  void set y(num value) => _blink.Native_SVGPathSegLinetoVerticalRel_y_Setter(this, value);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGPathSegList')
@Unstable()
class PathSegList extends NativeFieldWrapperClass2 with ListMixin<PathSeg>, ImmutableListMixin<PathSeg> implements List<PathSeg> {
  // To suppress missing implicit constructor warnings.
  factory PathSegList._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegList.numberOfItems')
  @DocsEditable()
  int get numberOfItems => _blink.Native_SVGPathSegList_numberOfItems_Getter(this);

  PathSeg operator[](int index) {
    if (index < 0 || index >= length)
      throw new RangeError.range(index, 0, length);
    return getItem(index);
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
      return getItem(0);
    }
    throw new StateError("No elements");
  }

  PathSeg get last {
    int len = this.length;
    if (len > 0) {
      return getItem(len - 1);
    }
    throw new StateError("No elements");
  }

  PathSeg get single {
    int len = this.length;
    if (len == 1) {
      return getItem(0);
    }
    if (len == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  PathSeg elementAt(int index) => this[index];
  // -- end List<PathSeg> mixins.

  @DomName('SVGPathSegList.appendItem')
  @DocsEditable()
  PathSeg appendItem(PathSeg newItem) => _blink.Native_SVGPathSegList_appendItem_Callback(this, newItem);

  @DomName('SVGPathSegList.clear')
  @DocsEditable()
  void clear() => _blink.Native_SVGPathSegList_clear_Callback(this);

  @DomName('SVGPathSegList.getItem')
  @DocsEditable()
  PathSeg getItem(int index) => _blink.Native_SVGPathSegList_getItem_Callback(this, index);

  @DomName('SVGPathSegList.initialize')
  @DocsEditable()
  PathSeg initialize(PathSeg newItem) => _blink.Native_SVGPathSegList_initialize_Callback(this, newItem);

  @DomName('SVGPathSegList.insertItemBefore')
  @DocsEditable()
  PathSeg insertItemBefore(PathSeg newItem, int index) => _blink.Native_SVGPathSegList_insertItemBefore_Callback(this, newItem, index);

  @DomName('SVGPathSegList.removeItem')
  @DocsEditable()
  PathSeg removeItem(int index) => _blink.Native_SVGPathSegList_removeItem_Callback(this, index);

  @DomName('SVGPathSegList.replaceItem')
  @DocsEditable()
  PathSeg replaceItem(PathSeg newItem, int index) => _blink.Native_SVGPathSegList_replaceItem_Callback(this, newItem, index);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGPathSegMovetoAbs')
@Unstable()
class PathSegMovetoAbs extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegMovetoAbs._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegMovetoAbs.x')
  @DocsEditable()
  num get x => _blink.Native_SVGPathSegMovetoAbs_x_Getter(this);

  @DomName('SVGPathSegMovetoAbs.x')
  @DocsEditable()
  void set x(num value) => _blink.Native_SVGPathSegMovetoAbs_x_Setter(this, value);

  @DomName('SVGPathSegMovetoAbs.y')
  @DocsEditable()
  num get y => _blink.Native_SVGPathSegMovetoAbs_y_Getter(this);

  @DomName('SVGPathSegMovetoAbs.y')
  @DocsEditable()
  void set y(num value) => _blink.Native_SVGPathSegMovetoAbs_y_Setter(this, value);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGPathSegMovetoRel')
@Unstable()
class PathSegMovetoRel extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegMovetoRel._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegMovetoRel.x')
  @DocsEditable()
  num get x => _blink.Native_SVGPathSegMovetoRel_x_Getter(this);

  @DomName('SVGPathSegMovetoRel.x')
  @DocsEditable()
  void set x(num value) => _blink.Native_SVGPathSegMovetoRel_x_Setter(this, value);

  @DomName('SVGPathSegMovetoRel.y')
  @DocsEditable()
  num get y => _blink.Native_SVGPathSegMovetoRel_y_Getter(this);

  @DomName('SVGPathSegMovetoRel.y')
  @DocsEditable()
  void set y(num value) => _blink.Native_SVGPathSegMovetoRel_y_Setter(this, value);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGPatternElement')
@Unstable()
class PatternElement extends SvgElement implements FitToViewBox, UriReference, Tests {
  // To suppress missing implicit constructor warnings.
  factory PatternElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPatternElement.SVGPatternElement')
  @DocsEditable()
  factory PatternElement() => _SvgElementFactoryProvider.createSvgElement_tag("pattern");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  PatternElement.created() : super.created();

  @DomName('SVGPatternElement.height')
  @DocsEditable()
  AnimatedLength get height => _blink.Native_SVGPatternElement_height_Getter(this);

  @DomName('SVGPatternElement.patternContentUnits')
  @DocsEditable()
  AnimatedEnumeration get patternContentUnits => _blink.Native_SVGPatternElement_patternContentUnits_Getter(this);

  @DomName('SVGPatternElement.patternTransform')
  @DocsEditable()
  AnimatedTransformList get patternTransform => _blink.Native_SVGPatternElement_patternTransform_Getter(this);

  @DomName('SVGPatternElement.patternUnits')
  @DocsEditable()
  AnimatedEnumeration get patternUnits => _blink.Native_SVGPatternElement_patternUnits_Getter(this);

  @DomName('SVGPatternElement.width')
  @DocsEditable()
  AnimatedLength get width => _blink.Native_SVGPatternElement_width_Getter(this);

  @DomName('SVGPatternElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.Native_SVGPatternElement_x_Getter(this);

  @DomName('SVGPatternElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.Native_SVGPatternElement_y_Getter(this);

  @DomName('SVGPatternElement.preserveAspectRatio')
  @DocsEditable()
  AnimatedPreserveAspectRatio get preserveAspectRatio => _blink.Native_SVGPatternElement_preserveAspectRatio_Getter(this);

  @DomName('SVGPatternElement.viewBox')
  @DocsEditable()
  AnimatedRect get viewBox => _blink.Native_SVGPatternElement_viewBox_Getter(this);

  @DomName('SVGPatternElement.requiredExtensions')
  @DocsEditable()
  StringList get requiredExtensions => _blink.Native_SVGPatternElement_requiredExtensions_Getter(this);

  @DomName('SVGPatternElement.requiredFeatures')
  @DocsEditable()
  StringList get requiredFeatures => _blink.Native_SVGPatternElement_requiredFeatures_Getter(this);

  @DomName('SVGPatternElement.systemLanguage')
  @DocsEditable()
  StringList get systemLanguage => _blink.Native_SVGPatternElement_systemLanguage_Getter(this);

  @DomName('SVGPatternElement.hasExtension')
  @DocsEditable()
  bool hasExtension(String extension) => _blink.Native_SVGPatternElement_hasExtension_Callback(this, extension);

  @DomName('SVGPatternElement.href')
  @DocsEditable()
  AnimatedString get href => _blink.Native_SVGPatternElement_href_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGPoint')
@Unstable()
class Point extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory Point._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPoint.x')
  @DocsEditable()
  num get x => _blink.Native_SVGPoint_x_Getter(this);

  @DomName('SVGPoint.x')
  @DocsEditable()
  void set x(num value) => _blink.Native_SVGPoint_x_Setter(this, value);

  @DomName('SVGPoint.y')
  @DocsEditable()
  num get y => _blink.Native_SVGPoint_y_Getter(this);

  @DomName('SVGPoint.y')
  @DocsEditable()
  void set y(num value) => _blink.Native_SVGPoint_y_Setter(this, value);

  @DomName('SVGPoint.matrixTransform')
  @DocsEditable()
  Point matrixTransform(Matrix matrix) => _blink.Native_SVGPoint_matrixTransform_Callback(this, matrix);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGPointList')
@Unstable()
class PointList extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory PointList._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPointList.numberOfItems')
  @DocsEditable()
  int get numberOfItems => _blink.Native_SVGPointList_numberOfItems_Getter(this);

  @DomName('SVGPointList.appendItem')
  @DocsEditable()
  Point appendItem(Point item) => _blink.Native_SVGPointList_appendItem_Callback(this, item);

  @DomName('SVGPointList.clear')
  @DocsEditable()
  void clear() => _blink.Native_SVGPointList_clear_Callback(this);

  @DomName('SVGPointList.getItem')
  @DocsEditable()
  Point getItem(int index) => _blink.Native_SVGPointList_getItem_Callback(this, index);

  @DomName('SVGPointList.initialize')
  @DocsEditable()
  Point initialize(Point item) => _blink.Native_SVGPointList_initialize_Callback(this, item);

  @DomName('SVGPointList.insertItemBefore')
  @DocsEditable()
  Point insertItemBefore(Point item, int index) => _blink.Native_SVGPointList_insertItemBefore_Callback(this, item, index);

  @DomName('SVGPointList.removeItem')
  @DocsEditable()
  Point removeItem(int index) => _blink.Native_SVGPointList_removeItem_Callback(this, index);

  @DomName('SVGPointList.replaceItem')
  @DocsEditable()
  Point replaceItem(Point item, int index) => _blink.Native_SVGPointList_replaceItem_Callback(this, item, index);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGPolygonElement')
@Unstable()
class PolygonElement extends GeometryElement {
  // To suppress missing implicit constructor warnings.
  factory PolygonElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPolygonElement.SVGPolygonElement')
  @DocsEditable()
  factory PolygonElement() => _SvgElementFactoryProvider.createSvgElement_tag("polygon");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  PolygonElement.created() : super.created();

  @DomName('SVGPolygonElement.animatedPoints')
  @DocsEditable()
  PointList get animatedPoints => _blink.Native_SVGPolygonElement_animatedPoints_Getter(this);

  @DomName('SVGPolygonElement.points')
  @DocsEditable()
  PointList get points => _blink.Native_SVGPolygonElement_points_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGPolylineElement')
@Unstable()
class PolylineElement extends GeometryElement {
  // To suppress missing implicit constructor warnings.
  factory PolylineElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPolylineElement.SVGPolylineElement')
  @DocsEditable()
  factory PolylineElement() => _SvgElementFactoryProvider.createSvgElement_tag("polyline");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  PolylineElement.created() : super.created();

  @DomName('SVGPolylineElement.animatedPoints')
  @DocsEditable()
  PointList get animatedPoints => _blink.Native_SVGPolylineElement_animatedPoints_Getter(this);

  @DomName('SVGPolylineElement.points')
  @DocsEditable()
  PointList get points => _blink.Native_SVGPolylineElement_points_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGPreserveAspectRatio')
@Unstable()
class PreserveAspectRatio extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory PreserveAspectRatio._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPreserveAspectRatio.SVG_MEETORSLICE_MEET')
  @DocsEditable()
  static const int SVG_MEETORSLICE_MEET = 1;

  @DomName('SVGPreserveAspectRatio.SVG_MEETORSLICE_SLICE')
  @DocsEditable()
  static const int SVG_MEETORSLICE_SLICE = 2;

  @DomName('SVGPreserveAspectRatio.SVG_MEETORSLICE_UNKNOWN')
  @DocsEditable()
  static const int SVG_MEETORSLICE_UNKNOWN = 0;

  @DomName('SVGPreserveAspectRatio.SVG_PRESERVEASPECTRATIO_NONE')
  @DocsEditable()
  static const int SVG_PRESERVEASPECTRATIO_NONE = 1;

  @DomName('SVGPreserveAspectRatio.SVG_PRESERVEASPECTRATIO_UNKNOWN')
  @DocsEditable()
  static const int SVG_PRESERVEASPECTRATIO_UNKNOWN = 0;

  @DomName('SVGPreserveAspectRatio.SVG_PRESERVEASPECTRATIO_XMAXYMAX')
  @DocsEditable()
  static const int SVG_PRESERVEASPECTRATIO_XMAXYMAX = 10;

  @DomName('SVGPreserveAspectRatio.SVG_PRESERVEASPECTRATIO_XMAXYMID')
  @DocsEditable()
  static const int SVG_PRESERVEASPECTRATIO_XMAXYMID = 7;

  @DomName('SVGPreserveAspectRatio.SVG_PRESERVEASPECTRATIO_XMAXYMIN')
  @DocsEditable()
  static const int SVG_PRESERVEASPECTRATIO_XMAXYMIN = 4;

  @DomName('SVGPreserveAspectRatio.SVG_PRESERVEASPECTRATIO_XMIDYMAX')
  @DocsEditable()
  static const int SVG_PRESERVEASPECTRATIO_XMIDYMAX = 9;

  @DomName('SVGPreserveAspectRatio.SVG_PRESERVEASPECTRATIO_XMIDYMID')
  @DocsEditable()
  static const int SVG_PRESERVEASPECTRATIO_XMIDYMID = 6;

  @DomName('SVGPreserveAspectRatio.SVG_PRESERVEASPECTRATIO_XMIDYMIN')
  @DocsEditable()
  static const int SVG_PRESERVEASPECTRATIO_XMIDYMIN = 3;

  @DomName('SVGPreserveAspectRatio.SVG_PRESERVEASPECTRATIO_XMINYMAX')
  @DocsEditable()
  static const int SVG_PRESERVEASPECTRATIO_XMINYMAX = 8;

  @DomName('SVGPreserveAspectRatio.SVG_PRESERVEASPECTRATIO_XMINYMID')
  @DocsEditable()
  static const int SVG_PRESERVEASPECTRATIO_XMINYMID = 5;

  @DomName('SVGPreserveAspectRatio.SVG_PRESERVEASPECTRATIO_XMINYMIN')
  @DocsEditable()
  static const int SVG_PRESERVEASPECTRATIO_XMINYMIN = 2;

  @DomName('SVGPreserveAspectRatio.align')
  @DocsEditable()
  int get align => _blink.Native_SVGPreserveAspectRatio_align_Getter(this);

  @DomName('SVGPreserveAspectRatio.align')
  @DocsEditable()
  void set align(int value) => _blink.Native_SVGPreserveAspectRatio_align_Setter(this, value);

  @DomName('SVGPreserveAspectRatio.meetOrSlice')
  @DocsEditable()
  int get meetOrSlice => _blink.Native_SVGPreserveAspectRatio_meetOrSlice_Getter(this);

  @DomName('SVGPreserveAspectRatio.meetOrSlice')
  @DocsEditable()
  void set meetOrSlice(int value) => _blink.Native_SVGPreserveAspectRatio_meetOrSlice_Setter(this, value);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGRadialGradientElement')
@Unstable()
class RadialGradientElement extends _GradientElement {
  // To suppress missing implicit constructor warnings.
  factory RadialGradientElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGRadialGradientElement.SVGRadialGradientElement')
  @DocsEditable()
  factory RadialGradientElement() => _SvgElementFactoryProvider.createSvgElement_tag("radialGradient");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  RadialGradientElement.created() : super.created();

  @DomName('SVGRadialGradientElement.cx')
  @DocsEditable()
  AnimatedLength get cx => _blink.Native_SVGRadialGradientElement_cx_Getter(this);

  @DomName('SVGRadialGradientElement.cy')
  @DocsEditable()
  AnimatedLength get cy => _blink.Native_SVGRadialGradientElement_cy_Getter(this);

  @DomName('SVGRadialGradientElement.fr')
  @DocsEditable()
  AnimatedLength get fr => _blink.Native_SVGRadialGradientElement_fr_Getter(this);

  @DomName('SVGRadialGradientElement.fx')
  @DocsEditable()
  AnimatedLength get fx => _blink.Native_SVGRadialGradientElement_fx_Getter(this);

  @DomName('SVGRadialGradientElement.fy')
  @DocsEditable()
  AnimatedLength get fy => _blink.Native_SVGRadialGradientElement_fy_Getter(this);

  @DomName('SVGRadialGradientElement.r')
  @DocsEditable()
  AnimatedLength get r => _blink.Native_SVGRadialGradientElement_r_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGRect')
@Unstable()
class Rect extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory Rect._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGRect.height')
  @DocsEditable()
  num get height => _blink.Native_SVGRect_height_Getter(this);

  @DomName('SVGRect.height')
  @DocsEditable()
  void set height(num value) => _blink.Native_SVGRect_height_Setter(this, value);

  @DomName('SVGRect.width')
  @DocsEditable()
  num get width => _blink.Native_SVGRect_width_Getter(this);

  @DomName('SVGRect.width')
  @DocsEditable()
  void set width(num value) => _blink.Native_SVGRect_width_Setter(this, value);

  @DomName('SVGRect.x')
  @DocsEditable()
  num get x => _blink.Native_SVGRect_x_Getter(this);

  @DomName('SVGRect.x')
  @DocsEditable()
  void set x(num value) => _blink.Native_SVGRect_x_Setter(this, value);

  @DomName('SVGRect.y')
  @DocsEditable()
  num get y => _blink.Native_SVGRect_y_Getter(this);

  @DomName('SVGRect.y')
  @DocsEditable()
  void set y(num value) => _blink.Native_SVGRect_y_Setter(this, value);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGRectElement')
@Unstable()
class RectElement extends GeometryElement {
  // To suppress missing implicit constructor warnings.
  factory RectElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGRectElement.SVGRectElement')
  @DocsEditable()
  factory RectElement() => _SvgElementFactoryProvider.createSvgElement_tag("rect");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  RectElement.created() : super.created();

  @DomName('SVGRectElement.height')
  @DocsEditable()
  AnimatedLength get height => _blink.Native_SVGRectElement_height_Getter(this);

  @DomName('SVGRectElement.rx')
  @DocsEditable()
  AnimatedLength get rx => _blink.Native_SVGRectElement_rx_Getter(this);

  @DomName('SVGRectElement.ry')
  @DocsEditable()
  AnimatedLength get ry => _blink.Native_SVGRectElement_ry_Getter(this);

  @DomName('SVGRectElement.width')
  @DocsEditable()
  AnimatedLength get width => _blink.Native_SVGRectElement_width_Getter(this);

  @DomName('SVGRectElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.Native_SVGRectElement_x_Getter(this);

  @DomName('SVGRectElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.Native_SVGRectElement_y_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGRenderingIntent')
@Unstable()
class RenderingIntent extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory RenderingIntent._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGRenderingIntent.RENDERING_INTENT_ABSOLUTE_COLORIMETRIC')
  @DocsEditable()
  static const int RENDERING_INTENT_ABSOLUTE_COLORIMETRIC = 5;

  @DomName('SVGRenderingIntent.RENDERING_INTENT_AUTO')
  @DocsEditable()
  static const int RENDERING_INTENT_AUTO = 1;

  @DomName('SVGRenderingIntent.RENDERING_INTENT_PERCEPTUAL')
  @DocsEditable()
  static const int RENDERING_INTENT_PERCEPTUAL = 2;

  @DomName('SVGRenderingIntent.RENDERING_INTENT_RELATIVE_COLORIMETRIC')
  @DocsEditable()
  static const int RENDERING_INTENT_RELATIVE_COLORIMETRIC = 3;

  @DomName('SVGRenderingIntent.RENDERING_INTENT_SATURATION')
  @DocsEditable()
  static const int RENDERING_INTENT_SATURATION = 4;

  @DomName('SVGRenderingIntent.RENDERING_INTENT_UNKNOWN')
  @DocsEditable()
  static const int RENDERING_INTENT_UNKNOWN = 0;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGScriptElement')
@Unstable()
class ScriptElement extends SvgElement implements UriReference {
  // To suppress missing implicit constructor warnings.
  factory ScriptElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGScriptElement.SVGScriptElement')
  @DocsEditable()
  factory ScriptElement() => _SvgElementFactoryProvider.createSvgElement_tag("script");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  ScriptElement.created() : super.created();

  @DomName('SVGScriptElement.type')
  @DocsEditable()
  String get type => _blink.Native_SVGScriptElement_type_Getter(this);

  @DomName('SVGScriptElement.type')
  @DocsEditable()
  void set type(String value) => _blink.Native_SVGScriptElement_type_Setter(this, value);

  @DomName('SVGScriptElement.href')
  @DocsEditable()
  AnimatedString get href => _blink.Native_SVGScriptElement_href_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGSetElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class SetElement extends AnimationElement {
  // To suppress missing implicit constructor warnings.
  factory SetElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGSetElement.SVGSetElement')
  @DocsEditable()
  factory SetElement() => _SvgElementFactoryProvider.createSvgElement_tag("set");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  SetElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGStopElement')
@Unstable()
class StopElement extends SvgElement {
  // To suppress missing implicit constructor warnings.
  factory StopElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGStopElement.SVGStopElement')
  @DocsEditable()
  factory StopElement() => _SvgElementFactoryProvider.createSvgElement_tag("stop");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  StopElement.created() : super.created();

  @DomName('SVGStopElement.offset')
  @DocsEditable()
  AnimatedNumber get gradientOffset => _blink.Native_SVGStopElement_offset_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGStringList')
@Unstable()
class StringList extends NativeFieldWrapperClass2 with ListMixin<String>, ImmutableListMixin<String> implements List<String> {
  // To suppress missing implicit constructor warnings.
  factory StringList._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGStringList.numberOfItems')
  @DocsEditable()
  int get numberOfItems => _blink.Native_SVGStringList_numberOfItems_Getter(this);

  String operator[](int index) {
    if (index < 0 || index >= length)
      throw new RangeError.range(index, 0, length);
    return getItem(index);
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
      return getItem(0);
    }
    throw new StateError("No elements");
  }

  String get last {
    int len = this.length;
    if (len > 0) {
      return getItem(len - 1);
    }
    throw new StateError("No elements");
  }

  String get single {
    int len = this.length;
    if (len == 1) {
      return getItem(0);
    }
    if (len == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  String elementAt(int index) => this[index];
  // -- end List<String> mixins.

  @DomName('SVGStringList.appendItem')
  @DocsEditable()
  String appendItem(String item) => _blink.Native_SVGStringList_appendItem_Callback(this, item);

  @DomName('SVGStringList.clear')
  @DocsEditable()
  void clear() => _blink.Native_SVGStringList_clear_Callback(this);

  @DomName('SVGStringList.getItem')
  @DocsEditable()
  String getItem(int index) => _blink.Native_SVGStringList_getItem_Callback(this, index);

  @DomName('SVGStringList.initialize')
  @DocsEditable()
  String initialize(String item) => _blink.Native_SVGStringList_initialize_Callback(this, item);

  @DomName('SVGStringList.insertItemBefore')
  @DocsEditable()
  String insertItemBefore(String item, int index) => _blink.Native_SVGStringList_insertItemBefore_Callback(this, item, index);

  @DomName('SVGStringList.removeItem')
  @DocsEditable()
  String removeItem(int index) => _blink.Native_SVGStringList_removeItem_Callback(this, index);

  @DomName('SVGStringList.replaceItem')
  @DocsEditable()
  String replaceItem(String item, int index) => _blink.Native_SVGStringList_replaceItem_Callback(this, item, index);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGStyleElement')
// http://www.w3.org/TR/SVG/types.html#InterfaceSVGStylable
@Experimental() // nonstandard
class StyleElement extends SvgElement {
  // To suppress missing implicit constructor warnings.
  factory StyleElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGStyleElement.SVGStyleElement')
  @DocsEditable()
  factory StyleElement() => _SvgElementFactoryProvider.createSvgElement_tag("style");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  StyleElement.created() : super.created();

  @DomName('SVGStyleElement.disabled')
  @DocsEditable()
  bool get disabled => _blink.Native_SVGStyleElement_disabled_Getter(this);

  @DomName('SVGStyleElement.disabled')
  @DocsEditable()
  void set disabled(bool value) => _blink.Native_SVGStyleElement_disabled_Setter(this, value);

  @DomName('SVGStyleElement.media')
  @DocsEditable()
  String get media => _blink.Native_SVGStyleElement_media_Getter(this);

  @DomName('SVGStyleElement.media')
  @DocsEditable()
  void set media(String value) => _blink.Native_SVGStyleElement_media_Setter(this, value);

  @DomName('SVGStyleElement.title')
  @DocsEditable()
  String get title => _blink.Native_SVGStyleElement_title_Getter(this);

  @DomName('SVGStyleElement.title')
  @DocsEditable()
  void set title(String value) => _blink.Native_SVGStyleElement_title_Setter(this, value);

  @DomName('SVGStyleElement.type')
  @DocsEditable()
  String get type => _blink.Native_SVGStyleElement_type_Getter(this);

  @DomName('SVGStyleElement.type')
  @DocsEditable()
  void set type(String value) => _blink.Native_SVGStyleElement_type_Setter(this, value);

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
@Unstable()
class SvgElement extends Element implements GlobalEventHandlers {
  static final _START_TAG_REGEXP = new RegExp('<(\\w+)');

  factory SvgElement.tag(String tag) =>
      document.createElementNS("http://www.w3.org/2000/svg", tag);
  factory SvgElement.svg(String svg,
      {NodeValidator validator, NodeTreeSanitizer treeSanitizer}) {

    if (validator == null && treeSanitizer == null) {
      validator = new NodeValidatorBuilder.common()..allowSvg();
    }

    final match = _START_TAG_REGEXP.firstMatch(svg);
    var parentElement;
    if (match != null && match.group(1).toLowerCase() == 'svg') {
      parentElement = document.body;
    } else {
      parentElement = new SvgSvgElement();
    }
    var fragment = parentElement.createFragment(svg, validator: validator,
        treeSanitizer: treeSanitizer);
    return fragment.nodes.where((e) => e is SvgElement).single;
  }

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

  void set innerHtml(String value) {
    this.setInnerHtml(value);
  }

  DocumentFragment createFragment(String svg,
      {NodeValidator validator, NodeTreeSanitizer treeSanitizer}) {

    if (treeSanitizer == null) {
      if (validator == null) {
        validator = new NodeValidatorBuilder.common()
          ..allowSvg();
      }
      treeSanitizer = new NodeTreeSanitizer(validator);
    }

    // We create a fragment which will parse in the HTML parser
    var html = '<svg version="1.1">$svg</svg>';
    var fragment = document.body.createFragment(html,
        treeSanitizer: treeSanitizer);

    var svgFragment = new DocumentFragment();
    // The root is the <svg/> element, need to pull out the contents.
    var root = fragment.nodes.single;
    while (root.firstChild != null) {
      svgFragment.append(root.firstChild);
    }
    return svgFragment;
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

  HtmlCollection get _children {
    throw new UnsupportedError("Cannot get _children on SVG.");
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

  @DomName('SVGElement.abortEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> abortEvent = const EventStreamProvider<Event>('abort');

  @DomName('SVGElement.blurEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> blurEvent = const EventStreamProvider<Event>('blur');

  @DomName('SVGElement.canplayEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> canPlayEvent = const EventStreamProvider<Event>('canplay');

  @DomName('SVGElement.canplaythroughEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> canPlayThroughEvent = const EventStreamProvider<Event>('canplaythrough');

  @DomName('SVGElement.changeEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> changeEvent = const EventStreamProvider<Event>('change');

  @DomName('SVGElement.clickEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<MouseEvent> clickEvent = const EventStreamProvider<MouseEvent>('click');

  @DomName('SVGElement.contextmenuEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<MouseEvent> contextMenuEvent = const EventStreamProvider<MouseEvent>('contextmenu');

  @DomName('SVGElement.dblclickEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> doubleClickEvent = const EventStreamProvider<Event>('dblclick');

  @DomName('SVGElement.dragEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<MouseEvent> dragEvent = const EventStreamProvider<MouseEvent>('drag');

  @DomName('SVGElement.dragendEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<MouseEvent> dragEndEvent = const EventStreamProvider<MouseEvent>('dragend');

  @DomName('SVGElement.dragenterEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<MouseEvent> dragEnterEvent = const EventStreamProvider<MouseEvent>('dragenter');

  @DomName('SVGElement.dragleaveEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<MouseEvent> dragLeaveEvent = const EventStreamProvider<MouseEvent>('dragleave');

  @DomName('SVGElement.dragoverEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<MouseEvent> dragOverEvent = const EventStreamProvider<MouseEvent>('dragover');

  @DomName('SVGElement.dragstartEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<MouseEvent> dragStartEvent = const EventStreamProvider<MouseEvent>('dragstart');

  @DomName('SVGElement.dropEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<MouseEvent> dropEvent = const EventStreamProvider<MouseEvent>('drop');

  @DomName('SVGElement.durationchangeEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> durationChangeEvent = const EventStreamProvider<Event>('durationchange');

  @DomName('SVGElement.emptiedEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> emptiedEvent = const EventStreamProvider<Event>('emptied');

  @DomName('SVGElement.endedEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> endedEvent = const EventStreamProvider<Event>('ended');

  @DomName('SVGElement.errorEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> errorEvent = const EventStreamProvider<Event>('error');

  @DomName('SVGElement.focusEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> focusEvent = const EventStreamProvider<Event>('focus');

  @DomName('SVGElement.inputEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> inputEvent = const EventStreamProvider<Event>('input');

  @DomName('SVGElement.invalidEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> invalidEvent = const EventStreamProvider<Event>('invalid');

  @DomName('SVGElement.keydownEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<KeyboardEvent> keyDownEvent = const EventStreamProvider<KeyboardEvent>('keydown');

  @DomName('SVGElement.keypressEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<KeyboardEvent> keyPressEvent = const EventStreamProvider<KeyboardEvent>('keypress');

  @DomName('SVGElement.keyupEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<KeyboardEvent> keyUpEvent = const EventStreamProvider<KeyboardEvent>('keyup');

  @DomName('SVGElement.loadEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> loadEvent = const EventStreamProvider<Event>('load');

  @DomName('SVGElement.loadeddataEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> loadedDataEvent = const EventStreamProvider<Event>('loadeddata');

  @DomName('SVGElement.loadedmetadataEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> loadedMetadataEvent = const EventStreamProvider<Event>('loadedmetadata');

  @DomName('SVGElement.mousedownEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<MouseEvent> mouseDownEvent = const EventStreamProvider<MouseEvent>('mousedown');

  @DomName('SVGElement.mouseenterEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<MouseEvent> mouseEnterEvent = const EventStreamProvider<MouseEvent>('mouseenter');

  @DomName('SVGElement.mouseleaveEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<MouseEvent> mouseLeaveEvent = const EventStreamProvider<MouseEvent>('mouseleave');

  @DomName('SVGElement.mousemoveEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<MouseEvent> mouseMoveEvent = const EventStreamProvider<MouseEvent>('mousemove');

  @DomName('SVGElement.mouseoutEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<MouseEvent> mouseOutEvent = const EventStreamProvider<MouseEvent>('mouseout');

  @DomName('SVGElement.mouseoverEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<MouseEvent> mouseOverEvent = const EventStreamProvider<MouseEvent>('mouseover');

  @DomName('SVGElement.mouseupEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<MouseEvent> mouseUpEvent = const EventStreamProvider<MouseEvent>('mouseup');

  @DomName('SVGElement.mousewheelEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<WheelEvent> mouseWheelEvent = const EventStreamProvider<WheelEvent>('mousewheel');

  @DomName('SVGElement.pauseEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> pauseEvent = const EventStreamProvider<Event>('pause');

  @DomName('SVGElement.playEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> playEvent = const EventStreamProvider<Event>('play');

  @DomName('SVGElement.playingEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> playingEvent = const EventStreamProvider<Event>('playing');

  @DomName('SVGElement.ratechangeEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> rateChangeEvent = const EventStreamProvider<Event>('ratechange');

  @DomName('SVGElement.resetEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> resetEvent = const EventStreamProvider<Event>('reset');

  @DomName('SVGElement.resizeEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> resizeEvent = const EventStreamProvider<Event>('resize');

  @DomName('SVGElement.scrollEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> scrollEvent = const EventStreamProvider<Event>('scroll');

  @DomName('SVGElement.seekedEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> seekedEvent = const EventStreamProvider<Event>('seeked');

  @DomName('SVGElement.seekingEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> seekingEvent = const EventStreamProvider<Event>('seeking');

  @DomName('SVGElement.selectEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> selectEvent = const EventStreamProvider<Event>('select');

  @DomName('SVGElement.stalledEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> stalledEvent = const EventStreamProvider<Event>('stalled');

  @DomName('SVGElement.submitEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> submitEvent = const EventStreamProvider<Event>('submit');

  @DomName('SVGElement.suspendEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> suspendEvent = const EventStreamProvider<Event>('suspend');

  @DomName('SVGElement.timeupdateEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> timeUpdateEvent = const EventStreamProvider<Event>('timeupdate');

  @DomName('SVGElement.volumechangeEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> volumeChangeEvent = const EventStreamProvider<Event>('volumechange');

  @DomName('SVGElement.waitingEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> waitingEvent = const EventStreamProvider<Event>('waiting');
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  SvgElement.created() : super.created();

  @DomName('SVGElement.className')
  @DocsEditable()
  @Experimental() // untriaged
  AnimatedString get _svgClassName => _blink.Native_SVGElement_className_Getter(this);

  @DomName('SVGElement.ownerSVGElement')
  @DocsEditable()
  SvgSvgElement get ownerSvgElement => _blink.Native_SVGElement_ownerSVGElement_Getter(this);

  @DomName('SVGElement.style')
  @DocsEditable()
  @Experimental() // untriaged
  CssStyleDeclaration get style => _blink.Native_SVGElement_style_Getter(this);

  @DomName('SVGElement.viewportElement')
  @DocsEditable()
  SvgElement get viewportElement => _blink.Native_SVGElement_viewportElement_Getter(this);

  @DomName('SVGElement.xmlbase')
  @DocsEditable()
  String get xmlbase => _blink.Native_SVGElement_xmlbase_Getter(this);

  @DomName('SVGElement.xmlbase')
  @DocsEditable()
  void set xmlbase(String value) => _blink.Native_SVGElement_xmlbase_Setter(this, value);

  @DomName('SVGElement.xmllang')
  @DocsEditable()
  @Experimental() // untriaged
  String get xmllang => _blink.Native_SVGElement_xmllang_Getter(this);

  @DomName('SVGElement.xmllang')
  @DocsEditable()
  @Experimental() // untriaged
  void set xmllang(String value) => _blink.Native_SVGElement_xmllang_Setter(this, value);

  @DomName('SVGElement.xmlspace')
  @DocsEditable()
  @Experimental() // untriaged
  String get xmlspace => _blink.Native_SVGElement_xmlspace_Getter(this);

  @DomName('SVGElement.xmlspace')
  @DocsEditable()
  @Experimental() // untriaged
  void set xmlspace(String value) => _blink.Native_SVGElement_xmlspace_Setter(this, value);

  @DomName('SVGElement.onabort')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onAbort => abortEvent.forElement(this);

  @DomName('SVGElement.onblur')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onBlur => blurEvent.forElement(this);

  @DomName('SVGElement.oncanplay')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onCanPlay => canPlayEvent.forElement(this);

  @DomName('SVGElement.oncanplaythrough')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onCanPlayThrough => canPlayThroughEvent.forElement(this);

  @DomName('SVGElement.onchange')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onChange => changeEvent.forElement(this);

  @DomName('SVGElement.onclick')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<MouseEvent> get onClick => clickEvent.forElement(this);

  @DomName('SVGElement.oncontextmenu')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<MouseEvent> get onContextMenu => contextMenuEvent.forElement(this);

  @DomName('SVGElement.ondblclick')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onDoubleClick => doubleClickEvent.forElement(this);

  @DomName('SVGElement.ondrag')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<MouseEvent> get onDrag => dragEvent.forElement(this);

  @DomName('SVGElement.ondragend')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<MouseEvent> get onDragEnd => dragEndEvent.forElement(this);

  @DomName('SVGElement.ondragenter')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<MouseEvent> get onDragEnter => dragEnterEvent.forElement(this);

  @DomName('SVGElement.ondragleave')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<MouseEvent> get onDragLeave => dragLeaveEvent.forElement(this);

  @DomName('SVGElement.ondragover')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<MouseEvent> get onDragOver => dragOverEvent.forElement(this);

  @DomName('SVGElement.ondragstart')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<MouseEvent> get onDragStart => dragStartEvent.forElement(this);

  @DomName('SVGElement.ondrop')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<MouseEvent> get onDrop => dropEvent.forElement(this);

  @DomName('SVGElement.ondurationchange')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onDurationChange => durationChangeEvent.forElement(this);

  @DomName('SVGElement.onemptied')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onEmptied => emptiedEvent.forElement(this);

  @DomName('SVGElement.onended')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onEnded => endedEvent.forElement(this);

  @DomName('SVGElement.onerror')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onError => errorEvent.forElement(this);

  @DomName('SVGElement.onfocus')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onFocus => focusEvent.forElement(this);

  @DomName('SVGElement.oninput')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onInput => inputEvent.forElement(this);

  @DomName('SVGElement.oninvalid')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onInvalid => invalidEvent.forElement(this);

  @DomName('SVGElement.onkeydown')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<KeyboardEvent> get onKeyDown => keyDownEvent.forElement(this);

  @DomName('SVGElement.onkeypress')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<KeyboardEvent> get onKeyPress => keyPressEvent.forElement(this);

  @DomName('SVGElement.onkeyup')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<KeyboardEvent> get onKeyUp => keyUpEvent.forElement(this);

  @DomName('SVGElement.onload')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onLoad => loadEvent.forElement(this);

  @DomName('SVGElement.onloadeddata')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onLoadedData => loadedDataEvent.forElement(this);

  @DomName('SVGElement.onloadedmetadata')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onLoadedMetadata => loadedMetadataEvent.forElement(this);

  @DomName('SVGElement.onmousedown')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<MouseEvent> get onMouseDown => mouseDownEvent.forElement(this);

  @DomName('SVGElement.onmouseenter')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<MouseEvent> get onMouseEnter => mouseEnterEvent.forElement(this);

  @DomName('SVGElement.onmouseleave')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<MouseEvent> get onMouseLeave => mouseLeaveEvent.forElement(this);

  @DomName('SVGElement.onmousemove')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<MouseEvent> get onMouseMove => mouseMoveEvent.forElement(this);

  @DomName('SVGElement.onmouseout')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<MouseEvent> get onMouseOut => mouseOutEvent.forElement(this);

  @DomName('SVGElement.onmouseover')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<MouseEvent> get onMouseOver => mouseOverEvent.forElement(this);

  @DomName('SVGElement.onmouseup')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<MouseEvent> get onMouseUp => mouseUpEvent.forElement(this);

  @DomName('SVGElement.onmousewheel')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<WheelEvent> get onMouseWheel => mouseWheelEvent.forElement(this);

  @DomName('SVGElement.onpause')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onPause => pauseEvent.forElement(this);

  @DomName('SVGElement.onplay')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onPlay => playEvent.forElement(this);

  @DomName('SVGElement.onplaying')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onPlaying => playingEvent.forElement(this);

  @DomName('SVGElement.onratechange')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onRateChange => rateChangeEvent.forElement(this);

  @DomName('SVGElement.onreset')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onReset => resetEvent.forElement(this);

  @DomName('SVGElement.onresize')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onResize => resizeEvent.forElement(this);

  @DomName('SVGElement.onscroll')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onScroll => scrollEvent.forElement(this);

  @DomName('SVGElement.onseeked')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onSeeked => seekedEvent.forElement(this);

  @DomName('SVGElement.onseeking')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onSeeking => seekingEvent.forElement(this);

  @DomName('SVGElement.onselect')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onSelect => selectEvent.forElement(this);

  @DomName('SVGElement.onstalled')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onStalled => stalledEvent.forElement(this);

  @DomName('SVGElement.onsubmit')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onSubmit => submitEvent.forElement(this);

  @DomName('SVGElement.onsuspend')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onSuspend => suspendEvent.forElement(this);

  @DomName('SVGElement.ontimeupdate')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onTimeUpdate => timeUpdateEvent.forElement(this);

  @DomName('SVGElement.onvolumechange')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onVolumeChange => volumeChangeEvent.forElement(this);

  @DomName('SVGElement.onwaiting')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onWaiting => waitingEvent.forElement(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('SVGSVGElement')
@Unstable()
class SvgSvgElement extends GraphicsElement implements FitToViewBox, ZoomAndPan {
  factory SvgSvgElement() {
    final el = new SvgElement.tag("svg");
    // The SVG spec requires the version attribute to match the spec version
    el.attributes['version'] = "1.1";
    return el;
  }

  // To suppress missing implicit constructor warnings.
  factory SvgSvgElement._() { throw new UnsupportedError("Not supported"); }
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  SvgSvgElement.created() : super.created();

  @DomName('SVGSVGElement.currentScale')
  @DocsEditable()
  num get currentScale => _blink.Native_SVGSVGElement_currentScale_Getter(this);

  @DomName('SVGSVGElement.currentScale')
  @DocsEditable()
  void set currentScale(num value) => _blink.Native_SVGSVGElement_currentScale_Setter(this, value);

  @DomName('SVGSVGElement.currentTranslate')
  @DocsEditable()
  Point get currentTranslate => _blink.Native_SVGSVGElement_currentTranslate_Getter(this);

  @DomName('SVGSVGElement.currentView')
  @DocsEditable()
  ViewSpec get currentView => _blink.Native_SVGSVGElement_currentView_Getter(this);

  @DomName('SVGSVGElement.height')
  @DocsEditable()
  AnimatedLength get height => _blink.Native_SVGSVGElement_height_Getter(this);

  @DomName('SVGSVGElement.pixelUnitToMillimeterX')
  @DocsEditable()
  double get pixelUnitToMillimeterX => _blink.Native_SVGSVGElement_pixelUnitToMillimeterX_Getter(this);

  @DomName('SVGSVGElement.pixelUnitToMillimeterY')
  @DocsEditable()
  double get pixelUnitToMillimeterY => _blink.Native_SVGSVGElement_pixelUnitToMillimeterY_Getter(this);

  @DomName('SVGSVGElement.screenPixelToMillimeterX')
  @DocsEditable()
  double get screenPixelToMillimeterX => _blink.Native_SVGSVGElement_screenPixelToMillimeterX_Getter(this);

  @DomName('SVGSVGElement.screenPixelToMillimeterY')
  @DocsEditable()
  double get screenPixelToMillimeterY => _blink.Native_SVGSVGElement_screenPixelToMillimeterY_Getter(this);

  @DomName('SVGSVGElement.useCurrentView')
  @DocsEditable()
  bool get useCurrentView => _blink.Native_SVGSVGElement_useCurrentView_Getter(this);

  @DomName('SVGSVGElement.viewport')
  @DocsEditable()
  Rect get viewport => _blink.Native_SVGSVGElement_viewport_Getter(this);

  @DomName('SVGSVGElement.width')
  @DocsEditable()
  AnimatedLength get width => _blink.Native_SVGSVGElement_width_Getter(this);

  @DomName('SVGSVGElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.Native_SVGSVGElement_x_Getter(this);

  @DomName('SVGSVGElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.Native_SVGSVGElement_y_Getter(this);

  @DomName('SVGSVGElement.animationsPaused')
  @DocsEditable()
  bool animationsPaused() => _blink.Native_SVGSVGElement_animationsPaused_Callback(this);

  @DomName('SVGSVGElement.checkEnclosure')
  @DocsEditable()
  bool checkEnclosure(SvgElement element, Rect rect) => _blink.Native_SVGSVGElement_checkEnclosure_Callback(this, element, rect);

  @DomName('SVGSVGElement.checkIntersection')
  @DocsEditable()
  bool checkIntersection(SvgElement element, Rect rect) => _blink.Native_SVGSVGElement_checkIntersection_Callback(this, element, rect);

  @DomName('SVGSVGElement.createSVGAngle')
  @DocsEditable()
  Angle createSvgAngle() => _blink.Native_SVGSVGElement_createSVGAngle_Callback(this);

  @DomName('SVGSVGElement.createSVGLength')
  @DocsEditable()
  Length createSvgLength() => _blink.Native_SVGSVGElement_createSVGLength_Callback(this);

  @DomName('SVGSVGElement.createSVGMatrix')
  @DocsEditable()
  Matrix createSvgMatrix() => _blink.Native_SVGSVGElement_createSVGMatrix_Callback(this);

  @DomName('SVGSVGElement.createSVGNumber')
  @DocsEditable()
  Number createSvgNumber() => _blink.Native_SVGSVGElement_createSVGNumber_Callback(this);

  @DomName('SVGSVGElement.createSVGPoint')
  @DocsEditable()
  Point createSvgPoint() => _blink.Native_SVGSVGElement_createSVGPoint_Callback(this);

  @DomName('SVGSVGElement.createSVGRect')
  @DocsEditable()
  Rect createSvgRect() => _blink.Native_SVGSVGElement_createSVGRect_Callback(this);

  @DomName('SVGSVGElement.createSVGTransform')
  @DocsEditable()
  Transform createSvgTransform() => _blink.Native_SVGSVGElement_createSVGTransform_Callback(this);

  @DomName('SVGSVGElement.createSVGTransformFromMatrix')
  @DocsEditable()
  Transform createSvgTransformFromMatrix(Matrix matrix) => _blink.Native_SVGSVGElement_createSVGTransformFromMatrix_Callback(this, matrix);

  @DomName('SVGSVGElement.deselectAll')
  @DocsEditable()
  void deselectAll() => _blink.Native_SVGSVGElement_deselectAll_Callback(this);

  @DomName('SVGSVGElement.forceRedraw')
  @DocsEditable()
  void forceRedraw() => _blink.Native_SVGSVGElement_forceRedraw_Callback(this);

  @DomName('SVGSVGElement.getCurrentTime')
  @DocsEditable()
  double getCurrentTime() => _blink.Native_SVGSVGElement_getCurrentTime_Callback(this);

  @DomName('SVGSVGElement.getElementById')
  @DocsEditable()
  Element getElementById(String elementId) => _blink.Native_SVGSVGElement_getElementById_Callback(this, elementId);

  @DomName('SVGSVGElement.getEnclosureList')
  @DocsEditable()
  List<Node> getEnclosureList(Rect rect, SvgElement referenceElement) => _blink.Native_SVGSVGElement_getEnclosureList_Callback(this, rect, referenceElement);

  @DomName('SVGSVGElement.getIntersectionList')
  @DocsEditable()
  List<Node> getIntersectionList(Rect rect, SvgElement referenceElement) => _blink.Native_SVGSVGElement_getIntersectionList_Callback(this, rect, referenceElement);

  @DomName('SVGSVGElement.pauseAnimations')
  @DocsEditable()
  void pauseAnimations() => _blink.Native_SVGSVGElement_pauseAnimations_Callback(this);

  @DomName('SVGSVGElement.setCurrentTime')
  @DocsEditable()
  void setCurrentTime(num seconds) => _blink.Native_SVGSVGElement_setCurrentTime_Callback(this, seconds);

  @DomName('SVGSVGElement.suspendRedraw')
  @DocsEditable()
  int suspendRedraw(int maxWaitMilliseconds) => _blink.Native_SVGSVGElement_suspendRedraw_Callback(this, maxWaitMilliseconds);

  @DomName('SVGSVGElement.unpauseAnimations')
  @DocsEditable()
  void unpauseAnimations() => _blink.Native_SVGSVGElement_unpauseAnimations_Callback(this);

  @DomName('SVGSVGElement.unsuspendRedraw')
  @DocsEditable()
  void unsuspendRedraw(int suspendHandleId) => _blink.Native_SVGSVGElement_unsuspendRedraw_Callback(this, suspendHandleId);

  @DomName('SVGSVGElement.unsuspendRedrawAll')
  @DocsEditable()
  void unsuspendRedrawAll() => _blink.Native_SVGSVGElement_unsuspendRedrawAll_Callback(this);

  @DomName('SVGSVGElement.preserveAspectRatio')
  @DocsEditable()
  AnimatedPreserveAspectRatio get preserveAspectRatio => _blink.Native_SVGSVGElement_preserveAspectRatio_Getter(this);

  @DomName('SVGSVGElement.viewBox')
  @DocsEditable()
  AnimatedRect get viewBox => _blink.Native_SVGSVGElement_viewBox_Getter(this);

  @DomName('SVGSVGElement.zoomAndPan')
  @DocsEditable()
  int get zoomAndPan => _blink.Native_SVGSVGElement_zoomAndPan_Getter(this);

  @DomName('SVGSVGElement.zoomAndPan')
  @DocsEditable()
  void set zoomAndPan(int value) => _blink.Native_SVGSVGElement_zoomAndPan_Setter(this, value);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGSwitchElement')
@Unstable()
class SwitchElement extends GraphicsElement {
  // To suppress missing implicit constructor warnings.
  factory SwitchElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGSwitchElement.SVGSwitchElement')
  @DocsEditable()
  factory SwitchElement() => _SvgElementFactoryProvider.createSvgElement_tag("switch");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  SwitchElement.created() : super.created();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGSymbolElement')
@Unstable()
class SymbolElement extends SvgElement implements FitToViewBox {
  // To suppress missing implicit constructor warnings.
  factory SymbolElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGSymbolElement.SVGSymbolElement')
  @DocsEditable()
  factory SymbolElement() => _SvgElementFactoryProvider.createSvgElement_tag("symbol");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  SymbolElement.created() : super.created();

  @DomName('SVGSymbolElement.preserveAspectRatio')
  @DocsEditable()
  AnimatedPreserveAspectRatio get preserveAspectRatio => _blink.Native_SVGSymbolElement_preserveAspectRatio_Getter(this);

  @DomName('SVGSymbolElement.viewBox')
  @DocsEditable()
  AnimatedRect get viewBox => _blink.Native_SVGSymbolElement_viewBox_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGTSpanElement')
@Unstable()
class TSpanElement extends TextPositioningElement {
  // To suppress missing implicit constructor warnings.
  factory TSpanElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGTSpanElement.SVGTSpanElement')
  @DocsEditable()
  factory TSpanElement() => _SvgElementFactoryProvider.createSvgElement_tag("tspan");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  TSpanElement.created() : super.created();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGTests')
@Unstable()
abstract class Tests extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory Tests._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGTests.requiredExtensions')
  @DocsEditable()
  StringList get requiredExtensions => _blink.Native_SVGTests_requiredExtensions_Getter(this);

  @DomName('SVGTests.requiredFeatures')
  @DocsEditable()
  StringList get requiredFeatures => _blink.Native_SVGTests_requiredFeatures_Getter(this);

  @DomName('SVGTests.systemLanguage')
  @DocsEditable()
  StringList get systemLanguage => _blink.Native_SVGTests_systemLanguage_Getter(this);

  @DomName('SVGTests.hasExtension')
  @DocsEditable()
  bool hasExtension(String extension) => _blink.Native_SVGTests_hasExtension_Callback(this, extension);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGTextContentElement')
@Unstable()
class TextContentElement extends GraphicsElement {
  // To suppress missing implicit constructor warnings.
  factory TextContentElement._() { throw new UnsupportedError("Not supported"); }
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  TextContentElement.created() : super.created();

  @DomName('SVGTextContentElement.LENGTHADJUST_SPACING')
  @DocsEditable()
  static const int LENGTHADJUST_SPACING = 1;

  @DomName('SVGTextContentElement.LENGTHADJUST_SPACINGANDGLYPHS')
  @DocsEditable()
  static const int LENGTHADJUST_SPACINGANDGLYPHS = 2;

  @DomName('SVGTextContentElement.LENGTHADJUST_UNKNOWN')
  @DocsEditable()
  static const int LENGTHADJUST_UNKNOWN = 0;

  @DomName('SVGTextContentElement.lengthAdjust')
  @DocsEditable()
  AnimatedEnumeration get lengthAdjust => _blink.Native_SVGTextContentElement_lengthAdjust_Getter(this);

  @DomName('SVGTextContentElement.textLength')
  @DocsEditable()
  AnimatedLength get textLength => _blink.Native_SVGTextContentElement_textLength_Getter(this);

  @DomName('SVGTextContentElement.getCharNumAtPosition')
  @DocsEditable()
  int getCharNumAtPosition(Point point) => _blink.Native_SVGTextContentElement_getCharNumAtPosition_Callback(this, point);

  @DomName('SVGTextContentElement.getComputedTextLength')
  @DocsEditable()
  double getComputedTextLength() => _blink.Native_SVGTextContentElement_getComputedTextLength_Callback(this);

  @DomName('SVGTextContentElement.getEndPositionOfChar')
  @DocsEditable()
  Point getEndPositionOfChar(int offset) => _blink.Native_SVGTextContentElement_getEndPositionOfChar_Callback(this, offset);

  @DomName('SVGTextContentElement.getExtentOfChar')
  @DocsEditable()
  Rect getExtentOfChar(int offset) => _blink.Native_SVGTextContentElement_getExtentOfChar_Callback(this, offset);

  @DomName('SVGTextContentElement.getNumberOfChars')
  @DocsEditable()
  int getNumberOfChars() => _blink.Native_SVGTextContentElement_getNumberOfChars_Callback(this);

  @DomName('SVGTextContentElement.getRotationOfChar')
  @DocsEditable()
  double getRotationOfChar(int offset) => _blink.Native_SVGTextContentElement_getRotationOfChar_Callback(this, offset);

  @DomName('SVGTextContentElement.getStartPositionOfChar')
  @DocsEditable()
  Point getStartPositionOfChar(int offset) => _blink.Native_SVGTextContentElement_getStartPositionOfChar_Callback(this, offset);

  @DomName('SVGTextContentElement.getSubStringLength')
  @DocsEditable()
  double getSubStringLength(int offset, int length) => _blink.Native_SVGTextContentElement_getSubStringLength_Callback(this, offset, length);

  @DomName('SVGTextContentElement.selectSubString')
  @DocsEditable()
  void selectSubString(int offset, int length) => _blink.Native_SVGTextContentElement_selectSubString_Callback(this, offset, length);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGTextElement')
@Unstable()
class TextElement extends TextPositioningElement {
  // To suppress missing implicit constructor warnings.
  factory TextElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGTextElement.SVGTextElement')
  @DocsEditable()
  factory TextElement() => _SvgElementFactoryProvider.createSvgElement_tag("text");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  TextElement.created() : super.created();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGTextPathElement')
@Unstable()
class TextPathElement extends TextContentElement implements UriReference {
  // To suppress missing implicit constructor warnings.
  factory TextPathElement._() { throw new UnsupportedError("Not supported"); }
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  TextPathElement.created() : super.created();

  @DomName('SVGTextPathElement.TEXTPATH_METHODTYPE_ALIGN')
  @DocsEditable()
  static const int TEXTPATH_METHODTYPE_ALIGN = 1;

  @DomName('SVGTextPathElement.TEXTPATH_METHODTYPE_STRETCH')
  @DocsEditable()
  static const int TEXTPATH_METHODTYPE_STRETCH = 2;

  @DomName('SVGTextPathElement.TEXTPATH_METHODTYPE_UNKNOWN')
  @DocsEditable()
  static const int TEXTPATH_METHODTYPE_UNKNOWN = 0;

  @DomName('SVGTextPathElement.TEXTPATH_SPACINGTYPE_AUTO')
  @DocsEditable()
  static const int TEXTPATH_SPACINGTYPE_AUTO = 1;

  @DomName('SVGTextPathElement.TEXTPATH_SPACINGTYPE_EXACT')
  @DocsEditable()
  static const int TEXTPATH_SPACINGTYPE_EXACT = 2;

  @DomName('SVGTextPathElement.TEXTPATH_SPACINGTYPE_UNKNOWN')
  @DocsEditable()
  static const int TEXTPATH_SPACINGTYPE_UNKNOWN = 0;

  @DomName('SVGTextPathElement.method')
  @DocsEditable()
  AnimatedEnumeration get method => _blink.Native_SVGTextPathElement_method_Getter(this);

  @DomName('SVGTextPathElement.spacing')
  @DocsEditable()
  AnimatedEnumeration get spacing => _blink.Native_SVGTextPathElement_spacing_Getter(this);

  @DomName('SVGTextPathElement.startOffset')
  @DocsEditable()
  AnimatedLength get startOffset => _blink.Native_SVGTextPathElement_startOffset_Getter(this);

  @DomName('SVGTextPathElement.href')
  @DocsEditable()
  AnimatedString get href => _blink.Native_SVGTextPathElement_href_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGTextPositioningElement')
@Unstable()
class TextPositioningElement extends TextContentElement {
  // To suppress missing implicit constructor warnings.
  factory TextPositioningElement._() { throw new UnsupportedError("Not supported"); }
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  TextPositioningElement.created() : super.created();

  @DomName('SVGTextPositioningElement.dx')
  @DocsEditable()
  AnimatedLengthList get dx => _blink.Native_SVGTextPositioningElement_dx_Getter(this);

  @DomName('SVGTextPositioningElement.dy')
  @DocsEditable()
  AnimatedLengthList get dy => _blink.Native_SVGTextPositioningElement_dy_Getter(this);

  @DomName('SVGTextPositioningElement.rotate')
  @DocsEditable()
  AnimatedNumberList get rotate => _blink.Native_SVGTextPositioningElement_rotate_Getter(this);

  @DomName('SVGTextPositioningElement.x')
  @DocsEditable()
  AnimatedLengthList get x => _blink.Native_SVGTextPositioningElement_x_Getter(this);

  @DomName('SVGTextPositioningElement.y')
  @DocsEditable()
  AnimatedLengthList get y => _blink.Native_SVGTextPositioningElement_y_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGTitleElement')
@Unstable()
class TitleElement extends SvgElement {
  // To suppress missing implicit constructor warnings.
  factory TitleElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGTitleElement.SVGTitleElement')
  @DocsEditable()
  factory TitleElement() => _SvgElementFactoryProvider.createSvgElement_tag("title");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  TitleElement.created() : super.created();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGTransform')
@Unstable()
class Transform extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory Transform._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGTransform.SVG_TRANSFORM_MATRIX')
  @DocsEditable()
  static const int SVG_TRANSFORM_MATRIX = 1;

  @DomName('SVGTransform.SVG_TRANSFORM_ROTATE')
  @DocsEditable()
  static const int SVG_TRANSFORM_ROTATE = 4;

  @DomName('SVGTransform.SVG_TRANSFORM_SCALE')
  @DocsEditable()
  static const int SVG_TRANSFORM_SCALE = 3;

  @DomName('SVGTransform.SVG_TRANSFORM_SKEWX')
  @DocsEditable()
  static const int SVG_TRANSFORM_SKEWX = 5;

  @DomName('SVGTransform.SVG_TRANSFORM_SKEWY')
  @DocsEditable()
  static const int SVG_TRANSFORM_SKEWY = 6;

  @DomName('SVGTransform.SVG_TRANSFORM_TRANSLATE')
  @DocsEditable()
  static const int SVG_TRANSFORM_TRANSLATE = 2;

  @DomName('SVGTransform.SVG_TRANSFORM_UNKNOWN')
  @DocsEditable()
  static const int SVG_TRANSFORM_UNKNOWN = 0;

  @DomName('SVGTransform.angle')
  @DocsEditable()
  double get angle => _blink.Native_SVGTransform_angle_Getter(this);

  @DomName('SVGTransform.matrix')
  @DocsEditable()
  Matrix get matrix => _blink.Native_SVGTransform_matrix_Getter(this);

  @DomName('SVGTransform.type')
  @DocsEditable()
  int get type => _blink.Native_SVGTransform_type_Getter(this);

  @DomName('SVGTransform.setMatrix')
  @DocsEditable()
  void setMatrix(Matrix matrix) => _blink.Native_SVGTransform_setMatrix_Callback(this, matrix);

  @DomName('SVGTransform.setRotate')
  @DocsEditable()
  void setRotate(num angle, num cx, num cy) => _blink.Native_SVGTransform_setRotate_Callback(this, angle, cx, cy);

  @DomName('SVGTransform.setScale')
  @DocsEditable()
  void setScale(num sx, num sy) => _blink.Native_SVGTransform_setScale_Callback(this, sx, sy);

  @DomName('SVGTransform.setSkewX')
  @DocsEditable()
  void setSkewX(num angle) => _blink.Native_SVGTransform_setSkewX_Callback(this, angle);

  @DomName('SVGTransform.setSkewY')
  @DocsEditable()
  void setSkewY(num angle) => _blink.Native_SVGTransform_setSkewY_Callback(this, angle);

  @DomName('SVGTransform.setTranslate')
  @DocsEditable()
  void setTranslate(num tx, num ty) => _blink.Native_SVGTransform_setTranslate_Callback(this, tx, ty);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGTransformList')
@Unstable()
class TransformList extends NativeFieldWrapperClass2 with ListMixin<Transform>, ImmutableListMixin<Transform> implements List<Transform> {
  // To suppress missing implicit constructor warnings.
  factory TransformList._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGTransformList.numberOfItems')
  @DocsEditable()
  int get numberOfItems => _blink.Native_SVGTransformList_numberOfItems_Getter(this);

  Transform operator[](int index) {
    if (index < 0 || index >= length)
      throw new RangeError.range(index, 0, length);
    return getItem(index);
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
      return getItem(0);
    }
    throw new StateError("No elements");
  }

  Transform get last {
    int len = this.length;
    if (len > 0) {
      return getItem(len - 1);
    }
    throw new StateError("No elements");
  }

  Transform get single {
    int len = this.length;
    if (len == 1) {
      return getItem(0);
    }
    if (len == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  Transform elementAt(int index) => this[index];
  // -- end List<Transform> mixins.

  @DomName('SVGTransformList.appendItem')
  @DocsEditable()
  Transform appendItem(Transform item) => _blink.Native_SVGTransformList_appendItem_Callback(this, item);

  @DomName('SVGTransformList.clear')
  @DocsEditable()
  void clear() => _blink.Native_SVGTransformList_clear_Callback(this);

  @DomName('SVGTransformList.consolidate')
  @DocsEditable()
  Transform consolidate() => _blink.Native_SVGTransformList_consolidate_Callback(this);

  @DomName('SVGTransformList.createSVGTransformFromMatrix')
  @DocsEditable()
  Transform createSvgTransformFromMatrix(Matrix matrix) => _blink.Native_SVGTransformList_createSVGTransformFromMatrix_Callback(this, matrix);

  @DomName('SVGTransformList.getItem')
  @DocsEditable()
  Transform getItem(int index) => _blink.Native_SVGTransformList_getItem_Callback(this, index);

  @DomName('SVGTransformList.initialize')
  @DocsEditable()
  Transform initialize(Transform item) => _blink.Native_SVGTransformList_initialize_Callback(this, item);

  @DomName('SVGTransformList.insertItemBefore')
  @DocsEditable()
  Transform insertItemBefore(Transform item, int index) => _blink.Native_SVGTransformList_insertItemBefore_Callback(this, item, index);

  @DomName('SVGTransformList.removeItem')
  @DocsEditable()
  Transform removeItem(int index) => _blink.Native_SVGTransformList_removeItem_Callback(this, index);

  @DomName('SVGTransformList.replaceItem')
  @DocsEditable()
  Transform replaceItem(Transform item, int index) => _blink.Native_SVGTransformList_replaceItem_Callback(this, item, index);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGUnitTypes')
@Unstable()
class UnitTypes extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory UnitTypes._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGUnitTypes.SVG_UNIT_TYPE_OBJECTBOUNDINGBOX')
  @DocsEditable()
  static const int SVG_UNIT_TYPE_OBJECTBOUNDINGBOX = 2;

  @DomName('SVGUnitTypes.SVG_UNIT_TYPE_UNKNOWN')
  @DocsEditable()
  static const int SVG_UNIT_TYPE_UNKNOWN = 0;

  @DomName('SVGUnitTypes.SVG_UNIT_TYPE_USERSPACEONUSE')
  @DocsEditable()
  static const int SVG_UNIT_TYPE_USERSPACEONUSE = 1;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGURIReference')
@Unstable()
abstract class UriReference extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory UriReference._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGURIReference.href')
  @DocsEditable()
  AnimatedString get href => _blink.Native_SVGURIReference_href_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGUseElement')
@Unstable()
class UseElement extends GraphicsElement implements UriReference, Tests {
  // To suppress missing implicit constructor warnings.
  factory UseElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGUseElement.SVGUseElement')
  @DocsEditable()
  factory UseElement() => _SvgElementFactoryProvider.createSvgElement_tag("use");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  UseElement.created() : super.created();

  @DomName('SVGUseElement.animatedInstanceRoot')
  @DocsEditable()
  ElementInstance get animatedInstanceRoot => _blink.Native_SVGUseElement_animatedInstanceRoot_Getter(this);

  @DomName('SVGUseElement.height')
  @DocsEditable()
  AnimatedLength get height => _blink.Native_SVGUseElement_height_Getter(this);

  @DomName('SVGUseElement.instanceRoot')
  @DocsEditable()
  ElementInstance get instanceRoot => _blink.Native_SVGUseElement_instanceRoot_Getter(this);

  @DomName('SVGUseElement.width')
  @DocsEditable()
  AnimatedLength get width => _blink.Native_SVGUseElement_width_Getter(this);

  @DomName('SVGUseElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.Native_SVGUseElement_x_Getter(this);

  @DomName('SVGUseElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.Native_SVGUseElement_y_Getter(this);

  @DomName('SVGUseElement.requiredExtensions')
  @DocsEditable()
  StringList get requiredExtensions => _blink.Native_SVGUseElement_requiredExtensions_Getter(this);

  @DomName('SVGUseElement.requiredFeatures')
  @DocsEditable()
  StringList get requiredFeatures => _blink.Native_SVGUseElement_requiredFeatures_Getter(this);

  @DomName('SVGUseElement.systemLanguage')
  @DocsEditable()
  StringList get systemLanguage => _blink.Native_SVGUseElement_systemLanguage_Getter(this);

  @DomName('SVGUseElement.hasExtension')
  @DocsEditable()
  bool hasExtension(String extension) => _blink.Native_SVGUseElement_hasExtension_Callback(this, extension);

  @DomName('SVGUseElement.href')
  @DocsEditable()
  AnimatedString get href => _blink.Native_SVGUseElement_href_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGViewElement')
@Unstable()
class ViewElement extends SvgElement implements FitToViewBox, ZoomAndPan {
  // To suppress missing implicit constructor warnings.
  factory ViewElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGViewElement.SVGViewElement')
  @DocsEditable()
  factory ViewElement() => _SvgElementFactoryProvider.createSvgElement_tag("view");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  ViewElement.created() : super.created();

  @DomName('SVGViewElement.viewTarget')
  @DocsEditable()
  StringList get viewTarget => _blink.Native_SVGViewElement_viewTarget_Getter(this);

  @DomName('SVGViewElement.preserveAspectRatio')
  @DocsEditable()
  AnimatedPreserveAspectRatio get preserveAspectRatio => _blink.Native_SVGViewElement_preserveAspectRatio_Getter(this);

  @DomName('SVGViewElement.viewBox')
  @DocsEditable()
  AnimatedRect get viewBox => _blink.Native_SVGViewElement_viewBox_Getter(this);

  @DomName('SVGViewElement.zoomAndPan')
  @DocsEditable()
  int get zoomAndPan => _blink.Native_SVGViewElement_zoomAndPan_Getter(this);

  @DomName('SVGViewElement.zoomAndPan')
  @DocsEditable()
  void set zoomAndPan(int value) => _blink.Native_SVGViewElement_zoomAndPan_Setter(this, value);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGViewSpec')
@Unstable()
class ViewSpec extends NativeFieldWrapperClass2 implements FitToViewBox, ZoomAndPan {
  // To suppress missing implicit constructor warnings.
  factory ViewSpec._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGViewSpec.preserveAspectRatioString')
  @DocsEditable()
  String get preserveAspectRatioString => _blink.Native_SVGViewSpec_preserveAspectRatioString_Getter(this);

  @DomName('SVGViewSpec.transform')
  @DocsEditable()
  TransformList get transform => _blink.Native_SVGViewSpec_transform_Getter(this);

  @DomName('SVGViewSpec.transformString')
  @DocsEditable()
  String get transformString => _blink.Native_SVGViewSpec_transformString_Getter(this);

  @DomName('SVGViewSpec.viewBoxString')
  @DocsEditable()
  String get viewBoxString => _blink.Native_SVGViewSpec_viewBoxString_Getter(this);

  @DomName('SVGViewSpec.viewTarget')
  @DocsEditable()
  SvgElement get viewTarget => _blink.Native_SVGViewSpec_viewTarget_Getter(this);

  @DomName('SVGViewSpec.viewTargetString')
  @DocsEditable()
  String get viewTargetString => _blink.Native_SVGViewSpec_viewTargetString_Getter(this);

  @DomName('SVGViewSpec.preserveAspectRatio')
  @DocsEditable()
  @Experimental() // nonstandard
  AnimatedPreserveAspectRatio get preserveAspectRatio => _blink.Native_SVGViewSpec_preserveAspectRatio_Getter(this);

  @DomName('SVGViewSpec.viewBox')
  @DocsEditable()
  @Experimental() // nonstandard
  AnimatedRect get viewBox => _blink.Native_SVGViewSpec_viewBox_Getter(this);

  @DomName('SVGViewSpec.zoomAndPan')
  @DocsEditable()
  @Experimental() // nonstandard
  int get zoomAndPan => _blink.Native_SVGViewSpec_zoomAndPan_Getter(this);

  @DomName('SVGViewSpec.zoomAndPan')
  @DocsEditable()
  @Experimental() // nonstandard
  void set zoomAndPan(int value) => _blink.Native_SVGViewSpec_zoomAndPan_Setter(this, value);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGZoomAndPan')
@Unstable()
abstract class ZoomAndPan extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory ZoomAndPan._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGZoomAndPan.SVG_ZOOMANDPAN_DISABLE')
  @DocsEditable()
  static const int SVG_ZOOMANDPAN_DISABLE = 1;

  @DomName('SVGZoomAndPan.SVG_ZOOMANDPAN_MAGNIFY')
  @DocsEditable()
  static const int SVG_ZOOMANDPAN_MAGNIFY = 2;

  @DomName('SVGZoomAndPan.SVG_ZOOMANDPAN_UNKNOWN')
  @DocsEditable()
  static const int SVG_ZOOMANDPAN_UNKNOWN = 0;

  @DomName('SVGZoomAndPan.zoomAndPan')
  @DocsEditable()
  int get zoomAndPan => _blink.Native_SVGZoomAndPan_zoomAndPan_Getter(this);

  @DomName('SVGZoomAndPan.zoomAndPan')
  @DocsEditable()
  void set zoomAndPan(int value) => _blink.Native_SVGZoomAndPan_zoomAndPan_Setter(this, value);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGZoomEvent')
@Unstable()
class ZoomEvent extends UIEvent {
  // To suppress missing implicit constructor warnings.
  factory ZoomEvent._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGZoomEvent.newScale')
  @DocsEditable()
  double get newScale => _blink.Native_SVGZoomEvent_newScale_Getter(this);

  @DomName('SVGZoomEvent.newTranslate')
  @DocsEditable()
  Point get newTranslate => _blink.Native_SVGZoomEvent_newTranslate_Getter(this);

  @DomName('SVGZoomEvent.previousScale')
  @DocsEditable()
  double get previousScale => _blink.Native_SVGZoomEvent_previousScale_Getter(this);

  @DomName('SVGZoomEvent.previousTranslate')
  @DocsEditable()
  Point get previousTranslate => _blink.Native_SVGZoomEvent_previousTranslate_Getter(this);

  @DomName('SVGZoomEvent.zoomRectScreen')
  @DocsEditable()
  Rect get zoomRectScreen => _blink.Native_SVGZoomEvent_zoomRectScreen_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGElementInstanceList')
@Unstable()
class _ElementInstanceList extends NativeFieldWrapperClass2 with ListMixin<ElementInstance>, ImmutableListMixin<ElementInstance> implements List<ElementInstance> {
  // To suppress missing implicit constructor warnings.
  factory _ElementInstanceList._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGElementInstanceList.length')
  @DocsEditable()
  int get length => _blink.Native_SVGElementInstanceList_length_Getter(this);

  ElementInstance operator[](int index) {
    if (index < 0 || index >= length)
      throw new RangeError.range(index, 0, length);
    return _blink.Native_SVGElementInstanceList_NativeIndexed_Getter(this, index);
  }

  ElementInstance _nativeIndexedGetter(int index) => _blink.Native_SVGElementInstanceList_NativeIndexed_Getter(this, index);

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
      return _nativeIndexedGetter(0);
    }
    throw new StateError("No elements");
  }

  ElementInstance get last {
    int len = this.length;
    if (len > 0) {
      return _nativeIndexedGetter(len - 1);
    }
    throw new StateError("No elements");
  }

  ElementInstance get single {
    int len = this.length;
    if (len == 1) {
      return _nativeIndexedGetter(0);
    }
    if (len == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  ElementInstance elementAt(int index) => this[index];
  // -- end List<ElementInstance> mixins.

  @DomName('SVGElementInstanceList.item')
  @DocsEditable()
  ElementInstance item(int index) => _blink.Native_SVGElementInstanceList_item_Callback(this, index);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGGradientElement')
@Unstable()
class _GradientElement extends SvgElement implements UriReference {
  // To suppress missing implicit constructor warnings.
  factory _GradientElement._() { throw new UnsupportedError("Not supported"); }
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  _GradientElement.created() : super.created();

  @DomName('SVGGradientElement.SVG_SPREADMETHOD_PAD')
  @DocsEditable()
  static const int SVG_SPREADMETHOD_PAD = 1;

  @DomName('SVGGradientElement.SVG_SPREADMETHOD_REFLECT')
  @DocsEditable()
  static const int SVG_SPREADMETHOD_REFLECT = 2;

  @DomName('SVGGradientElement.SVG_SPREADMETHOD_REPEAT')
  @DocsEditable()
  static const int SVG_SPREADMETHOD_REPEAT = 3;

  @DomName('SVGGradientElement.SVG_SPREADMETHOD_UNKNOWN')
  @DocsEditable()
  static const int SVG_SPREADMETHOD_UNKNOWN = 0;

  @DomName('SVGGradientElement.gradientTransform')
  @DocsEditable()
  AnimatedTransformList get gradientTransform => _blink.Native_SVGGradientElement_gradientTransform_Getter(this);

  @DomName('SVGGradientElement.gradientUnits')
  @DocsEditable()
  AnimatedEnumeration get gradientUnits => _blink.Native_SVGGradientElement_gradientUnits_Getter(this);

  @DomName('SVGGradientElement.spreadMethod')
  @DocsEditable()
  AnimatedEnumeration get spreadMethod => _blink.Native_SVGGradientElement_spreadMethod_Getter(this);

  @DomName('SVGGradientElement.href')
  @DocsEditable()
  AnimatedString get href => _blink.Native_SVGGradientElement_href_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAltGlyphDefElement')
@Unstable()
abstract class _SVGAltGlyphDefElement extends SvgElement {
  // To suppress missing implicit constructor warnings.
  factory _SVGAltGlyphDefElement._() { throw new UnsupportedError("Not supported"); }
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  _SVGAltGlyphDefElement.created() : super.created();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAltGlyphItemElement')
@Unstable()
abstract class _SVGAltGlyphItemElement extends SvgElement {
  // To suppress missing implicit constructor warnings.
  factory _SVGAltGlyphItemElement._() { throw new UnsupportedError("Not supported"); }
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  _SVGAltGlyphItemElement.created() : super.created();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGComponentTransferFunctionElement')
@Unstable()
abstract class _SVGComponentTransferFunctionElement extends SvgElement {
  // To suppress missing implicit constructor warnings.
  factory _SVGComponentTransferFunctionElement._() { throw new UnsupportedError("Not supported"); }
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  _SVGComponentTransferFunctionElement.created() : super.created();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGCursorElement')
@Unstable()
abstract class _SVGCursorElement extends SvgElement implements UriReference, Tests {
  // To suppress missing implicit constructor warnings.
  factory _SVGCursorElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGCursorElement.SVGCursorElement')
  @DocsEditable()
  factory _SVGCursorElement() => _SvgElementFactoryProvider.createSvgElement_tag("cursor");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  _SVGCursorElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGFEDropShadowElement')
@Experimental() // nonstandard
abstract class _SVGFEDropShadowElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory _SVGFEDropShadowElement._() { throw new UnsupportedError("Not supported"); }
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  _SVGFEDropShadowElement.created() : super.created();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGFontElement')
@Unstable()
abstract class _SVGFontElement extends SvgElement {
  // To suppress missing implicit constructor warnings.
  factory _SVGFontElement._() { throw new UnsupportedError("Not supported"); }
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  _SVGFontElement.created() : super.created();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGFontFaceElement')
@Unstable()
abstract class _SVGFontFaceElement extends SvgElement {
  // To suppress missing implicit constructor warnings.
  factory _SVGFontFaceElement._() { throw new UnsupportedError("Not supported"); }
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  _SVGFontFaceElement.created() : super.created();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGFontFaceFormatElement')
@Unstable()
abstract class _SVGFontFaceFormatElement extends SvgElement {
  // To suppress missing implicit constructor warnings.
  factory _SVGFontFaceFormatElement._() { throw new UnsupportedError("Not supported"); }
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  _SVGFontFaceFormatElement.created() : super.created();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGFontFaceNameElement')
@Unstable()
abstract class _SVGFontFaceNameElement extends SvgElement {
  // To suppress missing implicit constructor warnings.
  factory _SVGFontFaceNameElement._() { throw new UnsupportedError("Not supported"); }
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  _SVGFontFaceNameElement.created() : super.created();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGFontFaceSrcElement')
@Unstable()
abstract class _SVGFontFaceSrcElement extends SvgElement {
  // To suppress missing implicit constructor warnings.
  factory _SVGFontFaceSrcElement._() { throw new UnsupportedError("Not supported"); }
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  _SVGFontFaceSrcElement.created() : super.created();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGFontFaceUriElement')
@Unstable()
abstract class _SVGFontFaceUriElement extends SvgElement {
  // To suppress missing implicit constructor warnings.
  factory _SVGFontFaceUriElement._() { throw new UnsupportedError("Not supported"); }
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  _SVGFontFaceUriElement.created() : super.created();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGGlyphElement')
@Unstable()
abstract class _SVGGlyphElement extends SvgElement {
  // To suppress missing implicit constructor warnings.
  factory _SVGGlyphElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGGlyphElement.SVGGlyphElement')
  @DocsEditable()
  factory _SVGGlyphElement() => _SvgElementFactoryProvider.createSvgElement_tag("glyph");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  _SVGGlyphElement.created() : super.created();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGGlyphRefElement')
@Unstable()
abstract class _SVGGlyphRefElement extends SvgElement implements UriReference {
  // To suppress missing implicit constructor warnings.
  factory _SVGGlyphRefElement._() { throw new UnsupportedError("Not supported"); }
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  _SVGGlyphRefElement.created() : super.created();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGHKernElement')
@Unstable()
abstract class _SVGHKernElement extends SvgElement {
  // To suppress missing implicit constructor warnings.
  factory _SVGHKernElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGHKernElement.SVGHKernElement')
  @DocsEditable()
  factory _SVGHKernElement() => _SvgElementFactoryProvider.createSvgElement_tag("hkern");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  _SVGHKernElement.created() : super.created();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGMPathElement')
abstract class _SVGMPathElement extends SvgElement implements UriReference {
  // To suppress missing implicit constructor warnings.
  factory _SVGMPathElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGMPathElement.SVGMPathElement')
  @DocsEditable()
  factory _SVGMPathElement() => _SvgElementFactoryProvider.createSvgElement_tag("mpath");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  _SVGMPathElement.created() : super.created();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGMissingGlyphElement')
@Unstable()
abstract class _SVGMissingGlyphElement extends SvgElement {
  // To suppress missing implicit constructor warnings.
  factory _SVGMissingGlyphElement._() { throw new UnsupportedError("Not supported"); }
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  _SVGMissingGlyphElement.created() : super.created();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGVKernElement')
@Unstable()
abstract class _SVGVKernElement extends SvgElement {
  // To suppress missing implicit constructor warnings.
  factory _SVGVKernElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGVKernElement.SVGVKernElement')
  @DocsEditable()
  factory _SVGVKernElement() => _SvgElementFactoryProvider.createSvgElement_tag("vkern");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  _SVGVKernElement.created() : super.created();

}
