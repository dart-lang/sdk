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
final svgBlinkMap = {
  'SVGAElement': () => AElement,
  'SVGAltGlyphDefElement': () => _SVGAltGlyphDefElement,
  'SVGAltGlyphElement': () => AltGlyphElement,
  'SVGAltGlyphItemElement': () => _SVGAltGlyphItemElement,
  'SVGAngle': () => Angle,
  'SVGAnimateElement': () => AnimateElement,
  'SVGAnimateMotionElement': () => AnimateMotionElement,
  'SVGAnimateTransformElement': () => AnimateTransformElement,
  'SVGAnimatedAngle': () => AnimatedAngle,
  'SVGAnimatedBoolean': () => AnimatedBoolean,
  'SVGAnimatedEnumeration': () => AnimatedEnumeration,
  'SVGAnimatedInteger': () => AnimatedInteger,
  'SVGAnimatedLength': () => AnimatedLength,
  'SVGAnimatedLengthList': () => AnimatedLengthList,
  'SVGAnimatedNumber': () => AnimatedNumber,
  'SVGAnimatedNumberList': () => AnimatedNumberList,
  'SVGAnimatedPreserveAspectRatio': () => AnimatedPreserveAspectRatio,
  'SVGAnimatedRect': () => AnimatedRect,
  'SVGAnimatedString': () => AnimatedString,
  'SVGAnimatedTransformList': () => AnimatedTransformList,
  'SVGAnimationElement': () => AnimationElement,
  'SVGCircleElement': () => CircleElement,
  'SVGClipPathElement': () => ClipPathElement,
  'SVGComponentTransferFunctionElement': () => _SVGComponentTransferFunctionElement,
  'SVGCursorElement': () => _SVGCursorElement,
  'SVGDefsElement': () => DefsElement,
  'SVGDescElement': () => DescElement,
  'SVGDiscardElement': () => DiscardElement,
  'SVGElement': () => SvgElement,
  'SVGElementInstance': () => ElementInstance,
  'SVGElementInstanceList': () => _ElementInstanceList,
  'SVGEllipseElement': () => EllipseElement,
  'SVGFEBlendElement': () => FEBlendElement,
  'SVGFEColorMatrixElement': () => FEColorMatrixElement,
  'SVGFEComponentTransferElement': () => FEComponentTransferElement,
  'SVGFECompositeElement': () => FECompositeElement,
  'SVGFEConvolveMatrixElement': () => FEConvolveMatrixElement,
  'SVGFEDiffuseLightingElement': () => FEDiffuseLightingElement,
  'SVGFEDisplacementMapElement': () => FEDisplacementMapElement,
  'SVGFEDistantLightElement': () => FEDistantLightElement,
  'SVGFEDropShadowElement': () => _SVGFEDropShadowElement,
  'SVGFEFloodElement': () => FEFloodElement,
  'SVGFEFuncAElement': () => FEFuncAElement,
  'SVGFEFuncBElement': () => FEFuncBElement,
  'SVGFEFuncGElement': () => FEFuncGElement,
  'SVGFEFuncRElement': () => FEFuncRElement,
  'SVGFEGaussianBlurElement': () => FEGaussianBlurElement,
  'SVGFEImageElement': () => FEImageElement,
  'SVGFEMergeElement': () => FEMergeElement,
  'SVGFEMergeNodeElement': () => FEMergeNodeElement,
  'SVGFEMorphologyElement': () => FEMorphologyElement,
  'SVGFEOffsetElement': () => FEOffsetElement,
  'SVGFEPointLightElement': () => FEPointLightElement,
  'SVGFESpecularLightingElement': () => FESpecularLightingElement,
  'SVGFESpotLightElement': () => FESpotLightElement,
  'SVGFETileElement': () => FETileElement,
  'SVGFETurbulenceElement': () => FETurbulenceElement,
  'SVGFilterElement': () => FilterElement,
  'SVGFilterPrimitiveStandardAttributes': () => FilterPrimitiveStandardAttributes,
  'SVGFitToViewBox': () => FitToViewBox,
  'SVGFontElement': () => _SVGFontElement,
  'SVGFontFaceElement': () => _SVGFontFaceElement,
  'SVGFontFaceFormatElement': () => _SVGFontFaceFormatElement,
  'SVGFontFaceNameElement': () => _SVGFontFaceNameElement,
  'SVGFontFaceSrcElement': () => _SVGFontFaceSrcElement,
  'SVGFontFaceUriElement': () => _SVGFontFaceUriElement,
  'SVGForeignObjectElement': () => ForeignObjectElement,
  'SVGGElement': () => GElement,
  'SVGGeometryElement': () => GeometryElement,
  'SVGGlyphElement': () => _SVGGlyphElement,
  'SVGGlyphRefElement': () => _SVGGlyphRefElement,
  'SVGGradientElement': () => _GradientElement,
  'SVGGraphicsElement': () => GraphicsElement,
  'SVGHKernElement': () => _SVGHKernElement,
  'SVGImageElement': () => ImageElement,
  'SVGLength': () => Length,
  'SVGLengthList': () => LengthList,
  'SVGLineElement': () => LineElement,
  'SVGLinearGradientElement': () => LinearGradientElement,
  'SVGMPathElement': () => _SVGMPathElement,
  'SVGMarkerElement': () => MarkerElement,
  'SVGMaskElement': () => MaskElement,
  'SVGMatrix': () => Matrix,
  'SVGMetadataElement': () => MetadataElement,
  'SVGMissingGlyphElement': () => _SVGMissingGlyphElement,
  'SVGNumber': () => Number,
  'SVGNumberList': () => NumberList,
  'SVGPathElement': () => PathElement,
  'SVGPathSeg': () => PathSeg,
  'SVGPathSegArcAbs': () => PathSegArcAbs,
  'SVGPathSegArcRel': () => PathSegArcRel,
  'SVGPathSegClosePath': () => PathSegClosePath,
  'SVGPathSegCurvetoCubicAbs': () => PathSegCurvetoCubicAbs,
  'SVGPathSegCurvetoCubicRel': () => PathSegCurvetoCubicRel,
  'SVGPathSegCurvetoCubicSmoothAbs': () => PathSegCurvetoCubicSmoothAbs,
  'SVGPathSegCurvetoCubicSmoothRel': () => PathSegCurvetoCubicSmoothRel,
  'SVGPathSegCurvetoQuadraticAbs': () => PathSegCurvetoQuadraticAbs,
  'SVGPathSegCurvetoQuadraticRel': () => PathSegCurvetoQuadraticRel,
  'SVGPathSegCurvetoQuadraticSmoothAbs': () => PathSegCurvetoQuadraticSmoothAbs,
  'SVGPathSegCurvetoQuadraticSmoothRel': () => PathSegCurvetoQuadraticSmoothRel,
  'SVGPathSegLinetoAbs': () => PathSegLinetoAbs,
  'SVGPathSegLinetoHorizontalAbs': () => PathSegLinetoHorizontalAbs,
  'SVGPathSegLinetoHorizontalRel': () => PathSegLinetoHorizontalRel,
  'SVGPathSegLinetoRel': () => PathSegLinetoRel,
  'SVGPathSegLinetoVerticalAbs': () => PathSegLinetoVerticalAbs,
  'SVGPathSegLinetoVerticalRel': () => PathSegLinetoVerticalRel,
  'SVGPathSegList': () => PathSegList,
  'SVGPathSegMovetoAbs': () => PathSegMovetoAbs,
  'SVGPathSegMovetoRel': () => PathSegMovetoRel,
  'SVGPatternElement': () => PatternElement,
  'SVGPoint': () => Point,
  'SVGPointList': () => PointList,
  'SVGPolygonElement': () => PolygonElement,
  'SVGPolylineElement': () => PolylineElement,
  'SVGPreserveAspectRatio': () => PreserveAspectRatio,
  'SVGRadialGradientElement': () => RadialGradientElement,
  'SVGRect': () => Rect,
  'SVGRectElement': () => RectElement,
  'SVGRenderingIntent': () => RenderingIntent,
  'SVGSVGElement': () => SvgSvgElement,
  'SVGScriptElement': () => ScriptElement,
  'SVGSetElement': () => SetElement,
  'SVGStopElement': () => StopElement,
  'SVGStringList': () => StringList,
  'SVGStyleElement': () => StyleElement,
  'SVGSwitchElement': () => SwitchElement,
  'SVGSymbolElement': () => SymbolElement,
  'SVGTSpanElement': () => TSpanElement,
  'SVGTests': () => Tests,
  'SVGTextContentElement': () => TextContentElement,
  'SVGTextElement': () => TextElement,
  'SVGTextPathElement': () => TextPathElement,
  'SVGTextPositioningElement': () => TextPositioningElement,
  'SVGTitleElement': () => TitleElement,
  'SVGTransform': () => Transform,
  'SVGTransformList': () => TransformList,
  'SVGURIReference': () => UriReference,
  'SVGUnitTypes': () => UnitTypes,
  'SVGUseElement': () => UseElement,
  'SVGVKernElement': () => _SVGVKernElement,
  'SVGViewElement': () => ViewElement,
  'SVGViewSpec': () => ViewSpec,
  'SVGZoomAndPan': () => ZoomAndPan,
  'SVGZoomEvent': () => ZoomEvent,

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
  AnimatedString get target => _blink.BlinkSVGAElement.$target_Getter(this);

  @DomName('SVGAElement.href')
  @DocsEditable()
  AnimatedString get href => _blink.BlinkSVGAElement.$href_Getter(this);

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
  String get format => _blink.BlinkSVGAltGlyphElement.$format_Getter(this);

  @DomName('SVGAltGlyphElement.format')
  @DocsEditable()
  void set format(String value) => _blink.BlinkSVGAltGlyphElement.$format_Setter(this, value);

  @DomName('SVGAltGlyphElement.glyphRef')
  @DocsEditable()
  String get glyphRef => _blink.BlinkSVGAltGlyphElement.$glyphRef_Getter(this);

  @DomName('SVGAltGlyphElement.glyphRef')
  @DocsEditable()
  void set glyphRef(String value) => _blink.BlinkSVGAltGlyphElement.$glyphRef_Setter(this, value);

  @DomName('SVGAltGlyphElement.href')
  @DocsEditable()
  AnimatedString get href => _blink.BlinkSVGAltGlyphElement.$href_Getter(this);

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
  int get unitType => _blink.BlinkSVGAngle.$unitType_Getter(this);

  @DomName('SVGAngle.value')
  @DocsEditable()
  num get value => _blink.BlinkSVGAngle.$value_Getter(this);

  @DomName('SVGAngle.value')
  @DocsEditable()
  void set value(num value) => _blink.BlinkSVGAngle.$value_Setter(this, value);

  @DomName('SVGAngle.valueAsString')
  @DocsEditable()
  String get valueAsString => _blink.BlinkSVGAngle.$valueAsString_Getter(this);

  @DomName('SVGAngle.valueAsString')
  @DocsEditable()
  void set valueAsString(String value) => _blink.BlinkSVGAngle.$valueAsString_Setter(this, value);

  @DomName('SVGAngle.valueInSpecifiedUnits')
  @DocsEditable()
  num get valueInSpecifiedUnits => _blink.BlinkSVGAngle.$valueInSpecifiedUnits_Getter(this);

  @DomName('SVGAngle.valueInSpecifiedUnits')
  @DocsEditable()
  void set valueInSpecifiedUnits(num value) => _blink.BlinkSVGAngle.$valueInSpecifiedUnits_Setter(this, value);

  @DomName('SVGAngle.convertToSpecifiedUnits')
  @DocsEditable()
  void convertToSpecifiedUnits(int unitType) => _blink.BlinkSVGAngle.$convertToSpecifiedUnits_Callback(this, unitType);

  @DomName('SVGAngle.newValueSpecifiedUnits')
  @DocsEditable()
  void newValueSpecifiedUnits(int unitType, num valueInSpecifiedUnits) => _blink.BlinkSVGAngle.$newValueSpecifiedUnits_Callback(this, unitType, valueInSpecifiedUnits);

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
  Angle get animVal => _blink.BlinkSVGAnimatedAngle.$animVal_Getter(this);

  @DomName('SVGAnimatedAngle.baseVal')
  @DocsEditable()
  Angle get baseVal => _blink.BlinkSVGAnimatedAngle.$baseVal_Getter(this);

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
  bool get animVal => _blink.BlinkSVGAnimatedBoolean.$animVal_Getter(this);

  @DomName('SVGAnimatedBoolean.baseVal')
  @DocsEditable()
  bool get baseVal => _blink.BlinkSVGAnimatedBoolean.$baseVal_Getter(this);

  @DomName('SVGAnimatedBoolean.baseVal')
  @DocsEditable()
  void set baseVal(bool value) => _blink.BlinkSVGAnimatedBoolean.$baseVal_Setter(this, value);

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
  int get animVal => _blink.BlinkSVGAnimatedEnumeration.$animVal_Getter(this);

  @DomName('SVGAnimatedEnumeration.baseVal')
  @DocsEditable()
  int get baseVal => _blink.BlinkSVGAnimatedEnumeration.$baseVal_Getter(this);

  @DomName('SVGAnimatedEnumeration.baseVal')
  @DocsEditable()
  void set baseVal(int value) => _blink.BlinkSVGAnimatedEnumeration.$baseVal_Setter(this, value);

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
  int get animVal => _blink.BlinkSVGAnimatedInteger.$animVal_Getter(this);

  @DomName('SVGAnimatedInteger.baseVal')
  @DocsEditable()
  int get baseVal => _blink.BlinkSVGAnimatedInteger.$baseVal_Getter(this);

  @DomName('SVGAnimatedInteger.baseVal')
  @DocsEditable()
  void set baseVal(int value) => _blink.BlinkSVGAnimatedInteger.$baseVal_Setter(this, value);

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
  Length get animVal => _blink.BlinkSVGAnimatedLength.$animVal_Getter(this);

  @DomName('SVGAnimatedLength.baseVal')
  @DocsEditable()
  Length get baseVal => _blink.BlinkSVGAnimatedLength.$baseVal_Getter(this);

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
  LengthList get animVal => _blink.BlinkSVGAnimatedLengthList.$animVal_Getter(this);

  @DomName('SVGAnimatedLengthList.baseVal')
  @DocsEditable()
  LengthList get baseVal => _blink.BlinkSVGAnimatedLengthList.$baseVal_Getter(this);

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
  double get animVal => _blink.BlinkSVGAnimatedNumber.$animVal_Getter(this);

  @DomName('SVGAnimatedNumber.baseVal')
  @DocsEditable()
  num get baseVal => _blink.BlinkSVGAnimatedNumber.$baseVal_Getter(this);

  @DomName('SVGAnimatedNumber.baseVal')
  @DocsEditable()
  void set baseVal(num value) => _blink.BlinkSVGAnimatedNumber.$baseVal_Setter(this, value);

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
  NumberList get animVal => _blink.BlinkSVGAnimatedNumberList.$animVal_Getter(this);

  @DomName('SVGAnimatedNumberList.baseVal')
  @DocsEditable()
  NumberList get baseVal => _blink.BlinkSVGAnimatedNumberList.$baseVal_Getter(this);

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
  PreserveAspectRatio get animVal => _blink.BlinkSVGAnimatedPreserveAspectRatio.$animVal_Getter(this);

  @DomName('SVGAnimatedPreserveAspectRatio.baseVal')
  @DocsEditable()
  PreserveAspectRatio get baseVal => _blink.BlinkSVGAnimatedPreserveAspectRatio.$baseVal_Getter(this);

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
  Rect get animVal => _blink.BlinkSVGAnimatedRect.$animVal_Getter(this);

  @DomName('SVGAnimatedRect.baseVal')
  @DocsEditable()
  Rect get baseVal => _blink.BlinkSVGAnimatedRect.$baseVal_Getter(this);

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
  String get animVal => _blink.BlinkSVGAnimatedString.$animVal_Getter(this);

  @DomName('SVGAnimatedString.baseVal')
  @DocsEditable()
  String get baseVal => _blink.BlinkSVGAnimatedString.$baseVal_Getter(this);

  @DomName('SVGAnimatedString.baseVal')
  @DocsEditable()
  void set baseVal(String value) => _blink.BlinkSVGAnimatedString.$baseVal_Setter(this, value);

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
  TransformList get animVal => _blink.BlinkSVGAnimatedTransformList.$animVal_Getter(this);

  @DomName('SVGAnimatedTransformList.baseVal')
  @DocsEditable()
  TransformList get baseVal => _blink.BlinkSVGAnimatedTransformList.$baseVal_Getter(this);

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
  SvgElement get targetElement => _blink.BlinkSVGAnimationElement.$targetElement_Getter(this);

  @DomName('SVGAnimationElement.beginElement')
  @DocsEditable()
  void beginElement() => _blink.BlinkSVGAnimationElement.$beginElement_Callback(this);

  @DomName('SVGAnimationElement.beginElementAt')
  @DocsEditable()
  void beginElementAt(num offset) => _blink.BlinkSVGAnimationElement.$beginElementAt_Callback(this, offset);

  @DomName('SVGAnimationElement.endElement')
  @DocsEditable()
  void endElement() => _blink.BlinkSVGAnimationElement.$endElement_Callback(this);

  @DomName('SVGAnimationElement.endElementAt')
  @DocsEditable()
  void endElementAt(num offset) => _blink.BlinkSVGAnimationElement.$endElementAt_Callback(this, offset);

  @DomName('SVGAnimationElement.getCurrentTime')
  @DocsEditable()
  double getCurrentTime() => _blink.BlinkSVGAnimationElement.$getCurrentTime_Callback(this);

  @DomName('SVGAnimationElement.getSimpleDuration')
  @DocsEditable()
  double getSimpleDuration() => _blink.BlinkSVGAnimationElement.$getSimpleDuration_Callback(this);

  @DomName('SVGAnimationElement.getStartTime')
  @DocsEditable()
  double getStartTime() => _blink.BlinkSVGAnimationElement.$getStartTime_Callback(this);

  @DomName('SVGAnimationElement.requiredExtensions')
  @DocsEditable()
  StringList get requiredExtensions => _blink.BlinkSVGAnimationElement.$requiredExtensions_Getter(this);

  @DomName('SVGAnimationElement.requiredFeatures')
  @DocsEditable()
  StringList get requiredFeatures => _blink.BlinkSVGAnimationElement.$requiredFeatures_Getter(this);

  @DomName('SVGAnimationElement.systemLanguage')
  @DocsEditable()
  StringList get systemLanguage => _blink.BlinkSVGAnimationElement.$systemLanguage_Getter(this);

  @DomName('SVGAnimationElement.hasExtension')
  @DocsEditable()
  bool hasExtension(String extension) => _blink.BlinkSVGAnimationElement.$hasExtension_Callback(this, extension);

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
  AnimatedLength get cx => _blink.BlinkSVGCircleElement.$cx_Getter(this);

  @DomName('SVGCircleElement.cy')
  @DocsEditable()
  AnimatedLength get cy => _blink.BlinkSVGCircleElement.$cy_Getter(this);

  @DomName('SVGCircleElement.r')
  @DocsEditable()
  AnimatedLength get r => _blink.BlinkSVGCircleElement.$r_Getter(this);

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
  AnimatedEnumeration get clipPathUnits => _blink.BlinkSVGClipPathElement.$clipPathUnits_Getter(this);

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
  SvgElement get correspondingElement => _blink.BlinkSVGElementInstance.$correspondingElement_Getter(this);

  @DomName('SVGElementInstance.correspondingUseElement')
  @DocsEditable()
  UseElement get correspondingUseElement => _blink.BlinkSVGElementInstance.$correspondingUseElement_Getter(this);

  @DomName('SVGElementInstance.firstChild')
  @DocsEditable()
  ElementInstance get firstChild => _blink.BlinkSVGElementInstance.$firstChild_Getter(this);

  @DomName('SVGElementInstance.lastChild')
  @DocsEditable()
  ElementInstance get lastChild => _blink.BlinkSVGElementInstance.$lastChild_Getter(this);

  @DomName('SVGElementInstance.nextSibling')
  @DocsEditable()
  ElementInstance get nextSibling => _blink.BlinkSVGElementInstance.$nextSibling_Getter(this);

  @DomName('SVGElementInstance.parentNode')
  @DocsEditable()
  ElementInstance get parentNode => _blink.BlinkSVGElementInstance.$parentNode_Getter(this);

  @DomName('SVGElementInstance.previousSibling')
  @DocsEditable()
  ElementInstance get previousSibling => _blink.BlinkSVGElementInstance.$previousSibling_Getter(this);

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
  AnimatedLength get cx => _blink.BlinkSVGEllipseElement.$cx_Getter(this);

  @DomName('SVGEllipseElement.cy')
  @DocsEditable()
  AnimatedLength get cy => _blink.BlinkSVGEllipseElement.$cy_Getter(this);

  @DomName('SVGEllipseElement.rx')
  @DocsEditable()
  AnimatedLength get rx => _blink.BlinkSVGEllipseElement.$rx_Getter(this);

  @DomName('SVGEllipseElement.ry')
  @DocsEditable()
  AnimatedLength get ry => _blink.BlinkSVGEllipseElement.$ry_Getter(this);

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
  AnimatedString get in1 => _blink.BlinkSVGFEBlendElement.$in1_Getter(this);

  @DomName('SVGFEBlendElement.in2')
  @DocsEditable()
  AnimatedString get in2 => _blink.BlinkSVGFEBlendElement.$in2_Getter(this);

  @DomName('SVGFEBlendElement.mode')
  @DocsEditable()
  AnimatedEnumeration get mode => _blink.BlinkSVGFEBlendElement.$mode_Getter(this);

  @DomName('SVGFEBlendElement.height')
  @DocsEditable()
  AnimatedLength get height => _blink.BlinkSVGFEBlendElement.$height_Getter(this);

  @DomName('SVGFEBlendElement.result')
  @DocsEditable()
  AnimatedString get result => _blink.BlinkSVGFEBlendElement.$result_Getter(this);

  @DomName('SVGFEBlendElement.width')
  @DocsEditable()
  AnimatedLength get width => _blink.BlinkSVGFEBlendElement.$width_Getter(this);

  @DomName('SVGFEBlendElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.BlinkSVGFEBlendElement.$x_Getter(this);

  @DomName('SVGFEBlendElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.BlinkSVGFEBlendElement.$y_Getter(this);

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
  AnimatedString get in1 => _blink.BlinkSVGFEColorMatrixElement.$in1_Getter(this);

  @DomName('SVGFEColorMatrixElement.type')
  @DocsEditable()
  AnimatedEnumeration get type => _blink.BlinkSVGFEColorMatrixElement.$type_Getter(this);

  @DomName('SVGFEColorMatrixElement.values')
  @DocsEditable()
  AnimatedNumberList get values => _blink.BlinkSVGFEColorMatrixElement.$values_Getter(this);

  @DomName('SVGFEColorMatrixElement.height')
  @DocsEditable()
  AnimatedLength get height => _blink.BlinkSVGFEColorMatrixElement.$height_Getter(this);

  @DomName('SVGFEColorMatrixElement.result')
  @DocsEditable()
  AnimatedString get result => _blink.BlinkSVGFEColorMatrixElement.$result_Getter(this);

  @DomName('SVGFEColorMatrixElement.width')
  @DocsEditable()
  AnimatedLength get width => _blink.BlinkSVGFEColorMatrixElement.$width_Getter(this);

  @DomName('SVGFEColorMatrixElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.BlinkSVGFEColorMatrixElement.$x_Getter(this);

  @DomName('SVGFEColorMatrixElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.BlinkSVGFEColorMatrixElement.$y_Getter(this);

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
  AnimatedString get in1 => _blink.BlinkSVGFEComponentTransferElement.$in1_Getter(this);

  @DomName('SVGFEComponentTransferElement.height')
  @DocsEditable()
  AnimatedLength get height => _blink.BlinkSVGFEComponentTransferElement.$height_Getter(this);

  @DomName('SVGFEComponentTransferElement.result')
  @DocsEditable()
  AnimatedString get result => _blink.BlinkSVGFEComponentTransferElement.$result_Getter(this);

  @DomName('SVGFEComponentTransferElement.width')
  @DocsEditable()
  AnimatedLength get width => _blink.BlinkSVGFEComponentTransferElement.$width_Getter(this);

  @DomName('SVGFEComponentTransferElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.BlinkSVGFEComponentTransferElement.$x_Getter(this);

  @DomName('SVGFEComponentTransferElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.BlinkSVGFEComponentTransferElement.$y_Getter(this);

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
  AnimatedString get in1 => _blink.BlinkSVGFECompositeElement.$in1_Getter(this);

  @DomName('SVGFECompositeElement.in2')
  @DocsEditable()
  AnimatedString get in2 => _blink.BlinkSVGFECompositeElement.$in2_Getter(this);

  @DomName('SVGFECompositeElement.k1')
  @DocsEditable()
  AnimatedNumber get k1 => _blink.BlinkSVGFECompositeElement.$k1_Getter(this);

  @DomName('SVGFECompositeElement.k2')
  @DocsEditable()
  AnimatedNumber get k2 => _blink.BlinkSVGFECompositeElement.$k2_Getter(this);

  @DomName('SVGFECompositeElement.k3')
  @DocsEditable()
  AnimatedNumber get k3 => _blink.BlinkSVGFECompositeElement.$k3_Getter(this);

  @DomName('SVGFECompositeElement.k4')
  @DocsEditable()
  AnimatedNumber get k4 => _blink.BlinkSVGFECompositeElement.$k4_Getter(this);

  @DomName('SVGFECompositeElement.operator')
  @DocsEditable()
  AnimatedEnumeration get operator => _blink.BlinkSVGFECompositeElement.$operator_Getter(this);

  @DomName('SVGFECompositeElement.height')
  @DocsEditable()
  AnimatedLength get height => _blink.BlinkSVGFECompositeElement.$height_Getter(this);

  @DomName('SVGFECompositeElement.result')
  @DocsEditable()
  AnimatedString get result => _blink.BlinkSVGFECompositeElement.$result_Getter(this);

  @DomName('SVGFECompositeElement.width')
  @DocsEditable()
  AnimatedLength get width => _blink.BlinkSVGFECompositeElement.$width_Getter(this);

  @DomName('SVGFECompositeElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.BlinkSVGFECompositeElement.$x_Getter(this);

  @DomName('SVGFECompositeElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.BlinkSVGFECompositeElement.$y_Getter(this);

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
  AnimatedNumber get bias => _blink.BlinkSVGFEConvolveMatrixElement.$bias_Getter(this);

  @DomName('SVGFEConvolveMatrixElement.divisor')
  @DocsEditable()
  AnimatedNumber get divisor => _blink.BlinkSVGFEConvolveMatrixElement.$divisor_Getter(this);

  @DomName('SVGFEConvolveMatrixElement.edgeMode')
  @DocsEditable()
  AnimatedEnumeration get edgeMode => _blink.BlinkSVGFEConvolveMatrixElement.$edgeMode_Getter(this);

  @DomName('SVGFEConvolveMatrixElement.in1')
  @DocsEditable()
  AnimatedString get in1 => _blink.BlinkSVGFEConvolveMatrixElement.$in1_Getter(this);

  @DomName('SVGFEConvolveMatrixElement.kernelMatrix')
  @DocsEditable()
  AnimatedNumberList get kernelMatrix => _blink.BlinkSVGFEConvolveMatrixElement.$kernelMatrix_Getter(this);

  @DomName('SVGFEConvolveMatrixElement.kernelUnitLengthX')
  @DocsEditable()
  AnimatedNumber get kernelUnitLengthX => _blink.BlinkSVGFEConvolveMatrixElement.$kernelUnitLengthX_Getter(this);

  @DomName('SVGFEConvolveMatrixElement.kernelUnitLengthY')
  @DocsEditable()
  AnimatedNumber get kernelUnitLengthY => _blink.BlinkSVGFEConvolveMatrixElement.$kernelUnitLengthY_Getter(this);

  @DomName('SVGFEConvolveMatrixElement.orderX')
  @DocsEditable()
  AnimatedInteger get orderX => _blink.BlinkSVGFEConvolveMatrixElement.$orderX_Getter(this);

  @DomName('SVGFEConvolveMatrixElement.orderY')
  @DocsEditable()
  AnimatedInteger get orderY => _blink.BlinkSVGFEConvolveMatrixElement.$orderY_Getter(this);

  @DomName('SVGFEConvolveMatrixElement.preserveAlpha')
  @DocsEditable()
  AnimatedBoolean get preserveAlpha => _blink.BlinkSVGFEConvolveMatrixElement.$preserveAlpha_Getter(this);

  @DomName('SVGFEConvolveMatrixElement.targetX')
  @DocsEditable()
  AnimatedInteger get targetX => _blink.BlinkSVGFEConvolveMatrixElement.$targetX_Getter(this);

  @DomName('SVGFEConvolveMatrixElement.targetY')
  @DocsEditable()
  AnimatedInteger get targetY => _blink.BlinkSVGFEConvolveMatrixElement.$targetY_Getter(this);

  @DomName('SVGFEConvolveMatrixElement.height')
  @DocsEditable()
  AnimatedLength get height => _blink.BlinkSVGFEConvolveMatrixElement.$height_Getter(this);

  @DomName('SVGFEConvolveMatrixElement.result')
  @DocsEditable()
  AnimatedString get result => _blink.BlinkSVGFEConvolveMatrixElement.$result_Getter(this);

  @DomName('SVGFEConvolveMatrixElement.width')
  @DocsEditable()
  AnimatedLength get width => _blink.BlinkSVGFEConvolveMatrixElement.$width_Getter(this);

  @DomName('SVGFEConvolveMatrixElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.BlinkSVGFEConvolveMatrixElement.$x_Getter(this);

  @DomName('SVGFEConvolveMatrixElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.BlinkSVGFEConvolveMatrixElement.$y_Getter(this);

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
  AnimatedNumber get diffuseConstant => _blink.BlinkSVGFEDiffuseLightingElement.$diffuseConstant_Getter(this);

  @DomName('SVGFEDiffuseLightingElement.in1')
  @DocsEditable()
  AnimatedString get in1 => _blink.BlinkSVGFEDiffuseLightingElement.$in1_Getter(this);

  @DomName('SVGFEDiffuseLightingElement.kernelUnitLengthX')
  @DocsEditable()
  AnimatedNumber get kernelUnitLengthX => _blink.BlinkSVGFEDiffuseLightingElement.$kernelUnitLengthX_Getter(this);

  @DomName('SVGFEDiffuseLightingElement.kernelUnitLengthY')
  @DocsEditable()
  AnimatedNumber get kernelUnitLengthY => _blink.BlinkSVGFEDiffuseLightingElement.$kernelUnitLengthY_Getter(this);

  @DomName('SVGFEDiffuseLightingElement.surfaceScale')
  @DocsEditable()
  AnimatedNumber get surfaceScale => _blink.BlinkSVGFEDiffuseLightingElement.$surfaceScale_Getter(this);

  @DomName('SVGFEDiffuseLightingElement.height')
  @DocsEditable()
  AnimatedLength get height => _blink.BlinkSVGFEDiffuseLightingElement.$height_Getter(this);

  @DomName('SVGFEDiffuseLightingElement.result')
  @DocsEditable()
  AnimatedString get result => _blink.BlinkSVGFEDiffuseLightingElement.$result_Getter(this);

  @DomName('SVGFEDiffuseLightingElement.width')
  @DocsEditable()
  AnimatedLength get width => _blink.BlinkSVGFEDiffuseLightingElement.$width_Getter(this);

  @DomName('SVGFEDiffuseLightingElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.BlinkSVGFEDiffuseLightingElement.$x_Getter(this);

  @DomName('SVGFEDiffuseLightingElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.BlinkSVGFEDiffuseLightingElement.$y_Getter(this);

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
  AnimatedString get in1 => _blink.BlinkSVGFEDisplacementMapElement.$in1_Getter(this);

  @DomName('SVGFEDisplacementMapElement.in2')
  @DocsEditable()
  AnimatedString get in2 => _blink.BlinkSVGFEDisplacementMapElement.$in2_Getter(this);

  @DomName('SVGFEDisplacementMapElement.scale')
  @DocsEditable()
  AnimatedNumber get scale => _blink.BlinkSVGFEDisplacementMapElement.$scale_Getter(this);

  @DomName('SVGFEDisplacementMapElement.xChannelSelector')
  @DocsEditable()
  AnimatedEnumeration get xChannelSelector => _blink.BlinkSVGFEDisplacementMapElement.$xChannelSelector_Getter(this);

  @DomName('SVGFEDisplacementMapElement.yChannelSelector')
  @DocsEditable()
  AnimatedEnumeration get yChannelSelector => _blink.BlinkSVGFEDisplacementMapElement.$yChannelSelector_Getter(this);

  @DomName('SVGFEDisplacementMapElement.height')
  @DocsEditable()
  AnimatedLength get height => _blink.BlinkSVGFEDisplacementMapElement.$height_Getter(this);

  @DomName('SVGFEDisplacementMapElement.result')
  @DocsEditable()
  AnimatedString get result => _blink.BlinkSVGFEDisplacementMapElement.$result_Getter(this);

  @DomName('SVGFEDisplacementMapElement.width')
  @DocsEditable()
  AnimatedLength get width => _blink.BlinkSVGFEDisplacementMapElement.$width_Getter(this);

  @DomName('SVGFEDisplacementMapElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.BlinkSVGFEDisplacementMapElement.$x_Getter(this);

  @DomName('SVGFEDisplacementMapElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.BlinkSVGFEDisplacementMapElement.$y_Getter(this);

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
  AnimatedNumber get azimuth => _blink.BlinkSVGFEDistantLightElement.$azimuth_Getter(this);

  @DomName('SVGFEDistantLightElement.elevation')
  @DocsEditable()
  AnimatedNumber get elevation => _blink.BlinkSVGFEDistantLightElement.$elevation_Getter(this);

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
  AnimatedLength get height => _blink.BlinkSVGFEFloodElement.$height_Getter(this);

  @DomName('SVGFEFloodElement.result')
  @DocsEditable()
  AnimatedString get result => _blink.BlinkSVGFEFloodElement.$result_Getter(this);

  @DomName('SVGFEFloodElement.width')
  @DocsEditable()
  AnimatedLength get width => _blink.BlinkSVGFEFloodElement.$width_Getter(this);

  @DomName('SVGFEFloodElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.BlinkSVGFEFloodElement.$x_Getter(this);

  @DomName('SVGFEFloodElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.BlinkSVGFEFloodElement.$y_Getter(this);

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
  AnimatedString get in1 => _blink.BlinkSVGFEGaussianBlurElement.$in1_Getter(this);

  @DomName('SVGFEGaussianBlurElement.stdDeviationX')
  @DocsEditable()
  AnimatedNumber get stdDeviationX => _blink.BlinkSVGFEGaussianBlurElement.$stdDeviationX_Getter(this);

  @DomName('SVGFEGaussianBlurElement.stdDeviationY')
  @DocsEditable()
  AnimatedNumber get stdDeviationY => _blink.BlinkSVGFEGaussianBlurElement.$stdDeviationY_Getter(this);

  @DomName('SVGFEGaussianBlurElement.setStdDeviation')
  @DocsEditable()
  void setStdDeviation(num stdDeviationX, num stdDeviationY) => _blink.BlinkSVGFEGaussianBlurElement.$setStdDeviation_Callback(this, stdDeviationX, stdDeviationY);

  @DomName('SVGFEGaussianBlurElement.height')
  @DocsEditable()
  AnimatedLength get height => _blink.BlinkSVGFEGaussianBlurElement.$height_Getter(this);

  @DomName('SVGFEGaussianBlurElement.result')
  @DocsEditable()
  AnimatedString get result => _blink.BlinkSVGFEGaussianBlurElement.$result_Getter(this);

  @DomName('SVGFEGaussianBlurElement.width')
  @DocsEditable()
  AnimatedLength get width => _blink.BlinkSVGFEGaussianBlurElement.$width_Getter(this);

  @DomName('SVGFEGaussianBlurElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.BlinkSVGFEGaussianBlurElement.$x_Getter(this);

  @DomName('SVGFEGaussianBlurElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.BlinkSVGFEGaussianBlurElement.$y_Getter(this);

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
  AnimatedPreserveAspectRatio get preserveAspectRatio => _blink.BlinkSVGFEImageElement.$preserveAspectRatio_Getter(this);

  @DomName('SVGFEImageElement.height')
  @DocsEditable()
  AnimatedLength get height => _blink.BlinkSVGFEImageElement.$height_Getter(this);

  @DomName('SVGFEImageElement.result')
  @DocsEditable()
  AnimatedString get result => _blink.BlinkSVGFEImageElement.$result_Getter(this);

  @DomName('SVGFEImageElement.width')
  @DocsEditable()
  AnimatedLength get width => _blink.BlinkSVGFEImageElement.$width_Getter(this);

  @DomName('SVGFEImageElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.BlinkSVGFEImageElement.$x_Getter(this);

  @DomName('SVGFEImageElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.BlinkSVGFEImageElement.$y_Getter(this);

  @DomName('SVGFEImageElement.href')
  @DocsEditable()
  AnimatedString get href => _blink.BlinkSVGFEImageElement.$href_Getter(this);

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
  AnimatedLength get height => _blink.BlinkSVGFEMergeElement.$height_Getter(this);

  @DomName('SVGFEMergeElement.result')
  @DocsEditable()
  AnimatedString get result => _blink.BlinkSVGFEMergeElement.$result_Getter(this);

  @DomName('SVGFEMergeElement.width')
  @DocsEditable()
  AnimatedLength get width => _blink.BlinkSVGFEMergeElement.$width_Getter(this);

  @DomName('SVGFEMergeElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.BlinkSVGFEMergeElement.$x_Getter(this);

  @DomName('SVGFEMergeElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.BlinkSVGFEMergeElement.$y_Getter(this);

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
  AnimatedString get in1 => _blink.BlinkSVGFEMergeNodeElement.$in1_Getter(this);

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
  AnimatedString get in1 => _blink.BlinkSVGFEMorphologyElement.$in1_Getter(this);

  @DomName('SVGFEMorphologyElement.operator')
  @DocsEditable()
  AnimatedEnumeration get operator => _blink.BlinkSVGFEMorphologyElement.$operator_Getter(this);

  @DomName('SVGFEMorphologyElement.radiusX')
  @DocsEditable()
  AnimatedNumber get radiusX => _blink.BlinkSVGFEMorphologyElement.$radiusX_Getter(this);

  @DomName('SVGFEMorphologyElement.radiusY')
  @DocsEditable()
  AnimatedNumber get radiusY => _blink.BlinkSVGFEMorphologyElement.$radiusY_Getter(this);

  @DomName('SVGFEMorphologyElement.setRadius')
  @DocsEditable()
  void setRadius(num radiusX, num radiusY) => _blink.BlinkSVGFEMorphologyElement.$setRadius_Callback(this, radiusX, radiusY);

  @DomName('SVGFEMorphologyElement.height')
  @DocsEditable()
  AnimatedLength get height => _blink.BlinkSVGFEMorphologyElement.$height_Getter(this);

  @DomName('SVGFEMorphologyElement.result')
  @DocsEditable()
  AnimatedString get result => _blink.BlinkSVGFEMorphologyElement.$result_Getter(this);

  @DomName('SVGFEMorphologyElement.width')
  @DocsEditable()
  AnimatedLength get width => _blink.BlinkSVGFEMorphologyElement.$width_Getter(this);

  @DomName('SVGFEMorphologyElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.BlinkSVGFEMorphologyElement.$x_Getter(this);

  @DomName('SVGFEMorphologyElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.BlinkSVGFEMorphologyElement.$y_Getter(this);

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
  AnimatedNumber get dx => _blink.BlinkSVGFEOffsetElement.$dx_Getter(this);

  @DomName('SVGFEOffsetElement.dy')
  @DocsEditable()
  AnimatedNumber get dy => _blink.BlinkSVGFEOffsetElement.$dy_Getter(this);

  @DomName('SVGFEOffsetElement.in1')
  @DocsEditable()
  AnimatedString get in1 => _blink.BlinkSVGFEOffsetElement.$in1_Getter(this);

  @DomName('SVGFEOffsetElement.height')
  @DocsEditable()
  AnimatedLength get height => _blink.BlinkSVGFEOffsetElement.$height_Getter(this);

  @DomName('SVGFEOffsetElement.result')
  @DocsEditable()
  AnimatedString get result => _blink.BlinkSVGFEOffsetElement.$result_Getter(this);

  @DomName('SVGFEOffsetElement.width')
  @DocsEditable()
  AnimatedLength get width => _blink.BlinkSVGFEOffsetElement.$width_Getter(this);

  @DomName('SVGFEOffsetElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.BlinkSVGFEOffsetElement.$x_Getter(this);

  @DomName('SVGFEOffsetElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.BlinkSVGFEOffsetElement.$y_Getter(this);

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
  AnimatedNumber get x => _blink.BlinkSVGFEPointLightElement.$x_Getter(this);

  @DomName('SVGFEPointLightElement.y')
  @DocsEditable()
  AnimatedNumber get y => _blink.BlinkSVGFEPointLightElement.$y_Getter(this);

  @DomName('SVGFEPointLightElement.z')
  @DocsEditable()
  AnimatedNumber get z => _blink.BlinkSVGFEPointLightElement.$z_Getter(this);

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
  AnimatedString get in1 => _blink.BlinkSVGFESpecularLightingElement.$in1_Getter(this);

  @DomName('SVGFESpecularLightingElement.specularConstant')
  @DocsEditable()
  AnimatedNumber get specularConstant => _blink.BlinkSVGFESpecularLightingElement.$specularConstant_Getter(this);

  @DomName('SVGFESpecularLightingElement.specularExponent')
  @DocsEditable()
  AnimatedNumber get specularExponent => _blink.BlinkSVGFESpecularLightingElement.$specularExponent_Getter(this);

  @DomName('SVGFESpecularLightingElement.surfaceScale')
  @DocsEditable()
  AnimatedNumber get surfaceScale => _blink.BlinkSVGFESpecularLightingElement.$surfaceScale_Getter(this);

  @DomName('SVGFESpecularLightingElement.height')
  @DocsEditable()
  AnimatedLength get height => _blink.BlinkSVGFESpecularLightingElement.$height_Getter(this);

  @DomName('SVGFESpecularLightingElement.result')
  @DocsEditable()
  AnimatedString get result => _blink.BlinkSVGFESpecularLightingElement.$result_Getter(this);

  @DomName('SVGFESpecularLightingElement.width')
  @DocsEditable()
  AnimatedLength get width => _blink.BlinkSVGFESpecularLightingElement.$width_Getter(this);

  @DomName('SVGFESpecularLightingElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.BlinkSVGFESpecularLightingElement.$x_Getter(this);

  @DomName('SVGFESpecularLightingElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.BlinkSVGFESpecularLightingElement.$y_Getter(this);

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
  AnimatedNumber get limitingConeAngle => _blink.BlinkSVGFESpotLightElement.$limitingConeAngle_Getter(this);

  @DomName('SVGFESpotLightElement.pointsAtX')
  @DocsEditable()
  AnimatedNumber get pointsAtX => _blink.BlinkSVGFESpotLightElement.$pointsAtX_Getter(this);

  @DomName('SVGFESpotLightElement.pointsAtY')
  @DocsEditable()
  AnimatedNumber get pointsAtY => _blink.BlinkSVGFESpotLightElement.$pointsAtY_Getter(this);

  @DomName('SVGFESpotLightElement.pointsAtZ')
  @DocsEditable()
  AnimatedNumber get pointsAtZ => _blink.BlinkSVGFESpotLightElement.$pointsAtZ_Getter(this);

  @DomName('SVGFESpotLightElement.specularExponent')
  @DocsEditable()
  AnimatedNumber get specularExponent => _blink.BlinkSVGFESpotLightElement.$specularExponent_Getter(this);

  @DomName('SVGFESpotLightElement.x')
  @DocsEditable()
  AnimatedNumber get x => _blink.BlinkSVGFESpotLightElement.$x_Getter(this);

  @DomName('SVGFESpotLightElement.y')
  @DocsEditable()
  AnimatedNumber get y => _blink.BlinkSVGFESpotLightElement.$y_Getter(this);

  @DomName('SVGFESpotLightElement.z')
  @DocsEditable()
  AnimatedNumber get z => _blink.BlinkSVGFESpotLightElement.$z_Getter(this);

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
  AnimatedString get in1 => _blink.BlinkSVGFETileElement.$in1_Getter(this);

  @DomName('SVGFETileElement.height')
  @DocsEditable()
  AnimatedLength get height => _blink.BlinkSVGFETileElement.$height_Getter(this);

  @DomName('SVGFETileElement.result')
  @DocsEditable()
  AnimatedString get result => _blink.BlinkSVGFETileElement.$result_Getter(this);

  @DomName('SVGFETileElement.width')
  @DocsEditable()
  AnimatedLength get width => _blink.BlinkSVGFETileElement.$width_Getter(this);

  @DomName('SVGFETileElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.BlinkSVGFETileElement.$x_Getter(this);

  @DomName('SVGFETileElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.BlinkSVGFETileElement.$y_Getter(this);

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
  AnimatedNumber get baseFrequencyX => _blink.BlinkSVGFETurbulenceElement.$baseFrequencyX_Getter(this);

  @DomName('SVGFETurbulenceElement.baseFrequencyY')
  @DocsEditable()
  AnimatedNumber get baseFrequencyY => _blink.BlinkSVGFETurbulenceElement.$baseFrequencyY_Getter(this);

  @DomName('SVGFETurbulenceElement.numOctaves')
  @DocsEditable()
  AnimatedInteger get numOctaves => _blink.BlinkSVGFETurbulenceElement.$numOctaves_Getter(this);

  @DomName('SVGFETurbulenceElement.seed')
  @DocsEditable()
  AnimatedNumber get seed => _blink.BlinkSVGFETurbulenceElement.$seed_Getter(this);

  @DomName('SVGFETurbulenceElement.stitchTiles')
  @DocsEditable()
  AnimatedEnumeration get stitchTiles => _blink.BlinkSVGFETurbulenceElement.$stitchTiles_Getter(this);

  @DomName('SVGFETurbulenceElement.type')
  @DocsEditable()
  AnimatedEnumeration get type => _blink.BlinkSVGFETurbulenceElement.$type_Getter(this);

  @DomName('SVGFETurbulenceElement.height')
  @DocsEditable()
  AnimatedLength get height => _blink.BlinkSVGFETurbulenceElement.$height_Getter(this);

  @DomName('SVGFETurbulenceElement.result')
  @DocsEditable()
  AnimatedString get result => _blink.BlinkSVGFETurbulenceElement.$result_Getter(this);

  @DomName('SVGFETurbulenceElement.width')
  @DocsEditable()
  AnimatedLength get width => _blink.BlinkSVGFETurbulenceElement.$width_Getter(this);

  @DomName('SVGFETurbulenceElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.BlinkSVGFETurbulenceElement.$x_Getter(this);

  @DomName('SVGFETurbulenceElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.BlinkSVGFETurbulenceElement.$y_Getter(this);

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
  AnimatedInteger get filterResX => _blink.BlinkSVGFilterElement.$filterResX_Getter(this);

  @DomName('SVGFilterElement.filterResY')
  @DocsEditable()
  AnimatedInteger get filterResY => _blink.BlinkSVGFilterElement.$filterResY_Getter(this);

  @DomName('SVGFilterElement.filterUnits')
  @DocsEditable()
  AnimatedEnumeration get filterUnits => _blink.BlinkSVGFilterElement.$filterUnits_Getter(this);

  @DomName('SVGFilterElement.height')
  @DocsEditable()
  AnimatedLength get height => _blink.BlinkSVGFilterElement.$height_Getter(this);

  @DomName('SVGFilterElement.primitiveUnits')
  @DocsEditable()
  AnimatedEnumeration get primitiveUnits => _blink.BlinkSVGFilterElement.$primitiveUnits_Getter(this);

  @DomName('SVGFilterElement.width')
  @DocsEditable()
  AnimatedLength get width => _blink.BlinkSVGFilterElement.$width_Getter(this);

  @DomName('SVGFilterElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.BlinkSVGFilterElement.$x_Getter(this);

  @DomName('SVGFilterElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.BlinkSVGFilterElement.$y_Getter(this);

  @DomName('SVGFilterElement.setFilterRes')
  @DocsEditable()
  void setFilterRes(int filterResX, int filterResY) => _blink.BlinkSVGFilterElement.$setFilterRes_Callback(this, filterResX, filterResY);

  @DomName('SVGFilterElement.href')
  @DocsEditable()
  AnimatedString get href => _blink.BlinkSVGFilterElement.$href_Getter(this);

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
  AnimatedLength get height => _blink.BlinkSVGFilterPrimitiveStandardAttributes.$height_Getter(this);

  @DomName('SVGFilterPrimitiveStandardAttributes.result')
  @DocsEditable()
  AnimatedString get result => _blink.BlinkSVGFilterPrimitiveStandardAttributes.$result_Getter(this);

  @DomName('SVGFilterPrimitiveStandardAttributes.width')
  @DocsEditable()
  AnimatedLength get width => _blink.BlinkSVGFilterPrimitiveStandardAttributes.$width_Getter(this);

  @DomName('SVGFilterPrimitiveStandardAttributes.x')
  @DocsEditable()
  AnimatedLength get x => _blink.BlinkSVGFilterPrimitiveStandardAttributes.$x_Getter(this);

  @DomName('SVGFilterPrimitiveStandardAttributes.y')
  @DocsEditable()
  AnimatedLength get y => _blink.BlinkSVGFilterPrimitiveStandardAttributes.$y_Getter(this);

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
  AnimatedPreserveAspectRatio get preserveAspectRatio => _blink.BlinkSVGFitToViewBox.$preserveAspectRatio_Getter(this);

  @DomName('SVGFitToViewBox.viewBox')
  @DocsEditable()
  AnimatedRect get viewBox => _blink.BlinkSVGFitToViewBox.$viewBox_Getter(this);

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
  AnimatedLength get height => _blink.BlinkSVGForeignObjectElement.$height_Getter(this);

  @DomName('SVGForeignObjectElement.width')
  @DocsEditable()
  AnimatedLength get width => _blink.BlinkSVGForeignObjectElement.$width_Getter(this);

  @DomName('SVGForeignObjectElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.BlinkSVGForeignObjectElement.$x_Getter(this);

  @DomName('SVGForeignObjectElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.BlinkSVGForeignObjectElement.$y_Getter(this);

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
  bool isPointInFill(Point point) => _blink.BlinkSVGGeometryElement.$isPointInFill_Callback(this, point);

  @DomName('SVGGeometryElement.isPointInStroke')
  @DocsEditable()
  @Experimental() // untriaged
  bool isPointInStroke(Point point) => _blink.BlinkSVGGeometryElement.$isPointInStroke_Callback(this, point);

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
  SvgElement get farthestViewportElement => _blink.BlinkSVGGraphicsElement.$farthestViewportElement_Getter(this);

  @DomName('SVGGraphicsElement.nearestViewportElement')
  @DocsEditable()
  @Experimental() // untriaged
  SvgElement get nearestViewportElement => _blink.BlinkSVGGraphicsElement.$nearestViewportElement_Getter(this);

  @DomName('SVGGraphicsElement.transform')
  @DocsEditable()
  @Experimental() // untriaged
  AnimatedTransformList get transform => _blink.BlinkSVGGraphicsElement.$transform_Getter(this);

  @DomName('SVGGraphicsElement.getBBox')
  @DocsEditable()
  @Experimental() // untriaged
  Rect getBBox() => _blink.BlinkSVGGraphicsElement.$getBBox_Callback(this);

  @DomName('SVGGraphicsElement.getCTM')
  @DocsEditable()
  @Experimental() // untriaged
  Matrix getCtm() => _blink.BlinkSVGGraphicsElement.$getCTM_Callback(this);

  @DomName('SVGGraphicsElement.getScreenCTM')
  @DocsEditable()
  @Experimental() // untriaged
  Matrix getScreenCtm() => _blink.BlinkSVGGraphicsElement.$getScreenCTM_Callback(this);

  @DomName('SVGGraphicsElement.getTransformToElement')
  @DocsEditable()
  @Experimental() // untriaged
  Matrix getTransformToElement(SvgElement element) => _blink.BlinkSVGGraphicsElement.$getTransformToElement_Callback(this, element);

  @DomName('SVGGraphicsElement.requiredExtensions')
  @DocsEditable()
  @Experimental() // untriaged
  StringList get requiredExtensions => _blink.BlinkSVGGraphicsElement.$requiredExtensions_Getter(this);

  @DomName('SVGGraphicsElement.requiredFeatures')
  @DocsEditable()
  @Experimental() // untriaged
  StringList get requiredFeatures => _blink.BlinkSVGGraphicsElement.$requiredFeatures_Getter(this);

  @DomName('SVGGraphicsElement.systemLanguage')
  @DocsEditable()
  @Experimental() // untriaged
  StringList get systemLanguage => _blink.BlinkSVGGraphicsElement.$systemLanguage_Getter(this);

  @DomName('SVGGraphicsElement.hasExtension')
  @DocsEditable()
  @Experimental() // untriaged
  bool hasExtension(String extension) => _blink.BlinkSVGGraphicsElement.$hasExtension_Callback(this, extension);

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
  AnimatedLength get height => _blink.BlinkSVGImageElement.$height_Getter(this);

  @DomName('SVGImageElement.preserveAspectRatio')
  @DocsEditable()
  AnimatedPreserveAspectRatio get preserveAspectRatio => _blink.BlinkSVGImageElement.$preserveAspectRatio_Getter(this);

  @DomName('SVGImageElement.width')
  @DocsEditable()
  AnimatedLength get width => _blink.BlinkSVGImageElement.$width_Getter(this);

  @DomName('SVGImageElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.BlinkSVGImageElement.$x_Getter(this);

  @DomName('SVGImageElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.BlinkSVGImageElement.$y_Getter(this);

  @DomName('SVGImageElement.href')
  @DocsEditable()
  AnimatedString get href => _blink.BlinkSVGImageElement.$href_Getter(this);

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
  int get unitType => _blink.BlinkSVGLength.$unitType_Getter(this);

  @DomName('SVGLength.value')
  @DocsEditable()
  num get value => _blink.BlinkSVGLength.$value_Getter(this);

  @DomName('SVGLength.value')
  @DocsEditable()
  void set value(num value) => _blink.BlinkSVGLength.$value_Setter(this, value);

  @DomName('SVGLength.valueAsString')
  @DocsEditable()
  String get valueAsString => _blink.BlinkSVGLength.$valueAsString_Getter(this);

  @DomName('SVGLength.valueAsString')
  @DocsEditable()
  void set valueAsString(String value) => _blink.BlinkSVGLength.$valueAsString_Setter(this, value);

  @DomName('SVGLength.valueInSpecifiedUnits')
  @DocsEditable()
  num get valueInSpecifiedUnits => _blink.BlinkSVGLength.$valueInSpecifiedUnits_Getter(this);

  @DomName('SVGLength.valueInSpecifiedUnits')
  @DocsEditable()
  void set valueInSpecifiedUnits(num value) => _blink.BlinkSVGLength.$valueInSpecifiedUnits_Setter(this, value);

  @DomName('SVGLength.convertToSpecifiedUnits')
  @DocsEditable()
  void convertToSpecifiedUnits(int unitType) => _blink.BlinkSVGLength.$convertToSpecifiedUnits_Callback(this, unitType);

  @DomName('SVGLength.newValueSpecifiedUnits')
  @DocsEditable()
  void newValueSpecifiedUnits(int unitType, num valueInSpecifiedUnits) => _blink.BlinkSVGLength.$newValueSpecifiedUnits_Callback(this, unitType, valueInSpecifiedUnits);

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
  int get numberOfItems => _blink.BlinkSVGLengthList.$numberOfItems_Getter(this);

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
  Length appendItem(Length item) => _blink.BlinkSVGLengthList.$appendItem_Callback(this, item);

  @DomName('SVGLengthList.clear')
  @DocsEditable()
  void clear() => _blink.BlinkSVGLengthList.$clear_Callback(this);

  @DomName('SVGLengthList.getItem')
  @DocsEditable()
  Length getItem(int index) => _blink.BlinkSVGLengthList.$getItem_Callback(this, index);

  @DomName('SVGLengthList.initialize')
  @DocsEditable()
  Length initialize(Length item) => _blink.BlinkSVGLengthList.$initialize_Callback(this, item);

  @DomName('SVGLengthList.insertItemBefore')
  @DocsEditable()
  Length insertItemBefore(Length item, int index) => _blink.BlinkSVGLengthList.$insertItemBefore_Callback(this, item, index);

  @DomName('SVGLengthList.removeItem')
  @DocsEditable()
  Length removeItem(int index) => _blink.BlinkSVGLengthList.$removeItem_Callback(this, index);

  @DomName('SVGLengthList.replaceItem')
  @DocsEditable()
  Length replaceItem(Length item, int index) => _blink.BlinkSVGLengthList.$replaceItem_Callback(this, item, index);

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
  AnimatedLength get x1 => _blink.BlinkSVGLineElement.$x1_Getter(this);

  @DomName('SVGLineElement.x2')
  @DocsEditable()
  AnimatedLength get x2 => _blink.BlinkSVGLineElement.$x2_Getter(this);

  @DomName('SVGLineElement.y1')
  @DocsEditable()
  AnimatedLength get y1 => _blink.BlinkSVGLineElement.$y1_Getter(this);

  @DomName('SVGLineElement.y2')
  @DocsEditable()
  AnimatedLength get y2 => _blink.BlinkSVGLineElement.$y2_Getter(this);

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
  AnimatedLength get x1 => _blink.BlinkSVGLinearGradientElement.$x1_Getter(this);

  @DomName('SVGLinearGradientElement.x2')
  @DocsEditable()
  AnimatedLength get x2 => _blink.BlinkSVGLinearGradientElement.$x2_Getter(this);

  @DomName('SVGLinearGradientElement.y1')
  @DocsEditable()
  AnimatedLength get y1 => _blink.BlinkSVGLinearGradientElement.$y1_Getter(this);

  @DomName('SVGLinearGradientElement.y2')
  @DocsEditable()
  AnimatedLength get y2 => _blink.BlinkSVGLinearGradientElement.$y2_Getter(this);

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
  AnimatedLength get markerHeight => _blink.BlinkSVGMarkerElement.$markerHeight_Getter(this);

  @DomName('SVGMarkerElement.markerUnits')
  @DocsEditable()
  AnimatedEnumeration get markerUnits => _blink.BlinkSVGMarkerElement.$markerUnits_Getter(this);

  @DomName('SVGMarkerElement.markerWidth')
  @DocsEditable()
  AnimatedLength get markerWidth => _blink.BlinkSVGMarkerElement.$markerWidth_Getter(this);

  @DomName('SVGMarkerElement.orientAngle')
  @DocsEditable()
  AnimatedAngle get orientAngle => _blink.BlinkSVGMarkerElement.$orientAngle_Getter(this);

  @DomName('SVGMarkerElement.orientType')
  @DocsEditable()
  AnimatedEnumeration get orientType => _blink.BlinkSVGMarkerElement.$orientType_Getter(this);

  @DomName('SVGMarkerElement.refX')
  @DocsEditable()
  AnimatedLength get refX => _blink.BlinkSVGMarkerElement.$refX_Getter(this);

  @DomName('SVGMarkerElement.refY')
  @DocsEditable()
  AnimatedLength get refY => _blink.BlinkSVGMarkerElement.$refY_Getter(this);

  @DomName('SVGMarkerElement.setOrientToAngle')
  @DocsEditable()
  void setOrientToAngle(Angle angle) => _blink.BlinkSVGMarkerElement.$setOrientToAngle_Callback(this, angle);

  @DomName('SVGMarkerElement.setOrientToAuto')
  @DocsEditable()
  void setOrientToAuto() => _blink.BlinkSVGMarkerElement.$setOrientToAuto_Callback(this);

  @DomName('SVGMarkerElement.preserveAspectRatio')
  @DocsEditable()
  AnimatedPreserveAspectRatio get preserveAspectRatio => _blink.BlinkSVGMarkerElement.$preserveAspectRatio_Getter(this);

  @DomName('SVGMarkerElement.viewBox')
  @DocsEditable()
  AnimatedRect get viewBox => _blink.BlinkSVGMarkerElement.$viewBox_Getter(this);

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
  AnimatedLength get height => _blink.BlinkSVGMaskElement.$height_Getter(this);

  @DomName('SVGMaskElement.maskContentUnits')
  @DocsEditable()
  AnimatedEnumeration get maskContentUnits => _blink.BlinkSVGMaskElement.$maskContentUnits_Getter(this);

  @DomName('SVGMaskElement.maskUnits')
  @DocsEditable()
  AnimatedEnumeration get maskUnits => _blink.BlinkSVGMaskElement.$maskUnits_Getter(this);

  @DomName('SVGMaskElement.width')
  @DocsEditable()
  AnimatedLength get width => _blink.BlinkSVGMaskElement.$width_Getter(this);

  @DomName('SVGMaskElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.BlinkSVGMaskElement.$x_Getter(this);

  @DomName('SVGMaskElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.BlinkSVGMaskElement.$y_Getter(this);

  @DomName('SVGMaskElement.requiredExtensions')
  @DocsEditable()
  StringList get requiredExtensions => _blink.BlinkSVGMaskElement.$requiredExtensions_Getter(this);

  @DomName('SVGMaskElement.requiredFeatures')
  @DocsEditable()
  StringList get requiredFeatures => _blink.BlinkSVGMaskElement.$requiredFeatures_Getter(this);

  @DomName('SVGMaskElement.systemLanguage')
  @DocsEditable()
  StringList get systemLanguage => _blink.BlinkSVGMaskElement.$systemLanguage_Getter(this);

  @DomName('SVGMaskElement.hasExtension')
  @DocsEditable()
  bool hasExtension(String extension) => _blink.BlinkSVGMaskElement.$hasExtension_Callback(this, extension);

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
  num get a => _blink.BlinkSVGMatrix.$a_Getter(this);

  @DomName('SVGMatrix.a')
  @DocsEditable()
  void set a(num value) => _blink.BlinkSVGMatrix.$a_Setter(this, value);

  @DomName('SVGMatrix.b')
  @DocsEditable()
  num get b => _blink.BlinkSVGMatrix.$b_Getter(this);

  @DomName('SVGMatrix.b')
  @DocsEditable()
  void set b(num value) => _blink.BlinkSVGMatrix.$b_Setter(this, value);

  @DomName('SVGMatrix.c')
  @DocsEditable()
  num get c => _blink.BlinkSVGMatrix.$c_Getter(this);

  @DomName('SVGMatrix.c')
  @DocsEditable()
  void set c(num value) => _blink.BlinkSVGMatrix.$c_Setter(this, value);

  @DomName('SVGMatrix.d')
  @DocsEditable()
  num get d => _blink.BlinkSVGMatrix.$d_Getter(this);

  @DomName('SVGMatrix.d')
  @DocsEditable()
  void set d(num value) => _blink.BlinkSVGMatrix.$d_Setter(this, value);

  @DomName('SVGMatrix.e')
  @DocsEditable()
  num get e => _blink.BlinkSVGMatrix.$e_Getter(this);

  @DomName('SVGMatrix.e')
  @DocsEditable()
  void set e(num value) => _blink.BlinkSVGMatrix.$e_Setter(this, value);

  @DomName('SVGMatrix.f')
  @DocsEditable()
  num get f => _blink.BlinkSVGMatrix.$f_Getter(this);

  @DomName('SVGMatrix.f')
  @DocsEditable()
  void set f(num value) => _blink.BlinkSVGMatrix.$f_Setter(this, value);

  @DomName('SVGMatrix.flipX')
  @DocsEditable()
  Matrix flipX() => _blink.BlinkSVGMatrix.$flipX_Callback(this);

  @DomName('SVGMatrix.flipY')
  @DocsEditable()
  Matrix flipY() => _blink.BlinkSVGMatrix.$flipY_Callback(this);

  @DomName('SVGMatrix.inverse')
  @DocsEditable()
  Matrix inverse() => _blink.BlinkSVGMatrix.$inverse_Callback(this);

  @DomName('SVGMatrix.multiply')
  @DocsEditable()
  Matrix multiply(Matrix secondMatrix) => _blink.BlinkSVGMatrix.$multiply_Callback(this, secondMatrix);

  @DomName('SVGMatrix.rotate')
  @DocsEditable()
  Matrix rotate(num angle) => _blink.BlinkSVGMatrix.$rotate_Callback(this, angle);

  @DomName('SVGMatrix.rotateFromVector')
  @DocsEditable()
  Matrix rotateFromVector(num x, num y) => _blink.BlinkSVGMatrix.$rotateFromVector_Callback(this, x, y);

  @DomName('SVGMatrix.scale')
  @DocsEditable()
  Matrix scale(num scaleFactor) => _blink.BlinkSVGMatrix.$scale_Callback(this, scaleFactor);

  @DomName('SVGMatrix.scaleNonUniform')
  @DocsEditable()
  Matrix scaleNonUniform(num scaleFactorX, num scaleFactorY) => _blink.BlinkSVGMatrix.$scaleNonUniform_Callback(this, scaleFactorX, scaleFactorY);

  @DomName('SVGMatrix.skewX')
  @DocsEditable()
  Matrix skewX(num angle) => _blink.BlinkSVGMatrix.$skewX_Callback(this, angle);

  @DomName('SVGMatrix.skewY')
  @DocsEditable()
  Matrix skewY(num angle) => _blink.BlinkSVGMatrix.$skewY_Callback(this, angle);

  @DomName('SVGMatrix.translate')
  @DocsEditable()
  Matrix translate(num x, num y) => _blink.BlinkSVGMatrix.$translate_Callback(this, x, y);

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
  num get value => _blink.BlinkSVGNumber.$value_Getter(this);

  @DomName('SVGNumber.value')
  @DocsEditable()
  void set value(num value) => _blink.BlinkSVGNumber.$value_Setter(this, value);

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
  int get numberOfItems => _blink.BlinkSVGNumberList.$numberOfItems_Getter(this);

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
  Number appendItem(Number item) => _blink.BlinkSVGNumberList.$appendItem_Callback(this, item);

  @DomName('SVGNumberList.clear')
  @DocsEditable()
  void clear() => _blink.BlinkSVGNumberList.$clear_Callback(this);

  @DomName('SVGNumberList.getItem')
  @DocsEditable()
  Number getItem(int index) => _blink.BlinkSVGNumberList.$getItem_Callback(this, index);

  @DomName('SVGNumberList.initialize')
  @DocsEditable()
  Number initialize(Number item) => _blink.BlinkSVGNumberList.$initialize_Callback(this, item);

  @DomName('SVGNumberList.insertItemBefore')
  @DocsEditable()
  Number insertItemBefore(Number item, int index) => _blink.BlinkSVGNumberList.$insertItemBefore_Callback(this, item, index);

  @DomName('SVGNumberList.removeItem')
  @DocsEditable()
  Number removeItem(int index) => _blink.BlinkSVGNumberList.$removeItem_Callback(this, index);

  @DomName('SVGNumberList.replaceItem')
  @DocsEditable()
  Number replaceItem(Number item, int index) => _blink.BlinkSVGNumberList.$replaceItem_Callback(this, item, index);

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
  PathSegList get animatedNormalizedPathSegList => _blink.BlinkSVGPathElement.$animatedNormalizedPathSegList_Getter(this);

  @DomName('SVGPathElement.animatedPathSegList')
  @DocsEditable()
  PathSegList get animatedPathSegList => _blink.BlinkSVGPathElement.$animatedPathSegList_Getter(this);

  @DomName('SVGPathElement.normalizedPathSegList')
  @DocsEditable()
  PathSegList get normalizedPathSegList => _blink.BlinkSVGPathElement.$normalizedPathSegList_Getter(this);

  @DomName('SVGPathElement.pathLength')
  @DocsEditable()
  AnimatedNumber get pathLength => _blink.BlinkSVGPathElement.$pathLength_Getter(this);

  @DomName('SVGPathElement.pathSegList')
  @DocsEditable()
  PathSegList get pathSegList => _blink.BlinkSVGPathElement.$pathSegList_Getter(this);

  @DomName('SVGPathElement.createSVGPathSegArcAbs')
  @DocsEditable()
  PathSegArcAbs createSvgPathSegArcAbs(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) => _blink.BlinkSVGPathElement.$createSVGPathSegArcAbs_Callback(this, x, y, r1, r2, angle, largeArcFlag, sweepFlag);

  @DomName('SVGPathElement.createSVGPathSegArcRel')
  @DocsEditable()
  PathSegArcRel createSvgPathSegArcRel(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) => _blink.BlinkSVGPathElement.$createSVGPathSegArcRel_Callback(this, x, y, r1, r2, angle, largeArcFlag, sweepFlag);

  @DomName('SVGPathElement.createSVGPathSegClosePath')
  @DocsEditable()
  PathSegClosePath createSvgPathSegClosePath() => _blink.BlinkSVGPathElement.$createSVGPathSegClosePath_Callback(this);

  @DomName('SVGPathElement.createSVGPathSegCurvetoCubicAbs')
  @DocsEditable()
  PathSegCurvetoCubicAbs createSvgPathSegCurvetoCubicAbs(num x, num y, num x1, num y1, num x2, num y2) => _blink.BlinkSVGPathElement.$createSVGPathSegCurvetoCubicAbs_Callback(this, x, y, x1, y1, x2, y2);

  @DomName('SVGPathElement.createSVGPathSegCurvetoCubicRel')
  @DocsEditable()
  PathSegCurvetoCubicRel createSvgPathSegCurvetoCubicRel(num x, num y, num x1, num y1, num x2, num y2) => _blink.BlinkSVGPathElement.$createSVGPathSegCurvetoCubicRel_Callback(this, x, y, x1, y1, x2, y2);

  @DomName('SVGPathElement.createSVGPathSegCurvetoCubicSmoothAbs')
  @DocsEditable()
  PathSegCurvetoCubicSmoothAbs createSvgPathSegCurvetoCubicSmoothAbs(num x, num y, num x2, num y2) => _blink.BlinkSVGPathElement.$createSVGPathSegCurvetoCubicSmoothAbs_Callback(this, x, y, x2, y2);

  @DomName('SVGPathElement.createSVGPathSegCurvetoCubicSmoothRel')
  @DocsEditable()
  PathSegCurvetoCubicSmoothRel createSvgPathSegCurvetoCubicSmoothRel(num x, num y, num x2, num y2) => _blink.BlinkSVGPathElement.$createSVGPathSegCurvetoCubicSmoothRel_Callback(this, x, y, x2, y2);

  @DomName('SVGPathElement.createSVGPathSegCurvetoQuadraticAbs')
  @DocsEditable()
  PathSegCurvetoQuadraticAbs createSvgPathSegCurvetoQuadraticAbs(num x, num y, num x1, num y1) => _blink.BlinkSVGPathElement.$createSVGPathSegCurvetoQuadraticAbs_Callback(this, x, y, x1, y1);

  @DomName('SVGPathElement.createSVGPathSegCurvetoQuadraticRel')
  @DocsEditable()
  PathSegCurvetoQuadraticRel createSvgPathSegCurvetoQuadraticRel(num x, num y, num x1, num y1) => _blink.BlinkSVGPathElement.$createSVGPathSegCurvetoQuadraticRel_Callback(this, x, y, x1, y1);

  @DomName('SVGPathElement.createSVGPathSegCurvetoQuadraticSmoothAbs')
  @DocsEditable()
  PathSegCurvetoQuadraticSmoothAbs createSvgPathSegCurvetoQuadraticSmoothAbs(num x, num y) => _blink.BlinkSVGPathElement.$createSVGPathSegCurvetoQuadraticSmoothAbs_Callback(this, x, y);

  @DomName('SVGPathElement.createSVGPathSegCurvetoQuadraticSmoothRel')
  @DocsEditable()
  PathSegCurvetoQuadraticSmoothRel createSvgPathSegCurvetoQuadraticSmoothRel(num x, num y) => _blink.BlinkSVGPathElement.$createSVGPathSegCurvetoQuadraticSmoothRel_Callback(this, x, y);

  @DomName('SVGPathElement.createSVGPathSegLinetoAbs')
  @DocsEditable()
  PathSegLinetoAbs createSvgPathSegLinetoAbs(num x, num y) => _blink.BlinkSVGPathElement.$createSVGPathSegLinetoAbs_Callback(this, x, y);

  @DomName('SVGPathElement.createSVGPathSegLinetoHorizontalAbs')
  @DocsEditable()
  PathSegLinetoHorizontalAbs createSvgPathSegLinetoHorizontalAbs(num x) => _blink.BlinkSVGPathElement.$createSVGPathSegLinetoHorizontalAbs_Callback(this, x);

  @DomName('SVGPathElement.createSVGPathSegLinetoHorizontalRel')
  @DocsEditable()
  PathSegLinetoHorizontalRel createSvgPathSegLinetoHorizontalRel(num x) => _blink.BlinkSVGPathElement.$createSVGPathSegLinetoHorizontalRel_Callback(this, x);

  @DomName('SVGPathElement.createSVGPathSegLinetoRel')
  @DocsEditable()
  PathSegLinetoRel createSvgPathSegLinetoRel(num x, num y) => _blink.BlinkSVGPathElement.$createSVGPathSegLinetoRel_Callback(this, x, y);

  @DomName('SVGPathElement.createSVGPathSegLinetoVerticalAbs')
  @DocsEditable()
  PathSegLinetoVerticalAbs createSvgPathSegLinetoVerticalAbs(num y) => _blink.BlinkSVGPathElement.$createSVGPathSegLinetoVerticalAbs_Callback(this, y);

  @DomName('SVGPathElement.createSVGPathSegLinetoVerticalRel')
  @DocsEditable()
  PathSegLinetoVerticalRel createSvgPathSegLinetoVerticalRel(num y) => _blink.BlinkSVGPathElement.$createSVGPathSegLinetoVerticalRel_Callback(this, y);

  @DomName('SVGPathElement.createSVGPathSegMovetoAbs')
  @DocsEditable()
  PathSegMovetoAbs createSvgPathSegMovetoAbs(num x, num y) => _blink.BlinkSVGPathElement.$createSVGPathSegMovetoAbs_Callback(this, x, y);

  @DomName('SVGPathElement.createSVGPathSegMovetoRel')
  @DocsEditable()
  PathSegMovetoRel createSvgPathSegMovetoRel(num x, num y) => _blink.BlinkSVGPathElement.$createSVGPathSegMovetoRel_Callback(this, x, y);

  @DomName('SVGPathElement.getPathSegAtLength')
  @DocsEditable()
  int getPathSegAtLength(num distance) => _blink.BlinkSVGPathElement.$getPathSegAtLength_Callback(this, distance);

  @DomName('SVGPathElement.getPointAtLength')
  @DocsEditable()
  Point getPointAtLength(num distance) => _blink.BlinkSVGPathElement.$getPointAtLength_Callback(this, distance);

  @DomName('SVGPathElement.getTotalLength')
  @DocsEditable()
  double getTotalLength() => _blink.BlinkSVGPathElement.$getTotalLength_Callback(this);

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
  int get pathSegType => _blink.BlinkSVGPathSeg.$pathSegType_Getter(this);

  @DomName('SVGPathSeg.pathSegTypeAsLetter')
  @DocsEditable()
  String get pathSegTypeAsLetter => _blink.BlinkSVGPathSeg.$pathSegTypeAsLetter_Getter(this);

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
  num get angle => _blink.BlinkSVGPathSegArcAbs.$angle_Getter(this);

  @DomName('SVGPathSegArcAbs.angle')
  @DocsEditable()
  void set angle(num value) => _blink.BlinkSVGPathSegArcAbs.$angle_Setter(this, value);

  @DomName('SVGPathSegArcAbs.largeArcFlag')
  @DocsEditable()
  bool get largeArcFlag => _blink.BlinkSVGPathSegArcAbs.$largeArcFlag_Getter(this);

  @DomName('SVGPathSegArcAbs.largeArcFlag')
  @DocsEditable()
  void set largeArcFlag(bool value) => _blink.BlinkSVGPathSegArcAbs.$largeArcFlag_Setter(this, value);

  @DomName('SVGPathSegArcAbs.r1')
  @DocsEditable()
  num get r1 => _blink.BlinkSVGPathSegArcAbs.$r1_Getter(this);

  @DomName('SVGPathSegArcAbs.r1')
  @DocsEditable()
  void set r1(num value) => _blink.BlinkSVGPathSegArcAbs.$r1_Setter(this, value);

  @DomName('SVGPathSegArcAbs.r2')
  @DocsEditable()
  num get r2 => _blink.BlinkSVGPathSegArcAbs.$r2_Getter(this);

  @DomName('SVGPathSegArcAbs.r2')
  @DocsEditable()
  void set r2(num value) => _blink.BlinkSVGPathSegArcAbs.$r2_Setter(this, value);

  @DomName('SVGPathSegArcAbs.sweepFlag')
  @DocsEditable()
  bool get sweepFlag => _blink.BlinkSVGPathSegArcAbs.$sweepFlag_Getter(this);

  @DomName('SVGPathSegArcAbs.sweepFlag')
  @DocsEditable()
  void set sweepFlag(bool value) => _blink.BlinkSVGPathSegArcAbs.$sweepFlag_Setter(this, value);

  @DomName('SVGPathSegArcAbs.x')
  @DocsEditable()
  num get x => _blink.BlinkSVGPathSegArcAbs.$x_Getter(this);

  @DomName('SVGPathSegArcAbs.x')
  @DocsEditable()
  void set x(num value) => _blink.BlinkSVGPathSegArcAbs.$x_Setter(this, value);

  @DomName('SVGPathSegArcAbs.y')
  @DocsEditable()
  num get y => _blink.BlinkSVGPathSegArcAbs.$y_Getter(this);

  @DomName('SVGPathSegArcAbs.y')
  @DocsEditable()
  void set y(num value) => _blink.BlinkSVGPathSegArcAbs.$y_Setter(this, value);

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
  num get angle => _blink.BlinkSVGPathSegArcRel.$angle_Getter(this);

  @DomName('SVGPathSegArcRel.angle')
  @DocsEditable()
  void set angle(num value) => _blink.BlinkSVGPathSegArcRel.$angle_Setter(this, value);

  @DomName('SVGPathSegArcRel.largeArcFlag')
  @DocsEditable()
  bool get largeArcFlag => _blink.BlinkSVGPathSegArcRel.$largeArcFlag_Getter(this);

  @DomName('SVGPathSegArcRel.largeArcFlag')
  @DocsEditable()
  void set largeArcFlag(bool value) => _blink.BlinkSVGPathSegArcRel.$largeArcFlag_Setter(this, value);

  @DomName('SVGPathSegArcRel.r1')
  @DocsEditable()
  num get r1 => _blink.BlinkSVGPathSegArcRel.$r1_Getter(this);

  @DomName('SVGPathSegArcRel.r1')
  @DocsEditable()
  void set r1(num value) => _blink.BlinkSVGPathSegArcRel.$r1_Setter(this, value);

  @DomName('SVGPathSegArcRel.r2')
  @DocsEditable()
  num get r2 => _blink.BlinkSVGPathSegArcRel.$r2_Getter(this);

  @DomName('SVGPathSegArcRel.r2')
  @DocsEditable()
  void set r2(num value) => _blink.BlinkSVGPathSegArcRel.$r2_Setter(this, value);

  @DomName('SVGPathSegArcRel.sweepFlag')
  @DocsEditable()
  bool get sweepFlag => _blink.BlinkSVGPathSegArcRel.$sweepFlag_Getter(this);

  @DomName('SVGPathSegArcRel.sweepFlag')
  @DocsEditable()
  void set sweepFlag(bool value) => _blink.BlinkSVGPathSegArcRel.$sweepFlag_Setter(this, value);

  @DomName('SVGPathSegArcRel.x')
  @DocsEditable()
  num get x => _blink.BlinkSVGPathSegArcRel.$x_Getter(this);

  @DomName('SVGPathSegArcRel.x')
  @DocsEditable()
  void set x(num value) => _blink.BlinkSVGPathSegArcRel.$x_Setter(this, value);

  @DomName('SVGPathSegArcRel.y')
  @DocsEditable()
  num get y => _blink.BlinkSVGPathSegArcRel.$y_Getter(this);

  @DomName('SVGPathSegArcRel.y')
  @DocsEditable()
  void set y(num value) => _blink.BlinkSVGPathSegArcRel.$y_Setter(this, value);

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
  num get x => _blink.BlinkSVGPathSegCurvetoCubicAbs.$x_Getter(this);

  @DomName('SVGPathSegCurvetoCubicAbs.x')
  @DocsEditable()
  void set x(num value) => _blink.BlinkSVGPathSegCurvetoCubicAbs.$x_Setter(this, value);

  @DomName('SVGPathSegCurvetoCubicAbs.x1')
  @DocsEditable()
  num get x1 => _blink.BlinkSVGPathSegCurvetoCubicAbs.$x1_Getter(this);

  @DomName('SVGPathSegCurvetoCubicAbs.x1')
  @DocsEditable()
  void set x1(num value) => _blink.BlinkSVGPathSegCurvetoCubicAbs.$x1_Setter(this, value);

  @DomName('SVGPathSegCurvetoCubicAbs.x2')
  @DocsEditable()
  num get x2 => _blink.BlinkSVGPathSegCurvetoCubicAbs.$x2_Getter(this);

  @DomName('SVGPathSegCurvetoCubicAbs.x2')
  @DocsEditable()
  void set x2(num value) => _blink.BlinkSVGPathSegCurvetoCubicAbs.$x2_Setter(this, value);

  @DomName('SVGPathSegCurvetoCubicAbs.y')
  @DocsEditable()
  num get y => _blink.BlinkSVGPathSegCurvetoCubicAbs.$y_Getter(this);

  @DomName('SVGPathSegCurvetoCubicAbs.y')
  @DocsEditable()
  void set y(num value) => _blink.BlinkSVGPathSegCurvetoCubicAbs.$y_Setter(this, value);

  @DomName('SVGPathSegCurvetoCubicAbs.y1')
  @DocsEditable()
  num get y1 => _blink.BlinkSVGPathSegCurvetoCubicAbs.$y1_Getter(this);

  @DomName('SVGPathSegCurvetoCubicAbs.y1')
  @DocsEditable()
  void set y1(num value) => _blink.BlinkSVGPathSegCurvetoCubicAbs.$y1_Setter(this, value);

  @DomName('SVGPathSegCurvetoCubicAbs.y2')
  @DocsEditable()
  num get y2 => _blink.BlinkSVGPathSegCurvetoCubicAbs.$y2_Getter(this);

  @DomName('SVGPathSegCurvetoCubicAbs.y2')
  @DocsEditable()
  void set y2(num value) => _blink.BlinkSVGPathSegCurvetoCubicAbs.$y2_Setter(this, value);

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
  num get x => _blink.BlinkSVGPathSegCurvetoCubicRel.$x_Getter(this);

  @DomName('SVGPathSegCurvetoCubicRel.x')
  @DocsEditable()
  void set x(num value) => _blink.BlinkSVGPathSegCurvetoCubicRel.$x_Setter(this, value);

  @DomName('SVGPathSegCurvetoCubicRel.x1')
  @DocsEditable()
  num get x1 => _blink.BlinkSVGPathSegCurvetoCubicRel.$x1_Getter(this);

  @DomName('SVGPathSegCurvetoCubicRel.x1')
  @DocsEditable()
  void set x1(num value) => _blink.BlinkSVGPathSegCurvetoCubicRel.$x1_Setter(this, value);

  @DomName('SVGPathSegCurvetoCubicRel.x2')
  @DocsEditable()
  num get x2 => _blink.BlinkSVGPathSegCurvetoCubicRel.$x2_Getter(this);

  @DomName('SVGPathSegCurvetoCubicRel.x2')
  @DocsEditable()
  void set x2(num value) => _blink.BlinkSVGPathSegCurvetoCubicRel.$x2_Setter(this, value);

  @DomName('SVGPathSegCurvetoCubicRel.y')
  @DocsEditable()
  num get y => _blink.BlinkSVGPathSegCurvetoCubicRel.$y_Getter(this);

  @DomName('SVGPathSegCurvetoCubicRel.y')
  @DocsEditable()
  void set y(num value) => _blink.BlinkSVGPathSegCurvetoCubicRel.$y_Setter(this, value);

  @DomName('SVGPathSegCurvetoCubicRel.y1')
  @DocsEditable()
  num get y1 => _blink.BlinkSVGPathSegCurvetoCubicRel.$y1_Getter(this);

  @DomName('SVGPathSegCurvetoCubicRel.y1')
  @DocsEditable()
  void set y1(num value) => _blink.BlinkSVGPathSegCurvetoCubicRel.$y1_Setter(this, value);

  @DomName('SVGPathSegCurvetoCubicRel.y2')
  @DocsEditable()
  num get y2 => _blink.BlinkSVGPathSegCurvetoCubicRel.$y2_Getter(this);

  @DomName('SVGPathSegCurvetoCubicRel.y2')
  @DocsEditable()
  void set y2(num value) => _blink.BlinkSVGPathSegCurvetoCubicRel.$y2_Setter(this, value);

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
  num get x => _blink.BlinkSVGPathSegCurvetoCubicSmoothAbs.$x_Getter(this);

  @DomName('SVGPathSegCurvetoCubicSmoothAbs.x')
  @DocsEditable()
  void set x(num value) => _blink.BlinkSVGPathSegCurvetoCubicSmoothAbs.$x_Setter(this, value);

  @DomName('SVGPathSegCurvetoCubicSmoothAbs.x2')
  @DocsEditable()
  num get x2 => _blink.BlinkSVGPathSegCurvetoCubicSmoothAbs.$x2_Getter(this);

  @DomName('SVGPathSegCurvetoCubicSmoothAbs.x2')
  @DocsEditable()
  void set x2(num value) => _blink.BlinkSVGPathSegCurvetoCubicSmoothAbs.$x2_Setter(this, value);

  @DomName('SVGPathSegCurvetoCubicSmoothAbs.y')
  @DocsEditable()
  num get y => _blink.BlinkSVGPathSegCurvetoCubicSmoothAbs.$y_Getter(this);

  @DomName('SVGPathSegCurvetoCubicSmoothAbs.y')
  @DocsEditable()
  void set y(num value) => _blink.BlinkSVGPathSegCurvetoCubicSmoothAbs.$y_Setter(this, value);

  @DomName('SVGPathSegCurvetoCubicSmoothAbs.y2')
  @DocsEditable()
  num get y2 => _blink.BlinkSVGPathSegCurvetoCubicSmoothAbs.$y2_Getter(this);

  @DomName('SVGPathSegCurvetoCubicSmoothAbs.y2')
  @DocsEditable()
  void set y2(num value) => _blink.BlinkSVGPathSegCurvetoCubicSmoothAbs.$y2_Setter(this, value);

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
  num get x => _blink.BlinkSVGPathSegCurvetoCubicSmoothRel.$x_Getter(this);

  @DomName('SVGPathSegCurvetoCubicSmoothRel.x')
  @DocsEditable()
  void set x(num value) => _blink.BlinkSVGPathSegCurvetoCubicSmoothRel.$x_Setter(this, value);

  @DomName('SVGPathSegCurvetoCubicSmoothRel.x2')
  @DocsEditable()
  num get x2 => _blink.BlinkSVGPathSegCurvetoCubicSmoothRel.$x2_Getter(this);

  @DomName('SVGPathSegCurvetoCubicSmoothRel.x2')
  @DocsEditable()
  void set x2(num value) => _blink.BlinkSVGPathSegCurvetoCubicSmoothRel.$x2_Setter(this, value);

  @DomName('SVGPathSegCurvetoCubicSmoothRel.y')
  @DocsEditable()
  num get y => _blink.BlinkSVGPathSegCurvetoCubicSmoothRel.$y_Getter(this);

  @DomName('SVGPathSegCurvetoCubicSmoothRel.y')
  @DocsEditable()
  void set y(num value) => _blink.BlinkSVGPathSegCurvetoCubicSmoothRel.$y_Setter(this, value);

  @DomName('SVGPathSegCurvetoCubicSmoothRel.y2')
  @DocsEditable()
  num get y2 => _blink.BlinkSVGPathSegCurvetoCubicSmoothRel.$y2_Getter(this);

  @DomName('SVGPathSegCurvetoCubicSmoothRel.y2')
  @DocsEditable()
  void set y2(num value) => _blink.BlinkSVGPathSegCurvetoCubicSmoothRel.$y2_Setter(this, value);

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
  num get x => _blink.BlinkSVGPathSegCurvetoQuadraticAbs.$x_Getter(this);

  @DomName('SVGPathSegCurvetoQuadraticAbs.x')
  @DocsEditable()
  void set x(num value) => _blink.BlinkSVGPathSegCurvetoQuadraticAbs.$x_Setter(this, value);

  @DomName('SVGPathSegCurvetoQuadraticAbs.x1')
  @DocsEditable()
  num get x1 => _blink.BlinkSVGPathSegCurvetoQuadraticAbs.$x1_Getter(this);

  @DomName('SVGPathSegCurvetoQuadraticAbs.x1')
  @DocsEditable()
  void set x1(num value) => _blink.BlinkSVGPathSegCurvetoQuadraticAbs.$x1_Setter(this, value);

  @DomName('SVGPathSegCurvetoQuadraticAbs.y')
  @DocsEditable()
  num get y => _blink.BlinkSVGPathSegCurvetoQuadraticAbs.$y_Getter(this);

  @DomName('SVGPathSegCurvetoQuadraticAbs.y')
  @DocsEditable()
  void set y(num value) => _blink.BlinkSVGPathSegCurvetoQuadraticAbs.$y_Setter(this, value);

  @DomName('SVGPathSegCurvetoQuadraticAbs.y1')
  @DocsEditable()
  num get y1 => _blink.BlinkSVGPathSegCurvetoQuadraticAbs.$y1_Getter(this);

  @DomName('SVGPathSegCurvetoQuadraticAbs.y1')
  @DocsEditable()
  void set y1(num value) => _blink.BlinkSVGPathSegCurvetoQuadraticAbs.$y1_Setter(this, value);

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
  num get x => _blink.BlinkSVGPathSegCurvetoQuadraticRel.$x_Getter(this);

  @DomName('SVGPathSegCurvetoQuadraticRel.x')
  @DocsEditable()
  void set x(num value) => _blink.BlinkSVGPathSegCurvetoQuadraticRel.$x_Setter(this, value);

  @DomName('SVGPathSegCurvetoQuadraticRel.x1')
  @DocsEditable()
  num get x1 => _blink.BlinkSVGPathSegCurvetoQuadraticRel.$x1_Getter(this);

  @DomName('SVGPathSegCurvetoQuadraticRel.x1')
  @DocsEditable()
  void set x1(num value) => _blink.BlinkSVGPathSegCurvetoQuadraticRel.$x1_Setter(this, value);

  @DomName('SVGPathSegCurvetoQuadraticRel.y')
  @DocsEditable()
  num get y => _blink.BlinkSVGPathSegCurvetoQuadraticRel.$y_Getter(this);

  @DomName('SVGPathSegCurvetoQuadraticRel.y')
  @DocsEditable()
  void set y(num value) => _blink.BlinkSVGPathSegCurvetoQuadraticRel.$y_Setter(this, value);

  @DomName('SVGPathSegCurvetoQuadraticRel.y1')
  @DocsEditable()
  num get y1 => _blink.BlinkSVGPathSegCurvetoQuadraticRel.$y1_Getter(this);

  @DomName('SVGPathSegCurvetoQuadraticRel.y1')
  @DocsEditable()
  void set y1(num value) => _blink.BlinkSVGPathSegCurvetoQuadraticRel.$y1_Setter(this, value);

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
  num get x => _blink.BlinkSVGPathSegCurvetoQuadraticSmoothAbs.$x_Getter(this);

  @DomName('SVGPathSegCurvetoQuadraticSmoothAbs.x')
  @DocsEditable()
  void set x(num value) => _blink.BlinkSVGPathSegCurvetoQuadraticSmoothAbs.$x_Setter(this, value);

  @DomName('SVGPathSegCurvetoQuadraticSmoothAbs.y')
  @DocsEditable()
  num get y => _blink.BlinkSVGPathSegCurvetoQuadraticSmoothAbs.$y_Getter(this);

  @DomName('SVGPathSegCurvetoQuadraticSmoothAbs.y')
  @DocsEditable()
  void set y(num value) => _blink.BlinkSVGPathSegCurvetoQuadraticSmoothAbs.$y_Setter(this, value);

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
  num get x => _blink.BlinkSVGPathSegCurvetoQuadraticSmoothRel.$x_Getter(this);

  @DomName('SVGPathSegCurvetoQuadraticSmoothRel.x')
  @DocsEditable()
  void set x(num value) => _blink.BlinkSVGPathSegCurvetoQuadraticSmoothRel.$x_Setter(this, value);

  @DomName('SVGPathSegCurvetoQuadraticSmoothRel.y')
  @DocsEditable()
  num get y => _blink.BlinkSVGPathSegCurvetoQuadraticSmoothRel.$y_Getter(this);

  @DomName('SVGPathSegCurvetoQuadraticSmoothRel.y')
  @DocsEditable()
  void set y(num value) => _blink.BlinkSVGPathSegCurvetoQuadraticSmoothRel.$y_Setter(this, value);

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
  num get x => _blink.BlinkSVGPathSegLinetoAbs.$x_Getter(this);

  @DomName('SVGPathSegLinetoAbs.x')
  @DocsEditable()
  void set x(num value) => _blink.BlinkSVGPathSegLinetoAbs.$x_Setter(this, value);

  @DomName('SVGPathSegLinetoAbs.y')
  @DocsEditable()
  num get y => _blink.BlinkSVGPathSegLinetoAbs.$y_Getter(this);

  @DomName('SVGPathSegLinetoAbs.y')
  @DocsEditable()
  void set y(num value) => _blink.BlinkSVGPathSegLinetoAbs.$y_Setter(this, value);

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
  num get x => _blink.BlinkSVGPathSegLinetoHorizontalAbs.$x_Getter(this);

  @DomName('SVGPathSegLinetoHorizontalAbs.x')
  @DocsEditable()
  void set x(num value) => _blink.BlinkSVGPathSegLinetoHorizontalAbs.$x_Setter(this, value);

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
  num get x => _blink.BlinkSVGPathSegLinetoHorizontalRel.$x_Getter(this);

  @DomName('SVGPathSegLinetoHorizontalRel.x')
  @DocsEditable()
  void set x(num value) => _blink.BlinkSVGPathSegLinetoHorizontalRel.$x_Setter(this, value);

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
  num get x => _blink.BlinkSVGPathSegLinetoRel.$x_Getter(this);

  @DomName('SVGPathSegLinetoRel.x')
  @DocsEditable()
  void set x(num value) => _blink.BlinkSVGPathSegLinetoRel.$x_Setter(this, value);

  @DomName('SVGPathSegLinetoRel.y')
  @DocsEditable()
  num get y => _blink.BlinkSVGPathSegLinetoRel.$y_Getter(this);

  @DomName('SVGPathSegLinetoRel.y')
  @DocsEditable()
  void set y(num value) => _blink.BlinkSVGPathSegLinetoRel.$y_Setter(this, value);

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
  num get y => _blink.BlinkSVGPathSegLinetoVerticalAbs.$y_Getter(this);

  @DomName('SVGPathSegLinetoVerticalAbs.y')
  @DocsEditable()
  void set y(num value) => _blink.BlinkSVGPathSegLinetoVerticalAbs.$y_Setter(this, value);

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
  num get y => _blink.BlinkSVGPathSegLinetoVerticalRel.$y_Getter(this);

  @DomName('SVGPathSegLinetoVerticalRel.y')
  @DocsEditable()
  void set y(num value) => _blink.BlinkSVGPathSegLinetoVerticalRel.$y_Setter(this, value);

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
  int get numberOfItems => _blink.BlinkSVGPathSegList.$numberOfItems_Getter(this);

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
  PathSeg appendItem(PathSeg newItem) => _blink.BlinkSVGPathSegList.$appendItem_Callback(this, newItem);

  @DomName('SVGPathSegList.clear')
  @DocsEditable()
  void clear() => _blink.BlinkSVGPathSegList.$clear_Callback(this);

  @DomName('SVGPathSegList.getItem')
  @DocsEditable()
  PathSeg getItem(int index) => _blink.BlinkSVGPathSegList.$getItem_Callback(this, index);

  @DomName('SVGPathSegList.initialize')
  @DocsEditable()
  PathSeg initialize(PathSeg newItem) => _blink.BlinkSVGPathSegList.$initialize_Callback(this, newItem);

  @DomName('SVGPathSegList.insertItemBefore')
  @DocsEditable()
  PathSeg insertItemBefore(PathSeg newItem, int index) => _blink.BlinkSVGPathSegList.$insertItemBefore_Callback(this, newItem, index);

  @DomName('SVGPathSegList.removeItem')
  @DocsEditable()
  PathSeg removeItem(int index) => _blink.BlinkSVGPathSegList.$removeItem_Callback(this, index);

  @DomName('SVGPathSegList.replaceItem')
  @DocsEditable()
  PathSeg replaceItem(PathSeg newItem, int index) => _blink.BlinkSVGPathSegList.$replaceItem_Callback(this, newItem, index);

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
  num get x => _blink.BlinkSVGPathSegMovetoAbs.$x_Getter(this);

  @DomName('SVGPathSegMovetoAbs.x')
  @DocsEditable()
  void set x(num value) => _blink.BlinkSVGPathSegMovetoAbs.$x_Setter(this, value);

  @DomName('SVGPathSegMovetoAbs.y')
  @DocsEditable()
  num get y => _blink.BlinkSVGPathSegMovetoAbs.$y_Getter(this);

  @DomName('SVGPathSegMovetoAbs.y')
  @DocsEditable()
  void set y(num value) => _blink.BlinkSVGPathSegMovetoAbs.$y_Setter(this, value);

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
  num get x => _blink.BlinkSVGPathSegMovetoRel.$x_Getter(this);

  @DomName('SVGPathSegMovetoRel.x')
  @DocsEditable()
  void set x(num value) => _blink.BlinkSVGPathSegMovetoRel.$x_Setter(this, value);

  @DomName('SVGPathSegMovetoRel.y')
  @DocsEditable()
  num get y => _blink.BlinkSVGPathSegMovetoRel.$y_Getter(this);

  @DomName('SVGPathSegMovetoRel.y')
  @DocsEditable()
  void set y(num value) => _blink.BlinkSVGPathSegMovetoRel.$y_Setter(this, value);

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
  AnimatedLength get height => _blink.BlinkSVGPatternElement.$height_Getter(this);

  @DomName('SVGPatternElement.patternContentUnits')
  @DocsEditable()
  AnimatedEnumeration get patternContentUnits => _blink.BlinkSVGPatternElement.$patternContentUnits_Getter(this);

  @DomName('SVGPatternElement.patternTransform')
  @DocsEditable()
  AnimatedTransformList get patternTransform => _blink.BlinkSVGPatternElement.$patternTransform_Getter(this);

  @DomName('SVGPatternElement.patternUnits')
  @DocsEditable()
  AnimatedEnumeration get patternUnits => _blink.BlinkSVGPatternElement.$patternUnits_Getter(this);

  @DomName('SVGPatternElement.width')
  @DocsEditable()
  AnimatedLength get width => _blink.BlinkSVGPatternElement.$width_Getter(this);

  @DomName('SVGPatternElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.BlinkSVGPatternElement.$x_Getter(this);

  @DomName('SVGPatternElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.BlinkSVGPatternElement.$y_Getter(this);

  @DomName('SVGPatternElement.preserveAspectRatio')
  @DocsEditable()
  AnimatedPreserveAspectRatio get preserveAspectRatio => _blink.BlinkSVGPatternElement.$preserveAspectRatio_Getter(this);

  @DomName('SVGPatternElement.viewBox')
  @DocsEditable()
  AnimatedRect get viewBox => _blink.BlinkSVGPatternElement.$viewBox_Getter(this);

  @DomName('SVGPatternElement.requiredExtensions')
  @DocsEditable()
  StringList get requiredExtensions => _blink.BlinkSVGPatternElement.$requiredExtensions_Getter(this);

  @DomName('SVGPatternElement.requiredFeatures')
  @DocsEditable()
  StringList get requiredFeatures => _blink.BlinkSVGPatternElement.$requiredFeatures_Getter(this);

  @DomName('SVGPatternElement.systemLanguage')
  @DocsEditable()
  StringList get systemLanguage => _blink.BlinkSVGPatternElement.$systemLanguage_Getter(this);

  @DomName('SVGPatternElement.hasExtension')
  @DocsEditable()
  bool hasExtension(String extension) => _blink.BlinkSVGPatternElement.$hasExtension_Callback(this, extension);

  @DomName('SVGPatternElement.href')
  @DocsEditable()
  AnimatedString get href => _blink.BlinkSVGPatternElement.$href_Getter(this);

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
  num get x => _blink.BlinkSVGPoint.$x_Getter(this);

  @DomName('SVGPoint.x')
  @DocsEditable()
  void set x(num value) => _blink.BlinkSVGPoint.$x_Setter(this, value);

  @DomName('SVGPoint.y')
  @DocsEditable()
  num get y => _blink.BlinkSVGPoint.$y_Getter(this);

  @DomName('SVGPoint.y')
  @DocsEditable()
  void set y(num value) => _blink.BlinkSVGPoint.$y_Setter(this, value);

  @DomName('SVGPoint.matrixTransform')
  @DocsEditable()
  Point matrixTransform(Matrix matrix) => _blink.BlinkSVGPoint.$matrixTransform_Callback(this, matrix);

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
  int get numberOfItems => _blink.BlinkSVGPointList.$numberOfItems_Getter(this);

  @DomName('SVGPointList.appendItem')
  @DocsEditable()
  Point appendItem(Point item) => _blink.BlinkSVGPointList.$appendItem_Callback(this, item);

  @DomName('SVGPointList.clear')
  @DocsEditable()
  void clear() => _blink.BlinkSVGPointList.$clear_Callback(this);

  @DomName('SVGPointList.getItem')
  @DocsEditable()
  Point getItem(int index) => _blink.BlinkSVGPointList.$getItem_Callback(this, index);

  @DomName('SVGPointList.initialize')
  @DocsEditable()
  Point initialize(Point item) => _blink.BlinkSVGPointList.$initialize_Callback(this, item);

  @DomName('SVGPointList.insertItemBefore')
  @DocsEditable()
  Point insertItemBefore(Point item, int index) => _blink.BlinkSVGPointList.$insertItemBefore_Callback(this, item, index);

  @DomName('SVGPointList.removeItem')
  @DocsEditable()
  Point removeItem(int index) => _blink.BlinkSVGPointList.$removeItem_Callback(this, index);

  @DomName('SVGPointList.replaceItem')
  @DocsEditable()
  Point replaceItem(Point item, int index) => _blink.BlinkSVGPointList.$replaceItem_Callback(this, item, index);

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
  PointList get animatedPoints => _blink.BlinkSVGPolygonElement.$animatedPoints_Getter(this);

  @DomName('SVGPolygonElement.points')
  @DocsEditable()
  PointList get points => _blink.BlinkSVGPolygonElement.$points_Getter(this);

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
  PointList get animatedPoints => _blink.BlinkSVGPolylineElement.$animatedPoints_Getter(this);

  @DomName('SVGPolylineElement.points')
  @DocsEditable()
  PointList get points => _blink.BlinkSVGPolylineElement.$points_Getter(this);

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
  int get align => _blink.BlinkSVGPreserveAspectRatio.$align_Getter(this);

  @DomName('SVGPreserveAspectRatio.align')
  @DocsEditable()
  void set align(int value) => _blink.BlinkSVGPreserveAspectRatio.$align_Setter(this, value);

  @DomName('SVGPreserveAspectRatio.meetOrSlice')
  @DocsEditable()
  int get meetOrSlice => _blink.BlinkSVGPreserveAspectRatio.$meetOrSlice_Getter(this);

  @DomName('SVGPreserveAspectRatio.meetOrSlice')
  @DocsEditable()
  void set meetOrSlice(int value) => _blink.BlinkSVGPreserveAspectRatio.$meetOrSlice_Setter(this, value);

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
  AnimatedLength get cx => _blink.BlinkSVGRadialGradientElement.$cx_Getter(this);

  @DomName('SVGRadialGradientElement.cy')
  @DocsEditable()
  AnimatedLength get cy => _blink.BlinkSVGRadialGradientElement.$cy_Getter(this);

  @DomName('SVGRadialGradientElement.fr')
  @DocsEditable()
  AnimatedLength get fr => _blink.BlinkSVGRadialGradientElement.$fr_Getter(this);

  @DomName('SVGRadialGradientElement.fx')
  @DocsEditable()
  AnimatedLength get fx => _blink.BlinkSVGRadialGradientElement.$fx_Getter(this);

  @DomName('SVGRadialGradientElement.fy')
  @DocsEditable()
  AnimatedLength get fy => _blink.BlinkSVGRadialGradientElement.$fy_Getter(this);

  @DomName('SVGRadialGradientElement.r')
  @DocsEditable()
  AnimatedLength get r => _blink.BlinkSVGRadialGradientElement.$r_Getter(this);

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
  num get height => _blink.BlinkSVGRect.$height_Getter(this);

  @DomName('SVGRect.height')
  @DocsEditable()
  void set height(num value) => _blink.BlinkSVGRect.$height_Setter(this, value);

  @DomName('SVGRect.width')
  @DocsEditable()
  num get width => _blink.BlinkSVGRect.$width_Getter(this);

  @DomName('SVGRect.width')
  @DocsEditable()
  void set width(num value) => _blink.BlinkSVGRect.$width_Setter(this, value);

  @DomName('SVGRect.x')
  @DocsEditable()
  num get x => _blink.BlinkSVGRect.$x_Getter(this);

  @DomName('SVGRect.x')
  @DocsEditable()
  void set x(num value) => _blink.BlinkSVGRect.$x_Setter(this, value);

  @DomName('SVGRect.y')
  @DocsEditable()
  num get y => _blink.BlinkSVGRect.$y_Getter(this);

  @DomName('SVGRect.y')
  @DocsEditable()
  void set y(num value) => _blink.BlinkSVGRect.$y_Setter(this, value);

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
  AnimatedLength get height => _blink.BlinkSVGRectElement.$height_Getter(this);

  @DomName('SVGRectElement.rx')
  @DocsEditable()
  AnimatedLength get rx => _blink.BlinkSVGRectElement.$rx_Getter(this);

  @DomName('SVGRectElement.ry')
  @DocsEditable()
  AnimatedLength get ry => _blink.BlinkSVGRectElement.$ry_Getter(this);

  @DomName('SVGRectElement.width')
  @DocsEditable()
  AnimatedLength get width => _blink.BlinkSVGRectElement.$width_Getter(this);

  @DomName('SVGRectElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.BlinkSVGRectElement.$x_Getter(this);

  @DomName('SVGRectElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.BlinkSVGRectElement.$y_Getter(this);

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
  String get type => _blink.BlinkSVGScriptElement.$type_Getter(this);

  @DomName('SVGScriptElement.type')
  @DocsEditable()
  void set type(String value) => _blink.BlinkSVGScriptElement.$type_Setter(this, value);

  @DomName('SVGScriptElement.href')
  @DocsEditable()
  AnimatedString get href => _blink.BlinkSVGScriptElement.$href_Getter(this);

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
  AnimatedNumber get gradientOffset => _blink.BlinkSVGStopElement.$offset_Getter(this);

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
  int get numberOfItems => _blink.BlinkSVGStringList.$numberOfItems_Getter(this);

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
  String appendItem(String item) => _blink.BlinkSVGStringList.$appendItem_Callback(this, item);

  @DomName('SVGStringList.clear')
  @DocsEditable()
  void clear() => _blink.BlinkSVGStringList.$clear_Callback(this);

  @DomName('SVGStringList.getItem')
  @DocsEditable()
  String getItem(int index) => _blink.BlinkSVGStringList.$getItem_Callback(this, index);

  @DomName('SVGStringList.initialize')
  @DocsEditable()
  String initialize(String item) => _blink.BlinkSVGStringList.$initialize_Callback(this, item);

  @DomName('SVGStringList.insertItemBefore')
  @DocsEditable()
  String insertItemBefore(String item, int index) => _blink.BlinkSVGStringList.$insertItemBefore_Callback(this, item, index);

  @DomName('SVGStringList.removeItem')
  @DocsEditable()
  String removeItem(int index) => _blink.BlinkSVGStringList.$removeItem_Callback(this, index);

  @DomName('SVGStringList.replaceItem')
  @DocsEditable()
  String replaceItem(String item, int index) => _blink.BlinkSVGStringList.$replaceItem_Callback(this, item, index);

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
  bool get disabled => _blink.BlinkSVGStyleElement.$disabled_Getter(this);

  @DomName('SVGStyleElement.disabled')
  @DocsEditable()
  void set disabled(bool value) => _blink.BlinkSVGStyleElement.$disabled_Setter(this, value);

  @DomName('SVGStyleElement.media')
  @DocsEditable()
  String get media => _blink.BlinkSVGStyleElement.$media_Getter(this);

  @DomName('SVGStyleElement.media')
  @DocsEditable()
  void set media(String value) => _blink.BlinkSVGStyleElement.$media_Setter(this, value);

  @DomName('SVGStyleElement.title')
  @DocsEditable()
  String get title => _blink.BlinkSVGStyleElement.$title_Getter(this);

  @DomName('SVGStyleElement.title')
  @DocsEditable()
  void set title(String value) => _blink.BlinkSVGStyleElement.$title_Setter(this, value);

  @DomName('SVGStyleElement.type')
  @DocsEditable()
  String get type => _blink.BlinkSVGStyleElement.$type_Getter(this);

  @DomName('SVGStyleElement.type')
  @DocsEditable()
  void set type(String value) => _blink.BlinkSVGStyleElement.$type_Setter(this, value);

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
  AnimatedString get _svgClassName => _blink.BlinkSVGElement.$className_Getter(this);

  @DomName('SVGElement.ownerSVGElement')
  @DocsEditable()
  SvgSvgElement get ownerSvgElement => _blink.BlinkSVGElement.$ownerSVGElement_Getter(this);

  @DomName('SVGElement.style')
  @DocsEditable()
  @Experimental() // untriaged
  CssStyleDeclaration get style => _blink.BlinkSVGElement.$style_Getter(this);

  @DomName('SVGElement.viewportElement')
  @DocsEditable()
  SvgElement get viewportElement => _blink.BlinkSVGElement.$viewportElement_Getter(this);

  @DomName('SVGElement.xmlbase')
  @DocsEditable()
  String get xmlbase => _blink.BlinkSVGElement.$xmlbase_Getter(this);

  @DomName('SVGElement.xmlbase')
  @DocsEditable()
  void set xmlbase(String value) => _blink.BlinkSVGElement.$xmlbase_Setter(this, value);

  @DomName('SVGElement.xmllang')
  @DocsEditable()
  @Experimental() // untriaged
  String get xmllang => _blink.BlinkSVGElement.$xmllang_Getter(this);

  @DomName('SVGElement.xmllang')
  @DocsEditable()
  @Experimental() // untriaged
  void set xmllang(String value) => _blink.BlinkSVGElement.$xmllang_Setter(this, value);

  @DomName('SVGElement.xmlspace')
  @DocsEditable()
  @Experimental() // untriaged
  String get xmlspace => _blink.BlinkSVGElement.$xmlspace_Getter(this);

  @DomName('SVGElement.xmlspace')
  @DocsEditable()
  @Experimental() // untriaged
  void set xmlspace(String value) => _blink.BlinkSVGElement.$xmlspace_Setter(this, value);

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
  num get currentScale => _blink.BlinkSVGSVGElement.$currentScale_Getter(this);

  @DomName('SVGSVGElement.currentScale')
  @DocsEditable()
  void set currentScale(num value) => _blink.BlinkSVGSVGElement.$currentScale_Setter(this, value);

  @DomName('SVGSVGElement.currentTranslate')
  @DocsEditable()
  Point get currentTranslate => _blink.BlinkSVGSVGElement.$currentTranslate_Getter(this);

  @DomName('SVGSVGElement.currentView')
  @DocsEditable()
  ViewSpec get currentView => _blink.BlinkSVGSVGElement.$currentView_Getter(this);

  @DomName('SVGSVGElement.height')
  @DocsEditable()
  AnimatedLength get height => _blink.BlinkSVGSVGElement.$height_Getter(this);

  @DomName('SVGSVGElement.pixelUnitToMillimeterX')
  @DocsEditable()
  double get pixelUnitToMillimeterX => _blink.BlinkSVGSVGElement.$pixelUnitToMillimeterX_Getter(this);

  @DomName('SVGSVGElement.pixelUnitToMillimeterY')
  @DocsEditable()
  double get pixelUnitToMillimeterY => _blink.BlinkSVGSVGElement.$pixelUnitToMillimeterY_Getter(this);

  @DomName('SVGSVGElement.screenPixelToMillimeterX')
  @DocsEditable()
  double get screenPixelToMillimeterX => _blink.BlinkSVGSVGElement.$screenPixelToMillimeterX_Getter(this);

  @DomName('SVGSVGElement.screenPixelToMillimeterY')
  @DocsEditable()
  double get screenPixelToMillimeterY => _blink.BlinkSVGSVGElement.$screenPixelToMillimeterY_Getter(this);

  @DomName('SVGSVGElement.useCurrentView')
  @DocsEditable()
  bool get useCurrentView => _blink.BlinkSVGSVGElement.$useCurrentView_Getter(this);

  @DomName('SVGSVGElement.viewport')
  @DocsEditable()
  Rect get viewport => _blink.BlinkSVGSVGElement.$viewport_Getter(this);

  @DomName('SVGSVGElement.width')
  @DocsEditable()
  AnimatedLength get width => _blink.BlinkSVGSVGElement.$width_Getter(this);

  @DomName('SVGSVGElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.BlinkSVGSVGElement.$x_Getter(this);

  @DomName('SVGSVGElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.BlinkSVGSVGElement.$y_Getter(this);

  @DomName('SVGSVGElement.animationsPaused')
  @DocsEditable()
  bool animationsPaused() => _blink.BlinkSVGSVGElement.$animationsPaused_Callback(this);

  @DomName('SVGSVGElement.checkEnclosure')
  @DocsEditable()
  bool checkEnclosure(SvgElement element, Rect rect) => _blink.BlinkSVGSVGElement.$checkEnclosure_Callback(this, element, rect);

  @DomName('SVGSVGElement.checkIntersection')
  @DocsEditable()
  bool checkIntersection(SvgElement element, Rect rect) => _blink.BlinkSVGSVGElement.$checkIntersection_Callback(this, element, rect);

  @DomName('SVGSVGElement.createSVGAngle')
  @DocsEditable()
  Angle createSvgAngle() => _blink.BlinkSVGSVGElement.$createSVGAngle_Callback(this);

  @DomName('SVGSVGElement.createSVGLength')
  @DocsEditable()
  Length createSvgLength() => _blink.BlinkSVGSVGElement.$createSVGLength_Callback(this);

  @DomName('SVGSVGElement.createSVGMatrix')
  @DocsEditable()
  Matrix createSvgMatrix() => _blink.BlinkSVGSVGElement.$createSVGMatrix_Callback(this);

  @DomName('SVGSVGElement.createSVGNumber')
  @DocsEditable()
  Number createSvgNumber() => _blink.BlinkSVGSVGElement.$createSVGNumber_Callback(this);

  @DomName('SVGSVGElement.createSVGPoint')
  @DocsEditable()
  Point createSvgPoint() => _blink.BlinkSVGSVGElement.$createSVGPoint_Callback(this);

  @DomName('SVGSVGElement.createSVGRect')
  @DocsEditable()
  Rect createSvgRect() => _blink.BlinkSVGSVGElement.$createSVGRect_Callback(this);

  @DomName('SVGSVGElement.createSVGTransform')
  @DocsEditable()
  Transform createSvgTransform() => _blink.BlinkSVGSVGElement.$createSVGTransform_Callback(this);

  @DomName('SVGSVGElement.createSVGTransformFromMatrix')
  @DocsEditable()
  Transform createSvgTransformFromMatrix(Matrix matrix) => _blink.BlinkSVGSVGElement.$createSVGTransformFromMatrix_Callback(this, matrix);

  @DomName('SVGSVGElement.deselectAll')
  @DocsEditable()
  void deselectAll() => _blink.BlinkSVGSVGElement.$deselectAll_Callback(this);

  @DomName('SVGSVGElement.forceRedraw')
  @DocsEditable()
  void forceRedraw() => _blink.BlinkSVGSVGElement.$forceRedraw_Callback(this);

  @DomName('SVGSVGElement.getCurrentTime')
  @DocsEditable()
  double getCurrentTime() => _blink.BlinkSVGSVGElement.$getCurrentTime_Callback(this);

  @DomName('SVGSVGElement.getElementById')
  @DocsEditable()
  Element getElementById(String elementId) => _blink.BlinkSVGSVGElement.$getElementById_Callback(this, elementId);

  @DomName('SVGSVGElement.getEnclosureList')
  @DocsEditable()
  List<Node> getEnclosureList(Rect rect, SvgElement referenceElement) => _blink.BlinkSVGSVGElement.$getEnclosureList_Callback(this, rect, referenceElement);

  @DomName('SVGSVGElement.getIntersectionList')
  @DocsEditable()
  List<Node> getIntersectionList(Rect rect, SvgElement referenceElement) => _blink.BlinkSVGSVGElement.$getIntersectionList_Callback(this, rect, referenceElement);

  @DomName('SVGSVGElement.pauseAnimations')
  @DocsEditable()
  void pauseAnimations() => _blink.BlinkSVGSVGElement.$pauseAnimations_Callback(this);

  @DomName('SVGSVGElement.setCurrentTime')
  @DocsEditable()
  void setCurrentTime(num seconds) => _blink.BlinkSVGSVGElement.$setCurrentTime_Callback(this, seconds);

  @DomName('SVGSVGElement.suspendRedraw')
  @DocsEditable()
  int suspendRedraw(int maxWaitMilliseconds) => _blink.BlinkSVGSVGElement.$suspendRedraw_Callback(this, maxWaitMilliseconds);

  @DomName('SVGSVGElement.unpauseAnimations')
  @DocsEditable()
  void unpauseAnimations() => _blink.BlinkSVGSVGElement.$unpauseAnimations_Callback(this);

  @DomName('SVGSVGElement.unsuspendRedraw')
  @DocsEditable()
  void unsuspendRedraw(int suspendHandleId) => _blink.BlinkSVGSVGElement.$unsuspendRedraw_Callback(this, suspendHandleId);

  @DomName('SVGSVGElement.unsuspendRedrawAll')
  @DocsEditable()
  void unsuspendRedrawAll() => _blink.BlinkSVGSVGElement.$unsuspendRedrawAll_Callback(this);

  @DomName('SVGSVGElement.preserveAspectRatio')
  @DocsEditable()
  AnimatedPreserveAspectRatio get preserveAspectRatio => _blink.BlinkSVGSVGElement.$preserveAspectRatio_Getter(this);

  @DomName('SVGSVGElement.viewBox')
  @DocsEditable()
  AnimatedRect get viewBox => _blink.BlinkSVGSVGElement.$viewBox_Getter(this);

  @DomName('SVGSVGElement.zoomAndPan')
  @DocsEditable()
  int get zoomAndPan => _blink.BlinkSVGSVGElement.$zoomAndPan_Getter(this);

  @DomName('SVGSVGElement.zoomAndPan')
  @DocsEditable()
  void set zoomAndPan(int value) => _blink.BlinkSVGSVGElement.$zoomAndPan_Setter(this, value);

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
  AnimatedPreserveAspectRatio get preserveAspectRatio => _blink.BlinkSVGSymbolElement.$preserveAspectRatio_Getter(this);

  @DomName('SVGSymbolElement.viewBox')
  @DocsEditable()
  AnimatedRect get viewBox => _blink.BlinkSVGSymbolElement.$viewBox_Getter(this);

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
  StringList get requiredExtensions => _blink.BlinkSVGTests.$requiredExtensions_Getter(this);

  @DomName('SVGTests.requiredFeatures')
  @DocsEditable()
  StringList get requiredFeatures => _blink.BlinkSVGTests.$requiredFeatures_Getter(this);

  @DomName('SVGTests.systemLanguage')
  @DocsEditable()
  StringList get systemLanguage => _blink.BlinkSVGTests.$systemLanguage_Getter(this);

  @DomName('SVGTests.hasExtension')
  @DocsEditable()
  bool hasExtension(String extension) => _blink.BlinkSVGTests.$hasExtension_Callback(this, extension);

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
  AnimatedEnumeration get lengthAdjust => _blink.BlinkSVGTextContentElement.$lengthAdjust_Getter(this);

  @DomName('SVGTextContentElement.textLength')
  @DocsEditable()
  AnimatedLength get textLength => _blink.BlinkSVGTextContentElement.$textLength_Getter(this);

  @DomName('SVGTextContentElement.getCharNumAtPosition')
  @DocsEditable()
  int getCharNumAtPosition(Point point) => _blink.BlinkSVGTextContentElement.$getCharNumAtPosition_Callback(this, point);

  @DomName('SVGTextContentElement.getComputedTextLength')
  @DocsEditable()
  double getComputedTextLength() => _blink.BlinkSVGTextContentElement.$getComputedTextLength_Callback(this);

  @DomName('SVGTextContentElement.getEndPositionOfChar')
  @DocsEditable()
  Point getEndPositionOfChar(int offset) => _blink.BlinkSVGTextContentElement.$getEndPositionOfChar_Callback(this, offset);

  @DomName('SVGTextContentElement.getExtentOfChar')
  @DocsEditable()
  Rect getExtentOfChar(int offset) => _blink.BlinkSVGTextContentElement.$getExtentOfChar_Callback(this, offset);

  @DomName('SVGTextContentElement.getNumberOfChars')
  @DocsEditable()
  int getNumberOfChars() => _blink.BlinkSVGTextContentElement.$getNumberOfChars_Callback(this);

  @DomName('SVGTextContentElement.getRotationOfChar')
  @DocsEditable()
  double getRotationOfChar(int offset) => _blink.BlinkSVGTextContentElement.$getRotationOfChar_Callback(this, offset);

  @DomName('SVGTextContentElement.getStartPositionOfChar')
  @DocsEditable()
  Point getStartPositionOfChar(int offset) => _blink.BlinkSVGTextContentElement.$getStartPositionOfChar_Callback(this, offset);

  @DomName('SVGTextContentElement.getSubStringLength')
  @DocsEditable()
  double getSubStringLength(int offset, int length) => _blink.BlinkSVGTextContentElement.$getSubStringLength_Callback(this, offset, length);

  @DomName('SVGTextContentElement.selectSubString')
  @DocsEditable()
  void selectSubString(int offset, int length) => _blink.BlinkSVGTextContentElement.$selectSubString_Callback(this, offset, length);

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
  AnimatedEnumeration get method => _blink.BlinkSVGTextPathElement.$method_Getter(this);

  @DomName('SVGTextPathElement.spacing')
  @DocsEditable()
  AnimatedEnumeration get spacing => _blink.BlinkSVGTextPathElement.$spacing_Getter(this);

  @DomName('SVGTextPathElement.startOffset')
  @DocsEditable()
  AnimatedLength get startOffset => _blink.BlinkSVGTextPathElement.$startOffset_Getter(this);

  @DomName('SVGTextPathElement.href')
  @DocsEditable()
  AnimatedString get href => _blink.BlinkSVGTextPathElement.$href_Getter(this);

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
  AnimatedLengthList get dx => _blink.BlinkSVGTextPositioningElement.$dx_Getter(this);

  @DomName('SVGTextPositioningElement.dy')
  @DocsEditable()
  AnimatedLengthList get dy => _blink.BlinkSVGTextPositioningElement.$dy_Getter(this);

  @DomName('SVGTextPositioningElement.rotate')
  @DocsEditable()
  AnimatedNumberList get rotate => _blink.BlinkSVGTextPositioningElement.$rotate_Getter(this);

  @DomName('SVGTextPositioningElement.x')
  @DocsEditable()
  AnimatedLengthList get x => _blink.BlinkSVGTextPositioningElement.$x_Getter(this);

  @DomName('SVGTextPositioningElement.y')
  @DocsEditable()
  AnimatedLengthList get y => _blink.BlinkSVGTextPositioningElement.$y_Getter(this);

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
  double get angle => _blink.BlinkSVGTransform.$angle_Getter(this);

  @DomName('SVGTransform.matrix')
  @DocsEditable()
  Matrix get matrix => _blink.BlinkSVGTransform.$matrix_Getter(this);

  @DomName('SVGTransform.type')
  @DocsEditable()
  int get type => _blink.BlinkSVGTransform.$type_Getter(this);

  @DomName('SVGTransform.setMatrix')
  @DocsEditable()
  void setMatrix(Matrix matrix) => _blink.BlinkSVGTransform.$setMatrix_Callback(this, matrix);

  @DomName('SVGTransform.setRotate')
  @DocsEditable()
  void setRotate(num angle, num cx, num cy) => _blink.BlinkSVGTransform.$setRotate_Callback(this, angle, cx, cy);

  @DomName('SVGTransform.setScale')
  @DocsEditable()
  void setScale(num sx, num sy) => _blink.BlinkSVGTransform.$setScale_Callback(this, sx, sy);

  @DomName('SVGTransform.setSkewX')
  @DocsEditable()
  void setSkewX(num angle) => _blink.BlinkSVGTransform.$setSkewX_Callback(this, angle);

  @DomName('SVGTransform.setSkewY')
  @DocsEditable()
  void setSkewY(num angle) => _blink.BlinkSVGTransform.$setSkewY_Callback(this, angle);

  @DomName('SVGTransform.setTranslate')
  @DocsEditable()
  void setTranslate(num tx, num ty) => _blink.BlinkSVGTransform.$setTranslate_Callback(this, tx, ty);

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
  int get numberOfItems => _blink.BlinkSVGTransformList.$numberOfItems_Getter(this);

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
  Transform appendItem(Transform item) => _blink.BlinkSVGTransformList.$appendItem_Callback(this, item);

  @DomName('SVGTransformList.clear')
  @DocsEditable()
  void clear() => _blink.BlinkSVGTransformList.$clear_Callback(this);

  @DomName('SVGTransformList.consolidate')
  @DocsEditable()
  Transform consolidate() => _blink.BlinkSVGTransformList.$consolidate_Callback(this);

  @DomName('SVGTransformList.createSVGTransformFromMatrix')
  @DocsEditable()
  Transform createSvgTransformFromMatrix(Matrix matrix) => _blink.BlinkSVGTransformList.$createSVGTransformFromMatrix_Callback(this, matrix);

  @DomName('SVGTransformList.getItem')
  @DocsEditable()
  Transform getItem(int index) => _blink.BlinkSVGTransformList.$getItem_Callback(this, index);

  @DomName('SVGTransformList.initialize')
  @DocsEditable()
  Transform initialize(Transform item) => _blink.BlinkSVGTransformList.$initialize_Callback(this, item);

  @DomName('SVGTransformList.insertItemBefore')
  @DocsEditable()
  Transform insertItemBefore(Transform item, int index) => _blink.BlinkSVGTransformList.$insertItemBefore_Callback(this, item, index);

  @DomName('SVGTransformList.removeItem')
  @DocsEditable()
  Transform removeItem(int index) => _blink.BlinkSVGTransformList.$removeItem_Callback(this, index);

  @DomName('SVGTransformList.replaceItem')
  @DocsEditable()
  Transform replaceItem(Transform item, int index) => _blink.BlinkSVGTransformList.$replaceItem_Callback(this, item, index);

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
  AnimatedString get href => _blink.BlinkSVGURIReference.$href_Getter(this);

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
  ElementInstance get animatedInstanceRoot => _blink.BlinkSVGUseElement.$animatedInstanceRoot_Getter(this);

  @DomName('SVGUseElement.height')
  @DocsEditable()
  AnimatedLength get height => _blink.BlinkSVGUseElement.$height_Getter(this);

  @DomName('SVGUseElement.instanceRoot')
  @DocsEditable()
  ElementInstance get instanceRoot => _blink.BlinkSVGUseElement.$instanceRoot_Getter(this);

  @DomName('SVGUseElement.width')
  @DocsEditable()
  AnimatedLength get width => _blink.BlinkSVGUseElement.$width_Getter(this);

  @DomName('SVGUseElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.BlinkSVGUseElement.$x_Getter(this);

  @DomName('SVGUseElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.BlinkSVGUseElement.$y_Getter(this);

  @DomName('SVGUseElement.requiredExtensions')
  @DocsEditable()
  StringList get requiredExtensions => _blink.BlinkSVGUseElement.$requiredExtensions_Getter(this);

  @DomName('SVGUseElement.requiredFeatures')
  @DocsEditable()
  StringList get requiredFeatures => _blink.BlinkSVGUseElement.$requiredFeatures_Getter(this);

  @DomName('SVGUseElement.systemLanguage')
  @DocsEditable()
  StringList get systemLanguage => _blink.BlinkSVGUseElement.$systemLanguage_Getter(this);

  @DomName('SVGUseElement.hasExtension')
  @DocsEditable()
  bool hasExtension(String extension) => _blink.BlinkSVGUseElement.$hasExtension_Callback(this, extension);

  @DomName('SVGUseElement.href')
  @DocsEditable()
  AnimatedString get href => _blink.BlinkSVGUseElement.$href_Getter(this);

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
  StringList get viewTarget => _blink.BlinkSVGViewElement.$viewTarget_Getter(this);

  @DomName('SVGViewElement.preserveAspectRatio')
  @DocsEditable()
  AnimatedPreserveAspectRatio get preserveAspectRatio => _blink.BlinkSVGViewElement.$preserveAspectRatio_Getter(this);

  @DomName('SVGViewElement.viewBox')
  @DocsEditable()
  AnimatedRect get viewBox => _blink.BlinkSVGViewElement.$viewBox_Getter(this);

  @DomName('SVGViewElement.zoomAndPan')
  @DocsEditable()
  int get zoomAndPan => _blink.BlinkSVGViewElement.$zoomAndPan_Getter(this);

  @DomName('SVGViewElement.zoomAndPan')
  @DocsEditable()
  void set zoomAndPan(int value) => _blink.BlinkSVGViewElement.$zoomAndPan_Setter(this, value);

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
  String get preserveAspectRatioString => _blink.BlinkSVGViewSpec.$preserveAspectRatioString_Getter(this);

  @DomName('SVGViewSpec.transform')
  @DocsEditable()
  TransformList get transform => _blink.BlinkSVGViewSpec.$transform_Getter(this);

  @DomName('SVGViewSpec.transformString')
  @DocsEditable()
  String get transformString => _blink.BlinkSVGViewSpec.$transformString_Getter(this);

  @DomName('SVGViewSpec.viewBoxString')
  @DocsEditable()
  String get viewBoxString => _blink.BlinkSVGViewSpec.$viewBoxString_Getter(this);

  @DomName('SVGViewSpec.viewTarget')
  @DocsEditable()
  SvgElement get viewTarget => _blink.BlinkSVGViewSpec.$viewTarget_Getter(this);

  @DomName('SVGViewSpec.viewTargetString')
  @DocsEditable()
  String get viewTargetString => _blink.BlinkSVGViewSpec.$viewTargetString_Getter(this);

  @DomName('SVGViewSpec.preserveAspectRatio')
  @DocsEditable()
  @Experimental() // nonstandard
  AnimatedPreserveAspectRatio get preserveAspectRatio => _blink.BlinkSVGViewSpec.$preserveAspectRatio_Getter(this);

  @DomName('SVGViewSpec.viewBox')
  @DocsEditable()
  @Experimental() // nonstandard
  AnimatedRect get viewBox => _blink.BlinkSVGViewSpec.$viewBox_Getter(this);

  @DomName('SVGViewSpec.zoomAndPan')
  @DocsEditable()
  @Experimental() // nonstandard
  int get zoomAndPan => _blink.BlinkSVGViewSpec.$zoomAndPan_Getter(this);

  @DomName('SVGViewSpec.zoomAndPan')
  @DocsEditable()
  @Experimental() // nonstandard
  void set zoomAndPan(int value) => _blink.BlinkSVGViewSpec.$zoomAndPan_Setter(this, value);

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
  int get zoomAndPan => _blink.BlinkSVGZoomAndPan.$zoomAndPan_Getter(this);

  @DomName('SVGZoomAndPan.zoomAndPan')
  @DocsEditable()
  void set zoomAndPan(int value) => _blink.BlinkSVGZoomAndPan.$zoomAndPan_Setter(this, value);

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
  double get newScale => _blink.BlinkSVGZoomEvent.$newScale_Getter(this);

  @DomName('SVGZoomEvent.newTranslate')
  @DocsEditable()
  Point get newTranslate => _blink.BlinkSVGZoomEvent.$newTranslate_Getter(this);

  @DomName('SVGZoomEvent.previousScale')
  @DocsEditable()
  double get previousScale => _blink.BlinkSVGZoomEvent.$previousScale_Getter(this);

  @DomName('SVGZoomEvent.previousTranslate')
  @DocsEditable()
  Point get previousTranslate => _blink.BlinkSVGZoomEvent.$previousTranslate_Getter(this);

  @DomName('SVGZoomEvent.zoomRectScreen')
  @DocsEditable()
  Rect get zoomRectScreen => _blink.BlinkSVGZoomEvent.$zoomRectScreen_Getter(this);

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
  int get length => _blink.BlinkSVGElementInstanceList.$length_Getter(this);

  ElementInstance operator[](int index) {
    if (index < 0 || index >= length)
      throw new RangeError.range(index, 0, length);
    return _blink.BlinkSVGElementInstanceList.$NativeIndexed_Getter(this, index);
  }

  ElementInstance _nativeIndexedGetter(int index) => _blink.BlinkSVGElementInstanceList.$NativeIndexed_Getter(this, index);

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
  ElementInstance item(int index) => _blink.BlinkSVGElementInstanceList.$item_Callback(this, index);

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
  AnimatedTransformList get gradientTransform => _blink.BlinkSVGGradientElement.$gradientTransform_Getter(this);

  @DomName('SVGGradientElement.gradientUnits')
  @DocsEditable()
  AnimatedEnumeration get gradientUnits => _blink.BlinkSVGGradientElement.$gradientUnits_Getter(this);

  @DomName('SVGGradientElement.spreadMethod')
  @DocsEditable()
  AnimatedEnumeration get spreadMethod => _blink.BlinkSVGGradientElement.$spreadMethod_Getter(this);

  @DomName('SVGGradientElement.href')
  @DocsEditable()
  AnimatedString get href => _blink.BlinkSVGGradientElement.$href_Getter(this);

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
